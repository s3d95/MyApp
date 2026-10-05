#!/usr/bin/env python3
"""Validates content/cities.json and content/story.json against SCHEMA.md (sections 0, 2, 18),
GDD rules (caps, licences, upgrade ladder, goal template) and tools/art_keys.txt.

Usage: python3 check_cities.py [content_dir]
Exit code 0 = no errors (warnings allowed).
"""
import json, math, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
CONTENT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(HERE), "content")
ART_FILE = "/home/user/MyApp/tools/art_keys.txt"

errors, warnings = [], []
def err(where, msg): errors.append(f"ERROR {where}: {msg}")
def warn(where, msg): warnings.append(f"WARN  {where}: {msg}")

ART = set(open(ART_FILE, encoding="utf-8").read().split())

# ---------------------------------------------------------------- enums (SCHEMA 0.2, 0.7, 0.8, 18)
REGION = {"palestine", "arab", "world"}
CUISINE = {"palestinian", "levantine", "egyptian", "gulf", "iraqi", "maghrebi", "turkish", "world"}  # "any" = exclusive chefs only
CATEGORY = {"fried", "grill", "bakery", "sweets", "drinks", "dishes", "seafood", "street"}
WEATHER_TAG = {"none", "hot", "cold"}
SILHOUETTE = {"oldCity", "hills", "coast", "towers", "desert", "minarets", "bridge", "mountains"}
CHEST = {"wood", "silver", "gold"}
RARITY = {"common", "rare", "epic", "legendary"}
REWARD_TYPES = {"gold", "zaatar", "xp", "rep", "seasonPoints", "tickets", "freezes", "timeWarpMin", "incomeMin",
                "chest", "chefCards", "heritageItem", "heritageCase", "eventTokens", "cosmetic", "storyScene"}
TWIST_METRICS = {"busesWelcomed": "busWaves", "ovenPerfects": "ovenTiming", "chainUnits": "productionChain",
                 "shipmentsDelivered": "portShipments", "deliveriesDone": "deliveryRuns",
                 "weatherEarnedBase": "weatherSwing", "nightEarnedBase": "nightMarket", "vipServed": "vipLounge"}
GOAL_PARAMS = {  # type: (required, optional, default scope)
    "unlockStation": ({"stationId"}, set(), "city"),
    "stationLevel": ({"stationId", "level"}, set(), "city"),
    "allStationsLevel": ({"level"}, set(), "city"),
    "hireManager": ({"stationId"}, set(), "city"),
    "managersCount": ({"count"}, set(), "city"),
    "earnCash": ({"amountBase"}, set(), "city"),
    "incomeRate": ({"amountBase"}, set(), "city"),
    "buyUpgrades": ({"count"}, set(), "city"),
    "customersServed": ({"count"}, set(), "city"),
    "tapCook": ({"count"}, set(), "city"),
    "specialCustomers": ({"count"}, set(), "city"),
    "choiceEvents": ({"count"}, set(), "slot"),
    "rushRounds": ({"count"}, {"minScore"}, "slot"),
    "collectVault": ({"count"}, set(), "slot"),
    "startResearch": ({"count"}, set(), "slot"),
    "researchLevels": ({"count"}, set(), "slot"),
    "sendSupplyRun": ({"count"}, set(), "slot"),
    "supplyReturns": ({"count"}, set(), "slot"),
    "equipChefs": ({"count"}, set(), "city"),
    "chefTagMatch": ({"count"}, set(), "city"),
    "dailyOrders": ({"count"}, set(), "slot"),
    "contractGoals": ({"count"}, set(), "slot"),
    "eventMilestones": ({"count"}, set(), "slot"),
    "heritageItems": ({"count"}, set(), "slot"),
    "branchCollect": ({"count"}, set(), "slot"),
    "leagueRep": ({"amount"}, set(), "slot"),
    "twistMetric": ({"metric", "amount"}, set(), "city"),
}
# empire level at which the system behind a goal type unlocks (GDD 4.4)
GOAL_UNLOCK = {"hireManager": 2, "managersCount": 2, "specialCustomers": 3, "buyUpgrades": 3, "equipChefs": 4,
               "chefTagMatch": 4, "collectVault": 5, "startResearch": 7, "researchLevels": 7, "sendSupplyRun": 8,
               "supplyReturns": 8, "heritageItems": 8, "dailyOrders": 9, "choiceEvents": 10, "rushRounds": 11,
               "leagueRep": 12, "contractGoals": 14, "eventMilestones": 15}
# expected empire level at city start (casual bot, GDD 3.1 start days mapped through GDD 4.2)
EXP_LEVEL = {1: 1, 2: 7, 3: 9, 4: 10, 5: 13, 6: 16, 7: 18, 8: 21, 9: 24, 10: 26, 11: 28, 12: 31, 13: 33, 14: 35,
             15: 37, 16: 39, 17: 41, 18: 43, 19: 45, 20: 47, 21: 49, 22: 51, 23: 53, 24: 54, 25: 56}
# GDD 3.1 table
GDD = {1: (6, 10.5, 1), 2: (6, 11.3, 1), 3: (7, 12.2, 1), 4: (7, 13.0, 1), 5: (7, 13.7, 1), 6: (7, 14.1, 1.1),
       7: (7, 14.5, 1.4), 8: (7, 14.8, 1.7), 9: (8, 15.1, 2.2), 10: (8, 15.25, 2.8), 11: (8, 15.4, 3.5),
       12: (8, 15.6, 4.4), 13: (8, 15.7, 5.8), 14: (8, 15.8, 7.2), 15: (8, 15.9, 9), 16: (8, 16.0, 11),
       17: (8, 16.25, 14), 18: (8, 16.35, 18), 19: (8, 16.4, 23), 20: (8, 16.5, 29), 21: (8, 16.55, 37),
       22: (8, 16.6, 47), 23: (8, 16.65, 60), 24: (8, 16.7, 79)}
TWIST_PARAMS = {  # type: (required, optional)
    "productionChain": ({"inputStation", "outputStation"}, {"ratio", "outputMult", "stockCapMin"}),
    "ovenTiming": ({"station"}, {"windowSec", "perfectMult", "minCycleSec"}),
    "busWaves": (set(), {"intervalMin", "windowSec", "waveMult", "waveSec", "stations"}),
    "nightMarket": ({"stations"}, {"startHour", "endHour", "nightMult"}),
    "portShipments": ({"station"}, {"intervalHours", "dockHours", "targetMin", "rewardMin", "offlineRewardFrac"}),
    "deliveryRuns": (set(), {"intervalMin", "tripMin", "rewardMin", "scooters", "queueMax", "extraScooterCostsBase",
                             "dispatcherCostBase", "offlineRewardFrac", "rainMult"}),
    "weatherSwing": (set(), {"hotProb", "coldProb", "rainProb", "hotDayStations", "coldDayStations", "rainDayStations", "mult"}),
    "vipLounge": ({"loungeStation"}, {"specialIntervalMult", "vipShare", "vipTierWeights", "vipTipMin", "levelPerTier"}),
}
STATION_KEYS_IN = {"inputStation", "outputStation", "station", "loungeStation"}
STATION_LISTS_IN = {"stations", "hotDayStations", "coldDayStations", "rainDayStations"}

CITY_FIELDS_R = {"id", "index", "name", "region", "currency", "landmarkArt", "palette", "levelCap", "licenceHours",
                 "finalGoalBase", "priceScale", "stations", "upgrades", "goals", "rival", "chapterId", "rushIngredients"}
CITY_FIELDS_O = {"decorArts", "silhouette", "starsToGraduate", "twists", "customerArts"}
STATION_R = {"id", "key", "name", "art", "tier", "cuisine", "category"}
STATION_O = {"weather", "managerName", "managerArt"}
SCENE_TRIGGERS = {"arrival", "rival", "midpoint", "finale", "festival", "memory", "manual"}
FESTIVALS = {"ramadan", "eidFitr", "eidAdha", "oliveHarvest", "summer", "backToSchool", "bethlehemChristmas", "mothersDay"}
MEMORY_LEVELS = [82, 83, 84, 85, 86, 87, 88, 89, 91, 92, 93, 94, 95, 96, 97, 98, 99]
PLACEHOLDERS = {"n", "station", "amount"}

HEX = re.compile(r"^#[0-9A-Fa-f]{6}$")
LATIN = re.compile(r"[A-Za-z]")
EMOJI = re.compile("[\U0001F000-\U0001FAFF☀-➿️]")
ID_RE = re.compile(r"^[a-z][A-Za-z0-9]*$")

# known chef ids (prefer the teammate file)
CHEF_IDS = None
cp = os.path.join(CONTENT, "chefs.json")
if os.path.exists(cp):
    try:
        CHEF_IDS = {c["id"] for c in json.load(open(cp, encoding="utf-8"))["chefs"]}
    except Exception as e:  # noqa
        warn("chefs.json", f"could not read chef ids: {e}")

def is_num(x): return isinstance(x, (int, float)) and not isinstance(x, bool)
def is_int(x): return isinstance(x, int) and not isinstance(x, bool)

def check_text(where, s, max_words=None, allow_ph=PLACEHOLDERS):
    if not isinstance(s, str) or not s.strip():
        err(where, "empty text"); return
    if EMOJI.search(s): err(where, f"emoji character in text: {s}")
    if LATIN.search(re.sub(r"\{\w+\}", "", s)): err(where, f"Latin letters in player-facing text: {s}")
    for ph in re.findall(r"\{(\w+)\}", s):
        if ph not in allow_ph: err(where, f"unknown placeholder {{{ph}}}")
    if max_words is not None:
        words = [w for w in s.split() if re.search(r"[\w؀-ۿ0-9]", w)]
        if len(words) > max_words: err(where, f"{len(words)} words > {max_words}: {s}")

def check_gtext(where, v, max_words=None, allow_ph=PLACEHOLDERS):
    if isinstance(v, str):
        check_text(where, v, max_words, allow_ph)
    elif isinstance(v, dict):
        if set(v.keys()) != {"m", "f"}: err(where, f"GText object must have exactly m,f: {list(v)}")
        for k in ("m", "f"):
            check_text(f"{where}.{k}", v.get(k), max_words, allow_ph)
        if v.get("m") == v.get("f"): warn(where, "m == f; use a plain string")
    else:
        err(where, f"GText must be string or {{m,f}}, got {type(v).__name__}")

def check_art(where, k, prefixes=None):
    if not isinstance(k, str) or k not in ART:
        err(where, f"art key not in art_keys.txt: {k!r}")
    elif prefixes and not k.startswith(prefixes):
        err(where, f"art key {k} should start with {prefixes}")

def check_reward(where, r):
    if not isinstance(r, dict): err(where, "reward must be an object"); return
    allowed = {"type", "amount", "id", "rarity"}
    for k in r:
        if k not in allowed: err(where, f"unknown reward field {k}")
    t = r.get("type")
    if t not in REWARD_TYPES: err(where, f"unknown reward type {t}"); return
    if not is_num(r.get("amount")) or r["amount"] <= 0: err(where, "reward amount must be > 0")
    if t == "chest" and r.get("id") not in CHEST: err(where, f"chest id must be one of {CHEST}")
    if t == "chefCards":
        if "id" in r:
            if CHEF_IDS is not None and r["id"] not in CHEF_IDS | {"seasonChef", "themeChef"}:
                err(where, f"unknown chef id {r['id']}")
        elif r.get("rarity") not in RARITY:
            err(where, "chefCards needs id or rarity")
    if "rarity" in r and r["rarity"] not in RARITY: err(where, f"bad rarity {r['rarity']}")

def ordered_first_key(path, obj):
    if not isinstance(obj, dict) or next(iter(obj), None) != "version" or not is_int(obj.get("version")):
        err(path, "first field must be \"version\": Int")

# ---------------------------------------------------------------- load
def load(name):
    p = os.path.join(CONTENT, name)
    try:
        with open(p, encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        err(name, f"cannot load: {e}"); return None

cities_doc = load("cities.json")
story_doc = load("story.json")

# ---------------------------------------------------------------- generic art-key scan (catches keys anywhere)
for name in ("cities.json", "story.json"):
    p = os.path.join(CONTENT, name)
    if os.path.exists(p):
        txt = open(p, encoding="utf-8").read()
        for m in re.finditer(r'"((?:food|ppl|face|bld|veh|ui|ani)_[a-z0-9_]+)"', txt):
            if m.group(1) not in ART:
                err(name, f"line {txt[:m.start()].count(chr(10)) + 1}: unknown art key {m.group(1)}")

# ---------------------------------------------------------------- cities
all_station_ids = set()
city_goal_ids = {}
city_by_id = {}
chapter_refs = {}
summary = []
if cities_doc:
    ordered_first_key("cities.json", cities_doc)
    if set(cities_doc) != {"version", "cities"}: err("cities.json", f"unexpected top-level keys {set(cities_doc)}")
    cities = cities_doc.get("cities", [])
    if len(cities) != 24: err("cities.json", f"expected 24 cities, got {len(cities)}")
    idxs = [c.get("index") for c in cities]
    if idxs != sorted(idxs) or idxs != list(range(1, len(cities) + 1)): err("cities.json", f"cities must be sorted by index 1..24: {idxs}")
    regions = [c.get("region") for c in cities]
    for r, rng in (("palestine", range(0, 8)), ("arab", range(8, 16)), ("world", range(16, 24))):
        if any(regions[i] != r for i in rng if i < len(regions)): err("cities.json", f"cities {rng.start+1}-{rng.stop} must be region {r}")
    seen_ids = set()
    twist_types_used = []
    for c in cities:
        cid = c.get("id", "?"); W = f"city {cid}"
        for k in c:
            if k not in CITY_FIELDS_R | CITY_FIELDS_O: err(W, f"unknown field {k} (schema 2)")
        for k in CITY_FIELDS_R:
            if k not in c: err(W, f"missing required field {k}")
        if not isinstance(cid, str) or not ID_RE.match(cid): err(W, "id must be lowerCamelCase")
        if cid in seen_ids: err(W, "duplicate city id")
        seen_ids.add(cid); city_by_id[cid] = c
        i = c.get("index", 0)
        check_gtext(f"{W}.name", c.get("name"))
        if c.get("region") not in REGION: err(W, f"bad region {c.get('region')}")
        cur = c.get("currency", {})
        if set(cur) != {"name", "symbol", "art"}: err(W, f"currency must have name, symbol, art: {list(cur)}")
        check_gtext(f"{W}.currency.name", cur.get("name"))
        if not isinstance(cur.get("symbol"), str) or not cur.get("symbol") or len(cur["symbol"]) > 6:
            err(W, f"currency.symbol must be a short string: {cur.get('symbol')!r}")
        check_art(f"{W}.currency.art", cur.get("art"), ("ui_",))
        check_art(f"{W}.landmarkArt", c.get("landmarkArt"), ("bld_",))
        for j, a in enumerate(c.get("decorArts", [])): check_art(f"{W}.decorArts[{j}]", a)
        for j, a in enumerate(c.get("customerArts", [])): check_art(f"{W}.customerArts[{j}]", a, ("ppl_", "ani_"))
        pal = c.get("palette", {})
        if set(pal) != {"skyTop", "skyMid", "sunset", "glow", "accent"}: err(W, f"palette keys must be skyTop, skyMid, sunset, glow, accent: {list(pal)}")
        for k, v in pal.items():
            if not isinstance(v, str) or not HEX.match(v): err(W, f"palette.{k} not #RRGGBB: {v}")
        if c.get("silhouette", "oldCity") not in SILHOUETTE: err(W, f"bad silhouette {c.get('silhouette')}")
        exp_cap = 100 if i <= 3 else 200 if i <= 8 else 300 if i <= 16 else 400
        if c.get("levelCap") != exp_cap: err(W, f"levelCap {c.get('levelCap')} != GDD {exp_cap}")
        exp_lic = {1: 0, 2: 0, 3: 0, 4: 1, 5: 2, 6: 4, 7: 8, 8: 12}.get(i, 24 if i <= 16 else 36)
        if c.get("licenceHours") != exp_lic: err(W, f"licenceHours {c.get('licenceHours')} != GDD {exp_lic}")
        F = c.get("finalGoalBase"); S = c.get("priceScale")
        if not is_num(F) or F <= 0: err(W, "finalGoalBase must be > 0"); F = 1
        if not is_num(S) or S < 1: err(W, "priceScale must be >= 1"); S = 1
        if F * S >= 1e30: err(W, "finalGoalBase × priceScale >= 1e30")
        if i in GDD:
            n_exp, lf, s_exp = GDD[i]
            if abs(math.log10(F) - lf) > 0.01: warn(W, f"finalGoalBase log10 {math.log10(F):.2f} differs from GDD {lf}")
            if abs(S - s_exp) > 1e-9: warn(W, f"priceScale {S} differs from GDD {s_exp}")
        # stations
        sts = c.get("stations", [])
        if not 6 <= len(sts) <= 8: err(W, f"needs 6-8 stations, has {len(sts)}")
        if i in GDD and len(sts) != GDD[i][0]: warn(W, f"{len(sts)} stations, GDD table says {GDD[i][0]}")
        keys = []
        for t, s in enumerate(sts):
            SW = f"{W}.stations[{t}]"
            for k in s:
                if k not in STATION_R | STATION_O: err(SW, f"unknown field {k}")
            for k in STATION_R:
                if k not in s: err(SW, f"missing {k}")
            if s.get("tier") != t: err(SW, f"tier {s.get('tier')} must equal index {t}")
            if s.get("id") != f"{cid}.{s.get('key')}": err(SW, f"id must be '{cid}.<key>'")
            if s.get("id") in all_station_ids: err(SW, "station id not globally unique")
            all_station_ids.add(s.get("id")); keys.append(s.get("key"))
            if not isinstance(s.get("key"), str) or not ID_RE.match(s.get("key", "")): err(SW, "key must be lowerCamelCase")
            check_gtext(f"{SW}.name", s.get("name"))
            check_art(f"{SW}.art", s.get("art"), ("food_", "ani_"))
            if s.get("cuisine") not in CUISINE: err(SW, f"bad cuisine {s.get('cuisine')}")
            if s.get("category") not in CATEGORY: err(SW, f"bad category {s.get('category')}")
            if s.get("weather", "none") not in WEATHER_TAG: err(SW, f"bad weather {s.get('weather')}")
            if "managerName" in s: check_gtext(f"{SW}.managerName", s["managerName"])
            if "managerArt" in s: check_art(f"{SW}.managerArt", s["managerArt"], ("ppl_",))
        if len(set(keys)) != len(keys): err(W, "duplicate station keys")
        names = [s.get("name") for s in sts]
        if len(set(map(str, names))) != len(names): err(W, "duplicate station names")
        # upgrades (GDD 2.8)
        ups = c.get("upgrades", [])
        exp_n = 0
        while 2.5e5 * 20 ** exp_n <= 10 * F: exp_n += 1
        if len(ups) != exp_n: err(W, f"{len(ups)} upgrades, GDD 2.8 generates {exp_n}")
        order = []
        while len(order) < len(ups) + 1: order += keys + ["all"]
        up_ids = set()
        for j, u in enumerate(ups):
            UW = f"{W}.upgrades[{j}]"
            for k in u:
                if k not in {"id", "target", "mult", "priceBase", "name"}: err(UW, f"unknown field {k}")
            if u.get("id") != f"{cid}.u{j:02d}": err(UW, f"id should be {cid}.u{j:02d}")
            if u.get("id") in up_ids: err(UW, "duplicate id")
            up_ids.add(u.get("id"))
            if u.get("target") not in keys + ["all"]: err(UW, f"target {u.get('target')} not a station key or 'all'")
            elif u.get("target") != order[j]: warn(UW, f"target {u.get('target')} breaks GDD order (expected {order[j]})")
            if not is_num(u.get("priceBase")) or abs(u["priceBase"] - 2.5e5 * 20 ** j) > 1e-6 * u["priceBase"]:
                err(UW, f"priceBase {u.get('priceBase')} != 2.5e5·20^{j}")
            if u.get("mult", 3) != 3: warn(UW, "mult != 3")
            if "name" in u: check_gtext(f"{UW}.name", u["name"])
        # twists
        tws = c.get("twists", [])
        if len(tws) > 2: err(W, "at most 2 twists")
        if i == 1 and tws: err(W, "Jerusalem (tutorial) must have no twist")
        if i > 1 and not tws: err(W, "cities 2-24 need a twist")
        ttypes = []
        for j, tw in enumerate(tws):
            TW = f"{W}.twists[{j}]"
            if set(tw) != {"type", "params"}: err(TW, f"twist must be {{type, params}}: {list(tw)}")
            t = tw.get("type"); p = tw.get("params", {})
            if t not in TWIST_PARAMS: err(TW, f"unknown twist type {t}"); continue
            ttypes.append(t)
            req, opt = TWIST_PARAMS[t]
            for k in req:
                if k not in p: err(TW, f"missing required param {k}")
            for k in p:
                if k not in req | opt: err(TW, f"unknown param {k}")
            for k, v in p.items():
                if k in STATION_KEYS_IN and v not in keys: err(TW, f"{k}={v} is not a station key of {cid}")
                if k in STATION_LISTS_IN:
                    if not isinstance(v, list): err(TW, f"{k} must be a list")
                    else:
                        for x in v:
                            if x not in keys: err(TW, f"{k} contains unknown station key {x}")
            if t == "ovenTiming" and p.get("station") in keys and keys.index(p["station"]) < 2:
                err(TW, "ovenTiming station must be tier >= 2 (GDD 3.6)")
            if t == "productionChain" and p.get("inputStation") == p.get("outputStation"): err(TW, "chain input == output")
            if t == "weatherSwing":
                tot = p.get("hotProb", 0.45) + p.get("coldProb", 0.15) + p.get("rainProb", 0.10)
                if tot > 1 + 1e-9: err(TW, f"weather probs sum {tot} > 1")
            if t == "vipLounge":
                w = p.get("vipTierWeights", [0.6, 0.3, 0.1])
                if len(w) != 3 or abs(sum(w) - 1) > 1e-6: err(TW, f"vipTierWeights must be 3 probs summing to 1: {w}")
                if p.get("loungeStation") in keys and 3 * p.get("levelPerTier", 40) > c.get("levelCap", 0):
                    err(TW, "VIP tier 3 needs a lounge level above the cap")
            if t == "nightMarket" and not p.get("stations"): warn(TW, "nightMarket with [] = all stations")
            if t == "deliveryRuns":
                ex = p.get("extraScooterCostsBase", [])
                if any((not is_num(x)) for x in ex) or ex != sorted(ex): err(TW, "extraScooterCostsBase must be ascending numbers")
        if len(tws) == 2 and ttypes[0] == ttypes[1] and cid != "amman": err(W, "two twists of the same type are only allowed in Amman")
        twist_types_used.append(tuple(ttypes))
        # goals
        goals = c.get("goals", [])
        if not 15 <= len(goals) <= 24: err(W, f"goals must be 15-24, has {len(goals)}")
        gids = []
        stars = 0
        prev_cash = 0; prev_all = 0
        types_seen = set()
        for j, g in enumerate(goals):
            GW = f"{W}.goals[{j}]"
            for k in g:
                if k not in {"id", "type", "params", "stars", "scope", "text", "rewards"}: err(GW, f"unknown field {k}")
            if g.get("id") != f"{cid}.g{j + 1:02d}": err(GW, f"id should be {cid}.g{j + 1:02d}")
            gids.append(g.get("id"))
            t = g.get("type"); p = g.get("params", {})
            if t not in GOAL_PARAMS: err(GW, f"unknown goal type {t}"); continue
            types_seen.add(t)
            req, opt, _ = GOAL_PARAMS[t]
            if set(p) - (req | opt) or req - set(p): err(GW, f"params {sorted(p)} != required {sorted(req)} (+{sorted(opt)})")
            if "stationId" in p and p["stationId"] not in {s.get("id") for s in sts}: err(GW, f"stationId {p['stationId']} not in {cid}")
            for k in ("level", "count"):
                if k in p and (not is_num(p[k]) or p[k] <= 0): err(GW, f"{k} must be > 0")
            if "level" in p and p["level"] > c.get("levelCap", 0): err(GW, f"level {p['level']} above cap")
            if t == "managersCount" and p.get("count", 0) > len(sts): err(GW, "managersCount above station count")
            if t == "buyUpgrades" and p.get("count", 0) > len(ups): err(GW, "buyUpgrades above upgrade count")
            if t == "earnCash":
                a = p.get("amountBase", 0)
                if a > F * (1 + 1e-9): err(GW, "earnCash above finalGoalBase")
                if a < prev_cash: warn(GW, "earnCash targets not ascending")
                prev_cash = max(prev_cash, a)
            if t == "allStationsLevel":
                if p.get("level", 0) < prev_all: warn(GW, "allStationsLevel not ascending")
                prev_all = max(prev_all, p.get("level", 0))
            if t == "twistMetric":
                m = p.get("metric")
                if m not in TWIST_METRICS: err(GW, f"unknown metric {m}")
                elif TWIST_METRICS[m] not in ttypes: err(GW, f"metric {m} needs a {TWIST_METRICS[m]} twist in {cid}")
            if "scope" in g and g["scope"] not in ("city", "slot"): err(GW, "scope must be city/slot")
            if not is_int(g.get("stars")) or not 1 <= g["stars"] <= 3: err(GW, "stars must be 1-3")
            else: stars += g["stars"]
            check_gtext(f"{GW}.text", g.get("text"))
            txt = json.dumps(g.get("text"), ensure_ascii=False)
            if t == "earnCash" and "{amount}" not in txt: warn(GW, "earnCash text should use {amount}")
            for k, r in enumerate(g.get("rewards", [])): check_reward(f"{GW}.rewards[{k}]", r)
            # unlock timing (warning only)
            # Jerusalem goals 14, 17, 18 are deliberate time gates (GDD 3.4)
            if t in GOAL_UNLOCK and i in EXP_LEVEL and not (cid == "jerusalem" and j + 1 in (14, 17, 18)):
                frac = j / max(1, len(goals) - 1)
                allowed = EXP_LEVEL[i] + 1 + frac * (EXP_LEVEL[i + 1] - EXP_LEVEL[i])
                if GOAL_UNLOCK[t] > allowed + 0.5:
                    warn(GW, f"{t} unlocks at L{GOAL_UNLOCK[t]}, expected level here ≈ L{allowed:.0f}")
            if t == "branchCollect" and i < 3: err(GW, "branchCollect impossible before a branch exists")
        if len(set(gids)) != len(gids): err(W, "duplicate goal ids")
        city_goal_ids[cid] = set(gids)
        stg = c.get("starsToGraduate", math.ceil(0.75 * stars))
        if stg > stars: err(W, f"starsToGraduate {stg} > total stars {stars}")
        if stg != math.ceil(0.75 * stars): warn(W, f"starsToGraduate {stg} != ceil(0.75 × {stars})")
        last = goals[-1] if goals else {}
        if last.get("type") != "earnCash" or abs(last.get("params", {}).get("amountBase", 0) - F) > 1e-9 * F:
            err(W, "last goal must be earnCash = finalGoalBase (crown goal)")
        if i > 1:
            for need in ("unlockStation", "stationLevel", "managersCount", "earnCash", "buyUpgrades", "allStationsLevel", "twistMetric"):
                if need not in types_seen: err(W, f"goal mix missing {need}")
            if len(types_seen) < 9: warn(W, f"only {len(types_seen)} goal types")
        # rival, chapter, rush
        rv = c.get("rival", {})
        if set(rv) != {"name", "art"}: err(W, "rival must be {name, art}")
        check_gtext(f"{W}.rival.name", rv.get("name")); check_art(f"{W}.rival.art", rv.get("art"), ("ppl_",))
        chapter_refs[c.get("chapterId")] = cid
        ri = c.get("rushIngredients", {})
        if set(ri) != {"bases", "fillings"}: err(W, "rushIngredients must be {bases, fillings}")
        if len(ri.get("bases", [])) != 2: err(W, "rushIngredients.bases must have 2")
        if len(ri.get("fillings", [])) != 6: err(W, "rushIngredients.fillings must have 6")
        rk = []
        for part in ("bases", "fillings"):
            for j, x in enumerate(ri.get(part, [])):
                IW = f"{W}.rushIngredients.{part}[{j}]"
                if set(x) != {"key", "name", "art"}: err(IW, "ingredient must be {key, name, art}")
                rk.append(x.get("key")); check_gtext(f"{IW}.name", x.get("name")); check_art(f"{IW}.art", x.get("art"), ("food_", "ani_"))
        if len(set(rk)) != len(rk): err(W, "duplicate rush ingredient keys")
        summary.append((i, cid, c.get("name"), "+".join(ttypes) or "—", len(sts), len(goals), stars, stg))
    # variety: consecutive cities should not repeat the same first twist
    for a in range(1, len(twist_types_used) - 1):
        if twist_types_used[a] and twist_types_used[a + 1] and twist_types_used[a][0] == twist_types_used[a + 1][0]:
            warn("cities.json", f"cities {a + 1} and {a + 2} open with the same twist {twist_types_used[a][0]}")

# ---------------------------------------------------------------- story
scene_ids = set()
if story_doc:
    ordered_first_key("story.json", story_doc)
    for k in story_doc:
        if k not in {"version", "cast", "chapters", "extraScenes", "memories"}: err("story.json", f"unknown top-level key {k}")
    cast_ids = set()
    for j, cm in enumerate(story_doc.get("cast", [])):
        CW = f"story.cast[{j}]"
        if set(cm) != {"id", "name", "art"}: err(CW, "cast entry must be {id, name, art}")
        if cm.get("id") in cast_ids or cm.get("id") in ("player", "rival"): err(CW, f"duplicate/reserved cast id {cm.get('id')}")
        cast_ids.add(cm.get("id"))
        check_gtext(f"{CW}.name", cm.get("name")); check_art(f"{CW}.art", cm.get("art"), ("ppl_", "ani_"))
    if "sitti" not in cast_ids: err("story.cast", "mentor 'sitti' missing")
    speakers_used = set()

    def check_scene(where, sc, city=None):
        for k in sc:
            if k not in {"id", "trigger", "triggerParam", "lines", "rewards"}: err(where, f"unknown field {k}")
        sid = sc.get("id")
        if not isinstance(sid, str) or not sid: err(where, "missing id")
        if sid in scene_ids: err(where, f"duplicate scene id {sid}")
        scene_ids.add(sid)
        t = sc.get("trigger"); p = sc.get("triggerParam")
        if t not in SCENE_TRIGGERS: err(where, f"bad trigger {t}")
        if t in ("rival", "midpoint") and not (is_num(p) and 0 < p < 1): err(where, f"{t} needs a star fraction 0..1")
        if t == "festival" and p not in FESTIVALS: err(where, f"festival param {p} unknown")
        if t == "memory" and not is_num(p): err(where, "memory needs level number")
        if t == "manual":
            if not isinstance(p, str) or not p: err(where, "manual needs a string triggerParam")
            elif p.startswith("goal:"):
                gid = p[5:]
                if city is None or gid not in city_goal_ids.get(city, set()): err(where, f"goal trigger {gid} not a goal of {city}")
        if p is not None and not isinstance(p, (str, int, float)): err(where, "triggerParam must be String or Double")
        lines = sc.get("lines", [])
        if not 2 <= len(lines) <= 5: err(where, f"needs 2-5 lines, has {len(lines)}")
        for k, ln in enumerate(lines):
            LW = f"{where}.lines[{k}]"
            if set(ln) != {"speaker", "text"}: err(LW, "line must be {speaker, text}")
            spk = ln.get("speaker"); speakers_used.add(spk)
            if spk not in cast_ids | {"player", "rival"}: err(LW, f"unknown speaker {spk}")
            if spk == "rival" and city is None: err(LW, "'rival' speaker outside a city chapter")
            check_gtext(LW, ln.get("text"), max_words=12, allow_ph=set())
        for k, r in enumerate(sc.get("rewards", [])): check_reward(f"{where}.rewards[{k}]", r)

    chs = story_doc.get("chapters", [])
    if len(chs) != 24: err("story.chapters", f"expected 24 chapters, got {len(chs)}")
    ch_ids = set()
    total_scenes = 0
    for j, ch in enumerate(chs):
        CW = f"story.chapters[{j}]({ch.get('id')})"
        if set(ch) != {"id", "cityId", "scenes"}: err(CW, "chapter must be {id, cityId, scenes}")
        if ch.get("id") in ch_ids: err(CW, "duplicate chapter id")
        ch_ids.add(ch.get("id"))
        if chapter_refs.get(ch.get("id")) != ch.get("cityId"): err(CW, "chapter id/cityId does not match cities.json chapterId")
        scs = ch.get("scenes", [])
        total_scenes += len(scs)
        if not 6 <= len(scs) <= 10: err(CW, f"chapter needs 6-10 scenes, has {len(scs)}")
        trig = [s.get("trigger") for s in scs]
        for need in ("arrival", "rival", "midpoint", "finale"):
            if trig.count(need) < 1: err(CW, f"missing {need} scene")
        if trig.count("arrival") != 1 or trig.count("finale") != 1: err(CW, "exactly one arrival and one finale")
        if trig and (trig[0] != "arrival" or trig[-1] != "finale"): err(CW, "scenes must start with arrival and end with finale")
        for k, sc in enumerate(scs):
            check_scene(f"{CW}.scenes[{k}]", sc, ch.get("cityId"))
        city = city_by_id.get(ch.get("cityId"), {})
        mentors = {ln.get("speaker") for sc in scs for ln in sc.get("lines", [])}
        if "sitti" not in mentors: err(CW, "ستّي never speaks in this chapter")
        if "rival" not in mentors: err(CW, "the rival never speaks in this chapter")
        fin = [s for s in scs if s.get("trigger") == "finale"]
        if fin and not fin[0].get("rewards"): warn(CW, "finale scene has no graduation reward")
    for cid in city_by_id:
        if city_by_id[cid].get("chapterId") not in ch_ids: err(f"city {cid}", "chapterId not found in story.json")
    for j, sc in enumerate(story_doc.get("extraScenes", [])):
        check_scene(f"story.extraScenes[{j}]({sc.get('id')})", sc)
    fest_cov = {s.get("triggerParam") for s in story_doc.get("extraScenes", []) if s.get("trigger") == "festival"}
    for f in ("mothersDay", "ramadan", "eidFitr"):
        if f not in fest_cov: err("story.extraScenes", f"GDD 6.19 festival beat missing: {f}")
    mem = story_doc.get("memories", [])
    mem_ids = [m.get("id") for m in mem]
    for lv in MEMORY_LEVELS:
        if f"memory_L{lv}" not in mem_ids: err("story.memories", f"memory_L{lv} missing (Appendix H storyMemory)")
    for j, sc in enumerate(mem):
        check_scene(f"story.memories[{j}]({sc.get('id')})", sc)
        if sc.get("trigger") != "memory": err(f"story.memories[{j}]", "trigger must be memory")
        if sc.get("id") != f"memory_L{sc.get('triggerParam')}": err(f"story.memories[{j}]", "id must be memory_L{level}")
    unused = cast_ids - speakers_used
    if unused: warn("story.cast", f"cast never speaks: {sorted(unused)}")

# ---------------------------------------------------------------- report
for w in warnings: print(w)
for e in errors: print(e)
if summary:
    print("\n#  id         name            twist(s)                          st  goals  ★  grad")
    for row in summary:
        print(f"{row[0]:<2} {row[1]:<10} {str(row[2]):<14} {row[3]:<33} {row[4]:<3} {row[5]:<6} {row[6]:<3} {row[7]}")
    print(f"total goals: {sum(r[5] for r in summary)}  total stars: {sum(r[6] for r in summary)}")
if story_doc:
    print(f"story: {len(story_doc.get('chapters', []))} chapters, "
          f"{sum(len(c.get('scenes', [])) for c in story_doc.get('chapters', []))} chapter scenes, "
          f"{len(story_doc.get('extraScenes', []))} extra scenes, {len(story_doc.get('memories', []))} memories, "
          f"{len(story_doc.get('cast', []))} cast")
print(f"\nRESULT: {len(errors)} errors, {len(warnings)} warnings")
sys.exit(1 if errors else 0)
