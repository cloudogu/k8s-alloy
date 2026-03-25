#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

componentTemplateFile="k8s/helm/component-patch-tpl.yaml"
alloyTempChart="/tmp/alloy"
alloyTempValues="${alloyTempChart}/values.yaml"
alloyTempChartYaml="${alloyTempChart}/Chart.yaml"

# this function will be sourced from release.sh and be called from release_functions.sh
update_versions_modify_files() {
  echo "Update helm dependencies"
  make helm-update-dependencies  > /dev/null

  # Extract alloy chart
  local alloyVersion
  alloyVersion=$(./.bin/yq '.dependencies[] | select(.name=="alloy").version' < "k8s/helm/Chart.yaml")
  local alloyPackage
  alloyPackage="k8s/helm/charts/alloy-${alloyVersion}.tgz"

  echo "Extract alloy helm chart"
  tar -zxvf "${alloyPackage}" -C "/tmp" > /dev/null

  local alloyAppVersion
  alloyAppVersion=$(./.bin/yq '.appVersion' < "${alloyTempChartYaml}")

  echo "Set images in component patch template"

  local alloyImageRegistry
  local alloyImageRepo
  alloyImageRegistry=$(./.bin/yq '.image.registry' < "${alloyTempValues}")
  alloyImageRepo=$(./.bin/yq '.image.repository' < "${alloyTempValues}")
  setAttributeInComponentPatchTemplate ".values.images.alloy" "${alloyImageRegistry}/${alloyImageRepo}:${alloyAppVersion}"

  local alloyConfigReloadRegistry
  local alloyConfigReloadRepo
  local alloyConfigReloadTag
  alloyConfigReloadRegistry=$(./.bin/yq '.configReloader.image.registry' < "${alloyTempValues}")
  alloyConfigReloadRepo=$(./.bin/yq '.configReloader.image.repository' < "${alloyTempValues}")
  alloyConfigReloadTag=$(./.bin/yq '.configReloader.image.tag' < "${alloyTempValues}")
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
