-- ZeDUI/tools/qa/bx_health.lua  (Nov 21 2026, QA beast mode; tag bx_hlth)
-- Injuries, sickness, sleep, rest and sit, done fast and in odd orders with ZeD's Health tab open. Run after
-- zedqa_prelude.lua and rt_kit.lua.
-- SAFETY (Nov 21 2026, after the first run killed the character). God mode cannot stay on here: with it the game
-- heals every wound on every update (BodyDamage.Update -> RestoreToFullHealth) and resets tiredness, breath and
-- body heat (IsoGameCharacter.updateInternal), so nothing this script stages would last a frame. Invincible stays
-- ON, but the game does not ask it before a death by infection or blood loss. So while god mode is off a guard
-- runs on EVERY game tick (X.safety, Events.OnTick, not the step queue: it keeps running when a step throws):
--   * the zombie infection never runs: the bite is kept as a wound only, its infection is taken off in the same
--     call, and the guard clears any infection the game adds and its clock. The game's SetBitten(false) infects
--     the part as well, so it is always followed by SetInfected(false);
--   * (the first run died of blood loss, not of the bite's infection: at game speed x20 with god mode off, six
--     bleeding parts and the bite put the game's BLEEDING moodle at its top level, which takes health off every
--     part on every update, times 20; the infection, at Mortality 2-3 days, had not begun to hurt. The ZOMBIE
--     moodle at 4 in that log is what the game shows on any dead body that carried the infection at all);
--   * health under 75 is topped up on every part (the wounds stay); under 35 the run stops: god mode ON (the game
--     itself then heals him) and the queue jumps to the put-back;
--   * if the queue never reaches the end of the put-back, the guard heals him and turns god mode ON by itself.
-- The put-back heals FIRST (god mode ON, so the game's own heal runs too), then proves it: a PASS/FAIL line for
-- alive, health 100, no wound on any part, no fracture, not infected. If that fails god mode is left ON.
--   1. WOUNDS: ten wound kinds on ten body parts, one every few frames (fracture, scratch, bleeding, deep wound,
--      bullet, laceration, glass, bite, burn, infected wound). After each: the tab's own data (win._healthCache)
--      names the wound in the game's word, the body figure's colour for the part follows its health, the counts
--      match a fresh read, the injury rows are for listed parts only.
--   2. THE MENU: every figure part's treatment menu opened in a burst, a part that does not exist, a closed window.
--   3. TREATMENTS through ZeD's part menu (HealthTab._onPartClicked, then the game's entry): a bandage interrupted
--      half way (nothing bandaged, the bandage kept), a bandage finished while the tab is switched and the windows
--      are shut and reopened, disinfect, a Bandage entry picked after the bandages left the inventory, stitch,
--      splint, remove bullet, remove glass, clean burn, and one bandage through the wheel's Medicine list
--      (DpadWheels.H.treatments). After each the tab shows the new state and drops the old word.
--   4. THE BITE taken off (the body is never infected: with the sandbox's mortality on Instant one update kills);
--      everything healed: the tab is calm, no row left, the figure all healthy.
--   5. STATES: food sickness, a cold, drunk, panic, stress, boredom, unhappy, pain, wet, tired, out of breath, hot,
--      cold, piled up without clearing. After each ZeD's moodle list is the game's (key and level), ZeD's moodle
--      rect counts them and lies on screen; the full pile in each of the three Moodles places; the Thermal tab
--      reads the game's core temperature; then all cleared: nothing stale.
--   6. SLEEP, SIT, REST through ZeD's wheel handlers (DpadWheels.H.sleep / H.sitWheel): not tired and panicked are
--      refused in the game's words; asleep on the ground (the question asked once for two presses), ZeD's clock
--      radio draws, the windows toggled while asleep, woken; sit on the ground (pressed twice), exhausted, up
--      again; a chair placed beside the character: sat on, named by the sleep slice, taken away (the wheel says no
--      seat); a bed tile: sat on, slept on, woken.
--   PUT BACK: awake, standing, the placed chair and bed removed, the body healed, every stat as found, the cold
--   gone, god mode and invincible as found, the Moodles place, the input mode, game speed 1, the clock, the windows
--   and tab as found, the things given taken back, the character home.
-- The game's save() is swapped for a no-op only around the sleep confirm (falling asleep saves the game, and the QA
-- save must not be written with test state in it). grep "ZEDQA bx_hlth".
if not RT then print("ZEDQA bx_hlth ERR rt_kit.lua did not run first"); print("ZEDQA bx_hlth DONE"); return end
local Q = RT.make("bx_hlth")
Q.maxMs = 430000
local p = RT.p
local pn = RT.pn
local X = {}
local S = { holds = {}, objs = {}, found = {}, live = false, t0 = getTimestampMs() }
local HT = ZeD and ZeD.HealthTab
local MO = ZeD and ZeD.Moodles
local CW = ZeD_CharacterWindow
if not (p and HT and HT.gatherData and CW and MO) then
    Q.check(false, "ZeD's Health tab, Character window and Moodles are loaded", "missing")
    Q.start()
    return
end
if ZEDQA_HOME then pcall(ZEDQA_HOME, "bx_hlth") end
local bd = p:getBodyDamage()
local st = p:getStats()

-- ===================================================================== small helpers
function X.speed(n)
    local f = ZEDQA_SPEED or setGameSpeed
    pcall(f, n)
    if not ZEDQA_SPEED then pcall(function() getGameTime():setMultiplier(n >= 3 and 20 or 1) end) end
end
function X.word(key) return getText(key) end
function X.low(s) return string.lower(tostring(s)) end
function X.has(hay, needle) return X.low(hay):find(X.low(needle), 1, true) ~= nil end
function X.part(c) return bd:getBodyPart(BodyPartType[c.bp]) end
-- every poll: nobody dies, the Character window stays drawn, the held stats stay where the scene wants them
function X.hold()
    if p:isDead() then return end
    local w = RT.cw()
    if w then
        pcall(function()
            w._autoShaded = false
            if w.windowShaded then w:setWindowShaded(false) end
            w._outSince = getTimestampMs() + 600000
        end)
    end
    for _, fn in ipairs(S.holds) do pcall(fn) end
end
-- wait (real time) until cond() or ms have gone, then fn(ok)
function X.untilMs(ms, cond, fn)
    local t = {}
    Q.waitFor(1, 1000000, function()
        t.t = t.t or getTimestampMs()
        X.hold()
        local ok, r = pcall(cond)
        if ok and r then t.ok = true; return true end
        return getTimestampMs() - t.t >= ms
    end, function() fn(t.ok == true) end)
end
function X.pause(ms) X.untilMs(ms, function() return false end, function() end) end
function X.fresh()
    local ok, d = pcall(HT.gatherData, p)
    if not ok then Q.check(false, "HealthTab.gatherData ran without an error", d); return nil end
    return d
end
function X.shown() local w = RT.cw(); return w and w._healthCache or nil end
function X.entry(data, name)
    for _, e in ipairs(data and data.entries or {}) do if e.name == name then return e end end
    return nil
end
function X.labels(e)
    local t = {}
    for _, c in ipairs(e and e.conditions or {}) do t[#t + 1] = tostring(c.label) end
    return table.concat(t, ", ")
end
function X.hasLabel(e, word)
    for _, c in ipairs(e and e.conditions or {}) do if X.has(c.label, word) then return true end end
    return false
end
function X.shownHas(c, word) return X.hasLabel(X.entry(X.shown(), c.list), word) end
function X.healthTab()
    RT.pairOpen()
    local ok = false
    pcall(function() ok = RT.charTab("health") end)
    if not ok then pcall(CW.openTab, pn, "health") end
end
-- the zombie infection off the body and off every part (the game copies a part's infection to the body on its next
-- update, and an infected body dies: at once with the sandbox's mortality on Instant)
-- NOTE the game's BodyPart.SetBitten(false) INFECTS the part too (bytecode: with the world's Transmission not None it
-- sets isInfected whatever the argument), so every SetBitten here is followed, in the same call, by SetInfected(false)
-- or by this (vanilla's own cheat does the same: SetBitten(false), then SetInfected(false)).
function X.noInfection()
    local parts = bd:getBodyParts()
    for i = 0, parts:size() - 1 do
        local b = parts:get(i)
        if b:IsInfected() then b:SetInfected(false) end
        if b:IsFakeInfected() then b:SetFakeInfected(false) end
    end
    if bd:isInfected() then bd:setInfected(false) end
    if bd:isIsFakeInfected() then bd:setIsFakeInfected(false) end
    if st:get(CharacterStat.ZOMBIE_INFECTION) > 0 then st:set(CharacterStat.ZOMBIE_INFECTION, 0) end
    if st:get(CharacterStat.ZOMBIE_FEVER) > 0 then st:set(CharacterStat.ZOMBIE_FEVER, 0) end
    -- (and the infection clock: one update with an infected part starts it, and a later infection would count from
    -- that old start instead of from zero)
    if bd:getInfectionTime() >= 0 then bd:setInfectionTime(-1) end
    if bd:getInfectionMortalityDuration() >= 0 then bd:setInfectionMortalityDuration(-1) end
end
-- every wound, splint, bandage and stitch off every part, then the game's own full heal. Each call is its own pcall
-- (one wrong call must not stop the rest); the part's and the body's RestoreToFullHealth are what heal, the setters
-- before them are a second belt. NOTE the body's full heal also resets every stat (hunger, thirst...): the put-back
-- sets the stats as found after it.
function X.healAll()
    local parts = bd:getBodyParts()
    for i = 0, parts:size() - 1 do
        local b = parts:get(i)
        pcall(function() b:SetBitten(false) end)
        pcall(function() b:setBiteTime(0) end)
        pcall(function() b:SetInfected(false) end)
        pcall(function() b:SetFakeInfected(false) end)
        pcall(function() b:setHaveBullet(false, 0) end)
        pcall(function() b:setHaveGlass(false) end)
        pcall(function() b:setFractureTime(0) end)
        pcall(function() b:setSplint(false, 0) end)
        pcall(function() b:setSplintFactor(0) end)
        pcall(function() b:setBurnTime(0) end)
        pcall(function() b:setNeedBurnWash(false) end)
        pcall(function() b:setInfectedWound(false) end)
        pcall(function() b:setWoundInfectionLevel(0) end)
        pcall(function() b:setBandaged(false, 0) end)
        pcall(function() b:setStitched(false) end)
        pcall(function() b:setAdditionalPain(0) end)
        pcall(function() b:RestoreToFullHealth() end)
        pcall(function() b:SetHealth(100) end)
    end
    -- (S.fullHeal: the game's own full heal ran without an error; the put-back's PASS/FAIL line says so)
    S.fullHeal = pcall(function() bd:RestoreToFullHealth() end)
    pcall(function() bd:setInfected(false) end)
    pcall(function() bd:setIsFakeInfected(false) end)
    pcall(function() bd:setInfectionTime(-1) end)
    pcall(function() bd:setInfectionMortalityDuration(-1) end)
    pcall(function() st:set(CharacterStat.ZOMBIE_INFECTION, 0) end)
    pcall(function() st:set(CharacterStat.ZOMBIE_FEVER, 0) end)
end
-- is the body whole? true, or false and what is wrong (alive, health, every part's wounds, fracture, infection)
function X.bodyClean()
    if p:isDead() then return false, "DEAD" end
    local bad = {}
    local okAll = pcall(function()
        local h = bd:getOverallBodyHealth()
        if h < 99 then bad[#bad + 1] = string.format("health %.1f", h) end
        if bd:isInfected() then bad[#bad + 1] = "infected" end
        if st:get(CharacterStat.ZOMBIE_INFECTION) > 0 then bad[#bad + 1] = "infection level " .. tostring(st:get(CharacterStat.ZOMBIE_INFECTION)) end
        local parts = bd:getBodyParts()
        for i = 0, parts:size() - 1 do
            local b = parts:get(i)
            local w = {}
            if b:getFractureTime() > 0 then w[#w + 1] = "fracture" end
            if b:bitten() then w[#w + 1] = "bite" end
            if b:scratched() then w[#w + 1] = "scratch" end
            if b:isCut() then w[#w + 1] = "cut" end
            if b:deepWounded() then w[#w + 1] = "deep wound" end
            if b:bleeding() then w[#w + 1] = "bleeding" end
            if b:haveBullet() then w[#w + 1] = "bullet" end
            if b:haveGlass() then w[#w + 1] = "glass" end
            if b:getBurnTime() > 0 then w[#w + 1] = "burn" end
            if b:isInfectedWound() then w[#w + 1] = "infected wound" end
            if b:IsInfected() then w[#w + 1] = "infection" end
            if b:bandaged() then w[#w + 1] = "bandage" end
            if b:stitched() then w[#w + 1] = "stitches" end
            if b:isSplint() then w[#w + 1] = "splint" end
            if b:getHealth() < 99 then w[#w + 1] = string.format("health %.1f", b:getHealth()) end
            if #w > 0 then bad[#bad + 1] = tostring(BodyPartType.getDisplayName(b:getType())) .. ": " .. table.concat(w, "+") end
        end
    end)
    if not okAll then bad[#bad + 1] = "the body could not be read" end
    if #bad > 0 then return false, table.concat(bad, "; ") end
    return true, "health " .. string.format("%.1f", bd:getOverallBodyHealth()) .. ", no wound, no fracture, not infected"
end
-- stop the run and go to the put-back (the step queue's own jump; safe from inside a step and from the guard)
function X.bail(why)
    if S.bailed then return end
    S.bailed = true
    Q.check(false, "the run went on to its end", "stopped, on to the put-back: " .. tostring(why))
    if Q.backAt and Q.qi < Q.backAt then Q.qi = Q.backAt; Q.wait = nil end
end
-- THE GUARD, on every game tick while god mode is off (see SAFETY at the top)
function X.safety()
    if not S.live then return end
    local ok, err = pcall(function()
        if p:isDead() then
            if not S.deadSaid then
                S.deadSaid = true
                Q.check(false, "the character is alive", "DEAD during the run: restore the QA save from its backup")
                X.bail("the character died")
            end
            return
        end
        X.noInfection()
        local h = bd:getOverallBodyHealth()
        if h < 75 then
            local parts = bd:getBodyParts()
            for i = 0, parts:size() - 1 do parts:get(i):SetHealth(100) end
            S.topUps = (S.topUps or 0) + 1
        end
        if h < 35 and not S.bailed then
            p:setGodMod(true)
            X.bail("health fell to " .. string.format("%.1f", h) .. " past the guard: god mode ON")
        end
        -- the queue never came to the end of the put-back: heal here
        if getTimestampMs() - S.t0 > Q.maxMs + 120000 then
            S.live = false
            X.healAll()
            p:setGodMod(true)
            p:setInvincible(true)
            Q.say("ERR the put-back did not finish in time: the guard healed the character and left god mode ON")
            Events.OnTick.Remove(X.safety)
        end
    end)
    if not ok and not S.guardErrSaid then
        S.guardErrSaid = true
        Q.say("ERR the guard threw: " .. tostring(err))
        pcall(function() p:setGodMod(true) end)
        X.bail("the guard threw, god mode ON")
    end
end
-- the parts the tab lists now that it did not list before the first wound
function X.left()
    local d = X.shown()
    if not d then return 99 end
    local n = 0
    for _, e in ipairs(d.entries or {}) do if not (S.pre and S.pre[e.name]) then n = n + 1 end end
    return n
end
function X.bucket(h)
    local T = ZeD.T
    if h > 80 then return T.positive end
    if h > 50 then return T.warning end
    if h > 20 then return T.danger end
    return { r = 0.95, g = 0.15, b = 0.15 }
end
-- the figure's colour for a part is the bucket of the health the tab read (what drew last)
function X.figureOk(fig)
    local w = RT.cw()
    local f = w and w._healthBodyFigure
    local d = X.shown()
    local col = f and f.colorMap and f.colorMap[fig]
    local h = d and d.partHealth and d.partHealth[fig]
    if not (col and h) then return false, "no colour or no health for " .. tostring(fig) end
    local b = X.bucket(h)
    local same = math.abs(col.r - b.r) < 0.02 and math.abs(col.g - b.g) < 0.02 and math.abs(col.b - b.b) < 0.02
    return same, string.format("health %.1f colour %.2f,%.2f,%.2f want %.2f,%.2f,%.2f", h, col.r, col.g, col.b, b.r, b.g, b.b)
end

-- ===================================================================== the part menu
function X.menu() return getPlayerContextMenu(pn) end
function X.names()
    local t = {}
    local m = X.menu()
    for _, o in ipairs(m and m.options or {}) do t[#t + 1] = tostring(o.name) end
    return t
end
function X.closeMenu()
    pcall(function()
        local m = X.menu()
        if m and m._zedMenu and m._zedMenu.close then m._zedMenu:close() end
        if m then m:hideAndChildren() end
        if m and m:isVisible() then m:closeAll() end
    end)
end
function X.run(o)
    return pcall(o.onSelect, o.target, o.param1, o.param2, o.param3, o.param4, o.param5, o.param6, o.param7, o.param8, o.param9, o.param10)
end
-- pick the entry whose name holds text; an entry with a sub menu: its first live entry
function X.pick(text)
    local m = X.menu()
    for _, o in ipairs(m and m.options or {}) do
        if X.has(o.name, text) then
            if o.onSelect then return X.run(o) end
            if o.subOption then
                local sm = nil
                pcall(function() sm = m:getSubMenu(o.subOption) end)
                for _, so in ipairs(sm and sm.options or {}) do
                    if so.onSelect and not so.notAvailable then return X.run(so) end
                end
                return false, "the sub menu has no live entry"
            end
        end
    end
    return false, "no such entry"
end
function X.offered(text)
    for _, n in ipairs(X.names()) do if X.has(n, text) then return true end end
    return false
end
function X.click(fig)
    X.closeMenu()
    if not RT.cw() then X.healthTab() end
    return pcall(HT._onPartClicked, RT.cw(), fig, nil, 10, 10)
end
function X.queued()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    return q and q.queue and #q.queue or 0
end
function X.clearQueue()
    pcall(function() ISTimedActionQueue.clear(p) end)
    pcall(function() p:StopAllActionQueue() end)
end
function X.count(ft)
    local n = 0
    pcall(function() n = p:getInventory():getItemCountRecurse(ft) end)
    return n
end

-- ===================================================================== 0. setup
Q.step(4, function()
    local f = S.found
    f.god = p:isGodMod()
    pcall(function() f.inv = p:isInvincible() end)
    f.open = RT.isOpen()
    f.tab = RT.cw() and RT.cw()._activeTab or nil
    pcall(function() f.tod = getGameTime():getTimeOfDay() end)
    pcall(function() f.lastSleep = p:getLastHourSleeped() end)
    pcall(function() f.cold = bd:isHasACold(); f.coldStr = bd:getColdStrength() end)
    pcall(function() f.place = ZeD.Settings.moodlePlaceOption:getValue() end)
    -- (every part's wetness: the game mixes the WETNESS stat into the parts each update and the stat back from them,
    -- so the stat alone put back leaves the body wet)
    f.partWet = {}
    pcall(function()
        local parts = bd:getBodyParts()
        for i = 0, parts:size() - 1 do f.partWet[i] = parts:get(i):getWetness() end
    end)
    f.stats = {}
    for _, k in ipairs({ "FOOD_SICKNESS", "SICKNESS", "POISON", "INTOXICATION", "PANIC", "STRESS", "BOREDOM", "UNHAPPINESS", "PAIN",
                         "WETNESS", "TEMPERATURE", "FATIGUE", "ENDURANCE", "HUNGER", "THIRST", "ZOMBIE_INFECTION", "ZOMBIE_FEVER" }) do
        pcall(function() f.stats[k] = st:get(CharacterStat[k]) end)
    end
    if p:isDead() then
        Q.check(false, "the character is alive at the start", "dead")
        X.bail("dead at the start")
        return
    end
    X.speed(1)
    -- the guard first, then god mode off (never off without the guard running)
    S.live = true
    Events.OnTick.Add(X.safety)
    pcall(function() p:setInvincible(true) end)
    X.healAll()
    p:setGodMod(false)
    Q.check(p:isGodMod() == false, "god mode is off for the run (it heals a wound at once), the guard is on", "was " .. tostring(f.god))
    Q.check(p:isInvincible() == true, "invincible is on for the run", "was " .. tostring(f.inv))
    X.clearQueue()
    for _, ft in ipairs({ "Base.Bandage", "Base.Bandage", "Base.Bandage", "Base.Bandage", "Base.Bandage", "Base.Bandage",
                          "Base.Disinfectant", "Base.AlcoholWipes", "Base.SutureNeedle", "Base.SutureNeedle", "Base.Needle", "Base.Thread",
                          "Base.Tweezers", "Base.SutureNeedleHolder", "Base.Splint", "Base.Plank", "Base.RippedSheets", "Base.RippedSheets" }) do
        if not RT.give(ft) then Q.say("note: " .. ft .. " could not be given") end
    end
    X.healthTab()
end)
X.untilMs(2500, function() local w = RT.cw(); return w and w._activeTab == "health" and w._healthCache ~= nil end, function(ok)
    Q.check(ok, "the Character window is open on the Health tab and it read the body", tostring(RT.cw() and RT.cw()._activeTab))
    local d = X.shown()
    S.pre = {}
    for _, e in ipairs(d and d.entries or {}) do S.pre[e.name] = true end
    if d and d.injuredCount > 0 then Q.say("note: " .. d.injuredCount .. " part(s) listed before any wound (stiffness or pain the character came with)") end
    RT.bounds(Q, "health tab, healthy")
end)

-- ===================================================================== 1. wounds
local W = {
    { id = "fracture", fig = "Right Lower Leg", list = "Right Shin", bp = "LowerLeg_R", key = "IGUI_health_Fracture",
      apply = function(b) b:setFractureTime(40) end, has = function(b) return b:getFractureTime() > 0 end },
    { id = "scratch", fig = "Left Hand", list = "Left Hand", bp = "Hand_L", key = "IGUI_health_Scratch",
      apply = function(b) b:setScratched(true, true); b:setScratchTime(15) end, has = function(b) return b:scratched() end },
    { id = "bleeding", fig = "Groin", list = "Groin", bp = "Groin", key = "IGUI_health_Bleeding",
      apply = function(b) b:setBleeding(true); b:setBleedingTime(10) end, has = function(b) return b:bleeding() end },
    { id = "deep wound", fig = "Left Upper Leg", list = "Left Thigh", bp = "UpperLeg_L", key = "IGUI_health_DeepWound",
      apply = function(b) b:setDeepWounded(true); b:setDeepWoundTime(15) end, has = function(b) return b:deepWounded() end },
    { id = "bullet", fig = "Left Upper Arm", list = "Left Upper Arm", bp = "UpperArm_L", key = "IGUI_health_LodgedBullet",
      apply = function(b) b:setHaveBullet(true, 0) end, has = function(b) return b:haveBullet() end },
    { id = "laceration", fig = "Right Forearm", list = "Right Forearm", bp = "ForeArm_R", key = "IGUI_health_Cut",
      apply = function(b) b:setCut(true); b:setCutTime(15) end, has = function(b) return b:isCut() end },
    { id = "glass", fig = "Left Foot", list = "Left Foot", bp = "Foot_L", zedKey = "UI_ZeD_Health_GlassShards",
      apply = function(b) if not pcall(function() b:generateDeepShardWound() end) then b:setHaveGlass(true); b:setDeepWounded(true) end end,
      has = function(b) return b:haveGlass() end },
    { id = "bite", fig = "Right Hand", list = "Right Hand", bp = "Hand_R", key = "IGUI_health_Bitten",
      -- (a bite infects: the infection is taken off in the same call, before the game's next update can copy it
      -- to the body; the bite stays as a wound)
      apply = function(b) b:SetBitten(true); b:SetInfected(false); b:SetFakeInfected(false); pcall(X.noInfection) end,
      has = function(b) return b:bitten() end },
    { id = "burn", fig = "Upper Torso", list = "Upper Torso", bp = "Torso_Upper", zedKey = "UI_ZeD_Health_Burn",
      apply = function(b) if not pcall(function() b:setBurned() end) then b:setBurnTime(40); b:setNeedBurnWash(true) end end,
      has = function(b) return b:getBurnTime() > 0 end },
    { id = "infected wound", fig = "Left Forearm", list = "Left Forearm", bp = "ForeArm_L", key = "IGUI_health_Infected",
      apply = function(b) b:setScratched(true, true); b:setScratchTime(15); b:setInfectedWound(true); b:setWoundInfectionLevel(5) end,
      has = function(b) return b:isInfectedWound() end },
}
function X.case(id) for _, c in ipairs(W) do if c.id == id then return c end end end
function X.caseWord(c) return c.zedKey and ZeD.tr(c.zedKey) or X.word(c.key) end
function X.woundCheck(c, ok)
    if c.off then return end
    local e = X.entry(X.shown(), c.list)
    Q.check(ok, c.id .. " on " .. c.fig .. ": the tab's row names it '" .. X.caseWord(c) .. "'", "row: " .. X.labels(e))
    local d = X.fresh()
    if not d then return end
    Q.check(X.hasLabel(X.entry(d, c.list), X.caseWord(c)), c.id .. ": a fresh read names it too", X.labels(X.entry(d, c.list)))
    Q.check(d.partByFigure and d.partByFigure[c.fig] == X.part(c), c.id .. ": the figure's " .. c.fig .. " is the game's part")
    local fo, fd = X.figureOk(c.fig)
    Q.check(fo, c.id .. ": the figure's colour for " .. c.fig .. " follows its health", fd)
    local sh = X.shown()
    Q.check(sh ~= nil and math.abs(sh.injuredCount - d.injuredCount) <= 1 and sh.injuredCount == #sh.entries,
        c.id .. ": the tab's count is its rows and keeps up with the body", "tab " .. tostring(sh and sh.injuredCount) .. ", fresh " .. d.injuredCount)
end
for _, c in ipairs(W) do
    Q.step(3, function()
        local b = X.part(c)
        local ok, err = pcall(c.apply, b)
        local took = false
        pcall(function() took = c.has(b) end)
        if not (ok and took) then
            c.off = true
            Q.skip(c.id .. " on " .. c.fig, "the game did not take the wound: " .. tostring(err))
        end
    end)
    X.untilMs(1500, function() return c.off or X.shownHas(c, X.caseWord(c)) end, function(ok) X.woundCheck(c, ok) end)
end
Q.step(2, function()
    local w = RT.cw()
    local sh = X.shown()
    local zones = w and w._healthInjuryZones or {}
    local stale = {}
    for _, z in ipairs(zones) do if not X.entry(sh, z.bodyPartName) then stale[#stale + 1] = tostring(z.bodyPartName) end end
    Q.check(#zones >= 1 and #zones <= #(sh and sh.entries or {}) and #stale == 0, "ten wounds: every injury row on the tab is for a listed part",
        #zones .. " rows, " .. #(sh and sh.entries or {}) .. " listed, stale: " .. table.concat(stale, ", "))
    local f = w and w._healthBodyFigure
    local rects = {}
    pcall(function() rects = f:getPartRects() end)
    local bad = 0
    for _, r in ipairs(rects) do if not (r.w and r.h and r.w > 0 and r.h > 0) then bad = bad + 1 end end
    Q.check(#rects >= 12 and bad == 0, "the body figure has a box for its parts", #rects .. " boxes, " .. bad .. " empty")
    local d = X.fresh()
    if d then
        Q.check(math.abs((d.overall or 0) - bd:getOverallBodyHealth()) < 0.5, "overall health is the game's", tostring(d.overall))
        local okW, wd = pcall(HT.overallWordOf, d)
        Q.check(okW and type(wd) == "string" and wd ~= "", "the overall word is said without an error", tostring(wd))
    end
    RT.bounds(Q, "health tab, ten wounds")
end)

-- ===================================================================== 2. the part menu, in a burst
Q.step(4, function()
    local d = X.fresh()
    local n, errs = 0, {}
    for fig in pairs(d and d.partHealth or {}) do
        local ok, err = X.click(fig)
        n = n + 1
        if not ok then errs[#errs + 1] = fig .. ": " .. tostring(err) end
    end
    Q.check(n >= 17 and #errs == 0, "every figure part's menu opened one after another without an error", n .. " parts; " .. table.concat(errs, "; "))
    local ok1, e1 = pcall(HT._onPartClicked, RT.cw(), "Tail", nil, 10, 10)
    local ok2, e2 = pcall(HT._onPartClicked, RT.cw(), nil, nil, nil, nil)
    Q.check(ok1 and ok2, "a part that does not exist opens nothing and raises nothing", tostring(e1) .. " " .. tostring(e2))
    X.closeMenu()
end)
Q.step(6, function()
    local vis = false
    pcall(function() vis = X.menu():isVisible() end)
    Q.check(not vis, "the menu is shut after the burst")
    -- twice on one part, no close in between
    local okA = pcall(HT._onPartClicked, RT.cw(), "Left Hand", nil, 10, 10)
    local okB, eB = pcall(HT._onPartClicked, RT.cw(), "Left Hand", nil, 400, 300)
    Q.check(okA and okB, "the same part pressed twice without closing the menu", tostring(eB))
    RT.bounds(Q, "the part menu up")
    X.closeMenu()
end)

-- ===================================================================== 3. treatments
-- one treatment through ZeD's part menu: open, pick the game's entry, wait for the game, then the tab
function X.treat(id, menuKey, done, wantKey, goneWord)
    local c = X.case(id)
    local t = {}
    Q.step(5, function()
        if c.off then t.off = true; return end
        X.healthTab()
        local ok, err = X.click(c.fig)
        Q.check(ok, id .. ": ZeD's menu for " .. c.fig .. " opens", err)
        if not X.offered(X.word(menuKey)) then
            t.off = true
            Q.skip(id .. ": " .. X.word(menuKey), "the game's menu does not offer it here: " .. table.concat(X.names(), " | "))
            X.closeMenu()
            return
        end
        local okP, eP = X.pick(X.word(menuKey))
        Q.check(okP, id .. ": '" .. X.word(menuKey) .. "' picked from the menu", eP)
        X.closeMenu()
    end)
    X.untilMs(9000, function() return t.off or done(X.part(c)) end, function(ok)
        if t.off then return end
        t.done = ok
        Q.check(ok, id .. ": the game finished '" .. X.word(menuKey) .. "' on " .. c.fig, "queue " .. X.queued())
        if not ok then X.clearQueue() end
    end)
    X.untilMs(1500, function()
        if t.off or not t.done then return true end
        local e = X.entry(X.shown(), c.list)
        return (not wantKey or X.hasLabel(e, X.word(wantKey))) and (not goneWord or not X.hasLabel(e, goneWord))
    end, function(ok)
        if t.off or not t.done then return end
        local e = X.entry(X.shown(), c.list)
        Q.check(ok, id .. ": the tab shows the treatment" .. (wantKey and (" ('" .. X.word(wantKey) .. "')") or "")
            .. (goneWord and (" and drops '" .. goneWord .. "'") or ""), "row: " .. X.labels(e))
        local fo, fd = X.figureOk(c.fig)
        Q.check(fo, id .. ": the figure's colour still follows the part's health", fd)
    end)
end

-- 3a. a bandage interrupted half way
Q.step(4, function()
    local c = X.case("scratch")
    if c.off then return end
    X.speed(1)
    S.band0 = X.count("Base.Bandage")
    X.click(c.fig)
    local ok, err = X.pick(X.word("ContextMenu_Bandage"))
    S.cutShort = ok
    if not ok then Q.skip("a bandage interrupted", "Bandage could not be picked: " .. tostring(err)) end
    X.closeMenu()
end)
X.pause(350)
Q.step(1, function()
    if not S.cutShort then return end
    Q.say("interrupting with " .. X.queued() .. " queued")
    X.clearQueue()
end)
X.pause(700)
Q.step(1, function()
    local c = X.case("scratch")
    if not S.cutShort then return end
    Q.check(not X.part(c):bandaged(), "a bandage stopped half way: the hand is not bandaged")
    Q.check(not X.shownHas(c, X.word("IGUI_health_Bandaged")), "and the tab does not say Bandaged", X.labels(X.entry(X.shown(), c.list)))
    Q.check(X.count("Base.Bandage") == S.band0, "and the bandage is still in the inventory", X.count("Base.Bandage") .. " of " .. tostring(S.band0))
    Q.check(X.shownHas(c, X.caseWord(c)), "and the scratch is still listed")
end)
-- 3b. a bandage finished while the tab is switched and the windows are shut
Q.step(3, function()
    local c = X.case("scratch")
    if c.off then return end
    X.speed(3)
    X.click(c.fig)
    S.away = X.pick(X.word("ContextMenu_Bandage"))
    X.closeMenu()
    local other = nil
    for _, id in ipairs(RT.tabs(RT.charStrip())) do if id ~= "health" and id ~= "loot" then other = other or id end end
    if other then pcall(RT.charTab, other) end
    Q.say("bandaging with the tab on " .. tostring(other))
end)
Q.step(6, function() RT.pairShut() end)
X.untilMs(9000, function() return not S.away or X.part(X.case("scratch")):bandaged() end, function(ok)
    if not S.away then Q.skip("a bandage with the windows shut", "Bandage could not be picked"); return end
    Q.check(ok, "the bandage went on with the windows shut", "queue " .. X.queued())
    X.healthTab()
end)
X.untilMs(2500, function() return not S.away or X.shownHas(X.case("scratch"), X.word("IGUI_health_Bandaged")) end, function(ok)
    if not S.away then return end
    Q.check(ok, "reopened on Health: the tab says Bandaged (nothing stale from before)", X.labels(X.entry(X.shown(), "Left Hand")))
    RT.bounds(Q, "health tab reopened")
end)
-- 3c. disinfect, then a Bandage entry picked after the bandages left
X.treat("laceration", "ContextMenu_Disinfect", function(b) return b:getAlcoholLevel() > 0 end, nil, nil)
Q.step(4, function()
    local c = X.case("laceration")
    if c.off then return end
    X.click(c.fig)
    if not X.offered(X.word("ContextMenu_Bandage")) then Q.skip("a stale Bandage entry", "no Bandage in the menu"); X.closeMenu(); return end
    S.gone = {}
    pcall(function()
        local inv = p:getInventory()
        for _, ft in ipairs({ "Base.Bandage", "Base.AlcoholBandage", "Base.RippedSheets" }) do
            local it = inv:FindAndReturn(ft)
            while it do inv:Remove(it); S.gone[#S.gone + 1] = ft; it = inv:FindAndReturn(ft) end
        end
    end)
    local ok, err = X.pick(X.word("ContextMenu_Bandage"))
    Q.check(ok or not X.has(err, "zed"), "Bandage picked after every bandage left the inventory raises nothing in ZeD", tostring(err))
    X.closeMenu()
end)
X.pause(900)
Q.step(1, function()
    local c = X.case("laceration")
    if not S.gone then return end
    Q.check(not X.part(c):bandaged(), "no bandage, so nothing was bandaged", "queue " .. X.queued())
    X.clearQueue()
    local okC, eC = X.click(c.fig)
    Q.check(okC and not X.offered(X.word("ContextMenu_Bandage")), "the menu opened again offers no Bandage", tostring(eC) .. " " .. table.concat(X.names(), " | "))
    X.closeMenu()
    RT.given = {}                       -- (the removed ones are gone; the new ones are given below)
    for _, ft in ipairs(S.gone) do RT.give(ft) end
    for _, ft in ipairs({ "Base.Disinfectant", "Base.AlcoholWipes", "Base.SutureNeedle", "Base.Needle", "Base.Thread", "Base.Tweezers",
                          "Base.SutureNeedleHolder", "Base.Splint", "Base.Plank" }) do
        pcall(function()
            local items = p:getInventory():getItemsFromFullType(ft)
            for i = 0, items:size() - 1 do
                local it = items:get(i)
                if it:getModData().ZeDQA_spawned then RT.given[#RT.given + 1] = it end
            end
        end)
    end
end)
-- 3d. the rest, each through the menu
X.treat("deep wound", "ContextMenu_Stitch", function(b) return b:stitched() end, "IGUI_health_Stitched", nil)
X.treat("fracture", "ContextMenu_Splint", function(b) return b:getSplintFactor() > 0 end, "IGUI_health_Splinted", getText("IGUI_health_Fracture"))
X.treat("bullet", "ContextMenu_Remove_Bullet", function(b) return not b:haveBullet() end, nil, getText("IGUI_health_LodgedBullet"))
X.treat("glass", "ContextMenu_Remove_Glass", function(b) return not b:haveGlass() end, nil, ZeD.tr("UI_ZeD_Health_GlassShards"))
-- (Nov 21 2026 review: the burn passed with the row still 'Burn (Need Cleaning)' one frame after the cleaning, as
-- nothing was asked of the tab. Vanilla's panel and ZeD's tab both drop 'Need Cleaning' once the game's flag is off.)
X.treat("burn", "ContextMenu_Clean_Burn", function(b) return not b:isNeedBurnWash() end, nil, ZeD.tr("IGUI_health_NeedCleaning"))
X.treat("bite", "ContextMenu_Bandage", function(b) return b:bandaged() end, "IGUI_health_Bandaged", nil)
-- 3e. the bleeding groin through the wheel's Medicine list
Q.step(4, function()
    local c = X.case("bleeding")
    local DH = ZeD.DpadWheels and ZeD.DpadWheels.H
    if c.off or not (DH and DH.treatments) then Q.skip("a bandage from the wheel", "no bleeding part or no wheel handler"); return end
    local ok, list = pcall(DH.treatments, p, pn)
    Q.check(ok and type(list) == "table" and #list > 0, "the wheel's Medicine list has treatments for the wounded body", ok and (#list .. " entries") or list)
    local partName = BodyPartType.getDisplayName(BodyPartType.Groin)
    for _, e in ipairs(ok and list or {}) do
        if not S.wheelRun and e.detail == partName and X.has(e.name, X.word("ContextMenu_Bandage")) then S.wheelRun = e end
    end
    if not S.wheelRun then Q.skip("a bandage from the wheel", "no Bandage entry for " .. tostring(partName)); return end
    local okR, eR = pcall(S.wheelRun.run)
    Q.check(okR, "the wheel's '" .. tostring(S.wheelRun.name) .. "' runs", eR)
end)
X.untilMs(9000, function() return not S.wheelRun or X.part(X.case("bleeding")):bandaged() end, function(ok)
    if S.wheelRun then Q.check(ok, "the wheel's bandage went on the groin", "queue " .. X.queued()) end
end)
X.untilMs(1500, function() return not S.wheelRun or X.shownHas(X.case("bleeding"), X.word("IGUI_health_Bandaged")) end, function(ok)
    if S.wheelRun then Q.check(ok, "and the tab says Bandaged for it", X.labels(X.entry(X.shown(), "Groin"))) end
    X.speed(1)
    RT.bounds(Q, "health tab, treated")
end)
-- 3f. the controller's focus on a wounded part shows its detail
Q.step(4, function()
    local F, Det = RT.focus(), ZeD.Input and ZeD.Input.Detector
    local c = X.case("fracture")
    if not (F and Det and F.focusWhere and F.claimFocus) or c.off then Q.skip("the controller on a part", "no focus manager, or no fracture"); return end
    X.healthTab()
    if not RT.cw() then Q.check(false, "the Character window is there for the controller", "no window"); return end
    local ok, el = pcall(function()
        Det.setLockedMode(Det.MODE_GAMEPAD)
        S.padLocked = true
        F.claimFocus(RT.cw())
        RT.cw()._healthFigureExpanded = true
        return F.focusWhere(RT.cw(), "charTabContent", function(e) return e.partName == c.fig end)
    end)
    S.padOn = ok and el ~= nil
    if not S.padOn then Q.skip("the controller on a part", "the part took no focus: " .. tostring(el)) end
end)
X.untilMs(1500, function() return not S.padOn or (RT.cw() and RT.cw()._healthActivePart == "Right Lower Leg") end, function(ok)
    if S.padOn then
        Q.check(ok, "the controller's focus on the splinted leg makes it the tab's active part", tostring(RT.cw() and RT.cw()._healthActivePart))
        RT.bounds(Q, "health tab, controller detail")
    end
    X.padOff()
end)
function X.padOff()
    if not S.padLocked then return end
    S.padLocked = false
    pcall(function()
        local Det = ZeD.Input.Detector
        Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
        RT.focus().releaseFocus()
    end)
end

-- ===================================================================== 4. infection, then everything healed
-- (the body is never infected here: an infected body dies, at once with the sandbox's mortality on Instant, and the
-- Health tab never reads the zombie infection, it shows only the wound's own Infected word; ZeD's moodle checks in
-- section 5 compare the whole moodle list, ZOMBIE included, with the game's)
Q.step(4, function()
    local c = X.case("bite")
    Q.check(bd:IsInfected() == false, "the bite was kept as a wound only: the game says not infected", "infection level " .. tostring(st:get(CharacterStat.ZOMBIE_INFECTION)))
    -- (Nov 21 2026, second run: this asked for the word Bitten on the BANDAGED hand and failed. The game's own
    -- BodyPart.setBandaged(true, ...) lowers the part's bitten, scratched, cut, deep wound and bleeding flags and keeps
    -- only their clocks; vanilla's health panel reads the same flags and says only Bandaged. So under the bandage the
    -- tab must say what the game says; the bandage taken off, the game raises the bite again from its clock and the
    -- tab must name it again.)
    local d = X.fresh()
    if d and not c.off then
        local b = X.part(c)
        Q.check(X.hasLabel(X.entry(d, c.list), X.word("IGUI_health_Bitten")) == b:bitten(), "the bitten hand: the tab says Bitten only when the game does",
            "row: " .. X.labels(X.entry(d, c.list)) .. "; the game: bitten " .. tostring(b:bitten()) .. ", bandaged " .. tostring(b:bandaged()) .. ", bite clock " .. string.format("%.1f", b:getBiteTime()))
        if b:bandaged() then pcall(function() b:setBandaged(false, 0) end) end
        pcall(X.noInfection)
        S.biteBack = b:bitten()
        if not S.biteBack then Q.skip("the bandage off the bitten hand", "the game did not raise the bite again (bite clock " .. string.format("%.1f", b:getBiteTime()) .. ")") end
    end
end)
X.untilMs(1500, function() return not S.biteBack or X.shownHas(X.case("bite"), X.word("IGUI_health_Bitten")) end, function(ok)
    if not S.biteBack then return end
    S.biteShown = ok
    local e = X.entry(X.shown(), "Right Hand")
    Q.check(ok, "the bandage off the bitten hand: the tab names it Bitten again", "row: " .. X.labels(e))
    Q.check(not X.hasLabel(e, X.word("IGUI_health_Bandaged")), "and it no longer says Bandaged", "row: " .. X.labels(e))
end)
Q.step(2, function()
    local c = X.case("bite")
    -- (SetBitten(false) FIRST: the game's SetBitten sets the part infected whatever its argument; the infection comes
    -- off after it, in this same call, before the game's next update can copy it to the body)
    pcall(function() local b = X.part(c); b:SetBitten(false); b:SetInfected(false); b:SetFakeInfected(false); b:setBiteTime(0); b:setBandaged(false, 0) end)
    pcall(X.noInfection)
    Q.check(not X.part(c):bitten() and not X.part(c):IsInfected(), "cured: the bite is off the hand and the hand is not infected",
        "bitten " .. tostring(X.part(c):bitten()) .. ", infected " .. tostring(X.part(c):IsInfected()))
end)
X.untilMs(1500, function() return not X.shownHas(X.case("bite"), X.word("IGUI_health_Bitten")) end, function(ok)
    -- (Nov 21 2026 review: only when the tab named the bite just before the cure. In the second run the hand was
    -- still bandaged here, the tab had never said Bitten, and this passed on its first look whatever the tab did.)
    if not S.biteShown then Q.skip("cured: the tab drops Bitten from the hand", "the tab did not name the bite before the cure"); return end
    Q.check(ok, "cured: the tab drops Bitten from the hand", X.labels(X.entry(X.shown(), "Right Hand")))
end)
Q.step(2, function()
    X.clearQueue()
    X.healAll()
end)
X.untilMs(2000, function() return X.left() == 0 end, function(ok)
    local d = X.shown()
    Q.check(ok, "everything healed: the tab lists no part it did not list at the start", X.left() .. " left, " .. tostring(d and d.injuredCount) .. " listed")
    local okC, calm = pcall(HT.calm, d)
    if d and d.injuredCount == 0 then Q.check(okC and calm == true, "and it is calm", tostring(calm)) end
    local bad = {}
    for _, c in ipairs(W) do
        local fo = X.figureOk(c.fig)
        if not fo then bad[#bad + 1] = c.fig end
    end
    Q.check(#bad == 0, "and the figure shows every wounded part healthy again", table.concat(bad, ", "))
    local DH = ZeD.DpadWheels and ZeD.DpadWheels.H
    if DH and DH.treatments then
        local okT, list = pcall(DH.treatments, p, pn)
        Q.check(okT and #list == 0, "and the wheel's Medicine list has no treatment left", okT and (#list .. " entries") or list)
    end
end)
Q.step(8, function()
    local w = RT.cw()
    local sh = X.shown()
    Q.check(#(w and w._healthInjuryZones or {}) <= #(sh and sh.entries or {}), "and no injury row is left over on the tab", #(w and w._healthInjuryZones or {}) .. " rows, " .. #(sh and sh.entries or {}) .. " listed")
    RT.bounds(Q, "health tab, healed")
    local okB, whyB = X.bodyClean()
    Q.check(okB, "after the wounds: the body is whole again before the states start", whyB)
end)

-- ===================================================================== 5. states and moodles
function X.setStat(k, f, abs)
    local cs = CharacterStat[k]
    if not cs then return end
    local v = abs
    if not v then
        local lo, hi = cs:getMinimumValue(), cs:getMaximumValue()
        v = lo + (hi - lo) * f
    end
    st:set(cs, v)
end
function X.level(mood)
    local n = 0
    pcall(function() n = p:getMoodles():getMoodleLevel(MoodleType[mood]) end)
    return n
end
function X.gameMoodles()
    local out = {}
    local md = p:getMoodles()
    for _, e in ipairs(MO.order()) do
        local t = MoodleType[e[1]]
        local lvl = t and md:getMoodleLevel(t) or 0
        if e[1] == "FOOD_EATEN" and lvl < 3 then lvl = 0 end
        if lvl > 0 then out[#out + 1] = e[1] .. ":" .. lvl end
    end
    return table.concat(out, " "), #out
end
function X.zedMoodles()
    local L = MO.getLayer(pn)
    local out = {}
    for _, m in ipairs(L and L._list or {}) do out[#out + 1] = tostring(m.key) .. ":" .. tostring(m.level) end
    return table.concat(out, " "), #out
end
function X.moodlesOff()
    local L = MO.getLayer(pn)
    if not L then return "ZeD has no moodle layer for the player" end
    if MO.standIn(pn) then return "another mod draws the moodles" end
    if not L._show then return "the moodles are hidden" end
    return nil
end
-- ZeD's list is the game's, its rect counts them and lies on screen
function X.sync(label)
    X.untilMs(1200, function() return X.moodlesOff() or X.gameMoodles() == X.zedMoodles() end, function(ok)
        local why = X.moodlesOff()
        if why then Q.skip("moodles (" .. label .. ")", why); return end
        local g, gn = X.gameMoodles()
        local z, zn = X.zedMoodles()
        Q.check(ok, "moodles (" .. label .. "): ZeD's list is the game's, key and level", "game [" .. g .. "] ZeD [" .. z .. "]")
        local r = MO.rect(pn)
        if not r then Q.check(false, "moodles (" .. label .. "): ZeD has a place for them", "no rect"); return end
        local sw, sh = RT.core:getScreenWidth(), RT.core:getScreenHeight()
        Q.check(r.n == zn, "moodles (" .. label .. "): the place counts " .. zn, tostring(r.n))
        Q.check(r.x >= 0 and r.y >= 0 and r.x + r.w <= sw and r.y + r.h <= sh, "moodles (" .. label .. "): all " .. zn .. " lie on the screen (" .. tostring(r.place) .. ")",
            string.format("%d,%d %dx%d in %dx%d", math.floor(r.x), math.floor(r.y), math.floor(r.w), math.floor(r.h), sw, sh))
    end)
end
local M = {
    { id = "food poisoning", mood = "SICK", set = function() X.setStat("FOOD_SICKNESS", 0.8) end },
    { id = "a cold", mood = "HAS_A_COLD", set = function() bd:setHasACold(true); bd:setColdStrength(60) end },
    { id = "drunk", mood = "DRUNK", set = function() X.setStat("INTOXICATION", 0.7) end },
    { id = "panic", mood = "PANIC", set = function() X.setStat("PANIC", 0.9) end },
    { id = "stress", mood = "STRESS", set = function() X.setStat("STRESS", 0.8) end },
    { id = "boredom", mood = "BORED", set = function() X.setStat("BOREDOM", 0.8) end },
    { id = "unhappy", mood = "UNHAPPY", set = function() X.setStat("UNHAPPINESS", 0.8) end },
    { id = "pain", mood = "PAIN", set = function() X.setStat("PAIN", 0.7) end },
    { id = "wet", mood = "WET", set = function() X.setStat("WETNESS", 0.8) end },
    { id = "tired", mood = "TIRED", set = function() X.setStat("FATIGUE", 0.85) end },
    { id = "out of breath", mood = "ENDURANCE", set = function() X.setStat("ENDURANCE", 0.1) end },
    { id = "hot", mood = "HYPERTHERMIA", set = function() X.setStat("TEMPERATURE", nil, 40.5) end, alone = true },
    { id = "cold", mood = "HYPOTHERMIA", set = function() X.setStat("TEMPERATURE", nil, 33.5) end, alone = true },
}
Q.step(4, function()
    if RT.isOpen() then RT.pairShut() end            -- (the moodles alone first; the windows come back for the pile)
end)
X.sync("none yet")
for _, m in ipairs(M) do
    Q.step(2, function()
        S.holds[#S.holds + 1] = m.set
        m.at = #S.holds
        pcall(m.set)
    end)
    X.untilMs(3000, function() return X.level(m.mood) > 0 end, function(ok)
        m.on = ok
        if not ok then
            Q.skip(m.id, "the game did not raise its " .. m.mood .. " moodle from the value set")
            table.remove(S.holds, m.at)
            return
        end
        Q.say(m.id .. ": the game's " .. m.mood .. " moodle is at " .. X.level(m.mood))
    end)
    X.sync(m.id)
    if m.alone then
        -- (hot and cold are one stat: the hot hold goes before the cold one is set)
        Q.step(1, function() if m.on then table.remove(S.holds, m.at) end end)
    end
end
-- the full pile in each Moodles place, the windows open over it
for _, place in ipairs({ 2, 3, 1 }) do
    Q.step(3, function()
        RT.pairOpen()
        local ok, err = pcall(function() ZeD.Settings.moodlePlaceOption:setValue(place) end)
        if not ok then Q.check(false, "the Moodles place option takes " .. place, err) end
    end)
    X.pause(350)
    X.sync("the pile, place " .. place)
    Q.step(1, function() RT.bounds(Q, "the pile of moodles, place " .. place) end)
end
-- the Health tab's own fill and the Thermal tab, sick and hot
Q.step(3, function()
    X.healthTab()
    local ok, fill = pcall(HT.gatherFill, p)
    Q.check(ok and fill ~= nil, "the Health tab's Moodles and Fitness blocks read the sick body without an error", ok and "" or fill)
    local d = X.fresh()
    if d then Q.check(type(d.overall) == "number" and math.abs(d.overall - bd:getOverallBodyHealth()) < 0.5, "sick: overall health is the game's", tostring(d.overall)) end
end)
Q.step(10, function()
    local ok = false
    pcall(function() ok = RT.charTab("thermal") end)
    if not ok then S.noThermal = true; Q.skip("the Thermal tab", "no thermal tab on the strip") end
end)
X.pause(500)
Q.step(1, function()
    if S.noThermal then return end
    local w = RT.cw()
    Q.check(w and w._activeTab == "thermal", "the Thermal tab opens", tostring(w and w._activeTab))
    local ok, d = pcall(ZeD.ThermalTab.gatherData, p)
    local core = nil
    pcall(function() core = bd:getThermoregulator():getCoreCelcius() end)
    Q.check(ok and d and core and math.abs(d.coreTemp - core) < 0.3, "its core temperature is the game's", ok and (tostring(d.coreTemp) .. " vs " .. tostring(core)) or d)
    local n = 0
    for _ in pairs(ok and d.nodes or {}) do n = n + 1 end
    Q.check(n >= 12, "it has a reading for the body's parts", n .. " parts")
    RT.bounds(Q, "thermal tab, the pile on")
    X.healthTab()
end)
-- all cleared at once
function X.clearStates()
    S.holds = {}
    local f = S.found
    for k, v in pairs(f.stats) do pcall(function() st:set(CharacterStat[k], v) end) end
    pcall(function() st:set(CharacterStat.PANIC, 0); st:set(CharacterStat.PAIN, 0) end)
    pcall(function() bd:setHasACold(f.cold and true or false); bd:setColdStrength(f.coldStr or 0) end)
    pcall(function()
        local parts = bd:getBodyParts()
        for i = 0, parts:size() - 1 do if f.partWet and f.partWet[i] then parts:get(i):setWetness(f.partWet[i]) end end
    end)
    pcall(function() bd:setInfected(false) end)
end
Q.step(3, function() X.clearStates() end)
X.untilMs(4000, function() local _, n = X.gameMoodles(); return n == 0 end, function(ok)
    local g = X.gameMoodles()
    if not ok then Q.say("note: the game still has moodles on after the stats went back: [" .. g .. "]") end
end)
X.sync("all cleared")

-- ===================================================================== 6. sleep, sit, rest
local DH = ZeD.DpadWheels and ZeD.DpadWheels.H
function X.sleepSlice()
    local ok, r = pcall(DH.sleep, p, pn)
    if not ok then Q.check(false, "the wheel's sleep handler ran without an error", r); return nil end
    return r
end
function X.sitSlices()
    local ok, r = pcall(DH.sitWheel, p, pn)
    if not ok then Q.check(false, "the wheel's sit handler ran without an error", r); return nil end
    return r
end
function X.sitting()
    local s = false
    pcall(function() s = p:isSitOnGround() or p:isSittingOnFurniture() end)
    return s
end
function X.tired()
    X.setStat("FATIGUE", 0.9)
    pcall(function() st:set(CharacterStat.PANIC, 0); st:set(CharacterStat.PAIN, 0) end)
end
function X.sleepUI()
    local ui = nil
    pcall(function() ui = getPlayerData(pn).sleepingUI end)
    return ui
end
-- press Yes on the game's sleep question; save() is a no-op for the press (falling asleep saves the game). The third
-- value says whether there was a question to press: with none, the game's onConfirmSleep is called directly so the
-- scene can go on, and the caller's check FAILS (the wheel's Sleep raised no question).
function X.confirmSleep(bed)
    local d = ISWorldObjectContextMenu.sleepDialog
    local asked = (d ~= nil and d.yes ~= nil) and true or false
    local realSave = save
    save = function() end
    local ok, err = pcall(function()
        if asked then d:onClick(d.yes)
        else
            if d then d:destroy() end
            ISWorldObjectContextMenu.sleepDialog = nil
            ISWorldObjectContextMenu.onConfirmSleep(nil, { internal = "YES" }, pn, bed)
        end
    end)
    save = realSave
    return ok, err, asked
end
-- what the press did, for the check's line
function X.confirmDetail(ok, err, asked)
    if not asked then return "no question was up: the game's onConfirmSleep was called directly" end
    if not ok then return tostring(err) end
    return "the question's own Yes pressed"
end
function X.wake()
    pcall(function() getSleepingEvent():wakeUp(p) end)
    if p:isAsleep() then pcall(function() p:forceAwake() end) end
    if p:isAsleep() then pcall(function() p:setAsleep(false) end) end
    pcall(function() UIManager.setFadeBeforeUI(pn, false) end)
    pcall(function() UIManager.FadeIn(pn, 1) end)
    X.speed(1)
end
function X.getUp()
    pcall(function()
        if p:isSitOnGround() or p:isSittingOnFurniture() then p:StopAllActionQueue(); p:setVariable("forceGetUp", true) end
    end)
end
function X.removeObj(o)
    if not o then return end
    local sq = nil
    pcall(function() sq = o:getSquare() end)
    -- (the plain removal: the one-argument calls first look for the other tiles of a couch or a bed, find none
    -- for a lone placed tile, warn "Failed to find all parts of a multi-tile object" and remove nothing: the first
    -- run left its chair standing that way)
    if sq then
        pcall(function() if sq:getObjects():contains(o) then sq:RemoveTileObject(o, false) end end)
        pcall(function() if sq:getObjects():contains(o) then sq:transmitRemoveItemFromSquare(o, false) end end)
    end
end
function X.objGone(o)
    local there = false
    pcall(function() local sq = o:getSquare(); there = sq ~= nil and sq:getObjects():contains(o) end)
    return not there
end
-- a seat tile (a chair or a bed) on a free square near home: the first sprite the game has seat places for
function X.place(prefixes, dx, dy, wantBed)
    local sq = getCell():getGridSquare(math.floor(p:getX()) + dx, math.floor(p:getY()) + dy, 0)
    if not (sq and sq:isFree(false)) then return nil, "the square is not free" end
    for _, pre in ipairs(prefixes) do
        for i = 0, 63 do
            local name = pre .. i
            local spr = getSprite(name)
            local good = spr ~= nil
            if good and not wantBed then
                -- a chair of one tile only (one tile of a couch is half a couch)
                local grid = nil
                pcall(function() grid = spr:getSpriteGrid() end)
                if grid ~= nil then good = false end
            end
            if good and wantBed then
                good = false
                pcall(function() good = spr:getProperties():has("BedType") end)
            end
            if good then
                local o, n = nil, 0
                pcall(function() o = IsoObject.new(sq, name, nil, false) end)
                pcall(function() n = SeatingManager.getInstance():getTilePositionCount(o) end)
                if o and n > 0 then
                    sq:AddTileObject(o)
                    S.objs[#S.objs + 1] = o
                    return o, name
                end
            end
        end
    end
    return nil, "no sprite with seat places"
end

-- 6a. refused: not tired, then panicked
Q.step(4, function()
    if not (DH and DH.sleep and DH.sitWheel) then S.noWheel = true; Q.skip("sleep and sit through the wheel", "DpadWheels.H.sleep / sitWheel are not there"); return end
    X.closeMenu()
    X.healthTab()
    X.setStat("FATIGUE", 0)
    local r = X.sleepSlice()
    Q.check(r and r.off ~= nil and r.run == nil, "not tired: the sleep slice is off, with the game's reason", tostring(r and r.off))
    S.holds = { function() X.setStat("FATIGUE", 0.9); X.setStat("PANIC", 0.95) end }
    pcall(function() p:setLastHourSleeped(math.floor(p:getHoursSurvived()) - 10) end)
end)
X.untilMs(3000, function() return S.noWheel or X.level("PANIC") >= 1 end, function(ok)
    if S.noWheel then return end
    if not ok then Q.skip("panicked: sleep refused", "the game raised no panic moodle") else
        local r = X.sleepSlice()
        Q.check(r and r.off ~= nil and r.run == nil, "tired but panicked: the sleep slice is off", tostring(r and r.off))
    end
    S.holds = { X.tired }
end)
-- 6b. asleep on the ground
X.untilMs(4000, function() if S.noWheel then return true end; local ok, r = pcall(DH.sleep, p, pn); return ok and r and r.run ~= nil end, function(ok)
    if S.noWheel then return end
    local r = X.sleepSlice()
    S.canSleep = ok and r and r.run ~= nil
    if not S.canSleep then Q.skip("asleep on the ground", "the sleep slice stays off: " .. tostring(r and r.off)); return end
    Q.check(r.detail == getText("ContextMenu_SleepOnGround"), "tired and calm: the sleep slice says the ground", tostring(r.detail))
    local ok1, e1 = pcall(r.run, p, pn)
    local ok2, e2 = pcall(r.run, p, pn)
    Q.check(ok1 and ok2, "Sleep pressed twice raises nothing", tostring(e1) .. " " .. tostring(e2))
    -- (Nov 21 2026, second run: the question was counted here, in the frame of the presses, and came to 0. The game's
    -- UIManager.AddUI only queues a new window; it is on the screen's list after the next UI update. So: the game has
    -- its question now, and the count waits until it is listed.)
    S.asked = ISWorldObjectContextMenu.sleepDialog
    Q.check(S.asked ~= nil, "and the game has its sleep question", tostring(S.asked ~= nil))
end)
-- every sleep question on screen (any window whose answer goes to the game's onConfirmSleep), and is the game's own
-- one among them
function X.sleepQuestions()
    local n, own = 0, false
    for _, root in ipairs(RT.roots()) do
        local vis = false
        pcall(function() vis = root.e:isVisible() end)
        if vis and type(root.t) == "table" and root.t.onclick ~= nil and root.t.onclick == ISWorldObjectContextMenu.onConfirmSleep then
            n = n + 1
            if root.t == ISWorldObjectContextMenu.sleepDialog then own = true end
        end
    end
    return n, own
end
X.untilMs(2000, function() return not S.canSleep or X.sleepQuestions() >= 1 end, function()
    if not S.canSleep then return end
    local n, own = X.sleepQuestions()
    Q.check(n == 1 and own, "and it asks once for the two presses", n .. " question(s) up, the game's own one among them " .. tostring(own))
    RT.bounds(Q, "the sleep question up")
end)
Q.step(10, function()
    if not S.canSleep then return end
    local ok, err, asked = X.confirmSleep(nil)
    Q.check(ok and asked, "Yes on the sleep question", X.confirmDetail(ok, err, asked))
end)
function X.asleepChecks(label)
    X.untilMs(5000, function() return not S.canSleep or p:isAsleep() end, function(ok)
        if not S.canSleep then return end
        S.slept = ok
        if not ok then Q.skip(label .. ": asleep", "the game did not put the character to sleep (queue " .. X.queued() .. ")") end
    end)
    X.pause(1300)
    Q.step(1, function()
        if not (S.canSleep and S.slept) then return end
        Q.check(p:isAsleep(), label .. ": asleep")
        local ui = X.sleepUI()
        local vis = false
        pcall(function() vis = ui:isVisible() end)
        Q.check(vis, label .. ": the game's sleep panel is up")
        Q.check(ISSleepingUI._zedOrigRender ~= nil and ISSleepingUI.render ~= ISSleepingUI._zedOrigRender and ui and ui._zedAlarmAt ~= nil,
            label .. ": ZeD's clock radio drew on it", "drawn at " .. tostring(ui and ui._zedAlarmAt))
        local r = X.sleepSlice()
        Q.say(label .. ": the sleep slice while asleep: off " .. tostring(r and r.off) .. ", run " .. tostring(r and r.run ~= nil))
        local okA, eA = pcall(CW.toggleBothPaired, pn)
        local okB, eB = pcall(CW.toggleBothPaired, pn)
        Q.check(okA and okB, label .. ": the windows toggled twice while asleep raise nothing", tostring(eA) .. " " .. tostring(eB))
        Q.check(X.fresh() ~= nil, label .. ": the Health tab reads the sleeping body")
        RT.bounds(Q, label .. ", asleep")
        X.wake()
    end)
    X.untilMs(4000, function() return not S.slept or not p:isAsleep() end, function(ok)
        if not (S.canSleep and S.slept) then return end
        Q.check(ok, label .. ": woken", "asleep " .. tostring(p:isAsleep()))
        if not ok then X.wake() end
    end)
    X.untilMs(3000, function()
        if not S.slept then return true end
        local vis = true
        pcall(function() vis = X.sleepUI():isVisible() end)
        return not vis
    end, function(ok)
        if not (S.canSleep and S.slept) then return end
        Q.check(ok, label .. ": the sleep panel went with the sleep")
        X.speed(1)
        X.healthTab()
    end)
    X.untilMs(2500, function() return not S.slept or (RT.cw() and RT.cw()._activeTab == "health") end, function(ok)
        if not (S.canSleep and S.slept) then return end
        Q.check(ok, label .. ": awake, the Health tab opens again")
        RT.bounds(Q, label .. ", awake")
    end)
end
X.asleepChecks("on the ground")
-- 6c. sit on the ground, exhausted, up again
Q.step(6, function()
    if S.noWheel then return end
    S.holds = {}
    X.clearQueue()
    local sl = X.sitSlices()
    if not (sl and sl[1] and sl[1].run) then S.noSit = true; Q.skip("sit on the ground", "the wheel has no sit slice"); return end
    Q.check(sl[1].name == getText("ContextMenu_SitGround"), "standing: the wheel's first sit slice sits on the ground", tostring(sl[1].name))
    local ok1, e1 = pcall(sl[1].run, p, pn)
    Q.check(ok1, "Sit on ground runs", e1)
end)
X.untilMs(6000, function() return S.noWheel or S.noSit or p:isSitOnGround() end, function(ok)
    if S.noWheel or S.noSit then return end
    S.sat = ok
    if not ok then Q.skip("sat on the ground", "the game did not sit the character down"); return end
    local sl = X.sitSlices()
    Q.check(sl and sl[1].name == ZeD.tr("UI_ZeD_Wheel_GetUp"), "sat: the same slice now gets up", tostring(sl and sl[1].name))
    S.holds = { function() X.setStat("ENDURANCE", 0.05); X.setStat("FATIGUE", 0.9) end }
    pcall(function() ISTimedActionQueue.add(ISRestAction:new(p, nil, true)) end)
end)
X.untilMs(3000, function() return not S.sat or X.level("ENDURANCE") >= 1 end, function(ok)
    if not S.sat then return end
    if ok then Q.say("exhausted while sitting: ENDURANCE moodle " .. X.level("ENDURANCE") .. ", TIRED " .. X.level("TIRED"))
    else Q.skip("exhausted while sitting", "the game raised no endurance moodle") end
end)
X.sync("sat and exhausted")
Q.step(2, function()
    if not S.sat then return end
    RT.bounds(Q, "sat on the ground")
    local r = X.sleepSlice()
    Q.say("sat: the sleep slice says " .. tostring(r and (r.detail or r.off)))
    S.holds = {}
    X.setStat("ENDURANCE", 1)
    local sl = X.sitSlices()
    local ok, err = pcall(sl[1].run, p, pn)
    Q.check(ok, "Get up runs", err)
    pcall(CW.toggleBothPaired, pn)          -- the windows shut while the character gets up
end)
X.untilMs(7000, function() return not S.sat or not X.sitting() end, function(ok)
    RT.pairOpen()
    if not S.sat then return end
    Q.check(ok, "the character is up again", "sitting " .. tostring(X.sitting()))
    if not ok then X.getUp() end
    local sl = X.sitSlices()
    if ok and sl then Q.check(sl[1].name == getText("ContextMenu_SitGround"), "up: the slice sits again", tostring(sl[1].name)) end
end)
-- 6d. a chair: sat on, named, taken away
function X.seatScene(label, prefixes, dy, wantBed, sleepToo)
    local t = {}
    Q.step(8, function()
        if S.noWheel then return end
        X.clearQueue()
        X.speed(1)
        local okP, o, why = pcall(X.place, prefixes, 2, dy, wantBed)
        if not (okP and o) then Q.skip(label, "it could not be placed: " .. tostring(okP and why or o)); return end
        t.o = o
        Q.say(label .. ": placed " .. tostring(why))
    end)
    Q.step(20, function()
        if not t.o then return end
        local okN, seat = pcall(DH.nearestSeat, p)
        Q.check(okN and seat == t.o, label .. ": the wheel's nearest seat is the one placed", tostring(seat))
        local sl = X.sitSlices()
        -- (the seat's name is ISWorldObjectContextMenu.getMoveableDisplayName: the game has no global of that name)
        local nm = nil
        pcall(function() nm = ISWorldObjectContextMenu.getMoveableDisplayName(t.o) end)
        if sl and sl[2] and nm then Q.check(X.has(sl[2].name, nm), label .. ": the wheel's seat slice names the seat", tostring(sl[2].name) .. " vs " .. tostring(nm))
        elseif sl and sl[2] then Q.skip(label .. ": the wheel's seat slice names the seat", "the game has no name for this seat; the slice says " .. tostring(sl[2].name)) end
        t.run = sl and sl[2] and sl[2].run
        if not t.run then Q.skip(label .. ": sat on", "the wheel's seat slice is off: " .. tostring(sl and sl[2] and sl[2].off)); return end
        local ok, err = pcall(t.run, p, pn)
        Q.check(ok, label .. ": '" .. tostring(sl[2].name) .. "' runs", err)
    end)
    X.untilMs(10000, function() return not t.run or p:isSittingOnFurniture() end, function(ok)
        if not t.run then return end
        t.sat = ok
        if not ok then Q.skip(label .. ": sat on", "the game did not seat the character (queue " .. X.queued() .. ")"); X.clearQueue(); return end
        local sl = X.sitSlices()
        Q.check(sl and sl[1].name == ZeD.tr("UI_ZeD_Wheel_GetUp"), label .. ": seated, the first slice gets up", tostring(sl and sl[1].name))
        S.holds = { X.tired }
        pcall(function() p:setLastHourSleeped(math.floor(p:getHoursSurvived()) - 10) end)
        RT.bounds(Q, label .. ", seated")
    end)
    X.untilMs(3000, function() if not t.sat then return true end; local ok, r = pcall(DH.sleep, p, pn); return ok and r and r.run ~= nil end, function(ok)
        if not t.sat then S.canSleep = false; return end
        local r = X.sleepSlice()
        local name = nil
        -- (Nov 21 2026, second run: a bare getMoveableDisplayName(...) here called nil, two Java exceptions in the log,
        -- and left name nil, so the check below passed whatever the slice said)
        pcall(function() name = ISWorldObjectContextMenu.getMoveableDisplayName(p:getSitOnFurnitureObject()) end)
        if ok and r and name == nil then Q.skip(label .. ": the sleep slice names the seat", "the game has no name for this seat; the slice says " .. tostring(r.detail))
        elseif ok and r then Q.check(r.detail == name, label .. ": the sleep slice names the seat", tostring(r.detail) .. " vs " .. tostring(name))
        else Q.skip(label .. ": the sleep slice names the seat", "the slice is off: " .. tostring(r and r.off)) end
        S.canSleep = (sleepToo and ok and r and r.run ~= nil) and true or false
        S.slept = false
        if S.canSleep then
            local okR, eR = pcall(r.run, p, pn)
            Q.check(okR, label .. ": Sleep runs from the seat", eR)
        end
    end)
    if sleepToo then
        Q.step(10, function()
            if not S.canSleep then return end
            local ok, err, asked = X.confirmSleep(t.o)
            Q.check(ok and asked, label .. ": Yes on the sleep question", X.confirmDetail(ok, err, asked))
        end)
        X.asleepChecks(label)
        Q.step(1, function() if S.slept then Q.say(label .. ": slept with bed type " .. tostring(p:getBedType())) end end)
    end
    Q.step(4, function() S.holds = {}; X.setStat("FATIGUE", 0.2); if t.sat then X.getUp() end end)
    X.untilMs(7000, function() return not t.sat or not X.sitting() end, function(ok)
        if t.sat then Q.check(ok, label .. ": the character is up again", "sitting " .. tostring(X.sitting())) end
    end)
    Q.step(6, function()
        if not t.o then return end
        X.clearQueue()
        X.removeObj(t.o)
        Q.check(X.objGone(t.o), label .. ": the placed tile is off the square again")
        local sl = X.sitSlices()
        local okN, seat = pcall(DH.nearestSeat, p)
        Q.check(okN and seat ~= t.o, label .. ": taken away, the wheel no longer finds it", tostring(seat))
        if sl and seat == nil then Q.check(sl[2].run == nil and sl[2].off ~= nil, label .. ": taken away, the seat slice says there is no seat", tostring(sl[2].off)) end
    end)
end
X.seatScene("a chair", { "furniture_seating_indoor_01_", "furniture_seating_outdoor_01_", "furniture_seating_indoor_02_" }, 0, false, false)
X.seatScene("a bed", { "furniture_bedding_01_" }, 2, true, true)

-- ===================================================================== PUT BACK
Q.mark()
-- the body FIRST, in its own step: healed by the script and, with god mode ON, by the game itself on its next
-- update. Nothing before it in the put-back can throw past it.
Q.step(1, function()
    S.holds = {}
    pcall(X.speed, 1)
    pcall(X.healAll)
    pcall(function() p:setInvincible(true) end)
    pcall(function() p:setGodMod(true) end)
end)
Q.step(2, function()
    S.holds = {}
    if save == nil then Q.say("ERR the game's save() is missing") end
    if p:isAsleep() then X.wake() end
    pcall(function() if ISWorldObjectContextMenu.sleepDialog then ISWorldObjectContextMenu.sleepDialog:destroy(); ISWorldObjectContextMenu.sleepDialog = nil end end)
    X.closeMenu()
    X.clearQueue()
    X.getUp()
    X.padOff()
    X.speed(1)
    pcall(function() UIManager.setFadeBeforeUI(pn, false) end)
    pcall(function() UIManager.FadeIn(pn, 1) end)
end)
X.untilMs(6000, function() return not X.sitting() and not p:isAsleep() end, function(ok)
    if not ok then
        pcall(function() p:setSitOnGround(false) end)
        pcall(function() p:setSitOnFurnitureObject(nil); p:setSittingOnFurniture(false) end)
    end
    local left = 0
    for _, o in ipairs(S.objs) do
        X.removeObj(o)
        if not X.objGone(o) then left = left + 1 end
    end
    if #S.objs > 0 then Q.check(left == 0, "put back: the placed chair and bed are off the ground", left .. " of " .. #S.objs .. " still there") end
    S.objs = {}
end)
-- healed again (the steps above may have run a game update with a wound on), then PROVED, while god mode is still ON
Q.step(2, function() pcall(X.healAll) end)
X.untilMs(4000, function() return X.bodyClean() end, function()
    local ok, why = X.bodyClean()
    if not ok and not p:isDead() then
        pcall(X.healAll)
        ok, why = X.bodyClean()
    end
    S.healed = ok
    Q.check(ok and S.fullHeal == true, "put back: the character is alive and healed by the game's full heal, BodyDamage:RestoreToFullHealth() (health 100, no wound on any part, no fracture, not infected)",
        why .. "; the full heal ran " .. tostring(S.fullHeal))
    Q.say("the guard topped his health up " .. tostring(S.topUps or 0) .. " time(s) in the run")
end)
Q.step(4, function()
    local f = S.found
    -- (the stats after the heal: the game's full heal resets every one of them; in a pcall so nothing here can keep
    -- the god mode decision and the guard's removal below from running)
    pcall(X.clearStates)
    pcall(function() st:set(CharacterStat.ZOMBIE_INFECTION, 0); st:set(CharacterStat.ZOMBIE_FEVER, 0) end)
    if f.lastSleep ~= nil then pcall(function() p:setLastHourSleeped(f.lastSleep) end) end
    if f.place ~= nil then pcall(function() ZeD.Settings.moodlePlaceOption:setValue(f.place) end) end
    -- god mode and invincible as found, but only for a healed body: a hurt one keeps both ON, and the guard is
    -- taken off only now
    if S.healed then
        if f.inv ~= nil then pcall(function() p:setInvincible(f.inv) end) end
        pcall(function() p:setGodMod(f.god and true or false) end)
    else
        pcall(function() p:setInvincible(true) end)
        pcall(function() p:setGodMod(true) end)
        Q.say("ERR the body is not whole: god mode and invincible are left ON")
    end
    S.live = false
    Events.OnTick.Remove(X.safety)
    if f.tod ~= nil then
        pcall(function()
            local gt = getGameTime()
            if math.abs(gt:getTimeOfDay() - f.tod) > 0.05 then gt:setTimeOfDay(f.tod) end
        end)
    end
    -- anything this script gave that a treatment moved out of the kit's list
    pcall(function()
        local inv = p:getInventory()
        local items = inv:getItems()
        for i = items:size() - 1, 0, -1 do
            local it = items:get(i)
            if it:getModData().ZeDQA_spawned then inv:Remove(it) end
        end
    end)
end)
Q.step(10, function()
    local f = S.found
    if f.open then
        RT.pairOpen()
        pcall(RT.charTab, f.tab or "loot")
    else
        RT.pairShut()
    end
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "bx_hlth") end
end)
Q.step(20, function()
    local f = S.found
    local d = X.fresh()
    Q.check(d and d.woundedCount == 0, "put back: the Health tab's data has no wound on the body", tostring(d and d.woundedCount))
    -- (the last look at the body, after every other put-back step)
    local okB, whyB = X.bodyClean()
    if not okB and not p:isDead() then
        pcall(X.healAll)
        pcall(function() p:setGodMod(true); p:setInvincible(true) end)
        S.healed = false
    end
    Q.check(okB, "put back, last look: alive, health 100, no wound on any part, no fracture, not infected", whyB)
    Q.check(not p:isDead() and bd:IsInfected() == false and not p:isAsleep() and not X.sitting(), "put back: alive, not infected, awake, standing")
    if S.healed then
        Q.check(p:isGodMod() == (f.god and true or false), "put back: god mode as found", "found " .. tostring(f.god) .. ", now " .. tostring(p:isGodMod()))
        if f.inv ~= nil then Q.check(p:isInvincible() == f.inv, "put back: invincible as found", "found " .. tostring(f.inv) .. ", now " .. tostring(p:isInvincible())) end
    else
        Q.check(p:isGodMod() == true, "put back: the body was not whole, so god mode is left ON", tostring(p:isGodMod()))
    end
    Q.check(getGameSpeed() == 1, "put back: game speed 1", tostring(getGameSpeed()))
    Q.check(RT.isOpen() == (f.open and true or false), "put back: the windows as found")
    local _, n = X.gameMoodles()
    Q.say("put back: " .. n .. " moodles on, items given left: " .. X.count("Base.Bandage") .. " bandages")
end)
Q.start()
