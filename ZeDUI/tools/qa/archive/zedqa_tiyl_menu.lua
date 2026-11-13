-- ZeDUI/tools/qa/zedqa_tiyl_menu.lua  (Nov 5 2026, QA; punch list 64): a new game through ZeD's screens with This Is Your
-- Life on. Reads the pick from Lua/zedqa_tiyl_pick.txt ("origin <n>" or "story <id>"). Sandbox mode; the mod's town in the
-- town list; the Hometown page with its rows; then a hometown goes on through ZeD's Sandbox, Occupation and Looks, a story
-- through the mod's own screens. Pictures tiyl_<pick>_<n>_<page>.png. grep "ZEDQA tym".
local function say(s) print("ZEDQA tym " .. tostring(s)) end
local MM, R = ZeD.MainMenu, ZeD.MainMenu.root
local function vwin(view) for _, rv in ipairs(MM.views) do if rv.view == view then return R[rv.field] end end end
local r = getFileReader("zedqa_tiyl_pick.txt", false)
local line = r and r:readLine() or "origin 2"; if r then r:close() end
local kind, arg = line:match("^(%a+) (.+)$")
local shots = 0
local function shot(n) shots = shots + 1; local f = string.format("tiyl_%s%s_%d_%s.png", kind, arg, shots, n); pcall(function() getCore():TakeFullScreenshot(f) end); say("shot " .. f) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
add(1500, function() say("TIYL loaded " .. tostring(TIYL ~= nil) .. ", pick " .. line); MM.showView("newgame") end)
add(1500, function()
    local nw = R.newWin
    for k, d in ipairs(nw:items()) do if d.mode == "Sandbox" then nw.sel = k end end
    nw:next()
end)
add(2500, function()
    local sp = vwin("spawn")
    local items, hit = sp:items(), nil
    local names = {}
    for k, it in ipairs(items) do
        names[#names + 1] = tostring(it.name)
        if it.region and it.region.name == TIYL.REGION_NAME then hit = k end
    end
    say("town list (" .. #items .. "): " .. table.concat(names, ", "))
    say((hit and "PASS" or "FAIL") .. " the mod's town is in ZeD's list at " .. tostring(hit))
    if hit then sp.sel = hit end
    shot("towns")
end)
add(1200, function() vwin("spawn"):next() end)
add(2500, function()
    local h = vwin("tiyl")
    local items = h and h:items() or {}
    local rows = {}
    for k, it in ipairs(items) do rows[#rows + 1] = k .. ":" .. tostring(it.name) .. "[" .. tostring(it.tiyl and it.tiyl.kind) .. ":" .. tostring(it.tiyl and it.tiyl.id) .. "]" end
    say("Hometown page (" .. #items .. "): " .. table.concat(rows, ", "))
    local want
    for k, it in ipairs(items) do
        if it.tiyl and ((kind == "origin" and it.tiyl.kind == "origin" and k == tonumber(arg)) or (kind == "story" and it.tiyl.id == arg)) then want = k end
    end
    say((want and "PASS" or "FAIL") .. " the pick is row " .. tostring(want))
    if want then h.sel = want end
    PICKED_TYM = want and items[want] or nil
    shot("hometown")
end)
add(1500, function()
    say("desc: " .. string.sub(tostring(PICKED_TYM and PICKED_TYM.desc), 1, 220))
    vwin("tiyl"):next()
    say("pending origin " .. tostring(TIYL.PendingOriginId) .. ", story " .. tostring(TIYL.PendingPosterStoryId))
end)
add(3000, function() shot("after_hometown") end)
-- a hometown: ZeD's Sandbox, Occupation, Looks. A story: ZeD's Sandbox, then the mod's screens press Play themselves.
add(800, function() vwin("sandbox"):next() end)
if kind == "origin" then
    add(2500, function() shot("occupation"); say("pending origin " .. tostring(TIYL.PendingOriginId)); vwin("traits"):next() end)
    add(2500, function() shot("looks"); say("Play"); local l = vwin("looks"); if l.play then l:play() else l:next() end end)
end
add(1000, function() say("the world loads next"); say("DONE") end)
local function drive()
    local st = plan[i]
    if not st then Events.OnFETick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnFETick.Add(drive)
