-- ZeD-UI/42/media/lua/client/ZeD/ZeD_PausedLook.lua
-- ============================================================================
-- THE CHARACTER WINDOW WHILE PAUSED. Client; a layer over ZeD's two windows:
-- a glass element laid on each, and a check the focus manager asks.
--
-- While the game speed is 0, the Skills, Health, Info and Protection keys and
-- the Back wheel's Player Info open the Character window on its own, in place
-- of the game's own Character info window (ZeD_CharacterWindow.toggleBothPaired,
-- alone while paused: the World window waits for play). For as long as the
-- game stays paused its actions are greyed, and a World window already open is
-- held the same way. Moves between bags still go, as the game's drag does
-- while paused: they queue and run on play (KISS #41):
--   * a glass over the tab's page (not the tab strip, the bags or the window's
--     own box) takes every press and right press, so nothing there is used;
--     the wheel still scrolls what is under it;
--   * a veil over the item list lets the mouse through: a drag between bags
--     and a double-click that brings a thing into his inventory work; a
--     right-click, a double-click's quick use in his own bags and the
--     container buttons do nothing (the windows ask PL.on());
--   * each draws the drawer's colour thinly over what it covers and a line at
--     its top says why (the list's only while no page is open beside it);
--   * the controller's A and X do nothing there either (FocusManager asks
--     ZeD.PausedLook.blocks); X held drags a row to another bag, and its quick
--     use only brings a thing in (PL.blocksUse); the tab strip and the bags
--     still answer.
-- The game playing again takes the glass away the same frame. A dead
-- character needs nothing here: the windows close on death.
-- ============================================================================

require "ISUI/ISUIElement"
require "ZeD/Tokens"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.PausedLook = ZeD.PausedLook or {}
local PL = ZeD.PausedLook

local VEIL_A = 0.45     -- the drawer colour over what the glass covers
local NOTE_PAD = 6

-- paused: the game speed at 0 (the pause button, the pause menu, a mod's pause)
function PL.on()
    -- (KISS #51: the tour pauses the game itself while its balloons show; the windows it opens are not veiled for it)
    if ZeD.Tutorial and ZeD.Tutorial.running and ZeD.Tutorial.running() == true then return false end
    local ok, sp = pcall(getGameSpeed)
    return ok and sp == 0 or false
end

-- the windows held while paused: the Character window, and the World window's actions too, under the same veil
local function charWin() return ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow() end
local function worldWin() return ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow() end

-- the controls the controller may still use while paused: both windows' tab strips and bags, and
-- the pins in their title bars (WindowHalves: chrome, as the mouse's click on them)
local FREE_ZONES = { charTabBar = true, charContainerStrip = true, worldTabBar = true, worldContainerStrip = true,
    charTitlePins = true, worldTitlePins = true }
--- Should the controller's A and X do nothing on window w now? True while
--- paused on either ZeD window, except in its tab strip and its bags. (el, the
--- focused element, is passed by FocusManager and not read here.)
function PL.blocks(w, el)
    if not PL.on() then return false end
    if not w or (w ~= charWin() and w ~= worldWin()) then return false end
    local Focus = ZeD.Input and ZeD.Input.Focus
    local fz = Focus and Focus.liveZone and Focus.liveZone(w)
    if fz and FREE_ZONES[fz.zone] then return false end
    return true
end

--- Should a row's quick use (the controller's X held, the double-click's twin) do nothing on window w now? Paused,
--- it goes only where it is a move: a thing in another bag or around comes into his inventory; one already in his
--- own bags would be used (eaten, worn), so it waits for play. (KISS #41)
function PL.blocksUse(w, el)
    if not PL.on() then return false end
    if not w or (w ~= charWin() and w ~= worldWin()) then return false end
    local item = el and el.item
    if not item then return true end
    local p = w._playerObj or getSpecificPlayer(w.playerNum or 0)
    local ok, mine = pcall(function() return item:getContainer() == p:getInventory() end)
    return not ok or mine == true
end

-- ---------------------------------------------------------------------------
-- the glass
-- ---------------------------------------------------------------------------
ZeD_PausedGlass = ISUIElement:derive("ZeD_PausedGlass")

-- list: the veil over the item list (the mouse goes through it to the list: KISS #41)
function ZeD_PausedGlass:new(win, list)
    local o = ISUIElement.new(self, 0, 0, 1, 1)
    o.win = win
    o.list = list and true or false
    o.anchorLeft, o.anchorRight, o.anchorTop, o.anchorBottom = true, false, true, false
    return o
end

-- the portrait studio's camera button on the ID photo, where the glass lies over it: the studio moves nothing and uses
-- nothing, and it pauses the game anyway, so the button stays bright and takes its press (QA's Mac run, Nov 10 2026:
-- from a paused game the button did nothing). Its rectangle in the glass's space, or nil.
local function camRect(g)
    local cam = g.win and g.win._studioBtn
    if not (cam and cam:isVisible() and ZeD.Studio and ZeD.Studio.available and ZeD.Studio.available()) then return nil end
    local x, y = cam:getAbsoluteX() - g:getAbsoluteX(), cam:getAbsoluteY() - g:getAbsoluteY()
    local w, h = cam:getWidth(), cam:getHeight()
    if x + w <= 0 or y + h <= 0 or x >= g.width or y >= g.height then return nil end
    return x, y, w, h
end
PL._camRect = camRect

function ZeD_PausedGlass:prerender()
    local T = ZeD.T
    if not T then return end
    local db = T.drawerBg or T.surf1
    local cx, cy, cw, ch = camRect(self)
    if cx then
        -- the veil round the camera button: above it, below it, and either side of it
        local W, H = self.width, self.height
        local x0, y0 = math.max(0, cx), math.max(0, cy)
        local x1, y1 = math.min(W, cx + cw), math.min(H, cy + ch)
        self:drawRect(0, 0, W, y0, VEIL_A, db.r, db.g, db.b)
        self:drawRect(0, y1, W, H - y1, VEIL_A, db.r, db.g, db.b)
        self:drawRect(0, y0, x0, y1 - y0, VEIL_A, db.r, db.g, db.b)
        self:drawRect(x1, y0, W - x1, y1 - y0, VEIL_A, db.r, db.g, db.b)
    else
        self:drawRect(0, 0, self.width, self.height, VEIL_A, db.r, db.g, db.b)
    end
    -- the line at the top: why nothing answers (a surface strip across, the words in the default ink); the list's
    -- veil says it only while no page glass beside it does (KISS #41)
    if self.list and not self.note then return end
    local text = ZeD.tr(self.list and "UI_ZeD_Char_PausedMoves" or "UI_ZeD_Char_PausedLook")
    local f = T.fontF2
    local fh = ZeD.TM:getFontHeight(f)
    local h = fh + T.px(NOTE_PAD) * 2
    local s1, bd, tc = T.surf1, T.borderS, T.text
    self:drawRect(0, 0, self.width, h, 1, s1.r, s1.g, s1.b)
    self:drawRect(0, h - T.hair, self.width, T.hair, bd.a or 1, bd.r, bd.g, bd.b)
    local words = ZeD.Atoms and ZeD.Atoms.truncateText and ZeD.Atoms.truncateText(text, f, self.width - T.px(16)) or text
    local tw = ZeD.TM:MeasureStringX(f, words)
    self:drawText(words, math.floor((self.width - tw) / 2), T.px(NOTE_PAD), tc.r, tc.g, tc.b, tc.a or 1, f)
end

-- (the page glass eats every press; the list's veil takes none, the list under it answers: KISS #41)
local function eat(self) return not self.list end
ZeD_PausedGlass.onMouseDown = eat
-- (a release on the camera button opens the studio: camRect)
function ZeD_PausedGlass:onMouseUp(x, y)
    if self.list then return false end
    local cx, cy, cw, ch = camRect(self)
    if cx and x >= cx and y >= cy and x < cx + cw and y < cy + ch then
        local cam = self.win._studioBtn
        if cam.onMouseUp then cam:onMouseUp(x - cx, y - cy) end
    end
    return true
end
ZeD_PausedGlass.onRightMouseDown = eat
ZeD_PausedGlass.onRightMouseUp = eat
ZeD_PausedGlass.onMouseDoubleClick = eat

-- the wheel scrolls what lies under the glass (the tab's drawer, the item list)
function ZeD_PausedGlass:onMouseWheel(del)
    if self.list then return false end
    local win = self.win
    local mx, my = getMouseX(), getMouseY()
    local list = { win and win._drawerPanel, win and win._mainContent }
    if win and win._actionTabStrip then   -- (the World window: any of its panels under the pointer)
        list = {}
        for _, c in pairs(win:getChildren() or {}) do if c ~= self then list[#list + 1] = c end end
    end
    for _, c in ipairs(list) do
        -- (by place: the glass over it has the pointer, so the panel's own "mouse over" would say no)
        local over = c and c:isVisible() and mx >= c:getAbsoluteX() and mx < c:getAbsoluteX() + c:getWidth()
            and my >= c:getAbsoluteY() and my < c:getAbsoluteY() + c:getHeight()
        if over and c.onMouseWheel then
            local ok = pcall(c.onMouseWheel, c, del)
            if ok then return true end
        end
    end
    return true
end

-- where the glass lies: right of the tab strip, left of the bags, the window's body
function PL.rect(win)
    local strip, bags = win._tabStripPanel, win._containerStrip
    if not (strip and bags) then return nil end
    local x = strip:getX() + strip:getWidth()
    local w = bags:getX() - x
    if w <= 0 then return nil end
    return x, strip:getY(), w, strip:getHeight()
end

-- the World window's (it mirrors the Character window): right of its bags, left of its tab strip
function PL.worldRect(win)
    local bags, strip = win._containerStrip, win._actionTabStrip
    if not (bags and strip) then return nil end
    local x = bags:getX() + bags:getWidth()
    local w = strip:getX() - x
    if w <= 0 then return nil end
    return x, bags:getY(), w, bags:getHeight()
end

-- each frame before the UI draws: the glass on while paused, off while the game plays, on each window
local SLOTS = { { key = "_glass", kids = "_kids", get = charWin, rect = function(w) return PL.rect(w) end },
                { key = "_wglass", kids = "_wkids", get = worldWin, rect = function(w) return PL.worldRect(w) end } }
function PL.frame()
    for _, s in ipairs(SLOTS) do PL.frameFor(s) end
    PL.padHold()
end

-- the game ignores a controller while paused unless its focus says otherwise (activeWhilePaused): while ZeD's
-- Character or World window holds a pad's focus in a pause, that pad works (the D-pad, B, LB, RB; A and X held by
-- PL.blocks); it goes back to what it was when the window lets go or the game plays. Set every frame, so a wheel's
-- own put-back (ZeD_WheelGesture) cannot leave it off.
function PL.padHold()
    local paused = PL.on()
    local cw, ww = charWin(), worldWin()
    for i = 1, 4 do
        local jd = JoypadState and JoypadState.players and JoypadState.players[i]
        if jd then
            local held = paused and jd.focus ~= nil and (jd.focus == cw or jd.focus == ww)
            if held then
                if not jd._zedPausedHold then jd._zedPausedHold, jd._zedPausedWas = true, jd.activeWhilePaused end
                jd.activeWhilePaused = true
            elseif jd._zedPausedHold then
                jd.activeWhilePaused, jd._zedPausedHold, jd._zedPausedWas = jd._zedPausedWas, nil, nil
            end
        end
    end
end
-- One glass of a window's: made on first use, dropped when its window went, hidden while w is nil.
function PL.place(win, key, list, x, y, w, h)
    local g = PL[key]
    if g and g.win ~= win then
        pcall(function() g.win:removeChild(g) end)
        PL[key], g = nil, nil
    end
    if not (win and x and w and w > 0) then
        if g and g:isVisible() then g:setVisible(false) end
        return nil
    end
    if not g then
        g = ZeD_PausedGlass:new(win, list)
        g:initialise()
        g:instantiate()
        -- (the list's veil lets every press through to the list: KISS #41)
        if list then pcall(function() g.javaObject:setConsumeMouseEvents(false) end) end
        win:addChild(g)
        PL[key] = g
    end
    if g:getX() ~= x then g:setX(x) end
    if g:getY() ~= y then g:setY(y) end
    if g:getWidth() ~= w then g:setWidth(w) end
    if g:getHeight() ~= h then g:setHeight(h) end
    if not g:isVisible() then g:setVisible(true) end
    return g
end

-- The body's span split in two: the item list's part (the veil, KISS #41) and the page's (the glass), the larger
-- side left of the list or right of it (the Character window's page is left of its list, the World window's right).
-- Returns pageX, pageW, listX, listW (a part with no width: nil).
function PL.split(win, x, w)
    local c = win._contentPanel
    local shown = c and not win._rolled and c:isVisible()
    if not shown then return x, w, nil, nil end
    local l = math.max(x, c:getX())
    local r = math.min(x + w, c:getX() + c:getWidth())
    if r <= l then return x, w, nil, nil end
    local leftW, rightW = l - x, (x + w) - r
    local px, pw = nil, nil
    if leftW >= rightW and leftW > 0 then px, pw = x, leftW
    elseif rightW > 0 then px, pw = r, rightW end
    return px, pw, l, r - l
end

function PL.frameFor(s)
    local win = s.get()
    local want = win ~= nil and PL.on() and not win.windowShaded
    local x, y, w, h = nil, nil, nil, nil
    if want then x, y, w, h = s.rect(win) end
    local px, pw, lx, lw = nil, nil, nil, nil
    if x then px, pw, lx, lw = PL.split(win, x, w) end
    local g = PL.place(win, s.key, false, px, y, pw, h)
    local v = PL.place(win, s.key .. "List", true, lx, y, lw, h)
    if v then v.note = g == nil end   -- (the list's line only while no page glass says why)
    if not (g or v) then return end
    -- on top of whatever the tab added since (its figures, its fields): a child added after the glass sits over
    -- it (the order children are added is the order they draw and take the mouse), so a change in their count
    -- puts the glasses back on top
    local n = 0
    for _ in pairs(win:getChildren() or {}) do n = n + 1 end
    if n ~= PL[s.kids] then
        PL[s.kids] = n
        pcall(function()
            if v then win:removeChild(v); win:addChild(v) end
            if g then win:removeChild(g); win:addChild(g) end
        end)
    end
end

if Events and Events.OnPreUIDraw and not PL._hooked then
    PL._hooked = true
    Events.OnPreUIDraw.Add(function()
        local ok, err = pcall(PL.frame)
        if not ok and ZeD.logOnce then ZeD.logOnce("paused look", err) end
    end)
end

return PL
