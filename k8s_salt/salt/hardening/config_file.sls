/etc/rancher/rke2/config.yaml:
    file.managed:
        - source: salt://files/server/configs/config.yaml # add the registry path to this file
        - user: root
        - group: root
        - mode: 0600
        - makedirs: True