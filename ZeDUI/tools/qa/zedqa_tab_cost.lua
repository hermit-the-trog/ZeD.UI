-- ZeDUI/tools/qa/zedqa_tab_cost.lua  (Nov 8 2026, Build; punch list 120): where a Character window tab's ms per tick
-- go, in the game. Run after zedqa_prelude and zedqa_pin_windows (pnw), both windows open; grep "ZEDQA tc".
-- For Loot, Equipment, Thermal, Identity, Skills and Health in turn (the World window on Loot), each 180-tick
-- window after 30 settle ticks, as suite_perf measures:
--   full     ms per tick as it is
--   render   ms inside the tab's own draw function (getTimestampMs around it: whole ms, averaged)
--   notab    ms per tick with the tab's draw function doing nothing: full - notab is all the tab costs
--   nostops  ms per tick with the controller's stops left to wait (ZEDQA_FRESH_STOPS off, as for a mouse
--            player): full - nostops is what the prelude's fresh stops add
--   nomodel  (Identity) ms per tick with the 3D portrait not placed: full - nomodel is the model
--   draws    per frame, by kind, counted on the drawer panel (a separate window of ticks: counting costs);
--            "lines" are the chevrons and dashed edges drawn from the line textures, one draw each
-- Then "ZEDQA tc DONE". Puts everything back.
local TAG = "tc"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
local ww = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
local R = ZeD_CharacterWindow and ZeD_CharacterWindow._tabRenderers
if not (cw and ww and R) then say("ERR open both windows first (and a build with _tabRenderers)"); say("DONE"); return end
if getGameSpeed() == 0 and setGameSpeed then pcall(setGameSpeed, 1) end
local function tabClick(strip, id)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then strip:onMouseDown(z.x + 2, z.y + 2); return true end
    end
    return false
end

local TABS = { "loot", "equip", "thermal", "identity", "skills", "health" }
local DRAWS = { "drawRect", "drawRectBorder", "drawText", "drawTextRight", "drawTextCentre", "drawTextZoomed",
    "drawTexture", "drawTextureScaled", "drawTextureScaledAspect", "drawTextureScaledUniform" }
local origR = {}
for _, id in ipairs(TABS) do origR[id] = R[id] end
local freshWas = ZEDQA_FRESH_STOPS
local placeWas = cw._placeIdentityModel
local leanWas = ZeD.LeanDraw
local lineJoWas = ZeD.Atoms and ZeD.Atoms.lineJo

local st = { renderMs = 0, counts = {}, lines = 0, frames = 0 }
local function putBack()
    for _, id in ipairs(TABS) do R[id] = origR[id] end
    ZEDQA_FRESH_STOPS = freshWas
    cw._placeIdentityModel = placeWas
    ZeD.LeanDraw = leanWas
    if ZeD.Atoms then ZeD.Atoms.lineJo = lineJoWas end
    local dp = cw._drawerPanel
    if dp then for _, k in ipairs(DRAWS) do rawset(dp, k, nil) end end   -- (the panel's own counters off: its class's again)
end

-- each phase: what it sets up and takes down
local function timed(id)
    local f = origR[id]
    if not f then return end
    R[id] = function(...)
        local t0 = getTimestampMs()
        local a, b = f(...)
        st.renderMs = st.renderMs + (getTimestampMs() - t0)
        return a, b
    end
end
local function counted(id)
    local dp = cw._drawerPanel
    if not dp then return end
    local lean = ZeD.LeanDraw or {}
    local mine = {}
    for k, v in pairs(lean) do mine[k] = v end
    for _, k in ipairs(DRAWS) do
        local orig = dp[k]
        if orig then
            local w = function(self, ...) st.counts[k] = (st.counts[k] or 0) + 1; return orig(self, ...) end
            rawset(dp, k, w)
            if k == "drawRect" then mine.drawRect = w end   -- (so the line textures still count as plain rects' panel)
        end
    end
    ZeD.LeanDraw = mine
    if lineJoWas then
        ZeD.Atoms.lineJo = function(p)
            local jo = lineJoWas(p)
            if jo then st.lines = st.lines + 1 end
            return jo
        end
    end
end

local phases = {}
for _, id in ipairs(TABS) do
    local function show()
        tabClick(ww._actionTabStrip, "loot")
        if id == "loot" then tabClick(cw._tabStripPanel, "loot") else tabClick(cw._tabStripPanel, id) end
    end
    phases[#phases + 1] = { tab = id, what = "full", setup = show }
    phases[#phases + 1] = { tab = id, what = "render", setup = function() show(); timed(id) end }
    if id ~= "loot" then
        phases[#phases + 1] = { tab = id, what = "notab", setup = function() show(); R[id] = function() end end }
    end
    phases[#phases + 1] = { tab = id, what = "nostops", setup = function() show(); ZEDQA_FRESH_STOPS = nil end }
    if id == "identity" then
        phases[#phases + 1] = { tab = id, what = "nomodel", setup = function() show(); cw._placeIdentityModel = function() return false end end }
    end
    if id ~= "loot" then
        phases[#phases + 1] = { tab = id, what = "draws", setup = function() show(); counted(id) end }
    end
end

local pi, n, t0 = 0, 0, 0
local function start()
    putBack()
    pi = pi + 1
    local ph = phases[pi]
    if not ph then return false end
    st.renderMs, st.counts, st.lines, st.frames = 0, {}, 0, 0
    ph.setup()
    n = 0
    return true
end
local function report(ph, avg)
    if ph.what == "render" then
        say(string.format("%-9s render  %.2f ms a tick inside the tab's draw (whole ms, averaged)", ph.tab, st.renderMs / 180))
    elseif ph.what == "draws" then
        local parts, total = {}, 0
        for _, k in ipairs(DRAWS) do
            local c = st.counts[k]
            if c and c > 0 then parts[#parts + 1] = string.format("%s %.1f", k, c / 180); total = total + c end
        end
        say(string.format("%-9s draws   %.1f a frame (%s; lines %.1f)", ph.tab, total / 180, table.concat(parts, ", "), st.lines / 180))
    else
        say(string.format("%-9s %-7s avg=%.2fms/tick", ph.tab, ph.what, avg))
    end
end
local function tick()
    local now = getTimestampMs()
    n = n + 1
    if n == 30 then t0 = now; st.renderMs, st.counts, st.lines = 0, {}, 0 end
    if n >= 210 then
        report(phases[pi], (now - t0) / 180)
        if not start() then
            Events.OnTick.Remove(tick)
            putBack()
            say("DONE")
        end
    end
end
if start() then Events.OnTick.Add(tick) else say("DONE") end
