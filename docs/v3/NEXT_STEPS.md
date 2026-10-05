# v3 rebuild: status and next steps

Paused on 2026-10-05 because the account's usage limit was nearly reached.

## Done (saved in this repo)
- Research: `research_brief.md` (synthesis) and `research_reports.json` (6 full reports).
- Design: `GDD.md` (complete game design document) and `SCHEMA.md` (JSON content schemas).
- Lead inputs and scope: `INPUTS.md`, `design_draft.md`.
- Content drafts (not yet validated or tuned): `content/*.json`; generators and checks in `design_tools/`.
- Groundwork code (compiles on CI, not yet used by the game): `MyApp/UI/Kit`, `MyApp/UI/FX`,
  `MyApp/UI/Scene/StreetScene.swift`, `MyApp/Audio`, fonts in `MyApp/Resources/Fonts`, brand and loading screen.
- Art: re-download the 453 Fluent 3D PNGs with `tools/art/fetch.py` (manifest `tools/art/manifest.json`),
  then install the used ones with `tools/install_art.py`.

## Next (in order)
1. Validate and finish content against SCHEMA.md (`design_tools/check_cities.py`, meta checks).
2. Tune the economy with the simulator against the pacing targets in INPUTS.md.
3. Write ARCHITECTURE.md (Swift file plan, Catalog structs, SaveState, GameStore API).
4. Phase I: core playable game (cities, stations, goals, branches, empire level, offline vault, HUD,
   living scene, tutorial). Build on CI and release.
5. Phase II: chefs, research, supply runs, daily systems. Phase III: contracts, weekend events,
   league, season pass, festivals.
