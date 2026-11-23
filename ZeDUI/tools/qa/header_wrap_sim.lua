-- ZeDUI/tools/qa/header_wrap_sim.lua  (Nov 22 2026, Build; the director's heading rules that day): the pad loop round a
-- list with no game running. "Transfer buttons, always in the footer. Selection buttons, always in the header." and
-- "move them to the right": the heading holds Pick all, Filter and the view flip at its right end; the footer band
-- (right-aligned) holds the moves, the World window's Take all first, the Character window's Transfer all first; a
-- Loot column has its own foot with its Take all.
-- The real FocusManager.lua and SpatialNav.lua run on Lua 5.1 stubs; the D-pad is read through Focus.previewMove.
--   LOOP     one list: Down past the last row lands on the band's Take all (never To floor or Same type); Up from
--            the first row lands on the heading's Pick all; Up from it reaches the title bar; Up from the title bar
--            (nothing above) wraps on round to the band's first button; Right walks every band button; Down from
--            each band button goes to the list's first row on show; Up from the band goes to the last row on show
--   COLUMNS  a Loot view of two columns: Down past a column's last row lands on that column's own foot Take all
--            (matched by the toggle's key), Up from its first row lands on its own Pick all; no band to wrap to
--   CHAR     the Character window: Down past the last row lands on Transfer all; Up on Pick all; the loop as LOOP
-- Run from the repo root:  lua51 ZeDUI/tools/qa/header_wrap_sim.lua
-- It prints FAIL lines and a last line "header_wrap_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]header_wrap_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

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
-- (a container's key: the renderer's containerKey, here the stub inventory's own name)
ZeD = { Input = {}, InventoryRenderer = { containerKey = function(inv) return inv and inv.k end } }

local okN, errN = pcall(dofile, Z .. "Input/SpatialNav.lua")
check("SpatialNav.lua loads", okN, errN)
local okF, errF = pcall(dofile, Z .. "Input/FocusManager.lua")
check("FocusManager.lua loads", okF, errF)
local Focus = ZeD.Input.Focus

local function panel(x, y, w, h)
    return { getX = function() return x end, getY = function() return y end,
             getWidth = function() return w end, getHeight = function() return h end,
             isVisible = function() return true end }
end

-- the heading's buttons (Pick all, Filter, view) at its right end, panel-local at y 5
local function heading(key, x0)
    local out, x = {}, x0
    for _, b in ipairs({ { "all", 50 }, { "filter", 20 }, { "flip", 20 } }) do
        out[#out + 1] = { id = "view:" .. b[1] .. ":" .. key, isViewToggle = true, view = b[1], key = key,
                          x = x, y = 5, w = b[2], h = 20 }
        x = x + b[2] + 4
    end
    return out
end
-- the title bar's stops: two, the bar's whole width, window-local (WindowHalves.padElements)
local function pins(ww)
    return { { id = "halfpin:inv", x = 0, y = 2, w = math.floor(ww / 2), h = 16 },
             { id = "windowbox", x = math.floor(ww / 2), y = 2, w = ww - math.floor(ww / 2), h = 16 } }
end

-- The World window, one list: the bag strip at the left (x 0..50), the list's panel at x 60 y 30 (300 x 400), 12 rows
-- of 20 under the heading (all on show), the band at the panel's foot (y 340), right-aligned: Take all, Same type,
-- To floor, an object's button.
local BAND = { "take", "same", "floor", "obj:1" }
local function worldWin(opts)
    opts = opts or {}
    local rows = {}
    for i = 1, 12 do
        rows[i] = { id = "invrow:" .. i, item = { n = i }, x = 0, y = 30 + (i - 1) * 20, w = 300, h = 20 }
    end
    for _, e in ipairs(heading("crate", 300 - 6 - 98)) do rows[#rows + 1] = e end
    Focus.markOffscreen(rows, { top = 30, bottom = 330 })
    local band = {}
    for i, k in ipairs(BAND) do band[i] = { id = "worldCtl:" .. k, ccKey = k, x = 300 - 6 - (#BAND - i + 1) * 64, y = 340, w = 60, h = 20 } end
    local strip = {}
    for i = 1, 4 do strip[i] = { id = "strip:" .. i, x = 0, y = (i - 1) * 40, w = 50, h = 36 } end
    return {
        _zedLabel = "world",
        _contentPanel = panel(60, 30, 300, 400),
        _containerStrip = panel(0, 30, 50, 400),
        _focusRing = {
            { zone = "worldTitlePins", focusable = true, elements = pins(360), focusedElementIdx = 1 },
            { zone = "worldContainerStrip", focusable = true, elements = strip, focusedElementIdx = 1 },
            { zone = "worldMainInv", focusable = true, elements = rows, focusedElementIdx = 1 },
            { zone = "worldCtl", focusable = not opts.noBand, elements = band, focusedElementIdx = 1, walkLR = true },
        },
        _focusIdx = 3,
    }
end

-- A Loot view of two columns: worldMC1 (key A, x 0..140) and worldMC2 (key B, x 150..300) in the list's panel; no
-- band; each column's own foot (y 340) holds its Take all at its right end. strayA: column 2's zone also holds a Take
-- all of key A ahead of its own, to prove the match is by key.
local function columnsWin(strayA)
    local invA, invB = { k = "A" }, { k = "B" }
    local function col(slot, key, x0)
        local els = {}
        for i = 1, 6 do
            els[i] = { id = "mc" .. slot .. ":" .. i, item = { n = i }, colIdx = slot, x = x0, y = 30 + (i - 1) * 20, w = 140, h = 20 }
        end
        if strayA and key == "B" then
            els[#els + 1] = { id = "view:lootall:A", isViewToggle = true, view = "lootall", key = "A", x = x0 + 10, y = 340, w = 30, h = 20 }
        end
        els[#els + 1] = { id = "view:lootall:" .. key, isViewToggle = true, view = "lootall", key = key, x = x0 + 80, y = 340, w = 54, h = 20 }
        for _, e in ipairs(heading(key, x0 + 50)) do e.w = math.min(e.w, 26); els[#els + 1] = e end
        return els
    end
    return {
        _zedLabel = "world",
        _contentPanel = panel(60, 30, 300, 400),
        _mainContent = { _colStates = { { inventory = invA }, { inventory = invB } }, _playerObj = {} },
        _focusRing = {
            { zone = "worldTitlePins", focusable = true, elements = pins(360), focusedElementIdx = 1 },
            { zone = "worldMC1", focusable = true, elements = col(1, "A", 0), focusedElementIdx = 1 },
            { zone = "worldMC2", focusable = true, elements = col(2, "B", 150), focusedElementIdx = 1 },
            { zone = "worldCtl", focusable = false, elements = {}, focusedElementIdx = 1, walkLR = true },
        },
        _focusIdx = 2,
    }
end

local function focusOn(w, id)
    for zi, z in ipairs(w._focusRing) do
        for ei, e in ipairs(z.elements) do
            if e.id == id then w._focusIdx = zi; z.focusedElementIdx = ei; return true end
        end
    end
    return false
end
local function go(mk, from, dir)
    local w = mk()
    w._navLast = nil
    if not focusOn(w, from) then return "no stop " .. from end
    local ok, r = pcall(Focus.previewMove, w, dir)
    if not ok then return "threw " .. tostring(r) end
    if r.err then return "dry run threw" end
    return tostring(r.id)
end
local function expect(name, mk, from, dir, want)
    local got = go(mk, from, dir)
    check(name, got == want, got)
end

-- ---------------------------------------------------------------------------
section("LOOP")
-- ---------------------------------------------------------------------------
check("Focus._bandWrap exists", Focus and Focus._bandWrap ~= nil)
expect("last row Down -> the band's Take all", worldWin, "invrow:12", "down", "worldCtl:take")
expect("first row Up -> the heading's Pick all", worldWin, "invrow:1", "up", "view:all:crate")
expect("row 5 Down -> row 6 (no wrap inside the list)", worldWin, "invrow:5", "down", "invrow:6")
local pd = go(worldWin, "view:all:crate", "down")
check("Pick all Down -> a row", pd:sub(1, 7) == "invrow:", pd)
local up = go(worldWin, "view:all:crate", "up")
check("Pick all Up -> the title bar", up == "halfpin:inv" or up == "windowbox", up)
expect("title bar Up (nothing above) -> the band's first button", worldWin, "halfpin:inv", "up", "worldCtl:take")
expect("the window box Up -> the band's first button", worldWin, "windowbox", "up", "worldCtl:take")
-- no Up from a row ever lands on a move (the Filter and the view flip sit nearer some rows: still Pick all)
expect("a row under the view flip Up -> still Pick all", worldWin, "invrow:1", "up", "view:all:crate")
-- every band button: reached by Right along the ribbon, and Down from it goes to the list's first row
for i = 1, #BAND - 1 do
    expect("band " .. BAND[i] .. " Right -> " .. BAND[i + 1], worldWin, "worldCtl:" .. BAND[i], "right", "worldCtl:" .. BAND[i + 1])
end
for _, k in ipairs(BAND) do
    expect("band " .. k .. " Down -> the list's first row", worldWin, "worldCtl:" .. k, "down", "invrow:1")
    expect("band " .. k .. " Up -> the last row on show", worldWin, "worldCtl:" .. k, "up", "invrow:12")
end
-- scrolled: Down from the band lands on the top row on show, not one scrolled out of view above
do
    local function scrolled()
        local w = worldWin()
        for _, e in ipairs(w._focusRing[3].elements) do if e.item then e.y = e.y - 100 end end
        Focus.markOffscreen(w._focusRing[3].elements, { top = 30, bottom = 330 })
        return w
    end
    expect("scrolled: band Down -> the top row on show (row 6)", scrolled, "worldCtl:same", "down", "invrow:6")
    expect("scrolled: the last row on show Down -> the band's Take all", scrolled, "invrow:12", "down", "worldCtl:take")
    -- (QA PAD 3) Up from the band with the heading's Pick all straight above it (both at the right end): still the
    -- list's last row on show, never Pick all
    local function pickAbove()
        local w = scrolled()
        local take, pick
        for _, z in ipairs(w._focusRing) do
            for _, e in ipairs(z.elements or {}) do
                if e.id == "worldCtl:take" or (e.ccKey == "take") then take = take or e end
                if e.isViewToggle and e.view == "all" then pick = e end
            end
        end
        if take and pick then pick.x = take.x end
        return w
    end
    local pu = go(pickAbove, "worldCtl:take", "up")
    check("band Up with Pick all above it -> the last row on show, not Pick all", pu == "invrow:12", pu)
end
-- no band on show (nothing to do with this container): Up from the bar goes nowhere, as before
do
    local w = worldWin({ noBand = true })
    focusOn(w, "halfpin:inv")
    local r = Focus.previewMove(w, "up")
    check("no band: title bar Up goes nowhere", r.id == nil and not r.err, tostring(r.id))
end

-- ---------------------------------------------------------------------------
section("COLUMNS")
-- ---------------------------------------------------------------------------
local cols = function() return columnsWin(false) end
local stray = function() return columnsWin(true) end
expect("column 1 last row Down -> its own foot's Take all", cols, "mc1:6", "down", "view:lootall:A")
expect("column 2 last row Down -> its own foot's Take all", cols, "mc2:6", "down", "view:lootall:B")
expect("column 2 last row Down -> matched by key, not the first Take all in the zone", stray, "mc2:6", "down", "view:lootall:B")
expect("column 1 first row Up -> its own Pick all", cols, "mc1:1", "up", "view:all:A")
expect("column 2 first row Up -> its own Pick all", cols, "mc2:1", "up", "view:all:B")
do
    local w = cols()
    focusOn(w, "halfpin:inv")
    local r = Focus.previewMove(w, "up")
    check("columns (no band): title bar Up goes nowhere", r.id == nil and not r.err, tostring(r.id))
end

-- ---------------------------------------------------------------------------
section("CHAR")
-- ---------------------------------------------------------------------------
-- the Character window: its band's first move is Transfer all; the heading the same Pick all, Filter, view
do
    local function charWin()
        local w = worldWin()
        w._zedLabel = "char"
        local rows = w._focusRing[3]
        rows.zone = "charMainInv"
        local band = w._focusRing[4]
        band.zone = "charCtl"
        local keys = { "xfer", "same", "near", "obj:1" }
        for i, e in ipairs(band.elements) do e.ccKey = keys[i]; e.id = "charCtl:" .. keys[i] end
        w._focusRing[1].zone = "charTitlePins"
        w._focusRing[2].zone = "charContainerStrip"
        return w
    end
    expect("Character: last row Down -> Transfer all", charWin, "invrow:12", "down", "charCtl:xfer")
    expect("Character: first row Up -> Pick all", charWin, "invrow:1", "up", "view:all:crate")
    expect("Character: title bar Up -> the band's first button", charWin, "halfpin:inv", "up", "charCtl:xfer")
    expect("Character: band Down -> the list's first row", charWin, "charCtl:near", "down", "invrow:1")
    expect("Character: Right walks the band", charWin, "charCtl:xfer", "right", "charCtl:same")
end

print = realPrint
print("header_wrap_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
