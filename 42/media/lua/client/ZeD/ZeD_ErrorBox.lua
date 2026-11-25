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
-- ZeD'S NOTICE (the Messages note that was on the belt, its role and look): a small box with the paper note and the
-- count of what is new: red only for a new error of ZeD's own, the accent for a note, gray for other mods' or the
-- game's errors (K3 #42, ZeD.Belt.lampTone). It stands on player one's belt row, after the speed keys and before the
-- chat key, and shows there all the time the belt draws (Belt row, the director, Nov 23 2026: "Belt, space, time,
-- space, messages, chat"; ZeD.Belt.noticeScreen). While the belt is away (driving, hidden, dead) it falls back to the
-- screen's bottom right corner, so an error is never lost: there it shows while anything is unread, and for a few
-- seconds after something new comes in (the count of what Messages holds rose: a new note, a new error entry); then
-- it hides itself, as the game's box did. No fade: it shows and hides plainly. A click, or A when the belt's pad walk
-- reaches it, opens Messages. Messages' balloons come out of it, on the row or in the corner.
--
-- THE MARKER (ZeD's own red box in the game's box's place): when a new error is filed, a box the notice's width rises
-- from the screen's bottom edge under the notice (on the row or in the corner, the same way: it ends where the
-- notice's bottom stood) and lifts the notice with it, holds about 3 s and slides back down,
-- the marker off the screen and the notice to its place. A plain linear slide, 0.5 s up and 0.5 s down, as the game's
-- box moved; the one motion ZeD allows here. Red for ZeD's own errors, gray for other mods' or the game's; notes get
-- none. More errors while it is up keep it up longer. (Error marker, the director, Nov 22 2026: "a red box the width
-- of the message box, and it comes from the bottom of the screen up. It bumps the message box up with it, and then it
-- drops back down")
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

--- True while the notice may show at all (a character, not safe mode, Messages loaded): player one's belt row then
--- keeps its place for it (ZeD.Belt.noticeOnRow). (Belt row, the director, Nov 23 2026)
function E.rowWanted()
    if not (getPlayer and getPlayer()) then return false end
    if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on() then return false end
    return ZeD.Messages ~= nil
end

--- The notice's place on the whole screen: x, y, size, and true when that is on the belt row. On player one's row
--- while the belt draws it a place (ZeD.Belt.noticeScreen: after the speed keys, before the chat key); else the bottom
--- right corner, EDGE_U in; left of the game's own box while that is given back, and left of the split-screen speed
--- strip while it shows.
function E.rect()
    local B = ZeD.Belt
    if B and B.noticeScreen then
        local ok, rx, ry, rs = pcall(B.noticeScreen, 0)
        if ok and rx then return rx, ry, rs, true end
    end
    local T = ZeD.T
    local s = T.px(E.NOTE_U)
    local edge = T.px(E.EDGE_U)
    local c = getCore()
    local x = c:getScreenWidth() - s - edge
    local y = c:getScreenHeight() - s - edge
    if not E.hideWanted() then x = x - E.GAME_BOX_W end
    local SS = ZeD.SplitSpeed and ZeD.SplitSpeed._instance
    if SS and SS:isVisible() then x = math.min(x, SS:getX() - s - edge) end
    return x, y, s, false
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
--- True while player one's pad is on the notice: the belt's pad walk is on its place on the row ("notice", in row
--- order), and the belt still holds the pad (another window that took the pad leaves no mark behind here).
--- (Belt row, the director, Nov 23 2026)
function E.padOn()
    local B = ZeD.Belt
    local hud = B and B.getHUD and B.getHUD(0)
    if not (hud and hud._gp and hud._gpBox) then return false end
    local jd = JoypadState and JoypadState.players and JoypadState.players[1]
    if jd and jd.focus ~= hud then return false end
    local b = hud:_gpBox()
    return b ~= nil and b.kind == "notice" and not hud._gp.inList
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
    -- the belt row's white block, here and in the corner alike (WHITE BLOCKS, ZeD_Belt.lua; the director, Nov 24
    -- 2026: the Messages icon "did not receive the updated background and framing"): System 7's hard shadow, the
    -- paper, a one-unit ink edge, the same in every theme
    local BL = ZeD.Belt
    local s1 = (BL and BL.PAPER) or { r = 0.95, g = 0.95, b = 0.95 }
    local bd = (BL and BL.INK) or { r = 0.08, g = 0.08, b = 0.08 }
    ZeD.Atoms.drawHardShadow(self, 0, 0, w, h)
    self:drawRect(0, 0, w, h, 1, s1.r, s1.g, s1.b)
    local over = self:isMouseOver()
    local pad = E.padOn()
    if pad then ZeD.Focus.mark(self, 0, 0, w, h, self._mkOpts)
    elseif over then local hv = T.hover; self:drawRect(0, 0, w, h, hv.a or 0.2, hv.r, hv.g, hv.b) end
    for i = 0, (T.hair or 1) - 1 do self:drawRectBorder(i, i, w - 2 * i, h - 2 * i, 1, bd.r, bd.g, bd.b) end
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

-- ---------------------------------------------------------------------------
-- THE MARKER: what it shows and when (Error marker, the director, Nov 22 2026)
-- ---------------------------------------------------------------------------
E.RISE_MS = 500    -- the slide up (the game's box took about half a second)
E.HOLD_MS = 3000   -- how long it stays up after the last new error (the game's box's few seconds)
E.FALL_MS = 500    -- the slide back down
-- the marker's state: phase nil (down, hidden), "up" (rising), "hold" or "down" (falling); p how far up, 0 to 1;
-- t the last frame's time; holdEnd when the hold ends; count the errors filed since it started; kind "ours" or "others"
E._mk = E._mk or { phase = nil, p = 0, t = 0, holdEnd = 0, count = 0, kind = nil }

--- The error entries Messages has filed, ZeD's own and everyone else's: the totals of each error line's count.
function E.errorTotals()
    local M = ZeD.Messages
    local B = ZeD.Belt
    local ours, others = 0, 0
    for name, s in pairs(M and M.sources or {}) do
        if s.kind == "err" then
            -- (the same test as the badge's red: ZeD's own mod name)
            local mine
            if B and B.isZeDSource then mine = B.isZeDSource(name) else mine = tostring(name):sub(1, 7) == "ZeD-GUI" end
            for _, it in ipairs(s.items or {}) do
                if mine then ours = ours + (it.count or 0) else others = others + (it.count or 0) end
            end
        end
    end
    return ours, others
end

--- True while the marker may show: a character, not safe mode, and the game's own box hidden (with it given back, or
--- up for the FPS graph or the locked pointer, the game's box shows and there is no second one).
function E.markAllowed()
    if not (getPlayer and getPlayer()) then return false end
    if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on() then return false end
    return E.hideWanted()
end

-- moves the marker on by dt ms; it can cross from one phase to the next within one frame (a long frame)
local function markAdvance(k, dt, now)
    for _ = 1, 3 do
        if k.phase == "up" then
            k.p = k.p + dt / E.RISE_MS
            if k.p < 1 then return end
            dt = (k.p - 1) * E.RISE_MS   -- (the time since it reached the top)
            k.p = 1
            k.phase = "hold"
            k.holdEnd = math.max(k.holdEnd or 0, now - dt + E.HOLD_MS)
        elseif k.phase == "hold" then
            if now < k.holdEnd then return end
            dt = now - k.holdEnd   -- (the time since the hold ended)
            k.phase = "down"
        elseif k.phase == "down" then
            k.p = k.p - dt / E.FALL_MS
            if k.p > 0 then return end
            k.phase, k.p, k.count, k.kind = nil, 0, 0, nil
            return
        else
            return
        end
    end
end

--- Once a frame: reads the new error entries and moves the marker. Returns its state (E._mk).
function E.markStep(now)
    local k = E._mk
    local ours, others = E.errorTotals()
    -- (the first look, and a fall when a line is deleted, start nothing)
    local dOurs = math.max(0, ours - (E._mkOurs or ours))
    local dOthers = math.max(0, others - (E._mkOthers or others))
    E._mkOurs, E._mkOthers = ours, others
    if not E.markAllowed() then
        k.phase, k.p, k.count, k.kind, k.t = nil, 0, 0, nil, now
        return k
    end
    markAdvance(k, math.max(0, now - (k.t or now)), now)
    k.t = now
    local new = dOurs + dOthers
    if new > 0 then
        k.count = (k.count or 0) + new
        -- (red once one of ZeD's own came in; gray for other mods' or the game's)
        if dOurs > 0 then k.kind = "ours" elseif not k.kind then k.kind = "others" end
        if k.phase == nil then
            k.phase, k.p = "up", 0
            -- (under the hint strip and the rest of the HUD: to the back of the UI list each time it starts)
            if E._marker then pcall(function() E._marker:backMost() end) end
        elseif k.phase == "down" then
            k.phase = "up"   -- (back up from where it is, no jump)
        end
        -- (more while it is up: the hold runs on from the newest, the slide does not start again)
        k.holdEnd = math.max(k.holdEnd or 0, now + E.HOLD_MS)
    end
    return k
end

--- The marker's size in pixels: the notice's width, two lines of the badge's font high.
function E.markSize()
    local T = ZeD.T
    local fh = ZeD.TM and ZeD.TM.getFontHeight and ZeD.TM:getFontHeight(T.fontF1) or T.px(14)
    return T.px(E.NOTE_U), fh * 2 + T.px(6)
end

ZeD_ErrorMarker = ZeD_Panel:derive("ZeD_ErrorMarker")

function ZeD_ErrorMarker:new()
    local o = ZeD_Panel:new(0, 0, 10, 10)
    setmetatable(o, self)
    self.__index = self
    o.playerNum = 0
    o._zedLabel = "ErrorMarker"
    o.anchorRight, o.anchorBottom = false, false
    return o
end

function ZeD_ErrorMarker:prerender()
    local T = ZeD.T
    if not T then return end
    local w, h = self.width, self.height
    local k = E._mk
    -- red for ZeD's own errors, gray for other mods' or the game's (the badge's colors)
    local c = (k.kind == "ours") and T.danger or T.textDim
    self:drawRect(0, 0, w, h, 1, c.r, c.g, c.b)
    if self:isMouseOver() then local hv = T.hover; self:drawRect(0, 0, w, h, hv.a or 0.2, hv.r, hv.g, hv.b) end
    local bd = T.borderS
    self:drawRectBorder(0, 0, w, h, 1, bd.r, bd.g, bd.b)
    local ink = T.base or { r = 0.05, g = 0.05, b = 0.05 }
    local tm = ZeD.TM
    local word = ZeD.tr("UI_ZeD_ErrorBox_Marker")
    local num = tostring(math.min(k.count or 0, 99))
    -- (the badge's font; the small one when this language's word is wider than the box)
    local f = T.fontF1
    if tm:MeasureStringX(f, word) > w - T.px(4) then f = T.fontF5 end
    local fh = tm:getFontHeight(f)
    local top = math.floor((h - fh * 2) / 2)
    self:drawText(word, math.floor((w - tm:MeasureStringX(f, word)) / 2), top, ink.r, ink.g, ink.b, 1, f)
    self:drawText(num, math.floor((w - tm:MeasureStringX(f, num)) / 2), top + fh, ink.r, ink.g, ink.b, 1, f)
end
function ZeD_ErrorMarker:render() end

-- a click opens Messages, as the notice does
function ZeD_ErrorMarker:onMouseDown(x, y)
    E.press()
    return true
end
function ZeD_ErrorMarker:onMouseUp(x, y) return true end

-- shown or not, and where, before each frame draws (a hidden element gets no prerender to show itself again)
function E.frame()
    local el = E._note
    if not (el and ZeD.T) then return end
    local now = getTimestampMs and getTimestampMs() or 0
    local k = E.markStep(now)
    local want = E.wanted(now)
    -- the notice's place: on player one's belt row (shown all the time the belt draws), or the corner
    local nx, ny, ns, onRow = E.rect()
    if onRow then want = true end
    -- the marker: its top p of the way from the screen's bottom edge to its own height above where the notice's
    -- bottom stands (the corner's EDGE_U; on the row the belt's place), so at the top it fills the notice's place and
    -- the notice rides on it, the same on the row as in the corner (Belt row, the director, Nov 23 2026)
    local mk = E._marker
    local top = nil
    if mk then
        local on = k.phase ~= nil
        if on then
            local x = nx
            local mw, mh = E.markSize()
            local sh = getCore():getScreenHeight()
            local under = math.max(0, sh - (ny + ns))   -- (from the notice's bottom to the screen's bottom edge)
            top = sh - math.floor((mh + under) * k.p + 0.5)
            if mk.x ~= x then mk:setX(x) end
            if mk.y ~= top then mk:setY(top) end
            if mk.width ~= mw then mk:setWidth(mw) end
            if mk.height ~= mh then mk:setHeight(mh) end
            -- (QA EB 12c at 1280x800, Nov 22 2026: other HUD pieces sent to the back after the slide began left the
            -- marker over the hint strip; to the back every frame it shows, a few seconds at a time, so the strip and
            -- the rest of the HUD always draw over it)
            pcall(function() mk:backMost() end)
        end
        if on ~= mk:getIsVisible() then mk:setVisible(on) end
    end
    if want then
        local x, y, s = nx, ny, ns
        -- (the marker pushes the notice up once its top reaches the notice's bottom: lifted by its height at the top)
        if top then y = math.min(y, top - s) end
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
    -- the marker: under the HUD, not always on top (Error marker, the director, Nov 22 2026)
    local mk = ZeD_ErrorMarker:new()
    mk:initialise()
    mk:addToUIManager()
    mk:setVisible(false)
    pcall(function() mk:backMost() end)
    E._marker = mk
    E._mkOurs, E._mkOthers = E.errorTotals()   -- (errors filed before the game started are not new)
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
