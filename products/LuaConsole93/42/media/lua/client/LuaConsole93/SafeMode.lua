-- LuaConsole93/42/media/lua/client/LuaConsole93/SafeMode.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the parts of ZeD-GUI's SafeMode.lua the console uses (5 of its
-- 47 statements).
-- Made from ZeD-GUI's 42/media/lua/client/ZeD/SafeMode.lua by ZeDUI/tools/products/build_luaconsole93.py. Do
-- not edit it here: change ZeD-GUI's file and build again.
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

require "LuaConsole93/Tokens"
require "LuaConsole93/Tr"

LC93 = LC93 or {}
LC93.Safe = LC93.Safe or {}
local S = LC93.Safe
local traced, nTraced = {}, 0

function S.guard(panel, fn, label)
    local n0 = panel._lc93StencilN or 0
    local ok, err, trace = pcall(fn, panel)
    if ok then return true end
    local n = panel._lc93StencilN or 0
    while n > n0 do
        pcall(panel.clearStencilRect, panel)
        local m = panel._lc93StencilN or 0
        if m >= n then break end
        n = m
    end
    label = label or panel._lc93Label or panel.Type or "panel"
    LC93.logOnce(label, err)
    if trace and trace ~= "" and not traced[label] and nTraced < 100 then
        traced[label] = true
        nTraced = nTraced + 1
        print("[Lua Console 93] " .. tostring(label) .. " (Lua stack): " .. tostring(trace))
    end
    return false
end
