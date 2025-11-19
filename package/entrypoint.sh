#!/bin/bash

set -e

HTTP_PORT=80
HTTPS_PORT=443

function updateCerts() {
    if [ -x "$(command -v update-ca-certificates)" ]; then
        update-ca-certificates
    fi
    if [ -x "$(command -v c_rehash)" ]; then
        c_rehash
    fi
}

function runRancher() {
    exec tini -- rancher --http-listen-port=${HTTP_PORT} --https-listen-port=${HTTPS_PORT} \
      --audit-log-path=${AUDIT_LOG_PATH} --audit-level=${AUDIT_LEVEL} \
      --audit-log-maxage=${AUDIT_LOG_MAXAGE} --audit-log-maxbackup=${AUDIT_LOG_MAXBACKUP} \
      --audit-log-maxsize=${AUDIT_LOG_MAXSIZE} "${@}"
}

function rootlessMode() {
    echo "Running as ${UID} (EXPERIMENTAL ROOTLESS MODE)"

    runRancher
    exit $?
}

function dockerMode() {
    if [ ! -e /run/secrets/kubernetes.io/serviceaccount ] && [ ! -e /dev/kmsg ]; then
        echo "ERROR: Rancher must be ran with the --privileged flag when running outside of Kubernetes"
        exit 1
    fi

    #########################################################################################################################################
    # DISCLAIMER                                                                                                                            #
    # Copied from https://github.com/moby/moby/blob/ed89041433a031cafc0a0f19cfe573c31688d377/hack/dind#L28-L37                              #
    # Permission granted by Akihiro Suda <akihiro.suda.cz@hco.ntt.co.jp> (https://github.com/rancher/k3d/issues/493#issuecomment-827405962) #
    # Moby License Apache 2.0: https://github.com/moby/moby/blob/ed89041433a031cafc0a0f19cfe573c31688d377/LICENSE                           #
    #########################################################################################################################################
    # only run this if rancher is not running in kubernetes cluster
    if [ ! -e /run/secrets/kubernetes.io/serviceaccount ] && [ -f /sys/fs/cgroup/cgroup.controllers ]; then
        # move the processes from the root group to the /init group,
        # otherwise writing subtree_control fails with EBUSY.
        mkdir -p /sys/fs/cgroup/init
        xargs -rn1 < /sys/fs/cgroup/cgroup.procs > /sys/fs/cgroup/init/cgroup.procs || :
        # enable controllers
        sed -e 's/ / +/g' -e 's/^/+/' <"/sys/fs/cgroup/cgroup.controllers" >"/sys/fs/cgroup/cgroup.subtree_control"
    fi
}

function ensureK3s() {
    rm -f /var/lib/rancher/k3s/server/cred/node-passwd
    if [ -e /var/lib/rancher/management-state/etcd ] && [ ! -e /var/lib/rancher/k3s/server/db/etcd ]; then
        mkdir -p /var/lib/rancher/k3s/server/db
        ln -sf /var/lib/rancher/management-state/etcd /var/lib/rancher/k3s/server/db/etcd
        echo -n 'default' > /var/lib/rancher/k3s/server/db/etcd/name
    fi
    if [ -e /var/lib/rancher/k3s/server/db/etcd ]; then
        echo "INFO: Running k3s server --cluster-init --cluster-reset"
        set +e
        k3s server --cluster-init --cluster-reset &> ./k3s-cluster-reset.log
        K3S_CR_CODE=$?
        if [ "${K3S_CR_CODE}" -ne 0 ]; then
            echo "ERROR:" && cat ./k3s-cluster-reset.log
            rm -f /var/lib/rancher/k3s/server/db/reset-flag
            exit ${K3S_CR_CODE}
        fi
        set -e
    fi
}

function adjustPerms() {
    # Running as root revert the ownership changes needed for rootless.
    chown -R root /var/lib/{ca-certificates,cattle,rancher{,-data}} \
                    /var/log/auditlog \
                    /opt/drivers/management-state/bin /run
}

function main() {
    updateCerts

    if (( UID == 1500 )); then
        rootlessMode
    fi

    adjustPerms
    if [ ! -e /run/secrets/kubernetes.io/serviceaccount ]; then
        dockerMode
    fi

    ensureK3s
    runRancher
}

main
