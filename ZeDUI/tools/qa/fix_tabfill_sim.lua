-- ZeDUI/tools/qa/fix_tabfill_sim.lua  (Nov 12 2026, Build): the tab fill review's fixes checked with no game running, on
-- the real ThermalTab.lua, ZeD_TabFill.lua, HealthTab.lua, ZeD_HairBeard.lua, IdentityTab.lua and Input/SpatialNav.lua.
--   THERMAL   the default Character window at 1080p, Normal text (the tab's body 372 high: the view between the header
--             and the band 299): the open figure fills the view and the grid starts 13 px under it, so no cell was a
--             controller stop and Down from a foot went to the View box. Now the lowest stop shown scrolls the body on
--             (Health's rule): Down from the foot lands on a cell. Scrolled to the foot of the tab, Up onto the highest
--             stop shown scrolls back and Up goes on to the row above, not the header.
--   RULE      the rule itself (ZeD_TabFill.followStop, Health's own, moved there so both tabs share it): the lowest stop
--             scrolls a third on, Up onto the highest scrolls back, any other stop the least scroll, the band and the
--             disclosure never count, the stop always ends whole in view.
--   OVERALL   the Health tab's Overall row says the game's word for the overall health at the game's thresholds (its
--             health panel's Overall Body Status: OK only at 100, Slight damage above 90 ...), not a percent rounded up
--             to 100% while the game already says Slight damage. The row keeps a percent cut down (99%) and the word
--             has its own line under the bar, wrapped: every word the game ships, in all 28 languages, shows whole at
--             1x, 1.5x and 1.75x. The medical check's header tag and the Character window's help cut down too.
--   HAIR      Identity's Hair and beard with nothing carried to cut or style with: every style folded under the quiet
--             row, so "Hair (24)" and "Choose a row" stood over no rows. The fold opens by itself while nothing else
--             shows; shut by the player it stays shut while nothing can be done; once a row can be done it shuts
--             again, and a shut made then does not keep it shut once every tool is lost.
--   WEIGHT    the license's weight sign (+, ++, -): the help line says what it means while the pointer is on it.
-- Every section checks what the old code could not do, so it fails on the code before this work.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/fix_tabfill_sim.lua
-- It prints FAIL lines and a last line "fix_tabfill_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]fix_tabfill_sim%.lua$", "")
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"

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
local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end
local function load(path, env)
    local src = readFile(path)
    if not src then return false, "missing " .. path end
    local fn, err = loadstring(src, "@" .. path)
    if not fn then return false, err end
    if env then setfenv(fn, env) end
    return pcall(fn)
end

-- ---------------------------------------------------------------------------
-- THE LOOK at 1x (1080p, Normal text): tokens, a text manager 7 px a letter, a panel that draws nothing
-- ---------------------------------------------------------------------------
require = function() return nil end
getTimestampMs = function() return 100000 end
getText = function(k, a) if a ~= nil then return k .. "(" .. tostring(a) .. ")" end return k end
getCore = function() return nil end
getSoundManager = function() return { playUISound = noop } end
BodyPartType = setmetatable({}, { __index = function(_, k) return "BPT:" .. k end })
local function col() return { r = 1, g = 1, b = 1, a = 1 } end
local FH = { F1 = 14, F2 = 19, F3 = 14 }
ZeD = {
    T = setmetatable({
        px = function(n) return n end, fontF1 = "F1", fontF2 = "F2", fontF3 = "F3", fontF5 = "F3", selectionA = 0.3,
        fillBarH = 13, buttonH = 26, rowH = 24, scale = 1, disabledAlpha = 0.4, hair = 1,
        sp = { scrollbarW = 14, afterLine = 10, afterGroove = 8, rowGap = 6, xs = 6, sm = 10, figureW = 220, figureH = 260 },
    }, { __index = function(t, k) local c = col(); rawset(t, k, c); return c end }),
    TM = { getFontHeight = function(_, f) return FH[f] or 19 end, MeasureStringX = function(_, f, s) return #tostring(s) * 7 end },
    tr = function(k, a) return k .. (a ~= nil and ("(" .. tostring(a) .. ")") or "") end,
    Help = { set = function(_, s) ZeD.Help.last = s end },
    Focus = { mark = function() return false end },
    Text = { wordsEpoch = function() return 1 end },
    partLabel = function(n) return n end,
}
ZeD.Atoms = {
    FILL_SEGS = 10,
    fillBarMinW = function() return 40 end, rowBarW = function() return 60 end, fillBarCompactH = function() return 8 end,
    fillSegsLit = function(v, n) n = n or 10; if v <= 0 then return 0 end; if v >= 1 then return n end; return math.floor(v * n + 1e-6) end,
    drawSegFill = function() return false end, drawStatusDot = noop, drawStatusHollow = noop,
    mouseIn = function(panel, x, y, w, h)
        local mx, my = panel.mx or -1, panel.my or -1
        return mx >= x and mx < x + w and my >= y and my < y + h
    end,
    statusColor = function() return col() end,
    wrapText = function(text, font, w) return { tostring(text) } end,
    truncateText = function(s) return s end,
    drawDividerH = noop, drawBody = noop,
}
-- the molecules the tabs call, at their real sizes (Molecules.lua: the tab header 37, the pads 8, the band
-- buttonH + 10, Zone A's columns)
ZeD.Molecules = {
    getTabPad = function() return 8 end, getTabPadTop = function() return 8 end, getTabHeaderH = function() return 37 end,
    bandH = function() return ZeD.T.buttonH + 10 end,
    layoutZoneA = function(x, y, w, figW, figH)
        local leftX = x + 8
        local rightX = leftX + ZeD.T.sp.figureW + 10
        return { figX = leftX + math.floor((ZeD.T.sp.figureW - figW) / 2), figY = y, leftX = leftX, leftW = ZeD.T.sp.figureW,
                 rightX = rightX, rightY = y, rightW = w - 8 - rightX + x }
    end,
    drawStatRow = function() return 16 end,
    drawStatRowDot = function(panel, x, y, w, label, value) panel.rows = panel.rows or {}; panel.rows[label] = value; return 16 end,
    drawFillBar = function() return 13 end,
    drawTabHeader = noop, drawBand = noop, drawPopupMenu = noop,
    popupMenuW = function() return 120 end,
    drawSectionHeader = function() return 20 end,
    drawStatBarRow = function() return math.max(FH.F3, FH.F2) + 8 end,
    drawCategoryRow = function() return 20 end,
}
local function newPanel()
    return setmetatable({ mx = -1, my = -1 }, { __index = function(t, k)
        if type(k) == "string" and (k:find("draw", 1, true) == 1 or k:find("Stencil", 1, true)) then return noop end
        return nil
    end })
end

-- the controller, as the window keeps it: the focused element in its zone, the last move
local FOCUS, ZONE = nil, { elements = {} }
ZeD.Input = { Focus = {
    getFocusedWindow = function() return FOCUS and FOCUS.win or nil end,
    getFocusedElement = function() return FOCUS end,
    getFocusedZone = function() return ZONE end,
    liveElement = function() return FOCUS end,
    isFocused = function(_, _, id) return FOCUS ~= nil and FOCUS.id == id end,
} }

local okN, errN = load(CLIENT .. "Input/SpatialNav.lua")
check("SpatialNav.lua loads", okN, errN)
local okF, errF = load(CLIENT .. "ZeD_TabFill.lua")
check("ZeD_TabFill.lua loads", okF, errF)
local N, F = ZeD.SpatialNav, ZeD.TabFill

-- ===========================================================================
section("THERMAL: the open figure fills the view; the pad reaches the grid")
-- ===========================================================================
-- the body figure: the male layout's hit rects (ZeD_BodyFigure.lua's M_HITS), drawn at 1x where the tab puts it
local HITS = {
    { "Head", 96, 5, 30, 42 }, { "Neck", 103, 40, 15, 16 }, { "Upper Torso", 87, 48, 54, 58 },
    { "Right Upper Arm", 72, 56, 25, 52 }, { "Left Upper Arm", 125, 56, 24, 53 }, { "Lower Torso", 101, 99, 19, 21 },
    { "Right Forearm", 67, 99, 18, 41 }, { "Left Forearm", 136, 99, 17, 41 }, { "Groin", 88, 109, 46, 32 },
    { "Right Hand", 67, 134, 15, 32 }, { "Left Hand", 137, 134, 16, 32 }, { "Right Upper Leg", 86, 124, 22, 64 },
    { "Left Upper Leg", 113, 124, 22, 64 }, { "Right Lower Leg", 86, 179, 17, 60 }, { "Left Lower Leg", 118, 179, 17, 60 },
    { "Right Foot", 85, 233, 15, 21 }, { "Left Foot", 119, 233, 17, 21 },
}
ZeD_BodyFigure = { new = function()
    local fig = { x = 0, y = 0 }
    fig.initialise, fig.loadTextures, fig.setSex, fig.setPartColor = noop, noop, noop, noop
    function fig:drawAt(panel, px, py) self.x, self.y = px, py end
    function fig:getPartRects()
        local out = {}
        for i, h in ipairs(HITS) do out[i] = { name = h[1], x = self.x + h[2], y = self.y + h[3], w = h[4], h = h[5] } end
        return out
    end
    return fig
end }
local okT, errT = load(CLIENT .. "ThermalTab.lua")
check("ThermalTab.lua loads", okT, errT)

-- the player: a thermoregulator whose every reading is half way
local node = setmetatable({}, { __index = function() return function() return 0.5 end end })
local thermo = { getCoreCelcius = function() return 37 end, getTemperatureAir = function() return 20 end,
                 getTemperatureAirAndWind = function() return 18 end, getHeatGenerationUI = function() return 0.3 end,
                 getNodeForType = function() return node end }
local PLAYER = { getBodyDamage = function() return { getThermoregulator = function() return thermo end } end,
                 isFemale = function() return false end }
local function newScroll()
    return { scrollPos = 0, visible = false, setBarSize = noop, draw = noop,
             setScrollPos = function(self, v) self.scrollPos = math.max(0, math.min(1, v)) end }
end

-- the window's controller stops on the tab, as ZeD_CharacterWindow's _buildThermalFocusables makes them: the
-- header's disclosure, the parts the body shows (clipped to it), the fill stops (cells, the picked rows), the band's box
local function inBodyView(view, y, h)
    local top, bot = math.max(y, view.y), math.min(y + h, view.y + view.h)
    if bot - top < 2 then return nil end
    return top, bot - top
end
local function thermalStops(win)
    local els = {}
    local fz = win._thermalFigureZone
    els[#els + 1] = { x = fz.x, y = fz.y, w = fz.w, h = fz.h, id = "thermal:__disclosure", isDisclosure = true, win = win }
    for _, r in ipairs(win._thermalBodyFigure:getPartRects()) do
        local vy, vh = inBodyView(win._thermalBodyRect, r.y, r.h)
        if vy then
            els[#els + 1] = { x = r.x, y = vy, w = r.w, h = vh, fullY = r.y, fullH = r.h, id = "thermalpart:" .. r.name,
                              partName = r.name, win = win }
        end
    end
    for _, e in ipairs(F.focusables(win, "thermal", win._thermalBodyRect)) do e.win = win; els[#els + 1] = e end
    local bz = win._thermalBand
    els[#els + 1] = { x = bz.box.x, y = bz.box.y, w = bz.box.w, h = bz.box.h, id = "thermal:view", bandStop = true, win = win }
    return els
end
local function byId(els, id) for _, e in ipairs(els) do if e.id == id then return e end end return nil end
local function others(els, e) local out = {} for _, o in ipairs(els) do if o ~= e then out[#out + 1] = o end end return out end
local function isCell(e) return e ~= nil and e.id:find("^fill:thermal:cell:") ~= nil end

if okT and okF and okN then
    local win = { _playerObj = PLAYER, _thermalScroll = newScroll(), _thermalFigureExpanded = true, _thermalView = 1 }
    local W, H = 480, 372   -- (the full card at 1x; the tab's body in a new 420-high window: 420 - 26 - 22)
    local function frame()
        local p = newPanel()
        ZeD.ThermalTab.render(p, win, 0, 0, W, H)
        return thermalStops(win)
    end
    FOCUS = nil
    local els = frame()
    els = frame()   -- (the figure's rects are its last draw's, as in game)
    local view = win._thermalBodyRect
    check("the default view: 299 between the header and the band", view.h == 299, view.h)
    local cells = 0
    for _, e in ipairs(els) do if isCell(e) then cells = cells + 1 end end
    check("the default view: the grid starts under it (no cell is a stop at the top)", cells == 0, cells)
    local foot = byId(els, "thermalpart:Right Foot")
    check("the foot is a stop, whole in view", foot ~= nil and foot.h == foot.fullH)
    -- the pad walks down the figure to the foot (one focus change: the follow runs once)
    win._navLast = { dir = "down" }
    FOCUS, ZONE.elements = foot, els
    els = frame()   -- the body follows the focus
    check("focusing the lowest part shown scrolls the body on", win._thermalScroll.scrollPos > 0, win._thermalScroll.scrollPos)
    -- the window rebuilds the stops as the scroll moved; the focus stays on the foot
    FOCUS = byId(els, "thermalpart:Right Foot")
    ZONE.elements = els
    check("the foot stays a stop, whole in view", FOCUS ~= nil and FOCUS.h == FOCUS.fullH, FOCUS and FOCUS.h)
    local down = FOCUS and N.pick(FOCUS, others(els, FOCUS), "down")
    check("Down from the foot lands on a grid cell", isCell(down), down and down.id)
    els = frame()   -- (the focus is the same: nothing moves)
    -- scrolled to the foot of the tab, the pad comes back up through the grid
    win._thermalScroll:setScrollPos(1)
    FOCUS = nil
    els = frame()
    local top = nil
    for _, e in ipairs(els) do
        if not e.bandStop and not e.isDisclosure and (not top or e.y < top.y) then top = e end
    end
    check("at the foot of the tab the highest stop shown is a cell", isCell(top), top and top.id)
    local before = win._thermalScroll.scrollPos
    win._navLast = { dir = "up" }
    FOCUS, ZONE.elements = top, els
    els = frame()
    check("Up onto the highest stop shown scrolls the body back", win._thermalScroll.scrollPos < before,
        before .. " to " .. win._thermalScroll.scrollPos)
    FOCUS = byId(els, top.id)
    ZONE.elements = els
    local up = FOCUS and N.pick(FOCUS, others(els, FOCUS), "up")
    check("Up from it goes on to the row above, not the header", up ~= nil and not up.isDisclosure and up.y < FOCUS.y,
        up and up.id)
    check("the source: the Thermal tab follows by the shared rule",
        (readFile(CLIENT .. "ThermalTab.lua") or ""):find("ZeD.TabFill.followStop(win, el, ly, lh, scrollH, oldOff, span)", 1, true) ~= nil)
    FOCUS = nil
end

-- ===========================================================================
section("RULE: the body's scroll-follow, Health's own, shared")
-- ===========================================================================
if okF and F.followStop then
    -- a view 300 high scrolled 100 down a 1000 tall body; four stops in view and the band under it
    local win = {}
    local VY = 50   -- (the view's top on screen)
    local function stop(id, contentY, h)
        local y, hh = VY + contentY - 100, h
        return { id = id, y = y, h = hh }
    end
    local a, b, c, d = stop("a", 120, 30), stop("b", 200, 30), stop("c", 280, 30), stop("d", 360, 30)
    local band = { id = "band", y = VY + 300, h = 30, bandStop = true }
    local disc = { id = "disc", y = 10, h = 30, isDisclosure = true }
    ZONE.elements = { disc, a, b, c, d, band }
    win._navLast = { dir = "down" }
    check("the lowest stop shown scrolls a third of the view on", F.followStop(win, d, 360, 30, 300, 100, 700) == 260,
        F.followStop(win, d, 360, 30, 300, 100, 700))
    check("a stop in the middle takes no scroll", F.followStop(win, b, 200, 30, 300, 100, 700) == 100)
    win._navLast = { dir = "up" }
    check("Up onto the highest stop shown scrolls back a third", F.followStop(win, a, 120, 30, 300, 100, 700) == 0,
        F.followStop(win, a, 120, 30, 300, 100, 700))
    check("Up onto the lowest one does not scroll it on", F.followStop(win, d, 360, 30, 300, 100, 700) == 100)
    win._navLast = nil
    check("the band and the disclosure never count as below or above", F.followStop(win, d, 360, 30, 300, 100, 700) == 260)
    check("the scroll stays in its range", F.followStop(win, d, 990, 30, 300, 600, 700) == 700,
        F.followStop(win, d, 990, 30, 300, 600, 700))
    -- a lone stop above the view (the lowest, as nothing else is shown): it still ends whole in view
    local lone = stop("lone", 50, 30)
    ZONE.elements = { disc, lone, band }
    check("the stop ends whole in view", F.followStop(win, lone, 50, 30, 300, 100, 700) == 50,
        F.followStop(win, lone, 50, 30, 300, 100, 700))
    local hs = readFile(CLIENT .. "HealthTab.lua") or ""
    check("the source: the Health tab follows by the same rule",
        hs:find("ZeD.TabFill.followStop(win, el, elY - scrollY + oldOff, elH, scrollH, oldOff, span)", 1, true) ~= nil)
    ZONE.elements = {}
else
    check("ZeD_TabFill.followStop exists", false)
end

-- ===========================================================================
section("OVERALL: the game's word for the overall health")
-- ===========================================================================
local okH, errH = load(CLIENT .. "HealthTab.lua")
check("HealthTab.lua loads", okH, errH)
local HT = ZeD.HealthTab
if okH and HT then
    -- the game's own panel (zombie.ui.NewHealthPanel.getDamageStatusString): == 100 OK, > 90 Slight, > 80 Very Minor,
    -- > 70 Minor, > 60 Moderate, > 50 Severe, > 40 Very Severe, > 20 Critical, > 10 Highly Critical, > 0 Terminal
    local GAME = { { 100, "IGUI_health_ok" }, { 99.6, "IGUI_health_Slight_damage" }, { 90.01, "IGUI_health_Slight_damage" },
                   { 90, "IGUI_health_Very_Minor_damage" }, { 75, "IGUI_health_Minor_damage" }, { 65, "IGUI_health_Moderate_damage" },
                   { 55, "IGUI_health_Severe_damage" }, { 50, "IGUI_health_Very_Severe_damage" }, { 30, "IGUI_health_Crital_damage" },
                   { 20, "IGUI_health_Highly_Crital_damage" }, { 10, "IGUI_health_Terminal_damage" }, { 0.5, "IGUI_health_Terminal_damage" },
                   { 0, "IGUI_health_Deceased" } }
    local ok = type(HT.overallWord) == "function"
    if ok then
        for _, g in ipairs(GAME) do
            check("overall " .. g[1] .. ": the game's word", HT.overallWord(g[1]) == g[2], HT.overallWord(g[1]))
        end
    else
        check("the game's words for the overall health", false, "no overallWord")
    end
    -- the row itself: 99.6 (a bleed has cost the forearm a little) read "100%"; the game says Slight damage.
    -- The row keeps its percent, cut down (99%), and the word has a line of its own under the bar: in the
    -- row's value slot a long word was cut with "..." ("Slight ..." at the 1.5 step).
    ZeD.Atoms.pctText = function(f) return tostring(math.floor(math.max(0, math.min(1, f)) * 100 + 1e-6)) .. "%" end
    local realBody = ZeD.Atoms.drawBody
    ZeD.Atoms.drawBody = function(panel, s) panel.body = panel.body or {}; panel.body[#panel.body + 1] = s end
    local p = newPanel()
    local win = { _playerObj = nil }
    HT._renderHeader(p, win, { overall = 99.6, woundedCount = 6, injuredCount = 6, totalParts = 17 }, 0, 0, 220)
    local shown = p.rows and p.rows["UI_ZeD_Health_Overall"]
    check("99.6: the Overall row reads 99%, not 100%", shown == "99%", shown)
    check("99.6: the game's word on its own line under the bar", p.body and p.body[1] == "IGUI_health_Slight_damage",
        p.body and p.body[1])
    p = newPanel()
    HT._renderHeader(p, win, { overall = 100, woundedCount = 6, injuredCount = 6, totalParts = 17 }, 0, 0, 220)
    check("fresh wounds the game has not counted yet: OK, as the game says", p.body and p.body[1] == "IGUI_health_ok",
        p.body and p.body[1])
    ZeD.Atoms.drawBody = realBody
    local medic = readFile(CLIENT .. "ObjectCardMedic.lua") or ""
    check("the medical check draws the same overall block", medic:find("ZeD.HealthTab.drawOverall(card, rx, y, rw, d)", 1, true) ~= nil
        and medic:find("overallWordOf(d), pctColor", 1, true) == nil)
    check("the medical check's header tag is cut down too (99.6 is 99%)",
        medic:find("return ZeD.Atoms.pctText(frac), ZeD.Atoms.statusColor(frac)", 1, true) ~= nil
        and medic:find("math.floor(t.d.overall + 0.5)", 1, true) == nil)
    local cw = readFile(CLIENT .. "ZeD_CharacterWindow.lua") or ""
    check("the Character window's health help is cut down too",
        cw:find("local hp = math.floor(bd:getOverallBodyHealth())", 1, true) ~= nil)

    -- Every one of the game's overall words, in every language it ships, shows whole at 1x, the 1.5 step and
    -- 1.75x (the director's QA scale), Normal and Large text: wrapped to the Health tab's right column with the
    -- scrollbar showing (layoutZoneA: the window's 480 less the 14 scrollbar, 8 + figure + 10 + 8, the figure 220
    -- at its whole zoom: 220 wide at 1x and 1.5x, 330 at 1.75x). Widths are measured on the safe side: Fira's
    -- letters at 0.6 em (mono, wider than the sans the line is drawn in), a CJK letter a whole em, a Thai mark none.
    local GAMEDIR = "E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/lua/shared/Translate/"
    local WORDS = { "ok", "Slight_damage", "Very_Minor_damage", "Minor_damage", "Moderate_damage", "Severe_damage",
        "Very_Severe_damage", "Crital_damage", "Highly_Crital_damage", "Terminal_damage", "Deceased" }
    local VLANGS = { "EN", "AR", "CA", "CH", "CN", "CS", "DA", "DE", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT",
        "JP", "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
    local EM = 0
    local function cpW(s)
        local wsum, i = 0, 1
        while i <= #s do
            local b = s:byte(i)
            local n = (b >= 240 and 4) or (b >= 224 and 3) or (b >= 192 and 2) or 1
            local cp = b
            if n == 2 then cp = (b % 32) * 64 + (s:byte(i + 1) % 64)
            elseif n == 3 then cp = (b % 16) * 4096 + (s:byte(i + 1) % 64) * 64 + (s:byte(i + 2) % 64)
            elseif n == 4 then cp = 0x10000 end
            local thaiMark = cp == 0x0E31 or (cp >= 0x0E34 and cp <= 0x0E3A) or (cp >= 0x0E47 and cp <= 0x0E4E)
            local comb = cp >= 0x0300 and cp <= 0x036F
            if not thaiMark and not comb then wsum = wsum + ((cp >= 0x2E80) and EM or EM * 0.6) end
            i = i + n
        end
        return wsum
    end
    local function wrapModel(text, _, maxW)
        local lines, line = {}, ""
        for word in text:gmatch("%S+") do
            local test = line == "" and word or (line .. " " .. word)
            if cpW(test) > maxW and line ~= "" then lines[#lines + 1] = line; line = word else line = test end
        end
        if line ~= "" then lines[#lines + 1] = line end
        return lines
    end
    local realWrap, realMeasure = ZeD.Atoms.wrapText, ZeD.TM.MeasureStringX
    ZeD.Atoms.wrapText = wrapModel
    ZeD.TM.MeasureStringX = function(_, _, s) return cpW(tostring(s)) end
    local STEPS = { { 1, 220, 13 }, { 1.5, 220, 19.5 }, { 1.75, 330, 22.75 }, { 1, 220, 15 }, { 1.5, 220, 22.5 }, { 1.75, 330, 26.25 } }
    local bad, seen, langsRead = {}, 0, 0
    for _, l in ipairs(VLANGS) do
        local j = readFile(GAMEDIR .. l .. "/IG_UI.json")
        if j then
            langsRead = langsRead + 1
            for _, k in ipairs(WORDS) do
                local word = j:match('"IGUI_health_' .. k .. '"%s*:%s*"([^"]*)"')
                if word then
                    for _, s in ipairs(STEPS) do
                        EM = s[3]
                        seen = seen + 1
                        local lines = (HT.overallLines or function() return { "" } end)({ overall = 50, overallWord = word }, "F2", s[2])
                        local whole = true
                        for _, ln in ipairs(lines) do if cpW(ln) > s[2] then whole = false end end
                        local joined = table.concat(lines, ""):gsub("%s", "")
                        if not whole or joined ~= word:gsub("%s", "") then
                            bad[#bad + 1] = l .. ":" .. k .. "@" .. s[1] .. "x/" .. s[3] .. "px"
                        end
                    end
                end
            end
        end
    end
    ZeD.Atoms.wrapText, ZeD.TM.MeasureStringX = realWrap, realMeasure
    check("the game's translations found", langsRead == #VLANGS, langsRead)
    check("every overall word in every language shows whole at 1x, 1.5x and 1.75x (" .. seen .. " looks)",
        #bad == 0 and seen > 0, table.concat(bad, " "))
    -- the word is looked up once per read of the body (a few times a second), not every frame
    local d = { overall = 85 }
    local calls = 0
    local realGetText = getText
    getText = function(k, a) calls = calls + 1; return realGetText(k, a) end
    HT.overallWordOf(d); HT.overallWordOf(d); HT.overallWordOf(d)
    getText = realGetText
    check("the word is looked up once per read", calls == 1 and d.overallWord == "IGUI_health_Very_Minor_damage", calls)
end

-- ===========================================================================
section("HAIR: nothing to cut with, the rows still show")
-- ===========================================================================
-- (a forgiving world for this file alone: any global it reads that nobody set is a stand-in that takes any call)
local autoMT = {}
local function auto() return setmetatable({}, autoMT) end
autoMT.__index = function() return auto() end
autoMT.__call = function() return auto() end
autoMT.__concat = function() return "" end
-- the library's folded rows (Molecules.lua's ZeD.Disclose), with its own split for the default "folded"
local DS = { open = {} }
function DS.setting() return "folded" end
function DS.split(verbs)
    local shown, hidden = {}, {}
    for _, v in ipairs(verbs or {}) do
        if v.sensible ~= false then
            if v.canDo then shown[#shown + 1] = v else hidden[#hidden + 1] = v end
        end
    end
    return shown, hidden
end
function DS.isOpen(key) return key ~= nil and DS.open[key] == true end
function DS.setOpen(key, open) if key ~= nil then DS.open[key] = open and true or nil end end
function DS.toggle(key) DS.setOpen(key, not DS.isOpen(key)) end
function DS.needsLine(v) return "needs " .. tostring(v.needs) end
local HZ = setmetatable({
    T = ZeD.T, TM = ZeD.TM, tr = ZeD.tr, Atoms = ZeD.Atoms, Disclose = DS, Help = ZeD.Help,
    Molecules = { measureMoreRow = function() return 20 end, buttonW = function() return 40 end },
    MakeUp = { rows = function() return {} end },
    Settings = { hiddenActions = function() return "folded" end },
}, { __index = function() return auto() end })
local henv = setmetatable({ ZeD = HZ, getText = getText, tostring = tostring, getTimestampMs = getTimestampMs,
                            getItemNameFromFullType = function(ft) return ft end,
                            getActivatedMods = function() return { size = function() return 0 end } end },
    { __index = function(t, k)
        local v = _G[k]
        if v ~= nil then return v end
        return auto()
    end })
HZ.Atoms.radioSize = function() return 12 end
local okB, errB = load(CLIENT .. "ZeD_HairBeard.lua", henv)
check("ZeD_HairBeard.lua loads", okB, errB)
local HB = HZ.HairBeard
if okB and HB and HB.layout then
    -- the character carries nothing to cut or style with: every one of the 24 styles the game offers needs scissors
    local PL = { isFemale = function() return false end }
    local function newHair(nOk)
        local win = { _playerObj = PL }
        local st = HB.state(win)
        st.tick, st.player, st.female, st.part = 0, PL, false, "hair"
        st.rows = {}
        for i = 1, 24 do
            st.rows[i] = { key = "h:cut:Style" .. i, part = "hair", style = "Style" .. i, label = "Cut hair: Style " .. i,
                           ok = i <= nOk, req = "s", grp = "Cut", verb = "Cut", kind = "cut", level = 1 }
        end
        st.out, st.tools, st.counts = {}, {}, { hair = 24, beard = 0 }
        return win, st
    end
    local function rowsShown(L)
        local n, more = 0, nil
        for _, it in ipairs(L.items) do
            if it.kind == "row" then n = n + 1 elseif it.kind == "more" then more = it end
        end
        return n, more
    end
    DS.open = {}
    local win, st = newHair(0)
    st.tick = 0
    local L = HB.layout(win, 400)
    local n, more = rowsShown(L)
    check("nothing to cut with: the 24 styles show (grayed) under the open fold", n == 24 and more ~= nil, n)
    -- the player shuts the fold (A on it): it stays shut
    st.top, st.x = 0, 0
    local stop = nil
    for _, e in ipairs(HB.focusables(win)) do if e.id == "hb:more" then stop = e end end
    check("the folded row is a stop", stop ~= nil)
    if stop then stop.onActivate(win) end
    st.tick = 0
    n = rowsShown(HB.layout(win, 400))
    check("shut by the player, the fold stays shut", n == 0, n)
    -- a fresh look: open by itself; then scissors in the bag (one row can be done): it shuts again
    DS.open = {}
    win, st = newHair(0)
    st.tick = 0
    HB.layout(win, 400)
    for i = 1, 3 do st.rows[i].ok = true end
    st.tick = 0
    n = rowsShown(HB.layout(win, 400))
    check("once rows can be done, the fold that opened by itself shuts again", n == 3, n)
    -- opened by the player while rows could be done: it stays open
    DS.open = {}
    win, st = newHair(3)
    st.tick = 0
    HB.layout(win, 400)
    st.top, st.x = 0, 0
    for _, e in ipairs(HB.focusables(win)) do if e.id == "hb:more" then e.onActivate(win) end end
    st.tick = 0
    n = rowsShown(HB.layout(win, 400))
    check("opened by the player, the fold stays open", n == 24, n)
    -- shut by the player while rows could be done, then every tool lost: the fold opens by itself again (the
    -- shut made with rows showing does not hold over a list with no rows)
    st.top, st.x = 0, 0
    for _, e in ipairs(HB.focusables(win)) do if e.id == "hb:more" then e.onActivate(win) end end
    st.tick = 0
    n = rowsShown(HB.layout(win, 400))
    check("shut by the player with rows to do: the 3 rows, the fold shut", n == 3, n)
    for i = 1, 3 do st.rows[i].ok = false end
    st.tick = 0
    n = rowsShown(HB.layout(win, 400))
    check("then every tool lost: the fold opens by itself, the 24 styles show", n == 24, n)
    -- a shut made while nothing can be done still holds while nothing can be done
    st.top, st.x = 0, 0
    for _, e in ipairs(HB.focusables(win)) do if e.id == "hb:more" then e.onActivate(win) end end
    st.tick = 0
    n = rowsShown(HB.layout(win, 400))
    check("shut with nothing to do: it stays shut", n == 0, n)
end

-- ===========================================================================
section("WEIGHT: the license's weight sign says what it means")
-- ===========================================================================
do
    local idt = readFile(CLIENT .. "IdentityTab.lua") or ""
    check("the render asks the help line for the sign under the pointer",
        idt:find("local key = TREND_HELP[data.trend]", 1, true) ~= nil and idt:find("ZeD.Help.set(win, ZeD.tr(key))", 1, true) ~= nil)
    check("each sign has its words", idt:find('["+"] = "UI_ZeD_Identity_WeightUp"', 1, true) ~= nil
        and idt:find('["++"] = "UI_ZeD_Identity_WeightUpFast"', 1, true) ~= nil
        and idt:find('["-"] = "UI_ZeD_Identity_WeightDown"', 1, true) ~= nil)
    check("the sign's place is kept where it is drawn", idt:find("a.on, a.x, a.y, a.w, a.zoom = true, x, y, w, zoom", 1, true) ~= nil
        and idt:find("drawWeight(panel, data, x + w - wt, y, zoom, ink, sign, wt)", 1, true) ~= nil
        and idt:find("drawWeight(panel, data, tx, ty, zoom, tc, T.accentText, wt)", 1, true) ~= nil)
    local LANGS = { "EN", "AR", "CA", "CH", "CN", "CS", "DA", "DE", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT",
        "JP", "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
    local missing = {}
    for _, l in ipairs(LANGS) do
        local j = readFile(ROOT .. "42/media/lua/shared/Translate/" .. l .. "/UI.json") or ""
        for _, k in ipairs({ "UI_ZeD_Identity_WeightUp", "UI_ZeD_Identity_WeightUpFast", "UI_ZeD_Identity_WeightDown" }) do
            if not j:find('"' .. k .. '": "[^"]+"') then missing[#missing + 1] = l .. ":" .. k end
        end
    end
    check("the three lines in all 28 languages", #missing == 0, table.concat(missing, " "))
    local ctx = readFile(ROOT .. "ZeDUI/i18n/UI_ZeD.context.md") or ""
    check("the context file says where they show", ctx:find("`UI_ZeD_Identity_WeightUpFast` | `Gaining weight fast.`", 1, true) ~= nil)
end

print(string.format("fix_tabfill_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
