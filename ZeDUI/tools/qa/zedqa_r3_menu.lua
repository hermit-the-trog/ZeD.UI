-- ZeDUI/tools/qa/zedqa_r3_menu.lua  (Oct 26 2026, compatibility round 3)
-- MAIN MENU ONLY, with a round-3 group's mods on in mods/default.txt (zedqa_menu_mods_run.ps1 -Tag r3m):
-- ZeD's main menu with the mods on: the main view, Mods, Options; then New Game > Sandbox > map >
-- sandbox settings > Occupation and traits (the occupations and traits the mods add: counts, and the
-- names of the ones from mods) > Looks; then back out to the main menu. Nothing is started.
-- A census of the visible UI on each view (a vanilla screen or a mod's panel over ZeD's).
-- Shots: zqa_r3m_*.png in Zomboid/Screenshots. grep "ZEDQA r3m".
local MM = ZeD.MainMenu
local R = MM.root
local function say(s) print("ZEDQA r3m " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_r3m_" .. n .. ".png") end); say("shot zqa_r3m_" .. n .. ".png") end
local function vwin(view) for _, rv in ipairs(MM.views) do if rv.view == view then return R[rv.field] end end return nil end
local function census(label)
    local ui = UIManager.getUI()
    local parts = {}
    for i = 0, ui:size() - 1 do
        local e = ui:get(i)
        if e:isVisible() then
            local t = e:getTable()
            local ty = tostring(t and (t.Type or t.type) or e:getClass():getSimpleName())
            parts[#parts + 1] = string.format("%s@%d,%d,%dx%d", ty, math.floor(e:getX()), math.floor(e:getY()), math.floor(e:getWidth()), math.floor(e:getHeight()))
        end
    end
    say("ui " .. label .. ": " .. table.concat(parts, " ; "))
end
local function prof() local m = MainScreen and MainScreen.instance; return m and m.charCreationProfession end
local VANILLA_PROFS = { unemployed = 1, fireofficer = 1, policeofficer = 1, parkranger = 1, constructionworker = 1, securityguard = 1, carpenter = 1,
    burglar = 1, chef = 1, repairman = 1, farmer = 1, fisherman = 1, doctor = 1, veteran = 1, nurse = 1, lumberjack = 1, fitnessInstructor = 1,
    burgerflipper = 1, electrician = 1, engineer = 1, metalworker = 1, mechanics = 1, rancher = 1, tailor = 1, blacksmith = 1, smither = 1, hunter = 1 }
local function listNames(lb)
    local out = {}
    for _, it in ipairs(lb and lb.items or {}) do
        local o = it.item
        local id = nil
        pcall(function() id = tostring(o:getType()) end)
        if not id then pcall(function() id = tostring(o:getName()) end) end
        out[#out + 1] = id or tostring(it.text)
    end
    return out
end
local steps = {}
local function step(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
step(60, function() census("main"); shot("1_main") end)
step(20, function() MM.showView("mods") end)
step(120, function() census("mods"); shot("2_mods") end)
step(20, function() MM.showView("main") end)
step(30, function() MM.showView("options") end)
step(120, function() census("options"); shot("3_options") end)
step(20, function() MM.showView("main") end)
step(30, function() MM.showView("newgame") end)
step(40, function()
    local nw = R.newWin
    for i, d in ipairs(nw:items()) do if d.mode == "Sandbox" then nw.sel = i end end
    nw:next()
end)
step(80, function() census("spawn"); shot("4_spawn"); vwin("spawn"):next() end)
step(80, function() shot("5_sandbox"); vwin("sandbox"):next() end)
step(120, function()
    census("traits")
    local pr = prof()
    local profs = listNames(pr and pr.listboxProf)
    local good = listNames(pr and pr.listboxTrait)
    local bad = listNames(pr and pr.listboxBadTrait)
    local modProfs = {}
    for _, n in ipairs(profs) do if not VANILLA_PROFS[n] then modProfs[#modProfs + 1] = n end end
    say("occupations " .. #profs .. " (not vanilla: " .. table.concat(modProfs, ", ") .. ")")
    say("traits positive " .. #good .. ", negative " .. #bad)
    shot("6_traits")
end)
step(30, function()
    local W = vwin("traits")
    if W then W.scroll = 100000; pcall(function() W._traitScroll = 100000 end) end
end)
step(40, function() shot("7_traits_scrolled") end)
step(30, function() vwin("traits"):next() end)
step(120, function() census("looks"); shot("8_looks") end)
step(30, function()
    pcall(function() vwin("looks"):back() end); pcall(function() vwin("traits"):back() end); pcall(function() vwin("sandbox"):back() end); pcall(function() vwin("spawn"):back() end)
    pcall(function() R.newWin:back() end); MM.showView("main")
end)
step(60, function() census("main again"); say("DONE") end)

local qi, wait = 1, nil
local function tick()
    local s = steps[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    wait = wait or (now + s.n * 1000 / 60)
    if now < wait then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
