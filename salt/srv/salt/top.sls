# this needs to be run with the parameter server_ip=<wks_internal_ip>

# file structure
# /srv/
#   | -- pillar/
#   |    | -- common_apps
#   |    | -- top
#   |    | -- wks_apps 
#   |
#   | -- salt/
#        | -- common/
#        |    | -- install_programs
#        |
#        | -- k8s/
#        |    | -- yum_repo
#        |
#        | -- wks/
#        |    | -- compose.yaml
#        |    | -- configure_httpd
#        |    | -- docker_registry
#        |    | -- populate_rpm_repo
#        |
#        | -- top

base:
    'wks':
        - common/install_programs
        - wks/configure_httpd
        - wks/populate_rpm_repo
        - wks/docker_registry
#     'k8s*': # this wouldn't be possbile to automate
#         - k8s/yum_repo
        