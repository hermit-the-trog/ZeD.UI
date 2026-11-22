-- ZeDUI/tools/qa/bxr_inv.lua  (Nov 21 2026, QA; tag bxri): the beast day report's in-game pictures, INVENTORY part:
-- the Move to submenu's bag icons (B0-1), the Equip tab's list (W3), the title bar's load (W8), a jammed pistol
-- (B5-11, B7-4), the reading and cooking bands (W4), a steak in a powered freezer (B5-9). Findings:
-- ZeDUI/qa/audits/2026-11-21_beast_*.md. Built on the hotfix report's kit (hfr_common.lua, G1); manifest
-- beast_report_inv.txt (the story stage, gallery_unload.lua, G1, hfr_common.lua). Pictures to
-- Zomboid/Screenshots/bxr_<id>_<short>.png (QA's runner moves them to Screenshots/beast_day_report/):
--   B0-1_moveto_strip, B0-1_moveto_list      a carried hammer's Move to, the three worn bags' rows, both looks
--   W3_equip_list_inner_ears                 the Equip tab's list: the Inner rows, the nose stud on Ears, empty slots
--   W8_title_pin_load_once                   on Loot, a pinned water bottle: the title bar holds the pin, and no load (the
--                                            list's heading under it carries the load: once in the window)
--   W8_bag_alone_load_once                   the Health tab, a bag viewed alone: the title bar's pin and its load once
--   W8_side_hidden_load_once                 the same bag's button pressed again: the inventory side shuts and stops
--                                            drawing (the fault's own path: before the fix the load showed twice)
--   B5-11_jammed_pouch_card                  a jammed pistol held: the belt's pouch and the item card say Jammed
--                                            (should the card shut when the pistol goes in the hand: two pictures,
--                                            B5-11_jammed_pouch and B5-11_jammed_card)
--   B7-4_jammed_hover_balloon                the loot card (the balloon by the pointer) on the pistol's row says Jammed
--                                            (the pistol carried, not held: a held thing is no row of the list)
--   W4_reading_band_cancel, W4_reading_cancelled, W4_cooking_band_no_x
--   B5-9_freezer_steak                       the freezer in the World window's Loot list, the steak's card
-- Each picture prints "ZEDQA bxri SHOT <name> | what is in it" or "ZEDQA bxri SKIP <name> | why".
-- Faked, and said so here: the pointer's place (getMouseX / getMouseY swapped while a menu or the balloon is up: the
-- game does not read Mouse.setXY; the real pointer stays hidden), and the cooking band (put up through ZeD's action
-- manager with no stove, as vx_inventory.lua stages it).
-- Windows: at their default places (the mod's own reset; at 4K the spread stands above the character), but for the
-- two Move to pictures and the balloon, where both go to the screen's edges first (a menu or the balloon opens to the
-- right of its row, down over the character); after each of those the reset again.
-- (QA review, Nov 21: the W8 Loot picture waited for a load the title bar leaves out while the list's heading shows it,
-- so it always skipped; the fault's own path at 4K, the side shut by its bag's button, is a picture now. The belt's
-- ammo pouch shows only with ZeD setup's "Ammo on the belt" on, off for a new player: on in memory for B5-11.)
-- What it puts back: every thing given, the clothes put on, the pistol unjammed and gone, the hands, the pins (the
-- character's own list, the same table), the fridge and the generator, the time of day (11:00, the story stage's) and
-- the needs the fast-forward moved, the Context menu, Equip view and Ammo on the belt options (changed in memory
-- only), the Equip list's folds, the inventory side and the bag viewed, the instant-action cheat, the windows' places
-- (ZEDQA_LAYOUT_BACK), the tabs, the game speed.
-- grep "ZEDQA bxri".
local S = HFR and HFR.init and HFR.init("bxri")
if not S then return end
S.DIR = "bxr_"
local Q, IR = S.Q, ZeD.InventoryRenderer
S.A = {}
S.STATS = { "HUNGER", "THIRST", "FATIGUE", "BOREDOM", "UNHAPPINESS", "STRESS", "IDLENESS", "NICOTINE_WITHDRAWAL", "ENDURANCE", "DISCOMFORT" }

-- ===================================================================== small helpers
function S.take(name, what, keepMenu)
    S.shot(name, keepMenu)
    Q.say("SHOT " .. name .. " | " .. tostring(what))
end
function S.skip(name, why)
    Q.nErr = Q.nErr + 1
    Q.say("SKIP " .. name .. " | " .. tostring(why))
end
function S.nm(it)
    if it == nil then return "nothing" end
    local n = nil
    pcall(function() n = it:getDisplayName() end)
    return tostring(n or it)
end
-- the pointer the game reads (Mouse.setXY does not move it): swapped for a spot, and back
function S.mouseOn(x, y)
    S.fx, S.fy = x, y
    if S.mouseSwapped then return end
    S.realMX, S.realMY = getMouseX, getMouseY
    S.mouseSwapped = true
    getMouseX = function() return S.fx end
    getMouseY = function() return S.fy end
end
function S.mouseOff()
    if not S.mouseSwapped then return end
    getMouseX, getMouseY = S.realMX, S.realMY
    S.mouseSwapped = false
end
-- both windows to the screen's edges (a menu or a balloon opens to the right of its row: never over the character)
function S.aside()
    local W = S.core:getScreenWidth()
    local m = ZeD.T.px(12)
    local c, w = S.CW(), S.WW()
    if c and c:isVisible() and c:getX() ~= m then
        c:setX(m)
        if c._anchorRightEdge ~= nil then c._anchorRightEdge = m + c:getWidth() end
    end
    if w and w:isVisible() then
        local x = W - w:getWidth() - m
        if w:getX() ~= x then
            w:setX(x)
            if w._anchorRightEdge ~= nil then w._anchorRightEdge = x + w:getWidth() end
        end
    end
end
-- both windows back at their default places (the mod's own reset, on Loot), after a picture that moved them aside
function S.home()
    if ZEDQA_LAYOUT_DEFAULT then pcall(ZEDQA_LAYOUT_DEFAULT, "bxri") else pcall(function() ZeD_Window.resetLayout() end) end
end
-- the dead taken away again near him (game hours went by on the fast-forward), as S.start0 does at the start
function S.zombiesAway()
    local gone = 0
    pcall(function()
        local zl = getCell():getZombieList()
        local px, py = S.p:getX(), S.p:getY()
        for i = zl:size() - 1, 0, -1 do
            local z = zl:get(i)
            if z and math.abs(z:getX() - px) < 40 and math.abs(z:getY() - py) < 40 then z:removeFromWorld(); z:removeFromSquare(); gone = gone + 1 end
        end
    end)
    return gone
end
-- a click (press and release) on a zone of the Character window's container strip: "cnt:<i>" a bag's button,
-- "main_toggle" the inventory's own
function S.pressStrip(id)
    local cw = S.CW()
    local strip = cw and cw._containerStrip
    for _, z in ipairs((strip and strip._hitZones) or {}) do
        if z.id == id then
            pcall(strip.onMouseDown, strip, z.x + 2, z.y + 2)
            pcall(strip.onMouseUp, strip, z.x + 2, z.y + 2)
            return true
        end
    end
    return false
end
function S.menu()
    local m = nil
    pcall(function() local v = getPlayerContextMenu(S.pn); m = v and v._zedMenu end)
    return m
end
function S.shutMenu()
    pcall(function() local m = S.menu(); if m then m:close() end end)
    G1.closeMenus()
    S.mouseOff()
end
-- a thing made here off the character and gone
function S.drop(it)
    if not it then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    pcall(function() S.p:removeWornItem(it) end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
function S.wornNow()
    local set = {}
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do set[wi:get(i):getItem()] = true end
    end)
    return set
end
function S.wornBack()
    local on, n = S.wornNow(), 0
    for _, e in ipairs(S.was.worn or {}) do
        local here = false
        pcall(function() here = e.item:getContainer() == S.p:getInventory() end)
        if not on[e.item] and here then
            pcall(function() S.p:setWornItem(e.loc, e.item) end)
            n = n + 1
        end
    end
    if n > 0 then pcall(function() triggerEvent("OnClothingUpdated", S.p) end) end
    return n
end
function S.handsBack()
    local h = S.was.hands
    if not h then return end
    pcall(function() if S.p:getPrimaryHandItem() ~= h[1] then S.p:setPrimaryHandItem(h[1]) end end)
    pcall(function() if S.p:getSecondaryHandItem() ~= h[2] then S.p:setSecondaryHandItem(h[2]) end end)
end
function S.statsSave()
    S.was.stats = {}
    for _, k in ipairs(S.STATS) do
        pcall(function() S.was.stats[k] = S.p:getStats():get(CharacterStat[k]) end)
    end
end
function S.statsBack()
    for _, k in ipairs(S.STATS) do
        local v = S.was.stats and S.was.stats[k]
        if v ~= nil then pcall(function() S.p:getStats():set(CharacterStat[k], v) end) end
    end
end
function S.reading() local r = false; pcall(function() r = S.p:isReading() end); return r and true or false end
function S.active(item)
    local a = nil
    pcall(function() a = ZeD.ItemActionManager.getActiveAction(item) end)
    return a
end
function S.stopActions() pcall(function() ISTimedActionQueue.clear(S.p) end) end
function S.speed(n) if ZEDQA_SPEED then pcall(ZEDQA_SPEED, n) else pcall(setGameSpeed, n) end end

-- a stacked kind has no row of its own: the kind's stack is opened (as hfr_inv.lua does), shut again at the end
function S.expand(it)
    local c, ft = S.cc(), nil
    pcall(function() ft = it:getFullType() end)
    if not (c and ft) then return end
    c._expandedStacks = c._expandedStacks or {}
    S.stackWas = S.stackWas or {}
    if S.stackWas[ft] == nil then S.stackWas[ft] = c._expandedStacks[ft] or false end
    c._expandedStacks[ft] = true
    for _, cs in ipairs(c._colStates or {}) do cs.expandedStacks = cs.expandedStacks or c._expandedStacks; cs.expandedStacks[ft] = true end
end
function S.same(a, b) return type(a) == "string" and type(b) == "string" and a:lower() == b:lower() end
-- a card on the Character window: the kind's stack opened, the row found, pressed; S.shutCard closes it
function S.openCard(key, label)
    local function IT() return S.A[key] end
    Q.step(10, function()
        S.openPair(); S.charTab("loot"); S.seekPos = nil
        S.expand(IT())
    end)
    Q.waitFor(5, 600, function() return IT() == nil or S.seekRow(S.cc(), IT()) end, function(ok)
        local did = false
        if IT() and ok then did = S.click(S.cc(), S.zone(S.cc(), IT())) end
        Q.say(label .. ": row " .. tostring(ok and IT() ~= nil) .. ", pressed " .. tostring(did))
    end)
    Q.waitFor(10, 300, function() return IT() == nil or S.cardOn(IT()) end, function(ok)
        Q.say(label .. ": card out " .. tostring(IT() ~= nil and S.cardOn(IT())))
        S.clearChar()
    end)
end
function S.shutCard(key)
    Q.step(5, function()
        local it = S.A[key]
        if not (it and S.cardOn(it)) then return end
        local c, w = S.cc(), S.CW()
        local z = S.zone(c, it)
        if z then S.click(c, z) end
        if S.cardOn(it) and c and w and w._updateDrawer then
            c._selectedItems = {}
            c._lastClickedItem = nil
            pcall(w._updateDrawer, c)
        end
    end)
    Q.waitFor(5, 300, function() local it = S.A[key]; return it == nil or not S.cardOn(it) end, function() end)
end

-- ===================================================================== start
Q.step(5, function()
    S.start0()
    G1.tp(S.P.smoke, "SE")     -- (outside the store, on the camera's side: nothing stands in front of him)
    local W = S.was
    W.hands = { S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem() }
    pcall(function() W.instant = S.p:isTimedActionInstantCheat() end)
    pcall(function() W.ctx = ZeD.Settings.contextStyleOption:getValue() end)
    pcall(function() W.eqView = ZeD.Settings.equipViewOption:getValue() end)
    pcall(function() W.hp = S.p:getBodyDamage():getOverallBodyHealth() end)
    W.worn = {}
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do
            local w = wi:get(i)
            W.worn[#W.worn + 1] = { loc = w:getLocation(), item = w:getItem() }
        end
    end)
    S.statsSave()
    -- the character's own pins put aside whole (the same table goes back)
    pcall(function()
        local md = S.p:getModData()
        W.pins = ZeD.Pins.list(S.p)
        md.ZeD_Pins = {}
        W.pinsAside = true
    end)
    S.stopActions()
    S.openPair()
    Q.say("standing at " .. math.floor(S.p:getX()) .. "," .. math.floor(S.p:getY()) .. " (the story's smoke spot, outside), worn " .. #W.worn
        .. ", Style Lite " .. tostring(ZeD.Settings.lite and ZeD.Settings.lite()))
end)
Q.zoomTo(1.0)
Q.waitFor(10, 600, function() return S.CW() ~= nil and S.WW() ~= nil and S.CWm.isOpen() and S.WWm.isOpen() end, function(ok)
    if not ok then Q.say("ERR the windows did not open") end
    pcall(function() S.was.snap = ZEDQA_LAYOUT_SNAP and ZEDQA_LAYOUT_SNAP() or nil end)
    pcall(function()
        S.gridKey = IR.containerKey and IR.containerKey(S.p:getInventory(), S.p) or "player"
        S.was.grid = IR.isGridKey(S.gridKey)
    end)
    -- the windows at their default places (the mod's own reset), both pinned
    if ZEDQA_LAYOUT_DEFAULT then pcall(ZEDQA_LAYOUT_DEFAULT, "bxri") else pcall(function() ZeD_Window.resetLayout() end) end
    S.charTab("loot"); S.worldTab("loot")
end)
Q.waitFor(10, 600, function() return S.oneSource() end, function() S.clearChar() end)

-- ===================================================================== B0-1: Move to, the bags' icons, both looks
Q.step(10, function()
    S.A.hammer = S.add("Base.Hammer")
    -- the three bags of the report, worn already by the story's character; one missing is given and worn where free
    S.bagWant = { { "FannyPack", "Base.Bag_FannyPackFront" }, { "Satchel", "Base.Bag_Satchel_Leather" }, { "ALICEpack", "Base.Bag_ALICEpack" } }
    S.bagMade = {}
    local have = {}
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do
            local it = wi:get(i):getItem()
            if instanceof(it, "InventoryContainer") then
                local ft = tostring(it:getFullType())
                for _, b in ipairs(S.bagWant) do if ft:find(b[1], 1, true) then have[b[1]] = it end end
            end
        end
    end)
    for _, b in ipairs(S.bagWant) do
        if not have[b[1]] then
            local it = S.add(b[2])
            local loc = nil
            if it then pcall(function() loc = it:canBeEquipped() end) end
            local there = nil
            if loc then pcall(function() there = S.p:getWornItem(loc) end) end
            if it and loc and not there then
                pcall(function() S.p:setWornItem(loc, it) end)
                S.bagMade[#S.bagMade + 1] = it
                have[b[1]] = it
            elseif it then
                S.drop(it)
            end
        end
    end
    if #S.bagMade > 0 then pcall(function() triggerEvent("OnClothingUpdated", S.p) end) end
    S.bagNames = {}
    for _, b in ipairs(S.bagWant) do S.bagNames[#S.bagNames + 1] = have[b[1]] and S.nm(have[b[1]]) or ("no " .. b[1]) end
    Q.say("B0-1 staged: a hammer carried " .. tostring(S.A.hammer ~= nil) .. "; bags worn: " .. table.concat(S.bagNames, ", ")
        .. " (" .. #S.bagMade .. " of them given here)")
end)
-- the submenu's rows (no Back cell), and what each shows for an icon
function S.subDefs(m, style)
    local out = {}
    if style == 1 then
        for _, d in ipairs((m._ctx and m._ctx.items) or {}) do if type(d) == "table" and not d.isBack then out[#out + 1] = d end end
    else
        local lv = m._levels and m._levels[2]
        for _, r in ipairs((lv and lv.rows) or {}) do if r.def and not r.def.heading then out[#out + 1] = r.def end end
    end
    return out
end
function S.subWords(m, style)
    local t, bare = {}, 0
    for _, d in ipairs(S.subDefs(m, style)) do
        local ic = d.pxIcon and ("icon " .. tostring(d.pxIcon)) or (d.iconTexture and "its picture") or "NO ICON"
        if ic == "NO ICON" then bare = bare + 1 end
        t[#t + 1] = tostring(d.name) .. " (" .. ic .. ")"
    end
    return table.concat(t, ", "), #t, bare
end
function S.menuShot(style, name)
    local sname = (style == 1) and "the strip" or "the list"
    Q.step(10, function()
        S.shutMenu()
        S.menuOk, S.menuWhy = false, "the hammer's row was not found"
        pcall(function() ZeD.Settings.contextStyleOption:setValue(style) end)   -- (in memory only: the file is not written)
        S.openPair(); S.charTab("loot"); S.seekPos = nil
        S.expand(S.A.hammer)
        S.aside()
    end)
    Q.waitFor(20, 600, function() return S.A.hammer == nil or S.seekRow(S.cc(), S.A.hammer) end, function(ok)
        local c = S.cc()
        local z = (ok and S.A.hammer) and S.zone(c, S.A.hammer) or nil
        if not z then return end
        -- the right-click, at the hammer's row: the game's own menu call, the pointer read there
        local ax = c:getAbsoluteX() + z.x + math.floor(z.w * 0.45)
        local ay = c:getAbsoluteY() + z.y + math.floor(z.h / 2)
        S.mouseOn(ax, ay)
        local okM, e = pcall(ISInventoryPaneContextMenu.createMenu, S.pn, true, { S.A.hammer }, ax, ay)
        S.menuWhy = okM and "ZeD's menu did not come up" or ("the menu call stopped: " .. tostring(e))
    end)
    Q.waitFor(3, 240, function() return S.menu() ~= nil end, function(ok)
        local m = S.menu()
        if not m then return end
        local want = getText("ContextMenu_Move_To")
        S.menuWhy = "the menu has no " .. tostring(want) .. " row"
        if style == 1 and m._ctx and m._ctx.items then
            local c, idx = m._ctx, nil
            for i, d in ipairs(c.items) do if type(d) == "table" and S.same(d.name, want) then idx = i end end
            if idx then
                for _ = 1, #c.items do
                    if c.selected ~= idx then m:next() end
                end
                if c.selected == idx then m:confirm() end
                S.menuOk = #c.path == 1 and c.open == true
                S.menuWhy = "Move to did not open its cells"
            end
        elseif style == 2 and m._levels and m._levels[1] then
            local top, ri = m._levels[1], nil
            for i, r in ipairs(top.rows or {}) do if r.def and S.same(r.def.name, want) then ri = i end end
            if ri then
                -- (the menu's own arrow keys, as a keyboard player steps: the rows take the hover wash a mouse
                -- player sees. The pad's calls drew the controller's focus mark in a mouse game.)
                for _ = 1, #top.rows + 1 do
                    if top.sel ~= ri then m:onKeyPress(Keyboard.KEY_DOWN) end
                end
                if top.sel ~= ri then top.sel = ri end
                m:onKeyPress(Keyboard.KEY_RIGHT)
                S.menuOk = m._levels[2] ~= nil
                S.menuWhy = "Move to did not open its list"
            end
        end
        Q.say(name .. ": menu " .. tostring(m.Type) .. ", Move to open " .. tostring(S.menuOk))
    end)
    -- the strip's slide over, then drawn frames
    Q.waitFor(30, 400, function()
        local m = S.menu()
        return (not S.menuOk) or m == nil or m._settleAt == nil
    end, function() end)
    Q.step(20, function()
        local m = S.menu()
        local open = m ~= nil and S.menuOk and ((style == 1 and #m._ctx.path == 1) or (style == 2 and m._levels[2] ~= nil))
        if not open then S.skip(name, S.menuWhy .. " (menu " .. tostring(m and m.Type) .. ")"); return end
        local words, n, bare = S.subWords(m, style)
        S.take(name, "Move to on a carried hammer, " .. sname .. " (" .. tostring(m.Type) .. "): " .. n .. " rows, " .. bare .. " with no icon: " .. words
            .. " | bags worn: " .. table.concat(S.bagNames or {}, ", "), true)
    end)
    Q.step(5, function() S.shutMenu() end)
end
S.menuShot(1, "B0-1_moveto_strip")
S.menuShot(2, "B0-1_moveto_list")
Q.step(5, function()
    pcall(function() if S.was.ctx then ZeD.Settings.contextStyleOption:setValue(S.was.ctx) end end)
    for _, it in ipairs(S.bagMade or {}) do S.drop(it) end
    if #(S.bagMade or {}) > 0 then pcall(function() triggerEvent("OnClothingUpdated", S.p) end) end
    S.bagMade = {}
    -- (the windows back from the screen's edges: the next pictures have them at their default places)
    S.home()
end)
Q.waitFor(10, 300, function() local w = S.CW(); return w ~= nil and w._activeTab == "loot" end, function() S.clearChar() end)

-- ===================================================================== W3: the Equip tab's list
function S.eqRows()
    local rows, n = {}, 0
    local cw = S.CW()
    for _, z in ipairs((cw and cw._equipSlotZones) or {}) do
        if z.item then rows[z.item] = tostring(z.type); n = n + 1 end
    end
    return rows, n
end
function S.w3Back()
    for _, it in ipairs(S.eqMade or {}) do S.drop(it) end
    S.eqMade = {}
    S.wornBack()
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
    pcall(function() if S.was.eqView and ZeD.Settings.equipViewOption:getValue() ~= S.was.eqView then ZeD.Settings.equipViewOption:setValue(S.was.eqView) end end)
    local cw, e = S.CW(), S.eqWas
    if cw and e then
        cw._equipListExpanded, cw._equipSelected = e.list, e.sel
        if cw._equipExpanded then cw._equipExpanded.head, cw._equipExpanded.torso = e.head, e.torso end
    end
    S.eqWas = nil
end
Q.step(10, function()
    S.w3 = false
    local D, cw = ZeD.EquipDoll, S.CW()
    if not (D and D.view and ZeD.EquipmentTab and cw) then S.skip("W3_equip_list_inner_ears", "the Equip tab is not loaded"); return end
    -- (the view is switched in memory only: the option's file is not written)
    if D.view() ~= "list" then pcall(function() ZeD.Settings.equipViewOption:setValue(1) end) end
    S.eq, S.eqMade = {}, {}
    -- a tank top, a T-shirt and a nose stud, each put on only where nothing is worn yet (none of his clothes comes off)
    for _, e in ipairs({ { "tank", "Base.Vest_DefaultTEXTURE" }, { "tee", "Base.Tshirt_DefaultTEXTURE" }, { "stud", "Base.NoseStud_Silver" } }) do
        local it = S.add(e[2])
        local loc = nil
        if it then pcall(function() loc = it:getBodyLocation() end) end
        local there = nil
        if loc then pcall(function() there = S.p:getWornItem(loc) end) end
        if it and loc and not there then
            pcall(function() S.p:setWornItem(loc, it) end)
            S.eqMade[#S.eqMade + 1] = it
        elseif it then
            S.drop(it)      -- (he wears one there already: his own shows)
        end
        S.eq[e[1]] = { loc = loc }
    end
    for _, k in ipairs({ "tank", "tee", "stud" }) do
        local e = S.eq[k]
        if e.loc then pcall(function() e.item = S.p:getWornItem(e.loc) end) end
    end
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
    S.eqWas = { list = cw._equipListExpanded, sel = cw._equipSelected,
                head = cw._equipExpanded and cw._equipExpanded.head, torso = cw._equipExpanded and cw._equipExpanded.torso }
    cw._equipListExpanded = true
    cw._equipSelected = nil
    S.w3 = S.charTab("equip") and true or false
    if not S.w3 then S.skip("W3_equip_list_inner_ears", "the Equip tab is not on the strip") end
end)
Q.waitFor(6, 400, function()
    if not S.w3 then return true end
    local cw = S.CW()
    if not (cw and cw._activeTab == "equip") then return false end
    -- the Head and Torso groups unfolded: their empty slots are listed too
    if cw._equipExpanded then cw._equipExpanded.head = true; cw._equipExpanded.torso = true end
    pcall(function() if cw._equipScroll and cw._equipScroll.setScrollPos then cw._equipScroll:setScrollPos(0) end end)
    local rows = S.eqRows()
    for _, k in ipairs({ "tank", "tee", "stud" }) do
        local it = S.eq[k].item
        if it and not rows[it] then return false end
    end
    return true
end, function(ok) S.clearChar() end)
Q.still(10, function()
    if not S.w3 then return end
    local cw = S.CW()
    local rows, n = S.eqRows()
    local inner, ears = {}, {}
    for _, z in ipairs((cw and cw._equipSlotZones) or {}) do
        local ty = tostring(z.type)
        if z.item and ty:sub(1, 3) == "INR" then inner[#inner + 1] = ty .. " " .. S.nm(z.item) end
        if z.item and ty:sub(1, 3) == "EAR" then ears[#ears + 1] = ty .. " " .. S.nm(z.item) end
    end
    local empty = "?"
    pcall(function()
        local data, k = ZeD.EquipmentTab.gatherData(S.p), 0
        for _, g in ipairs(data.groups) do
            if g.id == "head" or g.id == "torso" then
                for _, s in ipairs(g.slots) do if not s.item then k = k + 1 end end
            end
        end
        empty = tostring(k)
    end)
    local tank, tee, stud = S.eq.tank.item, S.eq.tee.item, S.eq.stud.item
    if not (cw and cw._activeTab == "equip" and ZeD.EquipDoll.view() == "list") then
        S.skip("W3_equip_list_inner_ears", "the Equip tab's list is not showing (tab " .. tostring(cw and cw._activeTab) .. ")")
    elseif #inner < 2 then
        S.skip("W3_equip_list_inner_ears", "fewer than two Inner rows (" .. table.concat(inner, "; ") .. "): tank top worn " .. tostring(tank ~= nil) .. ", T-shirt worn " .. tostring(tee ~= nil))
    else
        S.take("W3_equip_list_inner_ears", "the Equip tab's list, Head and Torso unfolded: " .. #inner .. " Inner rows (" .. table.concat(inner, "; ")
            .. "); the tank top " .. S.nm(tank) .. " on row " .. tostring(tank and rows[tank]) .. ", the T-shirt " .. S.nm(tee) .. " on row " .. tostring(tee and rows[tee])
            .. "; the nose stud " .. S.nm(stud) .. " on row " .. tostring(stud and rows[stud]) .. " (Ears rows: " .. table.concat(ears, "; ")
            .. "); " .. n .. " rows with a thing, " .. empty .. " empty slots listed in Head and Torso")
    end
end)
Q.step(5, function() S.w3Back(); S.charTab("loot") end)

-- ===================================================================== W8: the title bar's load, once
-- the title bar's entries: the pins first, the load the one with no status mark
function S.barWords()
    local cw = S.CW()
    local t, loads = {}, 0
    for _, st in ipairs((cw and cw.titleStats) or {}) do
        if st.noMark then loads = loads + 1 end
        t[#t + 1] = (st.noMark and "load " or "pin ") .. "\"" .. tostring(st.text) .. "\""
    end
    return table.concat(t, ", "), loads, #t
end
function S.viewMain()
    local w = S.CW()
    if not w then return end
    pcall(function()
        if w._viewedContainer ~= nil then
            w._viewedContainer = nil
            w._activeContainer = 1
            w._mainVisible = true
            local c = w._contentPanel
            if c and w._containers and w._containers[1] then
                c._inventory = w._containers[1].inventory
                c._selectedItems = {}
                c._lastClickedItem = nil
            end
        end
    end)
end
Q.step(20, function()
    S.w8 = false
    S.charTab("loot")
    local P = ZeD.Pins
    S.A.bottle = S.add("Base.WaterBottle")
    if P and P.kindOf and P.toggle and S.A.bottle then
        local k = P.kindOf(S.A.bottle)
        -- (what the bottle's own right-click row, Pin to title bar, runs)
        if k then S.w8 = P.toggle(S.p, k, S.A.bottle:getID(), S.A.bottle:getDisplayName()) == true end
    end
    Q.say("W8 staged: a water bottle given " .. tostring(S.A.bottle ~= nil) .. ", pinned to the title bar " .. tostring(S.w8))
end)
-- (on Loot with the inventory's own list showing, the title bar keeps the pins only: the list's heading under it says
-- the load, so the title leaves it out (QA's visual noise audit 1). The wait is for the pin; a load in the title here
-- would be the fault.)
Q.waitFor(10, 300, function()
    if not S.w8 then return true end
    local _, loads, n = S.barWords()
    return n - loads >= 1
end, function(ok) S.clearChar() end)
Q.still(10, function()
    local words, loads, n = S.barWords()
    if not S.w8 then S.skip("W8_title_pin_load_once", "the water bottle could not be pinned"); return end
    if n - loads < 1 then S.skip("W8_title_pin_load_once", "the title bar shows no pin (" .. words .. ")"); return end
    local cw, head = S.CW(), "?"
    pcall(function() head = tostring(S.cc()._containerInfo.stats) end)
    S.take("W8_title_pin_load_once", "the Character window on Loot (tab " .. tostring(cw and cw._activeTab) .. "), its main list showing, a water bottle pinned: "
        .. "the title bar holds " .. words .. " (the load " .. loads .. " time(s) in it" .. ((loads == 0) and ", as meant" or ": the FAULT") .. "); the list's heading under it reads \""
        .. head .. "\" (the load once in the window)")
end)
-- the fault's place: a bag viewed alone (a press on its button in the strip, on a tab other than Loot), then the
-- same button again, which shuts the inventory side: the side stops drawing and the title bar takes over the pins and
-- the load (titleLoadFallback). Before the fix the side's last list, its own load at the end, stayed and the fallback
-- added a second load. The same at 1280x720 when a wide tab drawer covers the side; at 4K this is the way there.
Q.step(10, function()
    S.w8b = false
    if not S.w8 then return end
    local cw = S.CW()
    S.bagI = nil
    for i, c in ipairs((cw and cw._containers) or {}) do if not c.isMain and not S.bagI then S.bagI = i end end
    if not S.bagI then S.skip("W8_bag_alone_load_once", "no bag on the Character strip"); return end
    S.w8b = S.charTab("health") and true or false
    if not S.w8b then S.skip("W8_bag_alone_load_once", "no Health tab on the strip") end
end)
Q.waitFor(10, 400, function() local cw = S.CW(); return not S.w8b or (cw ~= nil and cw._activeTab == "health") end, function() end)
Q.still(10, function()
    if not S.w8b then return end
    S.w8press = S.pressStrip("cnt:" .. S.bagI)
end)
Q.step(40, function() if S.w8b then S.clearChar() end end)
Q.still(10, function()
    S.w8c = false
    if not S.w8b then return end
    local cw = S.CW()
    local view = cw._containers and cw._containers[cw._viewedContainer or cw._activeContainer]
    local alone = view ~= nil and not view.isMain and #(cw._mcSelected or {}) == 0 and cw._invDrawerOpen ~= false
    local words, loads = S.barWords()
    if not (S.w8press and alone) then
        S.skip("W8_bag_alone_load_once", "the bag is not viewed alone (its button pressed " .. tostring(S.w8press) .. ", viewed " .. tostring(view and view.name) .. ")")
        S.skip("W8_side_hidden_load_once", "the bag was not viewed alone first")
        return
    end
    S.w8bag = tostring(view.name)
    S.take("W8_bag_alone_load_once", "the Health tab open, " .. S.w8bag .. " viewed alone in the list: the title bar holds " .. words .. " (the load "
        .. loads .. " time(s)" .. ((loads == 1) and ")" or ": the FAULT)"))
    S.w8c = true
end)
-- the same bag's button again: the inventory side shuts (the window narrows to its tab strip, the Health drawer and
-- the bag strip) and no longer draws
Q.step(10, function()
    if not S.w8c then return end
    S.w8press2 = S.pressStrip("cnt:" .. S.bagI)
end)
Q.waitFor(10, 400, function()
    if not S.w8c then return true end
    local cw = S.CW()
    local c = cw and cw._contentPanel
    return cw ~= nil and cw._invDrawerOpen == false and c ~= nil and not c:isVisible()
end, function(ok)
    if not S.w8c then return end
    S.w8hid = ok
    S.clearChar()
end)
Q.still(10, function()
    if not S.w8c then return end
    local cw = S.CW()
    local c = cw and cw._contentPanel
    local words, loads = S.barWords()
    if not S.w8hid then
        S.skip("W8_side_hidden_load_once", "the inventory side did not shut (button pressed again " .. tostring(S.w8press2) .. ", inventory open "
            .. tostring(cw and cw._invDrawerOpen) .. ", list drawn " .. tostring(c and c:isVisible()) .. ")")
        return
    end
    S.take("W8_side_hidden_load_once", "the Health tab open, " .. tostring(S.w8bag) .. "'s button pressed again: the inventory side shut (list drawn "
        .. tostring(c and c:isVisible()) .. "); the title bar holds " .. words .. " (the load " .. loads .. " time(s)"
        .. ((loads == 1) and ", once: fixed; the old code showed it twice here)" or ": the FAULT)"))
end)
-- the inventory side open again on the main inventory (the inventory's own button on a tab: its main list, the
-- window as wide as before), then Loot
Q.step(10, function()
    local cw = S.CW()
    if cw and cw._invDrawerOpen == false and cw._activeTab ~= "loot" then S.pressStrip("main_toggle") end
end)
Q.waitFor(5, 300, function() local cw = S.CW(); return cw == nil or cw._invDrawerOpen ~= false end, function(ok)
    local cw = S.CW()
    if cw and cw._invDrawerOpen == false then cw._invDrawerOpen = true; Q.say("note: the inventory side was opened by its flag (the button did not)") end
end)
Q.step(10, function()
    S.viewMain()
    S.charTab("loot")
    -- the pin off: the character's own list goes back at the end
    pcall(function() S.p:getModData().ZeD_Pins = {} end)
    S.drop(S.A.bottle); S.A.bottle = nil
end)
Q.waitFor(5, 300, function() local w = S.CW(); return w ~= nil and w._activeTab == "loot" end, function()
    -- (at the default place again: the strip's snap moved the window's left edge)
    S.home()
end)

-- ===================================================================== B5-11 / B7-4: a jammed pistol
function S.hud() local h = nil; pcall(function() h = ZeD.Belt.getHUD(S.pn) end); return h end
function S.pouchJam()
    local h = S.hud()
    local c = h and h._ammo
    return c ~= nil and c.gun == S.A.gun and c.a ~= nil and c.a.jammed == true
end
-- ZeD setup's "Ammo on the belt" (an addition, off for a new player: then the belt has no ammo pouch at all,
-- ZeD_BeltHUD:_ammoState), on in memory for the pouch's picture (the option's file is not written), back after
function S.ammoOn()
    local St = ZeD.Settings
    local o = St and St.ammoBoxOption
    if not o then return false end
    if S.was.ammoBox == nil then pcall(function() S.was.ammoBox = o:getValue() end) end
    pcall(function() o:setValue(2) end)
    local on = false
    pcall(function() on = St.ammoBoxOn() == true end)
    return on
end
function S.ammoBack()
    local o = ZeD.Settings and ZeD.Settings.ammoBoxOption
    if o and S.was.ammoBox ~= nil then pcall(function() o:setValue(S.was.ammoBox) end) end
end
function S.jamBack()
    S.ammoBack()
    local g = S.A.gun
    if not g then return end
    pcall(function() g:setJammed(false) end)
    S.drop(g)
    S.A.gun = nil
    S.handsBack()
end
Q.step(20, function()
    S.jam = false
    S.charTab("loot")
    local g = S.add("Base.Pistol")
    S.A.gun = g
    if not g then S.skip("B5-11_jammed_pouch_card", "no pistol could be given"); return end
    pcall(function() g:setContainsClip(true); g:setCurrentAmmoCount(10); g:setRoundChambered(true) end)
    -- the game's own jam flag (HandWeapon.setJammed), as its rack sets it
    pcall(function() g:setJammed(true) end)
    pcall(function() S.jam = g:isJammed() == true end)
    S.ammo = S.jam and S.ammoOn() or false
    Q.say("B5-11 staged: a pistol carried, 10 rounds and one chambered, jammed " .. tostring(S.jam) .. "; Ammo on the belt on " .. tostring(S.ammo)
        .. " (it was " .. tostring(S.was.ammoBox) .. ": 1 off, 2 on)")
    if not S.jam then S.skip("B5-11_jammed_pouch_card", "the game did not take the jam") end
end)
-- (a thing held is no row of the Loot list: its card is opened from its row first, then the pistol goes in the hand)
S.openCard("gun", "B5-11 the pistol")
Q.step(10, function()
    if not S.jam then return end
    pcall(function() S.p:setPrimaryHandItem(S.A.gun) end)
end)
Q.waitFor(10, 400, function() return not S.jam or S.pouchJam() end, function(ok)
    if not S.jam then return end
    Q.say("the pistol in the hand: the belt's pouch says Jammed " .. tostring(S.pouchJam()) .. ", its card still open " .. tostring(S.cardOn(S.A.gun))
        .. " (Ammo on the belt on " .. tostring(S.ammo) .. ", Lite " .. tostring(ZeD.Settings.lite and ZeD.Settings.lite()) .. ")")
    S.clearChar()
end)
-- what the pouch says, and what the card's facts say
function S.jamWords(g)
    local J = { status = "none", ammo = "?", pouch = "no pouch" }
    pcall(function()
        for _, r in ipairs(ZeD.itemFacts(g) or {}) do
            if r.label == "Status" then J.status = tostring(r.value) end
        end
    end)
    pcall(function()
        local panel = ZeD.ItemFactsPanel.factsFor(g, S.pn)
        local lbl = getText("Tooltip_weapon_Ammo")
        for _, grp in ipairs(panel.groups or {}) do
            for _, r in ipairs(grp.rows or {}) do if r.label == lbl then J.ammo = tostring(r.value) end end
        end
    end)
    pcall(function() local c = S.hud()._ammo; if c and c.gun == g then J.pouch = tostring(ZeD.Belt.ammoWords(c.a)) end end)
    return "the belt's ammo pouch reads \"" .. J.pouch .. "\" (jammed " .. tostring(S.pouchJam()) .. ")",
        "the card's Status row reads \"" .. J.status .. "\", the facts' Ammo row \"" .. J.ammo .. "\" (the word is \"" .. tostring(ZeD.tr("UI_ZeD_Jammed")) .. "\")"
end
Q.still(10, function()
    if not S.jam then return end
    local g = S.A.gun
    local pw, cw = S.jamWords(g)
    S.jamSplit = not S.cardOn(g)
    if not S.jamSplit then
        S.take("B5-11_jammed_pouch_card", "a jammed pistol held (" .. S.nm(g) .. "): " .. pw .. "; its card is open, " .. cw)
    elseif S.pouchJam() then
        -- (the card shut when the pistol went in the hand: the pouch now, the card in a picture of its own)
        S.take("B5-11_jammed_pouch", "a jammed pistol held (" .. S.nm(g) .. "): " .. pw .. " (its card shut when it went in the hand: the card is the next picture)")
    else
        S.skip("B5-11_jammed_pouch_card", "the pistol's card shut when it went in the hand and the pouch does not say Jammed (" .. pw .. ")")
    end
end)
-- out of the hand again (the hands as found): its row is back in the list; Ammo on the belt as found
Q.step(6, function() if S.jam then S.handsBack() end; S.ammoBack() end)
Q.step(20, function() S.A.gun2 = (S.jam and S.jamSplit) and S.A.gun or nil end)
-- only when the card shut above: the card alone, the pistol carried (S.A.gun2 is nothing otherwise, and nothing opens)
S.openCard("gun2", "B5-11 the pistol's card alone")
Q.still(10, function()
    if not S.A.gun2 then return end
    local _, cw = S.jamWords(S.A.gun2)
    if S.cardOn(S.A.gun2) then S.take("B5-11_jammed_card", "the jammed pistol's card (" .. S.nm(S.A.gun2) .. ", carried): " .. cw)
    else S.skip("B5-11_jammed_card", "the pistol's card did not open") end
end)
Q.step(6, function() S.A.gun2 = nil end)
S.shutCard("gun")
-- the balloon by the pointer on the pistol's row (ZeD's loot card): no card open, no menu, the pointer on the row
Q.still(10, function() if S.jam then S.aside(); S.seekPos = nil end end)
Q.waitFor(20, 600, function() return not S.jam or S.A.gun == nil or S.seekRow(S.cc(), S.A.gun) end, function(ok)
    S.tipOn = false
    if not (S.jam and S.A.gun) then return end
    local c = S.cc()
    local z = S.zone(c, S.A.gun)
    if not z then return end
    S.mouseOn(c:getAbsoluteX() + z.x + math.floor(z.w * 0.4), c:getAbsoluteY() + z.y + math.floor(z.h / 2))
    S.tipOn = true
end)
function S.tipUp()
    local IT = ZeD.InvTip
    local w = IT and IT._want
    return w ~= nil and w.item == S.A.gun and w.content ~= nil and w.frame >= (IT._frame or 0) - 1
end
Q.waitFor(5, 300, function() return not S.tipOn or S.tipUp() end, function() end)
Q.step(6, function()
    if not S.jam then S.skip("B7-4_jammed_hover_balloon", "no jammed pistol"); return end
    if not (S.tipOn and S.tipUp()) then
        local cues = false
        pcall(function() cues = ZeD.Input.Focus.cuesVisible() and true or false end)
        S.skip("B7-4_jammed_hover_balloon", "the balloon did not come up on the pistol's row (row found " .. tostring(S.tipOn) .. ", controller marks showing " .. tostring(cues) .. ")")
        return
    end
    local tags = {}
    pcall(function()
        for _, t in ipairs(ZeD.LootCard.facts(S.A.gun, S.p).tags or {}) do tags[#tags + 1] = tostring(t[1]) end
    end)
    S.take("B7-4_jammed_hover_balloon", "the pointer resting on the jammed pistol's row in the Character list (the pointer itself hidden, its place faked): ZeD's loot card, title \""
        .. tostring(ZeD.InvTip._want.content.title) .. "\", tags: " .. ((#tags > 0) and table.concat(tags, ", ") or "none"))
end)
Q.step(5, function()
    S.mouseOff(); S.jamBack()
    -- (the windows back from the screen's edges for the rest)
    S.home()
end)
Q.waitFor(10, 300, function() local w = S.CW(); return w ~= nil and w._activeTab == "loot" end, function() S.clearChar() end)

-- ===================================================================== W4: the reading band's Cancel, the cooking band
Q.step(20, function()
    S.w4 = false
    S.stopActions()
    local dark = true
    pcall(function() dark = S.p:tooDarkToRead() end)
    if dark then S.skip("W4_reading_band_cancel", "it is too dark to read here"); return end
    if not (ZeD.ItemActionManager and ISInventoryPaneContextMenu.readItem) then S.skip("W4_reading_band_cancel", "the action manager or the game's read is not loaded"); return end
    pcall(function() S.p:setTimedActionInstantCheat(false) end)    -- (a read at its real length)
    S.speed(1)
    S.A.book = S.add("Base.Book")
    S.w4 = S.A.book ~= nil
    if not S.w4 then S.skip("W4_reading_band_cancel", "no book could be given") end
end)
S.openCard("book", "W4 the book")
Q.step(5, function()
    if not S.w4 then return end
    if not S.cardOn(S.A.book) then S.w4 = false; S.skip("W4_reading_band_cancel", "the book's card did not open"); return end
    local ok, e = pcall(ISInventoryPaneContextMenu.readItem, S.A.book, S.pn)
    if not ok then S.w4 = false; S.skip("W4_reading_band_cancel", "the game's read stopped: " .. tostring(e)) end
end)
function S.bandUp()
    local w = S.CW()
    local card = w and w._itemCard
    local a = S.active(S.A.book)
    return S.reading() and a ~= nil and card ~= nil and card._cancelRect ~= nil
end
Q.waitFor(2, 1200, function() return not S.w4 or S.bandUp() end, function(ok)
    if not S.w4 then return end
    if not ok then
        S.w4 = false
        local a = S.active(S.A.book)
        S.skip("W4_reading_band_cancel", "the reading band with its Cancel did not come up (reading " .. tostring(S.reading()) .. ", band " .. tostring(a and a.kind) .. ")")
        S.stopActions()
        return
    end
    S.clearChar()
end)
Q.still(4, function()
    if not S.w4 then return end
    local a = S.active(S.A.book)
    if not (S.bandUp() and S.cardOn(S.A.book)) then
        S.w4 = false
        S.skip("W4_reading_band_cancel", "the read ended before the picture (reading " .. tostring(S.reading()) .. ")")
        S.stopActions()
        return
    end
    S.take("W4_reading_band_cancel", "reading " .. S.nm(S.A.book) .. ", its card open: the band reads " .. tostring(a.label or a.kind) .. " with its Cancel on it (band kind " .. tostring(a.kind) .. ")")
    S.w4shot = true
end)
-- Cancel, as a press on the band's X runs it (a step after the picture: the picture is of the frame as drawn)
Q.step(6, function()
    if not (S.w4 and S.w4shot) then return end
    local card = S.CW()._itemCard
    local okC, e = pcall(function() card:_dispatchProgressCancel() end)
    S.w4c = okC
    if not okC then Q.say("ERR the band's Cancel stopped: " .. tostring(e)) end
end)
Q.waitFor(2, 400, function() return not (S.w4 and S.w4c) or not S.reading() end, function(ok) end)
Q.still(20, function()
    if not (S.w4 and S.w4c) then return end
    local a = S.active(S.A.book)
    if S.reading() or a ~= nil then
        S.take("W4_reading_cancelled", "AFTER Cancel on the band the character still reads (reading " .. tostring(S.reading()) .. ", band " .. tostring(a and a.kind) .. "): the fault")
    else
        S.take("W4_reading_cancelled", "after Cancel on the band: the reading stopped, the band gone from " .. S.nm(S.A.book) .. "'s card (reading false, no band)")
    end
end)
Q.step(5, function() S.stopActions() end)
S.shutCard("book")
-- the cooking band: nothing to stop, so no X. Staged through ZeD's action manager on a steak's card (no stove)
Q.step(10, function()
    S.w4b = false
    S.drop(S.A.book); S.A.book = nil
    if not ZeD.ItemActionManager then S.skip("W4_cooking_band_no_x", "the action manager is not loaded"); return end
    S.A.steak = S.add("Base.Steak")
    S.w4b = S.A.steak ~= nil
    if not S.w4b then S.skip("W4_cooking_band_no_x", "no steak could be given") end
end)
S.openCard("steak", "W4 the steak")
Q.step(5, function()
    if not S.w4b then return end
    if not S.cardOn(S.A.steak) then S.w4b = false; S.skip("W4_cooking_band_no_x", "the steak's card did not open"); return end
    S.cookOn = true
    -- (the words the game's own cooking poll gives the band, ItemActionHooks._pollCooking: COOKING and the minutes left)
    local label, left = "COOKING", "5 min"
    pcall(function() label = ZeD.upper(ZeD.tr("IGUI_invpanel_Cooking")) end)
    pcall(function() left = ZeD.tr("UI_ZeD_ItemAct_MinutesShort", 5) end)
    pcall(function()
        ZeD.ItemActionManager.notify(S.A.steak, "start", { kind = "cooking", label = label, mode = "active", percent = 0.4, timeStr = left, _action = nil })
    end)
end)
Q.step(30, function() if S.w4b then S.clearChar() end end)
Q.still(10, function()
    if not S.w4b then return end
    local w = S.CW()
    local card = w and w._itemCard
    local a = S.active(S.A.steak)
    if not (card and S.cardOn(S.A.steak) and a and a.kind == "cooking") then
        S.skip("W4_cooking_band_no_x", "the staged band did not hold on the steak's card (band " .. tostring(a and a.kind) .. ")")
        return
    end
    S.take("W4_cooking_band_no_x", "a cooking band on " .. S.nm(S.A.steak) .. "'s card (staged through ZeD's action manager, no stove): an X on the band "
        .. tostring(card._cancelRect ~= nil) .. (card._cancelRect and " (the fault: a cooking band has nothing to cancel)" or " (none, as fixed)"))
end)
function S.w4Back()
    S.stopActions()
    if S.cookOn and S.A.steak then pcall(function() ZeD.ItemActionManager.notify(S.A.steak, "complete", nil) end) end
    S.cookOn = nil
    pcall(function() if S.was.instant ~= nil then S.p:setTimedActionInstantCheat(S.was.instant == true) end end)
end
Q.step(5, function() S.w4Back() end)
S.shutCard("steak")
Q.step(5, function()
    S.drop(S.A.steak); S.A.steak = nil
    S.drop(S.A.book); S.A.book = nil
    S.handsBack()
end)

-- ===================================================================== B5-9: a steak in a powered freezer
function S.inList(inv)
    local w = S.WW()
    if not inv then return false end
    for _, c in ipairs((w and w._containers) or {}) do if c.inventory == inv then return true end end
    return false
end
function S.inPane(inv, item)
    local c = S.wc()
    if not (c and inv and item and c._inventory == inv) then return false end
    for _, it in ipairs(c._flatItems or {}) do if it == item then return true end end
    return false
end
function S.powered() local on = false; pcall(function() on = S.frz:isPowered() end); return on and true or false end
function S.removeObj(obj)
    if not obj then return end
    local sq = nil
    pcall(function() sq = obj:getSquare() end)
    if sq then
        pcall(function() sq:transmitRemoveItemFromSquare(obj) end)
        pcall(function() if obj:getObjectIndex() >= 0 then sq:RemoveTileObject(obj) end end)
    end
    pcall(function() if instanceof(obj, "IsoGenerator") then obj:remove() end end)
end
function S.wcardOn(item)
    local w = S.WW()
    local c = w and w._itemCard
    return item ~= nil and w ~= nil and w._drawerItem == item and c ~= nil and c.item == item
end
function S.frBack()
    S.speed(1)
    if S.frFast then
        S.frFast = nil
        pcall(function() if STORY and STORY.day then STORY.day(11.0) end end)
        S.statsBack()
    end
    if S.frSteak then pcall(function() local c = S.frSteak:getContainer(); if c then c:Remove(S.frSteak) end end) end
    S.frSteak = nil
    if S.gen then pcall(function() S.gen:setActivated(false); S.gen:setConnected(false) end) end
    S.removeObj(S.fridge); S.removeObj(S.gen)
    S.fridge, S.gen, S.frz = nil, nil, nil
    pcall(function() S.WW()._containersDirty = true end)
end
-- a free square beside him that he reaches (no wall between: the smoke spot can stand by the store's wall, and the
-- World window lists only what he reaches)
function S.nearSq(offs)
    local here = nil
    pcall(function() here = S.p:getCurrentSquare() end)
    for _, o in ipairs(offs) do
        local sq = getCell():getGridSquare(math.floor(S.p:getX()) + o[1], math.floor(S.p:getY()) + o[2], math.floor(S.p:getZ()))
        local ok = false
        if sq and here then pcall(function() ok = sq:isFree(false) and here:canReachTo(sq) end) end
        if ok then return sq end
    end
    return nil
end
Q.step(20, function()
    S.fr = false
    S.openPair(); S.charTab("loot"); S.worldTab("loot")
    -- beside him on the far side from the camera (west or north), so the fridge stands behind him; at his side (the
    -- same depth) only when neither is free
    local sq = S.nearSq({ { -1, 0 }, { 0, -1 }, { -1, -1 }, { 1, -1 }, { -1, 1 } })
    if not sq then S.skip("B5-9_freezer_steak", "no free square beside the character that he reaches"); return end
    for _, name in ipairs({ "appliances_refrigeration_01_0", "appliances_refrigeration_01_4" }) do
        if not S.fridge and getSprite(name) then
            pcall(function()
                local o = IsoObject.new(sq, name, nil, false)
                sq:AddTileObject(o)
                pcall(function() o:createContainersFromSpriteProperties() end)
                if o:getContainer() then S.fridge = o else pcall(function() sq:transmitRemoveItemFromSquare(o) end) end
            end)
        end
    end
    if not S.fridge then S.skip("B5-9_freezer_steak", "no fridge tile could be placed"); return end
    pcall(function() S.frz = S.fridge:getContainerByType("freezer") end)
    if S.frz then pcall(function() S.frSteak = S.frz:AddItem("Base.Steak") end) end
    if not (S.frz and S.frSteak) then S.skip("B5-9_freezer_steak", "the fridge has no freezer, or no steak could be put in it"); S.frBack(); return end
    S.fr = true
    pcall(function() S.WW()._containersDirty = true end)
end)
Q.step(30, function()
    if not S.fr or S.powered() then return end
    -- no power here: a generator a few squares off, behind him, as a player would run one
    local gsq = S.freeSq({ { -3, -1 }, { -1, -3 }, { -3, 0 }, { 0, -3 }, { -2, -2 }, { -3, -3 }, { -3, 1 }, { 1, -3 } })
    if gsq then
        pcall(function()
            S.gen = IsoGenerator.new(instanceItem("Base.Generator"), getCell(), gsq)
            S.gen:setFuel(60); S.gen:setCondition(100); S.gen:setConnected(true); S.gen:setActivated(true)
        end)
    end
    Q.say("B5-9: no power at the spot, a generator placed " .. tostring(S.gen ~= nil))
end)
Q.waitFor(10, 900, function() return not S.fr or S.powered() end, function(ok)
    if not S.fr then return end
    if not S.powered() then S.fr = false; S.skip("B5-9_freezer_steak", "the freezer has no power (generator " .. tostring(S.gen ~= nil) .. ")"); S.frBack(); return end
    pcall(function() S.WW()._containersDirty = true end)
end)
Q.waitFor(10, 900, function() return not S.fr or S.inList(S.frz) end, function(ok)
    if not S.fr then return end
    if not S.inList(S.frz) then S.fr = false; S.skip("B5-9_freezer_steak", "the World window does not list the freezer"); S.frBack(); return end
    pcall(S.WWm.selectContainer, S.frz, 120, S.pn)
end)
Q.waitFor(10, 900, function() return not S.fr or S.inPane(S.frz, S.frSteak) end, function(ok)
    if not S.fr then return end
    if not S.inPane(S.frz, S.frSteak) then S.fr = false; S.skip("B5-9_freezer_steak", "the Loot list does not show the freezer with the steak"); S.frBack(); return end
    pcall(function() S.fz0 = S.frSteak:getFreezingTime() end)
    Q.say(string.format("B5-9: the freezer shows in the Loot list, powered %s (%s), the steak's freezing %.1f of 100; fast-forward now", tostring(S.powered()),
        S.gen and "a generator" or "the grid", S.fz0 or -1))
    -- (nothing can hurt him over the game hours that pass; the picture's own clean-up takes god mode off again)
    pcall(function() S.p:setGodMod(true) end)
    S.frFast = true
    S.frT0 = getTimestampMs()
    S.speed(3)
end)
-- (a full freeze is 4 game hours of freezer time; the wait is by the clock, two minutes at most)
Q.waitFor(10, 60000, function()
    if not S.fr then return true end
    local fz = false
    pcall(function() fz = S.frSteak:isFrozen() end)
    return fz or getTimestampMs() - (S.frT0 or 0) > 120000
end, function(ok)
    if not S.fr then return end
    S.speed(1)
    pcall(function() S.fz1 = S.frSteak:getFreezingTime() end)
    pcall(function() S.frFrozen = S.frSteak:isFrozen() and true or false end)
    Q.say(string.format("B5-9: after %d s at speed 3 the steak's freezing is %.1f of 100, frozen %s", math.floor((getTimestampMs() - (S.frT0 or 0)) / 1000), S.fz1 or -1, tostring(S.frFrozen)))
    -- the story's daylight again, his needs as they were, and the dead that wandered near in those hours taken away
    -- (none walks into the picture)
    S.frFast = nil
    pcall(function() if STORY and STORY.day then STORY.day(11.0) end end)
    S.statsBack()
    Q.say("B5-9: zombies taken away near him after the fast-forward: " .. S.zombiesAway())
    pcall(S.WWm.selectContainer, S.frz, 120, S.pn)
end)
Q.waitFor(20, 600, function() return not S.fr or S.zone(S.wc(), S.frSteak) ~= nil end, function(ok)
    if not S.fr then return end
    local c = S.wc()
    local z = S.zone(c, S.frSteak)
    Q.say("B5-9: the steak's row " .. tostring(z ~= nil) .. ", pressed " .. tostring(z ~= nil and S.click(c, z)))
end)
Q.waitFor(10, 300, function() return not S.fr or S.wcardOn(S.frSteak) end, function(ok) if S.fr then S.clearChar() end end)
Q.still(10, function()
    if not S.fr then return end
    local tags = {}
    pcall(function()
        for _, t in ipairs(ZeD.LootCard.facts(S.frSteak, S.p).tags or {}) do tags[#tags + 1] = tostring(t[1]) end
    end)
    if not ((S.fz1 or 0) > (S.fz0 or 0)) then
        S.skip("B5-9_freezer_steak", string.format("the steak's freezing did not start (%.1f -> %.1f of 100, freezer powered %s): the fault, or no freezing in this game", S.fz0 or -1, S.fz1 or -1, tostring(S.powered())))
        return
    end
    S.take("B5-9_freezer_steak", string.format("a powered freezer (%s) in the World window's Loot list, a steak in it: its freezing went %.1f -> %.1f of 100 with only ZeD's list showing it, frozen %s; "
        .. "the steak's card open on the World window %s; its state words: %s", S.gen and "a generator behind him" or "grid power", S.fz0 or -1, S.fz1 or -1, tostring(S.frFrozen),
        tostring(S.wcardOn(S.frSteak)), (#tags > 0) and table.concat(tags, ", ") or "none"))
end)
Q.step(5, function()
    if S.frSteak and S.wcardOn(S.frSteak) then
        local c = S.wc()
        local z = S.zone(c, S.frSteak)
        if z then S.click(c, z) end
    end
end)
Q.step(20, function() S.frBack(); S.worldTab("loot") end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    S.shutMenu()
    S.mouseOff()
    pcall(S.w4Back)
    pcall(S.jamBack)
    pcall(S.frBack)
    pcall(S.viewMain)
    pcall(S.w3Back)
    for _, it in ipairs(S.bagMade or {}) do S.drop(it) end
    S.bagMade = {}
    pcall(function() if S.was.ctx then ZeD.Settings.contextStyleOption:setValue(S.was.ctx) end end)
    pcall(function() if S.was.eqView and ZeD.Settings.equipViewOption:getValue() ~= S.was.eqView then ZeD.Settings.equipViewOption:setValue(S.was.eqView) end end)
    pcall(S.ammoBack)
    -- the inventory side open again, if a run cut short left it shut by its bag's button (W8; on a tab the inventory's
    -- own button opens it on its main list; on Loot that button is a column's, and the layout reset below opens it)
    pcall(function()
        local cw = S.CW()
        if cw and cw._invDrawerOpen == false and cw._activeTab ~= "loot" then S.pressStrip("main_toggle") end
    end)
    -- the character's own pins, the same table
    if S.was.pinsAside then pcall(function() S.p:getModData().ZeD_Pins = S.was.pins end); S.was.pinsAside = nil end
    pcall(function()
        local c = S.cc()
        for ft, v in pairs(S.stackWas or {}) do
            if c and c._expandedStacks then c._expandedStacks[ft] = (v ~= false) and v or nil end
            for _, cs in ipairs((c and c._colStates) or {}) do
                if cs.expandedStacks and cs.expandedStacks ~= c._expandedStacks then cs.expandedStacks[ft] = (v ~= false) and v or nil end
            end
        end
    end)
    for _, k in ipairs({ "hammer", "bottle", "gun", "book", "steak" }) do S.drop(S.A[k]); S.A[k] = nil end
    S.takeMade()
    S.handsBack()
    local back = S.wornBack()
    S.statsBack()
    G1.glassesBack(Q)
    -- alive and whole
    local hp = nil
    pcall(function() hp = S.p:getBodyDamage():getOverallBodyHealth() end)
    if hp ~= nil and S.was.hp ~= nil and hp < S.was.hp - 0.01 then
        pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end)
        Q.say("the character was hurt (" .. string.format("%.1f", hp) .. " of " .. string.format("%.1f", S.was.hp) .. "): healed whole")
    end
    Q.say("put back: clothes put on again " .. back .. ", worn now " .. (function() local n = 0; for _ in pairs(S.wornNow()) do n = n + 1 end; return n end)()
        .. " of " .. #(S.was.worn or {}) .. " at the start, dead " .. tostring(S.p:isDead()))
end)
Q.step(20, function()
    S.openPair()
    S.charTab("loot"); S.worldTab("loot")
    if ZEDQA_LAYOUT_BACK and S.was.snap then pcall(ZEDQA_LAYOUT_BACK, S.was.snap, "bxri") end
    pcall(function() if S.gridKey and S.was.grid ~= nil then IR.setGridKey(S.gridKey, S.was.grid == true) end end)
    S.back0()
end)
Q.step(30, function()
    if not S.was.pairOpen then S.closePair() end
    pcall(function() Mouse.setCursorVisible(true) end)
    Q.say("put back")
end)
Q.start()
