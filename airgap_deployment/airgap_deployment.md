## Downloading all files to the workstation
- note that all container images need to be pushed to the private docker registry, while all other files must be placed into the httpd repository, preferably in a separate folder from the rpms.
- [here is a script to download the necessary files and images](dependency/dependency-download.sh)
- `sudo dmesg -n 1`

### setting up pushing to/pulling from private docker registry 
by default, podman attempts to use https for traffic with a docker registry. to fix this, add the following in `/etc/containers/registries.conf`
```
[[registry]]
  location = "<wks_ip>:5000"
  insecure = true
```


## Installing k3s
*note that none of the pods will be able to be installed and started until a CNI is installed*
1. download the k3s binary and installation script
`curl -L -O http://<SERVER_IP>/path/to/file`
2. change the binary ownership to root, move it to /usr/local/bin, and change the SELinux permissions
```
sudo chown root:root k3s`
sudo mv k3s /usr/local/bin/.
sudo restorecon -v /usr/local/bin/k3s
```
3. create the file `/etc/rancher/k3s/repositories.yaml`. this allows the private docker registry to act as a mirror for docker.io, quay.io, and ghcr.io
```
mirrors:
  docker.io:
    endpoint:
      - "http://<REGISTRY_IP>:5000"
  quay.io:
    endpoint:
      - "http://<REGISTRY_IP>:5000"
  ghcr.io:
    endpoint:
      - "http://<REGISTRY_IP>:5000"
```
4. run the installation script
`INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_SKIP_START=true ./install.sh`
5. edit **/etc/systemd/system/k3s.service** to add the following after **server** under **ExecStart**:
```
    --disable servicelb \
    --flannel-backend none \
    --private-registry /etc/rancher/k3s/registries.yaml \
    --cluster-init \
```
6. in order for the k3s server to start, a default route needs to be configured. if there isn't one for the system running it, a dummy route can be configured for testing purposes with:
```
ip link add dummy0 type dummy
ip link set dummy0 up
ip addr add xxx.xxx.xxx.254/31 dev dummy0
ip route add default via xxx.xxx.xxx.255 dev dummy0 metric 1000
```
8. run `systemctl daemon-reload`
9. start the k3s service with `systemctl start k3s`

### Installing Canal
1. get the canal manifest
2. because flannel and k3s use different default CIDR blocks (10.244.0.0/16 and 10.42.0.0/16 respectively), one of the configs needs to be changed. for this case, the canal.yaml config will be changed as shown:
3. by default, k3s uses 10.42.0.0/16 as a CIDR block for cluster IP addresses, while flannel uses 10.244.0.0/16. In order 
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

### setting up k9s
1. allow traffic on port 10250 to allow the metrics server to communicate with the host
`sudo firewall-cmd --add-port=10250/tcp --permanent`  
`sudo firewall-cmd --reload`
2. get the k9s tarball
3. extract the executable from the tarball
4. run with `k9s --kubeconfig /etc/rancher/k3s/k3s.yaml



### setting up ingress
```
firewall-cmd --permanent --add-port=6443/tcp #apiserver
firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16 #pods
firewall-cmd --permanent --zone=trusted --add-source=10.43.0.0/16 #services
firewall-cmd --reload
```
