daemon_reload:
    cmd.run:
        - name: systemctl daemon-reload

rke2-server:
    service.running:
        - enable: True
        - reload: True
        - require:
            - cmd: daemon_reload