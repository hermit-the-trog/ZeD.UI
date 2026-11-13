-- ZeDUI/tools/qa/fix_shared_misc_sim.lua  (Nov 12 2026, review fixes: the shared pieces), checked on the real pieces of
-- the changed files with no game running.
--   BUTTON   a grayed button is the plain keycap whatever its variant (Molecules drawButton): one line in borderS, the
--            default ink, at the disabled alpha; no accent double line (it read as the focused default), no red, no
--            pulse. An enabled default keeps its double accent line; a red default answer keeps its double red line.
--   CASE     (from zedqa_button_case_game.lua) button words go through ZeD.btnCase (keepCase as given); the card's
--            verbs, verb strip and flags, tabs and tags reach the case rule; no in-game tab opts out
--   HEADING  a container's heading reads the game's capacity for the character (InventoryRenderer.capacityOf): the
--            character's own inventory its carry limit, a bag its capacity with Organized / Disorganized applied;
--            the Character and World windows' headings and the side-by-side columns all ask it
--   PROFESSION  Foraging's profession modifier is the game's name for the profession ("Unemployed"), not its id
--   FURNITURE   the selected row's Target button takes the row's ink (an accent ring on the accent wash read poorly);
--            the chip at the cursor's tile stays clear of the game's version mark in the lower right corner: its
--            version line and the lines it stacks above it (the position line under -debug, one per cheat on)
--   LISTS    the Journal's empty loadout and outfit lines name the item's menu, not a mouse button, in all 28
--            languages, each with the menu option's own words, a context row and a machine-draft note
-- Run from the repo root:  lua51 ZeDUI/tools/qa/fix_shared_misc_sim.lua
-- It prints FAIL lines and a last line "fix_shared_misc_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]fix_shared_misc_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

local function readFile(rel)
    local f = io.open(ROOT .. rel, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end
local function srcOf(rel) return readFile("42/media/lua/client/ZeD/" .. rel) or "" end

-- a top-level function of a file, from its opening text to its first unindented "end"
local function cutFn(src, open)
    local a = src:find(open, 1, true)
    if not a then return nil end
    local e = src:find("\nend\n", a, true)
    if not e then return nil end
    return src:sub(a, e + 4)
end

local function col(r, g, b) return { r = r, g = g, b = b, a = 1 } end

-- ---------------------------------------------------------------------------
section("BUTTON: a grayed button is the plain keycap")
-- ---------------------------------------------------------------------------
do
    local LOG = {}
    ZeD = {
        T = {
            px = function(n) return n end, fontF3 = "F3", buttonH = 24, disabledAlpha = 0.4,
            accent = col(0, 0.6, 0.6), accentText = col(0, 0.8, 0.8), danger = col(1, 0, 0), dangerText = col(1, 0.3, 0.3),
            borderS = col(0.3, 0.3, 0.3), text = col(1, 1, 1), textOnFocus = col(0, 0, 0), hover = col(1, 1, 1),
            dangerPulseMin = 0.1, dangerPulseMax = 0.3,
        },
        TM = { MeasureStringX = function(_, f, s) return #tostring(s) * 8 end, getFontHeight = function() return 14 end },
        Atoms = {
            fillRounded = function(_, x, y, w, h, r, g, b, a) LOG[#LOG + 1] = { k = "fill", r = r, a = a } end,
            borderRounded = function(_, x, y, w, h, r, g, b, a) LOG[#LOG + 1] = { k = "line1", r = r, g = g, b = b, a = a } end,
            borderDoubleRounded = function(_, x, y, w, h, r, g, b, a) LOG[#LOG + 1] = { k = "line2", r = r, g = g, b = b, a = a } end,
        },
        Molecules = {},
    }
    ZeD.btnCase = function(s) return s end
    getTimestampMs = function() return 1000 end
    local panel = { drawText = function(_, s, x, y, r, g, b, a) LOG[#LOG + 1] = { k = "text", s = s, r = r, g = g, b = b, a = a } end }
    local piece = cutFn(srcOf("Molecules.lua"), "function ZeD.Molecules.drawButton(")
    local chunk, err = piece and loadstring("local NO_OPTS = {}\nlocal function focusOptsOf(o) return o.focus end\n"
        .. "local function giveHelp() end\n" .. piece, "=Molecules.lua (cut)")
    check("drawButton cut and loads", chunk ~= nil, err)
    if chunk then
        chunk()
        local T = ZeD.T
        local function draw(variant, opts)
            LOG = {}
            ZeD.Molecules.drawButton(panel, 0, 0, 100, 24, "Craft", variant, false, nil, opts)
            local out = { fills = 0 }
            for _, e in ipairs(LOG) do
                if e.k == "line1" or e.k == "line2" then out.line = e end
                if e.k == "text" then out.text = e end
                if e.k == "fill" then out.fills = out.fills + 1 end
            end
            return out
        end
        local function same(c, t) return c and t and c.r == t.r and c.g == t.g and c.b == t.b end
        local on = draw("primary", {})
        check("an enabled default: the double line in the accent", on.line and on.line.k == "line2" and same(on.line, T.accent))
        local off = draw("primary", { disabled = true })
        check("a grayed default: one line, not two", off.line and off.line.k == "line1", off.line and off.line.k)
        check("a grayed default: the line in borderS, not the accent", same(off.line, T.borderS))
        check("a grayed default: the words in the default ink, dimmed", same(off.text, T.text) and off.text.a == T.disabledAlpha)
        check("a grayed default: the line dimmed", off.line and off.line.a == T.disabledAlpha)
        local plain = draw("default", { disabled = true })
        check("a grayed plain button: the same keycap", plain.line and plain.line.k == "line1" and same(plain.line, T.borderS))
        local red = draw("danger", { disabled = true, default = true })
        check("a grayed red default: the plain keycap, no red, no pulse", red.line and red.line.k == "line1"
            and same(red.line, T.borderS) and red.fills == 0 and same(red.text, T.text))
        local redOn = draw("danger", { default = true })
        check("an enabled red default keeps its double red line and its pulse", redOn.line and redOn.line.k == "line2"
            and same(redOn.line, T.danger) and redOn.fills == 1)
        -- (A5) a default button on a row in the selected wash takes the row's ink: its outline from colors.border
        LOG = {}
        ZeD.Molecules.drawButton(panel, 0, 0, 100, 24, "Target", "primary", false, { text = T.text, border = T.text }, {})
        local ln, tx = nil, nil
        for _, e in ipairs(LOG) do
            if e.k == "line1" or e.k == "line2" then ln = e end
            if e.k == "text" then tx = e end
        end
        check("colors.border: the default's double line in the row's ink, its words too", ln and ln.k == "line2"
            and same(ln, T.text) and same(tx, T.text))
        -- CASE (from zedqa_button_case_game.lua, Nov 12 2026): a button's words go through ZeD.btnCase, a key's name
        -- passed with colors.keepCase as it is
        ZeD.btnCase = function(s) return "bc(" .. tostring(s) .. ")" end
        local function words(colors)
            LOG = {}
            ZeD.Molecules.drawButton(panel, 0, 0, 100, 24, "WASH", "default", false, colors, {})
            for _, e in ipairs(LOG) do if e.k == "text" then return e.s end end
        end
        check("CASE a button's words go through ZeD.btnCase", words(nil) == "bc(WASH)", words(nil))
        check("CASE a key's name (colors.keepCase) is drawn as given", words({ keepCase = true }) == "WASH", words({ keepCase = true }))
        ZeD.btnCase = function(s) return s end
    end
end

-- ---------------------------------------------------------------------------
section("CASE: the in-game windows' button words reach the case rule")
-- ---------------------------------------------------------------------------
-- (from zedqa_button_case_game.lua, which only took pictures) the item card's header verbs, its Wash / Repair / Pad
-- verb strip and its flag chips, the tabs and tags (Health exercise and Thermal view pickers, Animals footer, Foraging
-- strip, Craft and Vehicle tabs draw through these) put their words through ZeD.btnCase or ZeD.textCase; none of the
-- in-game tabs' own button calls opts out with keepCase but the game's own words on Fishing's and Foraging's chips
do
    local M = srcOf("Molecules.lua")
    local function inFn(open, needle)
        local f = cutFn(M, open)
        return f ~= nil and f:find(needle, 1, true) ~= nil
    end
    check("CASE the card header's verbs", M:find('local labelStr = ZeD.btnCase(v.label or "")   -- sentence case (draw only', 1, true) ~= nil)
    check("CASE the card's verb strip (Wash, Repair, Pad)", inFn("function ZeD.Molecules.drawCardVerbStrip(", "ZeD.btnCase(v.label"))
    check("CASE the card's flag strip", inFn("function ZeD.Molecules.drawCardFlagStrip(", "A.textCase("))
    check("CASE a tab's words", inFn("function ZeD.Molecules.drawTab(", "text = A.textCase(text)"))
    check("CASE a button's natural width measures the words as drawn", inFn("function ZeD.Molecules.buttonW(", "ZeD.btnCase(text"))
    local atoms = srcOf("Atoms.lua")
    check("CASE a tag's words (unless keepCase)", atoms:find("if not opts.keepCase then s = textCase(s) end", 1, true) ~= nil)
    local opted = {}
    for _, f in ipairs({ "HealthTab.lua", "ThermalTab.lua", "AnimalsTab.lua", "CraftingTab.lua", "CraftingCore.lua",
                         "MechanicsTab.lua", "ItemCardOrganism.lua", "ZeD_WorldWindow.lua", "ZeD_CharacterWindow.lua" }) do
        if srcOf(f):find("keepCase", 1, true) then opted[#opted + 1] = f end
    end
    check("CASE no in-game tab's button opts out of the case rule", #opted == 0, table.concat(opted, ", "))
end

-- ---------------------------------------------------------------------------
section("HEADING: a container's capacity is the game's, for the character")
-- ---------------------------------------------------------------------------
do
    ZeD = { InventoryRenderer = {} }
    local piece = cutFn(srcOf("InventoryRenderer.lua"), "function ZeD.InventoryRenderer.capacityOf(")
    local chunk, err = piece and loadstring(piece, "=InventoryRenderer.lua (cut)")
    check("capacityOf cut and loads", chunk ~= nil, err)
    if chunk then
        chunk()
        local capOf = ZeD.InventoryRenderer.capacityOf
        local main = { getMaxWeight = function() return 22 end, getEffectiveCapacity = function() return 50 end }
        local disorganized = { getInventory = function() return main end }
        local bag = { getMaxWeight = function() return 28 end,
                      getEffectiveCapacity = function(_, chr) return chr == disorganized and 19 or 28 end }
        check("the character's own inventory: the weight it can carry", capOf(main, disorganized) == 22)
        check("a bag: its capacity for this character (Disorganized: 19 of 28)", capOf(bag, disorganized) == 19, capOf(bag, disorganized))
        check("no character: the container's own figure", capOf(bag, nil) == 28)
        check("no container: 0", capOf(nil, disorganized) == 0)
    end
    local ir, cw, ww = srcOf("InventoryRenderer.lua"), srcOf("ZeD_CharacterWindow.lua"), srcOf("ZeD_WorldWindow.lua")
    check("the side-by-side columns' headings ask it", ir:find("local capacity = ZeD.InventoryRenderer.capacityOf(inv, self._playerObj)", 1, true) ~= nil)
    check("the Character window's heading asks it", cw:find("round(ZeD.InventoryRenderer.capacityOf(cInv, win._playerObj), 1)", 1, true) ~= nil)
    check("the World window's heading asks it", ww:find("round(ZeD.InventoryRenderer.capacityOf(cInv, win._playerObj), 1)", 1, true) ~= nil)
    check("no heading reads a bare getMaxWeight any more", not ir:find("inv:getMaxWeight() or 0", 1, true)
        and not cw:find("cInv:getMaxWeight()", 1, true) and not ww:find("cInv:getMaxWeight()", 1, true))
end

-- ---------------------------------------------------------------------------
section("PROFESSION: Foraging names the profession as the game does")
-- ---------------------------------------------------------------------------
do
    ZeD = { tr = function(k) return k end }
    local prof = { getName = function() return "unemployed" end }
    local P = { getDescriptor = function() return { getCharacterProfession = function() return prof end } end }
    ISSearchManager = { players = { [P] = { modifiers = {} } } }
    forageSystem = { skillDefs = { trait = {}, occupation = { unemployed = { name = "unemployed", visionBonus = 0.5 } } } }
    CharacterProfessionDefinition = { getCharacterProfessionDefinition = function(p)
        return p == prof and { getUIName = function() return "Unemployed" end } or nil
    end }
    local piece = cutFn(srcOf("ForagingTab.lua"), "local function getModifiers(")
    local chunk, err = piece and loadstring("local TRAIT_FRIENDLY = {}\n" .. piece .. "return getModifiers\n", "=ForagingTab.lua (cut)")
    check("getModifiers cut and loads", chunk ~= nil, err)
    if chunk then
        local mods = chunk()({ _playerObj = P })
        local m = mods[1]
        check("the profession's modifier reads the game's name for it (Unemployed, not the id)", m and m.label == "Unemployed",
            m and m.label)
        check("its bonus as before", m and m.value == "+0.5")
    end
    ISSearchManager, forageSystem, CharacterProfessionDefinition = nil, nil, nil
end

-- ---------------------------------------------------------------------------
section("FURNITURE: the selected row's Target button, the chip clear of the version line")
-- ---------------------------------------------------------------------------
do
    local T = { px = function(n) return n end, buttonH = 24, selectionA = 0.3, accent = col(0, 0.6, 0.6), text = col(1, 1, 1),
                textDim = col(0.5, 0.5, 0.5), border = col(0.2, 0.2, 0.2), fontF2 = "F2", fontF5 = "F5", hair = 1 }
    local calls = {}
    ZeD = {
        T = T,
        TM = { getFontHeight = function() return 12 end, MeasureStringX = function(_, f, s) return #tostring(s) * 8 end },
        Molecules = {
            buttonW = function(s) return #s * 8 + 20 end,
            drawButton = function(_, x, y, w, h, label, variant, pressed, colors, opts)
                calls[#calls + 1] = { variant = variant, colors = colors, opts = opts }
            end,
        },
        Atoms = { mouseIn = function() return false end },
        CraftingCore = { truncText = function(s) return s end },
    }
    local panel = { drawRect = function() end, drawTextureScaledAspect = function() end, drawText = function() end }
    local src = srcOf("FurnitureTab.lua")
    local piece = cutFn(src, "local function drawRow(")
    local chunk, err = piece and loadstring("local ROW_H = 30\nlocal _rowInk = {}\nlocal function col(c) return c.r, c.g, c.b end\n"
        .. "local function stamp() end\n" .. piece .. "return drawRow\n", "=FurnitureTab.lua (cut)")
    check("drawRow cut and loads", chunk ~= nil, err)
    if chunk then
        local drawRow = chunk()
        local s = { gpId = nil }
        drawRow(panel, s, 0, 0, 300, "row1", nil, "Wooden Chair", nil, "Target", true, function() end, true)
        local c = calls[#calls]
        check("the selected row's Target: the default, in the row's ink (words and outline)", c and c.variant == "primary"
            and c.colors and c.colors.text == T.text and c.colors.border == T.text)
        drawRow(panel, s, 0, 0, 300, "row2", nil, "Table", nil, "Pick up", false, function() end, true)
        c = calls[#calls]
        check("a row that is not selected: the plain button, its own colors", c and c.variant == "default" and c.colors == nil)
        s.gpId = "row1"
        drawRow(panel, s, 0, 0, 300, "row1", nil, "Wooden Chair", nil, "Target", true, function() end, true)
        c = calls[#calls]
        check("the controller's focus on it keeps the focus ink", c and c.colors == nil)
        drawRow(panel, { gpId = nil }, 0, 0, 300, "row1", nil, "Wooden Chair", nil, "Target", true, function() end, false)
        c = calls[#calls]
        check("a grayed Target stays the plain keycap", c and c.colors == nil and c.opts.disabled == true)
    end
    -- the chip at the cursor's tile, clear of the game's version line (lower right corner)
    local FT = {}
    local p1, p2 = cutFn(src, "function FT.chipSpot("), cutFn(src, "function FT.versionBox(")
    local p3, p4, p5 = cutFn(src, "function FT.versionLines("), cutFn(src, "function FT.versionStackW("),
        cutFn(src, "function FT.versionReach(")
    local chunk2, err2 = (p1 and p2 and p3 and p4 and p5)
        and loadstring("local FT = ...\n" .. p1 .. p2 .. p3 .. p4 .. p5, "=FurnitureTab.lua (cut)")
    check("chipSpot and the version mark's room cut and load", chunk2 ~= nil, err2)
    if chunk2 then
        chunk2(FT)
        UIFont = { Small = "S", NewSmall = "NS" }
        getTextManager = function()
            return { MeasureStringX = function(_, f, s) return #s * 7 end, getFontHeight = function() return 14 end }
        end
        getCore = function() return { getVersion = function() return "42.22.2 3d39148846" end, getBulletVersion = function() return "" end } end
        local vw, vh = FT.versionBox()
        local words = #("42.22.2 3d39148846 pzBullet()") * 7
        check("the version line's room: its words + 10, 10 from the corner; its line + 6, 10 from the foot",
            vw == math.max(100, words + 10) + 10 and vh == 14 + 6 + 10, vw .. "x" .. vh)
        local sw, sh = 1920, 1080
        -- on the version line: lifted clear of it
        local x, y = FT.chipSpot(1750, 1050, 150, 20, sw, sh, vw, vh, 0, 0)
        check("a chip that would sit on the version line goes above it", x == 1750 and y + 20 <= sh - vh, y)
        -- anywhere else: where it was
        x, y = FT.chipSpot(600, 400, 150, 20, sw, sh, vw, vh, 0, 0)
        check("elsewhere the chip stays beside its tile", x == 600 and y == 400)
        x, y = FT.chipSpot(100, 1050, 150, 20, sw, sh, vw, vh, 0, 0)
        check("at the foot's left (no version line there) it stays", y == 1050)
        -- over the pointer: above it, as before
        x, y = FT.chipSpot(600, 400, 150, 20, sw, sh, vw, vh, 650, 410)
        check("a chip that would cover the pointer goes above it", y == 400 - 20 - 16, y)
        check("the chip's prerender places it through chipSpot",
            src:find("x, y = FT.chipSpot(x, y, w, h, core:getScreenWidth(), core:getScreenHeight(), vw, vh, getMouseX(), getMouseY())", 1, true) ~= nil)
        -- the lines the version mark stacks above its version line: the position line under -debug, one per cheat
        local now, debugOn, cheatsOn = 0, false, {}
        local CHEATS = { "God", "Invisible", "NoClip" }
        getTimestampMs = function() return now end
        isClient = function() return false end
        isDebugEnabled = function() return debugOn end
        getSandboxOptions = function() return { isUnstableScriptNameSpam = function() return false end } end
        getCheatTypes = function()
            return { size = function() return #CHEATS end,
                     get = function(_, i) return { getTooltip = function() return CHEATS[i + 1] end, _n = CHEATS[i + 1] } end }
        end
        getText = function(k) return k end
        -- isCheatSet is handed the list's entry: the stub keys on its name
        getSpecificPlayer = function() return { isCheatSet = function(_, c) return cheatsOn[c._n] == true end } end
        check("no debug, no cheats: no lines above the version line", FT.versionLines() == 0 and select(2, FT.versionReach(0)) == vh)
        debugOn, now = true, 1000
        local n = FT.versionLines()
        check("under -debug: the position line", n == 1, n)
        local rw, rh = FT.versionReach(n)
        check("the debug line's room: one NewSmall line + 3 above the version line", rh == vh + 14 + 3, rh)
        local posW = #("x: 00000 , y: 00000, z: -00 ; 0000x0000@000") * 7 + 10
        check("the debug line's room: as wide as the position line at its longest", rw == math.max(vw, posW), rw)
        -- the QA bridge's case: a chip beside a tile under the position line, clear of the version line alone
        local cy = sh - vh - 20 - 6
        x, y = FT.chipSpot(sw - posW + 20, cy, 150, 20, sw, sh, rw, rh, 0, 0)
        check("a chip that would sit on the debug position line goes above it", y + 20 <= sh - rh, y)
        x, y = FT.chipSpot(sw - posW + 20, cy, 150, 20, sw, sh, vw, vh, 0, 0)
        check("(the version line alone would have left it on the position line)", y == cy and y + 20 > sh - rh, y)
        cheatsOn.God, cheatsOn.NoClip, now = true, true, 1200
        check("recounted at most every half second", FT.versionLines() == 1)
        now = 1600
        n = FT.versionLines()
        check("under -debug with two cheats on: three lines", n == 3, n)
        rw, rh = FT.versionReach(n)
        check("three lines' room", rh == vh + 3 * (14 + 3), rh)
        check("the chip counts the lines each frame through versionReach",
            src:find("local vw, vh = FT.versionReach(FT.versionLines())", 1, true) ~= nil)
        getTimestampMs, getSpecificPlayer, isClient, isDebugEnabled, getSandboxOptions, getCheatTypes, getText =
            nil, nil, nil, nil, nil, nil, nil
        UIFont, getTextManager, getCore = nil, nil, nil
    end
end

-- ---------------------------------------------------------------------------
section("LISTS: the empty lines name the item's menu, not a mouse button")
-- ---------------------------------------------------------------------------
do
    local MOUSE = { "RMB", "PPM", "ПКМ", "右鍵", "右键", "右クリック", "우클릭", "คลิกขวา", "sağ tık", "clic droit", "Rechtsklick" }
    local langs = { "AR", "CA", "CH", "CN", "CS", "DA", "DE", "EN", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT", "JP",
                    "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
    local bad, missing, noOption = {}, {}, {}
    local function value(s, key) return s:match('"' .. key .. '"%s*:%s*"([^"]*)"') end
    for _, L in ipairs(langs) do
        local s = readFile("42/media/lua/shared/Translate/" .. L .. "/UI.json")
        if not s then missing[#missing + 1] = L else
            for _, pair in ipairs({ { "UI_ZeD_Lists_EmptySec", "UI_ZeD_Lists_SaveToLoadout" }, { "UI_ZeD_Lists_EmptyWorn", "UI_ZeD_Lists_SaveToOutfit" } }) do
                local v, opt = value(s, pair[1]), value(s, pair[2])
                if not v then missing[#missing + 1] = L .. ":" .. pair[1] else
                    for _, m in ipairs(MOUSE) do if v:find(m, 1, true) then bad[#bad + 1] = L .. ":" .. pair[1] end end
                    if not (opt and v:find(opt, 1, true)) then noOption[#noOption + 1] = L .. ":" .. pair[1] end
                end
            end
        end
    end
    check("all 28 languages have both lines", #missing == 0, table.concat(missing, " "))
    check("no line names a mouse button (a controller opens the item's menu too)", #bad == 0, table.concat(bad, " "))
    check("each names the menu's option as the language's menu writes it", #noOption == 0, table.concat(noOption, " "))
    local ctx = readFile("ZeDUI/i18n/UI_ZeD.context.md") or ""
    check("the context file has a row for each", ctx:find("`UI_ZeD_Lists_EmptySec`", 1, true) ~= nil and ctx:find("`UI_ZeD_Lists_EmptyWorn`", 1, true) ~= nil)
    local notes = 0
    for _, L in ipairs(langs) do
        if L ~= "EN" then
            local n = readFile("ZeDUI/i18n/mt_notes/" .. L .. ".txt") or ""
            if n:find("UI_ZeD_Lists_EmptySec and UI_ZeD_Lists_EmptyWorn reworded", 1, true) then notes = notes + 1 end
        end
    end
    check("each machine draft is labeled in its language's notes", notes == 27, notes)
end

print(string.format("fix_shared_misc_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
