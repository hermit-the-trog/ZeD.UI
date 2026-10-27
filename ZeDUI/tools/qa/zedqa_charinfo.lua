-- ZeDUI/tools/qa/zedqa_charinfo.lua  (Oct 26 2026)
-- The game's own Character window pages land on ZeD's Character window (Overrides/CharacterInfo.lua):
-- everything that calls ISCharacterInfoWindow:toggleView on getPlayerInfoPanel(n).
--   1. the game's keys (its own key handler, xpUpdate.displayCharacterInfo): Health, Skills, Info,
--      Protection each open ZeD's tab; the same key again folds the tab; the game's window never shows
--   2. with Mini Health Panel on (zedqa_mods_run.ps1 -ModList minihealth_mods.txt): a click on its body
--      figure (its own onMouseDown / onMouseUp, which call toggleView(getText("IGUI_XP_Health"))) opens
--      ZeD's Character window on Health, with the windows shut and with them open on another tab; a
--      second click folds Health; the game's window never shows. Capture zqa_ci_click_opens_zed.png
--   3. puts back: both windows open on Loot, the mini panel's own setting
-- grep "ZEDQA ci".
local TAG = "ci"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); return end
local CW = ZeD_CharacterWindow
local core = getCore()
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function win() return CW.getWindow() end
local function vanillaShown() local v = getPlayerInfoPanel(0); return v ~= nil and v:getIsVisible() == true end
local function showing(tab)
    local w = win()
    return CW.isOpen() and w ~= nil and w._activeTab == tab and w._drawerOpen == true and w._drawerMode == "tab"
end
local function clickTab(id)
    local w = win()
    for _, z in ipairs(w and w._tabStripPanel and w._tabStripPanel._hitZones or {}) do
        if z.id == "tab:" .. id then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2); return true end
    end
    return false
end
local function routes() return ZeD.CharInfoRoute and ZeD.CharInfoRoute.count or 0 end
local mods = {}
do
    local list = getActivatedMods()
    for i = 0, list:size() - 1 do mods[(tostring(list:get(i)):gsub("^\\", ""))] = true end
end
local MHP = mods.MiniHealthPanel and mhpHandle or nil

-- the windows still (place, size, drawer width) for 30 checks in a row
local function shape()
    local t = {}
    for _, w in ipairs({ CW.getWindow(), ZeD_WorldWindow.getWindow() }) do
        if w and w:isVisible() then
            t[#t + 1] = string.format("%d,%d,%d,%d,%d", w:getX(), w:getY(), w:getWidth(), w:getHeight(), math.floor(w._drawerEffW or 0))
        end
    end
    return table.concat(t, ";")
end
local stillLast, stillN = nil, 0
local function still()
    local sh = shape()
    if sh == stillLast then stillN = stillN + 1 else stillLast, stillN = sh, 0 end
    if stillN >= 30 then stillLast, stillN = nil, 0; return true end
    return false
end

local Q, qi, wait = {}, 1, nil
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function until_(n, tries, fn, what) Q[#Q + 1] = { n = n, fn = fn, tries = tries, what = what } end

-- 0. the pair open on Loot
step(20, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not CW.isOpen() then CW.toggleBothPaired(0) end
    say("ZeD's Character window hook on: " .. tostring(ISCharacterInfoWindow._zedOrigToggleView ~= nil) .. " | Mini Health Panel on: " .. tostring(MHP ~= nil))
end)
step(20, function() clickTab("loot") end)

-- 1. the game's keys
local KEYS = {
    { "TOGGLE_HEALTH_PANEL", "health" },
    { "TOGGLE_SKILL_PANEL", "skills" },
    { "TOGGLE_INFO_PANEL", "identity" },
    { "TOGGLE_CLOTHING_PROTECTION_PANEL", "equip" },
}
for _, k in ipairs(KEYS) do
    local before
    step(10, function()
        local id = KeybindId[k[1]]
        local key = id and core:getKey(id) or 0
        before = routes()
        if key == 0 then say("key " .. k[1] .. " is not bound: skipped"); return end
        xpUpdate.displayCharacterInfo(key)
    end)
    step(30, function()
        check(showing(k[2]) and not vanillaShown() and routes() > before,
            "the game's " .. k[1] .. " key opens ZeD's " .. k[2] .. " tab (tab " .. tostring(win() and win()._activeTab) .. ", the game's window shown " .. tostring(vanillaShown()) .. ")")
    end)
end
step(10, function()
    local key = core:getKey(KeybindId.TOGGLE_CLOTHING_PROTECTION_PANEL)
    if key and key ~= 0 then xpUpdate.displayCharacterInfo(key) end
end)
step(30, function()
    check(not showing("equip") and CW.isOpen() and not vanillaShown(), "the same key again folds the tab (tab " .. tostring(win() and win()._activeTab) .. ")")
end)

-- 2. Mini Health Panel's click
local savedAlways
local function mhpClick()
    MHP.dragging = false
    MHP:onMouseDown(4, 4)
    MHP:onMouseUp(4, 4)
end
step(10, function()
    if not MHP then say("Mini Health Panel is off: its click is not checked"); return end
    savedAlways = MHP.alwaysShow
    MHP.alwaysShow = true
    clickTab("loot")
end)
-- open on another tab: the click lands on Health
step(30, function()
    if not MHP then return end
    local before = routes()
    mhpClick()
    say("clicked the mini panel (windows open on " .. tostring(win() and win()._activeTab) .. ")")
end)
step(30, function()
    if not MHP then return end
    check(showing("health") and not vanillaShown(), "Mini Health Panel's click opens ZeD's Health tab (tab " .. tostring(win() and win()._activeTab) .. ", the game's window shown " .. tostring(vanillaShown()) .. ")")
    local last = ZeD.CharInfoRoute and ZeD.CharInfoRoute.last
    check(last and last.view == getText("IGUI_XP_Health") and last.tab == "health", "it came through the game's toggleView (" .. tostring(last and last.view) .. " -> " .. tostring(last and last.tab) .. ")")
    mhpClick()
end)
step(30, function()
    if not MHP then return end
    check(not showing("health") and CW.isOpen() and not vanillaShown(), "a second click folds Health (tab " .. tostring(win() and win()._activeTab) .. ")")
    CW.toggleBothPaired(0)   -- both windows shut
end)
step(30, function()
    if not MHP then return end
    check(not CW.isOpen() and not ZeD_WorldWindow.isOpen(), "both windows shut")
    mhpClick()
end)
until_(10, 60, function()
    if not MHP then return true end
    return showing("health")
end, "with the windows shut, the click opens them on Health")
until_(1, 900, function() return (not MHP) or still() end, "the windows are still")
step(30, function()
    if not MHP then return end
    check(showing("health") and not vanillaShown(), "the windows open on Health, the game's window shut (shown " .. tostring(vanillaShown()) .. ")")
    local w = win()
    say(string.format("rect click_opens_zed char %d %d %d %d", w:getAbsoluteX(), w:getAbsoluteY(), w:getWidth(), w:getHeight()))
    say(string.format("rect click_opens_zed mhp %d %d %d %d", MHP:getAbsoluteX(), MHP:getAbsoluteY(), MHP:getWidth(), MHP:getHeight()))
    say("mini panel visible " .. tostring(MHP:isVisible()) .. ", in the UI " .. tostring(MHP.javaObject and MHP.javaObject:isVisible()))
    local ok, e = pcall(function() core:TakeFullScreenshot("zqa_ci_click_opens_zed.png") end)
    if ok then say("shot zqa_ci_click_opens_zed.png") else fails = fails + 1; say("ERR shot: " .. tostring(e)) end
end)

-- 3. put back
step(30, function()
    if MHP and savedAlways ~= nil then MHP.alwaysShow = savedAlways end
    if not CW.isOpen() then CW.toggleBothPaired(0) end
end)
step(30, function()
    clickTab("loot")
    local v = getPlayerInfoPanel(0)
    if v and v:getIsVisible() then v:close() end
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

-- a step's n is in 60ths of a second (wall clock; OnRenderTick runs while paused)
local tries = 0
local function tick()
    local s = Q[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    wait = wait or (now + s.n * 1000 / 60)
    if now < wait then return end
    wait = nil
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
