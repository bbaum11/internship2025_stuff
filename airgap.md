# setting up the airgapped network

## install rocky linux boxes
- download the iso
    - [Download Link](https://rockylinux.org/download)
- create the vms
    - doing this later

## useful commands to setup network
- nmtui
  - gui that configures network interfaces
  - to enable ipv4 on inet
    - nmtui
    - activate connection
    - activate the interface/turn it off and back on
- ip a
	- shows the network interfaces and ip addresses
- shutdown -h now
	c-shuts down the system (needs root)

## how to set up network
1. create internal network in VirtualBox
    1. list icon next to **Tools -> Network -> Host-only Networks**
    2. click **Create**
    3. **DHCP Server -> Enable Server**
    4. Set Upper and Lower bounds
2. on workstation, need 3 adapters
    1. host-only adapter for internal network (set to new internal network)
    2. host-only adapter (set to first internal network)
    3. NAT adapter
3. on minion and child, need 1 adapter
    1. host-only adapter for internal network (set to new internal network)
4. setting network interface
    1. select vm -> **Settings -> Network -> Adapter x -> Enable Network Adapter**
    2. choose adapter type under **Attached to**
    3. for the host-only adapters, chose the correct network under **Name**

## connecting to the vm`s from the windows host machine
1. open PowerShell
2. **ssh-keygen**
3. **cd .ssh**
4. **notepad config**
5. Enter config settings in the template
6. Make sure the file has no file extension (saved as config, not confix.txt)
7. You can now use ssh to connect to the boxes using the set host names

## setting up ssh keys
1. 'ssh-copy-id -f -i <public key> <username>@<hostname>`

## getting dnf to work on the workstation
1. go to the [rocky downlaod link](https://mirrors.rockylinux.org/mirrormanager/)
2. select the icon left of the URL and navigate to **Connection is Secure** and view the certificate information
3. Navigate to **Details** and under **Certificate Hierarchy** select the top level dropdown and **Export**
4. save the file and move it onto the workstation inside of **etc/pki/ca-trust/source/anchors/** (need sudo)
5. On the workstation, enter **sudo update-ca-trust**

## next steps
dnf download
https
rpms into httpd folder
point machines to that server

1. install httpd, createrepo_c, yum-utils
2. create folder in /var/www/html
3. Do this if you want to download everything: **'dnf reposync -g -m —download-metadata -p /var/www/html/<repo>`**
4. Otherwise download individual rpms with **'dnf download <package>`**
5. Add the following in /etc/httpd/conf/httpd.conf:
`<VirtualHost *:80>`
	ServerName `<server_ip>`
 	DocumentRoot /var/www/html/`repo>`
  	`<Directory /var/www/html/<repo>/>`
   		Options Indexes
   	`</Directory>`
`</VirtualHost>`

enable http on firewall **firewall-cmd --zone=public -add-service=http --permanent** && **firewall-cmd reload**

on the client machines in /etc/yum.repos.d:
[name_of_repo]
name=name of repo
baseurl=http://`<server_ip>`/`<directorynameofrepo>`
enabled=1
gpgcheck=0

remove all other files in /etc/yum.repos.d/


**TODO**
delete welcome message and config on workstation
