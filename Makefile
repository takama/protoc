# Use the v0.0.0 tag for testing, it shouldn't clobber any release builds
RELEASE ?= v0.2.15
CONTAINER_IMAGE ?= takama/protoc

all: build push

build:
	@echo "+ $@"
	@docker build --pull -t $(CONTAINER_IMAGE):$(RELEASE) .

push:
	@echo "+ $@"
	@docker push $(CONTAINER_IMAGE):$(RELEASE)

.PHONY: all \
	build \
	push
