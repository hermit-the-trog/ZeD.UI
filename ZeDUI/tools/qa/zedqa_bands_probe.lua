-- ZeDUI/tools/qa/zedqa_bands_probe.lua  (Oct 30 2026, QA; punch list 21)
-- The one header strip and footer band on every tab, with the controller (simulated, as suite_gamepad):
-- for each tab of both windows (Craft also with a recipe open, Journal on each page), a full screenshot
-- (zqa_band_<win>_<tab>.png), the tab's stops in the order the focus manager holds them, and the card's
-- width against the half / full card. Every pop-up box found among the stops (Sort, Show, View, Page,
-- Exercise ...) is opened with A (its list must open: a shot), Down then A picks the next row; the list
-- must shut and the focus come back to the box. Puts the tabs, the pick and the input mode back.
-- (Oct 30 2026, punch list 21 a-f) and for each open list: it opens on the row chosen now (the
-- builder's _focusIdx), its rows alone are the stops (marked _menuRows), it outlives a full
-- screenshot (a 4K one is a hitch of more than 300 ms), Up and Down past both ends stay in it on
-- the end rows with it open (the Journal's Page list on Loadouts too), Left / Right do nothing,
-- B shuts it unchanged with the focus back on its box. The map's pop-out is not a list: skipped.
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
local POPS = { "sortMenu", "showMenu", "health:exercise", "thermal:view", "^jpage$", "Menu$", "style:menu", ":pop", "Pick$" }
local function isPop(id)
    id = tostring(id)
    if id:find("popout") or id:find("Popout") then return false end   -- (the map's pop-out window, not a list)
    for _, p in ipairs(POPS) do if id:find(p) then return true end end
    return false
end
local function anyOpen(w)
    local open = {}
    for _, k in ipairs({ "_healthMenuOpen", "_thermalMenuOpen", "_journalPageOpen", "_mapStyleMenuOpen" }) do if w[k] then open[#open + 1] = k end end
    -- a page's own lists (Papers' Show, Loadouts' filter) and any zone holding open-list rows
    for _, z in ipairs(w._focusRing or {}) do
        if z.elements and z.elements._menuRows then open[#open + 1] = tostring(z.zone) .. "._menuRows" end
    end
    for _, sk in ipairs({ "_craftState", "_buildState", "_jrecipeState" }) do
        local s = w[sk]
        if s then for _, k in ipairs({ "sortMenuOpen", "showMenuOpen" }) do if s[k] then open[#open + 1] = sk .. "." .. k end end end
    end
    return #open > 0, table.concat(open, ",")
end
local function focusedId(w) local e = F.getFocusedElement(w); return e and tostring(e.id) or "nil" end
-- the open list's zone (its elements marked _menuRows) and its rows top to bottom (by place)
local function listZone(w)
    for _, z in ipairs(w._focusRing or {}) do if z.elements and z.elements._menuRows then return z end end
end
local function rowsByY(z)
    local list = {}
    for _, e in ipairs(z and z.elements or {}) do list[#list + 1] = e end
    table.sort(list, function(a, b) return a.y < b.y end)
    return list
end
local function press(w, dir, n) for _ = 1, n do F.dispatchJoypadDir(w, dir) end end

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
        step(30, function()
            if not (w._qaPops and w._qaPops[i]) then return end
            local open, which = anyOpen(w)
            check(open, label .. ": A on " .. w._qaBox .. " opens its list (" .. which .. ")")
            local z = listZone(w)
            check(z ~= nil and F.getFocusedZone(w) == z, label .. ": the open list's rows hold the focus (" .. focusedId(w) .. ")")
            if z and z.elements._focusIdx then
                check(z.focusedElementIdx == z.elements._focusIdx, label .. ": the list opens on the row chosen now (" .. focusedId(w) .. ")")
            end
            say(label .. ": focus in the list on " .. focusedId(w))
            shot(label .. "_pop" .. i)
        end)
        step(5, function()
            if not (w._qaPops and w._qaPops[i]) then return end
            local z = listZone(w)
            check(z ~= nil, label .. ": " .. w._qaBox .. "'s list outlives the screenshot")
            if not z then return end
            local rows = rowsByY(z)
            local n = #rows + 2
            press(w, "up", n)
            check(listZone(w) == z and focusedId(w) == tostring(rows[1].id), label .. ": Up past the first row stays on it, the list open (" .. focusedId(w) .. ")")
            press(w, "down", n)
            check(listZone(w) == z and focusedId(w) == tostring(rows[#rows].id), label .. ": Down past the last row stays on it, the list open (" .. focusedId(w) .. ")")
            local r = F.previewMove(w, "down")
            check(r and r.zone == nil, label .. ": nothing below the last row (preview " .. tostring(r and r.id) .. ")")
            local before = focusedId(w)
            press(w, "left", 1); press(w, "right", 1)
            check(focusedId(w) == before and listZone(w) == z, label .. ": Left / Right do nothing in the list")
            -- B: the focused row's onCancel (what B fires)
            local fe = F.getFocusedElement(w)
            if fe and fe.onCancel then fe.onCancel(w, fe) end
        end)
        step(30, function()
            if not (w._qaPops and w._qaPops[i]) then return end
            local open, which = anyOpen(w)
            check(not open, label .. ": B shuts " .. w._qaBox .. "'s list (" .. which .. ")")
            check(focusedId(w) == w._qaBox, label .. ": after B the focus is back on " .. w._qaBox .. " (on " .. focusedId(w) .. ")")
            -- open it again for the pick
            local fe = F.getFocusedElement(w)
            if fe and fe.onActivate and tostring(fe.id) == w._qaBox then fe.onActivate(w, fe) end
        end)
        step(30, function()
            if not (w._qaPops and w._qaPops[i]) then return end
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
    -- (Oct 30 2026, punch list 21 f) the game's own Character Info panel stays hidden under ZeD's windows
    local v = getPlayerInfoPanel(0)
    check(not (v and v:getIsVisible()), "the game's Character Info panel is hidden at "
        .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight())
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
step(20, function()
    local v = getPlayerInfoPanel(0)
    check(not (v and v:getIsVisible()), "the game's Character Info panel is still hidden at the end of the run")
    say(fails == 0 and "all checks passed" or (fails .. " failed")); say("DONE")
end)

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
