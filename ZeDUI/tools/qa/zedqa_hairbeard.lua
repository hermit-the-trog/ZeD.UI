-- ZeDUI/tools/qa/zedqa_hairbeard.lua  (Oct 26 2026)
-- Hair and beard in the Identity tab (ZeD_HairBeard.lua, mockup zed_hair_beard_v1),
-- on the ZeD-QA save. Runs with no hair mod (zedqa_run.ps1) and with them on
-- (zedqa_mods_run.ps1 with hairbeard_mods_*.txt): the mod checks run only when that mod is on.
--   1. long hair and a full beard, no tools: rows from the game's own menu, greyed with its reasons
--   2. the mouse: pick a row (the strip says why), hover (the game's hint), the button greyed
--   3. scissors and a cap: the strip names the cap and the tool; Cut runs the game's action;
--      the license follows
--   4. tie and untie by controller (A on the row), the rows follow
--   5. controller: down from the disclosure lands on the switch, right flips to Beard, down
--      walks the rows (the strip follows focus), A on a greyed row does nothing, A trims
--   6. Out of reach folds open; the Identity traits' descriptions on focus and hover
--   7. Large text; the hair mods (Spongie's tag, the Pictures window) when on
-- Captures: Zomboid/Screenshots/zqa_hb_<name>.png. grep "ZEDQA hb".
local TAG = "hb"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); return end
local HB = ZeD.HairBeard
if not HB then say("ERR ZeD.HairBeard is not loaded"); return end
local CW = ZeD_CharacterWindow
local F = ZeD.Input and ZeD.Input.Focus
local core = getCore()
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(name)
    local f = "zqa_hb_" .. name .. ".png"
    local ok, e = pcall(function() core:TakeFullScreenshot(f) end)
    if ok then say("shot " .. f) else fails = fails + 1; say("ERR shot " .. name .. ": " .. tostring(e)) end
end
local function win() return CW.getWindow() end
local function st() local w = win(); return w and w._hb end
local function park() pcall(function() Mouse.setXY(core:getScreenWidth() - 4, core:getScreenHeight() - 4) end) end
local function mods()
    local m = {}
    local list = getActivatedMods()
    for i = 0, list:size() - 1 do m[(tostring(list:get(i)):gsub("^\\", ""))] = true end
    return m
end
local MODS = mods()
local hv = p:getHumanVisual()
local female = p:isFemale()
local orig = { hair = hv:getHairModel(), beard = hv:getBeardModel(), na = hv:getNonAttachedHair() }
local LONG = female and "Long2" or "Fabian"
local size, base, accent = ZeD.currentSize, ZeD.currentBase, ZeD.currentAccent
local given, taken = {}, {}
local function give(ft) local it = p:getInventory():AddItem(ft); if it then given[#given + 1] = it end; return it end
local function refresh() local s = st(); if s then s.tick = 999 end end
local function setLook(hair, beard)
    hv:setNonAttachedHair(nil)
    hv:setHairModel(hair)
    if not female and beard then hv:setBeardModel(beard) end
    p:resetModel()
    refresh()
    local w = win(); if w then w._identityCache = nil end
end
local function rows() local s = st(); return s and s.rows or {} end
local function rowWhere(fn) for _, r in ipairs(rows()) do if fn(r) then return r end end; return nil end
local function zoneOf(key) local s = st(); for _, z in ipairs(s and s.zones or {}) do if z.item.row and z.item.row.key == key then return z end end; return nil end
local function els() local w = win(); return w and ZeD.IdentityTab.focusables(w) or {} end
local function el(id) for _, e in ipairs(els()) do if e.id == id then return e end end; return nil end
local function focusId(id) local w = win(); return F.focusWhere(w, "charTabContent", function(x) return x.id == id end) end
local function focused() local w = win(); local e = F.getFocusedElement(w); return e and e.id end
local function queueLen() local q = ISTimedActionQueue.getTimedActionQueue(p); return q and q.queue and #q.queue or 0 end
-- the tab's scroll so the section shows (its top at the view's top)
local function scrollToHair()
    local w, s = win(), st()
    local sc = w and w._identityScroll
    if not (sc and sc.visible and s and s.top) then return end
    local view = w._identityGridScrollZone
    if not view then return end
    local total = view.h / math.max(0.01, sc.barSizeRatio)
    local maxOff = math.max(1, total - view.h)
    local off = math.floor(sc.scrollPos * maxOff)
    local want = off + (s.top - view.y)
    sc:setScrollPos(math.max(0, math.min(1, want / maxOff)))
end
-- scroll the tab so a row (its stop) shows in the middle of the view
local function showRow(key)
    local w = win()
    local sc, view = w._identityScroll, w._identityGridScrollZone
    local e = el("hb:row:" .. key)
    if not (sc and view and e and sc.visible) then return end
    local total = view.h / math.max(0.01, sc.barSizeRatio)
    local maxOff = math.max(1, total - view.h)
    local off = sc.scrollPos * maxOff
    local want = off + (e.y - view.y) - view.h / 3
    sc:setScrollPos(math.max(0, math.min(1, want / maxOff)))
end
-- the pointer over the drawer: the drawer's own getMouseX/Y answer a test position (Mouse.setXY
-- moved the OS cursor but the game did not see it in the 4K runs); nil puts the real one back
local function pointAt(x, y)
    local dp = win()._drawerPanel
    if x then dp.getMouseX = function() return x end; dp.getMouseY = function() return y end
    else dp.getMouseX = nil; dp.getMouseY = nil end
end
local function absOf(z) local dp = win()._drawerPanel; return dp:getAbsoluteX() + z.x, dp:getAbsoluteY() + z.y end
local function hairWord(n) local k = "IGUI_Hair_" .. tostring(n); local s = getText(k); return s == k and tostring(n) or s end

local Q, qi, wait = {}, 1, nil
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
-- a step that waits: fn returns true when done, false to look again in n frames (up to tries)
local function until_(n, tries, fn, what) Q[#Q + 1] = { n = n, fn = fn, tries = tries, what = what } end

-- 1. the look and no tools
step(30, function()
    park()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CW.isOpen() and ZeD_WorldWindow.isOpen()) then CW.toggleBothPaired(0) end
    local w = win()
    for _, z in ipairs(w._tabStripPanel._hitZones or {}) do
        if z.id == "tab:identity" and w._activeTab ~= "identity" then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end
    end
    local inv = p:getInventory()
    local function tool(it)
        local t = it:getType()
        return it:hasTag(ItemTag.RAZOR) or it:hasTag(ItemTag.SCISSORS) or it:hasTag(ItemTag.DO_HAIRDO)
            or t == "Razor" or t == "Scissors" or t == "Hairgel" or t == "Hairspray2"
    end
    local list = inv:getAllEvalRecurse(tool)
    for i = 0, list:size() - 1 do
        local it = list:get(i)
        local c = it:getContainer()
        if p:getPrimaryHandItem() == it then p:setPrimaryHandItem(nil) end
        if p:getSecondaryHandItem() == it then p:setSecondaryHandItem(nil) end
        if c then c:Remove(it); taken[#taken + 1] = { it = it, c = c } end
    end
    say("tools taken away for the test: " .. #taken .. " | female " .. tostring(female) .. " | was " .. tostring(orig.hair) .. " / " .. tostring(orig.beard))
    setLook(LONG, "Full")
    HB.setPart(w, "hair")
end)
step(60, function()
    local w = win()
    check(w._activeTab == "identity", "the Character window is on Identity")
    local rs = rows()
    check(#rs > 3, "hair rows from the game's menu: " .. #rs)
    local grp = {}
    for _, r in ipairs(rs) do grp[r.grp] = (grp[r.grp] or 0) + 1 end
    say("groups: tie " .. tostring(grp.Tie) .. " shave " .. tostring(grp.Shave) .. " cut " .. tostring(grp.Cut) .. " style " .. tostring(grp.Style))
    check((grp.Tie or 0) > 0 and (grp.Cut or 0) > 0, "Tie and Cut groups")
    local cut = rowWhere(function(r) return r.grp == "Cut" end)
    check(cut and not cut.ok and cut.reason == getText("Tooltip_RequireScissors"), "a cut with no scissors is greyed with the game's reason: " .. tostring(cut and cut.reason))
    local tie = rowWhere(function(r) return r.grp == "Tie" end)
    check(tie and tie.ok, "tying needs no tool")
    local sty = rowWhere(function(r) return r.grp == "Style" end)
    if sty then check(not sty.ok and sty.reason ~= nil, "a style with no gel or spray is greyed: " .. tostring(sty.reason)) end
    local okWord = true
    for _, r in ipairs(rs) do if r.label:sub(1, 7) == "[DEBUG]" then okWord = false end end
    check(okWord, "no debug rows")
    if MODS.SpnHairAPI then say("Out of reach with Spongie's Hairstyle Unlocker on: " .. #(st().out or {}) .. " (every style at or under the length can be picked)")
    else check(#(st().out or {}) > 0, "Out of reach holds what the hair cannot become: " .. #(st().out or {})) end
    scrollToHair()
end)
step(30, function() shot("no_tools") end)

-- 2. the mouse: pick a greyed cut, hover it, the button stays greyed
step(10, function()
    local cut = rowWhere(function(r) return r.grp == "Cut" end)
    if cut then showRow(cut.key) end
end)
step(20, function()
    local w, s = win(), st()
    local cut = rowWhere(function(r) return r.grp == "Cut" end)
    local z = cut and zoneOf(cut.key)
    check(z ~= nil, "the cut row has a click zone")
    if z then
        HB.onClick(w, z.x + 6, z.y + 4)
        check(s.sel == cut.key, "a click picks the row")
        pointAt(z.x + 40, z.y + 6)
    end
end)
step(50, function()
    local s = st()
    check(s.btn and not s.btn.on, "the strip's button is greyed for a greyed row")
    local before = queueLen()
    HB.onClick(win(), s.btn.x + 4, s.btn.y + 4)
    check(queueLen() == before, "pressing the greyed button does nothing")
    check(s.hover ~= nil, "the mouse is over a row (its hint shows)")
    shot("greyed_hover")
    pointAt(nil)
end)

-- 3. scissors and a cap: Cut runs the game's action, the license follows
local target, capGiven
step(10, function()
    park()
    give("Base.Scissors")
    if not p:getClothingItem_Head() then
        local cap = give("Base.Hat_BaseballCap")
        if cap then pcall(function() p:setWornItem(cap:getBodyLocation(), cap) end); capGiven = cap end
    end
    refresh()
end)
step(40, function()
    local s = st()
    local cut = rowWhere(function(r) return r.grp == "Cut" and r.style == (female and "Bob" or "Short") end)
        or rowWhere(function(r) return r.grp == "Cut" end)
    check(cut and cut.ok, "with scissors the cut can be done: " .. tostring(cut and cut.label))
    target = cut and cut.style
    s.sel = cut and cut.key
    say("head item: " .. tostring(p:getClothingItem_Head() and p:getClothingItem_Head():getDisplayName()))
end)
step(30, function()
    shot("ready")
    local s = st()
    check(s.btn and s.btn.on, "the strip's button is live")
    HB.onClick(win(), s.btn.x + 4, s.btn.y + 4)
    check(s.busy ~= nil, "the cut is running")
end)
step(40, function()
    check(ISTimedActionQueue.hasActionType(p, "ISCutHair"), "the game's ISCutHair is queued")
    shot("cutting")
end)
until_(30, 60, function() return st().busy == nil end, "the cut ends")
step(30, function()
    local s = st()
    check(hv:getHairModel() == target, "the hair is now " .. tostring(target) .. ": " .. tostring(hv:getHairModel()))
    check(s.done ~= nil, "the strip says done: " .. tostring(s.done))
    check(p:getClothingItem_Head() == nil, "the cap came off first")
    local w = win()
    check(w._identityCache and w._identityCache.hairStyle == hairWord(target), "the license's Hair style line follows: " .. tostring(w._identityCache and w._identityCache.hairStyle))
    shot("done")
end)

-- 4. tie and untie (A on the row)
step(10, function() setLook(LONG, "Full") end)
local tieKey
step(40, function()
    local tie = rowWhere(function(r) return r.grp == "Tie" end)
    check(tie ~= nil, "a tie row after growing it back")
    tieKey = tie and tie.key
    local w = win()
    pcall(F.claimFocus, w)
end)
step(20, function()
    local e = tieKey and focusId("hb:row:" .. tieKey)
    check(e ~= nil, "the tie row is a controller stop")
    if e then e.onActivate(win(), e) end
end)
until_(30, 40, function() return st().busy == nil and not ISTimedActionQueue.hasActionType(p, "ISCutHair") end, "the tie ends")
step(30, function()
    check(hv:getNonAttachedHair() == LONG, "tied: the loose style is kept (" .. tostring(hv:getNonAttachedHair()) .. ")")
    local rs = rows()
    check(#rs == 1 and rs[1].label == getText("ContextMenu_UntieHair"), "tied: Untie Hair is the only row (" .. #rs .. ")")
    shot("tied")
    local e = rs[1] and focusId("hb:row:" .. rs[1].key)
    if e then e.onActivate(win(), e) end
end)
until_(30, 40, function() return st().busy == nil and not ISTimedActionQueue.hasActionType(p, "ISCutHair") end, "the untie ends")
step(20, function()
    check(hv:getHairModel() == LONG and hv:getNonAttachedHair() == nil, "untied: back to " .. LONG .. " (" .. tostring(hv:getHairModel()) .. ")")
end)

-- 5. the controller path
step(20, function()
    local w = win()
    w._identityScroll:setScrollPos(0)
    check(focusId("identity:__disclosure") ~= nil, "focus on the tab's disclosure")
end)
step(20, function()
    F.dispatchJoypadDir(win(), "down")
    check(focused() == "hb:part", "down from the disclosure lands on the Hair | Beard switch (" .. tostring(focused()) .. ")")
end)
step(20, function()
    if female then say("no beard half for a woman: skipped"); return end
    F.dispatchJoypadDir(win(), "right")
    check(st().part == "beard" and focused() == "hb:part", "right flips to Beard and stays on the switch")
end)
step(30, function()
    if female then return end
    -- no tools: the beard rows are greyed; A does nothing
    for i = #given, 1, -1 do
        local it = given[i]
        if it:getType() == "Scissors" then
            if p:getPrimaryHandItem() == it then p:setPrimaryHandItem(nil) end
            if it:getContainer() then it:getContainer():Remove(it) end
            table.remove(given, i)
        end
    end
    refresh()
end)
step(30, function()
    if female then return end
    F.dispatchJoypadDir(win(), "down")
    local id = focused() or ""
    check(id:sub(1, 7) == "hb:row:", "down walks into the beard rows (" .. id .. ")")
    local s = st()
    check(s.sel ~= nil and ("hb:row:" .. s.sel) == id, "the strip follows focus with no press")
    local r = rowWhere(function(x) return x.key == s.sel end)
    check(r and not r.ok and r.reason == getText("Tooltip_requireRazorOrScissors"), "greyed with the game's reason: " .. tostring(r and r.reason))
    local before = queueLen()
    local e = F.getFocusedElement(win())
    if e then e.onActivate(win(), e) end
    check(queueLen() == before and s.busy == nil, "A on a greyed row does nothing")
    shot("pad_beard_greyed")
end)
step(10, function() if not female then give("Base.Scissors"); refresh() end end)
step(40, function()
    if female then return end
    local r = rowWhere(function(x) return x.style == "Moustache" end) or rowWhere(function(x) return x.grp == "Trim" end)
    check(r and r.ok, "with scissors the trim can be done: " .. tostring(r and r.label))
    target = r and r.style
    local e = r and focusId("hb:row:" .. r.key)
    shot("pad_beard")
    if e then e.onActivate(win(), e) end
end)
until_(30, 60, function() return st().busy == nil and not ISTimedActionQueue.hasActionType(p, "ISTrimBeard") end, "the trim ends")
step(20, function()
    if female then return end
    check(hv:getBeardModel() == target, "the beard is now " .. tostring(target) .. ": " .. tostring(hv:getBeardModel()))
end)

-- 6. Out of reach; the Identity traits
step(20, function()
    local e = focusId("hb:out")
    check(e ~= nil, "Out of reach is a stop")
    if e then e.onActivate(win(), e) end
end)
step(30, function()
    check(st().outOpen == true, "A folds Out of reach open")
    local r = st().out[1]
    local e = r and focusId("hb:row:" .. r.key)
    check(e ~= nil and st().sel == r.key, "an out-of-reach row can be focused and says why")
    shot("out_of_reach")
end)
step(20, function()
    local w = win()
    local e = F.focusWhere(w, "charTabContent", function(x) return x.id and x.id:sub(1, 15) == "identity:trait:" end)
    check(e ~= nil, "a trait is a controller stop: " .. tostring(e and e.id))
end)
step(40, function()
    local w = win()
    check(w._idTraitHint and w._idTraitHint.hintKey == nil, "focus shows the description at once (no hover timer)")
    shot("trait_focus")
    pcall(F.releaseFocus)
end)
step(20, function()
    local w = win()
    local view = w._identityGridScrollZone
    local z
    for _, t in ipairs(w._idTraitZones or {}) do
        if not z and view and t.y >= view.y and t.y + t.h <= view.y + view.h then z = t end
    end
    if z then pointAt(z.x + 30, z.y + 6) end
    check(z ~= nil, "trait zones are kept for hover")
end)
step(50, function()
    local w = win()
    check(w._idTraitHint and w._idTraitHint.hintKey ~= nil, "hover on a trait shows its description")
    shot("trait_hover")
    pointAt(nil)
    park()
end)

-- 7. Large text; the hair mods
step(10, function() setLook(LONG, "Full"); HB.setPart(win(), "hair") end)
step(30, function() scrollToHair(); ZeD.applyTheme(base, accent, "large") end)
step(60, function() scrollToHair() end)
step(30, function() shot("large") end)
step(10, function() ZeD.applyTheme(base, accent, size) end)
step(40, function()
    local s = st()
    if MODS.SpnHairAPI and not (MODS.improvedhairmenubuild42 or MODS.NeatUI_Hairstyler) then
        local tagged = rowWhere(function(r) return r.mod == "SpnHairAPI" end)
        check(tagged ~= nil, "Spongie's Hairstyle Unlocker: its extra rows carry its tag (" .. tostring(tagged and tagged.label) .. ")")
        scrollToHair()
    else
        say("Spongie's Hairstyle Unlocker on: " .. tostring(MODS.SpnHairAPI == true))
    end
    if MODS.improvedhairmenubuild42 or MODS.NeatUI_Hairstyler then
        check(#(s.pics or {}) > 0, "the picture mod's lists are read into rows (" .. #rows() .. " rows)")
        check(el("hb:pics") ~= nil, "Pictures is a controller stop")
        scrollToHair()
    end
    if not mods().traitsAsSkills then check(CW._extTabs.traits == nil, "no Traits tab without Traits As Skills") end
end)
step(30, function() if MODS.SpnHairAPI or MODS.improvedhairmenubuild42 or MODS.NeatUI_Hairstyler then shot("mod_rows") end end)
local picWin
step(10, function()
    if not (MODS.improvedhairmenubuild42 or MODS.NeatUI_Hairstyler) then return end
    local e = el("hb:pics")
    if e then e.onActivate(win(), e) end
end)
step(60, function()
    if not (MODS.improvedhairmenubuild42 or MODS.NeatUI_Hairstyler) then return end
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local t = ui:get(i):getTable()
        if t and t.Type == "HairMenuPanelWindow" and ui:get(i):isVisible() then picWin = t end
    end
    check(picWin ~= nil, "Pictures opens the mod's own window")
    shot("pictures")
end)
step(30, function() if picWin then picWin:close(); check(not picWin:isVisible(), "its window closes") end end)

-- put everything back
step(20, function()
    park()
    pcall(F.releaseFocus)
    pcall(pointAt, nil)
    ZeD.applyTheme(base, accent, size)
    pcall(ZeD.Settings.reapplyFromOptions)
    pcall(ISTimedActionQueue.clear, p)
    for _, it in ipairs(given) do
        if p:getPrimaryHandItem() == it then p:setPrimaryHandItem(nil) end
        if p:getSecondaryHandItem() == it then p:setSecondaryHandItem(nil) end
        if p:isEquipped(it) then pcall(function() p:removeWornItem(it) end) end
        if it:getContainer() then it:getContainer():Remove(it) end
    end
    for _, t in ipairs(taken) do t.c:AddItem(t.it) end
    hv:setHairModel(orig.hair)
    if not female then hv:setBeardModel(orig.beard) end
    hv:setNonAttachedHair(orig.na)
    p:resetModel()
    local w = win(); if w then w._identityCache = nil; w._identityScroll:setScrollPos(0) end
    HB.setPart(w, "hair")
    refresh()
    say("put back: " .. tostring(hv:getHairModel()) .. " / " .. tostring(hv:getBeardModel()) .. ", " .. #taken .. " tools returned")
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

-- a step's n is in 60ths of a second (wall clock; OnRenderTick runs while paused)
local tries = 0
local function tick()
    local s = Q[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    wait = wait or (now + s.n * 1000 / 60)
    if now < wait then return end
    wait = nil
    local ok, res = pcall(s.fn)
    if not ok then
        fails = fails + 1; say("ERR step " .. qi .. ": " .. tostring(res)); qi = qi + 1; tries = 0
    elseif s.tries and res ~= true then
        tries = tries + 1
        if tries >= s.tries then fails = fails + 1; say("FAIL timed out: " .. tostring(s.what)); qi = qi + 1; tries = 0 end
    else
        if s.what then say("PASS " .. s.what) end
        qi = qi + 1; tries = 0
    end
end
Events.OnRenderTick.Add(tick)
say("start")
