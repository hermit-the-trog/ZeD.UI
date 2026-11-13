-- ZeDUI/tools/qa/zedqa_pad_figure.lua  (Nov 12 2026, Build; punch list 108, the drawn controller; tag padfig)
-- In game, single player, the game paused behind the pause menu (the steps run on drawn frames). Options > Controls >
-- Button map and test in the in-game Options window, and the quick wheel's Controller map:
--   rest     the page opens on the drawn pad: the whole multiple k (5 at 4K and 1.75, 2 on the Deck at 1280 x 800),
--            the textures there, the 13 labels inside the figure's box and clear of each other and of the pad
--   lit      a made-up moment of input (the page's MM.padState stood in for: A, the D-pad's left arm, RB and the left
--            stick's click held, the left stick pushed, LT pulled 60%): the parts lit, the labels lit; put back after
--   sets     the button pictures set to PlayStation, Nintendo and Steam Deck in turn: each its own drawing; put back
--   pulls    the left stick's label asks which element, its click's actions open under its name (pictures of each)
--   cmap     the Controller map from the quick wheel draws the same pad
-- Pictures Screenshots/zqa_padfig_<step>_<w>x<h>.png. Run it at 4K and on the Deck size:
--   pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Manifest ZeDUI/tools/qa/pad_figure.txt
--   pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Manifest ZeDUI/tools/qa/pad_figure.txt -Mode windowed -Width 1280 -Height 800
-- The live test itself needs a real controller in the director's hands: the MANUAL lines at the end say what to try.
-- grep "ZEDQA padfig".
local TAG = "padfig"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local MM, PF, S, CM = ZeD and ZeD.MainMenu, ZeD and ZeD.PadFigure, ZeD and ZeD.Settings, ZeD and ZeD.ControllerMap
if not (MM and PF and S and S.glyphOption and CM and ToggleEscapeMenu) or isClient() then
    say("ERR single player with ZeD's Options, the drawn pad and the Controller map only")
    say("DONE")
    return
end
local npass, nfail = 0, 0
local function check(ok, what, detail)
    if ok then npass = npass + 1 else nfail = nfail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. ((detail ~= nil) and (" (" .. tostring(detail) .. ")") or ""))
    return ok
end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local function shot(name)
    local file = "zqa_padfig_" .. name .. "_" .. sw .. "x" .. sh .. ".png"
    local ok = pcall(function() getCore():TakeFullScreenshot(file) end)
    say("shot " .. file .. (ok and "" or " FAILED"))
end
local function menuUp() return MainScreen and MainScreen.instance and MainScreen.instance:isVisible() end
local function toggleMenu() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end
local function ow() return MM.pauseOpts end
local function spec(w, id) for _, s in ipairs(w and w._specs or {}) do if s.id == id then return s end end end
local glyphWas = S.glyphOption:getValue()
local function setGlyphs(key) for i, k in ipairs(S.glyphKeys) do if k == key then S.glyphOption:setValue(i) end end end
local realState = MM.padState
local IDS = { "LT", "LB", "DPAD", "LS", "SEL", "START", "RT", "RB", "Y", "B", "A", "RS", "X" }

-- the plan: each entry waits ms, then runs (on drawn frames: the pause menu stops OnTick)
local plan, pi, pt = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end

local function rectsMeet(a, b) return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h end
local function placement(fig, label)
    local box, pad = fig.box, { x = fig.x, y = fig.y, w = fig.w, h = fig.h }
    local out, over, onPad = 0, nil, nil
    for i, a in ipairs(IDS) do
        local la = fig.labs[a]
        if la.x < box.x or la.y < box.y or la.x + la.w > box.x + box.w or la.y + la.h > box.y + box.h then out = out + 1 end
        if rectsMeet(la, pad) then onPad = a end
        for j = i + 1, #IDS do if rectsMeet(la, fig.labs[IDS[j]]) then over = a .. "/" .. IDS[j] end end
    end
    check(out == 0, label .. ": every label inside the figure's box", out)
    check(over == nil, label .. ": no label over another", over)
    check(onPad == nil, label .. ": no label over the pad", onPad)
end

-- open the page
add(200, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    setGlyphs("auto")
    if not menuUp() then toggleMenu() end
end)
add(800, function()
    check(menuUp(), "the pause menu is up")
    MM.openOptions()
end)
add(800, function()
    local w = ow()
    if not check(w and w:isVisible(), "the in-game Options window is open") then return end
    w:openVanillaController()
end)
-- rest
add(1200, function()
    local w = ow()
    if not check(w and w.sub == "pad", "Button map and test is a page of ZeD's Options", w and w.sub) then return end
    local fig = w._padFig
    if not check(fig ~= nil, "the page drew the figure") then return end
    local T = ZeD.T
    say(string.format("screen %dx%d, ZeD scale %.2f: k %d, the pad %dx%d at %d,%d in the box %dx%d", sw, sh, T.scale or 0, fig.k, fig.w, fig.h, fig.x, fig.y, fig.box.w, fig.box.h))
    local want = nil
    if sw == 3840 and sh == 2160 and math.abs((T.scale or 0) - 1.75) < 0.01 then want = 5 elseif sw == 1280 and sh == 800 then want = 2 end
    if want then check(fig.k == want, "the whole multiple at this screen is the mockup's " .. want, fig.k)
    else say("NOTE no expected multiple for this screen (4K at 1.75 is 5, the Deck 2): k " .. fig.k) end
    check(PF._tex("zpad_xbox_stickup") ~= nil and PF._tex("zpad_xbox_stickup_parts") ~= nil, "the game has the drawn pad's textures")
    placement(fig, "rest")
    for _, id in ipairs(IDS) do if fig.lit[id] then say("NOTE " .. id .. " lit at rest: a controller is held?") end end
    shot("01_rest")
end)
-- a made-up moment of input
add(300, function()
    MM.padState = function()
        return { b = { A = true, DL = true, RB = true, L3 = true }, ls = { 0.6, -0.4 }, rs = { 0, 0 }, lt = 0.6, rt = 0 }
    end
end)
add(600, function()
    local fig = ow()._padFig
    MM.padState = realState
    if not fig then return end
    check(fig.lit.A and fig.lit.DPAD and fig.lit.RB and fig.lit.LS and fig.lit.LT, "held, pushed and pulled parts light their labels")
    check(not (fig.lit.B or fig.lit.X or fig.lit.RT or fig.lit.RS), "the rest stay unlit")
    shot("02_lit")
end)
-- the button pictures: each set its own drawing
for i, key in ipairs({ "ps", "nintendo", "deck" }) do
    add(400, function() setGlyphs(key) end)
    add(800, function()
        local fig = ow()._padFig
        local want = ({ ps = "ps", nintendo = "nin", deck = "deck" })[key]
        check(fig and fig.set == want, "the button pictures " .. key .. ": the " .. want .. " drawing", fig and fig.set)
        placement(fig, key)
        shot(string.format("%02d_set_%s", 2 + i, key))
    end)
end
add(300, function() S.glyphOption:setValue(glyphWas) end)
-- the pull-downs: the left stick's label asks which element; its click's actions under its name
add(600, function()
    local s = spec(ow(), "lab:LS")
    if check(s ~= nil, "the left stick's label is a stop") then s.fn() end
end)
add(600, function()
    local pop = MM.popup
    check(MM.ctx.open ~= nil and pop and #pop.items >= 2 and pop.items[1].pad ~= nil, "the left stick's label asks which element first", pop and #pop.items)
    shot("06_pull_which")
    local click
    for _, it in ipairs(pop and pop.items or {}) do if type(it) == "table" and it.pad and it.pad[1] == "L3" then click = it end end
    MM.ctx.open = nil
    if check(click ~= nil, "the stick's click is one of them") then click.fn() end
end)
add(600, function()
    local pop = MM.popup
    check(MM.ctx.open ~= nil and pop and pop.items[1].header == true and pop.back ~= nil, "its click's actions open under its name, with B back to the question")
    shot("07_pull_actions")
    MM.ctx.open = nil
end)
-- leave the page and the menu
add(400, function()
    local w = ow()
    w:closeSub()
    check(w.sub == nil, "Back leaves the page for the Options")
    w:back()
end)
add(600, function()
    MM.pauseView = "pause"
    if menuUp() then toggleMenu() end
end)
-- the Controller map: the same drawing
add(800, function() CM.open(0) end)
add(800, function()
    local win = CM.windows[0]
    check(win and win:isReallyVisible(), "the Controller map opens")
    shot("08_cmap")
    CM.close(0)
end)
add(400, function()
    say("MANUAL with a controller in hand, on Options > Controls > Button map and test:")
    say("MANUAL   each face button, View, Menu and both bumpers: held, it fills with the accent; a face button and View / Menu sit one art pixel down and right, their shadow gone")
    say("MANUAL   each D-pad arm: that arm lights with its arrow; the D-pad's label picture shows the arm")
    say("MANUAL   each stick: the cap follows the push (up is up), the label's dial dot too; a click lights the cap")
    say("MANUAL   each trigger: fills from the bottom row up as it is pulled, the label's percent counts to 100")
    say("MANUAL   the D-pad walks the labels (one stop each); A opens a label's actions; on a stick or the D-pad A first asks which element; B there goes back, B again closes; B on the page backs out")
    say("MANUAL   Test controller: pick the pad, the page leaves the buttons alone; A and Y held together end the test")
    say("MANUAL   the same with the button pictures on PlayStation (the D-pad up top) and on Xbox (the left stick up top)")
end)

local function drive()
    local st = plan[pi]
    if not st then return end
    local now = getTimestampMs()
    if now - pt < st.ms then return end
    pt = now
    pi = pi + 1
    local ok, e = pcall(st.fn)
    if not ok then nfail = nfail + 1; say("FAIL ERR step " .. (pi - 1) .. ": " .. tostring(e)) end
    if pi > #plan then
        MM.padState = realState
        pcall(function() S.glyphOption:setValue(glyphWas) end)
        say(npass .. " passed, " .. nfail .. " failed")
        say("DONE")
        Events.OnPreUIDraw.Remove(drive)
    end
end
Events.OnPreUIDraw.Add(drive)   -- (drawn frames run while the game is paused; OnTick may not)
say("start")
