-- ZeDUI/tools/qa/vk8_wounds.lua  (Nov 22 2026, QA; tag vk8_wnd): the in-game proof of branch wounds, Design's body
-- figure (ZeDUI/HANDOFF_design_body_wounds_20261122.md; merged in main at 8bc420cf1): flesh, wounds and their care on
-- the figure, each mark on a fading patch of the character's skin, and the height chart in the frame's margins.
-- Run after zedqa_prelude.lua and rt_kit.lua (vk8.txt). grep "ZEDQA vk8_wnd".
--
-- Staged on the QA character with the game's own BodyPart setters (never a bite; the zombie infection is cleared on
-- every tick; the only infection is a wound infection on the scratch, held at 0.1, for the First Aid rule):
--   Hand_L       a scratch (infected wound, level 0.1)    -> a scratch mark on skin; the ring only to First Aid 9+
--   ForeArm_R    a laceration, bleeding                   -> a cut mark on skin, blood below it
--   UpperLeg_L   a deep wound with glass                  -> the gash and the shards on skin
--   UpperArm_L   a bandage, clean                         -> gauze, no mark, no skin
--   UpperArm_R   a bandage, dirty (its life spent)        -> the bloody gauze
--   LowerLeg_R   a fracture, splinted                     -> the crack (no skin) and the boards
--   ForeArm_L    a deep wound, stitched                   -> stitches, no gash
-- The checks read what the figure is handed (gatherData's woundsByFigure, the figure's own wounds table) and what it
-- draws: ZeD_BodyFigure._drawWounds and drawChart are wrapped, and each call's panel draws are recorded for that frame
-- (the picture's name, where, its tint). A mark is "on the right part" when its middle lies in that part's rect
-- (getPartRects, the stops the pad uses).
--   start     a new figure starts with wounds = {} and skinTone = 0; god mode off, the guard on; First Aid 0
--   health    each staged part on the Health tab's figure: the read, the figure's table and the draws; no infected
--             ring at First Aid 0; the skin tone is the character's (skinToneOf) and tints the skin; the chart draws
--             in the frame's margins (lines, the floor, words where the lines hold them)
--   tone      the character's skin tone changed (HumanVisual.setSkinTextureIndex, put back at once): the figure
--             follows and the skin's tint changes
--   first aid First Aid 10: the infected ring shows round the scratch (picture vk8_health_wounds)
--   thermal   the Thermal and the Equipment defense figures draw no wound (their own colors), the chart by design
--   card      the medical check card (a stand-in patient: his own body) held to 336 and to the 220 half card: each
--             staged part on the card's figure; the frame, then the chart, then the focus marks and the figure; 336
--             in halves shows the lines only, 220 stacked the words (Build; at 4K and 1080p, Design's table), and the
--             words always where the lines hold them (pictures vk8_medcard_336, vk8_medcard_220)
--   lite      Lite: no chart, the wounds still draw (picture vk8_lite); Full brings the chart back
-- Puts back: each staged part exactly as found (every flag and clock, the bandage, splint, stitches, fracture, health,
-- stiffness, pain), every part's health, the pain stat, First Aid, the skin tone, ISHealthPanel.cheat, Style, god mode,
-- invincible, the game speed, the card closed, the folds, the windows and the tab; no wrapper left. No Lua error.
if not RT then print("ZEDQA vk8_wnd ERR rt_kit.lua did not run first"); print("ZEDQA vk8_wnd DONE"); return end
local Q = RT.make("vk8_wnd")
Q.maxMs = 600000                     -- (the runner gives this script 900 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, rec = {}, chart = {}, ord = {}, seq = 0, live = false,
            t0 = getTimestampMs(), held = {}, back = {} }
local Z = ZeD

S.INF = 0.1                          -- the scratch's wound infection: hidden to First Aid 0 (1 < 2.5), shown to 9+
S.NOTE_W = { left = 23, right = 24 } -- the widest script picture a side (ZeD_BodyFigure CHART.notes, both sexes)
S.CHART_M = 2                        -- the art pixels the lines keep clear (CHART.margin)
S.SKIN = { { r = 1.000, g = 0.849, b = 0.677 }, { r = 0.996, g = 0.750, b = 0.518 }, { r = 0.862, g = 0.629, b = 0.426 },
           { r = 0.548, g = 0.352, b = 0.222 }, { r = 0.372, g = 0.246, b = 0.130 } }   -- (ZeD_BodyFigure SKIN_TINT, tones 0 to 4)
S.WOUND_FNS = { "drawTextureScaledUniform" }
S.CHART_FNS = { "drawTextureScaled", "drawRect" }
S.PARTS = {
    { id = "scratch", bp = "Hand_L", fig = "Left Hand", sfx = "hand-l", marks = { "scratch" }, inf = true,
      say = "its scratch on a patch of skin (the infected ring by First Aid)",
      apply = function(b) b:setScratched(true, true); b:setScratchTime(15); b:setInfectedWound(true); b:setWoundInfectionLevel(0.1) end,
      has = function(b) return b:scratched() and b:isInfectedWound() end },
    { id = "laceration, bleeding", bp = "ForeArm_R", fig = "Right Forearm", sfx = "wrist-r", marks = { "cut" }, bleed = true,
      say = "its cut on a patch of skin, blood below it",
      apply = function(b) b:setCut(true); b:setCutTime(15); b:setBleeding(true); b:setBleedingTime(10) end,
      has = function(b) return b:isCut() and b:bleeding() end },
    { id = "deep wound with glass", bp = "UpperLeg_L", fig = "Left Upper Leg", sfx = "thigh-l", marks = { "deep", "glass" },
      say = "the gash and the shards on a patch of skin",
      apply = function(b) b:setDeepWounded(true); b:setDeepWoundTime(15); b:setBleedingTime(10); b:setHaveGlass(true) end,
      has = function(b) return b:deepWounded() and b:haveGlass() end },
    { id = "clean bandage", bp = "UpperArm_L", fig = "Left Upper Arm", sfx = "bicep-l", bandage = "clean",
      pics = { "bandage" }, notPics = { "bandage-dirty" }, say = "clean gauze, no mark",
      apply = function(b) b:setBandaged(true, 10) end,
      has = function(b) return b:bandaged() and b:getBandageLife() > 0 end },
    { id = "dirty bandage", bp = "UpperArm_R", fig = "Right Upper Arm", sfx = "bicep-r", bandage = "dirty",
      pics = { "bandage-dirty" }, notPics = { "bandage" }, say = "the bloody gauze, no mark",
      apply = function(b) b:setBandaged(true, 0) end,
      has = function(b) return b:bandaged() and b:getBandageLife() <= 0 end },
    { id = "splint (fracture set)", bp = "LowerLeg_R", fig = "Right Lower Leg", sfx = "ankle-r", splint = true, fracture = true,
      pics = { "splint", "fracture" }, say = "the crack in the bone (no skin) and the boards",
      apply = function(b) b:setFractureTime(40); b:setSplint(true, 1.0) end,
      has = function(b) return b:getFractureTime() > 0 and b:getSplintFactor() > 0 end },
    { id = "stitches", bp = "ForeArm_L", fig = "Left Forearm", sfx = "wrist-l", marks = { "stitch" }, notMarks = { "deep" },
      say = "stitches on a patch of skin, no gash",
      apply = function(b) b:setDeepWounded(true); b:setDeepWoundTime(15); b:setStitched(true); b:setStitchTime(10) end,
      has = function(b) return b:stitched() and not b:deepWounded() end },
}
-- what is read of a part and put back exactly: { field, getter }
S.GETS = { { "scratched", "scratched" }, { "scratchTime", "getScratchTime" }, { "cut", "isCut" }, { "cutTime", "getCutTime" },
           { "bleeding", "bleeding" }, { "bleedingTime", "getBleedingTime" }, { "deep", "deepWounded" },
           { "deepTime", "getDeepWoundTime" }, { "glass", "haveGlass" }, { "bandaged", "bandaged" },
           { "bandageLife", "getBandageLife" }, { "splint", "isSplint" }, { "splintFactor", "getSplintFactor" },
           { "fractureTime", "getFractureTime" }, { "stitched", "stitched" }, { "stitchTime", "getStitchTime" },
           { "infectedWound", "isInfectedWound" }, { "woundInfection", "getWoundInfectionLevel" }, { "health", "getHealth" },
           { "stiffness", "getStiffness" }, { "addPain", "getAdditionalPain" }, { "bitten", "bitten" } }
-- the clocks and amounts put back after the flags: { setter, field }
S.SETS = { { "setScratchTime", "scratchTime" }, { "setCutTime", "cutTime" }, { "setDeepWoundTime", "deepTime" },
           { "setBleedingTime", "bleedingTime" }, { "setStitchTime", "stitchTime" }, { "setSplintFactor", "splintFactor" },
           { "setFractureTime", "fractureTime" }, { "setBandageLife", "bandageLife" },
           { "setWoundInfectionLevel", "woundInfection" }, { "setStiffness", "stiffness" }, { "setAdditionalPain", "addPain" },
           { "SetHealth", "health" } }

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
function S.inList(list, x) for _, v in ipairs(list or {}) do if v == x then return true end end; return false end
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
function S.hv() local h = nil; pcall(function() h = S.p:getHumanVisual() end); return h end
function S.tone()
    local h, v = S.hv(), nil
    if h then pcall(function() v = h:getSkinTextureIndex() end) end
    return v
end
function S.setTone(i)
    local h = S.hv()
    if h and i ~= nil then pcall(function() h:setSkinTextureIndex(i) end) end
end
function S.stats() local st = nil; pcall(function() st = S.p:getStats() end); return st end
function S.stat(k)
    local st, v = S.stats(), nil
    if st and CharacterStat[k] then pcall(function() v = st:get(CharacterStat[k]) end) end
    return v
end
function S.setStat(k, v)
    local st = S.stats()
    if st and v ~= nil and CharacterStat[k] then pcall(function() st:set(CharacterStat[k], v) end) end
end
function S.style() local v = nil; pcall(function() v = Z.Settings.lookStyleOption:getValue() end); return v end
function S.setStyle(n)
    local o = Z.Settings and Z.Settings.lookStyleOption
    if o and n ~= nil and S.style() ~= n then pcall(function() o:setValue(n) end) end
end
function S.lite() local v = false; pcall(function() v = Z.Settings.lite() end); return v == true end
function S.screenH() local h = 0; pcall(function() h = RT.core:getScreenHeight() end); return h end

-- ===================================================================== the body: read, stage, put back
function S.snap(bp)
    local f = {}
    if not bp then return f end
    for _, g in ipairs(S.GETS) do
        local m = g[2]
        pcall(function() f[g[1]] = bp[m](bp) end)
    end
    return f
end
-- what differs between two reads of a part ("field now (was x)")
function S.snapDiff(a, b)
    local diff = {}
    for _, g in ipairs(S.GETS) do
        local k = g[1]
        local x, y = a[k], b[k]
        local same
        if type(x) == "number" and type(y) == "number" then same = math.abs(x - y) < ((k == "health") and 0.5 or 0.01)
        else same = (x == y) end
        if not same then diff[#diff + 1] = k .. " " .. tostring(y) .. " (was " .. tostring(x) .. ")" end
    end
    return diff
end
-- a part healed of what this script put on it, then set as found (BodyPart.setStitched(false) on a fresh stitch reopens
-- the deep wound, so the stitches come off before the wound flags are lowered)
function S.restore(bp, f)
    if not (bp and f) then return end
    -- (the gauze off only where there is gauze: BodyPart.setBandaged(false, ...) also raises each wound whose clock
    -- still runs and resets the poultice; the flags come down just below)
    local band = false
    pcall(function() band = bp:bandaged() end)
    if band then pcall(function() bp:setBandaged(false, 0) end) end
    pcall(function() bp:setStitched(false) end)
    pcall(function() bp:setSplint(false, 0) end)
    pcall(function() bp:setDeepWounded(false) end)
    pcall(function() bp:setHaveGlass(false) end)
    pcall(function() bp:setScratched(false, true) end)
    pcall(function() bp:setCut(false) end)
    pcall(function() bp:setBleeding(false) end)
    pcall(function() bp:setInfectedWound(false) end)
    if f.scratched then pcall(function() bp:setScratched(true, true) end) end
    if f.cut then pcall(function() bp:setCut(true) end) end
    if f.deep then pcall(function() bp:setDeepWounded(true) end) end
    if f.glass then pcall(function() bp:setHaveGlass(true) end) end
    if f.bleeding then pcall(function() bp:setBleeding(true) end) end
    if f.stitched then pcall(function() bp:setStitched(true) end) end
    if f.splint then pcall(function() bp:setSplint(true, f.splintFactor or 0) end) end
    if f.infectedWound then pcall(function() bp:setInfectedWound(true) end) end
    if f.bandaged then pcall(function() bp:setBandaged(true, f.bandageLife or 0) end) end
    for _, s in ipairs(S.SETS) do
        local v, m = f[s[2]], s[1]
        if type(v) == "number" then pcall(function() bp[m](bp, v) end) end
    end
end
function S.stage()
    local bad = {}
    for _, P in ipairs(S.PARTS) do
        local bp = S.part(P.bp)
        if not bp then bad[#bad + 1] = P.bp .. ": no part"
        else
            local ok, err = pcall(P.apply, bp)
            if not ok then bad[#bad + 1] = P.bp .. ": " .. tostring(err) end
        end
    end
    S.infPart = S.part("Hand_L")
    S.staged = true
    return bad
end
-- the zombie infection off the body and every part (bx_health's way; this script makes no bite, this is the belt)
function S.noInfection(bd)
    local parts = bd:getBodyParts()
    for i = 0, parts:size() - 1 do
        local b = parts:get(i)
        if b:IsInfected() then b:SetInfected(false) end
        if b:IsFakeInfected() then b:SetFakeInfected(false) end
    end
    if bd:isInfected() then bd:setInfected(false) end
    if bd:isIsFakeInfected() then bd:setIsFakeInfected(false) end
    local st = S.stats()
    if st then
        if st:get(CharacterStat.ZOMBIE_INFECTION) > 0 then st:set(CharacterStat.ZOMBIE_INFECTION, 0) end
        if st:get(CharacterStat.ZOMBIE_FEVER) > 0 then st:set(CharacterStat.ZOMBIE_FEVER, 0) end
    end
    if bd:getInfectionTime() >= 0 then bd:setInfectionTime(-1) end
    if bd:getInfectionMortalityDuration() >= 0 then bd:setInfectionMortalityDuration(-1) end
end
-- stop the run and go to the put-back (from a step or from the guard)
function S.bail(why)
    if S.bailed then return end
    S.bailed = true
    S.dead = true
    Q.check(false, "the run went on to its end", "stopped, on to the put-back: " .. tostring(why))
    if Q.backAt and Q.qi < Q.backAt then Q.qi = Q.backAt; Q.wait = nil end
end
-- THE GUARD, on every game tick while god mode is off: no zombie infection, the scratch's infection held at S.INF,
-- health under 75 topped up on every part (the wounds stay), under 35 god mode ON and on to the put-back; a run that
-- never reaches the put-back is put back here
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
    local b = S.infPart
    if b and S.staged and b:isInfectedWound() and math.abs(b:getWoundInfectionLevel() - S.INF) > 0.001 then
        b:setWoundInfectionLevel(S.INF)
    end
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

-- ===================================================================== the draw recorder
function S.texName(tex)
    if tex == nil then return nil end
    if type(tex) == "string" then return tex end
    local nm = nil
    pcall(function() nm = tex:getName() end)
    return nm and tostring(nm) or nil
end
function S.recAdd(R, fn, a1, a2, a3, a4, a5, a6, a7, a8, a9)
    local d = { fn = fn }
    if fn == "drawRect" then
        d.x, d.y, d.w, d.h = a1, a2, a3, a4
    else
        d.name = S.texName(a1)
        d.x, d.y = a2, a3
        if fn == "drawTextureScaledUniform" then
            d.s = a4
            d.a, d.r, d.g, d.b = a5, a6, a7, a8
        else
            d.w, d.h = a4, a5
            d.a, d.r, d.g, d.b = a6, a7, a8, a9
        end
    end
    d.x, d.y = tonumber(d.x) or 0, tonumber(d.y) or 0
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
-- the order of the card's figure pieces in a frame (frame, chart, focus marks, figure)
function S.order(panel, what)
    if not (S.ordPanel and panel == S.ordPanel) then return end
    if #S.ord > 400 then S.ord = {} end
    S.seq = S.seq + 1
    S.ord[#S.ord + 1] = what
end
-- the figure's wounds pass and chart wrapped (each call's draws recorded, the last per figure), the card's order
function S.wrapOn()
    if S.w0 then return end
    local F, M, Fo = ZeD_BodyFigure, Z.Molecules, Z.Focus
    local w0 = { wounds = F._drawWounds, chart = F.drawChart, at = F.drawAt, frame = M and M.drawFigureFrame,
                 mark = Fo and Fo.mark }
    S.w0 = w0
    F._drawWounds = function(self, panel, xOff, yOff, s)
        local R = { panel = panel, s = s, x = xOff, y = yOff, list = {} }
        S.recOn(R, panel, S.WOUND_FNS)
        local ok, err = pcall(w0.wounds, self, panel, xOff, yOff, s)
        S.recOff(R)
        S.rec[self] = R
        if not ok then error(err, 0) end
    end
    F.drawChart = function(self, panel, L)
        local R = { panel = panel, L = L, list = {}, female = self.isFemale and true or false, lite = S.lite() }
        S.recOn(R, panel, S.CHART_FNS)
        local ok, err = pcall(w0.chart, self, panel, L)
        S.recOff(R)
        S.chart[self] = R
        S.order(panel, "chart")
        if not ok then error(err, 0) end
    end
    F.drawAt = function(self, panel, px, py, pw, ph)
        S.order(panel, "figure")
        return w0.at(self, panel, px, py, pw, ph)
    end
    if w0.frame then
        M.drawFigureFrame = function(panel, L, a3, a4)
            S.order(panel, "frame")
            return w0.frame(panel, L, a3, a4)
        end
    end
    if w0.mark then
        Fo.mark = function(panel, x, y, w, h, opts, rounded)
            S.order(panel, "mark")
            return w0.mark(panel, x, y, w, h, opts, rounded)
        end
    end
end
function S.wrapOff()
    local w0 = S.w0
    if not w0 then return end
    local F, M, Fo = ZeD_BodyFigure, Z.Molecules, Z.Focus
    F._drawWounds, F.drawChart, F.drawAt = w0.wounds, w0.chart, w0.at
    if w0.frame then M.drawFigureFrame = w0.frame end
    if w0.mark then Fo.mark = w0.mark end
    S.w0 = nil
end
function S.wrapsBack()
    local F, M, Fo = ZeD_BodyFigure, Z.Molecules, Z.Focus
    local w0 = S.w0k
    if not w0 then return true end
    return F._drawWounds == w0.wounds and F.drawChart == w0.chart and F.drawAt == w0.at
        and (w0.frame == nil or M.drawFigureFrame == w0.frame) and (w0.mark == nil or Fo.mark == w0.mark)
end

-- ===================================================================== what a figure was handed and drew
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
-- the figure's name for a staged part (gatherData's partByFigure), else the name the figure uses
function S.figName(data, P)
    for fig, bp in pairs(data and data.partByFigure or {}) do
        if S.typeOf(bp) == P.bp then return fig end
    end
    return P.fig
end
-- what the part's read lacks (gatherData's woundsByFigure, ZeD_BodyFigure.woundsFrom)
function S.readProblems(P, w)
    local bad = {}
    if not w then bad[1] = "nothing read for the part"; return bad end
    for _, k in ipairs(P.marks or {}) do if not S.inList(w.marks, k) then bad[#bad + 1] = "no " .. k .. " mark" end end
    for _, k in ipairs(P.notMarks or {}) do if S.inList(w.marks, k) then bad[#bad + 1] = "a " .. k .. " mark still" end end
    if w.marks and #w.marks > 2 then bad[#bad + 1] = #w.marks .. " marks (two at most)" end
    if P.bleed and w.bleed ~= true then bad[#bad + 1] = "no bleeding" end
    if P.bandage then
        if w.bandage ~= P.bandage then bad[#bad + 1] = "bandage " .. tostring(w.bandage) .. ", want " .. P.bandage end
        if w.marks then bad[#bad + 1] = "marks under the gauze" end
    end
    if P.splint and w.splint ~= true then bad[#bad + 1] = "no splint" end
    if P.fracture and w.fracture ~= true then bad[#bad + 1] = "no fracture" end
    if P.inf and ((w.infected == true) ~= (S.infWant == true)) then
        bad[#bad + 1] = "infected " .. tostring(w.infected) .. ", want " .. tostring(S.infWant == true)
    end
    return bad
end
-- what the part's draws lack (the figure's _drawWounds this frame)
function S.drawProblems(P, fig, R, fn)
    local bad = {}
    if not R then bad[1] = "no wounds pass drawn"; return bad end
    local rect = S.rectOf(fig, fn)
    if not rect then bad[#bad + 1] = "no rect for " .. tostring(fn) end
    local sx = "-" .. P.sfx .. "-"
    for _, k in ipairs(P.marks or {}) do
        if not S.markIn(R, "mark-" .. k .. ".png", rect) then bad[#bad + 1] = "mark-" .. k .. " not drawn on the part" end
    end
    for _, k in ipairs(P.notMarks or {}) do
        if S.markIn(R, "mark-" .. k .. ".png", rect) then bad[#bad + 1] = "mark-" .. k .. " drawn on the part" end
    end
    if P.bleed and not S.markIn(R, "mark-bleed.png", rect, 10 * (tonumber(R.s) or 1)) then bad[#bad + 1] = "no blood drawn" end
    local skin = #S.drawsNamed(R, sx .. "skin")
    if P.marks and skin == 0 then bad[#bad + 1] = "no skin under the marks" end
    if not P.marks and skin > 0 then bad[#bad + 1] = "skin drawn where no mark is" end
    for _, pic in ipairs(P.pics or {}) do
        if #S.drawsNamed(R, sx .. pic .. ".png") == 0 then bad[#bad + 1] = "no " .. pic .. " picture" end
    end
    for _, pic in ipairs(P.notPics or {}) do
        if #S.drawsNamed(R, sx .. pic .. ".png") > 0 then bad[#bad + 1] = "the " .. pic .. " picture drawn" end
    end
    if P.inf then
        local ring = S.markIn(R, "mark-" .. P.marks[1] .. "-infected.png", rect)
        if ring ~= (S.infWant == true) then bad[#bad + 1] = "infected ring drawn " .. tostring(ring) .. ", want " .. tostring(S.infWant == true) end
    end
    return bad
end
function S.partCheck(lab, P, fig, data, R)
    local fn = S.figName(data, P)
    local w = data and data.woundsByFigure and data.woundsByFigure[fn] or nil
    local bad = S.readProblems(P, w)
    local fw = fig and fig.wounds and fig.wounds[fn] or nil
    if S.wText(fw) ~= S.wText(w) then bad[#bad + 1] = "the figure holds " .. S.wText(fw) end
    for _, b in ipairs(S.drawProblems(P, fig, R, fn)) do bad[#bad + 1] = b end
    Q.check(#bad == 0, lab .. ": " .. P.id .. " (" .. P.bp .. ") draws " .. P.say .. " on " .. tostring(fn),
        #bad == 0 and S.wText(w) or table.concat(bad, "; "))
end
-- every staged part on one figure, and the picture names readable
function S.figureCheck(lab, fig, data)
    local R = fig and S.rec[fig] or nil
    if not Q.check(fig ~= nil and data ~= nil and R ~= nil, lab .. ": the figure drew its wounds pass with the body read",
        "figure " .. tostring(fig ~= nil) .. ", read " .. tostring(data ~= nil) .. ", pass " .. tostring(R ~= nil)) then return end
    local named = 0
    for _, d in ipairs(R.list) do if d.name then named = named + 1 end end
    Q.check(#R.list > 0 and named == #R.list, lab .. ": the wounds pass drew, every picture by name",
        #R.list .. " draws, " .. named .. " named, zoom " .. tostring(R.s))
    for _, P in ipairs(S.PARTS) do S.partCheck(lab, P, fig, data, R) end
    if S.infWant ~= true then
        local rings = #S.drawsNamed(R, "-infected.png")
        Q.check(rings == 0, lab .. ": no infected ring anywhere at First Aid " .. tostring(S.doc()), rings .. " drawn")
    end
end
-- is every staged part read as staged (the throttled reads have caught up)
function S.readReady(data)
    if not (data and data.woundsByFigure) then return false end
    for _, P in ipairs(S.PARTS) do
        if #S.readProblems(P, data.woundsByFigure[S.figName(data, P)]) > 0 then return false end
    end
    return true
end
-- the skin's tint drawn under a part's marks
function S.skinTint(R, sfx)
    local d = S.drawsNamed(R, "-" .. sfx .. "-skin")[1]
    if not d then return nil end
    return { r = tonumber(d.r), g = tonumber(d.g), b = tonumber(d.b) }
end
function S.tintText(c) return c and string.format("%.3f,%.3f,%.3f", c.r or -1, c.g or -1, c.b or -1) or "none" end
function S.sameTint(a, b) return a ~= nil and b ~= nil and S.near(a.r, b.r) and S.near(a.g, b.g) and S.near(a.b, b.b) end

-- ===================================================================== the chart
-- each margin's width in art pixels and whether its words fit (drawChart's own rule)
function S.wordsWant(L)
    if not (L and tonumber(L.zoom) and L.zoom > 0 and L.figX and L.frameX and L.frameW and L.figW) then return nil, nil, nil, nil end
    local line = Z.T.px(1)
    local z = L.zoom
    local sideL = math.floor((L.figX - (L.frameX + line)) / z)
    local sideR = math.floor((L.frameX + L.frameW - line - (L.figX + L.figW)) / z)
    local m = S.CHART_M
    return (sideL - 2 * m) >= S.NOTE_W.left, (sideR - 2 * m) >= S.NOTE_W.right, sideL, sideR
end
function S.chartRead(fig)
    local C = fig and S.chart[fig] or nil
    if not C then return nil end
    local o = { n = #C.list, lines = 0, left = 0, right = 0, rects = 0, out = 0, L = C.L, lite = C.lite }
    local L = C.L
    for _, d in ipairs(C.list) do
        if d.fn == "drawRect" then o.rects = o.rects + 1
        elseif S.has(d.name, "fig-chart-lines") then o.lines = o.lines + 1
        elseif S.has(d.name, "fig-notes-") then
            if S.has(d.name, "-left") then o.left = o.left + 1 else o.right = o.right + 1 end
        end
        -- (every picture in the frame's margins: inside the frame, off the figure's canvas)
        if d.fn ~= "drawRect" and L and L.frameX and L.figX then
            local x0 = d.x
            local x1 = d.x + (tonumber(d.w) or 0)
            local inFrame = x0 >= L.frameX - 1 and x1 <= L.frameX + L.frameW + 1
            local offFig = x1 <= L.figX + 1 or x0 >= L.figX + L.figW - 1
            if not (inFrame and offFig) then o.out = o.out + 1 end
        end
    end
    o.wantL, o.wantR, o.sideL, o.sideR = S.wordsWant(L)
    return o
end
function S.chartText(o)
    if not o then return "no chart call" end
    return "lines " .. o.lines .. ", words left " .. o.left .. " right " .. o.right .. ", floor " .. o.rects
        .. ", outside the margins " .. o.out .. "; margins " .. tostring(o.sideL) .. " / " .. tostring(o.sideR)
        .. " art px (words fit " .. tostring(o.wantL) .. " / " .. tostring(o.wantR) .. "), "
        .. ((o.L and o.L.two) and "halves" or "stacked") .. ", zoom " .. tostring(o.L and o.L.zoom)
end
-- the chart as drawChart's rule says for these margins: lines where they are longer than the clearances, the floor,
-- the words where the lines hold them, nothing outside the margins
function S.chartAsRule(o)
    if not (o and o.sideL and o.sideR) then return false end
    local wantLines = ((o.sideL > 2 * S.CHART_M) and 1 or 0) + ((o.sideR > 2 * S.CHART_M) and 1 or 0)
    return o.lines == wantLines and o.rects >= 1 and (o.left > 0) == (o.wantL == true) and (o.right > 0) == (o.wantR == true)
        and o.out == 0
end

-- ===================================================================== windows, the card, the pictures
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
function S.healthFig() local w = RT.cw(); return w and w._healthBodyFigure or nil end
function S.thermalFig() local w = RT.cw(); return w and w._thermalBodyFigure or nil end
function S.equipFig() local w = RT.cw(); return w and w._equipDefBodyFigure or nil end
function S.card() local c = nil; pcall(function() c = ZeD_WorldWindow.getObjectCard(S.pn) end); return c end
function S.entryT()
    local c = S.card()
    local e = c and c.entry
    return e and e.t or nil
end
function S.cardFig()
    local c = S.card()
    if not c then return nil end
    for fig, R in pairs(S.rec) do if R.panel == c then return fig end end
    return nil
end
-- a stand-in patient: every method call answered with the character's own (single player has no other player)
function S.proxyOf(pl)
    local px = { _vk8QaPatient = true }
    setmetatable(px, { __index = function(t, k)
        if type(k) ~= "string" then return nil end
        local m = nil
        pcall(function() m = pl[k] end)
        if m == nil then return nil end
        local f = function(self, a1, a2, a3, a4) return m(pl, a1, a2, a3, a4) end
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
-- the card's width held by its own prerender (gc_cleanup's way): S.cardW units
function S.cardHook()
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
    local card = S.hooked
    S.cardW = nil
    if not card then return end
    if S.hookOwn then card.prerender = S.hookOwn else card.prerender = nil end
    S.hooked, S.hookOwn = nil, nil
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
-- a picture: the pointer parked and hidden, three frames, the picture, the pointer back
function S.shot(name, what, skipIf)
    Q.step(1, function() if not S.dead then S.park(true) end end)
    Q.step(4, function()
        if S.dead then S.park(false); return end
        if skipIf and skipIf() then
            S.park(false)
            Q.say("NOTE the picture " .. name .. " was not taken: " .. tostring(skipIf()))
            return
        end
        local file = name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then Q.say("NOTE picture Zomboid/Screenshots/" .. file .. " | " .. what)
        else Q.say("NOTE the picture " .. name .. " was not taken: " .. tostring(e)) end
        S.park(false)
    end)
    Q.waitMs(1500)
end
-- a fresh record: the records cleared, then frames until fig() has drawn its wounds pass and its chart
function S.recQ(getFig, fn)
    Q.step(1, function() S.rec, S.chart, S.ord = {}, {}, {} end)
    Q.waitFor(6, 300, function()
        if S.dead then return true end
        local f = getFig()
        return f ~= nil and S.rec[f] ~= nil and S.chart[f] ~= nil
    end, function(ok)
        if S.dead then return end
        fn(ok, getFig())
    end)
end
function S.until1(n, max, cond, fn)
    Q.waitFor(n, max, function() return S.dead or cond() end, function(ok) if not S.dead then fn(ok) end end)
end

-- ===================================================================== start
Q.step(10, function()
    S.err0 = S.errN()
    local F = ZeD_BodyFigure
    local ready = F ~= nil and F.woundsFrom ~= nil and F.skinToneOf ~= nil and F.setPartWounds ~= nil and F.drawChart ~= nil
        and F._drawWounds ~= nil and Z.HealthTab ~= nil and Z.HealthTab.gatherData ~= nil and Z.ObjectCards ~= nil
        and Z.ObjectCards.kinds ~= nil and Z.ObjectCards.kinds.medic ~= nil and ZeD_WorldWindow ~= nil
        and ZeD_WorldWindow.openObjectCard ~= nil and Z.Settings ~= nil and Z.Settings.lookStyleOption ~= nil
        and Z.Molecules ~= nil and Z.Focus ~= nil and S.bd() ~= nil
    if not Q.check(ready, "the wounds' figure (woundsFrom, skinToneOf, setPartWounds, drawChart), the Health tab, the medical card and Style are loaded") then
        S.dead = true
        return
    end
    -- a new figure starts with no wounds and the first skin tone
    local fig = nil
    pcall(function() fig = F:new(0, 0, 10, 10) end)
    local nW = -1
    if fig and type(fig.wounds) == "table" then
        nW = 0
        for _ in pairs(fig.wounds) do nW = nW + 1 end
    end
    Q.check(fig ~= nil and nW == 0 and fig.skinTone == 0, "a new figure starts with wounds = {} and skinTone = 0",
        "wounds " .. tostring(nW) .. " entries, skinTone " .. tostring(fig and fig.skinTone))
    -- what to put back
    local f = S.found
    f.pair = RT.isOpen()
    local w = RT.cw()
    f.tab = w and w._activeTab or nil
    f.god = S.p:isGodMod()
    pcall(function() f.inv = S.p:isInvincible() end)
    f.speed = S.gameSpeed()
    f.cheat = ISHealthPanel and ISHealthPanel.cheat
    f.doc = S.doc()
    f.tone = S.tone()
    f.style = S.style()
    f.pain = S.stat("PAIN")
    local bd = S.bd()
    f.zInf = false
    pcall(function() f.zInf = bd:isInfected() end)
    f.hp, f.hurt = {}, {}
    pcall(function()
        local parts = bd:getBodyParts()
        for i = 0, parts:size() - 1 do
            local b = parts:get(i)
            f.hp[i] = b:getHealth()
            if b:HasInjury() then f.hurt[S.typeOf(b) or i] = true end
        end
    end)
    for _, P in ipairs(S.PARTS) do P.f0 = S.snap(S.part(P.bp)) end
    f.recorded = true
    S.back.on = true
    Q.say("found: First Aid " .. tostring(f.doc) .. ", skin tone " .. tostring(f.tone) .. ", Style " .. tostring(f.style)
        .. ", god " .. tostring(f.god) .. ", speed " .. tostring(f.speed) .. ", cheat " .. tostring(f.cheat)
        .. ", screen " .. RT.core:getScreenWidth() .. "x" .. S.screenH() .. ", UI scale " .. tostring(Z.T.scale))
    -- the run's state: speed 1, the guard before god mode goes off, the debug cheat off, First Aid 0, Full
    S.speed(1)
    S.live = true
    Events.OnTick.Add(S.safety)
    pcall(function() S.p:setInvincible(true) end)
    pcall(function() S.p:setGodMod(false) end)
    Q.check(S.p:isGodMod() == false, "god mode is off for the run (it heals a wound at once), the guard is on", "was " .. tostring(f.god))
    if ISHealthPanel then ISHealthPanel.cheat = false end
    S.setDoc(0)
    S.setStyle(1)
    S.wrapOn()
    S.w0k = S.w0
    -- the wounds
    local bad = S.stage()
    local miss = {}
    for _, P in ipairs(S.PARTS) do
        local bp = S.part(P.bp)
        local ok, yes = false, false
        if bp then ok, yes = pcall(P.has, bp) end
        if not (ok and yes) then miss[#miss + 1] = P.id end
    end
    Q.check(#bad == 0 and #miss == 0, "staged: the game reads each wound and its care back (scratch, laceration, deep wound and glass, clean and dirty bandage, splinted fracture, stitches)",
        #bad + #miss == 0 and "all seven" or (table.concat(bad, "; ") .. " | not read: " .. table.concat(miss, ", ")))
    Q.check(S.doc() == 0, "First Aid is 0 for the first look", tostring(S.doc()))
    S.infWant = false
    RT.pairOpen()
end)
S.until1(10, 180, function() local w = RT.cw(); return w ~= nil and w:isReallyVisible() and w._tabStripPanel ~= nil end, function(ok)
    local w = RT.cw()
    if w then
        if S.found.hfold == nil then S.found.hfold = w._healthFigureExpanded and true or false end
        w._healthFigureExpanded = true
        S.hold(w)
    end
    Q.check(ok and RT.charTab("health"), "the Character window opens on the Health tab")
end)

-- ===================================================================== the Health tab, First Aid 0
S.until1(5, 600, function()
    local w = RT.cw()
    return w ~= nil and w._activeTab == "health" and S.readReady(w._healthCache)
end, function(ok)
    local w = RT.cw()
    local d = w and w._healthCache
    local why = {}
    for _, P in ipairs(S.PARTS) do
        local fn = S.figName(d, P)
        local b = S.readProblems(P, d and d.woundsByFigure and d.woundsByFigure[fn])
        if #b > 0 then why[#why + 1] = P.id .. ": " .. table.concat(b, ", ") end
    end
    Q.check(ok, "Health: the tab reads every staged wound within a few reads (woundsByFigure)", #why == 0 and "all seven" or table.concat(why, "; "))
end)
S.recQ(S.healthFig, function(ok, fig)
    local w = RT.cw()
    local d = w and w._healthCache
    S.figureCheck("Health (First Aid 0)", fig, d)
    -- the skin tone: the character's, handed to the figure, tinting the skin
    local R = fig and S.rec[fig]
    local tone = S.tone()
    local want = ZeD_BodyFigure.skinToneOf(S.p)
    S.tintA = S.skinTint(R, "hand-l")
    Q.check(tone ~= nil and want == tone and d ~= nil and d.skinTone == tone and fig ~= nil and fig.skinTone == tone
        and S.sameTint(S.tintA, S.SKIN[tone + 1]),
        "Health: the skin tone is the character's (getSkinTextureIndex) and tints the skin under the marks",
        "game " .. tostring(tone) .. ", skinToneOf " .. tostring(want) .. ", read " .. tostring(d and d.skinTone) .. ", figure "
        .. tostring(fig and fig.skinTone) .. ", tint " .. S.tintText(S.tintA))
    -- the chart in Full
    local o = S.chartRead(fig)
    Q.check(o ~= nil and o.lite == false and S.chartAsRule(o),
        "Health (Full): the height chart draws in the frame's margins (lines, the floor, words where the lines hold them)", S.chartText(o))
    Q.check(o ~= nil and o.left > 0 and o.right > 0, "Health (Full): words on both sides (Design's table: the Health tab on every screen)", S.chartText(o))
end)

-- ===================================================================== the skin tone changed
Q.step(2, function()
    if S.dead then return end
    local a = S.found.tone or 0
    S.toneB = (a <= 2) and 4 or 0
    S.setTone(S.toneB)
end)
S.until1(5, 300, function()
    local w = RT.cw()
    return w ~= nil and w._healthCache ~= nil and w._healthCache.skinTone == S.toneB
end, function(ok)
    Q.check(ok, "tone: the Health tab reads the new skin tone", "want " .. tostring(S.toneB))
end)
S.recQ(S.healthFig, function(ok, fig)
    local R = fig and S.rec[fig]
    local tint = S.skinTint(R, "hand-l")
    Q.check(fig ~= nil and fig.skinTone == S.toneB and S.sameTint(tint, S.SKIN[S.toneB + 1]) and not S.sameTint(tint, S.tintA),
        "tone: the skin tone applies: the figure takes tone " .. tostring(S.toneB) .. " and the skin's tint changes",
        "figure " .. tostring(fig and fig.skinTone) .. ", tint " .. S.tintText(tint) .. " (was " .. S.tintText(S.tintA) .. ")")
    S.setTone(S.found.tone)
end)
S.until1(5, 300, function()
    local fig = S.healthFig()
    return fig ~= nil and fig.skinTone == S.found.tone
end, function(ok)
    Q.check(ok and S.tone() == S.found.tone, "tone: put back at once, the figure follows", tostring(S.tone()))
end)

-- ===================================================================== First Aid 10: the infection shows
Q.step(2, function()
    if S.dead then return end
    S.setDoc(10)
    S.infWant = true
end)
S.until1(5, 300, function()
    local w = RT.cw()
    return w ~= nil and S.readReady(w._healthCache)
end, function(ok)
    Q.check(ok and S.doc() == 10, "First Aid 10: the Health tab names the scratch's infection (woundsByFigure .infected)", "First Aid " .. tostring(S.doc()))
end)
S.recQ(S.healthFig, function(ok, fig)
    local w = RT.cw()
    local d = w and w._healthCache
    local R = fig and S.rec[fig]
    S.partCheck("Health (First Aid 10)", S.PARTS[1], fig, d, R)
end)
S.shot("vk8_health_wounds", "the Health tab's figure: every wound and its care, the infected ring at First Aid 10, the chart")

-- ===================================================================== Thermal and Equipment: no wounds
S.OTHER = {
    { tab = "thermal", say = "Thermal", fig = S.thermalFig },
    { tab = "equip", say = "Equipment's defense", fig = S.equipFig },
}
for _, O in ipairs(S.OTHER) do
    Q.step(3, function()
        if S.dead then return end
        local w = RT.cw()
        if not w then return end
        if O.tab == "thermal" then
            if S.found.tfold == nil then S.found.tfold = w._thermalFigureExpanded and true or false end
            w._thermalFigureExpanded = true
        else
            if S.found.esel == nil then S.found.esel = w._equipSelected or false end
            w._equipSelected = nil
        end
        O.open = RT.charTab(O.tab)
    end)
    S.recQ(O.fig, function(ok, fig)
        local what = O.say .. ": the figure draws no wound (its own colors), the chart by design"
        if not fig then Q.check(false, what, "no figure (tab opened " .. tostring(O.open) .. ")"); return end
        if not ok then Q.skip(what, "the figure did not draw in 300 frames (tab " .. tostring(RT.cw() and RT.cw()._activeTab) .. ")"); return end
        local R = S.rec[fig]
        local n = 0
        for _ in pairs(fig.wounds or {}) do n = n + 1 end
        local o = S.chartRead(fig)
        Q.check(R ~= nil and #R.list == 0 and n == 0 and o ~= nil and o.lines > 0 and o.rects >= 1, what,
            "wound draws " .. tostring(R and #R.list) .. ", wounds set " .. n .. ", skin tone " .. tostring(fig.skinTone) .. "; " .. S.chartText(o))
    end)
end

-- ===================================================================== the medical check card
Q.step(5, function()
    if S.dead then return end
    RT.charTab("health")
    local ok, why = S.medOpen()
    S.medOff = not ok
    if not ok then Q.check(false, "card: the medical check card opens on the World window", why); return end
    S.cardHook()
    local ww = RT.ww()
    if ww then S.hold(ww) end
end)
S.CARDS = {
    { w = 336, shot = "vk8_medcard_336", say = "the 336 card" },
    { w = 220, shot = "vk8_medcard_220", say = "the 220 half card" },
}
for _, K in ipairs(S.CARDS) do
    Q.step(2, function()
        if S.dead or S.medOff then return end
        S.cardW = K.w
    end)
    S.until1(5, 600, function()
        if S.medOff then return true end
        local c, t = S.card(), S.entryT()
        return c ~= nil and t ~= nil and t == S.medT and t.d ~= nil and S.readReady(t.d)
            and math.abs(c:getWidth() - Z.T.px(K.w)) <= 1.5
    end, function(ok)
        if S.medOff then return end
        local c = S.card()
        Q.check(ok, "card (" .. K.say .. "): open, " .. K.w .. " units wide, its read of the body has every staged wound",
            "width " .. tostring(c and S.n(c:getWidth() / (Z.T.scale or 1))) .. " units")
    end)
    Q.waitMs(500)
    Q.step(1, function() S.ordPanel = S.card() end)
    S.recQ(S.cardFig, function(ok, fig)
        S.ordPanel = nil
        if S.medOff then return end
        local t = S.entryT()
        local lab = "card (" .. K.say .. ", First Aid " .. tostring(t and t.level) .. ")"
        S.figureCheck(lab, fig, t and t.d)
        -- the frame, then the chart, then the focus marks and the figure (the last whole frame recorded)
        -- (each frame's run starts at its frame and ends at its figure; the injury rows' marks after it are not this)
        local seg, last = nil, nil
        for _, wt in ipairs(S.ord) do
            if wt == "frame" then seg = { "frame" }
            elseif seg then
                seg[#seg + 1] = wt
                if wt == "figure" then last = seg; seg = nil end
            end
        end
        local okO = last ~= nil and last[1] == "frame" and last[2] == "chart" and last[#last] == "figure"
        if okO then for i = 3, #last - 1 do if last[i] ~= "mark" then okO = false end end end
        Q.check(okO, lab .. ": the frame draws first, then the chart, then the focus marks and the figure",
            last and table.concat(last, ", ") or "no whole frame recorded")
        local o = S.chartRead(fig)
        Q.check(o ~= nil and S.chartAsRule(o), lab .. ": the chart draws in the frame's margins, words exactly where the lines hold them",
            S.chartText(o))
        local wantWords = (K.w == 220)
        local what = lab .. (wantWords and ": the chart shows the words (Build: the 220 drawer card)" or ": the chart shows the lines only (Build: the 336 card)")
        if S.screenH() >= 1000 then
            local words = o ~= nil and (o.left + o.right) > 0
            Q.check(o ~= nil and o.lines > 0 and words == wantWords, what, S.chartText(o))
        else
            Q.skip(what, "a screen under 1000 px tall (Design's table: at 1280x800 the 336 card stacks with words, the 220 card keeps the lines); the rule above holds it: " .. S.chartText(o))
        end
    end)
    S.shot(K.shot, "the medical check card (a stand-in patient: his own body), " .. K.say .. ", First Aid 10",
        function() return S.medOff and "the medical card did not open" or nil end)
end
Q.step(3, function()
    S.cardW = nil
    if S.card() then pcall(ZeD_WorldWindow.closeObjectCard, S.pn) end
    S.cardUnhook()
end)

-- ===================================================================== Lite: no chart, the wounds stay
Q.step(5, function()
    if S.dead then return end
    RT.charTab("health")
    S.setStyle(2)
end)
Q.waitMs(600)
S.recQ(S.healthFig, function(ok, fig)
    local R = fig and S.rec[fig]
    local o = S.chartRead(fig)
    Q.check(S.lite() and o ~= nil and o.n == 0, "Lite: the figure frame draws no chart (drawChart called, nothing drawn)",
        "lite " .. tostring(S.lite()) .. "; " .. (o and (o.n .. " chart draws") or "no chart call"))
    Q.check(R ~= nil and #R.list > 0 and #S.drawsNamed(R, "mark-") > 0, "Lite: the wounds still draw on the Health figure",
        tostring(R and #R.list) .. " wound draws")
end)
S.shot("vk8_lite", "the Health tab in Lite: the wounds on the figure, no chart in the frame")
Q.step(2, function() S.setStyle(1) end)
Q.waitMs(600)
S.recQ(S.healthFig, function(ok, fig)
    local o = S.chartRead(fig)
    Q.check(not S.lite() and o ~= nil and o.n > 0 and S.chartAsRule(o), "Full again: the chart comes back at once", S.chartText(o))
end)

-- ===================================================================== put back
Q.mark()
function S.putBack()
    if not S.back.on then return end
    S.back.on = nil
    S.staged = false
    S.park(false)
    S.ordPanel = nil
    S.cardW = nil
    if S.card() then pcall(ZeD_WorldWindow.closeObjectCard, S.pn) end
    S.cardUnhook()
    S.wrapOff()
    S.unholdAll()
    local f = S.found
    for _, P in ipairs(S.PARTS) do S.restore(S.part(P.bp), P.f0) end
    local bd = S.bd()
    if bd then
        pcall(function()
            local parts = bd:getBodyParts()
            for i = 0, parts:size() - 1 do
                if f.hp[i] then parts:get(i):SetHealth(f.hp[i]) end
            end
        end)
        if f.zInf == false then pcall(S.noInfection, bd) end
    end
    S.setStat("PAIN", f.pain)
    S.setDoc(f.doc)
    S.setTone(f.tone)
    pcall(function() S.p:resetModelNextFrame() end)
    if ISHealthPanel then ISHealthPanel.cheat = f.cheat end
    S.setStyle(f.style)
    if S.bailed then pcall(function() S.p:setGodMod(true) end)
    else pcall(function() S.p:setGodMod(f.god and true or false) end) end
    if f.inv ~= nil then pcall(function() S.p:setInvincible(f.inv) end) end
    S.speed(f.speed)
    S.live = false
    pcall(function() Events.OnTick.Remove(S.safety) end)
    -- (read at once, before the game's next update moves a clock)
    S.putDiff = {}
    for _, P in ipairs(S.PARTS) do
        for _, x in ipairs(S.snapDiff(P.f0 or {}, S.snap(S.part(P.bp)))) do S.putDiff[#S.putDiff + 1] = P.bp .. " " .. x end
    end
    local w = RT.cw()
    if w then
        if f.hfold ~= nil then w._healthFigureExpanded = f.hfold end
        if f.tfold ~= nil then w._thermalFigureExpanded = f.tfold end
        if f.esel then w._equipSelected = f.esel end
    end
end
Q.step(5, function()
    if not S.back.on then return end
    S.putBack()
    Q.check(#S.putDiff == 0, "put back: each staged part exactly as found (every flag and clock, bandage, splint, stitches, fracture, health, stiffness, pain)",
        #S.putDiff == 0 and "seven parts" or table.concat(S.putDiff, "; "))
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
    Q.check(S.card() == nil and S.hooked == nil, "put back: the medical card closed, its width hook off")
    Q.check(S.wrapsBack() and #S.held == 0 and S.parked == nil and getMouseX ~= nil, "put back: the figure's, the frame's and the focus mark's own functions, no window held, the pointer the game's")
    Q.check(S.doc() == f.doc and S.tone() == f.tone and S.style() == f.style and (not ISHealthPanel or ISHealthPanel.cheat == f.cheat),
        "put back: First Aid, the skin tone, Style and the debug cheat as found",
        "First Aid " .. tostring(S.doc()) .. ", tone " .. tostring(S.tone()) .. ", Style " .. tostring(S.style()) .. ", cheat " .. tostring(ISHealthPanel and ISHealthPanel.cheat))
    if S.bailed then
        Q.check(p:isGodMod() == true, "put back: the run stopped early, so god mode is left ON", tostring(p:isGodMod()))
    else
        Q.check(p:isGodMod() == (f.god and true or false), "put back: god mode as found", tostring(f.god))
    end
    local bd = S.bd()
    local hurt, inf, hp = {}, false, nil
    pcall(function()
        local parts = bd:getBodyParts()
        for i = 0, parts:size() - 1 do
            local b = parts:get(i)
            local nm = S.typeOf(b) or i
            if b:HasInjury() and not f.hurt[nm] then hurt[#hurt + 1] = tostring(nm) end
        end
        inf = bd:isInfected()
        hp = bd:getOverallBodyHealth()
    end)
    Q.check(not p:isDead() and #hurt == 0 and (inf == false or f.zInf == true),
        "put back: the character is alive and as well as found (no new wound, not infected)",
        (p:isDead() and "DEAD; " or "") .. "health " .. S.n(hp) .. "; new: " .. table.concat(hurt, ", ") .. "; infected " .. tostring(inf)
        .. "; health top-ups " .. tostring(S.topUps or 0))
    local e1 = S.errN()
    if S.err0 and e1 then
        Q.check(e1 == S.err0, "the wounds run ran with no Lua error", (e1 - S.err0) .. " new")
    else
        Q.skip("the wounds run's Lua error count", "the game's Lua error count cannot be read here")
    end
end)
Q.start()
