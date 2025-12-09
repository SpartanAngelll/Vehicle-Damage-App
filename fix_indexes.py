import json
import sys

# Try different encodings to read the file
encodings = ['utf-8-sig', 'utf-16', 'utf-16-le', 'utf-16-be', 'utf-8']
data = None

for encoding in encodings:
    try:
        with open('current_indexes.json', 'r', encoding=encoding) as f:
            data = json.load(f)
        print(f"Successfully read file with {encoding} encoding")
        break
    except (UnicodeDecodeError, json.JSONDecodeError) as e:
        continue

if data is None:
    print("Failed to read current_indexes.json with any encoding")
    sys.exit(1)

# Write to firestore.indexes.json with UTF-8 encoding (no BOM)
with open('firestore.indexes.json', 'w', encoding='utf-8', newline='\n') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Fixed encoding and wrote firestore.indexes.json")

