## Downloading all files to the workstation
- note that all container images need to be pushed to the private docker registry, while all other files must be placed into the httpd repository, preferably in a separate folder from the rpms.

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
`https://github.com/derailed/k9s/releases/download/v0.50.6/k9s_Linux_amd64.tar.gz`

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
