-- ZeDUI/tools/qa/card_cover_sim.lua  (Nov 7 2026, Build): two cards items of the outside review of beta 7
-- (ZeDUI/qa/REVIEW_BETA7_EXTERNAL_20261107.md, items 2 and 8), with no game running. The real pieces are cut out of
-- Molecules.lua, ZeD_CharacterWindow.lua, CraftingTab.lua and CraftingCore.lua and run on Lua 5.1 stubs.
--   BAND    an item card over a drawer tab (the Character window: _coverX, the card over the right part; the World
--           window: _coverL, over the left part): a band's buttons, icons and question line lay out in what the card
--           leaves showing (ZeD.Molecules.bandRoom), so the Journal's Cancel / Delete stay in reach; with no card, or
--           too little showing, the band keeps its whole width
--   HIDE    the Character window hides the tab's own boxes the card lies over, measured in the drawer (as the clip
--           is): a box under the card by less than the tab strip's width hides too; Save, placed in the room the
--           card leaves, stays
--   CRAFT   Craft goes by the craft's own start check (HandcraftLogic canPerformCurrentRecipe, as ISHandcraftAction
--           :start asks it), not only the list's cached answer: a stale "craftable" leaves Craft off; the check is
--           asked again when the containers are gathered again; a press the start check refuses queues nothing and
--           counts nothing; a batch past the most it can make is cut to that most
--   BENCH   the start check with distance (a fake HandcraftLogic that models the 3-tile workbench reach): a bench
--           bound out past it (ZeD's 4.5-tile leash, more from a right-click) leaves Craft on and the press walks
--           there, when the materials are there; short of them (Required 1/4) Craft is off near or far and a press
--           walks nowhere; an any-surface recipe in Hand mode is checked and made on the table found in reach
--   SCAN    a vanilla scan that throws drops the answers it held (fromLogic), so they don't carry on
-- A last section puts the old code's shape back (no bandRoom; no start check) and shows the sim catches both.
-- What it can't show is how it looks: an item card over the Journal's question band, in the game.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/card_cover_sim.lua
-- It prints FAIL lines and a last line "card_cover_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]card_cover_sim%.lua$", "")

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
    local f = assert(io.open(ROOT .. rel, "rb"))
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end
-- the text from the first `from` to the end of the line where the first `to` after it ends (plain finds)
local function cut(src, from, to, init)
    local a = string.find(src, from, init or 1, true)
    if not a then return nil end
    local b = string.find(src, to, a, true)
    if not b then return nil end
    local e = string.find(src, "\n", b + #to, true) or #src
    return string.sub(src, a, e), e
end

-- ---------------------------------------------------------------------------
-- STUBS: the theme, the atoms, a panel that writes down what it draws
-- ---------------------------------------------------------------------------
local CHAR_W = 7
local T = {
    px = function(n) return n end, buttonH = 20, fontF2 = "f2", sp = { xs = 4 },
    danger = { r = 1, g = 0, b = 0 }, text = { r = 1, g = 1, b = 1, a = 1 },
}
local A = {
    surfaceFill = function() end, drawDividerH = function() end, mouseIn = function() return false end,
    drawStatusDot = function() end,
    truncateText = function(s, _, room)
        local n = math.floor(room / CHAR_W)
        if #s <= n then return s end
        return string.sub(s, 1, math.max(0, n - 3)) .. "..."
    end,
}
local drawn = {}
local M = {}
M.bandH = function() return 30 end
M.buttonW = function(label) return #label * CHAR_W + 16 end
M.drawButton = function(_, x, y, w, h, label) drawn[#drawn + 1] = { kind = "button", x = x, w = w, label = label } end
M.drawIconButton = function(_, x, _, s) drawn[#drawn + 1] = { kind = "icon", x = x, w = s } end
local ZeD = {
    T = T, Atoms = A, Molecules = M,
    TM = { getFontHeight = function() return 14 end },
    tr = function(k) return k == "UI_Cancel" and "Cancel" or k end,
}
local function newPanel(coverX, coverL)
    return {
        _coverX = coverX, _coverL = coverL,
        drawText = function(_, s, x) drawn[#drawn + 1] = { kind = "text", x = x, w = #s * CHAR_W, label = s } end,
    }
end

-- the band (bandRoom, drawBand, drawQuestionBand) from Molecules.lua
local loadBand
do
    local src = readFile("42/media/lua/client/ZeD/Molecules.lua")
    local a = string.find(src, "function ZeD.Molecules.bandRoom(", 1, true)
    check("Molecules.lua has bandRoom", a ~= nil)
    a = a or string.find(src, "function ZeD.Molecules.drawBand(", 1, true)   -- (the old code: the band alone)
    local q, qEnd = cut(src, "function ZeD.Molecules.drawQuestionBand(", "\nend", a or 1)
    check("Molecules.lua has drawBand and drawQuestionBand", a ~= nil and q ~= nil)
    local body = (a and qEnd) and string.sub(src, a, qEnd) or ""
    loadBand = function()
        local chunk = assert(loadstring("local ZeD, NO_OPTS, _bandBtn, _bandIcon, drawBandCheck = ...\n" .. body))
        chunk(ZeD, {}, {}, {}, function() return { x = 0, y = 0, w = 0, h = 0 } end)
    end
    loadBand()
    -- (without one, the checks on it fail, they don't stop the run)
    M.bandRoom = M.bandRoom or function() return nil, nil end
end

-- what a band drew: the rightmost right edge and the leftmost left edge of every button, icon and text
local function extent()
    local l, r = math.huge, -math.huge
    for _, d in ipairs(drawn) do
        if d.x < l then l = d.x end
        if d.x + d.w > r then r = d.x + d.w end
    end
    return l, r
end

local QUESTION = "Delete the entry? It can't be brought back."
local function askBand(panel, x, w)
    drawn = {}
    local _, cancel, verb = M.drawQuestionBand(panel, x, 100, w, QUESTION, "Delete", { danger = true })
    return cancel, verb
end

-- ---------------------------------------------------------------------------
section("BAND")
-- ---------------------------------------------------------------------------
do
    -- no card: the buttons end at the band's right edge less the 8u edge
    local cancel, verb = askBand(newPanel(nil, nil), 0, 480)
    check("no card: Delete at the band's right", verb and verb.x + verb.w == 480 - 8, verb and (verb.x + verb.w))
    check("no card: Cancel left of Delete", cancel and verb and cancel.x + cancel.w <= verb.x)

    -- the Character window: the card over the right part from 240 (a 480 drawer, the 240 half card)
    cancel, verb = askBand(newPanel(240, nil), 0, 480)
    local l, r = extent()
    check("card at 240: Delete ends left of the card", verb and verb.x + verb.w <= 240, verb and (verb.x + verb.w))
    check("card at 240: Cancel ends left of the card", cancel and cancel.x + cancel.w <= 240)
    check("card at 240: nothing drawn under the card", r <= 240, r)
    check("card at 240: the question still shows", (function()
        for _, d in ipairs(drawn) do if d.kind == "text" and #d.label > 0 then return true end end
        return false end)())
    check("card at 240: the question ends before Cancel", (function()
        for _, d in ipairs(drawn) do
            if d.kind == "text" and cancel and d.x + d.w > cancel.x then return false end
        end
        return true end)())

    -- the World window: the card over the left part up to 240
    cancel, verb = askBand(newPanel(nil, 240), 0, 480)
    l, r = extent()
    check("left card to 240: nothing drawn under the card", l >= 240, l)
    check("left card to 240: Delete still at the right", verb and verb.x + verb.w == 480 - 8)

    -- a band with icons under a left card: the icons start where the card ends
    drawn = {}
    M.drawBand(newPanel(nil, 200), 0, 100, 480, { icons = { { icon = "x" }, { icon = "y" } }, buttons = { { label = "Save" } } })
    l = extent()
    check("left card to 200: the icons start after it", l >= 200 + 8, l)

    -- too little showing for the buttons: the band keeps its whole width (they are not squeezed off)
    cancel, verb = askBand(newPanel(40, nil), 0, 480)
    check("card at 40: the band keeps its width", verb and verb.x + verb.w == 480 - 8)

    -- bandRoom itself
    local bl, br = M.bandRoom(newPanel(300, nil), 10, 400, 50)
    check("bandRoom: right card", bl == 10 and br == 300, tostring(bl) .. "," .. tostring(br))
    bl, br = M.bandRoom(newPanel(nil, 100), 10, 400, 50)
    check("bandRoom: left card", bl == 100 and br == 410, tostring(bl) .. "," .. tostring(br))
    bl, br = M.bandRoom(newPanel(600, nil), 10, 400, 50)
    check("bandRoom: card past the band", bl == 10 and br == 410)
    bl, br = M.bandRoom(nil, 10, 400, 50)
    check("bandRoom: no panel", bl == 10 and br == 410)
end

-- ---------------------------------------------------------------------------
section("HIDE")
-- ---------------------------------------------------------------------------
local hideBlock
do
    local src = readFile("42/media/lua/client/ZeD/ZeD_CharacterWindow.lua")
    local blk = cut(src, "if win._drawerItem ~= nil and win._drawerMode == \"tab\" then", "\n        end\n")
    check("the Character window's cover-hide block is found", blk ~= nil)
    hideBlock = assert(loadstring("local win, T, getTargetDrawerW, ITEM_CARD_W, TAB_STRIP_W = ...\n" .. (blk or "")))
end
local function box(x, w)
    local b = { x = x, w = w, vis = true }
    function b:isVisible() return self.vis end
    function b:getX() return self.x end
    function b:getWidth() return self.w end
    function b:setVisible(v) self.vis = v end
    return b
end
do
    -- a 480 drawer, the 240 card from 240 (drawer-local); the tab strip is 40 wide
    local drawerW, cardW, stripW = 480, 240, 40
    local coverX = drawerW - cardW
    -- Save where the Journal puts it: in the room the band leaves, 8u in
    local bl, br = M.bandRoom(newPanel(coverX, nil), 0, drawerW, 60 + 16)
    br = br or drawerW   -- (the old code: no bandRoom, Save at the band's right)
    local save = box(br - 8 - 60, 60)
    local input = box(0, coverX)            -- the entry box, cut at the card (JournalTab)
    local under = box(0, coverX + 20)       -- a search box 20 px under the card
    local win = { _drawerItem = {}, _drawerMode = "tab", _journalSaveBtn = save, _journalInput = input,
                  _journalSearch = under }
    hideBlock(win, T, function() return drawerW end, cardW, stripW)
    check("Save, in the room the card leaves, stays", save.vis)
    check("the entry box, cut at the card, stays", input.vis)
    check("a box 20 px under the card hides", not under.vis)
end

-- ---------------------------------------------------------------------------
-- CRAFT: the Craft tab's start check, gatherDetail and startCraft from CraftingTab.lua
-- ---------------------------------------------------------------------------
local logicNews, refuse, mostCanMake = 0, false, 5
local HandcraftLogic = { new = function()
    logicNews = logicNews + 1
    local l = {}
    function l:setContainers(c) self.c = c end
    function l:setRecipe(r) self.r = r end
    function l:canPerformCurrentRecipe() return not refuse end
    function l:getPossibleCraftCount() return mostCanMake end
    return l
end }
local queued, counted = 0, 0
local recipe = {
    getName = function() return "MakeAdvancedFramepackFrame" end,
    getTimedActionScript = function() return "x" end, isCanWalk = function() return false end,
    getTime = function() return 10 end,
}
local entry = { name = "MakeAdvancedFramepackFrame", recipe = recipe, allowBatch = true }
local gatherCont = {}
local CC = {
    gatherDetail = function() return gatherCont end,
    buildContainers = function() return {} end,
    incrementCraftCount = function() counted = counted + 1 end,
}
local gatherDetail
local lastAction
-- opts (the BENCH section): HandcraftLogic, Stations, ISEntityUI, boundBench, recipes (by name)
local function loadCraft(src, opts)
    opts = opts or {}
    local a = string.find(src, "function ZeD.CraftingTab.startCheck(", 1, true)
    local e = string.find(src, "-- CONFIG TABLE", a or 1, true)
    check("CraftingTab.lua's start check to startCraft is found", a ~= nil and e ~= nil)
    if not (a and e) then return end
    local env = {
        ZeD = { CraftingTab = {}, Stations = opts.Stations },
        HandcraftLogic = opts.HandcraftLogic or HandcraftLogic, pcall = pcall, math = math, tostring = tostring,
        ipairs = ipairs,
        ISBaseTimedAction = { new = function() return {} end }, ISHandcraftAction = {},
        ISTimedActionQueue = { add = function(act) queued = queued + 1; lastAction = act end },
        CharacterTrait = { ALL_THUMBS = 1 }, ISEntityUI = opts.ISEntityUI,
    }
    local chunk = assert(loadstring("local CC, _recipeByName, boundBench = ...\n" .. string.sub(src, a, e - 1)
        .. "\nreturn gatherDetail"))
    setfenv(chunk, env)
    local g = chunk(CC, opts.recipes or { [entry.name] = entry }, opts.boundBench or function() return nil end)
    if not opts.Stations then gatherDetail = g end
    return env.ZeD.CraftingTab, g
end
local CT = loadCraft(readFile("42/media/lua/client/ZeD/CraftingTab.lua"))

-- the Craft button's enabled state, from CraftingCore's drawBandActions
local canCraftOf
do
    local src = readFile("42/media/lua/client/ZeD/CraftingCore.lua")
    local line = string.match(src, "\n%s*(canCraft = rd%.status == \"craftable\"[^\r\n]*)")
    check("drawBandActions' canCraft line is found", line ~= nil)
    canCraftOf = assert(loadstring("local rd, maxQty = ...\nlocal canCraft\n" .. (line or "") .. "\nreturn canCraft"))
end

local player = { hasTrait = function() return false end, isWearingAwkwardGloves = function() return false end }

section("CRAFT")
if not (CT and gatherDetail) then check("the Craft tab's start check loads", false) else
    -- the list's answer, cached, says craftable; the materials went (Required 1/4): the start check refuses
    local win = { _playerObj = player }
    local rd = { entry = entry, status = "craftable", learned = true }
    refuse = true
    gatherDetail(rd, player, win)
    check("stale craftable, start refuses: canStart false", rd.canStart == false, rd.canStart)
    check("stale craftable, start refuses: Craft off", canCraftOf(rd, 1) == false)

    -- asked once per containers: the same containers, no new logic; new ones, asked again
    local n0 = logicNews
    gatherDetail(rd, player, win)
    check("same containers: not asked again", logicNews == n0, logicNews - n0)
    refuse = false
    gatherCont = {}
    gatherDetail(rd, player, win)
    check("containers gathered again: asked again", logicNews == n0 + 1, logicNews - n0)
    check("materials back: Craft on", rd.canStart == true and canCraftOf(rd, 1) == true)
    check("materials back: the batch's most", rd.maxBatchQty == mostCanMake, rd.maxBatchQty)

    -- not craftable by the list: no Java call, Craft off
    local rd2 = { entry = entry, status = "missing", learned = true }
    n0 = logicNews
    gatherDetail(rd2, player, win)
    check("missing: no start check", logicNews == n0)
    check("missing: Craft off", canCraftOf(rd2, 1) == false)

    -- the game would not answer (nil): the list's answer stands, as before
    check("no answer: Craft by the list", canCraftOf({ status = "craftable", learned = true, canStart = nil }, 1) == true)

    -- the press: refused, nothing queued, nothing counted, the tab asks again
    refuse = true
    queued, counted = 0, 0
    local w3 = { _playerObj = player, _craftStartChk = { name = "x" } }
    local st = { selected = entry.name, qty = 1 }
    CT.startCraft(w3, st)
    check("refused press: nothing queued", queued == 0, queued)
    check("refused press: nothing counted", counted == 0, counted)
    check("refused press: the tab asks again", w3._craftStartChk == nil and w3._craftLogicAt == nil)

    -- a batch past the most: nothing queued, the amount cut to the most
    refuse, mostCanMake = false, 2
    queued, counted = 0, 0
    st = { selected = entry.name, qty = 4 }
    CT.startCraft(w3, st)
    check("batch of 4, most 2: nothing queued", queued == 0, queued)
    check("batch of 4, most 2: amount cut to 2", st.qty == 2, st.qty)

    -- a press it accepts: queued and counted
    st = { selected = entry.name, qty = 2 }
    CT.startCraft(w3, st)
    check("accepted batch of 2: two queued", queued == 2, queued)
    check("accepted batch of 2: counted", counted == 1, counted)
end

-- ---------------------------------------------------------------------------
section("BENCH")
-- ---------------------------------------------------------------------------
-- A HandcraftLogic that models distance as the game's does (42.21 / 42.22 bytecode):
-- isCharacterInRangeOfWorkbench is the bench's (or surface's) square under 3 tiles from the
-- player, false with none; canPerformCurrentRecipe is the materials, then false for an
-- any-surface recipe out of that range and for a station recipe out of it (hasRequiredWorkstation);
-- getPossibleCraftCount counts the materials only. ZeD keeps a bench bound to 4.5 tiles and
-- Craft walks there: a recipe the player can make at the bench stays on and walks; one short
-- of materials is off, near or far; an any-surface recipe in Hand mode goes by the table found.
do
    local W = { px = 0, py = 0, have = 4 }
    local function dist(o) return math.sqrt((o.x - W.px) ^ 2 + (o.y - W.py) ^ 2) end
    local DistLogic = { new = function(_, comp, iso)
        local l = { comp = comp, iso = iso }
        function l:setContainers() end
        function l:setRecipe(r) self.r = r end
        function l:isCharacterInRangeOfWorkbench() return self.iso ~= nil and dist(self.iso) < 3 end
        function l:getPossibleCraftCount() return math.floor(W.have / self.r.need) end
        function l:canPerformCurrentRecipe()
            local ok = W.have >= self.r.need
            if self.r.anySurface and not self:isCharacterInRangeOfWorkbench() then ok = false end
            if self.r.specific and not (self:isCharacterInRangeOfWorkbench() and self.comp ~= nil) then ok = false end
            return ok
        end
        return l
    end }
    local function mkRecipe(name, need, flags)
        local r = { name = name, need = need, anySurface = flags.anySurface, specific = flags.specific }
        r.getName = function() return name end
        r.getTimedActionScript = function() return "x" end
        r.isCanWalk = function() return false end
        r.getTime = function() return 10 end
        return r
    end
    local frame = { name = "MakeAdvancedFramepackFrame", allowBatch = true, stationInfo = {},
                    recipe = mkRecipe("MakeAdvancedFramepackFrame", 4, { specific = true }) }
    local onTable = { name = "MakeOnTable", allowBatch = false, needSurface = true,
                      recipe = mkRecipe("MakeOnTable", 1, { anySurface = true }) }
    local benchObj = { x = 10, y = 10 }
    local bench = { kind = "bench", obj = benchObj, comp = {} }
    local bound = bench
    local walks, surfaceAt = {}, nil
    local Stations = {
        validate = function() return bound end,
        recipeSet = function() return { [frame.name] = true } end,
    }
    local Entity = {
        WalkToEntity = function(_, obj) walks[#walks + 1] = obj; return true end,
        FindCraftSurface = function() return surfaceAt end,
    }
    local CT2, gd = loadCraft(readFile("42/media/lua/client/ZeD/CraftingTab.lua"), {
        HandcraftLogic = DistLogic, Stations = Stations, ISEntityUI = Entity,
        boundBench = function() return bound end,
        recipes = { [frame.name] = frame, [onTable.name] = onTable },
    })
    if not (CT2 and gd) then check("the Craft tab loads with a bench", false) else
        local function craftState(e)
            local win = { _playerObj = player }
            local rd = { entry = e, status = "craftable", learned = true }
            gatherCont = {}
            gd(rd, player, win)
            return rd, win
        end
        local function press(win, e, qty)
            queued, counted, walks, lastAction = 0, 0, {}, nil
            local st = { selected = e.name, qty = qty or 1 }
            CT2.startCraft(win, st)
            return st
        end

        -- bound at 4 tiles (inside the 4.5 leash, past the check's 3), the materials there: on, and walks
        W.px, W.py, W.have = 6, 10, 4
        local rd, win = craftState(frame)
        check("bench 4 tiles off, materials there: canStart", rd.canStart == true, rd.canStart)
        check("bench 4 tiles off, materials there: Craft on", canCraftOf(rd, 1) == true)
        press(win, frame)
        check("bench 4 tiles off: walks to the bench", walks[1] == benchObj, #walks)
        check("bench 4 tiles off: queued and counted", queued == 1 and counted == 1, queued .. "," .. counted)
        check("bench 4 tiles off: the action carries the bench", lastAction and lastAction.isoObject == benchObj
            and lastAction.craftBench == bench.comp)

        -- a batch from far: the most is what the materials make
        W.have = 8
        rd, win = craftState(frame)
        check("bench 4 tiles off, materials for 2: the batch's most is 2", rd.maxBatchQty == 2, rd.maxBatchQty)
        press(win, frame, 2)
        check("bench 4 tiles off, batch of 2: two queued", queued == 2, queued)

        -- bound far from a right-click across the room (the leash: distance + 1)
        W.px, W.have = 3, 4
        rd = craftState(frame)
        check("bench 7 tiles off, materials there: Craft on", rd.canStart == true and canCraftOf(rd, 1) == true)

        -- short of materials (Required 1/4): off near or far, and a press walks nowhere
        W.px, W.have = 6, 1
        rd, win = craftState(frame)
        check("bench 4 tiles off, Required 1/4: canStart false", rd.canStart == false, rd.canStart)
        check("bench 4 tiles off, Required 1/4: Craft off", canCraftOf(rd, 1) == false)
        press(win, frame)
        check("bench 4 tiles off, Required 1/4: no walk, nothing queued or counted",
            #walks == 0 and queued == 0 and counted == 0)
        W.px = 9
        rd, win = craftState(frame)
        check("bench 1 tile off, Required 1/4: Craft off", rd.canStart == false and canCraftOf(rd, 1) == false)

        -- at the bench with the materials: on, as before
        W.have = 4
        rd = craftState(frame)
        check("bench 1 tile off, materials there: Craft on", rd.canStart == true)

        -- Hand mode, an any-surface recipe: a table 1 tile off makes it; none in reach refuses
        bound = nil
        W.px, W.py, W.have = 0, 0, 1
        surfaceAt = { x = 1, y = 0 }
        rd, win = craftState(onTable)
        check("Hand, a table in reach: Craft on", rd.canStart == true and canCraftOf(rd, 1) == true, rd.canStart)
        press(win, onTable)
        check("Hand, a table in reach: walks to it and the action carries it",
            walks[1] == surfaceAt and lastAction and lastAction.isoObject == surfaceAt and lastAction.craftBench == nil)
        surfaceAt = nil
        rd = craftState(onTable)
        check("Hand, no table in reach: Craft off", rd.canStart == false, rd.canStart)
        bound = bench
    end
end

-- ---------------------------------------------------------------------------
section("SCAN")
-- ---------------------------------------------------------------------------
do
    local src = readFile("42/media/lua/client/ZeD/CraftingCore.lua")
    local body = cut(src, "function CC.logicScan(", "\nend\n")
    check("CC.logicScan is found", body ~= nil)
    local CC2 = { buildContainers = function() error("the game would not answer") end }
    local env = { pcall = pcall, ipairs = ipairs, getTimestampMs = function() return 99999 end, ArrayList = {} }
    local chunk = assert(loadstring("local CC, LOGIC_EVERY_MS = ...\n" .. (body or "")))
    setfenv(chunk, env)
    chunk(CC2, 1200)
    local rd = { entry = entry, status = "craftable", fromLogic = true }
    local win = { _playerObj = player, _craftLogic = { setContainers = function() end } }
    CC2.logicScan({ recipes = { rd } }, win, "craft", function() return {} end)
    check("a scan that throws drops its held answer", rd.fromLogic == nil)
    check("a scan that throws drops the logic", win._craftLogic == nil)
end

-- ---------------------------------------------------------------------------
section("TEETH: the old code's shape fails")
-- ---------------------------------------------------------------------------
do
    local real = M.bandRoom
    M.bandRoom = function(_, x, w) return x, x + w end   -- (no room taken for the card, as before)
    local _, verb = askBand(newPanel(240, nil), 0, 480)
    check("teeth: without bandRoom, Delete lies under the card", verb and verb.x + verb.w > 240)
    M.bandRoom = real

    local rd = { entry = entry, status = "craftable", learned = true }   -- (no canStart: the old gatherDetail)
    check("teeth: without the start check, Craft stays on at a stale craftable", canCraftOf(rd, 1) == true)
end

print(string.format("card_cover_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
