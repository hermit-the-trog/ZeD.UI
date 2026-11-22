-- ZeDUI/tools/qa/vk3_screen.lua  (Nov 22 2026, QA, KISS batch K3; tag vk3_scr): the in-game proof of twelve of the
-- director's K3 picks (ZeDUI/qa/audits/2026-11-22_kiss_calls_K3.md, each "### K3-n (#rank)" entry's pick): #12, #22,
-- #33, #40, #42, #46, #51, #53, #56, #59, #60 and #61. The old code is 0b366177e; the picks are in 7b8ed6843 (the merge
-- ae3f4a2b2 of branch k3). Built on rt_kit.lua (the global RT), run after zedqa_prelude.lua (its ZEDQA_CAR_* helpers
-- spawn, wait for, seat and take away the car; without the prelude the car is spawned as beta21_report.lua:459-494
-- spawns its pickup). grep "ZEDQA vk3_scr". For QA's manifest:
-- vk3_screen.lua | vk3_scr | timeout=420
--
-- How to read the log: the proofs are the lines that start "K3 #". Each FAILS on 0b366177e and PASSES on 7b8ed6843,
-- for the pick's own reason (read from both commits). Staging and the put-back print a FAIL line only when they go
-- wrong (a SAY line when they do not), so nothing else prints PASS: a part that cannot be staged FAILS ("... staging:"),
-- it never passes quietly. A SKIP is said only where the pick cannot be reached in a game (below).
--
-- What each check reads, and what the old code does there:
--   #12      Text size's default (ZeD setup's textSize: the item Settings.lua marks as the default as it loads, which
--            ZeD keeps as the option's zedDefault for Defaults and the help band, and ZeD.Settings.defaultSizeKey), read
--            against the screen's height (ZeD.Scale.screenSize, BASE_H 1080). The saved pick is only read, never set.
--            Under 1080 tall (the 1280x800 run): Large. Old: Small at every height -> FAIL. At 1080 or more (the 4K
--            run): Small, and the default is the screen's (defaultSizeKey). Old: Small too, but no screen rule at all
--            (defaultSizeKey nil) -> FAIL; at 4K this half is weak (the player meets the same Small on both), the
--            1280x800 run is the proof.
--   #59      The Character window's tab names as its strip's hover balloon and the title read them
--            (ZeD_CharacterWindow.tabLabel over ZeD_CharacterWindow.TABS): loot, thermal and identity read the game's
--            page words, getText IGUI_Controller_Inventory ("Inventory"), IGUI_XP_ClothingIns ("Temperature") and
--            IGUI_XP_Info ("Info"); the ids stay. Old: Loot, Thermal, Identity (ZeD's own keys) -> FAIL. (The World
--            window's first tab stays Loot: read in a NOTE only.)
--   #33 (a)  Options' Back question, asked with a change made: the band's answers (ZeD_MMOptions:buildStrip, the
--            question's own builder, on a probe of the window: setConfirm("back"), one change counted, the band's
--            drawing helper MM.ui.stripSpecs read instead of drawn) hold the game's Apply as the primary answer, and the
--            question lands on it. Nothing is answered, applied or saved. Old: Keep editing and Discard changes only,
--            landing on Keep editing -> FAIL. (A probe, not the pause screen's window: opening Options in a game puts
--            the live options screen under the run; the probe runs the same two methods the window runs.)
--   #33 (b)  The first-launch window's close box (ZeD_MMWelcome:close) on a probe whose Accept and Skip are stubs (no
--            file written): with Pick your own it ends as Accept (done), the picks kept; with Skip picked as the way it
--            ends as Skip. Old: the close box is Skip -> FAIL.
--   #53 (a)  Playing with read from the device in use: the window's onShow (every time it shows) on a probe, once
--            with a controller driving the desk (MM.forceGamepad, the main menu's own switch for it) and once without:
--            Controller, then what the desk reads now (Mouse and keys with no controller on the desk). Old: onShow
--            leaves Playing with where it was -> FAIL.
--   #53 (b)  Y accepts on a pad: the desk's Y goes to the window's joyY (ZeD_MainMenu.lua's dispatch: "if w.joyY then
--            w:joyY()"), on a probe: it ends as Accept, and the window's controller footer names Y Accept (the game's
--            UI_btn_accept). Old: no joyY, no Y in the footer -> FAIL.
--   #53 (c)  SKIP: the Style tip under Style draws only on the main menu's desk (no in-game path to the window).
--   #40 (a)  Each window's three-line menu, pulled down by the window box's own action (win._boxDo = "menu", as
--            vk1_world.lua): on the Character and the World window the first rows are the Keyboard map (when ZeD has it)
--            and ZeD setup. Old: both sit at the bottom, after Bug report -> FAIL.
--   #40 (b)  Both menus have a Style row with Full and Lite (the pad wheel's own choices), the one in use checked. Old:
--            no Style row -> FAIL.
--   #40 (c)  With no controller connected (JoypadState.players), neither menu shows Controller highlight or Controller
--            map. Old: Controller highlight shows to the mouse -> FAIL. With a controller connected the rows belong
--            there: SKIP, said plainly (the run on the director's desk has none).
--   #51 (a)  Both menus have a Show me around row that starts the tour. Old: no such row -> FAIL.
--   #51 (b)  The Character menu's Show me around fired (its row's own onFire, as a click on it): the tour runs and the
--            game is paused (game speed 0) while its balloon is up; Stop tour then gives the speed back. The tour's
--            file (Zomboid/Lua/ZeD_tutorial.txt) is never written: Lua's getFileWriter refuses that name (and the
--            setup and guide-bubble files) while the tour runs and stops. Old: no row, so the tour is started by
--            TU.start, its first-launch call: it runs over the live game -> FAIL.
--   #42      The belt's Messages note: every unread message set read for the test (put back after), then one unread
--            error from another mod ("QA vk3 Other Mod", as ZeD_Messages files a stack's mod): the count's badge is
--            drawn gray (the theme's textDim), not the danger red; then one unread error of ZeD's own (its source named
--            by ZeD's mod name, as a ZeD stack names it): red. The badge's color is read as the belt draws it (its
--            _drawLamp watched for one frame: the badge's drawRect before the count's drawText). Old: red for both ->
--            FAIL.
--   #61      Style Full (the value only: Lite's guide is the window, the book is Full's), both windows shut so no tab
--            gives a topic (W.contextTopicKey nil), F1's own call (ZeD_SurvivalGuide.lua onKey: W.toggle(0)): the book
--            opens on the spread that holds its contents (bk.contentsPage, the book's own Contents key's page), not on
--            the copyright and title pages; F1 again shuts it. The guide's bubble is not marked done by this open
--            (ZeD.GuideBubble.done held for the call: it would write Zomboid/Lua/ZeD_guidebubble.txt). Old: the book
--            opens on spread 1 -> FAIL.
--   #22 (a)  Style Full and the Watch on the belt (values only, ZeD's defaults), a digital wrist watch worn (given, as
--            rt_hud.lua; his own when he wears one): the belt holds a row of five speed keys (Pause, Play, Fast forward
--            x1 and x2, Wait) beside its watch. Old: the watch's SPEED and START pushers only -> FAIL.
--   #22 (b)  Each key pressed once through the belt's own mouse handler (onMouseDown at the key's middle) sets that
--            speed, read from the game's speed controls (getCurrentGameSpeed): Pause 0, x1 2, x2 3, Wait 4, Play 1 (in
--            that order, two frames at each fast speed). Old: no keys -> FAIL.
--   #56      A pickup (the prelude's ZEDQA_CAR_WAIT), no key on him; he in the passenger seat (seat 1, ZEDQA_CAR_ENTER):
--            the belt is drawn (ZeD_BeltHUD:wanted and _drawn) and the dash is not shown. Old: the belt hides and the
--            read-only PASSENGER dash shows -> FAIL.
--   #46 (a)  He at the wheel, still no key on him: each switch of the dash's plate (dash._hit, live and dead alike)
--            pointed at, the pointer the dash reads set on it (its getMouseX / getMouseY / isMouseOver answered for the
--            dash alone; up to three spots a switch), and the hint the dash asks for read as it asks
--            (ZeD.Atoms.requestHint watched): every switch names itself; the game's dashboard words where the game has
--            them (Tooltip_Dashboard_*: the key, Headlights, Locked doors, the trunk, Heater, Radio), and the switches
--            with a state end " | On" or " | Off" (the game's UI_On / UI_Off). Old: a hover only washes the switch, no
--            name -> FAIL.
--   #46 (b)  The key: with no key on him, none in the lock (a key the car came with in the lock taken out first, as
--            bx_vehicles.lua does) and the car not hotwired, it reads the game's "No Key for
--            this car found." (Tooltip_Dashboard_NoKey); then, its key given (ZEDQA_CAR_PREP), "Put the keys in the
--            ignition" (Tooltip_Dashboard_PutKeysInIgnition). Old: no words -> FAIL. (Build: the dead switches are not
--            painted blank yet; nothing here reads the art.)
--   #60      Out of the car beside it: the game's right-click fill for a car (ISVehicleMenu.FillMenuOutsideVehicle,
--            where the world's right-click on a car ends, ISVehicleMenu.lua:44-51) into a recorder menu (nothing shown,
--            nothing fired): it holds the game's "Enter Vehicle" (IGUI_EnterVehicle) running ISVehicleMenu.onEnter on
--            this car and "Vehicle Mechanics" (ContextMenu_VehicleMechanics) running ISVehicleMenu.onMechanic. Old:
--            fuel, wash and trailer lines only -> FAIL.
--
-- Order: #12, #59, #33/#53 (probes), #40/#51 (the pair open), #42, then Style Full for #61 (the pair shut) and #22, then
-- the found Style for the car (#56, #46, #60). Waits go by the clock; no pixel size is written in (4K at UI scale 1.75
-- and 1280x800 Auto alike). Nothing is fired but the menu row's tour start, the belt's speed keys and F1: no dash
-- control, no menu choice, nothing used, eaten or drunk, no timed action.
-- What it puts back (also when a step throws or the time runs out): the tour stopped and the guide book shut (if
-- found shut), no window menu up, Lua's getFileWriter, ZeD.Atoms.requestHint, MM.ui.stripSpecs, ZeD.GuideBubble.done,
-- MM.forceGamepad and the main menu's open pull-down as found, the belt's and the dash's watchers gone, every message's
-- read mark as found and the test's two errors gone, the watch (the one given taken off and away, a worn one put back),
-- Style, Watch and the watch's pop as found (values only: nothing applied, nothing saved; Text size never touched), the
-- car taken away (ZEDQA_CAR_AWAY: him out first, the key out of his inventory, the car removed ticks later), him where he
-- was found, the windows open or shut as found, where and as big as they were, on their tabs, and the game speed. No
-- option is saved, ModOptions is never written, no ZeD_setup / ZeD_tutorial / ZeD_guidebubble file is written,
-- ZEDQA_LAYOUT_BACK is never called.
-- Not run in game yet. KCheck OK.

if not (RT and RT.make) then
    print("ZEDQA vk3_scr ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vk3_scr VERDICT FAIL 1")
    print("ZEDQA vk3_scr DONE")
    return
end

local Q = RT.make("vk3_scr")
Q.maxMs = 240000   -- (four minutes, then the put-back; a run takes under two)
local Z = ZeD or {}
local S = { p = RT.p, pn = RT.pn, was = { geo = {}, tab = {} }, off = {}, menus = {},
    k12 = {}, k22 = { res = {} }, k33 = {}, k42 = { stash = {}, made = {}, unread = {} }, k46 = { got = {}, miss = {}, list = {} },
    k51 = {}, k56 = {}, k60 = {}, k61 = {} }
S.CARS = { "Base.PickUpTruck", "Base.CarNormal" }
S.WATCH = "Base.WristWatch_Left_DigitalBlack"
S.SPOTS = { 0.5, 0.25, 0.75 }
S.PRESS = { 0, 2, 3, 4, 1 }
S.OTHER = "QA vk3 Other Mod"
S.PART = { menu = "#40 and #51", tour = "#51 (b)", belt = "#42", guide = "#61", speed = "#22", car = "#56, #46 and #60", dash = "#46" }
-- the files the game's Lua must not write while the tour, F1 and the probes run (Zomboid/Lua)
S.BLOCK = { ["ZeD_tutorial.txt"] = true, ["ZeD_setup.txt"] = true, ["ZeD_setup_seen.txt"] = true, ["ZeD_guidebubble.txt"] = true }
-- the game's dashboard words for a switch (ZeD_Dashboard.lua D.switchWords), and the switches that carry a state
S.GAMEWORDS = {
    ignition = { "Tooltip_Dashboard_Hotwired", "Tooltip_Dashboard_KeysIgnition", "Tooltip_Dashboard_PutKeysInIgnition", "Tooltip_Dashboard_NoKey" },
    lights = { "Tooltip_Dashboard_Headlights" }, lock = { "Tooltip_Dashboard_LockedDoors" },
    trunk = { "Tooltip_Dashboard_TrunkLocked", "Tooltip_Dashboard_TrunkUnlocked" }, heat = { "Tooltip_Dashboard_Heater" },
    pwr = { "Tooltip_Dashboard_Radio" }, vol = { "Tooltip_Dashboard_Radio" }, radio = { "Tooltip_Dashboard_Radio" },
}
-- (cruise names the game's regulator line with its keys, and its state; when its keys cannot be read it falls back to
-- ZeD's verb, so only its words are required)
S.STATEFUL = { lights = true, lock = true, heat = true, pwr = true, vol = true, radio = true }

-- ===================================================================== words and numbers
function S.num(v)
    local x = tonumber(v)
    if x == nil then return "?" end
    local r = math.floor(x * 10 + 0.5) / 10
    if r == math.floor(r) then return tostring(math.floor(r)) end
    return tostring(r)
end
function S.tr(k)
    local s = nil
    pcall(function() s = ZeD.tr(k) end)
    return tostring(s or k)
end
function S.gt(k)
    local s = nil
    pcall(function() s = getText(k) end)
    return tostring(s or k)
end
function S.starts(s, p) return type(s) == "string" and type(p) == "string" and p ~= "" and s:sub(1, #p) == p end
function S.ends(s, p) return type(s) == "string" and type(p) == "string" and #s >= #p and s:sub(#s - #p + 1) == p end
-- staging that cannot go on: one FAIL line, the part's checks not run (a part not proven is a FAIL, never a SKIP)
function S.fail(key, why)
    if S.off[key] then return end
    S.off[key] = true
    Q.check(false, "K3 " .. S.PART[key] .. " staging: " .. tostring(why) .. " (not proven)")
end
-- the put-back: a SAY line when it is as found, a FAIL line when it is not (never a PASS: it proves no pick)
function S.putBack(ok, what, detail)
    if ok then Q.say("put back: " .. what .. " | " .. tostring(detail))
    else Q.check(false, "put back: " .. what, detail) end
end
function S.near(a, b)
    if not (a and b) then return false end
    return math.abs((a.r or 0) - (b.r or 0)) < 0.02 and math.abs((a.g or 0) - (b.g or 0)) < 0.02 and math.abs((a.b or 0) - (b.b or 0)) < 0.02
end
function S.rgb(c)
    if not c then return "none" end
    return S.num((c.r or 0) * 100) .. "/" .. S.num((c.g or 0) * 100) .. "/" .. S.num((c.b or 0) * 100)
end

-- ===================================================================== the windows (vk2_pad.lua, vx12_wheel.lua)
function S.charOpen()
    local CW = ZeD_CharacterWindow
    return (CW ~= nil and CW.isOpen ~= nil and CW.isOpen(S.pn)) and true or false
end
function S.worldOpen()
    local WW = ZeD_WorldWindow
    return (WW ~= nil and WW.isOpen ~= nil and WW.isOpen(S.pn)) and true or false
end
function S.geo(w)
    if not w then return nil end
    return { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() }
end
function S.gs(g)
    if not g then return "none" end
    return S.num(g.x) .. "," .. S.num(g.y) .. " " .. S.num(g.w) .. "x" .. S.num(g.h)
end
function S.sameGeo(a, b)
    if a == nil or b == nil then return a == nil and b == nil end
    return math.abs(a.x - b.x) <= 1 and math.abs(a.y - b.y) <= 1 and math.abs(a.w - b.w) <= 1 and math.abs(a.h - b.h) <= 1
end
function S.copy(t, depth)
    if type(t) ~= "table" then return t end
    depth = depth or 0
    local out = {}
    for k, v in pairs(t) do out[k] = (depth < 6) and S.copy(v, depth + 1) or v end
    return out
end
function S.closePair()
    local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
    if not (CW and WW) then return end
    if S.charOpen() and S.worldOpen() and CW.toggleBothPaired then pcall(CW.toggleBothPaired, S.pn) end
    if S.charOpen() and CW.toggle then pcall(CW.toggle, S.pn) end
    if S.worldOpen() and WW.close then pcall(WW.close, S.pn) end
end
function S.openPair()
    local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
    if not (CW and WW) then return end
    if not S.charOpen() and not S.worldOpen() and CW.toggleBothPaired then pcall(CW.toggleBothPaired, S.pn) end
    if not S.charOpen() and CW.toggle then pcall(CW.toggle, S.pn) end
    if not S.worldOpen() and WW.open then pcall(WW.open, S.pn) end
end
-- the windows open or shut as found (the opens first, the shuts last, so an open that brings its partner is undone)
function S.windowsBack()
    local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
    if not (CW and WW) then return end
    if S.was.char and S.was.world and not S.charOpen() and not S.worldOpen() and CW.toggleBothPaired then
        pcall(CW.toggleBothPaired, S.pn)
    end
    if S.was.char and not S.charOpen() and CW.toggle then pcall(CW.toggle, S.pn) end
    if S.was.world and not S.worldOpen() and WW.open then pcall(WW.open, S.pn) end
    if S.was.char == false and S.charOpen() and CW.toggle then pcall(CW.toggle, S.pn) end
    if S.was.world == false and S.worldOpen() and WW.close then pcall(WW.close, S.pn) end
end
-- the layout the character keeps for each window (md.ZeD_WinState.char / .world): open true, the windows found open
-- get the layout they saved when the run first shut them; open false, the windows found shut get the layout they had
-- (vk2_pad.lua S.layoutBack)
function S.layoutBack(open)
    local ws = S.was.ws
    local md = (ws and ws.taken and S.p) and S.p:getModData() or nil
    if not md then return end
    if not open and not ws.had and not (S.was.char or S.was.world) then md.ZeD_WinState = nil; return end
    local src = open and S.was.wsShut or ws.v
    if type(src) ~= "table" then src = {} end
    local cur = md.ZeD_WinState
    if type(cur) ~= "table" then
        cur = {}
        md.ZeD_WinState = cur
    end
    for _, k in ipairs({ { "char", S.was.char == true }, { "world", S.was.world == true } }) do
        if k[2] == open and (src[k[1]] ~= nil or not open) then cur[k[1]] = S.copy(src[k[1]]) end
    end
end
-- the windows at rest: the same places and sizes for 300 ms
function S.settled()
    local cw, ww = S.charOpen() and RT.cw() or nil, S.worldOpen() and RT.ww() or nil
    local sig = S.gs(S.geo(cw)) .. " | " .. S.gs(S.geo(ww))
    local now = getTimestampMs()
    if sig ~= S.restSig then
        S.restSig, S.restAt = sig, now
        return false
    end
    return now - S.restAt >= 300
end
-- a window not where it was found, set back by its own setters (never ZEDQA_LAYOUT_BACK); true when it moved it
function S.placeBack(w, g)
    if not (w and g) or S.sameGeo(S.geo(w), g) then return false end
    if math.abs(w:getWidth() - g.w) > 1 then
        w.minimumWidth = math.min(w.minimumWidth or g.w, g.w)
        w:setWidth(g.w)
    end
    if math.abs(w:getHeight() - g.h) > 1 then
        w.minimumHeight = math.min(w.minimumHeight or g.h, g.h)
        w:setHeight(g.h)
    end
    if w:getX() ~= g.x then w:setX(g.x) end
    if w:getY() ~= g.y then w:setY(g.y) end
    if w._anchorRightEdge ~= nil then w._anchorRightEdge = g.x + w:getWidth() end
    return true
end
function S.winOf(k) if k == "c" then return RT.cw() end; return RT.ww() end
function S.winName(k) if k == "c" then return "Character" end; return "World" end

-- ===================================================================== settings (the values only), the player
function S.optVal(o) if o and o.getValue then return o:getValue() end; return nil end
function S.optSet(o, v) if o and o.setValue and v ~= nil and o:getValue() ~= v then o:setValue(v) end end
function S.liteNow() return (Z.Settings and Z.Settings.lite and Z.Settings.lite()) and true or false end
function S.speed(n) if ZEDQA_SPEED then ZEDQA_SPEED(n) elseif setGameSpeed then setGameSpeed(n) end end
function S.gameSpeed()
    local v = nil
    pcall(function() v = getGameSpeed() end)
    return v
end
-- the speed the game's speed controls hold (0 paused, 1 x1, 2 x5, 3 x20, 4 x40), as the belt and the watch read it
function S.spNow()
    local v = nil
    pcall(function()
        local sc = UIManager.getSpeedControls()
        if sc then v = sc:getCurrentGameSpeed() end
    end)
    return v
end
function S.pausedBox()
    local v = nil
    pcall(function() v = UIManager.isShowPausedMessage() end)
    return v
end
function S.health() local h = nil; pcall(function() h = S.p:getBodyDamage():getOverallBodyHealth() end); return h end
function S.queueN()
    local n = 0
    if ISTimedActionQueue and ISTimedActionQueue.getTimedActionQueue then
        local q = ISTimedActionQueue.getTimedActionQueue(S.p)
        if q and q.queue then n = #q.queue end
    end
    return n
end
-- a timed action the run queued (none should be) cleared, only when none was queued at the start
function S.queueBack()
    if not S.was.taken then return end
    local n = S.queueN()
    if n > 0 and (S.was.queue or 0) == 0 and ISTimedActionQueue and ISTimedActionQueue.clear then
        S.queued = n
        pcall(ISTimedActionQueue.clear, S.p)
    end
end
function S.where() return S.num(S.p:getX()) .. "," .. S.num(S.p:getY()) .. "," .. S.num(S.p:getZ()) end
-- him back where he was found (the car's door and the prelude's spot are elsewhere), as ZEDQA_HOME moves him
function S.homeBack()
    local at = S.was.pos
    if not at or S.p:getVehicle() then return end
    local dx, dy = S.p:getX() - at.x, S.p:getY() - at.y
    if dx * dx + dy * dy <= 2.25 and math.floor(S.p:getZ()) == math.floor(at.z) then return end
    S.movedFrom = S.where()
    S.p:setX(at.x); S.p:setY(at.y); S.p:setZ(at.z)
    S.p:setLastX(at.x); S.p:setLastY(at.y); S.p:setLastZ(at.z)
end
-- Style Full (the value only) for #61 and #22; S.styleBack puts the found value back
function S.styleFull()
    local St = Z.Settings
    if not (St and St.lookStyleOption) then return end
    S.optSet(St.lookStyleOption, 1)
end
function S.styleBack()
    local St = Z.Settings
    if not (S.was.taken and St and St.lookStyleOption) then return end
    S.optSet(St.lookStyleOption, S.was.style)
end

-- ===================================================================== the guards (files, the bubble, the hints)
-- Lua's getFileWriter refuses the tour's, the setup's and the guide bubble's files while on (every other file goes
-- through); off puts the game's own back
function S.blockFiles(on)
    if on then
        if S.fileOrig or not getFileWriter then return end
        local orig = getFileWriter
        S.fileOrig = orig
        getFileWriter = function(name, a, b)
            if S.BLOCK[tostring(name)] then
                S.blocked = (S.blocked or 0) + 1
                return nil
            end
            return orig(name, a, b)
        end
        return
    end
    if S.fileOrig then
        getFileWriter = S.fileOrig
        S.fileOrig = nil
    end
end
-- the guide's bubble held: an open by F1 would mark it done for good (G.markShown writes its file)
function S.holdBubble(on)
    local G = Z.GuideBubble
    if on then
        if S.k61.doneOrig or not (G and G.done) then return end
        S.k61.doneOrig = G.done
        G.done = function() S.k61.bubbleAsked = true end
        return
    end
    if S.k61.doneOrig and G then
        G.done = S.k61.doneOrig
        S.k61.doneOrig = nil
    end
end
-- ZeD.Atoms.requestHint watched: the dash's "sw:<id>" hints recorded as the dash asks for them
function S.hintWatch(on)
    local A = Z.Atoms
    local k = S.k46
    if on then
        if k.hintOrig or not (A and type(A.requestHint) == "function") then return end
        local orig = A.requestHint
        k.hintOrig = orig
        A.requestHint = function(owner, key, text, ...)
            if owner ~= nil and owner == k.dash and type(key) == "string" and key:sub(1, 3) == "sw:" then
                k.cap = { id = key:sub(4), words = text }
            end
            return orig(owner, key, text, ...)
        end
        return
    end
    if k.hintOrig and A then
        A.requestHint = k.hintOrig
        k.hintOrig = nil
    end
end
-- the pointer the dash reads, set by the run (k.mx, k.my in the dash's own pixels; nil: off the dash)
function S.mockOn(d)
    local k = S.k46
    if k.mock or not d then return end
    k.mock = { d = d, gx = rawget(d, "getMouseX"), gy = rawget(d, "getMouseY"), mo = rawget(d, "isMouseOver") }
    d.getMouseX = function() return k.mx or -10000 end
    d.getMouseY = function() return k.my or -10000 end
    d.isMouseOver = function() return k.mx ~= nil end
end
function S.mockOff()
    local k = S.k46
    local m = k.mock
    if not m then return end
    k.mock = nil
    k.mx, k.my = nil, nil
    m.d.getMouseX, m.d.getMouseY, m.d.isMouseOver = m.gx, m.gy, m.mo
end

-- ===================================================================== the window menus (vk1_world.lua)
function S.menuOn(w)
    local WM = Z.WindowMenu
    local m = WM and WM.current
    if w == nil or m == nil or m._ctx == nil or m._ctx.open ~= true or m.win ~= w then return nil end
    return m
end
function S.closeWinMenu()
    local WM = Z.WindowMenu
    local m = WM and WM.current
    if m and m._ctx and m._ctx.open and m.close then pcall(m.close, m) end
end
-- the defs of the menu's top level, in the order it draws them (the lines between groups left out)
function S.rowDefs(m)
    local out = {}
    local lv = m and m._levels and m._levels[1]
    for _, r in ipairs((lv and lv.rows) or {}) do
        if type(r) == "table" and type(r.def) == "table" then out[#out + 1] = r.def end
    end
    return out
end
function S.namesOf(defs)
    local out = {}
    for _, d in ipairs(defs or {}) do out[#out + 1] = tostring(d.name or "") end
    return out
end
function S.findDef(defs, name)
    for _, d in ipairs(defs or {}) do if d.name == name then return d end end
    return nil
end
function S.hasPad()
    return (JoypadState ~= nil and JoypadState.players ~= nil and JoypadState.players[S.pn + 1] ~= nil) and true or false
end

-- ===================================================================== the belt
function S.hud() local B = Z.Belt; return (B and B.getHUD) and B.getHUD(S.pn) or nil end
function S.boxes(kind)
    local hud = S.hud()
    local out = {}
    for _, b in ipairs((hud and hud._boxes) or {}) do if b.kind == kind then out[#out + 1] = b end end
    return out
end
function S.beltShown()
    local hud = S.hud()
    if not hud then return false end
    local vis, want = false, false
    pcall(function() vis = hud:isVisible() end)
    pcall(function() want = hud:wanted() end)
    return vis == true and want == true and hud._drawn == true
end

-- ===================================================================== the car (zedqa_prelude.lua, vk2_pad.lua)
function S.carStart()
    if not ZEDQA_CAR_WAIT then return S.carSpawn() end
    S.k56.waiting = true
    ZEDQA_CAR_WAIT(S.CARS[1], "vk3_scr", function(v)
        S.k56.waiting = false
        if S.k56.gaveUp then
            if ZEDQA_CAR_AWAY then ZEDQA_CAR_AWAY(v) end
            return
        end
        S.car = { v = v, script = S.CARS[1], how = "the prelude's ZEDQA_CAR_WAIT (the drag strip's marked stretch)" }
    end, function(why)
        S.k56.waiting = false
        S.carWhy = why
    end, 4000)
    return true
end
-- a bare 3 x 7 footprint round sq0 (beta21_report.lua's place test, widened to the car as kiss_pad.lua's)
function S.carClear(sq0)
    if not sq0 then return false end
    local cell = getCell()
    local cx, cy, z = sq0:getX(), sq0:getY(), sq0:getZ()
    for dy = -3, 3 do
        for dx = -1, 1 do
            local sq = cell:getGridSquare(cx + dx, cy + dy, z)
            if not sq then return false end
            local ok = false
            pcall(function() ok = sq:isFree(false) and not sq:HasTree() and sq:getVehicleContainer() == nil and sq:getRoom() == nil end)
            if not ok then return false end
        end
    end
    return true
end
function S.carSpawn()
    if ZEDQA_CAR_SPAWN then
        for _, script in ipairs(S.CARS) do
            local v, why = ZEDQA_CAR_SPAWN(script, "vk3_scr")
            if v then
                S.car = { v = v, script = script, how = "the prelude's ZEDQA_CAR_SPAWN (the drag strip's marked stretch)" }
                return true
            end
            S.carWhy = why
        end
        return false
    end
    local cell = getCell()
    for _, o in ipairs({ { 5, 2 }, { 5, -3 }, { -5, 2 }, { 2, 5 }, { -4, -4 } }) do
        local sq = cell:getGridSquare(math.floor(S.p:getX()) + o[1], math.floor(S.p:getY()) + o[2], math.floor(S.p:getZ()))
        if S.carClear(sq) then
            for _, script in ipairs(S.CARS) do
                local v = nil
                pcall(function() v = addVehicleDebug(script, IsoDirections.N, nil, sq) end)
                if v then
                    S.car = { v = v, script = script, how = "addVehicleDebug beside him (beta21_report.lua:459-464; no prelude)" }
                    return true
                end
            end
        end
    end
    S.carWhy = "no bare 3 x 7 footprint at beta21_report.lua's five places round him"
    return false
end
function S.carReady()
    local c = S.car
    if not (c and c.v) then return false end
    if ZEDQA_CAR_READY then
        local ok, r = pcall(ZEDQA_CAR_READY, c.v)
        return ok and r == true
    end
    local r = false
    pcall(function() r = c.v:getSquare() ~= nil and c.v:isPhysicsActive() end)
    if r then c.seen = true end
    return c.seen == true
end
-- repaired, its key in his inventory
function S.carPrep()
    local c = S.car
    local key = nil
    if ZEDQA_CAR_PREP then
        local ok, k = pcall(ZEDQA_CAR_PREP, c.v)
        if ok then key = k end
    else
        pcall(function() c.v:repair() end)
        pcall(function() key = S.p:getInventory():AddItem(c.v:createVehicleKey()) end)
    end
    if key then pcall(function() key:getModData().ZeDQA_spawned = true end) end
    c.key = key
end
-- a seat (ZEDQA_CAR_ENTER refuses a car that is not ready or is far: seating one drops to the main menu)
function S.carIn(seat)
    local c = S.car
    if ZEDQA_CAR_ENTER then
        local okc, ok, why = pcall(ZEDQA_CAR_ENTER, c.v, seat)
        if not okc then return false, tostring(ok) end
        return ok == true, why
    end
    if not S.carReady() then return false, "the car is not ready" end
    pcall(function() c.v:enter(seat, S.p); triggerEvent("OnEnterVehicle", S.p) end)
    return S.p:getVehicle() == c.v, "entered directly"
end
-- out of the car beside it, as ZEDQA_CAR_AWAY lets him out
function S.carOut()
    local c = S.car
    if not (c and c.v) or S.p:getVehicle() ~= c.v then return end
    pcall(function() c.v:exit(S.p); triggerEvent("OnExitVehicle", S.p) end)
end
function S.seat()
    local s = -1
    local c = S.car
    if c and c.v then pcall(function() s = c.v:getSeat(S.p) end) end
    return s
end
function S.carLive(v)
    if not v then return false end
    local live = false
    pcall(function()
        local it = getCell():getVehicles():iterator()
        while it:hasNext() do if it:next() == v then live = true end end
    end)
    return live
end
-- him out, the key out, the car away ticks later (removing it in the tick of the exit is a NullPointerException and
-- the main menu: ZEDQA_CAR_AWAY's sweep removes it two ticks on; without the prelude, S.carGone half a second on, once)
function S.carAway()
    local c = S.car
    if not c or c.going then return end
    c.going = true
    c.awayAt = getTimestampMs()
    if ZEDQA_CAR_AWAY then pcall(ZEDQA_CAR_AWAY, c.v, c.key); return end
    c.manual = true
    if S.p:getVehicle() == c.v then pcall(function() c.v:exit(S.p); triggerEvent("OnExitVehicle", S.p) end) end
    local k = c.key
    if k then pcall(function() local con = k:getContainer(); if con then con:Remove(k) end end) end
end
function S.carGone()
    local c = S.car
    if not c then return true end
    if c.manual and not c.removed and S.p:getVehicle() ~= c.v and getTimestampMs() - (c.awayAt or 0) > 500 and S.carLive(c.v) then
        c.removed = true
        pcall(function() c.v:permanentlyRemove() end)
    end
    return not S.carLive(c.v)
end
function S.dash() local D = Z.Dashboard; return (D and D.getInstance) and D.getInstance(S.pn) or nil end
function S.dashShown()
    local d = S.dash()
    if not d then return false end
    local v = false
    pcall(function() v = d:isVisible() end)
    return v == true
end
-- the car's key state as the dash reads it: on him, in the lock, hotwired
function S.keyState()
    local c = S.car
    local st = { on = false, lock = false, wired = false }
    if not (c and c.v) then return st end
    pcall(function() st.on = S.p:getInventory():haveThisKeyId(c.v:getKeyId()) ~= nil end)
    pcall(function() st.lock = c.v:isKeysInIgnition() == true end)
    pcall(function() st.wired = c.v:isHotwired() == true end)
    return st
end
-- a menu that records what the game's right-click fill adds (nothing drawn, nothing fired)
function S.recorder()
    local r = { options = {}, numOptions = 1, player = S.pn }
    function r:addOption(name, target, onSelect, ...)
        local o = { name = name, target = target, onSelect = onSelect, args = { ... } }
        self.options[#self.options + 1] = o
        self.numOptions = self.numOptions + 1
        return o
    end
    function r:addOptionOnTop(...) return self:addOption(...) end
    function r:addDebugOption(...) return self:addOption(...) end
    function r:addActionsOption(...) return self:addOption(...) end
    function r:addSubMenu(option, child) if option then option.sub = child end end
    function r:getNew() return S.recorder() end
    function r:removeLastOption() if #self.options > 0 then table.remove(self.options) end end
    function r:getOptionFromName(n)
        for _, o in ipairs(self.options) do if o.name == n then return o end end
        return nil
    end
    function r:isEmpty() return #self.options == 0 end
    function r:setVisible() end
    function r:getIsVisible() return false end
    function r:isReallyVisible() return false end
    return r
end

-- ===================================================================== waits
-- until cond() holds (asked every drawn frame; it never throws), for at most ms of real time; then fn(ok)
function S.waitUntil(ms, cond, fn)
    local st = {}
    Q.waitFor(1, math.floor(ms / 3) + 900, function()
        local now = getTimestampMs()
        st.t = st.t or now
        if cond() then st.ok = true; return true end
        return now - st.t >= ms
    end, function() fn(st.ok == true) end)
end

-- ===================================================================== #12: Text size's default
function S.k12run()
    local St = Z.Settings
    local o = St and St.opts and St.opts.dict and St.opts.dict.textSize or nil
    local keys = St and St.sizeKeys or nil
    local sc = Z.Scale
    local okH, sw, sh = pcall(function() return sc.screenSize() end)
    if not (o and keys and sc and sc.BASE_H and okH and type(sh) == "number") then
        Q.check(false, "K3 #12 staging: ZeD setup's Text size, its sizes and the screen's height can be read (not proven)",
            "option " .. tostring(o ~= nil) .. ", sizes " .. tostring(keys ~= nil) .. ", ZeD.Scale " .. tostring(sc ~= nil) .. ", height " .. tostring(sh))
        return
    end
    local under = sh < sc.BASE_H
    local want = under and "large" or "small"
    local defKey = keys[o.zedDefault or 0]
    local declared = St.defaultSizeKey
    local saved = S.optVal(o)
    S.k12.saved = saved
    local detail = "screen " .. tostring(sw) .. "x" .. tostring(sh) .. " (the rule's line " .. tostring(sc.BASE_H) .. "); the option's default item "
        .. tostring(o.zedDefault) .. " (" .. tostring(defKey) .. "), the screen's default ZeD.Settings.defaultSizeKey " .. tostring(declared)
        .. "; the saved pick " .. tostring(saved) .. " (" .. tostring(keys[saved or 0]) .. ", only read)"
    if under then
        Q.check(defKey == "large" and declared == "large",
            "K3 #12: under 1080 tall Text size starts on Large (a default only: the saved pick wins)", detail)
    else
        Q.check(defKey == "small" and declared == "small",
            "K3 #12: at 1080 tall or more Text size starts on Small, the default set by the screen's height (weak here: the 1280x800 run proves Large)", detail)
    end
end

-- ===================================================================== #59: the Character window's tab names
function S.k59run()
    local CW = ZeD_CharacterWindow
    if not (CW and CW.TABS and CW.tabLabel) then
        Q.check(false, "K3 #59 staging: the Character window's tabs (ZeD_CharacterWindow.TABS, tabLabel) are loaded (not proven)")
        return
    end
    local want = { loot = "IGUI_Controller_Inventory", thermal = "IGUI_XP_ClothingIns", identity = "IGUI_XP_Info" }
    local bad, said, seen = {}, {}, 0
    for _, tab in ipairs(CW.TABS) do
        local key = want[tab.id]
        if key then
            seen = seen + 1
            local okL, label = pcall(CW.tabLabel, tab)
            local w = S.gt(key)
            said[#said + 1] = tostring(tab.id) .. ": \"" .. tostring(label) .. "\" (the game's " .. key .. " \"" .. w .. "\")"
            if not (okL and label == w) then bad[#bad + 1] = tostring(tab.id) end
        end
    end
    Q.check(seen == 3 and #bad == 0,
        "K3 #59: the Character window's tabs read the game's page words: Inventory, Temperature and Info",
        table.concat(said, "; ") .. ((#bad > 0) and ("; not the game's: " .. table.concat(bad, ", ")) or ""))
    -- (the World window's first tab stays Loot: a reading, not a check)
    local WW = ZeD_WorldWindow
    local wt = WW and WW.TABS
    local first = (type(wt) == "table") and wt[1] or nil
    local wl = nil
    if first and WW.tabLabel then pcall(function() wl = WW.tabLabel(first) end) end
    Q.say("NOTE #59: the World window's first tab " .. tostring(first and first.id) .. " reads \"" .. tostring(wl or (first and first.key)) .. "\" (it stays Loot)")
end

-- ===================================================================== #33 and #53: the probes
-- #33 (a): Options' Back question on a probe of the window
function S.k33options()
    local MM = Z.MainMenu
    local UI = MM and MM.ui or nil
    local Opt = ZeD_MMOptions
    if not (Opt and Opt.setConfirm and Opt.buildStrip and UI and UI.stripSpecs and MM.ctx) then
        Q.check(false, "K3 #33 (a) staging: ZeD's Options window (ZeD_MMOptions) and the main menu's band helpers are loaded (not proven)")
        return
    end
    local k = S.k33
    local field = { setVisible = function() end, isFocused = function() return false end, unfocus = function() end }
    local pr = setmetatable({ confirm = false, focusId = "row:music", field = field, _specs = {} }, { __index = Opt })
    pr.stopCapture = function() end
    pr.changedCount = function() return 1 end
    pr.discard = function() k.fired = "discard" end
    pr.discardStay = function() k.fired = "discard (stay)" end
    pr.apply = function() k.fired = "apply" end
    k.pr = pr
    k.ctxTaken, k.ctxOpen = true, MM.ctx.open
    local orig = UI.stripSpecs
    k.stripOrig, k.ui = orig, UI
    UI.stripSpecs = function(self, ...)
        if self == pr then
            local a = { ... }
            k.answers, k.ask = a[5], a[6]
            return 0
        end
        return orig(self, ...)
    end
    local ok1, e1 = pcall(Opt.setConfirm, pr, "back")
    local ok2, e2 = pcall(Opt.buildStrip, pr, 0, 40, 800)
    S.k33back()
    local apply, said = nil, {}
    for _, a in ipairs(k.answers or {}) do
        if type(a) == "table" then
            said[#said + 1] = tostring(a[1]) .. " \"" .. tostring(a[2]) .. "\" (" .. tostring(a[4]) .. ")"
            if a[1] == "confirm:apply" then apply = a end
        end
    end
    local ok = ok1 and ok2 and apply ~= nil and apply[2] == S.gt("UI_btn_apply") and apply[4] == "primary"
        and pr.focusId == "confirm:apply" and k.fired == nil
    Q.check(ok, "K3 #33 (a): Options' Back question, with a change made, offers the game's Apply as its main answer, and lands on it",
        "the band asks \"" .. tostring(k.ask) .. "\"; answers " .. ((#said > 0) and table.concat(said, ", ") or "none")
        .. "; the question lands on " .. tostring(pr.focusId) .. "; nothing answered " .. tostring(k.fired == nil)
        .. ((ok1 and ok2) and "" or ("; ERR " .. tostring(e1) .. " / " .. tostring(e2))))
end
-- the band's helper and the shared pull-down as found
function S.k33back()
    local k = S.k33
    if k.stripOrig and k.ui then k.ui.stripSpecs = k.stripOrig; k.stripOrig = nil end
    local MM = Z.MainMenu
    if k.ctxTaken and MM and MM.ctx then MM.ctx.open = k.ctxOpen; k.ctxTaken = nil end
    if k.fgTaken and MM then MM.forceGamepad = k.fgWas; k.fgTaken = nil end
end
-- a probe of the first-launch window: its Accept and Skip stubs say which one ended it (no file written)
function S.welcomeProbe(way, input)
    local pr = setmetatable({ way = way, input = input, tutorial = 1, snap = {} }, { __index = ZeD_MMWelcome })
    pr.done = function() pr.ended = "Accept (done)" end
    pr.skip = function() pr.ended = "Skip" end
    pr.saveSetup = function() pr.ended = "Save setup" end
    return pr
end
-- #33 (b), #53 (a), (b), (c)
function S.k53run()
    local MM = Z.MainMenu
    local Wc = ZeD_MMWelcome
    if not (Wc and Wc.close and Wc.onShow and MM and MM.gamepad) then
        Q.check(false, "K3 #33 (b) and #53 staging: the first-launch window (ZeD_MMWelcome) is loaded (not proven)")
        return
    end
    local k = S.k33
    -- #33 (b): the close box
    local p1, p3 = S.welcomeProbe(1, 1), S.welcomeProbe(3, 1)
    local okC1, e1 = pcall(Wc.close, p1)
    local okC3, e3 = pcall(Wc.close, p3)
    Q.check(okC1 and p1.ended == "Accept (done)" and p3.ended == "Skip",
        "K3 #33 (b): the first-launch window's close box keeps the picks (with Pick your own it ends as Accept, not Skip)",
        "Pick your own: the close box ends as " .. tostring(p1.ended) .. "; Skip picked as the way: " .. tostring(p3.ended)
        .. (okC1 and "" or ("; ERR " .. tostring(e1))) .. (okC3 and "" or ("; ERR " .. tostring(e3))))
    -- #53 (a): Playing with from the device in use (the window's onShow, with a controller on the desk and without)
    k.fgTaken, k.fgWas = true, MM.forceGamepad
    MM.forceGamepad = true
    local pPad = S.welcomeProbe(1, 1)
    local okS1, s1 = pcall(Wc.onShow, pPad)
    local okF, prompts = false, nil
    if Wc.getFooterPrompts then okF, prompts = pcall(Wc.getFooterPrompts, pPad) end
    MM.forceGamepad = nil
    local padNow = false
    pcall(function() padNow = MM.gamepad() == true end)
    local pMouse = S.welcomeProbe(1, 2)
    local okS2, s2 = pcall(Wc.onShow, pMouse)
    MM.forceGamepad = k.fgWas
    k.fgTaken = nil
    local wantMouse = padNow and 2 or 1
    Q.check(okS1 and okS2 and pPad.input == 2 and pMouse.input == wantMouse,
        "K3 #53 (a): the first-launch window's Playing with starts on the device in use (Controller with a pad on the desk)",
        "a controller on the desk: Playing with " .. tostring(pPad.input) .. " (1 Mouse and keys, 2 Controller; it was 1 before the show); "
        .. "the desk as it reads now (a controller " .. tostring(padNow) .. "): " .. tostring(pMouse.input) .. " (it was 2 before the show)"
        .. (okS1 and "" or ("; ERR " .. tostring(s1))) .. (okS2 and "" or ("; ERR " .. tostring(s2))))
    -- #53 (b): Y accepts (the desk's Y: "if w.joyY then w:joyY()"), and the footer names it
    local pY = S.welcomeProbe(1, 1)
    local hasY = pY.joyY ~= nil
    local okY, eY = true, nil
    if hasY then okY, eY = pcall(pY.joyY, pY) end
    local yWord, said = nil, {}
    if okF and type(prompts) == "table" then
        for _, pp in ipairs(prompts) do
            if type(pp) == "table" then
                said[#said + 1] = tostring(pp.glyph) .. " " .. tostring(pp.label)
                if pp.glyph == "Y" then yWord = pp.label end
            end
        end
    end
    Q.check(hasY and okY and pY.ended == "Accept (done)" and yWord == S.gt("UI_btn_accept"),
        "K3 #53 (b): on a pad, Y accepts the first-launch window, and its footer names Y",
        "the window's Y " .. (hasY and ("ends it as " .. tostring(pY.ended)) or "is not taken") .. "; the controller footer: "
        .. ((#said > 0) and table.concat(said, ", ") or "none") .. (okY and "" or ("; ERR " .. tostring(eY))))
    -- #53 (c)
    Q.skip("K3 #53 (c): the Style tip under Style", "the first-launch window draws only on the main menu's desk; no game path reaches it")
end

-- ===================================================================== #40 and #51 (a): the two window menus
function S.k40run()
    local w = S.w
    local pad = S.hasPad()
    local order, style, padRows, show, said = {}, {}, {}, {}, {}
    local seen = 0
    local curStyle = Z.Settings and S.optVal(Z.Settings.lookStyleOption) or nil
    for _, k in ipairs({ "c", "w" }) do
        local defs = S.menus[k]
        if type(defs) == "table" then
            seen = seen + 1
            local name = S.winName(k)
            local names = S.namesOf(defs)
            said[#said + 1] = name .. ": " .. table.concat(names, ", ")
            -- the Keyboard map (when ZeD has it) and ZeD setup lead
            local want = {}
            if Z.KeyboardMap and Z.KeyboardMap.open then want[#want + 1] = w.kmap end
            want[#want + 1] = w.setup
            local lead = true
            for i, n in ipairs(want) do if names[i] ~= n then lead = false end end
            if not lead then order[#order + 1] = name end
            -- Style, Full and Lite, the one in use checked
            local st = S.findDef(defs, w.style)
            local kids = (st and type(st.children) == "table") and st.children or {}
            local kn = S.namesOf(kids)
            local marked = false
            local kid = curStyle and kids[curStyle] or nil
            if kid and kid.checked then pcall(function() marked = kid.checked() == true end) end
            if not (st and #kn == 2 and kn[1] == w.full and kn[2] == w.lite and marked) then style[#style + 1] = name end
            -- the pad's rows
            if S.findDef(defs, w.focus) or S.findDef(defs, w.cmap) then padRows[#padRows + 1] = name end
            -- Show me around
            local sh = S.findDef(defs, w.show)
            if not (sh and type(sh.onFire) == "function") then show[#show + 1] = name end
        end
    end
    if seen < 2 then
        S.fail("menu", "only " .. seen .. " of the two window menus came down")
        return
    end
    local menus = table.concat(said, " | ")
    Q.check(#order == 0, "K3 #40 (a): each window's menu leads with the Keyboard map and ZeD setup",
        ((#order > 0) and ("not first on the " .. table.concat(order, " and ") .. " window; ") or "") .. menus)
    Q.check(#style == 0, "K3 #40 (b): each window's menu has Style, Full and Lite, the one in use checked",
        ((#style > 0) and ("missing or wrong on the " .. table.concat(style, " and ") .. " window; ") or "")
        .. "Style in use " .. tostring(curStyle) .. " (1 Full, 2 Lite)")
    if pad then
        Q.skip("K3 #40 (c): the controller's rows hidden without a controller", "a controller is connected for player " .. (S.pn + 1)
            .. ": its rows belong in the menu (shown on the " .. ((#padRows > 0) and table.concat(padRows, " and ") or "no") .. " window)")
    else
        Q.check(#padRows == 0, "K3 #40 (c): with no controller connected, no window's menu shows Controller highlight or Controller map",
            ((#padRows > 0) and ("shown on the " .. table.concat(padRows, " and ") .. " window") or "neither shows them"))
    end
    Q.check(#show == 0, "K3 #51 (a): each window's menu has a Show me around row that starts the tour",
        ((#show > 0) and ("missing on the " .. table.concat(show, " and ") .. " window") or ("\"" .. w.show .. "\" on both")))
end

-- ===================================================================== #51 (b): the tour pauses the game
function S.k51start()
    local TU = Z.Tutorial
    local k = S.k51
    if not (TU and TU.start and TU.stop and TU.running) then S.fail("tour", "the tour (ZeD.Tutorial) is not loaded"); return end
    if TU.running() then S.fail("tour", "a tour was already running"); return end
    if S.gameSpeed() == 0 then S.speed(1) end
    k.before, k.boxBefore = S.gameSpeed(), S.pausedBox()
    S.blockFiles(true)
    local def = S.findDef(S.menus.c, S.w.show)
    if def and type(def.onFire) == "function" then
        k.how = "the Character window's menu row Show me around"
        local ok, e = pcall(def.onFire)
        if not ok then Q.say("ERR the row's onFire: " .. tostring(e)) end
    else
        k.how = "TU.start (no Show me around row to fire: the first-launch way in)"
        local ok, e = pcall(TU.start, S.pn, "mouse")
        if not ok then Q.say("ERR TU.start: " .. tostring(e)) end
    end
    k.started = true
end
function S.k51check(ok)
    local TU = Z.Tutorial
    local k = S.k51
    local on = TU.running() == true
    local sp, ctl, box = S.gameSpeed(), S.spNow(), S.pausedBox()
    local step = nil
    pcall(function() step = TU.step() end)
    Q.check(ok and on and sp == 0, "K3 #51 (b): the game pauses while a tour balloon is up (the tour started by " .. tostring(k.how) .. ")",
        "the tour running " .. tostring(on) .. " on step " .. tostring(step) .. "; game speed " .. tostring(sp) .. " (before "
        .. tostring(k.before) .. "), the speed controls read " .. tostring(ctl) .. "; the game's Paused box shown " .. tostring(box)
        .. " (before " .. tostring(k.boxBefore) .. ")")
    -- Stop tour (its file write refused), then the guard off
    if on then
        local okS, e = pcall(TU.stop)
        if not okS then Q.say("ERR Stop tour: " .. tostring(e)) end
    end
    S.blockFiles(false)
end

-- ===================================================================== #42: the belt's note count
function S.k42stage()
    local M = Z.Messages
    local hud = S.hud()
    local k = S.k42
    if not (M and M.sources and M.unread and hud and Z.T and Z.T.danger and Z.T.textDim) then
        S.fail("belt", "ZeD's Messages, the belt and the theme's colors are loaded (Messages " .. tostring(M ~= nil) .. ", the belt " .. tostring(hud ~= nil) .. ")")
        return
    end
    if not S.beltShown() then S.fail("belt", "the belt is not on screen"); return end
    -- ZeD's own errors are filed under ZeD's mod name (ZeD_Messages fileError: the stack's "((MOD:name))")
    k.ours = "ZeD-GUI [BETA]"
    pcall(function()
        local mi = getModInfoByID("ZeD_UI")
        if mi then k.ours = tostring(mi:getName()) end
    end)
    -- every unread message set read for the test (put back after)
    for _, s in pairs(M.sources) do
        for _, it in ipairs((type(s) == "table" and s.items) or {}) do
            if type(it) == "table" and not it.read then
                it.read = true
                k.unread[#k.unread + 1] = it
            end
        end
    end
    S.beltWatch(hud)
    S.fakeErr(S.OTHER)
    k.t0 = getTimestampMs()
    k.count = nil
end
-- an unread error filed under name, as ZeD_Messages files one (a source that was there is set aside first)
function S.fakeErr(name)
    local M = Z.Messages
    local k = S.k42
    if M.sources[name] ~= nil and not k.made[name] and k.stash[name] == nil then k.stash[name] = M.sources[name] end
    M.sources[name] = { name = name, kind = "err", at = (M.seq or 0) + 1,
        items = { { k = "err", count = 1, firsts = { "QA vk3_scr: a test line, not a real error" }, texts = { "QA vk3_scr" }, whens = {}, read = false, when = "" } } }
    k.made[name] = true
    if type(M.seq) == "number" then M.seq = M.seq + 1 end
end
-- the belt's note watched: the badge's color, the one drawRect before the count's drawText inside _drawLamp
function S.beltWatch(hud)
    local k = S.k42
    if k.hook then return end
    k.hook = { hud = hud, dl = rawget(hud, "_drawLamp"), dr = rawget(hud, "drawRect"), dt = rawget(hud, "drawText") }
    local baseLamp, baseRect, baseText = hud._drawLamp, hud.drawRect, hud.drawText
    hud._drawLamp = function(self, b, f, h)
        k.inLamp, k.rect = true, nil
        local ok, e = pcall(baseLamp, self, b, f, h)
        k.inLamp = false
        if not ok then k.err = tostring(e) end
    end
    hud.drawRect = function(self, x, y, w, h, a, r, g, bb, ...)
        if k.inLamp then k.rect = { r = r, g = g, b = bb } end
        return baseRect(self, x, y, w, h, a, r, g, bb, ...)
    end
    hud.drawText = function(self, t, ...)
        if k.inLamp and k.rect then k.count = { text = tostring(t), c = k.rect, at = getTimestampMs() } end
        return baseText(self, t, ...)
    end
end
function S.beltUnwatch()
    local k = S.k42
    local h = k.hook
    if not h then return end
    k.hook = nil
    h.hud._drawLamp, h.hud.drawRect, h.hud.drawText = h.dl, h.dr, h.dt
end
-- the messages as found: the test's errors gone, a set-aside source back, every read mark back
function S.k42back()
    local M = Z.Messages
    local k = S.k42
    S.beltUnwatch()
    if not (M and M.sources) then return end
    for name, _ in pairs(k.made) do M.sources[name] = nil end
    for name, s in pairs(k.stash) do M.sources[name] = s end
    for _, it in ipairs(k.unread) do it.read = false end
    k.made, k.stash, k.unread = {}, {}, {}
    if type(M.seq) == "number" then M.seq = M.seq + 1 end
end
function S.k42fresh() local c = S.k42.count; return c ~= nil and c.at >= (S.k42.t0 or 0) end
function S.k42swap()
    local M = Z.Messages
    local k = S.k42
    k.other = k.count
    local s = M.sources[S.OTHER]
    for _, it in ipairs((s and s.items) or {}) do it.read = true end
    S.fakeErr(k.ours)
    k.t0 = getTimestampMs()
    k.count = nil
end
function S.k42check(ok)
    local k = S.k42
    local T = Z.T
    local o, z = k.other, k.count
    local gray = o ~= nil and S.near(o.c, T.textDim) and not S.near(o.c, T.danger)
    local red = z ~= nil and S.near(z.c, T.danger)
    Q.check(ok and gray and red,
        "K3 #42: the belt's note count is red only for ZeD's own errors; another mod's error is counted in gray",
        "another mod's error alone: the count " .. tostring(o and o.text) .. " on " .. S.rgb(o and o.c) .. "; ZeD's own (\"" .. tostring(k.ours)
        .. "\"): " .. tostring(z and z.text) .. " on " .. S.rgb(z and z.c) .. " (the theme's red " .. S.rgb(T.danger) .. ", gray "
        .. S.rgb(T.textDim) .. ")" .. (k.err and ("; ERR " .. k.err) or ""))
    S.k42back()
end

-- ===================================================================== #61: F1 with no tab topic
function S.k61press()
    local W, B = Z.Guide, Z.GuideBook
    local k = S.k61
    if not (W and W.toggle and W.contextTopicKey and B and B.isOpen and B.books) then S.fail("guide", "the guide (ZeD.Guide) and its book are not loaded"); return end
    if B.isOpen(0) then S.fail("guide", "the guide book was open"); return end
    if W.useBook and not W.useBook() then S.fail("guide", "the guide is its window here, not the book (Style " .. tostring(S.liteNow() and "Lite" or "Full") .. ", or a language the book cannot draw)"); return end
    local topic = nil
    pcall(function() topic = W.contextTopicKey() end)
    if topic ~= nil then S.fail("guide", "with both windows shut the guide still finds a tab topic: " .. tostring(topic)); return end
    S.blockFiles(true)
    S.holdBubble(true)
    local ok, e = pcall(W.toggle, 0)   -- (F1's own call: ZeD_SurvivalGuide.lua onKey)
    S.holdBubble(false)
    S.blockFiles(false)
    if not ok then Q.say("ERR F1: " .. tostring(e)) end
    k.pressed = true
end
function S.k61check(ok)
    local W, B = Z.Guide, Z.GuideBook
    local bk = B.books[0]
    local open = B.isOpen(0) == true
    local cp = bk and bk.contentsPage or nil
    local want = math.floor(((cp or 3) + 1) / 2)
    local sp = bk and bk.spread or nil
    Q.check(ok and open and cp ~= nil and sp == want and sp ~= 1,
        "K3 #61: F1 with no tab topic opens the guide book on its contents, not on the title pages",
        "the book open " .. tostring(open) .. " on spread " .. tostring(sp) .. "; its contents on page " .. tostring(cp) .. " (spread "
        .. want .. "); the first spread holds the copyright and title pages; the bubble's done asked " .. tostring(S.k61.bubbleAsked == true) .. " (held)")
    if open then
        S.blockFiles(true)
        S.holdBubble(true)
        local okT, e = pcall(W.toggle, 0)   -- (F1 again shuts it)
        S.holdBubble(false)
        S.blockFiles(false)
        if not okT then Q.say("ERR F1 again: " .. tostring(e)) end
    end
end

-- ===================================================================== #22: the speed keys
function S.k22stage()
    local St, Wt = Z.Settings, Z.Watch
    local k = S.k22
    if not (St and St.watchPlaceOption and St.lookStyleOption and Wt and Wt._wornWatch and S.hud()) then
        S.fail("speed", "ZeD's Watch option, Style, the watch and the belt are loaded"); return
    end
    k.taken = true
    local md = S.p:getModData()
    k.pop = md and md.ZeD_WatchPop
    if md then md.ZeD_WatchPop = nil end
    S.optSet(St.watchPlaceOption, 1)   -- (the Watch on the belt: ZeD's default)
    S.styleFull()                      -- (Lite keeps the watch in the corner, ZeD_Watch.lua W.beltMode)
    local worn = Wt._wornWatch(S.p)
    if worn then
        k.item = worn
        k.how = "his own " .. tostring(worn:getDisplayName())
        return
    end
    local it = RT.give(S.WATCH)
    if not it then S.fail("speed", "no watch could be given (" .. S.WATCH .. ")"); return end
    local loc = nil
    pcall(function() loc = it:getBodyLocation() end)
    pcall(function() k.prev = S.p:getWornItem(loc) end)
    local ok = pcall(function() S.p:setWornItem(loc, it) end)
    if ok then
        k.item, k.given, k.loc = it, it, loc
        k.how = "a " .. tostring(it:getDisplayName()) .. " given and worn"
    else
        S.fail("speed", "the watch given could not be worn")
    end
end
-- the watch put back: the one given taken off (RT.takeBack takes it away), a worn one before it back on; the options
function S.k22back()
    local k = S.k22
    if not k.taken then return end
    k.taken = nil
    local St, Wt = Z.Settings, Z.Watch
    if k.given then
        pcall(function() S.p:removeWornItem(k.given) end)
        if k.prev then pcall(function() S.p:setWornItem(k.loc, k.prev) end) end
        k.given = nil
    end
    pcall(function() if Wt and Wt.togglePop then Wt.togglePop(false) end end)
    local md = S.p:getModData()
    if md then md.ZeD_WatchPop = k.pop end
    if St and S.was.taken then S.optSet(St.watchPlaceOption, S.was.watch) end
end
-- the speed keys beside the belt's watch: { watch = box, keys = { [n] = box } } once the watch is on the belt
function S.k22row()
    local wb = S.boxes("watch")[1]
    if not wb then return nil end
    local keys, n = {}, 0
    for _, b in ipairs(S.boxes("speed")) do
        if type(b.n) == "number" then keys[b.n] = b; n = n + 1 end
    end
    return { watch = wb, keys = keys, n = n }
end
function S.k22rowCheck(ok)
    local k = S.k22
    local r = S.k22row()
    if not (ok and r) then S.fail("speed", "the worn watch did not come up on the belt (" .. tostring(k.how) .. ")"); return end
    k.row = r
    local all, said = r.n == 5, {}
    local lo, hi = nil, nil
    for n = 0, 4 do
        local b = r.keys[n]
        if not b then all = false
        else
            said[#said + 1] = n .. "@" .. S.num(b.x)
            lo = (lo == nil or b.x < lo) and b.x or lo
            hi = (hi == nil or b.x + b.w > hi) and (b.x + b.w) or hi
        end
    end
    -- beside the watch: the row's near edge within three keys' width of the watch's box
    local wb = r.watch
    local kw = (r.keys[0] and r.keys[0].w) or 0
    local beside = all and lo ~= nil and (math.abs(wb.x - hi) <= 3 * kw or math.abs(lo - (wb.x + wb.w)) <= 3 * kw)
    Q.check(all and beside, "K3 #22 (a): a row of five speed keys (Pause, Play, x1, x2, Wait) sits beside the belt's watch",
        "speed keys " .. tostring(r.n) .. ((#said > 0) and (" (" .. table.concat(said, ", ") .. ")") or "") .. "; the watch at "
        .. S.num(wb.x) .. " (" .. S.num(wb.w) .. " wide, " .. tostring(wb.wrist) .. " wrist); " .. tostring(k.how))
end
function S.k22press(n)
    local k = S.k22
    if S.off.speed or not k.row then return end
    local b = k.row.keys[n]
    local hud = S.hud()
    if not (b and hud) then return end
    local ok, e = pcall(hud.onMouseDown, hud, b.x + math.floor(b.w / 2), b.y + math.floor(b.h / 2))
    if not ok then Q.say("ERR the speed key " .. n .. ": " .. tostring(e)) end
    k.pressed = true
end
function S.k22read(n)
    local k = S.k22
    if S.off.speed or not k.row then return end
    k.res[n] = S.spNow()
end
function S.k22check()
    local k = S.k22
    if S.off.speed or not k.row then return end
    local bad, said = {}, {}
    for _, n in ipairs(S.PRESS) do
        local got = k.res[n]
        said[#said + 1] = "key " .. n .. " -> " .. tostring(got)
        local good = (n == 4 and type(got) == "number" and got >= 4) or got == n
        if not good then bad[#bad + 1] = tostring(n) end
    end
    Q.check(#bad == 0, "K3 #22 (b): one press of each speed key beside the watch sets that speed",
        table.concat(said, ", ") .. " (the game's speed controls: 0 paused, 1 x1, 2 x5, 3 x20, 4 Wait)"
        .. ((#bad > 0) and ("; wrong: " .. table.concat(bad, ", ")) or ""))
end

-- ===================================================================== #46: the dash's switches named on hover
-- one frame of the sweep (a waitUntil condition): each switch's spots in turn, the dash's hint read a frame later
function S.sweepTick()
    local k = S.k46
    if k.i > #k.list then
        k.mx, k.my = nil, nil
        return true
    end
    local t = k.list[k.i]
    if k.set then
        k.waited = k.waited + 1
        local cap = k.cap
        if cap and k.got[cap.id] == nil then k.got[cap.id] = tostring(cap.words or "") end
        if cap and cap.id == t.id then
            t.mx, t.my = k.mx, k.my   -- (the spot that named it: the key is pointed at there again)
            k.i, k.pt, k.set = k.i + 1, 1, false
            return false
        end
        if k.waited < 3 then return false end
        k.pt, k.set = k.pt + 1, false
        if k.pt > #S.SPOTS then
            local d = S.dash()
            local lamp = d and d._lampHov or nil
            if k.got[t.id] == nil then k.miss[#k.miss + 1] = t.id .. ((lamp ~= nil) and (" (a lamp's card took the spot: " .. tostring(lamp) .. ")") or "") end
            k.i, k.pt = k.i + 1, 1
        end
        return false
    end
    if k.got[t.id] ~= nil then
        k.i, k.pt = k.i + 1, 1
        return false
    end
    k.mx = math.floor(t.x + t.w * S.SPOTS[k.pt])
    k.my = math.floor(t.y + t.h * 0.5)
    k.cap, k.waited, k.set = nil, 0, true
    return false
end
function S.k46start()
    local k = S.k46
    local d = S.dash()
    k.dash = d
    k.list, k.got, k.miss, k.i, k.pt, k.set = {}, {}, {}, 1, 1, false
    local seen = {}
    for _, hr in ipairs((d and d._hit) or {}) do
        if type(hr) == "table" and type(hr.id) == "string" and not seen[hr.id] and (hr.w or 0) > 2 and (hr.h or 0) > 2 then
            seen[hr.id] = true
            k.list[#k.list + 1] = { id = hr.id, x = hr.x, y = hr.y, w = hr.w, h = hr.h, live = hr.enabled }
        end
    end
    -- (a car that came with its key in the lock: the key out of it, as bx_vehicles.lua takes it out; the car goes)
    local c = S.car
    if c and c.v then pcall(function() if c.v:isKeysInIgnition() then c.v:setKeysInIgnition(false); k.unlocked = true end end) end
    k.key0 = S.keyState()
    k.design = d and d._designId
    S.hintWatch(true)
    S.mockOn(d)
end
-- a switch's words in the game's words where the game has them, with its state where it has one
function S.wordsOk(id, words)
    if type(words) ~= "string" or words == "" or S.starts(words, "UI_ZeD_") or S.starts(words, "Tooltip_") then return false end
    local game = S.GAMEWORDS[id]
    if game then
        local hit = false
        for _, key in ipairs(game) do if S.starts(words, S.gt(key)) then hit = true end end
        if not hit then return false end
    end
    if S.STATEFUL[id] then
        return S.ends(words, " | " .. S.gt("UI_On")) or S.ends(words, " | " .. S.gt("UI_Off"))
    end
    return true
end
function S.k46check(ok)
    local k = S.k46
    local bad, said = {}, {}
    for _, t in ipairs(k.list) do
        local words = k.got[t.id]
        said[#said + 1] = t.id .. ((t.live == false) and " (dead)" or "") .. ": " .. ((words ~= nil) and ("\"" .. words .. "\"") or "nothing")
        if not S.wordsOk(t.id, words) then bad[#bad + 1] = t.id end
    end
    Q.check(ok and #k.list > 0 and #bad == 0,
        "K3 #46 (a): every switch on the dash names itself on hover, in the game's dashboard words and with its state",
        tostring(#k.list) .. " switches on the plate " .. tostring(k.design) .. "; " .. table.concat(said, "; ")
        .. ((#bad > 0) and (" | not named in the game's words: " .. table.concat(bad, ", ")) or "")
        .. ((#k.miss > 0) and (" | no hint at any spot: " .. table.concat(k.miss, ", ")) or ""))
    Q.say("NOTE #46: the dead switches are drawn as before (Build: the blank art needs an art rebuild; nothing here reads it)")
end
function S.k46hasIgnition()
    for _, t in ipairs(S.k46.list) do if t.id == "ignition" then return t end end
    return nil
end

-- ===================================================================== #60: a car's right-click
function S.k60run()
    local V = ISVehicleMenu
    local c = S.car
    if not (V and V.FillMenuOutsideVehicle and V.onEnter and V.onMechanic) then S.fail("car", "the game's vehicle menu (ISVehicleMenu) is not loaded"); return end
    if S.p:getVehicle() then
        Q.check(false, "K3 #60 staging: he is out of the car beside it (not proven)", "still in seat " .. tostring(S.seat()))
        return
    end
    if Z.Safe and Z.Safe.on and Z.Safe.on() then
        Q.check(false, "K3 #60 staging: ZeD is not in safe mode (not proven)")
        return
    end
    local rec = S.recorder()
    local ok, e = pcall(V.FillMenuOutsideVehicle, S.pn, rec, c.v, false)
    local wEnter, wMech = S.gt("IGUI_EnterVehicle"), S.gt("ContextMenu_VehicleMechanics")
    local enter, mech, names = nil, nil, {}
    for _, o in ipairs(rec.options) do
        names[#names + 1] = tostring(o.name)
        local a1 = o.args and o.args[1]
        if o.name == wEnter and o.onSelect == V.onEnter and a1 == c.v then enter = o end
        if o.name == wMech and o.onSelect == V.onMechanic and a1 == c.v then mech = o end
    end
    local dx, dy = 0, 0
    pcall(function() dx, dy = S.p:getX() - c.v:getX(), S.p:getY() - c.v:getY() end)
    Q.check(ok and enter ~= nil and mech ~= nil,
        "K3 #60: a car's right-click has the game's Enter Vehicle and Vehicle Mechanics, running the game's onEnter and onMechanic",
        "the menu: " .. ((#names > 0) and table.concat(names, ", ") or "empty") .. "; Enter Vehicle " .. tostring(enter ~= nil)
        .. (enter and (" (seat " .. tostring(enter.args[2]) .. ")") or "") .. ", Vehicle Mechanics " .. tostring(mech ~= nil)
        .. "; he " .. S.num(math.sqrt(dx * dx + dy * dy)) .. " tiles from the car's middle" .. (ok and "" or ("; ERR " .. tostring(e))))
end

-- ===================================================================== start
Q.step(5, function()
    local St = Z.Settings
    local ready = S.p ~= nil and St ~= nil and St.lookStyleOption ~= nil and ZeD_CharacterWindow ~= nil and ZeD_WorldWindow ~= nil
        and Z.T ~= nil and Z.T.px ~= nil
    if not ready then
        Q.check(false, "staging: ZeD's settings, the windows and the tokens are loaded (nothing proven)")
        S.dead = true
        return
    end
    if S.p:isDead() then
        Q.check(false, "staging: the character is alive (nothing is run on a dead one)")
        S.dead = true
        return
    end
    S.w = { kmap = S.tr("UI_ZeD_KMap_Title"), setup = S.tr("UI_ZeD_WinMenu_Setup"), show = S.tr("UI_ZeD_Welcome_ShowMe"),
        style = S.tr("UI_ZeD_Settings_LookStyle"), full = S.tr("UI_ZeD_Settings_Full"), lite = S.tr("UI_ZeD_Settings_Lite"),
        focus = S.tr("UI_ZeD_Settings_FocusStyle"), cmap = S.tr("UI_ZeD_Wheel_ControllerMap") }
    -- as found (the windows' open or shut last: the put-back reads the windows only once it is set)
    local char, world = S.charOpen(), S.worldOpen()
    local cw, ww = RT.cw(), RT.ww()
    S.was.geo = { c = char and S.geo(cw) or nil, w = world and S.geo(ww) or nil }
    S.was.tab = { c = (char and cw) and cw._activeTab or nil, w = (world and ww) and ww._activeTab or nil }
    local md = S.p:getModData()
    S.was.ws = { taken = md ~= nil, had = md ~= nil and md.ZeD_WinState ~= nil, v = md and S.copy(md.ZeD_WinState) or nil }
    S.was.style = S.optVal(St.lookStyleOption)
    S.was.watch = S.optVal(St.watchPlaceOption)
    local ts = St.opts and St.opts.dict and St.opts.dict.textSize or nil
    S.was.text = S.optVal(ts)
    S.was.speed = S.gameSpeed() or 1
    S.was.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
    S.was.health = S.health()
    S.was.queue = S.queueN()
    S.was.tour = (Z.Tutorial and Z.Tutorial.running) and Z.Tutorial.running() or false
    S.was.book = (Z.GuideBook and Z.GuideBook.isOpen) and Z.GuideBook.isOpen(0) or false
    S.was.fg = Z.MainMenu and Z.MainMenu.forceGamepad or nil
    S.was.hint = Z.Atoms and Z.Atoms.requestHint or nil
    S.was.fw = getFileWriter
    S.was.taken = true
    S.was.char, S.was.world = char, world
    Q.say("start: screen " .. RT.core:getScreenWidth() .. "x" .. RT.core:getScreenHeight() .. ", ZeD's scale " .. tostring(Z.T.scale)
        .. "; Character window open " .. tostring(char) .. " (" .. S.gs(S.was.geo.c) .. ", on " .. tostring(S.was.tab.c) .. "), World window open "
        .. tostring(world) .. " (" .. S.gs(S.was.geo.w) .. ", on " .. tostring(S.was.tab.w) .. "); Style " .. tostring(S.was.style)
        .. " (1 Full, 2 Lite), Watch " .. tostring(S.was.watch) .. " (1 belt), Text size " .. tostring(S.was.text) .. "; game speed "
        .. tostring(S.was.speed) .. "; he at " .. S.where() .. ", in a car " .. tostring(S.p:getVehicle() ~= nil) .. "; a controller "
        .. tostring(S.hasPad()) .. "; the tour running " .. tostring(S.was.tour) .. ", the guide book open " .. tostring(S.was.book)
        .. "; the prelude's car helpers " .. tostring(ZEDQA_CAR_SPAWN ~= nil))
    if S.was.speed ~= 1 then S.speed(1) end
end)

-- ===================================================================== #12, #59, #33 and #53 (read, and probes)
Q.step(2, function() if not S.dead then S.k12run() end end)
Q.step(2, function() if not S.dead then S.k59run() end end)
Q.step(2, function()
    if S.dead then return end
    S.blockFiles(true)   -- (the probes' Accept and Skip are stubs; the guard is the second lock)
    S.k33options()
    S.k53run()
    S.k33back()
    S.blockFiles(false)
end)

-- ===================================================================== #40 and #51: the window menus, the tour
Q.step(3, function()
    if S.dead then S.off.menu = true; return end
    S.openPair()
    S.restSig = nil
end)
S.waitUntil(4000, function() return S.off.menu or (S.charOpen() and S.worldOpen() and S.settled()) end, function(ok)
    if S.off.menu then return end
    if not (S.charOpen() and S.worldOpen()) then
        S.fail("menu", "the Character and World windows did not open (Character " .. tostring(S.charOpen()) .. ", World " .. tostring(S.worldOpen()) .. ")")
    end
end)
for _, k in ipairs({ "c", "w" }) do
    Q.step(3, function()
        if S.off.menu then return end
        S.closeWinMenu()
        local w = S.winOf(k)
        if w then w._boxDo = "menu" end   -- (what a press and release on the window box asks update() for)
    end)
    S.waitUntil(3000, function() return S.off.menu or S.menuOn(S.winOf(k)) ~= nil end, function(ok)
        if S.off.menu then return end
        local m = S.menuOn(S.winOf(k))
        if not (ok and m) then S.fail("menu", "the " .. S.winName(k) .. " window's box did not pull its menu down"); return end
        S.menus[k] = S.rowDefs(m)
        S.closeWinMenu()
    end)
end
Q.step(3, function() if not S.off.menu then S.k40run() end end)
Q.step(3, function()
    if S.dead then S.off.tour = true; return end
    S.k51start()
end)
S.waitUntil(2000, function()
    if S.off.tour then return true end
    local TU = Z.Tutorial
    return TU.running() == true and S.gameSpeed() == 0
end, function(ok)
    if S.off.tour or not S.k51.started then return end
    S.k51check(ok)
end)
Q.step(5, function()
    if S.off.tour or not S.k51.started then return end
    local TU = Z.Tutorial
    local sp = S.gameSpeed()
    Q.say("the tour stopped: running " .. tostring(TU.running()) .. ", game speed " .. tostring(sp) .. " (before " .. tostring(S.k51.before)
        .. "); the tour's file writes refused " .. tostring(S.blocked or 0))
    if sp ~= 1 then S.speed(1) end
end)

-- ===================================================================== #42: the belt's note count
Q.step(3, function()
    if S.dead then S.off.belt = true; return end
    S.k42stage()
end)
S.waitUntil(3000, function() return S.off.belt or S.k42fresh() end, function(ok)
    if S.off.belt then return end
    if not ok then
        Q.check(false, "K3 #42 staging: the belt draws its note's count for an unread error (not proven)", "no count drawn in 3 s" .. (S.k42.err and ("; ERR " .. S.k42.err) or ""))
        S.k42back()
        S.off.belt = true
        return
    end
    S.k42swap()
end)
S.waitUntil(3000, function() return S.off.belt or S.k42fresh() end, function(ok)
    if S.off.belt then return end
    S.k42check(ok)
end)

-- ===================================================================== #61: F1 with no tab topic (Style Full, the pair shut)
Q.step(3, function()
    if S.dead then S.off.guide = true; S.off.speed = true; return end
    S.styleFull()
    S.closePair()
end)
S.waitUntil(3000, function() return not S.charOpen() and not S.worldOpen() and not S.liteNow() end, function(ok)
    -- the layout each window found open saved as the pair shut just now: the put-back opens a shut one on this
    local md = S.p:getModData()
    if S.was.wsShut == nil and md then S.was.wsShut = S.copy(md.ZeD_WinState) end
    if S.off.guide then return end
    if not ok then S.fail("guide", "both windows shut and Style Full (Character " .. tostring(S.charOpen()) .. ", World " .. tostring(S.worldOpen()) .. ", Lite " .. tostring(S.liteNow()) .. ")"); return end
    S.k61press()
end)
S.waitUntil(2000, function()
    if S.off.guide or not S.k61.pressed then return true end
    local B = Z.GuideBook
    return B.isOpen(0) == true
end, function(ok)
    if S.off.guide or not S.k61.pressed then return end
    S.k61check(ok)
end)
Q.step(5, function()
    if S.gameSpeed() ~= 1 then S.speed(1) end   -- (the book's close sets x1; the run's speed is x1 until the put-back)
end)

-- ===================================================================== #22: the speed keys beside the belt's watch
Q.step(3, function()
    if S.off.speed then return end
    S.k22stage()
end)
S.waitUntil(4000, function()
    if S.off.speed then return true end
    local Wt = Z.Watch
    -- (the belt's speed keys press the watch's own: its instance must be up, ZeD_Watch.lua W.act)
    return S.k22row() ~= nil and (Wt.getInstance == nil or Wt.getInstance() ~= nil)
end, function(ok)
    if S.off.speed then return end
    S.k22rowCheck(ok)
end)
for _, n in ipairs(S.PRESS) do
    Q.step(2, function() S.k22press(n) end)
    Q.step(3, function() S.k22read(n) end)
end
Q.step(2, function()
    S.k22check()
    if S.gameSpeed() ~= 1 then S.speed(1) end
    S.k22back()
    S.styleBack()
end)

-- ===================================================================== #56, #46 and #60: the car
Q.step(10, function()
    if S.dead then S.off.car = true; return end
    if S.p:getVehicle() then S.fail("car", "he sat in a car when the run began"); return end
    if not S.carStart() then S.fail("car", "no car could be spawned: " .. tostring(S.carWhy)) end
end)
-- (the prelude's wait tries the strip's spots in turn, 4 s each; without it, one spawn and 10 s for its physics)
S.waitUntil(ZEDQA_CAR_WAIT and 45000 or 10000, function()
    if S.off.car then return true end
    if S.car then return S.carReady() end
    return not S.k56.waiting
end, function(ok)
    if S.off.car then return end
    if not (ok and S.car) then
        S.k56.gaveUp = true
        S.fail("car", "no car was ready to sit in (" .. (S.car and "its physics never woke" or tostring(S.carWhy or "the prelude's wait gave none")) .. ")")
        S.carAway()
        return
    end
    pcall(function() S.car.scriptName = tostring(S.car.v:getScriptName()) end)
    local seats = false
    pcall(function() seats = S.car.v:getMaxPassengers() >= 2 and S.car.v:isSeatInstalled(1) and not S.car.v:isSeatOccupied(1) end)
    if not seats then S.fail("car", "the car has no free passenger seat"); S.carAway(); return end
    local okIn, why = S.carIn(1)
    if not okIn then S.fail("car", "he could not be seated beside the driver's seat: " .. tostring(why)); S.carAway() end
end)
-- #56: the passenger keeps the belt and gets no dash
S.waitUntil(4000, function()
    if S.off.car then return true end
    return S.p:getVehicle() == S.car.v and S.beltShown() and not S.dashShown()
end, function(ok)
    if S.off.car then return end
    local hud = S.hud()
    local want = false
    if hud then pcall(function() want = hud:wanted() == true end) end
    Q.check(ok and S.seat() == 1,
        "K3 #56: in the passenger seat the belt stays and no dash shows (the dash is the driver's, as in the game)",
        "in the car " .. tostring(S.p:getVehicle() == S.car.v) .. ", seat " .. tostring(S.seat()) .. "; the belt wanted " .. tostring(want)
        .. ", drawn " .. tostring(hud and hud._drawn) .. "; the dash shown " .. tostring(S.dashShown()) .. "; " .. tostring(S.car.scriptName)
        .. " by " .. tostring(S.car.how))
    S.carOut()
end)
Q.waitMs(700)
Q.step(1, function()
    if S.off.car then return end
    if S.p:getVehicle() then S.fail("car", "he did not get out of the passenger seat"); return end
    local okIn, why = S.carIn(0)
    if not okIn then S.fail("car", "he could not be seated at the wheel: " .. tostring(why)) end
end)
-- #46: the dash up for the driver, the switches pointed at one by one (no key on him)
S.waitUntil(4000, function()
    if S.off.car then return true end
    local d = S.dash()
    return S.p:getVehicle() == S.car.v and d ~= nil and S.dashShown() and d._driver == true and #(d._hit or {}) > 0
end, function(ok)
    if S.off.car then return end
    if not ok then
        S.fail("car", "the dash did not come up for him at the wheel (seat " .. tostring(S.seat()) .. ", the dash shown " .. tostring(S.dashShown()) .. ")")
        return
    end
    S.k46start()
end)
S.waitUntil(30000, function()
    if S.off.car then return true end
    return S.sweepTick()
end, function(ok)
    if S.off.car then return end
    S.k46check(ok)
    local k = S.k46
    k.ign = S.k46hasIgnition()
    k.noKeyWords = k.ign and k.got.ignition or nil
    S.carPrep()   -- (its key in his inventory: the dash reads the key on him every 200 ms)
end)
Q.waitMs(700)
Q.step(1, function()
    local k = S.k46
    if S.off.car or not k.ign then return end
    k.cap = nil
    k.mx = k.ign.mx or math.floor(k.ign.x + k.ign.w * 0.5)
    k.my = k.ign.my or math.floor(k.ign.y + k.ign.h * 0.5)
end)
S.waitUntil(2000, function()
    local k = S.k46
    if S.off.car or not k.ign then return true end
    return k.cap ~= nil and k.cap.id == "ignition"
end, function(ok)
    if S.off.car then return end
    local k = S.k46
    local k0 = k.key0 or {}
    local k1 = S.keyState()
    local withKey = (k.cap and k.cap.id == "ignition") and tostring(k.cap.words) or nil
    local staged = k0.on == false and k0.lock == false and k0.wired == false
    local noKey, putKey = S.gt("Tooltip_Dashboard_NoKey"), S.gt("Tooltip_Dashboard_PutKeysInIgnition")
    if not staged then
        Q.check(false, "K3 #46 (b) staging: the car came with no key on him, none in the lock and not hotwired (not proven)",
            "key on him " .. tostring(k0.on) .. ", in the lock " .. tostring(k0.lock) .. ", hotwired " .. tostring(k0.wired))
    else
        Q.check(k.ign ~= nil and k.noKeyWords == noKey and k1.on == true and withKey == putKey,
            "K3 #46 (b): the key says the game's No key when there is none, and asks for the key once he has it",
            "no key: \"" .. tostring(k.noKeyWords) .. "\" (the game's \"" .. noKey .. "\"); the key on him " .. tostring(k1.on) .. ": \""
            .. tostring(withKey) .. "\" (the game's \"" .. putKey .. "\")" .. ((k.ign == nil) and "; the plate has no key switch" or "")
            .. (k.unlocked and "; the car came with its key in the lock: taken out first" or ""))
    end
    S.mockOff()
    S.hintWatch(false)
    S.carOut()
end)
Q.waitMs(700)
-- #60: out of the car beside it, the game's right-click fill for the car
Q.step(1, function()
    if S.off.car then return end
    S.k60run()
end)

-- ===================================================================== put back
Q.mark()
Q.step(3, function()
    S.k56.gaveUp = true   -- (a car the prelude's wait brings after this is taken away at once)
    S.mockOff()
    S.hintWatch(false)
    S.k42back()
    S.k33back()
    S.closeWinMenu()
    -- the tour stopped and the book shut, if the run left them (their file writes refused)
    S.blockFiles(true)
    S.holdBubble(true)
    local TU = Z.Tutorial
    if TU and TU.running and TU.running() and not S.was.tour then pcall(TU.stop) end
    local B = Z.GuideBook
    if B and B.isOpen and B.isOpen(0) and not S.was.book and B.close then pcall(B.close, 0) end
    S.holdBubble(false)
    S.blockFiles(false)
    S.k22back()
    S.styleBack()
    S.carAway()
end)
S.waitUntil(6000, function() return S.carGone() end, function(ok)
    S.carGoneOk = ok
    S.homeBack()
    RT.takeBack()   -- (the watch given)
    S.queueBack()
end)
Q.step(3, function()
    if S.was.char == nil then return end   -- (the run stopped before it read the windows)
    S.layoutBack(true)
    S.windowsBack()
end)
S.waitUntil(5000, function()
    if S.was.char == nil then return true end
    return S.charOpen() == S.was.char and S.worldOpen() == S.was.world
end, function()
    if S.was.char == nil then return end
    -- a window found shut: the layout the character keeps for it, as it was
    S.layoutBack(false)
    -- the windows on the tabs they were found on (the tour may have turned the Character window's)
    local cw, ww = RT.cw(), RT.ww()
    if S.was.char and cw and S.was.tab.c and cw._activeTab ~= S.was.tab.c then RT.charTab(S.was.tab.c) end
    if S.was.world and ww and S.was.tab.w and ww._activeTab ~= S.was.tab.w then RT.worldTab(S.was.tab.w) end
    S.restSig = nil
end)
S.waitUntil(3000, function()
    if S.was.char == nil then return true end
    return S.settled()
end, function()
    if S.was.char == nil then return end
    local moved = {}
    if S.was.char and S.placeBack(RT.cw(), S.was.geo.c) then moved[#moved + 1] = "Character" end
    if S.was.world and S.placeBack(RT.ww(), S.was.geo.w) then moved[#moved + 1] = "World" end
    S.moved = (#moved > 0) and table.concat(moved, " and ") or nil
end)
Q.step(10, function()
    if not S.was.taken then return end
    local St = Z.Settings
    if S.gameSpeed() ~= S.was.speed then S.speed(S.was.speed) end
    -- the tour, the book, the window menu
    local TU, B, WM = Z.Tutorial, Z.GuideBook, Z.WindowMenu
    local tour = (TU and TU.running) and TU.running() or false
    local book = (B and B.isOpen) and B.isOpen(0) or false
    local menu = WM and WM.current
    local menuUp = menu ~= nil and menu._ctx ~= nil and menu._ctx.open == true
    S.putBack(tour == S.was.tour and book == S.was.book and not menuUp, "the tour, the guide book and the window menus as found",
        "the tour running " .. tostring(tour) .. " (found " .. tostring(S.was.tour) .. "), the book open " .. tostring(book) .. " (found "
        .. tostring(S.was.book) .. "), a window menu up " .. tostring(menuUp) .. "; file writes refused " .. tostring(S.blocked or 0))
    -- the guards gone
    local MM = Z.MainMenu
    local fg = MM and MM.forceGamepad or nil
    local hint = Z.Atoms and Z.Atoms.requestHint or nil
    local G = Z.GuideBubble
    S.putBack(getFileWriter == S.was.fw and hint == S.was.hint and fg == S.was.fg and S.k33.stripOrig == nil and S.k61.doneOrig == nil
        and S.k42.hook == nil and S.k46.mock == nil and (G == nil or G.done ~= nil),
        "the game's getFileWriter, ZeD's hint call, the main menu's switches and helpers, the belt's and the dash's own drawing as found",
        "getFileWriter " .. tostring(getFileWriter == S.was.fw) .. ", requestHint " .. tostring(hint == S.was.hint) .. ", forceGamepad "
        .. tostring(fg) .. " (found " .. tostring(S.was.fg) .. ")")
    -- the messages
    local M = Z.Messages
    local left = 0
    if M and M.sources then
        if M.sources[S.OTHER] ~= nil then left = left + 1 end
        local s = S.k42.ours and M.sources[S.k42.ours] or nil
        if s and type(s.items) == "table" and s.items[1] and s.items[1].texts and s.items[1].texts[1] == "QA vk3_scr" then left = left + 1 end
    end
    S.putBack(left == 0 and #S.k42.unread == 0, "the messages as found (the test's errors gone, every read mark back)", "test errors left " .. left)
    -- the option values (values only, never applied or saved; Text size never touched)
    local style, watch = S.optVal(St.lookStyleOption), S.optVal(St.watchPlaceOption)
    local ts = St.opts and St.opts.dict and St.opts.dict.textSize or nil
    local text = S.optVal(ts)
    S.putBack(style == S.was.style and watch == S.was.watch and text == S.was.text, "Style, Watch and Text size values as found",
        "Style " .. tostring(style) .. " (found " .. tostring(S.was.style) .. "), Watch " .. tostring(watch) .. " (found " .. tostring(S.was.watch)
        .. "), Text size " .. tostring(text) .. " (found " .. tostring(S.was.text) .. ")")
    -- the car, the key, the watch, him
    local keyOn, watchOn = false, false
    local key = S.car and S.car.key
    if key then pcall(function() keyOn = S.p:getInventory():containsID(key:getID()) end) end
    local given = S.k22.item and (S.k22.how or ""):find("given", 1, true) and S.k22.item or nil
    if given then
        pcall(function() watchOn = S.p:getInventory():containsID(given:getID()) end)
        if not watchOn and S.k22.loc then pcall(function() watchOn = S.p:getWornItem(S.k22.loc) == given end) end
    end
    local carLeft = S.car ~= nil and S.carLive(S.car.v)
    local h = S.health()
    local dx, dy = S.p:getX() - S.was.pos.x, S.p:getY() - S.was.pos.y
    local home = dx * dx + dy * dy <= 2.25 and math.floor(S.p:getZ()) == math.floor(S.was.pos.z)
    S.putBack(not carLeft and not keyOn and not watchOn and S.p:getVehicle() == nil and not S.p:isDead() and home
        and (S.was.health == nil or h == nil or h >= S.was.health - 1),
        "the car gone, its key and the watch given out of his things, he on foot where he was found, alive and unhurt",
        "the car in the cell " .. tostring(carLeft) .. ", its key on him " .. tostring(keyOn) .. ", the watch given on him " .. tostring(watchOn)
        .. ", in a car " .. tostring(S.p:getVehicle() ~= nil) .. ", at " .. S.where() .. " (found at " .. S.num(S.was.pos.x) .. ","
        .. S.num(S.was.pos.y) .. "," .. S.num(S.was.pos.z) .. (S.movedFrom and ("; moved back from " .. S.movedFrom) or "")
        .. "), health " .. S.num(h) .. " (found " .. S.num(S.was.health) .. "), dead " .. tostring(S.p:isDead()))
    S.putBack(S.queued == nil and S.queueN() <= (S.was.queue or 0), "no timed action left by the run",
        "queued now " .. tostring(S.queueN()) .. " (found " .. tostring(S.was.queue) .. ")" .. (S.queued and ("; " .. S.queued .. " the run queued, cleared") or ""))
    -- the windows
    if S.was.char ~= nil then
        local cw, ww = RT.cw(), RT.ww()
        local c, w = S.charOpen(), S.worldOpen()
        local gc = c and S.geo(cw) or nil
        local gw = w and S.geo(ww) or nil
        local tc = (c and cw) and cw._activeTab or nil
        local tw = (w and ww) and ww._activeTab or nil
        S.putBack(c == S.was.char and w == S.was.world and S.sameGeo(gc, S.was.geo.c) and S.sameGeo(gw, S.was.geo.w)
            and tc == S.was.tab.c and tw == S.was.tab.w,
            "the Character and World windows open or shut as found, where and as big as they were, on their tabs",
            "Character open " .. tostring(c) .. " " .. S.gs(gc) .. " on " .. tostring(tc) .. " (found " .. tostring(S.was.char) .. " "
            .. S.gs(S.was.geo.c) .. " on " .. tostring(S.was.tab.c) .. "); World open " .. tostring(w) .. " " .. S.gs(gw) .. " on "
            .. tostring(tw) .. " (found " .. tostring(S.was.world) .. " " .. S.gs(S.was.geo.w) .. " on " .. tostring(S.was.tab.w) .. ")"
            .. (S.moved and ("; the reopen left " .. S.moved .. " elsewhere: set back by its own setters") or ""))
    end
    -- the game speed
    local sp = S.gameSpeed()
    S.putBack(sp == S.was.speed, "the game speed as found", "speed " .. tostring(sp) .. " (found " .. tostring(S.was.speed) .. ")")
end)
Q.start()
