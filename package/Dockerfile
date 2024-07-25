ARG BASE_IMAGE

FROM --platform=$BUILDPLATFORM registry.suse.com/bci/golang:1.22 AS build
ARG VERSION
ARG COMMIT
ARG RKE_VERSION
ARG CGO_ENABLED=0
ARG TAGS="k8s"
ARG LINKFLAGS="-extldflags -static"
ARG DEFAULT_VALUES="{\"rke-version\":\"${RKE_VERSION}\"}"
ARG LDFLAGS="-X github.com/rancher/rancher/pkg/version.Version=${VERSION} -X github.com/rancher/rancher/pkg/version.GitCommit=${COMMIT} -X github.com/rancher/rancher/pkg/settings.InjectDefaults=${DEFAULT_VALUES} ${LINKFLAGS}"
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

# Only invalidate cache if go.mod/go.sum changes.
COPY go.mod go.sum .
COPY pkg/apis/go.mod pkg/apis/go.sum pkg/apis/
COPY pkg/client/go.mod pkg/client/go.sum pkg/client/
RUN go mod download

COPY . .

RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go build -tags "${TAGS}" -ldflags "${LDFLAGS}" -o rancher

FROM ${BASE_IMAGE}

ARG VERSION=${VERSION}
ENV CATTLE_SERVER_VERSION ${VERSION}
ENV CATTLE_AGENT_IMAGE ${IMAGE_REPO}/rancher-agent:${VERSION}
ENV CATTLE_SERVER_IMAGE ${IMAGE_REPO}/rancher

COPY --chown=root:root --chmod=0755 \
     --from=build /app/rancher \
                  /app/package/entrypoint.sh \
                  /app/package/kustomize.sh \
                  /app/package/jailer.sh /usr/bin/

VOLUME /var/lib/rancher
VOLUME /var/lib/kubelet
VOLUME /var/lib/cni
VOLUME /var/log

ENTRYPOINT ["entrypoint.sh"]
