-- ZeDUI/tools/qa/zedqa_atom_probe.lua  (Nov 3 2026, QA; punch list 83: are PZAPI text atoms drawn, and captured?)
-- Three of the game's text atoms (PZAPI UI.Text, SdfOldBold, large, red): A on its own root at 600,300; B the child
-- of a 1x1 root at 600,700 (the book's layer); C the same but the root alwaysOnTop and brought to the top. Then the
-- book is opened over them. A game screenshot at each stage, and a wait marker for a desktop capture. grep "ZEDQA ap".
local function say(s) print("ZEDQA ap " .. tostring(s)) end
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local UI = PZAPI and PZAPI.UI
if not (UI and UI.Text) then say("ERR no PZAPI.UI"); say("DONE"); return end
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local made = {}
step(30, function()
    local ok, err = pcall(function()
        local a = UI.Text{ font = UIFont.SdfOldBold, text = "A: atom on its own", x = 600, y = 300, width = 1400, height = 120, scaleX = 3, scaleY = 3, r = 1, g = 0.1, b = 0.1, a = 1, alwaysOnTop = true }
        a:instantiate(); made[#made + 1] = a
        local root = UI.Node{ x = 0, y = 0, width = 1, height = 1 }
        root:instantiate(); made[#made + 1] = root
        local b = UI.Text{ font = UIFont.SdfOldBold, text = "B: child of a 1x1 root", x = 600, y = 700, width = 1, height = 1, scaleX = 3, scaleY = 3, r = 1, g = 0.1, b = 0.1, a = 1 }
        UI._addChild(root, b)
        local root2 = UI.Node{ x = 0, y = 0, width = 1, height = 1, alwaysOnTop = true }
        root2:instantiate(); made[#made + 1] = root2
        local c = UI.Text{ font = UIFont.SdfOldBold, text = "C: child, root on top", x = 600, y = 1100, width = 1, height = 1, scaleX = 3, scaleY = 3, r = 1, g = 0.1, b = 0.1, a = 1 }
        UI._addChild(root2, c)
        pcall(function() root2.javaObj:bringToTop() end)
        say("made A, B, C; A javaObj " .. tostring(a.javaObj) .. ", B parent " .. tostring(b.parent ~= nil))
    end)
    if not ok then say("ERR making: " .. tostring(err)) end
end)
step(60, function() pcall(function() core:TakeFullScreenshot("zqa_ap_1_atoms.png") end); say("shot 1"); say("DESKTOP NOW 1") end)
step(240, function() say("open the book"); pcall(function() ZeD.GuideBook.open(0) end) end)
step(60, function() pcall(function() core:TakeFullScreenshot("zqa_ap_2_book.png") end); say("shot 2"); say("DESKTOP NOW 2") end)
step(240, function()
    pcall(function() ZeD.GuideBook.close(0) end)
    for _, n in ipairs(made) do pcall(function() n:setVisible(false) end); pcall(function() UIManager.RemoveElement(n.javaObj) end) end
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say("DONE")
end)
local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnRenderTick.Remove(tick); return end
    wait = wait + 1
    if wait < q.n then return end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
