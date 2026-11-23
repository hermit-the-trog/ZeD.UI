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
-- (Nov 14 2026, punch list 211: ZeD's clicks go through ZeD.uiSound, shared/ZeD/Tokens.lua; at Full it is playUISound)
ZeD.uiSound = function(n) return getSoundManager():playUISound(n) end
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
-- (Nov 22 2026, KISS #45 and #18: the heading also holds a Pick all word button, and the World window's list a Loot all; both
-- are drawn with drawButton, which these stubs keep apart from the view button's picture, and "heading" below takes the
-- Pick all rect out of GV.toggles after checking it, so the view button's checks read as they did)
ZeD.Molecules.buttonW = function(label) return 40 end
local WORD_BUTTONS = {}
ZeD.Molecules.drawButton = function(p, x, y, w, h, label, style, a, b, o) WORD_BUTTONS[#WORD_BUTTONS + 1] = { label = label, id = o and o.id } end
ZeD.ContainerControls = { PAD_X = 8, headLootOn = function() return false end, headLootEnabled = function() return false end, lootAllLabel = function() return "Loot all" end }
local PA = 40 + 6   -- (Pick all's width and its gap)
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
    WORD_BUTTONS = {}
    drawColumnHeading(p, GV, 0, colW, 20, 60, 6, 14, 14)
    for i = #GV.toggles, 1, -1 do
        if GV.toggles[i].view == "all" then
            check("ALL: Pick all is a stamped stop with its own id", GV.toggles[i].id == "view:all:" .. tostring(key) and #WORD_BUTTONS == 1 and WORD_BUTTONS[1].label == "UI_ZeD_Inv_PickAll")
            table.remove(GV.toggles, i)
        end
    end
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
-- (Nov 20 2026, QA's visual noise audit 37: an outline, as the Filter beside it, not the accent's solid square)
check("SHOWS: drawn as an outline (not active), as the Filter", b.active == false)
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
check("SHOWS: still an outline in grid view", b.active == false)
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
    return NAME_ROOM and NAME_ROOM + PA   -- (Pick all took PA of the name's room)
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
    return NAME_ROOM and NAME_ROOM + PA, drawn
end
local NAME_W = #"Inventory" * 7
local room, drawn = narrow(160, "0.0 / 8 kg", "63 items")
check("ROOM narrow: the whole name fits", room and room >= NAME_W, room)
check("ROOM narrow: the count and the weight give way", not drawn["63 items"] and not drawn["0.0 / 8 kg"])
-- (Header order, Nov 22 2026: the drop rule now measures every heading button, Pick all too (PA); the old sum left it
-- out, so 200 kept a weight that cut the name. 200 + PA is the same room the old case meant.)
room, drawn = narrow(200 + PA, "0.0 / 8 kg", "1234567890 items")
check("ROOM narrow: a long count goes first, the name fits", room and room >= NAME_W and not drawn["1234567890 items"], room)
check("ROOM narrow: the weight stays where it leaves the name whole", drawn["0.0 / 8 kg"] == true)
room, drawn = narrow(420, "0.0 / 8 kg", "63 items")
check("ROOM wide: both stay where the name fits", drawn["0.0 / 8 kg"] and drawn["63 items"] and room == 420 - (70 + 30) - 6 - 12, room)

section("ORDER")
-- (Buttons right, the director, Nov 22 2026: "move them to the right, because on any dialogue or in other places,
-- they're always on the right"; Selection in the header, the same day: "Transfer buttons, always in the footer.
-- Selection buttons, always in the header." The heading reads [icon] [name] ... [weight and count] [Pick all, Filter,
-- view], the buttons ending at the heading's right edge less padX; no Take all in any heading.)
local function placed(compact, loot, colW)
    local p3 = mkPanel("Crate", compact, true)
    p3._containerInfo.texture = "tex"
    local at = {}
    function p3:drawText(s, x) at[s] = x end
    local icons = {}
    local saveIcon = ZeD.Atoms.drawIcon
    ZeD.Atoms.drawIcon = function(_, _, x) icons[#icons + 1] = x end
    local saveOn, saveEn = ZeD.ContainerControls.headLootOn, ZeD.ContainerControls.headLootEnabled
    if loot then ZeD.ContainerControls.headLootOn = function() return true end end
    BUTTONS, NAME_ROOM, WORD_BUTTONS = {}, nil, {}
    local G = { key = CRATE, toggles = {}, on = R.isGridKey(CRATE) }
    drawColumnHeading(p3, G, 0, colW or 420, 20, 60, 6, 14, 14)
    ZeD.Atoms.drawIcon = saveIcon
    ZeD.ContainerControls.headLootOn, ZeD.ContainerControls.headLootEnabled = saveOn, saveEn
    return G, at, icons
end
local G1, at1, ic1 = placed(false, true)
local views = {}
for i, r in ipairs(G1.toggles) do views[i] = r.view end
check("ORDER: the buttons left to right: Pick all, Filter, view (no Take all, even where a Take all was on)",
    table.concat(views, ",") == "all,filter,flip", table.concat(views, ","))
local lastR, firstL = 0, 9999
for _, r in ipairs(G1.toggles) do lastR = math.max(lastR, r.x + r.w); firstL = math.min(firstL, r.x) end
check("ORDER: the last button ends at the heading's right less padX", lastR == 420 - 6, lastR)
check("ORDER: the icon at the heading's left (padX)", ic1[1] == 6, ic1[1])
check("ORDER: the name right of the icon", at1["Crate"] and at1["Crate"] > ic1[1], at1["Crate"])
check("ORDER: the weight right-aligned a pad short of the buttons", at1["12.5 / 20"] == firstL - 6 - #"12.5 / 20" * 7, at1["12.5 / 20"])
check("ORDER: the count right-aligned under it", at1["9 items"] == firstL - 6 - #"9 items" * 7, at1["9 items"])
check("ORDER: the name's room ends before the weight stack", NAME_ROOM and at1["Crate"] + NAME_ROOM <= at1["12.5 / 20"], NAME_ROOM)
local G2, at2, ic2 = placed(true, false, 210)
lastR, firstL = 0, 9999
for _, r in ipairs(G2.toggles) do lastR = math.max(lastR, r.x + r.w); firstL = math.min(firstL, r.x) end
check("ORDER compact: the buttons end at the right less padX", lastR == 210 - 6 and G2.toggles[1].view == "all", lastR)
check("ORDER compact: icon, name and weight left of the buttons", ic2[1] == 6 and at2["Crate"] > ic2[1]
    and at2["12.5 / 20"] == 6 and at2["Crate"] + (NAME_ROOM or 0) <= firstL, tostring(ic2[1]) .. " " .. tostring(at2["Crate"]) .. " " .. tostring(at2["12.5 / 20"]))

section("NAME FIRST")
-- (QA's Lite finding, Nov 22 2026: in Lite the World window's heading drew no name. The buttons give way first:
-- Lite's words become the pictures, then the view flip goes, then the Filter, then Pick all; then the weight and count.)
-- QA's widths: Pick all 145, Filter 122, List 154 (Lite words), the column 639 wide (its right edge at 651, 12 in)
do
    local saveW, saveLite = ZeD.Molecules.buttonW, ZeD.Molecules.lite
    local WORDW = { UI_ZeD_Inv_PickAll = 145, UI_ZeD_Inv_Filter = 122, IGUI_CraftingWindow_ListView = 154, UI_ZeD_Inv_GridView = 154 }
    ZeD.Molecules.buttonW = function(label) return WORDW[label] or 40 end
    ZeD.Molecules.lite = function() return true end
    local function liteHead(colW, name)
        local p4 = mkPanel(name or "Kitchen Counter", false, true)
        p4._containerInfo.texture = "tex"
        local at = {}
        function p4:drawText(s, x) at[s] = x end
        BUTTONS, NAME_ROOM, WORD_BUTTONS = {}, nil, {}
        local G = { key = CRATE, toggles = {}, on = false }
        drawColumnHeading(p4, G, 0, colW, 20, 60, 6, 14, 14)
        local v = {}
        for i, r in ipairs(G.toggles) do v[i] = r.view end
        return G.headLevel, table.concat(v, ","), NAME_ROOM, at
    end
    local nameMin = #"Kit..." * 7
    local lvl, v, room = liteHead(639)
    check("NAME FIRST 639 (QA's column): the name keeps a few letters and the dots", room and room >= nameMin, room)
    check("NAME FIRST 639: Lite's words stay where they and the name fit", lvl == 0 and v == "all,filter,flip", tostring(lvl) .. " " .. v)
    -- the steps, widest first, at this sim's sizes (padX 6, icon 14 + 4, 7 px a letter, buttons 24 square)
    local steps, last, bad = {}, nil, nil
    for w = 700, 80, -1 do
        local l, _, r = liteHead(w)
        if l ~= last then steps[#steps + 1] = w .. ":" .. tostring(l); last = l end
        if not bad and not (r and r >= nameMin) then bad = w .. " room " .. tostring(r) end
    end
    print("   Lite heading steps (width:level): " .. table.concat(steps, " "))
    check("NAME FIRST: from 700 down to 80 the name always keeps its few letters", bad == nil, bad)
    local l1, v1 = liteHead(500)
    check("NAME FIRST 500: Lite's words become the pictures first", l1 == 1 and v1 == "all,filter,flip", tostring(l1) .. " " .. v1)
    local l2, v2 = liteHead(270)
    check("NAME FIRST 270: then the view flip goes", l2 == 2 and v2 == "all,filter", tostring(l2) .. " " .. v2)
    local l3, v3 = liteHead(240)
    check("NAME FIRST 240: then the Filter", l3 == 3 and v3 == "all", tostring(l3) .. " " .. v3)
    local l4, v4, r4, at4 = liteHead(150)
    check("NAME FIRST 150: then Pick all", l4 == 4 and v4 == "", tostring(l4) .. " " .. v4)
    check("NAME FIRST 150: the weight and count give way after the buttons", r4 and r4 >= nameMin and not at4["9 items"], r4)
    ZeD.Molecules.buttonW, ZeD.Molecules.lite = saveW, saveLite
end

section("DECK")
-- (QA, Nov 22 2026: at 1280 x 800 the Full heading dropped the name too.) Both windows at UI scale 0.75: the list opens
-- 296 units wide (222 px), its pad 8, the buttons 20 square, letters about 5 px, Pick all's word button 46 px. Full
-- (pictures) and Lite (words: Filter 38, List 32): the name shows, a few letters and the dots at least; the buttons
-- give way first, then the weight and count.
do
    local saveW, saveLite, saveTM, saveBH = ZeD.Molecules.buttonW, ZeD.Molecules.lite, ZeD.TM.MeasureStringX, ZeD.T.buttonH
    local WORDW = { UI_ZeD_Inv_PickAll = 46, UI_ZeD_Inv_Filter = 38, IGUI_CraftingWindow_ListView = 32, UI_ZeD_Inv_GridView = 32 }
    ZeD.Molecules.buttonW = function(label) return WORDW[label] or 40 end
    ZeD.TM.MeasureStringX = function(_, font, s) return #tostring(s) * 5 end
    ZeD.T.buttonH = 20
    for _, win in ipairs({ { "Character", "Inventory", "12.5 / 20", "9 items" }, { "World", "Kitchen Counter", "3.1 / 50", "14 items" } }) do
        for _, lite in ipairs({ false, true }) do
            ZeD.Molecules.lite = function() return lite end
            for _, colW in ipairs({ 222, 180 }) do
                local p5 = mkPanel(win[2], false, true)
                p5._containerInfo.texture = "tex"
                p5._containerInfo.stats, p5._containerInfo.count = win[3], win[4]
                local at = {}
                function p5:drawText(s, x) at[s] = x end
                BUTTONS, NAME_ROOM, WORD_BUTTONS = {}, nil, {}
                local G = { key = CRATE, toggles = {}, on = false }
                drawColumnHeading(p5, G, 0, colW, 15, 45, 8, 11, 11)
                local nameMin = #(win[2]:sub(1, 3) .. "...") * 5
                local lastR = 0
                for _, r in ipairs(G.toggles) do lastR = math.max(lastR, r.x + r.w) end
                check("DECK " .. win[1] .. (lite and " Lite " or " Full ") .. colW .. " px: the name shows (a few letters and the dots at least)",
                    NAME_ROOM and NAME_ROOM >= nameMin and lastR <= colW - 8,
                    tostring(NAME_ROOM) .. " room, level " .. tostring(G.headLevel) .. ", buttons end " .. lastR)
            end
        end
    end
    ZeD.Molecules.buttonW, ZeD.Molecules.lite, ZeD.TM.MeasureStringX, ZeD.T.buttonH = saveW, saveLite, saveTM, saveBH
end

section("COLUMN LOOT")
-- (Transfer in the footer, the director, Nov 22 2026: a Loot column's Take all sits in the column's own foot,
-- drawColumnFoot, right-aligned, its stop and press the same "view:lootall:<key>" as before)
do
    local G3 = placed(true, true, 210)
    check("COLUMN LOOT: no Take all in a column's heading", G3.toggles[1] and G3.toggles[1].view == "all")
    local foot = { _ccH = 34, _compactMode = true, _ccSide = "world" }
    function foot:getHeight() return 300 end
    local saveS, saveDiv = ZeD.Surface, ZeD.Atoms.drawDividerH
    ZeD.Surface = { fill = function() end }
    ZeD.Atoms.drawDividerH = function() end
    WORD_BUTTONS = {}
    local GF = { key = CRATE, toggles = {} }
    R.drawColumnFoot(foot, GF, 100, 210)
    ZeD.Surface, ZeD.Atoms.drawDividerH = saveS, saveDiv
    local t = GF.toggles[1]
    check("COLUMN LOOT: the foot holds the column's Take all", t and t.view == "lootall" and t.key == CRATE and t.id == "view:lootall:" .. CRATE
        and WORD_BUTTONS[1] and WORD_BUTTONS[1].label == "Loot all")
    check("COLUMN LOOT: right-aligned in the foot, inside the column's bottom", t and t.x + t.w == 100 + 210 - 8 and t.y >= 300 - 34, t and (t.x + t.w))
    local took = {}
    local saveCC = ZeD.ContainerControls
    ZeD.ContainerControls = setmetatable({
        lootAllFrom = function(po, src, dest) took[#took + 1] = { src = src, dest = dest } return true end,
        otherInventory = function() return "bag on show" end,
    }, { __index = saveCC })
    local savePaused = isGamePaused
    isGamePaused = function() return false end
    local invA, invB = { key = "A" }, { key = "B" }
    local cols = { _playerObj = {}, _inventory = invB, _colStates = { { inventory = invA }, { inventory = invB } } }
    took = {}
    R.lootAllOf(cols, "A")
    check("COLUMN LOOT: the key picks its column's container, not the last one bound", took[1] and took[1].src == invA, took[1] and took[1].src and took[1].src.key)
    check("COLUMN LOOT: into the Character window's bag on show", took[1] and took[1].dest == "bag on show")
    took = {}
    R.onViewZone("view:lootall:A", cols)
    check("COLUMN LOOT: a click on column A's Take all takes from A", took[1] and took[1].src == invA)
    took = {}
    local els = R.toggleElements({ { x = 0, y = 0, w = 40, h = 20, view = "lootall", key = "B" } })
    if els[1] then els[1].onActivate({ _mainContent = cols }, els[1]) end
    check("COLUMN LOOT: A on column B's Take all takes from B", took[1] and took[1].src == invB)
    took = {}
    R.lootAllOf(cols, "nobody")
    check("COLUMN LOOT: a key no column has takes nothing", #took == 0, #took)
    took = {}
    R.lootAllOf({ _playerObj = {}, _inventory = invA, _colStates = { { inventory = invA } } }, "zzz")
    check("COLUMN LOOT: one list takes from its own container", took[1] and took[1].src == invA)
    ZeD.ContainerControls, isGamePaused = saveCC, savePaused
    local CC = readFile("42/media/lua/client/ZeD/ContainerControls.lua")
    local on = CC:match("\nfunction CT%.headLootOn%(.-\nend\n") or ""
    check("COLUMN LOOT: headLootOn is a column's (compact) foot only", on:find("content._compactMode == true", 1, true) ~= nil)
    local en = CC:match("\nfunction CT%.headLootEnabled%(.-\nend\n") or ""
    check("COLUMN LOOT: headLootEnabled asks the column's own container", en:find("content._compactMode", 1, true) ~= nil
        and en:find("isEmptyOrUnwanted", 1, true) ~= nil)
end

section("WINDOWS")
local CW = readFile("42/media/lua/client/ZeD/ZeD_CharacterWindow.lua")
local WW = readFile("42/media/lua/client/ZeD/ZeD_WorldWindow.lua")
local function count(s, pat) return select(2, s:gsub(pat, "")) end
check("WINDOWS: the Character window builds its stops from the renderer's rects (main list and columns)",
    count(CW, "ZeD%.InventoryRenderer%.toggleElements%(") >= 2)
check("WINDOWS: the World window builds its stops from the renderer's rects (main list and columns)",
    count(WW, "ZeD%.InventoryRenderer%.toggleElements%(") >= 2)
check("WINDOWS: both hand a heading click to onViewZone", CW:find("onViewZone(zid, self)", 1, true) ~= nil and WW:find("onViewZone(zid, self)", 1, true) ~= nil)
-- (Nov 15 2026, punch list 245: the same line keeps an open stack's header stop too; 256: and a category's heading)
local KEEP = "(fe.isViewToggle or fe.isStackHead or fe.isCatHead) then keepId = fe.id"
check("WINDOWS: both keep the focus on a view stop across a rebuild", CW:find(KEEP, 1, true) ~= nil
    and WW:find(KEEP, 1, true) ~= nil)
local stale = {}
for _, f in ipairs({ "InventoryRenderer.lua", "ZeD_CharacterWindow.lua", "ZeD_WorldWindow.lua", "Input/FocusManager.lua", "InventoryFilter.lua" }) do
    local s = readFile("42/media/lua/client/ZeD/" .. f)
    if s:find("view:list", 1, true) or s:find("view:grid", 1, true) or s:find('{ "list", "grid" }', 1, true) then stale[#stale + 1] = f end
end
check("WINDOWS: nothing names the old List / Grid stops", #stale == 0, table.concat(stale, ","))

print(string.format("view_toggle_sim: %d checks, %d failed", checks, failed))
os.exit(failed > 0 and 1 or 0)
