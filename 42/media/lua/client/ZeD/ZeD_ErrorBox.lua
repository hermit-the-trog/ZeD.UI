-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ErrorBox.lua
-- ============================================================================
-- THE ERROR BOX: the game's red "ERROR" box at the screen's bottom right goes, and ZeD's own notice stands there.
-- Client-side. (Error box, the director, Nov 22 2026: "If we can hide it, hook it, and make our own, can remove our
-- message icon over there in the bottom right corner, because it's really more about the game than the player. So I
-- don't think it belongs on the player's belt or adjacent." Then, on the trick and its side effects: "hide it. Use
-- the trick.")
--
-- HIDING THE GAME'S BOX. The box is Java (zombie.core.logger.ExceptionLogger.render), drawn by Core.EndFrameUI after
-- UIManager.render, with no Lua handle. The trick (the joke mod Error Fixifier's): in the last OnPostUIDraw handler of
-- the frame a stencil rect is set off the screen and never cleared, so everything the game draws after the UI that
-- frame is clipped away, the red box with it. UIManager.render sets the stencil level back to 0 at the start of every
-- frame, so the UI itself never feels it. In game only (never the main menu), never in safe mode, and the "Error box"
-- tick under Safe mode in ZeD setup gives the game's own box back.
--
-- WHAT ELSE THE GAME DRAWS AFTER THE UI (IngameState.renderFrameUI, read from the game's bytecode, build 42) and what
-- happens to it here:
--   * ZomboidRadio.render: only the story sounds' debug text (SLSoundManager.renderDebug, debug mode). Radio and TV
--     lines are drawn in the world before the UI (and ZeD draws its own radio and TV): not touched.
--   * FPSGraph (the Display FPS key): hidden by the clip, so the clip stays off while the graph is up (the game's own
--     Lua mirror of that key, ISFPS.start).
--   * OnSleepingTick: the game only moves its sleeping clock (ISSleepingUI, a UI element drawn before); nothing drawn.
--   * ActiveMods.renderUI, JoypadManager.renderUI (OnJoypadRenderUI): debug options only. Moodles and the game's
--     controller marks are UI elements, drawn before: not touched. ZeD's own pad marks are ZeD's UI: not touched.
--   * Debug overlays (the chunk map, the corpse and item atlases, the anim picker, model outlines): debug mode only,
--     hidden while the trick is on (tick "Error box" in ZeD setup to see them).
--   * The game's own mouse pointer when "Lock cursor to window" is on and the offscreen UI is off: the clip stays off
--     then (Core.EndFrameUI draws that pointer after the box).
--
-- ZeD'S NOTICE (the Messages note that was on the belt, its role and look): a small box at the screen's bottom right
-- with the paper note and the count of what is new: red only for a new error of ZeD's own, the accent for a note, gray
-- for other mods' or the game's errors (K3 #42, ZeD.Belt.lampTone). It shows while anything is unread, and for a few
-- seconds after something new comes in (the count of what Messages holds rose: a new note, a new error entry); then it
-- hides itself, as the game's box did. No slide and no fade: it shows and hides plainly. A click, or A when the pad
-- reaches it from the belt's right end, opens Messages. Messages' balloons come out of it.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/ZeD_Panel"
require "ZeD/SafeMode"
require "ZeD/ZeD_Messages"

ZeD = ZeD or {}
ZeD.ErrorBox = ZeD.ErrorBox or {}
local E = ZeD.ErrorBox

E.SHOW_MS = 6000     -- how long the notice stays after something new, with nothing unread (the toasts' six seconds)
E.NOTE_U = 38        -- the notice's size in design units (the belt's old Messages note)
E.EDGE_U = 10        -- its gap from the screen's right and bottom edges
E.GAME_BOX_W = 100   -- the game's red box's width in pixels (ExceptionLogger.render): the notice stands left of it
                     -- while the game's box is given back
E.off = E.off or false   -- QA's switch: true leaves the game's box alone for this session

-- ---------------------------------------------------------------------------
-- HIDING THE GAME'S BOX
-- ---------------------------------------------------------------------------

--- True while the trick should run this frame: in game, not safe mode, not given back, nothing that needs the
--- after-UI drawing up. (Error box, the director, Nov 22 2026)
function E.hideWanted()
    if E.off then return false end
    -- (in game only: the main menu and the loading screens are other game states, never clipped)
    if not (isIngameState and isIngameState()) then return false end
    -- (safe mode, or the "Error box" tick in ZeD setup: the game's own box)
    if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on("errorbox") then return false end
    -- (the game's FPS graph draws after the UI: the game's own Lua mirror of its key says when it is up)
    if ISFPS and ISFPS.start then return false end
    -- (with the offscreen UI off, the game's own pointer for "Lock cursor to window" draws after the box in the same
    -- pass: it would be clipped too)
    local ok, risky = pcall(function()
        local c = getCore()
        return c:getOptionLockCursorToWindow() and not c:getOptionUIFBO()
    end)
    if ok and risky then return false end
    return true
end

-- the element the clip rect belongs to: never on the UI list, so it draws nothing and takes no clicks; off the screen,
-- so its stencil rect (the element's own place plus the rect) covers no pixel
local function clipElement()
    if E._clip and E._clip.javaObject then return E._clip end
    local el = ISUIElement:new(-64, -64, 1, 1)
    el:initialise()
    el:instantiate()   -- (the Java side, which setStencilRect is called on)
    E._clip = el
    return el
end

--- The frame's last OnPostUIDraw: the clip that hides the game's box. Called straight on the Java element, past
--- ISUIElement's Lua wrapper (ZeD_Surface counts the Lua calls: this one is never cleared, by design).
function E.postDraw()
    if not E.hideWanted() then return end
    local ok, err = pcall(function()
        local el = clipElement()
        el.javaObject:setStencilRect(0, 0, 1, 1)
    end)
    if not ok and ZeD.logOnce then ZeD.logOnce("Error box: the clip", err) end
end

-- It must run after every other OnPostUIDraw handler (anything after it would be clipped): added again at the game's
-- start and once more on the first tick after it, when every mod has added its own.
local function _post() E.postDraw() end
function E.lastInLine()
    if not (Events and Events.OnPostUIDraw) then return end
    Events.OnPostUIDraw.Remove(_post)
    Events.OnPostUIDraw.Add(_post)
end
local function _firstTick()
    E.lastInLine()
    Events.OnTick.Remove(_firstTick)
end
if Events and Events.OnGameStart and not E._hooked then
    E._hooked = true
    Events.OnGameStart.Add(function()
        E.lastInLine()
        Events.OnTick.Add(_firstTick)
    end)
end

-- ---------------------------------------------------------------------------
-- ZeD'S NOTICE: what it shows and when
-- ---------------------------------------------------------------------------

--- What Messages holds that a player would call new: an unread line counts 1, and each error entry filed on an
--- error's line counts 1 more (ZeD_Messages fileError: the game's entry count rising, not the raw number of entries,
--- since one Lua error writes several). The notes over his head never count (they are kept already read).
function E.arrivals()
    local M = ZeD.Messages
    local n = 0
    for _, s in pairs(M and M.sources or {}) do
        if s.kind ~= "halo" then
            for _, it in ipairs(s.items or {}) do
                if not it.read then n = n + 1 end
                if s.kind == "err" then n = n + (it.count or 0) end
            end
        end
    end
    return n
end

--- Keep the notice up for ms more (the tour's Guide step points at it).
function E.showFor(ms)
    local now = getTimestampMs and getTimestampMs() or 0
    E._until = math.max(E._until or 0, now + (ms or E.SHOW_MS))
end

--- Read once a frame: true while the notice shows. A rise in E.arrivals() starts the few seconds; anything unread,
--- a balloon of Messages on the screen or the pad on it keep it up.
function E.wanted(now)
    if not (getPlayer and getPlayer()) then return false end
    if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on() then return false end
    local M = ZeD.Messages
    if not M then return false end
    local a = E.arrivals()
    if a > (E._seen or 0) then E._until = math.max(E._until or 0, now + E.SHOW_MS) end
    E._seen = a   -- (a fall, a line read or deleted, starts nothing)
    if E.padOn() then return true end
    if (E._until or 0) > now then return true end
    local un = M.unread and M.unread() or 0
    if un > 0 then return true end
    return #(M.toasts or {}) > 0
end

--- The notice's place on the whole screen: x, y, size. The bottom right corner, EDGE_U in; left of the game's own
--- box while that is given back, and left of the split-screen speed strip while it shows.
function E.rect()
    local T = ZeD.T
    local s = T.px(E.NOTE_U)
    local edge = T.px(E.EDGE_U)
    local c = getCore()
    local x = c:getScreenWidth() - s - edge
    local y = c:getScreenHeight() - s - edge
    if not E.hideWanted() then x = x - E.GAME_BOX_W end
    local SS = ZeD.SplitSpeed and ZeD.SplitSpeed._instance
    if SS and SS:isVisible() then x = math.min(x, SS:getX() - s - edge) end
    return x, y, s
end

--- Where Messages' balloons come out (screen pixels): the notice's top middle while it shows on this player's part
--- of the screen, else nil (ZeD_MessagesWindow then uses its own fallbacks).
function E.anchor(pn)
    local el = E._note
    if not (el and el:getIsVisible()) then return nil end
    local x, y, s = el:getX(), el:getY(), el:getWidth()
    pn = pn or 0
    local l, t = getPlayerScreenLeft(pn), getPlayerScreenTop(pn)
    local cx = x + math.floor(s / 2)
    if cx < l or cx > l + getPlayerScreenWidth(pn) or y < t or y > t + getPlayerScreenHeight(pn) then return nil end
    return cx, y
end

--- The pad from the belt: true when player pn's pad may step onto the notice (player one's, while it shows).
function E.padReach(pn)
    return (pn or 0) == 0 and E._note ~= nil and E._note:getIsVisible()
end
--- The belt's pad steps on (true) or off (nil) the notice.
function E.setPad(on) E._pad = on and true or nil end
--- True while player one's pad is on the notice: the belt says so, and the belt still holds the pad (another window
--- that took the pad leaves no mark behind here).
function E.padOn()
    if not E._pad then return false end
    local B = ZeD.Belt
    local hud = B and B.getHUD and B.getHUD(0)
    local jd = JoypadState and JoypadState.players and JoypadState.players[1]
    if hud and hud._gp and hud._gp.notice and not (jd and jd.focus ~= hud) then return true end
    E._pad = nil
    return false
end

--- A click or A on the notice: Messages opens (the belt's note opened it before).
function E.press()
    pcall(function() ZeD.uiSound("UIActivateButton") end)
    if ZeD.Messages and ZeD.Messages.open then ZeD.Messages.open() end
end

-- ---------------------------------------------------------------------------
-- ZeD'S NOTICE: the element
-- ---------------------------------------------------------------------------
ZeD_ErrorNotice = ZeD_Panel:derive("ZeD_ErrorNotice")

function ZeD_ErrorNotice:new()
    local o = ZeD_Panel:new(0, 0, 10, 10)
    setmetatable(o, self)
    self.__index = self
    o.playerNum = 0
    o._zedLabel = "ErrorNotice"
    o.anchorRight, o.anchorBottom = false, false
    o._mkOpts = { win = o, focused = true }   -- (the pad's mark: the belt says when the pad is here)
    return o
end

local noteTex = nil
function ZeD_ErrorNotice:prerender()
    local T = ZeD.T
    if not T then return end
    local w, h = self.width, self.height
    local s1, bd = T.surf1, T.borderS
    self:drawRect(0, 0, w, h, 0.92, s1.r, s1.g, s1.b)
    local over = self:isMouseOver()
    local pad = E.padOn()
    if pad then ZeD.Focus.mark(self, 0, 0, w, h, self._mkOpts)
    elseif over then local hv = T.hover; self:drawRect(0, 0, w, h, hv.a or 0.2, hv.r, hv.g, hv.b) end
    self:drawRectBorder(0, 0, w, h, 1, bd.r, bd.g, bd.b)
    -- the map's flyer note without its pin, pixel art at a whole zoom (the belt's note's picture)
    if noteTex == nil then noteTex = getTexture("media/textures/ZeD/icons/msg_note.png") or false end
    if noteTex then
        local k = math.max(1, math.floor(h * 0.75 / 14))
        local iw, ih = 13 * k, 14 * k
        self:drawTextureScaledAspect(noteTex, math.floor((w - iw) / 2), math.floor((h - ih) / 2), iw, ih, 1, 1, 1, 1)
    end
    local M = ZeD.Messages
    local un = M.unread()
    if un > 0 then
        local t = tostring(un > 99 and "99" or un)
        local f = T.fontF1
        local pw, ph = ZeD.TM:MeasureStringX(f, t) + T.px(6), ZeD.TM:getFontHeight(f) + T.px(2)
        -- red only for a new error of ZeD's own, the accent for a new note, gray for other mods' or the game's
        -- errors, nothing he can fix (KISS #42, as the belt's note was)
        local tone = ZeD.Belt and ZeD.Belt.lampTone and ZeD.Belt.lampTone() or nil
        local c = (tone == "ours" and T.danger) or (tone == "note" and T.accent) or T.textDim
        local ink = T.base or { r = 0.05, g = 0.05, b = 0.05 }
        -- (inside the box's top right: the corner leaves no room above or to the right)
        self:drawRect(w - pw, 0, pw, ph, 1, c.r, c.g, c.b)
        self:drawText(t, w - pw + T.px(3), T.px(1), ink.r, ink.g, ink.b, 1, f)
    end
    -- the hint: "Messages", or "Messages | 3 new" (the belt's note's words); the pad's once it has rested here
    if over or pad then
        ZeD.Atoms.requestHint(self, "note", ZeD.tr(un > 0 and "UI_ZeD_Msg_LampNew" or "UI_ZeD_Msg_Title", un), self,
            { x = 0, y = 0, w = w, h = h }, (not over) and { now = true } or nil)
    end
    ZeD.Focus.drawOverlay(self, self)
end
function ZeD_ErrorNotice:render() end

function ZeD_ErrorNotice:onMouseDown(x, y)
    E.press()
    return true
end
function ZeD_ErrorNotice:onMouseUp(x, y) return true end

-- shown or not, and where, before each frame draws (a hidden element gets no prerender to show itself again)
function E.frame()
    local el = E._note
    if not (el and ZeD.T) then return end
    local now = getTimestampMs and getTimestampMs() or 0
    local want = E.wanted(now)
    if want then
        local x, y, s = E.rect()
        if el.x ~= x then el:setX(x) end
        if el.y ~= y then el:setY(y) end
        if el.width ~= s then el:setWidth(s); el:setHeight(s) end
    end
    if want ~= el:getIsVisible() then el:setVisible(want) end
end

--- Made once a game is on (one notice for the whole screen, as the game's box was one).
function E.install()
    if E._note then return E._note end
    local el = ZeD_ErrorNotice:new()
    el:initialise()
    el:addToUIManager()
    el:setAlwaysOnTop(true)
    el:setVisible(false)
    E._note = el
    E._seen = E.arrivals()   -- (what Messages already holds is not new)
    return el
end

if Events and not E._frameHooked then
    E._frameHooked = true
    if Events.OnGameStart then Events.OnGameStart.Add(function() pcall(E.install) end) end
    if Events.OnPreUIDraw then
        Events.OnPreUIDraw.Add(function()
            local ok, err = pcall(E.frame)
            if not ok and ZeD.logOnce then ZeD.logOnce("Error box: the notice", err) end
        end)
    end
end

print("[ZeD] Error box: module loaded")
return E
