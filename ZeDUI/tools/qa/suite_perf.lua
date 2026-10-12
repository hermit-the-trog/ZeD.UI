-- ZeD QA suite: ms per tick on each tab (180-tick windows after 30 settle frames) + recipe builder cost
local cw = ZeD_CharacterWindow.getWindow(); local ww = ZeD_WorldWindow.getWindow()
if not cw or not ww then print("ZEDQA perf: open both windows first") return end
if getGameSpeed() == 0 and setGameSpeed then pcall(setGameSpeed, 1) end
local function tabClick(strip, id) for _, z in ipairs(strip._hitZones or {}) do if z.id == "tab:" .. id then strip:onMouseDown(z.x + 2, z.y + 2); return true end end; return false end
local phases = {}
for _, id in ipairs({"loot", "equip", "health", "thermal", "identity", "journal", "skills"}) do
    phases[#phases + 1] = { name = "char " .. id, setup = function() tabClick(ww._actionTabStrip, "loot"); tabClick(cw._tabStripPanel, id); if id == "journal" then cw._journalSubTab = 2 end end }
end
for _, id in ipairs({"craft", "build", "maps", "forage", "animals", "loot"}) do
    phases[#phases + 1] = { name = "world " .. id, setup = function() tabClick(cw._tabStripPanel, "loot"); tabClick(ww._actionTabStrip, id) end }
end
local pi, n, t0, maxDt, lastT = 0, 0, 0, 0, 0
local function startPhase() pi = pi + 1; local ph = phases[pi]; if not ph then return false end; ph.setup(); n = 0; maxDt = 0; lastT = getTimestampMs(); t0 = lastT; return true end
local function tick()
    local now = getTimestampMs(); n = n + 1
    if n > 30 then local dt = now - lastT; if dt > maxDt then maxDt = dt end end
    lastT = now; if n == 30 then t0 = now end
    if n >= 210 then
        print(string.format("ZEDQA perf %-16s avg=%.2fms/tick max=%dms", phases[pi].name, (now - t0) / 180, maxDt))
        if not startPhase() then
            local CC = ZeD.CraftingCore
            local function timeIt(label, fn) local t = getTimestampMs(); local c = 0; for i = 1, 30 do c = #fn() end; print(string.format("ZEDQA perf %s: %d elements, %.2f ms per build", label, c, (getTimestampMs() - t) / 30)) end
            if cw._jrecipeState then timeIt("journal recipes build", function() return CC.buildFocusables(cw, cw._jrecipeState, "jrecipe", nil, nil) end) end
            if ww._craftState then timeIt("world craft build", function() return CC.buildFocusables(ww, ww._craftState, "craft", nil, nil) end) end
            Events.OnTick.Remove(tick); print("ZEDQA perf done")
        end
    end
end
if startPhase() then Events.OnTick.Add(tick) end
