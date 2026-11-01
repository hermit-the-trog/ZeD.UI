-- ZeDUI/tools/qa/gallery_nov1_menu.lua  (Nov 1 2026, QA)
-- MAIN MENU ONLY, pushed by gallery_nov1_menus_run.ps1 (zedqa_run.ps1 refuses main-menu scripts). The Workshop
-- gallery retake (workshop/gallery/REVIEW_20261101.md, "Retakes" 9): page 48's picture, mm4_01_options_zed
-- (gallery_v4_menus.lua's name, so shots.json keeps working). The t14 picture had ZeD setup at the top of its list:
-- the Hidden actions row scrolled out and its pop-up shut. Here the desk's Options opens on ZeD setup with the
-- monitor's screen area stretched to the bottom of the display (as gallery_v4_menus.lua), the list is scrolled so
-- the Hidden actions row sits mid-list, the row is marked for the help band, and its drop-down is opened from its
-- own box (what a click on the box does). Nothing is chosen: the pop-up is shut and the window closed with Back.
-- Logs "rect mm4_01_options_zed options x y w h list y h | row at y (scroll s) | pop-up ...". "ZEDQA n1m ... DONE".
local MM = ZeD and ZeD.MainMenu
local N = { steps = {}, t = 0, T0 = 0 }
function N.say(s) print("ZEDQA n1m " .. tostring(s)) end
local say = N.say
if not (MM and MM.openOptions) then say("ERR ZeD's main menu is not loaded"); say("DONE"); return end
function N.at(n, fn) N.T0 = N.T0 + n; N.steps[#N.steps + 1] = { n = N.T0, fn = fn } end
function N.O() return MM.root and MM.root.optsWin end
function N.park() pcall(function() Mouse.setXY(getCore():getScreenWidth() - 4, getCore():getScreenHeight() - 4) end) end
-- the Hidden actions row on ZeD setup: its index in the rows, its place in the list (the drawn heights)
function N.find()
    local w = N.O()
    local rows = w:rowsFor(w:pages()[w.pageIdx])
    local y = 0
    for i, r in ipairs(rows) do
        if r.labelKey == "UI_ZeD_Settings_HiddenActions" then return { r = r, i = i, y = y, h = r._h or ZeD.T.px(30) } end
        y = y + (r._h or ZeD.T.px(30))
    end
    return nil
end

N.at(2, function()
    N.park()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    local L = MM.layout()
    L.th = getCore():getScreenHeight() - L.ty - math.floor(L.s * 4)
    say("tube " .. L.tx .. "," .. L.ty .. " " .. L.tw .. "x" .. L.th)
    MM.openOptions()
end)
N.at(30, function()
    local w = N.O()
    if not w then say("ERR no Options window"); return end
    local idx = 1
    for i, pg in ipairs(w:pages()) do if pg.setup then idx = i end end
    w.pageIdx = idx; w.scroll = 0; w.focusId = nil; w._cellRow = nil
    say("options on page " .. idx .. " (" .. tostring(w:pages()[idx] and w:pages()[idx].title) .. ")")
end)
N.at(20, function()
    local w = N.O()
    if not w then return end
    local f = N.find()
    N.row = f
    if not f then say("ERR no Hidden actions row on ZeD setup"); return end
    local vh = (w._list and w._list.h) or 0
    w.scroll = math.max(0, f.y - math.floor((vh - f.h) / 2))
    w._cellRow = f.r   -- (the help band reads this row, as for a row being edited)
    say(string.format("Hidden actions: row %d at %d of the list, list %d high: scroll %d", f.i, math.floor(f.y), math.floor(vh), math.floor(w.scroll)))
end)
-- its box, as a click on it: the drop-down opens from the box (ZeD_MMOptions:drawControl's hit)
N.at(6, function()
    local w, f = N.O(), N.row
    if not (w and f) then return end
    local want = tostring(w.kind) .. ":r" .. f.i .. ":box"
    local hit = nil
    for _, h in ipairs(w._hits or {}) do if h.id == want then hit = h end end
    if hit and hit.fn then hit.fn(); say("the Hidden actions box clicked (" .. want .. ")")
    else w:activateRow(f.r); say("no box hit (" .. want .. "): the row activated") end
    N.park()
end)
N.at(30, function()
    local w, f = N.O(), N.row
    local pop = MM.popup
    local items = {}
    for _, it in ipairs(pop and pop.items or {}) do if type(it) == "table" and it.text then items[#items + 1] = tostring(it.text) end end
    say("pop-up " .. tostring(MM.ctx and MM.ctx.open) .. ": " .. table.concat(items, " | "))
    pcall(function() getCore():TakeFullScreenshot("mm4_01_options_zed.png") end)
    say("shot mm4_01_options_zed")
    if w then
        local L = w._list or {}
        say(string.format("rect mm4_01_options_zed options %d %d %d %d list %d %d | row at %d (scroll %d) | pop-up at %s",
            math.floor(w:getAbsoluteX()), math.floor(w:getAbsoluteY()), math.floor(w:getWidth()), math.floor(w:getHeight()),
            math.floor((L.y or 0) + w:getAbsoluteY()), math.floor(L.h or 0), f and math.floor(f.y) or -1, math.floor(w.scroll or 0),
            tostring(pop and pop.anchor and (math.floor(pop.anchor.x) .. "," .. math.floor(pop.anchor.y)))))
    end
end)
N.at(10, function()
    if MM.ctx then MM.ctx.open = nil end
    MM.popup = nil
    local w = N.O()
    if w then w._cellRow = nil; w.scroll = 0; w.focusId = nil; w:back() end
end)
N.at(20, function() MM._layout = nil; say("view " .. tostring(MM.view)); say("DONE") end)

function N.tick()
    N.t = N.t + 1
    for _, s in ipairs(N.steps) do
        if s.n == N.t then
            local ok, e = pcall(s.fn)
            if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end
        end
    end
    if N.t > N.T0 + 5 then Events.OnFETick.Remove(N.tick) end
end
Events.OnFETick.Add(N.tick)
say("start")
