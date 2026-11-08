-- ZeDUI/tools/qa/dual_pin_sim.lua: dual pinning, each half of the Character and World windows rolling up and pinning
-- on its own (WindowHalves.lua; the director's rulings, punch list 112), with no game running. Lua 5.1 stubs of the
-- game's panels; ZeD's REAL Organisms.lua (the window: its update, pins, shade, title bar), WindowCurtain.lua (the
-- inventory side's roll) and WindowHalves.lua. The two windows' layouts are small stand-ins with the real windows'
-- geometry (Character: tabs and drawer left, inventory right; World: containers left, drawer and tabs right) and a tab
-- strip whose press does what the real strips' presses do (a new tab opens the drawer, the open tab folds it, Loot
-- folds it).
--   TIMERS   each half's 2 s: the pointer in the drawer rolls the inventory only, in the inventory folds the drawer
--            only, away from both rolls the whole window; nothing rolls at 1.9 s; the pointer on a rolled half's part
--            of the title bar brings that half back
--   AIM      aiming with one half pinned rolls the other only, the right button held (the mouse's aim) too, and aiming
--            across a rolled bar leaves it rolled; the controller's aiming escape (ZeD.Halves.aim) the same; both
--            pinned: nothing moves
--   SAVE     the two pins saved per window; an old single pin pinned both halves; a click on each pin toggles that
--            half only; setPinned (QA, older code) sets both
--   TABS     a press on the open tab and on Loot still folds the drawer by hand, as before; the roll box's roll
--            stays until its tab is pressed; a tab pressed under a folded half opens it and the half is down
--   MAPS     the World window with the Maps tab pinned open: its containers and the whole Character window roll with
--            the pointer, the map stays open, aim too
--   PAD      the pins are the title bar's stops (left to right; the rolled side's pin on its rod), A toggles
--   SHADE    a shade or unshade from elsewhere (double-click, Y) rolls or brings down both halves
-- Run from the repo root:  lua51 ZeDUI/tools/qa/dual_pin_sim.lua
-- It prints FAIL lines and a last line "dual_pin_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]dual_pin_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- ---------------------------------------------------------------------------
-- THE GAME
-- ---------------------------------------------------------------------------
local CLOCK = 100000
function getTimestampMs() return CLOCK end
local MX, MY, DOWN = -5000, -5000, false
function getMouseX() return MX end
function getMouseY() return MY end
local RDOWN = false
function isMouseButtonDown(b) if b == 1 then return RDOWN end return b == 0 and DOWN end
JoypadState = { players = {} }
local PLAYER = { md = {}, aiming = false }
function PLAYER:getModData() return self.md end
function PLAYER:isAiming() return self.aiming end
function getSpecificPlayer() return PLAYER end
function getCore() return { getScreenWidth = function() return 3840 end, getScreenHeight = function() return 2160 end } end
function getSoundManager() return { playUISound = function() end } end
UIManager = { getMillisSinceLastRender = function() return 100 end }

ISUIElement = {}
ISPanel = {}
ISPanel.__index = ISPanel
function ISPanel:derive(name)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.Type = name
    return o
end
function ISPanel:new(x, y, w, h)
    local o = { x = x, y = y, width = w, height = h, visible = true, kids = {}, onUI = false }
    setmetatable(o, self)
    self.__index = self
    return o
end
function ISPanel:initialise() end
function ISPanel:instantiate() end
function ISPanel:update() end
function ISPanel:prerender() end
function ISPanel:render() end
function ISPanel:addChild(c) self.kids[#self.kids + 1] = c; c.parent = self end
function ISPanel:getChildren() return self.kids end
function ISPanel:setVisible(v) self.visible = v and true or false end
function ISPanel:isVisible() return self.visible end
function ISPanel:getIsVisible() return self.visible end
function ISPanel:addToUIManager() self.onUI = true end
function ISPanel:removeFromUIManager() self.onUI = false end
function ISPanel:bringToTop() end
function ISPanel:getX() return self.x end
function ISPanel:getY() return self.y end
function ISPanel:getAbsoluteX() return self.parent and (self.parent:getAbsoluteX() + self.x) or self.x end
function ISPanel:getAbsoluteY() return self.parent and (self.parent:getAbsoluteY() + self.y) or self.y end
function ISPanel:getWidth() return self.width end
function ISPanel:getHeight() return self.height end
function ISPanel:setX(v) self.x = v end
function ISPanel:setY(v) self.y = v end
function ISPanel:setWidth(v) self.width = v end
function ISPanel:setHeight(v) self.height = v end
function ISPanel:setMaxDrawHeight() end
function ISPanel:clearMaxDrawHeight() end
function ISPanel:getMouseX() return MX - self:getAbsoluteX() end
function ISPanel:getMouseY() return MY - self:getAbsoluteY() end
function ISPanel:isMouseOver()
    local h = self.shownHeight and self:shownHeight() or self.height
    local x, y = self:getAbsoluteX(), self:getAbsoluteY()
    return self.visible and MX >= x and MX < x + self.width and MY >= y and MY < y + h
end
function ISPanel:drawRect() end
function ISPanel:drawRectBorder() end
function ISPanel:drawText() end

-- ---------------------------------------------------------------------------
-- ZeD's stand-ins (what the three files read)
-- ---------------------------------------------------------------------------
ZeD = {}
local function rgb() return { r = 0.5, g = 0.5, b = 0.5, a = 1 } end
ZeD.T = {
    px = function(v) return v end, line = function(v) return v end, hair = 1, borderW = 1,
    closeBoxSz = 14, titleBarH = 26, minWinH = 200, minWinW = 200,
    sp = { sm = 4, md = 8, titleBoxPad = 4 },
    hover = rgb(), surf2 = rgb(), borderS = rgb(), accent = rgb(), textDim = rgb(), textHead = rgb(), textOnFocus = rgb(),
    fontF3 = "F3",
}
ZeD.TM = { MeasureStringX = function(_, _, s) return #tostring(s) * 7 end, getFontHeight = function() return 14 end }
ZeD.tr = function(k, ...) return k end
local HELPSET = {}
ZeD.Help = { set = function(_, s) HELPSET.last = s end }
ZeD.Atoms = {
    drawPxIcon = function() end, frame = function() end, drawCloseBox = function() end,
    drawTriangleUp = function() end, drawTriangleDown = function() end,
    mouseIn = function(p, x, y, w, h) local mx, my = p:getMouseX(), p:getMouseY(); return mx >= x and mx < x + w and my >= y and my < y + h end,
    truncateText = function(s) return s end,
}
ZeD.Molecules = { drawBodyBg = function() end, drawWindowTitleBar = function() end }
ZeD.Focus = { mark = function() return true end }
-- the controller's ring: stores the zones' stops as FocusManager does
local FOCUSED = nil
ZeD.Input = { Focus = {
    setRingZoneElementsKeepId = function(w, name, els)
        for _, z in ipairs(w._focusRing) do if z.zone == name then z.elements = els end end
    end,
    setZoneFocusable = function(w, name, on)
        for _, z in ipairs(w._focusRing) do if z.zone == name then z.focusable = on and true or false end end
    end,
    isFocused = function(w, _, id) return FOCUSED == id end,
} }
ZeD.Safe = { guard = function(self, fn) return fn(self) end, on = function() return false end }

local LOADED = {}
function require(name)
    if LOADED[name] then return end
    LOADED[name] = true
end
local function load(file)
    local fn, err = loadfile(CLIENT .. file)
    if not fn then error(err) end
    fn()
end
load("Organisms.lua")
load("WindowCurtain.lua")
load("WindowHalves.lua")
local H, C = ZeD.Halves, ZeD.Curtain
check("the files load", H and C and ZeD_Window and ZeD_Window.drawPinBox ~= nil)

-- ---------------------------------------------------------------------------
-- The two windows (the real geometry, design units at 1x)
-- ---------------------------------------------------------------------------
local STRIP, CSTRIP, INV, DRAWER = 36, 36, 372, 300
local CW, WW

-- the window's widths and divider every update, as the real layouts do
local function layout(win)
    local L = win._lay
    local effW = (win._drawerOpen and win._drawerMode == "tab") and DRAWER or 0
    win._drawerEffW = effW
    local invW = win._rolled and 0 or INV
    L.content.width = invW
    L.content.visible = not win._rolled and not win.windowShaded
    local w = STRIP + effW + (win._rolled and 0 or (CSTRIP + INV))
    if win:getWidth() ~= w and not win.windowShaded then
        if L.side == "left" then win:setX(L.anchor - w) end   -- (the Character window grows to the left)
        win:setWidth(w)
    end
    win._dividerX = (effW > 0 and invW > 0) and ((L.side == "left") and (STRIP + effW) or (CSTRIP + INV)) or nil
    L.strip.x = (L.side == "left") and 0 or (win:getWidth() - STRIP)
    -- the strip's tab hit zones, as the strips stamp them while drawing
    L.strip._hitZones = {}
    for i, id in ipairs(L.tabs) do L.strip._hitZones[i] = { id = "tab:" .. id, x = 2, y = (i - 1) * 40, w = 32, h = 36 } end
    C.sync(win)
end

-- a press on a tab, as the real strips' handlers do
local function stripPress(win, tabId)
    if tabId == "loot" then
        if win._rolled then C.finishUnroll(win) end
        win._activeTab, win._drawerMode, win._drawerOpen = "loot", nil, false
    elseif tabId == win._activeTab then
        if win._drawerOpen and win._drawerMode == "tab" then
            win._activeTab, win._drawerOpen, win._drawerMode = "loot", false, nil
        else
            win._drawerMode, win._drawerOpen = "tab", true
        end
    else
        win._activeTab, win._drawerMode, win._drawerOpen = tabId, "tab", true
    end
    win._stripPresses = (win._stripPresses or 0) + 1
end

local function makeWindow(key)
    local left = key == "char"
    local x = left and (1920 - 5 - 744) or (1920 + 5)
    local win = ZeD_Window:new(x, 100, 744, 420, key)
    win:createChildren()
    win.autoCollapse = true
    win.resizable = false
    win.playerNum = 0
    win.javaObject = nil
    win._activeTab, win._drawerMode, win._drawerOpen = (left and "health" or "maps"), "tab", true
    local strip = ISPanel:new(0, 26, STRIP, 360)
    win:addChild(strip)
    local content = ISPanel:new(0, 26, INV, 360)
    win:addChild(content)
    strip.onMouseDown = function(self, sx, sy)
        for _, z in ipairs(self._hitZones or {}) do
            if sx >= z.x and sx < z.x + z.w and sy >= z.y and sy < z.y + z.h then stripPress(win, z.id:sub(5)); return true end
        end
        return true
    end
    win._lay = { side = left and "left" or "right", anchor = x + 744, strip = strip, content = content,
        tabs = left and { "loot", "health", "skills" } or { "loot", "maps", "vehicle" } }
    win[left and "_tabStripPanel" or "_actionTabStrip"] = strip
    win._mainContent = content
    win._focusRing = { { zone = "list", focusable = true, elements = {}, focusedElementIdx = 1 } }
    C.attach(win, {
        side = left and "right" or nil,
        sideW = function() return content:getWidth() + CSTRIP end,
        canRoll = function()
            return win._drawerOpen and win._drawerMode == "tab" and win._activeTab ~= nil and (win._rolled or content:isVisible())
        end,
        chip = function() return "Inventory", 3 end,
        dropInv = function() return nil end,
    })
    H.attach(win, { key = key, side = left and "left" or "right", strip = left and "_tabStripPanel" or "_actionTabStrip",
        zone = left and "charTitlePins" or "worldTitlePins" })
    layout(win)
    return win
end

ZeD_CharacterWindow = { getWindow = function() return CW end }
ZeD_WorldWindow = { getWindow = function() return WW end }

-- the rod's draw until it has rolled up or down (it draws at the drawers' speed)
local function rodSettle(win)
    for _ = 1, 40 do
        local rod = win._rod
        if not (rod and rod:isVisible() and win._rolled) then return end
        rod:prerender()
    end
end

-- one update of both windows (100 ms, the engine's UI tick), each laid out as its next frame would be
local function tick(n)
    for _ = 1, n or 1 do
        CLOCK = CLOCK + 100
        for _, w in ipairs({ CW, WW }) do
            if w then
                w:update()
                layout(w)
                rodSettle(w)
            end
        end
    end
end

-- the pointer at a window-local point (or a rod-local one)
local function pointAt(win, x, y) MX, MY = win:getAbsoluteX() + x, win:getAbsoluteY() + y end
local function away() MX, MY = 100, 2000 end

local function fresh(pins)
    PLAYER.md = { ZeD_WinPinned = pins or { charInv = false, charTabs = false, worldInv = false, worldTabs = false } }
    PLAYER.aiming = false
    DOWN = false
    CW = makeWindow("char")
    WW = nil
    return CW
end

-- ===========================================================================
-- TIMERS
-- ===========================================================================
do
    local w = fresh()
    check("TIMERS: the Character window opens on Health, nothing rolled", w._drawerOpen and not w._rolled and not w.windowShaded)
    pointAt(w, 100, 200)   -- over the drawer
    tick(19)
    check("TIMERS: pointer in the drawer, 1.9 s: the inventory not yet rolled", not w._rolled and not w._halves.inv.rolled)
    tick(3)
    check("TIMERS: pointer in the drawer, past 2 s: the inventory rolls under its rod", w._rolled == true and w._halves.inv.rolled, tostring(w._rolled))
    check("TIMERS: ... and the drawer stays open, the window down", w._drawerOpen and not w.windowShaded and w._halves.foldTab == nil)
    check("TIMERS: the rod has rolled up to the title bar", w._rod and w._rod:getHeight() == 26, w._rod and w._rod:getHeight())
    -- the pointer on the rod's title bar brings the inventory back
    local rod = w._rod
    MX, MY = rod:getX() + 200, rod:getY() + 10
    tick(1)
    check("TIMERS: the pointer on the rolled side's bar brings it down", not w._rolled and not w._halves.inv.rolled, tostring(w._rolled))

    w = fresh()
    pointAt(w, 36 + 300 + 100, 200)   -- over the inventory
    tick(22)
    check("TIMERS: pointer in the inventory, past 2 s: the drawer folds in", w._halves.foldTab == "health" and not w._drawerOpen, tostring(w._halves.foldTab))
    check("TIMERS: ... the inventory stays, the window down", not w._rolled and not w.windowShaded)
    check("TIMERS: ... through the strip's own press (as a second press of the tab)", (w._stripPresses or 0) == 1, w._stripPresses)
    pointAt(w, 10, 10)   -- the drawer's part of the title bar (the tab strip's end)
    tick(1)
    check("TIMERS: the pointer on the drawer's part of the bar opens it again on its tab", w._drawerOpen and w._activeTab == "health" and w._halves.foldTab == nil)

    w = fresh()
    away()
    tick(19)
    check("TIMERS: pointer away, 1.9 s: nothing rolled", not w.windowShaded and not w._rolled and w._drawerOpen)
    tick(3)
    check("TIMERS: pointer away, past 2 s: both halves roll, the window to its title bar as always", w.windowShaded == true)
    check("TIMERS: ... at its full width (the curtain down under the shade)", not w._rolled and w:getWidth() == 744, w:getWidth())
    -- the drawer's part of the rolled bar: the drawer comes down, the inventory rolls under its rod
    pointAt(w, 100, 10)
    tick(3)
    check("TIMERS: the drawer's part of a rolled bar: the window down, the drawer open", not w.windowShaded and w._drawerOpen)
    check("TIMERS: ... and the inventory still rolled, under its rod", w._rolled == true, tostring(w._rolled))
    -- and from the shade, the inventory's part instead
    w = fresh()
    away(); tick(22)
    pointAt(w, 600, 10)
    tick(3)
    check("TIMERS: the inventory's part of a rolled bar: the window down, the drawer folded", not w.windowShaded and not w._rolled and w._halves.foldTab == "health", tostring(w._halves.foldTab))
    -- a held button (a drag, the map moved) holds both timers
    w = fresh()
    away(); DOWN = true
    tick(30)
    check("TIMERS: a button held holds every timer", not w.windowShaded and not w._rolled and w._drawerOpen)
    DOWN = false
    -- a tab opened by its key holds them a moment (win._outSince ahead of the clock), QA's staging the same
    w._outSince = CLOCK + 600000
    tick(30)
    check("TIMERS: _outSince ahead of the clock holds every timer (QA's staging)", not w.windowShaded and not w._rolled)
    w._outSince = nil
    -- the window on Loot (no drawer): the inventory's timer rolls the whole window
    w = fresh()
    stripPress(w, "loot"); layout(w)
    away(); tick(22)
    check("TIMERS: on Loot (no drawer), the inventory's 2 s rolls the whole window", w.windowShaded == true)
    pointAt(w, 10, 10); tick(2)
    check("TIMERS: ... and any part of its bar brings it down", not w.windowShaded)
end

-- ===========================================================================
-- AIM
-- ===========================================================================
do
    local w = fresh({ charInv = true, charTabs = false })
    away()
    PLAYER.aiming = true
    tick(1)
    check("AIM: inventory pinned, aiming: the drawer folds at once", w._halves.foldTab == "health" and not w._drawerOpen)
    check("AIM: ... the pinned inventory stays exactly as it is", not w._rolled and not w.windowShaded)
    tick(10)
    check("AIM: ... still, while aiming goes on", not w._rolled and not w.windowShaded)
    PLAYER.aiming = false

    w = fresh({ charInv = false, charTabs = true })
    away(); PLAYER.aiming = true
    tick(2)
    check("AIM: drawer pinned, aiming: the inventory rolls, the drawer stays open", w._rolled == true and w._drawerOpen and not w.windowShaded)
    PLAYER.aiming = false

    -- the mouse's aim is the right button held: it holds no timer while the player aims
    w = fresh({ charInv = true, charTabs = false })
    away(); RDOWN = true
    tick(10)
    check("AIM: the right button held without aiming holds the timers", w._drawerOpen and w._halves.foldTab == nil)
    PLAYER.aiming = true
    tick(1)
    check("AIM: the right button held while aiming: the unpinned drawer folds at once", w._halves.foldTab == "health")
    -- aiming through a rolled half's bar does not bring it back
    pointAt(w, 10, 10)
    tick(3)
    check("AIM: aiming across the folded drawer's bar leaves it folded", w._halves.foldTab == "health" and not w._drawerOpen)
    RDOWN = false; PLAYER.aiming = false
    tick(1)
    check("AIM: done aiming, the pointer on that bar brings it back", w._drawerOpen and w._halves.foldTab == nil)

    -- the controller's aiming escape (FocusManager calls ZeD.Halves.aim; no pointer timers with a pad)
    w = fresh({ charInv = false, charTabs = true })
    JoypadState.players[1] = {}
    H.aim(w); tick(2)
    check("AIM pad: drawer pinned: the inventory rolls, the drawer stays", w._rolled == true and w._drawerOpen and not w.windowShaded)
    w = fresh({ charInv = false, charTabs = false })
    JoypadState.players[1] = {}
    H.aim(w); tick(1)
    check("AIM pad: nothing pinned: the whole window rolls", w.windowShaded == true)
    H.showAll(w); tick(2)
    check("AIM pad: a bumper / Y (showAll) brings both halves back", not w.windowShaded and not w._rolled and w._drawerOpen)
    w = fresh({ charInv = true, charTabs = true })
    JoypadState.players[1] = {}
    H.aim(w); tick(3)
    check("AIM pad: both pinned: nothing moves", not w.windowShaded and not w._rolled and w._drawerOpen)
    JoypadState.players[1] = nil
    -- with a controller the pointer's timers stop (the game pins its pages for a controller)
    w = fresh()
    JoypadState.players[1] = {}
    away(); tick(30)
    check("AIM pad: no pointer timers while a controller plays", not w.windowShaded and not w._rolled and w._drawerOpen)
    JoypadState.players[1] = nil
end

-- ===========================================================================
-- SAVE
-- ===========================================================================
do
    local w = fresh({ char = true, world = false })
    local t = PLAYER.md.ZeD_WinPinned
    check("SAVE: an old single pin pins both halves", H.isPinned(w, "inv") and H.isPinned(w, "drawer") and w.pinned == true)
    check("SAVE: ... written as the two new keys", t.charInv == true and t.charTabs == true)
    w = fresh({ char = false })
    check("SAVE: an old unpinned window: both halves unpinned", not H.isPinned(w, "inv") and not H.isPinned(w, "drawer"))
    w = fresh({})
    check("SAVE: no pins saved: both unpinned", not H.isPinned(w, "inv") and not H.isPinned(w, "drawer"))

    -- a real click on each pin: the drawer's at the left end (after the close box), the inventory's at the right
    w = fresh()
    local lp, rp = H.pinRect(w, "left"), H.pinRect(w, "right")
    check("SAVE: Character: the drawer's pin after the close box, the inventory's before the window box",
        lp and rp and lp.x == 4 + 14 + 4 and rp.x == w:windowBoxRect().x - 4 - 14, lp and lp.x)
    check("SAVE: the title moves right past the left pin", H.titleShift(w) == 14 + 4)
    check("SAVE: pinRect (the bar's right end, the stats' edge) is the inventory's pin", w:pinRect() == rp)
    pointAt(w, lp.x + 3, lp.y + 3)
    DOWN = true; tick(1); DOWN = false; tick(1)
    t = PLAYER.md.ZeD_WinPinned
    check("SAVE: a click on the left pin pins the drawer only", H.isPinned(w, "drawer") and not H.isPinned(w, "inv"))
    check("SAVE: ... saved per half", t.charTabs == true and t.charInv == false and t.char == false)
    tick(1)
    check("SAVE: ... its help line, the next update", w._updHelp == "UI_ZeD_Win_HelpUnpinTabs", w._updHelp)
    pointAt(w, rp.x + 3, rp.y + 3)
    DOWN = true; tick(1); DOWN = false; tick(1)
    check("SAVE: a click on the right pin pins the inventory", H.isPinned(w, "inv") and PLAYER.md.ZeD_WinPinned.charInv == true)
    check("SAVE: both pinned: the single key reads pinned too, win.pinned true", PLAYER.md.ZeD_WinPinned.char == true and w.pinned == true)
    -- reopened: the pins come back as saved
    local saved = PLAYER.md.ZeD_WinPinned
    saved.charInv = false
    CW = makeWindow("char")
    check("SAVE: reopened: each half's pin as saved", H.isPinned(CW, "drawer") and not H.isPinned(CW, "inv"))
    -- setPinned (QA, older code) sets both
    CW:setPinned(true)
    check("SAVE: setPinned(true) pins both halves", H.isPinned(CW, "inv") and H.isPinned(CW, "drawer") and PLAYER.md.ZeD_WinPinned.charInv == true)
    CW:setPinned(false)
    check("SAVE: setPinned(false) unpins both", not H.isPinned(CW, "inv") and not H.isPinned(CW, "drawer") and CW.pinned == false)
    -- win.pinned set straight on the window (QA scripts) holds both halves
    CW.pinned = true
    away(); tick(30)
    check("SAVE: win.pinned = true straight on the window keeps both halves open", not CW.windowShaded and not CW._rolled and CW._drawerOpen)
    CW.pinned = false
    -- pinning a half that rolled by itself brings it back (as the window's pin did)
    local w2 = fresh()
    away(); tick(22)
    check("SAVE: (staged) both rolled", w2.windowShaded)
    H.setPin(w2, "drawer", true); tick(2)
    check("SAVE: pinning the drawer of a rolled window: the window down, the drawer open, the inventory still rolled",
        not w2.windowShaded and w2._drawerOpen and w2._rolled == true)
    -- the saved layout keeps a folded drawer's tab
    local w3 = fresh({ charInv = true })
    away(); tick(22)
    check("SAVE: (staged) the drawer folded", w3._halves.foldTab == "health")
    check("SAVE: a folded drawer is saved on its tab", H.foldedTab(w3) == "health")
end

-- ===========================================================================
-- TABS
-- ===========================================================================
do
    local w = fresh({ charInv = true, charTabs = true })
    stripPress(w, "health"); layout(w); tick(1)
    check("TABS: a press on the open tab still folds the drawer, pins or not", not w._drawerOpen and w._activeTab == "loot")
    check("TABS: ... by hand: not the half's fold (nothing to bring back)", w._halves.foldTab == nil and not w._halves.drawer.rolled)
    stripPress(w, "skills"); layout(w); tick(1)
    check("TABS: a new tab opens the drawer", w._drawerOpen and w._activeTab == "skills")
    stripPress(w, "loot"); layout(w); tick(1)
    check("TABS: Loot folds it too", not w._drawerOpen and w._activeTab == "loot")

    -- the roll box's roll: a roll by hand stays until its tab is pressed, even with the pointer on the rod
    w = fresh({ charInv = false, charTabs = true })
    C.roll(w); layout(w); rodSettle(w)
    check("TABS: the roll box rolls the inventory by hand", w._rolled and w._halves.inv.rolled and w._halves.inv.hand)
    local rod = w._rod
    MX, MY = rod:getX() + 200, rod:getY() + 10
    tick(5)
    check("TABS: ... and the pointer on its rod leaves it rolled (its tab brings it down)", w._rolled == true)
    C.unroll(w); rodSettle(w); tick(1)
    check("TABS: the rod's tab unrolls it, and the half is down", not w._rolled and not w._halves.inv.rolled and not w._halves.inv.hand)
    -- a press on the open tab while the inventory is rolled: the drawer folds, the inventory comes back (as before)
    C.roll(w); layout(w); rodSettle(w)
    stripPress(w, "health"); layout(w); tick(1)
    check("TABS: the open tab pressed under a rolled inventory: the drawer folds, the inventory back", not w._drawerOpen and not w._rolled and not w._halves.inv.rolled)

    -- a tab pressed under a folded half opens it, and the half counts as down
    w = fresh({ charInv = true })
    pointAt(w, 500, 200); tick(22)
    check("TABS: (staged) the drawer folded by its half", w._halves.foldTab == "health")
    stripPress(w, "skills"); layout(w); tick(1)
    check("TABS: a tab pressed under a folded half opens that tab, the half down", w._drawerOpen and w._activeTab == "skills" and w._halves.foldTab == nil and not w._halves.drawer.rolled)
end

-- ===========================================================================
-- SHADE (from elsewhere)
-- ===========================================================================
do
    local w = fresh({ charInv = true, charTabs = true })
    w:setWindowShaded(true)
    check("SHADE: a shade from elsewhere (double-click, Y) rolls both halves", w.windowShaded and w._halves.inv.rolled and w._halves.drawer.rolled)
    away(); tick(5)
    check("SHADE: ... pinned, it stays rolled until brought down", w.windowShaded)
    w:setWindowShaded(false); tick(2)
    check("SHADE: an unshade from elsewhere brings both down", not w.windowShaded and not w._rolled and w._drawerOpen and not w._halves.inv.rolled)
end

-- ===========================================================================
-- MAPS: the World window with the Maps tab pinned open
-- ===========================================================================
do
    PLAYER.md = { ZeD_WinPinned = { charInv = false, charTabs = false, worldInv = false, worldTabs = true } }
    PLAYER.aiming = false
    CW = makeWindow("char")
    WW = makeWindow("world")
    check("MAPS: World opens on the Maps tab, its drawer pinned", WW._activeTab == "maps" and WW._drawerOpen and H.isPinned(WW, "drawer") and not H.isPinned(WW, "inv"))
    local lp, rp = H.pinRect(WW, "left"), H.pinRect(WW, "right")
    check("MAPS: World: the containers' pin after the close box, the drawer's before the window box", lp and rp and lp.x < rp.x)
    -- the pointer on the map for a long while: the containers roll, the map stays
    pointAt(WW, CSTRIP + INV + 150, 200)
    tick(25)
    check("MAPS: pointer on the map: the containers roll under their rod", WW._rolled == true and not WW.windowShaded)
    check("MAPS: ... the map stays open", WW._drawerOpen and WW._activeTab == "maps" and WW._halves.foldTab == nil)
    check("MAPS: ... the Character window rolls up whole (the pointer is away from it)", CW.windowShaded == true)
    -- the pointer away from both
    away(); tick(30)
    check("MAPS: pointer away: the map still open, the World window down", WW._drawerOpen and not WW.windowShaded and WW._rolled)
    -- aim
    PLAYER.aiming = true; tick(3); PLAYER.aiming = false
    check("MAPS: aiming: the map still open", WW._drawerOpen and not WW.windowShaded)
    -- back over the containers' rod: they come down; then away again: they roll again
    local rod = WW._rod
    check("MAPS: the World rod sits left of the window (the containers' side)", rod:getX() < WW:getX())
    MX, MY = rod:getX() + 100, rod:getY() + 10
    tick(1)
    check("MAPS: the pointer on the containers' rod brings them down", not WW._rolled)
    away(); tick(25)
    check("MAPS: away again: the containers roll again, the map open", WW._rolled == true and WW._drawerOpen)
    -- the containers' pin moves to the rod while they are rolled
    check("MAPS: rolled: the containers' pin is on the rod, not the bar", H.pinRect(WW, "left") == nil and H.rodPinRect(WW._rod) ~= nil)
    check("MAPS: a left rod's tab moves right past its pin", H.rodChipShift(WW) == 14 + 4 and H.rodChipShift(CW) == 0)
    -- the Character window over its bar: down again
    pointAt(CW, 300, 10); tick(3)
    check("MAPS: the Character window's bar brings it down", not CW.windowShaded)

    -- PAD: the pins as the title bar's stops
    local zone
    for _, z in ipairs(WW._focusRing) do if z.zone == "worldTitlePins" then zone = z end end
    check("PAD: World has its pins' zone", zone ~= nil)
    local els = zone and zone.elements or {}
    check("PAD: rolled: two stops, the containers' on its rod (left of the window), the drawer's on the bar",
        #els == 2 and els[1].id == "halfpin:inv" and els[1].x < 0 and els[2].id == "halfpin:drawer", #els)
    check("PAD: A on the drawer's pin says Unpin", els[2] and els[2].promptA(WW) == "UI_ZeD_Cm_Unpin")
    if els[2] then els[2].onActivate(WW) end
    check("PAD: A toggles that pin", not H.isPinned(WW, "drawer") and PLAYER.md.ZeD_WinPinned.worldTabs == false)
    check("PAD: ... its prompt now Pin", els[2] and els[2].promptA(WW) == "UI_ZeD_Prompt_Pin")
    local cz
    for _, z in ipairs(CW._focusRing) do if z.zone == "charTitlePins" then cz = z end end
    local ce = cz and cz.elements or {}
    check("PAD: Character down: two stops on its bar, left to right drawer then inventory",
        #ce == 2 and ce[1].id == "halfpin:drawer" and ce[2].id == "halfpin:inv" and cz.focusable, #ce)
    away(); CW:setWindowShaded(true); tick(1)
    check("PAD: a rolled window offers no stops", cz and (#cz.elements == 0 and not cz.focusable))
end

print("dual_pin_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
