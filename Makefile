TARGETS := $(shell ls scripts)

DAPPER_ROOT_URL := https://releases.rancher.com/dapper/latest
DAPPER_FILE := Dockerfile.dapper
DAPPER_BINARY := .dapper
DAPPER_COMMAND := ./$(DAPPER_BINARY)

ifeq ($(OS),Windows_NT)
    DAPPER_FILE := Dockerfile-windows.dapper
	DAPPER_BINARY := dapper.exe
	DAPPER_COMMAND := $(DAPPER_BINARY)
endif

.dapper:
	@echo Downloading dapper
	@curl -sL $(DAPPER_ROOT_URL)/dapper-`uname -s`-`uname -m` > $(DAPPER_BINARY).tmp
	@@chmod +x $(DAPPER_BINARY).tmp
	@./$(DAPPER_BINARY).tmp -v
	@mv $(DAPPER_BINARY).tmp $(DAPPER_BINARY)

dapper.exe:
	@curl.exe -sfL $(DAPPER_ROOT_URL)/dapper-Windows-x86_64.exe -o $(DAPPER_BINARY)

$(TARGETS): $(DAPPER_BINARY)
	@if [ "$@" = "post-release-checks" ] || [ "$@" = "list-gomod-updates" ] || [ "$@" = "check-chart-kdm-source-values" ]; then \
		$(DAPPER_COMMAND) -f $(DAPPER_FILE) -q --no-out $@; \
	else \
		$(DAPPER_COMMAND) -f $(DAPPER_FILE) $@; \
	fi

.DEFAULT_GOAL := ci

.PHONY: $(TARGETS)
