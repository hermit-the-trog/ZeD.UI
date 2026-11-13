-- LuaConsole93/42/media/lua/client/LuaConsole93/LC93_Text.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the text: the game's own fonts for every role, and its text
-- manager with the measures kept. It stands in for ZeD-GUI's Scale.lua text layer, which draws in Fira by
-- replacing the game's font list. The palette (Tokens.lua) loads it first: it measures the font heights as it
-- is made.
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

LC93 = LC93 or {}
LC93.Text = LC93.Text or {}
local X = LC93.Text

-- the game's face for each role: F1 chrome, F2 body, F3 data (fixed pitch: the log's columns and the caret are counted
-- in its character width), F4 heading, F5 micro
X.ROLE_FONTS = { "Small", "Small", "CodeSmall", "Medium", "Small" }

-- The languages whose words the code face draws: the game's codeSmall.fnt holds the first 256 characters only, so a
-- language with letters past them (Cyrillic, CJK, Thai, Polish, Turkish, German quotes) gets the data role in its own
-- Small face, which the game picks by language. Worked out by the build from each language's words here.
X.CODE_LANGS = { AR = true, CA = true, DA = true, EN = true, ES = true, ES_CL = true, ES_MX = true, FI = true, FR = true, ID = true, IT = true, NL = true, NO = true, PT = true, PTBR = true, }

local function langName() return tostring(Translator.getLanguage():name()) end

--- True when the game's language is one the code face draws (or the language cannot be read).
function X.codeFaceFits()
    local ok, name = pcall(langName)
    if not ok or type(name) ~= "string" then return true end
    return X.CODE_LANGS[name] == true
end

--- True: the roles draw in the game's own fonts (the palette then asks roleFallbackFont for each one).
function X.checkRoleFonts() return true end

--- The game's font for role i (1 to 5). px, the role's design size, is not needed: the game's faces come in the
--- size its font size option picks.
function X.roleFallbackFont(px, i)
    local name = X.ROLE_FONTS[i or 2] or "Small"
    if name == "CodeSmall" and not X.codeFaceFits() then name = "Small" end
    return UIFont[name] or UIFont.Small
end

-- The kept measures: two generations of MAX strings. They start over whenever a width could differ: a new palette
-- (theme, scale), another root scale, another language, the game's font size option (it loads other faces).
local MAX = 3000
local M = { T = false, root = false, gen = false, fs = false, x = {}, xOld = {}, h = {}, n = 0, epoch = 0 }
local fsNow = false

local function settle()
    local root = (LC93.Scale and LC93.Scale._root) or false
    if M.T ~= LC93.T or M.root ~= root or M.gen ~= LC93._trGen or M.fs ~= fsNow then
        M.T, M.root, M.gen, M.fs = LC93.T, root, LC93._trGen, fsNow
        M.x, M.xOld, M.h, M.n = {}, {}, {}, 0
        M.epoch = M.epoch + 1
    end
end

--- A number that changes whenever the kept measures start over (the atoms keep their wraps and cuts by it).
function X.measureEpoch()
    settle()
    return M.epoch
end

--- measureEpoch, for kept words
function X.wordsEpoch() return X.measureEpoch() * 2 end

LC93.TM = LC93.TM or {}
local TM = LC93.TM

--- A string's width in screen px, kept.
function TM:MeasureStringX(font, str)
    if type(str) ~= "string" then str = tostring(str) end
    if font == nil then return getTextManager():MeasureStringX(font, str) end
    settle()
    local byF = M.x[font]
    if byF then
        local v = byF[str]
        if v then return v end
    else
        byF = {}
        M.x[font] = byF
    end
    local old = M.xOld[font]
    local v = old and old[str]
    if not v then v = getTextManager():MeasureStringX(font, str) end
    if M.n >= MAX then
        M.xOld, M.x, M.n = M.x, {}, 0
        byF = {}
        M.x[font] = byF
    end
    byF[str] = v
    M.n = M.n + 1
    return v
end

--- A string's height in screen px (not kept).
function TM:MeasureStringY(font, str) return getTextManager():MeasureStringY(font, tostring(str)) end

--- A font's line height in screen px, kept.
function TM:getFontHeight(font)
    if font == nil then return getTextManager():getFontHeight(font) end
    settle()
    local v = M.h[font]
    if not v then
        v = getTextManager():getFontHeight(font)
        M.h[font] = v
    end
    return v
end

-- any other method of the game's text manager passes through, wrapped once
setmetatable(TM, { __index = function(t, k)
    local v = getTextManager()[k]
    if type(v) ~= "function" then return v end
    local wrapper = function(_, ...) local real = getTextManager(); return real[k](real, ...) end
    rawset(t, k, wrapper)
    return wrapper
end })

-- the game's font size option, read once a frame while the console can open (debug mode); one function made at
-- load, never one a frame. A new screen size starts the measures over.
local function readFontSize() return getCore():getOptionFontSize() end
local function onPreUIDraw()
    local ok, v = pcall(readFontSize)
    fsNow = ok and v or false
end
X._onPreUIDraw = onPreUIDraw
if Events then
    if Events.OnPreUIDraw and isDebugEnabled and isDebugEnabled() then Events.OnPreUIDraw.Add(onPreUIDraw) end
    if Events.OnResolutionChange then Events.OnResolutionChange.Add(function() M.T = false end) end
end
