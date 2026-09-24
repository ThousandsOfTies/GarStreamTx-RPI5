# GarStreamTx-RPI5 Agent Rules

This Product repository is named `GarStreamTx-RPI5` and fixes the `gar-stream-tx`
application to `raspberry-pi-5`. Do not add another physical target or restore a
Deployment dispatcher. Create another Product repository when the same application
needs a different physical target.

- `sources`: pinned application and reusable-tool submodules
- `hardware`: Product-specific hardware requirements and fixed binding
- `config/artifact.json`: fixed target artifact contract
- `scripts/target`: Product-specific physical target implementation

Keep reusable board support in `sources/gar-tools`. Commit and push child
repository changes before updating parent submodule pointers. Generated
artifacts are not committed.

## Web simulator

For any GAR App simulator, read `sources/gar-tools/AGENTS.md`
before editing the panel. If the pinned copy lacks it, consult the latest
gar-tools guide; update the pin when using newer shared components. Build
reusable device UI and interactions as shared Web
Components in `sources/gar-tools/web-simulator/components/`; keep Product
mapping, bridge protocol, and commands in the Product adapter.
