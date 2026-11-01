from __future__ import annotations

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class ProductAssetOwnershipTests(unittest.TestCase):
    def test_rv1106_product_logic_moved_to_its_own_repository(self) -> None:
        moved = (
            "hardware/targets/luckfox-rv1106/gpio.csv",
            "tools/rv1106/app-template/src/main.cpp",
            "tools/rv1106/runtime/bin/gar-luckfox-sim-isp-engine",
            "tools/rv1106/runtime/bin/gar-luckfox-sim-rotary-ui",
            "tools/rv1106/scripts/luckfox_push_rtsp.sh",
            "docs/rv1106/05_RV1106_FEATURE_MENU.md",
        )

        for relative_path in moved:
            with self.subTest(path=relative_path):
                self.assertFalse((ROOT / relative_path).is_file())

    def test_panel_uses_shared_hardware_components(self) -> None:
        panel = (ROOT / "panel" / "index.html").read_text(encoding="utf-8")

        self.assertIn("./studio.js", panel)
        self.assertIn("<gar-camera-input", panel)
        self.assertIn("<gar-display", panel)
        self.assertIn("<gar-rotary", panel)
        self.assertIn("<gar-connection-status", panel)
        self.assertFalse((ROOT / "panel" / "components" / "video-transmitter.js").exists())

        shared_root = ROOT / "sources" / "gar-tools" / "web-simulator" / "components"
        for name in ("camera-input.mjs", "connection-status.mjs", "display.mjs", "framebuffer.mjs", "rotary.mjs"):
            with self.subTest(shared_component=name):
                self.assertTrue((shared_root / name).is_file())

        bridge = (
            ROOT / "sources" / "gar-tools" / "targets" / "linux-device"
            / "runtime" / "web-bridge" / "bridge.py"
        ).read_text(encoding="utf-8")
        self.assertIn('"gar-components/"', bridge)
        self.assertIn("WEB_COMPONENTS_DIR", bridge)


if __name__ == "__main__":
    unittest.main()
