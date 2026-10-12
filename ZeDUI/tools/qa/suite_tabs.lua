-- ZeD QA suite: walk every tab in both windows through the strip click handlers + focusable census
local cw = ZeD_CharacterWindow.getWindow(); local ww = ZeD_WorldWindow.getWindow()
if not cw or not ww then print("ZEDQA tabs: open both windows first") return end
if getGameSpeed() == 0 and setGameSpeed then pcall(setGameSpeed, 1) end
local function tabsOf(strip) local out = {}; for _, z in ipairs(strip._hitZones or {}) do if type(z.id) == "string" and z.id:sub(1, 4) == "tab:" then out[#out + 1] = { id = z.id:sub(5), x = z.x + 2, y = z.y + 2 } end end; return out end
local function zoneInfo(w, name) for _, z in ipairs(w._focusRing or {}) do if z.zone == name then local kinds = {}; for _, e in ipairs(z.elements or {}) do local k = tostring(e.id):match("^[^:]+") or "?"; kinds[k] = (kinds[k] or 0) + 1 end; local parts = {}; for k, c in pairs(kinds) do parts[#parts + 1] = k .. "=" .. c end; table.sort(parts); return #(z.elements or {}), table.concat(parts, " ") end end; return 0, "" end
local steps = {}
local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local n0 = 10
local function walk(label, win, strip, zone)
    local tabs = tabsOf(strip); local ids = {}; for _, t in ipairs(tabs) do ids[#ids + 1] = t.id end
    print("ZEDQA " .. label .. " tabs: " .. table.concat(ids, ","))
    for _, t in ipairs(tabs) do
        at(n0, function() strip:onMouseDown(t.x, t.y) end)
        at(n0 + 50, function() local c, k = zoneInfo(win, zone); print("ZEDQA " .. label .. " tab=" .. t.id .. " active=" .. tostring(win._activeTab) .. " w=" .. tostring(win:getWidth()) .. " focusables=" .. c .. " {" .. k .. "}") end)
        n0 = n0 + 60
    end
    at(n0, function() for _, t in ipairs(tabs) do if t.id == "loot" then strip:onMouseDown(t.x, t.y) end end end); n0 = n0 + 30
end
walk("char", cw, cw._tabStripPanel, "charTabContent")
walk("world", ww, ww._actionTabStrip, "worldTabContent")
at(n0, function() print("ZEDQA tabs done") end)
local n, i = 0, 1
local function tick() n = n + 1; while steps[i] and steps[i].n <= n do local ok, err = pcall(steps[i].f); if not ok then print("ZEDQA step error: " .. tostring(err)) end; i = i + 1 end; if not steps[i] then Events.OnTick.Remove(tick) end end
Events.OnTick.Add(tick); print("ZEDQA tabs armed")
