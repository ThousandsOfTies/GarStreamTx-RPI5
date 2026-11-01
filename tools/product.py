#!/usr/bin/env python3
"""Use the pinned composition engine for this Product."""
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
if __name__ == '__main__':
    data = json.loads((ROOT / 'product.json').read_text(encoding='utf-8'))
    cli = ROOT / data['components']['tools'] / 'composition/cli.py'
    raise SystemExit(subprocess.call([sys.executable, str(cli), '--root', str(ROOT), *sys.argv[1:]]))
