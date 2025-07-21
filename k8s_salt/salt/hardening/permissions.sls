# i am entirely too lazy to do this in salt
/tmp/file-permissions.sh:
    file.managed:
        - contents: |
            #!/bin/bash
            apply_permissions() {
                local path="$1"
                local perms="$2"
                local owner="$3"

                for file in $path; do
                    if [ -e "$file" ]; then
                        [ -n "$perm" ] && chmod "$perms" "$file"
                        [ -n "$owner" ] && chown "$owner" "$file"
                    fi
                done
            }
            apply_permissions "/etc/rancher/rke2/*" "0600" "root:root"
            apply_permissions "/var/lib/rancher/rke2/*" "" "root:root"
            apply_permissions "/var/lib/rancher/rke2/agent/*" "" "root:root"
            apply_permissions "/var/lib/rancher/rke2/agent/pod-manifests" "0700" ""
            apply_permissions "/var/lib/rancher/rke2/agent/etc" "0700" ""
            apply_permissions "/var/lib/rancher/rke2/agent/*.kubeconfig" "0640" ""
            apply_permissions "/var/lib/rancher/rke2/agent/*.crt" "0600" ""
            apply_permissions "/var/lib/rancher/rke2/agent/*.key" "0600" ""
            apply_permissions "/var/lib/rancher/rke2/agent/bin/*" "0750" "root:root"
            apply_permissions "/var/lib/rancher/rke2/agent/data" "0750" "root:root"
            apply_permissions "/var/lib/rancher/rke2/data/*" "0640" "root:root"
            apply_permissions "/var/lib/rancher/rke2/server/*" "" "root:root"
            apply_permissions "/var/lib/rancher/rke2/server/cred" "0700" ""
            apply_permissions "/var/lib/rancher/rke2/server/db" "0700" ""
            apply_permissions "/var/lib/rancher/rke2/server/tls" "0700" ""
            apply_permissions "/var/lib/rancher/rke2/server/manifests" "0750" ""
            apply_permissions "/var/lib/rancher/rke2/server/logs" "0750" ""
            apply_permissions "/var/lib/rancher/rke2/server/token" "0600" ""
        - mode: 0700

run-perm-script:
    cmd.run:
        - name: /tmp/file-permissions.sh && rm /tmp/file-permissions.sh
        - require:
            - file: /tmp/file-permissions.sh