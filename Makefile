# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

## Open Match Make Help
## ====================
##
## Create a GKE Cluster (requires gcloud installed and initialized, https://cloud.google.com/sdk/docs/quickstarts)
## make activate-gcp-apis
## make create-gke-cluster push-helm
##
## Create a Minikube Cluster (requires VirtualBox)
## make create-mini-cluster push-helm
##
## Create a KinD Cluster (Follow instructions to run command before pushing helm.)
## make create-kind-cluster get-kind-kubeconfig
## Finish KinD setup by installing helm:
## make push-helm
##
## Deploy Open Match
## make push-images -j$(nproc)
## make install-chart
##
## Build and Test
## make all -j$(nproc)
## make test
##
## Access telemetry
## make proxy-prometheus
## make proxy-grafana
## make proxy-ui
##
## Teardown
## make delete-mini-cluster
## make delete-gke-cluster
## make delete-kind-cluster && export KUBECONFIG=""
##
## Prepare a Pull Request
## make presubmit

# If you want information on how to edit this file checkout,
# http://makefiletutorial.com/

BASE_VERSION = 0.0.0-dev
SHORT_SHA = $(shell git rev-parse --short=7 HEAD | tr -d [:punct:])
VERSION_SUFFIX = $(SHORT_SHA)
BRANCH_NAME = $(shell git rev-parse --abbrev-ref HEAD | tr -d [:punct:])
VERSION = $(BASE_VERSION)-$(VERSION_SUFFIX)
BUILD_DATE = $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
YEAR_MONTH = $(shell date -u +'%Y%m')
YEAR_MONTH_DAY = $(shell date -u +'%Y%m%d')
MAJOR_MINOR_VERSION = $(shell echo $(BASE_VERSION) | cut -d '.' -f1).$(shell echo $(BASE_VERSION) | cut -d '.' -f2)
NANOS = $(shell date -u +'%N')
NANOS_MODULO_60 = $(shell echo $(NANOS)%60 | bc)
PROTOC_VERSION = 3.8.0
HELM_VERSION = 2.14.1
KUBECTL_VERSION = 1.14.3
SKAFFOLD_VERSION = latest
MINIKUBE_VERSION = latest
GOLANGCI_VERSION = 1.17.1
KIND_VERSION = 0.4.0
SWAGGERUI_VERSION = 3.23.0
TERRAFORM_VERSION = 0.12.3
CHART_TESTING_VERSION = 2.3.3

ENABLE_SECURITY_HARDENING = 0
GO = GO111MODULE=on go
# Defines the absolute local directory of the open-match project
REPOSITORY_ROOT := $(patsubst %/,%,$(dir $(abspath $(MAKEFILE_LIST))))
GO_BUILD_COMMAND = CGO_ENABLED=0 $(GO) build -a -installsuffix cgo .
BUILD_DIR = $(REPOSITORY_ROOT)/build
TOOLCHAIN_DIR = $(BUILD_DIR)/toolchain
TOOLCHAIN_BIN = $(TOOLCHAIN_DIR)/bin
PROTOC_INCLUDES := $(REPOSITORY_ROOT)/third_party
GCP_PROJECT_ID ?=
GCP_PROJECT_FLAG = --project=$(GCP_PROJECT_ID)
OPEN_MATCH_BUILD_PROJECT_ID = open-match-build
OPEN_MATCH_PUBLIC_IMAGES_PROJECT_ID = open-match-public-images
REGISTRY ?= gcr.io/$(GCP_PROJECT_ID)
TAG = $(VERSION)
ALTERNATE_TAG = dev
VERSIONED_CANARY_TAG = $(BASE_VERSION)-canary
DATED_CANARY_TAG = $(YEAR_MONTH_DAY)-canary
CANARY_TAG = canary
GKE_CLUSTER_NAME = om-cluster
GCP_REGION = us-west1
GCP_ZONE = us-west1-a
GCP_LOCATION = $(GCP_ZONE)
EXE_EXTENSION =
GCP_LOCATION_FLAG = --zone $(GCP_ZONE)
GO111MODULE = on
GOLANG_TEST_COUNT = 1
SWAGGERUI_PORT = 51500
PROMETHEUS_PORT = 9090
GRAFANA_PORT = 3000
LOCUST_PORT = 8089
FRONTEND_PORT = 51504
BACKEND_PORT = 51505
MMLOGIC_PORT = 51503
SYNCHRONIZER_PORT = 51506
DEMO_PORT = 51507
PROTOC := $(TOOLCHAIN_BIN)/protoc$(EXE_EXTENSION)
HELM = $(TOOLCHAIN_BIN)/helm$(EXE_EXTENSION)
TILLER = $(TOOLCHAIN_BIN)/tiller$(EXE_EXTENSION)
MINIKUBE = $(TOOLCHAIN_BIN)/minikube$(EXE_EXTENSION)
KUBECTL = $(TOOLCHAIN_BIN)/kubectl$(EXE_EXTENSION)
KIND = $(TOOLCHAIN_BIN)/kind$(EXE_EXTENSION)
TERRAFORM = $(TOOLCHAIN_BIN)/terraform$(EXE_EXTENSION)
SKAFFOLD = $(TOOLCHAIN_BIN)/skaffold$(EXE_EXTENSION)
CERTGEN = $(TOOLCHAIN_BIN)/certgen$(EXE_EXTENSION)
GOLANGCI = $(TOOLCHAIN_BIN)/golangci-lint$(EXE_EXTENSION)
CHART_TESTING = $(TOOLCHAIN_BIN)/ct$(EXE_EXTENSION)
GCLOUD = gcloud --quiet
OPEN_MATCH_CHART_NAME = open-match
OPEN_MATCH_RELEASE_NAME = open-match
OPEN_MATCH_KUBERNETES_NAMESPACE = open-match
OPEN_MATCH_SECRETS_DIR = $(REPOSITORY_ROOT)/install/helm/open-match/secrets
REDIS_NAME = om-redis
GCLOUD_ACCOUNT_EMAIL = $(shell gcloud auth list --format yaml | grep account: | cut -c 10-)
_GCB_POST_SUBMIT ?= 0
# Latest version triggers builds of :latest images.
_GCB_LATEST_VERSION ?= undefined
IMAGE_BUILD_ARGS = --build-arg BUILD_DATE=$(BUILD_DATE) --build-arg=VCS_REF=$(SHORT_SHA) --build-arg BUILD_VERSION=$(BASE_VERSION)
GCLOUD_EXTRA_FLAGS =
# Make port forwards accessible outside of the proxy machine.
PORT_FORWARD_ADDRESS_FLAG = --address 0.0.0.0
DASHBOARD_PORT = 9092

# Open Match Cluster E2E Test Variables
OPEN_MATCH_CI_LABEL = open-match-ci

# This flag is set when running in Continuous Integration.
ifdef OPEN_MATCH_CI_MODE
	export KUBECONFIG = $(HOME)/.kube/config
	GCLOUD = gcloud --quiet --no-user-output-enabled
	GKE_CLUSTER_NAME = open-match-ci
	OPEN_MATCH_RELEASE_NAME = open-match-$(SHORT_SHA)
	OPEN_MATCH_KUBERNETES_NAMESPACE = open-match-$(SHORT_SHA)
	GKE_CLUSTER_FLAGS = --labels open-match-ci=1 --node-labels=open-match-ci=1 --network=projects/$(GCP_PROJECT_ID)/global/networks/open-match-ci --subnetwork=projects/$(GCP_PROJECT_ID)/regions/$(GCP_REGION)/subnetworks/ci-$(GCP_REGION)-$(NANOS_MODULO_60)
endif

export PATH := $(TOOLCHAIN_BIN):$(PATH)

# Get the project from gcloud if it's not set.
ifeq ($(GCP_PROJECT_ID),)
	export GCP_PROJECT_ID = $(shell gcloud config list --format 'value(core.project)')
endif

ifeq ($(OS),Windows_NT)
	HELM_PACKAGE = https://storage.googleapis.com/kubernetes-helm/helm-v$(HELM_VERSION)-windows-amd64.zip
	MINIKUBE_PACKAGE = https://storage.googleapis.com/minikube/releases/$(MINIKUBE_VERSION)/minikube-windows-amd64.exe
	SKAFFOLD_PACKAGE = https://storage.googleapis.com/skaffold/releases/$(SKAFFOLD_VERSION)/skaffold-windows-amd64.exe
	EXE_EXTENSION = .exe
	PROTOC_PACKAGE = https://github.com/protocolbuffers/protobuf/releases/download/v$(PROTOC_VERSION)/protoc-$(PROTOC_VERSION)-win64.zip
	KUBECTL_PACKAGE = https://storage.googleapis.com/kubernetes-release/release/v$(KUBECTL_VERSION)/bin/windows/amd64/kubectl.exe
	GOLANGCI_PACKAGE = https://github.com/golangci/golangci-lint/releases/download/v$(GOLANGCI_VERSION)/golangci-lint-$(GOLANGCI_VERSION)-windows-amd64.zip
	KIND_PACKAGE = https://github.com/kubernetes-sigs/kind/releases/download/v$(KIND_VERSION)/kind-windows-amd64
	TERRAFORM_PACKAGE = https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/terraform_$(TERRAFORM_VERSION)_windows_amd64.zip
	CHART_TESTING_PACKAGE = https://github.com/helm/chart-testing/releases/download/v$(CHART_TESTING_VERSION)/chart-testing_$(CHART_TESTING_VERSION)_windows_amd64.zip
	SED_REPLACE = sed -i
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		HELM_PACKAGE = https://storage.googleapis.com/kubernetes-helm/helm-v$(HELM_VERSION)-linux-amd64.tar.gz
		MINIKUBE_PACKAGE = https://storage.googleapis.com/minikube/releases/$(MINIKUBE_VERSION)/minikube-linux-amd64
		SKAFFOLD_PACKAGE = https://storage.googleapis.com/skaffold/releases/$(SKAFFOLD_VERSION)/skaffold-linux-amd64
		PROTOC_PACKAGE = https://github.com/protocolbuffers/protobuf/releases/download/v$(PROTOC_VERSION)/protoc-$(PROTOC_VERSION)-linux-x86_64.zip
		KUBECTL_PACKAGE = https://storage.googleapis.com/kubernetes-release/release/v$(KUBECTL_VERSION)/bin/linux/amd64/kubectl
		GOLANGCI_PACKAGE = https://github.com/golangci/golangci-lint/releases/download/v$(GOLANGCI_VERSION)/golangci-lint-$(GOLANGCI_VERSION)-linux-amd64.tar.gz
		KIND_PACKAGE = https://github.com/kubernetes-sigs/kind/releases/download/v$(KIND_VERSION)/kind-linux-amd64
		TERRAFORM_PACKAGE = https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/terraform_$(TERRAFORM_VERSION)_linux_amd64.zip
		CHART_TESTING_PACKAGE = https://github.com/helm/chart-testing/releases/download/v$(CHART_TESTING_VERSION)/chart-testing_$(CHART_TESTING_VERSION)_linux_amd64.tar.gz
		SED_REPLACE = sed -i
	endif
	ifeq ($(UNAME_S),Darwin)
		HELM_PACKAGE = https://storage.googleapis.com/kubernetes-helm/helm-v$(HELM_VERSION)-darwin-amd64.tar.gz
		MINIKUBE_PACKAGE = https://storage.googleapis.com/minikube/releases/$(MINIKUBE_VERSION)/minikube-darwin-amd64
		SKAFFOLD_PACKAGE = https://storage.googleapis.com/skaffold/releases/$(SKAFFOLD_VERSION)/skaffold-darwin-amd64
		PROTOC_PACKAGE = https://github.com/protocolbuffers/protobuf/releases/download/v$(PROTOC_VERSION)/protoc-$(PROTOC_VERSION)-osx-x86_64.zip
		KUBECTL_PACKAGE = https://storage.googleapis.com/kubernetes-release/release/v$(KUBECTL_VERSION)/bin/darwin/amd64/kubectl
		GOLANGCI_PACKAGE = https://github.com/golangci/golangci-lint/releases/download/v$(GOLANGCI_VERSION)/golangci-lint-$(GOLANGCI_VERSION)-darwin-amd64.tar.gz
		KIND_PACKAGE = https://github.com/kubernetes-sigs/kind/releases/download/v$(KIND_VERSION)/kind-darwin-amd64
		TERRAFORM_PACKAGE = https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/terraform_$(TERRAFORM_VERSION)_darwin_amd64.zip
		CHART_TESTING_PACKAGE = https://github.com/helm/chart-testing/releases/download/v$(CHART_TESTING_VERSION)/chart-testing_$(CHART_TESTING_VERSION)_darwin_amd64.tar.gz
		SED_REPLACE = sed -i ''
	endif
endif

GOLANG_PROTOS = pkg/pb/backend.pb.go pkg/pb/frontend.pb.go pkg/pb/matchfunction.pb.go pkg/pb/messages.pb.go pkg/pb/mmlogic.pb.go pkg/pb/messages.pb.go pkg/pb/evaluator.pb.go internal/pb/synchronizer.pb.go pkg/pb/backend.pb.gw.go pkg/pb/frontend.pb.gw.go pkg/pb/matchfunction.pb.gw.go pkg/pb/messages.pb.gw.go pkg/pb/mmlogic.pb.gw.go pkg/pb/evaluator.pb.gw.go internal/pb/synchronizer.pb.gw.go

SWAGGER_JSON_DOCS = api/frontend.swagger.json api/backend.swagger.json api/mmlogic.swagger.json api/matchfunction.swagger.json api/synchronizer.swagger.json api/evaluator.swagger.json

ALL_PROTOS = $(GOLANG_PROTOS) $(SWAGGER_JSON_DOCS)

help:
	@cat Makefile | grep ^\#\# | grep -v ^\#\#\# |cut -c 4-

local-cloud-build: LOCAL_CLOUD_BUILD_PUSH = # --push
local-cloud-build: gcloud
	cloud-build-local --config=cloudbuild.yaml --dryrun=false $(LOCAL_CLOUD_BUILD_PUSH) --substitutions SHORT_SHA=$(VERSION_SUFFIX),_GCB_POST_SUBMIT=$(_GCB_POST_SUBMIT),_GCB_LATEST_VERSION=$(_GCB_LATEST_VERSION),BRANCH_NAME=$(BRANCH_NAME) .

# Below should match push-images
retag-images: retag-service-images retag-example-images retag-tool-images retag-stress-test-images

retag-service-images: retag-backend-image retag-frontend-image retag-mmlogic-image retag-minimatch-image retag-synchronizer-image retag-swaggerui-image
retag-example-images: retag-demo-images retag-mmf-example-images retag-evaluator-example-images
retag-demo-images: retag-mmf-go-soloduel-image retag-demo-first-match-image
retag-mmf-example-images: retag-mmf-go-soloduel-image retag-mmf-go-pool-image
retag-evaluator-example-images: retag-evaluator-go-simple-image
retag-tool-images: retag-reaper-image retag-base-build-image
retag-stress-test-images: retag-stress-frontend-image
# Above should match push-images

retag-%-image: SOURCE_REGISTRY = gcr.io/$(OPEN_MATCH_BUILD_PROJECT_ID)
retag-%-image: TARGET_REGISTRY = gcr.io/$(OPEN_MATCH_PUBLIC_IMAGES_PROJECT_ID)
retag-%-image: SOURCE_TAG = canary
retag-%-image: docker
	docker pull $(SOURCE_REGISTRY)/openmatch-$*:$(SOURCE_TAG)
	docker tag $(SOURCE_REGISTRY)/openmatch-$*:$(SOURCE_TAG) $(TARGET_REGISTRY)/openmatch-$*:$(TAG)
	docker push $(TARGET_REGISTRY)/openmatch-$*:$(TAG)

# Below should match retag-images
push-images: push-service-images push-example-images push-tool-images push-stress-test-images

push-service-images: push-backend-image push-frontend-image push-mmlogic-image push-minimatch-image push-synchronizer-image push-swaggerui-image
push-example-images: push-demo-images push-mmf-example-images push-evaluator-example-images
push-demo-images: push-mmf-go-soloduel-image push-demo-first-match-image
push-mmf-example-images: push-mmf-go-soloduel-image push-mmf-go-pool-image
push-evaluator-example-images: push-evaluator-go-simple-image
push-tool-images: push-reaper-image push-base-build-image
push-stress-test-images: push-stress-frontend-image
# Above should match retag-images

push-%-image: build-%-image docker
	docker push $(REGISTRY)/openmatch-$*:$(TAG)
	docker push $(REGISTRY)/openmatch-$*:$(ALTERNATE_TAG)
ifeq ($(_GCB_POST_SUBMIT),1)
	docker tag $(REGISTRY)/openmatch-$*:$(TAG) $(REGISTRY)/openmatch-$*:$(VERSIONED_CANARY_TAG)
	docker push $(REGISTRY)/openmatch-$*:$(VERSIONED_CANARY_TAG)
ifeq ($(BASE_VERSION),0.0.0-dev)
	docker tag $(REGISTRY)/openmatch-$*:$(TAG) $(REGISTRY)/openmatch-$*:$(DATED_CANARY_TAG)
	docker push $(REGISTRY)/openmatch-$*:$(DATED_CANARY_TAG)
	docker tag $(REGISTRY)/openmatch-$*:$(TAG) $(REGISTRY)/openmatch-$*:$(CANARY_TAG)
	docker push $(REGISTRY)/openmatch-$*:$(CANARY_TAG)
endif
endif

build-images: build-service-images build-example-images build-tool-images build-stress-test-images

build-service-images: build-backend-image build-frontend-image build-mmlogic-image build-minimatch-image build-synchronizer-image build-swaggerui-image
build-example-images: build-demo-images build-mmf-example-images build-evaluator-example-images
build-demo-images: build-mmf-go-soloduel-image build-demo-first-match-image
build-mmf-example-images: build-mmf-go-soloduel-image build-mmf-go-pool-image
build-evaluator-example-images: build-evaluator-go-simple-image
build-tool-images: build-reaper-image
build-stress-test-images: build-stress-frontend-image

# Include all-protos here so that all dependencies are guaranteed to be downloaded after the base image is created.
# This is important so that the repository does not have any mutations while building individual images.
build-base-build-image: docker $(ALL_PROTOS)
	docker build -f Dockerfile.base-build -t open-match-base-build -t $(REGISTRY)/openmatch-base-build:$(TAG) -t $(REGISTRY)/openmatch-base-build:$(ALTERNATE_TAG) .

build-%-image: docker build-base-build-image
	docker build \
		-f Dockerfile.cmd \
		$(IMAGE_BUILD_ARGS) \
		--build-arg=IMAGE_TITLE=$* \
		-t $(REGISTRY)/openmatch-$*:$(TAG) \
		-t $(REGISTRY)/openmatch-$*:$(ALTERNATE_TAG) \
		.

build-mmf-go-soloduel-image: docker build-base-build-image
	docker build -f examples/functions/golang/soloduel/Dockerfile -t $(REGISTRY)/openmatch-mmf-go-soloduel:$(TAG) -t $(REGISTRY)/openmatch-mmf-go-soloduel:$(ALTERNATE_TAG) .

build-mmf-go-pool-image: docker build-base-build-image
	docker build -f examples/functions/golang/pool/Dockerfile -t $(REGISTRY)/openmatch-mmf-go-pool:$(TAG) -t $(REGISTRY)/openmatch-mmf-go-pool:$(ALTERNATE_TAG) .

build-evaluator-go-simple-image: docker build-base-build-image
	docker build -f examples/evaluator/golang/simple/Dockerfile -t $(REGISTRY)/openmatch-evaluator-go-simple:$(TAG) -t $(REGISTRY)/openmatch-evaluator-go-simple:$(ALTERNATE_TAG) .

build-reaper-image: docker build-base-build-image
	docker build -f tools/reaper/Dockerfile -t $(REGISTRY)/openmatch-reaper:$(TAG) -t $(REGISTRY)/openmatch-reaper:$(ALTERNATE_TAG) .

build-stress-frontend-image: docker
	docker build -f test/stress/Dockerfile -t $(REGISTRY)/openmatch-stress-frontend:$(TAG) -t $(REGISTRY)/openmatch-stress-frontend:$(ALTERNATE_TAG) .

clean-images: docker
	-docker rmi -f open-match-base-build
	-docker rmi -f $(REGISTRY)/openmatch-backend:$(TAG) $(REGISTRY)/openmatch-backend:$(ALTERNATE_TAG)
	-docker rmi -f $(REGISTRY)/openmatch-frontend:$(TAG) $(REGISTRY)/openmatch-frontend:$(ALTERNATE_TAG)
	-docker rmi -f $(REGISTRY)/openmatch-mmlogic:$(TAG) $(REGISTRY)/openmatch-mmlogic:$(ALTERNATE_TAG)
	-docker rmi -f $(REGISTRY)/openmatch-synchronizer:$(TAG) $(REGISTRY)/openmatch-synchronizer:$(ALTERNATE_TAG)
	-docker rmi -f $(REGISTRY)/openmatch-minimatch:$(TAG) $(REGISTRY)/openmatch-minimatch:$(ALTERNATE_TAG)
	-docker rmi -f $(REGISTRY)/openmatch-swaggerui:$(TAG) $(REGISTRY)/openmatch-swaggerui:$(ALTERNATE_TAG)

	-docker rmi -f $(REGISTRY)/openmatch-mmf-go-soloduel:$(TAG) $(REGISTRY)/openmatch-mmf-go-soloduel:$(ALTERNATE_TAG)
	-docker rmi -f $(REGISTRY)/openmatch-mmf-go-pool:$(TAG) $(REGISTRY)/openmatch-mmf-go-pool:$(ALTERNATE_TAG)
	-docker rmi -f $(REGISTRY)/openmatch-evaluator-go-simple:$(TAG) $(REGISTRY)/openmatch-evaluator-go-simple:$(ALTERNATE_TAG)
	-docker rmi -f $(REGISTRY)/openmatch-demo:$(TAG) $(REGISTRY)/openmatch-demo:$(ALTERNATE_TAG)
	-docker rmi -f $(REGISTRY)/openmatch-reaper:$(TAG) $(REGISTRY)/openmatch-reaper:$(ALTERNATE_TAG)
	-docker rmi -f $(REGISTRY)/openmatch-stress-frontend:$(TAG) $(REGISTRY)/openmatch-stress-frontend:$(ALTERNATE_TAG)

update-chart-deps: build/toolchain/bin/helm$(EXE_EXTENSION)
	(cd $(REPOSITORY_ROOT)/install/helm/open-match; $(HELM) repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com; $(HELM) dependency update)

lint-chart: build/toolchain/bin/helm$(EXE_EXTENSION) build/toolchain/bin/ct$(EXE_EXTENSION)
	(cd $(REPOSITORY_ROOT)/install/helm; $(HELM) lint $(OPEN_MATCH_CHART_NAME))
	$(CHART_TESTING) lint --all --chart-yaml-schema $(TOOLCHAIN_BIN)/etc/chart_schema.yaml --lint-conf $(TOOLCHAIN_BIN)/etc/lintconf.yaml --chart-dirs $(REPOSITORY_ROOT)/install/helm/
	$(CHART_TESTING) lint-and-install --all --chart-yaml-schema $(TOOLCHAIN_BIN)/etc/chart_schema.yaml --lint-conf $(TOOLCHAIN_BIN)/etc/lintconf.yaml --chart-dirs $(REPOSITORY_ROOT)/install/helm/

print-chart: build/toolchain/bin/helm$(EXE_EXTENSION)
	(cd $(REPOSITORY_ROOT)/install/helm; $(HELM) install --name $(OPEN_MATCH_RELEASE_NAME) --dry-run --debug $(OPEN_MATCH_CHART_NAME))

build/chart/open-match-$(BASE_VERSION).tgz: build/toolchain/bin/helm$(EXE_EXTENSION) lint-chart
	mkdir -p $(BUILD_DIR)/chart/
	$(HELM) init --client-only
	$(HELM) package -d $(BUILD_DIR)/chart/ --version $(BASE_VERSION) $(REPOSITORY_ROOT)/install/helm/open-match

build/chart/index.yaml: build/toolchain/bin/helm$(EXE_EXTENSION) gcloud build/chart/open-match-$(BASE_VERSION).tgz
	-gsutil cp gs://open-match-chart/chart/index.yaml $(BUILD_DIR)/chart-index/
	$(HELM) repo index --merge $(BUILD_DIR)/chart/index.yaml $(BUILD_DIR)/chart/

build/chart/index.yaml.$(YEAR_MONTH_DAY): build/chart/index.yaml
	cp $(BUILD_DIR)/chart/index.yaml $(BUILD_DIR)/chart/index.yaml.$(YEAR_MONTH_DAY)

build/chart/: build/chart/index.yaml build/chart/index.yaml.$(YEAR_MONTH_DAY)

install-large-chart: build/toolchain/bin/helm$(EXE_EXTENSION) install/helm/open-match/secrets/
	$(HELM) upgrade $(OPEN_MATCH_RELEASE_NAME) --install --wait --debug install/helm/open-match \
		--timeout=600 \
		--namespace=$(OPEN_MATCH_KUBERNETES_NAMESPACE) \
		--set global.image.registry=$(REGISTRY) \
		--set global.image.tag=$(TAG) \
		--set global.telemetry.grafana.enabled=true \
		--set global.telemetry.jaeger.enabled=true \
		--set global.telemetry.prometheus.enabled=true \
		--set global.logging.rpc.enabled=true \
		--set global.telemetry.stackdriver.gcpProjectId=$(GCP_PROJECT_ID)

install-chart: build/toolchain/bin/helm$(EXE_EXTENSION) install/helm/open-match/secrets/
	$(HELM) upgrade $(OPEN_MATCH_RELEASE_NAME) --install --wait --debug install/helm/open-match \
		--timeout=400 \
		--namespace=$(OPEN_MATCH_KUBERNETES_NAMESPACE) \
		--set global.image.registry=$(REGISTRY) \
		--set global.image.tag=$(TAG) \
		--set global.telemetry.stackdriver.gcpProjectId=$(GCP_PROJECT_ID)

install-ci-chart: build/toolchain/bin/helm$(EXE_EXTENSION) install/helm/open-match/secrets/
	$(HELM) upgrade $(OPEN_MATCH_RELEASE_NAME) --install --wait --debug install/helm/open-match \
		--timeout=600 \
		--namespace=$(OPEN_MATCH_KUBERNETES_NAMESPACE) \
		--set global.image.registry=$(REGISTRY) \
		--set global.image.tag=$(TAG) \
		--set open-match-demo.enabled=false \
		--set open-match-customize.enabled=false \
		--set global.telemetry.stackdriver.gcpProjectId=$(GCP_PROJECT_ID)

dry-chart: build/toolchain/bin/helm$(EXE_EXTENSION)
	$(HELM) upgrade --install --wait --debug --dry-run $(OPEN_MATCH_RELEASE_NAME) install/helm/open-match \
		--namespace=$(OPEN_MATCH_KUBERNETES_NAMESPACE) \
		--set global.image.registry=$(REGISTRY) \
		--set global.image.tag=$(TAG)

delete-chart: build/toolchain/bin/helm$(EXE_EXTENSION) build/toolchain/bin/kubectl$(EXE_EXTENSION)
	-$(HELM) delete --purge $(OPEN_MATCH_RELEASE_NAME)
	-$(KUBECTL) --ignore-not-found=true delete crd prometheuses.monitoring.coreos.com
	-$(KUBECTL) --ignore-not-found=true delete crd servicemonitors.monitoring.coreos.com
	-$(KUBECTL) --ignore-not-found=true delete crd prometheusrules.monitoring.coreos.com
	-$(KUBECTL) delete namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE)

install/yaml/: install/yaml/install.yaml install/yaml/01-open-match-core.yaml install/yaml/02-open-match-demo.yaml install/yaml/03-prometheus-chart.yaml install/yaml/04-grafana-chart.yaml install/yaml/05-jaeger-chart.yaml

install/yaml/01-open-match-core.yaml: build/toolchain/bin/helm$(EXE_EXTENSION)
	mkdir -p install/yaml/
	$(HELM) template --name $(OPEN_MATCH_RELEASE_NAME) --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) \
		--set global.image.registry=$(REGISTRY) \
		--set global.image.tag=$(TAG) \
		--set open-match-customize.enabled=false \
		--set open-match-telemetry.enabled=false \
		--set open-match-demo.enabled=false \
		install/helm/open-match > install/yaml/01-open-match-core.yaml

install/yaml/02-open-match-demo.yaml: build/toolchain/bin/helm$(EXE_EXTENSION)
	mkdir -p install/yaml/
	$(HELM) template --name $(OPEN_MATCH_RELEASE_NAME) --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) \
		--set global.image.registry=$(REGISTRY) \
		--set global.image.tag=$(TAG) \
		--set open-match-core.enabled=false \
		--set open-match-telemetry.enabled=false \
		install/helm/open-match > install/yaml/02-open-match-demo.yaml

install/yaml/03-prometheus-chart.yaml: build/toolchain/bin/helm$(EXE_EXTENSION)
	mkdir -p install/yaml/
	$(HELM) template --name $(OPEN_MATCH_RELEASE_NAME) --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) \
		--set global.image.registry=$(REGISTRY) \
		--set global.image.tag=$(TAG) \
		--set open-match-customize.enabled=false \
		--set open-match-demo.enabled=false \
		--set open-match-core.enabled=false \
		--set global.telemetry.prometheus.enabled=true \
		install/helm/open-match > install/yaml/03-prometheus-chart.yaml

install/yaml/04-grafana-chart.yaml: build/toolchain/bin/helm$(EXE_EXTENSION)
	mkdir -p install/yaml/
	$(HELM) template --name $(OPEN_MATCH_RELEASE_NAME) --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) \
		--set global.image.registry=$(REGISTRY) \
		--set global.image.tag=$(TAG) \
		--set open-match-customize.enabled=false \
		--set open-match-demo.enabled=false \
		--set open-match-core.enabled=false \
		--set global.telemetry.grafana.enabled=true \
		install/helm/open-match > install/yaml/04-grafana-chart.yaml

install/yaml/05-jaeger-chart.yaml: build/toolchain/bin/helm$(EXE_EXTENSION)
	mkdir -p install/yaml/
	$(HELM) template --name $(OPEN_MATCH_RELEASE_NAME) --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) \
		--set global.image.registry=$(REGISTRY) \
		--set global.image.tag=$(TAG) \
		--set open-match-customize.enabled=false \
		--set open-match-demo.enabled=false \
		--set open-match-core.enabled=false \
		--set global.telemetry.jaeger.enabled=true \
		install/helm/open-match > install/yaml/05-jaeger-chart.yaml

install/yaml/install.yaml: build/toolchain/bin/helm$(EXE_EXTENSION)
	mkdir -p install/yaml/
	$(HELM) template --name $(OPEN_MATCH_RELEASE_NAME) --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) \
		--set global.image.registry=$(REGISTRY) \
		--set global.image.tag=$(TAG) \
		--set open-match-customize.enabled=false \
		--set open-match-demo.enabled=false \
		--set global.telemetry.jaeger.enabled=true \
		--set global.telemetry.grafana.enabled=true \
		--set global.telemetry.prometheus.enabled=true \
		install/helm/open-match > install/yaml/install.yaml

set-redis-password:
	@stty -echo; \
		printf "Redis password: "; \
		read REDIS_PASSWORD; \
		stty echo; \
		printf "\n"; \
		$(KUBECTL) create secret generic $(REDIS_NAME) -n $(OPEN_MATCH_KUBERNETES_NAMESPACE) --from-literal=redis-password=$$REDIS_PASSWORD --dry-run -o yaml | $(KUBECTL) replace -f - --force

install-toolchain: install-kubernetes-tools install-protoc-tools install-openmatch-tools
install-kubernetes-tools: build/toolchain/bin/kubectl$(EXE_EXTENSION) build/toolchain/bin/helm$(EXE_EXTENSION) build/toolchain/bin/minikube$(EXE_EXTENSION) build/toolchain/bin/skaffold$(EXE_EXTENSION) build/toolchain/bin/terraform$(EXE_EXTENSION)
install-protoc-tools: build/toolchain/bin/protoc$(EXE_EXTENSION) build/toolchain/bin/protoc-gen-go$(EXE_EXTENSION) build/toolchain/bin/protoc-gen-grpc-gateway$(EXE_EXTENSION) build/toolchain/bin/protoc-gen-swagger$(EXE_EXTENSION)
install-openmatch-tools: build/toolchain/bin/certgen$(EXE_EXTENSION) build/toolchain/bin/reaper$(EXE_EXTENSION)

build/toolchain/bin/helm$(EXE_EXTENSION):
	mkdir -p $(TOOLCHAIN_BIN)
	mkdir -p $(TOOLCHAIN_DIR)/temp-helm
ifeq ($(suffix $(HELM_PACKAGE)),.zip)
	cd $(TOOLCHAIN_DIR)/temp-helm && curl -Lo helm.zip $(HELM_PACKAGE) && unzip -j -q -o helm.zip
else
	cd $(TOOLCHAIN_DIR)/temp-helm && curl -Lo helm.tar.gz $(HELM_PACKAGE) && tar xzf helm.tar.gz --strip-components 1
endif
	mv $(TOOLCHAIN_DIR)/temp-helm/helm$(EXE_EXTENSION) $(HELM)
	mv $(TOOLCHAIN_DIR)/temp-helm/tiller$(EXE_EXTENSION) $(TILLER)
	rm -rf $(TOOLCHAIN_DIR)/temp-helm/

build/toolchain/bin/ct$(EXE_EXTENSION):
	mkdir -p $(TOOLCHAIN_BIN)
	mkdir -p $(TOOLCHAIN_DIR)/temp-charttesting
ifeq ($(suffix $(CHART_TESTING_PACKAGE)),.zip)
	cd $(TOOLCHAIN_DIR)/temp-charttesting && curl -Lo charttesting.zip $(CHART_TESTING_PACKAGE) && unzip -j -q -o charttesting.zip
else
	cd $(TOOLCHAIN_DIR)/temp-charttesting && curl -Lo charttesting.tar.gz $(CHART_TESTING_PACKAGE) && tar xzf charttesting.tar.gz
endif
	mv $(TOOLCHAIN_DIR)/temp-charttesting/* $(TOOLCHAIN_BIN)
	rm -rf $(TOOLCHAIN_DIR)/temp-charttesting/

build/toolchain/bin/minikube$(EXE_EXTENSION):
	mkdir -p $(TOOLCHAIN_BIN)
	curl -Lo $(MINIKUBE) $(MINIKUBE_PACKAGE)
	chmod +x $(MINIKUBE)

build/toolchain/bin/kubectl$(EXE_EXTENSION):
	mkdir -p $(TOOLCHAIN_BIN)
	curl -Lo $(KUBECTL) $(KUBECTL_PACKAGE)
	chmod +x $(KUBECTL)

build/toolchain/bin/skaffold$(EXE_EXTENSION):
	mkdir -p $(TOOLCHAIN_BIN)
	curl -Lo $(SKAFFOLD) $(SKAFFOLD_PACKAGE)
	chmod +x $(SKAFFOLD)

build/toolchain/bin/golangci-lint$(EXE_EXTENSION):
	mkdir -p $(TOOLCHAIN_BIN)
	mkdir -p $(TOOLCHAIN_DIR)/temp-golangci
ifeq ($(suffix $(GOLANGCI_PACKAGE)),.zip)
	cd $(TOOLCHAIN_DIR)/temp-golangci && curl -Lo golangci.zip $(GOLANGCI_PACKAGE) && unzip -j -q -o golangci.zip
else
	cd $(TOOLCHAIN_DIR)/temp-golangci && curl -Lo golangci.tar.gz $(GOLANGCI_PACKAGE) && tar xzf golangci.tar.gz --strip-components 1
endif
	mv $(TOOLCHAIN_DIR)/temp-golangci/golangci-lint$(EXE_EXTENSION) $(GOLANGCI)
	rm -rf $(TOOLCHAIN_DIR)/temp-golangci/

build/toolchain/bin/kind$(EXE_EXTENSION):
	mkdir -p $(TOOLCHAIN_BIN)
	curl -Lo $(KIND) $(KIND_PACKAGE)
	chmod +x $(KIND)

build/toolchain/bin/terraform$(EXE_EXTENSION):
	mkdir -p $(TOOLCHAIN_BIN)
	mkdir -p $(TOOLCHAIN_DIR)/temp-terraform
	cd $(TOOLCHAIN_DIR)/temp-terraform && curl -Lo terraform.zip $(TERRAFORM_PACKAGE) && unzip -j -q -o terraform.zip
	mv $(TOOLCHAIN_DIR)/temp-terraform/terraform$(EXE_EXTENSION) $(TOOLCHAIN_BIN)/terraform$(EXE_EXTENSION)
	rm -rf $(TOOLCHAIN_DIR)/temp-terraform/

build/toolchain/python/:
	virtualenv --python=python3 $(TOOLCHAIN_DIR)/python/
	# Hack to workaround some crazy bug in pip that's chopping off python executable's name.
	cd $(TOOLCHAIN_DIR)/python/bin && ln -s python3 pytho
	cd $(TOOLCHAIN_DIR)/python/ && . bin/activate && pip install locustio && deactivate

build/toolchain/bin/protoc$(EXE_EXTENSION):
	mkdir -p $(TOOLCHAIN_BIN)
	curl -o $(TOOLCHAIN_DIR)/protoc-temp.zip -L $(PROTOC_PACKAGE)
	(cd $(TOOLCHAIN_DIR); unzip -q -o protoc-temp.zip)
	rm $(TOOLCHAIN_DIR)/protoc-temp.zip $(TOOLCHAIN_DIR)/readme.txt

build/toolchain/bin/protoc-gen-go$(EXE_EXTENSION):
	mkdir -p $(TOOLCHAIN_BIN)
	cd $(TOOLCHAIN_BIN) && $(GO) build -pkgdir . github.com/golang/protobuf/protoc-gen-go

build/toolchain/bin/protoc-gen-grpc-gateway$(EXE_EXTENSION):
	cd $(TOOLCHAIN_BIN) && $(GO) build -pkgdir . github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway

build/toolchain/bin/protoc-gen-swagger$(EXE_EXTENSION):
	mkdir -p $(TOOLCHAIN_BIN)
	cd $(TOOLCHAIN_BIN) && $(GO) build -pkgdir . github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger

build/toolchain/bin/certgen$(EXE_EXTENSION): tools/certgen/certgen$(EXE_EXTENSION)
	mkdir -p $(TOOLCHAIN_BIN)
	cp -f $(REPOSITORY_ROOT)/tools/certgen/certgen$(EXE_EXTENSION) $(CERTGEN)

build/toolchain/bin/reaper$(EXE_EXTENSION): tools/reaper/reaper$(EXE_EXTENSION)
	mkdir -p $(TOOLCHAIN_BIN)
	cp -f $(REPOSITORY_ROOT)/tools/reaper/reaper$(EXE_EXTENSION) $(TOOLCHAIN_BIN)/reaper$(EXE_EXTENSION)
 
push-helm-ci: build/toolchain/bin/helm$(EXE_EXTENSION) build/toolchain/bin/kubectl$(EXE_EXTENSION)
	$(HELM) init --service-account tiller --force-upgrade --client-only

push-helm: build/toolchain/bin/helm$(EXE_EXTENSION) build/toolchain/bin/kubectl$(EXE_EXTENSION)
	$(KUBECTL) create serviceaccount --namespace kube-system tiller
	$(HELM) init --service-account tiller --force-upgrade
	$(KUBECTL) create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
ifneq ($(strip $($(KUBECTL) get clusterroles | grep -i rbac)),)
	$(KUBECTL) patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
endif
	@echo "Waiting for Tiller to become ready..."
	$(KUBECTL) wait deployment --timeout=60s --for condition=available -l app=helm,name=tiller --namespace kube-system
	$(KUBECTL) wait pod --timeout=60s --for condition=Ready -l app=helm,name=tiller --namespace kube-system

delete-helm: build/toolchain/bin/helm$(EXE_EXTENSION) build/toolchain/bin/kubectl$(EXE_EXTENSION)
	-$(HELM) reset
	-$(KUBECTL) --ignore-not-found=true delete serviceaccount --namespace kube-system tiller
	-$(KUBECTL) --ignore-not-found=true delete clusterrolebinding tiller-cluster-rule
ifneq ($(strip $($(KUBECTL) get clusterroles | grep -i rbac)),)
	-$(KUBECTL) --ignore-not-found=true delete deployment --namespace kube-system tiller-deploy
endif
	@echo "Waiting for Tiller to go away..."
	-$(KUBECTL) wait deployment --timeout=60s --for delete -l app=helm,name=tiller --namespace kube-system

# Fake target for docker
docker: no-sudo

# Fake target for gcloud
gcloud: no-sudo

tls-certs: install/helm/open-match/secrets/

install/helm/open-match/secrets/: install/helm/open-match/secrets/tls/root-ca/ install/helm/open-match/secrets/tls/server/

install/helm/open-match/secrets/tls/root-ca/: build/toolchain/bin/certgen$(EXE_EXTENSION)
	mkdir -p $(OPEN_MATCH_SECRETS_DIR)/tls/root-ca
	$(CERTGEN) -ca=true -publiccertificate=$(OPEN_MATCH_SECRETS_DIR)/tls/root-ca/public.cert -privatekey=$(OPEN_MATCH_SECRETS_DIR)/tls/root-ca/private.key

install/helm/open-match/secrets/tls/server/: build/toolchain/bin/certgen$(EXE_EXTENSION) install/helm/open-match/secrets/tls/root-ca/
	mkdir -p $(OPEN_MATCH_SECRETS_DIR)/tls/server/
	$(CERTGEN) -publiccertificate=$(OPEN_MATCH_SECRETS_DIR)/tls/server/public.cert -privatekey=$(OPEN_MATCH_SECRETS_DIR)/tls/server/private.key -rootpubliccertificate=$(OPEN_MATCH_SECRETS_DIR)/tls/root-ca/public.cert -rootprivatekey=$(OPEN_MATCH_SECRETS_DIR)/tls/root-ca/private.key

auth-docker: gcloud docker
	$(GCLOUD) $(GCP_PROJECT_FLAG) auth configure-docker

auth-gke-cluster: gcloud
	$(GCLOUD) $(GCP_PROJECT_FLAG) container clusters get-credentials $(GKE_CLUSTER_NAME) $(GCP_LOCATION_FLAG)

activate-gcp-apis: gcloud
	$(GCLOUD) services enable containerregistry.googleapis.com
	$(GCLOUD) services enable container.googleapis.com
	$(GCLOUD) services enable containeranalysis.googleapis.com
	$(GCLOUD) services enable binaryauthorization.googleapis.com

create-gcp-service-account: gcloud
	gcloud $(GCP_PROJECT_FLAG) iam service-accounts create open-match --display-name="Open Match Service Account"
	gcloud $(GCP_PROJECT_FLAG) iam service-accounts add-iam-policy-binding --member=open-match@$(GCP_PROJECT_ID).iam.gserviceaccount.com --role=roles/container.clusterAdmin
	gcloud $(GCP_PROJECT_FLAG) iam service-accounts keys create ~/key.json --iam-account open-match@$(GCP_PROJECT_ID).iam.gserviceaccount.com

create-kind-cluster: build/toolchain/bin/kind$(EXE_EXTENSION) build/toolchain/bin/kubectl$(EXE_EXTENSION)
	$(KIND) create cluster

get-kind-kubeconfig: build/toolchain/bin/kind$(EXE_EXTENSION)
	@echo "============================================="
	@echo "= Run this command"
	@echo "============================================="
	@echo "export KUBECONFIG=\"$(shell $(KIND) get kubeconfig-path)\""
	@echo "============================================="

delete-kind-cluster: build/toolchain/bin/kind$(EXE_EXTENSION) build/toolchain/bin/kubectl$(EXE_EXTENSION)
	-$(KIND) delete cluster

create-gke-cluster: GKE_VERSION = 1.13.6 # gcloud beta container get-server-config --zone us-central1-a
create-gke-cluster: GKE_CLUSTER_SHAPE_FLAGS = --machine-type n1-standard-4 --enable-autoscaling --min-nodes 1 --num-nodes 2 --max-nodes 10 --disk-size 50
create-gke-cluster: GKE_FUTURE_COMPAT_FLAGS = --no-enable-basic-auth --no-issue-client-certificate --enable-ip-alias --metadata disable-legacy-endpoints=true --enable-autoupgrade
create-gke-cluster: build/toolchain/bin/kubectl$(EXE_EXTENSION) gcloud
	$(GCLOUD) beta $(GCP_PROJECT_FLAG) container clusters create $(GKE_CLUSTER_NAME) $(GCP_LOCATION_FLAG) $(GKE_CLUSTER_SHAPE_FLAGS) $(GKE_FUTURE_COMPAT_FLAGS) $(GKE_CLUSTER_FLAGS) \
		--enable-pod-security-policy \
		--cluster-version $(GKE_VERSION) \
		--image-type cos_containerd \
		--tags open-match \
		--identity-namespace=$(GCP_PROJECT_ID).svc.id.goog
	$(KUBECTL) create clusterrolebinding myname-cluster-admin-binding --clusterrole=cluster-admin --user=$(GCLOUD_ACCOUNT_EMAIL)

delete-gke-cluster: gcloud
	-$(GCLOUD) $(GCP_PROJECT_FLAG) container clusters delete $(GKE_CLUSTER_NAME) $(GCP_LOCATION_FLAG) $(GCLOUD_EXTRA_FLAGS)

create-mini-cluster: build/toolchain/bin/minikube$(EXE_EXTENSION)
	$(MINIKUBE) start --memory 6144 --cpus 4 --disk-size 50g

delete-mini-cluster: build/toolchain/bin/minikube$(EXE_EXTENSION)
	-$(MINIKUBE) delete

gcp-apply-binauthz-policy: build/policies/binauthz.yaml
	$(GCLOUD) beta $(GCP_PROJECT_FLAG) container binauthz policy import build/policies/binauthz.yaml

all-protos: $(ALL_PROTOS)

pkg/pb/%.pb.go: api/%.proto third_party/ build/toolchain/bin/protoc$(EXE_EXTENSION) build/toolchain/bin/protoc-gen-go$(EXE_EXTENSION) build/toolchain/bin/protoc-gen-grpc-gateway$(EXE_EXTENSION)
	mkdir -p $(REPOSITORY_ROOT)/pkg/pb
	$(PROTOC) $< \
		-I $(REPOSITORY_ROOT) -I $(PROTOC_INCLUDES) \
		--go_out=plugins=grpc:$(REPOSITORY_ROOT)

internal/pb/%.pb.go: api/%.proto third_party/ build/toolchain/bin/protoc$(EXE_EXTENSION) build/toolchain/bin/protoc-gen-go$(EXE_EXTENSION) build/toolchain/bin/protoc-gen-grpc-gateway$(EXE_EXTENSION)
	mkdir -p $(REPOSITORY_ROOT)/internal/pb
	$(PROTOC) $< \
		-I $(REPOSITORY_ROOT) -I $(PROTOC_INCLUDES) \
		--go_out=plugins=grpc:$(REPOSITORY_ROOT)
	$(SED_REPLACE) 's|pkg/pb|open-match.dev/open-match/pkg/pb|' $@

pkg/pb/%.pb.gw.go: api/%.proto third_party/ build/toolchain/bin/protoc$(EXE_EXTENSION) build/toolchain/bin/protoc-gen-go$(EXE_EXTENSION) build/toolchain/bin/protoc-gen-grpc-gateway$(EXE_EXTENSION)
	mkdir -p $(REPOSITORY_ROOT)/pkg/pb
	$(PROTOC) $< \
		-I $(REPOSITORY_ROOT) -I $(PROTOC_INCLUDES) \
   		--grpc-gateway_out=logtostderr=true,allow_delete_body=true:$(REPOSITORY_ROOT)

internal/pb/%.pb.gw.go: api/%.proto third_party/ build/toolchain/bin/protoc$(EXE_EXTENSION) build/toolchain/bin/protoc-gen-go$(EXE_EXTENSION) build/toolchain/bin/protoc-gen-grpc-gateway$(EXE_EXTENSION)
	mkdir -p $(REPOSITORY_ROOT)/internal/pb
	$(PROTOC) $< \
		-I $(REPOSITORY_ROOT) -I $(PROTOC_INCLUDES) \
   		--grpc-gateway_out=logtostderr=true,allow_delete_body=true:$(REPOSITORY_ROOT)

api/%.swagger.json: api/%.proto third_party/ build/toolchain/bin/protoc$(EXE_EXTENSION) build/toolchain/bin/protoc-gen-swagger$(EXE_EXTENSION)
	$(PROTOC) $< \
		-I $(REPOSITORY_ROOT) -I $(PROTOC_INCLUDES) \
		--swagger_out=logtostderr=true,allow_delete_body=true:$(REPOSITORY_ROOT)

# Include structure of the protos needs to be called out do the dependency chain is run through properly.
pkg/pb/backend.pb.go: pkg/pb/messages.pb.go
pkg/pb/frontend.pb.go: pkg/pb/messages.pb.go
pkg/pb/matchfunction.pb.go: pkg/pb/messages.pb.go
pkg/pb/mmlogic.pb.go: pkg/pb/messages.pb.go
pkg/pb/evaluator.pb.go: pkg/pb/messages.pb.go
internal/pb/synchronizer.pb.go: pkg/pb/messages.pb.go

build: assets
	$(GO) build ./...
	$(GO) build -tags e2ecluster ./... 

test: $(ALL_PROTOS) tls-certs third_party/
	$(GO) test -cover -test.count $(GOLANG_TEST_COUNT) -race ./...
	$(GO) test -cover -test.count $(GOLANG_TEST_COUNT) -run IgnoreRace$$ ./...

test-e2e-cluster: $(ALL_PROTOS) tls-certs third_party/
	$(GO) test ./... -race -tags e2ecluster

stress-frontend-%: build/toolchain/python/
	$(TOOLCHAIN_DIR)/python/bin/locust -f $(REPOSITORY_ROOT)/test/stress/frontend.py --host=http://localhost:$(FRONTEND_PORT) \
		--no-web -c $* -r 100 -t10m --csv=test/stress/stress_user$*

fmt:
	$(GO) fmt ./...
	gofmt -s -w .

vet:
	$(GO) vet ./...

golangci: build/toolchain/bin/golangci-lint$(EXE_EXTENSION)
	GO111MODULE=on $(GOLANGCI) run --config=$(REPOSITORY_ROOT)/.golangci.yaml

lint: fmt vet golangci lint-chart terraform-lint

assets: $(ALL_PROTOS) tls-certs third_party/ build/chart/

# CMDS is a list of all folders in cmd/
CMDS = $(notdir $(wildcard cmd/*))
CMDS_BUILD_FOLDERS = $(foreach CMD,$(CMDS),build/cmd/$(CMD))

build/cmd: $(CMDS_BUILD_FOLDERS)

# Building a given build/cmd folder is split into two pieces: BUILD_PHONY and
# COPY_PHONY.  The BUILD_PHONY is the common go build command, which is
# reusable.  The COPY_PHONY is used by some targets which require additional
# files to be included in the image.
$(CMDS_BUILD_FOLDERS): build/cmd/%: build/cmd/%/BUILD_PHONY build/cmd/%/COPY_PHONY

build/cmd/%/BUILD_PHONY:
	mkdir -p $(BUILD_DIR)/cmd/$*
	CGO_ENABLED=0 $(GO) build -a -installsuffix cgo -o $(BUILD_DIR)/cmd/$*/run open-match.dev/open-match/cmd/$*

# Default is that nothing needs to be copied into the direcotry
build/cmd/%/COPY_PHONY:
	#

build/cmd/swaggerui/COPY_PHONY:
	mkdir -p $(BUILD_DIR)/cmd/swaggerui/static/api
	cp third_party/swaggerui/* $(BUILD_DIR)/cmd/swaggerui/static/
	$(SED_REPLACE) 's|https://open-match.dev/api/v.*/|/api/|g' $(BUILD_DIR)/cmd/swaggerui/static/config.json
	cp api/*.json $(BUILD_DIR)/cmd/swaggerui/static/api/

build/cmd/demo-%/COPY_PHONY:
	mkdir -p $(BUILD_DIR)/cmd/demo-$*/
	cp -r examples/demo/static $(BUILD_DIR)/cmd/demo-$*/static

all: service-binaries example-binaries tools-binaries

service-binaries: cmd/minimatch/minimatch$(EXE_EXTENSION) cmd/swaggerui/swaggerui$(EXE_EXTENSION)
service-binaries: cmd/backend/backend$(EXE_EXTENSION) cmd/frontend/frontend$(EXE_EXTENSION)
service-binaries: cmd/mmlogic/mmlogic$(EXE_EXTENSION) cmd/synchronizer/synchronizer$(EXE_EXTENSION)

example-binaries: example-mmf-binaries example-evaluator-binaries
example-mmf-binaries: examples/functions/golang/soloduel/soloduel$(EXE_EXTENSION) examples/functions/golang/pool/pool$(EXE_EXTENSION)
example-evaluator-binaries: examples/evaluator/golang/simple/simple$(EXE_EXTENSION)

examples/functions/golang/soloduel/soloduel$(EXE_EXTENSION): pkg/pb/mmlogic.pb.go pkg/pb/mmlogic.pb.gw.go api/mmlogic.swagger.json pkg/pb/matchfunction.pb.go pkg/pb/matchfunction.pb.gw.go api/matchfunction.swagger.json
	cd $(REPOSITORY_ROOT)/examples/functions/golang/soloduel; $(GO_BUILD_COMMAND)

examples/functions/golang/pool/pool$(EXE_EXTENSION): pkg/pb/mmlogic.pb.go pkg/pb/mmlogic.pb.gw.go api/mmlogic.swagger.json pkg/pb/matchfunction.pb.go pkg/pb/matchfunction.pb.gw.go api/matchfunction.swagger.json
	cd $(REPOSITORY_ROOT)/examples/functions/golang/pool; $(GO_BUILD_COMMAND)

examples/evaluator/golang/simple/simple$(EXE_EXTENSION): pkg/pb/evaluator.pb.go pkg/pb/evaluator.pb.gw.go api/evaluator.swagger.json
	cd $(REPOSITORY_ROOT)/examples/evaluator/golang/simple; $(GO_BUILD_COMMAND)

tools-binaries: tools/certgen/certgen$(EXE_EXTENSION) tools/reaper/reaper$(EXE_EXTENSION)

cmd/backend/backend$(EXE_EXTENSION): pkg/pb/backend.pb.go pkg/pb/backend.pb.gw.go api/backend.swagger.json
	cd $(REPOSITORY_ROOT)/cmd/backend; $(GO_BUILD_COMMAND)

cmd/frontend/frontend$(EXE_EXTENSION): pkg/pb/frontend.pb.go pkg/pb/frontend.pb.gw.go api/frontend.swagger.json
	cd $(REPOSITORY_ROOT)/cmd/frontend; $(GO_BUILD_COMMAND)

cmd/mmlogic/mmlogic$(EXE_EXTENSION): pkg/pb/mmlogic.pb.go pkg/pb/mmlogic.pb.gw.go api/mmlogic.swagger.json
	cd $(REPOSITORY_ROOT)/cmd/mmlogic; $(GO_BUILD_COMMAND)

cmd/synchronizer/synchronizer$(EXE_EXTENSION): internal/pb/synchronizer.pb.go internal/pb/synchronizer.pb.gw.go api/synchronizer.swagger.json
	cd $(REPOSITORY_ROOT)/cmd/synchronizer; $(GO_BUILD_COMMAND)

# Note: This list of dependencies is long but only add file references here. If you add a .PHONY dependency make will always rebuild it.
cmd/minimatch/minimatch$(EXE_EXTENSION): pkg/pb/backend.pb.go pkg/pb/backend.pb.gw.go api/backend.swagger.json
cmd/minimatch/minimatch$(EXE_EXTENSION): pkg/pb/frontend.pb.go pkg/pb/frontend.pb.gw.go api/frontend.swagger.json
cmd/minimatch/minimatch$(EXE_EXTENSION): pkg/pb/mmlogic.pb.go pkg/pb/mmlogic.pb.gw.go api/mmlogic.swagger.json
cmd/minimatch/minimatch$(EXE_EXTENSION): pkg/pb/evaluator.pb.go pkg/pb/evaluator.pb.gw.go api/evaluator.swagger.json
cmd/minimatch/minimatch$(EXE_EXTENSION): pkg/pb/matchfunction.pb.go pkg/pb/matchfunction.pb.gw.go api/matchfunction.swagger.json
cmd/minimatch/minimatch$(EXE_EXTENSION): pkg/pb/messages.pb.go
cmd/minimatch/minimatch$(EXE_EXTENSION): internal/pb/synchronizer.pb.go internal/pb/synchronizer.pb.gw.go api/synchronizer.swagger.json
	cd $(REPOSITORY_ROOT)/cmd/minimatch; $(GO_BUILD_COMMAND)

cmd/swaggerui/swaggerui$(EXE_EXTENSION): third_party/swaggerui/
	cd $(REPOSITORY_ROOT)/cmd/swaggerui; $(GO_BUILD_COMMAND)

tools/certgen/certgen$(EXE_EXTENSION):
	cd $(REPOSITORY_ROOT)/tools/certgen/ && $(GO_BUILD_COMMAND)

tools/reaper/reaper$(EXE_EXTENSION):
	cd $(REPOSITORY_ROOT)/tools/reaper/ && $(GO_BUILD_COMMAND)

build/policies/binauthz.yaml: install/policies/binauthz.yaml
	mkdir -p $(BUILD_DIR)/policies
	cp -f $(REPOSITORY_ROOT)/install/policies/binauthz.yaml $(BUILD_DIR)/policies/binauthz.yaml
	$(SED_REPLACE) 's/$$PROJECT_ID/$(GCP_PROJECT_ID)/g' $(BUILD_DIR)/policies/binauthz.yaml
	$(SED_REPLACE) 's/$$GKE_CLUSTER_NAME/$(GKE_CLUSTER_NAME)/g' $(BUILD_DIR)/policies/binauthz.yaml
	$(SED_REPLACE) 's/$$GCP_LOCATION/$(GCP_LOCATION)/g' $(BUILD_DIR)/policies/binauthz.yaml
ifeq ($(ENABLE_SECURITY_HARDENING),1)
	$(SED_REPLACE) 's/$$EVALUATION_MODE/ALWAYS_DENY/g' $(BUILD_DIR)/policies/binauthz.yaml
else
	$(SED_REPLACE) 's/$$EVALUATION_MODE/ALWAYS_ALLOW/g' $(BUILD_DIR)/policies/binauthz.yaml
endif

terraform-test: install/terraform/open-match/.terraform/ install/terraform/open-match-build/.terraform/
	(cd $(REPOSITORY_ROOT)/install/terraform/open-match/ && $(TERRAFORM) validate)
	(cd $(REPOSITORY_ROOT)/install/terraform/open-match-build/ && $(TERRAFORM) validate)

terraform-plan: install/terraform/open-match/.terraform/
	(cd $(REPOSITORY_ROOT)/install/terraform/open-match/ && $(TERRAFORM) plan -var gcp_project_id=$(GCP_PROJECT_ID) -var gcp_location=$(GCP_LOCATION))

terraform-lint: build/toolchain/bin/terraform$(EXE_EXTENSION)
	$(TERRAFORM) fmt -recursive

terraform-apply: install/terraform/open-match/.terraform/
	(cd $(REPOSITORY_ROOT)/install/terraform/open-match/ && $(TERRAFORM) apply -var gcp_project_id=$(GCP_PROJECT_ID) -var gcp_location=$(GCP_LOCATION))

install/terraform/open-match/.terraform/: build/toolchain/bin/terraform$(EXE_EXTENSION)
	(cd $(REPOSITORY_ROOT)/install/terraform/open-match/ && $(TERRAFORM) init)

install/terraform/open-match-build/.terraform/: build/toolchain/bin/terraform$(EXE_EXTENSION)
	(cd $(REPOSITORY_ROOT)/install/terraform/open-match-build/ && $(TERRAFORM) init)

build/certificates/: build/toolchain/bin/certgen$(EXE_EXTENSION)
	mkdir -p $(BUILD_DIR)/certificates/
	cd $(BUILD_DIR)/certificates/ && $(CERTGEN)

md-test: docker
	docker run -t --rm -v $(CURDIR):/mnt:ro dkhamsing/awesome_bot --white-list "localhost,https://goreportcard.com,github.com/googleforgames/open-match/tree/release-,github.com/googleforgames/open-match/blob/release-,github.com/googleforgames/open-match/releases/download/v" --allow-dupe --allow-redirect --skip-save-results `find . -type f -name '*.md' -not -path './build/*' -not -path './.git*'`

ci-deploy-artifacts: install/yaml/ $(SWAGGER_JSON_DOCS) build/chart/ gcloud
ifeq ($(_GCB_POST_SUBMIT),1)
	gsutil cp -a public-read $(REPOSITORY_ROOT)/install/yaml/* gs://open-match-chart/install/v$(BASE_VERSION)/yaml/
	gsutil cp -a public-read $(REPOSITORY_ROOT)/api/*.json gs://open-match-chart/api/v$(BASE_VERSION)/
	# Deploy Helm Chart
	# Since each build will refresh just it's version we can allow this for every post submit.
	# Copy the files into multiple locations to keep a backup.
	gsutil cp -a public-read $(BUILD_DIR)/chart/*.* gs://open-match-chart/chart/by-hash/$(VERSION)/
	gsutil cp -a public-read $(BUILD_DIR)/chart/*.* gs://open-match-chart/chart/
else
	@echo "Not deploying build artifacts to open-match.dev because this is not a post commit change."
endif

ci-reap-namespaces: build/toolchain/bin/reaper$(EXE_EXTENSION)
	$(TOOLCHAIN_BIN)/reaper -age=30m

# For presubmit we want to update the protobuf generated files and verify that tests are good.
presubmit: GOLANG_TEST_COUNT = 5
presubmit: clean update-deps third_party/ assets lint build install-toolchain test md-test terraform-test

build/release/: presubmit clean-install-yaml install/yaml/
	mkdir -p $(BUILD_DIR)/release/
	cp $(REPOSITORY_ROOT)/install/yaml/* $(BUILD_DIR)/release/

validate-preview-release:
ifneq ($(_GCB_POST_SUBMIT),1)
	@echo "You must run make with _GCB_POST_SUBMIT=1"
	exit 1
endif
ifneq (,$(findstring -preview,$(BASE_VERSION)))
	@echo "Creating preview for $(BASE_VERSION)"
else
	@echo "BASE_VERSION must contain -preview, it is $(BASE_VERSION)"
	exit 1
endif

preview-release: REGISTRY = gcr.io/$(OPEN_MATCH_PUBLIC_IMAGES_PROJECT_ID)
preview-release: TAG = $(BASE_VERSION)
preview-release: validate-preview-release build/release/ retag-images ci-deploy-artifacts

release: REGISTRY = gcr.io/$(OPEN_MATCH_PUBLIC_IMAGES_PROJECT_ID)
release: TAG = $(BASE_VERSION)
release: build/release/

clean-secrets:
	rm -rf $(OPEN_MATCH_SECRETS_DIR)

clean-release:
	rm -rf $(BUILD_DIR)/release/

clean-protos:
	rm -rf $(REPOSITORY_ROOT)/pkg/pb/
	rm -rf $(REPOSITORY_ROOT)/internal/pb/

clean-binaries:
	rm -rf $(REPOSITORY_ROOT)/cmd/backend/backend$(EXE_EXTENSION)
	rm -rf $(REPOSITORY_ROOT)/cmd/synchronizer/synchronizer$(EXE_EXTENSION)
	rm -rf $(REPOSITORY_ROOT)/cmd/frontend/frontend$(EXE_EXTENSION)
	rm -rf $(REPOSITORY_ROOT)/cmd/mmlogic/mmlogic$(EXE_EXTENSION)
	rm -rf $(REPOSITORY_ROOT)/cmd/minimatch/minimatch$(EXE_EXTENSION)
	rm -rf $(REPOSITORY_ROOT)/examples/functions/golang/soloduel/soloduel$(EXE_EXTENSION)
	rm -rf $(REPOSITORY_ROOT)/examples/functions/golang/pool/pool$(EXE_EXTENSION)
	rm -rf $(REPOSITORY_ROOT)/examples/functions/golang/simple/evaluator$(EXE_EXTENSION)
	rm -rf $(REPOSITORY_ROOT)/cmd/swaggerui/swaggerui$(EXE_EXTENSION)
	rm -rf $(REPOSITORY_ROOT)/tools/certgen/certgen$(EXE_EXTENSION)
	rm -rf $(REPOSITORY_ROOT)/tools/reaper/reaper$(EXE_EXTENSION)

clean-terraform:
	rm -rf $(REPOSITORY_ROOT)/install/terraform/.terraform/

clean-build: clean-toolchain clean-archives clean-release
	rm -rf $(BUILD_DIR)/

clean-toolchain:
	rm -rf $(TOOLCHAIN_DIR)/

clean-chart:
	rm -rf $(BUILD_DIR)/chart/

clean-archives:
	rm -rf $(BUILD_DIR)/archives/

clean-install-yaml:
	rm -f $(REPOSITORY_ROOT)/install/yaml/*

clean-stress-test-tools:
	rm -rf $(TOOLCHAIN_DIR)/python
	rm -f $(REPOSITORY_ROOT)/test/stress/*.csv

clean-swagger-docs:
	rm -rf $(REPOSITORY_ROOT)/api/*.json

clean-third-party:
	rm -rf $(REPOSITORY_ROOT)/third_party/

clean-swaggerui:
	rm -rf $(REPOSITORY_ROOT)/third_party/swaggerui/

clean: clean-images clean-binaries clean-release clean-chart clean-build clean-protos clean-swagger-docs clean-install-yaml clean-stress-test-tools clean-secrets clean-swaggerui clean-terraform clean-third-party

proxy-frontend: build/toolchain/bin/kubectl$(EXE_EXTENSION)
	@echo "Frontend Health: http://localhost:$(FRONTEND_PORT)/healthz"
	@echo "Frontend RPC: http://localhost:$(FRONTEND_PORT)/debug/rpcz"
	@echo "Frontend Trace: http://localhost:$(FRONTEND_PORT)/debug/tracez"
	$(KUBECTL) port-forward --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) $(shell $(KUBECTL) get pod --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) --selector="app=open-match,component=frontend,release=$(OPEN_MATCH_RELEASE_NAME)" --output jsonpath='{.items[0].metadata.name}') $(FRONTEND_PORT):51504 $(PORT_FORWARD_ADDRESS_FLAG)

proxy-backend: build/toolchain/bin/kubectl$(EXE_EXTENSION)
	@echo "Backend Health: http://localhost:$(BACKEND_PORT)/healthz"
	@echo "Backend RPC: http://localhost:$(BACKEND_PORT)/debug/rpcz"
	@echo "Backend Trace: http://localhost:$(BACKEND_PORT)/debug/tracez"
	$(KUBECTL) port-forward --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) $(shell $(KUBECTL) get pod --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) --selector="app=open-match,component=backend,release=$(OPEN_MATCH_RELEASE_NAME)" --output jsonpath='{.items[0].metadata.name}') $(BACKEND_PORT):51505 $(PORT_FORWARD_ADDRESS_FLAG)

proxy-mmlogic: build/toolchain/bin/kubectl$(EXE_EXTENSION)
	@echo "MmLogic Health: http://localhost:$(MMLOGIC_PORT)/healthz"
	@echo "MmLogic RPC: http://localhost:$(MMLOGIC_PORT)/debug/rpcz"
	@echo "MmLogic Trace: http://localhost:$(MMLOGIC_PORT)/debug/tracez"
	$(KUBECTL) port-forward --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) $(shell $(KUBECTL) get pod --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) --selector="app=open-match,component=mmlogic,release=$(OPEN_MATCH_RELEASE_NAME)" --output jsonpath='{.items[0].metadata.name}') $(MMLOGIC_PORT):51503 $(PORT_FORWARD_ADDRESS_FLAG)

proxy-synchronizer: build/toolchain/bin/kubectl$(EXE_EXTENSION)
	@echo "Synchronizer Health: http://localhost:$(SYNCHRONIZER_PORT)/healthz"
	@echo "Synchronizer RPC: http://localhost:$(SYNCHRONIZER_PORT)/debug/rpcz"
	@echo "Synchronizer Trace: http://localhost:$(SYNCHRONIZER_PORT)/debug/tracez"
	$(KUBECTL) port-forward --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) $(shell $(KUBECTL) get pod --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) --selector="app=open-match,component=synchronizer,release=$(OPEN_MATCH_RELEASE_NAME)" --output jsonpath='{.items[0].metadata.name}') $(SYNCHRONIZER_PORT):51506 $(PORT_FORWARD_ADDRESS_FLAG)

proxy-grafana: build/toolchain/bin/kubectl$(EXE_EXTENSION)
	@echo "User: admin"
	@echo "Password: openmatch"
	$(KUBECTL) port-forward --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) $(shell $(KUBECTL) get pod --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) --selector="app=grafana,release=$(OPEN_MATCH_RELEASE_NAME)" --output jsonpath='{.items[0].metadata.name}') $(GRAFANA_PORT):3000 $(PORT_FORWARD_ADDRESS_FLAG)

proxy-prometheus: build/toolchain/bin/kubectl$(EXE_EXTENSION)
	$(KUBECTL) port-forward --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) $(shell $(KUBECTL) get pod --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) --selector="app=prometheus,component=server,release=$(OPEN_MATCH_RELEASE_NAME)" --output jsonpath='{.items[0].metadata.name}') $(PROMETHEUS_PORT):9090 $(PORT_FORWARD_ADDRESS_FLAG)

proxy-dashboard: build/toolchain/bin/kubectl$(EXE_EXTENSION)
	$(KUBECTL) port-forward --namespace kube-system $(shell $(KUBECTL) get pod --namespace kube-system --selector="app=kubernetes-dashboard" --output jsonpath='{.items[0].metadata.name}') $(DASHBOARD_PORT):9092 $(PORT_FORWARD_ADDRESS_FLAG)

proxy-ui: build/toolchain/bin/kubectl$(EXE_EXTENSION)
	@echo "SwaggerUI Health: http://localhost:$(SWAGGERUI_PORT)/"
	$(KUBECTL) port-forward --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) $(shell $(KUBECTL) get pod --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) --selector="app=open-match,component=swaggerui,release=$(OPEN_MATCH_RELEASE_NAME)" --output jsonpath='{.items[0].metadata.name}') $(SWAGGERUI_PORT):51500 $(PORT_FORWARD_ADDRESS_FLAG)

proxy-demo: build/toolchain/bin/kubectl$(EXE_EXTENSION)
	@echo "View Demo: http://localhost:$(DEMO_PORT)"
	$(KUBECTL) port-forward --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) $(shell $(KUBECTL) get pod --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) --selector="app=open-match-demo,component=demo,release=$(OPEN_MATCH_RELEASE_NAME)" --output jsonpath='{.items[0].metadata.name}') $(DEMO_PORT):51507 $(PORT_FORWARD_ADDRESS_FLAG)

proxy-locust: build/toolchain/bin/kubectl$(EXE_EXTENSION)
	@echo "Locust UI: http://localhost:$(LOCUST_PORT)"
	$(KUBECTL) port-forward --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) $(shell $(KUBECTL) get pod --namespace $(OPEN_MATCH_KUBERNETES_NAMESPACE) --selector="app=open-match-test,component=locust-master,release=$(OPEN_MATCH_RELEASE_NAME)" --output jsonpath='{.items[0].metadata.name}') $(LOCUST_PORT):8089 $(PORT_FORWARD_ADDRESS_FLAG)

# Run `make proxy` instead to run everything at the same time.
# If you run this directly it will just run each proxy sequentially.
proxy-all: proxy-frontend proxy-backend proxy-mmlogic proxy-grafana proxy-prometheus proxy-synchronizer proxy-ui proxy-dashboard proxy-demo

proxy:
	# This is an exception case where we'll call recursive make.
	# To simplify accessing all the proxy ports we'll call `make proxy-all` with enough subprocesses to run them concurrently.
	$(MAKE) proxy-all -j20

update-deps:
	$(GO) mod tidy

third_party/: third_party/google/api third_party/protoc-gen-swagger/options third_party/swaggerui/

third_party/google/api:
	mkdir -p $(TOOLCHAIN_DIR)/googleapis-temp/
	mkdir -p $(REPOSITORY_ROOT)/third_party/google/api
	mkdir -p $(REPOSITORY_ROOT)/third_party/google/rpc
	curl -o $(TOOLCHAIN_DIR)/googleapis-temp/googleapis.zip -L https://github.com/googleapis/googleapis/archive/master.zip
	(cd $(TOOLCHAIN_DIR)/googleapis-temp/; unzip -q -o googleapis.zip)
	cp -f $(TOOLCHAIN_DIR)/googleapis-temp/googleapis-master/google/api/*.proto $(REPOSITORY_ROOT)/third_party/google/api/
	cp -f $(TOOLCHAIN_DIR)/googleapis-temp/googleapis-master/google/rpc/*.proto $(REPOSITORY_ROOT)/third_party/google/rpc/
	rm -rf $(TOOLCHAIN_DIR)/googleapis-temp

third_party/protoc-gen-swagger/options:
	mkdir -p $(TOOLCHAIN_DIR)/grpc-gateway-temp/
	mkdir -p $(REPOSITORY_ROOT)/third_party/protoc-gen-swagger/options
	curl -o $(TOOLCHAIN_DIR)/grpc-gateway-temp/grpc-gateway.zip -L https://github.com/grpc-ecosystem/grpc-gateway/archive/master.zip
	(cd $(TOOLCHAIN_DIR)/grpc-gateway-temp/; unzip -q -o grpc-gateway.zip)
	cp -f $(TOOLCHAIN_DIR)/grpc-gateway-temp/grpc-gateway-master/protoc-gen-swagger/options/*.proto $(REPOSITORY_ROOT)/third_party/protoc-gen-swagger/options/
	rm -rf $(TOOLCHAIN_DIR)/grpc-gateway-temp

third_party/swaggerui/:
	mkdir -p $(TOOLCHAIN_DIR)/swaggerui-temp/
	mkdir -p $(TOOLCHAIN_BIN)
	curl -o $(TOOLCHAIN_DIR)/swaggerui-temp/swaggerui.zip -L \
		https://github.com/swagger-api/swagger-ui/archive/v$(SWAGGERUI_VERSION).zip
	(cd $(TOOLCHAIN_DIR)/swaggerui-temp/; unzip -q -o swaggerui.zip)
	cp -rf $(TOOLCHAIN_DIR)/swaggerui-temp/swagger-ui-$(SWAGGERUI_VERSION)/dist/ \
		$(REPOSITORY_ROOT)/third_party/swaggerui
	# Update the URL in the main page to point to a known good endpoint.
	cp $(REPOSITORY_ROOT)/cmd/swaggerui/config.json $(REPOSITORY_ROOT)/third_party/swaggerui/
	$(SED_REPLACE) 's|url:.*|configUrl: "/config.json",|g' $(REPOSITORY_ROOT)/third_party/swaggerui/index.html
	$(SED_REPLACE) 's|0.0.0-dev|$(BASE_VERSION)|g' $(REPOSITORY_ROOT)/third_party/swaggerui/config.json
	rm -rf $(TOOLCHAIN_DIR)/swaggerui-temp

sync-deps:
	$(GO) clean -modcache
	$(GO) mod download

sleep-10:
	sleep 10

sleep-30:
	sleep 30

# Prevents users from running with sudo.
# There's an exception for Google Cloud Build because it runs as root.
no-sudo:
ifndef OPEN_MATCH_CI_MODE
ifeq ($(shell whoami),root)
	@echo "ERROR: Running Makefile as root (or sudo)"
	@echo "Please follow the instructions at https://docs.docker.com/install/linux/linux-postinstall/ if you are trying to sudo run the Makefile because of the 'Cannot connect to the Docker daemon' error."
	@echo "NOTE: sudo/root do not have the authentication token to talk to any GCP service via gcloud."
	exit 1
endif
endif

.PHONY: docker gcloud update-deps sync-deps sleep-10 sleep-30 all build proxy-dashboard proxy-prometheus proxy-grafana clean clean-build clean-toolchain clean-archives clean-binaries clean-protos presubmit test ci-reap-namespaces md-test vet
