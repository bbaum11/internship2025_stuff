## Downloading all files to the workstation
- note that all container images need to be pushed to the private docker registry, while all other files must be placed into the httpd repository, preferably in a separate folder from the rpms.
`sudo dmesg -n 1`

### setting up pushing to/pulling from docker registry 
by default, podman attempts to use https for traffic with a docker registry. to fix this, add the following in `/etc/containers/registries.conf`
```
[[registry]]
  location = "<wks_ip>:5000"
  insecure = true
```

### downloading the container engine (cri-o)
1. set the following environment variables:
```
KUBERNETES_VERSION=v1.32
CRIO_VERSION=v1.32
```
2. add the kubernetes and crio repositories
```
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/repodata/repomd.xml.key
EOF
```
```
cat <<EOF | tee /etc/yum.repos.d/cri-o.repo
[cri-o]
name=CRI-O
baseurl=https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/rpm/repodata/repomd.xml.key
EOF
```
3. download the dependencies to the local repository  
`dnf download --alldep --resolve container-selinux`
4. download the crio, kubelet, kubeadm, and kubectl packages  
`dnf download --alldep --resolve cri-o kubelet kubeadm kubectl`

### downloading the crictl tarball
1. download the tar file  
`curl -L -O https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.33.0/crictl-v1.33.0-linux-amd64.tar.gz`

### downloading the k9s tarball
1. download the tar file  
`curl -L -O https://github.com/derailed/k9s/releases/download/v0.50.6/k9s_Linux_amd64.tar.gz`

### downloading longhorn's files
1. download the list of needed images  
`wget https://raw.githubusercontent.com/longhorn/longhorn/v1.9.0/deploy/longhorn-images.txt`
2. download the script to pull the images onto the local machine  
`wget https://raw.githubusercontent.com/longhorn/longhorn/v1.9.0/scripts/save-images.sh`
3. download the script to push the images to a private repository  
`wget https://raw.githubusercontent.com/longhorn/longhorn/v1.9.0/scripts/load-images.sh`
4. run the **save-images.sh** script  
```
chmod +x save-images.sh
./save-images.sh --image-list longhorn-images.txt --images longhorn-images.tar.gz
```
5. run the **load-images.sh** script  
```wget https://raw.githubusercontent.com/longhorn/longhorn/v1.9.0/scripts/load-images.sh
chmod +x load-images.sh  
./load-images.sh --image-list longhorn-images.txt --images longhorn-images.tar.gz --registry <DOCKER-REGISTRY>
```
6. download the manifest file  
`wget https://raw.githubusercontent.com/longhorn/longhorn/v1.9.0/deploy/longhorn.yaml`

### downloading calico's files
1. pull the calico operator image and push it to the local docker registry. note that the operator version doesn't match the calico version. the operator releases are [here](https://github.com/tigera/operator/releases)
```
#!/bin/bash

#Adjust the variables below to your environment

registry=<DOCKER-REGISTRY>
repository=<REPOSITORY-NAME>
version=v1.38.3

#The images list contains all components operator must be able to deploy

images=(
typha:"${version}"
cni:"${version}"
pod2daemon-flexvol:"${version}"
node:"${version}"
kube-controllers:"${version}"
)

for image in "${images[@]}"
do
  :
  docker pull calico/$image
  docker tag calico/$image $registry/$repository/$image
  docker push $registry/$repository/$image
done

docker pull quay.io/tigera/operator:v1.15.1
docker tag quay.io/tigera/operator:v1.15.1 <DOCKER-REGISTRY>/REPOSITORY-NAME>/operator:v1.15.1
docker push <DOCKER-REGISTRY>/REPOSITORY-NAME>/library/operator:v1.15.1
```
2. download the calico manifests
```
curl -L https://docs.projectcalico.org/manifests/tigera-operator.yaml -o tigera-operator.yaml
curl -L https://docs.projectcalico.org/mfanifests/custom-resources.yaml -o custom-resources.yaml
```

### downloading the files for canal
```
#!/bin/bash

images=$(podman images --format '{{.Repository}}:{{.Tag}}' | grep -e calico -e flannel)

for image in $images; do
        echo "tagging: $image"
        path_tag="${image#docker.io/}"

        podman tag "${image}" "192.168.47.102:5000/$path_tag"
done
```
```
#!/bin/bash

images=$(podman images --format '{{.Repository}}:{{.Tag}}' | grep '^192' | grep -e flannel -e calico)

for image in $images; do
        echo "Pushing: $image"
        podman push "$image"
        if [ $? -ne 0 ]; then
                echo "failed pushing $image"
        else
                echo "pushed $image"
        fi
done
```


### downloading the necessary files for kuberenetes
```
images=(
  "registry.k8s.io/kube-apiserver:v1.32.6"
  "registry.k8s.io/kube-controller-manager:v1.32.6"
  "registry.k8s.io/kube-scheduler:v1.32.6"
  "registry.k8s.io/kube-proxy:v1.32.6"
  "registry.k8s.io/coredns/coredns:v1.11.3"
  "registry.k8s.io/pause:3.10"
  "registry.k8s.io/etcd:3.5.16-0"
)

for image in "${images[@]}"; do
  docker pull "$image"
  image_name=$(echo "$image" | sed 's|/|_|g' | sed 's/:/_/g')
  docker save -o "${image_name}.tar" "$image"
done
```

### downloading the k3s files
1. download the airgap images .tar.zst file from the [releases page](https://github.com/k3s-io/k3s/releases)
2. extract the images locally:
`docker image load -i k3s-airgap-images-amd64.tar.zst`
3. retag each of the images to beign with the docker registry's ip
`podman tag localhost/rancher/<image>:<tag> <wks_ip>:5000/rancher/<image>:<tag>
4. push each image to the docker registry
```
images=$(podman images --format '{{.Repository}}:{{.Tag}}' | grep '^<wks_ip>')

for image in $images; do
  echo "Pushing: $image"
  podman push "$image"
done
```
5. download the k3s binary for the same release on the releases page
6. download the installation script
`wget https://get.k3s.io/ --output-document=install.sh`



## Installing k3s

### troubleshooting k3s
- private registry not working
  - edit /etc/systemd/system/k3s.service
    - add `--private-registry=/etc/rancher/k3s/registries.yaml ` under execstart
  - edit /etc/rancher/k3s/repositories.yaml
    - add this
```
mirrors:
  "192.168.47.102:5000":
    endpoint:
      - "http://<WORKSTATION_IP>:5000"
  docker.io:
    endpoint:
      - "http://<WORKSTATION_IP>:5000"
```

### installing on the master
1. download the k3s binary and installation script
`curl -L -O http://<WORKSTATION_IP>/path/to/file`
2. change the binary ownership to root, move it to /usr/local/bin, and change the SELinux permissions
`sudo chown root:root k3s`
`sudo mv k3s /usr/local/bin/.`
`sudo restorecon -v /usr/local/bin/k3s`
3. create the file /etc/rancher/k3s/repositories.yaml
```
mirrors:
  docker.io:
    endpoint:
      - "http://<WORKSTATION_IP>:5000"
```
4. run the installation script
`INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_SKIP_START=true ./install.sh`
5. edit **/etc/systemd/system/k3s.service** to add the following after **server** under **ExecStart**:
```
    --disable servicelb \
    --disable-cloud-provider \
    --flannel-backend none \
    --private-registry /etc/rancher/k3s/registries.yaml \
```
6. run `systemctl daemon-reload`
7. start the k3s service with `systemctl start k3s`

### Installing Canal
1. get the canal manifest
2. because flannel and k3s use different default CIDR blocks (10.244.0.0/16 and 10.42.0.0/16 respectively), one of the configs needs to be changed. for this case, the canal.yaml config will be changed as shown:
```
  # Flannel network configuration. Mounted into the flannel container.
  net-conf.json: |
    {
      "Network": "10.42.0.0/16",
      "Backend": {
        "Type": "vxlan"
      }
    }
```
3. apply the manifest
`k3s kubectl apply -f canal.yaml`

### Installing Longhorn
1. install open-iscsi
  1. on the workstation:
  `dnf download --resolve --alldep iscsi-initiator-utils`
  `createrepo <REPO_PATH>`
  3. on the master node:
  `dnf update --refresh`
  `dnf install iscsi-initiator-utils -y`
5. create the longhorn namespace
`k3s kubectl create namespace longhorn-system`
6. apply the manifest
`k3s kubectl apply -f longhorn.yaml`
