-- ZeDUI/tools/qa/ad_split.lua  (Nov 23 2026, QA; tag ad_split): the Loadouts split in the running game. Since 1.0
-- Loadouts, outfits and Restock are the add-on ZeD-GUI: Loadouts (mod id ZeDLoadouts, folder mods\ZeD-Loadouts,
-- require=\ZeD_UI), which talks to ZeD only through the plug-in points (docs/ADDON_API.md, ZeD.API). Built on
-- rt_kit.lua (the global RT), run after zedqa_prelude.lua. grep "ZEDQA ad_split". No pictures.
-- The script reads which run it is in: ZeDLoadouts loaded (getActivatedMods() holds it, or its global has made its
-- options) is the "with" run, else the "alone" run. Manifests: ad_split_alone.txt and ad_split_with.txt (each names
-- the mod list it needs). On a build with no ZeD.API (Loadouts built in, before the split) it is one SKIP.
-- Checks, ZeD alone (ZeD_UI only):
--   * none of Loadouts' code is in ZeD: no ZeD.Lists, ListsUI, Restock, EquipLoadout, JournalLists, RestockPin, no
--     ZeDLoadouts global, no ModOptions "ZeDLoadouts"; every plug-in point idle: nothing in the Equip tab's sections,
--     the doll's overlays, the Journal's pages, the Character wheel's slices, the item card's marks, sections and
--     gens, ZeD setup's spliced rows and preset joins, the warmed add-on icons;
--   * invisible: the Equip tab draws no section (height 0, no takeover, no fold zone); the Journal has no page past
--     ZeD's four and openPage("loadouts") is refused; the Character wheel has no Loadouts slice; the item card (a
--     hammer's, opened by a click on its row) has no Lists mark and no toggle_lists stop, and no In lists section
--     is registered; the hammer's right-click menu has no Save to loadout or Save to outfit; ZeD setup's page has
--     no Loadouts or Restock row;
--   * no Lua error while it runs (the game's error count, before and after).
-- Checks, ZeD plus the add-on (ZeD_UI and ZeDLoadouts), with the add-on's Loadouts switch turned On for the run:
--   * each plug-in point holds the add-on's entry (section, overlay, page, slice, mark, card section, ZeD setup rows);
--   * the Equip tab's Loadouts fold draws and a press on its heading opens it (taller after);
--   * the Journal's Loadouts page opens by id and draws (its state made);
--   * the Character wheel has the Loadouts slice, before the belt;
--   * the hammer's card draws its Lists mark (its rect and its toggle_lists stop), the mark pressed opens the Lists
--     pop-up, and with the hammer on a loadout made for the run the mark lights;
--   * the hammer's right-click menu has Save to loadout with its list under it;
--   * ZeD setup's page shows the Loadouts and Restock rows (the add-on's options);
--   * no Lua error while it runs.
-- In Lite the item card has no marks strip and ZeD setup leaves the Additions group out: those parts SKIP.
-- Puts back: the add-on's Loadouts switch, the loadout made for the run (deleted), the fold as found, the Journal page
-- and the Character tab as found, the pop-up and the menus closed, the pause screen shut, the hammer taken back.

if not (RT and RT.make) then
    print("ZEDQA ad_split ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA ad_split VERDICT FAIL 1")
    print("ZEDQA ad_split DONE")
    return
end

local Q = RT.make("ad_split")
Q.maxMs = 600000
local S = { p = RT.p, pn = RT.pn }
local H = {}
local MM = ZeD.MainMenu
local St = ZeD.Settings

-- ===================================================================== helpers
function H.tr(key) local s = key; pcall(function() s = ZeD.tr(key) end); return tostring(s) end
function H.nm(it) if it == nil then return "nil" end; local n = nil; pcall(function() n = it:getDisplayName() end); return tostring(n or it) end
function H.errs() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function H.lite() local on = false; pcall(function() on = St ~= nil and St.lite ~= nil and St.lite() and true or false end); return on end
function H.modOn(id)
    local on = false
    pcall(function()
        local l = getActivatedMods()
        for i = 0, l:size() - 1 do
            local s = tostring(l:get(i))
            if s == id or s == "\\" .. id then on = true end
        end
    end)
    return on
end
function H.loOpts() local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeDLoadouts") end); return zo end
-- a registry's entries (ZeD.API.registry's shape: { list, byId }), {} when there is none
function H.list(reg) return (type(reg) == "table" and type(reg.list) == "table") and reg.list or {} end
function H.has(reg, id) return type(reg) == "table" and type(reg.byId) == "table" and reg.byId[id] ~= nil end
function H.ids(reg) local t = {}; for _, d in ipairs(H.list(reg)) do t[#t + 1] = tostring(d.id) end; return table.concat(t, ",") end
function H.slices() local D = ZeD.DpadWheels; return D and D._slices and D._slices.character or nil end
function H.overlays() local D = ZeD.EquipDoll; return D and D._overlays or nil end
-- the add-on's rows spliced into ZeD setup's groups, and its preset joins (by owner)
function H.rowAddsOf(owner)
    local n = 0
    for _, a in ipairs((ZeD.Options and ZeD.Options.rowAdds) or {}) do if a.owner == owner then n = n + #(a.rows or {}) end end
    return n
end
function H.joinsOf(owner)
    local n = 0
    for _, j in ipairs((ZeD.Options and ZeD.Options.presetJoins) or {}) do if j.owner == owner then n = n + 1 end end
    return n
end
-- the Character wheel's slices as its own builder makes them (no pad needed to read them)
function H.wheel()
    local es = {}
    pcall(function() es = ZeD.DpadWheels.B.character(S.p, S.pn) or {} end)
    return es
end
function H.loSlice(es)
    local nm = H.tr("UI_ZeD_Wheel_Loadouts")
    for i, e in ipairs(es) do
        if e.icon == "loadout" or e.name == nm or e.name == "UI_ZeD_Wheel_Loadouts" then return i, e end
    end
    return nil
end

-- the Character window's list and the hammer's row in it (rt_cards.lua's way: the row's hit zone, a press the list's
-- own handlers take)
function H.content() local w = RT.cw(); return w and w._mainContent end
function H.rowZone(item)
    local c = H.content()
    for _, z in ipairs((c and c._hitZones) or {}) do if z.id == item then return z end end
    return nil
end
function H.clickPoint(c, z, item)
    if not (c and z and c.hitZoneAt) then return nil end
    local x = z.x + math.floor(z.w / 2)
    for _, f in ipairs({ 0.5, 0.3, 0.7, 0.15, 0.85 }) do
        local y = z.y + math.floor(z.h * f)
        local hz = c:hitZoneAt(x, y)
        if hz ~= nil and hz.id == item then return x, y end
    end
    return nil
end
function H.seekRow(item)
    local c = H.content()
    if not c then return false end
    local z0 = H.rowZone(item)
    if z0 and H.clickPoint(c, z0, item) ~= nil then return true end
    local sc = c._scroll
    if sc and sc.setScrollPos then
        S.seekPos = (S.seekPos or -0.1) + 0.1
        if S.seekPos > 1.001 then S.seekPos = 0 end
        sc:setScrollPos(S.seekPos)
    end
    return false
end
function H.click(item)
    local c = H.content()
    local z = H.rowZone(item)
    if not (c and z) then return false end
    local x, y = H.clickPoint(c, z, item)
    if not x then return false end
    c._zedLastClick = nil   -- (never a double-click: that would be the quick use)
    c:onMouseDown(x, y)
    c:onMouseUp(x, y)
    return true
end
function H.card() local w = RT.cw(); return w and w._itemCard end
function H.cardOn(item)
    local w = RT.cw()
    local c = w and w._itemCard
    return item ~= nil and w ~= nil and w._drawerItem == item and c ~= nil and c.item == item
end
-- the card's Lists mark's rect (the plug-in points keep it in card._markRects.lists), nil when none is drawn
function H.listsRect(c)
    local mr = c and c._markRects
    if type(mr) == "table" then return mr.lists end
    return nil
end
function H.hasStop(c, id)
    local els = {}
    if c and c.getActionStripElements then pcall(function() els = c:getActionStripElements() or {} end) end
    for _, e in ipairs(els) do if e.id == id then return true end end
    return false
end
-- the hammer's right-click menu (the game's createMenu, as a right-click on its row builds it): the names of its rows
-- and the Save to loadout row, then the menu shut
function H.menuRows(item)
    local names, saveRow = {}, nil
    local ctx = nil
    pcall(function() ctx = ISInventoryPaneContextMenu.createMenu(S.pn, true, { item }, 40, 40) end)
    local want = { [H.tr("UI_ZeD_Lists_SaveToLoadout")] = true, UI_ZeD_Lists_SaveToLoadout = true, ["Save to loadout"] = true }
    for _, o in ipairs((ctx and ctx.options) or {}) do
        names[#names + 1] = tostring(o.name)
        if want[tostring(o.name)] then saveRow = o end
    end
    H.menuShut(ctx)
    return names, saveRow
end
function H.menuShut(ctx)
    pcall(function() local v = getPlayerContextMenu(S.pn); local m = v and v._zedMenu; if m and m.close then m:close() end end)
    if ctx then pcall(function() ctx:setVisible(false) end) end
end
function H.isSaveTo(name)
    for _, k in ipairs({ "UI_ZeD_Lists_SaveToLoadout", "UI_ZeD_Lists_SaveToOutfit" }) do
        if name == k or name == H.tr(k) then return true end
    end
    return name == "Save to loadout" or name == "Save to outfit"
end
-- the pause screen and ZeD setup (rt_system.lua's way: the pause menu, Options, its setup page)
function H.menuUp()
    local up = false
    pcall(function() up = MainScreen.instance ~= nil and MainScreen.instance:isVisible() end)
    return up
end
function H.toggleMenu() pcall(function() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end) end
function H.setupRows()
    local w = MM and MM.pauseOpts
    local rows = {}
    if w then pcall(function() rows = w:zedSetupRows() or {} end) end
    return rows
end
-- the add-on's option's row on ZeD setup (its control is the option's own element), else nil
function H.loRow(rows, id)
    local lo = H.loOpts()
    local o = lo and lo.dict and lo.dict[id]
    local el = o and o.element
    for _, r in ipairs(rows) do
        if (el ~= nil and r.control == el) or (r.zedOwner == "ZeDLoadouts" and r.labelKey == ("UI_ZeD_Settings_" .. ((id == "loadouts") and "Loadouts" or "Restock"))) then return r end
    end
    return nil
end

-- ===================================================================== which run
S.api = ZeD.API ~= nil and (ZeD.API.VERSION or 0) >= 1
S.builtIn = (St ~= nil and St.loadoutsOption ~= nil)
S.with = H.modOn("ZeDLoadouts") or (type(ZeDLoadouts) == "table" and ZeDLoadouts.opts ~= nil)
S.err0 = H.errs()
if not S.api or S.builtIn then
    Q.skip("the Loadouts split: ZeD alone and ZeD with ZeD-GUI: Loadouts", "this build has Loadouts built in"
        .. (S.api and " (ZeD.Settings.loadoutsOption is ZeD's own)" or " (no ZeD.API)"))
    Q.start()
    return
end
Q.say("NOTE mode: " .. (S.with and "ZeD plus ZeD-GUI: Loadouts (the with run)" or "ZeD alone (the alone run)")
    .. "; Lua errors so far " .. tostring(S.err0) .. "; Lite " .. tostring(H.lite()))

-- ===================================================================== setup
Q.step(5, function()
    RT.pairOpen()
    local w = RT.cw()
    S.tabWas = w and w._activeTab
    S.subWas = w and w._journalSubTab
    S.hammer = RT.give("Base.Hammer")
    if S.with then
        local LO = ZeDLoadouts
        local o = LO and LO.loadoutsOption
        if o then S.loWas = o:getValue(); if S.loWas ~= 2 then pcall(function() o:setValue(2) end) end end
        -- (the fold as found, kept; shut for the run, so the heading's press (its zone stamped as drawn) opens it)
        local EL = ZeD.EquipLoadout
        if EL and EL.openFor then S.foldWas = EL.openFor[S.pn]; EL.openFor[S.pn] = nil end
    end
    Q.check(S.hammer ~= nil, "setup: a hammer given to the character for the card and the menu", H.nm(S.hammer))
end)

-- ===================================================================== 1. the code and the plug-in points
Q.step(3, function()
    local E, J, C = ZeD.EquipmentTab, ZeD.JournalTab, ZeD.ItemCard
    local secs, pages = E and E._sections, J and J._pages
    local marks, csecs, gens = C and C._marks, C and C._sections, C and C._gens
    local warm = (ZeD.PxIcon and ZeD.PxIcon._warmAdded) or {}
    if not S.with then
        local mods = {}
        for _, k in ipairs({ "Lists", "ListsUI", "Restock", "EquipLoadout", "JournalLists", "RestockPin" }) do
            if ZeD[k] ~= nil then mods[#mods + 1] = "ZeD." .. k end
        end
        if ZeDLoadouts ~= nil then mods[#mods + 1] = "ZeDLoadouts" end
        if ZeD_RestockPin ~= nil then mods[#mods + 1] = "ZeD_RestockPin" end
        if H.loOpts() ~= nil then mods[#mods + 1] = "ModOptions ZeDLoadouts" end
        Q.check(#mods == 0, "alone: none of Loadouts' code is in ZeD (no ZeD.Lists, ListsUI, Restock, EquipLoadout, JournalLists, RestockPin, no ZeDLoadouts options)",
            (#mods == 0) and "none" or table.concat(mods, " "))
        local busy = {}
        local function idle(label, reg) if #H.list(reg) > 0 then busy[#busy + 1] = label .. " " .. H.ids(reg) end end
        idle("Equip sections", secs); idle("doll overlays", H.overlays()); idle("Journal pages", pages)
        idle("wheel slices", H.slices()); idle("card marks", marks); idle("card sections", csecs); idle("card gens", gens)
        local adds, joins = #((ZeD.Options and ZeD.Options.rowAdds) or {}), #((ZeD.Options and ZeD.Options.presetJoins) or {})
        if adds > 0 then busy[#busy + 1] = "setup row adds " .. adds end
        if joins > 0 then busy[#busy + 1] = "preset joins " .. joins end
        if #warm > 0 then busy[#busy + 1] = "warmed icons " .. table.concat(warm, ",") end
        Q.check(#busy == 0, "alone: every plug-in point is idle (no section, overlay, page, slice, mark, card section, gen, setup row, preset join or warmed icon)",
            (#busy == 0) and "all empty" or table.concat(busy, "; "))
        return
    end
    local miss = {}
    local function need(label, ok) if not ok then miss[#miss + 1] = label end end
    need("Equip section loadouts", H.has(secs, "loadouts")); need("doll overlay loadouts", H.has(H.overlays(), "loadouts"))
    need("Journal page loadouts", H.has(pages, "loadouts")); need("wheel slice loadouts", H.has(H.slices(), "loadouts"))
    need("card mark lists", H.has(marks, "lists")); need("card section lists", H.has(csecs, "lists"))
    need("setup rows (2)", H.rowAddsOf("ZeDLoadouts") == 2); need("preset joins (2)", H.joinsOf("ZeDLoadouts") == 2)
    need("the Loadouts switch", ZeDLoadouts ~= nil and ZeDLoadouts.loadoutsOption ~= nil)
    Q.check(#miss == 0, "with: each plug-in point holds the add-on's entry (Equip section, doll overlay, Journal page, wheel slice, card mark and section, two setup rows and preset joins)",
        (#miss == 0) and ("sections " .. H.ids(secs) .. ", pages " .. H.ids(pages) .. ", slices " .. H.ids(H.slices()) .. ", marks " .. H.ids(marks))
        or ("missing: " .. table.concat(miss, ", ")))
    local o = (type(ZeDLoadouts) == "table") and ZeDLoadouts.loadoutsOption or nil
    local on = false
    if ZeD.Lists and ZeD.Lists.on then pcall(function() on = ZeD.Lists.on() and true or false end) end
    Q.check(on, "with: the add-on's Loadouts switch is On for the run", tostring(o and o:getValue()))
end)

-- ===================================================================== 2. the item card (a click on the hammer's row)
Q.step(3, function() RT.charTab("loot"); S.seekPos = nil end)
Q.waitFor(2, 240, function() return H.seekRow(S.hammer) end, function(ok)
    Q.check(ok, "card: the hammer's row is in the Character window's list", H.nm(S.hammer))
    if ok then H.click(S.hammer) end
end)
-- (the card drawn a few frames, so its marks' rects are stamped)
Q.waitFor(4, 240, function()
    local c = H.card()
    if not H.cardOn(S.hammer) then return false end
    if not S.with or H.lite() then return (c.verbRects ~= nil) end
    return H.listsRect(c) ~= nil
end, function(ok)
    local c = H.card()
    local on = H.cardOn(S.hammer)
    local marks = nil
    pcall(function() marks = ZeD.ItemCard.readMarks(S.hammer, S.pn) end)
    if not S.with then
        Q.check(on and H.listsRect(c) == nil and not H.hasStop(c, "toggle_lists") and marks ~= nil and marks.lists == nil,
            "alone: the hammer's card has no Lists mark (no rect, no toggle_lists stop, no lists in its marks)",
            "card " .. tostring(on) .. ", rect " .. tostring(H.listsRect(c) ~= nil) .. ", marks.lists " .. tostring(marks and marks.lists))
        local C = ZeD.ItemCard
        Q.check(C ~= nil and #H.list(C._sections) == 0, "alone: the card has no In lists section (no body section registered)", H.ids(C and C._sections))
        return
    end
    if H.lite() then
        Q.skip("with: the hammer's card draws its Lists mark", "Lite: the item card has no marks strip")
        return
    end
    S.markOk = ok and on
    Q.check(ok and on and H.hasStop(c, "toggle_lists"), "with: the hammer's card draws its Lists mark, a pad stop (toggle_lists)",
        "card " .. tostring(on) .. ", rect " .. tostring(H.listsRect(c) ~= nil) .. ", marks.lists " .. tostring(marks and marks.lists))
    if S.markOk then pcall(function() ZeD.ItemCard.activateMark(c, "lists", false) end) end
end)
Q.waitFor(2, 120, function()
    if not S.markOk then return true end
    local LU = ZeD.ListsUI
    local m = LU and LU.popup
    return m ~= nil and m._ctx ~= nil and m._ctx.open == true
end, function(ok)
    if not S.markOk then return end
    local LU = ZeD.ListsUI
    local m = LU and LU.popup
    Q.check(ok, "with: the Lists mark pressed opens the Lists pop-up", tostring(m and m.headText))
    if m then pcall(function() m:close() end) end
    -- the hammer on a loadout made for the run: the mark lights ("in 1 loadout") and the In lists section has it
    local L = ZeD.Lists
    pcall(function() S.list = L.createWith(S.p, "loadout", "zedqa split", S.hammer) end)
end)
Q.waitFor(4, 120, function()
    if not (S.markOk and S.list) then return true end
    local marks = nil
    pcall(function() marks = ZeD.ItemCard.readMarks(S.hammer, S.pn) end)
    return marks ~= nil and marks.lists == true
end, function(ok)
    if not S.markOk then return end
    local marks = nil
    pcall(function() marks = ZeD.ItemCard.readMarks(S.hammer, S.pn) end)
    Q.check(ok and S.list ~= nil, "with: the hammer on a loadout lights its Lists mark",
        "list " .. tostring(S.list and S.list.id) .. ", marks.lists " .. tostring(marks and marks.lists) .. " " .. tostring(marks and marks.listsText))
end)

-- ===================================================================== 3. the right-click menu
Q.step(3, function()
    local names, save = H.menuRows(S.hammer)
    if not S.with then
        local bad = {}
        for _, n in ipairs(names) do if H.isSaveTo(n) then bad[#bad + 1] = n end end
        Q.check(#names > 0 and #bad == 0, "alone: the hammer's right-click menu has no Save to loadout or Save to outfit",
            #names .. " rows" .. ((#bad > 0) and (", found: " .. table.concat(bad, ", ")) or ""))
        return
    end
    Q.check(save ~= nil and save.subOption ~= nil, "with: the hammer's right-click menu has Save to loadout, its lists under it",
        #names .. " rows: " .. table.concat(names, ", "))
end)

-- ===================================================================== 4. the Equip tab's Loadouts fold
Q.step(3, function() RT.charTab("equip") end)
Q.waitFor(6, 240, function()
    local w = RT.cw()
    if not (w and w._activeTab == "equip") then return false end
    if not S.with then return true end
    for _, z in ipairs(w._elZones or {}) do if z.id == "fold" then return true end end
    return false
end, function(ok)
    local w = RT.cw()
    local E = ZeD.EquipmentTab
    local dw = 400
    if w and w._drawerPanel then pcall(function() dw = w._drawerPanel:getWidth() end) end
    local h = 0
    if w and E and E.extH then pcall(function() h = E.extH(w, dw) end) end
    if not S.with then
        local tk = nil
        if w and E and E.extTakeover then pcall(function() tk = E.extTakeover(w) end) end
        Q.check(ok and w ~= nil and h == 0 and tk == nil and w._el == nil and w._elZones == nil,
            "alone: the Equip tab draws no Loadouts fold (sections' height 0, no takeover, no fold state or zones)",
            "tab " .. tostring(w and w._activeTab) .. ", height " .. tostring(h) .. ", takeover " .. tostring(tk ~= nil))
        return
    end
    local fold = nil
    for _, z in ipairs((w and w._elZones) or {}) do if z.id == "fold" then fold = z end end
    S.foldH0 = h
    if not Q.check(ok and fold ~= nil and h > 0, "with: the Equip tab draws the Loadouts fold (its heading)", "height " .. tostring(h)) then return end
    -- (shut since the setup) a press on its heading as the drawer takes it
    local taken = false
    pcall(function() taken = E.extClick(w, fold.x + math.floor(fold.w / 2), fold.y + math.floor(fold.h / 2)) and true or false end)
    if not taken then
        Q.say("NOTE the fold's heading took no press at its middle (scrolled out of view?): its own press run instead")
        pcall(fold.fn)
    end
    S.foldDw = dw
end)
Q.waitFor(3, 120, function()
    if not S.with then return true end
    local EL = ZeD.EquipLoadout
    return EL ~= nil and EL.openFor ~= nil and EL.openFor[S.pn] == true
end, function(ok)
    if not S.with or S.foldH0 == nil then return end
    local h = 0
    pcall(function() h = ZeD.EquipmentTab.extH(RT.cw(), S.foldDw or 400) end)
    Q.check(ok and h > S.foldH0, "with: a press on the fold's heading opens it (the Equip tab's section grows)",
        "height " .. tostring(S.foldH0) .. " -> " .. tostring(h))
end)

-- ===================================================================== 5. the Journal's Loadouts page
Q.step(3, function() RT.charTab("journal") end)
Q.waitFor(4, 240, function() local w = RT.cw(); return w ~= nil and w._activeTab == "journal" end, function(ok)
    local w = RT.cw()
    local J = ZeD.JournalTab
    local idx = J and J.pageIndex and J.pageIndex("loadouts")
    S.jIdx = idx
    if not S.with then
        local opened = true
        if w and J and J.openPage then pcall(function() opened = J.openPage(w, "loadouts") and true or false end) end
        local extra = J and J.pageDef and J.pageDef(5)
        Q.check(ok and w ~= nil and idx == nil and not opened and extra == nil and w._jl == nil,
            "alone: the Journal has no Loadouts page (no page past ZeD's four, openPage refused)",
            "tab " .. tostring(w and w._activeTab) .. ", index " .. tostring(idx) .. ", opened " .. tostring(opened))
        return
    end
    local opened = false
    if w and J and J.openPage then pcall(function() opened = J.openPage(w, "loadouts") and true or false end) end
    S.jOpened = opened
    Q.check(ok and idx ~= nil and opened, "with: the Journal's Loadouts page opens by id (ZeD.JournalTab.openPage)", "index " .. tostring(idx))
end)
Q.waitFor(4, 120, function()
    if not (S.with and S.jOpened) then return true end
    local w = RT.cw()
    return w ~= nil and w._journalSubTab == S.jIdx and w._jl ~= nil
end, function(ok)
    if not (S.with and S.jOpened) then return end
    local w = RT.cw()
    Q.check(ok, "with: the Loadouts page draws (the page shown, its own state made)", "page " .. tostring(w and w._journalSubTab) .. " of " .. tostring(S.jIdx))
end)

-- ===================================================================== 6. the Character wheel
Q.step(3, function()
    local es = H.wheel()
    local i, e = H.loSlice(es)
    local last = es[#es]
    if not S.with then
        Q.check(#es > 0 and i == nil, "alone: the Character wheel has no Loadouts slice", #es .. " slices, the last " .. tostring(last and last.name))
        return
    end
    Q.check(i ~= nil and e.sub ~= nil and last ~= nil and last.key == "belt" and i < #es,
        "with: the Character wheel has the Loadouts slice (its ring), before the belt",
        #es .. " slices, Loadouts at " .. tostring(i) .. ", the last " .. tostring(last and last.name))
end)

-- ===================================================================== 7. ZeD setup's rows
Q.step(5, function()
    S.menuWas = H.menuUp()
    if not S.menuWas then H.toggleMenu() end
end)
Q.waitFor(10, 400, function() return H.menuUp() and MM ~= nil and MM.pauseOpts ~= nil end, function(ok)
    S.optsOk = ok
    if ok then pcall(MM.openOptions) end
end)
Q.waitFor(5, 300, function() return not S.optsOk or (MM.pauseOpts ~= nil and MM.pauseOpts:isVisible()) end, function(ok)
    if not (S.optsOk and ok) then Q.check(false, "ZeD setup opens from the pause screen (Options)"); return end
    local w = MM.pauseOpts
    S.pageWas = w.pageIdx
    pcall(function() for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end end)
    local rows = H.setupRows()
    if not S.with then
        local bad = {}
        for _, r in ipairs(rows) do
            local k = tostring(r.labelKey or "")
            if r.zedOwner == "ZeDLoadouts" or k == "UI_ZeD_Settings_Loadouts" or k == "UI_ZeD_Settings_Restock" then bad[#bad + 1] = k end
        end
        Q.check(#rows > 0 and #bad == 0 and H.loOpts() == nil, "alone: ZeD setup has no Loadouts or Restock row",
            #rows .. " rows" .. ((#bad > 0) and (", found: " .. table.concat(bad, ", ")) or ""))
        return
    end
    local rL, rR = H.loRow(rows, "loadouts"), H.loRow(rows, "restock")
    if not (rL or rR) and H.lite() then
        Q.skip("with: ZeD setup shows the Loadouts and Restock rows", "Lite leaves the Additions group out of ZeD setup")
        return
    end
    Q.check(rL ~= nil and rR ~= nil, "with: ZeD setup shows the Loadouts and Restock rows (the add-on's options, Loadouts On)",
        "Loadouts " .. tostring(rL ~= nil) .. ", Restock " .. tostring(rR ~= nil) .. " of " .. #rows .. " rows")
end)
Q.step(5, function()
    local w = MM and MM.pauseOpts
    if w and w:isVisible() then
        if S.pageWas then w.pageIdx = S.pageWas end
        pcall(function() w:discardStay() end)
        pcall(function() w:back() end)
    end
end)
Q.step(10, function() if not S.menuWas and H.menuUp() then H.toggleMenu() end end)
Q.waitFor(5, 300, function() return S.menuWas or not H.menuUp() end, function(ok)
    Q.check(ok, "the pause screen shuts again")
end)

-- ===================================================================== 8. no Lua error
Q.step(3, function()
    local n = H.errs()
    Q.check(n == nil or S.err0 == nil or n == S.err0, (S.with and "with" or "alone") .. ": no Lua error while the script ran",
        "errors " .. tostring(S.err0) .. " -> " .. tostring(n))
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    H.menuShut(nil)
    pcall(function() local LU = ZeD.ListsUI; local m = LU and LU.popup; if m and m._ctx and m._ctx.open then m:close() end end)
    if S.list then pcall(function() ZeD.Lists.delete(S.p, S.list.id) end) end
    S.list = nil
    if S.with then
        pcall(function() ZeD.EquipLoadout.openFor[S.pn] = S.foldWas end)
        local LO = ZeDLoadouts
        local o = LO and LO.loadoutsOption
        if o and S.loWas and o:getValue() ~= S.loWas then pcall(function() o:setValue(S.loWas) end) end
    end
    local w = RT.cw()
    if w and S.subWas and ZeD.JournalTab and ZeD.JournalTab.setPage then pcall(ZeD.JournalTab.setPage, w, S.subWas) end
    if S.tabWas then RT.charTab(S.tabWas) end
end)
Q.step(5, function()
    local LO = ZeDLoadouts
    local o = LO and LO.loadoutsOption
    local back = (not S.with) or o == nil or S.loWas == nil or o:getValue() == S.loWas
    local w = RT.cw()
    Q.check(back and not H.menuUp() and (S.tabWas == nil or (w ~= nil and w._activeTab == S.tabWas)),
        "put back: the Loadouts switch, the pause screen shut, the Character tab as found",
        "switch " .. tostring(o and o:getValue()) .. " (was " .. tostring(S.loWas) .. "), tab " .. tostring(w and w._activeTab) .. " (was " .. tostring(S.tabWas) .. ")")
end)
Q.start()
