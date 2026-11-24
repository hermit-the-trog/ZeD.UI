-- ZeDUI/tools/qa/popups_close_sim.lua
-- (the director, Nov 23 2026: "Drop-down list selection boxes should disappear if they aren't used.") Runs the real
-- ZeD_Popups.lua and ZeD_MouseTick.lua on stubs: shown / openCount / openKeys; a press outside shuts a list and one
-- inside keeps it; a list missing from MISS frames shuts, one drawn every frame never does; a queued action shuts
-- player lists, not main menu ones; the list's own keys keep it, a game key shuts it; the context list gets rule c
-- only. Then a source check that every wired file tells ZeD.Popups its list was drawn.
-- Run from the repo root: lua51 ZeDUI/tools/qa/popups_close_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]popups_close_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if ok then print("ok   " .. name) else failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function read(rel)
    local f = io.open(ROOT .. rel, "rb")
    if not f then return nil end
    local s = f:read("*a"):gsub("\r\n", "\n")
    f:close()
    return s
end

-- ---------------------------------------------------------------------------
-- stubs
-- ---------------------------------------------------------------------------
local handlers = {}
local function ev(name)
    handlers[name] = handlers[name] or {}
    return { Add = function(fn) table.insert(handlers[name], fn) end, Remove = function() end }
end
Events = {}
for _, n in ipairs({ "OnPreUIDraw", "OnPostUIDraw", "OnKeyStartPressed", "OnKeyPressed", "OnPlayerUpdate",
                     "OnGameBoot", "OnGameStart" }) do Events[n] = ev(n) end
local function fire(name, ...)
    for _, fn in ipairs(handlers[name] or {}) do fn(...) end
end
Keyboard = { KEY_UP = 200, KEY_DOWN = 208, KEY_LEFT = 203, KEY_RIGHT = 205, KEY_RETURN = 28, KEY_ESCAPE = 1,
             KEY_BACK = 14, KEY_PRIOR = 201, KEY_NEXT = 209, KEY_HOME = 199, KEY_END = 207, KEY_LSHIFT = 42,
             KEY_RSHIFT = 54, KEY_LCONTROL = 29, KEY_Q = 16, KEY_F1 = 59, KEY_W = 17 }
local mouseDown = { [0] = false, [1] = false }
local mx, my = 0, 0
function isMouseButtonDown(b) return mouseDown[b] == true end
function getMouseX() return mx end
function getMouseY() return my end
function getTimestampMs() return 0 end
local queued = {}
ISTimedActionQueue = { add = function(action) queued[#queued + 1] = action; return "q", action end }
JoypadState = { players = {} }
require = function() end

ZeD = {}
assert(loadstring(assert(read("42/media/lua/client/ZeD/ZeD_MouseTick.lua"), "no ZeD_MouseTick.lua")))()
assert(loadstring(assert(read("42/media/lua/client/ZeD/ZeD_Popups.lua"), "no ZeD_Popups.lua")))()
local P = ZeD.Popups
check("ZeD.Popups loads", P ~= nil and P.shown ~= nil and P.openCount ~= nil and P.openKeys ~= nil)

-- one UI frame: OnPreUIDraw (the press sample, the frame count), the lists that draw, OnPostUIDraw
local function frame(draw)
    fire("OnPreUIDraw")
    if draw then draw() end
    fire("OnPostUIDraw")
end
-- a press and its release, one frame each, while drawFn (the lists still open) draws
local function press(b, x, y, drawFn)
    mx, my = x, y
    mouseDown[b] = true
    frame(drawFn)
    mouseDown[b] = false
    frame(drawFn)
end

-- a list owner: open flag, a closer that counts
local function owner(name)
    local o = { name = name, open = true, closed = 0 }
    return o
end
local function isOpen(o) return o.open == true end
local function closer(o) o.open = false; o.closed = o.closed + 1 end
local function draw(o, key, opts, rects)
    if not o.open then return end
    opts = opts or {}
    opts.arg, opts.isOpen = o, isOpen
    P.shown(key, rects or { { x = 100, y = 100, w = 50, h = 80 }, { x = 100, y = 180, w = 50, h = 20 } }, closer, opts)
end

-- ---------------------------------------------------------------------------
-- shown, openCount, openKeys
-- ---------------------------------------------------------------------------
local a = owner("a")
local aOpts = { player = 0 }
frame(function() draw(a, "health:0", aOpts) end)
check("a drawn list is counted", P.openCount() == 1, P.openCount())
local keys = P.openKeys()
check("openKeys names it", keys[1] == "health:0" and #keys == 1, table.concat(keys, ","))

-- ---------------------------------------------------------------------------
-- (a) presses
-- ---------------------------------------------------------------------------
local function drawA() draw(a, "health:0", aOpts) end
press(0, 120, 150, drawA)
check("a press inside the list keeps it", a.open and a.closed == 0)
press(0, 110, 190, drawA)
check("a press on its box keeps it (the box toggles it as before)", a.open and a.closed == 0)
mx, my = 120, 150
mouseDown[0] = true
frame(drawA)
mx, my = 500, 500   -- (held: no new press)
frame(drawA)
mouseDown[0] = false
frame(drawA)
check("a held button moved outside is no press", a.open and a.closed == 0)
press(0, 500, 500, drawA)
check("a left press outside shuts it through its closer", not a.open and a.closed == 1)
check("and openCount() == 0", P.openCount() == 0, P.openCount())
check("why: press", P.lastWhy == "press", P.lastWhy)

a = owner("a")
frame(drawA)
press(1, 10, 10, drawA)
check("a right press outside shuts it too", not a.open and a.closed == 1)

local mm = owner("mm")
local function drawMM() draw(mm, "mm:menu", { noPlayer = true, noPress = true }) end
frame(drawMM)
press(0, 900, 900, drawMM)
check("noPress (the main menu shuts its own): a press outside leaves it to the owner", mm.open and mm.closed == 0)

-- ---------------------------------------------------------------------------
-- (b) not drawn
-- ---------------------------------------------------------------------------
frame(nil)
check("one frame missed: still open (a late frame never shuts it)", mm.open and mm.closed == 0)
frame(nil)
check("MISS frames missed: shut", not mm.open and mm.closed == 1 and P.MISS == 2)
check("why: hidden", P.lastWhy == "hidden", P.lastWhy)

local steady = owner("steady")
for _ = 1, 200 do frame(function() draw(steady, "craft:sort:0", { player = 0 }) end) end
check("a list drawn every frame is never shut", steady.open and steady.closed == 0)
local alt = owner("alt")
for i = 1, 40 do
    frame(function()
        draw(steady, "craft:sort:0", { player = 0 })
        if i % 2 == 0 then draw(alt, "maps:style:0", { player = 0 }) end
    end)
end
check("a list drawn every other frame is never shut", alt.open and alt.closed == 0)

-- an owner that shut its list itself: let go, its closer not run again; one still open and no longer drawn: shut
steady.open = false
frame(nil); frame(nil)
check("a list its owner shut is let go without its closer", steady.closed == 0)
check("one still open but no longer drawn is shut", not alt.open and alt.closed == 1)
check("all let go", P.openCount() == 0, table.concat(P.openKeys(), ","))

-- ---------------------------------------------------------------------------
-- (c) a timed action
-- ---------------------------------------------------------------------------
local chr0 = { getPlayerNum = function() return 0 end }
local chr1 = { getPlayerNum = function() return 1 end }
local p0, p1, menu = owner("p0"), owner("p1"), owner("menu")
local function drawAll()
    draw(p0, "station:0", { player = 0 })
    draw(p1, "station:1", { player = 1 })
    draw(menu, "mm:menu", { noPlayer = true, noPress = true })
end
frame(drawAll)
check("three open", P.openCount() == 3, P.openCount())
local act = { character = chr1 }
local r1, r2 = ISTimedActionQueue.add(act)
check("the wrapped queue keeps the game's return", r1 == "q" and r2 == act and queued[#queued] == act)
check("an action for player 1 shuts player 1's list", not p1.open and p1.closed == 1)
check("not player 0's", p0.open)
ISTimedActionQueue.add({ character = chr0 })
check("an action for player 0 shuts player 0's list", not p0.open and p0.closed == 1)
check("a main menu list (no player) is never shut by an action", menu.open and menu.closed == 0)
check("why: action", P.lastWhy == "action", P.lastWhy)

p0 = owner("p0")
frame(function() draw(p0, "ctx:0", { player = 0 }) end)
P.firing(function() ISTimedActionQueue.add({ character = chr0 }) end)
check("an action a list's own row queues (firing) does not shut it", p0.open)
ISTimedActionQueue.add({ character = chr0 })
check("one queued afterwards does", not p0.open)
check("a second load of the file does not wrap the queue again", ISTimedActionQueue._zedPopups == true)

-- ---------------------------------------------------------------------------
-- (c) keys
-- ---------------------------------------------------------------------------
local k = owner("k")
local typ = owner("typ")
local function drawK()
    draw(k, "cook:dish:0", { player = 0 })
    draw(typ, "typing:0", { player = 0, typing = true })
end
frame(drawK)
for _, key in ipairs({ Keyboard.KEY_UP, Keyboard.KEY_DOWN, Keyboard.KEY_RETURN, Keyboard.KEY_ESCAPE, Keyboard.KEY_PRIOR,
                       Keyboard.KEY_NEXT, Keyboard.KEY_HOME, Keyboard.KEY_END, Keyboard.KEY_BACK, Keyboard.KEY_LSHIFT }) do
    fire("OnKeyStartPressed", key)
end
check("the list's own keys (arrows, Enter, Esc, Page Up / Down, Home / End, Backspace, Shift) keep it", k.open and typ.open)
fire("OnKeyStartPressed", Keyboard.KEY_Q)
check("a game key (Q) shuts a list without typing", not k.open and k.closed == 1)
check("a list that types ahead keeps a printable key", typ.open)
fire("OnKeyStartPressed", Keyboard.KEY_F1)
check("and shuts on a game key that types nothing (F1)", not typ.open)
check("why: key", P.lastWhy == "key", P.lastWhy)
check("the key goes down: OnKeyStartPressed, not the release", #(handlers.OnKeyStartPressed or {}) == 1 and #(handlers.OnKeyPressed or {}) == 0)

local pad = owner("pad")
JoypadState.players[2] = {}   -- player 1 plays with a controller
frame(function() draw(pad, "health:1", { player = 1 }) end)
fire("OnKeyStartPressed", Keyboard.KEY_Q)
check("a key does not shut a controller player's list (split screen)", pad.open)
JoypadState.players[2] = nil
pad.open = false
frame(nil); frame(nil); frame(nil)

-- ---------------------------------------------------------------------------
-- (c) walking
-- ---------------------------------------------------------------------------
local moving = { [0] = false }
local pl0 = { getPlayerNum = function() return 0 end, isPlayerMoving = function() return moving[0] end }
fire("OnPlayerUpdate", pl0)
local w = owner("w")
local function drawW() draw(w, "mech:sort:0", { player = 0 }) end
frame(drawW)
fire("OnPlayerUpdate", pl0)
check("standing still keeps it", w.open)
moving[0] = true
fire("OnPlayerUpdate", pl0)
check("the player starting to walk shuts it", not w.open and w.closed == 1)
check("why: move", P.lastWhy == "move", P.lastWhy)
w = owner("w")
frame(drawW)   -- (opened while walking)
fire("OnPlayerUpdate", pl0)
check("a list opened while walking stays while the walk goes on", w.open)
moving[0] = false
fire("OnPlayerUpdate", pl0)
frame(drawW)
moving[0] = true
fire("OnPlayerUpdate", pl0)
check("and shuts when the player stops and walks again", not w.open)
moving[0] = false
fire("OnPlayerUpdate", pl0)
frame(nil); frame(nil); frame(nil)

-- ---------------------------------------------------------------------------
-- (d) the context list: rule c only
-- ---------------------------------------------------------------------------
local c = owner("ctx")
local cOpts = { player = 0, selfClosing = true, noMove = true }
local function drawC() draw(c, "ctx:0", cOpts) end
frame(drawC)
press(0, 900, 900, drawC)
check("context list: a press outside is its own (no closer from here)", c.open and c.closed == 0)
moving[0] = true
fire("OnPlayerUpdate", pl0)
check("context list: walking is its own (its walk-off rule)", c.open)
moving[0] = false
fire("OnPlayerUpdate", pl0)
fire("OnKeyStartPressed", Keyboard.KEY_UP)
check("context list: its keys keep it", c.open)
fire("OnKeyStartPressed", Keyboard.KEY_W)
check("context list: a key meant for the game shuts it", not c.open and c.closed == 1)
c = owner("ctx")
frame(drawC)
ISTimedActionQueue.add({ character = chr0 })
check("context list: an action queued shuts it", not c.open and c.closed == 1)
c = owner("ctx")
frame(drawC)
frame(nil); frame(nil)
check("context list not drawn: forgotten, its closer not run (it shuts itself)", c.open and c.closed == 0 and P.openCount() == 0)

-- ---------------------------------------------------------------------------
-- shownAt and closeAll
-- ---------------------------------------------------------------------------
local panel = { getAbsoluteX = function() return 1000 end, getAbsoluteY = function() return 500 end }
local s = owner("s")
local sOpts = { arg = s, isOpen = isOpen, player = 0 }
local function drawS() if s.open then P.shownAt("thermal:0", panel, closer, sOpts, 10, 10, 40, 60, 10, 70, 40, 20) end end
frame(drawS)
press(0, 1020, 520, drawS)
check("shownAt: a press inside the panel-local rect (moved to the screen) keeps it", s.open)
press(0, 1020, 575, drawS)
check("shownAt: a press on the second rect (the box) keeps it", s.open)
press(0, 20, 20, drawS)
check("shownAt: the same spot in screen terms but outside the moved rect shuts it", not s.open)
local o1, o2 = owner("o1"), owner("o2")
frame(function() draw(o1, "x:0", { player = 0 }); draw(o2, "y:0", { player = 0 }) end)
P.closeAll()
check("closeAll shuts every list", not o1.open and not o2.open and P.openCount() == 0)

-- ---------------------------------------------------------------------------
-- ZeD_MouseTick: the listener sees left and right presses once
-- ---------------------------------------------------------------------------
local seen = {}
ZeD.MouseTick.listen(function(b, x, y) seen[#seen + 1] = b end)
mouseDown[0] = true; ZeD.MouseTick.sample(); ZeD.MouseTick.sample(); mouseDown[0] = false; ZeD.MouseTick.sample()
mouseDown[1] = true; ZeD.MouseTick.sample(); ZeD.MouseTick.sample(); mouseDown[1] = false; ZeD.MouseTick.sample()
check("MouseTick.listen: one left press and one right press, each told once", #seen == 2 and seen[1] == 0 and seen[2] == 1, #seen)

-- ---------------------------------------------------------------------------
-- source: every wired list tells ZeD.Popups it was drawn
-- ---------------------------------------------------------------------------
local wired = {
    { "HealthTab.lua", "ZeD.Popups.shownAt(po.key, panel, ZeD.HealthTab.closeMenu" },
    { "ThermalTab.lua", "ZeD.Popups.shownAt(po.key, panel, ZeD.ThermalTab.closeMenu" },
    { "ZeD_JournalReaders.lua", "ZeD.Popups.shownAt(po.key, panel, J.shutList" },
    -- (ZeD_JournalLists.lua's list went with the add-on ZeD-GUI: Loadouts, Nov 23 2026: its tests/source_sim.lua)
    { "CraftingCore.lua", "CC.popupsShown(panel, win, state, config)" },
    { "CraftingCore.lua", "Pp.shownAt(po.key, panel, CC.closeCatDropdown" },
    { "Stations.lua", "Pp.shownAt(po.key, panel, ST.closeDropdown" },
    { "CookingTab.lua", "ZeD.Popups.shownAt(po.key, panel, CK.closePopup" },
    { "MechanicsTab.lua", "ZeD.Popups.shownAt(po.key, panel, MT.closeSort" },
    { "MapsTab.lua", "ZeD.Popups.shownAt(po.key, target, ZeD.MapsTab.closeStyleMenu" },
    { "Molecules.lua", "ZeD.Popups.shownAt(po.key, self, ZeD_Dropdown.closeList" },
    { "ForagingTab.lua", "dd.popKey, dd.popPlayer = \"forage:focus\"" },
    { "ZeD_TicketCards.lua", "ZeD.Popups.shownAt(po.key, panel, TC.shutPopup" },
    { "ZeD_MainMenu.lua", "ZeD.Popups.shown(\"mm:menu\", nil, MM.popClose" },
    { "ZeD_MainMenu.lua", "Pp.shownAt(po.key, nil, MM.palClose" },
    { "ZeD_MainMenuOptions.lua", "MM.palShown(self, " },
    { "ZeD_MainMenuModsPanes.lua", "MM.palShown(self, \"palette:mods\")" },
    { "ZeD_ContextList.lua", "ZeD.Popups.shown(po.key, nil, ZeD_ContextList.popClose" },
}
for _, wdef in ipairs(wired) do
    local src = read("42/media/lua/client/ZeD/" .. wdef[1]) or ""
    check("wired: " .. wdef[1] .. " (" .. string.sub(wdef[2], 1, 40) .. ")", string.find(src, wdef[2], 1, true) ~= nil)
end
local cl = read("42/media/lua/client/ZeD/ZeD_ContextList.lua") or ""
check("ContextList fires its row through ZeD.Popups.firing (keepOpen rows stay)", string.find(cl, "pcall(ZeD.Popups.firing, r.def.onFire", 1, true) ~= nil)
local pp = read("42/media/lua/client/ZeD/ZeD_Popups.lua") or ""
local bad = nil
for i = 1, #pp do if string.byte(pp, i) > 127 then bad = i; break end end
check("ZeD_Popups.lua is ASCII only", bad == nil, bad)
check("ZeD_Popups.lua calls no next()", not string.find(pp, "[^%w_]next%s*%("))

-- ---------------------------------------------------------------------------
-- QA's notes (Nov 23 2026)
-- ---------------------------------------------------------------------------
P.closeAll()
-- 1. an action no player can be named for shuts nobody's list (split screen)
local s1, s2 = owner("s1"), owner("s2")
local o1, o2 = { player = 0 }, { player = 1 }
frame(function() draw(s1, "n1:0", o1); draw(s2, "n1:1", o2) end)
P.onAction({ character = nil })
frame(function() draw(s1, "n1:0", o1); draw(s2, "n1:1", o2) end)
check("note 1: an action with no player shuts no list", s1.open and s2.open)
P.onAction({ character = { getPlayerNum = function() return 1 end } })
check("note 1: player 1's action shuts only player 1's list", s1.open and not s2.open)
P.closeAll()
-- 2. lastWhy is only set for a list this shut, not one its owner already shut
local w = owner("w")
frame(function() draw(w, "n2:0", { player = 0 }) end)
P.lastWhy, P.lastClosed = "before", nil
w.open = false                       -- the owner shuts it (a pick)
frame(function() end); frame(function() end); frame(function() end)
check("note 2: a list its owner shut leaves lastWhy alone", P.lastWhy == "before" and P.openCount() == 0, tostring(P.lastWhy))
-- 3. a list with no player keys as the slot alone
local nobody = {}
check("note 3: no player: the key is the slot alone", P.opts(nobody, "palette:mods", isOpen, nil).key == "palette:mods")
check("note 3: a player: slot:player", P.opts({}, "health", isOpen, 0).key == "health:0")

print("popups_close_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
