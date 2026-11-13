-- ZeDUI/tools/qa/theme_look_core_sim.lua  (Nov 12 2026, Build; punch list 175f and the D6 ruling, the shared look core)
-- With no game running, the real Tokens.lua and Settings.lua run on Lua 5.1 against a stub of the game's ModOptions (the
-- stubs follow default_accent_sim.lua), and the changed pieces of the other files are cut out and run on stubs. It checks:
--   SOLID     (175f(5), the director: "Solid in Light and HC") Light and High Contrast always draw the window bodies
--             solid, whatever See-through says: ZeD.applyTheme sets every surface to alpha 1 there, and ZeD.surfaceAlpha
--             (which the windows' own accent palettes read) reads 1; Dark keeps the pick, and the pick comes back when
--             the theme goes back to Dark, through applyTheme alone (the wheel, the window menu) and through ZeD setup
--   HELP      the See-through help line says it works in Dark only, in all 28 languages, with a context row and a
--             machine-draft note; the short "Dark theme only" line is there too
--   OFF       outside Dark the Select wheel's See-through and its choices are off and say why, the window menu's
--             See-through row is disabled with the same words, and ZeD setup's See-through and Solid while in use rows
--             dim (the controller passes over them) with the help line saying why
--   DISABLED  (175f(2b)) a grayed label (the default ink at T.disabledAlpha) stands at least 3 : 1 off surfaces 1 to 3
--             in every theme (Light was 2.4 : 1) and 4.5 : 1 in High Contrast (was 3.7 : 1); Dark keeps 0.42
--   SECTION   (D6) drawSectionHeader is the small fold-open mono line: no surface 2 band, F1 whatever font the caller
--             passes, the triangle, the words and the count in the category row's ink (T.toneLo); noArrow draws none
--   FOCUS     (175f(3), verify) the shared mark: the wash style is the 0.55 accent fill under the words (textOnFocus);
--             the hand style the hover wash and the hand (by design, the player's pick in ZeD setup)
--   MOODLES   (175f(4), verify) a moodle answers the pointer only while the engine's picking says the layer holds it
-- What it can't show: the colors on screen, the real game's ModOptions screen.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/theme_look_core_sim.lua
-- It prints FAIL lines and a last line "theme_look_core_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]theme_look_core_sim%.lua$", "")
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
local function section(s) print("-- " .. s) end

local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end

-- a top-level function of a file, from its opening text to its first unindented "end"
local function cutFn(src, open)
    local a = src:find(open, 1, true)
    if not a then return nil end
    local e = src:find("\nend\n", a, true)
    if not e then return nil end
    return src:sub(a, e + 4)
end

-- ---------------------------------------------------------------------------
-- THE STUBS (as default_accent_sim.lua)
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
getFileReader = function() return nil end

local opts = { dict = {}, order = {} }
local function newOption(id, kind)
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
ZeD = {
    Scale = { root = function() return 1 end },
    Text  = { checkRoleFonts = function() return false end, noFonts = true },
    Font  = { sdf = { sec = { font = 1 }, body = { font = 2 }, stat = { font = 3 }, head = { font = 4 }, title = { font = 5 } } },
}
setmetatable(_G, { __index = function() return dummy end })

local function load(dir, name)
    local f, err = loadfile(dir .. name)
    if not f then print("theme_look_core_sim: " .. tostring(err)); os.exit(1) end
    local ok, e = pcall(f)
    if not ok then print("theme_look_core_sim: " .. name .. ": " .. tostring(e)); os.exit(1) end
end

load(SDIR, "Tokens.lua")
ZeD.tr = ZeD.tr or function(k) return k end
load(CDIR, "Settings.lua")
setmetatable(_G, nil)

local SURF = { "base", "surf1", "surf2", "surf3", "surf4" }
local function alphas()
    local T, out = ZeD.T, {}
    for _, k in ipairs(SURF) do out[#out + 1] = (T[k] and T[k].a) or "nil" end
    return table.concat(out, " ")
end
local function allAlpha(a)
    for _, k in ipairs(SURF) do
        local c = ZeD.T[k]
        if not (c and math.abs((c.a or 1) - a) < 1e-6) then return false end
    end
    return true
end

-- ---------------------------------------------------------------------------
section("SOLID: Light and High Contrast draw the bodies solid; Dark keeps See-through")
-- ---------------------------------------------------------------------------
check("ZeD.seeThroughWorks: Dark yes, Light and High contrast no", ZeD.seeThroughWorks ~= nil
    and ZeD.seeThroughWorks("dark") == true and ZeD.seeThroughWorks("light") == false and ZeD.seeThroughWorks("hicon") == false)
do
    ZeD.surfaceAlpha = 0.7
    ZeD.applyTheme("light", "teal", "small")
    check("Light at See-through 70: every surface alpha 1", allAlpha(1), alphas())
    check("Light: ZeD.surfaceAlpha (the windows' own palettes read it) is 1", ZeD.surfaceAlpha == 1, ZeD.surfaceAlpha)
    ZeD.applyTheme("hicon", nil, nil)
    check("High contrast at See-through 70: every surface alpha 1", allAlpha(1), alphas())
    ZeD.applyTheme("dark", nil, nil)
    check("back to Dark through applyTheme alone (the wheel, the window menu): the pick of 70 comes back",
        allAlpha(0.7) and ZeD.surfaceAlpha == 0.7, alphas() .. " / " .. tostring(ZeD.surfaceAlpha))
    ZeD.applyTheme("dark", nil, nil)
    check("Dark applied twice keeps 70", allAlpha(0.7), alphas())
    -- no pick at all (before ZeD setup is read): Light's own 0.97 is not solid either
    ZeD.surfaceAlpha = nil
    ZeD._seeForced = nil
    ZeD.applyTheme("light", nil, nil)
    check("Light with no See-through pick: solid, not the theme's own 0.97", allAlpha(1), alphas())
    ZeD.applyTheme("dark", nil, nil)
    check("then Dark with no pick: the theme's own alpha (0.92)", allAlpha(0.92), alphas())
end
do
    -- through ZeD setup (Settings.lua applyFromOptions, from the combos' onChange)
    local S = ZeD.Settings
    local base, see = opts.dict.baseTheme, opts.dict.seeThrough
    check("ZeD setup has the base theme and See-through combos", base ~= nil and see ~= nil)
    if base and see then
        see:setValue(5)                -- 60
        base:setValue(2)               -- Light
        base.onChange(base, 2)
        check("ZeD setup, Light at 60: solid", ZeD.currentBase == "light" and allAlpha(1), ZeD.currentBase .. " " .. alphas())
        base:setValue(3)
        base.onChange(base, 3)
        check("ZeD setup, High contrast at 60: solid", ZeD.currentBase == "hicon" and allAlpha(1), ZeD.currentBase .. " " .. alphas())
        base:setValue(1)
        base.onChange(base, 1)
        check("ZeD setup, Dark at 60: see-through 0.6", ZeD.currentBase == "dark" and allAlpha(0.6), ZeD.currentBase .. " " .. alphas())
        see:setValue(3)
        see.onChange(see, 3)           -- 80, in Dark
        check("ZeD setup, Dark, a new pick of 80 takes", allAlpha(0.8), alphas())
        base.onChange(base, 2)
        base:setValue(2)
        check("then Light: solid", allAlpha(1), alphas())
        ZeD.applyTheme("dark", nil, nil)
        check("then Dark from the wheel: 80 again", allAlpha(0.8), alphas())
        base:setValue(1)
        see:setValue(2)
        S = nil
    end
end

-- ---------------------------------------------------------------------------
section("HELP: the help line says Dark only, in every language")
-- ---------------------------------------------------------------------------
local LANGS = { "AR", "CA", "CH", "CN", "CS", "DA", "DE", "EN", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT", "JP",
                "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
do
    local OLD_EN = "How much of the game shows through ZeD's windows: 100 is solid, 60 shows the most. Words, lines and controls stay solid."
    local miss = ""
    for _, L in ipairs(LANGS) do
        local t = readFile(ROOT .. "42/media/lua/shared/Translate/" .. L .. "/UI.json") or ""
        local tip = t:match('"UI_ZeD_Settings_SeeThroughTip": "([^"]*)"')
        local dark = t:match('"UI_ZeD_Settings_Dark": "([^"]*)"')
        local only = t:match('"UI_ZeD_Settings_SeeThroughDarkOnly": "([^"]*)"')
        -- the tip names the Dark theme by the language's own theme name (the new last sentence)
        if not (tip and dark and tip:find(dark, 1, true)) then miss = miss .. L .. ":tip " end
        if not (only and only ~= "") then miss = miss .. L .. ":darkOnly " end
        if L ~= "EN" then
            local n = readFile(ROOT .. "ZeDUI/i18n/mt_notes/" .. L .. ".txt") or ""
            if not n:find("UI_ZeD_Settings_SeeThroughDarkOnly", 1, true) then miss = miss .. L .. ":note " end
        end
    end
    check("the tip names Dark, the short line is there, a machine-draft note, in all 28 languages", miss == "", miss)
    local en = readFile(ROOT .. "42/media/lua/shared/Translate/EN/UI.json") or ""
    local tip = en:match('"UI_ZeD_Settings_SeeThroughTip": "([^"]*)"') or ""
    check("EN: the tip keeps its first sentences and adds Dark only", tip:sub(1, #OLD_EN) == OLD_EN and #tip > #OLD_EN
        and tip:find("Dark theme only", 1, true) ~= nil, tip)
    local ctx = readFile(ROOT .. "ZeDUI/i18n/UI_ZeD.context.md") or ""
    check("context rows for the tip and the short line", ctx:find("| `UI_ZeD_Settings_SeeThroughDarkOnly` |", 1, true) ~= nil
        and ctx:find("Works in the Dark theme only", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
section("OFF: the wheel, the window menu and ZeD setup show See-through off outside Dark")
-- ---------------------------------------------------------------------------
do
    local src = readFile(CDIR .. "ZeD_DpadWheels.lua") or ""
    local offFn = cutFn(src, "function Z.seeThroughOff()")
    local wheelFn = cutFn(src, "function Z.seeThroughWheel()")
    check("the wheel has Z.seeThroughOff", offFn ~= nil)
    if offFn and wheelFn then
        local chunk, err = loadstring("local Z = {}\nlocal SEE_ICON = 'seethrough'\nlocal function tr(k, ...) return k end\n"
            .. "local function inUse(on) return on and 'in use' or nil end\n" .. offFn .. wheelFn .. "\nreturn Z", "=ZeD_DpadWheels.lua (cut)")
        check("the wheel's pieces load", chunk ~= nil, err)
        if chunk then
            local Z = chunk()
            local S = ZeD.Settings
            local saved = { S.seeThroughIndex, S.solidInUse }
            S.seeThroughIndex = function() return 2 end
            S.solidInUse = function() return false end
            ZeD.applyTheme("light", nil, nil)
            local out = Z.seeThroughWheel()
            local allOff = #out > 0
            for _, e in ipairs(out) do if e.off ~= "UI_ZeD_Settings_SeeThroughDarkOnly" then allOff = false end end
            check("Light: every See-through choice on the wheel is off, saying Dark theme only", allOff and Z.seeThroughOff() ~= nil, #out)
            ZeD.applyTheme("dark", nil, nil)
            out = Z.seeThroughWheel()
            local noneOff = #out > 0
            for _, e in ipairs(out) do if e.off then noneOff = false end end
            check("Dark: no See-through choice is off", noneOff and Z.seeThroughOff() == nil)
            S.seeThroughIndex, S.solidInUse = saved[1], saved[2]
        end
    end
    check("the wheel's top See-through entry is off outside Dark", src:find("sub = Z.seeThroughWheel,\n          off = Z.seeThroughOff() }", 1, true) ~= nil)

    local wm = readFile(CDIR .. "ZeD_WindowMenu.lua") or ""
    local a = wm:find('local see = { name = tr("UI_ZeD_Settings_SeeThrough")', 1, true)
    local blk = a and wm:sub(a, a + 600) or ""
    check("the window menu's See-through row: disabled outside Dark, with the Dark-only words",
        blk:find("disabled = function() return ZeD.seeThroughWorks ~= nil and not ZeD.seeThroughWorks() end", 1, true) ~= nil
        and blk:find("UI_ZeD_Settings_SeeThroughDarkOnly", 1, true) ~= nil)

    local mo = readFile(CDIR .. "ZeD_MainMenuOptions.lua") or ""
    local s0 = mo:find("local SEE_ROWS = ", 1, true)
    local nf = cutFn(mo, "local function needsOff(r)")
    check("ZeD setup has the See-through rows' dim rule", s0 ~= nil and nf ~= nil)
    if s0 and nf then
        local e0 = mo:find("local function needsOff(r)", s0, true)
        local chunk, err = loadstring(mo:sub(s0, e0 - 1) .. nf .. "\nreturn needsOff", "=ZeD_MainMenuOptions.lua (cut)")
        check("ZeD setup's pieces load", chunk ~= nil, err)
        if chunk then
            local needsOff = chunk()
            local seeRow, solidRow, other = { labelKey = "UI_ZeD_Settings_SeeThrough" }, { labelKey = "UI_ZeD_Settings_SolidInUse" },
                { labelKey = "UI_ZeD_Settings_TextSize" }
            ZeD.applyTheme("light", nil, nil)
            check("Light: ZeD setup dims See-through and Solid while in use, not Text size",
                needsOff(seeRow) == true and needsOff(solidRow) == true and not needsOff(other))
            ZeD.applyTheme("dark", nil, nil)
            check("Dark: neither row is dimmed", not needsOff(seeRow) and not needsOff(solidRow))
        end
    end
    check("ZeD setup's help line on a dimmed See-through row is the tip (it says Dark only)",
        mo:find('if seeOff(r) then return UI.plain(ZeD.tr("UI_ZeD_Settings_SeeThroughTip")) end', 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
section("DISABLED: grayed labels readable in every theme")
-- ---------------------------------------------------------------------------
do
    local function lin(c) if c <= 0.03928 then return c / 12.92 end return ((c + 0.055) / 1.055) ^ 2.4 end
    local function lum(c) return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b) end
    local function over(fg, a, bg)
        return { r = bg.r * (1 - a) + fg.r * a, g = bg.g * (1 - a) + fg.g * a, b = bg.b * (1 - a) + fg.b * a }
    end
    local function ratio(c1, c2)
        local l1, l2 = lum(c1), lum(c2)
        if l1 < l2 then l1, l2 = l2, l1 end
        return (l1 + 0.05) / (l2 + 0.05)
    end
    for _, base in ipairs({ "dark", "light", "hicon" }) do
        ZeD.applyTheme(base, nil, nil)
        local T = ZeD.T
        local need = (base == "hicon") and 4.5 or 3.0
        local worst = 99
        for _, k in ipairs({ "surf1", "surf2", "surf3" }) do
            local bg = T[k]
            local r = ratio(over(T.text, (T.text.a or 1) * T.disabledAlpha, bg), bg)
            if r < worst then worst = r end
        end
        check(base .. ": a grayed label stands " .. need .. " : 1 or more off surfaces 1 to 3", worst >= need,
            string.format("%.2f at disabledAlpha %.2f", worst, T.disabledAlpha))
        print(string.format("   %s worst %.2f", base, worst))
    end
    ZeD.applyTheme("dark", nil, nil)
    check("Dark keeps disabledAlpha 0.42", math.abs(ZeD.T.disabledAlpha - 0.42) < 1e-6, ZeD.T.disabledAlpha)
    ZeD.applyTheme("light", nil, nil)
    check("a grayed label is still dimmer than a live one in Light", ZeD.T.disabledAlpha < 0.8, ZeD.T.disabledAlpha)
    ZeD.applyTheme("dark", nil, nil)
end

-- ---------------------------------------------------------------------------
section("SECTION: drawSectionHeader is the small fold-open mono line")
-- ---------------------------------------------------------------------------
do
    local LOG = {}
    local function col(r, g, b) return { r = r, g = g, b = b, a = 1 } end
    local saveZ = ZeD
    ZeD = {
        T = {
            px = function(n) return n end, hair = 1, fontF1 = "F1", fontF4 = "F4", sp = { sm = 6, xs = 4 },
            hover = col(0.5, 0.5, 0.5), textHead = col(0.9, 0.9, 0.9), textDim = col(0.4, 0.4, 0.4), arrow = col(0.6, 0.6, 0.6),
            toneLo = col(0.3, 0.7, 0.6), textOnFocus = col(0, 0, 0),
        },
        TM = { MeasureStringX = function(_, f, s) return #tostring(s) * 7 end, getFontHeight = function() return 12 end },
        Atoms = {
            textCase = function(s) return s end,
            truncateText = function(s) return s end,
            surfaceFill = function(_, x, y, w, h, k) LOG[#LOG + 1] = { k = "band", s = k } end,
            drawDividerH = function() LOG[#LOG + 1] = { k = "line" } end,
            drawTriangleDown = function(_, x, y, sz, c) LOG[#LOG + 1] = { k = "tri", c = c } end,
            drawTriangleRight = function(_, x, y, sz, c) LOG[#LOG + 1] = { k = "tri", c = c } end,
            drawTextRight = function(_, s, x, y, f, c) LOG[#LOG + 1] = { k = "text", s = s, f = f, c = c } end,
        },
        Molecules = {},
    }
    local panel = {
        drawRect = function(_, x, y, w, h, a, r, g, b) LOG[#LOG + 1] = { k = "rect", a = a } end,
        drawText = function(_, s, x, y, r, g, b, a, f) LOG[#LOG + 1] = { k = "text", s = s, f = f, c = { r = r, g = g, b = b } } end,
    }
    local piece = cutFn(readFile(CDIR .. "Molecules.lua") or "", "function ZeD.Molecules.drawSectionHeader(")
    local chunk, err = piece and loadstring("local NO_OPTS = {}\nlocal SECTION_H = 20\n" .. piece, "=Molecules.lua (cut)")
    check("drawSectionHeader cut and loads", chunk ~= nil, err)
    if chunk then
        chunk()
        local T = ZeD.T
        local function same(c, t) return c and t and c.r == t.r and c.g == t.g and c.b == t.b end
        local function draw(...)
            LOG = {}
            ZeD.Molecules.drawSectionHeader(panel, 10, 0, 200, ...)
            local out = { bands = 0, tris = 0, texts = {} }
            for _, e in ipairs(LOG) do
                if e.k == "band" then out.bands = out.bands + 1 end
                if e.k == "tri" then out.tris = out.tris + 1; out.tri = e end
                if e.k == "text" then out.texts[#out.texts + 1] = e end
                if e.k == "line" then out.line = true end
            end
            return out
        end
        -- (as EquipmentTab's Defense passes it: F4, a bleed, a height of its own)
        local o = draw("Defense", nil, true, false, T.fontF4, nil, 8, 30)
        check("no surface 2 band under the section head", o.bands == 0, o.bands)
        check("the words in F1 whatever font the caller passes", o.texts[1] and o.texts[1].f == "F1", o.texts[1] and o.texts[1].f)
        check("the words in the category row's ink (T.toneLo)", o.texts[1] and same(o.texts[1].c, T.toneLo))
        check("the triangle in the same ink", o.tri and same(o.tri.c, T.toneLo))
        check("the content line under it", o.line == true)
        o = draw("Traits", 4, false, false, nil, true)
        check("the count inline, in the same ink", #o.texts == 2 and o.texts[2].s == "(4)" and same(o.texts[2].c, T.toneLo))
        o = draw("Hair", nil, true, false, nil, nil, 0, 20, true)
        check("noArrow: the same line with no triangle", o.tris == 0 and o.texts[1] and same(o.texts[1].c, T.toneLo))
        o = draw("Skin temperature", nil, true, true)
        local hov = false
        for _, e in ipairs(LOG) do if e.k == "rect" then hov = true end end
        check("hover: the hover wash over it", hov)
    end
    ZeD = saveZ
end

-- ---------------------------------------------------------------------------
section("FOCUS and MOODLES (verify)")
-- ---------------------------------------------------------------------------
do
    local fp = readFile(CDIR .. "ZeD_FocusPaint.lua") or ""
    check("FocusPaint: the wash style is the 0.55 accent fill, its words textOnFocus",
        fp:find("local WASH_A   = 0.55", 1, true) ~= nil and fp:find("fillShape(p, x, y, w, h, T.accent, WASH_A, rounded)\n        return true", 1, true) ~= nil)
    local mo = readFile(CDIR .. "ZeD_Moodles.lua") or ""
    local hi = cutFn(mo, "function ZeD_MoodleLayer:_hoverIndex()") or ""
    check("Moodles: a moodle answers the pointer only while the layer holds it (isMouseOver)",
        hi:find("if not self:isMouseOver() then return nil end", 1, true) ~= nil)
    check("Moodles: the layer does not raise itself", mo:find("bringToTop", 1, true) == nil)
end

print("theme_look_core_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
