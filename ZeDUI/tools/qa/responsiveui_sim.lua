-- ZeDUI/tools/qa/responsiveui_sim.lua  (Nov 9 2026): ZeD's right-click menu under Responsive Context Menus
-- (ResponsiveUI, Workshop 3783387236) with no game running. The mod's own two files run as they are (its
-- RefreshController and its Client hooks), on the game's own ISContextMenu functions (get, clear, the option
-- and submenu calls, hide and highlight, cut out of ISContextMenu.lua) and ZeD's real Registry, Overrides,
-- strip, list and ModSupport/ResponsiveUI.lua. Panels and drawing are stubs; an inventory menu builder stands
-- in for the game's (Read greyed in the dark, Put in Container with a crate submenu greyed out of range, a
-- Lamp submenu and a Toggle light row that keep the menu open).
--   BUG     the mod on, ZeD's support off: each rebuild closes ZeD's menu and a new one opens at row 1
--   STRIP   a rebuild keeps the same strip open, in place: new labels, Read no longer greyed, the balloon's words
--           and the selection (by name) kept, the lit outline back on the new option in the same tick
--   SUBPATH an open submenu (Put in Container) stays open through a rebuild, its selected crate kept
--   LIST    the list: the same, levels, places and selection kept
--   KEEP    a keep-open option (strip, and in the list's submenu) keeps the menu and its submenu after the
--           pick, and the mod rebuilds it at once
--   PRESS   a press reaching the hidden game menu does not end the mod's watch while ZeD's menu is up
--   GONE    the item gone: the mod closes the menu, and ZeD's goes with it
--   OFF     neither mod: a clear closes ZeD's menu, a keep-open row closes the strip, the game's outside press
--           is the game's own, no hooks set
-- Run from the repo root: lua51 ZeDUI/tools/qa/responsiveui_sim.lua ["ISContextMenu.lua"] ["ResponsiveUI mod folder"]
local GAME = arg and arg[1] or "E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/lua/client/ISUI/ISContextMenu.lua"
local RUI = arg and arg[2] or "E:/Project Zomboid/SteamApps/workshop/content/108600/3783387236/mods/ResponsiveUI"
local ZD = "42/media/lua/client/ZeD/"

local function slurp(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return (s:gsub("\r", "")) end
local function cut(src, head)
    local a = assert(src:find(head, 1, true), head)
    local _, b = src:find("\nend\n", a, true)
    return src:sub(a, b)
end
local VAN = slurp(GAME)
SLIDEY = 10
table.wipe = table.wipe or function(t) for k in pairs(t) do t[k] = nil end end
local VFN = {
    "ISContextMenu.get = function(player, x, y)", "function ISContextMenu:clear()", "function ISContextMenu:hideSelf()",
    "function ISContextMenu:hideAndChildren()", "function ISContextMenu:checkHighlightedOption(",
    "function ISContextMenu:callOptionHighlightFunction(", "function ISContextMenu:allocOption(",
    "function ISContextMenu:addOption(", "function ISContextMenu:addSubMenu(", "function ISContextMenu:isEmpty()",
    "function ISContextMenu:getSubMenu(", "function ISContextMenu:getSubInstance(", "function ISContextMenu:getNew(",
    "function ISContextMenu:onMouseDownOutside(", "function ISContextMenu:closeAll()", "function ISContextMenu:isAnyVisible()",
    "function ISContextMenu:isOptionSingleMenu()", "function ISContextMenu:addDefaultOptions()",
    "function ISContextMenu:calcWidth()", "function ISContextMenu:onJoypadDown(",
}

local pass, fail = 0, 0
local function ok(c, name) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. name) end end

-- ---------------------------------------------------------------------------
-- one game: every global fresh, the files loaded in the game's order (ResponsiveUI/ before ZeD/)
-- ---------------------------------------------------------------------------
local W, NOW, EV, ROOT, HL, STYLE, ACTIVE
local function newEvent()
    local e = { list = {} }
    e.Add = function(f) e.list[#e.list + 1] = f end
    e.Remove = function(f) for i = #e.list, 1, -1 do if e.list[i] == f then table.remove(e.list, i) end end end
    return e
end
local function frame()
    for _, f in ipairs(EV.OnTick.list) do f() end
    if ROOT:getIsVisible() then ROOT:prerender() end
end

local CONT = { isInCharacterInventory = function() return true end, contains = function() return W.has end }
local ITEM = { _cls = "InventoryItem", getContainer = function() return CONT end }

local function game(withRui, withZedSupport)
    W = { light = false, inRange = false, has = true, reads = 0 }
    NOW, HL, STYLE = 1000, {}, 1
    ACTIVE = withZedSupport and { "ZeD_UI", "ResponsiveUI" } or { "ZeD_UI" }
    for _, k in ipairs({ "ZeD", "ResponsiveUI", "ISContextMenu", "ZeD_ContextMenu", "ZeD_ContextList", "ZeD_Panel" }) do _G[k] = nil end
    require = function() end
    getTimestampMs = function() return NOW end
    getText = function(k) return k end
    getTexture = function() return nil end
    log, DebugType = function() end, { Lua = 1 }
    Keyboard, Joypad = { KEY_ESCAPE = 1, KEY_LEFT = 2, KEY_RIGHT = 3, KEY_RETURN = 4, KEY_BACK = 5, KEY_TAB = 6, KEY_UP = 7, KEY_DOWN = 8 }, { AButton = 1, BButton = 2 }
    GameKeyboard = { eatKeyPress = function() end }
    JoypadState = { players = {} }
    getMouseX, getMouseY = function() return 300 end, function() return 400 end
    isMouseButtonDown = function() return false end
    isGamePaused = function() return false end
    UIManager = { getSpeedControls = function() return { getCurrentGameSpeed = function() return 1 end } end }
    instanceof = function(o, c) return type(o) == "table" and o._cls == c end
    getActivatedMods = function()
        return { size = function() return #ACTIVE end, get = function(_, i) return ACTIVE[i + 1] end }
    end
    local core = { getGameMode = function() return "Sandbox" end, isTutorial = function() return false end,
        getOptionSingleContextMenu = function() return false end, getScreenWidth = function() return 1920 end,
        getScreenHeight = function() return 1080 end, getZoom = function() return 1 end, setDisplayCursor = function() end,
        isKey = function() return false end, getKey = function() return 1 end }
    getCore = function() return core end
    getTextManager = function() return { MeasureStringX = function(_, _, s) return 7 * #tostring(s) end } end
    local PLAYER = { isDead = function() return false end, getModData = function() return {} end }
    getSpecificPlayer = function() return PLAYER end
    EV = { OnTick = newEvent(), OnKeyStartPressed = newEvent(), OnFillInventoryObjectContextMenu = newEvent(), OnGameStart = newEvent() }
    Events = EV

    -- the game's menu: its own functions on a stub panel
    ISContextMenu = {}
    ISContextMenu.__index = ISContextMenu
    function ISContextMenu:new(x, y, w, h)
        return setmetatable({ x = x or 0, y = y or 0, width = w or 100, height = h or 0, visible = false, options = {},
            optionPool = {}, numOptions = 1, itemHgt = 20, font = 1, mouseOver = -1, player = 0 }, ISContextMenu)
    end
    for _, n in ipairs({ "initialise", "instantiate", "addToUIManager", "removeFromUIManager", "bringToTop", "setFontFromOption",
        "setForceCursorVisible", "hideToolTip", "calcHeight", "onMouseUp", "setHeight" }) do ISContextMenu[n] = function() end end
    function ISContextMenu:setVisible(v) self.visible = v end
    function ISContextMenu:isVisible() return self.visible end
    function ISContextMenu:getIsVisible() return self.visible end
    function ISContextMenu:setX(v) self.x = v end
    function ISContextMenu:setY(v) self.y = v end
    function ISContextMenu:getX() return self.x end
    function ISContextMenu:getY() return self.y end
    function ISContextMenu:setWidth(v) self.width = v end
    function ISContextMenu:setSlideGoalX() end
    function ISContextMenu:setSlideGoalY() end
    function ISContextMenu:prerender() end
    function ISContextMenu:render() end
    function ISContextMenu:onMouseMoveOutside() end
    for _, h in ipairs(VFN) do assert(loadstring(cut(VAN, h)))() end
    ROOT = ISContextMenu:new(0, 0, 100, 0)
    ROOT.instanceMap, ROOT.subMenuPool = {}, {}
    getPlayerContextMenu = function() return ROOT end
    ISInventoryPage = { OnObjectHighlighted = function() end }
    ISWorldObjectContextMenu = { createMenu = function() return nil end }
    local mgr = { createWorldMenu = function() return nil end }
    ISContextManager = { getInstance = function() return mgr end }

    -- the game's inventory menu builder, standing in for vanilla's
    local function hl(opt, menu, on) HL[#HL + 1] = { name = opt.name, opt = opt, on = on } end
    ISInventoryPaneContextMenu = {}
    ISInventoryPaneContextMenu.createMenu = function(player, isInInv, items, x, y, origin)
        local context = ISContextMenu.get(player, x, y)
        context.origin = origin
        local read = context:addOption(W.light and "Read" or "Read (too dark)", items, function() W.reads = W.reads + 1 end)
        read.onHighlight, read.onHighlightParams = hl, {}
        read.toolTip = { description = W.light and "Reads the book." or "Too dark to read." }
        if not W.light then read.notAvailable = true end
        context:addOption("Eat", items, function() end)
        local put = context:addOption("Put in Container")
        local sub = ISContextMenu:getNew(context)
        context:addSubMenu(put, sub)
        for i = 1, 3 do
            local o = sub:addOption("Crate " .. i, items, function() end)
            if not W.inRange then o.notAvailable = true; o.toolTip = { description = "Too far away." } end
        end
        local lamp = context:addOption("Lamp")
        local lsub = ISContextMenu:getNew(context)
        context:addSubMenu(lamp, lsub)
        lsub:addOption("Check bulb", nil, function() end)
        local t = lsub:addOption(W.light and "Turn off" or "Turn on", nil, function() W.light = not W.light end)
        t.responsiveUIKeepOpen = true
        local tl = context:addOption("Toggle light", nil, function() W.light = not W.light end)
        tl.responsiveUIKeepOpen = true
        return context
    end
    ISInventoryPaneContextMenu.createMenuNoItems = function() return nil end

    if withRui then
        dofile(RUI .. "/common/media/lua/client/ResponsiveUI/RefreshController.lua")
        dofile(RUI .. "/42/media/lua/client/ResponsiveUI/Client.lua")
    end

    -- ZeD: the stubs its files need, then its files
    ZeD = { tr = function(k) return k end, logOnce = function(k, e) print("logOnce " .. tostring(k) .. " " .. tostring(e)) end,
        Safe = { on = function() return false end },
        Settings = { contextStyleOption = { getValue = function() return STYLE end } } }
    ZeD.T = { px = function(v) return v end, fontF1 = 1, fontF2 = 2,
        ctx = { maxVisible = 9, cellW = 40, gap = 2, animMs = 120, cellH = 40, drilledBorderTop = 3, gutter = 4,
                bumperMinW = 20, chevW = 10, labelMarginV = 4, targetCardMarginV = 4 } }
    ZeD.TM = getTextManager()
    ZeD_Panel = {}
    ZeD_Panel.__index = ZeD_Panel
    function ZeD_Panel:derive(name) local c = setmetatable({}, { __index = self }); c.Type = name; return c end
    function ZeD_Panel:new(x, y, w, h) return { x = x, y = y, width = w, height = h, _hitZones = {} } end
    for _, n in ipairs({ "initialise", "update", "addToUIManager", "removeFromUIManager", "bringToTop", "setWantKeyEvents",
        "clearHitZones" }) do ZeD_Panel[n] = function() end end
    function ZeD_Panel:setX(v) self.x = v end
    function ZeD_Panel:setY(v) self.y = v end
    function ZeD_Panel:getX() return self.x end
    function ZeD_Panel:getY() return self.y end
    function ZeD_Panel:setWidth(v) self.width = v end
    function ZeD_Panel:setHeight(v) self.height = v end
    dofile(ZD .. "ContextMenuRegistry.lua")
    dofile(ZD .. "ZeD_ContextMenu.lua")
    dofile(ZD .. "ZeD_ContextList.lua")
    dofile(ZD .. "Overrides/ContextMenu.lua")
    dofile(ZD .. "ModSupport/ResponsiveUI.lua")
    for _, f in ipairs(EV.OnGameStart.list) do f() end
end

local function open(style)
    STYLE = style
    ISInventoryPaneContextMenu.createMenu(0, true, { ITEM }, 300, 400)
    frame()   -- the mod's first look at the menu; ZeD's menu opens in the game's prerender
    return ROOT._zedMenu
end
local function later(ms) NOW = NOW + (ms or 300); frame() end
local function idx(list, name) for i, d in ipairs(list) do if d.name == name then return i end end end
local function lit() return ROOT.highlightedOption end

-- ---------------------------------------------------------------------------
-- BUG: the mod on, ZeD's support off
-- ---------------------------------------------------------------------------
game(true, false)
local m = open(1)
ok(m and m._ctx.open, "BUG ZeD's strip opened")
m._ctx.selected = idx(m._ctx.items, "Eat")
later()
ok(not m._ctx.open, "BUG the rebuild closed ZeD's strip")
local m2 = ROOT._zedMenu
ok(m2 and m2 ~= m and m2._ctx.selected == 1, "BUG a new strip opened at row 1")

-- ---------------------------------------------------------------------------
-- STRIP and SUBPATH
-- ---------------------------------------------------------------------------
game(true, true)
m = open(1)
local x0, y0 = m:getX(), m:getY()
local readDef = m._ctx.items[idx(m._ctx.items, "Read (too dark)")]
ok(readDef and readDef.disabled() == true and readDef.stateKind() == "bad", "STRIP Read greyed in the dark")
ok(readDef and readDef.body == "Too dark to read.", "STRIP the balloon says why")
m._ctx.selected = idx(m._ctx.items, "Eat")
ZeD.ContextMenu.Registry.highlight(m, m._ctx.items[m._ctx.selected])   -- (as the strip's prerender does)
later()
ok(ROOT._zedMenu == m and m._ctx.open, "STRIP the same strip stays open through a quiet rebuild")
W.light = true
later()
ok(ROOT._zedMenu == m and m._ctx.open, "STRIP the same strip stays open through a changing rebuild")
ok(m:getX() == x0 and m:getY() == y0, "STRIP in the same place")
local i = idx(m._ctx.items, "Read")
ok(i and not idx(m._ctx.items, "Read (too dark)"), "STRIP the new label")
local rd = i and m._ctx.items[i]
ok(rd and rd.disabled() == false and rd.stateKind() == "ok" and rd.body == "Reads the book.", "STRIP Read live, its balloon's words new")
ok(m._ctx.items[m._ctx.selected].name == "Eat", "STRIP selection kept by name")
local l = lit()
ok(l and l.name == "Eat" and l == m._ctx.items[m._ctx.selected].vanillaRef, "STRIP the lit option is the new Eat, same tick")
ok(ROOT.x == -100000, "STRIP the game's menu stays parked")
-- drill into Put in Container, pick Crate 2, then come into range
m._ctx.selected = idx(m._ctx.items, "Put in Container")
m:confirm()
ok(#m._ctx.path == 1, "SUBPATH drilled in")
m._ctx.selected = idx(m._ctx.items, "Crate 2")
ok(m._ctx.items[m._ctx.selected].disabled() == true, "SUBPATH crate out of range greyed")
W.inRange = true
later()
ok(ROOT._zedMenu == m and m._ctx.open and #m._ctx.path == 1, "SUBPATH the submenu stays open")
local c2 = m._ctx.items[m._ctx.selected]
ok(c2 and c2.name == "Crate 2" and c2.disabled() == false, "SUBPATH Crate 2 still selected, now in range")
ok(m._ctx.items[1].isBack, "SUBPATH the back cell is first")
-- PRESS: a press reaching the hidden game menu
ROOT:onMouseDownOutside(10, 10)
ok(ROOT:getIsVisible(), "PRESS the game's menu stays shown under ZeD's")
later()
ok(ResponsiveUI.controller:getSession(0) ~= nil and m._ctx.open, "PRESS the mod still watches it")
-- KEEP (strip): Toggle light keeps the strip open and rebuilds it at once
m:cancel()
m._ctx.selected = idx(m._ctx.items, "Toggle light")
local reads = W.light
m:confirm()
ok(W.light ~= reads, "KEEP the option ran")
ok(m._ctx.open and ROOT._zedMenu == m, "KEEP the strip stays open after the pick")
NOW = NOW + 1; frame()   -- the very next tick, no quarter second wait
ok(idx(m._ctx.items, "Read (too dark)") ~= nil, "KEEP rebuilt at once: Read greyed again")
ok(m._ctx.items[m._ctx.selected].name == "Toggle light", "KEEP the selection stays on the option")
-- GONE: the item leaves its container
W.has = false
later()
ok(not m._ctx.open, "GONE ZeD's strip closes with the mod's menu")
ok(ResponsiveUI.controller:getSession(0) == nil and not ROOT:getIsVisible(), "GONE the mod let it go")

-- ---------------------------------------------------------------------------
-- LIST
-- ---------------------------------------------------------------------------
game(true, true)
m = open(2)
ok(m and m.Type == "ZeD_ContextList" and m._ctx.open, "LIST opened")
local top = m._levels[1]
local function rowNamed(lv, name) for ri, r in ipairs(lv.rows) do if r.def and r.def.name == name then return ri end end end
top.sel = rowNamed(top, "Put in Container")
m:_openSub(1, true)
local sub = m._levels[2]
sub.sel = rowNamed(sub, "Crate 3")
local lx, ly, sx, sy = top.x, top.y, sub.x, sub.y
W.inRange, W.light = true, true
later()
ok(ROOT._zedMenu == m and m._ctx.open and #m._levels == 2, "LIST the same list, submenu still open")
ok(m._levels[1].x == lx and m._levels[1].y == ly and m._levels[2].x == sx and m._levels[2].y == sy, "LIST levels in place")
local s2 = m._levels[2]
ok(s2.rows[s2.sel].def.name == "Crate 3" and s2.rows[s2.sel].def.disabled() == false, "LIST Crate 3 kept, now in range")
ok(m._levels[1].rows[m._levels[1].sel].def.name == "Put in Container", "LIST the parent row kept")
ok(rowNamed(m._levels[1], "Read") ~= nil, "LIST the new label")
-- KEEP (list, in a submenu): Lamp > Turn off
m:cancel()
top = m._levels[1]
top.sel = rowNamed(top, "Lamp")
m:_openSub(1, true)
sub = m._levels[2]
sub.sel = rowNamed(sub, "Turn off")
m:confirm()
ok(m._ctx.open and #m._levels == 2 and W.light == false, "KEEP the list and its submenu stay after the pick")
NOW = NOW + 1; frame()
sub = m._levels[2]
ok(#m._levels == 2 and rowNamed(sub, "Turn on") ~= nil, "KEEP rebuilt at once: the row now says Turn on")
ok(sub.sel and sub.rows[sub.sel].def.name == "Turn on", "KEEP the renamed row keeps the selection (same place)")
-- a plain row still closes the list
sub.sel = rowNamed(sub, "Check bulb")
m:confirm()
ok(not m._ctx.open, "LIST a plain row still closes it")

-- ESC: the mod's Escape hides the game's menu directly (no clear); ZeD's menu follows on the next tick
m = open(1)
ok(m and m._ctx.open and ROOT:getIsVisible(), "ESC strip open over a shown game menu")
later(10)
ok(m._ctx.open, "ESC a tick with the game menu shown leaves ZeD's menu up")
ROOT:setVisible(false)
later(10)
ok(not m._ctx.open, "ESC the game menu hidden directly: ZeD's menu closes on the next tick")

-- ---------------------------------------------------------------------------
-- OFF: neither mod
-- ---------------------------------------------------------------------------
game(false, false)
ok(ZeD.ContextMenu.holdOnClear == nil and ZeD.ContextMenu.decorateDef == nil, "OFF no hooks set")
ok(ZeD.ModSupport == nil or ZeD.ModSupport.ResponsiveUI == nil, "OFF the support file returned at once")
ok(ISContextMenu._zedRuiDownOutside == nil, "OFF the game's outside press untouched")
m = open(1)
ok(m and m._ctx.open, "OFF strip opened")
m._ctx.selected = idx(m._ctx.items, "Toggle light")
ok(m._ctx.items[m._ctx.selected].keepOpen == nil, "OFF no keep-open on the row")
m:confirm()
ok(not m._ctx.open, "OFF the keep-open row closes the strip as before")
m = open(1)
ISContextMenu.get(0, 1, 1)
ok(not m._ctx.open, "OFF a clear closes ZeD's menu as before")
m = open(1)
ROOT:onMouseDownOutside(1, 1)
ok(not ROOT:getIsVisible(), "OFF the game's outside press hides its menu as before")

print(string.format("responsiveui_sim: %d pass, %d fail", pass, fail))
os.exit(fail == 0 and 0 or 1)
