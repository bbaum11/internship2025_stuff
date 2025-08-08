#!/bin/bash

set -o pipefail


# sourcing the install.sh script except for the last two lines that execute it
wget -O install.sh get.rke2.io
head -n -2 install.sh > trimmed-install.sh
source trimmed-install.sh


# copying the download tarball function but making it download the traefik archive instead
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


# modifying the tmp folder setup to create a traefik archive path
setup_tmp() {
    TMP_DIR=$(mktemp -d -t rke2-install.XXXXXXXXXX)
    TMP_AIRGAP_TARBALL=${TMP_DIR}/rke2-images.${SUFFIX}.tar.zst
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




setup_env
setup_arch
verify_downloader curl || verify_downloader wget || fatal "can not find curl or wget for downloading files"
get_release_version
setup_tmp
download_bin
download_airgap_tarball

echo -e "[info] contents of the tmp directory:\n$(ls ${TMP_DIR})"
mkdir rke2-tmp
cp -r ${TMP_DIR}/* rke2-tmp/.
info "copied contents of the tmp directory to ./rke2-tmp"
rm -f install.sh trimmed-install.sh

pushd rke2-tmp

tar -cvf deps.tar $(ls)
info "dependencies saved to deps.tar"
cp deps.tar ../.

popd

rm -rf rke2-tmp
