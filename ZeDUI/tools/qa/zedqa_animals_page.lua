-- ZeDUI/tools/qa/zedqa_animals_page.lua  (Nov 5 2026, QA; f59ffdc8, the Ranch page scrolls): after zedqa_animals.lua built the
-- pen. The Ranch page's bar, the wheel to the foot (Totals in view, Create zone clear), folding Alerts and Totals until the
-- page fits, a zone opened and back, the wheel on a zone's roster, Butcher and an animal's details, at the run's size and at
-- Large. Pictures zqa_apg_<size>_<page>.png. grep "ZEDQA apg".
local function say(s) print("ZEDQA apg " .. tostring(s)) end
local function check(ok, s) say((ok and "PASS " or "FAIL ") .. s) end
local AT = ZeD.AnimalsTab
local AP = ZeD.AnimalsAlertPoller
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local TAG = "n"
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_apg_" .. getCore():getScreenWidth() .. "_" .. TAG .. "_" .. n .. ".png") end) end
local function W() return WWm.getWindow() end
local function wheel(n, dir) for k = 1, n do AT.onMouseWheel(W(), dir) end end
local function pass(tag)
    add(1200, function()
        TAG = tag
        local w = W()
        AT.switchSubmode(w, "ranch")
        local ov = w._animalsOverviewState
        if ov then ov.alertsExpanded, ov.totalsExpanded = true, true end
    end)
    add(1200, function()
        local w = W()
        local sb = w._animalsScroll
        say(tag .. ": the Ranch bar visible " .. tostring(sb and sb.visible) .. ", share " .. tostring(sb and sb.barSizeRatio) .. ", height " .. tostring(sb and sb.height))
        check(sb and sb.visible and sb.barSizeRatio < 1, tag .. " the page runs over and shows its bar")
        if sb then sb:setScrollPos(0) end
        shot("top")
        if sb then
            local a = sb.scrollPos
            wheel(1, 1)
            local b = sb.scrollPos
            say(string.format("one wheel tick moved %.1f px", (b - a) * sb:scrollRange()))
            check(b > a, tag .. " the wheel moves the Ranch page")
            wheel(300, 1)
            check(sb.scrollPos >= 0.999, tag .. " the wheel reaches the foot")
        end
    end)
    add(1000, function()
        shot("foot")
        local w = W()
        local sum = {}
        for _, z in ipairs(w._animalsSectionZones or {}) do sum[#sum + 1] = tostring(z.key) .. "@" .. tostring(z.y) end
        say(tag .. " sections at the foot: " .. table.concat(sum, ", "))
        local ov = w._animalsOverviewState
        ov.alertsExpanded = false
    end)
    add(1000, function()
        shot("alerts_folded")
        local w = W()
        local sb = w._animalsScroll
        say(tag .. " Alerts folded: bar visible " .. tostring(sb and sb.visible) .. ", share " .. tostring(sb and sb.barSizeRatio))
        w._animalsOverviewState.totalsExpanded = false
    end)
    add(1000, function()
        shot("both_folded")
        local w = W()
        local sb = w._animalsScroll
        check(not (sb and sb.visible), tag .. " both folded the page fits and the bar goes")
        local ov = w._animalsOverviewState
        ov.alertsExpanded, ov.totalsExpanded = true, true
        local zones = AP.getZoneList()
        local name
        pcall(function() name = zones[1]:getName() end)
        ZONE_APG = name
        say(tag .. " opening zone " .. tostring(name))
        AT.navigate(w, "zone", name)
    end)
    add(1200, function()
        shot("zone")
        local w = W()
        local st = AT.getState(w)
        check(st.view == "zone", tag .. " the zone card opens")
        local rs = w._animalsRosterScroll
        say(tag .. " roster needs scroll " .. tostring(rs and rs.needsScroll))
        if rs and rs.needsScroll then
            local zs = AT.getZoneViewState(w)
            local a = zs.scrollY
            wheel(1, 1)
            check(zs.scrollY > a, tag .. " the wheel moves the roster")
        end
        local all = AP.getAllAnimals()
        if all[1] then AT.showAnimal(w, all[1]) end
    end)
    add(1200, function()
        shot("animal")
        local w = W()
        local ds = w._animalsDetailScroll
        say(tag .. " details need scroll " .. tostring(ds and ds.needsScroll))
        AT.navigateBack(w)
    end)
    add(800, function()
        local w = W()
        AT.navigateBack(w)
    end)
    add(1000, function()
        local w = W()
        check(AT.getState(w).view == "overview", tag .. " back returns to the Ranch page")
        AT.switchSubmode(w, "butcher")
    end)
    add(1200, function()
        shot("butcher")
        local w = W()
        local bs = w._animalsButcherScroll
        say(tag .. " Butcher needs scroll " .. tostring(bs and bs.needsScroll))
        if bs and bs.needsScroll then
            local st = AT.getButcherState(w)
            local a = st.scrollY
            wheel(1, 1)
            check(st.scrollY > a, tag .. " the wheel moves Butcher")
        end
        AT.switchSubmode(w, "ranch")
    end)
end
add(300, function()
    AP.refreshCache()
    say("animals " .. #AP.getAllAnimals() .. ", alerts " .. #AP.getAlerts())
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
end)
add(2000, function() local w = W(); w._activeTab = "animals"; w._drawerMode = "tab"; w._drawerOpen = true end)
pass("small")
add(300, function() ZeD.applyTheme(nil, nil, "large") end)
pass("large")
add(300, function() ZeD.applyTheme(nil, nil, "small") end)
add(500, function() CWm.toggleBothPaired(0); say("DONE") end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); if i > #plan then say("DONE") end end
end
Events.OnTick.Add(drive)
