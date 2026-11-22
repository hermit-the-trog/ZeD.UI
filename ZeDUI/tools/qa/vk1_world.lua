-- ZeDUI/tools/qa/vk1_world.lua  (Nov 22 2026, QA KISS batch K1; tag vk1_wld): the in-game proof of Build's fixes for
-- K1-6, K1-9, K1-11, K1-14 and K1-15 (ZeDUI/qa/audits/2026-11-22_kiss_bugs_K1.md). The old code is 2488ceead (what
-- shipped as 0.3.0-beta21c); the fixes are 7fb4f1f97 (K1-9, K1-11) and 9a7b0461a (K1-6, K1-14, K1-15), all in
-- 0ebd56570. Built on rt_kit.lua (the global RT) and the prelude's car helpers (ZEDQA_CAR_*), run after
-- zedqa_prelude.lua. grep "ZEDQA vk1_wld". Manifest line (QA writes vk1.txt): vk1_world.lua | vk1_wld | timeout=480
--
-- How to read the log: the 13 proofs are the lines that start "K1-"; each of them FAILS on 2488ceead and PASSES on
-- 0ebd56570. Staging and put-back print "ok ..." lines and become a FAIL (its words start "... staging:" or "put
-- back:") only when they go wrong: a part that could not be staged FAILS, it never passes quietly, and its proofs are
-- then not run. "NOTE" lines are readings, never checks. A SKIP is said only for K1-9 on a game with the mechanics
-- cheat on.
--
-- K1-15 The guide's bubble shows on default settings.
--   Finding: the bubble is a Messages balloon and M.notice asked for it with force false; balloons are off by
--   default, so a new player's offer ended at once (G.done("off")) and left a paper note.
--   Staging (rt_hud.lua's guide check, with the balloons at their default instead of on): ZeD setup's Messages
--   balloons (messagesToast) set to its default, Off; the game's Show the guide on startup on (its default); the flag
--   file Zomboid/Lua/ZeD_guidebubble.txt emptied (a machine that never had the bubble); the clock shortened (first
--   showing after 1 s, up for 3 s); G.start(). The game's own OnTick drives G.tick.
--   15  The bubble comes out within 6 s with the guide's words (a balloon from the source "Survival guide" whose text
--       is G.text(0)). Old: toast() refuses it (force false, balloons Off), no bubble, the offer ends "off" -> FAIL.
--
-- K1-6 Hide the interface leaves the mouse's window menu.
--   6   Each window's three-line menu, pulled down by the window box's own click action (win._boxDo = "menu", what a
--       press and release on the box asks update() for), on the Character and the World window: no row reads "Hide
--       the interface" (UI_ZeD_Wheel_HideInterface). Old: WM.build adds that row to the setup group -> FAIL.
--   NOTE (not a check, read from the code first): the way back. The interface hidden the way the old row did it (the
--   View wheel's H.hideInterface, ISUIHandler.toggleUI), then the two calls Escape and Resume make
--   (ISUIHandler.setVisibleAllUI(false), then (true)): the line says which of the windows, the belt, the watch and the
--   moodles are back. On both old and new the windows come back and the belt, watch and moodles do not: the fix's
--   WM.showHud returns while ISUIHandler.allUIVisible is false, and only Toggle UI sets it again (Escape and Resume
--   leave it false). With the row gone the mouse cannot fall into that state; the pad's View wheel still has Show the
--   interface. Then Toggle UI again. So the fix's second half (the way back) is not proven here: in the audit's own
--   steps it changes nothing a player sees, and a plain Escape and Resume already brings everything back on the old
--   code (the game shows again, by table, each panel it hid).
--
-- K1-14 The tour, the guide and the Controller map name keys and buttons that do what they say.
--   14a The tour with the mouse (ZeD.Tutorial started in "mouse" mode, each step shown by the tour's own Next, its
--       balloon's words read from the tour's content, R.content): the Character and World steps name, before
--       "opens", the player's live Toggle Inventory key (getKeyName of getCore():getKey("Toggle Inventory")) and say
--       it opens both windows; the Guide step names the guide's own key (ZeD.Guide.bubbleKey, F1 unless rebound); and
--       that inventory key, pressed through ZeD's inventory key handler (ZeD_CharacterWindow._onKeyPressed, what the
--       key reaches) with both windows shut, opens both. Old: the Character step says "Tab opens it" (Tab is not the
--       inventory key) and the World step "I opens it" -> FAIL. (The Guide part alone does not tell old from new where
--       the guide key is F1, the default: the old step said F1 in fixed words. It guards a rebound key only.)
--   14b The tour on a controller ("pad" mode): every button the Character and World steps name does what they say.
--       The one named before "opens", pressed through ZeD's controller poll (FocusManager's QA hook, the input mode
--       locked to the controller, both windows shut, the pad let go), opens both windows; and where the steps say
--       "<buttons> step the tabs", each bumper named there (LB, RB), tapped with the pair open and the pad on the
--       Character window (FocusManager's own press, dispatchJoypadDown on the window holding the pad, then the hook's
--       release, as a tap reaches the poll), steps its own window's tab (LB the Character window's, RB the World
--       window's). Old: "LB opens it", "RB opens it" and no tab words; a bumper alone opens nothing -> FAIL.
--   14c The controller tour's Card step names the control that opens an item's card. Read on the Character window's
--       list, on a thing given for the run, with no card open: a D-pad step onto its row (FocusManager's own D-pad
--       dispatch, from the row beside it) opens no card; A tapped on it does (the drawer shows that thing's card).
--       Old: "Move to an item with the D-pad and its card opens": the D-pad step opens none -> FAIL.
--   NOTE (not a check) where that A left the pad: the new Controller map A line says "A again opens its menu", but A
--       on a row moves the pad onto the card's main button (Focus.focusPrimarySoon), so A again runs that button (Eat
--       on food). The line names the zone and the button the pad is on; nothing is pressed.
--   14d The guide bubble's controller words (UI_ZeD_Guide_BubblePad, what the bubble names on a controller):
--       "D-pad <dir>, then <slice>": that D-pad wheel, opened by the game's own opener (ISDPadWheels.onDisplay<Dir>),
--       has a slice of that name, and taking it (the slice's own command) opens a wheel holding the survival guide's
--       slice (Show/Hide Survival Guide). Old: "D-pad Right, then Survival Guide": ZeD's World wheel has no such
--       slice -> FAIL.
--   14e What X does: X tapped on the thing's row (the controller's own press, down then up) starts a move of it to
--       the World window's container (the game's transfer is caught at ISTimedActionQueue.add and never queued, so
--       nothing moves) and opens no menu; the Controller map's X line says X moves (no menu), the guide's controller
--       chapter says X moves an item, and the Moving page's controller line names X for the move. Old: "RMB: it opens
--       the context menu", "{pad:X} a right click", "{pad:A} on an item, then Move in its card" -> FAIL. (The detail
--       says where the caught move was going: X queues it at once, with no picking step, so the Moving page's "then
--       pick where it goes" is not read as a claim here.)
--   14f The Controller map's A, X and B lines and the guide's controller chapter name no mouse button (LMB, RMB, left
--       click, right click). Old: "LMB: it opens ...", "RMB: it opens ...", "{pad:A} is a left click" -> FAIL.
--
-- K1-11 The Vehicle tab's key line reads the ignition.
--   A car (Base.CarNormal) spawned by the prelude's helper on the drag strip: no key anywhere, not hotwired, its
--   driver's door unlocked (so the hood's rule, VehicleUtils.RequiredKeyNotFound, says no key is needed, as on most
--   found cars). He stands two squares beside it; the World window on its Vehicle tab, on that car. The key line is
--   read as the tab draws it: a pass-through wrapper on ZeD.Molecules.drawStatRowDot records the value drawn beside
--   the label Key while the tab shows this car.
--   11a No key on him: the line reads No key (UI_ZeD_Dash_PromptNoKey) with the game's easy use off, and Not needed
--       only with it on (SandboxVars.VehicleEasyUse set for one reading each, then put back). Old: Not needed with
--       easy use off (the hood's rule) -> FAIL.
--   11b The car's key in his pocket: On you; then seated at the wheel, the key put in by the game's own
--       BaseVehicle.setKeysInIgnition (it leaves his pocket), out of the car again: Key in ignition (the game's
--       Tooltip_Dashboard_KeysIgnition without its full stop). Old: Not needed with the key in the ignition -> FAIL.
--
-- K1-9 The hood after a look.
--   The same car. A look is the game's U: the mechanics key through ISVehicleMenu.onKeyPressed with the player's own
--   binding when the game picks this car (else ISVehicleMenu.onMechanic on it, said in the detail): he walks to the
--   hood, opens it and looks, and ZeD opens the World window's Vehicle tab. A look is done when the car is inspected,
--   the window is open on that tab and the hood is open. A game with its mechanics cheat on skips the walk and the
--   hood: then K1-9 is a SKIP.
--   9b  After a look, U again with the Vehicle tab open closes the World window within 1.5 s. Old: the tab is opened
--       again (MT.openFromAction) and the window stays -> FAIL.
--   9c  After a look, E at the open hood (the game's use event, VehicleUtils.OnUseVehicle, when the hood is the part
--       the game offers him there; else the hood's own use function, which E reaches at the hood) shuts the hood
--       within 6 s and queues no look. Old: vanilla's Vehicles.Use.EngineDoor queues the look again and the hood stays
--       open -> FAIL.
--   9a  After a look, the World window closed by its close box (win._boxDo = "close") shuts the hood within 6 s.
--       Old: the hood stays open -> FAIL.
--
-- Safety: nothing here can hurt him (no wound, no food, no drink, no book; the one A on a thing's row is a tap on a
-- kitchen tool, which opens its card; the X move is caught before it is queued; the seat at the wheel is for the key
-- only, the engine never starts). Every timed action this script starts is a walk, a door or a look; the queue is
-- cleared after the E and close-box checks, when a look cannot be staged, and in the put-back.
-- What it puts back (also when a step throws or the time runs out): the guide bubble's state, file and settings as
-- rt_hud's putGuide does; the tour stopped and its file (Zomboid/Lua/ZeD_tutorial.txt) as found; the interface
-- shown; wheels and menus closed; the pad's QA hook let go, the focus released, the input lock and the mode ZeD reads
-- as found (vx12_wheel.lua's way); the two wrappers taken off; the given thing taken away (from the floor too, if a
-- move got through); the Character window's selection as found; the car: him out of it, its key off him, the car
-- removed (the prelude's ZEDQA_CAR_AWAY); SandboxVars.VehicleEasyUse as found; him where he stood; his hunger,
-- thirst, fatigue, stress, sickness, endurance and panic as found; the windows open or shut, placed, sized and on the
-- tabs they were found on (vx12_wheel.lua's layout put-back). No option is saved, ZEDQA_LAYOUT_BACK is never called.
-- "Alive and well" is judged against the start: dead, health under what it was (and under 99.5), or an infection he
-- did not have FAILS; a character another script left hurt is not this script's FAIL.
-- Not run offline before the first game run; parse-checked with the game's Kahlua compiler (KCheck).
-- (Nov 22 2026, adversarial review: 14b now proves the new pad words' "LB and RB step the tabs" too, not only "Y
-- opens both windows"; a NOTE says where A leaves the pad, against the Controller map's "A again opens its menu";
-- the caught X move says where it was going; the health check reads against the start; two list reads are guarded.)

if not (RT and RT.make) then
    print("ZEDQA vk1_wld ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vk1_wld VERDICT FAIL 1")
    print("ZEDQA vk1_wld DONE")
    return
end

local Q = RT.make("vk1_wld")
Q.maxMs = 330000   -- (five and a half minutes, then the put-back; a run takes about two)
local Z = ZeD or {}
local S = { p = RT.p, pn = RT.pn, was = { geo = {}, tab = {} }, off = {}, kN = 0, kMark = 0, kv = {}, qRec = {},
            padRes = {}, menus = {}, tourM = {}, tourP = {}, bub = {}, row = {} }
local H = {}
S.Det = Z.Input and Z.Input.Detector
S.Focus = Z.Input and Z.Input.Focus
S.GFILE = "ZeD_guidebubble.txt"
S.TFILE = (Z.Tutorial and Z.Tutorial.FILE) or "ZeD_tutorial.txt"
-- the QA hook's names for the buttons a line can name
H.HOOK = { Y = "Y", LB = "LeftBump", RB = "RightBump", A = "A", B = "B", X = "X" }
-- the bumpers a step can say step the tabs: the hook's name and the window whose tabs that bumper steps
H.BUMP = { LB = { hook = "LeftBump", side = "c" }, RB = { hook = "RightBump", side = "w" } }
H.DIRFN = { down = "onDisplayDown", right = "onDisplayRight", left = "onDisplayLeft", up = "onDisplayUp" }
-- kitchen tools for the pad's row (not food, not a drink, nothing the game uses on a hold): the first he does not carry
H.TOOLS = { "Base.Spatula", "Base.Ladle", "Base.RollingPin", "Base.Spoon", "Base.Kettle", "Base.Pan" }
H.MOUSE = { "lmb", "rmb", "left click", "right click" }
H.STATS = { "HUNGER", "THIRST", "FATIGUE", "STRESS", "SICKNESS", "ENDURANCE", "PANIC" }

-- ===================================================================== words and numbers
-- (every reading asks before it indexes: in -debug a throw caught by pcall still logs a Java exception, and the runner
-- counts it)
function H.num(v)
    local x = tonumber(v)
    if x == nil then return "?" end
    local r = math.floor(x * 10 + 0.5) / 10
    if r == math.floor(r) then return tostring(math.floor(r)) end
    return tostring(r)
end
function H.trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
function H.lower(s) return string.lower(tostring(s or "")) end
function H.firstLine(text)
    for l in tostring(text or ""):gmatch("[^\n]+") do
        local t = H.trim(l)
        if t ~= "" then return t end
    end
    return ""
end
function H.has(list, x)
    for _, v in ipairs(list or {}) do if v == x then return true end end
    return false
end
-- the mouse's words found in a controller's line
function H.mouseWords(text)
    local low, out = H.lower(text), {}
    for _, w in ipairs(H.MOUSE) do if low:find(w, 1, true) then out[#out + 1] = w end end
    return out
end
-- what a line says a button does: "menu" (a menu, a right click), "move" (it moves the thing), else "?"
function H.claim(text)
    local low = H.lower(text)
    if low:find("menu", 1, true) or low:find("right click", 1, true) or low:find("rmb", 1, true) then return "menu" end
    if low:find("move", 1, true) then return "move" end
    return "?"
end
function H.keyName(code)
    local n = nil
    if code and code ~= 0 then pcall(function() n = getKeyName(code) end) end
    if n == nil or n == "" then return tostring(code) end
    return tostring(n)
end
function H.list(t)
    local out = {}
    for _, v in ipairs(t or {}) do out[#out + 1] = tostring(v) end
    return table.concat(out, ", ")
end

-- ===================================================================== waits and reports
-- until cond() holds (asked every drawn frame), for at most ms of real time; then fn(ok)
function H.waitUntil(ms, cond, fn)
    local st = {}
    Q.waitFor(1, math.floor(ms / 3) + 900, function()
        local now = getTimestampMs()
        st.t = st.t or now
        local okC, r = pcall(cond)
        if okC and r then st.ok = true; return true end
        return now - st.t >= ms
    end, function() fn(st.ok == true) end)
end
-- the same, skipped once the start failed
function H.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function H.wait(ms, cond, fn)
    H.waitUntil(ms, function() if S.dead then return true end; return cond() end, function(ok)
        if S.dead then return end
        fn(ok)
    end)
end
-- staging and put-back: an "ok" line, or a FAIL when it went wrong
function H.must(ok, what, detail)
    if ok then
        Q.say("ok " .. tostring(what) .. ((detail ~= nil) and (" | " .. tostring(detail)) or ""))
        return true
    end
    Q.check(false, what, detail)
    return false
end

-- ===================================================================== windows (vx12_wheel.lua)
function H.charOpen()
    local CW = ZeD_CharacterWindow
    return (CW ~= nil and CW.isOpen ~= nil and CW.isOpen(S.pn)) and true or false
end
function H.worldOpen()
    local WW = ZeD_WorldWindow
    return (WW ~= nil and WW.isOpen ~= nil and WW.isOpen(S.pn)) and true or false
end
function H.pairVisible()
    local c, w = RT.cw(), RT.ww()
    local v = false
    pcall(function() v = c ~= nil and w ~= nil and c:isVisible() and w:isVisible() end)
    return v and true or false
end
function H.geo(w)
    if not w then return nil end
    return { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() }
end
function H.gs(g)
    if not g then return "none" end
    return H.num(g.x) .. "," .. H.num(g.y) .. " " .. H.num(g.w) .. "x" .. H.num(g.h)
end
function H.sameGeo(a, b)
    if a == nil or b == nil then return a == nil and b == nil end
    return math.abs(a.x - b.x) <= 1 and math.abs(a.y - b.y) <= 1 and math.abs(a.w - b.w) <= 1 and math.abs(a.h - b.h) <= 1
end
function H.copy(t, depth)
    if type(t) ~= "table" then return t end
    depth = depth or 0
    local out = {}
    for k, v in pairs(t) do out[k] = (depth < 6) and H.copy(v, depth + 1) or v end
    return out
end
-- the pair shut (a pause closes only the Character window, so anything left is shut too)
function H.closePair()
    local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
    if not (CW and WW) then return end
    if H.charOpen() and H.worldOpen() and CW.toggleBothPaired then pcall(CW.toggleBothPaired, S.pn) end
    if H.charOpen() and CW.toggle then pcall(CW.toggle, S.pn) end
    if H.worldOpen() and WW.close then pcall(WW.close, S.pn) end
end
-- the windows open or shut as found
function H.windowsBack()
    local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
    if not (CW and WW) then return end
    if S.was.char and S.was.world and not H.charOpen() and not H.worldOpen() and CW.toggleBothPaired then
        pcall(CW.toggleBothPaired, S.pn)
    end
    if S.was.char and not H.charOpen() and CW.toggle then pcall(CW.toggle, S.pn) end
    if S.was.world and not H.worldOpen() and WW.open then pcall(WW.open, S.pn) end
    if S.was.char == false and H.charOpen() and CW.toggle then pcall(CW.toggle, S.pn) end
    if S.was.world == false and H.worldOpen() and WW.close then pcall(WW.close, S.pn) end
end
-- the layout the character keeps for each window (md.ZeD_WinState.char / .world, what a window opens on). open true:
-- the windows found open get the layout they saved when the test first shut them; open false: the windows found
-- shut get the layout they had
function H.layoutBack(open)
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
        if k[2] == open and (src[k[1]] ~= nil or not open) then cur[k[1]] = H.copy(src[k[1]]) end
    end
end
-- the windows at rest: the same places and sizes for 300 ms
function H.settled()
    local cw, ww = H.charOpen() and RT.cw() or nil, H.worldOpen() and RT.ww() or nil
    local sig = H.gs(H.geo(cw)) .. " | " .. H.gs(H.geo(ww))
    local now = getTimestampMs()
    if sig ~= S.restSig then
        S.restSig, S.restAt = sig, now
        return false
    end
    return now - S.restAt >= 300
end
-- a window not where it was found, set back by its own setters (never ZEDQA_LAYOUT_BACK); true when it moved it
function H.placeBack(w, g)
    if not (w and g) or H.sameGeo(H.geo(w), g) then return false end
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
-- a window kept up while it is read: its halves unfolded, unrolled, its hover roll-up held (an unpinned window
-- rolls up when the pointer is elsewhere; as MechanicsTab's openFromAction and the tour hold it)
function H.hold(w)
    if not w then return end
    if w._halves and Z.Halves and Z.Halves.showAll then pcall(Z.Halves.showAll, w) end
    if w.windowShaded and w.setWindowShaded then
        w._autoShaded = false
        pcall(w.setWindowShaded, w, false)
    end
    w._outSince = getTimestampMs() + 600000
end
function H.holdBoth() H.hold(RT.cw()); H.hold(RT.ww()) end
-- the roll-up held only (asked every frame while a wait runs)
function H.keep(w) if w then w._outSince = getTimestampMs() + 600000 end end
-- both windows open (the pair by the inventory key's own toggle, then each on its own)
function H.openBoth()
    local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
    if not (CW and WW) then return end
    if not H.charOpen() and not H.worldOpen() and CW.toggleBothPaired then pcall(CW.toggleBothPaired, S.pn) end
    if not H.charOpen() and CW.toggle then pcall(CW.toggle, S.pn) end
    if not H.worldOpen() and WW.open then pcall(WW.open, S.pn) end
end
-- the pair shut; the first time, the layout each open window saved as it shut is kept for the put-back
function H.shutPair()
    H.closePair()
    if S.was.wsShut == nil and S.p then
        local md = S.p:getModData()
        S.was.wsShut = (md and H.copy(md.ZeD_WinState)) or false
    end
end

-- ===================================================================== the input mode ZeD reads (vx12_wheel.lua)
-- the lock as found: ZeD setup's Input lock, as Settings.lua applies it ("auto" is no lock); the save's copy only
-- when the setting cannot be read
function H.lockFound()
    local key = nil
    local api = PZAPI and PZAPI.ModOptions
    local zo = (api and api.getOptions) and api:getOptions("ZeD_UI") or nil
    local o = zo and zo.dict and zo.dict.inputModeLock
    local keys = Z.Settings and Z.Settings.inputLockKeys
    if o and o.getValue and keys then key = keys[o:getValue() or 1] end
    if key == nil and S.p then
        local md = S.p:getModData()
        local g = md and md.ZeD_Gamepad
        key = g and g.inputModeLock
    end
    return key or "auto"
end
function H.mode() return (S.Det and S.Det.getMode) and S.Det.getMode(S.pn) or nil end
-- mode "gamepad"; nil or false puts back the lock found (only a lock this script set)
function H.lock(mode)
    if not (S.Det and S.Det.setLockedMode) then return end
    if mode then
        if S.lockWas == nil then S.lockWas = H.lockFound() end
        S.Det.setLockedMode(mode)
        S.locked = true
        return
    end
    if not S.locked then return end
    S.locked = false
    S.Det.setLockedMode(nil)
    if S.lockWas == "kbm" or S.lockWas == "gamepad" then S.Det.setLockedMode(S.lockWas) end
end
-- the lock lifted, and with no lock found the mode ZeD read: a moment's lock on the mode found lets the detector's
-- tick take it (H.modeFree lifts it)
function H.modeBack()
    local held = S.locked
    H.lock(false)
    if not (held and S.lockWas == "auto" and S.was.mode ~= nil and S.Det and S.Det.setLockedMode) then return end
    local want = (S.was.mode == "gamepad") and "gamepad" or "kbm"
    if H.mode() == want then return end
    S.Det.setLockedMode(want)
    S.modeHeld = want
end
function H.modeFree()
    if not S.modeHeld then return end
    S.modeHeld = nil
    S.Det.setLockedMode(nil)
end

-- ===================================================================== wheels and menus (vx12_wheel.lua)
function H.wheelSt()
    local D = Z.DpadWheels
    return (D and D.state) and D.state[S.pn] or nil
end
function H.radial() return getPlayerRadialMenu and getPlayerRadialMenu(S.pn) or nil end
-- (a wheel never built has no element: it is not on screen, and asking would build one)
function H.vis(m)
    if not (m and m.javaObject ~= nil and m.isReallyVisible) then return false end
    return m:isReallyVisible() and true or false
end
function H.closeWheel()
    local D = Z.DpadWheels
    if not D then return end
    if H.wheelSt() and D.close then pcall(D.close, S.pn) end
    local st = H.wheelSt()
    if st and st.menu and st.menu.undisplay then pcall(st.menu.undisplay, st.menu) end
    if D.state then D.state[S.pn] = nil end
    local m = H.radial()
    if m and m.undisplay and H.vis(m) then pcall(m.undisplay, m) end
end
-- a ZeD right-click menu, or the game's, closed
function H.closeMenu()
    local v = getPlayerContextMenu and getPlayerContextMenu(S.pn) or nil
    if not v then return end
    local zm = v._zedMenu
    if zm and zm.close then pcall(zm.close, zm) end
    if not v._zedMenu and v.javaObject ~= nil and v.closeAll and v:isVisible() then pcall(v.closeAll, v) end
end
-- a context menu on screen (ZeD draws the game's)
function H.menuUp()
    local v = getPlayerContextMenu and getPlayerContextMenu(S.pn) or nil
    if not v then return false end
    local zm = v._zedMenu
    if zm and zm._ctx and zm._ctx.open then return true end
    local up = false
    if v.javaObject ~= nil then pcall(function() up = v:isVisible() end) end
    return up == true
end
-- a window's box menu closed
function H.closeWinMenu()
    local WM = Z.WindowMenu
    local m = WM and WM.current
    if m and m._ctx and m._ctx.open and m.close then pcall(m.close, m) end
end
function H.release()
    if S.Focus and S.Focus.releaseFocus then pcall(S.Focus.releaseFocus, S.pn) end
end
-- nothing but the wheel: no wheel or menu up, the pad let go, the pair shut
function H.toWheel()
    H.closeWheel()
    H.closeMenu()
    H.release()
    H.shutPair()
    H.release()
    if setJoypadFocus then pcall(setJoypadFocus, S.pn, nil) end
end
-- the wheel opened the way the game opens it; ZeD.DpadWheels.open only when that did not
function H.openWheel(dir, fn)
    local D = Z.DpadWheels
    if ISDPadWheels and ISDPadWheels[fn] then pcall(ISDPadWheels[fn], { player = S.pn, id = nil }) end
    local st = H.wheelSt()
    if st and st.dir == dir then return true, "the game's opener, ISDPadWheels." .. fn end
    local ok, e = pcall(D.open, dir, { player = S.pn, id = nil })
    if not ok then Q.say("ERR open " .. dir .. ": " .. tostring(e)) end
    st = H.wheelSt()
    return st ~= nil and st.dir == dir, "ZeD.DpadWheels.open (the game's opener left it shut)"
end
function H.sliceNames(m)
    local out = {}
    for _, s in ipairs((m and m.slices) or {}) do out[#out + 1] = H.firstLine(s.text) end
    return out
end
function H.sliceIdx(m, name)
    for i, s in ipairs((m and m.slices) or {}) do if H.firstLine(s.text) == name then return i end end
    return nil
end

-- ===================================================================== files
function H.readFile(name)
    local r = nil
    pcall(function() r = getFileReader(name, false) end)
    if not r then return nil end
    local t = {}
    pcall(function()
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
    end)
    pcall(function() r:close() end)
    return t
end
function H.writeFile(name, text)
    pcall(function()
        local w = getFileWriter(name, true, false)
        if w then w:write(text or ""); w:close() end
    end)
end
function H.joinLines(t)
    if not t then return nil end
    return table.concat(t, "\n") .. ((#t > 0) and "\n" or "")
end
function H.tourFileBack()
    if not S.tourTouched then return end
    S.tourTouched = nil
    H.writeFile(S.TFILE, H.joinLines(S.was.tour) or "")
end

-- ===================================================================== K1-15: the guide's bubble (rt_hud.lua)
function H.opt(o) local v = nil; pcall(function() v = o:getValue() end); return v end
function H.setOpt(o, v) if o and v then pcall(function() o:setValue(v) end) end end
function H.guideToast()
    local G, M = Z.GuideBubble, Z.Messages
    if not (G and M and M.toasts) then return nil end
    local head = G.head()
    for _, t in ipairs(M.toasts) do if t.source == head then return t end end
    return nil
end
function H.guideStage()
    local G, M = Z.GuideBubble, Z.Messages
    local core = RT.core
    local lines = H.readFile(S.GFILE)
    S.g = { flag = H.joinLines(lines), FIRST = G.FIRST_MS, EVERY = G.EVERY_MS, HOUR = G.HOUR_MS, SHOW = G.SHOW_MS, st = G.st,
            show = core:getOptionShowSurvivalGuide(), toastOpt = H.opt(Z.Settings.messagesToastOption), src = M.sources[G.head()] }
    M.sources[G.head()] = nil
    for i = #M.toasts, 1, -1 do if M.toasts[i].source == G.head() then table.remove(M.toasts, i) end end
    H.setOpt(Z.Settings.messagesToastOption, 1)   -- (ZeD setup's default: Off)
    H.writeFile(S.GFILE, "")
    core:setOptionShowSurvivalGuide(true)
    G.FIRST_MS, G.EVERY_MS, G.HOUR_MS, G.SHOW_MS = 1000, 600000, 3600000, 3000
    G.start()
end
function H.guideBack()
    local g = S.g
    if not g then return end
    S.g = nil
    local G, M = Z.GuideBubble, Z.Messages
    G.FIRST_MS, G.EVERY_MS, G.HOUR_MS, G.SHOW_MS = g.FIRST, g.EVERY, g.HOUR, g.SHOW
    G.st = g.st
    H.writeFile(S.GFILE, g.flag or "")
    pcall(function() RT.core:setOptionShowSurvivalGuide(g.show) end)
    M.sources[G.head()] = g.src
    for i = #M.toasts, 1, -1 do if M.toasts[i].source == G.head() then table.remove(M.toasts, i) end end
    H.setOpt(Z.Settings.messagesToastOption, g.toastOpt or 1)
    S.gBack = { FIRST = g.FIRST, flag = g.flag or "", toastOpt = g.toastOpt or 1 }
end

-- ===================================================================== K1-6: the window menu, the interface
-- the menu pulled down from window w, or nil
function H.menuOn(w)
    local WM = Z.WindowMenu
    local m = WM and WM.current
    if w == nil or m == nil or m._ctx == nil or m._ctx.open ~= true or m.win ~= w then return nil end
    return m
end
-- the words of its top level's rows
function H.rowNames(m)
    local out = {}
    local lv = m and m._levels and m._levels[1]
    for _, r in ipairs((lv and lv.rows) or {}) do
        if type(r) == "table" and type(r.def) == "table" then out[#out + 1] = tostring(r.def.name or "") end
    end
    return out
end
-- the belt (shown and drawn), the watch (shown, and the interface on: it draws nothing while it is off) and the
-- moodles (the layer shown and drawing)
function H.hudState()
    local out = { belt = false, watch = false, moodles = false, ui = ISUIHandler and ISUIHandler.allUIVisible }
    local B = Z.Belt
    local hud = (B and B.getHUD) and B.getHUD(S.pn) or nil
    if hud then pcall(function() out.belt = hud:getIsVisible() and hud._drawn == true end) end
    local W = Z.Watch
    local w = (W and W.getInstance) and W.getInstance() or nil
    if w then pcall(function() out.watch = w:getIsVisible() and out.ui ~= false end) end
    local M = Z.Moodles
    local L = (M and M.getLayer) and M.getLayer(S.pn) or nil
    if L then pcall(function() out.moodles = L:getIsVisible() and L._show == true end) end
    out.belt, out.watch, out.moodles = out.belt == true, out.watch == true, out.moodles == true
    return out
end
function H.hudSays(h)
    return "belt " .. tostring(h.belt) .. ", watch " .. tostring(h.watch) .. ", moodles " .. tostring(h.moodles)
end

-- ===================================================================== K1-14: the tour, the keys, the pad
function H.stepIdx(key)
    local TU = Z.Tutorial
    for i, st in ipairs((TU and TU.STEPS) or {}) do if st.key == key then return i end end
    return nil
end
-- the tour started in mode ("mouse" or "pad"), each step in keys shown by the tour's own Next, its balloon's words
-- read (R.content, what TU.draw hands the balloon), then stopped; all in one frame, so no balloon draws. The tour's
-- stop writes its file: put back after.
function H.tourRead(mode, keys)
    local TU = Z.Tutorial
    local R = TU and TU._state
    local out = {}
    if not (TU and R and TU.start and TU.next and TU.stop and TU.running and TU.step) then return out, "the tour is not loaded" end
    if TU.running() then return out, "a tour is already running" end
    S.tourTouched = true
    local ok, e = pcall(TU.start, S.pn, mode)
    if not ok then return out, "TU.start: " .. tostring(e) end
    for _, k in ipairs(keys) do
        local i = H.stepIdx(k)
        if i and TU.running() then
            R.i = i - 1
            pcall(TU.next)
            local c = R.content
            if TU.running() and TU.step() == i and type(c) == "table" and type(c.lines) == "table" then
                out[k] = tostring(c.lines[1] or "")
            end
        end
    end
    if TU.running() then pcall(TU.stop) end
    return out, nil
end
function H.invCode()
    local c = 0
    pcall(function() c = getCore():getKey("Toggle Inventory") end)
    return c or 0
end
function H.guideKey()
    local G = Z.Guide
    if not (G and G.bubbleKey) then return nil end
    local ok, k = pcall(G.bubbleKey, 0)
    if ok and k then return tostring(k) end
    return nil
end
-- the Controller map's words for a button, as it draws them (CM.ROWS: the roles, then the words' key)
function H.cmapWords(role)
    local CM = Z.ControllerMap
    for _, r in ipairs((CM and CM.ROWS) or {}) do
        if type(r) == "table" and type(r[1]) == "table" and r[1][1] == role and r[2] then return ZeD.tr(r[2]) end
    end
    return ""
end
-- the Character window's list
function H.cc() local w = RT.cw(); return w and w._mainContent or nil end
-- a stop of window w's zone that passes pred (the stops are kept fresh every frame in a QA run: ZEDQA_FRESH_STOPS)
function H.findEl(w, zone, pred)
    for _, z in ipairs((w and w._focusRing) or {}) do
        if z.zone == zone then
            for i, e in ipairs(z.elements or {}) do
                if pred(e) then return e, i, z end
            end
        end
    end
    return nil
end
function H.isMine(e) return type(e) == "table" and e.item ~= nil and e.item == S.padItem and not e.isStackHead end
function H.focusMine()
    local w = RT.cw()
    if not (w and S.Focus and S.Focus.focusWhere) then return nil end
    local e = nil
    pcall(function() e = S.Focus.focusWhere(w, "charMainInv", H.isMine) end)
    return e
end
function H.focused()
    local w = RT.cw()
    local e = nil
    if w and S.Focus and S.Focus.getFocusedElement then pcall(function() e = S.Focus.getFocusedElement(w) end) end
    return e
end
function H.cardOf() local w = RT.cw(); return w and w._drawerItem or nil end
-- NOTE (read only, nothing pressed): where the A that opened the card left the pad. The Controller map's new A line
-- says A again opens the item's menu; A on a row whose card is open is the menu (InventoryRenderer.padItemButtons),
-- but the A that opens a card moves the pad onto its main button (Focus.focusPrimarySoon), so A again runs that.
function H.noteAgain()
    local w = RT.cw()
    if not (w and S.row and S.row.cardAfterA) then return end
    local z = nil
    if S.Focus and S.Focus.getFocusedZone then pcall(function() z = S.Focus.getFocusedZone(w) end) end
    local e = H.focused()
    local n = (type(e) == "table") and tonumber(tostring(e.id or ""):match("^hverb_(%d+)$") or "") or nil
    local card = w._itemCard
    local vs = (type(card) == "table") and card._lastHeaderVerbs or nil
    local v = (n and type(vs) == "table") and vs[n] or nil
    local verb = (type(v) == "table") and v.label or nil
    local onRow = H.isMine(e)
    Q.say("NOTE K1-14, the Controller map's A line (not a check): it says A again opens the item's menu; after A opened the card the pad is on "
        .. tostring(type(z) == "table" and z.zone or nil) .. " (" .. tostring(type(e) == "table" and e.id or nil)
        .. ((type(e) == "table" and e.isPrimary) and ", the card's main button" or "") .. (verb and (" \"" .. tostring(verb) .. "\"") or "")
        .. "), so A again " .. (onRow and "opens the menu (A on a row whose card is open)" or "runs that button, not the menu") .. " (not pressed)")
end
-- the list scrolled so the row is in view (rt_inventory.lua's H.reveal); the scroll as found is kept
function H.reveal(c, item)
    local s = c and c._scroll
    local y = c and c._itemRenderYMap and c._itemRenderYMap[item]
    if not (s and y) then return end
    if S.scrollWas == nil then S.scrollWas, S.scrollOf = s.scrollPos or 0, c end
    if not (s.visible and s.barSizeRatio and s.barSizeRatio > 0 and s.barSizeRatio < 1) then return end
    local vis = s.height
    local range = vis / s.barSizeRatio - vis
    if range <= 0 then return end
    local logical = y - s.y + math.floor(s.scrollPos * range)
    pcall(function() s:setScrollPos(math.max(0, math.min(1, (logical - math.floor(vis / 3)) / range))) end)
end
-- the list's selection kept and put back (a selection of one is an open card)
function H.selKeep()
    S.selTouched = true
    local c = H.cc()
    if not c or S.selWas ~= nil then return end
    local sel = {}
    for k, v in pairs(c._selectedItems or {}) do sel[k] = v end
    S.selWas, S.selOf, S.selLast = sel, c, c._lastClickedItem
end
-- (only once the test has touched it: a list it never touched keeps its own selection)
function H.selBack()
    if not S.selTouched then return end
    local c, w = H.cc(), RT.cw()
    if not (c and w and w._updateDrawer) then return end
    local sel = {}
    if c == S.selOf then for k, v in pairs(S.selWas or {}) do sel[k] = v end end
    c._selectedItems = sel
    c._lastClickedItem = (c == S.selOf) and S.selLast or nil
    c._padMarks = nil
    pcall(w._updateDrawer, c)
end
-- the given thing out of the game wherever it went (rt_inventory.lua's H.removeItem)
function H.removeItem(it)
    if not it then return end
    pcall(function()
        local wo = it:getWorldItem()
        if wo then
            local sq = wo:getSquare()
            if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
        end
    end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
-- ISTimedActionQueue.add caught for the given thing only: what X's move would queue is written down, never queued
-- (nothing moves); every other action passes through
function H.qWrap()
    if S.qWrapped or not ISTimedActionQueue then return end
    S.qOrig = ISTimedActionQueue.add
    S.qFn = function(action, ...)
        if type(action) == "table" and S.padItem ~= nil and action.item == S.padItem then
            S.qRec[#S.qRec + 1] = tostring(action.Type)
            -- (where it was going: the transfer's own destination, read only)
            local d = action.destContainer
            if d ~= nil and S.qDest == nil and instanceof(d, "ItemContainer") then pcall(function() S.qDest = tostring(d:getType()) end) end
            return nil
        end
        return S.qOrig(action, ...)
    end
    ISTimedActionQueue.add = S.qFn
    S.qWrapped, S.qEver = true, true
end
function H.qUnwrap()
    if not S.qWrapped then return true end
    S.qWrapped = false
    if ISTimedActionQueue.add == S.qFn then ISTimedActionQueue.add = S.qOrig; return true end
    return false
end
-- a press of a pad button through the QA hook, queued over a few frames (down, up, let go); getName gives the hook's
-- name or nil (nothing pressed); getW the window that holds the pad (its dispatch takes the press), or nil
function H.queuePress(getName, getW)
    H.step(2, function()
        local n = getName()
        if not n then return end
        RT.pad(n, true)
        local w = getW and getW() or nil
        local bt = ({ A = Joypad.AButton, X = Joypad.XButton, B = Joypad.BButton, Y = Joypad.YButton,
                      LeftBump = Joypad.LBumper, RightBump = Joypad.RBumper })[n]
        if w and bt then RT.padDown(bt, w) end
    end)
    H.step(2, function() local n = getName(); if n then RT.pad(n, false) end end)
    H.step(3, function() local n = getName(); if n then RT.pad(n, nil) end end)
end

-- ===================================================================== K1-11 and K1-9: the car
function H.part(id)
    if not S.v then return nil end
    local p = nil
    pcall(function() p = S.v:getPartById(id) end)
    return p
end
function H.door(part)
    if not part then return nil end
    local d = nil
    pcall(function() d = part:getDoor() end)
    return d
end
function H.hood() return H.part("EngineDoor") end
function H.hoodOpen()
    local d = H.door(H.hood())
    if not d then return false end
    local o = false
    pcall(function() o = d:isOpen() end)
    return o == true
end
function H.inspected()
    local MT = Z.MechanicsTab
    local r = false
    if S.v and MT and MT.isInspected then pcall(function() r = MT.isInspected(S.v) end) end
    return r == true
end
function H.vehTabOpen()
    local ww = H.worldOpen() and RT.ww() or nil
    return ww ~= nil and ww._activeTab == "vehicle"
end
-- a look is done: inspected, the World window on its Vehicle tab, the hood open
function H.looked() return H.inspected() and H.vehTabOpen() and H.hoodOpen() end
function H.lookSays()
    return "inspected " .. tostring(H.inspected()) .. ", Vehicle tab open " .. tostring(H.vehTabOpen()) .. ", hood open "
        .. tostring(H.hoodOpen()) .. ", the queue: " .. H.queueTypes() .. "; U by " .. tostring(S.uHow)
end
-- the tab's current car
function H.curVeh()
    local ww = RT.ww()
    local st = ww and ww._mech
    local e = (st and st.vehicles) and st.vehicles[st.idx or 1] or nil
    return e and e.vehicle or nil
end
function H.onMyCar() return S.v ~= nil and H.vehTabOpen() and H.curVeh() == S.v end
-- the World window on its Vehicle tab, on this car (the car's own sub-tab, as its press does)
function H.toVehTab()
    local ww = H.worldOpen() and RT.ww() or nil
    if not ww then return end
    H.keep(ww)   -- (asked every frame while a wait runs: the roll-up held, the halves were unfolded before it)
    if ww._activeTab ~= "vehicle" then RT.worldTab("vehicle") end
    local st = ww._mech
    local MT = Z.MechanicsTab
    if st and st.vehicles and MT and MT.vehicleTabFn and H.curVeh() ~= S.v then
        for i, e in ipairs(st.vehicles) do
            if e.vehicle == S.v then pcall(MT.vehicleTabFn(st, i)); break end
        end
    end
end
-- the key line as the tab draws it: ZeD.Molecules.drawStatRowDot passed through, the value beside the label Key kept
function H.keyWrap()
    local M = Z.Molecules
    if S.kWrapped or not (M and M.drawStatRowDot) then return end
    S.kOrig = M.drawStatRowDot
    S.keyLabel = getText("IGUI_ItemType_Key")
    S.kFn = function(panel, x, y, w, label, value, ...)
        if label == S.keyLabel then
            S.kN = S.kN + 1
            S.kRec = { n = S.kN, v = H.curVeh(), value = tostring(value) }
        end
        return S.kOrig(panel, x, y, w, label, value, ...)
    end
    M.drawStatRowDot = S.kFn
    S.kWrapped, S.kEver = true, true
end
function H.keyUnwrap()
    if not S.kWrapped then return true end
    S.kWrapped = false
    local M = Z.Molecules
    if M and M.drawStatRowDot == S.kFn then M.drawStatRowDot = S.kOrig; return true end
    return false
end
-- the line drawn for this car since the last change (S.kMark), or nil
function H.keyRead()
    local r = S.kRec
    if r and r.n > S.kMark and r.v ~= nil and r.v == S.v then return r.value end
    return nil
end
-- the game's easy use for one reading (nil: as found)
function H.easy(on)
    if not SandboxVars then return end
    if on == nil then SandboxVars.VehicleEasyUse = S.was.easy else SandboxVars.VehicleEasyUse = on end
end
function H.ignWords()
    local w = getText("Tooltip_Dashboard_KeysIgnition")
    return (string.gsub(tostring(w), "%.$", ""))
end
-- him moved by his own setters (X, Y, Z and their last values, as zedqa_prelude.lua moves him)
function H.tp(x, y, z)
    pcall(function()
        S.p:setX(x); S.p:setY(y); S.p:setZ(z)
        S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z)
    end)
end
-- a free square two beside the car (the car faces north: its sides are west and east), as a tile centre
function H.besideCar()
    local cx, cy, cz = nil, nil, nil
    pcall(function() cx, cy, cz = math.floor(S.v:getX()), math.floor(S.v:getY()), math.floor(S.v:getZ()) end)
    if not cx then return nil end
    for _, o in ipairs({ { -2, 0 }, { 2, 0 }, { -2, 1 }, { 2, 1 }, { -2, -1 }, { 2, -1 } }) do
        local sq = getCell():getGridSquare(cx + o[1], cy + o[2], cz)
        local free = false
        if sq then pcall(function() free = sq:isFree(false) and not sq:HasTree() and sq:getVehicleContainer() == nil end) end
        if free then return cx + o[1] + 0.5, cy + o[2] + 0.5, cz end
    end
    return nil
end
function H.exitCar()
    local v = nil
    pcall(function() v = S.p:getVehicle() end)
    if not v then return end
    pcall(function() v:exit(S.p) end)
    pcall(function() triggerEvent("OnExitVehicle", S.p) end)
end
function H.queueTypes()
    local out = {}
    local q = ISTimedActionQueue and ISTimedActionQueue.queues and ISTimedActionQueue.queues[S.p]
    for _, a in ipairs((q and q.queue) or {}) do out[#out + 1] = tostring(a.Type) end
    return (#out > 0) and table.concat(out, " ") or "empty"
end
function H.queueEmpty()
    local q = ISTimedActionQueue and ISTimedActionQueue.queues and ISTimedActionQueue.queues[S.p]
    local busy = false
    pcall(function() busy = not S.p:getCharacterActions():isEmpty() end)
    return not busy and #((q and q.queue) or {}) == 0
end
function H.hasLook()
    local r = false
    pcall(function() r = ISTimedActionQueue.hasActionType(S.p, "ISOpenMechanicsUIAction") end)
    return r == true
end
function H.stopActions() pcall(function() ISTimedActionQueue.clear(S.p) end) end
-- U: the mechanics key through the game's own key handler when the game picks this car, else the handler's call
function H.pressU()
    local code = 0
    pcall(function() code = getCore():getKey(KeybindId.VEHICLE_MECHANICS) end)
    local pick = nil
    pcall(function() pick = ISVehicleMenu.getVehicleToInteractWith(S.p) end)
    local seated = nil
    pcall(function() seated = S.p:getVehicle() end)
    if code and code ~= 0 and pick ~= nil and pick == S.v and seated == nil then
        local ok, e = pcall(ISVehicleMenu.onKeyPressed, code)
        S.uHow = "the mechanics key " .. H.keyName(code) .. " through ISVehicleMenu.onKeyPressed"
        if not ok then Q.say("ERR the mechanics key: " .. tostring(e)) end
        return
    end
    local ok, e = pcall(ISVehicleMenu.onMechanic, S.p, S.v)
    S.uHow = "ISVehicleMenu.onMechanic on the car (the key's code " .. tostring(code) .. "; the game picks "
        .. ((pick == nil) and "no car" or ((pick == S.v) and "this car" or "another car")) .. ")"
    if not ok then Q.say("ERR the mechanics key's handler: " .. tostring(e)) end
end
-- E: the game's use event when the hood is the part it offers him, else the hood's own use function
function H.pressE()
    local hood = H.hood()
    if not hood then S.eHow = "no hood"; return end
    local part = nil
    pcall(function() part = S.v:getUseablePart(S.p) end)
    if part ~= nil and part == hood then
        local ok, e = pcall(VehicleUtils.OnUseVehicle, S.p, S.v)
        S.eHow = "the game's use event at the hood (VehicleUtils.OnUseVehicle)"
        if not ok then Q.say("ERR E at the hood: " .. tostring(e)) end
        return
    end
    local fn = nil
    pcall(function() fn = hood:getLuaFunction("use") end)
    local pid = nil
    if part ~= nil then pcall(function() pid = part:getId() end) end
    if fn and fn ~= "" then
        local ok, e = pcall(VehicleUtils.callLua, fn, S.v, hood, S.p)
        S.eHow = "the hood's own use function " .. tostring(fn) .. " (the part the game offers him: " .. tostring(pid) .. ")"
        if not ok then Q.say("ERR the hood's use: " .. tostring(e)) end
    else
        S.eHow = "the hood has no use function"
    end
end

-- ===================================================================== his stats and his health (bx_vehicles.lua)
function H.statsKeep()
    S.stats = {}
    pcall(function()
        local st = S.p:getStats()
        for _, k in ipairs(H.STATS) do
            if CharacterStat[k] then S.stats[k] = st:get(CharacterStat[k]) end
        end
    end)
end
function H.statsBack()
    pcall(function()
        local st = S.p:getStats()
        for k, v in pairs(S.stats or {}) do st:set(CharacterStat[k], v) end
    end)
end
-- his health and infection at the start (the put-back judges against them: another script's wound is not this one's)
function H.healthKeep()
    pcall(function()
        local bd = S.p:getBodyDamage()
        S.was.health, S.was.infected = bd:getOverallBodyHealth(), bd:IsInfected()
    end)
end
-- what is wrong with him now, in words; an empty list is alive and well
function H.hurt()
    local bad = {}
    local okR = pcall(function()
        if S.p:isDead() then bad[#bad + 1] = "dead" end
        local bd = S.p:getBodyDamage()
        local hp, was = bd:getOverallBodyHealth(), S.was.health or 100
        if hp < math.min(99.5, was - 0.5) then bad[#bad + 1] = "health " .. H.num(hp) .. " (found " .. H.num(was) .. ")" end
        if bd:IsInfected() and S.was.infected ~= true then bad[#bad + 1] = "infected" end
    end)
    if not okR then bad[#bad + 1] = "the body could not be read" end
    return bad
end

-- ===================================================================== start: what is found
Q.step(5, function()
    local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
    local ready = CW ~= nil and WW ~= nil and CW.isOpen ~= nil and CW.toggleBothPaired ~= nil and CW._onKeyPressed ~= nil
        and WW.isOpen ~= nil and WW.getWindow ~= nil and WW.open ~= nil and WW.close ~= nil
        and Z.GuideBubble ~= nil and Z.GuideBubble.start ~= nil and Z.Messages ~= nil and Z.Messages.toasts ~= nil
        and Z.Settings ~= nil and Z.Settings.messagesToastOption ~= nil and Z.WindowMenu ~= nil and Z.Tutorial ~= nil
        and Z.Tutorial._state ~= nil and Z.DpadWheels ~= nil and Z.DpadWheels.state ~= nil and Z.DpadWheels.enter ~= nil
        and Z.MechanicsTab ~= nil and Z.MechanicsTab.isInspected ~= nil and Z.Molecules ~= nil and Z.Molecules.drawStatRowDot ~= nil
        and Z.ControllerMap ~= nil and Z.ControllerMap.ROWS ~= nil and Z.Guide ~= nil and Z.Guide.bubbleKey ~= nil
        and S.Det ~= nil and S.Det.setLockedMode ~= nil and S.Det.getMode ~= nil and S.Focus ~= nil and S.Focus.qaButton ~= nil
        and S.Focus.focusWhere ~= nil and S.Focus.claimFocus ~= nil and ISDPadWheels ~= nil and ISVehicleMenu ~= nil
        and VehicleUtils ~= nil and ISTimedActionQueue ~= nil and ISUIHandler ~= nil and S.p ~= nil
    if not H.must(ready, "ZeD's windows, menus, tour, guide, wheels and Vehicle tab and the game's vehicle code are loaded") then
        S.dead = true
        return
    end
    if not H.must(not S.p:isDead(), "the character is alive at the start") then S.dead = true; return end
    local char, world = H.charOpen(), H.worldOpen()
    local cw, ww = RT.cw(), RT.ww()
    S.was.geo = { c = char and H.geo(cw) or nil, w = world and H.geo(ww) or nil }
    S.was.tab = { c = (char and cw) and cw._activeTab or nil, w = (world and ww) and ww._activeTab or nil }
    S.was.cwObj, S.was.wwObj = char and cw or nil, world and ww or nil
    S.was.outC, S.was.outW = cw and cw._outSince or nil, ww and ww._outSince or nil
    local md = S.p:getModData()
    S.was.ws = { taken = md ~= nil, had = md ~= nil and md.ZeD_WinState ~= nil, v = md and H.copy(md.ZeD_WinState) or nil }
    S.was.mode = H.mode()
    S.lockWas = H.lockFound()
    S.was.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
    S.was.speed = getGameSpeed and getGameSpeed() or 1
    S.was.easy = SandboxVars and SandboxVars.VehicleEasyUse
    S.was.ui = ISUIHandler.allUIVisible
    S.was.tour = H.readFile(S.TFILE)
    S.was.tourOn = Z.Tutorial.running and Z.Tutorial.running() or false
    if S.was.tourOn then S.off.tour = true end
    H.statsKeep()
    H.healthKeep()
    S.was.char, S.was.world = char, world
    Q.say("start: screen " .. RT.core:getScreenWidth() .. "x" .. RT.core:getScreenHeight() .. ", ZeD's scale " .. tostring(Z.T and Z.T.scale)
        .. "; Character window open " .. tostring(char) .. " (" .. H.gs(S.was.geo.c) .. ", on " .. tostring(S.was.tab.c) .. "), World window open "
        .. tostring(world) .. " (" .. H.gs(S.was.geo.w) .. ", on " .. tostring(S.was.tab.w) .. "); Input lock " .. tostring(S.lockWas)
        .. ", ZeD reads " .. tostring(S.was.mode) .. "; game speed " .. tostring(S.was.speed) .. "; easy use " .. tostring(S.was.easy)
        .. "; the interface on " .. tostring(S.was.ui) .. "; a tour running " .. tostring(S.was.tourOn) .. "; he stands at "
        .. H.num(S.was.pos.x) .. "," .. H.num(S.was.pos.y) .. "," .. H.num(S.was.pos.z))
    if S.was.speed == 0 then pcall(setGameSpeed, 1) end
    -- (the pair shut once, so the layout each open window keeps is the one found: the put-back opens them on it)
    if char or world then H.shutPair() end
end)

-- ===================================================================== K1-15: the guide's bubble on default settings
H.step(5, function()
    local ok, e = pcall(H.guideStage)
    local G = Z.GuideBubble
    if not H.must(ok and G.st ~= nil, "K1-15 staging: a machine that never had the bubble, ZeD setup's Messages balloons at their default (Off), the game's Show the guide on startup on",
        "the bubble's clock armed " .. tostring(G.st ~= nil) .. (ok and "" or ("; " .. tostring(e)))) then
        S.off.guide = true
    end
end)
H.wait(6000, function() return S.off.guide or H.guideToast() ~= nil end, function()
    if S.off.guide then H.guideBack(); return end
    local G = Z.GuideBubble
    local t = H.guideToast()
    local st = G.st or {}
    Q.check(t ~= nil and t.text == G.text(0), "K1-15: on default settings (Messages balloons Off) the guide's bubble comes out the first time, with the guide's words",
        "bubble " .. tostring(t ~= nil) .. (t and (" \"" .. tostring(t.text) .. "\"") or "") .. "; the balloons setting "
        .. tostring(H.opt(Z.Settings.messagesToastOption)) .. " (1 = Off, the default); the offer: shown " .. tostring(st.shows)
        .. " time(s), ended " .. tostring(st.done) .. " (" .. tostring(st.why) .. ")")
    H.guideBack()
end)

-- ===================================================================== K1-6: the window menus, then the way back (a NOTE)
H.step(5, function() H.openBoth() end)
H.wait(4000, function() return H.charOpen() and H.worldOpen() end, function(ok)
    if not H.must(ok, "K1-6 staging: both windows open") then S.off.menu = true; return end
    H.holdBoth()
end)
for _, k in ipairs({ "c", "w" }) do
    local function win()
        if k == "c" then return RT.cw() end
        return RT.ww()
    end
    local name = (k == "c") and "Character" or "World"
    H.step(6, function()
        if S.off.menu then return end
        H.closeWinMenu()
        local w = win()
        if w then w._boxDo = "menu" end   -- (what a press and release on the window box asks update() for)
    end)
    H.wait(3000, function() return S.off.menu or H.menuOn(win()) ~= nil end, function(ok)
        if S.off.menu then return end
        local m = H.menuOn(win())
        if not H.must(ok and m ~= nil, "K1-6 staging: the " .. name .. " window's box pulls its menu down") then S.menus[k] = false; return end
        S.menus[k] = H.rowNames(m)
        H.closeWinMenu()
    end)
end
H.step(3, function()
    if S.off.menu then return end
    local hide = ZeD.tr("UI_ZeD_Wheel_HideInterface")
    local bad, said, seen = {}, {}, 0
    for _, k in ipairs({ "c", "w" }) do
        local names = S.menus[k]
        if type(names) == "table" then
            seen = seen + 1
            said[#said + 1] = ((k == "c") and "Character: " or "World: ") .. table.concat(names, ", ")
            if H.has(names, hide) then bad[#bad + 1] = (k == "c") and "Character" or "World" end
        end
    end
    if seen == 0 then return end   -- (no menu came down: a FAIL above)
    Q.check(#bad == 0, "K1-6: no window's menu offers \"" .. hide .. "\" to the mouse (it had no way back from it)",
        ((#bad > 0) and ("offered on the " .. table.concat(bad, " and ") .. " window; ") or "") .. table.concat(said, " | "))
end)
-- the way back, read (not a check): hidden as the old row hid it, then Escape's and Resume's calls
H.step(5, function()
    if S.off.menu then return end
    S.hud0 = H.hudState()
    local WH = Z.DpadWheels and Z.DpadWheels.H
    if not (WH and WH.hideInterface and ISUIHandler.toggleUI and ISUIHandler.setVisibleAllUI and ISUIHandler.allUIVisible ~= false) then return end
    S.s1 = true
    pcall(WH.hideInterface)   -- (ISUIHandler.toggleUI, what the old row fired)
end)
H.step(10, function() if S.s1 then pcall(ISUIHandler.setVisibleAllUI, false) end end)   -- (Escape: ToggleEscapeMenu's call)
H.step(5, function() if S.s1 then pcall(ISUIHandler.setVisibleAllUI, true) end end)    -- (Resume: the same call, the pause screen up)
Q.waitMs(700)
H.step(1, function()
    if not S.s1 then return end
    local h = H.hudState()
    Q.say("NOTE K1-6, the way back (not a check): after Hide the interface, Escape and Resume the windows are back "
        .. tostring(H.pairVisible()) .. "; " .. H.hudSays(h) .. "; ISUIHandler.allUIVisible " .. tostring(ISUIHandler.allUIVisible)
        .. " (before the hide: " .. H.hudSays(S.hud0) .. ")")
    if ISUIHandler.allUIVisible == false then pcall(ISUIHandler.toggleUI) end
end)
H.wait(3000, function()
    if not S.s1 then return true end
    local h = H.hudState()
    return h.ui ~= false and h.belt == S.hud0.belt and h.watch == S.hud0.watch and h.moodles == S.hud0.moodles and H.pairVisible()
end, function(ok)
    if not S.s1 then return end
    S.s1 = nil
    H.must(ok and ISUIHandler.allUIVisible ~= false, "put back: the interface shown again (Toggle UI), the windows, the belt, the watch and the moodles as before",
        H.hudSays(H.hudState()) .. ", windows " .. tostring(H.pairVisible()))
    H.holdBoth()
end)

-- ===================================================================== K1-14: the tour's words, mouse and pad
H.step(3, function()
    if S.off.tour then
        H.must(false, "K1-14 staging: no tour running when the test starts", "a tour was found running: the tour's checks are not run")
        return
    end
    H.selKeep()
    local words, why = H.tourRead("mouse", { "Char", "World", "Guide" })
    S.tourM = words
    if not H.must(words.Char ~= nil and words.World ~= nil and words.Guide ~= nil, "K1-14 staging: the tour with the mouse shows its Character, World and Guide steps",
        "Character " .. tostring(words.Char ~= nil) .. ", World " .. tostring(words.World ~= nil) .. ", Guide " .. tostring(words.Guide ~= nil)
        .. (why and ("; " .. why) or "")) then
        S.off.tourM = true
    end
end)
H.step(3, function()
    if S.off.tour then return end
    local words, why = H.tourRead("pad", { "Char", "World", "Card" })
    S.tourP = words
    H.tourFileBack()
    H.selBack()   -- (the Card step opened a card: the selection as found)
    if not H.must(words.Char ~= nil and words.World ~= nil and words.Card ~= nil, "K1-14 staging: the tour on a controller shows its Character, World and Card steps",
        "Character " .. tostring(words.Char ~= nil) .. ", World " .. tostring(words.World ~= nil) .. ", Card " .. tostring(words.Card ~= nil)
        .. (why and ("; " .. why) or "")) then
        S.off.tourP = true
    end
    Q.say("tour words: mouse Character \"" .. tostring(S.tourM.Char) .. "\" | World \"" .. tostring(S.tourM.World) .. "\" | Guide \""
        .. tostring(S.tourM.Guide) .. "\"; pad Character \"" .. tostring(words.Char) .. "\" | World \"" .. tostring(words.World)
        .. "\" | Card \"" .. tostring(words.Card) .. "\"")
end)

-- 14a: the inventory key, pressed with both windows shut
H.step(3, function() if not (S.off.tour or S.off.tourM) then H.shutPair() end end)
H.wait(3000, function() return S.off.tour or S.off.tourM or (not H.charOpen() and not H.worldOpen()) end, function(ok)
    if S.off.tour or S.off.tourM then return end
    if not H.must(ok, "K1-14 staging: both windows shut before the inventory key") then S.off.tourM = true; return end
    S.invCode = H.invCode()
    local okP, e = pcall(ZeD_CharacterWindow._onKeyPressed, S.invCode)
    if not okP then Q.say("ERR the inventory key's handler: " .. tostring(e)) end
end)
H.wait(3000, function() return S.off.tour or S.off.tourM or (H.charOpen() and H.worldOpen()) end, function(ok)
    if S.off.tour or S.off.tourM then return end
    local inv = H.keyName(S.invCode)
    local gk = H.guideKey()
    local parts, good = {}, ok
    for _, k in ipairs({ "Char", "World" }) do
        local t = S.tourM[k] or ""
        local named = t:match("(%S+) opens")
        local after = H.trim(t:match("opens ([^%.]*)") or "")
        local both = H.lower(after):find("both", 1, true) ~= nil
        if not (named ~= nil and named == inv and both) then good = false end
        parts[#parts + 1] = ((k == "Char") and "Character" or "World") .. " step names \"" .. tostring(named) .. "\", which opens \"" .. after .. "\""
    end
    local g = S.tourM.Guide or ""
    local gOk = gk ~= nil and gk ~= "" and g:find(gk, 1, true) ~= nil
    if not gOk then good = false end
    Q.check(good, "K1-14: the mouse tour's Character, World and Guide steps name the player's own keys, and the inventory key does what they say",
        table.concat(parts, "; ") .. "; the Toggle Inventory key is " .. inv .. ", pressed with both windows shut: both open " .. tostring(ok)
        .. "; the Guide step names the guide's key " .. tostring(gk) .. ": " .. tostring(gOk))
    H.holdBoth()
end)

-- 14b: the controller's button for the windows, pressed with both shut (the input mode locked to the controller)
H.step(3, function()
    H.lock("gamepad")
    H.toWheel()
end)
-- (again: the switch to the controller opens the pair, and can hand it the pad, a frame after the lock)
H.step(10, function() H.toWheel() end)
Q.waitMs(400)
for _, k in ipairs({ "Char", "World" }) do
    H.step(3, function()
        S.padCur = nil
        if S.off.tour or S.off.tourP then return end
        local named = (S.tourP[k] or ""):match("(%S+) opens")
        for _, j in ipairs({ "Char", "World" }) do
            if j ~= k and S.padRes[j] and S.padRes[j].named == named then S.padRes[k] = S.padRes[j]; return end
        end
        S.padCur = { k = k, named = named, hook = named and H.HOOK[named] or nil }
        H.toWheel()
    end)
    H.wait(3000, function() return S.padCur == nil or (not H.charOpen() and not H.worldOpen()) end, function(ok)
        if not S.padCur then return end
        if not H.must(ok, "K1-14 staging: both windows shut and the pad let go before the " .. tostring(S.padCur.named) .. " press") then S.padCur.hook = nil end
    end)
    H.queuePress(function() return S.padCur and S.padCur.hook or nil end, nil)
    H.wait(2000, function() return S.padCur == nil or S.padCur.hook == nil or (H.charOpen() and H.worldOpen()) end, function(ok)
        if not S.padCur then return end
        S.padRes[k] = { named = S.padCur.named, pressed = S.padCur.hook ~= nil, opened = ok and S.padCur.hook ~= nil }
        S.padCur = nil
    end)
end
-- the bumpers the steps say step the tabs ("Y opens both windows, and LB and RB step the tabs"): each tapped with the
-- pair open and the pad on the Character window, where the Y above left it; the old words make no such claim
H.step(2, function()
    S.bumpWant, S.bumpRes = {}, {}
    if S.off.tour or S.off.tourP then return end
    for _, k in ipairs({ "Char", "World" }) do
        local who = (S.tourP[k] or ""):match("([%w ]-) step the tabs")
        for b in tostring(who or ""):gmatch("%a+") do
            if H.BUMP[b] and not H.has(S.bumpWant, b) then S.bumpWant[#S.bumpWant + 1] = b end
        end
    end
end)
for j = 1, 2 do
    H.step(3, function()
        S.bumpCur = nil
        local b = S.bumpWant and S.bumpWant[j]
        if not b then return end
        S.bumpCur = { name = b, hook = H.BUMP[b].hook, side = H.BUMP[b].side }
        if not (H.charOpen() and H.worldOpen()) then H.openBoth() end
    end)
    H.wait(3000, function() return S.bumpCur == nil or (H.charOpen() and H.worldOpen()) end, function(ok)
        local c = S.bumpCur
        if not c then return end
        local cw = RT.cw()
        local w = (c.side == "c") and cw or RT.ww()
        if not (ok and cw and w) then c.hook, c.why = nil, "the pair was not open"; return end
        H.holdBoth()
        pcall(S.Focus.claimFocus, cw)
        c.before = w._activeTab
    end)
    H.queuePress(function() return S.bumpCur and S.bumpCur.hook or nil end, function() return RT.cw() end)
    H.wait(2000, function()
        local c = S.bumpCur
        if not (c and c.hook) then return true end
        H.keep(RT.cw()); H.keep(RT.ww())
        local w = (c.side == "c") and RT.cw() or RT.ww()
        return w ~= nil and w._activeTab ~= c.before
    end, function(ok)
        local c = S.bumpCur
        if not c then return end
        local w = (c.side == "c") and RT.cw() or RT.ww()
        S.bumpRes[c.name] = { pressed = c.hook ~= nil, stepped = ok and c.hook ~= nil, before = c.before, after = w and w._activeTab, why = c.why }
        S.bumpCur = nil
    end)
end
H.step(3, function()
    if S.off.tour or S.off.tourP then return end
    local parts, good = {}, true
    for _, k in ipairs({ "Char", "World" }) do
        local r = S.padRes[k] or {}
        if not (r.pressed and r.opened) then good = false end
        parts[#parts + 1] = ((k == "Char") and "Character" or "World") .. " step names \"" .. tostring(r.named) .. "\" for the windows: pressed " .. tostring(r.pressed)
            .. ", both windows open after it " .. tostring(r.opened)
    end
    for _, b in ipairs(S.bumpWant or {}) do
        local r = S.bumpRes[b] or {}
        if not r.stepped then good = false end
        parts[#parts + 1] = b .. " (the steps say it steps the tabs) tapped " .. tostring(r.pressed) .. ": the "
            .. ((H.BUMP[b].side == "c") and "Character" or "World") .. " window's tab " .. tostring(r.before) .. " -> " .. tostring(r.after)
            .. (r.why and (" (" .. tostring(r.why) .. ")") or "")
    end
    if #(S.bumpWant or {}) == 0 then parts[#parts + 1] = "no bumper named for the tabs" end
    Q.check(good, "K1-14: every button the controller tour's Character and World steps name does what they say (the windows' button opens both; a bumper said to step the tabs steps them)",
        table.concat(parts, "; "))
end)

-- 14d: the guide bubble's controller words, against the wheel they name
H.step(3, function() H.toWheel() end)
H.wait(3000, function() return not H.charOpen() and not H.worldOpen() end, function(ok)
    local words = ZeD.tr("UI_ZeD_Guide_BubblePad")
    local dir, slice = words:match("^D%-pad (%a+), then (.+)$")
    S.bub = { words = words, dir = dir and H.lower(dir) or nil, slice = slice and H.trim(slice) or nil }
    if not H.must(ok, "K1-14 staging: both windows shut and the pad let go before the D-pad wheel") then S.bub.off = true; return end
    local fn = S.bub.dir and H.DIRFN[S.bub.dir] or nil
    if not (fn and S.bub.slice) then return end
    S.bub.opened, S.bub.how = H.openWheel(S.bub.dir, fn)
end)
H.wait(2000, function()
    if S.bub.off or not S.bub.opened then return true end
    local st = H.wheelSt()
    return st ~= nil and st.menu ~= nil and H.vis(st.menu)
end, function()
    if S.bub.off or not S.bub.opened then return end
    local st = H.wheelSt()
    local m = st and st.menu
    S.bub.names = H.sliceNames(m)
    local i = H.sliceIdx(m, S.bub.slice)
    S.bub.found = i ~= nil
    if not i then return end
    local sl = m.slices[i]
    local cmd = sl and sl.command
    if type(cmd) == "table" and cmd[1] ~= nil and cmd[1] == Z.DpadWheels.enter then
        -- (the slice's own command: what the wheel runs when the slice is taken)
        pcall(cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7])
        S.bub.entered = true
    elseif H.firstLine(sl and sl.text) == ZeD.tr("UI_ZeD_Wheel_GuideShowHide") then
        S.bub.isGuide = true
    end
end)
H.step(5, function()
    if S.bub.off then return end
    local st = H.wheelSt()
    local m = st and st.menu
    if S.bub.entered then S.bub.sub = H.sliceNames(m) end
    local guide = ZeD.tr("UI_ZeD_Wheel_GuideShowHide")
    local leads = S.bub.isGuide == true or H.has(S.bub.sub, guide)
    Q.check(S.bub.found == true and leads, "K1-14: the guide bubble's controller words name a D-pad wheel and a slice that lead to the survival guide",
        "the words \"" .. tostring(S.bub.words) .. "\": the " .. tostring(S.bub.dir) .. " wheel opened " .. tostring(S.bub.opened) .. " by "
        .. tostring(S.bub.how) .. ", its slices: " .. H.list(S.bub.names) .. "; \"" .. tostring(S.bub.slice) .. "\" there " .. tostring(S.bub.found)
        .. "; it opens: " .. H.list(S.bub.sub) .. " (the guide's slice \"" .. guide .. "\": " .. tostring(leads) .. ")")
    H.closeWheel()
end)

-- 14c, 14e: a thing's row on the controller (the Character window holding the pad)
H.step(5, function()
    H.closeWheel()
    H.openBoth()
end)
H.wait(4000, function() return H.charOpen() and H.worldOpen() end, function(ok)
    if not H.must(ok, "K1-14 staging: both windows open for the row on the controller") then S.off.row = true; return end
    H.holdBoth()
    RT.charTab("loot")
    RT.worldTab("loot")
end)
H.wait(3000, function()
    if S.off.row then return true end
    local c, w = RT.cw(), RT.ww()
    H.keep(c); H.keep(w)
    return c ~= nil and w ~= nil and c._activeTab == "loot" and w._activeTab == "loot"
end, function(ok)
    if S.off.row then return end
    if not H.must(ok, "K1-14 staging: both windows on their lists (Loot)") then S.off.row = true; return end
    -- a kitchen tool he does not carry, so its row is its own
    local have = {}
    pcall(function()
        local items = S.p:getInventory():getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if it then have[it:getFullType()] = true end
        end
    end)
    for _, ft in ipairs(H.TOOLS) do
        if not S.padItem and not have[ft] then S.padItem = RT.give(ft) end
    end
    if not H.must(S.padItem ~= nil, "K1-14 staging: a kitchen tool given for the row") then S.off.row = true end
end)
H.wait(3000, function() return S.off.row or H.findEl(RT.cw(), "charMainInv", H.isMine) ~= nil end, function(ok)
    if S.off.row then return end
    if not H.must(ok, "K1-14 staging: the tool's row is in the Character window's list",
        tostring(S.padItem and S.padItem:getFullType())) then S.off.row = true; return end
    H.holdBoth()
    local w, c = RT.cw(), H.cc()
    if not H.must(w ~= nil and c ~= nil, "K1-14 staging: the Character window and its list to step on",
        "window " .. tostring(w ~= nil) .. ", list " .. tostring(c ~= nil)) then S.off.row = true; return end
    -- no card open, the Character window holding the pad, the row in view
    if H.cardOf() ~= nil then
        c._selectedItems = {}
        c._lastClickedItem = nil
        pcall(w._updateDrawer, c)
    end
    pcall(S.Focus.claimFocus, w)
    H.reveal(c, S.padItem)
    -- the row beside it, to step onto it from
    local e, i, z = H.findEl(w, "charMainInv", H.isMine)
    local els = (z and z.elements) or {}
    local nb, dir = els[(i or 0) + 1], "up"
    if not (type(nb) == "table" and nb.item ~= nil and not nb.isStackHead) then nb, dir = els[(i or 0) - 1], "down" end
    S.row = { dir = nil }
    if type(nb) == "table" and nb.item ~= nil and not nb.isStackHead then
        local nbItem = nb.item
        local okF = nil
        pcall(function() okF = S.Focus.focusWhere(w, "charMainInv", function(x) return x.item == nbItem and not x.isStackHead end) end)
        if okF then S.row.dir = dir end
    end
end)
H.step(3, function()
    if S.off.row then return end
    if S.row.dir then RT.padDir(S.row.dir, RT.cw()) end
end)
H.step(3, function()
    if S.off.row then return end
    local e = H.focused()
    S.row.landed = H.isMine(e)
    S.row.how = S.row.dir and ("a D-pad step " .. S.row.dir .. " from the row beside it") or "no row beside it"
    if not S.row.landed then
        -- (no step landed on it: the focus put on it as a landing does, firing its onFocus)
        H.focusMine()
        S.row.how = S.row.how .. "; it landed elsewhere, so the focus was put on the row as a landing does"
        S.row.landed = H.isMine(H.focused())
    end
    S.row.cardAfterMove = H.cardOf() == S.padItem
    if not H.must(S.row.landed, "K1-14 staging: the controller's focus on the tool's row", S.row.how) then S.off.row = true end
end)
-- A tapped on the row
H.queuePress(function() return (not S.off.row) and "A" or nil end, function() return RT.cw() end)
H.wait(2000, function() return S.off.row or H.cardOf() == S.padItem end, function(ok)
    if S.off.row then return end
    S.row.cardAfterA = ok
    if S.off.tour or S.off.tourP then return end
    local t = S.tourP.Card or ""
    local claim = "?"
    if t:find("D-pad", 1, true) then claim = "a D-pad step"
    elseif t:find("Press A", 1, true) or t:find(" A on ", 1, true) then claim = "A" end
    local good = (claim == "A" and S.row.cardAfterA) or (claim == "a D-pad step" and S.row.cardAfterMove)
    Q.check(good == true, "K1-14: the controller tour's Card step names the control that opens an item's card",
        "the step says \"" .. t .. "\" (names " .. claim .. "); with no card open, " .. tostring(S.row.how) .. ": a card opened "
        .. tostring(S.row.cardAfterMove) .. "; A tapped on the row: its card opened " .. tostring(S.row.cardAfterA))
end)
-- X tapped on the row (the move caught before it is queued)
H.wait(2000, function()
    if S.off.row then return true end
    local w = RT.cw()
    return w ~= nil and not (S.Focus.soonPending and S.Focus.soonPending(w))
end, function()
    if S.off.row then return end
    H.noteAgain()   -- (where the A left the pad: read before the focus goes back to the row)
    H.focusMine()
    local CT = Z.ContainerControls
    local cc = H.cc()
    S.row.dest = (CT and CT.otherInventory and cc) and CT.otherInventory(cc) or nil
    if not H.must(H.isMine(H.focused()) and S.row.dest ~= nil, "K1-14 staging: the focus back on the tool's row, the World window's container across",
        "on the row " .. tostring(H.isMine(H.focused())) .. ", a container across " .. tostring(S.row.dest ~= nil)) then
        S.off.row = true
        return
    end
    S.qRec, S.qDest = {}, nil
    S.row.menuBefore = H.menuUp()
    H.qWrap()
end)
H.queuePress(function() return (not S.off.row) and "X" or nil end, function() return RT.cw() end)
H.wait(1500, function() return S.off.row or #S.qRec > 0 or H.menuUp() end, function()
    if S.off.row then return end
    S.row.moved = #S.qRec > 0
    S.row.menu = H.menuUp() and not S.row.menuBefore
    S.row.qBack = H.qUnwrap()
    H.closeMenu()
    local mapX = H.cmapWords("X")
    local gch = ZeD.tr("UI_ZeD_GCh_zed_pad_Text")
    local xSeg = gch:match("{pad:X}(.-){pad:") or gch:match("{pad:X}(.*)$") or ""
    local w1p = ZeD.tr("UI_ZeD_GCh_zed_moving_W1P")
    local w1pBtn = w1p:match("{pad:(%a+)}")
    local good = S.row.moved and not S.row.menu and H.claim(mapX) == "move" and H.claim(xSeg) == "move" and w1pBtn == "X"
    Q.check(good == true, "K1-14: X moves the thing it is on, as the Controller map, the guide's controller chapter and its Moving page say",
        "X tapped on the row: a move queued " .. tostring(S.row.moved) .. " (" .. H.list(S.qRec) .. " to " .. tostring(S.qDest)
        .. ", queued at once with no picking step, caught, nothing moved), a menu opened "
        .. tostring(S.row.menu) .. "; the map's X line \"" .. mapX .. "\" says " .. H.claim(mapX) .. "; the chapter's X words \""
        .. H.trim(xSeg) .. "\" say " .. H.claim(xSeg) .. "; the Moving page's controller line \"" .. w1p .. "\" names " .. tostring(w1pBtn))
end)
-- 14f: the mouse's words on the controller's lines
H.step(2, function()
    local lines = { { "the map's A line", H.cmapWords("A") }, { "the map's X line", H.cmapWords("X") }, { "the map's B line", H.cmapWords("B") },
                    { "the guide's controller chapter", ZeD.tr("UI_ZeD_GCh_zed_pad_Text") } }
    local bad = {}
    for _, l in ipairs(lines) do
        local mw = H.mouseWords(l[2])
        if #mw > 0 then bad[#bad + 1] = l[1] .. " (" .. table.concat(mw, ", ") .. ")" end
    end
    Q.check(#bad == 0, "K1-14: the Controller map's A, X and B lines and the guide's controller chapter name no mouse button",
        (#bad > 0) and ("mouse words in " .. table.concat(bad, "; ")) or ("A \"" .. lines[1][2] .. "\" | X \"" .. lines[2][2] .. "\" | B \"" .. lines[3][2] .. "\""))
end)
-- the row's session put back: no menu, the selection as found, the tool taken away, the pad let go, the lock lifted
H.step(3, function()
    H.qUnwrap()
    H.closeMenu()
    H.selBack()
    if S.scrollOf and S.scrollWas ~= nil and S.scrollOf == H.cc() then
        local s = S.scrollOf._scroll
        if s then pcall(function() s:setScrollPos(S.scrollWas) end) end
    end
    S.scrollOf, S.scrollWas = nil, nil
    if S.padItem then H.removeItem(S.padItem) end
    for _, b in ipairs({ "A", "B", "X", "Y", "LeftBump", "RightBump" }) do RT.pad(b, nil) end
    H.release()
    H.modeBack()
end)
Q.waitMs(400)
H.step(1, function() H.modeFree() end)

-- ===================================================================== K1-11: the car and its key line
H.step(5, function()
    if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_READY and ZEDQA_CAR_ENTER and ZEDQA_CAR_AWAY and ZEDQA_CAR_KEEP) then
        H.must(false, "the car staging: the prelude's car helpers are loaded (zedqa_prelude.lua runs first)")
        S.off.car = true
        return
    end
    ZEDQA_CAR_WAIT("Base.CarNormal", "vk1_wld", function(v)
        S.v = v
        ZEDQA_CAR_KEEP[v] = true
        S.carReady = true
    end, function(why) S.carWhy = why or "no ready car" end, 6000)
end)
H.wait(45000, function() return S.off.car or S.carReady or S.carWhy ~= nil end, function()
    if S.off.car then return end
    if not H.must(S.v ~= nil and S.carReady == true, "the car staging: a Base.CarNormal on the drag strip, its physics awake", tostring(S.carWhy)) then
        S.off.car = true
        return
    end
    -- no key anywhere, not hotwired, the driver's door unlocked (the hood's rule then says no key is needed), the
    -- hood unlocked and shut
    pcall(function() S.v:repair() end)
    pcall(function() if S.v:isHotwired() then S.v:setHotwired(false) end end)
    pcall(function() S.v:setKeyIsOnDoor(false) end)
    local dd = nil
    pcall(function() dd = S.v:getPassengerDoor(0) end)
    local d = H.door(dd)
    if d then pcall(function() d:setLocked(false) end) end
    local hd = H.door(H.hood())
    if hd then pcall(function() hd:setLocked(false); hd:setOpen(false) end) end
    local inIgn = false
    pcall(function() inIgn = S.v:isKeysInIgnition() end)
    S.ignAtSpawn = inIgn
end)
-- (a car that came with its key in the ignition: the key out of it the game's way, at the wheel, and away)
H.step(5, function()
    if S.off.car or not S.ignAtSpawn then return end
    local okC, okE = pcall(ZEDQA_CAR_ENTER, S.v, 0)
    if okC and okE == true then
        pcall(function() S.v:setKeysInIgnition(false) end)
        local k = nil
        pcall(function() k = S.p:getInventory():haveThisKeyId(S.v:getKeyId()) end)
        if k then pcall(function() local c = k:getContainer(); if c then c:Remove(k) end end) end
    end
    H.exitCar()
end)
H.step(10, function()
    if S.off.car then return end
    local inIgn = false
    pcall(function() inIgn = S.v:isKeysInIgnition() end)
    local x, y, z = H.besideCar()
    if not H.must(x ~= nil and not inIgn, "the car staging: no key in the ignition, a free square two beside the car",
        "key in the ignition " .. tostring(inIgn) .. ", square " .. tostring(x ~= nil)) then
        S.off.car = true
        return
    end
    S.stand = { x = x, y = y, z = z }
    H.tp(x, y, z)
    H.openBoth()
    H.holdBoth()
end)
H.wait(6000, function()
    if S.off.car then return true end
    H.keep(RT.ww())
    return H.worldOpen() and H.has(RT.tabs(RT.worldStrip()), "vehicle")
end, function(ok)
    if S.off.car then return end
    if not H.must(ok, "the car staging: beside the car the World window offers its Vehicle tab") then S.off.car = true; return end
    H.holdBoth()
    H.keyWrap()
end)
H.wait(4000, function()
    if S.off.car then return true end
    H.toVehTab()
    return H.onMyCar()
end, function(ok)
    if S.off.car then return end
    if not H.must(ok, "the car staging: the Vehicle tab shows the car", "tab " .. tostring(RT.ww() and RT.ww()._activeTab)) then S.off.car = true; return end
    -- no key on him, easy use off
    H.easy(false)
    local eng = H.part("Engine")
    pcall(function() S.rule = VehicleUtils.RequiredKeyNotFound(eng, S.p) end)
    S.kMark = S.kN
end)
H.wait(3000, function() return S.off.car or H.keyRead() ~= nil end, function()
    if S.off.car then return end
    S.kv.A1 = H.keyRead()
    -- (the same car with the game's easy use on)
    H.easy(true)
    S.kMark = S.kN
end)
H.wait(3000, function() return S.off.car or H.keyRead() ~= nil end, function()
    if S.off.car then return end
    S.kv.A2 = H.keyRead()
    H.easy(nil)
    local noKey, notNeeded = ZeD.tr("UI_ZeD_Dash_PromptNoKey"), ZeD.tr("UI_ZeD_Veh_KeyNotNeeded")
    Q.check(S.kv.A1 == noKey and S.kv.A2 == notNeeded, "K1-11: a found car with no key on him reads No key; Not needed only with the game's easy use",
        "easy use off: \"" .. tostring(S.kv.A1) .. "\" (want \"" .. noKey .. "\"); easy use on: \"" .. tostring(S.kv.A2) .. "\" (want \""
        .. notNeeded .. "\"); the hood's rule (VehicleUtils.RequiredKeyNotFound, easy use off) says a key is needed: " .. tostring(S.rule))
    -- the car's key in his pocket
    pcall(function() S.vkey = S.p:getInventory():AddItem(S.v:createVehicleKey()) end)
    if not H.must(S.vkey ~= nil, "K1-11 staging: the car's key in his pocket") then S.off.key = true; return end
    S.kMark = S.kN
end)
H.wait(3000, function() return S.off.car or S.off.key or H.keyRead() ~= nil end, function()
    if S.off.car or S.off.key then return end
    S.kv.C = H.keyRead()
    -- at the wheel, the key into the ignition by the game's own setKeysInIgnition
    local okC, okE, why = pcall(ZEDQA_CAR_ENTER, S.v, 0)
    if not H.must(okC and okE == true, "K1-11 staging: seated at the wheel", tostring(why or okE)) then S.off.key = true; H.exitCar(); return end
    pcall(function() S.v:setKeysInIgnition(true) end)
end)
H.step(5, function()
    if S.off.car or S.off.key then return end
    local inIgn, onHim = false, true
    pcall(function() inIgn = S.v:isKeysInIgnition() end)
    pcall(function() onHim = S.p:getInventory():haveThisKeyId(S.v:getKeyId()) ~= nil end)
    S.ignOk = inIgn == true and onHim == false
    H.exitCar()
end)
H.step(10, function()
    if S.off.car or S.off.key then return end
    H.tp(S.stand.x, S.stand.y, S.stand.z)
    if not H.must(S.ignOk, "K1-11 staging: the key in the ignition, not in his pocket, him out of the car beside it") then S.off.key = true; return end
    H.openBoth()
    H.holdBoth()
end)
H.wait(5000, function()
    if S.off.car or S.off.key then return true end
    H.toVehTab()
    return H.onMyCar()
end, function(ok)
    if S.off.car or S.off.key then return end
    if not H.must(ok, "K1-11 staging: the Vehicle tab shows the car again") then S.off.key = true; return end
    S.kMark = S.kN
end)
H.wait(3000, function() return S.off.car or S.off.key or H.keyRead() ~= nil end, function()
    if S.off.car or S.off.key then return end
    S.kv.B = H.keyRead()
    local onYou, ign = ZeD.tr("UI_ZeD_Veh_KeyOnYou"), H.ignWords()
    Q.check(S.kv.C == onYou and S.kv.B == ign, "K1-11: the key line follows the key: in his pocket On you, in the ignition Key in ignition",
        "the key in his pocket: \"" .. tostring(S.kv.C) .. "\" (want \"" .. onYou .. "\"); in the ignition: \"" .. tostring(S.kv.B) .. "\" (want \""
        .. ign .. "\", the game's Tooltip_Dashboard_KeysIgnition)")
end)

-- ===================================================================== K1-9: the hood after a look
H.step(3, function()
    S.kBack = H.keyUnwrap()
    if S.off.car then return end
    local cheat = false
    pcall(function() cheat = ISVehicleMechanics ~= nil and ISVehicleMechanics.cheat == true end)
    pcall(function()
        if getCore():getDebug() and getDebugOptions and getDebugOptions() and getDebugOptions():getBoolean("Cheat.Vehicle.MechanicsAnywhere") then cheat = true end
    end)
    if cheat then
        Q.skip("K1-9 (the hood after a look)", "the game's mechanics cheat is on: a look skips the walk and the hood")
        S.off.hood = true
        return
    end
    H.stopActions()
    if S.p:getVehicle() == nil and S.stand then H.tp(S.stand.x, S.stand.y, S.stand.z) end
    local hd = H.door(H.hood())
    if hd then pcall(function() hd:setOpen(false) end) end
    -- (a look is kept by the car's id, which the game hands on to the next car it adds: one left by a car gone before
    -- this one is dropped by the tab's own refresh, so this car starts with no look)
    if H.inspected() and Z.MechanicsTab.refresh and RT.ww() then pcall(Z.MechanicsTab.refresh, RT.ww()) end
    if not H.must(not H.inspected(), "K1-9 staging: the car not looked at yet") then S.off.hood = true; return end
    H.pressU()   -- (look 1)
end)
H.wait(25000, function() return S.off.car or S.off.hood or H.looked() end, function(ok)
    if S.off.car or S.off.hood then return end
    if not H.must(ok, "K1-9 staging: U on the car: he walks to the hood, opens it and looks, and the Vehicle tab opens", H.lookSays()) then
        S.off.hood = true
        H.stopActions()
        return
    end
    H.hold(RT.ww())
    H.pressU()   -- 9b: U again, the Vehicle tab open
    S.u2How = S.uHow
end)
H.wait(1500, function() return S.off.car or S.off.hood or not H.worldOpen() end, function(ok)
    if S.off.car or S.off.hood then return end
    Q.check(ok, "K1-9: U with the Vehicle tab open closes the World window (as the game's U toggles its window)",
        "World window open after U " .. tostring(H.worldOpen()) .. "; U by " .. tostring(S.u2How) .. "; inspected " .. tostring(H.inspected())
        .. ", hood open " .. tostring(H.hoodOpen()))
end)
-- look 2 (a look still open is used as it is)
H.wait(6000, function() return S.off.car or S.off.hood or H.queueEmpty() end, function()
    if S.off.car or S.off.hood then return end
    if not H.looked() then H.pressU() end
end)
H.wait(25000, function() return S.off.car or S.off.hood or H.looked() end, function(ok)
    if S.off.car or S.off.hood then return end
    if not H.must(ok, "K1-9 staging: a second look under the hood", H.lookSays()) then S.off.hood = true; H.stopActions(); return end
    H.hold(RT.ww())
    H.pressE()   -- 9c: E at the open hood
end)
H.step(2, function()
    if S.off.car or S.off.hood then return end
    S.eLook, S.eQueue = H.hasLook(), H.queueTypes()
end)
H.wait(6000, function() return S.off.car or S.off.hood or (not H.hoodOpen() and H.queueEmpty()) end, function(ok)
    if S.off.car or S.off.hood then return end
    local look = S.eLook or H.hasLook()
    Q.check(ok and not H.hoodOpen() and not look, "K1-9: E at the open hood after a look shuts the hood and looks no more",
        "hood open " .. tostring(H.hoodOpen()) .. "; after E the queue held: " .. tostring(S.eQueue) .. " (a look " .. tostring(look) .. "); E by "
        .. tostring(S.eHow) .. "; inspected " .. tostring(H.inspected()))
    H.stopActions()
end)
-- look 3
H.wait(6000, function() return S.off.car or S.off.hood or H.queueEmpty() end, function()
    if S.off.car or S.off.hood then return end
    if not H.looked() then H.pressU() end
end)
H.wait(25000, function() return S.off.car or S.off.hood or H.looked() end, function(ok)
    if S.off.car or S.off.hood then return end
    if not H.must(ok, "K1-9 staging: a third look under the hood", H.lookSays()) then S.off.hood = true; H.stopActions(); return end
    local ww = RT.ww()
    H.hold(ww)
    if ww then ww._boxDo = "close" end   -- 9a: the World window's close box (what a press and release on it asks for)
end)
H.wait(1500, function() return S.off.car or S.off.hood or not H.worldOpen() end, function(ok)
    if S.off.car or S.off.hood then return end
    if not H.must(ok, "K1-9 staging: the World window's close box closes it") then S.off.hood = true end
end)
H.wait(6000, function() return S.off.car or S.off.hood or not H.hoodOpen() end, function(ok)
    if S.off.car or S.off.hood then return end
    Q.check(ok, "K1-9: after a look, closing the World window shuts the hood (as the game's window does)",
        "hood open " .. tostring(H.hoodOpen()) .. "; the queue: " .. H.queueTypes() .. "; inspected " .. tostring(H.inspected()))
    H.stopActions()
end)

-- ===================================================================== put back
Q.mark()
Q.step(3, function()
    local TU = Z.Tutorial
    if TU and TU.running and TU.running() and not S.was.tourOn then pcall(TU.stop) end
    H.tourFileBack()
    H.closeWheel()
    H.closeWinMenu()
    H.closeMenu()
    for _, b in ipairs({ "A", "B", "X", "Y", "LeftBump", "RightBump" }) do RT.pad(b, nil) end
    S.qBack = H.qUnwrap()
    S.kBack = H.keyUnwrap()
    if ISUIHandler and ISUIHandler.allUIVisible == false and S.was.ui ~= false then pcall(ISUIHandler.toggleUI) end
    H.guideBack()
    H.easy(nil)
    if S.padItem then H.removeItem(S.padItem) end
    H.selBack()
    -- the car: him out, its key off him, the car away a tick after (ZEDQA_CAR_AWAY waits for that)
    H.stopActions()
    H.exitCar()
    if S.v then
        local k = nil
        pcall(function() k = S.p:getInventory():haveThisKeyId(S.v:getKeyId()) end)
        if k then pcall(function() local c = k:getContainer(); if c then c:Remove(k) end end) end
    end
    H.release()
    H.modeBack()
end)
Q.waitMs(400)
Q.step(1, function()
    H.modeFree()
    if S.v then
        if ZEDQA_CAR_KEEP then ZEDQA_CAR_KEEP[S.v] = nil end
        if ZEDQA_CAR_AWAY then pcall(ZEDQA_CAR_AWAY, S.v, nil) end
    end
    if S.was.pos and S.p:getVehicle() == nil then
        local dx, dy = S.p:getX() - S.was.pos.x, S.p:getY() - S.was.pos.y
        if math.abs(dx) > 0.01 or math.abs(dy) > 0.01 or math.floor(S.p:getZ()) ~= math.floor(S.was.pos.z) then
            H.tp(S.was.pos.x, S.was.pos.y, S.was.pos.z)
        end
    end
    if S.was.char == nil then return end   -- (the run stopped before it read the windows)
    H.layoutBack(true)
    H.windowsBack()
end)
H.waitUntil(5000, function()
    if S.was.char == nil then return true end
    return H.charOpen() == S.was.char and H.worldOpen() == S.was.world
end, function()
    if S.was.char == nil then return end
    H.layoutBack(false)
end)
H.waitUntil(3000, function()
    if S.was.char == nil then return true end
    return H.settled()
end, function()
    if S.was.char == nil then return end
    local moved = {}
    if S.was.char and H.placeBack(RT.cw(), S.was.geo.c) then moved[#moved + 1] = "Character" end
    if S.was.world and H.placeBack(RT.ww(), S.was.geo.w) then moved[#moved + 1] = "World" end
    S.moved = (#moved > 0) and table.concat(moved, " and ") or nil
    -- the tabs as found
    local cw, ww = RT.cw(), RT.ww()
    if S.was.char and cw and S.was.tab.c and cw._activeTab ~= S.was.tab.c then RT.charTab(S.was.tab.c) end
    if S.was.world and ww and S.was.tab.w and ww._activeTab ~= S.was.tab.w then RT.worldTab(S.was.tab.w) end
end)
Q.step(10, function()
    -- the roll timers as found on the windows found open (a window made again since keeps its own)
    local cw, ww = RT.cw(), RT.ww()
    if cw then if cw == S.was.cwObj then cw._outSince = S.was.outC else cw._outSince = nil end end
    if ww then if ww == S.was.wwObj then ww._outSince = S.was.outW else ww._outSince = nil end end
    H.statsBack()
    local bad = H.hurt()
    H.must(#bad == 0, "put back: he is alive and well (nothing here can hurt him)", (#bad > 0) and table.concat(bad, ", ")
        or ("alive, health " .. H.num(S.was.health) .. " at the start and no worse, no infection"))
    local seated = nil
    pcall(function() seated = S.p:getVehicle() end)
    local carLeft = false
    if S.v then pcall(function() carLeft = not S.v:isRemovedFromWorld() end) end
    H.must(seated == nil and H.queueEmpty(), "put back: him on foot, nothing queued", "seated " .. tostring(seated ~= nil) .. ", the queue " .. H.queueTypes())
    if S.v then
        H.must(not carLeft, "put back: the car taken away (ZEDQA_CAR_AWAY removes it a tick after he is out)", "still in the world " .. tostring(carLeft))
    end
    local itemLeft = false
    if S.padItem then pcall(function() itemLeft = S.padItem:getContainer() ~= nil or S.padItem:getWorldItem() ~= nil end) end
    H.must(not itemLeft, "put back: the given tool taken away", tostring(S.padItem and S.padItem:getFullType()))
    if S.qEver or S.kEver then
        local M = Z.Molecules
        H.must(S.qBack ~= false and S.kBack ~= false and (not S.qEver or ISTimedActionQueue.add == S.qOrig) and (not S.kEver or (M and M.drawStatRowDot == S.kOrig)),
            "put back: ISTimedActionQueue.add and ZeD.Molecules.drawStatRowDot are their own again (the two wrappers off)")
    end
    H.must((SandboxVars == nil) or SandboxVars.VehicleEasyUse == S.was.easy, "put back: the game's easy use as found", tostring(SandboxVars and SandboxVars.VehicleEasyUse))
    H.must(ISUIHandler.allUIVisible == S.was.ui or (S.was.ui == nil and ISUIHandler.allUIVisible ~= false), "put back: the interface shown as found", tostring(ISUIHandler.allUIVisible))
    if S.gBack then
        local G = Z.GuideBubble
        local flag = H.joinLines(H.readFile(S.GFILE)) or ""
        H.must(G.FIRST_MS == S.gBack.FIRST and flag == S.gBack.flag and H.opt(Z.Settings.messagesToastOption) == S.gBack.toastOpt and H.guideToast() == nil,
            "put back: the guide bubble's clock, its file and the balloons setting as found, no bubble up",
            "file \"" .. flag:gsub("\n", " ") .. "\", balloons " .. tostring(H.opt(Z.Settings.messagesToastOption)))
    end
    if S.tourTouched == nil and S.was.tour ~= false then
        local now = H.joinLines(H.readFile(S.TFILE)) or ""
        local was = H.joinLines(S.was.tour) or ""
        local TU = Z.Tutorial
        H.must(now == was and not (TU.running() and not S.was.tourOn), "put back: the tour stopped and its file as found", "\"" .. now:gsub("\n", " ") .. "\"")
    end
    H.must(H.wheelSt() == nil and not H.vis(H.radial()) and not H.menuUp(), "put back: no wheel and no menu up")
    if S.lockWas ~= nil and S.was.mode ~= nil then
        local now, mode = H.lockFound(), H.mode()
        local unknown = S.was.mode == "unknown" and mode == "kbm"
        H.must(now == S.lockWas and (mode == S.was.mode or unknown) and S.modeHeld == nil, "put back: the input lock as found, and the mode ZeD reads",
            "ZeD setup's Input lock " .. tostring(now) .. " (found " .. tostring(S.lockWas) .. "); ZeD reads " .. tostring(mode) .. " (found "
            .. tostring(S.was.mode) .. ")")
    end
    if S.was.char ~= nil then
        local c, w = H.charOpen(), H.worldOpen()
        local gc = c and H.geo(cw) or nil
        local gw = w and H.geo(ww) or nil
        local tc = (c and cw) and cw._activeTab or nil
        local tw = (w and ww) and ww._activeTab or nil
        H.must(c == S.was.char and w == S.was.world and H.sameGeo(gc, S.was.geo.c) and H.sameGeo(gw, S.was.geo.w) and tc == S.was.tab.c and tw == S.was.tab.w,
            "put back: the Character and World windows open or shut as found, where and as big as they were, on their tabs",
            "Character open " .. tostring(c) .. " " .. H.gs(gc) .. " on " .. tostring(tc) .. " (found " .. tostring(S.was.char) .. " " .. H.gs(S.was.geo.c)
            .. " on " .. tostring(S.was.tab.c) .. "); World open " .. tostring(w) .. " " .. H.gs(gw) .. " on " .. tostring(tw) .. " (found "
            .. tostring(S.was.world) .. " " .. H.gs(S.was.geo.w) .. " on " .. tostring(S.was.tab.w) .. ")"
            .. (S.moved and ("; the reopen left the " .. S.moved .. " window elsewhere: set back by its own setters") or ""))
    end
    -- (last: a game found paused is paused again; the car's removal above needed the ticks)
    if S.was.speed == 0 then pcall(setGameSpeed, 0) end
end)
Q.start()
