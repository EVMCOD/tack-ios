#!/usr/bin/env python3
"""Pull named screenshot attachments out of an .xcresult into a flat folder."""
import json, subprocess, sys, shutil
from pathlib import Path

result, out = Path(sys.argv[1]), Path(sys.argv[2])
out.mkdir(parents=True, exist_ok=True)
tmp = out / "_raw"
if tmp.exists(): shutil.rmtree(tmp)
tmp.mkdir()

subprocess.run(["xcrun", "xcresulttool", "export", "attachments",
                "--path", str(result), "--output-path", str(tmp)],
               check=True, capture_output=True)

manifest = json.loads((tmp / "manifest.json").read_text())
n = 0
for test in manifest:
    for att in test.get("attachments", []):
        name = att.get("suggestedHumanReadableName") or att.get("exportedFileName", "")
        if not name.endswith(".png"):
            continue
        src = tmp / att["exportedFileName"]
        dst = out / name
        shutil.copyfile(src, dst)
        n += 1
        print(f"  → {dst}")
shutil.rmtree(tmp)
if n == 0:
    print("  ⚠️  no PNG attachments found — did the test fail before capturing?")
