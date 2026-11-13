-- LuaConsole93/42/media/lua/client/LuaConsole93/LC93_Prompt.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the parts of ZeD-GUI's ZeD_Prompt.lua the console uses (5 of its
-- 109 statements).
-- Made from ZeD-GUI's 42/media/lua/client/ZeD/ZeD_Prompt.lua by ZeDUI/tools/products/build_luaconsole93.py.
-- Do not edit it here: change ZeD-GUI's file and build again.
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

require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "LuaConsole93/Tokens"
require "LuaConsole93/Atoms"
require "LuaConsole93/Molecules"
require "LuaConsole93/Organisms"

LC93 = LC93 or {}
LC93.Prompt = LC93.Prompt or {}
local P = LC93.Prompt

local function padNote(s)
    local first, rest = tostring(s):match("^(%S+)%s+(.+)$")
    local PG = LC93.PadGlyphs
    if first and PG and PG.roles(LC93.upper(first)) then return { glyph = LC93.upper(first), label = rest } end
    return tostring(s)
end
P.padNote = padNote
