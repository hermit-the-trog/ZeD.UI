-- ZeDUI/tools/qa/zedqa_button_census.lua  (Nov 2 2026, QA; the beta checklist, old item 6: every button does what it says)
-- Every tab of both windows: every stop the controller can land on (the window's focus ring) is listed with its id and
-- label. Each must have something behind it (A, the menu button, a D-pad handler, a disclosure, or a read stop that
-- shows its details when landed on), a size, and a place within its window's sides. A dead stop is one with none of these. The list is written
-- to Lua/zedqa_button_census.txt for the record. Presses are left to the scripts that own each surface (pressing every
-- button blind drops, eats and breaks things). grep "ZEDQA bcn".
local function say(s) print("ZEDQA bcn " .. tostring(s)) end
local F = ZeD.Input.Focus
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function ww() return ZeD_WorldWindow.getWindow() end
local function goTab(w, strip, id)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
    return false
end
local function tabsOf(strip)
    local out = {}
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if type(z.id) == "string" and z.id:sub(1, 4) == "tab:" then out[#out + 1] = z.id:sub(5) end
    end
    return out
end
local out = getFileWriter("zedqa_button_census.txt", true, false)
local total, dead = 0, 0
local function census(which, tab)
    local w = which == "c" and cw() or ww()
    local W, H = w:getWidth(), w:getHeight()
    local n, bad, outside = 0, {}, {}
    for _, z in ipairs(w._focusRing or {}) do
        if z.focusable then
            for _, e in ipairs(z.elements or {}) do
                n = n + 1
                local acts = (e.onActivate and "A" or "") .. (e.onContextMenu and "M" or "") .. (e.onDpadDir and "D" or "")
                    .. (e.onHoldActivate and "H" or "") .. (e.isDisclosure and "d" or "") .. (e.onFocus and "f" or "")
                local label = tostring(e._zedLabel or e.label or e.text or "")
                out:write(string.format("%s\t%s\t%s\t%s\t%s\t%d,%d %dx%d\r\n", which, tab, tostring(z.zone), tostring(e.id), label,
                    math.floor(tonumber(e.x) or -1), math.floor(tonumber(e.y) or -1), math.floor(tonumber(e.w) or 0), math.floor(tonumber(e.h) or 0)) .. "")
                out:write("\t" .. acts .. "\r\n")
                local live = e.onActivate or e.onContextMenu or e.onDpadDir or e.onHoldActivate or e.isDisclosure
                    or e.isCanvasCursor or e.isZoneDraw or e.isGridScroll or e.bandStop or e.readOnly or e.onFocus   -- (a read stop: landing on it shows its details)
                if not live then bad[#bad + 1] = tostring(e.id) end
                -- the place: x/y are window-relative in ZeD's rings; below the window is a row scrolled out of view (fine), so only
                -- a stop off the window's sides counts; an element with no size is not drawn (left alone)
                local ex, ey, ew, eh = tonumber(e.x), tonumber(e.y), tonumber(e.w) or 0, tonumber(e.h) or 0
                if ex and ey and ew > 0 and eh > 0 and (ex + ew < 0 or ex > W) then outside[#outside + 1] = tostring(e.id) end
            end
        end
    end
    total = total + n; dead = dead + #bad
    say(which .. " " .. tab .. ": " .. n .. " stops")
    check(n > 0, which .. " " .. tab .. ": the controller has stops to land on")
    check(#bad == 0, which .. " " .. tab .. ": every stop has something behind it" .. (#bad > 0 and (" (dead: " .. table.concat(bad, ", ") .. ")") or ""))
    check(#outside == 0, which .. " " .. tab .. ": every stop sits inside its window" .. (#outside > 0 and (" (outside: " .. table.concat(outside, ", ") .. ")") or ""))
end

local Q, qi, wait = {}, 1, nil
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (ZeD_CharacterWindow.isOpen() and ZeD_WorldWindow.isOpen()) then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
step(30, function()
    local list = {}
    for _, t in ipairs(tabsOf(cw()._tabStripPanel)) do list[#list + 1] = { "c", t } end
    for _, t in ipairs(tabsOf(ww()._actionTabStrip)) do list[#list + 1] = { "w", t } end
    say("tabs: " .. #list)
    local more = {}
    for _, j in ipairs(list) do
        local which, tab = j[1], j[2]
        more[#more + 1] = { n = 5, fn = function()
            local w = which == "c" and cw() or ww()
            goTab(w, which == "c" and w._tabStripPanel or w._actionTabStrip, tab)
        end }
        more[#more + 1] = { n = 30, fn = function() F.claimFocus(which == "c" and cw() or ww()) end }
        more[#more + 1] = { n = 10, fn = function() census(which, tab) end }
    end
    for i = #more, 1, -1 do table.insert(Q, qi, more[i]) end
end)
step(10, function()
    out:close()
    pcall(function() F.releaseFocus() end)
    goTab(cw(), cw()._tabStripPanel, "loot"); goTab(ww(), ww()._actionTabStrip, "loot")
    say("stops listed: " .. total .. ", dead: " .. dead .. " (Lua/zedqa_button_census.txt)")
    if fails == 0 then say("summary: all " .. passes .. " PASS") else say("summary: " .. fails .. " of " .. (passes + fails) .. " checks FAIL") end
    say("DONE")
end)

local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
