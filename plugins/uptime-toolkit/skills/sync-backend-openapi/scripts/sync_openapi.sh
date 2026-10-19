#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../../../.." && pwd)"
backend_dir="${repo_root}/backend"

cd "${backend_dir}"
swag init -g cmd/server/main.go -d . -o docs --parseInternal --parseDependency
npx --yes @redocly/cli build-docs docs/swagger.yaml -o docs/swagger.html
