packages:
    pkg.installed:
        - pkg_verify: True
        - pkgs:
            - epel-release
            - openscap-scanner
            - scap-security-guide
            - rocky-release-security
            - openscap-utils
            - podman


/srv/scripts:
    file.directory:
        - makedirs: True

#rke2 needs this disabled
disable_firewalld:
    service.dead:
        - name: firewalld