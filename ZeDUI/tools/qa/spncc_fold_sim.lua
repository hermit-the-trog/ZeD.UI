-- ZeDUI/tools/qa/spncc_fold_sim.lua  (Nov 6 2026, QA): Spongie's Character Customization, the folds (FAIV's long list of add-on
-- details), with no game running. The real ModSupport/SPNCC.lua, ZeD_MainMenuOptions.lua and ZeD_MainMenuLooks.lua run on Lua 5.1
-- stubs of the library, the mod's menus and a panel. The Appearance tab and the Looks screen each draw, fold and open, and
-- what the controller sees and what Save sends are read back. What it can't show is how it looks and the game's own focus
-- manager: zedqa_spncc.lua and zedqa_spncc_looks.lua, in the game.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/spncc_fold_sim.lua
-- It prints FAIL lines and a last line "spncc_fold_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]spncc_fold_sim%.lua$", "")

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
local COLOR = { r = 0.5, g = 0.5, b = 0.5, a = 1 }

-- ---------------------------------------------------------------------------
-- THE STUBS
-- ---------------------------------------------------------------------------
local heads, helped, saved, sounds = {}, {}, {}, 0
local mouse = { x = -1, y = -1 }

local function list(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end }
end
local function anyNoop() return setmetatable({}, { __index = function() return noop end }) end

Events = setmetatable({}, { __index = function() return { Add = noop, Remove = noop } end })
getActivatedMods = function() return list({ "SPNCC" }) end
getText = function(k) return k end
getMouseX, getMouseY = function() return mouse.x end, function() return mouse.y end
isClient, isServer = function() return false end, function() return false end
local debugOn = true
isDebugEnabled = function() return debugOn end
isAdmin = function() return false end
getModInfoByID = function() return nil end
getSoundManager = function() return { playUISound = function() sounds = sounds + 1 end } end
SandboxVars = { SPNCharCustom = { AllowCustomisationChange = 1 } }
Perks = { Strength = 1 }
ItemTag = {}
IsoDirections = { S = 1 }
ISUI3DModel = anyNoop()
ISCharacterScreen = {}
ISPanel = {}

local MODS = {}
local realRequire = require
require = function(name)
    if MODS[name] then return MODS[name] end
    return nil
end

ZeD_ScrollbarState = { new = function()
    return { scrollPos = 0, visible = false, x = 0, y = 0, width = 12, height = 0,
        setScrollPos = function(self, v) self.scrollPos = math.max(0, math.min(1, v)) end, setBarSize = noop, draw = noop, handleMouseDown = noop }
end }

local tabs = {}
ZeD_CharacterWindow = { addTab = function(t) tabs[t.id] = t end, getWindow = function() return nil end, isOpen = function() return false end }

local T = setmetatable({
    px = function(n) return n end, sp = { scrollbarW = 12, afterGroove = 4, sm = 6, xs = 3, inputPadX = 6 },
    buttonH = 24, checkboxSz = 14, grooveH = 2, selectionA = 0.3, disabledAlpha = 0.5, hair = 1, titleBarH = 24,
}, { __index = function() return COLOR end })

local F2 = 16
ZeD = {
    T = T,
    TM = { getFontHeight = function() return F2 end, MeasureStringX = function(_, _, s) return #tostring(s) * 7 end },
    tr = function(k, ...)
        local a = { ... }
        return k .. (a[1] and (":" .. tostring(a[1])) or "")
    end,
    textCase = function(s) return s end,
    btnCase = function(s) return s end,
    Help = { set = function(_, s) helped[#helped + 1] = s end },
    Atoms = setmetatable({
        mouseIn = function(_, x, y, w, h) return mouse.x >= x and mouse.x < x + w and mouse.y >= y and mouse.y < y + h end,
        truncateText = function(s) return s end,
        wrapText = function(s) return { s } end,
        radioSize = function() return 12 end,
    }, { __index = function() return noop end }),
    Molecules = setmetatable({
        getTabHeaderH = function() return 30 end,
        bandH = function() return 40 end,
        drawSectionHeader = function(_, x, y, w, text, count, expanded, hovered, font, countInline, bleed, hh, noArrow, opts)
            heads[#heads + 1] = { x = x, y = y, w = w, text = text, count = count, expanded = expanded, hovered = hovered, countInline = countInline,
                noArrow = noArrow, focus = opts and opts.focus }
            return 20
        end,
        drawBand = function(_, x, y, w, spec)
            local out = { buttons = {} }
            for i in ipairs(spec.buttons) do out.buttons[i] = { x = x + i * 80, y = y, w = 70, h = 24 } end
            return 40, out
        end,
    }, { __index = function() return noop end }),
    Focus = { mark = function() return false end },
    Input = { Focus = {} },
    Surface = { fill = noop },
    Safe = {},
    TabPx = {},
}
-- (Atoms.lua's: a window's player number, split view)
ZeD.playerNumOf = function(w) local p = w and w._playerObj; return p and p.getPlayerNum and p:getPlayerNum() or 0 end

local function panelStub()
    return setmetatable({ getMouseX = function() return mouse.x end, getMouseY = function() return mouse.y end,
        getWidth = function() return 800 end, getHeight = function() return 600 end }, { __index = function() return noop end })
end

local function option(name, extra)
    local o = { name = name, display = name, id = "Item" .. name, texture = 0, sort = name, bodylocation = "Loc" .. name }
    for k, v in pairs(extra or {}) do o[k] = v end
    return o
end
local function dict(prefix, n)
    local t = {}
    for i = 1, n do t[prefix .. i] = option(prefix .. string.format("%02d", i)) end
    return t
end

local faceDict, detDict = dict("Face", 3), dict("Det", 12)
MODS["CharacterCustomisation/SPNCC_Data"] = {
    GetFacesForCharacter = function() return faceDict end,
    GetBodyDetailsForCharacter = function() return detDict end,
}
MODS["CharacterCustomisation/FaceManager_Shared"] = { GetMuscleLevel = function() return 0 end }
MODS["CharacterCustomisation/FaceManager/Main"] = { SetCustomisation = function(_, d) saved[#saved + 1] = d end }

-- ---------------------------------------------------------------------------
-- THE REAL FILES
-- ---------------------------------------------------------------------------
dofile(ROOT .. "42/media/lua/client/ZeD/ModSupport/SPNCC.lua")
local S = ZeD.ModSupport.SPNCC
check("the support loaded", S ~= nil and S.looksRows ~= nil)

-- ---------------------------------------------------------------------------
-- THE APPEARANCE TAB
-- ---------------------------------------------------------------------------
local function newPlayer()
    local md = { SPNCharCustom = { face = { name = "Face01" }, bodyDetails = {}, muscleVisuals = true } }
    return {
        getModData = function() return md end,
        getInventory = function() return { containsEvalRecurse = function() return false end } end,
        isFemale = function() return false end,
        getPerkLevel = function() return 0 end,
    }
end
local panel = panelStub()
local function newWin() return { _playerObj = newPlayer(), _activeTab = "appearance", _drawerMode = "tab" } end
local function draw(win)
    heads, helped = {}, {}
    S.render(panel, win, 0, 0, 800, 600)
    return win._spncc
end
local function head(text)
    for _, h in ipairs(heads) do if h.text == text then return h end end
    return nil
end
local function stops(win)
    local ids, at = {}, {}
    for i, e in ipairs(S.buildFocusables(win)) do ids[i] = e.id; at[e.id] = e end
    return ids, at
end
local function countPrefix(ids, p)
    local n = 0
    for _, id in ipairs(ids) do if string.sub(id, 1, #p) == p then n = n + 1 end end
    return n
end
local function indexOf(ids, id)
    for i, x in ipairs(ids) do if x == id then return i end end
    return nil
end
local function tilesOf(st, kind)
    local n = 0
    for _, t in ipairs(st.tiles) do if t.kind == kind then n = n + 1 end end
    return n
end

local DET, FACE = "UI_characreation_bodydetail", "UI_characreation_face"

section("the tab: what it starts as")
local win = newWin()
local st = draw(win)
local keyStart = S.scrollKey(win)
local ids, at = stops(win)
check("Details shut", head(DET) and head(DET).expanded == false and head(DET).noArrow == nil)
check("Face open", head(FACE) and head(FACE).expanded == true and head(FACE).noArrow == nil)
check("the count reads after the name", head(DET).count == 0 and head(DET).countInline == true)
check("no detail stops", countPrefix(ids, "spn:det:") == 0, countPrefix(ids, "spn:det:"))
check("no detail figures", tilesOf(st, "det") == 0)
check("the faces are stops", countPrefix(ids, "spn:face:") == 3)
check("each head is a stop", at["spn:fold:det"] ~= nil and at["spn:fold:face"] ~= nil)
check("reading order: Face's head, its tiles, Details' head", indexOf(ids, "spn:fold:face") < indexOf(ids, "spn:face:Face01")
    and indexOf(ids, "spn:face:Face03") < indexOf(ids, "spn:fold:det"))

section("the tab: A on Details")
at["spn:fold:det"].onActivate(win, at["spn:fold:det"])
st = draw(win)
ids, at = stops(win)
check("it opens", head(DET).expanded == true)
check("every tile is a stop", countPrefix(ids, "spn:det:") == 12, countPrefix(ids, "spn:det:"))
check("the figures come", tilesOf(st, "det") > 0)
check("the focus list refreshes", S.scrollKey(win) ~= keyStart)
local keyOpen = S.scrollKey(win)
at["spn:det:Det01"].onActivate(win, at["spn:det:Det01"])
at["spn:det:Det05"].onActivate(win, at["spn:det:Det05"])
draw(win)
check("the count follows", head(DET).count == 2)
ids, at = stops(win)
at["spn:fold:det"].onActivate(win, at["spn:fold:det"])
st = draw(win)
ids, at = stops(win)
check("it shuts", head(DET).expanded == false)
check("the count stays", head(DET).count == 2)
check("the stops go", countPrefix(ids, "spn:det:") == 0)
check("the figures go", tilesOf(st, "det") == 0)
check("the head keeps its stop", at["spn:fold:det"] ~= nil)

section("the tab: Save with the details hidden keeps the picks")
check("Save is there", at["spn:save"] ~= nil)
at["spn:save"].onActivate(win, at["spn:save"])
local sent = saved[#saved]
local names = {}
for _, d in ipairs(sent and sent.bodyDetails or {}) do names[#names + 1] = d.name end
table.sort(names)
check("both picks go to the mod", table.concat(names, ",") == "Det01,Det05", table.concat(names, ","))

section("the tab: a tile under the pointer goes with its fold")
S.closed.det = false
st = draw(win)
st.hover = st.tiles[#st.tiles]
ids, at = stops(win)
at["spn:fold:det"].onActivate(win, at["spn:fold:det"])
check("the stale hover is dropped", st.hover == nil)
check("the head is pinned in view again", st.lastPinned == nil)

section("the tab: Face folds too")
ids, at = stops(win)
at["spn:fold:face"].onActivate(win, at["spn:fold:face"])
st = draw(win)
ids, at = stops(win)
check("it shuts", head(FACE).expanded == false)
check("no face stops", countPrefix(ids, "spn:face:") == 0)
check("the face pick stays", st.face == "Face01", st.face)
check("the two heads sit together", head(DET).y - head(FACE).y == 24, head(DET).y - head(FACE).y)
S.closed.face = false

section("the tab: a click, and the pointer's help")
st = draw(win)
local dh = head(DET)
mouse.x, mouse.y = dh.x + 5, dh.y + 5
draw(win)
check("hover washes the head", head(DET).hovered == true)
check("and says what a click does", helped[#helped] == "UI_ZeD_ETW_HelpCatShow:" .. DET, helped[#helped])
S.onClick(win, dh.x + 5, dh.y + 5)
draw(win)
check("a click opens it", head(DET).expanded == true)
check("the help follows", helped[#helped] == "UI_ZeD_ETW_HelpCatHide:" .. DET, helped[#helped])
mouse.x, mouse.y = -1, -1
S.closed.det = true

section("the tab: the List view folds the same")
S.view = "list"
st = draw(win)
ids = stops(win)
check("shut, no rows", countPrefix(ids, "spn:det:") == 0)
S.closed.det = false
draw(win)
ids = stops(win)
check("open, a row each", countPrefix(ids, "spn:det:") == 12)
S.view, S.closed.det = "grid", true

section("the tab: read-only (no changes in game)")
debugOn = false
SandboxVars.SPNCharCustom.AllowCustomisationChange = 4
local ro = newWin()
ro._playerObj.getModData().SPNCharCustom.bodyDetails = { { name = "Det02" } }
st = draw(ro)
ids, at = stops(ro)
check("nothing to pick", st.canDet == false and countPrefix(ids, "spn:det:") == 0)
check("the head still folds what's worn", at["spn:fold:det"] ~= nil and head(DET).count == 1)
at["spn:fold:det"].onActivate(ro, at["spn:fold:det"])
st = draw(ro)
ids = stops(ro)
check("open, it shows the one worn, no stop", tilesOf(st, "det") == 1 and countPrefix(ids, "spn:det:") == 0)
debugOn = true
SandboxVars.SPNCharCustom.AllowCustomisationChange = 1
S.closed.det = true

section("the tab: nothing to fold")
local keepDets = detDict
detDict = {}
local empty = newWin()
st = draw(empty)
ids, at = stops(empty)
check("no details: the head stays still", head(DET).noArrow == true and at["spn:fold:det"] == nil)
detDict = keepDets

-- the tab holds its scroll as a share of its height, and a fold changes the height: the head has to stay where it was pressed
section("the tab: a fold keeps its head where it was pressed")
local keepFaces, keepDet2 = faceDict, detDict
faceDict, detDict = dict("Face", 12), dict("Det", 60)
local function drawAt(w, h)
    heads, helped = {}, {}
    S.render(panel, w, 0, 0, 480, h)
    return w._spncc
end
local function inView(name, h, text)
    local hd = head(text)
    local top, bot = 30, h - 40
    check(name, hd ~= nil and hd.y >= top and hd.y + 20 <= bot, hd and hd.y)
end
local function stays(name, y, text)
    local hd = head(text)
    check(name, hd ~= nil and math.abs(hd.y - y) <= 1, hd and hd.y)
end
local Fo = ZeD.Input.Focus
-- the pad: the head under the bottom edge, the D-pad onto it, A
do
    S.closed.face, S.closed.det = false, true
    local w = newWin()
    st = drawAt(w, 500)
    check("the head starts under the view", head(DET) == nil)
    local _, a2 = stops(w)
    local el = a2["spn:fold:det"]
    Fo.getFocusedWindow, Fo.getFocusedElement = function() return w end, function() return el end
    drawAt(w, 500)
    drawAt(w, 500)
    inView("the D-pad brings it in", 500, DET)
    local y0 = head(DET).y
    el.onActivate(w, el)
    drawAt(w, 500)
    check("it opened", head(DET) and head(DET).expanded == true)
    stays("A: the head stays put", y0, DET)
    drawAt(w, 500)
    stays("and the next frame", y0, DET)
    check("the anchor is spent", w._spncc.foldAnchor == nil)
    el.onActivate(w, el)
    drawAt(w, 500)
    check("it shut", head(DET) and head(DET).expanded == false)
    inView("A again: still in view", 500, DET)
    Fo.getFocusedWindow, Fo.getFocusedElement = nil, nil
end
-- the mouse, wheeled to the bottom with both lists as they start
do
    S.closed.face, S.closed.det = false, true
    local w = newWin()
    st = drawAt(w, 600)
    st.scroll:setScrollPos(1)
    drawAt(w, 600)
    local dh = head(DET)
    check("the head is there at the bottom", dh ~= nil)
    local y0 = dh.y
    S.onClick(w, dh.x + 5, dh.y + 5)
    st = drawAt(w, 600)
    check("a click opens it", head(DET) and head(DET).expanded == true)
    stays("the head stays put, not at the list's end", y0, DET)
    check("the scroll holds", st.scroll.scrollPos < 1, st.scroll.scrollPos)
    -- and shut again, from a little way down an open list
    S.onClick(w, dh.x + 5, y0 + 5)
    st = drawAt(w, 600)
    check("a click shuts it", head(DET) and head(DET).expanded == false)
    stays("shut, it hasn't moved", y0, DET)
end
-- shutting Details from the top of an open list
do
    S.closed.face, S.closed.det = false, false
    local w = newWin()
    st = drawAt(w, 500)
    st.scroll:setScrollPos(0.05)
    drawAt(w, 500)
    local dh = head(DET)
    check("the head is in view", dh ~= nil)
    local y0 = dh.y
    S.onClick(w, dh.x + 5, dh.y + 5)
    drawAt(w, 500)
    stays("shutting: it doesn't drop down the view", y0, DET)
end
-- shut with the head at the very top: the list ends sooner than the place it was, and the head still shows
do
    S.closed.face, S.closed.det = false, false
    local w = newWin()
    st = drawAt(w, 600)
    local _, a3 = stops(w)
    local cy = a3["spn:fold:det"].cy
    local L = st.scroll
    local maxOff = cy / 0.5
    for _ = 1, 40 do
        L:setScrollPos(math.min(1, (cy - 2) / maxOff))
        drawAt(w, 600)
        if head(DET) then break end
        maxOff = maxOff * 1.25
    end
    local dh = head(DET)
    check("the head is near the top", dh ~= nil)
    S.onClick(w, dh.x + 5, dh.y + 5)
    drawAt(w, 600)
    inView("the end of the list comes up to it, in view", 600, DET)
end
-- Face, with Details open below it
do
    S.closed.face, S.closed.det = false, false
    local w = newWin()
    st = drawAt(w, 500)
    st.scroll:setScrollPos(0.005)
    drawAt(w, 500)
    local fh = head(FACE)
    check("Face's head shows", fh ~= nil)
    local y0 = fh.y
    S.onClick(w, fh.x + 5, fh.y + 5)
    drawAt(w, 500)
    check("Face shut", head(FACE) and head(FACE).expanded == false)
    stays("Face stays put too", y0, FACE)
end
-- a tab that doesn't scroll, before and after
do
    S.closed.face, S.closed.det = true, true
    local w = newWin()
    drawAt(w, 500)
    local fh = head(FACE)
    local y0 = fh.y
    S.onClick(w, head(DET).x + 5, head(DET).y + 5)
    st = drawAt(w, 500)
    stays("from the top, the top stays", y0, FACE)
    check("no anchor left", st.foldAnchor == nil)
    S.onClick(w, head(DET).x + 5, head(DET).y + 5)
    st = drawAt(w, 500)
    check("shut, back at the top", st.off == 0 and st.scroll.scrollPos == 0, st.off)
end
faceDict, detDict = keepFaces, keepDet2
S.closed.face, S.closed.det = nil, true

-- ---------------------------------------------------------------------------
-- THE LOOKS SCREEN: the rows
-- ---------------------------------------------------------------------------
section("the Looks rows")
local function looksMenu()
    local menu = { options = detDict, selectedOptions = {}, lockedOptionsVisible = false }
    function menu.setSelected(self, o)
        if self.selectedOptions[o.name] then self.selectedOptions[o.name] = nil else self.selectedOptions[o.name] = o end
    end
    return menu
end
local updates = 0
local look = {
    spn_update_character_customisation = function() updates = updates + 1 end,
    characterCustomisationPanel = {
        faceMenu = { options = faceDict, getSelectedOption = function() return nil end, setSelectedOption = noop },
        bodyDetailMenu = looksMenu(),
    },
}
local function looksRows()
    local rows = {}
    S.looksRows(look, rows, function(t) rows[#rows + 1] = { kind = "header", text = t } end)
    return rows
end
local function foldHead(rows)
    for _, r in ipairs(rows) do if r.onFold then return r end end
    return nil
end
local function ticks(rows)
    local n = 0
    for _, r in ipairs(rows) do if r.kind == "tick" then n = n + 1 end end
    return n
end
local rows = looksRows()
local fh = foldHead(rows)
check("a Details head that folds, the game's word", fh ~= nil and fh.kind == "header" and fh.text == DET)
check("shut, none picked", fh.shut == true and fh.count == 0)
check("shut, the ticks aren't built", ticks(rows) == 0, ticks(rows))
check("Face's head doesn't fold", rows[1].kind == "header" and rows[1].text == FACE and rows[1].onFold == nil)
fh.onFold()
rows = looksRows()
fh = foldHead(rows)
check("open, a tick each", fh.shut == false and ticks(rows) == 12, ticks(rows))
for _, r in ipairs(rows) do
    if r.kind == "tick" and (r.label == "Det03" or r.label == "Det07") then r.control.changeOptionMethod(nil, 1, true) end
end
rows = looksRows()
fh = foldHead(rows)
check("the head counts the picks", fh.count == 2, fh.count)
fh.onFold()
rows = looksRows()
fh = foldHead(rows)
check("shut again, the picks stay", fh.count == 2 and fh.shut == true and ticks(rows) == 0)
check("in the mod's own menu", look.characterCustomisationPanel.bodyDetailMenu.selectedOptions.Det03 ~= nil
    and look.characterCustomisationPanel.bodyDetailMenu.selectedOptions.Det07 ~= nil)
check("each pick told the mod, a fold never did", updates == 2, updates)
check("the Looks screen keeps its own fold", S.closed.det == true and S.closed.looks == true)

-- ---------------------------------------------------------------------------
-- THE LOOKS SCREEN: the shared rows' drawing and the controller
-- ---------------------------------------------------------------------------
local gamepad = false
local clicks, joyDirs = 0, {}
local MM = setmetatable({
    ctx = {}, U = {}, views = {},
    ui = setmetatable({ plain = function(s) return s end }, { __index = function() return noop end }),
    optionGroups = setmetatable({ text = function(s) return s end }, { __index = function() return noop end }),
    gamepad = function() return gamepad end,
    fontH = function() return F2 end,
    textW = function(_, s) return #tostring(s) * 7 end,
    clickSound = function() clicks = clicks + 1 end,
    hoverSound = noop,
    rowLook = function() return false end,
    focusOpts = function() return { pad = true } end,
}, { __index = function() return noop end })
ZeD.MainMenu = MM
ZeD.PadGlyphs = nil

local function derive(base, name)
    local c = {}
    c.__index = c
    c.Type = name
    c.derive = derive
    return setmetatable(c, { __index = base })
end
ISPanel.derive = derive
ZeD_Window = derive(nil, "ZeD_Window")
ZeD_MMWindow = derive(ZeD_Window, "ZeD_MMWindow")
function ZeD_MMWindow.joyDir(self, dir) joyDirs[#joyDirs + 1] = dir end
MainScreen = { onMenuItemMouseDownMainMenu = noop }

dofile(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenuOptions.lua")
dofile(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenuLooks.lua")

local function looksWindow()
    local W = setmetatable({ kind = "looks", scroll = 0, _specs = {}, _hits = {}, noHelpBand = false }, ZeD_MMLooks)
    W.getAbsoluteX, W.getAbsoluteY = function() return 0 end, function() return 0 end
    for _, m in ipairs({ "setStencilRect", "clearStencilRect", "drawRect", "drawText", "drawControl", "drawRectBorder" }) do W[m] = noop end
    return W
end
-- a row above, Details, a row and a head below: what rowsNow makes of the Looks screen
local function screenRows()
    local out = {
        { kind = "header", text = "Name" },
        { kind = "combo", label = "Sex", control = { options = { "a" }, selected = 1 } },
    }
    for _, r in ipairs(looksRows()) do out[#out + 1] = r end
    out[#out + 1] = { kind = "header", text = "Hair" }
    out[#out + 1] = { kind = "combo", label = "Style", control = { options = { "a" }, selected = 1 } }
    return out
end
local function drawScreen(W, h)
    heads = {}
    W._specs, W._hits = {}, {}
    W:drawRows(0, 0, 800, h or 560, screenRows(), nil, false)
end
local function headDrawn(text)
    for _, x in ipairs(heads) do if x.text == text then return x end end
    return nil
end
local function headSpec(W)
    for _, b in ipairs(W._specs) do if b.rowRef and b.rowRef.onFold then return b end end
    return nil
end
local function foldHit(W)
    for _, h in ipairs(W._hits) do if string.find(h.id, ":fold", 1, true) then return h end end
    return nil
end

section("the shared rows: a fold head")
local W = looksWindow()
S.closed.looks = true
drawScreen(W)
local dh2 = headDrawn(DET)
check("the triangle, shut", dh2 ~= nil and dh2.expanded == false and dh2.noArrow == false)
check("Details (2)", dh2.count == 2 and dh2.countInline == true)
check("a plain head draws as it did", headDrawn("Name").noArrow == true and headDrawn("Name").count == nil and headDrawn("Name").expanded == true)
local b = headSpec(W)
check("it's a stop", b ~= nil and b.listRow == true and b.col == 1)
local order = {}
for _, s in ipairs(W._specs) do order[s.row] = s.rowRef end
check("in reading order: Sex, the Face row, the head, the row below", order[1].label == "Sex" and order[2].label == FACE
    and order[3].onFold ~= nil and order[4].label == "Style")
check("a plain head is no stop", #W._specs == 4, #W._specs)
check("a click target over the head", foldHit(W) ~= nil and foldHit(W).sound == true)

section("the shared rows: the controller")
gamepad = true
W.focusId = b.id
drawScreen(W)
check("the controller's mark", headDrawn(DET).focus ~= nil)
check("the help band's row is the head", W:focusedRow() ~= nil and W:focusedRow().onFold ~= nil)
local prompts = W:getFooterPrompts()
check("A says Toggle", prompts[1].glyph == "A" and prompts[1].label == "UI_ZeD_Options_PromptToggle", prompts[1].label)
local wasClosed = S.closed.looks
W:joyDir("left")
W:joyDir("right")
check("left and right don't fold", S.closed.looks == wasClosed)
check("they move on, between the columns", #joyDirs == 2 and joyDirs[1] == "left" and joyDirs[2] == "right")
local fid = b.id
b.fn()
check("A opens it, with the click", S.closed.looks == false and clicks == 1)
drawScreen(W)
check("the head keeps its stop's id", headSpec(W).id == fid)
check("open, the ticks are stops", #W._specs == 16, #W._specs)
local firstTick = 99
for _, s in ipairs(W._specs) do if s.rowRef.kind == "tick" then firstTick = math.min(firstTick, s.row) end end
check("the head comes before its ticks", headSpec(W).row + 1 == firstTick, firstTick)
headSpec(W).fn()
drawScreen(W)
check("A shuts it: the ticks drop out", #W._specs == 4, #W._specs)
check("the stops stay in order", headSpec(W).id == fid)
gamepad = false

section("the shared rows: the pointer")
foldHit(W).fn()
check("a click toggles", S.closed.looks == false and clicks == 3, clicks)
drawScreen(W)
foldHit(W).fn()
drawScreen(W)
MM.ctx.hot = foldHit(W).id
drawScreen(W)
check("the hover wash", headDrawn(DET).hovered == true)
MM.ctx.hot = nil

section("the shared rows: a head half scrolled out")
S.closed.looks = false
W.scroll = 0
drawScreen(W)
local y0 = headDrawn(DET).y
W.scroll = y0 + 5
drawScreen(W, 200)
check("the list did scroll", W.scroll == y0 + 5, W.scroll)
check("not drawn, no click target", headDrawn(DET) == nil and foldHit(W) == nil)
check("still a stop, so the D-pad can bring it back", headSpec(W) ~= nil)
S.closed.looks = true

section("a page with no fold heads keeps its rows' numbers")
local plain = setmetatable({ kind = "options", scroll = 0, _specs = {}, _hits = {} }, ZeD_MMOptions)
plain.getAbsoluteX, plain.getAbsoluteY = W.getAbsoluteX, W.getAbsoluteY
plain.drawHelp = noop
plain.isChanged = function() return false end
for _, m in ipairs({ "setStencilRect", "clearStencilRect", "drawRect", "drawText", "drawControl" }) do plain[m] = noop end
plain:drawRows(0, 0, 800, 560, { { kind = "header", text = "A" }, { kind = "combo", label = "x", control = { options = {}, selected = 1 } },
    { kind = "header", text = "B" }, { kind = "combo", label = "y", control = { options = {}, selected = 1 } } }, nil, false)
check("two rows, two stops, numbered as ever", #plain._specs == 2 and plain._specs[1].id == "orow:1" and plain._specs[2].id == "orow:2")
check("no fold target", #plain._hits == 0)

print("spncc_fold_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
