# v3 rebuild: status and next steps

## Done
- Research: `research_brief.md` (synthesis) and `research_reports.json` (6 full reports).
- Design: `GDD.md` (complete game design document) and `SCHEMA.md` (JSON content schemas).
- Lead inputs and scope: `INPUTS.md`, `design_draft.md`.
- Content: `content/*.json`; `design_tools/check_cities.py` passes (0 errors, 0 warnings).
- `ARCHITECTURE.md`: Swift file plan and Phase I scope.
- **Phase I is in the app** (2026-10-19, branch `v3-phase1`): the v2 game was replaced by the v3 core.
  - Shipped content: `MyApp/Content/{economy,cities,levels,story,ftue}.json` (copies of `docs/v3/content`;
    re-copy after editing the drafts).
  - Engine: `MyApp/Engine` (catalog, kitchen, goals, branches, empire level, vault, specials, twists, FTUE,
    feedback tiers, notifications). Screens: `MyApp/Screens`.
  - Art: 215 Fluent 3D images installed in `MyApp/Assets.xcassets/Art` (`tools/install_art.py` now also scans
    content JSON).
  - CI: `.github/workflows/check.yml` compile-checks every non-main branch without making a release.

## Phase I known gaps
- Economy not re-tuned against real play yet (simulator numbers only); watch session-1 pacing (GDD 8).
- Goals of systems that are not built (chefs, research, supply, daily, contracts, events, rush, choices)
  are hidden; chests/chef cards/heritage rewards are stored in `wallet.pending*` for Phase II.
- Legacy gift gives the gold and the gold chest now; the exclusive chef comes with the chef system.

## Next (in order)
1. Play-test Phase I on device; fix layout and pacing issues.
2. Phase II: chefs and chests (deliver pending chests/cards), research "دفتر ستّي", supply runs + heritage,
   daily/weekly orders, calendar and streak, choice events, rush minigame, daily market and weather.
3. Phase III: contracts, weekend venue, league, season pass, festivals, inspector, achievements.
