import re
import json

with open("tool/raw_user_prompts.txt", "r", encoding="utf-8") as f:
    text = f.read()

# Category mapping
cat_headers = [
    ("animals", r"##\s*Animals"),
    ("nature", r"##\s*Nature"),
    ("flowers", r"##\s*Flowers"),
    ("landmarks", r"##\s*Landmarks"),
    ("art", r"##\s*Art")
]

# Find start positions of each category section
sections = []
for cat, pattern in cat_headers:
    m = re.search(pattern, text, re.IGNORECASE)
    if not m:
        raise Exception(f"Category header not found for {cat}")
    sections.append((cat, m.start()))

sections.sort(key=lambda x: x[1])

puzzles = []

for idx, (cat, start_pos) in enumerate(sections):
    end_pos = sections[idx + 1][1] if idx + 1 < len(sections) else len(text)
    section_text = text[start_pos:end_pos]
    
    # Pattern for each item: **id - Title** followed by prompt text
    # e.g.: **a001 - Kitten Cozy**\na fluffy kitten wearing...
    pattern = r"\*\*([anflr]\d{3})\s*-\s*([^\*\n]+)\*\*\s*\n+([^\n\*]+(?:(?!\*\*|\#\#)[^\n\*]+)*)"
    matches = list(re.finditer(pattern, section_text, re.MULTILINE))
    
    print(f"Category {cat}: found {len(matches)} items")
    for m in matches:
        pid = m.group(1).strip()
        title = m.group(2).strip()
        prompt = m.group(3).strip()
        # Clean extra spaces in prompt
        prompt = " ".join(prompt.split())
        
        num = int(pid[1:])
        is_premium = (num > 3 and num % 5 == 0)
        
        puzzles.append({
            "id": pid,
            "category": cat,
            "path": f"assets/puzzles/{cat}/{pid}.jpg",
            "title": title,
            "prompt": prompt,
            "premium": is_premium
        })

print(f"Total parsed puzzles: {len(puzzles)}")

# Group by category check
by_cat = {}
for p in puzzles:
    by_cat[p["category"]] = by_cat.get(p["category"], 0) + 1

for cat, count in by_cat.items():
    print(f"  {cat}: {count}")

assert len(puzzles) == 250, f"Expected 250 puzzles, got {len(puzzles)}"
for cat in ["animals", "nature", "flowers", "landmarks", "art"]:
    assert by_cat[cat] == 50, f"Expected 50 for {cat}, got {by_cat[cat]}"

# Save manifest
with open("assets/puzzles_manifest.json", "w", encoding="utf-8") as f:
    json.dump(puzzles, f, indent=2, ensure_ascii=False)

print("Saved assets/puzzles_manifest.json successfully!")

# Also generate tool/setup_250_puzzles.py
setup_py_content = '''# Auto-generated 250 puzzle metadata & manifest generator
import json
import os

puzzles_data = [
'''

for p in puzzles:
    # Escape quotes
    title_esc = p["title"].replace('"', '\\"')
    prompt_esc = p["prompt"].replace('"', '\\"')
    setup_py_content += f'    ("{p["category"]}", "{p["id"]}", "{title_esc}", "{prompt_esc}"),\n'

setup_py_content += ''']

manifest = []
for category, pid, title, prompt in puzzles_data:
    num = int(pid[1:])
    is_premium = (num > 3 and num % 5 == 0)

    manifest.append({
        "id": pid,
        "category": category,
        "path": f"assets/puzzles/{category}/{pid}.jpg",
        "title": title,
        "prompt": prompt,
        "premium": is_premium
    })

manifest_path = "assets/puzzles_manifest.json"
with open(manifest_path, "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2, ensure_ascii=False)

print(f"Generated {len(manifest)} puzzles manifest in {manifest_path} successfully!")
'''

with open("tool/setup_250_puzzles.py", "w", encoding="utf-8") as f:
    f.write(setup_py_content)

print("Saved tool/setup_250_puzzles.py successfully!")
