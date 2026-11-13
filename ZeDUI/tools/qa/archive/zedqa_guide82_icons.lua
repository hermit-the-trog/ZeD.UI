-- ZeDUI/tools/qa/zedqa_guide82_icons.lua  (Nov 3 2026, QA; punch list 82, Build's 4bb09315: the game's small pictures in its text)
-- Every topic, the mouse text and then the controller text (the topics' own getText(true), set on the window's
-- topics, so no pad is faked): no file name, marker or tag left in a line; every picture the game names that loads
-- is drawn in a line (a line's height square); a picture that does not load is skipped without a double space.
-- Pictures: Barricading mid-clip (the mouse text), and a controller topic with button pictures. The Video effects
-- option put back. Shots zqa_g82i_<w>x<h>_*.png; grep "ZEDQA g8i".
local function say(s) print("ZEDQA g8i " .. tostring(s)) end
local G = ZeD and ZeD.Guide
if not G then say("ERR ZeD.Guide is not loaded"); say("DONE"); return end
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_g82i_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local function Wn() return G.get(0) end
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local was = {}
local res = { mouse = {}, pad = {} }
local padTopic

-- the pictures a text names, and how many of them load
local function named(text)
    local all, ok = 0, 0
    for path in tostring(text):gmatch("<%s*[Ii][Mm][Aa][Gg][Ee]%s*:%s*([^,>]+)") do
        all = all + 1
        if getTexture((path:gsub("%s+$", ""))) then ok = ok + 1 end
    end
    return all, ok
end
-- what the window laid out for the chosen topic: picture runs, and any text run with a leftover
local function laidOut(w)
    local tex, bad, dbl = 0, {}, 0
    for _, it in ipairs((w._g and w._g.items) or {}) do
        if it.kind == "line" then
            for _, r in ipairs(it.runs or {}) do
                if r.tex then tex = tex + 1
                elseif r.text then
                    if r.text:find("\1", 1, true) or r.text:find("<", 1, true) or r.text:find("%.png") or r.text:find("%[[%w_]+%]") then bad[#bad + 1] = r.text end
                    if r.text:find("%S  +%S") then dbl = dbl + 1 end
                end
            end
        end
    end
    return tex, bad, dbl
end

step(60, function()
    was.video = core:getOptionDoVideoEffects()
    core:setOptionDoVideoEffects(true)
    pcall(function() Mouse.setXY(sw - 4, sh - 4) end)
    G.open(0)
end)
for _, mode in ipairs({ "mouse", "pad" }) do
    step(10, function()
        local w = Wn()
        w:readTopics()
        if mode == "pad" then for _, t in ipairs(w.flat) do local ok, s = pcall(function() return t.entry:getText(true) end); if ok and s then t.text = s end end end
        say(mode .. ": " .. #w.flat .. " topics")
    end)
    for i = 1, 90 do
        step(3, function() local w = Wn(); local t = w.flat[i]; if t then w:choose(t.id, true) end end)
        step(3, function()
            local w = Wn(); local t = w.flat[i]
            if not t then return end
            local all, ok = named(t.text)
            local tex, bad, dbl = laidOut(w)
            if all > 0 or #bad > 0 then
                res[mode][#res[mode] + 1] = { title = t.title, all = all, ok = ok, tex = tex, bad = bad, dbl = dbl, t = t }
            end
        end)
    end
    step(5, function()
        local withPics, drawn, named_, loaded, leftovers, doubles = 0, 0, 0, 0, {}, 0
        for _, r in ipairs(res[mode]) do
            withPics = withPics + 1; drawn = drawn + r.tex; named_ = named_ + r.all; loaded = loaded + r.ok; doubles = doubles + r.dbl
            for _, b in ipairs(r.bad) do leftovers[#leftovers + 1] = r.title .. ": \"" .. b .. "\"" end
            say(string.format("%s %s: %d named, %d load, %d drawn", mode, r.title, r.all, r.ok, r.tex))
            if mode == "pad" and r.tex > 0 and not padTopic then padTopic = r.t end
        end
        check(withPics > 0, mode .. ": topics with pictures in their text: " .. withPics)
        check(drawn == loaded, mode .. ": every picture that loads is drawn (" .. drawn .. " of " .. loaded .. "; " .. named_ .. " named)")
        check(#leftovers == 0, mode .. ": no file name, marker or tag left in a line" .. (#leftovers > 0 and (" (" .. table.concat(leftovers, "; ") .. ")") or ""))
        check(doubles == 0, mode .. ": no double space where a picture was skipped (" .. doubles .. ")")
    end)
end
-- the pictures
step(10, function()
    local w = Wn()
    w:readTopics()
    for _, t in ipairs(w.flat) do if t.titleKey == "SurvivalGuide_barricades_title" then w:choose(t.id, true) end end
end)
step(150, function() shot("3_mid_clip") end)
step(10, function()
    local w = Wn()
    if not padTopic then say("(no controller topic with a picture)"); return end
    for _, t in ipairs(w.flat) do local ok, s = pcall(function() return t.entry:getText(true) end); if ok and s then t.text = s end end
    for _, t in ipairs(w.flat) do if t.id == padTopic.id then w:choose(t.id, true); say("controller topic: " .. t.title) end end
end)
step(120, function() shot("5_pad_text") end)
step(10, function()
    local w = Wn(); w:readTopics(); w:close()
    core:setOptionDoVideoEffects(was.video)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say("put back: video effects " .. tostring(was.video))
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
