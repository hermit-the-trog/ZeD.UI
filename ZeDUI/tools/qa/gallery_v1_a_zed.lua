-- ZeDUI/tools/qa/gallery_v1_a_zed.lua  (Nov 17 2026, QA): the ZeD-GUI 1.0 gallery, ZeD's half of set A
-- (ZeDUI/HANDOFF_design_gallery_v1_20261117.md, "For QA: the shot list"; the storyboard cards in
-- workshop/gallery/v1_plan/storyboard.html). Manifest gallery_v1_a_zed.txt: after gallery_story_stage.lua (Angel at the
-- Fossoil, West Point), gallery_unload.lua (every container within its weight limit) and gallery_v1_a_common.lua (G1).
-- The story look: Light + Blue, daylight 11:00. 4K at 1.75x, the list view, font 19px (the runner's fontSize=2).
-- THE RULE for every picture: the window shown sits to one side or along the top; Angel and the place stay uncovered
-- (a window over the character is moved to the left or right edge, logged "moved ..."; each box is logged, with
-- "COVERS the character" if one still does).
--   08  g1_08_intro             the forecourt (STORY.P.smoke), both windows on their first tabs, the belt, nothing else
--   17  g1_17_zed               the stock spot (STORY.P.stock): the Character window's inventory (three apples given,
--                               their stack open: header row and each apple on its row), the World window on the shelf
--                               G1.fillShelf filled (the same ten things as the vanilla run), one source each, zoom 1.0
--   01  g1_01_zed               the same moment at zoom 0.75 (Angel and the windows bigger, for the 116 x 65 thumbnail)
--   21  g1_21_equip_doll        the forecourt, the Character window alone on Equipment in doll view
--   26  g1_26_zed               the forecourt, the Character window alone on Health, the figure open, a bandaged scratch
--                               on the left forearm (the same wound as g1_26_vanilla)
--   39/40 g1_39_identity_tall, g1_39_identity_traits, g1_39_skills_tall: the forecourt, the Character window alone and
--                               tall along the left edge (Identity: the license; scrolled to the traits; Skills), the
--                               skills six days in (as gallery_story_who.lua), 23 kills; one retake used in both
--   35  g1_35_stew_plan         behind the counter (STORY.P.clerk): a pot of water, carrots, potato and cabbage, the
--                               Cooking tab with a Stew planned (3 of 6); not made
--       g1_35_dish_list         the stew saved, the Dish list open: the saved stew first, then the pot's dishes
--   25  g1_25_left, g1_25_bottom, g1_25_right: windows shut, the forecourt, five moodles held (stressed, hungry,
--                               thirsty, bored, the scratch's pain when it shows), the balloon open on the Stressed
--                               moodle with its tail on it, in each of the three places (left, above the belt, right)
-- Puts back: the theme (reapplied from the options), the window places and sizes, the equip view, the moodle place,
-- the stats, the wound, the kills and favorite weapon, the saved dishes, everything given, the shelf, the game speed.
-- The skills go back with gallery_story_teardown.lua (the stage kept them). grep "ZEDQA g1z".
-- (Nov 18 2026, the pitch retakes: G1Z_ONLY = { ["01"] = true, ["26"] = true } takes only those beats (01 runs with
-- 17's staging; only 01's picture is wanted) and G1Z_LOOK = { "dark", "teal" } replaces the story's Light + Blue.
-- gallery_v1_pitch_only.lua sets both.)
local function want(k) return (not G1Z_ONLY) or G1Z_ONLY[k] == true end
local S = { was = {}, made = {} }
local Q = G1 and G1.make and G1.make("g1z")
if not Q then print("ZEDQA g1z ERR run gallery_v1_a_common.lua first"); print("ZEDQA g1z DONE"); return end
if not G1.zed then Q.say("ERR ZeD is not loaded: this script is for the ZeD run"); Q.say("DONE"); return end
if not (STORY and STORY.ready and STORY.P) then Q.say("ERR run gallery_story_stage.lua first"); Q.say("DONE"); return end
S.p, S.pn, S.core = G1.p, G1.pn, G1.core
S.CWm, S.WWm = ZeD_CharacterWindow, ZeD_WorldWindow
S.P = STORY.P
S.SKILLS = {
    { "Mechanics", 7, 0.35 }, { "Maintenance", 6, 0.2 }, { "MetalWelding", 6, 0.1 },
    { "Electricity", 3, 0.4 }, { "Woodwork", 3, 0.15 }, { "SmallBlunt", 3, 0.5 },
    { "Cooking", 2, 0.3 }, { "Sprinting", 2, 0.6 }, { "Sneak", 2, 0.2 }, { "Doctor", 2, 0.1 },
    { "Lightfoot", 1, 0.5 }, { "Nimble", 1, 0.4 }, { "PlantScavenging", 1, 0.3 }, { "Aiming", 1, 0.2 },
    { "Fitness", 6, 0.3 },
}
S.MOOD = { STRESS = 0.6, HUNGER = 0.45, THIRST = 0.45, BOREDOM = 0.6 }

-- ===================================================================== windows
function S.CW() return S.CWm.getWindow() end
function S.WW() return S.WWm.getWindow() end
function S.goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab or (tab ~= "loot" and win._drawerOpen == false) then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
function S.charTab(id) local w = S.CW(); return (w and S.goTab(w, w._tabStripPanel, id)) and true or false end
function S.worldTab(id) local w = S.WW(); return (w and S.goTab(w, w._actionTabStrip, id)) and true or false end
-- the first tab of a strip (the leftmost tab zone)
function S.firstTab(strip)
    local best = nil
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if tostring(z.id):sub(1, 4) == "tab:" and (not best or z.x < best.x) then best = z end
    end
    return best and tostring(best.id):sub(5) or nil
end
function S.openPair()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (S.CWm.isOpen() and S.WWm.isOpen()) then S.CWm.toggleBothPaired(S.pn) end
end
function S.closePair()
    if S.CWm.isOpen() and S.WWm.isOpen() then S.CWm.toggleBothPaired(S.pn)
    else
        if S.CWm.isOpen() then S.CWm.toggle(S.pn) end
        if S.WWm.isOpen() then S.WWm.close(S.pn) end
    end
end
-- the Character window alone (the World window shut)
function S.charOnly()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not S.CWm.isOpen() then S.CWm.toggle(S.pn) end
    if S.WWm.isOpen() then S.WWm.close(S.pn) end
end
function S.clearChar()
    G1.clear(Q, S.CW(), "left", "the Character window")
    G1.clear(Q, S.WW(), "right", "the World window")
end
function S.keepBox(w)
    if not w then return nil end
    return { x = w:getX(), y = w:getY(), h = w:getHeight(), a = w._anchorRightEdge }
end
function S.putBox(w, b)
    if not (w and b) then return end
    pcall(function() w:setHeight(b.h); w:onResize() end)
    w:setX(b.x); w:setY(b.y)
    w._anchorRightEdge = b.a
end
function S.lightBlue()
    local b, a = "light", "blue"
    if G1Z_LOOK then b, a = G1Z_LOOK[1], G1Z_LOOK[2] end
    ZeD.applyTheme(b, a, ZeD.currentSize)
    local c, w = S.CW(), S.WW()
    if c then c._accentKey = a end
    if w then w._accentKey = a end
end
-- one source per window: every extra column off (as gallery_b19_a.lua)
function S.oneSource()
    local done = true
    for _, pair in ipairs({ { S.CW(), S.CWm }, { S.WW(), S.WWm } }) do
        local win, mod = pair[1], pair[2]
        if win then
            for _, j in ipairs(win._mcSelected or {}) do
                local c = win._containers and win._containers[j]
                if c and c.inventory and mod.toggleColumn and #(win._mcSelected or {}) > 1 then mod.toggleColumn(c.inventory); done = false; break end
            end
        end
    end
    return done
end
-- the Character list's apple stack opened or shut (as gallery_b19_a.lua)
function S.openStack(ft, on)
    local cnt = S.CW() and S.CW()._mainContent
    if not cnt then return nil end
    local best = nil
    for _, stk in pairs(cnt._stacks or {}) do
        local ok, full = pcall(function() return stk.rep:getFullType() end)
        if ok and full == ft and stk.count and stk.count > 1 and (not best or stk.count > best.count) then best = stk end
    end
    for _, stk in ipairs(cnt._openHeads or {}) do
        local ok, full = pcall(function() return stk.rep:getFullType() end)
        if ok and full == ft and stk.count and stk.count > 1 and (not best or stk.count > best.count) then best = stk end
    end
    if not best then return nil end
    cnt._expandedStacks = cnt._expandedStacks or {}
    cnt._expandedStacks[best.key] = on or nil
    for _, cs in ipairs(cnt._colStates or {}) do
        cs.expandedStacks = cs.expandedStacks or cnt._expandedStacks
        cs.expandedStacks[best.key] = on or nil
    end
    return best.count
end
function S.stackShown(ft)
    local cnt = S.CW() and S.CW()._mainContent
    for _, stk in ipairs(cnt and cnt._openHeads or {}) do
        local ok, full = pcall(function() return stk.rep:getFullType() end)
        if ok and full == ft then return stk.count end
    end
    return nil
end
function S.add(ft)
    local it = nil
    pcall(function() it = S.p:getInventory():AddItem(ft) end)
    if it then S.made[#S.made + 1] = it end
    return it
end
function S.takeMade()
    for _, it in ipairs(S.made) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    S.made = {}
end

-- ===================================================================== the Cooking tab (as zedqa_cook80.lua)
S.CK = ZeD.CookingTab
function S.cook() local w = S.CW(); return w and w._cook end
function S.zone(id) local s = S.cook(); return s and s.byId and s.byId[id] end
function S.press(id)
    local z, w = S.zone(id), S.CW()
    if not (z and w and S.CK) then Q.say("(no zone " .. id .. ")"); return false end
    S.CK.onClick(w, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    return true
end
function S.rescan() local s = S.cook(); if s then s.scanAt = -1; s.visAt = nil; s.ingCache = nil end end
function S.cookDrawn() local w, s = S.CW(), S.cook(); return w and w._activeTab == "cooking" and s and #(s.zones or {}) > 0 end
function S.planText()
    local o = {}
    local s = S.cook()
    for _, e in ipairs(s and s.plan or {}) do o[#o + 1] = tostring(e.ft) end
    return table.concat(o, ", ")
end

-- ===================================================================== moodles
function S.hold()
    pcall(function()
        local st = S.p:getStats()
        for k, v in pairs(S.MOOD) do st:set(CharacterStat[k], v) end
    end)
end
-- the layer's mouse on the Stressed moodle (ZeD's balloon reads the layer's mouse only)
function S.hoverStress()
    local L = ZeD.Moodles and ZeD.Moodles.getLayer(S.pn)
    if not L then return nil end
    local idx = nil
    for i, e in ipairs(L._list or {}) do if tostring(e.key):upper():find("STRESS", 1, true) then idx = i end end
    idx = idx or 2
    local s = L._size or 32
    local lx, ly = s / 2, (idx - 1) * (s + 10) + s / 2
    if L._mode == "bottom" then lx, ly = (idx - 1) * (s + 10) + s / 2, s / 2 end
    L.getMouseX = function() return lx end
    L.getMouseY = function() return ly end
    L.isMouseOver = function() return true end
    S.hoverIdx = idx
    return idx
end
function S.unhover()
    pcall(function() local L = ZeD.Moodles.getLayer(S.pn); L.getMouseX, L.getMouseY, L.isMouseOver = nil, nil, nil end)
end
function S.moodleLine(place)
    local L = ZeD.Moodles and ZeD.Moodles.getLayer(S.pn)
    local keys = {}
    for _, e in ipairs(L and L._list or {}) do keys[#keys + 1] = tostring(e.key) .. " " .. tostring(e.level) end
    local c = L and L._chip
    Q.say(string.format("moodles %s: %d on (%s) | balloon on %s (idx %s) at %s, tail to %s", place, #keys, table.concat(keys, ", "),
        tostring(c and c.key), tostring(c and c.idx),
        c and (tostring(c.x) .. "," .. tostring(c.y) .. " " .. tostring(c.w) .. "x" .. tostring(c.h)) or "-",
        c and (tostring(c.tox) .. "," .. tostring(c.toy)) or "-"))
    return #keys
end

-- ===================================================================== start
Q.step(5, function()
    local W = S.was
    W.base, W.accent, W.size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    W.speed = getGameSpeed()
    W.pairOpen = S.CWm.isOpen() and S.WWm.isOpen()
    W.kills = S.p:getZombieKills()
    W.fav = S.p:getModData()["Fav:Crowbar"]
    W.dishes = S.p:getModData().ZeD_CookDishes
    pcall(function() W.equip = ZeD.EquipDoll.view() end)
    pcall(function() W.mood = ZeD.Settings.moodlePlaceOption:getValue() end)
    W.stats = {}
    pcall(function() for k, _ in pairs(S.MOOD) do W.stats[k] = S.p:getStats():get(CharacterStat[k]) end end)
    pcall(function() W.inv = S.p:isInvisible(); W.god = S.p:isGodMod(); W.dda = S.p:isZombiesDontAttack() end)
    G1.clean(Q)
    pcall(function() STORY.day(11.0) end)
    S.openPair()
    Q.say(string.format("start at %d,%d | screen %dx%d | font size option %s | ZeD %s %s %s | pair open %s",
        math.floor(S.p:getX()), math.floor(S.p:getY()), S.core:getScreenWidth(), S.core:getScreenHeight(),
        tostring(S.core:getOptionFontSize()), tostring(W.base), tostring(W.accent), tostring(W.size), tostring(W.pairOpen)))
end)
Q.step(40, function()
    S.was.cBox, S.was.wBox = S.keepBox(S.CW()), S.keepBox(S.WW())
    S.lightBlue()
    local IR = ZeD.InventoryRenderer
    if IR and IR.setGridKey then pcall(function() IR.setGridKey("player", false, S.p); IR.setGridKey("world", false, S.p) end) end
    Q.say("look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " | the list view | default boxes logged next")
    G1.boxes(Q, "default")
end)

if want("08") then
-- ===================================================================== 08 the introduction
Q.step(10, function() G1.tp(S.P.smoke, "SE"); S.openPair() end)
Q.zoomTo(1.0)
Q.step(20, function()
    local c, w = S.CW(), S.WW()
    local ct, wt = S.firstTab(c and c._tabStripPanel), S.firstTab(w and w._actionTabStrip)
    Q.say("first tabs: Character " .. tostring(ct) .. ", World " .. tostring(wt))
    if ct then S.charTab(ct) end
    if wt then S.worldTab(wt) end
end)
Q.step(30, function() S.clearChar() end)
Q.still(10, function() Q.shot("g1_08_intro") end)
end

if want("01") then
-- ===================================================================== 17 (and 01) inventory and loot
Q.step(10, function()
    G1.tp(S.P.stock, "SE")
    G1.fillShelf(Q)
    G1.giveApples(Q)
end)
Q.step(60, function()
    S.charTab("loot"); S.worldTab("loot")
    if G1.shelf then S.WWm.selectContainer(G1.shelf.inv, 120, S.pn) end
end)
Q.waitFor(10, 600, function() return S.oneSource() end, function() end)
Q.step(20, function() if G1.shelf then S.WWm.selectContainer(G1.shelf.inv, 120, S.pn) end end)
Q.step(40, function() Q.say("apple stack opened: " .. tostring(S.openStack("Base.Apple", true))) end)
Q.waitFor(10, 300, function() return S.stackShown("Base.Apple") ~= nil end, function() end)
Q.step(20, function()
    local w = S.WW()
    local showing = w and w._mainContent and w._mainContent._inventory
    Q.say("World window shows the shelf " .. tostring(G1.shelf ~= nil and showing == G1.shelf.inv))
    S.clearChar()
end)
Q.still(10, function()
    local n = S.stackShown("Base.Apple")
    if n and n >= 3 then Q.say("open stack: Apple (" .. n .. ")"); if want("17") then Q.shot("g1_17_zed") end
    else Q.notTaken("g1_17_zed", "no open apple stack of three (" .. tostring(n) .. ")") end
end)
Q.zoomTo(0.75)
Q.step(10, function() S.clearChar() end)
Q.still(10, function()
    Q.say("01: the same moment as g1_17_zed, closer (zoom 0.75), for the before-and-after spread; if g1_17 reads at 116 x 65, 01 = 17's pair")
    Q.shot("g1_01_zed")
end)
Q.zoomTo(1.0)
Q.step(5, function() S.openStack("Base.Apple", false); G1.applesBack(Q); G1.shelfBack(Q) end)
end

if want("21") then
-- ===================================================================== 21 the Equipment tab
Q.step(10, function() G1.tp(S.P.smoke, "SE"); S.charOnly() end)
Q.waitFor(10, 120, function() return S.charTab("equip") end, function() end)
Q.step(20, function() pcall(function() ZeD.EquipDoll.setView("doll") end) end)
Q.step(30, function() S.clearChar() end)
Q.still(10, function() Q.shot("g1_21_equip_doll") end)
Q.step(2, function() pcall(function() ZeD.EquipDoll.setView(S.was.equip) end) end)
end

if want("26") then
-- ===================================================================== 26 the Health tab, a bandaged scratch
-- (Nov 18 2026: with 21 skipped (the pitch retake), its move to the forecourt and the Character window alone come here)
if not want("21") then Q.step(10, function() G1.tp(S.P.smoke, "SE"); S.charOnly() end) end
Q.step(5, function() G1.wound(Q, true) end)
Q.waitFor(10, 120, function() return S.charTab("health") end, function() end)
Q.step(20, function()
    local w = S.CW()
    if w then
        w._healthFigureExpanded = true
        pcall(function() w._healthScroll:setScrollPos(0) end)
    end
end)
-- (Nov 18 2026, Design: "the bandaged scratch showing": the figure's left forearm held as if hovered, so the right
-- column shows that part's detail (the scratch, bandaged) and the figure lights it; the pointer stays hidden)
function S.holdArm()
    local w = S.CW()
    if w and w._activeTab == "health" then w._healthHoveredPart = "Left Forearm" end
end
Q.step(30, function() S.clearChar(); Events.OnTick.Add(S.holdArm) end)
Q.still(10, function() Q.shot("g1_26_zed") end)
Q.step(2, function()
    Events.OnTick.Remove(S.holdArm)
    local w = S.CW()
    if w then w._healthHoveredPart = nil end
    G1.wound(Q, false)
end)
end

if want("39") then
-- ===================================================================== 39 / 40 skills and the old job (one retake)
Q.step(5, function()
    local xp = S.p:getXp()
    local lv = {}
    for _, s in ipairs(S.SKILLS) do
        local perk = Perks[s[1]]
        local ok = perk and pcall(function()
            S.p:setPerkLevelDebug(perk, s[2])
            xp:setXPToLevel(perk, s[2])
            local pk = PerkFactory.getPerk(perk)
            local span = pk:getTotalXpForLevel(s[2] + 1) - pk:getTotalXpForLevel(s[2])
            xp:AddXPNoMultiplier(perk, span * s[3])
        end)
        lv[#lv + 1] = s[1] .. "=" .. tostring(perk and S.p:getPerkLevel(perk)) .. (ok and "" or "(ERR)")
    end
    pcall(function() SyncXp(S.p) end)
    S.p:setZombieKills(23)
    S.p:getModData()["Fav:Crowbar"] = 23
    Q.say("skills " .. table.concat(lv, " ") .. " | kills " .. S.p:getZombieKills())
    G1.tp(S.P.smoke, "SE")
    S.charOnly()
end)
Q.waitFor(10, 120, function() return S.charTab("identity") end, function() end)
-- tall along the left edge, from the top to just above the belt
Q.step(30, function()
    local c = S.CW()
    if not c then return end
    S.was.tallH = c:getHeight()
    local m = ZeD.T.px(12)
    c:setY(0)
    c:setHeight(math.floor(S.core:getScreenHeight() * 0.86))
    pcall(function() c:onResize() end)
    c:setX(m)
    c._anchorRightEdge = m + c:getWidth()
    Q.say("tall: height " .. tostring(S.was.tallH) .. " -> " .. c:getHeight() .. ", at the left edge x " .. m)
end)
Q.step(30, function() local c = S.CW(); if c then c:setX(ZeD.T.px(12)); c._anchorRightEdge = c:getX() + c:getWidth() end; S.clearChar() end)
Q.still(10, function() Q.shot("g1_39_identity_tall") end)
Q.step(2, function() local c = S.CW(); if c and c._identityScroll then c._identityScroll:setScrollPos(1.0) end end)
Q.still(30, function() Q.shot("g1_39_identity_traits") end)
Q.step(2, function() local c = S.CW(); if c and c._identityScroll then c._identityScroll:setScrollPos(0) end end)
Q.waitFor(2, 120, function() return S.charTab("skills") end, function() end)
Q.still(30, function() Q.shot("g1_39_skills_tall") end)
Q.step(2, function()
    local c = S.CW()
    if c and S.was.cBox then S.putBox(c, { x = S.was.cBox.x, y = S.was.cBox.y, h = S.was.tallH or S.was.cBox.h, a = S.was.cBox.a }) end
    S.p:setZombieKills(S.was.kills)
    S.p:getModData()["Fav:Crowbar"] = S.was.fav
    Q.say("put back: the window's height, kills " .. S.p:getZombieKills() .. " (skills go back with the teardown)")
end)
end

if want("35") then
-- ===================================================================== 35 cooking
Q.step(10, function()
    G1.tp(S.P.clerk, "SE")
    S.p:getModData().ZeD_CookDishes = {}
    local pot = S.add("Base.Pot")
    pcall(function() local fc = pot:getFluidContainer(); fc:addFluid(Fluid.Water, fc:getCapacity()) end)
    S.add("Base.Carrots"); S.add("Base.Potato"); S.add("Base.Cabbage")
    S.charOnly()
end)
Q.step(70, function() S.rescan() end)
Q.waitFor(10, 600, function() return S.charTab("cooking") end, function(ok) if not ok then Q.say("note: no Cooking tab in the strip") end end)
Q.waitFor(10, 600, function() return S.cookDrawn() end, function() end)
Q.step(20, function() S.press("cook:dish") end)
Q.step(20, function()
    local s = S.cook()
    local label = (getTextOrNull and getTextOrNull("ContextMenu_EvolvedRecipe_Stew")) or "Stew"
    S.dishKey = nil
    for _, m in ipairs((s and s.dishGeo and s.dishGeo.modes) or {}) do
        if not S.dishKey and m.label == label and tostring(m.id):sub(1, 5) == "dish:" then S.dishKey = tostring(m.id):sub(6) end
    end
    if not (S.dishKey and S.press("cook:pop:dish:" .. S.dishKey)) then Q.say("(no " .. label .. " in the Dish list)"); if s then s.popup = nil end end
end)
Q.step(20, function() S.press("cook:ing:Base.Carrots") end)
Q.step(20, function() S.press("cook:ing:Base.Potato") end)
Q.step(20, function() S.press("cook:ing:Base.Cabbage") end)
Q.step(20, function() Q.say("dish " .. tostring(S.cook() and S.cook().dish) .. " | plan " .. S.planText()); S.clearChar() end)
Q.still(10, function()
    local s = S.cook()
    if s and #(s.plan or {}) == 3 then Q.shot("g1_35_stew_plan") else Q.notTaken("g1_35_stew_plan", "the plan holds " .. S.planText()) end
end)
Q.step(10, function() S.press("cook:save") end)
Q.step(20, function()
    local l = S.p:getModData().ZeD_CookDishes or {}
    Q.say("saved dishes: " .. #l)
    local s = S.cook(); if s then s.plan = {} end
end)
Q.step(90, function() S.rescan() end)
Q.step(20, function() S.press("cook:dish") end)
Q.step(20, function()
    if S.zone("cook:pop:saved:1") then Q.shot("g1_35_dish_list") else Q.notTaken("g1_35_dish_list", "no saved stew at the head of the Dish list") end
end)
Q.step(10, function()
    local s = S.cook(); if s then s.popup = nil; s.plan = {} end
    S.takeMade()
    S.p:getModData().ZeD_CookDishes = S.was.dishes
    S.charTab("loot")
end)
end

if want("25") then
-- ===================================================================== 25 moodles, three places
Q.step(10, function()
    S.closePair()
    G1.tp(S.P.smoke, "SE")
    pcall(function() S.p:setGodMod(false) end)
    S.hold()
    Events.OnTick.Add(S.hold)
    S.holding = true
end)
Q.zoomTo(1.0)
for _, place in ipairs({ { 2, "left" }, { 3, "bottom" }, { 1, "right" } }) do
    Q.step(10, function() pcall(function() ZeD.Settings.moodlePlaceOption:setValue(place[1]) end) end)
    Q.step(90, function() S.unhover(); S.hoverStress() end)
    Q.waitFor(2, 240, function()
        local L = ZeD.Moodles.getLayer(S.pn)
        return L and L._chip and L._chip.idx == S.hoverIdx and L._chip.balloon
    end, function(ok)
        local n = S.moodleLine(place[2])
        if not ok then Q.notTaken("g1_25_" .. place[2], "no balloon on the hovered moodle")
        elseif n < 3 then Q.notTaken("g1_25_" .. place[2], "only " .. n .. " moodles on")
        else Q.shot("g1_25_" .. place[2]) end
    end)
    Q.step(2, function() S.unhover() end)
end
end

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    S.unhover()
    if S.holding then Events.OnTick.Remove(S.hold); S.holding = false end
    pcall(function() for k, v in pairs(S.was.stats or {}) do S.p:getStats():set(CharacterStat[k], v) end end)
    pcall(function() ZeD.Settings.moodlePlaceOption:setValue(S.was.mood or 1) end)
    pcall(function() ZeD.EquipDoll.setView(S.was.equip) end)
    G1.wound(Q, false)
    S.takeMade()
    G1.applesBack(Q)
    G1.shelfBack(Q)
    G1.glassesBack(Q)
    S.p:getModData().ZeD_CookDishes = S.was.dishes
    S.p:setZombieKills(S.was.kills or S.p:getZombieKills())
    S.p:getModData()["Fav:Crowbar"] = S.was.fav
    S.openPair()
end)
Q.step(30, function()
    S.charTab("loot"); S.worldTab("loot")
    S.putBox(S.CW(), S.was.cBox)
    S.putBox(S.WW(), S.was.wBox)
    pcall(ZeD.Settings.reapplyFromOptions)
    local c, w = S.CW(), S.WW()
    if c then c._accentKey = nil end
    if w then w._accentKey = nil end
    pcall(function() S.p:setInvisible(S.was.inv == true); S.p:setGodMod(S.was.god == true); S.p:setZombiesDontAttack(S.was.dda == true) end)
    pcall(function() setGameSpeed((S.was.speed and S.was.speed > 0) and S.was.speed or 1) end)
end)
Q.step(30, function()
    if not S.was.pairOpen then S.closePair() end
    pcall(function() Mouse.setCursorVisible(true) end)
    G1.boxes(Q, "put_back")
    Q.say("put back: look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " (was " .. tostring(S.was.base) .. " " .. tostring(S.was.accent) .. ")")
end)
Q.start()
