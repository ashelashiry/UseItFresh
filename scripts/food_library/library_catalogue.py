"""Use It Fresh food picture library: what to photograph and how the app matches it.

Each entry: (id, kind, subject, match phrases, options)
  kind   'fresh' | 'pack'  (pack = unbranded packaging, nothing fresh beside it)
  match  phrases found as whole words in a food's name (plurals added automatically)
  opts   needs: at least one of these words must be in the name
         allow: processed words this picture may show (see PROCESSED)
         not:   words that rule the picture out
"""
import json

PROCESSED = [
    "can", "canned", "tin", "tinned", "chopped", "diced", "passata", "paste", "puree",
    "sauce", "soup", "dried", "dry", "powder", "ketchup", "juice", "jar", "pickled",
    "noodles", "mayo", "mayonnaise", "pesto", "dip", "frozen", "jam", "smoked",
    "cooked", "roast", "roasted", "fried", "leftover", "leftovers", "salad", "pie",
    "cake", "curry", "stew", "bake", "baked", "milk", "oil", "flakes", "crisps", "chips",
]
CANS = ["can", "canned", "tin", "tinned"]

FRESH_STYLE = ("on a soft warm cream linen surface. Natural soft daylight from the left, gentle "
               "shadows, shallow depth of field, fresh and appetising, vivid natural colours, subtle "
               "pale sage-green background blur. No text, no logos, no hands.")
PACK_STYLE = ("on a soft warm cream linen surface. Natural soft daylight from the left, gentle "
              "shadows, shallow depth of field, appetising, natural colours, subtle pale sage-green "
              "background blur. Only this product: no fresh fruit, vegetables, herbs or other foods "
              "beside it. Any packaging is plain and unbranded with no label text, no logos, no brand. "
              "No hands.")

C = [
    # ---- fruit
    ("apples", "fresh", "crisp shiny red apples, one with a leaf on its stem", ["apple", "red apple"], {"not": ["green", "juice", "sauce", "cider"]}),
    ("green-apples", "fresh", "crisp bright green Granny Smith apples", ["green apple", "granny smith"], {}),
    ("bananas", "fresh", "a bunch of ripe yellow bananas", ["banana"], {"not": ["bread"]}),
    ("oranges", "fresh", "bright fresh oranges, one cut in half showing juicy segments", ["orange", "navel orange"], {}),
    ("lemons", "fresh", "bright yellow fresh lemons with green leaves, one cut in half", ["lemon"], {}),
    ("limes", "fresh", "fresh green limes, one cut in half showing juicy flesh", ["lime"], {}),
    ("mandarins", "fresh", "fresh mandarins with leaves, one peeled showing segments", ["mandarin", "clementine", "satsuma", "tangerine"], {}),
    ("grapefruit", "fresh", "pink grapefruit, one cut in half showing ruby flesh", ["grapefruit"], {}),
    ("strawberries", "fresh", "ripe red strawberries with green tops, a few halved", ["strawberry"], {}),
    ("blueberries", "fresh", "fresh plump blueberries in a small pile", ["blueberry"], {}),
    ("raspberries", "fresh", "fresh ripe raspberries in a small pile", ["raspberry"], {}),
    ("blackberries", "fresh", "fresh glossy blackberries in a small pile", ["blackberry"], {}),
    ("grapes", "fresh", "a bunch of fresh green grapes and a bunch of red grapes", ["grape", "green grape", "red grape"], {}),
    ("pears", "fresh", "ripe green-yellow pears", ["pear"], {}),
    ("peaches", "fresh", "ripe blushing peaches and nectarines, one halved showing the stone", ["peach", "nectarine"], {}),
    ("plums", "fresh", "ripe dark purple plums, one halved", ["plum"], {}),
    ("cherries", "fresh", "fresh glossy dark red cherries with stems", ["cherry"], {"not": ["tomato", "tomatoes"]}),
    ("mango", "fresh", "ripe mangoes, one cut hedgehog-style showing golden flesh", ["mango"], {}),
    ("pineapple", "fresh", "a whole ripe pineapple and a few golden slices", ["pineapple"], {}),
    ("watermelon", "fresh", "slices of juicy red watermelon", ["watermelon"], {}),
    ("melon", "fresh", "a rockmelon cantaloupe cut open showing orange flesh", ["melon", "rockmelon", "cantaloupe", "honeydew"], {}),
    ("kiwi", "fresh", "kiwifruit, some halved showing bright green flesh", ["kiwi", "kiwifruit"], {}),
    ("avocado", "fresh", "ripe avocados, one halved with the stone", ["avocado", "avo"], {}),
    ("pomegranate", "fresh", "a pomegranate broken open showing ruby seeds", ["pomegranate"], {}),
    ("passionfruit", "fresh", "purple passionfruit, one halved showing pulp", ["passionfruit", "passion fruit"], {}),
    # ---- vegetables
    ("red-onions", "fresh", "whole red onions with glossy pinkish-purple skins, one halved showing pink rings", ["red onion", "spanish onion", "purple onion"], {}),
    ("brown-onions", "fresh", "whole brown onions with golden papery skins, one halved", ["onion", "brown onion", "white onion", "yellow onion"], {"not": ["spring", "green", "red", "spanish", "purple", "powder", "rings"]}),
    ("spring-onions", "fresh", "a bunch of fresh spring onions (scallions)", ["spring onion", "scallion", "green onion", "shallot"], {}),
    ("garlic", "fresh", "whole garlic bulbs and a few loose cloves", ["garlic", "garlic bulb"], {"not": ["bread", "powder", "granules"]}),
    ("ginger", "fresh", "fresh ginger root, one piece sliced", ["ginger"], {"not": ["beer", "ale", "biscuit", "nut"]}),
    ("potatoes", "fresh", "fresh washed potatoes", ["potato", "baby potato", "white potato"], {"not": ["sweet", "chips", "crisps", "mashed", "wedges"]}),
    ("sweet-potatoes", "fresh", "orange sweet potatoes, one cut showing orange flesh", ["sweet potato", "kumara"], {}),
    ("carrots", "fresh", "a bunch of fresh orange carrots with green tops", ["carrot", "baby carrot"], {"not": ["cake"]}),
    ("broccoli", "fresh", "fresh green broccoli heads", ["broccoli", "broccolini"], {}),
    ("cauliflower", "fresh", "a fresh white cauliflower head with green leaves", ["cauliflower"], {}),
    ("cabbage", "fresh", "a fresh green cabbage, one halved", ["cabbage", "savoy cabbage", "green cabbage"], {"not": ["red"]}),
    ("red-cabbage", "fresh", "a fresh red cabbage cut in half showing purple layers", ["red cabbage", "purple cabbage"], {}),
    ("lettuce", "fresh", "a fresh crisp cos lettuce and an iceberg lettuce", ["lettuce", "cos", "romaine", "iceberg"], {}),
    ("salad-leaves", "fresh", "a pile of fresh mixed baby salad leaves", ["salad leaves", "mixed leaves", "salad mix", "mesclun", "baby leaves", "mixed salad"], {"allow": ["salad"]}),
    ("rocket", "fresh", "a pile of fresh peppery rocket arugula leaves", ["rocket", "arugula"], {}),
    ("spinach", "fresh", "a pile of fresh baby spinach leaves", ["spinach", "baby spinach"], {}),
    ("kale", "fresh", "a bunch of fresh curly kale", ["kale"], {"not": ["chips"]}),
    ("bok-choy", "fresh", "fresh baby bok choy, one halved", ["bok choy", "pak choi", "pak choy", "bok choi"], {}),
    ("celery", "fresh", "a bunch of fresh green celery sticks with leaves", ["celery"], {"not": ["salt", "seed"]}),
    ("cucumber", "fresh", "fresh green cucumbers, one sliced", ["cucumber", "lebanese cucumber", "continental cucumber"], {}),
    ("zucchini", "fresh", "fresh green zucchini courgettes, one sliced", ["zucchini", "courgette"], {}),
    ("eggplant", "fresh", "glossy purple eggplants aubergines, one halved", ["eggplant", "aubergine"], {}),
    ("capsicum", "fresh", "fresh red, yellow and green capsicums bell peppers", ["capsicum", "bell pepper", "red pepper", "green pepper", "yellow pepper", "pepper"], {"not": ["black", "white", "ground", "cracked", "peppercorn", "salt", "chilli", "chili"]}),
    ("chillies", "fresh", "fresh red and green chillies", ["chilli", "chili", "chile", "jalapeno", "red chilli", "green chilli"], {"not": ["powder", "flakes", "sauce", "con carne"]}),
    ("tomatoes", "fresh", "ripe red vine tomatoes, one sliced", ["tomato", "roma tomato", "vine tomato", "truss tomato"], {"not": ["cherry", "sun", "sundried"]}),
    ("cherry-tomatoes", "fresh", "fresh red cherry tomatoes on the vine", ["cherry tomato", "grape tomato", "cocktail tomato"], {}),
    ("mushrooms", "fresh", "fresh white button and brown cup mushrooms", ["mushroom", "button mushroom", "cup mushroom", "portobello", "swiss brown"], {}),
    ("corn", "fresh", "fresh corn cobs with husks pulled back", ["corn", "corn cob", "sweetcorn", "sweet corn", "corn on the cob"], {"not": ["flour", "starch", "chips", "flakes", "cornflour"]}),
    ("green-beans", "fresh", "a pile of fresh green beans", ["green bean", "string bean", "runner bean", "french bean"], {}),
    ("peas", "fresh", "fresh green pea pods, some open showing peas", ["pea", "snow pea", "sugar snap", "snap pea", "garden pea"], {"not": ["chick", "chickpea", "split"]}),
    ("asparagus", "fresh", "a bunch of fresh green asparagus spears", ["asparagus"], {}),
    ("beetroot", "fresh", "fresh beetroot with leaves, one halved showing deep magenta", ["beetroot", "beet"], {}),
    ("pumpkin", "fresh", "a wedge of fresh orange pumpkin and a small whole pumpkin", ["pumpkin", "butternut", "butternut squash", "squash"], {"not": ["seeds", "soup"]}),
    ("leeks", "fresh", "fresh leeks with white and green stems", ["leek"], {}),
    ("radishes", "fresh", "a bunch of fresh pink-red radishes with leaves", ["radish"], {}),
    ("brussels-sprouts", "fresh", "fresh green brussels sprouts, some halved", ["brussels sprout", "brussel sprout", "sprout"], {"not": ["bean", "alfalfa"]}),
    # ---- herbs
    ("basil", "fresh", "a bunch of fresh sweet basil", ["basil"], {"not": ["pesto"]}),
    ("coriander", "fresh", "a bunch of fresh coriander cilantro", ["coriander", "cilantro"], {"not": ["seed", "ground"]}),
    ("parsley", "fresh", "a bunch of fresh flat-leaf parsley", ["parsley"], {}),
    ("mint", "fresh", "a bunch of fresh mint", ["mint"], {"not": ["sauce", "chocolate", "tea"]}),
    ("rosemary", "fresh", "fresh rosemary sprigs", ["rosemary"], {}),
    ("thyme", "fresh", "fresh thyme sprigs", ["thyme"], {}),
    ("dill", "fresh", "a bunch of fresh feathery dill", ["dill"], {"not": ["pickle", "pickles"]}),
    ("chives", "fresh", "a bunch of fresh chives", ["chive"], {}),
    # ---- dairy and eggs
    ("eggs", "fresh", "fresh brown eggs in a simple bowl, one cracked showing a golden yolk", ["egg", "free range egg", "free range eggs"], {"not": ["noodle", "noodles", "easter", "chocolate", "plant"]}),
    ("milk", "fresh", "a glass bottle of fresh milk and a glass of milk", ["milk", "full cream milk", "skim milk", "whole milk", "lite milk"], {"allow": ["milk"], "not": ["coconut", "almond", "oat", "soy", "rice", "condensed", "evaporated", "powder", "chocolate", "powdered"]}),
    ("butter", "fresh", "a block of pale yellow butter on a small board, a curl sliced off", ["butter", "salted butter", "unsalted butter"], {"not": ["peanut", "almond", "nut", "cashew", "bean", "beans", "milk"]}),
    ("cheddar", "fresh", "a wedge of mature cheddar cheese with a few slices", ["cheddar", "cheese", "tasty cheese", "block cheese", "sliced cheese", "grated cheese", "shredded cheese"], {"not": ["cream", "cottage", "feta", "mozzarella", "parmesan", "brie", "camembert", "halloumi", "ricotta", "blue", "goat", "haloumi", "cake", "macaroni"]}),
    ("feta", "fresh", "a block of white feta cheese, some crumbled", ["feta"], {}),
    ("mozzarella", "fresh", "fresh white mozzarella balls, one torn open", ["mozzarella", "bocconcini", "burrata"], {}),
    ("parmesan", "fresh", "a wedge of aged parmesan cheese with a few shavings", ["parmesan", "parmigiano", "grana padano", "pecorino"], {}),
    ("brie", "fresh", "a wheel of soft brie cheese with a wedge cut out", ["brie", "camembert"], {}),
    ("halloumi", "fresh", "a block of halloumi cheese, a few slices", ["halloumi", "haloumi"], {}),
    ("cream", "fresh", "a small glass jug of fresh pouring cream", ["cream", "thickened cream", "thick cream", "pouring cream", "double cream", "heavy cream", "whipping cream"], {"not": ["cheese", "ice", "sour", "sauce", "coconut", "cracker", "biscuit"]}),
    ("sour-cream", "fresh", "a simple white bowl of thick sour cream", ["sour cream", "creme fraiche", "crème fraîche"], {}),
    ("yogurt", "fresh", "a simple white bowl of thick natural greek yoghurt", ["yogurt", "yoghurt", "greek yogurt", "greek yoghurt", "natural yoghurt"], {"not": ["frozen"]}),
    ("cream-cheese", "fresh", "a simple bowl of smooth cream cheese with a butter knife", ["cream cheese", "philadelphia", "ricotta", "cottage cheese", "mascarpone"], {}),
    # ---- meat and fish (raw)
    ("chicken-breast", "fresh", "raw skinless chicken breast fillets on a wooden board with a sprig of rosemary", ["chicken", "chicken breast", "chicken fillet", "chicken tenderloin"], {"not": ["thigh", "drumstick", "wing", "whole", "stock", "nugget", "nuggets", "schnitzel", "soup", "salt"]}),
    ("chicken-thighs", "fresh", "raw chicken thigh fillets on a wooden board", ["chicken thigh", "thigh fillet", "chicken drumstick", "drumstick", "chicken wing"], {}),
    ("whole-chicken", "fresh", "a whole raw chicken on a wooden board", ["whole chicken"], {"not": ["roast", "cooked", "bbq"]}),
    ("beef-mince", "fresh", "raw beef mince in a simple bowl", ["mince", "beef mince", "ground beef", "minced beef", "pork mince", "chicken mince", "lamb mince"], {}),
    ("steak", "fresh", "raw marbled beef steaks on a wooden board with a sprig of thyme", ["steak", "beef", "scotch fillet", "rump", "sirloin", "porterhouse", "eye fillet", "ribeye", "stir fry beef", "diced beef", "beef strips"], {"allow": ["diced"], "not": ["mince", "stock", "jerky", "corned", "sausage", "sausages"]}),
    ("lamb", "fresh", "raw lamb cutlets on a wooden board with rosemary", ["lamb", "lamb chop", "lamb cutlet", "lamb leg", "lamb shoulder"], {"not": ["mince"]}),
    ("pork", "fresh", "raw pork chops and pork loin on a wooden board", ["pork", "pork chop", "pork loin", "pork belly", "pork cutlet", "pork fillet"], {"not": ["mince", "sausage", "sausages", "bacon", "ham", "crackling"]}),
    ("sausages", "fresh", "raw pork and beef sausages on a wooden board", ["sausage", "snag", "chipolata", "bratwurst"], {"not": ["roll", "rolls"]}),
    ("bacon", "fresh", "raw rashers of bacon on a wooden board", ["bacon", "bacon rasher", "rasher", "streaky bacon", "pancetta", "prosciutto"], {"allow": ["smoked"]}),
    ("ham", "fresh", "thin slices of ham folded on a board", ["ham", "sliced ham", "shaved ham", "leg ham", "salami", "deli meat"], {"allow": ["smoked"]}),
    ("salmon", "fresh", "raw fresh salmon fillets with skin on a board with lemon slices", ["salmon", "salmon fillet", "trout", "ocean trout"], {"not": ["smoked", "canned", "tin"]}),
    ("smoked-salmon", "fresh", "folded slices of smoked salmon on a board", ["smoked salmon", "lox"], {"needs": ["smoked", "lox"]}),
    ("white-fish", "fresh", "raw white fish fillets on a board", ["fish", "white fish", "fish fillet", "barramundi", "snapper", "cod", "hake", "basa", "flathead", "whiting", "dory", "tilapia"], {"not": ["sauce", "finger", "fingers", "cake", "cakes", "tuna", "salmon", "smoked"]}),
    ("prawns", "fresh", "raw pink prawns shrimp, some peeled, on a board", ["prawn", "shrimp", "king prawn", "tiger prawn"], {}),
    ("tofu", "fresh", "a block of firm white tofu, a few cubes cut", ["tofu", "bean curd"], {}),
    # ---- bakery
    ("sourdough", "fresh", "a crusty sourdough loaf with a few slices cut", ["sourdough", "sourdough loaf", "loaf", "crusty bread", "baguette", "ciabatta"], {"not": ["tin"]}),
    ("sliced-bread", "fresh", "a soft white sandwich loaf, sliced, with a few slices fanned out", ["bread", "sliced bread", "sandwich bread", "white bread", "wholemeal bread", "multigrain bread", "toast bread", "toast"], {"not": ["crumbs", "breadcrumbs", "banana", "garlic", "roll", "rolls", "flat", "pita", "naan", "sourdough", "gluten"]}),
    ("bread-rolls", "fresh", "soft golden bread rolls", ["bread roll", "roll", "burger bun", "bun", "dinner roll", "hot dog roll"], {"not": ["spring", "sausage", "sushi", "egg", "cinnamon"]}),
    ("wraps", "pack", "a neat stack of plain soft flour tortilla wraps, unfilled and folded, nothing inside them", ["wrap", "tortilla", "flatbread", "pita", "pita bread", "naan", "mountain bread", "lavash"], {"not": ["cling", "plastic", "chips"]}),
    ("croissants", "fresh", "golden flaky croissants", ["croissant", "pastry", "danish"], {}),
    ("bagels", "fresh", "fresh plain and sesame bagels, one sliced", ["bagel"], {}),
    ("english-muffins", "fresh", "english muffins, one split and toasted", ["english muffin", "crumpet"], {}),
    # ---- pantry, dry
    ("dry-pasta", "pack", "uncooked dry penne and spaghetti pasta, some spilling from a plain glass jar. Dry uncooked pasta only, no sauce, no cooked food", ["pasta", "penne", "spaghetti", "fusilli", "macaroni", "rigatoni", "linguine", "fettuccine", "farfalle", "spirals", "lasagne sheets", "lasagna sheets", "orzo", "tagliatelle"], {"allow": ["dry", "dried"], "not": ["cooked", "fresh", "salad", "bake", "sauce"]}),
    ("rice", "pack", "uncooked white rice in a simple ceramic bowl with a wooden scoop", ["rice", "basmati", "jasmine rice", "white rice", "brown rice", "arborio", "sushi rice", "long grain"], {"allow": ["dry"], "not": ["cooked", "fried", "microwave", "cake", "cakes", "crackers", "paper", "noodles", "milk", "wine", "vinegar"]}),
    ("oats", "pack", "rolled oats in a simple bowl with a wooden spoon", ["oats", "rolled oats", "porridge oats", "quick oats", "oat", "porridge", "muesli", "granola"], {"allow": ["dry"], "not": ["milk", "bar", "bars"]}),
    ("flour", "pack", "white flour in a simple ceramic bowl with a scoop, a little dusted on the surface", ["flour", "plain flour", "self raising flour", "self-raising flour", "bread flour", "wholemeal flour", "cornflour"], {"not": ["tortilla", "tortillas", "wraps"]}),
    ("sugar", "pack", "white sugar in a simple glass jar with a spoon", ["sugar", "caster sugar", "white sugar", "brown sugar", "raw sugar", "icing sugar"], {"allow": ["jar"], "not": ["snap", "snaps", "free"]}),
    ("lentils", "pack", "dried red and green lentils in small simple bowls", ["lentil", "red lentil", "green lentil", "split pea", "split peas"], {"allow": ["dry", "dried"]}),
    ("quinoa", "pack", "uncooked quinoa grains in a simple bowl", ["quinoa"], {"allow": ["dry"]}),
    ("couscous", "pack", "uncooked couscous in a simple bowl", ["couscous", "cous cous", "bulgur", "burghul"], {"allow": ["dry"]}),
    ("noodles", "pack", "dried egg noodle nests and rice noodles, uncooked", ["noodle", "egg noodle", "rice noodle", "ramen", "udon", "soba", "vermicelli", "hokkien noodle"], {"allow": ["noodles", "dried", "dry"], "not": ["cooked", "soup", "instant cup"]}),
    ("nuts", "pack", "a simple bowl of raw almonds, cashews and walnuts", ["nuts", "almond", "cashew", "walnut", "mixed nuts", "peanut", "pistachio", "hazelnut", "pecan", "macadamia"], {"not": ["butter", "milk", "meal", "flour", "oil", "bar"]}),
    ("peanut-butter", "pack", "an open plain unlabelled glass jar of smooth peanut butter with a knife", ["peanut butter", "almond butter", "nut butter", "cashew butter"], {"allow": ["jar"]}),
    ("honey", "pack", "a plain unlabelled glass jar of golden honey with a wooden dipper", ["honey", "maple syrup", "golden syrup"], {"allow": ["jar"], "not": ["soy", "mustard", "chicken"]}),
    ("olive-oil", "pack", "a plain unlabelled glass bottle of golden-green olive oil with a small dish of oil", ["olive oil", "extra virgin olive oil", "oil", "vegetable oil", "canola oil", "sunflower oil", "cooking oil"], {"allow": ["oil"], "not": ["spray", "fish", "tuna", "coconut", "sesame"]}),
    ("breakfast-cereal", "pack", "a simple bowl of cornflakes breakfast cereal", ["cereal", "cornflakes", "corn flakes", "weet-bix", "weetbix", "bran flakes", "rice bubbles"], {"allow": ["flakes"]}),
    ("crackers", "pack", "a small stack of plain water crackers and rice crackers on a board", ["cracker", "rice cracker", "water cracker", "crispbread", "rice cake"], {"allow": ["cake"]}),
    ("coffee", "pack", "roasted coffee beans and a small bowl of ground coffee", ["coffee", "coffee beans", "ground coffee", "instant coffee"], {"allow": ["roasted"], "not": ["pod", "pods", "capsule", "capsules"]}),
    ("tea", "pack", "loose black tea leaves and plain tea bags in a small bowl", ["tea", "tea bags", "black tea", "green tea", "herbal tea"], {"not": ["towel", "iced"]}),
    ("dark-chocolate", "pack", "pieces of a broken dark chocolate bar, unwrapped", ["chocolate", "dark chocolate", "milk chocolate", "cooking chocolate", "choc chips", "chocolate chips"], {"allow": ["milk"], "not": ["milk drink", "cake", "biscuit", "ice", "spread"]}),
    # ---- cans
    ("canned-tomatoes", "pack", "an opened plain unbranded metal tin of chopped tomatoes in rich red juice, with a spoon beside it, no fresh tomatoes", ["tomato", "chopped tomato", "diced tomato", "crushed tomato", "whole peeled tomato"], {"needs": CANS + ["chopped", "diced", "crushed"], "allow": CANS + ["chopped", "diced"]}),
    ("canned-tuna", "pack", "an opened plain unbranded metal tin of tuna chunks, a fork beside it", ["tuna", "tuna chunks", "tuna in oil", "tuna in springwater", "canned salmon", "sardines"], {"allow": CANS + ["oil"], "not": ["steak", "fresh", "sashimi"]}),
    ("canned-chickpeas", "pack", "an opened plain unbranded metal tin of chickpeas with a spoon", ["chickpea", "chick pea", "garbanzo"], {"allow": CANS + ["dried", "dry"]}),
    ("canned-beans", "pack", "an opened plain unbranded metal tin of red kidney beans with a spoon", ["kidney bean", "red kidney bean", "black bean", "cannellini bean", "butter bean", "four bean mix", "mixed beans", "bean"], {"allow": CANS + ["dried", "dry"], "not": ["green", "string", "french", "runner", "baked", "coffee", "jelly", "sprout", "sprouts", "broad", "edamame"]}),
    ("baked-beans", "pack", "an opened plain unbranded metal tin of baked beans in tomato sauce", ["baked bean", "baked beans"], {"allow": CANS + ["baked", "sauce"]}),
    ("coconut-milk", "pack", "an opened plain unbranded metal tin of creamy coconut milk, a small bowl of it beside", ["coconut milk", "coconut cream"], {"allow": CANS + ["milk"]}),
    ("canned-corn", "pack", "an opened plain unbranded metal tin of golden sweetcorn kernels with a spoon", ["corn", "corn kernels", "sweetcorn", "sweet corn", "creamed corn"], {"needs": CANS + ["kernels", "creamed"], "allow": CANS}),
    ("canned-soup", "pack", "a simple bowl of smooth tomato soup next to an opened plain unbranded metal tin", ["soup", "tomato soup", "pumpkin soup", "chicken soup", "vegetable soup"], {"allow": CANS + ["soup"]}),
    ("canned-fruit", "pack", "an opened plain unbranded metal tin of peach slices in light syrup", ["peach", "pear", "pineapple", "fruit salad", "apricot", "fruit"], {"needs": CANS, "allow": CANS}),
    # ---- jars, bottles, sauces
    ("pasta-sauce", "pack", "an open plain unlabelled glass jar of rich red tomato pasta sauce with a spoon", ["pasta sauce", "passata", "tomato passata", "marinara", "bolognese sauce", "napoletana", "tomato pasta sauce", "arrabbiata"], {"allow": ["sauce", "passata", "jar"]}),
    ("tomato-paste", "pack", "a small simple bowl of thick red tomato paste with a spoon", ["tomato paste", "tomato puree", "concentrated tomato"], {"allow": ["paste", "puree", "can", "tin", "jar"]}),
    ("pesto", "pack", "an open plain unlabelled glass jar of green basil pesto with a spoon", ["pesto", "basil pesto"], {"allow": ["pesto", "jar"]}),
    ("mayonnaise", "pack", "a simple small bowl of creamy mayonnaise with a spoon", ["mayonnaise", "mayo", "aioli", "whole egg mayonnaise"], {"allow": ["mayo", "mayonnaise", "jar"]}),
    ("ketchup", "pack", "a simple small bowl of tomato ketchup with a plain unlabelled glass bottle", ["ketchup", "tomato sauce", "tomato ketchup", "bbq sauce", "barbecue sauce"], {"allow": ["ketchup", "sauce"]}),
    ("mustard", "pack", "a small open plain unlabelled jar of dijon and wholegrain mustard with a spoon", ["mustard", "dijon", "wholegrain mustard", "hot english mustard"], {"allow": ["jar"]}),
    ("soy-sauce", "pack", "a small simple dish of dark soy sauce with a plain unlabelled glass bottle", ["soy sauce", "soya sauce", "tamari", "fish sauce", "oyster sauce", "worcestershire"], {"allow": ["sauce"]}),
    ("jam", "pack", "an open plain unlabelled glass jar of strawberry jam with a spoon", ["jam", "strawberry jam", "raspberry jam", "apricot jam", "marmalade", "jelly", "conserve"], {"allow": ["jam", "jar"]}),
    ("olives", "pack", "a simple small bowl of green and black olives", ["olive", "kalamata", "green olive", "black olive"], {"allow": ["jar", "pickled", "can", "tin"], "not": ["oil"]}),
    ("pickles", "pack", "an open plain unlabelled glass jar of pickled gherkins, a few on a plate", ["pickle", "gherkin", "dill pickle", "cornichon", "pickled onion", "sauerkraut", "kimchi"], {"allow": ["pickled", "jar"]}),
    ("hummus", "pack", "a simple bowl of smooth hummus with a swirl of olive oil", ["hummus", "houmous", "tzatziki", "baba ganoush", "dip"], {"allow": ["dip"]}),
    ("salsa", "pack", "a simple small bowl of chunky tomato salsa", ["salsa", "tomato salsa"], {"allow": ["jar", "dip", "sauce"]}),
    ("stock", "pack", "a plain unlabelled carton of stock next to a small bowl of clear golden broth", ["stock", "chicken stock", "beef stock", "vegetable stock", "broth", "bone broth"], {"allow": ["powder", "cube"], "not": ["pot"]}),
    ("vinegar", "pack", "a plain unlabelled glass bottle of vinegar with a small dish of balsamic", ["vinegar", "balsamic", "apple cider vinegar", "white vinegar", "red wine vinegar"], {}),
    # ---- frozen
    ("frozen-peas", "pack", "frozen green peas with a light frost in a simple bowl", ["pea", "garden pea", "baby pea"], {"needs": ["frozen"], "allow": ["frozen"]}),
    ("frozen-berries", "pack", "frozen mixed berries with a light frost in a simple bowl", ["berry", "mixed berry", "blueberry", "raspberry", "strawberry", "mango"], {"needs": ["frozen"], "allow": ["frozen"]}),
    ("frozen-vegetables", "pack", "frozen mixed vegetables (peas, corn, carrot, beans) with a light frost in a simple bowl", ["vegetable", "veg", "mixed vegetable", "mixed veg", "stir fry vegetable", "broccoli", "spinach", "corn", "beans", "vegies", "veggies"], {"needs": ["frozen"], "allow": ["frozen"]}),
    ("frozen-chips", "pack", "frozen potato chips fries with a light frost on a simple tray", ["chips", "fries", "potato chips", "wedges", "hash brown", "potato gems"], {"needs": ["frozen", "oven", "fries", "wedges", "hash", "gems"], "allow": ["frozen", "chips"]}),
    ("ice-cream", "pack", "scoops of vanilla ice cream in a simple bowl", ["ice cream", "gelato", "sorbet", "frozen yogurt", "frozen yoghurt"], {"allow": ["frozen"]}),
    ("frozen-meals", "pack", "a frosted plain unbranded frozen food container with a clear lid", ["frozen meal", "ready meal", "frozen dinner", "frozen pizza", "pizza"], {"allow": ["frozen"]}),
    # ---- drinks and other fridge food
    ("orange-juice", "pack", "a glass bottle of fresh orange juice and a full glass", ["orange juice", "juice", "apple juice", "oj"], {"allow": ["juice"]}),
    ("plant-milk", "pack", "a plain unlabelled carton of oat milk and a glass of it", ["oat milk", "almond milk", "soy milk", "soya milk", "rice milk", "plant milk", "coconut drink"], {"allow": ["milk"]}),
    ("sparkling-water", "pack", "a plain unlabelled glass bottle of sparkling water and a glass with lemon-free bubbles", ["sparkling water", "mineral water", "soda water", "water"], {"not": ["melon", "chestnut", "cress", "crackers", "coconut"]}),
    ("dumplings", "pack", "a few uncooked dumplings gyoza on a simple plate", ["dumpling", "gyoza", "wonton", "dim sum", "potsticker"], {"allow": ["frozen"]}),
    ("pastry-sheets", "pack", "folded sheets of raw puff pastry dusted with flour", ["puff pastry", "pastry sheet", "shortcrust pastry", "filo", "filo pastry", "phyllo"], {"allow": ["frozen"]}),
    ("spices", "pack", "small simple bowls of ground paprika, turmeric, cumin and black pepper", ["spice", "paprika", "turmeric", "cumin", "cinnamon", "curry powder", "chilli powder", "garlic powder", "onion powder", "black pepper", "mixed herbs", "oregano", "dried herbs", "ground pepper", "peppercorn", "salt"], {"allow": ["powder", "dried", "ground"]}),
    ("biscuits", "pack", "a small stack of plain golden biscuits cookies on a simple plate", ["biscuit", "cookie", "shortbread", "digestive"], {}),
    ("potato-crisps", "pack", "a simple bowl of golden potato crisps", ["crisps", "potato crisps", "chips", "corn chips", "tortilla chips"], {"needs": ["crisps", "corn", "tortilla", "salt", "vinegar"], "allow": ["crisps", "chips"]}),
    ("sundried-tomatoes", "pack", "a small simple bowl of sun-dried tomatoes in oil", ["sun dried tomato", "sundried tomato", "semi dried tomato"], {"allow": ["dried", "jar", "oil"]}),
    ("leftovers", "pack", "a clear glass meal-prep container with a home-cooked meal of rice, vegetables and chicken, lid beside it", ["leftover", "leftovers", "meal prep", "cooked meal", "home cooked"], {"allow": ["leftover", "leftovers", "cooked", "curry", "stew", "roast", "roasted", "fried", "pie", "soup", "bake", "baked", "salad", "sauce"]}),
]

TRIAL = {  # already generated on 15 Sep (4-photo trial)
    "red-onions": "abeaefb9-1d1b-440c-b631-b8014c488e37",
    "lemons": "71620e8a-a5eb-48d3-9bb7-f1e6cce4da0a",
    "canned-tomatoes": "eed166a2-b38a-4f39-99a5-4eff89c6e852",
    "dry-pasta": "29162599-5a55-43a1-b1a0-1aa13a30e40b",
}


def plurals(p):
    words = p.split(" ")
    last = words[-1]
    out = {p}
    if last.endswith("y") and last[-2:-1] not in "aeiou":
        out.add(" ".join(words[:-1] + [last[:-1] + "ies"]))
    elif last.endswith(("o", "ch", "sh", "s", "x")):
        out.add(" ".join(words[:-1] + [last + "es"]))
        if last.endswith("o"):
            out.add(" ".join(words[:-1] + [last + "s"]))
    elif not last.endswith("s"):
        out.add(" ".join(words[:-1] + [last + "s"]))
    return sorted(out)


def prompt(kind, subject):
    return f"Food photography: {subject}, {FRESH_STYLE if kind == 'fresh' else PACK_STYLE}"


def norm(p):
    import re
    return re.sub(r"[^a-z]+", " ", p.lower()).strip()


def index_json(files):
    items = []
    for id_, kind, subject, match, opts in C:
        if id_ not in files:
            continue
        m = sorted({x for p in match for x in plurals(norm(p))})
        item = {"id": id_, "kind": kind, "file": files[id_], "match": m}
        for k in ("needs", "allow", "not"):
            if opts.get(k):
                item[k] = sorted({norm(w) for w in opts[k]})
        items.append(item)
    return {
        "version": 1,
        "about": "Use It Fresh food pictures: illustrative photos generated for the app (15 Sep 2026). "
                 "A food shows a picture when a match phrase is in its name, every processed word in "
                 "its name is allowed, any needs word is present and no not word is.",
        "base": "https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@main/design/library/",
        "processed": sorted(set(PROCESSED)),
        "items": items,
    }


if __name__ == "__main__":
    ids = [c[0] for c in C]
    assert len(ids) == len(set(ids)), [i for i in ids if ids.count(i) > 1]
    todo = [c for c in C if c[0] not in TRIAL]
    print(len(C), "entries;", len(todo), "to generate")
    json.dump([{"id": c[0], "prompt": prompt(c[1], c[2])} for c in todo],
              open("library_prompts.json", "w"), indent=1)
