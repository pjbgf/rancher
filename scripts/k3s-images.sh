#!/bin/bash
set -e -x

cd $(dirname $0)/..

K3S_IMAGES_FILE=${K3S_IMAGES_FILE:-/usr/tmp/k3s-images.txt}

mkdir -p bin

# This is used for downloading the tar file and not the images text file.
# Referenced in test: tests/validation/tests/v3_api/test_airgap.py
if [ -e "${K3S_IMAGES_FILE}" ]; then
    images=$(grep -e 'docker.io/rancher/mirrored-pause' -e 'docker.io/rancher/mirrored-coredns-coredns' "${K3S_IMAGES_FILE}")
    xargs -n1 docker pull <<< "${images}"
    docker save -o ./bin/k3s-airgap-images.tar ${images}
else
    touch bin/k3s-airgap-images.tar
fi
