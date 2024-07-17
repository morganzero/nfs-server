FROM alpine:latest

LABEL maintainer="Morgan Zero <morgan@sushibox.dev>"

RUN apk add --no-cache nfs-utils bash iproute2 && \
    rm -rf /var/cache/apk /tmp /sbin/halt /sbin/poweroff /sbin/reboot && \
    mkdir -p /var/lib/nfs/rpc_pipefs /var/lib/nfs/v4recovery && \
    echo "rpc_pipefs    /var/lib/nfs/rpc_pipefs rpc_pipefs      defaults        0       0" >> /etc/fstab && \
    echo "nfsd  /proc/fs/nfsd   nfsd    defaults        0       0" >> /etc/fstab

COPY exports.template /etc/exports.template
COPY nfsd.sh /usr/local/bin/nfsd.sh
COPY .bashrc /root/.bashrc

RUN chmod +x /usr/local/bin/nfsd.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s CMD pidof rpc.mountd || exit 1

ENTRYPOINT ["/usr/local/bin/nfsd.sh"]
