-- ZeDUI/tools/qa/zedqa_kinsoku.lua  (Nov 4 2026, QA; punch list 83, Build's d085a6fc: Japanese and Chinese line breaks)
-- The window on every topic: no laid-out line starts with a closing mark, a long-vowel mark or a small kana, and none
-- ends with an opening mark. Compared by code point (source literals lose their high bytes). grep "ZEDQA kin".
local function say(s) print("ZEDQA kin " .. tostring(s)) end
local G = ZeD and ZeD.Guide
if not G then say("ERR ZeD.Guide is not loaded"); say("DONE"); return end
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function set(t) local s = {}; for _, c in ipairs(t) do s[c] = true end; return s end
local noStart = set({ 0x3001, 0x3002, 0xFF0C, 0xFF0E, 0xFF01, 0xFF1F, 0xFF1A, 0xFF1B, 0x300D, 0x300F, 0xFF09, 0x3015,
    0x3011, 0x3009, 0x300B, 0x30FC, 0x30FB, 0x3005,
    0x3041, 0x3043, 0x3045, 0x3047, 0x3049, 0x3063, 0x3083, 0x3085, 0x3087, 0x308E,
    0x30A1, 0x30A3, 0x30A5, 0x30A7, 0x30A9, 0x30C3, 0x30E3, 0x30E5, 0x30E7, 0x30EE, 0x30F5, 0x30F6 })
local noEnd = set({ 0x300C, 0x300E, 0xFF08, 0x3014, 0x3010, 0x3008, 0x300A })
local lang = "?"
pcall(function() lang = tostring(Translator.getLanguage():name()) end)
local function Wn() return G.get(0) end
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local lines, cjkLines, badStart, badEnd = 0, 0, {}, {}
local function firstCode(s)
    for i = 1, #s do local c = string.byte(s, i); if c and c ~= 32 then return c end end
end
local function lastCode(s)
    for i = #s, 1, -1 do local c = string.byte(s, i); if c and c ~= 32 then return c end end
end
step(60, function() if G.openWindow then G.openWindow(0) else G.open(0) end end)
for i = 1, 90 do
    step(3, function() local w = Wn(); local t = w.flat[i]; if t then w:choose(t.id, true) end end)
    step(3, function()
        local w = Wn(); local t = w.flat[i]; local g = w._g
        if not (t and g) then return end
        local prevPara = true
        for _, it in ipairs(g.items or {}) do
            if it.kind == "line" then
                local txt = {}
                for _, r in ipairs(it.runs or {}) do if r.text then txt[#txt + 1] = r.text end end
                local s = table.concat(txt)
                if #s > 0 then
                    lines = lines + 1
                    local a, z = firstCode(s), lastCode(s)
                    if (a and a >= 0x3000) or (z and z >= 0x3000) then cjkLines = cjkLines + 1 end
                    if a and noStart[a] then badStart[#badStart + 1] = t.title .. string.format(" U+%04X", a) end
                    if z and noEnd[z] then badEnd[#badEnd + 1] = t.title .. string.format(" U+%04X", z) end
                end
            end
        end
    end)
end
step(5, function()
    say(string.format("language %s: %d lines, %d with CJK at an end", lang, lines, cjkLines))
    check(cjkLines > 0, "the window is laid out in CJK (" .. cjkLines .. " lines)")
    check(#badStart == 0, "no line starts with a closing mark, long-vowel mark or small kana" .. (#badStart > 0 and (" (" .. #badStart .. ": " .. table.concat(badStart, ", ", 1, math.min(#badStart, 10)) .. ")") or ""))
    check(#badEnd == 0, "no line ends with an opening mark" .. (#badEnd > 0 and (" (" .. #badEnd .. ": " .. table.concat(badEnd, ", ", 1, math.min(#badEnd, 10)) .. ")") or ""))
    Wn():close()
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
Events.OnRenderTick.Add(tick)
say("start")
