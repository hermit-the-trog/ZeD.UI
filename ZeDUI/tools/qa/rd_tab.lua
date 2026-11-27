-- ZeDUI/tools/qa/rd_tab.lua  (Nov 27 2026, QA; tag rd_tab): the Radio tab in both windows, the device faces, the
-- pop-out, the car radio up close, the dash's head unit and the D-pad wheels' radio slices, the gamut sweep, in the
-- style of the Mechanics and object card sweeps (mt_tab.lua, oca_tab.lua). Its spec is the map
-- ZeDUI/qa/audits/2026-11-27_map_radio.md (section 3's cases R1-R56, section 4's suspicions B1-B14). Run after
-- zedqa_prelude.lua and rt_kit.lua (rd.txt). grep "ZEDQA rd_tab".
-- Each case the map lists is run (or said SKIP with the reason): PASS when ZeD does what the game does or what the map
-- says ZeD should do, FAIL with both sides in the detail. Each suspected bug is a check that proves or clears it.
-- How it drives the tab: a click is the tab's own handler at the control's middle (ZeD.RadioTab.onClick, as the
-- drawer's onMouseDown calls it); a key that acts on the release fires on the next drawn frame, as the tab's render
-- does it (the mouse is up); a right-click is ZeD.RadioTab.onRightClick, the wheel ZeD.RadioTab.onWheel. The pad's
-- presses go through FocusManager's QA hook and its own dispatch on the window (RT.pad + RT.padDown, RT.padDir), the
-- focus put by focusWhere in charTabContent or worldTabContent, the input mode locked to the controller and put back.
-- The truth is the game's: the device's DeviceData (getIsTurnedOn, getChannel, getDeviceVolume, getMicIsMuted,
-- getHasBattery, getPower, getHeadphoneType, hasMedia, isPlayingMedia, the preset list), ISRadioAction's own isValid
-- rules, the game's queue, the items where the game put them, ISRadioWindow's instances, the vehicle's part; never
-- ZeD's reading of it. What ZeD shows is read from what it drew this frame (win._radioTw: the face's controls and its
-- fill rows, the tab strip's zones, the pop-out, the car radio).
-- Where: ZEDQA_HOME first (the drag strip) for the held radios and the car; a room on the grid for the placed sets
-- and the TVs (rt_media's way: the nearest room square within 45 tiles of home with room beside it, else the Fossoil at
-- West Point; the grid turned on for the run through ElecShutModifier and the world's hydro flag, put back).
-- Cases (R<n> = the map's case; B<n> = its suspicion, each a check where it can be staged):
--   R1  empty: both strips without Radio, the wheels' radio slices greyed, B11 the Character window's empty line
--   R2  a walkie equipped by the game's action with both windows open: Radio on the Character strip, no tab change,
--       no game window
--   R3  a walkie in each hand and a ManPack on the back: three tabs in the game's order, (Primary) / (Secondary), the
--       help line, one unequipped: the tab drops and the shown radio is followed (mouse; pad on a tab)
--   R4  a radio in a bag routed by Device Options: the Carried tab, dropped on the floor: gone
--   R5  placed sets round him: the ValuTech 1 tile away listed, the TV 2 tiles away not until he steps closer, sorted
--       by distance; a set across a wall left out (canReachTo)
--   R6  Lite, Device Options on a TV 6 tiles away: the World tab pinned on it (Floor), B3 power from 6 tiles with no
--       walk; 11 tiles away: dropped, the tab back to Loot
--   R7  Device Options on a TV one floor down or up: nothing opens; the game's own window does (compare)
--   R8  faces on: a world click on a TV pops it out, a second puts it away; the game's click within 1.5 tiles: one
--       surface, no game window
--   R9  a radio and a TV in reach: the World tab, its icon and the wheel's slice read Television only with the TV shown
--   R10 three ham sets: the tabs' short names, whole names where they collide, "..." at the half card
--   R11 split screen: SKIP (a second controller)
--   R12 safe mode: the game's onEquip window and Device Options come back, the car radio up close goes; off again:
--       suppressed (run late, before the put-back)
--   R13 power with no battery against what the game's own action does on a twin set (mouse), with one on (pad)
--   R14 volume steps to 1.0 and 0, refused while off; the hand-built set's knob by the wheel and the grabbed D-pad
--   R15 mute and unmute to the kept volume; with none kept: 0.5 (the game: 0.1)
--   R16 TUNE wraps 108.0 to 88.0, the wheel's fast spin 1 MHz a click, refused while off
--   R17 battery in and out (the fullest one, moved from a bag), B5 Spare counting a dead battery
--   R18 presets: a hold stores on p2, a press recalls, an empty key flashes EMPTY, nothing while off
--   R19 headphones: Earbuds in a bag only (the key's words), then in the main inventory: in, then out
--   R20 the Premium's CD: the slot lists the disc in a bag, in, play (the clock runs), stop and play inside 4 s, eject
--   R21 B9 the Premium turned off while the CD plays: does the disc stop (the game's window stops it)
--   R22 the pop-out of a held radio: the header button, a click on the face, dropped: closed; in a bag: stays
--   R23 the CD player: the half card held and dropped, no tuner; B6 the fill's Channels, Heard and range rows
--   R24 a TV on the grid: Power nearby, power on: snow then a picture, sign-off or standby
--   R25 a TV with no power: Requires power nearby, power refused; a generator in range: on
--   R26 the TV's 12 stops by CH+ (mouse), 12 and 13 bars, the wrap; the antique dial stops at its ends (pad)
--   R27 the screen against each channel's getAiringBroadcast at this hour
--   R28 VHS: the slot lists both tapes, in, play (H:MM:SS), eject
--   R29 B2 headphones on a TV (the game never offers them)
--   R30 B4 a TV and a ValuTech on one square: a battery and a tape each through its own tab
--   R31 B1 a walkie's battery: BAT bars, Battery 10%, no battery key on the face or the plain card
--   R32 a walkie's power: VOL clicked (mouse), X on VOL (pad)
--   R33 the Tactical's 10-500 MHz: three places, the wrap, the pad's 5x step after quick repeats
--   R34 MEM and CH: stored once, CH 02 STORED, CH- from 01 to the last
--   R35 MEM held names a channel (right-click by the mouse), an empty name clears it (A held by the pad)
--   R36 MEMORY FULL at getMaxPresets
--   R37 MIC refused while off, then MIC OFF and Microphone No
--   R38 SCAN on the Army walkie: a named station each 5 s, stopped by power off
--   R39 LAMP on the Tactical at night: 5 s
--   R40 the toy walkie: vol, tune and mic only, nnn.nn MHZ
--   R41 B7 the pop-out of a walkie carried in a bag
--   R42 B2 headphones on a walkie: no key, no row (the game offers them)
--   R43 two-way talk and a server's channels: SKIP (multiplayer)
--   R44 a ham set placed on its battery and on the grid: BAT or AC, no battery key
--   R45 the army ham's p1-p6: a hold stores, a press recalls, MEM to MEMORY FULL, the pad's 25x tuning
--   R46 a ham set at the half card: its narrow face, the same controls
--   R47 the car radio up close from the driver's seat: B, Escape, leaving the seat; the back seat gets none
--   R48 the car radio's power with the car battery flat
--   R49 the car's CD (RadioRed in the radio part): list, in, play, eject; the dash's slot
--   R50 the car's ham: MEM, MEM named, CH, MIC
--   R51 B3 the car's radio part pinned in the World tab from outside: the plain card, power from outside
--   R52 B8 the pad's landing on a TV, a ValuTech and a walkie; A grabs a knob, the D-pad turns, B lets go
--   R53 the pad on an empty slot: the list, back on the slot
--   R54 B14 Lite: plain cards, no preset keys, MEM, lamp or pop-out; the Channels rows recall; nothing stores
--   R55 the wheel over the strip, over a knob, elsewhere
--   R56 Large text, Dark and Light: the fill blocks fold, the scrollbar (pictures)
--   B10 the World list's rebuilds a second (NOTE), B12 RadioPlates read by nothing (NOTE), B13 RadioWindow.lua's
--   comment (NOTE)
--   faces: the makeshift walkie, the ManPack and the widescreen TV, which no case shows, drawn and pictured
--   every case: no Lua error over it; put back exactly
-- Pictures rd_<face>_<WxH> (each face the first time it shows: the six walkies and the ManPack, the three hams, the
-- three radios, the CD player, the three TVs, the plain cards rd_plain_<face>_<WxH>, the car radio rd_carradio_<kind>_
-- <WxH>), rd_walkie_tactical_night_lamp, rd_ham_tabs_half, rd_ham_makeshift_narrow and rd_fill_<theme>_<WxH> (R56).
-- Puts back: every item given (the radios, the walkies, the batteries, the discs, the tapes, the headphones, the bags),
-- every set placed and the generator, the car (the prelude's spawn and removal), his own radios, batteries,
-- headphones and media set aside and given back, his hands and back as found, the grid and the shut-off day, the clock,
-- Lite and safe mode as found, the theme and the text size, the Character and World windows' tabs, the width cap and
-- the layout, the input lock, the pointer, the pop-out and the car radio put away, the route's pin and the Carried pin,
-- the draw watchers and the hooks (ISContextMenu.get, the empty line, the tab strip, the World list,
-- RadioPlates), game speed 1, where he stood, god mode as found; the game's volume settings are never touched (checked).

if not (RT and RT.make) then
    print("ZEDQA rd_tab ERR rt_kit.lua did not run first")
    print("ZEDQA rd_tab VERDICT FAIL 1")
    print("ZEDQA rd_tab DONE")
    return
end
local Q = RT.make("rd_tab")
Q.maxMs = 2200000                    -- (the runner gives this script 2400 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, caseMade = {}, objs = {}, shots = {}, errs = 0,
            dead = false, said = {}, shotFace = {}, cars = {}, keep = {}, emptyLines = {}, stripLabels = {}, boxes = {} }
local H = {}
local C = {}
S.RTab = ZeD and ZeD.RadioTab
S.O = ZeD and ZeD.RadioOps
S.R = ZeD and ZeD.Rtv
S.TW = ZeD and ZeD.TwoWay
S.TF = ZeD and ZeD.TwoWayFull
S.WR = ZeD and ZeD.WorldRoutes
S.CR = ZeD and ZeD.CarRadio
S.FP = ZeD and ZeD.FacePop
S.DW = ZeD and ZeD.DpadWheels
S.F = RT.focus()
S.CRATE = "carpentry_01_16"
S.RING = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
S.STORE = { x0 = 12052, y0 = 7117, x1 = 12069, y1 = 7126 }   -- the Fossoil at West Point (rt_media's)
-- every radio type and the things the cases give: his own of these are set aside for the run
S.RADIOS = { "Base.WalkieTalkie1", "Base.WalkieTalkie2", "Base.WalkieTalkie3", "Base.WalkieTalkie4", "Base.WalkieTalkie5",
             "Base.WalkieTalkieMakeShift", "Base.ManPackRadio", "Base.HamRadio1", "Base.HamRadio2", "Base.HamRadioMakeShift",
             "Base.CDplayer", "Base.RadioBlack", "Base.RadioMakeShift", "Base.RadioRed", "Base.TvAntique", "Base.TvBlack", "Base.TvWideScreen" }
S.THINGS = { "Base.Battery", "Base.Headphones", "Base.Earbuds", "Base.Disc_Retail", "Base.VHS_Retail", "Base.VHS_Home" }
-- the sets placed in the world (their tiles, rt_media's and zedqa_rtv's)
S.SPR = { tv_black = "appliances_television_01_5", tv_widescreen = "appliances_television_01_1", tv_antique = "appliances_television_01_9",
          radio_black = "appliances_radio_01_0", radio_red = "appliances_radio_01_9", ham_civilian = "appliances_com_01_0",
          ham_army = "appliances_com_01_8", ham_makeshift = "appliances_com_01_56" }

if not (S.p and S.RTab and S.O and S.R and S.TW and S.TF and ZeD_WorldWindow and ZeD_CharacterWindow) then
    Q.check(false, "the player, ZeD's Radio tab, its faces and both windows are loaded")
    Q.start()
    return
end

-- ===================================================================== small helpers (mt_tab's, named for this script)
function H.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function H.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function H.note(s) Q.say("NOTE " .. tostring(s)) end
-- time, not frames: cond asked every drawn frame until it holds, at most ms; fn(ok)
function H.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 4000000, function()
        if S.dead then return true end
        local now = getTimestampMs()
        st.t = st.t or now
        local ok, r = pcall(cond)
        if ok and r then st.ok = true; return true end
        return now - st.t >= ms
    end, function() if S.dead then return end; fn(st.ok == true) end)
end
function H.speed(n) if ZEDQA_SPEED then pcall(ZEDQA_SPEED, n) else pcall(setGameSpeed, n) end end
function H.list(t, max)
    local o = {}
    for i, v in ipairs(t or {}) do
        if max and i > max then o[#o + 1] = "..."; break end
        o[#o + 1] = tostring(v)
    end
    return (#o > 0) and table.concat(o, ", ") or "none"
end
-- a value said in a check's words: no raw bar (the help line carries one)
function H.s(v) local s = tostring(v); s = string.gsub(s, "|", "/"); return s end
function H.n1(x) if type(x) ~= "number" then return tostring(x) end; return string.format("%.1f", x) end
function H.n2(x) if type(x) ~= "number" then return tostring(x) end; return string.format("%.2f", x) end
function H.mhz(hz) if type(hz) ~= "number" then return tostring(hz) end; return string.format("%.3f", hz / 1000) end
function H.screen() local w, h = 0, 0; pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end); return math.floor(w), math.floor(h) end
function H.sizeTag() local w, h = H.screen(); return w .. "x" .. h end
function H.zopt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
function H.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function H.setOpt(o, v) if o and v ~= nil then pcall(function() o:setValue(v) end) end end
function H.goTo(x, y, z)
    pcall(function()
        S.p:setX(x); S.p:setY(y); S.p:setZ(z)
        S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z)
    end)
end
function H.home() local f = S.found; if f.pos then H.goTo(f.pos.x, f.pos.y, f.pos.z) end; if f.dir then pcall(function() S.p:setDir(f.dir) end) end end
function H.zcall(fn)
    local ok, err = pcall(fn)
    if not ok then S.errs = S.errs + 1; S.zerr = S.zerr or tostring(err) end
    return ok
end
function H.has(s, sub) return type(s) == "string" and type(sub) == "string" and sub ~= "" and string.find(s, sub, 1, true) ~= nil end
function H.lang() local l = "?"; pcall(function() l = tostring(Translator.getLanguage():name()) end); return l end
function H.tr(k, ...) local s = tostring(k); local a = { ... }; pcall(function() s = ZeD.tr(k, a[1], a[2], a[3]) end); return s end

-- ===================================================================== the timed-action queue (the game's)
function H.queue() local q = nil; pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end); return (q and q.queue) or {} end
function H.qlen() return #H.queue() end
function H.qcount(ty) local n = 0; for _, a in ipairs(H.queue()) do if a.Type == ty then n = n + 1 end end; return n end
function H.qkinds() local o = {}; for _, a in ipairs(H.queue()) do o[#o + 1] = tostring(a.Type) end; return H.list(o, 10) end
function H.qstop() pcall(function() ISTimedActionQueue.clear(S.p) end) end
function H.qWalk() for _, a in ipairs(H.queue()) do local t = tostring(a.Type); if H.has(t, "Walk") or H.has(t, "Path") then return true end end; return false end
-- queue: the game's queue run out (speed 2), at most ms; T.qDone, T.qKinds (what it held when it started)
function H.waitQ(T, ms)
    H.step(1, function()
        if T.off then return end
        T.qt0 = getTimestampMs()
        T.qKinds = H.qkinds()
        H.speed(2)
    end)
    H.wait(ms, function() return T.off or (H.qlen() == 0 and getTimestampMs() - (T.qt0 or 0) > 400) end, function(ok)
        H.speed(1)
        if T.off then return end
        T.qDone = ok
        if not ok then H.note(T.L .. ": the game's queue did not run out in " .. ms .. " ms (" .. H.qkinds() .. "): cleared"); H.qstop() end
    end)
end

-- ===================================================================== things (mt_tab's)
function H.isItem(it) local ok = false; if it ~= nil then pcall(function() ok = instanceof(it, "InventoryItem") end) end; return ok end
function H.ft(it) local s = "?"; if H.isItem(it) then pcall(function() s = tostring(it:getFullType()) end) end; return s end
function H.nm(it) local s = "nothing"; if H.isItem(it) then pcall(function() s = tostring(it:getDisplayName()) end) end; return s end
function H.where(it) local c = nil; if H.isItem(it) then pcall(function() c = it:getContainer() end) end; return c end
function H.ctype(c) local t = "none"; if c then pcall(function() t = tostring(c:getType()) end) end; return t end
function H.inv() return S.p:getInventory() end
function H.inMain(it) return H.isItem(it) and H.where(it) == H.inv() end
function H.onHim(it) local m = false; local c = H.where(it); if c then pcall(function() m = c:isInCharacterInventory(S.p) and true or false end) end; return m end
function H.known(ft) local ok = false; if ft then pcall(function() ok = getScriptManager():FindItem(ft) ~= nil end) end; return ok end
function H.walkInv(inv, out, depth)
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        out[#out + 1] = it
        if depth < 4 and instanceof(it, "InventoryContainer") then
            local sub = nil
            pcall(function() sub = it:getInventory() end)
            if sub then H.walkInv(sub, out, depth + 1) end
        end
    end
end
function H.all() local out = {}; pcall(H.walkInv, H.inv(), out, 0); return out end
function H.count(ft) local n = 0; for _, it in ipairs(H.all()) do if H.ft(it) == ft then n = n + 1 end end; return n end
function H.mark(it)
    if not H.isItem(it) then return nil end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    S.made[#S.made + 1] = it
    S.caseMade[#S.caseMade + 1] = it
    return it
end
function H.give(ft) if not ft then return nil end; local it = nil; pcall(function() it = H.inv():AddItem(ft) end); return H.mark(it) end
function H.giveTo(inv, ft) local it = nil; if inv and ft then pcall(function() it = inv:AddItem(ft) end) end; return H.mark(it) end
-- a bag in his main inventory (not worn): what is in it is "in a bag"
function H.bag() local b = H.give("Base.Bag_Schoolbag"); local inv = nil; if b then pcall(function() inv = b:getInventory() end) end; return b, inv end
function H.moveTo(it, inv)
    if not (H.isItem(it) and inv) then return false end
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
    pcall(function() inv:AddItem(it) end)
    return H.where(it) == inv
end
function H.unhold(it)
    if not H.isItem(it) then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    pcall(function() if S.p:getClothingItem_Back() == it then S.p:setClothingItem_Back(nil) end end)
end
function H.removeItem(it)
    if not H.isItem(it) then return end
    H.unhold(it)
    pcall(function()
        local wo = it:getWorldItem()
        if wo then
            local sq = wo:getSquare()
            if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            pcall(function() it:setWorldItem(nil) end)
        end
    end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
function H.gone(it) return H.where(it) == nil end
function H.sweepNew()
    local n = 0
    for _, it in ipairs(H.all()) do
        if not S.found.inv0[it] then H.removeItem(it); n = n + 1 end
    end
    return n
end
-- hold a thing: "p" primary, "s" secondary, "b" on the back
function H.hold(it, slot)
    if not H.isItem(it) then return false end
    pcall(function() if H.where(it) ~= H.inv() then H.moveTo(it, H.inv()) end end)
    if slot == "b" then pcall(function() S.p:setClothingItem_Back(it) end)
    elseif slot == "s" then pcall(function() S.p:setSecondaryHandItem(it) end)
    else pcall(function() S.p:setPrimaryHandItem(it) end) end
    local now = nil
    pcall(function() now = (slot == "b" and S.p:getClothingItem_Back()) or (slot == "s" and S.p:getSecondaryHandItem()) or S.p:getPrimaryHandItem() end)
    return now == it
end
function H.handsEmpty()
    pcall(function() S.p:setPrimaryHandItem(nil) end)
    pcall(function() S.p:setSecondaryHandItem(nil) end)
    pcall(function() local b = S.p:getClothingItem_Back(); if b and instanceof(b, "Radio") then S.p:setClothingItem_Back(nil) end end)
end
-- his own radios, batteries, headphones and recorded media set aside (the keys and lists take only what a case gave)
function H.stashOwn()
    local set = {}
    for _, ft in ipairs(S.RADIOS) do set[ft] = true end
    for _, ft in ipairs(S.THINGS) do set[ft] = true end
    local kept = 0
    for _, it in ipairs(H.all()) do
        local media = false
        pcall(function() media = it:isRecordedMedia() and true or false end)
        local radio = false
        pcall(function() radio = instanceof(it, "Radio") and true or false end)
        if (set[H.ft(it)] or media or radio) and S.found.inv0[it] then
            local c, free = nil, false
            pcall(function()
                c = it:getContainer()
                free = it:getAttachedSlot() == -1 and not it:isEquipped() and not S.p:isEquippedClothing(it)
                    and S.p:getPrimaryHandItem() ~= it and S.p:getSecondaryHandItem() ~= it and S.p:getClothingItem_Back() ~= it
            end)
            if c and free and pcall(function() c:Remove(it) end) then
                S.stash = S.stash or {}
                S.stash[#S.stash + 1] = { it = it, c = c }
            else
                kept = kept + 1
            end
        end
    end
    return #(S.stash or {}), kept
end
function H.unstash()
    local lost = 0
    for _, s in ipairs(S.stash or {}) do
        pcall(function() if s.it:getContainer() == nil then s.c:AddItem(s.it) end end)
        if H.where(s.it) == nil then lost = lost + 1 end
    end
    S.stash = {}
    return lost
end
-- a recorded medium with its media data (a spawned disc may come without it: given one of its category)
function H.mediaReady(it, cat)
    local rec = false
    pcall(function() rec = it:isRecordedMedia() and true or false end)
    if rec then return true end
    pcall(function()
        local rm = getZomboidRadio():getRecordedMedia()
        local md = rm and rm.getRandomFromCategory and rm:getRandomFromCategory(cat)
        if md and it.setRecordedMediaData then it:setRecordedMediaData(md) end
    end)
    pcall(function() rec = it:isRecordedMedia() and true or false end)
    return rec
end
function H.battery(charge, inv)
    local b = inv and H.giveTo(inv, "Base.Battery") or H.give("Base.Battery")
    if b then pcall(function() b:setCurrentUsesFloat(charge) end) end
    return b
end
function H.uses(it) local u = nil; if H.isItem(it) then pcall(function() u = it:getCurrentUsesFloat() end) end; return u end

-- ===================================================================== the device (the game's DeviceData)
function H.dd(dev) local d = nil; if dev then pcall(function() d = dev:getDeviceData() end) end; return d end
function H.on(dev) local v = false; local d = H.dd(dev); if d then pcall(function() v = d:getIsTurnedOn() and true or false end) end; return v end
function H.ch(dev) local v = nil; local d = H.dd(dev); if d then pcall(function() v = d:getChannel() end) end; return v end
function H.vol(dev) local v = nil; local d = H.dd(dev); if d then pcall(function() v = d:getDeviceVolume() end) end; return v end
function H.micMuted(dev) local v = nil; local d = H.dd(dev); if d then pcall(function() v = d:getMicIsMuted() and true or false end) end; return v end
function H.battOn(dev) local v = nil; local d = H.dd(dev); if d then pcall(function() v = d:getHasBattery() and true or false end) end; return v end
function H.charge(dev) local v = nil; local d = H.dd(dev); if d then pcall(function() v = d:getPower() end) end; return v end
function H.usesBatt(dev) local v = false; local d = H.dd(dev); if d then pcall(function() v = d:getIsBatteryPowered() and true or false end) end; return v end
function H.phones(dev) local v = nil; local d = H.dd(dev); if d then pcall(function() v = d:getHeadphoneType() end) end; return v end
function H.media(dev) local v = false; local d = H.dd(dev); if d then pcall(function() v = d:hasMedia() and true or false end) end; return v end
function H.playing(dev) local v = false; local d = H.dd(dev); if d then pcall(function() v = d:isPlayingMedia() and true or false end) end; return v end
function H.isTV(dev) local v = false; local d = H.dd(dev); if d then pcall(function() v = d:getIsTelevision() and true or false end) end; return v end
function H.range(dev) local lo, hi = nil, nil; local d = H.dd(dev); if d then pcall(function() lo, hi = d:getMinChannelRange(), d:getMaxChannelRange() end) end; return lo, hi end
function H.devName(dev) local v = "?"; local d = H.dd(dev); if d then pcall(function() v = tostring(d:getDeviceName()) end) end; return v end
function H.maxPresets(dev) local v = nil; local d = H.dd(dev); if d then pcall(function() v = d:getDevicePresets():getMaxPresets() end) end; return v end
-- the game's preset list: { { name, freq } }
function H.presets(dev)
    local out = {}
    local d = H.dd(dev)
    if not d then return out end
    pcall(function()
        local l = d:getDevicePresets():getPresets()
        for i = 0, l:size() - 1 do local pr = l:get(i); out[#out + 1] = { name = tostring(pr:getName()), freq = pr:getFrequency() } end
    end)
    return out
end
function H.presetText(dev) local o = {}; for i, pr in ipairs(H.presets(dev)) do o[#o + 1] = i .. " " .. H.s(pr.name) .. " " .. H.mhz(pr.freq) end; return H.list(o, 12) end
-- the NoTransmit flag (its getter's name read by probe: a method missing on the class is nil, never a throw)
function H.noTransmit(dev)
    local d = H.dd(dev)
    if not d then return nil end
    local v = nil
    for _, m in ipairs({ "getIsNoTransmit", "isNoTransmit", "getNoTransmit" }) do
        local f = nil
        pcall(function() f = d[m] end)
        if f and v == nil then pcall(function() v = f(d) and true or false end) end
    end
    return v
end
-- staged state on a device: { batt = charge or false, on, vol, ch, mic, presets = { { name, freq } } }
function H.prep(dev, o)
    local d = H.dd(dev)
    if not d then return false end
    pcall(function()
        if d:getIsBatteryPowered() then
            if o.batt then d:setHasBattery(true); d:setPower(o.batt) elseif o.batt == false then d:setPower(0); d:setHasBattery(false) end
        end
    end)
    if o.vol then pcall(function() d:setDeviceVolume(o.vol) end) end
    if o.ch then pcall(function() d:setChannel(o.ch) end) end
    if o.mic ~= nil then pcall(function() d:setMicIsMuted(o.mic) end) end
    if o.presets then
        pcall(function()
            local l = d:getDevicePresets():getPresets()
            l:clear()
            for _, pr in ipairs(o.presets) do l:add(PresetEntry.new(pr[1], pr[2])) end
        end)
    end
    if o.on ~= nil then pcall(function() d:setIsTurnedOn(o.on and true or false) end) end
    return true
end
-- a radio item given into his main inventory, staged
function H.giveRadio(ft, o)
    local it = H.give(ft)
    if it then H.prep(it, o or {}) end
    return it
end
-- the game's own rule for a radio action (ISRadioAction's isValid<mode>), nil when it cannot be asked
function H.gameValid(mode, dev, arg)
    local v = nil
    pcall(function()
        local a = ISRadioAction:new(mode, S.p, dev, arg)
        if a and a.deviceData then v = a:isValid() and true or false end
    end)
    return v
end
-- the game's own portable flag (DeviceData:getIsPortable, what RWMVolume asks before its headphone box)
function H.portable(dev) local v = nil; local d = H.dd(dev); if d then pcall(function() v = d:getIsPortable() and true or false end) end; return v end
-- what the game's own action leaves (its perform<mode>, as its timed action ends) on a twin of the set, staged the
-- same and taken away again: the twin's on state, nil when it could not be run
function H.gameDoes(mode, ft, o, arg)
    local twin = H.giveRadio(ft, o)
    if not twin then return nil end
    local v = nil
    pcall(function()
        local a = ISRadioAction:new(mode, S.p, twin, arg)
        if a and a.deviceData and a["perform" .. mode] then a["perform" .. mode](a); v = H.on(twin) end
    end)
    H.removeItem(twin)
    return v
end
-- ZeD's short-lived state for a device (its key in RadioOps)
function H.key(dev) local k = nil; pcall(function() k = S.O.keyOf(dev) end); return k end
function H.flash(dev) local t = nil; pcall(function() t = S.O.flashOf(S.O.keyOf(dev)) end); return t end
function H.scanning(dev) local k = H.key(dev); return k ~= nil and S.O._scan[k] ~= nil end
function H.stopOf(hz) local s = nil; pcall(function() s = S.R.stopOf(hz) end); return s end
function H.stopNo(hz) local s = H.stopOf(hz); return s and s.number or nil end
function H.stops() local t = {}; pcall(function() t = S.R.stops() end); return t end
function H.stName(hz) local n = nil; pcall(function() n = S.O.chanName(hz) end); return n end

-- ===================================================================== the windows and the tab
function H.win(which) if which == "cw" then return RT.cw() end; return RT.ww() end
function H.which(w) if w ~= nil and w == RT.cw() then return "cw" end; return "ww" end
function H.zoneOf(w) return (H.which(w) == "cw") and "charTabContent" or "worldTabContent" end
function H.wname(which) return (which == "cw") and "Character window" or "World window" end
function H.tw(w) return w and w._radioTw end
function H.hits(w) local t = H.tw(w); return (t and t.hits) or {} end
function H.hit(w, id) for _, h in ipairs(H.hits(w)) do if h.id == id then return h end end; return nil end
function H.hitIds(w) local o = {}; for _, h in ipairs(H.hits(w)) do o[#o + 1] = tostring(h.id) end; return o end
function H.hasHit(w, pat) for _, h in ipairs(H.hits(w)) do if string.find(tostring(h.id), pat) then return true end end; return false end
function H.onTab(w) return w ~= nil and w._activeTab == "radio" and w._drawerOpen ~= false end
function H.shownDev(w) local t = H.tw(w); return t and t.dev or nil end
function H.face(w) local t = H.tw(w); return t and t.pid or nil end
function H.basePid(pid)
    if not pid then return nil end
    local b = nil
    pcall(function() b = S.R.basePid(pid) end)
    return b or pid
end
function H.isPlain(w) local t = H.tw(w); return t ~= nil and t.drv ~= nil and t.drv.plain == true end
function H.fill(w) local t = H.tw(w); return t and t.fill or nil end
-- a fill row by its id (Channels, Heard, Power), as the tab read it
function H.fillRow(w, id)
    local d = H.fill(w)
    if not d then return nil end
    for _, blk in ipairs({ d.presets or {}, d.heard or {}, d.power or {} }) do
        for _, r in ipairs(blk) do if r.id == id then return r end end
    end
    return nil
end
function H.fillIds(w)
    local o = {}
    local d = H.fill(w)
    if not d then return o end
    for _, blk in ipairs({ d.presets or {}, d.heard or {}, d.power or {} }) do for _, r in ipairs(blk) do o[#o + 1] = r.id end end
    return o
end
function H.fillZone(w, id)
    local b = w and w._fill and w._fill.radio
    for _, list in ipairs({ (b and b.zones) or {}, (b and b.last) or {} }) do
        for _, z in ipairs(list) do if z.id == id then return z end end
    end
    return nil
end
function H.tabText(which, dev)
    local w = H.win(which)
    local t = H.tw(w)
    return H.wname(which) .. " tab " .. tostring(w and w._activeTab) .. ", " .. #((w and w._radios) or {}) .. " listed, shown "
        .. H.s(t and H.devName(t.dev)) .. " (the one wanted " .. tostring(t ~= nil and t.dev == dev) .. "), face " .. tostring(t and t.pid)
        .. ", " .. #((t and t.hits) or {}) .. " controls"
end
-- the drawer has stopped growing (its width the same three frames running)
function H.settled(w)
    S.settle = S.settle or {}
    local e = math.floor((w and w._drawerEffW) or -1)
    local s = S.settle[w] or { v = -2, n = 0 }
    S.settle[w] = s
    if e == s.v then s.n = s.n + 1 else s.v, s.n = e, 0 end
    return s.n >= 3 and e > 0
end
function H.tabStrip(which) local w = H.win(which); return (which == "cw") and (w and w._tabStripPanel) or (w and w._actionTabStrip) end
function H.stripHas(which, id) for _, t in ipairs(RT.tabs(H.tabStrip(which))) do if t == id then return true end end; return false end
function H.refreshList(which)
    local w = H.win(which)
    if not w then return end
    if which == "cw" then pcall(function() w._radios = S.RTab.buildEquippedRadios(S.p) end)
    else pcall(function() w._radios = S.RTab.buildWorldRadios(S.p) end) end
end
function H.openRadioTab(which)
    if which == "cw" then pcall(ZeD_CharacterWindow.openTab, S.pn, "radio") else pcall(ZeD_WorldWindow.openTab, S.pn, "radio") end
end
-- queue: the tab open in the window on T[key], its face (or plain card) drawn and the drawer settled
function H.showQ(T, which, key)
    local st = {}
    H.step(2, function()
        if T.off then return end
        RT.pairOpen()
        if not T[key] then T.off = true; Q.skip(T.L, "the device for the case could not be staged"); return end
        H.refreshList(which)
        local w = H.win(which)
        local i = w and S.RTab.indexOf(w._radios, T[key])
        if i then S.RTab.selectRadio(w, i) end
        H.openRadioTab(which)
        st.n = 0
    end)
    H.wait(6000, function()
        if T.off then return true end
        local w, dev = H.win(which), T[key]
        if not w then return false end
        st.n = (st.n or 0) + 1
        if not H.onTab(w) and st.n % 20 == 0 then H.refreshList(which); H.openRadioTab(which) end
        local i = S.RTab.indexOf(w._radios, dev)
        if i and w._radioFollow ~= dev then S.RTab.selectRadio(w, i) end
        local t = H.tw(w)
        return H.onTab(w) and t ~= nil and t.dev == dev and t.hits ~= nil and #t.hits > 0 and H.settled(w)
    end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the " .. H.wname(which) .. "'s Radio tab shows the device", H.tabText(which, T[key])) then T.off = true end
    end)
end

-- ===================================================================== the mouse (the tab's own handlers)
function H.inView(t, x, y) local v = t and t.view; return v ~= nil and x >= v.x and x < v.x + v.w and y >= v.y and y < v.y + v.h end
-- a click on a control: side "l" / "r" a knob's left or right half
function H.click(w, id, side, what)
    local t, h = H.tw(w), H.hit(w, id)
    if not (t and h) then return false end
    local x = (side == "l" and h.x + 2) or (side == "r" and h.x + h.w - 3) or (h.x + math.floor(h.w / 2))
    local y = h.y + math.floor(h.h / 2)
    if not H.inView(t, x, y) then
        if not S.said[id] then
            S.said[id] = true
            H.note(tostring(what) .. ": " .. id .. " is scrolled out of the tab's view: pressed as its own key presses it")
        end
        H.zcall(function() t.drv.press(w._playerObj, t.dev, id, (side == "l") and -1 or ((side == "r") and 1 or nil), nil) end)
        return true
    end
    H.zcall(function() S.RTab.onClick(w, x, y) end)
    return true
end
function H.rclick(w, id)
    local h = H.hit(w, id)
    if not h then return false end
    H.zcall(function() S.RTab.onRightClick(w, h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2)) end)
    return true
end
function H.wheelOn(w, x, y, del) local used = false; H.zcall(function() used = S.RTab.onWheel(w, del, x, y) and true or false end); return used end
function H.wheelHit(w, id, del) local h = H.hit(w, id); if not h then return false end; return H.wheelOn(w, h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2), del) end
function H.clickAt(w, z) if not z then return false end; H.zcall(function() S.RTab.onClick(w, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)) end); return true end
function H.tabZone(w, idx) for _, z in ipairs((w and w._radioTabZones) or {}) do if z.idx == idx then return z end end; return nil end
-- a point on the face away from every control (nil when none is found)
function H.faceBare(w)
    local t = H.tw(w)
    local f = t and t.face
    if not f then return nil end
    for gy = 1, 9 do
        for gx = 1, 9 do
            local x, y = f.x + math.floor(f.w * gx / 10), f.y + math.floor(f.h * gy / 10)
            local hit = false
            for _, h in ipairs(t.hits or {}) do if x >= h.x - 2 and x < h.x + h.w + 2 and y >= h.y - 2 and y < h.y + h.h + 2 then hit = true end end
            if not hit and H.inView(t, x, y) then return x, y end
        end
    end
    return nil
end

-- ===================================================================== the pad (mt_tab's, on either window)
function H.lockFound()
    local key = nil
    pcall(function()
        local o = H.zopt("inputModeLock")
        local keys = ZeD.Settings.inputLockKeys
        if o and keys then key = keys[o:getValue() or 1] end
    end)
    if key == nil then pcall(function() local md = S.p:getModData().ZeD_Gamepad; key = md and md.inputModeLock end) end
    return key or "auto"
end
function H.padOn(w)
    local Det = ZeD.Input and ZeD.Input.Detector
    if not (Det and Det.setLockedMode and S.F and w) then return false end
    if S.lockWas == nil then S.lockWas = H.lockFound() end
    pcall(Det.setLockedMode, "gamepad")
    S.back.pad = true
    if S.F.claimFocus then pcall(S.F.claimFocus, w) end
    return true
end
function H.padOff()
    if not S.back.pad then return end
    S.back.pad = nil
    for _, b in ipairs({ "A", "B", "X", "Y" }) do RT.pad(b, nil) end
    pcall(function() S.F.releaseFocus(S.pn) end)
    local Det = ZeD.Input and ZeD.Input.Detector
    pcall(function()
        Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then Det.setLockedMode(S.lockWas) end
    end)
end
function H.padStops(w)
    local zn = H.zoneOf(w)
    for _, z in ipairs((w and w._focusRing) or {}) do if z.zone == zn then return z.elements or {} end end
    return {}
end
function H.stopIds(w) local o = {}; for _, e in ipairs(H.padStops(w)) do o[#o + 1] = tostring(e.id) end; return H.list(o, 16) end
function H.focusedId(w) local el = nil; pcall(function() el = S.F.getFocusedElement(w) end); return el and el.id or nil end
function H.focusEl(w, id)
    if not (w and S.F and S.F.focusWhere and id) then return false end
    pcall(S.F.claimFocus, w)
    local e = nil
    pcall(function() e = S.F.focusWhere(w, H.zoneOf(w), function(el) return el.id == id end) end)
    return e ~= nil
end
function H.grabbed(w, id) return w ~= nil and id ~= nil and w._knobGrab == id end
-- a tap queued on window which: down through the QA hook and FocusManager's dispatch, up 4 frames later, then the
-- hook lets go (nothing is pressed when gate says no)
function H.tapQ(which, name, gate)
    local st = {}
    local joy = { A = "AButton", B = "BButton", X = "XButton", Y = "YButton" }
    H.step(1, function()
        local w = H.win(which)
        if not w then return end
        if gate and not gate() then return end
        st.on = true
        RT.pad(name, true)
        RT.padDown(Joypad[joy[name]], w)
    end)
    H.step(4, function() if st.on then RT.pad(name, false) end end)
    H.step(4, function() if st.on then RT.pad(name, nil) end end)
end
-- A held past the hold (ms), then let go
function H.holdAQ(which, ms, gate)
    local st = {}
    H.step(1, function()
        local w = H.win(which)
        if not w then return end
        if gate and not gate() then return end
        st.on = true
        RT.pad("A", true)
        RT.padDown(Joypad.AButton, w)
    end)
    Q.waitMs(ms or 800)
    H.step(1, function() if st.on then RT.pad("A", false) end end)
    H.step(4, function() if st.on then RT.pad("A", nil) end end)
end
function H.dirQ(which, dir, gate) H.step(1, function() if gate and not gate() then return end; RT.padDir(dir, H.win(which)) end) end

-- ===================================================================== the lists a key opens, the naming box
function H.menuOpen()
    local c = S.lastCtx
    if not c then return false end
    local up = false
    pcall(function()
        local m = c._zedMenu
        if m and m._ctx then up = m._ctx.open == true else up = c:isReallyVisible() and c:getX() > -1000 end
    end)
    return up
end
function H.menuNames()
    local o = {}
    local c = S.lastCtx
    if not c then return o end
    pcall(function() for i = 1, (c.numOptions or 1) - 1 do local op = c.options[i]; if op then o[#o + 1] = tostring(op.name) end end end)
    return o
end
function H.menuOpt(param)
    local c = S.lastCtx
    local found = nil
    if not c then return nil end
    pcall(function() for i = 1, (c.numOptions or 1) - 1 do local op = c.options[i]; if op and op.param1 == param and not found then found = op end end end)
    return found
end
function H.menuPick(param)
    local op = H.menuOpt(param)
    if not (op and op.onSelect) then return false end
    H.zcall(function() op.onSelect(op.target, op.param1) end)
    return true
end
function H.menuClose()
    local c = S.lastCtx
    S.lastCtx = nil
    if not c then return end
    pcall(function() if c._zedMenu and c._zedMenu.close then c._zedMenu:close() end end)
    pcall(function() c:hideAndChildren() end)
    pcall(function() c:setVisible(false) end)
end
-- the naming box on screen: ZeD's text prompt (Overrides/Prompts.lua makes ISTextBox:new one) or the game's own
-- ISTextBox where ZeD's prompt is not ready. (Run 1: a wrapper on ISTextBox.new never saw the box: Prompts.lua's
-- rewrap, every tick, puts its own new back on top and keeps any other wrapper as its fallback only.)
function H.findBox()
    local b = nil
    pcall(function()
        b = RT.find(function(t)
            return (t.Type == "ZeD_Prompt" and t.kind == "text" and not t._dead) or t.Type == "ISTextBox"
        end)
    end)
    S.lastBox = b
    return b
end
function H.boxUp() return H.findBox() ~= nil end
-- the naming box answered: its words, then its OK (the game's button)
function H.boxOK(text)
    local b = H.findBox()
    if not b then return false end
    local ok = H.zcall(function() b.entry:setText(text); b:onClick(b.yes) end)
    S.lastBox = nil
    return ok
end
function H.boxShut() local b = H.findBox(); S.lastBox = nil; if b then pcall(function() b:destroy() end) end end
-- the game's radio window for this player (an item's or a set's), up or not
function H.gameWin()
    local up = false
    pcall(function()
        for _, list in ipairs({ ISRadioWindow.instances or {}, ISRadioWindow.instancesIso or {} }) do
            local w = list[S.pn]
            if w and w:isVisible() then up = true end
        end
    end)
    return up
end
function H.gameWinShut()
    pcall(function()
        for _, list in ipairs({ ISRadioWindow.instances or {}, ISRadioWindow.instancesIso or {} }) do
            local w = list[S.pn]
            if w and w:isVisible() then w:close() end
        end
    end)
end
function H.popShowing() local d = nil; pcall(function() d = S.TF.showing(S.pn) end); return d end
function H.popShut() pcall(function() S.TF.close(S.pn) end) end
function H.carProp() local p = nil; pcall(function() p = S.CR.get(S.pn) end); return p end
function H.carUp() local p = H.carProp(); local v = false; if p then pcall(function() v = p:isReallyVisible() and true or false end) end; return v end
function H.carShut() pcall(function() S.CR.closeFor(S.pn) end) end

-- ===================================================================== hooks on for the run (put back at the end)
function H.hooksOn()
    if S.hk then return end
    local K = { ctxGet = ISContextMenu.get }
    S.hk = K
    K.ctxFn = function(...) local c = K.ctxGet(...); S.lastCtx = c; return c end
    ISContextMenu.get = K.ctxFn
end
function H.hooksOff()
    local K = S.hk
    if not K then return end
    if ISContextMenu.get == K.ctxFn then ISContextMenu.get = K.ctxGet end
    S.hk = nil
end
function H.hooked() return S.hk == nil end
-- R10: the tab strip's words as drawn in the World window's Radio tab (recorded only while asked)
function H.stripRecOn()
    if S.sr then return end
    local K = { sub = ZeD.SubTabs.draw, tab = ZeD.Molecules.drawTab }
    S.sr = K
    K.subFn = function(panel, x, y, w, items, active, opts, ...)
        local mine = opts ~= nil and opts.win ~= nil and opts.win == RT.ww() and RT.ww()._activeTab == "radio"
        if mine then S.srIn = true; S.srFrame = {} end
        local a, b = K.sub(panel, x, y, w, items, active, opts, ...)
        if mine then S.srIn = false; S.stripLabels = S.srFrame end
        return a, b
    end
    K.tabFn = function(panel, x, y, text, ...)
        if S.srIn and S.srFrame then S.srFrame[#S.srFrame + 1] = tostring(text) end
        return K.tab(panel, x, y, text, ...)
    end
    ZeD.SubTabs.draw = K.subFn
    ZeD.Molecules.drawTab = K.tabFn
end
function H.stripRecOff()
    local K = S.sr
    if not K then return end
    if ZeD.SubTabs.draw == K.subFn then ZeD.SubTabs.draw = K.sub end
    if ZeD.Molecules.drawTab == K.tabFn then ZeD.Molecules.drawTab = K.tab end
    S.sr, S.srIn = nil, false
end
-- B10: the World window's list rebuilds, counted for a time
function H.countOn()
    if S.cnt then return end
    local K = { orig = S.RTab.buildWorldRadios, n = 0 }
    S.cnt = K
    K.fn = function(...) K.n = K.n + 1; return K.orig(...) end
    S.RTab.buildWorldRadios = K.fn
end
function H.countOff() local K = S.cnt; if not K then return 0 end; if S.RTab.buildWorldRadios == K.fn then S.RTab.buildWorldRadios = K.orig end; S.cnt = nil; return K.n end
-- B12: every read of ZeD.RadioPlates counted over the run
function H.plateProxyOn()
    local real = ZeD.RadioPlates
    if type(real) ~= "table" or S.rp then return end
    S.rp = { real = real, n = 0 }
    local K = S.rp
    K.proxy = setmetatable({}, { __index = function(_, k) K.n = K.n + 1; return real[k] end })
    ZeD.RadioPlates = K.proxy
end
function H.plateProxyOff() local K = S.rp; if not K then return nil end; if ZeD.RadioPlates == K.proxy then ZeD.RadioPlates = K.real end; S.rp = nil; return K.n end

-- ===================================================================== the pointer and the pictures
function H.park(on)
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
-- a picture named by nameFn at the step (nil: none), the pointer parked
function H.shotQ(nameFn, what)
    local st = {}
    Q.step(1, function()
        st.name = nil
        if S.dead then return end
        local ok, n = pcall(nameFn)
        if ok and n then st.name = n; H.park(true) end
    end)
    Q.step(4, function()
        if not st.name then return end
        local file = st.name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then S.shots[#S.shots + 1] = file; H.note("picture Zomboid/Screenshots/" .. file .. " / " .. tostring(what))
        else H.note("the picture " .. st.name .. " was not taken: " .. tostring(e)) end
        H.park(false)
    end)
    Q.waitMs(600)
end
-- the face showing, pictured the first time it shows: rd_<face>_<WxH> (the plain card rd_plain_<face>_<WxH>)
function H.faceShotQ(T, which, key)
    H.shotQ(function()
        if T.off then return nil end
        local w = H.win(which)
        local t = H.tw(w)
        if not (t and t.dev == T[key] and t.pid) then return nil end
        local face = H.basePid(t.pid)
        if H.isPlain(w) then face = "plain_" .. face end
        if S.shotFace[face] then return nil end
        S.shotFace[face] = true
        return "rd_" .. face .. "_" .. H.sizeTag()
    end, "a device face in the " .. H.wname(which) .. "'s Radio tab (" .. tostring(T.L) .. ")")
end

-- ===================================================================== the world: a room on the grid, sets placed
function H.sq(x, y, z) local s = nil; pcall(function() s = getCell():getGridSquare(x, y, z) end); return s end
function H.freeSqAt(x, y, z)
    local sq = H.sq(x, y, z)
    local ok = false
    if sq then pcall(function() ok = sq:isFree(false) and sq:getFloor() ~= nil and sq:getVehicleContainer() == nil and not sq:HasTree() end) end
    if ok then
        -- (no set on it already: a set the run did not place is left alone)
        pcall(function()
            local objs = sq:getObjects()
            for i = 0, objs:size() - 1 do if instanceof(objs:get(i), "IsoWaveSignal") then ok = false end end
        end)
    end
    return ok and sq or nil
end
-- a room square with room squares he can reach beside it (rt_media's findSpot, three or more)
function H.roomRing(x, y, z)
    local here = H.freeSqAt(x, y, z)
    local out = {}
    if not here then return out end
    pcall(function() if here:getRoom() == nil then here = nil end end)
    if not here then return out end
    for _, d in ipairs(S.RING) do
        local n = H.freeSqAt(x + d[1], y + d[2], z)
        local reach = false
        if n then pcall(function() reach = n:getRoom() ~= nil and here:canReachTo(n) end) end
        if reach then out[#out + 1] = n end
    end
    return out
end
function H.findSpot(cx, cy, cz, rad)
    for r = 0, rad do
        for dy = -r, r do
            for dx = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local ring = H.roomRing(cx + dx, cy + dy, cz)
                    if #ring >= 3 then return { x = cx + dx + 0.5, y = cy + dy + 0.5, z = cz, ring = ring } end
                end
            end
        end
    end
    return nil
end
function H.atSpot() local sp = S.spot; if sp then H.goTo(sp.x, sp.y, sp.z) end end
function H.used(sq) for _, c in ipairs(S.objs) do if c.sq == sq and not c.removed then return true end end; return false end
function H.keepObj(o, sq, what, kind) local c = { obj = o, sq = sq, what = what, kind = kind }; S.objs[#S.objs + 1] = c; return c end
-- a set placed on sq by its face's tile (pid: a key of S.SPR), its own data as the game makes it; the object or nil
function H.place(pid, sq)
    local spr = S.SPR[pid]
    if not (spr and sq) then return nil end
    local o = nil
    local tv = string.sub(pid, 1, 3) == "tv_"
    pcall(function()
        if tv then o = IsoTelevision.new(getCell(), sq, getSprite(spr)) else o = IsoRadio.new(getCell(), sq, getSprite(spr)) end
        sq:AddTileObject(o)
    end)
    if not o then return nil end
    H.keepObj(o, sq, pid .. " at " .. sq:getX() .. "," .. sq:getY() .. "," .. sq:getZ(), "set")
    return o
end
function H.mkGen(sq)
    if not sq then return nil end
    local g = nil
    pcall(function() g = IsoGenerator.new(instanceItem("Base.Generator"), getCell(), sq) end)
    if not g then return nil end
    pcall(function() g:setFuel(100) end)
    pcall(function() g:setCondition(100) end)
    pcall(function() g:setConnected(true) end)
    pcall(function() g:setActivated(true) end)
    return H.keepObj(g, sq, "a generator at " .. sq:getX() .. "," .. sq:getY(), "gen")
end
function H.rmObj(c)
    if not (c and c.obj) or c.removed then return end
    local o = c.obj
    pcall(function() if c.kind == "gen" then o:setActivated(false); o:setConnected(false) end end)
    -- (a set still on its square is switched off first; one already taken off has no square, and the game's
    -- setIsTurnedOn asks the square for power: run 1 threw 15 times here, sets swept twice)
    local onSq = false
    pcall(function() onSq = o:getSquare() ~= nil and o:getObjectIndex() >= 0 end)
    if c.kind == "set" and onSq then pcall(function() local d = o:getDeviceData(); if d and d:getIsTurnedOn() then d:setIsTurnedOn(false) end end) end
    local sq = c.sq
    pcall(function() sq = o:getSquare() or c.sq end)
    if sq then
        pcall(function() sq:transmitRemoveItemFromSquare(o) end)
        pcall(function() if o:getObjectIndex() >= 0 then sq:RemoveTileObject(o) end end)
        pcall(function() sq:getObjects():remove(o) end)
        pcall(function() sq:getSpecialObjects():remove(o) end)
        pcall(function() sq:RecalcProperties() end)
    end
    pcall(function() if c.kind == "gen" then o:remove() end end)
    pcall(function() o:removeFromWorld() end)
    pcall(function() o:removeFromSquare() end)
    c.removed = true
end
function H.objLeft(c)
    if not (c and c.obj) then return false end
    local left = false
    pcall(function() left = c.sq:getObjects():contains(c.obj) end)
    return left
end
-- the floor round a place snapped, so only what the run dropped there is taken away
function H.snapFloor(set, cx, cy, cz)
    for y = cy - 8, cy + 8 do
        for x = cx - 8, cx + 8 do
            local sq = H.sq(x, y, cz)
            local wos = sq and sq:getWorldObjects()
            for i = 0, (wos and wos:size() or 0) - 1 do set[wos:get(i)] = true end
        end
    end
end
function H.snapAt(x, y, z)
    S.floorAt = S.floorAt or {}
    local c = { x = math.floor(x), y = math.floor(y), z = math.floor(z or 0) }
    S.floorAt[#S.floorAt + 1] = c
    pcall(H.snapFloor, S.found.floor0, c.x, c.y, c.z)
end
function H.sweepFloor()
    local now, n = {}, 0
    for _, c in ipairs(S.floorAt or {}) do pcall(H.snapFloor, now, c.x, c.y, c.z) end
    for wo in pairs(now) do
        if not S.found.floor0[wo] then
            pcall(function() local sq = wo:getSquare(); if sq then sq:transmitRemoveItemFromSquare(wo) end end)
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            n = n + 1
        end
    end
    return n
end
-- the radio sets (IsoWaveSignal) left round a place that the run placed or dropped: none expected after a case
function H.setsNear(cx, cy, cz)
    local n = 0
    for y = cy - 8, cy + 8 do
        for x = cx - 8, cx + 8 do
            local sq = H.sq(x, y, cz)
            local objs = sq and sq:getObjects()
            for i = 0, (objs and objs:size() or 0) - 1 do
                local o = objs:get(i)
                if instanceof(o, "IsoWaveSignal") and not S.found.sets0[o] then n = n + 1 end
            end
        end
    end
    return n
end
function H.snapSets(cx, cy, cz)
    for y = cy - 8, cy + 8 do
        for x = cx - 8, cx + 8 do
            local sq = H.sq(x, y, cz)
            local objs = sq and sq:getObjects()
            for i = 0, (objs and objs:size() or 0) - 1 do local o = objs:get(i); if instanceof(o, "IsoWaveSignal") then S.found.sets0[o] = true end end
        end
    end
end
-- the grid on or off (rt_media's: the shut-off day and the world's hydro flag), put back at the end
function H.setGrid(on)
    if not S.back.grid then
        S.back.grid = true
        pcall(function() S.so = getSandboxOptions(); S.elec = S.so:getOptionByName("ElecShutModifier"); S.found.elec = S.elec:getValue() end)
        pcall(function() S.found.hydro = getWorld():isHydroPowerOn() end)
    end
    pcall(function() if S.elec then S.elec:setValue(on and 99999 or 0); S.so:toLua() end end)
    pcall(function() getWorld():setHydroPowerOn(on and true or false) end)
end
function H.gridBack()
    if not S.back.grid then return end
    S.back.grid = nil
    pcall(function() if S.elec and S.found.elec ~= nil then S.elec:setValue(S.found.elec); S.so:toLua() end end)
    pcall(function() if S.found.hydro ~= nil then getWorld():setHydroPowerOn(S.found.hydro) end end)
end
function H.gridHere() local g = false; pcall(function() g = S.p:getCurrentSquare():hasGridPower() and true or false end); return g end
function H.powered(dev) local v = nil; pcall(function() v = S.O.canBePoweredHere(H.dd(dev)) and true or false end); return v end

-- ===================================================================== Lite, the half card, safe mode, theme and size
function H.lite(on)
    local o = ZeD.Settings and ZeD.Settings.lookStyleOption
    if not o then return false end
    if S.found.style == nil then S.found.style = H.optVal(o) end
    H.setOpt(o, on and 2 or 1)
    S.back.lite = true
    return true
end
function H.liteBack()
    if not S.back.lite then return end
    S.back.lite = nil
    H.setOpt(ZeD.Settings and ZeD.Settings.lookStyleOption, S.found.style)
end
function H.isLite() local v = false; pcall(function() v = ZeD.Settings.lite() and true or false end); return v end
function H.drawerW(w) return math.floor((w and w._drawerEffW) or 0) end
function H.isHalf(w) return w ~= nil and math.abs((w._drawerEffW or 0) - ZeD.T.px(220)) <= 1 end
-- queue: the World window's drawer held in to the half card (mt_tab's way: its width cap made too narrow for the full card)
function H.halfOnQ(T)
    H.step(2, function()
        T.half = nil
        if T.off then return end
        local w = RT.ww()
        if w and not H.isHalf(w) then
            if S.back.maxW == nil then S.back.maxW = { v = w._maxWinW } end
            S.layoutTouched = true
            w._maxWinW = ZeD.T.px(700)
        end
        T.hs = { last = -1, n = 0 }
    end)
    H.wait(5000, function()
        if T.off then return true end
        local e = H.drawerW(RT.ww())
        if e == T.hs.last then T.hs.n = T.hs.n + 1 else T.hs.last, T.hs.n = e, 0 end
        return T.hs.n >= 6 and H.isHalf(RT.ww())
    end, function(ok) if not T.off then T.half = ok end end)
end
function H.halfBack()
    if not S.back.maxW then return end
    local w = RT.ww()
    if w then w._maxWinW = S.back.maxW.v end
    S.back.maxW = nil
end
function H.safe(on)
    local o = ZeD.Settings and ZeD.Settings.safeModeOption
    if not o then return false end
    if S.found.safe == nil then S.found.safe = H.optVal(o) end
    H.setOpt(o, on and 2 or 1)
    S.back.safe = true
    pcall(function() ZeD.Safe.reread() end)
    return true
end
function H.safeBack()
    if not S.back.safe then return end
    S.back.safe = nil
    H.setOpt(ZeD.Settings and ZeD.Settings.safeModeOption, S.found.safe)
    pcall(function() ZeD.Safe.reread() end)
end
function H.safeOn() local v = false; pcall(function() v = ZeD.Safe.on() and true or false end); return v end
function H.theme(key)
    local o = H.zopt("baseTheme")
    local i = nil
    for k, v in ipairs((ZeD.Settings and ZeD.Settings.baseKeys) or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, key, nil, nil)
    S.back.theme = true
end
function H.themeBack()
    if not S.back.theme then return end
    S.back.theme = nil
    local o = H.zopt("baseTheme")
    if o and S.found.baseIdx then pcall(function() o:setValue(S.found.baseIdx) end) end
    pcall(ZeD.applyTheme, S.found.base, nil, nil)
end
function H.sizeSet(key)
    local o = H.zopt("textSize")
    local i = nil
    for k, v in ipairs((ZeD.Settings and ZeD.Settings.sizeKeys) or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, nil, nil, key)
    S.back.size = true
end
function H.sizeBack()
    if not S.back.size then return end
    S.back.size = nil
    local o = H.zopt("textSize")
    if o and S.found.sizeIdx then pcall(function() o:setValue(S.found.sizeIdx) end) end
    pcall(ZeD.applyTheme, nil, nil, S.found.size)
end
-- the game's own volume settings (read only: the run never sets them)
function H.volumes()
    local o = {}
    for _, m in ipairs({ "getOptionSoundVolume", "getOptionMusicVolume", "getOptionAmbientVolume", "getOptionJumpScareVolume", "getOptionVehicleEngineVolume" }) do
        local v = "?"
        pcall(function() local c = getCore(); local f = c[m]; if f then v = tostring(f(c)) end end)
        o[#o + 1] = m:sub(10) .. " " .. v
    end
    return table.concat(o, ", ")
end

-- the sets the run left round a place (a radio dropped on the floor may stand as a set): taken away
function H.sweepSets()
    local n = 0
    for _, c in ipairs(S.floorAt or {}) do
        for y = c.y - 8, c.y + 8 do
            for x = c.x - 8, c.x + 8 do
                local sq = H.sq(x, y, c.z)
                local objs = sq and sq:getObjects()
                local gone = {}
                for i = 0, (objs and objs:size() or 0) - 1 do
                    local o = objs:get(i)
                    if instanceof(o, "IsoWaveSignal") and not S.found.sets0[o] then gone[#gone + 1] = o end
                end
                for _, o in ipairs(gone) do H.rmObj({ obj = o, sq = sq, kind = "set" }); n = n + 1 end
            end
        end
    end
    return n
end

-- ===================================================================== a case's start and end
function H.legClean()
    H.speed(1)
    H.qstop()
    H.padOff()
    H.park(false)
    H.menuClose()
    H.boxShut()
    H.popShut()
    H.carShut()
    H.gameWinShut()
    H.stripRecOff()
    pcall(function() S.WR.unpin(S.p) end)
    pcall(function() if S.RTab._carried then S.RTab._carried[S.pn] = nil end end)
    pcall(function() if S.p:getVehicle() then local car = S.p:getVehicle(); car:exit(S.p); triggerEvent("OnExitVehicle", S.p) end end)
    H.handsEmpty()
    for _, it in ipairs(S.caseMade) do H.removeItem(it) end
    S.caseMade = {}
    for _, it in ipairs(H.all()) do if not S.found.inv0[it] and not S.keep[it] then H.removeItem(it) end end
    -- (the sets the case placed first, through their own records; then any set a dropped radio left standing)
    for i = (S.caseObjs or 0) + 1, #S.objs do H.rmObj(S.objs[i]) end
    S.caseObjs = #S.objs
    H.sweepFloor()
    H.sweepSets()
    H.liteBack()
    H.halfBack()
    for _, w in ipairs({ RT.cw(), RT.ww() }) do
        if w then w._radioFollow = nil; w._knobGrab = nil; w._gpFocusedRadioCtl = nil end
    end
end
-- where: "home" (the drag strip) or "spot" (the room on the grid)
function H.caseStart(T, where)
    S.caseMade = {}
    S.lastCtx, S.lastBox = nil, nil
    H.legClean()
    T.where = where
    if where == "spot" then
        if not S.spot then T.off = true; Q.skip(T.L, S.noSpot or "no room on the grid was found for the placed sets"); return false end
        H.setGrid(true)
        H.atSpot()
    else
        H.goTo(S.homeAt.x, S.homeAt.y, S.homeAt.z)
    end
    RT.pairOpen()
    T.t0case = getTimestampMs()
    return true
end
function H.caseEnd(label)
    H.step(2, function() H.legClean() end)
    H.step(10, function()
        local e1 = H.errN()
        Q.check(S.e0 == nil or e1 == nil or e1 == S.e0, label .. ": no Lua error over the case",
            (S.e0 and e1) and ((e1 - S.e0) .. " new") or "the count cannot be read")
        if S.zerr then Q.check(false, label .. ": nothing ZeD ran for the case threw", S.zerr); S.zerr = nil end
        S.e0 = e1
    end)
end

-- ===================================================================== setup
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.dead = S.p:isDead() and true or false
        if S.dead then Q.check(false, "setup: the character is alive (nothing is run on a dead one)"); return end
        if not (S.F and S.F.focusWhere and ISTimedActionQueue and ISRadioAction and ISRadioWindow and ISDeviceBatteryAction
                and ISDeviceMediaAction and ISEquipWeaponAction and PresetEntry) then
            S.dead = true
            Q.check(false, "setup: the pad's focus manager and the game's radio code are loaded")
            return
        end
        S.err0 = H.errN()
        S.e0 = S.err0
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.dir = S.p:getDir() end)
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "rd_tab") end
        S.homeAt = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        H.speed(1)
        H.qstop()
        f.pair = RT.isOpen()
        f.hands = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
        pcall(function() f.back = S.p:getClothingItem_Back() end)
        f.inv0, f.types, f.floor0, f.sets0 = {}, {}, {}, {}
        for _, it in ipairs(H.all()) do
            f.inv0[it] = true
            local ft = H.ft(it)
            f.types[ft] = (f.types[ft] or 0) + 1
        end
        H.snapAt(S.homeAt.x, S.homeAt.y, S.homeAt.z)
        pcall(H.snapSets, math.floor(S.homeAt.x), math.floor(S.homeAt.y), math.floor(S.homeAt.z))
        pcall(function() f.tod = getGameTime():getTimeOfDay() end)
        pcall(function() f.god = S.p:isGodMod() and true or false; S.p:setGodMod(true) end)
        f.base, f.size = ZeD.currentBase, ZeD.currentSize
        f.baseIdx, f.sizeIdx = H.optVal(H.zopt("baseTheme")), H.optVal(H.zopt("textSize"))
        f.style = H.optVal(ZeD.Settings and ZeD.Settings.lookStyleOption)
        f.safe = H.optVal(ZeD.Settings and ZeD.Settings.safeModeOption)
        S.lockWas = H.lockFound()
        f.vols = H.volumes()
        RT.pairOpen()
        if ZEDQA_LAYOUT_SNAP then pcall(function() f.layout = ZEDQA_LAYOUT_SNAP() end) end
        local cw, ww = RT.cw(), RT.ww()
        f.ctab, f.wtab = cw and cw._activeTab, ww and ww._activeTab
        f.maxW = ww and ww._maxWinW
        f.recorded = true
        S.back.on = true
        H.hooksOn()
        H.plateProxyOn()
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", screen " .. H.sizeTag() .. ", language " .. H.lang()
            .. ", input lock " .. tostring(S.lockWas) .. ", Lite " .. tostring(H.isLite()) .. ", safe mode " .. tostring(H.safeOn())
            .. ", theme " .. tostring(f.base) .. ", text " .. tostring(f.size) .. ", tabs " .. tostring(f.ctab) .. " / " .. tostring(f.wtab)
            .. ", the game's volumes " .. f.vols)
        if H.isLite() then H.lite(false); H.note("setup: Lite was on: Full for the run (put back)") end
        if H.safeOn() then H.safe(false); H.note("setup: safe mode was on: off for the run (put back)") end
        H.handsEmpty()
        local aside, kept = H.stashOwn()
        H.note("setup: " .. aside .. " of his own radios, batteries, headphones and recorded media set aside" .. (kept > 0 and (", " .. kept .. " worn or held stay") or ""))
        local miss = {}
        for _, ft in ipairs(S.RADIOS) do if not H.known(ft) then miss[#miss + 1] = ft end end
        for _, ft in ipairs(S.THINGS) do if not H.known(ft) then miss[#miss + 1] = ft end end
        Q.check(#miss == 0, "setup: every radio and thing the cases use is known to this game", "unknown: " .. H.list(miss))
        -- a room for the placed sets near home (rt_media's search); none: the Fossoil at West Point, when the placed cases start
        S.spot = H.findSpot(math.floor(S.homeAt.x), math.floor(S.homeAt.y), math.floor(S.homeAt.z), 45)
        H.note("setup: " .. (S.spot and ("a room square on the grid's side at " .. math.floor(S.spot.x) .. "," .. math.floor(S.spot.y) .. " with " .. #S.spot.ring .. " room squares beside it")
            or "no room within 45 tiles of home: the placed cases go to the Fossoil at West Point"))
        if S.spot then H.snapAt(S.spot.x, S.spot.y, S.spot.z); pcall(H.snapSets, math.floor(S.spot.x), math.floor(S.spot.y), S.spot.z) end
        H.legClean()
    end)
    Q.waitMs(600)
end
-- queue: to the room for the placed sets (the Fossoil when none was near home: its cells loaded, then searched)
function S.toSpotQ()
    H.step(2, function()
        if S.spot then H.setGrid(true); H.atSpot(); return end
        S.farT0 = getTimestampMs()
        S.far = true
        H.setGrid(true)
        H.goTo(math.floor((S.STORE.x0 + S.STORE.x1) / 2) + 0.5, math.floor((S.STORE.y0 + S.STORE.y1) / 2) + 0.5, 0)
    end)
    H.wait(20000, function()
        if S.spot then return true end
        return H.sq(S.STORE.x0, S.STORE.y0, 0) ~= nil and H.sq(S.STORE.x1, S.STORE.y1, 0) ~= nil and getTimestampMs() - (S.farT0 or 0) > 9000
    end, function()
        if not S.spot and S.far then
            S.spot = H.findSpot(math.floor((S.STORE.x0 + S.STORE.x1) / 2), math.floor((S.STORE.y0 + S.STORE.y1) / 2), 0, 12)
            if S.spot then H.snapAt(S.spot.x, S.spot.y, S.spot.z); pcall(H.snapSets, math.floor(S.spot.x), math.floor(S.spot.y), S.spot.z) end
        end
        if not Q.check(S.spot ~= nil, "the placed cases: a room square with room squares beside it", S.spot and (math.floor(S.spot.x) .. "," .. math.floor(S.spot.y)) or "none found") then
            S.noSpot = "no room square with three room squares beside it was found"
        else
            H.atSpot()
        end
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if not S.spot then return end
        H.note("the room: grid power on his square " .. tostring(H.gridHere()) .. " (the world's hydro flag " .. tostring(getWorld():isHydroPowerOn()) .. ")")
    end)
end
-- queue: back home (the drag strip), the cells loaded again after a far move
function S.toHomeQ()
    H.step(2, function() H.legClean(); H.goTo(S.homeAt.x, S.homeAt.y, S.homeAt.z); S.homeT0 = getTimestampMs() end)
    H.wait(12000, function() return not S.far or (H.sq(math.floor(S.homeAt.x), math.floor(S.homeAt.y), 0) ~= nil and getTimestampMs() - S.homeT0 > 9000) end, function() end)
end

-- ===================================================================== R1 empty states (B11)
-- the words the tab draws with no radio (the same render in both windows): its empty line, read off its draw
function H.emptyLine()
    local got = nil
    local orig = ZeD.Molecules.drawEmptyLine
    ZeD.Molecules.drawEmptyLine = function(panel, x, y, w, text) got = tostring(text) end
    local stub = { _radios = {}, _playerObj = S.p }
    pcall(function() S.RTab.render({}, stub, 0, 0, 300, 200) end)
    ZeD.Molecules.drawEmptyLine = orig
    return got or "?"
end
function H.slice(list, pred) for _, e in ipairs(list or {}) do if pred(e) then return e end end; return nil end
function C.r1()
    local T = { L = "R1 empty states" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        H.refreshList("cw")
        H.refreshList("ww")
    end)
    Q.waitMs(1200)
    H.step(2, function()
        if T.off then return end
        local eq, wd = {}, {}
        pcall(function() eq = S.RTab.buildEquippedRadios(S.p) end)
        pcall(function() wd = S.RTab.buildWorldRadios(S.p) end)
        if #eq > 0 or #wd > 0 then T.off = true; Q.skip(T.L, "radios on him or in reach here (" .. #eq .. " on him, " .. #wd .. " in reach)"); return end
        Q.check(not H.stripHas("cw", "radio") and not H.stripHas("ww", "radio"), T.L .. ": with no radio on him or in reach neither window's strip offers Radio",
            "the game's lists: 0 on him, 0 in reach; Character strip " .. H.list(RT.tabs(H.tabStrip("cw"))) .. "; World strip " .. H.list(RT.tabs(H.tabStrip("ww"))))
        local cT, wT, use = {}, {}, {}
        pcall(function() cT = S.DW.C.tabs(S.p, S.pn) end)
        pcall(function() wT = S.DW.Wd.tabs(S.p, S.pn) end)
        pcall(function() use = S.DW.C.use(S.p, S.pn) end)
        local cr = H.slice(cT, function(e) return e.key == "radio" end)
        local wr = H.slice(wT, function(e) return e.key == "radio" end)
        local ur = H.slice(use, function(e) return e.icon == "walkie" end)
        Q.check(cr ~= nil and cr.off == H.tr("UI_ZeD_Wheel_NoRadioOnYou"), T.L .. ": the Character wheel's Radio tab slice is greyed with its reason",
            "slice " .. H.s(cr and cr.name) .. ", off: " .. H.s(cr and cr.off))
        Q.check(wr ~= nil and wr.off == H.tr("UI_ZeD_Wheel_NoRadioInReach"), T.L .. ": the World wheel's Radio slice is greyed with its reason",
            "slice " .. H.s(wr and wr.name) .. ", off: " .. H.s(wr and wr.off))
        Q.check(ur ~= nil and ur.off ~= nil, T.L .. ": the Use wheel's Radio slice is greyed", "slice " .. H.s(ur and ur.name) .. ", off: " .. H.s(ur and ur.off))
        H.note(T.L .. ": the wheels' words are \"" .. H.s(cr and cr.off) .. "\" and \"" .. H.s(wr and wr.off) .. "\" (the map wrote \"No radio on you\" and \"No radio in reach\")")
        local text = H.emptyLine()
        if H.lang() == "EN" then
            Q.check(not H.has(string.lower(text), "in range"), T.L .. " (B11): the Character window's empty line speaks of radios on him, not in range",
                "the tab draws \"" .. text .. "\" in both windows; the Character window lists only radios in his hands, on his back or carried")
        else
            H.note(T.L .. " (B11): the empty line in " .. H.lang() .. " is \"" .. text .. "\" (the check runs in EN)")
        end
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R2 equip a walkie
function C.r2()
    local T = { L = "R2 a walkie equipped with both windows open" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        local cw, ww = RT.cw(), RT.ww()
        T.ctab, T.wtab = cw and cw._activeTab, ww and ww._activeTab
        T.dev = H.giveRadio("Base.WalkieTalkie2", { batt = 0.8, on = false })
        if not T.dev then T.off = true; Q.skip(T.L, "no walkie could be given"); return end
        T.had = H.stripHas("cw", "radio")
        pcall(function() ISTimedActionQueue.add(ISEquipWeaponAction:new(S.p, T.dev, 20, true, false)) end)
    end)
    H.wait(8000, function() return T.off or S.p:getPrimaryHandItem() == T.dev end, function(ok)
        if T.off then return end
        T.tEq = getTimestampMs()
        Q.check(ok, T.L .. ": the game's equip action puts the walkie in his hand", "primary " .. H.nm(S.p:getPrimaryHandItem()))
        local cw = RT.cw()
        T.listNow = cw ~= nil and S.RTab.indexOf(cw._radios, T.dev) ~= nil
    end)
    H.wait(1500, function() return T.off or H.stripHas("cw", "radio") end, function(ok)
        if T.off then return end
        local ms = getTimestampMs() - (T.tEq or 0)
        Q.check(ok and T.listNow, T.L .. ": the Character window's list has the walkie at once and its strip offers Radio",
            "listed in the frame the equip ended " .. tostring(T.listNow) .. ", Radio on the strip " .. tostring(ok) .. " after " .. ms .. " ms (before the equip " .. tostring(T.had) .. ")")
        local cw, ww = RT.cw(), RT.ww()
        Q.check((cw and cw._activeTab) == T.ctab and (ww and ww._activeTab) == T.wtab, T.L .. ": the equip opens no tab",
            "Character " .. tostring(T.ctab) .. " -> " .. tostring(cw and cw._activeTab) .. ", World " .. tostring(T.wtab) .. " -> " .. tostring(ww and ww._activeTab))
        Q.check(not H.gameWin(), T.L .. ": the game's radio window does not open (its onEquip auto-open is off)", "ISRadioWindow up " .. tostring(H.gameWin()))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R3 primary, secondary and back
function C.r3()
    local T = { L = "R3 primary, secondary and back" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.a = H.giveRadio("Base.WalkieTalkie2", { batt = 0.8 })
        T.b = H.giveRadio("Base.WalkieTalkie2", { batt = 0.8 })
        T.c = H.giveRadio("Base.ManPackRadio", { batt = 0.8 })
        H.hold(T.a, "p")
        H.hold(T.b, "s")
        local worn = nil
        pcall(function() worn = S.p:getClothingItem_Back() end)
        if worn == nil then T.backOk = H.hold(T.c, "b") end
        if not T.backOk then H.note(T.L .. ": the ManPack was not put on his back (" .. (worn and ("he wears " .. H.nm(worn) .. " there") or "setClothingItem_Back did not take") .. "): two radios only") end
    end)
    H.showQ(T, "cw", "a")
    H.faceShotQ(T, "cw", "a")
    H.step(2, function()
        if T.off then return end
        local cw = RT.cw()
        local list = cw._radios or {}
        local want = { T.a, T.b }
        if T.backOk then want[3] = T.c end
        local order, ok = {}, #list == #want
        for i, e in ipairs(list) do order[#order + 1] = H.s(e.locationTag); if e.radioInstance ~= want[i] then ok = false end end
        Q.check(ok, T.L .. ": one tab each, in the game's order: primary, secondary, back", "listed " .. H.list(order) .. " (" .. #list .. " of " .. #want .. ")")
        local items = S.RTab.tabItems(list)
        local la, lb = items[1] and items[1].label, items[2] and items[2].label
        local name = H.devName(T.a)
        name = name:match("^[^%.]+%.(.+)$") or name
        local locP, locS = S.RTab.locationName("Primary"), S.RTab.locationName("Secondary")
        Q.check(la == name .. " (" .. locP .. ")" and lb == name .. " (" .. locS .. ")", T.L .. ": two of one name carry their slot",
            "labels \"" .. H.s(la) .. "\" and \"" .. H.s(lb) .. "\"; the game's name " .. H.s(name))
        if T.backOk then
            local lc = items[3] and items[3].label
            Q.check(lc ~= nil and not H.has(lc, "("), T.L .. ": a radio with a name of its own carries no slot", "\"" .. H.s(lc) .. "\" (the game's name " .. H.s(H.devName(T.c)) .. ")")
        end
        local help = items[1] and items[1].help
        Q.check(H.has(help, name) and H.has(help, locP), T.L .. ": the help line on a tab names the radio and where it is", H.s(help))
        T.pick = T.backOk and 3 or 2
        T.pickDev = list[T.pick] and list[T.pick].radioInstance
        H.clickAt(cw, H.tabZone(cw, T.pick))
    end)
    H.step(3, function()
        if T.off then return end
        local sh = S.RTab.showingEntry(RT.cw())
        Q.check(sh ~= nil and sh.radioInstance == T.pickDev, T.L .. " (mouse): a click on a radio's tab shows that radio",
            "showing " .. H.s(sh and H.devName(sh.radioInstance)) .. " (" .. H.s(sh and sh.locationTag) .. ")")
        T.t0 = getTimestampMs()
        -- (the radio before the shown one is put down, so the shown one moves up a place in the list: run 1 put down
        -- the very radio it showed, with no ManPack on his back, and read that as the tab not following)
        T.victim, T.vSlot = T.b, "s"
        if not T.backOk then T.victim, T.vSlot = T.a, "p" end
        T.n0 = #(RT.cw()._radios or {})
        T.idx0 = RT.cw()._radioIdx
        H.unhold(T.victim)
    end)
    H.wait(1500, function() local cw = RT.cw(); return T.off or (cw ~= nil and #(cw._radios or {}) == (T.n0 or 0) - 1) end, function(ok)
        if T.off then return end
        local cw = RT.cw()
        local ms = getTimestampMs() - (T.t0 or 0)
        local sh = S.RTab.showingEntry(cw)
        Q.check(ok and ms <= 1100, T.L .. ": an unequipped walkie's tab goes within the list's 500 ms read", ms .. " ms, " .. #(cw._radios or {}) .. " tabs left")
        Q.check(sh ~= nil and sh.radioInstance == T.pickDev, T.L .. ": the tab stays on the radio it showed while the list moves up under it",
            "showing " .. H.s(sh and H.devName(sh.radioInstance)) .. " (" .. H.s(sh and sh.locationTag) .. "), its place " .. tostring(T.idx0) .. " -> " .. tostring(cw._radioIdx))
        H.hold(T.victim, T.vSlot)
    end)
    H.wait(1500, function() local cw = RT.cw(); return T.off or (cw ~= nil and #(cw._radios or {}) == (T.n0 or 0)) end, function() end)
    H.step(2, function()
        if T.off then return end
        local cw = RT.cw()
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tab:1")
        Q.check(T.go, T.L .. " (pad): the focus goes onto the first radio's tab", "stops " .. H.stopIds(cw))
    end)
    H.tapQ("cw", "A", function() return T.go and not T.off end)
    H.step(3, function()
        H.padOff()
        if T.off or not T.go then return end
        local sh = S.RTab.showingEntry(RT.cw())
        Q.check(sh ~= nil and sh.radioInstance == T.a, T.L .. " (pad): A on a tab shows that radio", "showing " .. H.s(sh and H.devName(sh.radioInstance)) .. " (" .. H.s(sh and sh.locationTag) .. ")")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R4 carried (a radio in a bag)
function C.r4()
    local T = { L = "R4 a radio carried in a bag" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        local _, inv = H.bag()
        T.dev = H.giveRadio("Base.RadioBlack", { batt = 0.6 })
        if not (inv and T.dev and H.moveTo(T.dev, inv)) then T.off = true; Q.skip(T.L, "no radio in a bag could be staged"); return end
        H.refreshList("cw")
        H.zcall(function() ISRadioWindow.activate(S.p, T.dev) end)
    end)
    H.wait(4000, function()
        local cw = RT.cw()
        return T.off or (H.onTab(cw) and H.shownDev(cw) == T.dev)
    end, function(ok)
        if T.off then return end
        local cw = RT.cw()
        local e = cw and cw._radios and cw._radios[S.RTab.indexOf(cw._radios, T.dev) or 0]
        local items = S.RTab.tabItems(cw._radios or {})
        local i = S.RTab.indexOf(cw._radios, T.dev) or 0
        Q.check(ok and e ~= nil and e.locationTag == "Carried", T.L .. ": Device Options on a radio in a bag opens the Character window's Radio tab on it, Carried",
            H.tabText("cw", T.dev) .. "; its place " .. H.s(e and e.locationTag) .. ", its help " .. H.s(items[i] and items[i].help) .. "; the item in " .. H.ctype(H.where(T.dev)))
        Q.check(not H.gameWin(), T.L .. ": no game window", "ISRadioWindow up " .. tostring(H.gameWin()))
        -- dropped on the floor beside him
        pcall(function() local c = T.dev:getContainer(); if c then c:Remove(T.dev) end end)
        pcall(function() S.p:getCurrentSquare():AddWorldInventoryItem(T.dev, 0.5, 0.5, 0) end)
        T.t0 = getTimestampMs()
    end)
    H.wait(2500, function() local cw = RT.cw(); return T.off or (cw ~= nil and S.RTab.indexOf(cw._radios, T.dev) == nil) end, function(ok)
        if T.off then return end
        local wo = nil
        pcall(function() wo = T.dev:getWorldItem() end)
        local pin = S.RTab._carried and S.RTab._carried[S.pn]
        Q.check(ok and pin == nil, T.L .. ": put on the floor, the Carried tab goes and its pin with it",
            "on the floor " .. tostring(wo ~= nil) .. ", listed " .. tostring(not ok) .. ", pin " .. tostring(pin ~= nil) .. " after " .. (getTimestampMs() - (T.t0 or 0)) .. " ms")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R13 power with and without a battery
function C.r13()
    local T = { L = "R13 power with and without a battery" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.RadioBlack", { batt = false, on = false, vol = 0.5 })
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    H.faceShotQ(T, "cw", "dev")
    H.step(2, function()
        if T.off then return end
        T.game = H.gameValid("ToggleOnOff", T.dev)
        -- (run 1: the game's isValidToggleOnOff says true with no battery (canBePoweredHere answers true for a battery
        -- set in his hands); the truth is what the game's own action leaves: its perform run on a twin set)
        T.twin = H.gameDoes("ToggleOnOff", "Base.RadioBlack", { batt = false, on = false, vol = 0.5 })
        T.battIn = H.battOn(T.dev)
        H.click(RT.cw(), "power", nil, T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.on(T.dev) == T.twin, T.L .. " (mouse): power with no battery does what the game's own action does",
            "ZeD: on " .. tostring(H.on(T.dev)) .. " (a battery in " .. tostring(T.battIn) .. "); the game's performToggleOnOff on a twin leaves it on " .. tostring(T.twin)
            .. "; its isValidToggleOnOff " .. tostring(T.game))
        H.prep(T.dev, { batt = 0.6 })
        local cw = RT.cw()
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tw:power")
        Q.check(T.go, T.L .. " (pad): the focus goes onto power", "stops " .. H.stopIds(cw))
    end)
    H.tapQ("cw", "A", function() return T.go and not T.off end)
    H.step(3, function()
        H.padOff()
        if T.off or not T.go then return end
        local st = nil
        pcall(function() st = S.R.read(T.dev) end)
        Q.check(H.on(T.dev) and st ~= nil and st.on == true, T.L .. " (pad): with a battery in, power turns it on and the face reads it on",
            "on " .. tostring(H.on(T.dev)) .. ", charge " .. H.n2(H.charge(T.dev)) .. "; the face reads on " .. tostring(st and st.on) .. "; the game's rule " .. tostring(H.gameValid("ToggleOnOff", T.dev)))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R14 volume
function C.r14()
    local T = { L = "R14 volume" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.RadioBlack", { batt = 0.8, on = true, vol = 0.5 })
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    H.step(2, function()
        if T.off then return end
        local cw = RT.cw()
        T.v0 = H.vol(T.dev)
        for _ = 1, 10 do H.click(cw, "volup", nil, T.L) end
        T.up = H.vol(T.dev)
        for _ = 1, 12 do H.click(cw, "voldn", nil, T.L) end
        T.dn = H.vol(T.dev)
        Q.check(math.abs((T.up or -1) - 1) < 0.001 and math.abs(T.dn or -1) < 0.001, T.L .. " (mouse): VOL+ ten times from 0.5 stops at 1.0, VOL- stops at 0",
            "the game's volume " .. H.n2(T.v0) .. " -> " .. H.n2(T.up) .. " -> " .. H.n2(T.dn))
        H.prep(T.dev, { on = false, vol = 0.5 })
        T.game = H.gameValid("SetVolume", T.dev, 0.6)
        H.click(cw, "volup", nil, T.L)
    end)
    H.step(2, function()
        if T.off then return end
        Q.check(math.abs((H.vol(T.dev) or -1) - 0.5) < 0.001 and T.game == false, T.L .. ": VOL+ while off does nothing, as the game refuses it",
            "volume " .. H.n2(H.vol(T.dev)) .. "; the game's isValidSetVolume " .. tostring(T.game))
        H.unhold(T.dev)
        T.hb = H.giveRadio("Base.RadioMakeShift", { batt = 0.8, on = true, vol = 0.5 })
        H.hold(T.hb, "p")
    end)
    H.showQ(T, "cw", "hb")
    H.faceShotQ(T, "cw", "hb")
    H.step(2, function()
        if T.off then return end
        local cw = RT.cw()
        local h = H.hit(cw, "vol")
        if not (h and h.knob) then T.off = true; Q.skip(T.L .. ": the hand-built set's volume knob", "its face has no vol knob (" .. H.list(H.hitIds(cw)) .. ")"); return end
        T.k0 = H.vol(T.hb)
        H.wheelHit(cw, "vol", -1)
        T.k1 = H.vol(T.hb)
        Q.check(math.abs((T.k1 or 0) - (T.k0 or 0) - 0.1) < 0.001, T.L .. " (mouse): the wheel on the hand-built set's knob turns the volume up a step",
            "volume " .. H.n2(T.k0) .. " -> " .. H.n2(T.k1))
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tw:vol")
        Q.check(T.go, T.L .. " (pad): the focus goes onto the volume knob", "stops " .. H.stopIds(cw))
    end)
    H.tapQ("cw", "A", function() return T.go and not T.off end)
    H.step(2, function()
        if T.off or not T.go then return end
        T.grab = H.grabbed(RT.cw(), "radio:tw:vol")
        T.k2 = H.vol(T.hb)
    end)
    H.dirQ("cw", "right", function() return T.go and not T.off end)
    H.step(2, function() if not T.off then T.k3 = H.vol(T.hb) end end)
    H.tapQ("cw", "B", function() return T.go and not T.off end)
    H.step(3, function()
        if T.off or not T.go then H.padOff(); return end
        local cw = RT.cw()
        Q.check(T.grab and math.abs((T.k3 or 0) - (T.k2 or 0) - 0.1) < 0.001 and not H.grabbed(cw, "radio:tw:vol") and H.focusedId(cw) == "radio:tw:vol",
            T.L .. " (pad): A grabs the knob, the D-pad turns it a step, B lets go and the focus stays",
            "grabbed " .. tostring(T.grab) .. ", volume " .. H.n2(T.k2) .. " -> " .. H.n2(T.k3) .. ", held after B " .. tostring(cw and cw._knobGrab) .. ", focus " .. tostring(H.focusedId(cw)))
        H.padOff()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R15 mute and unmute
function C.r15()
    local T = { L = "R15 mute and unmute" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.RadioBlack", { batt = 0.8, on = true, vol = 0.7 })
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    H.step(2, function()
        if T.off then return end
        H.click(RT.cw(), "mute", nil, T.L)
        T.v1 = H.vol(T.dev)
        local st = nil
        pcall(function() st = S.R.read(T.dev) end)
        T.muted = st and st.muted
        H.click(RT.cw(), "mute", nil, T.L)
        T.v2 = H.vol(T.dev)
        Q.check(math.abs(T.v1 or -1) < 0.001 and T.muted == true and math.abs((T.v2 or 0) - 0.7) < 0.001, T.L .. " (mouse): MUTE silences the set and MUTE again brings back 0.7",
            "the game's volume 0.70 -> " .. H.n2(T.v1) .. " (the face reads muted " .. tostring(T.muted) .. ") -> " .. H.n2(T.v2))
        pcall(function() S.O._lastVol[S.O.keyOf(T.dev)] = nil end)
        pcall(function() H.dd(T.dev):setDeviceVolume(0) end)
        local cw = RT.cw()
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tw:mute")
    end)
    H.tapQ("cw", "A", function() return T.go and not T.off end)
    H.step(3, function()
        H.padOff()
        if T.off or not T.go then return end
        Q.check(math.abs((H.vol(T.dev) or 0) - 0.5) < 0.001, T.L .. " (pad): MUTE on a silent set with no volume kept unmutes to 0.5",
            "the game's volume " .. H.n2(H.vol(T.dev)) .. " (the game's own window unmutes to 0.1 when none is kept: RWMVolume)")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R16 tune
function C.r16()
    local T = { L = "R16 tune" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.RadioBlack", { batt = 0.8, on = true, vol = 0.3, ch = 107800 })
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    H.step(2, function()
        if T.off then return end
        local cw = RT.cw()
        H.click(cw, "tune", "r", T.L)
        T.c1 = H.ch(T.dev)
        H.click(cw, "tune", "r", T.L)
        T.c2 = H.ch(T.dev)
        local lo, hi = H.range(T.dev)
        Q.check(T.c1 == 108000 and T.c2 == lo, T.L .. " (mouse): TUNE's right half from 107.8 reads 108.0, then wraps to the band's foot",
            "the game's channel 107.800 -> " .. H.mhz(T.c1) .. " -> " .. H.mhz(T.c2) .. " (the band " .. H.mhz(lo) .. "-" .. H.mhz(hi) .. ")")
        local h = H.hit(cw, "tune")
        if h and h.knob then
            pcall(function() H.dd(T.dev):setChannel(90000) end)
            cw._radioWheel = nil
            for _ = 1, 8 do H.wheelHit(cw, "tune", -1) end
            T.c8 = H.ch(T.dev)
            H.wheelHit(cw, "tune", -1)
            T.c9 = H.ch(T.dev)
            Q.check((T.c9 or 0) - (T.c8 or 0) == 1000, T.L .. " (mouse): a fast wheel spin moves 1 MHz a click once 8 quick clicks have turned",
                "the game's channel 90.000 -> " .. H.mhz(T.c8) .. " after 8 clicks, then " .. H.mhz(T.c9) .. " (" .. tostring((T.c9 or 0) - (T.c8 or 0)) .. " kHz)")
        else
            H.note(T.L .. ": TUNE on " .. tostring(H.face(cw)) .. " is no knob: the wheel's spin is not run")
        end
        H.prep(T.dev, { on = false, ch = 95000 })
        T.game = H.gameValid("SetChannel", T.dev, 95200)
        H.click(cw, "tune", "r", T.L)
    end)
    H.step(2, function()
        if T.off then return end
        Q.check(H.ch(T.dev) == 95000 and T.game == false, T.L .. ": TUNE while off does nothing, as the game refuses it",
            "channel " .. H.mhz(H.ch(T.dev)) .. "; the game's isValidSetChannel " .. tostring(T.game))
        H.prep(T.dev, { on = true, ch = 95000 })
        local cw = RT.cw()
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tw:tune")
    end)
    H.tapQ("cw", "A", function() return T.go and not T.off end)
    H.dirQ("cw", "right", function() return T.go and not T.off end)
    H.step(2, function()
        if T.off or not T.go then H.padOff(); return end
        Q.check(H.ch(T.dev) == 95200, T.L .. " (pad): A grabs TUNE and the D-pad tunes a step", "channel 95.000 -> " .. H.mhz(H.ch(T.dev)) .. ", grabbed " .. tostring(RT.cw()._knobGrab))
    end)
    H.tapQ("cw", "B", function() return T.go and not T.off end)
    H.step(2, function() H.padOff() end)
    H.caseEnd(T.L)
end

-- ===================================================================== R17 battery in and out (B5)
function H.battsOn() local n, live = 0, 0; for _, it in ipairs(H.all()) do if H.ft(it) == "Base.Battery" then n = n + 1; if (H.uses(it) or 0) > 0 then live = live + 1 end end end; return n, live end
function C.r17()
    local T = { L = "R17 battery in and out" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.RadioBlack", { batt = false, on = false })
        local _, inv = H.bag()
        T.dead = H.battery(0, inv)
        T.good = H.battery(0.6, inv)
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    Q.waitMs(700)
    H.step(2, function()
        if T.off then return end
        local cw = RT.cw()
        local sp = H.fillRow(cw, "fill:radio:spare")
        local n = H.battsOn()
        Q.check(sp ~= nil and sp.value == "x" .. n, T.L .. ": the Power block counts the spare batteries he carries", "row " .. H.s(sp and sp.label) .. " " .. H.s(sp and sp.value) .. "; the game's count of Base.Battery on him " .. n)
        T.goodUses = H.uses(T.good)
        H.click(cw, "battery", nil, T.L)
    end)
    H.step(3, function() if not T.off then T.k = H.qkinds() end end)
    H.waitQ(T, 15000)
    Q.waitMs(700)
    H.step(2, function()
        if T.off then return end
        local row = H.fillRow(RT.cw(), "fill:radio:batt")
        Q.check(H.battOn(T.dev) == true and math.abs((H.charge(T.dev) or 0) - (T.goodUses or 0)) < 0.02 and not H.onHim(T.good),
            T.L .. " (mouse): the battery key puts in the fullest battery he carries, from his bag",
            "queued " .. tostring(T.k) .. "; the set's battery in " .. tostring(H.battOn(T.dev)) .. " at " .. H.n2(H.charge(T.dev)) .. " (the 60% one " .. H.n2(T.goodUses) .. ", still on him " .. tostring(H.onHim(T.good)) .. ")")
        Q.check(row ~= nil and row.value == math.floor((H.charge(T.dev) or 0) * 100 + 0.5) .. "%", T.L .. ": the Power block reads the battery's charge",
            "row " .. H.s(row and row.label) .. " " .. H.s(row and row.value) .. "; the game's charge " .. H.n2(H.charge(T.dev)))
        local cw = RT.cw()
        T.n0 = H.battsOn()
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tw:battery")
    end)
    H.tapQ("cw", "A", function() return T.go and not T.off end)
    H.step(2, function() H.padOff() end)
    H.waitQ(T, 15000)
    H.step(2, function()
        if T.off or not T.go then return end
        local n = H.battsOn()
        Q.check(H.battOn(T.dev) == false and n == (T.n0 or 0) + 1, T.L .. " (pad): A on the battery key takes the battery out into his inventory",
            "the set's battery in " .. tostring(H.battOn(T.dev)) .. "; batteries on him " .. tostring(T.n0) .. " -> " .. n)
        -- B5: only the dead battery left
        for _, it in ipairs(H.all()) do if H.ft(it) == "Base.Battery" and (H.uses(it) or 0) > 0 then H.removeItem(it) end end
    end)
    Q.waitMs(700)
    H.step(2, function()
        if T.off then return end
        T.sp = H.fillRow(RT.cw(), "fill:radio:spare")
        S.lastCtx = nil
        H.click(RT.cw(), "battery", nil, T.L)
    end)
    H.step(3, function()
        if T.off then return end
        local n, live = H.battsOn()
        local none = H.tr("UI_ZeD_Radio_NoBatteries")
        local said = H.list(H.menuNames())
        local keyNone = H.has(said, none)
        local spSays = T.sp and T.sp.value
        Q.check(not (keyNone and spSays ~= nil and H.has(spSays, "x")), T.L .. " (B5): the Spare row and the battery key agree when the only battery is dead",
            "the Power block reads " .. H.s(T.sp and T.sp.label) .. " " .. H.s(spSays) .. "; the key answers \"" .. H.s(said) .. "\"; the game: " .. n .. " battery on him, " .. live .. " with charge (Spare counts getCountTypeRecurse, the key takes only one with uses left)")
        H.menuClose()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R18 presets
function C.r18()
    local T = { L = "R18 presets" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.RadioBlack", { batt = 0.8, on = true, vol = 0.3, ch = 101200, presets = { { "Stage", 89400 } } })
        H.hold(T.dev, "p")
        T.want = H.stName(101200) or "101.2 MHz"
    end)
    H.showQ(T, "cw", "dev")
    H.step(2, function()
        if T.off then return end
        local cw = RT.cw()
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tw:p2")
        Q.check(T.go, T.L .. " (pad): the focus goes onto preset 2", "stops " .. H.stopIds(cw))
    end)
    H.holdAQ("cw", 800, function() return T.go and not T.off end)
    H.step(2, function()
        H.padOff()
        if T.off or not T.go then return end
        local pr = H.presets(T.dev)
        T.fl = H.flash(T.dev)
        local st = nil
        pcall(function() st = S.R.read(T.dev) end)
        Q.check(#pr == 2 and pr[2].freq == 101200 and pr[2].name == T.want, T.L .. " (pad): A held on P2 stores the station on preset 2 with its name",
            "the game's presets " .. H.presetText(T.dev) .. " (want 2 " .. H.s(T.want) .. " 101.200)")
        Q.check(T.fl == H.tr("UI_ZeD_Radio_Store", 2) and st ~= nil and st.presetIdx == 2, T.L .. ": the glass flashes STORE 2 and reads P2",
            "flash " .. H.s(T.fl) .. ", the face's preset " .. tostring(st and st.presetIdx))
    end)
    Q.waitMs(700)
    H.step(2, function()
        if T.off then return end
        local row = H.fillRow(RT.cw(), "fill:radio:ch:2")
        Q.check(row ~= nil and H.has(row.label, T.want) and row.sel == true, T.L .. ": a Channels row for it, the tuned one marked",
            "row " .. H.s(row and row.label) .. " " .. H.s(row and row.value) .. " marked " .. tostring(row and row.sel))
        pcall(function() H.dd(T.dev):setChannel(89400) end)
        H.click(RT.cw(), "p2", nil, T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.ch(T.dev) == 101200, T.L .. " (mouse): P2 pressed at 89.4 recalls 101.2", "the game's channel " .. H.mhz(H.ch(T.dev)))
        H.click(RT.cw(), "p4", nil, T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.flash(T.dev) == H.tr("UI_ZeD_Radio_Empty") and H.ch(T.dev) == 101200, T.L .. " (mouse): an empty P4 flashes EMPTY and leaves the channel",
            "flash " .. H.s(H.flash(T.dev)) .. ", channel " .. H.mhz(H.ch(T.dev)) .. ", presets " .. #H.presets(T.dev))
        H.prep(T.dev, { on = false, ch = 89400 })
        H.click(RT.cw(), "p2", nil, T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.ch(T.dev) == 89400, T.L .. ": a preset pressed while off does nothing", "the game's channel " .. H.mhz(H.ch(T.dev)))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R19 headphones
function C.r19()
    local T = { L = "R19 headphones" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.RadioBlack", { batt = 0.8, on = true, vol = 0.3 })
        local _, inv = H.bag()
        T.ear = H.giveTo(inv, "Base.Earbuds")
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    H.step(2, function()
        if T.off then return end
        S.lastCtx = nil
        H.click(RT.cw(), "phones", nil, T.L)
    end)
    H.step(3, function()
        if T.off then return end
        local said = H.list(H.menuNames())
        Q.check(H.has(said, H.tr("UI_ZeD_Radio_NoHeadphones")) and H.qlen() == 0, T.L .. " (mouse): with Earbuds only in a bag the key says none are on him",
            "the key answers \"" .. H.s(said) .. "\"; queued " .. H.qkinds() .. "; the earbuds in " .. H.ctype(H.where(T.ear)) .. " (the key reads his main inventory only)")
        H.menuClose()
        H.moveTo(T.ear, H.inv())
        local cw = RT.cw()
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tw:phones")
    end)
    H.tapQ("cw", "A", function() return T.go and not T.off end)
    H.step(2, function() H.padOff(); if not T.off then T.k = H.qkinds() end end)
    H.waitQ(T, 15000)
    Q.waitMs(700)
    H.step(2, function()
        if T.off or not T.go then return end
        local row = H.fillRow(RT.cw(), "fill:radio:phones")
        Q.check((H.phones(T.dev) or -1) >= 0 and H.count("Base.Earbuds") == 0 and row ~= nil and row.value == H.tr("UI_ZeD_Plain_PhonesIn"),
            T.L .. " (pad): with the Earbuds in his main inventory A plugs them in and the block reads In",
            "queued " .. tostring(T.k) .. "; the game's headphone type " .. tostring(H.phones(T.dev)) .. ", earbuds on him " .. H.count("Base.Earbuds") .. "; row " .. H.s(row and row.value))
        H.click(RT.cw(), "phones", nil, T.L)
    end)
    H.step(3, function() if not T.off then T.k2 = H.qkinds() end end)
    H.waitQ(T, 15000)
    H.step(2, function()
        if T.off then return end
        Q.check((H.phones(T.dev) or 0) < 0 and H.count("Base.Earbuds") == 1, T.L .. " (mouse): the jack pressed again takes them out",
            "queued " .. tostring(T.k2) .. "; headphone type " .. tostring(H.phones(T.dev)) .. ", earbuds on him " .. H.count("Base.Earbuds"))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R20 the Premium's CD
function C.r20()
    local T = { L = "R20 the Premium's CD" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.RadioRed", { batt = 0.9, on = true, vol = 0.2 })
        local _, inv = H.bag()
        T.disc = H.giveTo(inv, "Base.Disc_Retail")
        T.rec = T.disc and H.mediaReady(T.disc, "CDs")
        H.hold(T.dev, "p")
        if not T.rec then T.off = true; Q.skip(T.L, "the disc given has no recorded media") end
    end)
    H.showQ(T, "cw", "dev")
    H.faceShotQ(T, "cw", "dev")
    H.step(2, function() if not T.off then S.lastCtx = nil; H.click(RT.cw(), "slot", nil, T.L) end end)
    H.step(3, function()
        if T.off then return end
        local names = H.menuNames()
        Q.check(H.menuOpen() and H.menuOpt(T.disc) ~= nil, T.L .. " (mouse): the empty slot lists the disc carried in his bag", "the list: " .. H.s(H.list(names)) .. "; the disc " .. H.s(H.nm(T.disc)))
        if not H.menuPick(T.disc) then T.off = true end
        H.menuClose()
    end)
    H.step(2, function() if not T.off then T.k = H.qkinds() end end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off then return end
        Q.check(H.media(T.dev) and not H.onHim(T.disc), T.L .. ": the pick moves the disc and puts it in", "queued " .. tostring(T.k) .. "; the game's hasMedia " .. tostring(H.media(T.dev)) .. ", the disc on him " .. tostring(H.onHim(T.disc)))
        H.click(RT.cw(), "play", nil, T.L)
    end)
    Q.waitMs(2500)
    H.step(2, function()
        if T.off then return end
        local st = nil
        pcall(function() st = S.R.read(T.dev) end)
        Q.check(H.playing(T.dev) and st ~= nil and (st.clockMs or 0) > 1000, T.L .. ": play runs the disc and the face's clock runs",
            "the game's isPlayingMedia " .. tostring(H.playing(T.dev)) .. "; the face's clock " .. tostring(st and st.clockMs) .. " ms, its title " .. H.s(st and st.mediaTitle))
        H.click(RT.cw(), "play", nil, T.L)
        pcall(function() st = S.R.read(T.dev) end)
        T.readStop = st and st.playing
    end)
    H.step(3, function() if not T.off then T.t0 = getTimestampMs(); H.click(RT.cw(), "play", nil, T.L) end end)
    H.wait(7000, function() return T.off or (getTimestampMs() - (T.t0 or 0) > 300 and H.playing(T.dev)) end, function(ok)
        if T.off then return end
        Q.check(T.readStop == false and ok, T.L .. ": stop reads stopped at once and a play inside 4 s resumes as soon as the game lets it",
            "the face read playing " .. tostring(T.readStop) .. " right after stop; playing again " .. tostring(ok) .. " after " .. (getTimestampMs() - (T.t0 or 0)) .. " ms")
        local cw = RT.cw()
        T.n0 = H.count("Base.Disc_Retail")
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tw:eject")
    end)
    H.tapQ("cw", "A", function() return T.go and not T.off end)
    H.step(2, function() H.padOff() end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off or not T.go then return end
        Q.check(not H.media(T.dev) and H.count("Base.Disc_Retail") == (T.n0 or 0) + 1, T.L .. " (pad): A on eject takes the disc out into his inventory",
            "the game's hasMedia " .. tostring(H.media(T.dev)) .. "; discs on him " .. tostring(T.n0) .. " -> " .. H.count("Base.Disc_Retail"))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R21 off while a CD plays (B9)
function C.r21()
    local T = { L = "R21 the Premium turned off while the CD plays" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.RadioRed", { batt = 0.9, on = true, vol = 0.2 })
        T.disc = H.give("Base.Disc_Retail")
        if not (T.disc and H.mediaReady(T.disc, "CDs")) then T.off = true; Q.skip(T.L, "the disc given has no recorded media"); return end
        H.hold(T.dev, "p")
        pcall(function() ISTimedActionQueue.add(ISDeviceMediaAction:new(S.p, false, T.disc, T.dev:getID())) end)
    end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off then return end
        if not H.media(T.dev) then T.off = true; Q.skip(T.L, "the game's media action did not put the disc in"); return end
        pcall(function() H.dd(T.dev):StartPlayMedia() end)
    end)
    H.showQ(T, "cw", "dev")
    Q.waitMs(1200)
    H.step(2, function()
        if T.off then return end
        T.p0 = H.playing(T.dev)
        if not T.p0 then T.off = true; Q.skip(T.L, "the disc did not start playing"); return end
        H.click(RT.cw(), "power", nil, T.L)
    end)
    Q.waitMs(2500)
    H.step(2, function()
        if T.off then return end
        T.offPlay = H.playing(T.dev)
        Q.check(not H.on(T.dev) and not T.offPlay, T.L .. " (B9): turned off by its power key, the disc stops (the game's window stops it, RWMMedia)",
            "on " .. tostring(H.on(T.dev)) .. ", the game's isPlayingMedia " .. tostring(T.offPlay) .. " 2.5 s after power off (playing before " .. tostring(T.p0) .. ")")
        local cw = RT.cw()
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tw:power")
    end)
    H.tapQ("cw", "A", function() return T.go and not T.off end)
    Q.waitMs(1500)
    H.step(2, function()
        H.padOff()
        if T.off then return end
        H.note(T.L .. " (pad): turned on again without Play: on " .. tostring(H.on(T.dev)) .. ", the game's isPlayingMedia " .. tostring(H.playing(T.dev))
            .. " (off it read " .. tostring(T.offPlay) .. ")")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R22 the pop-out of a held radio
function C.r22()
    local T = { L = "R22 the pop-out of a held radio" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.RadioBlack", { batt = 0.8, on = true, vol = 0.3 })
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    H.step(2, function()
        if T.off then return end
        local cw = RT.cw()
        if not cw._radioFullZone then T.off = true; Q.skip(T.L, "no pop-out button on this face"); return end
        H.clickAt(cw, cw._radioFullZone)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.popShowing() == T.dev, T.L .. " (mouse): the header's button pops the face out", "showing " .. H.s(H.devName(H.popShowing())))
        RT.bounds(Q, T.L .. ", the pop-out")
        H.clickAt(RT.cw(), RT.cw()._radioFullZone)
    end)
    H.step(3, function()
        if T.off then return end
        T.shut1 = H.popShowing() == nil
        local x, y = H.faceBare(RT.cw())
        T.bare = x ~= nil
        if x then H.zcall(function() S.RTab.onClick(RT.cw(), x, y) end) end
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(T.shut1 and T.bare and H.popShowing() == T.dev, T.L .. " (mouse): the button again puts it away; a click on the face away from its controls pops it out",
            "put away " .. tostring(T.shut1) .. ", a bare place on the face found " .. tostring(T.bare) .. ", showing " .. H.s(H.devName(H.popShowing())))
        H.unhold(T.dev)
        pcall(function() local c = T.dev:getContainer(); if c then c:Remove(T.dev) end end)
        pcall(function() S.p:getCurrentSquare():AddWorldInventoryItem(T.dev, 0.5, 0.5, 0) end)
        T.t0 = getTimestampMs()
    end)
    H.wait(2500, function() return T.off or H.popShowing() == nil end, function(ok)
        if T.off then return end
        Q.check(ok, T.L .. ": the radio put on the floor, the pop-out closes", "after " .. (getTimestampMs() - (T.t0 or 0)) .. " ms showing " .. H.s(H.devName(H.popShowing())))
        local _, inv = H.bag()
        T.b2 = H.giveRadio("Base.RadioBlack", { batt = 0.8, on = true, vol = 0.3 })
        if not (inv and T.b2 and H.moveTo(T.b2, inv)) then T.off = true; return end
        H.zcall(function() ISRadioWindow.activate(S.p, T.b2) end)
    end)
    H.wait(4000, function() local cw = RT.cw(); return T.off or (H.onTab(cw) and H.shownDev(cw) == T.b2 and cw._radioFullZone ~= nil) end, function(ok)
        if T.off then return end
        if not ok then Q.check(false, T.L .. ": the radio in a bag shows on the Carried tab", H.tabText("cw", T.b2)); T.off = true; return end
        H.clickAt(RT.cw(), RT.cw()._radioFullZone)
    end)
    Q.waitMs(2000)
    H.step(2, function()
        if T.off then return end
        Q.check(H.popShowing() == T.b2, T.L .. ": the pop-out of a radio in a bag stays open (a radio carried is in reach)",
            "showing " .. H.s(H.devName(H.popShowing())) .. " 2 s after the button; the radio in " .. H.ctype(H.where(T.b2)))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== the two-way face's own reading (what its glass shows)
function H.twRead(dev) local st = nil; pcall(function() st = S.TW.read(dev) end); return st end
function H.twKind(pid) local k = nil; pcall(function() local i = S.TW.info(pid); k = i and i.kind end); return k end
function H.twGlass(w)
    local t = H.tw(w)
    if not t then return nil end
    local r = nil
    pcall(function() r = S.TW.reading(S.TW.read(t.dev), H.twKind(t.pid)) end)
    return r
end

-- ===================================================================== R31 a walkie's battery (B1)
function C.r31()
    local T = { L = "R31 a walkie's battery" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.WalkieTalkie3", { batt = 0.1, on = true, vol = 0.3 })
        H.give("Base.Battery")
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    H.faceShotQ(T, "cw", "dev")
    Q.waitMs(700)
    H.step(2, function()
        if T.off then return end
        local cw = RT.cw()
        local g = H.twGlass(cw)
        local c = H.charge(T.dev) or 0
        local want = math.max(0, math.min(4, math.ceil(c * 4 - 0.001)))
        Q.check(g ~= nil and g.batt == want and g.batLabel == H.tr("UI_ZeD_Radio_Bat"), T.L .. ": the glass shows BAT with the charge's bars",
            "glass " .. H.s(g and g.batLabel) .. " " .. tostring(g and g.batt) .. " bars; the game's charge " .. H.n2(c) .. " (" .. want .. " bars)")
        local row = H.fillRow(cw, "fill:radio:batt")
        Q.check(row ~= nil and row.value == math.floor(c * 100 + 0.5) .. "%", T.L .. ": the Power block reads the battery's charge", "row " .. H.s(row and row.value) .. "; the game's " .. H.n2(c))
        pcall(function() H.dd(T.dev):setPower(0) end)
        T.keys = H.hitIds(cw)
    end)
    Q.waitMs(700)
    H.step(2, function()
        if T.off then return end
        local cw = RT.cw()
        local key = H.hit(cw, "battery") ~= nil
        local plainBatt = nil
        pcall(function()
            local ctl = ZeD.PlainFace.controlsFor(S.TW, S.TW.basePid(H.face(cw)))
            plainBatt = ctl and ctl.byId and ctl.byId.battery ~= nil and ctl.byId.battery.press ~= nil
        end)
        Q.check(key or plainBatt == true, T.L .. " (B1): a walkie gone flat has a ZeD control to change its battery (the game's Power module does: UsesBattery)",
            "the face's controls " .. H.list(T.keys, 16) .. "; a pressable battery row on the plain card " .. tostring(plainBatt) .. "; the game: uses a battery " .. tostring(H.usesBatt(T.dev))
            .. ", battery in " .. tostring(H.battOn(T.dev)) .. " at " .. H.n2(H.charge(T.dev)) .. ", a spare on him " .. H.count("Base.Battery"))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R32 a walkie's power (VOL)
function C.r32()
    local T = { L = "R32 a walkie's power" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.WalkieTalkie2", { batt = 0.8, on = false, vol = 0.3 })
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    H.faceShotQ(T, "cw", "dev")
    H.step(2, function()
        if T.off then return end
        H.click(RT.cw(), "vol", nil, T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.on(T.dev), T.L .. " (mouse): a click on VOL pushes the walkie's power on", "the game's on " .. tostring(H.on(T.dev)) .. ", volume " .. H.n2(H.vol(T.dev)))
        local cw = RT.cw()
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tw:vol")
        -- (run 1: X did nothing at both sizes. What the focused stop carries is read here, and its own X is pressed
        -- after the pad's, so the report tells the pad's dispatch from the stop)
        local el = nil
        pcall(function() el = S.F.getFocusedElement(cw) end)
        T.elInfo = "focused " .. tostring(el and el.id) .. ", a knob " .. tostring(el and el.isKnob) .. ", an X (onContextMenu) " .. tostring(el ~= nil and el.onContextMenu ~= nil)
            .. ", its X word " .. H.s(el and el.promptX)
        T.t0 = getTimestampMs()
    end)
    H.tapQ("cw", "X", function() return T.go and not T.off end)
    H.step(3, function()
        if T.off or not T.go then H.padOff(); return end
        T.ms = getTimestampMs() - (T.t0 or 0)
        Q.check(not H.on(T.dev), T.L .. " (pad): X on VOL pushes the power off", "the game's on " .. tostring(H.on(T.dev)) .. "; " .. T.elInfo
            .. "; the tap (down 4 frames, then up) and this check about " .. T.ms .. " ms apart (X counts as held past 350 ms)")
        T.on1 = H.on(T.dev)
        local cw = RT.cw()
        local el = nil
        pcall(function() el = S.F.getFocusedElement(cw) end)
        if T.on1 and el and el.onContextMenu then H.zcall(function() el.onContextMenu(cw, el) end) end
    end)
    H.step(3, function()
        H.padOff()
        if T.off or not T.go or not T.on1 then return end
        H.note(T.L .. ": the focused VOL stop's own X (onContextMenu) called directly leaves the walkie on " .. tostring(H.on(T.dev))
            .. " (off means the stop is wired and the pad's X tap never reached it)")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R33 the Tactical's range
function C.r33()
    local T = { L = "R33 the Tactical's 10-500 MHz" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.WalkieTalkie4", { batt = 0.8, on = true, vol = 0.3, ch = 500000 })
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    H.faceShotQ(T, "cw", "dev")
    H.step(2, function()
        if T.off then return end
        H.click(RT.cw(), "tune", "r", T.L)
        local lo, hi = H.range(T.dev)
        local g = H.twGlass(RT.cw())
        Q.check(H.ch(T.dev) == lo and g ~= nil and g.big == S.O.freqText(lo, true) and g.big == "010.000", T.L .. " (mouse): TUNE up from 500.000 wraps to 10.000, read to three places",
            "the game's channel " .. H.mhz(H.ch(T.dev)) .. " (its band " .. H.mhz(lo) .. "-" .. H.mhz(hi) .. "); the glass " .. H.s(g and g.big))
        pcall(function() H.dd(T.dev):setChannel(100000) end)
        local cw = RT.cw()
        cw._radioPadTurn = nil
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tw:tune")
    end)
    H.tapQ("cw", "A", function() return T.go and not T.off end)
    for i = 1, 9 do
        H.dirQ("cw", "right", function() return T.go and not T.off end)
        if i == 8 then H.step(1, function() T.c8 = H.ch(T.dev) end) end
    end
    H.step(2, function()
        if T.off or not T.go then H.padOff(); return end
        local d = (H.ch(T.dev) or 0) - (T.c8 or 0)
        Q.check(d == 1000, T.L .. " (pad): held, the D-pad tunes a walkie 5 steps a click after 8 quick ones (not a ham's 25)",
            "the game's channel 100.000 -> " .. H.mhz(T.c8) .. " after 8, then " .. H.mhz(H.ch(T.dev)) .. " (" .. d .. " kHz)")
    end)
    H.tapQ("cw", "B", function() return T.go and not T.off end)
    H.step(2, function() H.padOff() end)
    H.caseEnd(T.L)
end

-- ===================================================================== R34 MEM and CH
function C.r34()
    local T = { L = "R34 MEM and CH" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.WalkieTalkie3", { batt = 0.8, on = true, vol = 0.3, ch = 146520, presets = {} })
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    H.faceShotQ(T, "cw", "dev")
    H.step(2, function() if not T.off then H.click(RT.cw(), "mem", nil, T.L) end end)
    H.step(3, function()
        if T.off then return end
        T.f1, T.n1 = H.flash(T.dev), #H.presets(T.dev)
        H.click(RT.cw(), "tune", "r", T.L)
        T.c2 = H.ch(T.dev)
        H.click(RT.cw(), "mem", nil, T.L)
    end)
    H.step(3, function()
        if T.off then return end
        T.f2, T.n2 = H.flash(T.dev), #H.presets(T.dev)
        H.click(RT.cw(), "mem", nil, T.L)
    end)
    H.step(3, function()
        if T.off then return end
        T.f3, T.n3 = H.flash(T.dev), #H.presets(T.dev)
        local w1, w2 = H.tr("UI_ZeD_Radio_ChStored", "01"), H.tr("UI_ZeD_Radio_ChStored", "02")
        Q.check(T.n1 == 1 and T.f1 == w1 and T.n2 == 2 and T.f2 == w2 and T.n3 == 2 and T.f3 == w2, T.L .. " (mouse): MEM stores the channel once (CH 01, CH 02), MEM on a stored one flashes it again with no copy",
            "presets " .. tostring(T.n1) .. " " .. H.s(T.f1) .. "; " .. tostring(T.n2) .. " " .. H.s(T.f2) .. " (at " .. H.mhz(T.c2) .. "); " .. tostring(T.n3) .. " " .. H.s(T.f3) .. "; the game's list " .. H.presetText(T.dev))
        local pr = H.presets(T.dev)
        if pr[1] then pcall(function() H.dd(T.dev):setChannel(pr[1].freq) end) end
        local cw = RT.cw()
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tw:chdn")
    end)
    H.tapQ("cw", "A", function() return T.go and not T.off end)
    Q.waitMs(700)
    H.step(2, function()
        H.padOff()
        if T.off or not T.go then return end
        local pr = H.presets(T.dev)
        Q.check(#pr >= 2 and H.ch(T.dev) == pr[#pr].freq, T.L .. " (pad): CH- on channel 01 goes to the last stored channel", "the game's channel " .. H.mhz(H.ch(T.dev)) .. "; the list " .. H.presetText(T.dev))
        local n = 0
        local d = H.fill(RT.cw())
        n = d and #(d.presets or {}) or 0
        Q.check(n == #pr, T.L .. ": the Channels block has a row for each stored channel", n .. " rows, " .. #pr .. " stored")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R35 name a channel
function C.r35()
    local T = { L = "R35 name a channel" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.WalkieTalkie3", { batt = 0.8, on = true, vol = 0.3, ch = 146520, presets = { { "146.520 MHz", 146520 } } })
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    H.step(2, function() if not T.off then S.lastBox = nil; H.rclick(RT.cw(), "mem") end end)
    H.wait(1500, function() return T.off or H.boxUp() end, function(ok)
        if T.off then return end
        Q.check(ok, T.L .. " (mouse): a right-click on MEM opens the naming box", "box up " .. tostring(H.boxUp()))
        if ok then H.boxOK("Base") end
    end)
    Q.waitMs(700)
    H.step(2, function()
        if T.off then return end
        local pr = H.presets(T.dev)
        local row = H.fillRow(RT.cw(), "fill:radio:ch:1")
        Q.check(#pr == 1 and pr[1].name == "Base" and row ~= nil and H.has(row.label, "Base"), T.L .. ": OK names the channel and its Channels row",
            "the game's list " .. H.presetText(T.dev) .. "; row " .. H.s(row and row.label))
        S.lastBox = nil
        local cw = RT.cw()
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tw:mem")
    end)
    H.holdAQ("cw", 800, function() return T.go and not T.off end)
    H.wait(1500, function() return T.off or not T.go or H.boxUp() end, function(ok)
        H.padOff()
        if T.off or not T.go then return end
        Q.check(ok, T.L .. " (pad): A held on MEM opens the naming box", "box up " .. tostring(H.boxUp()))
        if ok then H.boxOK("") end
        T.fl = H.flash(T.dev)
    end)
    H.step(3, function()
        if T.off or not T.go then return end
        Q.check(#H.presets(T.dev) == 0 and T.fl == H.tr("UI_ZeD_Radio_ChCleared", "01"), T.L .. " (pad): an empty name forgets the channel and flashes CH 01 CLEARED",
            "the game's list " .. H.presetText(T.dev) .. "; flash " .. H.s(T.fl))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R36 memory full
function C.r36()
    local T = { L = "R36 memory full" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.WalkieTalkie3", { batt = 0.8, on = true, vol = 0.3, ch = 120000, presets = {} })
        T.max = H.maxPresets(T.dev) or 10
        local list = {}
        for i = 1, T.max - 1 do list[#list + 1] = { "Stage " .. i, 30000 + i * 200 } end
        H.prep(T.dev, { presets = list })
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    H.step(2, function() if not T.off then H.click(RT.cw(), "mem", nil, T.L) end end)
    H.step(3, function()
        if T.off then return end
        T.n1, T.f1 = #H.presets(T.dev), H.flash(T.dev)
        pcall(function() H.dd(T.dev):setChannel(121000) end)
        H.click(RT.cw(), "mem", nil, T.L)
    end)
    H.step(3, function()
        if T.off then return end
        local n2, f2 = #H.presets(T.dev), H.flash(T.dev)
        Q.check(T.n1 == T.max and n2 == T.max and f2 == H.tr("UI_ZeD_Radio_MemFull"), T.L .. " (mouse): at the game's getMaxPresets MEM flashes MEMORY FULL and adds nothing",
            "max " .. tostring(T.max) .. "; after the last free MEM " .. tostring(T.n1) .. " (" .. H.s(T.f1) .. "), after one more " .. n2 .. " (" .. H.s(f2) .. ")")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R37 MIC
function C.r37()
    local T = { L = "R37 MIC" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.WalkieTalkie2", { batt = 0.8, on = false, vol = 0.3, mic = false })
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    H.step(2, function()
        if T.off then return end
        T.game = H.gameValid("MuteMicrophone", T.dev, true)
        H.click(RT.cw(), "mic", nil, T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.micMuted(T.dev) == false and T.game == false, T.L .. " (mouse): MIC on a walkie that is off does nothing, as the game refuses it",
            "the game's mic muted " .. tostring(H.micMuted(T.dev)) .. "; its isValidMuteMicrophone " .. tostring(T.game))
        H.prep(T.dev, { on = true })
        local cw = RT.cw()
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tw:mic")
    end)
    H.tapQ("cw", "A", function() return T.go and not T.off end)
    Q.waitMs(700)
    H.step(2, function()
        H.padOff()
        if T.off or not T.go then return end
        local g = H.twGlass(RT.cw())
        local row = H.fillRow(RT.cw(), "fill:radio:mic")
        Q.check(H.micMuted(T.dev) == true and g ~= nil and g.tx == S.O.word("micOff") and row ~= nil and row.value == getText("IGUI_RadioNo"),
            T.L .. " (pad): MIC mutes the microphone: MIC OFF on the glass, Microphone No in the block",
            "the game's mic muted " .. tostring(H.micMuted(T.dev)) .. "; glass " .. H.s(g and g.tx) .. "; row " .. H.s(row and row.value))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R38 SCAN on the Army walkie
function C.r38()
    local T = { L = "R38 SCAN on the Army walkie" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.WalkieTalkie5", { batt = 0.9, on = true, vol = 0.2, ch = 88000 })
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    H.faceShotQ(T, "cw", "dev")
    H.step(2, function()
        if T.off then return end
        if not H.hit(RT.cw(), "scan") then T.off = true; Q.skip(T.L, "no SCAN on the face (" .. H.list(H.hitIds(RT.cw())) .. ")"); return end
        H.click(RT.cw(), "scan", nil, T.L)
    end)
    H.step(3, function()
        if T.off then return end
        T.c1 = H.ch(T.dev)
        local g = H.twGlass(RT.cw())
        Q.check(H.scanning(T.dev) and H.stName(T.c1) ~= nil and g ~= nil and (g.line == S.O.word("scan") or H.has(g.l2, S.O.word("scan"))),
            T.L .. " (mouse): SCAN tunes to the next named station and the glass reads SCAN",
            "the game's channel " .. H.mhz(T.c1) .. " (" .. H.s(H.stName(T.c1)) .. "); scanning " .. tostring(H.scanning(T.dev)) .. "; glass " .. H.s(g and (g.line or g.l2)))
    end)
    Q.waitMs(5800)
    H.step(2, function()
        if T.off then return end
        T.c2 = H.ch(T.dev)
        Q.check(T.c2 ~= T.c1 and H.stName(T.c2) ~= nil, T.L .. ": after 5 s SCAN moves on to the next named station",
            H.mhz(T.c1) .. " -> " .. H.mhz(T.c2) .. " (" .. H.s(H.stName(T.c2)) .. ")")
        H.click(RT.cw(), "vol", nil, T.L)
    end)
    Q.waitMs(5800)
    H.step(2, function()
        if T.off then return end
        Q.check(not H.on(T.dev) and not H.scanning(T.dev) and H.ch(T.dev) == T.c2, T.L .. ": turned off, the scan stops",
            "on " .. tostring(H.on(T.dev)) .. ", scanning " .. tostring(H.scanning(T.dev)) .. ", channel " .. H.mhz(T.c2) .. " -> " .. H.mhz(H.ch(T.dev)))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R39 LAMP on the Tactical at night
function C.r39()
    local T = { L = "R39 LAMP on the Tactical at night" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.WalkieTalkie4", { batt = 0.8, on = true, vol = 0.2, ch = 100000 })
        H.hold(T.dev, "p")
        pcall(function() getGameTime():setTimeOfDay(22.5) end)
        S.back.clock = true
    end)
    H.showQ(T, "cw", "dev")
    H.step(2, function()
        if T.off then return end
        if not H.hit(RT.cw(), "lamp") then T.off = true; Q.skip(T.L, "no LAMP on the face (" .. H.list(H.hitIds(RT.cw())) .. ")"); return end
        local cw = RT.cw()
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tw:lamp")
    end)
    H.tapQ("cw", "A", function() return T.go and not T.off end)
    H.step(2, function()
        H.padOff()
        if T.off or not T.go then return end
        T.lit = S.O.lampLit(T.dev)
        T.t0 = getTimestampMs()
    end)
    H.shotQ(function() if T.off or not T.lit then return nil end; return "rd_walkie_tactical_night_lamp_" .. H.sizeTag() end, "the Tactical's lamp lit at night")
    H.wait(7000, function() return T.off or not S.O.lampLit(T.dev) end, function(ok)
        if T.off or not T.go then return end
        local ms = getTimestampMs() - (T.t0 or 0)
        Q.check(T.lit and ok and ms >= 4000 and ms <= 6500, T.L .. " (pad): A on LAMP lights the glass for 5 s", "lit " .. tostring(T.lit) .. ", dark again after " .. ms .. " ms")
        pcall(function() if S.found.tod then getGameTime():setTimeOfDay(S.found.tod) end end)
        S.back.clock = nil
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R40 the toy walkie
function C.r40()
    local T = { L = "R40 the toy walkie" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.WalkieTalkie1", { batt = 0.8, on = true, vol = 0.2, ch = 100000 })
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    H.faceShotQ(T, "cw", "dev")
    H.step(2, function()
        if T.off then return end
        local ids = H.hitIds(RT.cw())
        table.sort(ids)
        local g = H.twGlass(RT.cw())
        local want = string.format("%.2f", (H.ch(T.dev) or 0) / 1000) .. " MHZ"
        Q.check(table.concat(ids, ",") == "mic,tune,vol", T.L .. ": the toy's face has VOL, TUNE and MIC only", H.list(ids))
        Q.check(g ~= nil and g.big == want, T.L .. ": its glass reads the frequency to two places and MHZ", "glass " .. H.s(g and g.big) .. "; the game's channel " .. H.mhz(H.ch(T.dev)))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R41 the pop-out of a walkie in a bag (B7)
function C.r41()
    local T = { L = "R41 the pop-out of a walkie carried in a bag" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        local _, inv = H.bag()
        T.dev = H.giveRadio("Base.WalkieTalkie2", { batt = 0.8, on = true, vol = 0.2 })
        if not (inv and T.dev and H.moveTo(T.dev, inv)) then T.off = true; Q.skip(T.L, "no walkie in a bag could be staged"); return end
        H.zcall(function() ISRadioWindow.activate(S.p, T.dev) end)
    end)
    H.wait(4000, function() local cw = RT.cw(); return T.off or (H.onTab(cw) and H.shownDev(cw) == T.dev and cw._radioFullZone ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the walkie in a bag shows on the Carried tab with its pop-out button", H.tabText("cw", T.dev)) then T.off = true; return end
        H.clickAt(RT.cw(), RT.cw()._radioFullZone)
        T.opened0 = H.popShowing() == T.dev
        T.t0 = getTimestampMs()
    end)
    H.step(3, function() if not T.off then T.opened = H.popShowing() == T.dev end end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        local tw = nil
        pcall(function() tw = S.TW.inReach(S.p, T.dev) end)
        Q.check(T.opened and H.popShowing() == T.dev, T.L .. " (B7): the pop-out of a walkie in a bag stays open",
            "showing in the click's own frame " .. tostring(T.opened0) .. ", 3 frames on " .. tostring(T.opened) .. ", after 1.5 s " .. tostring(H.popShowing() == T.dev)
            .. "; TwoWayFace.inReach " .. tostring(tw) .. "; the walkie in " .. H.ctype(H.where(T.dev))
            .. " (TwoWayFace.inReach takes the hands and the back only)")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R42 headphones on a walkie (B2)
function C.r42()
    local T = { L = "R42 headphones on a walkie" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.WalkieTalkie2", { batt = 0.8, on = true, vol = 0.2 })
        H.give("Base.Earbuds")
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    Q.waitMs(700)
    H.step(2, function()
        if T.off then return end
        local cw = RT.cw()
        local key, row = H.hit(cw, "phones") ~= nil, H.fillRow(cw, "fill:radio:phones") ~= nil
        local game = H.gameValid("AddHeadphones", T.dev, H.slice(H.all(), function(it) return H.ft(it) == "Base.Earbuds" end))
        local port = H.portable(T.dev)
        Q.check(key or row, T.L .. " (B2): a walkie has a ZeD way to plug in the headphones the game offers it (a portable set's box, RWMVolume)",
            "a phones key " .. tostring(key) .. ", a Headphones row " .. tostring(row) .. "; the face's controls " .. H.list(H.hitIds(cw), 14)
            .. "; the game's isValidAddHeadphones " .. tostring(game) .. ", portable " .. tostring(port))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R55 the mouse wheel
function C.r55()
    local T = { L = "R55 the mouse wheel" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.RadioMakeShift", { batt = 0.8, on = true, vol = 0.5 })
        T.b = H.giveRadio("Base.RadioBlack", { batt = 0.8, on = false })
        H.hold(T.dev, "p")
        H.hold(T.b, "s")
    end)
    H.showQ(T, "cw", "dev")
    H.step(2, function()
        if T.off then return end
        local cw = RT.cw()
        local z = cw._radioStripZone
        T.i0 = cw._radioIdx
        local used = z and H.wheelOn(cw, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2), 1)
        T.i1 = cw._radioIdx
        local sh = S.RTab.showingEntry(cw)
        Q.check(used and T.i1 ~= T.i0 and sh ~= nil and sh.radioInstance == T.b, T.L .. ": the wheel over the radios' strip shows the next radio",
            "used " .. tostring(used) .. ", index " .. tostring(T.i0) .. " -> " .. tostring(T.i1) .. ", showing " .. H.s(sh and H.devName(sh.radioInstance)))
        S.RTab.selectRadio(cw, T.i0 or 1)
    end)
    H.wait(2000, function() return T.off or (H.shownDev(RT.cw()) == T.dev and H.hit(RT.cw(), "vol") ~= nil) end, function(ok)
        if T.off then return end
        local cw = RT.cw()
        local v0 = H.vol(T.dev)
        local used = H.wheelHit(cw, "vol", -1)
        local v1 = H.vol(T.dev)
        Q.check(ok and used and math.abs((v1 or 0) - (v0 or 0) - 0.1) < 0.001, T.L .. ": the wheel over a knob turns it", "used " .. tostring(used) .. ", the game's volume " .. H.n2(v0) .. " -> " .. H.n2(v1))
        local sc = cw._radioScroll
        if sc and sc.visible then
            local x, y = H.faceBare(cw)
            local p0 = sc.scrollPos
            local u2 = x and H.wheelOn(cw, x, y, 1)
            Q.check(u2 and sc.scrollPos ~= p0, T.L .. ": the wheel elsewhere on the face scrolls the body", "used " .. tostring(u2) .. ", scroll " .. H.n2(p0) .. " -> " .. H.n2(sc.scrollPos))
        else
            H.note(T.L .. ": the body fits at " .. H.sizeTag() .. " (no scrollbar): the wheel elsewhere has nothing to scroll")
        end
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R53 the pad on an empty slot
function C.r53()
    local T = { L = "R53 the pad on an empty slot" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.dev = H.giveRadio("Base.RadioRed", { batt = 0.8, on = true, vol = 0.2 })
        T.disc = H.give("Base.Disc_Retail")
        T.rec = T.disc and H.mediaReady(T.disc, "CDs")
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    H.step(2, function()
        if T.off then return end
        S.lastCtx = nil
        local cw = RT.cw()
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tw:slot")
        Q.check(T.go, T.L .. ": the focus goes onto the slot", "stops " .. H.stopIds(cw))
    end)
    H.tapQ("cw", "A", function() return T.go and not T.off end)
    H.step(2, function()
        if T.off or not T.go then H.padOff(); return end
        Q.check(H.menuOpen() and (not T.rec or H.menuOpt(T.disc) ~= nil), T.L .. ": A on the empty slot lists the discs he carries",
            "the list up " .. tostring(H.menuOpen()) .. ": " .. H.s(H.list(H.menuNames())))
        local jd = nil
        pcall(function() jd = JoypadState.players[S.pn + 1] end)
        if jd then
            Q.check(jd.focus == S.lastCtx, T.L .. ": the pad's focus goes into the list", "the pad's focus " .. tostring(jd.focus and jd.focus.Type))
        else
            Q.skip(T.L .. ": the pad's focus goes into the list", "no controller is bound on this rig (the list takes the pad's focus only from a real one)")
        end
        H.menuClose()
    end)
    H.step(4, function()
        if T.off or not T.go then H.padOff(); return end
        Q.check(H.focusedId(RT.cw()) == "radio:tw:slot", T.L .. ": the list closed, the focus is back on the slot", "focus " .. tostring(H.focusedId(RT.cw())))
        H.padOff()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== the room's squares
function H.ringSq(i) return S.spot and S.spot.ring[i] or nil end
function H.spotXYZ() return math.floor(S.spot.x), math.floor(S.spot.y), S.spot.z end
-- a free square at distance d (on a ring of that size round the spot) on floor z; room squares first
function H.sqAtDist(d, z)
    local cx, cy = H.spotXYZ()
    local any = nil
    for dy = -d, d do
        for dx = -d, d do
            if math.abs(dx) == d or math.abs(dy) == d then
                local sq = H.freeSqAt(cx + dx, cy + dy, z)
                if sq and not H.used(sq) then
                    local room = false
                    pcall(function() room = sq:getRoom() ~= nil end)
                    if room then return sq end
                    any = any or sq
                end
            end
        end
    end
    return any
end
-- the devices the World window lists (the game's objects, read from its squares: the 3 x 3 he can reach)
function H.gameNear()
    local out = {}
    local cur = S.p:getCurrentSquare()
    local cx, cy, cz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    for dy = -1, 1 do
        for dx = -1, 1 do
            local sq = H.sq(cx + dx, cy + dy, cz)
            local ok = sq ~= nil
            if ok and sq ~= cur and cur then pcall(function() ok = cur:canReachTo(sq) end) end
            if ok then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do local o = objs:get(i); if instanceof(o, "IsoWaveSignal") then out[#out + 1] = o end end
            end
        end
    end
    return out
end
function H.inList(w, dev) return w ~= nil and S.RTab.indexOf(w._radios, dev) ~= nil end
function H.wwShow(T, key) H.showQ(T, "ww", key) end

-- ===================================================================== R5 the world 3 x 3
function C.r5()
    local T = { L = "R5 the world 3 x 3" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        T.r = H.place("radio_black", H.ringSq(1))
        local cx, cy, cz = H.spotXYZ()
        for _, d in ipairs({ { 2, 0, 1, 0 }, { -2, 0, -1, 0 }, { 0, 2, 0, 1 }, { 0, -2, 0, -1 } }) do
            if not T.tvSq then
                local sq = H.freeSqAt(cx + d[1], cy + d[2], cz)
                local step = H.freeSqAt(cx + d[3], cy + d[4], cz)
                if sq and step and not H.used(sq) and sq ~= H.ringSq(1) and step ~= H.ringSq(1) then T.tvSq, T.stepSq = sq, step end
            end
        end
        T.tv = T.tvSq and H.place("tv_black", T.tvSq)
        if not (T.r and T.tv) then T.off = true; Q.skip(T.L, "no room for a set beside him and a TV two tiles off"); return end
        H.refreshList("ww")
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        local ww = RT.ww()
        Q.check(H.inList(ww, T.r) and not H.inList(ww, T.tv), T.L .. ": the set one tile away is listed, the TV two tiles away is not",
            "the World list: radio " .. tostring(H.inList(ww, T.r)) .. ", TV " .. tostring(H.inList(ww, T.tv)) .. "; the game's 3 x 3 holds " .. #H.gameNear() .. " set(s)")
        H.goTo(T.stepSq:getX() + 0.5, T.stepSq:getY() + 0.5, T.stepSq:getZ())
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        local ww = RT.ww()
        local list = ww._radios or {}
        local sorted, d = true, {}
        for i, e in ipairs(list) do d[#d + 1] = H.n1(e.distance); if i > 1 and (e.distance or 0) < (list[i - 1].distance or 0) then sorted = false end end
        local near = H.gameNear()
        Q.check(H.inList(ww, T.tv) and #list == #near and sorted, T.L .. ": a step closer, the TV joins, the list sorted by distance",
            "listed " .. #list .. " at " .. H.list(d) .. "; the game's 3 x 3 holds " .. #near .. "; TV listed " .. tostring(H.inList(ww, T.tv)))
        -- a set across a wall: a square of the 3 x 3 he cannot reach
        local cur = S.p:getCurrentSquare()
        local cx, cy, cz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
        for _, dd in ipairs(S.RING) do
            if not T.wall then
                local sq = H.freeSqAt(cx + dd[1], cy + dd[2], cz)
                local reach = true
                if sq then pcall(function() reach = cur:canReachTo(sq) end) end
                if sq and not reach and not H.used(sq) then T.wall = sq end
            end
        end
        if T.wall then T.w = H.place("radio_red", T.wall) end
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        if not T.w then Q.skip(T.L .. ": a set across a wall", "no free square of his 3 x 3 behind a wall here"); return end
        Q.check(not H.inList(RT.ww(), T.w), T.L .. ": a set across a wall is left out (canReachTo)", "listed " .. tostring(H.inList(RT.ww(), T.w)) .. " at " .. T.wall:getX() .. "," .. T.wall:getY())
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R6 a TV across the room, Lite (B3)
function C.r6()
    local T = { L = "R6 a TV across the room (Lite)" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        H.lite(true)
        local sq = H.sqAtDist(6, S.spot.z) or H.sqAtDist(5, S.spot.z) or H.sqAtDist(7, S.spot.z)
        T.tv = sq and H.place("tv_black", sq)
        if not T.tv then T.off = true; Q.skip(T.L, "no free square 5 to 7 tiles off"); return end
        H.prep(T.tv, { on = false, vol = 0.2 })
        T.d = math.sqrt((sq:getX() + 0.5 - S.p:getX()) ^ 2 + (sq:getY() + 0.5 - S.p:getY()) ^ 2)
        H.zcall(function() ISRadioWindow.activate(S.p, T.tv) end)
    end)
    H.wait(4000, function() local ww = RT.ww(); return T.off or (H.onTab(ww) and H.shownDev(ww) == T.tv) end, function(ok)
        if T.off then return end
        local ww = RT.ww()
        local e = ww and ww._radios and ww._radios[S.RTab.indexOf(ww._radios, T.tv) or 0]
        Q.check(ok and e ~= nil and e.locationTag == "Floor" and e.pinned == true and S.WR.pins[S.pn] == T.tv and H.isPlain(ww),
            T.L .. ": Device Options on a TV " .. H.n1(T.d) .. " tiles away opens the World window's Radio tab on it, pinned, the plain card",
            H.tabText("ww", T.tv) .. "; its place " .. H.s(e and e.locationTag) .. ", pinned " .. tostring(e and e.pinned) .. ", the route's pin " .. tostring(S.WR.pins[S.pn] == T.tv))
        Q.check(not H.gameWin(), T.L .. ": no game window", "ISRadioWindow up " .. tostring(H.gameWin()))
        if H.powered(T.tv) and H.hit(ww, "power") then
            H.qstop()
            H.click(ww, "power", nil, T.L)
            T.pressed = true
        else
            Q.skip(T.L .. " (B3): power from across the room", "the TV has no power there (" .. tostring(H.powered(T.tv)) .. ") or the plain card has no power control")
        end
    end)
    H.step(3, function()
        if T.off or not T.pressed then return end
        Q.check(not (H.on(T.tv) and not H.qWalk()), T.L .. " (B3): ZeD's power works the set from " .. H.n1(T.d) .. " tiles with no walk, as the game would not (it walks to the set first: the director's stakes call)",
            "the game's on " .. tostring(H.on(T.tv)) .. "; queued " .. H.qkinds())
        local x = T.tv:getX() + 11.5
        H.goTo(x, T.tv:getY() + 0.5, T.tv:getZ())
    end)
    Q.waitMs(2000)
    H.step(2, function()
        if T.off then return end
        local ww = RT.ww()
        Q.check(S.WR.pins[S.pn] == nil and not H.inList(ww, T.tv), T.L .. ": 11 tiles away the pin drops and the TV leaves the list",
            "pin " .. tostring(S.WR.pins[S.pn] ~= nil) .. ", listed " .. tostring(H.inList(ww, T.tv)))
        if #((ww and ww._radios) or {}) == 0 then
            Q.check(ww._activeTab ~= "radio", T.L .. ": with the list empty the tab falls back to Loot", "the World tab " .. tostring(ww._activeTab))
        else
            H.note(T.L .. ": other sets are still in reach there, the tab stays")
        end
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R7 another floor
function C.r7()
    local T = { L = "R7 a TV on another floor" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        local cx, cy, cz = H.spotXYZ()
        for _, z in ipairs({ cz + 1, cz - 1 }) do
            for r = 0, 6 do
                for dy = -r, r do
                    for dx = -r, r do
                        if not T.sq and z >= 0 then
                            local sq = H.freeSqAt(cx + dx, cy + dy, z)
                            if sq then T.sq = sq end
                        end
                    end
                end
            end
        end
        T.tv = T.sq and H.place("tv_black", T.sq)
        if not T.tv then T.off = true; Q.skip(T.L, "no square with a floor one storey up or down within 6 tiles"); return end
        local ww = RT.ww()
        T.tab0 = ww and ww._activeTab
        H.zcall(function() ISRadioWindow.activate(S.p, T.tv) end)
    end)
    Q.waitMs(1200)
    H.step(2, function()
        if T.off then return end
        local ww = RT.ww()
        Q.check((ww and ww._activeTab) == T.tab0 and S.WR.pins[S.pn] == nil and not H.gameWin() and H.popShowing() == nil,
            T.L .. ": Device Options on a TV on another floor opens nothing",
            "the TV on floor " .. T.sq:getZ() .. " (he is on " .. math.floor(S.p:getZ()) .. "); the World tab " .. tostring(T.tab0) .. " -> " .. tostring(ww and ww._activeTab)
            .. ", pin " .. tostring(S.WR.pins[S.pn] ~= nil) .. ", the game's window " .. tostring(H.gameWin()) .. ", a pop-out " .. tostring(H.popShowing() ~= nil))
        pcall(function() ISRadioWindow._zedRoute(S.p, T.tv) end)
    end)
    H.step(3, function()
        if T.off then return end
        H.note(T.L .. ": the game's own window for it (compare): opens " .. tostring(H.gameWin()) .. " (its reach reads x and y only)")
        H.gameWinShut()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R8 faces on: the world click
function C.r8()
    local T = { L = "R8 the TV's face popped out by a click in the world" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        T.tv = H.place("tv_black", H.ringSq(1))
        if not T.tv then T.off = true; Q.skip(T.L, "no TV could be placed"); return end
        H.prep(T.tv, { on = false, vol = 0.2 })
        local ww = RT.ww()
        T.tab0 = ww and ww._activeTab
        H.zcall(function() S.FP.worldClick(T.tv) end)
    end)
    H.step(3, function()
        if T.off then return end
        T.open1 = H.popShowing() == T.tv
        H.zcall(function() S.FP.worldClick(T.tv) end)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(T.open1 and H.popShowing() == nil, T.L .. " (mouse): a click on the TV pops its face out and a second puts it away",
            "after the first " .. tostring(T.open1) .. ", after the second showing " .. tostring(H.popShowing() ~= nil) .. " (faces on " .. tostring(S.FP.on()) .. ")")
        S.FP._click.obj = nil
        H.zcall(function() ISObjectClickHandler.doClick(T.tv, 0, 0) end)
    end)
    H.step(3, function()
        if T.off then return end
        local ww = RT.ww()
        Q.check(H.popShowing() == T.tv and (ww and ww._activeTab) == T.tab0 and not H.gameWin(), T.L .. ": the game's own click within 1.5 tiles brings one surface: the pop-out, no tab and no game window",
            "showing " .. tostring(H.popShowing() == T.tv) .. ", the World tab " .. tostring(T.tab0) .. " -> " .. tostring(ww and ww._activeTab) .. ", the game's window " .. tostring(H.gameWin()))
        RT.bounds(Q, T.L .. ", the TV's pop-out")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R9 Television naming
function H.wwRadioTab() for _, t in ipairs(ZeD_WorldWindow.TABS or {}) do if t.id == "radio" then return t end end; return nil end
function H.namings()
    local ww, tab = RT.ww(), H.wwRadioTab()
    local label, icon, slice = nil, nil, nil
    pcall(function() label = ZeD_WorldWindow.tabLabel(tab, ww) end)
    pcall(function() icon = ZeD_WorldWindow.tabIcon(tab, ww) end)
    local wT = {}
    pcall(function() wT = S.DW.Wd.tabs(S.p, S.pn) end)
    local e = H.slice(wT, function(x) return x.key == "radio" end)
    slice = e and e.name
    return label, icon, slice
end
function C.r9()
    local T = { L = "R9 Television naming" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        T.r = H.place("radio_black", H.ringSq(1))
        T.tv = H.place("tv_black", H.ringSq(2))
        if not (T.r and T.tv) then T.off = true; Q.skip(T.L, "two sets could not be placed"); return end
    end)
    H.wwShow(T, "r")
    H.faceShotQ(T, "ww", "r")
    H.step(2, function()
        if T.off then return end
        local l, i, s = H.namings()
        local radio = getText("IGUI_ItemType_Radio")
        Q.check(l == radio and i == "radio" and s == radio, T.L .. ": the radio showing, the World tab, its icon and the wheel's slice read Radio",
            "tab " .. H.s(l) .. ", icon " .. H.s(i) .. ", slice " .. H.s(s) .. "; the shown set a TV " .. tostring(H.isTV(H.shownDev(RT.ww()))))
        local ww = RT.ww()
        T.tvIdx = S.RTab.indexOf(ww._radios, T.tv)
        H.clickAt(ww, H.tabZone(ww, T.tvIdx))
    end)
    H.step(3, function()
        if T.off then return end
        local l, i, s = H.namings()
        local tvw = H.tr("UI_ZeD_World_TabTelevision")
        Q.check(l == tvw and i == "tv" and s == tvw, T.L .. " (mouse): the TV's tab clicked, the World tab, its icon and the wheel's slice read Television",
            "tab " .. H.s(l) .. ", icon " .. H.s(i) .. ", slice " .. H.s(s) .. "; the shown set a TV " .. tostring(H.isTV(H.shownDev(RT.ww()))))
        local ww = RT.ww()
        T.rIdx = S.RTab.indexOf(ww._radios, T.r)
        T.go = H.padOn(ww) and H.focusEl(ww, "radio:tab:" .. tostring(T.rIdx))
    end)
    H.tapQ("ww", "A", function() return T.go and not T.off end)
    H.step(3, function()
        H.padOff()
        if T.off or not T.go then return end
        local l = H.namings()
        Q.check(l == getText("IGUI_ItemType_Radio"), T.L .. " (pad): A on the radio's tab, the World tab reads Radio again", "tab " .. H.s(l))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R10 three ham sets
-- the map's rule for a name's tab: the words it shares at its end with another name (two or more) dropped, both
-- keeping a word of their own; two cut alike keep their whole names
function H.words(s)
    local out, i = {}, 1
    while true do
        local j = string.find(s, " ", i, true)
        local w = j and string.sub(s, i, j - 1) or string.sub(s, i)
        if w ~= "" then out[#out + 1] = w end
        if not j then break end
        i = j + 1
    end
    return out
end
function H.expectShort(names)
    local words = {}
    for _, n in ipairs(names) do
        words[n] = H.words(n)
    end
    local out = {}
    for _, a in ipairs(names) do
        local best = 0
        for _, b in ipairs(names) do
            if a ~= b then
                local wa, wb, k = words[a], words[b], 0
                while k < #wa - 1 and k < #wb - 1 and wa[#wa - k] == wb[#wb - k] do k = k + 1 end
                if k > best then best = k end
            end
        end
        if best >= 2 then
            local s = words[a][1]
            for i = 2, #words[a] - best do s = s .. " " .. words[a][i] end
            out[a] = s
        else
            out[a] = a
        end
    end
    local used = {}
    for _, a in ipairs(names) do used[out[a]] = (used[out[a]] or 0) + 1 end
    for _, a in ipairs(names) do if used[out[a]] > 1 then out[a] = a end end
    return out
end
function C.r10()
    local T = { L = "R10 three ham sets" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        T.a = H.place("ham_civilian", H.ringSq(1))
        T.b = H.place("ham_army", H.ringSq(2))
        T.c = H.place("ham_makeshift", H.ringSq(3))
        if not (T.a and T.b and T.c) then T.off = true; Q.skip(T.L, "three ham sets could not be placed"); return end
        for _, o in ipairs({ T.a, T.b, T.c }) do H.prep(o, { batt = 0.8, on = false }) end
    end)
    H.wwShow(T, "a")
    H.step(2, function()
        if T.off then return end
        local ww = RT.ww()
        local items = S.RTab.tabItems(ww._radios)
        local names, got = {}, {}
        for i, e in ipairs(ww._radios) do
            local n = H.devName(e.radioInstance)
            n = n:match("^[^%.]+%.(.+)$") or n
            names[#names + 1] = n
            got[n] = items[i] and items[i].label
        end
        local want = H.expectShort(names)
        local bad = {}
        for _, n in ipairs(names) do if got[n] ~= want[n] then bad[#bad + 1] = n .. ": " .. H.s(got[n]) .. " (want " .. want[n] .. ")" end end
        local shown = {}
        for _, n in ipairs(names) do shown[#shown + 1] = H.s(got[n]) end
        Q.check(#names == 3 and #bad == 0, T.L .. ": the tabs drop the words the names share at their end, whole names where cutting collides",
            "names " .. H.list(names) .. "; tabs " .. H.list(shown) .. (#bad > 0 and ("; wrong " .. H.list(bad)) or ""))
        T.labels = shown
        H.stripRecOn()
    end)
    H.halfOnQ(T)
    Q.waitMs(600)
    H.step(2, function()
        if T.off then return end
        if not T.half then Q.skip(T.L .. ": the tabs at the half card", "the drawer could not be held in to the half card"); return end
        local drawn = S.stripLabels or {}
        local bad = {}
        for _, s in ipairs(drawn) do
            local whole = false
            for _, l in ipairs(T.labels or {}) do if s == l then whole = true end end
            local cut = string.sub(s, -3) == "..."
            local ofOne = false
            if cut then for _, l in ipairs(T.labels or {}) do if string.sub(l, 1, #s - 3) == string.sub(s, 1, #s - 3) then ofOne = true end end end
            if not whole and not (cut and ofOne) then bad[#bad + 1] = s end
        end
        Q.check(#drawn > 0 and #bad == 0, T.L .. ": at the half card each tab is whole or cut with \"...\"", "drawn " .. H.s(H.list(drawn)) .. "; the tabs " .. H.list(T.labels or {}))
        H.stripRecOff()
    end)
    H.shotQ(function() if T.off or not T.half then return nil end; return "rd_ham_tabs_half_" .. H.sizeTag() end, "three ham sets' tabs at the half card")
    H.caseEnd(T.L)
end

-- ===================================================================== R44 a ham set on its battery and on the grid
function C.r44()
    local T = { L = "R44 a ham set placed on its battery and on the grid" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        T.dev = H.place("ham_civilian", H.ringSq(1))
        if not T.dev then T.off = true; Q.skip(T.L, "no ham set could be placed"); return end
        H.setGrid(false)
        H.prep(T.dev, { batt = 0.7, on = true, vol = 0.2 })
        if not H.usesBatt(T.dev) then H.note(T.L .. ": the placed civilian ham's data says it uses no battery: the BAT leg reads its mains") end
    end)
    H.wwShow(T, "dev")
    H.faceShotQ(T, "ww", "dev")
    Q.waitMs(700)
    H.step(2, function()
        if T.off then return end
        local ww = RT.ww()
        local g = H.twGlass(ww)
        local row = H.fillRow(ww, "fill:radio:batt")
        local pw = H.powered(T.dev)
        if H.usesBatt(T.dev) then
            Q.check(g ~= nil and g.batLabel == (pw and H.tr("UI_ZeD_Radio_Ac") or H.tr("UI_ZeD_Radio_Bat")), T.L .. ": off the grid the glass reads BAT",
                "glass " .. H.s(g and g.batLabel) .. " " .. tostring(g and g.batt) .. " bars; the game: battery " .. tostring(H.battOn(T.dev)) .. " at " .. H.n2(H.charge(T.dev)) .. ", power nearby " .. tostring(pw))
            Q.check(row ~= nil, T.L .. ": the Power block has its battery row", "row " .. H.s(row and row.label) .. " " .. H.s(row and row.value))
        else
            Q.skip(T.L .. ": the glass on its battery", "the placed set's data uses no battery")
        end
        Q.check(H.hit(ww, "battery") == nil, T.L .. " (B1): the ham's face has no battery key (as R31: no ZeD way to change it)", H.list(H.hitIds(ww), 16))
        H.setGrid(true)
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        local g = H.twGlass(RT.ww())
        local pw = H.powered(T.dev)
        Q.check((not pw) or (g ~= nil and g.batLabel == H.tr("UI_ZeD_Radio_Ac")), T.L .. ": on the grid the glass reads AC",
            "glass " .. H.s(g and g.batLabel) .. "; the game's power nearby " .. tostring(pw) .. ", grid on his square " .. tostring(H.gridHere()))
        if not pw then H.note(T.L .. ": the grid does not reach the ham's square here: the AC leg says what the game says") end
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R45 the army ham's presets and tuning
function C.r45()
    local T = { L = "R45 the army ham's presets" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        T.dev = H.place("ham_army", H.ringSq(1))
        if not T.dev then T.off = true; Q.skip(T.L, "no army ham could be placed"); return end
        H.prep(T.dev, { batt = 0.9, on = true, vol = 0.2, ch = 100000, presets = { { "One", 90000 }, { "Two", 92000 } } })
    end)
    H.wwShow(T, "dev")
    H.faceShotQ(T, "ww", "dev")
    H.step(2, function()
        if T.off then return end
        local ww = RT.ww()
        if not H.hit(ww, "p3") then T.off = true; Q.skip(T.L, "no preset keys on the face (" .. H.list(H.hitIds(ww)) .. ")"); return end
        T.go = H.padOn(ww) and H.focusEl(ww, "radio:tw:p3")
    end)
    H.holdAQ("ww", 800, function() return T.go and not T.off end)
    H.step(2, function()
        H.padOff()
        if T.off or not T.go then return end
        local pr = H.presets(T.dev)
        Q.check(#pr == 3 and pr[3].freq == 100000, T.L .. " (pad): A held on P3 stores the station on preset 3", "the game's list " .. H.presetText(T.dev))
        pcall(function() H.dd(T.dev):setChannel(90000) end)
        H.click(RT.ww(), "p3", nil, T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.ch(T.dev) == 100000, T.L .. " (mouse): P3 pressed recalls it", "the game's channel " .. H.mhz(H.ch(T.dev)))
        local max = H.maxPresets(T.dev) or 10
        T.max = max
        local list = {}
        for i = 1, max do list[#list + 1] = { "Stage " .. i, 30000 + i * 200 } end
        H.prep(T.dev, { presets = list, ch = 140000 })
        if H.hit(RT.ww(), "mem") then H.click(RT.ww(), "mem", nil, T.L); T.mem = true end
    end)
    H.step(3, function()
        if T.off then return end
        if T.mem then
            Q.check(#H.presets(T.dev) == T.max and H.flash(T.dev) == H.tr("UI_ZeD_Radio_MemFull"), T.L .. " (mouse): MEM at the game's getMaxPresets flashes MEMORY FULL",
                #H.presets(T.dev) .. " of " .. tostring(T.max) .. "; flash " .. H.s(H.flash(T.dev)))
        end
        H.rclick(RT.ww(), "p3")
    end)
    H.step(3, function()
        if T.off then return end
        local pr = H.presets(T.dev)
        Q.check(#pr == T.max and pr[3] and pr[3].freq == 140000, T.L .. " (mouse): a right-click on P3 with the list full stores over preset 3, adding nothing",
            #pr .. " of " .. tostring(T.max) .. "; preset 3 " .. H.mhz(pr[3] and pr[3].freq))
        pcall(function() H.dd(T.dev):setChannel(100000) end)
        local ww = RT.ww()
        ww._radioPadTurn = nil
        T.go2 = H.padOn(ww) and H.focusEl(ww, "radio:tw:tune")
    end)
    H.tapQ("ww", "A", function() return T.go2 and not T.off end)
    for i = 1, 11 do
        H.dirQ("ww", "right", function() return T.go2 and not T.off end)
        if i == 10 then H.step(1, function() T.c10 = H.ch(T.dev) end) end
    end
    H.step(2, function()
        if T.off or not T.go2 then H.padOff(); return end
        local d = (H.ch(T.dev) or 0) - (T.c10 or 0)
        Q.check(d == 5000, T.L .. " (pad): held, the D-pad tunes a ham set 25 steps a click after 10 quick ones", H.mhz(T.c10) .. " -> " .. H.mhz(H.ch(T.dev)) .. " (" .. d .. " kHz)")
    end)
    H.tapQ("ww", "B", function() return T.go2 and not T.off end)
    H.step(2, function() H.padOff() end)
    H.caseEnd(T.L)
end

-- ===================================================================== R46 a ham set's narrow face
function C.r46()
    local T = { L = "R46 a ham set at the half card" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        T.dev = H.place("ham_makeshift", H.ringSq(1))
        if not T.dev then T.off = true; Q.skip(T.L, "no ham set could be placed"); return end
        H.prep(T.dev, { batt = 0.8, on = true })
    end)
    H.wwShow(T, "dev")
    H.faceShotQ(T, "ww", "dev")
    H.step(2, function()
        if T.off then return end
        T.pid0 = H.face(RT.ww())
        T.ids0 = H.hitIds(RT.ww())
        table.sort(T.ids0)
    end)
    H.halfOnQ(T)
    Q.waitMs(800)
    H.step(2, function()
        if T.off then return end
        if not T.half then Q.skip(T.L, "the drawer could not be held in to the half card"); return end
        local pid = H.face(RT.ww())
        local nPid = nil
        pcall(function() nPid = S.TW.narrowOf(S.TW.basePid(T.pid0)) end)
        local ids = H.hitIds(RT.ww())
        table.sort(ids)
        Q.check(nPid ~= nil and pid == nPid and table.concat(ids, ",") == table.concat(T.ids0, ","), T.L .. ": at the half card the set draws its narrow face with the same controls",
            "face " .. tostring(T.pid0) .. " -> " .. tostring(pid) .. " (its narrow face " .. tostring(nPid) .. "); controls " .. H.list(T.ids0, 14) .. " -> " .. H.list(ids, 14))
    end)
    H.shotQ(function() if T.off or not T.half then return nil end; return "rd_ham_makeshift_narrow_" .. H.sizeTag() end, "the makeshift ham's narrow face at the half card")
    H.caseEnd(T.L)
end

-- ===================================================================== R23 the CD player (B6)
function C.r23()
    local T = { L = "R23 the CD player" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        T.dev = H.giveRadio("Base.CDplayer", { batt = 0.8, on = true, vol = 0.2 })
        H.hold(T.dev, "p")
    end)
    H.showQ(T, "cw", "dev")
    H.faceShotQ(T, "cw", "dev")
    Q.waitMs(700)
    H.step(2, function()
        if T.off then return end
        local cw = RT.cw()
        local half = ZeD.T.px(220)
        local hc = S.RTab.halfCard(cw, half)
        Q.check(hc and H.drawerW(cw) <= half + 1 and H.hit(cw, "tune") == nil and H.hit(cw, "battery") ~= nil, T.L .. ": held, the half card in the Character window, no tuner, its battery on the face",
            "the half card " .. tostring(hc) .. ", drawer " .. H.drawerW(cw) .. " px (half " .. half .. "); controls " .. H.list(H.hitIds(cw), 14))
        local d = H.fill(cw)
        local nt = H.noTransmit(T.dev)
        local range = H.fillRow(cw, "fill:radio:range")
        local heard = d and #(d.heard or {}) or 0
        local chans = d and #(d.presets or {}) or 0
        Q.check(not (nt and (range ~= nil or heard > 0 or chans > 0)), T.L .. " (B6): a NoTransmit set shows no Channels, Heard or Frequency range (the game hides General, Signal and Channel)",
            "the game's NoTransmit " .. tostring(nt) .. "; drawn: " .. chans .. " Channels rows, " .. heard .. " Heard rows, range " .. H.s(range and range.value))
        H.unhold(T.dev)
        pcall(function() local c = T.dev:getContainer(); if c then c:Remove(T.dev) end end)
        pcall(function() H.ringSq(1):AddWorldInventoryItem(T.dev, 0.5, 0.5, 0) end)
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        H.refreshList("ww")
        local ww = RT.ww()
        for _, e in ipairs((ww and ww._radios) or {}) do
            local pid = nil
            pcall(function() pid = S.R.plateId(e.radioInstance) end)
            if pid == "cd_player" then T.set = e.radioInstance end
        end
        if not T.set then T.off = true; Q.skip(T.L .. ": the CD player on the floor in the World window", "dropped on the floor it stands as no set the World window lists") end
    end)
    H.wwShow(T, "set")
    H.step(2, function()
        if T.off then return end
        local ww = RT.ww()
        Q.check(S.RTab.halfCard(ww, ZeD.T.px(220)) and H.isHalf(ww), T.L .. ": on the floor, the half card in the World window too",
            "the half card " .. tostring(S.RTab.halfCard(ww, ZeD.T.px(220))) .. ", drawer " .. H.drawerW(ww) .. " px")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R24 a TV on the grid (B10)
function C.r24()
    local T = { L = "R24 a TV on the grid" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        T.tv = H.place("tv_black", H.ringSq(1))
        if not T.tv then T.off = true; Q.skip(T.L, "no TV could be placed"); return end
        H.prep(T.tv, { on = false, vol = 0.2, ch = 200 })
    end)
    H.wwShow(T, "tv")
    H.faceShotQ(T, "ww", "tv")
    Q.waitMs(700)
    H.step(2, function()
        if T.off then return end
        local row = H.fillRow(RT.ww(), "fill:radio:mains")
        local pw = H.powered(T.tv)
        Q.check(pw and row ~= nil and row.label == getText("IGUI_RadioPowerNearby"), T.L .. ": the Power block reads Power nearby",
            "row " .. H.s(row and row.label) .. "; the game's canBePoweredHere " .. tostring(pw) .. ", grid on his square " .. tostring(H.gridHere()))
        if not pw then T.off = true; return end
        H.click(RT.ww(), "power", nil, T.L)
        local st = nil
        pcall(function() st = S.R.read(T.tv) end)
        pcall(function() T.air0 = S.R.air(st) end)
    end)
    Q.waitMs(700)
    H.step(2, function()
        if T.off then return end
        local st, air = nil, nil
        pcall(function() st = S.R.read(T.tv); air = S.R.air(st) end)
        local okAir = air == "picture" or air == "signoff" or air == "standby" or air == "bars"
        Q.check(H.on(T.tv) and okAir, T.L .. " (mouse): power on, the screen shows the station: its picture, its sign-off card or standby",
            "the game's on " .. tostring(H.on(T.tv)) .. "; the screen " .. H.s(T.air0) .. " at once, " .. H.s(air) .. " after 0.7 s (the map wrote snow for 0.45 s on power on: snow follows a channel change only)")
        local ww = RT.ww()
        T.go = H.padOn(ww) and H.focusEl(ww, "radio:tw:power")
    end)
    H.tapQ("ww", "A", function() return T.go and not T.off end)
    H.step(2, function()
        H.padOff()
        if T.off or not T.go then return end
        Q.check(not H.on(T.tv), T.L .. " (pad): A on power turns it off", "the game's on " .. tostring(H.on(T.tv)))
        H.countOn()
    end)
    Q.waitMs(2000)
    H.step(2, function()
        local n = H.countOff()
        if T.off then return end
        H.note(T.L .. " (B10): with the World window's Radio tab open its list was rebuilt " .. n .. " times in 2 s (the Character window's: every 500 ms); a cost, not a behavior")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R25 a TV with no power
function C.r25()
    local T = { L = "R25 a TV with no power" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        H.setGrid(false)
        T.tv = H.place("tv_black", H.ringSq(1))
        if not T.tv then T.off = true; Q.skip(T.L, "no TV could be placed"); return end
        H.prep(T.tv, { on = false, vol = 0.2, ch = 200 })
    end)
    H.wwShow(T, "tv")
    Q.waitMs(1200)
    H.step(2, function()
        if T.off then return end
        local row = H.fillRow(RT.ww(), "fill:radio:mains")
        local pw = H.powered(T.tv)
        if pw then T.off = true; Q.skip(T.L, "the TV still has power with the grid off here (a generator or the shut-off day)"); return end
        Q.check(row ~= nil and row.label == getText("IGUI_RadioRequiresPowerNearby"), T.L .. ": the Power block reads Requires power nearby", "row " .. H.s(row and row.label))
        T.game = H.gameValid("ToggleOnOff", T.tv)
        H.click(RT.ww(), "power", nil, T.L)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(not H.on(T.tv) and T.game == false, T.L .. " (mouse): power with no power nearby does nothing, as the game refuses it",
            "the game's on " .. tostring(H.on(T.tv)) .. ", its isValidToggleOnOff " .. tostring(T.game))
        T.gen = H.mkGen(H.ringSq(3) or H.ringSq(2))
        if not T.gen then T.off = true; Q.skip(T.L .. ": a generator in range", "no generator could be placed") end
    end)
    H.wait(6000, function() return T.off or H.powered(T.tv) == true end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": a running generator beside it gives the TV power (the game's canBePoweredHere)", "power nearby " .. tostring(H.powered(T.tv))) then return end
        local ww = RT.ww()
        T.go = H.padOn(ww) and H.focusEl(ww, "radio:tw:power")
    end)
    H.tapQ("ww", "A", function() return T.go and not T.off end)
    H.step(3, function()
        H.padOff()
        if T.off or not T.go then return end
        Q.check(H.on(T.tv), T.L .. " (pad): with the generator running power turns it on", "the game's on " .. tostring(H.on(T.tv)))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R26 the TV's channels
function C.r26()
    local T = { L = "R26 the TV's channels" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        T.tv = H.place("tv_black", H.ringSq(1))
        T.ant = H.place("tv_antique", H.ringSq(2))
        if not (T.tv and T.ant) then T.off = true; Q.skip(T.L, "two TVs could not be placed"); return end
        H.prep(T.tv, { on = true, vol = 0.1, ch = 200 })
        H.prep(T.ant, { on = true, vol = 0.1, ch = 200 })
    end)
    H.wwShow(T, "tv")
    H.step(2, function()
        if T.off then return end
        if not H.on(T.tv) then T.off = true; Q.skip(T.L, "the TV has no power here"); return end
        local seen, freqs = {}, {}
        for _ = 1, 12 do
            H.click(RT.ww(), "chup", nil, T.L)
            seen[#seen + 1] = tostring(H.stopNo(H.ch(T.tv)))
            freqs[#freqs + 1] = tostring(H.ch(T.tv))
        end
        Q.check(table.concat(seen, ",") == "3,4,5,6,7,8,9,10,11,12,13,2", T.L .. " (mouse): CH+ from Triple-N walks the stops 3 to 13 and wraps to 2",
            "stops " .. H.list(seen, 12) .. "; the game's channels " .. H.list(freqs, 12) .. " (RadioData: 200, 201, 203-210, then 211 and 212 have no station)")
        pcall(function() H.dd(T.tv):setChannel(211) end)
    end)
    Q.waitMs(700)
    H.step(2, function()
        if T.off then return end
        local air = nil
        pcall(function() air = S.R.air(S.R.read(T.tv)) end)
        Q.check(air == "bars", T.L .. ": stop 12 (no station) shows the bars", "the screen " .. H.s(air) .. " on " .. tostring(H.ch(T.tv)) .. " (station " .. H.s(H.stName(H.ch(T.tv))) .. ")")
    end)
    H.wwShow(T, "ant")
    H.faceShotQ(T, "ww", "ant")
    H.step(2, function()
        if T.off then return end
        local ww = RT.ww()
        if not H.hit(ww, "channel") then T.off = true; Q.skip(T.L .. ": the antique dial", "no channel dial on its face (" .. H.list(H.hitIds(ww)) .. ")"); return end
        T.go = H.padOn(ww) and H.focusEl(ww, "radio:tw:channel")
    end)
    H.tapQ("ww", "A", function() return T.go and not T.off end)
    H.dirQ("ww", "left", function() return T.go and not T.off end)
    H.step(2, function() if not T.off then T.a1 = H.ch(T.ant); pcall(function() H.dd(T.ant):setChannel(212) end) end end)
    H.dirQ("ww", "right", function() return T.go and not T.off end)
    H.step(2, function() if not T.off then T.a2 = H.ch(T.ant) end end)
    H.dirQ("ww", "left", function() return T.go and not T.off end)
    H.step(2, function()
        if T.off or not T.go then H.padOff(); return end
        Q.check(T.a1 == 200 and T.a2 == 212 and H.ch(T.ant) == 211, T.L .. " (pad): the antique dial grabbed stops at stop 2 and at 13 and turns between them",
            "down from 200: " .. tostring(T.a1) .. "; up from 212: " .. tostring(T.a2) .. "; down from 212: " .. tostring(H.ch(T.ant)))
    end)
    H.tapQ("ww", "B", function() return T.go and not T.off end)
    H.step(2, function() H.padOff() end)
    H.caseEnd(T.L)
end

-- ===================================================================== R27 the screen against the schedule
function H.scriptChannel(freq)
    local c = nil
    pcall(function()
        local list = getZomboidRadio():getScriptManager():getChannelsList()
        for i = 0, list:size() - 1 do local ch = list:get(i); if ch:GetFrequency() == freq then c = ch end end
    end)
    return c
end
function C.r27()
    local T = { L = "R27 the TV's screen against the schedule", bad = {}, seen = {} }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        T.tv = H.place("tv_black", H.ringSq(1))
        if not T.tv then T.off = true; Q.skip(T.L, "no TV could be placed"); return end
        H.prep(T.tv, { on = true, vol = 0.1, ch = 200 })
        if not H.on(T.tv) then T.off = true; Q.skip(T.L, "the TV has no power here") end
    end)
    -- (run 1, 4K: every channel read snow. The TV was never shown, so the screen's channel memory moved only on this
    -- script's one read 600 ms later, and a change first seen reads snow for 450 ms. The TV is shown now, its face
    -- reading each frame as a player sees it, and the change is also seen at once here)
    H.wwShow(T, "tv")
    for i = 1, 10 do
        H.step(2, function()
            if T.off then return end
            local s = H.stops()[i]
            T.cur = s
            if s then pcall(function() H.dd(T.tv):setChannel(s.freq) end) end
            pcall(function() S.R.air(S.R.read(T.tv)) end)
        end)
        Q.waitMs(600)
        H.step(1, function()
            if T.off or not T.cur then return end
            local s = T.cur
            local air = nil
            pcall(function() air = S.R.air(S.R.read(T.tv)) end)
            local ch = H.scriptChannel(s.freq)
            local airing, script = nil, nil
            if ch then pcall(function() airing = ch:getAiringBroadcast() ~= nil; script = ch:getCurrentScript() ~= nil end) end
            local want = (ch == nil and "?") or (airing and "picture") or ((not script) and "standby") or "signoff"
            T.seen[#T.seen + 1] = string.format("%02d", s.number) .. " " .. H.s(air) .. "/" .. want
            if ch and air ~= want and not (air == "picture" and want == "signoff") then T.bad[#T.bad + 1] = string.format("%02d", s.number) end
        end)
    end
    H.step(2, function()
        if T.off then return end
        Q.check(#T.bad == 0, T.L .. ": each channel's screen shows what its schedule airs now (getAiringBroadcast: the picture; between broadcasts the sign-off; done: standby)",
            "ZeD/the game at " .. H.n1(getGameTime():getTimeOfDay()) .. "h: " .. H.list(T.seen, 10) .. (#T.bad > 0 and ("; off: " .. H.list(T.bad)) or "")
            .. " (a picture between broadcasts is allowed while lines were heard in the last 9 s)")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R28 VHS
function C.r28()
    local T = { L = "R28 VHS" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        T.tv = H.place("tv_black", H.ringSq(1))
        if not T.tv then T.off = true; Q.skip(T.L, "no TV could be placed"); return end
        H.prep(T.tv, { on = true, vol = 0.1, ch = 200 })
        T.ret = H.give("Base.VHS_Retail")
        T.home = H.give("Base.VHS_Home")
        T.r1 = T.ret and H.mediaReady(T.ret, "Retail-VHS")
        T.r2 = T.home and H.mediaReady(T.home, "Home-VHS")
        if not (H.on(T.tv) and T.r1) then T.off = true; Q.skip(T.L, "the TV has no power or the tape has no recorded media") end
    end)
    H.wwShow(T, "tv")
    H.step(2, function() if not T.off then S.lastCtx = nil; H.click(RT.ww(), "slot", nil, T.L) end end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.menuOpen() and H.menuOpt(T.ret) ~= nil and (not T.r2 or H.menuOpt(T.home) ~= nil), T.L .. " (mouse): the empty slot lists both tapes he carries",
            "the list: " .. H.s(H.list(H.menuNames())))
        if not H.menuPick(T.ret) then T.off = true end
        H.menuClose()
    end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off then return end
        Q.check(H.media(T.tv), T.L .. ": the pick puts the tape in", "the game's hasMedia " .. tostring(H.media(T.tv)) .. "; queued " .. tostring(T.qKinds))
        H.click(RT.ww(), "play", nil, T.L)
    end)
    Q.waitMs(2200)
    H.step(2, function()
        if T.off then return end
        local st, txt = nil, nil
        pcall(function() st = S.R.read(T.tv); txt = S.R.hms(st.clockMs) end)
        Q.check(H.playing(T.tv) and txt ~= nil and string.match(txt, "^%d+:%d%d:%d%d$") ~= nil, T.L .. ": play runs the tape and the counter reads H:MM:SS",
            "the game's isPlayingMedia " .. tostring(H.playing(T.tv)) .. "; counter " .. H.s(txt))
        T.n0 = H.count("Base.VHS_Retail")
        local ww = RT.ww()
        T.go = H.padOn(ww) and H.focusEl(ww, "radio:tw:eject")
    end)
    H.tapQ("ww", "A", function() return T.go and not T.off end)
    H.step(2, function() H.padOff() end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off or not T.go then return end
        Q.check(not H.media(T.tv) and H.count("Base.VHS_Retail") == (T.n0 or 0) + 1, T.L .. " (pad): A on eject takes the tape out", "hasMedia " .. tostring(H.media(T.tv)) .. ", tapes " .. tostring(T.n0) .. " -> " .. H.count("Base.VHS_Retail"))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R29 headphones on a TV (B2)
function C.r29()
    local T = { L = "R29 headphones on a TV" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        T.tv = H.place("tv_black", H.ringSq(1))
        if not T.tv then T.off = true; Q.skip(T.L, "no TV could be placed"); return end
        H.prep(T.tv, { on = true, vol = 0.1, ch = 200 })
        T.hp = H.give("Base.Headphones")
    end)
    H.wwShow(T, "tv")
    H.step(2, function()
        if T.off then return end
        if not H.hit(RT.ww(), "phones") then Q.check(true, T.L .. " (B2): the TV's face has no headphone jack", H.list(H.hitIds(RT.ww()))); T.off = true; return end
        H.click(RT.ww(), "phones", nil, T.L)
    end)
    H.step(3, function() if not T.off then T.k = H.qkinds() end end)
    H.waitQ(T, 15000)
    H.step(2, function()
        if T.off then return end
        local port = H.portable(T.tv)
        Q.check((H.phones(T.tv) or -1) < 0, T.L .. " (B2): ZeD puts no headphones on a TV (the game offers its headphone box on portable non-TV sets only, RWMVolume)",
            "queued " .. tostring(T.k) .. "; the TV's headphone type " .. tostring(H.phones(T.tv)) .. ", headphones on him " .. H.count("Base.Headphones") .. "; TvBlack portable " .. tostring(port))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R30 two sets on one square (B4)
-- which set the game's queued action of type ty works on: its deviceData against each set's ("the radio", "the TV")
function H.qTarget(ty, T)
    for _, a in ipairs(H.queue()) do
        if a.Type == ty then
            local d = a.deviceData
            if d == nil then return "no set" end
            if d == H.dd(T.r) then return "the radio" end
            if d == H.dd(T.tv) then return "the TV" end
            return "another set"
        end
    end
    return "nothing queued"
end
function C.r30()
    local T = { L = "R30 a TV and a ValuTech on one square" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        local sq = H.ringSq(1)
        T.tv = H.place("tv_black", sq)
        T.r = H.place("radio_black", sq)
        if not (T.tv and T.r) then T.off = true; Q.skip(T.L, "two sets could not be placed on one square"); return end
        H.prep(T.tv, { on = true, vol = 0.1, ch = 200 })
        H.prep(T.r, { batt = false, on = false })
        T.batt = H.battery(0.8)
        T.tape = H.give("Base.VHS_Retail")
        T.rec = T.tape and H.mediaReady(T.tape, "Retail-VHS")
    end)
    H.wwShow(T, "r")
    H.step(2, function()
        if T.off then return end
        if not (H.usesBatt(T.r) and H.hit(RT.ww(), "battery")) then T.noBatt = true; Q.skip(T.L .. ": a battery through the radio's tab", "the placed ValuTech uses no battery here or has no battery key"); return end
        T.tvB = H.battOn(T.tv)
        H.click(RT.ww(), "battery", nil, T.L)
    end)
    -- (the key acts on the release, the next drawn frame: the action is read off the game's queue once it is there.
    -- Run 1 read the queue a frame too soon and saw nothing)
    H.wait(1500, function() return T.off or T.noBatt or H.qcount("ISDeviceBatteryAction") > 0 end, function(ok)
        if T.off or T.noBatt then return end
        T.bAim = H.qTarget("ISDeviceBatteryAction", T)
        T.bQueued = ok
    end)
    H.waitQ(T, 15000)
    H.step(2, function()
        if T.off or T.noBatt then return end
        Q.check(H.battOn(T.r) == true and not H.onHim(T.batt), T.L .. " (B4): the battery pressed on the radio's tab goes into the radio, not the TV on its square",
            "the game's battery action queued " .. tostring(T.bQueued) .. ", aimed at " .. tostring(T.bAim) .. "; the radio's battery in " .. tostring(H.battOn(T.r))
            .. "; the TV's " .. tostring(T.tvB) .. " -> " .. tostring(H.battOn(T.tv)) .. "; the battery still on him " .. tostring(H.onHim(T.batt)) .. "; queued " .. tostring(T.qKinds))
    end)
    H.wwShow(T, "tv")
    H.step(2, function()
        if T.off then return end
        if not (T.rec and H.on(T.tv)) then T.noTape = true; Q.skip(T.L .. ": a tape through the TV's tab", "no power or no recorded tape"); return end
        S.lastCtx = nil
        T.rM = H.media(T.r)
        H.click(RT.ww(), "slot", nil, T.L)
    end)
    H.step(3, function()
        if T.off or T.noTape then return end
        if not H.menuPick(T.tape) then T.noTape = true; Q.check(false, T.L .. ": the TV's slot lists the tape", "the list: " .. H.s(H.list(H.menuNames()))) end
        H.menuClose()
    end)
    H.wait(1500, function() return T.off or T.noTape or H.qcount("ISDeviceMediaAction") > 0 end, function()
        if T.off or T.noTape then return end
        T.mAim = H.qTarget("ISDeviceMediaAction", T)
    end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off or T.noTape then return end
        Q.check(H.media(T.tv) and H.media(T.r) == T.rM, T.L .. " (B4): the tape picked on the TV's tab goes into the TV, not the radio on its square",
            "the game's media action aimed at " .. tostring(T.mAim) .. "; the TV's media " .. tostring(H.media(T.tv)) .. "; the radio's " .. tostring(T.rM) .. " -> " .. tostring(H.media(T.r)) .. "; queued " .. tostring(T.qKinds))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R52 the pad's landing (B8)
function C.r52leg(T, which, key, want, label)
    H.step(2, function()
        if T.off then return end
        local w = H.win(which)
        if w then w._gpFocusedRadioCtl = nil end
    end)
    H.showQ(T, which, key)
    H.step(4, function()
        if T.off then return end
        local w = H.win(which)
        local first = H.padStops(w)[1]
        local fid = first and first.id
        local ok = false
        for _, id in ipairs(want) do if fid == id then ok = true end end
        -- (run 1, 4K: the TV's first stop was power but the tab's seed id read radio:tab:1, written in a frame before
        -- the face drew. Nothing reads that seed (FocusManager lands on the zone's first stop): it is reported only)
        Q.check(ok, label .. ": the pad lands on its first stop, the set's primary control (" .. H.list(want) .. ")",
            "first stop " .. tostring(fid) .. " (the tab's seed id " .. tostring(w and w._gpFocusedRadioCtl) .. ", read by nothing); stops " .. H.stopIds(w))
    end)
end
function C.r52()
    local T = { L = "R52 the pad's landing" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        T.tv = H.place("tv_black", H.ringSq(1))
        if T.tv then H.prep(T.tv, { on = false, vol = 0.1, ch = 200 }) end
        T.r = H.giveRadio("Base.RadioBlack", { batt = 0.8, on = false })
        T.wk = H.giveRadio("Base.WalkieTalkie2", { batt = 0.8, on = true, vol = 0.3 })
        H.hold(T.r, "p")
    end)
    C.r52leg(T, "cw", "r", { "radio:tw:power" }, T.L .. " on a ValuTech")
    H.step(2, function() if T.off then return end; H.unhold(T.r); H.hold(T.wk, "p") end)
    C.r52leg(T, "cw", "wk", { "radio:tw:vol" }, T.L .. " (B8) on a walkie")
    H.step(2, function()
        if T.off then return end
        local cw = RT.cw()
        T.go = H.padOn(cw) and H.focusEl(cw, "radio:tw:vol")
        T.v0 = H.vol(T.wk)
    end)
    H.tapQ("cw", "A", function() return T.go and not T.off end)
    H.step(2, function() if not T.off then T.g = H.grabbed(RT.cw(), "radio:tw:vol") end end)
    H.dirQ("cw", "up", function() return T.go and not T.off end)
    H.step(2, function() if not T.off then T.v1 = H.vol(T.wk) end end)
    H.tapQ("cw", "B", function() return T.go and not T.off end)
    H.step(3, function()
        if T.off or not T.go then H.padOff(); return end
        local cw = RT.cw()
        Q.check(T.g and math.abs((T.v1 or 0) - (T.v0 or 0) - 0.1) < 0.001 and not H.grabbed(cw, "radio:tw:vol") and H.focusedId(cw) == "radio:tw:vol",
            T.L .. ": on the walkie's VOL, A grabs, the D-pad turns, B lets go and the focus stays",
            "grabbed " .. tostring(T.g) .. ", the game's volume " .. H.n2(T.v0) .. " -> " .. H.n2(T.v1) .. ", held after B " .. tostring(cw and cw._knobGrab) .. ", focus " .. tostring(H.focusedId(cw)))
        H.padOff()
    end)
    -- (the TV last: no TV placed skips only this leg)
    C.r52leg(T, "ww", "tv", { "radio:tw:power", "radio:tw:volpwr" }, T.L .. " on a TV")
    H.caseEnd(T.L)
end

-- ===================================================================== R54 Lite (B14)
function C.r54leg(T, which, key, label)
    H.showQ(T, which, key)
    H.faceShotQ(T, which, key)
    H.step(2, function()
        if T.off then return end
        local w = H.win(which)
        local stores = {}
        for _, id in ipairs(H.hitIds(w)) do if string.find(id, "^p%d$") or id == "mem" or id == "lamp" then stores[#stores + 1] = id end end
        Q.check(H.isPlain(w) and #stores == 0 and w._radioCanPop ~= true and w._radioFullZone == nil, label .. ": the plain card, no preset keys, MEM or lamp, no pop-out button",
            "plain " .. tostring(H.isPlain(w)) .. "; controls " .. H.list(H.hitIds(w), 16) .. "; the pop-out " .. tostring(w and w._radioCanPop))
        T.stores = (T.stores or 0) + #stores
    end)
end
function C.r54()
    local T = { L = "R54 Lite" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        if not H.lite(true) then T.off = true; Q.skip(T.L, "no Lite setting"); return end
        T.r = H.giveRadio("Base.RadioBlack", { batt = 0.8, on = true, vol = 0.2, ch = 90000, presets = { { "One", 90000 }, { "Two", 101200 } } })
        T.wk = H.giveRadio("Base.WalkieTalkie5", { batt = 0.8, on = true, vol = 0.2 })
        T.tv = H.place("tv_black", H.ringSq(1))
        if T.tv then H.prep(T.tv, { on = true, vol = 0.1, ch = 200 }) end
        H.hold(T.r, "p")
    end)
    C.r54leg(T, "cw", "r", T.L .. " on a ValuTech")
    Q.waitMs(700)
    -- (run 1: the row was found but below the tab's view, where a click does nothing: the body is scrolled to it the
    -- way the wheel scrolls it, one notch a frame, then the row is clicked where it is drawn)
    H.wait(4000, function()
        if T.off then return true end
        local cw = RT.cw()
        local t, z = H.tw(cw), H.fillZone(cw, "fill:radio:ch:2")
        if z and H.inView(t, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)) then return true end
        local sc = cw and cw._radioScroll
        if sc and sc.visible then pcall(function() sc:handleMouseWheel(1) end) end
        return false
    end, function(ok)
        if T.off then return end
        local cw = RT.cw()
        local z = H.fillZone(cw, "fill:radio:ch:2")
        T.zOk, T.inV = z ~= nil, ok
        if z and ok then H.clickAt(cw, z) end
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(T.zOk and T.inV and H.ch(T.r) == 101200, T.L .. " (mouse): a Channels row still tunes to its channel",
            "row found " .. tostring(T.zOk) .. ", in the tab's view " .. tostring(T.inV) .. "; the game's channel " .. H.mhz(H.ch(T.r)))
        H.unhold(T.r)
        H.hold(T.wk, "p")
    end)
    C.r54leg(T, "cw", "wk", T.L .. " on the Army walkie")
    H.step(2, function()
        if T.off then return end
        Q.check((T.stores or 0) > 0, T.L .. " (B14): Lite keeps a way to store a channel (the game's window has Add, Edit and Delete: \"if vanilla does it, so does Lite\")",
            (T.stores or 0) .. " storing controls on the ValuTech's and the walkie's plain cards; the Channels rows only recall")
    end)
    -- (the TV last: no TV placed skips only this leg)
    C.r54leg(T, "ww", "tv", T.L .. " on a TV")
    H.caseEnd(T.L)
end

-- ===================================================================== R56 Large text, Dark and Light
function C.r56()
    local T = { L = "R56 Large text, Dark and Light" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        T.r = H.giveRadio("Base.RadioBlack", { batt = 0.8, on = true, vol = 0.2, ch = 101200, presets = { { "One", 90000 }, { "Two", 101200 } } })
        H.hold(T.r, "p")
        H.sizeSet("large")
    end)
    H.showQ(T, "cw", "r")
    for _, th in ipairs({ "dark", "light" }) do
        H.step(2, function() if not T.off then H.theme(th) end end)
        Q.waitMs(1200)
        H.shotQ(function() if T.off then return nil end; return "rd_fill_" .. th .. "_" .. H.sizeTag() end, "the ValuTech and its fill blocks at Large text, " .. th)
        H.step(2, function() if not T.off then RT.bounds(Q, T.L .. ", " .. th) end end)
    end
    H.step(2, function()
        if T.off then return end
        local cw = RT.cw()
        T.z = H.fillZone(cw, "fill:radio:head:channels")
        if T.z then H.clickAt(cw, T.z) end
    end)
    H.step(3, function()
        if T.off then return end
        local cw = RT.cw()
        T.f1 = ZeD.TabFill.folded(cw, "radio", "channels")
        local z = H.fillZone(cw, "fill:radio:head:channels")
        if z then H.clickAt(cw, z) end
    end)
    H.step(3, function()
        if T.off then return end
        local cw = RT.cw()
        local f2 = ZeD.TabFill.folded(cw, "radio", "channels")
        Q.check(T.z ~= nil and T.f1 == true and f2 == false, T.L .. " (mouse): the Channels head folds the block and opens it again", "head found " .. tostring(T.z ~= nil) .. ", folded " .. tostring(T.f1) .. " then " .. tostring(f2))
        local sc, t = cw._radioScroll, H.tw(cw)
        if sc and sc.visible and t and t.view then
            H.note(T.L .. ": the scrollbar at x " .. math.floor(sc.x) .. " to " .. math.floor(sc.x + sc.width) .. ", the body's view ends at " .. math.floor(t.view.x + t.view.w)
                .. ", the drawer " .. H.drawerW(cw) .. " px wide (the director's eye on the pictures: it meets the frame)")
        else
            H.note(T.L .. ": the body fits at Large text here (no scrollbar)")
        end
        H.themeBack()
        H.sizeBack()
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== the car
function H.part(v, id) local p = nil; if v then pcall(function() p = v:getPartById(id) end) end; return p end
function H.keep(it)
    if not H.isItem(it) then return end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    S.keep[it] = true
    S.made[#S.made + 1] = it
end
-- the car's radio part with this item (a fresh one each case); its kind as ZeD reads it
function H.carRadio(ft)
    local part = H.part(S.car, "Radio")
    if not part then return nil end
    pcall(function()
        local it = instanceItem(ft)
        part:setInventoryItem(it)
        S.car:transmitPartItem(part)
    end)
    return part
end
function H.carKind(part) local k = nil; pcall(function() k = S.O.kindOf(part:getInventoryItem(), part:getDeviceData()) end); return k end
function H.carBatt(c) pcall(function() local it = H.part(S.car, "Battery"):getInventoryItem(); it:setCurrentUsesFloat(c) end) end
function H.carHit(id) local p = H.carProp(); for _, h in ipairs((p and p._hits) or {}) do if h.id == id then return h end end; return nil end
function H.carIds() local o = {}; local p = H.carProp(); for _, h in ipairs((p and p._hits) or {}) do o[#o + 1] = tostring(h.id) end; return H.list(o, 16) end
function H.carDown(id) local p, h = H.carProp(), H.carHit(id); if not (p and h) then return false end; H.zcall(function() p:onMouseDown(h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2)) end); return true end
function H.carUpAt(id) local p, h = H.carProp(), H.carHit(id); if not (p and h) then return false end; H.zcall(function() p:onMouseUp(h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2)) end); return true end
function H.carClick(id) local ok = H.carDown(id); H.carUpAt(id); return ok end
function H.carRight(id) local p, h = H.carProp(), H.carHit(id); if not (p and h) then return false end; H.zcall(function() p:onRightMouseDown(h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2)) end); return true end
function H.carPad(id, button) local p = H.carProp(); if not p then return false end; if id then p.focusId = id end; H.zcall(function() p:onJoypadDown(button, nil) end); return true end
function H.carOpenQ(T)
    H.step(2, function() if not T.off then H.zcall(function() ISVehicleMenu.onSignalDevice(S.p, T.part) end) end end)
    H.wait(3000, function() return T.off or (H.carUp() and #((H.carProp() and H.carProp()._hits) or {}) > 0) end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": the wheel's Device Options slice brings the car radio up close", "up " .. tostring(H.carUp()) .. ", controls " .. H.carIds()) then T.off = true end
    end)
end
function S.carQ()
    H.step(2, function()
        if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_PREP and ZEDQA_CAR_READY and ZEDQA_CAR_ENTER and ZEDQA_CAR_AWAY) then
            S.noCar = "the prelude's car helpers are not loaded (zedqa_prelude.lua runs first)"
            return
        end
        ZEDQA_CAR_WAIT("Base.CarNormal", "rd_tab", function(v)
            S.car = v
            S.cars[#S.cars + 1] = v
            ZEDQA_CAR_KEEP[v] = true
            H.keep(ZEDQA_CAR_PREP(v))
            H.snapAt(v:getX(), v:getY(), 0)
            S.carReady = true
        end, function(why) S.noCar = why or "no ready car" end, 6000)
    end)
    H.wait(45000, function() return S.carReady or S.noCar ~= nil end, function()
        if not Q.check(S.car ~= nil, "the car cases: a sedan spawned on the strip, repaired, its key in his bag", tostring(S.noCar)) then S.noCar = S.noCar or "no car in 45 s" end
        if S.car and not H.part(S.car, "Radio") then S.noCar = "the sedan has no Radio part" end
    end)
end
function H.carStart(T, ft, seat)
    if not H.caseStart(T, "home") then return false end
    if not S.car then T.off = true; Q.skip(T.L, S.noCar or "no car"); return false end
    pcall(function() S.car:repair() end)
    H.carBatt(1.0)
    T.part = H.carRadio(ft)
    T.kind = T.part and H.carKind(T.part)
    if not (T.part and H.dd(T.part)) then T.off = true; Q.skip(T.L, "the radio part took no " .. ft); return false end
    if seat then
        local ok, why = ZEDQA_CAR_ENTER(S.car, seat)
        if not ok then T.off = true; Q.skip(T.L, "he could not be seated: " .. tostring(why)); return false end
    end
    return true
end

-- ===================================================================== R47 the car radio up close
function C.r47()
    local T = { L = "R47 the car radio up close" }
    H.step(2, function() if not H.carStart(T, "Base.RadioBlack", 0) then return end; H.prep(T.part, { on = false, vol = 0.2 }) end)
    H.carOpenQ(T)
    H.shotQ(function() if T.off then return nil end; return "rd_carradio_" .. tostring(T.kind) .. "_" .. H.sizeTag() end, "the car radio up close (" .. "ValuTech" .. ")")
    H.step(2, function() if not T.off then RT.bounds(Q, T.L); H.carPad(nil, Joypad.BButton) end end)
    H.step(3, function()
        if T.off then return end
        Q.check(not H.carUp(), T.L .. " (pad): B puts it away", "up " .. tostring(H.carUp()))
        H.zcall(function() ISVehicleMenu.onSignalDevice(S.p, T.part) end)
    end)
    H.step(3, function()
        if T.off then return end
        T.up2 = H.carUp()
        H.zcall(function() S.CR.takeEscape() end)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(T.up2 and not H.carUp(), T.L .. ": Escape puts it away", "up again " .. tostring(T.up2) .. ", after Escape " .. tostring(H.carUp()))
        H.zcall(function() ISVehicleMenu.onSignalDevice(S.p, T.part) end)
    end)
    H.step(3, function()
        if T.off then return end
        T.up3 = H.carUp()
        pcall(function() S.car:exit(S.p); triggerEvent("OnExitVehicle", S.p) end)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(T.up3 and not H.carUp(), T.L .. ": leaving the seat puts it away", "up again " .. tostring(T.up3) .. ", after the exit " .. tostring(H.carUp()))
    end)
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        local ok, why = ZEDQA_CAR_ENTER(S.car, 2)
        if not ok then Q.skip(T.L .. ": a back-seat passenger", "he could not take a back seat: " .. tostring(why)); return end
        T.back = true
        H.zcall(function() ISVehicleMenu.onSignalDevice(S.p, T.part) end)
    end)
    H.step(3, function()
        if T.off or not T.back then return end
        local reach = nil
        pcall(function() reach = S.O.reachable(S.p) end)
        Q.check(reach == nil and not H.carUp(), T.L .. ": from a back seat the car's radio is out of reach and nothing comes up close",
            "the seat " .. tostring(S.car:getSeat(S.p)) .. ", reachable " .. tostring(reach ~= nil) .. ", up " .. tostring(H.carUp()) .. " (the game shows a back seat no Device Options slice)")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R48 the car radio's power with the battery flat
function C.r48()
    local T = { L = "R48 the car radio's power with the car battery flat" }
    H.step(2, function()
        if not H.carStart(T, "Base.RadioBlack", 0) then return end
        pcall(function() if S.car:isEngineRunning() then S.car:shutOff() end end)
        H.prep(T.part, { on = false, vol = 0.2 })
        H.carBatt(0)
    end)
    H.carOpenQ(T)
    H.step(2, function()
        if T.off then return end
        T.pw = H.powered(T.part)
        H.carClick("vol")
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(not H.on(T.part) and T.pw == false, T.L .. " (mouse): with the engine off and the battery flat VOL's push does nothing",
            "the game's on " .. tostring(H.on(T.part)) .. ", canBePoweredHere " .. tostring(T.pw) .. "; controls " .. H.carIds())
        H.carBatt(1.0)
    end)
    Q.waitMs(400)
    H.step(2, function() if not T.off then T.pw2 = H.powered(T.part); H.carPad("vol", Joypad.XButton) end end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.on(T.part) and T.pw2 == true, T.L .. " (pad): with the battery charged X on VOL turns it on", "the game's on " .. tostring(H.on(T.part)) .. ", canBePoweredHere " .. tostring(T.pw2))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R49 the car's CD
function H.dash() local d = nil; pcall(function() d = RT.find(function(t) return t.Type == "ZeD_Dashboard" end) end); return d end
function C.r49()
    local T = { L = "R49 the car's CD" }
    H.step(2, function()
        if not H.carStart(T, "Base.RadioRed", 0) then return end
        H.prep(T.part, { on = true, vol = 0.1 })
        local _, inv = H.bag()
        T.disc = H.giveTo(inv, "Base.Disc_Retail")
        if not (T.disc and H.mediaReady(T.disc, "CDs")) then T.off = true; Q.skip(T.L, "the disc given has no recorded media"); return end
        local mt = -1
        pcall(function() mt = H.dd(T.part):getMediaType() end)
        if mt < 0 then T.off = true; Q.skip(T.L, "the radio part's data plays no media with RadioRed in it (kind " .. tostring(T.kind) .. ")") end
    end)
    H.carOpenQ(T)
    H.shotQ(function() if T.off then return nil end; return "rd_carradio_" .. tostring(T.kind) .. "_" .. H.sizeTag() end, "the car radio up close (" .. "Premium CD" .. ")")
    H.step(2, function() if not T.off then S.lastCtx = nil; H.carClick("slot") end end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.menuOpen() and H.menuOpt(T.disc) ~= nil, T.L .. " (mouse): the empty slot lists the disc in his bag", "the list: " .. H.s(H.list(H.menuNames())) .. "; controls " .. H.carIds())
        if not H.menuPick(T.disc) then T.off = true end
        H.menuClose()
    end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off then return end
        Q.check(H.media(T.part), T.L .. ": the pick puts it in the car's radio", "the game's hasMedia " .. tostring(H.media(T.part)) .. "; queued " .. tostring(T.qKinds))
        H.carClick("play")
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        Q.check(H.playing(T.part), T.L .. " (mouse): play runs the disc", "the game's isPlayingMedia " .. tostring(H.playing(T.part)))
        T.n0 = H.count("Base.Disc_Retail")
        H.carPad("eject", Joypad.AButton)
    end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off then return end
        Q.check(not H.media(T.part) and H.count("Base.Disc_Retail") == (T.n0 or 0) + 1, T.L .. " (pad): A on eject takes it out", "hasMedia " .. tostring(H.media(T.part)) .. ", discs " .. tostring(T.n0) .. " -> " .. H.count("Base.Disc_Retail"))
        H.carShut()
        T.dsh = H.dash()
        if not T.dsh then Q.skip(T.L .. ": the dash's slot", "no ZeD dashboard on screen"); return end
        H.zcall(function() T.dsh:_fire("slot", false) end)
    end)
    H.step(3, function()
        if T.off or not T.dsh then return end
        Q.check(H.carUp(), T.L .. ": the dash's empty slot brings the radio up close", "up " .. tostring(H.carUp()))
        H.carShut()
        local disc = nil
        for _, it in ipairs(H.all()) do if H.ft(it) == "Base.Disc_Retail" and not S.found.inv0[it] then disc = it end end
        pcall(function()
            local a = ISDeviceMediaAction:new(S.p, false, disc, ISDeviceBatteryAction:getDeviceDataParameter(S.p, T.part, "VehiclePart"))
            if not a.deviceData then a.deviceData = T.part:getDeviceData() end
            ISTimedActionQueue.add(a)
        end)
    end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off or not T.dsh then return end
        if not H.media(T.part) then Q.skip(T.L .. ": the dash's slot with a disc in", "the game's media action put no disc in"); T.noDash = true; return end
        H.zcall(function() T.dsh:_fire("slot", false) end)
    end)
    H.waitQ(T, 20000)
    H.step(2, function()
        if T.off or not T.dsh or T.noDash then return end
        Q.check(not H.media(T.part), T.L .. ": the dash's slot with a disc in ejects it", "hasMedia " .. tostring(H.media(T.part)))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R50 the car's ham
function C.r50()
    local T = { L = "R50 the car's ham" }
    H.step(2, function()
        if not H.carStart(T, "Base.HamRadio1", 0) then return end
        H.prep(T.part, { on = true, vol = 0.1, ch = 146520, presets = {}, mic = false })
        if not H.on(T.part) then T.off = true; Q.skip(T.L, "the car's ham would not turn on") end
    end)
    H.carOpenQ(T)
    H.shotQ(function() if T.off then return nil end; return "rd_carradio_" .. tostring(T.kind) .. "_" .. H.sizeTag() end, "the car radio up close (ham)")
    H.step(2, function() if not T.off then H.carClick("mem") end end)
    H.step(3, function()
        if T.off then return end
        T.n1 = #H.presets(T.part)
        S.lastBox = nil
        H.carRight("mem")
    end)
    H.wait(1500, function() return T.off or H.boxUp() end, function(ok)
        if T.off then return end
        Q.check(T.n1 == 1 and ok, T.L .. " (mouse): MEM stores the channel, a right-click on MEM opens the naming box", "presets " .. tostring(T.n1) .. "; box up " .. tostring(ok) .. "; controls " .. H.carIds())
        if ok then H.boxOK("Base") end
    end)
    H.step(3, function()
        if T.off then return end
        local pr = H.presets(T.part)
        Q.check(pr[1] ~= nil and pr[1].name == "Base", T.L .. ": OK names it", "the game's list " .. H.presetText(T.part))
        pcall(function() H.dd(T.part):setChannel(147000) end)
        H.carClick("mem")
    end)
    H.step(3, function()
        if T.off then return end
        local pr = H.presets(T.part)
        if pr[1] then pcall(function() H.dd(T.part):setChannel(pr[1].freq) end) end
        H.carPad("chdn", Joypad.AButton)
    end)
    H.step(3, function()
        if T.off then return end
        local pr = H.presets(T.part)
        Q.check(#pr == 2 and H.ch(T.part) == pr[2].freq, T.L .. " (pad): CH- on channel 01 goes to the last", "the game's channel " .. H.mhz(H.ch(T.part)) .. "; the list " .. H.presetText(T.part))
        T.m0 = H.micMuted(T.part)
        H.carClick("mic")
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.micMuted(T.part) == not T.m0, T.L .. " (mouse): MIC mutes the car ham's microphone", "the game's mic muted " .. tostring(T.m0) .. " -> " .. tostring(H.micMuted(T.part)))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R51 the car's radio part in the World tab (B3)
function C.r51()
    local T = { L = "R51 the car's radio part from outside the car" }
    H.step(2, function()
        if not H.carStart(T, "Base.RadioBlack", nil) then return end
        H.prep(T.part, { on = false, vol = 0.1 })
        H.goTo(S.car:getX() - 2.6, S.car:getY() + 0.5, 0)
        H.zcall(function() ISRadioWindow.activate(S.p, T.part) end)
    end)
    H.wait(4000, function() local ww = RT.ww(); return T.off or (H.onTab(ww) and H.shownDev(ww) == T.part) end, function(ok)
        if T.off then return end
        local ww = RT.ww()
        local e = ww and ww._radios and ww._radios[S.RTab.indexOf(ww._radios, T.part) or 0]
        Q.check(ok and e ~= nil and e.locationTag == "Vehicle" and H.isPlain(ww), T.L .. ": Device Options on the car's radio from outside opens the World tab on it, Vehicle, the plain card",
            H.tabText("ww", T.part) .. "; its place " .. H.s(e and e.locationTag) .. ", the plain card " .. tostring(H.isPlain(ww)))
        if not ok then T.off = true; return end
        T.pw = H.powered(T.part)
        if not H.click(ww, "power", nil, T.L) then T.off = true; Q.skip(T.L .. " (B3)", "the plain card has no power control (" .. H.list(H.hitIds(ww)) .. ")") end
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(not H.on(T.part), T.L .. " (B3): from outside the car ZeD's power does nothing, as the game's buttons do nothing there (the director's stakes call)",
            "the game's on " .. tostring(H.on(T.part)) .. " (power nearby " .. tostring(T.pw) .. "); he is " .. H.n1(math.sqrt((S.car:getX() - S.p:getX()) ^ 2 + (S.car:getY() - S.p:getY()) ^ 2)) .. " tiles from the car, in it " .. tostring(S.p:getVehicle() ~= nil))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== R12 safe mode
function C.r12()
    local T = { L = "R12 safe mode" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        if not (ZeD.Settings and ZeD.Settings.safeModeOption) then T.off = true; Q.skip(T.L, "no safe mode setting"); return end
        T.wk = H.giveRadio("Base.WalkieTalkie2", { batt = 0.8, on = false })
        T.wk2 = H.giveRadio("Base.WalkieTalkie2", { batt = 0.8, on = false })
        if S.car and H.part(S.car, "Radio") then
            T.part = H.carRadio("Base.RadioBlack")
            local ok = ZEDQA_CAR_ENTER(S.car, 0)
            if ok and T.part then H.zcall(function() ISVehicleMenu.onSignalDevice(S.p, T.part) end); T.car = true end
        end
    end)
    H.step(4, function()
        if T.off then return end
        T.carUp0 = H.carUp()
        H.safe(true)
    end)
    Q.waitMs(800)
    H.step(2, function()
        if T.off then return end
        if T.car then
            Q.check(H.safeOn() and T.carUp0 and not H.carUp(), T.L .. ": safe mode on puts the car radio up close away", "safe " .. tostring(H.safeOn()) .. ", up before " .. tostring(T.carUp0) .. ", after " .. tostring(H.carUp()))
        else
            Q.skip(T.L .. ": the car radio up close in safe mode", S.noCar or "no car")
        end
        pcall(function() if S.p:getVehicle() then local car = S.p:getVehicle(); car:exit(S.p); triggerEvent("OnExitVehicle", S.p) end end)
        H.gameWinShut()
        pcall(function() ISTimedActionQueue.add(ISEquipWeaponAction:new(S.p, T.wk, 20, true, false)) end)
    end)
    H.wait(8000, function() return T.off or S.p:getPrimaryHandItem() == T.wk end, function() end)
    Q.waitMs(600)
    H.step(2, function()
        if T.off then return end
        Q.check(H.gameWin(), T.L .. ": in safe mode equipping a walkie opens the game's window again (its onEquip auto-open is back)", "ISRadioWindow up " .. tostring(H.gameWin()) .. ", safe " .. tostring(H.safeOn()))
        H.gameWinShut()
        H.zcall(function() ISRadioWindow.activate(S.p, T.wk) end)
    end)
    H.step(3, function()
        if T.off then return end
        Q.check(H.gameWin(), T.L .. ": in safe mode Device Options opens the game's window", "ISRadioWindow up " .. tostring(H.gameWin()))
        H.gameWinShut()
        H.safe(false)
        H.unhold(T.wk)
    end)
    Q.waitMs(800)
    H.step(2, function()
        if T.off then return end
        RT.pairOpen()
        pcall(function() ISTimedActionQueue.add(ISEquipWeaponAction:new(S.p, T.wk2, 20, true, false)) end)
    end)
    H.wait(8000, function() return T.off or S.p:getPrimaryHandItem() == T.wk2 end, function() end)
    Q.waitMs(600)
    H.step(2, function()
        if T.off then return end
        Q.check(not H.safeOn() and not H.gameWin(), T.L .. ": safe mode off, equipping a walkie opens no game window again", "safe " .. tostring(H.safeOn()) .. ", ISRadioWindow up " .. tostring(H.gameWin()))
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== the faces no case shows, pictured (and drawn without an error)
function C.faceLeg(T, which, key)
    H.showQ(T, which, key)
    H.faceShotQ(T, which, key)
    H.step(2, function()
        if T.off then return end
        Q.check(#H.hits(H.win(which)) > 0 and H.face(H.win(which)) ~= nil, T.L .. ": its face draws with its controls", "face " .. tostring(H.face(H.win(which))) .. ", controls " .. H.list(H.hitIds(H.win(which)), 14))
    end)
end
function C.facesHome()
    local T = { L = "faces: the makeshift walkie and the ManPack" }
    H.step(2, function()
        if not H.caseStart(T, "home") then return end
        T.a = H.giveRadio("Base.WalkieTalkieMakeShift", { batt = 0.8, on = true, vol = 0.1 })
        T.b = H.giveRadio("Base.ManPackRadio", { batt = 0.8, on = true, vol = 0.1 })
        H.hold(T.a, "p")
        H.hold(T.b, "s")
    end)
    C.faceLeg(T, "cw", "a")
    C.faceLeg(T, "cw", "b")
    H.caseEnd(T.L)
end
function C.facesSpot()
    local T = { L = "faces: the widescreen TV" }
    H.step(2, function()
        if not H.caseStart(T, "spot") then return end
        T.tv = H.place("tv_widescreen", H.ringSq(1))
        if T.tv then H.prep(T.tv, { on = true, vol = 0.1, ch = 200 }) end
    end)
    C.faceLeg(T, "ww", "tv")
    H.caseEnd(T.L)
end

-- ===================================================================== what single player cannot stage
function C.skips()
    H.step(2, function()
        Q.skip("R11 split screen: player 2's radio while player 1 owns the World window", "needs a second local player on a second controller")
        Q.skip("R43 two-way talk to another player, a server's channels and another player's lines in Heard", "multiplayer only")
    end)
end

-- ===================================================================== put back
function H.rwComment()
    for _, path in ipairs({ "42/media/lua/client/ZeD/Overrides/RadioWindow.lua", "media/lua/client/ZeD/Overrides/RadioWindow.lua" }) do
        local r = nil
        pcall(function() r = getModFileReader("ZeD_UI", path, false) end)
        if r then
            local n, hit = 0, nil
            pcall(function()
                local ln = r:readLine()
                while ln do
                    n = n + 1
                    if not hit and string.find(ln, "still to be drawn", 1, true) then hit = "line " .. n .. ": " .. ln end
                    ln = r:readLine()
                end
            end)
            pcall(function() r:close() end)
            return hit or "the words are gone"
        end
    end
    return nil
end
function H.putBack()
    if not S.back.on then return end
    S.back.on = nil
    local f = S.found
    H.speed(1)
    H.qstop()
    H.park(false)
    H.padOff()
    H.menuClose()
    H.boxShut()
    H.popShut()
    H.carShut()
    H.gameWinShut()
    H.stripRecOff()
    H.countOff()
    S.rpN = H.plateProxyOff()
    H.hooksOff()
    pcall(function() S.WR.unpin(S.p) end)
    pcall(function() if S.RTab._carried then S.RTab._carried[S.pn] = nil end end)
    pcall(function() if S.p:getVehicle() then local car = S.p:getVehicle(); car:exit(S.p); triggerEvent("OnExitVehicle", S.p) end end)
    H.handsEmpty()
    for _, c in ipairs(S.objs) do H.rmObj(c) end
    for _, it in ipairs(S.made) do H.removeItem(it) end
    H.liteBack()
    H.safeBack()
    H.themeBack()
    H.sizeBack()
    H.halfBack()
    H.gridBack()
    if f.recorded then pcall(function() if f.tod then getGameTime():setTimeOfDay(f.tod) end end) end
    for _, w in ipairs({ RT.cw(), RT.ww() }) do
        if w then w._radioFollow = nil; w._knobGrab = nil; w._gpFocusedRadioCtl = nil; w._radioIdx = 1 end
    end
end
function S.buildPutBack()
    Q.mark()
    Q.step(2, function()
        H.putBack()
        if S.homeAt then H.goTo(S.homeAt.x, S.homeAt.y, S.homeAt.z) end
    end)
    -- the car: the prelude's removal, a tick after he is out (removing one in the tick of the exit drops the game)
    Q.step(6, function()
        for _, v in ipairs(S.cars) do
            if ZEDQA_CAR_KEEP then ZEDQA_CAR_KEEP[v] = nil end
            if ZEDQA_CAR_AWAY then pcall(ZEDQA_CAR_AWAY, v) else pcall(function() v:permanentlyRemove() end) end
        end
    end)
    Q.waitMs(1500)
    Q.step(10, function()
        local f = S.found
        if not f.recorded then return end
        S.swept = H.sweepNew()
        S.lost = H.unstash()
        local now, n = {}, 0
        for _, it in ipairs(H.all()) do local ft = H.ft(it); now[ft] = (now[ft] or 0) + 1 end
        for ft, was in pairs(f.types or {}) do
            for _ = 1, was - (now[ft] or 0) do
                local it = nil
                pcall(function() it = H.inv():AddItem(ft) end)
                if it then f.inv0[it] = true; n = n + 1 end
            end
        end
        S.refilled = n
        S.floorSwept = H.sweepFloor()
        S.setsSwept = H.sweepSets()
        pcall(function()
            local a, b = f.hands.p, f.hands.s
            S.p:setPrimaryHandItem((a and S.p:getInventory():containsRecursive(a)) and a or nil)
            S.p:setSecondaryHandItem((b and S.p:getInventory():containsRecursive(b)) and b or nil)
        end)
        pcall(function() if f.back and S.p:getClothingItem_Back() ~= f.back then S.p:setClothingItem_Back(f.back) end end)
        H.goTo(f.pos.x, f.pos.y, f.pos.z)
        pcall(function() if f.dir then S.p:setDir(f.dir) end end)
        if S.layoutTouched and f.layout and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, f.layout, "rd_tab") end
        local w = RT.ww()
        if w then w._maxWinW = f.maxW end
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then return end
        RT.pairOpen()
        pcall(ZeD_CharacterWindow.openTab, S.pn, (f.ctab and f.ctab ~= "radio") and f.ctab or "loot")
        RT.worldTab((f.wtab and f.wtab ~= "radio") and f.wtab or "loot")
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then Q.skip("put back", "nothing was staged"); return end
        local carsLeft = 0
        for _, v in ipairs(S.cars) do
            local live = false
            pcall(function() local it = getCell():getVehicles():iterator(); while it:hasNext() do if it:next() == v then live = true end end end)
            if live then carsLeft = carsLeft + 1 end
        end
        Q.check(carsLeft == 0, "put back: the car the run spawned is gone", #S.cars .. " spawned, " .. carsLeft .. " left")
        local left = {}
        for _, it in ipairs(S.made) do if not H.gone(it) then left[#left + 1] = H.ft(it) end end
        Q.check(#left == 0, "put back: every thing the run gave is gone (radios, walkies, batteries, discs, tapes, headphones, bags, the car's key)", #S.made .. " given; left " .. H.list(left, 8))
        local extra = {}
        for _, it in ipairs(H.all()) do if not f.inv0[it] then extra[#extra + 1] = H.ft(it) end end
        Q.check(#extra == 0 and (S.lost or 0) == 0, "put back: he carries what he carried (his set-aside radios and things back)",
            "new " .. H.list(extra, 8) .. "; " .. tostring(S.swept) .. " swept, " .. tostring(S.floorSwept) .. " off the floor, " .. tostring(S.setsSwept) .. " sets left standing taken away, "
            .. tostring(S.refilled) .. " of his own given again, " .. tostring(S.lost) .. " set-aside things not given back")
        local objs = {}
        for _, c in ipairs(S.objs) do if H.objLeft(c) then objs[#objs + 1] = c.what end end
        local stray = 0
        if S.homeAt then stray = stray + H.setsNear(math.floor(S.homeAt.x), math.floor(S.homeAt.y), math.floor(S.homeAt.z)) end
        if S.spot then stray = stray + H.setsNear(math.floor(S.spot.x), math.floor(S.spot.y), S.spot.z) end
        Q.check(#objs == 0 and stray == 0, "put back: every set and the generator placed are gone, no new set stands at home or in the room", #S.objs .. " placed; left " .. H.list(objs, 6) .. "; new sets standing " .. stray)
        local hp, hs = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
        local bk = nil
        pcall(function() bk = S.p:getClothingItem_Back() end)
        Q.check(hp == f.hands.p and hs == f.hands.s and bk == f.back, "put back: his hands and back as found", H.nm(hp) .. ", " .. H.nm(hs) .. ", back " .. H.nm(bk))
        local elec, hydro = nil, nil
        pcall(function() elec = getSandboxOptions():getOptionByName("ElecShutModifier"):getValue() end)
        pcall(function() hydro = getWorld():isHydroPowerOn() end)
        Q.check(S.back.grid == nil and (f.elec == nil or elec == f.elec) and (f.hydro == nil or hydro == f.hydro), "put back: the grid and the shut-off day as found",
            "ElecShutModifier " .. tostring(elec) .. " (found " .. tostring(f.elec) .. "), hydro " .. tostring(hydro) .. " (found " .. tostring(f.hydro) .. ")")
        Q.check(H.optVal(ZeD.Settings and ZeD.Settings.lookStyleOption) == f.style and H.optVal(ZeD.Settings and ZeD.Settings.safeModeOption) == f.safe
            and ZeD.currentBase == f.base and ZeD.currentSize == f.size,
            "put back: Lite, safe mode, the theme and the text size as found", "style " .. tostring(H.optVal(ZeD.Settings and ZeD.Settings.lookStyleOption)) .. ", safe "
            .. tostring(H.optVal(ZeD.Settings and ZeD.Settings.safeModeOption)) .. ", " .. tostring(ZeD.currentBase) .. ", " .. tostring(ZeD.currentSize))
        local w = RT.ww()
        Q.check(H.lockFound() == (S.lockWas or H.lockFound()) and S.parked == nil and S.back.maxW == nil and (w == nil or w._maxWinW == f.maxW)
            and H.hooked() and S.sr == nil and S.cnt == nil and S.rp == nil and H.popShowing() == nil and not H.carUp() and not H.gameWin(),
            "put back: the input lock, the pointer, the width cap, the hooks and watchers, the pop-out, the car radio and the game's window as found",
            "lock " .. H.lockFound() .. ", width cap " .. tostring(w and w._maxWinW) .. ", hooks off " .. tostring(H.hooked()))
        Q.check(H.volumes() == f.vols, "put back: the game's volume settings untouched", H.volumes() .. " (found " .. tostring(f.vols) .. ")")
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6 and S.p:getVehicle() == nil and H.qlen() == 0 and getGameSpeed() == 1,
            "put back: he stands where he stood, on foot, no action queued, game speed 1", string.format("%.1f,%.1f off", dx, dy) .. ", " .. H.qkinds())
        Q.check(S.errs == 0, "put back: nothing ZeD ran for this script threw", S.errs .. " caught" .. (S.zerr and (": " .. S.zerr) or ""))
        local e1 = H.errN()
        if S.err0 and e1 then Q.check(e1 == S.err0, "the Radio tab run ran with no Lua error", (e1 - S.err0) .. " new")
        else Q.skip("the Radio tab run's Lua error count", "the game's Lua error count cannot be read here") end
        H.note("B12: ZeD.RadioPlates was read " .. tostring(S.rpN) .. " times over the run (a dead file when 0; the car radio draws from PhysPx)")
        local rw = H.rwComment()
        H.note("B13: Overrides/RadioWindow.lua's comment on the TV and house radio faces: " .. H.s(rw or "the file could not be read through the game's mod file reader") .. " (RtvFace.lua draws them)")
        H.note("pictures: " .. H.list(S.shots, 40))
    end)
    Q.step(10, function()
        local f = S.found
        if f.pair == false and RT.isOpen() then RT.pairShut() end
        if f.recorded then pcall(function() if f.god ~= nil then S.p:setGodMod(f.god) end end) end
    end)
end

-- ===================================================================== the run
S.setup()
-- at home, the radios he carries (the Character window)
C.r1()
C.r2()
C.r3()
C.r4()
C.r13()
C.r14()
C.r15()
C.r16()
C.r17()
C.r18()
C.r19()
C.r20()
C.r21()
C.r22()
C.r31()
C.r32()
C.r33()
C.r34()
C.r35()
C.r36()
C.r37()
C.r38()
C.r39()
C.r40()
C.r41()
C.r42()
C.r55()
C.r53()
C.facesHome()
-- in the room on the grid, the sets placed (the World window)
S.toSpotQ()
C.r5()
C.r6()
C.r7()
C.r8()
C.r9()
C.r10()
C.r44()
C.r45()
C.r46()
C.r23()
C.r24()
C.r25()
C.r26()
C.r27()
C.r28()
C.r29()
C.r30()
C.r52()
C.r54()
C.r56()
C.facesSpot()
-- home again: the car, then safe mode
S.toHomeQ()
S.carQ()
C.r47()
C.r48()
C.r49()
C.r50()
C.r51()
C.r12()
C.skips()
S.buildPutBack()
Q.start()
