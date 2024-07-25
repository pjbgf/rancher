include hack/make/build.mk

TARGETS := $(shell ls scripts)

.dapper:
	@echo Downloading dapper
	@curl -sL https://releases.rancher.com/dapper/latest/dapper-`uname -s`-`uname -m` > .dapper.tmp
	@@chmod +x .dapper.tmp
	@./.dapper.tmp -v
	@mv .dapper.tmp .dapper

$(TARGETS): .dapper
	@if [ "$@" = "check-chart-kdm-source-values" ]; then \
		./.dapper -q --no-out $@; \
	else \
		./.dapper $@; \
	fi

.DEFAULT_GOAL := ci

.PHONY: $(TARGETS)
# Define target platforms, image builder and the fully qualified image name.
TARGET_PLATFORMS ?= linux/amd64,linux/arm64

IMAGE_REPO ?= rancher
RANCHER_IMAGE ?= $(IMAGE_REPO)/rancher:$(TAG)
RANCHER_BASE = $(IMAGE_REPO)/rancher-base:$(shell sha256sum package/Dockerfile.base | cut -f1 -d' ')
BUILD_ACTION = --load

CATTLE_K3S_VERSION = v1.30.2+k3s2

# TODO: Move to inside Dockerfile
build/k3s-airgap-images.tar:
	curl -sLf https://github.com/rancher/k3s/releases/download/$(CATTLE_K3S_VERSION)/k3s-images.txt -o /tmp/k3s-images.txt
	K3S_IMAGES_FILE=/tmp/k3s-images.txt ./scripts/k3s-images.sh
	mkdir -p build
	mv bin/k3s-airgap-images.tar build/k3s-airgap-images.tar

.PHONY: build-image-base
build-image-base: build/k3s-airgap-images.tar buildx-machine ## build (and load) the base container image.
	@docker pull $(REMOTE_REGISTRY)/$(RANCHER_BASE) 2> /dev/null || true
	@if docker images $(RANCHER_BASE) 1> /dev/null 2>&1 | grep -q $(RANCHER_BASE); then \
		echo "Image $(RANCHER_BASE) found locally, skipping building it"; \
	else \
		$(BUILDER) build -t $(RANCHER_BASE) $(BUILD_ACTION) \
			-f package/Dockerfile.base . ; \
	fi

build-images: build-image-rancher build-image-agent build-image-installer

.PHONY: build-image
build-image: build-image-base
	$(BUILDER) build -t $(IMAGE_REPO)/$(IMAGE_NAME):$(TAG) \
			$(BUILD_ACTION) --build-arg=BASE_IMAGE=$(BASE_IMAGE) \
			--build-arg=VERSION=$(VERSION) -f package/$(FILE_NAME) .

build-image-rancher: ## build (and load) rancher's container image.
	$(MAKE) build-image BASE_IMAGE=$(RANCHER_BASE) \
			VERSION=$(VERSION) IMAGE_NAME=rancher FILE_NAME=Dockerfile

build-image-agent: ## build (and load) agent's container image.
	$(MAKE) build-image BASE_IMAGE=$(RANCHER_IMAGE) \
			VERSION=$(VERSION) IMAGE_NAME=rancher-agent FILE_NAME=Dockerfile.agent

build-image-installer: ## build (and load) installer's container image.
	$(MAKE) build-image BASE_IMAGE=$(RANCHER_IMAGE) \
			IMAGE_NAME=system-agent-installer-rancher \
			FILE_NAME=Dockerfile.installer
