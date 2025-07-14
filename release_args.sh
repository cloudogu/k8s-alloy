#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

componentTemplateFile=k8s/helm/component-patch-tpl.yaml
lokiTempChart="/tmp/loki"
lokiTempValues="${lokiTempChart}/values.yaml"
lokiTempChartYaml="${lokiTempChart}/Chart.yaml"

lokiValues="k8s/helm/values.yaml"

# this function will be sourced from release.sh and be called from release_functions.sh
update_versions_modify_files() {
  echo "Update helm dependencies"
  make helm-update-dependencies  > /dev/null

  # Extract loki chart
  local lokiVersion
  lokiVersion=$(yq '.dependencies[] | select(.name=="loki").version' < "k8s/helm/Chart.yaml")
  local lokiPackage
  lokiPackage="k8s/helm/charts/loki-${lokiVersion}.tgz"

  echo "Extract loki helm chart"
  tar -zxvf "${lokiPackage}" -C "/tmp" > /dev/null

  local lokiAppVersion
  lokiAppVersion=$(yq '.appVersion' < "${lokiTempChartYaml}")

  echo "Set images in component patch template"

  local lokiKubectlRegistry
  local lokiKubectlRepo
  local lokiKubectlTag
  lokiKubectlRegistry=$(yq '.loki.kubectlImage.registry' < "${lokiValues}")
  lokiKubectlRepo=$(yq '.loki.kubectlImage.repository' < "${lokiValues}")
  lokiKubectlTag=$(yq '.loki.kubectlImage.tag' < "${lokiValues}")
  setAttributeInComponentPatchTemplate ".values.images.kubectl" "${lokiKubectlRegistry}/${lokiKubectlRepo}:${lokiKubectlTag}"

  local lokiImageRegistry
  local lokiImageRepo
  lokiImageRegistry=$(yq '.loki.image.registry' < "${lokiTempValues}")
  lokiImageRepo=$(yq '.loki.image.repository' < "${lokiTempValues}")
  setAttributeInComponentPatchTemplate ".values.images.loki" "${lokiImageRegistry}/${lokiImageRepo}:${lokiAppVersion}"

  local lokiCanaryRegistry
  local lokiCanaryRepo
  lokiCanaryRegistry=$(yq '.lokiCanary.image.registry' < "${lokiTempValues}")
  lokiCanaryRepo=$(yq '.lokiCanary.image.repository' < "${lokiTempValues}")
  setAttributeInComponentPatchTemplate ".values.images.lokiCanary" "${lokiCanaryRegistry}/${lokiCanaryRepo}:${lokiAppVersion}"

  local lokiGatewayRegistry
  local lokiGatewayRepo
  local lokiGatewayTag
  lokiGatewayRegistry=$(yq '.gateway.image.registry' < "${lokiTempValues}")
  lokiGatewayRepo=$(yq '.gateway.image.repository' < "${lokiTempValues}")
  lokiGatewayTag=$(yq '.gateway.image.tag' < "${lokiTempValues}")
  setAttributeInComponentPatchTemplate ".values.images.gateway" "${lokiGatewayRegistry}/${lokiGatewayRepo}:${lokiGatewayTag}"

  local lokiSidecarRegistryRepo
  local lokiSidecarTag
  lokiSidecarRegistryRepo=$(yq '.sidecar.image.repository' < "${lokiTempValues}")
  lokiSidecarTag=$(yq '.sidecar.image.tag' < "${lokiTempValues}")
  setAttributeInComponentPatchTemplate ".values.images.sidecar" "${lokiSidecarRegistryRepo}:${lokiSidecarTag}"

  rm -rf ${lokiTempChart}
}

setAttributeInComponentPatchTemplate() {
  local key="${1}"
  local value="${2}"

  yq -i "${key} = \"${value}\"" "${componentTemplateFile}"
}

update_versions_stage_modified_files() {
  git add "${componentTemplateFile}"
}
