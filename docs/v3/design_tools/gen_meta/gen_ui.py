"""ftue.json, strings.json.

story.json is owned by the cities author (tools/build_cities.py); meta files only reference its scene ids
(fest_*, choice_radio, choice_grandmaCall, memory_L*, ch01_rival).
"""
from common import *

# ---------------------------------------------------------------- ftue.json
def step(id, start, text, complete, anchors=(), soft=False, feedback=None, script=None):
    s = {"id": id, "start": start}
    if anchors:
        s["anchors"] = list(anchors)
    if soft:
        s["soft"] = True
    s["text"] = text
    s["complete"] = complete
    if feedback:
        s["feedback"] = feedback
    if script:
        s["script"] = script
    return s


def st(type_, value=None, id=None):
    d = {"type": type_}
    if value is not None:
        d["value"] = value
    if id is not None:
        d["id"] = id
    return d


def ftue():
    steps = [
        step(1, st("firstFrame"), G("أهلا يا حبيبي! دقّ عالفلافل عشان تقلي أوّل قرص",
                                    "أهلا يا حبيبتي! دقّي عالفلافل عشان تقلي أوّل قرص"),
             st("tapCook", 1, "jerusalem.falafel"), anchors=["station.0.cook"], feedback="t1"),
        step(2, st("stepDone"), "كمان! كل دقّة بتجيب مصاري", st("cashAtLeast", 6),
             anchors=["station.0.cook"], soft=True, feedback="t1"),
        step(3, st("cashForNextLevel", id="jerusalem.falafel"),
             G("اشتري مستوى كمان، الزباين بستنّوا!", "اشتري مستوى كمان، الزباين بستنّوا!"),
             st("stationLevel", 2, "jerusalem.falafel"), anchors=["station.0.buy"], feedback="t0"),
        step(4, st("stepDone"), G("كل ما تكبّر الفلافل بتربح أكتر", "كل ما تكبّري الفلافل بتربحي أكتر"),
             st("stationLevel", 10, "jerusalem.falafel"), soft=True, feedback="t1"),
        step(5, st("cashAtLeast", 60), G("صار معك مصاري! افتح محطّة الحمّص", "صار معك مصاري! افتحي محطّة الحمّص"),
             st("stationUnlocked", id="jerusalem.hummus"), anchors=["station.1.card"], feedback="t1"),
        step(6, st("stepDone"), "الحمّص بدّه دقّة كمان", st("tapCook", 1, "jerusalem.hummus"),
             anchors=["station.1.cook"], feedback="t0"),
        step(7, st("stepDone"), G("خلّصت أوّل هدف! خذ نجمتك", "خلّصتي أوّل هدف! خذي نجمتك"),
             st("goalClaimed", id="jerusalem.g01"), anchors=["goal.0.claim"], feedback="t2"),
        step(8, st("managerAffordable", id="jerusalem.falafel"),
             G("وظّف معلّم للفلافل، بيقلي عنك وإنت مش هون", "وظّفي معلّم للفلافل، بيقلي عنك وإنتِ مش هون"),
             st("managerHired", id="jerusalem.falafel"), anchors=["station.0.manager"], feedback="t1"),
        step(9, st("stepDone"), G("جرّب ×10، أسرع بكتير!", "جرّبي ×10، أسرع بكتير!"), st("buyMode", 10),
             anchors=["buyMode"], feedback="t0"),
        step(10, st("levelReached", 3), G("زبون مميّز وصل! الحقه قبل ما يروح", "زبون مميّز وصل! الحقيه قبل ما يروح"),
             st("specialTapped"), anchors=["special"], feedback="t2", script={"forceSpecialOutcome": "frenzy"}),
        step(11, st("upgradeAffordable"), G("الترقيات بتضرب الربح ×3، جرّب وحدة!", "الترقيات بتضرب الربح ×3، جرّبي وحدة!"),
             st("upgradeBought"), anchors=["upgrades", "upgrade.0.buy"], feedback="t1"),
        step(12, st("levelReached", 4),
             G("ستّي بعتتلك صندوق! افتحه وحطّ سامي بالمطبخ، بيقوّي الفلافل",
               "ستّي بعتتلك صندوق! افتحيه وحطّي سامي بالمطبخ، بيقوّي الفلافل"),
             st("chefEquipped", id="samiFryer"), anchors=["tab.chefs", "chest.free", "chef.slot.0", "tab.home"],
             feedback="t2", script={"scriptedChest": {"chest": "wood", "chefId": "samiFryer"}}),
        step(13, st("afterSec", 120), "في ضيف جاي يسلّم عليك…", st("bubbleClosed"), soft=True,
             script={"storyScene": "ch01_rival"}),
        step(14, st("levelReached", 5),
             G("الخزنة بتتعبّى لحالها وإنت برّا، لحد 3 ساعات. ارجعلي بعد ساعتين، بفرجيك مدينة جديدة!",
               "الخزنة بتتعبّى لحالها وإنتِ برّا، لحد 3 ساعات. ارجعيلي بعد ساعتين، بفرجيكي مدينة جديدة!"),
             st("bubbleClosed"), anchors=["rail.vault"], feedback="t2", script={"askNotifications": True}),
        step(15, st("relaunchAway", 1800), G("أهلين! شوف قدّيش جمّعت الخزنة", "أهلين! شوفي قدّيش جمّعت الخزنة"),
             st("vaultCollected"), anchors=["vault.collect"], feedback="t1"),
        step(16, st("levelReached", 6), G("هاي الخريطة! بيت لحم بتفتح لما تجمع 25 نجمة",
                                          "هاي الخريطة! بيت لحم بتفتح لما تجمعي 25 نجمة"),
             st("screenViewed", id="map"), anchors=["tab.map", "map.next"], feedback="t2"),
        step(17, st("levelReached", 7), G("دفتر ستّي فيه أسرار. ابدأ أوّل بحث", "دفتر ستّي فيه أسرار. ابدئي أوّل بحث"),
             st("researchStarted", id="biggerVault"), anchors=["rail.research", "research.node.biggerVault"], feedback="t2"),
        step(18, st("levelReached", 8), G("ابعت التراكتور يجيب أغراض من البلد", "ابعتي التراكتور يجيب أغراض من البلد"),
             st("runSent", id="tractor"), anchors=["rail.supply", "supply.vehicle.tractor", "supply.duration.0"], feedback="t2"),
        step(19, st("graduationReady"), G("جاهز! افتح فرع بالقدس وانقل على بيت لحم",
                                          "جاهزة! افتحي فرع بالقدس وانقلي على بيت لحم"),
             st("graduated"), anchors=["goalStrip.graduate"], feedback="t3"),
    ]
    sp = lambda anchor, m, f=None: {"anchor": anchor, "text": G(m, f)}
    spots = [
        ("rushHours", [sp("banner.rushHour", "وقت الغدا والعشا الدخل دبل، خلّيك فاتح!", "وقت الغدا والعشا الدخل دبل، خلّيكي فاتحة!")]),
        ("shop", [sp("tab.shop", "هون الدكّان: صناديق ورزم وقت وديكور بالذهب")]),
        ("heritage", [sp("supply.segment.heritage", "كل قطعة تراث بترجع من الرحلات بتنحط هون"),
                      sp("heritage.shelf.0", "كمّل المجموعة الأربعة، وبتاخد بركتها للأبد", "كمّلي المجموعة الأربعة، وبتاخدي بركتها للأبد")]),
        ("daily", [sp("tab.tasks", "طلبات اليوم وصلت! خلّصها وخذ ذهب", "طلبات اليوم وصلت! خلّصيها وخذي ذهب"),
                   sp("orders.card.0", "ما عجبك الطلب؟ غيّره مرّة ببلاش كل يوم", "ما عجبك الطلب؟ غيّريه مرّة ببلاش كل يوم")]),
        ("calendar", [sp("calendar.today", "كل يوم بتفتح فيه إلك هديّة، واليوم 28 زعتر ذهبي")]),
        ("streak", [sp("streak.flame", "خلّص طلب واحد كل يوم وخلّي النار مولّعة", "خلّصي طلب واحد كل يوم وخلّي النار مولّعة")]),
        ("choices", [sp("choice.modal", "أهل الحارة إلهم حكايات، وكل جواب إله نتيجة")]),
        ("newspaper", [sp("rail.newspaper", "جريدة الحارة بتحكيلك شو صار وإنت برّا", "جريدة الحارة بتحكيلك شو صار وإنتِ برّا")]),
        ("rush", [sp("rail.tickets", "جرّب طلبيات على السريع! كل جولة بتولّع الدخل", "جرّبي طلبيات على السريع! كل جولة بتولّع الدخل"),
                  sp("rush.practice", "التدريب ببلاش دايماً، جرّب قبل التذكرة", "التدريب ببلاش دايماً، جرّبي قبل التذكرة")]),
        ("league", [sp("rail.league", "دوري المطاعم بلّش! السمعة بتطلّعك درجة كل أسبوع"),
                    sp("league.zone.promote", "خلّيك بالأخضر لآخر الأسبوع وبتطلع درجة", "خلّيكي بالأخضر لآخر الأسبوع وبتطلعي درجة")]),
        ("market", [sp("market.card", "شوف عرض اليوم والطقس، وكبّر المحطّات اللي بتربح", "شوفي عرض اليوم والطقس، وكبّري المحطّات اللي بتربح")]),
        ("contracts", [sp("rail.contracts", "وصلتك طلبيّة! مطبخ جانبي بجوايز كبيرة"),
                       sp("contracts.card.0", "تلات أهداف قبل ما يخلص الوقت، وشركاءك بيساعدوك", "تلات أهداف قبل ما يخلص الوقت، وشركاءك بيساعدوكي")]),
        ("events", [sp("rail.events", "مهرجان الويكند! من الخميس للأحد، كل أسبوع شكل")]),
        ("season", [sp("rail.season", "الموسم بلّش: 50 درجة جوايز وطبّاخ خاص")]),
        ("branchUpgrades", [sp("map.branch.0", "فرعك بالقدس بيقدر يكبر! كل مستوى ذهب ودخل أكتر")]),
        ("inspector", [sp("rail.inspector", "المفتّش جاي! خلّي المعلّمين والطبّاخين جاهزين", "المفتّش جاي! خلّي المعلّمين والطبّاخين جاهزين")]),
        ("crafting", [sp("heritage.craft", "القطع الزيادة صارت حِرفة، اصنع فيها اللي ناقصك", "القطع الزيادة صارت حِرفة، اصنعي فيها اللي ناقصك")]),
        ("chefSkills", [sp("action.chefSkill", "دقّ على وجه الطبّاخ الكبير وشغّل مهارته", "دقّي على وجه الطبّاخ الكبير وشغّلي مهارته")]),
        ("timeWarpShop", [sp("shop.timeWarps", "رزم الوقت صارت بالدكّان: ساعة شغل بكبسة")]),
    ]
    return {"version": 1, "steps": steps,
            "unlockSpotlights": [{"systemId": s, "steps": stp} for s, stp in spots]}


# ---------------------------------------------------------------- strings.json
SYSTEM_CEREMONIES = {
    "kitchen": ("البسطة", "دقّ عالأكل واطبخ، وكل دقّة بتجيب مصاري", "دقّي عالأكل واطبخي، وكل دقّة بتجيب مصاري"),
    "goals": ("الأهداف والنجوم", "خلّص الأهداف واجمع نجوم، النجوم بتفتح مدن جديدة", "خلّصي الأهداف واجمعي نجوم، النجوم بتفتح مدن جديدة"),
    "managers": ("المعلّمين", "وظّف معلّم، بيطبخ عنك حتّى وإنت برّا", "وظّفي معلّم، بيطبخ عنك حتّى وإنتِ برّا"),
    "specials": ("الزبون المميّز", "كل شوي بيمرق زبون مميّز، الحقه قبل ما يروح!", "كل شوي بيمرق زبون مميّز، الحقيه قبل ما يروح!"),
    "upgrades": ("الترقيات", "كل ترقية بتضرب ربح المحطّة ×3", None),
    "chefs": ("الطبّاخين", "جمّع طبّاخين، كل واحد بيقوّي أكلات من مطبخه", "جمّعي طبّاخين، كل واحد بيقوّي أكلات من مطبخه"),
    "chests": ("الصناديق", "افتح الصناديق ولاقي طبّاخين جداد", "افتحي الصناديق ولاقي طبّاخين جداد"),
    "shop": ("الدكّان", "صناديق ورزم وقت وتذاكر وديكور، كله بالذهب اللي بتجمعه", "صناديق ورزم وقت وتذاكر وديكور، كله بالذهب اللي بتجمعيه"),
    "rushHours": ("ساعات الذروة", "وقت الغدا والعشا الدخل دبل وإنت فاتح", "وقت الغدا والعشا الدخل دبل وإنتِ فاتحة"),
    "vault": ("الخزنة", "الخزنة بتتعبّى لحالها وإنت برّا، ارجع اجمعها", "الخزنة بتتعبّى لحالها وإنتِ برّا، ارجعي اجمعيها"),
    "map": ("الخريطة", "مدن جديدة ناطرتك! كل مدينة بتخلّصها بتصير فرع", "مدن جديدة ناطرتك! كل مدينة بتخلّصيها بتصير فرع"),
    "research": ("دفتر ستّي", "أسرار ستّي بالطبخ، كل بحث بيقوّيك للأبد", None),
    "supply": ("رحلات التوريد", "ابعت السيّارات تجيب تراث وطبّاخين وذهب", "ابعتي السيّارات تجيب تراث وطبّاخين وذهب"),
    "heritage": ("صندوق التراث", "جمّع قطع التراث، وكل مجموعة كاملة إلها بركة", "جمّعي قطع التراث، وكل مجموعة كاملة إلها بركة"),
    "daily": ("طلبات اليوم", "تلات طلبات كل يوم وتلاتة كل أسبوع، وإلهم جوايز حلوة", None),
    "calendar": ("الروزنامة", "كل يوم بتفتح فيه إلك هديّة، واليوم 28 فيه زعتر ذهبي", None),
    "streak": ("السلسلة", "خلّص طلب كل يوم، وخلّي النار مولّعة", "خلّصي طلب كل يوم، وخلّي النار مولّعة"),
    "choices": ("حكايات الحارة", "أهل الحارة إلهم حكايات، وإنت بتقرّر", "أهل الحارة إلهم حكايات، وإنتِ بتقرّري"),
    "newspaper": ("جريدة الحارة", "لما ترجع، الجريدة بتحكيلك شو صار وإنت برّا", "لما ترجعي، الجريدة بتحكيلك شو صار وإنتِ برّا"),
    "rush": ("طلبيات على السريع", "لفّ السندويشات بسرعة، واربح ولعة ×2", "لفّي السندويشات بسرعة، واربحي ولعة ×2"),
    "league": ("الدوري", "نافس مطاعم الحارة كل أسبوع، واطلع درجة", "نافسي مطاعم الحارة كل أسبوع، واطلعي درجة"),
    "market": ("سوق اليوم والطقس", "كل يوم إله عرض، والطقس بيغيّر شو بينباع", None),
    "contracts": ("الطلبيات", "عرس، تخرّج، عزومة… مطبخ جانبي وجوايز كبيرة", None),
    "events": ("مهرجان الويكند", "من الخميس للأحد: مهرجان جديد كل أسبوع", None),
    "season": ("الموسم", "خمسين درجة جوايز ببلاش، وطبّاخ خاص كل موسم", None),
    "branchUpgrades": ("ترقية الفروع", "كبّر فروعك، بتعطيك ذهب أكتر ودخل أعلى", "كبّري فروعك، بتعطيكي ذهب أكتر ودخل أعلى"),
    "inspector": ("مفتّش البلديّة", "المفتّش جاي يشوف البسطة، خلّيها تلمع!", None),
    "crafting": ("صنعة التراث", "القطع الزيادة بتصير حِرفة، واصنع اللي ناقصك", "القطع الزيادة بتصير حِرفة، واصنعي اللي ناقصك"),
    "chefSkills": ("مهارات الطبّاخين", "الطبّاخين الكبار إلهم مهارات، دقّ عالوجه وشغّلها", "الطبّاخين الكبار إلهم مهارات، دقّي عالوجه وشغّليها"),
    "timeWarpShop": ("رزم الوقت", "اشتري ساعات شغل جاهزة من الدكّان", None),
}


def strings():
    S = {}

    def put(key, m, f=None):
        assert key not in S, key
        S[key] = G(m, f)

    put("app.name", "بسطة فلافل")
    # tabs
    for k, v in [("map", "الخريطة"), ("tasks", "المهام"), ("home", "البسطة"), ("chefs", "الطبّاخين"), ("shop", "الدكان")]:
        put("tab." + k, v)
    put("tab.locked", "مستوى {n}")
    put("tab.teaser", "بتفتح بمستوى {n}: {what}!")
    # buttons
    B = [("collect", "اجمع", "اجمعي"), ("claim", "خذ", "خذي"), ("buy", "اشتري", None), ("hire", "وظّف", "وظّفي"),
         ("send", "ابعت", "ابعتي"), ("skip", "تخطّي", None), ("skipAll", "تخطّي الكل", None), ("double", "اجمع ×2", "اجمعي ×2"),
         ("open", "افتح", "افتحي"), ("equip", "حطّه", "حطّيه"), ("unequip", "شيله", "شيليه"), ("upgrade", "رقّي", None),
         ("levelUp", "رقّي الطبّاخ", None), ("start", "ابدأ", "ابدئي"), ("finishNow", "خلّصها بـ {g}", "خلّصيها بـ {g}"),
         ("reroll", "غيّر", "غيّري"), ("close", "سكّر", "سكّري"), ("ok", "تمام", None), ("yes", "أكيد", None),
         ("no", "لأ", None), ("later", "بعدين", None), ("notNow", "مش هسّا", None), ("go", "يلا", None),
         ("play", "العب", "العبي"), ("practice", "تدريب", None), ("wrap", "لفّ", "لفّي"), ("welcome", "استقبل", "استقبلي"),
         ("load", "حمّل الشحنة", "حمّلي الشحنة"), ("dispatch", "ابعت", "ابعتي"), ("graduate", "افتح فرع وانقل على {next}", "افتحي فرع وانقلي على {next}"),
         ("craft", "اصنع", "اصنعي"), ("more", "المزيد", None), ("back", "رجوع", None), ("info", "شو هاد؟", None),
         ("x1", "×1", None), ("x10", "×10", None), ("next", "التالي", None), ("max", "أقصى", None),
         ("ranking", "الترتيب", None), ("eventShop", "دكّانة المهرجان", None), ("upgrades", "ترقيات", None),
         ("startContract", "ابدأ الطلبيّة", "ابدئي الطلبيّة"), ("useWarp", "استعمل", "استعملي"), ("goldSources", "من وين بجيب ذهب؟", None)]
    for k, m, f in B:
        put("btn." + k, m, f)
    # hud
    H = [("locked", "مستوى {n}"), ("perSec", "{v}/ث"), ("max", "مكتمل"), ("maxLevel", "أقصى مستوى"),
         ("stationLevel", "مستوى {n}/{cap}"), ("unlockFor", "افتح بـ {cost}"), ("eta", "بعد {t}"),
         ("hireManager", "وظّف معلّم"), ("tapToCook", "دقّ للطبخ"), ("stars", "★ {n}/{total}"),
         ("milestoneSpeed", "سرعة ×2"), ("milestoneProfit", "ربح ×2"), ("allStations", "كل المحطّات {n}: {x}/{y}"),
         ("frenzy", "عجقة زباين ×5"), ("rushChip", "×2"), ("paused", "متوقّف"), ("notEnough", "مش كافي"),
         ("chefBoost", "+{p}%"), ("managedBy", "المعلّم {name}"), ("deficit", "ناقص {x}%"), ("night", "سوق الليل ×{m}"),
         ("perfect", "مظبوطة!"), ("delivered", "انسلّم {p}%"), ("tokens", "{n} {token}")]
    HF = {"unlockFor": "افتحي بـ {cost}", "hireManager": "وظّفي معلّم", "tapToCook": "دقّي للطبخ"}
    for k, v in H:
        put("hud." + k, v, HF.get(k))
    # numbers and time
    for k, v in [("e3", "ألف"), ("e6", "مليون"), ("e9", "مليار"), ("e12", "تريليون"), ("e15", "كوادريليون"),
                 ("e18", "كوينتليون"), ("e21", "سكستليون"), ("e24", "سبتليون"), ("e27", "أوكتليون"),
                 ("e30", "نونليون"), ("e33", "ديسيليون")]:
        put("num." + k, v)
    for k, v in [("h", "س"), ("m", "د"), ("s", "ث"), ("days", "{n} أيام"), ("day", "يوم"), ("oneDay", "يوم واحد"),
                 ("twoDays", "يومين"), ("hours", "{n} ساعات"), ("minutes", "{n} دقايق"), ("now", "هسّا"),
                 ("left", "ضايل {t}"), ("ago", "من {t}")]:
        put("time." + k, v)
    # notifications (GDD 6.15)
    put("notif.title", "بسطة فلافل")
    put("notif.streakRisk", "سلسلتك {n} يوم! طلب واحد بيحميها")
    put("notif.contractEnding", "طلبيّة «{title}» بتخلص بكرة، ضايل شوي!")
    put("notif.leagueResult", "نتيجة الدوري طلعت! شوف وين صرت", "نتيجة الدوري طلعت! شوفي وين صرتي")
    put("notif.supplyBack", "رجع {vehicle} ومعه إشي حلو! تعال شوف", "رجع {vehicle} ومعه إشي حلو! تعالي شوفي")
    put("notif.researchDone", "دفتر ستّي: خلص بحث «{node}»")
    put("notif.vaultFull", "الخزنة تعبّت يا معلّم! تعال اجمعها", "الخزنة تعبّت يا معلّمة! تعالي اجمعيها")
    put("notif.winback3", "ستّي بتسأل عنك… البسطة مشتاقتلك")
    put("notif.winback7", "زباينك ناطرينك، وفي إشي جديد بالسوق")
    # ceremonies
    for sid, (title, m, f) in SYSTEM_CEREMONIES.items():
        put(f"ceremony.{sid}.title", title)
        put(f"ceremony.{sid}.line", m, f)
    put("ceremony.waitEvent", "المهرجان بيبلّش الخميس")
    put("ceremony.unlocked", "انفتح!")
    # banners
    put("banner.rushHour", "ساعة الذروة! الدخل دبل")
    put("banner.frenzy", "عجقة زباين! الدخل ×5")
    put("banner.iftar", "ساعة الإفطار! الدخل ×5")
    put("banner.suhoor", "سحور! الدخل دبل")
    put("banner.inspector", "المفتّش جاي بعد {t}")
    put("banner.clock", "ساعة الجهاز رجعت لورا، الوقت موقّف لحد ما ترجع")
    put("banner.licence", "الرخصة جاهزة! انقل على {city}", "الرخصة جاهزة! انقلي على {city}")
    put("banner.bus", "باص سيّاح وصل!")
    put("banner.ship", "الباخرة رست! حمّل الشحنة قبل ما تطلع", "الباخرة رست! حمّلي الشحنة قبل ما تطلع")
    put("banner.festival", "{festival}! الدخل ×{m} اليوم")
    # toasts
    put("toast.freshDough", "عجينة طازة! دبل لمدّة {m} دقيقة")
    put("toast.tokensConverted", "حوّلنا {t} {token} لـ {g} ذهب")
    put("toast.vipTooSmall", "صالة كبار الزوار بدها تكبر")
    put("toast.levelUp", "يا سلام! طلعت مستوى {n}", "يا سلام! طلعتي مستوى {n}")
    put("toast.saved", "انحفظ")
    put("toast.cardsToGold", "كروت زيادة صارت {g} ذهب")
    put("toast.walla", "ولعة ×2 لمدّة {m} دقيقة!")
    # goals, graduation, map, branches
    put("goals.title", "الأهداف")
    put("goals.claimed", "تمّ")
    put("goals.lockedSystem", "بتفتح بمستوى {n}")
    put("goals.threshold", "بدّك {n} نجمة لتنقل")
    put("goals.licence", "الرخصة بتطلع بعد {t}")
    put("goals.more", "و{n} كمان")
    put("graduate.confirm", "رح تسكّر {city} وتصير فرع. الفرع بعطيك ذهب كل يوم و+10% دخل لكل المدن الجاية.",
        "رح تسكّري {city} وتصير فرع. الفرع بعطيكي ذهب كل يوم و+10% دخل لكل المدن الجاية.")
    put("graduate.warnGoals", "الأهداف اللي ما خلّصتها رح تروح (والتاج كمان).", "الأهداف اللي ما خلّصتيها رح تروح (والتاج كمان).")
    put("graduate.sign", "فرع")
    put("map.region.palestine", "فلسطين")
    put("map.region.arab", "الوطن العربي")
    put("map.region.world", "العالم")
    put("map.locked", "بدها رخصة ونجوم")
    put("map.branchGold", "{x} ذهب/يوم")
    put("map.safe", "خزنة الفروع")
    put("map.safeCap", "بتتعبّى بعد {t}")
    put("map.crowned", "متوّجة")
    put("branch.bonus", "+{p}% دخل لكل المدن")
    put("branch.level", "مستوى الفرع {n}/10")
    put("branch.upgrade", "رقّي الفرع بـ {g} ذهب")
    put("crown.title", "تاج {city}!")
    # chefs & chests
    put("chefs.slots", "خانات الطبّاخين")
    put("chefs.slotLocked", "مستوى {n}")
    put("chefs.filterAll", "الكل")
    put("chefs.whereStrong", "وين بيقوّي؟")
    put("chefs.cards", "{x}/{y} كرت")
    put("chefs.skill", "مهارة: {name}")
    put("chefs.skillReady", "جاهزة!")
    put("chefs.skillCooldown", "بترجع بعد {t}")
    put("chefs.exclusive", "طبّاخ حصري")
    for k, v in [("common", "عادي"), ("rare", "نادر"), ("epic", "ملحمي"), ("legendary", "أسطوري")]:
        put("rarity." + k, v)
    for k, v in [("palestinian", "فلسطيني"), ("levantine", "شامي"), ("egyptian", "مصري"), ("gulf", "خليجي"),
                 ("iraqi", "عراقي"), ("maghrebi", "مغربي"), ("turkish", "تركي"), ("world", "عالمي"), ("any", "كل المطابخ")]:
        put("cuisine." + k, v)
    for k, v in [("fried", "مقالي"), ("grill", "مشاوي"), ("bakery", "مخبوزات"), ("sweets", "حلويات"), ("drinks", "مشروبات"),
                 ("dishes", "طبخات"), ("seafood", "أكل بحر"), ("street", "أكل شارع"), ("any", "كل الأصناف")]:
        put("category." + k, v)
    put("chest.inventory", "صناديقك")
    put("chest.free", "صندوق هديّة!")
    put("chest.newChef", "طبّاخ جديد!")
    # research & supply & heritage
    put("research.title", "دفتر ستّي")
    for k, v in [("kitchen", "المطبخ"), ("customers", "الزباين"), ("vault", "الخزنة والوقت"), ("empire", "الإمبراطوريّة")]:
        put("research.branch." + k, v)
    put("research.slotIdle", "الدفتر فاضي، ابدأ بحث!", "الدفتر فاضي، ابدئي بحث!")
    put("research.maxed", "خلص للآخر")
    put("supply.title", "رحلات التوريد")
    put("supply.garage", "الكراج")
    put("supply.short", "مشوار قصير")
    put("supply.mid", "مشوار نصّ نصّ")
    put("supply.long", "مشوار طويل")
    put("supply.rolls", "{n} لقيات")
    put("supply.back", "رجعت الرحلة ومعها إشي حلو")
    put("supply.stars", "نجوم السيّارة")
    put("supply.segment.runs", "الرحلات")
    put("supply.segment.heritage", "صندوق التراث")
    put("heritage.title", "صندوق التراث")
    put("heritage.setBonus", "بركة المجموعة")
    put("heritage.craftPoints", "حِرفة: {n}")
    put("heritage.setDone", "المجموعة كملت!")
    # tasks
    for k, v in [("today", "اليوم"), ("week", "الأسبوع"), ("calendar", "الروزنامة"), ("season", "الموسم"), ("achievements", "الإنجازات")]:
        put("tasks." + k, v)
    put("orders.bonus", "صندوق المكافأة {x}/3")
    put("orders.reroll", "غيّر الطلب", "غيّري الطلب")
    put("orders.rerollFree", "تغيير ببلاش")
    put("orders.allDone", "خلّصت كل طلبات اليوم!", "خلّصتي كل طلبات اليوم!")
    put("calendar.day", "يوم {n}")
    put("calendar.claimed", "انستلم")
    put("calendar.cycle", "الدورة {n}")
    put("streak.count", "{n} يوم")
    put("streak.frozen", "تجمّدت السلسلة اليوم")
    put("streak.broken", "السلسلة انقطعت… بس فيك ترجّعها", "السلسلة انقطعت… بس فيكي ترجّعيها")
    put("streak.repair", "رجّع السلسلة: خلّص 6 طلبات يومية خلال يومين", "رجّعي السلسلة: خلّصي 6 طلبات يومية خلال يومين")
    put("streak.freezes", "تجميدات: {n}")
    put("season.title", "الموسم")
    put("season.daysLeft", "ضايل {n} يوم")
    put("season.tier", "درجة {n}")
    put("season.bonus", "صندوق إضافي كل 300 نقطة")
    put("achievements.next", "الجاي: {n}")
    # league
    put("league.title", "الدوري")
    put("league.endsIn", "بيخلص بعد {t}")
    put("league.trial", "أسبوع تجريبي")
    put("league.promote", "منطقة الطلوع")
    put("league.demote", "منطقة النزول")
    put("league.npcInfo", "مطعم وهمي من اللعبة. بيلعب بالدوري زيّك.")
    put("league.promoted", "طلعت درجة! صرت بـ {tier}", "طلعتي درجة! صرتي بـ {tier}")
    put("league.stayed", "ضلّيت بـ {tier}، الأسبوع الجاي إلك!", "ضلّيتي بـ {tier}، الأسبوع الجاي إلك!")
    put("league.demoted", "نزلت لـ {tier}، ولا يهمّك، منرجع!", "نزلتي لـ {tier}، ولا يهمّك، منرجع!")
    put("league.rep", "سمعة")
    # contracts & events
    put("contract.title", "طلبيات")
    put("contract.new", "جديد")
    put("contract.rerun", "إعادة")
    put("contract.grade", "الدرجة: {g}")
    put("contract.slotFull", "الخانات مليانة، خلّص طلبيّة أوّل", "الخانات مليانة، خلّصي طلبيّة أوّل")
    put("contract.deadline", "بتخلص بعد {t}")
    put("contract.partners", "الشركاء")
    put("contract.cash", "كاش الطلبيّة")
    for k, v in [("noManagers", "بلا معلّمين: كله بإيدك"), ("noUpgrades", "بلا ترقيات"), ("chefsOff", "الطبّاخين بإجازة"),
                 ("fastCheap", "كل إشي أسرع وأرخص"), ("goldenHour", "عجقة زباين كل ساعة"), ("oneStation", "محطّة وحدة بس")]:
        put("contract.rule." + k, v)
    put("contract.done", "الطلبيّة كملت! يسلموا إيديك", "الطلبيّة كملت! يسلموا إيديكي")
    put("event.title", "مهرجان الويكند")
    put("event.startsIn", "بيبلّش بعد {t}")
    put("event.endsIn", "بيخلص بعد {t}")
    put("event.milestone", "مرحلة {n}")
    put("event.rank", "ترتيبك: {n}")
    put("event.shop", "دكّانة المهرجان")
    # market, weather, newspaper, choices, specials, rush, inspector
    put("market.title", "سوق اليوم")
    put("market.friday", "فرحة الجمعة: عرضين اليوم")
    put("weather.title", "الطقس")
    put("newspaper.title", "جريدة الحارة")
    put("newspaper.vault", "الخزنة جمّعت")
    put("newspaper.whileAway", "وإنت برّا…", "وإنتِ برّا…")
    put("newspaper.runsBack", "رجعت {n} رحلات")
    put("newspaper.researchDone", "خلص بحث «{node}»")
    put("newspaper.partners", "شركاء الطلبيّة سلّموا {p}%")
    put("newspaper.league", "صرت بالمرتبة {n} بالدوري", "صرتي بالمرتبة {n} بالدوري")
    put("newspaper.licence", "رخصة {city} جاهزة!")
    put("newspaper.safeFull", "خزنة الفروع تعبّت")
    put("choice.hint.sure", "أكيد")
    put("choice.hint.luck", "حظّ")
    put("special.arrived", "زبون مميّز وصل! الحقه قبل ما يروح", "زبون مميّز وصل! الحقيه قبل ما يروح")
    put("rush.title", "طلبيات على السريع")
    put("rush.combo", "×{c}")
    put("rush.urgent", "مستعجل!")
    put("rush.best", "أحسن نتيجة: {n}")
    put("rush.newBest", "رقم قياسي جديد!")
    put("rush.result", "ولعة ×2 لمدّة {m} دقيقة")
    put("rush.tickets", "تذاكر: {n}")
    put("inspector.title", "مفتّش البلديّة")
    put("inspector.score", "النتيجة: {s} من 15")
    put("inspector.cert", "شهادة نظافة!")
    put("inspector.tip", "نصيحة المفتّش: وظّف معلّمين لكل المحطّات", "نصيحة المفتّش: وظّفي معلّمين لكل المحطّات")
    # profile
    put("profile.title", "ملفّ المعلّم", "ملفّ المعلّمة")
    put("profile.power", "قوّة الإمبراطوريّة ×{p}")
    put("profile.zaatar", "زعتر ذهبي: {n} (دخل ×{m})")
    put("profile.why", "ليش دخلي هيك؟")
    put("profile.titles", "الألقاب")
    put("title.L100", "سلطان البسطات", "سلطانة البسطات")
    # shop
    put("shop.chests", "الصناديق")
    put("shop.timeWarps", "رزم وقت")
    put("shop.tickets", "تذاكر")
    put("shop.freezes", "تجميد السلسلة")
    put("shop.chefStall", "بسطة الطبّاخين")
    put("shop.decor", "ديكور")
    put("shop.eventCurrency", "عملة المهرجان")
    put("shop.notEnough", "الذهب مش كافي. بتجمعه من الطلبات والروزنامة والدوري والفروع",
        "الذهب مش كافي. بتجمعيه من الطلبات والروزنامة والدوري والفروع")
    put("shop.dailyLimit", "خلصت عروض اليوم")
    # cosmetic slots
    for k, v in [("awning", "مظلّة"), ("sign", "يافطة"), ("lights", "إضاءة"), ("prop", "إكسسوار"), ("frame", "إطار")]:
        put("cosmetic.slot." + k, v)
    # festivals
    put("festival.intro", "إجا {festival}!")
    put("festival.neutral", "أيام البركة")
    put("festival.dailyClaim", "هديّة اليوم")
    put("festival.eidiyya", "عيديّتك!")
    put("festival.lanterns", "فوانيس: {n}/30")
    # legacy gift
    put("legacy.title", "هديّة الجيل الأوّل")
    put("legacy.body", "شكراً إنّك معنا من الأوّل! ستّي خبّتلك هديّة")
    # ftue helpers
    put("ftue.addressAsk", "كيف بدّك أناديك؟")
    put("ftue.addressM", "يا شب")
    put("ftue.addressF", "يا صبية")
    put("ftue.notifAsk", "بدّك أخبرك لما تتعبّى الخزنة؟")
    put("ftue.notifYes", "أكيد")
    put("ftue.notifNo", "مش هسّا")
    put("ftue.defaultStall", "بسطة ستّي")
    # settings & credits
    for k, v in [("title", "الإعدادات"), ("sfx", "الأصوات"), ("music", "الموسيقى"), ("haptics", "الاهتزاز"),
                 ("notifications", "الإشعارات"), ("streakReminder", "تذكير السلسلة"), ("reduceMotion", "تقليل الحركة"),
                 ("reduceMotion.auto", "تلقائي"), ("reduceMotion.always", "دايماً"), ("reduceMotion.never", "أبداً"),
                 ("digits", "الأرقام"), ("festiveDecor", "زينة المواسم"), ("address", "طريقة المناداة"),
                 ("replayTutorial", "أعيد الشرح"), ("about", "عن اللعبة"), ("reset", "ابدأ من جديد"),
                 ("resetWord", "امسح"), ("stallName", "اسم البسطة")]:
        put("settings." + k, v)
    put("settings.resetConfirm", "اكتب «امسح» عشان نبدأ من جديد. التقدّم كله رح يروح!",
        "اكتبي «امسح» عشان نبدأ من جديد. التقدّم كله رح يروح!")
    put("settings.resetSure", "متأكّد؟ ما في رجعة", "متأكّدة؟ ما في رجعة")
    put("credits.developer", "Developer: Saad")
    put("credits.developerAr", "المطوّر: سعد")
    put("credits.fluent", "Fluent Emoji 3D — MIT License, Microsoft")
    put("credits.fonts", "Baloo Bhaijaan 2 · Cairo — SIL Open Font License 1.1")
    put("credits.version", "النسخة {v}")
    # errors
    put("error.cantAfford", "المصاري مش كافية")
    put("error.slotsFull", "الخانات مليانة")
    put("error.locked", "لسّا مسكّر")
    return {"version": 1, "strings": S}


def main():
    print("wrote", write_json("ftue.json", ftue()))
    print("wrote", write_json("strings.json", strings()))


if __name__ == "__main__":
    main()
