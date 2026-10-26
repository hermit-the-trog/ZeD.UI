-- ZeDUI/tools/qa/zedqa_traits.lua  (Oct 26 2026)
-- The Traits tab for Traits As Skills (ZeD/ModSupport/traitsAsSkills.lua, mockup
-- zed_traits_tab_v1), on the ZeD-QA save with the mod on. Run with traits_manifest.txt
-- through zedqa_mods_run.ps1 -ModList traits_mods.txt -Mode fullscreen4k.
--   1. the tab sits right after Skills; its rows are the mod's ladders; Mind first, Skills last
--   2. the mouse: a row picks its details; hover a step (its trait and level); All | With a
--      trait; a category folds; Find narrows the list
--   3. the controller: into the tab from the strip, Find, the switch (left / right), a
--      category (A folds), rows (the details follow focus), A on a row does nothing
--   4. NEW on a trait gained by levelling (the mod's own XP call), Large text, light theme
-- Captures: Zomboid/Screenshots/zqa_tas_<name>.png. grep "ZEDQA tas".
local TAG = "tas"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); return end
local S = ZeD.ModSupport and ZeD.ModSupport.traitsAsSkills
if not S then say("ERR ZeD's Traits As Skills support is not loaded (is the mod on?)"); return end
local CW = ZeD_CharacterWindow
local F = ZeD.Input and ZeD.Input.Focus
local core = getCore()
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(name)
    local f = "zqa_tas_" .. name .. ".png"
    local ok, e = pcall(function() core:TakeFullScreenshot(f) end)
    if ok then say("shot " .. f) else fails = fails + 1; say("ERR shot " .. name .. ": " .. tostring(e)) end
end
local function win() return CW.getWindow() end
local function st() local w = win(); return w and w._tas end
local function park() pcall(function() Mouse.setXY(core:getScreenWidth() - 4, core:getScreenHeight() - 4) end) end
local function absOf(x, y) local dp = win()._drawerPanel; return dp:getAbsoluteX() + x, dp:getAbsoluteY() + y end
local function els() return S.buildFocusables(win()) end
local function focusId(id) return F.focusWhere(win(), "charTabContent", function(x) return x.id == id end) end
local function focused() local e = F.getFocusedElement(win()); return e and e.id end
local function items(kind) local out = {}; for _, it in ipairs(st().L.items) do if it.kind == kind then out[#out + 1] = it end end; return out end
local function zoneRow(id) for _, z in ipairs(st().zones or {}) do if z.item.row and z.item.row.id == id then return z end end; return nil end
local function anyRow() for _, z in ipairs(st().zones or {}) do if z.item.kind == "row" and z.h >= z.item.h then return z end end; return nil end
-- the drawer answers a test pointer (Mouse.setXY did not reach the game in the 4K runs); nil = the real one
local function pointAt(x, y)
    local dp = win()._drawerPanel
    if x then dp.getMouseX = function() return x end; dp.getMouseY = function() return y end
    else dp.getMouseX = nil; dp.getMouseY = nil end
end
local size, base, accent = ZeD.currentSize, ZeD.currentBase, ZeD.currentAccent
local savedState

local Q, qi, wait = {}, 1, nil
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

-- 1. the tab
step(30, function()
    park()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CW.isOpen() and ZeD_WorldWindow.isOpen()) then CW.toggleBothPaired(0) end
    local order = {}
    for _, t in ipairs(CW.TABS) do order[#order + 1] = t.id end
    local s = table.concat(order, ",")
    say("tabs: " .. s)
    check(s:find("skills,traits", 1, true) ~= nil, "the Traits tab sits right after Skills")
    local w = win()
    local found = false
    for _, z in ipairs(w._tabStripPanel._hitZones or {}) do
        if z.id == "tab:traits" then found = true; w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end
    end
    check(found, "the Traits tab is on the strip")
    check(ZeD.TabPx and ZeD.TabPx.has("traits"), "it has the lit pixel-art icon")
end)
step(60, function()
    local w = win()
    check(w._activeTab == "traits", "the Character window is on Traits")
    local s = st()
    local n = 0
    for _ in pairs(TAS.Spectrum.registry) do n = n + 1 end
    check(s and #s.rows == n, "one row per ladder in the mod's registry: " .. tostring(s and #s.rows) .. " / " .. n)
    local cats = items("cat")
    local names = {}
    for _, c in ipairs(cats) do names[#names + 1] = c.cat end
    say("categories: " .. table.concat(names, ","))
    check(cats[1] and cats[1].cat == "inteligencia", "Mind first")
    check(cats[#cats] and cats[#cats].cat == "skills", "Skills last")
    local withT = 0
    for _, r in ipairs(s.rows) do if #r.now > 0 then withT = withT + 1 end end
    say("ladders with a trait now: " .. withT)
    check(st().field ~= nil and st().field:isVisible(), "the Find box shows in the heading")
end)
step(30, function() shot("tab") end)

-- 2. the mouse
step(10, function()
    local s = st()
    local z = zoneRow("TAS.Reading") or anyRow()
    check(z ~= nil, "a row has a click zone")
    if z then S.onClick(win(), z.x + 30, z.y + 4) end
end)
step(30, function()
    check(st().sel ~= nil, "a click picks the row for the details: " .. tostring(st().sel))
    shot("details")
    -- hover the third step of the first row in view
    local z = zoneRow(st().sel)
    local stp = z and z.item.steps and z.item.steps[3]
    if stp then pointAt(stp.x + 2, stp.y + 3) end
end)
step(30, function()
    check(st().stepHover ~= nil, "hovering a step names its trait and level")
    shot("step_hover")
    pointAt(nil)
    park()
end)
step(10, function()
    local o = st().only and st().only[2]
    if o then S.onClick(win(), o.x + 4, o.y + 4) end
end)
step(30, function()
    check(S.only == true, "With a trait")
    local okAll = true
    for _, it in ipairs(items("row")) do if #it.row.now == 0 then okAll = false end end
    check(okAll, "only ladders that give a trait are listed")
    shot("with_trait")
    local o = st().only[1]
    S.onClick(win(), o.x + 4, o.y + 4)
end)
step(20, function()
    check(S.only == false, "All again")
    local c = items("cat")[1]
    for _, z in ipairs(st().zones) do if z.item == c then S.onClick(win(), z.x + 4, z.y + 4) end end
end)
step(30, function()
    local c = items("cat")[1]
    check(c and c.shut == true, "a click folds the category")
    shot("folded")
    for _, z in ipairs(st().zones) do if z.item.kind == "cat" and z.item.cat == c.cat then S.onClick(win(), z.x + 4, z.y + 4) end end
end)
step(20, function()
    local f = st().field
    if f and f.input then f.input:setText("read") end
end)
step(30, function()
    check(S.find == "read", "Find takes the typed text: " .. tostring(S.find))
    local rs = items("row")
    local ok = #rs > 0
    for _, it in ipairs(rs) do
        local hit = it.row.name:lower():find("read", 1, true) ~= nil
        for _, b in ipairs(it.row.bands) do
            local list = type(b.trait) == "table" and b.trait or { b.trait }
            for _, t in ipairs(list) do
                local tt = t and TAS.Trait.get(t)
                local d = tt and CharacterTraitDefinition.getCharacterTraitDefinition(tt)
                if d and d:getLabel():lower():find("read", 1, true) then hit = true end
            end
        end
        if not hit then ok = false end
    end
    check(ok, "Find narrows the list (" .. #rs .. " rows)")
    shot("find")
    st().field:clear()
    S.find = ""
end)

-- 3. the controller
step(20, function()
    local w = win()
    pcall(F.claimFocus, w)
    local e = F.focusWhere(w, "charTabBar", function(x) return x.id == "tab:traits" end)
    check(e ~= nil, "focus on the Traits tab in the strip")
end)
step(20, function()
    F.dispatchJoypadDir(win(), "right")
    local id = focused() or ""
    say("into the tab from the strip: " .. id)
    check(id:sub(1, 4) == "tas:", "the D-pad goes into the tab")
    local e = focusId("tas:find")
    check(e ~= nil, "Find is a stop")
end)
step(20, function()
    F.dispatchJoypadDir(win(), "down")
    check(focused() == "tas:only", "down from Find: All | With a trait (" .. tostring(focused()) .. ")")
    F.dispatchJoypadDir(win(), "right")
    check(S.only == true and focused() == "tas:only", "right picks With a trait")
    F.dispatchJoypadDir(win(), "left")
    check(S.only == false, "left picks All")
end)
step(20, function()
    F.dispatchJoypadDir(win(), "down")
    local id = focused() or ""
    check(id:sub(1, 8) == "tas:cat:", "down: the first category (" .. id .. ")")
    local e = F.getFocusedElement(win())
    if e then e.onActivate(win(), e) end
end)
step(20, function()
    local c = items("cat")[1]
    check(c.shut == true, "A folds the category")
    local e = F.getFocusedElement(win())
    if e then e.onActivate(win(), e) end
end)
step(20, function()
    F.dispatchJoypadDir(win(), "down")
    local id = focused() or ""
    check(id:sub(1, 8) == "tas:row:", "down: a row (" .. id .. ")")
    check(("tas:row:" .. tostring(st().sel)) == id, "the details follow focus with no press")
    F.dispatchJoypadDir(win(), "down")
    F.dispatchJoypadDir(win(), "down")
end)
step(30, function()
    local id = focused() or ""
    check(("tas:row:" .. tostring(st().sel)) == id, "walking rows moves the details: " .. id)
    local before = st().sel
    local e = F.getFocusedElement(win())
    if e then e.onActivate(win(), e) end
    check(st().sel == before, "A on a row does nothing")
    shot("pad_row")
end)
step(10, function() pcall(F.releaseFocus) end)

-- 4. NEW, Large text, light theme
local gained
step(10, function()
    -- the mod's own XP call (single player): enough Reading XP to reach the next range
    local Sys = TASSpectrumSystem
    local s = st()
    local r = s.byId["TAS.Reading"]
    if Sys and r and not isClient() then
        savedState = { level = r.level }
        local md = p:getModData()
        md.ZeD_TASSeen = md.ZeD_TASSeen or {}
        -- forget Fast Reader as seen, so a gained or held Fast Reader counts as new on the next visit
        md.ZeD_TASSeen.FAST_READER = nil
        gained = "FAST_READER"
        local ok, e = pcall(Sys.addXP, p, "TAS.Reading", 40000, "active_gain")
        say("addXP Reading: " .. tostring(ok) .. " " .. tostring(e))
    end
    -- leave the tab and come back (a new visit)
    local w = win()
    for _, z in ipairs(w._tabStripPanel._hitZones or {}) do if z.id == "tab:skills" then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end end
end)
step(30, function()
    local w = win()
    for _, z in ipairs(w._tabStripPanel._hitZones or {}) do if z.id == "tab:traits" then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end end
end)
step(60, function()
    local s = st()
    local r = s.byId["TAS.Reading"]
    say("Reading now level " .. tostring(r and r.level) .. ", traits " .. tostring(r and table.concat(r.now, ",")))
    if gained then check(s.newSet and s.newSet[gained] == true, "a trait gained since the last visit carries NEW") end
    s.sel = "TAS.Reading"
    shot("new")
end)
step(10, function() ZeD.applyTheme(base, accent, "large") end)
step(60, function() shot("large") end)
step(10, function() ZeD.applyTheme("light", accent, size) end)
step(60, function() shot("light") end)

step(10, function()
    park()
    pcall(pointAt, nil)
    ZeD.applyTheme(base, accent, size)
    pcall(ZeD.Settings.reapplyFromOptions)
    S.only, S.find, S.closed = false, "", {}
    local w = win()
    for _, z in ipairs(w._tabStripPanel._hitZones or {}) do if z.id == "tab:identity" then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end end
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local function tick()
    local s = Q[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    wait = wait or (now + s.n * 1000 / 60)
    if now < wait then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then fails = fails + 1; say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
