-- ZeDUI/tools/qa/zedqa_tab_review.lua  (Nov 11 2026, QA): the tab review. Every tab of both ZeD windows that can hold
-- content, each shown EMPTY and FULL, one full-screen picture each (1920x1080 window, UI scale 1x, Dark + PZ Teal,
-- 19px game font): tabs_<char|world>_<tab>_<empty|full>.png in Zomboid/Screenshots (zedqa_tab_review_collect.ps1 moves
-- them to the review folder). Runs three times in one manifest (tab_review.txt), by the order of the calls:
--   1st (tag tabr)   EMPTY: after gallery_v3_core/reveal, the character put aside (bare, glasses only), nothing staged
--   2nd (tag tabr2)  FULL : after gallery_v3_stage (kit, car with a full trunk, duffel, ground things)
--   3rd (tag tabr3)  WOODS: Foraging empty / full (search mode, finds spotted), far from the lot
-- Contextual tabs that the game hides when nothing is near (Vehicle, Cooking, the Character Radio) have a FULL
-- picture only. Server / Admin tabs exist on a server only (not shot). Everything spawned is removed again; the
-- teardown script puts the rest back. grep "ZEDQA tabr".
local G = GAL
TABR_N = (TABR_N or 0) + 1
local MODE = ({ "empty", "full", "woods" })[TABR_N] or "empty"
local TAG = "tabr" .. ((TABR_N > 1) and tostring(TABR_N) or "")
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
        if TABR_SCALE_WAS == nil then TABR_SCALE_WAS = Opt.uiScaleOption:getValue() or 1 end
        Opt.uiScaleOption:setValue(4)
        pcall(function() Opt.applyScale(4) end)
    end
    Z.theme()
    say(string.format("mode %s | theme %s %s | scale option %s (was %s) -> %s | screen %dx%d", MODE, tostring(ZeD.currentBase),
        tostring(ZeD.currentAccent), tostring(Opt.uiScaleOption and Opt.uiScaleOption:getValue()), tostring(TABR_SCALE_WAS),
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

if MODE == "woods" then
    -- ===================================== WOODS: Foraging ==================================================
    local site = nil
    local function natural(sq)
        local fl = sq and sq:getFloor()
        local nm = string.lower(tostring(fl and fl:getSprite() and fl:getSprite():getName() or ""))
        return nm:find("natural", 1, true) ~= nil
    end
    local function findClearing(cx, cy, r)
        local cell = getCell()
        local best, bd = nil, 1e9
        for dx = -r, r, 3 do for dy = -r, r, 3 do
            local x, y = cx + dx, cy + dy
            local sq = cell:getGridSquare(x, y, 0)
            if sq and natural(sq) and not sq:getBuilding() then
                local ok, trees = true, 0
                for ex = -2, 2 do for ey = -2, 2 do
                    local s2 = cell:getGridSquare(x + ex, y + ey, 0)
                    if not s2 or s2:getTree() or not natural(s2) then ok = false end
                end end
                if ok then
                    for ex = -12, 12, 2 do for ey = -12, 12, 2 do
                        local s2 = cell:getGridSquare(x + ex, y + ey, 0)
                        if s2 and s2:getTree() then trees = trees + 1 end
                    end end
                    local d = dx * dx + dy * dy
                    if trees >= 6 and d < bd then best, bd = { x, y, trees }, d end
                end
            end
        end end
        return best
    end
    S.step(5, function() Z.closePair() end)
    local SPOTS = { { 8800, 10800 }, { 9500, 11600 }, { 10300, 12000 }, { 8200, 9800 } }
    for k = 1, #SPOTS do
        S.step(5, function() if not site then G.tp(SPOTS[k][1] + 0.5, SPOTS[k][2] + 0.5, 0) end end)
        S.step(150, function()
            if site then return end
            site = findClearing(SPOTS[k][1], SPOTS[k][2], 60)
            say("woods spot " .. k .. ": " .. tostring(site and (site[1] .. "," .. site[2] .. " (" .. site[3] .. " trees)")))
        end)
    end
    S.step(10, function()
        if not site then say("ERR no woods clearing"); return end
        G.tp(site[1] + 0.5, site[2] + 0.5, 0)
        p:setDir(IsoDirections.S)
    end)
    S.step(120, function() Z.openPair(); Z.theme() end)
    Z.T("forage_empty", "w", "forage", 60)
    -- the search on, crouched, finds spotted until the list holds a few
    S.step(30, function()
        local ww = Z.WW()
        local mgr = ISSearchManager.getManager(p)
        if mgr and not mgr.isSearchMode then pcall(function() ZeD.ForagingTab.toggleSearch(ww) end) end
        say("search mode " .. tostring(mgr and mgr.isSearchMode))
    end)
    local tries, last, tick = 0, -9999, 0
    S.poll(30, 2400, function()
        tick = tick + 30
        pcall(function() p:setSneaking(true) end)
        local mgr = ISSearchManager.getManager(p)
        if mgr and not mgr.isSearchMode then pcall(function() ZeD.ForagingTab.toggleSearch(Z.WW()) end) end
        local q = ZeD.ForagingTab._findQueues[pn] or {}
        if #q >= 6 or not mgr then return true end
        if tick < 480 or tick - last < 120 then return false end
        last = tick; tries = tries + 1
        local best, bd = nil, 1e9
        local reach = (tonumber(mgr.radius) or 6) + 3
        for _, icon in pairs(mgr.activeIcons or {}) do
            local seen = true
            pcall(function() seen = icon:getIsSeen() end)
            if not seen and icon.xCoord and icon.yCoord then
                local d = math.sqrt((icon.xCoord - p:getX()) ^ 2 + (icon.yCoord - p:getY()) ^ 2)
                if d <= reach and d < bd then best, bd = icon, d end
            end
        end
        if best then pcall(function() best:spotIcon() end) elseif mgr.currentZone then pcall(function() mgr:doMoveIconNearPlayer() end) end
        return tries >= 14
    end, function() say("note: finds did not reach 6") end)
    Z.T("forage_full", "w", "forage", 60)
    S.step(5, function()
        pcall(function() p:setSneaking(false) end)
        local mgr = ISSearchManager.getManager(p)
        if mgr and mgr.isSearchMode then pcall(function() ZeD.ForagingTab.toggleSearch(Z.WW()) end) end
        say("forage done; finds " .. tostring(#(ZeD.ForagingTab._findQueues[pn] or {})))
    end)
else
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
    S.step(2, function() if not E then Z.charTab("loot"); Z.worldTab("loot") end end)
    if not E then S.poll(10, 600, function() return Z.mc(true) end, function() say("note: columns did not all come on") end) end
    Z.T("loot_" .. ST, "c", "loot", 45)
    Z.T("equip_list_" .. ST, "c", "equip", 50, function() ZeD.EquipDoll.setView("list"); if ZeD.EquipLoadout.openFor then ZeD.EquipLoadout.openFor[pn] = true end end)
    Z.T("equip_doll_" .. ST, "c", "equip", 50, function() ZeD.EquipDoll.setView("doll") end)
    S.step(2, function() ZeD.EquipDoll.setView(was.equip) end)
    Z.T("health_" .. ST, "c", "health", 45, function()
        if E then return end
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
    Z.T("thermal_" .. ST, "c", "thermal", 45)
    Z.T("identity_" .. ST, "c", "identity", 45)
    for i, sub in ipairs({ "journal", "notebooks", "papers", "recipes", "loadouts" }) do
        Z.T("journal_" .. sub .. "_" .. ST, "c", "journal", 45, function() Z.CW()._journalSubTab = i end)
    end
    S.step(2, function() Z.CW()._journalSubTab = 1 end)
    if not E then Z.T("skills_" .. ST, "c", "skills", 45) end   -- (no empty state: every skill is always listed)
    if not E then
        Z.T("radio_" .. ST, "c", "radio", 45)
        Z.T("cooking_" .. ST, "c", "cooking", 45)
    end
    S.step(2, function() Z.charTab("loot") end)

    -- item cards, full width (480): food, weapon, container
    if not E then
        for _, c in ipairs({ { "card_food", "Base.Apple" }, { "card_weapon", "Base.Machete" }, { "card_container", "bag" } }) do
            Z.T("loot_" .. c[1] .. "_full", "c", "loot", 45, function()
                local it = (c[2] == "bag") and G.bags.back or Z.found(c[2])
                if not it then return false, "no " .. c[2] end
                if not Z.selectItem(it) then return false, "Loot list not ready" end
            end)
            S.step(2, function() Z.selectItem(nil) end)
        end
    end

    -- ---- World ----
    Z.T("loot_" .. ST, "w", "loot", 45)
    Z.T("craft_list_" .. ST, "w", "craft", 60, function() if E then Z.search("craft", "zzzzqq") else Z.search("craft", "") end end)
    if not E then
        Z.T("craft_recipe_full", "w", "craft", 60, function() return Z.recipe("craft", true) end)
        S.step(2, function() Z.recipe("craft", false) end)
    end
    S.step(2, function() Z.search("craft", "") end)
    Z.T("build_list_" .. ST, "w", "build", 60, function() if E then Z.search("build", "zzzzqq") else Z.search("build", "") end end)
    if not E then
        Z.T("build_recipe_full", "w", "build", 60, function() return Z.recipe("build", true) end)
        S.step(2, function() Z.recipe("build", false) end)
    end
    S.step(2, function() Z.search("build", "") end)
    Z.T("furniture_" .. ST, "w", "furniture", 60)
    Z.T("maps_" .. ST, "w", "maps", 90, function()
        pcall(function() Z.mp().mapAPI:centerOn(p:getX(), p:getY()) end)
        pcall(function() Z.mp():_zoomTo(15) end)
        if not E then
            local ok, e = pcall(function()
                local api = Z.mp().mapAPI:getSymbolsAPI()
                Z.tmp.sym = api
                Z.tmp.symN = api:getSymbolCount()
                local lay = api:getDefaultTextLayerID()
                for _, t in ipairs({ { "QA camp", 25, 12 }, { "Cache", -30, -25 }, { "Safe route", 10, -40 } }) do
                    local ts = api:addUntranslatedText(t[1], lay, p:getX() + t[2], p:getY() + t[3])
                    ts:setRGBA(0.1, 0.1, 0.1, 1.0); ts:setAnchor(0.5, 0.5); ts:setScale(ISMap.SCALE)
                end
            end)
            say("map symbols: " .. tostring(ok) .. " " .. tostring(ok and "" or e))
        end
    end)
    S.step(2, function() pcall(function()
        local api = Z.tmp.sym
        if api and Z.tmp.symN then while api:getSymbolCount() > Z.tmp.symN do api:removeSymbolByIndex(api:getSymbolCount() - 1) end end
    end) end)
    Z.T("animals_" .. ST, "w", "animals", 60, function()
        local st = Z.WW()._animalsState
        if st then st.submode = "ranch"; st.view = "overview"; st.zoneName = nil end
    end)
    if not E then
        Z.T("animals_zone_full", "w", "animals", 200, function()
            local w = Z.WW()
            w._animalsState = w._animalsState or { submode = "ranch" }
            local st = w._animalsState
            st.submode = "ranch"; st.prevView = "overview"; st.view = "zone"; st.zoneName = "QA Pen"
        end)
        S.step(2, function() local st = Z.WW()._animalsState; if st then st.view = "overview"; st.zoneName = nil end end)
    end
    Z.T("radio_" .. ST, "w", "radio", 60)
    if not E then Z.T("vehicle_full", "w", "vehicle", 60) end   -- (hidden with no vehicle in reach: no empty state)

    -- the belt (windows shut)
    S.step(2, function() Z.worldTab("loot"); Z.charTab("loot") end)
    S.step(30, function() Z.closePair() end)
    S.step(40, function() G.faceFront() end)
    Z.Sc = nil
    S.step(30, function() Z.sc.ok = true; Z.finish("belt_" .. ST) end)
    S.step(2, function() Z.openPair() end)
    S.step(40, function() Z.tall() end)

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
    if MODE == "woods" and Opt.uiScaleOption and TABR_SCALE_WAS then
        Opt.uiScaleOption:setValue(TABR_SCALE_WAS)
        pcall(function() Opt.applyScale(TABR_SCALE_WAS) end)
        say("UI scale option back: " .. tostring(Opt.uiScaleOption:getValue()))
    end
end)
S.start()
