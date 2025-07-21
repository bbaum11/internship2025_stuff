# Creating a salt state to automate the deployment of the hardened kubernetes cluster
i was initially going to do this by loading every image into a docker registry and then using those images to install everything. however, it is **significantly** easier to just download the tarballs and install like that. this way, the only images needed are just the ones for my services and the only files needed are the tarballs. the upgrade process is also very straightforward and simple.


## installation
```
mkdir /root/rke2-artifacts && cd /root/rke2-artifacts/
curl -OLs https://github.com/rancher/rke2/releases/download/v1.33.1%2Brke2r1/rke2-images.linux-amd64.tar.zst
curl -OLs https://github.com/rancher/rke2/releases/download/v1.33.1%2Brke2r1/rke2.linux-amd64.tar.gz
curl -OLs https://github.com/rancher/rke2/releases/download/v1.33.1%2Brke2r1/sha256sum-amd64.txt
curl -sfL https://get.rke2.io --output install.sh
INSTALL_RKE2_ARTIFACT_PATH=/root/rke2-artifacts sh install.sh
```

```
sudo cp -f /usr/share/rke2/rke2-cis-sysctl.conf /etc/sysctl.d/60-rke2-cis.conf
sudo systemctl restart systemd-sysctl
sudo sysctl -p /usr/local/share/rke2/rke2-cis-sysctl.conf
sudo useradd -r -c "etcd user" -s /sbin/nologin -M etcd -U
```
## to update:
1. download new tar files and replace the ones in `/var/lib/rancher/rke2/agent/images/`
2. replace the executable file `/usr/local/bin/rke2`
3. restart the service
