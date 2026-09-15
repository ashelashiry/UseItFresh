"""Python copy of the app's _uLibrary matcher, run over realistic food names."""
import re, sys
from library_catalogue import C, index_json

lib = index_json({c[0]: c[0] + ".webp" for c in C})


def match(name, fresh_only=False):
    n = " " + re.sub(r"[^a-z]+", " ", name.lower()).strip() + " "
    has = lambda w: (" " + w + " ") in n
    processed = [w for w in lib["processed"] if has(w)]
    best, score = "", -1
    for it in lib["items"]:
        if fresh_only and it["kind"] != "fresh":
            continue
        needs, allow = it.get("needs", []), it.get("allow", [])
        if any(has(w) for w in it.get("not", [])):
            continue
        if needs and not any(has(w) for w in needs):
            continue
        if any(w not in needs and w not in allow for w in processed):
            continue
        for m in it["match"]:
            if has(m):
                s = len(m) + (100 if needs else 0)
                if s > score:
                    score, best = s, it["id"]
    return best


CASES = {
    "Red onions": "red-onions", "Brown onion": "brown-onions", "Onions": "brown-onions",
    "Spring onions": "spring-onions", "Onion powder": "spices",
    "Chopped tomatoes 400g": "canned-tomatoes", "Canned tomatoes": "canned-tomatoes",
    "Tomatoes": "tomatoes", "Cherry tomatoes": "cherry-tomatoes", "Tomato paste": "tomato-paste",
    "Tomato sauce": "ketchup", "Passata": "pasta-sauce", "Pasta sauce": "pasta-sauce",
    "Spaghetti": "dry-pasta", "Dry pasta": "dry-pasta", "Penne": "dry-pasta",
    "Cooked pasta": "", "Pasta salad": "",
    "Milk": "milk", "Full cream milk 2L": "milk", "Oat milk": "plant-milk", "Coconut milk": "coconut-milk",
    "Butter": "butter", "Peanut butter": "peanut-butter",
    "Cream": "cream", "Cream cheese": "cream-cheese", "Sour cream": "sour-cream", "Ice cream": "ice-cream",
    "Frozen peas": "frozen-peas", "Peas": "peas", "Frozen mixed vegetables": "frozen-vegetables",
    "Frozen berries": "frozen-berries", "Blueberries": "blueberries",
    "Tuna in springwater": "canned-tuna", "Chickpeas": "canned-chickpeas", "Kidney beans": "canned-beans",
    "Green beans": "green-beans", "Baked beans": "baked-beans",
    "Chicken breast": "chicken-breast", "Chicken thighs": "chicken-thighs", "Chicken stock": "stock",
    "Beef mince": "beef-mince", "Smoked salmon": "smoked-salmon", "Salmon fillets": "salmon",
    "Eggs": "eggs", "Free range eggs 12 pack": "eggs", "Egg noodles": "noodles",
    "Sweet potato": "sweet-potatoes", "Potatoes": "potatoes", "Frozen chips": "frozen-chips",
    "Apple juice": "orange-juice", "Apples": "apples", "Green apples": "green-apples",
    "Cheddar cheese": "cheddar", "Tasty cheese grated": "cheddar", "Feta": "feta",
    "Greek yoghurt": "yogurt", "Frozen yoghurt": "ice-cream",
    "Sourdough": "sourdough", "Bread": "sliced-bread", "Garlic bread": "",
    "Olive oil": "olive-oil", "Black pepper": "spices", "Red capsicum": "capsicum",
    "Leftover curry": "leftovers", "Sweetcorn can": "canned-corn", "Corn": "corn",
    "Rice": "rice", "Fried rice": "", "Honey": "honey", "Soy sauce": "soy-sauce",
    "Lettuce": "lettuce", "Mixed salad leaves": "salad-leaves", "Baby spinach": "spinach",
    "Basil pesto": "pesto", "Basil": "basil", "Avocado": "avocado", "Bananas": "bananas",
    "Banana bread": "", "Carrots": "carrots", "Carrot cake": "",
}
bad = 0
for name, want in CASES.items():
    got = match(name)
    if got != want:
        bad += 1
        print(f"MISMATCH {name!r}: got {got!r}, want {want!r}")
print("meal cue for 'pasta':", repr(match("pasta", True)), "| 'onion':", repr(match("onion", True)))
print(len(CASES) - bad, "of", len(CASES), "ok")
sys.exit(1 if bad else 0)
