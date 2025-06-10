# 2 main issues
1. won't list files outside of /var/www/html unless it's a directory
2. can't get it to install createrepo when it's a pillar
# remember to fix perms for the /srv/salt folder on the workstation


# Doing stuff with Salt
- [files for salt folder](srv/salt)
- [files for pillar folder](srv/pillar)

## setting up salt master
1. on the workstation, run `sudo dnf install salt-master`
2. enable salt traffic on the firewall with `sudo firewall-cmd --permanent --zone=public --add-port=4505-4506/tcp && sudo firewall-cmd --reload`
3. run `systemctl enable salt-master --now`


## setting up salt minion
1. add salt minion to the dnf repository
2. on the workstation and the master/minion machines, run `sudo dnf install salt-minion`
3. in **/etc/salt/minion**, uncomment the line `master: salt` and change it to `master: <workstation ip>`
  1. the minion's id can also be set by uncommenting the `id:` line
4. run `systemctl enable salt-minion --now`

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
- pillars are defined in **/srv/pillar/top.sls** and can be broken into seperate files the same as in the other top file
- the salt state file can be run with `salt '*' state.apply pillar='{"field": "value"}'
  - where 'pillar' is an optional argument that can create pillar values to be used in the code. in my implementation, a pillar is used for **server_ip**, the address of the workstation on the internal network.
