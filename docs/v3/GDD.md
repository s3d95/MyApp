# بسطة فلافل v3.0: Game Design Document

Status: implementation-ready design, v3.0 launch scope. This document is the source of truth for rules and numbers. Content rows live in JSON (see `SCHEMA.md`). Every tunable number here is mirrored in `economy.json` or in the content file named next to it. Where this document and a JSON file disagree, the JSON wins after the simulator (tools/sim) has passed.

Calibration inputs: `design/tools/kitchen_sim.py`, `calibrate.py`, `campaign.py`, `side_sim.py`, `meta.py`, `levels.py`. Their outputs are quoted in sections 3 and 8.

## Contents
0. Conventions
1. Vision, pillars, tone, brand, HUD, screens, feedback tiers
2. Kitchen engine
3. City ladder, goals, graduation, branches, licences, twists
4. Empire level
5. Currencies, faucets, sinks, prices
6. Meta and live systems (6.1 chefs/chests, 6.2 research, 6.3 supply runs/heritage, 6.4 calendar/streak, 6.5 orders, 6.6 market/weather, 6.7 league, 6.8 season pass, 6.9 contracts, 6.10 weekend venue, 6.11 festivals, 6.12 Happening engine, 6.13 rush minigame, 6.14 achievements, 6.15 notifications, 6.16 legacy gift, 6.17 settings, 6.18 FTUE, 6.19 story, 6.20 stall tiers and cosmetics)
7. Save model, determinism, clock guard
8. Pacing plan
Appendices: A cities, B chefs, C contracts, D weekend themes, E choice events, F market modifiers, G heritage, H empire levels 1-100, I achievements, J calendar, K season pass, L league names

---

## 0. Conventions

| Topic | Rule |
|---|---|
| Time | All engine time in seconds (`Double`). Field names carry the unit: `cycleSec`, `durationMin`, `durationHours`. |
| Game day | A game day starts at **04:00 local**. `gameDay = localDate(now − 4h)`, written `yyyyMMdd`. Suhoor play counts toward the same day. |
| Game week | Starts **Monday 04:00 local**. `weekId = ISO year-week of gameDay`. |
| Big numbers | `Double` everywhere. Any value above 1e30 is a sim failure. |
| Base units | City economies are authored in base units (priceScale = 1). Runtime prices and cash targets are base × `city.priceScale`. Revenues are never scaled. |
| Rounding | Costs round **up** to 3 significant digits for display, but the engine compares exact doubles. Gold, stars, XP, tickets, cards and tokens are integers. |
| Number display | Below 1e6: full number with thousands grouping (`12,450`). From 1e6: 3 significant digits, floored, plus the scale word: مليون، مليار، تريليون، كوادريليون، كوينتليون، سكستليون، سبتليون، أوكتليون، نونليون، ديسيليون. Above 1e33: scientific (`1.23e34`). Western digits by default; setting toggles to ١٢٣. Every number and every `×N` is wrapped in Unicode isolates (U+2066 … U+2069). All counters use `.monospacedDigit()`. |
| Durations display | `2س 14د`, `45د`, `30ث`, `3 أيام`. Never show seconds above 10 minutes. |
| Ids | Lowercase camelCase strings, unique per file. Station ids are `cityId.stationKey` (e.g. `jerusalem.falafel`). |
| Art | Only keys from `tools/art_keys.txt`, SF Symbols (`.heavy`), and vector shapes. Fluent PNGs are 256 px: never draw one larger than **85 pt**. Never render emoji characters as `Text`. |
| RNG | SplitMix64 seeded per purpose (section 7.2). No `Int.random` anywhere in rules code. |
| Multiplier stacking | Bonuses **add within** a category and **multiply across** categories (section 2.9). |

---

## 1. Vision, pillars, tone, brand, HUD and screens

### 1.1 Vision
بسطة فلافل is a warm, premium idle tycoon in which the player grows Grandma Umm Khalil's (ستّي أم خليل) falafel stall in Jerusalem into a family empire across 24 cities. Each city is a new chapter with new dishes, a new rival, a new twist mechanic and its own currency. The player never resets into the same content. Every day brings something to do, every week something new, and every month a new region. The game runs fully offline with no ads and no purchases, and it should still be good to open every day a year from now.

### 1.2 Pillars
1. **Something new within 10 minutes.** Progressive unlocks, a new city every chapter, new dishes and art, one twist mechanic per city.
2. **A reason to return in hours and tomorrow.** Vault, research, supply runs and contracts work in hours. Calendar, orders, league, weekend venue and season work in days and weeks.
3. **A long horizon.** The campaign takes about 3 months for a casual player and can never be finished in under about 25 days. Collections, chefs, leagues, seasons, contracts and events never end.
4. **Premium, consistent feel.** One art language (Fluent 3D, wood and gold), a living street, and one feedback system with four tiers.
5. **Forgiving.** Nothing withers, nobody quits, there are no offline losses, missed days pause tracks instead of resetting them, and every random event comes out positive.

### 1.3 Player fantasy
"I'm the grandchild who took Teta's falafel recipe from a wooden cart in the Old City to the whole world, one neighbourhood at a time, and everyone in the street knows my name." The player is an معلّم (master), not a clerk: they hire, invest, travel, collect heritage and win rivals over.

### 1.4 Tone and voice
- **Register:** polite Palestinian colloquial (عامية فلسطينية مهذبة). Warm, cheeky and family-friendly. No MSA except proper names. Second person singular masculine is the default; FTUE asks once (يا شب / يا صبية) and stores `addressForm` (m/f). Every string with gendered verbs has `_m` and `_f` variants in strings.json.
- **Bubbles:** 8–12 words. Buttons: 1–2 words. Toasts: at most 6 words.
- **Vocabulary:** يلا، هسّا، كمان، منيح، شو، وين، عشان، بدّك، خلّص، إشي، هيك، والله، يا سلام، يا عيني، الحق، استنّى، تعال.
- **Grandma's voice (ستّي):** tender and proud, with proverbs ("اللي بدّه يعمل جمّال بعلّي باب داره"، "الرزق بحب الخفّية"). Rivals are cheeky but kind, and never insulting.
- **Taboos:** no politics, no real brands, no mocking accents, nothing festive on mourning dates (6.11), no gambling words (use "حظّ" and "مفاجأة"; never "قمار" or "رهان").
- **Sample lines:** "دقّ عالفلافل عشان تقلي أوّل قرص!"، "يا سلام! طلعت مستوى 2"، "زبون مميّز وصل! الحقه قبل ما يروح"، "الخزنة بتتعبّى لحالها وإنت برّا"، "رجعت الرحلة ومعها إشي حلو".

### 1.5 Brand look
- **Mood:** a sunset market. Dusk sky gradient, string lights, bunting, wooden stalls, gold outlined titles. The palette tokens already exist in `Brand.swift` (duskTop #33172E, duskMid #6E2F4A, sunset #D9714A, glow #FFB36B, wood #6B3A1C / woodDark #3E1F10 / woodLight #9A5A2A, gold #F9B233 / goldLight #FFE38A / goldDeep #D9801A, outline #4A230F, cream #FFF4DE, teal, olive, red, parsley).
- **Materials:** UI panels are `WoodPanel` (wood gradient, 3 pt dark outline, 4 pt bottom lip, inner cream card). Primary buttons are `ChunkyButton` gold with a 3–4 pt lip. Secondary buttons are green (buy), blue (info), purple (meta) or gray (disabled). Corners are 14 pt on panels and 12 pt on buttons.
- **Per-city skin:** each city overrides only the sky gradient (4 colours), the accent colour, the landmark art key and the silhouette shape. Wood and gold UI chrome never changes, so the brand stays constant.
- **Typography:** display text uses Baloo Bhaijaan 2 ExtraBold via `Font.game` (28 titles, 22 headers, 18 buttons, 16 numbers). Body text uses Cairo SemiBold/Bold via `Font.body` (15 body, 13 captions). Never apply letter spacing to Arabic. Outlined text (`OutlinedText`) is only for titles and big numbers.
- **Icons:** SF Symbols `.heavy`, white with a 2 pt outline, inside chunky circles. 3D art (Fluent) is used for objects only: dishes, people, vehicles, buildings, chests and currencies. There is one light direction (top-left) and one shadow spec (0, 3, radius 0, outline colour at 35%).
- **Rarity:** shown by frame shape as well as colour. Common: a rounded square in wood brown. Rare: a hexagon in teal. Epic: an octagon in purple with 2 gems. Legendary: a scalloped badge in gold with 4 gems and a slow shine sweep.
- **Currency art:** gold `ui_coin`; Golden Za'atar `food_herb` inside a gold ring; stars `ui_star`; XP `ui_sparkles`; tickets `ui_admission_tickets`; streak freeze `ui_snowflake`; time warp `ui_hourglass`; league reputation `ui_sports_medal`; season points `ui_ticket`; city cash per city (Appendix A).

### 1.6 Navigation and HUD (RTL)

**Layout (portrait only).** From top to bottom:

| Zone | Height | Content |
|---|---|---|
| Top bar | 56 pt + safe area | Right: level badge (48 pt circle, XP ring, level number; title under it in 11 pt). Centre: up to 3 currency pills (30 pt high). Left: gear (40 pt) and the newspaper button (only when unread). |
| Stage | ~210 pt | Living street scene for the active kitchen: landmark, stall at its tier, customers, special customer, twist props. Side rails overlay this zone. |
| Goal strip | 64 pt | 3 goal chips (city) / deadline + 3-goal bar (contract) / milestone track (event). |
| Content | flexible | Station list (scroll). |
| Action bar | 52 pt floating | Buy-mode toggle (×1 / ×10 / التالي / أقصى), ترقيات button, and a twist button when the city has one. |
| Tab bar | 64 pt + safe area | 5 tabs; the centre tab is raised 1.25×. |

**Currency pills:** at most 3. Kitchen: city cash, gold, stars (`★ 12/33`). Contract: contract cash, gold, delivered %. Event: event cash, gold, event tokens. Other tabs: gold, Golden Za'atar (from L14, else XP to next level), tickets (from L11). Gold has a "+" that opens the shop.

**Tabs:** RTL visual order from right to left, single-word labels:

| # (right→left) | Label | SF Symbol | Unlock | Contents |
|---|---|---|---|---|
| 1 | الخريطة | `map.fill` | L6 | City route, branches, licence, branch safe |
| 2 | المهام | `checklist` | L9 | اليوم، الأسبوع، الروزنامة، الموسم، الإنجازات |
| 3 (centre, raised) | البسطة | `flame.fill` | L1 | The active main kitchen |
| 4 | الطبّاخين | `person.3.fill` | L4 | Chefs, equipped slots, chests |
| 5 | الدكان | `bag.fill` | L4 | Chests, time warps, tickets, freezes, cosmetics, daily chef stall |

A locked tab shows a lock glyph and "مستوى 6" in place of its label. Tapping it opens a teaser card ("بتفتح بمستوى 6: الخريطة ومدن جديدة!") and plays T0 only.

**Side rails:** 52 pt round buttons. There are at most 4 per rail plus a "more" chevron. Each button has a countdown chip (11 pt, pill) or a red dot.
- **Right rail (live-ops):** مهرجان الويكند، طلبيات، الدوري، الموسم، عيد/موسم (festival).
- **Left rail (appointments):** دفتر ستّي (research timer), رحلات (soonest return), خزنة الفروع (fill %), تذاكر (count/timer), المفتّش (warning countdown).
- **Locked items:** each rail shows only the **next** locked item as a "?" silhouette with "مستوى N". Others stay hidden.

**Red dots** mean exactly "something can be claimed or started right now":
- a goal ready to claim
- a free chest
- an idle research slot when research is affordable
- an idle supply slot
- a calendar claim available
- a completed order
- a league result
- a season tier ready
- a branch safe ≥ 50%
- an event milestone reward
- a new contract with a free slot

Nothing else gets a red dot, ever.

**Banners** (under the top bar, 36 pt, slide in): rush hour, frenzy, festival hour, inspector warning, clock-rollback warning, licence ready. At most one at a time; priority follows the list order, reversed so that clock warning comes first.

### 1.7 Screens and modals
Every screen has these states: `loading` (skeleton wood cards, never a spinner over 300 ms), `normal`, `locked teaser`, `empty`, and `claimable`. Only the deviations are listed below.

| # | Screen / modal | Layout | States and notes |
|---|---|---|---|
| S1 | **Kitchen (البسطة)** | HUD; stage; goal strip (3 chips: art 32 pt, text, progress bar, claim button); station cards (see S2); action bar | **Frenzy:** gold vignette and a "×5" chip. **Rush hour:** banner plus a ×2 chip on cards. **Twist widgets** (3.6). **Graduation ready:** goal strip replaced by a pulsing gold "افتح فرع وانقل على {next}" card. **Licence pending:** the same card shows a countdown. **Clock guard:** banner, and timers show "متوقّف". |
| S2 | **Station card** (92 pt) | Right: 64 pt dish art on a plate disc. Centre: name (Font.game 17), "مستوى 37/100", segmented milestone bar to the next milestone (pulses above 80%; a ghost segment previews the purchase), income "2.4 مليون/ث". Left: buy button (green, cost, "×10" badge), cook ring (24 pt) around the dish while cycling. Manager: a 22 pt ppl_ badge or a blue "وظّف معلّم" button | **Locked:** grey silhouette, "افتح بـ {cost}" button. **Unaffordable:** buy button grey, shows cost and ETA ("بعد 3د"). **Max:** gold frame, "مكتمل" ribbon. **Unmanaged:** "دقّ للطبخ" hint and the dish bounces every 4 s while idle. **Chef boost:** small chef face 18 pt and "+80%" chip. |
| S3 | Station detail sheet | Milestone list (✓ / next / locked), chef bonuses, manager, twist info, lifetime earned | Opened by long-press or by tapping the name |
| S4 | Upgrades sheet (ترقيات) | List of the next 3 unbought cash upgrades + "و{n} كمان" | Buy with green; bought ones collapse into a counter |
| S5 | Goals sheet | Header: stars `x/total`, graduation threshold marker, licence timer. List: claimed ✓, the 3 active ones, then "؟" silhouettes with type icons only | |
| S6 | **Map (الخريطة)** | Vertical scroll route (bottom = Jerusalem). Three region banners: فلسطين، الوطن العربي، العالم. City nodes: 72 pt disc with landmark art (≤ 64 pt) | Node states: **locked** (silhouette, "؟", "بدها رخصة/نجوم"), **next** (padlock with licence countdown), **current** (pulsing ring, stars ring), **branch** (gold rim, level pip, "{x} ذهب/يوم"), **crowned** (crown overlay). Top card: branch safe (fill bar, "اجمع", cap). |
| S7 | Branch sheet | Stall preview at its tier, level 0–10, bonus (+2% global income per level), gold/day, upgrade button (gold) | |
| S8 | Graduation sequence (T3) | Confirm modal → stall sign "فرع" → route travel animation → new city reveal (landmark, palette crossfade) → story scene | Skippable after first view |
| S9 | **Chefs (الطبّاخين)** | Top: equipped slots row (locked slots show "مستوى 15"). Segments: الطبّاخين (grid 3 columns, filter chips by cuisine), الصناديق (inventory and open) | Unowned chef: silhouette and rarity frame |
| S10 | Chef detail | Portrait in rarity frame, cuisine/category tags, level, card bar "12/20", level-up (cards + gold), skill (epic+), "وين بيقوّي؟" list of matching stations in the current kitchen | |
| S11 | Chest reveal (4 beats) | Full screen dim; see 1.8 T2/T3 | Tap skips each beat; "تخطّي" button after 3 views |
| S12 | **Tasks (المهام)** | Segmented control: اليوم، الأسبوع، الروزنامة، الموسم، الإنجازات | Each segment is its own view |
| S13 | Today | Streak flame (count, freezes), 3 order cards (progress, reward, reroll), bonus chest meter 0/3, daily market and weather card | |
| S14 | Calendar | 4×7 grid; today pulses; claimed days stamped; day 28 big | |
| S15 | Season | Header: theme art, days left, points bar. Horizontal track of 50 tiers | |
| S16 | Achievements | Families list with tier pips (5) and the next target | |
| S17 | **Shop (الدكان)** | Sections: الصناديق، رزم وقت، تذاكر، تجميد السلسلة، بسطة الطبّاخين (3 daily chef-card offers), ديكور، عملة المهرجان (when active) | All prices in gold. A "مش كافي" sheet links to the gold sources list (never to money) |
| S18 | Research (دفتر ستّي) | Notebook pages: 4 branch tabs. Node cards: level, effect now→next, cost, time. Slot strip at the top with timer and "خلّصها بـ {g}" | Locked nodes show "مستوى N" |
| S19 | Supply runs (رحلات التوريد) | Garage with 3 slots → vehicle picker (ladder; locked silhouettes) → duration picker (3 cards, loot preview) → "ابعت" | Return → reveal (T1/T2) |
| S20 | Heritage box (صندوق التراث) | 8 set shelves × 4 items, item level pips, set bonus, craft points, "اصنع" | Inside S19 as its second segment |
| S21 | Contracts board (طلبيات) | Cards: title, art, "جديد" or "إعادة", grade, duration, 3 reward icons, partners | Slot-full state |
| S22 | Contract kitchen | Kitchen UI; goal strip = deadline + 3-goal bar with partner contributions stacked in partner colours | End state → results modal |
| S23 | Weekend venue | Kitchen UI with the theme palette and decorations; goal strip = milestone track (10 pips); buttons: الترتيب، دكانة المهرجان | Pre-event teaser Mon–Wed |
| S24 | League (الدوري) | Tier badge, countdown to Monday 04:00, 30 rows (rank, chain name, avatar art, score); green promotion zone, red demotion zone; rewards preview | Result modal on Monday |
| S25 | Profile sheet | Level, title ladder, stats, Za'atar count and ×, multiplier breakdown ("ليش دخلي هيك؟") per category | Opened from the level badge |
| S26 | Settings | 6.17 | |
| S27 | Newspaper (جريدة الحارة) + vault | Paper texture card: headline, vault amount with count-up, up to 6 short items, "اجمع" (+ "اجمع ×2" once per day for gold) | Shown on return ≥ 60 s away (vault) and ≥ 60 min away (with happenings) |
| S28 | Choice event | Wood modal: 64 pt art, title, 2–3 lines, 2–3 choice buttons with hint chips (أكيد / حظّ) | |
| S29 | Special customer | In-scene: customer art 56 pt with a gold glow and a 15 s ring; a tap opens a reward pop | |
| S30 | Rush minigame | 6.13 | |
| S31 | Level-up | Ribbon, level number, rewards row, "شو فتح" teaser of the next unlock | T2 |
| S32 | System unlock ceremony | Lock breaks, icon flies to its rail/tab, 1-line explanation, one-time spotlight | T2 |
| S33 | Story scene | Bottom sheet, portrait 72 pt, `StoryBubble`, tap to continue | |
| S34 | Legacy gift | 6.16 | Once |
| S35 | Inspector visit | Clipboard modal with 6 checks and the score | |
| S36 | Festival intro | Theme art, effects list, dates | Once per festival instance |
| S37 | Daily market detail | Today's modifiers and weather with effect chips | |

### 1.8 Feedback tiers
One API: `Feedback.play(_ tier: Tier, at: CGPoint?, art: String?, amount: Double?)`. Screens never call SFX, Haptic or FX directly.

| Tier | Visual | Sound | Haptic | Rate limit |
|---|---|---|---|---|
| **T0 micro** | Press scale 0.94 for 80 ms; a tiny pop at the point | `tick`, pitch ±6% random | light, intensity 0.45 | 10/s; haptic ≥ 80 ms apart |
| **T1 minor** | Coins/items fly to the HUD target: count = clamp(4 + 2·log10(amount), 4, 14), accelerate over 0.45–0.7 s. The HUD display value lags: each landing adds amount/n and bumps the counter to 1.15×. Float label "+1.2 مليون" | `coin` rising 1 semitone per coin (pre-rendered coin_0…coin_12), ≤ 1 per 70 ms | medium on the first landing | 4/s |
| **T2 major** | Ribbon + rays + 40–60 confetti pieces, count-up 0.35 + 0.15·log10(Δ) s (max 1.2 s), modal with spring (response 0.45, damping 0.7) | `levelup` / `reward` sting | `.success` | 1 per 60 s; excess downgrades to T1 |
| **T3 epic** | 60–100 ms freeze, white flash (≤ 3 flashes/s), 6–10 pt decaying shake, 60–120 sparks, 2.5–4 s skippable sequence | fanfare sting | AHAP crescendo (0.6 s ramp + heavy transient) | 1 per 10 min; excess downgrades to T2 |

Reduce Motion: no shake, flights become fades, particles ×0.3, and sound and haptics stay. Settings toggles mute their channel only.

**Event mapping (complete):**

| Event | Tier | Notes |
|---|---|---|
| Any button press, tab switch, toggle | T0 | |
| Tap-to-cook start | T0 | |
| Cycle completes (unmanaged, player-started) | T1 (small) | Coin count 4 |
| Cycle completes (managed) | none | Scene coin pop only, no sound above 2 cycles/s |
| Buy station level(s) | T0 + bar fill | T1 if it crosses a milestone |
| Station milestone reached | T1 | "سرعة ×2" / "ربح ×2" float |
| All-stations milestone | T2 | |
| Unlock station | T1 | |
| Hire manager | T1 | Manager badge drops in |
| Cash upgrade bought | T1 | |
| Goal completed (ready) | T0 chime + red dot | |
| Goal claimed 1★/2★ | T1 | Stars fly to the star pill |
| Goal claimed 3★ | T2 | |
| Crown (100% city) | T2 | |
| City graduation and new city | T3 | |
| Empire level up | T2 | |
| New system unlock ceremony | T2 | |
| Special customer appears | T0 (bell) | |
| Special customer tapped | T1; Frenzy start T2 | |
| Choice event outcome | T1 | |
| Rush hour begins (app open) | banner + T0 | |
| Festival begins | T2 | Once per day |
| Chest open: wood/silver | T2 | Legendary inside → T3 |
| Chest open: gold | T3 | |
| New chef obtained | T2 | |
| Chef level up | T1 | Level 10 → T2 |
| Research started | T0 | |
| Research complete (claim) | T1 | |
| Supply run sent | T0 + truck drive-off | |
| Supply run return (claim) | T1; epic/legendary item T2 | |
| Heritage set completed | T2 | |
| Calendar claim | T1; day 28 T2 | |
| Streak +1 | T1; milestone T2 | |
| Daily order complete | T1 | |
| All 3 daily orders (bonus chest) | T2 | |
| Weekly order complete | T1 | |
| League promotion result | T2; stay/demote T1 | |
| Season tier reached | T1; tier 25/50 T2 | |
| Contract goal 1/2 | T1 | Goal 3 → T2 |
| Event milestone 1–9 | T1; milestone 10 T2 | |
| Rush minigame correct order | T0 | Wrong → `wrong` sound + light shake, no haptic error |
| Rush minigame round end | T1; new best T2 | |
| Achievement tier | T1 | |
| Vault collect | T1 (coin count by amount) | |
| Branch safe collect | T1 | |
| Branch upgrade | T1; stall-tier change T2 | |
| Error (can't afford) | T0 + `error` sound, button shake 4 pt | No haptic error |


---

## 2. The Kitchen engine

One engine (`Kitchen`, a value type plus pure rule functions) runs three kinds of kitchen:

| Kind | Instances | Adds |
|---|---|---|
| `city` | 1 active (the current city) | Goals/stars, story, licence, twists, branches on graduation, per-city cash name |
| `contract` | 0–2 active | Deadline, 3 goals, NPC partners, rules, side tier table |
| `event` | 0–1 active (Thu–Sun) | Theme, event cash, tokens, 10 milestones, NPC ranking, side tier table |

### 2.1 State
`Kitchen { id, kind, defId, stations: [StationState], cash: Double, lifetimeEarned: Double, upgradesBought: Set<Int>, twistState: [TwistState], counters: [String: Double], openedAt: Date }`
`StationState { level: Int (0 = locked), managed: Bool, progress: Double (0..<1), cooking: Bool, lifetimeEarned: Double, milestonesSeen: Int }`

Station 0 of every kitchen starts at **level 1**. City kitchens start with `cash = 50 × priceScale`. Side kitchens start with `cash = 20`.

### 2.2 Tier tables (economy.json)
A station's numbers come from its **tier** (its index in its kitchen) and its kitchen's table. Content only names dishes and art.

**City table** (`economy.cityTiers`):

| Tier | baseCost b | growth r | baseCycleSec | baseRevenue | managerMult |
|---|---|---|---|---|---|
| 0 | 5 | 1.09 | 1 | 1 | 200 |
| 1 | 60 | 1.15 | 3 | 60 | 200 |
| 2 | 720 | 1.14 | 6 | 540 | 120 |
| 3 | 8,640 | 1.13 | 12 | 4,320 | 60 |
| 4 | 103,680 | 1.12 | 24 | 51,840 | 15 |
| 5 | 1,244,160 | 1.11 | 96 | 622,080 | 8 |
| 6 | 14,929,920 | 1.10 | 384 | 7,464,960 | 6 |
| 7 | 179,159,040 | 1.09 | 1,536 | 89,579,520 | 4 |

**Side table** (`economy.sideTiers`, contracts and weekend venues):

| Tier | b | r | baseCycleSec | baseRevenue | managerMult |
|---|---|---|---|---|---|
| 0 | 10 | 1.10 | 2 | 2 | 20 |
| 1 | 150 | 1.12 | 8 | 60 | 20 |
| 2 | 2,500 | 1.13 | 30 | 1,500 | 15 |
| 3 | 40,000 | 1.14 | 120 | 40,000 | 10 |
| 4 | 800,000 | 1.15 | 480 | 1,200,000 | 8 |

### 2.3 Costs and bulk buy
For a station at level `n` (S = kitchen priceScale; 1 for side kitchens):
- Next level: `cost(n) = S · b · rⁿ`. Unlocking is buying level 1 from level 0: `S · b`.
- k levels: `C(n,k) = S · b · rⁿ · (r^k − 1)/(r − 1)`.
- Max affordable with cash `C`: `k = ⌊ ln(1 + C·(r−1)/(S·b·rⁿ)) / ln r ⌋`, clamped to `[0, cap − n]`. If `C(n,k) > C` because of rounding, use `k − 1`.
- Research A3 "مورّد أمين" multiplies all station costs by `(1 − 0.02·A3)`. The market modifier `levelSale` multiplies by 0.75. They stack multiplicatively, with a floor of 0.5.

**Buy modes** (one global toggle that cycles on tap and is remembered per kitchen kind):

| Mode | Label | k |
|---|---|---|
| ×1 | `×1` | 1 |
| ×10 | `×10` | min(10, cap − n). Disabled (grey, showing the cost) if unaffordable |
| Next | `التالي` | next station milestone − n (or cap − n) |
| Max | `أقصى` | max affordable (≥ 1; else disabled showing the cost of 1) |

### 2.4 Income
For station i at level n ≥ 1:
```
speedMult_i  = 2^(stationMilestones_i) × (1 + 0.02·A4) × twistSpeed_i × activeSpeed_i
profitMult_i = 3^(upgrades on i or all) × 2^(allStationMilestones) × chef_i × perm × twistProfit_i × day × active
income_i (/s) = n × baseRevenue_i × profitMult_i × speedMult_i / baseCycle_i
```
- **Cycle floor 0.5 s.** The displayed cycle is `T_eff = max(0.5, baseCycle_i / speedMult_i)`. Speed beyond the floor is not lost: income uses the full `speedMult_i`. A milestone that would push past the floor is labelled "ربح ×2" instead of "سرعة ×2".
- **Payout per completed cycle** is `income_i × T_eff`. Cash is credited when a cycle completes. At 10 Hz with a 0.5 s floor, at most one completion per station per tick; implement as `while progress >= 1`.
- **Customers served** (`counters.customers`) goes up by 1 per completed cycle.

### 2.5 Milestones
- **Station milestones** (×2 each) at levels `[10, 25, 50, 100, 150, 200, 250, 300, 350, 400]`, filtered to ≤ cap. Each is labelled speed or profit as above. Reaching one for the first time gives 2 XP (city kitchens only).
- **All-stations milestones** (×2 profit to every station) once **every** station of the kitchen (locked = 0) is ≥ `[25, 50, 100, 150, 200, 250, 300, 400]`, filtered to ≤ cap. The goal strip shows the next one: "كل المحطّات 50: 5/7".
- Side kitchens use station milestones `[10, 25, 50, 75, 100, 125, 150]` and all-stations `[25, 50, 100, 150]`.

### 2.6 Level caps
| Cities | Cap |
|---|---|
| 1–3 | 100 |
| 4–8 | 200 |
| 9–16 | 300 |
| 17–24 | 400 |
| Side kitchens | 150 |

At cap the card shows a gold frame and "مكتمل". The buy button becomes a disabled "أقصى مستوى".

### 2.7 Managers and tap-to-cook
- **Before a manager:** tapping an idle station starts one cycle (T0). When it completes, cash is credited (T1 small) and the station waits idle. Tapping a cooking station does nothing except a 3% bounce. Unmanaged stations earn nothing offline.
- **Hire:** `managerCost_i = S · b_i · managerMult_i · (1 − 0.05·A2) · marketMgrSale`. `marketMgrSale` = 0.5 on "managerSale" days. After hiring, the station auto-restarts forever and earns offline. Each city station has an authored `managerName` (optional; fallback "معلّم {dish}") and `managerArt` (ppl_ key).
- **Unlock gate:** managers unlock at empire L2. FTUE step 7 (section 6.18) forces the first hire.

### 2.8 Cash upgrades (ترقيات)
Generated per city by the content tool and stored explicitly in cities.json so designers can edit names.
- Order: stations 0…N−1, then "all", then stations 0…N−1 again, then "all".
- `price_j = S · 2.5e5 · 20^j` (base `economy.upgradeBase`, ratio `economy.upgradeRatio`).
- Generate entries while `2.5e5 · 20^j ≤ 10 · finalGoalBase`.
- Each upgrade gives ×3 profit to its target.
- Names: "{dish}: وصفة سرّية ×3", and for "all" "يافطة جديدة: كل المحطّات ×3". Designers may override them.
- Side kitchens get 3 upgrades at `2e4 · 30^j` (j = 0, 1, 2), targeting stations 0, 1 and all.

### 2.9 Multiplier categories
Within a category, bonuses add. Across categories, they multiply. `perm` is the product of categories 5–8 (city kitchens) or 9 (side kitchens).

| # | Category | Formula | Applies to |
|---|---|---|---|
| 1 | Milestones | `2^stationMs × 2^allMs` | all kitchens |
| 2 | Cash upgrades | `3^count` | own kitchen |
| 3 | Chefs (per station) | `1 + Σ matching chef bonus × (1 + 0.03·D5) × (1 + tatreezSet)` (6.1) | all kitchens |
| 4 | Twists (per station) | 3.6 | kitchen with that twist |
| 5 | Branches | `1 + 0.10·branches + 0.02·Σ branchLevels` | cities |
| 6 | Research income | `1 + 0.05·A1` | cities |
| 7 | Golden Za'atar | `1.05^Z` | cities |
| 8 | Heritage income | `1 + glassSetBonus` | cities |
| 9 | Side boost | contracts `1 + 0.15·D3 + copperSet`; events `1 + 0.15·D4 + copperSet` | side kitchens |
| 10 | Day | product of today's market income modifiers × weather × festival day effects, capped at ×5 | all kitchens, online and offline |
| 11 | Active | product of rush hour, frenzy, ولعة, chef skill, iftar hour, fresh dough, capped at ×50 | foreground only |

`powerScore = categories 5 × 6 × 7 × 8` is shown in the profile sheet as "قوّة الإمبراطورية ×{p}" and drives contract and event grades together with empire level (6.9).

### 2.10 Offline vault (الخزنة)
- **Cap:** `capHours = 3 + C1 + soapSetHours`, max 16.
- **Efficiency:** `eff = 0.50 + 0.05·C2`, max 1.00.
- **On resume:** take `gap = trustedNow − lastActiveTick` (7.3).
  - If `gap < 60 s`, catch up silently at the full online rate without the active category, and show no modal.
  - Otherwise `window = min(gap, capHours·3600)`, and for every kitchen with at least one manager: `vault_k = offlineIncome_k(window) × eff`.
- **offlineIncome** sums managed stations only, with categories 1–10. Category 11 is excluded. Twists provide closed forms (3.6).
  - If the window crosses a game-day boundary, split it and use each day's modifiers.
- **Presentation:** the newspaper modal (S27) shows the vault with one line per kitchen ("القدس +2.3 مليار، طلبية العرس +14 مليون"). The only exit is "اجمع" (T1).
- **"اجمع ×2" (once per game day):** costs `clamp(ceil(10 × window_h × eff), 5, 160)` gold.
- **Rail icon:** shows the cap ("3س") while online. The notification rule is in 6.15.
- **Fresh dough (عجينة طازة):** if `gap ≥ 24 h`, grant an active ×2 boost lasting `30 min × min(3, ⌊gap/24h⌋)` of active time. Toast: "عجينة طازة! دبل لمدّة {m} دقيقة".

### 2.11 Active boosts (category 11)
All active boosts count down in **active time only**: the app is in the foreground and not in a modal longer than 10 s.

| Boost | Multiplier | Duration | Source |
|---|---|---|---|
| Rush hour (ساعة الذروة) | ×2 (+0.1 per B3 level, max ×3) | Clock windows 12:00–14:00 and 19:00–22:00 local | 6.12 |
| Frenzy (عجقة زباين) | ×5 | 60 s + 6 s per B2 level | special customer |
| ولعة | ×2 | `clamp(5 + score/400, 5, 30)` min, banked up to 60 min | rush minigame |
| Chef skill | per chef | per chef | epic/legendary chefs (L22) |
| Fresh dough | ×2 | 30–90 min | 2.10 |
| Iftar hour (Ramadan) | ×5 (replaces rush hour) | sunset −10 min → +80 min | 6.11 |

The product is capped at ×50. HUD chips show each active boost with its remaining time.

**Time warp (رزمة وقت)**: instantly credits `minutes × 60 × Σ managed income_i` (categories 1–10) to the **current** kitchen. Sources: rewards, and the shop from L24 (10 gold per hour, max 3 per day).

### 2.12 Tick order (GameStore, 10 Hz)
1. Update the trusted clock (7.3); bail out if frozen.
2. Process game-day and week rollovers. They are idempotent and keyed by `gameDay` and `weekId`.
3. Happenings scheduler (6.12).
4. For each active kitchen: twists `tick(dt)`, then stations advance (`progress += dt / T_eff`), then income is credited.
5. Timers: research, supply runs, contracts, event, licence, branch safe, tickets.
6. Evaluate goals, orders, achievements and unlocks at 2 Hz. Fire feedback events.
7. Save every 10 s, on background, and after any claim or purchase of gold, chest or chef.

### 2.13 Kitchen variant summary

| | City | Contract | Event |
|---|---|---|---|
| Tier table | city | side | side |
| Stations | 6–8 | 3–5 | 3–4 (4th unlocks at milestone 3) |
| Cap | 100–400 | 150 | 150 |
| Cash | per-city currency | "كاش الطلبية" (`ui_money_bag`) | per-theme event cash |
| Progress metric | goals/stars | lifetime earned (delivered) | lifetime earned (score) |
| Perm categories | 5–8 | 9 | 9 |
| Ends | graduation | deadline | Monday 04:00 |
| Offline | yes | yes | yes |

---

## 3. City ladder

### 3.1 The 24 cities
Full rows (stations, dishes, art, palette, rival) are in Appendix A. The calibration numbers below come from `design/tools/campaign.py` (greedy bot with the casual profile of 3 sessions, 12/8/15 min, and day 0 sessions of 25/8/12 min; binge 4×2 h). Expect real players to be about 20% slower than the bot.

| # | id | City | Region | Stations | Cap | Licence h | finalGoalBase (log10) | priceScale | Twist(s) | Casual start day (bot) | Casual days | Binge start day |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | jerusalem | القدس | فلسطين | 6 | 100 | 0 | 10.5 | 1 | — | 0.42 | 0.17 | 0.42 |
| 2 | bethlehem | بيت لحم | فلسطين | 6 | 100 | 0 | 11.3 | 1 | busWaves | 0.58 | 0.75 | 0.52 |
| 3 | nablus | نابلس | فلسطين | 7 | 100 | 0 | 12.2 | 1 | ovenTiming | 1.33 | 1.0 | 0.75 |
| 4 | hebron | الخليل | فلسطين | 7 | 200 | 1 | 13.0 | 1 | productionChain | 2.33 | 1.54 | 1.38 |
| 5 | jaffa | يافا | فلسطين | 7 | 200 | 2 | 13.7 | 1 | portShipments | 3.88 | 2.46 | 1.67 |
| 6 | haifa | حيفا | فلسطين | 7 | 200 | 4 | 14.1 | 1.1 | deliveryRuns | 6.33 | 2.54 | 2.5 |
| 7 | gaza | غزة | فلسطين | 7 | 200 | 8 | 14.5 | 1.4 | weatherSwing | 8.88 | 3.0 | 3.52 |
| 8 | ramallah | رام الله | فلسطين | 7 | 200 | 12 | 14.8 | 1.7 | nightMarket | 11.88 | 3.67 | 5.38 |
| 9 | amman | عمّان | الوطن العربي | 8 | 300 | 24 | 15.1 | 2.2 | productionChain | 15.54 | 3.79 | 6.89 |
| 10 | beirut | بيروت | الوطن العربي | 8 | 300 | 24 | 15.25 | 2.8 | nightMarket | 19.33 | 4.0 | 9.38 |
| 11 | damascus | دمشق | الوطن العربي | 8 | 300 | 24 | 15.4 | 3.5 | busWaves | 23.33 | 4.0 | 11.5 |
| 12 | cairo | القاهرة | الوطن العربي | 8 | 300 | 24 | 15.6 | 4.4 | deliveryRuns | 27.33 | 4.0 | 13.75 |
| 13 | baghdad | بغداد | الوطن العربي | 8 | 300 | 24 | 15.7 | 5.8 | ovenTiming | 31.33 | 4.0 | 16.67 |
| 14 | riyadh | الرياض | الوطن العربي | 8 | 300 | 24 | 15.8 | 7.2 | weatherSwing | 35.33 | 4.0 | 19.58 |
| 15 | dubai | دبي | الوطن العربي | 8 | 300 | 24 | 15.9 | 9 | vipLounge | 39.33 | 4.0 | 22.75 |
| 16 | marrakesh | مراكش | الوطن العربي | 8 | 300 | 24 | 16.0 | 11 | nightMarket + busWaves | 43.33 | 4.21 | 26.39 |
| 17 | istanbul | إسطنبول | العالم | 8 | 400 | 36 | 16.25 | 14 | portShipments + busWaves | 47.54 | 5.0 | 29.75 |
| 18 | athens | أثينا | العالم | 8 | 400 | 36 | 16.35 | 18 | busWaves + weatherSwing | 52.54 | 5.0 | 33.83 |
| 19 | london | لندن | العالم | 8 | 400 | 36 | 16.4 | 23 | weatherSwing + deliveryRuns | 57.54 | 4.79 | 38.38 |
| 20 | paris | باريس | العالم | 8 | 400 | 36 | 16.5 | 29 | vipLounge + ovenTiming | 62.33 | 5.54 | 42.38 |
| 21 | newYork | نيويورك | العالم | 8 | 400 | 36 | 16.55 | 37 | deliveryRuns + nightMarket | 67.88 | 5.46 | 46.58 |
| 22 | santiago | سانتياغو | العالم | 8 | 400 | 36 | 16.6 | 47 | productionChain + vipLounge | 73.33 | 6.0 | 50.83 |
| 23 | rio | ريو دي جانيرو | العالم | 8 | 400 | 36 | 16.65 | 60 | nightMarket + weatherSwing | 79.33 | 6.0 | 55.38 |
| 24 | tokyo | طوكيو | العالم | 8 | 400 | 36 | 16.7 | 79 | ovenTiming + portShipments | 85.33 | 6.54 | 59.75 |

The bot finishes the campaign on day 91.9 (casual) and day 64.7 (binge). After Tokyo comes the story epilogue "رجعة عالقدس" (a T3 family feast and credits) and the endless layer: branches, chefs, research, heritage, leagues, seasons, contracts and events.

**priceScale** is `S_k = max(1, M_k/3)`, where `M_k` is the expected permanent multiplier (`perm` × average chef bonus) at the city's casual start day (`design/tools/meta.py`). This turns the player's meta progress into a ×3 head start rather than a skip. Re-derive S_k whenever meta numbers change.

**Cash targets** in goals are authored in base units (`amountBase`). Runtime target = `amountBase × S_k`. Display uses the city's currency name.

### 3.2 Goals
- Each city has an ordered list of 15–24 goals (Jerusalem has 20, the template has 22). The **3 visible goals** are the first 3 unclaimed goals in list order.
- A completed goal stays in its slot with a pulsing "خذ" button until claimed. Claiming plays T1 (T2 for 3★) and pays the goal's stars, XP and any extra reward.
- **XP per goal** = `10 × stars × (1 + 0.1 × (cityIndex − 1))`, rounded.
- **Progress scope:**
  - `city`: counted from city open. This is the default for kitchen metrics.
  - `slot`: counted from the moment the goal becomes visible. This is the default for meta and time-gated goals, so the player must act after seeing the goal.
- Goals never require spending gold. A goal whose system is still locked shows "بتفتح بمستوى N" and can still be claimed later.

**Goal types** (`goalType` enum; params in SCHEMA.md):

| Type | Params | Metric | Default scope |
|---|---|---|---|
| `unlockStation` | stationId | station level ≥ 1 | city |
| `stationLevel` | stationId, level | station level | city |
| `allStationsLevel` | level | min level over all stations | city |
| `hireManager` | stationId | managed | city |
| `managersCount` | count | managers hired | city |
| `earnCash` | amountBase | lifetime earned × (1/S) ≥ amountBase | city |
| `incomeRate` | amountBase (/s) | current income (categories 1–10) | city |
| `buyUpgrades` | count | cash upgrades bought | city |
| `customersServed` | count | cycles completed | city |
| `tapCook` | count | tap-to-cook cycles | city |
| `specialCustomers` | count | special customers tapped | city |
| `choiceEvents` | count | choice events answered | slot |
| `rushRounds` | count, minScore? | rush minigame rounds | slot |
| `collectVault` | count | vault collections after ≥ 30 min away | slot |
| `startResearch` | count | research levels started | slot |
| `researchLevels` | count | research levels completed | slot |
| `sendSupplyRun` | count | runs sent | slot |
| `supplyReturns` | count | runs claimed | slot |
| `equipChefs` | count | chefs equipped (current) | city |
| `chefTagMatch` | count | equipped chefs matching ≥ 1 station here | city |
| `dailyOrders` | count | daily orders completed | slot |
| `contractGoals` | count | contract goals reached | slot |
| `eventMilestones` | count | event milestones reached | slot |
| `heritageItems` | count | new heritage items obtained | slot |
| `branchCollect` | count | branch safe collections | slot |
| `leagueRep` | amount | reputation earned | slot |
| `twistMetric` | metric (twist enum metric), amount | twist counter | city |

### 3.3 Goal template (cities 2–24)
The content tool generates this list per city, then designers edit it. `N` = station count, `C` = cap, `F` = finalGoalBase, `t` = the city's first twist. `meta1` and `meta2` are picked from the eligible-meta table below by expected empire level at the city's start.

| # | Type | Target | ★ | Extra reward |
|---|---|---|---|---|
| 1 | unlockStation | s1 | 1 | |
| 2 | stationLevel | s0 = 25 | 1 | |
| 3 | managersCount | 2 | 1 | |
| 4 | unlockStation | s2 | 1 | |
| 5 | twistMetric | t.intro | 1 | wood chest |
| 6 | earnCash | F × 1e-5 | 2 | |
| 7 | unlockStation | s⌈N/2⌉ | 1 | |
| 8 | buyUpgrades | 2 | 1 | |
| 9 | managersCount | N | 2 | |
| 10 | allStationsLevel | 25 | 2 | gold 10 |
| 11 | meta1 | see table | 2 | |
| 12 | earnCash | F × 1e-3 | 2 | |
| 13 | stationLevel | s(N−1) = 50 | 2 | |
| 14 | twistMetric | t.mid | 2 | |
| 15 | allStationsLevel | 50 | 2 | wood chest |
| 16 | buyUpgrades | ⌈count(upgrades ≤ F/10)⌉ | 2 | |
| 17 | meta2 | see table | 2 | |
| 18 | earnCash | F × 0.1 | 3 | |
| 19 | allStationsLevel | min(100, C/2) | 3 | |
| 20 | twistMetric | t.hard | 3 | silver chest |
| 21 | stationLevel | s0 = C | 3 | |
| 22 | earnCash | F | 3 | (claiming every goal = crown, 3.5) |

Total stars: 42. `starsToGraduate = ceil(0.75 × total)` = 32. Cities without twists (only Jerusalem) replace twist goals with `specialCustomers` 1/5/15.

**Eligible meta goals** (pick the first whose unlock level ≤ the expected level at city start + 1):

| Expected level | meta1 | meta2 |
|---|---|---|
| < 9 | startResearch 1 | sendSupplyRun 2 |
| 9–13 | researchLevels 2 | dailyOrders 3 |
| 14–19 | contractGoals 1 | supplyReturns 4 |
| 20–34 | contractGoals 2 | eventMilestones 3 |
| ≥ 35 | researchLevels 3 | heritageItems 3 |

Twist goal amounts (`intro / mid / hard`):
- busWaves `busesWelcomed`: 1 / 5 / 15
- ovenTiming `ovenPerfects`: 5 / 40 / 150
- productionChain `chainUnits`: 100 / U1h / 20 × U1h, where U1h = units the output station consumes in 1 h with both stations at level 50 and no upgrades (the content tool computes it)
- portShipments `shipmentsDelivered`: 1 / 4 / 10
- deliveryRuns `deliveriesDone`: 3 / 20 / 60
- weatherSwing `weatherEarnedBase`: F×1e−4 / F×1e−2 / F×0.05
- nightMarket `nightEarnedBase`: F×1e−4 / F×1e−2 / F×0.05
- vipLounge `vipServed`: 1 / 6 / 20

When a city has two twists, rows 5 and 14 use the first twist and row 20 uses the second.

### 3.4 Jerusalem goals (authored, FTUE-aligned)
F = 3.16e10, S = 1. Total 33★, graduation at 25★. Goals 14, 17 and 18 are time gates that hold back session 1 (≈ 40–50% of stars in session 1).

| # | Type | Target | ★ | Arabic text |
|---|---|---|---|---|
| 1 | unlockStation | jerusalem.hummus | 1 | افتح محطة الحمّص |
| 2 | stationLevel | falafel 10 | 1 | كبّر الفلافل لمستوى 10 |
| 3 | hireManager | falafel | 1 | وظّف معلّم للفلافل |
| 4 | unlockStation | jerusalem.tea | 1 | افتح محطة الشاي بالنعنع |
| 5 | earnCash | 5,000 | 1 | اربح 5,000 جنيه |
| 6 | managersCount | 3 | 1 | وظّف 3 معلّمين |
| 7 | specialCustomers | 1 | 1 | استقبل زبون مميّز |
| 8 | stationLevel | falafel 25 | 1 | الفلافل لمستوى 25 |
| 9 | unlockStation | jerusalem.kaak | 1 | افتح كعك القدس |
| 10 | buyUpgrades | 1 | 2 | اشتري أوّل ترقية |
| 11 | equipChefs | 1 | 2 | حطّ طبّاخ بالمطبخ |
| 12 | unlockStation | jerusalem.ful | 2 | افتح محطة الفول |
| 13 | earnCash | 1e8 | 2 | اربح 100 مليون جنيه |
| 14 | collectVault | 1 | 2 | ارجع واجمع الخزنة |
| 15 | unlockStation | jerusalem.maqluba | 2 | افتح المقلوبة |
| 16 | allStationsLevel | 25 | 2 | كل المحطّات لمستوى 25 |
| 17 | startResearch | 1 | 2 | افتح دفتر ستّي وابدأ بحث |
| 18 | sendSupplyRun | 1 | 2 | ابعت أوّل رحلة توريد |
| 19 | allStationsLevel | 50 | 3 | كل المحطّات لمستوى 50 |
| 20 | earnCash | 3.16e10 | 3 | اربح 31.6 مليار جنيه (تاج القدس) |

### 3.5 Graduation, licences, branches
- **Graduation requires** all three of:
  1. stars ≥ starsToGraduate;
  2. the licence for the next city is ready;
  3. a next city exists.
- **Action:** the goal strip turns into a pulsing gold card. Confirm modal: "رح تسكّر {city} وتصير فرع. الفرع بعطيك ذهب كل يوم و+10% دخل لكل المدن الجاية." If goals remain: "الأهداف اللي ما خلّصتها رح تروح (والتاج كمان)." Then the T3 sequence (S8).
- **Result:**
  - The city's kitchen is discarded. Its summary (stars, crown, lifetime earned, final income) is kept in `branches[cityId]`.
  - The next city kitchen opens.
  - Graduation XP = `50 × cityIndex`.
  - Story finale scene plays, then the arrival scene of the next city.
- **Crown (تاج):** claiming every goal of a city gives +1 Golden Za'atar and a crown on the map node. The branch starts at level 1 instead of 0.
- **Licences (رخصة البلدية):** city k's licence timer starts automatically when city k−1 opens. Durations (hours) by city index: 1–3: 0; 4: 1; 5: 2; 6: 4; 7: 8; 8: 12; 9–16: 24; 17–24: 36. Licences cannot be rushed with gold. The map node and the goals sheet show "الرخصة بتطلع بعد 5س 20د".
- **Branch income (gold):** `goldPerDay_b = 0.5 × (1 + 0.2 × level_b)`.
  - `total = Σ goldPerDay_b × (1 + 0.10·D1) × (1 + memoriesSet)`.
  - Soft cap: `effective = total ≤ 10 ? total : 10 + 2·√(total − 10)`.
  - The gold accrues continuously into خزنة الفروع up to `capHours = 8 + D2` hours of `effective/24` per hour. Collecting takes ⌊stored⌋ gold; the fraction is kept.
  - The safe shows "{x} ذهب/يوم".
- **Branch upgrades** (gold; from L17), level 0→10:
  - Cost to go from L to L+1: `20·(L+1) + 5·L²` = 20, 45, 80, 125, 180, 245, 320, 405, 500, 605.
  - Each level adds +0.02 to category 5 (all city income) and +0.1 gold/day before the soft cap.
  - The visual stall tier changes at levels 1, 2, 3, 5, 7 and 10 (6.20).

### 3.6 Twists (parametric)
A city (or contract, or event) declares `twists: [{ "type": <TwistType>, "params": {…} }]` with 0–2 entries. The engine has one handler per type implementing `profitMult(station, now, active)`, `tick(dt)`, `offline(window)`, `metric`, and a UI widget. All twists are **bonus-only**: nothing a twist does can lower income below the no-twist baseline. Each twist's first appearance has an unlock ceremony and a 2-step spotlight.

**1. `productionChain` — سلسلة إنتاج** (Hebron grapes → dibs, Amman milk → jameed → mansaf, Santiago wheat → empanada)
- Params: `inputStation`, `outputStation`, `ratio` (input units per output cycle-level, default 1), `outputMult` (default 3), `stockCapMin` (default 60).
- The input station earns no cash. It produces units at `P = level_in × profitMult_in × speedMult_in / baseCycle_in` (per second).
- The output station demands `D = level_out × speedMult_out / baseCycle_out × ratio`.
- Stock `s` lies in `[0, D × 60 × stockCapMin]`:
  - if `s > 0` or `P ≥ D`: σ = 1;
  - else: σ = P/D.
  - `ds/dt = P − σD`.
- Output profit multiplier = `1 + (outputMult − 1) × σ`.
- **Offline, closed form:** if `P ≥ D`, σ = 1 throughout. Otherwise σ = 1 until `t0 = s/(D − P)`, then P/D.
- Metric `chainUnits` (units consumed). UI: an animated pipe between the two cards, stock bar, and "ناقص {x}%" chip when σ < 1.
- Chains of three stations are two `productionChain` entries that share the middle station (its output becomes the next input).

**2. `ovenTiming` — توقيت الفرن** (Nablus knafeh, Baghdad samoon, Paris baguette, Tokyo tempura). Content rule: the station must be tier ≥ 2
- Params: `station`, `windowSec` (default 1.6), `perfectMult` (default 3), `minCycleSec` (default 2).
- When a cycle of `station` completes and `T_eff ≥ minCycleSec` and the app is in the foreground, the tray glows for `windowSec` before auto-collect.
- A tap inside the window pays the cycle × perfectMult ("مظبوطة!", T1). Otherwise it auto-collects at ×1 (managed) or waits (unmanaged).
- When `T_eff < minCycleSec`, the twist converts to a passive ×1.25 on that station.
- Offline ×1. Metric `ovenPerfects`.

**3. `busWaves` — باصات السيّاح** (Bethlehem, Damascus, Marrakesh, Istanbul, Athens)
- Params: `intervalMin` (default 20), `windowSec` (30), `waveMult` (4), `waveSec` (60), `stations` ([] = all).
- Buses arrive at `hh:mm` where `minute ≡ offset (mod intervalMin)`, with `offset = seed(cityId, gameDay) mod intervalMin`.
- If the app is in the foreground, a bus drives into the scene with the banner "باص سيّاح وصل!". Tapping "استقبل" within windowSec gives ×waveMult to the listed stations for waveSec (active category).
- Missed buses cost nothing. No offline effect. Metric `busesWelcomed`.

**4. `nightMarket` — سوق الليل** (Ramallah, Beirut, Marrakesh, New York, Rio)
- Params: `stations`, `startHour` (20), `endHour` (2), `nightMult` (3).
- Local device hour h in `[start, end)`, wrapping midnight → listed stations get ×nightMult (day category). This applies offline too: integrate the fraction of the window inside night hours.
- The scene switches to night lighting.
- Metric `nightEarnedBase` (cash earned while the multiplier was active ÷ S).

**5. `portShipments` — شحنات الميناء** (Jaffa oranges, Istanbul, Tokyo fish market)
- Params: `station`, `intervalHours` (4), `dockHours` (3), `targetMin` (30), `rewardMin` (90).
- A ship docks every intervalHours, aligned to local midnight + `seed(cityId, gameDay) mod intervalHours`. It stays dockHours.
- At docking: target units = `targetMin × 60 × (cycles/s of station at docking) × level`. While docked, each completed cycle of `station` adds `level` units to the crate. This does not divert revenue.
- When full: "حمّل الشحنة" pays `rewardMin` minutes of total city income (categories 1–10) and T1.
- If the ship leaves unfilled, nothing is lost and the crate resets.
- Works offline: units accrue from managed cycles, and a full crate auto-loads at 50% reward.
- Metric `shipmentsDelivered`.

**6. `deliveryRuns` — طلبات دليفري** (Haifa, Cairo, London, New York)
- Params: `intervalMin` (10), `tripMin` (6), `rewardMin` (8), `scooters` (2), `extraScooterCostsBase` ([F×1e-6, F×1e-4, F×1e-2]), `dispatcherCostBase` (F×1e-5).
- Orders appear every intervalMin while the app is open (queue max 5; 3 are pre-filled after returning from away). "ابعت" uses a free scooter. It returns after tripMin and pays `rewardMin` minutes of city income (T1).
- Extra scooters and the "موظّف دليفري" dispatcher are bought with city cash.
- With the dispatcher, orders auto-run offline at 50% reward, at most `window / intervalMin` orders.
- Metric `deliveriesDone`.

**7. `weatherSwing` — طقس متقلّب** (Gaza summer beach, Riyadh, Athens, London, Rio)
- Params: `hotProb` (0.45), `coldProb` (0.15), `rainProb` (0.10), `hotStations`, `coldStations`, `rainStations`, `mult` (2.5).
- Replaces the global weather probabilities for this city. Matching stations get ×mult instead of the global ×1.15 (day category, offline too).
- Metric `weatherEarnedBase`.

**8. `vipLounge` — صالة كبار الزوار** (Dubai, Paris, Santiago)
- Params: `loungeStation`, `specialIntervalMult` (0.5), `vipShare` (0.6), `vipTipMin` (20), `levelPerTier` (40).
- Special customers spawn at `interval × specialIntervalMult`. `vipShare` of them are VIPs with tier `v ∈ {1,2,3}` (weights 60/30/10).
- A VIP is served only if `level(loungeStation) ≥ v × levelPerTier`. Served pays `vipTipMin × v` minutes of income; otherwise the toast reads "صالة كبار الزوار بدها تكبر" with no loss.
- Metric `vipServed`.


---

## 4. Empire level (مستوى المعلّم)

### 4.1 XP sources (never from cash)
| Source | XP |
|---|---|
| City goal claimed | `10 × stars × (1 + 0.1 × (cityIndex − 1))`, rounded |
| Station milestone (first time, city) | 2 |
| Station unlocked (city) | 4 |
| Manager hired (city) | 2 |
| Graduation | `50 × cityIndex` |
| Daily order / daily bonus chest | 30 / 40 |
| Weekly order / weekly bonus | 120 / 150 |
| Calendar claim | 15 |
| Research level completed | `10 + 2 × level` |
| Supply run claimed | short 10 / mid 20 / long 40, × (1 + 0.25 × vehicleTier) |
| Contract goal 1 / 2 / 3 | `50 / 100 / 200 × gradeXpMult` (1, 1.2, 1.4, 1.6, 1.8) |
| Event milestone 1–9 / 10 | 30 / 100 |
| League week end | `50 + 10 × tier`; +50 if promoted |
| Achievement tier 1–5 | 20 / 40 / 80 / 150 / 250 |
| Special customer / choice event / rush round | 2 / 5 / 10 |
| Inspector visit | 20–60 (score × 4) |

### 4.2 Curve
- `xpToNext(L) = 5 × round(15 × L^1.36 / 5)`. Checkpoints:

| L | xpToNext | Cumulative XP to reach L | Expected (casual) |
|---|---|---|---|
| 2 | 40 | 15 | 1:45 min |
| 5 | 135 | 220 | end of session 1 |
| 8 | 255 | 735 | end of day 0 |
| 10 | 345 | 1,290 | day 2 |
| 12 | 440 | 2,025 | day 3 |
| 15 | 595 | 3,500 | day 5 |
| 17 | 705 | 4,745 | day 6–7 |
| 20 | 880 | 7,040 | day 10 |
| 25 | 1,195 | 12,065 | day 17 |
| 32 | 1,670 | 21,830 | day 30 |
| 40 | 2,265 | 37,240 | day 45 |
| 55 | 3,490 | 79,615 | day 90 |
| 75 | 5,325 | 166,505 | ~day 190 |
| 100 | — | 329,620 | ~1 year |

- **Beyond 100:** levels continue as "100+n" with a flat 8,000 XP each. Each gives 25 gold and a wood chest. The badge shows a gold "+" ring.
- **Multiple level-ups at once** merge into one T2 modal listing all rewards. Unlock ceremonies queue after it, one at a time.

### 4.3 Per-level rewards (every level gives something)
- **Gold:** L2–10: 10; L11–30: 15; L31–60: 20; L61–100: 25.
- **Chests:** every level ending in 5 gives a chest (wood below L40, silver L40–79, gold L80+). Every level ending in 0 gives a chest (silver below L50, gold from L50) plus a 1 h time warp.
- **L25, 50, 75, 100:** 3 legendary chef cards (random non-exclusive legendary).
- **Plus one unlock:** a system (4.4). If none, a cosmetic or a new street visitor type. The order is in Appendix H, generated by `design/tools/levels_table.py`. Levels with no system or cosmetic unlock give a `storyMemory` instead.

### 4.4 Feature unlock schedule
About one new system per day in week 1, then every few levels. Every unlock gets a T2 ceremony (S32) plus a one-time spotlight. Locked items appear as teasers (tab lock with "مستوى N", rail "?").

| L | Unlock | Expected (casual) |
|---|---|---|
| 1 | Kitchen: stations, tap-to-cook, buy modes; goals and stars (from FTUE step 7, not level-gated) | 0:00 |
| 2 | Managers | ~1:45 |
| 3 | Special customers, cash upgrades | ~7 min |
| 4 | Chefs and chests, Shop tab, chef slot 1 | ~12 min |
| 5 | Rush hours, vault explained (appointment) | ~20–25 min |
| 6 | Map and graduation (Bethlehem) | session 2, day 0 |
| 7 | دفتر ستّي (research, slot 1) | day 0 |
| 8 | Supply runs (slot 1), heritage box, chef slot 2 | day 0–1 |
| 9 | Daily orders, calendar, streak, Tasks tab | day 1–2 |
| 10 | Choice events, newspaper, supply slot 2 | day 2 |
| 11 | Rush minigame and tickets | day 2–3 |
| 12 | League | day 3 |
| 13 | Daily market and weather | day 3–4 |
| 14 | Contracts (slot 1); Za'atar pill | day 4 |
| 15 | Weekend venue, chef slot 3 | day 5 |
| 16 | Season pass, supply slot 3 | day 6 |
| 17 | Branch upgrades | day 7 |
| 18 | Inspector | day 8 |
| 19 | Heritage crafting | day 9 |
| 20 | Research slot 2, side grade 2 | day 10 |
| 22 | Chef active skills | day 13 |
| 24 | Time warps in shop | day 15 |
| 25 | Chef slot 4 | day 17 |
| 30 | Contract slot 2 | day 26 |
| 35 | Ticket cap 4, side grade 3 | day 36 |
| 40 | Chef slot 5 | day 45 |
| 45 | Streak freeze cap 3 | day 56 |
| 55 | Side grade 4 | day 90 |
| 60 | Chef slot 6 | ~day 110 |
| 70 | Research slot 3 | ~day 160 |
| 80 | Side grade 5 | ~day 230 |
| 90 | Supply slot 4 | ~day 300 |
| 100 | Title سلطان البسطات + golden stall skin | ~day 365 |

If a system unlocks while its content is not running (the weekend venue Mon–Wed), the ceremony shows the countdown: "المهرجان بيبلّش الخميس".

### 4.5 Titles (every 5 levels; shown under the badge and in league rows)
L1 بيّاع عالبسطة · L5 صاحب عربايّة · L10 معلّم فلافل · L15 صاحب كشك · L20 معلّم حمّص · L25 صاحب دكّانة · L30 طبّاخ الحارة · L35 مشهور بالبلد · L40 صاحب مطعم · L45 معلّم المعلّمين · L50 شيف المدينة · L55 صاحب فروع · L60 تاجر الشام · L65 نجم المطابخ · L70 ملك الصاج · L75 شيخ الطبّاخين · L80 سفير الفلافل · L85 أسطورة السوق · L90 إمبراطور الحمّص · L95 إمبراطور الفلافل · L100 سلطان البسطات.

---

## 5. Currencies and economy

### 5.1 Currencies and resources
| Name | Art | Scope | Earned from | Spent on | Cap | Lifetime |
|---|---|---|---|---|---|---|
| City cash (e.g. جنيه، دينار) | per city | one city | stations, specials, twists | levels, managers, upgrades, research cost, twist items | none | until graduation |
| Contract cash (كاش الطلبية) | `ui_money_bag` | one contract | contract kitchen | its levels/managers/upgrades | none | until the contract ends |
| Event cash | per theme | one event | event kitchen | its levels/managers/upgrades | none | until the event ends |
| **Gold (ذهب)** | `ui_coin` | global | fixed faucet (5.2) | 5.3 | none | forever |
| **Golden Za'atar (زعتر ذهبي)** | `food_herb` + gold ring | global | crowns, contract goal 2, calendar day 28 | nothing (×1.05 each, compounding, city income) | none | forever |
| Stars (★) | `ui_star` | per city + lifetime total | goals | nothing (graduation gate, XP) | — | forever (counted) |
| XP | `ui_sparkles` | global | 4.1 | nothing | — | forever |
| Event tokens | per theme | one event | milestones, event specials | event shop | none | converted at event end |
| Tickets (تذاكر) | `ui_admission_tickets` | global | +1 per 3 h, rewards | rush minigame | 3 (4 at L35); rewards may overflow to 9 | forever |
| Streak freezes (تجميدة) | `ui_snowflake` | global | streak milestones, weekly bonus, shop | auto on a missed day | 2 (3 at L45) | forever |
| Time warps (رزم وقت) | `ui_hourglass` | global inventory | rewards, shop | instant income | none | forever |
| Chef cards | chef portrait | per chef | chests, runs, rewards | chef level-ups | none | forever |
| Heritage items | item art | global | supply runs, contracts, rewards | set bonuses (levels) | — | forever |
| Craft points (حِرفة) | `ui_hammer_and_wrench` | global | salvaged max-level duplicates | crafting items | none | forever |
| Season points (نقاط الموسم) | `ui_ticket` | one season | 6.8 | tiers | — | per season |
| Reputation (سمعة) | `ui_sports_medal` | one league week | 6.7 | league rank | — | per week |

At most 3 currency pills are visible at once (1.6).

### 5.2 Gold faucet (fixed; never scales with cash)
Budget for a casual player (3 sessions, 35 min/day). The sim checks it with tolerance ±20%.

| Source | Amount | Casual gold/day, week 2–4 | Month 3 |
|---|---|---|---|
| Daily orders | 2 each × 3 | 6 | 6 |
| Daily bonus wood chest | 2–5 gold inside | 3.5 | 3.5 |
| Weekly orders + bonus silver chest | 10 each × 3; chest 8–20 | 6.3 | 6.3 |
| Calendar (Appendix J) | 120 per 28 days | 4.3 | 4.3 |
| Empire level-ups | 10–25 per level | 7 | 5 |
| Branch safe | 3.5 soft-capped | 6 | 14 |
| League week end | 15–120 by tier and rank | 4 | 6 |
| Contracts goal 1 | 10 × grade gold mult (1, 1.25, 1.5, 1.75, 2) | 4 | 5 |
| Season pass | 190 per 42 days (Appendix K) | 4.5 | 4.5 |
| Weekend event | 40 from milestones + ≤ 20 from token conversion | 5.7 | 7 |
| Achievements | 5/10/15/25/40 per tier | 2 | 0.5 |
| Inspector | 20/10/5 per visit | 2.5 | 2.5 |
| Supply-run gold drops | 2–10 | 2 | 3 |
| Streak milestones | Appendix J | 1.5 | 1 |
| **Total** | | **≈ 59** | **≈ 68** |

Week 1 runs at about 70/day because of one-off level-ups and achievements. Special customers, choice events and the rush minigame never pay gold. **Value anchor:** 1 gold ≈ 6 minutes of waiting.

### 5.3 Gold sinks and prices
| Sink | Price | Limits |
|---|---|---|
| Wood / silver / gold chest | 50 / 150 / 400 | none |
| Rush research | `ceil(remainingMin / 6)` (min 1) | — |
| Rush supply run | `ceil(remainingMin / 6)` | — |
| Time warp (L24) | 1 h = 10, 4 h = 36 | 3 purchases per game day |
| Rush ticket | 10 | 3 per game day |
| Streak freeze | 50 | up to cap |
| Order reroll | first free per day, then 5 | 3 per day |
| Vault "اجمع ×2" | `clamp(ceil(10 × window_h × eff), 5, 160)` | once per day |
| Chef level-up | L1→2 … L9→10: 5, 10, 20, 35, 50, 75, 100, 150, 200 (plus cards) | — |
| Branch upgrade | 20, 45, 80, 125, 180, 245, 320, 405, 500, 605 | L17 |
| بسطة الطبّاخين (daily chef offers) | 3 seeded offers per day: 10 common cards = 20; 5 rare = 40; 2 epic = 80; on Fridays slot 3 is 1 legendary card = 150 | each once per day |
| Cosmetics | 150–600 (cosmetics.json) | — |
| **Never for gold** | licences, goals, stars, Golden Za'atar, league placement | — |

### 5.4 Golden Za'atar (زعتر ذهبي)
- **Effect:** city income × `1.05^Z` (category 7).
- **Sources (only these three):**
  - city crown: 1 each, 24 total;
  - contract goal 2: 1, only the first time per contract id; otherwise 50 gold;
  - calendar day 28: 1 per cycle.
- **Expected totals:** day 30 ≈ 16, day 90 ≈ 47.
- **UI:** profile sheet "زعتر ذهبي: 16 (دخل ×2.18)". The pill appears from L14.

### 5.5 Event currency
- Each weekend theme defines event cash (kitchen money) and **tokens** (e.g. "فوانيس").
- Tokens come from milestones (10–60 each, 300 total) and event special customers (2–5 each).
- They are spent in the event shop (6.10).
- **Monday 04:00:** unspent tokens convert to gold at 1 gold per 5 tokens, max 20 gold. A T1 toast: "حوّلنا {t} فانوس لـ {g} ذهب".


---

## 6. Meta and live systems

### 6.1 Chefs and chests (الطبّاخين والصناديق), from L4

**Roster** (Appendix B): 30 chest chefs (12 common, 9 rare, 6 epic, 3 legendary), plus 3 exclusives: ستّي أم خليل (story reward on graduating Ramallah), أبو صبحي الأوّلاني (legacy gift), and one season-exclusive epic per season (season.json).

**Tags:**
- Every chef has one `cuisine`: palestinian, levantine, egyptian, gulf, iraqi, maghrebi, turkish or world.
- Every chef has one `category`: fried, grill, bakery, sweets, drinks, dishes, seafood or street.
- Every station has one cuisine and one category.
- The value `any` is allowed only on exclusive chefs.

**Matching and bonus:**
- A chef matches a station if the cuisine **or** the category matches.
- If both match, the bonus is ×1.5.
- `bonus(chef) = base[rarity] × (1 + 0.25 × (level − 1))`, with base common 0.25, rare 0.50, epic 1.00 and legendary 2.00.
- Station chef multiplier = `1 + Σ_matching bonus × matchFactor × (1 + 0.03·D5) × (1 + tatreezSet)` (category 3).
- Equipped chefs apply in every kitchen (city, contract, event).

**Equip slots:**

| Level | Slots |
|---|---|
| L4 | 1 |
| L8 | 2 |
| L15 | 3 |
| L25 | 4 |
| L40 | 5 |
| L60 | 6 |

Equipping is free. Swapping is free and instant. The kitchen shows "+x%" chips per station.

**Levels 1–10.** The first card unlocks the chef at level 1. Cards and gold needed to go from L to L+1:

| L→L+1 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|---|---|---|---|---|---|---|---|---|---|
| common cards | 2 | 4 | 8 | 15 | 25 | 40 | 60 | 90 | 130 |
| rare cards | 2 | 3 | 6 | 10 | 16 | 25 | 36 | 50 | 70 |
| epic cards | 1 | 2 | 4 | 6 | 9 | 13 | 18 | 24 | 32 |
| legendary cards | 1 | 1 | 2 | 3 | 4 | 6 | 8 | 10 | 13 |
| gold | 5 | 10 | 20 | 35 | 50 | 75 | 100 | 150 | 200 |

Cards beyond the total needed for L10 convert automatically on receipt to gold: common 1, rare 3, epic 8 and legendary 20 per card.

**Skills (L22, epic and legendary only).**
- Tap the chef's face in the action bar to activate.
- Each skill has `type`, `magnitude`, `durationSec` (active time) and `cooldownMin` (real time). Example: "نار الصاج", fried stations ×5 for 180 s, 45 min cooldown.
- Skill types:
  - `categoryBoost`: stations of category X ×m
  - `cuisineBoost`
  - `allBoost`
  - `instantIncome`: m minutes of income
  - `spawnSpecial`: a special customer now
  - `frenzy`: trigger a frenzy

**Chests:**

| Chest | Card stacks | Total cards | Gold | Rarity odds per stack (C/R/E/L) | Guarantee |
|---|---|---|---|---|---|
| Wood (صندوق خشب) `ui_gift` with a wood frame | 3 | 8 | 2–5 | 80 / 18 / 2 / 0 | — |
| Silver (صندوق فضّة) | 4 | 20 | 8–20 | 62 / 30 / 7.5 / 0.5 | ≥ 1 rare stack |
| Gold (صندوق ذهب) | 5 | 45 | 25–50 | 45 / 37 / 15 / 3 | ≥ 1 epic stack |

- **Stack sizes:** weights common 1.0, rare 0.5, epic 0.2, legendary 0.08. `cards_s = max(1, round(total × w_s/Σw))`. Adjust the largest common stack so the sum equals the total.
- **Chef pick within a rarity:** if unowned chefs exist, 35% of stacks pick an unowned chef. Otherwise pick uniformly from chefs of that rarity that are not yet at L10.
- **Pity:**
  - A legendary is guaranteed in the next silver/gold chest after 12 consecutive silver/gold chests without one.
  - An epic is guaranteed in a silver chest after 5 silvers without one.
  - Counters are stored in the save.
- **Sources:** daily bonus (wood), weekly bonus (silver), level-ups, calendar, supply runs (wood on mid/long), contract goal 1, event milestones, season pass, league, story, shop.
- **Inventory:** chests are stored and opened from the Chefs tab. A red dot shows while any is unopened.

**4-beat reveal (S11):**
1. **Build-up, 0.9 s.** The chest shakes 3 times with rising pitch. In the last 0.3 s the glow takes the colour of the best rarity inside.
2. **Burst.** 80 ms freeze, flash, 80 sparks, the lid flies off.
3. **Cascade.** Each stack 260 ms apart. Card flip (`rotation3DEffect`): 0.35 s common, 0.5 rare, 0.65 epic, 0.8 legendary. A legendary adds rays and T3.
4. **Collect.** "خذ": cards fly to the Chefs tab icon and gold to the pill.

A tap skips the current beat. "تخطّي الكل" appears after the player has seen 3 reveals.

### 6.2 Research: دفتر ستّي, from L7
- **Slots:** 1 (L7), 2 (L20), 3 (L70).
- **Starting a level:**
  - Costs current-city cash: `cost = max(incomePerSec × 60 × m, F_k × S_k × 1e−6 × m)`, where `m = costMin × level` and `incomePerSec` is categories 1–10 of the current city.
  - Takes `dur(L) = min(24 h, 10 min × timeMult × 1.5^(L−1)) × (1 − 0.02·C4) × (1 − oliveWoodSet)`.
- **Completion:** the effect applies immediately, so it counts offline too. The rail shows a red dot, and the claim gives XP and a T1.
- **Rush:** `ceil(remainingMin/6)` gold.
- **Market:** "researchSale" (cost −50%) and "researchFast" (−25% duration for levels started that day).

| id | Name | Branch | Effect per level | Max | Unlock | timeMult | costMin |
|---|---|---|---|---|---|---|---|
| secretBlend | خلطة ستّي | المطبخ | city income +5% (cat 6) | 40 | L7 | 1.0 | 4 |
| loyalManagers | معلّمين أوفياء | المطبخ | manager cost −5% | 10 | L7 | 0.5 | 2 |
| honestSupplier | مورّد أمين | المطبخ | station level cost −2% | 15 | L12 | 1.0 | 3 |
| gentleFire | نار هادية | المطبخ | all station speed +2% | 30 | L20 | 1.5 | 4 |
| happyCustomer | زبون مبسوط | الزباين | special customer rewards +10% | 10 | L7 | 0.8 | 2 |
| longerRush | عجقة أطول | الزباين | frenzy +6 s | 10 | L10 | 0.8 | 2 |
| peakHour | ساعة الذروة | الزباين | rush hour mult +0.1 | 10 | L12 | 1.0 | 3 |
| sweetTalk | كلمة حلوة | الزباين | choice, inspector, VIP, delivery and port rewards +10% | 10 | L14 | 1.0 | 3 |
| biggerVault | خزنة أكبر | الخزنة والوقت | vault cap +1 h | 9 | L7 | 0.6 | 3 |
| tightHarvest | ضبّ الغلّة | الخزنة والوقت | vault efficiency +5% | 10 | L8 | 0.8 | 3 |
| shortcuts | طرق مختصرة | الخزنة والوقت | supply-run time −3% | 10 | L10 | 1.0 | 2 |
| tidyNotebook | دفتر مرتّب | الخزنة والوقت | research time −2% | 15 | L16 | 1.2 | 3 |
| smartBranches | فروع شاطرة | الإمبراطورية | branch gold +10% | 10 | L17 | 1.0 | 3 |
| branchSafe | خزنة الفروع | الإمبراطورية | branch safe cap +1 h | 8 | L17 | 0.8 | 2 |
| cateringCrew | شغل طلبيات | الإمبراطورية | contract kitchen income +15% | 30 | L14 | 1.2 | 3 |
| festivalSpirit | روح المهرجان | الإمبراطورية | event kitchen income +15% | 30 | L15 | 1.2 | 3 |
| cookingSchool | مدرسة الطبخ | الإمبراطورية | chef bonuses +3% | 30 | L20 | 1.5 | 4 |
| strongStart | بداية قوية | الإمبراطورية | new kitchens start with stations 0…L−1 at level 10 | 5 | L25 | 4.0 | 5 |
| expertEye | عين خبيرة | الإمبراطورية | each supply roll +4% chance to upgrade rarity one step | 10 | L22 | 1.0 | 3 |

The total research content is 302 levels and about 3,080 slot-hours (128 slot-days; `design/tools`). With slots 2 and 3, a player who keeps research running finishes in about 3–4 months. The FTUE's first research is `biggerVault` level 1 (6 minutes).

### 6.3 Supply runs (رحلات التوريد) and heritage (صندوق التراث), from L8
- **Slots:** L8 1, L10 2, L16 3, L90 4.
- **Sending:** free. Pick a vehicle and one of its 3 durations.
- **Return:** the claim reveal plays T1 (T2 if epic or better).
- **Rush:** `ceil(remainingMin/6)` gold.
- **Duration** = base × `(1 − 0.03·C3) × (1 − potterySet)` × market "supplyFast" 0.75.

| id | Vehicle | Art | Unlock | Durations (min) | Rolls short / mid / long | Rarity weights C/R/E/L |
|---|---|---|---|---|---|---|
| tractor | تراكتور أبو سليم | `veh_tractor` | L8 | 20 / 60 / 120 | 2 / 3 / 4 | 75 / 22 / 3 / 0 |
| pickup | البكم | `veh_pickup_truck` | L10 and 4 tractor launches | 30 / 90 / 180 | 3 / 4 / 6 | 68 / 26 / 5.5 / 0.5 |
| van | الفان | `veh_minibus` | L13 and 6 pickup launches | 90 / 240 / 480 | 4 / 6 / 9 | 60 / 30 / 8.5 / 1.5 |
| lorry | الشاحنة | `veh_lorry` | L18 and 10 van launches | 240 / 480 / 720 | 6 / 9 / 12 | 52 / 33 / 12 / 3 |
| ship | سفينة يافا | `veh_ship` | L26 and 15 lorry launches | 720 / 1440 / 2160 | 9 / 13 / 18 | 45 / 35 / 15 / 5 |
| plane | الطيّارة | `veh_airplane` | L36 and 20 ship launches | 1440 / 2880 / 4320 | 12 / 18 / 26 | 38 / 36 / 18 / 8 |

The INPUTS ladder starts with a donkey cart, but the art set has no donkey, so tier 1 is a village tractor. If a donkey key is added later, the vehicle can be swapped through data.

- **Vehicle stars:** ★1 at 4 launches, ★2 at 10, ★3 at 25. Each star adds `ceil(15% × rolls)` rolls. ★3 also shifts 2 points from common to epic.
- **Each roll:**
  1. Rarity from the weights, with the `expertEye` upgrade chance.
  2. Kind: heritage item 70%, chef cards 20% (common 3 / rare 2 / epic 1 / legendary 1 card), gold 7% (2 / 4 / 7 / 10 by rarity), wood chest 3% (mid and long runs only; otherwise a heritage item).
  3. A heritage item of that rarity is uniform among items of that rarity, weighted ×2 toward items the player owns 0 copies of.
- **Market:** "supplyDouble" doubles rolls for runs **sent** that day.

**Heritage collection** (Appendix G): 8 sets × 4 items = 32 items.
- **Item level** 1–5: copies to go up are 2, 3, 4, 5 (15 copies to L5).
- **Set bonus:** active once all 4 items are owned. Strength = `base × (1 + 0.5 × (minLevel − 1))`, so ×3 at L5.

| Set | Base bonus |
|---|---|
| زجاج الخليل | city income +10% (cat 8) |
| صابون نابلس | vault cap +1 h |
| تطريز فلّاحي | chef bonuses +10% |
| صدف بيت لحم | special customer and happening rewards +20% |
| فخّار غزّة | supply-run time −5% |
| خشب الزيتون | research time −5% |
| نحاس وقهوة | side-kitchen income +15% |
| صندوق الذكريات | branch gold +15% |

- **Crafting (L19):**
  - Copies beyond L5 become craft points: common 1, rare 3, epic 8, legendary 20.
  - Crafting one copy of any chosen item costs 10, 30, 80 or 200 points.
  - This guarantees that no set is ever blocked by bad luck.
- **Heritage case (صندوق تراث):** 3 rolls with a rarity floor of rare.

### 6.4 Calendar (الروزنامة) and streak (السلسلة), from L9
**Calendar:**
- A 28-day track (Appendix J). One claim per game day. A missed day **pauses** the track, so nothing is lost.
- After day 28 a new cycle begins. Gold amounts scale by `1 + 0.1 × (cycle − 1)` (max ×2). Day 28 always pays 1 Golden Za'atar.
- Claim plays T1 (day 28 plays T2). The red dot shows until claimed.

**Streak:**
- The flame counts consecutive game days with at least one daily order completed.
- **Rollover without an order:**
  - If the player holds a freeze, it is used automatically. The flame turns icy for that day and the streak is kept.
  - Otherwise the streak breaks and a **repair quest** opens: "رجّع السلسلة: خلّص 6 طلبات يومية خلال يومين" (counter 0/6 over the next 2 game days). Success restores the old streak + 2.
- **Freezes:**
  - Cap 2 (3 from L45).
  - Earned at streak milestones 7 and 14, 1 from each weekly bonus (if under the cap), or bought for 50 gold.
- **Milestones** (Appendix J): 3, 7, 14, 30, 50, 100, 200, 365.

### 6.5 Daily and weekly orders (طلبات اليوم/الأسبوع), from L9
**Daily:**
- Three orders are generated at rollover (one easy, one medium, one hard) from eligible templates. Seed: `hash("orders", gameDay, playerSeed)`.
- Each order pays 2 gold, 30 XP, 10 season points and 20 rep.
- All 3 done → bonus wood chest + 40 XP + 20 SP + 30 rep (T2).

**Weekly:**
- Three orders generated Monday 04:00. Each pays 10 gold, 120 XP, 40 SP and 60 rep.
- Bonus: silver chest + 150 XP + 50 SP + 1 freeze (if under the cap).

**Reroll** (per order card): the first reroll of the day is free, then 5 gold, max 3 per day. It replaces the order with another eligible template of the same difficulty.

**Bands by empire level:** B1 L9–14, B2 L15–24, B3 L25–39, B4 L40–59, B5 L60+.

Daily templates (quests.json). Target listed per band B1/B2/B3/B4/B5:

| id | Text (m) | Metric | Targets | Diff | Eligible when |
|---|---|---|---|---|---|
| buyLevels | اشتري {n} مستوى بالمحطّات | levels bought | 40/80/150/250/400 | med | always |
| claimGoals | خلّص {n} أهداف بالمدينة | city goals claimed | 1/2/2/3/3 | hard | ≥ n unclaimed goals left |
| specials | استقبل {n} زباين مميّزين | special customers | 2/3/4/5/6 | easy | L3 |
| rushRounds | العب {n} جولة طلبيات على السريع | rounds | 1/1/2/2/3 | med | L11 |
| choices | جاوب على {n} حكاية | choice events | 1/1/2/2/2 | med | L10 |
| sendRuns | ابعت {n} رحلة توريد | runs sent | 1/2/2/3/3 | easy | L8 |
| returnRuns | استلم {n} رحلة | runs claimed | 1/2/2/3/3 | med | L8 |
| startResearch | ابدأ {n} بحث بدفتر ستّي | research started | 1/1/1/2/2 | easy | L7, a slot is free or frees up today |
| earnMinutes | اربح قدّ {n} دقيقة شغل | city cash vs income snapshot | 20/30/45/60/90 | hard | always |
| milestones | وصّل {n} محطّات لعلامة جديدة | station milestones | 2/3/3/4/5 | med | any station below cap |
| vault | ارجع واجمع الخزنة | vault collects ≥ 30 min | 1 | easy | always |
| branches | اجمع ذهب الفروع | branch collects | 1 | easy | L17 |
| contractPush | كمّل {n}% من هدف الطلبية الجاي | % of next goal | 10/10/15/15/20 | hard | active contract |
| eventPush | وصّل مرحلة جديدة بالمهرجان | event milestones | 1 | med | event live |
| tapCook | اطبخ {n} مرّة بإيدك | tap-cooks | 30 | easy | unmanaged station exists |
| openChest | افتح صندوق | chests opened | 1 | easy | chest in inventory |
| leagueRep | اجمع {n} سمعة اليوم | rep | 100/150/200/250/300 | hard | L12 |
| buyUpgrade | اشتري ترقية | cash upgrades | 1 | hard | next upgrade ≤ 30 min of income |

Weekly templates:

| id | Text | Target |
|---|---|---|
| wDaily | خلّص 15 طلب يومي | 15 |
| wStars | اجمع 20 نجمة | 20 (10 if fewer remain) |
| wContract | وصّل 3 أهداف طلبيات | 3 (L14) |
| wEvent | وصّل 6 مراحل بالمهرجان | 6 (L15) |
| wRuns | استلم 15 رحلة توريد | 15 |
| wResearch | خلّص 4 أبحاث | 4 |
| wSpecials | استقبل 25 زبون مميّز | 25 |
| wRush | العب 6 جولات على السريع | 6 (L11) |
| wRep | اجمع 1,500 سمعة | 1500 (L12) |
| wChoices | جاوب على 8 حكايات | 8 |
| wCalendar | استلم الروزنامة 5 أيام | 5 |
| wChef | رقّي أي طبّاخ مرّة | 1 (if any chef is upgradable) |

### 6.6 Daily market (سوق اليوم) and weather (الطقس), from L13
- **Rollover:** roll the day's market modifiers with seed `hash("market", gameDay, playerSeed)`.
  - Saturday–Thursday: 1 modifier. Friday: 2 (فرحة الجمعة).
  - Pool and weights in Appendix F. Each modifier has a 5-day cooldown and lasts the whole game day.
  - The card in the Today tab and the top-bar weather icon show them.
- **Weather** (global unless a `weatherSwing` city overrides it):

| Season | Sunny | Hot | Cold | Rainy |
|---|---|---|---|---|
| Jun–Aug | 55 | 40 | 0 | 5 |
| Dec–Feb | 40 | 0 | 40 | 20 |
| Otherwise | 55 | 17.5 | 17.5 | 10 |

- **Effects:**
  - Hot: stations with `weather: "cold"` (iced items) ×1.15.
  - Cold: stations with `weather: "hot"` ×1.15.
  - Rainy: delivery twist rewards ×1.5 and the special customer interval ×0.8.
  - Weather effects are day category, so they also apply offline.
- **Visuals:** sky tint, rain particles (reduced by Reduce Motion), and a sun or cloud icon (`ui_sun`, `ui_snowflake`, `ui_cloud_with_rain`, `ui_sun_behind_cloud`).


### 6.7 League (الدوري), from L12
- **Week:** Monday 04:00 → Monday 04:00. A player who unlocks mid-week joins at once in tier 1 for a "أسبوع تجريبي". NPC finals are scaled by the remaining week fraction, and promotion is guaranteed (q = 0.35).
- **Group:** 30 rows, the player plus 29 openly fictional NPC chains. Names, avatars and archetypes come from league.json (≥ 120 names, Appendix L), picked with `hash("league", weekId, tier, playerSeed)`. Rows show "مطعم وهمي" in the info sheet.
- **Score:** reputation (سمعة) earned during the week. Never cash.

| Source | Rep |
|---|---|
| Daily order / daily bonus | 20 / 30 |
| Weekly order / weekly bonus | 60 / 100 |
| City goal | 8 per star |
| Contract goal 1/2/3 | 25 / 40 / 60 |
| Event milestone 1–9 / 10 | 10 / 40 |
| Special customer / choice event | 2 / 5 |
| Rush round | `10 + ⌊score/500⌋` |
| Supply run claimed / research level | 5 / 5 |
| Inspector | 2 × score |
| Calendar claim | 10 |
| Graduation | 100 |

A casual week totals about 1,700–2,000 rep.

- **Tiers:**

| Tier | Name | Promote top | Demote bottom |
|---|---|---|---|
| 1 | بسطة | 15 | 0 |
| 2 | عربايّة | 12 | 5 |
| 3 | كشك | 10 | 5 |
| 4 | دكّانة | 8 | 5 |
| 5 | مطعم | 7 | 5 |
| 6 | مطعم مشهور | 6 | 5 |
| 7 | سلسلة مطاعم | 5 | 5 |
| 8 | ماركة بالبلد | 5 | 5 |
| 9 | أسطورة | 4 | 5 |
| 10 | سلطان الفلافل | 0 | 5 |

- **NPC model (deterministic, rubber-banded):**
  1. Baseline `B` = mean of the player's final scores over the last 2 completed weeks (1 week → that value; none → 1,400).
  2. Promotion line `Lp = B × q[tier]`, with q = [0.45, 0.75, 0.90, 1.00, 1.05, 1.10, 1.15, 1.20, 1.25, 1.30].
  3. Draw 29 seeded standard normals `z`, sort them descending, and let `p = promoteCount − 1` (for tier 10, p = 4).
  4. NPC finals: `f_i = Lp × exp(0.45 × (z_i − z_p))`. The p-th NPC sits exactly on the line, so a player who beats `Lp` is promoted.
  5. Each NPC has an archetype curve `c(x)` over week fraction x ∈ [0,1]:

| Archetype | Weight | c(x) |
|---|---|---|
| steady | 40% | x |
| earlyBird | 15% | min(1, 1.6x)^0.8 |
| weekendBurst | 20% | x < 0.43 ? 0.6x : 0.258 + 0.742 × (x − 0.43)/0.57 |
| closer | 15% | x² |
| sprinter | 10% | 1 − (1 − x)² |

  6. Shown score = `round(f_i × c(x) × (1 + 0.03 × noiseDay))`, kept monotonic. NPCs never react to the player during the week.
- **Week end:**
  - Ranks are computed, promotions and demotions applied, rewards granted, and the result modal plays (T2 on promotion).
  - A player with **0 rep** all week is held in the same tier, never demoted.
- **Rewards** (gold + chest, by tier T and rank):

| Rank | Reward |
|---|---|
| 1 | `30 + 10T` gold + silver chest (gold chest from T6) |
| 2–3 | `20 + 8T` + wood chest (silver from T6) |
| 4–10 | `15 + 5T` |
| 11–20 | `10 + 2T` |
| 21–30 | 5 |

A promotion adds a wood chest.

### 6.8 Season pass (الموسم), free, from L16
- **Length:** 42 days. Season `n = ⌊(gameDay − epoch)/42⌋`, epoch = Monday 2026-01-05 (04:00 local).
- **Tiers:** 50 tiers at 140 points each (7,000 total). After tier 50, every 300 points gives a bonus wood chest (max 10 per season).
- **Late joiner:** if the player's first season has fewer than 42 days left, points are multiplied by `min(2, 42/daysLeft)`.
- **Theme:** `themes[n mod count]` (season.json). Each season adds 1 exclusive epic chef (card at tier 10, the full unlock at tier 25, more cards at 35 and 45), 1 cosmetic set and 1 rule twist for that season's weekend venues (e.g. olive season: `productionChain` olives → oil).
- **Points:**

| Source | Points |
|---|---|
| Daily order / daily bonus | 10 / 20 |
| Weekly order / weekly bonus | 40 / 50 |
| Calendar claim | 10 |
| City goal | 2 per star |
| Contract goal 1/2/3 | 20 / 30 / 50 |
| Event milestone | 15 |
| League week end | 30 (+30 promoted) |
| Research level / supply run claimed | 5 / 5 (runs max 25/day) |
| Rush round | 5 (max 15/day) |
| Special customer | 1 (max 10/day) |

A casual player earns about 190 points a day, so tier 50 lands around day 37. A 20-minute player reaches about tier 45.

- **Rewards:** Appendix K.
- **Season end:** reached but unclaimed tiers are auto-claimed into the newspaper. Points reset.

### 6.9 Catering contracts (الطلبيات), from L14
- **Library:** 24 contracts at launch (Appendix C). Each has 3–5 themed stations (side tiers), `durationHours` (48–120), 3 goal targets in base units, 2–4 NPC partners, optional rule and twist, and rewards.
- **Schedule:**
  - Releases at Monday, Wednesday and Friday 04:00. Release index `r = weeks since epoch`.
  - Monday: "جديد" = `library[r mod count]` in `releaseOrder`.
  - Wednesday and Friday: "إعادة", 2 seeded picks (`hash("contract", weekId, slot, playerSeed)`) from contracts with `releaseOrder < r mod count`, excluding the last 3 weeks' picks.
  - Each release can be started within 7 days of release. The board shows at most 3.
- **Slots:** 1 (L14), 2 (L30). Starting freezes the grade.
- **Grade by empire level:**

| Grade | Name | Levels | Target factor | Gold mult | XP mult | Goal 1 chest |
|---|---|---|---|---|---|---|
| 1 | سهل | L < 20 | 1 | 1 | 1 | wood |
| 2 | متوسط | L20–34 | 4 | 1.25 | 1.2 | wood |
| 3 | صعب | L35–54 | 15 | 1.5 | 1.4 | silver |
| 4 | صعب كتير | L55–79 | 60 | 1.75 | 1.6 | silver |
| 5 | أسطوري | L80+ | 250 | 2 | 1.8 | gold |

- **Goals:** `delivered = contract lifetimeEarned + Σ partner contributions`.
  - Goal i reached when `delivered ≥ target_i × gradeFactor`.
  - **Authoring rule:** `g3 = 0.55 × Lcasual(stations, durationHours)`, `g2 = 0.05 × g3`, `g1 = 0.002 × g3`.
  - `Lcasual` (side sim, M = 1):

| Stations | 48 h | 72 h | 96 h | 120 h |
|---|---|---|---|---|
| 3 | 2.9e12 | 7.9e12 | 1.3e13 | 1.9e13 |
| 4 | 5.0e12 | 1.1e13 | 1.8e13 | 2.6e13 |
| 5 | 3.7e12 | 8.6e12 | 2.9e13 | 5.3e13 |

- **Partners:** each partner p has `share_p` ∈ [0.10, 0.25] (Σ ≤ 0.6) and `gamma_p` ∈ {0.7, 1.0, 1.5}. Contribution at elapsed t: `share_p × g3 × gradeFactor × (t/T)^gamma_p`. The goal bar stacks partner colours under the player's.
- **Rewards:**

| Goal | Reward |
|---|---|
| 1 | `10 × goldMult` gold + chest (above) + XP + SP + rep |
| 2 | 1 Golden Za'atar the first time this contract id reaches goal 2; otherwise 50 gold |
| 3 | authored: heritage case, or 3 epic cards of a named chef, or 1 legendary card |

- **End:**
  - Reaching goal 3 ends the contract at once (T2).
  - At the deadline, the results modal auto-claims reached goals and the kitchen is discarded.
  - Offline accrual goes through the vault.
- **Rules** (`contractRule`; about 30% of contracts):

| Rule | Effect |
|---|---|
| `noManagers` | tap-to-cook only; always 48 h; targets authored ×0.3 |
| `noUpgrades` | cash upgrades hidden |
| `chefsOff` | chef bonuses disabled |
| `fastCheap` | cycles ×0.5, costs ×0.5 |
| `goldenHour` | a frenzy at the top of every hour while open |
| `oneStation` | the kitchen has exactly 1 station; targets ×0.05 |

Any city twist may also be declared in `twists`.

### 6.10 Weekend venue (مهرجان الويكند), from L15
- **When:** Thursday 04:00 → Monday 04:00 (96 h). Mon–Wed the right rail shows the next theme with a countdown.
- **Theme:** `rotation[weekIndex mod 12]`, overridden by festival preference (Ramadan → ramadanNights, Eid al-Fitr → eidSweets, Eid al-Adha → eidFeast, olive season → oliveHarvest, Christmas window → bethlehemChristmas, Jul–Aug → summerBeach). Never the same theme twice in a row (if equal, take the next).
- **Kitchen:**
  - 4 stations (side tiers 0–3). The 4th unlocks at milestone 3.
  - Event cash named by theme; tokens named by theme.
  - Optional twist from the theme or the season.
  - Grade factor as for contracts (by empire level at event start).
- **Milestones** (lifetime event cash ≥ base × gradeFactor):

| # | Base | Reward |
|---|---|---|
| 1 | 1e4 | 20 tokens |
| 2 | 1e6 | 20 tokens + 5 gold |
| 3 | 1e8 | 30 tokens + 4th station + wood chest |
| 4 | 3e9 | 30 tokens + 5 gold |
| 5 | 5e10 | 40 tokens + 3 rare cards (theme chef) |
| 6 | 3e11 | 40 tokens + 10 gold |
| 7 | 1e12 | 40 tokens + silver chest |
| 8 | 3e12 | 30 tokens + 10 gold + heritage case |
| 9 | 8e12 | 30 tokens + 10 gold |
| 10 | 1.5e13 | 20 tokens + gold chest + theme frame (cosmetic) |

Totals: 300 tokens and 40 gold. A casual player without event research reaches about milestone 8–9. Research and chefs make milestone 10 routine over the months.

- **Event specials:** in the venue, special customer outcomes "collector", "visitingChef" and "critic" are replaced by 2–5 tokens.
- **Ranking:**
  - 20 NPCs. `E` = log-mean of the player's last 2 event finals (default = milestone-8 threshold × gradeFactor).
  - NPC finals `E × exp(0.6 z_i)`, using the league archetype curves.
  - Rank rewards at the end: 1 → gold chest + "بطل المهرجان" frame; 2–3 → silver chest; 4–10 → wood chest; 11–21 → 3 rare cards.
- **Event shop** (tokens; open until Monday 04:00):

| Item | Price | Max |
|---|---|---|
| 3 rare cards (theme chef) | 40 | 5 |
| 1 epic card (theme chef) | 60 | 3 |
| 1 h time warp | 30 | 3 |
| Wood chest | 50 | 2 |
| Heritage case | 120 | 1 |
| Theme decoration | 150 | 1 |
| Ticket | 15 | 3 |

- **Conversion** at Monday 04:00: leftover tokens → gold at 1 per 5, max 20.

### 6.11 Real-calendar festivals (المواسم والأعياد)
- **Hijri dates:** `Calendar(identifier: .islamicUmmAlQura)` on the game day. Windows are recomputed on every rollover. Festivals may overlap, and their day effects stack within the day cap (×5).
- **Moon-sighting tolerance:** Eid windows run one extra day at the end, and decorations appear on the eve (day −1).

| id | Name | Window | Effects |
|---|---|---|---|
| ramadan | رمضان | Hijri 9/1 – 9/30 (eve decorations 8/30) | Iftar hour ×5 active, from computed sunset −10 min to +80 min (replaces the dinner rush hour). Suhoor 02:00–04:30 ×2 active. Daily فانوس collectible (claim in Today: 30 lanterns; 10 → silver chest, 20 → 30 gold, 30 → exclusive "فوانيس رمضان" decoration). Ramadan choice events enabled. Weekend theme ramadanNights. Notifications 6.15. **No daytime penalty.** |
| eidFitr | عيد الفطر | Hijri 10/1 – 10/3 (+1) | All income ×1.5 (day). Daily "عيدية" 15 gold + wood chest. Ka'ak/ma'amoul decorations. Theme eidSweets. |
| eidAdha | عيد الأضحى | Hijri 12/10 – 12/13 (+1) | Same as Eid al-Fitr; theme eidFeast. |
| oliveHarvest | موسم الزيتون | Oct 15 – Nov 30 | Palestinian-cuisine stations ×1.25 (day). Mid/long supply runs +1 roll from the خشب الزيتون set. Theme oliveHarvest. |
| summer | الصيفية | Jul 1 – Aug 31 | `weather: cold` stations ×1.25 (day). Theme summerBeach. |
| backToSchool | رجعة المدارس | Sep 1 – Sep 10 | School choice events. Special customer "طالب" art. Daily bonus chest +2 gold. |
| bethlehemChristmas | ميلاد بيت لحم | Dec 20 – Jan 7 | `weather: hot` stations ×1.25 (day). Star/lights decorations. Theme bethlehemChristmas. |
| mothersDay | عيد الأم | Mar 21 | Story scene with ستّي. 1 legendary card of ستّي if owned, else 30 gold. |

- **Sunset:** NOAA approximation at the reference point (31.78°N, 35.23°E), converted to device local time. ±10 min is acceptable.
- **Settings "زينة المواسم":** when off, festival visuals, themed names and festival happenings are hidden. Numeric effects remain under the neutral name "أيام البركة", so nobody loses rewards.
- **Quiet dates** (festivals.json `quietDates`, launch: `05-15`): no festival visuals, no `festive` market modifiers, and no festive promos. Player-achievement celebrations still play.

### 6.12 Happening engine
One engine evaluates data rows (happenings.json, market.json). It is a pure function plus a scheduler:
```
eligible(row, ctx) -> Bool     // conditions: level, city, kitchen kind, festival, hour, weekday, weather, system unlocked, FTUE done, karma
schedule(kind, ctx, rng) -> Row?
present(row) -> UI request (scene | banner | modal | news)
resolve(row, choiceIndex, rng) -> [Effect]
apply(effects)                 // the only place rewards are granted
```
- **Effects (shared enum, SCHEMA):** incomeMult (day/active, scope, duration), instantIncomeMin, gold, xp, rep, seasonPoints, chest, chefCards, heritage, tickets, timeWarpMin, eventTokens, frenzy, spawnSpecial, karma, setFlag, storyScene.
- **Determinism:** every roll uses `hash(kind, rowId, gameDay, counter, playerSeed)`. Re-opening never re-rolls.
- **Queue:** one modal happening at a time; queue max 3 (oldest dropped). In-scene specials never queue.

**Special customer (زبون مميّز), from L3:**
- **Spawns only** while the app is in the foreground and a kitchen screen is visible, not during FTUE steps before 10, and not while a modal is open.
- **Timing:** `t` = active seconds since the last special despawned. Each second with `t ≥ 300` (×0.5 with `vipLounge`, ×0.8 if rainy) spawns with probability `((t − 300)/600)^5`. Forced at `t ≥ 900`. The mean gap is about 12 min.
- **On screen:** 15 s with a ring timer. It leaves quietly if not tapped, and that counts as nothing.
- **Outcomes** (weights; rewards × (1 + 0.1·B1) × (1 + pearlSet)):

| Outcome | Weight | Effect |
|---|---|---|
| زبون كريم (tip) | 55 | `max(2 min income, min(0.15 × cash, 15 min income))` |
| عجقة زباين (frenzy) | 25 | ×5 for 60 s + 6 s·B2 (T2) |
| ناقد طعام (critic) | 8 | ×2 for 5 min + 15 rep |
| باص رحلة (bus) | 7 | 10 min of income |
| جامع تراث (collector) | 3 | 1 heritage item (C 80 / R 20); tip before L8 |
| طبّاخ زائر (visiting chef) | 2 | 3 chef cards (C 70 / R 30); tip before L4 |

- **Art:** a random customer from the city's customer list, with a gold aura and the outcome icon above (`ui_money_bag`, `ui_fire`, `ui_memo`, `veh_bus`, `ui_old_key`, `ppl_cook`).

**Choice events (حكايات الحارة), from L10** (Appendix E, 40 rows):
- **Spawns while** the app is in the foreground on a kitchen screen, after 10 min of lifetime play.
- **Timing:** the next one comes after `U(180, 360)` active seconds since the last. Max 4 per game day. Each row has a 7-day cooldown and a weight.
- **Dismiss (X):** no effect, and it does not count toward the cap.
- **Outcomes:** never net-negative.
  - A risky option ("حظّ") has expected value ≥ 1.5× the safe option.
  - Its bad branch still pays a consolation (rep, karma, a common heritage item).
  - A karma counter (int) unlocks warm follow-ups.

**Offline newspaper (جريدة الحارة):** on resume after ≥ 60 min away, the newspaper lists:
- the vault;
- up to 2 offline happenings (rows with `offline.allowed`, resolved with `offline.autoChoice`, positive only; max 3 per day);
- system news: runs back, research done, partner progress, league rank change, event rank, licence ready, branch safe full, season tiers reached.

**Rush hours:** 12:00–14:00 and 19:00–22:00 local. Active ×2 (+0.1·B3). The banner "ساعة الذروة! الدخل دبل" shows if open at the start. In Ramadan the dinner window becomes the iftar hour.

**Inspector (مفتّش البلدية), from L18:**
- **Schedule:** next visit = last + triangular(4, 6, 8) days (seeded), at a seeded hour 10–20.
- **Warning:** banner and rail countdown 12 h before.
- **Visit:** happens at the first foreground moment after the scheduled time on that game day. If the day passes, it moves to the next day. Never a penalty.
- **Score:** six checks, each worth 0 / 1.5 / 2.5:

| Check | 2.5 | 1.5 |
|---|---|---|
| معلّمين | all stations managed | ≥ 75% |
| طبّاخين | all chef slots filled | ≥ 1 |
| شكل البسطة | stall tier ≥ 5 | ≥ 3 |
| الزباين | ≥ 3 specials in the last 24 h | ≥ 1 |
| الخزنة | vault collected in the last 12 h | in the last 24 h |
| التنويع | all stations unlocked | ≥ 75% |

- **Rewards** (× (1 + 0.1·B4)):

| Score | Reward |
|---|---|
| ≥ 12 | 20 gold + "شهادة نظافة" certificate |
| 8–11.5 | 10 gold |
| < 8 | 5 gold + friendly tip |

  All scores also pay `4 × score` XP and `2 × score` rep.


### 6.13 Rush minigame "طلبيات على السريع" and tickets, from L11
- **Entry:** the tickets button on the left rail. A round costs 1 ticket. "تدريب" (practice) is free, never rewards, and is always available.
- **Tickets:**
  - +1 per 3 h of real time while below the cap. The cap is 3 (4 from L35).
  - Rewards may overflow the cap up to 9.
  - Buying a ticket costs 10 gold (max 3 per day).
- **Screen** (S30, portrait):
  - Top: 60 s timer bar, score, combo "×1.3".
  - Middle: customer art (64 pt) with an order card showing base + fillings as 40 pt icons.
  - Bottom: 3×3 grid, 8 ingredient buttons (72 pt) from the city's `rushIngredients`, and a centre "لفّ" (wrap) button.
- **Rules:**
  - Tap the base first, then the fillings in any order, then "لفّ".
  - A wrong tap resets the combo and the ingredient shakes. No time penalty.
  - "لفّ" with a missing filling just shakes.
  - **Points per order** = `(100 + 25 × fillings) × combo + (≤ 3 s ? 50 : 0)`, where combo = `min(2.0, 1 + 0.1 × streak)`.
  - **Ramp:** orders 1–3 have 2 fillings, 4–7 have 3, 8–12 have 4, 13+ have 5.
  - Every 5th order is "مستعجل": its own 6 s timer, ×1.5 points. If it runs out, the customer leaves and only the combo resets.
- **Results** (T1; new best T2):
  - ولعة ×2 for `clamp(5 + score/400, 5, 30)` active minutes (banked max 60);
  - cash = `score/1000 × 3` minutes of current-kitchen income;
  - rep `10 + ⌊score/500⌋`, 10 XP, 5 SP.
  - The best score is kept per city. A typical round is 12–18 orders ≈ 3,000–6,000 points.
- **Accessibility:** icons never rely on colour alone, every target is ≥ 64 pt, and Reduce Motion is respected. The minigame is never required, except for orders that ask the player to "play N rounds".

### 6.14 Achievements (الإنجازات)
- **Structure:** 30 families × 5 tiers = 150 achievements (Appendix I).
- **Tier rewards:** gold 5 / 10 / 15 / 25 / 40, XP 20 / 40 / 80 / 150 / 250, plus T1.
- **Display:** families list in Tasks → الإنجازات, with progress to the next tier. A red dot shows only when a tier can be claimed.
- **Counting:** metrics are lifetime counters in `stats`, so achievements are retroactive.

### 6.15 Notifications (local only)
- **Permission:** soft-prime at FTUE step 14 (the first natural appointment) with the bubble "بدّك أخبرك لما تتعبّى الخزنة؟" [أكيد / مش هسّا].
  - Only "أكيد" opens the iOS prompt.
  - After "مش هسّا", ask once more when the first supply run is sent, then never again.
- **Candidates:**

| id | Fire time | Condition at scheduling | Text (m) |
|---|---|---|---|
| streakRisk | 20:00 today | streak ≥ 3 and no daily order done today | سلسلتك {n} يوم! طلب واحد بيحميها |
| contractEnding | deadline − 24 h | goal 3 not reached | طلبية "{title}" بتخلص بكرة، ضايل شوي! |
| leagueResult | Monday 10:00 | league active | نتيجة الدوري طلعت! شوف وين صرت |
| supplyBack | run return time | unclaimed run | رجع {vehicle} ومعه إشي حلو! تعال شوف |
| researchDone | completion time | — | دفتر ستّي: خلص بحث "{node}" |
| vaultFull | lastActive + max(capHours, 6 h) | — | الخزنة تعبّت يا معلّم! تعال اجمعها |
| winback3 | lastActive + 3 days, 18:30 | — | ستّي بتسأل عنك… البسطة مشتاقتلك |
| winback7 | lastActive + 7 days, 18:30 | — | زباينك ناطرينك، وفي إشي جديد بالسوق |

- **Rules:**
  - Max 1 per game day and 5 per rolling 7 days.
  - Priority: streakRisk > contractEnding > leagueResult > supplyBack > researchDone > vaultFull > winback.
  - **Quiet hours:** 22:00–09:00, or 23:30–10:00 during Ramadan (streakRisk moves to 21:30). A candidate falling in quiet hours shifts to the end of quiet hours if it is still true then (supplyBack, researchDone, vaultFull). Otherwise it is dropped.
  - **Scheduling:** on every background and every launch:
    1. Remove all pending notifications.
    2. Build the candidate list for the next 7 days.
    3. Pick one per game day by priority (ties: earliest).
    4. Schedule at most 7 (iOS keeps max 64 pending).
  - On foreground, clear delivered notifications.
  - After winback7, nothing more is sent until the player returns.
- **Settings:** a master toggle plus "تذكير السلسلة".

### 6.16 Legacy gift for v2 players
- **Detection:** on first v3 launch, check `UserDefaults` key `falafel.save.v2`. Decode leniently: only `stallName`, `prestigeCount`, `lifetimeEarnings`, `liras`. If decoding fails, still grant the gift when the key exists. Never modify or delete v2 data.
- **Gift** (once; `legacy.claimed = true`):
  - 300 gold + 1 gold chest.
  - Exclusive legendary chef **أبو صبحي الأوّلاني** (palestinian / fried) at level `1 + min(4, ⌊prestigeCount/5⌋)`.
  - Profile frame "من الجيل الأوّل".
  - The v2 `stallName` becomes the v3 stall name. Default: "بسطة ستّي".
- **Timing:** the modal (S34) appears right after the FTUE level-2 celebration, never before the first tap.
  - Text: "شكراً إنّك معنا من الأوّل! ستّي خبّتلك هديّة".
  - The chef can be equipped at L4. The chest goes to inventory.

### 6.17 Settings (S26)
| Setting | Values | Default |
|---|---|---|
| الأصوات (SFX) | on/off | on |
| الموسيقى (ambience) | on/off; hidden if no music asset is bundled | on |
| الاهتزاز (haptics) | on/off | on |
| الإشعارات | on/off + "تذكير السلسلة" | per permission |
| تقليل الحركة | تلقائي / دايماً / أبداً | تلقائي (follows the system) |
| الأرقام | 123 / ١٢٣ | 123 |
| زينة المواسم | on/off | on |
| طريقة المناداة | يا شب / يا صبية | asked in FTUE |
| أعيد الشرح | re-enables one-time spotlights for current screens, without resetting progress | — |
| عن اللعبة | credits: "Developer: Saad" (and "المطوّر: سعد"); licences: Fluent Emoji 3D (MIT, Microsoft), Baloo Bhaijaan 2 (SIL OFL 1.1), Cairo (SIL OFL 1.1); version | — |
| ابدأ من جديد | requires typing "امسح" and a second confirmation; keeps settings and the legacy flag | — |

### 6.18 FTUE script
- **Spotlight:** 70% black overlay with an even-odd cut-out (anchor rect inset −8 pt, radius 14). Only the cut-out accepts taps.
- **Hand pointer:** `TutorialHand` on a 1.0 s loop.
- **Bubbles:** `StoryBubble`, 8–12 words, ستّي's portrait `ppl_old_woman`. Placed above the anchor if it is in the lower half, otherwise below.
- **Soft steps** show the bubble without the overlay.
- **Anchors** are `fxAnchor` ids. The `_m` text is shown; `_f` variants live in strings.json.
- **Saving:** steps are saved (`ftue.step`). A killed app resumes at the step's start condition.

| # | Starts when | Spotlight anchor | Line (Arabic) | Completes when | Feedback |
|---|---|---|---|---|---|
| 1 | first frame (t = 0) | `station.0.cook` | أهلا يا حبيبي! دقّ عالفلافل عشان تقلي أوّل قرص | 1 tap-cook | T0 + T1 coins |
| 2 | step 1 done | `station.0.cook` (soft) | كمان! كل دقّة بتجيب مصاري | cash ≥ cost of level 2 | T1 per cycle |
| 3 | cash ≥ cost | `station.0.buy` | اشتري مستوى كمان، الزباين بستنّوا! | level 2 bought (< 15 s) | T0 |
| 4 | level 2 | none (soft bubble) | كل ما تكبّر الفلافل بتربح أكتر | falafel level 10 | T1 "سرعة ×2" |
| 5 | cash ≥ 60 | `station.1.card` | صار معك مصاري! افتح محطة الحمّص | hummus unlocked | T1 |
| 6 | step 5 done | `station.1.cook` | الحمّص بدّه دقّة كمان | 1 tap on hummus | T0 |
| 7 | step 6 done (goal strip slides in; goal 1 is already complete) | `goal.0.claim` | خلّصت أوّل هدف! خذ نجمتك | goal claimed → L2 (~1:30–2:00) | T1 + T2 level up |
| 8 | cash ≥ manager cost (1,000) | `station.0.manager` | وظّف معلّم للفلافل، بيقلي عنك وإنت مش هون | manager hired (~3 min) | T1 |
| 9 | step 8 done | `buyMode` | جرّب ×10، أسرع بكتير! | mode = ×10 | T0 |
| 10 | L3 reached | `special` (forced spawn, outcome frenzy) | زبون مميّز وصل! الحقه قبل ما يروح | special tapped | T2 frenzy |
| 11 | first upgrade affordable | `upgrades` → `upgrade.0.buy` | الترقيات بتضرب الربح ×3، جرّب وحدة! | upgrade bought | T1 |
| 12 | L4 reached (ceremony) | `tab.chefs` → `chest.free` → `chef.slot.0` → `tab.home` | ستّي بعتتلك صندوق! افتحه … حطّ سامي بالمطبخ، بيقوّي الفلافل | chest opened (scripted: chef "سامي القلّاي") and equipped | T2 chest, T1 equip |
| 13 | 2 min after step 12 | none | Story: rival scene "أبو شاكر" (6.19) | scene closed | — |
| 14 | L5 reached | `rail.vault` | الخزنة بتتعبّى لحالها وإنت برّا، لحد 3 ساعات. ارجعلي بعد ساعتين، بفرجيك مدينة جديدة! + notification soft-prime | bubble closed | T2 ceremony |
| 15 | next launch ≥ 30 min away | newspaper `vault.collect` | أهلين! شوف قدّيش جمّعت الخزنة | vault collected → goal 14 | T1 |
| 16 | L6 reached | `tab.map` → `map.next` | هاي الخريطة! بيت لحم بتفتح لما تجمع 25 نجمة | map viewed | T2 ceremony |
| 17 | L7 reached | `rail.research` → `research.node.biggerVault` | دفتر ستّي فيه أسرار. ابدأ أوّل بحث | research started | T2 ceremony, T0 |
| 18 | L8 reached | `rail.supply` → `supply.vehicle.tractor` → `supply.duration.0` | ابعت التراكتور يجيب أغراض من البلد | run sent | T2 ceremony, T0 |
| 19 | graduation available | `goalStrip.graduate` | جاهز! افتح فرع بالقدس وانقل على بيت لحم | graduated | T3 |

- **Targets:** first tap under 3 s (step 1 is live on the first frame), first purchase under 15 s, first T2 under 2 min (step 7).
- **Session 1 ends on the appointment** at step 14 (vault plus "مدينة جديدة").
- **After FTUE**, each new system gets its ceremony and a one-time spotlight from `ftue.json` (`unlockSpotlights`).

### 6.19 Story (story.json)
- **Cast:**
  - ستّي أم خليل (`ppl_old_woman`): the mentor. She calls by phone in every city.
  - The player (no portrait; name = stall name).
  - One rival chef per city (Appendix A), cheeky but kind; each becomes a friend at the finale.
  - Recurring customers in `ppl_*` art.
- **Chapter = city.** Four scenes, each 2–5 lines:

| Scene | When |
|---|---|
| `arrival` | first open of the city |
| `rival` | 25% of stars |
| `midpoint` | 50% of stars |
| `finale` | graduation, before the T3 travel |

- **Extra scenes:**
  - Story beats for festivals (mothersDay, Ramadan day 1, Eid day 1).
  - Graduating Ramallah (end of Palestine) gives the legendary chef ستّي أم خليل with the scene "ستّي بتنضم للفريق".
  - The epilogue after Tokyo is "رجعة عالقدس".
- **Jerusalem chapter** (complete; other chapters follow this shape, with synopses in Appendix A):
  - **arrival** (merged into FTUE steps 1–3): ستّي: "هاي بسطة جدّك أبو خليل، الله يرحمه. صارت إلك يا حبيبي."
  - **rival:**
    - أبو شاكر: "أهلين بالجار الجديد! فلافلي أطيب فلافل بالقدس… بس منشوف."
    - ستّي: "لا تخاف منه، قلبه طيّب، بسّ بموت بالمنافسة."
    - أبو شاكر: "إذا وصلت الفلافل لمستوى 25، بعزمك على كاسة شاي."
  - **midpoint:**
    - ستّي (phone): "سمعت إنّه الطابور واصل لباب العامود!"
    - Player: "كلّه من وصفتك يا ستّي."
    - ستّي: "الوصفة نصّ الشغل، والنصّ التاني ابتسامتك."
  - **finale:**
    - أبو شاكر: "والله طلعت قدّها! البسطة صارت فرع، وأنا ضلّيت جارك."
    - ستّي: "بيت لحم ناطرتك، هناك الكستنا والسحلب وناس بتحب الضيف."
    - Player: "يلا عبيت لحم!"

### 6.20 Stall tiers and cosmetics
- **City stall tier** = `⌊8 × claimedStars / totalStars⌋`:

| Tier | Look |
|---|---|
| 0 | wooden cart |
| 1 | striped awning |
| 2 | string lights |
| 3 | bunting |
| 4 | second fryer + steam |
| 5 | tables and chairs |
| 6 | painted sign |
| 7 | plants and lanterns |
| 8 | gold sign + queue rope |

  Tier changes play T1 with a build puff in the scene.
- **Branch stall** (map and branch sheet): level 0 → tier 6 look, 1 → 7, 2 → 8, 3 → 8 + gold trim, 5 → restaurant front, 7 → neon, 10 → golden façade.
- **Queue length** in the scene = `clamp(1 + log10(income/s), 1, 6)` customers.
- **Cosmetics** (cosmetics.json): 4 stall slots (مظلّة، يافطة، إضاءة، إكسسوار) plus a profile frame. They apply to every kitchen's stall and are visual only. Sources: level rewards, event milestone 10, season pass, shop (150–600 gold), achievements, festivals, legacy.

---

## 7. Save model, determinism and clock guard

### 7.1 Save model
- **Storage:** one Codable `GameSave` JSON in UserDefaults key `basta.save.v3`, plus a backup copy `basta.save.v3.bak` written at each game-day rollover.
- **Tolerant decoding:** every field is optional with a default; unknown fields are ignored; enums decode unknown raw values to a fallback. `saveVersion: Int` drives explicit migrations.
- **Writes:** every 10 s while running, on background, and after any gold/chest/chef/heritage/research/run state change.

| Section | Contents | Resets when |
|---|---|---|
| `meta` | saveVersion, playerSeed (UInt64), createdAt, installId, lastTrustedWall, lastUptime, bootTime, lastActiveTick, lastProcessedDay, lastProcessedWeek, clockFrozen | never |
| `settings` | 6.17 values, addressForm, stallName | never |
| `ftue` | step, done flags, seenSpotlights, seenCeremonies, revealViews | never ("أعيد الشرح" clears spotlights only) |
| `empire` | level, xp, title, unlockedSystems, cosmeticsOwned/equipped | never |
| `wallet` | gold, zaatar, tickets, ticketRegenAt, freezes, timeWarps [min], craftPoints, purchasesToday | daily counters at rollover |
| `city` | currentCityId, kitchen (Kitchen), goalsClaimed, stars, storyScenesSeen, twistState, licenceStartedAt | at graduation (kitchen discarded) |
| `branches` | per cityId: level, crowned, stars, finalIncome, graduatedAt | never |
| `branchSafe` | stored (Double), lastAccrual | never |
| `chefs` | owned [id: level, cards], equipped [id], skillCooldowns, chestInventory [kind: count], pity counters | never |
| `research` | levels [nodeId: Int], slots [{nodeId, level, startAt, endAt}] | never |
| `supply` | vehicles [id: launches], slots [{vehicleId, durationIdx, sentAt, endAt, rollsSeed}], heritage [itemId: copies] | never |
| `daily` | calendar {index, cycle, lastClaimDay}, streak {count, best, lastDay, repair}, orders {day, list, progress, rerolls}, weekly {weekId, list, progress}, lanterns | daily/weekly lists at rollover |
| `market` | cached modifiers and weather for the next 14 days | rolling |
| `contracts` | board [{releaseId, contractId, releasedAt}], active [{contractId, grade, startAt, endAt, kitchen, goalsReached}], zaatarClaimedIds | active kitchen at end |
| `event` | weekId, themeId, kitchen, milestonesClaimed, tokens, shopBought, npcSeed, history [finals] | at Monday 04:00 (history kept) |
| `league` | weekId, tier, groupSeed, scoreThisWeek, history [{weekId, tier, finalScore, rank}] | score weekly |
| `season` | seasonIndex, points, claimedTiers, bonusChests | at season end |
| `happenings` | lastSpecialAt, activeTimeSinceSpecial, lastChoiceAt, choicesToday, rowCooldowns [id: day], karma, flags, newspaper queue, inspector {nextAt, lastScore} | daily counters |
| `boosts` | active [{kind, mult, remainingActiveSec}], dayEffects cache | expiry |
| `stats` | lifetime counters (taps, customers, stars, specials, runs, chests, …) for achievements | never |
| `achievements` | claimed tiers per family | never |
| `notifications` | permission state, asked count, lastScheduled list, weekCount | never |
| `legacy` | claimed, v2Snapshot {stallName, prestigeCount} | never |
| `schedule` | precomputed 14-day rows (7.2) | rolling |

### 7.2 Deterministic seeding
- **playerSeed:** a random `UInt64` created at first launch and stored.
- **Rule RNG:** `rng(purpose, parts…) = SplitMix64(FNV1a64("purpose|part1|part2|…") ^ playerSeed)`. Global-calendar content that should feel shared (contract "new" pick, event theme rotation, season index) does **not** mix in playerSeed.
- **Purposes:** `market`, `weather`, `orders`, `ordersReroll`, `league`, `event`, `contract`, `inspector`, `special`, `choice`, `offlineNews`, `chest`, `supplyRoll`, `busOffset`, `portOffset`, `rushOrders`.
- **14-day schedule:** at each rollover, compute and store the next 14 days of market, weather, contract releases, event themes, inspector date and twist offsets. Days already stored are never recomputed, so content updates only affect day 15 onward.
- **Per-call seeds:**
  - Chest and supply rolls seed with `(purpose, openCounter)` and store the counter, so killing the app mid-reveal cannot re-roll.
  - Supply runs store `rollsSeed` at send time; the result is fixed at departure.

### 7.3 Clock-rollback guard
- **During a session:**
  - `trustedNow = lastTrustedWall + (systemUptime − lastUptime)`, which is monotonic.
  - If wall time differs from trustedNow by more than 120 s, the device clock has changed. Keep using trustedNow and recheck on resume.
- **On resume**, compare `kern.boottime`:
  - **Same boot:** `elapsed = uptimeNow − lastUptime` (trusted).
    - If `wallNow − lastTrustedWall > elapsed + 600`, the clock moved forward manually. Use `elapsed` and set `lastTrustedWall += elapsed`.
  - **Rebooted:** `elapsed = max(0, wallNow − lastTrustedWall)`. This cannot be verified; it is limited by vault caps.
  - **Backward**, when `wallNow < lastTrustedWall − 300`: enter **clockFrozen**.
    - Real-time timers (research, runs, contracts, licences, tickets, branch safe, boosts' real-time parts) do not advance.
    - No rollovers, no offline earnings.
    - Banner: "ساعة الجهاز رجعت لورا، الوقت موقّف لحد ما ترجع".
    - Active income still runs (tick dt from uptime).
    - Unfreeze when `wallNow ≥ lastTrustedWall`.
- **Rollovers** are idempotent per `gameDay` and `weekId`, and never run for a day ≤ `lastProcessedDay`. Calendar and orders give at most one claim per processed day, so pushing the clock forward and then back freezes the game until real time catches up.
- **Offline gains** are always clamped by the vault cap.

---

## 8. Pacing plan

Bot numbers come from `design/tools/campaign.py` (casual = 3 sessions/day, 12/8/15 min; day 0 = 25/8/12 min). Real players run about 20% slower; the targets below are for real players.

| Milestone | Session 1 (~25 min) | Day 1 | Week 1 | Month 1 | Month 3 |
|---|---|---|---|---|---|
| City | Jerusalem ~40–50% of stars | Jerusalem done; Bethlehem open (bot: Bethlehem done on the morning of day 1) | in city 4–5, i.e. 3–4 graduated (bot: city 6 on day 6.3) | in city 10–12 (bot: city 12 on day 27) | in city 20–23 (bot: Tokyo on day 85, campaign done on day 92) |
| Empire level | L4–5 | L8–9 | L17–19 | L31–33 | L54–56 |
| Systems unlocked | kitchen, goals, managers, specials, upgrades, chefs, vault | + map, research, supply runs (first research and run started) | + daily, calendar, streak, choices, rush, league (joined), market, contracts, weekend venue (first), season, branch upgrades | + inspector, crafting, research slot 2, chef skills, time warps, chef slot 4, contract slot 2 | + ticket cap 4, grade 3, chef slot 5, freezes 3 |
| Gold earned (cumulative) | ~40 | ~120 | ~480 | ~2,000 | ~6,000 |
| Golden Za'atar | 0 | 0–1 | 3–5 | 14–17 | 45–50 (×9–11) |
| Chefs owned | 1 | 2–3 | 8–10 | 16–19 | 24–27 |
| Research levels | 0 | 1–2 | 12–15 | 45–55 | 130–160 |
| Heritage items (unique) | 0 | 1–3 | 10–14 | 20–25 | 29–32 |
| League tier | — | — | 2 (week 1 promotes) | 3–4 | 5–7 |
| Season tiers | — | — | 5–8 | ~35 | season 2 done + season 3 at ~20 |
| Contracts done (goal 3) | — | — | 0–1 | 5–7 | 18–22 |
| Weekend events | — | — | 1 (milestone 6–8) | 4 | 13 |

**Acceptance (sim in CI, tools/sim):**
- Casual city durations within ±20% of the table in 3.1.
- Over any 7-day window, binge (8 h/day) ≤ 3× casual progress. The bot's day-7 ratio is about 1.6× in cities.
- No profile finishes the campaign before day 25. The bot binge finishes on day 64.7; licences alone sum to 21 days.
- Median wait to the next meaningful action ≤ 60 s, p90 ≤ 5 min.
- ≤ 10% of sessions with no goal progress.
- Every value < 1e30; the highest designed display value is about 4e18 (Tokyo F × S).
- Gold faucet 50–70/day steady state; Golden Za'atar ≤ 55 by day 90.
- Season tier 50 between days 33 and 40 for casual.

**Endless layer (after Tokyo):**
- Branch upgrades (23 × 10 levels ≈ 58,000 gold, a sink lasting years).
- Chefs to L10 (≈ 19,000 gold plus cards).
- Research completion (~4 months).
- Heritage L5 sets.
- League tiers 8–10.
- A season every 42 days, a new contract every week, weekend themes every week, festivals.
- The 28-day calendar (one Za'atar per cycle).
- Achievements tiers 4–5.

A post-launch Family Legacy (الإرث العائلي) reset layer is reserved: the save reserves a `dynasty` section, and `branches`, `chefs`, `supply.heritage`, `stats` and `achievements` are designed to survive it. It is not in v3.0.


---

# Appendices

## Appendix A: Cities
**Format.** Each station is listed as `index key name art cuisine/category [weather]`.
- Cuisine abbreviations: pal = palestinian, lev = levantine, egy = egyptian, gulf, irq = iraqi, mag = maghrebi, tur = turkish, wld = world.
- Weather tags (6.6): `[cold]` sells more on hot days; `[hot]` sells more on cold days.
- **Rush ingredients:** 2 bases followed by 6 fillings.
- **Story:** a one-line synopsis of the chapter (4 scenes each).

### A1. القدس `jerusalem`
- **Currency:** جنيه فلسطيني, symbol "ج.ف", art `ui_dollar`.
- **Landmark:** `bld_mosque`.
- **Sky:** #33172E #6E2F4A #D9714A #FFB36B, accent #F9B233.
- **Rival:** أبو شاكر (`ppl_man_cook`).
- **Stations:**
  - 0 falafel فلافل `food_falafel` pal/fried
  - 1 hummus حمّص `food_hummus_bowl` pal/dishes
  - 2 tea شاي بالنعنع `food_tea` lev/drinks [hot]
  - 3 kaak كعك القدس `food_bagel` pal/bakery
  - 4 ful فول مدمّس `food_beans` pal/dishes [hot]
  - 5 maqluba مقلوبة `food_maqluba_pan` pal/dishes
- **Twist:** none (tutorial).
- **Rush:** خبز `food_flatbread`, كعك `food_bagel`; فلافل `food_falafel`, حمّص `food_hummus_bowl`, بندورة `food_tomato`, خيار `food_cucumber`, بقدونس `food_leafy_green`, شطّة `food_hot_pepper`.
- **Story:** ستّي hands over grandpa's stall. The cheeky neighbour Abu Shaker challenges the newcomer, then becomes a friend.

### A2. بيت لحم `bethlehem`
- **Currency:** جنيه فلسطيني, `ui_dollar`.
- **Landmark:** `bld_night_with_stars`.
- **Sky:** #1B1A3A #3E2D63 #B0567A #FFD27A, accent #FFE38A.
- **Rival:** الخواجة جريس (`ppl_beard`).
- **Stations:**
  - 0 chestnut كستنا مشويّة `food_chestnut` pal/street [hot]
  - 1 lentilSoup شوربة عدس `food_steaming_bowl` pal/dishes [hot]
  - 2 musakhanRolls مسخّن رولات `food_stuffed_flatbread` pal/bakery
  - 3 sahlab سحلب `food_milk` lev/drinks [hot]
  - 4 spinachPies فطاير سبانخ `food_dumpling` lev/bakery
  - 5 feastCake كعكة العيد `food_shortcake` wld/sweets
- **Twist:** `busWaves` {intervalMin 20, windowSec 30, waveMult 4, waveSec 60, stations []}.
- **Rush:** طابون `food_flatbread`, صاج `food_stuffed_flatbread`; دجاج `food_poultry_leg`, بصل `food_onion`, سمّاق `food_herb`, زيتون `food_olive`, سبانخ `food_leafy_green`, ليمون `food_lemon`.
- **Story:** Tourist buses pour into Manger Square. Jiries the chestnut seller teaches that "الضيف ضيف الله".

### A3. نابلس `nablus`
- **Currency:** جنيه فلسطيني, `ui_dollar`.
- **Landmark:** `bld_mountain`.
- **Sky:** #2A1A12 #5E3420 #C8693A #FFC37A, accent #E07A2E.
- **Rival:** أبو حمدي الكنفاني (`ppl_older_person`).
- **Stations:**
  - 0 taboon خبز طابون `food_flatbread` pal/bakery
  - 1 nabulsiCheese جبنة نابلسيّة `food_cheese` pal/dishes
  - 2 olives زيتون مكبوس `food_olive` pal/dishes
  - 3 awwameh عوّامة `food_doughnut` lev/sweets
  - 4 qatayef قطايف `food_dumpling` lev/sweets
  - 5 halawa حلاوة بالسمسم `food_cookie` lev/sweets
  - 6 knafeh كنافة نابلسيّة `food_pie` pal/sweets
- **Twist:** `ovenTiming` {station knafeh, windowSec 1.6, perfectMult 3, minCycleSec 2}.
- **Rush:** كعك `food_bagel`, طابون `food_flatbread`; جبنة `food_cheese`, زعتر `food_herb`, زيتون `food_olive`, بيض `food_egg`, بندورة `food_tomato`, عسل `food_honey`.
- **Story:** Abu Hamdi guards the secret of knafeh timing. The player earns his respect one perfect tray at a time.

### A4. الخليل `hebron`
- **Currency:** جنيه فلسطيني, `ui_dollar`.
- **Landmark:** `bld_houses`.
- **Sky:** #2B1630 #5A2B57 #A85A7C #F2B5A0, accent #7B3F8C.
- **Rival:** أبو العز (`ppl_man_farmer`).
- **Stations:**
  - 0 dateKaak كعك بعجوة `food_cookie` pal/bakery
  - 1 grapes عنب خليلي `food_grapes` pal/street [cold]
  - 2 dibs دبس عنب `food_honey` pal/sweets
  - 3 malban ملبن `food_candy` pal/sweets
  - 4 qidra قدرة خليليّة `food_pot` pal/dishes [hot]
  - 5 mashawi مشاوي خليليّة `food_meat_on_bone` pal/grill
  - 6 qahwa قهوة سادة `food_coffee` lev/drinks [hot]
- **Twist:** `productionChain` {inputStation grapes, outputStation dibs, ratio 1, outputMult 3, stockCapMin 60}.
- **Rush:** صاج `food_stuffed_flatbread`, خبز `food_bread`; لحمة `food_cut_of_meat`, بصل `food_onion`, عنب `food_grapes`, دبس `food_honey`, جوز `food_peanuts`, بندورة `food_tomato`.
- **Story:** The grape harvest. Abu Al-Izz shows that good dibs needs patience and plenty of grapes.

### A5. يافا `jaffa`
- **Currency:** جنيه فلسطيني, `ui_dollar`.
- **Landmark:** `bld_sunset`.
- **Sky:** #12324A #2E6E8E #F08A24 #FFD08A, accent #F08A24.
- **Rival:** أم يوسف (`ppl_woman`).
- **Stations:**
  - 0 oranges برتقال يافاوي `food_tangerine` pal/street [cold]
  - 1 orangeJuice عصير برتقال `food_tropical_drink` pal/drinks [cold]
  - 2 friedFish سمك مقلي `ani_fish` pal/seafood
  - 3 shrimp قريدس مقلي `food_fried_shrimp` pal/seafood
  - 4 sayadieh صيّاديّة `food_cooked_rice` pal/seafood
  - 5 jaffaSalad سلطة يافاويّة `food_green_salad` pal/dishes
  - 6 seaIceCream بوظة عالبحر `food_ice_cream` wld/sweets [cold]
- **Twist:** `portShipments` {station oranges, intervalHours 4, dockHours 3, targetMin 30, rewardMin 90}.
- **Rush:** خبز `food_bread`, كعك `food_bagel`; سمك `ani_fish`, قريدس `food_fried_shrimp`, ليمون `food_lemon`, بندورة `food_tomato`, شطّة `food_hot_pepper`, برتقال `food_tangerine`.
- **Story:** Orange crates for the ships. Umm Yousef the fish-fryer runs the port kitchen like a captain.

### A6. حيفا `haifa`
- **Currency:** جنيه فلسطيني, `ui_dollar`.
- **Landmark:** `bld_sunrise_over_mountains`.
- **Sky:** #102A3A #1F5C6E #5FA8A0 #FFE1A8, accent #2F8F86.
- **Rival:** نزار الشاورماتي (`ppl_man`).
- **Stations:**
  - 0 shawarma شاورما `food_shawarma_wrap` lev/street
  - 1 fries بطاطا مقليّة `food_french_fries` wld/fried
  - 2 kibbeh كبّة مقليّة `food_roasted_sweet_potato` lev/fried
  - 3 corn ذرة مشويّة `food_corn` lev/street
  - 4 manakish مناقيش زعتر `food_flatbread` lev/bakery
  - 5 carmelCoffee قهوة الكرمل `food_coffee` lev/drinks [hot]
  - 6 muhallabia مهلبيّة `food_custard` lev/sweets [cold]
- **Twist:** `deliveryRuns` {intervalMin 10, tripMin 6, rewardMin 8, scooters 2, extraScooterCostsBase [F×1e−6, F×1e−4, F×1e−2], dispatcherCostBase F×1e−5}.
- **Rush:** صاج `food_stuffed_flatbread`, خبز `food_bread`; شاورما `food_shawarma_wrap`, بطاطا `food_french_fries`, ثوم `food_garlic`, مخلل `food_cucumber`, بندورة `food_tomato`, بصل `food_onion`.
- **Story:** Scooters climb Mount Carmel. Nizar bets that delivery beats queues.

### A7. غزّة `gaza`
- **Currency:** جنيه فلسطيني, `ui_dollar`.
- **Landmark:** `bld_beach_with_umbrella`.
- **Sky:** #0E2F4F #1D6FA3 #F3A65A #FFE7B8, accent #1D9BD1.
- **Rival:** أبو رامي الصيّاد (`ppl_old_man`).
- **Stations:**
  - 0 dagga دقّة غزّاويّة `food_hot_pepper` pal/street
  - 1 sumagiyya سمّاقيّة `food_steaming_bowl` pal/dishes [hot]
  - 2 grilledFish سمك مشوي `ani_fish` pal/seafood
  - 3 zibdiyya زبديّة قريدس `food_pot` pal/seafood [hot]
  - 4 watermelon بطّيخ `food_watermelon` pal/street [cold]
  - 5 lemonMint ليمون ونعنع `food_lemon` pal/drinks [cold]
  - 6 beachIceCream بوظة البحر `food_soft_ice_cream` wld/sweets [cold]
- **Twist:** `weatherSwing` {hotProb 0.45, coldProb 0.15, rainProb 0.10, hotDayStations [watermelon, lemonMint, beachIceCream], coldDayStations [sumagiyya, zibdiyya], rainDayStations [], mult 2.5}.
- **Rush:** خبز `food_bread`, طابون `food_flatbread`; سمك `ani_fish`, قريدس `food_fried_shrimp`, شطّة `food_hot_pepper`, ثوم `food_garlic`, ليمون `food_lemon`, بندورة `food_tomato`.
- **Story:** Families on the beach on hot days. Abu Rami teaches the dagga recipe and reading the sea.

### A8. رام الله `ramallah`
- **Currency:** جنيه فلسطيني, `ui_dollar`.
- **Landmark:** `bld_cityscape`.
- **Sky:** #1A1433 #3A2A6B #E0567A #FFC1A1, accent #E0567A.
- **Rival:** سلمى (`ppl_woman_office`).
- **Stations:**
  - 0 falafelSandwich ساندويش فلافل `food_sandwich` pal/street
  - 1 pizza بيتزا `food_pizza` wld/bakery
  - 2 shawarmaPlate صحن شاورما `food_fork_knife_plate` lev/street
  - 3 burger برغر `food_hamburger` wld/fried
  - 4 cappuccino كابتشينو `food_coffee` wld/drinks [hot]
  - 5 knafehCup كنافة بالكاسة `food_custard` pal/sweets
  - 6 sous عرق سوس `food_cup_with_straw` lev/drinks [cold]
- **Twist:** `nightMarket` {stations [shawarmaPlate, cappuccino, knafehCup], startHour 20, endHour 2, nightMult 3}.
- **Rush:** خبز `food_bread`, صاج `food_stuffed_flatbread`; فلافل `food_falafel`, بطاطا `food_french_fries`, حمّص `food_hummus_bowl`, خيار `food_cucumber`, بندورة `food_tomato`, شطّة `food_hot_pepper`.
- **Story:** The city that never sleeps early. Salma's café rivalry turns into a joint night market. On graduating Ramallah, ستّي joins as a legendary chef.

### A9. عمّان `amman`
- **Currency:** دينار أردني, symbol "د.أ", `ui_money_bag`.
- **Landmark:** `bld_castle`.
- **Sky:** #2D1E14 #6B4A2E #C98B4A #F6D9A8, accent #B5651D.
- **Rival:** أبو عودة (`ppl_turban`).
- **Stations:**
  - 0 downtownFalafel فلافل وسط البلد `food_falafel` lev/fried
  - 1 milk حليب `food_milk` lev/dishes
  - 2 jameed جميد `food_cheese` lev/dishes
  - 3 knafehNaama كنافة ناعمة `food_pie` lev/sweets
  - 4 mansaf منسف `food_cooked_rice` lev/dishes [hot]
  - 5 zarb زرب `food_meat_on_bone` lev/grill
  - 6 arabicCoffee قهوة عربيّة `food_teapot` gulf/drinks [hot]
  - 7 hareeseh هريسة `food_shortcake` lev/sweets
- **Twists:** `productionChain` {milk → jameed, ratio 1, outputMult 2} and `productionChain` {jameed → mansaf, ratio 1, outputMult 3}.
- **Rush:** شراك `food_flatbread`, خبز `food_bread`; لحمة `food_cut_of_meat`, رز `food_cooked_rice`, جميد `food_cheese`, لوز `food_peanuts`, بصل `food_onion`, بقدونس `food_leafy_green`.
- **Story:** A wedding mansaf for 500 guests. Abu Odeh's three-step jameed chain is the test.

### A10. بيروت `beirut`
- **Currency:** ليرة لبنانيّة, "ل.ل", `ui_money_bag`.
- **Landmark:** `bld_cityscape_at_dusk`.
- **Sky:** #0F2238 #24507A #E86A5C #FFD6A5, accent #E86A5C.
- **Rival:** طوني (`ppl_man_cook`).
- **Stations:**
  - 0 manoushe منقوشة زعتر `food_flatbread` lev/bakery
  - 1 kaakBeiruti كعكة بيروتيّة `food_pretzel` lev/bakery
  - 2 tabbouleh تبّولة `food_green_salad` lev/dishes [cold]
  - 3 shishTawook شيش طاووق `food_poultry_leg` lev/grill
  - 4 fattoush فتّوش `food_leafy_green` lev/dishes
  - 5 sfiha صفيحة `food_pizza` lev/bakery
  - 6 lemonade ليموناضة `food_lemon` lev/drinks [cold]
  - 7 halawetJibn حلاوة الجبن `food_custard` lev/sweets
- **Twist:** `nightMarket` {stations [shishTawook, sfiha, lemonade, halawetJibn], startHour 21, endHour 3, nightMult 3}.
- **Rush:** صاج `food_stuffed_flatbread`, خبز `food_bread`; دجاج `food_poultry_leg`, ثوم `food_garlic`, بطاطا `food_french_fries`, مخلل `food_cucumber`, بندورة `food_tomato`, نعنع `food_herb`.
- **Story:** Corniche nights. Tony's sfiha versus your manoushe, settled by the crowd at 1 a.m.

### A11. دمشق `damascus`
- **Currency:** ليرة سوريّة, "ل.س", `ui_money_bag`.
- **Landmark:** `bld_fountain`.
- **Sky:** #1E2A1A #3E5A2E #C9A23A #F8E7A1, accent #3E8E5A.
- **Rival:** أبو صيّاح (`ppl_old_man`).
- **Stations:**
  - 0 msabbaha مسبّحة `food_hummus_bowl` lev/dishes
  - 1 warakEnab ورق عنب `food_leafy_green` lev/dishes
  - 2 kebabHalabi كباب حلبي `food_meat_on_bone` lev/grill
  - 3 fatteh فتّة `food_steaming_bowl` lev/dishes [hot]
  - 4 maarouk خبز معروك `food_bread` lev/bakery
  - 5 qamarDeen قمر الدين `food_juice_box` lev/drinks [cold]
  - 6 pistachioIceCream بوظة بالفستق `food_ice_cream` lev/sweets [cold]
  - 7 baklava بقلاوة شاميّة `food_pie` lev/sweets
- **Twist:** `busWaves` {intervalMin 15, windowSec 30, waveMult 4, waveSec 75}.
- **Rush:** خبز `food_bread`, صاج `food_stuffed_flatbread`; لحمة `food_cut_of_meat`, حمّص `food_hummus_bowl`, بقدونس `food_leafy_green`, بصل `food_onion`, جوز `food_peanuts`, بندورة `food_tomato`.
- **Story:** Crowds flow through the old souq. Abu Sayyah pounds ice cream to music and challenges you to keep up.

### A12. القاهرة `cairo`
- **Currency:** جنيه مصري, "ج.م", `ui_pound`.
- **Landmark:** `bld_desert`.
- **Sky:** #2E2410 #6E5420 #D9A441 #FFE6A1, accent #D9A441.
- **Rival:** عم صابر (`ppl_older_person`).
- **Stations:**
  - 0 taameya طعميّة `food_falafel` egy/fried
  - 1 koshari كشري `food_spaghetti` egy/dishes
  - 2 fulMasri فول مصري `food_beans` egy/dishes [hot]
  - 3 hawawshi حواوشي `food_stuffed_flatbread` egy/street
  - 4 feteer فطير مشلتت `food_pancakes` egy/bakery
  - 5 sugarcane عصير قصب `food_cup_with_straw` egy/drinks [cold]
  - 6 basbousa بسبوسة `food_shortcake` egy/sweets
  - 7 omAli أم علي `food_custard` egy/sweets [hot]
- **Twist:** `deliveryRuns` {intervalMin 8, tripMin 5, rewardMin 8, scooters 3, extraScooterCostsBase [F×1e−6, F×1e−4, F×1e−2], dispatcherCostBase F×1e−5}.
- **Rush:** عيش بلدي `food_flatbread`, فينو `food_baguette`; طعميّة `food_falafel`, فول `food_beans`, بيض `food_egg`, طحينة `food_jar`, بندورة `food_tomato`, شطّة `food_hot_pepper`.
- **Story:** Ta'ameya versus falafel, the eternal debate. Amm Saber's delivery bikes rule the alleys.

### A13. بغداد `baghdad`
- **Currency:** دينار عراقي, "د.ع", `ui_money_bag`.
- **Landmark:** `bld_palm_tree`.
- **Sky:** #1A2430 #2F4A5E #C77D3A #F5D3A0, accent #2F7F9E.
- **Rival:** أبو جاسم (`ppl_man`).
- **Stations:**
  - 0 iraqiChai شاي عراقي `food_tea` irq/drinks [hot]
  - 1 tikka تكّة `food_cut_of_meat` irq/grill
  - 2 dolma دولمة `food_leafy_green` irq/dishes
  - 3 kahi كاهي وقيمر `food_pancakes` irq/bakery
  - 4 masgouf مسكوف `ani_fish` irq/seafood
  - 5 samoon صمّون `food_bread` irq/bakery
  - 6 quzi قوزي `food_meat_on_bone` irq/dishes
  - 7 zalabia زلابية `food_doughnut` irq/sweets
- **Twist:** `ovenTiming` {station samoon, windowSec 1.6, perfectMult 3}.
- **Rush:** صمّون `food_bread`, خبز `food_flatbread`; فلافل `food_falafel`, عمبة `food_mango`, بيض `food_egg`, بطاطا `food_potato`, بقدونس `food_leafy_green`, بندورة `food_tomato`.
- **Story:** Masgouf by the Tigris. Abu Jassim's samoon oven waits for nobody.

### A14. الرياض `riyadh`
- **Currency:** ريال سعودي, "ر.س", `ui_money_bag`.
- **Landmark:** `bld_tent`.
- **Sky:** #3A1E0E #7A3E14 #E0742A #FFD39A, accent #C9561E.
- **Rival:** أبو سلطان (`ppl_turban`).
- **Stations:**
  - 0 gahwa قهوة سعوديّة `food_teapot` gulf/drinks [hot]
  - 1 luqaimat لقيمات `food_dango` gulf/sweets
  - 2 kabsa كبسة `food_cooked_rice` gulf/dishes
  - 3 mutabbaq مطبّق `food_stuffed_flatbread` gulf/street
  - 4 jareesh جريش `food_steaming_bowl` gulf/dishes [hot]
  - 5 mandi مندي `food_poultry_leg` gulf/grill
  - 6 laban لبن بارد `food_milk` gulf/drinks [cold]
  - 7 iceCream آيس كريم `food_soft_ice_cream` wld/sweets [cold]
- **Twist:** `weatherSwing` {hotProb 0.60, coldProb 0.10, rainProb 0.02, hotDayStations [laban, iceCream], coldDayStations [gahwa, jareesh], mult 2.5}.
- **Rush:** صاج `food_stuffed_flatbread`, خبز `food_bread`; دجاج `food_poultry_leg`, رز `food_cooked_rice`, بصل `food_onion`, ليمون `food_lemon`, شطّة `food_hot_pepper`, خيار `food_cucumber`.
- **Story:** A desert heatwave. Abu Sultan's hospitality shows that cold laban is gold in August.

### A15. دبي `dubai`
- **Currency:** درهم إماراتي, "د.إ", `ui_money_bag`.
- **Landmark:** `bld_office_building`.
- **Sky:** #0D1B2A #1B3A5C #3FA7D6 #FFE9B0, accent #D4AF37.
- **Rival:** الشيف لؤي (`ppl_man_tuxedo`).
- **Stations:**
  - 0 karak شاي كرك `food_tea` gulf/drinks [hot]
  - 1 dubaiShawarma شاورما دبي `food_shawarma_wrap` gulf/street
  - 2 machboos مجبوس `food_cooked_rice` gulf/dishes
  - 3 harees هريس `food_steaming_bowl` gulf/dishes
  - 4 falafelSushi سوشي فلافل `food_sushi` wld/street
  - 5 goldenBurger برغر ذهبي `food_hamburger` wld/fried
  - 6 nouqMilk حليب نوق `food_milk` gulf/drinks [cold]
  - 7 goldLuqaimat لقيمات بالذهب `food_dango` gulf/sweets
- **Twist:** `vipLounge` {loungeStation goldLuqaimat, specialIntervalMult 0.5, vipShare 0.6, vipTipMin 20, levelPerTier 40}.
- **Rush:** صاج `food_stuffed_flatbread`, خبز `food_baguette`; دجاج `food_poultry_leg`, جبنة `food_cheese`, أفوكادو `food_avocado`, فلافل `food_falafel`, خس `food_leafy_green`, بندورة `food_tomato`.
- **Story:** Luxury and VIPs. Chef Louay thinks a street stall cannot impress royalty. Prove him wrong.

### A16. مراكش `marrakesh`
- **Currency:** درهم مغربي, "د.م", `ui_money_bag`.
- **Landmark:** `bld_cactus`.
- **Sky:** #3A1414 #7A2A20 #D9573A #FFC28A, accent #C0392B.
- **Rival:** لالّة زهرة (`ppl_woman_headscarf`).
- **Stations:**
  - 0 msemen مسمّن `food_pancakes` mag/bakery
  - 1 harira حريرة `food_steaming_bowl` mag/dishes [hot]
  - 2 tajine طاجين `food_pot` mag/dishes [hot]
  - 3 couscous كسكسي `food_cooked_rice` mag/dishes
  - 4 pastilla بسطيلة `food_pie` mag/bakery
  - 5 mechoui مشوي `food_meat_on_bone` mag/grill
  - 6 atay أتاي بالنعناع `food_teapot` mag/drinks [hot]
  - 7 chebakia شبّاكيّة `food_pretzel` mag/sweets
- **Twists:** `nightMarket` {stations [harira, mechoui, atay, chebakia], startHour 19, endHour 1, nightMult 3} and `busWaves` {intervalMin 25, windowSec 30, waveMult 4, waveSec 60}.
- **Rush:** خبز `food_bread`, مسمّن `food_pancakes`; لحمة `food_cut_of_meat`, زيتون `food_olive`, ليمون `food_lemon`, بيض `food_egg`, نعنع `food_herb`, فلفل `food_bell_pepper`.
- **Story:** The square fills at sunset. Lalla Zahra's harira stall and your falafel share the night.

### A17. إسطنبول `istanbul`
- **Currency:** ليرة تركيّة, "ل.ت", `ui_money_bag`.
- **Landmark:** `bld_bridge_at_night`.
- **Sky:** #1A1F3A #3A3F7A #B65A8C #FFD1A6, accent #3A6EA5.
- **Rival:** الأسطى كمال (`ppl_man_cook`).
- **Stations:**
  - 0 simit سميت `food_bagel` tur/bakery
  - 1 fishSandwich ساندويش سمك `food_sandwich` tur/seafood
  - 2 doner دونر `food_shawarma_wrap` tur/street
  - 3 lahmacun لحم بعجين `food_pizza` tur/bakery
  - 4 kofte كفتة `food_meat_on_bone` tur/grill
  - 5 turkishTea شاي تركي `food_tea` tur/drinks [hot]
  - 6 kunefe كنافة تركيّة `food_pie` tur/sweets
  - 7 baklavaTr بقلاوة `food_custard` tur/sweets
- **Twists:** `portShipments` {station fishSandwich, intervalHours 4, dockHours 3, targetMin 30, rewardMin 90} and `busWaves` {intervalMin 20}.
- **Rush:** سميت `food_bagel`, خبز `food_baguette`; سمك `ani_fish`, بصل `food_onion`, خس `food_leafy_green`, ليمون `food_lemon`, بندورة `food_tomato`, شطّة `food_hot_pepper`.
- **Story:** Ferries across the Bosphorus. Usta Kemal says falafel is just "Turkish"... the debate continues.

### A18. أثينا `athens`
- **Currency:** يورو, "€", `ui_euro`.
- **Landmark:** `bld_classical_building`.
- **Sky:** #13304A #2D6A9F #F2F2F2 #FFE8B0, accent #2D6A9F.
- **Rival:** كيريا ماريا (`ppl_woman`).
- **Stations:**
  - 0 gyros جيروس `food_shawarma_wrap` wld/street
  - 1 souvlaki سوفلاكي `food_oden` wld/grill
  - 2 greekSalad سلطة يونانيّة `food_green_salad` wld/dishes [cold]
  - 3 spanakopita فطيرة سبانخ `food_pie` wld/bakery
  - 4 moussaka مسقعة `food_eggplant` wld/dishes [hot]
  - 5 tavernaFish سمك التافرنا `ani_fish` wld/seafood
  - 6 frappe فرابيه `food_cup_with_straw` wld/drinks [cold]
  - 7 loukoumades لقمة القاضي `food_doughnut` wld/sweets
- **Twists:** `busWaves` {intervalMin 20, waveMult 4} and `weatherSwing` {hotProb 0.50, coldProb 0.10, rainProb 0.05, hotDayStations [greekSalad, frappe], coldDayStations [moussaka], mult 2.5}.
- **Rush:** بيتا `food_flatbread`, خبز `food_bread`; دجاج `food_poultry_leg`, جبنة `food_cheese`, زيتون `food_olive`, بندورة `food_tomato`, خيار `food_cucumber`, بصل `food_onion`.
- **Story:** Tourists by the ruins. Kyria Maria and you discover that لقمة القاضي and loukoumades are cousins.

### A19. لندن `london`
- **Currency:** جنيه إسترليني, "£", `ui_pound`.
- **Landmark:** `bld_ferris_wheel`.
- **Sky:** #1E2430 #3D4A5E #8C9AA8 #E8E2D0, accent #B22234.
- **Rival:** مستر هاري (`ppl_man_tuxedo`).
- **Stations:**
  - 0 englishTea شاي إنجليزي `food_teapot` wld/drinks [hot]
  - 1 fishChips سمك وبطاطا `food_french_fries` wld/fried
  - 2 londonSandwich ساندويش `food_sandwich` wld/street
  - 3 pie فطيرة لحمة `food_pie` wld/bakery [hot]
  - 4 falafelWrap راب فلافل `food_falafel` pal/street
  - 5 breakfast فطور إنجليزي `food_fried_egg` wld/dishes [hot]
  - 6 scones سكونز `food_bread` wld/bakery
  - 7 pudding بودنغ `food_custard` wld/sweets
- **Twists:** `weatherSwing` {hotProb 0.10, coldProb 0.30, rainProb 0.40, hotDayStations [londonSandwich], coldDayStations [englishTea, pie, breakfast], rainDayStations [englishTea, pie], mult 2.5} and `deliveryRuns` {intervalMin 10, tripMin 6, rewardMin 8, scooters 2}.
- **Rush:** راب `food_flatbread`, خبز `food_bread`; فلافل `food_falafel`, حمّص `food_hummus_bowl`, بطاطا `food_french_fries`, خس `food_leafy_green`, بندورة `food_tomato`, جبنة `food_cheese`.
- **Story:** Rainy days and delivery riders. Mr Harry discovers falafel wraps beat soggy chips.

### A20. باريس `paris`
- **Currency:** يورو, "€", `ui_euro`.
- **Landmark:** `bld_carousel_horse`.
- **Sky:** #24182E #4E3363 #C27BA0 #FFD9C2, accent #C27BA0.
- **Rival:** مسيو بيير (`ppl_man_cook`).
- **Stations:**
  - 0 crepe كريب `food_pancakes` wld/sweets
  - 1 croissant كرواسون `food_croissant` wld/bakery
  - 2 cafeParis قهوة باريسيّة `food_coffee` wld/drinks [hot]
  - 3 cheesePlate صحن أجبان `food_cheese` wld/dishes
  - 4 onionSoup شوربة بصل `food_steaming_bowl` wld/dishes [hot]
  - 5 baguette باغيت `food_baguette` wld/bakery
  - 6 gateau كيكة فرنسيّة `food_birthday_cake` wld/sweets
  - 7 gourmetFalafel فلافل فاخر `food_fork_knife_plate` pal/fried
- **Twists:** `vipLounge` {loungeStation gourmetFalafel, specialIntervalMult 0.5, vipShare 0.6, vipTipMin 20, levelPerTier 40} and `ovenTiming` {station baguette, windowSec 1.6, perfectMult 3}.
- **Rush:** باغيت `food_baguette`, كرواسون `food_croissant`; جبنة `food_cheese`, بيض `food_egg`, فطر `food_mushroom`, خس `food_leafy_green`, بندورة `food_tomato`, زبدة `food_butter`.
- **Story:** Food critics and Michelin dreams. Monsieur Pierre's baguette timing meets ستّي's falafel.

### A21. نيويورك `newYork`
- **Currency:** دولار, "$", `ui_heavy_dollar_sign`.
- **Landmark:** `bld_statue_of_liberty`.
- **Sky:** #101820 #26364A #F2A541 #FFE3B0, accent #F2A541.
- **Rival:** بيغ توني (`ppl_man`).
- **Stations:**
  - 0 hotDog هوت دوغ حلال `food_hot_dog` wld/street
  - 1 bagelNy بيغل `food_bagel` wld/bakery
  - 2 pizzaSlice سلايس بيتزا `food_pizza` wld/bakery
  - 3 halalCart صحن العربايّة `food_curry_rice` wld/street
  - 4 falafelTruck فلافل التراك `food_falafel` pal/fried
  - 5 pancakes بانكيك `food_pancakes` wld/sweets
  - 6 icedCoffee قهوة مثلّجة `food_cup_with_straw` wld/drinks [cold]
  - 7 cheesecake تشيز كيك `food_shortcake` wld/sweets
- **Twists:** `deliveryRuns` {intervalMin 8, tripMin 5, rewardMin 8, scooters 3} and `nightMarket` {stations [hotDog, pizzaSlice, halalCart, falafelTruck], startHour 22, endHour 4, nightMult 3}.
- **Rush:** خبز `food_bread`, بيغل `food_bagel`; فلافل `food_falafel`, دجاج `food_poultry_leg`, رز `food_cooked_rice`, صوص أبيض `food_jar`, خس `food_leafy_green`, شطّة `food_hot_pepper`.
- **Story:** Food trucks at 3 a.m. Big Tony's halal cart learns the power of "extra white sauce".

### A22. سانتياغو `santiago`
- **Currency:** بيزو تشيلي, "بيزو", `ui_dollar`.
- **Landmark:** `bld_snow_capped_mountain`.
- **Sky:** #1C2238 #3B4A7A #E06A4A #FFD6B0, accent #2E7D32.
- **Rival:** دون خوسيه (`ppl_older_person`). **Friend:** عمّو إلياس (`ppl_old_man`).
- **Stations:**
  - 0 completo كومبليتو `food_hot_dog` wld/street
  - 1 wheat قمح `food_wheat` wld/bakery
  - 2 empanada إمبانادا `food_dumpling` wld/bakery
  - 3 humitas أوميتاس `food_tamale` wld/dishes
  - 4 cornPie فطيرة ذرة `food_corn` wld/dishes [hot]
  - 5 churrasco ساندويش تشوراسكو `food_sandwich` wld/grill
  - 6 moteHuesillo موتي بالخوخ `food_peach` wld/drinks [cold]
  - 7 clubFalafel فلافل النادي الفلسطيني `food_falafel` pal/fried
- **Twists:** `productionChain` {inputStation wheat, outputStation empanada, ratio 1, outputMult 3, stockCapMin 60} and `vipLounge` {loungeStation clubFalafel, specialIntervalMult 0.5, vipShare 0.5, vipTipMin 20, levelPerTier 40}.
- **Rush:** خبز `food_bread`, صاج `food_flatbread`; لحمة `food_cut_of_meat`, أفوكادو `food_avocado`, بندورة `food_tomato`, زيتون `food_olive`, بيض `food_egg`, ذرة `food_corn`.
- **Story:** The biggest Palestinian community outside the Arab world. Ammo Elias's club hosts a family reunion, and Don José becomes a falafel convert.

### A23. ريو دي جانيرو `rio`
- **Currency:** ريال برازيلي, "ر.ب", `ui_dollar`.
- **Landmark:** `bld_desert_island`.
- **Sky:** #0B3D2E #138A5E #F2C94C #FFF1B8, accent #F2C94C.
- **Rival:** كارلوس (`ppl_man_cook`).
- **Stations:**
  - 0 acai أساي `food_blueberries` wld/sweets [cold]
  - 1 coxinha كوشينيا `food_poultry_leg` wld/fried
  - 2 cheeseBread خبز بالجبنة `food_bread` wld/bakery
  - 3 picanha مشاوي برازيليّة `food_cut_of_meat` wld/grill
  - 4 feijoada فيجوادا `food_beans` wld/dishes [hot]
  - 5 coconutWater ماي جوز هند `food_coconut` wld/drinks [cold]
  - 6 brigadeiro بريغاديرو `food_chocolate_bar` wld/sweets
  - 7 sambaFalafel فلافل السامبا `food_falafel` pal/fried
- **Twists:** `nightMarket` {stations [picanha, brigadeiro, sambaFalafel], startHour 20, endHour 2, nightMult 3} and `weatherSwing` {hotProb 0.55, coldProb 0.05, rainProb 0.15, hotDayStations [acai, coconutWater], coldDayStations [feijoada], mult 2.5}.
- **Rush:** خبز `food_bread`, صاج `food_flatbread`; لحمة `food_cut_of_meat`, جبنة `food_cheese`, أناناس `food_pineapple`, بصل `food_onion`, بندورة `food_tomato`, شطّة `food_hot_pepper`.
- **Story:** Carnival week. Carlos's churrasco grill and your falafel dance till dawn.

### A24. طوكيو `tokyo`
- **Currency:** ين, "¥", `ui_yen`.
- **Landmark:** `bld_tokyo_tower` (decor `bld_mount_fuji`).
- **Sky:** #1B1030 #3E1F5C #E0457B #FFD0DA, accent #E0457B.
- **Rival:** الشيف كينجي (`ppl_man_cook`).
- **Stations:**
  - 0 onigiri أونيغيري `food_rice_ball` wld/street
  - 1 ramen رامن `food_steaming_bowl` wld/dishes [hot]
  - 2 sushi سوشي `food_sushi` wld/seafood
  - 3 tempura تمبورا `food_fried_shrimp` wld/fried
  - 4 dango دانغو `food_dango` wld/sweets
  - 5 bento بنتو `food_bento_box` wld/dishes
  - 6 matcha ماتشا `food_tea` wld/drinks [hot]
  - 7 falafelOmakase فلافل أوماكاسي `food_falafel` pal/fried
- **Twists:** `ovenTiming` {station tempura, windowSec 1.4, perfectMult 3} and `portShipments` {station sushi, intervalHours 4, dockHours 3, targetMin 30, rewardMin 90}.
- **Rush:** رز `food_cooked_rice`, خبز `food_bread`; سمك `ani_fish`, قريدس `food_fried_shrimp`, خيار `food_cucumber`, بيض `food_egg`, أفوكادو `food_avocado`, فلافل `food_falafel`.
- **Story:** The final chapter. Chef Kenji's precision meets ستّي's soul. The epilogue "رجعة عالقدس" follows: the whole family and every rival gather at the first stall.


## Appendix B: Chefs
Skills apply to epic and legendary chefs only (from L22). Skill durations are in active seconds; cooldowns are in real minutes.

| id | Name | Rarity | Art | Cuisine / category | Skill |
|---|---|---|---|---|---|
| samiFryer | سامي القلّاي | common | `ppl_man_cook` | palestinian / fried | — |
| ummMohammad | أم محمد | common | `ppl_woman_headscarf` | palestinian / bakery | — |
| abuAbedFul | أبو العبد الفوّال | common | `ppl_older_person` | palestinian / dishes | — |
| laylaStudent | ليلى طالبة بيرزيت | common | `ppl_woman` | levantine / drinks | — |
| abuSalimSweets | أبو سليم الحلونجي | common | `ppl_old_man` | levantine / sweets | — |
| hassanGrill | حسن الشوّا | common | `ppl_man` | levantine / grill | — |
| nadiaCairo | نادية المصريّة | common | `ppl_woman_cook` | egyptian / street | — |
| mustafaKoshari | مصطفى الكشري | common | `ppl_beard` | egyptian / dishes | — |
| khaledSea | خالد البحري | common | `ppl_man_farmer` | palestinian / seafood | — |
| fatimaMaghreb | فاطمة المغربيّة | common | `ppl_woman_headscarf` | maghrebi / dishes | — |
| muratGrill | مراد التركي | common | `ppl_man_cook` | turkish / grill | — |
| yukiStreet | يوكي | common | `ppl_woman` | world / street | — |
| hajjaUmmSubhi | الحجّة أم صبحي | rare | `ppl_old_woman` | palestinian / dishes | — |
| abuGeorgeHalabi | أبو جورج الحلبي | rare | `ppl_beard` | levantine / grill | — |
| reemCoffee | ريم القهوجيّة | rare | `ppl_woman_office` | gulf / drinks | — |
| abuFahdKabsa | أبو فهد | rare | `ppl_turban` | gulf / dishes | — |
| monaSweets | منى الحلوانيّة | rare | `ppl_woman_cook` | egyptian / sweets | — |
| karimBaghdadi | كريم البغدادي | rare | `ppl_man` | iraqi / bakery | — |
| aminaMsemen | أمينة | rare | `ppl_woman_headscarf` | maghrebi / bakery | — |
| ozanBaklava | أوزان | rare | `ppl_man_cook` | turkish / sweets | — |
| mariaChile | ماريا | rare | `ppl_woman` | world / street | — |
| chefRami | الشيف رامي، ملك الفلافل | epic | `ppl_man_cook` | palestinian / fried | categoryBoost fried ×5, 180 s, cd 45 |
| sittElSham | ستّ الشام | epic | `ppl_woman_cook` | levantine / dishes | cuisineBoost levantine ×4, 240 s, cd 50 |
| abuAliAlex | أبو علي الإسكندراني | epic | `ppl_older_person` | egyptian / seafood | instantIncome 20 min, cd 60 |
| chefNoura | الشيف نورة | epic | `ppl_woman_headscarf` | gulf / sweets | spawnSpecial, cd 30 |
| chefHakim | الشيف حكيم | epic | `ppl_man` | maghrebi / grill | categoryBoost grill ×5, 180 s, cd 45 |
| chefHiro | الشيف هيرو | epic | `ppl_man_cook` | world / seafood | frenzy ×5 60 s, cd 40 |
| chefMaher | الشيف ماهر "رايح جاي" | legendary | `ppl_person_with_crown` | world / street | allBoost ×3, 300 s, cd 60 |
| abuNasser | المعلّم أبو ناصر | legendary | `ppl_old_man` | levantine / grill | allBoost ×2, 600 s, cd 90 |
| sultanaLama | السلطانة لمى | legendary | `ppl_princess` | gulf / drinks | instantIncome 60 min, cd 120 |
| sittiUmmKhalil | ستّي أم خليل (story, graduating Ramallah) | legendary | `ppl_old_woman` | palestinian / any | allBoost ×3, 300 s, cd 60 ("عزومة ستّي") |
| abuSubhiOG | أبو صبحي الأوّلاني (legacy gift) | legendary | `ppl_older_person` | palestinian / fried | categoryBoost fried ×6, 240 s, cd 45 |

Season-exclusive epics (season.json, `themes[n mod 8]`):

| # | Theme | Chef |
|---|---|---|
| 0 | شتويّة الكستنا | `sAbuJiries` أبو جريس الشتوي (`ppl_beard`, palestinian / street, cuisineBoost palestinian ×4 240 s cd 50) |
| 1 | ربيع الزعتر | `sUmmZaatar` أم زعتر (`ppl_woman_farmer`, levantine / bakery, categoryBoost bakery ×5 180 s cd 45) |
| 2 | صيفيّة البحر | `sRayyesBahri` الريّس بحري (`ppl_old_man`, palestinian / seafood, instantIncome 20 min cd 60) |
| 3 | موسم الزيتون | `sAbuZeit` أبو زيت (`ppl_man_farmer`, palestinian / dishes, categoryBoost dishes ×5 180 s cd 45) |
| 4 | ليالي السهر | `sSuhair` سهير (`ppl_singer`, levantine / drinks, frenzy cd 40) |
| 5 | عرس الحارة | `sUmmAlArsan` أم العرسان (`ppl_woman_headscarf`, levantine / sweets, categoryBoost sweets ×5 180 s cd 45) |
| 6 | أسواق العالم | `sRahhal` رحّال (`ppl_pilot`, world / street, spawnSpecial cd 30) |
| 7 | حلويات ستّي | `sBintSitti` بنت ستّي (`ppl_girl`, palestinian / sweets, cuisineBoost palestinian ×4 240 s cd 50) |

## Appendix C: Contracts library (24)
- **Format:** stations are listed as name `art` (cuisine/category). Contracts with 3 stations use side tiers 0–2, those with 4 use tiers 0–3, and the one with 5 uses tiers 0–4.
- **Partners:** NPC names come from the league pool.
- **Shares (sum):** 2 partners 0.30, 3 partners 0.40, 4 partners 0.50.

| # | id | Title | Art | Hours | Stations | Partners | Rule / twist | Goal 3 reward |
|---|---|---|---|---|---|---|---|---|
| 1 | hebronWedding | عرس بالخليل | `bld_wedding` | 72 | منسف `food_cooked_rice` (lev/dishes), كنافة `food_pie` (pal/sweets), عصير `food_tropical_drink` (pal/drinks), قهوة `food_teapot` (gulf/drinks) | 3 | — | heritage case |
| 2 | birzeitGraduation | تخرّج بيرزيت | `ui_scroll` | 48 | كيك `food_birthday_cake` (wld/sweets), بيتزا `food_pizza` (wld/bakery), عصير `food_juice_box` (wld/drinks) | 2 | fastCheap | 3 epic cards chefRami |
| 3 | gazaFishermen | غدا صيّادين غزّة | `veh_motor_boat` | 72 | سمك `ani_fish` (pal/seafood), رز `food_cooked_rice` (pal/dishes), سلطة `food_green_salad` (pal/dishes), شاي `food_tea` (lev/drinks) | 3 | twist portShipments {station سمك} | heritage case |
| 4 | eidOrphans | حلو العيد للأيتام | `ui_gift` | 48 | كعك `food_cookie` (pal/bakery), معمول `food_moon_cake` (pal/sweets), شوكولاتة `food_chocolate_bar` (wld/sweets) | 4 | — | 1 legendary card |
| 5 | iftarSaim | إفطار صايم | `ui_crescent_moon` | 48 | شوربة `food_steaming_bowl` (lev/dishes), مقلوبة `food_maqluba_pan` (pal/dishes), جلّاب `food_cup_with_straw` (lev/drinks), قطايف `food_dumpling` (lev/sweets) | 4 | twist nightMarket {all, 18–23} | heritage case |
| 6 | schoolCanteen | مقصف المدرسة | `bld_school` | 48 | منقوشة `food_flatbread` (lev/bakery), ساندويش فلافل `food_sandwich` (pal/street), عصير `food_juice_box` (wld/drinks) | 2 | noManagers | 3 epic cards (random) |
| 7 | builderLunch | غدا عمّال البنا | `ppl_construction` | 72 | فول `food_beans` (pal/dishes), حمّص `food_hummus_bowl` (pal/dishes), شاي `food_tea` (lev/drinks), خبز `food_bread` (pal/bakery) | 3 | — | heritage case |
| 8 | hospitalNight | مناوبة المستشفى | `bld_hospital` | 48 | قهوة `food_coffee` (wld/drinks), ساندويش `food_sandwich` (wld/street), شوربة `food_steaming_bowl` (lev/dishes) | 2 | twist nightMarket {all, 22–6} | 3 epic cards sittElSham |
| 9 | haraTeam | فريق الحارة | `bld_stadium` | 72 | بطاطا `food_french_fries` (wld/fried), شاورما `food_shawarma_wrap` (lev/street), مي `food_cup_with_straw` (wld/drinks), بوظة `food_ice_cream` (wld/sweets) | 3 | twist busWaves | 1 legendary card |
| 10 | hennaNight | ليلة الحنّة | `ui_hibiscus` | 48 | مهلبيّة `food_custard` (lev/sweets), قهوة `food_teapot` (gulf/drinks), فواكه `food_grapes` (pal/street) | 3 | goldenHour | heritage case |
| 11 | scoutTrip | رحلة الكشّافة | `bld_camping` | 72 | ذرة `food_corn` (lev/street), بطاطا مشويّة `food_roasted_sweet_potato` (lev/street), شاي عالحطب `food_teapot` (lev/drinks), ساندويش `food_sandwich` (wld/street) | 3 | twist weatherSwing {hotProb 0.4, coldProb 0.3, hotDay [ذرة, ساندويش], coldDay [شاي عالحطب, بطاطا مشويّة]} | 3 epic cards (random) |
| 12 | bookFair | معرض الكتاب | `ui_books` | 96 | قهوة `food_coffee` (wld/drinks), كرواسون `food_croissant` (wld/bakery), كعك `food_bagel` (pal/bakery), كيك `food_shortcake` (wld/sweets) | 3 | — | heritage case |
| 13 | oliveCrew | قطّيفة الزيتون | `food_olive` | 96 | زيتون `food_olive` (pal/street), زيت وزعتر `food_herb` (pal/bakery), مسخّن `food_stuffed_flatbread` (pal/dishes), شاي ميرمية `food_tea` (lev/drinks) | 4 | twist productionChain {زيتون → زيت وزعتر} | heritage case (floor rare, oliveWood set) |
| 14 | mukhtarFeast | عزومة المختار | `ppl_older_person` | 72 | منسف `food_cooked_rice` (lev/dishes), مقلوبة `food_maqluba_pan` (pal/dishes), كنافة `food_pie` (pal/sweets), قهوة `food_teapot` (gulf/drinks) | 3 | chefsOff | 1 legendary card |
| 15 | dabkeSquare | دبكة بالساحة | `ui_musical_notes` | 48 | شاورما `food_shawarma_wrap` (lev/street), بطاطا `food_french_fries` (wld/fried), عصير `food_tropical_drink` (pal/drinks) | 3 | twist busWaves | 3 epic cards (random) |
| 16 | kgParty | حفلة الروضة | `ui_balloon` | 48 | كب كيك `food_cupcake` (wld/sweets), عصير `food_juice_box` (wld/drinks), فشار `food_popcorn` (wld/street) | 2 | fastCheap | 3 epic cards (random) |
| 17 | engagement | حفلة خطوبة | `ui_two_hearts` | 72 | كنافة `food_pie` (pal/sweets), شوكولاتة `food_chocolate_bar` (wld/sweets), كيك `food_birthday_cake` (wld/sweets), قهوة `food_teapot` (gulf/drinks) | 3 | — | heritage case |
| 18 | bethlehemMarathon | ماراثون بيت لحم | `ui_sports_medal` | 48 | موز `food_banana` (wld/street), مي `food_cup_with_straw` (wld/drinks), ساندويش `food_sandwich` (wld/street), برتقال `food_tangerine` (pal/street) | 4 | twist busWaves | 1 legendary card |
| 19 | fridayMarket | سوق الجمعة | `veh_shopping_bags` | 96 | فلافل `food_falafel` (pal/fried), كعك `food_bagel` (pal/bakery), عصير قصب `food_cup_with_straw` (egy/drinks), بوظة `food_ice_cream` (wld/sweets) | 3 | — | heritage case |
| 20 | jaffaHisbeh | حسبة يافا | `veh_ship` | 96 | سمك `ani_fish` (pal/seafood), قريدس `food_fried_shrimp` (pal/seafood), ليمون `food_lemon` (pal/drinks), برتقال `food_tangerine` (pal/street) | 3 | twist portShipments {station برتقال} | 3 epic cards abuAliAlex |
| 21 | villageWedding | عرس بالضيعة | `bld_house_with_garden` | 120 | منسف `food_cooked_rice` (lev/dishes), كبّة `food_roasted_sweet_potato` (lev/fried), كنافة `food_pie` (pal/sweets), عصير `food_tropical_drink` (pal/drinks), قهوة `food_teapot` (gulf/drinks) | 4 | — | 1 legendary card |
| 22 | factoryShift | ورديّة المصنع | `bld_factory` | 72 | شاي `food_tea` (lev/drinks), فول `food_beans` (pal/dishes), ساندويش `food_sandwich` (wld/street) | 2 | twist nightMarket {all, 22–6} | heritage case |
| 23 | hummusChallenge | تحدّي الحمّص | `food_hummus_bowl` | 48 | حمّص `food_hummus_bowl` (pal/dishes) | 2 | oneStation | 3 epic cards (random) |
| 24 | beachCamp | مخيّم البحر | `bld_beach_with_umbrella` | 96 | بطّيخ `food_watermelon` (pal/street), ذرة `food_corn` (lev/street), بوظة `food_ice_cream` (wld/sweets), ليموناضة `food_lemon` (lev/drinks) | 3 | twist weatherSwing {hot 0.6, hotDay [بطّيخ, بوظة, ليموناضة]} | heritage case |

`releaseOrder` is the row number. Rules appear in 6 of 24 contracts (25%), and 11 contracts carry a twist.

## Appendix D: Weekend themes
- **Rotation** (non-festival weeks): haraWedding → worldCupNight → oliveHarvest* → schoolCanteen → grapeFestival → knafehFestival → fridayFamily → summerBeach*.
  - *oliveHarvest and summerBeach are skipped outside their festival windows and replaced by the next theme.
- **Festival-only themes:** ramadanNights, eidSweets, eidFeast, bethlehemChristmas.

| id | Name | Event cash | Tokens | Stations (side tiers 0–3) | Twist | Theme chef | Decoration (milestone 10) |
|---|---|---|---|---|---|---|---|
| haraWedding | عرس بالحارة | مصاري العرس `ui_money_bag` | ورود `ui_bouquet` | منسف `food_cooked_rice`, كنافة `food_pie`, عصير `food_tropical_drink`, قهوة `food_teapot` | — | sittElSham | زينة عرس `ui_balloon` |
| worldCupNight | سهرة المونديال | مصاري السهرة `ui_money_bag` | كاسات `ui_trophy` | بطاطا `food_french_fries`, سندويش `food_sandwich`, فشار `food_popcorn`, عصير `food_juice_box` | busWaves {intervalMin 15} | muratGrill | أعلام ملوّنة |
| oliveHarvest | موسم الزيتون | مصاري الموسم `ui_money_bag` | زيتونات `food_olive` | زيتون `food_olive`, زيت وزعتر `food_herb`, مسخّن `food_stuffed_flatbread`, شاي ميرمية `food_tea` | productionChain {زيتون → زيت وزعتر} | abuAbedFul | شجرة زيتون `bld_deciduous_tree` |
| schoolCanteen | مقصف المدرسة | مصروف `ui_money_bag` | دفاتر `ui_notebook` | منقوشة `food_flatbread`, ساندويش فلافل `food_sandwich`, كب كيك `food_cupcake`, عصير `food_juice_box` | — | laylaStudent | يافطة طبشورة |
| grapeFestival | مهرجان العنب | مصاري الكرم `ui_money_bag` | عناقيد `food_grapes` | عنب `food_grapes`, دبس `food_honey`, ملبن `food_candy`, عصير عنب `food_juice_box` | productionChain {عنب → دبس} | abuSalimSweets | عريشة عنب |
| knafehFestival | مهرجان الكنافة | مصاري الكنافة `ui_money_bag` | صواني `food_pie` | قطايف `food_dumpling`, عوّامة `food_doughnut`, كنافة `food_pie` (tier 2), شاي `food_tea` | ovenTiming {كنافة} | ozanBaklava | صينيّة ذهب |
| fridayFamily | عزومة الجمعة | مصاري العيلة `ui_money_bag` | صحون `food_fork_knife_plate` | مقلوبة `food_maqluba_pan`, سلطة `food_green_salad`, لبن `food_milk`, شاي `food_tea` | — | hajjaUmmSubhi | سفرة العيلة |
| summerBeach | صيفيّة عالبحر | مصاري البحر `ui_money_bag` | شموس `ui_sun` | بطّيخ `food_watermelon`, ذرة `food_corn`, بوظة `food_ice_cream`, ليموناضة `food_lemon` | weatherSwing {hotProb 0.8, hotDay [بطّيخ, بوظة, ليموناضة]} | khaledSea | شمسيّة `bld_beach_with_umbrella` |
| ramadanNights | ليالي رمضان | مصاري الخيمة `ui_money_bag` | فوانيس `ui_lantern` | قطايف `food_dumpling`, جلّاب `food_cup_with_straw`, شوربة عدس `food_steaming_bowl`, حليب وتمر `food_milk` | nightMarket {all, 18–3, ×3} | reemCoffee | هلال `ui_crescent_moon` |
| eidSweets | حلو العيد | عيديّة `ui_money_bag` | عيديّات `ui_envelope` | كعك العيد `food_cookie`, معمول `food_moon_cake`, قهوة `food_teapot`, شوكولاتة `food_chocolate_bar` | — | monaSweets | بالونات العيد |
| eidFeast | عزومة الأضحى | مصاري العزومة `ui_money_bag` | خواريف `ani_sheep` | فتّة `food_steaming_bowl`, مشاوي `food_meat_on_bone`, رز `food_cooked_rice`, لبن `food_milk` | — | hassanGrill | زينة العيد |
| bethlehemChristmas | ميلاد بيت لحم | مصاري السوق `ui_money_bag` | نجوم `ui_glowing_star` | كستنا `food_chestnut`, سحلب `food_milk`, كعك `food_cookie`, شوكولاتة ساخنة `food_coffee` | busWaves {intervalMin 20} | ummMohammad | نجمة الميلاد `ui_star` |

## Appendix E: Choice events (40 rows)
- **Notation:** "Nد" = instant income of N minutes (current kitchen). "ك+1" = karma +1. "س" = rep. "خ" = XP.
- **Stakes:** a stake is paid first; listed outcomes are gross.
- **Offline:** rows marked ◐ are `offline.allowed` with `autoChoice` A.
- **Rule:** no outcome is a net loss against declining.

| # | id | Art | Title | Body | A | B |
|---|---|---|---|---|---|---|
| 1 | neighborLoan | `ppl_man` | جارك بدّه دين | أبو العبد بدّه دين لآخر الشهر، بتدينه؟ | "تفضّل" (stake 5د): 70% → 15د + ك+1; 30% → 5د + common heritage + ك+1 | "معلش هسّا لأ" → س5 |
| 2 ◐ | weddingRush | `bld_wedding` | عرس فجأة! | عرس بالحارة وبدّهم 100 سندويشة هسّا! | "يلا نشتغل" → frenzy + 10د | "مش قادرين" → س5 |
| 3 | powerCut | `ui_electric_plug` | الكهربا قطعت | الكهربا قطعت! شو بنعمل؟ | "عالغاز" → ×2 active 3 min + خ5 | "بنستنّى" → 5د (الزباين تركوا بقشيش) |
| 4 | celebrity | `ppl_singer` | مطرب مشهور | مطرب مشهور واقف عالدور! بتعزمه؟ | "عالبيت" → س20 + ×3 active 3 min | "زيّه زيّ الكل" → 15د |
| 5 ◐ | tourGuide | `ppl_person_tipping_hand` | دليل سياحي | دليل بدّه يجيب مجموعته كل يوم | "أهلا وسهلا" → spawnSpecial + س5 | "ما في مكان" → 5د |
| 6 | students | `ppl_person_raising_hand` | طلّاب الجامعة | طلّاب بيرزيت بدّهم خصم طلّاب | "خصم 50%" → س15 + ك+1 + 5د | "بالسعر العادي" → 10د |
| 7 | lostChild | `ppl_child` | ولد ضايع | ولد صغير ضايع وبيعيّط عند البسطة | "بنطعميه وبنستنّى أهله" → ك+2 + س20 + rare heritage | "بنوصّله للشرطة" → ك+1 + س10 |
| 8 | grannyRecipe | `ppl_old_woman` | وصفة قديمة | ختيارة بتعرض عليك وصفة من زمان | "بجرّبها" → 60%: 3 rare cards; 40%: 10د | "يسلموا إيديكي" → ك+1 + خ10 |
| 9 ◐ | rainStorm | `ui_umbrella_with_rain_drops` | شتوة قويّة | الناس محشورة تحت المظلّة من الشتا | "شاي ببلاش" → س15 + ×2 active 5 min | "بنعلّي الراديو" → 5د |
| 10 | foodBlogger | `ui_mobile_phone` | بلوغر أكل | بلوغر بدّه يصوّر صحن | "أحلى صحن عنّا" → 75%: ×3 active 5 min + س10; 25%: س25 | "لا شكراً" → 5د |
| 11 | rivalBorrow | `ppl_man_cook` | الجار محتاج | {rival} خلصت عنده البندورة، بتسلّفه؟ | "أكيد" → ك+1 + س10 + flag rivalFriend | "يدبّر حاله" → 5د |
| 12 ◐ | marketDeal | `veh_lorry` | عرض بالحسبة | تاجر بعرض خضرة بنص السعر | "بشتري" (stake 10د) → 25د | "عندي" → 5د |
| 13 | kidsBirthday | `food_birthday_cake` | عيد ميلاد | أم بدّها فلافل لعيد ميلاد ابنها | "تكرم عينها" → 10د + س10 | "بخصم" → ك+1 + 5د + س15 |
| 14 | radio | `ui_studio_microphone` | مقابلة إذاعة | إذاعة محليّة بدها مقابلة معك | "بحكي عن ستّي" → س25 + storyScene | "بحكي عن العروض" → frenzy |
| 15 | oudPlayer | `ui_musical_notes` | عازف عود | عازف بدّه يعزف جنب البسطة | "أهلا فيه" → ×2 active 5 min | "سندويشة وشكراً" → ك+1 + س5 |
| 16 | oldFriend | `ppl_handshake` | صاحب قديم | صاحبك من المدرسة رجع من الغربة | "عالحساب" → ك+1 + س10 + rare heritage | "بنسولف شوي" → 5د + خ10 |
| 17 | haraCat | `ani_cat` | قطّة الحارة | قطّة الحارة قاعدة عند البسطة | "بنطعميها" → ك+1; the 3rd time grants decoration propCat | "بلطف بنبعدها" → 3د |
| 18 | lostWallet | `ui_money_bag` | محفظة ضايعة | لقيت محفظة فيها مصاري | "بدوّر على صاحبها" → ك+2 + س20 + 10د (مكافأة) | "للشرطة" → ك+1 + س10 |
| 19 ◐ | officeOrder | `bld_office_building` | طلبيّة شركة | شركة بدّها 50 صحن عالغدا | "بنوصّلها" → 20د | "مش اليوم" → 3د |
| 20 | farmerFresh | `ppl_man_farmer` | حمّص بلدي | فلّاح جايب حمّص بلدي طازة | "بشتري كلّه" (stake 5د) → palestinian stations ×2 for 30 min (day) | "شوي بس" → 5د |
| 21 | tvShow | `ui_television` | برنامج طبخ | برنامج طبخ بدّه يستضيفك | "أكيد!" → س30 + 3 rare cards | "مش وقته" → 5د |
| 22 ◐ | schoolBus | `bld_school` | رحلة مدرسة | باص رحلة وقف قدّام البسطة | "سندويشات للكل" → 15د + س10 | "عصير بس" → 8د + ك+1 |
| 23 | poet | `ui_scroll` | شاعر الحارة | شاعر بدّه يكتب قصيدة عن فلافلك | "اسمعنا!" → س20 + خ20 | "بدّي نسخة" → common heritage (memories set) |
| 24 | eatChallenge | `ppl_flexed_biceps` | تحدّي أكل | شب بتحدّى ياكل 20 قرص فلافل | "إذا خلّصهم ببلاش" → 50%: س30 + ×2 active 5 min; 50%: 15د | "ممنوع التحدّي" → 5د |
| 25 | lanternMaker | `ui_lantern` | صانع فوانيس (Ramadan) | صانع فوانيس بعرض فانوس للبسطة | "بشتريه" (stake 5د) → today's فانوس collected ×2 + س10 | "بتفرّج بس" → 5د |
| 26 | eidKids | `ppl_child` | أولاد العيد (Eid) | أولاد الحارة بدّهم عيديّة | "عيديّة لكل واحد" → ك+2 + س20 + خ20 | "قطعة حلو" → ك+1 + س10 |
| 27 | oliveHelp | `food_olive` | قطف الزيتون (olive season) | جارك بدّه مساعدة بقطف الزيتون | "بروح أساعد" → 1 oliveWood item (30% rare) | "ببعتله أكل" → ك+1 + س10 |
| 28 | choir | `ui_musical_notes` | كورال الميلاد (Christmas) | كورال بغنّي بالساحة | "سحلب للكورال" → س15 + frenzy | "منسمع بس" → 5د |
| 29 | heatWave | `ui_thermometer` | شوب! (hot day) | الدنيا شوب والناس بدها إشي بارد | "مي ببلاش" → س15 + ك+1 | "عصير بسعر خاص" → cold stations ×2 for 30 min |
| 30 | snowDay | `ui_snowflake` | تلج! (cold day) | التلج نازل والمدينة واقفة | "سحلب للكل" → س15 + hot stations ×2 for 30 min | "بنسكّر بكّير" → 10د |
| 31 ◐ | journalist | `ui_newspaper` | صحفي | صحفي بكتب عن أحسن البسطات | "بفرجيه المطبخ" → س25 | "سندويشة وبس" → 8د |
| 32 | apprentice | `ppl_boy` | صبي متدرّب | ولد بدّه يتعلّم الشغل بالصيف | "تعال تعلّم" → 3 common cards + ك+1 | "بتساعد بالتنظيف" → 5د + خ10 |
| 33 ◐ | tourPhoto | `ui_camera` | سايح بصوّر | سايح بدّه صورة مع البسطة | "أهلين!" → س10 + spawnSpecial | "صوّرني كمان" → خ10 + 5د |
| 34 | secretSpice | `food_herb` | بهار سرّي | عطّار بعرض بهار سرّي | "بجرّبه" (stake 10د) → 60%: 30د; 40%: 8د + س10 | "عالقديم" → 5د |
| 35 | rivalRace | `ppl_man_cook` | تحدّي الجار | {rival} بتحدّاك: مين أسرع ساندويشة؟ | "يلا!" → free rush round (no ticket) | "مرّة تانية" → س5 |
| 36 | elderMeal | `ppl_older_person` | ختيار جوعان | ختيار ما معه حقّ الأكل | "عالبيت يا حج" → ك+2 + خ20 + س10 | "بنص السعر" → ك+1 + 5د |
| 37 ◐ | cupWinners | `ui_trophy` | الأبطال! | فريق الحارة ربح الكاس وجايين يحتفلوا | "أكلة على حسابي" → س30 + ك+1 | "خصم للأبطال" → 15د |
| 38 | nightGuard | `ppl_guard` | حارس الليل (22:00–04:00) | الحارس الليلي بدّه شاي وسندويشة | "بالهنا" → ك+1 + س10 | "بالحساب" → 5د |
| 39 | lostTourist | `ppl_woman` | سايحة ضايعة | سايحة بتسأل عن الطريق | "بوصّلها" → س15 + ك+1 | "بشرحلها" → 5د + خ5 |
| 40 | grandmaCall | `ppl_old_woman` | تلفون من ستّي | ستّي عالتلفون: ابعتلي صحن من أكلك | "أحلى صحن لستّي" → خ30 + storyScene | "بزورها بكرة" → ك+1 + time warp 30 min |

**Karma follow-ups (content rule):** at karma ≥ 5, 10 and 20, the street visitor "الجار المبتسم" brings a rare heritage item, 3 epic cards, or the decoration "بوكيه ورد" (once each).

## Appendix F: Daily market modifiers (market.json)
All modifiers last the game day. Each has a 5-day cooldown. `festive` rows are excluded on quiet dates.

| id | Name | Effect | Weight | Notes |
|---|---|---|---|---|
| doubleDay | يوم الدبل | all kitchens income ×2 (day) | 5 | festive |
| hummusDay | يوم الحمّص | category dishes ×3 | 8 | |
| friedFriday | مقالي الجمعة | category fried ×3 | 8 | Friday only |
| sweetsDay | يوم الحلو | category sweets ×3 | 8 | |
| drinksDay | عصير وبس | category drinks ×3 | 8 | |
| bakeryDay | خبز طازة | category bakery ×3 | 8 | |
| grillDay | ريحة شوي | category grill ×3 | 6 | |
| seafoodDay | سمك طازة | category seafood ×3 | 5 | |
| managerSale | خصم المعلّمين | manager cost ×0.5 | 6 | |
| levelSale | أوكازيون | station level cost ×0.75 | 6 | |
| researchSale | بحث بنص السعر | research cost ×0.5 | 6 | |
| researchFast | دفتر سريع | research started today −25% time | 6 | |
| supplyDouble | رحلات دبل | rolls ×2 for runs sent today | 5 | |
| supplyFast | طرق فاضية | supply time ×0.75 for runs sent today | 6 | |
| specialRush | زباين كتير | special interval ×0.6 | 6 | |
| ticketGift | تذكرة ببلاش | +1 ticket on first open | 6 | |
| vaultBoost | خزنة كريمة | vault efficiency +25% (cap 1.0) | 5 | |
| chefStallSale | بسطة الطبّاخين بخصم | chef offers −30% | 4 | |

## Appendix G: Heritage (8 sets × 4 items)
Rarity pattern: sets 1–4 are [C, C, R, E]; sets 5–8 are [C, R, E, L].

| Set | Items (id name art rarity) | Bonus |
|---|---|---|
| glass زجاج الخليل | blueBall كرة زجاج زرقا `ui_crystal_ball` C · glassJar مرطبان زجاج `food_jar` C · blueBead خرزة زرقا `ui_gem` R · glassLamp قنديل زجاج `ui_lantern` E | city income +10% |
| soap صابون نابلس | soapBar قالب صابون `food_butter` C · oliveOil زيت زيتون `ui_droplet` C · soapFoam رغوة الصابون `ui_sparkles` R · factoryStamp ختم المصبنة `ui_label` E | vault cap +1 h |
| tatreez تطريز فلّاحي | stitchFlower وردة مطرّزة `ui_hibiscus` C · stitchCarnation قرنفلة `ui_tulip` C · threadColors خيطان ملوّنة `ui_artist_palette` R · bridalPanel قبّة ثوب العرس `ui_bouquet` E | chef bonuses +10% |
| pearl صدف بيت لحم | pearlStar نجمة صدف `ui_star` C · pearlRosary مسبحة صدف `ui_shooting_star` C · pearlBox علبة صدف `ui_dizzy` R · pearlNativity مغارة الصدف `ui_glowing_star` E | special and happening rewards +20% |
| pottery فخّار غزّة | clayPot قدرة فخّار `food_pot` C · clayJug إبريق فخّار `ui_alembic` R · clayOven فرن الطين `bld_hut` E · honeyJar جرّة عسل قديمة `food_honey` L | supply time −5% |
| oliveWood خشب الزيتون | woodOlive زيتونة خشب `food_olive` C · oliveBoard لوح زيتون `bld_wood` R · oliveBeads مسبحة زيتون `ui_link` E · romanTree الزيتونة الرومانيّة `bld_deciduous_tree` L | research time −5% |
| copper نحاس وقهوة | coffeeCup فنجان قهوة `food_coffee` C · copperDallah دلّة نحاس `food_teapot` R · copperBell جرس نحاس `ui_bellhop_bell` E · brassScale ميزان نحاس `ui_balance_scale` L | side-kitchen income +15% |
| memories صندوق الذكريات | grandpaLetter رسالة من سيدي `ui_envelope` C · familyPhoto صورة العيلة `ui_camera` R · oldDeed ورقة الدار القديمة `ui_scroll` E · houseKey مفتاح دار سيدي `ui_old_key` L | branch gold +15% |


## Appendix H: Empire levels 1–100
`xpToNext(L) = 5·round(15·L^1.36/5)`. Gold and chests follow 4.3. Titles are in the last column. Unlocks marked `storyMemory` play a short ستّي memory scene (story.json `memory_L{n}`) and grant 1 rare heritage item.

| L | XP to next | Cumulative | Gold | Chest | Extra | Unlock | Title |
|---|---|---|---|---|---|---|---|
| 1 | 15 | 0 | — | — | — | المطبخ والأهداف (FTUE) | بيّاع عالبسطة |
| 2 | 40 | 15 | 10 | — | — | المعلّمين |  |
| 3 | 65 | 55 | 10 | — | — | الزبون المميّز + الترقيات |  |
| 4 | 100 | 120 | 10 | — | — | الطبّاخين والصناديق + الدكان + خانة طبّاخ 1 |  |
| 5 | 135 | 220 | 10 | خشب | — | ساعات الذروة + الخزنة | صاحب عربايّة |
| 6 | 170 | 355 | 10 | — | — | الخريطة والتخرّج |  |
| 7 | 210 | 525 | 10 | — | — | دفتر ستّي (خانة 1) |  |
| 8 | 255 | 735 | 10 | — | — | رحلات التوريد (خانة 1) + صندوق التراث + خانة طبّاخ 2 |  |
| 9 | 300 | 990 | 10 | — | — | المهام اليوميّة + الروزنامة + السلسلة |  |
| 10 | 345 | 1290 | 10 | فضّة | رزمة وقت 1س | حكايات الحارة + الجريدة + خانة رحلة 2 | معلّم فلافل |
| 11 | 390 | 1635 | 15 | — | — | طلبيات على السريع + التذاكر |  |
| 12 | 440 | 2025 | 15 | — | — | الدوري |  |
| 13 | 490 | 2465 | 15 | — | — | سوق اليوم والطقس |  |
| 14 | 545 | 2955 | 15 | — | — | الطلبيات (خانة 1) |  |
| 15 | 595 | 3500 | 15 | خشب | — | مهرجان الويكند + خانة طبّاخ 3 | صاحب كشك |
| 16 | 650 | 4095 | 15 | — | — | الموسم + خانة رحلة 3 |  |
| 17 | 705 | 4745 | 15 | — | — | ترقية الفروع |  |
| 18 | 765 | 5450 | 15 | — | — | مفتّش البلديّة |  |
| 19 | 825 | 6215 | 15 | — | — | صنعة التراث |  |
| 20 | 880 | 7040 | 15 | فضّة | رزمة وقت 1س | خانة بحث 2 + درجة 2 | معلّم حمّص |
| 21 | 945 | 7920 | 15 | — | — | زبون جديد بالشارع: المعلّمة (`ppl_teacher`) |  |
| 22 | 1005 | 8865 | 15 | — | — | مهارات الطبّاخين |  |
| 23 | 1065 | 9870 | 15 | — | — | زبون جديد بالشارع: الممرّض (`ppl_health_worker`) |  |
| 24 | 1130 | 10935 | 15 | — | — | رزم الوقت بالدكان |  |
| 25 | 1195 | 12065 | 15 | خشب | 3 كروت أسطوريّة | خانة طبّاخ 4 | صاحب دكّانة |
| 26 | 1260 | 13260 | 15 | — | — | ديكور: مظلّة زيتي (`awningOlive`) |  |
| 27 | 1325 | 14520 | 15 | — | — | زبون جديد بالشارع: الميكانيكي (`ppl_mechanic`) |  |
| 28 | 1395 | 15845 | 15 | — | — | ديكور: أصيص نعنع (`propMint`) |  |
| 29 | 1460 | 17240 | 15 | — | — | زبون جديد بالشارع: الطيّار (`ppl_pilot`) |  |
| 30 | 1530 | 18700 | 15 | فضّة | رزمة وقت 1س | خانة طلبيّة 2 | طبّاخ الحارة |
| 31 | 1600 | 20230 | 20 | — | — | زبون جديد بالشارع: الرسّام (`ppl_artist`) |  |
| 32 | 1670 | 21830 | 20 | — | — | ديكور: إضاءة فوانيس (`lightsLanterns`) |  |
| 33 | 1745 | 23500 | 20 | — | — | زبون جديد بالشارع: الدكتورة (`ppl_scientist`) |  |
| 34 | 1815 | 25245 | 20 | — | — | ديكور: يافطة نحاس (`signCopper`) |  |
| 35 | 1890 | 27060 | 20 | خشب | — | تذكرة رابعة + درجة 3 | مشهور بالبلد |
| 36 | 1960 | 28950 | 20 | — | — | ديكور: قطّة الحارة (`propCat`) |  |
| 37 | 2035 | 30910 | 20 | — | — | زبون جديد بالشارع: الفلّاح (`ppl_farmer`) |  |
| 38 | 2110 | 32945 | 20 | — | — | ديكور: مظلّة تطريز (`awningTatreez`) |  |
| 39 | 2185 | 35055 | 20 | — | — | زبون جديد بالشارع: الفلّاحة (`ppl_woman_farmer`) |  |
| 40 | 2265 | 37240 | 20 | فضّة | رزمة وقت 1س | خانة طبّاخ 5 | صاحب مطعم |
| 41 | 2340 | 39505 | 20 | — | — | زبون جديد بالشارع: المبرمج (`ppl_technologist`) |  |
| 42 | 2420 | 41845 | 20 | — | — | ديكور: جرس نحاس (`propBell`) |  |
| 43 | 2500 | 44265 | 20 | — | — | زبون جديد بالشارع: عامل البنا (`ppl_construction`) |  |
| 44 | 2575 | 46765 | 20 | — | — | ديكور: إضاءة نجوم (`lightsStars`) |  |
| 45 | 2655 | 49340 | 20 | فضّة | — | تجميدة تالتة | معلّم المعلّمين |
| 46 | 2740 | 51995 | 20 | — | — | ديكور: يافطة خط عربي (`signCalligraphy`) |  |
| 47 | 2820 | 54735 | 20 | — | — | زبون جديد بالشارع: صاحب الكلب (`ani_dog`) |  |
| 48 | 2900 | 57555 | 20 | — | — | ديكور: دوّار الشمس (`propSunflower`) |  |
| 49 | 2985 | 60455 | 20 | — | — | زبون جديد بالشارع: المطرب (`ppl_singer`) |  |
| 50 | 3065 | 63440 | 20 | ذهب | رزمة وقت 1س، 3 كروت أسطوريّة | ديكور: مظلّة سماوي (`awningSky`) | شيف المدينة |
| 51 | 3150 | 66505 | 20 | — | — | زبون جديد بالشارع: الموظّفة (`ppl_office`) |  |
| 52 | 3235 | 69655 | 20 | — | — | ديكور: شجرة زيتون صغيرة (`propOliveTree`) |  |
| 53 | 3320 | 72890 | 20 | — | — | زبون جديد بالشارع: ولد بزي بطل (`ppl_superhero`) |  |
| 54 | 3405 | 76210 | 20 | — | — | ديكور: إضاءة شموع (`lightsCandles`) |  |
| 55 | 3490 | 79615 | 20 | فضّة | — | درجة 4 | صاحب فروع |
| 56 | 3580 | 83105 | 20 | — | — | ديكور: يافطة قيشاني (`signTiles`) |  |
| 57 | 3665 | 86685 | 20 | — | — | زبون جديد بالشارع: بنت بزي أميرة (`ppl_princess`) |  |
| 58 | 3755 | 90350 | 20 | — | — | ديكور: ديك الحارة (`propRooster`) |  |
| 59 | 3840 | 94105 | 20 | — | — | زبون جديد بالشارع: المحقّق (`ppl_detective`) |  |
| 60 | 3930 | 97945 | 20 | ذهب | رزمة وقت 1س | خانة طبّاخ 6 | تاجر الشام |
| 61 | 4020 | 101875 | 25 | — | — | زبون جديد بالشارع: عيلة مع بيبي (`ppl_baby`) |  |
| 62 | 4110 | 105895 | 25 | — | — | ديكور: مظلّة كوفيّة (`awningKeffiyeh`) |  |
| 63 | 4200 | 110005 | 25 | — | — | زبون جديد بالشارع: طالب الجامعة (`ppl_person_raising_hand`) |  |
| 64 | 4290 | 114205 | 25 | — | — | ديكور: بوكيه ورد (`propBouquet`) |  |
| 65 | 4380 | 118495 | 25 | فضّة | — | زبون جديد بالشارع: الجار المبتسم (`ppl_waving_hand`) | نجم المطابخ |
| 66 | 4475 | 122875 | 25 | — | — | ديكور: إضاءة قلوب (`lightsHearts`) |  |
| 67 | 4565 | 127350 | 25 | — | — | زبون جديد بالشارع: المدير (`ppl_man_office`) |  |
| 68 | 4660 | 131915 | 25 | — | — | ديكور: يافطة نيون (`signNeon`) |  |
| 69 | 4755 | 136575 | 25 | — | — | ديكور: أصيص توليب (`propTulips`) |  |
| 70 | 4845 | 141330 | 25 | ذهب | رزمة وقت 1س | خانة بحث 3 | ملك الصاج |
| 71 | 4940 | 146175 | 25 | — | — | ديكور: مظلّة ليلكي (`awningLilac`) |  |
| 72 | 5035 | 151115 | 25 | — | — | ديكور: نخلة صغيرة (`propPalm`) |  |
| 73 | 5130 | 156150 | 25 | — | — | ديكور: بالونات (`lightsBalloons`) |  |
| 74 | 5225 | 161280 | 25 | — | — | ديكور: مظلّة الغروب (`awningSunset`) |  |
| 75 | 5325 | 166505 | 25 | فضّة | 3 كروت أسطوريّة | ديكور: صبّارة (`propCactus`) | شيخ الطبّاخين |
| 76 | 5420 | 171830 | 25 | — | — | ديكور: مظلّة ملكيّة (`awningRoyal`) |  |
| 77 | 5515 | 177250 | 25 | — | — | ديكور: برسيم الحظ (`propClover`) |  |
| 78 | 5615 | 182765 | 25 | — | — | ديكور: يافطة ذهب (`signGold`) |  |
| 79 | 5715 | 188380 | 25 | — | — | ديكور: إطار زيتون (`frameOlive`) |  |
| 80 | 5810 | 194095 | 25 | ذهب | رزمة وقت 1س | درجة 5 | سفير الفلافل |
| 81 | 5910 | 199905 | 25 | — | — | ديكور: إطار ذهبي (`frameGold`) |  |
| 82 | 6010 | 205815 | 25 | — | — | ذكرى من ستّي: مشهد قصّة قصير + قطعة تراث نادرة (`storyMemory`) |  |
| 83 | 6110 | 211825 | 25 | — | — | ذكرى من ستّي: مشهد قصّة قصير + قطعة تراث نادرة (`storyMemory`) |  |
| 84 | 6210 | 217935 | 25 | — | — | ذكرى من ستّي: مشهد قصّة قصير + قطعة تراث نادرة (`storyMemory`) |  |
| 85 | 6310 | 224145 | 25 | ذهب | — | ذكرى من ستّي: مشهد قصّة قصير + قطعة تراث نادرة (`storyMemory`) | أسطورة السوق |
| 86 | 6410 | 230455 | 25 | — | — | ذكرى من ستّي: مشهد قصّة قصير + قطعة تراث نادرة (`storyMemory`) |  |
| 87 | 6515 | 236865 | 25 | — | — | ذكرى من ستّي: مشهد قصّة قصير + قطعة تراث نادرة (`storyMemory`) |  |
| 88 | 6615 | 243380 | 25 | — | — | ذكرى من ستّي: مشهد قصّة قصير + قطعة تراث نادرة (`storyMemory`) |  |
| 89 | 6720 | 249995 | 25 | — | — | ذكرى من ستّي: مشهد قصّة قصير + قطعة تراث نادرة (`storyMemory`) |  |
| 90 | 6820 | 256715 | 25 | ذهب | رزمة وقت 1س | خانة رحلة 4 | إمبراطور الحمّص |
| 91 | 6925 | 263535 | 25 | — | — | ذكرى من ستّي: مشهد قصّة قصير + قطعة تراث نادرة (`storyMemory`) |  |
| 92 | 7030 | 270460 | 25 | — | — | ذكرى من ستّي: مشهد قصّة قصير + قطعة تراث نادرة (`storyMemory`) |  |
| 93 | 7130 | 277490 | 25 | — | — | ذكرى من ستّي: مشهد قصّة قصير + قطعة تراث نادرة (`storyMemory`) |  |
| 94 | 7235 | 284620 | 25 | — | — | ذكرى من ستّي: مشهد قصّة قصير + قطعة تراث نادرة (`storyMemory`) |  |
| 95 | 7340 | 291855 | 25 | ذهب | — | ذكرى من ستّي: مشهد قصّة قصير + قطعة تراث نادرة (`storyMemory`) | إمبراطور الفلافل |
| 96 | 7445 | 299195 | 25 | — | — | ذكرى من ستّي: مشهد قصّة قصير + قطعة تراث نادرة (`storyMemory`) |  |
| 97 | 7555 | 306640 | 25 | — | — | ذكرى من ستّي: مشهد قصّة قصير + قطعة تراث نادرة (`storyMemory`) |  |
| 98 | 7660 | 314195 | 25 | — | — | ذكرى من ستّي: مشهد قصّة قصير + قطعة تراث نادرة (`storyMemory`) |  |
| 99 | 7765 | 321855 | 25 | — | — | ذكرى من ستّي: مشهد قصّة قصير + قطعة تراث نادرة (`storyMemory`) |  |
| 100 | 8000 (100+) | 329620 | 25 | ذهب | رزمة وقت 1س، 3 كروت أسطوريّة | لقب سلطان البسطات + بسطة ذهبيّة | سلطان البسطات |


## Appendix I: Achievements (30 families × 5 tiers = 150)
Tier rewards: gold 5/10/15/25/40, XP 20/40/80/150/250. Art is the family icon.

| # | id | Name | Art | Metric (lifetime) | Tiers |
|---|---|---|---|---|---|
| 1 | handCook | طبّاخ بإيده | `ppl_man_cook` | tap-cooks | 100 / 1k / 5k / 20k / 100k |
| 2 | customers | زباين وبس | `ppl_raising_hands` | customers served | 1k / 100k / 10M / 1B / 100B |
| 3 | stars | نجوم المعلّم | `ui_star` | stars earned | 10 / 50 / 200 / 500 / 1,000 |
| 4 | cities | مسافر | `bld_world_map` | cities graduated | 1 / 4 / 8 / 16 / 23 |
| 5 | crowns | تيجان | `ui_crown` | crowned cities | 1 / 5 / 10 / 18 / 24 |
| 6 | level | مستوى المعلّم | `ui_sparkles` | empire level | 10 / 25 / 50 / 75 / 100 |
| 7 | managers | صاحب شغل | `ppl_handshake` | managers hired | 10 / 50 / 100 / 150 / 180 |
| 8 | upgrades | مستثمر | `ui_chart_up` | cash upgrades bought | 5 / 25 / 75 / 150 / 250 |
| 9 | maxStations | للآخر | `ui_top_arrow` | stations at cap | 1 / 10 / 30 / 80 / 150 |
| 10 | chefsOwned | فريق الطبخ | `ppl_cook` | chefs owned | 5 / 10 / 18 / 25 / 32 |
| 11 | chefLevel | معلّم الطبّاخين | `ui_glowing_star` | highest chef level reached ≥ N (count of chefs at L10 for tier 5) | L3 / L5 / L7 / L10 / 5 chefs at L10 |
| 12 | chests | فتّاح الصناديق | `ui_gift` | chests opened | 10 / 50 / 150 / 400 / 1,000 |
| 13 | research | دفتر ستّي | `ui_notebook` | research levels | 5 / 25 / 75 / 150 / 302 |
| 14 | runs | راعي رحلات | `veh_pickup_truck` | supply runs claimed | 5 / 25 / 100 / 300 / 1,000 |
| 15 | heritage | حارس التراث | `ui_old_key` | unique heritage items | 4 / 12 / 20 / 28 / 32 |
| 16 | sets | المجموعة كاملة | `ui_puzzle_piece` | sets completed | 1 / 2 / 4 / 6 / 8 |
| 17 | contracts | معلّم طلبيات | `ui_clipboard` | contracts with goal 3 | 1 / 5 / 15 / 30 / 60 |
| 18 | events | نجم المهرجان | `ui_party_popper` | events with milestone 10 | 1 / 3 / 8 / 15 / 30 |
| 19 | league | ابن الدوري | `ui_trophy` | best league tier | 2 / 4 / 6 / 8 / 10 |
| 20 | season | ابن الموسم | `ui_ticket` | seasons finished (tier 50) | 1 / 2 / 4 / 6 / 10 |
| 21 | streak | نار ما بتنطفي | `ui_fire` | best streak | 7 / 30 / 100 / 200 / 365 |
| 22 | calendar | ابن الروزنامة | `ui_spiral_calendar` | calendar claims | 7 / 28 / 84 / 168 / 336 |
| 23 | dailyOrders | شغّيل | `ui_check_mark_button` | daily orders done | 10 / 50 / 200 / 500 / 1,000 |
| 24 | specials | صياد الزباين | `ui_bellhop_bell` | special customers tapped | 10 / 50 / 200 / 500 / 1,500 |
| 25 | stories | حكواتي | `ui_speech_balloon` | choice events answered | 5 / 25 / 75 / 150 / 300 |
| 26 | rush | على السريع | `ui_stopwatch` | rush rounds played | 5 / 25 / 100 / 250 / 500 |
| 27 | zaatar | زعتر ذهبي | `food_herb` | Golden Za'atar | 1 / 5 / 15 / 30 / 50 |
| 28 | branches | صاحب فروع | `bld_department_store` | total branch levels | 5 / 20 / 50 / 100 / 230 |
| 29 | festivals | ابن المواسم | `ui_lantern` | festival instances played | 1 / 3 / 5 / 8 / 12 |
| 30 | karma | قلب طيّب | `ui_red_heart` | karma | 3 / 10 / 20 / 40 / 80 |

## Appendix J: Calendar and streak
**28-day track (cycle 1).** Gold amounts scale by `1 + 0.1 × (cycle − 1)`, max ×2.

| Day | Reward | Day | Reward |
|---|---|---|---|
| 1 | 10 gold | 15 | 15 gold |
| 2 | 2 tickets | 16 | 5 rare cards |
| 3 | wood chest | 17 | 2 tickets |
| 4 | 10 gold | 18 | 20 gold |
| 5 | 3 rare cards | 19 | rare heritage item |
| 6 | 1 h time warp | 20 | 2 h time warp |
| 7 | silver chest | 21 | gold chest |
| 8 | 15 gold | 22 | 15 gold |
| 9 | common heritage item | 23 | 2 tickets |
| 10 | 2 tickets | 24 | wood chest |
| 11 | 15 gold | 25 | 2 epic cards |
| 12 | wood chest | 26 | 20 gold |
| 13 | 2 h time warp | 27 | 4 h time warp |
| 14 | silver chest + streak freeze | 28 | **1 Golden Za'atar** + silver chest |

Gold per cycle: 120.

**Streak milestones** (reward on reaching the count):

| Streak | Reward |
|---|---|
| 3 | 10 gold |
| 7 | 20 gold + freeze + silver chest |
| 14 | 30 gold + freeze |
| 30 | gold chest + flame frame |
| 50 | 3 epic cards |
| 100 | 1 legendary card + "نار المعلّم" decoration |
| 200 | 150 gold + gold chest |
| 365 | "بسطة السنة" golden awning + 365 gold |

## Appendix K: Season pass (50 tiers × 140 points)
"Season chef" is the season's exclusive epic (Appendix B).

| Tier | Reward | Tier | Reward |
|---|---|---|---|
| 1 | 10 gold | 26 | 10 gold |
| 2 | wood chest | 27 | wood chest |
| 3 | 2 tickets | 28 | 3 rare cards |
| 4 | 1 h time warp | 29 | 10 gold |
| 5 | silver chest | 30 | gold chest |
| 6 | 10 gold | 31 | 2 tickets |
| 7 | 3 rare cards | 32 | 2 h time warp |
| 8 | rare heritage item | 33 | 10 gold |
| 9 | 10 gold | 34 | epic heritage item |
| 10 | season chef ×1 (unlock card) + season frame | 35 | season chef ×4 |
| 11 | wood chest | 36 | 10 gold |
| 12 | 2 tickets | 37 | wood chest |
| 13 | 10 gold | 38 | streak freeze |
| 14 | 1 h time warp | 39 | 10 gold |
| 15 | 20 gold | 40 | 20 gold |
| 16 | 3 rare cards | 41 | 2 tickets |
| 17 | wood chest | 42 | 4 h time warp |
| 18 | rare heritage item | 43 | silver chest |
| 19 | 10 gold | 44 | 10 gold |
| 20 | heritage case | 45 | season chef ×6 |
| 21 | 2 tickets | 46 | heritage case |
| 22 | 10 gold | 47 | 10 gold |
| 23 | 2 h time warp | 48 | 3 epic cards |
| 24 | silver chest | 49 | 20 gold |
| 25 | season chef ×5 (reaches L3) + season awning | 50 | 5 legendary cards (random) + "بسطة الموسم" decoration + title frame "بطل الموسم" |

Gold per season: 190, so section 5.2 uses ≈ 4.5/day.

## Appendix L: League names and avatars (league.json)
**Fixed names (30)** (keys are lowercase transliterations, e.g. `abuShaker`, `falafelAlAmana`):
مطعم أبو شاكر · فلافل الأمانة · حمّص الملك · سناك الضيعة · مشاوي الخيمة · بسطة الفرح · كشك النجمة · فلافل على كيفك · فول أبو العبد · مطعم الدوّار · شاورما الريم · كنافة الأصيل · بيت الحمّص · مطبخ ستّ الدار · عربايّة أبو زيد · ملك الطعميّة · فلافل عالماشي · مطعم الطيّبين · حمّص ودقّة · بسطة الخير · أبو صالح للفلافل · مشاوي السلطان · سندويشات المدينة · مطعم الكرم · كشك الحبايب · فطاير أم علي · منقوشة وبس · بيت الكبّة · مطعم سما · الطاحونة

**Generated names:** `prefix + " " + suffix`, deterministic, never duplicating a fixed name. That gives 10 × 14 = 140 combinations.
- Prefixes: فلافل، حمّص، مطعم، بسطة، كشك، مشاوي، شاورما، فطاير، كنافة، سناك
- Suffixes: الهنا، الوادي، الربيع، السعادة، الدار، الجبل، البلد، الجامعة، المحطّة، القمر، النجوم، الأصدقاء، الحارة، البحر

**Avatars:** `food_falafel`, `food_hummus_bowl`, `food_shawarma_wrap`, `food_pie`, `food_sandwich`, `food_stuffed_flatbread`, `food_meat_on_bone`, `food_tea`, `ppl_man_cook`, `ppl_woman_cook`, `ppl_cook`, `ppl_old_man`, `ppl_beard`, `ppl_woman_headscarf`, `ppl_man`, `ppl_woman`.

**Info sheet** on tap: "مطعم وهمي من اللعبة. بلعب بالدوري زيّك." Archetypes are listed in 6.7.
