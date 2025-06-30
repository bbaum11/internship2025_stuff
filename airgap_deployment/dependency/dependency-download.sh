#!/bin/bash

# latest versions of each of the components can be found here:
# longhorn: https://longhorn.io/docs/1.9.0/deploy/install/airgap/
# k9s: https://github.com/derailed/k9s/releases
# canal: https://github.com/projectcalico/calico/blob/master/manifests/canal.yaml
# metallb: https://metallb.io/installation/ 
# k3s: https://github.com/k3s-io/k3s/releases/ 
# argocd: https://github.com/argoproj/argo-cd/blob/master/manifests/install.yaml 

# to extract the tarball:
# tar -xzvf airgap-bundle.tar.gz


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

cd .. && mkdir -p images && cd images

while read -r image; do
    [[ -z "$image" || "$image" =~ ^# ]] && continue
    echo "pulling $image"
    podman pull "$image"
    last_part="${image##*/}"
    base_name="${last_part%%:*}"
    podman save "$image" | gzip > ${base_name}.tar.gz
done < ../image-dependencies

cd ..

tar -czvf dependencies.tar.gz files images

rm -r files images