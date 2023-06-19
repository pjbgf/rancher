#!/bin/bash
set -e -x

cd $(dirname $0)/..

mkdir -p bin

# This is used for downloading the tar file and not the images text file.
# Referenced in test: tests/validation/tests/v3_api/test_airgap.py
if [ -e /usr/tmp/k3s-images.txt ]; then
    sed 's;docker.io/;;g' /usr/tmp/k3s-images.txt > /usr/tmp/docker-k3s-images.txt
    images=$(grep -e 'rancher/mirrored-pause' -e 'rancher/mirrored-coredns-coredns' /usr/tmp/docker-k3s-images.txt)
    ./scripts/download-frozen-image-v2.sh /tmp/images ${images}
    tar -C /tmp/images -cf './bin/k3s-airgap-images.tar' .
else
    touch bin/k3s-airgap-images.tar
fi
