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
   1. [image](https://hub.docker.com/_/traefik)
   2. [helm chart]()
6. dashboard/management: rancher
7. CSI: longhorn

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

### [RKE2]([https://docs.rke2.io/install/methods#rpm](https://docs.rke2.io/install/airgap?_highlight=downloa#tarball-method))
- download the tarball of the RKE release you want
   - `curl -LO https://github.com/rancher/rke2/releases/download/v1.33.1%2Brke2r1/rke2-images.linux-amd64.tar.gz`

### [Rancher](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/other-installation-methods/air-gapped-helm-cli-install/install-rancher-ha)
for this installation i am deploying rancher on a docker container for simplicity. however, it is recommended to run it on a separate HA kubernetes cluster
1.  at the [rancher releases](https://github.com/rancher/rancher/releases) page, find the rancher v2.x.x release to install and under **Assets**, download the following
   1. rancher-images.txt
   2. rancher-save-images.sh
   3. rancher-load-images.sh
2. if you are not using your own certificates or not terminating TLS on an external load balancer, add the cert-manager images for the Rancher default self-signed certificates:
   1. `helm repo add jetstack https://charts.jetstack.io`
   2. `helm repo update`
   3. `helm fetch jetstack/cert-manager`
   4. `helm template ./cert-manager-<version>.tgz | awk '$1 ~ /image:/ {print $2}' | sed s/\"//g >> ./rancher-images.txt`
   5. `sort -u rancher-images.txt -o rancher-images.txt`
2. run rancher-save-images.sh
   1. `chmod +x rancher-save-images.sh`
   2. `./rancher-save-images.sh --image-list ./rancher-images.txt`
      1. this will take a lot of time, especially for newer installations
      2. **note:** if you are running podman, you may have an issue with pulling the images because of short-name resolution. to fix this, all lines in save-images.txt starting with `rancher/` need to have `docker.io/` prepended to them
         1. `sed -i '/rancher/s/^/docker.io\//' save-images.txt`
      2. **also note** [you may need to add storage if you run out](#giving-your-vm-more-storage)
4. rancher-load-images.sh to load them into the docker registry
5. 

#### Giving your VM more storage ####
1. using your vm hypervisor, increase the virtual disk size
   1. for virtualbox, go to **File->Tools->Virtual Media Manager**, select hte hard disk you want to increase the size of and then under **Attributes** increase the slider
2. download the gparted .iso image and boot the vm from it
   1. [get it here](https://gparted.org/download.php)
   2. reboot the vm and navigate the boot options when it is starting (f12 on rocky)
   3. boot from the cd and select the downloaded .iso file when prompted by virtualbox
3. after launching GParted use the GUI to increase the size of the partition that needs it
4. exit GParted and restart the system
5. after booting normally and logging in, run the following commands with root
   1. `lvextend -l +100%FREE /dev/mapper/rl_vbox-root` (that is a lowercase 'L')
   2. `xfs_growfs /`
6. the resized partition can be verified with `df -k /`

#### Adding cert-manager to the images




- `helm repo add rancher-stable https://releases.rancher.com/server-charts/stable`
- `helm fetch rancher-<CHART_REPO>/rancher

## Hauler
This is a service created by rancher that allows for moving files onto an airgapped network. It works as a server that can store images, files, and charts which it then compresses into a file that is moved to the airgap. On the airgap, the file is then extracted and another Hauler server runs to serve those files.

Installation:  
1. curl -sfL https://get.hauler.dev | bash
