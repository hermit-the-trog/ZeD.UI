-- ZeDUI/tools/qa/kiss_screen.lua  (Nov 22 2026, QA; tag ksss): the KISS audit's pictures (Keep It Super Simple: the
-- places where ZeD-GUI costs a time-poor new player extra steps), part "screen": 4K full screen, mouse and keyboard.
-- One honest in-game picture of each friction as a player meets it today, for the report page that puts the
-- director's design calls to him. Pictures to Zomboid/Screenshots/kiss_<name>.png; QA's runner kiss_pics_run.ps1
-- moves them to Screenshots/kiss_report/<name>.png. Manifest kiss_pics_screen.txt: the 1.0 gallery's staging (the
-- story stage at the West Point Fossoil, gallery_unload.lua, G1, hfr_common.lua), as beast_report_menus.txt.
--   09_page_rolled      theme 9, open pages roll away by themselves: both windows shut, the pointer out in the world,
--                       H pressed (the game's Health key handler): the pair opens on Health and, with nothing more
--                       done, the Character window rolls to its title bar at the top of the screen about two seconds
--                       on, the Health page gone; the title as the bar draws it (cut short or not, in the line). The
--                       World window, pinned by the staging, stays open beside it
--   16_no_open_button   theme 16, nothing on screen opens the windows: every ZeD window and menu shut, him standing on
--                       the open patch; the whole screen, the HUD alone (the belt, the watch, the hint strip), every
--                       element on screen named in the line
--   17_craft_empty      theme 17, Craft opens on an empty list: on the open patch with nothing in the game's reach, his
--                       main inventory's loose things moved into a crate placed 6 to 9 squares behind him, a kitchen
--                       knife given, the crafting key B pressed: the Craft tab on Show: Ready, its list reading its
--                       empty line ("Nothing is ready to make with what is in reach."); any recipe that still shows is
--                       named in the line
--   22_watch_pushers    theme 22, the game's speed hides in tiny pushers on the belt's watch: Style Full and the Watch on
--                       the belt (ZeD's defaults, set for the picture where they are not), a digital wrist watch worn:
--                       the whole screen with the belt's mini watch and its SPEED and START pushers; the watch's and
--                       the pushers' boxes in screen pixels in the line, for the report's crop
--   25_second_press     theme 25, the second press does not put away what the first opened: both windows shut, H, the
--                       windows settle, H again: both windows still up, the Character window back on Loot, the World
--                       window beside it
--   35_amber_surface    theme 35, an amber Surface warning on every surface recipe, table or not: a table placed beside
--                       him, a plank and a screwdriver given, B: Drill Plank's card open (an any-surface recipe) with
--                       Craft lit and the amber Surface badge in its chip row
-- The scene: the open patch by the story's smoking spot (bxr_menus.lua's S.findPatch: bare squares round him, open sky
-- two and three squares toward the camera), zoom 1, him facing the camera. The windows open at their default places
-- (the saved places in his modData cleared while both are shut, put back at the end). The keys are pressed as the key
-- does, through the game's own handler (xpUpdate.displayCharacterInfo, server/XpSystem/XpUpdate.lua:125), which hands
-- the Health key to ZeD's toggleView hook (Overrides/CharacterInfo.lua:119) and the crafting key to ZeD's
-- OpenHandcraftWindow hook (Overrides/Stations.lua:136). The pointer the game's Lua reads (Mouse.setXY does not move
-- it) is swapped for a spot: out in the world for 09, off every window and the HUD for the rest; the real pointer
-- stays hidden. ZeD's input mode is locked to the mouse and keyboard for the run. Settings: 09 sets the Character
-- window's pins to ZeD's default (no saved pins, as a new character has them: today both halves unpinned); 17 sets
-- his pinned recipes aside (a new character has none: they would stay listed under Ready); 22 sets Style and the Watch
-- option to ZeD's defaults (Full, Belt) where they are not; every other look setting stays as the staging left it.
-- Each picture is checked against what ZeD draws or does now, so a friction Build has since taken away is a SKIP that
-- says so, not a picture of something else (09 rolls up or not, 25 leaves both windows up or not, 35's Surface badge
-- is drawn amber or not: ZeD.Atoms.drawBadge watched while the card draws); a belt box of a kind this script does not
-- know, or one added through ZeD.Belt.addBox (16, 22), is named in a NOTE, and so is a container or a table in his
-- reach in 17 (the tab's own container list, the game's surface finder).
-- Each picture prints "ZEDQA ksss SHOT <name> | what is in it" or "ZEDQA ksss SKIP <name> | why".
-- What it puts back: the Character window's pins (as the staging pinned them), his pinned recipes, Style and the Watch
-- option, the watch given (if one was), his loose things from the crate back into his main inventory, the crate and the
-- table removed, ZeD.Atoms.drawBadge unwatched, the things given taken back, his own things set aside for the weight,
-- a bound station, the windows' saved places and pins in his modData exactly as found, the pair as found, the input
-- mode lock, the pointer the game reads, the zoom, game speed, the glasses; he ends at the stock spot standing, alive
-- and whole. grep "ZEDQA ksss".
local S = HFR and HFR.init and HFR.init("ksss")
if not S then return end
S.DIR = "kiss_"
local Q = S.Q
S.CC, S.CT, S.HV, S.St = ZeD.CraftingCore, ZeD.CraftingTab, ZeD.Halves, ZeD.Settings
S.WA, S.WM, S.BT, S.HS, S.MS = ZeD.Watch, ZeD.WatchMini, ZeD.Belt, ZeD.HintStrip, ZeD.Messages
S.Det = ZeD.Input and ZeD.Input.Detector
S.pic, S.aside = {}, {}
S.p9, S.p16, S.p17, S.p22, S.p25, S.p35 = {}, {}, { moved = {} }, {}, {}, {}
S.N09, S.N16, S.N17 = "09_page_rolled", "16_no_open_button", "17_craft_empty"
S.N22, S.N25, S.N35 = "22_watch_pushers", "25_second_press", "35_amber_surface"
S.DRILL, S.PLANK, S.SCREW, S.KNIFE = "DrillPlank", "Base.Plank", "Base.Screwdriver", "Base.KitchenKnife"
S.WATCH, S.CRATE = "Base.WristWatch_Left_DigitalBlack", "carpentry_01_16"
-- (bxr_craft.lua's tables: the first one the game takes as a crafting surface is kept)
S.TABLES = { "furniture_tables_high_01_16", "furniture_tables_high_01_0", "furniture_tables_high_01_8", "furniture_tables_high_01_24",
    "furniture_tables_high_01_32", "furniture_tables_high_01_40", "furniture_tables_low_01_0", "furniture_tables_low_01_8" }
-- the squares beside him that are never between him and the camera: north, west, level right, level left, behind
S.SLOTS = { { 0, -1 }, { -1, 0 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }

if not (S.CC and S.CT and S.HV and S.St and S.St.lookStyleOption and S.St.watchPlaceOption and S.WA and S.WM and S.BT
        and S.HS and S.Det and S.Det.setLockedMode and xpUpdate and xpUpdate.displayCharacterInfo and KeybindId) then
    Q.say("ERR ZeD's windows, halves, Craft tab, watch, belt, hint strip or input detector, or the game's key handler, is not loaded")
    Q.start()
    return
end

-- ===================================================================== helpers: errors, pictures, time
-- (bxr_inv.lua) the debug build's red ERROR box comes for three seconds after every error the game logs, and no UI
-- element draws it: the game's error count is read every frame, and a picture waits until none has come for 3.6 s
S.errN, S.errAt = nil, -100000
function S.errWatch()
    local n = getLuaDebuggerErrorCount and getLuaDebuggerErrorCount() or nil
    if n ~= nil and n ~= S.errN then
        if S.errN ~= nil then S.errAt = getTimestampMs() end
        S.errN = n
    end
end
function S.quiet() S.errWatch(); return getTimestampMs() - S.errAt > 3600 end
Events.OnPreUIDraw.Add(S.errWatch)

function S.skip(name, why) Q.notTaken(name, why); Q.say("SKIP " .. name .. " | " .. tostring(why)) end
function S.fl(v) return math.floor(tonumber(v) or 0) end
function S.scr() return S.core:getScreenWidth(), S.core:getScreenHeight() end
function S.zoom()
    local z = S.core:getZoom(S.pn)
    if not z or z <= 0 then z = 1 end
    return z
end
function S.speed(n) if ZEDQA_SPEED then ZEDQA_SPEED(n) else setGameSpeed(n) end end
-- the main inventory's load (gallery_unload.lua's sum: the game's own figure lags a frame)
function S.load()
    if GAL_UNLOAD and GAL_UNLOAD.weight then return GAL_UNLOAD.weight() end
    local t = 0
    local items = S.p:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if S.p:isEquipped(it) then t = t + it:getEquippedWeight() else t = t + it:getUnequippedWeight() end
    end
    return t
end
function S.maxLoad() return S.p:getMaxWeight() or 20 end
-- An error balloon of ZeD's Messages (a red one out of the belt's note) taken off the screen, as a click on it does
-- (ZeD_Messages.lua M.dropToast: the line stays in Messages, read or unread as it was). Says what it found
function S.noBalloons()
    local M = S.MS
    if not (M and M.toasts and M.dropToast and M.unread) then return "" end
    local gone = 0
    for i = #M.toasts, 1, -1 do
        local t = M.toasts[i]
        if t and t.kind == "crit" then M.dropToast(t); gone = gone + 1 end
    end
    local un, err = M.unread()
    local out = ""
    if gone > 0 then out = out .. "; NOTE " .. gone .. " error balloon(s) of Messages dismissed before the picture" end
    if err then out = out .. "; NOTE Messages holds an unread error (" .. tostring(un) .. " unread): the belt's note counts it" end
    return out
end
-- the gallery rule: never over the weight limit (the Heavy Load moodle would show); no error box
function S.shotOk(name, what)
    local l, max = S.load(), S.maxLoad()
    if l > max then
        S.skip(name, string.format("over the weight limit (%.1f of %.1f kg): the Heavy Load moodle would show", l, max))
        return false
    end
    local note = S.noBalloons()
    if not S.quiet() then note = note .. "; NOTE a Lua error came " .. S.fl(getTimestampMs() - S.errAt) .. " ms before the picture: the game's red box may be in it" end
    S.shot(name)
    S.pic[#S.pic + 1] = name
    Q.say("SHOT " .. name .. " | " .. tostring(what) .. note)
    return true
end
-- time, not frames: cond asked every 100 ms (a UI update), at most ms; fn(true) when cond came true (bxr_menus.lua)
function S.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 400000, function()
        local now = getTimestampMs()
        st.t = st.t or now
        if st.last and now - st.last < 100 then return false end
        st.last = now
        local ok, r = pcall(cond)
        if ok and r then st.ok = true; return true end
        return now - st.t >= ms
    end, function() fn(st.ok == true) end)
end
-- the camera has stopped after a move: his place on screen the same for 20 drawn frames (at most 900)
function S.settle(on)
    local st = { same = 0 }
    Q.waitFor(5, 900, function()
        if on and not on() then return true end
        if S.p:getCurrentSquare() == nil then return false end
        local v = S.fl(isoToScreenX(S.pn, S.p:getX(), S.p:getY(), 0)) .. "," .. S.fl(isoToScreenY(S.pn, S.p:getX(), S.p:getY(), 0))
        if v == st.last then st.same = st.same + 1 else st.last, st.same = v, 0 end
        return st.same >= 20
    end, function() end)
end
-- the camera's zoom to get() (nil: left as it is), a quarter step a frame as G1's Q.zoomTo (bxr_menus.lua)
function S.zoomDyn(get)
    local st = {}
    Q.waitFor(2, 1200, function()
        if st.left == nil then
            local z = get()
            st.left = z and math.floor((S.core:getZoom(S.pn) - z) / 0.25 + 0.5) or 0
            st.moved = st.left ~= 0
        end
        if st.left == 0 then return true end
        S.core:doZoomScroll(S.pn, (st.left > 0) and -1 or 1)
        st.left = (st.left > 0) and (st.left - 1) or (st.left + 1)
        return st.left == 0
    end, function() end)
    Q.waitFor(1, 200, function()
        if not st.moved then return true end
        st.n = (st.n or 0) + 1
        return st.n >= 100
    end, function() if st.moved then Q.say("zoom " .. tostring(S.core:getZoom(S.pn))) end end)
end

-- ===================================================================== helpers: the open patch (bxr_menus.lua)
function S.sqAt(x, y) return getCell():getGridSquare(x, y, 0) end
-- a bare square in the open
function S.goodSq(sq)
    local good = false
    pcall(function()
        good = sq ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree() and sq:isOutside()
            and sq:getRoom() == nil and sq:getObjects():size() <= 3 and sq:getWorldObjects():size() == 0
            and sq:getVehicleContainer() == nil and sq:getMovingObjects():size() == 0
    end)
    return good and sq or nil
end
-- the squares up to three deep on the camera side of (x, y), in the band drawn over a character standing on (x, y):
-- open sky (no roof, canopy or room), no tree, no car
S.AHEAD = { { 2, 0 }, { 0, 2 }, { 2, 1 }, { 1, 2 }, { 2, 2 }, { 3, 1 }, { 1, 3 }, { 3, 2 }, { 2, 3 }, { 3, 3 } }
function S.clearAhead(x, y)
    for _, o in ipairs(S.AHEAD) do
        local sq = S.sqAt(x + o[1], y + o[2])
        local ok = false
        if sq then
            pcall(function() ok = sq:isOutside() and sq:getRoom() == nil and not sq:HasTree() and sq:getVehicleContainer() == nil end)
        end
        if not ok then return false end
    end
    return true
end
function S.patchAt(x, y, lo, hi)
    for dy = lo, hi do
        for dx = lo, hi do
            if not S.goodSq(S.sqAt(x + dx, y + dy)) then return false end
        end
    end
    return true
end
function S.findPatch(cx, cy)
    for _, r in ipairs({ { -3, 2 }, { -2, 2 } }) do
        local best, bs = nil, 1e9
        for dy = -14, 14 do
            for dx = -14, 14 do
                local sc = math.abs(dx) + math.abs(dy) - (dx + dy) * 0.25
                if sc < bs and S.patchAt(cx + dx, cy + dy, r[1], r[2]) and S.clearAhead(cx + dx, cy + dy) then best, bs = { x = cx + dx, y = cy + dy, lo = r[1] }, sc end
            end
        end
        if best then return best end
    end
    return nil
end
function S.home(dir) if S.c then G1.tp({ S.c.x, S.c.y }, dir or "SE") end end
function S.where() return S.c and (S.c.x .. "," .. S.c.y) or "?" end

-- ===================================================================== helpers: the pointer and the input mode
-- the pointer the game's Lua reads (Mouse.setXY does not move it): swapped for a spot, and back (bxr_menus.lua)
function S.mouseOn(x, y)
    S.fx, S.fy = x, y
    if S.mouseSwapped then return end
    S.realMX, S.realMY = getMouseX, getMouseY
    S.mouseSwapped = true
    getMouseX = function() return S.fx end
    getMouseY = function() return S.fy end
end
function S.mouseOff()
    if not S.mouseSwapped then return end
    getMouseX, getMouseY = S.realMX, S.realMY
    S.mouseSwapped = false
end
-- the lock as found: ZeD setup's Input lock ("auto" is no lock); the save's copy only when the setting cannot be read
function S.lockFound()
    local key = nil
    pcall(function()
        local o = S.opt("inputModeLock")
        local keys = S.St.inputLockKeys
        if o and keys then key = keys[o:getValue() or 1] end
    end)
    if key == nil then pcall(function() local md = S.p:getModData().ZeD_Gamepad; key = md and md.inputModeLock end) end
    return key or "auto"
end
-- mode "kbm" for the run (the mouse and keyboard part); nil or false puts back the lock found
function S.lock(mode)
    if S.lockWas == nil then S.lockWas = S.lockFound() end
    if mode then
        S.Det.setLockedMode(mode)
        S.locked = true
        return
    end
    if not S.locked then return end
    S.locked = false
    S.Det.setLockedMode(nil)
    if S.lockWas == "kbm" or S.lockWas == "gamepad" then S.Det.setLockedMode(S.lockWas) end
end

-- ===================================================================== helpers: the windows
function S.copy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = S.copy(v) end
    return o
end
function S.rect(e)
    if not e then return "none" end
    return S.fl(e:getAbsoluteX()) .. "," .. S.fl(e:getAbsoluteY()) .. " " .. S.fl(e:getWidth()) .. "x" .. S.fl(e:getHeight())
end
function S.box4(r) return S.fl(r[1]) .. "," .. S.fl(r[2]) .. " " .. S.fl(r[3]) .. "x" .. S.fl(r[4]) end
function S.pageOpen(w) return w ~= nil and w._drawerOpen == true and w._drawerMode == "tab" end
function S.cLine()
    local c = S.CW()
    if not c then return "the Character window shut" end
    return "the Character window at " .. S.rect(c) .. " on " .. tostring(c._activeTab) .. (S.pageOpen(c) and " (its page open)" or " (no page open)")
        .. (c.windowShaded and ", rolled to its title bar" or "")
end
function S.wLine()
    local w = S.WW()
    if not w then return "the World window shut" end
    return "the World window at " .. S.rect(w) .. " on " .. tostring(w._activeTab) .. (w.windowShaded and ", rolled to its title bar" or "")
end
function S.winLine() return S.cLine() .. "; " .. S.wLine() end
function S.halvesLine(w)
    local s = w and w._halves
    if not (s and s.inv and s.drawer) then return "no halves" end
    return "pins: inventory half " .. tostring(s.inv.pinned) .. ", tab half " .. tostring(s.drawer.pinned)
        .. "; rolled: inventory half " .. tostring(s.inv.rolled) .. ", tab half " .. tostring(s.drawer.rolled)
end
-- the pins a saved table gives a window, as WindowHalves.lua:74 load reads it: with no pin of a half saved, the old
-- single pin (char or world) pins both halves, and no table at all pins neither
function S.pinsFrom(t, key)
    if type(t) ~= "table" then return false, false end
    local i, d = t[key .. "Inv"], t[key .. "Tabs"]
    if i == nil and d == nil then
        local old = t[key] == true
        return old, old
    end
    return i == true, d == true
end
-- The Character window's pins at ZeD's default, as a new character has them: no pin of the Character window saved in
-- his modData (today WindowHalves.lua:74 load then gives both halves unpinned; Settings.lua has no pin option). The
-- staging pins both (zedqa_pin_windows.lua through ZeD_Window:setPinned, Organisms.lua:158). Read when the window is
-- built (WindowHalves.lua:876 attach, its key "char": ZeD_CharacterWindow.lua:6973), so only while the pair is shut;
-- whatever load makes of no saved pins is ZeD's default, and the halves' pins as built are in the picture's line
function S.pinsDefault()
    if S.CWm.isOpen(S.pn) then return false end
    local t = S.p:getModData().ZeD_WinPinned
    if type(t) == "table" then t.charInv, t.charTabs, t.char = nil, nil, nil end
    return true
end
-- the pins as the staging had them: an open window's halves (each half on its own, WindowHalves.lua:93), then the
-- saved table exactly as found
function S.pinsBack()
    local inv, drw = S.pinsFrom(S.was.pinT, "char")
    local w = S.CW()
    if w and w._halves then
        S.HV.setPin(w, "inv", inv)
        S.HV.setPin(w, "drawer", drw)
    end
    S.p:getModData().ZeD_WinPinned = S.copy(S.was.pinT)
    return inv, drw
end
-- The windows open at their default places, as a new character's do: no saved place (ZeD_CharacterWindow.lua:415
-- restoreCharState, ZeD_WorldWindow.lua:2757; the same spread as ZeD_Window.resetLayout, Organisms.lua:1607). Only
-- while both are shut (a close saves its place again); the saved places come back at the end (S.was.winState)
function S.defaultPlaces()
    if S.CWm.isOpen(S.pn) or S.WWm.isOpen(S.pn) then return false end
    local ws = S.p:getModData().ZeD_WinState
    if type(ws) == "table" then ws.char = nil; ws.world = nil end
    return true
end
-- every menu shut: the right-click menu (G1) and the controller's wheel
function S.closeMenu()
    G1.closeMenus()
    local m = getPlayerRadialMenu and getPlayerRadialMenu(S.pn) or nil
    if m and m:isReallyVisible() then m:undisplay() end
end
-- ZeD's other windows shut, as the prelude's layout rule shuts them (zedqa_prelude.lua ZEDQA_LAYOUT_DEFAULT): the
-- guide book, the studio, the guide, Messages. Says which were up
function S.closeOthers()
    local shut = {}
    local B = ZeD.GuideBook
    if B and B.isOpen and B.close and B.isOpen(S.pn) then B.close(S.pn); shut[#shut + 1] = "the guide book" end
    local Stu = ZeD.Studio
    if Stu and Stu.isOpen and Stu.close and Stu.isOpen() then Stu.close(); shut[#shut + 1] = "the studio" end
    for _, nm in ipairs({ "Guide", "MessagesWindow" }) do
        local t = ZeD[nm]
        local win = (t and t.get) and t.get(S.pn) or nil
        if win and win.close and win:isVisible() then win:close(); shut[#shut + 1] = nm end
    end
    if #shut > 0 then Q.say("shut " .. table.concat(shut, ", ") .. " (the prelude's layout rule leaves them shut)") end
    return shut
end
function S.allShut()
    S.closeMenu()
    local shut = S.closeOthers()
    S.closePair()
    return shut
end
-- how many times ZeD's toggleView hook has taken one of the game's Character pages (Overrides/CharacterInfo.lua:32,
-- counted at :116): the key's path went through ZeD's handler when it goes up
function S.route() return (ZeD.CharInfoRoute and ZeD.CharInfoRoute.count) or 0 end
-- a key of the game's options pressed as the key does: its key code to the game's own OnKeyPressed handler,
-- xpUpdate.displayCharacterInfo (server/XpSystem/XpUpdate.lua:125). The Health key goes on to
-- getPlayerInfoPanel(0):toggleView(Health) (XpUpdate.lua:154), ZeD's hook (Overrides/CharacterInfo.lua:119):
-- ZeD_CharacterWindow.openTab(pn, "health", true) (CharacterInfo.lua:60: the pair opened when shut, the tab pressed;
-- the open tab pressed again shuts its page, ZeD_CharacterWindow.lua:4721). The crafting key goes on to
-- ISEntityUI.OpenHandcraftWindow (XpUpdate.lua:132), ZeD's hook (Overrides/Stations.lua:136):
-- ZeD_WorldWindow.openTab(pn, "craft", true) (ZeD_WorldWindow.lua:6395). Returns ok and the key's name
function S.pressKey(id)
    local key = getCore():getKey(id)
    if type(key) ~= "number" or key <= 0 then return false, "not bound" end
    local nm = tostring(getKeyName(key))
    local ok, e = pcall(xpUpdate.displayCharacterInfo, key)
    if not ok then Q.say("ERR the game's key handler threw: " .. tostring(e)); return false, nm end
    return true, nm
end
-- the pair up on the Health page
function S.healthUp()
    local w = S.CW()
    return w ~= nil and S.WWm.isOpen(S.pn) and w._activeTab == "health" and S.pageOpen(w)
end
-- the pointer out in the world: right of and below the spread at the top of the screen, above the belt, off him (he
-- stands at the screen's middle); checked against the windows and the belt once they are up (S.under)
function S.worldPoint()
    local sw, sh = S.scr()
    return { S.fl(sw * 0.82), S.fl(sh * 0.66) }
end
function S.under(x, y)
    local hit = {}
    local list = { { "the Character window", S.CW() }, { "the World window", S.WW() } }
    list[#list + 1] = { "the belt", S.BT.getHUD and S.BT.getHUD(S.pn) or nil }
    for _, pr in ipairs(list) do
        local e = pr[2]
        if e and e:isVisible() then
            local ex, ey = e:getAbsoluteX(), e:getAbsoluteY()
            if x >= ex and y >= ey and x < ex + e:getWidth() and y < ey + e:getHeight() then hit[#hit + 1] = pr[1] end
        end
    end
    return (#hit > 0) and table.concat(hit, ", ") or "nothing"
end
-- the title as the bar draws it (Organisms.lua:689 _drawTitleBar: _titleShownW, the status pixel and the title cut to
-- what the stats and pins leave it) against its whole width
function S.titleLine(w)
    if not w then return "no window" end
    local title = tostring(w.title or "")
    local T, tm = ZeD.T, ZeD.TM
    local full = nil
    if T and T.fontF3 and tm and tm.MeasureStringX and title ~= "" then full = tm:MeasureStringX(T.fontF3, title) end
    local pix = 0
    if w._titleMark and T and T.px then pix = T.px(6) + T.px(4) end
    local shown = w._titleShownW
    local cut = "?"
    if full and shown then cut = tostring(shown - pix < full - 1) end
    return "its title \"" .. title .. "\" drawn " .. tostring(shown and S.fl(shown - pix)) .. " of " .. tostring(full and S.fl(full))
        .. " px (cut short " .. cut .. ")"
end

-- ===================================================================== helpers: the HUD
function S.hintWords(list)
    local words = {}
    for _, pr in ipairs(list or {}) do words[#words + 1] = tostring(pr.glyph) .. " " .. tostring(pr.label) end
    return (#words > 0) and table.concat(words, " ; ") or "nothing"
end
function S.watchWord(v) if v == 1 then return "Belt" elseif v == 2 then return "Corner" end; return tostring(v) end
function S.hudLine()
    local parts = {}
    local hud = S.BT.getHUD and S.BT.getHUD(S.pn) or nil
    if hud and hud:getIsVisible() and hud._drawn then
        local n = { hand = 0, slot = 0 }
        local more = {}
        for _, b in ipairs(hud._boxes or {}) do
            if b.kind == "hand" or b.kind == "slot" then n[b.kind] = n[b.kind] + 1
            elseif b.kind == "extra" then more[#more + 1] = "extra " .. tostring(b.id)
            else more[#more + 1] = tostring(b.kind) end
        end
        parts[#parts + 1] = "the belt at " .. S.rect(hud) .. " (" .. n.hand .. " hands, " .. n.slot .. " slots"
            .. ((#more > 0) and (", " .. table.concat(more, ", ")) or "") .. ")"
    else
        parts[#parts + 1] = "no belt drawn"
    end
    local onBelt = S.WA.beltWatch and S.WA.beltWatch(S.p) or nil
    local wi = S.WA.getInstance and S.WA.getInstance() or nil
    local place = S.watchWord(S.St.watchPlaceOption:getValue())
    if onBelt then parts[#parts + 1] = "the watch on the belt (the Watch option " .. place .. ")"
    elseif wi and wi:getIsVisible() and wi:getWidth() > 0 then parts[#parts + 1] = "the watch at " .. S.rect(wi) .. " (the Watch option as the staging left it: " .. place .. ")"
    else parts[#parts + 1] = "no watch drawn" end
    local pr = S.HS.prompts and S.HS.prompts(S.pn) or nil
    parts[#parts + 1] = "the hint strip " .. ((pr and #pr > 0) and ("offers " .. S.hintWords(pr)) or "offers nothing (nothing to do in front of him)")
    return table.concat(parts, "; ")
end
function S.vis(e) return (e ~= nil and e:getIsVisible()) and "shown" or "hidden" end
function S.vanillaLine()
    local col = ISEquippedItem and ISEquippedItem.instance or nil
    return "the game's own inventory page " .. S.vis(getPlayerInventory(S.pn)) .. ", its loot page " .. S.vis(getPlayerLoot(S.pn))
        .. ", its left-edge buttons " .. S.vis(col)
end
-- every UI element drawn on the screen now, by name
function S.uiNames()
    local out = {}
    local sw, sh = S.scr()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local e = ui:get(i)
        if e and e:isVisible() then
            local x, y, w, h = e:getX(), e:getY(), e:getWidth(), e:getHeight()
            if w > 0 and h > 0 and x < sw and y < sh and x + w > 0 and y + h > 0 then
                local nm = nil
                local t = e:getTable()
                if t then nm = t._zedLabel or t.Type end
                if not nm then nm = e:getClass():getSimpleName() end
                out[#out + 1] = tostring(nm) .. " " .. S.fl(x) .. "," .. S.fl(y) .. " " .. S.fl(w) .. "x" .. S.fl(h)
            end
        end
    end
    return out
end
-- the belt's box kinds this script knows (ZeD_Belt.lua:1003 _layout, :505: the watch, the hands, the slots, the ammo
-- tab, the Messages note, the chat key, the PvP marker); any other kind is named in a NOTE (a box added since, such as
-- one that opens the windows or sets the speed, is looked at in the picture, not passed over), and so is every box
-- added through ZeD.Belt.addBox (kind "extra", ZeD_Belt.lua:473 and :975), by its id: another mod's, or a new one
S.KINDS = { watch = true, hand = true, slot = true, ammo = true, lamp = true, chat = true, pvp = true }
function S.kindsNote()
    local hud = S.BT.getHUD and S.BT.getHUD(S.pn) or nil
    local out = {}
    for _, b in ipairs((hud and hud._boxes) or {}) do
        local k = tostring(b.kind)
        if k == "extra" then out[#out + 1] = "a box added through ZeD.Belt.addBox, id " .. tostring(b.id)
        elseif not S.KINDS[k] then out[#out + 1] = k end
    end
    if #out == 0 then return "" end
    return "; NOTE the belt carries a box this script does not know (" .. table.concat(out, ", ") .. "): look whether it opens the windows or sets the speed"
end
-- the watch worn, as ZeD_Watch.lua:264 _wornScan finds it
function S.wornWatch()
    local wi = S.p:getWornItems()
    if not wi then return nil end
    for i = 0, wi:size() - 1 do
        local w = wi:get(i)
        local it = w and w:getItem() or nil
        if it and instanceof(it, "AlarmClockClothing") then return it end
    end
    return nil
end
-- the belt's watch box (ZeD_Belt.lua:1025, drawn at :2149) and the belt
function S.watchBox()
    local hud = S.BT.getHUD and S.BT.getHUD(S.pn) or nil
    if not (hud and hud._drawn and hud:getIsVisible()) then return nil, nil end
    for _, b in ipairs(hud._boxes or {}) do
        if b.kind == "watch" then return b, hud end
    end
    return nil, hud
end
-- the pushers' boxes in screen px, from WatchMini.lua:212 M.hit: a digital case's SPEED texels x 0-5 and START 38-43,
-- rows 16-29; a round case's SPEED x 0-9 and START 33-43, rows 28-39; the art drawn at M.zoom() px a texel (:71)
function S.pushers(b, hud)
    local ck = S.WM.zoom()
    local X, Y = hud:getAbsoluteX() + b.x, hud:getAbsoluteY() + b.y
    local spec = S.WM.SPEC and S.WM.SPEC[b.plate] or nil
    if spec and spec.kind == "digital" then
        return { X, Y + 16 * ck, 6 * ck, 14 * ck }, { X + 38 * ck, Y + 16 * ck, 6 * ck, 14 * ck }, ck, true
    end
    return { X, Y + 28 * ck, 10 * ck, 12 * ck }, { X + 33 * ck, Y + 28 * ck, 11 * ck, 12 * ck }, ck, false
end

-- ===================================================================== helpers: the Craft tab (bxr_craft.lua)
function S.cst() local w = S.WW(); return w and w._craftState or nil end
function S.data() local w = S.WW(); return w and w._craftCache or nil end
function S.row(name) local d = S.data(); return d and d.byName and d.byName[name] or nil end
function S.zoneOf(kind, pred)
    local st = S.cst()
    for _, z in ipairs((st and st.zones) or {}) do
        if z.type == kind and z.w > 0 and z.h > 0 and (pred == nil or pred(z)) then return z end
    end
    return nil
end
function S.pressZone(z)
    if not z then return false end
    local ok, e = pcall(S.CT.onClick, S.WW(), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    if not ok then Q.say("ERR click: " .. tostring(e)) end
    return ok
end
function S.tabShowing() return S.WWm.isTabShowing("craft", S.pn) and true or false end
-- the list scrolled so the recipe's row is in the middle of its view
function S.rowIntoView(name)
    local st = S.cst()
    local g = st and st._listGeo
    local z = S.zoneOf("recipeRow", function(zz) return zz.id == name end)
    if not (g and z and st.scroll and st.scroll.setScrollPos) then return false end
    local span = (g.totalH or 0) - (g.viewH or 0)
    if span <= 0 then return true end
    local off = math.floor((st.scroll.scrollPos or 0) * span)
    local want = (z.y - g.viewY + off) - math.floor((g.viewH - z.h) / 2)
    if want < 0 then want = 0 end
    if want > span then want = span end
    st.scroll:setScrollPos(want / span)
    return true
end
-- a recipe's card opened as a click on its row does (from code when the row is out of view)
function S.openCard(name)
    local st = S.cst()
    if not (st and S.row(name)) then return false end
    if st.altSlotName then S.CC.exitAltMode(st) end
    if st.selected ~= name then
        local z = S.zoneOf("recipeRow", function(zz) return zz.id == name end)
        local lg = st._listGeo
        if z and lg and z.y >= lg.viewY and z.y + z.h <= lg.viewY + lg.viewH then S.pressZone(z) else S.CC.openCraft(st, name) end
    end
    return st.selected == name
end
function S.cardUp(name)
    local st, rd = S.cst(), S.row(name)
    return st ~= nil and rd ~= nil and st.selected == name and rd.ingredients ~= nil
        and (st.splitTarget or 1) == 1 and (st.splitFrac or 1) >= 0.99
end
function S.ready(rd) return (rd ~= nil and rd.status == "craftable" and rd.canStart == true) and true or false end
function S.readyWord(rd) return "list status " .. tostring(rd and rd.status) .. ", Craft lit " .. tostring(rd ~= nil and rd.canStart == true) end
function S.reqLine(rd)
    local n = #((rd and rd.ingredients) or {})
    return "Required " .. tostring(n - ((rd and rd.missingCount) or 0)) .. "/" .. n
end
-- the lists asked again now (as a drop or a pick-up makes them): the World window's strip, the card's counts
function S.recount()
    local w = S.WW()
    if not w then return end
    w._containersDirty = true
    w._craftContainerAt = nil
    w._craftLogicAt = nil
end
-- the containers the Craft tab counts from (CraftingCore.lua:162 CC.craftContainers: the game's list for its craft
-- window, the inventory, the bags, the floor and the containers in the game's 3 x 3 reach), with what each holds
function S.contLine()
    local l = S.CC.craftContainers(S.p)
    if not l then return "?" end
    local parts = {}
    for i = 0, l:size() - 1 do
        local c = l:get(i)
        if c then parts[#parts + 1] = tostring(c:getType()) .. " (" .. c:getItems():size() .. ")" end
    end
    return table.concat(parts, ", ")
end
function S.listHolds(c)
    local l = S.CC.craftContainers(S.p)
    if not (l and c) then return false end
    for i = 0, l:size() - 1 do if l:get(i) == c then return true end end
    return false
end
-- the containers of that list that are not his (not his inventory or a bag he carries, ItemContainer
-- isInCharacterInventory, and not the floor): a shelf, crate, fridge or car part in the game's reach, by kind
function S.worldConts()
    local l = S.CC.craftContainers(S.p)
    local out = {}
    if not l then return out end
    for i = 0, l:size() - 1 do
        local c = l:get(i)
        if c and c:getType() ~= "floor" and not c:isInCharacterInventory(S.p) then out[#out + 1] = tostring(c:getType()) end
    end
    return out
end
-- the list read by the game at least once, six seconds after the key, and the same length for 2.5 s (the game's
-- answers come every 1.2 s, CraftingCore.lua:444 logicScan; the quick scan every 5 s)
function S.listSteady(t)
    local w = S.WW()
    local st = w and w._craftState or nil
    if not (st and S.tabShowing() and w._craftCache and w._craftLogicAt and st.filteredCache and st.filterDirty == false) then
        t.lastN, t.since = nil, nil
        return false
    end
    local n = #st.filteredCache
    local now = getTimestampMs()
    if t.lastN ~= n then t.lastN, t.since = n, now; return false end
    return now - (t.t0 or now) >= 6000 and now - (t.since or now) >= 2500
end
-- His pinned recipes aside for 17: a pinned recipe stays listed under any Show (CraftingCore.lua:1148), and a new
-- character has none. Kept in his modData (ZeD_CraftPins), read when a new World window's Craft tab first draws
-- (CraftingCore.lua:3294, CC.loadPins :672); put back exactly as found once that window has shut
function S.craftPinsAside()
    local md = S.p:getModData()
    local pins = md.ZeD_CraftPins
    if not S.was.craftPinsSet then S.was.craftPinsSet, S.was.craftPins = true, S.copy(pins) end
    md.ZeD_CraftPins = nil
    return (type(pins) == "table") and #pins or 0
end
function S.craftPinsBack()
    if not S.was.craftPinsSet then return end
    S.p:getModData().ZeD_CraftPins = S.copy(S.was.craftPins)
    S.was.craftPinsSet, S.was.craftPins = nil, nil
end
-- 35: the Surface badge as the card draws it. ZeD.Atoms.drawBadge (Atoms.lua:1027) is called through the table every
-- frame by the card's chip row (CraftingCore.lua:3071, A.drawBadge(panel, "Surface", x, y, "warning"), A = ZeD.Atoms
-- fetched as the card draws): watched while the card is up, every call goes on to the real one with its arguments and
-- gives back what it gives, and the last Surface badge drawn is kept with its variant ("warning": the amber square) and
-- its box on the screen. Off puts the real one back
function S.badgeWatch(on)
    local A = ZeD.Atoms
    if on then
        if S.badgeOrig or not (A and A.drawBadge) then return end
        S.badgeOrig = A.drawBadge
        S.surfWord = tostring(ZeD.tr("IGUI_CraftingWindow_Surface"))
        S.badge = nil
        A.drawBadge = function(...)
            local panel, text, x, y, variant = ...
            local w, h = S.badgeOrig(...)
            if text == S.surfWord and panel then
                S.badge = { variant = variant, x = panel:getAbsoluteX() + x, y = panel:getAbsoluteY() + y, w = w or 0, h = h or 0, at = getTimestampMs() }
            end
            return w, h
        end
        return
    end
    if S.badgeOrig and A then A.drawBadge = S.badgeOrig end
    S.badgeOrig = nil
end
-- a recipe made on any surface (CraftingTab.lua:108 needSurface: recipe:isAnySurfaceCraft) and what to give for it:
-- Drill Plank (a plank or a log; a screwdriver or a knife, kept), as bxr_craft.lua's B6-14; else the first one he knows,
-- made by hand, whose every input can be given (one type each, 4 at most, 6 things in all)
function S.surfaceRecipe()
    local rd = S.row(S.DRILL)
    if rd and rd.entry and rd.entry.needSurface and not rd.entry.stationInfo and rd.status ~= "locked" then
        return S.DRILL, { S.PLANK, S.SCREW }
    end
    local d = S.data()
    for _, r in ipairs((d and d.recipes) or {}) do
        local e = r.entry
        if e and e.needSurface and not e.stationInfo and r.status ~= "locked" then
            local give, ok = {}, true
            for _, inp in ipairs(e.inputDefs or {}) do
                local names = {}
                for k in pairs(inp.validTypes or {}) do names[#names + 1] = k end
                table.sort(names)
                local amt = inp.amount or 1
                if #names == 0 or amt > 4 then ok = false; break end
                for _ = 1, amt do give[#give + 1] = names[1] end
            end
            if ok and #give > 0 and #give <= 6 then return e.name, give end
        end
    end
    return nil, nil
end

-- ===================================================================== helpers: his things, placed things, a station
function S.isMade(it)
    for _, m in ipairs(S.made) do if m == it then return true end end
    return false
end
-- loose: not on the belt, not worn, not held (bxr_craft.lua)
function S.loose(it)
    return it:getAttachedSlot() == -1 and not it:isEquipped() and not S.p:isEquipped(it) and not S.p:isEquippedClothing(it)
        and S.p:getPrimaryHandItem() ~= it and S.p:getSecondaryHandItem() ~= it
end
function S.setAside(it)
    local c = it:getContainer()
    if not c then return false end
    c:Remove(it)
    S.aside[#S.aside + 1] = { it = it, c = c }
    return true
end
function S.asideBack()
    local lost = 0
    for _, e in ipairs(S.aside) do
        if e.it:getContainer() == nil then e.c:AddItem(e.it) end
        if e.it:getContainer() == nil then lost = lost + 1 end
    end
    local n = #S.aside
    S.aside = {}
    return n, lost
end
-- the gallery rule: never over the weight limit. His own loose things go aside (heaviest first) until the load is a
-- kilo under it; they come back in the put-back
function S.lighten()
    local max = S.maxLoad()
    local n = 0
    for _ = 1, 40 do
        if S.load() <= max - 1 then break end
        local best, bw = nil, 0
        local items = S.p:getInventory():getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            local w = it:getUnequippedWeight()
            if w > bw and not S.isMade(it) and S.loose(it) and not instanceof(it, "InventoryContainer") then best, bw = it, w end
        end
        if not (best and S.setAside(best)) then break end
        n = n + 1
    end
    Q.say(string.format("load %.1f of %.1f kg%s", S.load(), max, (n > 0) and (" (" .. n .. " of his own things set aside for the weight)") or ""))
end
function S.removeObj(obj)
    if not obj then return end
    local sq = obj:getSquare()
    if not sq then return end
    sq:transmitRemoveItemFromSquare(obj)
    if obj:getObjectIndex() >= 0 then sq:RemoveTileObject(obj) end
end
-- the bare squares beside (x, y) he can reach, never between him and the camera (S.SLOTS)
function S.slotsAt(x, y)
    local c = S.sqAt(x, y)
    local out = {}
    if not c then return out end
    for _, o in ipairs(S.SLOTS) do
        local sq = S.goodSq(S.sqAt(x + o[1], y + o[2]))
        if sq and c:canReachTo(sq) then out[#out + 1] = sq end
    end
    return out
end
-- a table the game itself takes as a crafting surface (bxr_craft.lua S.setTable)
function S.setTable(sq)
    for _, name in ipairs(S.TABLES) do
        if not S.tableObj and getSprite(name) then
            local o = IsoObject.new(getCell(), sq, name)
            if o then
                sq:AddTileObject(o)
                if S.p:canUseAsGenericCraftingSurface(o) then S.tableObj, S.tableSprite = o, name else S.removeObj(o) end
            end
        end
    end
    return S.tableObj ~= nil
end
function S.surface()
    if not (ISEntityUI and ISEntityUI.FindCraftSurface) then return nil end
    return ISEntityUI.FindCraftSurface(S.p, 2)
end
-- a bare square in the open 6 to 9 squares from (x, y), never toward the camera (dx + dy < 0: behind him on the screen),
-- the nearest to 7 out; far outside the game's 3 x 3 loot reach (ISInventoryPage:refreshBackpacks)
function S.crateSq(x, y)
    local best, bd = nil, 1e9
    for dy = -9, 9 do
        for dx = -9, 9 do
            local d = math.max(math.abs(dx), math.abs(dy))
            if d >= 6 and dx + dy < 0 then
                local sq = S.goodSq(S.sqAt(x + dx, y + dy))
                if sq and math.abs(d - 7) < bd then best, bd = sq, math.abs(d - 7) end
            end
        end
    end
    return best
end
-- a crate with its container (bxr_craft.lua S.setCrate)
function S.setCrate(sq)
    if not (sq and getSprite(S.CRATE)) then return false end
    local o = IsoObject.new(getCell(), sq, S.CRATE)
    if not o then return false end
    o:createContainersFromSpriteProperties()
    sq:AddTileObject(o)
    local c = o:getContainer()
    if not c then S.removeObj(o); return false end
    c:setExplored(true)
    S.crateObj, S.crate = o, c
    return true
end
-- his main inventory's loose things into the crate; the list, for the way back
function S.moveLoose(crate)
    local inv = S.p:getInventory()
    local list, moved = {}, {}
    local items = inv:getItems()
    for i = 0, items:size() - 1 do list[#list + 1] = items:get(i) end
    for _, it in ipairs(list) do
        if S.loose(it) and not S.isMade(it) then
            inv:Remove(it)
            crate:AddItem(it)
            moved[#moved + 1] = it
        end
    end
    return moved
end
-- each one back into his main inventory, wherever it is now
function S.moveBack(list)
    local inv = S.p:getInventory()
    local back, lost = 0, 0
    for _, it in ipairs(list or {}) do
        local c = it:getContainer()
        if c ~= inv then
            if c then c:Remove(it) end
            inv:AddItem(it)
        end
        if it:getContainer() == inv then back = back + 1 else lost = lost + 1 end
    end
    return back, lost
end
-- the crate (only empty: what is in it would go with it) and the table off the patch
function S.objsBack()
    if S.crateObj then
        local left = S.crate and S.crate:getItems():size() or 0
        if left == 0 then
            S.removeObj(S.crateObj)
            S.crateObj, S.crate = nil, nil
        else
            Q.say("NOTE the crate still holds " .. left .. " things: it is left standing")
        end
    end
    if S.tableObj then S.removeObj(S.tableObj); S.tableObj = nil end
end
-- a bound station puts its own view in the Craft tab: unbound for the Craft pictures, bound again after (bxr_craft.lua)
function S.unbindStation()
    local ST = ZeD.Stations
    if not (ST and ST.current and ST.unbind) then return end
    local cur = ST.current(S.p)
    if cur then
        if not S.was.station then S.was.station = cur end
        ST.unbind(S.p)
        Q.say("a station was bound: unbound for the Craft pictures, bound again at the end")
    end
end
function S.rebindStation()
    local ST = ZeD.Stations
    if S.was.station and ST and ST.bind then ST.bind(S.p, S.was.station) end
    S.was.station = nil
end
-- 22's settings and the watch given back (safe to call twice)
function S.p22Back()
    local t = S.p22
    if t.watchSet then S.St.watchPlaceOption:setValue(t.watch0); t.watchSet = nil end
    if t.styleSet then S.St.lookStyleOption:setValue(t.style0); t.styleSet = nil end
    if t.given then
        S.p:removeWornItem(t.given, false)
        local c = t.given:getContainer()
        if c then c:Remove(t.given) end
        triggerEvent("OnClothingUpdated", S.p)
        t.given = nil
    end
end
-- 17's things back: the World window shut, his loose things from the crate, the crate, the knife, the station
function S.p17Back()
    local t = S.p17
    local back, lost = S.moveBack(t.moved)
    local n = #(t.moved or {})
    t.moved = {}
    S.takeMade()
    S.objsBack()
    S.rebindStation()
    if n > 0 then Q.say(S.N17 .. ": put back: " .. back .. " of his " .. n .. " things back in his inventory from the crate, not back " .. lost .. "; the crate removed, the knife taken") end
end

-- ===================================================================== start
Q.step(5, function()
    S.start0()
    S.speed(1)
    S.was.zoom = S.zoom()
    local md = S.p:getModData()
    S.was.winState = S.copy(md.ZeD_WinState)
    S.was.pinT = S.copy(md.ZeD_WinPinned)
    S.was.cOpen, S.was.wOpen = S.CWm.isOpen(S.pn), S.WWm.isOpen(S.pn)
    S.was.h1, S.was.h2 = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    -- the mouse and keyboard's input mode for the run, put back as found at the end
    S.lock("kbm")
    local cpi, cpd = S.pinsFrom(S.was.pinT, "char")
    local c = S.P.smoke or S.P.centre
    S.c = c and S.findPatch(c[1], c[2]) or nil
    if not S.c then
        Q.say("ERR no open patch within 14 squares of the smoking spot: every picture is skipped")
        return
    end
    S.allShut()
    S.home("SE")
    Q.say("the patch's middle " .. S.where() .. " (the smoking spot " .. c[1] .. "," .. c[2] .. "), bare from " .. S.c.lo .. " to 2 round it"
        .. " | the pair open " .. tostring(S.was.cOpen) .. "/" .. tostring(S.was.wOpen) .. ", the Character window's saved pins: inventory half "
        .. tostring(cpi) .. ", tab half " .. tostring(cpd) .. " | Style " .. tostring(S.St.lookStyleOption:getValue()) .. ", Watch "
        .. S.watchWord(S.St.watchPlaceOption:getValue()) .. ", input lock found " .. tostring(S.lockWas) .. " | zoom " .. tostring(S.was.zoom)
        .. " | load " .. ((GAL_UNLOAD and GAL_UNLOAD.line) and GAL_UNLOAD.line() or "?"))
end)
Q.zoomTo(1.0)
S.settle(function() return S.c ~= nil end)

-- ===================================================================== 09: the page rolls away by itself
-- Both windows shut, the Character window's pins at ZeD's default (no saved pins: today both halves load unpinned; the
-- pins are the setting the picture is about), the pointer out in the world before the key, as a player's is while he
-- plays. H: the pair opens on Health (the World window as the staging pins it). Each unpinned half rolls 2 s after the
-- pointer leaves it (WindowHalves.lua:830, H.COLLAPSE_MS); both rolled, the whole window rolls to its title bar (:573).
-- Nothing else is done. (The task named the tab half; with the inventory half left pinned only the Health drawer folds,
-- :600-606, and the window never rolls to its bar, so both halves take ZeD's default, as a new character's do.)
Q.step(10, function()
    local t = S.p9
    if not S.c then S.skip(S.N09, "no open patch near the smoking spot"); t.off = true; return end
    S.allShut()
    S.home("SE")
    S.defaultPlaces()
    if not S.pinsDefault() then S.skip(S.N09, "the Character window would not shut: its pins cannot be set to ZeD's default (" .. S.winLine() .. ")"); t.off = true; return end
    t.pt = S.worldPoint()
    S.mouseOn(t.pt[1], t.pt[2])
    Q.say(S.N09 .. ": both windows shut, the Character window's saved pins cleared (ZeD's default, as a new character has them); the pointer the game's Lua reads parked out in the world at "
        .. t.pt[1] .. "," .. t.pt[2])
end)
S.settle(function() return not S.p9.off end)
Q.step(5, function()
    local t = S.p9
    if t.off then return end
    t.r0 = S.route()
    t.ok, t.key = S.pressKey(KeybindId.TOGGLE_HEALTH_PANEL)
    t.t0 = getTimestampMs()
    t.viaZeD = S.route() > t.r0
    if not t.ok then S.skip(S.N09, "the game's Health key did nothing: " .. tostring(t.key)); t.off = true end
end)
S.wait(5000, function() return S.p9.off or S.healthUp() end, function(ok)
    local t = S.p9
    if t.off then return end
    t.upMs = getTimestampMs() - t.t0
    if not ok then S.skip(S.N09, "H did not open the pair on Health in 5 s (" .. S.winLine() .. "; game speed " .. tostring(getGameSpeed()) .. ": the game's handler does nothing while paused)"); t.off = true; return end
    Q.say(S.N09 .. ": H (" .. tostring(t.key) .. ") opened " .. S.winLine() .. " in " .. S.fl(t.upMs) .. " ms; " .. S.halvesLine(S.CW())
        .. "; the World window's " .. S.halvesLine(S.WW()))
end)
S.wait(9000, function() local w = S.CW(); return S.p9.off or (w ~= nil and w.windowShaded == true) end, function(ok)
    local t = S.p9
    if t.off then return end
    t.rollMs = getTimestampMs() - t.t0
    if not ok then
        local pad = JoypadState and JoypadState.players and JoypadState.players[S.pn + 1] ~= nil
        S.skip(S.N09, "with ZeD's default pins the Character window did not roll up in 9 s with the pointer out in the world, the page stays: the friction is not there ("
            .. S.cLine() .. "; " .. S.halvesLine(S.CW()) .. "; a controller bound " .. tostring(pad) .. ": with one the halves never roll by themselves)")
        t.off = true
    end
end)
Q.still(5, function() if not S.p9.off then S.worldClear() end end)
S.wait(4000, function() return S.p9.off or S.quiet() end, function() end)
Q.step(3, function()
    local t = S.p9
    if t.off then return end
    local w = S.CW()
    if not (w and w.windowShaded) then S.skip(S.N09, "the Character window came down again before the picture (" .. S.halvesLine(w) .. ")"); return end
    S.shotOk(S.N09, "both windows shut and the pointer the game's Lua reads out in the world at " .. t.pt[1] .. "," .. t.pt[2] .. " (under it: "
        .. S.under(t.pt[1], t.pt[2]) .. "), H pressed (the game's Health key " .. tostring(t.key) .. ", its own handler into ZeD's toggleView hook, which took it: "
        .. tostring(t.viaZeD) .. "): the pair opened on Health in "
        .. S.fl(t.upMs) .. " ms; with nothing more done, " .. S.fl(t.rollMs) .. " ms after the press the Character window rolled to its title bar at the top of the screen ("
        .. S.rect(w) .. "), the Health page gone, " .. S.titleLine(w) .. "; " .. S.halvesLine(w)
        .. "; the Character window's pins at ZeD's default (no saved pins, as a new character has; the staging pins both halves); " .. S.wLine()
        .. ", pinned as the staging pins it (" .. S.halvesLine(S.WW()) .. "); him on the open patch at " .. S.where() .. ", picture "
        .. S.fl(getTimestampMs() - t.t0) .. " ms after the press")
end)
Q.step(5, function()
    local inv, drw = S.pinsBack()
    S.mouseOff()
    Q.say(S.N09 .. ": the Character window's pins back as the staging had them (inventory half " .. tostring(inv) .. ", tab half " .. tostring(drw)
        .. "); " .. S.halvesLine(S.CW()))
end)
Q.step(10, function() S.allShut() end)

-- ===================================================================== 16: nothing on screen opens the windows
Q.step(10, function()
    local t = S.p16
    if not S.c then S.skip(S.N16, "no open patch near the smoking spot"); t.off = true; return end
    t.shut = S.allShut()
    S.home("SE")
    -- (the pointer the game's Lua reads off every HUD: no belt balloon under a resting pointer)
    S.mouseOn(-9000, -9000)
end)
S.settle(function() return not S.p16.off end)
S.wait(1500, function() return false end, function() end)
S.wait(4000, function() return S.p16.off or S.quiet() end, function() end)
Q.step(3, function()
    local t = S.p16
    if t.off then return end
    if S.CWm.isOpen(S.pn) or S.WWm.isOpen(S.pn) then S.skip(S.N16, "a window is still open: " .. S.winLine()); return end
    -- (the gallery rule first, as the picture takes it, so the list of what is on the screen is the picture's: G1.clean)
    G1.clean(Q)
    local shut = (t.shut and #t.shut > 0) and (" (shut for it: " .. table.concat(t.shut, ", ") .. ")") or ""
    S.shotOk(S.N16, "every ZeD window and menu shut" .. shut .. ", him on the open patch at " .. S.where() .. " facing the camera, zoom " .. tostring(S.zoom())
        .. ", nothing staged: " .. S.hudLine() .. "; " .. S.vanillaLine() .. "; on the screen: " .. table.concat(S.uiNames(), ", ") .. S.kindsNote())
end)
Q.step(5, function() S.mouseOff() end)

-- ===================================================================== 17: Craft opens on an empty list
-- On the open patch (bare squares round him: no container, shelf, crate, table or thing on the floor in the game's 3 x 3
-- reach), his main inventory's loose things moved into a crate placed 6 to 9 squares behind him, a kitchen knife given.
-- B: the World window opens on Craft, a new window's Craft tab on Show: Ready (CraftingCore.lua:1010 showMode, :1495
-- createState). What the bags and the belt hold stays with him (the tab counts them: their kinds in the line)
Q.step(10, function()
    local t = S.p17
    if not S.c then S.skip(S.N17, "no open patch near the smoking spot"); t.off = true; return end
    S.allShut()
    S.home("SE")
    S.unbindStation()
    local sq = S.crateSq(S.c.x, S.c.y)
    if not (sq and S.setCrate(sq)) then S.skip(S.N17, "no bare square 6 to 9 squares behind him for the crate, or no crate could be placed"); t.off = true; return end
    t.cx, t.cy = sq:getX(), sq:getY()
    t.moved = S.moveLoose(S.crate)
    t.knife = S.add(S.KNIFE)
    if not t.knife then S.skip(S.N17, "no kitchen knife could be given"); t.off = true; return end
    S.defaultPlaces()
    t.pins = S.craftPinsAside()
    S.mouseOn(-9000, -9000)
    Q.say(S.N17 .. ": " .. #t.moved .. " loose things of his main inventory moved into a crate at " .. t.cx .. "," .. t.cy .. ", a kitchen knife given, "
        .. t.pins .. " pinned recipes set aside")
end)
S.settle(function() return not S.p17.off end)
Q.step(5, function()
    local t = S.p17
    if t.off then return end
    t.ok, t.key = S.pressKey(KeybindId.CRAFTING_UI)
    t.t0 = getTimestampMs()
    if not t.ok then S.skip(S.N17, "the game's crafting key did nothing: " .. tostring(t.key)); t.off = true end
end)
S.wait(15000, function() return S.p17.off or S.listSteady(S.p17) end, function(ok)
    local t = S.p17
    if t.off then return end
    if not ok then S.skip(S.N17, "B did not bring up the Craft tab with a steady list in 15 s (" .. S.wLine() .. ", the tab showing " .. tostring(S.tabShowing()) .. ", game speed " .. tostring(getGameSpeed()) .. ")"); t.off = true; return end
    local st = S.cst()
    -- (a new window's tab: Show Ready, no search, every category, no card; set so only if something else changed them)
    if S.CC.showMode(st, nil) ~= "ready" or (st.search or "") ~= "" or (st.activeCat or "all") ~= "all" or st.selected then
        t.was = { show = st.show, showAll = st.showAll, search = st.search, cat = st.activeCat }
        t.reset = "NOTE the tab was not at its defaults (Show " .. tostring(S.CC.showMode(st, nil)) .. ", search \"" .. tostring(st.search) .. "\", category "
            .. tostring(st.activeCat) .. ", card " .. tostring(st.selected) .. "): set to Show Ready, no search, All, no card"
        if st.selected then S.CC.closeCraft(st) end
        S.CC.setShow(st, "ready")
        st.search, st.activeCat, st.filterDirty = "", "all", true
        Q.say(S.N17 .. ": " .. t.reset)
    end
end)
Q.still(5, function() if not S.p17.off then S.worldClear() end end)
S.wait(4000, function() return S.p17.off or S.quiet() end, function() end)
Q.step(3, function()
    local t = S.p17
    if t.off then return end
    local st = S.cst()
    if not (st and S.tabShowing()) then S.skip(S.N17, "the Craft tab is not showing (" .. S.wLine() .. ")"); return end
    local rows = {}
    for i, rd in ipairs(st.filteredCache or {}) do
        if i <= 12 then rows[#rows + 1] = tostring(rd.entry and rd.entry.displayName) end
    end
    local n = #(st.filteredCache or {})
    local list = (n == 0) and ("the list reads its empty line \"" .. tostring(S.CC.emptyListText(st, nil)) .. "\"")
        or ("NOTE " .. n .. " recipe(s) still show on Ready: " .. table.concat(rows, ", ") .. ((n > 12) and ", ..." or ""))
    local d = math.max(math.abs(t.cx - S.c.x), math.abs(t.cy - S.c.y))
    -- (what is in his reach, as the tab and the game read it: a container that is not his, a table or counter)
    local wc = S.worldConts()
    local reach = ((#wc == 0) and "no container in the game's 3 x 3 reach" or ("NOTE a container in the game's reach: " .. table.concat(wc, ", ")))
        .. ((S.surface() == nil) and " and no table or counter within 2 squares" or " and NOTE a table or counter within 2 squares (ISEntityUI.FindCraftSurface)")
    S.shotOk(S.N17, "the crafting key B (" .. tostring(t.key) .. ", the game's handler into ZeD's OpenHandcraftWindow hook) opened " .. S.wLine()
        .. "; him on the open patch at " .. S.where() .. " with " .. reach .. ", his " .. #t.moved
        .. " loose things of the main inventory in a crate placed at " .. t.cx .. "," .. t.cy .. ", " .. d .. " squares behind him (in the tab's container list "
        .. tostring(S.listHolds(S.crate)) .. "), a kitchen knife given, his " .. tostring(t.pins) .. " pinned recipes set aside (a new character has none)"
        .. "; the tab counts from: " .. S.contLine() .. "; Show: "
        .. tostring(S.CC.showMode(st, nil)) .. " (the tab's default) at its foot, no search, category " .. tostring(st.activeCat) .. "; " .. list
        .. (t.reset and ("; " .. t.reset) or ""))
end)
Q.step(5, function()
    local t = S.p17
    local st = S.cst()
    -- (the tab as it was, should it not have been at its defaults)
    if t.was and st then st.show, st.showAll, st.search, st.activeCat, st.filterDirty = t.was.show, t.was.showAll, t.was.search, t.was.cat, true end
    S.mouseOff()
    S.allShut()
    S.p17Back()
    S.craftPinsBack()
end)

-- ===================================================================== 22: the game's speed in the belt watch's pushers
-- Style Full and the Watch on the belt, ZeD's defaults (Settings.lua:607 lookStyle, :278 watchPlace), set for the picture
-- where they are not; a digital wrist watch worn (the story's kit wears a CaZio, gallery_story_stage.lua:500). Both
-- windows shut: the whole screen, the HUD alone
Q.step(10, function()
    local t = S.p22
    if not S.c then S.skip(S.N22, "no open patch near the smoking spot"); t.off = true; return end
    S.allShut()
    S.home("SE")
    t.style0, t.watch0 = S.St.lookStyleOption:getValue(), S.St.watchPlaceOption:getValue()
    if t.style0 ~= 1 then S.St.lookStyleOption:setValue(1); t.styleSet = true end
    if t.watch0 ~= 1 then S.St.watchPlaceOption:setValue(1); t.watchSet = true end
    local item = S.wornWatch()
    if not item then
        t.given = S.add(S.WATCH)
        if t.given then
            S.p:setWornItem(t.given:getBodyLocation(), t.given)
            triggerEvent("OnClothingUpdated", S.p)
            item = S.wornWatch()
        end
    end
    t.item = item
    if not item then S.skip(S.N22, "no wrist watch worn, and none could be given and worn"); t.off = true; S.p22Back(); return end
    S.mouseOn(-9000, -9000)
    Q.say(S.N22 .. ": Style " .. tostring(S.St.lookStyleOption:getValue()) .. " (found " .. tostring(t.style0) .. "), Watch "
        .. S.watchWord(S.St.watchPlaceOption:getValue()) .. " (found " .. S.watchWord(t.watch0) .. "), the watch worn " .. tostring(item:getDisplayName())
        .. (t.given and " (given for the picture)" or ""))
end)
S.settle(function() return not S.p22.off end)
-- (the belt lays out again about once a second: the watch's box comes in on the next layout)
S.wait(5000, function() return S.p22.off or S.watchBox() ~= nil end, function(ok)
    local t = S.p22
    if t.off then return end
    if not ok then
        local _, plate, wrist = nil, nil, nil
        if S.WA.beltWatch then _, plate, wrist = S.WA.beltWatch(S.p) end
        S.skip(S.N22, "the belt shows no watch in 5 s (the watch's plate " .. tostring(plate) .. ", wrist " .. tostring(wrist) .. ", Lite " .. tostring(S.St.lite and S.St.lite()) .. ")")
        t.off = true
    end
end)
Q.still(5, function() end)
S.wait(4000, function() return S.p22.off or S.quiet() end, function() end)
Q.step(3, function()
    local t = S.p22
    if t.off then return end
    local b, hud = S.watchBox()
    if not (b and hud) then S.skip(S.N22, "the belt's watch box is gone"); return end
    local sp, stt, ck, digital = S.pushers(b, hud)
    local sc = UIManager.getSpeedControls and UIManager.getSpeedControls() or nil
    local speed = sc and tostring(sc:getCurrentGameSpeed()) or "?"
    local parked = sc and ((sc:getY() < 0) and "parked off the screen" or "on the screen") or "?"
    S.shotOk(S.N22, "Style " .. ((S.St.lookStyleOption:getValue() == 1) and "Full" or "Lite") .. " (ZeD's default" .. (t.styleSet and ", set for this picture" or ", as found")
        .. ") and the Watch option on the belt (ZeD's default" .. (t.watchSet and (", set for this picture: found " .. S.watchWord(t.watch0)) or ", as found") .. "), "
        .. tostring(t.item:getDisplayName()) .. " worn on his " .. tostring(b.wrist) .. " wrist" .. (t.given and " (given for the picture)" or "")
        .. ", both windows shut, him on the open patch at " .. S.where() .. ": the belt's mini watch (plate " .. tostring(b.plate) .. ", "
        .. (digital and "digital" or "round") .. ") at " .. S.box4({ hud:getAbsoluteX() + b.x, hud:getAbsoluteY() + b.y, b.w, b.h })
        .. ", its SPEED pusher at " .. S.box4(sp) .. " and its START pusher at " .. S.box4(stt) .. " (screen px, the art at " .. tostring(ck)
        .. " px a texel); the game at speed " .. speed .. ", the game's own speed buttons " .. parked .. "; " .. S.hudLine()
        .. "; on the screen: " .. table.concat(S.uiNames(), ", ") .. S.kindsNote())
end)
Q.step(5, function()
    S.p22Back()
    S.takeMade()
    S.mouseOff()
    Q.say(S.N22 .. ": put back: Style " .. tostring(S.St.lookStyleOption:getValue()) .. ", Watch " .. S.watchWord(S.St.watchPlaceOption:getValue())
        .. ", the watch worn " .. tostring(S.wornWatch() ~= nil))
end)

-- ===================================================================== 25: the second press
-- Both windows shut, at their default places, pinned as the staging pins them. H, the windows settle, H again (the
-- same handler: ZeD's toggleView hook with toggle on, Overrides/CharacterInfo.lua:60): the open Health tab pressed
-- again shuts its page (ZeD_CharacterWindow.lua:4721) and both windows stay up
Q.step(10, function()
    local t = S.p25
    if not S.c then S.skip(S.N25, "no open patch near the smoking spot"); t.off = true; return end
    S.allShut()
    S.home("SE")
    S.defaultPlaces()
    S.mouseOn(-9000, -9000)
end)
S.settle(function() return not S.p25.off end)
Q.step(5, function()
    local t = S.p25
    if t.off then return end
    t.r0 = S.route()
    t.ok, t.key = S.pressKey(KeybindId.TOGGLE_HEALTH_PANEL)
    t.t0 = getTimestampMs()
    if not t.ok then S.skip(S.N25, "the game's Health key did nothing: " .. tostring(t.key)); t.off = true end
end)
S.wait(5000, function() return S.p25.off or S.healthUp() end, function(ok)
    local t = S.p25
    if t.off then return end
    if not ok then S.skip(S.N25, "the first H did not open the pair on Health in 5 s (" .. S.winLine() .. "; game speed " .. tostring(getGameSpeed()) .. ")"); t.off = true; return end
end)
Q.still(5, function()
    local t = S.p25
    if t.off then return end
    t.first = S.winLine()
    Q.say(S.N25 .. ": after the first H (" .. tostring(t.key) .. "): " .. t.first)
end)
Q.step(5, function()
    local t = S.p25
    if t.off then return end
    t.ok2 = S.pressKey(KeybindId.TOGGLE_HEALTH_PANEL)
    t.t1 = getTimestampMs()
    if not t.ok2 then S.skip(S.N25, "the second H did nothing"); t.off = true end
end)
S.wait(4000, function() local w = S.CW(); return S.p25.off or w == nil or not (w._activeTab == "health" and S.pageOpen(w)) end, function(ok)
    local t = S.p25
    if t.off then return end
    t.changed = ok
end)
Q.still(5, function() if not S.p25.off then S.clearChar() end end)
S.wait(4000, function() return S.p25.off or S.quiet() end, function() end)
Q.step(3, function()
    local t = S.p25
    if t.off then return end
    local c, w = S.CW(), S.WW()
    if not (c and w) then S.skip(S.N25, "after the second H a window is gone (" .. S.winLine() .. "): the second press put the windows away, the friction is not there"); return end
    S.shotOk(S.N25, "both windows shut, H (the game's Health key " .. tostring(t.key) .. ", its own handler into ZeD's toggleView hook, which took both presses: "
        .. tostring(S.route() - (t.r0 or 0) >= 2) .. ") pressed: " .. tostring(t.first)
        .. "; once they had settled, H pressed again: " .. S.winLine() .. (t.changed and "" or " (NOTE the second press changed nothing in 4 s)")
        .. "; both windows still up after the second press; him on the open patch at " .. S.where())
end)
Q.step(5, function()
    S.mouseOff()
    S.allShut()
end)

-- ===================================================================== 35: the amber Surface badge
-- A table placed beside him (never between him and the camera), the game taking it as a crafting surface; B: the Craft
-- tab; Drill Plank (or another any-surface recipe he knows) and what it takes given; its card open with Craft lit. The
-- chip row's Surface badge is drawn for every any-surface recipe, table or not (CraftingCore.lua:3068, "warning")
Q.step(10, function()
    local t = S.p35
    if not S.c then S.skip(S.N35, "no open patch near the smoking spot"); t.off = true; return end
    S.allShut()
    S.home("SE")
    S.unbindStation()
    local slots = S.slotsAt(S.c.x, S.c.y)
    if not (slots[1] and S.setTable(slots[1])) then S.skip(S.N35, "no table the game takes as a crafting surface could be placed beside him"); t.off = true; return end
    t.tx, t.ty = slots[1]:getX(), slots[1]:getY()
    t.surf = S.surface()
    S.defaultPlaces()
    S.mouseOn(-9000, -9000)
    Q.say(S.N35 .. ": table " .. tostring(S.tableSprite) .. " placed at " .. t.tx .. "," .. t.ty .. "; the game finds a crafting surface " .. tostring(t.surf ~= nil))
end)
S.settle(function() return not S.p35.off end)
Q.step(5, function()
    local t = S.p35
    if t.off then return end
    t.ok, t.key = S.pressKey(KeybindId.CRAFTING_UI)
    if not t.ok then S.skip(S.N35, "the game's crafting key did nothing: " .. tostring(t.key)); t.off = true end
end)
S.wait(12000, function()
    if S.p35.off then return true end
    local st = S.cst()
    return S.tabShowing() and st ~= nil and S.data() ~= nil and st.filteredCache ~= nil
end, function(ok)
    local t = S.p35
    if t.off then return end
    if not ok then S.skip(S.N35, "B did not bring up the Craft tab in 12 s (" .. S.wLine() .. ", game speed " .. tostring(getGameSpeed()) .. ")"); t.off = true; return end
    t.rec, t.give = S.surfaceRecipe()
    if not t.rec then S.skip(S.N35, "no any-surface recipe he knows, made by hand, whose inputs can be given (Drill Plank on the list " .. tostring(S.row(S.DRILL) ~= nil) .. ")"); t.off = true; return end
    for _, ft in ipairs(t.give) do S.add(ft) end
    S.lighten()
    S.recount()
end)
Q.step(20, function()
    local t = S.p35
    if t.off then return end
    S.rowIntoView(t.rec)
    t.open = S.openCard(t.rec)
    S.badgeWatch(true)
end)
S.wait(12000, function()
    local t = S.p35
    if t.off then return true end
    if not t.open then t.open = S.openCard(t.rec) end
    return S.cardUp(t.rec) and S.ready(S.row(t.rec)) and S.zoneOf("action_build") ~= nil
end, function(ok)
    local t = S.p35
    if t.off then return end
    t.readyOk = ok
    S.rowIntoView(t.rec)
    S.worldClear()
end)
Q.still(2, function() end)
S.wait(4000, function() return S.p35.off or S.quiet() end, function() end)
Q.step(3, function()
    local t = S.p35
    if t.off then return end
    local rd = S.row(t.rec)
    local e = rd and rd.entry or nil
    if not (e and S.cardUp(t.rec)) then S.skip(S.N35, "the card of " .. tostring(t.rec) .. " did not open"); return end
    if not S.ready(rd) then S.skip(S.N35, "beside the table with " .. table.concat(t.give, ", ") .. " given, " .. tostring(e.displayName) .. " does not read ready: " .. S.readyWord(rd)); return end
    if not e.needSurface then S.skip(S.N35, tostring(e.displayName) .. " is not an any-surface recipe: no Surface badge"); return end
    -- (the badge as the card drew it in the last second: none, or not the amber square, and the friction is not there)
    local bd = S.badge
    if not (bd and getTimestampMs() - bd.at < 1500) then S.skip(S.N35, "beside the table, " .. tostring(e.displayName) .. "'s ready card draws no Surface badge: the friction is not there"); return end
    if bd.variant ~= "warning" then S.skip(S.N35, "beside the table, " .. tostring(e.displayName) .. "'s ready card draws its Surface badge as " .. tostring(bd.variant) .. ", not the amber warning: the friction is not there"); return end
    t.surf = t.surf or S.surface()   -- (asked again: the first ask came the frame he was set down, as bxr_craft.lua notes)
    S.shotOk(S.N35, "a table (" .. tostring(S.tableSprite) .. ") placed beside him at " .. t.tx .. "," .. t.ty .. " on the open patch at " .. S.where()
        .. " (the game takes it as a crafting surface: ISEntityUI.FindCraftSurface found it " .. tostring(t.surf ~= nil) .. "), " .. table.concat(t.give, ", ")
        .. " given; the crafting key B (" .. tostring(t.key) .. ") opened " .. S.wLine() .. "; " .. tostring(e.displayName)
        .. "'s card open (an any-surface recipe: isAnySurfaceCraft), " .. S.readyWord(rd) .. ", " .. S.reqLine(rd)
        .. "; its chip row draws the Surface badge as \"" .. tostring(bd.variant) .. "\" (the amber square) at " .. S.box4({ bd.x, bd.y, bd.w, bd.h })
        .. " with the table one square from him (the badge is drawn for every any-surface recipe, table or not)")
end)
Q.step(5, function()
    S.badgeWatch(false)
    S.mouseOff()
    S.allShut()
    local hadTable = S.tableObj ~= nil
    S.takeMade()
    S.objsBack()
    local n, lost = S.asideBack()
    S.rebindStation()
    if hadTable then Q.say(S.N35 .. ": put back: the table removed, the things given taken, " .. n .. " of his own things set aside for the weight back (not back " .. lost .. ")") end
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    S.badgeWatch(false)
    S.mouseOff()
    S.allShut()
    -- (should a run cut short leave them: his things in the crate, the crate, the table, the watch given, the things given)
    local back, lost = S.moveBack(S.p17.moved)
    S.p17.moved = {}
    S.craftPinsBack()
    S.p22Back()
    S.takeMade()
    S.objsBack()
    local n, alost = S.asideBack()
    S.rebindStation()
    -- the windows' saved places and pins exactly as found
    local md = S.p:getModData()
    md.ZeD_WinState = S.copy(S.was.winState)
    md.ZeD_WinPinned = S.copy(S.was.pinT)
    S.lock(false)
    if S.p:getPrimaryHandItem() ~= S.was.h1 then S.p:setPrimaryHandItem(S.was.h1) end
    if S.p:getSecondaryHandItem() ~= S.was.h2 then S.p:setSecondaryHandItem(S.was.h2) end
    local mode = S.Det.getMode and tostring(S.Det.getMode(S.pn)) or "?"
    Q.say("put back: Style " .. tostring(S.St.lookStyleOption:getValue()) .. ", Watch " .. S.watchWord(S.St.watchPlaceOption:getValue())
        .. ", the input lock as found (" .. tostring(S.lockWas) .. "; ZeD reads " .. mode .. "), the saved window places and pins as found, crate "
        .. tostring(S.crateObj ~= nil) .. ", table " .. tostring(S.tableObj ~= nil) .. " still standing, things from the crate back now " .. back
        .. " (not back " .. lost .. "), things set aside back now " .. n .. " (not back " .. alost .. "), pointer swap " .. tostring(S.mouseSwapped == true))
    G1.glassesBack(Q)
end)
S.zoomDyn(function() return S.was.zoom end)
Q.step(20, function()
    -- the pair as found (built again from the saved places put back above)
    if S.was.cOpen and S.was.wOpen then S.openPair()
    elseif S.was.cOpen then S.CWm.toggle(S.pn)
    elseif S.was.wOpen then S.WWm.open(S.pn) end
    if S.p:getBodyDamage():getOverallBodyHealth() < 99 then S.p:getBodyDamage():RestoreToFullHealth() end
    if S.P.stock then G1.tp(S.P.stock, "SE") end
    S.back0()
end)
Q.step(30, function()
    Mouse.setCursorVisible(true)
    Events.OnPreUIDraw.Remove(S.errWatch)
    Q.say("put back: " .. S.winLine() .. "; game speed " .. tostring(getGameSpeed()) .. ", zoom " .. tostring(S.zoom()) .. ", alive " .. tostring(not S.p:isDead())
        .. ", in a car " .. tostring(S.p:getVehicle() ~= nil) .. "; pictures taken: " .. ((#S.pic > 0) and table.concat(S.pic, ", ") or "none"))
end)
Q.start()
