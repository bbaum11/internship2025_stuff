## Downloading all files to the workstation
- note that all container images need to be pushed to the private docker registry, while all other files must be placed into the httpd repository, preferably in a separate folder from the rpms.
- [here is a script to download the necessary files and images](dependency/dependency-download.sh)
- [here is a script to retag all the files and load them into the private docker registry]()
- `sudo dmesg -n 1`

### setting up pushing to/pulling from private docker registry 
by default, podman attempts to use https for traffic with a docker registry. to fix this, add the following in `/etc/containers/registries.conf`
```
[[registry]]
  location = "<wks_ip>:5000"
  insecure = true
```

## Installing k3s
1. download the k3s binary and installation script
`curl -L -O http://<SERVER_IP>/path/to/file`
2. change the binary ownership to root, move it to /usr/local/bin, and change the SELinux permissions
```
sudo chown root:root k3s
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

### important notes
- none of the pods will be installed and started until the CNI is installed
- in order to use the built-in tools that come with k3s (kubectl, ctr, crictl, etc), they need to be preceded with `k3s` (ex. `k3s kubectl <args>`)

### Installing Canal
1. get the canal manifest
2. by default, k3s uses 10.42.0.0/16 as a CIDR block for cluster IP addresses, while flannel uses 10.244.0.0/16. In order for the CNI to work, these two CIDR blocks need to match. it is easiest to edit the canal manifest to do this. in `canal.yaml`: 
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

### Installing metallb
1. get the metallb manifest

### Deploying an nginx service
1. get the 

### setting up ingress
1. k3s is recommended to be used without firewalld, which doesn't play nicely with the many network interfaces created. however, if firewalld is still desired, it can be configured to work with k3s as shown below:
```
firewall-cmd --permanent --add-port=6443/tcp #apiserver
firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16 #pods
firewall-cmd --permanent --zone=trusted --add-source=10.43.0.0/16 #services
firewall-cmd --reload
```
2. for traefik to work as an ingress, a DNS hostname needs to be set up that routes to its external IP. for testing purposes, `test.test` will be used as a local hostname. in `/etc/hosts`, add the following line:  
`<TRAEFIK_IP>  test.test`
3. now, an ingress route needs to be configured. a **.yaml** file needs to be created as shown below. for testing purposes, `/web` will be used to verify that traffic is properly being routed to the correct service. if a request goes through traefik and it is not to a configured service, a 404 error will be given.
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress-rule
  namespace: default
spec:
  rules:
    - host: test.test
      http:
        paths:
          - path: /web
            pathType: Prefix
            backend:
              Service:
                name: nginx
                port:
                  number: 80
```
4. apply the manifest with `k3s kubectl apply -f <ingress_manifest_file>`
5. to test, send a request with `curl test.test/web`. this should return the same thing as the service's endpoint (run `k3s kubectl get endpoints` to see)

### setting up k9s
1. allow traffic on port 10250 to allow the metrics server to communicate with the node host
`sudo firewall-cmd --add-port=10250/tcp --permanent`  
`sudo firewall-cmd --reload`
2. get the k9s tarball
3. extract the executable from the tarball
4. run with `k9s --kubeconfig /etc/rancher/k3s/k3s.yaml`



### Installing Longhorn
1. install open-iscsi  
`dnf install iscsi-initiator-utils -y`
5. create the longhorn namespace  
`k3s kubectl create namespace longhorn-system`
6. apply the manifest  
`k3s kubectl apply -f longhorn.yaml`



