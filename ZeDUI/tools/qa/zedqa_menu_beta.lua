-- ZeDUI/tools/qa/zedqa_menu_beta.lua  (Nov 2 2026, QA; punch list 65, 58 and 59 at the main menu, beta build 8e12102)
-- At the main menu, 4K (zedqa_menu_mods_run.ps1 with only ZeD on).
--   65: the ZeD menu's About lists a "ZeD-GUI" row (MM.zedVersion, read from ZeD's mod.info) above Game; a picture.
--   58: ZeD setup's UI scale slider: A on Auto goes to 0.75x (not stuck on Auto, not 0.5x); Left from 0.75x goes back to
--       Auto, Right from Auto lands on 0.75x; with 0.5 saved the row reads "0.5x (... here)" (a picture); put back.
--   59: dimmed rows: the pointer held over a game setting that does nothing with ZeD (r.moot) gets no hover wash
--       (MM.rowLook's hot argument false) and the help line still explains (the picture); the same for a row that waits
--       on another switch where one is found; neither is a controller stop (not in the window's focus specs).
-- grep "ZEDQA mbt"; shots mbt_*.png. Everything is put back.
local MM = ZeD and ZeD.MainMenu
local function say(s) print("ZEDQA mbt " .. tostring(s)) end
if not (MM and MM.openOptions and MM.zedVersion) then say("ERR ZeD's main menu (or its version row) is not loaded"); say("DONE"); return end
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("mbt_" .. n .. ".png") end); say("shot mbt_" .. n) end
local function O() return MM.root and MM.root.optsWin end
local steps, T0, t = {}, 0, 0
local function at(n, fn) T0 = T0 + n; steps[#steps + 1] = { n = T0, fn = fn } end
local function park() pcall(function() Mouse.setXY(getCore():getScreenWidth() - 4, getCore():getScreenHeight() - 4) end) end
local function label(c, i) local o = c.options and c.options[i]; return tostring(type(o) == "table" and (o.text or o[1]) or o) end

-- the pointer, as the options window reads it (getMouseX / getMouseY are globals there)
local realMX, realMY = getMouseX, getMouseY
local function pointAt(x, y) getMouseX = function() return x end; getMouseY = function() return y end end
local function pointBack() getMouseX, getMouseY = realMX, realMY end
-- the row wash: every call's y and hot argument, for the frame being looked at
local looks = {}
local realRowLook = MM.rowLook
MM.rowLook = function(p, x, y, w, h, selected, hot, focused, win)
    looks[#looks + 1] = { y = y, h = h, hot = hot, p = p }
    return realRowLook(p, x, y, w, h, selected, hot, focused, win)
end

-- a row of the current page: its place in the list (the drawn heights), as N.find in gallery_nov1_menu.lua
local function place(w, want)
    local rows = w:rowsFor(w:pages()[w.pageIdx])
    local y = 0
    for i, r in ipairs(rows) do
        if want(r) then return { r = r, i = i, y = y, h = r._h or ZeD.T.px(30) } end
        y = y + (r._h or ZeD.T.px(30))
    end
    return nil
end
local function show(w, f)
    local vh = (w._list and w._list.h) or 0
    w.scroll = math.max(0, f.y - math.floor((vh - f.h) / 2))
end
local function goPage(w, test)
    for i, pg in ipairs(w:pages()) do
        if test(pg, i) then w.pageIdx = i; w.scroll = 0; w.focusId = nil; w._cellRow = nil; return i end
    end
    return nil
end
-- the pointer on a row's middle, in screen pixels
local function rowPoint(w, f)
    local L = w._list
    return w:getAbsoluteX() + L.x + math.floor(L.w / 3), w:getAbsoluteY() + L.y - w.scroll + f.y + math.floor(f.h / 2)
end
local function isSpec(w, r) for _, s in ipairs(w._specs or {}) do if s.rowRef == r then return true end end; return false end

-- ---- 65: About
at(2, function()
    park()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    local mi = getModInfoByID("ZeD_UI")
    local mv = mi and mi:getModVersion()
    say("65: MM.zedVersion " .. tostring(MM.zedVersion()) .. " | mod.info modversion " .. tostring(mv) .. " | game " .. tostring(MM.version()))
    check(MM.zedVersion() == tostring(mv) and MM.zedVersion() ~= "?", "65: ZeD's version comes from its mod.info (" .. tostring(MM.zedVersion()) .. ")")
    MM.ctx.open = "zed"
end)
at(40, function() shot("about"); MM.ctx.open = nil end)

-- ---- 58: the scale slider on ZeD setup
local sc
at(10, function() MM.openOptions() end)
at(30, function()
    local w = O()
    if not w then say("ERR no Options window"); return end
    goPage(w, function(pg) return pg.setup end)
    sc = place(w, function(r) return r.labelKey == "UI_ZeD_Settings_UiScale" end)
    if not check(sc ~= nil, "58: ZeD setup has the UI scale row") then return end
    show(w, sc)
    local c = sc.r.control
    sc.was = c.selected
    local names = {}
    for i = 1, #(c.options or {}) do names[#names + 1] = i .. "=" .. label(c, i) end
    say("58: scale steps " .. table.concat(names, ", ") .. " | saved " .. tostring(sc.was))
    -- to Auto by Left presses
    for _ = 1, 10 do w:nudge(sc.r, -1) end
    check(c.selected == 1, "58: Left presses reach Auto (" .. tostring(c.selected) .. ")")
end)
at(20, function()
    local w = O(); if not (w and sc) then return end
    local c = sc.r.control
    w:activateRow(sc.r)
    check(c.selected ~= 1 and label(c, c.selected) == "0.75x", "58: A on Auto steps to 0.75x (" .. label(c, c.selected) .. ")")
end)
at(20, function()
    local w = O(); if not (w and sc) then return end
    local c = sc.r.control
    w:nudge(sc.r, -1)
    check(c.selected == 1, "58: Left from 0.75x goes back to Auto, past 0.5x (" .. label(c, c.selected) .. ")")
    w:nudge(sc.r, 1)
    check(label(c, c.selected) == "0.75x", "58: Right from Auto lands on 0.75x (" .. label(c, c.selected) .. ")")
end)
-- a saved 0.5: the option set to it, as an old save would hold it
at(20, function()
    local w = O(); if not (w and sc) then return end
    local c = sc.r.control
    local half
    for i = 1, #(c.options or {}) do if label(c, i) == "0.5x" then half = i end end
    if not check(half ~= nil, "58: the 0.5x step is still in the list (saves keep their place)") then return end
    sc.half = half
    ZeD.Settings.uiScaleOption:setValue(half); ZeD.Settings.applyScale(half)
    c.selected = half
    show(w, sc)
end)
at(60, function()
    local w = O(); if not (w and sc) then return end
    w._cellRow = sc.r
    say("58: saved 0.5: draws at " .. tostring(ZeD.Scale.computeGame()) .. " (the game), root " .. tostring(ZeD.Scale.root and ZeD.Scale.root()))
    check(math.abs(ZeD.Scale.computeGame() - 0.75) < 0.01, "58: a saved 0.5 draws at 0.75 in game")
end)
at(20, function() shot("scale_05_saved") end)
at(10, function()
    local w = O(); if not (w and sc) then return end
    local c = sc.r.control
    ZeD.Settings.uiScaleOption:setValue(sc.was); ZeD.Settings.applyScale(sc.was)
    c.selected = sc.was
    w._cellRow = nil
end)
at(60, function() say("58: put back to " .. tostring(ZeD.Settings.uiScaleOption:getValue())) end)

-- ---- 59: dimmed rows
local dims = {}
at(10, function()
    local w = O(); if not w then return end
    -- the first game setting that does nothing with ZeD (moot), on any page, and the first row that waits on a switch
    for i, pg in ipairs(w:pages()) do
        local y = 0
        for ri, r in ipairs(w:rowsFor(pg)) do
            if r.moot and not dims.moot then dims.moot = { page = i, r = r, i = ri, y = y, h = r._h or ZeD.T.px(30) } end
            y = y + (r._h or ZeD.T.px(30))
        end
    end
    say("59: a do-nothing game setting: " .. tostring(dims.moot and (dims.moot.r.labelKey or dims.moot.r.label or dims.moot.r.text)) .. " on page " .. tostring(dims.moot and dims.moot.page))
    if dims.moot then w.pageIdx = dims.moot.page; w.focusId = nil; w._cellRow = nil end
end)
at(20, function()
    local w = O(); if not (w and dims.moot) then return end
    local f = place(w, function(r) return r == dims.moot.r end)
    if not f then say("ERR the do-nothing row is not on its page"); return end
    dims.moot.f = f
    show(w, f)
end)
at(10, function()
    local w = O(); if not (w and dims.moot and dims.moot.f) then return end
    local x, y = rowPoint(w, dims.moot.f)
    pointAt(x, y)
    looks = {}
end)
at(3, function()
    local w = O(); if not (w and dims.moot and dims.moot.f) then return end
    local ry = w:getAbsoluteY() + w._list.y - w.scroll + dims.moot.f.y
    local hotOnIt, seen = false, false
    for _, l in ipairs(looks) do
        if l.p == w and math.abs((w:getAbsoluteY() + l.y) - ry) < 2 then seen = true; if l.hot then hotOnIt = true end end
    end
    say("59: row washes this frame " .. #looks .. " | the do-nothing row drawn " .. tostring(seen) .. " | hot " .. tostring(hotOnIt))
    check(seen and not hotOnIt, "59: the pointer over a do-nothing game setting gives it no hover wash")
    check(not isSpec(w, dims.moot.r), "59: the do-nothing game setting is not a controller stop")
end)
at(10, function() shot("dim_moot_hover") end)
at(5, function()
    pointBack(); park()
    -- a live row on the same page, for contrast: the wash shows under the pointer
    local w = O(); if not w then return end
    local f = place(w, function(r) return r.kind ~= "header" and r.kind ~= "note" and r.kind ~= "desc" and not r.moot and isSpec(w, r) end)
    if not f then say("NOTE no live row on that page to compare"); return end
    show(w, f)
    dims.live = f
end)
at(10, function()
    local w = O(); if not (w and dims.live) then return end
    local x, y = rowPoint(w, dims.live)
    pointAt(x, y)
    looks = {}
end)
at(3, function()
    local w = O(); if not (w and dims.live) then return end
    local any = false
    for _, l in ipairs(looks) do if l.p == w and l.hot then any = true end end
    check(any, "59: a live row on the same page does take the hover wash (the check can see one)")
    pointBack(); park()
end)

-- put back
at(10, function()
    pointBack()
    MM.rowLook = realRowLook
    local w = O(); if w then pcall(function() w:close() end) end
    say("summary: " .. passes .. " PASS, " .. fails .. " FAIL")
    say("DONE")
end)

local function tick()
    t = t + 1
    local i = 1
    while steps[i] do
        if steps[i].n <= t then
            local ok, e = pcall(steps[i].fn)
            if not ok then say("ERR step: " .. tostring(e)) end
            table.remove(steps, i)
        else i = i + 1 end
    end
    if #steps == 0 then Events.OnFETick.Remove(tick); pointBack(); MM.rowLook = realRowLook end
end
Events.OnFETick.Add(tick)
say("start")
