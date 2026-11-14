-- ZeDUI/tools/qa/view_toggle_sim.lua  (Nov 11 2026, Build): the inventory column heading's view button, with no game
-- running. The director's ruling (Nov 11): the List and Grid buttons are one button; it shows the view you are in (the
-- list's picture in list view, the grid's in grid view), lit in the accent as the chosen button was, and a press flips
-- to the other. From InventoryRenderer.lua it cuts the saved choice (gridStore .. onViewZone), the heading's pad stops
-- (toggleElements) and the heading's draw (drawViewToggle, drawColumnHeading), and runs them on stub panels.
--   ONE      one view button in the heading (with the Filter: the Filter and the view button, two)
--   SHOWS    list view draws the list's picture, grid view the grid's; lit (active) in both; hint and help name the view
--   FLIP     a press (the zone's click) flips to the other view and saves it for that container only; a second flips back
--   PAD      one pad stop per heading (no Filter), its id the same in both views (the focus keeps its place); A flips
--   R3       the controller's R3 flips the container on show the same way
--   ROOM     the heading gives the second button's width back to the name (normal and compact headings, with and
--            without the Filter)
--   WINDOWS  both windows build the stops from the renderer's rects and hand clicks to onViewZone; nothing left in the
--            mod names the old "view:list" / "view:grid" stops
-- Run from the repo root:  lua51 ZeDUI/tools/qa/view_toggle_sim.lua
-- It prints FAIL lines and a last line "view_toggle_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]view_toggle_sim%.lua$", "")

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
    local f = assert(io.open(ROOT .. path, "rb"))
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))
end

-- ---------------------------------------------------------------------------
-- STUBS
-- ---------------------------------------------------------------------------
local SOUNDS = 0
getSoundManager = function() return { playUISound = function() SOUNDS = SOUNDS + 1 end } end
local MD = {}
local PLAYER = { getModData = function() return MD end }
getPlayer = function() return PLAYER end
getSpecificPlayer = function() return PLAYER end
getText = function(k) return k end

local function rgb(r, g, b, a) return { r = r, g = g, b = b, a = a or 1 } end
ZeD = {}
-- (Atoms.lua's: a window's player number, split view)
ZeD.playerNumOf = function(w) local p = w and w._playerObj; return p and p:getPlayerNum() or 0 end
ZeD.T = {
    px = function(n) return n end, buttonH = 24,
    sp = { iconGap = 4 },
    fontF1 = "F1", fontF4 = "F4", fontF5 = "F5",
    toneHi = rgb(1, 1, 1), toneNorm = rgb(0.8, 0.8, 0.8), iconWhite = rgb(1, 1, 1),
}
ZeD.TM = {
    MeasureStringX = function(_, font, s) return #tostring(s) * 7 end,
    getFontHeight = function(_, font) return 14 end,
}
ZeD.tr = function(key) return key end
local NAME_ROOM = nil   -- (the room the heading gave the container's name: truncateText's width)
ZeD.Atoms = {
    mouseIn = function() return false end,
    drawIcon = function() end,
    truncateText = function(s, font, w) NAME_ROOM = w; return s end,
}
local BUTTONS = {}
ZeD.Molecules = {
    drawIconButton = function(p, x, y, size, icon, o)
        BUTTONS[#BUTTONS + 1] = { x = x, y = y, size = size, icon = icon, active = o.active, hint = o.hint, help = o.help, id = o.id }
    end,
}
ZeD.InvFilter = { act = function() end, clear = function() end, active = function() return false end }
ZeD.InventoryRenderer = {}
gpFocusedToggle = function() return nil end
containerKey = function(inv) return inv and inv.key end

-- ---------------------------------------------------------------------------
-- LOAD (the renderer's own code, cut out)
-- ---------------------------------------------------------------------------
local IR = readFile("42/media/lua/client/ZeD/InventoryRenderer.lua")
local function cutChunk(from, to, ret, name)
    local a = IR:find(from, 1, true)
    local b = a and IR:find(to, a, true)
    check("cut " .. name, a ~= nil and b ~= nil)
    return assert(loadstring(IR:sub(a, b - 1) .. "\n" .. ret, name))()
end
cutChunk("local function gridStore(", "-- Double-click a row", "return true", "saved choice")
cutChunk("local function filterOf(w)", "-- is this item the controller's focused element", "return true", "stops")
local drawViewToggle, drawColumnHeading = cutChunk("local _viewOpts = {}", "-- The grid by category",
    "return drawViewToggle, drawColumnHeading", "heading")
local R = ZeD.InventoryRenderer

-- a column panel and its grid state, as renderItemList makes them
local function mkPanel(name, compact, filterShown)
    local p = { _containerInfo = { name = name, stats = "12.5 / 20", count = "9 items" }, _compactMode = compact }
    if filterShown then p._zedFilter = { shown = true, open = false, rects = {} } end
    function p:drawText() end
    return p
end
local function heading(p, key, colW)
    BUTTONS, NAME_ROOM = {}, nil
    local GV = { key = key, toggles = {}, on = R.isGridKey(key) }
    drawColumnHeading(p, GV, 0, colW, 20, 60, 6, 14, 14)
    return GV
end

-- ---------------------------------------------------------------------------
section("ONE / SHOWS")
local BAG, CRATE = "player", "obj:10,20,0:crate"
local p = mkPanel("Large Backpack", false, false)
local GV = heading(p, BAG, 420)
check("ONE: one button in the heading", #BUTTONS == 1, #BUTTONS)
check("ONE: one stamped rect", #GV.toggles == 1, #GV.toggles)
local b = BUTTONS[1]
check("SHOWS: list view (the default) draws the list's picture", b.icon == "view_list", b.icon)
check("SHOWS: lit in the accent (active) as the chosen view", b.active == true)
check("SHOWS: its hint names the view on show", b.hint == "IGUI_CraftingWindow_ListView", b.hint)
check("SHOWS: its help line is the list's (it says a press flips)", b.help == "UI_ZeD_Inv_ListHelp", b.help)
local listId = b.id
check("ONE: its id is the flip stop's", listId == "view:flip:" .. BAG, listId)
local rx = GV.toggles[1].x

section("FLIP (a click)")
R.onViewZone(GV.toggles[1].id, p)
check("FLIP: a click flips the bag to the grid", R.isGridKey(BAG) == true)
check("FLIP: saved in the character's mod data for that container", MD.ZeD_GridViews and MD.ZeD_GridViews[BAG] == true)
check("FLIP: the crate keeps its own (untouched)", MD.ZeD_GridViews[CRATE] == nil and R.isGridKey(CRATE) == false)
check("FLIP: a click sound", SOUNDS == 1, SOUNDS)
GV = heading(p, BAG, 420)
b = BUTTONS[1]
check("SHOWS: grid view draws the grid's picture", #BUTTONS == 1 and b.icon == "view_grid", b.icon)
check("SHOWS: still lit in grid view", b.active == true)
check("SHOWS: hint and help name the grid", b.hint == "UI_ZeD_Inv_GridView" and b.help == "UI_ZeD_Inv_GridHelp", tostring(b.hint) .. " " .. tostring(b.help))
check("SHOWS: the button stays where it was (same x)", GV.toggles[1].x == rx, GV.toggles[1].x .. " vs " .. rx)
check("PAD: the same id in grid view (the focus keeps its place)", b.id == listId, b.id)
R.onViewZone(GV.toggles[1].id, p)
check("FLIP: a second click flips back to the list", R.isGridKey(BAG) == false and MD.ZeD_GridViews[BAG] == false)

section("PAD")
GV = heading(p, CRATE, 420)
local els = R.toggleElements(GV.toggles)
check("PAD: one stop for the heading", #els == 1, #els)
local e = els[1]
check("PAD: the stop is the drawn button (id, place)", e.id == BUTTONS[1].id and e.x == GV.toggles[1].x and e.w == GV.toggles[1].w)
check("PAD: the stop is a view stop (the windows keep focus on it)", e.isViewToggle == true and e.view == "flip")
e.onActivate({}, e)
check("PAD: A flips the crate to the grid", R.isGridKey(CRATE) == true)
check("PAD: the bag is untouched", R.isGridKey(BAG) == false)
e.onActivate({}, e)
check("PAD: A again flips it back", R.isGridKey(CRATE) == false)
local pf = mkPanel("Crate", false, true)
GV = heading(pf, CRATE, 420)
els = R.toggleElements(GV.toggles)
check("PAD: with the Filter, two stops (Filter, view button)", #els == 2 and els[1].view == "filter" and els[2].view == "flip",
    #els .. " " .. tostring(els[1] and els[1].view) .. " " .. tostring(els[2] and els[2].view))

section("R3")
local win = { _mainContent = { _colStates = {} }, _containers = { { inventory = { key = BAG } } }, _activeContainer = 1, _playerObj = PLAYER }
ZeD.Input = { Focus = { getFocusedElement = function() return nil end } }
check("R3: flips the container on show", R.padView(win) == true and R.isGridKey(BAG) == true)
check("R3: and back", R.padView(win) == true and R.isGridKey(BAG) == false)

section("ROOM")
-- the old pair took 2 buttons and a 4-unit gap; the name gets bw + 4 back (bw = buttonH 24 here)
local OLD_EXTRA = 24 + 4
local function nameRoom(compact, filterShown, colW)
    heading(mkPanel("A container with a long name", compact, filterShown), CRATE, colW)
    return NAME_ROOM
end
-- normal heading: name room = colW - (stackW + toggles + padX) - (padX + iconless 0) - padX * 2
local stackW = math.max(#"12.5 / 20" * 7, #"9 items" * 7)
local exp = 420 - (stackW + 24 + 6) - 6 - 6 * 2
local got = nameRoom(false, false, 420)
check("ROOM: normal heading: the name has one button less to clear", got == exp, tostring(got) .. " vs " .. exp)
check("ROOM: that is the second button and its gap given back", got - (exp - OLD_EXTRA) == OLD_EXTRA)
local gotF = nameRoom(false, true, 420)
check("ROOM: with the Filter: Filter + view button only", gotF == exp - (24 + 6), tostring(gotF) .. " vs " .. (exp - 30))
-- compact heading (a column among several): name room = colW - togW - padX - padX
local gotC = nameRoom(true, false, 210)
check("ROOM: compact heading (a narrow column): one button's width", gotC == 210 - (24 + 6) - 6 - 6, gotC)
local gotCF = nameRoom(true, true, 210)
check("ROOM: compact with the Filter", gotCF == 210 - (24 + 6 + 24 + 6) - 6 - 6, gotCF)

-- (QA b12 round 2) a narrow single column at Large text: the Character window's "Inventory" was cut to "Invent..."
-- because the weight and count stack took its room. The stack gives way (the count first, then the weight: the title
-- bar shows the weight, the foot line the count) where it would cut the name; where the name fits it stays.
local function narrow(colW, stats, cnt)
    local p2 = mkPanel("Inventory", false, false)
    p2._containerInfo.stats, p2._containerInfo.count = stats, cnt
    local drawn = {}
    function p2:drawText(s) drawn[s] = true end
    heading(p2, CRATE, colW)
    return NAME_ROOM, drawn
end
local NAME_W = #"Inventory" * 7
local room, drawn = narrow(160, "0.0 / 8 kg", "63 items")
check("ROOM narrow: the whole name fits", room and room >= NAME_W, room)
check("ROOM narrow: the count and the weight give way", not drawn["63 items"] and not drawn["0.0 / 8 kg"])
room, drawn = narrow(200, "0.0 / 8 kg", "1234567890 items")
check("ROOM narrow: a long count goes first, the name fits", room and room >= NAME_W and not drawn["1234567890 items"], room)
check("ROOM narrow: the weight stays where it leaves the name whole", drawn["0.0 / 8 kg"] == true)
room, drawn = narrow(420, "0.0 / 8 kg", "63 items")
check("ROOM wide: both stay where the name fits", drawn["0.0 / 8 kg"] and drawn["63 items"] and room == 420 - (70 + 30) - 6 - 12, room)

section("WINDOWS")
local CW = readFile("42/media/lua/client/ZeD/ZeD_CharacterWindow.lua")
local WW = readFile("42/media/lua/client/ZeD/ZeD_WorldWindow.lua")
local function count(s, pat) return select(2, s:gsub(pat, "")) end
check("WINDOWS: the Character window builds its stops from the renderer's rects (main list and columns)",
    count(CW, "ZeD%.InventoryRenderer%.toggleElements%(") >= 2)
check("WINDOWS: the World window builds its stops from the renderer's rects (main list and columns)",
    count(WW, "ZeD%.InventoryRenderer%.toggleElements%(") >= 2)
check("WINDOWS: both hand a heading click to onViewZone", CW:find("onViewZone(zid, self)", 1, true) ~= nil and WW:find("onViewZone(zid, self)", 1, true) ~= nil)
check("WINDOWS: both keep the focus on a view stop across a rebuild", CW:find("fe.isViewToggle then keepId = fe.id", 1, true) ~= nil
    and WW:find("fe.isViewToggle then keepId = fe.id", 1, true) ~= nil)
local stale = {}
for _, f in ipairs({ "InventoryRenderer.lua", "ZeD_CharacterWindow.lua", "ZeD_WorldWindow.lua", "Input/FocusManager.lua", "InventoryFilter.lua" }) do
    local s = readFile("42/media/lua/client/ZeD/" .. f)
    if s:find("view:list", 1, true) or s:find("view:grid", 1, true) or s:find('{ "list", "grid" }', 1, true) then stale[#stale + 1] = f end
end
check("WINDOWS: nothing names the old List / Grid stops", #stale == 0, table.concat(stale, ","))

print(string.format("view_toggle_sim: %d checks, %d failed", checks, failed))
os.exit(failed > 0 and 1 or 0)
