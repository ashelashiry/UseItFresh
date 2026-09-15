"""Download generated photos, save 800px webp files and index.json into design/library."""
import io, json, os, re, sys, urllib.request
from PIL import Image
from library_catalogue import C, TRIAL, index_json

SP = os.path.dirname(os.path.abspath(__file__))
REPO = "C:/Users/ashel/AppData/Local/FlutterFlow/agent-workspaces/ff-agent-useitfresh-fridge-wise-gvpy0s"
OUT = os.path.join(REPO, "design", "library")
RAW = os.path.join(SP, "lib_raw")
PFX = "https://d8j0ntlcm91z4.cloudfront.net/user_3HYvaIoVSDigfsCRXVwbeVBNvbX/hf_"
os.makedirs(OUT, exist_ok=True)
prompts = json.load(open(os.path.join(SP, "library_prompts.json")))

urls = {}
for line in open(os.path.join(SP, "lib_urls.txt")):
    i, u = line.split()
    urls[prompts[int(i)]["id"]] = u
for line in open(os.path.join(SP, "lib_done.txt")):
    parts = line.split()
    if len(parts) != 3:
        continue
    i, ts, job = parts
    stamp = ts if "_" in ts else "20260915_" + ts
    urls[prompts[int(i)]["id"]] = f"{PFX}{stamp}_{job}.png"

files = {}
for id_, kind, *_ in C:
    png = os.path.join(RAW, id_ + ".png")
    if not os.path.exists(png) and id_ in urls:
        urllib.request.urlretrieve(urls[id_], png)
    if not os.path.exists(png):
        continue
    webp = os.path.join(OUT, id_ + ".webp")
    if not os.path.exists(webp):
        im = Image.open(png).convert("RGB")
        im.thumbnail((800, 800), Image.LANCZOS)
        im.save(webp, "WEBP", quality=80, method=6)
    files[id_] = id_ + ".webp"

missing = [c[0] for c in C if c[0] not in files]
json.dump(index_json(files), io.open(os.path.join(OUT, "index.json"), "w", encoding="utf-8", newline="\n"),
          indent=1, ensure_ascii=False)
size = sum(os.path.getsize(os.path.join(OUT, f)) for f in files.values())
print(len(files), "photos,", round(size / 1e6, 1), "MB; missing:", missing)
