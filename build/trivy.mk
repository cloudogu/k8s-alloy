TRIVY_VERSION?=0.76.1
TRIVY_PLATFORM?=linux/amd64
TRIVY_REPORT_DIR?=$(TARGET_DIR)/trivy
TRIVY_CACHE_DIR?=$(TMP_DIR)/trivy
TRIVY_ADDITIONAL_IMAGES?=
# Override with TRIVY=trivy to use a locally installed scanner.
TRIVY?=docker run --rm --user "$(UID_NR):$(GID_NR)" \
	--env HOME=/tmp --volume "$(WORKDIR):$(WORKDIR)" --workdir "$(WORKDIR)" \
	aquasec/trivy:$(TRIVY_VERSION)

##@ Vulnerability scan

.PHONY: trivy-scan
trivy-scan: $(BINARY_HELM) $(BINARY_YQ) helm-generate ## Scan runtime images from the rendered chart and save JSON/text reports.
	@mkdir -p "$(TRIVY_REPORT_DIR)" "$(TRIVY_CACHE_DIR)"
	@rm -f "$(TRIVY_REPORT_DIR)"/*.json "$(TRIVY_REPORT_DIR)"/*.txt
	@$(BINARY_HELM) template $(COMPONENT_ARTIFACT_ID) "$(HELM_TARGET_DIR)" > "$(TRIVY_REPORT_DIR)/resources.yaml"
	@{ $(BINARY_YQ) --no-doc '.. | .image? | select(tag == "!!str")' "$(TRIVY_REPORT_DIR)/resources.yaml"; \
		printf '%s\n' $(foreach image,$(TRIVY_ADDITIONAL_IMAGES),"$(image)"); \
	} | sed '/^$$/d' | sort -u > "$(TRIVY_REPORT_DIR)/images.txt"
	@test -s "$(TRIVY_REPORT_DIR)/images.txt" || { echo "No images found to scan"; exit 1; }
	@while IFS= read -r image; do \
		report_name=$$(printf '%s' "$$image" | tr '/:@' '___'); \
		echo "Scanning $$image ($(TRIVY_PLATFORM))"; \
		$(TRIVY) --cache-dir "$(TRIVY_CACHE_DIR)" image \
			--image-src remote --platform "$(TRIVY_PLATFORM)" --scanners vuln \
			--exit-code 0 --timeout 15m --no-progress --list-all-pkgs \
			--format json --output "$(TRIVY_REPORT_DIR)/$$report_name.json" "$$image"; \
		$(TRIVY) convert --scanners vuln --format table \
			--output "$(TRIVY_REPORT_DIR)/$$report_name.txt" "$(TRIVY_REPORT_DIR)/$$report_name.json"; \
	done < "$(TRIVY_REPORT_DIR)/images.txt"
	@$(TRIVY) --cache-dir "$(TRIVY_CACHE_DIR)" --version > "$(TRIVY_REPORT_DIR)/scanner.txt"
