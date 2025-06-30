#!/bin/bash

# latest versions of each of the components can be found here:
# longhorn: https://longhorn.io/docs/1.9.0/deploy/install/airgap/
# k9s: https://github.com/derailed/k9s/releases
# canal: https://github.com/projectcalico/calico/blob/master/manifests/canal.yaml
# metallb: https://metallb.io/installation/ 
# k3s: https://github.com/k3s-io/k3s/releases/ 
# argocd: https://github.com/argoproj/argo-cd/blob/master/manifests/install.yaml 

# to extract the tarball:
# tar -xzvf dependencies.tar.gz

set -e

mkdir -p files && cd files

while read -r file; do
    [[ -z "$file" || "$file" =~ ^# ]] && continue
    if [[ $file == "https://get.k3s.io/" ]]; then
        curl -L "$file" -o install.sh
    else
        curl -LO "$file"
    fi
done < ../file-dependencies

cd ..

images=()
while read -r image; do
    [[ -z "$image" || "$image" =~ ^# ]] && continue
    echo "pulling $image"
    podman pull "$image"
    images+=("$image")
done < ../image-dependencies

if [ "${#images[@]}" -gt 0 ]; then
    podman save "${images[@]}" | gzip > all-images.tar.gz
fi

# adding the retag and push script into a local file and adding it to the archive file
cat > retag-and-push.sh <<'EOF'
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
EOF



tar -czvf dependencies.tar.gz files all-images.tar.gz retag-and-push.sh

rm -r files all-images.tar.gz retag-and-push.sh
