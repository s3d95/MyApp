"""economy.json, chefs.json, research.json, vehicles.json, heritage.json"""
from common import *

# ---------------------------------------------------------------- economy.json
def economy():
    city = [
        (5, 1.09, 1, 1, 200), (60, 1.15, 3, 60, 200), (720, 1.14, 6, 540, 120),
        (8640, 1.13, 12, 4320, 60), (103680, 1.12, 24, 51840, 15),
        (1244160, 1.11, 96, 622080, 8), (14929920, 1.10, 384, 7464960, 6),
        (179159040, 1.09, 1536, 89579520, 4),
    ]
    side = [
        (10, 1.10, 2, 2, 20), (150, 1.12, 8, 60, 20), (2500, 1.13, 30, 1500, 15),
        (40000, 1.14, 120, 40000, 10), (800000, 1.15, 480, 1200000, 8),
    ]
    row = lambda t: {"baseCost": t[0], "growth": t[1], "baseCycleSec": t[2], "baseRevenue": t[3], "managerMult": t[4]}
    return {
        "version": 1,
        "cityTiers": [row(t) for t in city],
        "sideTiers": [row(t) for t in side],
        "stationMilestones": [10, 25, 50, 100, 150, 200, 250, 300, 350, 400],
        "allStationMilestones": [25, 50, 100, 150, 200, 250, 300, 400],
        "sideStationMilestones": [10, 25, 50, 75, 100, 125, 150],
        "sideAllStationMilestones": [25, 50, 100, 150],
        "milestoneMult": 2,
        "cycleFloorSec": 0.5,
        "levelCaps": [
            {"fromCity": 1, "toCity": 3, "cap": 100}, {"fromCity": 4, "toCity": 8, "cap": 200},
            {"fromCity": 9, "toCity": 16, "cap": 300}, {"fromCity": 17, "toCity": 24, "cap": 400},
        ],
        "sideLevelCap": 150,
        "upgradeBase": 250000, "upgradeRatio": 20, "upgradeMult": 3,
        "sideUpgrades": {"base": 20000, "ratio": 30, "count": 3, "targets": ["0", "1", "all"]},
        "cityStartCashBase": 50, "sideStartCash": 20,
        "offline": {"baseCapHours": 3, "maxCapHours": 16, "baseEff": 0.5, "minGapSec": 60,
                    "doubleGoldPerHour": 10, "doubleMin": 5, "doubleMax": 160},
        "freshDough": {"minGapHours": 24, "minutesPerDay": 30, "maxDays": 3, "mult": 2},
        "boosts": {"rushHourMult": 2, "rushHourAddPerLevel": 0.1, "rushWindows": [[12, 14], [19, 22]],
                   "frenzyMult": 5, "frenzySec": 60, "frenzySecPerLevel": 6,
                   "wallaMult": 2, "wallaMinMin": 5, "wallaMaxMin": 30, "wallaPerScore": 400,
                   "wallaBankMaxMin": 60, "activeCap": 50, "dayCap": 5},
        "timeWarpShop": {"unlockLevel": 24, "goldPerHour": 10, "fourHourPrice": 36, "maxPerDay": 3},
        "rushTickets": {"regenHours": 3, "cap": 3, "capL35": 4, "overflowMax": 9, "goldPrice": 10, "maxBuyPerDay": 3},
        "vaultDouble": {"perDay": 1},
        "rushGoldPerMinute": 1 / 6,
        "branches": {"goldPerDayBase": 0.5, "goldPerLevel": 0.2, "softcapKnee": 10, "softcapCoef": 2,
                     "safeCapHours": 8, "incomePerBranch": 0.10, "incomePerLevel": 0.02, "maxLevel": 10,
                     "upgradeCosts": [20, 45, 80, 125, 180, 245, 320, 405, 500, 605]},
        "grades": [
            {"id": 1, "name": "سهل", "minLevel": 0, "targetFactor": 1, "goldMult": 1, "xpMult": 1, "goal1Chest": "wood"},
            {"id": 2, "name": "متوسط", "minLevel": 20, "targetFactor": 4, "goldMult": 1.25, "xpMult": 1.2, "goal1Chest": "wood"},
            {"id": 3, "name": "صعب", "minLevel": 35, "targetFactor": 15, "goldMult": 1.5, "xpMult": 1.4, "goal1Chest": "silver"},
            {"id": 4, "name": "صعب كتير", "minLevel": 55, "targetFactor": 60, "goldMult": 1.75, "xpMult": 1.6, "goal1Chest": "silver"},
            {"id": 5, "name": "أسطوري", "minLevel": 80, "targetFactor": 250, "goldMult": 2, "xpMult": 1.8, "goal1Chest": "gold"},
        ],
        "xp": {"perStar": 10, "cityBonusPerIndex": 0.1, "stationMilestone": 2, "stationUnlock": 4,
               "managerHire": 2, "graduationPerIndex": 50,
               "dailyOrder": 30, "dailyBonus": 40, "weeklyOrder": 120, "weeklyBonus": 150,
               "calendarClaim": 15, "researchBase": 10, "researchPerLevel": 2,
               "supplyShort": 10, "supplyMid": 20, "supplyLong": 40, "supplyPerVehicleTier": 0.25,
               "contractGoal1": 50, "contractGoal2": 100, "contractGoal3": 200,
               "eventMilestone": 30, "eventMilestoneFinal": 100,
               "leagueWeekBase": 50, "leagueWeekPerTier": 10, "leaguePromotion": 50,
               "special": 2, "choice": 5, "rushRound": 10, "inspectorPerPoint": 4,
               "achievementTiers": [20, 40, 80, 150, 250]},
        "priceScaleFormula": "max(1, M_k/3)",
    }


# ---------------------------------------------------------------- chefs.json
def skill(t, magnitude, dur, cd, name, value=None):
    s = {"type": t}
    if value is not None:
        s["value"] = value
    s.update({"magnitude": magnitude, "durationSec": dur, "cooldownMin": cd, "name": name})
    return s


CHEFS = [
    # ---- common (12) ----
    dict(id="samiFryer", name="سامي القلّاي", rarity="common", art="ppl_man_cook", cuisine="palestinian", category="fried",
         bio="بيقلي الفلافل وهو مغمّض، وبيعرف القرص استوى من صوته"),
    dict(id="ummMohammad", name="أم محمد", rarity="common", art="ppl_woman_headscarf", cuisine="palestinian", category="bakery",
         bio="طابونها بيصحّي الحارة كلها على ريحة الخبز السخن"),
    dict(id="abuAbedFul", name="أبو العبد الفوّال", rarity="common", art="ppl_older_person", cuisine="palestinian", category="dishes",
         bio="قدرة الفول عنده من أيام أبوه، وما بتنطفي ولا يوم"),
    dict(id="laylaStudent", name="ليلى طالبة بيرزيت", rarity="common", art="ppl_woman", cuisine="levantine", category="drinks",
         bio="بتدرس هندسة، وبتعمل أطيب ليموناضة بالجامعة كلها"),
    dict(id="abuSalimSweets", name="أبو سليم الحلونجي", rarity="common", art="ppl_old_man", cuisine="levantine", category="sweets",
         bio="بيوزن القطر بعينه، وما بيغلط ولا نقطة"),
    dict(id="hassanGrill", name="حسن الشوّا", rarity="common", art="ppl_man", cuisine="levantine", category="grill",
         bio="بيقلّب السيخ وبيغنّي، والفحم بيرقص معه"),
    dict(id="nadiaCairo", name="نادية المصريّة", rarity="common", art="ppl_woman_cook", cuisine="egyptian", category="street",
         bio="بتقول عنها طعميّة مش فلافل، وإحنا ساكتين عشان الطعم بيجنّن"),
    dict(id="mustafaKoshari", name="مصطفى الكشري", rarity="common", art="ppl_beard", cuisine="egyptian", category="dishes",
         bio="صحن الكشري عنده طبقات أكتر من عمارة"),
    dict(id="khaledSea", name="خالد البحري", rarity="common", art="ppl_man_farmer", cuisine="palestinian", category="seafood",
         bio="بيعرف السمكة الطازة من لمعة عينها"),
    dict(id="fatimaMaghreb", name="فاطمة المغربيّة", rarity="common", art="ppl_woman_headscarf", cuisine="maghrebi", category="dishes",
         bio="طنجرة الطاجين عندها بتحكي حكايات مراكش"),
    dict(id="muratGrill", name="مراد التركي", rarity="common", art="ppl_man_cook", cuisine="turkish", category="grill",
         bio="بيحلف إنّ الكباب اختراع تركي، وإحنا منضحك ومنوكل"),
    dict(id="yukiStreet", name="يوكي", rarity="common", art="ppl_woman", cuisine="world", category="street",
         bio="جاية من طوكيو تتعلّم الفلافل، وصارت تقول «يا عمّي» أحسن منّا"),
    # ---- rare (9) ----
    dict(id="hajjaUmmSubhi", name="الحجّة أم صبحي", rarity="rare", art="ppl_old_woman", cuisine="palestinian", category="dishes",
         bio="بتقلب المقلوبة وما بتوقع ولا حبّة رز"),
    dict(id="abuGeorgeHalabi", name="أبو جورج الحلبي", rarity="rare", art="ppl_beard", cuisine="levantine", category="grill",
         bio="كبابه حلبي أصلي، والبهارات سرّ ما بيحكيه لحدا"),
    dict(id="reemCoffee", name="ريم القهوجيّة", rarity="rare", art="ppl_woman_office", cuisine="gulf", category="drinks",
         bio="دلّتها ما بتبرد، وفنجانها بيصحّي النايم"),
    dict(id="abuFahdKabsa", name="أبو فهد", rarity="rare", art="ppl_turban", cuisine="gulf", category="dishes",
         bio="صينيّة الكبسة عنده بتكفّي الحارة والضيوف وزيادة"),
    dict(id="monaSweets", name="منى الحلوانيّة", rarity="rare", art="ppl_woman_cook", cuisine="egyptian", category="sweets",
         bio="البسبوسة عندها بتدوب بالتمّ قبل ما تبلعها"),
    dict(id="karimBaghdadi", name="كريم البغدادي", rarity="rare", art="ppl_man", cuisine="iraqi", category="bakery",
         bio="الصمّون عنده طالع من الفرن منفوخ زي الغيمة"),
    dict(id="aminaMsemen", name="أمينة", rarity="rare", art="ppl_woman_headscarf", cuisine="maghrebi", category="bakery",
         bio="المسمّن عندها طبقات طبقات، وكل طبقة أطيب من اللي قبلها"),
    dict(id="ozanBaklava", name="أوزان", rarity="rare", art="ppl_man_cook", cuisine="turkish", category="sweets",
         bio="بيعدّ طبقات البقلاوة: أربعين بالتمام والكمال"),
    dict(id="mariaChile", name="ماريا", rarity="rare", art="ppl_woman", cuisine="world", category="street",
         bio="من سانتياغو، ستّها من بيت جالا، وبتعمل إمبانادا بالزعتر"),
    # ---- epic (6) ----
    dict(id="chefRami", name="الشيف رامي، ملك الفلافل", rarity="epic", art="ppl_man_cook", cuisine="palestinian", category="fried",
         skill=skill("categoryBoost", 5, 180, 45, "نار الصاج", "fried"),
         bio="قرص الفلافل عنده بيطلع مدوّر زيّ القمر"),
    dict(id="sittElSham", name="ستّ الشام", rarity="epic", art="ppl_woman_cook", cuisine="levantine", category="dishes",
         skill=skill("cuisineBoost", 4, 240, 50, "نَفَس الشام", "levantine"),
         bio="بتلفّ ورق العنب وبتحكي حكايات، والحكاية أطيب من المحشي"),
    dict(id="abuAliAlex", name="أبو علي الإسكندراني", rarity="epic", art="ppl_older_person", cuisine="egyptian", category="seafood",
         skill=skill("instantIncome", 20, 0, 60, "صيدة اليوم"),
         bio="بيرمي الشبكة مرّة وحدة، وبيطلّع رزق أسبوع"),
    dict(id="chefNoura", name="الشيف نورة", rarity="epic", art="ppl_woman_headscarf", cuisine="gulf", category="sweets",
         skill=skill("spawnSpecial", 1, 0, 30, "ريحة اللقيمات"),
         bio="لقيماتها بتجيب الزباين من آخر الشارع"),
    dict(id="chefHakim", name="الشيف حكيم", rarity="epic", art="ppl_man", cuisine="maghrebi", category="grill",
         skill=skill("categoryBoost", 5, 180, 45, "جمر مراكش", "grill"),
         bio="مشاويه على طريقة مراكش، والدخنة بتعمل دعاية لحالها"),
    dict(id="chefHiro", name="الشيف هيرو", rarity="epic", art="ppl_man_cook", cuisine="world", category="seafood",
         skill=skill("frenzy", 5, 60, 40, "تقطيع البرق"),
         bio="بيقطّع الخيارة بثانية، وبيسلّم عالزبون بانحناءة"),
    # ---- legendary (3) ----
    dict(id="chefMaher", name="الشيف ماهر «رايح جاي»", rarity="legendary", art="ppl_person_with_crown", cuisine="world", category="street",
         skill=skill("allBoost", 3, 300, 60, "لفّة الدنيا"),
         bio="لفّ الدنيا بعربايته، ورجع يقول: ما في أطيب من أكل البلد"),
    dict(id="abuNasser", name="المعلّم أبو ناصر", rarity="legendary", art="ppl_old_man", cuisine="levantine", category="grill",
         skill=skill("allBoost", 2, 600, 90, "كلمة المعلّم"),
         bio="خمسين سنة عالمنقل، والناس بتوقف بالدور بس لتسلّم عليه"),
    dict(id="sultanaLama", name="السلطانة لمى", rarity="legendary", art="ppl_princess", cuisine="gulf", category="drinks",
         skill=skill("instantIncome", 60, 0, 120, "كرم السلطانة"),
         bio="بتضيّف المدينة كلها قهوة وتمر، وبتقول: الكرم ما بيخلص"),
    # ---- exclusives ----
    dict(id="sittiUmmKhalil", name="ستّي أم خليل", rarity="legendary", art="ppl_old_woman", cuisine="palestinian", category="any",
         source="story", skill=skill("allBoost", 3, 300, 60, "عزومة ستّي"),
         bio="صاحبة الوصفة الأصليّة، وصاحبة أحلى ضحكة بالحارة"),
    dict(id="abuSubhiOG", name="أبو صبحي الأوّلاني", rarity="legendary", art="ppl_older_person", cuisine="palestinian", category="fried",
         source="legacy", skill=skill("categoryBoost", 6, 240, 45, "قلية زمان", "fried"),
         bio="كان معك من أوّل بسطة، وما نسي ولا زبون"),
    # ---- season exclusives (epic, one per season theme) ----
    dict(id="sAbuJiries", name="أبو جريس الشتوي", rarity="epic", art="ppl_beard", cuisine="palestinian", category="street",
         source="season", seasonThemeIndex=0, skill=skill("cuisineBoost", 4, 240, 50, "كانون الشتا", "palestinian"),
         bio="الكستنا عنده بتفرقع عالنار، وبتدفّي القلب قبل الإيدين"),
    dict(id="sUmmZaatar", name="أم زعتر", rarity="epic", art="ppl_woman_farmer", cuisine="levantine", category="bakery",
         source="season", seasonThemeIndex=1, skill=skill("categoryBoost", 5, 180, 45, "زعتر الجبل", "bakery"),
         bio="بتقطف الزعتر مع طلعة الشمس، وبتخبز قبل ما تصحى الحارة"),
    dict(id="sRayyesBahri", name="الريّس بحري", rarity="epic", art="ppl_old_man", cuisine="palestinian", category="seafood",
         source="season", seasonThemeIndex=2, skill=skill("instantIncome", 20, 0, 60, "شبكة الريّس"),
         bio="بيقرا البحر زي الجريدة، وبيعرف وين السمك مخبّى"),
    dict(id="sAbuZeit", name="أبو زيت", rarity="epic", art="ppl_man_farmer", cuisine="palestinian", category="dishes",
         source="season", seasonThemeIndex=3, skill=skill("categoryBoost", 5, 180, 45, "أوّل عصرة", "dishes"),
         bio="زيته من الشجر الرومي، وكل نقطة فيها حكاية"),
    dict(id="sSuhair", name="سهير", rarity="epic", art="ppl_singer", cuisine="levantine", category="drinks",
         source="season", seasonThemeIndex=4, skill=skill("frenzy", 5, 60, 40, "موّال السهرة"),
         bio="بتغنّي عالبسطة، والناس بتوقف تسمع وبتطلب كمان"),
    dict(id="sUmmAlArsan", name="أم العرسان", rarity="epic", art="ppl_woman_headscarf", cuisine="levantine", category="sweets",
         source="season", seasonThemeIndex=5, skill=skill("categoryBoost", 5, 180, 45, "زغرودة", "sweets"),
         bio="ما في عرس بالحارة بدونها وبدون صدر الكنافة تبعها"),
    dict(id="sRahhal", name="رحّال", rarity="epic", art="ppl_pilot", cuisine="world", category="street",
         source="season", seasonThemeIndex=6, skill=skill("spawnSpecial", 1, 0, 30, "طيّارة زباين"),
         bio="بيجيب زباين من كل مطارات الدنيا لبسطتك"),
    dict(id="sBintSitti", name="بنت ستّي", rarity="epic", art="ppl_girl", cuisine="palestinian", category="sweets",
         source="season", seasonThemeIndex=7, skill=skill("cuisineBoost", 4, 240, 50, "دلع ستّي", "palestinian"),
         bio="تعلّمت الحلو على إيدين ستّي، وصارت تنافسها"),
]


def chefs():
    out = []
    for c in CHEFS:
        row = {"id": c["id"], "name": c["name"], "rarity": c["rarity"], "art": c["art"],
               "cuisine": c["cuisine"], "category": c["category"], "source": c.get("source", "chest")}
        if "seasonThemeIndex" in c:
            row["seasonThemeIndex"] = c["seasonThemeIndex"]
        if "skill" in c:
            row["skill"] = c["skill"]
        row["bio"] = c["bio"]
        out.append(row)
    rar = lambda c, r, e, l: {"common": c, "rare": r, "epic": e, "legendary": l}
    chests = [
        {"id": "wood", "name": "صندوق خشب", "art": "ui_gift", "stacks": 3, "cards": 8, "goldMin": 2, "goldMax": 5,
         "odds": rar(0.80, 0.18, 0.02, 0.0), "price": 50},
        {"id": "silver", "name": "صندوق فضّة", "art": "ui_gift", "stacks": 4, "cards": 20, "goldMin": 8, "goldMax": 20,
         "odds": rar(0.62, 0.30, 0.075, 0.005), "guarantee": "rare", "price": 150},
        {"id": "gold", "name": "صندوق ذهب", "art": "ui_gift", "stacks": 5, "cards": 45, "goldMin": 25, "goldMax": 50,
         "odds": rar(0.45, 0.37, 0.15, 0.03), "guarantee": "epic", "price": 400},
    ]
    rules = {
        "rarityBase": rar(0.25, 0.50, 1.00, 2.00),
        "perLevel": 0.25, "maxLevel": 10, "bothMatchFactor": 1.5,
        "cardsToLevel": rar([2, 4, 8, 15, 25, 40, 60, 90, 130], [2, 3, 6, 10, 16, 25, 36, 50, 70],
                            [1, 2, 4, 6, 9, 13, 18, 24, 32], [1, 1, 2, 3, 4, 6, 8, 10, 13]),
        "goldToLevel": [5, 10, 20, 35, 50, 75, 100, 150, 200],
        "surplusGold": rar(1, 3, 8, 20),
        "slotsByLevel": [{"level": 4, "slots": 1}, {"level": 8, "slots": 2}, {"level": 15, "slots": 3},
                         {"level": 25, "slots": 4}, {"level": 40, "slots": 5}, {"level": 60, "slots": 6}],
        "pity": {"legendaryAfterChests": 12, "epicAfterSilver": 5},
        "newChefStackChance": 0.35,
        "stackWeights": rar(1.0, 0.5, 0.2, 0.08),
        # Calendar weekdays: 1 = Sunday ... 6 = Friday, 7 = Saturday
        "dailyStall": [
            {"slot": 1, "rarity": "common", "cards": 10, "price": 20},
            {"slot": 2, "rarity": "rare", "cards": 5, "price": 40},
            {"slot": 3, "rarity": "epic", "cards": 2, "price": 80, "weekdays": [1, 2, 3, 4, 5, 7]},
            {"slot": 3, "rarity": "legendary", "cards": 1, "price": 150, "weekdays": [6]},
        ],
    }
    return {"version": 1, "chefs": out, "chests": chests, "rules": rules}


# ---------------------------------------------------------------- research.json
def research():
    N = lambda id, name, branch, art, eff, per, mx, unlock, tm, cm, desc, req=None: dict(
        [("id", id), ("name", name), ("branch", branch), ("art", art),
         ("effect", {"type": eff, "perLevel": per}), ("maxLevel", mx), ("unlockLevel", unlock)]
        + ([("requires", req)] if req else [])
        + [("timeMult", tm), ("costMin", cm), ("desc", desc)])
    req = lambda nid, lvl: [{"nodeId": nid, "level": lvl}]
    nodes = [
        # المطبخ
        N("secretBlend", "خلطة ستّي", "kitchen", "food_herb", "cityIncomePct", 0.05, 40, 7, 1.0, 4,
          "دخل كل المدن +{v}، والجاي +{next}"),
        N("loyalManagers", "معلّمين أوفياء", "kitchen", "ppl_handshake", "managerCostPct", 0.05, 10, 7, 0.5, 2,
          "المعلّمين أرخص بـ {v}، والجاي {next}"),
        N("honestSupplier", "مورّد أمين", "kitchen", "ui_balance_scale", "stationCostPct", 0.02, 15, 12, 1.0, 3,
          "مستويات المحطّات أرخص بـ {v}، والجاي {next}", req("loyalManagers", 2)),
        N("gentleFire", "نار هادية", "kitchen", "ui_fire", "speedPct", 0.02, 30, 20, 1.5, 4,
          "كل المحطّات أسرع بـ {v}، والجاي {next}", req("secretBlend", 5)),
        # الزباين
        N("happyCustomer", "زبون مبسوط", "customers", "ui_bellhop_bell", "specialRewardPct", 0.10, 10, 7, 0.8, 2,
          "هدايا الزبون المميّز +{v}، والجاي +{next}"),
        N("longerRush", "عجقة أطول", "customers", "ui_stopwatch", "frenzySec", 6, 10, 10, 0.8, 2,
          "عجقة الزباين بتطوّل {v} ثانية زيادة، والجاي {next}", req("happyCustomer", 1)),
        N("peakHour", "ساعة الذروة", "customers", "ui_alarm_clock", "rushHourAdd", 0.1, 10, 12, 1.0, 3,
          "ساعة الذروة بتعطي +{v} فوق الدبل، والجاي +{next}"),
        N("sweetTalk", "كلمة حلوة", "customers", "ui_speech_balloon", "happeningRewardPct", 0.10, 10, 14, 1.0, 3,
          "جوائز الحكايات والمفتّش والضيوف الكبار والتوصيل والميناء +{v}، والجاي +{next}", req("happyCustomer", 3)),
        # الخزنة والوقت
        N("biggerVault", "خزنة أكبر", "vault", "ui_locked_with_key", "vaultCapHours", 1, 9, 7, 0.6, 3,
          "الخزنة بتوسع {v} ساعات زيادة، والجاي {next}"),
        N("tightHarvest", "ضبّ الغلّة", "vault", "ui_money_bag", "vaultEffPct", 0.05, 10, 8, 0.8, 3,
          "الخزنة بتجمع +{v} من الدخل وإنت برّا، والجاي +{next}", req("biggerVault", 1)),
        N("shortcuts", "طرق مختصرة", "vault", "bld_compass", "supplyTimePct", 0.03, 10, 10, 1.0, 2,
          "رحلات التوريد أقصر بـ {v}، والجاي {next}"),
        N("tidyNotebook", "دفتر مرتّب", "vault", "ui_bookmark_tabs", "researchTimePct", 0.02, 15, 16, 1.2, 3,
          "أبحاث الدفتر أسرع بـ {v}، والجاي {next}", req("biggerVault", 3)),
        # الإمبراطوريّة
        N("smartBranches", "فروع شاطرة", "empire", "bld_department_store", "branchGoldPct", 0.10, 10, 17, 1.0, 3,
          "ذهب الفروع +{v}، والجاي +{next}"),
        N("branchSafe", "خزنة الفروع", "empire", "ui_key", "branchCapHours", 1, 8, 17, 0.8, 2,
          "خزنة الفروع بتوسع {v} ساعات زيادة، والجاي {next}"),
        N("cateringCrew", "شغل طلبيات", "empire", "ui_clipboard", "contractIncomePct", 0.15, 30, 14, 1.2, 3,
          "دخل مطابخ الطلبيات +{v}، والجاي +{next}"),
        N("festivalSpirit", "روح المهرجان", "empire", "ui_party_popper", "eventIncomePct", 0.15, 30, 15, 1.2, 3,
          "دخل مهرجان الويكند +{v}، والجاي +{next}"),
        N("cookingSchool", "مدرسة الطبخ", "empire", "ppl_cook", "chefBonusPct", 0.03, 30, 20, 1.5, 4,
          "قوّة الطبّاخين +{v}، والجاي +{next}"),
        N("strongStart", "بداية قويّة", "empire", "ui_high_voltage", "startStations", 1, 5, 25, 4.0, 5,
          "كل مطبخ جديد بيفتح وأوّل {v} محطّات على مستوى 10، والجاي {next}", req("secretBlend", 10)),
        N("expertEye", "عين خبيرة", "empire", "ui_search", "supplyRarityUpPct", 0.04, 10, 22, 1.0, 3,
          "كل لقية بالرحلة إلها فرصة {v} تطلع أندر، والجاي {next}", req("shortcuts", 3)),
    ]
    return {"version": 1, "baseMinutes": 10, "growth": 1.5, "capHours": 24, "costFloorFracOfFinal": 1e-6,
            "slotsByLevel": [{"level": 7, "slots": 1}, {"level": 20, "slots": 2}, {"level": 70, "slots": 3}],
            "nodes": nodes}


# ---------------------------------------------------------------- vehicles.json
def vehicles():
    rar = lambda c, r, e, l: {"common": c, "rare": r, "epic": e, "legendary": l}
    V = lambda id, name, art, tier, lvl, after, dur, rolls, w: dict(
        [("id", id), ("name", name), ("art", art), ("tier", tier), ("unlockLevel", lvl)]
        + ([("unlockAfter", {"vehicleId": after[0], "launches": after[1]})] if after else [])
        + [("durationsMin", dur), ("rolls", rolls), ("rarityWeights", w)])
    vs = [
        V("tractor", "تراكتور أبو سليم", "veh_tractor", 0, 8, None, [20, 60, 120], [2, 3, 4], rar(75, 22, 3, 0)),
        V("pickup", "البكم", "veh_pickup_truck", 1, 10, ("tractor", 4), [30, 90, 180], [3, 4, 6], rar(68, 26, 5.5, 0.5)),
        V("van", "الفان", "veh_minibus", 2, 13, ("pickup", 6), [90, 240, 480], [4, 6, 9], rar(60, 30, 8.5, 1.5)),
        V("lorry", "الشاحنة", "veh_lorry", 3, 18, ("van", 10), [240, 480, 720], [6, 9, 12], rar(52, 33, 12, 3)),
        V("ship", "سفينة يافا", "veh_ship", 4, 26, ("lorry", 15), [720, 1440, 2160], [9, 13, 18], rar(45, 35, 15, 5)),
        V("plane", "الطيّارة", "veh_airplane", 5, 36, ("ship", 20), [1440, 2880, 4320], [12, 18, 26], rar(38, 36, 18, 8)),
    ]
    return {"version": 1,
            "slotsByLevel": [{"level": 8, "slots": 1}, {"level": 10, "slots": 2}, {"level": 16, "slots": 3}, {"level": 90, "slots": 4}],
            "starLaunches": [4, 10, 25], "starRollsPct": 0.15, "star3CommonToEpic": 0.02,
            "rollKinds": {"heritage": 0.70, "chefCards": 0.20, "gold": 0.07, "woodChest": 0.03},
            "cardsPerRarity": rar(3, 2, 1, 1), "goldPerRarity": rar(2, 4, 7, 10),
            "unownedItemWeight": 2, "vehicles": vs}


# ---------------------------------------------------------------- heritage.json
SETS = [
    ("glass", "زجاج الخليل", "ui_crystal_ball", "cityIncomePct", 0.10, [
        ("blueBall", "كرة زجاج زرقا", "ui_crystal_ball", "common", "نفخها معلّم الزجاج بنَفَس واحد، ولونها لون بحر يافا"),
        ("glassJar", "مرطبان زجاج", "food_jar", "common", "ستّي كانت تخبّي فيه الملبّس للضيوف"),
        ("blueBead", "خرزة زرقا", "ui_gem", "rare", "بيعلّقوها على باب الدكّان، «عشان العين»"),
        ("glassLamp", "قنديل زجاج", "ui_lantern", "epic", "قنديل أزرق من أفران الخليل، ضوّه بيدفّي السهرة"),
    ]),
    ("soap", "صابون نابلس", "food_butter", "vaultCapHours", 1, [
        ("soapBar", "قالب صابون", "food_butter", "common", "صابون زيت زيتون، عليه ختم المصبنة وريحة البلد"),
        ("oliveOil", "زيت زيتون", "ui_droplet", "common", "أوّل عصرة، أخضر وحادّ بيقرص بالحلق"),
        ("soapFoam", "رغوة الصابون", "ui_sparkles", "rare", "رغوة بيضا ناعمة، سرّها بالطبخة الطويلة"),
        ("factoryStamp", "ختم المصبنة", "ui_label", "epic", "ختم نحاس قديم، كل قالب بيحمل اسم العيلة"),
    ]),
    ("tatreez", "تطريز فلّاحي", "ui_hibiscus", "chefBonusPct", 0.10, [
        ("stitchFlower", "وردة مطرّزة", "ui_hibiscus", "common", "غرزة صليب حمرا، طرّزتها ستّي وهي بتسولف"),
        ("stitchCarnation", "قرنفلة", "ui_tulip", "common", "قرنفلة على طرف الكم، من ثوب صبية من الضيعة"),
        ("threadColors", "خيطان ملوّنة", "ui_artist_palette", "rare", "خيطان حرير بألوان البيادر والبحر والسما"),
        ("bridalPanel", "قبّة ثوب العرس", "ui_bouquet", "epic", "قبّة مشغولة شهور، كل غرزة فيها دعوة حلوة"),
    ]),
    ("pearl", "صدف بيت لحم", "ui_star", "specialRewardPct", 0.20, [
        ("pearlStar", "نجمة صدف", "ui_star", "common", "نجمة صغيرة بتلمع، من سوق ساحة المهد"),
        ("pearlRosary", "مسبحة صدف", "ui_shooting_star", "common", "حبّاتها بتلمع مثل قطرات الندى"),
        ("pearlBox", "علبة صدف", "ui_dizzy", "rare", "علبة مطعّمة صدف، كانت تخبّي فيها ستّي الذهب"),
        ("pearlNativity", "مغارة الصدف", "ui_glowing_star", "epic", "شغل إيدين معلّم من بيت ساحور، أخذ منه سنة"),
    ]),
    ("pottery", "فخّار غزّة", "food_pot", "supplyTimePct", 0.05, [
        ("clayPot", "قدرة فخّار", "food_pot", "common", "قدرة الصيّاديّة، بتطلع من الفرن وريحتها بتسبقها"),
        ("clayJug", "إبريق فخّار", "ui_alembic", "rare", "إبريق بيبرّد المي بعزّ الصيف"),
        ("clayOven", "فرن الطين", "bld_hut", "epic", "فرن طين بالحوش، الخبز فيه بيطلع بطعم زمان"),
        ("honeyJar", "جرّة عسل قديمة", "food_honey", "legendary", "جرّة من أيام جدّ جدّك، لسّا ريحة العسل فيها"),
    ]),
    ("oliveWood", "خشب الزيتون", "bld_wood", "researchTimePct", 0.05, [
        ("woodOlive", "زيتونة خشب", "food_olive", "common", "زيتونة محفورة من غصن انكسر بالقطفة"),
        ("oliveBoard", "لوح زيتون", "bld_wood", "rare", "لوح تقطيع من خشب الزيتون، عروقه زي الخريطة"),
        ("oliveBeads", "مسبحة زيتون", "ui_link", "epic", "حبّات خشب ريحتها زيت، بتطقطق فيها وإنت مرتاح عالكرسي"),
        ("romanTree", "الزيتونة الروميّة", "bld_deciduous_tree", "legendary", "زيتونة عمرها أكبر من كل حكايات الحارة"),
    ]),
    ("copper", "نحاس وقهوة", "food_teapot", "sideIncomePct", 0.15, [
        ("coffeeCup", "فنجان قهوة", "food_coffee", "common", "فنجان صغير بلا إذن، للقهوة السادة بالأفراح"),
        ("copperDallah", "دلّة نحاس", "food_teapot", "rare", "دلّة مبيّضة، لمعتها من إيد أبو ناصر"),
        ("copperBell", "جرس نحاس", "ui_bellhop_bell", "epic", "جرس بائع العرق سوس، صوته بيرجّعك صغير"),
        ("brassScale", "ميزان نحاس", "ui_balance_scale", "legendary", "ميزان دكّان جدّك: ولا مرّة غشّ ولا بدرهم"),
    ]),
    ("memories", "صندوق الذكريات", "ui_old_key", "branchGoldPct", 0.15, [
        ("grandpaLetter", "رسالة من سيدي", "ui_envelope", "common", "رسالة بخطّ إيده: «البسطة أمانة، والزبون ضيف»"),
        ("familyPhoto", "صورة العيلة", "ui_camera", "rare", "صورة أبيض وأسود قدّام البسطة، والكل بيضحك"),
        ("oldDeed", "ورقة الدار القديمة", "ui_scroll", "epic", "ورقة صفرا مطويّة، ستّي بتحطّها تحت المخدّة"),
        ("houseKey", "مفتاح دار سيدي", "ui_old_key", "legendary", "سيدي كان يحكي: المفتاح بيضل معنا"),
    ]),
]


def heritage():
    sets, items = [], []
    for sid, sname, sart, btype, base, its in SETS:
        sets.append({"id": sid, "name": sname, "art": sart, "bonus": {"type": btype, "base": base},
                     "itemIds": [i[0] for i in its]})
        for iid, iname, iart, rar, desc in its:
            items.append({"id": iid, "setId": sid, "name": iname, "art": iart, "rarity": rar, "desc": desc})
    return {"version": 1, "copiesToLevel": [2, 3, 4, 5], "maxLevel": 5, "setLevelFactor": 0.5,
            "craft": {"unlockLevel": 19, "salvage": {"common": 1, "rare": 3, "epic": 8, "legendary": 20},
                      "cost": {"common": 10, "rare": 30, "epic": 80, "legendary": 200}},
            "case": {"rolls": 3, "rarityFloor": "rare"},
            "sets": sets, "items": items}


def main():
    for name, fn in [("economy.json", economy), ("chefs.json", chefs), ("research.json", research),
                     ("vehicles.json", vehicles), ("heritage.json", heritage)]:
        print("wrote", write_json(name, fn()))


if __name__ == "__main__":
    main()
