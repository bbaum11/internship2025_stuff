# setting up the airgapped network

## install rocky linux boxes
- download the iso
  - https://rockylinux.org/download
-create the vms
  - doing this later

## useful commands to setup network
- nmtui
  - gui that configures network interfaces
  - to enable ipv4 on inet
    1. nmtui
    2. activate connection
    3. activate the interface/turn it off and back on
- ip a
  - shows the network interfaces and ip addresses
- shutdown -h now
  -shuts down the system (needs root)

## how to set up network
1. on workstation, need 3 adapters
  - internal network
  - host-only adapter
  - NAT adapter
2. on minion and child, only need 1 adapter for internal network
3. on windows machine, do 'ssh-keygen' and create .ssh/config
  - create with the following lines:
    -
