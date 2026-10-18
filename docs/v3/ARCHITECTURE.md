# v3 architecture (Phase I)

Swift sources for the v3 game. Rules come from `GDD.md`; content shapes from `SCHEMA.md`.

## Content
- Shipped content: `MyApp/Content/{economy,cities,levels,story,ftue}.json` (copied from `docs/v3/content`
  after `design_tools/check_cities.py` passes). Bundled as resources, decoded at launch into `Catalog`.
- Decoding is tolerant: every field has a default (`KeyedDecodingContainer<AnyKey>.v(_:_:)`).

## Files
| File | Contents |
|---|---|
| `Engine/Catalog.swift` | Codable content structs (`CityDef`, `StationDef`, `GoalDef`, `TwistDef`, `SceneDef`, …), `Catalog.load()` |
| `Engine/Rules.swift` | Pure rules: SplitMix64/FNV1a RNG, game day, XP curve, cost/bulk formulas, milestone counts |
| `Engine/Num.swift` | Number, multiplier and duration formatting (Arabic scale words, bidi isolates) |
| `Engine/Save.swift` | `GameSave` and its sections, tolerant decoding, UserDefaults key `basta.save.v3` |
| `Engine/GameStore.swift` | `GameStore` (ObservableObject, single source of truth), 10 Hz tick, resume, save |
| `Engine/Store+Kitchen.swift` | Income, tap-to-cook, buy levels, managers, cash upgrades |
| `Engine/Store+Goals.swift` | Goals, stars, story triggers, graduation, licences, branches, branch safe |
| `Engine/Store+Empire.swift` | XP, empire level, level rewards, unlocks, titles |
| `Engine/Store+Happenings.swift` | Special customers, active boosts, rush hours |
| `Engine/Store+Twists.swift` | The 8 city twists (GDD 3.6) |
| `Engine/Store+Offline.swift` | Offline vault (stepwise integration), newspaper, fresh dough, clock guard |
| `Engine/Store+FTUE.swift` | Data-driven FTUE steps from `ftue.json` |
| `Engine/Feedback.swift` | Feedback tiers T0–T3 (the only caller of SFX/Haptic/FX from game code) |
| `Engine/Notifications.swift` | Local notifications (vault full, win-back), quiet hours |
| `Screens/*` | Root, HUD, kitchen, station card, goal strip, twist strip, map, sheets, modals, tutorial, tab bar |

## Phase I scope
Built: kitchen engine, 24 cities with twists, goals/stars, story chapters, graduation, licences, branches
(safe + upgrades), empire level 1–100+, offline vault + newspaper, special customers, rush hours, fresh dough,
time warps (inventory), FTUE, settings, legacy gift (gold part), local notifications.

Not built yet (Phase II/III): chefs and chests, research, supply runs/heritage, daily/weekly orders, calendar,
league, season, contracts, weekend venue, festivals, choice events, rush minigame, market/weather, inspector.
- Goals of unbuilt systems are hidden (they do not take one of the 3 slots); every city stays winnable
  (checked: available stars ≥ `starsToGraduate` for all 24 cities). A crown needs every *available* goal.
- Chests, chef cards and heritage items granted by goals/levels are stored in `wallet.pending*` and will be
  delivered when their system ships. Their tabs show a "قريباً" teaser.
