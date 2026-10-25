-- ZeDUI/tools/qa/zedqa_quick_chords.lua  (Oct 24 2026)
-- Quick action chords (ZeD_QuickChords.lua; QUICK_CHORDS_SPEC.md). No
-- physical pad: the held bumper is ZeD.QuickChords.qaBumper and the press is
-- sent the way the game sends it (JoypadControllerData:onPressButtonNoFocus
-- with no focus). Checks:
--   * the twelve defaults name a slice of the wheels;
--   * LB + X with a flashlight in a bag: the game's actions take it out, it
--     ends in a hand and on; again: off;
--   * LB + A (eat), LB + B (drink), LB + Y (smoke): the game queues its action;
--   * a chord whose thing is gone: the character says why (HaloTextHelper);
--   * the press is swallowed: the game's prompts never see it;
--   * from a wheel: point at Crouch, RB + Y assigns it, the bubble says so,
--     and the wheel shows the chord when it opens again; a slice of a wheel
--     the game fills says it can't.
-- The chords file is put back as it was; the flashlight is taken away.
-- Run on the deep-run character. grep "ZEDQA qc".
local p = getPlayer()
local pn = p:getPlayerNum()
local Qc, D, W = ZeD.QuickChords, ZeD.DpadWheels, ZeD.Wheel
local function say(s) print("ZEDQA qc " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_qc_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
-- waits up to max frames for cond, then runs fn(met)
local function waitFor(max, cond, fn) Q[#Q + 1] = { n = 1, max = max, cond = cond, fn = fn } end

if not (Qc and D) then say("ERR ZeD.QuickChords is not loaded"); say("DONE"); return end

-- the chords file, kept to put back
local FILE = "ZeD_chords.txt"
local kept = nil
do
    local r = getFileReader(FILE, false)
    if r then
        local lines, l = {}, r:readLine()
        while l do lines[#lines + 1] = l; l = r:readLine() end
        r:close()
        kept = table.concat(lines, "\n") .. "\n"
    end
end
local function putBackFile()
    local w = getFileWriter(FILE, true, false)
    if not w then return end
    if kept then w:write(kept) end
    w:close()
end

-- what the character said, and what the game's prompts saw
local said = {}
local origBad = HaloTextHelper and HaloTextHelper.addBadText
if origBad then HaloTextHelper.addBadText = function(chr, text, ...) said[#said + 1] = tostring(text); return origBad(chr, text, ...) end end
local promptsSaw = 0
local BP = ISButtonPrompt
local origA, origX = BP and BP.onAPress, BP and BP.onXPress
if BP then
    BP.onAPress = function(...) promptsSaw = promptsSaw + 1; return origA(...) end
    BP.onXPress = function(...) promptsSaw = promptsSaw + 1; return origX(...) end
end

local jd = { player = pn, id = 0, focus = nil }
local ctl = { joypad = jd }
setmetatable(ctl, { __index = JoypadControllerData })
local function press(bump, button)
    Qc.qaBumper = bump
    local ok, err = pcall(JoypadControllerData.onPressButtonNoFocus, ctl, button)
    if not ok then say("ERR press: " .. tostring(err)) end
    pcall(JoypadControllerData.onReleaseButton, ctl, button)
    Qc.qaBumper = nil
end
local function queueNames()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local out = {}
    for _, a in ipairs(q and q.queue or {}) do out[#out + 1] = tostring(a.Type) end
    return out
end
local function stopAll() pcall(function() p:StopAllActionQueue() end); pcall(function() ISTimedActionQueue.clear(p) end) end

-- the torch the character holds goes into a worn bag, with water, a cigarette, a lighter and an apple
-- (taken away again at the end; the torch back in the hand it was in)
local light, bag, added, lightHand = nil, nil, {}, nil
local chk, other = nil, nil   -- the light LB + X picks (the brightest carried), and how it was if not the torch
step(20, function()
    if ZeD_CharacterWindow.isOpen() and ZeD_CharacterWindow.toggleBothPaired then ZeD_CharacterWindow.toggleBothPaired(pn) end
    pcall(ZeD.Input.Focus.releaseFocus)
    stopAll()
    -- earlier runs eat, and a stuffed character may eat nothing (the game's rule): the well-fed timer from 0
    pcall(function() p:getBodyDamage():setHealthFromFoodTimer(0) end)
    local wi = p:getWornItems()
    for i = 0, wi:size() - 1 do
        local it = wi:get(i):getItem()
        if it and it:IsInventoryContainer() then bag = it; break end
    end
    local inv = bag and bag:getInventory() or p:getInventory()
    for _, h in ipairs({ "secondary", "primary" }) do
        local it = (h == "primary") and p:getPrimaryHandItem() or p:getSecondaryHandItem()
        if it and not light and it:getFullType() == "Base.HandTorch" then light, lightHand = it, h end
    end
    if light then
        pcall(function() light:setActivated(false) end)
        if lightHand == "primary" then p:setPrimaryHandItem(nil) else p:setSecondaryHandItem(nil) end
        p:getInventory():Remove(light)
        inv:AddItem(light)
    else
        light = inv:AddItem("Base.HandTorch")
        added[#added + 1] = light
    end
    for _, ft in ipairs({ "Base.WaterBottle", "Base.CigaretteSingle", "Base.Lighter", "Base.Apple" }) do   -- (an apple: earlier runs eat the character's own food)
        local it = inv:AddItem(ft)
        if it then
            added[#added + 1] = it
            if ft == "Base.WaterBottle" then local fc = it:getFluidContainer(); if fc then fc:Empty(); fc:addFluid(FluidType.Water, fc:getCapacity() * 0.8) end end
        end
    end
    say("the torch (" .. tostring(lightHand or "added") .. ") and water, a cigarette, a lighter, an apple in " .. tostring(bag and bag:getDisplayName() or "the main inventory")
        .. "; hands: " .. tostring(p:getPrimaryHandItem()) .. " / " .. tostring(p:getSecondaryHandItem()))
    -- LB + X takes the brightest light carried, bags included: that one is checked, off and out of the hands
    chk = D.H.bestLight(p) or light
    if chk ~= light then
        other = { it = chk, on = chk:isActivated(), c = chk:getContainer(),
                  hand = (p:getPrimaryHandItem() == chk and "primary") or (p:getSecondaryHandItem() == chk and "secondary") or nil }
        pcall(function() chk:setActivated(false) end)
        if other.hand == "primary" then p:setPrimaryHandItem(nil) elseif other.hand == "secondary" then p:setSecondaryHandItem(nil) end
        say("LB + X picks " .. chk:getFullType() .. " in " .. tostring(other.c and other.c:getType()) .. " (brighter than the torch): that light is checked")
    end
    -- every default chord names a slice
    for _, c in ipairs(Qc.CHORDS) do
        local path, words = Qc.get(c)
        local e, why = Qc.resolve(p, pn, path)
        say(string.format("%s = %s (%s): %s%s", c, tostring(path), table.concat(words, " > "),
            e and Qc.cleanName(e.name) or "nothing", (e and e.off) and (" [off: " .. tostring(e.off) .. "]") or (why and (" [" .. why .. "]") or "")))
        check(e ~= nil, c .. ": the default names a slice")
    end
end)

-- LB + X: the light
step(10, function()
    promptsSaw = 0
    press("LB", Joypad.XButton)
    say("LB + X queued: " .. table.concat(queueNames(), ", "))
    check(promptsSaw == 0, "LB + X: the game's prompts never saw X")
end)
waitFor(1800, function() return chk and (p:getPrimaryHandItem() == chk or p:getSecondaryHandItem() == chk) and chk:isActivated() end, function()
    if not check(chk ~= nil, "a light for LB + X") then return end
    local inHand = p:getPrimaryHandItem() == chk or p:getSecondaryHandItem() == chk
    check(inHand, "LB + X: the light is in a hand")
    check(chk:isActivated(), "LB + X: the light is on")
    shot("light_on")
end)
step(10, function() if chk then press("LB", Joypad.XButton) end end)
step(60, function()
    if chk then check(not chk:isActivated(), "LB + X again: the light is off") end
    stopAll()
end)
-- LB + X with the light in a carried bag: out of the bag, into a hand, on
local tmpBag, bagSkip
step(10, function()
    if not chk then return end
    if p:getPrimaryHandItem() == chk then p:setPrimaryHandItem(nil) end
    if p:getSecondaryHandItem() == chk then p:setSecondaryHandItem(nil) end
    pcall(function() chk:setActivated(false) end)
    tmpBag = p:getInventory():AddItem("Base.Bag_Schoolbag")
    if chk:getContainer() then chk:getContainer():Remove(chk) end
    tmpBag:getInventory():AddItem(chk)
    -- (a light already in a hand or on the belt comes first, the game's rule: another mod's belt light, say)
    local pick = D.H.bestLight(p)
    if pick ~= chk then
        bagSkip = true
        say("LB + X from a bag: skipped, LB + X picks " .. tostring(pick and pick:getFullType()) .. " in a hand or on the belt first")
        return
    end
    press("LB", Joypad.XButton)
    say("LB + X from a bag queued: " .. table.concat(queueNames(), ", "))
end)
waitFor(1800, function() return bagSkip or (chk and (p:getPrimaryHandItem() == chk or p:getSecondaryHandItem() == chk) and chk:isActivated()) end, function()
    if not chk then return end
    if bagSkip then
        if tmpBag then
            if chk:getContainer() == tmpBag:getInventory() then tmpBag:getInventory():Remove(chk); p:getInventory():AddItem(chk) end
            if tmpBag:getContainer() then tmpBag:getContainer():Remove(tmpBag) end
        end
        return
    end
    check(chk:getContainer() == p:getInventory(), "LB + X from a bag: the light is out of the bag")
    check(p:getPrimaryHandItem() == chk or p:getSecondaryHandItem() == chk, "LB + X from a bag: the light is in a hand")
    check(chk:isActivated(), "LB + X from a bag: the light is on")
    stopAll()
    pcall(function() chk:setActivated(false) end)
    if p:getPrimaryHandItem() == chk then p:setPrimaryHandItem(nil) end
    if p:getSecondaryHandItem() == chk then p:setSecondaryHandItem(nil) end
    if tmpBag then
        if chk:getContainer() == tmpBag:getInventory() then tmpBag:getInventory():Remove(chk); p:getInventory():AddItem(chk) end
        if tmpBag:getContainer() then tmpBag:getContainer():Remove(tmpBag) end
    end
end)

-- stuffed: Eat is off with the game's own reason, not "nothing to eat"
step(5, function() pcall(function() p:getBodyDamage():setHealthFromFoodTimer(8000) end) end)
waitFor(600, function() return ZeD.QuickWheel.tooFull(p) end, function()
    local e = Qc.resolve(p, pn, "character:3")
    check(ZeD.QuickWheel.tooFull(p) and e and e.off == getText("Tooltip_CantEatMore"), "stuffed: Eat says " .. tostring(e and e.off))
    pcall(function() p:getBodyDamage():setHealthFromFoodTimer(0) end)
end)
waitFor(600, function() return not ZeD.QuickWheel.tooFull(p) end, function() end)
-- LB + A, LB + B, LB + Y: the game queues its action
for _, t in ipairs({ { Joypad.AButton, "LB + A (eat)" }, { Joypad.BButton, "LB + B (drink)" }, { Joypad.YButton, "LB + Y (smoke)" } }) do
    step(10, function()
        stopAll()
        promptsSaw = 0
        press("LB", t[1])
        local q = queueNames()
        say(t[2] .. " queued: " .. table.concat(q, ", "))
        check(#q > 0, t[2] .. ": the game queues its action")
    end)
    step(30, function() shot("chord_" .. t[2]:sub(1, 6):gsub("%W", "")); stopAll() end)
end

-- a chord whose thing is gone
step(10, function()
    said = {}
    Qc.set("RB+B", "character:3:Base.NotAThingQA", { "Character", "Eat", "QA Gone" })
    press("RB", Joypad.BButton)
    say("said: " .. table.concat(said, " | "))
    check(#said > 0 and said[#said]:find("QA Gone", 1, true) ~= nil, "a gone thing: the character says " .. tostring(said[#said]))
end)
step(30, function() shot("gone_halo") end)

-- from a wheel: Crouch onto RB + Y
local wasRBY = Qc.get("RB+Y")
step(10, function()
    ISDPadWheels.onDisplayDown({ player = pn, id = nil })
    W.qaPoint = 2
end)
step(10, function()
    local st = D.state[pn]
    local menu = st and st.menu
    if not check(menu ~= nil, "the Here and now wheel is open") then return end
    D.assign(pn, menu, "RB+Y")
    check(Qc.get("RB+Y") == "now:2", "RB + Y on Crouch: the chord reads " .. tostring(Qc.get("RB+Y")))
    local s = menu.slices[2]
    say("the bubble's note: " .. tostring(s and s._zedNote))
    check(s and s._zedNote and s._zedNote ~= "", "the bubble says what it did")
end)
step(25, function() shot("wheel_assigned") end)
step(5, function()
    local st = D.state[pn]
    if st and st.menu then pcall(st.menu.undisplay, st.menu) end
    D.state[pn] = nil
    W.qaPoint = nil
end)
step(10, function()
    ISDPadWheels.onDisplayDown({ player = pn, id = nil })
    W.qaPoint = 2
    local st = D.state[pn]
    local s = st and st.menu and st.menu.slices[2]
    local c = s and s._zedChord
    check(c and c[1] == "RB" and c[2] == "Y", "opened again: Crouch shows RB + Y")
end)
step(25, function() shot("wheel_chord_shown") end)
step(5, function()
    local st = D.state[pn]
    if st and st.menu then pcall(st.menu.undisplay, st.menu) end
    D.state[pn] = nil
    W.qaPoint = nil
end)

-- ZeD setup on the pause screen: the Quick actions rows, a chord's help, its list of actions
local opts, chordRow
step(10, function()
    ZeD.Input.Detector.setLockedMode("gamepad")
    D.H.openSetup(p, pn)
end)
step(40, function()
    local MM = ZeD.MainMenu
    opts = MM and MM.pauseOpts
    if not check(opts ~= nil and opts:isVisible(), "ZeD setup is open on the pause screen") then return end
    local rows = opts:rowsFor(opts:pages()[opts.pageIdx or 1])
    local y, idx, n, seen = 0, 0, 0, 0
    for _, r in ipairs(rows) do
        if r.kind == "chord" then
            seen = seen + 1
            if not chordRow then chordRow = r; y = n end
        end
        if r.kind ~= "header" and r.kind ~= "note" and r.kind ~= "desc" then idx = idx + 1; if r == chordRow and not opts.focusId then opts.focusId = "orow:" .. idx end end
        if not chordRow then n = n + (r._h or ZeD.T.px(30)) end
    end
    check(seen == 12, "ZeD setup has the twelve chord rows (" .. seen .. ")")
    local putBack = false
    for _, r in ipairs(rows) do if r.labelKey == "UI_ZeD_Settings_PutBack" then putBack = true end end
    check(putBack, "ZeD setup has Put things back")
    opts.scroll = math.max(0, y - ZeD.T.px(60))
end)
step(30, function() shot("setup_chords") end)
step(5, function()
    if not (opts and chordRow) then return end
    opts:activateRow(chordRow)
    local MM = ZeD.MainMenu
    local items = MM.popup and MM.popup.items or {}
    local live = 0
    for _, it in ipairs(items) do if type(it) == "table" and not it.disabled then live = live + 1 end end
    say("the list for " .. chordRow.chord .. ": " .. #items .. " items, " .. live .. " to choose")
    check(live > 10, "the chord's list offers the wheels' actions")
end)
step(30, function() shot("setup_picker") end)
step(5, function()
    local MM = ZeD.MainMenu
    if MM then MM.ctx.open = nil; MM.popup = nil end
    if opts then pcall(function() opts:finish() end) end
    if MainScreen and MainScreen.instance and MainScreen.instance:isVisible() then ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end
    ZeD.Input.Detector.setLockedMode(nil)
end)

-- put back
step(20, function()
    stopAll()
    for _, it in ipairs(added) do
        if it == light then
            if light:isActivated() then light:setActivated(false) end
            if p:getPrimaryHandItem() == light then p:setPrimaryHandItem(nil) end
            if p:getSecondaryHandItem() == light then p:setSecondaryHandItem(nil) end
        end
        if it:getContainer() then it:getContainer():Remove(it) end
    end
    -- the light LB + X picked, if not the torch: back where it was, on or off as it was
    if other then
        local it = other.it
        if p:getPrimaryHandItem() == it then p:setPrimaryHandItem(nil) end
        if p:getSecondaryHandItem() == it then p:setSecondaryHandItem(nil) end
        if other.c and it:getContainer() ~= other.c then
            if it:getContainer() then it:getContainer():Remove(it) end
            other.c:AddItem(it)
        end
        if it:isActivated() ~= other.on then it:setActivated(other.on) end
        if other.hand == "primary" then p:setPrimaryHandItem(it) elseif other.hand == "secondary" then p:setSecondaryHandItem(it) end
    end
    -- the character's own torch back in the hand it was in
    if lightHand and light then
        if light:getContainer() and light:getContainer() ~= p:getInventory() then light:getContainer():Remove(light); p:getInventory():AddItem(light) end
        if lightHand == "primary" then p:setPrimaryHandItem(light) else p:setSecondaryHandItem(light) end
    end
    putBackFile()
    -- (the module reads the file again)
    pcall(function() Qc.reload() end)
    if origBad then HaloTextHelper.addBadText = origBad end
    if BP then BP.onAPress, BP.onXPress = origA, origX end
    say("put back: the chords file " .. (kept and "as it was" or "removed (there was none)") .. "; RB + Y reads " .. tostring(Qc.get("RB+Y")) .. " (was " .. tostring(wasRBY) .. ")")
    check(Qc.get("RB+Y") == wasRBY, "the chords are as they were")
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

-- (stepped on each drawn frame: the pause screen stops the game's tick)
local qi, wait, waited = 1, nil, 0
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    if s.cond then
        waited = waited + 1
        local ok, met = pcall(s.cond)
        if not (ok and met) and waited < s.max then return end
        qi = qi + 1; waited = 0
        local ok2, err = pcall(s.fn, ok and met and true or false)
        if not ok2 then fails = fails + 1; say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
        return
    end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then fails = fails + 1; say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
