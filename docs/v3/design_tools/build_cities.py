#!/usr/bin/env python3
"""Builds content/cities.json and content/story.json for بسطة فلافل v3.

Economy numbers follow GDD 2.2-2.8 and 3.1-3.4 (finalGoalBase, priceScale, licences,
caps, cash-upgrade ladder, goal template). Arabic content is authored inline below.
Run:  python3 build_cities.py   (writes ../content/cities.json and ../content/story.json)
"""
import json, math, os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), "content")

# ---------------------------------------------------------------- helpers
def sig3(x):
    return float(f"{x:.3g}")

def gt(m, f=None):
    """GText: plain string when both forms are equal."""
    if f is None or f == m:
        return m
    return {"m": m, "f": f}

VERB_F = {
    "افتح": "افتحي", "كبّر": "كبّري", "وظّف": "وظّفي", "اربح": "اربحي", "اجمع": "اجمعي",
    "اشتري": "اشتري", "استقبل": "استقبلي", "طلّع": "طلّعي", "اعصر": "اعصري", "حوّل": "حوّلي",
    "اطحن": "اطحني", "حمّل": "حمّلي", "وصّل": "وصّلي", "خدّم": "خدّمي", "حطّ": "حطّي",
    "بلّش": "بلّشي", "خلّص": "خلّصي", "ابعت": "ابعتي", "استلم": "استلمي", "حقّق": "حقّقي",
    "جمّع": "جمّعي", "اكسب": "اكسبي", "العب": "العبي", "جاوب": "جاوبي",
}

def gv(verb, rest, prefix=""):
    return gt(f"{prefix}{verb} {rest}", f"{prefix}{VERB_F[verb]} {rest}")

TIER_CYCLE = [1, 3, 6, 12, 24, 96, 384, 1536]
LICENCE = {1: 0, 2: 0, 3: 0, 4: 1, 5: 2, 6: 4, 7: 8, 8: 12}

def licence_hours(i):
    return LICENCE.get(i, 24 if i <= 16 else 36)

def level_cap(i):
    return 100 if i <= 3 else 200 if i <= 8 else 300 if i <= 16 else 400

CUISINE = {"pal": "palestinian", "lev": "levantine", "egy": "egyptian", "gulf": "gulf",
           "irq": "iraqi", "mag": "maghrebi", "tur": "turkish", "wld": "world"}

# ---------------------------------------------------------------- city data
# station row: key | name | definite form (for goal texts) | art | cuisine | category | weather | managerName | managerArt
def st(s):
    k, name, d, art, cu, cat, w, mn, ma = [x.strip() for x in s.split("|")]
    return dict(key=k, name=name, defn=d, art=art, cuisine=CUISINE[cu], category=cat,
                weather=w, managerName=mn, managerArt=ma)

def ing(s):
    k, name, art = [x.strip() for x in s.split("|")]
    return {"key": k, "name": name, "art": art}

CITIES = [
 dict(id="jerusalem", name="القدس", region="palestine", log10F=10.5, S=1,
      currency=("جنيه فلسطيني", "ج.ف", "ui_dollar"), cur="جنيه",
      landmark="bld_mosque", decor=["ui_lantern", "bld_potted_plant", "food_bagel"],
      palette=("#33172E", "#6E2F4A", "#D9714A", "#FFB36B", "#F9B233"), silhouette="oldCity",
      rival=("أبو شاكر", "ppl_man_cook"), customers=["ppl_older_person", "ppl_woman_headscarf", "ppl_child"],
      stations=[st(x) for x in [
        "falafel | فلافل | الفلافل | food_falafel | pal | fried | none | أبو سمير القلّاي | ppl_man_cook",
        "hummus | حمّص | الحمّص | food_hummus_bowl | pal | dishes | none | أبو حسن الحمّصاني | ppl_older_person",
        "tea | شاي بالنعنع | الشاي بالنعنع | food_tea | lev | drinks | hot | أم جميل | ppl_woman_headscarf",
        "kaak | كعك القدس | كعك القدس | food_bagel | pal | bakery | none | أبو صلاح الكعكاتي | ppl_beard",
        "ful | فول مدمّس | الفول المدمّس | food_beans | pal | dishes | hot | أبو فوزي الفوّال | ppl_old_man",
        "maqluba | مقلوبة | المقلوبة | food_maqluba_pan | pal | dishes | none | أم خالد | ppl_woman_cook"]],
      twists=[],
      rush=(["bread | خبز | food_flatbread", "kaak | كعك | food_bagel"],
            ["falafel | فلافل | food_falafel", "hummus | حمّص | food_hummus_bowl", "tomato | بندورة | food_tomato",
             "cucumber | خيار | food_cucumber", "parsley | بقدونس | food_leafy_green", "chili | شطّة | food_hot_pepper"])),

 dict(id="bethlehem", name="بيت لحم", region="palestine", log10F=11.3, S=1,
      currency=("جنيه فلسطيني", "ج.ف", "ui_dollar"), cur="جنيه",
      landmark="bld_night_with_stars", decor=["ui_glowing_star", "ui_candle", "food_chestnut"],
      palette=("#1B1A3A", "#3E2D63", "#B0567A", "#FFD27A", "#FFE38A"), silhouette="hills",
      rival=("الخواجة جريس", "ppl_beard"), customers=["ppl_person_tipping_hand", "ppl_woman", "ppl_beard"],
      stations=[st(x) for x in [
        "chestnut | كستنا مشويّة | الكستنا المشويّة | food_chestnut | pal | street | hot | حنّا الكستناوي | ppl_man",
        "lentilSoup | شوربة عدس | شوربة العدس | food_steaming_bowl | pal | dishes | hot | أم إلياس | ppl_woman_cook",
        "musakhanRolls | مسخّن رولات | المسخّن رولات | food_stuffed_flatbread | pal | bakery | none | أم سليمان | ppl_woman_headscarf",
        "sahlab | سحلب | السحلب | food_milk | lev | drinks | hot | أبو نقولا | ppl_older_person",
        "spinachPies | فطاير سبانخ | فطاير السبانخ | food_dumpling | lev | bakery | none | مريم الخبّازة | ppl_woman",
        "maamoul | معمول بالجوز | المعمول بالجوز | food_moon_cake | pal | sweets | none | بشارة الحلواني | ppl_man_cook"]],
      twists=[{"type": "busWaves", "params": {"intervalMin": 20, "windowSec": 30, "waveMult": 4, "waveSec": 60, "stations": []}}],
      rush=(["taboon | طابون | food_flatbread", "saj | صاج | food_stuffed_flatbread"],
            ["chicken | دجاج | food_poultry_leg", "onion | بصل | food_onion", "sumac | سمّاق | food_herb",
             "olives | زيتون | food_olive", "spinach | سبانخ | food_leafy_green", "lemon | ليمون | food_lemon"])),

 dict(id="nablus", name="نابلس", region="palestine", log10F=12.2, S=1,
      currency=("جنيه فلسطيني", "ج.ف", "ui_dollar"), cur="جنيه",
      landmark="bld_mountain", decor=["food_pie", "food_olive", "bld_deciduous_tree"],
      palette=("#2A1A12", "#5E3420", "#C8693A", "#FFC37A", "#E07A2E"), silhouette="mountains",
      rival=("أبو حمدي الكنفاني", "ppl_older_person"), customers=["ppl_old_man", "ppl_man_farmer"],
      stations=[st(x) for x in [
        "taboon | خبز طابون | خبز الطابون | food_flatbread | pal | bakery | none | أم صالح | ppl_woman_headscarf",
        "nabulsiCheese | جبنة نابلسيّة | الجبنة النابلسيّة | food_cheese | pal | dishes | none | أبو ماهر الجبّان | ppl_man_farmer",
        "olives | زيتون مكبوس | الزيتون المكبوس | food_olive | pal | dishes | none | الحاج أبو رائد | ppl_old_man",
        "awwameh | عوّامة | العوّامة | food_doughnut | lev | sweets | none | مهنّد | ppl_man_cook",
        "qatayef | قطايف | القطايف | food_dumpling | lev | sweets | none | أبو رمضان | ppl_beard",
        "halawa | حلاوة طحينيّة | الحلاوة الطحينيّة | food_cookie | lev | sweets | none | أبو نبيل الحلاوجي | ppl_older_person",
        "knafeh | كنافة نابلسيّة | الكنافة النابلسيّة | food_pie | pal | sweets | none | المعلّم أبو أنس | ppl_man_cook"]],
      twists=[{"type": "ovenTiming", "params": {"station": "knafeh", "windowSec": 1.6, "perfectMult": 3, "minCycleSec": 2}}],
      rush=(["kaak | كعك | food_bagel", "taboon | طابون | food_flatbread"],
            ["cheese | جبنة | food_cheese", "zaatar | زعتر | food_herb", "olives | زيتون | food_olive",
             "egg | بيض | food_egg", "tomato | بندورة | food_tomato", "honey | عسل | food_honey"])),

 dict(id="hebron", name="الخليل", region="palestine", log10F=13.0, S=1,
      currency=("جنيه فلسطيني", "ج.ف", "ui_dollar"), cur="جنيه",
      landmark="bld_houses", decor=["food_grapes", "ui_crystal_ball", "food_jar"],
      palette=("#2B1630", "#5A2B57", "#A85A7C", "#F2B5A0", "#7B3F8C"), silhouette="hills",
      rival=("أبو العز", "ppl_man_farmer"), customers=["ppl_farmer", "ppl_woman_farmer"],
      stations=[st(x) for x in [
        "dateKaak | كعك بعجوة | كعك العجوة | food_cookie | pal | bakery | none | أم محمود | ppl_woman_headscarf",
        "grapes | عنب خليلي | العنب الخليلي | food_grapes | pal | street | cold | أبو راتب الكرّام | ppl_man_farmer",
        "dibs | دبس عنب | دبس العنب | food_honey | pal | sweets | none | الحاج أبو خضر | ppl_old_man",
        "malban | ملبن | الملبن | food_candy | pal | sweets | none | أبو نادر | ppl_beard",
        "qidra | قدرة خليليّة | القدرة الخليليّة | food_pot | pal | dishes | hot | أم وليد | ppl_woman_cook",
        "mashawi | مشاوي خليليّة | المشاوي الخليليّة | food_meat_on_bone | pal | grill | none | أبو هاني الشوّا | ppl_man_cook",
        "qahwa | قهوة سادة | القهوة السادة | food_coffee | lev | drinks | hot | أبو عوني | ppl_older_person"]],
      twists=[{"type": "productionChain", "params": {"inputStation": "grapes", "outputStation": "dibs", "ratio": 1, "outputMult": 3, "stockCapMin": 60}}],
      rush=(["saj | صاج | food_stuffed_flatbread", "bread | خبز | food_bread"],
            ["meat | لحمة | food_cut_of_meat", "onion | بصل | food_onion", "grapes | عنب | food_grapes",
             "dibs | دبس | food_honey", "walnuts | جوز | food_peanuts", "tomato | بندورة | food_tomato"])),

 dict(id="jaffa", name="يافا", region="palestine", log10F=13.7, S=1,
      currency=("جنيه فلسطيني", "ج.ف", "ui_dollar"), cur="جنيه",
      landmark="bld_sunset", decor=["food_tangerine", "veh_sailboat", "veh_anchor"],
      palette=("#12324A", "#2E6E8E", "#F08A24", "#FFD08A", "#F08A24"), silhouette="coast",
      rival=("أم يوسف", "ppl_woman"), customers=["ppl_guard", "ppl_man"],
      stations=[st(x) for x in [
        "oranges | برتقال يافاوي | البرتقال اليافاوي | food_tangerine | pal | street | cold | أبو فريد البيّاراتي | ppl_man_farmer",
        "orangeJuice | عصير برتقال | عصير البرتقال | food_tropical_drink | pal | drinks | cold | نور | ppl_woman",
        "friedFish | سمك مقلي | السمك المقلي | ani_fish | pal | seafood | none | البحّار أبو صابر | ppl_old_man",
        "shrimp | قريدس مقلي | القريدس المقلي | food_fried_shrimp | pal | seafood | none | وسيم | ppl_man",
        "sayadieh | صيّاديّة | الصيّاديّة | food_cooked_rice | pal | seafood | none | أم ناصر | ppl_woman_cook",
        "jaffaSalad | سلطة يافاويّة | السلطة اليافاويّة | food_green_salad | pal | dishes | none | رنا | ppl_woman_headscarf",
        "seaIceCream | بوظة عالبحر | بوظة البحر | food_ice_cream | wld | sweets | cold | أبو شادي البوظجي | ppl_man_cook"]],
      twists=[{"type": "portShipments", "params": {"station": "oranges", "intervalHours": 4, "dockHours": 3, "targetMin": 30, "rewardMin": 90, "offlineRewardFrac": 0.5}}],
      rush=(["bread | خبز | food_bread", "kaak | كعك | food_bagel"],
            ["fish | سمك | ani_fish", "shrimp | قريدس | food_fried_shrimp", "lemon | ليمون | food_lemon",
             "tomato | بندورة | food_tomato", "chili | شطّة | food_hot_pepper", "orange | برتقال | food_tangerine"])),

 dict(id="haifa", name="حيفا", region="palestine", log10F=14.1, S=1.1,
      currency=("جنيه فلسطيني", "ج.ف", "ui_dollar"), cur="جنيه",
      landmark="bld_sunrise_over_mountains", decor=["veh_scooter", "bld_deciduous_tree", "food_coffee"],
      palette=("#102A3A", "#1F5C6E", "#5FA8A0", "#FFE1A8", "#2F8F86"), silhouette="coast",
      rival=("نزار الشاورماتي", "ppl_man"), customers=["ppl_technologist", "ppl_mechanic"],
      stations=[st(x) for x in [
        "shawarma | شاورما | الشاورما | food_shawarma_wrap | lev | street | none | أبو أمين الشاورماتي | ppl_man_cook",
        "fries | بطاطا مقليّة | البطاطا المقليّة | food_french_fries | wld | fried | none | جاد | ppl_boy",
        "kibbeh | كبّة مقليّة | الكبّة المقليّة | food_roasted_sweet_potato | lev | fried | none | أم رياض | ppl_woman_cook",
        "corn | ذرة مشويّة | الذرة المشويّة | food_corn | lev | street | none | عمّو نعيم | ppl_old_man",
        "manakish | مناقيش زعتر | مناقيش الزعتر | food_flatbread | lev | bakery | none | أم فادي | ppl_woman_headscarf",
        "carmelCoffee | قهوة الكرمل | قهوة الكرمل | food_coffee | lev | drinks | hot | إيلي | ppl_man",
        "muhallabia | مهلبيّة | المهلبيّة | food_custard | lev | sweets | cold | ست وداد | ppl_older_person"]],
      twists=[{"type": "deliveryRuns", "params": {"intervalMin": 10, "tripMin": 6, "rewardMin": 8, "scooters": 2, "queueMax": 5,
               "extraScooterCostsBase": "F*[1e-6,1e-4,1e-2]", "dispatcherCostBase": "F*1e-5", "offlineRewardFrac": 0.5, "rainMult": 1.5}}],
      rush=(["saj | صاج | food_stuffed_flatbread", "bread | خبز | food_bread"],
            ["shawarma | شاورما | food_shawarma_wrap", "fries | بطاطا | food_french_fries", "garlic | ثوم | food_garlic",
             "pickles | مخلّل | food_cucumber", "tomato | بندورة | food_tomato", "onion | بصل | food_onion"])),

 dict(id="gaza", name="غزّة", region="palestine", log10F=14.5, S=1.4,
      currency=("جنيه فلسطيني", "ج.ف", "ui_dollar"), cur="جنيه",
      landmark="bld_beach_with_umbrella", decor=["food_watermelon", "veh_sailboat", "ui_sun"],
      palette=("#0E2F4F", "#1D6FA3", "#F3A65A", "#FFE7B8", "#1D9BD1"), silhouette="coast",
      rival=("أبو رامي الصيّاد", "ppl_old_man"), customers=["ppl_child", "ppl_boy", "ppl_girl"],
      stations=[st(x) for x in [
        "dagga | دقّة غزّاويّة | الدقّة الغزّاويّة | food_hot_pepper | pal | street | none | أم العبد | ppl_woman_headscarf",
        "sumagiyya | سمّاقيّة | السمّاقيّة | food_steaming_bowl | pal | dishes | hot | الحاجّة أم رشاد | ppl_old_woman",
        "grilledFish | سمك مشوي | السمك المشوي | ani_fish | pal | seafood | none | أبو بلال الصيّاد | ppl_man_farmer",
        "zibdiyya | زبديّة قريدس | زبديّة القريدس | food_pot | pal | seafood | hot | أم تامر | ppl_woman_cook",
        "watermelon | بطّيخ | البطّيخ | food_watermelon | pal | street | cold | أبو عادل البطّيخاتي | ppl_older_person",
        "lemonMint | ليمون ونعنع | الليمون بالنعنع | food_lemon | pal | drinks | cold | مؤمن | ppl_boy",
        "beachIceCream | بوظة بالقرطاس | البوظة بالقرطاس | food_soft_ice_cream | wld | sweets | cold | سما | ppl_girl"]],
      twists=[{"type": "weatherSwing", "params": {"hotProb": 0.45, "coldProb": 0.15, "rainProb": 0.10,
               "hotDayStations": ["watermelon", "lemonMint", "beachIceCream"], "coldDayStations": ["sumagiyya", "zibdiyya"],
               "rainDayStations": [], "mult": 2.5}}],
      rush=(["bread | خبز | food_bread", "taboon | طابون | food_flatbread"],
            ["fish | سمك | ani_fish", "shrimp | قريدس | food_fried_shrimp", "chili | شطّة | food_hot_pepper",
             "garlic | ثوم | food_garlic", "lemon | ليمون | food_lemon", "tomato | بندورة | food_tomato"])),

 dict(id="ramallah", name="رام الله", region="palestine", log10F=14.8, S=1.7,
      currency=("جنيه فلسطيني", "ج.ف", "ui_dollar"), cur="جنيه",
      landmark="bld_cityscape", decor=["ui_musical_notes", "ui_balloon", "food_sandwich"],
      palette=("#1A1433", "#3A2A6B", "#E0567A", "#FFC1A1", "#E0567A"), silhouette="towers",
      rival=("سلمى", "ppl_woman_office"), customers=["ppl_person_raising_hand", "ppl_artist", "ppl_office"],
      stations=[st(x) for x in [
        "falafelSandwich | ساندويش فلافل | ساندويش الفلافل | food_sandwich | pal | street | none | أبو إسكندر | ppl_man_cook",
        "pizza | بيتزا | البيتزا | food_pizza | wld | bakery | none | طارق | ppl_man",
        "shawarmaPlate | صحن شاورما | صحن الشاورما | food_fork_knife_plate | lev | street | none | أبو إلياس | ppl_beard",
        "burger | برغر | البرغر | food_hamburger | wld | fried | none | عمر | ppl_technologist",
        "cappuccino | كابتشينو | الكابتشينو | food_coffee | wld | drinks | hot | دينا | ppl_woman_office",
        "knafehCup | كنافة بالكاسة | الكنافة بالكاسة | food_custard | pal | sweets | none | أبو سامح | ppl_older_person",
        "sous | عرق سوس | عرق السوس | food_cup_with_straw | lev | drinks | cold | العمّ أبو صخر | ppl_old_man"]],
      twists=[{"type": "nightMarket", "params": {"stations": ["shawarmaPlate", "cappuccino", "knafehCup"], "startHour": 20, "endHour": 2, "nightMult": 3}}],
      rush=(["bread | خبز | food_bread", "saj | صاج | food_stuffed_flatbread"],
            ["falafel | فلافل | food_falafel", "fries | بطاطا | food_french_fries", "hummus | حمّص | food_hummus_bowl",
             "cucumber | خيار | food_cucumber", "tomato | بندورة | food_tomato", "chili | شطّة | food_hot_pepper"])),

 dict(id="amman", name="عمّان", region="arab", log10F=15.1, S=2.2,
      currency=("دينار أردني", "د.أ", "ui_money_bag"), cur="دينار",
      landmark="bld_castle", decor=["bld_wedding", "food_teapot", "ui_lantern"],
      palette=("#2D1E14", "#6B4A2E", "#C98B4A", "#F6D9A8", "#B5651D"), silhouette="hills",
      rival=("أبو عودة", "ppl_turban"), customers=["ppl_turban", "ppl_man_office"],
      stations=[st(x) for x in [
        "downtownFalafel | فلافل وسط البلد | فلافل وسط البلد | food_falafel | lev | fried | none | أبو زيد | ppl_man_cook",
        "milk | حليب طازة | الحليب الطازة | food_milk | lev | dishes | none | أم عطا | ppl_woman_farmer",
        "jameed | جميد كركي | الجميد الكركي | food_cheese | lev | dishes | none | أبو مفلح | ppl_man_farmer",
        "knafehNaama | كنافة ناعمة | الكنافة الناعمة | food_pie | lev | sweets | none | أبو بشّار | ppl_man_cook",
        "mansaf | منسف | المنسف | food_cooked_rice | lev | dishes | hot | أبو عوّاد | ppl_turban",
        "zarb | زرب | الزرب | food_meat_on_bone | lev | grill | none | أبو نايف | ppl_beard",
        "arabicCoffee | قهوة عربيّة | القهوة العربيّة | food_teapot | gulf | drinks | hot | أبو فارس القهوجي | ppl_older_person",
        "hareeseh | هريسة | الهريسة | food_shortcake | lev | sweets | none | أم عصام | ppl_woman_headscarf"]],
      twists=[{"type": "productionChain", "params": {"inputStation": "milk", "outputStation": "jameed", "ratio": 1, "outputMult": 2, "stockCapMin": 60}},
              {"type": "productionChain", "params": {"inputStation": "jameed", "outputStation": "mansaf", "ratio": 1, "outputMult": 3, "stockCapMin": 60}}],
      rush=(["shrak | شراك | food_flatbread", "bread | خبز | food_bread"],
            ["meat | لحمة | food_cut_of_meat", "rice | رز | food_cooked_rice", "jameed | جميد | food_cheese",
             "almonds | لوز | food_peanuts", "onion | بصل | food_onion", "parsley | بقدونس | food_leafy_green"])),

 dict(id="beirut", name="بيروت", region="arab", log10F=15.25, S=2.8,
      currency=("ليرة لبنانيّة", "ل.ل", "ui_money_bag"), cur="ليرة",
      landmark="bld_cityscape_at_dusk", decor=["ui_musical_notes", "veh_sailboat", "food_lemon"],
      palette=("#0F2238", "#24507A", "#E86A5C", "#FFD6A5", "#E86A5C"), silhouette="coast",
      rival=("طوني", "ppl_man_cook"), customers=["ppl_singer", "ppl_artist"],
      stations=[st(x) for x in [
        "manoushe | منقوشة زعتر | منقوشة الزعتر | food_flatbread | lev | bakery | none | أم شربل | ppl_woman_cook",
        "kaakBeiruti | كعكة بيروتيّة | الكعكة البيروتيّة | food_pretzel | lev | bakery | none | أبو وليد | ppl_old_man",
        "tabbouleh | تبّولة | التبّولة | food_green_salad | lev | dishes | cold | تيتا هيام | ppl_old_woman",
        "shishTawook | شيش طاووق | الشيش طاووق | food_poultry_leg | lev | grill | none | جورج | ppl_man_cook",
        "fattoush | فتّوش | الفتّوش | food_leafy_green | lev | dishes | none | ميرنا | ppl_woman",
        "sfiha | صفيحة | الصفيحة | food_pizza | lev | bakery | none | أبو رامز | ppl_beard",
        "lemonade | ليموناضة | الليموناضة | food_lemon | lev | drinks | cold | زياد | ppl_boy",
        "halawetJibn | حلاوة الجبن | حلاوة الجبن | food_custard | lev | sweets | none | أبو مارون | ppl_older_person"]],
      twists=[{"type": "nightMarket", "params": {"stations": ["shishTawook", "sfiha", "lemonade", "halawetJibn"], "startHour": 21, "endHour": 3, "nightMult": 3}}],
      rush=(["saj | صاج | food_stuffed_flatbread", "bread | خبز | food_bread"],
            ["chicken | دجاج | food_poultry_leg", "garlic | ثوم | food_garlic", "fries | بطاطا | food_french_fries",
             "pickles | مخلّل | food_cucumber", "tomato | بندورة | food_tomato", "mint | نعنع | food_herb"])),

 dict(id="damascus", name="دمشق", region="arab", log10F=15.4, S=3.5,
      currency=("ليرة سوريّة", "ل.س", "ui_money_bag"), cur="ليرة",
      landmark="bld_fountain", decor=["ui_lantern", "ui_hibiscus", "food_ice_cream"],
      palette=("#1E2A1A", "#3E5A2E", "#C9A23A", "#F8E7A1", "#3E8E5A"), silhouette="minarets",
      rival=("أبو صيّاح", "ppl_old_man"), customers=["ppl_older_person", "ppl_woman_headscarf"],
      stations=[st(x) for x in [
        "msabbaha | مسبّحة | المسبّحة | food_hummus_bowl | lev | dishes | none | أبو حسين | ppl_man_cook",
        "warakEnab | ورق عنب | ورق العنب | food_leafy_green | lev | dishes | none | أم بشير | ppl_woman_headscarf",
        "kebabHalabi | كباب حلبي | الكباب الحلبي | food_meat_on_bone | lev | grill | none | أبو عبدو | ppl_beard",
        "fatteh | فتّة | الفتّة | food_steaming_bowl | lev | dishes | hot | أبو مصطفى | ppl_older_person",
        "maarouk | خبز معروك | المعروك | food_bread | lev | bakery | none | أبو ياسين | ppl_man",
        "qamarDeen | قمر الدين | قمر الدين | food_juice_box | lev | drinks | cold | رزان | ppl_woman",
        "pistachioIceCream | بوظة بالفستق | البوظة بالفستق | food_ice_cream | lev | sweets | cold | أبو كمال | ppl_man_cook",
        "baklava | بقلاوة شاميّة | البقلاوة الشاميّة | food_pie | lev | sweets | none | المعلّم أبو صطيف | ppl_old_man"]],
      twists=[{"type": "busWaves", "params": {"intervalMin": 15, "windowSec": 30, "waveMult": 4, "waveSec": 75, "stations": []}}],
      rush=(["bread | خبز | food_bread", "saj | صاج | food_stuffed_flatbread"],
            ["meat | لحمة | food_cut_of_meat", "hummus | حمّص | food_hummus_bowl", "parsley | بقدونس | food_leafy_green",
             "onion | بصل | food_onion", "walnuts | جوز | food_peanuts", "tomato | بندورة | food_tomato"])),

 dict(id="cairo", name="القاهرة", region="arab", log10F=15.6, S=4.4,
      currency=("جنيه مصري", "ج.م", "ui_pound"), cur="جنيه",
      landmark="bld_desert", decor=["veh_bicycle", "ui_lantern", "bld_palm_tree"],
      palette=("#2E2410", "#6E5420", "#D9A441", "#FFE6A1", "#D9A441"), silhouette="desert",
      rival=("عم صابر", "ppl_older_person"), customers=["ppl_beard", "ppl_old_man"],
      stations=[st(x) for x in [
        "taameya | طعميّة | الطعميّة | food_falafel | egy | fried | none | عم مدحت | ppl_man_cook",
        "koshari | كشري | الكشري | food_spaghetti | egy | dishes | none | الحاج سيّد | ppl_older_person",
        "fulMasri | فول مصري | الفول المصري | food_beans | egy | dishes | hot | عم فتحي | ppl_old_man",
        "hawawshi | حواوشي | الحواوشي | food_stuffed_flatbread | egy | street | none | شريف | ppl_man",
        "feteer | فطير مشلتت | الفطير المشلتت | food_pancakes | egy | bakery | none | الست أم هاني | ppl_woman_headscarf",
        "sugarcane | عصير قصب | عصير القصب | food_cup_with_straw | egy | drinks | cold | عبده | ppl_boy",
        "basbousa | بسبوسة | البسبوسة | food_shortcake | egy | sweets | none | الست زينب | ppl_woman_cook",
        "omAli | أم علي | أم علي | food_custard | egy | sweets | hot | الست نعمات | ppl_old_woman"]],
      twists=[{"type": "deliveryRuns", "params": {"intervalMin": 8, "tripMin": 5, "rewardMin": 8, "scooters": 3, "queueMax": 5,
               "extraScooterCostsBase": "F*[1e-6,1e-4,1e-2]", "dispatcherCostBase": "F*1e-5", "offlineRewardFrac": 0.5, "rainMult": 1.5}}],
      rush=(["baladi | عيش بلدي | food_flatbread", "fino | فينو | food_baguette"],
            ["taameya | طعميّة | food_falafel", "ful | فول | food_beans", "egg | بيض | food_egg",
             "tahini | طحينة | food_jar", "tomato | طماطم | food_tomato", "chili | شطّة | food_hot_pepper"])),

 dict(id="baghdad", name="بغداد", region="arab", log10F=15.7, S=5.8,
      currency=("دينار عراقي", "د.ع", "ui_money_bag"), cur="دينار",
      landmark="bld_palm_tree", decor=["ui_books", "veh_motor_boat", "ani_fish"],
      palette=("#1A2430", "#2F4A5E", "#C77D3A", "#F5D3A0", "#2F7F9E"), silhouette="minarets",
      rival=("أبو جاسم", "ppl_man"), customers=["ppl_teacher", "ppl_man"],
      stations=[st(x) for x in [
        "iraqiChai | شاي عراقي | الشاي العراقي | food_tea | irq | drinks | hot | أبو حيدر | ppl_older_person",
        "tikka | تكّة | التكّة | food_cut_of_meat | irq | grill | none | أبو كرّار | ppl_man_cook",
        "dolma | دولمة | الدولمة | food_leafy_green | irq | dishes | none | أم زينب | ppl_woman_headscarf",
        "kahi | كاهي وقيمر | الكاهي والقيمر | food_pancakes | irq | bakery | none | أبو سلام | ppl_beard",
        "masgouf | مسكوف | المسكوف | ani_fish | irq | seafood | none | الحاج أبو رعد | ppl_man_farmer",
        "samoon | صمّون | الصمّون | food_bread | irq | bakery | none | مصطفى الخبّاز | ppl_man",
        "quzi | قوزي | القوزي | food_meat_on_bone | irq | dishes | none | أبو ضياء | ppl_turban",
        "zalabia | زلابية | الزلابية | food_doughnut | irq | sweets | none | حجّية أم أحمد | ppl_old_woman"]],
      twists=[{"type": "ovenTiming", "params": {"station": "samoon", "windowSec": 1.6, "perfectMult": 3, "minCycleSec": 2}}],
      rush=(["samoon | صمّون | food_bread", "bread | خبز | food_flatbread"],
            ["falafel | فلافل | food_falafel", "amba | عمبة | food_mango", "egg | بيض | food_egg",
             "potato | بطاطا | food_potato", "parsley | كرفس | food_leafy_green", "tomato | طماطة | food_tomato"])),

 dict(id="riyadh", name="الرياض", region="arab", log10F=15.8, S=7.2,
      currency=("ريال سعودي", "ر.س", "ui_money_bag"), cur="ريال",
      landmark="bld_tent", decor=["ani_camel", "food_teapot", "bld_palm_tree"],
      palette=("#3A1E0E", "#7A3E14", "#E0742A", "#FFD39A", "#C9561E"), silhouette="desert",
      rival=("أبو سلطان", "ppl_turban"), customers=["ppl_turban", "ppl_man_farmer"],
      stations=[st(x) for x in [
        "gahwa | قهوة سعوديّة | القهوة السعوديّة | food_teapot | gulf | drinks | hot | أبو تركي | ppl_turban",
        "luqaimat | لقيمات | اللقيمات | food_dango | gulf | sweets | none | أم فهد | ppl_woman_headscarf",
        "kabsa | كبسة | الكبسة | food_cooked_rice | gulf | dishes | none | أبو خالد | ppl_man_cook",
        "mutabbaq | مطبّق | المطبّق | food_stuffed_flatbread | gulf | street | none | عبدالرحمن | ppl_man",
        "jareesh | جريش | الجريش | food_steaming_bowl | gulf | dishes | hot | أم نايف | ppl_woman_cook",
        "mandi | مندي | المندي | food_poultry_leg | gulf | grill | none | أبو ماجد | ppl_beard",
        "laban | لبن بارد | اللبن البارد | food_milk | gulf | drinks | cold | فيصل | ppl_boy",
        "iceCream | آيس كريم | الآيس كريم | food_soft_ice_cream | wld | sweets | cold | ريما | ppl_girl"]],
      twists=[{"type": "weatherSwing", "params": {"hotProb": 0.60, "coldProb": 0.10, "rainProb": 0.02,
               "hotDayStations": ["laban", "iceCream"], "coldDayStations": ["gahwa", "jareesh"], "rainDayStations": [], "mult": 2.5}}],
      rush=(["saj | صاج | food_stuffed_flatbread", "bread | خبز | food_bread"],
            ["chicken | دجاج | food_poultry_leg", "rice | رز | food_cooked_rice", "onion | بصل | food_onion",
             "lemon | ليمون | food_lemon", "chili | شطّة | food_hot_pepper", "cucumber | خيار | food_cucumber"])),

 dict(id="dubai", name="دبي", region="arab", log10F=15.9, S=9,
      currency=("درهم إماراتي", "د.إ", "ui_money_bag"), cur="درهم",
      landmark="bld_office_building", decor=["ui_gem", "veh_helicopter", "bld_palm_tree"],
      palette=("#0D1B2A", "#1B3A5C", "#3FA7D6", "#FFE9B0", "#D4AF37"), silhouette="towers",
      rival=("الشيف لؤي", "ppl_man_tuxedo"), customers=["ppl_man_tuxedo", "ppl_prince", "ppl_princess"],
      stations=[st(x) for x in [
        "karak | شاي كرك | شاي الكرك | food_tea | gulf | drinks | hot | راشد | ppl_man",
        "dubaiShawarma | شاورما دبي | شاورما دبي | food_shawarma_wrap | gulf | street | none | أبو حمدان | ppl_man_cook",
        "machboos | مجبوس | المجبوس | food_cooked_rice | gulf | dishes | none | أم سلطان | ppl_woman_headscarf",
        "harees | هريس | الهريس | food_steaming_bowl | gulf | dishes | none | الوالدة أم راشد | ppl_old_woman",
        "falafelSushi | سوشي فلافل | سوشي الفلافل | food_sushi | wld | street | none | الشيف كاي | ppl_cook",
        "goldenBurger | برغر ذهبي | البرغر الذهبي | food_hamburger | wld | fried | none | مارك | ppl_man_tuxedo",
        "nouqMilk | حليب نوق | حليب النوق | food_milk | gulf | drinks | cold | سيف | ppl_man_farmer",
        "goldLuqaimat | لقيمات بالذهب | اللقيمات بالذهب | food_dango | gulf | sweets | none | الشيفة شمّا | ppl_woman_cook"]],
      twists=[{"type": "vipLounge", "params": {"loungeStation": "goldLuqaimat", "specialIntervalMult": 0.5, "vipShare": 0.6,
               "vipTierWeights": [0.6, 0.3, 0.1], "vipTipMin": 20, "levelPerTier": 40}}],
      rush=(["saj | صاج | food_stuffed_flatbread", "bread | خبز | food_baguette"],
            ["chicken | دجاج | food_poultry_leg", "cheese | جبنة | food_cheese", "avocado | أفوكادو | food_avocado",
             "falafel | فلافل | food_falafel", "lettuce | خس | food_leafy_green", "tomato | طماط | food_tomato"])),

 dict(id="marrakesh", name="مراكش", region="arab", log10F=16.0, S=11,
      currency=("درهم مغربي", "د.م", "ui_money_bag"), cur="درهم",
      landmark="bld_cactus", decor=["ui_lantern", "food_teapot", "ui_musical_notes"],
      palette=("#3A1414", "#7A2A20", "#D9573A", "#FFC28A", "#C0392B"), silhouette="minarets",
      rival=("لالّة زهرة", "ppl_woman_headscarf"), customers=["ppl_woman_headscarf", "ppl_artist"],
      stations=[st(x) for x in [
        "msemen | مسمّن | المسمّن | food_pancakes | mag | bakery | none | للا خديجة | ppl_woman_headscarf",
        "harira | حريرة | الحريرة | food_steaming_bowl | mag | dishes | hot | الحاجّة عيشة | ppl_old_woman",
        "tajine | طاجين | الطاجين | food_pot | mag | dishes | hot | سي محمد | ppl_man_cook",
        "couscous | كسكسي | الكسكسي | food_cooked_rice | mag | dishes | none | للا نعيمة | ppl_woman_cook",
        "pastilla | بسطيلة | البسطيلة | food_pie | mag | bakery | none | سي عبد الكريم | ppl_older_person",
        "mechoui | مشوي | المشوي | food_meat_on_bone | mag | grill | none | الحاج إبراهيم | ppl_beard",
        "atay | أتاي بالنعناع | أتاي بالنعناع | food_teapot | mag | drinks | hot | سي حميد | ppl_old_man",
        "chebakia | شبّاكيّة | الشبّاكيّة | food_pretzel | mag | sweets | none | سعيدة | ppl_woman"]],
      twists=[{"type": "nightMarket", "params": {"stations": ["harira", "mechoui", "atay", "chebakia"], "startHour": 19, "endHour": 1, "nightMult": 3}},
              {"type": "busWaves", "params": {"intervalMin": 25, "windowSec": 30, "waveMult": 4, "waveSec": 60, "stations": []}}],
      rush=(["bread | خبز | food_bread", "msemen | مسمّن | food_pancakes"],
            ["meat | لحمة | food_cut_of_meat", "olives | زيتون | food_olive", "lemon | ليمون | food_lemon",
             "egg | بيض | food_egg", "mint | نعناع | food_herb", "pepper | فلفل | food_bell_pepper"])),

 dict(id="istanbul", name="إسطنبول", region="world", log10F=16.25, S=14,
      currency=("ليرة تركيّة", "ل.ت", "ui_money_bag"), cur="ليرة",
      landmark="bld_bridge_at_night", decor=["veh_ferry", "ani_cat", "food_tea"],
      palette=("#1A1F3A", "#3A3F7A", "#B65A8C", "#FFD1A6", "#3A6EA5"), silhouette="minarets",
      rival=("الأسطى كمال", "ppl_man_cook"), customers=["ani_cat", "ppl_man"],
      stations=[st(x) for x in [
        "simit | سميت | السميت | food_bagel | tur | bakery | none | أحمد آبي | ppl_man",
        "fishSandwich | ساندويش سمك | ساندويش السمك | food_sandwich | tur | seafood | none | إمره | ppl_man_farmer",
        "doner | دونر | الدونر | food_shawarma_wrap | tur | street | none | جنكيز | ppl_man_cook",
        "lahmacun | لحم بعجين | اللحم بعجين | food_pizza | tur | bakery | none | حاجي بابا | ppl_old_man",
        "kofte | كفتة | الكفتة | food_meat_on_bone | tur | grill | none | بوراك | ppl_beard",
        "turkishTea | شاي تركي | الشاي التركي | food_tea | tur | drinks | hot | زينب آبلا | ppl_woman_headscarf",
        "kunefe | كنافة تركيّة | الكنافة التركيّة | food_pie | tur | sweets | none | الأسطى حسن | ppl_older_person",
        "lokum | راحة حلقوم | راحة الحلقوم | food_candy | tur | sweets | none | صالح الأسطى | ppl_cook"]],
      twists=[{"type": "portShipments", "params": {"station": "fishSandwich", "intervalHours": 4, "dockHours": 3, "targetMin": 30, "rewardMin": 90, "offlineRewardFrac": 0.5}},
              {"type": "busWaves", "params": {"intervalMin": 20, "windowSec": 30, "waveMult": 4, "waveSec": 60, "stations": []}}],
      rush=(["simit | سميت | food_bagel", "bread | خبز | food_baguette"],
            ["fish | سمك | ani_fish", "onion | بصل | food_onion", "lettuce | خس | food_leafy_green",
             "lemon | ليمون | food_lemon", "tomato | بندورة | food_tomato", "chili | شطّة | food_hot_pepper"])),

 dict(id="athens", name="أثينا", region="world", log10F=16.35, S=18,
      currency=("يورو", "€", "ui_euro"), cur="يورو",
      landmark="bld_classical_building", decor=["food_olive", "veh_sailboat", "ui_sun"],
      palette=("#13304A", "#2D6A9F", "#F0A07A", "#FFE8B0", "#2D6A9F"), silhouette="hills",
      rival=("كيريا ماريا", "ppl_woman"), customers=["ppl_person_tipping_hand", "ppl_woman"],
      stations=[st(x) for x in [
        "gyros | جيروس | الجيروس | food_shawarma_wrap | wld | street | none | نيكوس | ppl_man_cook",
        "souvlaki | سوفلاكي | السوفلاكي | food_oden | wld | grill | none | ديمتري | ppl_beard",
        "greekSalad | سلطة يونانيّة | السلطة اليونانيّة | food_green_salad | wld | dishes | cold | إيليني | ppl_woman",
        "spanakopita | فطيرة سبانخ | فطيرة السبانخ | food_pie | wld | bakery | none | يايا صوفيا | ppl_old_woman",
        "moussaka | مسقعة | المسقعة | food_eggplant | wld | dishes | hot | كوستاس | ppl_older_person",
        "tavernaFish | سمك التافرنا | سمك التافرنا | ani_fish | wld | seafood | none | الكابتن ستافروس | ppl_old_man",
        "frappe | فرابيه | الفرابيه | food_cup_with_straw | wld | drinks | cold | ديسبينا | ppl_woman_office",
        "loukoumades | لقمة القاضي | لقمة القاضي | food_doughnut | wld | sweets | none | بابو يورغوس | ppl_older_person"]],
      twists=[{"type": "busWaves", "params": {"intervalMin": 20, "windowSec": 30, "waveMult": 4, "waveSec": 60, "stations": []}},
              {"type": "weatherSwing", "params": {"hotProb": 0.50, "coldProb": 0.10, "rainProb": 0.05,
               "hotDayStations": ["greekSalad", "frappe"], "coldDayStations": ["moussaka"], "rainDayStations": [], "mult": 2.5}}],
      rush=(["pita | بيتا | food_flatbread", "bread | خبز | food_bread"],
            ["chicken | دجاج | food_poultry_leg", "feta | جبنة فيتا | food_cheese", "olives | زيتون | food_olive",
             "tomato | بندورة | food_tomato", "cucumber | خيار | food_cucumber", "onion | بصل | food_onion"])),

 dict(id="london", name="لندن", region="world", log10F=16.4, S=23,
      currency=("جنيه إسترليني", "£", "ui_pound"), cur="جنيه",
      landmark="bld_ferris_wheel", decor=["ui_umbrella_with_rain_drops", "veh_bus", "veh_taxi"],
      palette=("#1E2430", "#3D4A5E", "#8C9AA8", "#E8E2D0", "#B22234"), silhouette="bridge",
      rival=("مستر هاري", "ppl_man_tuxedo"), customers=["ppl_guard", "ppl_police"],
      stations=[st(x) for x in [
        "englishTea | شاي إنجليزي | الشاي الإنجليزي | food_teapot | wld | drinks | hot | مسز ماغي | ppl_old_woman",
        "fishChips | سمك وبطاطا | السمك والبطاطا | food_french_fries | wld | fried | none | ديف | ppl_man_cook",
        "londonSandwich | ساندويش لندني | الساندويش اللندني | food_sandwich | wld | street | none | صوفي | ppl_woman",
        "pie | فطيرة لحمة | فطيرة اللحمة | food_pie | wld | bakery | hot | غراهام | ppl_beard",
        "falafelWrap | راب فلافل | راب الفلافل | food_falafel | pal | street | none | أبو كريم | ppl_man_cook",
        "breakfast | فطور إنجليزي | الفطور الإنجليزي | food_fried_egg | wld | dishes | hot | نايجل | ppl_older_person",
        "scones | سكونز | السكونز | food_bread | wld | bakery | none | إيميلي | ppl_woman_office",
        "pudding | بودنغ | البودنغ | food_custard | wld | sweets | none | الجدّة روز | ppl_old_woman"]],
      twists=[{"type": "weatherSwing", "params": {"hotProb": 0.10, "coldProb": 0.30, "rainProb": 0.40,
               "hotDayStations": ["londonSandwich"], "coldDayStations": ["englishTea", "pie", "breakfast"],
               "rainDayStations": ["englishTea", "pie"], "mult": 2.5}},
              {"type": "deliveryRuns", "params": {"intervalMin": 10, "tripMin": 6, "rewardMin": 8, "scooters": 2, "queueMax": 5,
               "extraScooterCostsBase": "F*[1e-6,1e-4,1e-2]", "dispatcherCostBase": "F*1e-5", "offlineRewardFrac": 0.5, "rainMult": 1.5}}],
      rush=(["wrap | راب | food_flatbread", "bread | خبز | food_bread"],
            ["falafel | فلافل | food_falafel", "hummus | حمّص | food_hummus_bowl", "fries | بطاطا | food_french_fries",
             "lettuce | خس | food_leafy_green", "tomato | بندورة | food_tomato", "cheese | جبنة | food_cheese"])),

 dict(id="paris", name="باريس", region="world", log10F=16.5, S=29,
      currency=("يورو", "€", "ui_euro"), cur="يورو",
      landmark="bld_carousel_horse", decor=["veh_bicycle", "ui_artist_palette", "food_croissant"],
      palette=("#24182E", "#4E3363", "#C27BA0", "#FFD9C2", "#C27BA0"), silhouette="oldCity",
      rival=("مسيو بيير", "ppl_man_cook"), customers=["ppl_artist", "ppl_man_tuxedo"],
      stations=[st(x) for x in [
        "crepe | كريب | الكريب | food_pancakes | wld | sweets | none | أميلي | ppl_woman",
        "croissant | كرواسون | الكرواسون | food_croissant | wld | bakery | none | جان لوك | ppl_man_cook",
        "cafeParis | قهوة باريسيّة | القهوة الباريسيّة | food_coffee | wld | drinks | hot | مدام كوليت | ppl_older_person",
        "cheesePlate | صحن أجبان | صحن الأجبان | food_cheese | wld | dishes | none | أنطوان | ppl_beard",
        "onionSoup | شوربة بصل | شوربة البصل | food_steaming_bowl | wld | dishes | hot | مسيو جيرار | ppl_old_man",
        "baguette | باغيت | الباغيت | food_baguette | wld | bakery | none | لوكاس | ppl_man",
        "gateau | كيكة فرنسيّة | الكيكة الفرنسيّة | food_birthday_cake | wld | sweets | none | كلوي | ppl_woman_cook",
        "gourmetFalafel | فلافل فاخر | الفلافل الفاخر | food_fork_knife_plate | pal | fried | none | الشيف ياسمين | ppl_woman_cook"]],
      twists=[{"type": "vipLounge", "params": {"loungeStation": "gourmetFalafel", "specialIntervalMult": 0.5, "vipShare": 0.6,
               "vipTierWeights": [0.6, 0.3, 0.1], "vipTipMin": 20, "levelPerTier": 40}},
              {"type": "ovenTiming", "params": {"station": "baguette", "windowSec": 1.6, "perfectMult": 3, "minCycleSec": 2}}],
      rush=(["baguette | باغيت | food_baguette", "croissant | كرواسون | food_croissant"],
            ["cheese | جبنة | food_cheese", "egg | بيض | food_egg", "mushroom | فطر | food_mushroom",
             "lettuce | خس | food_leafy_green", "tomato | بندورة | food_tomato", "butter | زبدة | food_butter"])),

 dict(id="newYork", name="نيويورك", region="world", log10F=16.55, S=37,
      currency=("دولار أمريكي", "$", "ui_heavy_dollar_sign"), cur="دولار",
      landmark="bld_statue_of_liberty", decor=["veh_taxi", "bld_cityscape", "food_hot_dog"],
      palette=("#101820", "#26364A", "#F2A541", "#FFE3B0", "#F2A541"), silhouette="towers",
      rival=("بيغ توني", "ppl_man"), customers=["ppl_police", "ppl_construction", "ppl_technologist"],
      stations=[st(x) for x in [
        "hotDog | هوت دوغ حلال | الهوت دوغ الحلال | food_hot_dog | wld | street | none | مايك | ppl_man",
        "bagelNy | بيغل | البيغل | food_bagel | wld | bakery | none | العمّ سول | ppl_older_person",
        "pizzaSlice | سلايس بيتزا | سلايس البيتزا | food_pizza | wld | bakery | none | جينو | ppl_man_cook",
        "halalCart | صحن العربايّة | صحن العربايّة | food_curry_rice | wld | street | none | أبو يوسف المصري | ppl_beard",
        "falafelTruck | فلافل التراك | فلافل التراك | food_falafel | pal | fried | none | سليم من باترسون | ppl_man_cook",
        "pancakes | بانكيك | البانكيك | food_pancakes | wld | sweets | none | بيكي | ppl_woman",
        "icedCoffee | قهوة مثلّجة | القهوة المثلّجة | food_cup_with_straw | wld | drinks | cold | جاكي | ppl_woman_office",
        "cheesecake | تشيز كيك | التشيز كيك | food_shortcake | wld | sweets | none | مسز هيلين | ppl_old_woman"]],
      twists=[{"type": "deliveryRuns", "params": {"intervalMin": 8, "tripMin": 5, "rewardMin": 8, "scooters": 3, "queueMax": 5,
               "extraScooterCostsBase": "F*[1e-6,1e-4,1e-2]", "dispatcherCostBase": "F*1e-5", "offlineRewardFrac": 0.5, "rainMult": 1.5}},
              {"type": "nightMarket", "params": {"stations": ["hotDog", "pizzaSlice", "halalCart", "falafelTruck"], "startHour": 22, "endHour": 4, "nightMult": 3}}],
      rush=(["bread | خبز | food_bread", "bagel | بيغل | food_bagel"],
            ["falafel | فلافل | food_falafel", "chicken | دجاج | food_poultry_leg", "rice | رز | food_cooked_rice",
             "whiteSauce | صوص أبيض | food_jar", "lettuce | خس | food_leafy_green", "chili | شطّة | food_hot_pepper"])),

 dict(id="santiago", name="سانتياغو", region="world", log10F=16.6, S=47,
      currency=("بيزو تشيلي", "ب.ت", "ui_dollar"), cur="بيزو",
      landmark="bld_snow_capped_mountain", decor=["food_peach", "ui_musical_notes", "veh_bus"],
      palette=("#1C2238", "#3B4A7A", "#E06A4A", "#FFD6B0", "#2E7D32"), silhouette="mountains",
      rival=("دون خوسيه", "ppl_older_person"), customers=["ppl_older_person", "ppl_old_man"],
      stations=[st(x) for x in [
        "completo | كومبليتو | الكومبليتو | food_hot_dog | wld | street | none | دييغو | ppl_man",
        "wheat | قمح | القمح | food_wheat | wld | bakery | none | دون رامون | ppl_man_farmer",
        "empanada | إمبانادا | الإمبانادا | food_dumpling | wld | bakery | none | سينيورا كارمن | ppl_woman_cook",
        "humitas | أوميتاس | الأوميتاس | food_tamale | wld | dishes | none | ماما روزا | ppl_old_woman",
        "cornPie | فطيرة ذرة | فطيرة الذرة | food_corn | wld | dishes | hot | خوانيتا | ppl_woman",
        "churrasco | ساندويش تشوراسكو | ساندويش التشوراسكو | food_sandwich | wld | grill | none | بابلو | ppl_man_cook",
        "moteHuesillo | موتي بالخوخ | الموتي بالخوخ | food_peach | wld | drinks | cold | إغناسيو | ppl_boy",
        "clubFalafel | فلافل النادي الفلسطيني | فلافل النادي الفلسطيني | food_falafel | pal | fried | none | جورج سعيد | ppl_older_person"]],
      twists=[{"type": "productionChain", "params": {"inputStation": "wheat", "outputStation": "empanada", "ratio": 1, "outputMult": 3, "stockCapMin": 60}},
              {"type": "vipLounge", "params": {"loungeStation": "clubFalafel", "specialIntervalMult": 0.5, "vipShare": 0.5,
               "vipTierWeights": [0.6, 0.3, 0.1], "vipTipMin": 20, "levelPerTier": 40}}],
      rush=(["bread | خبز | food_bread", "saj | صاج | food_flatbread"],
            ["meat | لحمة | food_cut_of_meat", "avocado | أفوكادو | food_avocado", "tomato | بندورة | food_tomato",
             "olives | زيتون | food_olive", "egg | بيض | food_egg", "corn | ذرة | food_corn"])),

 dict(id="rio", name="ريو دي جانيرو", region="world", log10F=16.65, S=60,
      currency=("ريال برازيلي", "ر.ب", "ui_dollar"), cur="ريال",
      landmark="bld_desert_island", decor=["ui_party_popper", "food_coconut", "ui_musical_notes"],
      palette=("#0B3D2E", "#138A5E", "#F2C94C", "#FFF1B8", "#F2C94C"), silhouette="mountains",
      rival=("كارلوس", "ppl_man_cook"), customers=["ppl_raising_hands", "ppl_woman_superhero", "ppl_superhero"],
      stations=[st(x) for x in [
        "acai | أساي | الأساي | food_blueberries | wld | sweets | cold | بيا | ppl_woman",
        "coxinha | كوشينيا | الكوشينيا | food_poultry_leg | wld | fried | none | دونا ماريا | ppl_woman_cook",
        "cheeseBread | خبز بالجبنة | الخبز بالجبنة | food_bread | wld | bakery | none | الجدّة جوانا | ppl_old_woman",
        "picanha | مشاوي برازيليّة | المشاوي البرازيليّة | food_cut_of_meat | wld | grill | none | جواو | ppl_man_cook",
        "feijoada | فيجوادا | الفيجوادا | food_beans | wld | dishes | hot | تيا لوسيا | ppl_older_person",
        "coconutWater | ماي جوز هند | ماي جوز الهند | food_coconut | wld | drinks | cold | ماركينيو | ppl_boy",
        "brigadeiro | بريغاديرو | البريغاديرو | food_chocolate_bar | wld | sweets | none | كاميلا | ppl_woman_office",
        "sambaFalafel | فلافل السامبا | فلافل السامبا | food_falafel | pal | fried | none | رافائيل حدّاد | ppl_man"]],
      twists=[{"type": "nightMarket", "params": {"stations": ["picanha", "brigadeiro", "sambaFalafel"], "startHour": 20, "endHour": 2, "nightMult": 3}},
              {"type": "weatherSwing", "params": {"hotProb": 0.55, "coldProb": 0.05, "rainProb": 0.15,
               "hotDayStations": ["acai", "coconutWater"], "coldDayStations": ["feijoada"], "rainDayStations": [], "mult": 2.5}}],
      rush=(["bread | خبز | food_bread", "saj | صاج | food_flatbread"],
            ["meat | لحمة | food_cut_of_meat", "cheese | جبنة | food_cheese", "pineapple | أناناس | food_pineapple",
             "onion | بصل | food_onion", "tomato | بندورة | food_tomato", "chili | شطّة | food_hot_pepper"])),

 dict(id="tokyo", name="طوكيو", region="world", log10F=16.7, S=79,
      currency=("ين ياباني", "¥", "ui_yen"), cur="ين",
      landmark="bld_tokyo_tower", decor=["bld_mount_fuji", "ui_lantern", "veh_train"],
      palette=("#1B1030", "#3E1F5C", "#E0457B", "#FFD0DA", "#E0457B"), silhouette="towers",
      rival=("الشيف كينجي", "ppl_man_cook"), customers=["ppl_bowing", "ppl_technologist"],
      stations=[st(x) for x in [
        "onigiri | أونيغيري | الأونيغيري | food_rice_ball | wld | street | none | أوباتشان هانا | ppl_old_woman",
        "ramen | رامن | الرامن | food_steaming_bowl | wld | dishes | hot | تايشي | ppl_man_cook",
        "sushi | سوشي | السوشي | food_sushi | wld | seafood | none | الشيف تاكيشي | ppl_older_person",
        "tempura | تمبورا | التمبورا | food_fried_shrimp | wld | fried | none | كينتا | ppl_man",
        "dango | دانغو | الدانغو | food_dango | wld | sweets | none | ساكورا | ppl_girl",
        "bento | بنتو | البنتو | food_bento_box | wld | dishes | none | ميكا | ppl_woman_office",
        "matcha | ماتشا | الماتشا | food_tea | wld | drinks | hot | أوجيسان كين | ppl_old_man",
        "falafelOmakase | فلافل أوماكاسي | فلافل الأوماكاسي | food_falafel | pal | fried | none | يوسف تاناكا | ppl_cook"]],
      twists=[{"type": "ovenTiming", "params": {"station": "tempura", "windowSec": 1.4, "perfectMult": 3, "minCycleSec": 2}},
              {"type": "portShipments", "params": {"station": "sushi", "intervalHours": 4, "dockHours": 3, "targetMin": 30, "rewardMin": 90, "offlineRewardFrac": 0.5}}],
      rush=(["rice | رز | food_cooked_rice", "bread | خبز | food_bread"],
            ["fish | سمك | ani_fish", "shrimp | قريدس | food_fried_shrimp", "cucumber | خيار | food_cucumber",
             "egg | بيض | food_egg", "avocado | أفوكادو | food_avocado", "falafel | فلافل | food_falafel"])),
]

# ---------------------------------------------------------------- twist goal texts (verb, rest-with-{n}/{amount}, intro-rest)
# Key = (cityId, twistIndex). Each: (verb, intro_rest, rest)
TWIST_TEXT = {
    ("bethlehem", 0): ("استقبل", "أوّل باص سيّاح بساحة المهد", "{n} باصات سيّاح"),
    ("nablus", 0): ("طلّع", "{n} صواني كنافة مظبوطة", "{n} صواني كنافة مظبوطة"),
    ("hebron", 0): ("اعصر", "{n} وحدة عنب للدبس", "{n} وحدة عنب للدبس"),
    ("jaffa", 0): ("حمّل", "أوّل شحنة برتقال عالسفينة", "{n} شحنات برتقال"),
    ("haifa", 0): ("وصّل", "{n} طلبات دليفري عالكرمل", "{n} طلبات دليفري"),
    ("gaza", 0): ("اربح", "{amount} جنيه من عروض الطقس", "{amount} جنيه من عروض الطقس"),
    ("ramallah", 0): ("اربح", "{amount} جنيه بسوق الليل", "{amount} جنيه بسوق الليل"),
    ("amman", 0): ("حوّل", "{n} وحدة حليب لجميد", "{n} وحدة حليب لجميد"),
    ("amman", 1): ("حوّل", "{n} وحدة جميد لمنسف", "{n} وحدة جميد لمنسف"),
    ("beirut", 0): ("اربح", "{amount} ليرة بسهرات الكورنيش", "{amount} ليرة بسهرات الكورنيش"),
    ("damascus", 0): ("استقبل", "أوّل جماعة سيّاح بالسوق", "{n} جماعات سيّاح بالسوق"),
    ("cairo", 0): ("وصّل", "{n} طلبات للعماير", "{n} طلبات للعماير"),
    ("baghdad", 0): ("طلّع", "{n} صمّونات مظبوطة", "{n} صمّونات مظبوطة"),
    ("riyadh", 0): ("اربح", "{amount} ريال من عروض الطقس", "{amount} ريال من عروض الطقس"),
    ("dubai", 0): ("خدّم", "أوّل ضيف كبير بالصالة", "{n} ضيوف كبار بالصالة"),
    ("marrakesh", 0): ("اربح", "{amount} درهم بليالي الساحة", "{amount} درهم بليالي الساحة"),
    ("marrakesh", 1): ("استقبل", "أوّل حافلة سيّاح", "{n} حافلات سيّاح"),
    ("istanbul", 0): ("حمّل", "أوّل شحنة سندويشات للقوارب", "{n} شحنات سندويشات للقوارب"),
    ("istanbul", 1): ("استقبل", "أوّل باص سيّاح", "{n} باصات سيّاح"),
    ("athens", 0): ("استقبل", "أوّل باص سيّاح للآثار", "{n} باصات سيّاح للآثار"),
    ("athens", 1): ("اربح", "{amount} يورو من عروض الطقس", "{amount} يورو من عروض الطقس"),
    ("london", 0): ("اربح", "{amount} جنيه من عروض الطقس", "{amount} جنيه من عروض الطقس"),
    ("london", 1): ("وصّل", "{n} طلبات دليفري تحت الشتي", "{n} طلبات دليفري تحت الشتي"),
    ("paris", 0): ("خدّم", "أوّل ناقد كبير بالصالة", "{n} نقّاد كبار بالصالة"),
    ("paris", 1): ("طلّع", "{n} باغيت مظبوطة", "{n} باغيت مظبوطة"),
    ("newYork", 0): ("وصّل", "{n} طلبات للأبراج", "{n} طلبات للأبراج"),
    ("newYork", 1): ("اربح", "{amount} دولار بسهرة نيويورك", "{amount} دولار بسهرة نيويورك"),
    ("santiago", 0): ("اطحن", "{n} وحدة قمح للإمبانادا", "{n} وحدة قمح للإمبانادا"),
    ("santiago", 1): ("خدّم", "أوّل ضيف كبير بالنادي", "{n} ضيوف كبار بالنادي"),
    ("rio", 0): ("اربح", "{amount} ريال بليالي الكرنفال", "{amount} ريال بليالي الكرنفال"),
    ("rio", 1): ("اربح", "{amount} ريال من عروض الطقس", "{amount} ريال من عروض الطقس"),
    ("tokyo", 0): ("طلّع", "{n} قطع تمبورا مظبوطة", "{n} قطع تمبورا مظبوطة"),
    ("tokyo", 1): ("حمّل", "أوّل شحنة سوشي", "{n} شحنات سوشي"),
}

TWIST_METRIC = {"busWaves": "busesWelcomed", "ovenTiming": "ovenPerfects", "productionChain": "chainUnits",
                "portShipments": "shipmentsDelivered", "deliveryRuns": "deliveriesDone",
                "weatherSwing": "weatherEarnedBase", "nightMarket": "nightEarnedBase", "vipLounge": "vipServed"}

def chain_u1h(city, tw):
    keys = [s["key"] for s in city["stations"]]
    tier_out = keys.index(tw["params"]["outputStation"])
    speed = 2 ** 3  # station milestones 10, 25, 50 at level 50
    d = 50 * speed / TIER_CYCLE[tier_out] * tw["params"].get("ratio", 1)
    return round(d * 3600)

def twist_amounts(city, tw, F):
    t = tw["type"]
    if t == "busWaves": return (1, 5, 15)
    if t == "ovenTiming": return (5, 40, 150)
    if t == "productionChain":
        u = chain_u1h(city, tw); return (100, u, 20 * u)
    if t == "portShipments": return (1, 4, 10)
    if t == "deliveryRuns": return (3, 20, 60)
    if t in ("weatherSwing", "nightMarket"): return (sig3(F * 1e-4), sig3(F * 1e-2), sig3(F * 0.05))
    if t == "vipLounge": return (1, 6, 20)
    raise ValueError(t)

# ---------------------------------------------------------------- goal builders
def G(gtype, params, stars, text, rewards=None):
    d = {"type": gtype, "params": params, "stars": stars, "text": text}
    if rewards: d["rewards"] = rewards
    return d

def meta_goal(kind, n):
    if kind == "startResearch":
        return G("startResearch", {"count": n}, 2, gv("بلّش", "بحث بدفتر ستّي" if n == 1 else "{n} أبحاث بدفتر ستّي"))
    if kind == "researchLevels":
        return G("researchLevels", {"count": n}, 2, gv("خلّص", "{n} أبحاث بدفتر ستّي"))
    if kind == "sendSupplyRun":
        return G("sendSupplyRun", {"count": n}, 2, gv("ابعت", "{n} رحلات توريد"))
    if kind == "supplyReturns":
        return G("supplyReturns", {"count": n}, 2, gv("استلم", "{n} رحلات توريد راجعة"))
    if kind == "dailyOrders":
        return G("dailyOrders", {"count": n}, 2, gv("خلّص", "{n} طلبات يوميّة"))
    if kind == "contractGoals":
        return G("contractGoals", {"count": n}, 2, gv("حقّق", "أوّل هدف بطلبيّة" if n == 1 else "{n} أهداف بالطلبيّات"))
    if kind == "eventMilestones":
        return G("eventMilestones", {"count": n}, 2, gv("خلّص", "{n} مراحل بمهرجان الويكند"))
    if kind == "heritageItems":
        return G("heritageItems", {"count": n}, 2, gv("جمّع", "{n} قطع تراث جديدة"))
    raise ValueError(kind)

def extra_goal(kind, n, city):
    if kind == "specialCustomers":
        return G("specialCustomers", {"count": n}, 1, gv("استقبل", "{n} زباين مميّزين"))
    if kind == "customersServed":
        return G("customersServed", {"count": n}, 1, gv("خدّم", "{n} زبون"))
    if kind == "tapCook":
        return G("tapCook", {"count": n}, 1, gt("دقّ واطبخ {n} مرّة بإيدك", "دقّي واطبخي {n} مرّة بإيدك"))
    if kind == "choiceEvents":
        return G("choiceEvents", {"count": n}, 1, gv("جاوب", "على {n} حكايات من الحارة"))
    if kind == "rushRounds":
        return G("rushRounds", {"count": n}, 1, gv("العب", "{n} جولات طلبيات على السريع"))
    if kind == "chefTagMatch":
        return G("chefTagMatch", {"count": n}, 1, gv("حطّ", "{n} طبّاخين بيناسبوا محطّات " + city["name"]))
    if kind == "equipChefs":
        return G("equipChefs", {"count": n}, 1, gv("حطّ", "{n} طبّاخين بالمطبخ"))
    if kind == "branchCollect":
        return G("branchCollect", {"count": n}, 1, gv("اجمع", "ذهب خزنة الفروع" if n == 1 else "ذهب خزنة الفروع {n} مرّات"))
    if kind == "dailyOrders":
        return G("dailyOrders", {"count": n}, 1, gv("خلّص", "{n} طلبات يوميّة"))
    if kind == "collectVault":
        return G("collectVault", {"count": n}, 1, gt("ارجع واجمع الخزنة", "ارجعي واجمعي الخزنة"))
    raise ValueError(kind)

# meta1, meta2, extras [(after template row, kind, n)]
PLAN = {
    "bethlehem": (("startResearch", 1), ("sendSupplyRun", 2), [(3, "specialCustomers", 3), (12, "customersServed", 3000)]),
    "nablus":    (("researchLevels", 2), ("dailyOrders", 3), [(1, "tapCook", 30), (13, "specialCustomers", 5)]),
    "hebron":    (("supplyReturns", 2), ("dailyOrders", 3), [(6, "customersServed", 5000), (14, "choiceEvents", 2)]),
    "jaffa":     (("contractGoals", 1), ("supplyReturns", 4), [(9, "rushRounds", 1), (15, "specialCustomers", 8)]),
    "haifa":     (("contractGoals", 1), ("heritageItems", 2), [(4, "chefTagMatch", 2), (16, "rushRounds", 2)]),
    "gaza":      (("contractGoals", 1), ("supplyReturns", 4), [(7, "customersServed", 8000), (13, "choiceEvents", 3)]),
    "ramallah":  (("contractGoals", 2), ("eventMilestones", 3), [(3, "specialCustomers", 10), (16, "dailyOrders", 3)]),
    "amman":     (("researchLevels", 3), ("eventMilestones", 3), [(5, "chefTagMatch", 3), (12, "branchCollect", 1)]),
    "beirut":    (("contractGoals", 2), ("supplyReturns", 5), [(8, "rushRounds", 2), (15, "specialCustomers", 12)]),
    "damascus":  (("dailyOrders", 5), ("eventMilestones", 3), [(4, "customersServed", 15000), (14, "choiceEvents", 3)]),
    "cairo":     (("contractGoals", 2), ("heritageItems", 3), [(6, "specialCustomers", 10), (17, "branchCollect", 2)]),
    "baghdad":   (("researchLevels", 3), ("eventMilestones", 4), [(2, "tapCook", 40), (16, "rushRounds", 3)]),
    "riyadh":    (("researchLevels", 3), ("heritageItems", 3), [(9, "chefTagMatch", 3), (15, "customersServed", 20000)]),
    "dubai":     (("contractGoals", 3), ("heritageItems", 3), [(4, "specialCustomers", 15), (13, "equipChefs", 4)]),
    "marrakesh": (("researchLevels", 4), ("eventMilestones", 4), [(7, "choiceEvents", 3), (15, "branchCollect", 2)]),
    "istanbul":  (("supplyReturns", 6), ("heritageItems", 4), [(5, "customersServed", 25000), (14, "rushRounds", 3)]),
    "athens":    (("contractGoals", 3), ("researchLevels", 4), [(3, "specialCustomers", 15), (16, "chefTagMatch", 4)]),
    "london":    (("dailyOrders", 6), ("heritageItems", 4), [(6, "choiceEvents", 4), (15, "customersServed", 30000)]),
    "paris":     (("researchLevels", 4), ("eventMilestones", 5), [(4, "equipChefs", 5), (13, "specialCustomers", 20)]),
    "newYork":   (("contractGoals", 3), ("supplyReturns", 6), [(8, "rushRounds", 4), (16, "branchCollect", 3)]),
    "santiago":  (("heritageItems", 4), ("researchLevels", 5), [(5, "chefTagMatch", 4), (14, "choiceEvents", 4)]),
    "rio":       (("eventMilestones", 5), ("contractGoals", 3), [(7, "customersServed", 30000), (15, "rushRounds", 4)]),
    "tokyo":     (("researchLevels", 5), ("heritageItems", 5), [(3, "specialCustomers", 20), (15, "equipChefs", 5)]),
}

CHEST_WOOD = [{"type": "chest", "id": "wood", "amount": 1}]
CHEST_SILVER = [{"type": "chest", "id": "silver", "amount": 1}]
GOLD10 = [{"type": "gold", "amount": 10}]

def upgrades_for(city, F):
    out = []
    keys = [s for s in city["stations"]]
    N = len(keys)
    order = []
    cycle = 0
    while len(order) < 40:
        for s in keys: order.append((s, cycle))
        order.append(("all", cycle))
        cycle += 1
    j = 0
    while 2.5e5 * 20 ** j <= 10 * F:
        tgt, cyc = order[j]
        if tgt == "all":
            name = ["يافطة جديدة: كل المحطّات ×3", "دعاية بالراديو: كل المحطّات ×3", "زينة العيد: كل المحطّات ×3"][min(cyc, 2)]
            target = "all"
        else:
            name = tgt["name"] + [": وصفة سرّية ×3", ": سرّ المعلّم ×3", ": لمسة ستّي ×3"][min(cyc, 2)]
            target = tgt["key"]
        out.append({"id": f"{city['id']}.u{j:02d}", "target": target, "mult": 3, "priceBase": 2.5e5 * 20 ** j, "name": name})
        j += 1
    return out

def template_goals(city, F, upgrades):
    s = city["stations"]; N = len(s); C = level_cap(city["index"]); cur = city["cur"]
    tw = city["twists"]; t0 = tw[0]; tl = tw[-1]
    a0 = twist_amounts(city, t0, F); al = twist_amounts(city, tl, F)
    sid = lambda i: f"{city['id']}.{s[i]['key']}"
    def tw_goal(tw_obj, idx, which, amount, stars, rewards=None):
        verb, intro, rest = TWIST_TEXT[(city["id"], idx)]
        txt = gv(verb, intro if which == 0 else rest)
        return G("twistMetric", {"metric": TWIST_METRIC[tw_obj["type"]], "amount": amount}, stars, txt, rewards)
    up_count16 = sum(1 for u in upgrades if u["priceBase"] <= F / 10)
    m1, m2, _ = PLAN[city["id"]]
    rows = {
        1: G("unlockStation", {"stationId": sid(1)}, 1, gv("افتح", "محطّة " + s[1]["defn"])),
        2: G("stationLevel", {"stationId": sid(0), "level": 25}, 1, gv("كبّر", s[0]["defn"] + " لمستوى {n}")),
        3: G("managersCount", {"count": 2}, 1, gv("وظّف", "{n} معلّمين")),
        4: G("unlockStation", {"stationId": sid(2)}, 1, gv("افتح", "محطّة " + s[2]["defn"])),
        5: tw_goal(t0, 0, 0, a0[0], 1, CHEST_WOOD),
        6: G("earnCash", {"amountBase": sig3(F * 1e-5)}, 2, gv("اجمع", "{amount} " + cur)),
        7: G("unlockStation", {"stationId": sid(math.ceil(N / 2))}, 1, gv("افتح", "محطّة " + s[math.ceil(N / 2)]["defn"])),
        8: G("buyUpgrades", {"count": 2}, 1, "اشتري {n} ترقيات"),
        9: G("managersCount", {"count": N}, 2, gv("وظّف", "معلّم لكل محطّة")),
        10: G("allStationsLevel", {"level": 25}, 2, gv("كبّر", "كل المحطّات لمستوى {n}"), GOLD10),
        11: meta_goal(*m1),
        12: G("earnCash", {"amountBase": sig3(F * 1e-3)}, 2, gv("اربح", "{amount} " + cur)),
        13: G("stationLevel", {"stationId": sid(N - 1), "level": 50}, 2, gv("كبّر", s[N - 1]["defn"] + " لمستوى {n}")),
        14: tw_goal(t0, 0, 1, a0[1], 2),
        15: G("allStationsLevel", {"level": 50}, 2, gv("كبّر", "كل المحطّات لمستوى {n}"), CHEST_WOOD),
        16: G("buyUpgrades", {"count": up_count16}, 2, "اشتري {n} ترقيات"),
        17: meta_goal(*m2),
        18: G("earnCash", {"amountBase": sig3(F * 0.1)}, 3, gv("اربح", "{amount} " + cur + " ب" + city["name"])),
        19: G("allStationsLevel", {"level": min(100, C // 2)}, 3, gv("كبّر", "كل المحطّات لمستوى {n}")),
        20: tw_goal(tl, len(tw) - 1, 2, al[2], 3, CHEST_SILVER),
        21: G("stationLevel", {"stationId": sid(0), "level": C}, 3, gv("كبّر", s[0]["defn"] + " لآخر مستوى ({n})")),
        22: G("earnCash", {"amountBase": F}, 3, gv("اربح", "{amount} " + cur, prefix="تاج " + city["name"] + ": ")),
    }
    return rows

def jerusalem_goals():
    J = "jerusalem."
    return [
        G("unlockStation", {"stationId": J + "hummus"}, 1, gv("افتح", "محطّة الحمّص")),
        G("stationLevel", {"stationId": J + "falafel", "level": 10}, 1, gv("كبّر", "الفلافل لمستوى {n}")),
        G("hireManager", {"stationId": J + "falafel"}, 1, gv("وظّف", "معلّم للفلافل")),
        G("unlockStation", {"stationId": J + "tea"}, 1, gv("افتح", "محطّة الشاي بالنعنع")),
        G("earnCash", {"amountBase": 5000}, 1, gv("اربح", "{amount} جنيه")),
        G("managersCount", {"count": 3}, 1, gv("وظّف", "{n} معلّمين")),
        G("specialCustomers", {"count": 1}, 1, gv("استقبل", "زبون مميّز")),
        G("stationLevel", {"stationId": J + "falafel", "level": 25}, 1, gv("كبّر", "الفلافل لمستوى {n}")),
        G("unlockStation", {"stationId": J + "kaak"}, 1, gv("افتح", "محطّة كعك القدس")),
        G("buyUpgrades", {"count": 1}, 2, "اشتري أوّل ترقية"),
        G("equipChefs", {"count": 1}, 2, gv("حطّ", "طبّاخ بالمطبخ")),
        G("unlockStation", {"stationId": J + "ful"}, 2, gv("افتح", "محطّة الفول المدمّس")),
        G("earnCash", {"amountBase": 1e8}, 2, gv("اربح", "{amount} جنيه")),
        G("collectVault", {"count": 1}, 2, gt("ارجع واجمع الخزنة", "ارجعي واجمعي الخزنة")),
        G("unlockStation", {"stationId": J + "maqluba"}, 2, gv("افتح", "محطّة المقلوبة")),
        G("allStationsLevel", {"level": 25}, 2, gv("كبّر", "كل المحطّات لمستوى {n}")),
        G("startResearch", {"count": 1}, 2, gt("افتح دفتر ستّي وبلّش بحث", "افتحي دفتر ستّي وبلّشي بحث")),
        G("sendSupplyRun", {"count": 1}, 2, gv("ابعت", "أوّل رحلة توريد")),
        G("allStationsLevel", {"level": 50}, 3, gv("كبّر", "كل المحطّات لمستوى {n}")),
        G("earnCash", {"amountBase": 3.16e10}, 3, gv("اربح", "{amount} جنيه", prefix="تاج القدس: ")),
    ]

# ---------------------------------------------------------------- story
# Lines: (speaker, text) ; text = str or (m, f)
# Scene: (trigger, param, lines, rewards) ; trigger "goal" -> manual + "goal:<goalId>"
#   param for "goal": template row "T<n>" (cities 2-24) or goal number (Jerusalem)
def L(sp, m, f=None): return (sp, gt(m, f))

def cards(cid, n): return [{"type": "chefCards", "id": cid, "amount": n}]
def cards_r(r, n): return [{"type": "chefCards", "rarity": r, "amount": n}]

STORY = {}

STORY["jerusalem"] = [
 ("arrival", None, [
   L("sitti", "هاي بسطة جدّك أبو خليل، الله يرحمه. صارت إلك يا حبيبي.",
              "هاي بسطة جدّك أبو خليل، الله يرحمه. صارت إلك يا حبيبتي."),
   L("player", "والله يا ستّي ما رح أخذلك."),
   L("sitti", "يلا، الزيت حامي والقدس صاحية بكّير.")], None),
 ("rival", 0.25, [
   L("rival", "أهلين بالجار الجديد! فلافلي أطيب فلافل بالقدس… بس منشوف.",
              "أهلين بالجارة الجديدة! فلافلي أطيب فلافل بالقدس… بس منشوف."),
   L("sitti", "لا تخاف منه، قلبه طيّب، بسّ بموت بالمنافسة.", "لا تخافي منه، قلبه طيّب، بسّ بموت بالمنافسة."),
   L("rival", "إذا وصلت الفلافل لمستوى 25، بعزمك على كاسة شاي.")], None),
 ("goal", 12, [
   L("abuAlAbed", "يا جماعة! سوّاقين التكسي صاروا يوقفوا عندك بالدور."),
   L("abuAlAbed", "أنا أبو العبد، أوّل زبون بالصبح وآخر زبون بالليل."),
   L("player", "أهلا أبو العبد، السندويشة الأولى على حسابي!"),
   L("abuAlAbed", "الله يخلّيك! من اليوم التكسي تحت أمرك، لوين ما بدّك.")], None),
 ("midpoint", 0.5, [
   L("sitti", "سمعت إنّه الطابور واصل لباب العامود!"),
   L("player", "كلّه من وصفتك يا ستّي."),
   L("sitti", "الوصفة نصّ الشغل، والنصّ التاني ابتسامتك.")], None),
 ("goal", 16, [
   L("lina", "عمّو! ماما بتقول فلافلك أطيب من فلافل أبو شاكر.",
             "خالتو! ماما بتقول فلافلك أطيب من فلافل أبو شاكر."),
   L("rival", "سمعتك يا لينا! بكرة بجيبلك قرص ببلاش."),
   L("lina", "طب أنا بحبّ الاتنين… بسّ الحمّص هون أطيب!"),
   L("sitti", "شايف؟ الولاد ما بكذبوا. يلا كمّل.", "شايفة؟ الولاد ما بكذبوا. يلا كمّلي.")], None),
 ("goal", 19, [
   L("rival", "يا جار، وعد الحرّ دين. تفضّل كاسة شاي بالنعنع.",
              "يا جارة، وعد الحرّ دين. تفضّلي كاسة شاي بالنعنع."),
   L("player", "تسلم إيدك يا أبو شاكر. شايك ولا أطيب."),
   L("rival", "بيني وبينك… سرّ فلافلي كمّون محمّص. لا تقول لحدا!",
              "بيني وبينك… سرّ فلافلي كمّون محمّص. لا تقولي لحدا!"),
   L("sitti", "شفت؟ المنافسة الحلوة بتعمل جيران أحلى.", "شفتي؟ المنافسة الحلوة بتعمل جيران أحلى.")], None),
 ("finale", None, [
   L("rival", "والله طلعت قدّها! البسطة صارت فرع، وأنا ضلّيت جارك.",
              "والله طلعتي قدّها! البسطة صارت فرع، وأنا ضلّيت جارك."),
   L("sitti", "بيت لحم ناطرتك، هناك الكستنا والسحلب وناس بتحب الضيف."),
   L("abuAlAbed", "التكسي جاهز! يلا عبيت لحم، الطريق عليّ."),
   L("player", "يلا عبيت لحم!")], cards("ummMohammad", 3)),
]

STORY["bethlehem"] = [
 ("arrival", None, [
   L("abuAlAbed", "وصلنا ساحة المهد! شامم ريحة الكستنا؟", "وصلنا ساحة المهد! شامّة ريحة الكستنا؟"),
   L("sitti", "بيت لحم بتستقبل الدنيا كلّها. خلّي بابك مفتوح."),
   L("player", "رح أعمل أطيب كستنا وشوربة عدس بالساحة!")], None),
 ("goal", "T5", [
   L("guideIssa", "أنا عيسى، دليل سياحي. كل شوي بجيب باص سيّاح!"),
   L("guideIssa", "لما يوصل الباص، استقبله بسرعة قبل ما يكمّل طريقه.",
                  "لما يوصل الباص، استقبليه بسرعة قبل ما يكمّل طريقه."),
   L("player", "أهلا وسهلا بالضيوف! الكستنا سخنة والسحلب جاهز.")], None),
 ("rival", 0.25, [
   L("rival", "كستنا جريس هون بالساحة من أيّام جدّي، يا ابني.",
              "كستنا جريس هون بالساحة من أيّام جدّي، يا بنتي."),
   L("rival", "بسّ بحبّ المنافسة الشريفة. منشوف مين بيدفّي السيّاح أكتر."),
   L("sitti", "جريس كان صاحب جدّك. اتعلّم منه، ما بتخسر.", "جريس كان صاحب جدّك. اتعلّمي منه، ما بتخسري.")], None),
 ("goal", "T12", [
   L("guideIssa", "الجماعة اللي من البرازيل بدّهم سحلب كمان!"),
   L("player", "سحلب بالقرفة والجوز، على أصوله."),
   L("guideIssa", "قالولي: أطيب إشي أكلناه بكل الرحلة!")], None),
 ("midpoint", 0.5, [
   L("sitti", "سمعت إنّه السيّاح صاروا يصوّروا بسطتك!"),
   L("sitti", "تذكّر: الضيف ضيف الله، أكرمه بيوسع رزقك.", "تذكّري: الضيف ضيف الله، أكرميه بيوسع رزقك."),
   L("player", "حاضر يا ستّي، الشوربة دايماً سخنة.")], None),
 ("goal", "T14", [
   L("rival", "اليوم السيّاح وقفوا عندك قبلي… أوّل مرّة من أربعين سنة!"),
   L("rival", "مبروك. بسّ الكستنا تبعتي لسّا أطيب، ما تزعل.", "مبروك. بسّ الكستنا تبعتي لسّا أطيب، ما تزعلي."),
   L("player", "صفقة يا خواجة: سحلب منّي وكستنا منّك؟"),
   L("rival", "صفقة! هيك بتصير الساحة أحلى.")], None),
 ("finale", None, [
   L("rival", "بكل عيد ميلاد، إلك كاسة سحلب عندي ببلاش."),
   L("sitti", "نابلس ناطرتك، والكنافة هناك بدها إيد حلوة وصبر."),
   L("player", "يلا على نابلس، دمشق الصغرى!")], cards("abuSalimSweets", 3)),
]

STORY["nablus"] = [
 ("arrival", None, [
   L("abuAlAbed", "نابلس! بين جبلين، وريحة الكنافة من أوّل الشارع."),
   L("sitti", "هون تعلّمت أعمل الكنافة لما كنت عروس."),
   L("sitti", "بسّ انتبه، النابلسيّة بيعرفوا الكنافة من نظرة.", "بسّ انتبهي، النابلسيّة بيعرفوا الكنافة من نظرة.")], None),
 ("goal", "T5", [
   L("rival", "أنا أبو حمدي. الكنافة يا بتطلع مظبوطة يا بلاش."),
   L("rival", "لما تلمع الصينيّة، دقّ عليها فوراً. ثانية بتفرق!", "لما تلمع الصينيّة، دقّي عليها فوراً. ثانية بتفرق!"),
   L("player", "خمس صواني مظبوطة! شو رأيك يا معلّم؟"),
   L("rival", "مش بطّال… للمبتدئين.")], None),
 ("rival", 0.25, [
   L("rival", "صوانيك صارت تلمع… بسّ الكنافة مش بسّ توقيت."),
   L("rival", "سرّ الكنافة النابلسيّة بالجبنة، والجبنة سرّها بالنقع."),
   L("sitti", "أبو حمدي بيحكي قاسي، بسّ بيعطي السرّ للي بيستاهله.")], None),
 ("goal", "T12", [
   L("soapMaker", "أنا أبو نضال، صابونجي من أربعين سنة."),
   L("soapMaker", "بتعرف شو بيشبه الصابون والكنافة؟ الصبر.", "بتعرفي شو بيشبه الصابون والكنافة؟ الصبر."),
   L("player", "والزيت البلدي كمان!"),
   L("soapMaker", "صح! خذ هالصابونة، ريحتها زيت زيتون.", "صح! خذي هالصابونة، ريحتها زيت زيتون.")], None),
 ("midpoint", 0.5, [
   L("sitti", "قالولي أبو حمدي أكل من كنافتك وما حكى ولا كلمة."),
   L("player", "يعني منيح ولا عاطل يا ستّي؟"),
   L("sitti", "عند أبو حمدي، السكوت يعني مدح كبير!")], None),
 ("goal", "T14", [
   L("rival", "أربعين صينيّة مظبوطة؟ والله صرت كنفاني!", "أربعين صينيّة مظبوطة؟ والله صرتي كنفانيّة!"),
   L("rival", "تعال، بفرجيك كيف بتنقع الجبنة بالليل.", "تعالي، بفرجيكي كيف بتنقعي الجبنة بالليل."),
   L("player", "شرف إلي يا معلّم!")], None),
 ("finale", None, [
   L("rival", "الكنافة إلها إيدين بنابلس هلّق: إيدي وإيدك."),
   L("sitti", "الخليل ناطرتك، موسم العنب بلّش والدبس بدّه صبر."),
   L("player", "يلا عالخليل، أنا جاي يا عنب!", "يلا عالخليل، أنا جاية يا عنب!")], cards("abuAbedFul", 3)),
]

STORY["hebron"] = [
 ("arrival", None, [
   L("abuAlAbed", "الخليل! ريحة العنب واصلة لآخر الطريق."),
   L("sitti", "أهل الخليل كرماء، والقدرة عندهم بتنطبخ بفرن الحارة."),
   L("player", "جبت الفلافل معي… وبدّي أتعلّم القدرة!")], None),
 ("goal", "T5", [
   L("rival", "أنا أبو العز. الدبس ما بيجي من الهوا، بدّه عنب."),
   L("rival", "كل ما زاد العنب، زاد الدبس وزاد الربح."),
   L("player", "يعني العنب ما بينباع؟ كلّه للدبس؟"),
   L("rival", "العنب بيشتغل للدبس، والدبس بيشتغل لجيبتك!")], None),
 ("rival", 0.25, [
   L("rival", "دبس أبو العز معروف من الخليل لعمّان."),
   L("rival", "إذا دبسك طلع أطيب من دبسي، ببوس راسك."),
   L("sitti", "أبو العز بيحلف بالعنب، وعنبه بيستاهل.")], None),
 ("goal", "T12", [
   L("glassSaeed", "أنا سعيد، بنفخ زجاج خليلي. شوف هالأزرق!", "أنا سعيد، بنفخ زجاج خليلي. شوفي هالأزرق!"),
   L("glassSaeed", "عملتلك كاسات للبسطة، الشاي فيها بيصير أحلى."),
   L("player", "يا سلام! ألوانها زيّ غروب الخليل.")], None),
 ("midpoint", 0.5, [
   L("sitti", "سمعت إنّك صرت تطبخ قدرة بفرن الحارة!", "سمعت إنّك صرتي تطبخي قدرة بفرن الحارة!"),
   L("player", "أهل الخليل علّموني، والطابور بيلفّ الحارة."),
   L("sitti", "اللي بدّه يعمل جمّال بعلّي باب داره. كبّر بسطتك!",
              "اللي بدّه يعمل جمّال بعلّي باب داره. كبّري بسطتك!")], None),
 ("goal", "T14", [
   L("rival", "ذقت دبسك اليوم… وعدتك أبوس راسك؟"),
   L("rival", "رح أبوس راسك وإيديك كمان! والله أطيب من دبسي."),
   L("player", "كلّه من عنبك يا أبو العز.")], None),
 ("finale", None, [
   L("rival", "خذ تنكة دبس للطريق، وسلّملي على البحر.", "خذي تنكة دبس للطريق، وسلّميلي على البحر."),
   L("sitti", "يافا ناطرتك، البرتقال والبحر والسفن، وأم يوسف كمان."),
   L("player", "يلا على يافا، عروس البحر!")], cards("khaledSea", 3)),
]

STORY["jaffa"] = [
 ("arrival", None, [
   L("abuAlAbed", "يافا، عروس البحر! البيّارات يمين والبحر شمال."),
   L("sitti", "برتقال يافا كان يسافر عالدنيا كلّها بالسفن."),
   L("player", "وهلّق رح يسافر من بسطتنا!")], None),
 ("goal", "T5", [
   L("portGuard", "أنا أبو عمر، حارس الميناء. السفينة رست، بدها برتقال!"),
   L("portGuard", "عبّي الصندوق برتقال قبل ما تطلع السفينة."),
   L("player", "أوّل شحنة طلعت! يا عيني على البرتقال.")], None),
 ("rival", 0.25, [
   L("rival", "أنا أم يوسف، ريّسة مطبخ الميناء. السمك عندي من البحر للصحن."),
   L("rival", "إنت فلافلي… شو بتعرف عن الصيّاديّة؟", "إنتِ فلافليّة… شو بتعرفي عن الصيّاديّة؟"),
   L("sitti", "أم يوسف قويّة، بسّ قلبها أبيض زيّ الملح.")], None),
 ("goal", "T12", [
   L("portGuard", "البحّارة صاروا يطلبوا سندويشاتك قبل ما ينزلوا!"),
   L("player", "سمك مقلي وعصير برتقال، أحلى ترويقة."),
   L("portGuard", "بكرة بجيبلك قبطان السفينة الكبيرة، حضّرله صحن.", "بكرة بجيبلك قبطان السفينة الكبيرة، حضّريله صحن.")], None),
 ("midpoint", 0.5, [
   L("sitti", "قالولي أم يوسف صارت تبعتلك زباينها!"),
   L("player", "والله يا ستّي، صرنا نتبادل السمك والفلافل."),
   L("sitti", "البحر واسع، بيساع كل الصيّادين.")], None),
 ("goal", "T14", [
   L("rival", "أربع شحنات! السفن صارت تستنّى برتقالك."),
   L("rival", "اسمع، تعال اطبخ معي الصيّاديّة، بعلّمك سرّها.", "اسمعي، تعالي اطبخي معي الصيّاديّة، بعلّمك سرّها."),
   L("player", "وأنا بعلّمك سرّ الفلافل… نصّ بنصّ!")], None),
 ("finale", None, [
   L("rival", "يافا فتحتلك قلبها. السفينة الجاي، إلك صندوق برتقال هديّة."),
   L("sitti", "حيفا على الكرمل ناطرتك، ونزار هناك سريع كتير."),
   L("player", "يلا على حيفا، بسّ البحر رح يضلّ معي!")], cards("hassanGrill", 3)),
]

STORY["haifa"] = [
 ("arrival", None, [
   L("abuAlAbed", "حيفا! الكرمل فوق والبحر تحت، والسكوترات بكل مكان."),
   L("sitti", "أهل حيفا مستعجلين، بدّهم الأكل يوصلهم لعند الباب."),
   L("player", "منيح، منوصّلهم الأكل لحدّ الباب!")], None),
 ("goal", "T5", [
   L("riderMajd", "أنا مجد! عندي سكوتر وبعرف كل درج بالكرمل."),
   L("riderMajd", "لما يجي طلب، ابعتني وأنا بطير فيه.", "لما يجي طلب، ابعتيني وأنا بطير فيه."),
   L("player", "تلات طلبات وصلت سخنة! برافو يا مجد.")], None),
 ("rival", 0.25, [
   L("rival", "نزار الشاورماتي! أسرع شاورما بحيفا، بتوصل قبل ما تطلبها."),
   L("rival", "الطابور موضة قديمة. المستقبل للدليفري يا صاحبي.", "الطابور موضة قديمة. المستقبل للدليفري يا صاحبتي."),
   L("sitti", "نزار شاطر، بسّ الأكل الطيّب بيوصل حتى لو مشي.")], None),
 ("goal", "T12", [
   L("riderMajd", "طلعت درج الكرمل كلّه… والفلافل لسّا سخنة!"),
   L("player", "يعطيك العافية! خذ صحن بطاطا على حسابي."),
   L("riderMajd", "وبدّي قهوة الكرمل كمان، بتصحّي الميّت!")], None),
 ("midpoint", 0.5, [
   L("sitti", "شو؟ صار عندك سكوترات كمان؟ جدّك كان عنده حمار!"),
   L("player", "والحمار كان أسرع من سكوترات نزار، صح؟"),
   L("sitti", "الله يرحمه، كان يسابق التكسيات فيه.")], None),
 ("goal", "T14", [
   L("rival", "عشرين طلب وصلوا قبل طلباتي؟ مش معقول!"),
   L("rival", "ماشي، بعترف: شاورمتي سريعة، بسّ كبّتك أطيب."),
   L("player", "شو رأيك نعمل صحن مشترك؟ كبّة وشاورما."),
   L("rival", "فكرة مجنونة… بحبّها!")], None),
 ("finale", None, [
   L("rival", "حيفا رح تشتاقلك. ومجد بيقول بدّه يوصّل طلباتك لغزّة!"),
   L("sitti", "غزّة ناطرتك، البحر والشمس وأبو رامي الصيّاد."),
   L("player", "يلا على غزّة، البحر بيستنّانا!")], cards("hajjaUmmSubhi", 2)),
]

STORY["gaza"] = [
 ("arrival", None, [
   L("abuAlAbed", "غزّة! شوف البحر قدّيش أزرق، والعيل قاعدة عالرملة.", "غزّة! شوفي البحر قدّيش أزرق، والعيل قاعدة عالرملة."),
   L("sitti", "أهل غزّة بحبّوا الأكل الحرّاق والقلب الكبير."),
   L("player", "جبت معي شطّة، وجبت قلبي كمان!")], None),
 ("goal", "T5", [
   L("hammouda", "أنا حمّودة! لما تشوب الدنيا، الكل بيركض عالبطّيخ!"),
   L("hammouda", "ولما تبرد، بدّهم سمّاقيّة وزبديّة سخنة."),
   L("sitti", "راقب الطقس كل يوم، وغيّر عروضك عليه.", "راقبي الطقس كل يوم، وغيّري عروضك عليه.")], None),
 ("rival", 0.25, [
   L("rival", "أنا أبو رامي، صيّاد من وأنا بعمر حمّودة."),
   L("rival", "الدقّة الغزّاويّة بدها شطّة وثوم وليمون… وجرأة!"),
   L("rival", "بتقدر توكل ملعقة دقّة بدون مي؟", "بتقدري توكلي ملعقة دقّة بدون مي؟"),
   L("player", "مي! بسرعة مي!")], None),
 ("goal", "T12", [
   L("hammouda", "عمّو، ممكن شقفة بطّيخ؟ مصرياتي خلصوا…", "خالتو، ممكن شقفة بطّيخ؟ مصرياتي خلصوا…"),
   L("player", "تعال يا بطل، البطّيخة كلّها على حسابي."),
   L("hammouda", "لما أكبر بدّي أصير طبّاخ زيّك!", "لما أكبر بدّي أصير طبّاخ زيّك يا خالتو!")], None),
 ("midpoint", 0.5, [
   L("sitti", "قالولي أبو رامي صار يجيبلك أحسن سمك عنده."),
   L("player", "بيقول سمكه بيستاهل إيد بتعرف تشويه."),
   L("sitti", "اللي بيشكر الصيّاد، البحر بيكرمه.")], None),
 ("goal", "T14", [
   L("rival", "اليوم طلعت بالفلوكة الصبح، وأوّل سمكة إلك."),
   L("rival", "صرت من أهل البحر يا ابني.", "صرتي من أهل البحر يا بنتي."),
   L("player", "وإنت صرت عمّي يا أبو رامي.")], None),
 ("finale", None, [
   L("rival", "ارجع زورنا بالصيف، البحر رح يسأل عنك.", "ارجعي زورينا بالصيف، البحر رح يسأل عنك."),
   L("sitti", "رام الله ناطرتك، مدينة ما بتنام، وسلمى هناك."),
   L("sitti", "وأنا كمان رح أجي… عندي مفاجأة."),
   L("player", "مفاجأة؟ يلا على رام الله بسرعة!")], cards("laylaStudent", 3)),
]

STORY["ramallah"] = [
 ("arrival", None, [
   L("abuAlAbed", "رام الله! الساعة عشرة بالليل والدوّار لسّا مليان."),
   L("sitti", "رام الله شابّة، بتحبّ القهوة والسهر والموسيقى."),
   L("player", "يعني لازم أفتح لنصّ الليل؟"),
   L("sitti", "لنصّ الليل وأكتر، يا قلبي.")], None),
 ("goal", "T5", [
   L("yazan", "أنا يزن، طالب جامعة. منقعد ندرس… ومنجوع الساعة 11!"),
   L("yazan", "بالليل الكل بيطلب صحن شاورما وكنافة بالكاسة."),
   L("player", "تمام، سوق الليل فتح! والأسعار حلوة للطلّاب.")], None),
 ("rival", 0.25, [
   L("rival", "أنا سلمى، صاحبة كافيه سلمى. الكابتشينو عندي فنّ."),
   L("rival", "إنت فلافلي… بتعرف شو يعني رسمة عالقهوة؟", "إنتِ فلافليّة… بتعرفي شو يعني رسمة عالقهوة؟"),
   L("player", "بعرف أرسم قلب بالطحينة، بيكفّي؟"),
   L("rival", "ماشي! منشوف مين بيسهّر رام الله.")], None),
 ("goal", "T12", [
   L("yazan", "نجحت بالامتحان! كلّه من سندويشات الفلافل بالليل."),
   L("player", "مبروك يا دكتور! السندويشة اليوم ببلاش."),
   L("yazan", "ونصّ الدفعة جاي يحتفل عندك الليلة!")], None),
 ("midpoint", 0.5, [
   L("sitti", "بتعرف إنّي كنت أبيع عرق سوس بالمنارة زمان؟", "بتعرفي إنّي كنت أبيع عرق سوس بالمنارة زمان؟"),
   L("player", "إنتِ يا ستّي؟ بالمنارة؟"),
   L("sitti", "كان صوتي يوصل لبيرزيت: سوس… سوس بارد!")], None),
 ("goal", "T15", [
   L("rival", "اسمع، شو رأيك نعمل سوق ليل مشترك؟ قهوتي وأكلك.", "اسمعي، شو رأيك نعمل سوق ليل مشترك؟ قهوتي وأكلك."),
   L("player", "فكرة حلوة! الناس بتتعشّى عنّا وبتتحلّى عندك."),
   L("rival", "اتّفقنا. رام الله أحلى لما نشتغل سوا.")], None),
 ("finale", None, [
   L("rival", "بسطتك صارت جزء من ليل رام الله. رح نشتاقلك."),
   L("sitti", "لفّيت فلسطين كلّها يا عمري. أنا فخورة فيك.", "لفّيتي فلسطين كلّها يا عمري. أنا فخورة فيكي."),
   L("sitti", "والمفاجأة؟ أنا جاية معك! حطّني بالمطبخ.", "والمفاجأة؟ أنا جاية معك! حطّيني بالمطبخ."),
   L("player", "ستّي بالفريق؟ يا سلام! يلا على عمّان!")], cards("sittiUmmKhalil", 1)),
]

STORY["amman"] = [
 ("arrival", None, [
   L("samer", "أهلين بعمّان! أنا سامر ابن عمّك، رح أرتّبلك كل الأوراق."),
   L("sitti", "عمّان مدينة الجبال السبعة، وأهلها أهلنا."),
   L("player", "أوّل مدينة برّا فلسطين… قلبي بيدقّ!")], None),
 ("goal", "T5", [
   L("rival", "أنا أبو عودة. المنسف بدّه جميد، والجميد بدّه حليب."),
   L("rival", "الحليب بيصير جميد، والجميد بيصير منسف. ولا خطوة بتنطّ!"),
   L("player", "يعني سلسلة من تلات محطّات؟ تحدّي!")], None),
 ("rival", 0.25, [
   L("rival", "عرس ابن أبو صالح الشهر الجاي: خمسمية ضيف ومنسف للكل."),
   L("rival", "إذا طبخت المنسف معي، بتصير منّا وفينا.", "إذا طبختي المنسف معي، بتصيري منّا وفينا."),
   L("sitti", "المنسف بالإيد اليمين، والكرم بالإيدين التنتين.")], None),
 ("goal", "T12", [
   L("groomFather", "أنا أبو صالح، أبو العريس. بدّي أحلى منسف بعمّان!"),
   L("groomFather", "خمسمية ضيف، والكل لازم يطلع مبسوط."),
   L("player", "على راسي يا عمّ! الجميد كركي والرز مفلفل.")], None),
 ("midpoint", 0.5, [
   L("samer", "خلّصت أوراق الفرع، وسجّلت البسطة بدفتر البلديّة."),
   L("sitti", "ابن عمّك سامر ذهب، بيرتّب الدنيا وإنت بتطبخ.", "ابن عمّك سامر ذهب، بيرتّب الدنيا وإنتِ بتطبخي."),
   L("player", "الشغل العيلي أحلى شغل!")], None),
 ("goal", "T15", [
   L("groomFather", "العرس كان أسطورة! الناس لسّا بتحكي عن المنسف."),
   L("rival", "والله يا جماعة، المنسف كان أطيب من منسفي… شوي."),
   L("player", "شوي بس؟ ماشي يا أبو عودة، بقبلها!")], None),
 ("finale", None, [
   L("rival", "إلك دار بعمّان. كل ما تمرق، القهوة جاهزة.", "إلك دار بعمّان. كل ما تمرقي، القهوة جاهزة."),
   L("samer", "بيروت جاهزة، حجزتلك محلّ عالكورنيش."),
   L("sitti", "بيروت بتحبّ الحياة، وطوني هناك ما بينام.")], cards("abuGeorgeHalabi", 2)),
]

STORY["beirut"] = [
 ("arrival", None, [
   L("samer", "بيروت! الكورنيش هون، والبحر بيسلّم عليك.", "بيروت! الكورنيش هون، والبحر بيسلّم عليكِ."),
   L("sitti", "اللبنانيّة بيحبّوا الترويقة: منقوشة زعتر وكاسة شاي."),
   L("player", "والزعتر عنّا من جبال فلسطين، أكيد رح يعجبهم!")], None),
 ("goal", "T5", [
   L("singerRita", "أنا ريتا، بغنّي عالكورنيش كل ليلة."),
   L("singerRita", "بعد الساعة تسعة، الناس بتنزل وبتجوع… كتير!"),
   L("player", "إذن سوق الليل فتح، والغنيّة علينا!")], None),
 ("rival", 0.25, [
   L("rival", "أهلا بالجار! أنا طوني، ملك الصفيحة ببيروت.", "أهلا بالجارة! أنا طوني، ملك الصفيحة ببيروت."),
   L("rival", "منقوشتك حلوة، بسّ صفيحتي بتخلّي الناس تغنّي."),
   L("rival", "الساعة وحدة بالليل، منشوف الناس عند مين واقفة.")], None),
 ("goal", "T12", [
   L("singerRita", "كتبت غنيّة عن بسطتك! اسمها: يا زعتر يا حبيبي."),
   L("player", "يا سلام! غنّيها الليلة، والحلاوة علينا."),
   L("singerRita", "صار عندك معجبين، انتبه عالطابور!", "صار عندك معجبين، انتبهي عالطابور!")], None),
 ("midpoint", 0.5, [
   L("sitti", "قالولي الناس عالكورنيش صاروا يرقصوا عند بسطتك!"),
   L("player", "ريتا بتغنّي وأنا بخبز، صارت حفلة كل ليلة."),
   L("sitti", "الأكل الطيّب بدّه مزاج حلو. كمّل يا فنّان.", "الأكل الطيّب بدّه مزاج حلو. كمّلي يا فنّانة.")], None),
 ("goal", "T14", [
   L("rival", "الساعة وحدة، والطابور عندك أطول من عندي…"),
   L("rival", "ماشي! من بكرة منعمل صحن مشترك: نصّ منقوشة ونصّ صفيحة."),
   L("player", "واسمه رح يكون: صفيوشة!")], None),
 ("finale", None, [
   L("rival", "بيروت ما بتودّع، بتقول: لنشوفك قريب!"),
   L("samer", "الشام جاهزة، والسوق القديم بيستنّاك."),
   L("sitti", "الشام قلب العرب، وهناك أطيب بوظة بالدنيا.")], cards("abuSalimSweets", 4)),
]

STORY["damascus"] = [
 ("arrival", None, [
   L("samer", "الشام! سوق الحميديّة طويل، والناس ما بتخلص."),
   L("sitti", "بالشام كل حجر إله حكاية، وكل صحن إله تاريخ."),
   L("player", "رح أعمل مسبّحة تخلّي الحكاية تكمل.")], None),
 ("goal", "T5", [
   L("hakawati", "أنا أبو راشد الحكواتي. كل شوي بتفوت جماعة سيّاح للسوق."),
   L("hakawati", "استقبلهم بسرعة، وأنا بحكيلهم عن بسطتك.", "استقبليهم بسرعة، وأنا بحكيلهم عن بسطتك."),
   L("player", "أوّل جماعة! أهلا وسهلا بالشام.")], None),
 ("rival", 0.25, [
   L("rival", "أنا أبو صيّاح! بدقّ البوظة عالإيقاع، دم تك تك!"),
   L("rival", "بتقدر تلحقني؟ كل دقّة بتجيب زبون.", "بتقدري تلحقيني؟ كل دقّة بتجيب زبون."),
   L("player", "بدقّ الفلافل أسرع من بوظتك يا أبو صيّاح!")], None),
 ("goal", "T12", [
   L("hakawati", "الليلة بحكي حكاية جديدة: الفلافلي اللي إجا من القدس.",
                 "الليلة بحكي حكاية جديدة: الفلافليّة اللي إجت من القدس."),
   L("player", "وشو آخر الحكاية؟"),
   L("hakawati", "آخرها لسّا ما انكتب… إنت اللي بتكتبه.", "آخرها لسّا ما انكتب… إنتِ اللي بتكتبيه.")], None),
 ("midpoint", 0.5, [
   L("sitti", "جدّك أخذني عالشام بشهر العسل، أكلنا بوظة بالفستق."),
   L("player", "يعني أنا هون عشان أكمّل الحكاية؟"),
   L("sitti", "إيه يا عمري، وكمّلها حلوة زيّ البوظة.", "إيه يا عمري، وكمّليها حلوة زيّ البوظة.")], None),
 ("goal", "T14", [
   L("rival", "خمس جماعات بيوم واحد؟ إيدك صارت أسرع من إيدي!"),
   L("rival", "تعال، دقّ معي البوظة. إذا لحقت الإيقاع، بتصير شامي.",
              "تعالي، دقّي معي البوظة. إذا لحقتي الإيقاع، بتصيري شاميّة."),
   L("player", "دم تك تك… دم تك! هيك؟"),
   L("rival", "قرّبت! بكرة بتصير معلّم.", "قرّبتي! بكرة بتصيري معلّمة.")], None),
 ("finale", None, [
   L("rival", "الشام فتحتلك بابها، وبوظتي إلك ببلاش طول العمر."),
   L("samer", "القاهرة جاهزة! بسّ انتبه… هناك اسمها طعميّة مش فلافل.",
              "القاهرة جاهزة! بسّ انتبهي… هناك اسمها طعميّة مش فلافل."),
   L("sitti", "مصر أمّ الدنيا، وعم صابر هناك بيعرف كل زاروب.")], cards("nadiaCairo", 3)),
]

STORY["cairo"] = [
 ("arrival", None, [
   L("samer", "القاهرة! زحمة وزمامير، وريحة طعميّة بكل شارع."),
   L("sitti", "المصريّين بيعملوا الطعميّة من الفول، مش من الحمّص."),
   L("player", "فول؟! بجرّبها… بسّ فلافلنا ما بتتنازل!")], None),
 ("goal", "T5", [
   L("bawwab", "أنا عم حسنين، بوّاب العمارة. السكّان كلّهم عايزين دليفري!"),
   L("bawwab", "الدور العاشر عايز فول، والسابع عايز كشري… يلا يا باشا!",
               "الدور العاشر عايز فول، والسابع عايز كشري… يلا يا هانم!"),
   L("player", "تلات طلبات طلعوا! عم حسنين، إنت أحسن مدير طلبات.")], None),
 ("rival", 0.25, [
   L("rival", "إزيّك يا فلسطيني؟ أنا عم صابر، ملك الطعميّة والدليفري.",
              "إزيّك يا فلسطينيّة؟ أنا عم صابر، ملك الطعميّة والدليفري."),
   L("rival", "عجلاتي بتعرف كل حارة بالقاهرة، حتّى اللي مش عالخريطة."),
   L("rival", "فلافل ولا طعميّة؟ الشارع هو اللي هيحكم!")], None),
 ("goal", "T12", [
   L("bawwab", "مدام الدور التالت بتقول أم علي بتاعتك أحلى من بتاعة أمّها!"),
   L("player", "لا يا عمّ، ما بدنا مشاكل عيليّة!"),
   L("bawwab", "ما تخافش، أمّها هي اللي طلبت الصحن التاني!", "ما تخافيش، أمّها هي اللي طلبت الصحن التاني!")], None),
 ("midpoint", 0.5, [
   L("sitti", "سمعت إنّك عملت صحن فلافل وطعميّة جنب بعض!", "سمعت إنّك عملتي صحن فلافل وطعميّة جنب بعض!"),
   L("player", "والناس انقسموا: نصّ مع هاي ونصّ مع هاي."),
   L("sitti", "الحمّص والفول إخوة، والفلافل والطعميّة ولاد عمّ.")], None),
 ("goal", "T14", [
   L("rival", "عشرين طلب في يوم واحد؟ ده إنت عفريت!", "عشرين طلب في يوم واحد؟ ده إنتي عفريتة!"),
   L("rival", "خلاص، عجلاتي تحت أمرك. نوصّل طعميّة وفلافل مع بعض."),
   L("player", "اتّفقنا يا عم صابر، الشارع للكل.")], None),
 ("finale", None, [
   L("rival", "مصر هتوحشك، وإنت هتوحشنا أكتر يا باشا.", "مصر هتوحشك، وإنتي هتوحشينا أكتر يا هانم."),
   L("samer", "بغداد جاهزة! على دجلة، والمسكوف بيستنّاك."),
   L("sitti", "أبو جاسم هناك فرنه ما بيستنّى حدا، كون جاهز.", "أبو جاسم هناك فرنه ما بيستنّى حدا، كوني جاهزة.")], cards("karimBaghdadi", 2)),
]

STORY["baghdad"] = [
 ("arrival", None, [
   L("samer", "بغداد! شوف دجلة، والسمك المسكوف عالنار.", "بغداد! شوفي دجلة، والسمك المسكوف عالنار."),
   L("sitti", "البغداديّة كرماء، والشاي عندهم بالاستكان وبالهيل."),
   L("player", "وأنا جايب شطّة وفلافل، يعني منتبادل!", "وأنا جايبة شطّة وفلافل، يعني منتبادل!")], None),
 ("goal", "T5", [
   L("rival", "هلا بيك! أنا أبو جاسم. الصمّون عندي يطلع من الفرن ويطير."),
   L("rival", "لما يحمرّ الصمّون، دقّ عليه فوراً، وإلّا راح عليك.", "لما يحمرّ الصمّون، دقّي عليه فوراً، وإلّا راح عليكِ."),
   L("player", "خمس صمّونات مظبوطة! سخنة ومقرمشة."),
   L("rival", "زين… زين. بسّ الفرن ما يستنّى أحد.")], None),
 ("rival", 0.25, [
   L("rival", "عيني، البغداديّة يعرفون الصمّون الزين من ريحته."),
   L("rival", "إذا صمّونك طلع مثل صمّوني، أعزمك على مسكوف بأبو نوّاس."),
   L("sitti", "أبو جاسم صعب، بسّ لمّا يحبّ حدا، بيحبّه من قلبه.")], None),
 ("goal", "T12", [
   L("ustazNawfal", "أنا الأستاذ نوفل، عندي مكتبة بشارع المتنبّي."),
   L("ustazNawfal", "يقولون: القاهرة تكتب، بيروت تطبع، وبغداد تقرأ… وتاكل!"),
   L("player", "إذا هيك، بعملك سندويشة بحجم كتاب!")], None),
 ("midpoint", 0.5, [
   L("sitti", "بعرف إنّه الشغل صعب بعيد عن البيت. اشتقتلك."),
   L("player", "وأنا اشتقتلك يا ستّي، وللقدس ولبسطة جدّي."),
   L("sitti", "كل فرع فتحته حجر بدار العيلة. كمّل.", "كل فرع فتحتيه حجر بدار العيلة. كمّلي.")], None),
 ("goal", "T14", [
   L("rival", "أربعين صمّونة مظبوطة! والله صرت خبّاز بغدادي.", "أربعين صمّونة مظبوطة! والله صرتي خبّازة بغداديّة."),
   L("rival", "يلا، المسكوف عليّ الليلة بأبو نوّاس، مثل ما وعدتك."),
   L("player", "وأنا جايب الفلافل… وهذا وعدي!", "وأنا جايبة الفلافل… وهذا وعدي!")], None),
 ("finale", None, [
   L("rival", "بغداد ما تنساك. كل ما تطلع صمّونة، أتذكّرك."),
   L("samer", "الرياض جاهزة، بسّ الحرّ هناك ولا مزح!"),
   L("sitti", "أبو سلطان هناك كريم، والقهوة عنده ما بتخلص.")], cards("abuFahdKabsa", 2)),
]

STORY["riyadh"] = [
 ("arrival", None, [
   L("samer", "الرياض! الشمس هون مش مزح، اشرب مي كتير.", "الرياض! الشمس هون مش مزح، اشربي مي كتير."),
   L("sitti", "أهل نجد كرماء، والقهوة عندهم بالهيل والتمر."),
   L("player", "ولقيمات بالدبس! صرت جوعان من هلّق.", "ولقيمات بالدبس! صرت جوعانة من هلّق.")], None),
 ("goal", "T5", [
   L("rival", "هلا والله! أنا أبو سلطان. الطقس هنا يقلب بين يوم ويوم."),
   L("rival", "إذا حرّ: لبن بارد وآيس كريم. إذا برد: قهوة وجريش."),
   L("player", "يعني الطقس هو المعلّم الحقيقي هون!")], None),
 ("rival", 0.25, [
   L("rival", "قهوتي ما يشربها أحد إلّا ويرجع. وش عندك أنت؟", "قهوتي ما يشربها أحد إلّا ويرجع. وش عندك أنتِ؟"),
   L("player", "عندي فلافل… وكبسة تعلّمتها من أهل الرياض."),
   L("rival", "كبسة؟ تبي تنافسني بكبستي؟ أبشر!", "كبسة؟ تبين تنافسيني بكبستي؟ أبشري!")], None),
 ("goal", "T12", [
   L("saad", "أنا سعد، عندي مخيّم بالبرّ. نبي عشا لعشرين نفر!"),
   L("player", "مندي ولقيمات وقهوة، منوصّلها لحدّ الخيمة."),
   L("saad", "كفو! هالعشا بيصير سالفة المخيّم أسبوع كامل.")], None),
 ("midpoint", 0.5, [
   L("sitti", "سمعت إنّه بالصيف اللبن البارد عندك صار ذهب!"),
   L("player", "الناس بتقول: لبنك بيطفّي الحرّ."),
   L("sitti", "الشاطر بيقرأ السما قبل ما يقرأ الدفتر.")], None),
 ("goal", "T14", [
   L("rival", "يا الغالي، كل يوم حرّ والطابور عندك. وش السرّ؟", "يا الغالية، كل يوم حرّ والطابور عندك. وش السرّ؟"),
   L("player", "السرّ إنّي بسمع لأهل البلد، وبحطّ اللبن بالتلج!"),
   L("rival", "كفو! من اليوم قهوتي معك، والضيف ضيفنا سوا.")], None),
 ("finale", None, [
   L("rival", "الرياض صارت ديرتك. ارجع لنا بالشتا، الكشتة عليّ.", "الرياض صارت ديرتك. ارجعي لنا بالشتا، الكشتة عليّ."),
   L("samer", "دبي جاهزة! بسّ هناك الزباين… كبار كتير."),
   L("sitti", "الشيف لؤي هناك بيقول البسطة ما بتليق بالكبار. فرجيه!")], cards("reemCoffee", 2)),
]

STORY["dubai"] = [
 ("arrival", None, [
   L("samer", "دبي! أبراج وسيّارات فخمة، وضيوف من كل الدنيا."),
   L("sitti", "هون الكل مستعجل، بسّ الكل بيحبّ الأكل الطيّب."),
   L("player", "وبسطتنا رح تلمع بين الأبراج!")], None),
 ("goal", "T5", [
   L("mira", "هاي! أنا ميرا، بلوغر أكل. عندي مليون متابع!"),
   L("mira", "الضيوف الكبار بدّهم صالة خاصّة، ولقيمات بالذهب!"),
   L("player", "أوّل ضيف كبير انبسط! الصالة اشتغلت.")], None),
 ("rival", 0.25, [
   L("rival", "أنا الشيف لؤي، مطعمي بالطابق المية. وإنت؟ بسطة؟", "أنا الشيف لؤي، مطعمي بالطابق المية. وإنتِ؟ بسطة؟"),
   L("rival", "الضيوف الكبار ما بياكلوا عالرصيف يا عزيزي.", "الضيوف الكبار ما بياكلوا عالرصيف يا عزيزتي."),
   L("sitti", "خلّيه يحكي. الأكل الطيّب بيطلع للطابق المية لحاله.")], None),
 ("goal", "T12", [
   L("mira", "نزّلت فيديو للقيماتك… صار عليه مليونين مشاهدة!"),
   L("player", "مليونين؟! لازم نكبّر الصالة هسّا."),
   L("mira", "والكل بيسأل: وين البسطة اللي بتلمع؟")], None),
 ("midpoint", 0.5, [
   L("sitti", "شفت؟ البسطة الزغيرة صار إلها اسم بأكبر مدينة.", "شفتي؟ البسطة الزغيرة صار إلها اسم بأكبر مدينة."),
   L("player", "بسّ الفلافل ضلّت نفس فلافل القدس، ما تغيّرت."),
   L("sitti", "هيك صحّ. كبّر المكان، وخلّي الطعمة متل ما هي.", "هيك صحّ. كبّري المكان، وخلّي الطعمة متل ما هي.")], None),
 ("goal", "T14", [
   L("rival", "ستّ ضيوف كبار تركوا مطعمي وإجوا لبسطتك!"),
   L("rival", "طيب… بتعلّمني الفلافل؟ بسّ ما تحكي لحدا.", "طيب… بتعلّميني الفلافل؟ بسّ ما تحكي لحدا."),
   L("player", "على شرط: تعزمني عالطابق المية!")], None),
 ("finale", None, [
   L("rival", "بعترف: البسطة بتليق بالكبار، وإنت أكبر منهم كلّهم.", "بعترف: البسطة بتليق بالكبار، وإنتِ أكبر منهم كلّهم."),
   L("samer", "مراكش جاهزة، والساحة هناك بتولّع كل ليلة."),
   L("sitti", "لالّة زهرة هناك بتطبخ حريرة بتشفي القلب.")], cards("fatimaMaghreb", 3)),
]

STORY["marrakesh"] = [
 ("arrival", None, [
   L("samer", "مراكش! ساحة جامع الفنا: دخان وموسيقى وحكايات."),
   L("sitti", "المغاربة بيحبّوا الضيف، وأتاي عندهم بالنعناع والسكّر."),
   L("player", "شاي بالنعنع؟ زيّ القدس بالضبط!")], None),
 ("goal", "T5", [
   L("idris", "مرحبا بيك! أنا إدريس. الساحة بالنهار عاديّة، وبالليل بتولّع!"),
   L("idris", "من المغرب للساعة وحدة، الناس بتاكل بزّاف."),
   L("player", "واخا! سوق الليل فتح، حريرة وأتاي للكل.")], None),
 ("rival", 0.25, [
   L("rival", "مرحبا! أنا لالّة زهرة، حريرتي مشهورة من أيّام جدّتي."),
   L("rival", "الساحة بتساع الكل، بسّ الحريرة… ما كاين غير حريرة زهرة!"),
   L("sitti", "لالّة زهرة متلي، ستّ بتطبخ بقلبها. احترمها.", "لالّة زهرة متلي، ستّ بتطبخ بقلبها. احترميها.")], None),
 ("goal", "T12", [
   L("idris", "جماعة سيّاح نزلوا من الحافلة، كلّهم بدّهم مسمّن!"),
   L("player", "مسمّن بالعسل والزبدة؟ جاهز!", "مسمّن بالعسل والزبدة؟ جاهزة!"),
   L("idris", "والله زوين بزّاف! غادي يرجعوا كل يوم.")], None),
 ("midpoint", 0.5, [
   L("sitti", "بتذكر لما حكيتلك عن مراكش وإنت زغير؟", "بتذكري لما حكيتلك عن مراكش وإنتِ زغيرة؟"),
   L("player", "إيه! قلتيلي فيها نجوم أكتر من السما."),
   L("sitti", "النجوم هي فوانيس الساحة، وهلّق فانوسك منهم.")], None),
 ("goal", "T14", [
   L("rival", "الليلة الطابور عندك وصل لعندي! شنو هاد؟"),
   L("rival", "واخا… نتشاركوا: حريرتي مع فلافلك، بصحن واحد."),
   L("player", "صحن الساحة! اسمه حريرة وفلافل.")], None),
 ("finale", None, [
   L("rival", "مراكش غادي توحشك. الحريرة ديالي ديما إلك."),
   L("samer", "إسطنبول جاهزة! البوسفور والعبّارات والسميت."),
   L("sitti", "الأسطى كمال هناك بيقول الفلافل تركيّة… بدّها نقاش!")], cards("muratGrill", 3)),
]

STORY["istanbul"] = [
 ("arrival", None, [
   L("samer", "إسطنبول! قارّتين ومدينة وحدة، والعبّارات رايحة جاية."),
   L("sitti", "الأتراك بيحبّوا الشاي بكاسات زغار، وكتير!"),
   L("player", "وأنا بحبّ الكاسات الزغار، بشرب أكتر!")], None),
 ("goal", "T5", [
   L("ayse", "أهلين! أنا عائشة، ببيع شاي عالعبّارة."),
   L("ayse", "قوارب الصيّادين بترسى، والركّاب بدّهم سندويشات سمك!"),
   L("player", "أوّل شحنة سندويشات طلعت عالقارب!")], None),
 ("rival", 0.25, [
   L("rival", "أنا الأسطى كمال. الفلافل؟ أكلة تركيّة طبعاً!"),
   L("player", "تركيّة؟! يا أسطى، الفلافل أكبر من الكل."),
   L("rival", "ماشي! خلّي الزباين يحكموا: كفتتي ضدّ فلافلك.")], None),
 ("goal", "T12", [
   L("ayse", "الركّاب صاروا يسألوا: وين البسطة الفلسطينيّة؟"),
   L("player", "احكيلهم: جنب الميناء، الشاي عليكِ والفلافل عليّ."),
   L("ayse", "تشكّرلر! يعني شكراً. صرنا شركاء يا صاحبي.", "تشكّرلر! يعني شكراً. صرنا شركاء يا صاحبتي.")], None),
 ("midpoint", 0.5, [
   L("sitti", "جدّك كان يحكي إنّه جدّه اشتغل بإسطنبول زمان."),
   L("player", "يعني رجعنا لمحلّ ما بلّشت الحكاية؟"),
   L("sitti", "الحكايات بتلفّ وبترجع، زيّ العبّارة.")], None),
 ("goal", "T14", [
   L("rival", "أربع شحنات! الصيّادين صاروا يحبّوك أكتر منّي.", "أربع شحنات! الصيّادين صاروا يحبّوكي أكتر منّي."),
   L("rival", "طيب، بعترف: الفلافل مش تركيّة… بسّ الكنافة تركيّة!"),
   L("player", "يا أسطى، الكنافة نابلسيّة! بسّ منكمّل النقاش عالشاي.")], None),
 ("finale", None, [
   L("rival", "إسطنبول بتقلّك: غوله غوله، يعني مع السلامة وارجع.", "إسطنبول بتقلّك: غوله غوله، يعني مع السلامة وارجعي."),
   L("samer", "أثينا جاهزة! آثار وبحر وشمس."),
   L("sitti", "كيريا ماريا هناك بتعمل لقمة القاضي. بنت عمّ العوّامة!")], cards("yukiStreet", 3)),
]

STORY["athens"] = [
 ("arrival", None, [
   L("samer", "أثينا! الآثار فوق، والسيّاح تحت، والشمس بكل مكان."),
   L("sitti", "اليونانيّين متلنا، بيحبّوا الزيتون والسهر والعيلة."),
   L("player", "والجيروس عندهم زيّ الشاورما تبعتنا!")], None),
 ("goal", "T5", [
   L("yannis", "ياسو! أنا يانيس. الباصات بتنزّل سيّاح للآثار كل شوي."),
   L("yannis", "استقبلهم بسرعة، وبيرجعوا يحكوا لكل الباص.", "استقبليهم بسرعة، وبيرجعوا يحكوا لكل الباص."),
   L("player", "أوّل باص! كاليميرا… هيك بيقولوا صح؟")], None),
 ("rival", 0.25, [
   L("rival", "كاليسبيرا! أنا كيريا ماريا، اللوكوماديس عندي بالعسل والقرفة."),
   L("player", "لوكوماديس؟ هاي لقمة القاضي تبعتنا!"),
   L("rival", "مستحيل! إلّا إذا… إحنا ولاد عمّ؟")], None),
 ("goal", "T12", [
   L("yannis", "اليوم الشوب قوي. السيّاح بدّهم فرابيه وسلطة باردة!"),
   L("player", "البحر بيعطيك سمك، وأنا بعطيك فلافل. صفقة؟"),
   L("yannis", "صفقة يونانيّة فلسطينيّة! أوبا!")], None),
 ("midpoint", 0.5, [
   L("sitti", "شفت؟ الأكل بيجمع الناس أكتر من أيّ لغة.", "شفتي؟ الأكل بيجمع الناس أكتر من أيّ لغة."),
   L("player", "يا ستّي، ماريا بتعرف كل وصفاتك بأسامي تانية!"),
   L("sitti", "البحر المتوسّط مطبخ واحد كبير، يا عمري.")], None),
 ("goal", "T14", [
   L("rival", "خمس باصات وقفوا عندك! السيّاح صاروا يطلبوا فلافل بدل جيروس."),
   L("rival", "يلا، منعمل صحن لقمة القاضي ولوكوماديس سوا، نصّ ونصّ."),
   L("player", "واسمه: لقمة ماريا!")], None),
 ("finale", None, [
   L("rival", "أثينا بتودّعك بالعسل. إفخاريستو يا صديقي.", "أثينا بتودّعك بالعسل. إفخاريستو يا صديقتي."),
   L("samer", "لندن جاهزة… بسّ جيب شمسيّة!", "لندن جاهزة… بسّ جيبي شمسيّة!"),
   L("sitti", "خالتك سهى هناك من عشرين سنة، واشتاقتلك.")], cards("mariaChile", 2)),
]

STORY["london"] = [
 ("arrival", None, [
   L("auntSuha", "حبيب خالتك! أخيراً وصلت لندن. تعال البس جاكيت!", "حبيبة خالتك! أخيراً وصلتي لندن. تعالي البسي جاكيت!"),
   L("sitti", "سهى بنتي، بتعرف لندن شارع شارع. اسمع منها.", "سهى بنتي، بتعرف لندن شارع شارع. اسمعي منها."),
   L("player", "خالتو! ستّي بعتتلك زعتر وزيت من البلد.")], None),
 ("goal", "T5", [
   L("auntSuha", "الطقس هون بيقلب كل ساعة: شمس، شتي، برد!"),
   L("auntSuha", "لما تشتي، الكل بيطلب شاي وفطيرة سخنة."),
   L("player", "يعني الشتي هون… رزقة!")], None),
 ("rival", 0.25, [
   L("rival", "غود إيفنينغ! أنا مستر هاري، سمك وبطاطا من خمسين سنة."),
   L("rival", "الفلافل؟ إشي لطيف… بسّ الإنجليز بيحبّوا البطاطا."),
   L("sitti", "خلّيه يجرّب راب الفلافل، وبعدين منحكي.")], None),
 ("goal", "T12", [
   L("auntSuha", "صحباتي بالشغل كلّهم بيطلبوا دليفري من عندك!"),
   L("player", "يا خالتو، صار عنّا دليفري تحت الشتي كمان."),
   L("auntSuha", "لو ستّك تشوفك، رح تعيّط من الفرحة.")], None),
 ("midpoint", 0.5, [
   L("sitti", "سهى بعتتلي صورة البسطة تحت المطر، بتلمع زيّ القمر."),
   L("player", "الناس بيوقفوا بالدور تحت الشمسيّات!"),
   L("sitti", "اللي بيستنّاك بالشتي، أكرمه بلقمة زيادة.", "اللي بيستنّاكي بالشتي، أكرميه بلقمة زيادة.")], None),
 ("goal", "T14", [
   L("rival", "يا ربّي، بطاطتي صارت طريّة من الشتي، وفلافلك لسّا مقرمشة!"),
   L("rival", "ممكن أطلب راب فلافل… والبطاطا جوّاته؟"),
   L("player", "أكيد يا مستر هاري، اسمه: راب لندن!")], None),
 ("finale", None, [
   L("rival", "تشيريو يا صاحبي! لندن رح تشتاق لفلافلك.", "تشيريو يا صاحبتي! لندن رح تشتاق لفلافلك."),
   L("auntSuha", "باريس قريبة بالقطار، بسّ لا تنسى خالتك!", "باريس قريبة بالقطار، بسّ لا تنسي خالتك!"),
   L("sitti", "مسيو بيير هناك بيقول الخبز فنّ. فرجيه فنّك.")], cards_r("epic", 1)),
]

STORY["paris"] = [
 ("arrival", None, [
   L("samer", "باريس! النهر والجسور والمقاهي، وريحة الكرواسون الصبح."),
   L("sitti", "الفرنسيّين بيحترموا الأكل كأنّه رسمة بمتحف."),
   L("player", "منيح، صحن الفلافل تبعي لوحة فنّيّة!")], None),
 ("goal", "T5", [
   L("claire", "بونجور، أنا كلير، ناقدة أكل. النقّاد بيدوّروا على صحن مميّز."),
   L("claire", "فلافل فاخر بصالة خاصّة؟ فكرة… جريئة."),
   L("player", "أوّل ناقد كبير طلع مبسوط! الصالة جاهزة.")], None),
 ("rival", 0.25, [
   L("rival", "بونسوار. أنا مسيو بيير. الباغيت عندي بيطلع بالثانية المظبوطة."),
   L("rival", "الفلافل؟ أكل شارع. باريس بدها فنّ، مش شارع."),
   L("sitti", "الشارع فيه أحلى فنّ. فرجيه!")], None),
 ("goal", "T12", [
   L("claire", "كتبت عنك بالجريدة: فلافل بتخلّي باريس تحكي عربي!"),
   L("player", "مرسي كلير! بعزمك على صحن كنافة من إيدي."),
   L("claire", "وأنا بعزمك على كرواسون… باريس بتحبّ التبادل.")], None),
 ("midpoint", 0.5, [
   L("sitti", "شو بدّك بالنجوم يا عمري؟ نجومك هم زباينك."),
   L("player", "بسّ يا ستّي، النقّاد هون صعبين كتير."),
   L("sitti", "الصعب بيصير سهل لمّا تحطّ قلبك بالعجينة.", "الصعب بيصير سهل لمّا تحطّي قلبك بالعجينة.")], None),
 ("goal", "T14", [
   L("rival", "ستّ نقّاد كبار مدحوا فلافلك… وواحد بسّ مدح باغيتي."),
   L("rival", "طيب، علّمني: كيف الفلافل مقرمشة برّا وطريّة جوّا؟", "طيب، علّميني: كيف الفلافل مقرمشة برّا وطريّة جوّا؟"),
   L("player", "بعلّمك، إذا علّمتني توقيت الباغيت!")], None),
 ("finale", None, [
   L("rival", "مرسي يا صديقي. من اليوم، باغيت فلافل على قائمتي.", "مرسي يا صديقتي. من اليوم، باغيت فلافل على قائمتي."),
   L("samer", "نيويورك جاهزة! مدينة ما بتنام، أكتر من رام الله كمان."),
   L("sitti", "عمّك جميل هناك من تلاتين سنة، وبيستنّاك.")], cards("samiFryer", 5)),
]

STORY["newYork"] = [
 ("arrival", None, [
   L("uncleJamil", "أهلا يا ابن أخوي! أخيراً نيويورك.", "أهلا يا بنت أخوي! أخيراً نيويورك."),
   L("samer", "يابا! اشتقتلك كتير!"),
   L("sitti", "جميل ابني، راح على أمريكا وأخذ ريحة الفلافل معه.")], None),
 ("goal", "T5", [
   L("uncleJamil", "هون الكل مستعجل. بدّهم الأكل يطلع للطابق الأربعين!"),
   L("uncleJamil", "ابعت الطلبات بسرعة، وما تنسى الصوص الأبيض.", "ابعتي الطلبات بسرعة، وما تنسي الصوص الأبيض."),
   L("player", "تلات طلبات وصلت! نيويورك بتاكل فلافل.")], None),
 ("rival", 0.25, [
   L("rival", "هاي! أنا بيغ توني. عربايتي بالشارع من عشرين سنة."),
   L("rival", "السرّ؟ صوص أبيض زيادة. دايماً زيادة!"),
   L("player", "وأنا عندي طحينة القدس… منشوف مين بيكسب.")], None),
 ("goal", "T12", [
   L("uncleJamil", "شفت الطابور الساعة تلاتة الصبح؟ سوّاقين وطلّاب وممرّضين!", "شفتي الطابور الساعة تلاتة الصبح؟ سوّاقين وطلّاب وممرّضين!"),
   L("player", "زيّ أبو العبد بالقدس! سوّاقين التكسي بيعرفوا الأكل الطيّب."),
   L("uncleJamil", "بلّغه سلامي، كان يوصّلني عالمطار زمان.", "بلّغيه سلامي، كان يوصّلني عالمطار زمان.")], None),
 ("midpoint", 0.5, [
   L("sitti", "جميل بيقول بسطتك صارت أشهر من الجسر!"),
   L("player", "عمّي جميل بيبالغ، بسّ الناس بتحبّ الفلافل كتير."),
   L("sitti", "اللي بيطلع من القلب بيوصل للقلب، حتّى بنيويورك.")], None),
 ("goal", "T14", [
   L("rival", "عشرين طلب وصلوا قبل طلباتي؟ إنت ماكينة!", "عشرين طلب وصلوا قبل طلباتي؟ إنتِ ماكينة!"),
   L("rival", "اتّفقنا: الصوص الأبيض منّي، والطحينة منك. أحسن صحن بالمدينة."),
   L("player", "صحن الصحاب! صوص أبيض وطحينة.")], None),
 ("finale", None, [
   L("rival", "نيويورك بتقلّك: شكراً يا بطل! ارجع بأيّ وقت.", "نيويورك بتقلّك: شكراً يا بطلة! ارجعي بأيّ وقت."),
   L("uncleJamil", "سانتياغو جاهزة. هناك جالية فلسطينيّة كبيرة كتير!"),
   L("sitti", "عمّو إلياس هناك، صاحب جدّك من أيّام الشباب.")], cards("mariaChile", 3)),
]

STORY["santiago"] = [
 ("arrival", None, [
   L("uncleElias", "أهلا وسهلا! أنا عمّو إلياس، أصلي من بيت جالا."),
   L("uncleElias", "هون بالتشيلي فلسطين بالقلب، والنادي كلّه عيلة."),
   L("sitti", "إلياس صاحب جدّك. سلّملي عليه، وبوسلي راسه.", "إلياس صاحب جدّك. سلّميلي عليه، وبوسيلي راسه.")], None),
 ("goal", "T5", [
   L("rival", "أولا! أنا دون خوسيه. الإمبانادا بدها قمح مطحون منيح."),
   L("rival", "القمح بيصير عجين، والعجين بيصير إمبانادا. خطوة خطوة."),
   L("player", "زيّ الحليب والجميد بعمّان! بعرف هاللعبة.")], None),
 ("rival", 0.25, [
   L("rival", "الإمبانادا تبعتي أطيب إمبانادا بسانتياغو، والكل بيعرف."),
   L("rival", "فلافل؟ ما بعرفها… بسّ ريحتها حلوة، لازم أعترف."),
   L("uncleElias", "خوسيه عنيد، بسّ بطنه بيفهم أكتر من راسه!")], None),
 ("goal", "T12", [
   L("uncleElias", "النادي الفلسطيني عامل عرس الجمعة. بدّهم فلافلك!"),
   L("player", "على راسي يا عمّو! فلافل وحمّص ومسخّن."),
   L("uncleElias", "العرسان من بيت لحم، رح يبكوا من الفرحة.")], None),
 ("midpoint", 0.5, [
   L("sitti", "إلياس بعتلي صورة… النادي كلّه بيدبك حوالين بسطتك!"),
   L("player", "يا ستّي، حسّيت حالي بالبلد."),
   L("sitti", "البلد ساكنة فينا، وين ما رحنا.")], None),
 ("goal", "T14", [
   L("rival", "أكلت فلافلك مبارح الصبح… والظهر… والمسا.", ),
   L("rival", "إذا بتعلّمني، بحطّ فلافل جوّا الإمبانادا!", "إذا بتعلّميني، بحطّ فلافل جوّا الإمبانادا!"),
   L("player", "إمبانادا فلافل؟ دون خوسيه، إنت عبقري!")], None),
 ("finale", None, [
   L("uncleElias", "ارجع بعيد الميلاد، النادي كلّه بيستنّاك.", "ارجعي بعيد الميلاد، النادي كلّه بيستنّاكي."),
   L("rival", "صرت فلافلي يا صديقي. شكراً من القلب.", "صرت فلافلي يا صديقتي. شكراً من القلب."),
   L("sitti", "ريو جاهزة: كرنفال وموسيقى، وكارلوس ما بيوقف رقص.")], cards_r("epic", 1)),
]

STORY["rio"] = [
 ("arrival", None, [
   L("samer", "ريو! الجبال والبحر والكرنفال… وكل الناس بترقص!"),
   L("sitti", "البرازيليّين قلبهم دافي، زيّ شمسهم."),
   L("player", "رح نخلّي الفلافل ترقص سامبا!")], None),
 ("goal", "T5", [
   L("mariana", "أولا! أنا ماريانا. أسبوع الكرنفال، والناس ما بتنام!"),
   L("mariana", "من الساعة تمانية، الكل بيطلب أكل وحلو… كتير كتير!"),
   L("player", "سوق الليل فتح! فلافل سامبا للكل.")], None),
 ("rival", 0.25, [
   L("rival", "أنا كارلوس، ملك الشوراسكو. المشاوي عندي ما بتنطفي."),
   L("rival", "إذا الناس رقصت عندك أكتر من عندي، بعزمك عالشوراسكو."),
   L("sitti", "كارلوس بيحبّ التحدّي، بسّ قلبه أبيض.")], None),
 ("goal", "T12", [
   L("mariana", "فرقة السامبا تبعتي بدها تمرق قدّام بسطتك الليلة!"),
   L("player", "الفلافل والبريغاديرو عليّ لكل الفرقة!"),
   L("mariana", "أوبريغادا! يعني شكراً بالبرتغالي.")], None),
 ("midpoint", 0.5, [
   L("sitti", "سمعت إنّك رقصت سامبا؟ جدّك كان أشطر منك بالدبكة!", "سمعت إنّك رقصتي سامبا؟ جدّك كان أشطر منك بالدبكة!"),
   L("player", "يا ستّي، الدبكة والسامبا ولاد عمّ."),
   L("sitti", "كل الرقصات بتبلّش من فرحة القلب.")], None),
 ("goal", "T14", [
   L("rival", "الناس رقصوا عندك لطلوع الضو! خسرت التحدّي…"),
   L("rival", "يلا، الشوراسكو عليّ والفلافل عليك. حفلة للكل!", "يلا، الشوراسكو عليّ والفلافل عليكِ. حفلة للكل!"),
   L("player", "أوبا! ريو بتعرف تحتفل.")], None),
 ("finale", None, [
   L("rival", "ريو بتقلّك: مش وداع، بسّ لنشوفك بالكرنفال الجاي!"),
   L("samer", "آخر محطّة: طوكيو! المدينة اللي كلّها دقّة."),
   L("sitti", "الشيف كينجي بيقيس كل إشي بالثانية، وإنت بتقيس بالقلب.", "الشيف كينجي بيقيس كل إشي بالثانية، وإنتِ بتقيسي بالقلب.")], cards("yukiStreet", 5)),
]

STORY["tokyo"] = [
 ("arrival", None, [
   L("samer", "طوكيو! قطارات عالدقيقة، وأضواء، وناس مؤدّبين كتير."),
   L("sitti", "آخر مدينة يا عمري. بعدها منرجع عالقدس سوا."),
   L("player", "يعني هاي الحلقة الأخيرة؟ لازم تكون أحلى وحدة!")], None),
 ("goal", "T5", [
   L("rival", "كونيتشيوا. أنا الشيف كينجي. التمبورا بتطلع بثانية وحدة مظبوطة."),
   L("rival", "لما تلمع، دقّ. لا قبل، ولا بعد.", "لما تلمع، دقّي. لا قبل، ولا بعد."),
   L("player", "خمس قطع مظبوطة! أريغاتو يا شيف.")], None),
 ("rival", 0.25, [
   L("rival", "الدقّة هي كل إشي. عشرين سنة وأنا بتعلّم أقطع السمك."),
   L("rival", "وإنت؟ فلافل؟ بدون قياس؟ بدون ميزان؟", "وإنتِ؟ فلافل؟ بدون قياس؟ بدون ميزان؟"),
   L("sitti", "ميزاننا بالقلب يا شيف، مش بالغرامات.")], None),
 ("goal", "T12", [
   L("haruto", "أنا هاروتو، طالب. أكلت فلافل لأوّل مرّة… واو!"),
   L("haruto", "صوّرتها ونزّلتها، وهلّق كل الصفّ جاي!"),
   L("player", "أهلا بالصفّ كلّه! أونيغيري وفلافل لكل واحد.")], None),
 ("midpoint", 0.5, [
   L("sitti", "بتعرف شو أحلى إشي بهالرحلة؟ إنّك ما نسيت أصلك.", "بتعرفي شو أحلى إشي بهالرحلة؟ إنّك ما نسيتي أصلك."),
   L("player", "كيف بنسى يا ستّي؟ الفلافل بتذكّرني فيكِ كل يوم."),
   L("sitti", "الله يرضى عليك. يلا، خلّص طوكيو وتعال عالدار.", "الله يرضى عليكِ. يلا، خلّصي طوكيو وتعالي عالدار.")], None),
 ("goal", "T14", [
   L("rival", "أربعين قطعة مظبوطة. أنا… بنحنيلك احترام."),
   L("rival", "علّمني الفلافل. بدّي أعمل فلافل أوماكاسي.", "علّميني الفلافل. بدّي أعمل فلافل أوماكاسي."),
   L("player", "بشرط: تيجي معي عالقدس، عالعزومة الكبيرة!"),
   L("rival", "هاي! يشرّفني.")], None),
 ("finale", None, [
   L("rival", "الفلافل فنّ، وإنت معلّمه.", "الفلافل فنّ، وإنتِ معلّمته."),
   L("samer", "كل الفروع شغّالة، من القدس لطوكيو! يا عيلة!"),
   L("sitti", "يلا يا روحي، الطيّارة عالقدس. العيلة كلّها ناطرة.")], cards_r("legendary", 1)),
]

CAST = [
    ("sitti", "ستّي أم خليل", "ppl_old_woman"),
    ("abuAlAbed", "أبو العبد، سوّاق التكسي", "ppl_man"),
    ("lina", "لينا بنت الجيران", "ppl_girl"),
    ("samer", "سامر ابن عمّك", "ppl_man_office"),
    ("abuShaker", "أبو شاكر", "ppl_man_cook"),
    ("guideIssa", "الدليل عيسى", "ppl_person_tipping_hand"),
    ("soapMaker", "أبو نضال الصابونجي", "ppl_older_person"),
    ("glassSaeed", "سعيد الزجّاج", "ppl_man"),
    ("portGuard", "أبو عمر حارس الميناء", "ppl_guard"),
    ("riderMajd", "مجد الديليفري", "ppl_boy"),
    ("hammouda", "حمّودة", "ppl_child"),
    ("yazan", "يزن طالب الجامعة", "ppl_person_raising_hand"),
    ("groomFather", "أبو صالح، أبو العريس", "ppl_older_person"),
    ("singerRita", "ريتا المغنّية", "ppl_singer"),
    ("hakawati", "الحكواتي أبو راشد", "ppl_older_person"),
    ("bawwab", "عم حسنين البوّاب", "ppl_old_man"),
    ("ustazNawfal", "الأستاذ نوفل", "ppl_teacher"),
    ("saad", "سعد صاحب المخيّم", "ppl_man_farmer"),
    ("mira", "ميرا البلوغر", "ppl_woman"),
    ("idris", "إدريس بيّاع العصير", "ppl_man"),
    ("ayse", "عائشة بيّاعة الشاي", "ppl_woman_headscarf"),
    ("yannis", "يانيس الصيّاد", "ppl_old_man"),
    ("auntSuha", "خالتك سهى", "ppl_woman_headscarf"),
    ("claire", "كلير الناقدة", "ppl_woman_office"),
    ("uncleJamil", "عمّك جميل", "ppl_older_person"),
    ("uncleElias", "عمّو إلياس", "ppl_old_man"),
    ("mariana", "ماريانا", "ppl_raising_hands"),
    ("haruto", "هاروتو", "ppl_bowing"),
]

EXTRA = [
 ("epilogue_backToJerusalem", "manual", "campaignComplete", [
   L("sitti", "شوف! أبو شاكر وجريس وأبو حمدي… كل الجيران إجوا.", "شوفي! أبو شاكر وجريس وأبو حمدي… كل الجيران إجوا."),
   L("abuShaker", "يا جار! الفلافل طلعت من هالبسطة ولفّت الدنيا كلّها.", "يا جارة! الفلافل طلعت من هالبسطة ولفّت الدنيا كلّها."),
   L("lina", "عمّو! أنا كبرت وصرت طبّاخة، بدّي أشتغل عندك!", "خالتو! أنا كبرت وصرت طبّاخة، بدّي أشتغل عندك!"),
   L("player", "البسطة بسطتك يا لينا، والحكاية مكمّلة."),
   L("sitti", "جدّك لو هون، كان قال: هيك بتكون البسطة.")], [{"type": "chest", "id": "gold", "amount": 1}]),
 ("fest_mothersDay", "festival", "mothersDay", [
   L("player", "كل عام وإنتِ بخير يا ستّي، يا أحلى أمّ بالدنيا."),
   L("sitti", "وإنت بخير يا روحي. أحلى هديّة إنّك اتّصلت.", "وإنتِ بخير يا روحي. أحلى هديّة إنّك اتّصلتي."),
   L("sitti", "بعتتلك وصفة سرّيّة… افتحها لما تشتاقلي.", "بعتتلك وصفة سرّيّة… افتحيها لما تشتاقيلي.")], None),
 ("fest_ramadan", "festival", "ramadan", [
   L("sitti", "رمضان كريم يا عمري! الفوانيس منوّرة بكل حارة."),
   L("player", "الله أكرم يا ستّي. الفطور عندي اليوم؟"),
   L("sitti", "أكيد! وبعد الفطور قطايف بالجوز، متل ما بتحبّ.", "أكيد! وبعد الفطور قطايف بالجوز، متل ما بتحبّي.")], None),
 ("fest_eidFitr", "festival", "eidFitr", [
   L("sitti", "كل عام وإنت بخير! هاي عيديّتك من ستّك.", "كل عام وإنتِ بخير! هاي عيديّتك من ستّك."),
   L("player", "يا ستّي، صرت كبير عالعيديّة!", "يا ستّي، صرت كبيرة عالعيديّة!"),
   L("sitti", "عمرك ما بتكبر على عيديّة ستّك.", "عمرك ما بتكبري على عيديّة ستّك.")], None),
 ("fest_eidAdha", "festival", "eidAdha", [
   L("sitti", "عيد أضحى مبارك! اعمل صحن كبير ووزّع عالجيران.", "عيد أضحى مبارك! اعملي صحن كبير ووزّعي عالجيران."),
   L("player", "على راسي يا ستّي، المنسف جاهز للكل.")], None),
 ("fest_oliveHarvest", "festival", "oliveHarvest", [
   L("sitti", "موسم الزيتون! زمان كانت العيلة كلّها تطلع عالكرم."),
   L("sitti", "الزيت الجديد بيخلّي الفلافل تغنّي."),
   L("player", "رح أبعتلك تنكة زيت من أوّل عصرة!")], None),
 ("fest_bethlehemChristmas", "festival", "bethlehemChristmas", [
   L("sitti", "ميلاد مجيد! بيت لحم منوّرة، والشجرة بالساحة عالية."),
   L("player", "رح أبعت سحلب وكستنا لجريس، بيستاهل.")], None),
 ("fest_summer", "festival", "summer", [
   L("sitti", "إجت الصيفيّة! بطّيخ وبوظة وسهر عالسطوح."),
   L("player", "وليموناضة بالنعنع، يا سلام!")], None),
 ("fest_backToSchool", "festival", "backToSchool", [
   L("lina", "رجعت عالمدرسة! بدّي سندويشة فلافل للفرصة."),
   L("player", "سندويشة فلافل وتفّاحة، عشان تتفوّقي!"),
   L("sitti", "العلم نور، والفلافل وقود. بالتوفيق يا لينا!")], None),
 ("choice_radio", "manual", "choice:radio", [
   L("player", "ستّي أم خليل علّمتني كل إشي: الوصفة والصبر والابتسامة."),
   L("sitti", "سمعتك بالراديو! الحارة كلّها سمعت. رفعت راسي.", "سمعتك بالراديو! الحارة كلّها سمعت. رفعتي راسي.")], None),
 ("choice_grandmaCall", "manual", "choice:grandmaCall", [
   L("sitti", "وصل الصحن! والله طعمته متل طعمة جدّك."),
   L("player", "منك تعلّمت يا ستّي، كلّه منك."),
   L("sitti", "الله يرضى عليك ويوسّع رزقك.", "الله يرضى عليكِ ويوسّع رزقك.")], None),
]

MEMORIES = {
 82: [L("sitti", "بتذكر أوّل يوم فتح جدّك البسطة؟ كان معه عشر حبّات فلافل.", "بتذكري أوّل يوم فتح جدّك البسطة؟ كان معه عشر حبّات فلافل."),
      L("sitti", "بعنا تسعة، والعاشرة أكلها هو وضحك!")],
 83: [L("sitti", "زمان كنّا نطحن الحمّص بالجاروشة. إيدي تتعب وقلبي يغنّي."),
      L("player", "هلّق في ماكينة يا ستّي!"),
      L("sitti", "الماكينة بتطحن، بسّ الغنا ما بتعرفه.")],
 84: [L("sitti", "جدّك كان يحطّ وردة عالبسطة كل صبح… عشاني."),
      L("player", "يا عيني! عشان هيك البسطة دايماً حلوة.")],
 85: [L("sitti", "أوّل مرّة شفت البحر كانت بيافا. أكلنا سمك وبرتقال."),
      L("sitti", "من يومها، ريحة البرتقال بترجّعني صبيّة.")],
 86: [L("sitti", "أمّي علّمتني التطريز. كل غرزة إلها اسم وحكاية."),
      L("player", "وأنا بتعلّم منك: كل صحن إله اسم وحكاية.")],
 87: [L("sitti", "بالشتا كنّا نتجمّع حوالين الكانون، والكستنا تطقّ."),
      L("sitti", "وجدّك يحكي حكايات، والولاد يناموا عحضني.")],
 88: [L("sitti", "عمّك جميل لما كان زغير، كان يسرق قرص فلافل ويركض."),
      L("player", "عمّي جميل؟! هلّق صار عنده عربايّة بنيويورك!")],
 89: [L("sitti", "موسم الزيتون كان عرس. العيلة كلّها تحت الشجر."),
      L("sitti", "والغدا عالكرم: زيت جديد وخبز طابون سخن.")],
 91: [L("sitti", "جدّك عملّي خاتم من خشب الزيتون. لسّا معي، شوف.", "جدّك عملّي خاتم من خشب الزيتون. لسّا معي، شوفي."),
      L("player", "أحلى من الدهب يا ستّي.")],
 92: [L("sitti", "الطابون كان بالحارة، وكل الجيران يخبزوا فيه سوا."),
      L("sitti", "الخبز بطلع أطيب لمّا الإيدين كتار.")],
 93: [L("sitti", "أوّل قرص فلافل عملته كان محروق…"),
      L("sitti", "وجدّك أكله كلّه وقال: أطيب قرص بحياتي!")],
 94: [L("sitti", "كنّا نسمع الراديو عالبسطة، والشارع كلّه يغنّي معه."),
      L("player", "يلا نشغّل الراديو هلّق يا ستّي!")],
 95: [L("sitti", "أبو شاكر وجدّك كانوا يتسابقوا مين بيفتح أوّل."),
      L("sitti", "وكل يوم بيخسر واحد، وبيعزم التاني على شاي.")],
 96: [L("sitti", "لما انولدت يا عمري، جدّك وزّع فلافل عالحارة كلّها.", "لما انولدتي يا عمري، جدّك وزّع فلافل عالحارة كلّها."),
      L("player", "يعني أنا من أوّل يوم ريحتي فلافل!")],
 97: [L("sitti", "مفتاح دار سيدي لسّا معي، بيذكّرني بالدار والعيلة."),
      L("sitti", "خبّيه منيح… يوم من الأيّام بصير إلك.", "خبّيه منيح… يوم من الأيّام بصير إلكِ.")],
 98: [L("sitti", "الرزق بحبّ الخفّية. جدّك كان يقولها كل صبح."),
      L("player", "وأنا بقولها كل صبح هلّق، بكل الفروع.")],
 99: [L("sitti", "أنا فخورة فيك، أكتر من كل الفروع والنجوم.", "أنا فخورة فيكي، أكتر من كل الفروع والنجوم."),
      L("player", "وأنا كل اللي عملته، عشان أشوف هالضحكة.")],
}

# ---------------------------------------------------------------- build
def build():
    cities_out = []
    chapters = []
    for idx, c in enumerate(CITIES, start=1):
        c["index"] = idx
        F = sig3(10 ** c["log10F"])
        # resolve deliveryRuns cost expressions
        for tw in c["twists"]:
            p = tw["params"]
            if p.get("extraScooterCostsBase") == "F*[1e-6,1e-4,1e-2]":
                p["extraScooterCostsBase"] = [sig3(F * 1e-6), sig3(F * 1e-4), sig3(F * 1e-2)]
            if p.get("dispatcherCostBase") == "F*1e-5":
                p["dispatcherCostBase"] = sig3(F * 1e-5)
        stations = []
        for t, s in enumerate(c["stations"]):
            d = {"id": f"{c['id']}.{s['key']}", "key": s["key"], "name": s["name"], "art": s["art"], "tier": t,
                 "cuisine": s["cuisine"], "category": s["category"]}
            if s["weather"] != "none": d["weather"] = s["weather"]
            d["managerName"] = s["managerName"]; d["managerArt"] = s["managerArt"]
            stations.append(d)
        upgrades = upgrades_for(c, F)
        # goals
        row_to_index = {}
        if c["id"] == "jerusalem":
            goals = jerusalem_goals()
            row_to_index = {i: i for i in range(1, len(goals) + 1)}
        else:
            rows = template_goals(c, F, upgrades)
            extras = PLAN[c["id"]][2]
            goals = []
            for r in range(1, 23):
                goals.append(rows[r]); row_to_index[f"T{r}"] = len(goals)
                for (after, kind, n) in extras:
                    if after == r:
                        goals.append(extra_goal(kind, n, c))
        for i, g in enumerate(goals, start=1):
            g_ordered = {"id": f"{c['id']}.g{i:02d}"}
            g_ordered.update(g)
            goals[i - 1] = g_ordered
        total = sum(g["stars"] for g in goals)
        chapter_id = f"ch{idx:02d}_{c['id']}"
        city = {
            "id": c["id"], "index": idx, "name": c["name"], "region": c["region"],
            "currency": {"name": c["currency"][0], "symbol": c["currency"][1], "art": c["currency"][2]},
            "landmarkArt": c["landmark"], "decorArts": c["decor"],
            "palette": dict(zip(["skyTop", "skyMid", "sunset", "glow", "accent"], c["palette"])),
            "silhouette": c["silhouette"], "levelCap": level_cap(idx), "licenceHours": licence_hours(idx),
            "finalGoalBase": F, "priceScale": c["S"], "starsToGraduate": math.ceil(0.75 * total),
            "stations": stations, "upgrades": upgrades, "goals": goals, "twists": c["twists"],
            "rival": {"name": c["rival"][0], "art": c["rival"][1]}, "chapterId": chapter_id,
            "customerArts": c["customers"],
            "rushIngredients": {"bases": [ing(x) for x in c["rush"][0]], "fillings": [ing(x) for x in c["rush"][1]]},
        }
        cities_out.append(city)
        # story chapter
        scenes = []
        for (trig, param, lines, rewards) in STORY[c["id"]]:
            if trig == "goal":
                gi = row_to_index[param]
                sid = f"ch{idx:02d}_g{gi:02d}"
                sc = {"id": sid, "trigger": "manual", "triggerParam": f"goal:{c['id']}.g{gi:02d}"}
            else:
                sc = {"id": f"ch{idx:02d}_{trig}", "trigger": trig}
                if param is not None: sc["triggerParam"] = param
            sc["lines"] = [{"speaker": sp, "text": tx} for (sp, tx) in lines]
            if rewards: sc["rewards"] = rewards
            scenes.append(sc)
        chapters.append({"id": chapter_id, "cityId": c["id"], "scenes": scenes})

    cities_json = {"version": 1, "cities": cities_out}
    story_json = {
        "version": 1,
        "cast": [{"id": i, "name": n, "art": a} for (i, n, a) in CAST],
        "chapters": chapters,
        "extraScenes": [dict({"id": i, "trigger": t, "triggerParam": p,
                              "lines": [{"speaker": sp, "text": tx} for (sp, tx) in ls]},
                             **({"rewards": rw} if rw else {})) for (i, t, p, ls, rw) in EXTRA],
        "memories": [{"id": f"memory_L{lv}", "trigger": "memory", "triggerParam": lv,
                      "lines": [{"speaker": sp, "text": tx} for (sp, tx) in ls]} for lv, ls in sorted(MEMORIES.items())],
    }
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "cities.json"), "w", encoding="utf-8") as f:
        json.dump(cities_json, f, ensure_ascii=False, indent=1)
        f.write("\n")
    with open(os.path.join(OUT, "story.json"), "w", encoding="utf-8") as f:
        json.dump(story_json, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print("wrote", len(cities_out), "cities,", sum(len(c["goals"]) for c in cities_out), "goals,",
          sum(len(ch["scenes"]) for ch in chapters), "chapter scenes")

if __name__ == "__main__":
    build()
