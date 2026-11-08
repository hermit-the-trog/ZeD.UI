-- ZeDUI/tools/qa/zedqa_b8_windows.lua  (Nov 7 2026, QA; tag b8vw): which window appears, ZeD's or the game's, for the vanilla windows of
-- docs/reference/VANILLA_WINDOWS_20261107.md that can be opened from a script in single player. Each case calls the game's own entry point (the one
-- the doc and HOOK_MAP name), waits, and records
--   * every window the game or a mod put on the UI list meanwhile (ISUIElement.addToUIManager is watched; a class named ZeD_* is ZeD's)
--   * what ZeD shows (its Character or World window and the tab)
--   * the game's own instance, where there is one (the Character Info window, the radio window, the label reader, the paper map)
-- then prints  "<id> | expected ZeD | got ZeD: ... | game: ..."  with PASS or FAIL, closes what it opened and goes on.
-- Cases (doc row):  B8 label reader, B14 Character window while paused, character keys (skills / health), the world map (key M),
--   the crafting window (key), B1 a carried radio, B2 a paper map (if the item can be made), B7 the mini-map is gone from the wheels.
-- Not scriptable here (manual or the MP manifest): B3 respawn, B4-B6, B9, B12-B13 (a controller), B10-B11, C1-C19 (see b8_menus_review_mp.txt).
-- Adds and removes only the items it names (a walkie-talkie, a map). grep "ZEDQA b8vw".
local TAG = "b8vw"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
local Q = { pass = 0, fail = 0, notrun = 0 }
local seen = {}
local realAdd = ISUIElement.addToUIManager
ISUIElement.addToUIManager = function(self, ...)
    seen[#seen + 1] = { t = tostring(self and self.Type), el = self }
    return realAdd(self, ...)
end

local function zedState()
    local out = {}
    if CW and CW.isOpen and CW.isOpen() then
        local w = CW.getWindow()
        out[#out + 1] = "Character window (tab " .. tostring(w and w._activeTab) .. ")"
    end
    if WW and WW.isOpen and WW.isOpen() then
        local w = WW.getWindow()
        out[#out + 1] = "World window (tab " .. tostring(w and w._activeTab) .. ")"
    end
    local R = ZeD.Reader
    if R and R.get then
        local ok, r = pcall(R.get, 0)
        if ok and r and r.getIsVisible and r:getIsVisible() then out[#out + 1] = "ZeD reader" end
    end
    return out
end
local function gameState()
    local out = {}
    local ok, ci = pcall(getPlayerInfoPanel, 0)
    if ok and ci and ci.getIsVisible and ci:getIsVisible() then out[#out + 1] = "Character Info window" end
    if ISRadioWindow then
        for _, set in ipairs({ ISRadioWindow.instances or {}, ISRadioWindow.instancesIso or {} }) do
            for _, w in pairs(set) do if w and w.getIsVisible and w:getIsVisible() then out[#out + 1] = "ISRadioWindow" end end
        end
    end
    if ISMediaInfo and ISMediaInfo.instance and ISMediaInfo.instance.getIsVisible and ISMediaInfo.instance:getIsVisible() then out[#out + 1] = "ISMediaInfo" end
    if ISMiniMapOuter and ISMiniMapOuter.instance and ISMiniMapOuter.instance.getIsVisible and ISMiniMapOuter.instance:getIsVisible() then out[#out + 1] = "mini-map" end
    for _, s in ipairs(seen) do
        local t = s.t
        if t ~= "nil" and t:sub(1, 3) ~= "ZeD" then
            local vis = true
            pcall(function() vis = s.el:getIsVisible() end)
            if vis then out[#out + 1] = t end
        end
    end
    return out
end
local function list(t) if #t == 0 then return "-" end; return table.concat(t, ", ") end

local cases, ci, tick = {}, 0, 0
local cur, waitUntil = nil, 0
local function case(id, expected, row, open, close)
    cases[#cases + 1] = { id = id, expected = expected, row = row, open = open, close = close }
end

local function closeAll()
    if WW and WW.isOpen and WW.isOpen() then pcall(WW.close) end
    if CW and CW.isOpen and CW.isOpen() then pcall(CW.toggle, 0) end
    pcall(function() local c = getPlayerInfoPanel(0); if c and c:getIsVisible() then c:setVisible(false) end end)
    local R = ZeD.Reader
    if R and R.get then pcall(function() local r = R.get(0); if r and r:getIsVisible() then r:close() end end) end
    if ISMediaInfo and ISMediaInfo.instance then pcall(function() ISMediaInfo.instance:setVisible(false); ISMediaInfo.instance:removeFromUIManager() end); ISMediaInfo.instance = nil end
    for _, s in ipairs(seen) do
        if s.t:sub(1, 3) ~= "ZeD" and s.t ~= "nil" then pcall(function() s.el:setVisible(false); s.el:removeFromUIManager() end) end
    end
end

-- B8: Read label
case("B8 Read label", "ZeD", "B8", function()
    ISMediaInfo.openPanel(0, "A label written on the case: tracks one to nine. Side B is scratched.")
end)
-- B14: the Character window while paused
case("B14 Character window while paused", "ZeD", "B14", function()
    local was = getGameSpeed()
    setGameSpeed(0)
    pcall(CW.toggleBothPaired, 0)
    setGameSpeed(was > 0 and was or 1)
end)
-- the game's Skills / Health keys: every way in is ISCharacterInfoWindow:toggleView on getPlayerInfoPanel
case("Character info: Health view", "ZeD", "HOOK_MAP Character info", function()
    local ci = getPlayerInfoPanel(0)
    ci:toggleView(getText("IGUI_XP_Health"))
end)
case("Character info: Skills view", "ZeD", "HOOK_MAP Character info", function()
    local ci = getPlayerInfoPanel(0)
    ci:toggleView(getText("IGUI_XP_Skills"))
end)
-- the world map (the M key funnels here)
case("World map (M)", "ZeD", "HOOK_MAP World map", function()
    ISWorldMap.ShowWorldMap(0)
end, function() pcall(ISWorldMap.HideWorldMap, 0) end)
-- the crafting window
case("Crafting window", "ZeD", "HOOK_MAP Crafting", function()
    ISEntityUI.OpenHandcraftWindow(p, nil)
end)
-- B1: a carried radio. The first walkie-talkie the game will make.
local made = {}
case("B1 Carried radio", "ZeD", "B1", function()
    local item = nil
    for _, n in ipairs({ "Radio.WalkieTalkie2", "Radio.WalkieTalkie1", "Radio.WalkieTalkie3", "Base.WalkieTalkie2", "Radio.HamRadio1" }) do
        if not item then
            local ok, it = pcall(function() return p:getInventory():AddItem(n) end)
            if ok and it then item = it end
        end
    end
    if not item then say("B1 NOT RUN: no radio item could be made"); return "notrun" end
    made[#made + 1] = item
    say("B1 radio item: " .. tostring(item:getFullType()))
    p:setPrimaryHandItem(item)   -- (Nov 8 QA: the Radio tab lists radios in the hands or on the back, as the game's window does)
    ISRadioWindow.activate(p, item)
end)
-- B2: a paper map
case("B2 Paper map", "ZeD", "B2", function()
    local item = nil
    for _, n in ipairs({ "Base.LouisvilleMap1", "Base.MuldraughMap", "Base.WestpointMap", "Base.RosewoodMap", "Base.RiversideMap" }) do
        if not item then
            local ok, it = pcall(function() return p:getInventory():AddItem(n) end)
            if ok and it then item = it end
        end
    end
    if not item then say("B2 NOT RUN: no map item could be made (its names differ in this build)"); return "notrun" end
    made[#made + 1] = item
    say("B2 map item: " .. tostring(item:getFullType()))
    ISInventoryPaneContextMenu.onCheckMap(item, 0)
end)

local function finishCase(c, ran)
    local z, g = zedState(), gameState()
    local got = (#z > 0 and ("ZeD: " .. list(z)) or "ZeD: -") .. " | game: " .. list(g)
    local ok
    if c.expected == "ZeD" then ok = (#z > 0 and #g == 0) else ok = (#g > 0) end
    if ran == "notrun" then
        Q.notrun = Q.notrun + 1
        say(c.id .. " | expected " .. c.expected .. " | NOT RUN")
    else
        if ok then Q.pass = Q.pass + 1 else Q.fail = Q.fail + 1 end
        say((ok and "PASS " or "FAIL ") .. c.id .. " (" .. c.row .. ") | expected " .. c.expected .. " | " .. got)
        pcall(function() getCore():TakeFullScreenshot("zqa_b8_vw_" .. string.gsub(string.lower(c.id), "[^%w]+", "_") .. ".png") end)
    end
end

local phase, phaseAt = "idle", 0
local function onTick()
    tick = tick + 1
    if tick < 5 then return end
    if phase == "idle" then
        ci = ci + 1
        cur = cases[ci]
        if not cur then
            -- the mini-map: gone from the wheels, and no window of the game's by itself
            local mm = ISMiniMapOuter and ISMiniMapOuter.instance and ISMiniMapOuter.instance.getIsVisible and ISMiniMapOuter.instance:getIsVisible()
            say((mm and "FAIL" or "PASS") .. " B7 Mini-map | expected gone | the game's mini-map window visible: " .. tostring(mm and true or false))
            if mm then Q.fail = Q.fail + 1 else Q.pass = Q.pass + 1 end
            for _, it in ipairs(made) do pcall(function() p:getInventory():Remove(it) end) end
            ISUIElement.addToUIManager = realAdd
            say("summary: " .. Q.pass .. " PASS, " .. Q.fail .. (Q.fail > 0 and " FAIL" or " failures")  .. ", " .. Q.notrun .. " not run")
            say("DONE")
            Events.OnTick.Remove(onTick)
            return
        end
        pcall(closeAll)
        seen = {}
        local ok, r = pcall(cur.open)
        if not ok then say("ERR " .. cur.id .. ": " .. tostring(r)) end
        cur.ran = ok and r or nil
        phase, phaseAt = "wait", tick
    elseif phase == "wait" and tick - phaseAt >= 60 then
        finishCase(cur, cur.ran)
        phase, phaseAt = "close", tick
        pcall(function() if cur.close then cur.close() end end)
        pcall(closeAll)
    elseif phase == "close" and tick - phaseAt >= 30 then
        phase = "idle"
    end
end
Events.OnTick.Add(onTick)
