# GarStreamTx-RPI5 Agent Rules

This Product repository is named `GarStreamTx-RPI5` and fixes the `gar-stream-tx`
application to `raspberry-pi-5`. Do not add another physical target or restore a
Deployment dispatcher. Create another Product repository when the same application
needs a different physical target.

- `sources`: pinned application and reusable-tool submodules
- `hardware`: Product-specific hardware requirements and fixed binding
- `config/artifact.json`: fixed target artifact contract
- `scripts/target`: Product-specific physical target implementation

Board/OS resource data belong to `sources/board-raspberry-pi-5`; generic
composition, build, packaging and simulator mechanisms belong to `sources/gar-tools`.
Read `product.json` and `docs/COMPOSITION.md` before changing that split.
Commit and push child
repository changes before updating parent submodule pointers. Generated
artifacts are not committed.

## Web simulator

For any GAR App simulator, read `sources/gar-tools/AGENTS.md`
before editing the panel. If the pinned copy lacks it, consult the latest
gar-tools guide; update the pin when using newer shared components. Build
reusable device UI and interactions as shared Web
Components in `sources/gar-tools/web-simulator/components/`; keep Product
mapping, bridge protocol, and commands in the Product adapter.


## Composition

Product-owned hardware CSVs select peripheral uses. product.json selects the
application, tools and board profile, application options, and deployment owner.
Never copy board resource inventory into the application or Product hooks.
The existing GAR Target Pack is a compatibility path; do not rewrite GAR core,
install a second startup manager, change live target settings or redeploy hardware
as part of this offline refactor. Preserve named runtime environment overrides.
GarAdhocApp remains planned until a physical port is separately implemented and
verified; do not make packaging succeed just to satisfy a composition check.
