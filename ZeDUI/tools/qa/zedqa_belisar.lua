-- ZeDUI/tools/qa/zedqa_belisar.lua  (Nov 8 2026, QA; tag bel): Belisar's three mods in a game, in whatever mod list the run set:
--   Stay With Me (Bridge), NeatUI Equipment (NeatUI_Equipment, needs NeatUI_Framework), Minimal Sidebar (MinimalSidebar).
-- Read-only except for two toggles it puts back. It reports (ZEDQA bel PASS / FAIL / info lines):
--   0. which of the mods are on; whether ZeD is on (the ZeD-off baseline run has no ZeD, so those checks are skipped)
--   1. step aside: what ZeD found (ZeD.StepAside.found), underFor() for each screen
--   2. NeatUI Equipment: its panel and toggle button (NEQ_InventoryPage.getPanel), visible or not, where, whether the toggle
--      is on screen and not under a ZeD window, then toggled open and shut (the button's own path, togglePanel); shots
--   3. Minimal Sidebar: ISEquippedItem's column (the mod fades it): visible, its fade value, whether the mod's hook is on the
--      column's buttons, whether ZeD's belt wrapped the same functions; shots
--   4. Stay With Me in game: its code loaded and its hooks on the inventory page (its design screen is in the main menu:
--      zedqa_belisar_menu.lua)
-- Shots zqa_bel_*.png in Zomboid/Screenshots. grep "ZEDQA bel ".
local function say(s) print("ZEDQA bel " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_bel_" .. n .. ".png") end); say("shot " .. n) end
local function vis(o) if not o then return false end local ok, v = pcall(function() return o:isVisible() end); return ok and v or false end
local function rect(o)
    if not o then return "nil" end
    local ok, s = pcall(function() return string.format("x=%d y=%d w=%d h=%d", o:getAbsoluteX(), o:getAbsoluteY(), o:getWidth(), o:getHeight()) end)
    return ok and s or "?"
end
local function inside(a, b)   -- the centre of a lies inside b
    local ok, r = pcall(function()
        local cx, cy = a:getAbsoluteX() + a:getWidth() / 2, a:getAbsoluteY() + a:getHeight() / 2
        return cx >= b:getAbsoluteX() and cx <= b:getAbsoluteX() + b:getWidth() and cy >= b:getAbsoluteY() and cy <= b:getAbsoluteY() + b:getHeight()
    end)
    return ok and r
end
local ZED = ZeD ~= nil and ZeD.StepAside ~= nil
local active = {}
do local list = getActivatedMods(); for i = 0, list:size() - 1 do active[(tostring(list:get(i)):gsub("^\\", ""))] = true end end
local steps = {}
local function step(n, fn) steps[#steps + 1] = { n = n, fn = fn } end

step(5, function()
    local on = {}
    for _, id in ipairs({ "Bridge", "NeatUI_Framework", "NeatUI_Equipment", "MinimalSidebar", "ZeD_UI" }) do on[#on + 1] = id .. "=" .. tostring(active[id] == true) end
    say("mods: " .. table.concat(on, " ") .. "; ZeD loaded: " .. tostring(ZED) .. "; debug: " .. tostring(getCore():getDebug()))
    say("screen " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight())
    check(active.Bridge and active.NeatUI_Equipment and active.MinimalSidebar, "all three mods are on in this game")
    if getGameSpeed() <= 0 then setGameSpeed(1) end
end)
-- 1. step aside
step(10, function()
    if not ZED then say("skip: ZeD is off in this run"); return end
    local SA = ZeD.StepAside
    local found = SA.found
    local n = 0
    if type(found) == "table" then
        for k, v in pairs(found) do
            n = n + 1
            say("step aside found: " .. tostring(k) .. " by " .. tostring(type(v) == "table" and (v.name or v.id) or v) .. " why " .. tostring(type(v) == "table" and v.why or ""))
        end
    end
    say("step aside: found " .. n .. " screen(s) taken (found is " .. type(found) .. ")")
    for _, sc in ipairs({ "charinfo", "inventory", "loot", "hotbar", "belt", "sidebar" }) do
        local ok, u = pcall(function() return SA.underFor(sc) end)
        if ok and u then say("underFor " .. sc .. ": " .. tostring(u)) end
    end
    check(n == 0, "nothing is handed back to the game (no mod of the three replaces a whole ZeD screen)")
    local ok, d = pcall(function() return SA.detect() end)
    if ok and type(d) == "table" then local c = 0; for _ in pairs(d) do c = c + 1 end; say("detect() now: " .. c .. " screen(s)") end
end)
-- 2. NeatUI Equipment
local neq, tog
step(10, function()
    if ZED and ZeD_CharacterWindow and not ZeD_CharacterWindow.isOpen() then pcall(function() ZeD_CharacterWindow.toggle(0) end) end
    -- the ZeD-off baseline: the game's own inventory page, shown (with ZeD on, ZeD's window is the inventory and the game's page stays hidden)
    if not ZED then
        local pg = ISPlayerData and ISPlayerData[1] and ISPlayerData[1].playerInventory
        if pg then pcall(function() pg:setVisible(true); pg.pin = true end); say("baseline: the game's inventory page shown") end
    end
end)
step(60, function()
    check(type(NEQ_InventoryPage) == "table", "NeatUI Equipment's inventory hook is loaded (NEQ_InventoryPage)")
    neq = NEQ_InventoryPage and NEQ_InventoryPage.getPanel(0)
    say("NEQ panel exists: " .. tostring(neq ~= nil))
    local page = ISPlayerData and ISPlayerData[1] and ISPlayerData[1].playerInventory
    say("the game's inventory page: exists " .. tostring(page ~= nil) .. ", visible " .. tostring(vis(page)) .. ", " .. rect(page))
    if neq then
        tog = neq.toggleButton
        say("NEQ panel visible " .. tostring(vis(neq)) .. " docked " .. tostring(neq.docked) .. " " .. rect(neq))
        say("NEQ toggle button exists " .. tostring(tog ~= nil) .. " visible " .. tostring(vis(tog)) .. " " .. rect(tog))
        local W, H = getCore():getScreenWidth(), getCore():getScreenHeight()
        if tog then
            local x, y = tog:getAbsoluteX(), tog:getAbsoluteY()
            check(vis(tog) and x >= 0 and y >= 0 and x < W and y < H, "NEQ's toggle button is visible and on screen")
        end
        if ZED then
            local cw = ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
            if tog and cw then say("toggle centre inside ZeD Character window: " .. tostring(inside(tog, cw))) end
        end
    else
        say("no NEQ panel was made (it attaches to the game's inventory page)")
    end
    shot("neq_1_start")
end)
step(10, function()
    if not neq then return end
    local was = vis(neq)
    pcall(function() NEQ_InventoryPage.togglePanel(0) end)
    say("toggled: panel visible " .. tostring(was) .. " -> " .. tostring(vis(neq)))
end)
step(60, function()
    if not neq then return end
    say("NEQ panel after toggle: visible " .. tostring(vis(neq)) .. " " .. rect(neq))
    shot("neq_2_toggled")
    pcall(function() NEQ_InventoryPage.togglePanel(0) end)
end)
step(30, function() end)
-- 3. Minimal Sidebar
step(10, function()
    local eq = ISEquippedItem and ISEquippedItem.instance
    check(eq ~= nil, "the game's sidebar column exists (ISEquippedItem.instance)")
    if not eq then return end
    say("sidebar column visible " .. tostring(vis(eq)) .. " " .. rect(eq))
    say("on the class: fadeAlpha=" .. tostring(ISEquippedItem.fadeAlpha))
    say("on the instance: fadeAlpha=" .. tostring(eq.fadeAlpha) .. " targetFadeAlpha=" .. tostring(eq.targetFadeAlpha) .. " mainHandAlpha=" .. tostring(eq.mainHandAlpha))
    local hooked, total = 0, 0
    if eq.children then for _, c in pairs(eq.children) do total = total + 1; if c._minimalFadeHook then hooked = hooked + 1 end end end
    say("sidebar buttons carrying the mod's fade hook: " .. hooked .. " of " .. total)
    check(not active.MinimalSidebar or hooked > 0, "the mod's fade hook is on the sidebar's buttons (the mod runs)")
    say("ZeD's belt wrapped the same functions: " .. tostring(ISEquippedItem._zedBelt))
    local sb = eq.healthBtn
    say("health button visible " .. tostring(vis(sb)) .. " " .. rect(sb))
    shot("ms_1")
end)
step(180, function()
    local eq = ISEquippedItem and ISEquippedItem.instance
    if not eq then return end
    say("3 s later: sidebar fadeAlpha=" .. tostring(eq.fadeAlpha) .. " visible " .. tostring(vis(eq)))
    local B = ZED and ZeD.Belt
    local hud = B and B.getHUD and B.getHUD(0)
    say("ZeD belt: exists " .. tostring(hud ~= nil) .. " visible " .. tostring(vis(hud)) .. " " .. rect(hud))
    shot("ms_2")
end)
-- 4. Stay With Me in game
step(10, function()
    check(type(BridgeData) == "table" or type(BridgeMain) == "table" or type(Bridge) == "table", "Stay With Me's code is loaded")
    say("Stay With Me wrapped the inventory page: bridgeWrapped=" .. tostring(ISInventoryPage and ISInventoryPage.bridgeWrapped) .. " bridgeProxWrapped=" .. tostring(ISInventoryPage and ISInventoryPage.bridgeProxWrapped))
end)
step(20, function()
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)
local qi, wait = 1, nil
local function tick()
    local s = steps[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    wait = wait or (now + s.n * 1000 / 60)
    if now < wait then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then fails = fails + 1; say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
