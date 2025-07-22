local_traefik_archive:
    file.managed:
        - name: /root/rke2-artifacts/rke2-images-traefik.linux-amd64.tar.zst
        - source: salt://files/server/archives/rke2-images-traefik.linux-amd64.tar.zst
        - makedirs: True

local_main_archive:
    file.managed:
        - name: /root/rke2-artifacts/rke2-images.linux-amd64.tar.zst
        - source: salt://files/server/archives/rke2-images.linux-amd64.tar.zst
        - makedirs: True

binary_archive:
    file.managed:
        - name: /root/rke2-artifacts/rke2.linux-amd64.tar.gz
        - source: salt://files/server/archives/rke2.linux-amd64.tar.gz

shasum_file:
    file.managed:
        - name: /root/rke2-artifacts/sha256sum-amd64.txt
        - source: salt://files/server/archives/sha256sum-amd64.txt

# rke2 installation
/tmp/install.sh:
    file.managed:
        - source: salt://files/server/scripts/install.sh
        - unless: "systemctl status rke2-server"
        - mode: 700
        - require:
            - file: binary_archive
            - file: local_traefik_archive
            - file: local_main_archive
            - file: shasum_file

run_install.sh:
    cmd.run:
        - name: "INSTALL_RKE2_ARTIFACT_PATH=/root/rke2-artifacts /tmp/install.sh"
        - require:
          - file: /tmp/install.sh

kernel_parameters:
    cmd.run:
        - name: sudo cp -f /usr/local/share/rke2/rke2-cis-sysctl.conf /etc/sysctl.d/60-rke2-cis.conf && sudo systemctl restart systemd-sysctl
        - require:
            - cmd: run_install.sh

create-etcd-user:
    cmd.run:
        - name: sudo useradd -r -c "etcd user" -s /sbin/nologin -M etcd -U
        - unless: getent passwd etcd >/dev/null 2>&1