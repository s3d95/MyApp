import Foundation

// MARK: - Choice events (happenings.json)

struct ConditionDef: Decodable {
    var minLevel = 0
    var maxLevel = 9999
    var cityIds: [String] = []
    var festivalIds: [String] = []
    var weather: [String] = []
    var hours: [Int] = []
    var weekdays: [Int] = []
    var requiresSystem: String? = nil
    var minKarma = 0
    var flagsAll: [String] = []
    var flagsNone: [String] = []
    var minPlayMin: Double = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        minLevel = c.int("minLevel", 0)
        maxLevel = c.int("maxLevel", 9999)
        cityIds = c.v("cityIds", [])
        festivalIds = c.v("festivalIds", [])
        weather = c.v("weather", [])
        hours = c.v("hours", [])
        weekdays = c.v("weekdays", [])
        requiresSystem = c.opt("requiresSystem")
        minKarma = c.int("minKarma", 0)
        flagsAll = c.v("flagsAll", [])
        flagsNone = c.v("flagsNone", [])
        minPlayMin = c.dbl("minPlayMin", 0)
    }
}

struct EffectDef: Decodable {
    var type = ""
    var scopeKind = "all"
    var scopeValue: String? = nil
    var mult: Double = 1
    var layer = "active"
    var durationSec: Double? = nil
    var reward: Reward? = nil
    var delta = 0
    var flag: String? = nil
    var sceneId: String? = nil
    var minutes: Double = 0
    var target: String? = nil
    var add: Double = 0

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        type = c.v("type", "")
        if let sc = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("scope")) {
            scopeKind = sc.v("kind", "all")
            scopeValue = sc.opt("value")
        }
        mult = c.dbl("mult", type == "frenzy" ? 5 : 1)
        layer = c.v("layer", "active")
        durationSec = c.dblOpt("durationSec")
        reward = c.opt("reward")
        delta = c.int("delta", 0)
        flag = c.opt("flag")
        sceneId = c.opt("sceneId")
        minutes = c.dbl("minutes", 0)
        target = c.opt("target")
        add = c.dbl("add", 0)
    }
}

struct OutcomeDef: Decodable {
    var p: Double = 1
    var effects: [EffectDef] = []
    var text = GText("")

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        p = c.dbl("p", 1)
        effects = c.v("effects", [])
        text = c.v("text", GText(""))
    }
}

struct ChoiceOptDef: Decodable {
    var label = GText("")
    var hint = "sure"
    var outcomes: [OutcomeDef] = []

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        label = c.v("label", GText(""))
        hint = c.v("hint", "sure")
        outcomes = c.v("outcomes", [])
    }
}

struct ChoiceRowDef: Decodable, Identifiable {
    var id = ""
    var art = "ppl_person"
    var title = GText("")
    var body = GText("")
    var weight: Double = 1
    var condition = ConditionDef()
    var choices: [ChoiceOptDef] = []

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = c.v("id", "")
        art = c.v("art", art)
        title = c.v("title", GText(""))
        body = c.v("body", GText(""))
        weight = c.dbl("weight", 1)
        condition = c.v("condition", ConditionDef())
        choices = c.v("choices", [])
    }
}

struct KarmaRewardDef: Decodable {
    var karma = 5
    var rewards: [Reward] = []

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        karma = c.int("karma", 5)
        rewards = c.v("rewards", [])
    }
}

struct HappeningsFile: Decodable {
    var choiceUnlockLevel = 10
    var firstAfterPlayMin: Double = 10
    var gapMinSec: Double = 180
    var gapMaxSec: Double = 360
    var maxPerDay = 4
    var cooldownDays = 7
    var choices: [ChoiceRowDef] = []
    var karmaRewards: [KarmaRewardDef] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        if let r = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: AnyKey("choiceRules")) {
            choiceUnlockLevel = r.int("unlockLevel", choiceUnlockLevel)
            firstAfterPlayMin = r.dbl("firstAfterPlayMin", firstAfterPlayMin)
            gapMinSec = r.dbl("gapMinSec", gapMinSec)
            gapMaxSec = r.dbl("gapMaxSec", gapMaxSec)
            maxPerDay = r.int("maxPerDay", maxPerDay)
            cooldownDays = r.int("cooldownDays", cooldownDays)
        }
        choices = c.v("choices", [])
        karmaRewards = c.v("karmaRewards", [])
    }
}
