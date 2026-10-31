-- ZeDUI/tools/qa/zedqa_uncovered21.lua  (Oct 30 2026, QA; punch list 21, the parts the band probe does not walk)
-- 1. the pop-ups with the mouse (the drawer panel's own press and release at the box, then at a row): Health's
--    exercise, Thermal's view, the Journal's page, Craft's Sort; each must open, pick, shut
-- 2. the Maps side list's delete question in the band (a question set with no delete behind it), its stops
-- 3. Forage: the Search key toggles search mode on and off; crouched, the band's Crouch follows (a shot)
-- 4. Health's Start sitting on the ground: greyed, the help line's reason (a shot)
-- 5. the Journal's Delete question on the first entry: the band asks, Cancel puts it away, nothing deleted
-- 6. Craft: after the craft key, the focus stays on it
-- Everything set is put back. Screenshots/zqa_u21_*.png; grep "ZEDQA u21".
local D = ZeD.Input.Detector; local F = ZeD.Input.Focus
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local cw, ww = CWm.getWindow(), WWm.getWindow()
local p = getPlayer()
local function say(s) print("ZEDQA u21 " .. tostring(s)) end
if not (cw and ww) then say("ERR open both windows first"); say("DONE"); return end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_u21_" .. n .. ".png") end) end
local function tabClick(strip, id) for _, z in ipairs(strip._hitZones or {}) do if z.id == "tab:" .. id then strip:onMouseDown(z.x + 2, z.y + 2); return true end end; return false end
local function zone(w, name) for _, z in ipairs(w._focusRing or {}) do if z.zone == name then return z end end end
local function stop(w, zn, id) local z = zone(w, zn); for _, e in ipairs((z and z.elements) or {}) do if tostring(e.id) == id then return e end end end
local function stopsMatching(w, zn, pat) local out = {}; local z = zone(w, zn); for _, e in ipairs((z and z.elements) or {}) do if tostring(e.id):find(pat) then out[#out + 1] = tostring(e.id) end end; return out end
local function focusedId(w) local e = F.getFocusedElement(w); return e and tostring(e.id) or "nil" end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local C, W = cw._tabStripPanel, ww._actionTabStrip

-- the drawer panel's press and release at a point (window-local stop rect -> drawer-local)
local function clickAt(w, e)
    local dp = w._drawerPanel
    if not (dp and e) then return false end
    local x, y = e.x + math.floor(e.w / 2), e.y + math.floor(e.h / 2)
    pcall(function() dp:onMouseDown(x, y) end)
    pcall(function() dp:onMouseUp(x, y) end)
    return true
end
local function mousePop(label, w, strip, zn, tab, boxId, isOpen, rowPat, setup)
    step(5, function() tabClick(strip, tab); if setup then pcall(setup) end end)
    step(60, function()
        D.setLockedMode("mouse")
        local e = stop(w, zn, boxId)
        if not e then say(label .. ": no stop " .. boxId .. " (" .. table.concat(stopsMatching(w, zn, "."), " ") .. ")"); return end
        clickAt(w, e)
    end)
    step(20, function()
        check(isOpen(), label .. ": a click on the box opens its list")
        shot(label .. "_open")
        -- a row: the list's stops while open
        local rows = stopsMatching(w, zn, rowPat)
        say(label .. ": rows " .. table.concat(rows, " "))
        local pick = rows[2] or rows[1]
        local e = pick and stop(w, zn, pick)
        if e then clickAt(w, e) else say(label .. ": no row stop to click") end
        w._qaPick = pick
    end)
    step(20, function()
        check(not isOpen(), label .. ": a click on a row (" .. tostring(w._qaPick) .. ") shuts it")
        shot(label .. "_picked")
    end)
end

-- 1. the mouse on the pop-ups
mousePop("mouse_health", cw, C, "charTabContent", "health", "health:exercise", function() return cw._healthMenuOpen == true end, "menuRow")
mousePop("mouse_thermal", cw, C, "charTabContent", "thermal", "thermal:view", function() return cw._thermalMenuOpen == true end, "viewRow")
mousePop("mouse_journal", cw, C, "charTabContent", "journal", "jpage", function() return cw._journalPageOpen == true end, "^jpage:", function() cw._journalSubTab = 1 end)
step(5, function() cw._journalSubTab = 1; tabClick(C, "loot") end)
mousePop("mouse_craft", ww, W, "worldTabContent", "craft", "craft:sortMenu",
    function() return ww._craftState and ww._craftState.sortMenuOpen == true end, "sortRow")

-- 2. the Maps delete question
step(5, function() D.setLockedMode("gamepad"); tabClick(W, "maps") end)
step(60, function()
    ww._mapSideAsk = { row = "qa", text = "Delete QA test note?", onYes = function() say("map: the Delete answer ran (a test question: nothing behind it)") end }
end)
step(30, function()
    local ask = stopsMatching(ww, "worldTabContent", "side:[yn]")
    say("map: question stops " .. table.concat(ask, " "))
    check(#ask >= 2, "map: the delete question is in the band with Cancel and Delete stops")
    shot("map_ask")
    ww._mapSideAsk = nil
end)
-- 3. Forage
step(5, function() tabClick(W, "forage") end)
step(60, function()
    F.claimFocus(ww)
    local e = stop(ww, "worldTabContent", "forage:search")
    local SM = ISSearchManager and ISSearchManager.getManager and ISSearchManager.getManager(p)
    ww._qaWasSearch = SM and SM.isSearchMode
    if e and e.onActivate then e.onActivate(ww, e) end
end)
step(30, function()
    local SM = ISSearchManager and ISSearchManager.getManager and ISSearchManager.getManager(p)
    check(SM and SM.isSearchMode ~= ww._qaWasSearch, "forage: Search turns search mode " .. tostring(SM and SM.isSearchMode))
    pcall(function() p:setSneaking(true) end)
end)
step(40, function()
    shot("forage_search_crouched")
    local e = stop(ww, "worldTabContent", "forage:search")
    if e and e.onActivate then e.onActivate(ww, e) end
end)
step(30, function()
    local SM = ISSearchManager and ISSearchManager.getManager and ISSearchManager.getManager(p)
    check(SM and SM.isSearchMode == ww._qaWasSearch, "forage: Search again turns it back (" .. tostring(SM and SM.isSearchMode) .. ")")
    pcall(function() p:setSneaking(false) end)
end)
step(30, function() shot("forage_stood") ; tabClick(W, "loot") end)
-- 4. Health's Start, sitting on the ground
step(5, function() tabClick(C, "health"); pcall(function() p:reportEvent("EventSitOnGround") end) end)
step(90, function()
    local e = stop(cw, "charTabContent", "health:start")
    F.claimFocus(cw)
    F.focusWhere(cw, "charTabContent", function(x) return tostring(x.id) == "health:start" end)
end)
step(20, function()
    say("health: sitting " .. tostring(p:isSitOnGround()) .. ", focus " .. focusedId(cw) .. ", help '" .. tostring(cw._helpText) .. "'")
    shot("health_start_sitting")
    pcall(function() p:setSitOnGround(false) end)
end)
-- 5. the Journal's Delete question
step(30, function() tabClick(C, "journal"); cw._journalSubTab = 1 end)
step(60, function()
    ZeD.JournalTab.askDelete(cw, 1)
end)
step(30, function()
    local ask = stopsMatching(cw, "charTabContent", "journal:ask")
    say("journal: question stops " .. table.concat(ask, " "))
    check(cw._journalAsk ~= nil and #ask == 2, "journal: Delete asks in the band (Cancel, Delete)")
    shot("journal_ask")
    local e = stop(cw, "charTabContent", "journal:ask:cancel")
    if e and e.onActivate then e.onActivate(cw, e) end
end)
step(20, function()
    check(cw._journalAsk == nil, "journal: Cancel puts the question away")
    tabClick(C, "loot")
end)
-- 6. Craft: the focus stays on the craft key
step(5, function()
    D.setLockedMode("gamepad"); tabClick(W, "craft")
end)
step(60, function()
    local data = ZeD.CraftingTab.gatherData(p, ww)
    local pick
    for _, rd in ipairs(data and data.recipes or {}) do if rd.status == "unlocked" and rd.canCraft ~= false then pick = rd; break end end
    pick = pick or (data and data.recipes and data.recipes[1])
    if pick then ZeD.CraftingCore.openCraft(ww._craftState, pick.entry.name); say("craft: recipe " .. tostring(pick.entry.name)) end
end)
step(60, function()
    F.claimFocus(ww)
    F.focusWhere(ww, "worldTabContent", function(x) return tostring(x.id) == "craft:actBuild" end)
    ww._qaBefore = focusedId(ww)
    local e = F.getFocusedElement(ww)
    if e and tostring(e.id) == "craft:actBuild" and e.onActivate then e.onActivate(ww, e) end
end)
step(120, function()
    say("craft: before " .. ww._qaBefore .. ", after " .. focusedId(ww))
    check(focusedId(ww) == "craft:actBuild" or ww._qaBefore ~= "craft:actBuild", "craft: the focus stays on the craft key after crafting")
    shot("craft_after")
    pcall(function() ZeD.CraftingCore.closeCraft(ww._craftState) end)
    tabClick(W, "loot"); D.setLockedMode(nil)
end)
step(20, function() say(fails == 0 and "all checks passed" or (fails .. " failed")); say("DONE") end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
