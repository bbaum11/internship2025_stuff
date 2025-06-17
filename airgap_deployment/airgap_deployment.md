# Process of setting up on VM

## things needed do download
1. engine: rke2
   1. CNI: canal
2. hauler
2. helm
   1. also install on workstation to pull charts
   2. git is a dependency
3. load balancer: metallb
4. ingress: traefik
5. dashboard/management: rancher
6. CSI: longhorn

dnf repo:
- rke2-server
- rke2-agent
- git
- docker (to deploy rancher)

curl'd binaries
- hauler
- helm

helm charts
- rancher
- metallb
- traefik
- longhorn

## downloading everything that will be installed on the air gap

### [RKE2](https://docs.rke2.io/install/methods#rpm)
The rancher repository needs to be added as a mirror in order to download the RPM's for the rpm repo.

1. run this bash snippet:  
```
export RKE2_MINOR=28
export LINUX_MAJOR=9 # or 8 or 7 etc
cat << EOF > /etc/yum.repos.d/rancher-rke2-1-${RKE2_MINOR}-latest.repo
[rancher-rke2-common-latest]
name=Rancher RKE2 Common Latest
baseurl=https://rpm.rancher.io/rke2/latest/common/centos/${LINUX_MAJOR}/noarch
enabled=1
gpgcheck=1
gpgkey=https://rpm.rancher.io/public.key

[rancher-rke2-1-${RKE2_MINOR}-latest]
name=Rancher RKE2 1.${RKE2_MINOR} Latest
baseurl=https://rpm.rancher.io/rke2/latest/1.${RKE2_MINOR}/centos/${LINUX_MAJOR}/x86_64
enabled=1
gpgcheck=1
gpgkey=https://rpm.rancher.io/public.key
EOF
```
2. download with `dnf download --alldep --resolve rke2-server` and `dnf download --alldep --resolve rke2-agent`
3. createrepo the local rpm repo

## Hauler
This is a service created by rancher that allows for moving files onto an airgapped network. It works as a server that can store images, files, and charts which it then compresses into a file that is moved to the airgap. On the airgap, the file is then extracted and another Hauler server runs to serve those files.

Installation:  
1. curl -sfL https://get.hauler.dev | bash

### MetalLB


### [Rancher](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/other-installation-methods/air-gapped-helm-cli-install/install-rancher-ha)
- helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
- `helm fetch rancher-<CHART_REPO>/rancher
