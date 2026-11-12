-- ZeDUI/tools/qa/zedqa_director_review.lua  (Nov 11 2026, Build): the director's notes on the tab review, retaken. The
-- same settings as zedqa_tab_review.lua (1920x1080 window, UI scale 1x, Dark + PZ Teal, 19px game font), the same
-- scenes and names, only the pictures the notes were on: tabs_<char|world>_<tab>_<empty|full>.png in
-- Zomboid/Screenshots. Runs twice in one manifest (director_review.txt), by the order of the calls:
--   1st (tag drv)    EMPTY: after gallery_v3_core/reveal, the character put aside (bare, glasses only), nothing staged:
--                    char_thermal_empty, char_identity_empty (trait icons), world_furniture_empty (no indent)
--   2nd (tag drv2)   FULL : after gallery_v3_stage: char_health_full (injury rows centered), char_thermal_full (no black
--                    cells), char_journal_notebooks_full (the page to the foot), world_radio_full (the full card),
--                    world_furniture_full
-- The tab fill (zed_tab_fill_v1) in the same two passes: char_health_empty (Moodles, Fitness, Regularity under the
-- figure with no injuries), char_health_full and char_thermal_* (the picked region's rows, Body Heat Generation),
-- char_radio_full (the walkie's Channels, Heard, Power), world_radio_full (the set's Presets, Heard, Power at the
-- full card), char_journal_notebooks_none_full (no notebook carried: Writing, Papers on you, Books on you; the
-- notebooks are taken off the character for the picture and put back), char_journal_loadouts_full (opens on a list,
-- ready X of Y, a square per line, the radio buttons). The tags with no boxes, in the full pass: char_health_full
-- (the injury tags: square under the part's square, word under its name), char_loot_full (Belt 2 after the M9's name,
-- secondary ink), char_equip_list_full (the belt rows).
-- The second review's fixes, retaken in the same pictures (Nov 11 2026): no loot card over the Inventory (the pointer
-- parked by pzlaunchwin), both windows solid (see-through 100 for the run), the moodle note over the World window
-- (char_health_full), Power with one Battery row and Spare, Heard with "Nothing heard yet" (char_radio_full,
-- world_radio_full), no notebook in any bag (char_journal_notebooks_none_full), the Loadouts line wrapped, not cut
-- (char_equip_list_full).
-- Everything spawned is removed again; the teardown script puts the rest back. grep "ZEDQA drv".
local G = GAL
DRV_N = (DRV_N or 0) + 1
local MODE = ({ "empty", "full" })[DRV_N] or "empty"
local TAG = "drv" .. ((DRV_N > 1) and tostring(DRV_N) or "")
if not (G and G.spot and G.newSeq) then print("ZEDQA " .. TAG .. " ERR run gallery_v3_core.lua first"); print("ZEDQA " .. TAG .. " DONE"); return end
if not (ZeD and ZeD_CharacterWindow and ZeD_WorldWindow) then print("ZEDQA " .. TAG .. " ERR ZeD is not loaded"); print("ZEDQA " .. TAG .. " DONE"); return end
local S = G.newSeq(TAG, 1500000)
local say = S.say
local p, inv, pn, core = G.p, G.inv, G.pn, G.core
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local Opt = ZeD.Settings
local Z = { sc = { ok = true, why = "" }, lock = nil, tmp = {} }
local SM = getScriptManager()
local function exists(ft) local ok, it = pcall(function() return SM:FindItem(ft) end); return ok and it ~= nil end
function Z.CW() return CWm.getWindow() end
function Z.WW() return WWm.getWindow() end

-- ---- windows ---------------------------------------------------------------------------------------------
function Z.place()
    local c, w = Z.CW(), Z.WW()
    if not (c and w and CWm.isOpen() and WWm.isOpen()) then return false end
    if w._rolled then return false end
    local L = Z.lock
    if not L then
        local gap = ZeD.T and ZeD.T.px and ZeD.T.px(8) or 8
        local x0 = math.floor((core:getScreenWidth() - (c:getWidth() + gap + w:getWidth())) / 2)
        L = { right = x0 + c:getWidth(), left = x0 + c:getWidth() + gap, cy = c:getY(), wy = w:getY() }
        Z.lock = L
    end
    c._anchorRightEdge = L.right
    c:setX(L.right - c:getWidth()); w:setX(L.left); c:setY(L.cy); w:setY(L.wy)
    return true
end
function Z.tall()
    local c, w = Z.CW(), Z.WW()
    if not (c and w) then return end
    local m = ZeD.T.px(12)
    local h = core:getScreenHeight() - 2 * m
    Z.lock = nil
    for _, win in ipairs({ c, w }) do win:setY(m); win:setHeight(h); pcall(function() win:onResize() end) end
    Z.place()
end
function Z.openPair()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
    Z.place()
end
function Z.closePair()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(0)
    else if CWm.isOpen() then CWm.toggle(0) end; if WWm.isOpen() then WWm.close() end end
end
function Z.goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab or not win._drawerOpen then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
function Z.charTab(id) local w = Z.CW(); return (w and Z.goTab(w, w._tabStripPanel, id)) and true or false end
function Z.worldTab(id) local w = Z.WW(); return (w and Z.goTab(w, w._actionTabStrip, id)) and true or false end
-- every disclosure unfolded, every list at its top
local OPEN = { "_healthFigureExpanded", "_thermalFigureExpanded", "_identityPhotoExpanded", "_killsExpanded",
               "_skillsGridExpanded", "_equipListExpanded", "_moreDetailOpen", "_mapToolsExpanded", "_mapSideOpen", "_mapKeyOpen" }
local SCROLLS = { "_healthScroll", "_identityScroll", "_journalScroll", "_radioScroll", "_skillsScroll", "_thermalScroll",
                  "_equipScroll", "_forageScroll", "_animalsScroll", "_animalsRosterScroll", "_animalsDetailScroll" }
function Z.unfold()
    for _, w in ipairs({ Z.CW() or false, Z.WW() or false }) do
        if w then
            for _, k in ipairs(OPEN) do if w[k] ~= nil or k == "_moreDetailOpen" then w[k] = true end end
            w._healthFigureExpanded, w._thermalFigureExpanded, w._identityPhotoExpanded = true, true, true
            w._skillsGridExpanded, w._equipListExpanded = true, true
            for _, k in ipairs(SCROLLS) do local sp = w[k]; if sp and sp.setScrollPos then pcall(function() sp:setScrollPos(0) end) end end
        end
    end
end
function Z.mcList()
    local cl, wl = {}, {}
    for _, k in ipairs({ "back", "webbing" }) do local b = G.bags and G.bags[k]; if b then cl[#cl + 1] = b:getInventory() end end
    if G.trunk then wl[#wl + 1] = G.trunk end
    if G.duffel then wl[#wl + 1] = G.duffel:getInventory() end
    return cl, wl
end
function Z.colOn(win, inv2)
    for i, c in ipairs(win._containers or {}) do
        if c.inventory == inv2 then
            for _, j in ipairs(win._mcSelected or {}) do if j == i then return true end end
            return false
        end
    end
    return false
end
function Z.mc(on)
    local c, w = Z.CW(), Z.WW()
    if not (c and w) then return false end
    local cl, wl = Z.mcList()
    local done = true
    for _, i2 in ipairs(cl) do if Z.colOn(c, i2) ~= on then CWm.toggleColumn(i2); done = false end end
    for _, i2 in ipairs(wl) do if Z.colOn(w, i2) ~= on then WWm.toggleColumn(i2); done = false end end
    return done
end
function Z.selectItem(item)
    local w = Z.CW()
    local c = w and w._mainContent
    if not c then return false end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    c._selectedItems, c._lastClickedItem = sel, item
    w._updateDrawer(c)
    return true
end
function Z.found(ft)
    local items = inv:getItems()
    for i = 0, items:size() - 1 do if items:get(i):getFullType() == ft then return items:get(i) end end
    return nil
end
function Z.theme()
    if ZeD.currentBase ~= "dark" or ZeD.currentAccent ~= "teal" then ZeD.applyTheme("dark", "teal", ZeD.currentSize) end
    for _, w in ipairs({ Z.CW() or false, Z.WW() or false }) do if w then w._accentKey = nil end end
end

-- a scene: select the tab, set it up, settle, shoot (name = <char|world>_<tab>_<state>)
function Z.setup(fn)
    pcall(Z.place)
    G.faceFront()
    Z.sc.ok, Z.sc.why = true, ""
    if not fn then return end
    local ok, a, b = pcall(fn)
    if not ok then Z.sc.ok, Z.sc.why = false, tostring(a)
    elseif a == false then Z.sc.ok, Z.sc.why = false, tostring(b or "setup refused") end
end
function Z.finish(name)
    if Z.sc.ok then
        S.shot("tabs_" .. name)
        local c, w = Z.CW(), Z.WW()
        if not (c and w) then return end
        say(string.format("size %s: char %dx%d tab %s | world %dx%d tab %s", name, c:getWidth(), c:getHeight(), tostring(c._activeTab),
            w:getWidth(), w:getHeight(), tostring(w._activeTab)))
        -- (Nov 11 2026) what else is in the picture: a loot card means the real pointer sat on a row (pzlaunchwin
        -- parks it now); a moodle note says whether its layer stood over the windows
        local IT = ZeD.InvTip
        local wt = IT and IT._want
        if wt and wt.content and wt.frame and IT._frame and wt.frame >= IT._frame - 1 then
            say("WARN " .. name .. ": a loot card is up (" .. tostring(wt.item and wt.item:getName()) .. "): the pointer is on a row")
        end
        local ml = ZeD.Moodles and ZeD.Moodles.getLayer and ZeD.Moodles.getLayer(0)
        if ml and ml._chip then say(name .. ": moodle note up, over the windows " .. tostring(ml._raised == true)) end
    else S.err(name, Z.sc.why) end
end
function Z.T(name, which, tab, settle, fn)
    S.step(2, function() Z.sc.ok, Z.sc.why = true, "" end)
    S.poll(2, 120, function()
        if which == "c" then return Z.charTab(tab) end
        return Z.worldTab(tab)
    end, function() Z.sc.ok = false; Z.sc.why = "no tab " .. tab .. " (hidden?)" end)
    S.step(6, function() Z.park(); Z.unfold(); Z.tall() end)
    S.step(20, function() if Z.sc.ok then Z.park(); Z.unfold(); Z.setup(fn) end end)
    S.step(settle or 45, function() Z.finish((which == "c" and "char_" or "world_") .. name) end)
end
function Z.recipe(kind, open)
    local w = Z.WW()
    local mod = (kind == "craft") and ZeD.CraftingTab or ZeD.BuildingTab
    local st = (kind == "craft") and w._craftState or w._buildState
    if not st then return false, "no " .. kind .. " state" end
    if not open then ZeD.CraftingCore.closeCraft(st); return true end
    local data = mod.gatherData(p, w)
    local pick = nil
    for _, rd in ipairs(data and data.recipes or {}) do if rd.status == "unlocked" then pick = rd; break end end
    pick = pick or (data and data.recipes and data.recipes[1])
    if not pick then return false, "no recipe" end
    ZeD.CraftingCore.openCraft(st, pick.entry.name)
    return true
end
function Z.search(kind, text)
    local w = Z.WW()
    local st = (kind == "craft") and w._craftState or w._buildState
    if st then st.search = text end
end
function Z.park() pcall(function() Mouse.setXY(core:getScreenWidth() - 4, core:getScreenHeight() - 4) end) end
function Z.mp() local w = Z.WW(); return w and w._worldMapPanel end

-- ---- what is shown at the start / end of every pass -------------------------------------------------------
local was = {}
S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G.cleanLook(); G.day()
    pcall(Opt.reapplyFromOptions)
    -- UI scale 1x for the review (the director's value is put back at the end of the last pass)
    if Opt.uiScaleOption then
        if DRV_SCALE_WAS == nil then DRV_SCALE_WAS = Opt.uiScaleOption:getValue() or 1 end
        Opt.uiScaleOption:setValue(4)
        pcall(function() Opt.applyScale(4) end)
    end
    Z.theme()
    -- solid windows for the pictures (Nov 11 2026): the run keeps the director's see-through 90 with "Solid while in
    -- use" on, so the window the pointer was not over drew see-through (the World window in loot_full and
    -- health_full). See-through 100 for the review; the director's value is put back at the end of the last pass.
    if Opt.setSeeThrough and Opt.seeThroughIndex then
        if DRV_SEE_WAS == nil then DRV_SEE_WAS = Opt.seeThroughIndex() end
        pcall(function() Opt.setSeeThrough(1) end)
        say("see-through " .. tostring(Opt.seeThrough and Opt.seeThrough()) .. " (was option " .. tostring(DRV_SEE_WAS) .. ")")
    end
    say(string.format("mode %s | theme %s %s | scale option %s (was %s) -> %s | screen %dx%d", MODE, tostring(ZeD.currentBase),
        tostring(ZeD.currentAccent), tostring(Opt.uiScaleOption and Opt.uiScaleOption:getValue()), tostring(DRV_SCALE_WAS),
        tostring(ZeD.Scale and ZeD.Scale.userScale) .. " px(100)=" .. tostring(ZeD.T.px(100)), core:getScreenWidth(), core:getScreenHeight()))
    was.ctx = Opt.contextStyleOption:getValue()
    was.equip = ZeD.EquipDoll.view()
    Opt.contextStyleOption:setValue(1)
    G.stand()
end)

-- gallery_v3_stage.lua's putAside, for the empty pass (it runs before the stage is loaded)
local function putAside()
    G.R = G.R or {}
    local R = G.R
    if R.aside then return end
    R.aside = true
    R.prim, R.sec = p:getPrimaryHandItem(), p:getSecondaryHandItem()
    R.hot = {}
    local hb = getPlayerHotbar and getPlayerHotbar(pn)
    if hb then
        for i, it in pairs(hb.attachedItems or {}) do R.hot[#R.hot + 1] = { i = i, it = it } end
        for _, h in ipairs(R.hot) do pcall(function() hb:removeItem(h.it, false) end) end
    end
    R.worn = {}
    pcall(function()
        local wi = p:getWornItems()
        for i = 0, wi:size() - 1 do R.worn[#R.worn + 1] = { it = wi:get(i):getItem(), loc = wi:get(i):getLocation() } end
    end)
    pcall(function() p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil) end)
    for _, w in ipairs(R.worn) do pcall(function() p:removeWornItem(w.it, false) end) end
    R.items = {}
    local items = inv:getItems()
    for i = 0, items:size() - 1 do R.items[#R.items + 1] = items:get(i) end
    for _, it in ipairs(R.items) do pcall(function() inv:Remove(it) end) end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    say(string.format("aside: %d worn, %d on the belt, %d items", #R.worn, #R.hot, #R.items))
end
local function bareCharacter()
    putAside()
    -- the QA character is short-sighted: glasses on, or the game blurs the world
    local g = inv:AddItem("Base.Glasses_Prescription")
    if g then pcall(function() p:setWornItem(g:getBodyLocation(), g) end); Z.tmp.glasses = g end
    pcall(function() p:getBodyDamage():RestoreToFullHealth() end)
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    say("bare: glasses " .. tostring(Z.tmp.glasses ~= nil))
end

do
    -- ===================================== LOT: both windows ================================================
    local E = (MODE == "empty")
    local ST = (E and "empty" or "full")
    if E then S.step(5, function() bareCharacter() end) end
    if E then   -- leftovers on the floor round the character (earlier staging) out, so the ground starts empty
        S.step(5, function()
            local n = 0
            local px, py = math.floor(p:getX()), math.floor(p:getY())
            for dx = -3, 3 do for dy = -3, 3 do
                local sq = G.sqAt(px + dx, py + dy)
                if sq then
                    local wo = sq:getWorldObjects()
                    for i = wo:size() - 1, 0, -1 do
                        local o = wo:get(i)
                        pcall(function() sq:transmitRemoveItemFromSquare(o); o:removeFromWorld(); o:removeFromSquare(); n = n + 1 end)
                    end
                end
            end end
            say("floor cleared: " .. n .. " things")
        end)
    end
    S.step(5, function() Z.openPair() end)
    S.step(40, function() Z.tall(); Z.theme(); G.faceFront() end)

    -- staging that is only for the full pass
    if not E then
        S.step(2, function()
            -- papers, notebook, magazine for the Journal
            for _, ft in ipairs({ "Base.Newspaper", "Base.Notebook", "Base.Magazine", "Base.Flier" }) do
                if exists(ft) then local it = inv:AddItem(ft); if it then Z.tmp.paper = Z.tmp.paper or {}; Z.tmp.paper[#Z.tmp.paper + 1] = it end end
            end
            -- a walkie in the off hand, on a station
            pcall(function()
                Z.tmp.walkie = inv:AddItem("Base.WalkieTalkie2")
                Z.tmp.offWas = p:getSecondaryHandItem()
                p:setSecondaryHandItem(Z.tmp.walkie)
                local dd = Z.tmp.walkie:getDeviceData()
                dd:setHasBattery(true); dd:setPower(0.8); dd:setIsTurnedOn(true); dd:setDeviceVolume(0.5); dd:setChannel(98000)
            end)
            -- a cooking base and things to cook
            Z.tmp.cook = {}
            local want = { "Base.Pot", "Base.Potato", "Base.Carrots", "Base.Onion", "Base.Steak", "Base.Cabbage" }
            -- the game's own dish bases (what the Cooking tab looks for), a few of them
            local seen, nb = {}, 0
            pcall(function()
                local list = getEvolvedRecipes()
                for i = 0, list:size() - 1 do
                    local r = list:get(i)
                    local b = tostring(r:getBaseItem() or "")
                    if not b:find(".", 1, true) then b = "Base." .. b end
                    if nb < 6 and not seen[b] and not r:isHidden() and b ~= "Base.Pot" then
                        seen[b] = true; nb = nb + 1; want[#want + 1] = b
                    end
                end
            end)
            for _, ft in ipairs(want) do
                if exists(ft) then local it = inv:AddItem(ft); if it then Z.tmp.cook[#Z.tmp.cook + 1] = it end end
            end
            say("cook items: " .. table.concat(want, " "))
            for _, it in ipairs(Z.tmp.cook) do   -- the pot with water in it (a bare pot offers no dish)
                if it:getFullType() == "Base.Pot" then pcall(function() it:getFluidContainer():addFluid("Water", 1.0) end) end
            end
            say("staged: walkie " .. tostring(Z.tmp.walkie ~= nil) .. " paper " .. tostring(#(Z.tmp.paper or {})) .. " cook " .. #Z.tmp.cook)
        end)
    end
    -- a radio set on the square (World Radio tab), off when empty, on when full; a pen and a hen when full
    S.step(2, function()
        pcall(function()
            local sq = p:getSquare()
            local o = IsoRadio.new(getCell(), sq, getSprite("appliances_radio_01_0"))
            sq:AddTileObject(o)
            Z.tmp.set = o
            local dd = o:getDeviceData()
            dd:setHasBattery(true); dd:setPower(0.8); dd:setDeviceVolume(0.5); dd:setChannel(98000)
            dd:setIsTurnedOn(not E)
        end)
        if not E then
            local px, py = math.floor(p:getX()), math.floor(p:getY())
            pcall(function() DesignationZoneAnimal.new("QA Pen", px - 4, py - 4, 0, px + 4, py + 4, true) end)
            pcall(function() Z.tmp.zone = DesignationZoneAnimal.getZoneByName("QA Pen") end)
            pcall(function()
                local breed = AnimalDefinitions.getDef("hen"):getBreeds():get(0)
                Z.tmp.hen = addAnimal(getCell(), px + 2, py - 2, 0, "hen", breed)
                Z.tmp.hen:addToWorld()
            end)
        end
        say("staged: radio set " .. tostring(Z.tmp.set ~= nil) .. " zone " .. tostring(Z.tmp.zone ~= nil) .. " hen " .. tostring(Z.tmp.hen ~= nil))
    end)
    S.step(60, function() Z.tall() end)

    -- ---- Character ----
    if not E then
        Z.T("health_" .. ST, "c", "health", 45, function()
            local bd = p:getBodyDamage()
            Z.tmp.god = p:isGodMod()
            pcall(function() p:setGodMod(false) end)
            local function try(name, f) local ok, e = pcall(f); if not ok then say("hurt " .. name .. ": " .. tostring(e)) end end
            try("scratch", function() bd:getBodyPart(BodyPartType.Hand_L):setScratched(true, true) end)
            try("cut", function() bd:getBodyPart(BodyPartType.ForeArm_R):setCut(true, true) end)
            try("deep", function() bd:getBodyPart(BodyPartType.UpperLeg_L):setDeepWounded(true) end)
            try("bleed", function() bd:getBodyPart(BodyPartType.Foot_R):setBleeding(true) end)
            try("pain", function() bd:getBodyPart(BodyPartType.Head):setAdditionalPain(20) end)
            try("bandage", function() bd:getBodyPart(BodyPartType.Torso_Upper):setBandaged(true, 5, true, "Base.Bandage") end)
            try("sync", function() bd:Update() end)
        end)
        S.step(2, function() if Z.tmp.god ~= nil then pcall(function() p:setGodMod(Z.tmp.god) end) end end)
    end
    -- (with no injuries the fill blocks sit right under the figure)
    if E then Z.T("health_" .. ST, "c", "health", 45) end
    -- the tags with no boxes (Nov 11 2026): the injury tags above (char_health_full), the inventory rows' Belt 2 by the
    -- belt's items (char_loot_full: the M9 Pistol) and the Equipment list's belt rows and In hand (char_equip_list_full)
    if not E then
        Z.T("loot_" .. ST, "c", "loot", 45)
        Z.T("equip_list_" .. ST, "c", "equip", 50, function() ZeD.EquipDoll.setView("list"); if ZeD.EquipLoadout.openFor then ZeD.EquipLoadout.openFor[pn] = true end end)
    end
    Z.T("thermal_" .. ST, "c", "thermal", 45)
    if E then Z.T("identity_" .. ST, "c", "identity", 45) end
    if not E then
        Z.T("journal_notebooks_" .. ST, "c", "journal", 45, function() Z.CW()._journalSubTab = 2 end)
        -- no notebook on the character: every notebook, journal and diary off them for the picture
        -- (Nov 11 2026: the tab looks in every bag, and the stage's satchel holds a notebook: the first retake took
        -- only the main inventory's and the satchel's stayed listed. Every container now, each put back where it was.)
        S.step(2, function()
            Z.tmp.nb = {}
            local function walk(c)
                local items = c:getItems()
                for i = items:size() - 1, 0, -1 do
                    local it = items:get(i)
                    if it:getCategory() == "Literature" and it:canBeWrite() then Z.tmp.nb[#Z.tmp.nb + 1] = { it = it, c = c } end
                    if instanceof(it, "InventoryContainer") then walk(it:getInventory()) end
                end
            end
            walk(inv)
            local where = {}
            for _, e in ipairs(Z.tmp.nb) do
                pcall(function() e.c:Remove(e.it) end)
                where[#where + 1] = (e.c == inv) and "main" or tostring(e.c:getType())
            end
            pcall(function() ZeD.JournalReaders.refresh(Z.CW()) end)
            say("notebooks off for the picture: " .. #Z.tmp.nb .. " (" .. table.concat(where, " ") .. ")")
        end)
        Z.T("journal_notebooks_none_" .. ST, "c", "journal", 45, function() Z.CW()._journalSubTab = 2 end)
        S.step(2, function()
            for _, e in ipairs(Z.tmp.nb or {}) do pcall(function() e.c:AddItem(e.it) end) end
            Z.tmp.nb = nil
            pcall(function() ZeD.JournalReaders.refresh(Z.CW()) end)
        end)
        Z.T("journal_loadouts_" .. ST, "c", "journal", 45, function() Z.CW()._journalSubTab = 5 end)
        S.step(2, function() Z.CW()._journalSubTab = 1 end)
        Z.T("radio_" .. ST, "c", "radio", 45)
    end
    S.step(2, function() Z.charTab("loot") end)

    -- ---- World ----
    Z.T("furniture_" .. ST, "w", "furniture", 60)
    if not E then
        Z.T("radio_" .. ST, "w", "radio", 60)
        S.step(2, function()
            local w = Z.WW()
            say("world radio drawer " .. tostring(w and w._drawerEffW) .. " (full card " .. tostring(ZeD.T.px(480)) .. ")")
        end)
    end
    S.step(2, function() Z.worldTab("loot"); Z.charTab("loot") end)

    -- clean up
    S.step(2, function()
        pcall(function() Z.mc(false) end)
        pcall(function() if Z.tmp.walkie then p:setSecondaryHandItem(Z.tmp.offWas); inv:Remove(Z.tmp.walkie) end end)
        pcall(function() local o = Z.tmp.set; if o then o:getSquare():transmitRemoveItemFromSquare(o) end end)
        pcall(function() if Z.tmp.hen then Z.tmp.hen:removeFromWorld(); Z.tmp.hen:removeFromSquare() end end)
        pcall(function() if Z.tmp.zone then DesignationZoneAnimal.removeZone(Z.tmp.zone, true) end end)
        for _, it in ipairs(Z.tmp.paper or {}) do pcall(function() inv:Remove(it) end) end
        for _, it in ipairs(Z.tmp.cook or {}) do pcall(function() inv:Remove(it) end) end
        pcall(function() p:getBodyDamage():RestoreToFullHealth() end)
        if E and Z.tmp.glasses then pcall(function() p:removeWornItem(Z.tmp.glasses, false); inv:Remove(Z.tmp.glasses) end) end
        Z.tmp = {}
        say("cleaned up")
    end)
end

S.step(10, function()
    Opt.contextStyleOption:setValue(was.ctx or 1)
    ZeD.EquipDoll.setView(was.equip)
    if MODE == "full" and Opt.uiScaleOption and DRV_SCALE_WAS then
        Opt.uiScaleOption:setValue(DRV_SCALE_WAS)
        pcall(function() Opt.applyScale(DRV_SCALE_WAS) end)
        say("UI scale option back: " .. tostring(Opt.uiScaleOption:getValue()))
    end
    if MODE == "full" and DRV_SEE_WAS and Opt.setSeeThrough then
        pcall(function() Opt.setSeeThrough(DRV_SEE_WAS) end)
        say("see-through back: " .. tostring(Opt.seeThrough and Opt.seeThrough()))
        DRV_SEE_WAS = nil
    end
end)
S.start()
