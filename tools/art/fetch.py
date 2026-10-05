import json, os, struct, subprocess, sys, urllib.parse
from concurrent.futures import ThreadPoolExecutor

BASE = "https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/"
ART = os.path.dirname(os.path.abspath(__file__))
PNG = os.path.join(ART, "png")
os.makedirs(PNG, exist_ok=True)

# (key, cldr name, [alt names])
C = {}
def add(cat, prefix, items):
    for it in items:
        if isinstance(it, tuple):
            key, name, *alts = it
        else:
            name, alts = it, []
            key = name.lower().replace("-", "_").replace(" ", "_").replace("'", "")
        C.setdefault(cat, []).append((prefix + key, name, list(alts)))

add("food", "food_", [
  "falafel", "flatbread", "bagel", "stuffed flatbread", ("shawarma_wrap", "burrito"), "sandwich", "hamburger",
  "pizza", "hot dog", "taco", "tamale", ("hummus_bowl", "bowl with spoon"), ("maqluba_pan", "shallow pan of food"),
  ("pot", "pot of food"), "curry rice", "cooked rice", "rice ball", "poultry leg", "meat on bone", "cut of meat",
  "bacon", "egg", ("fried_egg", "cooking"), "green salad", "cucumber", "tomato", "onion", "garlic", "hot pepper",
  "bell pepper", "lemon", "leafy green", "olive", "avocado", "eggplant", "carrot", "potato", "roasted sweet potato",
  "chestnut", "peanuts", "beans", ("wheat", "sheaf of rice"), ("corn", "ear of corn"), "herb", "broccoli", "mushroom",
  "ginger root", "pea pod", "bread", "croissant", ("baguette", "baguette bread"), "pretzel", "pancakes", "waffle",
  ("cheese", "cheese wedge"), "butter", ("honey", "honey pot"), ("milk", "glass of milk"), "cup with straw",
  ("juice_box", "beverage box"), ("coffee", "hot beverage"), ("tea", "teacup without handle"), "teapot", "mate",
  "tropical drink", "bubble tea", "cocktail glass", "pouring liquid", "ice", "shortcake", "birthday cake", "cupcake",
  "pie", "custard", "doughnut", "cookie", "chocolate bar", "candy", "lollipop", "ice cream", "soft ice cream",
  "shaved ice", "dango", "oden", "moon cake", "fortune cookie", "dumpling", "fried shrimp", "sushi", "bento box",
  "spaghetti", "steaming bowl", "fondue", "french fries", "popcorn", ("takeout", "takeout box"), "salt", "jar",
  "canned food", "peach", "watermelon", "grapes", "mango", "pineapple", "strawberry", "cherries", "banana",
  "coconut", "kiwi fruit", "red apple", "green apple", "pear", "tangerine", "melon", "blueberries",
  ("fork_knife_plate", "fork and knife with plate"), ("fork_knife", "fork and knife"), "spoon", "kitchen knife",
  "chopsticks", "fish cake with swirl",
])
add("animals", "ani_", [
  "chicken", "cow", ("sheep", "ewe"), "goat", "fish", "shrimp", "honeybee", "rooster", "camel", "cat", "dog",
])
add("people", "ppl_", [
  "cook", "man cook", "woman cook", "person", "man", "woman", "old man", "old woman", ("older_person", "older person"),
  "boy", "girl", "child", "baby", ("beard", "person beard"), ("woman_headscarf", "woman with headscarf"),
  ("turban", "person wearing turban"), ("man_tuxedo", "man in tuxedo"), ("tuxedo", "person in tuxedo"),
  ("man_office", "man office worker"), ("woman_office", "woman office worker"), ("office", "office worker"),
  "farmer", "man farmer", "woman farmer", "mechanic", ("police", "police officer"), ("construction", "construction worker"),
  "singer", "artist", "scientist", "teacher", "judge", "detective", "prince", "princess", "person with crown",
  ("superhero", "person superhero", "man superhero"), "woman superhero", "ninja", "technologist", "health worker", "pilot", "guard", "person tipping hand",
  ("person_raising_hand", "person raising hand"), ("bowing", "person bowing"), ("gesturing_ok", "person gesturing ok", "person gesturing OK"),
  "waving hand", "thumbs up", "thumbs down", "clapping hands", "flexed biceps", ("ok_hand", "ok hand", "OK hand"),
  "raising hands", "handshake", "folded hands", "victory hand", "writing hand",
])
add("faces", "face_", [
  "grinning face", "smiling face with heart-eyes", "star-struck", "face savoring food", "drooling face",
  "partying face", "smiling face with sunglasses", "money-mouth face", "thinking face", "neutral face",
  "angry face", ("pouting", "pouting face", "enraged face"), "hot face", "nauseated face", "loudly crying face", "sleeping face",
  "exploding head", "face blowing a kiss", "beaming face with smiling eyes", "zany face", "yawning face",
  "face with steam from nose", "pleading face", "smiling face with halo",
])
add("places", "bld_", [
  "house", "house with garden", "houses", "hut", "office building", "convenience store", "department store",
  "classical building", "mosque", "factory", "stadium", "hotel", "hospital", "bank", "school", "post office",
  "castle", "building construction", "tokyo tower", "statue of liberty", "moai", "cityscape", "cityscape at dusk",
  "sunset", "bridge at night", "night with stars", "sunrise over mountains", "sunrise", "desert", "camping",
  "beach with umbrella", "desert island", "national park", "mount fuji", "snow-capped mountain", "mountain",
  "volcano", "world map", ("globe_eu_africa", "globe showing europe-africa", "globe showing Europe-Africa"),
  ("globe_asia", "globe showing asia-australia", "globe showing Asia-Australia"),
  ("globe_americas", "globe showing americas", "globe showing Americas"), ("globe_meridians", "globe with meridians"),
  "compass", "tent", "circus tent", "carousel horse", "ferris wheel", "roller coaster", "fountain", "barber pole",
  "kaaba", "wedding", "stop sign", "construction", "rock", "wood", "potted plant", "palm tree", "deciduous tree",
  "cactus", "seedling", "four leaf clover",
])
add("vehicles", "veh_", [
  ("truck", "delivery truck"), ("lorry", "articulated lorry"), ("scooter", "motor scooter"), "bicycle", "motorcycle",
  ("car", "automobile"), "taxi", ("bus", "oncoming bus"), "bus", "minibus", "ambulance", "fire engine",
  "pickup truck", "sport utility vehicle", "tractor", "airplane", "small airplane", ("plane_departure", "airplane departure"),
  ("plane_arrival", "airplane arrival"), "ship", "motor boat", "sailboat", "ferry", "rocket", "helicopter",
  "railway car", ("train", "high-speed train"), "locomotive", "package", "shopping cart", "shopping bags",
  "fuel pump", "anchor", "satellite", "flying saucer",
])
add("ui", "ui_", [
  "coin", "money bag", "money with wings", ("dollar", "dollar banknote"), ("euro", "euro banknote"),
  ("pound", "pound banknote"), ("yen", "yen banknote"), "credit card", "heavy dollar sign", ("gem", "gem stone"),
  "crown", "trophy", "sports medal", ("medal_1st", "1st place medal"), ("medal_2nd", "2nd place medal"),
  ("medal_3rd", "3rd place medal"), "military medal", "reminder ribbon", "star", "glowing star", "shooting star",
  "sparkles", "dizzy", "fire", "high voltage", "collision", "hundred points", ("gift", "wrapped gift"), "party popper",
  "confetti ball", "balloon", "key", "old key", "locked", "unlocked", "locked with key", "shield",
  ("hourglass_done", "hourglass done"), ("hourglass", "hourglass not done"), "alarm clock", "stopwatch",
  "timer clock", "bell", "scroll", ("page", "page facing up"), "clipboard", "calendar", "spiral calendar",
  ("chart_up", "chart increasing"), ("chart_down", "chart decreasing"), "bar chart", "magic wand", "crystal ball",
  ("dice", "game die"), "slot machine", "video game", "joystick", ("target", "bullseye", "direct hit"),
  "puzzle piece", "light bulb", "gear", "hammer and wrench", "hammer", "toolbox", "test tube", "alembic", "dna",
  "books", "notebook", "bookmark", "label", "ticket", "admission tickets", "megaphone", "loudspeaker",
  "bellhop bell", "receipt", ("ballot_check", "check box with check", "ballot box with check"), "check mark button",
  "check mark", "cross mark", "warning", "no entry", "prohibited", "red heart", "sparkling heart", "crescent moon",
  ("lantern", "red paper lantern"), "candle", "sun", "sun behind cloud", "cloud", "cloud with rain", "rainbow",
  "snowflake", "umbrella with rain drops", "thermometer", "droplet", ("leaf_wind", "leaf fluttering in wind"),
  "maple leaf", "sunflower", "tulip", "hibiscus", "bouquet", ("search", "magnifying glass tilted left"),
  "round pushpin", "pushpin", "envelope", "mobile phone", "laptop", "television", "camera", "battery",
  "electric plug", "satellite antenna", "speech balloon", "thought balloon", "briefcase",
  "card index dividers", "file folder", "memo", "pencil", "chart increasing with yen", "abacus", "balance scale",
  "link", "two hearts", "musical notes", "studio microphone", "artist palette", "clapper board",
  "film projector", "newspaper", ("rolled_newspaper", "rolled-up newspaper"), "bookmark tabs", "up arrow",
  "plus", "information", "new button", "free button", "sos button", "top arrow", "repeat button",
])

def variants(name, alts):
    names = [name] + alts
    out = []
    for n in names:
        for folder in {n[0].upper() + n[1:], n}:
            base = n.lower().replace(" ", "_").replace("'", "").replace(":", "").replace(",", "").replace(".", "")
            files = [base]
            if "-" in base:
                files += [base.replace("-", "_"), base.replace("-", "")]
            for f in files:
                out.append((folder, f"{folder}/3D/{f}_3d.png"))
                out.append((folder, f"{folder}/Default/3D/{f}_3d_default.png"))
    seen, res = set(), []
    for v in out:
        if v[1] not in seen:
            seen.add(v[1]); res.append(v)
    return res

def png_info(path):
    with open(path, "rb") as fh:
        head = fh.read(33)
    if head[:8] != b"\x89PNG\r\n\x1a\n" or head[12:16] != b"IHDR":
        return None
    w, h = struct.unpack(">II", head[16:24])
    return w, h

def fetch(url, dest):
    r = subprocess.run(["curl", "-sS", "-L", "--retry", "2", "-o", dest, "-w", "%{http_code}", url],
                       capture_output=True, text=True)
    return r.stdout.strip()

def try_item(item):
    cat, key, name, alts = item
    dest = os.path.join(PNG, key + ".png")
    for folder, rel in variants(name, alts):
        url = BASE + urllib.parse.quote(rel)
        tmp = dest + ".part"
        code = fetch(url, tmp)
        if code == "200":
            info = png_info(tmp)
            if info:
                os.replace(tmp, dest)
                meta_url = BASE + urllib.parse.quote(folder) + "/metadata.json"
                glyph = ""
                try:
                    m = subprocess.run(["curl", "-sS", meta_url], capture_output=True, text=True).stdout
                    glyph = json.loads(m).get("glyph", "")
                except Exception:
                    pass
                return dict(cat=cat, key=key, emoji=glyph, name=name, folder=folder, url=url,
                            bytes=os.path.getsize(dest), width=info[0], height=info[1])
        if os.path.exists(tmp):
            os.remove(tmp)
    return dict(cat=cat, key=key, name=name, miss=True)

items, seenkeys = [], set()
for cat, lst in C.items():
    for key, name, alts in lst:
        if key in seenkeys:
            continue
        seenkeys.add(key)
        items.append((cat, key, name, alts))

with ThreadPoolExecutor(16) as ex:
    results = list(ex.map(try_item, items))

json.dump(results, open(os.path.join(ART, "results_raw.json"), "w"), ensure_ascii=False, indent=1)
ok = [r for r in results if not r.get("miss")]
miss = [r for r in results if r.get("miss")]
print("ok", len(ok), "miss", len(miss))
for r in miss:
    print("MISS", r["key"], "|", r["name"])

manifest = [dict(key=r["key"], category=r["cat"], name=r["name"], emoji=r["emoji"], folder=r["folder"], url=r["url"],
                 bytes=r["bytes"], width=r["width"], height=r["height"]) for r in ok]
json.dump(manifest, open(os.path.join(ART, "manifest.json"), "w"), ensure_ascii=False, indent=1)
code = fetch("https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/LICENSE", os.path.join(ART, "LICENSE-fluentui-emoji.txt"))
print("license", code)
