-- ZeDUI/tools/qa/zedqa_disclosure_walk.lua  (Nov 2 2026, QA; the beta checklist, old item 4: disclosures open and close)
-- Every tab of both windows: every disclosure the tab lists for the controller (isDisclosure in the window's focus
-- ring) is pressed as A presses it, the tab's layout must change (opened or folded), a picture is taken, then it is
-- pressed again and the layout must come back as it was. Up to 8 disclosures a tab. grep "ZEDQA dsc";
-- shots zqa_dsc_<c|w>_<tab>_<n>.png.
local function say(s) print("ZEDQA dsc " .. tostring(s)) end
local F = ZeD.Input.Focus
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_dsc_" .. n .. ".png") end) end
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
-- the tab's layout as a string: every focusable element's id and place (opening or folding a section moves or adds some)
local function layout(w)
    local parts = {}
    for _, z in ipairs(w and w._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do
            parts[#parts + 1] = tostring(e.id) .. "@" .. math.floor(tonumber(e.y) or 0) .. "x" .. math.floor(tonumber(e.h) or 0)
        end
    end
    return table.concat(parts, ";"), #parts
end
local function disclosures(w)
    local out = {}
    for _, z in ipairs(w and w._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do
            if e.isDisclosure and e.id ~= nil and #out < 8 then out[#out + 1] = e.id end
        end
    end
    return out
end
local function findId(w, id)
    for _, z in ipairs(w and w._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do if e.id == id then return e end end
    end
    return nil
end

-- the work list, built as the walk goes: { win, tag, tab }
local jobs = {}
local Q, qi, wait = {}, 1, nil
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function insertSteps(at, list) for i = #list, 1, -1 do table.insert(Q, at, list[i]) end end

local total = 0
local function tabSteps(which, tab)
    local function win() return which == "c" and cw() or ww() end
    local function strip() local w = win(); return w and (which == "c" and w._tabStripPanel or w._actionTabStrip) end
    local list, ids = {}, {}
    list[#list + 1] = { n = 5, fn = function() goTab(win(), strip(), tab) end }
    list[#list + 1] = { n = 30, fn = function()
        local w = win(); F.claimFocus(w)
    end }
    list[#list + 1] = { n = 10, fn = function()
        ids = disclosures(win())
        say(which .. " " .. tab .. ": " .. #ids .. " disclosure(s) " .. table.concat((function() local t = {} for _, i in ipairs(ids) do t[#t + 1] = tostring(i) end return t end)(), ", "))
        -- each disclosure: press, check, picture, press back, check
        local more = {}
        for k, id in ipairs(ids) do
            local before
            more[#more + 1] = { n = 2, fn = function()
                local w = win(); before = layout(w)
                local e = findId(w, id)
                if not check(e ~= nil, which .. " " .. tab .. " " .. tostring(id) .. ": listed") then return end
                local ok, err = pcall(e.onActivate, w, e)
                check(ok, which .. " " .. tab .. " " .. tostring(id) .. ": the press runs" .. (ok and "" or (" (" .. tostring(err) .. ")")))
            end }
            more[#more + 1] = { n = 25, fn = function()
                local w = win(); local now = layout(w)
                check(now ~= before, which .. " " .. tab .. " " .. tostring(id) .. ": the tab changes when pressed")
                shot(which .. "_" .. tab .. "_" .. k)
                total = total + 1
            end }
            more[#more + 1] = { n = 5, fn = function()
                local w = win(); local e = findId(w, id)
                if not check(e ~= nil, which .. " " .. tab .. " " .. tostring(id) .. ": still listed once pressed") then return end
                local ok, err = pcall(e.onActivate, w, e)
                check(ok, which .. " " .. tab .. " " .. tostring(id) .. ": the second press runs" .. (ok and "" or (" (" .. tostring(err) .. ")")))
            end }
            more[#more + 1] = { n = 25, fn = function()
                local w = win(); local now = layout(w)
                check(now == before, which .. " " .. tab .. " " .. tostring(id) .. ": pressed again, the tab is back as it was")
            end }
        end
        insertSteps(qi, more)
    end }
    return list
end

step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (ZeD_CharacterWindow.isOpen() and ZeD_WorldWindow.isOpen()) then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
step(30, function()
    local all = {}
    for _, t in ipairs(tabsOf(cw() and cw()._tabStripPanel)) do for _, s in ipairs(tabSteps("c", t)) do all[#all + 1] = s end end
    for _, t in ipairs(tabsOf(ww() and ww()._actionTabStrip)) do for _, s in ipairs(tabSteps("w", t)) do all[#all + 1] = s end end
    say("tabs: Character " .. #tabsOf(cw()._tabStripPanel) .. ", World " .. #tabsOf(ww()._actionTabStrip))
    insertSteps(qi, all)
end)
step(10, function()
    pcall(function() F.releaseFocus() end)
    goTab(cw(), cw() and cw()._tabStripPanel, "loot"); goTab(ww(), ww() and ww()._actionTabStrip, "loot")
    check(total > 0, "disclosures found and walked: " .. total)
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
