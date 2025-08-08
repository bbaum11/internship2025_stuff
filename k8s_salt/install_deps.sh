#!/bin/bash

set -o pipefail

# sourcing the install.sh script except for the last two lines that execute it
wget -O install.sh get.rke2.io
if [[ "$(sha256sum install.sh)" != "2d24db2184dd6b1a5e281fa45cc9a8234c889394721746f89b5fe953fdaaf40a  install.sh" ]]; then
	read -p "the shasum of the install script did not match what was expected. continue with the download? (y/n)" confirm
 	if [[ $confirm == "n" ]]; then
  		exit 0
	fi
 	echo "consider changing this script to use the new checksum"
fi

head -n -2 install.sh > trimmed-install.sh
source trimmed-install.sh

# modifying the download tarball function to download the zst archives without the otherwise required env variables
download_airgap_tarball(){
    if [ -n "${INSTALL_RKE2_COMMIT}" ]; then
	AIRGAP_TARBALL_URL=${STORAGE_URL}/rke2-images.${SUFFIX}-${INSTALL_RKE2_COMMIT}.tar.zst
    	# try for zst first; if that fails use gz for older release branches
    	if ! check_download "${AIRGAP_TARBALL_URL}"; then
       		AIRGAP_TARBALL_URL=${STORAGE_URL}/rke2-images.${SUFFIX}-${INSTALL_RKE2_COMMIT}.tar.gz
    	fi
    else
	version_urlsafe="$(echo ${INSTALL_RKE2_VERSION} | sed 's/\+/%2B/g')"
	AIRGAP_TARBALL_URL=${INSTALL_RKE2_ARTIFACT_URL}/${version_urlsafe}/rke2-images.${SUFFIX}.tar.zst
    fi
    info "downloading airgap tarball at ${AIRGAP_TARBALL_URL}"
    download "${TMP_AIRGAP_TARBALL}" "${AIRGAP_TARBALL_URL}"
}

# downloading just the binary
download_bin(){
    if [ -n "${INSTALL_RKE2_COMMIT}" ]; then
	BIN_URL=${STORAGE_URL}/rke2.${SUFFIX}-${INSTALL_RKE2_COMMIT}
    else
	version_urlsafe="$(echo ${INSTALL_RKE2_VERSION} | sed 's/\+/%2B/g')"
	BIN_URL=${INSTALL_RKE2_ARTIFACT_URL}/${version_urlsafe}/rke2.${SUFFIX}
    fi
    info "downloading airgap tarball at ${BIN_URL}"
    download "${TMP_BIN}" "${BIN_URL}"
}

# modifying the tmp folder setup
setup_tmp() {
    TMP_DIR=$(mktemp -d -t rke2-install.XXXXXXXXXX)
    TMP_AIRGAP_TARBALL=${TMP_DIR}/rke2-images.${SUFFIX}.tar.zst
    TMP_CHECKSUMS=${TMP_DIR}/rke2.sha256sum-${ARCH}.txt
    TMP_TARBALL=${TMP_DIR}/rke2.${SUFFIX}.tar.gz
    TMP_AIRGAP_CHECKSUMS=${TMP_DIR}/rke2-images.checksums
	TMP_BIN=${TMP_DIR}/rke2
    cleanup() {
        code=$?
        set +e
        trap - EXIT
        rm -rf "${TMP_DIR}"
        exit $code
    }
    trap cleanup INT EXIT
}

if [[ upgrade == "true" ]]; then













setup_env
setup_arch
verify_downloader curl || verify_downloader wget || fatal "can not find curl or wget for downloading files"
get_release_version
setup_tmp
download_tarball
download_checksums
download_airgap_tarball

echo -e "[info] contents of the tmp directory:\n$(ls ${TMP_DIR})"
mkdir rke2-tmp
rm -f install.sh trimmed-install.sh

pushd rke2-tmp # creating the tarfile to be moved onto the airgap

# creating the salt state expected filesystem structure
mkdir files
pushd files

mkdir server
pushd server

mkdir scripts
pushd scripts
	wget -O install.sh get.rke2.io
popd # scripts

mkdir archives
pushd archives

mv ${TMP_DIR}/rke2.sha256sum-${ARCH}.txt ${TMP_DIR}/sha256sum-${ARCH}.txt

# moving the rke2 archives in
cp -r ${TMP_DIR}/* .
info "copied contents of the tmp directory to $(pwd)"

info "pulling gitlab runner"
podman pull registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v18.1.1
info "saving gitlab runner"
podman save registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v18.1.1 | gzip > gitlab-runner.tar.gz
info "pulling gitlab runner helper"
podman pull registry.gitlab.com/gitlab-org/gitlab-runner/gitlab-runner-helper:x86_64-v18.1.1
info "saving gitlab runner helper"
podman save registry.gitlab.com/gitlab-org/gitlab-runner/gitlab-runner-helper:x86_64-v18.1.1 | gzip > gitlab-runner-helper.tar.gz

info "pulling metallb speaker"
podman pull quay.io/metallb/speaker:v0.15.2
info "saving metallb speaker"
podman save quay.io/metallb/speaker:v0.15.2 | gzip > speaker.tar.gz
info "pulling metallb controller"
podman pull quay.io/metallb/controller:v0.15.2
info "saving metallb controller"
podman save quay.io/metallb/controller:v0.15.2 | gzip > controller.tar.gz

info "pulling traefik image"
podman pull docker.io/library/traefik:v3.5.0 
info "saving traefik image"
podman save docker.io/library/traefik:v3.5.0 | gzip > traefik-v3.5.0.tgz

info "pulling cert-manager images"
tmpfile=$(mktemp)

echo "quay.io/jetstack/cert-manager-controller:v1.18.2
quay.io/jetstack/cert-manager-webhook:v1.18.2
quay.io/jetstack/cert-manager-cainjector:v1.18.2
quay.io/jetstack/cert-manager-acmesolver:v1.18.2
quay.io/jetstack/cert-manager-startupapicheck:v1.18.2" > ${tmpfile}

while IFS= read -r line; do
        podman pull $line
        filename=$(echo $line | sed 's/quay.io\/jetstack\///g' | sed 's/:v1.18.2//g')
        info "writing $line to $filename"
        podman save $line | gzip > $filename
done < "${tmpfile}"

popd # archives
mkdir binaries
pushd binaries
	info "downloading k9s binary"
	curl -OLs https://github.com/derailed/k9s/releases/download/v0.50.9/k9s_Linux_amd64.tar.gz
	gunzip k9s_Linux_amd64.tar.gz
	tar -xvf k9s_Linux_amd64.tar
	rm -f k9s_Linux_amd64.tar LICENSE README.md

	info "downloading helm binary"
	curl -OLs https://get.helm.sh/helm-v3.18.4-linux-amd64.tar.gz
	gunzip helm-v3.18.4-linux-amd64.tar.gz
	tar -xvf helm-v3.18.4-linux-amd64.tar
	mv linux-amd64/helm ./.
	rm -rf linux-amd64 helm-v3.18.4-linux-amd64.tar
popd # binaries
popd # server
popd # files

tar -cvf deps.tar files
info "dependencies saved to deps.tar"
cp deps.tar ../. 


rm -rf rke2-tmp
