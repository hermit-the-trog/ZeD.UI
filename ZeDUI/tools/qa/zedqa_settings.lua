-- ZeDUI/tools/qa/zedqa_settings.lua  (Oct 19 2026)
-- At the main menu (launch with -MainMenu): Options grouped like a modern game.
-- Lists each group's sections and row counts, what fell under "Other", the
-- rows marked does-nothing / only / ZeD setup, captures four groups, and tries
-- a change + Discard. grep "ZEDQA set". Screenshots zqa_set_*.png.
local MM = ZeD.MainMenu
local function say(s) print("ZEDQA set " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function win() return MM.root and MM.root.optsWin end
local function shot(name) pcall(function() getCore():TakeFullScreenshot("zqa_set_" .. name .. ".png") end) end
local function group(id)
    local w = win()
    for i, p in ipairs(w:pages()) do if p.raw == id then w.pageIdx = i; w.scroll = 0; w.focusId = nil end end
end
at(5, function() MM.openOptions() end)
at(40, function()
    local w = win()
    say("open " .. tostring(w and w:isVisible()) .. " view " .. tostring(MM.view))
    local moot, only, other = {}, {}, {}
    for _, p in ipairs(w:pages()) do
        local secs, n, inOther = {}, 0, false
        for _, r in ipairs(w:rowsFor(p)) do
            if r.kind == "header" then secs[#secs + 1] = r.text; inOther = (r.text == "Other")
            elseif r.kind ~= "note" and r.kind ~= "desc" then
                n = n + 1
                local nm = (r.opt and r.opt.name) or r.label
                if r.moot and not p.setup then moot[#moot + 1] = nm end
                if r.only and not p.setup then only[#only + 1] = nm end
                if inOther then other[#other + 1] = p.raw .. ":" .. tostring(nm) .. "(" .. r.kind .. ")" end
            end
        end
        say(p.title .. ": " .. n .. " rows | " .. table.concat(secs, ", "))
    end
    say("does nothing: " .. table.concat(moot, ", "))
    say("only: " .. table.concat(only, ", "))
    say("other: " .. table.concat(other, ", "))
end)
at(50, function() group("zed") end)
at(70, function() shot("zed") end)
at(80, function() group("interface") end)
at(100, function() shot("interface") end)
at(110, function() group("controls") end)
at(130, function() shot("controls") end)
at(140, function() group("gameplay") end)
at(160, function() shot("gameplay") end)
-- a change, then Discard (the window stays)
at(170, function()
    local w = win(); group("interface")
    for _, r in ipairs(w:rowsFor(w:pages()[w.pageIdx])) do
        if r.opt and r.opt.name == "clock24hour" then w._qaRow = r; w:nudge(r, ((r.control.selected or 1) < #(r.control.options or {})) and 1 or -1) end
    end
    say("after a change: changed " .. tostring(w:anyChanged()) .. " count " .. w:changedCount())
    w:setConfirm("discard")
end)
at(190, function() shot("discard") end)
at(200, function()
    local w = win(); w:discardStay()
    say("after Discard: changed " .. tostring(w:anyChanged()) .. " visible " .. tostring(w:isVisible()))
end)
-- a moot row is inert
at(210, function()
    local w = win(); group("interface")
    for _, r in ipairs(w:rowsFor(w:pages()[w.pageIdx])) do
        if r.opt and r.opt.name == "inventoryFont" then
            local before = r.control.selected
            w:nudge(r, 1); w:activateRow(r)
            say("inventory font inert: " .. tostring(r.control.selected == before) .. " changed " .. tostring(w:anyChanged()))
        end
    end
end)
at(230, function() local w = win(); w:back(); say("closed " .. tostring(not w:isVisible()) .. " view " .. tostring(MM.view) .. " | DONE") end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 235 then Events.OnFETick.Remove(onTick) end
end
Events.OnFETick.Add(onTick)
say("start")
