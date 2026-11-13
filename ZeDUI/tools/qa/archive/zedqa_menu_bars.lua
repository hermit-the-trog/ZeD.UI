-- ZeDUI/tools/qa/zedqa_menu_bars.lua  (Nov 5 2026, QA; 6c1e3fb2, the main menu's real scroll bars; the director: "the main
-- menus ... are not Z scroll bars"). At the main menu. Walks every screen with a list; on each, for every bar it drew
-- (window._zedBars): its place, whether it has arrows, whether it runs inside its window, and, when the list runs over,
-- the press path the mouse takes (the bar's hit.drag): down arrow steps, up arrow steps back, a click on the track pages, the
-- thumb drags. Large text second when Lua/zedqa_mbs_large.txt exists. Stops on Occupation and traits for the real mouse
-- (zedqa_menu_bars_run.ps1) until Lua/zedqa_mbs_end.txt exists. Pictures zqa_mbs_<WxH>_<screen>.png. grep "ZEDQA mbs".
local MM = ZeD.MainMenu
local R = MM.root
local function say(s) print("ZEDQA mbs " .. tostring(s)) end
local function vwin(view) for _, rv in ipairs(MM.views) do if rv.view == view then return R[rv.field] end end end
local SZ = getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight()
local function exists(f) local r = getFileReader(f, false); if r then r:close(); return true end return false end
local fails, passes, noArrows, bars = 0, 0, 0, 0
local function check(ok, s) if ok then passes = passes + 1 else fails = fails + 1; say("FAIL " .. s) end end
local plan, i, wait = {}, 1, 0
local function add(frames, fn) plan[#plan + 1] = { f = frames, fn = fn } end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_mbs_" .. SZ .. "_" .. n .. ".png") end) end

-- a bar's checks, one press a step (the bar lets go on its next draw, the button being up)
local function press(sb, ly) sb._hit.drag(nil, sb._top + ly) end
local function testBars(tag, win)
    add(30, function()
        win = (type(win) == "function") and win() or win
        CUR_WIN = win
        local list = {}
        local drawn = {}; for _, h in ipairs(win and win._hits or {}) do drawn[h] = true end   -- (drawn this frame: an old page's bar stays in the table)
        for k, sb in pairs(win and win._zedBars or {}) do if sb.visible and drawn[sb._hit] then list[#list + 1] = { k = k, sb = sb } end end
        table.sort(list, function(a, b) return a.k < b.k end)
        CUR_LIST = list
        say(tag .. ": " .. #list .. " bars")
        shot(tag)
        for _, e in ipairs(list) do
            local sb = e.sb
            bars = bars + 1
            if sb.arrowH == 0 then noArrows = noArrows + 1 end
            local ins = sb.x >= 0 and sb.y >= 0 and sb.x + sb.width <= win:getWidth() and sb.y + sb.height <= win:getHeight()
            say(string.format("  %s at %d,%d %dx%d arrows %d, thumb %d, over %s", e.k, sb.x, sb.y, sb.width, sb.height, sb.arrowH, sb:getThumbHeight(), tostring(sb.barSizeRatio < 1)))
            check(ins, tag .. " " .. e.k .. " runs outside its window")
            check(sb.barSizeRatio >= 1 or sb.arrowH > 0 or sb.height < sb.width * 2 + ZeD.T.px(24), tag .. " " .. e.k .. " has no arrows on a tall bar")
        end
    end)
    for n = 1, 4 do
        add(6, function()
            for _, e in ipairs(CUR_LIST or {}) do
                local sb = e.sb
                if sb.barSizeRatio < 1 then
                    e.p = e.p or {}
                    e.p[n] = sb.scrollPos
                    if n == 1 then sb:setScrollPos(0); e.p[1] = sb.scrollPos end
                    if n == 1 and sb.arrowH > 0 then press(sb, sb.height - math.floor(sb.arrowH / 2))
                    elseif n == 2 then press(sb, sb:getThumbY() + sb:getThumbHeight() + 2)
                    elseif n == 3 then local ty = sb:getThumbY() + 2; press(sb, ty); press(sb, ty + 20)
                    elseif n == 4 and sb.arrowH > 0 then press(sb, 2) end
                end
            end
        end)
    end
    add(6, function()
        for _, e in ipairs(CUR_LIST or {}) do
            local sb = e.sb
            if sb.barSizeRatio < 1 and e.p then
                local a, b, c, d, z = e.p[1], e.p[2], e.p[3], e.p[4], sb.scrollPos
                local range = sb:scrollRange()
                say(string.format("  %s arrow step %.0f px (a row %s), track step %.0f px, view %d, range %.0f", e.k, (b - a) * range, tostring(sb.lineH), (c - b) * range, sb.height, range))
                if sb.arrowH > 0 then
                    check(b > a, tag .. " " .. e.k .. " down arrow: " .. tostring(a) .. " to " .. tostring(b))
                    check(z < d, tag .. " " .. e.k .. " up arrow: " .. tostring(d) .. " to " .. tostring(z))
                end
                check(c > b, tag .. " " .. e.k .. " track: " .. tostring(b) .. " to " .. tostring(c))
                check(d > c, tag .. " " .. e.k .. " thumb drag: " .. tostring(c) .. " to " .. tostring(d))
                sb:setScrollPos(0)
            end
        end
        shot(tag .. "_top")
    end)
end

local function walk(suffix)
    local S = suffix
    add(10, function() MM.ctx.open = nil; MM.showView("load") end)
    testBars("load" .. S, function() return R.loadWin end)
    add(5, function() MM.showView("main"); MM.openMods() end)
    testBars("mods" .. S, function() return vwin("mods") or R.modsWin end)
    add(5, function() (vwin("mods") or R.modsWin):enterOrder("order") end)
    testBars("mods_order" .. S, function() return vwin("mods") or R.modsWin end)
    add(5, function() (vwin("mods") or R.modsWin):leaveOrder(false) end)
    add(10, function() (vwin("mods") or R.modsWin):enterProfiles() end)
    testBars("mods_profiles" .. S, function() return vwin("mods") or R.modsWin end)
    add(5, function() (vwin("mods") or R.modsWin):leaveProfiles() end)
    add(5, function() MM.showView("main"); MM.openOptions() end)
    testBars("options" .. S, function() return R.optsWin end)
    add(5, function() R.optsWin.pageIdx = 3; R.optsWin.scroll = 0 end)
    testBars("options_p3" .. S, function() return R.optsWin end)
    add(5, function()
        R.optsWin:back()
        local j = vwin("join")
        -- forty stand-in rows, so the saved servers list runs over
        local orig = ZeD_MMJoin.savedRows
        j.savedRows = function(self)
            local rows = orig(self)
            local base = rows[#rows]
            for k = 1, 40 do local c = {}; for a, v in pairs(base or {}) do c[a] = v end; c.key = "qa" .. k; c.h = c.h or 40; rows[#rows + 1] = c end
            return rows
        end
        MM.showView("join")
    end)
    testBars("join" .. S, function() return vwin("join") end)
    add(3, function() vwin("join").savedRows = nil end)
    add(5, function() MM.showView("main"); MM.act.host() end)
    add(20, function() R.hostWin:editSettings() end)
    testBars("srvset" .. S, function() return vwin("srvset") end)
    -- the page that has a list that runs over
    for pg = 2, 30 do add(4, function()
        local w = vwin("srvset")
        local found = false
        for _, h in ipairs(w._hits or {}) do if tostring(h.id):find("^srvset:track:") then found = true end end
        if not found and not SRV_FOUND then pcall(function() w:selectPage(pg) end) else SRV_FOUND = true end
    end) end
    testBars("srvset_list" .. S, function() return vwin("srvset") end)
    add(5, function() vwin("srvset"):act("back") end)
    add(10, function() R.hostWin:back(); MM.showView("newgame") end)
    add(20, function()
        local nw = R.newWin
        for k, d in ipairs(nw:items()) do if d.mode == "Sandbox" then nw.sel = k end end
        nw:next()
    end)
    testBars("spawn" .. S, function() return vwin("spawn") end)
    add(5, function() vwin("spawn"):next() end)
    testBars("sandbox" .. S, function() return vwin("sandbox") end)
    add(5, function() local s = vwin("sandbox"); s.pageIdx = 2; s.scroll = 0 end)
    testBars("sandbox_p2" .. S, function() return vwin("sandbox") end)
    add(5, function() vwin("sandbox"):next() end)
    testBars("traits" .. S, function() return vwin("traits") end)
    add(5, function() vwin("traits"):next() end)
    testBars("looks" .. S, function() return vwin("looks") end)
    -- the pull-down: sixty rows, so it scrolls; the bar must cover no words
    add(10, function()
        local items = {}
        for k = 1, 60 do items[k] = { text = "Pull-down row " .. k .. " with a long name", fn = function() end } end
        MM.openPopup("qabars", items, { x = ZeD.T.px(200), y = ZeD.T.px(60), w = ZeD.T.px(300), h = ZeD.T.px(26) }, false)
    end)
    add(20, function() shot("dropdown" .. S); MM.ctx.open = nil; MM.popup = nil end)
end
local function back()
    add(10, function() vwin("looks"):back() end)
    add(10, function() vwin("traits"):back() end)
    add(10, function() vwin("sandbox"):back() end)
    add(10, function() vwin("spawn"):back() end)
    add(10, function() R.newWin:back(); MM.showView("main") end)
end
walk("")
if exists("zedqa_mbs_large.txt") then
    back()
    add(10, function() ZeD.applyTheme(nil, nil, "large") end)
    walk("_large")
end
-- the bar with no arrows (Build's switch): the track takes the whole height
add(10, function() vwin("looks"):back() end)
add(10, function() MM.qaNoArrows = true end)
testBars("traits_noarrows", function() return vwin("traits") end)
add(5, function() MM.qaNoArrows = nil end)
-- the real mouse: Occupation and traits, the positive traits' list
add(40, function()
    local w = vwin("traits")
    local out = {}
    for k, sb in pairs(w._zedBars or {}) do
        if sb.visible and sb.barSizeRatio < 1 then
            local ax = w:getAbsoluteX() + sb.x + math.floor(sb.width / 2)
            local ay = w:getAbsoluteY() + sb.y
            out[#out + 1] = string.format("%s %d %d %d %d", k, ax, ay, sb.height, sb.arrowH)
        end
    end
    table.sort(out)
    local f = getFileWriter("zedqa_mbs_bars.txt", true, false)
    for _, l in ipairs(out) do f:write(l .. "\n") end
    f:close()
    say("real mouse ready: " .. table.concat(out, "; "))
    say("totals: " .. bars .. " bars, " .. noArrows .. " without arrows, " .. passes .. " pass, " .. fails .. " fail")
end)
local last = {}
local function watch()
    if i <= #plan then return end
    local w = vwin("traits")
    for k, v in pairs(w and w.scroll or {}) do
        if last[k] ~= v then last[k] = v; say("real mouse: column " .. tostring(k) .. " scroll " .. tostring(v)) end
    end
    if exists("zedqa_mbs_end.txt") then Events.OnFETick.Remove(watch); say("DONE") end
end
local function drive()
    local st = plan[i]
    if not st then Events.OnFETick.Remove(drive); Events.OnFETick.Add(watch); say("watching"); return end
    wait = wait + 1
    if wait < st.f then return end
    wait = 0; i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnFETick.Add(drive)
say("start " .. SZ)
