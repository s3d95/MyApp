# Falafel Empire v3 (إمبراطورية الفلافل): Design Research Brief

**About the evidence.** This brief draws on six research reports: idle meta-progression, restaurant and farm tycoons, live-ops and retention, economy math, UX and juice, and variety mechanics.
- WebFetch was blocked, so most web facts come from search-result excerpts.
- The numbers the design depends on were checked in two ways:
  - against shipped code or data: Cookie Clicker `main.js`, AdVenture Capitalist calculator data, the Antimatter Dimensions source, 1,256 decoded Egg, Inc. contracts, and the CorsixTH, OpenTTD and OpenRCT2 sources;
  - against a pacing simulator at `/tmp/claude-0/-home-user-MyApp/152624f1-659b-5de9-865b-3f5172424bf2/scratchpad/econ/idlesim.py`.
- Retention and download figures for the genre are directional only.

---

## 1. Why v2 fails

1. **Prestige pays about 150× too much.**
   - v2 pays stars = √(E/1e6) at +2% each, with r = 1.07 on every station.
   - At 1e15 lifetime earnings that is ×634. AdVenture Capitalist pays ×4 at the same point (angels = 150·√(E/1e15)).
   - The first star arrives at $1M, a few minutes into play.
   - When payouts are close to linear, every reset compounds into runaway inflation (https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii). This alone explains "finished in 2 hours."
2. **Each prestige replays the same content.** Kolibri describes the core idle problem as "after a few prestiges the game starts to feel the same." Their fix was new visual mines, keeping the original mine, and never forcing a reset (https://mobilefreetoplay.com/gdc-2019-deconstructing-idle-miner-tycoon/).
3. **No new mechanics arrive over time.** Long-lived idle games unlock a whole *system* at each reset tier.
   - Realm Grinder adds challenges at R2, mercenaries at R3 and research at R16 (https://realm-grinder.fandom.com/wiki/Reincarnation).
   - Cookie Clicker's minigames are locked behind sugar-lump levels.
4. **There are no goals beyond bigger numbers.** v2 has no player level, lifetime ladder, collection or story. Hay Day and Township have run for 12–13 years and unlock something almost every level. A single Egg, Inc. diamond trophy takes 50–75 days.
5. **Everything runs on one clock.** Nothing in v2 works on a scale of hours, weeks, months or seasons.
6. **It looks cheap.**
   - Emoji text sits next to 3D art.
   - Feedback effects are either uniform or missing.
   - Progress shows only as numbers.
   - On iOS 15, Arabic falls back to a non-rounded font.

**The fix is structural; retuning numbers won't solve it.**

---

## 2. Core principles

1. **Never send the player back into identical content.**
   - The empire never resets, and cash belongs to one city.
   - The main reset is graduating a city. The city becomes a branch that keeps paying, and play moves to a new map with new dishes and one new mechanic.
   - Precedents: Idle Miner's continents, AdVenture Capitalist's Moon and Mars, Eatventure's cities.
2. **Introduce one system at a time.** In week 1, unlock at most one system per day. After that, one per city or reset tier. Always preview what is coming next.
3. **Costs grow exponentially; rewards grow by roots.**
   - Costs follow cost = b·rⁿ.
   - Prestige pays the √ or ∛ of earnings.
   - Most meta progress is designer-authored (for example, stars per goal), not derived from cash.
4. **Pace for engagement that tapers off.** The first session is long and active (15–60 min). After that come short check-ins: the median session is 3.1–3.5 min, about 3.8 times a day (https://www.gameanalytics.com/reports/2026-mobile-pc-gaming-benchmarks). The offline cap sets the pace.
5. **Run clocks at every scale:** minutes, hours, days, weeks, months and years.
6. **Use side games instead of resets.** Contracts, weekend venues and events reuse the venue engine with a deadline and a twist. They never touch the main save.
7. **Reward showing up, not grinding.** The rarest currency comes only from goals and the calendar, like Egg, Inc.'s Prophecy Eggs. A binge player should be at most 3× ahead of a daily player.
8. **Forgive by default.** No withering, no staff quitting, no losses while offline, no hard storage walls. A missed day pauses a track rather than resetting it.
9. **Keep it data-driven and deterministic offline.**
   - Content lives in JSON tables.
   - Random rolls are seeded from `hash(yyyyMMdd + playerSeed)`.
   - 14 days of schedule are computed ahead of time.
   - Moving the device clock backwards is detected and blocked.
   - A simulator in CI checks every table.
10. **Premium means consistency.** One art style, one feedback system, progress you can see, and a ceremony for rare moments.

---

## 3. Proven systems to adopt

### 3.1 A ladder of cities in an empire that never resets (the spine)
- **Proof:**
  - Eatventure has 60 cities of 7 restaurants each, level caps growing from 25 to 250, and 69.3M downloads (https://eatventure-games.fandom.com/wiki/Cities).
  - Kolibri built a prototype on new mines with no forced reset. It reached 63–81% D1 retention.
- **Parameters:**
  - 24 cities: 8 in Palestine, 8 in the Arab world, 8 worldwide. Each has 6–8 stations.
  - Station level caps: 100 for cities 1–3, 200 for cities 4–8, 300 for 9–16, and 400 for 17–24.
  - Each city has 8–15 goals worth 1–3 stars each, about 90 stars in total. Reaching a star threshold unlocks the next city.
  - Each new city needs a licence that takes real time: none for cities 1–3, then 1, 2, 4, 8, 12 and 24 h. The timer runs while the player is still in the current city.
- **Route:** Jerusalem stall → Nablus → Hebron → Bethlehem → Ramallah → Jaffa → Haifa → Gaza → Amman, Beirut, Damascus, Cairo, Istanbul, Dubai… → diaspora and world cities.
- **Each city** gets its own palette, landmark, signature dish and **one mechanic**:

  | City | Mechanic |
  |---|---|
  | Nablus | timing the knafeh oven |
  | Jaffa | port shipments |
  | Gaza | fishing supply |
  | Cairo | delivery |
  | Istanbul | bazaar trading |
  | Dubai | VIP customers |
  | one city | a production chain (chickpea farm → dough → falafel), where output grows like tⁿ/n! |

### 3.2 Empire level (مستوى المعلّم)
- **Proof:** Hay Day unlocks something almost every level, with major feature areas at levels 17, 25 and 34. Its Town (level 34) has its own reputation track (https://hayday.fandom.com/wiki/Town).
- **Parameters:**
  - XP comes from orders, goals and events, never from cash.
  - Every level unlocks something: a dish, a decoration, an NPC or a staff member.
  - Every 5–8 levels unlocks a whole system:

    | Level | Unlock |
    |---|---|
    | 3 | order board |
    | 6 | tahini production chain |
    | 9 | delivery van |
    | 12 | regular customers |
    | 15 | Hejaz train shipments |
    | 18 | league |
    | 22 | Academy |
    | 25 | recipe lab |
    | 30 | Jaffa port |
    | 34 | the Souq, with its own reputation |
    | 40 | weddings |
    | 50 | airport |

  - Levels come with 20+ titles, from "بائع على البسطة" up to "إمبراطور الفلافل".

### 3.3 Reset layers that unlock systems
- **Proof:** in Clicker Heroes, transcendence adds a new layer (Outsiders). Egg, Inc. added Path of Virtue *above* its old endgame years after launch (https://egg-inc.fandom.com/wiki/Path_of_Virtue).
- **Renovation** (optional, within one city, from about city 9):
  - Reputation earned = 150·√(E/E0), each point worth +2%.
  - Set E0 so that a ×2 gain only becomes possible near the city's planned end.
  - In simulation, renovating at ×2–3 is optimal.
  - At most 3 renovations per city.
- **Family Legacy (الإرث العائلي)**, opening in months 3–6:
  - Resets the cities. Keeps the codex, trophies, saffron and Golden Za'atar.
  - Pays heritage points by cube root. They are spent in a tree where each level costs 1.3^L.
  - The tree unlocks franchise automation, league tiers and family-dynasty cosmetics.
  - Leave room in the design for another layer above it.
- **UI:** show the gain as a ratio ("income ×2.4") and show "next at X", computed with the inverse formula.

### 3.4 Catering contracts (طلبيات): the main fix for "nothing new happens"
- **Proof:** decoded Egg, Inc. contract data (https://raw.githubusercontent.com/carpetsage/egg/main/periodicals/data/contracts.json):
  - about 50 new contracts and about 155 re-runs a year, so 48% are recycled;
  - releases on Monday, Wednesday and Friday;
  - a median length of 6 days;
  - 98% of contract variants have exactly 3 goals;
  - targets scale 2.3 million× from the weakest player grade to the strongest.
- **Parameters:**
  - Each contract is a side kitchen running its own copy of the venue engine. It never touches the main empire.
  - Contracts last 2 days for new players and 6–7 days for veterans.
  - Difficulty runs from سهل to مستحيل, based on the player's permanent bonus.
  - Rewards: goal 1 pays cash or a chest, goal 2 pays Golden Za'atar, and goal 3 pays a heritage case or a chef card.
  - Each week brings 1 new contract and 2 re-runs from a library of about 40.
  - 25–30% of contracts have a twist: ×2 speed at ×0.5 price, no managers, or hummus only.
  - 2–4 simulated NPC partners each deliver a pre-set 10–25% of the target.
- **Examples:** a Birzeit graduation, a Hebron wedding, lunch for Gaza fishermen, Eid sweets for an orphanage.

### 3.5 Supply runs and heritage artifacts (رحلات التوريد)
- **Proof:**
  - Egg, Inc. added rockets years after launch. Missions last from 20 min to 96 h, ships level up after a number of launches, and loot comes in 44 families × 4 tiers × 4 rarities (https://raw.githubusercontent.com/carpetsage/egg/main/lib/missions.ts).
  - Idle Miner expeditions last 6 h or more, up to 5 a day.
- **Parameters:**

  | Vehicle | Run lengths |
  |---|---|
  | Donkey cart | 20 min / 1 h / 2 h |
  | Pickup | 30 min / 1 h / 3 h |
  | Van | 1.5 / 4 / 8 h |
  | Truck | 4 / 12 / 24 h |
  | Jaffa ship | 12 / 36 / 72 h |
  | Plane | 24 / 48 / 96 h |

  - 3 slots, about 5 runs a day.
  - Capacity grows after 4, 10 and 25 launches.
  - Loot comes in about 24 families × 4 tiers × 4 rarities, with crafting and 4 equip slots.
- **Loot themes:** Hebron glass, Nablus soap, Bethlehem mother-of-pearl, tatreez embroidery, Gaza pottery.

### 3.6 One "Happening" engine
A single data-driven engine runs every timed effect. A happening can carry a choice, a target, a deadline and a reward. It takes about 2–3 developer-weeks to build. After that, each system below is just rows in a JSON table.

- **Special customer (زبون مميّز).**
  - Based on Cookie Clicker's golden cookie. It appears 5–15 min after the last one, with chance ((t−min)/(max−min))^5, and can give a Frenzy of ×7 for 77 s (https://raw.githubusercontent.com/ozh/cookieclicker/master/main.js).
  - Ours stays 15–20 s and only appears while the app is open:

    | Chance | Outcome |
    |---|---|
    | 60% | tip: 15% of cash or 15 min of income, whichever is smaller |
    | 25% | Frenzy |
    | 10% | tour bus: ×20 taps for 13 s |
    | 5% | collectible fragment |

  - No outcome is ever negative.
- **Choice events.**
  - Based on A Dark Room, which fires an event every 3–6 min from a pool filtered by `isAvailable()` (https://raw.githubusercontent.com/doublespeakgames/adarkroom/master/script/events.js).
  - Ours: none in the first 10 min, at most 4 a day, and a 7-day cooldown per event.
  - A pool of about 60, such as a wedding rush, a power cut, a celebrity visit, or a neighbour asking for credit (50% chance of 3× back, plus a karma flag).
  - Events that happen while offline appear in a "while you were away" newspaper and never cause a loss.
- **Daily market (سوق اليوم).**
  - Based on Egg, Inc.'s 459–670 global events a year. 76% last exactly 24 h, and all are simple multipliers.
  - Each day brings 1–2 modifiers chosen from the date.
  - Weather, as in Kittens Game: 17.5% of days are hot (+15% cold drinks) and 17.5% are cold (+15% sahlab).
- **Inspector and critic.**
  - Based on CorsixTH's VIP visit (scored 0–15 from things the player can see) and OpenRCT2's monthly awards (https://raw.githubusercontent.com/OpenRCT2/OpenRCT2/develop/src/openrct2/management/Award.cpp).
  - The inspector comes every 4–8 days (6 on average), after a 12 h warning. The 6 checks are cleanliness, queue length, staff fatigue, menu variety, decor and manager coverage.
  - A bad score only costs reputation.
  - Monthly awards like "Best Hummus in Nablus" give +5–10% each, with 4 award slots.

### 3.7 Weekly rhythm
- **Proof:**
  - Eatventure runs a main event Thursday–Sunday, a smaller event Monday–Tuesday and a race on Wednesday.
  - Idle Miner's event mines often doubled weekend income.
  - Duolingo leagues hold 30 players per group, across 10 tiers (https://duolingo.deconstructoroffun.com/mechanics/leagues).
- **Weekend venue (Thursday–Sunday):**
  - 3–4 themed stations, its own currency, 10 milestone tiers and a shop.
  - Leftover event currency converts at 50% or less.
  - 12 rotating themes, such as wedding catering, Eid sweets, World Cup night and the olive harvest.
- **Weekdays:** a mini-event Monday–Tuesday, and a 1-hour Rush against 4 NPCs on Wednesday.
- **League:**
  - Groups of 30 clearly fictional chains ("مطعم أبو شاكر").
  - Each rival follows a pattern (steady, weekend-burst or sprinter) that adjusts to the player's last two weeks.
  - Score comes from reputation (12 weekly tasks plus orders), never from cash.
  - The lowest tier promotes its top 15, then 10, 7 and 5 as tiers rise. The bottom 5 drop a tier.
  - Week 1 always ends in promotion.

### 3.8 Rivals, market share and story
- **Proof:**
  - Good Pizza Great Pizza has 5 chapters, each built around a rival, and 90% positive reviews.
  - OpenTTD has advertising campaigns and exclusive rights (https://raw.githubusercontent.com/OpenTTD/OpenTTD/master/src/town_cmd.cpp).
  - My Café's top complaint is that its stories run out.
- **Rivals:**
  - 2–3 named NPC chains per city, with market share tracked per district.
  - Players compete with 1–3-day ad campaigns and a 7-day exclusive deal with the municipality. No bribes.
  - Holding more than 50% of a district triggers that rival's story scene.
- **Story:**
  - One chapter of 8–12 scenes per city.
  - 40–60 regular customers, such as Abu al-Abed the taxi driver, Umm Mohammad and the Birzeit student. Each has a 3–6-step story, letters, and a keepsake with a small bonus.
  - Weekly visitors follow Animal Crossing's rule: no visitor stays away for more than 2 weeks.

### 3.9 Real-calendar seasons
- **Proof:** Cookie Clicker changes seasons based on the device date (https://cookieclicker.wiki.gg/wiki/Seasons).
- **Dates** come from `Calendar(identifier: .islamicUmmAlQura)`, with ±1 day of tolerance.

  | Season | When | Content |
  |---|---|---|
  | Ramadan | 30 days | daytime ×0.5, iftar ×5, a suhoor window, qatayef, 30 lantern collectibles |
  | Eid al-Fitr | 3 days | ka'ak and ma'amoul |
  | Eid al-Adha | 4 days | |
  | Olive harvest | Oct 15 – Nov 30 | oil press |
  | Summer | Jun – Aug | |
  | Back to school | Sep | |
  | Christmas in Bethlehem | Dec 20 – Jan 7 | |

  - Ramadan moves about 11 days earlier each year, so seasons must be able to overlap.
  - Include a no-festivals toggle, and never make days of mourning festive.

### 3.10 Daily layer
- **Proof:**
  - Egg, Inc.'s 28-day calendar pays a Prophecy Egg every cycle for 24 cycles, which keeps players coming back for two years (https://egg-inc.fandom.com/wiki/Daily_Gift_Calendar?oldid=7711).
  - At Duolingo, users with a streak of 7+ days retain 2.4× better, and streak-forgiveness tools cut churn from 47% to 37% (https://blog.duolingo.com/improving-the-streak).
- **Parameters:**
  - A 28-day login track that pauses instead of resetting. Day 28 pays Golden Za'atar.
  - A streak flame for completing daily orders:
    - up to 2 freezes, earned through play;
    - milestones at 3, 7, 14, 30, 50, 100 and 365 days;
    - a 48 h quest to repair a broken streak.
  - 3 daily orders with 1 reroll, and 3 weekly orders.
  - The day resets at 04:00 local time, so suhoor play counts toward the same day.
  - A savings jar (حصّالة) that fills with 1% of earnings.

### 3.11 Saffron: a slow lifetime currency
- **Proof:**
  - Cookie Clicker's sugar lumps arrive about every 23 h and survive resets.
  - Level L costs L+1 lumps and gives +1%.
  - A building's first level opens its minigame.
  - Getting 20 buildings to level 10 takes about 3 years.
- **Parameters:**
  - One saffron thread about every 23 h, with the same cost curve.
  - Getting 24 dishes to level 10 takes 1,320 threads, about 3.6 years.
- **Minigames:**
  - A section's first level opens its minigame: falafel-frying timing, the shawarma spit (SpriteKit), the knafeh flip, or a spice-market trading game.
  - Minigames are optional and pay a different kind of reward.
  - About 2 developer-weeks each. Ship 1–2 at launch.

### 3.12 Super-chefs, staff and play-style choices
- **Proof:**
  - Idle Miner's super managers have a 2m30s skill on a 30 min cooldown, level caps of 40/30/20/20 by rarity, and a new passive every 10 levels (https://idleminertycoon.fandom.com/wiki/Super_Managers).
  - Realm Grinder's factions and Cookie Clicker's Pantheon let each run be played a different way.
- **Chefs:**
  - Active skills last 2–5 min, on 15–60 min cooldowns.
  - Duplicates turn into shards.
  - Each chef has a cuisine (Levantine, Egyptian, Gulf, Turkish or international) that matches certain city stations.
- **Staff:**
  - Skill from 0 to 1 and a rank: junior, cook or master.
  - Traits such as fast hands, charming, night owl or perfectionist.
  - Tired staff go to rest. Nobody ever quits.
- **Play-style choices:**
  - Pick a style for each city: street food, family diner, luxury or delivery.
  - Pick 3 Family Recipes from a larger set, each with a trade-off.
  - Equipment: 3 slots, 5 rarities.

### 3.13 Light production chains, mastery and research
- **Proof:** Hay Day mixes 2-minute and 2-hour timers, and mastering a machine cuts its time by 5/10/15%. Township caps time savings at 50%.
- **Production chains**, for signature dishes only:
  - chickpeas → falafel
  - sesame → tahini → hummus
  - olives → oil, during the harvest

  When storage is full, production pauses with a warning. It never blocks the player.
- **Mastery:** 3 stars per station, each with a visible change.
- **Research:** level L takes 10 min × 1.5^(L−1), capped at 24 h.
  - Level 8 takes about 2.8 h, and level 12 about 14 h.
  - 12 research items × 20 levels adds up to about 116 days of research time, or about 2 months with 2 slots.

### 3.14 Collections and a free season pass
- **Proof:** one Egg, Inc. diamond trophy takes 50–75 days (https://egg-inc.fandom.com/wiki/Trophies). Monopoly GO albums run 8 weeks, with rare stickers saved for the second half.
- **Recipe Album:**
  - 8-week seasons of about 18 sets × 9 cards.
  - The hard cards come late.
  - Duplicates become spice, which can craft missing cards.
  - Each completed set gives a permanent multiplier.
- **Trophies:** 5 tiers per city.
- **Achievements:** 300+.
- **Free Season Pass:**
  - 42 days and 50 tiers.
  - Filled by orders and events, never by cash.
  - A player who plays 20 min a day finishes around day 35.

---

## 4. Economy and pacing targets

### 4.1 Time budgets
These assume a casual player: 3 sessions and about 35 min a day.

| Window | Target |
|---|---|
| First 60 s | First tap within 3 s, first purchase within 15 s. |
| Session 1 (15–60 min) | First big celebration within 2 min. First manager within 15 min. Something new every 5–10 min. Jerusalem finished in about 45–60 min (0.1 day). The session ends with a catering order due in 2 h. |
| Day 1 | 2–4 sessions. Nablus opens. |
| Week 1 | One new system a day: day 2 login track and streak, day 3 league, day 4 album, day 5 contract or weekend venue, day 6 research, day 7 season pass. Cities 1–6 done (about 5.4 days). |
| Month 1 | Palestine finished by about day 11. Arab-world cities take about 4 days each, reaching city 12–13 by day 30. Supply runs, saffron and Renovation are open. Play settles at 10–20 min a day. |
| Month 3 | World cities take about 6 days each, so the campaign ends around day 90. Family Legacy opens in months 3–6. |
| Years 1–3 | Legacy tree, leagues, diamond trophies, the 24-cycle calendar (about 22 months), saffron level 10 (about 3.6 years). |

**Acceptance criteria:**
- Over any 7 days, a binge player (8 h a day) is at most 3× faster than a casual one.
- Nobody can finish the campaign in under about 25 days.
- Retention targets: day 1 ≥40%, day 7 ≥20%, day 30 ≥10%. There is no server, so check these with the simulator and playtests.

### 4.2 Formulas and constants
- **Costs:**
  - One unit: cost(n) = b·rⁿ.
  - Buying k units at once: b·rⁿ·(r^k−1)/(r−1).
  - Most units affordable with cash C: k = ⌊log_r(1 + C·(r−1)/(b·rⁿ))⌋.
- **Stations** (from AdVenture Capitalist data, https://raw.githubusercontent.com/Slimmmo/Slimmmo.github.io/master/src/components/WorldData/Earth.tsx):
  - Base cost ×12 per tier.
  - Cycle times of 1/3/6/12/24/96/384/1536 s.
  - The time for a level-1 station to pay for itself grows ×2–4 per tier.
  - r is 1.08–1.09 for station 1 and 1.15 for station 2, then drops by 0.01 per tier to a floor of 1.09.
- **Milestones:**
  - Speed ×2 at 10/25/50/100/150/200/250/300 owned.
  - All stations ×2 once every station reaches 25/50/100/150/200/300.
  - Cash upgrades at ×3, costing about 5e5·20^i.
- **City goals** (casual player, 4 h offline cap):

  | City length | Final goal |
  |---|---|
  | 0.2 d | 1e9 |
  | 1 d | 1e11–1e12 |
  | 2 d | 1e13 |
  | 3 d | 1e14 |
  | 6 d | 1e15 |
  | 11 d | 1e16 |

  - Scale city prices by S_k = M_k/3, so permanent bonuses give a ×3 head start rather than letting the player skip content.
  - Palestine city lengths: 0.1/0.25/0.5/1/1.5/2/3/3 days.
- **Golden Za'atar:** ×1.05 each, compounding, like Egg, Inc.'s EB = SE·0.10·1.05^PE (https://github.com/wasmegg-carpet/egg).
- **Offline earnings:** 4 h cap at 50% efficiency, shown as a filling vault. Research raises this to 16 h and 100%.
- **Daily progress:** H_day = A·t_active + e·Σmin(gap, cap). With active-play boosts of A ≈ 3–5 (rush ×2, celebrity ×5), active play makes up 25–35% of a day's progress.
- **Gold** (the premium currency, earned only through play):
  - About 40–60 a day, never scaling with cash.
  - Worth about 1 gold per 6 min skipped.
  - Chests cost 50/150/400.
- **Inflation control:**
  - Bonuses add up within a category and multiply across at most 5–6 categories.
  - Percentage bonuses grow linearly to 75% of their cap, then level off.
  - Open-ended bonuses use a soft cap: cap^0.5·x^0.5.
  - Prestige shop prices grow by 1.3^L.
  - Keep every value under 1e30, so Swift's `Double` is enough.

### 4.3 Simulator checks in CI
The simulator shares the game's economy code. A bot buys whatever has the best score = (cost−cash)/income + cost/Δincome. It plays four player types (minimal, casual, engaged and binge) with ±20% random variation.

The build fails if any of these happen:
- a casual player's city lengths miss their targets by more than 20%;
- binge play is more than 3× faster than casual;
- the median wait for the next meaningful action is over 60 s, or the 90th percentile is over 5 min;
- more than 10% of sessions make no goal progress;
- any value goes over 1e30.

---

## 5. Premium-feel checklist (SwiftUI, iOS 15)

**Art**
- [ ] Use Fluent Emoji 3D (MIT licence) for objects. The PNGs are 256 px, so never display one larger than about 85 pt on @3x screens. Build larger visuals by combining several icons with vector shapes.
- [ ] Commission matching icons for knafeh, maqluba and ka'ak. This is a recommendation; the research did not cover it.
- [ ] Remove every emoji drawn as `Text`.
- [ ] Draw UI icons with SF Symbols `.heavy`, white with a 2 pt outline, on chunky buttons with a 3–4 pt lip.
- [ ] Use one light direction and one shadow style everywhere.
- [ ] Show rarity through frame shape as well as colour.
- [ ] Give each branch 8–12 visible upgrade stages: awning, lights, second fryer, a queue that grows with income, neon sign, Ramadan decorations.

**HUD**
- [ ] A 44–56 pt top bar with level and XP ring at top right, up to 3 currency pills, and the settings gear at top left.
- [ ] Event icons in side rails, each with a countdown.
- [ ] 5 tabs with one-word labels.
- [ ] Locked content shown as a "?" silhouette with its unlock condition.
- [ ] Red dots only when something can be claimed.
- [ ] `.monospacedDigit()` on every number.
- [ ] Milestone bars that pulse above 80%, plus a faint bar previewing the next purchase.
- [ ] A city route map.

**Feedback effects:** all go through one `Feedback.play(.tier, at:)` API. Screens never call sound or haptics directly.
- [ ] **Tier 0, tap:**
  - Scale to 0.94 over 80 ms.
  - Tick sound with ±6% pitch variation.
  - Light haptic at intensity 0.4–0.5, at least 80 ms apart.
- [ ] **Tier 1, purchase:**
  - Coin count = clamp(4 + 2·log10(amount), 4, 14).
  - Coins fly in, speeding up, over 0.45–0.7 s.
  - The HUD counter lags behind the real value: each coin adds amount/n and bumps the counter to 1.15×.
  - Pitch rises one semitone per coin.
- [ ] **Tier 2, level-up:** ribbon, light rays, 40–60 confetti pieces and a `.success` haptic. At most one every 1–2 min.
- [ ] **Tier 3, new city:**
  - A 2.5–4 s sequence the player can skip.
  - A 60–100 ms freeze before the burst.
  - A 6–10 pt screen shake that settles down (port Jonasson's Shaker, https://github.com/grapefrukt/juicy-breakout).
  - A building haptic pattern (AHAP).
- [ ] Count-up numbers take 0.35 + 0.15·log10(Δ) s, at most 1.2 s, using `AnimatableModifier`. `.numericText` needs iOS 16.
- [ ] Springs use `.spring(response:dampingFraction: 1−bounce)` with bounce ≤0.4.
- [ ] Call `prepare()` on haptic generators when the finger touches down.
- [ ] Limit coin sounds to one per 60–80 ms (currently 35 ms).

**Reward reveals**
- [ ] Four beats: build-up (0.6–1.2 s), burst (60–120 sparks), items 220–300 ms apart with a hint of rarity first, then items fly to the HUD using `matchedGeometryEffect`.
- [ ] Card flips use `rotation3DEffect` and take 0.35–0.8 s.
- [ ] Tapping always skips. Show "تخطي" after the player has seen a reveal 3 times.
- [ ] No more than 3 flashes per second.

**Street scene**
- [ ] Build the street as a SpriteKit `SpriteView`: one texture atlas, `SKEmitterNode` for steam, 30 fps, paused when hidden.
- [ ] Pause every `TimelineView` that is off screen.

**Arabic**
- [ ] Bundle Baloo Bhaijaan 2 (OFL licence) for headings and Cairo for body text, through `Font.custom(_:size:relativeTo:)`. iOS 15 has no rounded Arabic font.
- [ ] Never add letter spacing to Arabic.
- [ ] Number formatting:
  - Below 10⁶, show the full number.
  - From 10⁶, show 3 significant digits, rounded down, plus مليون…ديسيليون. The standard Arabic short forms stop at ترليون.
  - Above 10³³, switch to scientific notation.
- [ ] Set the digit style explicitly (ar-PS defaults to ١٢٣) and offer a toggle.
- [ ] Wrap numbers and "×N" in Unicode direction isolates.
- [ ] Mirror bars and navigation for right-to-left. Never mirror art or digits.

**Onboarding and accessibility**
- [ ] A pointing hand on a 0.9–1.1 s loop.
- [ ] A 65–75% dark overlay where only the highlighted spot accepts taps.
- [ ] Tutorial bubbles of 8–12 words.
- [ ] An unlock ceremony for each new system.
- [ ] With Reduce Motion on: fades instead of movement and 70% fewer particles, but sound and haptics stay.
- [ ] Separate toggles for music, sound effects and haptics.
- [ ] Text contrast of at least 4.5:1.

**Local notifications**
- [ ] At most 1 a day and 5 a week, between 18:00 and 22:00 (after iftar during Ramadan).
- [ ] Only for real events: a supply run is back, a contract ends within 24 h, the inspector is coming, a streak is at risk, the vault is full, league results are in.
- [ ] Reschedule every time the app goes to the background (iOS keeps at most 64 pending).
- [ ] Win-back reminders on day 3 and day 7 of absence, then nothing.

---

## 6. Pitfalls to avoid

1. **Generous prestige.** Always pay by √ or ∛, with E0 tied to the end of the city.
2. **Resetting into the same content.** This is the "feels the same" problem Kolibri describes.
3. **Too many features at once.**
   - One new system a day.
   - Introduce Gold, Saffron and Za'atar gradually.
   - At most 3 currency pills on screen.
   - Animal Restaurant dropped a staff currency to keep onboarding simple.
4. **Running out of content** (My Café's #1 complaint). Launch with enough that nothing repeats within 2 weeks: about 60 events, about 40 contracts, 12 weekend themes, about 24 heritage families, 120+ recipes, 40–60 customers, 6–8 seasonal packs and 20+ cities.
5. **Storage walls and rare drops that block progress** (what Hay Day and Township players hate most). Use soft caps and make rare items craftable.
6. **Nerfing things after release.** Eatventure cut a bonus from about 70,000% to 10,616%. Tune in the simulator before release.
7. **Punishing players.** No withering, no staff quitting, no offline losses, no streak wipes, no required minigames that are too hard (a Township complaint). Use a rest bonus instead: "fresh dough" gives ×2 on the next orders after up to 3 days away.
8. **Bots pretending to be people.** Keep NPC rivals clearly fictional.
9. **Too many notifications.** Users who get more than 6 a week are 3.4× more likely to uninstall within 30 days.
10. **Grind walls late in the game** (an Eatventure complaint). Keep late cities to about 6 days for a casual player.
11. **Clock cheating.** Store the last trusted time, freeze timers if the clock moves back more than 5 minutes, cap offline gains, and choose random rolls from the date.
12. **Calendar insensitivity.** Plan for Ramadan moving each year and for moon sighting differing by a day. Never make days of mourning festive, and offer a no-festivals toggle.
13. **Technical traps.** Fluent art shown above 85 pt, relying on `.rounded` for Arabic, APIs that need iOS 16, unlimited haptics, and `TimelineView`s that never pause.
14. **Copycat sameness** (AppQuantum's criticism of Eatventure clones). Each city must differ in **mechanic**, not just art.