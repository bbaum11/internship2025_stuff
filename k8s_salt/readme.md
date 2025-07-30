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
 '*server*':
   - hardening/config_file
   - installation/services
   - ...
 '*agent*':
   - hardening/worker_config_file
   - installation/rke2_worker_init
   - ...
```


## Architecture
### kubernetes core
in place of upstream kubernetes, Rancher Kubernetes Engine 2 was used as the kubernetes distribution. it comes packaged with the following components:
- the rke2 implementation of `kubelet`?
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
the gitlab runner is deployed to the kubernetes cluster using the helm chart. however, instead of applying the chart normally with the helm cli tool, it is instead deployed as a manifest using rke2's HelmChart crd. 

## Security Implications
In order for RKE2 to operate without issues, firewalld, which interferes with canal's networking, must be disabled. 

## Maintenance
the following tools are used to manage the cluster. both require the KUBECONFIG environment variable to be set to `/etc/rancher/rke2/rke2.yaml`.
- **Kubectl**  
  - this is the standard kubectl executable, but it is located in the `/var/lib/rancher/rke2/bin`
  - while resources can be created and deleted with this, it is *not* recommended to try to delete any resources deployed from `/var/lib/rancher/rke2/server/manifests`, as this will cause issues with removing the namespace.
  - it requires the KUBECONFIG environment variable to be correctly set
- **k9s**  
  - this tool is used to monitor and manage the cluster through a gui, located in `/usr/local/bin`
  - it also requires the KUBECONFIG environment variable to be correctly set
resources can be added normally with kubectl, but the recommended way is to place the manifests into `/var/lib/rancher/rke2/server/manifests`. this deploys them automatically every time the server is restarted.

## Removal
uh...

## Upgrade
upgrading the core kubernetes cluster involves:
- downloading the new image archives and binary
- deleting the old images (stored in `/var/lib/rancher/rke2/images/*`) and the old binary (stored in `/usr/local/bin/rke2`) and replacing them with the new ones
- restarting the kubernetes service

this can be done by running the [upgrade_deps.sh](upgrade_deps.sh) script and moving the created `deps.tar` file over to the airgapped network. on the airgapped network, move the file into `salt/files/upgrade/` on the salt master and apply the `k8s-upgrade` state.

## Contributions

## License
