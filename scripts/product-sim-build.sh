#!/usr/bin/env bash
# GaplessAgentRuntime invokes scripts/product-sim-build.sh for `gar sim build`.
# GarStreamTx is a Python application for the Raspberry Pi 5.  The simulation
# artifact is a validated application bundle; `gar sim env build` separately
# builds the Linux device stubs and web bridge.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "${repo_root}/config/product.env" ]]; then
  # shellcheck disable=SC1091
  source "${repo_root}/config/product.env"
fi

app_dir="$(python3 "${repo_root}/tools/product.py" component application)"
tools_dir="$(python3 "${repo_root}/tools/product.py" component tools)"
target="${GAR_SIM_TARGET:-linux-device}"
artifact_root="${repo_root}/${GAR_SIM_ARTIFACT_ROOT:-artifacts/from-codespace}"
artifact_dir="${artifact_root}/files/gar-stream-tx"
panel_dir="${artifact_root}/files/panel"
panel_dest="/usr/local/share/gar/panels/gar-stream-tx"
deploy_dest="${GAR_SIM_ARTIFACT_DEST:-/usr/local/lib/gar/apps/gar-stream-tx}"
service_file="${artifact_root}/files/gar-sim-app.service"
service_dest="/etc/systemd/system/gar-sim-app.service"

if [[ "$#" -gt 1 || ( "$#" -eq 1 && "$1" != "clean" ) ]]; then
  echo "usage: $0 [clean]" >&2
  exit 2
fi

if [[ "${1:-}" == "clean" ]]; then
  rm -rf "${artifact_root}"
  echo "Removed simulation artifact: ${artifact_root}"
  exit 0
fi

if [[ ! -f "${app_dir}/camera_tx.py" || ! -f "${app_dir}/requirements.txt" || ! -d "${repo_root}/panel" || ! -d "${tools_dir}/targets/linux-device/runtime" ]]; then
  echo "missing simulation sources; run: git submodule update --init --recursive" >&2
  exit 1
fi

rm -rf "${artifact_dir}" "${panel_dir}"
mkdir -p "${artifact_dir}"

# Compile the copied sources so build output never adds __pycache__ to the
# application submodule checked out by this product branch.
cp "${app_dir}"/*.py "${app_dir}/requirements.txt" "${artifact_dir}/"
# Legacy artifacts without filtering do not require the helper.
debounce_helper="${tools_dir}/targets/linux-device/runtime/gpio-input/python/gar_gpio_debounce.py"
if [[ -f "$debounce_helper" ]]; then
    install -m 0644 "$debounce_helper" "${artifact_dir}/gar_gpio_debounce.py"
fi
cp -a "${repo_root}/panel" "${panel_dir}"
# Resolve defaults from the Product and its generated simulation hardware.
sim_environment="$(python3 "${repo_root}/tools/product.py" environment --environment simulation --format systemd)"
python3 -m compileall -q -f "${artifact_dir}"

printf '%s\n' "${panel_dest}" > "${artifact_root}/files/panel-dir"

cat > "${service_file}" <<EOF
[Unit]
Description=GarStreamTx simulation application
After=network-online.target gar-v4l2-camera.service gar-gpio-sim.service gar-cuse-spi@spidev0.0.service gar-bridge.service
Wants=network-online.target gar-v4l2-camera.service gar-gpio-sim.service gar-cuse-spi@spidev0.0.service gar-bridge.service
PartOf=gar-sim.target

[Service]
Type=simple
WorkingDirectory=${deploy_dest}
${sim_environment}
# System topology values are materialised here by gar system deploy.  Keep
# this after the static fallbacks: systemd applies assignments in declaration
# order, so a non-default link port takes precedence at runtime.
EnvironmentFile=-/etc/gar/system/gar-stream-tx.env
ExecStartPre=/bin/sh -c 'for n in \$(seq 1 50); do [ -S /run/gar/hw_sim.sock ] && exit 0; sleep 0.1; done; exit 1'
ExecStart=/usr/bin/python3 ${deploy_dest}/camera_tx.py
Restart=on-failure
RestartSec=3
EOF

python3 - "${artifact_root}/artifact.json" "${target}" "${deploy_dest}" "${panel_dest}" "${service_dest}" <<'PY'
from __future__ import annotations

import json
import sys
from pathlib import Path

output, target, destination, panel_destination, service_destination = sys.argv[1:]
output_path = Path(output)
try:
    payload = json.loads(output_path.read_text(encoding="utf-8"))
except FileNotFoundError:
    payload = {"name": "gar-stream-tx-simulation", "deploy": {}}

payload["name"] = "gar-stream-tx-simulation"
payload["target"] = target
deploy = payload.setdefault("deploy", {})
deploy["app"] = {
    "files": [
        {
            "src": "files/gar-stream-tx",
            "dest": destination,
        },
        {"src": "files/panel", "dest": panel_destination},
        {"src": "files/panel-dir", "dest": "/etc/gar/panel-dir", "mode": "0644"},
        {"src": "files/gar-sim-app.service", "dest": service_destination, "mode": "0644"},
    ]
}
output_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

echo "Target: ${target}"
echo "Artifact: ${artifact_root}"
