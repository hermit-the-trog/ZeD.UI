-- LuaConsole93/42/media/lua/client/LuaConsole93/Scale.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the parts of ZeD-GUI's Scale.lua the console uses (38 of its 118
-- statements).
-- Made from ZeD-GUI's 42/media/lua/shared/ZeD/Scale.lua by ZeDUI/tools/products/build_luaconsole93.py. Do not
-- edit it here: change ZeD-GUI's file and build again.
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

LC93 = LC93 or {}
LC93.Scale = LC93.Scale or {}
local S = LC93.Scale

S.BASE_H   = 1080
S.MIN      = 0.75
S.MAX      = 4.0
S.override = S.override or nil
S.userScale = S.userScale or nil

S.USER_MUL = { [1] = 0.85, [2] = 1.0, [3] = 1.0, [4] = 1.15, [5] = 1.3, [6] = 1.0 }

S._root = nil
S._tick = 0

function S.userMul()
    local ok, opt = pcall(function() return getCore():getOptionFontSize() end)
    if ok and opt ~= nil and S.USER_MUL[opt] then return S.USER_MUL[opt] end
    return 1.0
end

S.FIT_W_UNITS = 36 + 180 + 480 + 36
S.FIT_TABS    = 6
S.FIT_TAB_U   = 36
S.FIT_HELP_U  = 22
S.FIT_STEPS   = { 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0 }

function S.screenSize()
    local w, h = 1920, S.BASE_H
    pcall(function() w = getCore():getScreenWidth(); h = getCore():getScreenHeight() end)
    if type(w) ~= "number" or w <= 0 then w = 1920 end
    if type(h) ~= "number" or h <= 0 then h = S.BASE_H end
    return w, h
end

function S.autoScale(h)
    local r = (h or S.BASE_H) / S.BASE_H
    if r < S.MIN then r = S.MIN elseif r > S.MAX then r = S.MAX end
    return r * S.userMul()
end

local function textSizeFit()
    local TS = LC93.TextSizes
    local sz = TS and TS[LC93.currentSize or "small"]
    return (sz and sz.scale) or 1, (sz and sz.titleBarH) or 26
end

function S.stepFits(v, w, h)
    if not (w and h) then w, h = S.screenSize() end
    local k, titleU = textSizeFit()
    local sc = v * k
    if S.FIT_W_UNITS * sc > math.floor(w * 0.5) then return false end
    return titleU * v + (S.FIT_TABS * S.FIT_TAB_U + S.FIT_HELP_U) * sc <= h
end

function S.fitCap(w, h)
    if not (w and h) then w, h = S.screenSize() end
    local auto = S.autoScale(h)
    local cap = nil
    for _, v in ipairs(S.FIT_STEPS) do
        if cap == nil then cap = v end
        if v > cap and (v <= auto + 1e-6 or S.stepFits(v, w, h)) then cap = v end
    end
    return cap or S.MAX
end

S.STEP_FLOOR = 0.75

function S.computeGame()
    if S.override then return S.override end
    if S.userScale then
        local cap = S.fitCap()
        if S.userScale > cap then return cap end
        if S.userScale < S.STEP_FLOOR then return S.STEP_FLOOR end
        return S.userScale
    end
    local h = S.BASE_H
    pcall(function() h = getCore():getScreenHeight() end)
    if type(h) ~= "number" or h <= 0 then h = S.BASE_H end
    local r = h / S.BASE_H
    if r < S.MIN then r = S.MIN elseif r > S.MAX then r = S.MAX end
    return r * S.userMul()
end

S.menuUp = S.menuUp or nil
S.MENU_TUBE_W, S.MENU_TUBE_H = 240, 180
function S.menuMax(w, h)
    if not (w and h) then w, h = S.screenSize() end
    local sMax = math.max(1, math.floor(math.min(w / S.MENU_TUBE_W, h / S.MENU_TUBE_H)))
    return sMax / 4
end
function S.compute()
    local r = S.computeGame()
    if S.override then return r end
    if S.menuUp and S.menuUp() then
        local mx = S.menuMax()
        if r < 1 then r = 1 end
        if r > mx then r = mx end
    end
    return r
end

function S.root()
    if S._root == nil then S._root = S.compute() end
    return S._root
end

function S.artZoom(s)
    local k = math.floor((s or S.root()) + 0.5 + 1e-6)
    if k < 1 then k = 1 end
    return k
end

if Events then
    if Events.OnTick then
        Events.OnTick.Add(function()
            S._tick = S._tick + 1
            if S._tick >= 30 then S._tick = 0; S._root = S.compute() end
        end)
    end
    if Events.OnResolutionChange then
        Events.OnResolutionChange.Add(function() S._root = nil end)
    end
end

S._appliedRoot = S._appliedRoot or nil
S._reopenAt = nil
S._reopenChar, S._reopenWorld = false, false
local function reopenWindowsIfOpen()
    local CW, WW = LC93_CharacterWindow, LC93_WorldWindow
    local charOpen  = (CW and CW.isOpen and CW.isOpen()) and true or false
    local worldOpen = (WW and WW.isOpen and WW.isOpen()) and true or false
    if not charOpen and not worldOpen then return end
    if charOpen and CW.toggle then pcall(CW.toggle, 0) end
    if worldOpen and WW.close then pcall(WW.close) end
    S._reopenChar, S._reopenWorld = charOpen, worldOpen
    S._reopenAt = 3
end
local function reopenWindowsClosed()
    local p = getSpecificPlayer and getSpecificPlayer(0)
    if not p or p:isDead() then return end
    local CW, WW = LC93_CharacterWindow, LC93_WorldWindow
    if S._reopenChar and CW and CW.toggle and CW.isOpen and not CW.isOpen() then pcall(CW.toggle, 0) end
    if S._reopenWorld and WW and WW.open then pcall(WW.open, 0) end
    S._reopenChar, S._reopenWorld = false, false
end
local function rootChanged()
    if S._appliedRoot ~= nil and S._root ~= nil and math.abs(S._appliedRoot - S._root) > 0.001 and LC93.applyTheme and not S._reapplying then
        S._reapplying = true
        pcall(reopenWindowsIfOpen)
        pcall(LC93.applyTheme)
        S._reapplying = false
    end
end
if Events and Events.OnTick then
    Events.OnTick.Add(function()
        if S._tick == 0 then rootChanged() end
        if S._reopenAt then
            S._reopenAt = S._reopenAt - 1
            if S._reopenAt <= 0 then S._reopenAt = nil; pcall(reopenWindowsClosed) end
        end
    end)
end
