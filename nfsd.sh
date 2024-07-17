#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

trap "stop; exit 0;" SIGTERM SIGINT

stop() {
  echo "SIGTERM caught, terminating NFS process(es)..."
  /usr/sbin/exportfs -uav
  /usr/sbin/rpc.nfsd 0
  pkill rpc.mountd || true
  pkill rpcbind || true
  echo "Terminated."
}

configure_exports() {
  cp /etc/exports.template /etc/exports
  sed -i "s@{{SHARED_DIRECTORY}}@${SHARED_DIRECTORY:-/data}@g" /etc/exports
  sed -i "s@{{SHARED_DIRECTORY_2}}@${SHARED_DIRECTORY_2:-}@g" /etc/exports
  sed -i "s@{{PERMITTED}}@${PERMITTED:-*}@g" /etc/exports
  sed -i "s@{{READ_ONLY}}@${READ_ONLY:-rw}@g" /etc/exports
  sed -i "s@{{SYNC}}@${SYNC:-sync}@g" /etc/exports
}

start_nfs() {
  echo "Starting rpcbind..."
  /sbin/rpcbind -w
  echo "Starting NFS in the background..."
  /usr/sbin/rpc.nfsd --no-udp --no-nfs-version 2 --no-nfs-version 3
  echo "Exporting File System..."
  if /usr/sbin/exportfs -rv; then
    /usr/sbin/exportfs
  else
    echo "Export validation failed, exiting..."
    exit 1
  fi
  echo "Starting Mountd in the background..."
  /usr/sbin/rpc.mountd --no-udp --no-nfs-version 2 --no-nfs-version 3
}

monitor_nfs() {
  while true; do
    pid=$(pidof rpc.mountd || true)
    if [ -z "$pid" ]; then
      echo "NFS has failed, exiting, so Docker can restart the container..."
      exit 1
    fi
    sleep 1
  done
}

main() {
  if [ -z "${SHARED_DIRECTORY:-}" ]; then
    echo "The SHARED_DIRECTORY environment variable is unset or null, exiting..."
    exit 1
  fi
  configure_exports
  start_nfs
  monitor_nfs
}

main "$@"
