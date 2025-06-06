install_epel:
    cmd.run:
        - name: 'dnf install -y epel-release.noarch'

install_docker:
    cmd.run:
        - name: 'dnf install -y podman-compose'

# this section isn't necessary because the file would need to be on the workstation anyways
# get_compose_file:
#     file.managed:
#         - name: /srv/compose.yaml
#         - source: salt://wks/compose.yaml

start_registry:
    cmd.run:
        - name: 'podman compose -f /srv/salt/wks/compose.yaml up -d'