-- ZeDUI/tools/qa/cb_craft_fixes_sim.lua  (QA cb sweep, Nov 25 2026: the Crafting tab's fixes), checked on the real
-- pieces of CraftingCore.lua and CraftingTab.lua with no game running.
--   C1   Craft grays and a press is refused while a craft ZeD queued is still in the player's queue; a craft built
--        without chosen inputs asks the game's check at its start and stops (forceStop) when it fails
--   C19  the use count goes up when each craft starts, not at the press
--   C4   the card's have counts are the game's (logic:getInputCount; a uses slot: isInputSatisfied)
--   C7   with chosen ingredients, Max and the amount count only the crafts the choice covers
--   C9   a failed walk sends back every input moved for the craft, and queues no craft
--   C12  every category is a pad stop; landing on one out of view scrolls the list to it
--   C13  pad B with a card open shuts the card (or leaves the alternatives), never the running craft
--   C18  the game's favourites join the Craft tab's pins; a pin or unpin sets the game's flag
-- Run from the repo root:  lua51 ZeDUI/tools/qa/cb_craft_fixes_sim.lua
-- It prints FAIL lines and a last line "cb_craft_fixes_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]cb_craft_fixes_sim%.lua$", "")

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
local CCS = srcOf("CraftingCore.lua")
local CTS = srcOf("CraftingTab.lua")
local function has(src, s) return src:find(s, 1, true) ~= nil end

-- a top-level function of a file, from its opening text to its first unindented "end"
local function cutFn(src, open)
    local a = src:find(open, 1, true)
    if not a then return nil end
    local e = src:find("\nend\n", a, true)
    if not e then return nil end
    return src:sub(a, e + 4)
end
-- the text from one marker up to (not including) another
local function cutBetween(src, open, close)
    local a = src:find(open, 1, true)
    if not a then return nil end
    local b = src:find(close, a + #open, true)
    if not b then return nil end
    return src:sub(a, b - 1)
end
local function load(piece, prefix, name)
    if not piece then return nil, "not found" end
    return loadstring((prefix or "") .. piece, "=" .. name)
end

ZeD = { CraftingTab = {}, T = { px = function(n) return n end } }
CC = {}
ZeD.CraftingCore = CC
getTimestampMs = function() return 1000 end
getText = function(k) return k end

-- ---------------------------------------------------------------------------
section("C1 / C19: busy, the checked start, the count at start")
-- ---------------------------------------------------------------------------
do
    local block = cutBetween(CCS, "-- A craft in progress (QA cb sweep", "--- An any-surface recipe in Hand mode")
    local chunk, err = load(block, "local CC = ...\n", "CraftingCore.lua (busy block)")
    check("busy block cut and loads", chunk ~= nil, err)
    if chunk then
        CC.incrementCraftCount = function(p, name, key)
            p.counts[key] = p.counts[key] or {}
            p.counts[key][name] = (p.counts[key][name] or 0) + 1
        end
        chunk(CC)
        -- the queue
        local Q = { queue = {} }
        function Q:indexOf(a) for i, v in ipairs(self.queue) do if v == a then return i end end return -1 end
        ISTimedActionQueue = { getTimedActionQueue = function() return Q end }
        local win = { _playerObj = {} }
        check("nothing queued: not busy", CC.craftBusy(win) == false)
        local a1, a2 = {}, {}
        Q.queue = { a1, a2 }
        CC.trackCraftActions(win, { a1, a2 })
        check("queued crafts: busy", CC.craftBusy(win) == true)
        Q.queue = { a2 }
        check("one still queued: busy", CC.craftBusy(win) == true)
        Q.queue = {}
        check("all done: not busy", CC.craftBusy(win) == false)
        check("the list empties itself", win._craftQueued == nil)

        -- the checked start
        local can = false
        local started, stopped = 0, 0
        HandcraftLogic = { new = function() return {
            setContainers = function() end, setRecipe = function() end,
            canPerformCurrentRecipe = function() return can end } end }
        ISHandcraftAction = { start = function(self) started = started + 1; if self.onStartFunc then self.onStartFunc(self.onStartTarget, self) end end }
        local function mk(manual)
            local a = { manualInputs = manual }
            a.forceStop = function() stopped = stopped + 1 end
            a.setOnStart = function(self, f, t) self.onStartFunc = f; self.onStartTarget = t end
            return a
        end
        local p = { counts = {} }
        local a = mk(nil)
        CC.prepCraftAction(a, p, "Rip", "ZeD_CraftCounts")
        check("an automatic craft gets the checked start", a.start == CC.checkedCraftStart)
        check("nothing counted at the press", p.counts.ZeD_CraftCounts == nil)
        a:start()
        check("the check fails: stopped, not started", stopped == 1 and started == 0, stopped .. "/" .. started)
        check("a refused craft counts none", p.counts.ZeD_CraftCounts == nil)
        can = true
        local b = mk(nil)
        CC.prepCraftAction(b, p, "Rip", "ZeD_CraftCounts")
        b:start()
        local c = mk(nil)
        CC.prepCraftAction(c, p, "Rip", "ZeD_CraftCounts")
        c:start()
        check("each craft that starts counts one", p.counts.ZeD_CraftCounts and p.counts.ZeD_CraftCounts.Rip == 2)
        local m = mk({ [1] = {} })
        CC.prepCraftAction(m, p, "Rip", "ZeD_CraftCounts")
        check("a chosen-inputs craft keeps the game's own start", m.start == nil)
    end
    check("wire: the band grays Craft while busy", has(CCS, "and not rd.busy"))
    check("wire: the tab sets rd.busy", has(CTS, "rd.busy = CC.craftBusy(win, playerObj)"))
    check("wire: startCraft refuses while busy", has(CTS, "if CC.craftBusy(win, playerObj) then return end"))
    check("wire: the chosen-inputs start refuses while busy", has(CCS, "if CC.craftBusy(win, playerObj) then return true end"))
    check("wire: startCraft preps and tracks its actions", has(CTS, "CC.prepCraftAction(action, playerObj, recipeName")
        and has(CTS, "CC.trackCraftActions(win, queued, recipeName)"))
    check("wire: the chosen-inputs start preps and tracks", has(CCS, "CC.prepCraftAction(actions[i], playerObj, name")
        and has(CCS, "CC.trackCraftActions(win, queued, name)"))
    check("wire: no count at the press any more", not has(CTS, "CC.incrementCraftCount(") and
        not has(CCS, "CC.incrementCraftCount(playerObj, name"))
end

-- ---------------------------------------------------------------------------
section("C9: a failed walk sends every moved input back, no craft")
-- ---------------------------------------------------------------------------
do
    local piece = cutFn(CTS, "function ZeD.CraftingTab.startCraft(")
    local chunk, err = load(piece, "local CC, _recipeByName, craftSurface = ...\n", "CraftingTab.lua (startCraft)")
    check("startCraft cut and loads", chunk ~= nil, err)
    if chunk then
        local returned, added = nil, 0
        local CCx = {
            craftBusy = function() return false end,
            craftContainers = function() return {} end,
            moveCraftInputs = function() return { "screwdriver" }, { "plank", "screwdriver" } end,
            returnCraftInputs = function(_, list) returned = list end,
            prepCraftAction = function() end, trackCraftActions = function() end,
        }
        ZeD.Stations = nil
        ZeD.CraftingTab.startCheck = function() return true, 1, {} end
        ISEntityUI = { WalkToEntity = function() return false end }
        ISTimedActionQueue = { add = function() added = added + 1 end }
        ISBaseTimedAction = { new = function() return {} end }
        local entry = { recipe = { getName = function() return "Make" end } }
        chunk(CCx, { Make = entry }, function() return { "table" } end)
        local win = { _playerObj = {} }
        local state = { selected = "Make", qty = 1 }
        ZeD.CraftingTab.startCraft(win, state)
        check("no craft queued after a failed walk", added == 0, added)
        check("every moved input goes back, kept or not", returned and #returned == 2, returned and #returned)
        -- busy: nothing at all
        returned = nil
        CCx.craftBusy = function() return true end
        local moved = false
        CCx.moveCraftInputs = function() moved = true; return {}, {} end
        ZeD.CraftingTab.startCraft(win, state)
        check("busy: nothing moved or queued", not moved and added == 0)
    end
    check("wire: moveCraftInputs returns every moved item", has(CCS, "return back, all"))
    check("wire: the chosen-inputs start returns all on a failed walk", has(CCS, "CC.returnCraftInputs(playerObj, all)"))
end

-- ---------------------------------------------------------------------------
section("C4: the card's have counts are the game's")
-- ---------------------------------------------------------------------------
do
    local p1 = cutFn(CCS, "function CC.gameInputCounts(")
    local p2 = cutFn(CCS, "function CC.applyGameCounts(")
    local chunk, err = load(p1 and p2 and (p1 .. p2), "local CC = ...\n", "CraftingCore.lua (game counts)")
    check("game counts cut and load", chunk ~= nil, err)
    if chunk then
        chunk(CC)
        ResourceType = { Item = "item", Fluid = "fluid" }
        local function script(kind) return { getResourceType = function() return kind end } end
        local sBranch, sThread, sWater = script("item"), script("item"), script("fluid")
        local entry = { inputDefs = {
            { inputRef = sBranch, amount = 1 },
            { inputRef = sThread, amount = 1, usesBased = true },
            { inputRef = sWater, amount = 1 },
        } }
        -- one favourite branch in the bag: the type count says 1, the game's slot holds none
        local logic = {
            getInputCount = function(_, s) if s == sBranch then return 0 end return 9 end,
            isInputSatisfied = function(_, s) return s == sThread end,
        }
        local counts = CC.gameInputCounts(logic, entry)
        check("an item slot reads the game's count", counts[1] == 0, counts[1])
        check("a uses slot reads its need when covered", counts[2] == 1, counts[2])
        check("a fluid slot is left to the card", counts[3] == nil)
        local rd = { status = "craftable", ingredients = {
            { have = 1, need = 1 }, { have = 1, need = 1 }, { have = 1, need = 1 } } }
        CC.applyGameCounts(rd, counts)
        check("the card reads 0/1 for the favourite", rd.ingredients[1].have == 0)
        check("short slots worked out again", rd.missingCount == 1, rd.missingCount)
        check("the card's own status follows", rd.status == "missing", rd.status)
        local rd2 = { status = "craftable", fromLogic = true, ingredients = { { have = 1, need = 1 } } }
        CC.applyGameCounts(rd2, { [1] = 0 })
        check("the game's list answer is left alone", rd2.status == "craftable")
        check("no logic: no counts", CC.gameInputCounts(nil, entry) == nil)
    end
    check("wire: the tab puts the game's counts on the card", has(CTS, "chk.counts = CC.gameInputCounts(logic, entry)")
        and has(CTS, "CC.applyGameCounts(rd, chk.counts)"))
    check("wire: the catalog keeps usesBased", has(CCS, "usesBased  = usesBased,"))
end

-- ---------------------------------------------------------------------------
section("C7: Max counts the chosen ingredients")
-- ---------------------------------------------------------------------------
do
    local piece = cutFn(CCS, "function CC.pickedCraftCount(")
    local chunk, err = load(piece, "local CC = ...\nlocal function hasAny(t) for _ in pairs(t) do return true end return false end\n",
        "CraftingCore.lua (pickedCraftCount)")
    check("pickedCraftCount cut and loads", chunk ~= nil, err)
    if chunk then
        chunk(CC)
        local covers = 3
        CC.pickedCraftAction = function(_, _, _, _, _, used)
            used.n = (used.n or 0) + 1
            return used.n <= covers and {} or nil
        end
        local entry = { name = "Make" }
        local state = { picks = { Make = { [1] = "Base.Branch" } } }
        check("the choice covers 3 of 5", CC.pickedCraftCount({}, state, entry, nil, {}, nil, 5) == 3)
        covers = 9
        check("never past the automatic count", CC.pickedCraftCount({}, state, entry, nil, {}, nil, 5) == 5)
        check("nothing chosen: nil", CC.pickedCraftCount({}, { picks = { Make = {} } }, entry, nil, {}, nil, 5) == nil)
    end
    check("wire: the tab caps the most by the choice", has(CTS, "CC.pickedCraftCount(playerObj, state, entry, bench, containers")
        and has(CTS, "most = math.min(most or 1, chk.pickMost)") and has(CTS, "rd.maxBatchQty = most"))
end

-- ---------------------------------------------------------------------------
section("C12: every category is a pad stop")
-- ---------------------------------------------------------------------------
do
    local scroll = cutFn(CCS, "function CC.catScrollTo(")
    local rows = cutFn(CCS, "local function catRowFocusables(")
    local chunk, err = load(scroll and rows and (scroll .. rows .. "\nreturn catRowFocusables\n"),
        "local CC = ...\nlocal DD_ROW_H, DD_MAX_VIS = 20, 14\n", "CraftingCore.lua (category stops)")
    check("category stops cut and load", chunk ~= nil, err)
    if chunk then
        local catRowFocusables = chunk(CC)
        local cats = {}
        for i = 1, 24 do cats[i] = { id = "c" .. i } end
        local state = { categoryList = cats, catDropdownScroll = 0, _ddGeo = { x = 10, y = 100, w = 200 } }
        local els = catRowFocusables(state, "craft")
        check("24 categories, 24 stops", #els == 24, #els)
        check("row 15 sits just under the 14th", els[15].y == els[14].y + 20)
        check("rows out of view take no other zone's moves", els[15].offscreen == true and els[14].offscreen == nil)
        els[15].onFocus({}, els[15])
        check("landing on row 15 scrolls one", state.catDropdownScroll == 1, state.catDropdownScroll)
        els[24].onFocus({}, els[24])
        check("landing on the last shows it", state.catDropdownScroll == 10, state.catDropdownScroll)
        local els2 = catRowFocusables(state, "craft")
        check("laid out again from the scroll", els2[11].y == 100 and els2[24].y == 100 + 13 * 20, els2[11].y)
        els2[1].onFocus({}, els2[1])
        check("back to the top", state.catDropdownScroll == 0)
    end
end

-- ---------------------------------------------------------------------------
section("C13: B on the card shuts the card, not the craft")
-- ---------------------------------------------------------------------------
do
    local piece = cutFn(CCS, "function CC.padBack(")
    local chunk, err = load(piece, "local CC = ...\n", "CraftingCore.lua (padBack)")
    check("padBack cut and loads", chunk ~= nil, err)
    if chunk then
        chunk(CC)
        local exited, closed = 0, 0
        CC.exitAltMode = function(s) exited = exited + 1; s.altSlotName = nil end
        CC.closeCraft = function(s) closed = closed + 1; s.selected = nil end
        local state = { selected = "Make", altSlotName = "Thread" }
        check("in the alternatives: B leaves them", CC.padBack(state) == true and exited == 1 and closed == 0)
        check("then B shuts the card", CC.padBack(state) == true and closed == 1)
        check("the focus goes back to the row", state._gpReturnTo == "row:Make")
        check("a stale stop still never cancels", CC.padBack(state) == true)
    end
    check("wire: the card's stops take B", has(CCS, "el.onCancel = function(w, _el) return CC.padBack(state) end"))
    check("wire: before the station's leave", (CCS:find("return CC.padBack(state)", 1, true) or 1e9)
        < (CCS:find("ZeD.Stations.addLeaveCancel(elements, win, prefix)", 1, true) or 0))
end

-- ---------------------------------------------------------------------------
section("C18: the game's favourites are pins")
-- ---------------------------------------------------------------------------
do
    local block = cutBetween(CCS, "function CC.togglePin(", "function CC.isPinned(")
    local chunk, err = load(block, "local CC = ...\n", "CraftingCore.lua (pins)")
    check("pin block cut and loads", chunk ~= nil, err)
    if chunk then
        chunk(CC)
        CC.MAX_PINS = 8
        local md = {}
        CC.savePins = function(w, key, sk) md[key] = {}; for _, n in ipairs(w[sk] or {}) do md[key][#md[key] + 1] = n end end
        BaseCraftingLogic = { getFavouriteModDataString = function(n) return "fav:" .. n end }
        local win = { _playerObj = { getModData = function() return md end }, _craftPins = {} }
        md["fav:Rip"] = true
        local flat = { { name = "Rip" }, { name = "Saw" } }
        check("a game favourite joins the pins", CC.mergeGameFavourites(win, "ZeD_CraftPins", "_craftPins", flat) == true
            and win._craftPins[1] == "Rip")
        check("asked again: nothing new", CC.mergeGameFavourites(win, "ZeD_CraftPins", "_craftPins", flat) == false)
        CC.togglePin(win, "Saw", "ZeD_CraftPins", "_craftPins", "dirty")
        check("a pin sets the game's flag", md["fav:Saw"] == true)
        CC.togglePin(win, "Rip", "ZeD_CraftPins", "_craftPins", "dirty")
        check("an unpin clears the game's flag", md["fav:Rip"] == false)
        check("and the pin goes", #win._craftPins == 1 and win._craftPins[1] == "Saw")
        CC.togglePin(win, "Saw", "ZeD_CraftPins", "_craftPins", "dirty")
        md["fav:Rip"] = true
        CC.mergeGameFavourites(win, "ZeD_CraftPins", "_craftPins", flat)
        md["fav:Rip"] = false   -- cleared in the game's own window
        CC.mergeGameFavourites(win, "ZeD_CraftPins", "_craftPins", flat)
        check("a favourite cleared in the game leaves the pins", #win._craftPins == 0, #win._craftPins)
        local bwin = { _playerObj = win._playerObj, _buildPins = {} }
        md["fav:Saw"] = nil
        CC.togglePin(bwin, "Saw", "ZeD_BuildPins", "_buildPins", "dirty")
        check("Build's pins leave the game's flag alone", md["fav:Saw"] == nil)
    end
    check("wire: the render takes in the favourites", has(CCS, "CC.mergeGameFavourites(win, config.pinKey"))
end

print("cb_craft_fixes_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
