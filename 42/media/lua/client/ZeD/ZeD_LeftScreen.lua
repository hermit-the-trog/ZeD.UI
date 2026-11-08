-- ZeD-UI/42/media/lua/client/ZeD/ZeD_LeftScreen.lua
-- ============================================================================
-- KICKED OR DISCONNECTED: ZeD's desk screen with the reason and, for a ban, the appeal line. Client-side organisms (the
-- window and the desk behind it); ZeD_CommunityCards.lua opens them from the game's disconnect hook. Where the game
-- showed its two buttons over the frozen world (ISServerDisconnectUI), the desk comes back: the room and the monitor as
-- at the main menu, and on the monitor a ZeD window (the pause window's kind, ZeD_MMWindow): what happened, the game's
-- own words for it, for a ban the server's appeal line, and in the band Quit to desktop and Exit to the main menu (the
-- game's own two calls, through its screen).
--
-- The game's words: the engine draws the reason itself (ServerDisconnectState.render: GameWindow.kickReason, or
-- "Connection to server lost", centered on the screen in the Medium face, after every Lua window). Lua can neither stop
-- nor move that line, so the window keeps a dark slot for it exactly where the engine puts it: the line sits in the
-- window, readable on every theme (the engine's words are white).
--
-- The state clears every Lua event on its way in (LuaEventManager.ResetCallbacks): nothing here waits on OnTick. The desk
-- takes the pointer and the controller itself. If anything fails, the game's own screen stays as it was.
-- ============================================================================

require "ISUI/ISPanel"
require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MouseTick"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.LeftScreen = ZeD.LeftScreen or {}
local LS = ZeD.LeftScreen
local MM = ZeD.MainMenu

local U = { W = 460, PAD = 14, SLOT_PAD = 8, LINE_GAP = 6 }
local REASON = "ZEDREASON"
local BAN_KEYS = { "UI_OnConnectFailed_Banned", "UI_OnConnectFailed_BannedReason" }

local function px(n) return ZeD.T.px(n) end
local function tr(k, ...) return ZeD.tr(k, ...) end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
local function fh(f) return ZeD.TM:getFontHeight(f) end

--- True when a disconnect reason is a ban: the game's ban words, each cut where its reason goes, found in it (as
--- ZeD_Community.lua reads the kick and ban words).
function LS.isBan(reason)
    if type(reason) ~= "string" then return false end
    for _, key in ipairs(BAN_KEYS) do
        local words = safe(function() return getText(key, REASON) end, nil)
        if words and words ~= key then
            local cut = string.find(words, REASON, 1, true)
            local head = string.gsub(cut and string.sub(words, 1, cut - 1) or words, "%s+$", "")
            if head ~= "" and string.find(reason, head, 1, true) then return true end
        end
    end
    return string.find(reason, "You were banned", 1, true) ~= nil
end

-- what the window says. info = { reason, kind = "ban" | "kick" | nil, appeal }
function LS.lines(info)
    local head
    if info.kind == "ban" then head = tr("UI_ZeD_Left_Banned")
    elseif info.kind == "kick" then head = tr("UI_ZeD_Left_Kicked")
    else head = tr("UI_ZeD_Left_Lost") end
    local below = {}
    if info.kind == "ban" and info.appeal and info.appeal ~= "" then below[1] = tr("UI_ZeD_Adm_SeeAppeal", info.appeal) end
    return head, below
end

-- ---------------------------------------------------------------------------
-- THE WINDOW ON THE MONITOR
-- ---------------------------------------------------------------------------
ZeD_MMLeft = ZeD_MMWindow:derive("ZeD_MMLeft")

function ZeD_MMLeft:new(info)
    local o = ZeD_MMWindow.new(self, "left")
    o.info = info
    o.noResetControl = true
    o.focusId = "exit"
    return o
end

function ZeD_MMLeft:pctx() return self.ctx end

function ZeD_MMLeft:build()
    local T = ZeD.T
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local pad = px(U.PAD)
    local tb = T.titleBarH
    local med = UIFont.Medium
    local reasonW = safe(function() return ZeD.TM:MeasureStringX(med, LS.engineWords(self.info)) end, 0)
    local w = math.min(sw - px(20), math.max(px(U.W), reasonW + pad * 4))
    local head, below = LS.lines(self.info)
    local f2 = T.fontF2
    self._headLines = ZeD.Atoms.wrapText(head, T.fontF4, w - pad * 2)
    self._below = {}
    for _, s in ipairs(below) do
        for _, l in ipairs(ZeD.Atoms.wrapText(s, f2, w - pad * 2)) do self._below[#self._below + 1] = l end
    end
    -- the slot for the engine's line: its top where the engine draws it (the screen's middle)
    local slotH = fh(med) + px(U.SLOT_PAD) * 2
    local headH = #self._headLines * fh(T.fontF4)
    local slotTop = math.floor(sh / 2) - px(U.SLOT_PAD)
    local wy = slotTop - pad - headH - px(U.LINE_GAP) - tb
    local y = tb + pad
    self._headY = y
    y = y + headH + px(U.LINE_GAP)
    self._slot = { y = y, h = slotH }
    y = y + slotH + px(U.LINE_GAP)
    self._belowY = y
    y = y + #self._below * fh(f2) + pad
    self._head, self._mods, self._card = nil, nil, nil
    self.title = tr("UI_ZeD_Left_Title")
    self.titleStats = nil
    self._specs = {}
    self._strip = { y = y, h = MM.bandH() }
    self._ask = nil
    self._bandBtns = {
        { id = "quit", text = getText("IGUI_PostDeath_Quit"), fn = function() LS.quit() end, help = tr("UI_ZeD_MMHelp_QuitDesktopNow") },
        { id = "exit", text = getText("IGUI_PostDeath_Exit"), variant = "primary", fn = function() LS.exit() end, help = tr("UI_ZeD_Left_HelpExit") },
    }
    self._bandRow = 1
    y = y + self._strip.h
    local h = y + self:footerHeight()
    local x = math.floor((sw - w) / 2)
    wy = math.max(0, math.min(wy, sh - h))
    if self.x ~= x or self.y ~= wy then self:setX(x); self:setY(wy) end
    if self.width ~= w or self.height ~= h then self:setWidth(w); self:setHeight(h) end
    return self._specs
end

function ZeD_MMLeft:prerender()
    local was = MM.forceGamepad
    MM.forceGamepad = LS.pad ~= nil   -- (the window's focus mark and prompts read MM.gamepad: here the desk holds the pad)
    local ok, err = pcall(ZeD_MMWindow.prerender, self)
    MM.forceGamepad = was
    if not ok then
        -- (a draw that fails hands the screen back to the game's own, at once: its Exit and Quit are never lost)
        if ZeD.logOnce then ZeD.logOnce("left screen draw", err) end
        LS.giveBack()
        return
    end
    local T = ZeD.T
    local pad = px(U.PAD)
    local tc, dc = T.textHead or T.text, T.text
    for i, s in ipairs(self._headLines or {}) do
        self:drawText(s, pad, self._headY + (i - 1) * fh(T.fontF4), tc.r, tc.g, tc.b, tc.a or 1, T.fontF4)
    end
    -- the slot: the engine writes its own words here in white, so it is dark on every theme
    local sl = self._slot
    if sl then
        self:drawRect(pad, sl.y, self.width - pad * 2, sl.h, 1, 0.06, 0.06, 0.07)
        ZeD.Atoms.frame(self, pad, sl.y, self.width - pad * 2, sl.h, T.borderS)
    end
    for i, s in ipairs(self._below or {}) do
        self:drawText(s, pad, self._belowY + (i - 1) * fh(T.fontF2), dc.r, dc.g, dc.b, dc.a or 1, T.fontF2)
    end
end

function ZeD_MMLeft:update()
    ZeD_Window.update(self)
    MM.pointer(self.ctx, { self })
end

function ZeD_MMLeft:close() end            -- (the close box: there is nowhere to go back to)
function ZeD_MMLeft:joyB() LS.quitAsk() end   -- (B is the game's own B here: Quit to desktop)
function ZeD_MMLeft:getFooterPrompts()
    if not LS.pad then return nil end
    return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") } }
end

-- the engine's words, as it draws them (for the window's width)
function LS.engineWords(info)
    local r = info and info.reason
    if type(r) ~= "string" or r == "" then return "Connection to server lost" end
    return r
end

-- ---------------------------------------------------------------------------
-- THE DESK BEHIND IT (the main menu's room, its monitor's wallpaper and glass)
-- ---------------------------------------------------------------------------
ZeD_LeftDesk = ISPanel:derive("ZeD_LeftDesk")

function ZeD_LeftDesk:new()
    local core = getCore()
    local o = ISPanel:new(0, 0, core:getScreenWidth(), core:getScreenHeight())
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 1 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    return o
end

function ZeD_LeftDesk:prerender()
    -- (the state cleared OnPreUIDraw: the pointer's sampling runs here, every frame)
    if ZeD.MouseTick and ZeD.MouseTick.sample then ZeD.MouseTick.sample() end
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    if self.width ~= sw or self.height ~= sh then self:setWidth(sw); self:setHeight(sh) end
    self:drawRect(0, 0, sw, sh, 1, 0, 0, 0)
    local ok, err = pcall(function()
        local L = MM.roomLayout()
        local t = getTimestampMs()
        MM.drawDesk(self, L, t)
        MM.drawWallpaper(self, L, t)
        local step, line = math.max(2, px(3)), math.max(1, px(1))
        for y = L.ty, L.ty + L.th - 1, step do self:drawRect(L.tx, y, L.tw, line, 0.11, 0, 0, 0) end
    end)
    if not ok and ZeD.logOnce then ZeD.logOnce("left screen desk", err) end
end

function ZeD_LeftDesk:onMouseDown() return true end
function ZeD_LeftDesk:onJoypadDown(button)
    local w = LS.win
    if not w then return end
    if button == Joypad.AButton then w:joyA() elseif button == Joypad.BButton then w:joyB() end
end
function ZeD_LeftDesk:onJoypadDirUp() if LS.win then LS.win:joyDir("up") end end
function ZeD_LeftDesk:onJoypadDirDown() if LS.win then LS.win:joyDir("down") end end
function ZeD_LeftDesk:onJoypadDirLeft() if LS.win then LS.win:joyDir("left") end end
function ZeD_LeftDesk:onJoypadDirRight() if LS.win then LS.win:joyDir("right") end end
function ZeD_LeftDesk:onGainJoypadFocus(jd) LS.pad = jd end
function ZeD_LeftDesk:onLoseJoypadFocus() LS.pad = nil end

-- ---------------------------------------------------------------------------
-- THE GAME'S TWO WAYS ON (its screen's own: removeFromUIManager, then the call)
-- ---------------------------------------------------------------------------
function LS.exit()
    local g = LS.game
    if g and g.onToMainMenu then return g:onToMainMenu() end
    getCore():exitToMenu()
end
function LS.quit()
    local g = LS.game
    if g and g.onToDesktop then return g:onToDesktop() end
    getCore():quitToDesktop()
end
-- B: to the band's Quit, as the game's screen gives B to Quit (focus only: a press is still A)
function LS.quitAsk()
    local w = LS.win
    if w and w.focusId ~= "quit" then w.focusId = "quit"; MM.hoverSound() end
end

--- Shows the screen over the game's. info = { reason, kind = "ban" | "kick" | nil, appeal }. False if it could not
--- (safe mode, or a failure: then the game's own screen stays).
function LS.show(info)
    if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on() then return false end
    if not (ZeD.T and MM and MM.roomLayout and ZeD_MMWindow) then return false end
    local ok, err = pcall(function()
        local desk = ZeD_LeftDesk:new()
        desk:initialise()
        desk:instantiate()
        local win = ZeD_MMLeft:new(info)
        win:initialise()
        desk:addChild(win)
        desk:addToUIManager()
        desk:setAlwaysOnTop(true)
        LS.desk, LS.win = desk, win
        -- the game's own screen stays for its two calls, out of sight
        LS.game = ISServerDisconnectUI and ISServerDisconnectUI.instance or nil
        if LS.game then LS.game:setVisible(false) end
        local jd = JoypadState and JoypadState.players and JoypadState.players[1]
        if jd then
            LS.pad = jd
            setJoypadFocus(0, desk)
        end
    end)
    if ok then return true end
    if ZeD.logOnce then ZeD.logOnce("left screen", err) end
    LS.giveBack()
    return false
end

-- nothing of ours over the game's screen: it comes back with the controller
function LS.giveBack()
    local desk = LS.desk
    LS.desk, LS.win = nil, nil
    if desk then pcall(function() desk:setVisible(false); desk:removeFromUIManager() end) end
    local g = LS.game
    if g then
        pcall(function() g:setVisible(true) end)
        local jd = JoypadState and JoypadState.players and JoypadState.players[1]
        if jd then pcall(setJoypadFocus, 0, g) end
    end
end

return LS
