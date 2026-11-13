-- ZeDUI/tools/qa/zedqa_b8_station.lua  (Nov 7 2026, QA; CHECK_everyday_leftovers_20261107.md B15, item 2b)
-- Crafting stations other than benches and racks now open ZeD's general station card, but the game's own Butcher Hook, Log Bench,
-- Log Stool, Log Table and Other Log Stool must keep opening what they opened before (the game's window). The script builds each
-- of them beside the character (the game's own build code with the build cheat, as zedqa_animals.lua does), calls the game's
-- entry for a station option, ISEntityUI.OpenWindow(player, entity), with the World window shut, and checks that ZeD took none:
--   ZeD.Stations.classify (general) gives no kind that ZeD draws a general card for, no station is bound to the player, the World
--   window did not open. It reports (NOTE) whether the game's own window opened and closes it again.
-- Removes everything it built. Not scriptable here: a modded station (furnace, still, tank: the Craft tab's STATION card, Start /
-- Take / Add, B on the pad), a mod's machine on the drying-rack view, safe mode for stations, the pad's Interact prompt.
-- grep "ZEDQA b8sc"; no shots (the game's window is shown only for a moment).
local TAG = "b8sc"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
if ZEDQA_HOME then pcall(ZEDQA_HOME, TAG) end
local p = getPlayer()
local pn = p and p:getPlayerNum() or 0
local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
local ST = ZeD and ZeD.Stations
if not (p and CW and WW and ST and ISEntityUI and ISEntityUI.OpenWindow and ISBuildIsoEntity) then
    say("ERR ZeD's stations or the game's entity UI are not loaded"); say("DONE"); return
end
local passes, misses = 0, 0
local function check(ok, what)
    if ok then passes = passes + 1; say("PASS " .. what) else misses = misses + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8sc_" .. n .. ".png") end) end
local function cw() return CW.getWindow() end
local function ww() return WW.getWindow() end
local function keepDown(w)
    if not w then return end
    w._autoShaded = false
    if w.windowShaded and w.setWindowShaded then w:setWindowShaded(false) end
    w._outSince = getTimestampMs() + 600000
end
local function holdBoth() keepDown(cw()); keepDown(ww()) end

-- the step list: step(waitTicks, fn) runs fn that many ticks after the step before; waitFor(max, cond, fn) runs fn when cond holds (fn(timedOut))
local Q, qi, qc = {}, 1, 0
local function step(wait, fn) Q[#Q + 1] = { wait = wait, fn = fn } end
local function waitFor(max, cond, fn) Q[#Q + 1] = { max = max, cond = cond, fn = fn } end
local cleanups = {}
local function onCleanup(fn) cleanups[#cleanups + 1] = fn end
local ticker
local function finish()
    for i = #cleanups, 1, -1 do local ok, e = pcall(cleanups[i]); if not ok then say("ERR cleanup " .. i .. ": " .. tostring(e)) end end
    cleanups = {}
    say("checks: passes=" .. passes .. " misses=" .. misses)
    say("DONE")
end
local function onTick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(ticker); finish(); return end
    qc = qc + 1
    local go, timedOut = false, false
    if s.cond then
        local ok, v = pcall(s.cond)
        if ok and v then go = true elseif qc >= s.max then go, timedOut = true, true end
    else
        go = qc >= s.wait
    end
    if go then
        qi = qi + 1; qc = 0
        local ok, e = pcall(s.fn, timedOut)
        if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(e)) end
    end
end


-- ---- helpers
local HOME = { x = p:getX(), y = p:getY() }
local px, py = math.floor(p:getX()), math.floor(p:getY())
local wasOpen = { cw = CW.isOpen(), ww = WW.isOpen() }
local built = {}
local function bothShut()
    if CW.isOpen() then pcall(CW.toggle, pn) end
    if WW.isOpen() then pcall(WW.close) end
end
local function findInfo(full)
    local infos = SpriteConfigManager.GetObjectInfoList()
    for i = 0, infos:size() - 1 do
        local info = infos:get(i)
        local parent = info:getScript() and info:getScript():getParent()
        if parent and tostring(parent:getScriptObjectFullType()) == full then return info end
    end
end
-- the objects on the squares round (cx, cy), as a set
local function snapshot(cx, cy, r)
    local set = {}
    for y = cy - r, cy + r do
        for x = cx - r, cx + r do
            local sq = getCell():getGridSquare(x, y, 0)
            if sq then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do set[objs:get(i)] = true end
            end
        end
    end
    return set
end
local OFFSETS = { { 4, -4 }, { -4, -4 }, { 4, 4 }, { -4, 4 }, { 6, 0 }, { -6, 0 }, { 0, -6 }, { 0, 6 }, { 7, 3 }, { -7, 3 } }
-- builds the entity beside the character; returns the new objects (or nil, why)
local function build(full)
    local info = findInfo(full)
    if not info then return nil, "no entity info " .. full end
    for _, o in ipairs(OFFSETS) do
        local x, y = px + o[1], py + o[2]
        local before = snapshot(x, y, 2)
        p:setBuildCheat(true)
        local b = ISBuildIsoEntity:new(p, info, 1, ISInventoryPaneContextMenu.getContainers(p))
        b.buildCheat = true
        b.player = pn
        local sq = getCell():getGridSquare(x, y, 0)
        local ok, valid = pcall(function() b.sq = sq; return b:isValid(sq) end)
        if ok and valid then
            pcall(function() b:create(x, y, 0, false, nil) end)
            p:setBuildCheat(false)
            local after = snapshot(x, y, 2)
            local new = {}
            for obj in pairs(after) do if not before[obj] then new[#new + 1] = obj; built[#built + 1] = obj end end
            if #new > 0 then return new end
        end
        p:setBuildCheat(false)
    end
    return nil, "no room for " .. full
end
-- the game's station windows open now
local function gameWindows()
    local n, list = 0, {}
    local pl = ISEntityUI.players and ISEntityUI.players[pn]
    for _, w in pairs(pl and pl.windows or {}) do
        if w and w.instance then n = n + 1; list[#list + 1] = w.instance end
    end
    return n, list
end
local function closeGameWindows()
    local _, list = gameWindows()
    for _, inst in ipairs(list) do
        pcall(function() if inst.close then inst:close() else inst:removeFromUIManager() end end)
    end
end
onCleanup(function()
    closeGameWindows()
    pcall(ST.unbind, p)
    p:setBuildCheat(false)
    for _, obj in ipairs(built) do
        local sq = obj:getSquare()
        if sq then
            pcall(function() sq:transmitRemoveItemFromSquare(obj) end)
            pcall(function() sq:RemoveTileObject(obj) end)
        end
    end
    built = {}
    if wasOpen.cw and not CW.isOpen() then pcall(CW.toggle, pn) end
    if wasOpen.ww and not WW.isOpen() then pcall(WW.open, pn) end
end)

local FULLS = { "Base.ButcherHook", "Base.Log_Bench", "Base.Log_Stool", "Base.Log_Table", "Base.Other_Log_Stool" }
local current = { full = nil, objs = nil }

step(1, function()
    p:setGodMod(true)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    bothShut()
    -- (Nov 12 2026, test cleanup plan: "give it nails") the builds take nails; whatever is left is taken back
    local nails = {}
    for _ = 1, 40 do local it = p:getInventory():AddItem("Base.Nails"); if it then nails[#nails + 1] = it end end
    onCleanup(function()
        for _, it in ipairs(nails) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    end)
end)

for _, full in ipairs(FULLS) do
    local short = full:gsub("^Base%.", "")
    step(25, function()
        current.full, current.objs = full, nil
        local objs, why = build(full)
        if not objs then say("not run: " .. short .. " (not built here: " .. tostring(why) .. ")"); return end
        current.objs = objs
        local names = {}
        for _, o in ipairs(objs) do names[#names + 1] = tostring(o:getClass():getSimpleName()) end
        say("NOTE " .. short .. ": built " .. #objs .. " object(s): " .. table.concat(names, ","))
    end)
    step(20, function()
        local objs = current.objs
        if not objs or current.full ~= full then return end
        bothShut()
        closeGameWindows()
        local opened = 0
        local general, plain = nil, nil
        for _, o in ipairs(objs) do
            local ent = ST.call(o, "getMasterObject") or o
            local kind = ST.classify(ent, true)
            local kind2 = ST.classify(ent)
            if kind then general = kind end
            if kind2 then plain = kind2 end
            local okc = pcall(function() return ISEntityUI.CanOpenWindowFor(p, o) end)
            if okc and ISEntityUI.CanOpenWindowFor(p, o) then
                local ok, e = pcall(ISEntityUI.OpenWindow, p, o)
                if not ok then say("ERR OpenWindow " .. short .. ": " .. tostring(e)) end
                opened = opened + 1
                break
            end
        end
        say("NOTE " .. short .. ": ZeD classifies it as general=" .. tostring(general) .. ", plain=" .. tostring(plain) .. "; station option called: " .. tostring(opened > 0))
        current.called = opened > 0
        current.kinds = { general, plain }
    end)
    step(15, function()
        if not current.objs or current.full ~= full then return end
        local n = gameWindows()
        local bound = ST.current(p)
        check(bound == nil, short .. ": ZeD bound no station (" .. tostring(bound and bound.kind) .. ")")
        check(not (WW.isOpen() and WW.isTabShowing("craft")), short .. ": the World window's Craft tab did not open")
        check(not (current.kinds and current.kinds[1] == "general"), short .. ": ZeD does not draw its general card for it")
        say("NOTE " .. short .. ": the game's own window is up: " .. tostring(n > 0))
        closeGameWindows()
        pcall(ST.unbind, p)
        bothShut()
    end)
end
step(10, function() end)

ticker = onTick
Events.OnTick.Add(ticker)
say("start")
