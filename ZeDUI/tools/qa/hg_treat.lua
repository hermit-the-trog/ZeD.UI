-- ZeDUI/tools/qa/hg_treat.lua  (Nov 23 2026, QA; tag hg_trt): every treatment, through ZeD's own treatment menu, with
-- every item that qualifies. The director, Nov 23 2026: "Treat every injury with every type of bandage, every type of
-- treatment. Run the whole gamut. I don't want to get anybody killed because our mod doesn't work in the health panel."
-- Run after zedqa_prelude.lua and rt_kit.lua (hg.txt). grep "ZEDQA hg_trt".
--
-- How: a wound is staged on a clean part with the game's own setters; the items are given into a school bag in the
-- main inventory, and for the run the game's container list (ISInventoryPaneContextMenu.getContainers) answers that
-- bag alone for this character, so the menu offers exactly the items given and never the character's own (the game
-- then moves the item from the bag to the hands as it does from any bag). ZeD's part menu is opened the way a click
-- opens it (HealthTab._onPartClicked) with ISContextMenu.get answering a recorder (ZeD_DpadWheels' own recorder);
-- the game's option is picked by its handler (option.target.Type) and its item (the option's arguments) and run as a
-- click runs it (onSelect), and the game's real timed actions run at game speed x5. First Aid is 10 for the run.
-- Checks (each with the part and the item in its line):
--   bandage    HApplyBandage with every item whose BandagePower > 0 (Bandage, AlcoholBandage, RippedSheets,
--              AlcoholRippedSheets, DenimStrips, LeatherStrips, Bandaid and the four Dirty kinds), rotated so every one
--              of the 17 parts gets one: offered; the part bandaged with that item's type, life above 0 or 0 for a
--              Dirty kind; the item used; ZeD's list says Bandaged / Dirty Bandage (the whole row as vanilla's rule) and
--              the figure holds the gauze; then Remove Bandage offered (and no second Bandage), the gauze off, the
--              scratch listed again
--   disinfect  HDisinfect with AlcoholWipes, AlcoholedCottonBalls, Disinfectant and Whiskey (the fluid route: 40%
--              alcohol, more than 0.15 L): the part's alcohol level up, the item drained
--   poultice   HApplyPlantain / HApplyComfrey / HApplyGarlic: the factor above 0, the poultice used, the list names it;
--              a second poultice is not offered while one is on (vanilla's rule)
--   burn       HCleanBurn with every item of BandagePower 2 or more: the wash done, the item used, "Need Cleaning"
--              gone; Bandaid and a Dirty bandage alone offer no Clean Burn
--   stitch     HStitch with a SutureNeedle, Needle + Thread, and the tag-only needles and threads (Needle_Bone, _Brass,
--              _Forged with Thread_Aramid, Thread_Sinew, DentalFloss, FishingLine, PremiumFishingLine): stitched, the
--              thread used, the list and figure show the stitches; Remove Stitch takes them out. A tag-only pair the
--              game's menu does not offer is a SKIP with a NOTE (vanilla's HStitch:addToMenu looks the tags up by
--              name). Not offered with glass in the wound.
--   glass      HRemoveGlass with every removeglass tool (Tweezers, Tweezers_Forged, Forceps_Forged, SutureNeedleHolder,
--              Pliers, Multitool) and by hand: the glass out, the tool kept
--   bullet     HRemoveBullet with every removebullet tool: the bullet out, the tool kept; with no tool, not offered
--   splint     HSplint with a Splint, and Plank / TreeBranch2 / WoodenStick2 with RippedSheets on limbs: splinted with
--              that item, both used; Remove Splint gives the splint (and the sheets) back. Not offered on the head or
--              either torso part, nor on a stitched part.
--   nothing    with an empty bag ZeD's own line (KISS #29, HealthTab.sayNothingFits) names what is missing for a
--              scratch, a deep wound, a fracture and a bullet, and "nothing to treat" for a sound part; once through
--              the game's real menu. Glass with no tool: the game still offers Remove Glass by hand, so the line never
--              shows; what it would say is a NOTE.
--   card       the medical check card (a stand-in patient: his own body): each of three parts' menu from the card
--              is the Health tab's menu, the doctor is the character and the patient the stand-in (the actions are
--              not run: the game's timed actions turn the doctor to face a real patient)
--   put back   every part, the inventory (nothing left from the run, nothing of the character's used), First Aid and
--              its XP; no Lua error
-- Puts back: every part exactly as found, the zombie infection off as found, the pain, panic and stress stats, First
-- Aid level and XP, ISHealthPanel.cheat, god mode, invincible, the game speed, the container list, ISContextMenu.get,
-- the Health tab's sayNothingFits, the medical card closed, the figure's fold, the windows and the tab; the bag and
-- every item given or made by a treatment taken back.
if not RT then print("ZEDQA hg_trt ERR rt_kit.lua did not run first"); print("ZEDQA hg_trt DONE"); return end
local Q = RT.make("hg_trt")
Q.maxMs = 1500000                    -- (the runner gives this script 1800 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, live = false, t0 = getTimestampMs(), held = {}, base = {},
            ids0 = {}, pbBad = {} }
local Z = ZeD

S.DOC = 10
S.FAST = 2                           -- ZEDQA_SPEED 2: x5
S.PARTS = {
    { bp = "Head", fig = "Head" }, { bp = "Neck", fig = "Neck" }, { bp = "Torso_Upper", fig = "Upper Torso" },
    { bp = "Torso_Lower", fig = "Lower Torso" }, { bp = "Groin", fig = "Groin" },
    { bp = "UpperArm_L", fig = "Left Upper Arm" }, { bp = "UpperArm_R", fig = "Right Upper Arm" },
    { bp = "ForeArm_L", fig = "Left Forearm" }, { bp = "ForeArm_R", fig = "Right Forearm" },
    { bp = "Hand_L", fig = "Left Hand" }, { bp = "Hand_R", fig = "Right Hand" },
    { bp = "UpperLeg_L", fig = "Left Upper Leg" }, { bp = "UpperLeg_R", fig = "Right Upper Leg" },
    { bp = "LowerLeg_L", fig = "Left Lower Leg" }, { bp = "LowerLeg_R", fig = "Right Lower Leg" },
    { bp = "Foot_L", fig = "Left Foot" }, { bp = "Foot_R", fig = "Right Foot" },
}
-- every item with a BandagePower above 0 (media/scripts/generated/items/normal.txt, 42.22)
S.BANDAGES = { "Base.Bandage", "Base.AlcoholBandage", "Base.RippedSheets", "Base.AlcoholRippedSheets", "Base.DenimStrips",
               "Base.LeatherStrips", "Base.Bandaid", "Base.BandageDirty", "Base.RippedSheetsDirty", "Base.DenimStripsDirty",
               "Base.LeatherStripsDirty" }
-- BandagePower 2 or more: what may clean a burn (HCleanBurn:checkItem)
S.BURN_ITEMS = { "Base.Bandage", "Base.AlcoholBandage", "Base.RippedSheets", "Base.AlcoholRippedSheets", "Base.DenimStrips",
                 "Base.LeatherStrips" }
-- the removeglass / removebullet tools (their Tags in normal.txt and weapon.txt)
S.TOOLS = { "Base.Tweezers", "Base.Tweezers_Forged", "Base.Forceps_Forged", "Base.SutureNeedleHolder", "Base.Pliers",
            "Base.Multitool" }

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
    return tostring(math.floor(x * 100 + 0.5) / 100)
end
function S.speed(n)
    if n == nil then return end
    local f = ZEDQA_SPEED or setGameSpeed
    if f then pcall(f, n) end
end
function S.gameSpeed() local v = nil; pcall(function() v = getGameSpeed() end); return v end
function S.doc() local v = nil; pcall(function() v = S.p:getPerkLevel(Perks.Doctor) end); return v end
function S.setDoc(n) if n ~= nil then pcall(function() S.p:setPerkLevelDebug(Perks.Doctor, n) end) end end
function S.xp(perk) local v = nil; pcall(function() v = S.p:getXp():getXP(perk) end); return v end
-- a perk's XP put back: to its level's floor, then what it had over that
function S.putXp(perk, xp0, lvl0)
    if xp0 == nil or lvl0 == nil then return end
    pcall(function() S.p:getXp():setXPToLevel(perk, lvl0) end)
    local x = S.xp(perk)
    if x and xp0 > x + 0.001 then pcall(function() S.p:getXp():AddXPNoMultiplier(perk, xp0 - x) end) end
end
function S.stat(k)
    local v = nil
    if CharacterStat[k] then pcall(function() v = S.p:getStats():get(CharacterStat[k]) end) end
    return v
end
function S.setStat(k, v)
    if v ~= nil and CharacterStat[k] then pcall(function() S.p:getStats():set(CharacterStat[k], v) end) end
end
function S.inList(list, x) for _, v in ipairs(list or {}) do if v == x then return true end end; return false end
function S.partOf(bp) for _, P in ipairs(S.PARTS) do if P.bp == bp then return P end end; return nil end
function S.dispName(bpName) local s = nil; pcall(function() s = BodyPartType.getDisplayName(BodyPartType[bpName]) end); return tostring(s) end
function S.queued()
    local n = 0
    pcall(function()
        local q = ISTimedActionQueue.getTimedActionQueue(S.p)
        n = q and q.queue and #q.queue or 0
    end)
    return n
end
function S.clearQueue() pcall(function() ISTimedActionQueue.clear(S.p) end) end

-- ===================================================================== the body (hg_injury's read and put-back)
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
S.SETS = { { "setScratchTime", "scratchTime" }, { "setCutTime", "cutTime" }, { "setDeepWoundTime", "deepTime" },
           { "setBleedingTime", "bleedingTime" }, { "setStitchTime", "stitchTime" }, { "setSplintFactor", "splintFactor" },
           { "setFractureTime", "fractureTime" }, { "setBandageLife", "bandageLife" },
           { "setWoundInfectionLevel", "woundInfection" }, { "setBurnTime", "burnTime" },
           { "setLastTimeBurnWash", "lastBurnWash" }, { "setAlcoholLevel", "alcohol" }, { "setPlantainFactor", "plantain" },
           { "setComfreyFactor", "comfrey" }, { "setGarlicFactor", "garlic" }, { "setBiteTime", "biteTime" },
           { "setStiffness", "stiffness" }, { "setAdditionalPain", "addPain" }, { "SetHealth", "health" } }
S.CLEAN = { scratched = false, scratchTime = 0, cut = false, cutTime = 0, bleeding = false, bleedingTime = 0, deep = false,
            deepTime = 0, glass = false, bullet = false, bandaged = false, bandageLife = 0, splint = false, splintFactor = 0,
            fractureTime = 0, stitched = false, stitchTime = 0, infectedWound = false, woundInfection = 0, burnTime = 0,
            burnWash = false, alcohol = 0, plantain = 0, comfrey = 0, garlic = 0, health = 100, stiffness = 0,
            addPain = 0, bitten = false, biteTime = 0, infected = false }
function S.snap(bp)
    local f = {}
    if not bp then return f end
    for _, g in ipairs(S.GETS) do
        local m = g[2]
        pcall(function() f[g[1]] = bp[m](bp) end)
    end
    return f
end
function S.snapDiff(a, b)
    local diff = {}
    for _, g in ipairs(S.GETS) do
        local k = g[1]
        local x, y = a[k], b[k]
        local same
        if type(x) == "number" and type(y) == "number" then same = math.abs(x - y) < ((k == "health") and 0.5 or 0.01)
        elseif k == "bandageType" or k == "splintItem" then same = tostring(x or "") == tostring(y or "")
        else same = (x == y) end
        if not same then diff[#diff + 1] = k .. " " .. tostring(y) .. " (was " .. tostring(x) .. ")" end
    end
    return diff
end
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
        if f.splintItem then pcall(function() bp:setSplintItem(f.splintItem) end) end
    end
    if f.infectedWound then pcall(function() bp:setInfectedWound(true) end) end
    if f.burnWash then pcall(function() bp:setNeedBurnWash(true) end) end
    if f.bandaged then pcall(function() bp:setBandaged(true, f.bandageLife or 0, false, f.bandageType) end) end
    for _, s in ipairs(S.SETS) do
        local v, m = f[s[2]], s[1]
        if type(v) == "number" then pcall(function() bp[m](bp, v) end) end
    end
end
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
-- THE GUARD, on every game tick while god mode is off (vk8_wounds' and bx_health's): no zombie infection, health
-- under 75 topped up on every part, under 35 god mode ON and on to the put-back; a run that never reaches the
-- put-back is put back here
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

-- ===================================================================== the oracle (hg_injury's, from ISHealthPanel.lua:607-847)
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
function S.refresh()
    local w = RT.cw()
    if not w then return end
    S.oldData = w._healthCache
    w._healthAt = nil
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

-- ===================================================================== the bag, the items, the container list
-- the items in a container of one full type
function S.countIn(con, ft)
    local n = 0
    if not con then return 0 end
    pcall(function()
        local items = con:getItems()
        for i = 0, items:size() - 1 do if items:get(i):getFullType() == ft then n = n + 1 end end
    end)
    return n
end
function S.count(ft) return S.countIn(S.p:getInventory(), ft) + S.countIn(S.bagInv, ft) end
-- one item given into the bag (taken back at the end by rt_kit, or by the sweep)
function S.put(ft)
    local it = nil
    if S.bagInv then pcall(function() it = S.bagInv:AddItem(ft) end) end
    if it then
        pcall(function() it:getModData().ZeDQA_spawned = true end)
        RT.given[#RT.given + 1] = it
    else
        Q.say("NOTE " .. tostring(ft) .. " could not be given")
    end
    return it
end
function S.gone(it)
    if not it then return false end
    local c = nil
    pcall(function() c = it:getContainer() end)
    return c == nil
end
function S.amountOf(it)
    local v = nil
    if not it then return nil end
    -- (a fluid only where the item has the component, as vanilla's HDisinfect asks; else a drainable's uses)
    local fluid = false
    pcall(function() fluid = it:hasComponent(ComponentType.FluidContainer) end)
    if fluid then pcall(function() local fc = it:getFluidContainer(); if fc then v = fc:getAmount() end end) end
    if v == nil then pcall(function() if it:IsDrainable() then v = it:getCurrentUsesFloat() end end) end
    return v
end
-- every item in the main inventory that was not there at the start, and everything in the bag, taken out
function S.sweep()
    local inv = S.p:getInventory()
    local out = {}
    pcall(function()
        local items = inv:getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if it ~= S.bag and not S.ids0[it:getID()] then out[#out + 1] = it end
        end
    end)
    for _, it in ipairs(out) do
        pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
        pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
        pcall(function() inv:Remove(it) end)
    end
    local inBag = {}
    pcall(function()
        local items = S.bagInv:getItems()
        for i = 0, items:size() - 1 do inBag[#inBag + 1] = items:get(i) end
    end)
    for _, it in ipairs(inBag) do pcall(function() S.bagInv:Remove(it) end) end
    return #out + #inBag
end
-- for the run the game's container list answers the bag alone for this character
function S.isoOn()
    if S.gc0 then return end
    S.gc0 = ISInventoryPaneContextMenu.getContainers
    local orig = S.gc0
    ISInventoryPaneContextMenu.getContainers = function(character)
        if S.iso and S.bagInv and character == S.p then
            local l = ArrayList.new()
            l:add(S.bagInv)
            return l
        end
        return orig(character)
    end
end
function S.isoOff()
    S.iso = false
    if S.gc0 then ISInventoryPaneContextMenu.getContainers = S.gc0; S.gc0 = nil end
end

-- ===================================================================== ZeD's part menu, recorded
function S.recorder()
    local r = { options = {} }
    function r:addOption(name, target, onSelect, ...)
        local o = { name = name, target = target, onSelect = onSelect, n = select("#", ...), args = { ... } }
        self.options[#self.options + 1] = o
        return o
    end
    function r:addActionsOption(name, ...) return self:addOption(name, ...) end
    function r:getNew() return S.recorder() end
    function r:addSubMenu(option, child) option.sub = child end
    function r:isEmpty() return #self.options == 0 end
    function r:setVisible() end
    function r:getIsVisible() return false end
    return r
end
-- a stand-in for a character: every method call answered with the character's own (vk8_wounds' stand-in patient)
function S.proxyOf(pl, flag)
    local px = { [flag] = true }
    setmetatable(px, { __index = function(t, k)
        if type(k) ~= "string" then return nil end
        local m = nil
        pcall(function() m = pl[k] end)
        if m == nil then return nil end
        local f = function(self, ...) return m(pl, ...) end
        rawset(t, k, f)
        return f
    end })
    return px
end
-- ZeD's "nothing fits" line, recorded: the call goes to ZeD's own with a stand-in whose halo note is kept here (and
-- passed on to the character only for the one real-menu check)
function S.sayOn()
    if S.say0 then return end
    local HT = Z.HealthTab
    S.say0 = HT.sayNothingFits
    local orig = S.say0
    HT.sayNothingFits = function(patient, bp, pn)
        local px = S.proxyOf(patient, "_hgQaHalo")
        rawset(px, "setHaloNote", function(self, text) S.said = text end)
        local ok, err = pcall(orig, px, bp, pn)
        if S.passHalo and S.said then pcall(function() patient:setHaloNote(S.said) end) end
        if not ok then error(err, 0) end
    end
end
function S.sayOff()
    if S.say0 then Z.HealthTab.sayNothingFits = S.say0; S.sayBack = S.say0; S.say0 = nil end
end
-- ZeD's menu for a part, as a click opens it, recorded
function S.menuOf(fig)
    local w = RT.cw()
    local rec = S.recorder()
    local orig = ISContextMenu.get
    S.said = nil
    ISContextMenu.get = function() return rec end
    local ok, err = pcall(Z.HealthTab._onPartClicked, w, fig, w and w._healthContentPanel or nil, 10, 10)
    ISContextMenu.get = orig
    S.lastErr = (not ok) and tostring(err) or nil
    return rec
end
function S.leaves(rec, out)
    out = out or {}
    for _, o in ipairs(rec and rec.options or {}) do
        if o.sub then S.leaves(o.sub, out)
        elseif o.onSelect then out[#out + 1] = o end
    end
    return out
end
function S.kind(o) return type(o.target) == "table" and o.target.Type or nil end
function S.findOpt(rec, kind, a1, a2)
    for _, o in ipairs(S.leaves(rec)) do
        if S.kind(o) == kind and (a1 == nil or o.args[1] == a1) and (a2 == nil or o.args[2] == a2) then return o end
    end
    return nil
end
function S.hasKind(rec, kind) return S.findOpt(rec, kind) ~= nil end
function S.optText(o)
    local a = {}
    for i = 1, o.n or 0 do a[#a + 1] = tostring(o.args[i]) end
    return tostring(S.kind(o)) .. "(" .. table.concat(a, ",") .. ")"
end
function S.menuText(rec)
    local t = {}
    for _, o in ipairs(S.leaves(rec)) do t[#t + 1] = S.optText(o) end
    table.sort(t)
    return #t > 0 and table.concat(t, " ") or "an empty menu"
end
function S.run(o) return pcall(o.onSelect, o.target, unpack(o.args, 1, o.n)) end

-- ===================================================================== stages (the wound each treatment is for)
S.STAGE = {
    scratch = function(b) b:setScratched(true, false); b:setScratchTime(19) end,
    laceration = function(b) b:setCut(true); b:setCutTime(16) end,
    deep = function(b) b:generateDeepWound(); b:setDeepWoundTime(15) end,
    glass = function(b) b:generateDeepShardWound(); b:setDeepWoundTime(15) end,
    bullet = function(b) b:setHaveBullet(true, 0) end,
    burnwash = function(b) b:setBurnTime(50); b:setNeedBurnWash(true) end,
    fracture = function(b) b:setFractureTime(30) end,
    fracstitch = function(b) b:setFractureTime(30); b:setCut(true); b:setCutTime(16); b:setStitched(true); b:setStitchTime(20) end,
    healthy = function(b) end,
}
-- a part made clean, then staged; true when the game took it
function S.stageOn(bpName, stage)
    local bp = S.part(bpName)
    S.restore(bp, S.base[bpName] or S.CLEAN)
    local fn = S.STAGE[stage]
    local ok = fn ~= nil and pcall(fn, bp)
    return ok and true or false, bp
end
function S.putPart(bpName)
    local bp = S.part(bpName)
    local base = S.base[bpName] or S.CLEAN
    S.restore(bp, base)
    for _, x in ipairs(S.snapDiff(base, S.snap(bp))) do S.pbBad[#S.pbBad + 1] = bpName .. " " .. x end
end

-- ===================================================================== one treatment: offered, run, done, shown
-- U = { lab, part, stage, give = {ft...}, kind, a1, a2, useItem (ft whose given item is checked), used = "consumed" |
--       "drained" | "kept", done(b), result(b) -> ok, detail, figWant(w) -> problem or nil, remove = { kind, done(b),
--       back = ft returned }, tagOnly }
function S.tabReady(bpName, fig)
    local w = RT.cw()
    local d = w and w._healthCache
    if not d or d == S.oldData then return false end
    local bp = S.part(bpName)
    if not bp then return true end
    if not S.sameSet(S.labels(S.entryOf(d, bpName)), S.expect(bp, S.doc() or 0)) then return false end
    local f = w._healthBodyFigure
    local wd = d.woundsByFigure and d.woundsByFigure[fig] or nil
    return f ~= nil and S.wText(f.wounds and f.wounds[fig]) == S.wText(wd)
end
function S.tabCheck(lab, U, ok, figWant)
    local P = S.partOf(U.part)
    local bp = S.part(U.part)
    local d = S.data()
    local w = RT.cw()
    local f = w and w._healthBodyFigure
    local want = bp and S.expect(bp, S.doc() or 0) or {}
    local got = S.labels(S.entryOf(d, U.part))
    local bad = {}
    if not ok then bad[1] = "the tab did not catch up in 240 frames" end
    if not S.sameSet(got, want) then
        bad[#bad + 1] = "list [" .. table.concat(got, ", ") .. "], vanilla's rule [" .. table.concat(want, ", ") .. "]"
    end
    local wd = d and d.woundsByFigure and d.woundsByFigure[P.fig] or nil
    local wf = f and f.wounds and f.wounds[P.fig] or nil
    if S.wText(wf) ~= S.wText(wd) then bad[#bad + 1] = "the figure holds " .. S.wText(wf) .. ", the read " .. S.wText(wd) end
    if figWant then
        local why = figWant(wd)
        if why then bad[#bad + 1] = why end
    end
    Q.check(#bad == 0, lab .. ": ZeD's list and figure show it on " .. U.part,
        #bad == 0 and (table.concat(got, ", ") .. " | figure " .. S.wText(wd)) or table.concat(bad, "; "))
end
-- the game's work on a part is over: done with the queue empty, or the queue empty for 120 frames (the action refused)
function S.settled(t, bpName, done)
    local bp = S.part(bpName)
    local q = S.queued()
    if q > 0 then t.idle = 0 else t.idle = (t.idle or 0) + 1 end
    if q == 0 and bp ~= nil and done(bp) then t.idle = 0; return true end
    return t.idle > 120
end
function S.unit(U)
    local t = {}
    local lab = U.lab
    Q.step(1, function()
        if S.dead then t.off = true; return end
        S.sweep()
        S.clearQueue()
        local took, bp = S.stageOn(U.part, U.stage)
        if not took then
            t.off = true
            Q.skip(lab, "the wound was not staged on " .. U.part)
            return
        end
        t.items = {}
        for _, ft in ipairs(U.give or {}) do t.items[ft] = S.put(ft) end
        t.useIt = U.useItem and t.items[U.useItem] or nil
        t.amount0 = S.amountOf(t.useIt)
        local rec = S.menuOf(S.partOf(U.part).fig)
        local o = S.findOpt(rec, U.kind, U.a1, U.a2)
        if not o then
            t.off = true
            if U.tagOnly then
                Q.skip(lab .. ": offered", "the game's menu does not offer this pair: " .. (S.lastErr and ("error: " .. S.lastErr .. "; ") or "") .. S.menuText(rec))
                Q.say("NOTE " .. lab .. ": vanilla's HStitch:addToMenu finds a tag-only needle or thread with getItemOfTag(\"SewingNeedle\" / \"Thread\") (ISHealthPanel.lua:1382-1383); with only tag items given it found none. The menu is the game's own, not ZeD's")
            else
                Q.check(false, lab .. ": ZeD's menu offers it on " .. U.part, (S.lastErr and ("error: " .. S.lastErr .. "; ") or "") .. S.menuText(rec))
            end
            return
        end
        local ok, err = S.run(o)
        if not Q.check(ok, lab .. ": ZeD's menu offers it on " .. U.part .. " and the pick runs", ok and S.optText(o) or tostring(err)) then
            t.off = true
        end
    end)
    Q.waitFor(3, 1500, function()
        if t.off or S.dead then return true end
        return S.settled(t, U.part, U.done)
    end, function()
        if t.off or S.dead then return end
        local bp = S.part(U.part)
        local ok = bp ~= nil and S.queued() == 0 and U.done(bp)
        local bad = {}
        if not ok then bad[1] = "not done (queue " .. S.queued() .. ", idle " .. tostring(t.idle) .. " frames)" end
        local okR, detail = true, ""
        if U.result and bp then okR, detail = U.result(bp, t) end
        if not okR then bad[#bad + 1] = tostring(detail) end
        local used = "-"
        if U.used and t.useIt then
            local a1 = S.amountOf(t.useIt)
            local gone = S.gone(t.useIt)
            if U.used == "consumed" then
                if not gone then bad[#bad + 1] = U.useItem .. " still there (not used)" end
                used = gone and "used up" or "still there"
            elseif U.used == "drained" then
                local less = gone or (a1 ~= nil and t.amount0 ~= nil and a1 < t.amount0 - 0.0001)
                if not less then bad[#bad + 1] = U.useItem .. " not drained (" .. S.n(t.amount0) .. " to " .. S.n(a1) .. ")" end
                used = gone and "used up" or (S.n(t.amount0) .. " to " .. S.n(a1))
            elseif U.used == "kept" then
                if gone then bad[#bad + 1] = U.useItem .. " was used up (a tool is kept)" end
                used = gone and "gone" or "kept"
            end
        end
        if not ok then S.clearQueue() end
        t.done = ok
        Q.check(#bad == 0, lab .. ": the game's action finished on " .. U.part .. ", the part and the item as vanilla does",
            #bad == 0 and (tostring(detail) .. "; item " .. used) or table.concat(bad, "; "))
        S.refresh()
    end)
    Q.waitFor(2, 240, function()
        if t.off or S.dead or not t.done then return true end
        return S.tabReady(U.part, S.partOf(U.part).fig)
    end, function(ok)
        if t.off or S.dead or not t.done then return end
        S.tabCheck(lab, U, ok, U.figWant)
    end)
    if U.remove then S.removal(U, t) end
    Q.step(1, function()
        if S.dead then return end
        S.clearQueue()
        S.putPart(U.part)
        S.sweep()
    end)
end
-- the treatment taken off again through the same menu
function S.removal(U, t)
    local R = U.remove
    local lab = U.lab .. ", then " .. R.say
    Q.step(1, function()
        if t.off or S.dead or not t.done then return end
        for _, ft in ipairs(R.give or {}) do S.put(ft) end
        t.r0 = R.back and S.count(R.back) or nil
        local rec = S.menuOf(S.partOf(U.part).fig)
        local o = S.findOpt(rec, R.kind)
        local extra = R.notKind and S.hasKind(rec, R.notKind)
        if not o or extra then
            t.roff = true
            Q.check(false, lab .. ": ZeD's menu offers it" .. (R.notKind and (" and no " .. R.notKind) or ""), S.menuText(rec))
            return
        end
        local ok, err = S.run(o)
        if not Q.check(ok, lab .. ": ZeD's menu offers it" .. (R.notKind and (" and no " .. R.notKind) or "") .. ", the pick runs",
            ok and S.menuText(rec) or tostring(err)) then t.roff = true end
    end)
    Q.waitFor(3, 1500, function()
        if t.off or t.roff or S.dead or not t.done then return true end
        return S.settled(t, U.part, R.done)
    end, function()
        if t.off or t.roff or S.dead or not t.done then return end
        local bp = S.part(U.part)
        local ok = bp ~= nil and S.queued() == 0 and R.done(bp)
        local bad = {}
        if not ok then bad[1] = "not done (queue " .. S.queued() .. ", idle " .. tostring(t.idle) .. " frames)"; S.clearQueue() end
        local back = "-"
        if R.back then
            local n1 = S.count(R.back)
            back = R.back .. " " .. tostring(t.r0) .. " to " .. tostring(n1)
            if not (n1 > (t.r0 or 0)) then bad[#bad + 1] = "nothing given back (" .. back .. ")" end
        end
        Q.check(#bad == 0, lab .. ": the game's action finished on " .. U.part, #bad == 0 and ("given back: " .. back) or table.concat(bad, "; "))
        t.rdone = ok
        S.refresh()
    end)
    Q.waitFor(2, 240, function()
        if t.off or t.roff or S.dead or not t.rdone then return true end
        return S.tabReady(U.part, S.partOf(U.part).fig)
    end, function(ok)
        if t.off or t.roff or S.dead or not t.rdone then return end
        S.tabCheck(lab, U, ok, R.figWant)
    end)
end
-- a menu that must not offer a handler (vanilla's rule), with the items in the bag
function S.notOffered(lab, bpName, stage, give, kind, alsoKind)
    Q.step(1, function()
        if S.dead then return end
        S.sweep()
        local took = S.stageOn(bpName, stage)
        for _, ft in ipairs(give or {}) do S.put(ft) end
        local rec = S.menuOf(S.partOf(bpName).fig)
        local okA = not alsoKind or S.hasKind(rec, alsoKind)
        Q.check(took and not S.hasKind(rec, kind) and okA,
            lab .. ": ZeD's menu does not offer " .. kind .. " (vanilla's rule)" .. (alsoKind and (", it offers " .. alsoKind) or ""),
            S.menuText(rec))
        S.putPart(bpName)
        S.sweep()
    end)
end
function S.groupDone(name)
    Q.step(1, function()
        if S.dead then return end
        local e1 = S.errN()
        Q.check(S.e0 == nil or e1 == nil or e1 == S.e0, name .. ": no Lua error", (S.e0 and e1) and ((e1 - S.e0) .. " new") or "the count cannot be read")
        S.e0 = e1
        Q.check(#S.pbBad == 0, name .. ": every part put back exactly", #S.pbBad == 0 and "clean" or table.concat(S.pbBad, "; "))
        S.pbBad = {}
    end)
end

-- ===================================================================== the treatments
function S.isDirty(ft) return S.has(ft, "Dirty") end
function S.buildBandages()
    for i, P in ipairs(S.PARTS) do
        local ft = S.BANDAGES[((i - 1) - math.floor((i - 1) / #S.BANDAGES) * #S.BANDAGES) + 1]
        local dirty = S.isDirty(ft)
        S.unit({
            lab = "bandage " .. ft, part = P.bp, stage = "scratch", give = { ft }, kind = "HApplyBandage", a1 = ft,
            useItem = ft, used = "consumed",
            done = function(b) return b:bandaged() end,
            result = function(b)
                local ty, life = tostring(b:getBandageType()), b:getBandageLife()
                local okL = (dirty and life <= 0) or ((not dirty) and life > 0)
                return b:bandaged() and ty == ft and okL, "type " .. ty .. ", life " .. S.n(life) .. (dirty and " (a Dirty kind: 0)" or "")
            end,
            figWant = function(wd)
                local want = dirty and "dirty" or "clean"
                if not (wd and wd.bandage == want) then return "the figure's gauze " .. S.wText(wd) .. ", want " .. want end
                return nil
            end,
            remove = { kind = "HRemoveBandage", notKind = "HApplyBandage", say = "Remove Bandage", give = { ft },
                       done = function(b) return not b:bandaged() end,
                       figWant = function(wd) if wd and wd.bandage then return "gauze still on the figure" end; return nil end },
        })
    end
    S.groupDone("bandage")
end
function S.buildDisinfect()
    local list = { { "Base.AlcoholWipes", "ForeArm_R" }, { "Base.AlcoholedCottonBalls", "Hand_R" },
                   { "Base.Disinfectant", "UpperLeg_L" }, { "Base.Whiskey", "Neck" } }
    for _, x in ipairs(list) do
        S.unit({
            lab = "disinfect " .. x[1], part = x[2], stage = "laceration", give = { x[1] }, kind = "HDisinfect", a1 = x[1],
            useItem = x[1], used = "drained",
            done = function(b) return b:getAlcoholLevel() > 0 end,
            result = function(b) return b:getAlcoholLevel() > 0, "alcohol level " .. S.n(b:getAlcoholLevel()) .. ", pain " .. S.n(b:getAdditionalPain()) end,
        })
    end
    S.groupDone("disinfect")
end
function S.buildPoultices()
    local list = { { "HApplyPlantain", "Base.PlantainCataplasm", "Hand_L", "getPlantainFactor" },
                   { "HApplyComfrey", "Base.ComfreyCataplasm", "Foot_L", "getComfreyFactor" },
                   { "HApplyGarlic", "Base.WildGarlicCataplasm", "Torso_Lower", "getGarlicFactor" } }
    for _, x in ipairs(list) do
        local getter = x[4]
        S.unit({
            lab = "poultice " .. x[2], part = x[3], stage = "scratch", give = { x[2] }, kind = x[1], a1 = x[2],
            useItem = x[2], used = "consumed",
            done = function(b) return b[getter](b) > 0 end,
            result = function(b) return b[getter](b) > 0, getter .. " " .. S.n(b[getter](b)) end,
        })
    end
    -- one poultice at a time (HApplyPoultice:addToMenu): with plantain on, no comfrey offered
    Q.step(1, function()
        if S.dead then return end
        S.sweep()
        local took, bp = S.stageOn("ForeArm_L", "scratch")
        pcall(function() bp:setPlantainFactor(5) end)
        S.put("Base.ComfreyCataplasm")
        local rec = S.menuOf("Left Forearm")
        Q.check(took and not S.hasKind(rec, "HApplyComfrey"), "poultice: with plantain on, ZeD's menu offers no second poultice (vanilla's rule)",
            S.menuText(rec))
        S.putPart("ForeArm_L")
        S.sweep()
    end)
    S.groupDone("poultice")
end
function S.buildBurns()
    local parts = { "UpperArm_L", "UpperArm_R", "Torso_Upper", "Groin", "LowerLeg_R", "Foot_R" }
    for i, ft in ipairs(S.BURN_ITEMS) do
        S.unit({
            lab = "clean burn " .. ft, part = parts[i], stage = "burnwash", give = { ft }, kind = "HCleanBurn", a1 = ft,
            useItem = ft, used = "consumed",
            done = function(b) return not b:isNeedBurnWash() end,
            result = function(b) return (not b:isNeedBurnWash()) and b:getBurnTime() > 0, "needs a wash " .. tostring(b:isNeedBurnWash()) .. ", burn " .. S.n(b:getBurnTime()) end,
        })
    end
    S.notOffered("clean burn with only a Bandaid and a Dirty bandage", "ForeArm_L", "burnwash", { "Base.Bandaid", "Base.BandageDirty" },
        "HCleanBurn", "HApplyBandage")
    S.groupDone("clean burn")
end
S.STITCHES = {
    { "Base.SutureNeedle", "Base.SutureNeedle", "ForeArm_L" },
    { "Base.Needle", "Base.Thread", "UpperArm_R" },
    { "Base.Needle_Bone", "Base.Thread_Aramid", "UpperLeg_R", tag = true },
    { "Base.Needle_Brass", "Base.Thread_Sinew", "LowerLeg_L", tag = true },
    { "Base.Needle_Forged", "Base.DentalFloss", "Torso_Upper", tag = true },
    { "Base.Needle_Bone", "Base.FishingLine", "Head", tag = true },
    { "Base.Needle_Brass", "Base.PremiumFishingLine", "Groin", tag = true },
    { "Base.Needle", "Base.Thread_Sinew", "Hand_R", tag = true },
    { "Base.Needle_Forged", "Base.Thread", "Foot_L", tag = true },
}
function S.buildStitches()
    for _, x in ipairs(S.STITCHES) do
        local suture = x[1] == x[2]
        S.unit({
            lab = "stitch " .. (suture and x[1] or (x[1] .. " + " .. x[2])), part = x[3], stage = "deep",
            give = suture and { x[1] } or { x[1], x[2] }, kind = "HStitch", a1 = x[1], a2 = x[2], tagOnly = x.tag,
            useItem = x[2], used = "drained",
            done = function(b) return b:stitched() end,
            result = function(b) return b:stitched(), "stitched, time " .. S.n(b:getStitchTime()) end,
            figWant = function(wd) if not (wd and S.inList(wd.marks, "stitch")) then return "no stitch mark: " .. S.wText(wd) end; return nil end,
            remove = { kind = "HRemoveStitch", say = "Remove Stitch", done = function(b) return not b:stitched() end,
                       figWant = function(wd) if wd and S.inList(wd.marks, "stitch") then return "stitches still on the figure" end; return nil end },
        })
    end
    S.notOffered("stitch with glass in the wound", "ForeArm_R", "glass", { "Base.SutureNeedle" }, "HStitch", "HRemoveGlass")
    S.groupDone("stitch")
end
function S.buildGlass()
    local parts = { "ForeArm_L", "Hand_R", "UpperLeg_L", "LowerLeg_R", "Foot_L", "Neck" }
    for i, ft in ipairs(S.TOOLS) do
        S.unit({
            lab = "remove glass with " .. ft, part = parts[i], stage = "glass", give = { ft }, kind = "HRemoveGlass", a1 = ft,
            useItem = ft, used = "kept",
            done = function(b) return not b:haveGlass() end,
            result = function(b) return not b:haveGlass(), "glass " .. tostring(b:haveGlass()) .. ", pain " .. S.n(b:getAdditionalPain()) end,
            figWant = function(wd) if wd and S.inList(wd.marks, "glass") then return "glass still on the figure" end; return nil end,
        })
    end
    S.unit({
        lab = "remove glass by hand", part = "Foot_R", stage = "glass", give = {}, kind = "HRemoveGlass", a1 = "Hands",
        done = function(b) return not b:haveGlass() end,
        result = function(b) return not b:haveGlass(), "glass " .. tostring(b:haveGlass()) .. ", pain " .. S.n(b:getAdditionalPain()) end,
    })
    S.groupDone("remove glass")
end
function S.buildBullets()
    local parts = { "Torso_Upper", "UpperArm_L", "UpperLeg_R", "Groin", "ForeArm_R", "LowerLeg_L" }
    for i, ft in ipairs(S.TOOLS) do
        S.unit({
            lab = "remove bullet with " .. ft, part = parts[i], stage = "bullet", give = { ft }, kind = "HRemoveBullet", a1 = ft,
            useItem = ft, used = "kept",
            done = function(b) return not b:haveBullet() end,
            result = function(b) return not b:haveBullet(), "bullet " .. tostring(b:haveBullet()) .. ", deep wound " .. tostring(b:deepWounded()) end,
            figWant = function(wd) if wd and S.inList(wd.marks, "bullet") then return "the bullet still on the figure" end; return nil end,
        })
    end
    S.notOffered("remove bullet with no tool", "UpperArm_R", "bullet", {}, "HRemoveBullet")
    S.groupDone("remove bullet")
end
S.SPLINTS = {
    { nil, "Base.Splint", "LowerLeg_L" },
    { "Base.RippedSheets", "Base.Plank", "ForeArm_R" },
    { "Base.RippedSheets", "Base.TreeBranch2", "UpperLeg_R" },
    { "Base.RippedSheets", "Base.WoodenStick2", "Hand_L" },
}
function S.buildSplints()
    for _, x in ipairs(S.SPLINTS) do
        local sheet, plank = x[1], x[2]
        S.unit({
            lab = "splint " .. (sheet and (plank .. " + " .. sheet) or plank), part = x[3], stage = "fracture",
            give = sheet and { sheet, plank } or { plank }, kind = "HSplint", a1 = sheet, a2 = plank,
            useItem = plank, used = "consumed",
            done = function(b) return b:getSplintFactor() > 0 end,
            result = function(b)
                local it = tostring(b:getSplintItem())
                return b:getSplintFactor() > 0 and it == plank, "factor " .. S.n(b:getSplintFactor()) .. ", item " .. it
            end,
            figWant = function(wd) if not (wd and wd.splint) then return "no splint on the figure: " .. S.wText(wd) end; return nil end,
            remove = { kind = "HRemoveSplint", say = "Remove Splint", back = plank, done = function(b) return b:getSplintFactor() == 0 end,
                       figWant = function(wd) if wd and wd.splint then return "the splint still on the figure" end; return nil end },
        })
    end
    S.notOffered("splint on the upper torso", "Torso_Upper", "fracture", { "Base.Splint" }, "HSplint")
    S.notOffered("splint on the lower torso", "Torso_Lower", "fracture", { "Base.Splint" }, "HSplint")
    S.notOffered("splint on the head", "Head", "fracture", { "Base.Splint" }, "HSplint")
    S.notOffered("splint on a stitched fracture", "LowerLeg_R", "fracstitch", { "Base.Splint" }, "HSplint", "HRemoveStitch")
    S.groupDone("splint")
end

-- ===================================================================== nothing fits: ZeD's own line
function S.needs(bpName, keys)
    local t = {}
    for _, k in ipairs(keys) do t[#t + 1] = Z.tr(k) end
    return Z.tr("UI_ZeD_Disclose_Needs", S.dispName(bpName), table.concat(t, ", "))
end
function S.sayCase(lab, bpName, stage, want, contains)
    Q.step(1, function()
        if S.dead then return end
        S.sweep()
        local took = S.stageOn(bpName, stage)
        local rec = S.menuOf(S.partOf(bpName).fig)
        local said = S.said
        local empty = #S.leaves(rec) == 0
        local okT
        if want then okT = said == want else okT = S.has(said, contains) end
        Q.check(took and empty and okT, lab .. ": with an empty bag the menu is empty and ZeD's line says what is missing",
            "said \"" .. tostring(said) .. "\"" .. (want and (", want \"" .. want .. "\"") or (", naming \"" .. tostring(contains) .. "\""))
            .. "; " .. S.menuText(rec))
        S.putPart(bpName)
    end)
end
function S.buildNothing()
    S.sayCase("nothing to treat", "ForeArm_L", "healthy", Z.tr("UI_ZeD_Health_NothingToTreat", S.dispName("ForeArm_L")))
    S.sayCase("a scratch", "Hand_L", "scratch", S.needs("Hand_L", { "UI_ZeD_Health_NeedBandage" }))
    S.sayCase("a deep wound", "UpperArm_L", "deep", S.needs("UpperArm_L", { "UI_ZeD_Health_NeedBandage", "UI_ZeD_Health_NeedStitch" }))
    S.sayCase("a fracture", "LowerLeg_L", "fracture", S.needs("LowerLeg_L", { "UI_ZeD_Health_NeedSplint" }))
    S.sayCase("a lodged bullet", "UpperLeg_R", "bullet", nil, Z.tr("UI_ZeD_Health_NeedTweezers"))
    -- glass with no tool: the game still offers it by hand, so the line never shows; what it would say, as a NOTE
    Q.step(1, function()
        if S.dead then return end
        S.sweep()
        S.stageOn("Foot_L", "glass")
        local rec = S.menuOf("Left Foot")
        local hand = S.findOpt(rec, "HRemoveGlass", "Hands") ~= nil
        Q.check(hand, "glass with no tool: ZeD's menu offers Remove Glass by hand (the game's own)", S.menuText(rec))
        Q.say("NOTE glass with no tool: the game's menu is not empty (Remove Glass by hand), so ZeD's line never shows here; it would say \""
            .. tostring(S.said) .. "\", naming tweezers though bare hands work")
        S.putPart("Foot_L")
    end)
    -- once through the game's real menu: a sound part, the menu hidden, the line on the character
    Q.step(1, function()
        if S.dead then return end
        S.stageOn("ForeArm_R", "healthy")
        S.said = nil
        S.passHalo = true
        local w = RT.cw()
        local ok, err = pcall(Z.HealthTab._onPartClicked, w, "Right Forearm", w and w._healthContentPanel or nil, 10, 10)
        S.passHalo = false
        local vis = true
        pcall(function() local m = getPlayerContextMenu(S.pn); vis = m ~= nil and m:getIsVisible() end)
        local want = Z.tr("UI_ZeD_Health_NothingToTreat", S.dispName("ForeArm_R"))
        Q.check(ok and vis == false and S.said == want, "the real menu on a sound part: no menu shows and the character says \"" .. want .. "\"",
            "menu shown " .. tostring(vis) .. ", said \"" .. tostring(S.said) .. "\"" .. (ok and "" or ("; error " .. tostring(err))))
        pcall(function() local m = getPlayerContextMenu(S.pn); if m and m:getIsVisible() then m:hideAndChildren() end end)
        S.putPart("ForeArm_R")
    end)
    S.groupDone("nothing fits")
end

-- ===================================================================== the medical check card
function S.card() local c = nil; pcall(function() c = ZeD_WorldWindow.getObjectCard(S.pn) end); return c end
function S.medOpen()
    local def = Z.ObjectCards and Z.ObjectCards.kinds and Z.ObjectCards.kinds.medic
    if not def then return false, "no medic kind" end
    S.patient = S.proxyOf(S.p, "_hgQaPatient")
    local t = nil
    pcall(function() t = def.resolve(S.p, S.patient) end)
    if not t then return false, "the kind's resolve gave nothing" end
    t._ended = true   -- (its close never asks the game to stop sending the stand-in's body: there is no such player)
    S.medT = t
    local ok, r = pcall(ZeD_WorldWindow.openObjectCard, S.pn, { def = def, t = t })
    return ok and r == true, tostring(r)
end
function S.cardZone(fid)
    local c = S.card()
    if not c then return nil end
    for _, list in ipairs({ c._zones or {}, c._lastZones or {} }) do
        for _, z in ipairs(list) do if z.fid == fid and z.run then return z end end
    end
    return nil
end
S.CARD = {
    { part = "ForeArm_L", stage = "deep", give = { "Base.Bandage", "Base.SutureNeedle", "Base.AlcoholWipes" } },
    { part = "LowerLeg_R", stage = "fracture", give = { "Base.Splint", "Base.Bandage" } },
    { part = "Foot_L", stage = "glass", give = { "Base.Tweezers" } },
}
function S.buildCard()
    Q.step(2, function()
        if S.dead then return end
        S.sweep()
        local ok, why = S.medOpen()
        S.medOff = not ok
        Q.check(ok, "card: the medical check card opens on the World window (a stand-in patient: his own body)", why)
    end)
    for _, C in ipairs(S.CARD) do
        local fig = S.partOf(C.part).fig
        local fid = "mc:fig:" .. fig
        Q.step(1, function()
            if S.dead or S.medOff then return end
            S.stageOn(C.part, C.stage)
            for _, ft in ipairs(C.give) do S.put(ft) end
        end)
        Q.waitFor(3, 300, function() return S.dead or S.medOff or S.cardZone(fid) ~= nil end, function(ok)
            if S.dead or S.medOff then return end
            local tabRec = S.menuOf(fig)
            local z = S.cardZone(fid)
            local cardRec = S.recorder()
            local orig = ISContextMenu.get
            ISContextMenu.get = function() return cardRec end
            local okR, err = false, "no zone " .. fid
            if z then okR, err = pcall(z.run, S.card()) end
            ISContextMenu.get = orig
            local a, b = S.menuText(tabRec), S.menuText(cardRec)
            Q.check(ok and okR and #S.leaves(cardRec) > 0 and a == b, "card: " .. fig .. "'s menu from the card is the Health tab's",
                "card: " .. b .. (okR and "" or (" (error " .. tostring(err) .. ")")) .. " | tab: " .. a)
            local roles = {}
            for _, o in ipairs(S.leaves(cardRec)) do
                local d, p = nil, nil
                pcall(function() d = o.target:getDoctor(); p = o.target:getPatient() end)
                if not (d == S.p and type(p) == "table" and p._hgQaPatient) then roles[#roles + 1] = S.optText(o) end
            end
            Q.check(#S.leaves(cardRec) > 0 and #roles == 0, "card: " .. fig .. ": every treatment has the character as doctor and the stand-in as patient",
                #roles == 0 and (#S.leaves(cardRec) .. " options") or ("wrong roles: " .. table.concat(roles, " ")))
            S.putPart(C.part)
            S.sweep()
        end)
    end
    Q.step(2, function()
        if S.card() then pcall(ZeD_WorldWindow.closeObjectCard, S.pn) end
        if not (S.dead or S.medOff) then
            Q.say("NOTE card: the treatments are not run from the card here: the game's timed actions turn the doctor to face a real patient (faceThisObject), and single player has no second player")
        end
    end)
    S.groupDone("card")
end

-- ===================================================================== start
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
function S.until1(n, max, cond, fn)
    Q.waitFor(n, max, function() return S.dead or cond() end, function(ok) if not S.dead then fn(ok) end end)
end
function S.start()
    S.err0 = S.errN()
    S.e0 = S.err0
    local HT = Z.HealthTab
    local ready = HT ~= nil and HT._onPartClicked ~= nil and HT.treat ~= nil and HT.sayNothingFits ~= nil
        and ISHealthPanel ~= nil and ISHealthPanel.doBodyPartContextMenu ~= nil and ISContextMenu ~= nil
        and ISInventoryPaneContextMenu ~= nil and ISInventoryPaneContextMenu.getContainers ~= nil and S.bd() ~= nil
    if not Q.check(ready, "ZeD's treatment menu (HealthTab._onPartClicked, treat, sayNothingFits) and the game's are loaded") then
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
    f.docXp = S.xp(Perks.Doctor)
    f.stats = {}
    for _, k in ipairs({ "PAIN", "PANIC", "STRESS" }) do f.stats[k] = S.stat(k) end
    local bd = S.bd()
    f.zInf = false
    pcall(function() f.zInf = bd:isInfected() end)
    f.parts = {}
    for _, P in ipairs(S.PARTS) do f.parts[P.bp] = S.snap(S.part(P.bp)) end
    -- the main inventory as found (its items by id: whatever is new at the end goes)
    f.invN = 0
    pcall(function()
        local items = S.p:getInventory():getItems()
        for i = 0, items:size() - 1 do S.ids0[items:get(i):getID()] = true; f.invN = f.invN + 1 end
    end)
    f.recorded = true
    S.back.on = true
    Q.say("found: First Aid " .. tostring(f.doc) .. " (xp " .. S.n(f.docXp) .. "), god " .. tostring(f.god) .. ", speed "
        .. tostring(f.speed) .. ", infected " .. tostring(f.zInf) .. ", " .. f.invN .. " things in the main inventory")
    S.speed(1)
    S.live = true
    Events.OnTick.Add(S.safety)
    pcall(function() S.p:setInvincible(true) end)
    pcall(function() S.p:setGodMod(false) end)
    Q.check(S.p:isGodMod() == false, "god mode is off for the run (it heals a wound at once), the guard is on", "was " .. tostring(f.god))
    if ISHealthPanel then ISHealthPanel.cheat = false end
    S.setDoc(S.DOC)
    S.clearQueue()
    local dirty = {}
    for _, P in ipairs(S.PARTS) do
        local bp = S.part(P.bp)
        S.restore(bp, S.CLEAN)
        S.base[P.bp] = S.snap(bp)
        local d = S.cleanDiff(S.base[P.bp])
        if #d > 0 then dirty[#dirty + 1] = P.bp .. ": " .. table.concat(d, ", ") end
    end
    Q.check(#dirty == 0, "every part made clean for the run (each as found is kept)", #dirty == 0 and "17 parts" or table.concat(dirty, "; "))
    -- the bag the run's items go in, and the container list answering it alone
    S.bag = RT.give("Base.Bag_Schoolbag")
    pcall(function() S.bagInv = S.bag:getInventory() end)
    S.isoOn()
    S.iso = true
    S.sayOn()
    local l = nil
    pcall(function() l = ISInventoryPaneContextMenu.getContainers(S.p) end)
    local n = -1
    pcall(function() n = l:size() end)
    if not Q.check(S.bagInv ~= nil and n == 1, "the run's bag is the one container the menu sees", "containers " .. n) then
        -- (without it the menu would offer the character's own things and the run would use them up)
        S.bail("the run's bag could not be set up")
        return
    end
    RT.pairOpen()
end
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
        S.speed(S.FAST)
    end)
    S.buildBandages()
    S.buildDisinfect()
    S.buildPoultices()
    S.buildBurns()
    S.buildStitches()
    S.buildGlass()
    S.buildBullets()
    S.buildSplints()
    Q.step(1, function() S.speed(1) end)
    S.buildNothing()
    S.buildCard()
end

-- ===================================================================== put back
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    S.clearQueue()
    if S.card() then pcall(ZeD_WorldWindow.closeObjectCard, S.pn) end
    S.sayOff()
    S.isoOff()
    S.unholdAll()
    S.left = S.sweep()
    local f = S.found
    for _, P in ipairs(S.PARTS) do S.restore(S.part(P.bp), f.parts[P.bp]) end
    local bd = S.bd()
    if bd and f.zInf == false then pcall(S.noInfection, bd) end
    for k, v in pairs(f.stats or {}) do S.setStat(k, v) end
    S.setDoc(f.doc)
    S.putXp(Perks.Doctor, f.docXp, f.doc)
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
        Q.check(#S.putDiff == 0, "put back: every part exactly as found", #S.putDiff == 0 and "17 parts" or table.concat(S.putDiff, "; "))
        if S.found.pair then RT.pairOpen() else RT.pairShut() end
    end)
    Q.waitFor(5, 120, function() return RT.isOpen() == (S.found.pair == true) end, function(ok)
        if S.found.pair and S.found.tab and S.found.tab ~= "health" then RT.charTab(S.found.tab) end
        Q.check(ok, "put back: the window pair " .. (S.found.pair and "open" or "shut") .. " as found")
    end)
    -- (rt_kit takes the bag back after this, in Q.start's own step)
    Q.step(20, function()
        local f = S.found
        local p = S.p
        if not f.recorded then
            Q.skip("put back", "nothing was staged (the modules were not loaded)")
            return
        end
        local w = RT.cw()
        if f.pair and f.tab then Q.check(w ~= nil and w._activeTab == f.tab, "put back: the Character window's tab", tostring(w and w._activeTab)) end
        Q.check(ISInventoryPaneContextMenu.getContainers ~= nil and S.gc0 == nil and Z.HealthTab.sayNothingFits == (S.sayBack or Z.HealthTab.sayNothingFits)
            and S.card() == nil and #S.held == 0,
            "put back: the game's container list, ZeD's sayNothingFits, the card closed, no window held")
        local missing, extra = 0, 0
        local seen = {}
        pcall(function()
            local items = p:getInventory():getItems()
            for i = 0, items:size() - 1 do
                local it = items:get(i)
                local id = it:getID()
                seen[id] = true
                if not S.ids0[id] and it ~= S.bag then extra = extra + 1 end
            end
        end)
        for id in pairs(S.ids0) do if not seen[id] then missing = missing + 1 end end
        Q.check(missing == 0 and extra == 0, "put back: the main inventory as found (nothing of the character's used, nothing left from the run)",
            "missing " .. missing .. ", left " .. extra .. "; swept at the end " .. tostring(S.left))
        local xp = S.xp(Perks.Doctor)
        Q.check(S.doc() == f.doc and xp ~= nil and f.docXp ~= nil and math.abs(xp - f.docXp) < 1 and (not ISHealthPanel or ISHealthPanel.cheat == f.cheat),
            "put back: First Aid, its XP and the debug cheat as found",
            "First Aid " .. tostring(S.doc()) .. " (was " .. tostring(f.doc) .. "), xp " .. S.n(xp) .. " (was " .. S.n(f.docXp) .. ")")
        if S.bailed then
            Q.check(p:isGodMod() == true, "put back: the run stopped early, so god mode is left ON", tostring(p:isGodMod()))
        else
            Q.check(p:isGodMod() == (f.god and true or false), "put back: god mode as found", tostring(f.god))
        end
        local bd = S.bd()
        local inf, hp = false, nil
        pcall(function() inf = bd:isInfected(); hp = bd:getOverallBodyHealth() end)
        Q.check(not p:isDead() and (inf == false or f.zInf == true), "put back: the character is alive and not infected",
            (p:isDead() and "DEAD; " or "") .. "health " .. S.n(hp) .. "; infected " .. tostring(inf) .. "; health top-ups " .. tostring(S.topUps or 0))
        local e1 = S.errN()
        if S.err0 and e1 then
            Q.check(e1 == S.err0, "the treatment run ran with no Lua error", (e1 - S.err0) .. " new")
        else
            Q.skip("the treatment run's Lua error count", "the game's Lua error count cannot be read here")
        end
    end)
end

S.build()
S.buildPutBack()
Q.start()
