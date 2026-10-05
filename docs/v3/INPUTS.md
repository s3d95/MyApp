# بسطة فلافل v3 — design inputs (from the lead)

Read these first:
- Research brief (synthesized): `scratchpad/design/research_brief.md`
- Full research reports: `scratchpad/research_all.json` (array of {report, recommendations, sources})
- Lead's draft: `scratchpad/design_draft.md`
- Art keys available (Fluent 3D, 256px, show ≤ 85pt): `/home/user/MyApp/tools/art_keys.txt` (prefixes food_, ppl_, face_, bld_, veh_, ui_, ani_). A contact sheet is at `scratchpad/art/sheet_food.png`, `sheet_other1.png`, `sheet_other2.png`.
- Existing v3 groundwork code (UI kit) in `/home/user/MyApp/MyApp/UI/**`, `/home/user/MyApp/MyApp/Audio/AudioEngine.swift`, `/home/user/MyApp/MyApp/Views/Brand.swift`, `/home/user/MyApp/MyApp/Views/LoadingView.swift`.
(scratchpad = /tmp/claude-0/-home-user-MyApp/152624f1-659b-5de9-865b-3f5172424bf2/scratchpad)

## Player & problem
Levantine-Arabic speaking player (Palestinian). Finished v2 in 2 hours; complained the only loop was re-opening (prestige) with nothing new; wants a big, wide, professional, world-class game to play daily for a lifetime, with professional art. Brand: logo "بسطة فلافل" (sunset market stall, string lights, bunting, golden outlined title). App display name: بسطة فلافل.

## Hard constraints
- SwiftUI, iOS 15.0 deployment target, Swift 5 language mode, compiled by Xcode 16 on CI (no local compiler). SpriteKit allowed but avoid unless essential. No third-party packages.
- Fully offline single player. No backend, no ads, no IAP. Gold/gems are EARNED only. NPC rivals are openly fictional.
- All UI text Levantine Arabic, RTL. Digits Western (123). Numbers formatted with Arabic scale words (ألف, مليون, مليار, تريليون, كوادريليون…).
- Art: only the Fluent 3D pack keys listed in art_keys.txt + SF Symbols + vector shapes. Never render emoji characters as Text.
- Fonts bundled: Baloo Bhaijaan 2 (ExtraBold, Bold) for display, Cairo (SemiBold, Bold) for body (`Font.game(size, weight)` / `Font.body(size)` exist).
- Save: single Codable state in UserDefaults (JSON). Must decode tolerantly (every field optional with defaults) so later updates never wipe saves. v2 save is NOT migrated: returning v2 players get a one-time "legacy gift" (gold + a legendary chef) and start v3 fresh.

## Architecture decisions already made
1. Content is DATA: JSON files bundled under `MyApp/Content/*.json`, decoded at launch into Codable structs (the "Catalog"). A Python validator (tools/validate_content.py) checks schema, unique ids, cross-references and that every art key exists in tools/art_keys.txt. The balance simulator (tools/sim/) reads the same JSON.
2. One kitchen engine ("Kitchen") powers the main city, catering contracts and weekend event venues: stations with levels, cycle/revenue, managers, cash upgrades, milestones, per-kitchen cash. City adds goals/stars/story; contract adds deadline/3 goals/NPC partners/rule twist; event adds currency/milestone tiers/NPC ranking.
3. A single "Happening" engine (data rows) drives special customers, choice events, daily market modifiers, rush hours, inspections.
4. Feedback tiers API (T0 micro, T1 minor, T2 major, T3 epic) wraps SFX + Haptic + FX; screens never call SFX/Haptic directly.
5. GameStore (ObservableObject, single source of truth) ticks at 10 Hz; systems are extensions in separate files; pure rule functions on value types.
6. Deterministic daily content: seeded by date (yyyyMMdd) + player seed; schedules precomputed; clock-rollback guard.

## v3.0 scope (ALL of these ship; design each fully)
Core
1. City ladder: 24 cities — 8 Palestine (القدس, بيت لحم, نابلس, الخليل, يافا, حيفا, غزة, رام الله or similar), 8 Arab world (عمّان, بيروت, دمشق, القاهرة, بغداد, الرياض, دبي, مراكش…), 8 world (إسطنبول, لندن, باريس, نيويورك, طوكيو, …). Each city: own cash currency (local name/symbol), palette, landmark art, 6–8 stations (local dishes with art), 15–25 goals (shown 3 at a time) awarding stars, a level cap, a story chapter (grandma mentor ستّي أم خليل + that city's rival chef). Graduating converts the city into a BRANCH (passive gold/hour, capped; upgradable) — never re-play identical content.
2. Stations: AdCap-ladder economy, managers (automation + offline), speed/profit milestones, all-stations milestones, cash upgrades/investments per city.
3. Empire level 1–100+ (XP from stars, quests, contracts…): every level gives a reward; features unlock progressively (≈ one new system per day in week 1, then every few levels).
4. Offline vault: cap starts 2–4h at ~50% efficiency, raised by research.
5. Living street scene per city (StreetScene exists) + visible stall upgrades tiers.
Meta
6. Gold (earned only, fixed faucet ~40–60/day) and a rare compounding currency from goals/contracts/calendar only (e.g. زعتر ذهبي ×1.05 compounding, small).
7. Chefs: ~30 collectible cards, rarities (common/rare/epic/legendary, frames differ by shape too), cuisine tags, equip slots that grow with level, duplicates → shards → levels. Chests (wood/silver/gold) with 4-beat reveal.
8. Research "دفتر ستّي": timed tree (10 min → 24h), 1 slot (+1 later), global effects.
9. Supply runs "رحلات التوريد": vehicle ladder (donkey cart → pickup → van → truck → ship → plane), 3 slots, returns heritage items (Palestinian crafts: Hebron glass, Nablus soap, tatreez, Bethlehem mother-of-pearl, Gaza pottery, olive wood…) collection with set bonuses.
Daily/weekly
10. 28-day calendar that never resets (missing pauses), streak flame with earned freezes, 3 daily + 3 weekly orders with reroll and bonus chest, daily market modifiers + weather.
11. Weekly league vs ~30 NPC chains, tiers with promotion/demotion, score = reputation points (not cash), rubber-banded.
12. Free season pass: 42 days, 50 tiers.
13. Catering contracts (طلبيات): Egg-Inc style side kitchens with deadlines, 3 goals, NPC partners, rule twists; library ≥ 20; 1 new + 2 reruns per week.
14. Weekend event venue (Thu–Sun): mini-city with 3–4 themed stations, event currency, 10 milestones, NPC ranking; ≥ 8 themes.
15. Real-calendar festivals: Ramadan (iftar ×5 hour), Eid al-Fitr, Eid al-Adha, olive harvest (Oct 15–Nov 30), summer, Christmas in Bethlehem — via Calendar(identifier: .islamicUmmAlQura).
Moment-to-moment
16. Special customer every 5–15 min (app open) + choice events (≥ 40 rows) + rush hours (lunch 12–14, dinner 19–22 ×2 while open).
17. Rush minigame "طلبيات على السريع" (sandwich assembly) as an active boost, tickets.
Polish
18. FTUE: teach-by-doing, spotlight + hand pointer, first tap < 3s, first purchase < 15s, first T2 celebration < 2min; session 1 ends on an appointment.
19. Notifications: ≤ 1/day, true & useful only (supply run back, research done, vault full 6h+, streak at risk 20:00, contract ends 24h, league result Monday).
20. Settings: SFX, haptics, notifications, reduce motion, replay tutorial, credits (licenses: Fluent Emoji MIT, OFL fonts), developer credit "Developer: Saad".

## Pacing targets (casual = 3 sessions/day, ~35 min/day)
- Session 1 (~20–30 min): empire L4–5, Jerusalem ~40%.
- Day 1: finish Jerusalem (≈1–2 h of play incl. offline), start Bethlehem, first research & supply run started.
- Week 1: cities 3–5; league joined; first weekend event.
- Month 1: city ~10–12. Month 3: city ~20–24. Binge (8h/day) ≤ 3× casual pace; campaign cannot be finished in < ~25 days by anyone.
- Endless: collections, chefs to max, leagues, seasons, contracts, events continue after the last city.
