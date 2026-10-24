-- ZeDUI/tools/qa/zedqa_pad_glyphs.lua  (Oct 24 2026)
-- ZeD's pixel button pictures (ZeD_PadGlyphs.lua; GAMEPAD_SPEC.md, Button
-- pictures; mockup zed_quick_chords_v1.html). The input mode is held on the
-- controller so the footers show their prompts. Per set (PlayStation, Xbox,
-- Steam Deck, Nintendo, then Keyboard/mouse for the old boxed names):
--   * the pair open with the pad in the Character window: the footer's prompts;
--   * the World wheel: its prompts under the ring;
-- then PlayStation in the light and high contrast themes, and the dash's hint
-- in the deep run's car with the pad on the dash (PlayStation, Xbox).
-- Counts the pictures drawn per scene; the setting, the theme and the input
-- lock are put back. Run on the deep-run character. grep "ZEDQA pg".
local p = getPlayer()
local pn = p:getPlayerNum()
local PG, D, W = ZeD.PadGlyphs, ZeD.DpadWheels, ZeD.Wheel
local S = ZeD.Settings
local F = ZeD.Input.Focus
local Det = ZeD.Input.Detector
local function say(s) print("ZEDQA pg " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_pg_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

if not (PG and S and S.glyphOption) then say("ERR ZeD.PadGlyphs or the glyph setting is not loaded"); say("DONE"); return end

-- count the pictures drawn
local drawn = 0
local origDraw = PG.draw
PG.draw = function(...) drawn = drawn + 1; return origDraw(...) end
local function idx(key) for i, k in ipairs(S.glyphKeys) do if k == key then return i end end end
local function setGlyph(key) pcall(function() S.glyphOption:setValue(idx(key)) end); local el = S.glyphOption.element; if el then el.selected = idx(key) end end
local before = { glyph = S.glyphKey(), lock = Det.getLockedMode and Det.getLockedMode() or nil,
                 base = ZeD.currentBase, accent = ZeD.currentAccent, size = ZeD.currentSize }
local function closeWheel()
    local st = D.state[pn]
    if st and st.menu and st.menu.undisplay then pcall(st.menu.undisplay, st.menu) end
    D.state[pn] = nil
    local m = getPlayerRadialMenu(pn)
    if m and m:isReallyVisible() then pcall(m.undisplay, m) end
    W.qaPoint = nil
end
local function pairOpen(on)
    local open = ZeD_CharacterWindow.isOpen()
    if on ~= open and ZeD_CharacterWindow.toggleBothPaired then ZeD_CharacterWindow.toggleBothPaired(pn) end
end

step(20, function()
    Det.setLockedMode("gamepad")
    pairOpen(false); pcall(F.releaseFocus); closeWheel()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    say("scene: glyph setting " .. tostring(before.glyph) .. ", the game's style " .. tostring(getCore():getOptionControllerButtonStyleString()) .. ", input " .. tostring(Det.getMode()))
end)

for _, key in ipairs({ "ps", "xbox", "deck", "nintendo", "kbm" }) do
    step(5, function()
        setGlyph(key)
        check(S.glyphKey() == key, key .. ": the setting reads " .. tostring(S.glyphKey()))
        local want = ({ ps = "ps", xbox = "xbox", deck = "deck", nintendo = "nin" })[key]
        check(PG.set() == want, key .. ": the set in use is " .. tostring(PG.set()))
        pairOpen(true)
    end)
    step(25, function()
        local win = ZeD_CharacterWindow.getWindow()
        if win then pcall(F.claimFocus, win) end
    end)
    step(30, function() drawn = 0 end)
    step(10, function()
        say(key .. ": footer pictures drawn in 10 ticks: " .. drawn)
        if key == "kbm" then check(drawn == 0, "kbm: the footer draws boxed names, no pictures")
        else check(drawn > 0, key .. ": the footer draws its buttons as pictures") end
        shot("footer_" .. key)
    end)
    step(5, function()
        pcall(F.releaseFocus); pairOpen(false)
        ISDPadWheels.onDisplayRight({ player = pn, id = nil })
        W.qaPoint = 2
    end)
    step(20, function() drawn = 0 end)
    step(5, function()
        say(key .. ": wheel pictures drawn in 5 ticks: " .. drawn)
        if key ~= "kbm" then check(drawn > 0, key .. ": the wheel's prompts are pictures") end
        shot("wheel_" .. key)
    end)
    step(5, function() closeWheel() end)
end

-- PlayStation in the other two themes
for _, base in ipairs({ "light", "hicon" }) do
    step(5, function()
        setGlyph("ps"); D.Z.theme(base, nil, nil); pairOpen(true)
    end)
    step(25, function() local win = ZeD_CharacterWindow.getWindow(); if win then pcall(F.claimFocus, win) end end)
    step(30, function() shot("footer_ps_" .. base) end)
    step(5, function()
        pcall(F.releaseFocus); pairOpen(false)
        ISDPadWheels.onDisplayRight({ player = pn, id = nil }); W.qaPoint = 2
    end)
    step(25, function() shot("wheel_ps_" .. base) end)
    step(5, function() closeWheel() end)
end
step(5, function() D.Z.theme(before.base, before.accent, before.size) end)

-- the dash's hint, with the pad on the dash
local car
step(10, function()
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        local t
        pcall(function() t = v:getModData().ZeDDeepRun end)
        if t == "near_car" and v:DistTo(p) < 8 then car = v end
    end
    if not car then say("no deep-run car within 8 tiles: the dash scene is skipped"); return end
    pcall(function() car:enter(0, p) end)
    pcall(function() triggerEvent("OnEnterVehicle", p) end)
end)
for _, key in ipairs({ "ps", "xbox" }) do
    step(40, function()
        if not (car and p:getVehicle()) then return end
        setGlyph(key)
        check(ZeD.Dashboard.takePad(p), key .. ": the dash takes the pad")
    end)
    step(30, function() if car and p:getVehicle() then shot("dash_" .. key) end end)
    step(5, function() pcall(F.releaseFocus) end)
end
step(20, function()
    if car and p:getVehicle() then pcall(function() car:exit(p) end); pcall(function() triggerEvent("OnExitVehicle", p) end) end
end)

-- put back what was there
step(10, function()
    PG.draw = origDraw
    setGlyph(before.glyph or "auto")
    if S.save then S.save() end
    Det.setLockedMode(before.lock)
    pcall(F.releaseFocus)
    say("put back: glyph setting " .. tostring(S.glyphKey()) .. ", input lock " .. tostring(Det.getLockedMode and Det.getLockedMode()))
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then fails = fails + 1; say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
