"""Build a self-contained gallery page of the food picture library (thumbnails as data URIs)."""
import base64, io, json, os, re
from PIL import Image
from library_catalogue import C

SP = os.path.dirname(os.path.abspath(__file__))
REPO = "C:/Users/ashel/AppData/Local/FlutterFlow/agent-workspaces/ff-agent-useitfresh-fridge-wise-gvpy0s"
LIB = os.path.join(REPO, "design", "library")
index = json.load(io.open(os.path.join(LIB, "index.json"), encoding="utf-8"))

# section of each entry, from the "# ---- name" comments in the catalogue
section, sections = "", {}
for line in io.open(os.path.join(SP, "library_catalogue.py"), encoding="utf-8"):
    m = re.match(r"\s*# ---- (.+)", line)
    if m:
        section = m.group(1).strip()
    m = re.match(r'\s*\("([a-z-]+)", "(fresh|pack)"', line)
    if m:
        sections[m.group(1)] = section

cards = []
for it in index["items"]:
    im = Image.open(os.path.join(LIB, it["file"])).convert("RGB")
    im.thumbnail((360, 360))
    buf = io.BytesIO()
    im.save(buf, "WEBP", quality=72)
    it = dict(it)
    it["img"] = "data:image/webp;base64," + base64.b64encode(buf.getvalue()).decode()
    it["section"] = sections.get(it["id"], "")
    cards.append(it)

data = {"processed": index["processed"], "items": cards}
tpl = io.open(os.path.join(SP, "library_gallery_template.html"), encoding="utf-8").read()
out = tpl.replace("/*DATA*/null", json.dumps(data, ensure_ascii=False)).replace("{{COUNT}}", str(len(cards)))
io.open(os.path.join(SP, "food_picture_library.html"), "w", encoding="utf-8").write(out)
print(len(cards), "cards,", round(len(out) / 1e6, 2), "MB")
