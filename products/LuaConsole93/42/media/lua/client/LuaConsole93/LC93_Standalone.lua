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

-- KB.instance: the game's keyboard, looked up when asked (the game makes it the first time it shows)
setmetatable(KB, { __index = function(_, k)
    if k == "instance" and OnScreenKeyboard then return OnScreenKeyboard.instance end
    return nil
end })

-- THE CHAT: a chat channel's line (/all, /say, /yell, /whisper, /faction, /safehouse, /admin) from the Commands page
-- goes through the game's own chat box (ISChat), which knows each channel's tab, its slow mode and its rules.
LC93.Chat = LC93.Chat or {}

--- Send a chat channel's line as the game's chat does. True when the chat took it.
function LC93.Chat.send(text)
    local chat = ISChat and ISChat.instance
    if not (chat and chat.textEntry and ISChat.onCommandEntered) then return false end
    local ok = pcall(function()
        chat.textEntry:setText(tostring(text or ""))
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
