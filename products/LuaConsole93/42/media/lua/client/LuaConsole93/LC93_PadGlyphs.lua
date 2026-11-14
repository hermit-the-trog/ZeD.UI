-- LuaConsole93/42/media/lua/client/LuaConsole93/LC93_PadGlyphs.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the parts of ZeD-GUI's ZeD_PadGlyphs.lua the console uses (39 of
-- its 51 statements).
-- Made from ZeD-GUI's 42/media/lua/client/ZeD/ZeD_PadGlyphs.lua by
-- ZeDUI/tools/products/build_luaconsole93.py. Do not edit it here: change ZeD-GUI's file and build again.
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

require "LuaConsole93/PixelFonts"

LC93 = LC93 or {}
LC93.PadGlyphs = LC93.PadGlyphs or {}
local G = LC93.PadGlyphs

local F35, F57 = LC93.PixelFonts["35"], LC93.PixelFonts["57"]

local RING = { "....XXXXX....", "..XX.....XX..", ".X.........X.", ".X.........X.", "X...........X", "X...........X", "X...........X",
               "X...........X", "X...........X", ".X.........X.", ".X.........X.", "..XX.....XX..", "....XXXXX...." }
local BUMP = { "..XXXXXXXXXXXXXXX..", ".X...............X.", "X.................X", "X.................X", "X.................X", "X.................X",
               "X.................X", "X.................X", "X.................X", "X.................X", "XXXXXXXXXXXXXXXXXXX" }
local TRIG = { "...XXXXXXXXX...", ".XX.........XX.", "X.............X", "X.............X", "X.............X", "X.............X", "X.............X",
               "X.............X", "X.............X", "X.............X", "X.............X", "X.............X", "XXXXXXXXXXXXXXX" }
local DPAD = { "....XXXXX....", "....X...X....", "....X...X....", "....X...X....", "XXXXX...XXXXX", "X...........X", "X...........X",
               "X...........X", "XXXXX...XXXXX", "....X...X....", "....X...X....", "....X...X....", "....XXXXX...." }
local PILL = { ".XXXXXXX.", "X.......X", "X.......X", "X.......X", "X.......X", "X.......X", "X.......X", "X.......X", "X.......X", "X.......X", ".XXXXXXX." }
local SYM = {
    tri   = { "...X...", "..X.X..", "..X.X..", ".X...X.", ".X...X.", "XXXXXXX" },
    circ  = { "..XXX..", ".X...X.", "X.....X", "X.....X", "X.....X", ".X...X.", "..XXX.." },
    cross = { "XX...XX", ".XX.XX.", "..XXX..", "...X...", "..XXX..", ".XX.XX.", "XX...XX" },
    sq    = { "XXXXXXX", "X.....X", "X.....X", "X.....X", "X.....X", "X.....X", "XXXXXXX" },
}
local VIEW = { "XXXX..", "X..X..", "X.XXXX", "XXX..X", "..X..X", "..XXXX" }
local ARM = { DU = { 5, 1, 7, 4 }, DD = { 5, 8, 7, 11 }, DL = { 1, 5, 4, 7 }, DR = { 8, 5, 11, 7 } }

local function rgb(h) return { r = tonumber(h:sub(1, 2), 16) / 255, g = tonumber(h:sub(3, 4), 16) / 255, b = tonumber(h:sub(5, 6), 16) / 255, a = 1 } end
local PAD = {
    xbox = { A = { rgb("57B03A"), rgb("101010") }, B = { rgb("D7423A"), rgb("F4F2EC") }, X = { rgb("3C78D8"), rgb("F4F2EC") }, Y = { rgb("E4B320"), rgb("101010") } },
    ps   = { A = { "cross", rgb("7C9BF2") }, B = { "circ", rgb("F0505E") }, X = { "sq", rgb("EE8FD0") }, Y = { "tri", rgb("2FBF8F") } },
}
local DISC_PS, DISC_DECK, LETTER_DECK = rgb("1C1C1C"), rgb("262626"), rgb("ECECEC")
local RIM_DARK, RIM_LIGHT = rgb("6A6A6A"), rgb("101010")

local NAMES = {
    xbox = { A = "A", B = "B", X = "X", Y = "Y", LB = "LB", RB = "RB", LT = "LT", RT = "RT", LS = "LS", RS = "RS", L3 = "LS", R3 = "RS", SEL = "View", START = "Menu" },
    ps   = { A = "Cross", B = "Circle", X = "Square", Y = "Triangle", LB = "L1", RB = "R1", LT = "L2", RT = "R2", LS = "L3", RS = "R3", L3 = "L3", R3 = "R3", SEL = "Create", START = "Options" },
    deck = { A = "A", B = "B", X = "X", Y = "Y", LB = "L1", RB = "R1", LT = "L2", RT = "R2", LS = "L3", RS = "R3", L3 = "L3", R3 = "R3", SEL = "View", START = "Menu" },
    nin  = { A = "B", B = "A", X = "Y", Y = "X", LB = "L", RB = "R", LT = "ZL", RT = "ZR", LS = "L", RS = "R", L3 = "L", R3 = "R", SEL = "-", START = "+" },
}

local SETTING = { xbox = "xbox", ps = "ps", deck = "deck", nintendo = "nin" }
local STYLE = { PS4 = "ps", STEAMDECK = "deck" }
local NAMED = { xbox = "xbox", playstation = "ps", nintendo = "nin" }
local function padSetOf(pn)
    local P = JoypadState and JoypadState.players
    local jd = P and P[pn + 1]
    local id = jd and jd.id
    if type(id) ~= "number" then return nil end
    local ok, name = pcall(function() return getControllerName(id) end)
    if ok and name and string.find(string.lower(tostring(name)), "steam", 1, true) then return "deck" end
    local D = LC93.Input and LC93.Input.Detector
    local ok2, t = pcall(function() return D and D.getControllerType and D.getControllerType(id) end)
    return (ok2 and t and NAMED[t]) or nil
end

function G.set(pn)
    local key = (LC93.Settings and LC93.Settings.glyphKey and LC93.Settings.glyphKey()) or "auto"
    if key == "auto" then
        if type(pn) == "number" and pn > 0 then
            local own = padSetOf(pn)
            if own then return own end
        end
        local ok, s = pcall(function() return getCore():getOptionControllerButtonStyleString() end)
        return (ok and STYLE[tostring(s)]) or "xbox"
    end
    return SETTING[key]
end

function G.playerOf(panel)
    local o, hops = panel, 0
    while type(o) == "table" and hops < 8 do
        if type(o.playerNum) == "number" then return o.playerNum end
        if type(o.player) == "number" then return o.player end
        o = o.parent
        hops = hops + 1
    end
    return nil
end

local function newGrid(w, h) return { w = w, h = h, cell = {} } end
local function put(g, x, y, slot)
    if x < 0 or y < 0 or x >= g.w or y >= g.h then return end
    g.cell[y * g.w + x] = slot
end
local function stamp(g, rows, x0, y0, slot)
    for y = 1, #rows do
        local r = rows[y]
        for x = 1, #r do
            local ch = r:sub(x, x)
            if ch == "X" or ch == "1" then put(g, x0 + x - 1, y0 + y - 1, slot) end
        end
    end
end
local function fillInside(g, rows, slot)
    for y = 2, #rows - 1 do
        local r = rows[y]
        local a, b = nil, nil
        for x = 1, #r do if r:sub(x, x) == "X" then a = a or x; b = x end end
        if a then for x = a + 1, b - 1 do if r:sub(x, x) ~= "X" then put(g, x - 1, y - 1, slot) end end end
    end
end
local function text(g, font, str, x0, y0, slot)
    local x = x0
    for i = 1, #str do
        local rows = font[str:sub(i, i)]
        if rows then stamp(g, rows, x, y0, slot); x = x + #rows[1] + 1 end
    end
end
local function textW(font, str)
    local w = 0
    for i = 1, #str do local rows = font[str:sub(i, i)]; if rows then w = w + #rows[1] + 1 end end
    return math.max(0, w - 1)
end

local function build(role, set)
    local g
    if role == "A" or role == "B" or role == "X" or role == "Y" then
        g = newGrid(13, 13)
        if set == "xbox" then
            local c = PAD.xbox[role]
            fillInside(g, RING, c[1]); stamp(g, RING, 0, 0, c[1]); text(g, F57, role, 4, 3, c[2])
        elseif set == "ps" then
            local c = PAD.ps[role]
            fillInside(g, RING, DISC_PS); stamp(g, RING, 0, 0, "rim"); stamp(g, SYM[c[1]], 3, 3, c[2])
        else
            fillInside(g, RING, DISC_DECK); stamp(g, RING, 0, 0, "rim")
            text(g, F57, set == "nin" and NAMES.nin[role] or role, 4, 3, LETTER_DECK)
        end
    elseif role == "LB" or role == "RB" then
        g = newGrid(19, 11)
        fillInside(g, BUMP, "paper"); stamp(g, BUMP, 0, 0, "ink")
        local s = (set == "xbox") and role or (set == "nin") and role:sub(1, 1) or (role:sub(1, 1) .. "1")
        text(g, F35, s, math.floor((19 - textW(F35, s)) / 2), 3, "ink")
    elseif role == "LT" or role == "RT" then
        g = newGrid(15, 13)
        fillInside(g, TRIG, "paper"); stamp(g, TRIG, 0, 0, "ink")
        local s = (set == "xbox") and role or (set == "nin") and ("Z" .. role:sub(1, 1)) or (role:sub(1, 1) .. "2")
        text(g, F35, s, math.floor((15 - textW(F35, s)) / 2), 5, "ink")
    elseif role == "LS" or role == "RS" then
        g = newGrid(13, 13)
        stamp(g, RING, 0, 0, "ink"); text(g, F57, role:sub(1, 1), 4, 3, "ink")
        put(g, 6, 1, "ink"); put(g, 6, 11, "ink"); put(g, 1, 6, "ink"); put(g, 11, 6, "ink")
    elseif role == "L3" or role == "R3" then
        g = newGrid(13, 13)
        fillInside(g, RING, "ink"); stamp(g, RING, 0, 0, "ink")
        if set == "xbox" or set == "nin" then text(g, F57, role:sub(1, 1), 4, 3, "knock") else text(g, F35, role, 3, 4, "knock") end
    elseif role:sub(1, 1) == "D" then
        g = newGrid(13, 13)
        fillInside(g, DPAD, "paper"); stamp(g, DPAD, 0, 0, "ink")
        local arms = (role == "DLR") and { "DL", "DR" } or (role == "DUD") and { "DU", "DD" } or { role }
        for _, a in ipairs(arms) do
            local r = ARM[a]
            if r then for y = r[2], r[4] do for x = r[1], r[3] do put(g, x, y, "ink") end end end
        end
    elseif role == "SEL" or role == "START" then
        if set == "ps" then
            g = newGrid(9, 11)
            fillInside(g, PILL, "paper"); stamp(g, PILL, 0, 0, "ink")
            if role == "SEL" then for _, x in ipairs({ 3, 5 }) do for y = 3, 7 do put(g, x, y, "ink") end end
            else for _, y in ipairs({ 3, 5, 7 }) do for x = 2, 6 do put(g, x, y, "ink") end end end
        else
            g = newGrid(13, 13)
            fillInside(g, RING, "paper"); stamp(g, RING, 0, 0, "ink")
            if set == "nin" then text(g, F35, role == "SEL" and "-" or "+", 5, 4, "ink")
            elseif role == "SEL" then stamp(g, VIEW, 4, 4, "ink")
            else for _, y in ipairs({ 4, 6, 8 }) do for x = 4, 8 do put(g, x, y, "ink") end end end
        end
    else
        return nil
    end
    local runs = {}
    for y = 0, g.h - 1 do
        local x = 0
        while x < g.w do
            local s = g.cell[y * g.w + x]
            if s then
                local x1 = x
                while x1 + 1 < g.w and g.cell[y * g.w + x1 + 1] == s do x1 = x1 + 1 end
                runs[#runs + 1] = { x, y, x1 - x + 1, s }
                x = x1 + 1
            else
                x = x + 1
            end
        end
    end
    return { w = g.w, h = g.h, runs = runs }
end

local cache = {}
local function pic(role, set)
    local key = set .. ":" .. role
    local p = cache[key]
    if p == nil then p = build(role, set) or false; cache[key] = p end
    return p or nil
end

local ALIAS = { A = "A", B = "B", X = "X", Y = "Y", LB = "LB", RB = "RB", LT = "LT", RT = "RT", LS = "LS", RS = "RS", L3 = "L3", R3 = "R3",
    ["L-STICK"] = "LS", ["R-STICK"] = "RS", ["<>"] = "DLR", ["D-PAD"] = "DPAD", SELECT = "SEL", BACK = "SEL", VIEW = "SEL", START = "START", MENU = "START",
    ["\226\134\144"] = "DL", ["\226\134\146"] = "DR", ["\226\134\145"] = "DU", ["\226\134\147"] = "DD" }
function G.roles(str)
    if type(str) ~= "string" or str == "" then return nil end
    local one = ALIAS[str]
    if one then return { one } end
    local out = {}
    for part in str:gmatch("%S+") do
        local r = ALIAS[part]
        if not r then return nil end
        out[#out + 1] = r
    end
    return (#out > 0) and out or nil
end

function G.k(h) return math.max(1, math.floor((tonumber(h) or 13) / 13 + 0.25)) end

function G.width(roles, k, set)
    set = set or G.set()
    if not (set and roles) then return 0 end
    local w = 0
    for i, r in ipairs(roles) do
        local p = pic(r, set)
        if p then w = w + p.w * k + ((i > 1) and k or 0) end
    end
    return w
end

local function slotColour(s, T, light)
    if type(s) == "table" then return s end
    if s == "ink" then return T.text end
    if s == "paper" then return T.surf3 end
    if s == "knock" then return T.surf1 end
    if s == "rim" then return light and RIM_LIGHT or RIM_DARK end
    return T.text
end
local function isLight(T)
    local b = T.base
    return b and (b.r + b.g + b.b) > 1.5
end

function G.draw(panel, roles, x, y, h, k, set, pal)
    set = set or G.set(G.playerOf(panel))
    if not (set and roles and panel and panel.drawRect) then return 0 end
    local T = pal or LC93.T
    local light = isLight(T)
    local x0 = x
    for i, r in ipairs(roles) do
        local p = pic(r, set)
        if p then
            if i > 1 then x = x + k end
            local py = y + math.floor((h - p.h * k) / 2)
            for _, run in ipairs(p.runs) do
                local c = slotColour(run[4], T, light)
                panel:drawRect(x + run[1] * k, py + run[2] * k, run[3] * k, k, (type(run[4]) == "table") and 1 or (c.a or 1), c.r, c.g, c.b)
            end
            x = x + p.w * k
        end
    end
    return x - x0
end
