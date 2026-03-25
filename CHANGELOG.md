# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v1.1.2-3] - 2026-03-25
### Security
- [#6] Update config reloader to v0.90.0 to fix CVEs
- [#6] Update alloy to 1.14.2 to fix CVE-2026-33186

## [v1.1.2-2] - 2026-03-18

### Changed
- [#3] Update alloy to v.1.14.0 to fix CVE-2025-68121
- [#4] Configure alloy to send logs to loki
  - This replaces promtail because it is not actively maintained anymore.

## [v1.1.2-1] - 2025-07-22

### Added

- [#1] Adds initial component for Grafana Alloy
  - `k8s-alloy` watches events from the kubernetes api and send them as log line to `k8s-loki`

