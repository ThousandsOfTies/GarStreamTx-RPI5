#!/usr/bin/env bash
# Product artifact selection; build and launch generation live in gar-tools.
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ -f "${repo_root}/config/product.env" ]]; then
  source "${repo_root}/config/product.env"
fi
output="${GAR_TARGET_ARTIFACT_ROOT:-artifacts/from-codespace}"
if [[ "$#" -eq 1 && "$1" == clean ]]; then
  exec python3 "${repo_root}/tools/product.py" clean --output "$output"
fi
if [[ "$#" -ne 0 ]]; then echo "usage: $0 [clean]" >&2; exit 2; fi
exec python3 "${repo_root}/tools/product.py" package --replace --output "$output"
