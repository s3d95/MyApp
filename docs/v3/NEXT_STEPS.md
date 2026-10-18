# v3 rebuild: status and next steps

## Done
- Research, design (`GDD.md`), schemas (`SCHEMA.md`), inputs, content drafts (`content/*.json`, checked by
  `design_tools/check_cities.py`), `ARCHITECTURE.md`.
- **Phase I** (released as build-12): kitchen engine, 24 cities with twists, goals, story, graduation, licences,
  branches, empire level, vault + newspaper, special customers, rush hours, FTUE, settings, notifications.
- **Polish + Phase II/III** (branch `v3-polish`):
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

## Shipped content
`MyApp/Content/*.json` are copies of `docs/v3/content/*.json`. Re-copy after editing a draft.

## Known gaps
- Side kitchens ignore twists declared on contracts/themes; the `goldenHour` rule is not implemented.
- Cosmetics are recorded (`metrics["cosmetic.*"]`) but there is no cosmetics screen yet.
- Festival decorations and the "زينة المواسم" setting are not implemented (numeric effects are).
- Economy pacing is from the design simulator only; tune after play-testing.

## Next
1. Play-test on device; fix layout and pacing.
2. Cosmetics screen and stall skins; festival decorations.
3. Twists in side kitchens; season themes' event twists.
