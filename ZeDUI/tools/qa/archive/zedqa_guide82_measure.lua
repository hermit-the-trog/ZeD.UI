-- ZeDUI/tools/qa/zedqa_guide82_measure.lua  (Nov 3 2026, QA; punch list 82, the director's narrower topic panel)
-- Every topic: the letters in each line of its text (the most, and the longest ten percent), that no line runs past
-- the topic's measure, the head line (title, section, "n of 81") inside the head, the rules table inside the measure,
-- the clip no wider than the measure, the band's three controls inside the window and apart. grep "ZEDQA g8m".
local function say(s) print("ZEDQA g8m " .. tostring(s)) end
local G = ZeD and ZeD.Guide
if not G then say("ERR ZeD.Guide is not loaded"); say("DONE"); return end
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function Wn() return G.get(0) end
local function tw(font, s) return ZeD.TM:MeasureStringX(font, s) end
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local counts, over, headOver, rulesOver, clipOver, breaks = {}, {}, {}, {}, {}, {}
local measure

step(60, function() if G.openWindow then G.openWindow(0) else G.open(0) end end)
for i = 1, 90 do
    step(3, function() local w = Wn(); local t = w.flat[i]; if t then w:choose(t.id, true) end end)
    step(3, function()
        local w = Wn(); local t = w.flat[i]; local g = w._g
        if not (t and g) then return end
        local T = ZeD.T
        local pad = T.px(10) * 2
        local left = g.text.x + pad
        local right = g.text.x + g.text.w - pad - (T.sp.scrollbarW or 0)
        measure = right - left
        for _, it in ipairs(g.items or {}) do
            if it.kind == "line" then
                local n, endX = 0, it.x
                for _, r in ipairs(it.runs or {}) do
                    if r.text and r.text:find("\n", 1, true) then breaks[#breaks + 1] = t.title end
                    if r.text then n = n + #r.text; endX = math.max(endX, it.x + r.x + tw(T.fontF2, r.text)) end
                    if r.tex then n = n + 1; endX = math.max(endX, it.x + r.x + r.s) end
                end
                counts[#counts + 1] = n
                if endX > right + 1 then over[#over + 1] = t.title end
            elseif it.kind == "clip" then
                if it.x + it.w > right + 1 then clipOver[#clipOver + 1] = t.title end
            elseif it.kind == "rules" then
                for _, c in ipairs(it.cells or {}) do
                    if c.x + tw(c.head and T.fontF1 or T.fontF2, c.text or "") > it.x + it.w + 1 then rulesOver[#rulesOver + 1] = t.title .. " (" .. tostring(c.text) .. ")" end
                end
            end
        end
        -- the head: title, section, "n of 81", left to right without touching
        local hd = g.head
        local hx = hd.x + T.px(10) * 2
        local sec = ZeD.upper and ZeD.upper(t.section.title) or t.section.title
        local endSec = hx + tw(T.fontF4, t.title) + T.px(10) + tw(T.fontF1, sec)
        local where = ZeD.tr("UI_ZeD_Guide_NofM", i, #w.flat)
        local whereX = hd.x + hd.w - T.px(10) * 2 - tw(T.fontF1, where)
        if endSec + T.px(6) > whereX then headOver[#headOver + 1] = t.title end
    end)
end
step(5, function()
    local w = Wn(); local g = w._g
    table.sort(counts)
    local most = counts[#counts] or 0
    local p90 = counts[math.max(1, math.floor(#counts * 0.9))] or 0
    say(string.format("lines %d; letters per line: most %d, longest tenth from %d; measure %d px; window %d x %d px",
        #counts, most, p90, measure or -1, w:getWidth(), w:getHeight()))
    check(most <= 75 and most >= 50, "letters per line about 60-70 (most " .. most .. ", longest tenth " .. p90 .. ")")
    check(#breaks == 0, "no line carries a line break inside it (drawn a line low)" .. (#breaks > 0 and (" (" .. table.concat(breaks, ", ") .. ")") or ""))
    check(#over == 0, "no line runs past the measure" .. (#over > 0 and (" (" .. table.concat(over, ", ") .. ")") or ""))
    check(#clipOver == 0, "the clip fits the measure" .. (#clipOver > 0 and (" (" .. table.concat(clipOver, ", ") .. ")") or ""))
    check(#rulesOver == 0, "the rules table fits the measure" .. (#rulesOver > 0 and (" (" .. table.concat(rulesOver, ", ") .. ")") or ""))
    check(#headOver == 0, "the head line (title, section, n of 81) fits" .. (#headOver > 0 and (" (" .. table.concat(headOver, ", ") .. ")") or ""))
    local f = g.foot
    local ok = f[1].x >= 0 and f[3].x + f[3].w <= w:getWidth() and f[1].x + f[1].w + ZeD.T.px(8) <= f[2].x and f[2].x + f[2].w <= f[3].x
    check(ok, "the band fits: the start-up box, Previous, Next inside the window and apart")
    check(w:getX() >= 0 and w:getX() + w:getWidth() <= getCore():getScreenWidth() and w:getY() >= 0 and w:getY() + w:getHeight() <= getCore():getScreenHeight(), "the window fits the screen")
    w:close()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say(string.format("RESULT %d pass, %d fail", passes, fails))
    say("DONE")
end)

local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnRenderTick.Remove(tick); return end
    wait = wait + 1
    if wait < q.n then return end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(err)) end
end
-- (the guide pauses the game: the steps run on OnRenderTick)
Events.OnRenderTick.Add(tick)
say("start")
