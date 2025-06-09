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
it is really hard to find information that doesn't conflict about whether an engine's runtime implements CRI

### docker
- not supported for kubernetes 1.24+
- not ideal
- does not have a CNI, implements its own
  - uses container network model (CNM)

### podman
- i am getting a ton of conflicting information aobut whether podman's default container runtime implements CRI
- however, the runtime can be changed to one that does implement it

### cri-o
- this seems like the option that most sources are pushing for

### containerd
- dependency for docker
  - bascially the low-level part that docker runs off of
- interfaces directly with the os
- good if you want to access core functionality of the containers
- lower cpu usage than docker
- not meant to be used direcctly by end-users

## container networking interface
###

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

