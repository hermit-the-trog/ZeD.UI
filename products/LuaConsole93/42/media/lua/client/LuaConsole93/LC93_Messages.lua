-- LuaConsole93/42/media/lua/client/LuaConsole93/LC93_Messages.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the parts of ZeD-GUI's ZeD_Messages.lua the console uses (8 of
-- its 90 statements).
-- Made from ZeD-GUI's 42/media/lua/client/ZeD/ZeD_Messages.lua by ZeDUI/tools/products/build_luaconsole93.py.
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

require "LuaConsole93/Tr"
LC93 = LC93 or {}
LC93.Messages = LC93.Messages or {}
local M = LC93.Messages
local function safe(fn, ...) local ok, r = pcall(fn, ...); if ok then return r end return nil end

M.SCRUB_NOTE = "Your user name is taken out of this report. Files like console.txt still have it: look them over before you post them."

local function swapAll(s, what, with)
    if not what or what == "" then return s end
    local hay, needle = string.lower(s), string.lower(what)
    if #hay ~= #s or #needle ~= #what then hay, needle = s, what end
    local out, i = {}, 1
    while true do
        local a, b = string.find(hay, needle, i, true)
        if not a then break end
        out[#out + 1] = string.sub(s, i, a - 1)
        out[#out + 1] = with
        i = b + 1
    end
    if i == 1 then return s end
    out[#out + 1] = string.sub(s, i)
    return table.concat(out)
end

local USER_DIR = "%a:[/\\][Uu][Ss][Ee][Rr][Ss][/\\][^/\\:\r\n\"']+([/\\])"

function M.scrub(text)
    local s = tostring(text or "")
    local doc = safe(function() return tostring(getMyDocumentFolder() or "") end) or ""
    if doc ~= "" then
        local fwd = string.gsub(doc, "\\", "/")
        local back = string.gsub(doc, "/", "\\")
        s = swapAll(s, back, "~/Zomboid")
        s = swapAll(s, fwd, "~/Zomboid")
    end
    s = string.gsub(s, USER_DIR, function(sep) return "~" .. sep end)
    local home = string.match(doc, "^%a:[/\\][Uu][Ss][Ee][Rr][Ss][/\\][^/\\]+")
    if home then
        s = swapAll(s, (string.gsub(home, "/", "\\")), "~")
        s = swapAll(s, (string.gsub(home, "\\", "/")), "~")
    end
    if string.sub(s, -1) ~= "\n" then s = s .. "\n" end
    return s .. M.SCRUB_NOTE
end
