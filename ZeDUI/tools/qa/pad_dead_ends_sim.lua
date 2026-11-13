-- ZeDUI/tools/qa/pad_dead_ends_sim.lua  (Nov 12 2026, Build): the controller dead ends of the focus map's first
-- strict run (ZeDUI/qa/regression/2026-11-12_smoke_phase2_first_run.md), with no game running. The real
-- FocusManager.lua and SpatialNav.lua run on Lua 5.1 stubs; the D-pad is read through Focus.previewMove, the dry
-- run the QA focus map uses.
--   NEAR    the container buttons under a long list (xfer, same, near). The list's rows scrolled out of view keep
--           their place as stops, on the buttons' line and under it; Right from "same" went to a hidden row, so
--           "Same type, all nearby" could not be reached. Now a row out of view is for its own list's moves only
--           (Focus.markOffscreen, the picker) and the buttons' ribbon walks its own buttons first (zone.walkLR):
--           each fix alone brings near back; Up from the buttons goes to the last row on show; Down from the last
--           row on show still walks into the hidden ones (the list scrolls to them)
--   WIRED   the windows' row builders mark their rows (Character and World, list and columns), the renderer keeps
--           the view, the buttons' zone is a ribbon
--   EXITS   the stops whose own D-pad handler gives back the moves it does not hold say so (dpadExits): Hair and
--           beard's part switch, the skill rows, the doll's slots (both builders)
-- Run from the repo root:  lua51 ZeDUI/tools/qa/pad_dead_ends_sim.lua [old FocusManager.lua]
--   (with an old FocusManager, e.g. from git show HEAD~1:42/media/lua/client/ZeD/Input/FocusManager.lua, NEAR fails)
-- It prints FAIL lines and a last line "pad_dead_ends_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]pad_dead_ends_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"
local FM_PATH = (arg and arg[1]) or (Z .. "Input/FocusManager.lua")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function noop() end
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))
end

-- the engine, as little of it as the two files touch
Events = setmetatable({}, { __index = function(t, k)
    local e = { Add = noop, Remove = noop }
    rawset(t, k, e)
    return e
end })
LuaEventManager = { AddEvent = noop }
triggerEvent = noop
require = noop
getTimestampMs = function() return 100000 end
getSoundManager = function() return { playUISound = noop } end
isDebugEnabled = function() return false end
getCore = function() return { getScreenWidth = function() return 1920 end, getScreenHeight = function() return 1080 end } end
getSpecificPlayer = function() return nil end
getJoypadData = function() return nil end
getMaxActivePlayers = function() return 4 end
JoypadState = { players = {}, joypads = {}, controllers = {} }
local realPrint = print
print = function(s) if type(s) == "string" and s:sub(1, 5) == "[ZeD." then return end realPrint(s) end
ZeD = { Input = {} }

local okN, errN = pcall(dofile, Z .. "Input/SpatialNav.lua")
check("SpatialNav.lua loads", okN, errN)
local okF, errF = pcall(dofile, FM_PATH)
check("FocusManager.lua loads", okF, errF)
local Focus = ZeD.Input.Focus

local function panel(x, y, w, h)
    return { getX = function() return x end, getY = function() return y end,
             getWidth = function() return w end, getHeight = function() return h end,
             isVisible = function() return true end }
end

-- The Character window's Loot list as the first strict run had it: 29 rows of 20, the list's view 30..330 in the
-- content panel (rows 1..15 on show), the three buttons under it at y 340, rows 16 and 17 behind them, the
-- container column to the right. scroll = how far the list is scrolled (rows above the view then sit above 30).
local VIEW = { top = 30, bottom = 330 }
local function makeWin(opts)
    local scroll = opts.scroll or 0
    local rows = {}
    for i = 1, 29 do
        rows[i] = { id = "invrow:" .. i, item = { n = i }, x = 0, y = 30 + (i - 1) * 20 - scroll, w = 200, h = 20 }
    end
    rows[#rows + 1] = { id = "view:list:grid", isViewToggle = true, x = 150, y = 5, w = 40, h = 20 }
    if opts.mark then Focus.markOffscreen(rows, VIEW) end
    local band = {
        { id = "charCtl:xfer", x = 0,   y = 340, w = 60, h = 20 },
        { id = "charCtl:same", x = 64,  y = 340, w = 60, h = 20 },
        { id = "charCtl:near", x = 128, y = 340, w = 60, h = 20 },
    }
    local strip = { { id = "strip:main", x = 0, y = 0, w = 40, h = 400 } }
    local w = {
        _zedLabel = "char",
        _contentPanel = panel(300, 40, 220, 400),
        _containerStrip = panel(530, 40, 40, 400),
        _focusRing = {
            { zone = "charMainInv", focusable = true, elements = rows, focusedElementIdx = 1 },
            { zone = "charCtl", focusable = true, elements = band, focusedElementIdx = 1, walkLR = opts.walkLR },
            { zone = "charContainerStrip", focusable = true, elements = strip, focusedElementIdx = 1 },
        },
        _focusIdx = 1,
    }
    return w
end
local function focusOn(w, id)
    for zi, z in ipairs(w._focusRing) do
        for ei, e in ipairs(z.elements) do
            if e.id == id then w._focusIdx = zi; z.focusedElementIdx = ei; return true end
        end
    end
    return false
end
local function go(w, from, dir)
    w._navLast = nil
    if not focusOn(w, from) then return "no stop " .. from end
    local ok, r = pcall(Focus.previewMove, w, dir)
    if not ok then return "threw " .. tostring(r) end
    if r.err then return "dry run threw" end
    return tostring(r.id)
end

-- ---------------------------------------------------------------------------
section("NEAR")
-- ---------------------------------------------------------------------------
if Focus and Focus.previewMove then
    -- markOffscreen: rows out of the view, nothing else
    if Focus.markOffscreen then
        local w = makeWin({ mark = true })
        local rows = w._focusRing[1].elements
        local hidden, shown = {}, {}
        for i = 1, 29 do if rows[i].offscreen then hidden[#hidden + 1] = i else shown[#shown + 1] = i end end
        check("markOffscreen: rows 16..29 out of view", #hidden == 14 and hidden[1] == 16 and hidden[14] == 29, table.concat(hidden, ","))
        check("markOffscreen: rows 1..15 on show", #shown == 15 and shown[15] == 15, table.concat(shown, ","))
        check("markOffscreen: the view button is no row", rows[30].offscreen == nil)
        local ws = makeWin({ mark = true, scroll = 200 })
        local r2 = ws._focusRing[1].elements
        check("markOffscreen: scrolled down, the rows above the view (1..10) are out of it",
            r2[10].offscreen and not r2[11].offscreen and r2[25].offscreen == nil and r2[26].offscreen)
    else
        check("Focus.markOffscreen exists", false)
    end

    -- the move the first strict run found (both fixes in, as the game has them)
    local both = function() return makeWin({ mark = Focus.markOffscreen ~= nil, walkLR = true }) end
    check("same Right -> near (the island)", go(both(), "charCtl:same", "right") == "charCtl:near", go(both(), "charCtl:same", "right"))
    check("xfer Right -> same", go(both(), "charCtl:xfer", "right") == "charCtl:same", go(both(), "charCtl:xfer", "right"))
    check("near Left -> same", go(both(), "charCtl:near", "left") == "charCtl:same", go(both(), "charCtl:near", "left"))
    check("near Right -> the container column (past the ribbon's end)", go(both(), "charCtl:near", "right") == "strip:main", go(both(), "charCtl:near", "right"))
    check("same Up -> the last row on show, not one behind the buttons", go(both(), "charCtl:same", "up") == "invrow:15", go(both(), "charCtl:same", "up"))
    check("row 15 Down -> row 16 (its own list walks on into the hidden rows)", go(both(), "invrow:15", "down") == "invrow:16", go(both(), "invrow:15", "down"))
    check("row 16 Up -> row 15", go(both(), "invrow:16", "up") == "invrow:15", go(both(), "invrow:16", "up"))

    -- each fix alone brings near back
    local onlyOff = function() return makeWin({ mark = Focus.markOffscreen ~= nil }) end
    check("rows out of view alone: same Right -> near", go(onlyOff(), "charCtl:same", "right") == "charCtl:near", go(onlyOff(), "charCtl:same", "right"))
    check("rows out of view alone: xfer Right -> same", go(onlyOff(), "charCtl:xfer", "right") == "charCtl:same", go(onlyOff(), "charCtl:xfer", "right"))
    local onlyWalk = function() return makeWin({ walkLR = true }) end
    check("the ribbon alone: same Right -> near", go(onlyWalk(), "charCtl:same", "right") == "charCtl:near", go(onlyWalk(), "charCtl:same", "right"))

    -- scrolled down: the rows above the view never take a move from another zone; the strip's Left goes to a row on show
    local sc = function() return makeWin({ mark = Focus.markOffscreen ~= nil, walkLR = true, scroll = 200 }) end
    local sl = go(sc(), "strip:main", "left")
    local n = tonumber(sl:match("^invrow:(%d+)$") or "")
    check("scrolled: the column's Left lands on a row on show", n ~= nil and n >= 11 and n <= 25, sl)
else
    check("Focus.previewMove exists", false)
end

-- ---------------------------------------------------------------------------
section("WIRED")
-- ---------------------------------------------------------------------------
do
    local cw = readFile(Z .. "ZeD_CharacterWindow.lua") or ""
    local ww = readFile(Z .. "ZeD_WorldWindow.lua") or ""
    local ir = readFile(Z .. "InventoryRenderer.lua") or ""
    local cc = readFile(Z .. "ContainerControls.lua") or ""
    local function count(s, pat) local n = 0; for _ in s:gmatch(pat) do n = n + 1 end; return n end
    check("Character: the list and its columns mark their rows",
        cw:find("markOffscreen(elements, c._rowView)", 1, true) ~= nil and cw:find("markOffscreen(elements, cs.rowView)", 1, true) ~= nil)
    check("World: the list and its columns mark their rows",
        ww:find("markOffscreen(elements, c._rowView)", 1, true) ~= nil and ww:find("markOffscreen(elements, cs.rowView)", 1, true) ~= nil)
    check("the renderer keeps the rows' view", ir:find("self._rowView = rv", 1, true) ~= nil and ir:find("cs.rowView.top, cs.rowView.bottom", 1, true) ~= nil)
    check("both windows rebuild the rows when the view changes", count(cw, "snap%.vb ==") == 1 and count(ww, "snap%.vb ==") == 1
        and count(cw, "_rowView and self%._rowView%.bottom") == 1 and count(ww, "_rowView and self%._rowView%.bottom") == 1)
    local sync = cc:match("\nfunction CT%.syncFocus%(.-\nend\n") or ""
    check("the container buttons' zone is a ribbon", sync:find("zone.walkLR = true", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
section("EXITS")
-- ---------------------------------------------------------------------------
do
    local cw = readFile(Z .. "ZeD_CharacterWindow.lua") or ""
    local hb = readFile(Z .. "ZeD_HairBeard.lua") or ""
    check("Hair and beard: the part switch says dpadExits", hb:find('id = "hb:part",%s*\n%s*dpadExits = true') ~= nil)
    check("the skill rows say dpadExits", cw:find("onDpadDir = _skillRowOnDpadDir,%s*\n%s*dpadExits = true") ~= nil)
    local n = 0
    for _ in cw:gmatch("onDpadDir = _equipDollDpad,%s*\n%s*dpadExits = true") do n = n + 1 end
    check("the doll's slots say dpadExits (both builders)", n == 2, n)
    -- and the dry run hands it on
    if Focus and Focus.previewMove then
        local w = { _zedLabel = "x", _focusIdx = 1, _focusRing = { { zone = "z", focusable = true, focusedElementIdx = 1,
            elements = { { id = "a", x = 0, y = 0, w = 10, h = 10, dpadExits = true, onDpadDir = function() return false end },
                         { id = "b", x = 20, y = 0, w = 10, h = 10 } } } } }
        local r = Focus.previewMove(w, "right")
        check("previewMove: custom and dpadExits, then the fall-through pick", r.custom and r.dpadExits and r.id == "b", tostring(r.id))
    end
end

print = realPrint
print("pad_dead_ends_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
