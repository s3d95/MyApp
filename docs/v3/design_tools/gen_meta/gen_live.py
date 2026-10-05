"""league.json, contracts.json, events.json"""
from common import *

# ---------------------------------------------------------------- league.json
# (key, name, archetype, bio). All chains are openly fictional ("مطعم وهمي").
# `archetype` and `bio` are additive optional fields (personality); see check_meta.py EXTENSIONS.
LEAGUE_NAMES = [
    ("abuShaker", "مطعم أبو شاكر", "steady", "جارك من القدس، بيحلف إنّ فلافله أطيب، وبيسلّم عليك كل صبح"),
    ("falafelAlAmana", "فلافل الأمانة", "steady", "ما بيغشّ ولا بقرص، وبيرجّع الفراطة لآخر قرش"),
    ("hummusAlMalik", "حمّص الملك", "sprinter", "بيلبس تاج من كرتون وبيقول الحمّص ملكه لحاله"),
    ("snackAlDayaa", "سناك الضيعة", "earlyBird", "بيصحى قبل الديك، وبيخلّص شغله قبل ما تصحى إنت"),
    ("mashawiAlKheimeh", "مشاوي الخيمة", "weekendBurst", "نارهم بتولع آخر الأسبوع، والدخنة بتوصل للقمر"),
    ("bastetAlFarah", "بسطة الفرح", "weekendBurst", "كل زبون بيطلع من عندهم بيغنّي"),
    ("kushkAlNajmeh", "كشك النجمة", "sprinter", "صغير بس نشيط، وبيحب يطلع بالصورة"),
    ("falafelAlaKeifak", "فلافل على كيفك", "steady", "بيعملك القرص زي ما بدّك: صغير، كبير، أو مربّع!"),
    ("fulAbuAlAbed", "فول أبو العبد", "closer", "قدرته على النار من الفجر، وما بيستعجل أبداً"),
    ("matamAlDawwar", "مطعم الدوّار", "steady", "عالدوّار، وكل سيّارة بتلفّ لازم توقف عنده"),
    ("shawarmaAlSahra", "شاورما السهرة", "closer", "بيفتح المسا وبيسكّر مع طلعة الضو"),
    ("knafehAlAseel", "كنافة الأصيل", "weekendBurst", "صينيّته بتطلع مع العصر، والدور بيوصل للزاوية"),
    ("beitAlHummus", "بيت الحمّص", "steady", "عندهم سبع أنواع حمّص، وبيحلفوا إنّ التامن جاي"),
    ("matbakhSittAlDar", "مطبخ ستّ الدار", "earlyBird", "ستّ الدار بتطبخ وبتوزّع عالجيران قبل الزباين"),
    ("arabayetAbuZaid", "عربايّة أبو زيد", "sprinter", "عربايته بتلفّ الحارات كلها، وبتوصل قبلك"),
    ("malikAlTaamiyeh", "ملك الطعميّة", "closer", "جاي من مصر يتحدّى، وبيقول: طعميّة مش فلافل!"),
    ("falafelAlMashi", "فلافل عالماشي", "sprinter", "بيعطيك السندويشة وإنت ماشي، ولا بيوقّفك دقيقة"),
    ("matamAlTayyibin", "مطعم الطيّبين", "steady", "أطيب ناس بالدوري، بيهنّوك حتّى لو سبقتهم"),
    ("hummusWaDaqqa", "حمّص ودقّة", "earlyBird", "دقّتهم بالهاون بتنسمع من آخر السوق"),
    ("bastetAlKheir", "بسطة الخير", "steady", "بيطعموا كل محتاج ببلاش، والرزق بيزيد"),
    ("abuSalehFalafel", "أبو صالح للفلافل", "closer", "ختيار عنيد، بيستنّى آخر الأسبوع وبيقلب الطاولة"),
    ("mashawiAlSultan", "مشاوي السلطان", "weekendBurst", "بيعامل كل زبون زي السلطان، وبيطلب منك تقعد ساعة"),
    ("sandwichatAlMadina", "سندويشات المدينة", "sprinter", "سريعين زي البرق وقت الغدا"),
    ("matamAlKaram", "مطعم الكرم", "steady", "صحونهم مليانة لدرجة بدّك كيس توخذ الباقي"),
    ("kushkAlHabayeb", "كشك الحبايب", "weekendBurst", "كل الحارة بتقعد عندهم تسولف"),
    ("fatayerUmmAli", "فطاير أم علي", "earlyBird", "أم علي بتعجن بإيدين من ذهب"),
    ("manaqishWBass", "منقوشة وبس", "steady", "ما بيعملوا غير منقوشة، بس بيعملوها صح"),
    ("beitAlKubbeh", "بيت الكبّة", "sprinter", "كبّتهم مدبّبة من الطرفين زي الصاروخ"),
    ("matamSama", "مطعم سما", "closer", "مطعم على سطح، والمنظر لحاله بيجيب زباين"),
    ("alTahouneh", "الطاحونة", "weekendBurst", "بيطحنوا الحمّص الصبح، وبيطحنوا المنافسين آخر الأسبوع"),
    ("falafelAlBadr", "فلافل البدر", "closer", "بيقولوا القرص عندهم مدوّر زيّ البدر بنص الشهر"),
    ("sajAlBaraka", "صاج البركة", "steady", "الصاج عندهم ما بيبرد من الصبح للمسا"),
    ("kaakAbuJamil", "كعك أبو جميل", "earlyBird", "بينادي: كعك بسمسم! وصوته بيوصل لآخر الحارة"),
    ("tabounUmmIssa", "طابون أم عيسى", "earlyBird", "خبزها بيطلع منفّخ، وريحته بتصحّي الجيران"),
    ("qahwetAlMukhtar", "قهوة المختار", "steady", "بيصبّوا القهوة وبيوزّعوا أخبار الحارة ببلاش"),
    ("halawiyatAlSaa", "حلويات الساعة", "sprinter", "بيوقّتوا الكنافة عالساعة، ولا ثانية زيادة"),
    ("matamAlMina", "مطعم الميناء", "weekendBurst", "سمكهم من البحر للصحن بنص ساعة"),
    ("snackAmmoSamir", "سناك عمّو سمير", "steady", "عمّو سمير بيحكي نكت أكتر ما بيقلي"),
    ("kushkAlTalabeh", "كشك الطلبة", "closer", "بيعرفوا كل الطلّاب بأساميهم، وبيدينوهم لآخر الشهر"),
    ("awladAlAmm", "أولاد العم للمشاوي", "weekendBurst", "تلات أولاد عم، وكل واحد بيقول إنّه هو المعلّم"),
    ("falafelAlSarukh", "فلافل الصاروخ", "sprinter", "توصيلهم أسرع من الصاروخ، والسندويشة بتوصل سخنة"),
    ("bastetAlYasmin", "بسطة الياسمين", "steady", "ريحة الياسمين عندهم بتختلط بريحة الفلافل"),
    ("zaatarWZeit", "زعتر وزيت", "earlyBird", "فطورهم بيفتح النفس، والزيت من كرم ستّهم"),
    ("beitAlMaqluba", "بيت المقلوبة", "closer", "كل ما يقلبوا الطنجرة بتصفّق الحارة كلها"),
    ("arabayetAlSaada", "عربايّة السعادة", "weekendBurst", "عربايّة صغيرة، بس الضحكة عندهم كبيرة"),
]
PREFIXES = ["فلافل", "حمّص", "مطعم", "بسطة", "كشك", "مشاوي", "شاورما", "فطاير", "كنافة", "سناك"]
SUFFIXES = ["الهنا", "الوادي", "الربيع", "السعادة", "الدار", "الجبل", "البلد", "الجامعة", "المحطّة",
            "القمر", "النجوم", "الأصدقاء", "الحارة", "البحر"]
AVATARS = ["food_falafel", "food_hummus_bowl", "food_shawarma_wrap", "food_pie", "food_sandwich",
           "food_stuffed_flatbread", "food_meat_on_bone", "food_tea", "ppl_man_cook", "ppl_woman_cook",
           "ppl_cook", "ppl_old_man", "ppl_beard", "ppl_woman_headscarf", "ppl_man", "ppl_woman"]


def league():
    tiers = [
        (1, "بسطة", "bld_tent", 15, 0, 0.45),
        (2, "عربايّة", "veh_shopping_cart", 12, 5, 0.75),
        (3, "كشك", "bld_hut", 10, 5, 0.90),
        (4, "دكّانة", "bld_convenience_store", 8, 5, 1.00),
        (5, "مطعم", "food_fork_knife_plate", 7, 5, 1.05),
        (6, "مطعم مشهور", "ui_glowing_star", 6, 5, 1.10),
        (7, "سلسلة مطاعم", "bld_department_store", 5, 5, 1.15),
        (8, "ماركة بالبلد", "ui_military_medal", 5, 5, 1.20),
        (9, "أسطورة", "ui_trophy", 4, 5, 1.25),
        (10, "سلطان الفلافل", "ui_crown", 0, 5, 1.30),
    ]
    return {
        "version": 1,
        "unlockLevel": 12, "groupSize": 30, "defaultBaseline": 1400, "firstWeekQ": 0.35,
        "sigma": 0.45, "noiseDaily": 0.03,
        "tiers": [{"id": i, "name": n, "art": a, "promote": p, "demote": d, "q": q} for i, n, a, p, d, q in tiers],
        "archetypes": [{"id": "steady", "weight": 0.40}, {"id": "earlyBird", "weight": 0.15},
                       {"id": "weekendBurst", "weight": 0.20}, {"id": "closer", "weight": 0.15},
                       {"id": "sprinter", "weight": 0.10}],
        "rewards": [
            {"fromRank": 1, "toRank": 1, "goldBase": 30, "goldPerTier": 10, "chest": "silver", "chestFromTier6": "gold"},
            {"fromRank": 2, "toRank": 3, "goldBase": 20, "goldPerTier": 8, "chest": "wood", "chestFromTier6": "silver"},
            {"fromRank": 4, "toRank": 10, "goldBase": 15, "goldPerTier": 5},
            {"fromRank": 11, "toRank": 20, "goldBase": 10, "goldPerTier": 2},
            {"fromRank": 21, "toRank": 30, "goldBase": 5, "goldPerTier": 0},
        ],
        "promotionRewards": [chest("wood")],
        "repSources": {"dailyOrder": 20, "dailyBonus": 30, "weeklyOrder": 60, "weeklyBonus": 100,
                       "goalStar": 8, "contractGoal1": 25, "contractGoal2": 40, "contractGoal3": 60,
                       "eventMilestone": 10, "eventMilestoneFinal": 40, "special": 2, "choice": 5,
                       "rushRoundBase": 10, "rushRoundScorePer": 500, "supplyRun": 5, "researchLevel": 5,
                       "inspectorPerPoint": 2, "calendar": 10, "graduation": 100},
        "names": {
            "fixed": [{"key": k, "name": n, "archetype": a, "bio": b} for k, n, a, b in LEAGUE_NAMES],
            "prefixes": PREFIXES, "suffixes": SUFFIXES,
        },
        "avatars": AVATARS,
    }


# ---------------------------------------------------------------- shared side-station helper
def S(key, name, art, tier, cuisine, category, weather=None):
    s = {"key": key, "name": name, "art": art, "tier": tier, "cuisine": cuisine, "category": category}
    if weather:
        s["weather"] = weather
    return s


def stations(*rows):
    """rows: (key, name, art, cuisine, category[, weather]) -> tiers assigned 0..n-1 in order."""
    return [S(r[0], r[1], r[2], i, r[3], r[4], r[5] if len(r) > 5 else None) for i, r in enumerate(rows)]


def T(type_, **params):
    return {"type": type_, "params": params}


# ---------------------------------------------------------------- contracts.json
# Lcasual (GDD 6.9, side sim, M = 1): stations -> {hours: lifetime}
LCASUAL = {3: {48: 2.9e12, 72: 7.9e12, 96: 1.3e13, 120: 1.9e13},
           4: {48: 5.0e12, 72: 1.1e13, 96: 1.8e13, 120: 2.6e13},
           5: {48: 3.7e12, 72: 8.6e12, 96: 2.9e13, 120: 5.3e13}}
SHARE_PATTERNS = {2: [0.15, 0.15], 3: [0.15, 0.13, 0.12], 4: [0.15, 0.13, 0.12, 0.10]}
GAMMAS = [1.0, 0.7, 1.5, 1.0]


def goals_for(n_st, hours, rules):
    base_n = max(3, n_st)
    g3 = 0.55 * LCASUAL[base_n][hours]
    if "noManagers" in rules:
        g3 *= 0.3
    if "oneStation" in rules:
        g3 *= 0.05
    g3 = sig3(g3)
    return [sig3(0.002 * g3), sig3(0.05 * g3), g3]


def partners(keys, arts, named=None):
    n = len(keys) if keys else len(named)
    shares = SHARE_PATTERNS[n]
    out = []
    for i in range(n):
        p = {}
        if keys:
            p["nameKey"] = keys[i]
        else:
            p["name"] = named[i]
        p["art"] = arts[i]
        p["share"] = shares[i]
        p["gamma"] = GAMMAS[i]
        out.append(p)
    return out


def C(order, id, title, art, hours, desc, st, pkeys, parts, goal3, rules=(), twists=(), named=None):
    rules = list(rules)
    return {
        "id": id, "releaseOrder": order, "title": title, "art": art, "desc": desc,
        "durationHours": hours, "stations": st,
        "goalsBase": goals_for(len(st), hours, rules),
        "partners": partners(pkeys, parts, named),
        "rules": rules, "twists": list(twists),
        "rewards": {"goal1": [gold(10), chest("wood")], "goal2": [zaatar(1)], "goal3": goal3},
    }


def contracts():
    L = []
    L.append(C(1, "hebronWedding", "عرس بالخليل", "bld_wedding", 72,
               "عرس ابن الحاج بالخليل، والمعازيم من كل البلاد. المنسف لازم يكفّي الكل!",
               stations(("mansaf", "منسف", "food_cooked_rice", "levantine", "dishes"),
                        ("knafeh", "كنافة", "food_pie", "palestinian", "sweets"),
                        ("juice", "عصير", "food_tropical_drink", "palestinian", "drinks", "cold"),
                        ("coffee", "قهوة سادة", "food_teapot", "gulf", "drinks", "hot")),
               ["matamAlKaram", "mashawiAlSultan", "knafehAlAseel"], ["ppl_beard", "ppl_man_cook", "food_pie"],
               [hcase(1)]))
    L.append(C(2, "birzeitGraduation", "تخرّج بيرزيت", "ui_scroll", 48,
               "دفعة الهندسة تخرّجت! الأهالي بدّهم ضيافة، والخرّيجين بدّهم بيتزا.",
               stations(("cake", "كيك", "food_birthday_cake", "world", "sweets"),
                        ("pizza", "بيتزا", "food_pizza", "world", "bakery"),
                        ("juice", "عصير", "food_juice_box", "world", "drinks", "cold")),
               ["kushkAlTalabeh", "falafelAlMashi"], ["ppl_woman", "food_sandwich"],
               [cards(3, id="chefRami")], rules=["fastCheap"]))
    L.append(C(3, "gazaFishermen", "غدا صيّادين غزّة", "veh_motor_boat", 72,
               "المراكب رجعت مع الفجر، والصيّادين جوعانين. يلا عالطناجر!",
               stations(("fish", "سمك مقلي", "ani_fish", "palestinian", "seafood"),
                        ("rice", "رز صيّاديّة", "food_cooked_rice", "palestinian", "dishes"),
                        ("salad", "سلطة غزّاويّة", "food_green_salad", "palestinian", "dishes"),
                        ("tea", "شاي", "food_tea", "levantine", "drinks", "hot")),
               ["matamAlMina", "bastetAlKheir", "sajAlBaraka"], ["ppl_old_man", "ppl_woman_headscarf", "food_tea"],
               [hcase(1)], twists=[T("portShipments", station="fish")]))
    L.append(C(4, "eidOrphans", "حلو العيد للأيتام", "ui_gift", 48,
               "الحارة كلها متّفقة: ولا ولد بيقضّي العيد بلا حلو وبلا ضحكة.",
               stations(("kaak", "كعك", "food_cookie", "palestinian", "bakery"),
                        ("maamoul", "معمول", "food_moon_cake", "palestinian", "sweets"),
                        ("chocolate", "شوكولاتة", "food_chocolate_bar", "world", "sweets")),
               ["bastetAlKheir", "matamAlTayyibin", "matbakhSittAlDar", "halawiyatAlSaa"],
               ["ppl_woman_headscarf", "ppl_man", "ppl_woman_cook", "food_pie"],
               [cards(1, rarity="legendary")]))
    L.append(C(5, "iftarSaim", "إفطار صايم", "ui_crescent_moon", 48,
               "موائد الإفطار بالساحة، وكل صايم إله صحن سخن. الأذان قرّب!",
               stations(("soup", "شوربة عدس", "food_steaming_bowl", "levantine", "dishes", "hot"),
                        ("maqluba", "مقلوبة", "food_maqluba_pan", "palestinian", "dishes"),
                        ("jallab", "جلّاب", "food_cup_with_straw", "levantine", "drinks", "cold"),
                        ("qatayef", "قطايف", "food_dumpling", "levantine", "sweets")),
               ["beitAlMaqluba", "bastetAlKheir", "qahwetAlMukhtar", "knafehAlAseel"],
               ["ppl_old_woman", "ppl_man", "ppl_beard", "food_pie"],
               [hcase(1)], twists=[T("nightMarket", stations=[], startHour=18, endHour=23, nightMult=3)]))
    L.append(C(6, "canteenDuty", "مقصف المدرسة", "bld_school", 48,
               "الفرصة عشر دقايق بس، وكل الطلّاب بدّهم ساندويشة. بإيدك وبس، بلا معلّمين!",
               stations(("manousheh", "منقوشة زعتر", "food_flatbread", "levantine", "bakery"),
                        ("falafelSandwich", "ساندويش فلافل", "food_sandwich", "palestinian", "street"),
                        ("juice", "عصير", "food_juice_box", "world", "drinks", "cold")),
               ["kushkAlTalabeh", "manaqishWBass"], ["ppl_teacher", "food_stuffed_flatbread"],
               [cards(3, rarity="epic")], rules=["noManagers"]))
    L.append(C(7, "builderLunch", "غدا عمّال البنا", "ppl_construction", 72,
               "العمارة الجديدة طالعة، والعمّال بدّهم فطور بيسند الظهر.",
               stations(("ful", "فول مدمّس", "food_beans", "palestinian", "dishes", "hot"),
                        ("hummus", "حمّص", "food_hummus_bowl", "palestinian", "dishes"),
                        ("tea", "شاي", "food_tea", "levantine", "drinks", "hot"),
                        ("bread", "خبز", "food_bread", "palestinian", "bakery")),
               ["fulAbuAlAbed", "hummusWaDaqqa", "tabounUmmIssa"], ["ppl_older_person", "food_hummus_bowl", "ppl_woman_headscarf"],
               [hcase(1)]))
    L.append(C(8, "hospitalNight", "مناوبة المستشفى", "bld_hospital", 48,
               "الدكاترة والممرّضين سهرانين عشانّا، خلّينا نسهر عشانهم.",
               stations(("coffee", "قهوة", "food_coffee", "world", "drinks", "hot"),
                        ("sandwich", "ساندويش", "food_sandwich", "world", "street"),
                        ("soup", "شوربة", "food_steaming_bowl", "levantine", "dishes", "hot")),
               ["shawarmaAlSahra", "snackAmmoSamir"], ["ppl_man_cook", "ppl_man"],
               [cards(3, id="sittElSham")], twists=[T("nightMarket", stations=[], startHour=22, endHour=6, nightMult=3)]))
    L.append(C(9, "haraTeam", "فريق الحارة", "bld_stadium", 72,
               "نهائي الدوري الشعبي! الجمهور جاي بالباصات، والجوع جاي معهم.",
               stations(("fries", "بطاطا مقليّة", "food_french_fries", "world", "fried"),
                        ("shawarma", "شاورما", "food_shawarma_wrap", "levantine", "street"),
                        ("water", "مي باردة", "food_cup_with_straw", "world", "drinks", "cold"),
                        ("iceCream", "بوظة", "food_ice_cream", "world", "sweets", "cold")),
               ["sandwichatAlMadina", "falafelAlSarukh", "kushkAlNajmeh"], ["food_shawarma_wrap", "food_falafel", "ppl_man"],
               [cards(1, rarity="legendary")], twists=[T("busWaves")]))
    L.append(C(10, "hennaNight", "ليلة الحنّة", "ui_hibiscus", 48,
               "الصبايا بيغنّوا والعروس متحنّية. الحلو لازم يكون على قدّ الفرحة.",
               stations(("muhallabia", "مهلبيّة", "food_custard", "levantine", "sweets"),
                        ("coffee", "قهوة سادة", "food_teapot", "gulf", "drinks", "hot"),
                        ("fruit", "صحن فواكه", "food_grapes", "palestinian", "street", "cold")),
               ["bastetAlYasmin", "halawiyatAlSaa", "bastetAlFarah"], ["ppl_woman", "ppl_woman_cook", "ppl_woman_headscarf"],
               [hcase(1)], rules=["goldenHour"]))
    L.append(C(11, "scoutTrip", "رحلة الكشّافة", "bld_camping", 72,
               "مخيّم الكشّافة بالجبل، والطقس متقلّب زي مزاج القائد.",
               stations(("corn", "ذرة مشويّة", "food_corn", "levantine", "street"),
                        ("sweetPotato", "بطاطا حلوة عالجمر", "food_roasted_sweet_potato", "levantine", "street", "hot"),
                        ("fireTea", "شاي عالحطب", "food_teapot", "levantine", "drinks", "hot"),
                        ("sandwich", "ساندويش", "food_sandwich", "world", "street")),
               ["snackAlDayaa", "zaatarWZeit", "arabayetAbuZaid"], ["ppl_boy", "ppl_woman_farmer", "ppl_man"],
               [cards(3, rarity="epic")],
               twists=[T("weatherSwing", hotProb=0.4, coldProb=0.3, rainProb=0.1,
                         hotDayStations=["corn", "sandwich"], coldDayStations=["fireTea", "sweetPotato"],
                         rainDayStations=["fireTea"], mult=2.5)]))
    L.append(C(12, "bookFair", "معرض الكتاب", "ui_books", 96,
               "الكتّاب بيوقّعوا والقرّاء بيقلّبوا الصفحات، والكل بدّه قهوة وكعكة.",
               stations(("coffee", "قهوة", "food_coffee", "world", "drinks", "hot"),
                        ("croissant", "كرواسون", "food_croissant", "world", "bakery"),
                        ("kaak", "كعك بسمسم", "food_bagel", "palestinian", "bakery"),
                        ("cake", "كيك", "food_shortcake", "world", "sweets")),
               ["qahwetAlMukhtar", "kaakAbuJamil", "matamSama"], ["ppl_older_person", "food_tea", "ppl_woman_office"],
               [hcase(1)]))
    L.append(C(13, "oliveCrew", "قطّيفة الزيتون", "food_olive", 96,
               "العيلة كلها عالكرم من الفجر، والقطّيفة بدّهم زوّادة دسمة.",
               stations(("musakhan", "مسخّن", "food_stuffed_flatbread", "palestinian", "dishes"),
                        ("olives", "زيتون", "food_olive", "palestinian", "street"),
                        ("oilZaatar", "زيت وزعتر", "food_herb", "palestinian", "bakery"),
                        ("sageTea", "شاي بالميرميّة", "food_tea", "levantine", "drinks", "hot")),
               ["zaatarWZeit", "tabounUmmIssa", "snackAlDayaa", "sajAlBaraka"],
               ["ppl_woman_farmer", "ppl_woman_headscarf", "ppl_man_farmer", "food_stuffed_flatbread"],
               [hcase(1)], twists=[T("productionChain", inputStation="olives", outputStation="oilZaatar")]))
    L.append(C(14, "mukhtarFeast", "عزومة المختار", "ppl_older_person", 72,
               "المختار عازم العشيرة كلها، وبدّه الشغل من إيدك إنت، بلا مساعدة طبّاخين.",
               stations(("mansaf", "منسف", "food_cooked_rice", "levantine", "dishes"),
                        ("maqluba", "مقلوبة", "food_maqluba_pan", "palestinian", "dishes"),
                        ("knafeh", "كنافة", "food_pie", "palestinian", "sweets"),
                        ("coffee", "قهوة سادة", "food_teapot", "gulf", "drinks", "hot")),
               ["qahwetAlMukhtar", "matamAlKaram", "beitAlMaqluba"], ["ppl_older_person", "ppl_beard", "ppl_old_woman"],
               [cards(1, rarity="legendary")], rules=["chefsOff"]))
    L.append(C(15, "dabkeSquare", "دبكة بالساحة", "ui_musical_notes", 48,
               "فرقة الدبكة نازلة عالساحة، والدبّيكة بيجوعوا بعد كل دبكة!",
               stations(("shawarma", "شاورما", "food_shawarma_wrap", "levantine", "street"),
                        ("fries", "بطاطا", "food_french_fries", "world", "fried"),
                        ("juice", "عصير", "food_tropical_drink", "palestinian", "drinks", "cold")),
               ["bastetAlFarah", "kushkAlHabayeb", "awladAlAmm"], ["ppl_man", "ppl_woman", "food_meat_on_bone"],
               [cards(3, rarity="epic")], twists=[T("busWaves")]))
    L.append(C(16, "kgParty", "حفلة الروضة", "ui_balloon", 48,
               "تخرّج الروضة! أربعين طفل بتياب صغيرة وجوع كبير.",
               stations(("cupcake", "كب كيك", "food_cupcake", "world", "sweets"),
                        ("juice", "عصير", "food_juice_box", "world", "drinks", "cold"),
                        ("popcorn", "فشار", "food_popcorn", "world", "street")),
               ["arabayetAlSaada", "kushkAlNajmeh"], ["ppl_child", "ppl_woman_cook"],
               [cards(3, rarity="epic")], rules=["fastCheap"]))
    L.append(C(17, "engagement", "حفلة خطوبة", "ui_two_hearts", 72,
               "أهل العريس طلبوا إيد العروس، والجواب: موافقين! هسّا دور الحلو والقهوة.",
               stations(("knafeh", "كنافة", "food_pie", "palestinian", "sweets"),
                        ("chocolate", "شوكولاتة", "food_chocolate_bar", "world", "sweets"),
                        ("cake", "كيكة الخطوبة", "food_birthday_cake", "world", "sweets"),
                        ("coffee", "قهوة سادة", "food_teapot", "gulf", "drinks", "hot")),
               ["knafehAlAseel", "bastetAlYasmin", "matamSama"], ["food_pie", "ppl_woman", "ppl_man_cook"],
               [hcase(1)]))
    L.append(C(18, "bethlehemMarathon", "ماراثون بيت لحم", "ui_sports_medal", 48,
               "العدّائين طالعين من ساحة المهد، وبدّهم طاقة عالطريق.",
               stations(("banana", "موز", "food_banana", "world", "street"),
                        ("water", "مي", "food_cup_with_straw", "world", "drinks", "cold"),
                        ("sandwich", "ساندويش", "food_sandwich", "world", "street"),
                        ("oranges", "برتقال", "food_tangerine", "palestinian", "street", "cold")),
               ["falafelAlSarukh", "sandwichatAlMadina", "kushkAlNajmeh", "falafelAlMashi"],
               ["ppl_man", "ppl_woman", "ppl_boy", "food_sandwich"],
               [cards(1, rarity="legendary")], twists=[T("busWaves")]))
    L.append(C(19, "fridayMarket", "سوق الجمعة", "veh_shopping_bags", 96,
               "سوق الجمعة عجقة من الصبح، والبسطة بنص الدنيا.",
               stations(("falafel", "فلافل", "food_falafel", "palestinian", "fried"),
                        ("kaak", "كعك بسمسم", "food_bagel", "palestinian", "bakery"),
                        ("sugarcane", "عصير قصب", "food_cup_with_straw", "egyptian", "drinks", "cold"),
                        ("iceCream", "بوظة", "food_ice_cream", "world", "sweets", "cold")),
               ["falafelAlAmana", "kaakAbuJamil", "malikAlTaamiyeh"], ["food_falafel", "ppl_old_man", "ppl_beard"],
               [hcase(1)]))
    L.append(C(20, "jaffaHisbeh", "حسبة يافا", "veh_ship", 96,
               "حسبة السمك فاتحة، والبواخر بدّها صناديق برتقال. يافا ما بتنام!",
               stations(("fish", "سمك", "ani_fish", "palestinian", "seafood"),
                        ("shrimp", "قريدس", "food_fried_shrimp", "palestinian", "seafood"),
                        ("lemon", "ليمون بنعنع", "food_lemon", "palestinian", "drinks", "cold"),
                        ("oranges", "برتقال يافاوي", "food_tangerine", "palestinian", "street", "cold")),
               ["matamAlMina", "abuShaker", "falafelAlBadr"], ["ppl_woman", "ppl_man_cook", "food_falafel"],
               [cards(3, id="abuAliAlex")], twists=[T("portShipments", station="oranges")]))
    L.append(C(21, "villageWedding", "عرس بالضيعة", "bld_house_with_garden", 120,
               "عرس تلات أيام بالضيعة! الدبكة ما بتوقف، والطناجر كمان.",
               stations(("mansaf", "منسف", "food_cooked_rice", "levantine", "dishes"),
                        ("kubbeh", "كبّة مقليّة", "food_roasted_sweet_potato", "levantine", "fried"),
                        ("knafeh", "كنافة", "food_pie", "palestinian", "sweets"),
                        ("juice", "عصير", "food_tropical_drink", "palestinian", "drinks", "cold"),
                        ("coffee", "قهوة سادة", "food_teapot", "gulf", "drinks", "hot")),
               ["beitAlKubbeh", "mashawiAlKheimeh", "bastetAlFarah", "matamAlKaram"],
               ["food_meat_on_bone", "ppl_man_cook", "ppl_woman", "ppl_beard"],
               [cards(1, rarity="legendary")]))
    L.append(C(22, "factoryShift", "ورديّة المصنع", "bld_factory", 72,
               "الوردية الليلية بتبلّش، والعمّال بدّهم شاي وفول يصحّيهم.",
               stations(("tea", "شاي", "food_tea", "levantine", "drinks", "hot"),
                        ("ful", "فول", "food_beans", "palestinian", "dishes", "hot"),
                        ("sandwich", "ساندويش", "food_sandwich", "world", "street")),
               ["fulAbuAlAbed", "shawarmaAlSahra"], ["ppl_older_person", "food_shawarma_wrap"],
               [hcase(1)], twists=[T("nightMarket", stations=[], startHour=22, endHour=6, nightMult=3)]))
    L.append(C(23, "hummusChallenge", "تحدّي الحمّص", "food_hummus_bowl", 48,
               "محطّة وحدة، صحن واحد، وتحدّي كبير: مين بيعمل أطيب حمّص بالبلد؟",
               stations(("hummus", "حمّص بطحينة", "food_hummus_bowl", "palestinian", "dishes")),
               ["hummusAlMalik", "beitAlHummus"], ["food_hummus_bowl", "ppl_man_cook"],
               [cards(3, rarity="epic")], rules=["oneStation"]))
    L.append(C(24, "beachCamp", "مخيّم البحر", "bld_beach_with_umbrella", 96,
               "مخيّم صيفي عالشط، والشمس حامية. اللي عنده بطّيخ بارد بيربح!",
               stations(("watermelon", "بطّيخ", "food_watermelon", "palestinian", "street", "cold"),
                        ("corn", "ذرة", "food_corn", "levantine", "street"),
                        ("iceCream", "بوظة", "food_ice_cream", "world", "sweets", "cold"),
                        ("lemonade", "ليموناضة", "food_lemon", "levantine", "drinks", "cold")),
               ["matamAlMina", "arabayetAlSaada", "kushkAlHabayeb"], ["ppl_man_farmer", "ppl_girl", "ppl_woman"],
               [hcase(1)],
               twists=[T("weatherSwing", hotProb=0.6, coldProb=0.0, rainProb=0.0,
                         hotDayStations=["watermelon", "iceCream", "lemonade"], mult=2.5)]))
    # ---- new library rows (25-30) ----
    L.append(C(25, "tawjihiResults", "حلوان التوجيهي", "ui_party_popper", 48,
               "نتايج التوجيهي طلعت! الزمامير بالشوارع، وكل بيت بدّه صدر كنافة.",
               stations(("knafeh", "كنافة", "food_pie", "palestinian", "sweets"),
                        ("chocolate", "شوكولاتة", "food_chocolate_bar", "world", "sweets"),
                        ("juice", "عصير", "food_tropical_drink", "palestinian", "drinks", "cold")),
               ["knafehAlAseel", "halawiyatAlSaa", "kushkAlTalabeh"], ["food_pie", "ppl_woman_cook", "ppl_boy"],
               [cards(3, rarity="epic")], twists=[T("busWaves", intervalMin=15, waveMult=4)]))
    L.append(C(26, "wheatHarvest", "حصيدة القمح", "food_wheat", 96,
               "البيادر مليانة، والحصّادين بدّهم خبز طازة من قمحهم.",
               stations(("sageTea", "شاي بالميرميّة", "food_tea", "levantine", "drinks", "hot"),
                        ("wheat", "قمح", "food_wheat", "palestinian", "street"),
                        ("taboon", "خبز طابون", "food_flatbread", "palestinian", "bakery"),
                        ("maftoul", "مفتول", "food_steaming_bowl", "palestinian", "dishes")),
               ["tabounUmmIssa", "snackAlDayaa", "alTahouneh"], ["ppl_woman_farmer", "ppl_man_farmer", "food_stuffed_flatbread"],
               [hcase(1)], twists=[T("productionChain", inputStation="wheat", outputStation="taboon")]))
    L.append(C(27, "movingDay", "عزّال الجيران", "veh_truck", 48,
               "الجيران عزّلوا عالطابق الخامس وما في مصعد. أقلّ إشي نطعميهم!",
               stations(("falafelSandwich", "ساندويش فلافل", "food_sandwich", "palestinian", "street"),
                        ("watermelon", "بطّيخ بارد", "food_watermelon", "palestinian", "street", "cold"),
                        ("tea", "شاي", "food_tea", "levantine", "drinks", "hot")),
               ["snackAmmoSamir", "falafelAlaKeifak"], ["ppl_man", "food_falafel"],
               [cards(3, rarity="epic")], rules=["noUpgrades"]))
    L.append(C(28, "parkPicnic", "شوي بالحرش", "bld_national_park", 72,
               "طلعة الجمعة عالحرش: فحم ومشاوي وأولاد بيركضوا. بس ديروا بالكم عالغيم!",
               stations(("corn", "ذرة مشويّة", "food_corn", "levantine", "street"),
                        ("grill", "مشاوي", "food_meat_on_bone", "levantine", "grill"),
                        ("salad", "سلطة", "food_green_salad", "palestinian", "dishes", "cold"),
                        ("fireTea", "شاي عالحطب", "food_teapot", "levantine", "drinks", "hot")),
               ["awladAlAmm", "mashawiAlKheimeh", "kushkAlHabayeb"], ["food_meat_on_bone", "ppl_man_cook", "ppl_woman"],
               [hcase(1)],
               twists=[T("weatherSwing", hotProb=0.5, coldProb=0.1, rainProb=0.15,
                         hotDayStations=["salad", "corn"], coldDayStations=["fireTea"], rainDayStations=["fireTea"], mult=2.5)]))
    L.append(C(29, "hakawatiNight", "سهرة الحكواتي", "ui_speech_balloon", 72,
               "الحكواتي بالقهوة القديمة بيحكي عن الزير سالم، والسهّيرة بدّهم سحلب وكعك.",
               stations(("kaak", "كعك بسمسم", "food_bagel", "palestinian", "bakery"),
                        ("sahlab", "سحلب", "food_milk", "levantine", "drinks", "hot"),
                        ("harisseh", "هريسة", "food_shortcake", "levantine", "sweets"),
                        ("coffee", "قهوة سادة", "food_teapot", "gulf", "drinks", "hot")),
               ["qahwetAlMukhtar", "kaakAbuJamil", "shawarmaAlSahra"], ["ppl_older_person", "ppl_old_man", "food_tea"],
               [cards(1, rarity="legendary")], twists=[T("nightMarket", stations=[], startHour=20, endHour=1, nightMult=3)]))
    L.append(C(30, "sittiBirthday", "عيد ميلاد ستّي", "food_birthday_cake", 48,
               "ستّي صار عمرها تمانين، والعيلة كلها جاية مفاجأة. هِس! لا حدا يحكيلها.",
               stations(("kaakAjweh", "كعك بعجوة", "food_cookie", "palestinian", "bakery"),
                        ("maqluba", "مقلوبة", "food_maqluba_pan", "palestinian", "dishes"),
                        ("cake", "كيكة العيلة", "food_birthday_cake", "world", "sweets"),
                        ("mintTea", "شاي بالنعنع", "food_tea", "levantine", "drinks", "hot")),
               None, ["ppl_woman", "ppl_man", "ppl_girl", "ppl_beard"],
               [hcase(1)], rules=["goldenHour"],
               named=["عمّتك ريما", "خالك سليم", "بنت خالتك ديما", "جوز عمّتك أبو فادي"]))
    return {"version": 1,
            "schedule": {"epoch": "2026-01-05", "newWeekday": 2, "rerunWeekdays": [4, 6], "availabilityDays": 7,
                         "boardMax": 3, "rerunExclusionWeeks": 3},
            "slotsByLevel": [{"level": 14, "slots": 1}, {"level": 30, "slots": 2}],
            "partnerShareTotals": {"2": 0.30, "3": 0.40, "4": 0.50},
            "contracts": L}


# ---------------------------------------------------------------- events.json
def pal(a, b, c, d, e):
    return {"skyTop": a, "skyMid": b, "sunset": c, "glow": d, "accent": e}


def TH(id, name, art, palette, cash, tok, st, chef, deco, twists=(), festivalOnly=False, requires=None):
    t = {"id": id, "name": name, "art": art, "palette": palette,
         "eventCash": {"name": cash[0], "art": cash[1]}, "tokens": {"name": tok[0], "art": tok[1]},
         "stations": st, "twists": list(twists), "chefId": chef, "decorationId": deco,
         "festivalOnly": festivalOnly}
    if requires:
        t["requiresFestival"] = requires
    return t


def events():
    themes = [
        TH("haraWedding", "عرس بالحارة", "bld_wedding", pal("#3A1530", "#7A2E5A", "#E0607E", "#FFC2A8", "#FF8FB1"),
           ("مصاري العرس", "ui_money_bag"), ("ورود", "ui_bouquet"),
           stations(("mansaf", "منسف", "food_cooked_rice", "levantine", "dishes"),
                    ("knafeh", "كنافة", "food_pie", "palestinian", "sweets"),
                    ("juice", "عصير", "food_tropical_drink", "palestinian", "drinks", "cold"),
                    ("coffee", "قهوة سادة", "food_teapot", "gulf", "drinks", "hot")),
           "sittElSham", "lightsWedding"),
        TH("worldCupNight", "سهرة المونديال", "bld_stadium", pal("#0E2236", "#1E4D6B", "#3FA36B", "#B8F2C9", "#4CD07D"),
           ("مصاري السهرة", "ui_money_bag"), ("كاسات", "ui_trophy"),
           stations(("fries", "بطاطا", "food_french_fries", "world", "fried"),
                    ("sandwich", "سندويش", "food_sandwich", "world", "street"),
                    ("popcorn", "فشار", "food_popcorn", "world", "street"),
                    ("juice", "عصير", "food_juice_box", "world", "drinks", "cold")),
           "muratGrill", "lightsFlags", twists=[T("busWaves", intervalMin=15)]),
        TH("oliveHarvest", "موسم الزيتون", "food_olive", pal("#1E2A14", "#3E5A2A", "#B08A3A", "#F2D88A", "#8FB04A"),
           ("مصاري الموسم", "ui_money_bag"), ("زيتونات", "food_olive"),
           stations(("musakhan", "مسخّن", "food_stuffed_flatbread", "palestinian", "dishes"),
                    ("olives", "زيتون", "food_olive", "palestinian", "street"),
                    ("oilZaatar", "زيت وزعتر", "food_herb", "palestinian", "bakery"),
                    ("sageTea", "شاي بالميرميّة", "food_tea", "levantine", "drinks", "hot")),
           "abuAbedFul", "propOliveBasket",
           twists=[T("productionChain", inputStation="olives", outputStation="oilZaatar")], requires="oliveHarvest"),
        TH("schoolCanteen", "مقصف المدرسة", "bld_school", pal("#16263F", "#2F4F7A", "#E89A3C", "#FFE0A0", "#F2B33D"),
           ("مصروف", "ui_money_bag"), ("دفاتر", "ui_notebook"),
           stations(("manousheh", "منقوشة", "food_flatbread", "levantine", "bakery"),
                    ("falafelSandwich", "ساندويش فلافل", "food_sandwich", "palestinian", "street"),
                    ("cupcake", "كب كيك", "food_cupcake", "world", "sweets"),
                    ("juice", "عصير", "food_juice_box", "world", "drinks", "cold")),
           "laylaStudent", "signChalkboard"),
        TH("grapeFestival", "مهرجان العنب", "food_grapes", pal("#24122E", "#4E2A5E", "#B04A7A", "#F6C0D8", "#A45BC8"),
           ("مصاري الكرم", "ui_money_bag"), ("عناقيد", "food_grapes"),
           stations(("grapeJuice", "عصير عنب", "food_juice_box", "palestinian", "drinks", "cold"),
                    ("grapes", "عنب خليلي", "food_grapes", "palestinian", "street"),
                    ("dibs", "دبس", "food_honey", "palestinian", "sweets"),
                    ("malban", "ملبن", "food_candy", "palestinian", "sweets")),
           "abuSalimSweets", "propGrapevine",
           twists=[T("productionChain", inputStation="grapes", outputStation="dibs")]),
        TH("knafehFestival", "مهرجان الكنافة", "food_pie", pal("#2A1408", "#6A3416", "#E07A2E", "#FFD08A", "#F9B233"),
           ("مصاري الكنافة", "ui_money_bag"), ("صواني", "food_pie"),
           stations(("qatayef", "قطايف", "food_dumpling", "levantine", "sweets"),
                    ("awwameh", "عوّامة", "food_doughnut", "levantine", "sweets"),
                    ("knafeh", "كنافة نابلسيّة", "food_pie", "palestinian", "sweets"),
                    ("tea", "شاي", "food_tea", "levantine", "drinks", "hot")),
           "ozanBaklava", "goldTray", twists=[T("ovenTiming", station="knafeh", minCycleSec=2)]),
        TH("fridayFamily", "عزومة الجمعة", "food_fork_knife_plate", pal("#2E1A12", "#5E3A22", "#D08A4A", "#FFE2B0", "#E8A15A"),
           ("مصاري العيلة", "ui_money_bag"), ("صحون", "food_fork_knife_plate"),
           stations(("maqluba", "مقلوبة", "food_maqluba_pan", "palestinian", "dishes"),
                    ("salad", "سلطة", "food_green_salad", "palestinian", "dishes", "cold"),
                    ("laban", "لبن", "food_milk", "levantine", "drinks", "cold"),
                    ("tea", "شاي", "food_tea", "levantine", "drinks", "hot")),
           "hajjaUmmSubhi", "propFamilyTable"),
        TH("summerBeach", "صيفيّة عالبحر", "bld_beach_with_umbrella", pal("#0B3A5A", "#1E7AA8", "#FFB04A", "#FFE6A8", "#3EC6E0"),
           ("مصاري البحر", "ui_money_bag"), ("شموس", "ui_sun"),
           stations(("watermelon", "بطّيخ", "food_watermelon", "palestinian", "street", "cold"),
                    ("corn", "ذرة", "food_corn", "levantine", "street"),
                    ("iceCream", "بوظة", "food_ice_cream", "world", "sweets", "cold"),
                    ("lemonade", "ليموناضة", "food_lemon", "levantine", "drinks", "cold")),
           "khaledSea", "propBeachUmbrella",
           twists=[T("weatherSwing", hotProb=0.8, coldProb=0.0, rainProb=0.0,
                     hotDayStations=["watermelon", "iceCream", "lemonade"], mult=2.5)], requires="summer"),
        TH("falafelCup", "كاس الفلافل", "food_falafel", pal("#301A0C", "#6A3A16", "#D9714A", "#FFB36B", "#F9B233"),
           ("مصاري البطولة", "ui_money_bag"), ("أقراص ذهب", "food_falafel"),
           stations(("falafel", "فلافل", "food_falafel", "palestinian", "fried"),
                    ("pickles", "مخلّلات", "food_cucumber", "palestinian", "street"),
                    ("eggplant", "باذنجان مقلي", "food_eggplant", "palestinian", "fried"),
                    ("hummus", "حمّص", "food_hummus_bowl", "palestinian", "dishes")),
           "chefRami", "propFalafelCup", twists=[T("ovenTiming", station="eggplant", minCycleSec=2)]),
        TH("fishFestival", "مهرجان السمك", "ani_fish", pal("#0A2438", "#165A7A", "#E2834A", "#FFD2A0", "#2FB5C9"),
           ("مصاري الميناء", "ui_money_bag"), ("سمكات ذهب", "ani_fish"),
           stations(("fishSandwich", "ساندويش سمك", "food_sandwich", "palestinian", "seafood"),
                    ("shrimp", "قريدس مقلي", "food_fried_shrimp", "palestinian", "seafood"),
                    ("sayadiyeh", "صيّاديّة", "food_cooked_rice", "palestinian", "seafood"),
                    ("lemonMint", "ليمون بنعنع", "food_lemon", "levantine", "drinks", "cold")),
           "abuAliAlex", "propAnchor", twists=[T("portShipments", station="shrimp")]),
        TH("heritageVillage", "قرية التراث", "bld_hut", pal("#2A180E", "#5A3A1E", "#C27A3A", "#F6D2A2", "#C9A15A"),
           ("مصاري القرية", "ui_money_bag"), ("غرزات", "ui_hibiscus"),
           stations(("taboon", "خبز طابون", "food_flatbread", "palestinian", "bakery"),
                    ("labneh", "لبنة بزيت", "food_jar", "palestinian", "dishes"),
                    ("maftoul", "مفتول", "food_steaming_bowl", "palestinian", "dishes", "hot"),
                    ("zalabieh", "زلابية", "food_doughnut", "palestinian", "sweets")),
           "hajjaUmmSubhi", "propClayOven", twists=[T("busWaves", intervalMin=20, waveMult=4)]),
        TH("rooftopCinema", "سينما عالسطح", "ui_film_projector", pal("#0C0A1E", "#24204A", "#6A4AB0", "#C8B8FF", "#8F7BFF"),
           ("مصاري التذاكر", "ui_money_bag"), ("بكرات", "ui_clapper_board"),
           stations(("popcorn", "فشار", "food_popcorn", "world", "street"),
                    ("termos", "ترمس وبزر", "food_beans", "palestinian", "street"),
                    ("shawarma", "شاورما سهرة", "food_shawarma_wrap", "levantine", "street"),
                    ("nightCoffee", "قهوة ليل", "food_coffee", "world", "drinks", "hot")),
           "yukiStreet", "lightsCinema", twists=[T("nightMarket", stations=[], startHour=20, endHour=1, nightMult=3)]),
        # ---- festival-only ----
        TH("ramadanNights", "ليالي رمضان", "ui_crescent_moon", pal("#0E0F2E", "#2A2460", "#7A4AA0", "#FFD27A", "#FFC94A"),
           ("مصاري الخيمة", "ui_money_bag"), ("فوانيس", "ui_lantern"),
           stations(("qatayef", "قطايف", "food_dumpling", "levantine", "sweets"),
                    ("jallab", "جلّاب", "food_cup_with_straw", "levantine", "drinks", "cold"),
                    ("lentilSoup", "شوربة عدس", "food_steaming_bowl", "levantine", "dishes", "hot"),
                    ("milkDates", "حليب وتمر", "food_milk", "gulf", "drinks")),
           "reemCoffee", "propCrescent",
           twists=[T("nightMarket", stations=[], startHour=18, endHour=3, nightMult=3)], festivalOnly=True, requires="ramadan"),
        TH("eidSweets", "حلو العيد", "food_cookie", pal("#2A0E26", "#5E2252", "#E0609A", "#FFD0E4", "#FFB0D0"),
           ("عيديّة", "ui_money_bag"), ("عيديّات", "ui_envelope"),
           stations(("kaakEid", "كعك العيد", "food_cookie", "palestinian", "bakery"),
                    ("maamoul", "معمول", "food_moon_cake", "palestinian", "sweets"),
                    ("coffee", "قهوة سادة", "food_teapot", "gulf", "drinks", "hot"),
                    ("chocolate", "شوكولاتة", "food_chocolate_bar", "world", "sweets")),
           "monaSweets", "lightsEidBalloons", festivalOnly=True, requires="eidFitr"),
        TH("eidFeast", "عزومة الأضحى", "ani_sheep", pal("#1A1E0E", "#3E4A1E", "#C8923A", "#FFE2A0", "#E2B04A"),
           ("مصاري العزومة", "ui_money_bag"), ("خواريف", "ani_sheep"),
           stations(("fatteh", "فتّة", "food_steaming_bowl", "palestinian", "dishes"),
                    ("grill", "مشاوي", "food_meat_on_bone", "levantine", "grill"),
                    ("riceMeat", "رز ولحمة", "food_cooked_rice", "palestinian", "dishes"),
                    ("laban", "لبن", "food_milk", "levantine", "drinks", "cold")),
           "hassanGrill", "lightsEid", festivalOnly=True, requires="eidAdha"),
        TH("bethlehemChristmas", "ميلاد بيت لحم", "ui_glowing_star", pal("#0E1430", "#1E2A5E", "#B0567A", "#FFE38A", "#FFD24A"),
           ("مصاري السوق", "ui_money_bag"), ("نجوم", "ui_glowing_star"),
           stations(("chestnut", "كستنا", "food_chestnut", "palestinian", "street", "hot"),
                    ("sahlab", "سحلب", "food_milk", "levantine", "drinks", "hot"),
                    ("kaak", "كعك", "food_cookie", "palestinian", "bakery"),
                    ("hotChocolate", "شوكولاتة سخنة", "food_coffee", "world", "drinks", "hot")),
           "ummMohammad", "propNativityStar", twists=[T("busWaves", intervalMin=20)],
           festivalOnly=True, requires="bethlehemChristmas"),
    ]
    milestones = [
        {"base": 1e4, "rewards": [tokens(20)]},
        {"base": 1e6, "rewards": [tokens(20), gold(5)]},
        {"base": 1e8, "rewards": [tokens(30), chest("wood")], "unlocksStation": 3},
        {"base": 3e9, "rewards": [tokens(30), gold(5)]},
        {"base": 5e10, "rewards": [tokens(40), cards(3, id="themeChef")]},
        {"base": 3e11, "rewards": [tokens(40), gold(10)]},
        {"base": 1e12, "rewards": [tokens(40), chest("silver")]},
        {"base": 3e12, "rewards": [tokens(30), gold(10), hcase(1)]},
        {"base": 8e12, "rewards": [tokens(30), gold(10)]},
        # "themeDecoration" = the running theme's decorationId (sentinel, like chefCards "themeChef").
        {"base": 1.5e13, "rewards": [tokens(20), chest("gold"), cosmetic("themeDecoration")]},
    ]
    return {
        "version": 1,
        "startWeekday": 5, "durationHours": 96,
        "rotation": ["haraWedding", "worldCupNight", "oliveHarvest", "schoolCanteen", "grapeFestival",
                     "knafehFestival", "fridayFamily", "summerBeach", "falafelCup", "fishFestival",
                     "heritageVillage", "rooftopCinema"],
        "festivalOverrides": [
            {"festivalId": "ramadan", "themeId": "ramadanNights"},
            {"festivalId": "eidFitr", "themeId": "eidSweets"},
            {"festivalId": "eidAdha", "themeId": "eidFeast"},
            {"festivalId": "oliveHarvest", "themeId": "oliveHarvest"},
            {"festivalId": "bethlehemChristmas", "themeId": "bethlehemChristmas"},
            {"festivalId": "summer", "themeId": "summerBeach"},
        ],
        "milestones": milestones,
        "rankRewards": [
            {"fromRank": 1, "toRank": 1, "rewards": [chest("gold"), cosmetic("frameFestivalChampion")]},
            {"fromRank": 2, "toRank": 3, "rewards": [chest("silver")]},
            {"fromRank": 4, "toRank": 10, "rewards": [chest("wood")]},
            {"fromRank": 11, "toRank": 21, "rewards": [cards(3, rarity="rare")]},
        ],
        "npcCount": 20, "npcSigma": 0.6,
        "tokenConversion": {"tokensPerGold": 5, "maxGold": 20},
        "shop": [
            {"id": "themeCards", "reward": cards(3, id="themeChef"), "price": 40, "max": 5},
            {"id": "epicCard", "reward": cards(1, rarity="epic"), "price": 60, "max": 3},
            {"id": "timeWarp", "reward": warp(60), "price": 30, "max": 3},
            {"id": "woodChest", "reward": chest("wood"), "price": 50, "max": 2},
            {"id": "heritageCase", "reward": hcase(1), "price": 120, "max": 1},
            {"id": "decoration", "reward": cosmetic("themeDecoration"), "price": 150, "max": 1},
            {"id": "ticket", "reward": tickets(1), "price": 15, "max": 3},
        ],
        "themes": themes,
    }


def main():
    for name, fn in [("league.json", league), ("contracts.json", contracts), ("events.json", events)]:
        print("wrote", write_json(name, fn()))


if __name__ == "__main__":
    main()
