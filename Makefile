# Use the v0.0.0 tag for testing, it shouldn't clobber any release builds
RELEASE ?= v0.5.0
CONTAINER_IMAGE ?= ghcr.io/takama/protoc

all: build push

CRI_TOOL := docker
HAS_PODMAN := $(shell command -v podman;)

ifdef HAS_PODMAN
	CRI_TOOL := podman
endif

build:
	@echo "+ $@"
	@$(CRI_TOOL) build --pull -t $(CONTAINER_IMAGE):$(RELEASE) .

push:
	@echo "+ $@"
	@$(CRI_TOOL) push $(CONTAINER_IMAGE):$(RELEASE)

.PHONY: all \
	build \
	push
