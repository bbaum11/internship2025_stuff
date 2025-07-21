/var/lib/rancher/rke2/server/manifests/metallb-native.yaml:
    file.managed:
        - source: salt://files/server/manifests/metallb-native.yaml
        - makedirs: True

# this requires input to set the ip address space
{% if not salt['pillar.get']('metallb_pool', None) %}
no_metallb_pool:
    test.fail_without_changes:
        - name: "Missing metallb ip address space with pillar 'metallb_pool"
        - failhard: True
        - order: 1
{% endif %}

/var/lib/rancher/rke2/server/manifests/pools.yaml:
    file.managed:
        - source: salt://files/server/manifests/pools.yaml

add_metallb_address_space:
    cmd.run:
        - name: "sed -i 's|ADDRESS_RANGE|{{ pillar['metallb_pool'] }}|' /var/lib/rancher/rke2/server/manifests/pools.yaml"
        - require:
            - file: /var/lib/rancher/rke2/server/manifests/pools.yaml


# gitlab runner setup
{% if not salt['pillar.get']('runner_token', None) %}
no_runner_token:
    test.fail_without_changes:
        - name: "Missing runner registration token with pillar 'runner_token'"
        - failhard: True
{% endif %}

{% if not salt['pillar.get']('gitlab_url', None) %}
no_gitlab_address:
    test.fail_without_changes:
        - name: "Missing gitlab server address with pillar 'gitlab_url'"
        - failhard: True
{% endif %}

/var/lib/rancher/rke2/server/manifests/gitlab-runner-chart-crd.yaml:
    file.managed:
        - source: salt://files/server/manifests/gitlab-runner-chart-crd.yaml

configure_gitlab_runner_token:
    cmd.run:
        - name: sed -i 's|CONFIGURE_THE_TOKEN|{{ pillar['runner_token'] }}|' /var/lib/rancher/rke2/server/manifests/gitlab-runner-chart-crd.yaml
        - require: 
            - file: /var/lib/rancher/rke2/server/manifests/gitlab-runner-chart-crd.yaml

configure_gitlab_runner_url:
    cmd.run:
        - name: sed -i 's|CONFIGURE_THE_URL|{{ pillar['gitlab_url'] }}|' /var/lib/rancher/rke2/server/manifests/gitlab-runner-chart-crd.yaml
        - require: 
            - file: /var/lib/rancher/rke2/server/manifests/gitlab-runner-chart-crd.yaml

configure_local_chart:
    cmd.run:
        - name: sed -i 's|gitlab/gitlab-runner|/srv/charts/gitlab-runner-0.78.1.tgz|' /var/lib/rancher/rke2/server/manifests/gitlab-runner-chart-crd.yaml
        - require: 
            - file: /var/lib/rancher/rke2/server/manifests/gitlab-runner-chart-crd.yaml

/srv/charts/gitlab-runner-0.78.1.tgz:
    file.managed:
        - source: salt://files/server/archives/gitlab-runner-0.78.1.tgz
        - makedirs: True