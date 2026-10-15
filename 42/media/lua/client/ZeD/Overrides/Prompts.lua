-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Prompts.lua
-- ============================================================================
-- VANILLA'S POP-UPS — HOOK_MAP row 28 (ZeD_Prompt.lua, ZeD_Keyboard.lua)
--
-- Vanilla builds every question, note and text box through a handful of
-- classes; their :new is the entry point. Called on the class itself
-- (ISModalDialog:new(...)), each now returns a ZeD prompt that keeps vanilla's
-- contract (same fields, same answers to the same callbacks). A subclass that
-- builds through the parent (SomeDialog = ISModalDialog:derive, then
-- ISModalDialog.new(self, ...)) still gets vanilla's, untouched, and so does
-- everything when the ZeD prompt cannot be built.
--
--   ISModalDialog:new       question (Yes / No) or note (OK)
--   ISModalRichText:new     formatted text: a long note, or a question
--   ISTextBox:new           a field with OK / Cancel
--   ISAlarmClockDialog:new  Set Alarm (an alarm clock or watch in your bags)
--   ISBombTimerDialog:new   Set Timer (a pipe bomb or timed trap)
--   OnScreenKeyboard.Show   the controller keyboard
--
-- Escape answers No / Cancel (OK on a note) and Enter the main answer of the
-- prompt on top, before Escape can open the pause menu (vanilla's
-- ToggleEscapeMenu is re-registered behind this check).
-- ============================================================================

require "ISUI/ISModalDialog"
require "ISUI/ISModalRichText"
require "ISUI/ISTextBox"
require "ISUI/ISAlarmClockDialog"
require "ISUI/ISBombTimerDialog"
require "ISUI/ISOnScreenKeyboard"
require "ZeD/ZeD_Prompt"
require "ZeD/ZeD_Keyboard"

local function ready()
    return ZeD and ZeD.T and ZeD.T.px and ZeD.Prompt and ZeD_Prompt ~= nil
end

-- cls:new(...) -> the ZeD prompt when called on the class itself
local function hookNew(cls, name, build)
    if type(cls) ~= "table" or cls._zedPromptHooked then return end
    cls._zedPromptHooked = true
    local orig = cls.new
    cls._zedOrigNew = orig
    cls.new = function(self, ...)
        if self == cls and ready() then
            local ok, o = pcall(build, ...)
            if ok and o then return o end
            if not ok then print("[ZeD] Prompts: " .. name .. " kept vanilla's: " .. tostring(o)) end
        end
        return orig(self, ...)
    end
end

local function hookKeyboard()
    if not OnScreenKeyboard or OnScreenKeyboard._zedHooked then return end
    OnScreenKeyboard._zedHooked = true
    local origShow = OnScreenKeyboard.Show
    -- IsVisible / Hide / GetCurrentText are vanilla's: they ask OnScreenKeyboard.instance,
    -- which is the ZeD keyboard once it has been shown
    OnScreenKeyboard.Show = function(playerNum, textEntryBox, joypadData)
        if OnScreenKeyboard.IsVisible() then return OnScreenKeyboard.instance end
        if ready() and ZeD.Keyboard and ZeD.Keyboard.get then
            local ok, k = pcall(function()
                local kb = ZeD.Keyboard.get()
                OnScreenKeyboard.instance = kb
                return kb:show(playerNum, textEntryBox, joypadData)
            end)
            if ok and k then return k end
            print("[ZeD] Prompts: keyboard kept vanilla's: " .. tostring(k))
            OnScreenKeyboard.instance = nil
        end
        return origShow(playerNum, textEntryBox, joypadData)
    end
end

-- Escape / Enter for the prompt on top
local function isEscape(key)
    if key == Keyboard.KEY_ESCAPE then return true end
    local ok, r = pcall(function() return getCore():isKey(KeybindId.MAIN_MENU, key) end)
    return ok and r or false
end

local function onKey(key)
    local P = ZeD and ZeD.Prompt
    local top = P and P.top and P.top()
    local ms = MainScreen and MainScreen.instance
    -- in game with the pause menu up, the keys stay the menu's
    local pauseUp = ms and ms.inGame and ms:isVisible()
    if top and not pauseUp then
        if isEscape(key) then top:answerCancel(); return end
        if key == Keyboard.KEY_RETURN or key == Keyboard.KEY_NUMPADENTER then
            if not (top.entry and top.entry:isFocused()) then top:pressPrimary(); return end
        end
    end
    -- other ZeD surfaces that Escape puts away first (the seat chooser, the siren controller)
    if not pauseUp and isEscape(key) and ZeD.EscapeTakers then
        for _, take in pairs(ZeD.EscapeTakers) do if take() then return end end
    end
    if ToggleEscapeMenu then return ToggleEscapeMenu(key) end
end

local function hookKeys()
    if _G._zedPromptKeys then return end
    if not (ToggleEscapeMenu and Events and Events.OnKeyPressed and Events.OnKeyPressed.Remove) then return end
    _G._zedPromptKeys = true
    Events.OnKeyPressed.Remove(ToggleEscapeMenu)
    Events.OnKeyPressed.Add(onKey)
end

local function apply()
    if not ZeD_Prompt then return end
    local P = ZeD.Prompt
    hookNew(ISModalDialog, "question", P.question)
    hookNew(ISModalRichText, "rich text", P.rich)
    hookNew(ISTextBox, "text box", P.textBox)
    hookNew(ISAlarmClockDialog, "alarm", P.alarm)
    hookNew(ISBombTimerDialog, "timer", P.timer)
    hookKeyboard()
    hookKeys()
    if not _G._zedPromptsAnnounced then
        _G._zedPromptsAnnounced = true
        print("[ZeD] Overrides/Prompts: vanilla's pop-ups and keyboard open as ZeD prompts")
    end
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
