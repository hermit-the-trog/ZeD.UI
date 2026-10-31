-- ZeDUI/tools/qa/zedqa_bands_probe.lua  (Oct 30 2026, QA; punch list 21)
-- The one header strip and footer band on every tab, with the controller (simulated, as suite_gamepad):
-- for each tab of both windows (Craft also with a recipe open, Journal on each page), a full screenshot
-- (zqa_band_<win>_<tab>.png), the tab's stops in the order the focus manager holds them, and the card's
-- width against the half / full card. Every pop-up box found among the stops (Sort, Show, View, Page,
-- Exercise ...) is opened with A (its list must open: a shot), Down then A picks the next row; the list
-- must shut and the focus come back to the box. Puts the tabs, the pick and the input mode back.
-- grep "ZEDQA band".
local D = ZeD.Input.Detector; local F = ZeD.Input.Focus
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local cw, ww = CWm.getWindow(), WWm.getWindow()
local function say(s) print("ZEDQA band " .. tostring(s)) end
if not (cw and ww) then say("ERR open both windows first"); say("DONE"); return end
if getGameSpeed() == 0 then pcall(setGameSpeed, 1) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_band_" .. n .. ".png") end) end
local function tabClick(strip, id) for _, z in ipairs(strip._hitZones or {}) do if z.id == "tab:" .. id then strip:onMouseDown(z.x + 2, z.y + 2); return true end end; return false end
local function zone(w, name) for _, z in ipairs(w._focusRing or {}) do if z.zone == name then return z end end end
local POPS = { "sortMenu", "showMenu", "health:exercise", "thermal:view", "jpage", "Menu$", ":pop", "Pick$" }
local function isPop(id)
    id = tostring(id)
    for _, p in ipairs(POPS) do if id:find(p) then return true end end
    return false
end
local function anyOpen(w)
    local open = {}
    for _, k in ipairs({ "_healthMenuOpen", "_thermalMenuOpen", "_journalPageOpen" }) do if w[k] then open[#open + 1] = k end end
    for _, sk in ipairs({ "_craftState", "_buildState", "_jrecipeState" }) do
        local s = w[sk]
        if s then for _, k in ipairs({ "sortMenuOpen", "showMenuOpen" }) do if s[k] then open[#open + 1] = sk .. "." .. k end end end
    end
    return #open > 0, table.concat(open, ",")
end
local function focusedId(w) local e = F.getFocusedElement(w); return e and tostring(e.id) or "nil" end

local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local half, full

-- one tab: census, width, shot, then every pop-up through the pad
local function tabPass(label, w, strip, zoneName, tab, setup)
    step(5, function() tabClick(strip, tab); if setup then pcall(setup) end end)
    step(70, function()
        D.setLockedMode("gamepad")
        F.claimFocus(w)
        local z = zone(w, zoneName)
        local ids = {}
        for _, e in ipairs((z and z.elements) or {}) do ids[#ids + 1] = tostring(e.id) end
        local dw = math.floor(w._drawerEffW or 0)
        say(string.format("%s: card %d px (half %d, full %d), %d stops: %s", label, dw, half, full, #ids, table.concat(ids, " ")))
        check(dw == 0 or math.abs(dw - half) <= 1 or math.abs(dw - full) <= 1, label .. ": the card is the half or the full card (" .. dw .. ")")
        shot(label)
        -- the pop-ups among the stops, run one after the other below
        w._qaPops = {}
        for _, e in ipairs((z and z.elements) or {}) do if isPop(e.id) then w._qaPops[#w._qaPops + 1] = e end end
        say(label .. ": pop-ups " .. #w._qaPops)
    end)
    for i = 1, 3 do
        step(5, function()
            local e = w._qaPops and w._qaPops[i]
            if not e then return end
            w._qaBox = tostring(e.id)
            F.focusWhere(w, zoneName, function(x) return x == e or tostring(x.id) == w._qaBox end)
            say(label .. ": on " .. focusedId(w) .. ", A (the element's onActivate, what a released A fires)")
            local fe = F.getFocusedElement(w) or e
            if fe.onActivate then fe.onActivate(w, fe) end
        end)
        step(2, function()
            if not (w._qaPops and w._qaPops[i]) then return end
            local open, which = anyOpen(w)
            say(label .. ": 2 frames after A on " .. w._qaBox .. ": open " .. tostring(open) .. " (" .. which .. "), last draw " ..
                tostring(w._healthLastDraw and (getTimestampMs() - w._healthLastDraw)) .. " ms ago")
        end)
        step(28, function()
            if not (w._qaPops and w._qaPops[i]) then return end
            local open, which = anyOpen(w)
            check(open, label .. ": A on " .. w._qaBox .. " opens its list (" .. which .. ")")
            shot(label .. "_pop" .. i)
            say(label .. ": focus in the list on " .. focusedId(w))
            F.dispatchJoypadDir(w, "down")
        end)
        step(10, function()
            if not (w._qaPops and w._qaPops[i]) then return end
            local fe = F.getFocusedElement(w)
            say(label .. ": picking " .. tostring(fe and fe.id))
            if fe and fe.onActivate then fe.onActivate(w, fe) end
        end)
        step(30, function()
            if not (w._qaPops and w._qaPops[i]) then return end
            local open = anyOpen(w)
            check(not open, label .. ": a pick shuts " .. w._qaBox .. "'s list")
            check(focusedId(w) == w._qaBox, label .. ": the focus is back on " .. w._qaBox .. " (on " .. focusedId(w) .. ")")
        end)
    end
end

step(5, function()
    half, full = ZeD.T.px(220), ZeD.T.px(480)
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
end)
local C, W = cw._tabStripPanel, ww._actionTabStrip
for _, t in ipairs({ "equip", "health", "thermal", "identity", "skills" }) do tabPass("c_" .. t, cw, C, "charTabContent", t) end
for i, pg in ipairs({ "journal", "notebooks", "papers", "recipes", "loadouts" }) do
    tabPass("c_journal_" .. pg, cw, C, "charTabContent", "journal", function() cw._journalSubTab = i end)
end
step(5, function() cw._journalSubTab = 1; tabClick(C, "loot") end)
for _, t in ipairs({ "craft", "build", "maps", "forage", "furniture" }) do tabPass("w_" .. t, ww, W, "worldTabContent", t) end
-- Craft with a recipe open
tabPass("w_craft_recipe", ww, W, "worldTabContent", "craft", function()
    local st = ww._craftState
    local data = ZeD.CraftingTab.gatherData(getPlayer(), ww)
    local pick
    for _, rd in ipairs(data and data.recipes or {}) do if rd.status == "unlocked" then pick = rd; break end end
    pick = pick or (data and data.recipes and data.recipes[1])
    if pick then ZeD.CraftingCore.openCraft(st, pick.entry.name) end
end)
step(5, function() pcall(function() ZeD.CraftingCore.closeCraft(ww._craftState) end) end)
-- Furniture's sub-tabs: their stops
step(5, function() tabClick(W, "furniture") end)
step(60, function()
    local z = zone(ww, "worldTabContent")
    local subs = {}
    for _, e in ipairs((z and z.elements) or {}) do local id = tostring(e.id); if id:find("sub") or id:find("mode") then subs[#subs + 1] = id end end
    say("furniture sub-tab stops: " .. #subs .. " (" .. table.concat(subs, " ") .. ")")
end)
step(5, function() tabClick(W, "loot"); D.setLockedMode(nil) end)
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
