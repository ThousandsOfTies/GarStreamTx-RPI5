#!/usr/bin/env bash
# Fixed Raspberry Pi 5 target entrypoint; this repository has no target selector.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -n "${GAR_TARGET:-}" && "$GAR_TARGET" != raspberry-pi-5 ]]; then
  echo "GarStreamTx has fixed target raspberry-pi-5, not $GAR_TARGET" >&2
  exit 2
fi
export GAR_TARGET=raspberry-pi-5
export GAR_TARGET_ARTIFACT_MANIFEST="${repo_root}/config/artifact.json"
exec "${repo_root}/scripts/target/package.sh" "$@"
