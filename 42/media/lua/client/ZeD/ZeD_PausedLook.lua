-- ZeD-UI/42/media/lua/client/ZeD/ZeD_PausedLook.lua
-- ============================================================================
-- THE CHARACTER WINDOW WHILE PAUSED (the director, Nov 7 2026, vanilla windows
-- B14: "the Character window opens while paused, read-only (actions grayed
-- until unpaused)").
--
-- Until now ZeD stepped aside whenever the game speed was 0, and the game's
-- own Character info window showed for the Skills, Health, Info and
-- Protection keys and the Back wheel's Player Info. Now the Character window
-- opens on its own (ZeD_CharacterWindow.toggleBothPaired, alone while paused:
-- the World window waits for play) and, for as long as the game stays paused,
-- it is for looking:
--   * a glass over the tab and the item list (not the tab strip, the bags on
--     the right or the window's own box) takes every press and right press, so
--     nothing is used, moved, dropped or queued; the wheel still scrolls what
--     is under it;
--   * the glass draws the drawer's colour thinly over what it covers (the
--     actions read as greyed) and a line at its top says why;
--   * the controller's A and X do nothing there either (FocusManager asks
--     ZeD.PausedLook.blocks); the tab strip and the bags still answer.
-- The game playing again takes the glass away the same frame. A dead
-- character stays as before (the windows close on death).
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
    local ok, sp = pcall(getGameSpeed)
    return ok and sp == 0 or false
end

-- the windows held while paused (the director, Nov 7 2026: the World window's actions too, with the same veil)
local function charWin() return ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow() end
local function worldWin() return ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow() end

-- the controls the controller may still use while paused: the tab strips and the Character window's bags
local FREE_ZONES = { charTabBar = true, charContainerStrip = true, worldTabBar = true, worldContainerStrip = true }
function PL.blocks(w, el)
    if not PL.on() then return false end
    if not w or (w ~= charWin() and w ~= worldWin()) then return false end
    local Focus = ZeD.Input and ZeD.Input.Focus
    local fz = Focus and Focus.liveZone and Focus.liveZone(w)
    if fz and FREE_ZONES[fz.zone] then return false end
    return true
end

-- ---------------------------------------------------------------------------
-- the glass
-- ---------------------------------------------------------------------------
ZeD_PausedGlass = ISUIElement:derive("ZeD_PausedGlass")

function ZeD_PausedGlass:new(win)
    local o = ISUIElement.new(self, 0, 0, 1, 1)
    o.win = win
    o.anchorLeft, o.anchorRight, o.anchorTop, o.anchorBottom = true, false, true, false
    return o
end

function ZeD_PausedGlass:prerender()
    local T = ZeD.T
    if not T then return end
    local db = T.drawerBg or T.surf1
    self:drawRect(0, 0, self.width, self.height, VEIL_A, db.r, db.g, db.b)
    -- the line at the top: why nothing answers (a surface strip across, the words in the default ink)
    local text = ZeD.tr("UI_ZeD_Char_PausedLook")
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

local function eat() return true end
ZeD_PausedGlass.onMouseDown = eat
ZeD_PausedGlass.onMouseUp = eat
ZeD_PausedGlass.onRightMouseDown = eat
ZeD_PausedGlass.onRightMouseUp = eat
ZeD_PausedGlass.onMouseDoubleClick = eat

-- the wheel scrolls what lies under the glass (the tab's drawer, the item list)
function ZeD_PausedGlass:onMouseWheel(del)
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
function PL.frameFor(s)
    local win = s.get()
    local g = PL[s.key]
    if g and g.win ~= win then
        pcall(function() g.win:removeChild(g) end)
        PL[s.key], g = nil, nil
    end
    if not win then return end
    local want = PL.on() and not win.windowShaded
    if not want then
        if g and g:isVisible() then g:setVisible(false) end
        return
    end
    local x, y, w, h = s.rect(win)
    if not x then return end
    if not g then
        g = ZeD_PausedGlass:new(win)
        g:initialise()
        g:instantiate()
        win:addChild(g)
        PL[s.key] = g
    end
    if g:getX() ~= x then g:setX(x) end
    if g:getY() ~= y then g:setY(y) end
    if g:getWidth() ~= w then g:setWidth(w) end
    if g:getHeight() ~= h then g:setHeight(h) end
    if not g:isVisible() then g:setVisible(true) end
    -- on top of whatever the tab added since (its figures, its fields): a child added after the glass sits over
    -- it (the order children are added is the order they draw and take the mouse), so a change in their count
    -- puts the glass back on top
    local n = 0
    for _ in pairs(win:getChildren() or {}) do n = n + 1 end
    if n ~= PL[s.kids] then
        PL[s.kids] = n
        pcall(function() win:removeChild(g); win:addChild(g) end)
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
