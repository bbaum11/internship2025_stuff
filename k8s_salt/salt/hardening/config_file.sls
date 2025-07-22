/etc/rancher/rke2/config.yaml:
    file.managed:
        - source: salt://files/server/configs/config.yaml 
        - user: root
        - group: root
        - mode: 0600
        - makedirs: True