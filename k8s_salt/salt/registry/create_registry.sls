{% if not salt['pillar.get']('create_registry', None) %} # conditionals are within the registry/ directory
create_registry_not_specified:
    test.fail_without_changes:
        - name: "Specify whether to create the image registry or not with the pillar 'create_registry'"
        - failhard: True
{% endif %}

{% if pillar.get('create_registry', True) %}

registry_volume:
    cmd.run:
        - name: podman volume create registry-data
        - unless: podman volume inspect registry-data

registry_image:
  cmd.run:
    - name: podman pull docker.io/library/registry:2
    - unless: {% raw %} podman images --format '{{.Repository}}:{{.Tag}}' | grep -q docker.io/library/registry:2 {% endraw %}

registry_container:
    cmd.run:
        - name: >
            podman run -d --name private-registry
            -p 5000:5000
            -v registry-data:/var/lib/registry
            --restart=always
            docker.io/library/registry:2
        - unless: {% raw %} podman ps --format '{{.Names}}' | grep -q private-registry {% endraw %}
        - require:
            - cmd: registry_image
            - cmd: registry_volume

/srv/images:
    file.directory:
        - makedirs: True

metallb_controller:
    file.managed:
        - name: /srv/images/controller.tar.gz
        - source: salt://files/server/archives/controller.tar.gz

metallb_speaker:
    file.managed:
        - name: /srv/images/speaker.tar.gz
        - source: salt://files/server/archives/speaker.tar.gz

# canal_image_archive:
#     file.managed:
#         - name: /srv/images/rke2-images-canal.linux-amd64.tar.gz
#         - source: salt://files/server/archives/rke2-images-canal.linux-amd64.tar.gz

# traefik_image_archive:
#     file.managed:
#         - name: /srv/images/rke2-images-traefik.linux-amd64.tar.gz
#         - source: salt://files/server/archives/rke2-images-traefik.linux-amd64.tar.gz

# core_image_archive:
#     file.managed:
#         - name: /srv/images/rke2-images-core.linux-amd64.tar.gz
#         - source: salt://files/server/archives/rke2-images-core.linux-amd64.tar.gz

# need to figure out gitlab images
runner_helper_image:
    file.managed:
        - name: /srv/images/gitlab-runner-helper.tar.gz
        - source: salt://files/server/archives/gitlab-runner-helper.tar.gz

default_gitlab_runner_image:
    file.managed:
        - name: /srv/images/gitlab-runner.tar.gz
        - source: salt://files/server/archives/gitlab-runner.tar.gz

# ----------------------------------------
# creating the custom gitlab runner image
load_runner_image:
    cmd.run:
        - name: "podman load -i /srv/gitlab-runner.tar.gz | tee /tmp/loaded_image && sed -i 's/Loaded image: //' /tmp/loaded_image"
        - require:
            - file: default_gitlab_runner_image

{% if not salt['pillar.get']('cert_filename', None) %}
no_cert_filename:
    test.fail_without_changes:
        - name: "Missing tls cert filename for gitlab runner with pillar 'cert_filename'"
        - failhard: True
{% endif %}

/tmp/{{ pillar['cert_filename'] }}:
    file.managed:
        - source: /etc/pki/ca-trust/source/anchors/{{ pillar['cert_filename'] }}

/tmp/gitlab-dockerfile:
    file.managed:
        - contents: |
            FROM registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v18.1.1
            ARG src="{{ pillar['cert_filename'] }}"
            ARG target="/usr/local/share/ca-certificates/{{ pillar['cert_filename'] }}"
            COPY ${src} ${target}
            RUN update-ca-certificates
        - require:
            - cmd: load_runner_image
            - file: /tmp/{{ pillar['cert_filename'] }}

build_new_runner_image:
    cmd.run:
        - name: podman build -t my-gitlab-runner:v1 -f /tmp/gitlab-dockerfile
# ----------------------------------------

{% set archives = [
    '/srv/images/gitlab-runner-helper.tar.gz'
] %}

{% for file in archives %}
load_archive_{{ loop.index }}:
    cmd.run:
        - name: podman load -i {{ file }}

remove_archive_{{ loop.index }}:
    file.absent:
        - name: {{ file }}
        - require:
            - cmd: load_archive_{{ loop.index }}
{% endfor %}

/srv/scripts/retag-and-push.sh:
    file.managed:
        - source: salt://files/server/scripts/retag-and-push.sh
        - mode: 700

retag_images:
    cmd.run:
        - name: "/srv/scripts/retag-and-push.sh -i"
        - require:
            - file: /srv/scripts/retag-and-push.sh
            - cmd: build_new_runner_image
            {% for file in archives %}
            - cmd: load_archive_{{ loop.index }}
            {% endfor %}
{% endif %}