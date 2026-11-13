-- ZeDUI/tools/qa/tab_fill_sim.lua  (Nov 11 2026, Build): the tab fill (zed_tab_fill_v1, approved) checked with no game
-- running, on the real ZeD_TabFill.lua and the real pieces of the tabs that use it.
--   KIT      a row measures what it draws (wrapped words, never cut), the fold head folds its rows away, a press runs the
--            row's own deed, the controller's stops are clipped to the view, the scroll-follow brings a stop into view,
--            the scale word picks vanilla's low / middle / high word, and a frame makes no new zone tables.
--   HEALTH   the four blocks (Moodles, Fitness, Regularity, Muscle Strain) from a stand-in read: rows, the picked exercise
--            in the wash, a Regularity row picks the exercise for the band, the measure equals the draw.
--   SOURCE   what the approval asked that a stand-in cannot show: no gradient left on the Thermal tab, the Loadouts
--            switch drawn as radio buttons, the fill throttled (read on a clock, not every frame), the strings keyed.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/tab_fill_sim.lua
-- It prints FAIL lines and a last line "tab_fill_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]tab_fill_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function noop() end
local function readFile(rel)
    local f = io.open(ROOT .. rel, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end

-- ---------------------------------------------------------------------------
-- stand-ins: tokens at 1x, a text manager 7 px a letter, a panel that counts its draws
-- ---------------------------------------------------------------------------
require = function() return nil end
getTimestampMs = function() return 100000 end
getText = function(k, a) if a ~= nil then return k .. "(" .. tostring(a) .. ")" end return k end
getSoundManager = function() return { playUISound = noop } end
local col = function() return { r = 1, g = 1, b = 1, a = 1 } end
local FH = { F1 = 14, F2 = 19, F3 = 16 }
local MOUSE = { x = -1, y = -1 }
local FOCUS = nil
ZeD = {
    T = setmetatable({ px = function(n) return n end, fontF1 = "F1", fontF2 = "F2", fontF3 = "F3", selectionA = 0.3,
                       sp = { scrollbarW = 10 } }, { __index = function(t, k) local c = col(); rawset(t, k, c); return c end }),
    TM = { getFontHeight = function(_, f) return FH[f] or 19 end, MeasureStringX = function(_, f, s) return #tostring(s) * 7 end },
    tr = function(k, a, b) return k .. (a ~= nil and ("(" .. tostring(a) .. (b ~= nil and ("," .. tostring(b)) or "") .. ")") or "") end,
    Help = { set = noop },
    Focus = { mark = function() return true end },
    Input = { Focus = { isFocused = function(_, _, id) return id == FOCUS end } },
}
-- the atoms the kit uses: wrapText splits at spaces to the width
ZeD.Atoms = {
    FILL_SEGS = 10,
    fillBarMinW = function() return 40 end, rowBarW = function() return 60 end, fillBarCompactH = function() return 8 end,
    fillSegsLit = function(v, n) n = n or 10; if v <= 0 then return 0 end; if v >= 1 then return n end; return math.floor(v * n + 1e-6) end,
    drawSegFill = function(p) p.n = p.n + 1; return false end,
    drawStatusDot = function(p) p.n = p.n + 1 end, drawStatusHollow = function(p) p.n = p.n + 1 end,
    mouseIn = function(_, x, y, w, h) return MOUSE.x >= x and MOUSE.x < x + w and MOUSE.y >= y and MOUSE.y < y + h end,
    statusColor = function() return col() end,
    wrapText = function(text, font, w)
        local out, line = {}, ""
        for word in tostring(text):gmatch("%S+") do
            local try = (line == "") and word or (line .. " " .. word)
            if #try * 7 > w and line ~= "" then out[#out + 1] = line; line = word else line = try end
        end
        if line ~= "" or #out == 0 then out[#out + 1] = line end
        return out
    end,
    truncateText = function(s, font, w)
        s = tostring(s)
        if #s * 7 <= w then return s end
        local out = s
        while #out > 0 and #(out .. "...") * 7 > w do out = out:sub(1, -2) end
        return out .. "..."
    end,
}
-- (a fold head writes down its words: the radio's Channels head is checked by them)
ZeD.Molecules = { drawCategoryRow = function(p, x, y, w, label)
    p.n = p.n + 1
    p.heads = p.heads or {}
    p.heads[#p.heads + 1] = label
    return 20
end }
local function panel()
    local p = { n = 0, texts = {} }
    function p:drawRect() self.n = self.n + 1 end
    function p:drawText(s) self.n = self.n + 1; self.texts[#self.texts + 1] = s end
    return p
end

local okLoad, errLoad = pcall(dofile, ROOT .. "42/media/lua/client/ZeD/ZeD_TabFill.lua")
check("ZeD_TabFill.lua loads", okLoad, errLoad)
local F = ZeD.TabFill

section("KIT")
if okLoad then
    local win = {}
    F.begin(win, "t")
    local r = { id = "r1", label = "A long label that has to wrap over more than one line in a narrow column", sub = "under it", value = "64%", bar = 0.64 }
    local mh = F.row(nil, win, "t", r, 0, 0, 220)
    local p = panel()
    local dh = F.row(p, win, "t", r, 0, 0, 220)
    check("a row measures what it draws", mh == dh, mh .. " vs " .. dh)
    local cut = false
    for _, s in ipairs(p.texts) do if s:find("%.%.%.") then cut = true end end
    check("the words wrap, never cut", not cut and #p.texts >= 4, #p.texts)
    check("a long label takes more than one line", mh > 24, mh)
    check("a row with an id is a zone", #F.zones(win, "t") == 1)
    check("a row with no deed is a read-only stop", F.zones(win, "t")[1].read == true)

    -- the block and its fold
    F.begin(win, "t")
    local rows = { { id = "a", label = "One" }, { id = "b", label = "Two", fn = function() win.pressed = true end } }
    local open = F.block(panel(), win, "t", "blk", 0, 0, 300, "Block", 2, rows)
    check("an open block is its head and its rows", open > 20 + 24, open)
    local zs = F.zones(win, "t")
    check("head and two rows stamped", #zs == 3, #zs)
    check("a press on a row runs its deed", F.onClick(win, "t", 10, zs[3].y + 2) and win.pressed == true)
    check("a press on the head folds the block", F.onClick(win, "t", 10, 2) and F.folded(win, "t", "blk"))
    F.begin(win, "t")
    local shut = F.block(panel(), win, "t", "blk", 0, 0, 300, "Block", 2, rows)
    check("a folded block is its head alone", shut == 24, shut)
    check("an empty block draws nothing", F.block(panel(), win, "t", "none", 0, 0, 300, "None", 0, {}) == 0)

    -- the stops: clipped to the view, out of view no stop
    F.begin(win, "t")
    F.head(nil, win, "t", "blk", 0, 0, 300, "Block", 2)
    local y = 0
    for i = 1, 6 do
        local z = F.zone(win, "t", "z" .. i)
        z.x, z.y, z.w, z.h, z.fn = 0, y, 300, 30, noop
        y = y + 30
    end
    local st = F.focusables(win, "t", { x = 0, y = 40, w = 300, h = 80 })
    check("only the stops in view", #st == 3, #st)
    check("a stop keeps its whole rect", st[1].fullY == 30 and st[1].y == 40 and st[1].fillStop)
    check("the follow scrolls a stop below the view into it", (F.follow(win, "t", "z6", 40, 80, 0, 200) or 0) > 0)
    check("the follow leaves a stop in view", F.follow(win, "t", "z3", 40, 80, 0, 200) == nil)
    -- no new zone tables from frame to frame
    local first = F.zone(win, "t", "z1")
    F.begin(win, "t")
    -- (review, Nov 12: the Notebooks page asks for the follow after its frame has begun, as the Journal begins every
    -- page's frame first; the follow looked in this frame's empty list and the pad never scrolled the page)
    check("the follow reads last frame's zones once the frame has begun", (F.follow(win, "t", "z6", 40, 80, 0, 200) or 0) > 0)
    check("a zone's table is kept by its id", F.zone(win, "t", "z1") == first)

    -- a row that asks for one line (a radio's channel names): cut with "..." only where it does not fit
    F.begin(win, "t")
    local long = { id = "c1", cut = true, label = "1 | Automated Emergency Broadcast System", value = "98.4" }
    local cmh = F.row(nil, win, "t", long, 0, 0, 200)
    local cp = panel()
    local cdh = F.row(cp, win, "t", long, 0, 0, 200)
    check("a one-line row measures what it draws", cmh == cdh, cmh .. " vs " .. cdh)
    check("a one-line row is one line tall", cdh == 4 * 2 + FH.F2, cdh)
    check("a long name on one line is cut with ...", cp.texts[1] and cp.texts[1]:sub(-3) == "..." and #cp.texts == 2,
        tostring(cp.texts[1]))
    check("its words are kept whole on the row", long.label == "1 | Automated Emergency Broadcast System")
    local short = { id = "c2", cut = true, label = "2 | KnoxTalk", value = "101.2" }
    local sp = panel()
    F.row(sp, win, "t", short, 0, 0, 200)
    check("a name that fits is not cut", sp.texts[1] == "2 | KnoxTalk", tostring(sp.texts[1]))

    check("scale word: low", F.scaleWord(0.1, "lo", "mid", "hi") == "lo")
    check("scale word: middle", F.scaleWord(0.5, "lo", "mid", "hi") == "mid")
    check("scale word: high", F.scaleWord(0.9, "lo", "mid", "hi") == "hi")
    check("scale word, no middle", F.scaleWord(0.4, "dry", false, "soaked") == "dry" and F.scaleWord(0.6, "dry", false, "soaked") == "soaked")
end

section("HEALTH")
do
    local src = readFile("42/media/lua/client/ZeD/HealthTab.lua") or ""
    -- the fill's pieces, cut from the file (to the end of renderFill) and run on stand-ins
    local a = src:find("-- the rows of the four blocks, built once per read", 1, true)
    local b = src:find("ZeD.HealthTab._fillOpts = {}", 1, true)
    check("the Health fill is in the file", a and b)
    if a and b and okLoad then
        ZeD.HealthTab = { selectedExercise = function(w) return w._sel or "squats" end,
                          closeMenu = function(w, id) w._sel = id; w._healthReturnToMenu = true end }
        ZeD.partLabel = function(n) return n end
        local chunk, err = loadstring(src:sub(a, (src:find("\n", b, true))), "=HealthTab.lua (cut)")
        check("the Health fill cuts and loads", chunk ~= nil, err)
        if chunk then
            chunk()
            local win = { _healthView = { x = 0, y = 0, w = 480, h = 2000 } }
            win._healthFill = {
                moodles = { { name = "Peckish", desc = "Could do with a bite to eat.", level = 1, gbn = 2 } },
                fitness = 5, strength = 6,
                exercises = { { id = "squats", name = "Squats", have = true, reg = 0.3 },
                              { id = "barbellcurl", name = "Barbell Curls", need = "(Requires Barbell)", have = false, reg = 0 } },
                strain = { { name = "Left Thigh", minor = true } },
            }
            F.begin(win, "health")
            local mh = ZeD.HealthTab.renderFill(nil, win, 0, 0, 464)
            local dh = ZeD.HealthTab.renderFill(panel(), win, 0, 0, 464)
            check("the four blocks measure what they draw", mh == dh, mh .. " vs " .. dh)
            local ids = {}
            for _, z in ipairs(F.zones(win, "health")) do ids[z.id] = z end
            check("a moodle row", ids["fill:health:moodle:1"] ~= nil)
            check("Fitness and Strength rows", ids["fill:health:fit"] ~= nil and ids["fill:health:str"] ~= nil)
            check("a row per exercise", ids["fill:health:exe:squats"] ~= nil and ids["fill:health:exe:barbellcurl"] ~= nil)
            check("a strain row", ids["fill:health:strain:1"] ~= nil)
            check("four fold heads", ids["fill:health:head:moodles"] and ids["fill:health:head:strain"] and true)
            local d = win._healthFill
            check("the picked exercise carries the wash", d.rows.regularity[1].sel == true and not d.rows.regularity[2].sel)
            ids["fill:health:exe:barbellcurl"].fn()
            check("a Regularity row picks the exercise, the focus stays", win._sel == "barbellcurl" and win._healthReturnToMenu == nil)
            check("an exercise that needs an item says so, dimmed", d.rows.regularity[2].sub == "(Requires Barbell)" and d.rows.regularity[2].dim)
            check("moodle and strain rows only read", ids["fill:health:moodle:1"].read and ids["fill:health:strain:1"].read)
        end
    end
    -- the read itself (review, Nov 12): "(Requires Barbell)" only while the barbell is missing, as vanilla's fitness
    -- window says it; a carried barbell's row had the note under it, undimmed
    local ga = src:find("-- the moodles that are on, in vanilla's order", 1, true)
    local gb = src:find("-- the rows of the four blocks, built once per read", 1, true)
    check("the Health read is in the file", ga and gb)
    if ga and gb and okLoad then
        ZeD.HealthTab = ZeD.HealthTab or {}
        ZeD.HealthTab.exerciseLabel = function(id) return id end
        EXERCISES = { "squats", "barbellcurl", "bicepscurl" }
        FitnessExercises = { exercisesType = { squats = {}, barbellcurl = { item = "Base.BarBell" }, bicepscurl = { item = "Base.DumbBell" } } }
        local HAVE = { squats = true, barbellcurl = true, bicepscurl = false }
        isExerciseAvailable = function(_, id) return HAVE[id] == true end
        readRegularity = function() return 0.25 end
        getItemDisplayName = function(ft) return ft == "Base.BarBell" and "Barbell" or "Dumbbell" end
        Perks = { Fitness = "Fitness", Strength = "Strength" }
        local chunk, err = loadstring(src:sub(ga, gb - 1), "=HealthTab.lua (the read)")
        check("the Health read cuts and loads", chunk ~= nil, err)
        if chunk then
            chunk()
            local p = { getPerkLevel = function() return 3 end, getMoodles = function() return nil end,
                        getBodyDamage = function() return nil end }
            local d = ZeD.HealthTab.gatherFill(p)
            local ex = {}
            for _, e in ipairs(d.exercises or {}) do ex[e.id] = e end
            check("a carried item: no (Requires X) under its exercise", ex.barbellcurl and ex.barbellcurl.have == true
                and ex.barbellcurl.need == nil, ex.barbellcurl and tostring(ex.barbellcurl.need))
            check("a missing item: (Requires X) under its exercise", ex.bicepscurl and ex.bicepscurl.have == false
                and ex.bicepscurl.need == "IGUI_FitnessNeedItem(Dumbbell)", ex.bicepscurl and tostring(ex.bicepscurl.need))
            check("no item needed: no note", ex.squats and ex.squats.need == nil)
        end
    end
    check("the fill is read on a clock (500 ms), not every frame", src:find('dueMs(win, "_healthFillAt", 500', 1, true) ~= nil)
    check("the fill's stops join the controller's", (readFile("42/media/lua/client/ZeD/ZeD_CharacterWindow.lua") or ""):find('ZeD.TabFill.focusables(win, "health"', 1, true) ~= nil)
end

section("RADIO")
do
    -- the director's second review (Nov 11 2026): Power said Battery twice (the charge, then the spares by the item's
    -- name) and Heard was missing (an empty block draws nothing, and nothing had been heard yet)
    local src = readFile("42/media/lua/client/ZeD/RadioTab.lua") or ""
    local a = src:find("local function _fillGet(o, m, ...)", 1, true)
    local b = src:find("-- the face, its footer and the scrollbar under the header", 1, true)
    check("the radio fill is in the file", a and b)
    if a and b and okLoad then
        ZeD.RadioTab = {}
        getItemNameFromFullType = function() return "Battery" end
        local HEARD = {}
        local SPARES = 1
        ZeD.RadioOps = { chanName = function() return nil end, freqText = function(f) return tostring(f) end, recall = noop }
        ZeD.Rtv = {
            read = function() return { dd = {}, presets = {}, battery = true, hasBattery = true, charge = 0.8, min = 88000, max = 108000 } end,
            heardLines = function() return HEARD end,
        }
        local chunk, err = loadstring(src:sub(a, b - 1), "=RadioTab.lua (cut)")
        check("the radio fill cuts and loads", chunk ~= nil, err)
        if chunk then
            chunk()
            local inv = { getCountTypeRecurse = function() return SPARES end }
            local win = { _playerObj = { getInventory = function() return inv end } }
            local tw = { dev = {}, view = { x = 0, y = 0, w = 480, h = 2000 } }
            local function draw()
                tw.fill = nil
                F.begin(win, "radio")
                local p = panel()
                local h = ZeD.RadioTab.renderFill(p, win, tw, 0, 0, 464)
                local ids = {}
                for _, z in ipairs(F.zones(win, "radio")) do ids[z.id] = z end
                return h, p, ids
            end
            local _, p, ids = draw()
            local nBatt = 0
            for _, s in ipairs(p.texts) do if s == "Tooltip_Dashboard_Battery" or s == "Battery" then nBatt = nBatt + 1 end end
            check("Power: Battery once", nBatt == 1, nBatt)
            check("Power: the spares on a Spare row", tw.fill.power[2].label == "UI_ZeD_Radio_Spare" and tw.fill.power[2].value == "x1")
            check("Heard: the block shows with nothing heard", ids["fill:radio:head:heard"] ~= nil)
            check("Heard: its one line says nothing was heard yet", ids["fill:radio:heard:none"] ~= nil
                and tw.fill.heard[1].label == "UI_ZeD_Radio_NothingHeard" and tw.fill.heard[1].dim == true)
            check("Heard: the head counts no lines", tw.fill.heardN == 0)
            HEARD = { "This is a test of the emergency broadcast", "Stay indoors" }
            _, p, ids = draw()
            check("Heard: the lines once heard, no empty line", ids["fill:radio:heard:1"] ~= nil and ids["fill:radio:heard:2"] ~= nil
                and ids["fill:radio:heard:none"] == nil and tw.fill.heardN == 2)
            SPARES = 0
            draw()
            check("Power: no spares says so", tw.fill.power[2].label == "UI_ZeD_Radio_NoBatteries")

            -- the design review (Nov 12): one frequency format on every set (the game's own radio window lists every
            -- set's presets with one decimal; the walkie listed "098.400", the radio "98.0"), a channel's name on one
            -- line, one heading in both windows; and a TV (review finding): its channel numbers, no frequency range
            ZeD.RadioOps.freqText = function(f, ham) return (ham and "ham:" or "fm:") .. tostring(f) end
            local DD = { getIsTwoWay = function() return true end }
            local PRESETS = { { name = "Automated Emergency Broadcast System", freq = 98400 }, { name = "KnoxTalk Radio", freq = 101200 } }
            ZeD.Rtv.read = function()
                return { dd = DD, presets = PRESETS, battery = true, hasBattery = true, charge = 0.8, min = 50000, max = 200000 }
            end
            local _, wp = draw()
            local pr = tw.fill.presets
            check("a walkie's channels in the one format", pr[1].value == "fm:98400" and pr[2].value == "fm:101200", tostring(pr[1].value))
            check("a channel's name on one line", pr[1].cut == true and pr[2].cut == true)
            check("Channels in the Character window", wp.heads and wp.heads[1] == "UI_ZeD_Radio_Channels", wp.heads and tostring(wp.heads[1]))
            win._actionTabStrip = {}
            _, wp = draw()
            check("Channels in the World window too", wp.heads and wp.heads[1] == "UI_ZeD_Radio_Channels", wp.heads and tostring(wp.heads[1]))
            win._actionTabStrip = nil
            local function powerIds()
                local out = {}
                for _, r in ipairs(tw.fill.power) do out[r.id] = r end
                return out
            end
            -- a TV: the numbers its dial shows, the headphones row kept (its PHONES jack works), no frequency range
            DD = { getIsTwoWay = function() return false end, getIsTelevision = function() return true end }
            PRESETS = { { name = "", freq = 200 }, { name = "", freq = 201 }, { name = "", freq = 5000 } }
            ZeD.Rtv.stopOf = function(f)
                if f == 200 then return { number = 2 } elseif f == 201 then return { number = 3 } end
                return nil
            end
            draw()
            pr = tw.fill.presets
            local pw = powerIds()
            check("a TV: no frequency range", pw["fill:radio:range"] == nil)
            check("a TV: its headphones row kept", pw["fill:radio:phones"] ~= nil)
            check("a TV: its channels by the dial's number", pr[1].value == "02" and pr[2].value == "03" and pr[3].value == nil,
                tostring(pr[1].value) .. " " .. tostring(pr[2].value) .. " " .. tostring(pr[3].value))
            -- a radio keeps its frequency range
            DD = {}
            draw()
            check("a radio keeps its frequency range", powerIds()["fill:radio:range"] ~= nil)
        end
    end
    local en = readFile("42/media/lua/shared/Translate/EN/UI.json") or ""
    check("EN: Spare", en:find('"UI_ZeD_Radio_Spare": "Spare"', 1, true) ~= nil)
    check("EN: Nothing heard yet", en:find('"UI_ZeD_Radio_NothingHeard": "Nothing heard yet"', 1, true) ~= nil)
end

section("SOURCE")
do
    local th = readFile("42/media/lua/client/ZeD/ThermalTab.lua") or ""
    check("Thermal: no gradient bar left", th:find("drawGradientBar", 1, true) == nil)
    check("Thermal: Body Heat Generation read", th:find("getHeatGenerationUI", 1, true) ~= nil)
    check("Thermal: the readings no longer swap for a part", th:find("_renderDetailView(", 1, true) == nil)
    check("Thermal: the picked block's words made only on a change", th:find("c.data == data and c.part == part", 1, true) ~= nil)
    local jl = readFile("42/media/lua/client/ZeD/ZeD_JournalLists.lua") or ""
    check("Loadouts: the switch is radio buttons", jl:find("A.drawRadio(", 1, true) ~= nil)
    check("Loadouts: no segmented pill left", jl:find("panel:drawRect(sx, y, sw, h, 1, ac.r", 1, true) == nil)
    check("Loadouts: opens on a list", jl:find('L.all(p, "loadout")[1]', 1, true) ~= nil)
    check("Loadouts: ready X of Y in the head", jl:find('"UI_ZeD_EqBar_Ready"', 1, true) ~= nil)
    check("Loadouts: the standing read on a clock", jl:find("now - c.at < 500", 1, true) ~= nil)
    local rt = readFile("42/media/lua/client/ZeD/RadioTab.lua") or ""
    check("Radio: the blocks read on a clock", rt:find("now - tw.fillAt >= 500", 1, true) ~= nil)
    check("Radio: a channel row tunes on its press", rt:find("O.recall(win._playerObj, dev, idx)", 1, true) ~= nil)
    local jr = readFile("42/media/lua/client/ZeD/ZeD_JournalReaders.lua") or ""
    check("Notebooks: the blocks under the empty line", jr:find("J.renderNoNotebook(panel, win, carried, lx, cy, lw)", 1, true) ~= nil)
    local en = readFile("42/media/lua/shared/Translate/EN/UI.json") or ""
    for _, k in ipairs({ "UI_ZeD_Health_Moodles", "UI_ZeD_Radio_Channels", "UI_ZeD_Radio_Heard", "UI_ZeD_Notebook_HasTool",
                         "UI_ZeD_Notebook_LightOk", "UI_ZeD_Notebook_PapersOn", "UI_ZeD_Notebook_BooksOn" }) do
        check("EN has " .. k, en:find('"' .. k .. '"', 1, true) ~= nil)
    end
    local fill = readFile("42/media/lua/client/ZeD/ZeD_TabFill.lua") or ""
    -- (words wrap, never cut; the one exception the design review asked for: a row that asks for one line, the radio's
    -- channel names, cut with "..." only where they do not fit)
    local cutAt, truncAt = fill:find("if r.cut then", 1, true), fill:find("truncateText", 1, true)
    local _, nTrunc = fill:gsub("truncateText", "")
    check("the kit cuts words only on a row that asks for one line", cutAt and truncAt and nTrunc == 1 and truncAt > cutAt
        and truncAt - cutAt < 400, tostring(nTrunc))
end

print(string.format("tab_fill_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
