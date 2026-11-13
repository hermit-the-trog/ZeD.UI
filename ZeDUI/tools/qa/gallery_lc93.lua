-- ZeDUI/tools/qa/gallery_lc93.lua  (Nov 13 2026, QA; Lua Console 93 gallery shots, see the README beside its preview)
-- The plain game with -debug, Lua Console 93 on, ZeD-GUI off, three dev-only stand-in mods (Zomboid/mods/LC93Demo*:
-- Trail Markers, Camp Stove Plus, Radio Logbook) that print, warn and throw real errors from their own files.
-- Stages and shoots, at the game's size:
--   lc93_shot1_log_filters  the log with the mods' prints, a warning and errors; the MOD filter open, Radio Logbook
--                           unticked; a search typed in; the count in view
--   lc93_shot2_error_open   Trail Markers' error (x3) opened to its stack, picked
--   lc93_shot3_scratchpad   the scratchpad with a few lines, SNIPPETS and HISTORY open, the run's prints above
--   lc93_shot4_suggestions  getPlayer(): with the Java methods
--   lc93_shot5_commands     the Commands page as a host's admin sees it (CC.qaServer/qaRole: the same list and levels
--                           Lua Console 93 shows on a server), a command picked, the chat line filled
-- With LC93_GALLERY_DECK set (gallery_lc93_deck.lua), only the log for shot 6, at the window's size.
-- Snippets and history are put back afterwards. grep "ZEDQA lc93g".
local TAG = "lc93g"
-- (the console shows every print: notes wait in a list and are printed after the last shot)
local notes = {}
local function say(s) notes[#notes + 1] = "ZEDQA " .. TAG .. " " .. tostring(s) end
local function flushNotes() for _, n in ipairs(notes) do print(n) end; notes = {} end
local DC = LC93 and LC93.DebugConsole
local L = LC93 and LC93.ConsoleLog
local S = LC93 and LC93.ConsoleScratch
local CC = LC93 and LC93.ConsoleCommands
if not (DC and L and S and CC) then say("ERR Lua Console 93 is not loaded"); say("DONE"); flushNotes(); return end
local deck = LC93_GALLERY_DECK == true
local function shot(n) pcall(function() getCore():TakeFullScreenshot("lc93_" .. n .. ".png") end); say("shot " .. n) end

local Q, qi, qc = {}, 1, 0
local function step(wait, fn) Q[#Q + 1] = { wait = wait, fn = fn } end
local cleanups = {}
local ticker
local function finish()
    for i = #cleanups, 1, -1 do local ok, e = pcall(cleanups[i]); if not ok then say("ERR cleanup " .. i .. ": " .. tostring(e)) end end
    say("DONE")
    flushNotes()
end
local function onTick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(ticker); finish(); return end
    qc = qc + 1
    if qc >= s.wait then
        qi = qi + 1; qc = 0
        local ok, e = pcall(s.fn)
        if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(e)) end
    end
end

local jc = DC.game()
local function flag(v) pcall(function() jc:setVisible(v) end) end
local function win() return DC.win end
local function search(q) local w = win(); if w and w.find then w.find:setText(q) end end
local RADIO = "Radio Logbook"
local PADCODE = "local p = getPlayer()\nlocal inv = p:getInventory()\nprint(\"Carrying \" .. inv:getItems():size() .. \" items\")\nprint(\"Standing at \" .. math.floor(p:getX()) .. \", \" .. math.floor(p:getY()))"
-- every capability granted (a host's admin): CC.can then never asks the player's role, which single player lacks
local ALLCAPS = setmetatable({}, { __index = function() return true end })

S.load()
local keptSnips, keptHist = {}, {}
for i, s in ipairs(S.snippets) do keptSnips[i] = { name = s.name, code = s.code } end
for i, c in ipairs(S.history) do keptHist[i] = c end
cleanups[#cleanups + 1] = function()
    CC.qaServer, CC.qaRole, CC.qaCaps = nil, nil, nil
    S.snippets, S.history = keptSnips, keptHist
    S.rev = S.rev + 1
    S.writeSnippets(); S.writeHistory()
    if not L.isOn("mod", RADIO) then L.toggle("mod", RADIO) end
    local w = win()
    if w then
        search("")
        w:setMode("line"); w:setPage("log")
        pcall(function() w.input:setText(""); w.input:unfocus() end)
        pcall(function() w.cq:setText(""); w.chat:setText("") end)
        w.csel, w.pick, w.ac = nil, nil, nil
    end
    DC.mirror("")
end

-- open, a clean log, the mods' lines
step(1, function()
    -- (no warning row: DebugLog.General:warn is not reachable from Lua, Nov 13; a failed try still logs an error)
    local p = getPlayer()
    if p then p:setGodMod(true) end
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    flag(false)
end)
step(20, function() flag(true) end)
step(30, function()
    say("NOTE open " .. tostring(DC.isOpen()) .. ", window " .. tostring(win() and win():getWidth()) .. "x" .. tostring(win() and win():getHeight()))
    DC.clear(); L.showAll()
    local w = win()
    if w then w.fold = {} end
end)
step(10, function()
    if TrailMarkers then TrailMarkers.qaDemo() else say("NOTE Trail Markers is not loaded") end
    if CampStovePlus then CampStovePlus.qaDemo() else say("NOTE Camp Stove Plus is not loaded") end
    if RadioLogbook then RadioLogbook.qaDemo() else say("NOTE Radio Logbook is not loaded") end
    DC.run('print("Kentucky time: " .. getGameTime():getHour() .. ":00")')
end)
step(90, function()
    local n, total, errs = L.counts()
    say("NOTE rows shown " .. tostring(n) .. " of " .. tostring(total) .. ", errors " .. tostring(errs))
    for i = 1, n do
        local r = L.shownAt(i)
        say("NOTE row " .. r.kind .. " | " .. L.modName(r.mod) .. " | " .. L.srcOf(r) .. " | " .. tostring(r.msg):sub(1, 90) .. (r.n and (" | x" .. r.n) or ""))
    end
end)

if deck then
    step(30, function() shot("shot6_deck") end)
else
    -- 1. the filters, one mod unticked, a search
    step(5, function()
        if L.isOn("mod", RADIO) then L.toggle("mod", RADIO) end
        search("load")
    end)
    step(40, function()
        local n, total = L.counts()
        say("NOTE shot 1: " .. tostring(n) .. " of " .. tostring(total) .. " shown")
        shot("shot1_log_filters")
    end)
    -- 2. Trail Markers' error opened
    step(10, function()
        search("")
        L.toggle("mod", RADIO)
        local w = win()
        local err = nil
        for i = L.first, L.last do
            local r = L.rows[i]
            if r and r.kind == "error" and L.modName(r.mod) == "Trail Markers" then err = r end
        end
        say("NOTE Trail Markers error: " .. tostring(err and err.msg) .. " x" .. tostring(err and err.n) .. " at " .. tostring(err and L.srcOf(err)))
        if w and err then w.pick = err; w:toggleOpen(err); w.seek = true end
    end)
    -- (the log scrolls from its foot: all the way up puts the older rows on top, the opened error's line under them)
    step(5, function() local w = win(); if w then w.scroll = 100000 end end)
    step(35, function() shot("shot2_error_open") end)
    -- 3. the scratchpad
    step(10, function()
        local w = win()
        if w and w.pick and w.opened[w.pick.id] then w:toggleOpen(w.pick) end
        if w then w.pick = nil end
        S.snippets = {
            { name = "where am I", code = "local p = getPlayer()\nprint(math.floor(p:getX()), math.floor(p:getY()), p:getZ())" },
            { name = "count zombies", code = "print(getCell():getZombieList():size() .. \" zombies loaded\")" },
            { name = "heal me", code = "getPlayer():getBodyDamage():RestoreToFullHealth()" },
        }
        S.history = { "print(getGameTime():getDay())", "getPlayer():getStats():getHunger()" }
        S.rev = S.rev + 1
        w.scroll = 0
        w:press("topad")
        w.sFold = {}
        w:_padSet(PADCODE)
    end)
    -- (a run empties the box: the same code goes back in for the picture)
    step(10, function() win():runPad() end)
    step(10, function() win():_padSet(PADCODE) end)
    step(50, function() shot("shot3_scratchpad") end)
    -- 4. the suggestions
    step(10, function()
        local w = win()
        w:setMode("line")
        local s = "getPlayer():"
        w.input:focus()
        w.input:setText(s)
        pcall(function() w.input.javaObject:setCursorPos(#s) end)
    end)
    step(40, function()
        local w = win()
        say("NOTE suggestions: " .. tostring(w.ac and #w.ac.items) .. " rows, java " .. tostring(w.ac and w.ac.java) .. ", more " .. tostring(w.ac and w.ac.more))
        shot("shot4_suggestions")
    end)
    -- 5. the Commands page, a host's admin
    step(10, function()
        local w = win()
        pcall(function() w.input:setText(""); w.input:unfocus() end)
        w.ac = nil
        CC.qaServer, CC.qaRole, CC.qaCaps = true, "Admin", ALLCAPS
        w:setPage("cmds")
    end)
    step(15, function()
        local w = win()
        local c = CC.byName.servermsg or CC.byName.additem
        w:cmdPick(c)
        local t = ""
        pcall(function() t = w.chat:getText() end)
        if t == "" then pcall(function() w.chat:setText(c.ex or '/servermsg "Restart in 10 minutes"') end) end
        pcall(function() say("NOTE picked " .. tostring(w.csel) .. ", chat line '" .. tostring(w.chat:getText()) .. "'") end)
    end)
    step(40, function() shot("shot5_commands") end)
end

ticker = onTick
Events.OnTick.Add(ticker)
