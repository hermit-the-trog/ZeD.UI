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
for _, t in ipairs(CWm.TABS or {}) do
    local id = t.id
    add(300, function() CWm.openTab(0, id) end)
    add(1300, function() nums("char", CWm.getWindow(), id); shot("char_" .. tostring(id)) end)
end
for _, t in ipairs(WWm.TABS or {}) do
    local id = t.id
    add(300, function() WWm.openTab(0, id) end)
    add(1300, function() nums("world", WWm.getWindow(), id); shot("world_" .. tostring(id)) end)
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
