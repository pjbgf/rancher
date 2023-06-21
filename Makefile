TARGETS := $(shell ls scripts)
IMAGE_REPO ?= rancher

TARGET_PLATFORMS ?= linux/amd64,linux/arm64,linux/arm/v7,linux/s390x

.dapper:
	@echo Downloading dapper
	@curl -sL https://releases.rancher.com/dapper/latest/dapper-`uname -s`-`uname -m` > .dapper.tmp
	@@chmod +x .dapper.tmp
	@./.dapper.tmp -v
	@mv .dapper.tmp .dapper

$(TARGETS): .dapper
	@if [ "$@" = "post-release-checks" ] || [ "$@" = "list-gomod-updates" ] || [ "$@" = "check-chart-kdm-source-values" ]; then \
		./.dapper -q --no-out $@; \
	else \
		./.dapper $@; \
	fi

.DEFAULT_GOAL := ci

.PHONY: $(TARGETS)

.PHONY: buildx
buildx: buildx-machine ## build container image to current platform
	docker buildx build --build-arg IMAGE_REPO=$(IMAGE_REPO) -f package/Dockerfile \
		-t $(REPO)/rancher:$(TAG) --load .

buildx-machine: ## create buildx machine if not exists
	@docker buildx ls | grep docker-container || \
		docker buildx create --platform=$(TARGET_PLATFORMS) --use
