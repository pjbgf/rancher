ARG IMAGE_REPO=rancher

FROM ${IMAGE_REPO}/rancher-deps

# Only set here things that are specific to tests. Anything shared
# across the different images should be set in Dockerfile.deps
# instead.
#
# Overall, this file should be largely the same as package/Dockerfile.

RUN ln -s $(GOCOVERDIR=ranchercoverage /usr/bin/rancher) /usr/bin/reset-password && \
    ln -s $(GOCOVERDIR=ranchercoverage /usr/bin/rancher) /usr/bin/ensure-default-admin
WORKDIR /var/lib/rancher

ARG VERSION=dev
ENV CATTLE_SERVER_VERSION ${VERSION}
COPY run_rancher.sh rancher /usr/bin/
COPY kustomize.sh /usr/bin/
COPY jailer.sh /usr/bin/
RUN chmod +x /usr/bin/run_rancher.sh
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

ENTRYPOINT ["run_rancher.sh"]
