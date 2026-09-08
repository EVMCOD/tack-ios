#!/usr/bin/env bash
# Regenerate the Xcode project from project.yml.
set -euo pipefail
cd "$(dirname "$0")/.."
xcodegen generate "$@"
