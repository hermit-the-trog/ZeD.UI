-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/EvolvingTraitsWorld.lua
-- ============================================================================
-- SUPPORT FOR EVOLVING TRAITS WORLD (mod id EvolvingTraitsWorld, Workshop 2914075159, by MusicManiac)
-- In the look of the approved Traits tab (mockup zed_traits_tab_v1, ModSupport/traitsAsSkills.lua).
--
-- The mod makes traits change with play and puts its own "ETW" page in the game's
-- Character window, which ZeD never shows (its UI/ETW_CharacterPage.lua: sub-tabs
-- Vitals, Permanent Traits (Combat, Non-Combat), Non-permanent Traits (Physical,
-- Mental), Recent Events, Help). Its trait progress lands in ZeD's Traits tab instead:
--   * with Traits As Skills on, that mod's support owns the tab, and these rows are a
--     section of their own under a section head with this mod's name (ZeD.TraitsTab);
--   * without it, this file registers the Traits tab itself, right after Skills.
-- One row per progress the mod's page shows, in its groups (Vitals, Combat traits,
-- Non-combat traits, Physical traits, Mental traits, then the Delayed Traits System's
-- list), drawn like a Skills row: a square with the state (+ while the row gives you a
-- good trait, - a bad one), the name, a strip filled to the mod's own bar value with a
-- tick, framed green or red, wherever the mod gains or loses a trait, and the trait(s)
-- you have now at the right. The row's fill is the progress toward the next tick. The
-- details at the foot follow the focused (or hovered) row: the mod's bar with its "+ /-"
-- marks, the mod's own numbers ("Current value: ...", "3/5"), where each trait comes or
-- goes, and the mod's own description of what moves the progress.
--
-- Everything is read from the mod through pcall: its mod data (getETWModData), its
-- sandbox options, its checks for which systems run (ETW_CommonLogicChecks.*ShouldExecute),
-- its helpers (immunity thresholds, kill counts, Prowess kill needs) and its words. The
-- maths that turns them into each bar is the mod page's own, copied line for line from
-- ISETWUI:render (the mod keeps it inside the drawing; it exports no function for it).
-- Nothing is stored. Its sandbox options that hide things are kept: UIPage off hides the
-- rows (a line says so), DisableAllDynamicTraits drops the tab like the mod drops its page,
-- every system the mod switches off is left out, and its client option Hide Smoker bar.
-- ============================================================================

local MOD_ID = "EvolvingTraitsWorld"
local TAS_ID = "traitsAsSkills"

-- is a mod on in this game? (ids in the list may start with a backslash)
local function modOn(want)
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    for i = 0, list:size() - 1 do
        -- gsub returns the new text and a count; the brackets keep only the text
        local id = (tostring(list:get(i)):gsub("^\\", ""))
        if id == want then return true end
    end
    return false
end
if not modOn(MOD_ID) then return end

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ZeD_CharacterWindow"
require "ZeD/ModSupport/TraitsTab"

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.EvolvingTraitsWorld = S

local TAB_ID = "traits"
-- with Traits As Skills on, its support owns the Traits tab; this file only adds a source
local HOSTED = modOn(TAS_ID)
S.hosted = HOSTED

-- design units (the Traits tab's: ModSupport/traitsAsSkills.lua)
local PAD, CAT_H, BADGE_W, NAME_W, STRIP_W, STRIP_H, DET_H, FIND_W, KEY_W = 10, 20, 20, 112, 138, 13, 218, 150, 76
-- the fill and square strengths of a Skills row (SkillsTab getProgressColors), the approved look
local FILL_A, FILL_TOP_A, SQ_ON_A, SQ_OFF_A = 0.45, 0.55, 0.25, 0.12
-- the mod's groups in its page's order; the first two are its Permanent Traits sub-tabs,
-- the next two its Non-permanent ones, the last its Delayed Traits System list
local CAT_ORDER = { "vitals", "combat", "noncombat", "physical", "mental", "delayed" }
local CAT_KEY = {
    vitals = "UI_ETW_SubTab_Vitals", combat = "UI_ETW_SubTab_CombatTraits", noncombat = "UI_ETW_SubTab_NonCombatTraits",
    physical = "UI_ETW_SubTab_PhysicalTraits", mental = "UI_ETW_SubTab_MentalTraits", delayed = "Sandbox_ETW_DelayedTraitsSystem",
}
-- the sub-tab a group sits in on the mod's page (for the details' title row)
local CAT_PARENT = {
    combat = "UI_ETW_SubTab_Progress", noncombat = "UI_ETW_SubTab_Progress",
    physical = "UI_ETW_SubTab_NonPermanent", mental = "UI_ETW_SubTab_NonPermanent",
}

S.find = ""      -- the Find box's text (own tab only; hosted, the host's Find is passed in)
S.only = false   -- All (false) or With a trait (true) (own tab only)
S.closed = {}    -- folded groups by name; "*mod" folds the whole section when hosted

local function tr(k, ...) return ZeD.tr(k, ...) end
local function F(n) return ZeD.TM:getFontHeight(ZeD.T["fontF" .. n]) end

-- ---------------------------------------------------------------------------
-- THE MOD (read only, through pcall)
-- ---------------------------------------------------------------------------
local ETW = {}   -- the mod's modules once found: F (common functions), C (logic checks), R (its traits)
local function mod()
    if ETW.ready == nil then
        local ok = pcall(function()
            -- the mod's shared files return their module tables (they are not globals)
            ETW.F = require("ETW_CommonFunctions")
            ETW.C = require("ETW_CommonLogicChecks")
            local reg = require("ETW_Registry") or ETW_Registry
            ETW.R = reg and reg.traits
        end)
        ETW.ready = ok and type(ETW.F) == "table" and type(ETW.C) == "table" and type(ETW.R) == "table"
    end
    return ETW.ready and ETW or nil
end

-- the mod's sandbox options
local function SBV() return SandboxVars and SandboxVars.EvolvingTraitsWorld or {} end

-- the mod's own words: its tooltips carry <br> line breaks and doubled percent signs
local function clean(s)
    s = tostring(s or "")
    s = s:gsub("<br>", " ")
    -- "%%%%" is the pattern for two percent signs; "%%" in the replacement writes one
    s = s:gsub("%%%%", "%%")
    return s
end
local function words(key) return clean(getTextOrNull(key) or key) end

-- the mod page's percentile (ETW_CharacterPage.lua): where cur sits between min and max
local function pct(minV, maxV, cur)
    if minV == nil or maxV == nil or cur == nil or maxV == minV then return 0 end
    return (cur - minV) / (maxV - minV)
end
local function clamp01(v)
    v = tonumber(v) or 0
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end
-- the mod page's two decimals
local function dec(v) return string.format("%.2f", tonumber(v) or 0) end
-- "Current value: <v>", the mod's words under each bar
local function cur(v) return getText("UI_ETW_CurrentValue") .. tostring(v) end

-- a trait named in the tables below: V (the game's own CharacterTrait) or E (one the mod registers)
local function V(name) return { v = true, name = name } end
local function E(name) return { v = false, name = name } end
local function traitOf(c, spec)
    if not spec then return nil end
    if spec.v then return CharacterTrait and CharacterTrait[spec.name] end
    return c.R[spec.name]
end

-- the mod's Mark Dynamic Traits Framework names traits without its decorations
local MDTF = nil
local function mdtf()
    if MDTF == nil then
        MDTF = false
        if modOn("MarkDynamicTraitsFramework") then
            local ok, m = pcall(require, "MDTF_Main")
            if ok and type(m) == "table" then MDTF = m end
        end
    end
    return MDTF or nil
end

-- the game's traits (name, description, good or bad), read once each
local _tinfo = {}
local function tinfo(t)
    local key = tostring(t)
    local i = _tinfo[key]
    if i then return i end
    i = { label = key, desc = "", bad = false, trait = t }
    pcall(function()
        local d = CharacterTraitDefinition.getCharacterTraitDefinition(t)
        if d then
            -- the mod's page names traits by their UI name (without MDTF's marks)
            local m = mdtf()
            i.label = (m and m.getUndecoratedUIName and m.getUndecoratedUIName(d)) or d:getUIName() or i.label
            i.desc = d:getDescription() or ""
            i.bad = d:getCost() < 0
        end
    end)
    _tinfo[key] = i
    return i
end
local function owns(p, t)
    if not t then return false end
    local ok, r = pcall(function() return p:hasTrait(t) end)
    return ok and r == true
end
-- is the trait waiting in the Delayed Traits System's list? (the mod then hides its progress)
local function delayed(md, t)
    local list = md and md.DelayedTraits
    if not (list and t) then return false end
    local id = t:toString()
    for i = 1, #list do
        if list[i][1] == id then return true end
    end
    return false
end

-- the skill levels and kill counts the mod's page reads (its buildRenderStatsCache)
local PERKS = {
    sprinting = "Sprinting", lightfooted = "Lightfoot", nimble = "Nimble", sneaking = "Sneak", axe = "Axe",
    longBlunt = "Blunt", shortBlunt = "SmallBlunt", longBlade = "LongBlade", shortBlade = "SmallBlade", spear = "Spear",
    maintenance = "Maintenance", carpentry = "Woodwork", cooking = "Cooking", farming = "Farming", firstAid = "Doctor",
    electrical = "Electricity", metalworking = "MetalWelding", mechanics = "Mechanics", tailoring = "Tailoring",
    aiming = "Aiming", reloading = "Reloading", fishing = "Fishing", trapping = "Trapping", butchering = "Butchering",
    tracking = "Tracking", foraging = "PlantScavenging", husbandry = "Husbandry", carving = "Carving",
    blacksmith = "Blacksmith", knapping = "FlintKnapping", masonry = "Masonry",
}
local KILLS = {
    axeKills = "Axe", longBluntKills = "Blunt", shortBluntKills = "SmallBlunt", longBladeKills = "LongBlade",
    shortBladeKills = "SmallBlade", spearKills = "Spear", fireKills = "Fire", firearmKills = "Firearm",
    vehicleKills = "Vehicles", explosiveKills = "Explosives",
}
local function readStats(p, E_)
    local s = {}
    for k, perk in pairs(PERKS) do
        local ok, v = pcall(function() return p:getPerkLevel(Perks[perk]) end)
        s[k] = (ok and tonumber(v)) or 0
    end
    local okK, kc = pcall(E_.F.getKillCountWeaponCategories, p)
    if not (okK and type(kc) == "table") then kc = {} end
    for k, cat in pairs(KILLS) do s[k] = (kc[cat] and kc[cat].count) or 0 end
    local okG, g = pcall(E_.F.getGordoniteCrowbarKills, kc)
    s.gordoniteCrowbarKills = (okG and tonumber(g)) or 0
    s.zombieKills = p:getZombieKills()
    return s
end

-- the mod's newest 24 hourly averages, newest first (its formatHourlySamples)
local function hourly(samples)
    local parts = {}
    if samples then
        for i = math.min(24, #samples), 1, -1 do parts[#parts + 1] = dec(samples[i]) end
    end
    if #parts == 0 then return getText("UI_ETW_Vitals_LatestHourlyAverages") .. ":" end
    return getText("UI_ETW_Vitals_LatestHourlyAverages") .. ": " .. table.concat(parts, " ")
end

-- ---------------------------------------------------------------------------
-- WHAT THE MOD'S PAGE SHOWS (ETW_CharacterPage.lua createChildren + render)
--   bar:    a system's bar. val(c) gives the bar (0..1) and the mod's "Current value"
--           text; marks(c) where the mod writes "+ Trait" (gain) / "- Trait" (lose) /
--           "+/- Trait" along it (0..1)
--   count:  "Trait: a/b" lines (one part each); the row fills to the parts' average
--   chance: "Trait: 1 in N", a chance that does not build up
-- on(c) is the mod's own check for whether the page lists it.
-- c = { p = player, md = its mod data, SB = its sandbox options, s = skills and kills,
--       C = its checks, F = its helpers, R = its traits }
-- ---------------------------------------------------------------------------
local function M(at, spec, sign) return { at = at, spec = spec, sign = sign } end
local function ex(name) return function(c) return c.C[name](c.p) end end
-- one "a/b" part of a count row; tip is the mod's tooltip on that line; subs the "x/2" each skill needs
local function P(a, b, tip, isDec, subs) return { a = tonumber(a) or 0, b = tonumber(b) or 0, tip = tip, dec = isDec, subs = subs } end
-- a count row: the trait, the mod's check, its parts
local function cnt(id, cat, spec, on, parts, noDelay)
    return { id = id, cat = cat, kind = "count", spec = spec, on = on, parts = parts, noDelay = noDelay }
end
local function chance(id, cat, spec, on, nKey, tipKey)
    return { id = id, cat = cat, kind = "chance", spec = spec, on = on, nKey = nKey, tipKey = tipKey }
end
-- the mod's words for a kills part: "<option> (<its tooltip>)"
local function killTip(key) return words(key) .. " (" .. words(key .. "_tooltip") .. ")" end
-- the marks at a sixth, a third, two thirds and five sixths (the mod's two-trait meters)
local function sixths(a, b) return { M(1 / 6, a, "+"), M(1 / 3, a, "-"), M(2 / 3, b, "-"), M(5 / 6, b, "+") } end
-- the marks at the middle and the end (lose the bad one halfway, gain the good one at the top)
local function midEnd(bad, good) return { M(0.5, bad, "-"), M(1, good, "+") } end
-- a skills-sum bar (Hearing, Learner): the levels of several skills against an option
local function levels(s, keys)
    local n = 0
    for _, k in ipairs(keys) do n = n + (s[k] or 0) end
    return n
end
local HEARING_SKILLS = { "sprinting", "lightfooted", "nimble", "sneaking", "axe", "longBlunt", "shortBlunt", "longBlade", "shortBlade", "spear" }
local LEARNER_SKILLS = { "maintenance", "carpentry", "farming", "firstAid", "electrical", "metalworking", "mechanics", "tailoring", "cooking" }

-- Butterfingers stretches the two transfer bars by half (the mod's transferBarScale)
local function transferScale(c)
    return (owns(c.p, c.R.BUTTERFINGERS) and c.SB.TraitsLockSystemCanLoseNegative) and 1.5 or 1
end
local function transferMarks(c, first, second, endGood)
    local k = transferScale(c)
    local out = { M(1 / (3 * k), first, "-"), M(2 / (3 * k), second, "-") }
    if k > 1 then out[#out + 1] = M(1, E("BUTTERFINGERS"), "-") end
    out[#out + 1] = M(2 / (3 * k), endGood == "ORGANIZED" and V("DEXTROUS") or V("ORGANIZED"), "+")
    out[#out + 1] = M(1 / k, V(endGood), "+")
    return out
end

local ENTRIES = {
    -- VITALS: the 31-day averages; marks only while the mod's food / thirst / mental systems run
    { id = "food", cat = "vitals", kind = "bar", name = "UI_ETW_Vitals_Food", desc = "Sandbox_ETW_FoodSystem_tooltip",
      traits = { V("HEARTY_APPETITE"), V("LIGHT_EATER") },
      val = function(c) local v = c.md.RecentAverageFood or 0; return v, cur(dec(v)) end,
      marks = function(c)
          if not c.C.FoodSystemShouldExecute(c.p) then return {} end
          local SB = c.SB
          return { M(SB.FoodSystemGainNegativeThreshold, V("HEARTY_APPETITE"), "+"), M(SB.FoodSystemLosePositiveThreshold, V("LIGHT_EATER"), "-"),
                   M(SB.FoodSystemLoseNegativeThreshold, V("HEARTY_APPETITE"), "-"), M(SB.FoodSystemGainPositiveThreshold, V("LIGHT_EATER"), "+") }
      end,
      extra = function(c) return { hourly(c.md.FoodStateInLast24Hours) } end },
    { id = "thirst", cat = "vitals", kind = "bar", name = "UI_ETW_Vitals_Thirst", desc = "Sandbox_ETW_ThirstSystem_tooltip",
      traits = { V("HIGH_THIRST"), V("LOW_THIRST") },
      val = function(c) local v = c.md.RecentAverageThirst or 0; return v, cur(dec(v)) end,
      marks = function(c)
          if not c.C.ThirstSystemShouldExecute(c.p) then return {} end
          local SB = c.SB
          return { M(SB.ThirstSystemGainNegativeThreshold, V("HIGH_THIRST"), "+"), M(SB.ThirstSystemLosePositiveThreshold, V("LOW_THIRST"), "-"),
                   M(SB.ThirstSystemLoseNegativeThreshold, V("HIGH_THIRST"), "-"), M(SB.ThirstSystemGainPositiveThreshold, V("LOW_THIRST"), "+") }
      end,
      extra = function(c) return { hourly(c.md.ThirstStateInLast24Hours) } end },
    { id = "mental", cat = "vitals", kind = "bar", name = "UI_ETW_Vitals_Mental", desc = "UI_ETW_Vitals_Mental_tooltip",
      traits = { E("DEPRESSIVE"), E("BLISSFUL") },
      val = function(c) local v = c.md.RecentAverageMental or 0; return v, cur(dec(v)) end,
      marks = function(c)
          if not c.C.MentalStateSystemShouldExecute(c.p) then return {} end
          local SB, out = c.SB, {}
          if SB.TraitsLockSystemCanGainNegative or SB.TraitsLockSystemCanLoseNegative then
              out[#out + 1] = M(SB.MentalStateSystemDepressiveGainThreshold, E("DEPRESSIVE"), "+")
              out[#out + 1] = M(SB.MentalStateSystemDepressiveLoseThreshold, E("DEPRESSIVE"), "-")
          end
          if SB.TraitsLockSystemCanGainPositive or SB.TraitsLockSystemCanLosePositive then
              out[#out + 1] = M(SB.MentalStateSystemBlissfulLoseThreshold, E("BLISSFUL"), "-")
              out[#out + 1] = M(SB.MentalStateSystemBlissfulGainThreshold, E("BLISSFUL"), "+")
          end
          return out
      end,
      extra = function(c) return { hourly(c.md.MentalStateInLast24Hours) } end },

    -- COMBAT TRAITS
    { id = "bravery", cat = "combat", kind = "bar", name = "Sandbox_ETW_BraverySystem", desc = "Sandbox_ETW_BraverySystemKills_tooltip",
      on = ex("BraverySystemShouldExecute"),
      val = function(c)
          -- the mod's weighted kills: melee, firearm and other kills each at their option's value
          local s, SB = c.s, c.SB
          local other = s.fireKills + s.vehicleKills + s.explosiveKills
          local melee = s.zombieKills - s.firearmKills - other
          local v = melee * SB.BraverySystemMeleeKillValue + s.firearmKills * SB.BraverySystemFirearmKillValue + other * SB.BraverySystemOtherKillValue
          return pct(0, SB.BraverySystemKills, v), cur(v)
      end,
      marks = function()
          return { M(0.1, V("COWARDLY"), "-"), M(0.2, V("HEMOPHOBIC"), "-"), M(0.3, V("PACIFIST"), "-"),
                   M(0.4, V("ADRENALINE_JUNKIE"), "+"), M(0.6, V("BRAVE"), "+"), M(1, V("DESENSITIZED"), "+") }
      end },
    cnt("eagleEyed", "combat", V("EAGLE_EYED"), ex("EagleEyedShouldExecute"), function(c)
        return { P(c.md.EagleEyedKills, c.SB.EagleEyedKills, words("Sandbox_ETW_EagleEyedKills")) } end),
    cnt("hunter", "combat", V("HUNTER"), ex("HunterShouldExecute"), function(c)
        local s, SB = c.s, c.SB
        return { P(s.sneaking + s.aiming + s.shortBlade + s.tracking + s.butchering, SB.HunterSkill, words("Sandbox_ETW_HunterSkill_tooltip"), false,
                   { s.sneaking, s.aiming, s.shortBlade, s.tracking, s.butchering }),
                 P(s.shortBladeKills + s.firearmKills, SB.HunterKills, killTip("Sandbox_ETW_HunterKills")) } end),
    cnt("bladeEnthusiast", "combat", E("BLADE_ENTHUSIAST"), ex("BladeEnthusiastShouldExecute"), function(c)
        return { P(c.s.longBlade, c.SB.BladeEnthusiastSkill, words("Sandbox_ETW_BladeEnthusiastSkill")),
                 P(c.s.longBladeKills, c.SB.BladeEnthusiastKills, words("Sandbox_ETW_BladeEnthusiastKills")) } end),
    cnt("thuggish", "combat", E("THUGGISH"), ex("ThuggishShouldExecute"), function(c)
        local s = c.s
        return { P(s.shortBlunt + s.longBlunt, c.SB.ThuggishSkill, words("Sandbox_ETW_ThuggishSkill_tooltip")),
                 P(s.shortBluntKills + s.longBluntKills, c.SB.ThuggishKills, killTip("Sandbox_ETW_ThuggishKills")) } end),
    cnt("brawler", "combat", V("BRAWLER"), ex("BrawlerShouldExecute"), function(c)
        local s = c.s
        return { P(s.axe + s.longBlunt, c.SB.BrawlerSkill, words("Sandbox_ETW_BrawlerSkill_tooltip")),
                 P(s.axeKills + s.longBluntKills, c.SB.BrawlerKills, killTip("Sandbox_ETW_BrawlerKills")) } end),
    cnt("gordonite", "combat", E("GORDONITE"), ex("GordoniteShouldExecute"), function(c)
        return { P(c.s.gordoniteCrowbarKills, c.SB.GordoniteKills, words("Sandbox_ETW_GordoniteKills_tooltip")) } end),
    cnt("axeThrower", "combat", E("AXE_THROWER"), ex("AxeThrowerShouldExecute"), function(c)
        return { P(c.s.axe, c.SB.AxeThrowerSkill, words("Sandbox_ETW_AxeThrowerSkill")),
                 P(c.s.axeKills, c.SB.AxeThrowerKills, words("Sandbox_ETW_AxeThrowerKills")) } end),
    cnt("stickFighter", "combat", E("STICK_FIGHTER"), ex("StickFighterShouldExecute"), function(c)
        return { P(c.s.shortBlunt, c.SB.StickFighterSkill, words("Sandbox_ETW_StickFighterSkill")),
                 P(c.s.shortBluntKills, c.SB.StickFighterKills, words("Sandbox_ETW_StickFighterKills")) } end),
    cnt("knifeFighter", "combat", E("KNIFE_FIGHTER"), ex("KnifeFighterShouldExecute"), function(c)
        return { P(c.s.shortBlade, c.SB.KnifeFighterSkill, words("Sandbox_ETW_KnifeFighterSkill")),
                 P(c.s.shortBladeKills, c.SB.KnifeFighterKills, words("Sandbox_ETW_KnifeFighterKills")) } end),
    cnt("polearmFighter", "combat", E("POLEARM_FIGHTER"), ex("PolearmFighterShouldExecute"), function(c)
        return { P(c.s.spear, c.SB.PolearmFighterSkill, words("Sandbox_ETW_PolearmFighterSkill")),
                 P(c.s.spearKills, c.SB.PolearmFighterKills, words("Sandbox_ETW_PolearmFighterKills")) } end),
    -- (Prowess: the kills needed grow with every other Prowess trait you have; the mod's own sum)
    cnt("prowessBlade", "combat", E("PROWESS_BLADE"), ex("ProwessBladeShouldExecute"), function(c)
        local s = c.s
        local need = c.F.getProwessKillRequirement(c.p, c.R.PROWESS_BLADE, c.SB.ProwessBladeKills, c.md)
        return { P(s.shortBlade + s.longBlade + s.axe, c.SB.ProwessBladeSkill, words("Sandbox_ETW_ProwessBladeSkill_tooltip")),
                 P(s.shortBladeKills + s.longBladeKills + s.axeKills, need, words("Sandbox_ETW_ProwessBladeKills_tooltip")) } end),
    cnt("prowessBlunt", "combat", E("PROWESS_BLUNT"), ex("ProwessBluntShouldExecute"), function(c)
        local s = c.s
        local need = c.F.getProwessKillRequirement(c.p, c.R.PROWESS_BLUNT, c.SB.ProwessBluntKills, c.md)
        return { P(s.shortBlunt + s.longBlunt, c.SB.ProwessBluntSkill, words("Sandbox_ETW_ProwessBluntSkill_tooltip")),
                 P(s.shortBluntKills + s.longBluntKills, need, words("Sandbox_ETW_ProwessBluntKills_tooltip")) } end),
    cnt("prowessGuns", "combat", E("PROWESS_GUNS"), ex("ProwessGunsShouldExecute"), function(c)
        local s = c.s
        local need = c.F.getProwessKillRequirement(c.p, c.R.PROWESS_GUNS, c.SB.ProwessGunsKills, c.md)
        return { P(s.aiming + s.reloading, c.SB.ProwessGunsSkill, words("Sandbox_ETW_ProwessGunsSkill_tooltip")),
                 P(s.firearmKills, need, words("Sandbox_ETW_ProwessGunsKills_tooltip")) } end),
    cnt("prowessSpear", "combat", E("PROWESS_SPEAR"), ex("ProwessSpearShouldExecute"), function(c)
        local s = c.s
        local need = c.F.getProwessKillRequirement(c.p, c.R.PROWESS_SPEAR, c.SB.ProwessSpearKills, c.md)
        return { P(s.spear, c.SB.ProwessSpearSkill, words("Sandbox_ETW_ProwessSpearSkill_tooltip")),
                 P(s.spearKills, need, words("Sandbox_ETW_ProwessSpearKills_tooltip")) } end),
    cnt("antiGun", "combat", E("ANTI_GUN_ACTIVIST"), ex("AntiGunActivistShouldExecute"), function(c)
        local s = c.s
        return { P(s.aiming + s.reloading, c.SB.AntiGunActivistSkill, words("Sandbox_ETW_AntiGunActivistSkill_tooltip")),
                 P(s.firearmKills, c.SB.AntiGunActivistKills, words("Sandbox_ETW_AntiGunActivistKills_tooltip")) } end),
    cnt("gunEnthusiast", "combat", E("GUN_ENTHUSIAST"), ex("GunEnthusiastShouldExecute"), function(c)
        local s = c.s
        return { P(s.aiming + s.reloading, c.SB.GunEnthusiastSkill, words("Sandbox_ETW_GunEnthusiastSkill_tooltip")),
                 P(s.firearmKills, c.SB.GunEnthusiastKills, words("Sandbox_ETW_GunEnthusiastKills")) } end),
    cnt("terminator", "combat", E("TERMINATOR"), ex("TerminatorShouldExecute"), function(c)
        local s = c.s
        return { P(s.aiming + s.reloading + s.nimble, c.SB.TerminatorSkill, words("Sandbox_ETW_TerminatorSkill_tooltip")),
                 P(s.firearmKills, c.SB.TerminatorKills, words("Sandbox_ETW_TerminatorKills_tooltip")) } end),

    -- NON-COMBAT TRAITS: the systems with a bar, then the "Trait: a/b" lines
    { id = "immunity", cat = "noncombat", kind = "bar", name = "Sandbox_ETW_ImmunitySystem", desc = "Sandbox_ETW_ImmunitySystemCounter_tooltip",
      on = ex("ImmunitySystemShouldExecute"),
      val = function(c)
          local v = c.md.ImmunitySystemCounter or 0
          return pct(0, c.SB.ImmunitySystemCounter * c.C.getImmunitySystemMaximumThreshold(), v), cur(dec(v))
      end,
      marks = function(c)
          -- each stage's threshold (the mod's getImmunitySystemThreshold) along the bar's maximum
          local out = {}
          local maxT = c.C.getImmunitySystemMaximumThreshold()
          local function add(spec, sign)
              local t = traitOf(c, spec)
              local th = c.F.getImmunitySystemThreshold(t)
              if th and maxT and maxT > 0 and c.C.ImmunitySystemShouldExecute(nil, t) then out[#out + 1] = M(th / maxT, spec, sign) end
          end
          add(V("PRONE_TO_ILLNESS"), "-")
          add(E("IMMUNOCOMPROMISED"), "-")
          add(V("RESILIENT"), "+")
          add(E("SUPER_IMMUNE"), "+")
          return out
      end,
      extra = function(c)
          local SB = c.SB
          if (SB.ImmunitySystemSuperImmuneInfectionsSurvived or 0) > 0 and c.C.ImmunitySystemShouldExecute(nil, c.R.SUPER_IMMUNE) then
              local n = (c.md.InjurySnapshotSystem and c.md.InjurySnapshotSystem.KnoxInfectionsSurvived) or 0
              return { getText("UI_ETW_KnoxInfectionsSurvived") .. ": " .. n .. "/" .. SB.ImmunitySystemSuperImmuneInfectionsSurvived }
          end
          return nil
      end },
    { id = "foodSickness", cat = "noncombat", kind = "bar", name = "Sandbox_ETW_FoodSicknessSystem", desc = "Sandbox_ETW_FoodSicknessSystemCounter_tooltip",
      on = ex("FoodSicknessSystemShouldExecute"),
      val = function(c) local v = c.md.FoodSicknessWeathered or 0; return pct(0, c.SB.FoodSicknessSystemCounter, v), cur(dec(v)) end,
      marks = function() return midEnd(V("WEAK_STOMACH"), V("IRON_GUT")) end },
    { id = "hearing", cat = "noncombat", kind = "bar", name = "Sandbox_ETW_HearingSystem", desc = "Sandbox_ETW_HearingSystemSkill_tooltip",
      on = ex("HearingSystemShouldExecute"),
      val = function(c) local n = levels(c.s, HEARING_SKILLS); return pct(0, c.SB.HearingSystemSkill, n), cur(n) end,
      marks = function() return midEnd(V("HARD_OF_HEARING"), V("KEEN_HEARING")) end },
    { id = "learner", cat = "noncombat", kind = "bar", name = "Sandbox_ETW_LearnerSystem", desc = "Sandbox_ETW_LearnerSystemSkill_tooltip",
      on = ex("LearnerSystemShouldExecute"),
      val = function(c) local n = levels(c.s, LEARNER_SKILLS); return pct(0, c.SB.LearnerSystemSkill, n), cur(n) end,
      marks = function() return midEnd(V("SLOW_LEARNER"), V("FAST_LEARNER")) end },
    { id = "reader", cat = "noncombat", kind = "bar", name = "Sandbox_ETW_ReaderSystem", desc = "Sandbox_ETW_ReaderSystemCounter_tooltip",
      on = ex("ReaderSystemShouldExecute"),
      val = function(c) local v = c.md.PagesReadCounter or 0; return pct(0, c.SB.ReaderSystemCounter, v), cur(v) end,
      marks = function() return midEnd(V("SLOW_READER"), V("FAST_READER")) end },
    { id = "eatingSpeed", cat = "noncombat", kind = "bar", name = "Sandbox_ETW_EatingSpeedSystem", desc = "Sandbox_ETW_EatingSpeedSystemCounter_tooltip",
      on = ex("EatingSpeedSystemShouldExecute"),
      val = function(c) local v = c.md.EatingSpeedSystemCounter or 0; return pct(0, c.SB.EatingSpeedSystemCounter or 216000, v), cur(dec(v)) end,
      marks = function() return midEnd(E("SLOW_EATER"), E("FAST_EATER")) end },
    { id = "carryWeight", cat = "noncombat", kind = "bar", name = "UI_ETW_CarryWeightSystem", desc = "Sandbox_ETW_CarryWeightSystemCounter_tooltip",
      on = ex("CarryWeightSystemShouldExecute"),
      val = function(c) local v = c.md.CarryWeightCounter or 0; return pct(0, c.SB.CarryWeightSystemCounter, v), cur(dec(v)) end,
      marks = function() return { M(1 / 3, E("PACK_MOUSE"), "-"), M(2 / 3, E("HOARDER"), "+"), M(1, E("PACK_MULE"), "+") } end },
    -- (the two transfer bars show only until their target is reached, as on the mod's page)
    { id = "transferWeight", cat = "noncombat", kind = "bar", name = "Sandbox_ETW_InventoryTransferSystemWeight", desc = "Sandbox_ETW_InventoryTransferSystemWeight_tooltip",
      on = function(c)
          local v = (c.md.TransferSystem and c.md.TransferSystem.WeightTransferred) or 0
          return c.C.InventoryTransferSystemShouldExecute(c.p) and v < c.SB.InventoryTransferSystemWeight * transferScale(c)
      end,
      val = function(c)
          local v = (c.md.TransferSystem and c.md.TransferSystem.WeightTransferred) or 0
          return pct(0, c.SB.InventoryTransferSystemWeight * transferScale(c), v), cur(v)
      end,
      marks = function(c) return transferMarks(c, V("ALL_THUMBS"), V("DISORGANIZED"), "ORGANIZED") end },
    { id = "transferItems", cat = "noncombat", kind = "bar", name = "Sandbox_ETW_InventoryTransferSystemItems", desc = "Sandbox_ETW_InventoryTransferSystemItems_tooltip",
      on = function(c)
          local v = (c.md.TransferSystem and c.md.TransferSystem.ItemsTransferred) or 0
          return c.C.InventoryTransferSystemShouldExecute(c.p) and v < c.SB.InventoryTransferSystemItems * transferScale(c)
      end,
      val = function(c)
          local v = (c.md.TransferSystem and c.md.TransferSystem.ItemsTransferred) or 0
          return pct(0, c.SB.InventoryTransferSystemItems * transferScale(c), v), cur(v)
      end,
      marks = function(c) return transferMarks(c, V("DISORGANIZED"), V("ALL_THUMBS"), "DEXTROUS") end },
    chance("injured", "noncombat", E("INJURED"), ex("InjuredShouldExecute"), "InjuredChanceOneIn", "Sandbox_ETW_InjuredChanceOneIn_tooltip"),
    chance("burnWard", "noncombat", E("BURN_WARD_PATIENT"), ex("BurnWardPatientShouldExecute"), "BurnWardPatientChanceOneIn", "Sandbox_ETW_BurnWardPatientChanceOneIn_tooltip"),
    chance("brokenLeg", "noncombat", E("BROKEN_LEG"), ex("BrokenLegShouldExecute"), "BrokenLegChanceOneIn", "Sandbox_ETW_BrokenLegChanceOneIn_tooltip"),
    cnt("olympian", "noncombat", E("OLYMPIAN"), ex("OlympianShouldExecute"), function(c)
        return { P(c.md.OlympianCounter or 0, c.SB.OlympianCounter, words("Sandbox_ETW_OlympianCounter_tooltip")) } end),
    cnt("painTolerance", "noncombat", E("PAIN_TOLERANCE"), ex("PainToleranceShouldExecute"), function(c)
        return { P(c.md.PainToleranceCounter, c.SB.PainToleranceCounter, words("Sandbox_ETW_PainToleranceCounter_tooltip"), true) } end, true),
    cnt("noodleLegs", "noncombat", E("NOODLE_LEGS"), ex("NoodleLegsShouldExecute"), function(c)
        local s = c.s
        return { P((c.md.NoodleLegs and c.md.NoodleLegs.Distance) or 0, c.SB.NoodleLegsDistance, words("Sandbox_ETW_NoodleLegsDistance_tooltip"), true),
                 P(s.sprinting + s.lightfooted + s.nimble, c.SB.NoodleLegsSkill, words("Sandbox_ETW_NoodleLegsSkill_tooltip")) } end),
    cnt("naturalEater", "noncombat", E("NATURAL_EATER"), ex("NaturalEaterShouldExecute"), function(c)
        return { P(c.md.NaturalEaterFoodsEaten or 0, c.SB.NaturalEaterFoodsEaten or 3000, words("Sandbox_ETW_NaturalEaterFoodsEaten_tooltip")) } end),
    cnt("runner", "noncombat", V("JOGGER"), ex("RunnerShouldExecute"), function(c)
        return { P(c.s.sprinting, c.SB.RunnerSkill, words("Sandbox_ETW_RunnerSkill")) } end),
    cnt("lightStep", "noncombat", E("LIGHTSTEP"), ex("LightStepShouldExecute"), function(c)
        return { P(c.s.lightfooted, c.SB.LightStepSkill, words("Sandbox_ETW_LightStepSkill")) } end),
    cnt("gymnast", "noncombat", V("GYMNAST"), ex("GymnastShouldExecute"), function(c)
        return { P(c.s.lightfooted + c.s.nimble, c.SB.GymnastSkill, words("Sandbox_ETW_GymnastSkill_tooltip")) } end),
    cnt("clumsy", "noncombat", V("CLUMSY"), ex("ClumsyShouldExecute"), function(c)
        return { P(c.s.lightfooted + c.s.sneaking, c.SB.ClumsySkill, words("Sandbox_ETW_ClumsySkill_tooltip")) } end),
    cnt("graceful", "noncombat", V("GRACEFUL"), ex("GracefulShouldExecute"), function(c)
        local s = c.s
        return { P(s.lightfooted + s.sneaking + s.nimble, c.SB.GracefulSkill, words("Sandbox_ETW_GracefulSkill_tooltip")) } end),
    cnt("burglar", "noncombat", V("BURGLAR"), ex("BurglarShouldExecute"), function(c)
        local s = c.s
        return { P(s.electrical + s.mechanics + s.nimble, c.SB.BurglarSkill, words("Sandbox_ETW_BurglarSkill_tooltip"), false,
                   { s.electrical, s.mechanics }) } end),
    cnt("lowProfile", "noncombat", E("LOW_PROFILE"), ex("LowProfileShouldExecute"), function(c)
        return { P(c.s.sneaking, c.SB.LowProfileSkill, words("Sandbox_ETW_LowProfileSkill")) } end),
    cnt("conspicuous", "noncombat", V("CONSPICUOUS"), ex("ConspicuousShouldExecute"), function(c)
        return { P(c.s.sneaking, c.SB.ConspicuousSkill, words("Sandbox_ETW_ConspicuousSkill")) } end),
    cnt("inconspicuous", "noncombat", V("INCONSPICUOUS"), ex("InconspicuousShouldExecute"), function(c)
        return { P(c.s.sneaking, c.SB.InconspicuousSkill, words("Sandbox_ETW_InconspicuousSkill")) } end),
    cnt("quiet", "noncombat", E("QUIET"), ex("QuietShouldExecute"), function(c)
        return { P(c.s.sneaking + c.s.lightfooted, c.SB.QuietSkill, words("Sandbox_ETW_QuietSkill_tooltip")) } end),
    cnt("scrapper", "noncombat", E("SCRAPPER"), ex("ScrapperShouldExecute"), function(c)
        local s = c.s
        return { P(s.metalworking + s.maintenance + s.blacksmith, c.SB.ScrapperSkill, words("Sandbox_ETW_ScrapperSkill_tooltip")) } end),
    cnt("restorationExpert", "noncombat", E("RESTORATION_EXPERT"), ex("RestorationExpertShouldExecute"), function(c)
        return { P(c.s.maintenance, c.SB.RestorationExpertSkill, words("Sandbox_ETW_RestorationExpertSkill")) } end),
    cnt("handy", "noncombat", V("HANDY"), ex("HandyShouldExecute"), function(c)
        local s = c.s
        return { P(s.maintenance + s.carpentry + s.carving + s.masonry, c.SB.HandySkill, words("Sandbox_ETW_HandySkill_tooltip")) } end),
    cnt("furnitureAssembler", "noncombat", E("FURNITURE_ASSEMBLER"), ex("FurnitureAssemblerShouldExecute"), function(c)
        return { P(c.s.carpentry, c.SB.FurnitureAssemblerSkill, words("Sandbox_ETW_FurnitureAssemblerSkill")) } end),
    cnt("homeCook", "noncombat", E("HOME_COOK"), ex("HomeCookShouldExecute"), function(c)
        return { P(c.s.cooking, c.SB.HomeCookSkill, words("Sandbox_ETW_HomeCookSkill")) } end),
    cnt("cook", "noncombat", V("COOK"), ex("CookShouldExecute"), function(c)
        return { P(c.s.cooking, c.SB.CookSkill, words("Sandbox_ETW_CookSkill")) } end),
    cnt("firstAid", "noncombat", V("FIRST_AID"), ex("FirstAidShouldExecute"), function(c)
        return { P(c.s.firstAid, c.SB.FirstAidSkill, words("Sandbox_ETW_FirstAidSkill")) } end),
    cnt("avClub", "noncombat", E("AV_CLUB"), ex("AVClubShouldExecute"), function(c)
        return { P(c.s.electrical, c.SB.AVClubSkill, words("Sandbox_ETW_AVClubSkill")) } end),
    cnt("bodywork", "noncombat", E("BODYWORK_ENTHUSIAST"), ex("BodyWorkEnthusiastShouldExecute"), function(c)
        return { P(c.s.metalworking + c.s.mechanics, c.SB.BodyworkEnthusiastSkill, words("Sandbox_ETW_BodyworkEnthusiastSkill_tooltip")),
                 P(c.md.VehiclePartRepairs or 0, c.SB.BodyworkEnthusiastRepairs, words("Sandbox_ETW_BodyworkEnthusiastRepairs_tooltip")) } end),
    cnt("mechanics", "noncombat", V("MECHANICS"), ex("MechanicsShouldExecute"), function(c)
        return { P(c.s.mechanics, c.SB.MechanicsSkill, words("Sandbox_ETW_MechanicsSkill")),
                 P(math.floor(c.md.VehiclePartRepairs or 0), c.SB.MechanicsRepairs, words("Sandbox_ETW_MechanicsRepairs_tooltip")) } end),
    cnt("tailor", "noncombat", V("TAILOR"), ex("SewerShouldExecute"), function(c)
        local ripped = (c.md.UniqueClothingRipped and #c.md.UniqueClothingRipped) or 0
        return { P(c.s.tailoring, c.SB.SewerSkill, words("Sandbox_ETW_SewerSkill")),
                 P(ripped, c.SB.SewerUniqueClothesRipped, words("Sandbox_ETW_SewerUniqueClothesRipped_tooltip")) } end),
    cnt("petTherapy", "noncombat", E("PET_THERAPY"), ex("PetTherapyShouldExecute"), function(c)
        local A = c.md.AnimalsSystem
        local petted = (A and A.UniqueAnimalsPetted and #A.UniqueAnimalsPetted) or 0
        return { P(c.s.husbandry, c.SB.PetTherapySkill, words("Sandbox_ETW_PetTherapySkill")),
                 P(petted, c.SB.PetTherapyUniqueAnimalsPetted, words("Sandbox_ETW_PetTherapyUniqueAnimalsPetted_tooltip")) } end),
    cnt("angler", "noncombat", V("FISHING"), ex("AnglerShouldExecute"), function(c)
        return { P(c.s.fishing, c.SB.FishingSkill, words("Sandbox_ETW_FishingSkill")) } end),
    cnt("hiker", "noncombat", V("HIKER"), ex("HikerShouldExecute"), function(c)
        return { P(c.s.trapping + c.s.foraging, c.SB.HikerSkill, words("Sandbox_ETW_HikerSkill_tooltip")) } end),
    cnt("catEyes", "noncombat", V("NIGHT_VISION"), ex("CatEyesShouldExecute"), function(c)
        return { P(math.floor(c.md.CatEyesCounter or 0), c.SB.CatEyesCounter, words("Sandbox_ETW_CatEyesCounter_tooltip")) } end),
    cnt("herbalist", "noncombat", V("HERBALIST"), ex("HerbalistShouldExecute"), function(c)
        return { P(math.floor(c.md.HerbsPickedUp or 0), c.SB.HerbalistHerbsPicked, words("Sandbox_ETW_HerbalistHerbsPicked_tooltip")) } end),
    cnt("axeman", "noncombat", V("AXEMAN"), ex("AxemanShouldExecute"), function(c)
        return { P(c.md.TreesChopped or 0, c.SB.AxemanTrees, words("Sandbox_ETW_AxemanTrees_tooltip")) } end),
    cnt("whittler", "noncombat", V("WHITTLER"), ex("WhittlerShouldExecute"), function(c)
        return { P(c.s.carving, c.SB.WhittlerSkill, words("Sandbox_ETW_WhittlerSkill")) } end),
    cnt("blacksmith", "noncombat", V("BLACKSMITH"), ex("BlacksmithShouldExecute"), function(c)
        return { P(c.s.blacksmith + c.s.maintenance, c.SB.BlacksmithSkill, words("Sandbox_ETW_BlacksmithSkill_tooltip")) } end),
    cnt("wilderness", "noncombat", V("WILDERNESS_KNOWLEDGE"), ex("WildernessKnowledgeShouldExecute"), function(c)
        local s = c.s
        return { P(s.foraging + s.knapping + s.maintenance + s.carving, c.SB.WildernessKnowledgeSkill, words("Sandbox_ETW_WildernessKnowledgeSkill_tooltip"), false,
                   { s.foraging, s.knapping, s.maintenance, s.carving }) } end),

    -- PHYSICAL TRAITS (non-permanent: they come and go both ways)
    { id = "gym", cat = "physical", kind = "bar", name = "Sandbox_ETW_GymTraitsSystem", desc = "Sandbox_ETW_GymTraitsSystem_tooltip",
      on = ex("GymTraitsSystemShouldExecute"),
      val = function(c)
          local g = c.md.GymTraitsSystem or {}
          local v = g.GymTraitsSystemCounter or 0
          return pct(-c.SB.GymTraitsSystemCounter, c.SB.GymTraitsSystemCounter, v), cur(dec(v))
      end,
      marks = function() return { M(1 / 8, E("GYM_HATER"), "+"), M(3 / 8, E("GYM_HATER"), "-"), M(5 / 8, E("GYM_RAT"), "-"), M(7 / 8, E("GYM_RAT"), "+") } end,
      extra = function(c)
          -- the mod's lines under its bar: regularity against the midpoint, and the workout grace hours
          local SB, g = c.SB, c.md.GymTraitsSystem or {}
          local out = { getText("Sandbox_ETW_GymTraitsSystemRegularityMidpoint") .. ": " .. dec(c.F.getAverageExerciseRegularity(c.p))
              .. "%/" .. tostring(SB.GymTraitsSystemRegularityMidpoint) .. "%", words("Sandbox_ETW_GymTraitsSystemRegularityMidpoint_tooltip") }
          local grace = math.max(0, SB.GymTraitsSystemWorkoutGracePeriodHours or 16)
          local left = math.max(0, grace - (g.HoursSinceLastWorkout or 0))
          if left > 0 then out[#out + 1] = getText("UI_ETW_GymTraitsSystemWorkoutProtection", left) end
          return out
      end },
    { id = "injuries", cat = "physical", kind = "bar", name = "Sandbox_ETW_InjuriesSystem", desc = "Sandbox_ETW_InjuriesSystem_tooltip",
      on = ex("InjuriesSystemShouldExecute"),
      val = function(c) local v = c.md.injuriesCounter or 0; return pct(-c.SB.InjuriesSystemCounter, c.SB.InjuriesSystemCounter, v), cur(dec(v)) end,
      marks = function() return sixths(V("THIN_SKINNED"), V("THICK_SKINNED")) end },
    { id = "healer", cat = "physical", kind = "bar", name = "Sandbox_ETW_HealerSystem", desc = "Sandbox_ETW_HealerSystem_tooltip",
      on = ex("HealerSystemShouldExecute"),
      val = function(c) local v = c.md.healerCounter or 0; return pct(-c.SB.HealerSystemCounter, c.SB.HealerSystemCounter, v), cur(dec(v)) end,
      marks = function() return sixths(V("SLOW_HEALER"), V("FAST_HEALER")) end },
    { id = "sleep", cat = "physical", kind = "bar", name = "Sandbox_ETW_SleepSystem", desc = "Sandbox_ETW_SleepSystem_tooltip",
      on = ex("SleepSystemShouldExecute"),
      val = function(c)
          local v = (c.md.SleepSystem and c.md.SleepSystem.SleepHealthinessBar) or 0
          return pct(-c.SB.SleepSystemCounter, c.SB.SleepSystemCounter, v), cur(dec(v))
      end,
      marks = function() return sixths(V("NEEDS_MORE_SLEEP"), V("NEEDS_LESS_SLEEP")) end },
    { id = "asthmatic", cat = "physical", kind = "bar", traitName = V("ASTHMATIC"), desc = "Sandbox_ETW_AsthmaticCounter_tooltip",
      on = ex("AsthmaticShouldExecute"),
      val = function(c) local v = c.md.AsthmaticCounter or 0; return pct(c.SB.AsthmaticCounter * -2, c.SB.AsthmaticCounter * 2, v), cur(dec(v)) end,
      marks = function() return { M(1 / 4, V("ASTHMATIC"), "+"), M(3 / 4, V("ASTHMATIC"), "-") } end },
    { id = "idealWeight", cat = "physical", kind = "bar", name = "Sandbox_ETW_IdealWeight", desc = "Sandbox_ETW_IdealWeight_tooltip",
      on = ex("IdealWeightShouldExecute"),
      val = function(c) local v = c.md.IdealWeightCounter or 0; return pct(0, c.SB.IdealWeightCounter, v), cur(dec(v)) end,
      marks = function() return { M(0.33, E("IDEAL_WEIGHT"), "-"), M(0.66, E("IDEAL_WEIGHT"), "+") } end,
      extra = function() return { words("Sandbox_ETW_IdealWeightCounter_tooltip") } end },

    -- MENTAL TRAITS
    { id = "bloodlust", cat = "mental", kind = "bar", traitName = E("BLOODLUST"), desc = "Sandbox_ETW_Bloodlust_tooltip",
      on = ex("BloodlustShouldExecute"),
      val = function(c)
          local v = (c.md.BloodlustSystem and c.md.BloodlustSystem.BloodlustProgress) or 0
          return pct(-c.SB.BloodlustProgress, c.SB.BloodlustProgress, v), cur(dec(v))
      end,
      marks = function() return { M(1 / 4, E("BLOODLUST"), "-"), M(3 / 4, E("BLOODLUST"), "+") } end },
    { id = "outdoorsman", cat = "mental", kind = "bar", traitName = V("OUTDOORSMAN"), desc = "Sandbox_ETW_OutdoorsmanCounter_tooltip",
      on = ex("OutdoorsmanShouldExecute"),
      val = function(c)
          local v = (c.md.OutdoorsmanSystem and c.md.OutdoorsmanSystem.OutdoorsmanCounter) or 0
          return pct(c.SB.OutdoorsmanCounter * -2, c.SB.OutdoorsmanCounter * 2, v), cur(dec(v))
      end,
      marks = function() return { M(1 / 3, V("OUTDOORSMAN"), "-"), M(2 / 3, V("OUTDOORSMAN"), "+") } end },
    { id = "agoraphobic", cat = "mental", kind = "bar", traitName = V("AGORAPHOBIC"), desc = "Sandbox_ETW_FearOfLocationsSystemCounter_tooltip",
      on = ex("FearOfLocationsSystemShouldExecute"),
      val = function(c)
          local v = (c.md.LocationFearSystem and c.md.LocationFearSystem.FearOfOutside) or 0
          return pct(c.SB.FearOfLocationsSystemCounter * -2, c.SB.FearOfLocationsSystemCounter * 2, v), cur(dec(v))
      end,
      marks = function() return { M(1 / 3, V("AGORAPHOBIC"), "+"), M(2 / 3, V("AGORAPHOBIC"), "-") } end },
    { id = "claustrophobic", cat = "mental", kind = "bar", traitName = V("CLAUSTROPHOBIC"), desc = "Sandbox_ETW_FearOfLocationsSystemCounter_tooltip",
      on = ex("FearOfLocationsSystemShouldExecute"),
      val = function(c)
          local v = (c.md.LocationFearSystem and c.md.LocationFearSystem.FearOfInside) or 0
          return pct(c.SB.FearOfLocationsSystemCounter * -2, c.SB.FearOfLocationsSystemCounter * 2, v), cur(dec(v))
      end,
      marks = function() return { M(1 / 3, V("CLAUSTROPHOBIC"), "+"), M(2 / 3, V("CLAUSTROPHOBIC"), "-") } end },
    { id = "rain", cat = "mental", kind = "bar", name = "Sandbox_ETW_RainSystem", desc = "Sandbox_ETW_RainSystemCounter_tooltip",
      on = ex("RainSystemShouldExecute"),
      val = function(c) local v = c.md.RainCounter or 0; return pct(c.SB.RainSystemCounter * -2, c.SB.RainSystemCounter * 2, v), cur(dec(v)) end,
      marks = function() return { M(1 / 4, E("PLUVIOPHOBIA"), "+/-"), M(3 / 4, E("PLUVIOPHILE"), "+/-") } end },
    { id = "fog", cat = "mental", kind = "bar", name = "Sandbox_ETW_FogSystem", desc = "Sandbox_ETW_FogSystemCounter_tooltip",
      on = ex("FogSystemShouldExecute"),
      val = function(c) local v = c.md.FogCounter or 0; return pct(c.SB.FogSystemCounter * -2, c.SB.FogSystemCounter * 2, v), cur(dec(v)) end,
      marks = function() return { M(1 / 4, E("HOMICHLOPHOBIA"), "+/-"), M(3 / 4, E("HOMICHLOPHILE"), "+/-") } end },
    { id = "smoker", cat = "mental", kind = "bar", traitName = V("SMOKER"), desc = "Sandbox_ETW_SmokerCounter_tooltip",
      on = function(c)
          if not c.C.SmokerShouldExecute(c.p) then return false end
          -- the mod's client option "[UI] Hide Smoker Bar"
          local ok, hide = pcall(function() return PZAPI.ModOptions:getOptions("ETWModOptions"):getOption("HideSmokerUI"):getValue() end)
          return not (ok and hide == true)
      end,
      val = function(c)
          local v = (c.md.SmokeSystem and c.md.SmokeSystem.SmokingAddiction) or 0
          return pct(c.SB.SmokerCounter * -2, c.SB.SmokerCounter * 2, v), cur(v)
      end,
      marks = function() return { M(1 / 4, V("SMOKER"), "-"), M(3 / 4, V("SMOKER"), "+") } end },
}
S.ENTRIES = ENTRIES

-- ---------------------------------------------------------------------------
-- ROWS (read from the mod about twice a second; nothing kept between games)
-- ---------------------------------------------------------------------------
local function catName(cat) return words(CAT_KEY[cat] or cat) end

-- the row's fill: the progress from the tick below the bar's value to the tick above it
local function segment(v, marks)
    if v >= 1 then return 1 end
    local lo, hi = 0, 1
    for _, m in ipairs(marks) do
        if m.at <= v and m.at > lo then lo = m.at end
        if m.at > v and m.at < hi then hi = m.at end
    end
    if hi <= lo then return 0 end
    return clamp01((v - lo) / (hi - lo))
end

-- one count part's text in the mod's words: "a/b", then "| x/2" for each skill it needs at 2
local function partText(pt)
    local t = (pt.dec and dec(pt.a) or tostring(pt.a)) .. "/" .. tostring(pt.b)
    for _, v in ipairs(pt.subs or {}) do t = t .. " | " .. tostring(v) .. "/2" end
    return t
end
-- how far a part is (its skills at 2 each count as steps of their own)
local function partFrac(pt)
    local n, sum = 1, (pt.b > 0) and clamp01(pt.a / pt.b) or 1
    for _, v in ipairs(pt.subs or {}) do n = n + 1; sum = sum + clamp01((tonumber(v) or 0) / 2) end
    return sum / n
end

-- one row as the mod's page shows it now (nil when the page would not list it)
local function readRow(c, e)
    if e.on and not e.on(c) then return nil end
    local r = { id = "etw:" .. e.id, eid = e.id, cat = e.cat, kind = e.kind, entry = e, marks = {}, extra = nil }
    local specs = {}
    if e.kind == "bar" then
        local v, raw = e.val(c)
        r.value, r.raw = clamp01(v), raw
        r.name = e.traitName and tinfo(traitOf(c, e.traitName)).label or words(e.name)
        r.desc = words(e.desc)
        for _, m in ipairs(e.marks and e.marks(c) or {}) do
            local t = traitOf(c, m.spec)
            -- (a mark at no number, or a trait the mod did not register, is left out)
            if t and tonumber(m.at) then r.marks[#r.marks + 1] = { at = clamp01(m.at), t = t, sign = m.sign } end
        end
        r.extra = e.extra and e.extra(c) or nil
        for _, sp in ipairs(e.traits or {}) do specs[#specs + 1] = sp end
    else
        local t = traitOf(c, e.spec)
        if not t then return nil end
        -- the mod hides a trait's progress while it waits in the Delayed Traits System
        if e.kind == "count" and not e.noDelay and delayed(c.md, t) then return nil end
        local i = tinfo(t)
        r.name = i.label
        r.trait = t
        local has = owns(c.p, t)
        if e.kind == "count" then
            r.parts = e.parts(c)
            local sum, tips = 0, {}
            for _, pt in ipairs(r.parts) do sum = sum + partFrac(pt); tips[#tips + 1] = pt.tip end
            r.value = (#r.parts > 0) and (sum / #r.parts) or 0
            r.desc = table.concat(tips, " ")
            -- reaching the end gains the trait, or loses it when you have it
            r.marks[1] = { at = 1, t = t, sign = has and "-" or "+" }
        else
            -- "1 in N": a roll on each event, not a build-up (no strip)
            r.value = 0
            r.note = "1 " .. getText("UI_ETW_Chance") .. " " .. tostring(c.SB[e.nKey])
            r.desc = words(e.tipKey)
            r.marks[1] = { at = 1, t = t, sign = "-" }
        end
    end
    -- the traits the row can give or take: from its marks (and any it names itself)
    local seen, all = {}, {}
    for _, m in ipairs(r.marks) do
        local k = tostring(m.t)
        if not seen[k] then seen[k] = true; all[#all + 1] = m.t end
    end
    for _, sp in ipairs(specs) do
        local t = traitOf(c, sp)
        if t and not seen[tostring(t)] then seen[tostring(t)] = true; all[#all + 1] = t end
    end
    r.all = all
    r.now = {}
    for _, t in ipairs(all) do if owns(c.p, t) then r.now[#r.now + 1] = t end end
    r.fill = (r.kind == "chance") and 0 or segment(r.value, r.marks)
    return r
end

-- the Delayed Traits System's list (its own group): a trait waiting for its roll
local function delayedRows(c, rows)
    local list = c.SB.DelayedTraitsSystem and c.md.DelayedTraits
    if not list then return end
    for i = 1, #list do
        local d = list[i]
        local okT, t = pcall(c.F.resolveTrait, d[1])
        if okT and t then
            local info = tinfo(t)
            -- the mod's words: "gained on next trait-specific action", or "1 in <roll>"
            local note = d[3] and getText("UI_ETW_DelayedTraitReadyOnNextAction") or ("1 " .. getText("UI_ETW_Chance") .. " " .. tostring(d[2]))
            local has = owns(c.p, t)
            local r = { id = "etw:delayed:" .. tostring(d[1]), eid = "delayed", cat = "delayed", kind = "delayed", name = info.label,
                        trait = t, value = 0, fill = 0, note = note, desc = words("Sandbox_ETW_DelayedTraitsSystem_tooltip"),
                        marks = { { at = 1, t = t, sign = has and "-" or "+" } }, all = { t }, now = has and { t } or {} }
            rows[#rows + 1] = r
        end
    end
end

local function state(win)
    local st = win._etw
    if not st then
        st = { rows = {}, byId = {} }
        win._etw = st
    end
    return st
end

local function refresh(win, force)
    local st = state(win)
    local p = win._playerObj
    -- read the mod at most twice a second (every caller in a frame shares the one reading)
    local now = getTimestampMs()
    if not p or (not force and st.at and now - st.at < 500 and st.player == p) then return st end
    st.at, st.player = now, p
    local E_ = mod()
    local rows, byId = {}, {}
    st.hidden, st.broken, st.off = false, false, false
    st.rows, st.byId = rows, byId
    if not E_ then st.broken = true; return st end
    local SB = SBV()
    -- every dynamic trait off: the mod drops its page, and ZeD shows none of it
    if SB.DisableAllDynamicTraits == true then st.off = true; return st end
    -- the mod's sandbox option "UI page" off: it shows no progress, nor does ZeD
    if SB.UIPage == false then st.hidden = true; return st end
    local okM, md = pcall(E_.F.getETWModData, p)
    local okS, stats = pcall(readStats, p, E_)
    if not (okM and type(md) == "table" and okS) then st.broken = true; return st end
    local c = { p = p, md = md, SB = SB, s = stats, C = E_.C, F = E_.F, R = E_.R }
    for _, e in ipairs(ENTRIES) do
        local ok, r = pcall(readRow, c, e)
        if ok and r then rows[#rows + 1] = r; byId[r.id] = r
        elseif not ok and ZeD.logOnce then ZeD.logOnce("etw row " .. tostring(e.id), r) end
    end
    pcall(delayedRows, c, rows)
    for _, r in ipairs(rows) do byId[r.id] = r end
    return st
end
S.refresh = refresh

-- does a row answer the Find box? (its name, its group, its traits)
local function matches(r, q)
    if q == "" then return true end
    if string.find(string.lower(r.name or ""), q, 1, true) then return true end
    if string.find(string.lower(catName(r.cat)), q, 1, true) then return true end
    for _, t in ipairs(r.all or {}) do
        if string.find(string.lower(tinfo(t).label), q, 1, true) then return true end
    end
    return false
end
local function visible(st, q, only)
    local out = {}
    for _, r in ipairs(st.rows) do
        if (not only or #r.now > 0) and matches(r, q) then out[#out + 1] = r end
    end
    return out
end

-- ---------------------------------------------------------------------------
-- THE SOURCE (ZeD.TraitsTab): layout, drawing, clicks and the controller's stops
-- ---------------------------------------------------------------------------
local SRC = {}

function SRC.owns(id) return type(id) == "string" and id:sub(1, 4) == "etw:" end

function SRC.counts(win, q, only)
    local st = refresh(win)
    local with = 0
    for _, r in ipairs(st.rows) do if #r.now > 0 then with = with + 1 end end
    return #st.rows, with, #visible(st, string.lower(q or ""), only)
end

local function add(L, it) L.items[#L.items + 1] = it; return it end

-- hosted: a section head with the mod's name, then each group as a category row;
-- own tab: each group as a section head (the mod's name is on the credit line)
function SRC.layout(win, L, x, y, w, q, only, hosted)
    local T = ZeD.T
    local st = refresh(win)
    q = string.lower(q or "")
    local vis = visible(st, q, only)
    -- (every dynamic trait off: nothing at all, as the mod shows no page)
    if st.off then return y end
    if hosted then
        -- (Find or the switch left none of this mod's rows, or the mod could not be read: no head
        -- either; the page turned off by the server still gets its head and a line saying so)
        if (#vis == 0 or st.broken) and not st.hidden then return y end
        y = y + T.px(6)
        local shut = S.closed["*mod"] and q == ""
        add(L, { kind = "ext", src = SRC, sub = "mod", n = #vis, shut = shut, x = x, y = y, w = w, h = T.px(CAT_H) })
        y = y + T.px(CAT_H) + T.sp.afterGroove
        if shut then return y end
    end
    if st.hidden or st.broken then
        local text = tr(st.hidden and "UI_ZeD_ETW_Hidden" or "UI_ZeD_ETW_Broken")
        local lines = ZeD.Atoms.wrapText(text, T.fontF2, w)
        local eh = #lines * (F(2) + T.px(2)) - T.px(2)
        add(L, { kind = "ext", src = SRC, sub = "empty", text = text, x = x, y = y + T.px(8), w = w, h = eh })
        return y + T.px(8) + eh + T.px(12)
    end
    for _, cat in ipairs(CAT_ORDER) do
        local rs = {}
        for _, r in ipairs(vis) do if r.cat == cat then rs[#rs + 1] = r end end
        if #rs > 0 then
            local shut = S.closed[cat] and q == ""
            local hh = hosted and T.px(15) or T.px(CAT_H)
            if not hosted then y = y + T.px(6) end
            add(L, { kind = "ext", src = SRC, sub = "cat", cat = cat, n = #rs, shut = shut, hosted = hosted, x = x, y = y, w = w, h = hh })
            y = y + hh + T.sp.afterGroove
            if not shut then
                local rh = F(1) + T.px(8)   -- Skills' row height (grows with Large text)
                for i, r in ipairs(rs) do
                    add(L, { kind = "ext", src = SRC, sub = "row", row = r, odd = i % 2 == 0, x = x, y = y, w = w, h = rh })
                    y = y + rh + T.sp.rowGap
                end
            end
        end
    end
    return y
end

-- the controller's mark options for an element id (only while it has the focus)
local _focusOpts = {}
local function focusOf(win, id)
    local Fo = ZeD.Input and ZeD.Input.Focus
    if Fo and Fo.isFocused and Fo.isFocused(win, nil, id) then
        _focusOpts.win = win
        return _focusOpts
    end
    return nil
end
-- the footer help line's words for what the pointer is over
local function help(win, text)
    if ZeD.Help and ZeD.Help.set then ZeD.Help.set(win, text) end
end

-- the progress as the row's fill, in Skills' colours and strengths
local function fillColour(T, r)
    if r.value >= 1 then return T.warning, FILL_TOP_A end
    if r.fill >= 0.75 then return T.danger, FILL_A end
    if r.fill >= 0.4 then return T.warning, FILL_A end
    return T.positive, FILL_A
end
-- a mark's colour: green where it holds a good trait, red a bad one (the steps of Traits As Skills)
local function markColour(T, m) return tinfo(m.t).bad and T.danger or T.positive end

-- the strip: the mod's bar, filled to its value, a tick wherever it gains or loses a trait
local function drawStrip(panel, x, y, w, h, r)
    local T = ZeD.T
    local bdc, tx = T.base, T.text
    panel:drawRect(x, y, w, h, 1, bdc.r, bdc.g, bdc.b)
    local fw = math.floor(w * r.value)
    if fw > 0 then panel:drawRect(x, y, fw, h, 1, tx.r, tx.g, tx.b) end
    ZeD.Atoms.frame(panel, x, y, w, h, T.borderS)
    local tw = T.px(2)
    for _, m in ipairs(r.marks) do
        -- a tick 2u wide, 2u past the strip's top and bottom
        local mx = x + math.floor(m.at * (w - tw))
        local mc = markColour(T, m)
        panel:drawRect(mx, y - T.px(2), tw, h + T.px(4), 1, mc.r, mc.g, mc.b)
    end
end

-- one row, drawn like a Skills row
local function drawRow(panel, win, it, y, mx, my, sel)
    local T = ZeD.T
    local A = ZeD.Atoms
    local r = it.row
    local hov = mx ~= nil and mx >= it.x and mx < it.x + it.w and my >= y and my < y + it.h
    if it.odd then local s = T.stripe; panel:drawRect(it.x, y, it.w, it.h, s.a or 1, s.r, s.g, s.b) end
    -- the fill (progress to the next tick), the picked row's wash, the hover wash, the controller's mark
    if r.fill > 0 or r.value >= 1 then
        local fc, fa = fillColour(T, r)
        local fw = (r.value >= 1) and it.w or math.floor(it.w * r.fill)
        if fw > 0 then panel:drawRect(it.x, y, fw, it.h, fa, fc.r, fc.g, fc.b) end
    end
    local ac = T.accent
    if sel == r.id then panel:drawRect(it.x, y, it.w, it.h, T.selectionA, ac.r, ac.g, ac.b) end
    if hov then
        local hv = T.hover
        panel:drawRect(it.x, y, it.w, it.h, hv.a, hv.r, hv.g, hv.b)
        help(win, tr("UI_ZeD_TAS_HelpRow", r.name))
    end
    local ink = T.text
    local fo = focusOf(win, "etw:row:" .. r.id)
    if fo and ZeD.Focus.mark(panel, it.x, y, it.w, it.h, fo) then ink = T.textOnFocus end
    -- the square: + while the row gives you a good trait, - a bad one, empty while none
    local bw = T.px(BADGE_W)
    local s3 = T.surf3
    panel:drawRect(it.x, y, bw, it.h, (#r.now > 0) and SQ_ON_A or SQ_OFF_A, s3.r, s3.g, s3.b)
    if #r.now > 0 then
        local sign = tinfo(r.now[1]).bad and "-" or "+"
        panel:drawText(sign, it.x + math.floor((bw - ZeD.TM:MeasureStringX(T.fontF2, sign)) / 2), y + math.floor((it.h - F(2)) / 2),
            ink.r, ink.g, ink.b, ink.a or 1, T.fontF2)
    end
    -- the name
    local nx = it.x + bw + T.px(6)
    panel:drawText(A.truncateText(r.name, T.fontF2, T.px(NAME_W)), nx, y + math.floor((it.h - F(2)) / 2), ink.r, ink.g, ink.b, ink.a or 1, T.fontF2)
    -- the strip, or (a chance or a delayed trait) the mod's "1 in N" words in its place
    local sx = nx + T.px(NAME_W) + T.px(6)
    local sw, sh = T.px(STRIP_W), T.px(STRIP_H)
    if r.kind == "bar" or r.kind == "count" then
        drawStrip(panel, sx, y + math.floor((it.h - sh) / 2), sw, sh, r)
    elseif r.note then
        local dim = T.toneLo or T.textDim
        panel:drawText(A.truncateText(r.note, T.fontF1, sw), sx, y + math.floor((it.h - F(1)) / 2), dim.r, dim.g, dim.b, dim.a or 1, T.fontF1)
    end
    -- the trait(s) you have now from this row, or No trait (right-aligned)
    local cx = sx + sw + T.px(6)
    local dsz = T.px(6)
    local right = it.x + it.w - T.px(6)
    if #r.now == 0 then
        local c = T.toneLo or T.textDim
        local text = tr("UI_ZeD_TAS_NoTrait")
        local x0 = math.max(cx, right - (ZeD.TM:MeasureStringX(T.fontF2, text) + dsz + T.px(7)))
        A.drawStatusHollow(panel, x0, y + math.floor((it.h - dsz) / 2), c, dsz)
        panel:drawText(A.truncateText(text, T.fontF2, right - x0 - dsz - T.px(7)), x0 + dsz + T.px(7), y + math.floor((it.h - F(2)) / 2), c.r, c.g, c.b, c.a or 1, T.fontF2)
    else
        local total = 0
        for i, t in ipairs(r.now) do
            total = total + dsz + T.px(6) + ZeD.TM:MeasureStringX(T.fontF2, tinfo(t).label) + (i > 1 and T.px(8) or 0)
        end
        local x0 = math.max(cx, right - total)
        for i, t in ipairs(r.now) do
            if i > 1 then x0 = x0 + T.px(8) end
            if x0 + dsz >= right then break end
            local info = tinfo(t)
            A.drawStatusDot(panel, x0, y + math.floor((it.h - dsz) / 2), info.bad and T.danger or T.positive, dsz)
            x0 = x0 + dsz + T.px(6)
            local txt = A.truncateText(info.label, T.fontF2, right - x0)
            panel:drawText(txt, x0, y + math.floor((it.h - F(2)) / 2), ink.r, ink.g, ink.b, ink.a or 1, T.fontF2)
            x0 = x0 + ZeD.TM:MeasureStringX(T.fontF2, txt)
        end
    end
end

-- the mod's name (its mod.info), for the hosted section head and the credit line
local function modName()
    local mi = getModInfoByID and getModInfoByID(MOD_ID)
    return mi and mi:getName() or MOD_ID, mi
end

function SRC.drawItem(panel, win, it, y, mx, my, sel)
    local hov = mx ~= nil and mx >= it.x and mx < it.x + it.w and my >= y and my < y + it.h
    local sub = it.sub
    if sub == "row" then
        drawRow(panel, win, it, y, mx, my, sel)
        return hov and it.row.id or nil
    elseif sub == "mod" then
        local name = modName()
        if hov then help(win, tr(it.shut and "UI_ZeD_ETW_HelpCatShow" or "UI_ZeD_ETW_HelpCatHide", name)) end
        ZeD.Molecules.drawSectionHeader(panel, it.x, y, it.w, name, it.n, not it.shut, hov, nil, nil, nil, nil, nil,
            { focus = focusOf(win, "etw:mod") })
    elseif sub == "cat" then
        local name = catName(it.cat)
        if hov then help(win, tr(it.shut and "UI_ZeD_ETW_HelpCatShow" or "UI_ZeD_ETW_HelpCatHide", name)) end
        local fo = focusOf(win, "etw:cat:" .. it.cat)
        if it.hosted then
            -- under the mod's section head: the lighter category row
            ZeD.Molecules.drawCategoryRow(panel, it.x, y, it.w, name, it.n, not it.shut, { hover = hov, focus = fo, h = it.h })
        else
            ZeD.Molecules.drawSectionHeader(panel, it.x, y, it.w, name, it.n, not it.shut, hov, nil, nil, nil, nil, nil, { focus = fo })
        end
    elseif sub == "empty" then
        ZeD.Molecules.drawEmptyLine(panel, it.x, y, it.w, it.text)
    end
    return nil
end

function SRC.click(win, it)
    if it.sub == "row" then return it.row.id end
    if it.sub == "mod" then S.closed["*mod"] = not S.closed["*mod"]
    elseif it.sub == "cat" then S.closed[it.cat] = not S.closed[it.cat] end
    return nil
end

-- (tas = true and etw = true: either host's focus code knows the stop as one of its own)
function SRC.focusable(win, it, dy)
    if it.sub == "row" then
        local id = it.row.id
        return { x = it.x, y = dy, w = it.w, h = it.h, cy = it.y, id = "etw:row:" .. id, tas = true, etw = true, rowId = id,
            onFocus = function() end, onActivate = function() end }
    elseif it.sub == "mod" then
        return { x = it.x, y = dy, w = it.w, h = it.h, cy = it.y, id = "etw:mod", tas = true, etw = true,
            onFocus = function() end, onActivate = function() S.closed["*mod"] = not S.closed["*mod"] end }
    elseif it.sub == "cat" then
        local cat = it.cat
        return { x = it.x, y = dy, w = it.w, h = it.h, cy = it.y, id = "etw:cat:" .. cat, tas = true, etw = true,
            onFocus = function() end, onActivate = function() S.closed[cat] = not S.closed[cat] end }
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- THE DETAILS AT THE FOOT
-- ---------------------------------------------------------------------------
-- a mark in the mod's words: "+ Resilient", "- Prone to Illness", "+/- Pluviophile"
local function markText(m) return m.sign .. " " .. tinfo(m.t).label end

-- the key / value lines: the mod's numbers, its own lines, where traits come and go,
-- what moves the progress (the mod's description), and the traits you have now
local function detailItems(r)
    local items = {}
    local kProg = tr("UI_ZeD_TAS_KProgress")
    if r.kind == "bar" then
        items[#items + 1] = { k = kProg, v = r.raw or "", bar = r.value }
    elseif r.kind == "count" then
        for i, pt in ipairs(r.parts or {}) do
            items[#items + 1] = { k = (i == 1) and kProg or "", v = r.name .. ": " .. partText(pt), bar = partFrac(pt) }
        end
    else
        items[#items + 1] = { k = kProg, v = r.name .. ": " .. tostring(r.note or "") }
    end
    for _, line in ipairs(r.extra or {}) do items[#items + 1] = { k = "", v = line } end
    if #r.marks > 0 then
        local parts = {}
        for _, m in ipairs(r.marks) do
            if r.kind == "bar" then
                -- (where along the bar, as a whole percent)
                parts[#parts + 1] = markText(m) .. " (" .. tostring(math.floor(m.at * 100 + 0.5)) .. "%)"
            else
                parts[#parts + 1] = markText(m)
            end
        end
        items[#items + 1] = { k = tr("UI_ZeD_ETW_KChanges"), v = table.concat(parts, ", ") }
    end
    items[#items + 1] = { k = tr("UI_ZeD_ETW_KWhat"), v = (r.desc ~= "" and r.desc) or tr("UI_ZeD_TAS_NoneList") }
    local now
    if #r.now == 0 then now = tr("UI_ZeD_TAS_NoTrait")
    else
        local parts = {}
        for _, t in ipairs(r.now) do
            local i = tinfo(t)
            parts[#parts + 1] = i.label .. ": " .. ((i.desc ~= "") and i.desc or tr("UI_ZeD_TAS_NoDesc"))
        end
        now = table.concat(parts, " ")
    end
    items[#items + 1] = { k = tr("UI_ZeD_TAS_KNow"), v = now }
    return items
end
S.detailItems = detailItems

-- the key column fits the widest key (keys are short, but other languages are longer)
local function keyW(items)
    local T = ZeD.T
    local w = T.px(KEY_W)
    for _, it in ipairs(items) do w = math.max(w, ZeD.TM:MeasureStringX(T.fontF1, ZeD.textCase(it.k)) + T.px(4)) end
    return w
end
-- the height of the title row and, for a bar, the bar with its marks' names in two lines
local function topH(r)
    local T = ZeD.T
    local h = T.px(8) + F(4) + T.px(8)
    if r.kind == "bar" or r.kind == "count" then h = h + T.px(14) + T.px(3) + (F(5) + T.px(2)) * 2 + T.px(4) end
    return h
end
-- the wrapped lines of every item at a width, and their height (nothing is dropped)
local function layoutItems(items, iw, kw)
    local T = ZeD.T
    local vw = iw - kw - T.px(8)
    local h = 0
    for _, it in ipairs(items) do
        it.lines = ZeD.Atoms.wrapText(it.v or "", T.fontF2, math.max(T.px(40), vw - (it.bar and T.px(170) or 0)))
        h = h + #it.lines * F(2) + T.px(3)
    end
    return h
end

-- the mod's bar across the details: the fill, a tick per mark, a pointer at the value, the marks'
-- names under it in two lines (alternating, so neighbours do not run into each other)
local function drawBigBar(panel, r, ix, iw, cy)
    local T = ZeD.T
    local A = ZeD.Atoms
    local segH = T.px(14)
    A.drawFillBar(panel, ix, cy, iw, r.value, false, T.accent, segH)
    local tw = T.px(2)
    local sorted = {}
    for _, m in ipairs(r.marks) do sorted[#sorted + 1] = m end
    table.sort(sorted, function(a, b) return a.at < b.at end)
    local xs = {}
    for i, m in ipairs(sorted) do
        xs[i] = ix + math.floor(m.at * (iw - tw))
        local mc = markColour(T, m)
        panel:drawRect(xs[i], cy - T.px(2), tw, segH + T.px(4), 1, mc.r, mc.g, mc.b)
    end
    -- (the pointer where the value stands, as the ladder's in Traits As Skills)
    A.drawTriangleDown(panel, ix + math.floor(r.value * (iw - tw)) - T.px(4), cy - T.px(6), T.px(10), T.accentBright)
    local dim = T.toneLo or T.textDim
    local dot = T.px(6)
    for i, m in ipairs(sorted) do
        local line = (i - 1) % 2
        -- the room between this name and its neighbours on the same line (the whole width if none)
        local room = iw
        if xs[i + 2] then room = math.min(room, xs[i + 2] - xs[i]) end
        if xs[i - 2] then room = math.min(room, xs[i] - xs[i - 2]) end
        room = math.max(T.px(6), room - T.px(6) - dot - T.px(4))
        local text = A.truncateText(markText(m), T.fontF5, room)
        -- the dot in the mark's colour, then the name: centred on the tick, kept inside the panel
        local lw = dot + T.px(4) + ZeD.TM:MeasureStringX(T.fontF5, text)
        local tx = math.max(ix, math.min(ix + iw - lw, xs[i] - math.floor(lw / 2)))
        local ty = cy + segH + T.px(3) + line * (F(5) + T.px(2))
        A.drawStatusDot(panel, tx, ty + math.floor((F(5) - dot) / 2), markColour(T, m), dot)
        panel:drawText(text, tx + dot + T.px(4), ty, dim.r, dim.g, dim.b, dim.a or 1, T.fontF5)
    end
end

function SRC.drawDetail(panel, win, id, x, y, w, h, sc)
    local T = ZeD.T
    local A = ZeD.Atoms
    local st = refresh(win)
    local r = st.byId[id]
    local pad = T.px(PAD)
    local ix, iw = x + pad, w - pad * 2
    local dim, tc = T.toneLo or T.textDim, T.text
    local innerH = h - T.px(1)
    panel:setStencilRect(x, y + T.px(1), w, innerH)
    if sc then sc.visible = false end
    if not r then
        local lines = A.wrapText(tr("UI_ZeD_ETW_Pick"), T.fontF2, iw)
        for i, l in ipairs(lines) do panel:drawText(l, ix, y + T.px(12) + (i - 1) * F(2), dim.r, dim.g, dim.b, dim.a or 1, T.fontF2) end
        panel:clearStencilRect()
        return
    end
    -- the content, measured first: a panel too short for it scrolls instead of dropping lines
    local items = detailItems(r)
    local kw = keyW(items)
    local sbW = T.sp.scrollbarW
    local contentH = topH(r) + layoutItems(items, iw, kw) + T.px(6)
    local needs = sc ~= nil and contentH > innerH
    if needs then
        iw = iw - sbW
        contentH = topH(r) + layoutItems(items, iw, kw) + T.px(6)
    end
    local ds = win._etwDet or {}
    win._etwDet = ds
    if sc and ds.key ~= id then ds.key = id; sc:setScrollPos(0) end
    local off = 0
    if needs then
        sc.visible = true
        sc.x, sc.y, sc.height = x + w - sbW, y + T.px(1), innerH
        sc:setBarSize(innerH / contentH)
        off = math.floor(sc.scrollPos * (contentH - innerH))
        panel:setStencilRect(x, y + T.px(1), w - sbW, innerH)
    elseif sc then
        sc:setScrollPos(0)
    end
    local cy = y + T.px(8) - off
    -- the title row: the name, and at the right where the mod's page keeps it
    local th = T.textHead or tc
    panel:drawText(r.name, ix, cy, th.r, th.g, th.b, th.a or 1, T.fontF4)
    local where = catName(r.cat)
    if CAT_PARENT[r.cat] then where = words(CAT_PARENT[r.cat]) .. " | " .. where end
    local catT = tr("UI_ZeD_TAS_Category", where)
    panel:drawText(catT, ix + iw - ZeD.TM:MeasureStringX(T.fontF1, catT), cy + F(4) - F(1), dim.r, dim.g, dim.b, dim.a or 1, T.fontF1)
    cy = cy + F(4) + T.px(8)
    if r.kind == "bar" or r.kind == "count" then
        drawBigBar(panel, r, ix, iw, cy)
        cy = cy + T.px(14) + T.px(3) + (F(5) + T.px(2)) * 2 + T.px(4)
    end
    -- key / value lines: the key in the small font, sentence case; the value wrapped, all of it
    local vx = ix + kw + T.px(8)
    for _, it in ipairs(items) do
        panel:drawText(ZeD.textCase(it.k), ix, cy + T.px(2), dim.r, dim.g, dim.b, dim.a or 1, T.fontF1)
        for i, l in ipairs(it.lines) do
            panel:drawText(l, vx, cy, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
            if i == 1 and it.bar then
                -- the framed strip beside the first line (the standard amount bar)
                local bx = vx + ZeD.TM:MeasureStringX(T.fontF2, l) + T.px(8)
                local bw2 = math.min(T.px(160), ix + iw - bx)
                if bw2 > T.px(20) then
                    A.drawFillBar(panel, bx, cy + math.floor((F(2) - T.fillBarH) / 2), bw2, it.bar, false, T.accent)
                end
            end
            cy = cy + F(2)
        end
        cy = cy + T.px(3)
    end
    panel:clearStencilRect()
    if needs then sc:draw(panel) end
end

S.source = SRC
ZeD.TraitsTab.addSource(MOD_ID, SRC)

-- ===========================================================================
-- THE TAB OF ITS OWN (only without Traits As Skills, whose support owns the tab then)
-- ===========================================================================
if HOSTED then return end

local function hostState(win)
    local hs = win._etwHost
    if not hs then
        hs = { scroll = ZeD_ScrollbarState:new(), detScroll = ZeD_ScrollbarState:new(), zones = {} }
        win._etwHost = hs
    end
    return hs
end

local function focusedEl(win)
    local Fo = ZeD.Input and ZeD.Input.Focus
    if not (Fo and Fo.getFocusedWindow and Fo.getFocusedWindow() == win and Fo.getFocusedElement) then return nil end
    local el = Fo.getFocusedElement(win)
    if el and el.etw then return el end
    return nil
end

-- the tab's list: the credit line, the summary line, then the source's groups and rows
local function hostLayout(win, w)
    local T = ZeD.T
    local L = { items = {} }
    local x, y = T.px(PAD), T.px(8)
    local cw = w - T.px(PAD) * 2
    add(L, { kind = "credit", x = x, y = y, w = cw, h = math.max(F(5), T.px(18)) })
    y = y + math.max(F(5), T.px(18)) + T.px(8)
    add(L, { kind = "sum", x = x, y = y, h = F(1) })
    y = y + F(1) + T.px(10)
    local q = string.lower(S.find or "")
    local _, _, shown = SRC.counts(win, q, S.only)
    local st = refresh(win)
    if shown == 0 and not (st.hidden or st.broken) then
        local lines = ZeD.Atoms.wrapText(tr("UI_ZeD_TAS_Nothing", S.find), T.fontF2, cw)
        local eh = #lines * (F(2) + T.px(2)) - T.px(2)
        add(L, { kind = "empty", x = x, y = y + T.px(8), w = cw, h = eh })
        y = y + T.px(8) + eh + T.px(12)
    end
    y = SRC.layout(win, L, x, y, cw, q, S.only, false)
    L.h = y + T.px(12)
    return L
end

-- the credit line (the mod's name and author) and the All | With a trait switch
local function drawCredit(panel, win, hs, it, y)
    local T = ZeD.T
    local A = ZeD.Atoms
    local c = T.toneLo or T.textDim
    local name, mi = modName()
    local author = nil
    if mi then local ok, a = pcall(function() return mi:getAuthor() end); if ok and a and a ~= "" then author = a end end
    local text = author and tr("UI_ZeD_TAS_Credit", name, author) or name
    panel:drawText(text, it.x, y + math.floor((it.h - F(5)) / 2), c.r, c.g, c.b, c.a or 1, T.fontF5)
    local all, with = SRC.counts(win, "", false)
    local labels = { tr("UI_ZeD_TAS_All", all), tr("UI_ZeD_TAS_WithTrait", with) }
    local f = T.fontF2
    local rs = A.radioSize()
    local ws, total = {}, 0
    for i, l in ipairs(labels) do
        ws[i] = T.px(8) + rs + T.px(8) + ZeD.TM:MeasureStringX(f, l) + T.px(8)
        total = total + ws[i]
    end
    local bx = it.x + it.w - total
    local hv = T.hover
    hs.only = {}
    local fo = focusOf(win, "etw:only")
    for i, l in ipairs(labels) do
        local on = (i == 2) == (S.only == true)
        local hover = A.mouseIn(panel, bx, y, ws[i], it.h)
        if hover then
            panel:drawRect(bx, y, ws[i], it.h, hv.a, hv.r, hv.g, hv.b)
            help(win, tr("UI_ZeD_TAS_HelpOnly", l))
        end
        local tcol = T.text
        if fo and on and ZeD.Focus.mark(panel, bx, y, ws[i], it.h, fo) then tcol = T.textOnFocus end
        A.drawRadio(panel, bx + T.px(8), y + math.floor((it.h - rs) / 2), on, { hover = hover })
        panel:drawText(l, bx + T.px(8) + rs + T.px(8), y + math.floor((it.h - F(2)) / 2), tcol.r, tcol.g, tcol.b, tcol.a or 1, f)
        hs.only[#hs.only + 1] = { x = bx, y = y, w = ws[i], h = it.h, val = (i == 2) }
        bx = bx + ws[i]
    end
end

-- the summary line: good and bad traits the rows give now, and rows with none (Identity's words)
local function drawSum(panel, win, it, y)
    local T = ZeD.T
    local st = refresh(win)
    local good, bad, none = 0, 0, 0
    for _, r in ipairs(st.rows) do
        if #r.now == 0 then none = none + 1 end
        for _, t in ipairs(r.now) do if tinfo(t).bad then bad = bad + 1 else good = good + 1 end end
    end
    local dsz = T.px(6)
    local x = it.x
    local tc = T.text
    local dy = y + math.floor((F(1) - dsz) / 2)
    local function part(dot, text)
        if dot == "pos" then ZeD.Atoms.drawStatusDot(panel, x, dy, T.positive, dsz)
        elseif dot == "neg" then ZeD.Atoms.drawStatusDot(panel, x, dy, T.danger, dsz)
        else ZeD.Atoms.drawStatusHollow(panel, x, dy, T.toneLo or T.textDim, dsz) end
        x = x + dsz + T.px(6)
        panel:drawText(text, x, y, tc.r, tc.g, tc.b, tc.a or 1, T.fontF1)
        x = x + ZeD.TM:MeasureStringX(T.fontF1, text) + T.px(14)
    end
    part("pos", ZeD.textCase(tr("UI_ZeD_Identity_TraitsPositive", good)))
    part("neg", ZeD.textCase(tr("UI_ZeD_Identity_TraitsNegative", bad)))
    part("off", ZeD.textCase(tr("UI_ZeD_TAS_NoTraitN", none)))
end

-- keep the controller's focus in view (once per newly focused stop)
local function followFocus(win, hs, viewH, maxOff)
    local el = focusedEl(win)
    if not el or not el.cy or el.id == hs.lastPinned then return end
    hs.lastPinned = el.id
    local off = hs.off or 0
    local newOff = off
    if el.cy < off then newOff = el.cy - ZeD.T.px(6)
    elseif el.cy + el.h > off + viewH then newOff = el.cy + el.h - viewH + ZeD.T.px(6) end
    newOff = math.max(0, math.min(maxOff, newOff))
    if newOff ~= off and maxOff > 0 then hs.scroll:setScrollPos(newOff / maxOff) end
end

function S.render(panel, win, x, y, w, h)
    local T = ZeD.T
    local hs = hostState(win)
    if not win._playerObj then return end
    -- a new visit reads the mod at once
    if not hs.visiting then hs.visiting = true; refresh(win, true) end
    local M = ZeD.Molecules
    local headH = M.getTabHeaderH()
    -- the details keep their height, but never more than half the tab
    local detH = math.min(T.px(DET_H), math.floor((h - headH) / 2))
    local sy, sh = y + headH, h - headH - detH
    local scroll = hs.scroll
    local L = hostLayout(win, w - T.sp.scrollbarW)
    hs.L = L
    local needs = L.h > sh
    scroll.visible = needs
    local maxOff = math.max(0, L.h - sh)
    if needs then
        scroll.x, scroll.y, scroll.height = x + w - T.sp.scrollbarW, sy, sh
        scroll:setBarSize(sh / math.max(1, L.h))
    else
        scroll:setScrollPos(0)
    end
    followFocus(win, hs, sh, maxOff)
    local off = needs and math.floor(scroll.scrollPos * maxOff) or 0
    hs.off, hs.sy = off, sy
    local mx, my = panel:getMouseX(), panel:getMouseY()
    local Fo = ZeD.Input and ZeD.Input.Focus
    -- (the mouse's hover goes quiet while the controller's mark shows)
    if not (mx >= x and mx < x + w and my >= sy and my < sy + sh) or (Fo and Fo.cuesVisible and Fo.cuesVisible()) then mx, my = nil, nil end
    -- the focused row picks itself (the details follow focus with no press)
    local fe = focusedEl(win)
    if fe and fe.rowId then hs.sel = fe.rowId end
    hs.zones, hs.hover = {}, nil
    panel:setStencilRect(x, sy, w, sh)
    for _, it in ipairs(L.items) do
        local dy = sy + it.y - off
        local ih = it.h or T.px(20)
        if dy + ih >= sy and dy <= sy + sh then
            local k = it.kind
            if k == "credit" then drawCredit(panel, win, hs, it, dy)
            elseif k == "sum" then drawSum(panel, win, it, dy)
            elseif k == "empty" then M.drawEmptyLine(panel, it.x, dy, it.w, tr("UI_ZeD_TAS_Nothing", S.find))
            elseif k == "ext" then
                local hid = SRC.drawItem(panel, win, it, dy, mx, my, hs.sel)
                if hid then hs.hover = hid end
                local zy0, zy1 = math.max(sy, dy), math.min(sy + sh, dy + it.h)
                if zy1 > zy0 then hs.zones[#hs.zones + 1] = { x = it.x, y = zy0, w = it.w, h = zy1 - zy0, item = it } end
            end
        end
    end
    panel:clearStencilRect()
    panel:setStencilRect(0, 0, panel:getWidth(), panel:getHeight())
    -- the details at the foot (the hovered row, else the picked one)
    local dY = y + h - detH
    ZeD.Atoms.surfaceFill(panel, x, dY, w, detH, "surf2")
    ZeD.Atoms.drawDividerH(panel, x, dY, w, true)
    hs.detRect = { x = x, y = dY, w = w, h = detH }
    SRC.drawDetail(panel, win, hs.hover or hs.sel or "", x, dY, w, detH, hs.detScroll)
    -- the header: the tab's name; Find at its right (a text box placed by onWindowFrame)
    M.drawTabHeader(panel, x, y, w, getText("IGUI_char_Traits"), false, false, true)
    local fh = T.inputH or T.px(22)
    hs.findRect = { x = x + w - T.px(PAD) - T.px(FIND_W), y = y + math.floor((headH - fh) / 2), w = T.px(FIND_W), h = fh }
    local findFocus = focusOf(win, "etw:find")
    if findFocus then
        local f = hs.findRect
        ZeD.Focus.mark(panel, f.x, f.y, f.w, f.h, findFocus)
    end
    if needs then scroll:draw(panel) end
    hs.rendered = true
end

local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end

local function setOnly(hs, v)
    S.only = v
    hs.scroll:setScrollPos(0)
end

function S.onClick(win, x, y)
    local hs = hostState(win)
    local sc = hs.scroll
    if sc.visible and x >= sc.x and x < sc.x + sc.width and y >= sc.y and y < sc.y + sc.height then
        sc:handleMouseDown(y - sc.y)
        return
    end
    local ds = hs.detScroll
    if ds and ds.visible and x >= ds.x and x < ds.x + ds.width and y >= ds.y and y < ds.y + ds.height then
        ds:handleMouseDown(y - ds.y)
        return
    end
    for _, o in ipairs(hs.only or {}) do
        if x >= o.x and x < o.x + o.w and y >= o.y and y < o.y + o.h then
            setOnly(hs, o.val); getSoundManager():playUISound("UIActivateButton"); return
        end
    end
    for _, z in ipairs(hs.zones or {}) do
        if inRect(z, x, y) then
            local id = SRC.click(win, z.item)
            if id then hs.sel = id end
            getSoundManager():playUISound("UIActivateButton")
            return
        end
    end
end

-- the Find box with the controller: the game's on-screen keyboard
local function editFind(win, hs)
    local f = hs.field
    if not (f and f.input) then return end
    local p = win._playerObj
    local pn = p and p:getPlayerNum() or 0
    local jd = JoypadState.players[pn + 1]
    if jd and OnScreenKeyboard and OnScreenKeyboard.Show then
        local ok, osk = pcall(OnScreenKeyboard.Show, pn, f.input, jd)
        if ok and osk then return end
    end
    f.input:focus()
end

-- the controller's stops: Find, All | With a trait, each group, each row
function S.buildFocusables(win)
    local hs = win._etwHost
    if not (hs and hs.L and hs.sy) then return {} end
    local out = {}
    local fr = hs.findRect
    if fr then
        out[#out + 1] = { x = fr.x, y = fr.y, w = fr.w, h = fr.h, id = "etw:find", tas = true, etw = true,
            onFocus = function() end, onActivate = function(w) editFind(w, hs) end }
    end
    for _, it in ipairs(hs.L.items) do
        local dy = hs.sy + it.y - (hs.off or 0)
        if it.kind == "credit" then
            local o, o2 = hs.only and hs.only[1], hs.only and hs.only[2]
            if o and o2 then
                out[#out + 1] = { x = o.x, y = dy, w = o2.x + o2.w - o.x, h = it.h, cy = it.y, id = "etw:only", tas = true, etw = true,
                    onFocus = function() end,
                    onActivate = function() setOnly(hs, not S.only) end,
                    onDpadDir = function(w, el, dir)
                        if dir == "left" and S.only then setOnly(hs, false); return true end
                        if dir == "right" and not S.only then setOnly(hs, true); return true end
                        return false
                    end }
            end
        elseif it.kind == "ext" then
            local el = SRC.focusable(win, it, dy)
            if el then out[#out + 1] = el end
        end
    end
    return out
end

function S.scrollKey(win)
    local hs = win._etwHost
    if not hs then return nil end
    local n = hs.L and #hs.L.items or 0
    local closed = {}
    for c, v in pairs(S.closed) do if v then closed[#closed + 1] = c end end
    table.sort(closed)
    return tostring(hs.off or 0) .. ":" .. tostring(S.only) .. ":" .. tostring(S.find) .. ":" .. n .. ":" .. table.concat(closed, ",")
end

-- every frame, any tab: the Find box shows only on this tab
function S.onWindowFrame(win, drawerW)
    local hs = win._etwHost
    local show = win._activeTab == TAB_ID and win._drawerMode == "tab" and not win._drawerItem and (drawerW or 0) > 0
    if hs and not show then hs.visiting = false end
    if not show and not (hs and hs.field) then return end
    hs = hostState(win)
    local dp = win._drawerPanel
    if not hs.field and dp then
        local f = ZeD_SearchField:new(0, 0, ZeD.T.px(FIND_W), tr("UI_ZeD_TAS_Find"))
        f:initialise()
        f:setVisible(false)
        f.onFilter = function(_, text)
            S.find = text or ""
            hs.scroll:setScrollPos(0)
        end
        dp:addChild(f)
        hs.field = f
    end
    local f = hs.field
    if not f then return end
    local r = hs.findRect
    local on = (show and hs.rendered and r ~= nil and r.x + r.w <= drawerW) and true or false
    hs.rendered = false
    if on then
        f:setX(r.x); f:setY(r.y); f:setWidth(r.w); f:setHeight(r.h)
    end
    if f:isVisible() ~= on then f:setVisible(on) end
end

-- its lit pixel-art icon, the Traits tab's (ZeDUI/tools/tabpx/icons.py "traits", drawn by ZeD_TabPx.lua)
require "ZeD/ZeD_TabPx"
if ZeD.TabPx and ZeD.TabPx.ICONS then ZeD.TabPx.ICONS[TAB_ID] = true end

ZeD_CharacterWindow.addTab({
    id = TAB_ID, after = "skills", group = 2, glyph = "T",
    iconName = "traits-tab-white",
    -- the game's own word for the tab ("Traits")
    label = function() return getText("IGUI_char_Traits") end,
    -- the mod drops its page when its sandbox option turns every dynamic trait off; so does ZeD
    -- (read when the strip is drawn: the sandbox options are not loaded yet when this file is)
    visible = function() return SBV().DisableAllDynamicTraits ~= true end,
    render = S.render,
    -- (the wheel scrolls the details when the pointer is over them, the list otherwise)
    scroll = function(win)
        local hs = win._etwHost
        if not hs then return nil end
        local ds, r, dp = hs.detScroll, hs.detRect, win._drawerPanel
        if ds and ds.visible and r and dp then
            local mx, my = dp:getMouseX(), dp:getMouseY()
            if ds.dragging or (mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h) then return ds end
        end
        return hs.scroll
    end,
    onClick = S.onClick,
    buildFocusables = S.buildFocusables,
    scrollKey = S.scrollKey,
    onWindowFrame = S.onWindowFrame,
})
