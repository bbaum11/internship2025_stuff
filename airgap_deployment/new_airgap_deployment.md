### downloading cri-o
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
5. 
