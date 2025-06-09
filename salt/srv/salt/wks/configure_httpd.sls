{% set server_ip = salt['pillar.get']('server_ip', 'ip not entered') %}

create_repo_folder:
    file.directory:
        - name: /srv/repo

install_httpd:
    pkg.installed:
        - name: httpd
        - refresh: True
                    

#config_the_config:
#    file.append:
#        - name: /etc/httpd/conf/httpd.conf
#        - text: |
#            <VirtualHost *:80>
#                ServerName {{server_ip}}
#                DocumentRoot /srv/repo
#                <Directory /srv/repo/
#                    Options Indexes
#                </Directory>
#            </VirtualHost>           

change_root:
    file.replace:
        - name: /etc/httpd/conf/httpd.conf
        - pattern: DocumentRoot .*
        - repl: DocumentRoot /srv/repo

add_repo_dir_perms:
    file.append:
        - name: /etc/httpd/conf/httpd.conf
        - text: |
            <Directory "/srv/repo">
                Options All Indexes FollowSymLinks
                AllowOverride None
                Require all granted
            </Directory>

remove_welcome:
    file.absent:
        - name: /etc/httpd/conf.d/welcome.conf
        - watch_in:
            - service: start_httpd
        - onchanges:
            - pkg: install_httpd

start_httpd:
    service.running:
        - name: httpd
        - enable: True
        - reload: True
        - require:
            - pkg: install_httpd

start_firewall:
    cmd.run:
        - name: "firewall-cmd --zone=public --add-service=http --permanent && firewall-cmd --reload"