# بسطة فلافل v3.0: Content data schemas

All content lives in `MyApp/Content/*.json`. It is decoded at launch into the `Catalog` (Codable structs) and validated by `tools/validate_content.py`. The same files feed the simulator (`tools/sim`). Rules are in `GDD.md`; this file defines only shapes.

## 0. Conventions
- **Files:** UTF-8 JSON. Every file is an object whose first field is `"version": Int`.
- **Field names:** camelCase. Enum values are camelCase strings and map to `enum X: String, Codable`.
- **Decoding:** every field not marked **R** (required) is optional, and its default is in the Default column. Swift structs must decode tolerantly: use `decodeIfPresent` with a default, and decode an unknown enum raw value to `.unknown`, then skip that row with a validator warning.
- **Units:** in the field name or the Unit column. Seconds are `...Sec`, minutes `...Min`, hours `...Hours`, days `...Days`. Big numbers are `Double` in **base units** (multiplied at runtime by `city.priceScale` for city kitchens, or by the grade factor for side kitchens).
- **Ids:** unique within their file and referenced across files:
  - `stationId` = `"<cityId>.<key>"`
  - side station ids = `"<contractId|themeId>.<key>"`
- **Validator checks:** schema, unique ids, cross-references, art keys against `tools/art_keys.txt`, probabilities that sum to 1 (±1e-6), arrays sorted where required, and `finalGoalBase × priceScale < 1e30`.

### 0.1 Shared scalar types
| Type | JSON | Rule |
|---|---|---|
| `ArtKey` | string | Must exist in `tools/art_keys.txt` |
| `Hex` | string | `"#RRGGBB"` |
| `GText` | string **or** `{ "m": string, "f": string }` | Gendered text. A plain string is used for both forms. Placeholders use `{name}` |
| `Prob` | number | 0…1 |
| `DateMD` | string | `"MM-dd"` (Gregorian) |
| `DateYMD` | string | `"yyyy-MM-dd"` |

### 0.2 Shared enums
| Enum | Values |
|---|---|
| `Rarity` | `common`, `rare`, `epic`, `legendary` |
| `Cuisine` | `palestinian`, `levantine`, `egyptian`, `gulf`, `iraqi`, `maghrebi`, `turkish`, `world`, `any` (exclusive chefs only) |
| `Category` | `fried`, `grill`, `bakery`, `sweets`, `drinks`, `dishes`, `seafood`, `street`, `any` (exclusive chefs only) |
| `WeatherTag` | `none`, `hot` (sells more on cold days), `cold` (sells more on hot days) |
| `WeatherId` | `sunny`, `hot`, `cold`, `rainy` |
| `KitchenKind` | `city`, `contract`, `event` |
| `ChestId` | `wood`, `silver`, `gold` |
| `Region` | `palestine`, `arab`, `world` |
| `CosmeticSlot` | `awning`, `sign`, `lights`, `prop`, `frame` |
| `FeedbackTier` | `t0`, `t1`, `t2`, `t3` |
| `SystemId` | `kitchen`, `goals`, `managers`, `specials`, `upgrades`, `chefs`, `chests`, `shop`, `rushHours`, `vault`, `map`, `research`, `supply`, `heritage`, `daily`, `calendar`, `streak`, `choices`, `newspaper`, `rush`, `league`, `market`, `contracts`, `events`, `season`, `branchUpgrades`, `inspector`, `crafting`, `chefSkills`, `timeWarpShop` |
| `Silhouette` | `oldCity`, `hills`, `coast`, `towers`, `desert`, `minarets`, `bridge`, `mountains` (vector shapes drawn by `CitySilhouette`) |

### 0.3 `Reward`
`{ "type": RewardType, "amount": Double, "id": String?, "rarity": Rarity? }`

| `type` | `amount` | `id` / `rarity` |
|---|---|---|
| `gold` | count | — |
| `zaatar` | count | — |
| `xp` | count | — |
| `rep` | count | — |
| `seasonPoints` | count | — |
| `tickets` | count | — |
| `freezes` | count | — |
| `timeWarpMin` | minutes | — |
| `incomeMin` | minutes of current-kitchen income | — |
| `chest` | count | `id`: ChestId |
| `chefCards` | count | `id`: chefId **or** `rarity` (random chef of that rarity); `id: "seasonChef"` = current season chef; `id: "themeChef"` = current event theme chef |
| `heritageItem` | count | `id`: itemId **or** `rarity` |
| `heritageCase` | count | — (3 rolls, rarity floor rare) |
| `eventTokens` | count | — |
| `cosmetic` | 1 | `id`: cosmeticId |
| `storyScene` | 1 | `id`: sceneId |

Example: `{ "type": "chefCards", "amount": 3, "rarity": "rare" }`

### 0.4 `Scope` (targets of multipliers)
`{ "kind": "all" | "category" | "cuisine" | "weatherTag" | "stations", "value": String?, "stationIds": [String]? }`

Example: `{ "kind": "category", "value": "fried" }`

### 0.5 `Effect` (Happening engine, market, festivals, skills)
`{ "type": EffectType, ...params }`

| `type` | Params (unit) | Meaning |
|---|---|---|
| `incomeMult` | `scope` Scope, `mult` Double, `layer` `"day"`/`"active"`, `durationSec` Double? (active only; omitted = whole day for `day`) | Category 10 or 11 multiplier |
| `costMult` | `target` `"stationLevel"`/`"manager"`/`"research"`/`"chefOffers"`, `mult` | Price multiplier |
| `durationMult` | `target` `"research"`/`"supply"`, `mult` | Applied to timers **started** while active |
| `rollsMult` | `mult` | Supply rolls for runs sent while active |
| `specialIntervalMult` | `mult` | Special customer spawn interval |
| `vaultEffAdd` | `add` (0…1) | Added to vault efficiency, capped at 1 |
| `reward` | `reward` Reward | Grant |
| `frenzy` | `mult` (default 5), `durationSec` (default 60) | Active boost |
| `spawnSpecial` | — | Spawn a special customer now |
| `karma` | `delta` Int | |
| `setFlag` | `flag` String | |
| `storyScene` | `sceneId` | |
| `freeRushRound` | — | One rush round without a ticket |
| `collectibleBonus` | `collectibleId`, `amount` | E.g. Ramadan lanterns |
| `stake` | `minutes` | Deducts current-kitchen cash equal to N minutes of income. Only valid as the first effect of a choice |

Example: `{ "type": "incomeMult", "scope": { "kind": "category", "value": "dishes" }, "mult": 3, "layer": "day" }`

### 0.6 `Condition`
| Field | Type | Default |
|---|---|---|
| `minLevel` | Int | 0 |
| `maxLevel` | Int | ∞ |
| `cityIds` | [String] | any |
| `kitchenKinds` | [KitchenKind] | any |
| `festivalIds` | [String] (any active) | none required |
| `weather` | [WeatherId] | any |
| `hours` | [Int, Int] (local start, end; wraps midnight) | any |
| `weekdays` | [Int] (1 = Sunday … 7 = Saturday, `Calendar` convention) | any |
| `requiresSystem` | SystemId | none |
| `minKarma` | Int | 0 |
| `flagsAll` / `flagsNone` | [String] | [] |
| `minPlayMin` | Double (lifetime active minutes) | 0 |

Example: `{ "minLevel": 10, "festivalIds": ["ramadan"], "hours": [18, 23] }`

### 0.7 `GoalType` and params (cities.json `goals[].type`)
| `type` | `params` | Default scope |
|---|---|---|
| `unlockStation` | `stationId` | city |
| `stationLevel` | `stationId`, `level` Int | city |
| `allStationsLevel` | `level` Int | city |
| `hireManager` | `stationId` | city |
| `managersCount` | `count` Int | city |
| `earnCash` | `amountBase` Double (×priceScale at runtime) | city |
| `incomeRate` | `amountBase` Double per second | city |
| `buyUpgrades` | `count` Int | city |
| `customersServed` | `count` Double | city |
| `tapCook` | `count` Int | city |
| `specialCustomers` | `count` Int | city |
| `choiceEvents` | `count` Int | slot |
| `rushRounds` | `count` Int, `minScore` Int? | slot |
| `collectVault` | `count` Int (each needs ≥ 30 min away) | slot |
| `startResearch` | `count` Int | slot |
| `researchLevels` | `count` Int (completed) | slot |
| `sendSupplyRun` | `count` Int | slot |
| `supplyReturns` | `count` Int | slot |
| `equipChefs` | `count` Int (currently equipped) | city |
| `chefTagMatch` | `count` Int | city |
| `dailyOrders` | `count` Int | slot |
| `contractGoals` | `count` Int | slot |
| `eventMilestones` | `count` Int | slot |
| `heritageItems` | `count` Int (new copies) | slot |
| `branchCollect` | `count` Int | slot |
| `leagueRep` | `amount` Int | slot |
| `twistMetric` | `metric` TwistMetric, `amount` Double (`...Base` metrics ×priceScale) | city |

`TwistMetric`: `busesWelcomed`, `ovenPerfects`, `chainUnits`, `shipmentsDelivered`, `deliveriesDone`, `weatherEarnedBase`, `nightEarnedBase`, `vipServed`.

### 0.8 `Twist` and `TwistType` params
Shape: `{ "type": TwistType, "params": { ... } }`. A kitchen has at most 2 twists, except Amman, which declares two `productionChain` entries that share a middle station. Defaults are in brackets.

| `type` | Params |
|---|---|
| `productionChain` | `inputStation` stationKey **R**, `outputStation` stationKey **R**, `ratio` Double [1], `outputMult` Double [3], `stockCapMin` Double [60] |
| `ovenTiming` | `station` **R**, `windowSec` [1.6], `perfectMult` [3], `minCycleSec` [2] |
| `busWaves` | `intervalMin` [20], `windowSec` [30], `waveMult` [4], `waveSec` [60], `stations` [stationKey] ([] = all) |
| `nightMarket` | `stations` [stationKey] **R** ([] = all), `startHour` [20], `endHour` [2], `nightMult` [3] |
| `portShipments` | `station` **R**, `intervalHours` [4], `dockHours` [3], `targetMin` [30], `rewardMin` [90], `offlineRewardFrac` [0.5] |
| `deliveryRuns` | `intervalMin` [10], `tripMin` [6], `rewardMin` [8], `scooters` [2], `queueMax` [5], `extraScooterCostsBase` [Double] (×priceScale), `dispatcherCostBase` Double, `offlineRewardFrac` [0.5], `rainMult` [1.5] |
| `weatherSwing` | `hotProb` [0.45], `coldProb` [0.15], `rainProb` [0.10], `hotDayStations` [], `coldDayStations` [], `rainDayStations` [], `mult` [2.5] |
| `vipLounge` | `loungeStation` **R**, `specialIntervalMult` [0.5], `vipShare` [0.6], `vipTierWeights` [[0.6, 0.3, 0.1]], `vipTipMin` [20], `levelPerTier` [40] |

Station references inside twist params are **station keys** (local to the kitchen), not full ids.

Example: `{ "type": "portShipments", "params": { "station": "oranges", "intervalHours": 4, "dockHours": 3, "targetMin": 30, "rewardMin": 90 } }`

### 0.9 `ContractRule`
`noManagers` · `noUpgrades` · `chefsOff` · `fastCheap` · `goldenHour` · `oneStation` (GDD 6.9). Shape: plain string.

### 0.10 `Unlock` (levels.json)
`{ "type": UnlockType, "id": String?, "value": Int? }`

| `UnlockType` | Meaning |
|---|---|
| `system` | `id` = SystemId |
| `chefSlots` | `value` = new slot count |
| `researchSlots` | `value` = new slot count |
| `supplySlots` | `value` = new slot count |
| `contractSlots` | `value` = new slot count |
| `ticketCap` | `value` = new cap |
| `freezeCap` | `value` = new cap |
| `sideGrade` | `value` = grade |
| `cosmetic` | `id` = cosmeticId |
| `visitor` | `id` = ArtKey for a new street visitor |
| `storyMemory` | `id` = sceneId |
| `title` | `id` = title text key |

### 0.11 Shared sub-objects
- `SideStation`: `{ "key": String R, "name": GText R, "art": ArtKey R, "tier": Int R (0–4), "cuisine": Cuisine R, "category": Category R, "weather": WeatherTag ["none"] }`
- `Ingredient`: `{ "key": String, "name": GText, "art": ArtKey }`
- `Rarities<T>`: `{ "common": T, "rare": T, "epic": T, "legendary": T }`

---

## 1. economy.json (global tuning)
| Field | Type | Unit | Example |
|---|---|---|---|
| `cityTiers` R | [`{ baseCost, growth, baseCycleSec, baseRevenue, managerMult }`] | base units / s | GDD 2.2 (8 rows) |
| `sideTiers` R | same shape | | 5 rows |
| `stationMilestones` | [Int] | levels | [10,25,50,100,150,200,250,300,350,400] |
| `allStationMilestones` | [Int] | | [25,50,100,150,200,250,300,400] |
| `sideStationMilestones` | [Int] | | [10,25,50,75,100,125,150] |
| `sideAllStationMilestones` | [Int] | | [25,50,100,150] |
| `milestoneMult` | Double | | 2 |
| `cycleFloorSec` | Double | s | 0.5 |
| `levelCaps` | [`{ fromCity, toCity, cap }`] | | [{1,3,100},{4,8,200},{9,16,300},{17,24,400}] |
| `sideLevelCap` | Int | | 150 |
| `upgradeBase` / `upgradeRatio` / `upgradeMult` | Double | base units | 2.5e5 / 20 / 3 |
| `sideUpgrades` | `{ base, ratio, count, targets: [String] }` | | {2e4, 30, 3, ["0","1","all"]} |
| `cityStartCashBase` / `sideStartCash` | Double | | 50 / 20 |
| `offline` | `{ baseCapHours, maxCapHours, baseEff, minGapSec, doubleGoldPerHour, doubleMin, doubleMax }` | | {3,16,0.5,60,10,5,160} |
| `freshDough` | `{ minGapHours, minutesPerDay, maxDays, mult }` | | {24,30,3,2} |
| `boosts` | `{ rushHourMult, rushHourAddPerLevel, rushWindows: [[Int,Int]], frenzyMult, frenzySec, frenzySecPerLevel, wallaMult, wallaMinMin, wallaMaxMin, wallaPerScore, wallaBankMaxMin, activeCap, dayCap }` | | {2,0.1,[[12,14],[19,22]],5,60,6,2,5,30,400,60,50,5} |
| `timeWarpShop` | `{ unlockLevel, goldPerHour, fourHourPrice, maxPerDay }` | | {24,10,36,3} |
| `rushTickets` | `{ regenHours, cap, capL35, overflowMax, goldPrice, maxBuyPerDay }` | | {3,3,4,9,10,3} |
| `vaultDouble` | `{ perDay }` | | {1} |
| `rushGoldPerMinute` | Double | gold per min | 1/6 |
| `branches` | `{ goldPerDayBase, goldPerLevel, softcapKnee, softcapCoef, safeCapHours, incomePerBranch, incomePerLevel, maxLevel, upgradeCosts: [Int] }` | | {0.5,0.2,10,2,8,0.10,0.02,10,[20,45,80,125,180,245,320,405,500,605]} |
| `grades` R | [`{ id, name, minLevel, targetFactor, goldMult, xpMult, goal1Chest }`] | | GDD 6.9 (5 rows) |
| `xp` | `{ perStar, cityBonusPerIndex, stationMilestone, stationUnlock, managerHire, graduationPerIndex, … }` | | {10,0.1,2,4,2,50} |
| `priceScaleFormula` | String (documentation only) | | "max(1, M_k/3)" |

Example:
```json
{ "version": 1,
  "cityTiers": [ { "baseCost": 5, "growth": 1.09, "baseCycleSec": 1, "baseRevenue": 1, "managerMult": 200 } ],
  "cycleFloorSec": 0.5, "upgradeBase": 250000, "upgradeRatio": 20, "upgradeMult": 3 }
```

## 2. cities.json
`{ "version": 1, "cities": [City] }` (24 entries, sorted by `index`)

**City:**
| Field | Type | Unit / notes | Default |
|---|---|---|---|
| `id` R | String | e.g. `jerusalem` | |
| `index` R | Int | 1…24 | |
| `name` R | GText | | |
| `region` R | Region | | |
| `currency` R | `{ name: GText, symbol: String, art: ArtKey }` | | |
| `landmarkArt` R | ArtKey | ≤ 64 pt on the map | |
| `decorArts` | [ArtKey] | street-scene props | [] |
| `palette` R | `{ skyTop, skyMid, sunset, glow, accent: Hex }` | | |
| `silhouette` | Silhouette | | `oldCity` |
| `levelCap` R | Int | 100/200/300/400 | |
| `licenceHours` R | Double | hours, from the previous city's open | |
| `finalGoalBase` R | Double | base units (GDD 3.1) | |
| `priceScale` R | Double | ≥ 1 | |
| `starsToGraduate` | Int | | ceil(0.75 × Σ stars) |
| `stations` R | [Station] | 6–8, ordered by tier | |
| `upgrades` R | [CashUpgrade] | generated by GDD 2.8 | |
| `goals` R | [Goal] | 15–24 | |
| `twists` | [Twist] | 0–2 | [] |
| `rival` R | `{ name: GText, art: ArtKey }` | | |
| `chapterId` R | String | story.json chapter | |
| `customerArts` | [ArtKey] | street visitors added in this city | [] |
| `rushIngredients` R | `{ bases: [Ingredient] (2), fillings: [Ingredient] (6) }` | | |

**Station:**
| Field | Type | Notes |
|---|---|---|
| `id` R | String | `"<cityId>.<key>"` |
| `key` R | String | local key |
| `name` R | GText | |
| `art` R | ArtKey | |
| `tier` R | Int | 0…7 = index in the city |
| `cuisine` R | Cuisine | |
| `category` R | Category | |
| `weather` | WeatherTag | default `none` |
| `managerName` | GText | default "معلّم {name}" |
| `managerArt` | ArtKey | default `ppl_man_cook` |

**CashUpgrade:** `{ "id": String R, "target": stationKey | "all" R, "mult": Double [3], "priceBase": Double R, "name": GText }`

**Goal:**
| Field | Type | Notes |
|---|---|---|
| `id` R | String | `"<cityId>.g<nn>"` |
| `type` R | GoalType | 0.7 |
| `params` R | Object | per type |
| `stars` R | Int | 1–3 |
| `scope` | `"city"` / `"slot"` | default per 0.7 |
| `text` R | GText | `{n}`, `{station}`, `{amount}` placeholders |
| `rewards` | [Reward] | extra rewards (chests, gold) |

Example (shortened):
```json
{ "id": "jaffa", "index": 5, "name": "يافا", "region": "palestine",
  "currency": { "name": "جنيه فلسطيني", "symbol": "ج.ف", "art": "ui_dollar" },
  "landmarkArt": "bld_sunset",
  "palette": { "skyTop": "#12324A", "skyMid": "#2E6E8E", "sunset": "#F08A24", "glow": "#FFD08A", "accent": "#F08A24" },
  "silhouette": "coast", "levelCap": 200, "licenceHours": 2, "finalGoalBase": 5.0e13, "priceScale": 1,
  "stations": [ { "id": "jaffa.oranges", "key": "oranges", "name": "برتقال يافاوي", "art": "food_tangerine", "tier": 0, "cuisine": "palestinian", "category": "street", "weather": "cold" } ],
  "upgrades": [ { "id": "jaffa.u00", "target": "oranges", "mult": 3, "priceBase": 250000, "name": "برتقال يافاوي: وصفة سرّية ×3" } ],
  "goals": [ { "id": "jaffa.g05", "type": "twistMetric", "params": { "metric": "shipmentsDelivered", "amount": 1 }, "stars": 1, "text": "حمّل أوّل شحنة برتقال", "rewards": [ { "type": "chest", "id": "wood", "amount": 1 } ] } ],
  "twists": [ { "type": "portShipments", "params": { "station": "oranges", "intervalHours": 4, "dockHours": 3, "targetMin": 30, "rewardMin": 90 } } ],
  "rival": { "name": "أم يوسف", "art": "ppl_woman" }, "chapterId": "ch05_jaffa",
  "rushIngredients": { "bases": [ { "key": "bread", "name": "خبز", "art": "food_bread" } ], "fillings": [ { "key": "fish", "name": "سمك", "art": "ani_fish" } ] } }
```

## 3. chefs.json
`{ "version": 1, "chefs": [Chef], "chests": [Chest], "rules": ChefRules }`

**Chef:**
| Field | Type | Notes | Default |
|---|---|---|---|
| `id` R | String | | |
| `name` R | GText | | |
| `rarity` R | Rarity | | |
| `art` R | ArtKey | portrait | |
| `cuisine` R | Cuisine | | |
| `category` R | Category | | |
| `source` | `chest` / `story` / `legacy` / `season` / `event` | `chest` = in the chest pool | `chest` |
| `seasonThemeIndex` | Int | for `season` chefs | |
| `skill` | Skill | epic/legendary only | none |
| `bio` | GText | one line | |

**Skill:** `{ "type": "categoryBoost" | "cuisineBoost" | "allBoost" | "instantIncome" | "spawnSpecial" | "frenzy", "value": String? (category/cuisine), "magnitude": Double (mult, or minutes for instantIncome), "durationSec": Double, "cooldownMin": Double, "name": GText }`

**Chest:** `{ "id": ChestId R, "name": GText, "art": ArtKey, "stacks": Int, "cards": Int, "goldMin": Int, "goldMax": Int, "odds": Rarities<Prob>, "guarantee": Rarity?, "price": Int }`

**ChefRules:**
- `rarityBase`: Rarities<Double>
- `perLevel` (0.25), `maxLevel` (10), `bothMatchFactor` (1.5)
- `cardsToLevel`: Rarities<[Int]> (9 each), `goldToLevel`: [Int] (9)
- `surplusGold`: Rarities<Int>
- `slotsByLevel`: [{ level, slots }]
- `pity`: { legendaryAfterChests 12, epicAfterSilver 5 }
- `newChefStackChance` (0.35), `stackWeights`: Rarities<Double>
- `dailyStall`: [{ slot, rarity, cards, price, weekdays? }]

Example:
```json
{ "id": "chefRami", "name": "الشيف رامي، ملك الفلافل", "rarity": "epic", "art": "ppl_man_cook",
  "cuisine": "palestinian", "category": "fried", "source": "chest",
  "skill": { "type": "categoryBoost", "value": "fried", "magnitude": 5, "durationSec": 180, "cooldownMin": 45, "name": "نار الصاج" },
  "bio": "قرص الفلافل عنده بطلع مدوّر زيّ القمر" }
```

## 4. research.json
`{ "version": 1, "baseMinutes": 10, "growth": 1.5, "capHours": 24, "costFloorFracOfFinal": 1e-6, "slotsByLevel": [{ "level": Int, "slots": Int }], "nodes": [Node] }`

**Node:**
| Field | Type | Notes |
|---|---|---|
| `id` R | String | |
| `name` R | GText | |
| `branch` R | `kitchen` / `customers` / `vault` / `empire` | notebook page |
| `art` | ArtKey | node icon |
| `effect` R | `{ "type": ResearchEffect, "perLevel": Double }` | |
| `maxLevel` R | Int | |
| `unlockLevel` R | Int | empire level |
| `requires` | [{ nodeId, level }] | prerequisites (default none) |
| `timeMult` R | Double | |
| `costMin` R | Double | minutes of income × level |
| `desc` R | GText | `{v}` = current value, `{next}` = next value |

`ResearchEffect`: `cityIncomePct`, `managerCostPct`, `stationCostPct`, `speedPct`, `specialRewardPct`, `frenzySec`, `rushHourAdd`, `happeningRewardPct`, `vaultCapHours`, `vaultEffPct`, `supplyTimePct`, `researchTimePct`, `branchGoldPct`, `branchCapHours`, `contractIncomePct`, `eventIncomePct`, `chefBonusPct`, `startStations`, `supplyRarityUpPct`. Percentages are fractions: 0.05 = 5%.

Example: `{ "id": "biggerVault", "name": "خزنة أكبر", "branch": "vault", "art": "ui_locked_with_key", "effect": { "type": "vaultCapHours", "perLevel": 1 }, "maxLevel": 9, "unlockLevel": 7, "timeMult": 0.6, "costMin": 3, "desc": "الخزنة بتوسع {v} ساعات زيادة" }`

## 5. vehicles.json
| Field | Type | Example |
|---|---|---|
| `slotsByLevel` | [{ level, slots }] | [{8,1},{10,2},{16,3},{90,4}] |
| `starLaunches` | [Int] | [4,10,25] |
| `starRollsPct` | Double | 0.15 |
| `star3CommonToEpic` | Double | 0.02 |
| `rollKinds` | `{ heritage, chefCards, gold, woodChest: Prob }` | {0.70,0.20,0.07,0.03} |
| `cardsPerRarity` | Rarities<Int> | {3,2,1,1} |
| `goldPerRarity` | Rarities<Int> | {2,4,7,10} |
| `unownedItemWeight` | Double | 2 |
| `vehicles` R | [Vehicle] | |

**Vehicle:** `{ "id" R, "name": GText R, "art": ArtKey R, "tier": Int R (0–5), "unlockLevel": Int R, "unlockAfter": { "vehicleId": String, "launches": Int }?, "durationsMin": [Double] R (3), "rolls": [Int] R (3), "rarityWeights": Rarities<Double> R }`

Example: `{ "id": "pickup", "name": "البكم", "art": "veh_pickup_truck", "tier": 1, "unlockLevel": 10, "unlockAfter": { "vehicleId": "tractor", "launches": 4 }, "durationsMin": [30, 90, 180], "rolls": [3, 4, 6], "rarityWeights": { "common": 68, "rare": 26, "epic": 5.5, "legendary": 0.5 } }`

## 6. heritage.json
`{ "version": 1, "copiesToLevel": [2,3,4,5], "maxLevel": 5, "setLevelFactor": 0.5, "craft": { "unlockLevel": 19, "salvage": Rarities<Int>, "cost": Rarities<Int> }, "case": { "rolls": 3, "rarityFloor": "rare" }, "sets": [Set], "items": [Item] }`

- **Set:** `{ "id" R, "name": GText R, "art": ArtKey, "bonus": { "type": HeritageBonus, "base": Double } R, "itemIds": [String] R (4) }`
- **Item:** `{ "id" R, "setId" R, "name": GText R, "art": ArtKey R, "rarity": Rarity R, "desc": GText }`
- `HeritageBonus`: `cityIncomePct`, `vaultCapHours`, `chefBonusPct`, `specialRewardPct`, `supplyTimePct`, `researchTimePct`, `sideIncomePct`, `branchGoldPct`.

Example: `{ "id": "houseKey", "setId": "memories", "name": "مفتاح دار سيدي", "art": "ui_old_key", "rarity": "legendary", "desc": "سيدي كان يحكي: المفتاح بيضل معنا" }`

## 7. contracts.json
`{ "version": 1, "schedule": Schedule, "slotsByLevel": [...], "partnerShareTotals": { "2": 0.30, "3": 0.40, "4": 0.50 }, "contracts": [Contract] }`

**Schedule:** `{ "epoch": DateYMD ("2026-01-05"), "newWeekday": 2, "rerunWeekdays": [4, 6], "availabilityDays": 7, "boardMax": 3, "rerunExclusionWeeks": 3 }`. Weekdays use the `Calendar` convention: 2 = Monday.

**Contract:**
| Field | Type | Notes |
|---|---|---|
| `id` R | String | |
| `releaseOrder` R | Int | 1…N |
| `title` R | GText | |
| `art` R | ArtKey | |
| `desc` | GText | 1–2 lines |
| `durationHours` R | Double | 48…120 |
| `stations` R | [SideStation] | 1…5 |
| `goalsBase` R | [Double] | 3 (×gradeFactor at runtime) |
| `partners` R | [{ "nameKey": String?, "name": GText?, "art": ArtKey, "share": Prob, "gamma": Double }] | 2…4. `nameKey` refers to the league name pool |
| `rules` | [ContractRule] | default [] |
| `twists` | [Twist] | default [] |
| `rewards` R | `{ "goal1": [Reward], "goal2": [Reward], "goal3": [Reward] }` | goal2 should contain `{zaatar 1}`; the runtime swaps it for 50 gold on repeats |

Example:
```json
{ "id": "jaffaHisbeh", "releaseOrder": 20, "title": "حسبة يافا", "art": "veh_ship", "durationHours": 96,
  "stations": [ { "key": "fish", "name": "سمك", "art": "ani_fish", "tier": 0, "cuisine": "palestinian", "category": "seafood" } ],
  "goalsBase": [1.98e10, 4.95e11, 9.9e12],
  "partners": [ { "nameKey": "abuShaker", "art": "ppl_woman", "share": 0.15, "gamma": 1.0 } ],
  "twists": [ { "type": "portShipments", "params": { "station": "fish" } } ],
  "rewards": { "goal1": [ { "type": "gold", "amount": 10 }, { "type": "chest", "id": "wood", "amount": 1 } ],
               "goal2": [ { "type": "zaatar", "amount": 1 } ],
               "goal3": [ { "type": "chefCards", "id": "abuAliAlex", "amount": 3 } ] } }
```

## 8. events.json
| Field | Type | Notes |
|---|---|---|
| `startWeekday` | Int | 5 = Thursday |
| `durationHours` | Double | 96 |
| `rotation` R | [themeId] | non-festival order |
| `festivalOverrides` | [{ festivalId, themeId }] | |
| `milestones` R | [{ "base": Double, "rewards": [Reward], "unlocksStation": Int? }] | 10 |
| `rankRewards` | [{ fromRank, toRank, rewards: [Reward] }] | |
| `npcCount` | Int | 20 |
| `npcSigma` | Double | 0.6 |
| `tokenConversion` | `{ "tokensPerGold": 5, "maxGold": 20 }` | |
| `shop` R | [{ "id", "reward": Reward, "price": Int, "max": Int }] | |
| `themes` R | [Theme] | |

**Theme:** `{ "id" R, "name": GText R, "art": ArtKey R, "palette": {…Hex}, "eventCash": { "name": GText, "art": ArtKey } R, "tokens": { "name": GText, "art": ArtKey } R, "stations": [SideStation] R (4), "twists": [Twist], "chefId": String R, "decorationId": cosmeticId, "festivalOnly": Bool [false], "requiresFestival": String? }`

Example: `{ "id": "knafehFestival", "name": "مهرجان الكنافة", "art": "food_pie", "eventCash": { "name": "مصاري الكنافة", "art": "ui_money_bag" }, "tokens": { "name": "صواني", "art": "food_pie" }, "stations": [ { "key": "knafeh", "name": "كنافة", "art": "food_pie", "tier": 2, "cuisine": "palestinian", "category": "sweets" } ], "twists": [ { "type": "ovenTiming", "params": { "station": "knafeh", "minCycleSec": 2 } } ], "chefId": "ozanBaklava", "decorationId": "goldTray" }`

## 9. happenings.json
`{ "version": 1, "specials": Specials, "choiceRules": ChoiceRules, "choices": [ChoiceRow], "offline": OfflineRules, "rushHours": [RushHour], "inspector": Inspector, "karmaRewards": [{ "karma": Int, "rewards": [Reward] }] }`

- **Specials:** `{ "unlockLevel": 3, "minSec": 300, "rangeSec": 600, "power": 5, "forceSec": 900, "onScreenSec": 15, "outcomes": [SpecialOutcome] }`
- **SpecialOutcome:** `{ "id" R, "name": GText R, "art": ArtKey R, "weight": Double R, "effects": [Effect] R, "condition": Condition?, "fallbackId": String? (used when the condition fails), "eventReplacement": [Effect]? (tokens in the weekend venue) }`
  - Tip formula: `{ "type": "reward", "reward": { "type": "incomeMin", "amount": 15 } }`, and `capCashFrac 0.15` / `floorMin 2` are special-cased by outcome id `tip`.
- **ChoiceRules:** `{ "unlockLevel": 10, "firstAfterPlayMin": 10, "gapMinSec": 180, "gapMaxSec": 360, "maxPerDay": 4, "cooldownDays": 7 }`
- **ChoiceRow:**

| Field | Type | Notes |
|---|---|---|
| `id` R | String | |
| `art` R | ArtKey | |
| `title` R | GText | |
| `body` R | GText | `{rival}`, `{city}` placeholders |
| `weight` | Double | default 1 |
| `condition` | Condition | |
| `choices` R | [Choice] | 2–3 |
| `offline` | `{ "allowed": Bool, "autoChoice": Int, "newsText": GText }` | default not allowed |

- **Choice:** `{ "label": GText R, "hint": "sure" | "luck" ["sure"], "outcomes": [{ "p": Prob, "effects": [Effect], "text": GText }] R }`. The p values must sum to 1. A `stake` effect may only appear first.
- **OfflineRules:** `{ "minAwayMin": 60, "maxPerReturn": 2, "maxPerDay": 3 }`
- **RushHour:** `{ "id": "lunch" | "dinner", "startHour": Int, "endHour": Int, "mult": Double }`
- **Inspector:** `{ "unlockLevel": 18, "intervalDays": [4, 6, 8] (triangular), "hourRange": [10, 20], "warningHours": 12, "checks": [{ "id", "name": GText, "full": 2.5, "partial": 1.5 }], "rewardBands": [{ "minScore": Double, "rewards": [Reward] }], "xpPerPoint": 4, "repPerPoint": 2 }`

Example ChoiceRow:
```json
{ "id": "neighborLoan", "art": "ppl_man", "title": "جارك بدّه دين",
  "body": { "m": "أبو العبد بدّه دين لآخر الشهر، بتدينه؟", "f": "أبو العبد بدّه دين لآخر الشهر، بتدينيه؟" },
  "condition": { "minLevel": 10 },
  "choices": [
    { "label": "تفضّل", "hint": "luck", "outcomes": [
      { "p": 0.7, "effects": [ { "type": "stake", "minutes": 5 }, { "type": "reward", "reward": { "type": "incomeMin", "amount": 15 } }, { "type": "karma", "delta": 1 } ], "text": "رجّعلك الدين وزيادة!" },
      { "p": 0.3, "effects": [ { "type": "stake", "minutes": 5 }, { "type": "reward", "reward": { "type": "incomeMin", "amount": 5 } }, { "type": "reward", "reward": { "type": "heritageItem", "rarity": "common", "amount": 1 } }, { "type": "karma", "delta": 1 } ], "text": "رجّع جزء، وجابلك هديّة من دار أبوه" } ] },
    { "label": "معلش هسّا لأ", "outcomes": [ { "p": 1, "effects": [ { "type": "reward", "reward": { "type": "rep", "amount": 5 } } ], "text": "ولا يهمّك، بفهم" } ] } ] }
```

## 10. market.json
`{ "version": 1, "unlockLevel": 13, "perDay": { "default": 1, "friday": 2 }, "cooldownDays": 5, "modifiers": [MarketModifier], "weather": Weather }`

- **MarketModifier:** `{ "id" R, "name": GText R, "art": ArtKey R, "desc": GText R, "weight": Double R, "effects": [Effect] R, "weekdays": [Int]?, "festive": Bool [false] }`
- **Weather:** `{ "types": [{ "id": WeatherId, "name": GText, "art": ArtKey, "effects": [Effect] }], "seasons": [{ "months": [Int], "probs": { "sunny": Prob, "hot": Prob, "cold": Prob, "rainy": Prob } }] }`. Month lists must cover 1–12 exactly once.

Example: `{ "id": "hummusDay", "name": "يوم الحمّص", "art": "food_hummus_bowl", "desc": "الطبخات ×3 اليوم كلّه", "weight": 8, "effects": [ { "type": "incomeMult", "scope": { "kind": "category", "value": "dishes" }, "mult": 3, "layer": "day" } ] }`

## 11. levels.json
| Field | Type | Example |
|---|---|---|
| `xpCurve` R | `{ "a": 15, "p": 1.36, "roundTo": 5, "after100": 8000 }` | |
| `goldByLevel` | [{ from, to, gold }] | [{2,10,10},{11,30,15},{31,60,20},{61,100,25}] |
| `levels` R | [{ "level": Int, "unlocks": [Unlock], "rewards": [Reward], "ceremony": Bool }] | 1…100. Explicit rows win over generic rules; generic gold and chests are already expanded here by the content tool |
| `titles` R | [{ "level": Int, "name": GText }] | 21 entries |
| `beyond100Rewards` | [Reward] | [{gold 25}, {chest wood}] |

Example: `{ "level": 8, "unlocks": [ { "type": "system", "id": "supply" }, { "type": "system", "id": "heritage" }, { "type": "supplySlots", "value": 1 }, { "type": "chefSlots", "value": 2 } ], "rewards": [ { "type": "gold", "amount": 10 } ], "ceremony": true }`

## 12. league.json
| Field | Type | Notes |
|---|---|---|
| `unlockLevel` | Int | 12 |
| `groupSize` | Int | 30 |
| `defaultBaseline` | Double | 1400 |
| `firstWeekQ` | Double | 0.35 |
| `sigma` | Double | 0.45 |
| `noiseDaily` | Double | 0.03 |
| `tiers` R | [{ "id": Int, "name": GText, "art": ArtKey, "promote": Int, "demote": Int, "q": Double }] | 10 |
| `archetypes` R | [{ "id": "steady" \| "earlyBird" \| "weekendBurst" \| "closer" \| "sprinter", "weight": Prob }] | curves are fixed in code (GDD 6.7) |
| `rewards` R | [{ "fromRank", "toRank", "goldBase", "goldPerTier", "chest": ChestId?, "chestFromTier6": ChestId? }] | |
| `promotionRewards` | [Reward] | [wood chest] |
| `repSources` | Object<String, Double> | keys = GDD 6.7 source ids |
| `names` R | `{ "fixed": [{ "key", "name": GText }], "prefixes": [GText], "suffixes": [GText] }` | |
| `avatars` R | [ArtKey] | |

Example tier: `{ "id": 3, "name": "كشك", "art": "ui_medal_3rd", "promote": 10, "demote": 5, "q": 0.9 }`

## 13. quests.json
`{ "version": 1, "unlockLevel": 9, "bands": [{ "id": Int, "minLevel": Int, "maxLevel": Int }], "dailyReward": [Reward], "dailyBonus": [Reward], "weeklyReward": [Reward], "weeklyBonus": [Reward], "reroll": { "freePerDay": 1, "cost": 5, "maxPerDay": 3 }, "daily": [QuestTemplate], "weekly": [QuestTemplate] }`

**QuestTemplate:**
| Field | Type | Notes |
|---|---|---|
| `id` R | String | |
| `text` R | GText | `{n}` = target |
| `metric` R | QuestMetric | |
| `difficulty` | `easy` / `medium` / `hard` | daily only |
| `targets` R | [Double] | one per band (5), or 1 value for all |
| `condition` | Condition | unlock and system gating |
| `eligibility` | EligibilityRule | runtime check |

- `QuestMetric`: `levelsBought`, `goalsClaimed`, `specials`, `rushRounds`, `choices`, `runsSent`, `runsClaimed`, `researchStarted`, `researchCompleted`, `earnMinutes`, `stationMilestones`, `vaultCollects`, `branchCollects`, `contractPct`, `contractGoals`, `eventMilestones`, `tapCooks`, `chestsOpened`, `rep`, `upgradesBought`, `dailyOrders`, `stars`, `calendarClaims`, `chefLevelUps`.
- `EligibilityRule`: `always`, `goalsRemaining`, `researchSlotFree`, `stationBelowCap`, `unmanagedStation`, `chestInInventory`, `activeContract`, `eventLive`, `upgradeWithin30Min`, `chefUpgradable`, `starsRemaining`.

Example: `{ "id": "buyLevels", "text": "اشتري {n} مستوى بالمحطّات", "metric": "levelsBought", "difficulty": "medium", "targets": [40, 80, 150, 250, 400], "eligibility": "always" }`

## 14. calendar.json
`{ "version": 1, "unlockLevel": 9, "days": [{ "day": Int, "rewards": [Reward], "big": Bool }] (28), "goldScalePerCycle": 0.1, "goldScaleMax": 2, "streak": Streak }`

**Streak:** `{ "milestones": [{ "days": Int, "rewards": [Reward] }], "freezeCaps": [{ "level": Int, "cap": Int }], "freezePrice": 50, "repair": { "orders": 6, "days": 2, "bonusDays": 2 } }`

Example day: `{ "day": 28, "rewards": [ { "type": "zaatar", "amount": 1 }, { "type": "chest", "id": "silver", "amount": 1 } ], "big": true }`

## 15. season.json
| Field | Type | Example |
|---|---|---|
| `unlockLevel` | Int | 16 |
| `epoch` R | DateYMD | "2026-01-05" |
| `lengthDays` | Int | 42 |
| `pointsPerTier` | Int | 140 |
| `tiers` R | [{ "tier": Int, "rewards": [Reward] }] | 50 |
| `overflow` | `{ "pointsPer": 300, "rewards": [Reward], "max": 10 }` | |
| `lateJoinerMaxMult` | Double | 2 |
| `points` R | Object<String, `{ "amount": Double, "dailyCap": Double? }`> | keys: dailyOrder, dailyBonus, weeklyOrder, weeklyBonus, calendar, goalStar, contractGoal1/2/3, eventMilestone, leagueWeek, leaguePromotion, researchLevel, supplyRun, rushRound, special |
| `themes` R | [{ "index": Int, "id", "name": GText, "art": ArtKey, "chefId": String, "cosmeticIds": [String], "eventTwist": Twist? }] | 8 |

Example theme: `{ "index": 3, "id": "oliveSeason", "name": "موسم الزيتون", "art": "food_olive", "chefId": "sAbuZeit", "cosmeticIds": ["awningOliveSeason"], "eventTwist": { "type": "productionChain", "params": { "inputStation": "olives", "outputStation": "oilZaatar" } } }`

## 16. festivals.json
`{ "version": 1, "sunsetRef": { "lat": 31.78, "lon": 35.23 }, "quietDates": [DateMD], "festivals": [Festival] }`

**Festival:**
| Field | Type | Notes |
|---|---|---|
| `id` R | String | |
| `name` R | GText | |
| `neutralName` | GText | used when "زينة المواسم" is off (default "أيام البركة") |
| `art` R | ArtKey | |
| `calendar` R | `hijri` / `gregorian` | |
| `start` R / `end` R | `{ "month": Int, "day": Int }` | `end` may wrap the year (Dec → Jan) |
| `eveDays` | Int | decorations before the start (default 0) |
| `extraEndDays` | Int | sighting tolerance (default 0) |
| `effects` | [Effect] | day-layer effects |
| `activeWindows` | [{ "kind": "iftar" \| "suhoor" \| "fixed", "startOffsetMin": Int?, "endOffsetMin": Int?, "startHour": Double?, "endHour": Double?, "mult": Double, "replacesRushHour": String? }] | |
| `dailyClaim` | [Reward] | e.g. عيدية |
| `collectible` | `{ "id", "name": GText, "art": ArtKey, "count": Int, "milestones": [{ "count", "rewards": [Reward] }] }` | |
| `eventThemeId` | String | |
| `happeningTag` | String | enables choice rows whose `condition.festivalIds` contains this id |
| `storySceneId` | String | |
| `notificationQuiet` | `{ "start": "HH:mm", "end": "HH:mm", "streakRiskAt": "HH:mm" }` | |

Example:
```json
{ "id": "ramadan", "name": "رمضان", "art": "ui_crescent_moon", "calendar": "hijri",
  "start": { "month": 9, "day": 1 }, "end": { "month": 9, "day": 30 }, "eveDays": 1,
  "activeWindows": [
    { "kind": "iftar", "startOffsetMin": -10, "endOffsetMin": 80, "mult": 5, "replacesRushHour": "dinner" },
    { "kind": "suhoor", "startHour": 2, "endHour": 4.5, "mult": 2 } ],
  "collectible": { "id": "lantern", "name": "فانوس", "art": "ui_lantern", "count": 30,
    "milestones": [ { "count": 10, "rewards": [ { "type": "chest", "id": "silver", "amount": 1 } ] } ] },
  "eventThemeId": "ramadanNights",
  "notificationQuiet": { "start": "23:30", "end": "10:00", "streakRiskAt": "21:30" } }
```

## 17. achievements.json
`{ "version": 1, "tierRewards": [{ "gold": Int, "xp": Int }] (5), "families": [Family] }`

- **Family:** `{ "id" R, "name": GText R, "art": ArtKey R, "metric": StatId R, "tiers": [Double] R (5, ascending), "desc": GText (with {n}) }`
- `StatId` is any lifetime counter in `GameSave.stats`: `tapCooks`, `customers`, `starsEarned`, `citiesGraduated`, `crowns`, `empireLevel`, `managersHired`, `upgradesBought`, `stationsMaxed`, `chefsOwned`, `chefsAtMax`, `bestChefLevel`, `chestsOpened`, `researchLevels`, `runsClaimed`, `heritageUnique`, `setsCompleted`, `contractsCompleted`, `eventsMaxed`, `bestLeagueTier`, `seasonsCompleted`, `bestStreak`, `calendarClaims`, `dailyOrders`, `specials`, `choices`, `rushRounds`, `zaatar`, `branchLevels`, `festivals`, `karma`.

Example: `{ "id": "specials", "name": "صياد الزباين", "art": "ui_bellhop_bell", "metric": "specials", "tiers": [10, 50, 200, 500, 1500], "desc": "استقبل {n} زبون مميّز" }`

## 18. story.json
`{ "version": 1, "cast": [{ "id", "name": GText, "art": ArtKey }], "chapters": [{ "id", "cityId", "scenes": [Scene] }], "extraScenes": [Scene], "memories": [Scene] }`

**Scene:**
| Field | Type | Notes |
|---|---|---|
| `id` R | String | |
| `trigger` R | `arrival` / `rival` / `midpoint` / `finale` / `festival` / `memory` / `manual` | |
| `triggerParam` | String / Double | e.g. festivalId, star fraction |
| `lines` R | [{ "speaker": castId \| "player" \| "rival", "text": GText }] | 2–5 lines, ≤ 12 words each |
| `rewards` | [Reward] | |

Example:
```json
{ "id": "ch01_rival", "trigger": "rival", "triggerParam": 0.25, "lines": [
  { "speaker": "rival", "text": "أهلين بالجار الجديد! فلافلي أطيب فلافل بالقدس… بس منشوف." },
  { "speaker": "sitti", "text": "لا تخاف منه، قلبه طيّب، بسّ بموت بالمنافسة." } ] }
```

## 19. ftue.json
`{ "version": 1, "steps": [FtueStep], "unlockSpotlights": [{ "systemId": SystemId, "steps": [{ "anchor": String, "text": GText }] }] }`

**FtueStep:**
| Field | Type | Notes |
|---|---|---|
| `id` R | Int | 1…19 |
| `start` R | `{ "type": StartType, "value": Double?, "id": String? }` | |
| `anchors` | [String] | fxAnchor ids, spotlighted in order |
| `soft` | Bool | bubble only, no overlay (default false) |
| `text` R | GText | |
| `complete` R | `{ "type": CompleteType, "value": Double?, "id": String? }` | |
| `feedback` | FeedbackTier | |
| `script` | Object | e.g. `{ "forceSpecialOutcome": "frenzy" }`, `{ "scriptedChest": { "chest": "wood", "chefId": "samiFryer" } }`, `{ "askNotifications": true }` |

- `StartType`: `firstFrame`, `stepDone`, `cashAtLeast`, `cashForNextLevel`, `levelReached`, `afterSec`, `relaunchAway`, `graduationReady`, `upgradeAffordable`, `managerAffordable`.
- `CompleteType`: `tapCook`, `cashAtLeast`, `stationLevel`, `stationUnlocked`, `goalClaimed`, `managerHired`, `buyMode`, `specialTapped`, `upgradeBought`, `chefEquipped`, `bubbleClosed`, `vaultCollected`, `screenViewed`, `researchStarted`, `runSent`, `graduated`.

Example: `{ "id": 3, "start": { "type": "cashForNextLevel", "id": "jerusalem.falafel" }, "anchors": ["station.0.buy"], "text": "اشتري مستوى كمان، الزباين بستنّوا!", "complete": { "type": "stationLevel", "id": "jerusalem.falafel", "value": 2 }, "feedback": "t0" }`

## 20. cosmetics.json
`{ "version": 1, "cosmetics": [Cosmetic] }`

**Cosmetic:** `{ "id" R, "name": GText R, "slot": CosmeticSlot R, "art": ArtKey?, "pattern": String? (vector pattern id: stripes, tatreez, keffiyeh, solid, sunset, royal), "colors": [Hex]?, "price": Int? (gold; null = not sold), "source": "default" | "level" | "shop" | "event" | "season" | "achievement" | "festival" | "legacy" | "streak" }`. Exactly one default per slot.

Example: `{ "id": "awningKeffiyeh", "name": "مظلّة كوفيّة", "slot": "awning", "pattern": "keffiyeh", "colors": ["#1A1A1A", "#FFFFFF"], "source": "level" }`

## 21. strings.json (UI chrome and notifications)
`{ "version": 1, "strings": { "<key>": GText } }`. Flat keys grouped by prefix. Content names stay inline in the content files.

| Prefix | Examples |
|---|---|
| `tab.` | `tab.map` "الخريطة", `tab.tasks` "المهام", `tab.home` "البسطة", `tab.chefs` "الطبّاخين", `tab.shop` "الدكان" |
| `btn.` | `btn.collect` "اجمع", `btn.claim` "خذ", `btn.buy` "اشتري", `btn.hire` "وظّف", `btn.send` "ابعت", `btn.skip` "تخطّي", `btn.double` "اجمع ×2" |
| `hud.` | `hud.locked` "مستوى {n}", `hud.perSec` "{v}/ث", `hud.max` "مكتمل" |
| `num.` | scale words: `num.e6` "مليون", `num.e9` "مليار", `num.e12` "تريليون", `num.e15` "كوادريليون", `num.e18` "كوينتليون", `num.e21` "سكستليون", `num.e24` "سبتليون", `num.e27` "أوكتليون", `num.e30` "نونليون", `num.e33` "ديسيليون" |
| `time.` | `time.h` "س", `time.m` "د", `time.s` "ث", `time.days` "{n} أيام" |
| `notif.` | the 8 notification texts (GDD 6.15) |
| `ftue.`, `ceremony.<systemId>` | unlock ceremony title and one-liner per system |
| `banner.` | `banner.rushHour` "ساعة الذروة! الدخل دبل", `banner.clock` "ساعة الجهاز رجعت لورا، الوقت موقّف لحد ما ترجع" |
| `settings.`, `credits.` | `credits.developer` "Developer: Saad", `credits.fluent` "Fluent Emoji 3D — MIT License, Microsoft", `credits.fonts` "Baloo Bhaijaan 2 · Cairo — SIL Open Font License 1.1" |

Example: `{ "version": 1, "strings": { "btn.collect": "اجمع", "notif.streakRisk": { "m": "سلسلتك {n} يوم! طلب واحد بيحميها", "f": "سلسلتك {n} يوم! طلب واحد بيحميها" } } }`

---

## 22. Cross-file reference checks (validator)
| From | To |
|---|---|
| `cities[].stations[].id` | unique globally; prefix = city id |
| `cities[].goals[].params.stationId` | a station of the same city |
| `cities[].twists[].params.*Station*` | station keys of the same city |
| `cities[].chapterId` | `story.chapters[].id` |
| `chefs.chefs[].seasonThemeIndex` | `season.themes[].index` |
| `events.themes[].chefId`, `contracts[].rewards…id` (chefCards) | `chefs.chefs[].id` |
| `events.rotation[]`, `festivals[].eventThemeId` | `events.themes[].id` |
| `heritage.sets[].itemIds` | `heritage.items[].id` (exactly 4, matching setId) |
| `Reward.id` for `heritageItem` / `cosmetic` / `storyScene` | the matching file |
| `levels.levels[].unlocks[].id` (`system`) | SystemId enum; (`cosmetic`) cosmetics.json |
| `contracts[].partners[].nameKey` | `league.names.fixed[].key` |
| Every `ArtKey` | `tools/art_keys.txt` |
| Every `Prob` set | sums to 1 (outcomes, odds, rollKinds, weather probs) |
| `finalGoalBase × priceScale` | < 1e30 |
