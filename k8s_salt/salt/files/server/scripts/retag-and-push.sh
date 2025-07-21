#!/bin/bash

# this script takes all locally cached container images that start with docker.io, 
# quay.io, ghcr.io, and localhost and retags/pushes them to a specified docker registry.
# the hostname used for the registry should be the IP instead of localhost (if the server
# is on the system running this script) so that the k8s instance can pull from it if it
# is on another system.
# it will also remove all locally cached images to save space

# -r is for the registry, -i is for if the registry doesn't use https

registry_address="localhost:5000"

# Show usage
help(){
    echo "Usage: $0 [-r <registry>] [-i]"
    echo "-r <registry>: which registry to target. By default localhost."
    echo "-i           : force insecure usage of registry."
}

# Pull params
insecure=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            help
            exit 0
            ;;
        -r|--registry)
            shift # next is registry
            registry_address="$1" # check if valid address
            shift # next param
            ;;
        -i|--insecure)
            insecure="K"
            shift
            ;;
        *)
            echo "unrecognized option $1"
            exit 1
            ;;
    esac
done

if [[ $(curl -${insecure}Ls "${registry_address}/v2/_catalog" -o /dev/null -w "%{http_code}") != "200" ]]; then
    echo "please provide a valid docker registry"
    exit 1
fi

if [ "$insecure" ]; then # adding the insecure registry to the container registry config if it is not already there
    python3 << EOF
import re
with open('/etc/containers/registries.conf', 'r+') as f:
    contents = f.read()
    if f'location = "${registry}"' not in contents:
        f.write('\n\n[[registry]]\n  location = "${registry_address}"\n  insecure = true')
EOF
fi

while IFS= read -r image; do
    if [[ $(echo "${image}" | grep "registry") ]]; then
        continue
    fi
    suffix=$(echo "$image" | sed 's|[^/]*/\(.*\)|\1|')
    new_path="${registry_address}/${suffix}"

    echo "tagging: $image -> $new_path"
    podman tag "$image" "$new_path"

    echo "pushing: $new_path"
    podman push "${new_path}" || (echo "failed pushing $new_path"; exit 1)
    echo "pushed $new_path"
    podman rmi "${new_path}" --ignore
    podman rmi "${image}" --ignore
done < <(podman images --format '{{.Repository}}:{{.Tag}}')

echo "done!"