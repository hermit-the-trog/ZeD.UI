-- ZeDUI/tools/qa/zedqa_b8_mp_leftovers.lua  (Nov 7 2026, QA; beta 8): on the ADMIN client, CHECK_mp_leftovers_20261107.md, the parts a real server and one real
-- second player can answer (bob on the server; the kick and the kicked screen are zedqa_b8_mp_kick.lua / zedqa_b8_mp_bob_leave.lua).
--   C1  the pause window's Players page: the rows, a pick, the admin's actions, Teleport, your own row
--   C2  the Server tab's options card, and an option changed on the server shows up (put back after)
--   C4  the server-saving notice: one entry in Messages under Server, updated in place by the second save
--   C15 the admin's Edit item card on an axe: opens as a card, a Save with nothing changed changes nothing
--   C16 an admin message as a note in Messages with a place, and the note's Teleport
-- C3 (Steam invite), C5 (map mark sharing: needs a mark on the map), the pad walks, the 4K and Deck pictures and the look of every
-- card are manual. grep "ZEDQA b8lo". Pictures: zqa_b8_lo_*.png.
local TAG = "b8lo"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local npass, nfail = 0, 0
local function check(ok, what, d)
    ok = ok and true or false
    if ok then npass = npass + 1 else nfail = nfail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (d ~= nil and (" (" .. tostring(d) .. ")") or ""))
end
local function note(s) say("NOTE " .. tostring(s)) end
local function manual(s) say("MANUAL " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8_" .. n .. ".png") end) end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
local function has(s, w) return type(s) == "string" and w ~= nil and string.find(string.lower(s), string.lower(w), 1, true) ~= nil end
local function keepDown() pcall(function()
    for _, get in ipairs({ ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow, ZeD_WorldWindow and ZeD_WorldWindow.getWindow }) do
        local w = get and get()
        if w then w._autoShaded = false; if w.windowShaded and w.setWindowShaded then w:setWindowShaded(false) end; w._outSince = getTimestampMs() + 600000 end
    end
end) end
local plan, pi, pt = {}, 1, getTimestampMs()
local ins = nil
local function push(e) if ins then table.insert(plan, ins, e); ins = ins + 1 else plan[#plan + 1] = e end end
local function add(ms, fn) push({ ms = ms, fn = fn }) end
local function ticks(n, fn) push({ ticks = n, fn = fn }) end
local function waitFor(maxMs, cond, fn) push({ cond = cond, max = maxMs, fn = fn }) end
local function drive()
    local st = plan[pi]
    if not st then return end
    local now = getTimestampMs()
    local timedOut = false
    if st.ticks then
        st.ticks = st.ticks - 1
        if st.ticks > 0 then return end
    elseif st.cond then
        if not st.started then st.started = now end
        local ok, v = pcall(st.cond)
        if not (ok and v) and now - st.started < st.max then return end
        timedOut = not (ok and v)
    elseif now - pt < st.ms then return end
    pt = now
    pi = pi + 1
    keepDown()
    ins = pi
    local ok, e = pcall(st.fn, timedOut)
    ins = nil
    if not ok then nfail = nfail + 1; say("FAIL ERR step " .. (pi - 1) .. ": " .. tostring(e)) end
    if pi > #plan then
        say(npass .. " passed, " .. nfail .. " failed")
        say("DONE")
        Events.OnTick.Remove(drive)
    end
end
local MM, PL, L = ZeD.MainMenu, ZeD.PausePlayers, ZeD.MpLeftovers
local MS = ZeD.Messages
local p = getPlayer()
local me = p:getUsername()
local function pauseUp()
    local m = MainScreen and MainScreen.instance
    return m and m:isVisible() and MM.pause ~= nil and MM.pause:isVisible()
end
local function spec(id)
    for _, s in ipairs(MM.pause and MM.pause._specs or {}) do if s.id == id then return s end end
    return nil
end
local function fire(id)
    local s = spec(id)
    if s and s.fn and not s.disabled then s.fn(); return true end
    return false
end

-- ---- C1
add(500, function()
    check(PL ~= nil and L ~= nil, "the leftovers files are loaded")
    local ok = pcall(function() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end)
    check(ok, "the pause screen opens")
end)
waitFor(8000, pauseUp, function(to)
    check(not to, "C1: the pause window is up", to and "not shown" or nil)
    if to then return end
    pcall(MM.act.players)
    pcall(PL.ask, true)
end)
waitFor(10000, function() return PL.list ~= nil and #PL.list >= 2 end, function(to)
    local o = {}
    for _, e in ipairs(PL.list or {}) do o[#o + 1] = e.user .. "/" .. tostring(e.ping) end
    note("the scoreboard: " .. table.concat(o, ", "))
    check(not to, "C1 1: the scoreboard's reply fills the Players list", #(PL.list or {}))
    check(MM.pause and MM.pause.page == "players", "C1 1: Players is a page of the pause window, not the game's scoreboard", MM.pause and MM.pause.page)
end)
add(1200, function()
    check(spec("pl:bob") ~= nil, "C1 3: bob has a row")
    check(spec("pl:" .. me) ~= nil, "C1 4: the admin has a row of their own")
    ticks(30, function() shot("lo_players") end)
    fire("pl:bob")
end)
add(1500, function()
    local o = {}
    for _, id in ipairs({ "act:tp", "act:kick", "act:ban", "act:banip", "act:mute", "act:voip" }) do o[#o + 1] = id .. "=" .. tostring(spec(id) ~= nil) end
    note("actions for bob: " .. table.concat(o, " "))
    check(spec("act:kick") ~= nil and spec("act:ban") ~= nil, "C1 3: Kick and Ban show for the admin")
    check(spec("act:tp") ~= nil, "C1 3: Teleport shows for the admin")
    check(spec("act:mute") ~= nil, "C1 2: Mute shows for another player")
    ticks(30, function() shot("lo_players_bob") end)
    fire("pl:" .. me)
end)
add(1500, function()
    check(spec("act:kick") == nil and spec("act:mute") == nil, "C1 4: your own row has no Kick and no Mute")
    pcall(function() MM.pause:joyB() end)
end)
add(1500, function()
    check(MM.pause and MM.pause.page ~= "players", "C1 5: B goes back to the pause list", MM.pause and MM.pause.page)
    pcall(MM.act.resume)
end)
add(2500, function()
    manual("C1 2: bob muting the admin, then the admin typing in chat; C1 3: Kick/Ban from the pause page opens the Admin tab's Player card (zedqa_b8_mp_kick.lua does the kick itself); C1 6 to 8: pad, long list, Large text")
end)

-- ---- C2
local S = ZeD.ServerTab
local optName, optWas
add(800, function()
    ZeD_CharacterWindow.openTab(0, "server")
end)
add(2000, function()
    local win = ZeD_CharacterWindow.getWindow()
    local st = win and win._serverTab
    check(st ~= nil, "C2 1: the Server tab has its state")
    if st then S.openOptions(win, st) end
end)
add(2500, function()
    local win = ZeD_CharacterWindow.getWindow()
    local st = win and win._serverTab
    check(st and st.card and st.card.kind == "srvopts", "C2 1: the Server tab shows the options card", st and st.card and st.card.kind)
    local rows = safe(function() return S.optionsData(st.card) end, nil)
    check(rows ~= nil and #rows > 10, "C2 1: one row per option", rows and #rows)
    optName = "ShowFirstAndLastName"
    optWas = safe(function() return getServerOptions():getBoolean(optName) end, nil)
    local v
    for _, r in ipairs(rows or {}) do if r.name == optName then v = r.value end end
    note(optName .. " on the card reads '" .. tostring(v) .. "', the game says " .. tostring(optWas))
    check(v ~= nil, "C2 1: the option is a row")
    ticks(30, function() shot("lo_options") end)
    if optWas ~= nil then SendCommandToServer('/changeoption ' .. optName .. ' "' .. tostring(not optWas) .. '"') end
end)
add(7000, function()
    local win = ZeD_CharacterWindow.getWindow()
    local st = win and win._serverTab
    local rows = st and st.card and safe(function() return S.optionsData(st.card) end, nil)
    local v
    for _, r in ipairs(rows or {}) do if r.name == optName then v = r.value end end
    local now = safe(function() return getServerOptions():getBoolean(optName) end, nil)
    check(optWas ~= nil and now == (not optWas), "C2 5: the game's own copy followed the change", tostring(now))
    note("the card now reads '" .. tostring(v) .. "'")
    ticks(30, function() shot("lo_options_changed") end)
    if optWas ~= nil then SendCommandToServer('/changeoption ' .. optName .. ' "' .. tostring(optWas) .. '"') end
end)
add(6000, function()
    local now = safe(function() return getServerOptions():getBoolean(optName) end, nil)
    check(now == optWas, "C2: the option is put back", tostring(now))
    local win = ZeD_CharacterWindow.getWindow()
    local st = win and win._serverTab
    if st then st.card = nil end
    manual("C2 2 to 4: a plain user sees no Change; the Admin tab's More tools row opens the same card; D-pad steps down the rows")
end)

-- ---- C4
local srvName = ZeD.tr("UI_ZeD_Srv_Server")
local function srvItems()
    local s = MS and MS.sources and MS.sources[srvName]
    local n, first = 0, nil
    for _, it in ipairs(s and s.items or {}) do if it.k == "server" and it.id == "saving" then n = n + 1; first = first or it end end
    return n, first
end
add(800, function()
    check(MS ~= nil and MS.serverNote ~= nil, "C4: Messages has the server note")
    L.savingStart()
    L.savingDone()
end)
add(1500, function()
    local n, it = srvItems()
    check(n == 1, "C4 1: the saving notice is one entry in Messages under Server", n)
    check(it ~= nil and has(it.text, "saving"), "C4 1: it carries the game's words", it and it.text)
    ticks(30, function() shot("lo_saving") end)
    L.savingStart()
end)
add(1200, function()
    local n = srvItems()
    check(n == 1, "C4 1: the next save updates that entry, no second one", n)
    check(not L.savingVanilla, "C4 1: the game's box with Spiffo was not used")
    manual("C4 1: the real save from the server console (save) and the bubble out of the belt's Messages icon; C4 2: safe mode gives the game's box")
end)

-- ---- C15: Edit item
local axe, spy
local function axeFound()
    local l = p:getInventory():getItems()
    for i = 0, l:size() - 1 do if l:get(i):getType() == "Axe" then return l:get(i) end end
    return nil
end
add(500, function() if not axeFound() then SendCommandToServer('/additem "' .. me .. '" "Base.Axe" 1') end end)
waitFor(12000, function() axe = axeFound(); return axe ~= nil end, function(to)
    check(not to, "C15: an axe to edit", to and "none" or nil)
    if not axe then return end
    local FC = ZeD.FormCard
    local base = FC.open
    FC.open = function(sp) local c = base(sp); spy = { card = c, spec = sp }; return c end
    local was = { name = axe:getName(), weight = axe:getActualWeight(), cond = axe:getCondition() }
    axe._b8was = was
    local ok = L.openItemEditor(p, axe)
    FC.open = base
    check(ok == true, "C15 1: Edit item opens a card (not the game's panel)", tostring(ok))
    check(spy ~= nil and spy.card ~= nil, "C15 1: the card is a FormCard")
    ticks(30, function() shot("lo_edititem") end)
end)
add(1500, function()
    if not (spy and spy.card and axe) then return end
    -- Save with nothing changed: every field stays exactly as it was
    local buttons = safe(function() return spy.spec.band(spy.card).buttons end, {})
    local save
    for _, b in ipairs(buttons) do if b.id == "save" then save = b end end
    check(save ~= nil, "C15 2: the card has a Save button")
    if save then pcall(save.run, spy.card) end
end)
add(2000, function()
    if not axe or not axe._b8was then return end
    local w = axe._b8was
    check(axe:getName() == w.name, "C15 2: the name is as it was", axe:getName())
    check(math.abs(axe:getActualWeight() - w.weight) < 0.0001, "C15 2: the weight keeps its full figure", axe:getActualWeight())
    check(axe:getCondition() == w.cond, "C15 2: the condition is as it was", axe:getCondition())
    if spy and spy.card and not spy.card._done then pcall(function() spy.card:finish() end) end
    manual("C15 2 to 5: a changed name and condition, a negative Hunger on food, the Color row's picker on a dyed shirt, Cancel, the pad keyboard, another player's item")
end)

-- ---- C16
local tx, ty
add(800, function()
    tx, ty = math.floor(p:getX()), math.floor(p:getY())
    local it = L.adminMessage("<RGB:1,0,0>Server restarts soon <LINE> please finish up", tx + 6, ty, 0)
    check(it == true, "C16 1: the admin message went to Messages as a note", tostring(it))
end)
add(1000, function()
    local name = ZeD.tr("UI_ZeD_Adm_NoteHead")
    local s = MS and MS.sources and MS.sources[name]
    local last
    for _, it in ipairs(s and s.items or {}) do if it.k == "adminmsg" then last = it; break end end
    if not last and s and s.items then last = s.items[#s.items] end
    check(last ~= nil and has(last.text, "restarts soon") and not has(last.text, "<"), "C16 1: the note has the plain words", last and last.text)
    check(last ~= nil and last.tp ~= nil and last.tp.x == tx + 6, "C16 2: the note carries the place", last and last.tp and last.tp.x)
    ticks(30, function() shot("lo_adminmsg") end)
    if last and last.tp then L.teleport(last.tp) end
end)
add(5000, function()
    check(math.abs(p:getX() - (tx + 6)) < 3, "C16 2: Teleport on the note takes the admin to the place", string.format("%.1f vs %d", p:getX(), tx + 6))
    SendCommandToServer("/teleportto " .. tx .. "," .. ty .. ",0")
    manual("C16 1: a real admin message from the server (a ticket sent to a client without AnswerTickets); C16 3: safe mode gives the pop-up")
end)
Events.OnTick.Add(drive)
