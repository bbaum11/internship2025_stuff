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
1. create internal network in VirtualBox
  1. list icon next to **Tools -> Network -> Host-only Networks**
  2. click **Create**
  3. **DHCP Server -> Enable Server**
  4. Set Upper and Lower bounds
2. on workstation, need 3 adapters
  - host-only adapter for internal network (set to new internal network)
  - host-only adapter (set to first internal network)
  - NAT adapter
3. on minion and child, need 1 adapter
  - host-only adapter for internal network (set to new internal network)
4. setting network interface
  - select vm -> **Settings -> Network -> Adapter x -> Enable Network Adapter**
  - choose adapter type under **Attached to**
  - for the host-only adapters, chose the correct network under **Name**

## connecting to the vm's from the host machine
