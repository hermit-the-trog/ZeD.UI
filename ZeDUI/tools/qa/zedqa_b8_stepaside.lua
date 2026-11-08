-- ZeDUI/tools/qa/zedqa_b8_stepaside.lua  (Nov 7 2026, QA; tag b8sa): step aside with Wounds Overhaul (3775026731), in whichever
-- load order the run uses (zedqa_mods_run.ps1 -ZeDFirst or not; the order is read from the game's mod list and printed).
-- CHECK_step_aside_20261107.md. Run it right after zedqa_prelude.lua (b8_wo_manifest.txt does).
--   1. within ~8 s of the game's start ZeD has handed Character info back: ZeD_StepAside's record says set=charinfo by
--      WoundsOverhaul, nothing else handed back, ZeD setup's Character info switch is ticked (value 2), the other switches
--      are not, Safe.on("charinfo") is true, Zomboid/Lua/ZeD_step_aside.txt has the set= line
--   2. one unread notice in Messages under "ZeD screens" naming the mod and "character info"; ZeD setup's "Taken by" line
--      (ZeD.StepAside.underFor) names the mod
--   3. the Health key (the game's own key handler) opens the GAME's Character Info window on its Health page and not ZeD's
--      Character window; the second press shuts it; picture
--   4. the Messages bubble (the toast out of the belt's Messages note; replayed for the picture when the first has gone) and
--      the Messages window on "ZeD screens", pictured
--   5. the take-back: the switch unticked, within ~5 s the record says kept=charinfo|WoundsOverhaul and no set, the file has
--      the kept= line, "Taken by" is gone, no second notice, the Health key is ZeD's again (picture); a second
--      StepAside.check() (what the next start does) does not hand it back again
--   6. PUT BACK: the switch ticked again, ZeD_step_aside.txt written back as it was at step 1, the record reloaded from it,
--      the notice's read flag as it was. (The batch also puts the file back around the whole run.)
-- The console should hold "[ZeD] Step aside: Wounds Overhaul [B42] took charinfo; handed back to the game" (the runner reads
-- the console; the expect line below is for the report). ZeD setup itself is a main-menu screen: its "Taken by" line is
-- pictured by hand (CHECK_step_aside_20261107.md). grep "ZEDQA b8sa"; shots zqa_b8sa_*.png.
local function say(s) print("ZEDQA b8sa " .. tostring(s)) end
local p = getPlayer()
local fails = 0
local function check(ok, what)
    if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8sa_" .. n .. ".png") end) end
local CW, SA, MS, MW = ZeD_CharacterWindow, ZeD.StepAside, ZeD.Messages, ZeD.MessagesWindow
if not (p and CW and SA and MS and MW and ZeD.Settings and ZeD.Settings.screenOptions) then
    say("ERR ZeD's step aside, Messages or windows are not loaded")
    say("DONE")
    return
end

local Q, qi, waitT, tries = {}, 1, nil, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
-- fn returns true when ready; max tries (each n ticks apart); a timeout is a FAIL
local function untilDo(n, max, fn, what) Q[#Q + 1] = { n = n, fn = fn, tries = max, what = what } end

local FILE = "ZeD_step_aside.txt"
local MOD = "WoundsOverhaul"
local HEAD = ZeD.tr("UI_ZeD_StepAside_Head")
local opt = ZeD.Settings.screenOptions.charinfo
local function readLines()
    local r = getFileReader(FILE, false)
    if not r then return nil end
    local t = {}
    pcall(function()
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
    end)
    pcall(function() r:close() end)
    return t
end
local function fileHas(prefix)
    for _, l in ipairs(readLines() or {}) do
        if l:sub(1, #prefix) == prefix then return l end
    end
    return nil
end
local function writeLines(t)
    local w = getFileWriter(FILE, true, false)
    if not w then return false end
    pcall(function() w:write(table.concat(t, "\r\n") .. "\r\n") end)
    pcall(function() w:close() end)
    return true
end
local function saveOptions()
    if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.save then pcall(PZAPI.ModOptions.save, PZAPI.ModOptions) end
    if ZeD.Safe.reread then pcall(ZeD.Safe.reread) end
end
local function vanillaShown() local v = getPlayerInfoPanel(0); return v ~= nil and v:getIsVisible() == true end
local function routes() return ZeD.CharInfoRoute and ZeD.CharInfoRoute.count or 0 end
local function healthKey()
    local id = KeybindId and KeybindId.TOGGLE_HEALTH_PANEL
    local key = id and getCore():getKey(id) or 0
    if key == 0 then return false end
    xpUpdate.displayCharacterInfo(key)
    return true
end
local function setCount(rec) local n = 0; for _ in pairs(rec.set or {}) do n = n + 1 end; return n end
local function activeOrder()
    local list, zi, wi = getActivatedMods(), nil, nil
    for i = 0, list:size() - 1 do
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == "ZeD_UI" then zi = i elseif id == MOD then wi = i end
    end
    return zi, wi
end

local origLines, origValue, origRead, noticeCount
local order = "?"

-- 0. the mods, and the hand-back (the check runs about 30 ticks into the game, at most 5 s)
step(5, function()
    local zi, wi = activeOrder()
    order = (zi and wi) and ((zi < wi) and "ZeD first" or "ZeD last") or "?"
    say("load order: " .. order .. " (ZeD_UI at " .. tostring(zi) .. ", Wounds Overhaul at " .. tostring(wi) .. ")")
    check(wi ~= nil, "Wounds Overhaul is on in this game")
    check(type(Wounds) == "table", "Wounds Overhaul's Lua is loaded")
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if CW.isOpen() then CW.toggleBothPaired(0) end
end)
untilDo(10, 60, function()
    local rec = SA.record()
    return rec and rec.set and rec.set.charinfo ~= nil
end, "ZeD handed Character info back within ~10 s of the game's start (" .. "set=charinfo in the record)")

step(10, function()
    local rec = SA.record()
    local s = rec.set.charinfo
    check(s ~= nil and s.id == MOD, "the record names Wounds Overhaul as the one that took Character info (" .. tostring(s and s.id) .. ", " .. tostring(s and s.name) .. ")")
    check(setCount(rec) == 1, "exactly one screen handed back (" .. setCount(rec) .. ")")
    check(opt:getValue() == 2, "ZeD setup's Character info switch is ticked (value " .. tostring(opt:getValue()) .. ")")
    local others = {}
    for name, o in pairs(ZeD.Settings.screenOptions) do
        if name ~= "charinfo" and o:getValue() == 2 then others[#others + 1] = name end
    end
    check(#others == 0, "no other screen switch is ticked (" .. table.concat(others, ",") .. ")")
    check(ZeD.Safe.on("charinfo") == true, "ZeD.Safe.on(charinfo) is true")
    check(fileHas("set=charinfo|" .. MOD .. "|") ~= nil, "ZeD_step_aside.txt has set=charinfo|" .. MOD .. " (" .. tostring(fileHas("set=")) .. ")")
    -- the state to put back at the end
    origLines, origValue = readLines(), opt:getValue()
    say("saved for the end: " .. tostring(origLines and #origLines) .. " file lines, switch " .. tostring(origValue))
    say("(expect [ZeD] Step aside: Wounds Overhaul [B42] took charinfo; handed back to the game)")
    -- the notice
    local src = MS.sources[HEAD]
    noticeCount = src and #src.items or 0
    check(src ~= nil and #src.items == 1, "one notice under '" .. tostring(HEAD) .. "' in Messages (" .. tostring(noticeCount) .. ")")
    local it = src and src.items[1]
    origRead = it and it.read
    check(it ~= nil and it.read == false, "the notice is unread")
    local txt = it and it.text or ""
    check(txt:find("Wounds Overhaul", 1, true) ~= nil and txt:find("character info", 1, true) ~= nil,
        "the notice names the mod and 'character info'")
    say("notice text: " .. txt)
    local n = MS.unread()
    check(n >= 1, "Messages counts unread notes (" .. tostring(n) .. ")")
    local under = SA.underFor("charinfo")
    check(under ~= nil and under:find("Wounds Overhaul", 1, true) ~= nil, "ZeD setup's line under the switch: '" .. tostring(under) .. "'")
    say("(manual: ZeD setup is a main-menu screen; its 'Taken by' line is pictured by hand)")
end)

-- 1. the Health key: the game's window, not ZeD's
step(20, function()
    if CW.isOpen() then CW.toggleBothPaired(0) end
    if vanillaShown() then getPlayerInfoPanel(0):setVisible(false) end
end)
local routeBefore
step(30, function()
    routeBefore = routes()
    check(healthKey(), "the Health key is bound")
end)
untilDo(10, 30, function() return vanillaShown() end, "the game's Character Info window shows after the Health key")
step(40, function()
    local v = getPlayerInfoPanel(0)
    local page = v and v.panel and v.panel.activeView and v.panel.activeView.name
    check(vanillaShown() and not CW.isOpen() and routes() == routeBefore,
        "the Health key opened the GAME's window, not ZeD's (game's window " .. tostring(vanillaShown()) .. ", ZeD's open " .. tostring(CW.isOpen()) .. ", routed " .. (routes() - routeBefore) .. ")")
    say("the game's window is on the page '" .. tostring(page) .. "'")
    shot("healthkey")
end)
step(20, function() healthKey() end)
untilDo(10, 30, function() return not vanillaShown() end, "a second Health key shuts the game's window")

-- 2. the Messages bubble and the window
step(20, function()
    local alive = false
    local now = getTimestampMs()
    for _, t in ipairs(MS.toasts or {}) do
        if t.head == HEAD and (t.untilMs or 0) > now + 2000 then alive = true end
    end
    if not alive then
        local it = MS.sources[HEAD] and MS.sources[HEAD].items[1]
        MS.toasts = MS.toasts or {}
        MS.toasts[#MS.toasts + 1] = { kind = "warn", head = HEAD, source = HEAD, text = it and it.text or "", untilMs = now + 6000 }
        say("the first toast had gone: replayed for the picture")
    end
end)
step(25, function() shot("bubble") end)
step(10, function()
    local win = MW.open(0, HEAD)
    say("MW.open returned a window: " .. tostring(win ~= nil) .. ", really visible at once: " .. tostring(win ~= nil and win:isReallyVisible()))
end)
step(10, function()
    -- (Nov 8 QA) checked a few frames after the open: a window just added to the UI manager is not "really visible" in the same frame
    local win = MW.get(0)
    check(win ~= nil and win:isReallyVisible(), "the Messages window opens on '" .. tostring(HEAD) .. "'")
end)
step(30, function() shot("messages") end)
step(10, function()
    local win = MW.get(0)
    if win then win:close() end
    -- the picture opened the notice: unread again, as it was
    local it = MS.sources[HEAD] and MS.sources[HEAD].items[1]
    if it and origRead ~= nil then it.read = origRead end
end)

-- 3. the take-back: untick; the record follows within a second or two
step(20, function()
    opt:setValue(1)
    saveOptions()
    say("ticked off by the script (the player's untick)")
end)
untilDo(20, 40, function()
    local rec = SA.record()
    return rec.kept and rec.kept.charinfo ~= nil
end, "within ~13 s the record notes the take-back (kept=charinfo)")
step(20, function()
    local rec = SA.record()
    check(rec.kept.charinfo == MOD and rec.set.charinfo == nil, "kept=charinfo|" .. tostring(rec.kept.charinfo) .. ", no set (" .. tostring(rec.set.charinfo) .. ")")
    check(fileHas("kept=charinfo|" .. MOD) ~= nil, "ZeD_step_aside.txt has kept=charinfo|" .. MOD .. " (" .. tostring(fileHas("kept=")) .. ")")
    check(fileHas("set=charinfo") == nil, "and no set=charinfo line")
    check(SA.underFor("charinfo") == nil, "'Taken by' is gone from ZeD setup")
    check(ZeD.Safe.on("charinfo") ~= true, "ZeD.Safe.on(charinfo) is false again")
    local src = MS.sources[HEAD]
    check(src ~= nil and #src.items == noticeCount, "the take-back adds no notice (" .. tostring(src and #src.items) .. ")")
    if CW.isOpen() then CW.toggleBothPaired(0) end
    routeBefore = routes()
    healthKey()
end)
untilDo(10, 40, function() return CW.isOpen() end, "the Health key opens ZeD's Character window again")
step(60, function()
    local w = CW.getWindow()
    check(CW.isOpen() and not vanillaShown() and routes() > routeBefore,
        "the Health key is ZeD's again (tab " .. tostring(w and w._activeTab) .. ", game's window " .. tostring(vanillaShown()) .. ", routed " .. (routes() - routeBefore) .. ")")
    if w then w._autoShaded = false; if w.windowShaded then w:setWindowShaded(false) end; w._outSince = getTimestampMs() + 600000 end
    shot("takenback")
end)
step(20, function()
    -- what the next start does: the same check again must not take the screen back from the player
    pcall(SA.check)
end)
step(20, function()
    local rec = SA.record()
    check(opt:getValue() == 1 and rec.set.charinfo == nil and rec.kept.charinfo == MOD,
        "a second StepAside.check() leaves it with the player (switch " .. tostring(opt:getValue()) .. ", kept " .. tostring(rec.kept.charinfo) .. ")")
    local src = MS.sources[HEAD]
    check(src ~= nil and #src.items == noticeCount, "and says nothing more (" .. tostring(src and #src.items) .. " notices)")
    if CW.isOpen() then CW.toggleBothPaired(0) end
end)

-- 4. put back as it was
step(30, function()
    if origValue ~= nil then pcall(opt.setValue, opt, origValue) end
    saveOptions()
    if origLines then writeLines(origLines) end
    SA.reload()
    local rec = SA.record()
    local back = origValue == nil or (opt:getValue() == origValue)
    if origValue == 2 then back = back and rec.set.charinfo ~= nil and rec.kept.charinfo == nil end
    check(back, "put back: switch " .. tostring(opt:getValue()) .. ", record set=" .. tostring(rec.set.charinfo and rec.set.charinfo.id) .. ", kept=" .. tostring(rec.kept.charinfo))
    check(origLines == nil or (fileHas("set=charinfo|" .. MOD) ~= nil and fileHas("kept=") == nil), "ZeD_step_aside.txt is as it was at the start")
    local it = MS.sources[HEAD] and MS.sources[HEAD].items[1]
    if it and origRead ~= nil then it.read = origRead end
    say(fails == 0 and ("all checks passed (" .. order .. ")") or (fails .. " failed (" .. order .. ")"))
    say("DONE")
end)

-- a step's n is in 60ths of a second (wall clock; OnRenderTick runs while paused)
local function tick()
    local s = Q[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    waitT = waitT or (now + s.n * 1000 / 60)
    if now < waitT then return end
    waitT = nil
    local ok, res = pcall(s.fn)
    if not ok then
        fails = fails + 1; say("ERR step " .. qi .. ": " .. tostring(res)); qi = qi + 1; tries = 0
    elseif s.tries and res ~= true then
        tries = tries + 1
        if tries >= s.tries then fails = fails + 1; say("FAIL timed out: " .. tostring(s.what)); qi = qi + 1; tries = 0 end
    else
        if s.what then say("PASS " .. s.what) end
        qi = qi + 1; tries = 0
    end
end
Events.OnRenderTick.Add(tick)
say("start")
