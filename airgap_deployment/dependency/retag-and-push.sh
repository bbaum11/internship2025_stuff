#!/bin/bash

# this script takes all locally cached container images that start with docker.io, 
# quay.io, ghcr.io, and localhost and retags/pushes them to a specified docker registry.
# the hostname used for the registry should be the IP instead of localhost (if the server
# is on the system running this script) so that the k8s instance can pull from it if it
# is on another system.

if [ "$#" -eq 0 ]; then
  echo "please provide an address for the registry"
  exit 1
elif [[ $1 == *localhost* ]]; then
    echo "please make sure to use the IP address of the registry if it is on this system."
    exit 1
elif [[ $(curl -s "${1}/v2/_catalog" -o /dev/null -w "%{http_code}") != "200" ]]; then
    echo "please provide a valid docker registry"
    exit 1
fi

registry_address=$1

registries=("docker.io" "quay.io" "ghcr.io" "localhost")

for prefix in "${registries[@]}"; do
    while IFS= read -r image; do
        trimmed_name="${image#${prefix}/}"
        new_path="${registry_address}/${trimmed_name}"

        echo "tagging: $image -> $new_path"
        podman tag "$image" "$new_path"

        echo "pushing: $new_path"
        podman push "${new_path}"
        if [ $? -ne 0 ]; then
            echo "failed pushing $new_path"
        else
            echo "pushed $new_path"
        fi
    done < <(podman images --format '{{.Repository}}:{{.Tag}}' | grep "^${prefix}/")
done

echo "done!"