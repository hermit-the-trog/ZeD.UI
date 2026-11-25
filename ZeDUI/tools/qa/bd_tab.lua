-- ZeDUI/tools/qa/bd_tab.lua  (Nov 25 2026, QA; tag bd_tab): the World window's Build ("Building") tab, the whole
-- gamut, in the style of the Equipment and Thermal sweeps. Its spec is the map, qa/audits/2026-11-25_map_build.md
-- (section 5: suspicions B1-B20; section 3: the states to sweep). Run after zedqa_prelude.lua and rt_kit.lua (the
-- manifest's line). grep "ZEDQA bd_tab". Helpers are copied from bx_craft, th_tab, color_tabs, vk3_craft, rt_pad and
-- bx_context: the script stands alone.
--
-- Run mode: the debug cheat is off for the whole script (ISBuildMenu.cheat and the player's BuildCheat, as bx_craft
-- does: -debug sets ISBuildMenu.cheat, which skips the walk, the hammer and the after-place block, B17), timed
-- actions are not instant; all three put back as found. God mode on (left on), invincible on (as found after).
-- The character's own building things (hammers, planks, nails, branches, sticks, rags, rope, blowtorches, sheet
-- metal, welding rods) are set aside for the run, so every case counts only what it gives; his hands are emptied.
-- A crate (carpentry_01_16) is laid on a tile beside him: the occupied tile (the invalid spot) and "the crate beside
-- him" for the materials. A clear tile two away is the valid spot; another clear tile two away the second one.
-- Placing goes through the game's own DoTileBuilding with the cursor's build flag set, as a mouse click's release
-- does (ISBuildingObject.lua:97-176); walks run at x1, the build action at x20 (ZEDQA_SPEED 3).
-- No controller is plugged into the QA PC: for the pad ZeD's input mode is locked to the controller
-- (Detector.setLockedMode, put back as found); presses on ZeD's window go through FocusManager's QA hook and its own
-- dispatch (Focus.qaButton + dispatchJoypadDown, th_tab's way); presses on the game's cursor go through the game's
-- own controller press with no focus (JoypadControllerData:onPressButtonNoFocus, rt_pad's way), which hands them to
-- getCell():getDrag(pn):onJoypadPressButton (JoyPadSetup.lua:364-366), as a real pad's do.
-- The pointer is faked only where a case says so: getMouseX / getMouseY answer a point (th_tab's mouseAt).
--
-- Checks (FAIL = a plain bug, with its values; NOTE = data for a design call; SKIP = could not be staged here, said
-- why; B<n> = the map's suspicion):
--   1 list     each Category lists its own structures, all of them (Show: All); a Category picked by the mouse from
--              the select; search: no match empties the list, an ingredient's name finds the recipe, its category
--              word finds it; the card's have counts equal what the game's containers hold, and the row says
--              buildable exactly when the game would (a cross, carried); B9: a broken hammer (Butter Churn) and a
--              blowtorch with 1 use where 4 are needed (the metal feeding trough): ZeD's card must mark the input
--              the game finds short, never all green with Build gray and no reason; no "needs a table / bench" line
--              on a build card; B10: a recipe short of skill (Wood Crate (Shoddy), Carpentry set to 0): the card
--              names the skill it needs, and does not call a recipe that needs no learning "Unknown"; NOTE what the
--              preview card says and whether Show: Known hides it
--   2 mouse    from the preview card (the card's icon): its facing stepped twice with ">", then its Build: B6, the
--              cursor starts on the face the preview shows; the cursor is ISBuildIsoEntity, counted once; the tint:
--              valid on the clear tile, invalid on the crate's; placed once, it builds; B2: the cursor is still
--              usable for a second placement (the game re-arms it, ISBuildPanel.lua:414-422); right-click on the
--              world (the game's world menu, ISMenuContextWorld.lua:52) cancels it; B4: Escape with the pointer in
--              the window, outside under 2 s, outside after 2 s (the tab side unpinned) and with the window pinned:
--              one Escape drops the cursor, as the game's (MainScreen.lua:1713-1716)
--   3 pad      A on the row opens the card and the focus lands on Build (B12 data); A on Build starts the cursor
--              (NOTE the windows roll up); B1: A on the cursor over a valid tile places (the prompt says A Build);
--              B6: RB turns the cursor the way the preview's ">" steps (the preview's face order from the game's
--              build object) and LB undoes it; B on the cursor cancels it; B11: B on the card, no cursor, closes it
--   4 windows  B5, with the cursor up: the World window is not drawn over the tile being placed on (the game hides
--              its window while placing, ISBuildPanel.lua:428-445); closing the World window clears the cursor (the
--              game's close does, ISBuildPanel.lua:405-407); NOTE a tab switch; Furniture opened replaces it
--   5 material B7, the cross's three inputs: all carried, all in a worn bag, all on the floor at his feet, all in the
--              crate beside him, split two ways, one short: the row matches the game's answer and the card's have
--              counts match the game's containers; then two far builds (the materials in the crate, then on the
--              floor, the cross placed 6 to 9 tiles away): a build that runs to its end stands (FAIL when the
--              consume failed and the action built nothing), and its materials come from containers in reach where
--              he builds (FAIL when they were taken from the crate or the floor he walked away from)
--   6 twice    B3: one set carried, placed, then Build pressed at once again: no usable cursor while the build is
--              queued (the game grays Build while one runs, ISWidgetBuildControl.lua:163-172); whatever runs, nothing
--              is lost (used = built); NOTE how many build actions ran; Build pressed twice in one frame: NOTE B15
--              (the count is per cursor, not per build)
--   7 grayed   B8, nothing carried: the card's Build reads gray and its press starts nothing, by the mouse and by
--              the pad; NOTE that its press zone is still stamped; NOTE B12 (A on a grayed row's card)
--   8 language B18: every UI_ZeD_ key the Build tab asked for while this script ran, read in each language's
--              UI.json: NOTE the keys only English has and those some languages lack (no FAIL); NOTE the category
--              labels the search does not match (it matches the English word)
--   9 layout   the 480 card and the 220 card (held in: the window's width cap lowered), the text size found and
--              Large: every word the card draws stays inside the card; every ZeD window on screen; pictures
--              bd_<card>_<size>_<theme>_<w>x<h> in Dark, then the 480 card in Light and High contrast
--   each case  no Lua error over it (the game's count and the tab's own throws, caught by the wrappers)
-- Not covered here (the map's suspicions that need no in-game proof or another script): B13 (catalog once a session),
-- B14 (no vanilla build script has a tool slot), B16 (the alternatives list), B19 (a real bumper chord), B20 (an item's
-- Build list), wall coverings, the 9th pin, entry points, safe mode, Lite, MP safehouses.
-- Puts back: the cursor (getCell():setDrag(nil, pn), checked gone), the queue, game speed 1, everything built or laid
-- (each named if left), everything given (in the inventory, the bag, the crate, on the floor), his own things set
-- aside, his hands, a bag worn for the case, the skills (level and XP) and any recipe learned, the cheats, the build
-- counts and pins, the tab's Show, Sort, Category, search and card, the pins of the window's halves, the theme, the
-- text size, the width cap, the input lock, the pointer, the wrappers, the window pair and its tab and layout, the
-- character home. NOT put back: nothing known.

if not (RT and RT.make) then
    print("ZEDQA bd_tab ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA bd_tab VERDICT FAIL 1")
    print("ZEDQA bd_tab DONE")
    return
end

local Q = RT.make("bd_tab")
Q.maxMs = 1080000                    -- (the put-back runs before 18 minutes are up)
local S = { p = RT.p, pn = RT.pn, back = {}, found = {}, built = {}, given = {}, cg = {}, had = {}, floorHad = {},
            stash = {}, cnt = {}, xp = {}, learned = {}, trKeys = {}, mats = {}, renders = 0, tabErrs = 0, dead = false }
local H = {}
local C = {}
S.F = RT.focus()
S.CC = ZeD and ZeD.CraftingCore
S.BT = ZeD and ZeD.BuildingTab
S.WW = ZeD_WorldWindow
S.Det = ZeD and ZeD.Input and ZeD.Input.Detector
S.CRATE = "carpentry_01_16"
-- the recipes (by the game's recipe name; a fallback by words and shape when a build names them otherwise)
S.R = {
    cross  = { name = "RuggedCross", words = { "cross" } },
    churn  = { name = "ChurnBucket", words = { "churn" } },
    crate  = { name = "Wood_Crate_Lvl1", words = { "crate" } },
    trough = { name = "FeedingTroughDoubleMetal", words = { "trough" } },
}
-- the cross's three inputs (entity_rugged_cross: a branch, a long stick, a rag; no tool, no skill, four faces)
S.MAT = { branch = "Base.TreeBranch2", stick = "Base.LongStick", rag = "Base.RippedSheets" }
S.MAT_ORDER = { "branch", "stick", "rag" }
-- his own things of these types are set aside (and any hammer, by its tag)
S.OWN = { "Base.TreeBranch2", "Base.WoodenStick2", "Base.LongStick", "Base.Sapling", "Base.RippedSheets",
          "Base.RippedSheetsDirty", "Base.Twine", "Base.Rope", "Base.SheetRope", "Base.Plank", "Base.Nails",
          "Base.NailsBox", "Base.BlowTorch", "Base.SheetMetal", "Base.WeldingRods", "Base.Hammer", "Base.HammerStone",
          "Base.BallPeenHammer", "Base.ClubHammer" }
S.RING1 = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
S.RING2 = { { 2, 0 }, { 0, 2 }, { -2, 0 }, { 0, -2 }, { 2, 2 }, { -2, 2 }, { 2, -2 }, { -2, -2 }, { 2, 1 }, { 1, 2 }, { -2, 1 }, { 1, -2 } }
S.FAR = { { 8, 0 }, { 0, 8 }, { -8, 0 }, { 0, -8 }, { 7, 3 }, { -7, 3 }, { 7, -3 }, { 6, 0 }, { 0, 6 }, { -6, 0 }, { 0, -6 }, { 9, 0 } }
S.LANGS = { "AR", "CA", "CH", "CN", "CS", "DA", "DE", "EN", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT", "JP", "KO",
            "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
-- the Build tab's own keys, asked for or not while the script runs (the map's B18 names the first four)
S.KEYS = { "UI_ZeD_Craft_AllStructures", "UI_ZeD_Craft_OpenInBuild", "UI_ZeD_Craft_NeedsSurface", "UI_ZeD_Craft_NeedsBench",
           "UI_ZeD_World_TabBuilding", "UI_ZeD_World_SearchStructures", "UI_ZeD_Craft_BadgeUnknown" }
S.THEMES = { { key = "dark", tag = "dark" }, { key = "light", tag = "light" }, { key = "hicon", tag = "hc" } }
-- a stand-in controller for the game's own press with no focus (rt_pad's): the press goes to the player's cursor
S.jd = { player = S.pn, id = 0, focus = nil }
S.ctl = JoypadControllerData and setmetatable({ joypad = S.jd }, { __index = JoypadControllerData }) or nil

if not (S.p and S.CC and S.BT and S.WW and S.F) then
    Q.check(false, "the player, ZeD's Building tab, CraftingCore, the World window and FocusManager are loaded")
    Q.start()
    return
end

-- ===================================================================== small helpers
function H.note(s) Q.say("NOTE " .. tostring(s)) end
function H.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function H.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function H.idle(n) Q.step(n, function() end) end
-- time, not frames: cond asked every 100 ms, at most ms; fn(true) when cond came true
function H.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 400000, function()
        if S.dead then return true end
        local now = getTimestampMs()
        st.t = st.t or now
        if st.last and now - st.last < 100 then return false end
        st.last = now
        local ok, r = pcall(cond)
        if ok and r then st.ok = true; return true end
        return now - st.t >= ms
    end, function() if S.dead then return end; fn(st.ok == true) end)
end
-- a Java or Lua method called only when it is there (ObjectCards' call): nil when missing or when it throws
function H.call(o, m, ...)
    if o == nil then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end
function H.fl(v) return math.floor(tonumber(v) or 0) end
function H.join(t, max)
    max = max or 8
    local out = {}
    for i = 1, math.min(#t, max) do out[#out + 1] = tostring(t[i]) end
    local s = table.concat(out, "; ")
    if #t > max then s = s .. " (+" .. (#t - max) .. " more)" end
    if s == "" then s = "none" end
    return s
end
function H.speed(n) if ZEDQA_SPEED then pcall(ZEDQA_SPEED, n) else pcall(setGameSpeed, n) end end
function H.queue()
    local q = nil
    pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end)
    return (q and q.queue) or {}
end
function H.qlen() return #H.queue() end
function H.head() local a = H.queue()[1]; return a and tostring(a.Type) or "none" end
function H.stop() pcall(function() ISTimedActionQueue.clear(S.p) end) end
function H.drag() local d = nil; pcall(function() d = getCell():getDrag(S.pn) end); return d end
function H.noDrag() pcall(function() if getCell():getDrag(S.pn) then getCell():setDrag(nil, S.pn) end end) end
function H.dragType(d) if d == nil then return "none" end; return tostring(d.Type) end
function H.isBuildCur(d) return d ~= nil and d.Type == "ISBuildIsoEntity" end
function H.md(name)
    local v = 0
    pcall(function() local md = S.p:getModData(); v = (md.ZeD_BuildCounts and md.ZeD_BuildCounts[name]) or 0 end)
    return v
end

-- ===================================================================== things
function H.isItem(it) local ok = false; if it ~= nil then pcall(function() ok = instanceof(it, "InventoryItem") end) end; return ok end
function H.ft(it) local f = "?"; if H.isItem(it) then pcall(function() f = it:getFullType() end) end; return f end
function H.walkInv(inv, out, depth)
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        out[#out + 1] = it
        if depth < 4 and instanceof(it, "InventoryContainer") then
            local sub = nil
            pcall(function() sub = it:getInventory() end)
            if sub then H.walkInv(sub, out, depth + 1) end
        end
    end
end
function H.all() local out = {}; pcall(H.walkInv, S.p:getInventory(), out, 0); return out end
-- a thing given for this case (taken away at the case's end, and in the put-back)
function H.track(it)
    if not H.isItem(it) then return nil end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    S.given[#S.given + 1] = it
    S.cg[#S.cg + 1] = it
    return it
end
function H.give(ft)
    local it = RT.give(ft)
    if it then S.given[#S.given + 1] = it; S.cg[#S.cg + 1] = it end
    return it
end
function H.giveN(ft, n) local got = 0; for _ = 1, n do if H.give(ft) then got = got + 1 end end; return got end
function H.rmItem(it)
    if not H.isItem(it) then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    pcall(function() if S.p:isEquippedClothing(it) then S.p:removeWornItem(it) end end)
    local wo = nil
    pcall(function() wo = it:getWorldItem() end)
    if wo then
        local sq = nil
        pcall(function() sq = wo:getSquare() end)
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
        pcall(function() wo:removeFromWorld() end)
        pcall(function() wo:removeFromSquare() end)
        pcall(function() it:setWorldItem(nil) end)
    end
    local c = nil
    pcall(function() c = it:getContainer() end)
    if c then pcall(function() c:Remove(it) end) end
end
-- is a thing still anywhere (in a container, or laid in the world)?
function H.still(it)
    if not H.isItem(it) then return false end
    local held, laid = false, false
    pcall(function() local c = it:getContainer(); held = c ~= nil and c:contains(it) end)
    pcall(function() local wo = it:getWorldItem(); laid = wo ~= nil and wo:getSquare() ~= nil end)
    return held or laid
end
-- his own building things set aside for the run (not worn, held or on the belt), given back after
function H.isHammer(it)
    local yes = false
    pcall(function() if ItemTag and ItemTag.HAMMER then yes = it:hasTag(ItemTag.HAMMER) and true or false end end)
    return yes
end
function H.stashOwn()
    local want, kept = {}, {}
    for _, ft in ipairs(S.OWN) do want[ft] = true end
    for _, it in ipairs(H.all()) do
        if want[H.ft(it)] or H.isHammer(it) then
            local c, free = nil, false
            pcall(function() c = it:getContainer(); free = it:getAttachedSlot() == -1 and not it:isEquipped() end)
            if c and free and pcall(function() c:Remove(it) end) then
                S.stash[#S.stash + 1] = { it = it, c = c }
            else
                kept[#kept + 1] = H.ft(it)
            end
        end
    end
    return #S.stash, kept
end
function H.unstash()
    local lost = 0
    for _, s in ipairs(S.stash) do
        pcall(function() if s.it:getContainer() == nil then s.c:AddItem(s.it) end end)
        local back = false
        pcall(function() back = s.it:getContainer() ~= nil end)
        if not back then lost = lost + 1 end
    end
    S.stash = {}
    return lost
end
-- the skills: every perk's level and XP kept, set back after (bx_combat's xpBack)
function H.xpSnap()
    pcall(function()
        local xp = S.p:getXp()
        for i = 0, PerkFactory.PerkList:size() - 1 do
            local perk = PerkFactory.PerkList:get(i)
            S.xp[#S.xp + 1] = { perk = perk, xp = xp:getXP(perk), lvl = S.p:getPerkLevel(perk) }
        end
    end)
end
function H.xpBack()
    local grew, left = 0, 0
    pcall(function()
        local xp = S.p:getXp()
        for _, r in ipairs(S.xp) do
            if math.abs(xp:getXP(r.perk) - r.xp) > 0.001 or S.p:getPerkLevel(r.perk) ~= r.lvl then
                grew = grew + 1
                pcall(function()
                    S.p:setPerkLevelDebug(r.perk, r.lvl)
                    xp:setXPToLevel(r.perk, r.lvl)
                    local now = xp:getXP(r.perk)
                    -- (either way: a level's floor can sit above the XP found, so the gap may be negative)
                    if math.abs(r.xp - now) > 0.001 then xp:AddXPNoMultiplier(r.perk, r.xp - now) end
                end)
                local nx, nl2 = xp:getXP(r.perk), S.p:getPerkLevel(r.perk)
                if math.abs(nx - r.xp) > 0.01 or nl2 ~= r.lvl then
                    left = left + 1
                    S.xpLeftText = (S.xpLeftText or "") .. tostring(r.perk) .. " level " .. tostring(nl2) .. " (found " .. tostring(r.lvl) .. ") xp "
                        .. string.format("%.2f", nx) .. " (found " .. string.format("%.2f", r.xp) .. "); "
                end
            end
        end
    end)
    pcall(function() SyncXp(S.p) end)
    return grew, left
end
function H.setLevel(perkKey, lvl)
    local pk = Perks and Perks[perkKey]
    if pk then pcall(function() S.p:setPerkLevelDebug(pk, lvl) end) end
end
function H.level(perkKey)
    local v = nil
    local pk = Perks and Perks[perkKey]
    if pk then pcall(function() v = S.p:getPerkLevel(pk) end) end
    return v
end

-- ===================================================================== the World window and the tab
function H.bst() local w = RT.ww(); return w and w._buildState or nil end
function H.data() local w = RT.ww(); return w and w._buildCache or nil end
function H.row(name) local d = H.data(); return (d and d.byName and name) and d.byName[name] or nil end
function H.showing() local s = false; pcall(function() s = S.WW.isTabShowing("build", S.pn) end); return s and true or false end
function H.tab(id)
    if RT.worldTab(id) then return true end
    return pcall(S.WW.openTab, S.pn, id)
end
function H.zone(kind, id)
    local st = H.bst()
    local lg = st and st._listGeo
    for _, z in ipairs((st and st.zones) or {}) do
        if z.type == kind and (id == nil or z.id == id) and (z.w or 0) > 0 and (z.h or 0) > 0 then
            local inView = kind ~= "recipeRow" or lg == nil or (z.y >= lg.viewY and z.y + z.h <= lg.viewY + lg.viewH)
            if inView then return z end
        end
    end
    return nil
end
-- a click on a zone, through the tab's own click handler, as a click on the drawer lands there (bx_craft's)
function H.click(z, what, right)
    local fn = right and S.BT.onRightClick or S.BT.onClick
    local ok, err = pcall(fn, RT.ww(), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    if not ok then Q.check(false, tostring(what) .. ": the click ran without an error", err) end
    return ok
end
function H.open(name, what)
    local st = H.bst()
    if not (st and name) then return false end
    if st.selected == name then return true end
    local z = H.zone("recipeRow", name)
    if z then
        H.click(z, what)
    else
        local ok, err = pcall(S.CC.openCraft, st, name)
        if not ok then Q.check(false, tostring(what) .. ": the card opened without an error", err) end
        H.note(tostring(what) .. ": " .. tostring(name) .. " has no row in view, its card is opened from code")
    end
    return st.selected == name
end
function H.closeCard() local st = H.bst(); if st and st.selected then pcall(S.CC.closeCraft, st) end end
-- the Build key on the card's band, pressed by the mouse
function H.bPress(label)
    local z = H.zone("action_build")
    if not z then return false end
    return H.click(z, tostring(label) .. ": Build")
end
function H.settled(rd) return rd ~= nil and rd.status ~= "unlocked" end
function H.zedCan(rd) return rd ~= nil and rd.status == "craftable" and rd.learned ~= false end
function H.cardDrawn(name)
    local st = H.bst()
    return st ~= nil and st.selected == name and st._cardDrawnAt ~= nil and getTimestampMs() - st._cardDrawnAt < 500
end
function H.search(text)
    local f = RT.ww() and RT.ww()._buildSearch
    if not (f and f.input) then return false end
    return pcall(function() f.input:setText(text or "") end)
end
function H.show(id) local st = H.bst(); if st then pcall(S.CC.setShow, st, id) end end
-- ZeD's name for a recipe (the game's name, else the first whose name and words and shape fit)
function H.rname(key)
    local r = S.R[key]
    if not r then return nil end
    if r.found ~= nil then return r.found or nil end
    local d = H.data()
    if not (d and d.byName and #(d.recipes or {}) > 0) then return nil end
    if d.byName[r.name] then r.found = r.name; return r.name end
    for nm, rd in pairs(d.byName) do
        local txt = string.lower(tostring(rd.entry and rd.entry.displayName or "") .. " " .. tostring(nm))
        local all = true
        for _, w in ipairs(r.words) do if not string.find(txt, w, 1, true) then all = false end end
        if all and (r.pred == nil or r.pred(rd.entry)) then r.found = nm; return nm end
    end
    r.found = false
    return nil
end
S.R.crate.pred = function(e) return (e.requiredLevel or 0) > 0 and not e.needLearn end
S.R.churn.pred = function(e)
    for _, d in ipairs(e.inputDefs or {}) do if d.validTypes and d.validTypes["Base.Hammer"] then return true end end
    return false
end
S.R.trough.pred = function(e)
    for _, d in ipairs(e.inputDefs or {}) do if d.validTypes and d.validTypes["Base.BlowTorch"] then return true end end
    return false
end
-- the steps that put a recipe's card up the player's way: its name typed in the search, its row clicked;
-- T.ready once the card draws with its Build key and the row has settled
function H.openSteps(T, key, lab)
    H.step(1, function()
        T.name = H.rname(key)
        local rd = T.name and H.row(T.name)
        if not rd then return end
        local st = H.bst()
        if st and st.selected == T.name then T.open = true; return end
        H.search(tostring(rd.entry.displayName))
    end)
    H.wait(3000, function() return T.name == nil or T.open or H.zone("recipeRow", T.name) ~= nil end, function()
        if not (T.name and H.row(T.name)) then return end
        if not T.open then T.open = H.open(T.name, lab) end
    end)
    H.wait(6000, function()
        if not T.open then return true end
        return H.cardDrawn(T.name) and H.zone("action_build") ~= nil and H.settled(H.row(T.name))
    end, function(ok)
        T.ready = (T.open and ok) and true or false
        if T.name == nil then Q.skip(lab, "the Building tab lists no " .. tostring(S.R[key].name) .. " for this character")
        elseif not T.ready then Q.check(false, lab .. ": staging: the card opens on " .. tostring(T.name), "open " .. tostring(T.open)) end
    end)
end

-- ===================================================================== containers and the game's answers
function H.refreshLoot()
    pcall(function() getPlayerLoot(S.pn):refreshBackpacks() end)
    pcall(function() getPlayerInventory(S.pn):refreshBackpacks() end)
    pcall(function() triggerEvent("OnContainerUpdate") end)
    local w = RT.ww()
    if w then w._containersDirty = true; w._buildContainerAt = nil; w._buildTypeCache = nil end
end
-- the containers the game's own build window uses (ISBuildPanel:updateContainers), asked from the game itself
function H.conts()
    local list = nil
    pcall(function()
        if getPlayerInventory(S.pn) ~= nil and getPlayerLoot(S.pn) ~= nil then
            list = ISInventoryPaneContextMenu.getContainers(S.p)
        end
    end)
    return list
end
function H.countIn(conts, validTypes)
    local n = 0
    if not (conts and validTypes) then return 0 end
    pcall(function()
        for i = 0, conts:size() - 1 do
            local items = conts:get(i):getItems()
            for j = 0, items:size() - 1 do
                if validTypes[items:get(j):getFullType()] then n = n + 1 end
            end
        end
    end)
    return n
end
function H.inConts(it)
    local conts = H.conts()
    local has = false
    if not (conts and it) then return false end
    pcall(function()
        for i = 0, conts:size() - 1 do if conts:get(i):contains(it) then has = true end end
    end)
    return has
end
-- a BuildLogic set up as ZeD's startBuild and the game's panel set theirs up, with the game's containers now
function H.gameLogic(entry)
    local l = nil
    if not (entry and entry.recipe) then return nil end
    pcall(function()
        local g = BuildLogic.new(S.p, nil, nil)
        local list = g:getAllBuildableRecipes()
        g:setRecipes(list)
        g:setRecipe(entry.recipe)
        g:setContainers(H.conts())
        l = g
    end)
    return l
end
function H.gameCan(entry)
    local can = nil
    local l = H.gameLogic(entry)
    if l then pcall(function() can = l:canPerformCurrentRecipe() and true or false end) end
    return can
end
-- the inputs the game finds short (by ZeD's name for them), read from the game's own recipe data
function H.gameShort(entry)
    local out, read = {}, false
    local l = H.gameLogic(entry)
    if not l then return out, false end
    pcall(function()
        l:setManualSelectInputs(true)
        l:autoPopulateInputs()
        local rdata = l:getRecipeData()
        for _, def in ipairs(entry.inputDefs or {}) do
            local script = def.inputRef
            if script and script:getResourceType() == ResourceType.Item then
                local d = rdata:getDataForInputScript(script)
                if d then
                    read = true
                    if not d:isInputItemsSatisfied() then out[#out + 1] = tostring(def.name) end
                end
            end
        end
    end)
    return out, read
end
-- the card's have counts against what the game's containers hold (true, "" when every row agrees)
function H.haveAgree(rd)
    local conts = H.conts()
    if not (rd and rd.ingredients and conts) then return false, "no rows or no containers" end
    local bad = {}
    for _, ing in ipairs(rd.ingredients) do
        local n = H.countIn(conts, ing.validTypes)
        if n ~= ing.have then bad[#bad + 1] = tostring(ing.name) .. " ZeD " .. tostring(ing.have) .. ", the game's containers " .. n end
    end
    return #bad == 0, table.concat(bad, "; ")
end
function H.rowsText(rd)
    local t = {}
    for _, ing in ipairs((rd and rd.ingredients) or {}) do t[#t + 1] = tostring(ing.name) .. " " .. tostring(ing.have) .. "/" .. tostring(ing.need) end
    return table.concat(t, ", ")
end

-- ===================================================================== squares and objects
function H.sq(x, y) local s = nil; pcall(function() s = getCell():getGridSquare(x, y, 0) end); return s end
function H.free(sq)
    local good = false
    pcall(function()
        good = sq ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree()
            and sq:getObjects():size() <= 1 and sq:getWorldObjects():size() == 0 and sq:getVehicleContainer() == nil
    end)
    return good
end
function H.homeSq() return H.sq(S.hx, S.hy) end
function H.goHome()
    pcall(function()
        S.p:setX(S.hx + 0.5); S.p:setY(S.hy + 0.5); S.p:setZ(0)
        S.p:setLastX(S.hx + 0.5); S.p:setLastY(S.hy + 0.5); S.p:setLastZ(0)
    end)
    H.refreshLoot()
end
function H.dist(sq) return math.sqrt((sq:getX() - S.hx) ^ 2 + (sq:getY() - S.hy) ^ 2) end
function H.screenOf(sq)
    local sx, sy = 0, 0
    pcall(function()
        local x, y, z = sq:getX() + 0.5, sq:getY() + 0.5, sq:getZ()
        sx, sy = math.floor(isoToScreenX(S.pn, x, y, z)), math.floor(isoToScreenY(S.pn, x, y, z))
    end)
    return sx, sy
end
function H.snapObjs(cx, cy, r)
    local set = {}
    for y = cy - r, cy + r do
        for x = cx - r, cx + r do
            local sq = H.sq(x, y)
            local objs = sq and sq:getObjects()
            for i = 0, (objs and objs:size() or 0) - 1 do set[objs:get(i)] = true end
        end
    end
    return set
end
function H.newObjs(before, cx, cy, r)
    local out = {}
    for o in pairs(H.snapObjs(cx, cy, r)) do
        local wi = false
        pcall(function() wi = instanceof(o, "IsoWorldInventoryObject") end)
        if not before[o] and not wi then out[#out + 1] = o end
    end
    return out
end
function H.snapWorld(set)
    for y = S.hy - 12, S.hy + 12 do
        for x = S.hx - 12, S.hx + 12 do
            local sq = H.sq(x, y)
            local wos = sq and sq:getWorldObjects()
            for i = 0, (wos and wos:size() or 0) - 1 do set[wos:get(i)] = true end
        end
    end
end
function H.objName(o) local n = "?"; pcall(function() n = o:getSprite():getName() end); return tostring(n) end
function H.objOn(o)
    local on = false
    pcall(function() local sq = o:getSquare(); on = sq ~= nil and sq:getObjects():contains(o) end)
    return on
end
function H.rmObj(o)
    if not o then return end
    local sq = nil
    pcall(function() sq = o:getSquare() end)
    if sq then
        pcall(function() sq:transmitRemoveItemFromSquare(o) end)
        pcall(function() if o:getObjectIndex() >= 0 then sq:RemoveTileObject(o) end end)
        pcall(function() sq:getObjects():remove(o) end)
        pcall(function() sq:getSpecialObjects():remove(o) end)
        pcall(function() sq:RecalcProperties() end)
    end
    pcall(function() o:removeFromWorld() end)
    pcall(function() o:removeFromSquare() end)
end
-- a crate with the sprite's container on sq (color_tabs' mkObj)
function H.mkCrate(sq)
    local made = nil
    pcall(function()
        local o = IsoObject.new(getCell(), sq, S.CRATE)
        o:createContainersFromSpriteProperties()
        if not o:getContainer() then return end
        sq:AddTileObject(o)
        pcall(function() o:getContainer():setExplored(true) end)
        made = o
    end)
    return made
end
function H.crateInv() local c = nil; if S.crate then pcall(function() c = S.crate:getContainer() end) end; return c end
-- a bag on his back: the one he wears (kept), else a school bag worn for the run
function H.bagUp()
    if S.bagInv then return true end
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do
            local it = wi:get(i):getItem()
            if not S.bagInv and instanceof(it, "InventoryContainer") then S.bag = it; S.bagInv = it:getInventory() end
        end
    end)
    if S.bagInv then return true end
    local it = H.give("Base.Bag_Schoolbag")
    if not it then return false end
    local loc = nil
    pcall(function() loc = it:canBeEquipped() end)
    if loc and tostring(loc) ~= "" then pcall(function() S.p:setWornItem(loc, it) end) end
    local worn = false
    pcall(function() worn = S.p:isEquippedClothing(it) end)
    if worn then S.bag, S.bagMine = it, true; pcall(function() S.bagInv = it:getInventory() end) end
    -- (the case's clean-up would take it: it stays for the run, taken in the put-back)
    for i = #S.cg, 1, -1 do if S.cg[i] == it then table.remove(S.cg, i) end end
    return S.bagInv ~= nil
end

-- ===================================================================== the cross's materials, staged
function H.putMat(ft, where)
    local it = nil
    if where == "inv" then it = H.give(ft)
    elseif where == "bag" then pcall(function() it = S.bagInv:AddItem(ft) end); H.track(it)
    elseif where == "floor" then pcall(function() it = H.homeSq():AddWorldInventoryItem(ft, 0.5, 0.5, 0) end); H.track(it)
    elseif where == "crate" then pcall(function() it = H.crateInv():AddItem(ft) end); H.track(it)
    end
    return H.isItem(it) and it or nil
end
-- spec: { branch = "inv" | "bag" | "floor" | "crate", stick = ..., rag = ... }; n sets
function H.stageMat(spec, n)
    for _ = 1, (n or 1) do
        for _, k in ipairs(S.MAT_ORDER) do
            local where = spec[k]
            if where then
                local it = H.putMat(S.MAT[k], where)
                if it then S.mats[#S.mats + 1] = { it = it, where = where, kind = k } end
            end
        end
    end
    H.refreshLoot()
end
function H.clearMat() for _, m in ipairs(S.mats) do H.rmItem(m.it) end; S.mats = {}; H.refreshLoot() end
function H.matGone()
    local gone = {}
    for _, m in ipairs(S.mats) do if not H.still(m.it) then gone[#gone + 1] = m.kind .. " (" .. m.where .. ")" end end
    return gone
end

-- ===================================================================== the cursor
-- a placement as a click's release on sq: the game's own DoTileBuilding with the cursor's build flag set
function H.placeAt(cur, sq, label)
    local ok, err = pcall(function()
        cur.square = sq
        cur.isLeftDown = false
        cur.canBeBuild = cur:isValid(sq) and true or false
        cur.build = true
        DoTileBuilding(cur, false, sq:getX(), sq:getY(), sq:getZ(), sq)
    end)
    if not ok then Q.check(false, tostring(label) .. ": the placement (the game's DoTileBuilding) ran without an error", err) end
    return ok
end
function H.valid(cur, sq) local v = nil; if cur and sq then pcall(function() v = cur:isValid(sq) and true or false end) end; return v end
function H.faceName(cur)
    local nm = nil
    if not cur then return nil end
    pcall(function() local f = cur:getFace(); if f then nm = tostring(f:getFaceName()) end end)
    return nm
end
-- the build object's faces in the order the preview card steps them (ObjectCardPreview buildData: getFace 0..3)
function H.faceNames(entry)
    local out = {}
    pcall(function()
        -- (setRecipes first, as BuildingTab.startBuild does: without it getSelectedBuildObject threw, QA B5-8)
        local l = BuildLogic.new(S.p, nil, nil)
        local list = l:getAllBuildableRecipes()
        l:setRecipes(list)
        l:setRecipe(entry.recipe)
        local info = l:getSelectedBuildObject()
        if not info then return end
        local single = H.call(info, "isSingleFace")
        for i = 0, 3 do
            local f = info:getFace(i)
            if f then
                out[#out + 1] = tostring(f:getFaceName())
                if single then break end
            end
        end
    end)
    return out
end
-- a far tile the cursor takes (6 to 9 away)
function H.farSq(cur)
    for _, d in ipairs(S.FAR) do
        local sq = H.sq(S.hx + d[1], S.hy + d[2])
        if sq and H.free(sq) and H.valid(cur, sq) then return sq end
    end
    return nil
end
-- after a placement: the walk at x1, the build action at x20, until the queue is empty. T.go set by the caller;
-- T.acts counts the build actions that started, T.new the objects that stand after (kept for the put-back)
function H.runBuild(T, ms)
    H.wait(ms or 40000, function()
        if not T.go then return true end
        local a = H.queue()[1]
        if a and a.Type == "ISBuildAction" then
            if T.lastAct ~= a then T.lastAct = a; T.acts = (T.acts or 0) + 1 end
            if T.inReach == nil and T.watch then H.refreshLoot(); T.inReach = T.watch() end
            H.speed(3)
        else
            H.speed(1)
        end
        return H.qlen() == 0
    end, function(ok)
        H.speed(1)
        if not T.go then return end
        T.done = ok
        T.new = H.newObjs(T.before, S.hx, S.hy, 10)
        for _, o in ipairs(T.new) do S.built[#S.built + 1] = o end
        if not ok then H.stop() end
    end)
end
function H.rmNew(T) for _, o in ipairs((T and T.new) or {}) do H.rmObj(o) end end

-- ===================================================================== keys, the pointer, menus
function H.pauseUp()
    local ms = MainScreen and MainScreen.instance
    local v = false
    if ms then pcall(function() v = ms:isVisible() end) end
    return v and true or false
end
function H.esc() return pcall(function() ToggleEscapeMenu(Keyboard.KEY_ESCAPE) end) end
function H.unpause()
    if not H.pauseUp() then return end
    pcall(function()
        local key = nil
        if KeybindId and KeybindId.MAIN_MENU then key = getCore():getKey(KeybindId.MAIN_MENU) end
        if key == nil or key == 0 then key = Keyboard.KEY_ESCAPE end
        ToggleEscapeMenu(key)
    end)
end
function H.mouseAt(sx, sy)
    if not S.mouse then S.mouse = { mx = getMouseX, my = getMouseY } end
    getMouseX = function() return sx end
    getMouseY = function() return sy end
end
function H.mouseBack()
    if not S.mouse then return end
    getMouseX, getMouseY = S.mouse.mx, S.mouse.my
    S.mouse = nil
end
function H.park() H.mouseAt(-9000, -9000) end
function H.closeMenu()
    local v = nil
    pcall(function() v = getPlayerContextMenu(S.pn) end)
    if not v then return end
    local zm = v._zedMenu
    if zm and zm.close then pcall(zm.close, zm) end
    pcall(function() if v:isVisible() and v.closeAll then v:closeAll() end end)
end
-- a right-click on the world at sq: the game's world menu, as the world's own right-click asks for it (bx_context's)
function H.rightClickWorld(sq)
    local sx, sy = H.screenOf(sq)
    local fl = nil
    pcall(function() fl = sq:getFloor() end)
    local ok, err = pcall(function() ISContextManager.getInstance().createWorldMenu(S.pn, fl, { fl }, sx, sy) end)
    H.closeMenu()
    return ok, err
end
-- the halves' pins (WindowHalves): found, set, back
function H.pinsFound() local w = RT.ww(); local s = w and w._halves; if s then return { inv = s.inv.pinned, drawer = s.drawer.pinned } end; return nil end
function H.pin(on) local w = RT.ww(); if w and ZeD.Halves then pcall(ZeD.Halves.setPin, w, nil, on) end end
function H.unroll()
    for _, w in ipairs({ RT.cw() or false, RT.ww() or false }) do
        if w then
            pcall(ZeD.Halves.showAll, w)
            pcall(function() if w.windowShaded then w._autoShaded = false; w:setWindowShaded(false) end end)
        end
    end
end
function H.pinsBack()
    local w = RT.ww()
    local f = S.found.pins
    if w and f and ZeD.Halves then
        pcall(ZeD.Halves.setPin, w, "inv", f.inv and true or false)
        pcall(ZeD.Halves.setPin, w, "drawer", f.drawer and true or false)
    end
    H.unroll()
end
function H.drawerRolled()
    local w = RT.ww()
    local s = w and w._halves
    return (s ~= nil and (s.drawer.rolled == true or s.foldTab ~= nil)) or (w ~= nil and w.windowShaded == true)
end
-- is the World window drawn over sq on screen? (and the words saying where)
function H.winOver(sq)
    local w = RT.ww()
    if not (w and sq) then return false, "no window or no tile" end
    local vis = false
    pcall(function() vis = w:isReallyVisible() end)
    local sx, sy = H.screenOf(sq)
    local x, y, ww, hh = 0, 0, 0, 0
    pcall(function() x, y, ww, hh = w:getAbsoluteX(), w:getAbsoluteY(), w:getWidth(), w:getHeight() end)
    pcall(function() hh = w:shownHeight() end)
    local over = vis and not w.windowShaded and sx >= x and sx < x + ww and sy >= y and sy < y + hh
    return over and true or false, string.format("tile %d,%d at %d,%d; window %d,%d %dx%d, visible %s, rolled %s",
        sq:getX(), sq:getY(), sx, sy, H.fl(x), H.fl(y), H.fl(ww), H.fl(hh), tostring(vis), tostring(w.windowShaded == true))
end

-- ===================================================================== the pad
function H.zopt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
function H.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function H.lockFound()
    local key = nil
    pcall(function()
        local o = H.zopt("inputModeLock")
        local keys = ZeD.Settings.inputLockKeys
        if o and keys then key = keys[o:getValue() or 1] end
    end)
    if key == nil then pcall(function() local md = S.p:getModData().ZeD_Gamepad; key = md and md.inputModeLock end) end
    return key or "auto"
end
function H.padOn()
    if not (S.Det and S.Det.setLockedMode) then return false end
    if S.lockWas == nil then S.lockWas = H.lockFound() end
    pcall(S.Det.setLockedMode, "gamepad")
    S.back.pad = true
    return true
end
function H.padOff()
    if not S.back.pad then return end
    S.back.pad = nil
    for _, b in ipairs({ "A", "B" }) do RT.pad(b, nil) end
    pcall(function()
        S.Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then S.Det.setLockedMode(S.lockWas) end
    end)
    pcall(S.F.releaseFocus, S.pn)
end
function H.padClaim()
    local w = RT.ww()
    if not w then return end
    pcall(S.F.releaseFocus, S.pn)
    pcall(S.F.claimFocus, w)
end
function H.focId() local w = RT.ww(); local e = nil; if w then pcall(function() e = S.F.getFocusedElement(w) end) end; return e and e.id or nil end
function H.focusOn(id)
    local w = RT.ww()
    local e = nil
    if w and S.F.focusWhere then pcall(function() e = S.F.focusWhere(w, "worldTabContent", function(el) return el.id == id end) end) end
    return e
end
-- a tap on ZeD's window: the QA hook holds the button, FocusManager's dispatch takes the press, up after 4 frames
function H.tap(name, gate)
    local st = {}
    H.step(1, function()
        if gate and not gate() then return end
        st.on = true
        RT.pad(name, true)
        RT.padDown(Joypad[name .. "Button"], RT.ww())
    end)
    H.step(4, function() if st.on then RT.pad(name, false) end end)
    H.step(4, function() if st.on then RT.pad(name, nil) end end)
end
-- a press on the game's cursor: the game's own controller press with no focus (to getDrag(pn):onJoypadPressButton)
function H.ctlPress(button)
    if not S.ctl then return false, "no JoypadControllerData" end
    local ok, err = pcall(JoypadControllerData.onPressButtonNoFocus, S.ctl, button)
    pcall(JoypadControllerData.onReleaseButton, S.ctl, button)
    return ok, err
end

-- ===================================================================== theme, text size, pictures (th_tab's)
function H.theme(key)
    local o = H.zopt("baseTheme")
    local i = nil
    for k, v in ipairs(ZeD.Settings.baseKeys or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, key, nil, nil)
    S.back.theme = true
end
function H.themeBack()
    if not S.back.theme then return end
    S.back.theme = nil
    local o = H.zopt("baseTheme")
    if o and S.found.baseIdx then pcall(function() o:setValue(S.found.baseIdx) end) end
    pcall(ZeD.applyTheme, S.found.base, nil, nil)
end
function H.sizeSet(key)
    local o = H.zopt("textSize")
    local i = nil
    for k, v in ipairs(ZeD.Settings.sizeKeys or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, nil, nil, key)
    S.back.size = true
end
function H.sizeBack()
    if not S.back.size then return end
    S.back.size = nil
    local o = H.zopt("textSize")
    if o and S.found.sizeIdx then pcall(function() o:setValue(S.found.sizeIdx) end) end
    pcall(ZeD.applyTheme, nil, nil, S.found.size)
end
function H.sizeTag()
    local w, h = 0, 0
    pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end)
    return H.fl(w) .. "x" .. H.fl(h)
end
function H.shot(name, what)
    local st = {}
    H.step(1, function() st.had = S.mouse ~= nil; H.park() end)
    H.step(4, function()
        local file = name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then H.note("picture Zomboid/Screenshots/" .. file .. " | " .. what)
        else H.note("the picture " .. name .. " was not taken: " .. tostring(e)) end
        if not st.had then H.mouseBack() end
    end)
    Q.waitMs(1200)
end

-- ===================================================================== the draw, watched (wrappers on for the run)
-- S.card = { name, x, y, w, h, texts = { {s, x, y, font, right, centre} }, t }: the Build card's last drawn frame;
-- S.trKeys: every key ZeD.tr was asked for while the Build tab drew
function H.wrapOn()
    if S.w0 then return end
    local CC = S.CC
    S.w0 = { render = CC.render, card = CC.renderCraftCard, tr = ZeD.tr }
    local W = S.w0
    W.renderFn = function(panel, win, x, y, w, h, state, config, data)
        if not (config and config.prefix == "build") then return W.render(panel, win, x, y, w, h, state, config, data) end
        S.inBuild = true
        S.renders = S.renders + 1
        local ok, e = pcall(W.render, panel, win, x, y, w, h, state, config, data)
        S.inBuild = false
        if not ok then S.tabErrs = S.tabErrs + 1; S.tabErrLast = e; error(e, 0) end
    end
    W.cardFn = function(panel, x, y, w, h, state, config, rd, playerObj)
        if not (config and config.prefix == "build") then return W.card(panel, x, y, w, h, state, config, rd, playerObj) end
        local rec = { x = x, y = y, w = w, h = h, texts = {}, name = rd and rd.entry and rd.entry.name or nil, t = getTimestampMs() }
        local own = { rawget(panel, "drawText"), rawget(panel, "drawTextRight"), rawget(panel, "drawTextCentre") }
        local bd, br, bc = panel.drawText, panel.drawTextRight, panel.drawTextCentre
        if bd then
            panel.drawText = function(self, s, tx, ty, r, g, b, a, font)
                rec.texts[#rec.texts + 1] = { s = s, x = tx, y = ty, font = font }
                return bd(self, s, tx, ty, r, g, b, a, font)
            end
        end
        if br then
            panel.drawTextRight = function(self, s, tx, ty, r, g, b, a, font)
                rec.texts[#rec.texts + 1] = { s = s, x = tx, y = ty, font = font, right = true }
                return br(self, s, tx, ty, r, g, b, a, font)
            end
        end
        if bc then
            panel.drawTextCentre = function(self, s, tx, ty, r, g, b, a, font)
                rec.texts[#rec.texts + 1] = { s = s, x = tx, y = ty, font = font, centre = true }
                return bc(self, s, tx, ty, r, g, b, a, font)
            end
        end
        local ok, res = pcall(W.card, panel, x, y, w, h, state, config, rd, playerObj)
        rawset(panel, "drawText", own[1])
        rawset(panel, "drawTextRight", own[2])
        rawset(panel, "drawTextCentre", own[3])
        S.card = rec
        if not ok then error(res, 0) end
        return res
    end
    W.trFn = function(key, ...)
        if S.inBuild and type(key) == "string" then S.trKeys[key] = true end
        return W.tr(key, ...)
    end
    CC.render, CC.renderCraftCard, ZeD.tr = W.renderFn, W.cardFn, W.trFn
end
function H.wrapOff()
    local W = S.w0
    if not W then return end
    if S.CC.render == W.renderFn then S.CC.render = W.render end
    if S.CC.renderCraftCard == W.cardFn then S.CC.renderCraftCard = W.card end
    if ZeD.tr == W.trFn then ZeD.tr = W.tr end
    S.w0 = nil
end
-- the card's drawn words, fresh for name (nil when the card did not draw in the last second)
function H.cardTexts(name)
    local c = S.card
    if not (c and c.name == name and getTimestampMs() - c.t < 1000) then return nil end
    local out = {}
    for _, t in ipairs(c.texts) do out[#out + 1] = tostring(t.s) end
    return out
end
function H.hasText(texts, word)
    if not (texts and word and word ~= "") then return false end
    local w = string.lower(tostring(word))
    for _, s in ipairs(texts) do if string.find(string.lower(s), w, 1, true) then return true end end
    return false
end
function H.textW(t) local w = 0; pcall(function() w = ZeD.TM:MeasureStringX(t.font or UIFont.Small, tostring(t.s)) end); return w end

-- ===================================================================== case bookends
function H.caseStart(lab)
    H.step(1, function()
        S.e0 = H.errN()
        S.te0 = S.tabErrs
        S.cg = {}
        Q.say("case " .. lab)
    end)
end
function H.caseEnd(lab)
    H.step(2, function()
        H.speed(1)
        H.stop()
        H.noDrag()
        H.mouseBack()
        H.unpause()
        H.closeMenu()
        H.padOff()
        for _, o in ipairs(S.built) do if H.objOn(o) then H.rmObj(o) end end
        H.clearMat()
        for _, it in ipairs(S.cg) do H.rmItem(it) end
        S.cg = {}
        H.closeCard()
        H.search("")
        H.goHome()
        H.unroll()
    end)
    H.step(3, function()
        local e1 = H.errN()
        local te = S.tabErrs - (S.te0 or 0)
        Q.check((S.e0 == nil or e1 == nil or e1 == S.e0) and te == 0, lab .. ": no Lua error over the case",
            ((S.e0 and e1) and ((e1 - S.e0) .. " new") or "the game's count cannot be read") .. ", the tab's own " .. te
            .. (te > 0 and (" (" .. tostring(S.tabErrLast) .. ")") or ""))
        S.e0 = e1
        S.te0 = S.tabErrs
    end)
end

-- ===================================================================== setup
Q.step(2, function()
    S.dead = S.p:isDead() and true or false
    if S.dead then Q.check(false, "the character is alive (nothing is run on a dead one)"); return end
    if ZEDQA_HOME then ZEDQA_HOME("bd_tab") end
    H.speed(1)
    H.stop()
    H.noDrag()
    S.hx, S.hy = math.floor(S.p:getX()), math.floor(S.p:getY())
    for _, it in ipairs(H.all()) do S.had[it] = true end
    H.snapWorld(S.floorHad)
    S.handWas = { S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem() }
    pcall(function() if not S.p:isGodMod() then S.p:setGodMod(true); H.note("god mode was off: turned on and left on") end end)
    pcall(function() S.invWas = S.p:isInvincible() and true or false; S.p:setInvincible(true) end)
    pcall(function() S.instWas = S.p:isTimedActionInstantCheat(); S.p:setTimedActionInstantCheat(false) end)
    pcall(function() S.bcWas = S.p:isBuildCheat(); S.p:setBuildCheat(false) end)
    pcall(function() S.bmWas = ISBuildMenu.cheat; ISBuildMenu.cheat = false end)
    Q.say("setup: found ISBuildMenu.cheat " .. tostring(S.bmWas) .. ", BuildCheat " .. tostring(S.bcWas)
        .. ", instant actions " .. tostring(S.instWas) .. ": all three off for the run (B17)")
    H.xpSnap()
    local md = S.p:getModData()
    for _, key in ipairs({ "ZeD_BuildCounts", "ZeD_BuildPins" }) do
        if md[key] then
            local copy = {}
            for k, v in pairs(md[key]) do copy[k] = v end
            S.cnt[key] = copy
        end
    end
    S.pairWas = RT.isOpen()
    RT.pairOpen()
    if ZEDQA_LAYOUT_SNAP then S.layoutSnap = ZEDQA_LAYOUT_SNAP() end
    S.lockWas = H.lockFound()
    pcall(function() S.p:setPrimaryHandItem(nil); S.p:setSecondaryHandItem(nil) end)
    local aside, kept = H.stashOwn()
    H.note(aside .. " of his own building things are set aside for the run" .. (#kept > 0 and ("; kept (worn, held or on the belt): " .. H.join(kept)) or ""))
    S.keptOwn = kept
    S.found.base, S.found.baseIdx = ZeD.currentBase, H.optVal(H.zopt("baseTheme"))
    S.found.size, S.found.sizeIdx = ZeD.currentSize, H.optVal(H.zopt("textSize"))
    S.e0 = H.errN()
    H.wrapOn()
end)
H.step(10, function()
    local w = RT.ww()
    S.tabWas = w and w._activeTab
    H.tab("build")
end)
H.wait(10000, function()
    local d = H.data()
    return H.showing() and H.bst() ~= nil and d ~= nil and #(d.recipes or {}) > 0
end, function(ok)
    S.tabOk = Q.check(ok, "setup: the World window's Building tab opens with its rows", "showing " .. tostring(H.showing())
        .. ", rows " .. tostring(H.data() and #(H.data().recipes or {})))
    if not S.tabOk then return end
    local w, st = RT.ww(), H.bst()
    S.keep = { show = st.show, showAll = st.showAll, sort = st.sort, cat = st.activeCat }
    H.closeCard()
    H.show("all")
    st.activeCat = "all"
    S.found.pins = H.pinsFound()
    S.found.maxWinW = w._maxWinW
    -- the crate on a tile beside him (the occupied tile), two clear tiles two away
    for _, d in ipairs(S.RING1) do
        if not S.crate then
            local sq = H.sq(S.hx + d[1], S.hy + d[2])
            if sq and H.free(sq) then
                S.crate = H.mkCrate(sq)
                if S.crate then S.sqBad = sq end
            end
        end
    end
    for _, d in ipairs(S.RING2) do
        local sq = H.sq(S.hx + d[1], S.hy + d[2])
        if sq and H.free(sq) then
            if not S.sqClear then S.sqClear = sq elseif not S.sqClear2 then S.sqClear2 = sq end
        end
    end
    S.ok = Q.check(S.crate ~= nil and S.sqClear ~= nil and S.sqClear2 ~= nil,
        "setup: a crate laid beside him (the occupied tile) and two clear tiles two away",
        "crate " .. (S.sqBad and (S.sqBad:getX() .. "," .. S.sqBad:getY()) or "none") .. ", clear "
        .. (S.sqClear and (S.sqClear:getX() .. "," .. S.sqClear:getY()) or "none") .. " and "
        .. (S.sqClear2 and (S.sqClear2:getX() .. "," .. S.sqClear2:getY()) or "none") .. ", him at " .. S.hx .. "," .. S.hy)
    H.refreshLoot()
    local said = {}
    for _, k in ipairs({ "cross", "churn", "crate", "trough" }) do said[#said + 1] = k .. " " .. tostring(H.rname(k)) end
    Q.say("setup: recipes " .. table.concat(said, ", ") .. "; " .. #(H.data().recipes) .. " rows, "
        .. #(H.data().categories or {}) .. " categories; Carpentry " .. tostring(H.level("Woodwork")) .. ", Welding " .. tostring(H.level("MetalWelding")))
    RT.bounds(Q, "the Building tab")
end)

-- ===================================================================== 1. list and card
function C.list()
    H.caseStart("list")
    -- every Category in turn (the model's filter, Show: All): its own structures, all of them
    H.step(3, function()
        if not S.tabOk then return end
        local d, st, w = H.data(), H.bst(), RT.ww()
        local bad, n = {}, 0
        for _, c in ipairs(d.categories or {}) do
            if c.id ~= "all" then
                n = n + 1
                st.activeCat = c.id
                pcall(S.CC.refilter, d, st, st.config, w)
                local want, got, wrong = 0, 0, 0
                for _, e in ipairs(d.flatRecipes or {}) do if string.lower(tostring(e.category)) == c.id then want = want + 1 end end
                for _, rd in ipairs(st.filteredCache or {}) do
                    got = got + 1
                    if string.lower(tostring(rd.entry.category)) ~= c.id then wrong = wrong + 1 end
                end
                if got ~= want or wrong > 0 then bad[#bad + 1] = c.id .. " " .. got .. "/" .. want .. (wrong > 0 and (", " .. wrong .. " of another") or "") end
            end
        end
        st.activeCat = "all"
        st.filterDirty = true
        Q.check(n > 0 and #bad == 0, "list: each Category lists its own structures, all of them (Show: All)", n .. " categories" .. (#bad > 0 and ("; wrong: " .. H.join(bad)) or ""))
    end)
    -- one Category by the mouse: the select, then its second row
    H.step(3, function()
        if not S.tabOk then return end
        local z = H.zone("catDropdown")
        S.l = { z = z }
        if z then H.click(z, "list: the Category select") end
    end)
    H.idle(4)
    H.step(1, function()
        if not (S.tabOk and S.l and S.l.z) then Q.skip("list: a Category picked by the mouse", "no Category select drawn"); return end
        local st = H.bst()
        local geo = st._ddGeo
        local cats = st.categoryList or {}
        if not (st.catDropdownOpen and geo and cats[2]) then Q.check(false, "list: the Category select opens on a click", tostring(st.catDropdownOpen)); return end
        local rowH = ZeD.T.px(20)
        local scroll = st.catDropdownScroll or 0
        local okC = pcall(S.BT.onClick, RT.ww(), geo.x + 4, geo.y + (2 - 1 - scroll) * rowH + math.floor(rowH / 2))
        Q.check(okC and st.activeCat == cats[2].id and not st.catDropdownOpen, "list: a Category picked by the mouse from the select",
            "picked " .. tostring(st.activeCat) .. ", want " .. tostring(cats[2].id))
        st.activeCat = "all"
        st.filterDirty = true
    end)
    -- the search: no match, an ingredient's name, the category word
    H.step(2, function() if S.tabOk then H.search("zzqxj") end end)
    H.wait(3000, function() local st = H.bst(); return st and st.search == "zzqxj" and not st.filterDirty end, function(ok)
        if not S.tabOk then return end
        local st = H.bst()
        Q.check(ok and #(st.filteredCache or {}) == 0, "list: a search with no match empties the list", tostring(#(st.filteredCache or {})) .. " rows")
        S.l.churn = H.rname("churn")
        S.l.word = getItemNameFromFullType and getItemNameFromFullType("Base.Plank") or "Plank"
        H.search(S.l.word)
    end)
    H.wait(3000, function() local st = H.bst(); return st and st.search == S.l.word and not st.filterDirty end, function(ok)
        if not S.tabOk then return end
        local st = H.bst()
        local has = false
        for _, rd in ipairs(st.filteredCache or {}) do if rd.entry.name == S.l.churn then has = true end end
        if not S.l.churn then Q.skip("list: an ingredient's name finds the recipe", "no Butter Churn listed")
        else Q.check(ok and has, "list: the search for an ingredient's name (" .. tostring(S.l.word) .. ") finds " .. tostring(S.l.churn), #(st.filteredCache or {}) .. " rows") end
        local rd = S.l.churn and H.row(S.l.churn)
        S.l.cat = rd and tostring(rd.entry.category) or nil
        if S.l.cat then H.search(S.l.cat) end
    end)
    H.wait(3000, function() local st = H.bst(); return S.l.cat == nil or (st and st.search == S.l.cat and not st.filterDirty) end, function(ok)
        if not (S.tabOk and S.l.cat) then return end
        local st = H.bst()
        local has = false
        for _, rd in ipairs(st.filteredCache or {}) do if rd.entry.name == S.l.churn then has = true end end
        Q.check(ok and has, "list: the search for its category word (" .. S.l.cat .. ") finds " .. tostring(S.l.churn), #(st.filteredCache or {}) .. " rows")
        H.search("")
    end)
    -- have counts against the game's containers, and the row against the game: one cross set carried
    H.step(3, function() if S.ok then H.stageMat({ branch = "inv", stick = "inv", rag = "inv" }) end end)
    local T1 = {}
    H.openSteps(T1, "cross", "list, the cross carried")
    H.wait(6000, function()
        if not T1.ready then return true end
        local rd = H.row(T1.name)
        local agree = H.haveAgree(rd)
        return agree and H.zedCan(rd) == (H.gameCan(rd.entry) == true)
    end, function(ok)
        if not T1.ready then return end
        local rd = H.row(T1.name)
        local agree, why = H.haveAgree(rd)
        local g = H.gameCan(rd.entry)
        Q.check(agree, "list: the card's have counts equal what the game's containers hold (the cross carried)", agree and H.rowsText(rd) or why)
        Q.check(H.zedCan(rd) == (g == true), "list: the cross's row says buildable exactly when the game would", "ZeD " .. tostring(rd.status) .. ", the game " .. tostring(g))
        if g ~= true then H.note("list: the game does not build the cross with one set carried (staging)") end
        H.clearMat()
        H.closeCard()
    end)
    -- B9: a broken hammer, and a blowtorch with 1 use where 4 are needed
    H.step(2, function()
        if not S.ok then return end
        local hm = H.give("Base.Hammer")
        if hm then pcall(function() hm:setCondition(0) end) end
        S.l.broken = false
        pcall(function() S.l.broken = hm:isBroken() end)
        H.giveN("Base.Plank", 2)
        H.giveN("Base.Nails", 2)
        H.refreshLoot()
    end)
    local T2 = {}
    H.openSteps(T2, "churn", "B9, a broken hammer")
    -- (the game's answer for the row comes every 1.2 s, CC.logicScan; the card's short row is asked every 1 s)
    Q.waitMs(3000)
    H.wait(4000, function()
        if not T2.ready then return true end
        local rd = H.row(T2.name)
        return rd ~= nil and H.cardTexts(T2.name) ~= nil and (rd.status == "missing" or rd.status == "craftable")
    end, function() if T2.ready then C.b9(T2.name, "B9, a broken hammer (Butter Churn)", "hammer", S.l.broken) end end)
    H.step(2, function()
        if not S.ok then return end
        for _, it in ipairs(S.cg) do H.rmItem(it) end
        S.cg = {}
        H.closeCard()
        H.setLevel("MetalWelding", 3)
        local name = H.rname("trough")
        local rd = name and H.row(name)
        if rd and rd.entry.needLearn then
            local known = true
            pcall(function() known = S.p:isRecipeKnown(rd.entry.recipe, true) and true or false end)
            if not known then
                pcall(function() S.p:learnRecipe(rd.entry.recipe:getName()) end)
                S.learned[#S.learned + 1] = rd.entry.recipe:getName()
            end
        end
        local bt = H.give("Base.BlowTorch")
        S.l.uses = nil
        if bt then
            -- (one use left: the used delta set to one use's worth; methods asked for only where the item has them)
            local per = H.call(bt, "getUseDelta")
            if per then H.call(bt, "setUsedDelta", per) end
            S.l.uses = H.call(bt, "getCurrentUses")
        end
        H.giveN("Base.SheetMetal", 4)
        H.giveN("Base.WeldingRods", 2)
        H.refreshLoot()
    end)
    local T3 = {}
    H.openSteps(T3, "trough", "B9, a blowtorch nearly empty")
    Q.waitMs(3000)
    H.wait(4000, function()
        if not T3.ready then return true end
        local rd = H.row(T3.name)
        return rd ~= nil and H.cardTexts(T3.name) ~= nil and (rd.status == "missing" or rd.status == "craftable")
    end, function()
        if not T3.ready then return end
        H.note("B9: the blowtorch given holds " .. tostring(S.l.uses) .. " use(s); the trough needs 4")
        C.b9(T3.name, "B9, a blowtorch with " .. tostring(S.l.uses) .. " use where 4 are needed (metal feeding trough)", "blowtorch", true)
    end)
    -- B10: a recipe short of skill (Carpentry 0), no learning needed
    H.step(2, function()
        if not S.ok then return end
        for _, it in ipairs(S.cg) do H.rmItem(it) end
        S.cg = {}
        H.closeCard()
        H.setLevel("Woodwork", 0)
    end)
    H.idle(90)
    local T4 = {}
    H.openSteps(T4, "crate", "B10, a recipe short of skill")
    H.wait(4000, function() return not T4.ready or H.cardTexts(T4.name) ~= nil end, function()
        if not T4.ready then return end
        local rd = H.row(T4.name)
        local e = rd.entry
        local texts = H.cardTexts(T4.name) or {}
        local skill = e.skillDefs and e.skillDefs[1] and e.skillDefs[1].name or e.skillName
        local unknown = ZeD.tr("UI_ZeD_Craft_BadgeUnknown")
        Q.check(rd.hasSkill == false, "B10 staging: the crate is short of skill at Carpentry 0", "hasSkill " .. tostring(rd.hasSkill) .. ", needs " .. tostring(skill) .. " " .. tostring(e.requiredLevel))
        Q.check(H.hasText(texts, skill), "B10: the card of a recipe short of skill names the skill it needs (" .. tostring(skill) .. " " .. tostring(e.requiredLevel) .. "; the game's window shows it)",
            "drawn: " .. H.join(texts, 14))
        local learnNeeded = e.needLearn and true or false
        Q.check(learnNeeded or not H.hasText(texts, unknown), "B10: a recipe that needs no learning is not called \"" .. tostring(unknown) .. "\" for being short of skill",
            "needs learning " .. tostring(learnNeeded) .. ", badge drawn " .. tostring(H.hasText(texts, unknown)))
        -- (what Show: Known does with it, and what the preview says)
        local st = H.bst()
        S.CC.setShow(st, "known")
        H.closeCard()
        pcall(S.CC.refilter, H.data(), st, st.config, RT.ww())
        local listed = false
        for _, r in ipairs(st.filteredCache or {}) do if r.entry.name == T4.name then listed = true end end
        H.note("B10: under Show: Known the skill-short crate is " .. (listed and "listed" or "hidden") .. " (the game lists it with its skill in red)")
        S.CC.setShow(st, "all")
        pcall(S.CC.openCraft, st, T4.name)
    end)
    H.idle(10)
    H.step(1, function()
        if not T4.ready then return end
        local z = H.zone("detailIcon")
        if z then H.click(z, "B10: the card's icon") end
    end)
    H.wait(3000, function() local t = C.previewT(); return not T4.ready or (t ~= nil and t.d ~= nil) end, function(ok)
        if not T4.ready then return end
        local t = C.previewT()
        H.note("B10: the preview card " .. ((ok and t) and ("says Skill \"" .. tostring(t.d.skill) .. "\"") or "did not open"))
        pcall(function() RT.ww()._objectCard:close() end)
        H.closeCard()
    end)
    H.caseEnd("list")
end
-- the open preview card's state (ObjectCardPreview's t), or nil
function C.previewT()
    local w = RT.ww()
    local e = w and w._drawerObject
    if e and e.def and e.def.id == "preview" then return e.t end
    return nil
end
-- B9: ZeD's card against the game's per-input answer; expect names the input the staging made short
function C.b9(name, lab, expect, staged)
    local rd = H.row(name)
    local e = rd.entry
    local can = H.gameCan(e)
    local short, read = H.gameShort(e)
    if can ~= false then
        Q.skip(lab, "the game builds it with what was given (" .. tostring(can) .. "): the staging did not make the " .. expect .. " short (staged " .. tostring(staged) .. ")")
        return
    end
    if not read then short = { "(the game's recipe data could not be read)" } end
    local zedShort = {}
    for _, ing in ipairs(rd.ingredients or {}) do if (ing.have or 0) < (ing.need or 1) then zedShort[tostring(ing.name)] = true end end
    local stuck = (rd.missingCount or 0) == 0 and rd.status == "missing"
    local idx = (stuck and e._shortAt and getTimestampMs() - e._shortAt < 3000) and e._shortIdx or nil
    if idx and e.inputDefs[idx] then zedShort[tostring(e.inputDefs[idx].name)] = true end
    local marked = false
    for _, nm in ipairs(short) do if zedShort[nm] then marked = true end end
    local zs = {}
    for k in pairs(zedShort) do zs[#zs + 1] = k end
    local texts = H.cardTexts(name) or {}
    local surf, bench = ZeD.tr("UI_ZeD_Craft_NeedsSurface"), ZeD.tr("UI_ZeD_Craft_NeedsBench")
    local wrongLine = H.hasText(texts, surf) or H.hasText(texts, bench) or H.hasText(texts, "Needs a table or counter nearby.")
    Q.check(marked, lab .. ": ZeD's card marks the input the game finds short (never all green with Build gray and no reason)",
        "ZeD rows " .. H.rowsText(rd) .. " (status " .. tostring(rd.status) .. ", missing " .. tostring(rd.missingCount) .. "); ZeD marks "
        .. H.join(zs) .. " (stuck line " .. tostring(stuck) .. ", its short row " .. tostring(idx) .. "); the game short: " .. H.join(short))
    Q.check(not wrongLine, lab .. ": no \"needs a table / workbench\" line on a build card (CraftingCore.lua:3091-3104 asks a HandcraftLogic)",
        wrongLine and "drawn" or "none")
end

-- ===================================================================== 2. start, place and cancel with the mouse
function C.mouse()
    H.caseStart("mouse")
    local T = {}
    H.step(2, function() if S.ok then H.stageMat({ branch = "inv", stick = "inv", rag = "inv" }, 3) end end)
    H.openSteps(T, "cross", "mouse")
    -- B6: the preview card (the card's icon), its facing stepped twice with ">", then its Build
    H.step(2, function()
        if not T.ready then return end
        T.cnt0 = H.md(T.name)
        local z = H.zone("detailIcon")
        if z then H.click(z, "mouse: the card's icon") end
    end)
    H.wait(3000, function()
        if not T.ready then return true end
        local t, oc = C.previewT(), RT.ww()._objectCard
        return t ~= nil and t.d ~= nil and oc ~= nil and #(oc._zones or {}) > 0
    end, function(ok)
        if not T.ready then return end
        local t = C.previewT()
        if not (ok and t) then
            Q.skip("mouse (B6): the cursor starts on the face the preview shows", "the preview card did not open from the icon")
            H.bPress("mouse")
            T.cur = H.drag()
            return
        end
        local oc = RT.ww()._objectCard
        local n = #(t.d.faces or {})
        T.pFirst = t.d.faces[t.face] and t.d.faces[t.face].name
        -- the order the preview's ">" really steps (read, not assumed): a full turn, back to the start (Build's B6 fix
        -- makes ">" step as RB turns the cursor; the pad case checks RB against this)
        S.previewOrder = { T.pFirst }
        for k = 1, n do
            for _, z in ipairs(oc._zones or {}) do
                if z.fid == "oc:faceR" and z.run then pcall(z.run) end
            end
            if k < n then S.previewOrder[#S.previewOrder + 1] = t.d.faces[t.face] and t.d.faces[t.face].name end
        end
        T.pSteps = 0
        for _ = 1, 2 do
            for _, z in ipairs(oc._zones or {}) do
                if z.fid == "oc:faceR" and z.run and pcall(z.run) then T.pSteps = T.pSteps + 1 end
            end
        end
        T.pShown = t.d.faces[t.face] and t.d.faces[t.face].name
        T.pN = n
        local verb = t.verbs and t.verbs[1]
        T.verbOn = verb and verb.enabled
        if verb and verb.run then
            local okR, err = pcall(verb.run, S.p, t, oc)
            if not okR then Q.check(false, "mouse: the preview's Build ran without an error", err) end
        end
        T.cur = H.drag()
        if not H.isBuildCur(T.cur) then H.bPress("mouse"); T.cur = H.drag() end
    end)
    H.idle(3)
    H.step(1, function()
        if not T.ready then return end
        T.ok = Q.check(H.isBuildCur(T.cur) and (H.md(T.name) - (T.cnt0 or 0)) == 1, "mouse: Build starts the game's build cursor, counted once",
            H.dragType(T.cur) .. ", count +" .. tostring(H.md(T.name) - (T.cnt0 or 0)))
        if not T.ok then return end
        if T.pShown then
            local cf = H.faceName(T.cur)
            Q.check(cf == T.pShown, "mouse (B6): the cursor starts on the face the preview card showed at its Build",
                "preview opened on " .. tostring(T.pFirst) .. ", stepped " .. tostring(T.pSteps) .. " times with > to " .. tostring(T.pShown) .. " (" .. tostring(T.pN)
                .. " faces); the cursor's face " .. tostring(cf) .. " (nSprite " .. tostring(T.cur.nSprite) .. ")")
        end
        local vC, vB = H.valid(T.cur, S.sqClear), H.valid(T.cur, S.sqBad)
        Q.check(vC == true and vB == false, "mouse: the cursor's tint: valid on the clear tile, invalid on the crate's tile (BIE:isValid)",
            "clear " .. tostring(vC) .. ", crate " .. tostring(vB))
        -- placed once, as a click's release on the clear tile
        T.before = H.snapObjs(S.hx, S.hy, 10)
        H.speed(1)
        H.placeAt(T.cur, S.sqClear, "mouse, placed once")
        T.go = H.qlen() > 0
        if not T.go then Q.check(false, "mouse: a click on the clear tile queues the build (the walk, the action)", "queue " .. H.head() .. ", canBeBuild " .. tostring(T.cur.canBeBuild)) end
    end)
    H.runBuild(T)
    H.idle(20)
    H.step(1, function()
        if not (T.ok and T.go) then return end
        Q.check(#(T.new or {}) >= 1, "mouse: placed once, the cross stands", #(T.new or {}) .. " new objects, ran " .. tostring(T.acts))
        local d = H.drag()
        local v2 = H.valid(d, S.sqClear2)
        Q.check(H.isBuildCur(d) and v2 == true, "mouse (B2): after one placement the cursor is still usable for a second (the game re-arms it, ISBuildPanel.lua:414-422)",
            "cursor " .. H.dragType(d) .. (d == T.cur and " (the same)" or "") .. ", blockBuild " .. tostring(d and d.blockBuild) .. ", valid on a clear tile " .. tostring(v2))
        H.rmNew(T)
        H.noDrag()
        H.goHome()
    end)
    -- right-click on the world cancels it
    H.wait(3000, function() return not T.ok or (H.cardDrawn(T.name) and H.zone("action_build") ~= nil) end, function(ok)
        if not T.ok then return end
        if not H.open(T.name, "mouse, right-click") then return end
        H.bPress("mouse, right-click")
        local d = H.drag()
        if not H.isBuildCur(d) then Q.skip("mouse: right-click cancels the cursor", "Build started no cursor (" .. H.dragType(d) .. ")"); return end
        local okR, err = H.rightClickWorld(S.sqClear2)
        Q.check(okR and H.drag() == nil, "mouse: a right-click on the world cancels the build cursor (the game's world menu, ISMenuContextWorld.lua:52)",
            "cursor after " .. H.dragType(H.drag()) .. (okR and "" or (", the menu threw: " .. tostring(err))))
        H.noDrag()
    end)
    -- B4: Escape, four ways
    C.esc(T, "inside", "mouse, Escape with the pointer in the window")
    C.esc(T, "short", "mouse, Escape with the pointer outside under 2 s (unpinned)")
    C.esc(T, "long", "mouse, Escape with the pointer outside after 2 s (unpinned)")
    C.esc(T, "pinned", "mouse, Escape with the window pinned, the pointer outside")
    H.caseEnd("mouse")
end
function C.esc(T0, mode, lab)
    local T = {}
    H.step(2, function()
        if not T0.ok then return end
        H.noDrag()
        T.open = H.open(T0.name, lab)
    end)
    H.wait(4000, function() return not T.open or (H.cardDrawn(T0.name) and H.zone("action_build") ~= nil) end, function(ok)
        if not T.open then return end
        if not ok then Q.skip(lab, "the cross's card did not draw"); T.open = false; return end
        H.bPress(lab)
        if not H.isBuildCur(H.drag()) then Q.skip(lab, "Build started no build cursor"); T.open = false; return end
        local w = RT.ww()
        if mode == "inside" then
            local d = w and w._drawerPanel
            if d then H.mouseAt(H.fl(d:getAbsoluteX() + d:getWidth() / 2), H.fl(d:getAbsoluteY() + d:getHeight() / 2)) end
        elseif mode == "pinned" then
            H.pin(true)
            H.park()
        else
            H.pin(false)
            H.park()
        end
    end)
    Q.waitMs((mode == "long" or mode == "pinned") and 2800 or 600)
    H.step(1, function()
        if not T.open then return end
        local st = H.bst()
        local drawn = st ~= nil and st.selected ~= nil and st._cardDrawnAt ~= nil and getTimestampMs() - st._cardDrawnAt < 500
        local rolled = H.drawerRolled()
        H.esc()
        local after1 = H.drag()
        local card1 = st and st.selected
        local presses = 1
        if after1 then H.esc(); presses = 2 end
        local after2 = H.drag()
        local paused = H.pauseUp()
        if paused then H.unpause() end
        Q.check(after1 == nil, lab .. " (B4): one Escape drops the build cursor (the game's Escape drops it first, MainScreen.lua:1713-1716)",
            "card drawn in the last 0.5 s " .. tostring(drawn) .. ", tab side rolled " .. tostring(rolled) .. "; after the first Escape: cursor "
            .. H.dragType(after1) .. ", card " .. tostring(card1) .. "; Escapes to drop it: " .. (after2 == nil and tostring(presses) or "more than 2")
            .. (paused and "; the pause menu opened (shut again)" or ""))
        H.mouseBack()
        H.pinsBack()
        H.noDrag()
    end)
    H.idle(10)
end

-- ===================================================================== 3. the pad
function C.pad()
    H.caseStart("pad")
    local T = {}
    H.step(2, function() if S.ok then H.stageMat({ branch = "inv", stick = "inv", rag = "inv" }, 2) end end)
    H.step(2, function()
        if not S.tabOk then return end
        T.name = H.rname("cross")
        local rd = T.name and H.row(T.name)
        if rd then H.search(tostring(rd.entry.displayName)) end
        H.closeCard()
        H.padOn()
    end)
    H.wait(3000, function() return T.name == nil or H.zone("recipeRow", T.name) ~= nil end, function()
        if not T.name then Q.skip("pad", "no cross listed"); return end
        H.padClaim()
    end)
    H.idle(6)
    H.step(1, function()
        if not T.name then return end
        T.row = H.focusOn("build:row:" .. T.name) ~= nil
        if not Q.check(T.row, "pad: staging: the focus on the cross's row", tostring(H.focId())) then T.name = nil end
    end)
    H.tap("A", function() return T.name ~= nil end)
    H.wait(3000, function() local st = H.bst(); return T.name == nil or (st and st.selected == T.name and H.focId() == "build:actBuild") end, function(ok)
        if not T.name then return end
        local st = H.bst()
        Q.check(st.selected == T.name, "pad: A on the row opens its card", tostring(st.selected))
        H.note("pad (B12): after A on the row the focus is on " .. tostring(H.focId()) .. " (the card's Build key: build:actBuild)")
        T.cnt0 = H.md(T.name)
        if H.focId() ~= "build:actBuild" then H.focusOn("build:actBuild") end
    end)
    H.tap("A", function() return T.name ~= nil and H.focId() == "build:actBuild" end)
    H.wait(3000, function() return T.name == nil or H.isBuildCur(H.drag()) end, function(ok)
        if not T.name then return end
        T.cur = H.drag()
        T.ok = Q.check(ok and H.isBuildCur(T.cur), "pad: A on Build starts the game's build cursor", H.dragType(T.cur) .. ", count +" .. tostring(H.md(T.name) - (T.cnt0 or 0)))
    end)
    H.idle(10)
    -- B1: A on the cursor over a valid tile, the game's own press
    H.step(1, function()
        if not T.ok then return end
        local w = RT.ww()
        H.note("pad: with the cursor up the World window " .. ((w and (w.windowShaded or H.drawerRolled())) and "rolled up" or "stayed down")
            .. ", the pad's window " .. tostring(S.F.getFocusedWindow and S.F.getFocusedWindow(S.pn) and "held" or "let go"))
        T.before = H.snapObjs(S.hx, S.hy, 10)
        pcall(function()
            T.cur.square = S.sqClear
            T.cur.canBeBuild = T.cur:isValid(S.sqClear) and true or false
            T.cur.build = false
        end)
        T.canBe = T.cur.canBeBuild
        local okP, err = H.ctlPress(Joypad.AButton)
        T.flag = T.cur.build == true
        if not okP then Q.check(false, "pad: the game's press with no focus ran without an error", err) end
    end)
    Q.waitMs(1500)
    H.step(1, function()
        if not T.ok then return end
        T.go = H.qlen() > 0
        Q.check(T.flag or T.go, "pad (B1): A on the build cursor over a valid tile places it (the prompt says A, ISBuildingObject.lua:671-675)",
            "valid there " .. tostring(T.canBe) .. ", the cursor's build flag after A " .. tostring(T.flag) .. ", queue " .. H.head()
            .. " (onJoypadPressButton has no A case, ISBuildingObject.lua:627-653)")
    end)
    H.runBuild(T, 30000)
    H.step(2, function() if T.go then H.rmNew(T) end end)
    -- B6: RB against the preview's ">", LB back; then B cancels
    H.step(2, function()
        if not T.ok then return end
        local cur = H.drag()
        if not H.isBuildCur(cur) then Q.skip("pad (B6): RB turns the way the preview's > steps", "the cursor went (" .. H.dragType(cur) .. ")"); return end
        local rd = H.row(T.name)
        -- (the order the preview's ">" stepped in the mouse case, when it was read there; else the game's index order)
        local P = (S.previewOrder and #S.previewOrder >= 3) and S.previewOrder or H.faceNames(rd.entry)
        local R = { H.faceName(cur) }
        for _ = 1, 4 do H.ctlPress(Joypad.RBumper); R[#R + 1] = H.faceName(cur) end
        H.ctlPress(Joypad.LBumper)
        local lb = H.faceName(cur)
        local n, at = #P, nil
        for i, nm in ipairs(P) do if nm == R[1] then at = i end end
        local nextP = at and ((at < n) and P[at + 1] or P[1]) or nil
        local prevP = at and ((at > 1) and P[at - 1] or P[n]) or nil
        local way = (R[2] == nextP and "the same way") or (R[2] == prevP and "the opposite way") or "neither way"
        local rs = {}
        for i = 1, 5 do rs[i] = tostring(R[i]) end
        Q.check(R[2] ~= nil and R[2] ~= R[1], "pad: RB turns the build cursor", "faces " .. table.concat(rs, " > "))
        if n < 3 then
            Q.skip("pad (B6): RB turns the cursor the way the preview card's > steps it", "the game's build object gave " .. n .. " faces")
        else
            Q.check(R[2] == nextP, "pad (B6): RB turns the cursor the way the preview card's > steps it",
                "preview > order " .. table.concat(P, " > ") .. "; RB from " .. rs[1] .. ": " .. table.concat(rs, " > ") .. " (" .. way .. ")")
        end
        Q.check(lb == R[4], "pad: LB turns it back one step", "after 4 RB " .. tostring(R[5]) .. ", LB " .. tostring(lb) .. ", want " .. tostring(R[4]))
        local okB = H.ctlPress(Joypad.BButton)
        Q.check(okB and H.drag() == nil, "pad: B on the build cursor cancels it", H.dragType(H.drag()))
        H.noDrag()
    end)
    -- B11: B on the card, no cursor
    H.step(3, function()
        if not T.name then return end
        H.unroll()
        local st = H.bst()
        if st and st.selected ~= T.name then pcall(S.CC.openCraft, st, T.name) end
        H.padClaim()
    end)
    H.idle(8)
    H.step(1, function()
        if not T.name then return end
        T.onCard = H.focusOn("build:card:req") ~= nil or H.focusOn("build:icon") ~= nil
        T.focB = H.focId()
        T.q0 = H.qlen()
    end)
    H.tap("B", function() return T.onCard == true end)
    H.idle(6)
    H.step(1, function()
        if not T.name then return end
        if not T.onCard then Q.skip("pad (B11): B on the card closes it", "no card stop to put the focus on"); return end
        local st = H.bst()
        Q.check(st.selected == nil, "pad (B11): B on the build card with no cursor closes it (the game's B closes its build window)",
            "focus was " .. tostring(T.focB) .. "; the card " .. tostring(st.selected) .. ", focus now " .. tostring(H.focId()) .. ", queue " .. T.q0 .. " -> " .. H.qlen())
        H.padOff()
    end)
    H.caseEnd("pad")
end

-- ===================================================================== 4. window and tab changes with the cursor up (B5)
function C.windows()
    H.caseStart("windows")
    local T = {}
    H.step(2, function() if S.ok then H.stageMat({ branch = "inv", stick = "inv", rag = "inv" }, 1) end end)
    H.openSteps(T, "cross", "windows")
    H.step(2, function()
        if not T.ready then return end
        H.bPress("windows")
        T.cur = H.drag()
        if not H.isBuildCur(T.cur) then T.ready = false; Q.skip("windows (B5)", "Build started no cursor"); return end
        local o1, w1 = H.winOver(S.sqClear)
        local o2, w2 = H.winOver(S.sqClear2)
        Q.check(not (o1 or o2), "windows (B5): with the cursor up the World window is not drawn over the tiles being placed on (the game hides its window, ISBuildPanel.lua:428-445)",
            w1 .. "; " .. w2)
        pcall(S.WW.close, S.pn)
    end)
    H.idle(4)
    H.step(1, function()
        if not T.ready then return end
        local d = H.drag()
        Q.check(d == nil, "windows (B5): closing the World window clears the build cursor (the game's close does, ISBuildPanel.lua:405-407)",
            "cursor after the close " .. H.dragType(d) .. (d == T.cur and " (the same)" or ""))
        H.noDrag()
        pcall(S.WW.open, S.pn)
    end)
    H.idle(10)
    H.step(1, function() if T.ready then H.tab("build") end end)
    H.wait(6000, function() return not T.ready or (H.showing() and H.data() ~= nil) end, function(ok)
        if not T.ready then return end
        Q.check(ok, "windows: the World window opens again on Building", tostring(H.showing()))
        H.show("all")
        T.open = H.open(T.name, "windows, tab switch")
    end)
    H.wait(4000, function() return not T.open or (H.cardDrawn(T.name) and H.zone("action_build") ~= nil) end, function(ok)
        if not T.open then return end
        H.bPress("windows, tab switch")
        T.cur2 = H.drag()
        if not H.isBuildCur(T.cur2) then T.open = false; return end
        RT.worldTab("loot")
    end)
    H.idle(6)
    H.step(1, function()
        if not T.open then return end
        local d = H.drag()
        H.note("windows (B5): after a switch to Loot the build cursor is " .. ((d ~= nil and d == T.cur2) and "still up" or ("gone (" .. H.dragType(d) .. ")"))
            .. "; the game has no tabs (its window's close clears it)")
        H.noDrag()
        H.tab("build")
    end)
    H.wait(4000, function() return not T.open or H.showing() end, function()
        if not T.open then return end
        T.open2 = H.open(T.name, "windows, Furniture")
    end)
    H.wait(4000, function() return not T.open2 or (H.cardDrawn(T.name) and H.zone("action_build") ~= nil) end, function(ok)
        if not T.open2 then return end
        H.bPress("windows, Furniture")
        T.cur3 = H.drag()
        if not H.isBuildCur(T.cur3) then T.open2 = false; return end
        H.tab("furniture")
    end)
    H.wait(4000, function() return not T.open2 or (H.drag() ~= T.cur3) end, function(ok)
        if not T.open2 then return end
        local d = H.drag()
        Q.check(ok and d ~= T.cur3, "windows: opening Furniture with the build cursor up replaces it (FurnitureTab.lua:172-181)",
            "cursor now " .. H.dragType(d))
        H.tab("build")
    end)
    H.wait(4000, function() return not T.open2 or (H.showing() and H.drag() == nil) end, function(ok)
        if not T.open2 then return end
        Q.check(ok, "windows: leaving Furniture ends its cursor", H.dragType(H.drag()))
        H.noDrag()
    end)
    H.caseEnd("windows")
end

-- ===================================================================== 5. materials (B7)
S.MSPECS = {
    { lab = "all carried", spec = { branch = "inv", stick = "inv", rag = "inv" }, can = true },
    { lab = "all in a worn bag", spec = { branch = "bag", stick = "bag", rag = "bag" }, can = true },
    { lab = "all on the floor at his feet", spec = { branch = "floor", stick = "floor", rag = "floor" }, can = true },
    { lab = "all in the crate beside him", spec = { branch = "crate", stick = "crate", rag = "crate" }, can = true },
    { lab = "split: carried, bag, crate", spec = { branch = "inv", stick = "bag", rag = "crate" }, can = true },
    { lab = "split: crate, floor, bag", spec = { branch = "crate", stick = "floor", rag = "bag" }, can = true },
    { lab = "one short (no rag)", spec = { branch = "inv", stick = "crate" }, can = false },
}
function C.materials()
    H.caseStart("materials")
    local T = {}
    H.step(2, function()
        if not S.ok then return end
        T.bag = H.bagUp()
        if not T.bag then H.note("materials: no bag could be worn: the bag stagings are carried instead") end
    end)
    H.openSteps(T, "cross", "materials")
    for _, m in ipairs(S.MSPECS) do C.matStage(T, m) end
    C.farBuild(T, "crate", "materials, built far from the crate")
    C.farBuild(T, "floor", "materials, built far from the floor pile")
    H.caseEnd("materials")
end
function C.matStage(T, m)
    local lab = "materials, " .. m.lab
    H.step(2, function()
        if not T.ready then return end
        H.clearMat()
        local spec = {}
        for k, v in pairs(m.spec) do spec[k] = (v == "bag" and not S.bagInv) and "inv" or v end
        H.stageMat(spec)
        if not H.open(T.name, lab) then T.ready = false end
    end)
    H.wait(7000, function()
        if not T.ready then return true end
        local rd = H.row(T.name)
        if not (H.settled(rd) and rd.ingredients) then return false end
        local agree = H.haveAgree(rd)
        return agree and H.zedCan(rd) == (H.gameCan(rd.entry) == true)
    end, function(ok)
        if not T.ready then return end
        local rd = H.row(T.name)
        local g = H.gameCan(rd.entry)
        local agree, why = H.haveAgree(rd)
        if g ~= m.can then H.note(lab .. ": the game's own answer is " .. tostring(g) .. " (staged for " .. tostring(m.can) .. ")") end
        Q.check(H.zedCan(rd) == (g == true), lab .. ": the row says buildable exactly when the game would", "ZeD " .. tostring(rd.status) .. ", the game " .. tostring(g))
        Q.check(agree, lab .. ": the card's have counts equal what the game's containers hold", agree and H.rowsText(rd) or why)
    end)
end
-- the three inputs all in one place (where: "crate" or "floor"); Build pressed there, the cross placed 6 to 9 tiles
-- away: where the materials came from, and whether the consume failed
function C.farBuild(T0, where, lab)
    local T = {}
    H.step(2, function()
        if not T0.ready then return end
        H.clearMat()
        H.goHome()
        H.stageMat({ branch = where, stick = where, rag = where })
        T.open = H.open(T0.name, lab)
    end)
    H.wait(7000, function() return not T.open or (H.zedCan(H.row(T0.name)) and H.zone("action_build") ~= nil and H.cardDrawn(T0.name)) end, function(ok)
        if not T.open then return end
        if not ok then Q.skip(lab, "the row never read buildable with the materials " .. (where == "crate" and "in the crate" or "on the floor")); return end
        H.noDrag()
        H.bPress(lab)
        T.cur = H.drag()
        if not H.isBuildCur(T.cur) then Q.skip(lab, "Build started no cursor (" .. H.dragType(T.cur) .. ")"); return end
        T.sq = H.farSq(T.cur)
        if not T.sq then Q.skip(lab, "no free tile 6 to 9 away that the cursor takes"); H.noDrag(); return end
        T.before = H.snapObjs(S.hx, S.hy, 10)
        -- (asked when the build action starts: are the staged things in the game's list where he stands then?)
        T.watch = function()
            local inR = true
            for _, mm in ipairs(S.mats) do if not H.inConts(mm.it) then inR = false end end
            return inR
        end
        H.speed(1)
        H.placeAt(T.cur, T.sq, lab)
        T.go = H.qlen() > 0
        if not T.go then Q.skip(lab, "the click queued nothing (no way to walk there)") end
    end)
    H.runBuild(T, 50000)
    H.step(2, function()
        if not T.go then return end
        local built = #(T.new or {})
        local gone = H.matGone()
        local d = T.sq and H.fl(H.dist(T.sq)) or "?"
        Q.check(not (T.acts and T.acts > 0 and built == 0), lab .. ": a build that runs to its end stands (no consume that fails after the walk and the whole action)",
            (T.acts or 0) .. " build action(s) ran, " .. built .. " new objects, used: " .. H.join(gone) .. " (tile " .. tostring(d) .. " tiles from where Build was pressed)")
        if built > 0 then
            Q.check(#gone == 0 or T.inReach == true, lab .. " (B7): the materials come from containers in reach where he builds (the game's build window reads its list again as he moves, ISBuildPanel.lua:185-221)",
                "used " .. H.join(gone) .. ", which were " .. (T.inReach and "in" or "NOT in") .. " the game's containers when the action ran (" .. tostring(d) .. " tiles off)")
        end
        H.rmNew(T)
        H.noDrag()
        H.clearMat()
        H.goHome()
    end)
end

-- ===================================================================== 6. build twice, build while a build runs (B3)
function C.twice()
    H.caseStart("twice")
    local T = {}
    H.step(2, function() if S.ok then H.stageMat({ branch = "inv", stick = "inv", rag = "inv" }, 1) end end)
    H.openSteps(T, "cross", "twice")
    H.wait(5000, function() return not T.ready or H.zedCan(H.row(T.name)) end, function(ok)
        if not T.ready then return end
        if not ok then Q.skip("twice (B3)", "one set carried never read buildable"); T.ready = false; return end
        T.cnt0 = H.md(T.name)
        H.bPress("twice")
        T.cur1 = H.drag()
        if not H.isBuildCur(T.cur1) then Q.skip("twice (B3)", "Build started no cursor"); T.ready = false; return end
        T.before = H.snapObjs(S.hx, S.hy, 10)
        H.speed(1)
        H.placeAt(T.cur1, S.sqClear, "twice, the first")
        T.q1 = H.qlen()
        T.go = T.q1 > 0
        if not T.go then Q.skip("twice (B3)", "the first placement queued nothing"); return end
        -- Build again at once, the first build queued
        H.bPress("twice, again")
        T.cur2 = H.drag()
        T.new2 = H.isBuildCur(T.cur2) and T.cur2 ~= T.cur1
        T.valid2 = T.new2 and H.valid(T.cur2, S.sqClear2) == true
        Q.check(not T.valid2, "twice (B3): Build pressed while a build is queued starts no usable cursor (the game holds Build while one runs, ISWidgetBuildControl.lua:163-172)",
            "queue " .. T.q1 .. " (" .. H.head() .. "); a new cursor " .. tostring(T.new2) .. ", valid on a clear tile " .. tostring(T.valid2))
        if T.valid2 then H.placeAt(T.cur2, S.sqClear2, "twice, the second") end
        T.q2 = H.qlen()
    end)
    H.runBuild(T, 70000)
    H.step(2, function()
        if not T.go then return end
        local built = #(T.new or {})
        local gone = H.matGone()
        Q.check(built >= 1, "twice: the first build stands", built .. " new objects")
        Q.check(#gone == built * 3, "twice (B3): nothing is lost (what is used is what was built: 3 inputs a cross)",
            built .. " built, " .. #gone .. " of 3 inputs used: " .. H.join(gone) .. "; queue had " .. tostring(T.q1) .. " then " .. tostring(T.q2) .. " actions")
        H.note("twice (B3): " .. tostring(T.acts or 0) .. " build action(s) ran for " .. built .. " cross(es); the counts went +" .. (H.md(T.name) - (T.cnt0 or 0)))
        H.rmNew(T)
        H.noDrag()
        H.goHome()
    end)
    -- Build pressed twice in one frame
    H.step(2, function()
        if not T.ready then return end
        H.clearMat()
        H.stageMat({ branch = "inv", stick = "inv", rag = "inv" }, 1)
    end)
    H.wait(5000, function() return not T.ready or (H.zedCan(H.row(T.name)) and H.cardDrawn(T.name) and H.zone("action_build") ~= nil) end, function(ok)
        if not (T.ready and ok) then return end
        local c0 = H.md(T.name)
        H.bPress("twice in a frame")
        local d1 = H.drag()
        H.bPress("twice in a frame, again")
        local d2 = H.drag()
        H.note("twice (B15): Build pressed twice in one frame: cursors " .. H.dragType(d1) .. " then " .. H.dragType(d2)
            .. (d1 ~= d2 and " (replaced)" or " (the same)") .. ", counted +" .. (H.md(T.name) - c0) .. " with nothing built (the count is per cursor, BuildingTab.lua:377-380)")
        H.noDrag()
    end)
    H.caseEnd("twice")
end

-- ===================================================================== 7. the grayed Build (B8)
function C.grayed()
    H.caseStart("grayed")
    local T = {}
    H.step(2, function() if S.ok then H.clearMat() end end)
    H.openSteps(T, "cross", "grayed")
    H.wait(6000, function()
        if not T.ready then return true end
        local rd = H.row(T.name)
        return rd and rd.status ~= "craftable" and H.gameCan(rd.entry) == false
    end, function(ok)
        if not T.ready then return end
        local rd = H.row(T.name)
        if not ok then Q.skip("grayed (B8)", "the row never read gray with nothing carried (" .. tostring(rd and rd.status) .. ", the game " .. tostring(H.gameCan(rd.entry)) .. ")"); T.ready = false; return end
        T.cnt0 = H.md(T.name)
        local z = H.zone("action_build")
        H.note("grayed (B8): Build is gray (" .. tostring(rd.status) .. ") and its press zone is " .. (z and "still stamped" or "not stamped") .. " (CraftingCore.lua:2058)")
        H.noDrag()
        if z then H.bPress("grayed") end
        Q.check(H.drag() == nil and H.md(T.name) == T.cnt0, "grayed (B8): a press on the gray Build by the mouse starts nothing and counts nothing",
            "cursor " .. H.dragType(H.drag()) .. ", count +" .. (H.md(T.name) - T.cnt0))
        H.noDrag()
        H.padOn()
        H.padClaim()
    end)
    H.idle(8)
    H.step(1, function() if T.ready then T.onB = H.focusOn("build:actBuild") ~= nil end end)
    H.tap("A", function() return T.onB == true end)
    Q.waitMs(800)
    H.step(1, function()
        if not T.ready then return end
        if not T.onB then Q.skip("grayed (B8): A on the gray Build starts nothing", "the gray Build is no pad stop (" .. tostring(H.focId()) .. ")")
        else
            Q.check(H.drag() == nil and H.md(T.name) == T.cnt0, "grayed (B8): A on the gray Build starts nothing and counts nothing",
                "cursor " .. H.dragType(H.drag()) .. ", count +" .. (H.md(T.name) - T.cnt0))
        end
        H.noDrag()
        H.closeCard()
    end)
    H.idle(6)
    H.step(1, function() if T.ready then T.onRow = H.focusOn("build:row:" .. T.name) ~= nil end end)
    H.tap("A", function() return T.onRow == true end)
    Q.waitMs(1500)
    H.step(1, function()
        if not (T.ready and T.onRow) then return end
        H.note("grayed (B12): A on a row whose Build is gray opens the card with the focus on " .. tostring(H.focId())
            .. " (a second A there starts nothing, above)")
        H.padOff()
    end)
    H.caseEnd("grayed")
end

-- ===================================================================== 8. translations (B18)
function C.lang()
    H.caseStart("language")
    H.step(2, function()
        local want, seen = {}, {}
        for k in pairs(S.trKeys) do if string.sub(k, 1, 7) == "UI_ZeD_" and not seen[k] then seen[k] = true; want[#want + 1] = k end end
        for _, k in ipairs(S.KEYS) do if not seen[k] then seen[k] = true; want[#want + 1] = k end end
        table.sort(want)
        local files, read = {}, 0
        for _, lang in ipairs(S.LANGS) do
            local keys, lines = {}, 0
            pcall(function()
                local r = getModFileReader("ZeD_UI", "media/lua/shared/Translate/" .. lang .. "/UI.json", false)
                if not r then return end
                local l = r:readLine()
                while l do
                    lines = lines + 1
                    local k = string.match(l, '^%s*"(UI_ZeD_[%w_]+)"%s*:')
                    if k then keys[k] = true end
                    l = r:readLine()
                end
                r:close()
            end)
            if lines > 0 then files[lang] = keys; read = read + 1 end
        end
        if not files.EN then Q.skip("language (B18)", "ZeD's Translate/EN/UI.json could not be read in game"); return end
        local onlyEN, some, noEN = {}, {}, {}
        for _, k in ipairs(want) do
            if not files.EN[k] then noEN[#noEN + 1] = k
            else
                local have, miss = 0, {}
                for _, lang in ipairs(S.LANGS) do
                    if lang ~= "EN" and files[lang] then
                        if files[lang][k] then have = have + 1 else miss[#miss + 1] = lang end
                    end
                end
                if have == 0 then onlyEN[#onlyEN + 1] = k
                elseif #miss > 0 then some[#some + 1] = k .. " (no " .. table.concat(miss, " ") .. ")" end
            end
        end
        H.note("language (B18): " .. #want .. " ZeD keys the Build tab asked for (or names), " .. read .. " language files read")
        H.note("language (B18): only English has: " .. H.join(onlyEN, 20))
        H.note("language (B18): some languages lack: " .. H.join(some, 12))
        if #noEN > 0 then H.note("language (B18): not in the English file either (ZeD's code holds their English): " .. H.join(noEN, 12)) end
        H.note("language (B18): CraftingCore.lua:3100 keeps the English \"Needs a table or counter nearby.\" in code for UI_ZeD_Craft_NeedsSurface")
        -- the search matches a category's English word, not the label the select shows (CraftingCore.lua:1125 against 976-993)
        local d = H.data()
        local diff = {}
        for _, c in ipairs((d and d.categories) or {}) do
            if c.id ~= "all" then
                local label = S.CC.categoryLabel(c.full or c.label or c.id)
                if string.lower(tostring(label)) ~= string.lower(tostring(c.full or c.label or c.id)) then diff[#diff + 1] = tostring(c.full) .. " shown as " .. tostring(label) end
            end
        end
        H.note("language (B18): categories whose shown label is not the word the search matches: " .. H.join(diff, 12))
    end)
    H.caseEnd("language")
end

-- ===================================================================== 9. layout
function C.layoutCheck(lab, name)
    local c = S.card
    if not (c and c.name == name and getTimestampMs() - c.t < 1500) then Q.check(false, lab .. ": the card drew", "no card for " .. tostring(name) .. " in the last 1.5 s"); return end
    local outs = {}
    for _, t in ipairs(c.texts) do
        local tw = H.textW(t)
        local lx = t.x
        if t.right then lx = t.x - tw elseif t.centre then lx = t.x - tw / 2 end
        if lx < c.x - 1 or lx + tw > c.x + c.w + 1 then
            outs[#outs + 1] = "\"" .. tostring(t.s) .. "\" " .. H.fl(lx) .. "+" .. H.fl(tw)
        end
    end
    Q.check(#c.texts > 0 and #outs == 0, lab .. ": every word the card draws stays inside the card",
        #c.texts .. " words in " .. H.fl(c.x) .. "+" .. H.fl(c.w) .. (#outs > 0 and ("; out: " .. H.join(outs)) or ""))
    RT.bounds(Q, lab)
end
function C.layoutPass(T, card, size, theme, pic)
    local L = {}
    local lab = "layout, the " .. card .. " card, " .. tostring(size) .. " text, " .. theme.tag
    H.step(1, function()
        if not T.ready then return end
        local w = RT.ww()
        if not w then return end
        if card == 220 then S.back.cap = true; w._maxWinW = ZeD.T.px(620) else w._maxWinW = S.found.maxWinW end
        if ZeD.currentSize ~= size then H.sizeSet(size) end
        if ZeD.currentBase ~= theme.key then H.theme(theme.key) end
        H.open(T.name, lab)
    end)
    H.wait(5000, function()
        if not T.ready then return true end
        local w = RT.ww()
        local eff = w and math.floor(w._drawerEffW or 0)
        if eff == L.last then L.n = (L.n or 0) + 1 else L.n = 0 end
        L.last = eff
        return L.n >= 10 and H.cardDrawn(T.name)
    end, function()
        if not T.ready then return end
        local want = ZeD.T.px(card)
        if L.last ~= want then H.note(lab .. ": the drawer stands at " .. tostring(L.last) .. " px, not " .. want .. " (held in on this screen at this size)") end
        C.layoutCheck(lab .. " (" .. tostring(L.last) .. " px)", T.name)
    end)
    if pic then H.shot("bd_" .. card .. "_" .. tostring(size) .. "_" .. theme.tag .. "_" .. H.sizeTag(), "the Build card on the " .. card .. " card, " .. tostring(size) .. " text, " .. theme.tag) end
end
function C.layout()
    H.caseStart("layout")
    local T = {}
    H.step(2, function() if S.ok then H.stageMat({ branch = "inv", stick = "inv", rag = "inv" }, 1) end end)
    H.openSteps(T, "cross", "layout")
    local found = S.found.size or "small"
    local sizes = { found }
    if found ~= "large" then sizes[#sizes + 1] = "large" end
    local dark = S.THEMES[1]
    for _, sz in ipairs(sizes) do
        C.layoutPass(T, 480, sz, dark, true)
        C.layoutPass(T, 220, sz, dark, true)
    end
    C.layoutPass(T, 480, found, S.THEMES[2], true)
    C.layoutPass(T, 480, found, S.THEMES[3], true)
    H.step(2, function()
        H.sizeBack()
        H.themeBack()
        local w = RT.ww()
        if w and S.back.cap then w._maxWinW = S.found.maxWinW end
        S.back.cap = nil
    end)
    H.idle(30)
    H.step(1, function()
        Q.check(ZeD.currentSize == S.found.size and ZeD.currentBase == S.found.base, "layout: the text size and the theme are back as found",
            tostring(ZeD.currentSize) .. " / " .. tostring(ZeD.currentBase))
    end)
    H.caseEnd("layout")
end

-- ===================================================================== the run
C.list()
C.mouse()
C.pad()
C.windows()
C.materials()
C.twice()
C.grayed()
C.lang()
C.layout()

-- ===================================================================== put back
Q.mark()
H.step(2, function()
    H.speed(1)
    H.stop()
    H.noDrag()
    H.mouseBack()
    H.unpause()
    H.closeMenu()
    H.padOff()
    H.sizeBack()
    H.themeBack()
    local w = RT.ww()
    if w and S.found.maxWinW then w._maxWinW = S.found.maxWinW end
    H.pinsBack()
end)
H.step(3, function()
    if S.dead then return end
    for _, o in ipairs(S.built) do if H.objOn(o) then H.rmObj(o) end end
    for _, m in ipairs(S.mats) do H.rmItem(m.it) end
    S.mats = {}
    if S.bagMine and S.bag then pcall(function() S.p:removeWornItem(S.bag) end) end
    for _, it in ipairs(S.given) do H.rmItem(it) end
    RT.takeBack()
    if S.crate then H.rmObj(S.crate) end
    -- anything new carried (a build's leftovers) or new on the floor nearby goes
    local n = 0
    for _, it in ipairs(H.all()) do if not S.had[it] then H.rmItem(it); n = n + 1 end end
    local now = {}
    H.snapWorld(now)
    for wo in pairs(now) do
        if not S.floorHad[wo] then
            pcall(function() local sq = wo:getSquare(); if sq then sq:transmitRemoveItemFromSquare(wo) end end)
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            n = n + 1
        end
    end
    S.swept = n
    S.stashLost = H.unstash()
    pcall(function()
        local a, b = S.handWas[1], S.handWas[2]
        S.p:setPrimaryHandItem((a and S.p:getInventory():containsRecursive(a)) and a or nil)
        S.p:setSecondaryHandItem((b and S.p:getInventory():containsRecursive(b)) and b or nil)
    end)
    S.xpGrew, S.xpLeft = H.xpBack()
    for _, nm in ipairs(S.learned) do pcall(function() S.p:getKnownRecipes():remove(nm) end) end
    pcall(function() S.p:setTimedActionInstantCheat(S.instWas and true or false) end)
    pcall(function() S.p:setBuildCheat(S.bcWas and true or false) end)
    pcall(function() ISBuildMenu.cheat = S.bmWas end)
    -- the build counts and pins as found
    local md = S.p:getModData()
    for _, key in ipairs({ "ZeD_BuildCounts", "ZeD_BuildPins" }) do
        local was = S.cnt[key]
        if was then
            local t = {}
            for k, v in pairs(was) do t[k] = v end
            md[key] = t
        else
            md[key] = nil
        end
    end
    RT.pairOpen()
    local w2 = RT.ww()
    if w2 then pcall(S.CC.loadPins, w2, "ZeD_BuildPins", "_buildPins"); w2._buildCache = nil end
    H.refreshLoot()
end)
H.step(5, function()
    if S.dead then return end
    local st = H.bst()
    if st then
        H.closeCard()
        H.search("")
        if S.keep then st.show, st.showAll, st.sort, st.activeCat = S.keep.show, S.keep.showAll, S.keep.sort, S.keep.cat end
        st.filterDirty = true
        st.catDropdownOpen, st.sortMenuOpen, st.showMenuOpen = false, false, false
    end
    H.wrapOff()
    H.tab((S.tabWas and S.tabWas ~= "furniture") and S.tabWas or "loot")
end)
H.step(10, function()
    if S.dead then return end
    if ZEDQA_LAYOUT_BACK then ZEDQA_LAYOUT_BACK(S.layoutSnap, "bd_tab") end
    if ZEDQA_HOME then ZEDQA_HOME("bd_tab") else H.goHome() end
    if S.pairWas == false then RT.pairShut() end
end)
H.step(10, function()
    if S.dead then return end
    -- the cursor gone (removed, then read again)
    pcall(function() getCell():setDrag(nil, S.pn) end)
    Q.check(H.drag() == nil and H.qlen() == 0, "put back: no cursor and no action left (getCell():setDrag(nil, pn))", H.dragType(H.drag()) .. " / " .. H.head())
    local left = {}
    for _, o in ipairs(S.built) do if H.objOn(o) then left[#left + 1] = H.objName(o) end end
    if S.crate and H.objOn(S.crate) then left[#left + 1] = "the crate " .. S.CRATE end
    Q.check(#left == 0, "put back: nothing built or laid is left", #S.built .. " built and the crate taken away" .. (#left > 0 and ("; left: " .. H.join(left)) or ""))
    local gl = {}
    for _, it in ipairs(S.given) do if H.still(it) then gl[#gl + 1] = H.ft(it) end end
    Q.check(#gl == 0, "put back: every thing given is gone (inventory, bag, crate, floor)", #S.given .. " given" .. (#gl > 0 and ("; left: " .. H.join(gl)) or ""))
    local extra = {}
    for _, it in ipairs(H.all()) do if not S.had[it] then extra[#extra + 1] = H.ft(it) end end
    local now, floor = {}, 0
    H.snapWorld(now)
    for wo in pairs(now) do if not S.floorHad[wo] then floor = floor + 1 end end
    Q.check(#extra == 0 and floor == 0 and (S.stashLost or 0) == 0, "put back: he carries what he carried, his own things back, nothing new on the floor",
        tostring(S.swept) .. " swept; carried extra: " .. H.join(extra) .. "; " .. floor .. " new on the floor; " .. tostring(S.stashLost) .. " of his own not given back")
    local bm, bc, ia = nil, nil, nil
    pcall(function() bm = ISBuildMenu.cheat end)
    pcall(function() bc = S.p:isBuildCheat() end)
    pcall(function() ia = S.p:isTimedActionInstantCheat() end)
    Q.check(bm == S.bmWas and (bc and true or false) == (S.bcWas and true or false) and (ia and true or false) == (S.instWas and true or false),
        "put back: the cheats as found (ISBuildMenu.cheat, BuildCheat, instant actions)", tostring(bm) .. " / " .. tostring(bc) .. " / " .. tostring(ia)
        .. " (found " .. tostring(S.bmWas) .. " / " .. tostring(S.bcWas) .. " / " .. tostring(S.instWas) .. ")")
    local known = 0
    for _, nm in ipairs(S.learned) do pcall(function() if S.p:getKnownRecipes():contains(nm) then known = known + 1 end end) end
    Q.check((S.xpLeft or 0) == 0 and known == 0, "put back: the skills (level and XP) and the recipes known as found",
        tostring(S.xpGrew) .. " skills changed, " .. tostring(S.xpLeft) .. " not back" .. (S.xpLeftText and (": " .. S.xpLeftText) or "") .. "; " .. known .. " of " .. #S.learned .. " recipes learned still known")
    local st = H.bst()
    Q.check(S.w0 == nil and getGameSpeed() == 1 and (st == nil or (st.selected == nil and (st.search or "") == "")),
        "put back: the wrappers off, game speed 1, the Building tab's card shut and its search empty",
        tostring(S.w0 == nil) .. " / " .. tostring(getGameSpeed()) .. " / " .. tostring(st and st.selected) .. " / " .. tostring(st and st.search))
    RT.bounds(Q, "the end")
    pcall(function() if S.invWas ~= nil then S.p:setInvincible(S.invWas) end end)
end)
Q.start()
