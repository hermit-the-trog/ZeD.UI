-- ZeDUI/tools/qa/cb_calls_craft_sim.lua  (the director's calls on the Crafting tab, Nov 25 2026, "1 on all"),
-- checked on the real pieces of CraftingCore.lua and CraftingTab.lua with no game running.
--   call 1  the alternatives list chooses the exact item: under the chosen type, one row per item; a craft
--           uses the chosen items and no other (the batch stops where they run out); none chosen, the type
--           pick or the game's own pick stands
--   call 2  a progress band on the craft card while its craft runs; its X (or the pad's A) stops that craft
--   call 3  the card's tool rows say what the game's input tooltip says, in the game's own words
--   call 4  the Craft tab's pins have no cap: the 9th pin drops nothing
-- Run from the repo root:  lua51 ZeDUI/tools/qa/cb_calls_craft_sim.lua
-- It prints FAIL lines and a last line "cb_calls_craft_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]cb_calls_craft_sim%.lua$", "")

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
local EN = {
    IGUI_CraftingWindow_MayDegrade = "May damage tool.",
    IGUI_CraftingWindow_MayDegradeLight = "Slight chance of damaging tool.",
    IGUI_CraftingWindow_SharpnessCheck = "May dull tool.",
    IGUI_CraftingWindow_IsWorn = "Must be worn.",
    IGUI_CraftingWindow_IsSharpenable = "Must have Sharpness lower than its condition. <br> If too low, repair it first.",
}
getText = function(k) return EN[k] or k end

-- ---------------------------------------------------------------------------
section("call 4: the 9th pin drops nothing")
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
        for i = 1, 12 do CC.togglePin(win, "R" .. i, "ZeD_CraftPins", "_craftPins", "dirty") end
        check("twelve pins: all twelve kept", #win._craftPins == 12, #win._craftPins)
        check("the first pin is still there", win._craftPins[1] == "R1")
        check("its game flag stays set", md["fav:R1"] == true)
        check("the saved list holds all twelve", #(md.ZeD_CraftPins or {}) == 12)
        CC.togglePin(win, "R5", "ZeD_CraftPins", "_craftPins", "dirty")
        check("an unpin still takes only that one", #win._craftPins == 11 and md["fav:R5"] == false)
        local bwin = { _playerObj = win._playerObj, _buildPins = {} }
        for i = 1, 9 do CC.togglePin(bwin, "B" .. i, "ZeD_BuildPins", "_buildPins", "dirty") end
        check("Build has no cap either: all nine kept (the director's call 4)", #bwin._buildPins == 9 and bwin._buildPins[1] == "B1")
    end
    check("wire: no pin cap left in togglePin", not has(CCS, "#pins >= CC.MAX_PINS"))
end

-- ---------------------------------------------------------------------------
section("call 2: the progress band and its Cancel")
-- ---------------------------------------------------------------------------
do
    local block = cutBetween(CCS, "-- A craft in progress (QA cb sweep", "--- An any-surface recipe in Hand mode")
    local chunk, err = load(block, "local CC = ...\n", "CraftingCore.lua (busy block)")
    check("busy block cut and loads", chunk ~= nil, err)
    if chunk then
        CC.incrementCraftCount = function() end
        chunk(CC)
        local Q = { queue = {}, resets = 0 }
        function Q:indexOf(a) for i, v in ipairs(self.queue) do if v == a then return i end end return -1 end
        function Q:removeFromQueue(a) local i = self:indexOf(a); if i ~= -1 then table.remove(self.queue, i) end end
        function Q:resetQueue() self.queue = {}; self.resets = self.resets + 1 end
        ISTimedActionQueue = { getTimedActionQueue = function() return Q end }
        local function mk(delta)
            local a = { delta = delta, stops = 0, cancels = 0 }
            function a:getJobDelta() return self.delta end
            function a:forceStop() self.stops = self.stops + 1; Q:resetQueue() end
            function a:forceCancel() self.cancels = self.cancels + 1 end
            return a
        end
        local win = { _playerObj = {} }
        check("nothing queued: no band", CC.craftProgress(win) == nil)
        local walk, a1, a2 = mk(0.9), mk(0.4), mk(0)
        Q.queue = { walk, a1, a2 }; Q.current = walk
        CC.trackCraftActions(win, { a1, a2 }, "MakeRope")
        local name, pct = CC.craftProgress(win)
        check("a walk first: the band shows, at 0", name == "MakeRope" and pct == 0, tostring(name) .. " " .. tostring(pct))
        Q.queue = { a1, a2 }; Q.current = a1
        name, pct = CC.craftProgress(win)
        check("the craft runs: its share done", name == "MakeRope" and pct == 0.4, pct)
        a1.delta = 1.7
        name, pct = CC.craftProgress(win)
        check("the share never passes 1", pct == 1, pct)
        -- the head still holds the craft just done while the queue runs the next (QA cb_calls): the band reads the running one
        a1.delta = 1; Q.current = a2; a2.delta = 0.25
        name, pct = CC.craftProgress(win)
        check("the band reads the action the queue runs now, not the head", pct == 0.25, pct)
        Q.current = a1; a1.delta = 1.7
        -- Cancel while it runs: the game's stop
        check("Cancel stops the running craft", CC.cancelCraft(win) == true and a1.stops == 1)
        check("the game's stop clears what was behind it", #Q.queue == 0 and Q.resets == 1)
        check("the list is cleared", win._craftQueued == nil and win._craftQueuedRecipe == nil)
        check("no band after", CC.craftProgress(win) == nil)
        -- Cancel while the walk still runs: ZeD's waiting crafts leave the queue, the walk goes on
        local walk2, b1, b2 = mk(0.2), mk(0), mk(0)
        Q.queue = { walk2, b1, b2 }
        CC.trackCraftActions(win, { b1, b2 }, "MakeRope")
        check("Cancel during the walk takes the crafts out", CC.cancelCraft(win) == true)
        check("the walk stays, the crafts are gone", #Q.queue == 1 and Q.queue[1] == walk2 and b1.cancels == 1 and b2.cancels == 1)
        check("nothing to cancel: false", CC.cancelCraft(win) == false)
        -- busy ending clears the recipe too
        local c1 = mk(0)
        Q.queue = { c1 }
        CC.trackCraftActions(win, { c1 }, "Saw")
        Q.queue = {}
        check("all done: busy ends and the name goes", CC.craftBusy(win) == false and win._craftQueuedRecipe == nil)
        -- an action not yet begun: the queue is reset instead
        local d1 = mk(0)
        function d1:forceStop() error("no action") end
        Q.queue = { d1 }
        CC.trackCraftActions(win, { d1 }, "Saw")
        local r0 = Q.resets
        CC.cancelCraft(win)
        check("a craft with no game action yet: the queue is reset", Q.resets == r0 + 1)
    end

    -- the band itself
    local piece = cutBetween(CCS, "local _progRect, _progOpts = {}, {}", "-- ============================================================================\n-- MAIN ORCHESTRATOR")
    local chunk2, err2 = load(piece, "local CC, NO_FOCUS_OPTS = ...\n", "CraftingCore.lua (renderCraftProgress)")
    check("band piece cut and loads", chunk2 ~= nil, err2)
    if chunk2 then
        chunk2(CC, {})
        local drawn = nil
        ZeD.Atoms = { drawProgressBand = function(panel, x, y, w, mode, label, pct, timeStr, rect, compact, opts)
            drawn = { mode = mode, label = label, pct = pct, compact = compact, focus = opts.focus }
            rect.x, rect.y, rect.w, rect.h = x + w - 20, y + 4, 16, 16
            return 30
        end }
        local running = nil
        CC.craftProgress = function() if running then return running, 0.5 end return nil end
        local state = { selected = "MakeRope", zones = {}, _selEntry = { displayName = "Make Rope" } }
        local cfg = { prefix = "craft" }
        local win = { _playerObj = {} }
        check("no craft: no band, no height", CC.renderCraftProgress(nil, win, state, cfg, 0, 0, 240) == 0 and state._progOn == false)
        running = "MakeRope"
        local h = CC.renderCraftProgress(nil, win, state, cfg, 0, 0, 240)
        check("its craft runs: the band, its height", h == 30 and state._progOn == true)
        check("accent, named for the recipe, the share", drawn and drawn.mode == "active" and drawn.label == "Make Rope" and drawn.pct == 0.5)
        check("the card's narrow look", drawn and drawn.compact == true)
        local z = state.zones[#state.zones]
        check("its X stamps the Cancel zone", z and z.type == "craftCancel" and z.w == 16)
        state._gpFocusedId = "craft:craftCancel"
        state.zones = {}
        CC.renderCraftProgress(nil, win, state, cfg, 0, 0, 240)
        check("the pad's mark on the X when focused", drawn and drawn.focus ~= nil)
        running = "Saw"
        check("another recipe's craft: not on this card", CC.renderCraftProgress(nil, win, state, cfg, 0, 0, 240) == 0)
        running = "MakeRope"
        check("not on Build", CC.renderCraftProgress(nil, win, state, { prefix = "build" }, 0, 0, 240) == 0)
        check("not on the Journal", CC.renderCraftProgress(nil, win, state, { prefix = "craft", readOnly = true }, 0, 0, 240) == 0)
    end
    check("wire: the band over the split card", has(CCS, "local ph = CC.renderCraftProgress(panel, win, state, config, cardX + T.px(1), curY, cardW - T.px(1))")
        and has(CCS, "curY + ph, cardW - T.px(1), panesH - ph"))
    check("wire: the band over the stacked card", has(CCS, "CC.renderCraftCard(panel, cardX, cardY + ph, cardW, cardH - ph"))
    check("wire: a click on the X cancels", has(CCS, "elseif zone.type == \"craftCancel\" then\n                -- the progress band's X: stops the running craft (the director's call 2)\n                CC.cancelCraft(win, playerObj or win._playerObj)"))
    check("wire: the pad's stop cancels", has(CCS, "id = prefix .. \":craftCancel\",") and has(CCS, "onActivate = function(w, el) CC.cancelCraft(w, w._playerObj) end,"))
    check("wire: the stops are rebuilt as the band comes and goes", has(CTS, "tostring(state._progOn)"))
    check("wire: the tab names the queued recipe", has(CTS, "CC.trackCraftActions(win, queued, recipeName)"))
    check("wire: the chosen-inputs start names it too", has(CCS, "CC.trackCraftActions(win, queued, name)"))
end

-- ---------------------------------------------------------------------------
section("call 3: the tool rows' notes")
-- ---------------------------------------------------------------------------
do
    local piece = cutBetween(CCS, "CC.INPUT_NOTES = {", "function CC.renderCraftCard(")
    local chunk, err = load(piece, "local CC = ...\n", "CraftingCore.lua (input notes)")
    check("notes piece cut and loads", chunk ~= nil, err)
    if chunk then
        chunk(CC)
        local function script(flags)
            local s = {}
            for _, n in ipairs(CC.INPUT_NOTES) do
                local key = n[1]
                s[key] = function() return flags[key] == true end
            end
            s.isKeep = function() return flags.keep == true end
            return s
        end
        local saw = { inputRef = script({ keep = true, mayDegrade = true, mayDegradeLight = true, mayDegradeVeryLight = true, sharpnessCheck = true }) }
        local n = CC.inputNotes(saw)
        check("a kept saw: may damage, slight chance, may dull", #n == 3 and n[1] == "May damage tool." and n[2] == "Slight chance of damaging tool." and n[3] == "May dull tool.", #n)
        check("one key said once (Light and VeryLight share it)", #n == 3)
        check("asked once, kept on the def", CC.inputNotes(saw) == n)
        local used = { inputRef = script({ mayDegrade = true, isWorn = true }) }
        local u = CC.inputNotes(used)
        check("not kept: the wear notes are left out, as the game's", #u == 1 and u[1] == "Must be worn.", #u)
        local blade = { inputRef = script({ keep = true, isSharpenable = true }) }
        local b = CC.inputNotes(blade)
        check("the game's <br> reads as a space", #b == 1 and not b[1]:find("<", 1, true) and b[1]:find("condition. If", 1, true) ~= nil, b[1])
        check("no script: no notes", #CC.inputNotes({}) == 0)
        check("the game's own keys", CC.INPUT_NOTES[2][2] == "IGUI_CraftingWindow_MayDegrade" and CC.INPUT_NOTES[8][2] == "IGUI_CraftingWindow_IsWorn")
    end
    check("wire: the card reads the notes for tool and kept rows", has(CCS, "if def and (ing.isTool or ing.isKeep) then\n                local notes = CC.inputNotes(def)"))
    check("wire: the Craft tab only", has(CCS, "if config.prefix == \"craft\" and not config.readOnly and not state.reqCollapsed and entry.inputDefs then"))
    check("wire: the notes take room in the card's height", has(CCS, "inputsH = inputsH + #lines * noteStep + T.px(2)"))
    check("wire: drawn under the row", has(CCS, "curY = curY + #lines * noteStep + T.px(2)"))
end

-- ---------------------------------------------------------------------------
section("call 1: the exact item")
-- ---------------------------------------------------------------------------
do
    local picksPiece = cutBetween(CCS, "function CC.pickFor(", "-- A row of the open alternatives list")
    local chunk, err = load(picksPiece, "local CC = ...\n", "CraftingCore.lua (picks)")
    check("picks piece cut and loads", chunk ~= nil, err)
    local logicPiece = cutBetween(CCS, "-- Kahlua has no next(); whether a table has any entry.", "-- The names (and the game's item scripts) of a recipe's mapped outputs")
    local chunk2, err2 = load(logicPiece, "local CC = ...\n", "CraftingCore.lua (picked craft)")
    check("picked-craft piece cut and loads", chunk2 ~= nil, err2)
    if chunk and chunk2 then
        chunk(CC)
        chunk2(CC)
        -- items and containers
        local nextId = 0
        local function item(ft, cont)
            nextId = nextId + 1
            local it = { ft = ft, id = nextId, cont = cont }
            function it:getFullType() return self.ft end
            function it:getID() return self.id end
            function it:getContainer() return self.cont end
            return it
        end
        local function container()
            local c = { list = {} }
            function c:getItems() local l = self.list; return { size = function() return #l end, get = function(_, j) return l[j + 1] end } end
            return c
        end
        local inv, far = container(), container()
        local P = {}
        for i = 1, 4 do P[i] = item("Base.Plank", inv); inv.list[#inv.list + 1] = P[i] end
        local farPlank = item("Base.Plank", far); far.list[1] = farPlank
        local saw = item("Base.Saw", inv); inv.list[#inv.list + 1] = saw
        local containers = { size = function() return 1 end, get = function() return inv end }
        -- the game's handcraft logic, in manual select, as far as the picks use it
        ResourceType = { Item = "Item" }
        ArrayList = { new = function()
            local l = {}
            return { add = function(_, v) l[#l + 1] = v end, size = function() return #l end, get = function(_, i) return l[i + 1] end, _l = l }
        end }
        local plankIn = { need = 2, name = "plank", getResourceType = function() return "Item" end }
        local sawIn = { need = 1, name = "saw", getResourceType = function() return "Item" end }
        HandcraftLogic = { new = function()
            local L = { slots = {}, filter = nil }
            local function slot(s)
                local d = L.slots[s]
                if not d then
                    d = { items = {}, script = s }
                    function d:isInputItemsSatisfied() return #self.items >= self.script.need end
                    L.slots[s] = d
                end
                return d
            end
            function L:setContainers() end
            function L:setRecipe() end
            function L:setManualSelectInputs() end
            function L:autoPopulateInputs()
                -- the game's own fill: any plank, the saw
                for _, it in ipairs(inv.list) do
                    if it.ft == "Base.Plank" and #slot(plankIn).items < 2 then table.insert(slot(plankIn).items, it) end
                    if it.ft == "Base.Saw" and #slot(sawIn).items < 1 then table.insert(slot(sawIn).items, it) end
                end
            end
            function L:setManualSelectInputScriptFilter(s) self.filter = s end
            function L:getRecipeData() return { getDataForInputScript = function(_, s) return slot(s) end } end
            function L:clearManualInputsFor(d) d.items = {} end
            function L:offerInputItem(it)
                local d = slot(self.filter)
                local okType = (self.filter == plankIn and it.ft == "Base.Plank") or (self.filter == sawIn and it.ft == "Base.Saw")
                if okType and not d:isInputItemsSatisfied() then d.items[#d.items + 1] = it end
            end
            function L:canPerformCurrentRecipe() return slot(plankIn):isInputItemsSatisfied() and slot(sawIn):isInputItemsSatisfied() end
            function L:isCharacterInRangeOfWorkbench() return true end
            function L:getManualInputsFor(s, list) for _, it in ipairs(slot(s).items) do list:add(it) end return list end
            return L
        end }
        local lastLogic = nil
        ISHandcraftAction = { FromLogic = function(l) lastLogic = l; return { logic = l } end }
        local entry = { name = "Shelf", recipe = {}, inputDefs = {
            { inputRef = plankIn, amount = 2 },
            { inputRef = sawIn, amount = 1, isTool = true, isKeep = true } } }
        local state = { picks = {}, itemPicks = {} }

        -- the toggles
        CC.togglePick(state, "Shelf", 1, "Base.Plank")
        check("a type pick", CC.pickFor(state, "Shelf", 1) == "Base.Plank" and CC.itemPicksFor(state, "Shelf", 1) == nil)
        CC.toggleItemPick(state, "Shelf", 1, P[3])
        CC.toggleItemPick(state, "Shelf", 1, P[4])
        local l = CC.itemPicksFor(state, "Shelf", 1)
        check("two items chosen, in order", l and #l == 2 and l[1] == P[3] and l[2] == P[4])
        check("isItemPicked", CC.isItemPicked(state, "Shelf", 1, P[3]) and not CC.isItemPicked(state, "Shelf", 1, P[1]))
        local sigA = CC.pickSig(state, "Shelf", 2)
        CC.toggleItemPick(state, "Shelf", 1, P[4])
        check("chosen again: cleared", #CC.itemPicksFor(state, "Shelf", 1) == 1)
        check("the pick key changes with the items", CC.pickSig(state, "Shelf", 2) ~= sigA)
        CC.toggleItemPick(state, "Shelf", 1, P[4])

        -- the craft uses the chosen items
        local a, lg = CC.pickedCraftAction({}, state, entry, nil, containers, nil, nil)
        local got = lg and lg.slots[plankIn].items or {}
        check("the craft uses the chosen planks", a ~= nil and #got == 2 and got[1] == P[3] and got[2] == P[4], #got)
        check("the unchosen slot keeps the game's pick", lg and lg.slots[sawIn].items[1] == saw)
        check("two chosen: one craft", CC.pickedCraftCount({}, state, entry, nil, containers, nil, 5) == 1)
        CC.toggleItemPick(state, "Shelf", 1, P[1])
        CC.toggleItemPick(state, "Shelf", 1, P[2])
        check("four chosen: two crafts", CC.pickedCraftCount({}, state, entry, nil, containers, nil, 5) == 2)
        -- one chosen only: never filled from other planks
        state.itemPicks.Shelf[1] = { P[1] }
        check("one chosen of two needed: refused, not filled from others", CC.pickedCraftAction({}, state, entry, nil, containers, nil, nil) == nil)
        -- an item out of reach is not offered
        state.itemPicks.Shelf[1] = { P[1], farPlank }
        check("a chosen item out of reach: not used", CC.pickedCraftAction({}, state, entry, nil, containers, nil, nil) == nil)
        -- a chosen tool is used by every craft of the batch
        state.itemPicks.Shelf[1] = nil
        CC.toggleItemPick(state, "Shelf", 2, saw)
        check("a chosen saw: the type pick follows it", CC.pickFor(state, "Shelf", 2) == "Base.Saw")
        check("a chosen tool serves the whole batch", CC.pickedCraftCount({}, state, entry, nil, containers, nil, 5) == 2)
        -- the type row again: type and items cleared
        CC.togglePick(state, "Shelf", 2, "Base.Saw")
        check("the type again clears its items", CC.pickFor(state, "Shelf", 2) == nil and CC.itemPicksFor(state, "Shelf", 2) == nil)
        -- an item of another type switches the type and drops the old items
        CC.togglePick(state, "Shelf", 1, "Base.Plank")
        CC.toggleItemPick(state, "Shelf", 1, P[1])
        local other = item("Base.Log", inv)
        CC.toggleItemPick(state, "Shelf", 1, other)
        local l2 = CC.itemPicksFor(state, "Shelf", 1)
        check("another type: the type follows, the old items go", CC.pickFor(state, "Shelf", 1) == "Base.Log" and #l2 == 1 and l2[1] == other)
        -- item details
        local d = { IsDrainable = function() return true end, getCurrentUsesFloat = function() return 0.25 end }
        check("a drainable: its uses left", CC.itemDetail(d) == "25%")
        local worn = { IsDrainable = function() return false end, getConditionMax = function() return 10 end, getCondition = function() return 7 end }
        check("a worn tool: its condition", CC.itemDetail(worn) == "7/10")
        local fresh = { IsDrainable = function() return false end, getConditionMax = function() return 10 end, getCondition = function() return 10 end }
        check("a whole one: nothing", CC.itemDetail(fresh) == "")
    end
    check("wire: the alternatives list keeps each item of a type", has(CCS, "items = {},   -- each item of the type in reach"))
    check("wire: item rows under the chosen type", has(CCS, "CC.drawAltItemRow(panel, state, it, n, x, curY, contentW, ROW_H, y, h)"))
    check("wire: their height counted", has(CCS, "totalH = totalH + hdrH + (#owned + itemRowsN) * ROW_H"))
    check("wire: a click chooses the item", has(CCS, "CC.toggleItemPick(state, state.selected, state.altSlotIdx, zone.item)"))
    check("wire: the pad's A chooses the item", has(CCS, "id = prefix .. \":altItem:\" .. tostring(z.id),") and has(CCS, "CC.toggleItemPick(state, state.selected, state.altSlotIdx, el.item)"))
    check("wire: the stops are rebuilt as the item rows come and go", has(CTS, "tostring(state._altItemN or 0)"))
    check("wire: a fresh card clears the chosen items", has(CCS, "state.picks = {}   -- a fresh recipe starts on the game's own choice of ingredients\n    state.itemPicks = {}"))
    check("wire: the craft offers the chosen items", has(CCS, "fillPickSlot(logic, script, containers, fullType, skip, chosen, playerObj)"))
    check("wire: a chosen item on the ground more than a square off is out of reach (the shared floor container)", has(CCS, "and not floorTooFar(it, playerObj) then")
        and has(CCS, "if CC.floorTooFar and CC.floorTooFar(item, playerObj) then return false end"))
    check("wire: the band's Max keys on the items", has(CTS, "local sig = CC.pickSig(state, entry.name, #(entry.inputDefs or {}))"))
    check("wire: the mapped outputs see the items", has(CCS, "CC.resolveMappedOutputs(playerObj, entry, p, containers, ip)"))
    check("wire: the card's row counts the chosen items in reach", has(CCS, "shownHave = CC.pickedInReach(state, playerObj, chosenItems)"))
    check("wire: only a used-up chosen item is dropped, one out of reach stays (the craft refuses)", has(CCS, "if not c then table.remove(list, i) end   -- (used up: in no container)"))
    check("wire: no item rows on a Build card (its picks are by type)", has(CCS, "local pickedType = (state._pickOn and not ownPicks) and CC.pickFor(state, state.selected, state.altSlotIdx) or nil"))
    check("wire: the World window's pad stops follow the list's sections", has(srcOf("ZeD_WorldWindow.lua"), '.. ":" .. tostring(stk._sections) .. ":" .. tostring(stk._sectionsTotalH or 0)'))
end

print("cb_calls_craft_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
