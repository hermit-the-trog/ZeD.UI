-- ZeDUI/tools/qa/zedqa_mods_order.lua  (Oct 31 2026)
-- Main menu QA for the load order tools (MODS_LOAD_ORDER_SPEC.md, punch list 41, stage 1):
--   1. the order check is worked out once per change, not per frame (ZeD.ModOrder.stats counters
--      over 60 idle frames on the Load order page)
--   2. Find in the load order: only the matches, each with its real place number, the gaps
--      counted; "Show in the full list" clears Find and picks the match
--   3. pin first / pin last against a requirement: what a pinned-first mod needs is carried
--      above it, no row red; a mod pinned last that a pinned-first mod needs is carried up
--      (its row yellow)
--   4. a Load after rule survives Auto and a profile load
--   5. a rule that would close a circle is greyed in the picker, with its reason
--   6. the profile file keeps lines it does not know through a save and a profile update
-- Parts 1, 2 and 5 also run on made-up mods (ZeD.ModOrder alone), so they report with any mod
-- list; parts 3 and 4 live need mods with requirements on: run with compat_r4_mods.txt
-- (Neat_Crafting needs NeatUI_Framework, TheOnlyCurePlus needs TheOnlyCure).
-- Puts back: the profile file's text, the list's pins and rules, the load order; deletes its
-- test profile; leaves through Discard changes (vanilla's NO), so nothing new is accepted.
--
-- Run (never while the game runs; checks Lua/zedqa.lock itself):
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/compat_r4_mods.txt `
--        -Script ZeDUI/tools/qa/zedqa_mods_order.lua -Tag mlo -TimeoutSec 240
-- Lines: "ZEDQA mlo PASS ..." / "ZEDQA mlo FAIL ..." / "ZEDQA mlo SKIP ...", then a total and DONE.
local MM = ZeD.MainMenu
local O = ZeD.ModOrder
local function say(s) print("ZEDQA mlo " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_mlo_" .. n .. ".png") end) end
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

local PROFILE = "ZeDQA order"
local keep = {}           -- what goes back at the end

-- the profile file's text, read raw (put back as it was at the end)
local function readRaw()
    local r = getFileReader("ZeD_modprofiles.txt", false)
    if not r then return nil end
    local t = {}
    local line = r:readLine()
    while line do t[#t + 1] = line; line = r:readLine() end
    r:close()
    return table.concat(t, "\n") .. "\n"
end
local function writeRaw(s)
    local w = getFileWriter("ZeD_modprofiles.txt", true, false)
    if w then w:write(s); w:close() end
end

-- made-up mods for the parts that need no particular mod list
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
    keep.raw = readRaw()
    MM.ctx.open = nil
    MM.openMods()
end)

-- 6 first, on the file alone: unknown lines kept through a save and a reload
at(20, function()
    O.load()
    local e = O.entry(PROFILE, true)
    e.keep = { "zedqa_unknown=kept", "sep=QA section|qa1;qa2" }
    O.save()
    O.load()
    local e2 = O.entry(PROFILE)
    check(e2 and #e2.keep == 2 and e2.keep[1] == "zedqa_unknown=kept", "6a unknown lines survive a save and a reload")
    local raw = readRaw() or ""
    check(raw:find("sep=QA section|qa1;qa2", 1, true) ~= nil, "6b a later stage's line is in the file")
end)

-- 1, 2, 5 on made-up mods (ZeD.ModOrder and the page's list builder, no screen)
at(30, function()
    local I, order = fakeInfo(400)
    I.qa200.req = { "qa10" }
    local lo = { first = { "qa200" }, last = { "qa3" }, rules = { { id = "qa50", how = "after", other = "qa300" } } }
    local out, zone, carried = O.layout(order, I, lo, false)
    check(out[1] == "qa10" and out[2] == "qa200" and carried.qa10 == true, "3s pinned first carries what it needs above it")
    check(out[#out] == "qa3" and zone.qa3 == 3, "3s pinned last at the bottom")
    check(idx(out, "qa50") == idx(out, "qa300") + 1, "4s Load after laid out")
    local auto = O.layout(out, I, lo, true)
    check(idx(auto, "qa50") > idx(auto, "qa300"), "4s the rule survives Auto")
    local res = O.check(out, I, lo, zone)
    check(res.nBad == 0, "3s no red row with the pins")
    -- a chain of rules: qa50 after qa300 after qa301; qa301 after qa50 would close a circle
    lo.rules[#lo.rules + 1] = { id = "qa300", how = "after", other = "qa301" }
    local after50 = O.reach(I, lo, "qa301", true, false)     -- what must load before qa301? (nothing)
    local fwd = O.reach(I, lo, "qa301", false, false)        -- what must load after qa301: qa300, qa50
    check(fwd.qa300 and fwd.qa50 and not after50.qa50, "5s the rules' chain is seen (a circle would be refused)")
end)

-- 1 and 2 live: the Load order page
at(40, function()
    local w = W()
    w:enterOrder("order")
    keep.order = {}
    for i, id in ipairs(w.order) do keep.order[i] = id end
    keep.key = w.oKey
    keep.lo = O.getLo(w.oKey)
    say("load order: " .. #w.order .. " mods: " .. table.concat(w.order, ";"))
end)
at(50, function() keep.c0, keep.v0, keep.l0 = O.stats.checks, O.stats.views, O.stats.layouts end)
at(110, function()
    local dc, dv, dl = O.stats.checks - keep.c0, O.stats.views - keep.v0, O.stats.layouts - keep.l0
    say(string.format("over 60 idle frames: %d order checks, %d list builds, %d layouts", dc, dv, dl))
    check(dc <= 1 and dv <= 1 and dl == 0, "1 the order check and the list are not worked out per frame")
    shot("01_order")
end)
at(120, function()
    local w = W()
    local n = #w.order
    if n < 3 then say("SKIP 2 (fewer than 3 mods on)"); return end
    local mid = w.order[math.floor((n + 1) / 2)]
    keep.findId = mid
    w.find:setText(string.lower(mid))
end)
at(135, function()
    local w = W()
    if not keep.findId then return end
    local v = w:orderView()
    local rowsOk, matches, hidden = true, 0, 0
    for _, e in ipairs(v.ents) do
        if e.k == "row" then
            matches = matches + 1
            if w.order[tonumber(e.num)] ~= e.id then rowsOk = false end
        elseif e.k == "gap" then
            hidden = hidden + tonumber(e.text:match("%d+") or "0")
        end
    end
    say(string.format("Find \"%s\": %d matches, %d counted in the gaps, %d in the order", keep.findId, matches, hidden, #w.order))
    check(matches >= 1 and rowsOk, "2a the matches carry their real place numbers")
    check(matches + hidden == #w.order, "2b the gaps count every mod not shown")
    shot("02_find")
    local place = idx(w.order, keep.findId)
    w:orderShowInFull(place)
    check((w.find:getInternalText() or "") == "" and w.oSel == place, "2c Show in the full list clears Find and picks the mod")
end)
at(145, function() shot("03_shown") end)

-- 3 live: a mod with a requirement on, pinned first; the requirement pinned last
at(150, function()
    local w = W()
    local m = model()
    local who, need
    for _, id in ipairs(w.order) do
        local e = w.oInfo[id]
        for _, r in ipairs(e and e.req or {}) do if idx(w.order, r) and id ~= O.helperId() then who, need = id, r; break end end
        if who then break end
    end
    if not who then say("SKIP 3 (no mod on needs another: run with compat_r4_mods.txt)"); return end
    keep.who, keep.need = who, need
    w.oSel = idx(w.order, who)
    w:orderPin("first")
    local i, j = idx(w.order, who), idx(w.order, need)
    check(j < i and w.oZone[need] == 1 and w.oCarried[need] == true, "3a " .. need .. " is carried above " .. who .. " (pinned first)")
    check(w:orderCheck().nBad == 0, "3b no red row")
    w.oSel = j
    w:orderPin("last")
    local res = w:orderCheck()
    j = idx(w.order, need)
    check(w.oZone[need] == 1 and res.st[j] == "soft" and res.nBad == 0, "3c pinned last but needed by a pinned-first mod: carried up, yellow, never red")
    shot("04_pins")
end)
at(160, function()
    local w = W()
    if not keep.who then return end
    -- the pins go again (Undo twice)
    w:orderUndo(); w:orderUndo()
    check(O.pinOf(w.oLo, keep.who) == nil, "3d Undo takes the pins back")
end)

-- 4 and 5 live: Load after, Auto, Done, a profile, its load; a circle
at(170, function()
    local w = W()
    local mids = {}
    for _, id in ipairs(w.order) do if w.oZone[id] == 2 and id ~= "ZeD_UI" then mids[#mids + 1] = id end end
    if #mids < 3 then say("SKIP 4, 5 (fewer than 3 movable mods on)"); return end
    -- a: the first one that nothing needs and that needs nothing (the rule must be free to move it)
    local a, b
    for _, id in ipairs(mids) do
        local free = #(w.oInfo[id].req or {}) == 0
        for _, x in ipairs(w.order) do for _, r in ipairs(w.oInfo[x] and w.oInfo[x].req or {}) do if r == id then free = false end end end
        if free then a = id; break end
    end
    if not a then say("SKIP 4, 5 (no free mod)"); return end
    for k = #mids, 1, -1 do if mids[k] ~= a then b = mids[k]; break end end
    keep.a, keep.b = a, b
    w.oSel = idx(w.order, a)
    w:openPicker("after")
    check(w.pick ~= nil and w:pickWhy(b) == nil, "4a the picker opens and offers " .. b)
    w:pickChoose(b, false)
end)
at(180, function() shot("05_picker") end)
at(185, function()
    local w = W()
    if not keep.a then return end
    w:pickerConfirm()
    check(idx(w.order, keep.a) == idx(w.order, keep.b) + 1, "4b " .. keep.a .. " now loads just after " .. keep.b)
    w:autoSort()
    check(idx(w.order, keep.a) > idx(w.order, keep.b), "4c the rule survives Auto")
    -- 5: a circle: b after a would be the same pair (replaced); c after a, then a after... use b after c, c after a
    local c
    for _, id in ipairs(w.order) do if w.oZone[id] == 2 and id ~= keep.a and id ~= keep.b and id ~= "ZeD_UI" then c = id; break end end
    if c then
        w.oSel = idx(w.order, keep.b)
        w:openPicker("after"); w:pickChoose(c, false); w:pickerConfirm()      -- b after c (a after b after c)
        w.oSel = idx(w.order, c)
        w:openPicker("after")                                                  -- c after a would close the circle
        local why = w:pickWhy(keep.a)
        say("circle reason: " .. tostring(why))
        check(why ~= nil, "5 a rule that closes a circle is greyed, with its reason")
        shot("06_circle")
        w:closePicker(true)
        w.oSel = idx(w.order, keep.b)
        w:orderRemoveRules()          -- (b's rule goes; a after b stays for the profile test)
    else
        say("SKIP 5 (no third mod)")
    end
end)
at(195, function()
    local w = W()
    if not keep.a then return end
    w:orderDone()                     -- the list keeps the rule (and the order)
    w:writeProfile(PROFILE)           -- New...: the list's pins and rules go with the profile
    local e = O.entry(PROFILE)
    check(e and #(e.rules or {}) >= 1, "4d the profile keeps the rule")
    check(e and #(e.keep or {}) == 2, "6c Update keeps the profile's unknown lines")
    -- the rule broken by hand in the game's own list, then the profile loaded
    local m = model()
    local ord = jlist(m:getActiveMods():getMods())
    local ia, ib = idx(ord, keep.a), idx(ord, keep.b)
    table.remove(ord, ia); table.insert(ord, 1, keep.a)
    m:correctAndSaveModOrder(ord)
    O.putLo(O.listKey(m), O.copyLo(nil), true)     -- (the list forgets: the profile must bring it back)
    w:enterProfiles()
end)
at(205, function()
    local w = W()
    if not keep.a then return end
    w:loadProfile({ name = PROFILE })
    local ord = jlist(model():getActiveMods():getMods())
    say("after the profile load: " .. table.concat(ord, ";"))
    check(idx(ord, keep.a) > idx(ord, keep.b), "4e the rule survives a profile load (" .. keep.a .. " after " .. keep.b .. ")")
    check(#O.getLo(O.listKey(model())).rules >= 1, "4f loading the profile gives the list its rules")
end)
at(215, function() shot("07_after_profile") end)

-- put everything back
at(225, function()
    local w = W()
    if w.page == "order" or w.page == "maps" then w:leaveOrder(false) end
    if w.page == "profiles" then w:leaveProfiles() end
    local m = model()
    if keep.order then m:correctAndSaveModOrder(keep.order) end
    if m.presets[PROFILE] then w.psel = PROFILE; w:deletePreset() end
    -- (the profile file exactly as it was: its text written back, then read again)
    writeRaw(keep.raw or "")
    O.load()
    w:discard()
end)
at(260, function()
    say(string.format("view=%s; %d passed, %d failed", tostring(MM.view), pass, fail))
    say("DONE")
end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then fail = fail + 1; say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 280 then Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
say("start")
