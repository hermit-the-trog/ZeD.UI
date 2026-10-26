-- ZeDUI/tools/qa/zedqa_menu_zed_switches.lua  (Oct 26 2026)
-- ZeD setup's five on / off switches for what the game does not do (Ammo on the belt, Read marks in item lists,
-- NEXT LEVEL on skill books, Dashboard warning lamps, Moodle notices): at the main menu (zedqa_menu_mods_run.ps1
-- with an empty mod list), Options opened on ZeD setup, in Dark, Light, High contrast and Dark with Large text
-- (ZeD.applyTheme, in memory only; put back at the end). For each: every switch is on the page, in its group,
-- its name drawn whole (not cut short), the row as tall and the switch as far in as its neighbours'; a picture
-- with the switches in sight ("ZEDQA zsw rect" lines give the rows for the crops) and one at the bottom of the
-- page. Then the pad: Down from the first row walks the page, reaching each switch with its focus fill painted.
-- Nothing is changed: no value is set. grep "ZEDQA zsw".
local MM = ZeD.MainMenu
local R = MM.root
local function say(s) print("ZEDQA zsw " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_zsw_" .. n .. ".png") end) end
local was = { base = ZeD.currentBase, accent = ZeD.currentAccent, size = ZeD.currentSize }
local KEYS = {
    "UI_ZeD_Settings_ReadMarks", "UI_ZeD_Settings_ReadNext", "UI_ZeD_Settings_MoodleNotices",
    "UI_ZeD_Settings_AmmoBox", "UI_ZeD_Settings_DashLamps",
}
local NEIGHBOUR = {   -- the switch already in each group, to measure against
    UI_ZeD_Settings_ReadMarks = "UI_ZeD_Settings_WindowSquares", UI_ZeD_Settings_ReadNext = "UI_ZeD_Settings_WindowSquares",
    UI_ZeD_Settings_MoodleNotices = "UI_ZeD_Settings_WindowSquares", UI_ZeD_Settings_AmmoBox = "UI_ZeD_Settings_WindowSquares",
    UI_ZeD_Settings_DashLamps = "UI_ZeD_Settings_WindowSquares",
}
local W = nil
local drawn, fills = {}, {}
local function hookDraw()
    if W._zswHooked then return end
    W._zswHooked = true
    local origT, origR = W.drawText, W.drawRect
    W.drawText = function(self, s, x, y, r, g, b, a, f)
        drawn[#drawn + 1] = { s = s, x = x, y = y }
        return origT(self, s, x, y, r, g, b, a, f)
    end
    W.drawRect = function(self, x, y, w, h, a, r, g, b)
        if a and a > 0.5 and a < 0.6 then fills[#fills + 1] = { x = x, y = y, w = w, h = h } end
        return origR(self, x, y, w, h, a, r, g, b)
    end
end
local function specOf(key)
    for _, b in ipairs(W._specs or {}) do if b.rowRef and b.rowRef.labelKey == key then return b end end
    return nil
end
-- the group header each row sits under
local function groupOf(key)
    local head = nil
    for _, r in ipairs(W:rowsFor(W:pages()[W.pageIdx])) do
        if r.kind == "header" then head = tostring(r.text) end
        if r.labelKey == key then return head end
    end
    return nil
end
local function setupIdx()
    for i, p in ipairs(W:pages()) do if p.setup then return i end end
    return 1
end

local Q, qi, wait = {}, 1, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

step(10, function()
    MM.showView("main"); MM.openOptions()
end)
step(30, function()
    W = R.optsWin
    if not check(W ~= nil and W:isVisible(), "Options is open") then return end
    hookDraw()
    W.pageIdx = setupIdx(); W.scroll = 0; W.focusId = nil
end)

local CONFIGS = { { "dark", "dark", "small" }, { "light", "light", "small" }, { "hc", "hicon", "small" }, { "large", "dark", "large" } }
for _, cf in ipairs(CONFIGS) do
    step(10, function()
        ZeD.applyTheme(cf[2], was.accent, cf[3])
        W.scroll = 0
    end)
    -- bring the first switch to the top of the list
    step(20, function()
        local b = specOf(KEYS[1])
        if b then W.scroll = math.max(0, b.ry - ZeD.T.px(60)) end
    end)
    step(30, function()
        drawn = {}
    end)
    step(2, function()
        local T = ZeD.T
        local L = W._list
        local inner = L.w - T.px(2) - T.sp.scrollbarW
        local lw = math.floor(inner * 0.44)
        local f2 = T.fontF2
        local ax, ay = W:getAbsoluteX(), W:getAbsoluteY()
        local top, bot = nil, nil
        for _, key in ipairs(KEYS) do
            local b = specOf(key)
            local name = ZeD.tr(key)
            if check(b ~= nil, cf[1] .. " " .. key .. ": on the page") then
                local ry = L.y + b.ry - W.scroll
                local seen = false
                for _, d in ipairs(drawn) do if d.s == name and d.y >= ry and d.y < ry + b.rh then seen = true end end
                local tw = MM.textW(f2, name)
                local inView = ry >= L.y and ry + b.rh <= L.y + L.h
                if inView then
                    check(seen, cf[1] .. " " .. key .. ": its name drawn whole (" .. tw .. " of " .. (lw - T.px(26)) .. " px)")
                    top = math.min(top or ry, ry); bot = math.max(bot or 0, ry + b.rh)
                else
                    say(cf[1] .. " " .. key .. ": out of sight in this picture (row at " .. (ry - L.y) .. " of " .. L.h .. ")")
                end
                check(tw <= lw - T.px(26), cf[1] .. " " .. key .. ": the name fits its column (" .. tw .. " <= " .. (lw - T.px(26)) .. ")")
                local nb = specOf(NEIGHBOUR[key])
                if nb then check(nb.rh == b.rh, cf[1] .. " " .. key .. ": as tall as its neighbour switch (" .. b.rh .. " / " .. nb.rh .. ")") end
                local first = name:sub(1, 1)
                local rest = name:sub(2)
                local sentence = first == first:upper() and (rest == rest:lower() or key == "UI_ZeD_Settings_ReadNext")
                check(sentence, cf[1] .. " " .. key .. ": sentence case [" .. name .. "]")
                say(cf[1] .. " " .. key .. " group [" .. tostring(groupOf(key)) .. "] row y " .. (ry - L.y) .. " h " .. b.rh)
            end
        end
        if top then say(string.format("rect %s %d %d %d %d", cf[1], ax + L.x, ay + top - T.px(40), L.w, bot - top + T.px(48))) end
        say(string.format("rect %s_list %d %d %d %d", cf[1], ax + L.x, ay + L.y, L.w, L.h))
        shot(cf[1])
    end)
    -- the HUD group, if it was not all in sight
    step(5, function()
        local b = specOf("UI_ZeD_Settings_DashLamps")
        if b then W.scroll = math.max(0, b.ry - ZeD.T.px(260)) end
    end)
    step(30, function()
        local T, L = ZeD.T, W._list
        local ax, ay = W:getAbsoluteX(), W:getAbsoluteY()
        local a, b = specOf("UI_ZeD_Settings_MoodleNotices"), specOf("UI_ZeD_Settings_DashLamps")
        if a and b then
            local y0 = L.y + a.ry - W.scroll
            say(string.format("rect %s_hud %d %d %d %d", cf[1], ax + L.x, ay + y0 - T.px(130), L.w, b.ry - a.ry + b.rh + T.px(140)))
        end
        shot(cf[1] .. "_hud")
    end)
    -- the bottom of the page
    step(5, function() W.scroll = 1000000 end)
    step(30, function()
        local T, L = ZeD.T, W._list
        say(string.format("rect %s_bottom %d %d %d %d", cf[1], W:getAbsoluteX() + L.x, W:getAbsoluteY() + L.y, L.w, L.h))
        say(cf[1] .. " bottom: scroll " .. W.scroll)
        shot(cf[1] .. "_bottom")
    end)
end

-- the pad: Down from the first row, one press a frame
local reached, painted = {}, {}
step(10, function()
    ZeD.applyTheme(was.base, was.accent, was.size)
    MM.forceGamepad = true
    W.scroll = 0
    W.focusId = "orow:1"
end)
for i = 1, 60 do
    step(3, function()
        local r, b = W:focusedRow()
        if r and r.labelKey then
            for _, key in ipairs(KEYS) do
                if r.labelKey == key and not reached[key] then
                    reached[key] = i
                    local ry = W._list.y + b.ry - W.scroll
                    for _, f in ipairs(fills) do
                        if f.y <= ry + 1 and f.y + f.h >= ry + b.rh - 1 then painted[key] = true end
                    end
                    if key == "UI_ZeD_Settings_AmmoBox" then
                        local L = W._list
                        say(string.format("rect pad %d %d %d %d", W:getAbsoluteX() + L.x, W:getAbsoluteY() + ry - ZeD.T.px(40), L.w, b.rh + ZeD.T.px(80)))
                        shot("pad")
                    end
                end
            end
        end
        fills = {}
        W:joyDir("down")
    end)
end
step(5, function()
    for _, key in ipairs(KEYS) do
        check(reached[key] ~= nil, "pad: Down reaches " .. key .. (reached[key] and (" (press " .. reached[key] .. ")") or ""))
        check(painted[key] == true, "pad: " .. key .. " shows the focus fill")
    end
    MM.forceGamepad = false
    W.focusId = nil
    W.scroll = 0
    W:back()
    MM.showView("main")
end)
step(10, function()
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local function onTick()
    if not Q[qi] then Events.OnFETick.Remove(onTick); return end
    wait = wait + 1
    if wait < Q[qi].n then return end
    wait = 0
    local ok, e = pcall(Q[qi].fn)
    if not ok then fails = fails + 1; say("ERR step " .. qi .. " " .. tostring(e)) end
    qi = qi + 1
end
Events.OnFETick.Add(onTick)
say("start")
