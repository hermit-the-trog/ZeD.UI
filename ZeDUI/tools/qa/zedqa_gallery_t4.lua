-- ZeDUI/tools/qa/zedqa_gallery_t4.lua  (Oct 25 2026)
-- Captures for the Workshop gallery, tester build 0.2.0-t4 (director: "take all
-- new screens with callouts so I can replace the old ones"): Messages, with notes
-- from two made-up mods (the gallery's Mods card uses made-up names too): the toast
-- and the belt's envelope as they arrive, then the window open on a note. The other
-- new screens come from the QA runs of Oct 24-25 (bubbles, dashboards round 6, the
-- belt's condition rings, sandbox in game, the Mods screen).
-- Dark theme, orange accent (the gallery's in-game look); the store, the switches
-- and the look are put back after. Writes Screenshots/zqa_g4_*.png. grep "ZEDQA g4".
local p = getPlayer()
local pn = p:getPlayerNum()
local MS, MW = ZeD.Messages, ZeD.MessagesWindow
local function say(s) print("ZEDQA g4 " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_g4_" .. n .. ".png") end); say("shot " .. n) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
if not (MS and MW) then say("ERR ZeD.Messages is not loaded"); say("DONE"); return end

local look = { base = ZeD.currentBase, accent = ZeD.currentAccent, size = ZeD.currentSize }
local catchWas = ZeD.Settings.messagesCatchOption and ZeD.Settings.messagesCatchOption:getValue()
local toastWas = ZeD.Settings.messagesToastOption and ZeD.Settings.messagesToastOption:getValue()
local RADIO, FARM = "Sample Radio Plus", "Sample Farm Map"
local target = {}
local function noop() end
local function note(src, text, kind)
    MS.qaSource = src
    local d
    if kind == "rich" then d = ISModalRichText:new(0, 0, 420, 300, text, false, target, noop, pn)
    else d = ISModalDialog:new(0, 0, 320, 150, text, false, target, noop, pn) end
    d:initialise()
    d:addToUIManager()
    MS.qaSource = nil
end

step(20, function()
    ZeD.applyTheme("dark", "orange", look.size)
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
end)
step(30, function()
    if ZeD_CharacterWindow.isOpen() and ZeD_CharacterWindow.toggleBothPaired then ZeD_CharacterWindow.toggleBothPaired(pn) end
    pcall(function() Mouse.setXY(20, 20) end)
    MS.sources, MS.toasts = {}, {}
    pcall(function() ZeD.Settings.messagesCatchOption:setValue(2); ZeD.Settings.messagesToastOption:setValue(2) end)
end)
-- the notes arrive: the first mod's two, then the second's (its toast is the newest)
step(10, function()
    note(RADIO, "<H1> Sample Radio Plus 2.1 <LINE> <TEXT> New in this version: the scanner remembers the last ten stations it found. <LINE> <LINE> Hold R beside any radio to scan.", "rich")
    note(RADIO, "Sample Radio Plus: your saved stations were moved to the new list.")
end)
step(40, function()
    note(FARM, "<H1> Welcome to Sample Farm <LINE> <TEXT> The farmhouse keys are in the mailbox by the road. The barn's generator needs fuel before the first winter.", "rich")
end)
step(25, function() shot("belt_toast") end)
-- the window, open on the farm's note
step(10, function() MW.open(pn, FARM) end)
step(90, function() pcall(function() Mouse.setXY(20, 20) end) end)
step(10, function() shot("window_note") end)
step(10, function() local w = MW.get(pn); if w then w:choose(RADIO) end end)
step(60, function() shot("window_radio") end)

step(10, function()
    local w = MW.get(pn)
    if w then pcall(function() w:close() end) end
    MS.sources, MS.toasts = {}, {}
    pcall(function() ZeD.Settings.messagesCatchOption:setValue(catchWas or 2); ZeD.Settings.messagesToastOption:setValue(toastWas or 2) end)
    ZeD.applyTheme(look.base, look.accent, look.size)
    say("put back: " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent))
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
