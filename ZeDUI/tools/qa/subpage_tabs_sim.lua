-- ZeDUI/tools/qa/subpage_tabs_sim.lua  (Nov 12 2026, Build): punch list 175 C4, C1, D6 and C6 for the Radio, Vehicle,
-- Journal and Maps tabs, with no game running. Loads the real RadioTab.lua (ZeD.SubTabs, the radios' tabs, the click
-- router and the controller's stops) and JournalTab.lua against Lua 5.1 stand-ins (a panel that writes down every
-- draw, a TextManager whose widths add up letter by letter) and reads the other files' source. It proves:
--   C4  one way to pick a sub-page, the library's tab strip (ZeD.Molecules.drawTab, as Animals and Furniture):
--       * ZeD.SubTabs fits: every tab whole when there is room; short of room the longer words are cut ("...") and
--         every tab still drawn; far short, a run of tabs round the active one (and the controller's) only
--       * Radio: a tab per radio, named by the set (two alike carry where each is); a press on a tab shows that
--         radio (and follows it), the wheel over the strip steps; the controller's stops are "radio:tab:<n>" (none
--         with one radio), A shows that radio; no "< Secondary (1) >" pager left (drawDrawerInternalHeader)
--       * Vehicle: a tab per vehicle ("mech:veh:<n>" stamps, a press shows it, list from the top, no part chosen);
--         no pager, no "mech:prev" / "mech:next"
--       * Journal: the pages as tabs ("jtab:<page>" stops; A or a press opens the page; Loadouts only while on);
--         no "Page: Journal" pop-up (UI_ZeD_Journal_PagePick) and no modal page list
--   C1  Journal and Maps open with the tab's title (drawTabHeader); the Journal's search sits at its title's right;
--       the Maps pop-out (its own window title) has none
--   D6  one section style, the small mono line (M.drawCategoryRow): no drawSectionHeader left in MechanicsTab,
--       MechTrailer, MapsTabExt and JournalTab (the kills head folds as before); Radio's Channels / Heard / Power
--       blocks are ZeD_TabFill's, which draws its heads with drawCategoryRow
--   C6  Maps' icon buttons: the help line names the one under the pointer or the controller (ZeD.MapsTab.namedHelp,
--       "Unfold: Open the map..."; a help that starts with its name stays as it is); UI_ZeD_Map_HelpNamed in all 28
--       languages with %1 and %2, and its context row
-- Run from the repo root:  lua51 ZeDUI/tools/qa/subpage_tabs_sim.lua
-- It prints FAIL lines and a last line "subpage_tabs_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]subpage_tabs_sim%.lua$", "")
local SRC = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function read(p)
    local f = io.open(p, "rb")
    if not f then return "" end
    local s = f:read("*a")
    f:close()
    return s
end
local function has(s, pat) return string.find(s, pat, 1, true) ~= nil end

local function readJson(lang)
    local out = {}
    local f = io.open(ROOT .. "42/media/lua/shared/Translate/" .. lang .. "/UI.json", "rb")
    if not f then return out end
    for line in f:lines() do
        local k, v = line:match('^%s*"([^"]+)":%s*"(.*)",?%s*\r?$')
        if k then out[k] = v end
    end
    f:close()
    return out
end
local EN = readJson("EN")

-- ---------------------------------------------------------------------------
-- STAND-INS
-- ---------------------------------------------------------------------------
ZeD = {}
ZeD.tr = function(k, ...)
    local s = EN[k] or k
    local args = { ... }
    return (s:gsub("%%(%d)", function(n) return tostring(args[tonumber(n)] or "") end))
end
ZeD.trTestOn = function() return false end
function getText(k) return ZeD.tr(k) end
function getTimestampMs() return 0 end
function isMouseButtonDown() return false end

local CW = 7
ZeD.T = {
    scale = 1, hair = 1, buttonH = 20, inputH = 20, tabH = 22, stripH = 32, disabledAlpha = 0.4,
    fontF1 = "F1", fontF2 = "F2", fontF3 = "F3", fontF4 = "F4", fontF5 = "F5",
    sp = { sm = 6, xs = 3, md = 10, tabGap = 2, tabPadX = 12, scrollbarW = 8, inputPadX = 4, rowGap = 2 },
    text = {}, textDim = {}, textHead = {}, textOnFocus = {}, borderS = {}, hover = {}, accent = {},
}
ZeD.T.px = function(n) return n end
ZeD.TM = {
    MeasureStringX = function(_, f, s) return #tostring(s) * CW end,
    getFontHeight = function() return 14 end,
}
local MOUSE = { x = -1000, y = -1000 }
local function newPanel()
    local p = { draws = {} }
    function p:drawRect() end
    function p:drawText(s, x, y) self.draws[#self.draws + 1] = { "text", s, x, y } end
    function p:getMouseX() return MOUSE.x end
    function p:getMouseY() return MOUSE.y end
    function p:getWidth() return 1000 end
    function p:setStencilRect() end
    function p:clearStencilRect() end
    return p
end
local tabsDrawn = {}
ZeD.Atoms = {
    textCase = function(s) return s end,
    truncateText = function(s, font, w)
        if #s * CW <= w then return s end
        local out = s
        while #out > 0 and (#out + 3) * CW > w do out = out:sub(1, -2) end
        return out .. "..."
    end,
    mouseIn = function(panel, x, y, w, h)
        local mx, my = panel:getMouseX(), panel:getMouseY()
        return mx >= x and mx < x + w and my >= y and my < y + h
    end,
    drawDividerH = function() end,
    frame = function() end,
}
local headers = {}
ZeD.Molecules = {
    drawTab = function(panel, x, y, text, active, hovered, disabled, opts)
        local w = #text * CW + ((opts and opts.padX) or ZeD.T.sp.tabPadX) * 2
        tabsDrawn[#tabsDrawn + 1] = { text = text, active = active, x = x, w = w, focus = opts and opts.focus }
        return w
    end,
    drawTabHeader = function(panel, x, y, w, text) headers[#headers + 1] = text; return ZeD.T.stripH end,
    getTabHeaderH = function() return ZeD.T.stripH end,
    getTabPad = function() return 8 end,
    drawCategoryRow = function() return 15 end,
}
ZeD.Help = { last = nil, set = function(_, s) ZeD.Help.last = s end }
ZeD.Focus = { mark = function() return true end }
ZeD.Input = { Focus = { cuesVisible = function() return false end } }

local realRequire = require
require = function() end
dofile(SRC .. "RadioTab.lua")
require = realRequire

local ST, RT = ZeD.SubTabs, ZeD.RadioTab
check("ZeD.SubTabs loads with RadioTab", ST and ST.draw and ST.fit, "no ZeD.SubTabs")
if not (ST and ST.draw) then
    print(string.format("subpage_tabs_sim: %d checks, %d failed", checks, failed))
    os.exit(1)
end

-- ===========================================================================
section("the strip fits")
local function items(...)
    local out = {}
    for i, l in ipairs({ ... }) do out[i] = { label = l, help = "help " .. l } end
    return out
end
local p = newPanel()
tabsDrawn = {}
local h, zs = ST.draw(p, 0, 0, 480, items("Journal", "Notebooks", "Papers", "Recipes", "Loadouts"), 3)
check("strip height is the tab's", h == ZeD.T.tabH, h)
check("room: five tabs whole", #zs == 5 and tabsDrawn[2].text == "Notebooks", #zs)
check("room: the third is the active one", tabsDrawn[3].active == true and not tabsDrawn[1].active)
check("tabs left to right, no overlap", zs[2].x >= zs[1].x + zs[1].w and zs[5].x + zs[5].w <= 480)
tabsDrawn = {}
h, zs = ST.draw(p, 0, 0, 260, items("Journal", "Notebooks", "Papers", "Recipes", "Loadouts"), 1)
local cutOne, inside = false, true
for _, t in ipairs(tabsDrawn) do if t.text:find("%.%.%.$") then cutOne = true end end
for _, z in ipairs(zs) do if z.x + z.w > 260 then inside = false end end
check("short: every tab still drawn", #zs == 5, #zs)
check("short: the longer words cut", cutOne)
check("short: inside the strip", inside)
tabsDrawn = {}
local many = {}
for i = 1, 12 do many[i] = { label = "Premium Technologies Radio " .. i } end
h, zs = ST.draw(p, 0, 0, 220, many, 9)
local sawActive = false
for _, z in ipairs(zs) do if z.idx == 9 then sawActive = true end end
check("far short: a run of tabs only", #zs < 12 and #zs >= 1, #zs)
check("far short: the active one is in it", sawActive)
h, zs = ST.draw(p, 0, 0, 220, many, 9, { focus = 2 })
local sawF = false
for _, z in ipairs(zs) do if z.idx == 2 then sawF = true end end
check("far short: the controller's tab is in it", sawF)
-- hover names the tab in the help line
MOUSE.x, MOUSE.y = 30, 5
ZeD.Help.last = nil
ST.draw(p, 0, 0, 480, items("Ranch", "Butcher"), 1)
check("hover: the help line has the tab's help", ZeD.Help.last == "help Ranch", ZeD.Help.last)
MOUSE.x, MOUSE.y = -1000, -1000

-- ===========================================================================
section("Radio: a tab per radio")
local function dev(name) return { getDeviceName = function() return name end } end
local radios = {
    { radioInstance = "a", deviceData = dev("Base.WalkieTalkie1"), locationTag = "Primary" },
    { radioInstance = "b", deviceData = dev("Base.WalkieTalkie1"), locationTag = "Back" },
    { radioInstance = "c", deviceData = dev("Premium Radio"), locationTag = "Floor" },
}
local ti = RT.tabItems and RT.tabItems(radios) or {}
check("tabItems: one per radio", #ti == 3, #ti)
check("tabItems: the set's name, mod prefix cut, its place when two are alike",
    ti[1] and ti[1].label == "WalkieTalkie1 (" .. ZeD.tr("UI_ZeD_Radio_LocPrimary") .. ")", ti[1] and ti[1].label)
check("tabItems: one of a kind keeps its name alone", ti[3] and ti[3].label == "Premium Radio", ti[3] and ti[3].label)
check("tabItems: help names the radio and where it is", ti[3] and ti[3].help and ti[3].help:find(" | ", 1, true), ti[3] and ti[3].help)
local two = { { radioInstance = "x", deviceData = dev("TV"), locationTag = "Floor" },
              { radioInstance = "y", deviceData = dev("TV"), locationTag = "Floor" } }
ti = RT.tabItems(two)
check("tabItems: two alike in the same place carry their number", ti[2] and ti[2].label == "TV (2)", ti[2] and ti[2].label)

local win = { _radios = radios, _radioIdx = 1, _radioTabZones = {
    { x = 10, y = 10, w = 50, h = 22, idx = 1 }, { x = 62, y = 10, w = 50, h = 22, idx = 2 }, { x = 114, y = 10, w = 50, h = 22, idx = 3 } },
    _radioStripZone = { x = 0, y = 0, w = 300, h = 32 } }
check("click on the third tab: taken", RT.onClick(win, 120, 15) == true)
check("click on the third tab: that radio, followed", win._radioIdx == 3 and win._radioFollow == "c", win._radioIdx)
check("click on the strip off a tab: taken, nothing changes", RT.onClick(win, 250, 15) == true and win._radioIdx == 3)
RT.selectRadio(win, 1)
check("selectRadio: that radio", win._radioIdx == 1, win._radioIdx)
check("wheel over the strip: the next radio", RT.onWheel(win, 1, 100, 15) == true and win._radioIdx == 2, win._radioIdx)
RT.onWheel(win, -1, 100, 15)
check("wheel back: the previous radio", win._radioIdx == 1, win._radioIdx)
local els = RT.buildFocusables(win)
local tabStops, pager = 0, 0
for _, e in ipairs(els) do
    if tostring(e.id):match("^radio:tab:%d+$") then tabStops = tabStops + 1 end
    if e.id == "radio:browsePrev" or e.id == "radio:browseNext" then pager = pager + 1 end
end
check("pad: a stop per tab", tabStops == 3, tabStops)
check("pad: no pager stops", pager == 0, pager)
for _, e in ipairs(els) do
    if e.id == "radio:tab:2" then e.onActivate(win, e) end
end
check("pad: A on a tab shows that radio", win._radioIdx == 2, win._radioIdx)
local one = { _radios = { radios[1] }, _radioIdx = 1, _radioTabZones = { { x = 10, y = 10, w = 50, h = 22, idx = 1 } } }
local n1 = 0
for _, e in ipairs(RT.buildFocusables(one)) do if tostring(e.id):match("^radio:tab:") then n1 = n1 + 1 end end
check("pad: one radio, no tab stop", n1 == 0, n1)
local rsrc = read(SRC .. "RadioTab.lua")
check("Radio: no pager header", not has(rsrc, "drawDrawerInternalHeader"))
check("Radio: render draws the strip", has(rsrc, "ZeD.SubTabs.draw(panel, x, y + headerH - T.tabH, w, items, idx, _stripOpts)"))
check("Radio: the strip uses the library's tab", has(rsrc, "M.drawTab(panel, tabX, y, _stLab[i], isActive, hovered, false, o)"))

-- ===========================================================================
section("Vehicle: a tab per vehicle")
local msrc = read(SRC .. "MechanicsTab.lua")
check("Vehicle: no pager header", not has(msrc, "drawDrawerInternalHeader"))
check("Vehicle: no prev / next stops", not has(msrc, '"mech:prev"') and not has(msrc, '"mech:next"'))
check("Vehicle: a stop per tab", has(msrc, 'stamp(s, "mech:veh:" .. z.idx'))
check("Vehicle: the strip drawn", has(msrc, "ZeD.SubTabs.draw(panel, x, y + headerH - T.tabH, w, items, s.idx, _stripOpts)"))
check("Vehicle: needs RadioTab for the strip", has(msrc, 'require "ZeD/RadioTab"'))
-- the tab's press, run from the real source: that vehicle, the list from the top, no part chosen
local fnSrc = msrc:match("(local _vehTabFns = {}.-\r?\nend)\r?\n")
check("Vehicle: the tab's press found", fnSrc ~= nil)
if fnSrc then
    local env = { MT = {} }
    local chunk = loadstring("local MT = ...\n" .. fnSrc .. "\nreturn MT")
    local MT = chunk and chunk(env.MT)
    local s = { idx = 1, scrollY = 40, cardScroll = 9, card = "Engine", confirm = {} }
    local f = MT and MT.vehicleTabFn(s, 2)
    if f then f() end
    check("Vehicle: a press shows that vehicle, its list from the top", s.idx == 2 and s.scrollY == 0 and s.cardScroll == 0 and s.card == nil and s.confirm == nil, s.idx)
    check("Vehicle: the same fn each frame", MT and MT.vehicleTabFn(s, 2) == f)
end

-- ===========================================================================
section("Journal: the pages as tabs, its title first")
require = function() end
ZeD.JournalReaders = { beginFrame = function() end, listOpen = function() return false end, shutList = function() end,
    searchVisible = function() return false end, searchHint = function() return "" end,
    renderNotebooks = function() end, renderPapers = function() end }
ZeD.CraftingCore = {}
ZeD.Lists = { on = function() return true end }
ZeD.JournalLists = { listOpen = function() return false end, shutList = function() end, placeSearch = function() end,
    render = function() end }
dofile(SRC .. "JournalTab.lua")
require = realRequire
local JT = ZeD.JournalTab
local jw = { _journalSubTab = 2 }
jw._flyerSearch = nil
p = newPanel()
tabsDrawn, headers = {}, {}
local ok, err = pcall(function()
    -- the header alone (the page under it is not under test here)
    local saved = ZeD.JournalReaders.renderNotebooks
    JT.render(p, jw, 0, 0, 480, 400)
end)
check("Journal renders", ok, err)
check("Journal: the title first", headers[1] == ZeD.tr("UI_ZeD_Char_TabJournal"), headers[1])
check("Journal: five page tabs (Loadouts on)", #tabsDrawn == 5, #tabsDrawn)
check("Journal: Notebooks is the open tab", tabsDrawn[2] and tabsDrawn[2].active == true)
local stops = JT.headerFocusables(jw)
check("Journal: a stop per tab", #stops == 5 and stops[4].id == "jtab:4", stops[4] and stops[4].id)
stops[4].onActivate(jw, stops[4])
check("Journal: A on Recipes opens it", jw._journalSubTab == 4, jw._journalSubTab)
local z = jw._journalTabZones[3]
check("Journal: a press on Papers opens it", JT.onHeaderClick(jw, z.x + 2, z.y + 2) == true and jw._journalSubTab == 3, jw._journalSubTab)
check("Journal: no page list to hold the pad", JT.pageMenuOpen(jw) == false)
ZeD.Lists.on = function() return false end
tabsDrawn = {}
pcall(JT.render, p, jw, 0, 0, 480, 400)
check("Journal: Loadouts off, four tabs", #tabsDrawn == 4, #tabsDrawn)
local jsrc = read(SRC .. "JournalTab.lua")
check("Journal: no Page: pop-up", not has(jsrc, "UI_ZeD_Journal_PagePick") and not has(jsrc, "drawPopupMenu(panel, bx, rowY"))
check("Journal: the kills head is the one section style", not has(jsrc, "drawSectionHeader") and has(jsrc, "M.drawCategoryRow(panel, x, curY, drawW, getText(\"IGUI_char_Zombies_Killed\")"))

-- ===========================================================================
section("Maps: its title, one section style, the icon buttons named")
local mp = read(SRC .. "MapsTab.lua")
local mx = read(SRC .. "MapsTabExt.lua")
check("Maps: the title first in the drawer", has(mp, 'drawTabHeader(panel, x, y, w, ZeD.tr("UI_ZeD_World_TabMaps"), false, false, true)'))
check("Maps: no title in the pop-out", has(mp, "if not Ext.isPopout(win, panel) then"))
check("MapsTabExt: no drawSectionHeader", not has(mx, "drawSectionHeader("))
check("MapsTabExt: sections are category rows", has(mx, "M.drawCategoryRow(target, x, cy, w, s.title or \"\", s.count, true, _secO)"))
check("MechanicsTab: no drawSectionHeader", not has(msrc, "drawSectionHeader("))
check("MechTrailer: no drawSectionHeader", not has(read(SRC .. "MechTrailer.lua"), "drawSectionHeader("))
check("Radio's blocks: TabFill heads are category rows", has(read(SRC .. "ZeD_TabFill.lua"), "ZeD.Molecules.drawCategoryRow(panel, x, y, w, label, count, open"))
check("Radio's blocks: Channels, Heard, Power through TabFill", has(rsrc, 'F.block(panel, win, "radio", "heard"') and has(rsrc, 'F.block(panel, win, "radio", "power"'))
check("Maps: a tool button names itself to the controller", has(mp, "_focusHelp(panel, o)") and has(mp, "if o.hover or o.focus then"))
check("MapsTabExt: an icon button names itself to the controller", has(mx, "if focused and o.help then ZeD.Help.set(panel, o.help) end"))
-- namedHelp, run from the real source
local nh = mp:match("(function ZeD%.MapsTab%.namedHelp.-\r?\nend)\r?\n")
check("namedHelp found", nh ~= nil)
if nh then
    ZeD.MapsTab = {}
    loadstring(nh)()
    local NH = ZeD.MapsTab.namedHelp
    check("namedHelp: Unfold named", NH("Unfold", EN.UI_ZeD_Map_HelpUnfold) == "Unfold: " .. EN.UI_ZeD_Map_HelpUnfold, NH("Unfold", EN.UI_ZeD_Map_HelpUnfold))
    check("namedHelp: a help that starts with its name stays", NH("Note", "Note: type") == "Note: type")
    check("namedHelp: no help, the name", NH("Map key", nil) == "Map key")
end
for _, l in ipairs({ "EN", "AR", "CA", "CH", "CN", "CS", "DA", "DE", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT",
    "JP", "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }) do
    local v = readJson(l).UI_ZeD_Map_HelpNamed
    check(l .. ": UI_ZeD_Map_HelpNamed with %1 and %2", v and v:find("%%1") and v:find("%%2"), v)
end
check("context row for UI_ZeD_Map_HelpNamed", has(read(ROOT .. "ZeDUI/i18n/UI_ZeD.context.md"), "| `UI_ZeD_Map_HelpNamed` |"))

print(string.format("subpage_tabs_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
