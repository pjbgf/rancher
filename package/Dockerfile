ARG IMAGE_REPO=rancher

FROM ${IMAGE_REPO}/rancher-deps as rancher-deps

FROM rancher-deps as builder-base

ARG DAPPER_HOST_ARCH
ARG ARCH
ENV HOST_ARCH=${DAPPER_HOST_ARCH}

ARG GO_VERSION=1.19
# Based on registry.suse.com/bci/golang:1.19
# https://build.opensuse.org/package/view_file/devel:BCI:Tumbleweed/golang-1.19-image/Dockerfile
RUN set -euo pipefail; zypper -n in --no-recommends go${GO_VERSION} distribution-release make git-core; zypper -n clean; rm -rf /var/log/*
ENV GOLANG_VERSION="%%golang_version%%"
ENV GOPATH="/go"
ENV PATH="/go/bin:/usr/local/go/bin:/root/go/bin/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Combine all zypper installs in one layer.
RUN zypper -n install \
    gcc binutils glibc-devel-static ca-certificates git-core wget curl unzip tar vim less file xz gzip sed gawk iproute2 iptables jq skopeo \
    python3-tox python3-base python3 libffi-devel libopenssl-devel && \
    # use containerd from k3s image, not from bci
    zypper install -y -f docker && rpm -e --nodeps --noscripts containerd && \
    zypper -n clean -a && rm -rf /var/log/* /tmp/* /var/tmp/* /usr/share/doc/packages/*
    
ENV HELM_UNITTEST_VERSION 0.3.2
# k3d ci version
ENV K3D_VERSION v5.4.6

# kontainer-driver-metadata branch to be set for specific branch other than dev/master, logic at rancher/rancher/pkg/settings/setting.go
ENV CATTLE_KDM_BRANCH=dev-v2.7

RUN if [ "${ARCH}" != "s390x" ]; then \
        curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=${K3D_VERSION} bash; \
    fi

RUN if [ "${ARCH}" == "amd64" ]; then \
        curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s v1.49.0; \
        curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/fossas/spectrometer/master/install.sh | sh; \
    fi

RUN mkdir -p /go/src/github.com/rancher/rancher/.kube && \
    ln -s /etc/rancher/k3s/k3s.yaml /go/src/github.com/rancher/rancher/.kube/k3s.yaml

RUN mkdir -p /usr/tmp && \
    curl -sLf https://github.com/rancher/k3s/releases/download/${CATTLE_K3S_VERSION}/k3s-images.txt -o /usr/tmp/k3s-images.txt

ENV DAPPER_SOURCE /go/src/github.com/rancher/rancher/
ENV GOCACHE /root/.cache/go-build
ENV HOME ${DAPPER_SOURCE}
WORKDIR ${DAPPER_SOURCE}

# set up helm unittest - only needs to run on one arch. Needs to run after $HOME has been changed so we can find it later 
RUN if [ "${ARCH}" == "amd64" ]; then \
        helm_v3 plugin install https://github.com/helm-unittest/helm-unittest.git --version ${HELM_UNITTEST_VERSION}; \
    fi

FROM builder-base as builder

# Cache go modules and avoid redoing this step on every build.
COPY go.mod go.mod
COPY go.sum go.sum
COPY pkg/apis/go.mod pkg/apis/go.mod
COPY pkg/apis/go.sum pkg/apis/go.sum
COPY pkg/client/go.mod pkg/client/go.mod
COPY pkg/client/go.sum pkg/client/go.sum
RUN go mod download

# HACK: Tests purposes only.
COPY . .

# Just need to build the server for this image.
RUN ./scripts/build-server

FROM rancher-deps as final
LABEL description="Rancher Manager."

ARG VERSION=dev
ENV CATTLE_SERVER_VERSION ${VERSION}
COPY ./package/entrypoint.sh /usr/bin/
COPY ./package/kustomize.sh /usr/bin/
COPY ./package/jailer.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/kustomize.sh

# Segregate files that are used directly from the Git
# repository (above) from files that are somehow generated
# within the build process (below).
COPY --from=builder /go/src/github.com/rancher/rancher/bin/rancher /usr/bin/
COPY --from=builder /go/src/github.com/rancher/rancher/bin/data.json /var/lib/rancher-data/driver-metadata/

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
