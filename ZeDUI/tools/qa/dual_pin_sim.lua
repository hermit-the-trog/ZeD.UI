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
--   KEEP     a fold and unfold bring the drawer back exactly as it was (pick, scroll, cache, selection), never through
--            the strip's press; no fold over an item card; Loot columns or a card opened while folded forget the fold;
--            a tab with no hit zone on the strip folds and unfolds all the same
--   FLASH    from a rolled window only the half brought back shows, in the same update (the other already folded or
--            under its rod, the rod already up)
--   RESET    Reset this window forgets a folded drawer
--   PADUP    Up from the top tab and the top bag land on the pins at Large text (the real SpatialNav)
--   FULL     a drawer as wide as the window: the bag strip never rolls, the halves meet at it
--   ROLLBOX  the roll box after the title as drawn, its room kept in the bar
--   CAP      the snapped fold at the Deck with a 480 drawer at the half-screen cap: the swallowed width given back
--            (444, not 160), the cap counters clean, the minimum width lowered; the World window's push settled
--   PADY     one Y after the pad's aim brings the rolled halves back and never rolls a pinned one (the real
--            FocusManager.lua, its Y through Focus.qaButton)
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
local SCREEN_W, SCREEN_H = 3840, 2160
function getCore() return { getScreenWidth = function() return SCREEN_W end, getScreenHeight = function() return SCREEN_H end } end
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
load("Input/SpatialNav.lua")   -- (the D-pad's picker, for the pins' stops)
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
    local effW = (win._drawerOpen and win._drawerMode == "tab") and (L.drawerW or DRAWER) or 0
    win._drawerEffW = effW
    -- (a drawer as wide as the window: the inventory list hidden, the bag strip still there)
    local full = win._invDrawerOpen == false and effW > 0
    local invW = (win._rolled or full) and 0 or INV
    -- (L.fixedWidth: the window's width is staged by the test, as the cap left it; the list takes what is left)
    if L.fixedWidth then invW = (win._rolled or full) and 0 or math.max(0, win:getWidth() - STRIP - effW - CSTRIP) end
    L.content.width = invW
    if not win.windowShaded then L.content.visible = not win._rolled and not full end
    local w = STRIP + effW + (win._rolled and 0 or (CSTRIP + invW))
    if win:getWidth() ~= w and not win.windowShaded and not L.fixedWidth then
        if L.side == "left" then win:setX(L.anchor - w) end   -- (the Character window grows to the left)
        win:setWidth(w)
    end
    win._anchorRightEdge = L.anchor
    win._dividerX = (effW > 0 and invW > 0) and ((L.side == "left") and (STRIP + effW) or (CSTRIP + invW)) or nil
    L.strip.x = (L.side == "left") and 0 or (win:getWidth() - STRIP)
    L.bags.x = (L.side == "left") and (win:getWidth() - CSTRIP) or 0
    if not win.windowShaded then L.bags.visible = not win._rolled end
    -- the strip's tab hit zones, as the strips stamp them while drawing
    L.strip._hitZones = {}
    for i, id in ipairs(L.tabs) do L.strip._hitZones[i] = { id = "tab:" .. id, x = 2, y = (i - 1) * 40, w = 32, h = 36 } end
    C.sync(win)
end

-- a press on a tab, as the real strips' handlers do, with what each path wipes
-- (ZeD_CharacterWindow / ZeD_WorldWindow strip.onMouseDown)
local function stripPress(win, tabId)
    local content = win._lay.content
    if tabId == "loot" then
        if win._rolled then C.finishUnroll(win) end
        win._activeTab, win._drawerMode, win._drawerOpen, win._drawerItem = "loot", nil, false, nil
        content._selectedItems = {}
    elseif tabId == win._activeTab then
        if win._drawerOpen and win._drawerMode == "tab" then
            win._activeTab, win._drawerOpen, win._drawerMode = "loot", false, nil
            if tabId == "equip" then win._equipSelected = nil end
        else
            win._drawerMode, win._drawerOpen, win._drawerItem = "tab", true, nil
        end
    else
        -- the "new tab" path: Loot columns closed, the selection, the card, the scroll and the caches gone
        win._mcSelected = {}
        win._activeTab, win._drawerMode, win._drawerOpen, win._drawerItem = tabId, "tab", true, nil
        content._selectedItems = {}
        win._tabScroll.pos = 0
        win._healthCache, win._equipCache, win._equipSelected = nil, nil, nil
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
    content._selectedItems = {}
    local bags = ISPanel:new(0, 26, CSTRIP, 360)
    win:addChild(bags)
    win._containerStrip = bags
    win._tabScroll = { pos = 0 }
    win._mcSelected = {}
    strip.onMouseDown = function(self, sx, sy)
        for _, z in ipairs(self._hitZones or {}) do
            if sx >= z.x and sx < z.x + z.w and sy >= z.y and sy < z.y + z.h then stripPress(win, z.id:sub(5)); return true end
        end
        return true
    end
    win._lay = { side = left and "left" or "right", anchor = x + 744, strip = strip, content = content, bags = bags,
        tabs = left and { "loot", "health", "skills", "equip" } or { "loot", "maps", "vehicle" } }
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
        for i = 1, 2 do
            local w = (i == 1) and CW or WW   -- (ipairs would stop at a closed Character window)
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
-- the pointer resting on a rolled bar: the rest (H.REST_MS) is timed from the first update that sees it,
-- so three updates here and the next one brings the half back
local function rest() tick(3) end

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
    rest()   -- (the pointer rests on the bar first)
    tick(1)
    check("TIMERS: the pointer on the rolled side's bar brings it down", not w._rolled and not w._halves.inv.rolled, tostring(w._rolled))

    w = fresh()
    pointAt(w, 36 + 300 + 100, 200)   -- over the inventory
    tick(22)
    check("TIMERS: pointer in the inventory, past 2 s: the drawer folds in", w._halves.foldTab == "health" and not w._drawerOpen, tostring(w._halves.foldTab))
    check("TIMERS: ... the inventory stays, the window down", not w._rolled and not w.windowShaded)
    check("TIMERS: ... set straight, not through a press of the strip (which wipes the drawer)", (w._stripPresses or 0) == 0, w._stripPresses)
    pointAt(w, 10, 10)   -- the drawer's part of the title bar (the tab strip's end)
    rest()   -- (the pointer rests on the bar first)
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
    rest()   -- (the pointer rests on the bar first)
    tick(3)
    check("TIMERS: the drawer's part of a rolled bar: the window down, the drawer open", not w.windowShaded and w._drawerOpen)
    check("TIMERS: ... and the inventory still rolled, under its rod", w._rolled == true, tostring(w._rolled))
    -- and from the shade, the inventory's part instead
    w = fresh()
    away(); tick(22)
    pointAt(w, 600, 10)
    rest()   -- (the pointer rests on the bar first)
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
    pointAt(w, 10, 10); rest(); tick(2)
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
    rest()   -- (the pointer rests on the bar first)
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
    rest()   -- (the pointer rests on the bar first)
    tick(1)
    check("MAPS: the pointer on the containers' rod brings them down", not WW._rolled)
    away(); tick(25)
    check("MAPS: away again: the containers roll again, the map open", WW._rolled == true and WW._drawerOpen)
    -- the containers' pin moves to the rod while they are rolled
    check("MAPS: rolled: the containers' pin is on the rod, not the bar", H.pinRect(WW, "left") == nil and H.rodPinRect(WW._rod) ~= nil)
    check("MAPS: a left rod's tab moves right past its pin", H.rodChipShift(WW) == 14 + 4 and H.rodChipShift(CW) == 0)
    -- the Character window over its bar: down again
    pointAt(CW, 300, 10); rest(); tick(3)
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

-- ===========================================================================
-- KEEP (review 1): a fold and unfold bring the drawer back exactly as it was
-- ===========================================================================
do
    WW = nil
    local w = fresh({ charInv = true })
    stripPress(w, "equip"); layout(w)
    local content = w._lay.content
    w._equipSelected = "slot5"
    w._tabScroll.pos = 120
    w._equipCache = { built = true }
    content._selectedItems = { a = true, b = true }
    pointAt(w, 36 + 300 + 100, 200)   -- over the inventory
    tick(22)
    check("KEEP: (staged) the Equip drawer folded by its half", w._halves.foldTab == "equip" and not w._drawerOpen)
    check("KEEP: the fold keeps the Equip pick", w._equipSelected == "slot5", w._equipSelected)
    pointAt(w, 10, 10); rest(); tick(1)
    check("KEEP: unfolded on Equip", w._drawerOpen and w._activeTab == "equip" and w._halves.foldTab == nil)
    check("KEEP: ... its pick, scroll and cache as they were", w._equipSelected == "slot5" and w._tabScroll.pos == 120 and w._equipCache ~= nil,
        tostring(w._equipSelected) .. " " .. tostring(w._tabScroll.pos))
    local n = 0
    for _ in pairs(content._selectedItems) do n = n + 1 end
    check("KEEP: ... the list's selection kept", n == 2, n)
    check("KEEP: ... and never through a press of the strip", (w._stripPresses or 0) == 1, w._stripPresses)   -- (the one press: Equip opened above)

    -- no fold over an item card or with the inventory hidden; Loot columns or a card opened while folded take it over
    w = fresh({ charInv = true })
    w._drawerItem = { item = true }
    pointAt(w, 36 + 300 + 100, 200); tick(25)
    check("KEEP: an item card over the drawer: no fold", w._drawerOpen and w._halves.foldTab == nil and w._drawerItem ~= nil)
    w._drawerItem = nil
    tick(22)
    check("KEEP: (staged) folded once the card closed", w._halves.foldTab == "health")
    w._mcSelected = { "crate" }
    tick(1)
    check("KEEP: Loot columns opened while folded: the fold forgotten", w._halves.foldTab == nil and not w._halves.drawer.rolled)
    pointAt(w, 10, 10); rest(); tick(2)
    check("KEEP: ... and the drawer's bar leaves the columns alone", #w._mcSelected == 1 and w._activeTab == "loot")
    w = fresh({ charInv = true })
    pointAt(w, 36 + 300 + 100, 200); tick(22)
    w._drawerItem, w._drawerMode, w._drawerOpen = { item = true }, "item", true
    tick(1)
    check("KEEP: an item card opened while folded: the fold forgotten", w._halves.foldTab == nil)

    -- a tab scrolled out of the strip (no hit zone): the fold and unfold do not need the strip
    w = fresh({ charInv = true })
    w._lay.tabs = { "loot" }
    pointAt(w, 36 + 300 + 100, 200); tick(22)
    check("KEEP: a tab with no zone on the strip still folds", w._halves.foldTab == "health")
    pointAt(w, 10, 10); rest(); tick(1)
    check("KEEP: ... and unfolds", w._drawerOpen and w._activeTab == "health")
end

-- ===========================================================================
-- FLASH (review 2): from a rolled window only the half brought back shows
-- ===========================================================================
do
    local w = fresh()
    away(); tick(22)
    check("FLASH: (staged) both rolled", w.windowShaded)
    pointAt(w, 600, 10)   -- the inventory's part of the bar
    rest()   -- (the pointer rests on the bar first)
    CLOCK = CLOCK + 100; w:update()
    check("FLASH: the inventory's part: in the same update the window is down with the drawer already folded",
        not w.windowShaded and w._halves.foldTab == "health" and not w._drawerOpen and (w._drawerEffW or 0) == 0)
    layout(w)
    w = fresh()
    away(); tick(22)
    pointAt(w, 100, 10)   -- the drawer's part
    rest()   -- (the pointer rests on the bar first)
    CLOCK = CLOCK + 100; w:update()
    check("FLASH: the drawer's part: in the same update the inventory is already under its rod",
        not w.windowShaded and w._rolled == true and w._drawerOpen)
    check("FLASH: ... the rod already up (no roll-up to watch)", w._rod and w._rod:getHeight() == 26, w._rod and w._rod:getHeight())
    layout(w)
    -- drawer folded before the window rolled: the drawer's part brings it out with the inventory already rolled
    w = fresh()
    pointAt(w, 36 + 300 + 100, 200); tick(22)   -- the drawer folds
    away(); tick(22)                              -- then the inventory: the window rolls
    check("FLASH: (staged) folded, then rolled", w.windowShaded and w._halves.foldTab == "health")
    pointAt(w, 10, 10)
    rest()   -- (the pointer rests on the bar first)
    CLOCK = CLOCK + 100; w:update()
    check("FLASH: the drawer's part of that bar: down, the drawer open, the inventory already rolled",
        not w.windowShaded and w._drawerOpen and w._rolled == true)
    layout(w)
end

-- ===========================================================================
-- RESET (review 3): Reset this window forgets a folded drawer
-- ===========================================================================
do
    local w = fresh({ charInv = true })
    pointAt(w, 36 + 300 + 100, 200); tick(22)
    check("RESET: (staged) folded", H.foldedTab(w) == "health")
    ZeD_Window.resetLayout("char")
    check("RESET: the reset forgets the fold: the saved layout gets Loot", H.foldedTab(w) == nil and not w._halves.drawer.rolled and w._activeTab == "loot")
end

-- ===========================================================================
-- PADUP (review 4): Up from the top tab and the top bag lands on the pins, Deck Large text
-- ===========================================================================
do
    local keepBox = ZeD.T.closeBoxSz
    ZeD.T.closeBoxSz = 27   -- (Large text: each pin overlaps its 36-unit strip by 1 unit)
    local w = fresh()
    tick(1)
    local N = ZeD.SpatialNav
    local zone
    for _, z in ipairs(w._focusRing) do if z.zone == "charTitlePins" then zone = z end end
    local els = zone and zone.elements or {}
    local lp, rp = H.pinRect(w, "left"), H.pinRect(w, "right")
    check("PADUP: (staged) the pins barely overlap their strips", lp and 36 - lp.x <= 1 and rp and rp.x + rp.w - (w:getWidth() - 36) <= 1)
    local topTab = { x = 2, y = 26, w = 32, h = 36 }
    local topBag = { x = w:getWidth() - 34, y = 26, w = 32, h = 36 }
    local a, ta = N.pick(topTab, els, "up")
    local b, tb = N.pick(topBag, els, "up")
    check("PADUP: Up from the top tab: the drawer's pin, lined up", a and a.id == "halfpin:drawer" and ta == 0, a and a.id)
    check("PADUP: Up from the top bag: the inventory's pin, lined up", b and b.id == "halfpin:inv" and tb == 0, b and b.id)
    local d = els[1] and N.pick(els[1], { topTab, topBag }, "down")
    check("PADUP: Down from the drawer's pin: the top tab", d == topTab)
    ZeD.T.closeBoxSz = keepBox
end

-- ===========================================================================
-- FULL (review 7): a drawer as wide as the window keeps its bag strip
-- ===========================================================================
do
    local w = fresh({ charTabs = true })
    w._invDrawerOpen = false; layout(w)
    check("FULL: (staged) no list, the bag strip showing", w._dividerX == nil and w._lay.bags.visible)
    away(); tick(30)
    check("FULL: the bag strip never rolls under a rod", not w._rolled and not w.windowShaded and w._drawerOpen)
    check("FULL: the halves meet at the bag strip, not the window's edge", H.split(w) == w:getWidth() - 36, H.split(w))
    w = fresh({})
    w._invDrawerOpen = false; layout(w)
    away(); tick(25)
    check("FULL: nothing pinned: the whole window rolls (no drawer fold, no rod)", w.windowShaded and not w._rolled and w._halves.foldTab == nil)
    pointAt(w, 40, 10); rest(); tick(2)
    check("FULL: its bar brings it back down", not w.windowShaded and w._drawerOpen)
end

-- ===========================================================================
-- ROLLBOX (review 8): the roll box goes after the title as drawn
-- ===========================================================================
do
    local w = fresh()
    w.title = string.rep("Character window ", 6)
    w._titleShownW = 70   -- (the title bar drew it cut short)
    C.drawRollButton(w)
    local r = w._rollBtn
    check("ROLLBOX: right after the cut-short title", r and r.x == 4 + 14 + 8 + H.titleShift(w) + 70 + 4 + 2, r and r.x)
    check("ROLLBOX: the bar keeps its room from the title and the stats", w._titleReserve == 14 + 4 + 2)
    w._rolled = true; C.drawRollButton(w); w._rolled = false
    check("ROLLBOX: no box, no room kept", w._titleReserve == nil)
end

-- ===========================================================================
-- RODPIN (QA, beta 9 step 7): a real click on the pin on a rolled side's rod pins it; the window
-- menu never opens. The press order as the game runs it: the pointer arrives and rests (updates
-- run), the button goes down (the rod, the top panel there, takes onMouseDown; the window polls the
-- raw mouse in its update), then up.
-- ===========================================================================
do
    local menus = 0
    ZeD.WindowMenu = { open = function() menus = menus + 1 end }
    -- the click where the pointer is, as the engine delivers it
    local function realClick(win)
        local rod = win._rod
        local function onRod()
            return rod and rod:isVisible() and win._rolled and MX >= rod:getX() and MX < rod:getX() + rod:getWidth()
                and MY >= rod:getY() and MY < rod:getY() + rod:getHeight()
        end
        tick(2)   -- (the pointer rests on the pin a moment)
        DOWN = true
        local pressedRod = onRod()
        if pressedRod then rod:onMouseDown(MX - rod:getX(), MY - rod:getY()) end
        CLOCK = CLOCK + 100; win:update()
        DOWN = false
        if pressedRod then rod:onMouseUp(MX - rod:getX(), MY - rod:getY()) end
        tick(1)
    end
    for _, key in ipairs({ "char", "world" }) do
        PLAYER.md = { ZeD_WinPinned = { charInv = false, charTabs = true, worldInv = false, worldTabs = true } }
        local w
        if key == "char" then w = fresh(PLAYER.md.ZeD_WinPinned); WW = nil
        else CW = nil; WW = makeWindow("world"); w = WW end
        away(); PLAYER.aiming = true; tick(2); PLAYER.aiming = false
        local rod = w._rod
        check("RODPIN " .. key .. ": (staged) the inventory rolled by aim, its pin on the rod", w._rolled and rod and rod._pinRect ~= nil)
        local r = rod and rod._pinRect
        if r then MX, MY = rod:getX() + r.x + math.floor(r.w / 2), rod:getY() + r.y + math.floor(r.h / 2) end
        menus = 0
        realClick(w)
        check("RODPIN " .. key .. ": the click on the rod's pin pins the inventory", H.isPinned(w, "inv"))
        check("RODPIN " .. key .. ": ... the window menu does not open", menus == 0, menus)
        rodSettle(w); tick(2)
        check("RODPIN " .. key .. ": ... and the pinned inventory comes down", not w._rolled)
        -- the knock-on: the next click, on the open tab, still folds the drawer by hand
        stripPress(w, w._activeTab); layout(w); tick(1)
        check("RODPIN " .. key .. ": the next press on the open tab folds the drawer", not w._drawerOpen and w._activeTab == "loot")
    end
    -- a rolled window's bar: resting on a pin leaves the window rolled, the click pins and brings that half back
    local w = fresh()
    WW = nil
    away(); tick(22)
    local lp = H.pinRect(w, "left")
    pointAt(w, lp.x + 3, lp.y + 3)
    tick(3)
    check("RODPIN: on a rolled window's bar, resting on the drawer's pin leaves it rolled", w.windowShaded)
    menus = 0
    realClick(w)
    check("RODPIN: ... the click pins the drawer and brings it down, no menu", H.isPinned(w, "drawer") and not w.windowShaded and menus == 0)
    ZeD.WindowMenu = nil
end

-- ===========================================================================
-- REST: a rolled half comes back only after the pointer rests on its bar for 0.3 s (H.REST_MS);
-- a pointer passing over does not unroll it. Timed on the clock, the updates 100 ms apart.
-- ===========================================================================
do
    check("REST: the rest is 300 ms", H.REST_MS == 300)
    for _, key in ipairs({ "char", "world" }) do
        PLAYER.md = { ZeD_WinPinned = { charInv = false, charTabs = true, worldInv = false, worldTabs = true } }
        local w
        if key == "char" then w = fresh(PLAYER.md.ZeD_WinPinned); WW = nil
        else CW = nil; WW = makeWindow("world"); w = WW end
        away(); tick(22)
        check("REST " .. key .. ": (staged) the inventory under its rod", w._rolled == true)
        local rod = w._rod
        local cx = (key == "char") and (rod:getWidth() / 2) or (rod:getWidth() - 20)   -- (the rod's bar, off its pin and tab)
        local function onRod() MX, MY = rod:getX() + cx, rod:getY() + 10 end
        -- a 200 ms pass: the pointer is on the bar for two updates, then gone
        onRod(); tick(2); away(); tick(3)
        check("REST " .. key .. ": a 200 ms pass over the rod leaves it rolled", w._rolled == true)
        -- a 350 ms rest
        onRod(); tick(3)
        check("REST " .. key .. ": ... still rolled at 200 ms of rest", w._rolled == true)
        CLOCK = CLOCK + 50   -- (350 ms on the clock at the next update)
        tick(1)
        rodSettle(w)
        check("REST " .. key .. ": a 350 ms rest brings it back", not w._rolled, tostring(w._rolled))
        -- the rolled title bar the same
        away(); w:setWindowShaded(true); tick(1)   -- (rolled up whole, from elsewhere, both halves down before)
        local bx = (key == "char") and 600 or 50   -- (the inventory's part of the bar)
        pointAt(w, bx, 10); tick(2); away(); tick(2)
        check("REST " .. key .. ": a 200 ms pass over the rolled bar leaves it rolled", w.windowShaded == true)
        pointAt(w, bx, 10); tick(3)
        check("REST " .. key .. ": ... still rolled at 200 ms", w.windowShaded == true)
        CLOCK = CLOCK + 50; tick(1)
        check("REST " .. key .. ": a 350 ms rest on the bar brings it back", not w.windowShaded,
            string.format("inv %s drw %s split %s rolled %s", tostring(w._halves.inv.rolled), tostring(w._halves.drawer.rolled), tostring(w._halves.lastSplit), tostring(w._rolled)))
        -- an item held over the rolled bar still brings it down at once
        away(); w:setWindowShaded(true); tick(1)
        local content = w._lay.content
        content._drag = { isActive = function() return true end }
        pointAt(w, bx, 10)
        CLOCK = CLOCK + 100; w:update()
        check("REST " .. key .. ": an item held over the rolled bar: down at once", not w.windowShaded)
        content._drag = nil
    end
    WW = nil
end

-- ===========================================================================
-- CAP: the snapped fold at the Deck (1280x800), a 480 drawer capped at half the screen
-- ===========================================================================
do
    SCREEN_W, SCREEN_H = 1280, 800
    WW = nil
    local w = fresh()
    local L = w._lay
    L.drawerW, L.fixedWidth = 480, true
    -- staged as the real layout leaves it: 444 wide before the drawer, 924 wanted, 640 allowed (284 swallowed);
    -- the right edge anchored at 635, so the window was pushed 5 px off the screen's left edge
    L.anchor = 635
    w._maxWinW = 640
    w.minimumWidth = 640
    w:setWidth(640); w:setX(0)
    w._drawerCapLost, w._drawerCapPush = 284, 5
    layout(w)
    check("CAP: (staged) Skills open at the cap", w:getWidth() == 640 and w._drawerEffW == 480 and w._dividerX ~= nil)
    away(); tick(22)
    check("CAP: (staged) both halves rolled", w.windowShaded)
    pointAt(w, 600, 10)   -- the inventory's part of the bar
    rest()   -- (the pointer rests on the bar first)
    CLOCK = CLOCK + 100; w:update()
    check("CAP: the inventory's part: down with the drawer folded", not w.windowShaded and w._halves.foldTab == "health")
    check("CAP: the snapped fold gives back what the cap swallowed: 444 wide, not 160", w:getWidth() == 444, w:getWidth())
    check("CAP: ... on its right edge (635)", w:getX() + w:getWidth() == 635, w:getX())
    check("CAP: ... both cap counters clean", (w._drawerCapLost or 0) == 0 and (w._drawerCapPush or 0) == 0, tostring(w._drawerCapLost) .. " " .. tostring(w._drawerCapPush))
    check("CAP: ... the minimum width lowered first (a real click clamps to it)", w.minimumWidth <= 444, w.minimumWidth)
    layout(w)
    -- the World window settles its push through its own settleCapPush
    local settled = 0
    ZeD_WorldWindow.settleCapPush = function(win) settled = settled + 1; win._drawerCapPush = 0; win._drawerCapLost = 0 end
    PLAYER.md = { ZeD_WinPinned = { worldInv = false, worldTabs = false } }
    WW = makeWindow("world")
    local v = WW
    v._lay.drawerW, v._lay.fixedWidth = 480, true
    v._maxWinW = 640
    v:setWidth(640); v:setX(640)
    v._drawerCapLost, v._drawerCapPush = 284, 5
    layout(v)
    away(); tick(22)
    pointAt(v, 50, 10)
    rest()   -- (the pointer rests on the bar first)
    CLOCK = CLOCK + 100; v:update()
    check("CAP: World: snapped fold 444 wide, its push settled by its own settleCapPush", v:getWidth() == 444 and settled == 1, v:getWidth() .. " " .. settled)
    ZeD_WorldWindow.settleCapPush = nil
    WW = nil
    SCREEN_W, SCREEN_H = 3840, 2160
end

-- ===========================================================================
-- PADY (review 5): Y after aiming with a pinned half brings the halves back, never rolls the pinned one
-- (the REAL FocusManager.lua, its Y tap through Focus.qaButton)
-- ===========================================================================
do
    PLAYER.md = { ZeD_WinPinned = { charInv = false, charTabs = true, worldInv = false, worldTabs = true } }
    CW = makeWindow("char")
    WW = makeWindow("world")
    local magicMT = {}
    local function magic() return setmetatable({}, magicMT) end
    magicMT.__index = function() return magic() end
    magicMT.__call = function() return magic() end
    local keepG = getmetatable(_G)
    Events = setmetatable({}, { __index = function(t, k)
        local e = { fns = {} }
        e.Add = function(fn) e.fns[#e.fns + 1] = fn end
        e.Remove = function() end
        rawset(t, k, e); return e
    end })
    ZeD.Input.Detector = { getMode = function() return "gamepad" end }
    ZeD_CharacterWindow.isOpen = function() return CW ~= nil end
    ZeD_WorldWindow.isOpen = function() return WW ~= nil end
    setmetatable(_G, { __index = function(_, k) return magic() end })
    getJoypadData = function() return nil end
    getControllerCount = function() return 0 end
    local ok, err = pcall(load, "Input/FocusManager.lua")
    setmetatable(_G, keepG)
    check("PADY: the real FocusManager loads", ok, err)
    local F = ZeD.Input.Focus
    if ok and F.qaButton then
        -- the pad's aiming escape, as the right stick fires it
        JoypadState.players[1] = {}   -- (a controller plays: no pointer timers)
        H.aim(CW); H.aim(WW); tick(3)
        check("PADY: (staged) aim: the drawers pinned stay open, the inventories rolled", CW._rolled and WW._rolled and CW._drawerOpen and WW._drawerOpen and not CW.windowShaded,
            string.format("c rolled %s shaded %s open %s inv %s | w rolled %s open %s", tostring(CW._rolled), tostring(CW.windowShaded), tostring(CW._drawerOpen),
                tostring(CW._halves.inv.rolled), tostring(WW._rolled), tostring(WW._drawerOpen)) .. " pinned " .. tostring(H.isPinned(CW, "inv")) .. " " .. tostring(CW.pinned))
        check("PADY: a window with a half rolled by itself counts as rolled", F.isRolled(CW) and F.isRolled(WW))
        local function yTap()
            F.qaButton("Y", true); for _, fn in ipairs(Events.OnTick.fns) do pcall(fn) end
            F.qaButton("Y", false); for _, fn in ipairs(Events.OnTick.fns) do pcall(fn) end
            F.qaButton("Y", nil)
            tick(3)
        end
        if F.releaseFocus then pcall(F.releaseFocus) end
        yTap()
        check("PADY: one Y brings the rolled halves back", not CW._rolled and not WW._rolled and not CW.windowShaded and not WW.windowShaded)
        check("PADY: ... and never rolled a pinned half", CW._drawerOpen and WW._drawerOpen)
        JoypadState.players[1] = nil
    end
end

print("dual_pin_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
