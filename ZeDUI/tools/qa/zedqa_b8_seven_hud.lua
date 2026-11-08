-- ZeDUI/tools/qa/zedqa_b8_seven_hud.lua  (Nov 7 2026, QA; tag b8hud): the seven supported mods loaded TOGETHER (b8_seven_mods.txt:
-- Auto-Hide Hotbar, Item Condition Restored, Mask Filter Indicator, Better Item Transfer, Clear Skill Sheet, Better Folders,
-- Better Mod Experience), ZeD last. This half is the belt (CHECK_mods_hud_20261107.md parts 1 to 3); zedqa_b8_seven_menus.lua is the rest.
--   0. every ModSupport file answered (ZeD.ModSupport.<id> is a table for all seven), step aside STAYED OUT: nothing handed back,
--      no switch ticked, no "ZeD screens" notice in Messages, no set= line in ZeD_step_aside.txt (mods that only ADD to a screen
--      must not trip it: this run is the proof for the seven)
--   1. Item Condition Restored on the belt: the knife and lighter in belt slots, the pot with water in the main hand, a battery
--      radio in the off hand: ZeD.Belt.meter gives the knife's condition, the lighter's uses, the pot's water as "fluid" (the
--      info color), the radio's charge; the mod's None style hands the strip back to ZeD's own condition and its one-color
--      style gives "flat". Picture of the belt.
--   2. Mask Filter Indicator on the belt: a gas mask worn with two spare filters: the box exists, after the last slot and
--      before the Messages note, a slot's size, the strip at the filter left, the badge "+2", the hint "<name> | N% left |
--      spares: 2", the mod's menu opens from the box; the SCBA is a tank box; the mask off, the box goes. Pictures.
--   3. Auto-Hide Hotbar: the belt is attached through the mod's call; the slots fade and come back (getVisibility), the belt sits
--      where it was after the slide, "The inventory is open" keeps it shown while ZeD's windows are open. Pictures hidden and
--      shown. (Hover, a controller and a vehicle are by hand: the pointer is the desktop's.)
--   PUT BACK: the items, the mask, the options, the belt shown, the windows as they were.
-- grep "ZEDQA b8hud"; shots zqa_b8hud_*.png.
local function say(s) print("ZEDQA b8hud " .. tostring(s)) end
local p = getPlayer()
local fails = 0
local function check(ok, what)
    if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8hud_" .. n .. ".png") end) end
local CW, WW, B = ZeD_CharacterWindow, ZeD_WorldWindow, ZeD.Belt
if not (p and CW and B and ZeD.StepAside and ZeD.Messages) then say("ERR ZeD's belt, windows or step aside are not loaded"); say("DONE"); return end

local Q, qi, waitT, tries = {}, 1, nil, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function untilDo(n, max, fn, what) Q[#Q + 1] = { n = n, fn = fn, tries = max, what = what } end

local inv = p:getInventory()
local added = {}
local function give(ft)
    local ok, it = pcall(function() return inv:AddItem(ft) end)
    if ok and it then added[#added + 1] = it; return it end
    say("note: " .. ft .. " could not be added")
    return nil
end
local function hud() return B.getHUD and B.getHUD(0) or nil end
local function keepDown(w)
    if not w then return end
    w._autoShaded = false
    if w.windowShaded and w.setWindowShaded then w:setWindowShaded(false) end
    w._outSince = getTimestampMs() + 600000
end
local function modTable(id) return ZeD.ModSupport and ZeD.ModSupport[id] end
local function active()
    local t, list = {}, getActivatedMods()
    for i = 0, list:size() - 1 do t[(tostring(list:get(i)):gsub("^\\", ""))] = i end
    return t
end
local function near(a, b, e) return type(a) == "number" and type(b) == "number" and math.abs(a - b) <= (e or 0.06) end

local SEVEN = { "AutoHideHotbar", "ItemConditionRestored", "MaskFilterIndicator", "BetterItemTransfer", "Clear_SkillSheet",
    "VIF_DualRender_B42", "BetterModExperience" }
local windowsWere = { CW.isOpen() }
local knife, lighter, pot, radio, mask, scba, spares = nil, nil, nil, nil, nil, nil, {}
local attachedSlots = {}

-- 0. the seven answered; step aside stayed out
step(5, function()
    local act = active()
    local missing = {}
    for _, id in ipairs(SEVEN) do
        if act[id] == nil then missing[#missing + 1] = id end
    end
    check(#missing == 0, "all seven mods are on in this game" .. (#missing > 0 and (" (missing " .. table.concat(missing, ", ") .. ")") or ""))
    local silent = {}
    for _, id in ipairs(SEVEN) do
        if type(modTable(id)) ~= "table" then silent[#silent + 1] = id end
    end
    check(#silent == 0, "each mod's ModSupport file answered" .. (#silent > 0 and (" (silent: " .. table.concat(silent, ", ") .. ")") or ""))
    if getGameSpeed() <= 0 then setGameSpeed(1) end
end)
untilDo(10, 60, function() return ZeD.StepAside.found ~= nil end, "ZeD's step-aside check has run (within ~10 s of the game's start)")
step(10, function()
    local SA, MS = ZeD.StepAside, ZeD.Messages
    local n = 0
    for _ in pairs(SA.found or {}) do n = n + 1 end
    check(n == 0, "step aside found nothing to take over with the seven (a mod that only ADDS to a screen does not trip it)")
    local rec = SA.record()
    local sets = 0
    for _ in pairs(rec.set or {}) do sets = sets + 1 end
    check(sets == 0, "nothing was handed back (set= entries: " .. sets .. ")")
    local ticked = {}
    for name, o in pairs(ZeD.Settings.screenOptions or {}) do
        if o:getValue() == 2 then ticked[#ticked + 1] = name end
    end
    check(#ticked == 0, "no ZeD screen switch is ticked (" .. table.concat(ticked, ",") .. ")")
    local src = MS.sources[ZeD.tr("UI_ZeD_StepAside_Head")]
    check(src == nil or #src.items == 0, "no 'ZeD screens' notice in Messages (" .. tostring(src and #src.items or 0) .. ")")
    local r = getFileReader("ZeD_step_aside.txt", false)
    local sawSet = false
    if r then
        pcall(function()
            local l = r:readLine()
            while l do if l:sub(1, 4) == "set=" then sawSet = true end; l = r:readLine() end
        end)
        pcall(function() r:close() end)
    end
    check(not sawSet, "ZeD_step_aside.txt has no set= line")
    say("(expect no '[ZeD] Step aside: ... took' line in the console; a 'partial' line, if any, is the check being careful)")
end)

-- 1. Item Condition Restored on the belt
step(10, function()
    if CW.isOpen() then CW.toggleBothPaired(0) end
    knife = give("Base.HuntingKnife")
    lighter = give("Base.Lighter")
    pot = give("Base.Pot")
    radio = give("Base.WalkieTalkie2") or give("Base.WalkieTalkie1")
    if knife then pcall(function() knife:setCondition(math.max(1, math.floor(knife:getConditionMax() * 0.6))) end) end
    if lighter then pcall(function() lighter:setUsedDelta(0.4) end) end
    if pot then pcall(function()
        local fc = pot:getFluidContainer()
        fc:addFluid(Fluid.Water, fc:getCapacity() * 0.5)
    end) end
    if radio then pcall(function()
        local dd = radio:getDeviceData()
        dd:setIsBatteryPowered(true)
        dd:setPower(0.7)
    end) end
    -- into belt slots (the first empty one each fits), the pot and radio into the hands
    local hb = B.hotbar(0)
    for _, it in ipairs({ knife, lighter }) do
        if it and hb and hb.availableSlot then
            for i = 1, #hb.availableSlot do
                if hb.attachedItems[i] == nil and B.fits(hb, i, it) and B.attach(0, it, i) then attachedSlots[#attachedSlots + 1] = it; break end
            end
        end
    end
    say("belt slots filled: " .. #attachedSlots .. " of 2 (knife, lighter)")
    if pot then pcall(function() p:setPrimaryHandItem(pot) end) end
    if radio then pcall(function() p:setSecondaryHandItem(radio) end) end
end)
step(40, function()
    local IC = ItemCondition
    check(type(IC) == "table" and type(IC.Config) == "table", "Item Condition Restored's tables are loaded")
    if knife then
        local f, kind = B.meter(knife, "slot")
        check(near(f, 0.6, 0.12), "the knife's strip is its condition (" .. tostring(f) .. ", kind " .. tostring(kind) .. ")")
    end
    if lighter then
        local f, kind = B.meter(lighter, "slot")
        check(near(f, 0.4, 0.08), "the lighter's strip is its uses left (" .. tostring(f) .. ", kind " .. tostring(kind) .. ")")
    end
    if pot then
        local f, kind = B.meter(pot, "hand")
        check(kind == "fluid" and near(f, 0.5, 0.1), "the pot's ring is its water, in the info color (" .. tostring(f) .. ", kind " .. tostring(kind) .. ")")
    end
    if radio then
        local f, kind = B.meter(radio, "hand")
        if f == nil then say("SKIP the radio's charge (no number for it: " .. tostring(radio:getFullType()) .. ")")
        else check(near(f, 0.7, 0.1), "the radio's ring is its charge (" .. tostring(f) .. ", kind " .. tostring(kind) .. ")") end
    end
    -- the mod's styles: None hands the strip back to ZeD's own condition; a one-color style gives "flat"
    local cfg = IC and IC.Config and IC.Config.Hotbar
    if cfg and knife then
        local was = cfg.ProgressBarMode
        cfg.ProgressBarMode = 1
        local f1, k1 = B.meter(knife, "slot")
        check(near(f1, B.cond(knife), 0.001) and k1 == nil, "style None: the knife's strip is ZeD's own condition (" .. tostring(f1) .. ")")
        cfg.ProgressBarMode = 2
        local f2, k2 = B.meter(knife, "slot")
        check(k2 == "flat", "a one-color style: the knife's strip is flat, the theme's positive green (kind " .. tostring(k2) .. ")")
        cfg.ProgressBarMode = 3
        local f3, k3 = B.meter(knife, "slot")
        check(k3 == nil and f3 ~= nil, "the multicolor style: the graduated condition colors (kind " .. tostring(k3) .. ")")
        cfg.ProgressBarMode = was
    end
    shot("belt_meters")
end)

-- 2. Mask Filter Indicator
local MFI
step(10, function()
    MFI = modTable("MaskFilterIndicator")
    mask = give("Base.Hat_GasMask")
    for _ = 1, 2 do spares[#spares + 1] = give("Base.GasmaskFilter") end
    if mask then
        local ok, e = pcall(function()
            p:setWornItem(mask:getBodyLocation(), mask)
            triggerEvent("OnClothingUpdated", p)
        end)
        if not ok then say("note: could not wear the mask: " .. tostring(e)) end
    end
    if MFI then MFI.cache.at = nil end
end)
step(70, function()
    local st = MFI and MFI.state(p)
    check(st ~= nil, "Mask Filter Indicator has a state for the worn gas mask")
    if st then
        check(st.has == true and st.delta > 0, "the filter is fitted with some left (" .. tostring(st.delta) .. ")")
        check(st.spares == 2 and st.badge == "+2", "two spare filters: the badge reads +2 (spares " .. tostring(st.spares) .. ", badge " .. tostring(st.badge) .. ")")
        local hint = MFI.hint(st)
        say("hint: " .. tostring(hint))
        check(hint:find("%d+%%") ~= nil and hint:find("2", 1, true) ~= nil, "the hint names the mask, its filter and the spares")
    end
    local h = hud()
    local boxes = h and h._boxes or {}
    local idx, lastSlot, lamp, slotW, boxW
    for i, b in ipairs(boxes) do
        if b.kind == "slot" then lastSlot = i; slotW = b.w end
        if b.kind == "extra" and b.id == "MaskFilterIndicator" then idx = i; boxW = b.w end
        if b.kind == "lamp" then lamp = i end
    end
    check(idx ~= nil, "the mask's box is on the belt")
    if idx then
        check(lastSlot == nil or idx > lastSlot, "after the last slot")
        check(lamp == nil or idx < lamp, "before the Messages note")
        check(slotW == nil or boxW == slotW, "a slot's size (" .. tostring(boxW) .. " vs " .. tostring(slotW) .. ")")
    end
    check(MFI and MFI.zedOwns() == true, "the mod's own strip is parked while the belt is in charge")
    shot("belt_mask")
end)
step(10, function()
    local st = MFI and MFI.state(p)
    if not st then return end
    local ctx = MFI.menu(0, st, 700, 300, false)
    local m = getPlayerContextMenu(0)
    local names = {}
    for _, o in ipairs(m and m.options or {}) do names[#names + 1] = tostring(o.name) end
    say("the mod's menu from the box: " .. table.concat(names, " | "))
    check(ctx ~= nil and #names >= 1, "the mod's menu opens from the box (" .. #names .. " entries)")
end)
step(25, function() shot("mask_menu") end)
step(10, function()
    local m = getPlayerContextMenu(0)
    if m then pcall(function() m:hideAndChildren() end) end
    -- the SCBA instead of the mask
    if mask then pcall(function() p:removeWornItem(mask); triggerEvent("OnClothingUpdated", p) end) end
    scba = give("Base.SCBA")
    if scba then pcall(function() p:setWornItem(scba:getBodyLocation(), scba); triggerEvent("OnClothingUpdated", p) end) end
    if MFI then MFI.cache.at = nil end
end)
step(70, function()
    local st = MFI and MFI.state(p)
    if scba then
        check(st ~= nil and st.tank == true, "the SCBA is a tank box (tank " .. tostring(st and st.tank) .. ", has " .. tostring(st and st.has) .. ")")
        if st then say("SCBA hint: " .. tostring(MFI.hint(st))) end
        shot("belt_scba")
    else
        say("SKIP the SCBA could not be added")
    end
    if scba then pcall(function() p:removeWornItem(scba); triggerEvent("OnClothingUpdated", p) end) end
    if MFI then MFI.cache.at = nil end
end)
step(70, function()
    local h = hud()
    local found = false
    for _, b in ipairs(h and h._boxes or {}) do
        if b.kind == "extra" and b.id == "MaskFilterIndicator" then found = true end
    end
    check(not found, "mask off: the box goes and the belt closes up")
end)

-- 3. Auto-Hide Hotbar
local A, optHover, optKeep, optWas = nil, nil, nil, {}
local x0, y0
local function setOpt(id, v)
    local o = A and A.options and A.options:getOption(id)
    if not o then return false end
    if optWas[id] == nil then optWas[id] = o:getValue() end
    o:setValue(v)
    return true
end
local function vis() return A and A.getVisibility and A.getVisibility(0) or nil end
step(10, function()
    A = AutoHideHotbar
    check(type(A) == "table" and type(A.attach) == "function", "Auto-Hide Hotbar's API is there")
    local S = modTable("AutoHideHotbar")
    local h = hud()
    check(S and S.attached ~= nil and S.attached == h, "the belt is attached through the mod's call")
    if h then x0, y0 = h:getX(), h:getY() end
    -- the pointer is the desktop's: leave the hover alone while the hide is read
    check(setOpt("revealHover", false), "the hover reveal is switched off for the hide check (put back after)")
    setOpt("keepInventory", false)
    if CW.isOpen() then CW.toggleBothPaired(0) end
    if WW and WW.isOpen and WW.isOpen() then WW.toggleBothPaired(0) end
    pcall(A.reveal, 0, 0.5)
end)
step(15, function()   -- (Nov 8 QA: reveal(0, 0.5) lasts half a second at about 100 ticks a second and fades after; 45 ticks read it mid-fade)
    local v = vis()
    check(v ~= nil and v > 0.9, "revealed: the slots are shown (visibility " .. tostring(v) .. ")")
    shot("ahb_shown")
end)
untilDo(30, 40, function()
    local v = vis()
    return v ~= nil and v < 0.1
end, "the belt hides after the delay (visibility under 0.1)")
step(40, function()
    local h = hud()
    shot("ahb_hidden")
    check(h ~= nil and h:getIsVisible() ~= false, "the belt element itself is still there (only the slots fade)")
    pcall(A.reveal, 0, 1.0)
end)
step(60, function()
    local h = hud()
    local v = vis()
    check(v ~= nil and v > 0.9, "and comes back on reveal (visibility " .. tostring(v) .. ")")
    check(h ~= nil and h:getX() == x0 and h:getY() == y0, "after the slide the belt sits exactly where it was (" .. tostring(h and h:getX()) .. "," .. tostring(h and h:getY()) .. " vs " .. tostring(x0) .. "," .. tostring(y0) .. ")")
end)
-- "The inventory is open": ZeD's windows keep it shown
untilDo(30, 40, function()
    local v = vis()
    return v ~= nil and v < 0.1
end, "hidden again before the windows check")
step(10, function()
    setOpt("keepInventory", true)
    if not CW.isOpen() then CW.toggleBothPaired(0) end
    keepDown(CW.getWindow()); keepDown(WW and WW.getWindow and WW.getWindow())
end)
step(120, function()
    keepDown(CW.getWindow()); keepDown(WW and WW.getWindow and WW.getWindow())
    local v = vis()
    local S = modTable("AutoHideHotbar")
    check(v ~= nil and v > 0.9, "the inventory is open: the belt stays shown past the hide delay (visibility " .. tostring(v) .. ", keep " .. tostring(S and S.keep and S.keep.zed_windows) .. ")")
    shot("ahb_windows_open")
end)
step(10, function()
    if CW.isOpen() then CW.toggleBothPaired(0) end
    if WW and WW.isOpen and WW.isOpen() then WW.toggleBothPaired(0) end
end)
untilDo(30, 50, function()
    local v = vis()
    return v ~= nil and v < 0.1
end, "windows shut: the belt hides again")

-- put back
step(10, function()
    for id, v in pairs(optWas) do
        local o = A and A.options and A.options:getOption(id)
        if o then o:setValue(v) end
    end
    pcall(A.reveal, 0, 2)
    local h = hud()
    for _, it in ipairs(attachedSlots) do pcall(B.detach, 0, it) end
    pcall(function() p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil) end)
    for _, it in ipairs({ mask or false, scba or false }) do
        if it then pcall(function() p:removeWornItem(it) end) end
    end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    for _, it in ipairs(added) do pcall(function() inv:Remove(it) end) end
    if windowsWere[1] and not CW.isOpen() then CW.toggleBothPaired(0) end
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

-- a step's n is in 60ths of a second (wall clock; OnRenderTick runs while paused)
local function tick()
    local s = Q[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    waitT = waitT or (now + s.n * 1000 / 60)
    if now < waitT then return end
    waitT = nil
    local ok, res = pcall(s.fn)
    if not ok then
        fails = fails + 1; say("ERR step " .. qi .. ": " .. tostring(res)); qi = qi + 1; tries = 0
    elseif s.tries and res ~= true then
        tries = tries + 1
        if tries >= s.tries then fails = fails + 1; say("FAIL timed out: " .. tostring(s.what)); qi = qi + 1; tries = 0 end
    else
        if s.what then say("PASS " .. s.what) end
        qi = qi + 1; tries = 0
    end
end
Events.OnRenderTick.Add(tick)
say("start")
