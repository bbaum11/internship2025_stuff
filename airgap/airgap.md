# setting up the airgapped network

## install rocky linux boxes
- download the iso
    - [Download Link](https://rockylinux.org/download)
- create the vms
    - open virtualbox
    - Select **New**
    - select the rocky iso for **ISO Image**
    - Set a name under **Name and Operating System** and uncheck **Unattended Install**
    - Modify hardware resources under **Hardware** as desired
    - Select **Finish**
- [fix for image checksum error](https://sangkyu519.medium.com/install-rhel-with-virtualbox-fix-checksum-error-daba1bf566b0) if you performed an unattended install

## how to set up network
1. create internal network in VirtualBox
    1. list icon next to **Tools -> Network -> Host-only Networks**
    2. click **Create**
    3. **DHCP Server -> Enable Server**
    4. Set Upper and Lower bounds
2. on workstation, need 2 adapters
    1. host-only adapter for internal network and access from host machine (set to new internal network)
    2. NAT adapter
3. on minion and child, need 1 adapter
    1. host-only adapter for internal network (set to new internal network)
4. setting network interface
    1. select vm -> **Settings -> Network -> Adapter x -> Enable Network Adapter**
    2. choose adapter type under **Attached to**
    3. for the host-only adapters, chose the correct network under **Name**

## useful commands
- nmtui
  - tui that configures network interfaces
  - if dhcp is not working (ipv4 addresses not showing up)
  	- `nmtui`
	- **Activate connection**
	- activate the interface/turn it off and back on
- ip a
	- shows the network interfaces and ip addresses

## connecting to the vms from the windows host machine
1. open PowerShell
2. **ssh-keygen**
3. **cd .ssh**
4. **notepad config**
5. Enter config settings in the template
6. Make sure the file has no file extension (saved as config, not confix.txt)
7. You can now use ssh to connect to the boxes using the set host names

## setting up ssh key authentication
1. move the **\*.pub** key onto the workstation
2. create a .ssh folder in the home directory if there isn't one
3. run `cat \<key>.pub >> authorized_keys`
4. on the workstation, run `ssh-copy-id -f -i <public key> <username>@<hostname>` to move the key onto the master/minion boxes


## setting up the dnf registry

### workstation side
1. install and configure httpd
	1. `sudo dnf install httpd createrepo_c yum-utils`
	2. create a folder in **var/www/html**
	3. Add the following in **/etc/httpd/conf/httpd.conf**:  
```<VirtualHost *:80>  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;    ServerName \<server_ip>  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 	DocumentRoot /var/www/html/\<repo>  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;  	<Directory /var/www/html/\<repo>/  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;   		Options Indexes  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;   	\</Directory>  
\</VirtualHost>```
	4. enable http traffic on the firewall: `firewall-cmd --zone=public -add-service=http --permanent && firewall-cmd reload`
 	5. comment out all lines in **/etc/httpd/conf.d/welcome.conf**

#### troubleshooting package installation difficulties
if using a proxy, ensure proper certificate is used for rocky packages
1. go to the [rocky download link](https://mirrors.rockylinux.org/mirrormanager/)
2. select the icon left of the URL and navigate to **Connection is Secure** and view the certificate information
3. Navigate to **Details** and under **Certificate Hierarchy** select the top level dropdown and **Export**
4. save the file and move it onto the workstation inside of **etc/pki/ca-trust/source/anchors/** (need sudo)
5. On the workstation, enter **sudo update-ca-trust**

### master/minion side
1. on the client machines in **/etc/yum.repos.d**, make a file ending in .repo containing the following:  
```\[wks_repo]  
name=workstation repo  
baseurl=http://\<server_ip>/  
enabled=1  
gpgcheck=0```
2. move all other .repo files out of the **/etc/yum.repos.d** folder

### to install programs onto the master and minion machines
- do this if you want to download every possible package to the workstation: `dnf reposync -g -m —download-metadata -p /var/www/html/<repo>`
- otherwise download individual rpms on the workstation by navigating to the repository folder and `dnf download --alldep --resolve <package>`
- then run `repocreate ./`
- then use `dnf install` on the master/minion machine as normal

## setting up the docker registry
1. visit a site like [this one](https://www.composerize.com/) to create a docker compose file or do it manually for this command:
	1. `docker run -d -p 5000:5000 --restart always --name registry registry:2`
2. on the workstation, run the following:
3. `sudo dnf install epel-release.noarch`
4. `dnf provides podman-compose`
5. `sudo dnf install docker-compose-plugin`
6. move the docker compose file onto the workstation and `run sudo docker compose up -d`
