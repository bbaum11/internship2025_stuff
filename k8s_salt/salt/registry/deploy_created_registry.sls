{% if not salt['pillar.get']('registry_image', None) %}
no_registry_image:
    test.fail_without_changes:
        - name: "Deploy registry selected; please specify registry image to use with pillar 'registry_image'. The parameter is still needed for registry creation."
        - failhard: True
{% endif %}

{% if pillar.get('create_registry', False) %}
deploy_registry_container:
    cmd.run:
        - name: >
            podman run -d --name private-registry
            -p 5000:5000
            --restart=always
            {{ pillar['registry_image'] }}
        - unless: {% raw %} podman ps --format '{{.Names}}' | grep -q private-registry {% endraw %}

{% endif %}