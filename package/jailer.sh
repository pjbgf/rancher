#!/bin/bash
set -e

NAME=$1
JAIL_BASE=/opt/jail

function rootJail() {
  buildDirStructure

  # Copy over required files to the jail
  if [[ -d /lib64 ]]; then
    cp -r /lib64 "${JAIL_BASE}/$NAME"
    cp -r /usr/lib64 "${JAIL_BASE}/$NAME/usr"
  fi

  cp -r /lib "${JAIL_BASE}/$NAME"
  cp -r /usr/lib "${JAIL_BASE}/$NAME/usr"
  cp /var/lib/ca-certificates/ca-bundle.pem "${JAIL_BASE}/$NAME/etc/ssl"
  cp /etc/resolv.conf "${JAIL_BASE}/$NAME/etc/"
  cp /etc/passwd "${JAIL_BASE}/$NAME/etc/"
  cp /etc/hosts "${JAIL_BASE}/$NAME/etc/"
  cp /etc/nsswitch.conf "${JAIL_BASE}/$NAME/etc/"

  if [ -d /var/lib/rancher/management-state/bin ] && [ "$(ls -A /var/lib/rancher/management-state/bin)" ]; then
    ( cd /var/lib/rancher/management-state/bin
      for f in *; do
        if [ ! -f "/opt/drivers/management-state/bin/$f" ]; then
          cp "$f" "/opt/drivers/management-state/bin/$f"
        fi
      done
    )
  fi

  if [[ -f /etc/ssl/certs/ca-additional.pem ]]; then
    cp /etc/ssl/certs/ca-additional.pem "${JAIL_BASE}/$NAME/etc/ssl"
  fi

  if [[ -f /etc/rancher/ssl/cacerts.pem ]]; then
    cp /etc/rancher/ssl/cacerts.pem "${JAIL_BASE}/$NAME/etc/ssl"
  fi

  # Hard link driver binaries
  cp -r -l /opt/drivers/management-state/bin "${JAIL_BASE}/$NAME/var/lib/rancher/management-state"

  # Hard link rancher-machine, ssh, nc and mkisofs into the jail
  cp -l /usr/bin/{rancher-machine,ssh,nc,mkisofs} "${JAIL_BASE}/$NAME/usr/bin"

  # Hard link cat, bash, sh, rm into the jail
  cp -l /bin/{cat,bash,sh,rm} "${JAIL_BASE}/$NAME/bin/"
}

function buildDirStructure() {
  # Build the jail directory structure
  mkdir -p "${JAIL_BASE}/$NAME/dev"
  mkdir -p "${JAIL_BASE}/$NAME/etc/ssl"
  mkdir -p "${JAIL_BASE}/$NAME/usr/bin"
  mkdir -p "${JAIL_BASE}/$NAME/management-state/node/nodes"
  mkdir -p "${JAIL_BASE}/$NAME/var/lib/rancher/management-state/bin"
  mkdir -p "${JAIL_BASE}/$NAME/management-state/bin"
  mkdir -p "${JAIL_BASE}/$NAME/tmp"
  mkdir -p "${JAIL_BASE}/$NAME/bin"

  cd /dev

  # tar copy a minimum set of devices from /dev
  tar cf - zero urandom tty stdout stdin stderr random null fd core full | \
    (cd "${JAIL_BASE}/${NAME}/dev"; tar xfp -)

  cd -
}

function rootlessJail() {
  echo "Running as ${UID} (EXPERIMENTAL ROOTLESS MODE)"
  mkdir -p "${JAIL_BASE}/${NAME}"
  # chroot is not supported. The execution will be under rancher (UID:1000)
  # which is a lesser privileged user than cowpoke (UID:1500).
}

function main() {
  if [[ "${UID}" == "1500" ]]; then
    rootlessJail
  else
    rootJail
  fi

  touch "${JAIL_BASE}/${NAME}/done"
}

if [[ -z "$1" ]]
  then
    echo "No name supplied"
    exit 1
fi

main
