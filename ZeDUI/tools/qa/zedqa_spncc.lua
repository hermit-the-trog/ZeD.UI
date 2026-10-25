-- ZeDUI/tools/qa/zedqa_spncc.lua  (Oct 25 2026)
-- Support for Spongie's Character Customisation (ZeD/ModSupport/SPNCC.lua): the
-- Character window's Appearance tab, on the ZeD-QA save with SPNCC (and the
-- Retexture add-on's faces, SPNRetextureCustom) on. Run with spncc_manifest.txt
-- through zedqa_mods_run.ps1 -ModList spncc_mods.txt -Mode fullscreen4k.
--   1. the mod's window at game start (an old save): ZeD's tab instead, paused, Save only
--   2. picks (a face, a detail), Not saved, Save through the mod: its data has them
--   3. List view; Cancel puts picks back
--   4. the mod's default (no changes in game): read-only, Shave still there; the
--      Appearance Changing Spiffo opens it; player choice shows Muscle / Body Hair Growth
--   5. the controller: stops, D-pad moves, A picks
--   6. Large text, the light theme
-- Captures: Zomboid/Screenshots/zqa_spn_<name>.png. grep "ZEDQA spn".
local TAG = "spn"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); return end
local S = ZeD.ModSupport and ZeD.ModSupport.SPNCC
if not S then say("ERR ZeD's SPNCC support is not loaded (is the mod on?)"); return end
local CW = ZeD_CharacterWindow
local F = ZeD.Input and ZeD.Input.Focus
local core = getCore()
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(name)
    local f = "zqa_spn_" .. name .. ".png"
    local ok, e = pcall(function() core:TakeFullScreenshot(f) end)
    if ok then say("shot " .. f) else fails = fails + 1; say("ERR shot " .. name .. ": " .. tostring(e)) end
end
local function win() return CW.getWindow() end
local function st() local w = win(); return w and w._spncc end
local function data() return p:getModData().SPNCharCustom end
local function park() pcall(function() Mouse.setXY(core:getScreenWidth() - 4, core:getScreenHeight() - 4) end) end
local sb = SandboxVars.SPNCharCustom
local saved = { allow = sb.AllowCustomisationChange, mus = sb.MuscleVisuals, hair = sb.BodyHairGrowthEnabled }
local realDebug = isDebugEnabled
local size, base, accent = ZeD.currentSize, ZeD.currentBase, ZeD.currentAccent
local given = {}
local function give(ft) local it = p:getInventory():AddItem(ft); if it then given[#given + 1] = it end; return it end
local function els() local w = win(); return S.buildFocusables(w) end
local function el(id) for _, e in ipairs(els()) do if e.id == id then return e end end; return nil end
local function firstId(prefix) for _, e in ipairs(els()) do if e.id:sub(1, #prefix) == prefix then return e end end; return nil end
local function refresh() local s = st(); if s then s.tick = 999 end end

local Q, qi, wait = {}, 1, nil
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

-- 1. the mod asks for a look at game start; or ask it now (the mod's own call)
step(30, function()
    park()
    say("data " .. tostring(data() ~= nil) .. " hasCustomised " .. tostring(data() and data().hasCustomised)
        .. " first " .. tostring(S.first) .. " tab " .. tostring(win() and win()._activeTab))
    -- (the runner puts the windows back to their default spread before a script, which
    -- leaves Loot showing: the mod's call is made again, as it is at game start)
    local FS = require("CharacterCustomisation/FaceManager_Shared")
    FS.OpenCharacterCustomisationWindow(p, true)
end)
step(90, function()
    local w = win()
    check(w ~= nil and w._activeTab == "appearance", "the Character window is open on Appearance")
    check(S.first == true, "the first-time look (Save only)")
    check(getGameSpeed() == 0 or isClient(), "the game is paused while it is open")
    local s = st()
    check(s and #s.faces >= 1, "faces listed: " .. tostring(s and #s.faces))
    say("details listed: " .. tostring(s and #s.dets))
    check(el("spn:cancel") == nil, "no Cancel the first time")
    check(el("spn:save") ~= nil, "Save is a stop the first time")
    -- the mod's own window must not be up
    local ui, found = UIManager.getUI(), false
    for i = 0, ui:size() - 1 do
        local t = ui:get(i):getTable()
        if t and t.Type == "CharacterCustomisationPanel_Ingame" then found = true end
    end
    check(not found, "the mod's own window is not open")
end)
step(30, function() shot("first") end)

-- 2. pick the third face (or the last) and the first detail, then Save
local pickedFace, pickedDet
step(10, function()
    local s = st()
    local f = s.faces[math.min(3, #s.faces)]
    pickedFace = f and f.name
    local e = pickedFace and el("spn:face:" .. pickedFace)
    if e then e.onActivate(win(), e) end
    if s.dets[1] then
        pickedDet = s.dets[1].name
        local d = el("spn:det:" .. pickedDet)
        if d then d.onActivate(win(), d) end
    end
    say("picked " .. tostring(pickedFace) .. " + " .. tostring(pickedDet))
end)
step(60, function()
    local s = st()
    check(s.face == pickedFace, "the face pick is held")
    shot("picked")
    local e = el("spn:save")
    if e then e.onActivate(win(), e) end
end)
step(60, function()
    local d = data()
    check(d.hasCustomised == true, "the mod's data says customised")
    check(d.face and d.face.name == pickedFace, "the mod's data has the face: " .. tostring(d.face and d.face.name))
    if pickedDet then
        local has = false
        for _, v in ipairs(d.bodyDetails or {}) do if v.name == pickedDet then has = true end end
        check(has, "the mod's data has the detail")
    end
    check(S.first == false, "the first-time look is over")
    check(getGameSpeed() ~= 0, "the game runs again")
    check(el("spn:cancel") == nil and el("spn:save") == nil, "nothing to save or cancel after Save")
end)
step(30, function() shot("saved") end)

-- 3. the List view; a pick then Cancel
step(10, function() S.view = "list" end)
step(40, function()
    check(firstId("spn:face:") ~= nil, "list rows are stops")
    shot("list")
    local s = st()
    local other = s.faces[1].name ~= s.face and s.faces[1] or s.faces[2]
    if other then local e = el("spn:face:" .. other.name); if e then e.onActivate(win(), e) end end
end)
step(30, function()
    check(el("spn:cancel") ~= nil, "Cancel appears with an unsaved pick")
    shot("list_unsaved")
    local e = el("spn:cancel"); if e then e.onActivate(win(), e) end
end)
step(30, function()
    check(st().face == pickedFace, "Cancel puts the saved face back")
    S.view = "grid"
end)

-- 4. the mod's default: no changes in game (debug counts as an admin, so it is turned off here)
step(10, function()
    isDebugEnabled = function() return false end
    sb.AllowCustomisationChange = 4; sb.MuscleVisuals = 1; sb.BodyHairGrowthEnabled = 1
    give("Base.Razor")
    local FM = require("CharacterCustomisation/FaceManager/Main")
    pcall(FM.AddPlayerStubble, p, true, false)
    pcall(FM.AddPlayerBodyHair, p, false)
    refresh()
end)
step(60, function()
    local s = st()
    check(s.canFace == false and s.canDet == false, "the face and details are read-only")
    check(firstId("spn:face:") == nil, "no face stops when read-only")
    check(el("spn:save") == nil, "no Save when nothing can change")
    check(el("spn:shave:beard") ~= nil or p:isFemale(), "Shave (beard stubble) is a stop")
    shot("default")
end)
step(10, function()
    give("Spongie.AppearanceChanger")
    refresh()
end)
step(60, function()
    check(st().canFace == true, "the Spiffo opens the face")
    shot("spiffo")
    for i = #given, 1, -1 do
        if given[i]:getFullType() == "Spongie.AppearanceChanger" then p:getInventory():Remove(given[i]); table.remove(given, i) end
    end
    sb.AllowCustomisationChange = 1; sb.MuscleVisuals = 3; sb.BodyHairGrowthEnabled = 3
    refresh()
end)
step(60, function()
    check(el("spn:chk:muscle") ~= nil and el("spn:chk:growth") ~= nil, "player choice: Muscle and Body Hair Growth")
    shot("choice")
    local e = el("spn:shave:beard")
    if e then e.onActivate(win(), e) end
end)
step(60, function()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    say("queue after Shave: " .. tostring(q and q.queue and #q.queue))
    check(p:isFemale() or (q and q.queue and #q.queue > 0), "Shave queued the mod's action")
    shot("shaving")
end)

-- 5. the controller
step(30, function()
    local w = win()
    pcall(F.claimFocus, w)
    local e = F.focusWhere(w, "charTabContent", function(x) return x.id and x.id:sub(1, 9) == "spn:face:" end)
    check(e ~= nil, "focus lands on a face")
end)
step(20, function()
    local w = win()
    F.dispatchJoypadDir(w, "right")
    local e = F.getFocusedElement(w)
    say("after right: " .. tostring(e and e.id))
    check(e and e.id and e.id:sub(1, 4) == "spn:", "D-pad right stays in the tab")
end)
step(20, function()
    local w = win()
    F.dispatchJoypadDir(w, "down")
    local e = F.getFocusedElement(w)
    say("after down: " .. tostring(e and e.id))
    shot("pad")
end)
step(30, function() pcall(F.releaseFocus) end)

-- 6. Large text, the light theme
step(10, function() ZeD.applyTheme(base, accent, "large") end)
step(60, function() shot("large") end)
step(10, function() ZeD.applyTheme("light", accent, size) end)
step(60, function() shot("light") end)

-- put everything back
step(10, function()
    ZeD.applyTheme(base, accent, size)
    pcall(ZeD.Settings.reapplyFromOptions)
    isDebugEnabled = realDebug
    sb.AllowCustomisationChange, sb.MuscleVisuals, sb.BodyHairGrowthEnabled = saved.allow, saved.mus, saved.hair
    pcall(function() p:StopAllActionQueue() end)
    for _, it in ipairs(given) do
        if p:getPrimaryHandItem() == it then p:setPrimaryHandItem(nil) end
        if it:getContainer() then it:getContainer():Remove(it) end
    end
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

-- a step's n is in 60ths of a second (wall clock; OnRenderTick runs while paused)
local function tick()
    local s = Q[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    wait = wait or (now + s.n * 1000 / 60)
    if now < wait then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then fails = fails + 1; isDebugEnabled = realDebug; say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
