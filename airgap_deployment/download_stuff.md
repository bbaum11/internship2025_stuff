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
