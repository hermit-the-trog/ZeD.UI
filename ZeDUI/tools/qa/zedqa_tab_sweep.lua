-- ZeDUI/tools/qa/zedqa_tab_sweep.lua  (Nov 6 2026, QA; the director caught the missing tab icons and footer twice): after zedqa_animals.lua built the pen, every Character and World tab
-- with data in it: the clips each drawer ends a frame with against what it started with (must be 0), the tab strip's numbers and a picture. Read the rail and footer in every picture:
-- the count alone can miss a fault. Pictures zqa_tsw_<window>_<tab>.png. grep "ZEDQA tsw".
local function say(s) print("ZEDQA tsw " .. tostring(s)) end
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local worst = {}
local function hook(w, key)
    local p = w and w._drawerPanel
    if not p or p._tswHooked then return end
    local orig = p.prerender
    p._tswHooked = true
    p._tswOrig = orig
    p.prerender = function(self)
        local a = self._zedStencilN or 0
        orig(self)
        local d = (self._zedStencilN or 0) - a
        if d ~= 0 then worst[key] = d end
    end
end
local function unhook(w) local p = w and w._drawerPanel; if p and p._tswHooked then p.prerender = nil; p._tswHooked = nil end end
local function nums(key, w, id)
    local s = w and w._actionTabStrip
    local d = worst[key] or 0
    local on = w and w._activeTab == id
    say((not on and "SKIP " or d == 0 and "PASS " or "FAIL ") .. key .. " " .. id .. ": active=" .. tostring(w and w._activeTab) .. " clips left=" .. d .. " footer=" .. tostring(w and w.footerHeight and w:footerHeight())
        .. " strip vis=" .. tostring(s and s:isVisible()) .. " zones=" .. tostring(s and s._hitZones and #s._hitZones))
    worst[key] = nil
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_tsw_" .. n .. ".png") end) end
add(300, function()
    ZeD.AnimalsAlertPoller.refreshCache()
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
end)
add(2000, function() hook(CWm.getWindow(), "char"); hook(WWm.getWindow(), "world"); say("hooked") end)
-- (a tab this character isn't offered is forced on, so its draw still runs: it says FORCED, with no data in it)
local function force(w, id)
    if w and w._activeTab ~= id then
        w._activeTab, w._drawerMode, w._drawerOpen = id, "tab", true
        say("FORCED " .. id)
    end
end
-- a real item card over a tab, as a click on a row makes it: the row's item selected, then the window's own update
local function firstItem(w)
    for _, c in ipairs(w._containers or {}) do
        for _, v in pairs(c) do
            if instanceof(v, "ItemContainer") and v:getItems():size() > 0 then return v:getItems():get(0) end
        end
    end
    local items = getPlayer():getInventory():getItems()
    return items:size() > 0 and items:get(0) or nil
end
local function pick(w, item)
    local sel = w._mainContent._selectedItems
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    w._updateDrawer()
end
for _, t in ipairs(CWm.TABS or {}) do
    local id = t.id
    add(300, function() CWm.openTab(0, id) end)
    add(600, function() force(CWm.getWindow(), id) end)
    add(1000, function() nums("char", CWm.getWindow(), id); shot("char_" .. tostring(id)) end)
end
for _, t in ipairs(WWm.TABS or {}) do
    local id = t.id
    add(300, function() WWm.openTab(0, id) end)
    add(600, function() force(WWm.getWindow(), id) end)
    add(1000, function() nums("world", WWm.getWindow(), id); shot("world_" .. tostring(id)) end)
end
for _, c in ipairs({ { "world", WWm, "craft" }, { "world", WWm, "animals" }, { "world", WWm, "build" }, { "world", WWm, "maps" }, { "world", WWm, "forage" }, { "char", CWm, "journal" }, { "char", CWm, "skills" }, { "char", CWm, "health" } }) do
    local key, M, id = c[1], c[2], c[3]
    add(300, function() M.openTab(0, id); if id == "journal" then pcall(function() ZeD.JournalTab.setPage(M.getWindow(), "recipes") end) end end)
    add(1000, function() local w = M.getWindow(); local it = firstItem(w); say("card over " .. id .. ": " .. tostring(it and it:getDisplayName())); pick(w, it) end)
    add(1500, function() local w = M.getWindow(); say("card up " .. tostring(w._drawerItem ~= nil)); nums(key, w, id); shot("card_" .. key .. "_" .. id); pick(w, nil) end)
    add(1200, function() nums(key, M.getWindow(), id); shot("after_" .. key .. "_" .. id) end)
end
add(300, function() unhook(CWm.getWindow()); unhook(WWm.getWindow()); WWm.openTab(0, "loot"); say("DONE") end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); if i > #plan then say("DONE") end end
end
Events.OnTick.Add(drive)
