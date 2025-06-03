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
    - nmtui
    - activate connection
    - activate the interface/turn it off and back on
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
  1. host-only adapter for internal network (set to new internal network)
  2. host-only adapter (set to first internal network)
  3. NAT adapter
3. on minion and child, need 1 adapter
  1. host-only adapter for internal network (set to new internal network)
4. setting network interface
  1. select vm -> **Settings -> Network -> Adapter x -> Enable Network Adapter**
  2. choose adapter type under **Attached to**
  3. for the host-only adapters, chose the correct network under **Name**

## connecting to the vm's from the host machine
