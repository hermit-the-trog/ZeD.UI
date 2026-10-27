-- ZeD-UI/42/media/lua/client/ZeD/ZeD_PadGlyphs.lua
-- ============================================================================
-- THE CONTROLLER'S BUTTONS AS PICTURES (director, Oct 24 2026: "are we going
-- to use graphic icons for gamepad buttons. I think we should to help with
-- quick glance identifying"; GAMEPAD_SPEC.md, Button pictures; mockup
-- ZeDUI/mockups/zed_quick_chords_v1.html, approved Oct 24 2026)
--
-- ZeD's own pixel art, not the game's 32 px outlines: every picture is a few
-- design pixels, each drawn as a k x k block (ZeD_PixelParts' rule: whole
-- multiples only), so it stays sharp at every UI scale. One set per pad:
-- Xbox, PlayStation, Steam Deck, Nintendo. The set is ZeD's "Gamepad glyph
-- display" setting; Auto follows the game's controller button style. Face
-- buttons wear the pad's own colours (Steam Deck and Nintendo pads have
-- none); everything else is the theme's ink. The shape or the letter alone
-- tells every button apart.
--
-- Roles, the button's place on the pad (JoypadButton): A B X Y (bottom,
-- right, left, top), LB RB, LT RT, LS RS (the sticks), L3 R3 (the stick
-- clicks), DPAD, DU DD DL DR (one arm), DLR DUD (two arms), SEL START.
-- A Nintendo picture names the button in that place on its pad: role A
-- reads B.
--
--   G.set()                      the set in use: "xbox" | "ps" | "deck" | "nin", nil = lettered boxes
--   G.roles(text)                a prompt's glyph text as roles ("RT LT" -> { "RT", "LT" }), nil if not a button
--   G.k(h)                       the whole pixel multiple for a picture about h px tall
--   G.width(roles, k)            the pictures' width side by side
--   G.draw(panel, roles, x, y, h, k)   draws them centred in a strip h tall at y; returns the width
--   G.name(role)                 the button's name on this pad ("Cross", "L1"), for words
-- ============================================================================

require "ZeD/PixelFonts"

ZeD = ZeD or {}
ZeD.PadGlyphs = ZeD.PadGlyphs or {}
local G = ZeD.PadGlyphs

local F35, F57 = ZeD.PixelFonts["35"], ZeD.PixelFonts["57"]

-- outlines, a row per string, "X" = a pixel
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
local VIEW = { "XXXX..", "X..X..", "X.XXXX", "XXX..X", "..X..X", "..XXXX" }   -- two windows, one over the other
-- the arms of the D-pad (x0, y0, x1, y1)
local ARM = { DU = { 5, 1, 7, 4 }, DD = { 5, 8, 7, 11 }, DL = { 1, 5, 4, 7 }, DR = { 8, 5, 11, 7 } }

-- the pads' own colours
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

-- ---------------------------------------------------------------------------
-- the set in use
-- ---------------------------------------------------------------------------
local SETTING = { xbox = "xbox", ps = "ps", deck = "deck", nintendo = "nin" }
local STYLE = { PS4 = "ps", STEAMDECK = "deck" }   -- the game's file prefixes (JoyPadSetup: initControllerButtonStyle)
function G.set()
    local key = (ZeD.Settings and ZeD.Settings.glyphKey and ZeD.Settings.glyphKey()) or "auto"
    if key == "auto" then
        local ok, s = pcall(function() return getCore():getOptionControllerButtonStyleString() end)
        return (ok and STYLE[tostring(s)]) or "xbox"
    end
    return SETTING[key]
end

-- ---------------------------------------------------------------------------
-- a picture's pixels: a grid of slots, the last stamp on a pixel wins
-- slots: a colour table, or "ink" / "paper" / "knock" / "rim" (the theme's)
-- ---------------------------------------------------------------------------
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
-- between the outline's first and last pixel on each inner row
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
        put(g, 6, 1, "ink"); put(g, 6, 11, "ink"); put(g, 1, 6, "ink"); put(g, 11, 6, "ink")   -- the four ways it moves
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
    -- runs: one rect per stretch of the same slot on a row
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
G.pic = pic

-- ---------------------------------------------------------------------------
-- prompt text to roles
-- ---------------------------------------------------------------------------
local ALIAS = { A = "A", B = "B", X = "X", Y = "Y", LB = "LB", RB = "RB", LT = "LT", RT = "RT", LS = "LS", RS = "RS", L3 = "L3", R3 = "R3",
    ["L-STICK"] = "LS", ["R-STICK"] = "RS", ["<>"] = "DLR", ["D-PAD"] = "DPAD", SELECT = "SEL", BACK = "SEL", VIEW = "SEL", START = "START", MENU = "START",
    ["\226\134\144"] = "DL", ["\226\134\146"] = "DR", ["\226\134\145"] = "DU", ["\226\134\147"] = "DD" }
G.ALIAS = ALIAS
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

-- ---------------------------------------------------------------------------
-- sizes and drawing
-- ---------------------------------------------------------------------------
-- the whole multiple that makes a 13-pixel picture about h px tall
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

-- the pictures side by side, each centred in a strip h tall at y; panel:drawRect only
function G.draw(panel, roles, x, y, h, k, set)
    set = set or G.set()
    if not (set and roles and panel and panel.drawRect) then return 0 end
    local T = ZeD.T
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

-- ---------------------------------------------------------------------------
-- The controller strip of a HUD prop (the car radio, the siren controller, the two-way radio's full
-- view): the windows' help line without a window around it. Surface 2, solid (props never go
-- see-through), a 1u structure line on top, then the prompts left-aligned from 10u: each button's
-- picture 14u tall (its name in a box when the glyph setting is Keyboard/mouse or Off) and its label
-- in F2, 8u between prompts. A plain string is a dim note. When the prompts do not fit the strip,
-- the leftmost go first, as in the help line. The callers show it only while the pad has the prop.
--   G.stripH()                                the strip's height (22u, the help line's)
--   G.drawStrip(panel, x, y, w, prompts)      prompts = { "D-PAD Move", { glyph = "A", label = "Press" }, ... }
-- ---------------------------------------------------------------------------
local STRIP_H, PIC_H = 22, 14
function G.stripH() return ZeD.T.px(STRIP_H) end

local _sw, _sr, _sg = {}, {}, {}   -- the prompts' widths, roles and picture widths (reused each frame)
function G.drawStrip(panel, x, y, w, prompts)
    local T, tm = ZeD.T, ZeD.TM
    local h = G.stripH()
    local s2, bs = T.surf2, T.borderS
    panel:drawRect(x, y, w, h, 1, s2.r, s2.g, s2.b)
    panel:drawRect(x, y, w, T.hair, bs.a or 1, bs.r, bs.g, bs.b)
    local f2, f5 = T.fontF2, T.fontF5
    local pic, gap, between = T.px(PIC_H), T.px(4), T.px(8)
    local set = G.set()
    local k = G.k(pic)
    local n = #prompts
    local total = 0
    for i = 1, n do
        local pr = prompts[i]
        local label, gw, roles = nil, 0, false
        if type(pr) == "string" then
            label = pr
        else
            label = tostring(pr.label or "")
            roles = (set and (pr.pad or G.roles(pr.glyph))) or false
            if roles then gw = G.width(roles, k, set)
            else gw = math.max(pic, tm:MeasureStringX(f5, tostring(pr.glyph or "")) + T.px(4)) end
        end
        local wi = ((gw > 0) and (gw + gap) or 0) + ((label ~= "") and tm:MeasureStringX(f2, label) or 0)
        _sw[i], _sr[i], _sg[i] = wi, roles, gw
        total = total + wi + ((i > 1) and between or 0)
    end
    local x0, maxX = x + T.px(10), x + w - T.px(10)
    local first = 1
    while first < n and x0 + total > maxX do
        total = total - _sw[first] - between
        first = first + 1
    end
    if x0 + total > maxX then return end
    local fh2 = T.fontF2H or tm:getFontHeight(f2)
    local textY = y + math.floor((h - fh2) / 2)
    local tc, td = T.text, T.textDim
    local px = x0
    for i = first, n do
        local pr = prompts[i]
        local gw = _sg[i]
        if type(pr) == "string" then
            panel:drawText(pr, px, textY, td.r, td.g, td.b, td.a or 1, f2)
        else
            if _sr[i] then
                G.draw(panel, _sr[i], px, y, h, k, set)
            else
                local g = tostring(pr.glyph or "")
                local gy = y + math.floor((h - pic) / 2)
                local fh5 = T.fontF5H or tm:getFontHeight(f5)
                ZeD.Atoms.frame(panel, px, gy, gw, pic, bs)
                panel:drawText(g, px + math.floor((gw - tm:MeasureStringX(f5, g)) / 2), gy + math.floor((pic - fh5) / 2), tc.r, tc.g, tc.b, tc.a or 1, f5)
            end
            local label = tostring(pr.label or "")
            if label ~= "" then panel:drawText(label, px + gw + ((gw > 0) and gap or 0), textY, tc.r, tc.g, tc.b, tc.a or 1, f2) end
        end
        px = px + _sw[i] + between
    end
end

-- ---------------------------------------------------------------------------
-- the small pictures, five pixels tall, for the HUD props' pixel lettering
-- (the dash's top edge has room for its 3 x 5 letters and no more): the
-- face buttons as their letter or shape in the pad's colour, the rest as
-- the button's name in the lettering's own ink
-- ---------------------------------------------------------------------------
local MINI = {
    tri   = { "..X..", ".X.X.", ".X.X.", "X...X", "XXXXX" },
    circ  = { ".XXX.", "X...X", "X...X", "X...X", ".XXX." },
    cross = { "X...X", ".X.X.", "..X..", ".X.X.", "X...X" },
    sq    = { "XXXXX", "X...X", "X...X", "X...X", "XXXXX" },
}
-- the pixels of one small picture: rows and a colour (nil = the caller's ink), or a name to spell
local function mini(role, set)
    if role == "A" or role == "B" or role == "X" or role == "Y" then
        if set == "ps" then local c = PAD.ps[role]; return MINI[c[1]], c[2] end
        if set == "xbox" then return F35[role], PAD.xbox[role][1] end
        return F35[(set == "nin") and NAMES.nin[role] or role], nil
    end
    return nil, nil, (NAMES[set] and NAMES[set][role]) or role
end
-- its width in lettering pixels
function G.miniWidth(role, set)
    set = set or G.set()
    if not set then return 0 end
    local rows, _, word = mini(role, set)
    if rows then return #rows[1] end
    return (ZeD.Px and ZeD.Px.textWidth(word, "35", 1)) or (#word * 4 - 1)
end
-- draws it on a ZeD_PixelParts canvas at lettering pixel (x, y), with the lettering's ink and
-- shadow (both colour tables or "#rrggbb"); returns the width
function G.drawMini(cv, role, x, y, ink, shadow, set)
    set = set or G.set()
    if not set then return 0 end
    local P = ZeD.Px
    local rows, col, word = mini(role, set)
    if not rows then return P.text(cv, word, x, y, P.color(ink), "35", 1, "l", nil, shadow) end
    local c = col or P.color(ink)
    local sh = shadow and P.color(shadow)
    for pass = (sh and 1 or 2), 2 do
        local dx, cc = (pass == 1) and 1 or 0, (pass == 1) and sh or c
        for ry = 1, #rows do
            local r = rows[ry]
            for rx = 1, #r do
                local ch = r:sub(rx, rx)
                if ch == "X" or ch == "1" then P.rect(cv, x + rx - 1 + dx, y + ry - 1 + dx, 1, 1, cc) end
            end
        end
    end
    return #rows[1]
end

-- the button's name on this pad, for words ("Hold L1 and press Square")
function G.name(role, set)
    set = set or G.set() or "xbox"
    local n = NAMES[set] and NAMES[set][role]
    return n or role
end
