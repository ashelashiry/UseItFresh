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
    "Spring onions": "spring-onions", "Onion powder": "garlic-powder",
    "Chopped tomatoes 400g": "canned-tomatoes", "Canned tomatoes": "canned-tomatoes",
    "Tomatoes": "tomatoes", "Cherry tomatoes": "cherry-tomatoes", "Tomato paste": "tomato-paste",
    "Tomato sauce": "ketchup", "Passata": "pasta-sauce", "Pasta sauce": "pasta-sauce",
    "Spaghetti": "dry-pasta", "Dry pasta": "dry-pasta", "Penne": "dry-pasta",
    "Cooked pasta": "pasta-dish", "Pasta salad": "coleslaw",
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
    "Carrots": "carrots",
    # second wave
    "Banana bread": "raisin-toast", "Carrot cake": "cake", "Garlic bread": "frozen-garlic-bread",
    "Ricotta": "ricotta", "Cottage cheese": "cottage-cheese", "Blue cheese": "blue-cheese", "Goats cheese": "goat-cheese",
    "Salted butter": "butter", "Butter spread": "margarine", "Chocolate chips": "dark-chocolate",
    "Roasted almonds": "almonds", "Almond milk": "plant-milk", "Almond meal": "almond-meal",
    "Peanuts": "peanuts", "Peanut butter crunchy": "peanut-butter", "Satay sauce": "teriyaki",
    "Sweet chilli sauce": "sweet-chilli-sauce", "Sriracha": "hot-sauce", "BBQ sauce": "bbq-sauce",
    "Fish sauce": "worcestershire", "Oyster sauce": "oyster-sauce", "Oyster mushrooms": "oyster-mushrooms", "Oysters": "oysters",
    "Red curry paste": "curry-paste", "Chicken curry": "curry-meal", "Curry powder": "curry-powder", "Curry leaves": "curry-leaves",
    "Ground beef": "beef-mince", "Ground cinnamon": "cinnamon", "Cinnamon scrolls": "cinnamon-scrolls",
    "Instant coffee": "instant-coffee", "Instant noodles": "instant-noodles", "Coffee beans": "coffee",
    "Sesame seeds": "sesame-seeds", "Sesame oil": "sesame-oil", "Pumpkin seeds": "sunflower-seeds", "Pumpkin": "pumpkin",
    "Butternut pumpkin": "butternut", "Coriander seeds": "coriander-seeds", "Coriander": "coriander",
    "Frozen spinach": "frozen-spinach", "Frozen corn": "frozen-corn", "Frozen prawns": "frozen-prawns", "Frozen pizza": "frozen-pizza",
    "Pizza bases": "pizza-bases", "Fish fingers": "fish-fingers", "Crumbed fish": "fish-fingers", "Snapper fillets": "white-fish",
    "Canned salmon": "canned-salmon", "Tinned sardines": "sardines-tin", "Chicken nuggets": "chicken-nuggets",
    "Chicken schnitzel": "schnitzel", "Roast chicken": "roast-chicken", "Chicken wings": "chicken-wings", "Chicken drumsticks": "drumsticks",
    "Lamb shanks": "lamb-shanks", "Lamb leg": "roast-joint", "Pork belly": "pork-belly", "Pork mince": "beef-mince",
    "Salami": "salami", "Prosciutto": "prosciutto", "Hot dogs": "frankfurts", "Hot dog rolls": "bread-rolls",
    "Burger buns": "bread-rolls", "Beef burgers": "burger-patties", "Snow peas": "snow-peas", "Frozen peas": "frozen-peas",
    "Black beans": "black-beans", "Cannellini beans": "white-beans", "Kidney beans": "canned-beans", "Dried chickpeas": "dried-beans", "Chickpeas 400g": "canned-chickpeas",
    "Canned lentils": "canned-lentils", "Red lentils": "lentils", "Tinned pineapple": "canned-pineapple", "Pineapple": "pineapple",
    "Dates": "dates", "Dried apricots": "dried-apricots", "Apricots": "apricots", "Raisins": "raisins",
    "Brown rice": "brown-rice", "Fried rice": "cooked-rice", "Cooked rice": "cooked-rice", "Rice paper": "rice-paper",
    "Pad thai": "stir-fry", "Spaghetti bolognese": "pasta-dish", "Lasagne sheets": "dry-pasta", "Lasagne": "lasagne",
    "Pumpkin soup": "soup-bowl", "Tomato soup": "canned-soup", "Chicken noodle soup": "soup-bowl",
    "Sushi": "sushi", "Coleslaw": "coleslaw", "Potato salad": "coleslaw", "Coleslaw mix": "coleslaw-mix",
    "Caesar dressing": "salad-dressing", "Salad dressing": "salad-dressing", "Mixed salad": "salad-leaves",
    "Nutella": "choc-spread", "Vegemite": "yeast-spread", "Marmalade": "marmalade", "Strawberry jam": "jam",
    "Maple syrup": "maple-syrup", "Brown sugar": "brown-sugar", "Icing sugar": "icing-sugar", "Sugar": "sugar",
    "Cocoa powder": "cocoa", "Baking powder": "baking-powder", "Chilli flakes": "chilli-flakes", "Chilli": "chillies",
    "Black pepper": "black-pepper", "Salt": "salt", "Sea salt flakes": "salt", "Smoked paprika": "paprika",
    "Red wine": "red-wine", "White wine": "white-wine", "Red wine vinegar": "balsamic", "Beer": "beer", "Ginger beer": "soft-drink",
    "Lemonade": "soft-drink", "Sparkling water": "sparkling-water", "Coconut water": "coconut-water", "Apple juice": "apple-juice",
    "Orange juice": "orange-juice", "Lemon juice": "lemon-juice", "Lemons": "lemons",
    "Muesli bars": "muesli-bars", "Muesli": "granola", "Rolled oats": "oats", "Corn chips": "corn-chips", "Salt and vinegar chips": "potato-crisps",
    "Popcorn": "popcorn", "Tim Tams": "cookies", "Chocolate bar": "chocolate-bar", "Dark chocolate": "dark-chocolate",
    "Jelly beans": "lollies", "Jelly": "jelly", "Custard": "custard", "Chocolate milk": "chocolate-milk", "Strawberry yoghurt": "fruit-yogurt",
    "Condensed milk": "condensed-milk", "Baby formula": "milk-powder", "Baby food pouch": "baby-food",
    "Guacamole": "guacamole", "Tzatziki": "tzatziki", "Hummus": "hummus", "Kimchi": "kimchi",
    "Meat pie": "meat-pie", "Apple pie": "quiche", "Sausage rolls": "sausage-rolls", "Sausages": "sausages",
    "Naan": "naan", "Pita bread": "pita", "Wraps": "wraps", "Tortillas": "wraps", "Wholemeal bread": "rye-bread", "White bread": "sliced-bread",
    "Baguette": "baguette", "Crumpets": "crumpets", "English muffins": "english-muffins", "Blueberry muffins": "muffins",
    "Frozen berries": "frozen-berries", "Frozen mango": "frozen-mango", "Edamame": "edamame", "Hash browns": "hash-browns",
    "Spring rolls": "spring-rolls", "Dumplings": "dumplings", "Falafel": "falafel", "Tofu": "tofu", "Silken tofu": "tofu-puffs",
    "Mussels": "mussels", "Squid": "calamari", "Salt and pepper squid": "", "Crab": "crab", "Crab sticks": "crab-sticks",
    "Tuna steak": "tuna-steak", "Canned tuna": "canned-tuna", "Smoked salmon": "smoked-salmon",
    "Shiitake mushrooms": "shiitake", "Portobello mushrooms": "portobello", "Mushrooms": "mushrooms",
    "Bok choy": "bok-choy", "Wombok": "wombok", "Fennel": "fennel", "Parsnips": "parsnips", "Silverbeet": "silverbeet",
    "Kaffir lime leaves": "lime-leaves", "Limes": "limes", "Thai basil": "thai-basil", "Sage": "sage", "Dried oregano": "dried-herbs", "Oregano": "oregano-fresh",
    "Bay leaves": "dried-herbs", "Stock cubes": "stock-cubes", "Chicken stock": "stock", "Gravy": "gravy",
    "Vodka": "spirits", "Cola": "soft-drink", "Kombucha": "iced-tea", "Water": "sparkling-water",
    "Nori": "dried-seaweed", "Seaweed snacks": "rice-crackers", "Cheese platter": "cheese-platter",
    "Ham and cheese sandwich": "sandwich", "Ice cream": "ice-cream", "Icy poles": "ice-blocks",
    # wave 3
    "Mirin": "mirin", "Tamarind paste": "tamarind", "Palm sugar": "palm-sugar", "Pickled ginger": "pickled-ginger",
    "Galangal": "galangal", "Lotus root": "lotus-root", "Besan flour": "chickpea-flour", "Poppadoms": "poppadoms",
    "Char siu pork": "char-siu", "Bao buns": "bao-buns", "Pizza cheese": "pizza-cheese", "Cheese sticks": "cheese-sticks",
    "Chicken liver pate": "pate", "Beef jerky": "beef-jerky", "Rice pudding": "rice-pudding", "Fruit cups": "fruit-cups",
    "Coconut yoghurt": "plant-yogurt", "Starfruit": "starfruit", "Custard apple": "custard-apple",
    "Frozen chicken breast": "frozen-meat", "Frozen mince": "frozen-meat", "Chicken breast": "chicken-breast",
    "Frozen chicken nuggets": "chicken-nuggets", "Frozen pizza": "frozen-pizza", "Mozzarella": "mozzarella",
    "Roast pork": "char-siu", "Jackfruit": "jackfruit", "Fruit roll ups": "fruit-snacks",
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
