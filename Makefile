ARTIFACT_ID=k8s-alloy
MAKEFILES_VERSION=10.7.2
VERSION=1.1.2-2

.DEFAULT_GOAL:=help

ADDITIONAL_CLEAN=clean_charts
clean_charts:
	rm -rf ${K8S_HELM_RESSOURCES}/charts

include build/make/variables.mk
include build/make/clean.mk
include build/make/release.mk
include build/make/self-update.mk
include build/make/k8s.mk

##@ Release

include build/make/k8s-component.mk

.PHONY: alloy-release ${BINARY_YQ}
alloy-release: ## Interactively starts the release workflow for alloy
	@echo "Starting git flow release..."
	@build/make/release.sh alloy
