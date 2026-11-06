-- ZeDUI/tools/qa/mp_srvtab.lua  (Nov 5 2026, QA; multiplayer part 1, 593a51f0): the Server tab and the PvP marker.
-- On a server (zedqa_run.ps1 -Mp, the server's ini with PVP and SafetySystem on) or solo (the tab must be absent).
-- grep "ZEDQA mst".
--   tab       the tab on the Character window's strip (server) or not (solo)
--   buttons   each of the tab's buttons pressed where it is drawn: the game's window it opens
--   pvp       Turn PvP on/off: the seconds while it switches, then the state flips; the belt marker's words follow
--   players   the list fills from the scoreboard
-- Pictures: mst_<session>_<w>x<h>_tab.png, _pvp.png.
local function say(s) print("ZEDQA mst " .. tostring(s)) end
local p = getPlayer()
local S = ZeD.ServerTab
local SESSION = isClient() and "mp" or "solo"
local TAGS = SESSION .. "_" .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight()
local function CW() return ZeD_CharacterWindow.getWindow() end
local function stripHas(id)
    local strip = CW() and CW()._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do if z.id == "tab:" .. id then return z end end
    return nil
end
local function vis(e) return e ~= nil and e.getIsVisible and e:getIsVisible() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("mst_" .. TAGS .. "_" .. n .. ".png") end) end
local function belt() local B = ZeD.Belt; return B and B.pvpWords and B.pvpWords(p) end

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
add(300, function() if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end end)
add(2500, function()
    local z = stripHas("server")
    local tabs = {}
    local strip = CW() and CW()._tabStripPanel
    for _, hz in ipairs(strip and strip._hitZones or {}) do if hz.id and hz.id:find("^tab:") then tabs[#tabs + 1] = hz.id:sub(5) end end
    say("session " .. SESSION .. " " .. TAGS .. ": tabs [" .. table.concat(tabs, ", ") .. "]")
    if SESSION == "solo" then
        say((z and "FAIL" or "PASS") .. " solo: no Server tab")
        say("PASS solo: belt PvP marker words " .. tostring(belt()))
        return
    end
    say((z and "PASS" or "FAIL") .. " server: the Server tab on the strip")
    say("belt PvP marker words: " .. tostring(belt()))
    say("ZeD_CharacterWindow.openTab exists (the belt marker's click uses it): " .. tostring(ZeD_CharacterWindow.openTab ~= nil))
    local w = CW(); w._activeTab = "server"; w._drawerMode = "tab"; w._drawerOpen = true
end)
add(3000, function()
    if SESSION == "solo" then return end
    local st = CW()._serverTab
    local ids = {}
    for _, b in ipairs(st and st.btns or {}) do ids[#ids + 1] = b.id .. (b.disabled and " (greyed)" or "") end
    say("tab open " .. tostring(CW()._activeTab) .. "; buttons [" .. table.concat(ids, ", ") .. "]; players " .. #S.players)
    for _, pl in ipairs(S.players) do say("  player " .. pl.name .. " (" .. pl.user .. ")") end
    local pv = S.pvpState and S.pvpState(p)
    say("pvp state: " .. (pv and ("on " .. tostring(pv.on) .. ", left " .. tostring(pv.left) .. ", zone " .. tostring(pv.zone)) or "nil (safety system off?)"))
    shot("tab")
end)
-- each button pressed where it is drawn
local WINS = { options = function() return ISServerOptions and ISServerOptions.instance end,
    faction = function() return (ISFactionUI and ISFactionUI.instance) or (ISCreateFactionUI and ISCreateFactionUI.instance) end,
    safehouse = function() return ISSafehouseUI and ISSafehouseUI.instance end }
for _, id in ipairs({ "options", "faction", "safehouse" }) do
    add(600, function()
        if SESSION == "solo" then return end
        local st = CW()._serverTab
        local b
        for _, bb in ipairs(st and st.btns or {}) do if bb.id == id then b = bb end end
        if not b then say(id .. ": no button on the tab"); return end
        if b.disabled then say(id .. ": greyed"); return end
        S.onClick(CW(), b.x + 2, b.y + 2)
    end)
    add(1200, function()
        if SESSION == "solo" then return end
        local w = WINS[id]()
        say(id .. " -> the game's window open " .. tostring(vis(w)))
        if w then pcall(function() w:close() end); pcall(function() w:removeFromUIManager() end) end
    end)
end
-- pvp
add(500, function()
    if SESSION == "solo" then return end
    local pv = S.pvpState and S.pvpState(p)
    PV0 = pv and pv.on
    local st = CW()._serverTab
    local b
    for _, bb in ipairs(st and st.btns or {}) do if bb.id == "pvp" then b = bb end end
    if not b then say("pvp: no button (safety system off on the server?)"); return end
    S.onClick(CW(), b.x + 2, b.y + 2)
    say("pvp pressed, was on " .. tostring(PV0))
end)
for k = 1, 6 do
    add(2500, function()
        if SESSION == "solo" then return end
        local pv = S.pvpState and S.pvpState(p)
        say(string.format("pvp +%ds: on %s, left %s; belt marker '%s'", k * 2.5, tostring(pv and pv.on), tostring(pv and pv.left), tostring(belt())))
        if k == 1 then shot("pvp") end
    end)
end
add(500, function()
    if SESSION == "solo" then return end
    local pv = S.pvpState and S.pvpState(p)
    say(((pv and pv.on ~= PV0) and "PASS" or "FAIL") .. " pvp flipped: was " .. tostring(PV0) .. ", now " .. tostring(pv and pv.on))
end)
add(300, function() say("DONE") end)

local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
