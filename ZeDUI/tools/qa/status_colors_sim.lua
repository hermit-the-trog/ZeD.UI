-- ZeDUI/tools/qa/status_colors_sim.lua  (Nov 10 2026, Build; punch list 144, the Status colors option)
-- The director, Nov 10 2026: "Add as an option", after the swatch page (ZeDUI/qa/status_colors_swatches.html). With no
-- game running, the real Tokens.lua and Settings.lua run on Lua 5.1 against a stub of the game's ModOptions (the
-- stubs are default_accent_sim.lua's). It checks:
--   COMBO     Status colors is registered with two items, Standard the default, under ZeD Look in ZeD setup
--   STANDARD  a fresh install draws each theme's own green, yellow and red, and the text shades are as before
--   CB        Color blind (the combo's onChange, as the options screen and ZeD setup fire it) puts the set's blue,
--             yellow and orange in T for Dark, Light and High contrast; back to Standard puts the theme's own back
--   TEXT      the status text shades in both sets read at least 4.5 : 1 on surfaces 1 and 2 (drawn solid)
--   APART     in the color blind set, good, warning and bad differ by at least 20 (CIELAB) under deuteranopia,
--             protanopia and tritanopia (the swatch page's numbers)
-- Run from the repo root:  lua51 ZeDUI/tools/qa/status_colors_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]status_colors_sim%.lua$", "")
local CDIR = ROOT .. "42/media/lua/client/ZeD/"
local SDIR = ROOT .. "42/media/lua/shared/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- ---------------------------------------------------------------------------
-- THE STUBS
-- ---------------------------------------------------------------------------
local dummy
dummy = setmetatable({}, {
    __index = function(_, k) if type(k) == "number" then return nil end return dummy end,
    __call = function() return dummy end,
    __concat = function(a, b) return tostring(a == dummy and "" or a) .. tostring(b == dummy and "" or b) end,
})
require = function() end
getText = function(k) return k end
getTextOrNull = function(k) return k end
getFileReader = function() return nil end   -- (no ModOptions.ini: a first run)

local opts = { dict = {}, order = {} }
local function newOption(id, kind)
    -- (element false: the options screen is closed, so a pick is read from the option's own value)
    local o = { id = id, kind = kind, items = {}, default = nil, value = nil, element = false }
    function o:addItem(text, selected)
        self.items[#self.items + 1] = text
        if selected then self.default = #self.items; self.value = #self.items end
    end
    function o:getValue() return self.value end
    function o:setValue(v) self.value = v end
    function o:setEnabled() end
    return setmetatable(o, { __index = function() return function() return dummy end end })
end
setmetatable(opts, { __index = function(_, name)
    return function(self, id, ...)
        local o = newOption(id, name)
        if type(id) == "string" then self.dict[id] = o; self.order[#self.order + 1] = id end
        return o
    end
end })
PZAPI = { ModOptions = { create = function() return opts end, save = function() end } }
-- what Tokens.lua reads from files that load before it: a 1080p root scale and ZeD's own fonts in their slots
ZeD = {
    Scale = { root = function() return 1 end },
    Text  = { checkRoleFonts = function() return false end, noFonts = true },   -- (no fonts, as on a server)
    Font  = { sdf = { sec = { font = 1 }, body = { font = 2 }, stat = { font = 3 }, head = { font = 4 }, title = { font = 5 } } },
}
setmetatable(_G, { __index = function() return dummy end })

local function load(dir, name)
    local f, err = loadfile(dir .. name)
    if not f then print("status_colors_sim: " .. tostring(err)); os.exit(1) end
    local ok, e = pcall(f)
    if not ok then print("status_colors_sim: " .. name .. ": " .. tostring(e)); os.exit(1) end
end

load(SDIR, "Tokens.lua")
ZeD.tr = ZeD.tr or function(k) return k end
load(CDIR, "Settings.lua")
setmetatable(_G, nil)

local function hexOf(c) return string.format("#%02X%02X%02X", math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5)) end
local function same(a, b) return a and b and math.abs(a.r - b.r) < 1e-6 and math.abs(a.g - b.g) < 1e-6 and math.abs(a.b - b.b) < 1e-6 end

-- COMBO
local combo = opts.dict.statusColors
check("COMBO: Status colors is registered", combo ~= nil)
if not combo then print("status_colors_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end
check("COMBO: two items, Standard then Color blind", #combo.items == 2 and combo.items[1] == "UI_ZeD_Settings_StatusStandard"
      and combo.items[2] == "UI_ZeD_Settings_StatusColorBlind", table.concat(combo.items, ","))
check("COMBO: Standard is the default", combo.default == 1, combo.default)
check("COMBO: its name key is set for ZeD setup", combo.zedNameKey == "UI_ZeD_Settings_StatusColors", combo.zedNameKey)
do
    local f = io.open(CDIR .. "ZeD_MainMenuOptionGroups.lua", "rb"); local g = f:read("*a"); f:close()
    check("COMBO: ZeD setup's Look group has it as radio buttons", g:find('{ "statusColors", "radio" }', 1, true) ~= nil)
end
check("COMBO: a fresh install is on Standard", ZeD.currentStatus == "standard", ZeD.currentStatus)

-- the base themes as the options apply them
local base, accent = opts.dict.baseTheme, opts.dict.accentColor
local KEYS = ZeD.Settings.baseKeys or { "dark", "light", "hicon" }
local function themeIdx(k) for i, b in ipairs(KEYS) do if b == k then return i end end end
local function apply(themeKey, statusIdx)
    base:setValue(themeIdx(themeKey))
    combo.onChange(combo, statusIdx)
end

-- color math (the swatch page's)
local function lin(v) return v <= 0.04045 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
local function lum(c) return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b) end
local function cr(a, b) local x, y = lum(a), lum(b); if x < y then x, y = y, x end; return (x + 0.05) / (y + 0.05) end
local MX = {
    deutan = { { 0.367322, 0.860646, -0.227968 }, { 0.280085, 0.672501, 0.047413 }, { -0.011820, 0.042940, 0.968881 } },
    protan = { { 0.152286, 1.052583, -0.204868 }, { 0.114503, 0.786281, 0.099216 }, { -0.003882, -0.048116, 1.051998 } },
    tritan = { { 1.255528, -0.076749, -0.178779 }, { -0.078411, 0.930809, 0.147602 }, { 0.004733, 0.691367, 0.303900 } },
}
local function gam(v) v = math.max(0, math.min(1, v)); return v <= 0.0031308 and 12.92 * v or 1.055 * v ^ (1 / 2.4) - 0.055 end
local function sim(c, k)
    local l = { lin(c.r), lin(c.g), lin(c.b) }; local m = MX[k]
    local o = {}
    for i = 1, 3 do o[i] = gam(m[i][1] * l[1] + m[i][2] * l[2] + m[i][3] * l[3]) end
    return { r = o[1], g = o[2], b = o[3] }
end
local function lab(c)
    local r, g, b = lin(c.r), lin(c.g), lin(c.b)
    local X = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
    local Y = 0.2126 * r + 0.7152 * g + 0.0722 * b
    local Z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
    local function f(t) return t > 0.008856 and t ^ (1 / 3) or 7.787 * t + 16 / 116 end
    return 116 * f(Y) - 16, 500 * (f(X) - f(Y)), 200 * (f(Y) - f(Z))
end
local function dE(a, b)
    local l1, a1, b1 = lab(a); local l2, a2, b2 = lab(b)
    return math.sqrt((l1 - l2) ^ 2 + (a1 - a2) ^ 2 + (b1 - b2) ^ 2)
end

for _, tk in ipairs({ "dark", "light", "hicon" }) do
    local B = ZeD.BaseThemes[tk]
    local CB = ZeD.StatusColors.cb[tk]
    -- STANDARD
    apply(tk, 1)
    local T = ZeD.T
    check("STANDARD " .. tk .. ": the theme's own green, yellow, red", same(T.positive, B.positive) and same(T.warning, B.warning) and same(T.danger, B.danger),
          hexOf(T.positive) .. " " .. hexOf(T.warning) .. " " .. hexOf(T.danger))
    local stdText = { T.positiveText, T.warningText, T.dangerText }
    for _, k in ipairs({ "positiveText", "warningText", "dangerText" }) do
        local s1, s2 = T.surf1, T.surf2
        check("TEXT standard " .. tk .. ": " .. k .. " reads 4.5 on surfaces 1 and 2", cr(T[k], s1) >= 4.5 and cr(T[k], s2) >= 4.5,
              string.format("%.2f / %.2f", cr(T[k], s1), cr(T[k], s2)))
    end
    -- CB
    apply(tk, 2)
    T = ZeD.T
    check("CB " .. tk .. ": Color blind is applied", ZeD.currentStatus == "cb", ZeD.currentStatus)
    check("CB " .. tk .. ": the set's blue, yellow, orange", same(T.positive, CB.positive) and same(T.warning, CB.warning) and same(T.danger, CB.danger),
          hexOf(T.positive) .. " " .. hexOf(T.warning) .. " " .. hexOf(T.danger))
    for _, k in ipairs({ "positiveText", "warningText", "dangerText" }) do
        check("TEXT cb " .. tk .. ": " .. k .. " reads 4.5 on surfaces 1 and 2", cr(T[k], T.surf1) >= 4.5 and cr(T[k], T.surf2) >= 4.5,
              string.format("%s %.2f / %.2f", hexOf(T[k]), cr(T[k], T.surf1), cr(T[k], T.surf2)))
    end
    check("CB " .. tk .. ": the text shades moved off the standard ones", not same(T.positiveText, stdText[1]), hexOf(T.positiveText))
    -- APART
    for _, v in ipairs({ "deutan", "protan", "tritan" }) do
        local g, y, r = sim(CB.positive, v), sim(CB.warning, v), sim(CB.danger, v)
        local m = math.min(dE(g, y), dE(g, r), dE(y, r))
        check(("APART cb %s %s: the three at least 20 apart"):format(tk, v), m >= 20, string.format("%.1f", m))
    end
    -- back to Standard
    apply(tk, 1)
    check("STANDARD " .. tk .. ": back to the theme's own", same(ZeD.T.positive, B.positive) and same(ZeD.T.danger, B.danger), hexOf(ZeD.T.positive))
    check("STANDARD " .. tk .. ": its text shades as before", same(ZeD.T.positiveText, stdText[1]) and same(ZeD.T.dangerText, stdText[3]), hexOf(ZeD.T.positiveText))
end
-- a stored value past the list (a save from a build with more items): Standard
combo:setValue(99); combo.onChange(combo, nil)
check("a stored value past the list is Standard", ZeD.currentStatus == "standard", ZeD.currentStatus)

print("status_colors_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
