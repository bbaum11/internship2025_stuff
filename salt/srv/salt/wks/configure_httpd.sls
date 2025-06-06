{% set server_ip = salt['pillar.get']('server_ip', 'ip not entered') %}

create_repo_folder:
    file.directory:
        - name: /srv/repo

install_httpd:
    pkg.installed:
        - name: httpd
        - refresh: True
                    
config_the_config:
    file.append:
        - name: /etc/httpd/conf/httpd.conf
        - text: |
            <VirtualHost *:80>
                ServerName {{server_ip}}
                DocumentRoot /var/www/html/<repo>
                <Directory /var/www/html/<repo>/
                    Options Indexes
                </Directory>
            </VirtualHost>

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