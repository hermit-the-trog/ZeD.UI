-- ZeDUI/tools/qa/balloon_b10_sim.lua  (Nov 8 2026): the beta 10 balloon (Balloon.lua, RichTip.lua, Tokens.lua and the
-- strip's end boxes) with no game running. The real files are loaded on stubs: a text measure that counts characters
-- (UTF-8 in plain Lua) at each face's size, a screen, a clock and a pointer, and panels that write down every draw.
--   SIZE     hints and titled balloons at 1080p, 1.75x (4K) and 1280x800, Small and Large text: the box is the
--            longest line plus the padding, capped at 200u / 320u (Large: x1.15), a word longer than that widens it up
--            to 1.5x and then breaks; no line is ever wider than the box's inside, and every word drawn sits in the box
--   LONG     long German and Russian strings (the strip's longest name, the moodle's two-sentence line) never spill
--   TAIL     the 10-cell tail's tip is on its control, one hairline short of it, above, under (no room above), beside
--            (right, then left at the screen's edge), and when the box slides to stay on screen
--   COVER    a balloon above or under the strip never covers the strip
--   ONE      one balloon at a time: a later control takes the slot from one still asked for, a menu's outranks a hint,
--            the pointer on the balloon keeps it, Escape / B hides it until the control changes
--   REQ      the disassemble tooltip (built as ISDisassembleMenu builds it): the Name row left out, the tools one row each
--            with their values one under another, the condition row with the dash dropped, game order kept; each word
--            drawn once; checks and crosses in positiveText / dangerText; every value at one x; the picture first
--   TOKENS   positiveText and dangerText at least 4.5 : 1 on surface 2 in every theme; the strip's arrow (textOnAccent)
--            at least 3 : 1 on every accent in every theme
--   ARROWS   drawTruncChevron fills the accent, frames it in ink, draws the triangle in textOnAccent; pressed moves 1u
-- Run from the repo root: lua51 ZeDUI/tools/qa/balloon_b10_sim.lua
local LUA = "42/media/lua/"

local function slurp(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return (s:gsub("\r", "")) end
local pass, fail = 0, 0
local function ok(c, name) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. name) end end

-- ---------------------------------------------------------------- the stubs
local SW, SH = 1920, 1080
local NOW, MX, MY = 100000, -1, -1
function getTimestampMs() return NOW end
function getMouseX() return MX end
function getMouseY() return MY end
local GOOD, BAD = { r = 0.25, g = 0.85, b = 0.25 }, { r = 0.9, g = 0.2, b = 0.2 }
local function ci(c) return { getR = function() return c.r end, getG = function() return c.g end, getB = function() return c.b end } end
local CORE = { getScreenWidth = function() return SW end, getScreenHeight = function() return SH end,
               getGoodHighlitedColor = function() return ci(GOOD) end, getBadHighlitedColor = function() return ci(BAD) end }
function getCore() return CORE end
require = function() end
UIFont = setmetatable({}, { __index = function(_, k) return k end })

ZeD = {}
-- the real tokens: base themes, accents, the readable derivation
local okT, errT = pcall(function() assert(loadstring(slurp(LUA .. "shared/ZeD/Tokens.lua")))() end)
if not okT then print("NOTE Tokens.lua's own applyTheme stopped on the stubs: " .. tostring(errT)) end
ok(ZeD.BaseThemes and ZeD.AccentColors and ZeD.deriveReadable, "Tokens.lua loads its themes and the readable derivation")

-- fonts: a face's size in px at the scale; a character is 0.56 of it (sans) or 0.62 (mono); the line is 1.2 of it
local FACE = { F1 = { 11, 0.62 }, F2 = { 13, 0.56 }, F3 = { 11, 0.62 }, F4 = { 15, 0.56 }, F5 = { 9, 0.56 } }
local LARGE = { F1 = 13, F2 = 15, F3 = 13, F4 = 17, F5 = 11 }
local function chars(s) return #(tostring(s):gsub("[\128-\191]", "")) end
ZeD.TM = {
    MeasureStringX = function(_, f, s) return math.floor(chars(s) * f.px * f.k + 0.5) end,
    MeasureStringY = function(_, f, s) return math.floor(f.px * 1.2 + 0.5) end,
    getFontHeight = function(_, f) return math.floor(f.px * 1.2 + 0.5) end,
}
local EPOCH = 1
ZeD.Text = { measureEpoch = function() return EPOCH end }

-- ZeD.T for a theme, a root scale and a text size (only what the balloon reads)
local function setT(theme, root, size, accent)
    local base = ZeD.BaseThemes[theme]
    local sz = (size == "large") and 1.15 or 1
    local sc = root * sz
    local T = {}
    for k, v in pairs(base) do T[k] = v end
    T.scale, T.root = sc, root
    T.px = function(u) return math.floor(u * sc + 0.5) end
    local hair = math.max(1, math.floor(sc + 0.5))
    T.hair = hair
    T.line = function(n) return math.max(1, math.floor((n or 1) * hair + 0.5)) end
    for k, v in pairs(FACE) do
        local px = ((size == "large") and LARGE[k] or v[1]) * root
        T["font" .. k] = { px = px, k = v[2], name = k .. size .. root }
    end
    local set = ZeD.AccentColors[accent or "orange"][(theme == "light") and "light" or "dark"]
    T.accent, T.hover, T.textOnAccent = set.accent, set.hover, set.textOnAccent
    T.ctx = { chevW = T.px(12), cellH = T.px(22) }
    ZeD.deriveReadable(T, theme)
    T.textSec = T.textSec or T.textDim
    ZeD.T = T
    EPOCH = EPOCH + 1
    return T
end

-- a panel that writes down every draw, at a place on screen
local function recorder(ax, ay)
    local p = { texts = {}, rects = {}, ax = ax or 0, ay = ay or 0 }
    function p:getAbsoluteX() return self.ax end
    function p:getAbsoluteY() return self.ay end
    function p:drawText(s, x, y, r, g, b, a, f) self.texts[#self.texts + 1] = { s = s, x = x, y = y, r = r, g = g, b = b, f = f } end
    function p:drawRect(x, y, w, h, a, r, g, b) self.rects[#self.rects + 1] = { x = x, y = y, w = w, h = h, r = r, g = g, b = b, a = a } end
    function p:drawTextureScaledAspect(t, x, y, w, h) self.pic = { x = x, y = y, w = w, h = h } end
    return p
end
ZeD.Atoms = {
    drawHardShadow = function(p, x, y, w, h) end,
    frame = function(p, x, y, w, h, c, a, t)
        t = t or ZeD.T.hair
        p:drawRect(x, y, w, t, 1, c.r, c.g, c.b); p:drawRect(x, y + h - t, w, t, 1, c.r, c.g, c.b)
        p:drawRect(x, y + t, t, h - 2 * t, 1, c.r, c.g, c.b); p:drawRect(x + w - t, y + t, t, h - 2 * t, 1, c.r, c.g, c.b)
    end,
}
assert(loadstring(slurp(LUA .. "client/ZeD/Balloon.lua")))()
assert(loadstring(slurp(LUA .. "client/ZeD/RichTip.lua")))()
local B, RT = ZeD.Balloon, ZeD.RichTip

-- every word drawn inside the box and inside its padding
local function inside(p, box, lay, name)
    local T = ZeD.T
    local good = true
    for _, t in ipairs(p.texts) do
        local w = ZeD.TM:MeasureStringX(t.f, t.s)
        if t.x < box.x + lay.padX - 0.01 or t.x + w > box.x + box.w - lay.padX + 0.01 or t.y < box.y or t.y + ZeD.TM:getFontHeight(t.f) > box.y + box.h then
            good = false
            print("  spill: '" .. t.s .. "' x " .. t.x .. "+" .. w .. " in box " .. box.x .. "+" .. box.w)
        end
    end
    ok(good, name .. ": every word inside the box")
end

-- ---------------------------------------------------------------- SIZE and LONG
local STR = {
    en = { strip = "Put in Container (Driver's Seat)", hint = "Transfer All", long = "Dehydrated. Minor discomfort." },
    de = { strip = "Lege in Beh\195\164lter (Fahrersitz)", hint = "Alles verschieben",
           long = "Dehydriert. Leichtes Unwohlsein. Gartens\195\164gen- und Schlosserhammerverwendungshinweis." },
    ru = { strip = "\208\159\208\190\208\187\208\190\208\182\208\184\209\130\209\140 \208\178 \208\186\208\190\208\189\209\130\208\181\208\185\208\189\208\181\209\128 (\208\146\208\190\208\180\208\184\209\130\208\181\208\187\209\140\209\129\208\186\208\190\208\181 \209\129\208\184\208\180\208\181\208\189\209\140\208\181)",
           hint = "\208\159\208\181\209\128\208\181\208\188\208\181\209\129\209\130\208\184\209\130\209\140 \208\178\209\129\209\145",
           long = "\208\163\208\188\208\181\209\128\208\181\208\189\208\189\208\190\208\181 \208\190\208\177\208\181\208\183\208\178\208\190\208\182\208\184\208\178\208\176\208\189\208\184\208\181. \208\157\208\181\208\183\208\189\208\176\209\135\208\184\209\130\208\181\208\187\209\140\208\189\208\190\208\181 \208\189\208\181\208\180\208\190\208\188\208\190\208\179\208\176\208\189\208\184\208\181." },
}
local SCALES = { { "1080p", 1920, 1080, 1.0 }, { "4K 1.75x", 3840, 2160, 1.75 }, { "1280x800", 1280, 800, 800 / 1080 } }
for _, sc in ipairs(SCALES) do
    SW, SH = sc[2], sc[3]
    for _, size in ipairs({ "small", "large" }) do
        local T = setT("dark", sc[4], size)
        local tag = sc[1] .. " " .. size
        for lang, S in pairs(STR) do
            for _, c in ipairs({ { kind = "plain", title = S.hint }, { kind = "rich", title = S.strip, path = { "Move to" } },
                                 { kind = "rich", title = S.hint, lines = { S.long, { text = "2.0 kg", font = "F3" } } } }) do
                local lay = B.layout(c)
                local cap = T.px(c.kind == "plain" and 200 or 320)
                local label = tag .. " " .. lang .. " " .. c.kind .. " '" .. c.title .. "'"
                ok(lay.w <= math.floor(cap * 1.5), label .. ": the box stays within 1.5x the cap (" .. lay.w .. " <= " .. math.floor(cap * 1.5) .. ")")
                -- natural width: no wider than needed, no narrower than its words
                local fits = true
                for _, ln in ipairs(lay.lines) do if ZeD.TM:MeasureStringX(T["font" .. ln.k], ln.s) > lay.inner then fits = false end end
                for _, tl in ipairs(lay.tLines) do
                    local last = tl[#tl]
                    if last.x + ZeD.TM:MeasureStringX(T["font" .. lay.tk], last.s) > lay.inner + 0.01 then fits = false end
                end
                ok(fits, label .. ": every line fits the inside (" .. lay.inner .. " px)")
                local p = recorder(0, 0)
                MX, MY = -1, -1
                NOW = NOW + 1000
                local x, y, w, h = B.draw(p, c, { x = SW / 2, y = SH / 2, w = T.px(22), h = T.px(22) }, "above", { key = label })
                ok(x ~= nil, label .. ": drawn")
                if x then inside(p, { x = x, y = y, w = w, h = h }, lay, label) end
            end
        end
        -- the short hint is as wide as its words plus the padding, not the cap
        local lay = B.layout({ kind = "plain", title = "Back" })
        ok(lay.w == ZeD.TM:MeasureStringX(T.fontF2, "Back") + T.px(16), tag .. ": a short hint is its words plus 8u each side (" .. lay.w .. ")")
        -- a hint uses F2, a title F4 (no F1 anywhere)
        local p = recorder(0, 0)
        NOW = NOW + 1000
        B.draw(p, { kind = "rich", title = "Saw", lines = { "words" } }, { x = 300, y = 300, w = 20, h = 20 }, "above", { key = "f" .. tag })
        local f4, f2, f1 = false, false, false
        for _, t in ipairs(p.texts) do
            if t.f == T.fontF4 then f4 = true end
            if t.f == T.fontF2 then f2 = true end
            if t.f == T.fontF1 then f1 = true end
        end
        ok(f4 and f2 and not f1, tag .. ": the title in F4, lines in F2, no F1")
    end
end

-- the cap: 200u / 320u, and Large text's 1.15 through T.px
do
    SW, SH = 1920, 1080
    local T = setT("dark", 1, "large")
    local lay = B.layout({ kind = "plain", title = string.rep("word ", 60) })
    ok(lay.w == T.px(200) and T.px(200) == 230, "Large text: a long hint wraps at 230 px at 1080p (" .. lay.w .. ")")
    local lay2 = B.layout({ kind = "rich", title = "T", lines = { string.rep("word ", 90) } })
    ok(lay2.w == 368, "Large text: a titled balloon wraps at 368 px at 1080p (" .. lay2.w .. ")")
    -- one word longer than the cap: widens to 1.5x, then breaks
    setT("dark", 1, "small")
    local lay3 = B.layout({ kind = "plain", title = string.rep("W", 40) })
    ok(lay3.w > ZeD.T.px(200) and lay3.w <= 300, "a word longer than 200u widens the hint up to 300 px (" .. lay3.w .. ")")
    local lay4 = B.layout({ kind = "plain", title = string.rep("W", 120) })
    ok(lay4.w == 300 and #lay4.tLines >= 2, "a word longer than 1.5x the cap breaks between characters (" .. #lay4.tLines .. " lines)")
    -- a Russian word broken between letters, never inside a letter
    local ru = string.rep("\208\150", 70)
    local lay5 = B.layout({ kind = "plain", title = ru })
    local whole = true
    for _, tl in ipairs(lay5.tLines) do for _, w in ipairs(tl) do if (#w.s % 2) ~= 0 then whole = false end end end
    ok(#lay5.tLines >= 2 and whole, "a long Russian word breaks between letters, never inside one")
end

-- ---------------------------------------------------------------- TAIL
local function tipOf(p, lay, box)
    -- the tail's cells are the rects outside the box in the border color: the tip is the one farthest from the box
    local T = ZeD.T
    local far, tip = -1, nil
    for _, r in ipairs(p.rects) do
        local out = r.x + r.w <= box.x or r.x >= box.x + box.w or r.y + r.h <= box.y or r.y >= box.y + box.h
        if out then
            local d = math.max(box.x - (r.x + r.w), r.x - (box.x + box.w), box.y - (r.y + r.h), r.y - (box.y + box.h))
            if d > far then far, tip = d, r end
        end
    end
    return tip, far
end
do
    SW, SH = 1920, 1080
    for _, sc in ipairs({ 1, 1.75 }) do
        for _, theme in ipairs({ "dark", "hicon" }) do
            local T = setT(theme, sc, "small")
            local cell = T.hair
            local c = { kind = "rich", title = "Put in Container", lines = { "A line of words to make it wide enough." } }
            local cases = {
                { "middle, above", { x = 900, y = 600, w = T.px(22), h = T.px(22) }, "above", "above" },
                { "right edge, above (lower right corner, slid)", { x = SW - T.px(10), y = 600, w = T.px(8), h = T.px(22) }, "above", "above" },
                { "left edge, above", { x = 0, y = 600, w = T.px(22), h = T.px(22) }, "above", "above" },
                { "top edge: under", { x = 900, y = T.px(10), w = T.px(22), h = T.px(22) }, "above", "below" },
                { "beside, right", { x = 600, y = 500, w = T.px(200), h = T.px(24) }, "right", "right" },
                { "beside, right edge: left", { x = SW - T.px(220), y = 500, w = T.px(200), h = T.px(24) }, "right", "left" },
                { "beside, near the bottom (slid up)", { x = 600, y = SH - T.px(20), w = T.px(200), h = T.px(16) }, "right", "right" },
            }
            for _, k in ipairs(cases) do
                local name, a, pref, want = k[1], k[2], k[3], k[4]
                local p = recorder(0, 0)
                NOW = NOW + 1000
                local x, y, w, h = B.draw(p, c, a, pref, { key = name .. theme .. sc })
                local box = { x = x, y = y, w = w, h = h }
                local pl = B.lastPlace
                local tag = theme .. " " .. sc .. "x " .. name
                ok(pl.side == want, tag .. ": goes " .. want .. " (" .. tostring(pl.side) .. ")")
                ok(x >= T.px(4) and x + w <= SW - T.px(4) and y >= T.px(4) and y + h <= SH - T.px(4), tag .. ": the box keeps 4u inside the screen")
                local tip, depth = tipOf(p, nil, box)
                ok(depth == 9 * cell, tag .. ": the tail is 10 cells deep (" .. tostring(depth) .. ")")
                if want == "above" then
                    ok(tip.x >= a.x and tip.x + tip.w <= a.x + a.w and tip.y + tip.h == a.y - cell,
                        tag .. ": the tip is over the control, one hairline above it (tip " .. tip.x .. "," .. tip.y .. ")")
                    ok(y + h <= a.y, tag .. ": the box does not cover the control")
                elseif want == "below" then
                    ok(tip.x >= a.x and tip.x + tip.w <= a.x + a.w and tip.y == a.y + a.h + cell, tag .. ": the tip is under the control, one hairline below it")
                elseif want == "right" then
                    ok(tip.x == a.x + a.w + cell and tip.y >= a.y and tip.y < a.y + a.h, tag .. ": the tip is at the row's right edge, at its height")
                    ok(x >= a.x + a.w, tag .. ": the box does not cover the row")
                else
                    ok(tip.x + tip.w == a.x - cell and tip.y >= a.y and tip.y < a.y + a.h, tag .. ": the tip is at the row's left edge, at its height")
                    ok(x + w <= a.x, tag .. ": the box does not cover the row")
                end
                -- the frame is opened under the tail's base (filled with surface 2)
                local s2 = ZeD.T.surf2
                local opened = false
                for _, r in ipairs(p.rects) do
                    if r.r == s2.r and r.g == s2.g and r.b == s2.b and (r.h == T.line(T.borderW) or r.w == T.line(T.borderW)) and r.w ~= w then opened = true end
                end
                ok(opened, tag .. ": the frame opens into the tail")
            end
        end
    end
end

-- ---------------------------------------------------------------- COVER: the strip
do
    SW, SH = 1920, 1080
    local T = setT("dark", 1, "small")
    local strip = { x = 800, y = 500, w = 230, h = 24 }
    local cell = { x = 900, y = 501, w = 22, h = 22, below = strip.y + strip.h }
    local c = { kind = "rich", title = "Disassemble", path = { "Mahogany Drawers" } }
    local p = recorder(0, 0)
    NOW = NOW + 1000
    local x, y, w, h = B.draw(p, c, cell, "above", { key = "strip1", prio = 2 })
    ok(y + h <= strip.y, "the strip's balloon above never covers the strip")
    cell.y, strip.y = 10, 9
    cell.below = strip.y + strip.h
    NOW = NOW + 1000
    x, y, w, h = B.draw(recorder(0, 0), c, cell, "above", { key = "strip2", prio = 2 })
    ok(y >= strip.y + strip.h, "with no room above, the balloon goes under the strip and does not cover it")
end

-- ---------------------------------------------------------------- ONE at a time
do
    SW, SH = 1920, 1080
    setT("dark", 1, "small")
    local a1 = { x = 100, y = 500, w = 22, h = 22 }
    local a2 = { x = 300, y = 500, w = 22, h = 22 }
    local c1, c2 = { kind = "plain", title = "One" }, { kind = "plain", title = "Two" }
    MX, MY = 110, 510
    NOW = NOW + 5000
    local p = recorder(0, 0)
    ok(B.draw(p, c1, a1, "above", { key = "k1", since = NOW }) ~= nil, "ONE: the first balloon draws")
    NOW = NOW + 16
    ok(B.draw(p, c1, a1, "above", { key = "k1", since = NOW - 16 }) ~= nil, "ONE: it keeps drawing")
    ok(B.draw(p, c2, a2, "above", { key = "k2", since = NOW }) ~= nil, "ONE: a control pointed at later takes the slot")
    NOW = NOW + 16
    ok(B.draw(p, c1, a1, "above", { key = "k1", since = NOW - 32 }) == nil, "ONE: the older one is not drawn while the newer is up")
    ok(B.draw(p, c2, a2, "above", { key = "k2", since = NOW - 16 }) ~= nil, "ONE: the newer keeps drawing")
    -- a menu's balloon outranks a hint
    NOW = NOW + 16
    ok(B.draw(p, c1, a1, "above", { key = "menu", since = NOW - 1000, prio = 2 }) ~= nil, "ONE: a menu's balloon takes the slot from a hint")
    ok(B.draw(p, c2, a2, "above", { key = "k2", since = NOW }) == nil, "ONE: a hint waits while a menu's balloon is up")
    -- the pointer on the balloon keeps it
    NOW = NOW + 1000
    local x, y, w, h = B.draw(p, c1, a1, "above", { key = "held", since = NOW, owner = "o" })
    MX, MY = x + 2, y + 2
    NOW = NOW + 16
    ok(B.held(), "ONE: the pointer on the balloon holds it")
    ok(B.draw(p, c2, a2, "above", { key = "under", since = NOW }) == nil, "ONE: a control under the balloon does not take the slot while the pointer is on it")
    ok(B.redrawHeld("o", recorder(0, 0)), "ONE: its owner draws it again with the pointer on it")
    MX, MY = a1.x + 11, a1.y - 2   -- the tail's corridor, between the control and the box
    NOW = NOW + 16
    ok(B.held(), "ONE: the pointer crossing the tail's corridor keeps it")
    -- dismiss: hidden until the control changes
    MX, MY = -1, -1
    NOW = NOW + 16
    B.draw(p, c1, a1, "above", { key = "d1", since = NOW })
    B.dismiss()
    NOW = NOW + 16
    ok(B.draw(p, c1, a1, "above", { key = "d1", since = NOW - 16 }) == nil, "ONE: Escape / B hides it")
    NOW = NOW + 16
    ok(B.draw(p, c1, a1, "above", { key = "d1", since = NOW - 32 }) == nil, "ONE: it stays hidden while the same control is pointed at")
    NOW = NOW + 16
    ok(B.draw(p, c2, a2, "above", { key = "d2", since = NOW }) ~= nil, "ONE: the next control's balloon shows")
    NOW = NOW + 1000
    ok(B.draw(p, c1, a1, "above", { key = "d1", since = NOW }) ~= nil, "ONE: back on the first control later, it shows again")
    -- the menus' B closes the menu: a menu's balloon is not dismissed by it
    NOW = NOW + 16
    B.draw(p, c1, a1, "above", { key = "m1", since = NOW, prio = 2 })
    B.dismiss()
    NOW = NOW + 16
    ok(B.draw(p, c1, a1, "above", { key = "m1", since = NOW, prio = 2 }) ~= nil, "ONE: a menu's balloon is not hidden by Escape / B (they act on the menu)")
    -- warm: a neighbor's balloon shows without the pause
    ok(B.warm(), "ONE: right after a balloon, the next shows at once")
    NOW = NOW + 1000
    ok(not B.warm(), "ONE: a second later, the pause is back")
end

-- ---------------------------------------------------------------- REQ
-- the tooltip as ISDisassembleMenu.createMenu builds it (from getInfoPanelDescription's rows)
local function disassembleDesc(L)
    local W, R, G = { 255, 255, 255 }, { BAD.r * 255, BAD.g * 255, BAD.b * 255 }, { GOOD.r * 255, GOOD.g * 255, GOOD.b * 255 }
    local function row(a, ca, b, cb) local t = { { txt = a, c = ca } }; if b then t[2] = { txt = b, c = cb } end; return t end
    local info = {
        row(L.name .. ":", W, L.drawers, W), row(L.skill .. ":", W, L.carpentry, G),
        row(L.tool .. ":", W, L.hammers[1], G), row("", W, L.hammers[2], G), row("", W, L.hammers[3], G), row("", W, L.hammers[4], G),
        row(L.tool .. ":", W, L.saws[1], R), row("", W, L.saws[2], R), row("", W, L.saws[3], R),
        row("- " .. L.hasItems, R),
    }
    local d = ""
    for _, t in ipairs(info) do
        d = string.format("%s <RGB:%.2f,%.2f,%.2f> %s", d, t[1].c[1] / 255, t[1].c[2] / 255, t[1].c[3] / 255, t[1].txt)
        if t[2] then d = string.format("%s <SETX:%d> <INDENT:%d> <RGB:%.2f,%.2f,%.2f> %s", d, 90, 90, t[2].c[1] / 255, t[2].c[2] / 255, t[2].c[3] / 255, t[2].txt) end
        d = d .. " <LINE> <INDENT:0> "
    end
    return d
end
local LREQ = {
    en = { name = "Name", skill = "Skill", tool = "Tool needed", drawers = "Mahogany Drawers", carpentry = "Carpentry",
           hammers = { "Ball-peen Hammer", "Claw Hammer", "Smithing Hammer", "Stone Hammer" }, saws = { "Hacksaw", "Simple Wood Saw", "Wood Saw" },
           hasItems = "Has items in container." },
    de = { name = "Name", skill = "F\195\164higkeit", tool = "Ben\195\182tigt Werkzeug", drawers = "Schicke Schubladen aus Eiche", carpentry = "Tischlerei",
           hammers = { "Schlosserhammer", "Hammer", "Schmiedehammer", "Steinhammer" }, saws = { "S\195\164ge", "Einfache Holzs\195\164ge", "Gartens\195\164ge" },
           hasItems = "Der Container enth\195\164lt Gegenst\195\164nde." },
}
for _, size in ipairs({ "small", "large" }) do
    for lang, L in pairs(LREQ) do
        for _, theme in ipairs({ "dark", "light", "hicon" }) do
            SW, SH = 1920, 1080
            local T = setT(theme, 1.75, size)
            local tag = "REQ " .. lang .. " " .. theme .. " " .. size
            local m = RT.parse(disassembleDesc(L), L.drawers)
            ok(m and #m.rows == 3 and #m.conds == 1, tag .. ": three rows (Name left out) and one condition (" .. (m and #m.rows or 0) .. ", " .. (m and #m.conds or 0) .. ")")
            if m then
                ok(m.rows[1].label == L.skill and m.rows[1].st == "ok", tag .. ": Skill first, met")
                ok(#m.rows[2].values == 4 and m.rows[2].st == "ok", tag .. ": the hammers are one row of four values, met")
                ok(#m.rows[3].values == 3 and m.rows[3].st == "bad", tag .. ": the saws are one row of three values, missing")
                ok(m.conds[1].t == L.hasItems and m.conds[1].st == "bad", tag .. ": the condition row, its dash dropped, missing")
                local c = { kind = "rich", title = L.drawers, path = { "Disassemble" }, req = m, pic = {} }
                local p = recorder(0, 0)
                NOW = NOW + 1000
                local x, y, w, h = B.draw(p, c, { x = 1500, y = 1500, w = T.px(22), h = T.px(22) }, "above", { key = tag })
                local lay = B.layout(c)
                inside(p, { x = x, y = y, w = w, h = h }, lay, tag)
                -- once: every value and label drawn once (words may wrap: count the first word of each)
                local counts = {}
                for _, t in ipairs(p.texts) do counts[t.s] = (counts[t.s] or 0) + 1 end
                local once = true
                for _, r in ipairs(m.rows) do for _, v in ipairs(r.values) do
                    local first = v.t:match("^%S+")
                    local n = 0
                    for s, k in pairs(counts) do if s:sub(1, #first) == first then n = n + k end end
                    if n < 1 then once = false; print("  missing " .. v.t) end
                end end
                ok(once, tag .. ": every value drawn")
                ok(not counts[L.drawers] or counts[L.drawers] == 1, tag .. ": the Name row is not drawn (the title says it)")
                -- colors: the saws in dangerText, the hammers in positiveText, labels in text
                local pos, dan, txt = T.positiveText, T.dangerText, T.text
                local function colOf(s) for _, t in ipairs(p.texts) do if t.s == s then return t end end end
                local h1, s1, lb = colOf(L.hammers[1]), colOf(L.saws[1]), colOf(L.skill)
                ok(h1 and h1.r == pos.r and h1.g == pos.g and h1.b == pos.b, tag .. ": a met value in positiveText")
                ok(s1 and s1.r == dan.r and s1.g == dan.g, tag .. ": a missing value in dangerText")
                ok(lb and lb.r == txt.r and lb.g == txt.g, tag .. ": the labels in the text color")
                -- one value column
                local xs = {}
                for _, r in ipairs(m.rows) do local t = colOf(r.values[1].t); if t then xs[#xs + 1] = t.x end end
                local same = #xs == 3
                for i = 2, #xs do if xs[i] ~= xs[1] then same = false end end
                ok(same, tag .. ": every value starts at one x")
                -- the picture first, 32u, the labels after it
                ok(p.pic and p.pic.x < lb.x and math.abs((p.pic.w + 2 * T.hair) - T.px(32)) <= 1, tag .. ": the picture first, 32u square")
                -- marks: rects in positiveText and dangerText (the check and the cross)
                local mp, md = 0, 0
                for _, r in ipairs(p.rects) do
                    if r.r == pos.r and r.g == pos.g and r.b == pos.b then mp = mp + 1 end
                    if r.r == dan.r and r.g == dan.g and r.b == dan.b then md = md + 1 end
                end
                ok(mp > 0 and md > 0, tag .. ": a check and a cross drawn")
            end
        end
    end
end
-- plain lines (no SETX): good / bad lines get marks
do
    local m = RT.parse(" <RGB:0.90,0.20,0.20> Needs a saw <LINE> <RGB:1,1,1> Takes a while <LINE> ", "x")
    ok(m and #m.rows == 0 and #m.conds == 2 and m.conds[1].st == "bad" and m.conds[2].st == nil, "REQ plain lines keep their marks rule")
    ok(RT.parse("Just words <LINE> more words", "x") == nil, "REQ a tooltip with no color or column stays plain words")
end

-- ---------------------------------------------------------------- TOKENS
local function lum(c)
    local function ch(v) if v <= 0.03928 then return v / 12.92 end return ((v + 0.055) / 1.055) ^ 2.4 end
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b)
end
local function ratio(a, b) local x, y = lum(a), lum(b); if x < y then x, y = y, x end; return (x + 0.05) / (y + 0.05) end
for _, theme in ipairs({ "dark", "light", "hicon" }) do
    for acc in pairs(ZeD.AccentColors) do
        local T = setT(theme, 1, "small", acc)
        local s2 = ZeD.BaseThemes[theme].surf2
        local rp, rd = ratio(T.positiveText, s2), ratio(T.dangerText, s2)
        ok(rp >= 4.5, string.format("TOKENS %s %s: positiveText on surface 2 %.2f : 1", theme, acc, rp))
        ok(rd >= 4.5, string.format("TOKENS %s %s: dangerText on surface 2 %.2f : 1", theme, acc, rd))
        local ra = ratio(T.textOnAccent, T.accent)
        ok(ra >= 3.0, string.format("TOKENS %s %s: the strip's arrow on the accent %.2f : 1", theme, acc, ra))
    end
end
do
    local base = ZeD.BaseThemes
    local function hx(c) return string.format("#%02X%02X%02X", math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5)) end
    ok(hx(base.dark.dangerText) == "#DE7045" and hx(base.dark.positiveText) == "#7A9A34", "TOKENS Dark: the design's values")
    ok(hx(base.light.positiveText) == "#204A0C" and hx(base.light.dangerText) == "#7A2A11", "TOKENS Light: the design's values")
    ok(hx(base.hicon.positiveText) == "#44DD44" and hx(base.hicon.dangerText) == "#FF5533", "TOKENS High contrast: the design's values")
end

-- ---------------------------------------------------------------- ARROWS
do
    local src = slurp(LUA .. "client/ZeD/AtomExtensions.lua")
    local a = assert(src:find("local CHEV_INK", 1, true), "the chevron's ink")
    local _, b = src:find("\nend\n", src:find("function ZeD.Atoms.drawTruncChevron", a, true), true)
    local tri = {}
    ZeD.Atoms.drawSteppedShadow = function(p, x, y, w, h) p.shadow = true end
    ZeD.Atoms.drawTriangleLeft = function(p, x, y, s, c) tri[#tri + 1] = { x = x, y = y, c = c, d = "l" } end
    ZeD.Atoms.drawTriangleRight = function(p, x, y, s, c) tri[#tri + 1] = { x = x, y = y, c = c, d = "r" } end
    assert(loadstring(src:sub(a, b)))()
    for _, theme in ipairs({ "dark", "light", "hicon" }) do
        for acc in pairs(ZeD.AccentColors) do
            local T = setT(theme, 1.75, "small", acc)
            local p = recorder(0, 0)
            tri = {}
            ZeD.Atoms.drawTruncChevron(p, 100, 50, "left", T, false)
            local fill = p.rects[1]
            ok(fill and fill.r == T.accent.r and fill.g == T.accent.g and fill.b == T.accent.b and fill.x == 100, "ARROWS " .. theme .. " " .. acc .. ": the box is the accent")
            local framed = false
            for i = 2, #p.rects do local r = p.rects[i]; if r.r < 0.1 and r.g < 0.1 then framed = true end end
            ok(framed and p.shadow, "ARROWS " .. theme .. " " .. acc .. ": framed in the strip's ink, with its shadow")
            ok(tri[1] and tri[1].c == T.textOnAccent and tri[1].d == "l", "ARROWS " .. theme .. " " .. acc .. ": the arrow in the accent's text color")
            local p2 = recorder(0, 0)
            tri = {}
            ZeD.Atoms.drawTruncChevron(p2, 100, 50, "right", T, true)
            ok(p2.rects[1].x == 100 + T.px(1) and p2.rects[1].y == 50 + T.px(1) and not p2.shadow and tri[1].d == "r",
               "ARROWS " .. theme .. " " .. acc .. ": pressed, the box moves 1u into its shadow")
        end
    end
end

print(string.format("balloon_b10_sim: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
