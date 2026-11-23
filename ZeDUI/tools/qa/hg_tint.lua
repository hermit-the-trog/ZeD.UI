-- ZeDUI/tools/qa/hg_tint.lua  (Nov 23 2026, QA; tag hg_tint): the Health figure's tint, in game. Build's branch
-- fix/notint (c4f2f1de7): on the Health tab's body figure and the medical check card's only, a healthy part takes no
-- tint (colorMap empty for it), an injured part takes its worst condition's severity color that is not strain (the
-- token of its dot in the list, data.partSev), a part hurt with no condition named its health color, strain alone keeps
-- T.strainMinor / T.strainHeavy; both figures carry fig.boneLift, so the tint is lifted toward white (BONE_TINT 0.55)
-- before it multiplies the lit bone. Thermal and Equipment's defense view are unchanged (no boneLift).
-- The director, Nov 23 2026: "the problem is that I can't see the skeleton." The bones must stand out from the flesh in
-- every theme, Light especially: the pictures are for that look, and each logs the figure's rect on screen to crop it.
-- Run after zedqa_prelude.lua and rt_kit.lua (hg_tint.txt). grep "ZEDQA hg_tint".
--
-- Staged with the game's own BodyPart setters (hg_injury.lua's way): every part made clean first (each part as found is
-- kept and put back), then a moderate scratch on the Left Forearm (warning), a deep wound on the Right Upper Leg
-- (danger), a bite on the Right Hand (critical: the danger token; its zombie infection taken off at once and on every
-- tick), minor strain (stiffness 10) on the Left Upper Arm and heavy strain (40) on the Right Upper Arm, the stiffness
-- held on every player update (rt_strain.lua's hold: it fades otherwise). God mode off with the guard on (hg_injury's).
-- Checks, for each theme Dark, Light and High contrast (ZeD.applyTheme, gc_cleanup.lua's switch):
--   healthy   the Health tab, figure unfolded, the clean body: no colorMap entry for any of the 17 parts, fig.boneLift
--             set (picture hg_tint_<theme>_healthy_<w>x<h>)
--   hurt      the same figure with the body staged: each injured part's colorMap is the token of data.partSev (its
--             list dot: injuryList's row has that worst severity), the scratch the warning token, the deep wound and
--             the bite the danger token; the strained parts strainMinor / strainHeavy (their list rows at levels 1 and
--             2); every other part no entry; boneLift set; figureColor agrees (picture hg_tint_<theme>_hurt_<w>x<h>)
--   card      the medical check card (a stand-in patient: his own body, vk8_wounds.lua's) held to 336 units: its figure
--             has boneLift and the same colorMap rule on the card's read (picture hg_tint_<theme>_medcard_<w>x<h>)
--   thermal   Dark only: the Thermal tab's figure has no boneLift (unchanged) (picture hg_tint_dark_thermal_<w>x<h>)
--   theme     no Lua error in the theme's run; every part put back to clean after it
-- Each picture logs a NOTE line per figure in it:
--   NOTE rect <file> <which> figure=x,y,w,h box=x,y,w,h frame=x,y,w,h panel=x,y,w,h view=x,y,w,h zoom=<n> screen=WxH
-- in screen pixels: figure = the skeleton's canvas as drawn (106 x 254 art px at the zoom), box = the rect drawAt was
-- given, frame = the figure's frame (Molecules.drawFigureFrame's layout), panel = the panel it draws on, view = the
-- Health tab's scrolling view (the figure is clipped to it; "-" elsewhere). <which> is health, card or thermal.
-- Puts back: every part as found (every flag and clock: bandage and its type, splint and its item, stitches, bite,
-- infection, health, stiffness, pain), the stiffness hold off, the zombie infection off as found, the pain stat, First
-- Aid, god mode, invincible, the game speed, the theme (base, accent, size), the medical card closed and its width hold
-- off, the Health and Thermal figures' folds, the windows and the Character window's tab; the drawAt and frame wrappers
-- off; no window held, the pointer the game's. No Lua error. Nothing is given.
if not RT then print("ZEDQA hg_tint ERR rt_kit.lua did not run first"); print("ZEDQA hg_tint DONE"); return end
local Q = RT.make("hg_tint")
Q.maxMs = 900000                     -- (the runner gives this script 1200 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, live = false, t0 = getTimestampMs(), held = {}, base = {},
            pbBad = {}, drawn = {}, frames = {}, err0 = nil }
local Z = ZeD

S.DOC = 10                           -- First Aid for the run (every severity word read)
S.CARD_W = 336                       -- the medical card's width, in units (vk8_wounds.lua's)
S.THEMES = {
    { key = "dark", tag = "dark", say = "Dark", thermal = true },
    { key = "light", tag = "light", say = "Light" },
    { key = "hicon", tag = "hc", say = "High contrast" },
}
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
-- the hurt body: wounds (sev = the worst severity the list reads, tok = its token) and strain (lv, stiffness)
S.WOUNDS = {
    { bp = "ForeArm_L", id = "a moderate scratch", sev = "warning", tok = "warning",
      apply = function(b) b:setScratched(true, false); b:setScratchTime(15) end, has = function(b) return b:scratched() end },
    { bp = "UpperLeg_R", id = "a deep wound", sev = "danger", tok = "danger",
      apply = function(b) b:generateDeepWound(); b:setDeepWoundTime(15) end, has = function(b) return b:deepWounded() end },
    { bp = "Hand_R", id = "a bite", sev = "critical", tok = "danger",
      apply = function(b) b:SetBitten(true); b:SetInfected(false); b:SetFakeInfected(false); S.noInfection(S.bd()) end,
      has = function(b) return b:bitten() end },
}
S.STRAIN = { { bp = "UpperArm_L", lv = 1, stiff = 10, tok = "strainMinor" }, { bp = "UpperArm_R", lv = 2, stiff = 40, tok = "strainHeavy" } }

-- what is read of a part and put back exactly: { field, getter } (hg_injury.lua's)
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
S.CLEAN = { scratched = false, scratchTime = 0, cut = false, cutTime = 0, bleeding = false, bleedingTime = 0, deep = false,
            deepTime = 0, glass = false, bullet = false, bandaged = false, bandageLife = 0, splint = false, splintFactor = 0,
            fractureTime = 0, stitched = false, stitchTime = 0, infectedWound = false, woundInfection = 0, burnTime = 0,
            burnWash = false, alcohol = 0, plantain = 0, comfrey = 0, garlic = 0, health = 100, stiffness = 0,
            addPain = 0, bitten = false, biteTime = 0, infected = false }

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
function S.n(v)
    local x = tonumber(v)
    if x == nil then return "?" end
    return tostring(math.floor(x * 10 + 0.5) / 10)
end
function S.r(v) local x = tonumber(v); if x == nil then return "?" end; return tostring(math.floor(x + 0.5)) end
function S.near(a, b) return type(a) == "number" and type(b) == "number" and math.abs(a - b) < 0.002 end
function S.sameC(a, b) return a ~= nil and b ~= nil and S.near(a.r, b.r) and S.near(a.g, b.g) and S.near(a.b, b.b) end
function S.cText(c) return c and string.format("%.2f,%.2f,%.2f", c.r or -1, c.g or -1, c.b or -1) or "none" end
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
function S.until1(n, max, cond, fn)
    Q.waitFor(n, max, function() return S.dead or cond() end, function(ok) if not S.dead then fn(ok) end end)
end

-- ===================================================================== the body: read, clean, put back (hg_injury's)
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
        -- (a part with no bandage can keep the last bandage's type name in the game: the name counts only on a bandaged part)
        elseif k == "bandageType" and not a.bandaged and not b.bandaged then same = true
        elseif k == "bandageType" or k == "splintItem" then same = tostring(x or "") == tostring(y or "")
        else same = (x == y) end
        if not same then diff[#diff + 1] = k .. " " .. tostring(y) .. " (was " .. tostring(x) .. ")" end
    end
    return diff
end
-- a part healed of what this script put on it, then set as found (hg_injury.lua's S.restore: the bullet out first, the
-- gauze off only where there is gauze, a bite off with its infection, the stitches before the deep wound)
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
    if f.splint then pcall(function() bp:setSplint(true, f.splintFactor or 0) end) end
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
-- every part back to its clean base (the run's), each read again into S.pbBad
function S.allClean()
    for _, P in ipairs(S.PARTS) do
        local bp = S.part(P.bp)
        local base = S.base[P.bp] or S.CLEAN
        S.restore(bp, base)
        for _, x in ipairs(S.snapDiff(base, S.snap(bp))) do S.pbBad[#S.pbBad + 1] = P.bp .. " " .. x end
    end
end
function S.bail(why)
    if S.bailed then return end
    S.bailed = true
    S.dead = true
    Q.check(false, "the run went on to its end", "stopped, on to the put-back: " .. tostring(why))
    if Q.backAt and Q.qi < Q.backAt then Q.qi = Q.backAt; Q.wait = nil end
end
-- THE GUARD, on every game tick while god mode is off (hg_injury's): no zombie infection, health under 75 topped up on
-- every part (the wounds stay), under 35 god mode ON and on to the put-back
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

-- ===================================================================== the strain, held every player update (rt_strain's)
function S.applyStrain()
    if not S.want then return end
    for _, s in ipairs(S.STRAIN) do
        local bp = S.part(s.bp)
        if bp then pcall(function() bp:setStiffness(s.stiff) end) end
    end
end
function S.keep(pl) if S.want and pl == S.p then pcall(S.applyStrain) end end
function S.stage()
    S.want = true
    S.applyStrain()
    if not S.keeping then Events.OnPlayerUpdate.Add(S.keep); S.keeping = true end
end
function S.unstage()
    S.want = nil
    if S.keeping then Events.OnPlayerUpdate.Remove(S.keep); S.keeping = false end
end
-- the hurt body on the clean base: the three wounds and the two strains (the hold on); returns the parts not taken
function S.stageHurt()
    local miss = {}
    for _, W in ipairs(S.WOUNDS) do
        local bp = S.part(W.bp)
        S.restore(bp, S.base[W.bp] or S.CLEAN)
        local ok = bp ~= nil and pcall(W.apply, bp)
        local took = false
        if ok then pcall(function() took = W.has(bp) end) end
        if not took then miss[#miss + 1] = W.bp .. " (" .. W.id .. ")" end
    end
    S.stage()
    for _, s in ipairs(S.STRAIN) do
        local bp = S.part(s.bp)
        local v = nil
        if bp then pcall(function() v = bp:getStiffness() end) end
        if not (type(v) == "number" and math.abs(v - s.stiff) < 0.5) then miss[#miss + 1] = s.bp .. " (stiffness " .. tostring(v) .. ")" end
    end
    return miss
end

-- ===================================================================== the theme (gc_cleanup.lua's switch)
function S.theme(base)
    if ZeD.currentBase == base then return end
    pcall(ZeD.applyTheme, base, ZeD.currentAccent, ZeD.currentSize)
    Q.say("theme " .. tostring(ZeD.currentBase) .. " (" .. tostring(ZeD.currentAccent) .. ", " .. tostring(ZeD.currentSize) .. ")")
end

-- ===================================================================== the figures' draws (where each drew, its frame)
-- ZeD_BodyFigure.drawAt wrapped: each figure's panel and the rect it was given, the last draw; Molecules.drawFigureFrame
-- wrapped: the layout each panel drew its frame with (gc_cleanup.lua's frameWrap)
function S.wrapOn()
    if S.w0 then return end
    local F, M = ZeD_BodyFigure, Z.Molecules
    S.w0 = { drawAt = F.drawAt, frame = M and M.drawFigureFrame }
    local origD = S.w0.drawAt
    F.drawAt = function(self, panel, px, py, pw, ph)
        S.drawn[self] = { panel = panel, x = tonumber(px) or 0, y = tonumber(py) or 0, w = tonumber(pw) or 0, h = tonumber(ph) or 0 }
        return origD(self, panel, px, py, pw, ph)
    end
    local origF = S.w0.frame
    if origF then
        M.drawFigureFrame = function(panel, L, a3, a4, a5, a6)
            if panel and type(L) == "table" then S.frames[panel] = L end
            return origF(panel, L, a3, a4, a5, a6)
        end
    end
end
function S.wrapOff()
    if not S.w0 then return end
    ZeD_BodyFigure.drawAt = S.w0.drawAt
    if S.w0.frame and Z.Molecules then Z.Molecules.drawFigureFrame = S.w0.frame end
    S.w0 = nil
    S.frames = {}
end
function S.hFig() local w = RT.cw(); return w and w._healthBodyFigure or nil end
function S.tFig() local w = RT.cw(); return w and w._thermalBodyFigure or nil end
function S.data() local w = RT.cw(); return w and w._healthCache or nil end
function S.figName(data, bpName, fallback)
    for fig, bp in pairs(data and data.partByFigure or {}) do
        if S.typeOf(bp) == bpName then return fig end
    end
    return fallback
end
-- ask the tab for a fresh read on its next draw (hg_injury's)
function S.refresh()
    local w = RT.cw()
    if not w then return end
    S.oldData = w._healthCache
    w._healthAt = nil
    w._healthFillAt = nil
end
-- a cond: once ready() holds, the draws are cleared once, then true when fig() has drawn again (a draw from that read)
function S.readThenDraw(t, ready, fig)
    return function()
        if not t.seen then
            if ready() then t.seen = true; S.drawn = {} end
            return false
        end
        local f = fig()
        return f ~= nil and S.drawn[f] ~= nil
    end
end
function S.clean(d) return d ~= nil and d ~= S.oldData and d.woundedCount == 0 and (d.strainedCount or 0) == 0 end
-- the hurt read: each wound at its severity (partSev), each strain at its level (partStrain)
function S.hurtReady(d)
    if not (d and d.partSev and d.partStrain) then return false end
    for _, W in ipairs(S.WOUNDS) do
        if d.partSev[S.figName(d, W.bp, S.figOf(W.bp))] ~= W.sev then return false end
    end
    for _, s in ipairs(S.STRAIN) do
        if d.partStrain[S.figName(d, s.bp, S.figOf(s.bp))] ~= s.lv then return false end
    end
    return true
end
function S.figOf(bp) for _, P in ipairs(S.PARTS) do if P.bp == bp then return P.fig end end; return bp end
function S.woundOf(bp) for _, W in ipairs(S.WOUNDS) do if W.bp == bp then return W end end; return nil end
function S.strainOf(bp) for _, s in ipairs(S.STRAIN) do if s.bp == bp then return s end end; return nil end

-- ===================================================================== the tint rule
-- the problems of one figure against the rule, on the read d: hurt false = the clean body (no entry on any part)
function S.tintProblems(fig, d, hurt)
    local bad, seen = {}, {}
    local HT, T = Z.HealthTab, Z.T
    if not fig then bad[1] = "no figure"; return bad, "" end
    if not d then bad[1] = "no read"; return bad, "" end
    local cm = fig.colorMap or {}
    for _, P in ipairs(S.PARTS) do
        local fn = S.figName(d, P.bp, P.fig)
        local c = cm[fn]
        local hp = d.partHealth and d.partHealth[fn] or nil
        local W, St = hurt and S.woundOf(P.bp) or nil, hurt and S.strainOf(P.bp) or nil
        if W then
            local sev = d.partSev and d.partSev[fn] or nil
            local want = (sev and HT.sevColor(sev)) or (hp and HT.healthColor(hp)) or nil
            if not S.sameC(c, want) then
                bad[#bad + 1] = fn .. " " .. S.cText(c) .. ", want its severity " .. tostring(sev) .. " " .. S.cText(want)
            elseif not S.sameC(c, T[W.tok]) then
                bad[#bad + 1] = fn .. " " .. S.cText(c) .. ", not the " .. W.tok .. " token " .. S.cText(T[W.tok]) .. " (" .. W.id .. ", severity " .. tostring(sev) .. ")"
            end
            seen[#seen + 1] = fn .. " " .. tostring(sev) .. " " .. S.cText(c)
        elseif St then
            local want = T[St.tok]
            local okR, rc = pcall(HT.strainColor, St.lv)
            if not (S.sameC(c, want) and okR and S.sameC(rc, want)) then
                bad[#bad + 1] = fn .. " " .. S.cText(c) .. ", want " .. St.tok .. " " .. S.cText(want)
            end
            seen[#seen + 1] = fn .. " " .. St.tok .. " " .. S.cText(c)
        elseif c ~= nil then
            bad[#bad + 1] = fn .. " has a tint " .. S.cText(c) .. " (healthy: none)"
        end
        -- figureColor (the tab's and the card's one call) agrees with what the figure holds
        local okF, fc = pcall(HT.figureColor, d, fn, hp or 100)
        if not okF then bad[#bad + 1] = "figureColor threw on " .. fn .. ": " .. tostring(fc)
        elseif not ((fc == nil and c == nil) or S.sameC(fc, c)) then
            bad[#bad + 1] = fn .. ": figureColor " .. S.cText(fc) .. ", the figure " .. S.cText(c)
        end
    end
    return bad, table.concat(seen, "; ")
end
-- each hurt part's list dot: injuryList's row has the severity partSev gives (strain rows at their level)
function S.dotProblems(d)
    local bad = {}
    local okL, rows = pcall(Z.HealthTab.injuryList, d)
    if not (okL and type(rows) == "table") then bad[1] = "injuryList: " .. tostring(rows); return bad end
    local function rowOf(bp)
        for _, r in ipairs(rows) do if S.typeOf(r.bodyPart) == bp then return r end end
        return nil
    end
    for _, W in ipairs(S.WOUNDS) do
        local r = rowOf(W.bp)
        local fn = S.figName(d, W.bp, S.figOf(W.bp))
        local sev = d.partSev and d.partSev[fn] or nil
        if not r then bad[#bad + 1] = W.bp .. " has no list row"
        elseif r.worstSev ~= sev then bad[#bad + 1] = W.bp .. ": the row's dot " .. tostring(r.worstSev) .. ", partSev " .. tostring(sev) end
    end
    for _, s in ipairs(S.STRAIN) do
        local r = rowOf(s.bp)
        if not r then bad[#bad + 1] = s.bp .. " has no list row"
        elseif r.strainLv ~= s.lv then bad[#bad + 1] = s.bp .. ": the row's strain level " .. tostring(r.strainLv) .. ", want " .. s.lv end
    end
    return bad
end
function S.figCheck(lab, fig, d, hurt)
    local bad, seen = S.tintProblems(fig, d, hurt)
    local lift = fig ~= nil and fig.boneLift == true
    Q.check(lift, lab .. ": the figure keeps its bones light (fig.boneLift set)", "boneLift " .. tostring(fig and fig.boneLift))
    if hurt then
        Q.check(#bad == 0, lab .. ": each injured part takes its worst severity's token (its list dot), each strained part its strain tint, every other part no tint",
            #bad == 0 and seen or table.concat(bad, "; "))
    else
        Q.check(#bad == 0, lab .. ": the healthy body: no tint on any of the 17 parts",
            #bad == 0 and "17 parts, no colorMap entry" or table.concat(bad, "; "))
    end
end

-- ===================================================================== the medical check card (vk8_wounds / gc_cleanup)
function S.card() local c = nil; pcall(function() c = ZeD_WorldWindow.getObjectCard(S.pn) end); return c end
function S.entryT()
    local c = S.card()
    local e = c and c.entry
    return e and e.t or nil
end
-- a stand-in patient: every method call answered with the character's own (single player has no other player)
function S.proxyOf(pl)
    local px = { _hgTintQaPatient = true }
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
function S.medOpen()
    local def = Z.ObjectCards and Z.ObjectCards.kinds and Z.ObjectCards.kinds.medic
    if not def then return false, "no medic kind" end
    local t = nil
    pcall(function() t = def.resolve(S.p, S.proxyOf(S.p)) end)
    if not t then return false, "the kind's resolve gave nothing" end
    t._ended = true   -- (its close never asks the game to stop sending the stand-in's body: there is no such player)
    S.medT = t
    local ok, r = pcall(ZeD_WorldWindow.openObjectCard, S.pn, { def = def, t = t })
    return ok and r == true, tostring(r)
end
-- the card's width held (gc_cleanup's: the drawer's width through objectDrawerW where Build has it, else the card's
-- own prerender)
function S.cardHook()
    local WW = ZeD_WorldWindow
    if not S.drawerOrig and WW and WW.objectDrawerW then
        S.drawerOrig = WW.objectDrawerW
        WW.objectDrawerW = function(def, base)
            if S.cardW then return Z.T.px(S.cardW) end
            return S.drawerOrig(def, base)
        end
    end
    if S.drawerOrig then return end
    local ww = RT.ww()
    local card = ww and ww._objectCard
    if not card or S.hooked == card then return end
    S.hooked = card
    S.hookOwn = rawget(card, "prerender") or false
    local base = S.hookOwn or ZeD_ObjectCard.prerender
    card.prerender = function(self)
        if S.cardW then
            local w = Z.T.px(S.cardW)
            if math.abs(self:getWidth() - w) > 0.5 then self:setWidth(w) end
        end
        return base(self)
    end
end
function S.cardUnhook()
    S.cardW = nil
    if S.drawerOrig and ZeD_WorldWindow then ZeD_WorldWindow.objectDrawerW = S.drawerOrig end
    S.drawerOrig = nil
    local card = S.hooked
    if not card then return end
    if S.hookOwn then card.prerender = S.hookOwn else card.prerender = nil end
    S.hooked, S.hookOwn = nil, nil
end
function S.cardClose()
    if S.card() then pcall(ZeD_WorldWindow.closeObjectCard, S.pn) end
    S.cardUnhook()
end
-- the figure the card drew (its panel is the card)
function S.cFig()
    local c = S.card()
    if not c then return nil end
    for fig, R in pairs(S.drawn) do if R.panel == c then return fig end end
    return nil
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
-- the Character window on the Health tab, the figure unfolded, held in use
function S.onHealth()
    RT.pairOpen()
    local w = RT.cw()
    if not w then return false end
    if S.found.hfold == nil then S.found.hfold = w._healthFigureExpanded and true or false end
    w._healthFigureExpanded = true
    S.hold(w)
    return RT.charTab("health")
end
-- a panel's place on screen (its draws are panel-local; the Java draw adds the panel's y scroll)
function S.abs(panel)
    local x, y, w, h, ys = 0, 0, 0, 0, 0
    pcall(function() x, y = panel:getAbsoluteX(), panel:getAbsoluteY() end)
    pcall(function() w, h = panel:getWidth(), panel:getHeight() end)
    pcall(function() ys = panel:getYScroll() or 0 end)
    return x, y + (tonumber(ys) or 0), w, h
end
function S.rect4(x, y, w, h) return S.r(x) .. "," .. S.r(y) .. "," .. S.r(w) .. "," .. S.r(h) end
-- one NOTE line: where a figure drew on screen, for a later image check to crop it
function S.rectNote(file, which, fig, viewOf)
    local R = fig and S.drawn[fig]
    if not R then Q.say("NOTE rect " .. file .. " " .. which .. " not drawn"); return end
    local ax, ay, pw, ph = S.abs(R.panel)
    local s = tonumber(fig._drawAtS) or 1
    local cw = (Z.Spacing and Z.Spacing.figureW or 106) * s
    local ch = (Z.Spacing and Z.Spacing.figureH or 254) * s
    local fx, fy = ax + (tonumber(fig._drawAtX) or R.x), ay + (tonumber(fig._drawAtY) or R.y)
    local L = S.frames[R.panel]
    local frame = L and S.rect4(ax + L.frameX, ay + L.frameY, L.frameW, L.frameH) or "-"
    local v = viewOf and viewOf() or nil
    local view = v and S.rect4(ax + v.x, ay + v.y, v.w, v.h) or "-"
    local sw, sh = S.screen()
    Q.say("NOTE rect " .. file .. " " .. which .. " figure=" .. S.rect4(fx, fy, cw, ch) .. " box=" .. S.rect4(ax + R.x, ay + R.y, R.w, R.h)
        .. " frame=" .. frame .. " panel=" .. S.rect4(ax, ay, pw, ph) .. " view=" .. view .. " zoom=" .. S.n(s) .. " screen=" .. sw .. "x" .. sh)
end
function S.healthView() local w = RT.cw(); return w and w._healthView or nil end
-- a picture (hg_injury's S.shot: the pointer parked and hidden, the picture, the pointer back), notes() logs its rects
function S.shot(name, what, notes)
    Q.step(1, function() if not S.dead then S.park(true) end end)
    Q.step(4, function()
        if S.dead then S.park(false); return end
        local file = name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then
            Q.say("NOTE picture Zomboid/Screenshots/" .. file .. " | " .. what)
            if notes then
                local okN, eN = pcall(notes, file)
                if not okN then Q.say("NOTE the rects of " .. file .. " could not be read: " .. tostring(eN)) end
            end
        else Q.say("NOTE the picture " .. name .. " was not taken: " .. tostring(e)) end
        S.park(false)
    end)
    Q.waitMs(1500)
end

-- ===================================================================== start
function S.start()
    S.err0 = S.errN()
    local HT = Z and Z.HealthTab
    local F = ZeD_BodyFigure
    local ready = HT ~= nil and HT.gatherData ~= nil and HT.figureColor ~= nil and HT.sevColor ~= nil and HT.healthColor ~= nil
        and HT.strainColor ~= nil and HT.injuryList ~= nil and F ~= nil and F.drawAt ~= nil and ZeD.applyTheme ~= nil
        and Z.ObjectCards ~= nil and Z.ObjectCards.kinds ~= nil and Z.ObjectCards.kinds.medic ~= nil and ZeD_WorldWindow ~= nil
        and ZeD_WorldWindow.openObjectCard ~= nil and S.bd() ~= nil
    if not Q.check(ready, "the Health tab, its tint reads, the body figure, the themes and the medical card are loaded") then
        S.dead = true
        return
    end
    Q.check(HT.tintPart ~= nil and F.clearPartColor ~= nil,
        "Build's no-tint read is in this build (HealthTab.tintPart, ZeD_BodyFigure:clearPartColor: fix/notint c4f2f1de7)",
        "tintPart " .. tostring(HT.tintPart ~= nil) .. ", clearPartColor " .. tostring(F.clearPartColor ~= nil))
    local f = S.found
    f.pair = RT.isOpen()
    local w = RT.cw()
    f.tab = w and w._activeTab or nil
    f.tfold = w and (w._thermalFigureExpanded and true or false) or nil
    local ww = RT.ww()
    f.wtab = ww and ww._activeTab or nil
    f.card = S.card() ~= nil
    f.base, f.accent, f.size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    f.god = S.p:isGodMod()
    pcall(function() f.inv = S.p:isInvincible() end)
    f.speed = S.gameSpeed()
    f.doc = S.doc()
    f.pain = S.stat("PAIN")
    local bd = S.bd()
    f.zInf = false
    pcall(function() f.zInf = bd:isInfected() end)
    f.parts = {}
    for _, P in ipairs(S.PARTS) do f.parts[P.bp] = S.snap(S.part(P.bp)) end
    f.recorded = true
    S.back.on = true
    Q.say("found: theme " .. tostring(f.base) .. " / " .. tostring(f.accent) .. " / " .. tostring(f.size) .. ", First Aid "
        .. tostring(f.doc) .. ", god " .. tostring(f.god) .. ", speed " .. tostring(f.speed) .. ", infected " .. tostring(f.zInf)
        .. ", card open " .. tostring(f.card) .. ", screen " .. S.sizeTag() .. ", UI scale " .. tostring(Z.T and Z.T.scale))
    if f.card then Q.say("NOTE a card was open at the start: the medical card takes its place and is closed at the end") end
    -- the run's state: speed 1, the guard before god mode goes off, First Aid 10, every part clean
    S.speed(1)
    S.live = true
    Events.OnTick.Add(S.safety)
    pcall(function() S.p:setInvincible(true) end)
    pcall(function() S.p:setGodMod(false) end)
    Q.check(S.p:isGodMod() == false, "god mode is off for the run (it heals a wound at once), the guard is on", "was " .. tostring(f.god))
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
    S.wrapOn()
    S.wKeep = { drawAt = S.w0.drawAt, frame = S.w0.frame }
    RT.pairOpen()
end

-- ===================================================================== one theme
function S.buildTheme(TH)
    local lab = TH.say
    local sz = S.sizeTag()
    -- the theme, the clean body, the Health tab
    Q.step(5, function()
        if S.dead then return end
        S.e0 = S.errN()
        S.theme(TH.key)
        S.unstage()
        S.allClean()
        S.pbBad = {}
    end)
    Q.waitMs(800)
    Q.step(1, function()
        if S.dead then return end
        Q.check(ZeD.currentBase == TH.key and S.onHealth(), lab .. ": the theme is on and the Character window shows the Health tab",
            "theme " .. tostring(ZeD.currentBase) .. ", tab " .. tostring(RT.cw() and RT.cw()._activeTab))
        S.refresh()
    end)
    -- (a) healthy
    local tH = {}
    S.until1(2, 300, S.readThenDraw(tH, function() return S.clean(S.data()) end, S.hFig), function(ok)
        local d = S.data()
        if not ok then
            Q.check(false, lab .. " healthy: the tab read the clean body and drew it within 300 frames",
                "wounded " .. tostring(d and d.woundedCount) .. ", strained " .. tostring(d and d.strainedCount))
        end
        S.figCheck(lab .. " healthy, the Health figure", S.hFig(), d, false)
    end)
    S.shot("hg_tint_" .. TH.tag .. "_healthy_" .. sz, "the Health tab in " .. lab .. ", the healthy body: the skeleton with no tint",
        function(file) S.rectNote(file, "health", S.hFig(), S.healthView) end)
    -- (b) injured and strained
    Q.step(2, function()
        if S.dead then return end
        local miss = S.stageHurt()
        Q.check(#miss == 0, lab .. ": the body staged (a scratch, a deep wound, a bite, minor and heavy strain, the stiffness held)",
            #miss == 0 and "5 parts" or ("not taken: " .. table.concat(miss, ", ")))
        S.refresh()
    end)
    local tB = {}
    S.until1(2, 300, S.readThenDraw(tB, function()
        local d = S.data()
        return d ~= nil and d ~= S.oldData and S.hurtReady(d)
    end, S.hFig), function(ok)
        local d = S.data()
        if not ok then
            local sv = {}
            for _, P in ipairs(S.PARTS) do
                local fn = S.figName(d, P.bp, P.fig)
                local x = d and d.partSev and d.partSev[fn]
                local y = d and d.partStrain and d.partStrain[fn]
                if x or y then sv[#sv + 1] = fn .. " " .. tostring(x) .. "/" .. tostring(y) end
            end
            Q.check(false, lab .. " hurt: the tab read each wound at its severity and each strain at its level, and drew it, within 300 frames",
                "partSev " .. tostring(d and d.partSev ~= nil) .. "; " .. ((#sv > 0) and table.concat(sv, ", ") or "nothing read"))
        end
        S.figCheck(lab .. " hurt, the Health figure", S.hFig(), d, true)
        local db = d and S.dotProblems(d) or { "no read" }
        Q.check(#db == 0, lab .. " hurt: each injured part's list dot has the severity its figure tint takes (partSev), the strain rows their levels",
            #db == 0 and "3 wound rows, 2 strain rows" or table.concat(db, "; "))
    end)
    S.shot("hg_tint_" .. TH.tag .. "_hurt_" .. sz, "the Health tab in " .. lab .. ": a scratch on the left forearm, a deep wound on the right thigh, a bite on the right hand, minor strain on the left upper arm, heavy on the right",
        function(file) S.rectNote(file, "health", S.hFig(), S.healthView) end)
    -- (c) the medical check card, the same body
    S.buildCard(TH, lab, sz)
    -- (d) Thermal, Dark only
    if TH.thermal then S.buildThermal(TH, lab, sz) end
    -- the body clean again, the theme's errors
    Q.step(2, function()
        if S.dead then return end
        S.unstage()
        S.allClean()
        local e1 = S.errN()
        Q.check(S.e0 == nil or e1 == nil or e1 == S.e0, lab .. ": no Lua error in the theme's run",
            (S.e0 and e1) and ((e1 - S.e0) .. " new") or "the count cannot be read")
        Q.check(#S.pbBad == 0, lab .. ": every part put back to clean after the theme's run, the stiffness hold off",
            #S.pbBad == 0 and "17 parts" or table.concat(S.pbBad, "; "))
        S.pbBad = {}
    end)
end
function S.buildCard(TH, lab, sz)
    Q.step(3, function()
        if S.dead then return end
        S.onHealth()
        local ok, why = S.medOpen()
        S.medOff = not ok
        if not ok then Q.check(false, lab .. " card: the medical check card opens on the World window", why); return end
        S.cardW = S.CARD_W
        S.cardHook()
        local ww = RT.ww()
        if ww then S.hold(ww) end
    end)
    local tC = {}
    S.until1(5, 600, S.readThenDraw(tC, function()
        if S.medOff then return true end
        S.cardHook()
        local c, t = S.card(), S.entryT()
        return c ~= nil and t ~= nil and t == S.medT and t.d ~= nil and S.hurtReady(t.d)
            and math.abs(c:getWidth() - Z.T.px(S.CARD_W)) <= 2
    end, function() return S.medOff and S.hFig() or S.cFig() end), function(ok)
        if S.medOff then return end
        local c, t = S.card(), S.entryT()
        local fig = S.cFig()
        Q.check(ok and fig ~= nil, lab .. " card: open, " .. S.CARD_W .. " units wide, its read has the staged body, its figure drawn",
            "width " .. tostring(c and S.n(c:getWidth() / (Z.T.scale or 1))) .. " units, read " .. tostring(t and t.d ~= nil)
            .. ", hurt read " .. tostring(t and t.d and S.hurtReady(t.d)) .. ", figure " .. tostring(fig ~= nil))
        Q.check(fig == nil or fig ~= S.hFig(), lab .. " card: the card draws its own figure (not the Health tab's)")
        S.figCheck(lab .. " card, the medical card's figure", fig, t and t.d, true)
    end)
    S.shot("hg_tint_" .. TH.tag .. "_medcard_" .. sz, "the medical check card (a stand-in patient: his own body) at " .. S.CARD_W .. " units in " .. lab .. ", the same body",
        function(file)
            if S.medOff then Q.say("NOTE rect " .. file .. " card not open"); return end
            S.rectNote(file, "card", S.cFig(), nil)
            S.rectNote(file, "health", S.hFig(), S.healthView)
        end)
    Q.step(2, function() S.cardClose() end)
    S.until1(2, 120, function() return S.card() == nil end, function(ok)
        Q.check(ok and S.hooked == nil and S.drawerOrig == nil, lab .. " card: closed, its width hold off")
    end)
end
function S.buildThermal(TH, lab, sz)
    Q.step(2, function()
        if S.dead then return end
        local w = RT.cw()
        if w then
            if S.found.tfold == nil then S.found.tfold = w._thermalFigureExpanded and true or false end
            w._thermalFigureExpanded = true
        end
        S.thermalOpen = RT.charTab("thermal")
        S.drawn = {}
    end)
    S.until1(2, 300, function() local f = S.tFig(); return f ~= nil and S.drawn[f] ~= nil end, function(ok)
        local fig = S.tFig()
        Q.check(ok and fig ~= nil and fig ~= S.hFig() and fig.boneLift ~= true,
            lab .. " thermal: the Thermal figure is unchanged (no boneLift)",
            "tab " .. tostring(RT.cw() and RT.cw()._activeTab) .. ", opened " .. tostring(S.thermalOpen) .. ", figure "
            .. tostring(fig ~= nil) .. ", boneLift " .. tostring(fig and fig.boneLift))
    end)
    S.shot("hg_tint_" .. TH.tag .. "_thermal_" .. sz, "the Thermal tab in " .. lab .. " with the same body: its figure unchanged",
        function(file) S.rectNote(file, "thermal", S.tFig(), nil) end)
    Q.step(2, function() if not S.dead then S.onHealth() end end)
end

-- ===================================================================== the run
function S.build()
    Q.step(10, S.start)
    S.until1(10, 180, function() local w = RT.cw(); return w ~= nil and w:isReallyVisible() and w._tabStripPanel ~= nil end, function(ok)
        Q.check(ok and S.onHealth(), "the Character window opens on the Health tab, the figure unfolded")
    end)
    for _, TH in ipairs(S.THEMES) do S.buildTheme(TH) end
end

-- ===================================================================== put back
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    S.park(false)
    S.unstage()
    S.cardClose()
    S.wrapOff()
    S.unholdAll()
    local f = S.found
    for _, P in ipairs(S.PARTS) do S.restore(S.part(P.bp), f.parts[P.bp]) end
    local bd = S.bd()
    if bd and f.zInf == false then pcall(S.noInfection, bd) end
    S.setStat("PAIN", f.pain)
    S.setDoc(f.doc)
    if S.bailed then pcall(function() S.p:setGodMod(true) end)
    else pcall(function() S.p:setGodMod(f.god and true or false) end) end
    if f.inv ~= nil then pcall(function() S.p:setInvincible(f.inv) end) end
    S.speed(f.speed)
    S.live = false
    pcall(function() Events.OnTick.Remove(S.safety) end)
    if f.base and (ZeD.currentBase ~= f.base or ZeD.currentAccent ~= f.accent or ZeD.currentSize ~= f.size) then
        pcall(ZeD.applyTheme, f.base, f.accent, f.size)
    end
    S.putDiff = {}
    for _, P in ipairs(S.PARTS) do
        for _, x in ipairs(S.snapDiff(f.parts[P.bp] or {}, S.snap(S.part(P.bp)))) do S.putDiff[#S.putDiff + 1] = P.bp .. " " .. x end
    end
    local w = RT.cw()
    if w and f.hfold ~= nil then w._healthFigureExpanded = f.hfold end
    if w and f.tfold ~= nil then w._thermalFigureExpanded = f.tfold end
end
function S.buildPutBack()
    Q.mark()
    Q.step(5, function()
        if not S.back.on then return end
        S.putBack()
        Q.check(#S.putDiff == 0, "put back: every part exactly as found (every flag and clock, bandage and its type, splint and its item, bite, infection, health, stiffness, pain)",
            #S.putDiff == 0 and "17 parts" or table.concat(S.putDiff, "; "))
        if S.found.pair then RT.pairOpen() else RT.pairShut() end
    end)
    Q.waitFor(5, 120, function() return RT.isOpen() == (S.found.pair == true) end, function(ok)
        local f = S.found
        if f.pair and f.tab and f.tab ~= "health" then RT.charTab(f.tab) end
        local ww = RT.ww()
        if f.pair and f.wtab and ww and ww._activeTab ~= f.wtab then RT.worldTab(f.wtab) end
        Q.check(ok, "put back: the window pair " .. (f.pair and "open" or "shut") .. " as found")
    end)
    Q.step(20, function()
        local f = S.found
        local p = S.p
        if not f.recorded then
            Q.skip("put back", "nothing was staged (the modules were not loaded)")
            return
        end
        local w, ww = RT.cw(), RT.ww()
        if f.pair and f.tab then Q.check(w ~= nil and w._activeTab == f.tab, "put back: the Character window's tab", tostring(w and w._activeTab)) end
        if f.pair and f.wtab then Q.check(ww ~= nil and ww._activeTab == f.wtab, "put back: the World window's tab", tostring(ww and ww._activeTab)) end
        Q.check(ZeD.currentBase == f.base and ZeD.currentAccent == f.accent and ZeD.currentSize == f.size,
            "put back: the theme as found", tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent) .. " / " .. tostring(ZeD.currentSize))
        Q.check(S.card() == nil and S.hooked == nil and S.drawerOrig == nil, "put back: the medical card closed, its width hold off")
        local M = Z.Molecules
        Q.check(S.wKeep ~= nil and ZeD_BodyFigure.drawAt == S.wKeep.drawAt and (S.wKeep.frame == nil or (M and M.drawFigureFrame == S.wKeep.frame))
            and not S.keeping and #S.held == 0 and S.parked == nil,
            "put back: the figure's own drawAt and frame, no stiffness hold, no window held, the pointer the game's")
        Q.check(S.doc() == f.doc, "put back: First Aid as found", tostring(S.doc()))
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
            Q.check(e1 == S.err0, "the tint run ran with no Lua error", (e1 - S.err0) .. " new")
        else
            Q.skip("the tint run's Lua error count", "the game's Lua error count cannot be read here")
        end
    end)
end

S.build()
S.buildPutBack()
Q.start()
