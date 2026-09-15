"""Third wave of the food picture library (15 Sep): Asian and Middle Eastern
pantry, more cheese and deli, kids' snacks, a few more fruits and frozen meat."""
from library_catalogue_more import F, P, CANS

C3 = [
    # ---- Asian and Middle Eastern pantry
    P("mirin", "a small plain unlabelled glass bottle of golden mirin rice wine with a small dish", ["mirin", "rice wine", "shaoxing", "cooking sake", "sake"], allow=["jar"]),
    P("tamarind", "a small simple bowl of dark tamarind paste beside a few tamarind pods", ["tamarind", "tamarind paste", "tamarind puree"], allow=["paste", "puree", "jar"]),
    P("palm-sugar", "a few golden discs of palm sugar and some shaved, on a board", ["palm sugar", "jaggery", "gula melaka"]),
    P("pickled-ginger", "a small simple dish of pink pickled sushi ginger with a small mound of green wasabi", ["pickled ginger", "sushi ginger", "gari", "wasabi"], allow=["pickled", "jar", "paste"]),
    F("galangal", "fresh galangal root, one piece sliced, with a stalk of lemongrass", ["galangal", "fresh turmeric", "turmeric root"]),
    F("lotus-root", "fresh lotus root, a few slices cut showing the lace pattern", ["lotus root", "lotus"]),
    F("bitter-melon", "fresh green bitter melon, one halved", ["bitter melon", "bitter gourd", "karela"]),
    F("pandan", "a bunch of fresh pandan leaves", ["pandan", "pandan leaves", "screwpine"]),
    P("chickpea-flour", "a simple bowl of pale yellow chickpea flour besan", ["chickpea flour", "besan", "besan flour", "gram flour", "rice flour", "tapioca flour"]),
    P("poppadoms", "a small stack of crisp poppadoms on a plate", ["poppadom", "pappadam", "papadum", "prawn crackers"], allow=["fried", "crisps", "chips"]),
    P("preserved-lemons", "an open plain unlabelled glass jar of preserved lemons in brine", ["preserved lemon", "preserved lemons"], allow=["jar", "pickled"]),
    P("pomegranate-molasses", "a plain unlabelled small bottle of dark pomegranate molasses with a small dish", ["pomegranate molasses", "date syrup", "grape molasses"]),
    P("chinese-sausage", "sliced dried chinese lap cheong sausages on a board", ["lap cheong", "chinese sausage", "lap chong"], allow=["dried"]),
    P("char-siu", "sliced glossy red char siu roast pork on a board", ["char siu", "bbq pork", "roast pork", "chinese roast pork", "roast duck", "peking duck"], allow=["roast", "roasted", "cooked"]),
    P("bao-buns", "soft white steamed bao buns in a bamboo steamer", ["bao", "bao buns", "steamed buns", "pork buns", "bun bao"], allow=["frozen"]),
    P("fish-balls", "a simple bowl of fish balls and fish cakes slices", ["fish ball", "fish balls", "fish tofu", "kamaboko"], allow=["frozen", "cake"]),
    P("rice-cakes-tteok", "chewy korean rice cakes tteok on a plate", ["tteok", "rice cake sticks", "korean rice cakes", "mochi"], allow=["frozen", "cake"]),
    # ---- more cheese and deli
    F("pizza-cheese", "a simple bowl of shredded mozzarella pizza cheese", ["pizza cheese", "shredded mozzarella", "grated mozzarella", "pizza blend", "mixed grated cheese"]),
    F("cheese-sticks", "a few individually wrapped cheese sticks and string cheese on a plate", ["cheese sticks", "cheese stick", "string cheese", "cheestring", "cheese snacks", "babybel"]),
    F("cheese-spread", "a small open tub of creamy cheese spread with a knife and crackers", ["cheese spread", "cheese triangles", "spreadable cheese", "laughing cow", "cream cheese spread"], allow=["spread"]),
    P("pate", "a small simple ramekin of smooth chicken liver pâté with toast", ["pate", "pâté", "paté", "liver pate", "chicken liver pate", "liverwurst", "terrine", "rillettes"]),
    P("beef-jerky", "strips of beef jerky on a board", ["jerky", "beef jerky", "biltong", "meat sticks"], allow=["dried", "smoked"]),
    # ---- kids and snacks
    P("rice-pudding", "a small simple bowl of creamy rice pudding with a sprinkle of cinnamon", ["rice pudding", "creamed rice", "sago pudding", "tapioca pudding"]),
    P("fruit-cups", "a clear plastic cup of diced peaches and pears in juice with a spoon", ["fruit cup", "fruit cups", "diced fruit", "fruit in jelly", "fruit snack cup"], allow=["juice", "jelly"]),
    P("fruit-snacks", "a few colourful fruit leather roll-ups and fruit snacks on a plate", ["fruit roll", "roll ups", "fruit leather", "fruit snacks", "fruit bars", "fruit strap", "fruit twists"]),
    F("plant-yogurt", "a simple bowl of creamy coconut yoghurt with a few coconut flakes", ["coconut yoghurt", "coconut yogurt", "oat yoghurt", "oat yogurt", "soy yoghurt", "soy yogurt", "almond yoghurt", "plant yoghurt", "dairy free yoghurt"]),
    # ---- more fruit
    F("starfruit", "fresh golden starfruit carambola, some slices showing the star shape", ["starfruit", "star fruit", "carambola"]),
    F("custard-apple", "fresh green custard apples, one halved showing creamy white flesh", ["custard apple", "cherimoya", "soursop", "sugar apple"]),
    F("feijoa", "fresh green feijoas, one halved", ["feijoa", "pineapple guava"]),
    F("jackfruit", "a piece of fresh jackfruit showing yellow pods", ["jackfruit", "durian"], **{"not": CANS}),
    F("tamarillo", "fresh red tamarillos, one halved", ["tamarillo", "tree tomato"]),
    # ---- frozen meat
    P("frozen-meat", "frosted frozen chicken breasts and a frozen steak in a plain clear freezer bag on a tray", ["chicken", "chicken breast", "beef", "steak", "mince", "lamb", "pork", "sausages", "meat", "chicken thighs", "drumsticks", "wings"], needs=["frozen"], allow=["frozen"], **{"not": ["nuggets", "schnitzel", "kiev", "pie", "pies", "meal", "pizza"]}),
]
