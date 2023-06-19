ARG IMAGE_REPO=rancher

FROM ${IMAGE_REPO}/rancher-deps
LABEL description="Rancher Manager."

WORKDIR /var/lib/rancher

ARG VERSION=dev
ENV CATTLE_SERVER_VERSION ${VERSION}
COPY entrypoint.sh rancher /usr/bin/
COPY kustomize.sh /usr/bin/
COPY jailer.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/kustomize.sh

COPY data.json /var/lib/rancher-data/driver-metadata/

ENV CATTLE_AGENT_IMAGE ${IMAGE_REPO}/rancher-agent:${VERSION}
ENV CATTLE_SERVER_IMAGE ${IMAGE_REPO}/rancher
ENV ETCDCTL_API=3

ENV SSL_CERT_DIR /etc/rancher/ssl
VOLUME /var/lib/rancher
VOLUME /var/lib/kubelet
VOLUME /var/lib/cni
VOLUME /var/log

ENV ETCD_UNSUPPORTED_ARCH ${ETCD_UNSUPPORTED_ARCH}

ENTRYPOINT ["entrypoint.sh"]
