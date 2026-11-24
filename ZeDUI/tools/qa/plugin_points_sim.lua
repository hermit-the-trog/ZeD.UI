-- ZeDUI/tools/qa/plugin_points_sim.lua  (Nov 23 2026, Build; the 1.0 plug-in points, brief_plugins.md)
-- ZeD's general plug-in points for add-ons, with no game running. Loadouts and outfits (and Restock) moved onto them
-- and will leave ZeD for their own add-on; this checks the points themselves, each run from its real source:
--   API       ZeD_AddonAPI.lua: a registry keeps order and replaces the same id; a throwing callback is caught and
--             logged once
--   EQUIP     ZeD.EquipmentTab.addSection (and its takeover): idle with nothing registered (no height, no drawing,
--             no press, no stop, no scroll), a test section draws, takes a press, adds its stops; a takeover holds
--             the stops and the scroll; a throwing section is left out, the others still draw
--   DOLL      ZeD.EquipDoll.addOverlay: no marks with none; a test overlay marks and draws; a throwing one is contained
--   JOURNAL   ZeD.JournalTab.addPage: ZeD's four pages alone with none; a page joins at 5, by id; hidden while its
--             visible() is false (or throws); its stops, modal, click and children
--   WHEEL     ZeD.DpadWheels.addSlice: the Character wheel's ring unchanged with none; a slice joins, hides, is contained
--   CARD      ZeD.ItemCard.addMark / addSection / addGen and the mark strip (Molecules.drawCardFlagStrip): three
--             chips and no stop with none; a test mark draws its chip and words, a section its height, a gen moves
--             the model's key; a throwing state or section is contained
--   OPTIONS   ZeD.Options.addRows / joinPreset / showIf, G.groupRows / G.stateKey and Settings.lua's joinAddition:
--             ZeD's groups as they are with none; rows spliced in place; a joined option follows the presets,
--             starts on for a player who had ZeD before it, and an add-on's own owner works too
--   ICONS     ZeD.PxIcon.addWarm / addMark
--   SOURCE    no ZeD file outside Loadouts' six names EL. / JL. / ZeD.Lists / ZeD.ListsUI / ZeD.Restock /
--             ZeD_RestockPin / ZeD.EquipLoadout / ZeD.JournalLists or requires them (comments aside)
-- Run from the repo root:  lua51 ZeDUI/tools/qa/plugin_points_sim.lua
-- It prints FAIL lines and a last line "plugin_points_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]plugin_points_sim%.lua$", "")
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
    return (string.gsub(s, "\r\n", "\n"))
end
-- the text from the first `from` to the end of the line where the first `to` after it ends (plain finds)
local function cut(src, from, to)
    local a = src and string.find(src, from, 1, true)
    if not a then return nil end
    local b = string.find(src, to, a, true)
    if not b then return nil end
    local e = string.find(src, "\n", b + #to, true) or #src
    return string.sub(src, a, e)
end
local function has(s, sub) return s ~= nil and string.find(s, sub, 1, true) ~= nil end
-- run a piece of source in the globals (ZeD and the stubs below); returns what it returns
local function run(name, src, ...)
    local f, err = loadstring(src or "", "=" .. name)
    check(name .. " loads", f ~= nil, err)
    if not f then return nil end
    local res = { pcall(f, ...) }
    check(name .. " runs", res[1], res[2])
    return unpack(res, 2)
end

-- ---------------------------------------------------------------------------
-- STUBS
-- ---------------------------------------------------------------------------
local LOG = {}   -- every ZeD.logOnce line, by key and message (as the real one: once each)
local function freshZeD()
    LOG = {}
    ZeD = {}
    ZeD.logOnce = function(key, msg)
        local k = tostring(key) .. "|" .. tostring(msg)
        LOG[k] = (LOG[k] or 0) + 1
    end
    ZeD.tr = function(k, ...) return tostring(k) end
end
local function logCount()
    local n = 0
    for _ in pairs(LOG) do n = n + 1 end
    return n
end
Events = setmetatable({}, { __index = function(t, k) local e = { Add = noop, Remove = noop }; rawset(t, k, e); return e end })

local API_SRC = readFile(Z .. "ZeD_AddonAPI.lua")
check("ZeD_AddonAPI.lua found", API_SRC ~= nil)
local function loadAPI() run("ZeD_AddonAPI.lua", API_SRC) end

-- ===========================================================================
section("API: the registry and the safe call")
-- ===========================================================================
freshZeD()
loadAPI()
local A = ZeD.API
check("API: version 1", A and A.VERSION == 1)
if A then
    local reg = A.registry()
    A.add(reg, "t", "b", { order = 20 })
    A.add(reg, "t", "a", { order = 10 })
    A.add(reg, "t", "c", { order = 20 })
    check("API: kept in order, equal orders as they came", reg.list[1].id == "a" and reg.list[2].id == "b" and reg.list[3].id == "c")
    A.add(reg, "t", "b", { order = 20, again = true })
    check("API: the same id again replaces it in its place", #reg.list == 3 and reg.list[2].again == true and reg.byId.b.again == true)
    check("API: a bad id is left out", A.add(reg, "t", nil, {}) == false and #reg.list == 3)
    local r1 = A.call("x", function(a, b) return a + b end, 2, 3)
    check("API: call returns what the function returns", r1 == 5)
    local function boom() error("bang") end
    local before = logCount()
    local r2 = A.call("boom", boom)
    A.call("boom", boom)
    check("API: a throwing callback gives nil and is logged once", r2 == nil and logCount() == before + 1, logCount() - before)
    local w = {}
    local s = A.state(w, "_t", function() return { n = 1 } end)
    check("API: state made once on the window", s.n == 1 and A.state(w, "_t") == s and w._t == s)
    check("API: the window's player", A.player({ _playerObj = "P" }) == "P" and A.player(nil) == nil)
end

-- ===========================================================================
section("EQUIP: sections under the doll, and the takeover")
-- ===========================================================================
local ET_SRC = readFile(Z .. "EquipmentTab.lua")
local etBlock = cut(ET_SRC, "ZeD.EquipmentTab._sections = ", "win._equipSlotYMap[id] = y end\nend")
check("EQUIP: the registry found in EquipmentTab.lua", etBlock ~= nil)
freshZeD()
loadAPI()
ZeD.EquipmentTab = {}
run("EquipmentTab.lua (the sections)", etBlock)
local ET = ZeD.EquipmentTab
local win = { _equipSlotYMap = {} }
if ET.addSection then
    check("EQUIP idle: no takeover", ET.extTakeover(win) == nil)
    check("EQUIP idle: no height", ET.extH(win, 300) == 0)
    check("EQUIP idle: nothing drawn", ET.extDraw({}, win, 0, 0, 300, nil) == 0)
    check("EQUIP idle: no press taken", ET.extClick(win, 5, 5) == false)
    local els = { { id = "x" } }
    ET.extFocusables(win, els)
    check("EQUIP idle: no stop added", #els == 1 and els._focusIdx == nil)
    check("EQUIP idle: no takeover stops", ET.extTakeoverFocusables(win) == nil)
    check("EQUIP idle: the tab's own scroll", ET.extScroll(win) == nil)
    check("EQUIP idle: the stops' key unchanged", ET.extScrollKey(win) == "")
    -- a test add-on
    local drawn, began, landed, todo = {}, 0, 0, false
    local SCROLL = { scrollPos = 0 }
    local TK = { render = function(p, w, x, y, ww, h) drawn[#drawn + 1] = "todo" end,
                 focusables = function() return { { id = "t:1" }, { id = "t:2" } } end,
                 scroll = function() return SCROLL end }
    ET.addSection("test", {
        order = 20,
        beginFrame = function() began = began + 1 end,
        h = function(w, ww) return 40 end,
        draw = function(p, w, x, y, ww, view) drawn[#drawn + 1] = "test@" .. y; return 40 end,
        onClick = function(w, x, y) return y < 40 end,
        focusables = function(w, e) e[#e + 1] = { id = "test:1" } end,
        land = function(w, e) landed = landed + 1; e._focusIdx = #e end,
        scrollKey = function() return "k1" end,
        takeover = function() return todo and TK or nil end,
    })
    ET.addSection("first", { order = 10, h = function() return 10 end, draw = function(p, w, x, y) drawn[#drawn + 1] = "first@" .. y; return 10 end })
    ET.extBegin(win)
    check("EQUIP: beginFrame each frame", began == 1)
    check("EQUIP: the heights added", ET.extH(win, 300) == 50)
    local h = ET.extDraw({}, win, 0, 100, 300, nil)
    check("EQUIP: drawn in order, one under the other", h == 50 and drawn[1] == "first@100" and drawn[2] == "test@110", table.concat(drawn, ","))
    check("EQUIP: a press taken", ET.extClick(win, 1, 1) == true and ET.extClick(win, 1, 99) == false)
    els = {}
    ET.extFocusables(win, els)
    check("EQUIP: its stops added, the landing asked", #els == 1 and els[1].id == "test:1" and landed == 1 and els._focusIdx == 1)
    check("EQUIP: the stops' key", ET.extScrollKey(win) == "k1")
    todo = true
    check("EQUIP: a takeover holds the drawer", ET.extTakeover(win) == TK)
    local tes = ET.extTakeoverFocusables(win)
    check("EQUIP: the takeover's stops alone", tes and #tes == 2 and tes[1].id == "t:1")
    check("EQUIP: the takeover's scroll", ET.extScroll(win) == SCROLL)
    todo = false
    -- hidden: no height, no drawing, no stops
    ET.addSection("hidden", { order = 30, visible = function() return false end, h = function() return 99 end,
        draw = function() drawn[#drawn + 1] = "hidden"; return 99 end, focusables = function(w, e) e[#e + 1] = { id = "h" } end })
    drawn = {}
    check("EQUIP: a hidden section has no height", ET.extH(win, 300) == 50)
    ET.extDraw({}, win, 0, 0, 300, nil)
    check("EQUIP: a hidden section draws nothing", #drawn == 2)
    els = {}
    ET.extFocusables(win, els)
    check("EQUIP: a hidden section has no stops", #els == 1)
    -- throwing: left out, the others still draw
    ET.addSection("bad", { order = 5, h = function() error("bad h") end, draw = function() error("bad draw") end,
        onClick = function() error("bad click") end, takeover = function() error("bad takeover") end })
    drawn = {}
    local before = logCount()
    local okD, hD = pcall(ET.extDraw, {}, win, 0, 0, 300, nil)
    check("EQUIP: a throwing section is contained, the others draw", okD and hD == 50 and #drawn == 2, tostring(hD))
    pcall(ET.extDraw, {}, win, 0, 0, 300, nil)
    check("EQUIP: its error logged once", logCount() == before + 1, logCount() - before)
    check("EQUIP: a throwing takeover is no takeover", select(2, pcall(ET.extTakeover, win)) == nil)
    ET.followY(win, "el:x", 77)
    check("EQUIP: followY feeds the pad's scroll-follow", win._equipSlotYMap["el:x"] == 77)
    ET.setFocus(win, "el:x")
    check("EQUIP: focus / setFocus", ET.focus(win) == "el:x")
end
check("EQUIP: the tab hides the card and draws the takeover",
    has(ET_SRC, "local takeover = ZeD.EquipmentTab.extTakeover(win)") and has(ET_SRC, "if panel._equipCard then panel._equipCard:setVisible(false) end"))

-- ===========================================================================
section("DOLL: marks in the empty slots")
-- ===========================================================================
local DOLL_SRC = readFile(Z .. "EquipDoll.lua")
local dollBlock = cut(DOLL_SRC, "D._overlays = ", "\n    return nil\nend\n")
check("DOLL: the registry found", dollBlock ~= nil)
freshZeD()
loadAPI()
ZeD.EquipDoll = {}
run("EquipDoll.lua (the overlays)", "local D = ZeD.EquipDoll\n" .. (dollBlock or ""))
local D = ZeD.EquipDoll
if D.addOverlay then
    local m, by = D.overlayMarks({}, false)
    check("DOLL idle: no marks", m == nil and by == nil)
    local drew = {}
    D.addOverlay("test", { slots = function(w, bands) return { main = "axe", head = "hat" } end,
        draw = function(p, x, y, s, g) drew[#drew + 1] = g .. "@" .. x end })
    D.addOverlay("late", { order = 200, slots = function() return { main = "other" } end, draw = function() drew[#drew + 1] = "late" end })
    m, by = D.overlayMarks({}, true)
    check("DOLL: the marks by slot, the first overlay wins a slot", m and m.main == "axe" and m.head == "hat" and by.main.id == "test")
    D.drawOverlay({}, 5, 6, 30, m, by, "main")
    check("DOLL: drawn by its overlay", drew[1] == "axe@5" and #drew == 1)
    D.addOverlay("bad", { order = 1, slots = function() error("bad slots") end })
    local okM, m2 = pcall(D.overlayMarks, {}, true)
    check("DOLL: a throwing overlay is contained", okM and m2 and m2.main == "axe")
    local bw = { _equipDollData = { belt = { { i = 2, slot = { slotType = "Belt Left" } } } } }
    check("DOLL: beltSlotFor names the belt's slot", D.beltSlotFor(bw, "Belt Left") == "belt2" and D.beltSlotFor(bw, "x") == nil)
end
check("DOLL: a mark keeps its small-slot row showing",
    has(DOLL_SRC, "data.small[sm.id].items[1] or (ghosts and ghosts[sm.id])") and has(DOLL_SRC, "local ghosts, ghostBy = D.overlayMarks(win, bands)"))

-- ===========================================================================
section("JOURNAL: pages by id")
-- ===========================================================================
local JT_SRC = readFile(Z .. "JournalTab.lua")
local jtBlock = cut(JT_SRC, "local SUB_TABS = {", "\n    return nil\nend\n")
local setPageSrc = cut(JT_SRC, "function ZeD.JournalTab.setPage(", "\nend\n")
local jtApi = cut(JT_SRC, "function ZeD.JournalTab.openPage(", "def.syncChildren, win, journalShown and cur == i)\n        end\n    end\nend")
check("JOURNAL: the page registry found", jtBlock ~= nil and setPageSrc ~= nil and jtApi ~= nil)
freshZeD()
loadAPI()
ZeD.JournalTab = {}
local SUB, shown = run("JournalTab.lua (the pages)", (jtBlock or "") .. "\n" .. (setPageSrc or "") .. "\n" .. (jtApi or "")
    .. "\nreturn SUB_TABS, subTabShown\n")
local JT = ZeD.JournalTab
if JT.addPage and SUB then
    check("JOURNAL idle: ZeD's four pages", #SUB == 4 and JT.pageIndex("recipes") == 4 and JT.pageIndex("loadouts") == nil)
    local jw = { _journalSubTab = 4 }
    local els, modal = JT.pageFocusables(jw)
    check("JOURNAL idle: no page stops", #els == 0 and modal == false)
    check("JOURNAL idle: no page press", JT.pageClick(jw, 1, 1) == false and JT.pageScrollKey(jw) == nil and JT.pageScroll(jw) == nil)
    local kids = {}
    JT.syncPageChildren(jw, true)
    -- a test page
    local on, asking = true, false
    JT.addPage("test", { key = "UI_Test", order = 10, visible = function() return on end,
        focusables = function() return { { id = "tp:1" } } end, modal = function() return asking end,
        onClick = function(w, x, y) return x < 10 end, scrollKey = function() return "sk" end,
        syncChildren = function(w, s) kids[#kids + 1] = s end })
    check("JOURNAL: the page joins at 5", #SUB == 5 and JT.pageIndex("test") == 5 and SUB[5].key == "UI_Test")
    check("JOURNAL: openPage by id", JT.openPage(jw, "test") == true and jw._journalSubTab == 5)
    check("JOURNAL: openPage of a page that is not there", JT.openPage(jw, "nope") == false)
    els, modal = JT.pageFocusables(jw)
    check("JOURNAL: its stops", #els == 1 and els[1].id == "tp:1" and modal == false)
    asking = true
    els, modal = JT.pageFocusables(jw)
    check("JOURNAL: modal while it asks", modal == true)
    check("JOURNAL: its press and key", JT.pageClick(jw, 1, 1) == true and JT.pageClick(jw, 50, 1) == false and JT.pageScrollKey(jw) == "sk")
    JT.syncPageChildren(jw, true)
    JT.syncPageChildren(jw, false)
    check("JOURNAL: its children shown only on its page with the tab up", kids[1] == true and kids[2] == false, tostring(kids[1]))
    check("JOURNAL: shown while visible", shown(SUB[5]) == true)
    on = false
    check("JOURNAL: hidden while not (the render goes back to the first page)", shown(SUB[5]) == false)
    JT.addPage("bad", { order = 5, visible = function() error("bad visible") end })
    check("JOURNAL: by order: the earlier order first, ids keep their index by order", JT.pageIndex("bad") == 5 and JT.pageIndex("test") == 6)
    local okS, sv = pcall(shown, SUB[5])
    check("JOURNAL: a throwing visible() is contained (hidden)", okS and sv == false)
end
check("JOURNAL: the render falls back to the first page when the open one hides",
    has(JT_SRC, "if not subTabShown(SUB_TABS[win._journalSubTab]) then\n        win._journalSubTab = 1"))

-- ===========================================================================
section("WHEEL: slices on the Character wheel")
-- ===========================================================================
local DW_SRC = readFile(Z .. "ZeD_DpadWheels.lua")
local dwBlock = cut(DW_SRC, "D._slices = ", "\n    return ring\nend\n")
check("WHEEL: the registry found", dwBlock ~= nil)
freshZeD()
loadAPI()
ZeD.DpadWheels = {}
run("ZeD_DpadWheels.lua (the slices)", "local D = ZeD.DpadWheels\n" .. (dwBlock or ""))
local DW = ZeD.DpadWheels
if DW.addSlice then
    local ring = { { name = "Tabs" } }
    DW.addonSlices("character", ring, "p", 0)
    check("WHEEL idle: the ring as it was", #ring == 1)
    local on = true
    DW.addSlice("character", "test", { visible = function() return on end, entry = function(p, pn) return { name = "Test " .. pn } end })
    DW.addSlice("character", "bad", { order = 1, entry = function() error("bad entry") end })
    ring = { { name = "Tabs" } }
    local okR = pcall(DW.addonSlices, "character", ring, "p", 0)
    check("WHEEL: its slice after ZeD's; a throwing one left out", okR and #ring == 2 and ring[2].name == "Test 0")
    on = false
    ring = {}
    DW.addonSlices("character", ring, "p", 0)
    check("WHEEL: hidden while not visible", #ring == 0)
    ring = {}
    DW.addonSlices("world", ring, "p", 0)
    check("WHEEL: another wheel has none", #ring == 0)
end
check("WHEEL: the Character wheel asks for them before the belt",
    has(DW_SRC, 'D.addonSlices("character", ring, p, pn)') and has(DW_SRC, "D.openCharTab = H.charTab"))

-- ===========================================================================
section("CARD: marks, sections and gens")
-- ===========================================================================
local IC_SRC = readFile(Z .. "ItemCard.lua")
local icBlock = cut(IC_SRC, "ZeD.ItemCard._marks = ", "def.activate, card, r, pad and true or false)\nend")
check("CARD: the registry found", icBlock ~= nil)
freshZeD()
loadAPI()
ZeD.ItemCard = {}
ZeD.Atoms = { FLAG_ICON = { fav = "star", nocraft = "craft_off", dispose = "trash" } }
run("ItemCard.lua (the registries)", icBlock)
local IC = ZeD.ItemCard
-- the mark strip, run from Molecules.lua (its chips recorded)
local MOL_SRC = readFile(Z .. "Molecules.lua")
local stripSrc = (cut(MOL_SRC, "local _partFocus = {}", "\nend\n") or "") .. (cut(MOL_SRC, "local FLAG_CHIPS = {", "\n    return h\nend\n") or "")
check("CARD: the mark strip found", has(stripSrc, "function ZeD.Molecules.drawCardFlagStrip("))
local CHIPS, TEXTS, HELP = {}, {}, {}
ZeD.T = setmetatable({ px = function(v) return v end, textDim = { r = 1, g = 1, b = 1 }, line = function() return 1 end,
    fontF1 = 1, fontF1H = 10 }, { __index = function() return 1 end })
ZeD.TM = { MeasureStringX = function(_, f, s) return 5 * #tostring(s) end, MeasureStringY = function() return 10 end }
ZeD.Atoms.FLAG_CHIP_H = 22
ZeD.Atoms.flagChipW = function(label, compact) return 40 end
ZeD.Atoms.mouseIn = function() return false end
ZeD.Atoms.drawDividerH = noop
ZeD.Atoms.drawFlagChip = function(panel, x, y, kind, on, glyph, label, outRect, compact, o)
    CHIPS[#CHIPS + 1] = kind .. (on and "+" or "-") .. "@" .. x .. (o and o.focus and "*" or "")
    if outRect then outRect.x, outRect.y, outRect.w, outRect.h = x, y, 40, 22 end
    return 40
end
ZeD.Help = { set = function(_, s) HELP[#HELP + 1] = s end }
ZeD.Molecules = {}
local panelStub = { drawText = function(_, s, x) TEXTS[#TEXTS + 1] = s .. "@" .. x end }
run("Molecules.lua (the mark strip)", "local NO_OPTS = {}\n" .. stripSrc)
local M = ZeD.Molecules
if IC.addMark and M.drawCardFlagStrip then
    local m = { fav = true, nocraft = false, dispose = false }
    IC.markStates(m, "item", 0)
    check("CARD idle: the model's marks are the three", m.test == nil and m.testText == nil)
    local rects = { fav = {}, nocraft = {}, dispose = {} }
    M.drawCardFlagStrip(panelStub, 0, 0, 400, m, false, rects, nil)
    check("CARD idle: three chips", #CHIPS == 3 and CHIPS[1] == "fav+@12", table.concat(CHIPS, ","))
    check("CARD idle: no rect for an add-on", rects.test == nil)
    check("CARD idle: no section height", IC.drawSections({}, "item", 0, 0, 300, false) == 0)
    local k0 = IC.genKey()
    check("CARD idle: the model's key does not move", IC.genKey() == k0)
    -- a test add-on
    local onList, gen = true, 1
    local acted = nil
    IC.addMark("test", { icon = "loadout", label = "UI_Test", state = function(item, pn)
            if not onList then return nil end
            return { on = true, text = "in 1 list", hint = "the hint" } end,
        activate = function(card, r, pad) acted = { card = card, r = r, pad = pad } end })
    IC.addSection("test", { draw = function(card, item, x, y, w, compact) return 30 end })
    IC.addGen("test", function() return gen end)
    check("CARD: the mark's icon on the chip", ZeD.Atoms.FLAG_ICON.test == "loadout")
    m = { fav = true, nocraft = false, dispose = false }
    IC.markStates(m, "item", 0)
    check("CARD: the mark's state in the model", m.test == true and m.testText == "in 1 list" and m.testHint == "the hint")
    CHIPS, TEXTS = {}, {}
    rects = { fav = {}, nocraft = {}, dispose = {} }
    M.drawCardFlagStrip(panelStub, 0, 0, 400, m, false, rects, { focusParts = { test = true } })
    check("CARD: its chip after the three, with the focus mark", #CHIPS == 4 and CHIPS[4] == "test+@150*", table.concat(CHIPS, ","))
    check("CARD: its words after it", TEXTS[1] == "in 1 list@196", TEXTS[1])
    check("CARD: its rect (the press and the pad stop)", rects.test and rects.test.x == 150)
    local card = { item = "item", _markRects = { test = { x = 1, y = 2, w = 3, h = 4 } } }
    IC.activateMark(card, "test", true)
    check("CARD: a press runs its activate with its rect", acted and acted.r.x == 1 and acted.pad == true)
    check("CARD: a section draws its height", IC.drawSections({}, "item", 0, 0, 300, false) == 30)
    local k1 = IC.genKey()
    gen = 2
    check("CARD: a gen's change moves the model's key", IC.genKey() ~= k1)
    onList = false
    m = { fav = false, nocraft = false, dispose = false }
    IC.markStates(m, "item", 0)
    CHIPS = {}
    M.drawCardFlagStrip(panelStub, 0, 0, 400, m, false, {}, nil)
    check("CARD: a nil state: no chip (its switch off)", #CHIPS == 3 and m.test == nil)
    IC.addMark("bad", { order = 1, state = function() error("bad state") end })
    IC.addSection("bad", { order = 1, draw = function() error("bad draw") end })
    local okB = pcall(IC.markStates, {}, "item", 0)
    check("CARD: a throwing state is contained", okB)
    local okS, hS = pcall(IC.drawSections, {}, "item", 0, 0, 300, false)
    check("CARD: a throwing section is contained, the others draw", okS and hS == 30)
end
local ICO_SRC = readFile(Z .. "ItemCardOrganism.lua")
check("CARD: the pad stop is toggle_<id>", has(IC_SRC, 'def._stopId = "toggle_" .. tostring(id)') or has(IC_SRC, '"toggle_" .. tostring(id)'))
check("CARD: the controller's stops come from the marks' rects", has(IC_SRC, "local r = self._markRects and self._markRects[def.id]"))
check("CARD: Lite draws no mark strip (no rects, no stops)",
    has(ICO_SRC, "if not (ZeD.Settings and ZeD.Settings.lite and ZeD.Settings.lite()) then fsH = M.drawCardFlagStrip("))
check("CARD: the model asks the gens", has(ICO_SRC, "IC.genKey()"))

-- ===========================================================================
section("OPTIONS: rows, showIf, presets")
-- ===========================================================================
local AO_SRC = readFile(ROOT .. "42/media/lua/shared/ZeD/AddonOptions.lua")
local MG_SRC = readFile(Z .. "ZeD_MainMenuOptionGroups.lua")
local mgBlock = (cut(MG_SRC, "local function liveOf(zo, id)", "\nend\n") or "")
    .. (cut(MG_SRC, "function G.groupRows(grp)", "\nend\n") or "") .. (cut(MG_SRC, "function G.stateKey()", "\nend\n") or "")
check("OPTIONS: groupRows and stateKey found", has(mgBlock, "function G.groupRows") and has(mgBlock, "function G.stateKey"))
freshZeD()
run("AddonOptions.lua", AO_SRC)
local OPTS = {}   -- owner -> { dict }
local function optOf(v) return { selected = v, getValue = function(self) return self.selected end,
    setValue = function(self, x) self.selected = x end } end
PZAPI = { ModOptions = { getOptions = function(_, owner) return OPTS[owner] end } }
OPTS.ZeD_UI = { dict = { sw = optOf(1), dep = optOf(2), other = optOf(1) } }
OPTS.TestAddon = { dict = { mine = optOf(2), myDep = optOf(1) } }
local G = { ZED_GROUPS = { { "UI_Group", { { "other", "onoff" }, { "dep", "radio", showIf = "sw" } } } } }
run("ZeD_MainMenuOptionGroups.lua (groupRows, stateKey)", "local G = ...\n" .. mgBlock, G)
if G.groupRows then
    local grp = G.ZED_GROUPS[1]
    check("OPTIONS idle: a group's rows are its own", G.groupRows(grp) == grp[2])
    local k0 = G.stateKey()
    OPTS.ZeD_UI.dict.sw.selected = 2
    check("OPTIONS: a showIf switch flipped rebuilds the page", G.stateKey() ~= k0)
    ZeD.Options.addRows { owner = "ZeD_UI", into = "UI_Group", afterRow = "other", rows = { { "sw", "onoff" } } }
    ZeD.Options.addRows { owner = "TestAddon", into = "UI_Group", rows = { { "myDep", "onoff", showIf = "mine" } } }
    ZeD.Options.addRows { owner = "TestAddon", into = "UI_Nope", rows = { { "x" } } }
    local rows = G.groupRows(grp)
    check("OPTIONS: rows spliced after their row, the rest at the end",
        #rows == 4 and rows[1][1] == "other" and rows[2][1] == "sw" and rows[3][1] == "dep" and rows[4][1] == "myDep")
    check("OPTIONS: ZeD_UI's row as it is, another owner's marked", rows[2]._owner == nil and rows[4]._owner == "TestAddon")
    local k1 = G.stateKey()
    OPTS.TestAddon.dict.mine.selected = 1
    check("OPTIONS: an add-on's showIf switch is tracked too", G.stateKey() ~= k1)
end
check("OPTIONS: an add-on group's row with showIf is left out while off",
    has(MG_SRC, "if e.showIf and liveOf(zo, e.showIf) ~= 2 then"))
check("OPTIONS: Loadouts' rows are no longer ZeD's own", not has(MG_SRC, '{ "loadouts", "onoff" }') and not has(MG_SRC, '"restock", "radio"'))

-- Settings.lua's additions with joins (the hidden_facts_sim harness, small)
local FILES = {}
function getFileReader(name)
    local s = FILES[name]
    if not s then return nil end
    local lines, i = {}, 0
    for l in (s .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = l end
    return { readLine = function() i = i + 1; return lines[i] end, close = noop }
end
function getFileWriter() return { write = noop, close = noop } end
getText = function(k) return k end
getTextOrNull = getText
getCore = function() return { getOptionClock24Hour = function() return true end } end
getSpecificPlayer = function() return nil end
getPlayer = getSpecificPlayer
isClient = function() return false end
local function newOption(id)
    local o = { id = id, values = {}, selected = 1 }
    function o:addItem(name, isDefault)
        self.values[#self.values + 1] = name
        if isDefault then self.selected = #self.values end
    end
    function o:getValue() return self.selected end
    function o:setValue(v) self.selected = v end
    return o
end
local function newOpts()
    local opts = { dict = {} }
    local function add(self, id) local o = newOption(id); self.dict[id] = o; return o end
    return setmetatable(opts, { __index = function(t, k)
        if k == "addComboBox" or k == "addTickBox" or k == "addMultipleTickBox" or k == "addSlider" then return add end
        return noop
    end })
end
local lastOpts
local realRequire = require
local LISTS_SRC = readFile(Z .. "ZeD_Lists.lua")
local joinBlock = cut(LISTS_SRC, "if ZeD.Options and ZeD.Options.addRows and ZeD.Options.joinPreset then", "\nend\n")
check("OPTIONS: Loadouts' joins found in ZeD_Lists.lua", joinBlock ~= nil)
local function loadSettings(ini, joinFirst, addonOwner)
    FILES["ModOptions.ini"] = ini
    freshZeD()
    run("AddonOptions.lua", AO_SRC)
    OPTS = {}
    if addonOwner then
        local ao = newOpts()
        local x = ao:addComboBox("x")
        x:addItem("Off", true); x:addItem("On", false)
        OPTS[addonOwner] = ao
    end
    PZAPI = { ModOptions = { create = function() lastOpts = newOpts(); return lastOpts end, save = noop, load = noop,
        getOptions = function(_, owner) return OPTS[owner] end } }
    require = function() end
    if joinFirst then run("ZeD_Lists.lua (the joins, before Settings)", joinBlock) end
    local chunk, err = loadfile(Z .. "Settings.lua")
    check("Settings.lua loads", chunk ~= nil, err)
    local ok, e = pcall(chunk)
    check("Settings.lua runs", ok, e)
    require = realRequire
    return lastOpts
end
local function inIds(id)
    for _, k in ipairs(ZeD.Settings and ZeD.Settings.ADDITION_IDS or {}) do if k == id then return true end end
    return false
end
local o = loadSettings(nil)
if o then
    check("SETTINGS idle: Loadouts and Restock are no additions", not inIds("loadouts") and not inIds("restock"))
    check("SETTINGS idle: no preset names them", ZeD.Settings.ADDITION_PRESETS[2].loadouts == nil and ZeD.Settings.ADDITION_PRESETS[3].restock == nil)
    run("ZeD_Lists.lua (the joins)", joinBlock)
    check("SETTINGS: joined, both are additions", inIds("loadouts") and inIds("restock"))
    local P = ZeD.Settings.ADDITION_PRESETS
    check("SETTINGS: the presets as they were (Vanilla off, Plus on with Casual, Accessible on with Accessible)",
        P[1].loadouts == 1 and P[1].restock == nil and P[2].loadouts == 2 and P[2].restock == 2 and P[3].loadouts == 2 and P[3].restock == 3)
    o.dict.additionsPreset.onChange(nil, 3)
    check("SETTINGS: Vanilla Accessible sets them", o.dict.loadouts:getValue() == 2 and o.dict.restock:getValue() == 3)
    o.dict.additionsPreset.onChange(nil, 1)
    check("SETTINGS: Vanilla turns Loadouts off, leaves Restock", o.dict.loadouts:getValue() == 1 and o.dict.restock:getValue() == 3)
    check("SETTINGS: a change to it re-reads the preset (its onChange)", type(o.dict.loadouts.onChange) == "function")
    check("SETTINGS: the rows go into Additions after Hidden facts", ZeD.Options.rowAdds[1] and ZeD.Options.rowAdds[1].into == "UI_ZeD_Options_ZedAdditions"
        and ZeD.Options.rowAdds[1].afterRow == "hiddenFacts" and ZeD.Options.rowAdds[1].rows[2].showIf == "loadouts")
end
-- a player who had ZeD before the Loadouts switch (ZeD's lines, none for it): it starts on; a saved Off stays
o = loadSettings(table.concat({ "|ZeD_UI|ammoBox|2", "|ZeD_UI|additionsPreset|4" }, "\n"))
if o then
    run("ZeD_Lists.lua (the joins)", joinBlock)
    check("SETTINGS: an existing player starts with Loadouts on", o.dict.loadouts:getValue() == 2)
    check("SETTINGS: savedValue reads the file", ZeD.Settings.savedValue("ZeD_UI", "ammoBox") == 2 and ZeD.Settings.savedValue("ZeD_UI", "loadouts") == nil)
end
o = loadSettings(table.concat({ "|ZeD_UI|ammoBox|2", "|ZeD_UI|loadouts|1" }, "\n"))
if o then
    run("ZeD_Lists.lua (the joins)", joinBlock)
    check("SETTINGS: a saved line wins (no start-on)", o.dict.loadouts:getValue() == 1)
end
o = loadSettings(nil, true)
if o then check("SETTINGS: joins made before Settings loads are taken when it does", inIds("loadouts") and ZeD.Settings.ADDITION_PRESETS[2].loadouts == 2) end
o = loadSettings(nil, false, "TestAddon")
if o then
    ZeD.Options.joinPreset { owner = "TestAddon", id = "x", presets = { 1, 2, 2 } }
    check("SETTINGS: an add-on's own option joins by owner.id", inIds("TestAddon.x"))
    o.dict.additionsPreset.onChange(nil, 2)
    check("SETTINGS: the preset sets an add-on's own option", OPTS.TestAddon.dict.x:getValue() == 2)
    ZeD.Options.joinPreset { owner = "TestAddon", id = "missing", presets = { 1, 2, 2 } }
    check("SETTINGS: an option that is not there is left out", not inIds("TestAddon.missing"))
end

-- ===========================================================================
section("ICONS: warmed and marked")
-- ===========================================================================
local AT_SRC = readFile(Z .. "Atoms.lua")
local pxBlock = cut(AT_SRC, "local WARM_EXTRA = ", "\n    return true\nend\n")
check("ICONS: found", pxBlock ~= nil)
freshZeD()
local ASKED = {}
Texture = { getSharedTexture = function(path) ASKED[path] = true end }
ZeD.PxIcon = { DIR = "w/", SIZES = { 48, 32, 24, 16 } }
ZeD.PxIconMark = { have = "red" }
run("Atoms.lua (the warm-up)", "local PXI = ZeD.PxIcon\n" .. (pxBlock or ""))
local PXI = ZeD.PxIcon
if PXI.addWarm then
    PXI.addWarm({ "early" })
    ZeD.ContextPxIcons = { a = "ctx" }
    PXI.warm(16)
    check("ICONS: an icon added before the warm-up is warmed with ZeD's", ASKED["w/16/zw_early.png"] and ASKED["w/16/zw_ctx.png"])
    PXI.addWarm({ "late" })
    check("ICONS: one added after is asked for at once", ASKED["w/16/zw_late.png"] == true)
    check("ICONS: ZeD's own rows no longer warm Loadouts' icons", not ASKED["w/16/zw_loadout.png"])
    check("ICONS: addMark colors a new id, keeps ZeD's", PXI.addMark("new_add", "blue") and ZeD.PxIconMark.new_add == "blue"
        and PXI.addMark("have", "blue") and ZeD.PxIconMark.have == "red" and PXI.addMark("x", "pink") == false)
end

-- ===========================================================================
section("SOURCE: ZeD names none of Loadouts' six files outside them")
-- ===========================================================================
local SIX = { ["ZeD_Lists.lua"] = true, ["ZeD_ListsMenu.lua"] = true, ["ZeD_EquipLoadout.lua"] = true,
              ["ZeD_JournalLists.lua"] = true, ["ZeD_Restock.lua"] = true, ["ZeD_RestockPin.lua"] = true }
local BAD = { "%f[%w_]EL%.", "%f[%w_]JL%.", "ZeD%.Lists%f[^%w_]", "ZeD%.ListsUI", "ZeD%.Restock", "ZeD_RestockPin",
              "ZeD%.EquipLoadout", "ZeD%.JournalLists", "require%s*%(?%s*[\"']ZeD/ZeD_Lists", "require%s*%(?%s*[\"']ZeD/ZeD_EquipLoadout",
              "require%s*%(?%s*[\"']ZeD/ZeD_JournalLists", "require%s*%(?%s*[\"']ZeD/ZeD_Restock" }
local files = {}
local root = (ROOT ~= "" and ROOT or ".\\"):gsub("/", "\\")
local okP, pipe = pcall(io.popen, 'dir /s /b "' .. root .. '42\\media\\lua\\*.lua" 2>nul')
if okP and pipe then
    for l in pipe:lines() do files[#files + 1] = l end
    pipe:close()
end
check("SOURCE: the Lua files listed", #files > 100, #files)
local hits, optHits = {}, {}
for _, path in ipairs(files) do
    local name = path:match("([^\\/]+)$")
    if not SIX[name] then
        local src = readFile(path) or ""
        local n = 0
        for line in (src .. "\n"):gmatch("(.-)\n") do
            n = n + 1
            -- (comments aside: the words may say where a thing went; the code may not name it)
            local code = line:gsub("%-%-.*$", "")
            for _, pat in ipairs(BAD) do
                if code:find(pat) then hits[#hits + 1] = name .. ":" .. n .. " " .. pat; break end
            end
            if code:find('"loadouts"', 1, true) or code:find('"restock"', 1, true) then optHits[name] = true end
        end
    end
end
check("SOURCE: no ZeD file outside the six names them or requires them", #hits == 0, table.concat(hits, "; "))
-- the two option ids: only Settings.lua still makes the options (owner ZeD_UI, until the add-on owns them)
local others = {}
for name in pairs(optHits) do if name ~= "Settings.lua" then others[#others + 1] = name end end
check("SOURCE: the option ids only where Settings.lua makes them", #others == 0, table.concat(others, ", "))
-- and the six register themselves once every file has loaded
for _, f in ipairs({ "ZeD_EquipLoadout.lua", "ZeD_JournalLists.lua", "ZeD_ListsMenu.lua" }) do
    check("SOURCE: " .. f .. " registers on OnGameBoot", has(readFile(Z .. f), "Events.OnGameBoot.Add("))
end

print("plugin_points_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
