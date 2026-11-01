-- ZeDUI/tools/qa/zedqa_probe_skills_down.lua  (Nov 1 2026, punch list 42 c.)
-- A probe, not a test: on a short screen (the Steam Deck, 1280x800, Normal and Large text) the pad's
-- walk Down through the Skills tab's training rows stops at a row (Fishing in the Nov 1 runs) while a row
-- below it, partly under the view's bottom edge, is never reached (zedqa_world_pad_take.lua, check 7).
-- Every row registers its stop whether or not it is in view, and the pad's move takes every stop in the
-- column, so the cause is not a missing stop. This prints what the game sees: each Down's landing (id, the
-- stop's rectangle, the view's height, the scroll), then, from the row the walk ended on, every training
-- stop below it with ZeD.SpatialNav.cost's verdict, and the focus manager's dry run of a Down. Both text
-- sizes; the size it started at is put back. One minute. grep "ZEDQA pskd".
local p = getPlayer()
local Focus = ZeD.Input.Focus
local N = ZeD.SpatialNav
local function say(s) print("ZEDQA pskd " .. tostring(s)) end
local function cw() return ZeD_CharacterWindow.getWindow() end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local origSize = ZeD.currentSize
local ZONE = "charTabContent"

local function elements(w)
    for _, z in ipairs(w._focusRing or {}) do
        if z.zone == ZONE and z.focusable then return z.elements or {} end
    end
    return {}
end
local function rectStr(e)
    if not e then return "nil" end
    return string.format("%s x %s y %s w %s h %s", tostring(e.id), tostring(e.x), tostring(e.y), tostring(e.w), tostring(e.h))
end
-- the focused stop in the Skills content, or nil and where the focus went instead (the window, the zone,
-- the stop's id: the Nov 1 print said only "nil", which hid whether the focus left the zone or the window)
local function focused()
    local w = Focus.getFocusedWindow()
    local wn = (w == cw() and "Char") or (w == ZeD_WorldWindow.getWindow() and "World") or tostring(w)
    if w ~= cw() then return nil, "focus in window " .. wn end
    local z = Focus.getFocusedZone(w)
    local e = Focus.getFocusedElement(w)
    if z and z.zone == ZONE then return e, nil end
    return nil, "focus in " .. wn .. " zone " .. tostring(z and z.zone) .. " on " .. tostring(e and e.id)
        .. (e and string.format(" (x %s y %s w %s h %s)", tostring(e.x), tostring(e.y), tostring(e.w), tostring(e.h)) or "")
end
local function viewInfo(w)
    local dp = w._drawerPanel
    local sc = w._skillsScroll
    return string.format("view h %s | scroll %s | one column %s | drawer %s px",
        tostring(dp and dp:getHeight()), tostring(sc and sc.scrollPos and string.format("%.3f", sc.scrollPos)),
        tostring(w._skillsOneCol), tostring(w._drawerEffW and math.floor(w._drawerEffW)))
end
local function stripTab(w, id)
    local strip = w and w._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
    return false
end

-- one pass at the current text size: focus the first training stop, Down until it stays, then look
local presses, lastId, same, firstDown = 0, nil, 0, nil
local function startPass(label)
    local w = cw()
    say("---- " .. label .. ": " .. tostring(ZeD.currentSize) .. " text, screen " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight() .. ", root " .. string.format("%.3f", ZeD.Scale.root()))
    say(viewInfo(w))
    local els = elements(w)
    local n = 0
    for _, e in ipairs(els) do if tostring(e.id):find("^training:") then n = n + 1 end end
    say("training stops in the ring: " .. n .. " of " .. #els .. " stops in " .. ZONE)
    Focus.claimFocus(w)
    local ok = Focus.focusWhere(w, ZONE, function(e) return tostring(e.id):find("^training:col1_") ~= nil end)
    say("focus on the first col1 training stop: " .. tostring(ok) .. " -> " .. rectStr(focused()))
    presses, lastId, same = 0, nil, 0
    local e = focused(); lastId = e and e.id
end
local function pressDown()
    local w = cw()
    Focus.dispatchJoypadDir(w, "down")
    presses = presses + 1
end
local function afterPress()
    local w = cw()
    local e, where = focused()
    local id = e and e.id
    say(string.format("Down %d -> %s | %s", presses, e and rectStr(e) or ("nil: " .. tostring(where)), viewInfo(w)))
    if id == lastId then same = same + 1 else same = 0 end
    lastId = id
    return same >= 2 or presses >= 40
end
local function look(label)
    local w = cw()
    local e = focused()
    say("ended on " .. rectStr(e) .. " | " .. viewInfo(w))
    if not e then return end
    -- every training stop below it, with the pad's own cost for a Down from here
    local els = elements(w)
    local below = 0
    for _, x in ipairs(els) do
        if x ~= e and type(x.y) == "number" and tostring(x.id):find("^training:") and (x.y + (x.h or 0)) > (e.y + (e.h or 0)) then
            below = below + 1
            local tier, cost = N.cost(e, x, "down")
            local overlap = (x.x or 0) < (e.x or 0) + (e.w or 0) and (x.x or 0) + (x.w or 0) > (e.x or 0)
            say(string.format("  below: %s | x-overlap %s | cost tier %s cost %s", rectStr(x), tostring(overlap), tostring(tier), tostring(cost)))
        end
    end
    say("training stops below the last one: " .. below)
    -- the focus manager's own dry run of a Down from here (Focus.previewMove: zone, id, pass; custom
    -- when the stop's own Down handler would take it; err when the move threw)
    if Focus.previewMove then
        local okp, pv = pcall(Focus.previewMove, w, "down")
        if okp and type(pv) == "table" then
            say("dry run of Down: " .. tostring(pv.zone) .. ":" .. tostring(pv.id) .. " (" .. tostring(pv.pass) .. ")" .. (pv.custom and " custom handler" or "") .. (pv.err and " ERR in the move" or ""))
        else
            say("dry run of Down: " .. tostring(pv))
        end
    end
    -- the skills tab's own stamped zones (what the ring is built from)
    local tz = w._trainingGroupZones or {}
    say("stamped training zones this frame: " .. #tz .. " | the first " .. (tz[1] and rectStr(tz[1]) or "nil") .. " | the last " .. (tz[#tz] and rectStr(tz[#tz]) or "nil"))
    pcall(function() getCore():TakeFullScreenshot("zqa_pskd_" .. label .. ".png") end)
end

-- the schedule: open the window on Skills, two passes (Normal text, then Large), put back
at(2, function()
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    -- (a manifest that set Large text before this probe would make both passes Large: pass 1 is Normal)
    if ZeD.currentSize ~= "small" then ZeD.applyTheme(nil, nil, "small"); say("text size -> small for pass 1") end
end)
at(20, function() stripTab(cw(), "skills") end)
local walkFrom = 60
local function schedulePass(t0, label)
    at(t0, function() startPass(label) end)
    -- forty Downs at most, one every 6 ticks, each looked at 3 ticks after the press
    local stopped = false
    for i = 0, 39 do
        at(t0 + 6 + i * 6, function() if not stopped then pressDown() end end)
        at(t0 + 9 + i * 6, function() if not stopped and afterPress() then stopped = true end end)
    end
    at(t0 + 6 + 40 * 6 + 6, function() look(label) end)
    return t0 + 6 + 40 * 6 + 12
end
local t = schedulePass(walkFrom, "pass1")
at(t, function() ZeD.applyTheme(nil, nil, "large"); say("text size -> large") end)
at(t + 30, function() stripTab(cw(), "skills") end)
local t2 = schedulePass(t + 60, "pass2_large")
at(t2, function()
    ZeD.applyTheme(nil, nil, origSize)
    say("text size back to " .. tostring(origSize) .. " | DONE")
end)
local last = t2 + 2

local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do
        if s.n == tick then
            local ok, err = pcall(s.fn)
            if not ok then say("ERR " .. tostring(err)) end
        end
    end
    if tick > last then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
