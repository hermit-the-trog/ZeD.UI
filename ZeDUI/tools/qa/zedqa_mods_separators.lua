-- ZeDUI/tools/qa/zedqa_mods_separators.lua  (Oct 31 2026)
-- Main menu QA for separators in the load order (MOD_FOLDERS_SPEC.md 7, 8, 10, 11; punch lists 37
-- and 41, stage 3):
--   1. order follows position: each mod loads in its separator's place; a mod new to the list goes
--      under the last separator; Auto sorts inside each section and never across a separator
--   2. moving a separator moves its mods with it
--   3. a separator turned off turns its mods off; they keep their places (dimmed rows) and come
--      back on in the same places when it is turned on
--   4. separators survive the profile file (names as hex per UTF-16 unit, on / off, collapsed),
--      a profile save and load, and Auto
--   5. "Start separators from folders" places only the mods that are on, in the folders' order,
--      then Unfiled; nothing turns on or off
--   6. folders untouched by separator changes, and separators untouched by folder changes
--   7. the game's own list (what mods.txt gets) holds only mod ids, never a separator
-- Part 1 and the file part of 4 run on made-up mods (ZeD.ModOrder alone); the rest need at least
-- four mods on: run with compat_r4_mods.txt.
-- Works on its own folders file (ZeD.ModFolders.FILE pointed at Lua/ZeDQA_ModFolders.cfg), never
-- the player's. Puts back: the profile file's text, the load order, every mod's on / off; deletes
-- its test profile; leaves through Discard changes (vanilla's NO), so nothing new is accepted.
--
-- Run (never while the game runs; checks Lua/zedqa.lock itself):
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/compat_r4_mods.txt `
--        -Script ZeDUI/tools/qa/zedqa_mods_separators.lua -Tag msp -TimeoutSec 300
-- Lines: "ZEDQA msp PASS ..." / "ZEDQA msp FAIL ..." / "ZEDQA msp SKIP ...", then a total and DONE.
local MM = ZeD.MainMenu
local O = ZeD.ModOrder
local F = ZeD.ModFolders
local function say(s) print("ZEDQA msp " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_msp_" .. n .. ".png") end) end
local pass, fail = 0, 0
local function check(ok, what)
    if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end
end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function W() return MM.root and MM.root.modsWin end
local function model() return ModSelector.instance.model end
local function jlist(l) local t = {}; if l then for i = 0, l:size() - 1 do t[#t + 1] = l:get(i) end end; return t end
local function idx(order, id) for i, x in ipairs(order) do if x == id then return i end end; return nil end
local function join(t) return table.concat(t or {}, ";") end

local PROFILE = "ZeDQA separators"
local TESTF = "ZeDQA_ModFolders.cfg"
local keep = {}

local function readRaw(name)
    local r = getFileReader(name, false)
    if not r then return nil end
    local t = {}
    local line = r:readLine()
    while line do t[#t + 1] = line; line = r:readLine() end
    r:close()
    return table.concat(t, "\n") .. "\n"
end
local function writeRaw(name, s)
    local w = getFileWriter(name, true, false)
    if w then w:write(s); w:close() end
end

-- what is on, as one text (Start separators from folders must never change it)
local function onSet()
    local on = {}
    for _, d in ipairs(model().sortedMods or {}) do if d.isActive then on[#on + 1] = d.modId end end
    return join(on)
end

-- the page's mods (in order) under separator uid
local function under(w, uid)
    local t = {}
    for _, id in ipairs(w.order) do if (w.oZone[id] or 2) == 2 and (w.oSec[id] or 0) == uid then t[#t + 1] = id end end
    return t
end

-- true when every section's mods sit together, in the separators' order
local function grouped(w)
    local k = O.secIndex(w.oLo)
    local last = 0
    for _, id in ipairs(w.order) do
        if (w.oZone[id] or 2) == 2 then
            local s = k[w.oSec[id] or 0] or 0
            if s < last then return false end
            last = s
        end
    end
    return true
end

local function fakeInfo(n)
    local I, order = {}, {}
    for i = 1, n do
        local id = "qa" .. i
        order[i] = id
        I[id] = { name = "QA Mod " .. i, req = {}, after = {}, before = {}, installed = true, hay = "qa mod " .. i .. " qa" .. i }
    end
    return I, order
end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    keep.raw = readRaw("ZeD_modprofiles.txt")
    keep.ffile = F.FILE
    F.FILE = TESTF
    writeRaw(TESTF, "")
    MM.openMods()
end)

-- 1 on made-up mods: places, a mod new to the list, Auto inside sections only, the off mods kept
at(15, function()
    local I = fakeInfo(8)
    local A = { uid = O.newUid(), name = "A", on = true, open = true, ids = { "qa3", "qa4", "qa5" } }
    local B = { uid = O.newUid(), name = "B", on = true, open = true, ids = { "qa6", "qa7" } }
    local C = { uid = O.newUid(), name = "C", on = true, open = true, ids = {} }
    local lo = { first = {}, last = {}, rules = {}, top = { "qa1", "qa2" }, seps = { A, B, C } }
    local out, zone, carried, sec = O.layout({ "qa6", "qa1", "qa3", "qa7", "qa2", "qa4", "qa5", "qa8" }, I, lo, false)
    check(join(out) == "qa1;qa2;qa3;qa4;qa5;qa6;qa7;qa8", "1a order follows the separators' places (" .. join(out) .. ")")
    check(sec.qa8 == C.uid, "1b a mod new to the list goes under the last separator")
    -- Auto: qa4 needs qa5 (same section: sorted), qa3 needs qa7 (a later section: stays, red)
    I.qa4.req = { "qa5" }
    I.qa3.req = { "qa7" }
    local auto, z2, _, s2 = O.layout(out, I, lo, true)
    check(idx(auto, "qa5") < idx(auto, "qa4") and s2.qa5 == A.uid and s2.qa4 == A.uid, "1c Auto sorts inside a section")
    check(s2.qa3 == A.uid and s2.qa7 == B.uid and idx(auto, "qa3") < idx(auto, "qa7"), "1d Auto never moves a mod across a separator")
    local res = O.check(auto, I, lo, z2)
    check(res.st[idx(auto, "qa3")] == "bad", "1e a mod that needs one under a later separator stays red")
    -- qa4 off: its place under A is kept
    local onOrder = {}
    for _, id in ipairs(auto) do if id ~= "qa4" then onOrder[#onOrder + 1] = id end end
    O.secSync(lo, onOrder, z2, s2)
    check(join(A.ids) == "qa3;qa4;qa5", "1f a mod turned off keeps its place under its separator (" .. join(A.ids) .. ")")
    -- 2 on made-up mods: B moved above A, its mods with it
    lo.seps = { B, A, C }
    local g = O.secGroup(auto, z2, s2, lo)
    check(idx(g, "qa6") < idx(g, "qa3") and idx(g, "qa7") < idx(g, "qa3") and idx(g, "qa1") < idx(g, "qa6"), "2a moving a separator moves its mods with it")
end)

-- 4 on the file: names as hex per UTF-16 unit, on / off, collapsed, members; unknown lines kept
at(20, function()
    O.load()
    local e = O.entry(PROFILE, true)
    e.order = { "qa1", "qa2", "qa3" }
    local name1 = string.char(0x5730, 0x56FE)
    e.top = { "qa1" }
    e.seps = { { uid = O.newUid(), name = name1, on = false, open = false, ids = { "qa2" } },
               { uid = O.newUid(), name = "a|b;c", on = true, open = true, ids = { "qa3", "qa9" } } }
    e.keep = { "sep=QA section|qa1;qa2", "zedqa_unknown=kept" }
    O.save()
    local raw = readRaw("ZeD_modprofiles.txt") or ""
    check(raw:find("sep=0|0|5730,56FE|qa2\n", 1, true) ~= nil, "4a a separator's line: off, collapsed, its name as hex per UTF-16 unit")
    check(raw:find("top=qa1\n", 1, true) ~= nil, "4b the mods above the first separator are kept")
    O.load()
    local e2 = O.entry(PROFILE)
    check(e2 and #e2.seps == 2 and e2.seps[1].name == name1 and e2.seps[2].name == "a|b;c", "4c names read back as written")
    check(e2 and e2.seps[1].on == false and e2.seps[1].open == false and join(e2.seps[2].ids) == "qa3;qa9", "4d on / off, collapsed and members read back")
    check(e2 and #e2.keep == 2, "4e lines ZeD does not know are kept")
    O.entries()[PROFILE] = nil
    O.save()
end)

-- live: the Load order page, two separators
at(30, function()
    local w = W()
    w:enterOrder("order")
    keep.order0 = {}
    for i, id in ipairs(w.order) do keep.order0[i] = id end
    keep.lo0 = O.getLo(w.oKey)
    keep.on0 = onSet()
    local mids = {}
    for i, id in ipairs(w.order) do if w.oZone[id] == 2 and id ~= "ZeD_UI" then mids[#mids + 1] = i end end
    keep.mids = #mids
    if #mids < 4 then say("SKIP 2 to 7 (fewer than 4 movable mods on: run with compat_r4_mods.txt)"); return end
    -- (any separators the list had go for the run; they come back with the profile file at the end)
    w.oLo.seps, w.oLo.top = {}, {}
    w:orderChanged()
    w.oSel = mids[2]
    w:sepNew("QA Alpha")
    keep.alpha = w.oSepSel
    w.oSepSel = nil
    w.oSel = mids[math.floor(#mids / 2) + 2] or mids[#mids]
    w:sepNew("QA Beta")
    keep.beta = w.oSepSel
    local a, b = under(w, keep.alpha), under(w, keep.beta)
    say("Alpha: " .. join(a) .. " | Beta: " .. join(b))
    check(#a >= 1 and #b >= 1, "1g New separator puts the picked mod and the ones below it under the new one")
    check(grouped(w) and idx(w.order, a[#a]) < idx(w.order, b[1]), "1h order follows position (Alpha's mods load before Beta's)")
    local v = w:orderView()
    local seps = 0
    for _, e in ipairs(v.ents) do if e.k == "sep" then seps = seps + 1 end end
    check(seps == 2, "1i the list shows the two separator rows")
end)
at(35, function() shot("01_two") end)

-- 2 live: Beta moved up past Alpha, its mods with it; then back
at(40, function()
    local w = W()
    if not keep.beta then return end
    local b0 = join(under(w, keep.beta))
    w:sepShift(keep.beta, -1)
    local a, b = under(w, keep.alpha), under(w, keep.beta)
    check(join(b) == b0 and grouped(w) and idx(w.order, b[#b]) < idx(w.order, a[1]), "2b Move up moves Beta and its mods above Alpha")
    w:sepShift(keep.beta, 1)
    check(grouped(w) and join(under(w, keep.beta)) == b0, "2c and back")
    -- a mod at the top of Beta, Move up: it crosses to the end of Alpha, its place unchanged
    local first = under(w, keep.beta)[1]
    local place = idx(w.order, first)
    w:orderSelectAt(place, false)
    w:move(-1)
    check(w.oSec[first] == keep.alpha and idx(w.order, first) == place, "2d Move up on a separator's first mod puts it at the end of the one above")
    w:move(1)
    check(w.oSec[first] == keep.beta, "2e Move down takes it back under")
end)

-- 3 live: Beta off: its mods off, in place, dimmed; on again: back in the same places
at(50, function()
    local w = W()
    if not keep.beta then return end
    local m = model()
    keep.bIds = under(w, keep.beta)
    keep.before3 = join(w.order)
    local n0 = #w.order
    w:sepBox(keep.beta)
    say("band: " .. tostring(w.note and w.note.text))
    local allOff = true
    for _, id in ipairs(keep.bIds) do if m.mods[id].isActive then allOff = false end end
    local sp = w:sepGet(keep.beta)
    check(allOff and sp.on == false, "3a the separator off turns every mod under it off")
    local kept = true
    for _, id in ipairs(keep.bIds) do if not idx(sp.ids, id) then kept = false end end
    check(kept and #w.order <= n0 - #keep.bIds, "3b they leave the order (the numbers close up) and stay under it")
    local v = w:orderView()
    local held = 0
    for _, e in ipairs(v.ents) do if e.k == "held" and e.uid == keep.beta then held = held + 1 end end
    check(held == #keep.bIds, "3c they show dimmed in their places (" .. held .. " rows)")
end)
at(55, function() shot("02_off") end)
at(60, function()
    local w = W()
    if not keep.beta then return end
    local m = model()
    w:sepBox(keep.beta)
    local allOn = true
    for _, id in ipairs(keep.bIds) do if not m.mods[id].isActive then allOn = false end end
    check(allOn and join(under(w, keep.beta)) == join(keep.bIds), "3d on again: every mod back on, in the same places")
    -- (anything the cascade turned off with them comes back through the Undo of both)
end)

-- 6: folders and separators never change each other
at(70, function()
    local w = W()
    if not keep.beta then return end
    local m = model()
    local ok, fid = F.create("QA Folder")
    keep.fid = fid
    -- two mods on and one off into the folder
    local on2, off1 = {}, nil
    for _, id in ipairs(w.order) do if #on2 < 2 and w.oZone[id] == 2 and id ~= "ZeD_UI" then on2[#on2 + 1] = id end end
    for _, d in ipairs(m.sortedMods or {}) do if not off1 and not d.isActive and d.isAvailable and d.modId ~= "ModTemplate" then off1 = d.modId end end
    keep.on2, keep.off1 = on2, off1
    local seps0 = ""
    for _, sp in ipairs(w.oLo.seps) do seps0 = seps0 .. sp.name .. "=" .. join(under(w, sp.uid)) .. "|" end
    local list = {}
    for _, id in ipairs(on2) do list[#list + 1] = id end
    if off1 then list[#list + 1] = off1 end
    F.assign(list, fid)
    w:orderChanged()
    local seps1 = ""
    for _, sp in ipairs(w.oLo.seps) do seps1 = seps1 .. sp.name .. "=" .. join(under(w, sp.uid)) .. "|" end
    check(ok and seps0 == seps1, "6a making a folder and filling it changes no separator")
    local raw0 = readRaw(TESTF)
    w:sepRename(keep.alpha, "QA Alpha 2")
    w:sepShift(keep.beta, -1)
    w:sepShift(keep.beta, 1)
    w:sepBox(keep.alpha); w:sepBox(keep.alpha)
    check(readRaw(TESTF) == raw0, "6b renaming, moving and turning separators off and on never writes ModFolders.cfg")
end)

-- 5: Start separators from folders (asks first: the list has separators)
at(80, function()
    local w = W()
    if not keep.fid then return end
    keep.on5 = onSet()
    w:sepFromFolders(false)
    check(w.confirm == "sreplace", "5a with separators already there, it asks first")
end)
at(85, function() shot("03_ask_replace") end)
at(90, function()
    local w = W()
    if not keep.fid then return end
    local raw0 = readRaw(TESTF)
    w:sepFromFolders(true)
    local seps = w.oLo.seps
    say("separators: " .. tostring(#seps) .. ", band: " .. tostring(w.note and w.note.text))
    local first = seps[1]
    local ids = first and under(w, first.uid) or {}
    local want = {}
    for _, id in ipairs(keep.on2) do want[id] = true end
    local only = #ids == #keep.on2
    for _, id in ipairs(ids) do if not want[id] then only = false end end
    check(first and first.name == "QA Folder" and only, "5b one separator per folder, holding only its mods that are on")
    check(not (keep.off1 and first and idx(first.ids, keep.off1)), "5c a mod in the folder that is off is not placed")
    local last = seps[#seps]
    check(last and last.name == ZeD.tr("UI_ZeD_Folders_Unfiled") and #under(w, 0) == 0, "5d the rest go under Unfiled, last")
    check(onSet() == keep.on5, "5e nothing turned on or off")
    check(readRaw(TESTF) == raw0, "5f the folders file is not touched")
    -- a folder renamed later does not rename its separator (6.c)
    F.rename(keep.fid, "QA Folder renamed")
    check(first and first.name == "QA Folder", "6c renaming the folder leaves its separator's name")
end)
at(95, function() shot("04_from_folders") end)

-- 7 and 4 live: Done; the game's list holds only mod ids; the list keeps the separators; a profile
-- keeps them through a save and a load; Auto keeps every mod in its section
at(100, function()
    local w = W()
    if not keep.fid then return end
    keep.names = {}
    for _, sp in ipairs(w.oLo.seps) do keep.names[#keep.names + 1] = sp.name end
    w:leaveOrder(true)
    local m = model()
    local ord = jlist(m:getActiveMods():getMods())
    local plain, isName = true, {}
    for _, n in ipairs(keep.names) do isName[n] = true end
    for _, id in ipairs(ord) do if not m.mods[id] or isName[id] then plain = false end end
    check(plain, "7a the game's own list (mods.txt) holds only mod ids, no separator")
    local key = O.listKey(m)
    check(#O.getLo(key).seps == #keep.names, "4f Done keeps the separators with the list")
    local raw = readRaw("ZeD_modprofiles.txt") or ""
    check(raw:find("[" .. key .. "]", 1, true) ~= nil and raw:find("\nsep=1|", 1, true) ~= nil, "4g they are in ZeD_modprofiles.txt, ZeD's own file")
    w:writeProfile(PROFILE)
    local e = O.entry(PROFILE)
    check(e and #(e.seps or {}) == #keep.names, "4h New... saves them with the profile")
    -- the list forgets, the order is scrambled; the profile load brings both back
    O.putLo(key, O.copyLo(nil), true)
    local rev = {}
    for i = #ord, 1, -1 do rev[#rev + 1] = ord[i] end
    m:correctAndSaveModOrder(rev)
    w:enterProfiles()
end)
at(110, function()
    local w = W()
    if not keep.fid then return end
    w:loadProfile({ name = PROFILE })
    local m = model()
    local lo = O.getLo(O.listKey(m))
    local names = {}
    for _, sp in ipairs(lo.seps) do names[#names + 1] = sp.name end
    check(join(names) == join(keep.names), "4i loading the profile gives the list its separators back")
    w:enterOrder("order")
    check(grouped(w), "4j after the load, each separator's mods load together, in the separators' order")
    local sec0 = {}
    for _, id in ipairs(w.order) do sec0[id] = w.oSec[id] end
    w:autoSort()
    local same = true
    for _, id in ipairs(w.order) do if w.oZone[id] == 2 and w.oSec[id] ~= sec0[id] then same = false end end
    check(same and grouped(w), "4k Auto keeps every mod under its separator")
end)
at(115, function() shot("05_after_profile") end)

-- put everything back
at(125, function()
    local w = W()
    if w.page == "order" or w.page == "maps" then w:leaveOrder(false) end
    if w.page == "profiles" then w:leaveProfiles() end
    local m = model()
    if keep.order0 then m:correctAndSaveModOrder(keep.order0) end
    if m.presets[PROFILE] then w.psel = PROFILE; w:deletePreset() end
    writeRaw("ZeD_modprofiles.txt", keep.raw or "")
    O.load()
    F.FILE = keep.ffile or "ModFolders.cfg"
    writeRaw(TESTF, "")
    F.load()
    w:discard()
end)
at(150, function()
    say(string.format("view=%s; %d passed, %d failed", tostring(MM.view), pass, fail))
    say("DONE")
end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then fail = fail + 1; say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 170 then Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
say("start")
