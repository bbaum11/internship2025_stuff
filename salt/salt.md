# Doing stuff with Salt

## setting up salt master
1. on the workstation, run `sudo dnf install salt-master`
2. enable salt traffic on the firewall with `sudo firewall-cmd --permanent --zone=public --add-port=4505-4506/tcp && sudo firewall-cmd --reload`


## setting up salt minion
1. add salt minion to the dnf repository
2. on the workstation and the master/minion machines, run `sudo dnf install salt-minion`
3. in **/etc/salt/minion**, uncomment the line `master: salt` and change it to `master: <workstation ip>`

## TODO: build salt orchestration file
