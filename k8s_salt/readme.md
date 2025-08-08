# Automating the deployment of a kubernetes cluster with salt
the purpose of this project is to create a kubernetes cluster that can better allocate resources for and run gitlab runners. it will also serve as a way to consolidate separate containerized services under one platform.
 
## Assumptions
- RHEL 9 machines
- running on airgapped network
  - working rpm repo mirror with:
    - podman
    - openscap
- working gitlab server with the ability to create runners and retrieve the runner tokens
- salt-master node with connected salt-minions
  - working certificates on the salt minions that can connect to the gitlab server

## Install
to deploy the salt state to the kuberntes server and agents, the salt [state directory](salt) needs to be placed on the salt master and set as a file root for the kubernetes state. the server and agent labels should be set to target the desired machines. for example:
```
k8s:
 '*':
   - installation/dependencies
   - registry/create_registry
   - ...
 '*server-targeting*':
   - hardening/config_file
   - installation/services
   - ...
 '*agent-targeting*':
   - hardening/worker_config_file
   - installation/rke2_worker_init
   - ...
```
there are also file dependencies that need to be installed. [this script](install_deps.sh) handles downloading the necessary files and placing them in the correct directory within a tar file. once the script has been run, the created `deps.tar` file can be placed inside the `salt/` directory and untarred with `tar -xvf deps.tar` (the tar file can then be removed to save space). the following pillars then must be set:

## Salt Structure
file                         | purpose
---                          |  ---
`salt/`                        | base directory for the salt state
`├── files/`                  | location of files to be places on the salt minions
`|     ├── server/`           | files for the server (master) k8s node
`|     |     ├── archives/`   | archive files, including images and the compressed rke2 binary
`|     |     ├── binaries/`   | contains the helm and k9s binaries
`|     |     ├── configs /`   | contains the main configuration file for rke2 and the registry configuration file
`|     |     ├── manifests/`  | manifests for the services that are deployed to the cluster. these are placed in the rke2 auto-deploy directory
`|     |     ├── scripts/`    | contains scripts used by the salt state for installation, registry creation, and file permissions
`|     ├── agent/`            | files for agent specific configuaration
`|     ├── upgrade/`          | stores the upgrade dependencies tarball
`├── hardening/`              | stores state files for hardening the cluster with both rke2 and the underlying image
`├── installation/`           | stores state files for installing rke2
`├── registry/`               | stores state files for setting up the local container image registry
`├── upgrade/`                | stores the state file for upgrading rke2


## Architecture
### kubernetes core
in place of upstream kubernetes, Rancher Kubernetes Engine 2 was used as the kubernetes distribution. it comes packaged with the following components:
- the rke2 implementation of `kubelet`
- etcd for the control plane data store
- canal for the CNI
  - flannel for the overlay network and calico for the network policies
- helm controller for a built-in way to deploy helm charts
- nginx ingress controller
instead of using nginx, which is the default ingress, traefik was used instead.

there are two ways of getting images onto the cluster:
#### - pulling them from a registry
this is the traditional way to get images onto a kubernetes cluster. a registry is run locally on each kubernetes node. these registries are all identical and contain the images for deployments not native to rke2. this is done via podman hosting a docker registry on localhost:5000. the registry can either be created by the salt state, or if one has been prepopulated and stored as an image, that image can be deployed instead.

#### - adding them to the rke2's local image cache
rke2 comes with the ability to place archived images in `/var/lib/rancher/rke2/agent/images`, which it then caches locally instead of needing to pull them. this is how the rke2 core images are loaded onto the server.

### gitlab runner 
`https://docs.gitlab.com/runner/executors/kubernetes/`
the gitlab runner kubernetes executor runs as a single container that spawns in new containers to perform jobs whenever it is given a job.

the gitlab runner is deployed to the kubernetes cluster using the helm chart. however, instead of applying the chart normally with the helm cli tool, it is instead deployed as a manifest using rke2's HelmChart crd. the main gitlab runner container image has been modified to add a ca trust certificate so that it can properly operate with custom certificates. for the helm chart, in order to comply with the rke2 cis profile's podSecurity requirements, the values.yaml has added a patch to each of the containers that the runner uses to configure their podSecurity. Lastly, in order to circumvent the isssue with coreDNS (details below), the gitlab server is added as a host alias to each of the pods.

## Security Implications
In order for RKE2 to operate without issues, firewalld, which interferes with canal's networking, must be disabled. iptables, which canal manages, still runs on the host node. With the gitlab runners, because they are essentially reverse shells, they introduce another potential vulnerability. Additionally, there are some secrets stored in plain text in the manifests on the server node (such as the gitlab runner registration token), which requires those files to be secured and potentially encrypted.

## Maintenance
the following tools are used to manage the cluster. both require the KUBECONFIG environment variable to be set to `/etc/rancher/rke2/rke2.yaml`.
- **rke2-killall.sh**
 - this script (located in `/usr/local/bin`) stops all rke2 processes, and can be useful when trying to restart processes when there's errors not fixed by restarting the systemd service.
- **Kubectl**  
  - this is the standard kubectl executable, but it is located in the `/var/lib/rancher/rke2/bin`
  - while resources can be created and deleted with this, it is *not* recommended to try to delete any resources deployed from `/var/lib/rancher/rke2/server/manifests`, as this will cause issues with removing the namespace.
  - it requires the KUBECONFIG environment variable to be correctly set
- **k9s** (docs here: `https://k9scli.io/`)
  - this tool is used to monitor and manage the cluster through a gui, located in `/usr/local/bin`
  - it also requires the KUBECONFIG environment variable to be correctly set  
it is recommended that when testing new resources to add to the cluster, that they are applied with `kubectl -f <file.yaml>`. once they are in a final form, they should then be added to the `/var/lib/rancher/rke2/server/manifests` directory. manifests placed here will be applied every time the service restarts.
  

## Removal
rke2 comes with the uninstall script `/usr/local/bin/rke2-uninstall.sh`, which completely uninstalls the cluster. the registry container can also be stopped by running `podman ps` to get the id of the container, and then `podman stop <container_id> && podman remove <container_id>`. additionally, the `/srv/images` and `/srv/scripts` directories can be removed from the system.

## Upgrade
upgrading the core kubernetes cluster involves:
- downloading the new image archives and binary
- deleting the old images (stored in `/var/lib/rancher/rke2/images/*`) and the old binary (stored in `/usr/local/bin/rke2`) and replacing them with the new ones
- restarting the kubernetes service

this can be done by running the [upgrade_deps.sh](upgrade_deps.sh) script and moving the created `deps.tar` file over to the airgapped network. on the airgapped network, move the file into `salt/files/upgrade/` on the salt master and apply the `k8s-upgrade` state.

## Known Issues

### helm chart crd's
rke2 provides a crd that deploys helm charts onto the cluster from a single manifest. however, these resources create finalizers that don't properly uninstall the namespace. the fix found here `https://github.com/k3s-io/helm-controller/issues/33#issuecomment-2439771780` works to get the namespace fully deleted:  
#### in the namespace configuration (either kubectl edit the namespae or edit it with k9s)
1. add this annotation: `helmcharts.helm.cattle.io/unmanaged: "true"`
2. set `metadata.finalizers: []` (delete the content that was there before)
3. the namespace should delete itself after this, but it can be deleted with kubectl or k9s

### deleting the auto-deploy manifests
although resources in `/var/lib/rancher/rke2/server/manifests` are deployed and modified by rke2, they are not deleted when the manifest files get deleted. this results in some resources not getting deleted when they should be, with `kubectl delete` or k9s's delete feature not working. this is why it is recommended to test manifests with `kubectl apply` and then move them to the auto-deploy directory when they are finalized.  
the easiest way to fix this is to run the `/usr/local/bin/rke2-uninstall.sh` script and re-apply the salt state.

### CoreDNS
currently coredns, which handles dns for the cluster's pod name resolution and name resolution for other hosts, does not properly work. in the logs, it shows an i/o timeout whenever trying to resolve names both inside and outside the cluster. coreDNS can actually hitting the correct dns server, but the connection is still timing out. while this appears to be a firewall issue, creating a network policy allowing all traffic for the namespace does not fix the issue. this issue is circumvented by the gitlab runners by setting the gitlab server host name on the containers themselves.

### metallb/traefik integration
currently, the following setup is used for ingress traffic:
`Outside Network -> External IP -> MetelLB -> Traefik -> Service -> Pod`  
sending requests to the external ip (using a dns hostname) works on the host node. however, attempting to access it outside the node does not work properly. metallb is configured to do an L2 advertisement of the service on the external IP, and then send those requests to traefik. the traffic is able to hit metallb, but it gives an error that it can't decrypt the message, which causes the connection to timeout on the client side. there has been limited success with getting this setup to work (by setting another service to use the external IP and then switching it back) but the issue remains largely unresovled.

## Future Improvements
### service tls configuration
`https://raymii.org/s/tutorials/Self_signed_Root_CA_in_Kubernetes_with_k3s_cert-manager_and_traefik.html`
using this guide, a configuration of tls for webservices had been started. the guide details creating a certificate authority for the root authority and an intermediate certificate authority that issues certificates for the services

### single image registry
currently, a docker registry container is being run on each node in the cluster, which takes up more space than necessary because each node has two copies of the images they need. a more efficient solution would be to change the service configuration to point to a singluar external registry that contains the necessary images.


## Contributions


## License
MIT License

Copyright (c) 2025 Brandon Baumgartner

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
