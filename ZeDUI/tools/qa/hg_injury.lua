-- ZeDUI/tools/qa/hg_injury.lua  (Nov 23 2026, QA; tag hg_inj): every injury on every body part, read by ZeD's Health
-- tab. The director, Nov 23 2026: "Injuries, do all the injuries on every limb ... I don't want to get anybody killed
-- because our mod doesn't work in the health panel." Run after zedqa_prelude.lua and rt_kit.lua (hg.txt).
-- grep "ZEDQA hg_inj".
--
-- Staged with the game's own BodyPart setters (vanilla's health panel cheats, ISHealthPanel.lua:191-327), one state on
-- one clean part at a time, all 17 parts (Head, Neck, Upper and Lower Torso, Groin, both Upper Arms, Forearms, Hands,
-- Thighs, Shins and Feet) times 22 states: scratch, laceration, deep wound, bleeding, bite (its zombie infection taken
-- off in the same call and on every tick), lodged bullet, glass, burn, burn needing a wash, fracture, wound infection,
-- minor and heavy muscle strain, pain, heavy pain, clean and dirty bandage, stitches, splint on a fracture (not on the
-- head or the torso: the game never splints those) and the plantain, comfrey and garlic poultices.
-- Every part is made clean first (each part as found is kept and put back at the end), so the counts start at 0.
-- Checks:
--   start     the modules are loaded; god mode off with the guard on; First Aid 10; the Health tab open, figure shown
--   inj       for each state on each part, one line: (a) ZeD's injury list names the part with exactly the words
--             vanilla's health panel would show at this First Aid (an oracle written from ISHealthPanel.lua:631-847,
--             ZeD's own words where ZeD has them: Burn, Glass shards, Scratch), and its row is drawn; (b) the figure
--             holds what the read gave (woundsByFigure), tints the part as HealthTab.figureColor says (the strain tint
--             for strain, the health tint else) and draws the state's mark or picture on the part (mark-<kind>.png
--             inside the part's rect, or <sex>-<part>-bandage / -fracture / -splint), nothing for strain, pain and
--             poultices; (c) the summary: wounded and strained counts and the summary line ("1 of 17 injured" or
--             "No injuries, Muscle Strain: 1")
--   words     no word on the list is a raw translation key
--   state     per state: no Lua error over its 17 parts; every part put back exactly (snapDiff empty)
--   first aid at First Aid 0 the same oracle on a forearm and a shin: the severity words hidden, a faint wound
--             infection hidden (level 0.1), a heavy one shown (level 10), as vanilla rules
--   limb      every wound at once on the left forearm, then with a bandage, a splint and a poultice on top: the list
--             holds every word, the row is inside the tab, each tag fits the row's width, the row is as tall as its
--             wrapped tags; every ZeD window on screen (pictures hg_inj_limb_<w>x<h>, hg_inj_limb_care_<w>x<h>)
--   all 17    a wound on every part: "17 of 17 injured", 17 rows; the list scrolls when it is taller than the view
--             and the last row comes into view at the bottom; every ZeD window on screen (picture hg_inj_all17_<w>x<h>)
--   put back  every part exactly as found, the character alive, not infected, no new wound; no Lua error
-- Puts back: every part as found (every flag and clock: bandage and its type, splint and its item, stitches, fracture,
-- burn and its wash, bullet, glass, bite, infection, alcohol, poultices, health, stiffness, pain), the zombie
-- infection off as found, the pain stat, First Aid, ISHealthPanel.cheat, god mode, invincible, the game speed, the
-- figure's fold, the list's scroll, the windows and the tab; the figure's draw wrapper off. Nothing is given.
if not RT then print("ZEDQA hg_inj ERR rt_kit.lua did not run first"); print("ZEDQA hg_inj DONE"); return end
local Q = RT.make("hg_inj")
Q.maxMs = 1500000                    -- (the runner gives this script 1800 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, live = false, t0 = getTimestampMs(), rec = {}, held = {},
            base = {}, pbBad = {}, err0 = nil }
local Z = ZeD

S.DOC = 10                           -- First Aid for the list checks (every severity word shown)
S.WOUND_FNS = { "drawTextureScaledUniform" }
S.PARTS = {
    { bp = "Head", fig = "Head", sfx = "head" },
    { bp = "Neck", fig = "Neck", sfx = "neck" },
    { bp = "Torso_Upper", fig = "Upper Torso", sfx = "up-torso" },
    { bp = "Torso_Lower", fig = "Lower Torso", sfx = "low-torso" },
    { bp = "Groin", fig = "Groin", sfx = "groin" },
    { bp = "UpperArm_L", fig = "Left Upper Arm", sfx = "bicep-l" },
    { bp = "UpperArm_R", fig = "Right Upper Arm", sfx = "bicep-r" },
    { bp = "ForeArm_L", fig = "Left Forearm", sfx = "wrist-l" },
    { bp = "ForeArm_R", fig = "Right Forearm", sfx = "wrist-r" },
    { bp = "Hand_L", fig = "Left Hand", sfx = "hand-l" },
    { bp = "Hand_R", fig = "Right Hand", sfx = "hand-r" },
    { bp = "UpperLeg_L", fig = "Left Upper Leg", sfx = "thigh-l" },
    { bp = "UpperLeg_R", fig = "Right Upper Leg", sfx = "thigh-r" },
    { bp = "LowerLeg_L", fig = "Left Lower Leg", sfx = "ankle-l" },
    { bp = "LowerLeg_R", fig = "Right Lower Leg", sfx = "ankle-r" },
    { bp = "Foot_L", fig = "Left Foot", sfx = "foot-l" },
    { bp = "Foot_R", fig = "Right Foot", sfx = "foot-r" },
}
S.NO_SPLINT = { Head = true, Torso_Upper = true, Torso_Lower = true }   -- (HSplint:addToMenu, ISHealthPanel.lua:1556)

-- the states: apply on a clean part; has = the game took it; what the figure should show (mark, bleed, bandage,
-- fracture, splint, strain level; none = nothing drawn)
S.STATES = {
    { id = "scratch", mark = "scratch",
      apply = function(b) b:setScratched(true, false); b:setScratchTime(19) end, has = function(b) return b:scratched() end },
    { id = "laceration", mark = "cut",
      apply = function(b) b:setCut(true); b:setCutTime(16) end, has = function(b) return b:isCut() end },
    { id = "deep wound", mark = "deep",
      apply = function(b) b:generateDeepWound(); b:setDeepWoundTime(15) end, has = function(b) return b:deepWounded() end },
    { id = "bleeding", bleed = true,
      apply = function(b) b:setBleedingTime(10) end, has = function(b) return b:bleeding() end },
    { id = "bite", mark = "bite", bite = true,
      apply = function(b) b:SetBitten(true); b:SetInfected(false); b:SetFakeInfected(false); S.noInfection(S.bd()) end,
      has = function(b) return b:bitten() end },
    { id = "lodged bullet", mark = "bullet",
      apply = function(b) b:setHaveBullet(true, 0) end, has = function(b) return b:haveBullet() end },
    { id = "glass", mark = "glass",
      apply = function(b) b:generateDeepShardWound(); b:setDeepWoundTime(15) end, has = function(b) return b:haveGlass() end },
    { id = "burn", mark = "burn",
      apply = function(b) b:setBurnTime(50); b:setNeedBurnWash(false) end, has = function(b) return b:getBurnTime() > 0 end },
    { id = "burn needing a wash", mark = "burn",
      apply = function(b) b:setBurnTime(50); b:setNeedBurnWash(true) end, has = function(b) return b:isNeedBurnWash() end },
    { id = "fracture", fracture = true,
      apply = function(b) b:setFractureTime(30) end, has = function(b) return b:getFractureTime() > 0 end },
    { id = "wound infection", none = true,
      apply = function(b) b:setInfectedWound(true); b:setWoundInfectionLevel(10) end, has = function(b) return b:isInfectedWound() end },
    { id = "minor strain", strain = 1, none = true,
      apply = function(b) b:setStiffness(10) end, has = function(b) return b:getStiffness() >= 5 end },
    { id = "heavy strain", strain = 2, none = true,
      apply = function(b) b:setStiffness(40) end, has = function(b) return b:getStiffness() >= 20 end },
    { id = "pain", none = true,
      apply = function(b) b:setAdditionalPain(30) end, has = function(b) return b:getAdditionalPain() > 10 end },
    { id = "heavy pain", none = true,
      apply = function(b) b:setAdditionalPain(60) end, has = function(b) return b:getAdditionalPain() > 50 end },
    { id = "clean bandage", bandage = "clean",
      apply = function(b) S.bd():SetBandaged(b:getIndex(), true, 5, false, "Base.Bandage") end,
      has = function(b) return b:bandaged() and b:getBandageLife() > 0 end },
    { id = "dirty bandage", bandage = "dirty",
      apply = function(b) S.bd():SetBandaged(b:getIndex(), true, 0, false, "Base.BandageDirty") end,
      has = function(b) return b:bandaged() and b:getBandageLife() <= 0 end },
    { id = "stitches", mark = "stitch",
      apply = function(b) b:setStitched(true); b:setStitchTime(20) end, has = function(b) return b:stitched() end },
    { id = "splint on a fracture", splint = true, fracture = true, noSplintParts = true,
      apply = function(b) b:setFractureTime(30); b:setSplint(true, 2); b:setSplintItem("Base.Splint") end,
      has = function(b) return b:getSplintFactor() > 0 end },
    { id = "plantain poultice", none = true,
      apply = function(b) b:setPlantainFactor(5) end, has = function(b) return b:getPlantainFactor() > 0 end },
    { id = "comfrey poultice", none = true,
      apply = function(b) b:setComfreyFactor(5) end, has = function(b) return b:getComfreyFactor() > 0 end },
    { id = "garlic poultice", none = true,
      apply = function(b) b:setGarlicFactor(5) end, has = function(b) return b:getGarlicFactor() > 0 end },
}

-- what is read of a part and put back exactly: { field, getter }
S.GETS = { { "scratched", "scratched" }, { "scratchTime", "getScratchTime" }, { "cut", "isCut" }, { "cutTime", "getCutTime" },
           { "bleeding", "bleeding" }, { "bleedingTime", "getBleedingTime" }, { "deep", "deepWounded" },
           { "deepTime", "getDeepWoundTime" }, { "glass", "haveGlass" }, { "bullet", "haveBullet" },
           { "bandaged", "bandaged" }, { "bandageLife", "getBandageLife" }, { "bandageType", "getBandageType" },
           { "splint", "isSplint" }, { "splintFactor", "getSplintFactor" }, { "splintItem", "getSplintItem" },
           { "fractureTime", "getFractureTime" }, { "stitched", "stitched" }, { "stitchTime", "getStitchTime" },
           { "infectedWound", "isInfectedWound" }, { "woundInfection", "getWoundInfectionLevel" },
           { "burnTime", "getBurnTime" }, { "burnWash", "isNeedBurnWash" }, { "lastBurnWash", "getLastTimeBurnWash" },
           { "alcohol", "getAlcoholLevel" }, { "plantain", "getPlantainFactor" }, { "comfrey", "getComfreyFactor" },
           { "garlic", "getGarlicFactor" }, { "health", "getHealth" }, { "stiffness", "getStiffness" },
           { "addPain", "getAdditionalPain" }, { "bitten", "bitten" }, { "biteTime", "getBiteTime" },
           { "infected", "IsInfected" } }
-- the clocks and amounts put back after the flags: { setter, field }
S.SETS = { { "setScratchTime", "scratchTime" }, { "setCutTime", "cutTime" }, { "setDeepWoundTime", "deepTime" },
           { "setBleedingTime", "bleedingTime" }, { "setStitchTime", "stitchTime" }, { "setSplintFactor", "splintFactor" },
           { "setFractureTime", "fractureTime" }, { "setBandageLife", "bandageLife" },
           { "setWoundInfectionLevel", "woundInfection" }, { "setBurnTime", "burnTime" },
           { "setLastTimeBurnWash", "lastBurnWash" }, { "setAlcoholLevel", "alcohol" }, { "setPlantainFactor", "plantain" },
           { "setComfreyFactor", "comfrey" }, { "setGarlicFactor", "garlic" }, { "setBiteTime", "biteTime" },
           { "setStiffness", "stiffness" }, { "setAdditionalPain", "addPain" }, { "SetHealth", "health" } }

-- ===================================================================== small helpers
function S.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function S.bd() local b = nil; pcall(function() b = S.p:getBodyDamage() end); return b end
function S.part(name)
    local bd, t = S.bd(), BodyPartType[name]
    if not (bd and t) then return nil end
    local bp = nil
    pcall(function() bp = bd:getBodyPart(t) end)
    return bp
end
function S.typeOf(bp) local s = nil; if bp then pcall(function() s = tostring(bp:getType()) end) end; return s end
function S.has(s, sub) return type(s) == "string" and string.find(s, sub, 1, true) ~= nil end
function S.n(v)
    local x = tonumber(v)
    if x == nil then return "?" end
    return tostring(math.floor(x * 10 + 0.5) / 10)
end
function S.near(a, b, e) return type(a) == "number" and type(b) == "number" and math.abs(a - b) <= (e or 0.002) end
function S.speed(n)
    if n == nil then return end
    local f = ZEDQA_SPEED or setGameSpeed
    if f then pcall(f, n) end
end
function S.gameSpeed() local v = nil; pcall(function() v = getGameSpeed() end); return v end
function S.doc() local v = nil; pcall(function() v = S.p:getPerkLevel(Perks.Doctor) end); return v end
function S.setDoc(n) if n ~= nil then pcall(function() S.p:setPerkLevelDebug(Perks.Doctor, n) end) end end
function S.stat(k)
    local v = nil
    if CharacterStat[k] then pcall(function() v = S.p:getStats():get(CharacterStat[k]) end) end
    return v
end
function S.setStat(k, v)
    if v ~= nil and CharacterStat[k] then pcall(function() S.p:getStats():set(CharacterStat[k], v) end) end
end
function S.screen()
    local w, h = 0, 0
    pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end)
    return math.floor(w), math.floor(h)
end
function S.sizeTag() local w, h = S.screen(); return w .. "x" .. h end
function S.cText(c) return c and string.format("%.2f,%.2f,%.2f", c.r or -1, c.g or -1, c.b or -1) or "none" end
function S.sameC(a, b) return a ~= nil and b ~= nil and S.near(a.r, b.r) and S.near(a.g, b.g) and S.near(a.b, b.b) end
function S.inList(list, x) for _, v in ipairs(list or {}) do if v == x then return true end end; return false end

-- ===================================================================== the body: read, clean, put back
function S.snap(bp)
    local f = {}
    if not bp then return f end
    for _, g in ipairs(S.GETS) do
        local m = g[2]
        pcall(function() f[g[1]] = bp[m](bp) end)
    end
    return f
end
-- what differs between two reads of a part ("field now (was x)"); a missing bandage type or splint item is ""
function S.snapDiff(a, b)
    local diff = {}
    for _, g in ipairs(S.GETS) do
        local k = g[1]
        local x, y = a[k], b[k]
        local same
        if type(x) == "number" and type(y) == "number" then same = math.abs(x - y) < ((k == "health") and 0.5 or 0.01)
        -- (a part with no bandage can keep the last bandage's type name in the game: the name counts only on a bandaged part)
        elseif k == "bandageType" and not a.bandaged and not b.bandaged then same = true
        elseif k == "bandageType" or k == "splintItem" then same = tostring(x or "") == tostring(y or "")
        else same = (x == y) end
        if not same then diff[#diff + 1] = k .. " " .. tostring(y) .. " (was " .. tostring(x) .. ")" end
    end
    return diff
end
-- a part healed of what this script put on it, then set as found. The bullet comes out first (the game's
-- setHaveBullet(false) leaves a deep wound, which the flags below take down), the gauze off only where there is gauze
-- (BodyPart.setBandaged(false) raises each wound whose clock still runs and resets the poultices), a bite taken off
-- with its infection (the game's SetBitten(false) infects the part: bx_health's finding, Nov 21 2026), the stitches
-- before the deep wound (setStitched(false) on a fresh stitch reopens it).
function S.restore(bp, f)
    if not (bp and f) then return end
    local yes = false
    pcall(function() yes = bp:haveBullet() end)
    if yes then pcall(function() bp:setHaveBullet(false, 0) end) end
    yes = false
    pcall(function() yes = bp:bandaged() end)
    if yes then pcall(function() bp:setBandaged(false, 0) end) end
    yes = false
    pcall(function() yes = bp:bitten() end)
    if yes and not f.bitten then
        pcall(function() bp:SetBitten(false) end)
        pcall(function() bp:SetInfected(false) end)
        pcall(function() bp:SetFakeInfected(false) end)
    end
    pcall(function() bp:setStitched(false) end)
    pcall(function() bp:setSplint(false, 0) end)
    pcall(function() bp:setDeepWounded(false) end)
    pcall(function() bp:setHaveGlass(false) end)
    pcall(function() bp:setScratched(false, true) end)
    pcall(function() bp:setCut(false) end)
    pcall(function() bp:setBleeding(false) end)
    pcall(function() bp:setInfectedWound(false) end)
    pcall(function() bp:setNeedBurnWash(false) end)
    if not f.infected then pcall(function() bp:SetInfected(false) end) end
    if f.scratched then pcall(function() bp:setScratched(true, true) end) end
    if f.cut then pcall(function() bp:setCut(true) end) end
    if f.deep then pcall(function() bp:setDeepWounded(true) end) end
    if f.glass then pcall(function() bp:setHaveGlass(true) end) end
    if f.bullet then pcall(function() bp:setHaveBullet(true, 0) end) end
    if f.bitten then pcall(function() bp:SetBitten(true) end) end
    if f.bleeding then pcall(function() bp:setBleeding(true) end) end
    if f.stitched then pcall(function() bp:setStitched(true) end) end
    if f.splint then
        pcall(function() bp:setSplint(true, f.splintFactor or 0) end)
    end
    -- (the splint's item is kept apart from the splint itself: put back as found, nil too)
    pcall(function() bp:setSplintItem(f.splintItem) end)
    if f.infectedWound then pcall(function() bp:setInfectedWound(true) end) end
    if f.burnWash then pcall(function() bp:setNeedBurnWash(true) end) end
    -- (the body's SetBandaged, as ISApplyBandage does: the part's own setBandaged leaves the bandage type out)
    if f.bandaged then pcall(function() S.bd():SetBandaged(bp:getIndex(), true, f.bandageLife or 0, false, f.bandageType) end) end
    for _, s in ipairs(S.SETS) do
        local v, m = f[s[2]], s[1]
        if type(v) == "number" then pcall(function() bp[m](bp, v) end) end
    end
end
-- the clean part every state is staged on: nothing on it, health 100, no strain, no pain
S.CLEAN = { scratched = false, scratchTime = 0, cut = false, cutTime = 0, bleeding = false, bleedingTime = 0, deep = false,
            deepTime = 0, glass = false, bullet = false, bandaged = false, bandageLife = 0, splint = false, splintFactor = 0,
            fractureTime = 0, stitched = false, stitchTime = 0, infectedWound = false, woundInfection = 0, burnTime = 0,
            burnWash = false, alcohol = 0, plantain = 0, comfrey = 0, garlic = 0, health = 100, stiffness = 0,
            addPain = 0, bitten = false, biteTime = 0, infected = false }
-- what of a read is not clean (only the fields S.CLEAN names: the last burn wash and the item names are left as found)
function S.cleanDiff(f)
    local out = {}
    for k, v in pairs(S.CLEAN) do
        local x = f[k]
        local same
        if type(v) == "number" and type(x) == "number" then same = math.abs(v - x) < ((k == "health") and 0.5 or 0.01)
        else same = (v == x) end
        if not same then out[#out + 1] = k .. " " .. tostring(x) end
    end
    return out
end
-- the zombie infection off the body and every part (bx_health's way)
function S.noInfection(bd)
    if not bd then return end
    local parts = bd:getBodyParts()
    for i = 0, parts:size() - 1 do
        local b = parts:get(i)
        if b:IsInfected() then b:SetInfected(false) end
        if b:IsFakeInfected() then b:SetFakeInfected(false) end
    end
    if bd:isInfected() then bd:setInfected(false) end
    if bd:isIsFakeInfected() then bd:setIsFakeInfected(false) end
    local st = S.p:getStats()
    if st:get(CharacterStat.ZOMBIE_INFECTION) > 0 then st:set(CharacterStat.ZOMBIE_INFECTION, 0) end
    if st:get(CharacterStat.ZOMBIE_FEVER) > 0 then st:set(CharacterStat.ZOMBIE_FEVER, 0) end
    if bd:getInfectionTime() >= 0 then bd:setInfectionTime(-1) end
    if bd:getInfectionMortalityDuration() >= 0 then bd:setInfectionMortalityDuration(-1) end
end
function S.bail(why)
    if S.bailed then return end
    S.bailed = true
    S.dead = true
    Q.check(false, "the run went on to its end", "stopped, on to the put-back: " .. tostring(why))
    if Q.backAt and Q.qi < Q.backAt then Q.qi = Q.backAt; Q.wait = nil end
end
-- THE GUARD, on every game tick while god mode is off: no zombie infection, health under 75 topped up on every part
-- (the wounds stay), under 35 god mode ON and on to the put-back; a run that never reaches the put-back is put back here
function S.guard()
    local p, bd = S.p, S.bd()
    if not bd then return end
    if p:isDead() then
        if not S.deadSaid then
            S.deadSaid = true
            Q.check(false, "the character is alive", "DEAD during the run: restore the QA save from its backup")
            S.bail("the character died")
        end
        return
    end
    if S.found.zInf == false then S.noInfection(bd) end
    local h = bd:getOverallBodyHealth()
    if h < 75 then
        local parts = bd:getBodyParts()
        for i = 0, parts:size() - 1 do parts:get(i):SetHealth(100) end
        S.topUps = (S.topUps or 0) + 1
    end
    if h < 35 and not S.bailed then
        p:setGodMod(true)
        S.bail("health fell to " .. S.n(h) .. ": god mode ON")
    end
    if getTimestampMs() - S.t0 > Q.maxMs + 150000 then
        S.live = false
        pcall(S.putBack)
        Q.say("ERR the put-back did not come in time: the guard put the character back")
    end
end
function S.safety()
    if not S.live then return end
    local ok, err = pcall(S.guard)
    if not ok and not S.guardSaid then
        S.guardSaid = true
        Q.say("ERR the guard threw: " .. tostring(err))
        pcall(function() S.p:setGodMod(true) end)
        S.bail("the guard threw: god mode ON")
    end
end

-- ===================================================================== the oracle: vanilla's words for a part
-- Written from vanilla's ISHealthBodyPartListBox:doDrawItem (ISHealthPanel.lua:607-847): which lines show at the
-- doctor's First Aid and which severity word each carries. The words are the ones ZeD shows (vanilla's own keys,
-- except ZeD's Burn and Glass shards and the game's IGUI_health_Scratch). ISHealthPanel.cheat is off for the run.
function S.q(label, word) if word then return Z.tr("UI_ZeD_Health_Qualified", label, word) end; return label end
function S.expect(b, doc)
    local out = {}
    local band = b:bandaged()
    local frT, spl = b:getFractureTime(), b:getSplintFactor()
    local w = nil
    if b:bitten() then out[#out + 1] = getText("IGUI_health_Bitten") end
    if b:bleeding() then out[#out + 1] = getText("IGUI_health_Bleeding") end
    if b:deepWounded() then
        w = nil
        if doc > 4 then
            local t = b:getDeepWoundTime()
            if t > 10 then w = getText("IGUI_health_Severe") elseif t > 8 then w = getText("IGUI_health_Moderate") end
        end
        out[#out + 1] = S.q(getText("IGUI_health_DeepWound"), w)
    end
    if b:isInfectedWound() and not band and (doc > 8 or b:getWoundInfectionLevel() * 10 >= (2.5 - doc)) then
        out[#out + 1] = getText("IGUI_health_Infected")
    end
    if frT > 0 and spl == 0 then
        w = nil
        if doc > 6 then
            if frT > 50 then w = getText("IGUI_health_Severe") elseif frT > 20 then w = getText("IGUI_health_Moderate") end
        end
        out[#out + 1] = S.q(getText("IGUI_health_Fracture"), w)
    end
    if b:haveBullet() and not band then out[#out + 1] = getText("IGUI_health_LodgedBullet") end
    if b:haveGlass() and not band then out[#out + 1] = Z.tr("UI_ZeD_Health_GlassShards") end
    if b:scratched() then
        w = nil
        if doc > 2 then
            local t = b:getScratchTime()
            if t > 17 then w = getText("IGUI_health_Severe") elseif t > 14 then w = getText("IGUI_health_Moderate") end
        end
        out[#out + 1] = S.q(getText("IGUI_health_Scratch"), w)
    end
    if b:isCut() then
        w = nil
        if doc > 2 then
            local t = b:getCutTime()
            if t > 17 then w = getText("IGUI_health_Severe") elseif t > 14 then w = getText("IGUI_health_Moderate") end
        end
        out[#out + 1] = S.q(getText("IGUI_health_Cut"), w)
    end
    if b:getBurnTime() > 0 and not band then
        w = nil
        if doc > 4 and b:isNeedBurnWash() then w = Z.tr("IGUI_health_NeedCleaning") end
        out[#out + 1] = S.q(Z.tr("UI_ZeD_Health_Burn"), w)
    end
    local st = b:getStiffness()
    if st >= 5 then out[#out + 1] = getText(st < 20 and "IGUI_health_MinorStiffness" or "IGUI_health_Stiffness") end
    local pain = b:getAdditionalPain()
    if pain > 10 then out[#out + 1] = getText(pain > 50 and "IGUI_health_HeavyPain" or "IGUI_health_Pain") end
    if band then out[#out + 1] = getText(b:getBandageLife() > 0 and "IGUI_health_Bandaged" or "IGUI_health_DirtyBandage") end
    if b:stitched() then
        w = nil
        if doc > 6 then w = (b:getStitchTime() > 40) and getText("IGUI_health_Good") or Z.tr("IGUI_health_NeedTime") end
        out[#out + 1] = S.q(getText("IGUI_health_Stitched"), w)
    end
    if spl > 0 then
        w = nil
        if doc > 4 then
            if spl > 4 then w = getText("IGUI_health_Good") elseif frT > 2 then w = getText("IGUI_health_Moderate") end
        end
        out[#out + 1] = S.q(getText("IGUI_health_Splinted"), w)
    end
    if b:getPlantainFactor() > 0 then out[#out + 1] = getText("ContextMenu_PlantainCataplasm") end
    if b:getComfreyFactor() > 0 then out[#out + 1] = getText("ContextMenu_ComfreyCataplasm") end
    if b:getGarlicFactor() > 0 then out[#out + 1] = getText("ContextMenu_GarlicCataplasm") end
    return out
end
function S.sorted(list)
    local t = {}
    for _, s in ipairs(list or {}) do t[#t + 1] = tostring(s) end
    table.sort(t)
    return t
end
function S.sameSet(a, b)
    local x, y = S.sorted(a), S.sorted(b)
    if #x ~= #y then return false end
    for i = 1, #x do if x[i] ~= y[i] then return false end end
    return true
end
function S.isStrainWord(s) return s == getText("IGUI_health_MinorStiffness") or s == getText("IGUI_health_Stiffness") end
function S.rawKey(s)
    return type(s) == "string" and (s:find("IGUI_", 1, true) == 1 or s:find("UI_ZeD_", 1, true) == 1
        or s:find("ContextMenu_", 1, true) == 1)
end

-- ===================================================================== the Health tab's read
function S.cw() return RT.cw() end
function S.data() local w = RT.cw(); return w and w._healthCache or nil end
function S.entryOf(data, bpName)
    for _, e in ipairs(data and data.entries or {}) do
        if S.typeOf(e.bodyPart) == bpName then return e end
    end
    return nil
end
function S.labels(e)
    local t = {}
    for _, c in ipairs(e and e.conditions or {}) do t[#t + 1] = tostring(c.label) end
    return t
end
function S.figName(data, bpName, fallback)
    for fig, bp in pairs(data and data.partByFigure or {}) do
        if S.typeOf(bp) == bpName then return fig end
    end
    return fallback
end
-- ask the tab for a fresh read on its next draw (its clock: dueMs with no last time reads at once)
function S.refresh()
    local w = RT.cw()
    if not w then return end
    S.oldData = w._healthCache
    w._healthAt = nil
    w._healthFillAt = nil
end
function S.zoneOf(name)
    local w = RT.cw()
    for _, z in ipairs(w and w._healthInjuryZones or {}) do if z.bodyPartName == name then return z end end
    return nil
end

-- ===================================================================== the figure's draws
function S.texName(tex)
    if tex == nil then return nil end
    if type(tex) == "string" then return tex end
    local nm = nil
    pcall(function() nm = tex:getName() end)
    return nm and tostring(nm) or nil
end
function S.recAdd(R, fn, a1, a2, a3, a4, a5, a6, a7, a8, a9)
    local d = { fn = fn, name = S.texName(a1), x = tonumber(a2) or 0, y = tonumber(a3) or 0, s = a4 }
    R.list[#R.list + 1] = d
end
function S.recFn(R, fn, orig)
    return function(self, a1, a2, a3, a4, a5, a6, a7, a8, a9)
        pcall(S.recAdd, R, fn, a1, a2, a3, a4, a5, a6, a7, a8, a9)
        return orig(self, a1, a2, a3, a4, a5, a6, a7, a8, a9)
    end
end
function S.recOn(R, panel, fns)
    R.own, R.fns = {}, fns
    if type(panel) ~= "table" then return end
    for _, fn in ipairs(fns) do
        R.own[fn] = rawget(panel, fn) or false
        local orig = panel[fn]
        if orig then panel[fn] = S.recFn(R, fn, orig) end
    end
end
function S.recOff(R)
    local panel = R.panel
    if type(panel) ~= "table" then return end
    for _, fn in ipairs(R.fns or {}) do
        local o = R.own[fn]
        if o then panel[fn] = o else panel[fn] = nil end
    end
end
-- the figure's wounds pass wrapped: each call's draws recorded with the read the tab held at that moment
function S.wrapOn()
    if S.w0 then return end
    local F = ZeD_BodyFigure
    S.w0 = { wounds = F._drawWounds }
    local orig = S.w0.wounds
    F._drawWounds = function(self, panel, xOff, yOff, s)
        local R = { panel = panel, s = s, x = xOff, y = yOff, list = {} }
        local cw = RT.cw()
        R.data = cw and cw._healthCache or nil
        S.recOn(R, panel, S.WOUND_FNS)
        local ok, err = pcall(orig, self, panel, xOff, yOff, s)
        S.recOff(R)
        S.rec[self] = R
        if not ok then error(err, 0) end
    end
end
function S.wrapOff()
    if not S.w0 then return end
    ZeD_BodyFigure._drawWounds = S.w0.wounds
    S.wBack = S.w0.wounds
    S.w0 = nil
end
function S.fig() local w = RT.cw(); return w and w._healthBodyFigure or nil end
function S.drawsNamed(R, sub)
    local out = {}
    for _, d in ipairs(R and R.list or {}) do if S.has(d.name, sub) then out[#out + 1] = d end end
    return out
end
function S.rectOf(fig, name)
    local rs = nil
    if fig then pcall(function() rs = fig:getPartRects() end) end
    for _, r in ipairs(rs or {}) do if r.name == name then return r end end
    return nil
end
-- a mark's picture (15 x 15 art px, its middle at 7, 7) with its middle inside the part's rect
function S.markIn(R, sub, rect, slack)
    if not (R and rect) then return false end
    local c = 7 * (tonumber(R.s) or 1)
    slack = slack or 1
    for _, d in ipairs(S.drawsNamed(R, sub)) do
        local cx, cy = d.x + c, d.y + c
        if cx >= rect.x - slack and cx <= rect.x + rect.w + slack and cy >= rect.y - slack and cy <= rect.y + rect.h + slack then
            return true
        end
    end
    return false
end
function S.wText(w)
    if not w then return "nothing" end
    local t = {}
    if w.bandage then t[#t + 1] = "bandage " .. tostring(w.bandage) end
    if w.splint then t[#t + 1] = "splint" end
    if w.fracture then t[#t + 1] = "fracture" end
    if w.marks then t[#t + 1] = "marks " .. table.concat(w.marks, "+") end
    if w.bleed then t[#t + 1] = "bleed" end
    if w.infected then t[#t + 1] = "infected" end
    return #t > 0 and table.concat(t, ", ") or "empty"
end

-- ===================================================================== windows and pictures
function S.hold(w)
    if not w then return end
    for _, h in ipairs(S.held) do if h.w == w then return end end
    S.held[#S.held + 1] = { w = w, own = rawget(w, "pointerOn") }
    w.pointerOn = function() return true end
end
function S.unholdAll()
    for _, h in ipairs(S.held) do h.w.pointerOn = h.own end
    S.held = {}
end
function S.park(on)
    if on then
        if not S.parked then
            S.parked = { mx = getMouseX, my = getMouseY }
            getMouseX = function() return -9000 end
            getMouseY = function() return -9000 end
        end
        pcall(function() Mouse.setCursorVisible(false) end)
        return
    end
    if S.parked then
        getMouseX, getMouseY = S.parked.mx, S.parked.my
        S.parked = nil
        pcall(function() Mouse.setCursorVisible(true) end)
    end
end
function S.shot(name, what)
    Q.step(1, function() if not S.dead then S.park(true) end end)
    Q.step(4, function()
        if S.dead then S.park(false); return end
        local file = name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then Q.say("NOTE picture Zomboid/Screenshots/" .. file .. " | " .. what)
        else Q.say("NOTE the picture " .. name .. " was not taken: " .. tostring(e)) end
        S.park(false)
    end)
    Q.waitMs(1500)
end
function S.until1(n, max, cond, fn)
    Q.waitFor(n, max, function() return S.dead or cond() end, function(ok) if not S.dead then fn(ok) end end)
end

-- ===================================================================== one state on one part
-- is the tab's read new since the staging, with the oracle's words on the part, and the figure drawn from that read?
function S.ready(P, ST)
    local w = RT.cw()
    local d = w and w._healthCache
    if not d or d == S.oldData then return false end
    local bp = S.part(P.bp)
    if not bp then return true end
    if not S.sameSet(S.labels(S.entryOf(d, P.bp)), S.expect(bp, S.doc() or 0)) then return false end
    local fig = S.fig()
    local R = fig and S.rec[fig]
    return R ~= nil and R.data == d
end
-- (a) the list: what the row names, against the oracle, and its row drawn
function S.listProblems(P, d, bp, doc)
    local bad = {}
    local e = S.entryOf(d, P.bp)
    local want = S.expect(bp, doc)
    local got = S.labels(e)
    if not S.sameSet(got, want) then
        bad[#bad + 1] = "list says [" .. table.concat(got, ", ") .. "], vanilla's rule [" .. table.concat(want, ", ") .. "]"
    end
    for _, s in ipairs(got) do
        if S.rawKey(s) then bad[#bad + 1] = "raw key " .. s end
    end
    if e and not S.zoneOf(e.name) then bad[#bad + 1] = "no row drawn for " .. tostring(e.name) end
    if not e and #want > 0 then bad[#bad + 1] = "the part is not listed" end
    return bad, got
end
-- (b) the figure: its colour, the wounds it holds, what it drew on the part
function S.figProblems(P, ST, d)
    local bad = {}
    local HT = Z.HealthTab
    local fig = S.fig()
    local fn = S.figName(d, P.bp, P.fig)
    if not fig then bad[1] = "no figure"; return bad end
    local hp = d.partHealth and d.partHealth[fn] or nil
    local c = fig.colorMap and fig.colorMap[fn] or nil
    local want = nil
    if ST.strain then want = HT.strainColor(ST.strain) elseif hp then want = HT.healthColor(hp) end
    local okF, fc = pcall(HT.figureColor, d, fn, hp or 100)
    if not (S.sameC(c, want) and okF and S.sameC(fc, want)) then
        bad[#bad + 1] = "colour " .. S.cText(c) .. ", want " .. S.cText(want) .. " (figureColor " .. (okF and S.cText(fc) or tostring(fc)) .. ")"
    end
    local wd = d.woundsByFigure and d.woundsByFigure[fn] or nil
    local wf = fig.wounds and fig.wounds[fn] or nil
    if S.wText(wf) ~= S.wText(wd) then bad[#bad + 1] = "the figure holds " .. S.wText(wf) .. ", the read " .. S.wText(wd) end
    if ST.mark and not (wd and S.inList(wd.marks, ST.mark)) then bad[#bad + 1] = "no " .. ST.mark .. " mark read (" .. S.wText(wd) .. ")" end
    if ST.bleed and not (wd and wd.bleed) then bad[#bad + 1] = "no bleed read" end
    if ST.bandage and not (wd and wd.bandage == ST.bandage) then bad[#bad + 1] = "bandage read " .. S.wText(wd) end
    if ST.fracture and not (wd and wd.fracture) then bad[#bad + 1] = "no fracture read" end
    if ST.splint and not (wd and wd.splint) then bad[#bad + 1] = "no splint read" end
    if ST.none and wd ~= nil then bad[#bad + 1] = "something read where nothing draws: " .. S.wText(wd) end
    -- what it drew this frame
    local R = S.rec[fig]
    local rect = S.rectOf(fig, fn)
    local sx = "-" .. P.sfx .. "-"
    if not R then bad[#bad + 1] = "no wounds pass drawn"; return bad end
    if not rect then bad[#bad + 1] = "no rect for " .. tostring(fn) end
    if ST.mark and not S.markIn(R, "mark-" .. ST.mark .. ".png", rect) then bad[#bad + 1] = "mark-" .. ST.mark .. " not drawn on the part" end
    if ST.bleed and #S.drawsNamed(R, "mark-bleed.png") == 0 then bad[#bad + 1] = "no blood drawn" end
    if ST.bandage then
        local pic = (ST.bandage == "dirty") and "bandage-dirty.png" or "bandage.png"
        if #S.drawsNamed(R, sx .. pic) == 0 then bad[#bad + 1] = "no " .. pic .. " drawn" end
    end
    if ST.fracture and #S.drawsNamed(R, sx .. "fracture.png") == 0 then bad[#bad + 1] = "no fracture picture drawn" end
    if ST.splint and #S.drawsNamed(R, sx .. "splint.png") == 0 then bad[#bad + 1] = "no splint picture drawn" end
    if ST.none and #R.list > 0 then bad[#bad + 1] = #R.list .. " pictures drawn where nothing should be" end
    return bad
end
-- (c) the summary's counts and its line
function S.sumProblems(d, got)
    local bad = {}
    local HT = Z.HealthTab
    local wounded, strained = 0, 0
    for _, s in ipairs(got) do
        if S.isStrainWord(s) then strained = 1 else wounded = 1 end
    end
    if d.woundedCount ~= wounded or (d.strainedCount or 0) ~= strained then
        bad[#bad + 1] = "counts wounded " .. tostring(d.woundedCount) .. " strained " .. tostring(d.strainedCount)
            .. ", want " .. wounded .. " and " .. strained
    end
    local okL, lines = pcall(HT.summaryLines, d)
    local text = (okL and type(lines) == "table" and lines[1]) and tostring(lines[1].text) or tostring(lines)
    local want
    if wounded > 0 then want = Z.tr("UI_ZeD_Health_InjuredOf", wounded, d.totalParts)
    elseif strained > 0 then want = Z.tr("UI_ZeD_Health_NoInjuriesStrain", getText("IGUI_health_Stiffness"), strained)
    else want = nil end
    if want and text ~= want then bad[#bad + 1] = "summary \"" .. text .. "\", want \"" .. want .. "\"" end
    return bad
end
-- one combination: stage, wait for the read and the draw, check, put back
function S.combo(P, ST, doc, lab)
    local t = {}
    Q.step(1, function()
        if S.dead then return end
        local bp = S.part(P.bp)
        S.restore(bp, S.base[P.bp] or S.CLEAN)
        local ok, err = pcall(ST.apply, bp)
        local took = false
        if ok then pcall(function() took = ST.has(bp) end) end
        if not (ok and took) then
            t.off = true
            Q.skip(lab .. ": " .. ST.id .. " on " .. P.bp, "the game did not take it: " .. tostring(err))
            S.restore(bp, S.base[P.bp] or S.CLEAN)
            return
        end
        S.refresh()
    end)
    S.until1(2, 180, function() return t.off or S.ready(P, ST) end, function(ok)
        if t.off then return end
        local bp = S.part(P.bp)
        local d = S.data()
        local why = {}
        if not ok then why[1] = "the tab did not read it within 180 frames" end
        local lb, got = S.listProblems(P, d, bp, doc)
        for _, x in ipairs(lb) do why[#why + 1] = x end
        if d then
            for _, x in ipairs(S.figProblems(P, ST, d)) do why[#why + 1] = x end
            for _, x in ipairs(S.sumProblems(d, got)) do why[#why + 1] = x end
        end
        Q.check(#why == 0, lab .. ": " .. ST.id .. " on " .. P.bp .. ": the list, the figure and the summary",
            #why == 0 and table.concat(got, ", ") or table.concat(why, "; "))
        -- put back at once, read at once
        local base = S.base[P.bp] or S.CLEAN
        S.restore(bp, base)
        for _, x in ipairs(S.snapDiff(base, S.snap(bp))) do S.pbBad[#S.pbBad + 1] = P.bp .. " " .. x end
    end)
end
function S.stateDone(ST, lab)
    Q.step(1, function()
        if S.dead then return end
        local e1 = S.errN()
        Q.check(S.e0 == nil or e1 == nil or e1 == S.e0, lab .. ": " .. ST.id .. ": no Lua error over its parts",
            (S.e0 and e1) and ((e1 - S.e0) .. " new") or "the count cannot be read")
        S.e0 = e1
        Q.check(#S.pbBad == 0, lab .. ": " .. ST.id .. ": every part put back exactly",
            #S.pbBad == 0 and "clean" or table.concat(S.pbBad, "; "))
        S.pbBad = {}
    end)
end

-- ===================================================================== start
function S.start()
    S.err0 = S.errN()
    S.e0 = S.err0
    local HT = Z.HealthTab
    local F = ZeD_BodyFigure
    local ready = HT ~= nil and HT.gatherData ~= nil and HT.summaryLines ~= nil and HT.figureColor ~= nil
        and HT.healthColor ~= nil and HT.strainColor ~= nil and F ~= nil and F._drawWounds ~= nil and S.bd() ~= nil
    if not Q.check(ready, "the Health tab, its summary, figureColor and the body figure are loaded") then
        S.dead = true
        return
    end
    local f = S.found
    f.pair = RT.isOpen()
    local w = RT.cw()
    f.tab = w and w._activeTab or nil
    f.god = S.p:isGodMod()
    pcall(function() f.inv = S.p:isInvincible() end)
    f.speed = S.gameSpeed()
    f.cheat = ISHealthPanel and ISHealthPanel.cheat
    f.doc = S.doc()
    f.pain = S.stat("PAIN")
    local bd = S.bd()
    f.zInf = false
    pcall(function() f.zInf = bd:isInfected() end)
    f.parts = {}
    for _, P in ipairs(S.PARTS) do f.parts[P.bp] = S.snap(S.part(P.bp)) end
    f.recorded = true
    S.back.on = true
    Q.say("found: First Aid " .. tostring(f.doc) .. ", god " .. tostring(f.god) .. ", speed " .. tostring(f.speed)
        .. ", cheat " .. tostring(f.cheat) .. ", infected " .. tostring(f.zInf) .. ", screen " .. S.sizeTag()
        .. ", UI scale " .. tostring(Z.T and Z.T.scale))
    -- the run's state: speed 1, the guard before god mode goes off, the cheat off, First Aid 10, every part clean
    S.speed(1)
    S.live = true
    Events.OnTick.Add(S.safety)
    pcall(function() S.p:setInvincible(true) end)
    pcall(function() S.p:setGodMod(false) end)
    Q.check(S.p:isGodMod() == false, "god mode is off for the run (it heals a wound at once), the guard is on", "was " .. tostring(f.god))
    if ISHealthPanel then ISHealthPanel.cheat = false end
    S.setDoc(S.DOC)
    local dirty = {}
    for _, P in ipairs(S.PARTS) do
        local bp = S.part(P.bp)
        S.restore(bp, S.CLEAN)
        S.base[P.bp] = S.snap(bp)
        local d = S.cleanDiff(S.base[P.bp])
        if #d > 0 then dirty[#dirty + 1] = P.bp .. ": " .. table.concat(d, ", ") end
    end
    Q.check(#dirty == 0, "every part made clean for the run (each as found is kept)", #dirty == 0 and "17 parts" or table.concat(dirty, "; "))
    Q.check(S.doc() == S.DOC, "First Aid is " .. S.DOC .. " for the list checks", tostring(S.doc()))
    S.wrapOn()
    S.wKeep = S.w0.wounds
    RT.pairOpen()
end

-- ===================================================================== the run
function S.build()
    Q.step(10, S.start)
    S.until1(10, 180, function() local w = RT.cw(); return w ~= nil and w:isReallyVisible() and w._tabStripPanel ~= nil end, function(ok)
        local w = RT.cw()
        if w then
            if S.found.hfold == nil then S.found.hfold = w._healthFigureExpanded and true or false end
            w._healthFigureExpanded = true
            S.hold(w)
        end
        Q.check(ok and RT.charTab("health"), "the Character window opens on the Health tab")
    end)
    S.until1(5, 300, function()
        local w = RT.cw()
        local d = w and w._healthCache
        return w ~= nil and w._activeTab == "health" and d ~= nil and d.woundedCount == 0 and (d.strainedCount or 0) == 0
    end, function(ok)
        local d = S.data()
        Q.check(ok, "the tab reads the clean body: nothing wounded, nothing strained",
            "wounded " .. tostring(d and d.woundedCount) .. ", strained " .. tostring(d and d.strainedCount))
    end)
    -- every state on every part
    for _, ST in ipairs(S.STATES) do
        for _, P in ipairs(S.PARTS) do
            if not (ST.noSplintParts and S.NO_SPLINT[P.bp]) then S.combo(P, ST, S.DOC, "inj") end
        end
        S.stateDone(ST, "inj")
    end
    Q.step(1, function()
        if S.dead then return end
        Q.say("NOTE splint on a fracture was not staged on the head or either torso part: the game never splints them (HSplint:addToMenu)")
    end)
    S.buildFirstAid0()
    S.buildLimb()
    S.buildAll17()
end

-- ===================================================================== First Aid 0: what vanilla hides
S.FA0 = {
    { part = "ForeArm_L", id = "scratch" }, { part = "ForeArm_L", id = "laceration" }, { part = "ForeArm_L", id = "deep wound" },
    { part = "ForeArm_L", id = "burn needing a wash" }, { part = "ForeArm_L", id = "stitches" },
    { part = "ForeArm_L", id = "wound infection" }, { part = "LowerLeg_L", id = "fracture" },
    { part = "LowerLeg_L", id = "splint on a fracture" },
}
-- a faint infection on a scratch: hidden at First Aid 0 (0.1 x 10 < 2.5), shown at 9+
S.FAINT = { id = "faint wound infection on a scratch", mark = "scratch",
    apply = function(b) b:setScratched(true, false); b:setScratchTime(15); b:setInfectedWound(true); b:setWoundInfectionLevel(0.1) end,
    has = function(b) return b:isInfectedWound() end }
function S.stateById(id) for _, ST in ipairs(S.STATES) do if ST.id == id then return ST end end; return nil end
function S.partById(bp) for _, P in ipairs(S.PARTS) do if P.bp == bp then return P end end; return nil end
function S.buildFirstAid0()
    Q.step(2, function() if not S.dead then S.setDoc(0) end end)
    Q.step(2, function()
        if S.dead then return end
        Q.check(S.doc() == 0, "first aid: First Aid is 0", tostring(S.doc()))
    end)
    for _, c in ipairs(S.FA0) do
        local ST, P = S.stateById(c.id), S.partById(c.part)
        if ST and P then S.combo(P, ST, 0, "first aid 0") end
    end
    S.combo(S.partById("ForeArm_L"), S.FAINT, 0, "first aid 0")
    Q.step(2, function() if not S.dead then S.setDoc(S.DOC) end end)
    S.combo(S.partById("ForeArm_L"), S.FAINT, S.DOC, "first aid 10")
    S.stateDone({ id = "the First Aid 0 set" }, "first aid")
end

-- ===================================================================== every state on one limb
S.LIMB = "ForeArm_L"
function S.limbWounds(b)
    b:setScratched(true, false); b:setScratchTime(19)
    b:setCut(true); b:setCutTime(16)
    b:generateDeepShardWound(); b:setDeepWoundTime(15)
    b:setHaveBullet(true, 0)
    b:setBleedingTime(10)
    b:setBurnTime(50); b:setNeedBurnWash(true)
    b:setFractureTime(30)
    b:setInfectedWound(true); b:setWoundInfectionLevel(10)
    b:setStiffness(40)
    b:setAdditionalPain(30)
    b:SetBitten(true); b:SetInfected(false); b:SetFakeInfected(false)
    S.noInfection(S.bd())
end
function S.limbCare(b)
    b:setStitched(true); b:setStitchTime(20)
    b:setSplint(true, 2); b:setSplintItem("Base.Splint")
    b:setPlantainFactor(5)
    S.bd():SetBandaged(b:getIndex(), true, 5, false, "Base.Bandage")
end
-- the row of a part: inside the tab's view, each tag no wider than the row, the row as tall as its wrapped tags
function S.rowFits(name, e)
    local bad = {}
    local w = RT.cw()
    local z = S.zoneOf(name)
    local view = w and w._healthView
    local HT, T = Z.HealthTab, Z.T
    if not (z and view and e) then bad[1] = "no row or view"; return bad end
    if z.x < view.x - 1 or z.x + z.w > view.x + view.w + 1 then
        bad[#bad + 1] = string.format("row %d..%d outside the view %d..%d", math.floor(z.x), math.floor(z.x + z.w),
            math.floor(view.x), math.floor(view.x + view.w))
    end
    local bodyH = Z.TM:getFontHeight(T.fontF2)
    local lay0 = HT.injuryRowLayout(bodyH, 0)
    local room = z.w - lay0.indent + HT.tagHang()
    for _, c in ipairs(e.conditions or {}) do
        local tw = HT.tagHang() + Z.TM:MeasureStringX(T.fontF1, Z.textCase(c.label))
        if tw > room + 1 then bad[#bad + 1] = "tag \"" .. tostring(c.label) .. "\" " .. math.floor(tw) .. " wide, room " .. math.floor(room) end
    end
    local tagsH = HT._measureBadgeRows(e.conditions, z.w - lay0.indent, HT.tagHang())
    local want = HT.injuryRowLayout(bodyH, tagsH).h
    if z.h < want - 1 then bad[#bad + 1] = "row " .. math.floor(z.h) .. " tall, its tags need " .. math.floor(want) end
    return bad
end
function S.limbCheck(lab, ok)
    local bp = S.part(S.LIMB)
    local d = S.data()
    local e = S.entryOf(d, S.LIMB)
    local want = bp and S.expect(bp, S.DOC) or {}
    local got = S.labels(e)
    Q.check(ok and S.sameSet(got, want), lab .. ": the list holds every word vanilla's rule shows (" .. #want .. ")",
        "list [" .. table.concat(got, ", ") .. "], rule [" .. table.concat(want, ", ") .. "]")
    local bad = S.rowFits(e and e.name, e)
    Q.check(#bad == 0, lab .. ": the row is inside the tab, each tag fits, the row is as tall as its tags",
        #bad == 0 and (#got .. " tags") or table.concat(bad, "; "))
    RT.bounds(Q, lab)
end
function S.buildLimb()
    local t = {}
    Q.step(2, function()
        if S.dead then return end
        local bp = S.part(S.LIMB)
        S.restore(bp, S.base[S.LIMB])
        t.ok = pcall(S.limbWounds, bp)
        if not t.ok then Q.check(false, "limb: every wound staged on the left forearm") end
        S.refresh()
    end)
    S.until1(2, 240, function()
        local d = S.data()
        local bp = S.part(S.LIMB)
        return d ~= nil and d ~= S.oldData and bp ~= nil and S.sameSet(S.labels(S.entryOf(d, S.LIMB)), S.expect(bp, S.DOC))
    end, function(ok) S.limbCheck("limb, every wound", ok) end)
    S.shot("hg_inj_limb_" .. S.sizeTag(), "the Health tab with every wound on the left forearm")
    Q.step(2, function()
        if S.dead then return end
        local okC = pcall(S.limbCare, S.part(S.LIMB))
        if not okC then Q.check(false, "limb: the care staged on top") end
        S.refresh()
    end)
    S.until1(2, 240, function()
        local d = S.data()
        local bp = S.part(S.LIMB)
        return d ~= nil and d ~= S.oldData and bp ~= nil and S.sameSet(S.labels(S.entryOf(d, S.LIMB)), S.expect(bp, S.DOC))
    end, function(ok) S.limbCheck("limb, stitches, a splint and a poultice, then a bandage over them", ok) end)
    S.shot("hg_inj_limb_care_" .. S.sizeTag(), "the Health tab with every wound and its care on the left forearm")
    Q.step(1, function()
        if S.dead then return end
        local bp = S.part(S.LIMB)
        S.restore(bp, S.base[S.LIMB])
        for _, x in ipairs(S.snapDiff(S.base[S.LIMB], S.snap(bp))) do S.pbBad[#S.pbBad + 1] = S.LIMB .. " " .. x end
    end)
    S.stateDone({ id = "every state on one limb" }, "limb")
end

-- ===================================================================== a wound on every part
-- (only wounds that stay put while the picture is taken: a lone stitch or a lone wound infection can be cleared by
-- the game within frames, and the run of Nov 23 2026 pictured "16 of 17 injured")
S.ALL17 = { "scratch", "laceration", "burn", "fracture", "lodged bullet", "deep wound", "deep wound", "glass",
            "burn needing a wash", "scratch", "laceration", "fracture", "burn", "glass", "scratch", "laceration", "bite" }
function S.buildAll17()
    Q.step(2, function()
        if S.dead then return end
        local miss = {}
        for i, P in ipairs(S.PARTS) do
            local ST = S.stateById(S.ALL17[i])
            local bp = S.part(P.bp)
            S.restore(bp, S.base[P.bp])
            if not (ST and pcall(ST.apply, bp)) then miss[#miss + 1] = P.bp end
        end
        if #miss > 0 then Q.check(false, "all 17: a wound staged on every part", "not taken: " .. table.concat(miss, ", ")) end
        S.refresh()
    end)
    S.until1(2, 240, function()
        local d = S.data()
        return d ~= nil and d ~= S.oldData and d.woundedCount == 17
    end, function(ok)
        local d = S.data()
        local w = RT.cw()
        local okL, lines = pcall(Z.HealthTab.summaryLines, d)
        local text = (okL and lines and lines[1]) and tostring(lines[1].text) or "?"
        local want = Z.tr("UI_ZeD_Health_InjuredOf", 17, 17)
        Q.check(ok and text == want and #(d and d.entries or {}) == 17,
            "all 17: the summary reads \"" .. want .. "\" and 17 parts are listed",
            "\"" .. text .. "\", " .. #(d and d.entries or {}) .. " listed, wounded " .. tostring(d and d.woundedCount))
        local zones = w and w._healthInjuryZones or {}
        Q.check(#zones == 17, "all 17: an injury row is drawn for each", #zones .. " rows")
        local view = w and w._healthView
        local sc = w and w._healthScroll
        local tall = (w and view and w._healthDrawnH or 0) > (view and view.h or 0) + 1
        Q.check(view ~= nil and sc ~= nil and (not tall or sc.visible == true),
            "all 17: the list scrolls when it is taller than the view",
            "drawn " .. tostring(w and w._healthDrawnH and math.floor(w._healthDrawnH)) .. ", view " .. tostring(view and math.floor(view.h))
            .. ", scroll bar " .. tostring(sc and sc.visible))
        S.tall = tall
        RT.bounds(Q, "all 17, top of the list")
    end)
    S.shot("hg_inj_all17_" .. S.sizeTag(), "the Health tab with a wound on every part (17 of 17 injured)")
    Q.step(2, function()
        if S.dead then return end
        local w = RT.cw()
        local sc = w and w._healthScroll
        if S.tall and sc then
            S.scrollWas = sc.scrollPos
            pcall(function() sc:setScrollPos(1) end)
        end
    end)
    Q.step(4, function()
        if S.dead then return end
        if not S.tall then Q.skip("all 17: the last row comes into view", "the list fits the view at this size"); return end
        local w = RT.cw()
        local view = w and w._healthView
        local zones = w and w._healthInjuryZones or {}
        local last = zones[#zones]
        -- (QA, Nov 23 2026: the fill blocks (Moodles, Fitness, Regularity, Strain) sit under the injury list, so at
        -- the very bottom the last injury row is above the view: it must not be below it, and a scroll to it shows it)
        Q.check(view ~= nil and last ~= nil and last.y + last.h <= view.y + view.h + 1,
            "all 17: scrolled to the bottom, the last injury row is not cut off below the content",
            last and string.format("row %d..%d, view %d..%d", math.floor(last.y), math.floor(last.y + last.h),
                math.floor(view.y), math.floor(view.y + view.h)) or "no row")
        RT.bounds(Q, "all 17, bottom of the list")
        local sc = w and w._healthScroll
        local span = (w and w._healthDrawnH or 0) - (view and view.h or 0)
        if sc and view and last and span > 0 then
            -- the row's place in the content (at the bottom the content is moved up by the whole span)
            local bottom = last.y + last.h - view.y + span
            S.rowPos = math.max(0, math.min(1, (bottom - view.h + 4) / span))
            pcall(function() sc:setScrollPos(S.rowPos) end)
        end
    end)
    Q.step(4, function()
        if S.dead or not S.tall then return end
        local w = RT.cw()
        local view = w and w._healthView
        local zones = w and w._healthInjuryZones or {}
        local last = zones[#zones]
        Q.check(view ~= nil and last ~= nil and last.y + last.h <= view.y + view.h + 1 and last.y >= view.y - 1,
            "all 17: scrolled to it, the last injury row comes into view",
            (last and view) and string.format("scroll %.2f; row %d..%d, view %d..%d", S.rowPos or -1, math.floor(last.y),
                math.floor(last.y + last.h), math.floor(view.y), math.floor(view.y + view.h)) or "no row")
        local sc = w and w._healthScroll
        if sc then pcall(function() sc:setScrollPos(S.scrollWas or 0) end) end
    end)
    Q.step(1, function()
        if S.dead then return end
        for _, P in ipairs(S.PARTS) do
            local bp = S.part(P.bp)
            S.restore(bp, S.base[P.bp])
            for _, x in ipairs(S.snapDiff(S.base[P.bp], S.snap(bp))) do S.pbBad[#S.pbBad + 1] = P.bp .. " " .. x end
        end
    end)
    S.stateDone({ id = "a wound on every part" }, "all 17")
end

-- ===================================================================== put back
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    S.park(false)
    S.wrapOff()
    S.unholdAll()
    local f = S.found
    for _, P in ipairs(S.PARTS) do S.restore(S.part(P.bp), f.parts[P.bp]) end
    local bd = S.bd()
    if bd and f.zInf == false then pcall(S.noInfection, bd) end
    S.setStat("PAIN", f.pain)
    S.setDoc(f.doc)
    if ISHealthPanel then ISHealthPanel.cheat = f.cheat end
    if S.bailed then pcall(function() S.p:setGodMod(true) end)
    else pcall(function() S.p:setGodMod(f.god and true or false) end) end
    if f.inv ~= nil then pcall(function() S.p:setInvincible(f.inv) end) end
    S.speed(f.speed)
    S.live = false
    pcall(function() Events.OnTick.Remove(S.safety) end)
    S.putDiff = {}
    for _, P in ipairs(S.PARTS) do
        for _, x in ipairs(S.snapDiff(f.parts[P.bp] or {}, S.snap(S.part(P.bp)))) do S.putDiff[#S.putDiff + 1] = P.bp .. " " .. x end
    end
    local w = RT.cw()
    if w and f.hfold ~= nil then w._healthFigureExpanded = f.hfold end
end
function S.buildPutBack()
    Q.mark()
    Q.step(5, function()
        if not S.back.on then return end
        S.putBack()
        Q.check(#S.putDiff == 0, "put back: every part exactly as found (every flag and clock, bandage, splint, stitches, fracture, burn, bullet, glass, bite, infection, poultices, health, stiffness, pain)",
            #S.putDiff == 0 and "17 parts" or table.concat(S.putDiff, "; "))
        if S.found.pair then RT.pairOpen() else RT.pairShut() end
    end)
    Q.waitFor(5, 120, function() return RT.isOpen() == (S.found.pair == true) end, function(ok)
        if S.found.pair and S.found.tab and S.found.tab ~= "health" then RT.charTab(S.found.tab) end
        Q.check(ok, "put back: the window pair " .. (S.found.pair and "open" or "shut") .. " as found")
    end)
    Q.step(20, function()
        local f = S.found
        local p = S.p
        if not f.recorded then
            Q.skip("put back", "nothing was staged (the modules were not loaded)")
            return
        end
        local w = RT.cw()
        if f.pair and f.tab then Q.check(w ~= nil and w._activeTab == f.tab, "put back: the Character window's tab", tostring(w and w._activeTab)) end
        Q.check(ZeD_BodyFigure._drawWounds == S.wKeep and #S.held == 0 and S.parked == nil,
            "put back: the figure's own wounds pass, no window held, the pointer the game's")
        Q.check(S.doc() == f.doc and (not ISHealthPanel or ISHealthPanel.cheat == f.cheat),
            "put back: First Aid and the debug cheat as found",
            "First Aid " .. tostring(S.doc()) .. ", cheat " .. tostring(ISHealthPanel and ISHealthPanel.cheat))
        if S.bailed then
            Q.check(p:isGodMod() == true, "put back: the run stopped early, so god mode is left ON", tostring(p:isGodMod()))
        else
            Q.check(p:isGodMod() == (f.god and true or false), "put back: god mode as found", tostring(f.god))
        end
        local bd = S.bd()
        local inf, hp = false, nil
        pcall(function() inf = bd:isInfected(); hp = bd:getOverallBodyHealth() end)
        Q.check(not p:isDead() and (inf == false or f.zInf == true),
            "put back: the character is alive and not infected",
            (p:isDead() and "DEAD; " or "") .. "health " .. S.n(hp) .. "; infected " .. tostring(inf)
            .. "; health top-ups " .. tostring(S.topUps or 0))
        local e1 = S.errN()
        if S.err0 and e1 then
            Q.check(e1 == S.err0, "the injury run ran with no Lua error", (e1 - S.err0) .. " new")
        else
            Q.skip("the injury run's Lua error count", "the game's Lua error count cannot be read here")
        end
    end)
end

S.build()
S.buildPutBack()
Q.start()
