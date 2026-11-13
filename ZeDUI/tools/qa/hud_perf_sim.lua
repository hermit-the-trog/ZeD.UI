-- ZeDUI/tools/qa/hud_perf_sim.lua  (Nov 7 2026, Build; the outside performance review, items 10 and 11): the
-- always-on HUD's moodles and watch, before and after the speed work, with no game running.
--   * Loads ZeD_Moodles.lua and ZeD_Watch.lua twice, each into its own sandbox on the same stubs: as they were at
--     BASE (git show, default 7f17686e: the last main before the work) and as they are in the checkout.
--   * Plays the same script into both, frame by frame, and compares everything they leave behind each frame:
--     the game's moodle column (x, y), ZeD's layer (x, y, size), M.rect, the moodle list, the notices and the note,
--     every texture and word drawn; the watch's size and spot, its click areas, the plate's state and LCD reading,
--     W.beltWatch and W.miniState, the parked clock and speed controls.
--   * Moodles, run A at 100 ms a frame: identical every frame. Run B at 16 ms a frame: the list is read at most
--     every 100 ms, so a level change shows at most 100 ms (plus one frame) later; outside that window identical,
--     and the notices come in the same order.
--   * Counts the game calls (getMoodleLevel, the highlight colours, getWornItems, isAlarmSet) and the Lua memory a
--     steady frame allocates (GC stopped), before and after.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/hud_perf_sim.lua [base-rev]
-- It prints FAIL lines, the numbers, and a last line "hud_perf_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]hud_perf_sim%.lua$", "")
local BASE = (arg and arg[1]) or "7f17686e"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function noop() end

local function readFile(path)
    local f = io.open(path, "rb"); if not f then return nil end
    local s = f:read("*a"); f:close(); return s
end
local function gitShow(path)
    local h = io.popen("git " .. (ROOT ~= "" and ('-C "' .. ROOT .. '" ') or "") .. "show " .. BASE .. ":" .. path)
    if not h then return nil end
    local s = h:read("*a"); h:close()
    if s == "" then return nil end
    return s
end

-- a value as text: tables by sorted key, functions as "fn", stub objects by their __name
local function ser(v, depth)
    depth = depth or 0
    local tv = type(v)
    if tv == "function" then return "fn" end
    if tv ~= "table" then return tostring(v) end
    if v.__name then return "<" .. tostring(v.__name) .. ">" end
    if depth > 4 then return "{..}" end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local parts = {}
    for _, k in ipairs(keys) do parts[#parts + 1] = tostring(k) .. "=" .. ser(v[k], depth + 1) end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function newEvents()
    return setmetatable({}, { __index = function(t, k)
        local e = { fns = {} }
        e.Add = function(fn) e.fns[#e.fns + 1] = fn end
        e.Remove = noop
        rawset(t, k, e)
        return e
    end })
end
local function fire(env, name, ...)
    local e = rawget(env.Events, name)
    if e then for _, fn in ipairs(e.fns) do fn(...) end end
end

local function load(src, name, env)
    local fn, err = loadstring(src, "@" .. name)
    if not fn then return false, err end
    setfenv(fn, env)
    return pcall(fn)
end

-- a panel base for ZeD_Panel:derive / :new; draws go to world.log
local function panelBase(world)
    local B = {}
    B.__index = B
    function B:getX() return self.x end
    function B:getY() return self.y end
    function B:setX(v) self.x = v end
    function B:setY(v) self.y = v end
    function B:getWidth() return self.w end
    function B:getHeight() return self.h end
    function B:setWidth(v) self.w = v end
    function B:setHeight(v) self.h = v end
    function B:getMouseX() return world.MX - self.x end
    function B:getMouseY() return world.MY - self.y end
    function B:getAbsoluteX() return self.x end
    function B:getAbsoluteY() return self.y end
    function B:isMouseOver() return world.mouseOver == true end
    function B:initialise() end
    function B:addToUIManager() end
    function B:setVisible(v) self.visible = v end
    function B:getIsVisible() return self.visible ~= false end
    function B:setCapture() end
    -- (draws are logged where they land on the screen: the checkout draws the note from its note layer at the
    -- screen's corner, the BASE copy from the moodle layer itself; the same picture logs the same)
    function B:drawTexture(t, x, y, a, r, g, b) world.log[#world.log + 1] = "tex " .. ser({ t, self.x + x, self.y + y, a, r, g, b }) end
    function B:drawText(s, x, y, r, g, b, a, f) world.log[#world.log + 1] = "chip text " .. ser({ s, self.x + x, self.y + y, r, g, b, a, f }) end
    function B:drawRectBorder(...) world.log[#world.log + 1] = "border " .. ser({ ... }) end
    return {
        derive = function(_, name) return setmetatable({}, { __index = B }) end,
        new = function(_, x, y, w, h) return setmetatable({ x = x, y = y, w = w, h = h, __name = "panel" }, B) end,   -- (drawn as <panel>)
    }
end

local function newT(tag)
    return {
        tag = tag, px = function(v) return v end, fontF1 = 1, fontF2 = 2, fontF4 = 4, fontF5 = 5, buttonH = 20, scale = 1,
        text = { r = 1, g = 1, b = 1, a = 1 }, textDim = { r = 0.6, g = 0.6, b = 0.6, a = 1 },
        positive = { r = 0, g = 1, b = 0, a = 1 }, danger = { r = 1, g = 0, b = 0, a = 1 },
        warning = { r = 1, g = 1, b = 0, a = 1 }, accent = { r = 1, g = 0.5, b = 0, a = 1 },
        borderS = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
    }
end

-- ===========================================================================
-- THE MOODLES
-- ===========================================================================
local MOODLE_FILE = "42/media/lua/client/ZeD/ZeD_Moodles.lua"
local NAMES = { "ENDURANCE", "TIRED", "HUNGRY", "PANIC", "SICK", "BORED", "UNHAPPY", "BLEEDING", "WET", "HAS_A_COLD",
    "ANGRY", "STRESS", "THIRST", "INJURED", "PAIN", "HEAVY_LOAD", "DRUNK", "DEAD", "ZOMBIE", "HYPERTHERMIA",
    "HYPOTHERMIA", "WINDCHILL", "CANT_SPRINT", "UNCOMFORTABLE", "NOXIOUS_SMELL", "FOOD_EATEN" }
local GBN = { FOOD_EATEN = 1, TIRED = 2, HUNGRY = 2, PANIC = 2, WET = 2, THIRST = 2, STRESS = 2 }

local function moodleWorld(src, label)
    local world = { label = label, log = {}, MX = -100, MY = -100, clock = 0, place = 1, notices = true,
                    uiVisible = true, standIn = nil, LV = { [0] = {}, [1] = {} }, players = {},
                    good = { 0.2, 0.8, 0.3 }, bad = { 0.9, 0.1, 0.2 },
                    calls = { level = 0, gbn = 0, colour = 0, getMoodles = 0 } }
    local env = setmetatable({}, { __index = _G })
    world.env = env
    env.print = noop
    env.require = noop
    env.Events = newEvents()
    env.getTimestampMs = function() return world.clock end
    world.T = newT("A")
    local MT = {}
    local seed = 12345
    for _, n in ipairs(NAMES) do
        seed = (seed * 1103515245 + 12345) % 2147483648
        local h = seed - 1073741824          -- some negative, as Java's identity hashes can be
        MT[n] = { __name = n, hashCode = function() return h end }
    end
    env.MoodleType = MT
    local function colour(c)
        return { getR = function() return c[1] end, getG = function() return c[2] end, getB = function() return c[3] end }
    end
    local core = {
        getOptionMoodleSize = function() return 2 end,
        getOptionFontSizeReal = function() return 1 end,
        getGoodHighlitedColor = function() world.calls.colour = world.calls.colour + 1; return colour(world.good) end,
        getBadHighlitedColor = function() world.calls.colour = world.calls.colour + 1; return colour(world.bad) end,
    }
    env.getCore = function() return core end
    for pn = 0, 1 do
        local md = {
            getMoodleLevel = function(_, t) world.calls.level = world.calls.level + 1; return world.LV[pn][t.__name] or 0 end,
            getGoodBadNeutral = function(_, t) world.calls.gbn = world.calls.gbn + 1; return GBN[t.__name] or 0 end,
            getMoodleDisplayString = function(_, t) return t.__name .. " name" end,
            getMoodleDescriptionString = function(_, t) return t.__name .. " is described here" end,
        }
        world.players[pn] = { __name = "P" .. pn,
            getMoodles = function() world.calls.getMoodles = world.calls.getMoodles + 1; return md end,
            getPlayerNum = function() return pn end }
    end
    world.alive = { [0] = true, [1] = false }
    env.getSpecificPlayer = function(pn) return world.alive[pn] and world.players[pn] or nil end
    world.mui = {}
    for pn = 0, 1 do
        local m = { x = 1900, y = 120, w = 48, h = 400, vis = true }
        function m:getX() return self.x end
        function m:getY() return self.y end
        function m:setX(v) self.x = v end
        function m:setY(v) self.y = v end
        function m:getWidth() return self.w end
        function m:getHeight() return self.h end
        function m:isVisible() return self.vis end
        world.mui[pn] = m
    end
    env.UIManager = { getMoodleUI = function(pn) return world.mui[pn] end, getMillisSinceLastRender = function() return 16 end }
    env.getPlayerScreenTop = function(pn) return pn == 0 and 0 or 540 end
    env.getPlayerScreenLeft = function() return 0 end
    env.getPlayerScreenWidth = function() return 1920 end
    env.getPlayerScreenHeight = function() return 540 end
    env.ISUIHandler = { allUIVisible = true }
    env.getTexture = function(path) return { __name = path, getWidth = function() return 32 end } end
    env.ZeD_Panel = panelBase(world)
    local hud = { _drawn = true, getIsVisible = function() return world.belt == true end, getY = function() return 500 end }
    local watch = { _belt = false, getIsVisible = function() return world.watch == true end,
                    getHeight = function() return 100 end, getY = function() return 10 end }
    local function lg(s) world.log[#world.log + 1] = s end
    env.ZeD = {
        Safe = { on = function() return world.safe == true end, register = noop },
        Settings = { moodlePlaceOption = { getValue = function() return world.place end },
                     moodleNoticesOn = function() return world.notices end },
        Belt = { getHUD = function(pn) return pn == 0 and hud or nil end },
        Watch = { getInstance = function() return watch end },
        Bubbles = { TRAIL_LEN = 3, cloudBody = function(...) lg("chip cloud " .. ser({ ... })) end,
                    cloudShadow = function(...) lg("chip shadow " .. ser({ ... })) end,
                    drawTrail = function(...) lg("chip trail " .. ser({ ... })) end, syncColours = noop },
        Px = { k = function() return 1 end, canvas = function(o, x, y, k) return { x = o.x + x, y = o.y + y, k = k } end },
        Atoms = { wrapText = function(s) return { s } end,
                  drawStatusDot = function(p, x, y, c, s) lg("chip dot " .. ser({ p, p.x + x, p.y + y, c, s })) end },
        TM = { getFontHeight = function(_, f) return 10 + f end },
        Scale = { root = function() return 1 end },
    }
    setmetatable(env.ZeD, { __index = function(_, k) if k == "T" then return world.T end end })
    local ok, err = load(src, label .. "/ZeD_Moodles.lua", env)
    world.ok, world.err = ok, err
    return world
end

-- the script, by time (ms): the same for both copies
local MOODLE_EVENTS = {
    { 0, function(w) w.LV[0].HUNGRY = 1; w.LV[0].TIRED = 2; fire(w.env, "OnGameStart") end },
    { 500, function(w) w.alive[1] = true; w.LV[1].WET = 2; w.LV[1].PANIC = 4; fire(w.env, "OnCreatePlayer", 1) end },
    { 1000, function(w) w.LV[0].THIRST = 1 end },
    { 1500, function(w) w.LV[0].HUNGRY = 2 end },
    -- (the pointer on the layer, nothing over it there: the engine's isMouseOver says so)
    { 2000, function(w) local L = w.env.ZeD.Moodles.getLayer(0); w.MX, w.MY = L.x + 5, L.y + 48 + 10 + 5; w.mouseOver = true end },
    { 2500, function(w) w.MX, w.MY = -100, -100; w.mouseOver = false; w.LV[0].FOOD_EATEN = 2 end },
    { 3000, function(w) w.LV[0].FOOD_EATEN = 3; w.LV[1].PANIC = 3 end },
    { 3500, function(w) w.place = 2 end },
    { 4500, function(w) w.place = 3; w.belt = true end },
    -- the Options apply new highlight colours in play (no Lua reload, no new theme)
    { 4800, function(w) w.good = { 0.5, 0.5, 1.0 }; w.bad = { 0.3, 0.9, 0.6 } end },
    { 5200, function(w) w.LV[0].STRESS = 3; w.LV[0].TIRED = 0 end },
    -- a new theme (ZeD.T) with the highlight colours changed by the Options (a Lua reload in the game)
    { 6000, function(w) w.T = newT("B"); w.good = { 0.1, 0.9, 0.9 }; w.bad = { 0.8, 0.4, 0.0 } end },
    { 6500, function(w)
        local rev = {}
        for i = #NAMES, 1, -1 do rev[#rev + 1] = { NAMES[i], "Art_" .. NAMES[i] } end
        w.env.ZeD.Moodles.setStandIn({ id = "quarters", order = rev, drawing = function(pn) return pn == 0 end })
    end },
    { 7000, function(w) w.LV[0].BORED = 1 end },
    { 7500, function(w) w.env.ZeD.Moodles.setStandIn({ id = "whole", whole = true, drawing = function() return true end }) end },
    { 8500, function(w) w.env.ZeD.Moodles.setStandIn(nil); w.place = 1; w.watch = true; w.belt = false end },
    { 9000, function(w) w.notices = false; local L = w.env.ZeD.Moodles.getLayer(0); w.MX, w.MY = L.x + 5, L.y + 5; w.mouseOver = true end },
    { 9600, function(w) w.LV[0].THIRST = 0; w.LV[0].PAIN = 2 end },
    { 10000, function(w) w.MX, w.MY = -100, -100; w.mouseOver = false; w.notices = true; w.LV[0].DRUNK = 1; fire(w.env, "OnGameStart"); fire(w.env, "OnCreatePlayer", 1) end },
    { 10500, function(w) w.LV[0].DRUNK = 2; w.place = 2 end },
    { 11000, function(w) w.env.ISUIHandler.allUIVisible = false end },
    { 11500, function(w) w.env.ISUIHandler.allUIVisible = true; w.LV[1].WET = 0 end },
}
local MOODLE_END = 12500

-- one frame: OnPreUIDraw (placement), then each layer's prerender and its note layer's render (the checkout draws
-- the note there; the BASE copy has none); what it left, as text
local function moodleFrame(w, notices)
    w.log = {}
    fire(w.env, "OnPreUIDraw")
    local M = w.env.ZeD.Moodles
    for pn = 0, 1 do
        local L = M.getLayer(pn)
        if L then
            L:prerender()
            if L._note then L._note:render() end
        end
    end
    local out = {}
    -- (beta 10: the note for the moodle under the pointer is the balloon, after the hover pause, not the cloud; while
    -- the pointer is on the layer the note is left out of the comparison, the notices that show by themselves stay in)
    local hov = (w.MX or -1) >= 0
    for pn = 0, 1 do
        local L = M.getLayer(pn)
        if L then
            local list = {}
            for i, m in ipairs(L._list or {}) do list[i] = m.key .. ":" .. m.level .. ":" .. m.gbn .. ":" .. m.art .. ":" .. ser(m.type) end
            out[#out + 1] = table.concat({ "P" .. pn, tostring(L._mode), tostring(L._show), ser({ L.x, L.y, L.w, L.h }),
                ser(L._rect), ser(M.rect(pn)), "mui " .. w.mui[pn].x .. "," .. w.mui[pn].y, table.concat(list, ";") }, " | ")
            if notices then out[#out + 1] = "notices " .. ser(L._notices) .. " at " .. tostring(L._noticeAt) .. " chip " .. ser((not hov) and L._chip or nil) end
        end
    end
    for _, s in ipairs(w.log) do
        if (notices and not hov) or s:sub(1, 4) ~= "chip" then out[#out + 1] = s end
    end
    return table.concat(out, "\n")
end

-- a run: both copies, frame by frame; returns per-frame texts and the event times
local function moodleRun(srcBefore, srcAfter, step)
    local A, B = moodleWorld(srcBefore, "before"), moodleWorld(srcAfter, "after")
    local frames = {}
    local ei = 1
    local t = 0
    while t < MOODLE_END do
        local evAt = nil
        while MOODLE_EVENTS[ei] and MOODLE_EVENTS[ei][1] <= t do
            MOODLE_EVENTS[ei][2](A); MOODLE_EVENTS[ei][2](B)
            evAt = MOODLE_EVENTS[ei][1]
            ei = ei + 1
        end
        A.clock, B.clock = t, t
        local okA, fa = pcall(moodleFrame, A, step >= 100)
        local okB, fb = pcall(moodleFrame, B, step >= 100)
        if not okA or not okB then
            check("moodles: the frame at " .. t .. " ms runs", false, tostring(fa) .. " / " .. tostring(fb))
            break
        end
        -- (run B: the notices compared by order, below)
        local ha, hb
        if step < 100 then
            local La, Lb = A.env.ZeD.Moodles.getLayer(0), B.env.ZeD.Moodles.getLayer(0)
            ha = La and La._notices and La._notices[1]
            hb = Lb and Lb._notices and Lb._notices[1]
        end
        frames[#frames + 1] = { t = t, a = fa, b = fb, ev = evAt, ha = ha, hb = hb }
        t = t + step
    end
    return frames, A, B
end

section("Moodles: both copies load")
local srcMB, srcMA = gitShow(MOODLE_FILE), readFile(ROOT .. MOODLE_FILE)
check("moodles: the BASE copy (" .. BASE .. ") is readable through git", srcMB ~= nil)
check("moodles: the checkout's copy is readable", srcMA ~= nil)
if srcMB and srcMA then
    local probeA, probeB = moodleWorld(srcMB, "before"), moodleWorld(srcMA, "after")
    check("moodles: before loads on the stubs", probeA.ok, probeA.err)
    check("moodles: after loads on the stubs", probeB.ok, probeB.err)

    section("Moodles run A (100 ms a frame): identical every frame")
    local fr, A, B = moodleRun(srcMB, srcMA, 100)
    local diff, firstDiff = 0, nil
    for _, f in ipairs(fr) do
        if f.a ~= f.b then diff = diff + 1; firstDiff = firstDiff or f end
    end
    check("run A: " .. #fr .. " frames, every one the same (placement, rect, list, notices, note, every draw)", diff == 0,
        firstDiff and (firstDiff.t .. " ms:\nBEFORE\n" .. firstDiff.a .. "\nAFTER\n" .. firstDiff.b))
    -- the script really covered the ground
    local sawRow, sawChip, sawLeft, sawQuarters = false, false, false, false
    for _, f in ipairs(fr) do
        if f.a:find("tex ", 1, true) then sawRow = true end
        if f.a:find("chip cloud", 1, true) then sawChip = true end
        if f.a:find("P0 | left", 1, true) then sawLeft = true end
        if f.a:find("Art_", 1, true) then sawQuarters = true end
    end
    check("run A drew the bottom row, a note, the left column and a stand-in's order", sawRow and sawChip and sawLeft and sawQuarters,
        ser({ sawRow, sawChip, sawLeft, sawQuarters }))
    print(string.format("   run A game calls: getMoodleLevel %d -> %d, highlight colours %d -> %d",
        A.calls.level, B.calls.level, A.calls.colour, B.calls.colour))

    section("Moodles run B (16 ms a frame): the same once a change is 100 ms old")
    local frB, AB, BB = moodleRun(srcMB, srcMA, 16)
    local lastEv, bad, maxLag, pending = -1e9, 0, 0, nil
    local firstBad
    for _, f in ipairs(frB) do
        if f.ev then lastEv = f.ev; pending = f.ev end
        if f.a == f.b then
            if pending then maxLag = math.max(maxLag, f.t - pending); pending = nil end
        elseif f.t - lastEv > 116 then
            bad = bad + 1; firstBad = firstBad or f
        end
    end
    check("run B: " .. #frB .. " frames, the same at every frame 116 ms or more after a change", bad == 0,
        firstBad and (firstBad.t .. " ms:\nBEFORE\n" .. firstBad.a .. "\nAFTER\n" .. firstBad.b))
    check("run B: a change shows within 100 ms plus one frame (" .. maxLag .. " ms)", maxLag <= 116, maxLag)
    -- the notices shown, in order (each moodle's turn), the same
    local seqA, seqB = {}, {}
    for _, f in ipairs(frB) do
        if f.ha ~= seqA[#seqA] then seqA[#seqA + 1] = f.ha end
        if f.hb ~= seqB[#seqB] then seqB[#seqB + 1] = f.hb end
    end
    local function nn(s) local o = {} for i, v in ipairs(s) do o[i] = tostring(v) end return table.concat(o, ",") end
    check("run B: the notices come in the same order", nn(seqA) == nn(seqB), nn(seqA) .. " / " .. nn(seqB))
    local perA, perB = AB.calls.level / #frB, BB.calls.level / #frB
    print(string.format("   run B game calls over %d frames: getMoodleLevel %d -> %d (%.1f -> %.1f a frame), getMoodles %d -> %d, highlight colours %d -> %d",
        #frB, AB.calls.level, BB.calls.level, perA, perB, AB.calls.getMoodles, BB.calls.getMoodles, AB.calls.colour, BB.calls.colour))
    check("run B: getMoodleLevel at least 5x fewer", BB.calls.level * 5 <= AB.calls.level, BB.calls.level .. " vs " .. AB.calls.level)
    check("run B: the highlight colours read at most once per list read (2 a read)", BB.calls.colour <= BB.calls.getMoodles * 2,
        BB.calls.colour .. " for " .. BB.calls.getMoodles .. " list reads")
    -- the colours changed in play at 4800 ms: the row's new tint (bad 0.3,0.9,0.6 at level 2 -> g 0.7, b 0.55;
    -- the old one gave g 0.3, b 0.35) within 100 ms
    local tintAt, tintBefore
    for _, f in ipairs(frB) do
        local has = f.b:find("6=0.7,7=0.55", 1, true) ~= nil
        if f.t < 4800 and has then tintBefore = f.t end
        if f.t >= 4800 and not tintAt and has then tintAt = f.t end
    end
    check("run B: the new tint is not drawn before the colours change", tintBefore == nil, tintBefore)
    check("run B: colours applied in play show in the row within 100 ms plus one frame",
        tintAt ~= nil and tintAt - 4800 <= 116, tintAt and (tintAt - 4800) or "never")

    section("Moodles: a steady frame's Lua memory")
    local function steady(src, label)
        local w = moodleWorld(src, label)
        w.LV[0].HUNGRY, w.LV[0].TIRED, w.LV[0].WET, w.LV[0].PANIC, w.LV[0].FOOD_EATEN = 1, 2, 2, 3, 3
        fire(w.env, "OnGameStart")
        w.place = 3; w.belt = true
        for i = 1, 20 do w.clock = i * 16; moodleFrame(w, false) end
        -- (the frame's own text record is left out: only what the module allocates)
        local M = w.env.ZeD.Moodles
        local L = M.getLayer(0)
        collectgarbage("collect"); collectgarbage("stop")
        local k0 = collectgarbage("count")
        for i = 21, 220 do
            w.clock = i * 16; w.log = {}
            fire(w.env, "OnPreUIDraw"); L:prerender()
        end
        local k1 = collectgarbage("count")
        collectgarbage("restart")
        return (k1 - k0) * 1024 / 200
    end
    local ba, aa = steady(srcMB, "before"), steady(srcMA, "after")
    print(string.format("   bottom row, 5 moodles, 16 ms frames: %.0f -> %.0f bytes a frame (the stubs' own draw log included in both)", ba, aa))
    check("moodles: a steady frame allocates less", aa < ba, ba .. " -> " .. aa)
end

-- ===========================================================================
-- THE WATCH
-- ===========================================================================
local WATCH_FILE = "42/media/lua/client/ZeD/ZeD_Watch.lua"
-- the plate's own control list (ZeD_Plate.lua's PL.controls, cut out of the real file) for the BASE copy
local function realControls()
    local s = readFile(ROOT .. "42/media/lua/client/ZeD/ZeD_Plate.lua") or ""
    local body = s:match("(function PL%.controls%(des, st, out%).-\nend)")
    if not body then return nil end
    local PL = {}
    local fn = loadstring("local PL = ...\n" .. body:gsub("\r", ""))
    fn(PL)
    return PL.controls
end
local CONTROLS = realControls()

local function plateDes(w, h, ids, light)
    local hits = {}
    for i, id in ipairs(ids) do
        local e = { id = id, x = i * 3, y = i * 2 + 1, w = 5, h = 4 }
        if id == "setup" or id == "setdn" then e.needs = "setOpen" end
        if id == "dial" then e.kind = "look" end
        hits[#hits + 1] = e
    end
    return { w = w, h = h, hits = hits, light = light }
end
local PLATES = {
    speed_keys = plateDes(40, 20, { "speed0", "speed1", "speed2", "speed3" }),
    digital_black = plateDes(50, 60, { "dial", "speed", "start", "alarm", "set", "light", "setup", "setdn" }, "bulb"),
    classic_black = plateDes(52, 62, { "dial", "speed", "start", "alarm", "crown", "setup", "setdn" }),
    expensive = plateDes(54, 64, { "speed", "start", "crown", "setup", "setdn" }),
}

local function mkItem(ft, digital, hour)
    return { __name = ft, alarmClock = true, armed = false, hour = hour or 6,
             getFullType = function() return ft end, isDigital = function() return digital end }
end

local function watchWorld(src, label)
    local world = { label = label, log = {}, clock = 1000, MX = 0, MY = 0, worn = {}, speed = 1, hour = 9, min = 41,
                    h24 = true, placeOpt = 2, simple = false, client = false, scale = 1, safe = false, playerOn = true,
                    modData = {}, calls = { worn = 0, alarm = 0, hourGet = 0 } }
    local env = setmetatable({}, { __index = _G })
    world.env = env
    env.print = noop
    env.require = noop
    env.Events = newEvents()
    env.getTimestampMs = function() return world.clock end
    env.instanceof = function(o, cls) return type(o) == "table" and o.alarmClock == true and cls == "AlarmClockClothing" end
    local IMeta = {}
    function IMeta.isAlarmSet(self) world.calls.alarm = world.calls.alarm + 1; return self.armed end
    function IMeta.getHour(self) world.calls.hourGet = world.calls.hourGet + 1; return self.hour end
    function IMeta.setHour(self, h) self.hour = h end
    function IMeta.setMinute() end
    function IMeta.setAlarmSet(self, v) self.armed = v end
    world.IMeta = IMeta
    local player = { __name = "P0" }
    function player:getWornItems()
        world.calls.worn = world.calls.worn + 1
        local list = world.worn
        return { size = function() return #list end,
                 get = function(_, i) local e = list[i + 1]
                     return { getItem = function() return e.item end, getLocation = function() return e.loc end } end }
    end
    function player:getModData() return world.modData end
    world.player = player
    env.getSpecificPlayer = function(pn) return (pn == 0 and world.playerOn) and player or nil end
    env.isClient = function() return world.client end
    local gt = { getDay = function() return 6 end, getHour = function() return world.hour end, getMinutes = function() return world.min end,
                 getTimeOfDay = function() return world.hour + world.min / 60 end, getMonth = function() return 6 end,
                 getYear = function() return 1993 end, setMultiplier = noop }
    env.getGameTime = function() return gt end
    local season = { getDawn = function() return 6 end, getDusk = function() return 21 end }
    local climate = { getAirTemperatureForCharacter = function() return 21.3 end, getSeason = function() return season end }
    env.getClimateManager = function() return climate end
    local core = { getOptionClock24Hour = function() return world.h24 end, getOptionTemperatureDisplayCelsius = function() return true end,
                   getScreenWidth = function() return 1920 end, getScreenHeight = function() return 1080 end }
    env.getCore = function() return core end
    local clock = { x = 1800, y = 10, w = 100, vis = true }
    function clock:getX() return self.x end
    function clock:getY() return self.y end
    function clock:setY(v) self.y = v end
    function clock:getWidth() return self.w end
    function clock:isVisible() return self.vis end
    function clock:setVisible(v) self.vis = v end
    local sc = { y = 40, vis = true }
    function sc:getY() return self.y end
    function sc:setY(v) self.y = v end
    function sc:isVisible() return self.vis end
    function sc:setVisible(v) self.vis = v end
    function sc:getCurrentGameSpeed() return world.speed end
    function sc:ButtonClicked(b) world.log[#world.log + 1] = "button " .. b end
    function sc:SetCurrentGameSpeed(n) world.speed = n end
    world.clockObj, world.sc = clock, sc
    env.UIManager = { getClock = function() return clock end, getSpeedControls = function() return sc end }
    env.getPlayerScreenLeft = function() return 0 end
    env.getPlayerScreenWidth = function() return 1920 end
    env.getPlayerScreenTop = function() return 0 end
    env.ISUIHandler = { allUIVisible = true }
    env.isMouseButtonDown = function() return false end
    env.getMouseX = function() return world.MX end
    env.getMouseY = function() return world.MY end
    env.ZeD_Panel = panelBase(world)
    local function lg(s) world.log[#world.log + 1] = s end
    local T = newT("A")
    env.ZeD = {
        T = T,
        tr = function(k, ...) local s = k; for _, a in ipairs({ ... }) do s = s .. ":" .. tostring(a) end; return s end,
        trPlain = function(k, a) return k .. (a and (":" .. a) or "") end,
        trEnglish = function(k, a) return k .. (a and (":" .. a) or "") end,
        trDefaults = noop,
        Safe = { on = function() return world.safe end, register = noop },
        logOnce = function(k, e) lg("logOnce " .. tostring(k) .. " " .. tostring(e)) end,
        Scale = { root = function() return world.scale end },
        Px = { k = function(s) return math.max(1, math.floor(s + 0.5)) end,
               canvas = function(o, x, y, k) return { x = x, y = y, k = k } end, tex = function(p) return p end },
        PhysPx = { texdir = "t/", plates = PLATES },
        Plate = { draw = function(cv, des, st, ctx) lg("plate k" .. cv.k .. " " .. ser(st)); return true end, controls = CONTROLS },
        WatchMini = { has = function(p) return p ~= "expensive" end },
        Settings = { watchPlaceOption = { getValue = function() return world.placeOpt end },
                     watchSimple = function() return world.simple end },
        Belt = { watchScreen = function() return 900, 1000, 40, "left" end },
        TM = { getFontHeight = function(_, f) return 10 + f end, MeasureStringX = function(_, f, s) return #s * 6 end },
        Molecules = { buttonW = function(s) return #s * 7 + 10 end, drawButton = function(...) lg("button " .. ser({ ... })) end },
        Surface = { fill = function(...) lg("fill " .. ser({ ... })) end },
        Atoms = { wrapText = function(s) return { s } end, drawStatusDot = function(...) lg("dot " .. ser({ ... })) end },
    }
    local ok, err = load(src, label .. "/ZeD_Watch.lua", env)
    world.ok, world.err = ok, err
    return world
end

local function wear(w, ft, loc, digital, extra)
    local it = setmetatable(mkItem(ft, digital), { __index = w.IMeta })
    w.worn = { { item = it, loc = loc } }
    if extra then table.insert(w.worn, 1, { item = setmetatable(mkItem(extra[1], true), { __index = w.IMeta }), loc = extra[2] }) end
    return it
end

local WATCH_SCRIPT = {
    [0] = function(w) fire(w.env, "OnGameStart") end,
    [5] = function(w) w.speed = 2 end,
    [10] = function(w) wear(w, "Base.WristWatch_Left_DigitalBlack", "LeftWrist", true) end,
    [15] = function(w) w.env.ZeD.Watch.act("alarm") end,
    [20] = function(w) w.env.ZeD.Watch.act("light") end,
    [25] = function(w) w.env.ZeD.Watch.act("set") end,
    [27] = function(w) w.env.ZeD.Watch.act("setup") end,
    [30] = function(w) w.env.ZeD.Watch.act("set") end,
    [35] = function(w) w.hour = 22 end,
    [40] = function(w) w.placeOpt = 1 end,
    [45] = function(w) w.env.ZeD.Watch.togglePop(true) end,
    [50] = function(w) w.mouseOver = true end,
    [60] = function(w) w.mouseOver = false end,
    [70] = function(w) w.clock = w.clock + 7000 end,
    [75] = function(w) wear(w, "Base.WristWatch_Right_Expensive", "RightWrist", false) end,
    [80] = function(w) wear(w, "Base.WristWatch_Left_Weird", "Necklace", false) end,
    [85] = function(w) wear(w, "Base.WristWatch_Left_ClassicBlack", "LeftWrist", false, { "Base.WristWatch_Left_DigitalBlack", "Necklace" }) end,
    [90] = function(w) w.simple = true; w.placeOpt = 2 end,
    [95] = function(w) w.env.ZeD.Watch.act("set") end,
    [100] = function(w) w.placeOpt = 1; w.env.ZeD.Watch.togglePop(true) end,
    [105] = function(w) w.worn = {} end,
    [110] = function(w) w.simple = false end,
    [115] = function(w) w.client = true end,
    [120] = function(w) w.client = false; w.speed = 0 end,
    [125] = function(w) w.playerOn = false end,
    [128] = function(w) w.playerOn = true; wear(w, "Base.WristWatch_Right_DigitalBlack", "RightWrist", true) end,
    [130] = function(w) w.h24 = false; w.scale = 2; w.placeOpt = 2 end,
    [140] = function(w) w.safe = true end,
    [145] = function(w) w.safe = false end,
}
local WATCH_FRAMES = 160

-- one frame: OnPreUIDraw, the belt's layout (W.beltWatch), the watch, the small one (W.miniState), OnPostUIDraw;
-- then an update-phase lookup outside the draw
local function watchFrame(w)
    w.log = {}
    local env, W = w.env, w.env.ZeD.Watch
    fire(env, "OnTick")
    fire(env, "OnPreUIDraw")
    local p = env.getSpecificPlayer(0)
    local bi, bp, bw = W.beltWatch(p)
    local inst = W.getInstance()
    if inst then inst:prerender() end
    local mini = (p and bi) and ser(W.miniState(p, bi)) or "-"
    fire(env, "OnPostUIDraw")
    local hits = {}
    for i, hr in ipairs(inst and inst._hit or {}) do hits[i] = hr.id .. "@" .. hr.x .. "," .. hr.y .. "," .. hr.w .. "," .. hr.h end
    local out = {
        "belt " .. ser({ bi, bp, bw }) .. " mini " .. mini,
        inst and ser({ inst.x, inst.y, inst.w, inst.h, inst.visible, inst._belt, inst._popped, inst._setOpen, inst._item, inst._s, inst._litUntil }) or "-",
        "hits " .. table.concat(hits, ";"),
        "clock " .. w.clockObj.y .. " " .. tostring(w.clockObj.vis) .. " speed " .. w.sc.y .. " " .. tostring(w.sc.vis),
    }
    for _, s in ipairs(w.log) do out[#out + 1] = s end
    -- outside the draw (the update phase): a fresh lookup each time
    local oi = W.beltWatch(p)
    out[#out + 1] = "outside " .. ser(oi)
    return table.concat(out, "\n")
end

section("The watch: both copies load")
local srcWB, srcWA = gitShow(WATCH_FILE), readFile(ROOT .. WATCH_FILE)
check("watch: the BASE copy is readable through git", srcWB ~= nil)
check("watch: the checkout's copy is readable", srcWA ~= nil)
check("watch: ZeD_Plate.lua's PL.controls cut out", CONTROLS ~= nil)
if srcWB and srcWA and CONTROLS then
    local A, B = watchWorld(srcWB, "before"), watchWorld(srcWA, "after")
    check("watch: before loads on the stubs", A.ok, A.err)
    check("watch: after loads on the stubs", B.ok, B.err)

    section("The watch: identical every frame")
    local diff, first, sawPlain, sawDeck, sawPop, sawBulb = 0, nil, false, false, false, false
    for f = 0, WATCH_FRAMES - 1 do
        local s = WATCH_SCRIPT[f]
        if s then s(A); s(B) end
        A.clock, B.clock = A.clock + 16, B.clock + 16
        -- a change between frames, read in the update phase before the next draw
        if f == 12 then wear(A, "Base.WristWatch_Right_DigitalBlack", "RightWrist", true); wear(B, "Base.WristWatch_Right_DigitalBlack", "RightWrist", true) end
        local okA, fa = pcall(watchFrame, A)
        local okB, fb = pcall(watchFrame, B)
        if not (okA and okB) then check("watch: frame " .. f .. " runs", false, tostring(fa) .. " / " .. tostring(fb)); break end
        if fa ~= fb then diff = diff + 1; first = first or { f = f, a = fa, b = fb } end
        if fa:find("fill ", 1, true) then sawPlain = true end
        if fa:find("speed0@", 1, true) then sawDeck = true end
        if fa:find("bulb=true", 1, true) then sawBulb = true end
        local ia = A.env.ZeD.Watch.getInstance()
        if ia and ia._belt and ia._popped and ia.w > 0 then sawPop = true end
    end
    check("watch: " .. WATCH_FRAMES .. " frames, every one the same (spot, click areas, plate state, LCD, belt, small watch, parking)",
        diff == 0, first and ("frame " .. first.f .. ":\nBEFORE\n" .. first.a .. "\nAFTER\n" .. first.b))
    check("watch: the script drew the tape deck, the bulb, the popped watch and the Simple watch", sawDeck and sawBulb and sawPop and sawPlain,
        ser({ sawDeck, sawBulb, sawPop, sawPlain }))
    print(string.format("   game calls over %d frames: getWornItems %d -> %d, isAlarmSet %d -> %d, getHour %d -> %d",
        WATCH_FRAMES, A.calls.worn, B.calls.worn, A.calls.alarm, B.calls.alarm, A.calls.hourGet, B.calls.hourGet))
    check("watch: getWornItems fewer", B.calls.worn < A.calls.worn, A.calls.worn .. " -> " .. B.calls.worn)
    check("watch: isAlarmSet and getHour as often as before", A.calls.alarm == B.calls.alarm and A.calls.hourGet == B.calls.hourGet)

    section("The watch: a steady frame")
    local function steady(src, label, belt)
        local w = watchWorld(src, label)
        fire(w.env, "OnGameStart")
        wear(w, "Base.WristWatch_Left_DigitalBlack", "LeftWrist", true)
        if belt then w.placeOpt = 1 end
        for i = 1, 10 do w.clock = w.clock + 16; watchFrame(w) end
        local W = w.env.ZeD.Watch
        local inst = W.getInstance()
        local c0 = w.calls.worn
        local h1 = inst._hit[1]
        collectgarbage("collect"); collectgarbage("stop")
        local k0 = collectgarbage("count")
        for i = 1, 200 do
            w.clock = w.clock + 16; w.log = {}
            fire(w.env, "OnPreUIDraw")
            local p = w.player
            local bi = W.beltWatch(p)          -- the belt's layout
            inst:prerender()
            if bi then W.miniState(p, bi) end
            fire(w.env, "OnPostUIDraw")
        end
        local k1 = collectgarbage("count")
        collectgarbage("restart")
        return (k1 - k0) * 1024 / 200, (w.calls.worn - c0) / 200, h1 ~= nil and rawequal(h1, inst._hit[1])
    end
    local bb, bw, _ = steady(srcWB, "before", false)
    local ab, aw, reused = steady(srcWA, "after", false)
    print(string.format("   corner watch: %.0f -> %.0f bytes a frame, getWornItems %.1f -> %.1f a frame", bb, ab, bw, aw))
    check("watch (corner): the click areas are the same tables frame to frame", reused == true)
    check("watch (corner): one worn-items walk a frame", aw == 1, aw)
    check("watch (corner): a steady frame allocates less", ab < bb, bb .. " -> " .. ab)
    local bb2, bw2 = steady(srcWB, "before", true)
    local ab2, aw2 = steady(srcWA, "after", true)
    print(string.format("   belt watch (tucked): %.0f -> %.0f bytes a frame, getWornItems %.1f -> %.1f a frame", bb2, ab2, bw2, aw2))
    check("watch (belt): one worn-items walk a frame (was " .. bw2 .. ")", aw2 == 1, aw2)
end

print("hud_perf_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
