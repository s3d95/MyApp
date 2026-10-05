# بسطة فلافل v3 — Lead designer draft (to be stress-tested against research)

## Diagnosis of v2
- One map, one loop. Prestige replays identical content ("all I do is reopen shops").
- No gating by real time: binge-able in 2 hours. No appointment mechanics.
- Goals were only "bigger numbers". No chapters, no story, no new mechanics unlocking.
- Emoji art + flat UI = cheap feel. No juice, no living scene.

## Pillars
1. Always something NEW within the next 10 minutes (progressive unlocks, new city every chapter, new dishes/art).
2. Always a REASON TO RETURN in a few hours (timers: research, supply runs, offline vault, tickets) and tomorrow (daily calendar, quests, events, league).
3. Long horizon: ~3+ months to finish the city campaign; meta collections and leagues continue indefinitely.
4. Premium feel: 3D art pack, living animated street scene, chunky UI, juice on every reward, sound + haptics.

## Structure (layers)
### L1 — City restaurant (core idle loop, per city)
- Each city = a chapter with its own cash currency, its own 5–8 stations (local dishes), its own visuals (backdrop color, landmark art).
- Station: dish, level 1…N (cap grows by tier: 25 → 50 → 100 → 150 → 200 → 300 depending on city), upgrade cost exponential (growth ~1.12–1.18), cycle time, profit/cycle. Milestone levels (10/25/50/100/150/200/…) give: +1 cook (parallel cycles), speed ×2, profit ×2 alternating.
- Managers: hire per station (city cash) → auto-cooks and works offline. Before a manager, player taps the station to cook (active early game).
- Staff/support upgrades per city: waiters (serve speed), cashier (tips), seating/decor (customers per minute), ads (customer flow).
- Living scene: customers (3D person icons) walk in, queue, order bubble with the dish icon, get served, coin pops. Visual only, rate tied to income.
- Special customers (random, tap to claim): VIP (cash), food critic (temporary ×2 + reputation), celebrity (×5 frenzy 20s), tourist bus (big order), delivery request.

### L2 — City goals (chapter progression)
- Each city has 20–35 goals shown 3 at a time (AdCap missions / Eatventure tasks). Types: reach station level, unlock station, hire managers, earn cash, serve customers, buy support upgrades, complete events in city, serve VIPs, finish catering orders, research once (time gate), send a supply run (time gate).
- Goals award stars ★ (1–3) + XP + gold. When stars ≥ requirement, player can "open next city" (graduate). Current city becomes a BRANCH (passive gold income, upgradable) — not a reset of the same content.
- City pacing target: Jerusalem 1.5–2h (tutorial), then ×1.3–1.5 per city; later cities 3–7 days each. 24 cities ≈ 3–4 months.

### L3 — Empire meta (persistent, never resets)
- Empire level (XP from goals, quests, upgrades) 1–100+. Each level gives a reward and many unlock features (progressive disclosure): L2 managers, L3 daily quests, L4 chefs & chests, L5 lucky wheel, L6 research, L8 supply runs, L10 weekly events, L12 league, L15 season pass, L20 recipe mastery…
- Gold liras (soft-premium): from goals, quests, branches, events, league, calendar. Sinks: chests, research rush, boosts, extra wheel spins, branch upgrades.
- Chefs (collectible cards, ~36 across rarities common/rare/epic/legendary, each tied to a cuisine tag: Palestinian, Levantine, Gulf, Egyptian, Maghreb, Turkish, Global). Equip up to N chefs (slots grow with empire level) → boost stations with the matching tag in any city. Duplicates level chefs (1–10).
- Research "دفتر ستّي" (timed, Egg-Inc/Clash style): tree of 30–40 nodes across 4 branches (Kitchen speed, Profits, Customers, Logistics/Offline). Each node takes real time (5 min → 24 h) and gold/recipes points; one slot (second slot at higher level). Global effect across all cities. Appointment mechanic.
- Recipe Book (collection): every dish ever cooked has mastery stars (serve 1k/10k/100k/1M) → permanent +% for that dish everywhere; completing cuisine pages gives big bonuses.
- Branches portfolio: graduated cities produce gold/hour (cap 8h) + can be upgraded with gold → more gold/hour.
- Supply runs: 3 vehicles (scooter/truck/boat-plane unlocks), send for 30m/2h/8h → chests, gold, chef cards.

### L4 — Daily / weekly LiveOps (offline-simulated)
- 28-day login calendar with weekly big rewards + streak flame.
- Daily quests (5) + weekly quests (7); quest points fill daily chest track (thresholds) and weekly chest track.
- Lucky wheel (1 free/day).
- Season pass (30 days, 40 tiers, free track): XP from quests/events/goals; rewards gold, chests, exclusive legendary chef, cosmetic stall skins. Themes rotate by calendar (Olive harvest, Winter, Ramadan, Summer).
- Weekly event (Fri–Sun 72h): a mini-city with 3–4 themed stations (Knafeh festival, Mansaf wedding, Ramadan iftar, Ice-cream summer), event currency, milestone rewards, NPC leaderboard. Reuses the city engine.
- Weekly league: you + 19 NPC chains ranked by league points earned during the week (from goals, quests, events). Top 5 promote, bottom 5 demote; tiers Bronze → Silver → Gold → Platinum → Diamond → Legend. Deterministic NPC curves seeded by week.

### L5 — Active play
- Rush orders minigame (assemble sandwiches) with tickets; plus tap-to-cook early game and special customers.

## Screens
- Restaurant (home): HUD (empire level avatar, city cash, gold, stars), living street scene, stations list (wood cards: 3D dish, level, cook progress, profit/s, upgrade ×1/×10/max), side buttons (goals, events, quests, wheel), next-goal banner.
- Map: cities path (3D landmark per city, locked/current/branch), branches income collect.
- Chefs: collection + equipped slots + chests opening (3D chest art, rays, card flips).
- Quests: daily/weekly + season pass track + calendar.
- Shop: chests, boosts, time skips, gold offers (earned gold only).
- Research tree; League; Settings/stats.
- Modals: level-up, goal complete, city graduated (big celebration), offline earnings vault, reward reveal.

## FTUE (first 5 minutes)
Hand-pointer tutorial: tap stall → cook falafel → earn → upgrade → unlock hummus → hire first manager → first goal claimed → level up to 2 → introduce goals list. Ends with "come back in 1 hour: your manager keeps cooking (offline vault)".

## Economy targets
- Session 1: ~20–30 min reaches Empire L4–5 and Jerusalem goals 40%.
- Day 1: finish Jerusalem, start Bethlehem, first research started, first supply run.
- Week 1: cities 3–5, league joined, first weekly event.
- Month 1: city ~10–12; Month 3: city ~20–24; chefs/recipes/leagues continue after.
