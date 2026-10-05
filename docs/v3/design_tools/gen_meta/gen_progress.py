"""cosmetics.json, levels.json, quests.json, calendar.json, season.json, festivals.json, achievements.json"""
from common import *

# ---------------------------------------------------------------- cosmetics.json
def CO(id, name, slot, source, art=None, pattern=None, colors=None, price=None):
    c = {"id": id, "name": name, "slot": slot}
    if art:
        c["art"] = art
    if pattern:
        c["pattern"] = pattern
    if colors:
        c["colors"] = colors
    if price is not None:
        c["price"] = price
    c["source"] = source
    return c


# level-unlocked cosmetics in unlock order (levels.json uses this order)
LEVEL_COSMETICS = [
    CO("awningOlive", "مظلّة زيتي", "awning", "level", pattern="stripes", colors=["#5E7A2E", "#F2EAD0"]),
    CO("propMint", "أصيص نعنع", "prop", "level", art="food_herb"),
    CO("lightsLanterns", "إضاءة فوانيس", "lights", "level", art="ui_lantern"),
    CO("signCopper", "يافطة نحاس", "sign", "level", pattern="solid", colors=["#B8733A", "#FFE2B0"]),
    CO("propCat", "قطّة الحارة", "prop", "level", art="ani_cat"),
    CO("awningTatreez", "مظلّة تطريز", "awning", "level", pattern="tatreez", colors=["#B0242C", "#1A1A1A", "#F2EAD0"]),
    CO("propBell", "جرس نحاس", "prop", "level", art="ui_bellhop_bell"),
    CO("lightsStars", "إضاءة نجوم", "lights", "level", art="ui_glowing_star"),
    CO("signCalligraphy", "يافطة خط عربي", "sign", "level", pattern="solid", colors=["#1E2A44", "#F9B233"]),
    CO("propSunflower", "دوّار الشمس", "prop", "level", art="ui_sunflower"),
    CO("awningSky", "مظلّة سماوي", "awning", "level", pattern="stripes", colors=["#4FA8D8", "#FFFFFF"]),
    CO("propOliveTree", "شجرة زيتون صغيرة", "prop", "level", art="bld_deciduous_tree"),
    CO("lightsCandles", "إضاءة شموع", "lights", "level", art="ui_candle"),
    CO("signTiles", "يافطة قيشاني", "sign", "level", pattern="solid", colors=["#1F6FA8", "#FFFFFF"]),
    CO("propRooster", "ديك الحارة", "prop", "level", art="ani_rooster"),
    CO("awningKeffiyeh", "مظلّة كوفيّة", "awning", "level", pattern="keffiyeh", colors=["#1A1A1A", "#FFFFFF"]),
    CO("propBouquet", "بوكيه ورد", "prop", "level", art="ui_bouquet"),
    CO("lightsHearts", "إضاءة قلوب", "lights", "level", art="ui_red_heart"),
    CO("signNeon", "يافطة نيون", "sign", "level", pattern="solid", colors=["#14102A", "#FF4FA8"]),
    CO("propTulips", "أصيص توليب", "prop", "level", art="ui_tulip"),
    CO("awningLilac", "مظلّة ليلكي", "awning", "level", pattern="stripes", colors=["#A88AD8", "#FFFFFF"]),
    CO("propPalm", "نخلة صغيرة", "prop", "level", art="bld_palm_tree"),
    CO("lightsBalloons", "بالونات", "lights", "level", art="ui_balloon"),
    CO("awningSunset", "مظلّة الغروب", "awning", "level", pattern="sunset", colors=["#33172E", "#D9714A", "#FFB36B"]),
    CO("propCactus", "صبّارة", "prop", "level", art="bld_cactus"),
    CO("awningRoyal", "مظلّة ملكيّة", "awning", "level", pattern="royal", colors=["#4A1A6A", "#F9B233"]),
    CO("propClover", "برسيم الحظ", "prop", "level", art="bld_four_leaf_clover"),
    CO("signGold", "يافطة ذهب", "sign", "level", pattern="solid", colors=["#D9801A", "#FFE38A"]),
    CO("frameOlive", "إطار زيتون", "frame", "level", pattern="solid", colors=["#5E7A2E", "#C9D88A"]),
    CO("frameGold", "إطار ذهبي", "frame", "level", pattern="royal", colors=["#D9801A", "#FFE38A"]),
]
SULTAN = CO("awningSultan", "بسطة سلطان البسطات", "awning", "level", pattern="royal", colors=["#F9B233", "#FFE38A", "#D9801A"])

EVENT_DECOS = [
    CO("lightsWedding", "زينة عرس", "lights", "event", art="ui_balloon"),
    CO("lightsFlags", "أعلام ملوّنة", "lights", "event", art="ui_confetti_ball"),
    CO("propOliveBasket", "سلّة قطف الزيتون", "prop", "event", art="food_olive"),
    CO("signChalkboard", "يافطة طبشورة", "sign", "event", pattern="solid", colors=["#1E3A2A", "#FFFFFF"]),
    CO("propGrapevine", "عريشة عنب", "prop", "event", art="food_grapes"),
    CO("goldTray", "صينيّة ذهب", "prop", "event", art="food_pie"),
    CO("propFamilyTable", "سفرة العيلة", "prop", "event", art="food_fork_knife_plate"),
    CO("propBeachUmbrella", "شمسيّة البحر", "prop", "event", art="bld_beach_with_umbrella"),
    CO("propFalafelCup", "كاس الفلافل الذهبي", "prop", "event", art="ui_trophy"),
    CO("propAnchor", "مرساة الميناء", "prop", "event", art="veh_anchor"),
    CO("propClayOven", "طابون الطين", "prop", "event", art="bld_hut"),
    CO("lightsCinema", "أضواء السينما", "lights", "event", art="ui_film_projector"),
    CO("propCrescent", "هلال رمضان", "prop", "event", art="ui_crescent_moon"),
    CO("lightsEidBalloons", "بالونات العيد", "lights", "event", art="ui_balloon"),
    CO("lightsEid", "زينة العيد", "lights", "event", art="ui_sparkles"),
    CO("propNativityStar", "نجمة الميلاد", "prop", "event", art="ui_star"),
    CO("frameFestivalChampion", "بطل المهرجان", "frame", "event", pattern="royal", colors=["#B0242C", "#F9B233"]),
]



def season_themes():
    def tw(type_, **p):
        return {"type": type_, "params": p}
    return [
        (0, "winterChestnut", "شتويّة الكستنا", "food_chestnut", "sAbuJiries",
         [CO("frameWinter", "إطار الشتويّة", "frame", "season", pattern="solid", colors=["#1E2A5E", "#C8D8FF"]),
          CO("awningWinter", "مظلّة الشتا", "awning", "season", pattern="stripes", colors=["#1E2A5E", "#FFFFFF"]),
          CO("propChestnutCart", "عربايّة كستنا", "prop", "season", art="food_chestnut")],
         tw("nightMarket", stations=[], startHour=18, endHour=23, nightMult=2)),
        (1, "springZaatar", "ربيع الزعتر", "food_herb", "sUmmZaatar",
         [CO("frameSpring", "إطار الربيع", "frame", "season", pattern="solid", colors=["#3E7A2E", "#E8F5C8"]),
          CO("awningSpring", "مظلّة الربيع", "awning", "season", pattern="stripes", colors=["#6AB04A", "#FFFFFF"]),
          CO("propZaatarPot", "أصيص زعتر", "prop", "season", art="bld_potted_plant")],
         tw("busWaves", intervalMin=20, waveMult=4)),
        (2, "summerSea", "صيفيّة البحر", "bld_beach_with_umbrella", "sRayyesBahri",
         [CO("frameSea", "إطار البحر", "frame", "season", pattern="solid", colors=["#1E7AA8", "#C8F0FF"]),
          CO("awningSea", "مظلّة البحر", "awning", "season", pattern="stripes", colors=["#1E7AA8", "#FFFFFF"]),
          CO("propBoat", "فلوكة صغيرة", "prop", "season", art="veh_sailboat")],
         tw("busWaves", intervalMin=15, waveMult=3)),
        (3, "oliveSeason", "موسم الزيتون", "food_olive", "sAbuZeit",
         [CO("frameOliveSeason", "إطار الموسم", "frame", "season", pattern="solid", colors=["#3E5A2A", "#F2D88A"]),
          CO("awningOliveSeason", "مظلّة موسم الزيتون", "awning", "season", pattern="stripes", colors=["#3E5A2A", "#F2D88A"]),
          CO("propOilJar", "جرّة زيت", "prop", "season", art="ui_droplet")],
         tw("busWaves", intervalMin=25, waveMult=4)),
        (4, "lateNights", "ليالي السهر", "bld_night_with_stars", "sSuhair",
         [CO("frameNights", "إطار السهر", "frame", "season", pattern="solid", colors=["#24204A", "#C8B8FF"]),
          CO("awningNights", "مظلّة السهر", "awning", "season", pattern="stripes", colors=["#24204A", "#8F7BFF"]),
          CO("propStarryLamp", "قنديل السهرة", "prop", "season", art="bld_night_with_stars")],
         tw("nightMarket", stations=[], startHour=20, endHour=2, nightMult=3)),
        (5, "haraWeddingSeason", "عرس الحارة", "bld_wedding", "sUmmAlArsan",
         [CO("frameWedding", "إطار العرس", "frame", "season", pattern="solid", colors=["#7A2E5A", "#FFC2D8"]),
          CO("awningWedding", "مظلّة العرس", "awning", "season", pattern="stripes", colors=["#E0607E", "#FFFFFF"]),
          CO("propZaffeh", "طبلة الزفّة", "prop", "season", art="ui_musical_notes")],
         tw("busWaves", intervalMin=25, waveMult=5)),
        (6, "worldMarkets", "أسواق العالم", "bld_globe_eu_africa", "sRahhal",
         [CO("frameWorld", "إطار المسافر", "frame", "season", pattern="solid", colors=["#16405E", "#F9B233"]),
          CO("awningWorld", "مظلّة الأسواق", "awning", "season", pattern="stripes", colors=["#E07A2E", "#2F8FC9", "#FFFFFF"]),
          CO("propGlobe", "كرة أرضيّة", "prop", "season", art="bld_globe_meridians")],
         tw("busWaves", intervalMin=20, waveMult=4)),
        (7, "sittiSweets", "حلويات ستّي", "food_shortcake", "sBintSitti",
         [CO("frameSitti", "إطار ستّي", "frame", "season", pattern="tatreez", colors=["#B0242C", "#F2EAD0"]),
          CO("awningSitti", "مظلّة ستّي", "awning", "season", pattern="tatreez", colors=["#B0242C", "#1A1A1A", "#F2EAD0"]),
          CO("propHarisseh", "صدر هريسة", "prop", "season", art="food_shortcake")],
         tw("nightMarket", stations=[], startHour=19, endHour=23, nightMult=2)),
    ]


def cosmetics():
    out = [
        CO("awningDefault", "مظلّة ستّي المقلّمة", "awning", "default", pattern="stripes", colors=["#C8392B", "#FFF4DE"]),
        CO("signDefault", "يافطة خشب", "sign", "default", pattern="solid", colors=["#6B3A1C", "#FFF4DE"]),
        CO("lightsDefault", "لمبات ملوّنة", "lights", "default", art="ui_light_bulb"),
        CO("propDefault", "صندوق خضرة", "prop", "default", art="food_tomato"),
        CO("frameDefault", "إطار خشب", "frame", "default", pattern="solid", colors=["#6B3A1C", "#9A5A2A"]),
    ]
    out += LEVEL_COSMETICS + [SULTAN]
    out += [
        CO("frameFlame", "إطار النار", "frame", "streak", pattern="solid", colors=["#D9411A", "#FFB36B"]),
        CO("propFlame", "نار المعلّم", "prop", "streak", art="ui_fire"),
        CO("awningYear", "بسطة السنة", "awning", "streak", pattern="royal", colors=["#F9B233", "#B0242C"]),
        CO("lightsRamadan", "فوانيس رمضان", "lights", "festival", art="ui_lantern"),
        CO("frameFirstGen", "من الجيل الأوّل", "frame", "legacy", pattern="sunset", colors=["#33172E", "#F9B233"]),
        CO("signCleanCert", "شهادة نظافة", "sign", "achievement", pattern="solid", colors=["#FFFFFF", "#2E8F4A"]),
        CO("frameSeasonChampion", "بطل الموسم", "frame", "season", pattern="royal", colors=["#1E2A5E", "#F9B233"]),
    ]
    out += EVENT_DECOS
    for _, _, _, _, _, cos, _ in season_themes():
        out += cos
    out += [
        CO("awningCandy", "مظلّة حلاوة", "awning", "shop", pattern="stripes", colors=["#FF8FB1", "#FFFFFF"], price=150),
        CO("awningWatermelon", "مظلّة بطّيخ", "awning", "shop", pattern="stripes", colors=["#2E8F4A", "#E8394A"], price=200),
        CO("propDallah", "دلّة قهوة", "prop", "shop", art="food_teapot", price=200),
        CO("signMosaic", "يافطة فسيفساء", "sign", "shop", pattern="solid", colors=["#1F6FA8", "#F9B233"], price=300),
        CO("lightsJasmine", "عقد ياسمين", "lights", "shop", art="ui_hibiscus", price=250),
        CO("lightsFireflies", "ضو اليراعات", "lights", "shop", art="ui_sparkles", price=300),
        CO("propLemonTree", "شجرة ليمون", "prop", "shop", art="food_lemon", price=250),
        CO("propBicycle", "بسكليت الدليفري", "prop", "shop", art="veh_bicycle", price=300),
        CO("propCamel", "جمل صغير", "prop", "shop", art="ani_camel", price=450),
        CO("frameTatreez", "إطار تطريز", "frame", "shop", pattern="tatreez", colors=["#B0242C", "#F2EAD0"], price=350),
        CO("frameSunset", "إطار الغروب", "frame", "shop", pattern="sunset", colors=["#33172E", "#D9714A", "#FFB36B"], price=400),
        CO("awningGoldStripes", "مظلّة مخطّطة ذهب", "awning", "shop", pattern="stripes", colors=["#F9B233", "#3E1F10"], price=600),
    ]
    return {"version": 1, "cosmetics": out}


# ---------------------------------------------------------------- levels.json
def xp_to_next(L):
    return int(5 * round(15 * L ** 1.36 / 5))


SYS_UNLOCKS = {
    1: [("system", "kitchen"), ("system", "goals")],
    2: [("system", "managers")],
    3: [("system", "specials"), ("system", "upgrades")],
    4: [("system", "chefs"), ("system", "chests"), ("system", "shop"), ("chefSlots", 1)],
    5: [("system", "rushHours"), ("system", "vault")],
    6: [("system", "map")],
    7: [("system", "research"), ("researchSlots", 1)],
    8: [("system", "supply"), ("system", "heritage"), ("supplySlots", 1), ("chefSlots", 2)],
    9: [("system", "daily"), ("system", "calendar"), ("system", "streak"), ("freezeCap", 2)],
    10: [("system", "choices"), ("system", "newspaper"), ("supplySlots", 2)],
    11: [("system", "rush"), ("ticketCap", 3)],
    12: [("system", "league")],
    13: [("system", "market")],
    14: [("system", "contracts"), ("contractSlots", 1), ("sideGrade", 1)],
    15: [("system", "events"), ("chefSlots", 3)],
    16: [("system", "season"), ("supplySlots", 3)],
    17: [("system", "branchUpgrades")],
    18: [("system", "inspector")],
    19: [("system", "crafting")],
    20: [("researchSlots", 2), ("sideGrade", 2)],
    22: [("system", "chefSkills")],
    24: [("system", "timeWarpShop")],
    25: [("chefSlots", 4)],
    30: [("contractSlots", 2)],
    35: [("ticketCap", 4), ("sideGrade", 3)],
    40: [("chefSlots", 5)],
    45: [("freezeCap", 3)],
    55: [("sideGrade", 4)],
    60: [("chefSlots", 6)],
    70: [("researchSlots", 3)],
    80: [("sideGrade", 5)],
    90: [("supplySlots", 4)],
    100: [("title", "title.L100"), ("cosmetic", "awningSultan")],
}
VISITORS = ["ppl_teacher", "ppl_health_worker", "ppl_mechanic", "ppl_pilot", "ppl_artist", "ppl_scientist",
            "ppl_farmer", "ppl_woman_farmer", "ppl_technologist", "ppl_construction", "ani_dog", "ppl_singer",
            "ppl_office", "ppl_superhero", "ppl_princess", "ppl_detective", "ppl_baby", "ppl_person_raising_hand",
            "ppl_waving_hand", "ppl_man_office"]
TITLES = {1: "بيّاع عالبسطة", 5: "صاحب عربايّة", 10: "معلّم فلافل", 15: "صاحب كشك", 20: "معلّم حمّص",
          25: "صاحب دكّانة", 30: "طبّاخ الحارة", 35: "مشهور بالبلد", 40: "صاحب مطعم", 45: "معلّم المعلّمين",
          50: "شيف المدينة", 55: "صاحب فروع", 60: "تاجر الشام", 65: "نجم المطابخ", 70: "ملك الصاج",
          75: "شيخ الطبّاخين", 80: "سفير الفلافل", 85: "أسطورة السوق", 90: "إمبراطور الحمّص",
          95: "إمبراطور الفلافل", 100: "سلطان البسطات"}
TITLES_F = {1: "بيّاعة عالبسطة", 5: "صاحبة عربايّة", 10: "معلّمة فلافل", 15: "صاحبة كشك", 20: "معلّمة حمّص",
            25: "صاحبة دكّانة", 30: "طبّاخة الحارة", 35: "مشهورة بالبلد", 40: "صاحبة مطعم", 45: "معلّمة المعلّمين",
            50: "شيفة المدينة", 55: "صاحبة فروع", 60: "تاجرة الشام", 65: "نجمة المطابخ", 70: "ملكة الصاج",
            75: "شيخة الطبّاخين", 80: "سفيرة الفلافل", 85: "أسطورة السوق", 90: "إمبراطورة الحمّص",
            95: "إمبراطورة الفلافل", 100: "سلطانة البسطات"}


def level_gold(L):
    return 0 if L == 1 else 10 if L <= 10 else 15 if L <= 30 else 20 if L <= 60 else 25


def level_chest(L):
    if L % 10 == 5:
        return "wood" if L < 40 else ("silver" if L < 80 else "gold")
    if L % 10 == 0:
        return "silver" if L < 50 else "gold"
    return None


def memory_levels():
    # levels after the cosmetic/visitor pool runs out (no system unlock) -> storyMemory
    return [L for L in range(82, 100) if L != 90]


def levels():
    ci = vi = 0
    rows = []
    for L in range(1, 101):
        unlocks, ceremony = [], False
        if L in SYS_UNLOCKS:
            for t, v in SYS_UNLOCKS[L]:
                if t in ("system", "title", "cosmetic"):
                    unlocks.append({"type": t, "id": v})
                    if t == "system":
                        ceremony = True
                else:
                    unlocks.append({"type": t, "value": v})
                    ceremony = True
        else:
            # alternate cosmetic (even) / street visitor (odd), then story memories
            if L % 2 == 0 and ci < len(LEVEL_COSMETICS):
                unlocks.append({"type": "cosmetic", "id": LEVEL_COSMETICS[ci]["id"]}); ci += 1
            elif vi < len(VISITORS):
                unlocks.append({"type": "visitor", "id": VISITORS[vi]}); vi += 1
            elif ci < len(LEVEL_COSMETICS):
                unlocks.append({"type": "cosmetic", "id": LEVEL_COSMETICS[ci]["id"]}); ci += 1
            else:
                unlocks.append({"type": "storyMemory", "id": f"memory_L{L}"})
        rewards = []
        if level_gold(L):
            rewards.append(gold(level_gold(L)))
        c = level_chest(L)
        if c:
            rewards.append(chest(c))
        if L % 10 == 0:
            rewards.append(warp(60))
        if L in (25, 50, 75, 100):
            rewards.append(cards(3, rarity="legendary"))
        if any(u["type"] == "storyMemory" for u in unlocks):
            rewards.append(item(1, rarity="rare"))
        if L == 1:
            ceremony = False  # FTUE handles level 1
        rows.append({"level": L, "unlocks": unlocks, "rewards": rewards, "ceremony": ceremony})
    assert ci == len(LEVEL_COSMETICS) and vi == len(VISITORS), (ci, vi)
    return {
        "version": 1,
        "xpCurve": {"a": 15, "p": 1.36, "roundTo": 5, "after100": 8000},
        "goldByLevel": [{"from": 2, "to": 10, "gold": 10}, {"from": 11, "to": 30, "gold": 15},
                        {"from": 31, "to": 60, "gold": 20}, {"from": 61, "to": 100, "gold": 25}],
        "levels": rows,
        "titles": [{"level": L, "name": G(TITLES[L], TITLES_F[L])} for L in sorted(TITLES)],
        "beyond100Rewards": [gold(25), chest("wood")],
    }


# ---------------------------------------------------------------- quests.json
def Q(id, m, f, metric, targets, difficulty=None, cond=None, elig="always"):
    q = {"id": id, "text": G(m, f), "metric": metric}
    if difficulty:
        q["difficulty"] = difficulty
    q["targets"] = targets
    if cond:
        q["condition"] = cond
    q["eligibility"] = elig
    return q


def quests():
    sys = lambda s: {"requiresSystem": s}
    daily = [
        Q("buyLevels", "اشتري {n} مستوى بالمحطّات", "اشتري {n} مستوى بالمحطّات", "levelsBought", [40, 80, 150, 250, 400], "medium"),
        Q("claimGoals", "خلّص {n} أهداف بالمدينة", "خلّصي {n} أهداف بالمدينة", "goalsClaimed", [1, 2, 2, 3, 3], "hard", elig="goalsRemaining"),
        Q("specials", "استقبل {n} زباين مميّزين", "استقبلي {n} زباين مميّزين", "specials", [2, 3, 4, 5, 6], "easy", cond=sys("specials")),
        Q("rushRounds", "العب {n} جولة طلبيات على السريع", "العبي {n} جولة طلبيات على السريع", "rushRounds", [1, 1, 2, 2, 3], "medium", cond=sys("rush")),
        Q("choices", "جاوب على {n} حكاية", "جاوبي على {n} حكاية", "choices", [1, 1, 2, 2, 2], "medium", cond=sys("choices")),
        Q("sendRuns", "ابعت {n} رحلة توريد", "ابعتي {n} رحلة توريد", "runsSent", [1, 2, 2, 3, 3], "easy", cond=sys("supply")),
        Q("returnRuns", "استلم {n} رحلة", "استلمي {n} رحلة", "runsClaimed", [1, 2, 2, 3, 3], "medium", cond=sys("supply")),
        Q("startResearch", "ابدأ {n} بحث بدفتر ستّي", "ابدئي {n} بحث بدفتر ستّي", "researchStarted", [1, 1, 1, 2, 2], "easy",
          cond=sys("research"), elig="researchSlotFree"),
        Q("earnMinutes", "اربح قدّ {n} دقيقة شغل", "اربحي قدّ {n} دقيقة شغل", "earnMinutes", [20, 30, 45, 60, 90], "hard"),
        Q("milestones", "وصّل {n} محطّات لعلامة جديدة", "وصّلي {n} محطّات لعلامة جديدة", "stationMilestones", [2, 3, 3, 4, 5], "medium",
          elig="stationBelowCap"),
        Q("vault", "ارجع واجمع الخزنة", "ارجعي واجمعي الخزنة", "vaultCollects", [1], "easy", cond=sys("vault")),
        Q("branches", "اجمع ذهب الفروع", "اجمعي ذهب الفروع", "branchCollects", [1], "easy", cond={"minLevel": 17}),
        Q("contractPush", "كمّل {n}% من هدف الطلبيّة الجاي", "كمّلي {n}% من هدف الطلبيّة الجاي", "contractPct", [10, 10, 15, 15, 20], "hard",
          cond=sys("contracts"), elig="activeContract"),
        Q("eventPush", "وصّل مرحلة جديدة بالمهرجان", "وصّلي مرحلة جديدة بالمهرجان", "eventMilestones", [1], "medium",
          cond=sys("events"), elig="eventLive"),
        Q("tapCook", "اطبخ {n} مرّة بإيدك", "اطبخي {n} مرّة بإيدك", "tapCooks", [30], "easy", elig="unmanagedStation"),
        Q("openChest", "افتح صندوق", "افتحي صندوق", "chestsOpened", [1], "easy", cond=sys("chests"), elig="chestInInventory"),
        Q("leagueRep", "اجمع {n} سمعة اليوم", "اجمعي {n} سمعة اليوم", "rep", [100, 150, 200, 250, 300], "hard", cond=sys("league")),
        Q("buyUpgrade", "اشتري ترقية", "اشتري ترقية", "upgradesBought", [1], "hard", cond=sys("upgrades"), elig="upgradeWithin30Min"),
        Q("chefLevelUp", "رقّي طبّاخ مستوى", "رقّي طبّاخ مستوى", "chefLevelUps", [1], "medium", cond=sys("chefs"), elig="chefUpgradable"),
    ]
    weekly = [
        Q("wDaily", "خلّص {n} طلب يومي", "خلّصي {n} طلب يومي", "dailyOrders", [15]),
        Q("wStars", "اجمع {n} نجمة", "اجمعي {n} نجمة", "stars", [20], elig="starsRemaining"),
        Q("wContract", "وصّل {n} أهداف طلبيات", "وصّلي {n} أهداف طلبيات", "contractGoals", [3], cond=sys("contracts")),
        Q("wEvent", "وصّل {n} مراحل بالمهرجان", "وصّلي {n} مراحل بالمهرجان", "eventMilestones", [6], cond=sys("events")),
        Q("wRuns", "استلم {n} رحلة توريد", "استلمي {n} رحلة توريد", "runsClaimed", [15], cond=sys("supply")),
        Q("wResearch", "خلّص {n} أبحاث", "خلّصي {n} أبحاث", "researchCompleted", [4], cond=sys("research")),
        Q("wSpecials", "استقبل {n} زبون مميّز", "استقبلي {n} زبون مميّز", "specials", [25]),
        Q("wRush", "العب {n} جولات على السريع", "العبي {n} جولات على السريع", "rushRounds", [6], cond=sys("rush")),
        Q("wRep", "اجمع {n} سمعة", "اجمعي {n} سمعة", "rep", [1500], cond=sys("league")),
        Q("wChoices", "جاوب على {n} حكايات", "جاوبي على {n} حكايات", "choices", [8], cond=sys("choices")),
        Q("wCalendar", "استلم الروزنامة {n} أيام", "استلمي الروزنامة {n} أيام", "calendarClaims", [5]),
        Q("wChef", "رقّي أي طبّاخ مرّة", "رقّي أي طبّاخ مرّة", "chefLevelUps", [1], elig="chefUpgradable"),
    ]
    return {
        "version": 1, "unlockLevel": 9,
        "bands": [{"id": 1, "minLevel": 9, "maxLevel": 14}, {"id": 2, "minLevel": 15, "maxLevel": 24},
                  {"id": 3, "minLevel": 25, "maxLevel": 39}, {"id": 4, "minLevel": 40, "maxLevel": 59},
                  {"id": 5, "minLevel": 60, "maxLevel": 9999}],
        "dailyReward": [gold(2), xp(30), sp(10), rep(20)],
        "dailyBonus": [chest("wood"), xp(40), sp(20), rep(30)],
        "weeklyReward": [gold(10), xp(120), sp(40), rep(60)],
        "weeklyBonus": [chest("silver"), xp(150), sp(50), rep(100), freezes(1)],
        "reroll": {"freePerDay": 1, "cost": 5, "maxPerDay": 3},
        "daily": daily, "weekly": weekly,
    }


# ---------------------------------------------------------------- calendar.json
def calendar():
    D = {
        1: [gold(10)], 2: [tickets(2)], 3: [chest("wood")], 4: [gold(10)], 5: [cards(3, rarity="rare")],
        6: [warp(60)], 7: [chest("silver")], 8: [gold(15)], 9: [item(1, rarity="common")], 10: [tickets(2)],
        11: [gold(15)], 12: [chest("wood")], 13: [warp(120)], 14: [chest("silver"), freezes(1)],
        15: [gold(15)], 16: [cards(5, rarity="rare")], 17: [tickets(2)], 18: [gold(20)], 19: [item(1, rarity="rare")],
        20: [warp(120)], 21: [chest("gold")], 22: [gold(15)], 23: [tickets(2)], 24: [chest("wood")],
        25: [cards(2, rarity="epic")], 26: [gold(20)], 27: [warp(240)], 28: [zaatar(1), chest("silver")],
    }
    return {
        "version": 1, "unlockLevel": 9,
        "days": [{"day": d, "rewards": D[d], "big": d % 7 == 0} for d in range(1, 29)],
        "goldScalePerCycle": 0.1, "goldScaleMax": 2,
        "streak": {
            "milestones": [
                {"days": 3, "rewards": [gold(10)]},
                {"days": 7, "rewards": [gold(20), freezes(1), chest("silver")]},
                {"days": 14, "rewards": [gold(30), freezes(1)]},
                {"days": 30, "rewards": [chest("gold"), cosmetic("frameFlame")]},
                {"days": 50, "rewards": [cards(3, rarity="epic")]},
                {"days": 100, "rewards": [cards(1, rarity="legendary"), cosmetic("propFlame")]},
                {"days": 200, "rewards": [gold(150), chest("gold")]},
                {"days": 365, "rewards": [cosmetic("awningYear"), gold(365)]},
            ],
            "freezeCaps": [{"level": 9, "cap": 2}, {"level": 45, "cap": 3}],
            "freezePrice": 50,
            "repair": {"orders": 6, "days": 2, "bonusDays": 2},
        },
    }


# ---------------------------------------------------------------- season.json
def season():
    T = {
        1: [gold(10)], 2: [chest("wood")], 3: [tickets(2)], 4: [warp(60)], 5: [chest("silver")],
        6: [gold(10)], 7: [cards(3, rarity="rare")], 8: [item(1, rarity="rare")], 9: [gold(10)],
        # "seasonCosmetic" = the next of the running theme's cosmeticIds (frame -> awning -> prop)
        10: [cards(1, id="seasonChef"), cosmetic("seasonCosmetic")],
        11: [chest("wood")], 12: [tickets(2)], 13: [gold(10)], 14: [warp(60)], 15: [gold(20)],
        16: [cards(3, rarity="rare")], 17: [chest("wood")], 18: [item(1, rarity="rare")], 19: [gold(10)],
        20: [hcase(1)], 21: [tickets(2)], 22: [gold(10)], 23: [warp(120)], 24: [chest("silver")],
        25: [cards(5, id="seasonChef"), cosmetic("seasonCosmetic")],
        26: [gold(10)], 27: [chest("wood")], 28: [cards(3, rarity="rare")], 29: [gold(10)], 30: [chest("gold")],
        31: [tickets(2)], 32: [warp(120)], 33: [gold(10)], 34: [item(1, rarity="epic")],
        35: [cards(4, id="seasonChef")], 36: [gold(10)], 37: [chest("wood")], 38: [freezes(1)], 39: [gold(10)],
        40: [gold(20)], 41: [tickets(2)], 42: [warp(240)], 43: [chest("silver")], 44: [gold(10)],
        45: [cards(6, id="seasonChef")], 46: [hcase(1)], 47: [gold(10)], 48: [cards(3, rarity="epic")],
        49: [gold(20)],
        50: [cards(5, rarity="legendary"), cosmetic("seasonCosmetic"), cosmetic("frameSeasonChampion")],
    }
    themes = []
    for idx, tid, name, art, chef_id, cos, twist in season_themes():
        themes.append({"index": idx, "id": tid, "name": name, "art": art, "chefId": chef_id,
                       "cosmeticIds": [c["id"] for c in cos], "eventTwist": twist})
    pts = lambda a, cap=None: ({"amount": a, "dailyCap": cap} if cap is not None else {"amount": a})
    return {
        "version": 1, "unlockLevel": 16, "epoch": "2026-01-05", "lengthDays": 42, "pointsPerTier": 140,
        "tiers": [{"tier": t, "rewards": T[t]} for t in range(1, 51)],
        "overflow": {"pointsPer": 300, "rewards": [chest("wood")], "max": 10},
        "lateJoinerMaxMult": 2,
        "points": {"dailyOrder": pts(10), "dailyBonus": pts(20), "weeklyOrder": pts(40), "weeklyBonus": pts(50),
                   "calendar": pts(10), "goalStar": pts(2), "contractGoal1": pts(20), "contractGoal2": pts(30),
                   "contractGoal3": pts(50), "eventMilestone": pts(15), "leagueWeek": pts(30),
                   "leaguePromotion": pts(30), "researchLevel": pts(5), "supplyRun": pts(5, 25),
                   "rushRound": pts(5, 15), "special": pts(1, 10)},
        "themes": themes,
    }


# ---------------------------------------------------------------- festivals.json
def festivals():
    md = lambda m, d: {"month": m, "day": d}
    F = []
    F.append({"id": "ramadan", "name": "رمضان", "neutralName": "أيام البركة", "art": "ui_crescent_moon",
              "calendar": "hijri", "start": md(9, 1), "end": md(9, 30), "eveDays": 1, "extraEndDays": 0,
              "effects": [],
              "activeWindows": [
                  {"kind": "iftar", "startOffsetMin": -10, "endOffsetMin": 80, "mult": 5, "replacesRushHour": "dinner"},
                  {"kind": "suhoor", "startHour": 2, "endHour": 4.5, "mult": 2}],
              "collectible": {"id": "lantern", "name": "فانوس", "art": "ui_lantern", "count": 30,
                              "milestones": [{"count": 10, "rewards": [chest("silver")]},
                                             {"count": 20, "rewards": [gold(30)]},
                                             {"count": 30, "rewards": [cosmetic("lightsRamadan")]}]},
              "eventThemeId": "ramadanNights", "happeningTag": "ramadan", "storySceneId": "fest_ramadan",
              "notificationQuiet": {"start": "23:30", "end": "10:00", "streakRiskAt": "21:30"}})
    F.append({"id": "eidFitr", "name": "عيد الفطر", "neutralName": "أيام البركة", "art": "food_cookie",
              "calendar": "hijri", "start": md(10, 1), "end": md(10, 3), "eveDays": 1, "extraEndDays": 1,
              "effects": [e_income(scope_all(), 1.5, "day")],
              "dailyClaim": [gold(15), chest("wood")],
              "eventThemeId": "eidSweets", "happeningTag": "eidFitr", "storySceneId": "fest_eidFitr"})
    F.append({"id": "eidAdha", "name": "عيد الأضحى", "neutralName": "أيام البركة", "art": "ani_sheep",
              "calendar": "hijri", "start": md(12, 10), "end": md(12, 13), "eveDays": 1, "extraEndDays": 1,
              "effects": [e_income(scope_all(), 1.5, "day")],
              "dailyClaim": [gold(15), chest("wood")],
              "eventThemeId": "eidFeast", "happeningTag": "eidAdha", "storySceneId": "fest_eidAdha"})
    F.append({"id": "oliveHarvest", "name": "موسم الزيتون", "neutralName": "أيام البركة", "art": "food_olive",
              "calendar": "gregorian", "start": md(10, 15), "end": md(11, 30), "eveDays": 0, "extraEndDays": 0,
              "effects": [e_income(scope_cui("palestinian"), 1.25, "day")],
              "eventThemeId": "oliveHarvest", "happeningTag": "oliveHarvest", "storySceneId": "fest_oliveHarvest"})
    F.append({"id": "summer", "name": "الصيفيّة", "neutralName": "أيام البركة", "art": "ui_sun",
              "calendar": "gregorian", "start": md(7, 1), "end": md(8, 31), "eveDays": 0, "extraEndDays": 0,
              "effects": [e_income(scope_wt("cold"), 1.25, "day")],
              "eventThemeId": "summerBeach", "happeningTag": "summer", "storySceneId": "fest_summer"})
    F.append({"id": "backToSchool", "name": "رجعة المدارس", "neutralName": "أيام البركة", "art": "bld_school",
              "calendar": "gregorian", "start": md(9, 1), "end": md(9, 10), "eveDays": 0, "extraEndDays": 0,
              "effects": [], "dailyClaim": [gold(2)], "happeningTag": "backToSchool",
              "storySceneId": "fest_backToSchool"})
    F.append({"id": "bethlehemChristmas", "name": "ميلاد بيت لحم", "neutralName": "أيام البركة", "art": "ui_glowing_star",
              "calendar": "gregorian", "start": md(12, 20), "end": md(1, 7), "eveDays": 0, "extraEndDays": 0,
              "effects": [e_income(scope_wt("hot"), 1.25, "day")],
              "eventThemeId": "bethlehemChristmas", "happeningTag": "bethlehemChristmas",
              "storySceneId": "fest_bethlehemChristmas"})
    F.append({"id": "mothersDay", "name": "عيد الأم", "neutralName": "يوم العيلة", "art": "ui_bouquet",
              "calendar": "gregorian", "start": md(3, 21), "end": md(3, 21), "eveDays": 0, "extraEndDays": 0,
              "effects": [], "dailyClaim": [cards(1, id="sittiUmmKhalil")], "storySceneId": "fest_mothersDay"})
    return {"version": 1, "sunsetRef": {"lat": 31.78, "lon": 35.23}, "quietDates": ["05-15"], "festivals": F}


# ---------------------------------------------------------------- achievements.json
ACH = [
    ("handCook", "طبّاخ بإيده", "ppl_man_cook", "tapCooks", [100, 1000, 5000, 20000, 100000], "اطبخ {n} مرّة بإيدك", "اطبخي {n} مرّة بإيدك"),
    ("customers", "زباين وبس", "ppl_raising_hands", "customers", [1e3, 1e5, 1e7, 1e9, 1e11], "خدّم {n} زبون", "خدّمي {n} زبون"),
    ("stars", "نجوم المعلّم", "ui_star", "starsEarned", [10, 50, 200, 500, 1000], "اجمع {n} نجمة", "اجمعي {n} نجمة"),
    ("cities", "مسافر", "bld_world_map", "citiesGraduated", [1, 4, 8, 16, 23], "افتح فروع بـ {n} مدن", "افتحي فروع بـ {n} مدن"),
    ("crowns", "تيجان", "ui_crown", "crowns", [1, 5, 10, 18, 24], "خذ تاج {n} مدن", "خذي تاج {n} مدن"),
    ("level", "مستوى المعلّم", "ui_sparkles", "empireLevel", [10, 25, 50, 75, 100], "وصّل مستوى {n}", "وصّلي مستوى {n}"),
    ("managers", "صاحب شغل", "ppl_handshake", "managersHired", [10, 50, 100, 150, 180], "وظّف {n} معلّم", "وظّفي {n} معلّم"),
    ("upgrades", "مستثمر", "ui_chart_up", "upgradesBought", [5, 25, 75, 150, 250], "اشتري {n} ترقية", "اشتري {n} ترقية"),
    ("maxStations", "للآخر", "ui_top_arrow", "stationsMaxed", [1, 10, 30, 80, 150], "كمّل {n} محطّة لآخر مستوى", "كمّلي {n} محطّة لآخر مستوى"),
    ("chefsOwned", "فريق الطبخ", "ppl_cook", "chefsOwned", [5, 10, 18, 25, 32], "جمّع {n} طبّاخ", "جمّعي {n} طبّاخ"),
    ("chefLevel", "معلّم الطبّاخين", "ui_glowing_star", "bestChefLevel", [3, 5, 7, 9, 10], "رقّي طبّاخ لمستوى {n}", "رقّي طبّاخ لمستوى {n}"),
    ("chests", "فتّاح الصناديق", "ui_gift", "chestsOpened", [10, 50, 150, 400, 1000], "افتح {n} صندوق", "افتحي {n} صندوق"),
    ("research", "دفتر ستّي", "ui_notebook", "researchLevels", [5, 25, 75, 150, 302], "خلّص {n} بحث بالدفتر", "خلّصي {n} بحث بالدفتر"),
    ("runs", "راعي رحلات", "veh_pickup_truck", "runsClaimed", [5, 25, 100, 300, 1000], "استلم {n} رحلة توريد", "استلمي {n} رحلة توريد"),
    ("heritage", "حارس التراث", "ui_old_key", "heritageUnique", [4, 12, 20, 28, 32], "جمّع {n} قطعة تراث مختلفة", "جمّعي {n} قطعة تراث مختلفة"),
    ("sets", "المجموعة كاملة", "ui_puzzle_piece", "setsCompleted", [1, 2, 4, 6, 8], "كمّل {n} مجموعات تراث", "كمّلي {n} مجموعات تراث"),
    ("contracts", "معلّم طلبيات", "ui_clipboard", "contractsCompleted", [1, 5, 15, 30, 60], "خلّص {n} طلبيّة للآخر", "خلّصي {n} طلبيّة للآخر"),
    ("events", "نجم المهرجان", "ui_party_popper", "eventsMaxed", [1, 3, 8, 15, 30], "وصّل آخر مرحلة بـ {n} مهرجانات", "وصّلي آخر مرحلة بـ {n} مهرجانات"),
    ("league", "ابن الدوري", "ui_trophy", "bestLeagueTier", [2, 4, 6, 8, 10], "اطلع للدرجة {n} بالدوري", "اطلعي للدرجة {n} بالدوري"),
    ("season", "ابن الموسم", "ui_ticket", "seasonsCompleted", [1, 2, 4, 6, 10], "كمّل {n} مواسم للآخر", "كمّلي {n} مواسم للآخر"),
    ("streak", "نار ما بتنطفي", "ui_fire", "bestStreak", [7, 30, 100, 200, 365], "خلّي السلسلة توصل {n} يوم", "خلّي السلسلة توصل {n} يوم"),
    ("calendar", "ابن الروزنامة", "ui_spiral_calendar", "calendarClaims", [7, 28, 84, 168, 336], "استلم الروزنامة {n} يوم", "استلمي الروزنامة {n} يوم"),
    ("dailyOrders", "شغّيل", "ui_check_mark_button", "dailyOrders", [10, 50, 200, 500, 1000], "خلّص {n} طلب يومي", "خلّصي {n} طلب يومي"),
    ("specials", "صيّاد الزباين", "ui_bellhop_bell", "specials", [10, 50, 200, 500, 1500], "استقبل {n} زبون مميّز", "استقبلي {n} زبون مميّز"),
    ("stories", "حكواتي", "ui_speech_balloon", "choices", [5, 25, 75, 150, 300], "جاوب على {n} حكاية", "جاوبي على {n} حكاية"),
    ("rush", "على السريع", "ui_stopwatch", "rushRounds", [5, 25, 100, 250, 500], "العب {n} جولة على السريع", "العبي {n} جولة على السريع"),
    ("zaatar", "زعتر ذهبي", "food_herb", "zaatar", [1, 5, 15, 30, 50], "جمّع {n} زعتر ذهبي", "جمّعي {n} زعتر ذهبي"),
    ("branches", "صاحب فروع", "bld_department_store", "branchLevels", [5, 20, 50, 100, 230], "رقّي الفروع {n} مستوى", "رقّي الفروع {n} مستوى"),
    ("festivals", "ابن المواسم", "ui_lantern", "festivals", [1, 3, 5, 8, 12], "عيّد {n} مواسم مع البسطة", "عيّدي {n} مواسم مع البسطة"),
    ("karma", "قلب طيّب", "ui_red_heart", "karma", [3, 10, 20, 40, 80], "اعمل خير {n} مرّات بالحكايات", "اعملي خير {n} مرّات بالحكايات"),
]


def achievements():
    fams = [{"id": i, "name": n, "art": a, "metric": m, "tiers": t, "desc": G(dm, df)} for i, n, a, m, t, dm, df in ACH]
    return {"version": 1,
            "tierRewards": [{"gold": 5, "xp": 20}, {"gold": 10, "xp": 40}, {"gold": 15, "xp": 80},
                            {"gold": 25, "xp": 150}, {"gold": 40, "xp": 250}],
            "families": fams}


def main():
    for name, fn in [("cosmetics.json", cosmetics), ("levels.json", levels), ("quests.json", quests),
                     ("calendar.json", calendar), ("season.json", season), ("festivals.json", festivals),
                     ("achievements.json", achievements)]:
        print("wrote", write_json(name, fn()))


if __name__ == "__main__":
    main()
