upgrade_tarfile:
    file.managed:
        - name: /tmp/k8s_upgrade_dir/deps.tar
        - source: salt://files/upgrade/deps.tar
        - makedirs: True

untar_upgrade_tarfile:
    cmd.run:
        - name: tar -xvf /tmp/k8s_upgrade_dir/deps.tar
        - require:
            - file: upgrade_tarfile

new_local_traefik_archive:
    cmd.run:
        - name: cp /tmp/k8s_upgrade_dir/rke2-images-traefik.linux-amd64.tar.zst /var/lib/rancher/rke2/agent/images/rke2-images-traefik.linux-amd64.tar.zst
        - require:
            - cmd: untar_upgrade_tarfile

new_local_main_archive:
    cmd.run:
        - name: cp /tmp/k8s_upgrade_dir/rke2-images.linux-amd64.tar.zst /var/lib/rancher/rke2/agent/images/rke2-images.linux-amd64.tar.zst
        - require:
            - cmd: untar_upgrade_tarfile

new_binary:
    cmd.run:
        - name: cp /tmp/k8s_upgrade_dir/rke2 /usr/local/bin/rke2 && chmod 700 /usr/local/bin/rke2
        - require:
            - cmd: untar_upgrade_tarfile

restart_rke2_server_service:
    cmd.run:
        - name: systemctl try-restart rke2-server
        - require:
            - cmd: new_binary
            - cmd: new_local_main_archive
            - cmd: untar_upgrade_tarfile

restart_rke2_agent_service:
    cmd.run:
        - name: systemctl try-restart rke2-agent
        - require:
            - cmd: new_binary
            - cmd: new_local_main_archive
            - cmd: untar_upgrade_tarfile