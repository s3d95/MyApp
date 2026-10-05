"""happenings.json, market.json"""
from common import *


def ch(label, outcomes, hint="sure"):
    """outcomes: list of (p, effects, text)"""
    return {"label": label, "hint": hint,
            "outcomes": [{"p": p, "effects": eff, "text": txt} for p, eff, txt in outcomes]}


def sure(label, effects, text):
    return ch(label, [(1, effects, text)])


def row(id, art, title, body, choices, weight=None, cond=None, offline=None):
    r = {"id": id, "art": art, "title": title, "body": body}
    if weight is not None:
        r["weight"] = weight
    if cond:
        r["condition"] = cond
    r["choices"] = choices
    if offline:
        r["offline"] = {"allowed": True, "autoChoice": offline[0], "newsText": offline[1]}
    return r


I = lambda m: e_reward(incmin(m))
REP = lambda n: e_reward(rep(n))
XP = lambda n: e_reward(xp(n))
K = e_karma


def choices_rows():
    rows = []
    A = rows.append
    # ---------------- Appendix E (40 rows) ----------------
    A(row("neighborLoan", "ppl_man", "جارك بدّه دين",
          G("أبو العبد بدّه دين لآخر الشهر، بتدينه؟", "أبو العبد بدّه دين لآخر الشهر، بتدينيه؟"),
          [ch("تفضّل", [(0.7, [e_stake(5), I(15), K(1)], "رجّعلك الدين وزيادة!"),
                        (0.3, [e_stake(5), I(5), e_reward(item(1, rarity="common")), K(1)],
                         "رجّع جزء، وجابلك هديّة من دار أبوه")], hint="luck"),
           sure("معلش هسّا لأ", [REP(5)], "ولا يهمّك، بفهم")],
          cond={"minLevel": 10}))
    A(row("weddingRush", "bld_wedding", "عرس فجأة!", "عرس بالحارة وبدّهم 100 سندويشة هسّا!",
          [sure("يلا نشتغل", [e_frenzy(), I(10)], "الحارة كلها رقصت، والسندويشات خلصت!"),
           sure("مش قادرين", [REP(5)], "أهل العرس عذروك، وبعتولك صحن كنافة")],
          offline=(0, "عرس فجأة بالحارة! معلّمينك طلّعوا 100 سندويشة وإنت برّا")))
    A(row("powerCut", "ui_electric_plug", "الكهربا قطعت", "الكهربا قطعت! شو بنعمل؟",
          [sure("عالغاز", [e_active(2, 3), XP(5)], "ريحة القلي عالغاز جابت الحارة كلها!"),
           sure("بنستنّى", [I(5)], "الزباين استنّوا، وتركولك بقشيش")]))
    A(row("celebrity", "ppl_singer", "مطرب مشهور",
          G("مطرب مشهور واقف عالدور! بتعزمه؟", "مطرب مشهور واقف عالدور! بتعزميه؟"),
          [sure("عالبيت", [REP(20), e_active(3, 3)], "صوّر ستوري، والدنيا كلها إجت!"),
           sure("زيّه زيّ الكل", [I(15)], "دفع واستنّى دوره، وترك بقشيش محترم")]))
    A(row("tourGuide", "ppl_person_tipping_hand", "دليل سياحي", "دليل سياحي بدّه يجيب مجموعته عندك كل يوم",
          [sure("أهلا وسهلا", [e_special(), REP(5)], "أوّل مجموعة وصلت، وفيهم زبون مميّز!"),
           sure("ما في مكان", [I(5)], "اشتروا سندويشات عالطريق ومشيوا")],
          offline=(0, "دليل سياحي جاب مجموعته عالبسطة وإنت برّا")))
    A(row("students", "ppl_person_raising_hand", "طلّاب الجامعة", "طلّاب بيرزيت بدّهم خصم طلّاب",
          [sure("خصم 50%", [REP(15), K(1), I(5)], G("صرت حديث الكافتيريا كلها!", "صرتي حديث الكافتيريا كلها!")),
           sure("بالسعر العادي", [I(10)], "دفعوا، ووعدوا يرجعوا بعد الامتحانات")]))
    A(row("lostChild", "ppl_child", "ولد ضايع", "ولد صغير ضايع وبيعيّط عند البسطة",
          [sure("بنطعميه وبنستنّى أهله", [K(2), REP(20), e_reward(item(1, rarity="rare"))],
                "إمّه وصلت وما عرفت كيف تشكرك، وأعطتك هديّة من ستّها"),
           sure("بنوصّله للشرطة", [K(1), REP(10)], "وصل لأهله بالسلامة")]))
    A(row("grannyRecipe", "ppl_old_woman", "وصفة قديمة", "ختيارة بتعرض عليك وصفة من زمان",
          [ch("بجرّبها", [(0.6, [e_reward(cards(3, rarity="rare"))], "الوصفة زبطت! طبّاخين جداد بدّهم يتعلّموها"),
                          (0.4, [I(10)], "ما زبطت متل ما بدّها، بس الزباين حبّوها")], hint="luck"),
           sure("يسلموا إيديكي", [K(1), XP(10)], "دعتلك من قلبها، والدعوة بتسوى الدنيا")]))
    A(row("rainStorm", "ui_umbrella_with_rain_drops", "شتوة قويّة", "الناس محشورة تحت المظلّة من الشتا",
          [sure("شاي ببلاش", [REP(15), e_active(2, 5)], "الشاي دفّاهم، وما حدا روّح بلا سندويشة"),
           sure("بنعلّي الراديو", [I(5)], "سهرة حلوة تحت الشتا")],
          cond={"weather": ["rainy", "cold"]},
          offline=(0, "شتوة قويّة، والناس احتموا تحت مظلّة بسطتك وشربوا شاي")))
    A(row("foodBlogger", "ui_mobile_phone", "بلوغر أكل", "بلوغر أكل مشهور بدّه يصوّر صحن من عندك",
          [ch("أحلى صحن عنّا", [(0.75, [e_active(3, 5), REP(10)], "الفيديو ضرب! الطابور واصل لآخر الشارع"),
                                (0.25, [REP(25)], "الفيديو ما انتشر كتير، بس كتب عنك كلام حلو")], hint="luck"),
           sure("لا شكراً", [I(5)], "أكل وانبسط بهدوء")]))
    A(row("rivalBorrow", "ppl_man_cook", "الجار محتاج",
          G("{rival} خلصت عنده البندورة، بتسلّفه؟", "{rival} خلصت عنده البندورة، بتسلّفيه؟"),
          [sure("أكيد", [K(1), REP(10), e_flag("rivalFriend")], "{rival} قال: «ما بنساها إلك»"),
           sure("يدبّر حاله", [I(5)], "دبّر حاله، والمنافسة منافسة")]))
    A(row("marketDeal", "veh_lorry", "عرض بالحسبة", "تاجر بيعرض خضرة بنص السعر",
          [sure("بشتري", [e_stake(10), I(25)], "الخضرة طازة، والربح دبل"),
           sure("عندي", [I(5)], "خلّيها لمرّة جاية")],
          offline=(0, "تاجر الحسبة باعك خضرة بنص السعر، وربحت فيها")))
    A(row("kidsBirthday", "food_birthday_cake", "عيد ميلاد", "أم بدّها فلافل لعيد ميلاد ابنها",
          [sure("تكرم عينها", [I(10), REP(10)], "الأولاد غنّولك «سنة حلوة يا جميل»!"),
           sure("بخصم", [K(1), I(5), REP(15)], "الأم دعتلك، والأولاد صاروا زباينك")]))
    A(row("radio", "ui_studio_microphone", "مقابلة إذاعة", "إذاعة محليّة بدّها مقابلة معك",
          [sure("بحكي عن ستّي", [REP(25), e_scene("choice_radio")], "ستّي سمعتك عالراديو وعيّطت من الفرحة"),
           sure("بحكي عن العروض", [e_frenzy()], "الإعلان اشتغل! الناس جاية ركض")]))
    A(row("oudPlayer", "ui_musical_notes", "عازف عود", "عازف عود بدّه يعزف جنب البسطة",
          [sure("أهلا فيه", [e_active(2, 5)], "الطرب جاب الزباين من كل الحارات"),
           sure("سندويشة وشكراً", [K(1), REP(5)], "عزف لحن صغير وراح مبسوط")]))
    A(row("oldFriend", "ppl_handshake", "صاحب قديم",
          G("صاحبك من المدرسة رجع من الغربة", "صاحبتك من المدرسة رجعت من الغربة"),
          [sure("عالحساب", [K(1), REP(10), e_reward(item(1, rarity="rare"))], G("جابلك هديّة من البلاد اللي كان فيها", "جابتلك هديّة من البلاد اللي كانت فيها")),
           sure("بنسولف شوي", [I(5), XP(10)], "سولفتوا عن أيام زمان، وضحكتوا من القلب")]))
    A(row("haraCat", "ani_cat", "قطّة الحارة", "قطّة الحارة قاعدة عند البسطة وبتطلّع فيك",
          [sure("بنطعميها", [K(1), e_flag("catFed1")], "أكلت وغمّضت عيونها. شكلها رح ترجع!"),
           sure("بلطف بنبعدها", [I(3)], "راحت تتمشّى، وبتطلّع وراها")],
          cond={"flagsNone": ["catFed1"]}))
    A(row("lostWallet", "ui_money_bag", "محفظة ضايعة",
          G("لقيت محفظة فيها مصاري", "لقيتي محفظة فيها مصاري"),
          [sure("بدوّر على صاحبها", [K(2), REP(20), I(10)], "صاحبها أصرّ يعطيك مكافأة"),
           sure("للشرطة", [K(1), REP(10)], "وصلت لصاحبها، والأمانة ما بتضيع")]))
    A(row("officeOrder", "bld_office_building", "طلبيّة شركة", "شركة بدّها 50 صحن عالغدا",
          [sure("بنوصّلها", [I(20)], "الموظّفين شبعوا، والمدير طلب رقمك"),
           sure("مش اليوم", [I(3)], "طلبوا سندويشات وبس")],
          offline=(0, "شركة طلبت 50 صحن غدا، ومعلّمينك وصّلوهم")))
    A(row("farmerFresh", "ppl_man_farmer", "حمّص بلدي", "فلّاح جايب حمّص بلدي طازة",
          [sure("بشتري كلّه", [e_stake(5), e_active(2, 30, scope_cui("palestinian"))],
                "الطعم البلدي بيفرق! أكل البلد ×2 لنص ساعة"),
           sure("شوي بس", [I(5)], "كيلو للبيت، وكيلو لستّي")]))
    A(row("tvShow", "ui_television", "برنامج طبخ", "برنامج طبخ بدّه يستضيفك",
          [sure("أكيد!", [REP(30), e_reward(cards(3, rarity="rare"))], G("طلعت عالتلفزيون، وطبّاخين بدّهم يشتغلوا معك", "طلعتي عالتلفزيون، وطبّاخين بدّهم يشتغلوا معك")),
           sure("مش وقته", [I(5)], "المذيعة وعدت ترجع الموسم الجاي")]))
    A(row("schoolBus", "bld_school", "رحلة مدرسة", "باص رحلة وقف قدّام البسطة",
          [sure("سندويشات للكل", [I(15), REP(10)], "الأولاد غنّوا بالباص طول الطريق"),
           sure("عصير بس", [I(8), K(1)], "عصير بارد، وضحكات أبرد")],
          offline=(0, "باص رحلة مدرسة وقف عالبسطة، وما ضلّت ولا سندويشة")))
    A(row("poet", "ui_scroll", "شاعر الحارة", "شاعر الحارة بدّه يكتب قصيدة عن فلافلك",
          [sure("اسمعنا!", [REP(20), XP(20)], "«قرص الفلافل مدوّر زي القمر…» والحارة كلها صفّقت"),
           sure("بدّي نسخة", [e_reward(item(1, id="grandpaLetter"))], G("علّقتها جنب رسالة سيدي", "علّقتيها جنب رسالة سيدي"))]))
    A(row("eatChallenge", "ppl_flexed_biceps", "تحدّي أكل", "شب بيتحدّى ياكل 20 قرص فلافل",
          [ch("إذا خلّصهم ببلاش", [(0.5, [REP(30), e_active(2, 5)], "خلّصهم! والجمهور طلب نفس التحدّي"),
                                   (0.5, [I(15)], "وقف عند القرص 14، ودفع حقّهم كلهم")], hint="luck"),
           sure("ممنوع التحدّي", [I(5)], "أكل خمسة ومشي مبسوط")]))
    A(row("lanternMaker", "ui_lantern", "صانع فوانيس", "صانع فوانيس بيعرض فانوس للبسطة",
          [sure("بشتريه", [e_stake(5), e_collect("lantern", 1), REP(10)], "الفانوس بيلمع، وفانوس اليوم صار دبل"),
           sure("بتفرّج بس", [I(5)], "الفوانيس بتلمع، والحارة أحلى")],
          weight=2, cond={"festivalIds": ["ramadan"]}))
    A(row("eidKids", "ppl_child", "أولاد العيد", "أولاد الحارة بدّهم عيديّة",
          [sure("عيديّة لكل واحد", [K(2), REP(20), XP(20)], "الضحكات ملّت الشارع: «كل عام وإنت بخير!»"),
           sure("قطعة حلو", [K(1), REP(10)], "الحلو خلص بدقيقة")],
          weight=2, cond={"festivalIds": ["eidFitr", "eidAdha"]}))
    A(row("oliveHelp", "food_olive", "قطف الزيتون", "جارك بدّه مساعدة بقطف الزيتون",
          [ch("بروح أساعد", [(0.7, [e_reward(item(1, id="woodOlive"))], G("رجعت ريحتك زيت، ومعك زيتونة خشب هديّة", "رجعتي ريحتك زيت، ومعك زيتونة خشب هديّة")),
                             (0.3, [e_reward(item(1, id="oliveBoard"))], "أعطاك لوح زيتون من شجرة سيده")]),
           sure("ببعتله أكل", [K(1), REP(10)], "القطّيفة أكلوا ودعولك")],
          weight=2, cond={"festivalIds": ["oliveHarvest"]}))
    A(row("choir", "ui_musical_notes", "كورال الميلاد", "كورال بيغنّي بالساحة",
          [sure("سحلب للكورال", [REP(15), e_frenzy()], "غنّولك ترنيمة، والساحة كلها إجت"),
           sure("منسمع بس", [I(5)], "صوتهم دفّى الساحة")],
          weight=2, cond={"festivalIds": ["bethlehemChristmas"]}))
    A(row("heatWave", "ui_thermometer", "شوب!", "الدنيا شوب والناس بدّها إشي بارد",
          [sure("مي ببلاش", [REP(15), K(1)], "الناس شكروك من قلبهم"),
           sure("عصير بسعر خاص", [e_active(2, 30, scope_wt("cold"))], "البارد طار! المشروبات الباردة ×2 لنص ساعة")],
          cond={"weather": ["hot"]}))
    A(row("snowDay", "ui_snowflake", "تلج!", "التلج نازل والمدينة واقفة",
          [sure("سحلب للكل", [REP(15), e_active(2, 30, scope_wt("hot"))], "السخن طار! الأكل السخن ×2 لنص ساعة"),
           sure("بنسكّر بكّير", [I(10)], G("رحت عالبيت وعملت رجل تلج", "رحتي عالبيت وعملتي رجل تلج"))],
          cond={"weather": ["cold"]}))
    A(row("journalist", "ui_newspaper", "صحفي", "صحفي بيكتب عن أحسن البسطات",
          [sure("بفرجيه المطبخ", [REP(25)], "طلعت صورتك بالجريدة!"),
           sure("سندويشة وبس", [I(8)], "أكل ورجع طلب كمان وحدة")],
          offline=(0, "صحفي كتب عن بسطتك بجريدة الحارة!")))
    A(row("apprentice", "ppl_boy", "صبي متدرّب", "ولد بدّه يتعلّم الشغل بالصيف",
          [sure("تعال تعلّم", [e_reward(cards(3, rarity="common")), K(1)], "صار يقلّب الفلافل زي المعلّمين"),
           sure("بتساعد بالتنظيف", [I(5), XP(10)], "البسطة لمعت!")]))
    A(row("tourPhoto", "ui_camera", "سايح بيصوّر", "سايح بدّه صورة مع البسطة",
          [sure("أهلين!", [REP(10), e_special()], "نشر الصورة، وإجا زبون مميّز يسأل عنك"),
           sure("صوّرني كمان", [XP(10), I(5)], G("صرت مشهور عالإنترنت شوي", "صرتي مشهورة عالإنترنت شوي"))],
          offline=(0, "سايح نشر صورة بسطتك، وإجوا زباين جداد")))
    A(row("secretSpice", "food_herb", "بهار سرّي", "عطّار بيعرض بهار سرّي",
          [ch("بجرّبه", [(0.6, [e_stake(10), I(30)], "البهار سحر! الكل بدّه نفس الطعمة"),
                         (0.4, [e_stake(10), I(8), REP(10)], "طلع بهار عادي، بس العطّار حكى عنك بالسوق")], hint="luck"),
           sure("عالقديم", [I(5)], "خلطة ستّي ما بتتغيّر")]))
    A(row("rivalRace", "ppl_man_cook", "تحدّي الجار",
          G("{rival} بيتحدّاك: مين أسرع ساندويشة؟", "{rival} بيتحدّاكي: مين أسرع ساندويشة؟"),
          [sure("يلا!", [e_freeRush()], "جولة على السريع ببلاش!"),
           sure("مرّة تانية", [REP(5)], G("{rival} قال: «خايف؟» وضحك", "{rival} قال: «خايفة؟» وضحك"))],
          cond={"requiresSystem": "rush"}))
    A(row("elderMeal", "ppl_older_person", "ختيار جوعان", "ختيار ما معه حقّ الأكل",
          [sure("عالبيت يا حج", [K(2), XP(20), REP(10)], "دعالك بالخير وراح مبسوط"),
           sure("بنص السعر", [K(1), I(5)], "شكرك وأكل بهدوء")]))
    A(row("cupWinners", "ui_trophy", "الأبطال!", "فريق الحارة ربح الكاس وجايين يحتفلوا",
          [sure("أكلة على حسابي", [REP(30), K(1)], "شالوك عالأكتاف!"),
           sure("خصم للأبطال", [I(15)], "أكلوا وغنّوا للفجر")],
          offline=(0, "فريق الحارة ربح الكاس واحتفلوا عند بسطتك")))
    A(row("nightGuard", "ppl_guard", "حارس الليل", "الحارس الليلي بدّه شاي وسندويشة",
          [sure("بالهنا", [K(1), REP(10)], "قال: «البسطة بأمان الليلة»"),
           sure("بالحساب", [I(5)], "دفع وكمّل دورته")],
          cond={"hours": [22, 4]}))
    A(row("lostTourist", "ppl_woman", "سايحة ضايعة", "سايحة بتسأل عن الطريق",
          [sure(G("بوصّلها", "بوصّلها"), [REP(15), K(1)], "وصلت، ورجعت تاكل عندك"),
           sure("بشرحلها", [I(5), XP(5)], G("رسمتلها خريطة على كيس الخبز", "رسمتيلها خريطة على كيس الخبز"))]))
    A(row("grandmaCall", "ppl_old_woman", "تلفون من ستّي", "ستّي عالتلفون: «ابعتلي صحن من أكلك»",
          [sure("أحلى صحن لستّي", [XP(30), e_scene("choice_grandmaCall")], "ستّي ذاقت وقالت: «هاد طعم إيد سيدك»"),
           sure("بزورها بكرة", [K(1), e_reward(warp(30))], G("ستّي قالت: «ناطرتك، ولا تتأخّر»", "ستّي قالت: «ناطرتك، ولا تتأخّري»"))]))
    # ---------------- extra rows (alive, local, follow-ups) ----------------
    A(row("haraCat2", "ani_cat", "القطّة رجعت!", "قطّة الحارة رجعت، وجايبة معها بنتها الصغيرة",
          [sure("صحن حليب للتنتين", [K(1), e_flag("catFed2")], "شربوا الحليب وناموا بفيّة المظلّة"),
           sure("بتفرّج عليهم وبضحك", [I(3), XP(5)], "البنت الصغيرة لحقت ذيل إمّها ساعة")],
          weight=2, cond={"flagsAll": ["catFed1"], "flagsNone": ["catFed2"]}))
    A(row("haraCat3", "ani_cat", "القطّة اختارتك!", "قطّة الحارة صارت تنام كل يوم تحت البسطة. شكلها قرّرت تسكن عندك",
          [sure("أهلا بالموظّفة الجديدة!", [K(1), e_reward(cosmetic("propCat")), e_flag("catAdopted"), REP(10)],
                "صار عند البسطة قطّة رسميّة!"),
           sure("بعملّها بيت صغير", [K(1), e_reward(cosmetic("propCat")), e_flag("catAdopted"), XP(10)],
                "بيت كرتون صغير، وصارت حارسة البسطة")],
          weight=2, cond={"flagsAll": ["catFed2"], "flagsNone": ["catAdopted"]}))
    A(row("rivalThanks", "ppl_man_cook", "الجميلة ما بتنتسى", "{rival} بعتلك صينيّة هريسة مع ابنه: «هاي عشان البندورة!»",
          [sure("بشكره من قلبي", [REP(15), K(1), I(10), e_flag("rivalThanked")], "صرتوا جيران وحبايب"),
           sure("ببعتله صحن رجعة", [K(2), REP(10), e_flag("rivalThanked")], "الصحن راح ورجع مليان مرّتين!")],
          weight=2, cond={"flagsAll": ["rivalFriend"], "flagsNone": ["rivalThanked"]}))
    A(row("taxiDriver", "veh_taxi", "سوّاق التكسي", "أبو العبد سوّاق التكسي بدّه يلزق إعلان بسطتك على سيّارته",
          [sure("فكرة حلوة!", [e_special(), REP(10)], "أوّل مشوار جابلك زبون مميّز"),
           sure("سندويشة عالطريق", [I(5), K(1)], "زمّرلك وهو ماشي")]))
    A(row("weddingCard", "ui_envelope", "كرت عرس", G("وصلك كرت عرس من {rival}! بتروح؟", "وصلك كرت عرس من {rival}! بتروحي؟"),
          [sure("أكيد بروح", [REP(20), K(1)], G("دبكت لحد ما تعبت، و{rival} طاير من الفرحة", "دبكتي لحد ما تعبتي، و{rival} طاير من الفرحة")),
           sure("ببعت صدر كنافة", [REP(15)], "الكنافة وصلت قبل العريس!")]))
    A(row("kidsFootball", "ppl_boy", "كورة الولاد", "كورة الولاد نطّت بين كراسي البسطة، والولاد واقفين خايفين",
          [sure("برجّعلهم ياها وبضحك", [K(1), REP(10)], "وعدوا يشتروا عصير بعد الماتش"),
           sure("بنلعب معهم شوط", [XP(10), REP(10)], G("سجّلت هدف! والولاد صاروا يهتفوا باسم البسطة", "سجّلتي هدف! والولاد صاروا يهتفوا باسم البسطة"))]))
    A(row("streetCleaning", "ppl_construction", "تنظيف الحارة", "البلديّة بتنظّف الشارع وبدّها مساعدة أصحاب المحلّات",
          [sure("بشمّر وبساعد", [K(1), REP(15), XP(5)], "الحارة لمعت، والكل شكرك"),
           sure("ببعتلهم شاي", [I(5), K(1)], "الشاي رفع المعنويّات")]))
    A(row("oldRadioSong", "ui_musical_notes", "أغنية زمان", "الراديو بيغنّي أغنية من أيام ستّي، والزباين صاروا يدندنوا",
          [sure("بعلّي الصوت", [e_active(2, 3), REP(5)], "الحارة كلها صارت تغنّي معك"),
           sure("بغنّي معها", [XP(10), K(1)], "صوتك مش بطّال أبداً!")]))
    A(row("mysteryCritic", "ppl_detective", "زبون غامض", "زبون لابس نظّارة سودا وبيكتب بدفتر صغير… ناقد؟",
          [ch("بعطيه أحلى صحن", [(0.5, [e_active(2, 5), REP(25)], "طلع ناقد! وكتب: «أطيب بسطة بالبلد»"),
                                 (0.5, [REP(10), XP(10)], "طلع بيكتب ليستة السوق، بس انبسط كتير")], hint="luck"),
           sure("بعامله زي الكل", [I(10)], "دفع وراح، وترك بقشيش حلو")]))
    A(row("rainbow", "ui_rainbow", "قوس قزح", "طلع قوس قزح فوق البسطة بعد الشتوة، والناس بتصوّر",
          [sure("صورة جماعيّة!", [REP(15), e_special()], "الصورة لفّت الحارة، وإجا زبون مميّز"),
           sure("عرض قوس قزح", [e_active(2, 5)], "سبع ألوان وسبع سندويشات!")],
          weight=2, cond={"weather": ["rainy"]}))
    A(row("wrapLesson", "ppl_raising_hands", "درس لفّ", "مجموعة سيّاح بدّهم يتعلّموا كيف تنلفّ سندويشة الفلافل",
          [sure("دورة على السريع!", [e_freeRush(), REP(10)], "جولة ببلاش، والسيّاح صفّقولك"),
           sure("بلفّلهم أنا", [I(10)], "أكلوا، وصوّروا، وطلبوا كمان")],
          cond={"requiresSystem": "rush"}))
    A(row("hummusContest", "ppl_judge", "مسابقة الحمّص", G("مسابقة أطيب حمّص بالحي! بدّك تشارك؟", "مسابقة أطيب حمّص بالحي! بدّك تشاركي؟"),
          [ch("أكيد بشارك", [(0.4, [REP(40), e_reward(cards(3, rarity="rare"))], "المرتبة الأولى! الكاس إلك"),
                             (0.6, [REP(15), XP(15)], G("طلعت التاني، والناس حبّوا صحنك", "طلعتي التانية، والناس حبّوا صحنك"))],
              hint="luck"),
           sure(G("بكون حكَم", "بكون حكَمة"), [XP(20), REP(10)], G("حكَمت بالعدل، والكل احترمك", "حكَمتي بالعدل، والكل احترمك"))]))
    A(row("generousTourist", "ppl_man_tuxedo", "بقشيش كبير",
          G("سايح ترك بقشيش كبير بالغلط وراح! بتلحقه؟", "سايح ترك بقشيش كبير بالغلط وراح! بتلحقيه؟"),
          [sure("بلحقه وبرجّعله", [K(2), REP(15)], "انبسط من أمانتك، وكتب عنك بكل مكان"),
           sure("بحطّه بصندوق الخير", [K(1), REP(10)], "الصندوق رح يطعمي عيلة محتاجة")]))
    # ---------------- city-flavoured rows ----------------
    A(row("nablusSoap", "food_butter", "المصبنة القديمة", "صاحب المصبنة بيعرض يفرجيك كيف بينطبخ صابون زيت الزيتون",
          [sure("بروح أتعلّم", [e_reward(item(1, id="soapBar")), XP(15)], G("رجعت ومعك قالب صابون عليه ختمهم", "رجعتي ومعك قالب صابون عليه ختمهم")),
           sure("بشتري قالبين لستّي", [K(1), REP(10)], "ستّي بتحب ريحة صابون نابلس")],
          weight=2, cond={"cityIds": ["nablus"]}))
    A(row("hebronGlass", "ui_crystal_ball", "فرن الزجاج", "معلّم الزجاج بدّه يبدّل كرة زجاج زرقا بساندويشة",
          [sure("صفقة!", [e_reward(item(1, id="blueBall")), REP(5)], "كرة زرقا بتلمع زي البحر"),
           sure("الساندويشة هديّة", [K(1), REP(10)], G("قال: «إيدك خضرا يا معلّم»", "قال: «إيدك خضرا يا معلّمة»"))],
          weight=2, cond={"cityIds": ["hebron"]}))
    A(row("jaffaOranges", "food_tangerine", "برتقال زيادة", "تاجر البرتقال عنده صناديق زيادة قبل ما تطلع الباخرة",
          [sure("بشتري وبعصر", [e_stake(5), e_active(2, 15)], "عصير برتقال يافاوي! الدخل ×2 لربع ساعة"),
           sure("حبّتين للبيت", [I(5)], "البرتقال اليافاوي ما إله مثيل")],
          weight=2, cond={"cityIds": ["jaffa"]}))
    A(row("gazaSea", "ppl_old_man", "طلعة صيد", "الريّس عازمك على طلعة صيد مع الفجر",
          [ch("بطلع معه", [(0.6, [I(25), XP(10)], "الشبكة طلعت مليانة! سمك طازة للبسطة"),
                           (0.4, [REP(15), e_reward(item(1, rarity="common"))], "ما صدتوا كتير، بس الريّس أعطاك هديّة حلوة")],
              hint="luck"),
           sure("بنام شوي", [I(8)], G("صحيت على ريحة سمك مقلي", "صحيتي على ريحة سمك مقلي"))],
          weight=2, cond={"cityIds": ["gaza"]}))
    A(row("ramallahNight", "ppl_raising_hands", "سهرة رام الله", "شباب طالعين من حفلة، وبدّهم أكل الساعة وحدة بالليل",
          [sure("يلا نقلي!", [e_frenzy()], "الحفلة كمّلت عند البسطة!"),
           sure("آخر طلب", [I(8)], G("سكّرت مبسوط وتعبان", "سكّرتي مبسوطة وتعبانة"))],
          weight=2, cond={"cityIds": ["ramallah"], "hours": [22, 3]}))
    A(row("cairoDebate", "ppl_man", "طعميّة ولا فلافل؟", "زبونين بيتجادلوا: طعميّة ولا فلافل؟ وطالبين رأيك",
          [sure("التنين أطيب من بعض!", [REP(15), K(1)], "ضحكوا وتصالحوا على صحن مشكّل"),
           sure("اللي بالبسطة أطيب!", [I(10), XP(5)], "طلبوا التنين ليقرّروا… والمصاري إلك")],
          weight=2, cond={"cityIds": ["cairo"]}))
    A(row("tokyoBow", "ppl_bowing", "انحناءة", "زبون ياباني انحنالك شكراً عالفلافل",
          [sure("بنحنيله كمان", [REP(15), XP(10)], "انحنيتوا لبعض تلات مرّات!"),
           sure("بعلّمه «يسلموا»", [K(1), REP(10)], "صار يقول «يسلموا» لكل زبون")],
          weight=2, cond={"cityIds": ["tokyo"]}))
    A(row("santiagoFamily", "ppl_old_man", "من ريحة البلاد", "ختيار من أصل فلسطيني بيحكي إنّ ستّه كانت من بيت جالا",
          [sure("بنحكي عن البلاد", [K(1), REP(20), e_reward(item(1, id="grandpaLetter"))],
                "دمعت عينه، وأعطاك رسالة قديمة من عيلته"),
           sure("صحن على حسابي", [K(2), XP(10)], "قال: «طعمه طعم البيت»")],
          weight=2, cond={"cityIds": ["santiago"]}))
    A(row("newYorkRush", "veh_taxi", "سوّاقين التكسي", "سوّاقين التكسي الصفر وقفوا صف طويل الساعة تلاتة بالليل",
          [sure("يلا يا شباب!", [e_frenzy()], "زمامير وضحك وفلافل للصبح"),
           sure("بسرعة بسرعة", [I(10)], G("خلّصت الصف بربع ساعة", "خلّصتي الصف بربع ساعة"))],
          weight=2, cond={"cityIds": ["newYork"], "hours": [0, 4]}))
    # ---------------- festival rows ----------------
    A(row("musahharati", "ui_bell", "المسحّراتي", "المسحّراتي وقف عالبسطة: «اصحى يا نايم!» وبدّه سحور",
          [sure("سحور على حسابي", [K(1), REP(15)], "دعالك ودقّ عالطبلة لعند بيتك"),
           sure("بسحّر الحارة معه", [e_active(2, 10)], "الحارة صحيت عالسحور، والطابور طوّل")],
          weight=2, cond={"festivalIds": ["ramadan"], "hours": [1, 5]}))
    A(row("eidMaamoul", "food_moon_cake", "صحن العيد", "الجارة بعتتلك صحن معمول وكعك، والصحن لازم يرجع مليان",
          [sure("برجّعه مليان فلافل", [K(1), REP(10)], "رجع الصحن مليان، والمحبّة زادت"),
           sure("بعزمها عالقهوة", [XP(15), REP(5)], "سولفتوا ساعة، وعرفتوا كل أخبار الحارة")],
          weight=2, cond={"festivalIds": ["eidFitr", "eidAdha"]}))
    A(row("christmasTree", "ui_star", "شجرة الساحة", "شجرة الميلاد بالساحة بدّها زينة، والبلديّة بتطلب مساعدة المحلّات",
          [sure("بنعلّق نجمة باسم البسطة", [REP(20), e_special()], "النجمة بتلمع، وإجا زبون مميّز يصوّرها"),
           sure("سحلب للمتطوّعين", [K(1), I(8)], "السحلب دفّى الإيدين والقلوب")],
          weight=2, cond={"festivalIds": ["bethlehemChristmas"]}))
    A(row("schoolFirstDay", "ppl_child", "أوّل يوم مدرسة", "أوّل يوم مدرسة، والأولاد بيعيّطوا عباب المدرسة",
          [sure("عروسة زعتر لكل ولد", [K(1), REP(15)], "سكتوا كلهم وصاروا يضحكوا"),
           sure("سندويشات للأهالي", [I(12)], "الأهالي كمان كانوا بدّهم مين يطبطب عليهم")],
          weight=2, cond={"festivalIds": ["backToSchool"]}))
    A(row("oliveOilFirst", "ui_droplet", "الزيت الجديد", "أوّل زيت نزل من المعصرة! أخضر وبيقرص بالحلق",
          [sure("بغمّس للزباين", [REP(15), e_active(2, 15, scope_cat("bakery"))], "خبز وزيت جديد: المخبوزات ×2 لربع ساعة"),
           sure("جالون لستّي", [K(1), XP(15)], "ستّي ذاقت وقالت: «هاد زيت الخير»")],
          weight=2, cond={"festivalIds": ["oliveHarvest"]}))
    A(row("summerNight", "bld_night_with_stars", "سهرة صيفيّة", "الناس طالعة تتمشّى بالليل من الشوب",
          [sure("بنطلّع كراسي عالرصيف", [e_active(2, 10)], "الرصيف صار مطعم، والسهرة حلوة"),
           sure("بوظة للأولاد ببلاش", [K(1), REP(15)], "الأولاد لزّقوا إيديهم بالبوظة وضحكوا")],
          weight=2, cond={"festivalIds": ["summer"], "hours": [20, 23]}))
    return rows


def specials():
    out = [
        {"id": "tip", "name": "زبون كريم", "art": "ui_money_bag", "weight": 55, "effects": [e_reward(incmin(15))]},
        {"id": "frenzy", "name": "عجقة زباين", "art": "ui_fire", "weight": 25, "effects": [e_frenzy(5, 60)]},
        {"id": "critic", "name": "ناقد طعام", "art": "ui_memo", "weight": 8,
         "effects": [e_active(2, 5), e_reward(rep(15))], "eventReplacement": [e_reward(tokens(3))]},
        {"id": "bus", "name": "باص رحلة", "art": "veh_bus", "weight": 7, "effects": [e_reward(incmin(10))]},
        {"id": "collector", "name": "جامع تراث", "art": "ui_old_key", "weight": 2.4,
         "effects": [e_reward(item(1, rarity="common"))], "condition": {"minLevel": 8}, "fallbackId": "tip",
         "eventReplacement": [e_reward(tokens(4))]},
        {"id": "collectorRare", "name": "جامع تراث", "art": "ui_old_key", "weight": 0.6,
         "effects": [e_reward(item(1, rarity="rare"))], "condition": {"minLevel": 8}, "fallbackId": "tip",
         "eventReplacement": [e_reward(tokens(5))]},
        {"id": "visitingChef", "name": "طبّاخ زائر", "art": "ppl_cook", "weight": 1.4,
         "effects": [e_reward(cards(3, rarity="common"))], "condition": {"minLevel": 4}, "fallbackId": "tip",
         "eventReplacement": [e_reward(tokens(4))]},
        {"id": "visitingChefRare", "name": "طبّاخ زائر", "art": "ppl_cook", "weight": 0.6,
         "effects": [e_reward(cards(3, rarity="rare"))], "condition": {"minLevel": 4}, "fallbackId": "tip",
         "eventReplacement": [e_reward(tokens(5))]},
        # festival flavour (fall back to a tip outside their window)
        {"id": "suhoorGuest", "name": "زبون السحور", "art": "ui_bell", "weight": 4,
         "effects": [e_reward(incmin(20)), e_reward(rep(5))], "condition": {"festivalIds": ["ramadan"]}, "fallbackId": "tip"},
        {"id": "eidFamily", "name": "عيلة معيّدة", "art": "ui_gift", "weight": 5,
         "effects": [e_reward(incmin(20))], "condition": {"festivalIds": ["eidFitr", "eidAdha"]}, "fallbackId": "tip"},
        {"id": "oliveFarmer", "name": "فلّاح الزيتون", "art": "food_olive", "weight": 4,
         "effects": [e_reward(incmin(15)), e_reward(rep(5))], "condition": {"festivalIds": ["oliveHarvest"]}, "fallbackId": "tip"},
        {"id": "scoutParade", "name": "استعراض الكشّافة", "art": "ui_musical_notes", "weight": 4,
         "effects": [e_frenzy(5, 60)], "condition": {"festivalIds": ["bethlehemChristmas"]}, "fallbackId": "tip"},
        {"id": "student", "name": "طالب مدرسة", "art": "ui_notebook", "weight": 4,
         "effects": [e_reward(incmin(12))], "condition": {"festivalIds": ["backToSchool"]}, "fallbackId": "tip"},
    ]
    return {"unlockLevel": 3, "minSec": 300, "rangeSec": 600, "power": 5, "forceSec": 900, "onScreenSec": 15,
            "outcomes": out}


def happenings():
    return {
        "version": 1,
        "specials": specials(),
        "choiceRules": {"unlockLevel": 10, "firstAfterPlayMin": 10, "gapMinSec": 180, "gapMaxSec": 360,
                        "maxPerDay": 4, "cooldownDays": 7},
        "choices": choices_rows(),
        "offline": {"minAwayMin": 60, "maxPerReturn": 2, "maxPerDay": 3},
        "rushHours": [{"id": "lunch", "startHour": 12, "endHour": 14, "mult": 2},
                      {"id": "dinner", "startHour": 19, "endHour": 22, "mult": 2}],
        "inspector": {
            "unlockLevel": 18, "intervalDays": [4, 6, 8], "hourRange": [10, 20], "warningHours": 12,
            "checks": [
                {"id": "managers", "name": "معلّمين", "full": 2.5, "partial": 1.5},
                {"id": "chefs", "name": "طبّاخين", "full": 2.5, "partial": 1.5},
                {"id": "stall", "name": "شكل البسطة", "full": 2.5, "partial": 1.5},
                {"id": "customers", "name": "الزباين", "full": 2.5, "partial": 1.5},
                {"id": "vault", "name": "الخزنة", "full": 2.5, "partial": 1.5},
                {"id": "variety", "name": "التنويع", "full": 2.5, "partial": 1.5},
            ],
            "rewardBands": [
                {"minScore": 0, "rewards": [gold(5)]},
                {"minScore": 8, "rewards": [gold(10)]},
                {"minScore": 12, "rewards": [gold(20), cosmetic("signCleanCert")]},
            ],
            "xpPerPoint": 4, "repPerPoint": 2,
        },
        "karmaRewards": [
            {"karma": 5, "rewards": [item(1, rarity="rare")]},
            {"karma": 10, "rewards": [cards(3, rarity="epic")]},
            {"karma": 20, "rewards": [cosmetic("propBouquet")]},
        ],
    }


# ---------------------------------------------------------------- market.json
def market():
    def M(id, name, art, desc, weight, effects, weekdays=None, festive=False):
        m = {"id": id, "name": name, "art": art, "desc": desc, "weight": weight, "effects": effects}
        if weekdays:
            m["weekdays"] = weekdays
        m["festive"] = festive
        return m
    day = lambda scope, mult: e_income(scope, mult, "day")
    mods = [
        M("doubleDay", "يوم الدبل", "ui_party_popper", "دخل كل المطابخ ×2 اليوم كلّه", 5, [day(scope_all(), 2)], festive=True),
        M("hummusDay", "يوم الحمّص", "food_hummus_bowl", "الطبخات ×3 اليوم كلّه", 8, [day(scope_cat("dishes"), 3)]),
        M("friedFriday", "مقالي الجمعة", "food_falafel", "المقالي ×3، بركة الجمعة", 8, [day(scope_cat("fried"), 3)], weekdays=[6]),
        M("sweetsDay", "يوم الحلو", "food_pie", "الحلويات ×3 اليوم كلّه", 8, [day(scope_cat("sweets"), 3)]),
        M("drinksDay", "عصير وبس", "food_tropical_drink", "المشروبات ×3 اليوم كلّه", 8, [day(scope_cat("drinks"), 3)]),
        M("bakeryDay", "خبز طازة", "food_bread", "المخبوزات ×3 اليوم كلّه", 8, [day(scope_cat("bakery"), 3)]),
        M("grillDay", "ريحة شوي", "food_meat_on_bone", "المشاوي ×3 اليوم كلّه", 6, [day(scope_cat("grill"), 3)]),
        M("seafoodDay", "سمك طازة", "ani_fish", "أكل البحر ×3 اليوم كلّه", 5, [day(scope_cat("seafood"), 3)]),
        M("streetDay", "أكل الشارع", "food_shawarma_wrap", "أكل الشارع ×3 اليوم كلّه", 6, [day(scope_cat("street"), 3)]),
        M("baladDay", "من خير البلد", "food_olive", "الأكل الفلسطيني ×2 اليوم كلّه", 5, [day(scope_cui("palestinian"), 2)]),
        M("worldDay", "أكلات العالم", "bld_globe_eu_africa", "أكلات العالم ×3 اليوم كلّه", 4, [day(scope_cui("world"), 3)]),
        M("managerSale", "خصم المعلّمين", "ppl_handshake", "المعلّمين بنص السعر اليوم", 6,
          [{"type": "costMult", "target": "manager", "mult": 0.5}]),
        M("levelSale", "أوكازيون", "ui_label", "مستويات المحطّات أرخص بالربع", 6,
          [{"type": "costMult", "target": "stationLevel", "mult": 0.75}]),
        M("researchSale", "بحث بنص السعر", "ui_notebook", "أبحاث دفتر ستّي بنص السعر", 6,
          [{"type": "costMult", "target": "research", "mult": 0.5}]),
        M("researchFast", "دفتر سريع", "ui_hourglass", "الأبحاث اللي بتبلّش اليوم أقصر بالربع", 6,
          [{"type": "durationMult", "target": "research", "mult": 0.75}]),
        M("supplyDouble", "رحلات دبل", "veh_pickup_truck", "الرحلات اللي بتطلع اليوم بترجع بدبل اللقيات", 5,
          [{"type": "rollsMult", "mult": 2}]),
        M("supplyFast", "طرق فاضية", "veh_tractor", "الرحلات اللي بتطلع اليوم أقصر بالربع", 6,
          [{"type": "durationMult", "target": "supply", "mult": 0.75}]),
        M("specialRush", "زباين كتير", "ui_bellhop_bell", "الزبون المميّز بيجي أسرع اليوم", 6,
          [{"type": "specialIntervalMult", "mult": 0.6}]),
        M("ticketGift", "تذكرة ببلاش", "ui_admission_tickets", "تذكرة هديّة أوّل ما تفتح", 6, [e_reward(tickets(1))]),
        M("vaultBoost", "خزنة كريمة", "ui_locked_with_key", "الخزنة بتجمع +25% وإنت برّا", 5,
          [{"type": "vaultEffAdd", "add": 0.25}]),
        M("chefStallSale", "بسطة الطبّاخين بخصم", "ppl_cook", "عروض الطبّاخين أرخص 30% اليوم", 4,
          [{"type": "costMult", "target": "chefOffers", "mult": 0.7}]),
    ]
    weather = {
        "types": [
            {"id": "sunny", "name": "صحو", "art": "ui_sun_behind_cloud", "effects": []},
            {"id": "hot", "name": "شوب", "art": "ui_sun", "effects": [day(scope_wt("cold"), 1.15)]},
            {"id": "cold", "name": "برد", "art": "ui_snowflake", "effects": [day(scope_wt("hot"), 1.15)]},
            {"id": "rainy", "name": "شتا", "art": "ui_cloud_with_rain", "effects": [{"type": "specialIntervalMult", "mult": 0.8}]},
        ],
        "seasons": [
            {"months": [6, 7, 8], "probs": {"sunny": 0.55, "hot": 0.40, "cold": 0.0, "rainy": 0.05}},
            {"months": [12, 1, 2], "probs": {"sunny": 0.40, "hot": 0.0, "cold": 0.40, "rainy": 0.20}},
            {"months": [3, 4, 5, 9, 10, 11], "probs": {"sunny": 0.55, "hot": 0.175, "cold": 0.175, "rainy": 0.10}},
        ],
    }
    return {"version": 1, "unlockLevel": 13, "perDay": {"default": 1, "friday": 2}, "cooldownDays": 5,
            "modifiers": mods, "weather": weather}


def main():
    print("wrote", write_json("happenings.json", happenings()))
    print("wrote", write_json("market.json", market()))


if __name__ == "__main__":
    main()
