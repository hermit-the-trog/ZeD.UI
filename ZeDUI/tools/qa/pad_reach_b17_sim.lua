-- ZeDUI/tools/qa/pad_reach_b17_sim.lua  (Nov 16 2026, Build): the beta 17 reach audit's items 253, 255, 256, 259 and
-- 260 (PUNCH_LIST.md), with no game running. Each part runs the real functions, cut out of their files, on Lua 5.1
-- stubs.
--   SORT    255: L3 on a list's sort: a second press reverses it (as a second header click does), the press after
--           goes on to the next column, A-Z first; a column's own sort as the window's
--   CATS    256: a category's heading is a controller stop (InventoryRenderer.catElements): A folds and opens it, its
--           prompt says which, the list's scroll follows its place, a rebuild keeps the focus on it; both windows'
--           builders make the stops (every category folded too), the renderer stamps the headings' places
--   ZONES   253: an animal zone's rename and remove by pad (AnimalsTab: AT.zoneAct, AT.zoneStops): Rename opens the
--           keyboard and lands on Save, Save and Cancel come back where the player started, Remove lands on Cancel
--           (the safe answer), B on the rename or the question is Cancel; from a zone's card (its menu) the page goes
--           back to the overview and the card; the zone's menu is on the card (X, right-click) and the zone's name
--   ORDER   259: the load order's pane scrolls as one unit: every button is made (the last one too, below the foot),
--           the wheel and the pad's follow bring it into view, a new pick starts at the top
--   FOLDERS 260: the Workshop's folder list scrolls: every folder is a stop, the list follows the pad, the wheel
--           scrolls it, only the rows in sight take a press
-- Run from the repo root:  lua51 ZeDUI/tools/qa/pad_reach_b17_sim.lua
-- It prints FAIL lines and a last line "pad_reach_b17_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]pad_reach_b17_sim%.lua$", "")
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
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))
end
-- the text from the line that starts with `from` to the "end" at column 0 after the line that starts with `to`
local function cut(src, from, to)
    local a = src and src:find("\n" .. from, 1, true)
    if not a then return nil end
    local b = src:find("\n" .. (to or from), a, true)
    if not b then return nil end
    local e = src:find("\nend\n", b + 1, true)
    if not e then return nil end
    return src:sub(a + 1, e + 4)
end
local function load(name, upNames, body, ...)
    if not body then check(name .. ": found in its file", false); return nil end
    local fn, err = loadstring("local " .. upNames .. " = ...\n" .. body, name)
    if not fn then check(name .. ": compiles", false, err); return nil end
    local ok, e2 = pcall(fn, ...)
    if not ok then check(name .. ": runs", false, e2); return nil end
    return true
end

local IR_SRC = readFile(Z .. "InventoryRenderer.lua")
local CW_SRC = readFile(Z .. "ZeD_CharacterWindow.lua")
local WW_SRC = readFile(Z .. "ZeD_WorldWindow.lua")
local GL_SRC = readFile(Z .. "GridLayout.lua")
local AT_SRC = readFile(Z .. "AnimalsTab.lua")
local MO_SRC = readFile(Z .. "ZeD_MainMenuModsOrder.lua")
local WS_SRC = readFile(Z .. "ZeD_MainMenuWorkshop.lua")

-- the shared stubs
local words = {}
ZeD = {
    T = { px = function(n) return n end, rowH = 26, sp = { catHdrH = 22, scrollbarW = 10 }, buttonH = 24, fontF1 = 1, fontF2 = 2,
          fontF3 = 3, fontF4 = 4, textDim = {}, text = {}, accent = {}, border = {}, borderS = {}, textHead = {}, textOnFocus = {},
          positive = {}, scale = 1 },
    tr = function(k) words[#words + 1] = k; return k end,
    uiSound = noop,
    InventoryRenderer = {},
    Input = { Focus = {} },
}

-- ---------------------------------------------------------------------------
section("SORT")
local IR = ZeD.InventoryRenderer
local padFocus = nil
ZeD.Input.Focus.getFocusedElement = function() return padFocus end
local sortOk = load("padSort", "SORT_COLS", (cut(IR_SRC, "local function padList(") or "") .. (cut(IR_SRC, "function ZeD.InventoryRenderer.padSort(") or ""),
    { "name", "cat", "cond", "wt" })
if sortOk then
    local scrolled = 0
    local sc = { setScrollPos = function() scrolled = scrolled + 1 end }
    local cnt = { _sortCol = "name", _sortAsc = true, _scroll = sc }
    local win = { _mainContent = cnt }
    local seen = {}
    for i = 1, 9 do
        IR.padSort(win)
        seen[i] = cnt._sortCol .. (cnt._sortAsc and "+" or "-")
    end
    local want = { "name-", "cat+", "cat-", "cond+", "cond-", "wt+", "wt-", "name+", "name-" }
    check("SORT: L3 on Name A-Z reverses it first (the mouse's second click)", seen[1] == "name-", seen[1])
    check("SORT: the press after goes on to the next column, A-Z first", seen[2] == "cat+", seen[2])
    local all = true
    for i = 1, #want do if seen[i] ~= want[i] then all = false end end
    check("SORT: every column both ways, round again", all, table.concat(seen, " "))
    check("SORT: the list goes back to its top on each press", scrolled == 9, scrolled)
    -- a column of its own (a Loot column the pad is on)
    local cs = { sortCol = "wt", sortAsc = false, scroll = sc }
    local winCol, winAsc = cnt._sortCol, cnt._sortAsc
    cnt._colStates = { cs }
    padFocus = { colIdx = 1 }
    IR.padSort(win)
    check("SORT: a column's Z-A goes on to the next column (round to Name), A-Z", cs.sortCol == "name" and cs.sortAsc == true, tostring(cs.sortCol) .. tostring(cs.sortAsc))
    IR.padSort(win)
    check("SORT: a column's second press reverses its own sort, the window's untouched",
        cs.sortCol == "name" and cs.sortAsc == false and cnt._sortCol == winCol and cnt._sortAsc == winAsc)
    -- a sort set by a mouse header click to Z-A: L3 goes on (no third state)
    cnt._colStates, padFocus = nil, nil
    cnt._sortCol, cnt._sortAsc = "cond", false
    IR.padSort(win)
    check("SORT: after the mouse's Z-A, L3 goes on to the next column A-Z", cnt._sortCol == "wt" and cnt._sortAsc == true)
end

-- ---------------------------------------------------------------------------
section("CATS")
IR.padCancel, IR.padPromptB = function() return false end, function() return nil end
local catOk = load("catElements", "_x", cut(IR_SRC, "local function catFolds(", "function ZeD.InventoryRenderer.catElements("), nil)
local keepOk = load("keepToggleIdx", "_x", cut(IR_SRC, "function ZeD.InventoryRenderer.keepToggleIdx("), nil)
if catOk then
    local yMap = { ["cat:Food"] = 100, ["cat:Tools"] = 300 }
    local rowA, rowB = {}, {}
    local groups = { Food = { rowA, rowB }, Tools = {}, Junk = {} }
    local view = { top = 50, bottom = 250 }
    local els = IR.catElements({ "Food", "Tools", "Junk" }, groups, yMap, 0, 200, view, nil, nil, "INV")
    check("CATS: a stop for each heading drawn this frame (none for one with no place)", #els == 2, #els)
    local food, tools = els[1], els[2]
    check("CATS: the heading's stop says what it is, where, and its first row",
        food and food.isCatHead and food.cat == "Food" and food.y == 100 and food.h == 22 and food.rep == rowA and food.catInv == "INV")
    check("CATS: a heading out of the list's view is a stop for its own list's moves only",
        tools and tools.offscreen == true and food.offscreen == nil)
    -- the window: the main list (no column)
    local cnt = { _collapsedGroups = {} }
    local w = { _mainContent = cnt }
    food.onFocus(w, food)
    check("CATS: on focus the list's scroll follows the heading's place", cnt._gpFocusedRowItem == "cat:Food", cnt._gpFocusedRowItem)
    check("CATS: on focus the window remembers the category's first row", w._gpFocusedRowItem == rowA)
    check("CATS: A's prompt is Fold while the category is open", food.promptA(w, food) == "UI_ZeD_Prompt_Fold")
    food.onActivate(w, food)
    check("CATS: A folds the category (the mouse's table)", cnt._collapsedGroups.Food == true)
    check("CATS: A's prompt is Unfold while it is folded", food.promptA(w, food) == "UI_ZeD_Prompt_Unfold")
    food.onActivate(w, food)
    check("CATS: A again opens it", cnt._collapsedGroups.Food == nil)
    -- a Loot column's heading folds that column's category only
    local cs = { collapsedGroups = {} }
    cnt._colStates = { cs }
    local cel = IR.catElements({ "Food" }, groups, yMap, 40, 160, nil, 1, 3, "CRATE")[1]
    check("CATS: a column's stop carries its column and container", cel.colIdx == 1 and cel.mcSlot == 1 and cel.containerIdx == 3 and cel.id == "cathead:1:Food")
    cel.onActivate(w, cel)
    check("CATS: A on a column's heading folds that column's category, not the window's", cs.collapsedGroups.Food == true and cnt._collapsedGroups.Food == nil)
    cel.onFocus(w, cel)
    check("CATS: a column's heading names its column for the zone's rebuild", w._gpFocusedMCItem == rowA and w._gpFocusedMCColIdx == 1)
    if keepOk then
        local ring = { { zone = "worldMC1", elements = { { id = "mcrow:1:1" }, cel }, focusedElementIdx = 2 } }
        local rebuilt = { { id = "mcrow:1:1", item = rowA }, { id = "cathead:1:Food", isCatHead = true } }
        check("CATS: a rebuild of the column keeps the focus on the heading (folding it rebuilds the rows)",
            IR.keepToggleIdx({ _focusRing = ring }, "worldMC1", rebuilt, 1) == 2)
    end
end
-- the wiring in the windows and the renderer
local function count(s, pat) return select(2, (s or ""):gsub(pat, "")) end
check("CATS: the Character window builds heading stops (main list, columns, every category folded)",
    count(CW_SRC, "ZeD%.InventoryRenderer%.catElements%(") >= 3)
check("CATS: the World window builds heading stops (main list, columns, every category folded)",
    count(WW_SRC, "ZeD%.InventoryRenderer%.catElements%(") >= 3)
local KEEP = "(fe.isViewToggle or fe.isStackHead or fe.isCatHead) then keepId = fe.id"
check("CATS: both windows keep the focus on a heading across a rebuild", (CW_SRC or ""):find(KEEP, 1, true) ~= nil and (WW_SRC or ""):find(KEEP, 1, true) ~= nil)
check("CATS: the list stamps each heading's place before its cull", (IR_SRC or ""):find('itemRenderYMap["cat:" .. cat] = y', 1, true) ~= nil)
check("CATS: the grid by category stamps them too", (IR_SRC or ""):find('GV.ymap["cat:" .. cat] = y', 1, true) ~= nil)
check("CATS: an add-on's grid layout stamps them too", (GL_SRC or ""):find('GV.ymap["cat:" .. hd.cat] = y', 1, true) ~= nil)
check("CATS: a column keeps its headings for its stops (one and several columns)", count(IR_SRC, "cs%.catHeads%s+= self%._useGroups and self%._catOrder") == 2)
check("CATS: the heading draws the pad's mark", (IR_SRC or ""):find("o.focus = gpFocusedCat(cat, self._inventory", 1, true) ~= nil)

-- ---------------------------------------------------------------------------
section("ZONES")
local AT = {}
local S = { view = "zone", zoneName = "Pen", submode = "ranch" }
local log = {}
local function rec(s) return function() log[#log + 1] = s end end
local win = {}
local function getState() return S end
local function renameZone(w) w._animalsRenaming = true; log[#log + 1] = "renameZone" end
local function renameKeyboard() log[#log + 1] = "keyboard"; return true end
local function commitRename(w) w._animalsRenaming = false; S.zoneName = "Barn"; log[#log + 1] = "commit" end
local function cancelRename(w) w._animalsRenaming = false; log[#log + 1] = "cancelRename" end
local function removeZone(w) w._animalsRemoveConfirm = true end
local function cancelRemoveZone(w) w._animalsRemoveConfirm = false end
local function confirmRemoveZone(w) w._animalsRemoveConfirm = false; S.view = "overview"; log[#log + 1] = "removed" end
local function navigateBack() S.view = "overview"; S.zoneName = nil end
local function zoneStop(id) return "animals:zone:" .. tostring(id) end
local zOk = load("zoneAct", "AT, getState, renameZone, renameKeyboard, resetRename, commitRename, cancelRename, removeZone, cancelRemoveZone, confirmRemoveZone, navigateBack, zoneStop",
    cut(AT_SRC, "local function zoneReturn(", "function AT.zoneStops("),
    AT, getState, renameZone, renameKeyboard, rec("reset"), commitRename, cancelRename, removeZone, cancelRemoveZone, confirmRemoveZone, navigateBack, zoneStop)
local function ids(els) local t = {} for i, e in ipairs(els) do t[i] = e.id end return table.concat(t, " ") end
local function byId(els, id) for _, e in ipairs(els) do if e.id == "animals:zone:" .. id then return e end end end
if zOk then
    local R = function(x, y) return { x = x, y = y, w = 40, h = 20 } end
    win._animalsZoneNameZone = { x = 10, y = 40, w = 60, h = 14, sx = 110, sy = 155 }
    win._animalsZoneRenameBtn, win._animalsZoneRemoveBtn = R(300, 500), R(350, 500)
    local els = AT.zoneStops(win)
    check("ZONES: the zone page has stops for its name, Rename and Remove zone", ids(els) == "animals:zone:name animals:zone:rename animals:zone:remove", ids(els))
    local menus = {}
    AT.zoneMenu = function(w, name, sx, sy, pad, from) menus[#menus + 1] = { name, sx, sy, pad, from } end
    byId(els, "name").onContextMenu(win, byId(els, "name"))
    check("ZONES: X on the zone's name opens the zone's menu by pad, under the name, coming back to the name",
        menus[1] and menus[1][1] == "Pen" and menus[1][2] == 110 and menus[1][4] == true and menus[1][5] == "animals:zone:name")
    -- Rename by pad: the keyboard, then Save; Save comes back to Rename
    log = {}
    byId(els, "rename").onActivate(win, byId(els, "rename"))
    check("ZONES: A on Rename starts the rename and opens the controller's keyboard", win._animalsRenaming and log[1] == "renameZone" and log[2] == "keyboard", table.concat(log, ","))
    check("ZONES: and lands on Save", win._animalsNavFocusTarget == "animals:zone:save", win._animalsNavFocusTarget)
    win._animalsRenameFieldZone, win._animalsRenameResetBtn, win._animalsRenameCancelBtn, win._animalsRenameSaveBtn = R(10, 38), R(200, 500), R(250, 500), R(300, 500)
    els = AT.zoneStops(win)
    check("ZONES: during the rename: its box, Reset, Cancel and Save", ids(els) == "animals:zone:field animals:zone:reset animals:zone:cancel animals:zone:save", ids(els))
    check("ZONES: A on the box says it types", byId(els, "field").promptA == "UI_ZeD_Inv_PromptType")
    log = {}
    byId(els, "field").onActivate(win, byId(els, "field"))
    check("ZONES: A on the box opens the keyboard again", log[1] == "keyboard", table.concat(log, ","))
    byId(els, "reset").onActivate(win, byId(els, "reset"))
    check("ZONES: A on Reset gives the box the zone's first name", log[2] == "reset" and win._animalsRenaming)
    byId(els, "save").onActivate(win, byId(els, "save"))
    check("ZONES: A on Save renames and comes back to Rename", log[3] == "commit" and not win._animalsRenaming and win._animalsNavFocusTarget == "animals:zone:rename", win._animalsNavFocusTarget)
    -- B on the rename is Cancel; started from the name, it comes back to the name
    win._animalsNavFocusTarget = nil
    AT.zoneAct(win, "name", true)
    els = AT.zoneStops(win)
    check("ZONES: B on the rename's box is Cancel (a prompt says so)", byId(els, "field").onCancel ~= nil and byId(els, "field").promptB == "UI_Cancel")
    log = {}
    local took = byId(els, "save").onCancel(win)
    check("ZONES: B cancels the rename and comes back to the zone's name", took == true and log[1] == "cancelRename" and win._animalsNavFocusTarget == "animals:zone:name", win._animalsNavFocusTarget)
    -- Remove: lands on Cancel; Cancel and B come back to Remove; Remove removes
    win._animalsRemoveNo, win._animalsRemoveYes = R(250, 500), R(300, 500)
    els = AT.zoneStops(win)
    byId(els, "remove").onActivate(win, byId(els, "remove"))
    check("ZONES: A on Remove zone asks and lands on Cancel, the safe answer", win._animalsRemoveConfirm and win._animalsNavFocusTarget == "animals:zone:no", win._animalsNavFocusTarget)
    els = AT.zoneStops(win)
    check("ZONES: the question's Cancel and Remove are stops", ids(els) == "animals:zone:no animals:zone:yes", ids(els))
    byId(els, "no").onActivate(win, byId(els, "no"))
    check("ZONES: Cancel keeps the zone and comes back to Remove zone", not win._animalsRemoveConfirm and win._animalsNavFocusTarget == "animals:zone:remove")
    AT.zoneAct(win, "remove", true)
    els = AT.zoneStops(win)
    byId(els, "yes").onCancel(win)
    check("ZONES: B on the question is Cancel too", not win._animalsRemoveConfirm and win._animalsNavFocusTarget == "animals:zone:remove")
    AT.zoneAct(win, "remove", true)
    log = {}
    els = AT.zoneStops(win)
    byId(els, "yes").onActivate(win, byId(els, "yes"))
    check("ZONES: Remove removes the zone", log[1] == "removed")
    -- from a zone's card on the overview (its menu): the page goes back and lands on the card, under its new name
    S.view, S.zoneName = "zone", "Pen"
    win._animalsNavFocusTarget = nil
    AT.zoneAct(win, "rename", true, "animals:zonecard:Pen")
    AT.zoneAct(win, "save", true)
    check("ZONES: renamed from the card's menu, Save goes back to the overview and lands on the card (its new name)",
        S.view == "overview" and win._animalsNavFocusTarget == "animals:zonecard:Barn", tostring(S.view) .. " " .. tostring(win._animalsNavFocusTarget))
    S.view, S.zoneName = "zone", "Pen"
    AT.zoneAct(win, "remove", true, "animals:zonecard:Pen")
    AT.zoneAct(win, "no", true)
    check("ZONES: a Cancel on the question from the card's menu goes back to the card",
        S.view == "overview" and win._animalsNavFocusTarget == "animals:zonecard:Pen", tostring(win._animalsNavFocusTarget))
    -- the mouse: no landing
    S.view, S.zoneName = "zone", "Pen"
    win._animalsNavFocusTarget = nil
    AT.zoneAct(win, "remove", false)
    check("ZONES: by the mouse nothing moves the pad's focus", win._animalsNavFocusTarget == nil)
    AT.zoneAct(win, "no", false)
    -- no zone page: no stops, no acts
    S.view = "overview"
    check("ZONES: no zone on show: no zone stops and the acts do nothing", #AT.zoneStops(win) == 0 and AT.zoneAct(win, "rename", true) == false)
end
check("ZONES: the World window's Animals stops take the zone's own (AT.zoneStops)", (WW_SRC or ""):find("AT.zoneStops(win)", 1, true) ~= nil)
check("ZONES: X on a zone's card opens its menu", (WW_SRC or ""):find("AT.zoneMenu(w, el.zoneName, el.sx, el.sy, true, el.id)", 1, true) ~= nil)
check("ZONES: a right-click on a zone's card or name opens its menu", (cut(AT_SRC, "function ZeD.AnimalsTab.onRightClick(") or ""):find("AT.zoneMenu", 1, true) ~= nil)
check("ZONES: the bands draw the pad's mark on Rename, Remove, Save, Cancel, Reset and the question's answers",
    (AT_SRC or ""):find("focus = focusFor(win, zoneStop(v.id))", 1, true) ~= nil and (AT_SRC or ""):find('focusFor(win, zoneStop("save"))', 1, true) ~= nil
    and (AT_SRC or ""):find('cancelFocus = focusFor(win, zoneStop("no"))', 1, true) ~= nil)

-- ---------------------------------------------------------------------------
section("ORDER")
ZeD_MMMods = {}
local baseWheel, baseJoy = 0, 0
function ZeD_MMMods:wheel() baseWheel = baseWheel + 1; return false end
function ZeD_MMMods:joyDir() baseJoy = baseJoy + 1 end
local MM = {
    fontH = function() return 14 end, textW = function(_, s) return #tostring(s) * 6 end,
    scrollBar = function(p, key, x, y, w, h, scroll, total, set) p._bar = { key = key, scroll = scroll, total = total, set = set } end,
    paneView = function(key, vy, vh, off, contentH, set) return { key = key, y = vy, h = vh, off = off, span = contentH - vh, set = set } end,
    panePad = function(win, i0, v) for i = i0, #win._specs do win._specs[i].scrollView = v end end,
}
ZeD.Atoms = { frame = noop, truncateText = function(s) return s end, drawStatusDot = noop }
ZeD.Molecules = { buttonW = function(s) return #tostring(s) * 6 + 16 end }
ZeD.Font = { sdf = { head = { face = 64 } } }
ZeD.Text = { draw = noop, height = function() return 20 end }
local mx, my = 0, 0
getMouseX, getMouseY = function() return mx end, function() return my end
local oOk = load("drawOrderDetail", "MM, EMPTY, DETAIL_PAD", cut(MO_SRC, "local function paneOff(", "function ZeD_MMMods:joyDir("), MM, {}, 12)
if oOk then
    local items = { { t = "title", text = "Separator" }, { t = "sub", text = "12 mods" },
                    { t = "btns", list = { { id = "sdel", text = "Delete separator" } } }, { t = "head", text = "Mods under it" } }
    for i = 1, 60 do items[#items + 1] = { t = "text", lines = { "mod " .. i } } end
    items[#items + 1] = { t = "btns", list = { { id = "sfrom", text = "Start separators from folders" } } }
    local W = setmetatable({ page = "order", oSel = 4, oSepSel = "s1", _specs = {}, _hits = {}, focusId = "sdel" }, { __index = ZeD_MMMods })
    function W:orderDetailModel() return { items = items } end
    W.setStencilRect, W.clearStencilRect, W.drawText, W.drawRect = noop, noop, noop, noop
    function W:getAbsoluteX() return 0 end
    function W:getAbsoluteY() return 0 end
    local function frame()
        W._specs = {}
        W:drawOrderDetail(600, 100, 400, 300, false)
    end
    frame(); frame()   -- (the second frame knows the pane's height)
    local function spec(id) for _, s in ipairs(W._specs) do if s.id == id then return s end end end
    local last = spec("sfrom")
    check("ORDER: the button below the pane's foot is made (a stop), not dropped", last ~= nil)
    check("ORDER: it is out of view, so it neither draws nor takes a click yet", last and last.y + last.h > last.clipBot, last and last.y)
    check("ORDER: the pane knows it is taller than its view, with a bar", (W._oDetH or 0) > 300 and W._bar and W._bar.key == "mods:odet", W._oDetH)
    check("ORDER: its controls are in the pane's view for the pad's scroll", last and last.scrollView and last.scrollView.key == "mods:odet" and spec("sdel").scrollView ~= nil)
    -- the pad lands on it (the pad's scroll reached it): the follow brings it in
    W.focusId = "sfrom"
    W:joyDir("down")
    frame()
    last = spec("sfrom")
    check("ORDER: the pad on the last button scrolls the pane until it is wholly in view", baseJoy == 1 and last.y >= last.clipTop and last.y + last.h <= last.clipBot,
        tostring(last.y) .. " in " .. tostring(last.clipTop) .. ".." .. tostring(last.clipBot))
    W.focusId = "sdel"
    W:joyDir("up")
    frame()
    local first = spec("sdel")
    check("ORDER: back up on Delete separator, the pane scrolls back", first.y >= first.clipTop and first.y + first.h <= first.clipBot, first.y)
    -- the wheel over the pane
    mx, my = 700, 200
    local was = W.oDscroll
    check("ORDER: the wheel over the pane scrolls it", W:wheel(3) == true and W.oDscroll == was + 120, W.oDscroll)
    mx, my = 10, 200
    W:wheel(1)
    check("ORDER: the wheel elsewhere goes on to the list's", baseWheel == 1)
    W.oDscroll = 99999
    frame()
    check("ORDER: the scroll stays inside what there is", W.oDscroll == W._oDetH - 298, W.oDscroll)
    W.oSepSel = "s2"
    frame()
    check("ORDER: another pick starts at the top", W.oDscroll == 0)
    -- a short pane: nothing scrolls
    items = { { t = "title", text = "A mod" }, { t = "btns", list = { { id = "oafter", text = "Load after" } } } }
    W.oSepSel = nil
    frame(); W._bar = nil; frame()
    check("ORDER: a pane that fits shows no bar and has no scroll", W._bar == nil and W.oDscroll == 0)
end

-- ---------------------------------------------------------------------------
section("FOLDERS")
ZeD_MMWorkshop = {}
local UI = { insetBox = noop }
local BB = { trim = function(s) return s end }
local MM2 = { fontH = function() return 14 end, gamepad = function() return true end, ctx = {}, DOT = " | ",
              rowLook = function() return false end,
              scrollBar = function(p, key, x, y, w, h, scroll, total, set) p._bar = { key = key, set = set } end }
ZeD.Help = { set = noop }
ZeD.Molecules.drawEmptyLine = noop
local fOk = load("drawFolders", "UI, MM, BB, ROW_H",
    (cut(WS_SRC, "function ZeD_MMWorkshop:drawFolders(") or "") .. (cut(WS_SRC, "function ZeD_MMWorkshop:wheel(") or ""), UI, MM2, BB, 44)
if fOk then
    local function item(i) return { getTitle = function() return "Mod " .. i end, getFolderName = function() return "f" .. i end, getID = function() return nil end } end
    local W = { items = {}, sel = 1, scroll = 0, unsaved = {}, _specs = {}, _hits = {}, focusId = "frow:1",
                titleE = { getText = function() return "Mod 1" end } }
    setmetatable(W, { __index = ZeD_MMWorkshop })
    for i = 1, 20 do W.items[i] = item(i) end
    W.setStencilRect, W.clearStencilRect, W.drawText, W.drawRect = noop, noop, noop, noop
    function W:getAbsoluteX() return 0 end
    function W:getAbsoluteY() return 0 end
    local function frame() W._specs, W._hits = {}, {}; W:drawFolders(10, 50, 300, 400) end
    frame()
    check("FOLDERS: every folder is a stop, the ones past the foot too", #W._specs == 20, #W._specs)
    local s20 = W._specs[20]
    check("FOLDERS: a folder out of view is a stop for the list's own moves (its list and its view)", s20.listId == "wsfolders" and s20.clip and s20.y > s20.clip.y + s20.clip.h)
    check("FOLDERS: only the folders in sight take a press", #W._hits < 20 and #W._hits > 0, #W._hits)
    check("FOLDERS: the list has a bar", W._bar and W._bar.key == "ws:ftrack")
    W.focusId = "frow:20"
    frame()
    s20 = W._specs[20]
    check("FOLDERS: the pad on the last folder scrolls the list to it", s20.y >= s20.clip.y and s20.y + s20.h <= s20.clip.y + s20.clip.h, s20.y)
    W.focusId = "frow:2"
    frame()
    check("FOLDERS: back up the list, it follows", W._specs[2].y >= W._specs[2].clip.y, W._specs[2].y)
    local before = W.scroll
    mx, my = 100, 300
    check("FOLDERS: the wheel over the list scrolls it a row a tick", W:wheel(2) == true and W.scroll == before + 88, W.scroll)
    W.scroll = 99999
    frame()
    check("FOLDERS: the scroll stays inside the list", W.scroll == 20 * 44 - (W._folderBox.h), W.scroll)
    W.items = { item(1) }
    W.scroll = 50
    frame()
    check("FOLDERS: a list that fits has no scroll and no bar", W.scroll == 0)
end

print("pad_reach_b17_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
