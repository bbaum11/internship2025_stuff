# remember to fix perms for the /srv/salt folder on the workstation

# Doing stuff with Salt

## setting up salt master
1. on the workstation, run `sudo dnf install salt-master`
2. enable salt traffic on the firewall with `sudo firewall-cmd --permanent --zone=public --add-port=4505-4506/tcp && sudo firewall-cmd --reload`


## setting up salt minion
1. add salt minion to the dnf repository
2. on the workstation and the master/minion machines, run `sudo dnf install salt-minion`
3. in **/etc/salt/minion**, uncomment the line `master: salt` and change it to `master: <workstation ip>`
  1. the minion's id can also be set by uncommenting the `id:` line

## accepting minions
- minion keys can be listed with `salt-key`
- they can be accepted with `salt-key -a <minion_id>'
- they can be denied with `salt-key -r <minion_id>`
- they can be deleted with `salt-key -d <minion_id>`
- all salt keys can be accepted with `salt-key -A`

## creating and running salt states
- the main salt state file is defined in **/srv/salt/top.sls**
- it is structured like so:
```base:
    '<minion_id>':
      - <path_to_sls>
      - <path_to_sls>
```
