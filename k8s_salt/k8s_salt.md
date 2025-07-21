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
### installing on the airgapped side
after moving the files to the airgap, place them into /root/rke2-artifacts/.  
the installation script can then be run with  
`INSTALL_RKE2_ARTIFACT_PATH=/root/rke2-artifacts sh install.sh`
the host configuration prerequisites then need to be run:
```
sudo cp -f /usr/share/rke2/rke2-cis-sysctl.conf /etc/sysctl.d/60-rke2-cis.conf # configuring kernel settings
sudo systemctl restart systemd-sysctl
sudo useradd -r -c "etcd user" -s /sbin/nologin -M etcd -U # creating an etcd user
```
the [config file](salt/files/server/configs/config.yaml) then needs to be placed in `/etc/rancher/rke/config.yaml`.  
firewalld needs to be stopped and disabled with `systemctl stop firewalld && systemctl disable firewalld`  
we can then startup the cluster with `systemctl start rke2`.

### hardening the deployed cluster
we then harden the cluster. first, [file permissions need to be adjusted](salt/hardening/permissions.sls) according to the [rke2 disa stig](https://stigviewer.com/stigs/rancher_government_solutions_rke2) (the rest of the remediations were done with the config file)  
then, we harden the underlying os. to do this, we use oscap. 

### to update:
1. download new tar files and replace the ones in `/var/lib/rancher/rke2/agent/images/`
2. replace the executable file `/usr/local/bin/rke2`
3. restart the service
