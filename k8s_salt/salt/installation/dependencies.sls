{% set packages = [
    'openscap-scanner',
    'scap-security-guide',
    'rocky-release-security',
    'openscap-utils',
    'podman',
    'epel-release'
] %}

{% for package in packages %}
{{ package }}:
    pkg.installed:
        - pkg_verify: True
{% endfor %}

/srv/scripts:
    file.directory:
        - makedirs: True

#rke2 needs this disabled
disable_firewalld:
    service.dead:
        - name: firewalld