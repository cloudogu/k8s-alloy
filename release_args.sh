#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

componentTemplateFile="k8s/helm/component-patch-tpl.yaml"

# this function will be sourced from release.sh and be called from release_functions.sh
update_versions_modify_files() {
  echo "Set images in component patch template"

  local alloyImageRegistry
  local alloyImageRepo
  alloyAppVersion=$(./.bin/yq '.alloy.image.tag' < "k8s/helm/values.yaml")
  alloyImageRegistry=docker.io
  alloyImageRepo=grafana/alloy
  setAttributeInComponentPatchTemplate ".values.images.alloy" "${alloyImageRegistry}/${alloyImageRepo}:${alloyAppVersion}"

  local alloyConfigReloadRegistry
  local alloyConfigReloadRepo
  local alloyConfigReloadTag
  alloyConfigReloadRegistry=quay.io
  alloyConfigReloadRepo=prometheus-operator/prometheus-config-reloader
  alloyConfigReloadTag=$(./.bin/yq '.alloy.configReloader.image.tag' < "k8s/helm/values.yaml")
  setAttributeInComponentPatchTemplate ".values.images.configReloader" "${alloyConfigReloadRegistry}/${alloyConfigReloadRepo}:${alloyConfigReloadTag}"
}

setAttributeInComponentPatchTemplate() {
  local key="${1}"
  local value="${2}"

  ./.bin/yq -i "${key} = \"${value}\"" "${componentTemplateFile}"
}

update_versions_stage_modified_files() {
  git add "${componentTemplateFile}"
}
