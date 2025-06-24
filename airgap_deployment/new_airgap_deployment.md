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


### downloading the files for canal
`curl https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/canal.yaml -O`
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

### setting up k9s
1. allow traffic on port 10250 to allow the metrics server to communicate with the host
`sudo firewall-cmd --add-port=10250/tcp --permanent`
`sudo firewall-cmd --reload`
