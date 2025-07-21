# Creating a salt state to automate the deployment of the hardened kubernetes cluster
i was initially going to do this by loading every image into a docker registry and then using those images to install everything. however, it is **significantly** easier to just download the tarballs and install like that. this way, the only images needed are just the ones for my services and the only files needed are the tarballs. the upgrade process is also very straightforward and simple.



## Manual process of installing rke2 that the salt state is automating
### downloading the rke2 archive files on the non airgapped side
```
curl -OLs https://github.com/rancher/rke2/releases/download/v1.33.1%2Brke2r1/rke2-images.linux-amd64.tar.zst
curl -OLs https://github.com/rancher/rke2/releases/download/v1.33.1%2Brke2r1/rke2.linux-amd64.tar.gz
curl -OLs https://github.com/rancher/rke2/releases/download/v1.33.1%2Brke2r1/sha256sum-amd64.txt
curl -OLs https://github.com/rancher/rke2/releases/download/v1.33.1%2Brke2r1/rke2-images-traefik.linux-amd64.tar.zst
curl -sfL https://get.rke2.io --output install.sh
```

### adding needed images to a private registry
if a registry needs to be created for specific images, the following process is done:
- a new container is deployed on port 5000 with the registry:2 image using a persistent volume
  - `podman volume create registry-data`
  - `podman pull docker.io/library/registry:2`
  - ```podman run -d --name private-registry \
            -p 5000:5000 \
            -v registry-data:/var/lib/registry \
            --restart=always \
            docker.io/library/registry:2
    ```
- the metallb, gitlab runner, and gitlab runner helper archives are then loaded onto the system
- a custom gitlab runner image is created containing the required tls cert:
  - this docker file is used:
    - ```FROM registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v18.1.1
            ARG src="{{ pillar['cert_filename'] }}"
            ARG target="/usr/local/share/ca-certificates/<cert_name>.crt"
            COPY ${src} ${target}
            RUN update-ca-certificates
      ```
    - with this command: podman build -t my-gitlab-runner:v1 -f <dockerfile>
- then, the metallb files, the gitlab runner helper, and the custom gitlab runner images are retagged and pushed to the logal registry, after which they are removed from the local cache using this [script](salt/files/server/scripts/retag-and-push.sh)
### installing rke2 on the airgapped side
- after moving the files to the airgap, place them into /root/rke2-artifacts/.  
- the installation script can then be run with  `INSTALL_RKE2_ARTIFACT_PATH=/root/rke2-artifacts sh install.sh`
- the host configuration prerequisites then need to be run:
```
sudo cp -f /usr/share/rke2/rke2-cis-sysctl.conf /etc/sysctl.d/60-rke2-cis.conf # configuring kernel settings
sudo systemctl restart systemd-sysctl
sudo useradd -r -c "etcd user" -s /sbin/nologin -M etcd -U # creating an etcd user
```
- the [config file](salt/files/server/configs/config.yaml) then needs to be placed in `/etc/rancher/rke/config.yaml`.
- we then add the necessary manifests to `/etc/rancher/rke2/server/manifests/.`. these will automatically be deployed when rke2 starts:
  - the gitlab runners are deployed using rke2's [helm chart](salt/files/server/manifests/gitlab-runner-chart-crd.yaml) crd
    - the `valuesContent` field is used in place of `values.yaml`
    - we also need to add the helm chart archive file to the rke2 server for it to pull from instead of the helm repository
    - we need to configure the values.yaml chart to use the custom image
    - the gitlab server and runner authentication token are also added to its values
  - the [metallb manifest](salt/files/server/manifests/metallb-native.yaml) is added to this directory as well as an [ip address pool](salt/files/server/manifests/pools.yaml), which we set the values for
- firewalld needs to be stopped and disabled with `systemctl stop firewalld && systemctl disable firewalld`  
- we can then startup the cluster with `systemctl start rke2`.

### hardening the deployed cluster
- we then harden the cluster. first, [file permissions need to be adjusted](salt/hardening/permissions.sls) according to the [rke2 disa stig](https://stigviewer.com/stigs/rancher_government_solutions_rke2) (the rest of the remediations were done with the config file)  
- then, we harden the underlying os. to do this, we use openscap. a tailor file is created using the rhel 9 profile, ignoring the rules for httpd, dnsmasq, password expiration, account age, and firewalld.
  - ```autotailor \
          -u xccdf_org.ssgproject.content_rule_package_httpd_removed \
          -u xccdf_org.ssgproject.content_rule_package_dnsmasq_removed \
          -u xccdf_org.ssgproject.content_rule_account_disable_post_pw_expiration \
          -u xccdf_org.ssgproject.content_rule_accounts_maximum_age_login_defs \
          -u xccdf_org.ssgproject.content_rule_accounts_minimum_age_login_defs \
          -u xccdf_org.ssgproject.content_rule_accounts_password_set_max_life_existing \
          -u xccdf_org.ssgproject.content_rule_accounts_password_set_min_life_existing \
          -u xccdf_org.ssgproject.content_rule_accounts_password_set_warn_age_existing \
          -u xccdf_org.ssgproject.content_rule_accounts_password_warn_age_login_defs \
          -u xccdf_org.ssgproject.content_rule_accounts_set_post_pw_existing \
          -u xccdf_org.ssgproject.content_rule_accounts_password_pam_minclass \
          -u xccdf_org.ssgproject.content_rule_accounts_password_pam_minlen \
          -u xccdf_org.ssgproject.content_rule_accounts_password_pam_retry \
          -u xccdf_org.ssgproject.content_rule_package_firewalld_installed \
          -u xccdf_org.ssgproject.content_rule_service_firewalld_enabled \
          -u xccdf_org.ssgproject.content_rule_firewalld_loopback_traffic_restricted \
          -u xccdf_org.ssgproject.content_rule_firewalld_loopback_traffic_trusted \
          -o /tmp/tailor-file.xml \
          -p tailored-for-k8s \
          /usr/share/xml/scap/ssg/content/ssg-rl9-ds.xml \
          xccdf_org.ssgproject.content_profile_cis_server_l1`
    ```
- a remediation script is then generated by doing a scan of the system and outputting remediations as a bash script, which is then run.
  - `oscap xccdf generate fix --output /tmp/draft-remediation.sh --profile tailored-for-k8s --tailoring-file /tmp/tailor-file.xml /usr/share/xml/scap/ssg/content/ssg-rl9-ds.xml`
  - `chmod +x /tmp/draft-remediation.sh && /tmp/draft-remediation.sh`

### to update:
1. download new tar files and replace the ones in `/var/lib/rancher/rke2/agent/images/`
2. replace the executable file `/usr/local/bin/rke2`
3. restart the service
