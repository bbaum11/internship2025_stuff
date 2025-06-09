# comparison of different k8s technologies

## need to research:
- container engine
- container networking interface
- container storage interface
- ingress
- load-balancer
- secrets store
- kubernetes platform
- kubernetes interface

### container runtimes manage:
- container life-cycle
- image transfer and storage
- container execution and supervision
- storage and network attachments


## container engines

### docker
- not supported for kubernetes 1.24+
- not ideal
- does not have a CNI, implements its own
  - uses container network model (CNM)

### podman
- uses runc by default, which (i am pretty sure) doesn't implement CRI
- can be used with other runtimes to work with kubernetes

### `cri-o`
- designed for kubernetes
- non-root
- lightweight
- minimal components to focus on execution
- doesn't need extra configuration to work with k8s

### containerd
- dependency for docker
  - bascially the low-level part that docker runs off of
- interfaces directly with the os
- good if you want to access core functionality of the containers
- lower cpu usage than docker
- not meant to be used direcctly by end-users

## container networking interface

### `cilium`
- most popular CNI
- most difficult to use
- built with eBPF
  - runs without modifying the kernel source code or loading new kernel modules

### calico
- puts routes into OS routing table
- good for use with a team that is familiar with linux networking

### flannel

## container storage interfaces
### `Rook Ceph`
- distributed storage
- fast and stable
- doesn't require much effort to maintain after setting up

### Longhorn
- lightweight
- good for small clusters
- good for bare metal kubernetes

### OpenEBS
- easy integration with kubernetes
- container-native storage
- can also be deployed as a container
- not as scalable for large deployments

### GlusterFS
- backed by RedHat
- provides RESTful interface (Heketi) that can automate k8s volume provisioning
- not kubernetes-native
  - relatively new
    - only updated after users encounter significant bugs
  - still supports kubernetes integration


## ingress/load balancer
i believe i am trying to find an ingress controller?  
[community spreadsheet of ingress controller comparisons](https://docs.google.com/spreadsheets/d/191WWNpjJ2za6-nbG4ZoUMXMpUK8KlCIosvQB0f-oq3k/edit?gid=907731238#gid=907731238)

### ingress nginx
- no support for TCP+TLS and partial support for UDP
- less user-friendly
- more fine-grained control
- routes must be set and configured manually
- requires a reload to update config changes
- less dynamic
- better for prod environments?

### `traefik`
- support for all protocols except http 3
- only basic, external, and client cretificate authentication is available for the free version
- provides a dashboard
- fewer load balancing strategies compared to other options
  - not sure if this necessarily means the performance is worse in this regard
- fully dynamic config reload
- more difficult to tune under a heavy load
- better for dev environments?

## secrets store
### HashiCorp Vault
- secrets are stored in a centralized place and require authentication to access
- runs as a server

### Bitnami Sealed Secrets
- secrets are encrypted and then stored in the repo
- a kubernetes object is created and encrypted by the service
- much easier for a smaller setup

## kubernetes interface
### kubectl
- main way to interface with the cluster on the command line

### `kubernetes dashboard`
- developed by kubernetes
- easy to deploy
- authentication needs to be configured
- no native multi-cluster, metrics, logs or monitoring

### lens
- multi-cluster support
- auto detects clusters
- easy access to logs, metrics, and events
- no web interface; desktop only
- not really ideal since you would need a gui


## kubernetes platform
### vanilla kubernetes
- i mean it's kubernetes

### openshift
- security presets
- good for multiple clusters
- expensive
- comes with gui dashboard

### rancher
- made to work with longhorn
- should be run in its own cluster
- provides a gui
