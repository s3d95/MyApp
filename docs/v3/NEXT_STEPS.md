# v3 rebuild: status and next steps

## Done
- Research, design (`GDD.md`), schemas (`SCHEMA.md`), inputs, content drafts (`content/*.json`, checked by
  `design_tools/check_cities.py`), `ARCHITECTURE.md`.
- **Phase I** (released as build-12): kitchen engine, 24 cities with twists, goals, story, graduation, licences,
  branches, empire level, vault + newspaper, special customers, rush hours, FTUE, settings, notifications.
- **Polish + Phase II/III** (released as build-13):
  - Root is left-to-right with right-to-left screens, so tutorial spotlight, anchors and flying effects line up.
  - Fractions render as one unit in Arabic text; numbers have thousands separators.
  - Chefs, chests (4-beat reveal), daily chef stall, shop, time warps, chef skills.
  - Research (دفتر ستّي), supply runs + heritage box (crafting from L19).
  - Daily/weekly orders, 28-day calendar, streak with freezes and repair, tickets.
  - Choice events (حكايات الحارة), rush minigame (طلبيات على السريع).
  - Weekly league, daily market + weather, season pass, achievements.
  - Catering contracts and the weekend venue (side kitchens), real-calendar festivals, the inspector.
  - CI (`.github/workflows/check.yml`): simulator build + screenshots of demo states (`Engine/Demo.swift`),
    published with `status.txt`, `files.txt` and crash reports to the `ci-screens` pre-release.
  - Stall decor (shop: awnings, signs, lights, props); cosmetic rewards unlock decor.
- **Side kitchens + festivals** (branch `v3-sides`):
  - Side kitchens run their twists: contract `twists`, venue theme `twists`, else the season's `eventTwist`
    (bus, port, oven, weather, night market, production chain without stock). `goldenHour` gives a frenzy at the
    top of every hour while the app is open. Rules and twists show on contract cards and in the kitchen.
  - Festivals hang `decor` art over the street (and on `eveDays`), pick the weekend venue theme
    (`events.festivalOverrides`), and open festival choice events. Settings "زينة المواسم" off hides all of
    that and shows `neutralName`; numeric effects stay.

## Shipped content
`MyApp/Content/*.json` are copies of `docs/v3/content/*.json`. Re-copy after editing a draft.

## Known gaps
- Side kitchens do not support `deliveryRuns` or `vipLounge` (no content uses them there).
- Twists have no first-time ceremony inside side kitchens.
- Economy pacing is from the design simulator only; tune after play-testing.

## Next
1. Play-test on device; fix layout and pacing.
2. Tune contract and venue targets once real side-kitchen income with twists is measured.
