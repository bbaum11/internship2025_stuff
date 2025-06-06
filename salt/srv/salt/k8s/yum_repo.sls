{% set server_ip = salt['pillar.get']('server_ip', 'enter_ip_in_config') %}

move_repos:
    cmd.run:
        - name: mv /etc/yum.repos.d/ /etc/yum.repos.d.backup/

yum_repo:
    file.managed:
        - name: /etc/yum.repos.d/wks.repo
        - contents: |
            name=workstation repo
            baseurl=http://{{server_ip}}/
            enabled=1
            gpgcheck=0
        - user: root


