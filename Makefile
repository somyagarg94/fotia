APP_NAME=fotia
CURRENT_WORKING_DIR=$(shell pwd)

# Construct the image tag.
GO_PIPELINE_COUNTER?="unknown"
VERSION=1.1.$(GO_PIPELINE_COUNTER)

# Build configuration.
HOST_GOOS = linux
HOST_GOARCH = amd64
BUILD_ENV = CGO_ENABLED=0
STATIC_FLAGS = -a -installsuffix cgo
TOOLS_DIR := tools

# Glide configuration
GLIDE_VERSION = v0.12.3
GO_PLATFORM = $(HOST_GOOS)-$(HOST_GOARCH)

# Quay.io variables.
QUAY_REPO=swade1987
QUAY_USERNAME=swade1987
QUAY_PASSWORD?="unknown"

# Construct docker image name.
IMAGE = quay.io/$(QUAY_REPO)/$(APP_NAME)

build: build-app build-image clean

push: docker-login push-image docker-logout

install-glide:
	mkdir -p tools
	curl -L https://github.com/Masterminds/glide/releases/download/$(GLIDE_VERSION)/glide-$(GLIDE_VERSION)-$(GO_PLATFORM).tar.gz | tar -xz -C tools

build-fotia: install-glide
	./$(TOOLS_DIR)/$(GO_PLATFORM)/glide install -v
	go build $(STATIC_FLAGS) -o bin/$(HOST_GOOS)/$(APP_NAME) main.go

build-app:
	docker build -t build-img:$(VERSION) -f Dockerfile.build .

	docker run --name build-image-$(VERSION) \
	--rm -v $(CURRENT_WORKING_DIR):/go/src/github.com/swade1987/fotia:rw \
	build-img:$(VERSION) \
	make build-fotia

    docker rmi build-img:$(VERSION)
	docker rm -f build-img:$(VERSION)

build-image:
	docker build \
    --build-arg git_repository=`git config --get remote.origin.url` \
    --build-arg git_branch=`git rev-parse --abbrev-ref HEAD` \
    --build-arg git_commit=`git rev-parse HEAD` \
    --build-arg built_on=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
    -t $(IMAGE):$(VERSION) .

docker-login:
	docker login -u $(QUAY_USERNAME) -p $(QUAY_PASSWORD) quay.io

docker-logout:
	docker logout

push-image:
	docker push $(IMAGE):$(VERSION)
	docker rmi $(IMAGE):$(VERSION)

clean:
	rm -rf tools vendor .glide

run:
	docker-compose up -d