-- ZeDUI/tools/qa/zedqa_lists.lua  (Oct 29 2026)
-- In game on the ZeD-QA save: loadouts and outfits (handoff equip_doll_v4_loadouts,
-- parts B1-B3). Carries a crowbar, three bandages, a bottle of water and a cap.
--   * the data (ZeD_Lists): save what I carry / what I wear, create, rename,
--     delete, add and remove lines, Any | This one, A day | Fixed, amounts, the
--     resolver, and the store holding only what the save keeps (a deep copy put
--     back in the mod data reads the same: the round trip);
--   * the Journal's Loadouts page (sub-tab 5) in the full card (480 units, the panes
--     stacked): the top and, scrolled, the lines, its stops, a switch, the amount stepper, Delete asked first in
--     the band (its two answers the only stops);
--   * the right-click menu in both looks: Save to loadout / Save to outfit by
--     name, the checks matching the lists, a pick taking the item off and on;
--   * the item card's mark strip: the Lists button lit, its pop-up, the In
--     lists section.
-- Puts back the character's lists, the menu look and the tab; takes the items
-- back. Screenshots/zqa_ls_*.png. grep "ZEDQA ls".
local p = getPlayer()
local pn = p:getPlayerNum()
local L, LU, JL = ZeD.Lists, ZeD.ListsUI, ZeD.JournalLists
local Focus = ZeD.Input and ZeD.Input.Focus
local function say(s) print("ZEDQA ls " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ls_" .. n .. ".png") end) end
local function cw() return ZeD_CharacterWindow.getWindow() end
local fails = 0
local function check(ok, what) if ok then say("ok   " .. what) else fails = fails + 1; say("FAIL " .. what) end end

local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
-- before a capture: the windows still (place, size, drawer width) for 30 ticks, at most 600
local STILL, STILL_MAX = 30, 600
local function shape()
    local t = {}
    for _, w in ipairs({ ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow() }) do
        if w and w:isVisible() then
            local dp = w._drawerPanel
            t[#t + 1] = string.format("%d,%d,%d,%d,%d", w:getX(), w:getY(), w:getWidth(), math.floor(w._drawerEffW or 0), dp and dp:getWidth() or 0)
        end
    end
    return table.concat(t, ";")
end
local still = { last = nil, same = 0, waited = 0 }
local function stillStep(fn)
    Q[#Q + 1] = { still = true, fn = fn }
end

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = deepCopy(v) end
    return o
end

local md = p:getModData()
local saved = deepCopy(md.ZeD_Lists)
local styleOpt = ZeD.Settings.contextStyleOption
local styleWas = styleOpt and styleOpt:getValue()
local crowbar, bands, bottle, cap
local carryId, wearId
local function zoneOf(id)
    for _, z in ipairs(cw()._jlZones or {}) do if z.id == id then return z end end
    return nil
end
local function click(id, half)
    local z = zoneOf(id)
    if not z then say("no zone " .. id); return false end
    local x = z.x + (half == 2 and (z.w - 3) or 3)
    return JL.onClick(cw(), x, z.y + math.floor(z.h / 2))
end
-- the first line whose zone (prefix "sw:" / "amt:") is in the page's view and passes ok(line)
local function visibleLine(prefix, ok)
    local w = cw()
    local clip = JL.state(w).clip
    local lo = L.get(p, carryId)
    for _, z in ipairs(w._jlZones or {}) do
        if z.id:sub(1, #prefix) == prefix and clip and z.y >= clip.y and z.y + z.h <= clip.y + clip.h then
            local ln = L.line(lo, tonumber(z.id:sub(#prefix + 1)))
            if ln and ok(ln) then return ln end
        end
    end
    return nil
end
local function zm() local v = getPlayerContextMenu(pn); return v and v._zedMenu end
local function pageEls()
    local out = {}
    for _, e in ipairs(JL.focusables(cw())) do out[#out + 1] = e.id end
    return out
end

-- ---------------------------------------------------------------------------
step(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
    p:setGodMod(true)
    md.ZeD_Lists = nil   -- (a clean store for the run; the character's own put back at the end)
    local inv = p:getInventory()
    crowbar = inv:AddItem("Base.Crowbar")
    bands = { inv:AddItem("Base.Bandage"), inv:AddItem("Base.Bandage"), inv:AddItem("Base.Bandage") }
    bottle = inv:AddItem("Base.WaterBottle")
    pcall(function() local fc = bottle:getFluidContainer(); fc:Empty(); fc:addFluid(Fluid.Water, 0.8) end)
    cap = inv:AddItem("Base.Hat_BaseballCap")
    say("items: crowbar " .. tostring(crowbar ~= nil) .. " water " .. tostring(L.waterIn(bottle)))
end)

-- the data -----------------------------------------------------------------
step(10, function()
    local lo = L.saveCarry(p, "QA carry")
    carryId = lo.id
    local nCar, nBand, nWater, secs = 0, 0, 0, {}
    for _, ln in ipairs(lo.lines) do
        secs[ln.sec] = (secs[ln.sec] or 0) + 1
        if ln.type == "Base.Crowbar" then nCar = ln.amount; check(ln.sec == "gear", "crowbar is gear (" .. tostring(ln.place) .. ", " .. ln.rule .. ")") end
        if ln.type == "Base.Bandage" then nBand = ln.amount; check(ln.sec == "supply" and ln.per == "fixed", "bandages are a fixed supply") end
        if ln.kind == "water" then nWater = ln.amount end
    end
    say("carry: " .. #lo.lines .. " lines, gear " .. tostring(secs.gear) .. " supply " .. tostring(secs.supply))
    check(nCar >= 1, "save what I carry: the crowbar")
    check(nBand >= 3, "save what I carry: bandages grouped (" .. tostring(nBand) .. ")")
    check(nWater >= 0.5, "save what I carry: water in litres (" .. tostring(nWater) .. ")")
    for _, ln in ipairs(lo.lines) do
        if ln.place == "hand:main" or ln.place == "hand:off" then check(ln.rule == "this", "in hand: this one (" .. tostring(ln.name) .. ")") end
    end
    local wo = L.saveWear(p, "QA wear")
    wearId = wo.id
    local worn, nonBag = p:getWornItems(), 0
    for i = 0, worn:size() - 1 do
        local it = worn:get(i):getItem()
        if it and not instanceof(it, "InventoryContainer") then nonBag = nonBag + 1 end
    end
    check(#wo.lines == nonBag, "save what I wear: " .. #wo.lines .. " lines for " .. nonBag .. " worn non-bags")
    local allWorn = true
    for _, ln in ipairs(wo.lines) do if ln.sec ~= "worn" or ln.rule ~= "any" or ln.place:sub(1, 5) ~= "worn:" then allWorn = false end end
    check(allWorn, "outfit lines: worn, any, at their location")
end)

step(5, function()
    local t = L.create(p, "loadout", "QA temp")
    check(t and L.get(p, t.id) ~= nil, "create")
    L.rename(p, t.id, "QA temp 2")
    check(L.get(p, t.id).name == "QA temp 2", "rename")
    -- add / remove lines: the crowbar toggled on and off
    check(L.toggleItem(p, t.id, crowbar) == true and #L.get(p, t.id).lines == 1, "toggle on: one line")
    local hits = L.listsWith(p, crowbar)
    check(#hits >= 2, "listsWith: the crowbar is in " .. #hits .. " lists")
    check(L.toggleItem(p, t.id, crowbar) == false and #L.get(p, t.id).lines == 0, "toggle off: no lines")
    -- the cap cannot go on a loadout's outfit check, but on an outfit yes
    check(L.canOutfit(cap) and not L.canOutfit(crowbar), "outfits: wearables only")
    check(L.delete(p, t.id) and L.get(p, t.id) == nil, "delete")
    -- switches and amounts on the carry list
    local lo = L.get(p, carryId)
    local car, band
    for _, ln in ipairs(lo.lines) do
        if ln.type == "Base.Crowbar" then car = ln end
        if ln.type == "Base.Bandage" then band = ln end
    end
    L.setRule(p, carryId, car.id, "this"); check(car.rule == "this" and car.amount == 1, "This one")
    L.setRule(p, carryId, car.id, "any"); check(car.rule == "any", "Any")
    L.setPer(p, carryId, band.id, "day"); check(band.per == "day", "A day")
    L.setAmount(p, carryId, band.id, 2); check(band.amount == 2, "amount 2")
    local r1 = L.resolve(p, band, 1)
    local r3 = L.resolve(p, band, 3)
    check(r1.ok and r1.have >= 3, "resolve: bandages on you for 1 day (have " .. r1.have .. ")")
    check(not r3.ok and r3.need == 6, "resolve: 3 days need 6, not ready")
    L.setPer(p, carryId, band.id, "fixed"); L.setAmount(p, carryId, band.id, 3)
    local rc = L.resolve(p, car, 1)
    check(rc.ok, "resolve: the crowbar in its place (" .. tostring(car.place) .. ")")
    local n, m = L.ready(p, lo, 1)
    say("ready " .. n .. " of " .. m)
    -- the store holds only what the save keeps; a deep copy put back reads the same
    local ok, bad = L.check(p)
    check(ok, "store is plain values" .. (bad and (": " .. bad) or ""))
    local before = #L.all(p) .. ":" .. #L.get(p, carryId).lines .. ":" .. L.get(p, carryId).name
    md.ZeD_Lists = deepCopy(md.ZeD_Lists)
    local after = #L.all(p) .. ":" .. #L.get(p, carryId).lines .. ":" .. L.get(p, carryId).name
    check(before == after, "round trip " .. after)
end)

-- the page, in the full card (480 units) ----------------------------------------
step(5, function()
    local w = cw()
    w._activeTab = "journal"; w._drawerMode = "tab"; w._drawerOpen = true
    w._journalSubTab = 5
    JL.select(w, carryId)
end)
stillStep(function()
    local w = cw()
    local s = JL.state(w)
    say("page: drawer " .. tostring(w._drawerPanel and w._drawerPanel:getWidth()) .. " stacked " .. tostring(s.stacked) .. " zones " .. #(w._jlZones or {}))
    check(zoneOf("carry") and zoneOf("wear") and zoneOf("new") and zoneOf("filter") and zoneOf("list:" .. carryId), "the page's buttons, filter and list rows")
    check(zoneOf("rename") and zoneOf("add") and zoneOf("delete"), "the chosen list's Rename / Add / Delete")
    local ids = pageEls()
    say("stops " .. #ids .. ": " .. table.concat(ids, ","):sub(1, 400))
    check(s.stacked == true, "full card: the panes stack (drawer " .. tostring(w._drawerPanel:getWidth()) .. " px, 480u = " .. ZeD.T.px(480) .. ")")
    shot("01_page_480")
    -- the lines' section to the top of the view (the page's one scroll)
    local z, st = zoneOf("lsec:gear"), s
    if z and st.clip and (st.total or 0) > st.clip.h then
        local off = st.scroll.scrollPos * (st.total - st.clip.h)
        st.scroll:setScrollPos(math.max(0, math.min(1, (off + z.y - st.clip.y) / (st.total - st.clip.h))))
    end
end)
step(10, function() shot("02_page_480_lines") end)
step(5, function()
    -- a switch (Any | This one): the right half picks This one
    local car = visibleLine("sw:", function(ln) return ln.sec == "gear" and ln.rule == "any" and ln.itemId ~= nil end)
    say("switch on: " .. tostring(car and car.name))
    click("sw:" .. car.id, 2)
    check(car.rule == "this", "page: the switch's right half sets This one")
    click("sw:" .. car.id, 1)
    check(car.rule == "any", "page: the left half sets Any")
    -- the amount: pressed, a stepper; + adds one
    local band = visibleLine("amt:", function() return true end)
    cw()._qaBand = band
    say("amount on: " .. tostring(band and band.name))
    click("amt:" .. band.id)
    check(JL.state(cw()).step == band.id, "page: the amount opens a stepper")
end)
step(5, function()
    local band = cw()._qaBand
    local a0 = band.amount
    click("inc:" .. band.id)
    check(band.amount == a0 + 1, "page: + adds one (" .. band.amount .. ")")
    -- the pad's left on the open amount takes one off
    local el
    for _, e in ipairs(JL.focusables(cw())) do if e.id == "jl:amt:" .. band.id then el = e end end
    if el and el.onDpadDir then el.onDpadDir(cw(), el, "left") end
    check(band.amount == a0, "page: the pad's left takes one off (" .. band.amount .. ")")
    shot("03_stepper")
    click("amt:" .. band.id)
    check(JL.state(cw()).step == nil, "page: pressing the amount again closes the stepper")
end)
step(5, function()
    -- remove a line by its menu (the right-click's Remove)
    local lo = L.get(p, carryId)
    local n0 = #lo.lines
    local last = lo.lines[n0]
    local z = zoneOf("line:" .. last.id)
    if z and z.menu then
        z.menu(400, 400)
        local m = JL.menu
        local row = m and m._levels[1] and m._levels[1].rows[1]
        if row and row.def and row.def.onFire then row.def.onFire(); m:close() end
    end
    check(#lo.lines == n0 - 1, "page: Remove takes the line off (" .. #lo.lines .. ")")
end)

-- delete, asked first ------------------------------------------------------------
step(10, function()
    local t = L.create(p, "outfit", "QA doomed")
    JL.select(cw(), t.id)
    say("doomed " .. t.id)
    cw()._qaDoomed = t.id
end)
step(5, function()
    click("delete")
    check(JL.state(cw()).ask == cw()._qaDoomed, "Delete asks first")
end)
step(5, function()
    local ids = pageEls()
    check(#ids == 2 and ids[1] == "jl:ask:cancel", "the question's two answers are the only stops (" .. table.concat(ids, ",") .. ")")
    shot("04_ask_delete")
    local r = JL.state(cw()).askRects
    JL.onClick(cw(), r.verb.x + 2, r.verb.y + 2)
    check(L.get(p, cw()._qaDoomed) == nil, "Delete in the band deletes")
end)

-- the right-click menu, list look -------------------------------------------------
step(10, function()
    styleOpt:setValue(2)
    ISInventoryPaneContextMenu.createMenu(pn, true, { crowbar }, 700, 300)
end)
step(15, function()
    local m = zm()
    local lv = m and m._levels and m._levels[1]
    local names, at = {}, nil
    for i, r in ipairs(lv and lv.rows or {}) do
        names[#names + 1] = r.sep and "|" or tostring(r.def.name)
        if r.def and r.def.name == ZeD.tr("UI_ZeD_Lists_SaveToLoadout") then at = i end
    end
    say("list look: " .. table.concat(names, ", "))
    check(at ~= nil, "list look: Save to loadout")
    if at then
        lv.sel = at
        m:onJoypadDirRight()
        local sub = m._levels[2]
        local subNames, checkedCarry = {}, nil
        for _, r in ipairs(sub and sub.rows or {}) do
            if r.def then
                local c = r.def.check
                subNames[#subNames + 1] = tostring(r.def.name) .. (c == true and " [x]" or (c == false and " [ ]" or ""))
                if r.def.name == "QA carry" then checkedCarry = (c == true) end
            else subNames[#subNames + 1] = "|" end
        end
        say("submenu: " .. table.concat(subNames, ", "))
        check(checkedCarry == true, "list look: QA carry checked (the crowbar is on it)")
    end
end)
step(10, function() shot("05_rightclick_list") end)
step(5, function()
    local m = zm()
    local sub = m and m._levels[2]
    for i, r in ipairs(sub and sub.rows or {}) do
        if r.def and r.def.name == "QA carry" then sub.sel = i end
    end
    if m then m:confirm(2) end
    check(L.lineOfItem(L.get(p, carryId), crowbar) == nil, "list look: picking a checked list takes the item out")
end)
-- the right-click menu, icon strip --------------------------------------------------
step(10, function()
    styleOpt:setValue(1)
    ISInventoryPaneContextMenu.createMenu(pn, true, { crowbar }, 700, 300)
end)
step(15, function()
    local m = zm()
    local def
    for _, d in ipairs(m and m._ctx and m._ctx.actions or {}) do
        if d.name == ZeD.tr("UI_ZeD_Lists_SaveToLoadout") then def = d end
    end
    check(def ~= nil and def.children and #def.children >= 2, "strip: Save to loadout drills into the names")
    local carryDef
    for _, c in ipairs(def and def.children or {}) do if c.name == "QA carry" then carryDef = c end end
    check(carryDef and carryDef.check == false, "strip: QA carry unchecked now")
    -- drill in (the strip's own path) for the capture, then pick it
    if m and def then
        for i, d in ipairs(m._ctx.actions) do if d == def then pcall(function() m:_push(i) end) end end
    end
end)
step(10, function() shot("06_rightclick_strip") end)
step(5, function()
    local m = zm()
    local def
    for _, d in ipairs(m and m._ctx and m._ctx.actions or {}) do
        if d.name == ZeD.tr("UI_ZeD_Lists_SaveToLoadout") then def = d end
    end
    for _, c in ipairs(def and def.children or {}) do if c.name == "QA carry" then c.onFire() end end
    if m then m:close() end
    check(L.lineOfItem(L.get(p, carryId), crowbar) ~= nil, "strip: picking it puts the item back on")
    -- the cap: Save to outfit offered, the crowbar not
    local okCap = LU.canKind("outfit", { cap }) and not LU.canKind("outfit", { crowbar })
    check(okCap, "Save to outfit only for wearables")
end)

-- the mark strip -------------------------------------------------------------------
step(5, function()
    local w = cw()
    w._journalSubTab = 1
    w._activeTab = "loot"; w._drawerOpen = false
end)
step(20, function()
    local w = cw()
    local zi, z
    for i, zz in ipairs(w._focusRing or {}) do if zz.zone == "charMainInv" then zi, z = i, zz end end
    for ei, el in ipairs(z and z.elements or {}) do
        if el.item == crowbar then
            w._focusIdx = zi; z.focusedElementIdx = ei
            if el.onFocus then el.onFocus(w, el) end
            el.onActivate(w, el)
        end
    end
    say("card open " .. tostring(w._drawerItem == crowbar))
end)
stillStep(function()
    local c = cw()._itemCard
    local marks = ZeD.ItemCard.readMarks(crowbar, pn)
    check(marks.lists == true, "mark strip: Lists lit (" .. tostring(marks.listsText) .. ")")
    check(c and c._listsRect ~= nil, "mark strip: the Lists button is drawn")
    local found = false
    for _, e in ipairs(c and c:getActionStripElements() or {}) do if e.id == "toggle_lists" then found = true end end
    check(found, "mark strip: the Lists button is a pad stop")
    -- the In lists section, after the facts: the card scrolled to its foot
    if c then for _ = 1, 30 do pcall(c.onMouseWheel, c, 1) end end
end)
step(15, function()
    local c = cw()._itemCard
    shot("07_card_inlists")
    for _ = 1, 30 do pcall(c.onMouseWheel, c, -1) end
end)
step(10, function()
    local c = cw()._itemCard
    if c then c:openListsPopup() end
end)
step(10, function()
    local m = LU.popup
    local names = {}
    for _, r in ipairs(m and m._levels[1].rows or {}) do
        if r.def then
            local c = r.def.check
            if type(c) == "function" then c = c() end
            names[#names + 1] = tostring(r.def.name) .. (r.def.heading and " (head)" or "") .. (c == true and " [x]" or (c == false and " [ ]" or ""))
        else names[#names + 1] = "|" end
    end
    say("pop-up: " .. table.concat(names, ", "))
    check(m and m._ctx.open, "mark strip: the pop-up opens")
    shot("08_mark_popup")
end)
step(5, function()
    -- tick QA carry off in the pop-up: it stays open, the check follows
    local m = LU.popup
    local lv = m._levels[1]
    for i, r in ipairs(lv.rows) do if r.def and r.def.name == "QA carry" then lv.sel = i end end
    m:confirm(1)
    check(m._ctx.open and L.lineOfItem(L.get(p, carryId), crowbar) == nil, "pop-up: a tick takes it off and stays open")
    m:confirm(1)
    check(L.lineOfItem(L.get(p, carryId), crowbar) ~= nil, "pop-up: ticked again, back on")
    m:close()
end)

-- put back ---------------------------------------------------------------------------
step(10, function()
    local w = cw()
    if w then
        w._drawerItem = nil
        w._journalSubTab = 1
        w._activeTab = "loot"; w._drawerOpen = false
    end
    styleOpt:setValue(styleWas)
    md.ZeD_Lists = saved
    L.gen = L.gen + 1
    local inv = p:getInventory()
    for _, it in ipairs({ crowbar, bottle, cap, bands[1], bands[2], bands[3] }) do if it then inv:Remove(it) end end
    say("DONE (" .. fails .. " failed)")
end)

local function onTick()
    if qi >= #Q then Events.OnTick.Remove(onTick); return end
    local s = Q[qi + 1]
    if s.still then
        local sh = shape()
        if sh == still.last then still.same = still.same + 1 else still.same, still.last = 0, sh end
        still.waited = still.waited + 1
        if still.same < STILL and still.waited < STILL_MAX then return end
        if still.same < STILL then say("WARN the windows were still moving: captured anyway") end
        still.last, still.same, still.waited = nil, 0, 0
    else
        wait = wait + 1
        if wait < s.n then return end
        wait = 0
    end
    qi = qi + 1
    local ok, e = pcall(s.fn)
    if not ok then fails = fails + 1; say("ERR step " .. qi .. " " .. tostring(e)) end
end
Events.OnTick.Add(onTick)
say("start")
