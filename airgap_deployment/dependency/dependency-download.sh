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

tar -czvf dependencies.tar.gz files all-images.tar.gz

rm -r files all-images.tar.gz
