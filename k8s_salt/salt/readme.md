# Automating the deployment of a kubernetes cluster with salt
- Description of project
 
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

## Removal
uh...

## Upgrade
upgrading the core kubernetes cluster involves:
- downloading the new image archives and binary
- deleting the old images (stored in `/var/lib/rancher/rke2/images/*`) and the old binary (stored in `/usr/local/bin/rke2`) and replacing them with the new ones
- restarting the kubernetes service

## Contributions

## License
