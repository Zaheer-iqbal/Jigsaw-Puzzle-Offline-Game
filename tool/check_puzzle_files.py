import json
import os

with open("assets/puzzles_manifest.json", "r", encoding="utf-8") as f:
    manifest = json.load(f)

print(f"Manifest total items: {len(manifest)}")

missing_files = []
small_files = []
valid_files = []

for item in manifest:
    path = item["path"]
    if not os.path.exists(path):
        missing_files.append((item["id"], path))
    else:
        sz = os.path.getsize(path)
        if sz < 1000:
            small_files.append((item["id"], path, sz))
        else:
            valid_files.append((item["id"], path, sz))

print(f"Valid existing files (>1KB): {len(valid_files)}")
print(f"Missing files: {len(missing_files)}")
print(f"Empty/Corrupt (<1KB): {len(small_files)}")

if missing_files:
    print("Missing samples:", missing_files[:5])
