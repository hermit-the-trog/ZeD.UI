-- ZeDUI/tools/qa/player_theme_sim.lua  (Nov 13 2026, Build; the director's ruling on split view themes)
-- In split view each local player picks their own base theme, accent and status set, saved with their character;
-- the text size stays one for the whole screen, and the first player alone draws and costs as before.
-- With no game running, the real Tokens.lua and PlayerTheme.lua run on Lua 5.1 against stubs (as theme_look_core_sim
-- does), and the per-window accent swap is cut out of Organisms.lua and run on a fake window. It checks:
--   SHARED   ZeD.Tfor(0) and Tfor(nil) are ZeD.T itself; so is a player's table outside split view, and with no
--            choice of their own or the first player's own choice
--   OWN      split view, player 2 on Light / Red: their own table, the same px closure and fonts, another accent,
--            solid surfaces in Light while the first player keeps See-through in Dark (and the other way round:
--            the first player on Light does not turn a Dark player solid); the status set is their own too
--   CACHE    asked twice, the same table; a new choice or applyTheme builds it again from the new shared table
--   ADOPT    an adopted element's prerender, children and render all see the player's table, ZeD.T is the shared
--            table after; a first player's element is left untouched; adopting twice adds no layer; a wrapper put
--            over ours later is moved under it from the next frame; a failed prerender puts the shared table back
--   NESTING  a window with an accent of its own inside the player's switch: its accent shows inside, the player's
--            table gets its own colors back after, the shared table is never touched; a theme applied half way
--            through the draw leaves ZeD.T the new shared table, whose colors the window does not overwrite
--   SAVE     a pick goes onto the character (own = true) and comes back on OnCreatePlayer; a character without
--            its own pick follows the first player; OnPreUIDraw puts the shared table back
-- What it can't show: the colors on screen, the engine's real draw order.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/player_theme_sim.lua
-- It prints FAIL lines and a last line "player_theme_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]player_theme_sim%.lua$", "")
local CDIR = ROOT .. "42/media/lua/client/ZeD/"
local SDIR = ROOT .. "42/media/lua/shared/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end

-- a top-level function of a file, from its opening text to its first unindented "end"
local function cutFn(src, open)
    local a = src:find(open, 1, true)
    if not a then return nil end
    local e = src:find("\nend\n", a, true)
    if not e then return nil end
    return src:sub(a, e + 4)
end

-- ---------------------------------------------------------------------------
-- THE STUBS
-- ---------------------------------------------------------------------------
local dummy
dummy = setmetatable({}, {
    __index = function(_, k) if type(k) == "number" then return nil end return dummy end,
    __call = function() return dummy end,
})
require = function() end
getText = function(k) return k end

local handlers = {}
local function event(name)
    return { Add = function(fn) handlers[name] = handlers[name] or {}; table.insert(handlers[name], fn) end }
end
Events = { OnPreUIDraw = event("OnPreUIDraw"), OnCreatePlayer = event("OnCreatePlayer") }

local players = {}
local function newPlayer()
    local md = {}
    return { getModData = function() return md end, _md = md }
end
getSpecificPlayer = function(pn) return players[pn] end

ZeD = {
    Scale = { root = function() return 1 end },
    Text  = { checkRoleFonts = function() return false end, noFonts = true },
    Font  = { sdf = { sec = { font = 1 }, body = { font = 2 }, stat = { font = 3 }, head = { font = 4 }, title = { font = 5 } } },
}
setmetatable(_G, { __index = function() return dummy end })

local function load(dir, name)
    local f, err = loadfile(dir .. name)
    if not f then print("player_theme_sim: " .. tostring(err)); os.exit(1) end
    local ok, e = pcall(f)
    if not ok then print("player_theme_sim: " .. name .. ": " .. tostring(e)); os.exit(1) end
end

load(SDIR, "Tokens.lua")
load(CDIR, "PlayerTheme.lua")
setmetatable(_G, nil)
local TH = ZeD.Theme

-- the per-window accent swap, cut from Organisms.lua (windowAccentPalette, the swap block of _drawFrame,
-- _restoreAccent) and run on a fake window
local org = readFile(CDIR .. "Organisms.lua") or ""
local wapStart = org:find("local accentPalettes = {}\nlocal function windowAccentPalette(", 1, true)
local wapEnd = wapStart and org:find("\nend\n", wapStart, true)
local swapA = org:find("    local bk = T.baseKey or ZeD.currentBase\n", 1, true)
local swapB = swapA and org:find("    -- this window's own see-through", swapA, true)
local restore = cutFn(org, "function ZeD_Window:_restoreAccent()")
check("Organisms.lua: the accent palette, the swap and the restore are found",
    wapStart ~= nil and wapEnd ~= nil and swapA ~= nil and swapB ~= nil and restore ~= nil)
ZeD_Window = {}
if wapStart and wapEnd and swapA and swapB and restore then
    local chunk = org:sub(wapStart, wapEnd + 4) ..
        "function ZeD_Window:_swapAccent()\n    local T = ZeD.T\n" .. org:sub(swapA, swapB - 1) .. "end\n" .. restore
    local f, err = loadstring(chunk, "=Organisms cut")
    if not f then print("player_theme_sim: " .. tostring(err)); os.exit(1) end
    f()
end

local function same(a, b)
    return a and b and math.abs(a.r - b.r) < 1e-9 and math.abs(a.g - b.g) < 1e-9 and math.abs(a.b - b.b) < 1e-9
end

-- ---------------------------------------------------------------------------
section("SHARED: the first player, split view off, a player who follows")
-- ---------------------------------------------------------------------------
ZeD.surfaceAlpha = 0.8
ZeD.splitWindows = false
ZeD.applyTheme("dark", "teal", "small")
local S = ZeD.T
check("applyTheme sets ZeD._sharedT to ZeD.T", ZeD._sharedT == S)
check("the shared table carries its keys", S.baseKey == "dark" and S.accentKey == "teal" and S.statusKey == "standard"
    and S.surfaceAlpha == 0.8, tostring(S.baseKey) .. " " .. tostring(S.accentKey) .. " " .. tostring(S.surfaceAlpha))
check("Tfor(0) is ZeD.T", ZeD.Tfor(0) == ZeD.T)
check("Tfor(nil) is ZeD.T", ZeD.Tfor(nil) == ZeD.T)
TH.choice[1] = { base = "light", accent = "red" }
check("split view off: player 2's own choice is not used", ZeD.Tfor(1) == ZeD.T)
TH.choice[1] = nil
ZeD.splitWindows = true
check("split view on, no choice: player 2 follows the first player", ZeD.Tfor(1) == ZeD.T)
TH.choice[1] = { base = "dark", accent = "teal", status = "standard" }
check("split view on, the first player's own choice: the shared table", ZeD.Tfor(1) == ZeD.T)
TH.choice[1] = nil

-- ---------------------------------------------------------------------------
section("OWN: player 2 on Light / Red")
-- ---------------------------------------------------------------------------
players[1] = newPlayer()
TH.set(1, "light", "red")
local P = ZeD.Tfor(1)
check("Tfor(1) is not the shared table", P ~= ZeD.T)
check("the same px closure", P.px == ZeD.T.px)
check("the same fonts and sizes", P.fontF1 == ZeD.T.fontF1 and P.fontF5 == ZeD.T.fontF5 and P.rowH == ZeD.T.rowH
    and P.scale == ZeD.T.scale and P.sp == ZeD.T.sp)
check("its keys", P.baseKey == "light" and P.accentKey == "red" and P.statusKey == "standard")
check("another accent", not same(P.accent, ZeD.T.accent) and same(P.accent, ZeD.AccentColors.red.light.accent))
check("Light draws solid: surf1.a == 1", P.surf1.a == 1 and P.base.a == 1 and P.surfaceAlpha == 1, P.surf1.a)
check("the first player on Dark keeps See-through", ZeD.T.surf1.a == 0.8 and ZeD.surfaceAlpha == 0.8, ZeD.T.surf1.a)
check("the readable colors are solved for Light", P.textOnFocus ~= nil and not same(P.text, ZeD.T.text))
check("iconTone for Light", P.iconTone.r == 0 and ZeD.T.iconTone.r == 1)
check("asked again: the same table", ZeD.Tfor(1) == P)
check("the shared table's colors are its own", same(ZeD.T.accent, ZeD.AccentColors.teal.dark.accent))
TH.set(1, nil, nil, "cb")
local Pcb = ZeD.Tfor(1)
check("a new choice builds a new table", Pcb ~= P)
check("the status set is the player's own", same(Pcb.positive, ZeD.StatusColors.cb.light.positive)
    and same(ZeD.T.positive, ZeD.BaseThemes.dark.positive))
check("set(pn, nil, nil, status) keeps base and accent", Pcb.baseKey == "light" and Pcb.accentKey == "red")
TH.set(1, nil, nil, "standard")

-- the first player on Light, player 3 on Dark: the pick still shows for player 3
ZeD.applyTheme("light", nil, nil)
check("the first player on Light: solid", ZeD.T.surf1.a == 1)
players[2] = newPlayer()
TH.set(2, "dark", "teal")
check("player 3 on Dark keeps See-through 0.8 while the first player is on Light",
    ZeD.Tfor(2).surf1.a == 0.8, ZeD.Tfor(2).surf1.a)
ZeD.applyTheme("dark", nil, nil)
check("back on Dark the first player's pick comes back", ZeD.T.surf1.a == 0.8)
check("player 3 now matches the first player: the shared table", ZeD.Tfor(2) == ZeD.T)

-- ---------------------------------------------------------------------------
section("CACHE: applyTheme clears it")
-- ---------------------------------------------------------------------------
local before = ZeD.Tfor(1)
ZeD.applyTheme(nil, nil, "large")
local after = ZeD.Tfor(1)
check("after applyTheme player 2 gets a new table", after ~= before)
check("built from the new shared table (Large px)", after.px == ZeD.T.px and after.scale == ZeD.T.scale and after.scale ~= before.scale)
check("still Light / Red", after.baseKey == "light" and after.accentKey == "red")
ZeD.applyTheme(nil, nil, "small")

-- ---------------------------------------------------------------------------
section("ADOPT")
-- ---------------------------------------------------------------------------
local seen = {}
local Class = {}
Class.__index = Class
function Class:prerender() seen[#seen + 1] = { "pre", ZeD.T } end
function Class:render() seen[#seen + 1] = { "ren", ZeD.T } end
local function newEl(pn) return setmetatable({ playerNum = pn }, Class) end
local function drawFrame(el, child)
    for _, fn in ipairs(handlers.OnPreUIDraw or {}) do fn() end
    el.prerender(el)
    seen[#seen + 1] = { "child", ZeD.T }
    if child then child() end
    el.render(el)
end

local el = newEl(1)
TH.adopt(el)
check("adopt puts its own prerender and render on the element", rawget(el, "prerender") ~= nil and rawget(el, "render") ~= nil)
seen = {}
drawFrame(el)
local P2 = ZeD.Tfor(1)
check("prerender, children and render see player 2's table",
    #seen == 3 and seen[1][2] == P2 and seen[2][2] == P2 and seen[3][2] == P2)
check("after: the shared table", ZeD.T == ZeD._sharedT)
local pre1 = rawget(el, "prerender")
TH.adopt(el)
check("adopted twice: no new layer", rawget(el, "prerender") == pre1)

local el0 = newEl(0)
TH.adopt(el0)
check("the first player's element is left as it is", rawget(el0, "prerender") == nil and rawget(el0, "render") == nil)
local elA = newEl(0)
TH.adopt(elA, nil, true)
seen = {}
drawFrame(elA)
check("always: a first player's element draws in the shared table", seen[1][2] == ZeD.T and seen[3][2] == ZeD.T)
elA.playerNum = 1
seen = {}
drawFrame(elA)
check("always: the player set after it went up is read each frame", seen[1][2] == P2 and seen[3][2] == P2)

-- split view off: the wrapper is only a compare
ZeD.splitWindows = false
seen = {}
drawFrame(el)
check("split view off: the shared table throughout", seen[1][2] == ZeD.T and seen[2][2] == ZeD.T and seen[3][2] == ZeD.T)
ZeD.splitWindows = true

-- a wrapper put over ours later (a window's own render added after it opened)
local outerSeen
local inner = el.render
el.render = function(self) inner(self); outerSeen = ZeD.T end
drawFrame(el)
drawFrame(el)
check("a later wrapper ends up inside the switch from the next frame", outerSeen == P2, tostring(outerSeen == ZeD.T))
check("after: the shared table", ZeD.T == ZeD._sharedT)

-- a failed prerender puts the shared table back
local elE = newEl(1)
function elE:prerender() error("boom") end
TH.adopt(elE)
local ok = pcall(elE.prerender, elE)
check("a failed prerender raises and leaves the shared table", not ok and ZeD.T == ZeD._sharedT)

-- a function for the player (one layer that serves every player)
local which = 1
local elF = newEl(nil)
TH.adopt(elF, function() return which end)
seen = {}
drawFrame(elF)
check("adopted with a function: player 2's table", seen[1][2] == P2)
which = 0
seen = {}
drawFrame(elF)
check("the function says the first player: the shared table", seen[1][2] == ZeD.T)
check("ownerPn walks up to a parent's player", TH.ownerPn({ parent = { parent = { playerNum = 2 } } }) == 2
    and TH.ownerPn({}) == 0)

-- ---------------------------------------------------------------------------
section("NESTING: a window's own accent inside the player's switch, a theme applied mid-draw")
-- ---------------------------------------------------------------------------
local WinClass = setmetatable({}, { __index = ZeD_Window })
WinClass.__index = WinClass
function WinClass:prerender() self:_swapAccent(); seen[#seen + 1] = { "pre", ZeD.T, ZeD.T.accent } end
function WinClass:render() seen[#seen + 1] = { "ren", ZeD.T, ZeD.T.accent }; self:_restoreAccent() end
local win = setmetatable({ playerNum = 1, _accentKey = "blue" }, WinClass)
TH.adopt(win)
local P2acc, Sacc = P2.accent, ZeD.T.accent
seen = {}
drawFrame(win, function() seen[#seen + 1] = { "kid", ZeD.T, ZeD.T.accent } end)
local blueL = ZeD.AccentColors.blue.light.accent
check("inside: player 2's table with the window's own accent (Light's blue)",
    seen[1][2] == P2 and same(seen[1][3], blueL) and seen[3][2] == P2 and same(seen[3][3], blueL) and same(seen[4][3], blueL))
check("after: player 2's table has its own accent back", P2.accent == P2acc)
check("after: the shared table untouched and in use", ZeD.T == ZeD._sharedT and ZeD.T.accent == Sacc)

-- a theme applied half way through the draw (the scale settling, a pick from the wheel)
local oldShared = ZeD.T
seen = {}
drawFrame(win, function() ZeD.applyTheme(nil, "green", nil) end)
check("after a mid-draw applyTheme: ZeD.T is the new shared table", ZeD.T == ZeD._sharedT and ZeD.T ~= oldShared)
check("the new shared table keeps its own accent (the window's restore went to the table it swapped)",
    same(ZeD.T.accent, ZeD.AccentColors.green.dark.accent))
check("the old player table got its accent back too", P2.accent == P2acc)
seen = {}
drawFrame(win)
local P2n = ZeD.Tfor(1)
check("next frame: player 2's new table (from the new shared one)", P2n ~= P2 and seen[1][2] == P2n and P2n.px == ZeD.T.px)
check("player 2 keeps Light / Red", P2n.baseKey == "light" and P2n.accentKey == "red")

-- a window of player 2 nested in nothing, drawn by OnPreUIDraw's reset after a failure
ZeD.T = P2n
for _, fn in ipairs(handlers.OnPreUIDraw or {}) do fn() end
check("OnPreUIDraw puts the shared table back", ZeD.T == ZeD._sharedT)

-- ---------------------------------------------------------------------------
section("SAVE: with the character")
-- ---------------------------------------------------------------------------
local md = players[1]._md
check("the pick is on player 2's character", md.ZeD_Theme and md.ZeD_Theme.base == "light"
    and md.ZeD_Theme.accent == "red" and md.ZeD_Theme.own == true)
TH.choice[1] = nil
for _, fn in ipairs(handlers.OnCreatePlayer or {}) do fn(1, players[1]) end
check("OnCreatePlayer brings it back", TH.choice[1] and TH.choice[1].base == "light" and TH.choice[1].accent == "red")
local p1copy = newPlayer()
p1copy._md.ZeD_Theme = { base = "light", accent = "red", size = "small" }   -- the first player's copy, not own
for _, fn in ipairs(handlers.OnCreatePlayer or {}) do fn(1, p1copy) end
check("a character without its own pick follows the first player", TH.choice[1] == nil and ZeD.Tfor(1) == ZeD.T)
for _, fn in ipairs(handlers.OnCreatePlayer or {}) do fn(0, players[1]) end
check("the first player's OnCreatePlayer reads nothing", TH.choice[0] == nil)
local b, a = TH.keysFor(0)
check("keysFor(0): the shared keys", b == ZeD.currentBase and a == ZeD.currentAccent)

-- the readers
local wm = readFile(CDIR .. "ZeD_WindowMenu.lua") or ""
check("the window menu sends a split view player's pick to ZeD.Theme.set", wm:find("ZeD.Theme.set(pn, base, accent)", 1, true) ~= nil)
local dw = readFile(CDIR .. "ZeD_DpadWheels.lua") or ""
check("the Select wheel passes the pad's player", dw:find("run = function() Z.theme(k, nil, nil, pn) end", 1, true) ~= nil)

print("player_theme_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
