-- LuaConsole93/42/media/lua/client/LuaConsole93/LC93_Standalone.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the game's own pad keyboard and chat where ZeD-GUI has its own,
-- and the window's borders one design unit thick (ZeD-GUI's TextScale.lua does that for all its classes).
-- Written by ZeDUI/tools/products/build_luaconsole93.py. Do not edit it here: change the tool and build
-- again.
-- ============================================================================================================

-- With ZeD-GUI on (mod ZeD_UI; the game can put a backslash before a mod's id), ZeD-GUI's console is the one:
-- this file stops here and defines nothing.
do
    local guiOn = false
    pcall(function()
        local mods = getActivatedMods()
        for i = 0, mods:size() - 1 do
            if string.gsub(tostring(mods:get(i)), "^\\", "") == "ZeD_UI" then guiOn = true end
        end
    end)
    if guiOn then return end
end

require "LuaConsole93/Organisms"
require "LuaConsole93/LC93_DebugConsole"

LC93 = LC93 or {}

-- THE PAD KEYBOARD: the game's own on-screen keyboard (OnScreenKeyboard). The console shows it with
-- OnScreenKeyboard.Show, asks here whether it is still up, and on closing puts it away when it types into one of the
-- console's boxes (instance.textEntryBox).
LC93.Keyboard = LC93.Keyboard or {}
local KB = LC93.Keyboard

--- True while the game's on-screen keyboard is up.
function KB.isVisible()
    return OnScreenKeyboard ~= nil and OnScreenKeyboard.IsVisible ~= nil and OnScreenKeyboard.IsVisible() == true
end

-- KB.instance: the game's keyboard while it is up, nil once it is put away. The game's keeps its textEntryBox after
-- it hides, and its hide() gives that box the keys again; the console closing would then leave its own hidden line
-- holding every key. So the console sees only a keyboard that is up, and putting it away leaves the box unfocused,
-- as ZeD-GUI's keyboard does.
local proxy = {}
function proxy.hide()
    local inst = OnScreenKeyboard and OnScreenKeyboard.instance
    if not inst then return end
    local box = inst.textEntryBox
    pcall(function() inst:hide() end)
    if box and box.unfocus then pcall(function() box:unfocus() end) end
end
setmetatable(KB, { __index = function(_, k)
    if k == "instance" and KB.isVisible() then
        proxy.textEntryBox = OnScreenKeyboard.instance and OnScreenKeyboard.instance.textEntryBox
        return proxy
    end
    return nil
end })

-- The game's keyboard's Accept (and RT) put the words in the box, hide, give the box the keys, then press Enter for
-- it (ISOnScreenKeyboard:KeyFunction_Enter queues KEY_RETURN). ZeD-GUI's keyboard only puts the words in: the console
-- then lands the controller on Run or Send, and A runs it. So the Enter that follows an Accept into one of the
-- console's boxes is let go here (within ACCEPT_MS of the Accept), and the box lets the keys go with it.
local ACCEPT_MS = 500
local function acceptRecorded(o)
    KB._acceptAt, KB._acceptBox = getTimestampMs(), o and o.textEntryBox
end
local function wrapAccept(osk)
    if type(osk) ~= "table" or osk._lc93Accept then return end
    local orig = osk.accept
    if type(orig) ~= "function" then return end
    osk._lc93Accept = orig
    osk.accept = function(o, ...)
        if o and o.textEntryBox and o.textEntryBox._lc93Enter then acceptRecorded(o) end
        return orig(o, ...)
    end
end
--- True (once) when an Enter into box is the one the game's keyboard pressed after its Accept.
function KB.acceptEnter(box)
    if KB._acceptBox ~= box or not KB._acceptAt then return false end
    local now = getTimestampMs()
    KB._acceptBox = nil
    return now - KB._acceptAt <= ACCEPT_MS
end
local function wrapEnter(box)
    if type(box) ~= "table" or box._lc93Enter then return end
    box._lc93Enter = true
    local orig = box.onCommandEntered
    box.onCommandEntered = function(...)
        if KB.acceptEnter(box) then
            pcall(function() box:unfocus() end)
            return
        end
        if type(orig) == "function" then return orig(...) end
    end
end
local W = LC93_DebugConsoleWindow
if W and W.openKeyboard and not W._lc93KbWrapped then
    W._lc93KbWrapped = true
    local origOpen = W.openKeyboard
    function W:openKeyboard(jd, entry)
        entry = entry or self.input
        wrapEnter(entry)
        local r = origOpen(self, jd, entry)
        if self._kbOpen then wrapAccept(OnScreenKeyboard and OnScreenKeyboard.instance) end
        return r
    end
end

-- THE CHAT: a chat channel's line (/all, /say, /yell, /whisper, /faction, /safehouse, /admin) from the Commands page
-- goes through the game's own chat box (ISChat), which knows each channel's tab, its slow mode and its rules. The
-- game's chat drops a line without a word back in two cases: slow mode, and a channel of another tab than the one
-- the chat shows (it says so in the chat). Those are told here before the chat is asked, so the page never says Sent
-- for a line that went nowhere.
LC93.Chat = LC93.Chat or {}

local function streamOf(text)
    for _, s in ipairs(ISChat.allChatStreams or {}) do
        if (s.command and string.sub(text, 1, #s.command) == s.command)
            or (s.shortCommand and string.sub(text, 1, #s.shortCommand) == s.shortCommand) then return s end
    end
    return nil
end
local function ignoresSlowMode()
    local ok, yes = pcall(function() return getPlayer():getRole():hasCapability(Capability.IgnoreChatSlowMode) end)
    return ok and yes == true
end

--- Send a chat channel's line as the game's chat does. True when the chat sent it; false and why ("slow", "tab")
--- when it would not have.
function LC93.Chat.send(text)
    local chat = ISChat and ISChat.instance
    if not (chat and chat.textEntry and ISChat.onCommandEntered) then return false end
    text = tostring(text or "")
    if not ignoresSlowMode() and type(chat.timerMessageSlowMode) == "number" and chat.timerMessageSlowMode > getTimestampMs() then
        return false, "slow"
    end
    local stream = streamOf(text)
    if stream and stream.tabID and chat.currentTabID and stream.tabID ~= chat.currentTabID then return false, "tab" end
    local ok = pcall(function()
        chat.textEntry:setText(text)
        ISChat.onCommandEntered(chat)
    end)
    pcall(function() chat.textEntry:setText("") end)
    return ok
end

-- THE BORDERS: the game draws a border one screen pixel thick at any scale. The console's window and its overlay
-- draw theirs one design unit thick (T.px(1): two pixels at 4K), as four rects, so a border scales like everything
-- else; only these two classes, the game's own elements keep the game's call.
local function scaledBorder(self, x, y, w, h, a, r, g, b)
    local T = LC93.T
    local t = (T and T.px) and T.px(1) or 1
    if t <= 1 then return ISUIElement.drawRectBorder(self, x, y, w, h, a, r, g, b) end
    if w <= 0 or h <= 0 then return end
    if w <= 2 * t or h <= 2 * t then return self:drawRect(x, y, w, h, a, r, g, b) end
    self:drawRect(x, y, w, t, a, r, g, b)
    self:drawRect(x, y + h - t, w, t, a, r, g, b)
    self:drawRect(x, y + t, t, h - 2 * t, a, r, g, b)
    self:drawRect(x + w - t, y + t, t, h - 2 * t, a, r, g, b)
end
LC93.scaledBorder = scaledBorder
if LC93_Window then LC93_Window.drawRectBorder = scaledBorder end
if LC93_WindowOverlay then LC93_WindowOverlay.drawRectBorder = scaledBorder end
