-- ZeDUI/tools/qa/coverage_bugs_sim.lua  (Nov 12 2026): nine confirmed defects and the % traps found beside them, with
-- no game running. Each part runs the real code (the whole file, or the lines cut out of it, on Lua 5.1 stubs) and the
-- code before the fix (git show BASE) the same way: every check passes on the code now, and a CONTROL check fails the
-- run if the code before passes it too (a check that cannot tell the two apart proves nothing).
-- Lua 5.1's % is floored (-1 % 5 is 4); the game's Kahlua keeps the dividend's sign (-1 % 5 is -1: KahluaThread's
-- primitiveMath takes a - (int)(a / b) * b, so it also breaks once a / b passes 2^31). Every % in the code run here is
-- rewritten to that rule (__kmod), so a trap only the game shows shows here too.
--   KAHLUA    the rewrite itself: the game's answers for a run of expressions; % in strings and comments left alone
--   BROWSE    an object card's "previous" on the first object goes to the last (it threw, and the card closed); the
--             per-frame upkeep keeps an index outside the list inside it (a farm plot threw a second time)
--   TURN      the placement card: "-15" from 5 is 350 (it stored -10), D-pad left from 0 is 345, and an angle saved
--             below 0 reads 350 with the slider near the right end (it read -10 with the slider at the left)
--   CHANNEL   CH down on channel 01 of a two-way set goes to the last stored channel (it threw: l:get(-1))
--   POPOUT    Up on the station pop-out's first control wraps to the last (it stayed put)
--   TOOLTIP   the game's Tooltip Font option sizes ZeD's tooltips (Small, Medium and Large gave one size), and the
--             bigger size never stays on the body text afterwards, with the kept zooms and measures full or empty
--   HANDS     the hidden hand slots lose their hover zones (the held item's box popped up over nothing), the window
--             buttons keep their places in the list, and safe mode gets vanilla's list back untouched
--   CHORD     hold LB + tap RB zooms out and hold RB + tap LB zooms in, as the controller map says (it was the reverse)
--   ICONS     with only the belt handed back, the column's window buttons and their labels come back (they stayed
--             hidden for the session), and taking the belt again hides them again
--   INSPECT   Inspect on a garment marked with the controller opens ZeD's card, the marks gone (vanilla's window opened)
--   PRESS     the container buttons QA script finds and presses its buttons (it found none: a field that is gone), and
--             a miss prints ERR so the run counts it
--   CAROUSEL  the context menu's strip after a fast run of steps left settles in the middle copy (it landed in the
--             first, blank cells before it) and pages to a real option (it gave option -5)
--   STEPS     the options' wrapping stepper goes from the first step down to the last (it gave step 0)
-- What it can't show: the game itself (the tooltip, the belt's column and the cards on screen; QA in game).
-- Set PZ_LUA to the game's media/lua folder if it is not at E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/coverage_bugs_sim.lua
-- It prints FAIL lines and a last line "coverage_bugs_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]coverage_bugs_sim%.lua$", "")
local BASE = "9186a50a"   -- main when this work started: the code before the fixes
local PZ = os.getenv("PZ_LUA") or "E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua"
if not PZ:find("[/\\]$") then PZ = PZ .. "/" end

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function note(s) print("   " .. s) end
-- the same check on the code before must fail: okOld true is a failure here, nil means the code before was not there
local function control(name, okOld, detail)
    if okOld == nil then note("CONTROL " .. name .. ": no code before to try (git show " .. BASE .. ")"); return end
    checks = checks + 1
    if okOld then
        failed = failed + 1
        print("FAIL CONTROL " .. name .. ": the code before passes it too" .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    else
        note("before: " .. name .. " - no (" .. tostring(detail) .. ")")
    end
end

local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))   -- (the cuts below match LF line ends)
end
local function baseFile(rel)
    local p = io.popen('git -C "' .. (ROOT ~= "" and ROOT or ".") .. '" show ' .. BASE .. ':' .. rel .. ' 2>NUL')
    local s = p and p:read("*a") or ""
    if p then p:close() end
    return s ~= "" and (s:gsub("\r\n", "\n")) or nil
end
-- a repo file now, and as it was at BASE (nil when git cannot show it)
local function both(rel) return readFile(ROOT .. rel), baseFile(rel) end
-- the text from the first `from` (plain, searched from init) to the end of the line where the first `to` after it is
local function cut(src, from, to, init)
    if not src then return nil end
    local a = string.find(src, from, init or 1, true)
    if not a then return nil end
    local b = string.find(src, to, a + #from, true)
    if not b then return nil end
    local e = string.find(src, "\n", b + #to, true) or #src
    return string.sub(src, a, e)
end

-- ===========================================================================
-- THE GAME'S %: a - (int)(a / b) * b, the int cast truncating toward zero and saturating at 32 bits (Java d2i)
-- ===========================================================================
local function kmod(a, b)
    local q = a / b
    if q ~= q then q = 0
    elseif q >= 2147483647 then q = 2147483647
    elseif q <= -2147483648 then q = -2147483648
    elseif q >= 0 then q = math.floor(q)
    else q = math.ceil(q) end
    return a - q * b
end

-- Lua source to tokens: { t = "name" | "kw" | "number" | "string" | "op", v = text, s = first, e = last }
local KW = {}
for w in string.gmatch("and break do else elseif end false for function if in local nil not or repeat return then true until while", "%a+") do KW[w] = true end
local function tokens(src)
    local out, i, n = {}, 1, #src
    while i <= n do
        local c = string.sub(src, i, i)
        if string.find(c, "^%s") then
            i = i + 1
        elseif string.sub(src, i, i + 1) == "--" then
            local lvl = string.match(src, "^%[(=*)%[", i + 2)
            if lvl then
                local close = "]" .. lvl .. "]"
                local e = string.find(src, close, i + 4 + #lvl, true)
                i = (e or n) + #close
            else
                local e = string.find(src, "\n", i, true)
                i = (e or n) + 1
            end
        elseif c == "[" and string.find(src, "^%[=*%[", i) then
            local lvl = string.match(src, "^%[(=*)%[", i)
            local close = "]" .. lvl .. "]"
            local e = string.find(src, close, i + 2 + #lvl, true)
            local j = (e or n) + #close - 1
            out[#out + 1] = { t = "string", s = i, e = j }
            i = j + 1
        elseif c == '"' or c == "'" then
            local j = i + 1
            while j <= n do
                local d = string.sub(src, j, j)
                if d == "\\" then j = j + 2
                elseif d == c then break
                else j = j + 1 end
            end
            out[#out + 1] = { t = "string", s = i, e = j }
            i = j + 1
        elseif string.find(c, "^[%a_]") then
            local j = (string.find(src, "[^%w_]", i) or (n + 1)) - 1
            local w = string.sub(src, i, j)
            out[#out + 1] = { t = KW[w] and "kw" or "name", v = w, s = i, e = j }
            i = j + 1
        elseif string.find(c, "^%d") or (c == "." and string.find(string.sub(src, i + 1, i + 1), "^%d")) then
            local _, j = string.find(src, "^0[xX]%x+", i)
            if not j then
                _, j = string.find(src, "^%d*%.?%d*", i)
                local _, ej = string.find(src, "^[eE][%+%-]?%d+", j + 1)
                if ej then j = ej end
            end
            out[#out + 1] = { t = "number", s = i, e = j }
            i = j + 1
        else
            local three, two = string.sub(src, i, i + 2), string.sub(src, i, i + 1)
            local op = c
            if three == "..." then op = three
            elseif two == ".." or two == "==" or two == "~=" or two == "<=" or two == ">=" then op = two end
            out[#out + 1] = { t = "op", v = op, s = i, e = i + #op - 1 }
            i = i + #op
        end
    end
    return out
end
local function isOp(t, v) return t ~= nil and t.t == "op" and t.v == v end
local function isUnaryOp(t) return t ~= nil and ((t.t == "op" and (t.v == "-" or t.v == "#")) or (t.t == "kw" and t.v == "not")) end
-- the token before a "-" decides: after a value it is a minus, anywhere else a sign
local function minusIsSign(T, i)
    local p = T[i - 1]
    if not p then return true end
    if p.t == "name" or p.t == "number" or p.t == "string" then return false end
    if p.t == "kw" then return not (p.v == "nil" or p.v == "true" or p.v == "false" or p.v == "end") end
    return not (p.v == ")" or p.v == "]" or p.v == "}" or p.v == "...")
end
-- the first token of the suffixed expression (a.b, f(x), t[k], o:m(x), a group) that ends at token j
local function suffixedStart(T, M, j)
    while true do
        local t = T[j]
        if t.t == "op" and (t.v == ")" or t.v == "]" or t.v == "}") then
            local m = M[j]
            local p = T[m - 1]
            if p and (p.t == "name" or isOp(p, ")") or isOp(p, "]")) then j = m - 1 else return m end
        elseif t.t == "string" then
            local p = T[j - 1]
            if p and (p.t == "name" or isOp(p, ")") or isOp(p, "]")) then j = j - 1 else return j end
        elseif t.t == "name" then
            local p = T[j - 1]
            if isOp(p, ".") or isOp(p, ":") then j = j - 2 else return j end
        else
            return j
        end
    end
end
-- the first token of the operand ending at j, at the level of unary operators and powers
local function unaryStart(T, M, j)
    local s = suffixedStart(T, M, j)
    while isOp(T[s - 1], "^") do s = suffixedStart(T, M, s - 2) end
    while true do
        local p = T[s - 1]
        if isOp(p, "-") then
            if not minusIsSign(T, s - 1) then break end
            s = s - 1
        elseif isOp(p, "#") or (p and p.t == "kw" and p.v == "not") then
            s = s - 1
        else
            break
        end
    end
    return s
end
-- the last token of the suffixed expression that starts at token j
local function suffixedEnd(T, M, j)
    local t = T[j]
    local e = j
    if isOp(t, "(") or isOp(t, "{") then e = M[j] end
    if not (t.t == "name" or isOp(t, "(")) then return e end
    while true do
        local nx = T[e + 1]
        if isOp(nx, ".") or isOp(nx, ":") then e = e + 2
        elseif isOp(nx, "[") or isOp(nx, "(") or isOp(nx, "{") then e = M[e + 1]
        elseif nx and nx.t == "string" then e = e + 1
        else return e end
    end
end
local function unaryEnd(T, M, j)
    while isUnaryOp(T[j]) do j = j + 1 end
    local e = suffixedEnd(T, M, j)
    if isOp(T[e + 1], "^") then e = unaryEnd(T, M, e + 2) end   -- (a power binds tighter, right to left)
    return e
end
--- src with every % operator (not those in strings or comments) turned into __kmod(left, right)
local function kahluaPct(src)
    while true do
        local T = tokens(src)
        local M, stack, k = {}, {}, nil
        for i, t in ipairs(T) do
            if t.t == "op" then
                if t.v == "(" or t.v == "[" or t.v == "{" then stack[#stack + 1] = i
                elseif t.v == ")" or t.v == "]" or t.v == "}" then
                    local o = table.remove(stack)
                    if o then M[o], M[i] = i, o end
                elseif t.v == "%" and not k then k = i end
            end
        end
        if not k then return src end
        local ls = unaryStart(T, M, k - 1)
        while isOp(T[ls - 1], "*") or isOp(T[ls - 1], "/") do ls = unaryStart(T, M, ls - 2) end   -- (a * b % c is (a * b) % c)
        local re = unaryEnd(T, M, k + 1)
        local a, b = T[ls].s, T[re].e
        src = string.sub(src, 1, a - 1) .. "__kmod(" .. string.sub(src, a, T[k].s - 1) .. "," .. string.sub(src, T[k].e + 1, b) .. ")" .. string.sub(src, b + 1)
    end
end

-- A world: a fresh global table for the files run in it (the sim's own globals stay out), Lua's library underneath.
local function world(t)
    local W = setmetatable(t or {}, { __index = _G })
    rawset(W, "__kmod", kmod)
    if rawget(W, "require") == nil then rawset(W, "require", function() end) end
    if rawget(W, "print") == nil then rawset(W, "print", function() end) end
    return W
end
--- run src (its % the game's) in world W; returns pcall's results
local function run(W, src, name)
    if not src then return false, tostring(name) .. ": no source" end
    local f, err = loadstring(kahluaPct(src), "=" .. name)
    if not f then return false, err end
    setfenv(f, W)
    return pcall(f)
end

-- ===========================================================================
-- KAHLUA
-- ===========================================================================
section("KAHLUA")
do
    -- (each answer is the one the game's own Kahlua VM gives for the same line: 42.22.2, run through its compiler)
    local cases = {
        { "return -1 % 5", -1 }, { "return 7 % 3", 1 }, { "return -7 % 3", -1 }, { "return 6 % -4", 2 },
        { "return (1 - 1 - 1) % 3 + 1", 0 }, { "return 5.5 % 2", 1.5 }, { "return -5.5 % 2", -1.5 },
        { "local t = { a = { b = 7 } }; return t.a.b % 4", 3 },
        { "local function f(x) return x end; return f(-7) % 3", -1 },
        { "local o = { n = function(self) return -3 end }; return o:n() % 5", -3 },
        { "local t = { 4, 5 }; return t[2] % 3 + t[1] % 3", 3 },
        { "return 2 * -7 % 3", -2 }, { "return -7 % 3 * 2", -2 }, { "return 10 % 4 % 3", 2 },
        { "return #'abcde' % 3", 2 }, { "return 2 ^ 2 % 3", 1 }, { "return 5 % 2 ^ 2", 1 }, { "return -2 ^ 2 % 3", -1 },
        { "return ((-1 % 5) + 5) % 5", 4 },
        { "return 2 ^ 40 % 3", 2 ^ 40 - 2147483647 * 3 },   -- (past 2^31 the game's int cast saturates)
        { "local s = string.format('%d%%', -1 % 5); return s", "-1%" },
        { "-- a % in a comment\nreturn 3 % 2 --[[ and % here ]]", 1 },
        { "local s = [[50% off]] .. -3 % 2; return s", "50% off-1" },
    }
    for _, c in ipairs(cases) do
        local ok, v = run(world({}), c[1], "case")
        check("KAHLUA " .. c[1]:gsub("\n", " ") .. " gives " .. tostring(c[2]), ok and v == c[2], ok and tostring(v) or v)
    end
    check("KAHLUA Lua 5.1 itself floors (-1 % 5 is 4), so the rewrite is needed", -1 % 5 == 4)
end

-- ===========================================================================
-- BROWSE: ObjectCards.lua OC.browse and OC.tick
-- ===========================================================================
section("BROWSE")
do
    local now, old = both("42/media/lua/client/ZeD/ObjectCards.lua")
    check("BROWSE ObjectCards.lua reads", now ~= nil)
    local function probe(src)
        local code = cut(src, "function OC.browse(e, dir)", "\nend")
        if not code then return nil, "OC.browse not found" end
        local W = world({ OC = { REFRESH = 15 } })
        local ok, err = run(W, code, "OC.browse")
        if not ok then return nil, err end
        local function step(n, idx, dir)
            local list = {}
            for i = 1, n do list[i] = { key = "o" .. i } end
            local e = { list = list, idx = idx, t = list[idx] }
            local ok2, err2 = pcall(W.OC.browse, e, dir)
            if not ok2 then return "threw: " .. tostring(err2) end
            return tostring(e.idx) .. " " .. tostring(e.t and e.t.key) .. " " .. tostring(e.t and e.t._refreshT)
        end
        return { prev1of3 = step(3, 1, -1), next3of3 = step(3, 3, 1), prev2of3 = step(3, 2, -1), prev1of2 = step(2, 1, -1),
                 next1of3 = step(3, 1, 1) }
    end
    local r, err = probe(now)
    check("BROWSE the step is found and runs", r ~= nil, err)
    if r then
        check("BROWSE previous on 1 of 3 goes to 3", r.prev1of3 == "3 o3 15", r.prev1of3)
        check("BROWSE next on 3 of 3 goes to 1", r.next3of3 == "1 o1 15", r.next3of3)
        check("BROWSE previous on 2 of 3 goes to 1", r.prev2of3 == "1 o1 15", r.prev2of3)
        check("BROWSE previous on 1 of 2 goes to 2", r.prev1of2 == "2 o2 15", r.prev1of2)
        check("BROWSE next on 1 of 3 goes to 2", r.next1of3 == "2 o2 15", r.next1of3)
    end
    local ro = old and probe(old)
    control("BROWSE previous on 1 of 3 goes to 3", ro and ro.prev1of3 == "3 o3 15", ro and ro.prev1of3)

    -- the upkeep of a kind that keeps going (farm plots) with the index the old step left (0): the first object
    local function tickProbe(src)
        local code = cut(src, "function OC.tick(e, player)", "\nend")
        if not code then return nil, "OC.tick not found" end
        local W = world({ OC = { REFRESH = 15, LEASH = 3, BROWSE_EVERY = 60, squareDist = function() return 0 end },
            sixtieths = function() return 1 end, beat = function() return 0 end, browsePhase = function() return 0 end,
            getTimestampMs = function() return 1000 end, ZeD = { logOnce = function() end } })
        local ok, err = run(W, code, "OC.tick")
        if not ok then return nil, err end
        local live = { { key = "a", ok = true }, { key = "b", ok = true }, { key = "c", ok = true } }
        local def = { keepOnLoss = true, valid = function(o) return o ~= nil and o.ok == true end,
                      nearby = function() return live end, refresh = function() end }
        local e = { def = def, t = nil, idx = 0, list = live }
        local player = { getVehicle = function() return nil end, isDead = function() return false end }
        local ok2, res = pcall(W.OC.tick, e, player)
        if not ok2 then return "threw: " .. tostring(res) end
        return tostring(res) .. " " .. tostring(e.idx) .. " " .. tostring(e.t and e.t.key)
    end
    local t, terr = tickProbe(now)
    check("BROWSE the upkeep is found and runs", t ~= nil, terr)
    check("BROWSE a farm plot's upkeep with index 0 keeps the card on the first plot", t == "true 1 a", t)
    local to = old and tickProbe(old)
    control("BROWSE a farm plot's upkeep with index 0 keeps the card on the first plot", to and to == "true 1 a", to)
end

-- ===========================================================================
-- TURN: ObjectCardPlacement.lua setAxis and axisRow
-- ===========================================================================
section("TURN")
do
    local now, old = both("42/media/lua/client/ZeD/ObjectCardPlacement.lua")
    check("TURN ObjectCardPlacement.lua reads", now ~= nil)
    local DEG = string.char(176)
    local function probe(src)
        local code = cut(src, "local OC = ZeD.ObjectCards", "\n    return h\nend")
        if not code then return nil, "the axes and their rows not found" end
        code = code .. "\nreturn { setAxis = setAxis, axisRow = axisRow, AXES = AXES }\n"
        local shown, zones, buttons = {}, {}, {}
        local UI = { buttonW = function() return 40 end, button = function(card, x, y, label, o) buttons[label] = o end }
        local c0 = { r = 0, g = 0, b = 0, a = 1 }
        local T = { px = function(u) return u end, buttonH = 20, fontF1 = "F1", fontF3 = "F3", accent = c0, borderS = c0,
                    surf3 = c0, text = c0 }
        local W = world({
            ZeD = { ObjectCards = { ui = UI }, T = T, TM = { getFontHeight = function() return 10 end },
                    Atoms = { drawTextRight = function(card, s) shown.val = s end, fillBarCompactH = function() return 6 end,
                              drawSmoothBar = function(card, x, y, w, f) shown.f = f end, frame = function() end },
                    tr = function(k) return k end, Focus = { mark = function() end } },
            getText = function(k) return k end,
        })
        local ok, A = run(W, code, "ObjectCardPlacement")
        if not ok then return nil, A end
        local card = { drawText = function() end, focusOf = function() return nil end, drawRect = function() end,
                       zone = function(self, z) zones[z.fid] = z end }
        local function newT(rx, rz)
            local item = { rx = rx, ry = 0, rz = rz }
            function item:getWorldXRotation() return self.rx end
            function item:getWorldYRotation() return self.ry end
            function item:getWorldZRotation() return self.rz end
            function item:setWorldXRotation(v) self.rx = v end
            function item:setWorldYRotation(v) self.ry = v end
            function item:setWorldZRotation(v) self.rz = v end
            local obj = {}
            function obj:setExtendedPlacement(b) self.ext = b end
            return { item = item, obj = obj }
        end
        local AX, AZ = A.AXES.turn[1], A.AXES.turn[3]
        local res = {}
        local ok2, err2 = pcall(function()
            local t = newT(0, 5)                                   -- "-15" on Z from 5
            A.axisRow(card, 0, 0, 400, t, "turn", AZ)
            buttons["-15"].run()
            res.nudge = t.item.rz
            t = newT(0, 0)                                         -- D-pad left on X from 0
            A.axisRow(card, 0, 0, 400, t, "turn", AX)
            zones["p3:turn:x"].dpad("left")
            res.dpad = t.item.rx
            t = newT(0, 350)                                       -- "+15" on Z from 350
            A.axisRow(card, 0, 0, 400, t, "turn", AZ)
            buttons["+15"].run()
            res.up = t.item.rz
            t = newT(0, -10)                                       -- an angle saved below 0 by the build before
            A.axisRow(card, 0, 0, 400, t, "turn", AZ)
            res.val, res.f = shown.val, shown.f
            t = newT(0, 90)
            A.axisRow(card, 0, 0, 400, t, "turn", AZ)
            res.val90, res.f90 = shown.val, shown.f
            t = newT(0, 359.6)
            A.axisRow(card, 0, 0, 400, t, "turn", AZ)
            res.val360 = shown.val
        end)
        if not ok2 then return nil, err2 end
        return res
    end
    local r, err = probe(now)
    check("TURN the card's axes are found and run", r ~= nil, err)
    if r then
        check("TURN \"-15\" from 5 stores 350", r.nudge == 350, r.nudge)
        check("TURN D-pad left on X from 0 stores 345", r.dpad == 345, r.dpad)
        check("TURN \"+15\" from 350 stores 5", r.up == 5, r.up)
        check("TURN an angle saved at -10 reads 350", r.val == "350" .. DEG, r.val)
        check("TURN an angle saved at -10 puts the slider at 350 / 360", r.f and math.abs(r.f - 350 / 360) < 1e-9, r.f)
        check("TURN 90 reads 90 with the slider a quarter along", r.val90 == "90" .. DEG and r.f90 == 0.25, tostring(r.val90) .. " " .. tostring(r.f90))
        check("TURN 359.6 reads 0", r.val360 == "0" .. DEG, r.val360)
    end
    local ro = old and probe(old)
    control("TURN \"-15\" from 5 stores 350", ro and ro.nudge == 350, ro and ro.nudge)
    control("TURN D-pad left on X from 0 stores 345", ro and ro.dpad == 345, ro and ro.dpad)
    control("TURN an angle saved at -10 reads 350", ro and ro.val == "350" .. DEG, ro and ro.val and (ro.val:gsub(DEG, " deg")))
    control("TURN an angle saved at -10 puts the slider at 350 / 360", ro and ro.f ~= nil and math.abs(ro.f - 350 / 360) < 1e-9, ro and ro.f)
end

-- ===========================================================================
-- CHANNEL: ZeD_RadioOps.lua O.chStep
-- ===========================================================================
section("CHANNEL")
do
    local now, old = both("42/media/lua/client/ZeD/ZeD_RadioOps.lua")
    check("CHANNEL ZeD_RadioOps.lua reads", now ~= nil)
    local function probe(src)
        local code = cut(src, "function O.chStep(chr, part, dir)", "\nend")
        if not code then return nil, "O.chStep not found" end
        local W = world({ O = {}, stopScan = function() end,
            presetsOf = function(part) return part.dd, nil, part.l end,
            _get = function(o, m, d) local f = o and o[m]; if f then return f(o) end; return d end,
            setChannel = function(chr, part, hz) part.set = hz; return true end })
        local ok, err = run(W, code, "O.chStep")
        if not ok then return nil, err end
        local function stepFrom(freqs, cur, dir)
            local items = {}
            for i, hz in ipairs(freqs) do items[i] = { getFrequency = function() return hz end } end
            -- the stored channels: a Java ArrayList, read from 0, that throws past either end
            local l = { size = function() return #items end,
                        get = function(_, i)
                            if i < 0 or i >= #items then error("IndexOutOfBoundsException: Index " .. i .. " out of bounds for length " .. #items) end
                            return items[i + 1]
                        end }
            local part = { dd = { getChannel = function() return cur end }, l = l }
            local ok2, err2 = pcall(W.O.chStep, nil, part, dir)
            if not ok2 then return "threw: " .. tostring(err2) end
            return part.set
        end
        local C = { 88100, 95300, 101700 }
        return { down01 = stepFrom(C, 88100, -1), up03 = stepFrom(C, 101700, 1), down02 = stepFrom(C, 95300, -1),
                 one = stepFrom({ 88100 }, 88100, -1), off = stepFrom(C, 99900, -1), offUp = stepFrom(C, 99900, 1) }
    end
    local r, err = probe(now)
    check("CHANNEL the step is found and runs", r ~= nil, err)
    if r then
        check("CHANNEL CH down on 01 of 3 goes to 03", r.down01 == 101700, r.down01)
        check("CHANNEL CH up on 03 of 3 goes to 01", r.up03 == 88100, r.up03)
        check("CHANNEL CH down on 02 goes to 01", r.down02 == 88100, r.down02)
        check("CHANNEL one stored channel stays on 01", r.one == 88100, r.one)
        check("CHANNEL off the stored channels: down to the last, up to the first", r.off == 101700 and r.offUp == 88100,
            tostring(r.off) .. " " .. tostring(r.offUp))
    end
    local ro = old and probe(old)
    control("CHANNEL CH down on 01 of 3 goes to 03", ro and ro.down01 == 101700, ro and ro.down01)
end

-- ===========================================================================
-- POPOUT: StationPopout.lua move
-- ===========================================================================
section("POPOUT")
do
    local now, old = both("42/media/lua/client/ZeD/StationPopout.lua")
    check("POPOUT StationPopout.lua reads", now ~= nil)
    local function probe(src)
        local code = cut(src, "function ZeD_StationPopout:move(d)", "\nend")
        if not code then return nil, "move not found" end
        local W = world({ ZeD_StationPopout = {}, getSoundManager = function() return { playUISound = function() end } end })
        local ok, err = run(W, code, "ZeD_StationPopout:move")
        if not ok then return nil, err end
        local function mv(fi, d, n)
            local self = { fi = fi, controls = function() local c = {}; for i = 1, n do c[i] = i end; return c end }
            W.ZeD_StationPopout.move(self, d)
            return self.fi
        end
        return { up1 = mv(1, -1, 4), down4 = mv(4, 1, 4), up2 = mv(2, -1, 4), one = mv(1, -1, 1) }
    end
    local r, err = probe(now)
    check("POPOUT the move is found and runs", r ~= nil, err)
    if r then
        check("POPOUT Up on the first of 4 goes to the last", r.up1 == 4, r.up1)
        check("POPOUT Down on the last of 4 goes to the first", r.down4 == 1, r.down4)
        check("POPOUT Up on the second goes to the first", r.up2 == 1, r.up2)
        check("POPOUT one control stays", r.one == 1, r.one)
    end
    local ro = old and probe(old)
    control("POPOUT Up on the first of 4 goes to the last", ro and ro.up1 == 4, ro and ro.up1)
end

-- ===========================================================================
-- TOOLTIP: the real Scale.lua, Overrides/TextScale.lua and Overrides/Tooltip.lua with the game's own ISToolTip.lua
-- and ISRichTextPanel.lua, on a stand-in text manager, at a 4K root (2.0)
-- ===========================================================================
section("TOOLTIP")
do
    local van = { readFile(PZ .. "client/ISUI/ISRichTextPanel.lua"), readFile(PZ .. "client/ISUI/ISToolTip.lua") }
    check("TOOLTIP the game's ISRichTextPanel.lua and ISToolTip.lua read (PZ_LUA)", van[1] and van[2], PZ)
    local scaleNow, scaleOld = both("42/media/lua/shared/ZeD/Scale.lua")
    local textNow, textOld = both("42/media/lua/client/ZeD/Overrides/TextScale.lua")
    local tipNow, tipOld = both("42/media/lua/client/ZeD/Overrides/Tooltip.lua")
    -- Kahlua's string extras the game's files use
    string.trim = string.trim or function(s) return (string.gsub(string.gsub(s, "^%s+", ""), "%s+$", "")) end
    string.contains = string.contains or function(s, sub) return string.find(s, sub, 1, true) ~= nil end
    string.split = string.split or function(s, sep)
        local t = {}
        for p in string.gmatch(s, "([^" .. sep .. "]+)") do t[#t + 1] = p end
        return t
    end
    local F = {}
    for i = 1, 5 do F[i] = { name = "F" .. i, h = 77, adv = 30 } end   -- (the role fonts: a 64 px face, 77 px lines)
    local ROLE_PX = { 11, 13, 13, 16, 20 }
    local TITLE = "Claw Hammer"
    local DESC = "Pulls nails out of planks and builds walls."

    local function tooltipWorld(scaleSrc, textSrc, tipSrc)
        local W = world({})
        local draws = {}
        W.UIFont = { Small = { name = "Small", h = 16, adv = 7 }, Medium = { name = "Medium", h = 19, adv = 8 },
                     Large = { name = "Large", h = 24, adv = 10 }, NewSmall = { name = "NewSmall", h = 16, adv = 7 } }
        local realTM = {
            MeasureStringX = function(_, font, s) return #tostring(s) * (font and font.adv or 7) end,
            MeasureStringY = function(_, font) return font and font.h or 16 end,
            getFontHeight = function(_, font) return font and font.h or 16 end,
            getFontFromEnum = function(_, font) return { getLineHeight = function() return font and font.h or 16 end } end,
        }
        W.getTextManager = function() return realTM end
        W.tipOption = "Small"
        local core = { getOptionFontSize = function() return 2 end, getOptionTooltipFont = function() return W.tipOption end,
                       getScreenWidth = function() return 3840 end, getScreenHeight = function() return 2160 end,
                       getKey = function() return 0 end }
        W.getCore = function() return core end
        W.isServer = function() return false end
        W.getMouseX = function() return 100 end
        W.getMouseY = function() return 100 end
        W.getKeyName = function() return "" end
        W.getPlayerScreenLeft = function() return 0 end
        W.getPlayerScreenTop = function() return 0 end
        local function newJO()
            return { setConsumeMouseEvents = function() end,
                     DrawText = function(_, font, str, x, y, ...)
                         local z = 1
                         if select("#", ...) == 5 then z = (...) end   -- (font, str, x, y, zoom, r, g, b, a): the zoom path
                         draws[#draws + 1] = { font = font, str = str, z = z }
                     end }
        end
        local E = {}
        E.__index = E
        function E:derive(name) local o = {}; setmetatable(o, self); self.__index = self; o.Type = name; return o end
        function E:new(x, y, w, h) local o = {}; setmetatable(o, self); self.__index = self; o.x, o.y, o.width, o.height = x, y, w, h; return o end
        function E:drawText(str, x, y, r, g, b, a, font) if self.javaObject then self.javaObject:DrawText(font or W.UIFont.Small, str, x, y, r, g, b, a) end end
        E.drawTextRight, E.drawTextCentre = E.drawText, E.drawText
        local function noop() end
        for _, k in ipairs({ "drawRectBorder", "drawRect", "drawTextureScaled", "drawTextureScaledAspect", "updateAutoScroll",
                             "initialise", "removeFromUIManager", "setVisible", "setStencilRect", "clearStencilRect", "prerender" }) do
            E[k] = noop
        end
        function E:setWidth(w) self.width = w end
        function E:setHeight(h) self.height = h end
        function E:getWidth() return self.width end
        function E:getHeight() return self.height end
        function E:setX(x) self.x = x end
        function E:setY(y) self.y = y end
        function E:getX() return self.x end
        function E:getY() return self.y end
        function E:getAbsoluteX() return self.x end
        function E:getAbsoluteY() return self.y end
        function E:getYScroll() return 0 end
        function E:setScrollHeight(h) self.scrollH = h end
        function E:getScrollHeight() return self.scrollH or 0 end
        function E:instantiate() self.javaObject = newJO() end
        function E:noBackground() self.background = false end
        function E:isReallyVisible() return true end
        W.ISUIElement = E
        W.ISPanel = E:derive("ISPanel")
        function W.ISPanel:new(x, y, w, h) return E.new(self, x, y, w, h) end
        W.ISToolTipInv = { prerender = noop, render = noop, new = function() return {} end }
        W.ZeD = {}
        local ok, err = run(W, scaleSrc, "Scale.lua")
        if not ok then return nil, err end
        local S, X = W.ZeD.Scale, W.ZeD.Text
        X._fontsSettled, X.fallback = true, false
        S._root = 2.0
        ok, err = run(W, textSrc, "TextScale.lua")
        if not ok then return nil, err end
        -- the theme, as Tokens.lua applyTheme sets it: ZeD.T first, then the five role heights measured through ZeD.TM
        local T = { fontPx = {}, fontFace = {} }
        for i = 1, 5 do T["fontF" .. i] = F[i]; T.fontPx[F[i]] = ROLE_PX[i]; T.fontFace[F[i]] = 64 end
        T.px = function(u) return math.floor(u * 2.0 + 0.5) end
        local c = { r = 0.1, g = 0.1, b = 0.1, a = 1 }
        T.base, T.surf1, T.accentText, T.textSec, T.borderS = c, { r = 0.2, g = 0.2, b = 0.2, a = 1 }, c, c, c
        W.ZeD.T = T
        for i = 1, 5 do T["fontF" .. i .. "H"] = W.ZeD.TM:getFontHeight(T["fontF" .. i]) end
        ok, err = run(W, van[1], "ISRichTextPanel.lua")
        if not ok then return nil, err end
        ok, err = run(W, van[2], "ISToolTip.lua")
        if not ok then return nil, err end
        W.ZeD.Safe = { on = function() return false end }
        W.ZeD.Atoms = { drawHardShadow = noop, frame = noop }
        W.ZeD.currentBase = "dark"
        W.ZeD.logOnce = noop
        local boot
        W.Events = { OnGameBoot = { Add = function(fn) boot = fn end } }
        ok, err = run(W, tipSrc, "Tooltip.lua")
        W.Events = nil
        if not ok then return nil, err end
        if not boot then return nil, "Tooltip.lua registered nothing on OnGameBoot" end
        ok, err = pcall(boot)
        if not ok then return nil, err end
        -- one tooltip at an option: its size and the title's and description's zooms
        local function tip(option)
            W.tipOption = option
            local t = W.ISToolTip:new()
            t:initialise(); t:instantiate()
            t:setName(TITLE)
            t:setDescription(DESC)
            for k in pairs(draws) do draws[k] = nil end
            t:doLayout()
            t:prerender()
            t:render()
            local tz, dz
            for _, d in ipairs(draws) do
                if d.str == TITLE then tz = d.z elseif d.font == F[2] then dz = d.z end
            end
            return { w = t.width, h = t.height, tz = tz, dz = dz }
        end
        -- the body role as the rest of the UI sees it
        local function body()
            return { z = X.zoomOf(F[2]), h = W.ZeD.TM:getFontHeight(F[2]), w = W.ZeD.TM:MeasureStringX(F[2], TITLE) }
        end
        local function emptyKept() X._zoom.T = false; X._measureCache.T = false end
        return { tip = tip, body = body, emptyKept = emptyKept }
    end

    local function probe(scaleSrc, textSrc, tipSrc)
        if not (van[1] and van[2]) then return nil, "no game files" end
        local w, err = tooltipWorld(scaleSrc, textSrc, tipSrc)
        if not w then return nil, err end
        local res = {}
        local ok, perr = pcall(function()
            res.base = w.body()
            res.small, res.medium, res.large = w.tip("Small"), w.tip("Medium"), w.tip("Large")
            res.after = w.body()
            w.emptyKept()                         -- (as after a resolution change, before the theme is applied again)
            res.cold = w.tip("Large")
            res.afterCold = w.body()
        end)
        if not ok then return nil, perr end
        return res
    end
    local function near(a, b) return a ~= nil and b ~= nil and math.abs(a - b) < 1e-6 end
    local function sameBody(a, b) return a and b and near(a.z, b.z) and near(a.h, b.h) and near(a.w, b.w) end
    local function bodyText(b) return b and string.format("zoom %.4f, height %.2f, title %.2f", b.z, b.h, b.w) or "nil" end
    local r, err = probe(scaleNow, textNow, tipNow)
    check("TOOLTIP the tooltip runs on the stubs", r ~= nil, err)
    if r then
        local z0 = 13 * 2.0 / 64
        note(string.format("Small %dx%d, Medium %dx%d, Large %dx%d; title zoom %.4f / %.4f / %.4f",
            r.small.w, r.small.h, r.medium.w, r.medium.h, r.large.w, r.large.h, r.small.tz or -1, r.medium.tz or -1, r.large.tz or -1))
        check("TOOLTIP the body role starts at its own zoom", near(r.base.z, z0), r.base.z)
        check("TOOLTIP Small draws the title at the body role's own zoom", near(r.small.tz, z0), r.small.tz)
        check("TOOLTIP Medium draws the title at 1.15 times", near(r.medium.tz, z0 * 1.15), r.medium.tz)
        check("TOOLTIP Large draws the title at 1.3 times", near(r.large.tz, z0 * 1.3), r.large.tz)
        check("TOOLTIP Large draws the description at 1.3 times", near(r.large.dz, z0 * 1.3), r.large.dz)
        check("TOOLTIP Medium is wider and taller than Small", r.medium.w > r.small.w and r.medium.h > r.small.h,
            r.small.w .. "x" .. r.small.h .. " / " .. r.medium.w .. "x" .. r.medium.h)
        check("TOOLTIP Large is wider and taller than Medium", r.large.w > r.medium.w and r.large.h > r.medium.h,
            r.medium.w .. "x" .. r.medium.h .. " / " .. r.large.w .. "x" .. r.large.h)
        check("TOOLTIP after the tooltips the body text is its own size again", sameBody(r.after, r.base), bodyText(r.after))
        check("TOOLTIP with the kept zooms and measures empty, Large is the same tooltip", r.cold.w == r.large.w and r.cold.h == r.large.h
            and near(r.cold.tz, r.large.tz), r.cold.w .. "x" .. r.cold.h)
        check("TOOLTIP with them empty, the bigger size stays off the body text", sameBody(r.afterCold, r.base), bodyText(r.afterCold))
    end
    local ro = (scaleOld and textOld and tipOld) and probe(scaleOld, textOld, tipOld) or nil
    if (scaleOld and textOld and tipOld) and not ro then note("the code before did not run on the stubs") end
    control("TOOLTIP Medium is wider and taller than Small", ro and ro.medium.w > ro.small.w and ro.medium.h > ro.small.h,
        ro and (ro.small.w .. "x" .. ro.small.h .. " / " .. ro.medium.w .. "x" .. ro.medium.h))
    control("TOOLTIP with them empty, the bigger size stays off the body text", ro and sameBody(ro.afterCold, ro.base),
        ro and bodyText(ro.afterCold))
end

-- ===========================================================================
-- HANDS: Overrides/Belt.lua over the game's own hover test (ISEquippedItem checkToolTip and checkBounds)
-- ===========================================================================
section("HANDS")
do
    local now, old = both("42/media/lua/client/ZeD/Overrides/Belt.lua")
    local van = readFile(PZ .. "client/ISUI/ISEquippedItem.lua")
    check("HANDS Overrides/Belt.lua and the game's ISEquippedItem.lua read", now ~= nil and van ~= nil)
    local vanTip = cut(van, "function ISEquippedItem:checkToolTip()", "\nend")
    local vanBounds = cut(van, "function ISEquippedItem:checkBounds(", "\nend")
    check("HANDS the game's hover test is found", vanTip ~= nil and vanBounds ~= nil)
    local function probe(src)
        if not (vanTip and vanBounds) then return nil, "no hover test" end
        local hooks = {}
        local noop = function() end
        local mouse = { x = 0, y = 0 }
        local item1, item2 = { name = "hammer" }, { name = "torch" }
        local EQ = {}
        EQ.__index = EQ
        function EQ:render() end
        function EQ:prerender() end
        function EQ:addChild() end
        local W = world({
            ZeD = { Safe = { on = function() return false end, register = function(name, def) hooks[name] = def end, _originals = {} },
                    Belt = {} },
            Events = { OnGameBoot = { Add = noop }, OnGameStart = { Add = noop }, OnTick = { Add = noop, Remove = noop } },
            getCore = function() return { getGameMode = function() return "Sandbox" end, getDebug = function() return false end } end,
            isClient = function() return false end,
            getPlayerHotbar = function() return nil end,
            getNumActivePlayers = function() return 1 end,
            getMouseX = function() return mouse.x end,
            getMouseY = function() return mouse.y end,
            getSpecificPlayer = function()
                return { getPrimaryHandItem = function() return item1 end, getSecondaryHandItem = function() return item2 end }
            end,
            getPlayerContextMenu = function() return { isAnyVisible = function() return false end } end,
            ISEquippedItem = EQ,
            activateCounter = 0, activateTicks = 10, lastId = 0,   -- (file locals of the game's ISEquippedItem.lua)
        })
        local ok, err = run(W, vanTip .. vanBounds, "ISEquippedItem hover")
        if not ok then return nil, err end
        ok, err = run(W, src, "Overrides/Belt.lua")
        if not ok then return nil, err end
        -- the column as the game builds it: the hands filed as stand-in rects (createFakeObject), then the buttons
        local function panel(x, y, w, h)
            local o = { x = x, y = y, width = w, height = h, javaObject = {}, visible = true }
            function o:getX() return self.x end
            function o:getY() return self.y end
            function o:getWidth() return self.width end
            function o:getHeight() return self.height end
            function o:getIsVisible() return self.visible end
            function o:setVisible(v) self.visible = v end
            return o
        end
        local function createFakeObject(_x, _y, _w, _h)
            local self = {}
            self.x = _x; self.y = _y; self.w = _w; self.h = _h
            function self:getX() return self.x end
            function self:getY() return self.y end
            function self:getWidth() return self.w end
            function self:getHeight() return self.h end
            return self
        end
        local p = setmetatable({}, EQ)
        p.mainHand, p.offHand, p.invBtn = panel(0, 0, 48, 48), panel(0, 58, 48, 48), panel(0, 116, 48, 48)
        p.mouseOverList = {
            { object = createFakeObject(0, 0, 48, 48), displayString = "IGUI_PrimaryTooltip" },
            { object = createFakeObject(0, 58, 48, 48), displayString = "IGUI_SecondaryTooltip" },
            { object = p.invBtn, displayString = "IGUI_InventoryTooltip" },
        }
        local vanillaList = p.mouseOverList
        local firstEntry = vanillaList[1]
        p.chr = { getBodyDamage = function() return { getHealth = function() return 100 end } end }
        p.previousHealth, p.healthIconOscillatorLevel, p.playerNum = 100, 0, 0
        p.toolRender = { setVisible = noop }
        p.isMouseOver = function() return true end
        p.renderFPS = noop
        p.setVisible = function(self, v) self.visible = v end
        p.doToolTip = function(self, state, text) self._label = text end
        p.doInvToolTip = function(self, item) self._itemBox = item end
        W.getPlayerData = function() return { equipped = p } end
        local function hover(x, y)
            mouse.x, mouse.y = x, y
            p._label, p._itemBox = nil, nil
            p:checkToolTip()
            return p._itemBox, p._label
        end
        local res = {}
        local ok2, err2 = pcall(function()
            p:render()                                             -- ZeD's: the hands hide, their zones go
            res.mainBox = hover(24, 24)
            res.offBox = hover(24, 82)
            local _, label = hover(24, 140)
            res.invLabel = label
            res.n, res.third = #p.mouseOverList, p.mouseOverList[3] and p.mouseOverList[3].object == p.invBtn
            res.keptAll = p._zedOverAll == vanillaList and vanillaList[1] == firstEntry and firstEntry.object.w == 48
            hooks.belt.leave()                                     -- safe mode: vanilla's list, hands and all
            res.safeBox = hover(24, 24)
            p:render()                                             -- ZeD's again
            res.againBox = hover(24, 24)
        end)
        if not ok2 then return nil, err2 end
        return res
    end
    local r, err = probe(now)
    check("HANDS the belt's column runs on the stubs", r ~= nil, err)
    if r then
        check("HANDS no item box over the hidden main hand", r.mainBox == nil, r.mainBox and r.mainBox.name)
        check("HANDS no item box over the hidden off hand", r.offBox == nil, r.offBox and r.offBox.name)
        check("HANDS the inventory button keeps its label", r.invLabel == "IGUI_InventoryTooltip", r.invLabel)
        check("HANDS the buttons keep their places (third: the inventory button)", r.n == 3 and r.third, r.n)
        check("HANDS vanilla's list is kept as it was, for safe mode", r.keptAll)
        check("HANDS safe mode puts back vanilla's hover over the hands", r.safeBox and r.safeBox.name == "hammer")
        check("HANDS taking over again takes the zones again", r.againBox == nil, r.againBox and r.againBox.name)
    end
    local ro = old and probe(old)
    control("HANDS no item box over the hidden main hand", ro and ro.mainBox == nil, ro and ro.mainBox and ro.mainBox.name)
end

-- ===========================================================================
-- CHORD: Input/BumperChord.lua, against the game's zoom steps and ZeD's controller map
-- ===========================================================================
section("CHORD")
do
    local now, old = both("42/media/lua/client/ZeD/Input/BumperChord.lua")
    check("CHORD BumperChord.lua reads", now ~= nil)
    local wheel = readFile(PZ .. "client/ISUI/ISBackButtonWheel.lua")
    check("CHORD the game's ZoomOut slice sends ZoomPlus, which is doZoomScroll +1", wheel
        and wheel:find('getTexture("media/ui/ZoomOut.png"), self.onCommand, self, "ZoomPlus")', 1, true)
        and wheel:find('command == "ZoomPlus"[^\n]*\n%s*getCore%(%):doZoomScroll%(self%.playerNum, 1%)'))
    check("CHORD the game's ZoomIn slice sends ZoomMinus, which is doZoomScroll -1", wheel
        and wheel:find('getTexture("media/ui/ZoomIn.png"), self.onCommand, self, "ZoomMinus")', 1, true)
        and wheel:find('command == "ZoomMinus"[^\n]*\n%s*getCore%(%):doZoomScroll%(self%.playerNum, %-1%)'))
    local ui = readFile(ROOT .. "42/media/lua/shared/Translate/EN/UI.json") or ""
    check("CHORD the controller map says LB + RB zooms out and RB + LB zooms in",
        ui:find('"UI_ZeD_CMap_LB": "[^"]*LB %+ RB zooms out') and ui:find('"UI_ZeD_CMap_RB": "[^"]*RB %+ LB zooms in'))
    local function probe(src)
        local onTick
        local zooms, said = {}, {}
        local LB, RB = false, false
        local W = world({
            Events = { OnTick = { Add = function(fn) onTick = fn end }, ZeD_InputModeChanged = { Add = function() end } },
            LuaEventManager = { AddEvent = function() end },
            ZeD = { Input = { Detector = { getMode = function() return "gamepad" end } } },
            getJoypadData = function() return { id = 3 } end,
            JoypadButton = { LeftBump = { isDown = function() return LB end }, RightBump = { isDown = function() return RB end } },
            getCore = function() return { doZoomScroll = function(_, p, d) zooms[#zooms + 1] = d end } end,
            print = function(s) said[#said + 1] = tostring(s) end,
        })
        local ok, err = run(W, src, "BumperChord.lua")
        if not ok then return nil, err end
        if not onTick then return nil, "no tick handler" end
        local function tick(lb, rb) LB, RB = lb, rb; onTick() end
        tick(true, false); tick(true, true)       -- hold LB, tap RB
        tick(true, false); tick(true, true)       -- a second tap while LB stays down
        tick(false, false)
        tick(false, true); tick(true, true)       -- hold RB, tap LB
        tick(false, false)
        tick(true, true)                          -- both on one tick (LB counts first)
        tick(false, false)
        local first
        for _, s in ipairs(said) do if not first and s:find("chord fire: ", 1, true) then first = s end end
        return { lbrb = zooms[1], lbrb2 = zooms[2], rblb = zooms[3], both = zooms[4], n = #zooms, said = first }
    end
    local r, err = probe(now)
    check("CHORD the chord runs on the stubs", r ~= nil, err)
    if r then
        check("CHORD hold LB + tap RB sends +1 (zoom out)", r.lbrb == 1, r.lbrb)
        check("CHORD a second tap with LB held zooms out again", r.lbrb2 == 1, r.lbrb2)
        check("CHORD hold RB + tap LB sends -1 (zoom in)", r.rblb == -1, r.rblb)
        check("CHORD both on one tick zooms out (LB first)", r.both == 1, r.both)
        check("CHORD four steps, no more", r.n == 4, r.n)
        check("CHORD the console line names a zoom-out", r.said == "[ZeD.Input] chord fire: zoom-out", r.said)
    end
    local ro = old and probe(old)
    control("CHORD hold LB + tap RB sends +1 (zoom out)", ro and ro.lbrb == 1, ro and ro.lbrb)
    control("CHORD hold RB + tap LB sends -1 (zoom in)", ro and ro.rblb == -1, ro and ro.rblb)
end

-- ===========================================================================
-- ICONS: SafeMode.lua and Overrides/ScreenIcons.lua with only the belt handed back
-- ===========================================================================
section("ICONS")
do
    local safeNow, safeOld = both("42/media/lua/client/ZeD/SafeMode.lua")
    local iconNow, iconOld = both("42/media/lua/client/ZeD/Overrides/ScreenIcons.lua")
    check("ICONS SafeMode.lua and Overrides/ScreenIcons.lua read", safeNow ~= nil and iconNow ~= nil)
    local HIDE = { "invBtn", "healthBtn", "craftingBtn", "buildBtn", "movableBtn", "searchBtn", "zoneBtn", "mapBtn" }
    local function probe(safeSrc, iconSrc)
        local BELT = 1   -- the belt's ZeD setup switch: 1 ZeD's, 2 handed back to the game
        local EQ = {}
        EQ.__index = EQ
        function EQ:prerender() end
        local p = setmetatable({}, EQ)
        local W = world({
            getTimestampMs = function() return 100000 end,
            ZeD = { tr = function(k) return k end,
                    Settings = { safeModeOption = { getValue = function() return 1 end },
                                 screenOptions = { belt = { getValue = function() return BELT end } } } },
            getCore = function() return { getGameMode = function() return "Sandbox" end } end,
            getNumActivePlayers = function() return 1 end,
            getPlayerData = function() return { equipped = p } end,
            ISEquippedItem = EQ,
        })
        local ok, err = run(W, safeSrc, "SafeMode.lua")
        if not ok then return nil, err end
        ok, err = run(W, iconSrc, "ScreenIcons.lua")
        if not ok then return nil, err end
        for _, k in ipairs(HIDE) do
            local b = { visible = true }
            function b:getIsVisible() return self.visible end
            function b:setVisible(v) self.visible = v end
            p[k] = b
        end
        local list = { { object = {}, displayString = "hand 1" }, { object = {}, displayString = "hand 2" } }
        for i = 1, 7 do list[#list + 1] = { object = p[HIDE[i]], displayString = HIDE[i] } end   -- (the map button has none)
        p.mouseOverList = list
        local function shown() local n = 0; for _, k in ipairs(HIDE) do if p[k].visible then n = n + 1 end end; return n end
        local res = {}
        local ok2, err2 = pcall(function()
            p:prerender()
            res.hidden, res.listHidden = shown(), #p.mouseOverList
            BELT = 2; W.ZeD.Safe.reread()                      -- only the belt handed back
            res.back, res.listBack, res.flag = shown(), #p.mouseOverList, p._zedIconsHidden
            p:prerender()
            res.backFrame = shown()
            BELT = 1; W.ZeD.Safe.reread()                      -- the belt ZeD's again
            p:prerender()
            res.again, res.listAgain = shown(), #p.mouseOverList
        end)
        if not ok2 then return nil, err2 end
        return res
    end
    local r, err = probe(safeNow, iconNow)
    check("ICONS the column runs on the stubs", r ~= nil, err)
    if r then
        check("ICONS ZeD's belt: the eight window buttons hide, their labels with them", r.hidden == 0 and r.listHidden == 2,
            r.hidden .. " shown, " .. r.listHidden .. " labels")
        check("ICONS the belt handed back: all eight come back", r.back == 8, r.back)
        check("ICONS the belt handed back: vanilla's whole hover list is back", r.listBack == 9, r.listBack)
        check("ICONS the belt handed back: the next frame leaves them up", r.backFrame == 8, r.backFrame)
        check("ICONS the belt ZeD's again: hidden again, labels gone", r.again == 0 and r.listAgain == 2,
            r.again .. " shown, " .. r.listAgain .. " labels")
    end
    local ro = (safeOld and iconOld) and probe(safeOld, iconOld) or nil
    control("ICONS the belt handed back: all eight come back", ro and ro.back == 8, ro and ro.back)
end

-- ===========================================================================
-- INSPECT: Overrides/Garment.lua over the real mark wipe (InventoryRenderer.lua) and the Character window's rule
-- ===========================================================================
section("INSPECT")
do
    local now, old = both("42/media/lua/client/ZeD/Overrides/Garment.lua")
    local ir = readFile(ROOT .. "42/media/lua/client/ZeD/InventoryRenderer.lua")
    local cw = readFile(ROOT .. "42/media/lua/client/ZeD/ZeD_CharacterWindow.lua") or ""
    local irCode = cut(ir, "local function wipeMarks(cnt)", "\n    if not quiet then padRefresh(w, cnt) end\nend")
    check("INSPECT Garment.lua reads and the mark wipe is found", now ~= nil and irCode ~= nil)
    -- the drawer's rule below is the Character window's own (updateDrawer): the card shows for one item, not for marks
    check("INSPECT the Character window's card rule is the one the stand-in follows",
        cw:find("if count == 0 then contentPanel._padMarks = nil end", 1, true)
        and cw:find("if count == 1 and not contentPanel._padMarks then", 1, true))
    local function probe(src)
        local vanilla = {}
        local win = { _itemCard = {} }
        local cnt = { _selectedItems = {}, _colStates = {} }
        win._mainContent = cnt
        win._updateDrawer = function(c)
            local count, single = 0, nil
            for it in pairs(c._selectedItems) do count = count + 1; single = it; if count > 1 then break end end
            if count == 0 then c._padMarks = nil end
            if count == 1 and not c._padMarks then win._drawerItem = single else win._drawerItem = nil end
        end
        local W = world({
            ZeD = { Safe = { on = function() return false end }, windowsFor = function() return true end, InventoryRenderer = {} },
            ISInventoryPaneContextMenu = { onInspectClothingUI = function(p, c) vanilla[#vanilla + 1] = c end },
            ISGarmentUI = {},
            JoypadState = { players = {} },
            ZeD_CharacterWindow = { getWindow = function() return win end, isOpen = function() return true end, toggle = function() end },
            padRefresh = function() end,
        })
        local ok, err = run(W, irCode, "InventoryRenderer marks")
        if not ok then return nil, err end
        ok, err = run(W, src, "Garment.lua")
        if not ok then return nil, err end
        local player = { getPlayerNum = function() return 0 end }
        local shirt, pants, bag = { n = "shirt" }, { n = "pants" }, { n = "bag" }
        local res = {}
        local inspect = W.ISInventoryPaneContextMenu.onInspectClothingUI
        -- held A on the shirt: one controller mark, then X's menu and Inspect
        cnt._selectedItems, cnt._padMarks = { [shirt] = true }, true
        inspect(player, shirt)
        res.oneVanilla, res.oneCard, res.oneMarks = #vanilla, win._drawerItem == shirt, cnt._padMarks
        -- the shirt and the pants marked, a bag marked in an extra column
        vanilla[1] = nil
        cnt._selectedItems, cnt._padMarks = { [shirt] = true, [pants] = true }, true
        cnt._colStates = { { selectedItems = { [bag] = true } } }
        inspect(player, shirt)
        res.twoVanilla, res.twoCard = #vanilla, win._drawerItem == shirt
        res.twoPants, res.twoBag = cnt._selectedItems[pants], cnt._colStates[1].selectedItems[bag]
        -- no controller marks: the pants picked with the mouse, Inspect on the shirt
        vanilla[1] = nil
        cnt._selectedItems, cnt._padMarks, cnt._colStates = { [pants] = true }, nil, {}
        inspect(player, shirt)
        res.mouseVanilla, res.mouseCard = #vanilla, win._drawerItem == shirt
        return res
    end
    local r, err = probe(now)
    check("INSPECT Inspect runs on the stubs", r ~= nil, err)
    if r then
        check("INSPECT one controller mark: ZeD's card opens, not vanilla's window", r.oneVanilla == 0 and r.oneCard,
            r.oneVanilla .. " vanilla")
        check("INSPECT one controller mark: the marks' rule goes with them", r.oneMarks == nil)
        check("INSPECT two marks and an extra column's: the card opens on the garment", r.twoVanilla == 0 and r.twoCard)
        check("INSPECT the other marks are gone, the extra column's too", r.twoPants == nil and r.twoBag == nil)
        check("INSPECT no marks: the card opens as before", r.mouseVanilla == 0 and r.mouseCard)
    end
    local ro = old and probe(old)
    control("INSPECT one controller mark: ZeD's card opens, not vanilla's window", ro and ro.oneVanilla == 0 and ro.oneCard,
        ro and (ro.oneVanilla .. " vanilla"))
end

-- ===========================================================================
-- PRESS: ZeDUI/tools/qa/zedqa_container_controls.lua pressLabel, against ContainerControls.lua's band
-- ===========================================================================
section("PRESS")
do
    local now, old = both("ZeDUI/tools/qa/zedqa_container_controls.lua")
    local ct = readFile(ROOT .. "42/media/lua/client/ZeD/ContainerControls.lua") or ""
    check("PRESS the QA script reads", now ~= nil)
    -- the band as ContainerControls.lua lays it out: a hit per button, its spec beside it, its own label the hover hint
    check("PRESS the band's hits carry the button's spec and its hint as their label",
        ct:find("cc.hits[#cc.hits + 1] = { key = r.key, label = (s and s.hint) or r.label, spec = s,", 1, true))
    check("PRESS CT.press takes a hit's index", ct:find("local h = cc.hits and cc.hits[idx]", 1, true))
    local function probe(src)
        local code = cut(src, "local function pressLabel(content, label)", "\nend")
        if not code then return nil, "pressLabel not found" end
        local pressed, said = {}, {}
        local W = world({ CT = { press = function(content, i) pressed[#pressed + 1] = i end },
                          say = function(s) said[#said + 1] = tostring(s) end })
        local ok, pressLabel = run(W, code .. "\nreturn pressLabel\n", "pressLabel")
        if not ok then return nil, pressLabel end
        local content = { _cc = {
            hits = {
                { key = "same", label = "Take the kinds you already carry", spec = { id = "same", label = "Same type" } },
                { key = "take", label = "Take all", spec = { id = "take", label = "Take all" } },
                { key = "floor", label = "To floor", spec = { id = "floor", label = "To floor" } },
            },
            bottom = { rects = { { key = "same", label = "Same type" }, { key = "take", label = "Take all" }, { key = "floor", label = "To floor" } } },
        } }
        local res = {}
        res.same, res.samePressed, res.sameSaid = pressLabel(content, "Same type"), pressed[1], said[1]
        res.floor, res.floorPressed = pressLabel(content, "To floor"), pressed[2]
        res.miss = pressLabel(content, "Light")
        res.missSaid = said[#said]
        return res
    end
    local r, err = probe(now)
    check("PRESS pressLabel runs", r ~= nil, err)
    if r then
        check("PRESS \"Same type\" presses the first button (its hit's own label is the hint)", r.same == true and r.samePressed == 1, r.samePressed)
        check("PRESS \"To floor\" presses the third", r.floor == true and r.floorPressed == 3, r.floorPressed)
        check("PRESS a button that is not there says ERR, so the run counts it", r.miss == false and r.missSaid and r.missSaid:find("ERR", 1, true),
            r.missSaid)
    end
    local ro = old and probe(old)
    control("PRESS \"Same type\" presses the first button", ro and ro.same == true and ro.samePressed == 1, ro and ro.sameSaid)
end

-- ===========================================================================
-- CAROUSEL: ZeD_ContextMenu.lua's strip after a fast run of steps left (the wheel spun up, a key held)
-- ===========================================================================
section("CAROUSEL")
do
    local now, old = both("42/media/lua/client/ZeD/ZeD_ContextMenu.lua")
    check("CAROUSEL ZeD_ContextMenu.lua reads", now ~= nil)
    local FNS = { "function ZeD_ContextMenu:next()", "function ZeD_ContextMenu:prev()", "function ZeD_ContextMenu:_anchorSlot(visibleCount)",
                  "function ZeD_ContextMenu:page(dir)", "function ZeD_ContextMenu:_scheduleSettle()", "function ZeD_ContextMenu:_settleCarousel()" }
    local function probe(src)
        local parts = {}
        for _, f in ipairs(FNS) do
            local c = cut(src, f, "\nend")
            if not c then return nil, f .. " not found" end
            parts[#parts + 1] = c
        end
        local W = world({ ZeD_ContextMenu = {}, ZeD = { T = { ctx = { maxVisible = 7, cellW = 40, gap = 2, animMs = 180 } } },
                          getTimestampMs = function() return 0 end })
        local ok, err = run(W, table.concat(parts, "\n"), "ZeD_ContextMenu strip")
        if not ok then return nil, err end
        local function menu(N, sel)
            local items = {}
            for i = 1, N do items[i] = { id = i } end
            return setmetatable({ _ctx = { items = items, selected = sel, pos = N + sel, truncating = true, path = {} } },
                { __index = W.ZeD_ContextMenu })
        end
        local res = {}
        local m = menu(10, 1)
        for _ = 1, 12 do m:prev() end                       -- twelve steps left before the settle: pos -1
        res.spinPos0 = m._ctx.pos
        m:_settleCarousel()
        res.spinPos, res.spinSel = m._ctx.pos, m._ctx.selected
        m = menu(10, 1)
        for _ = 1, 19 do m:prev() end                       -- nineteen, then the left page arrow
        m:page(-1)
        res.pageSel = m._ctx.selected
        m:_settleCarousel()
        res.pagePos = m._ctx.pos
        return res
    end
    local function at(pos) return (pos - 1) - math.floor((pos - 1) / 10) * 10 + 1 end   -- (the option a track place shows)
    local r, err = probe(now)
    check("CAROUSEL the strip runs", r ~= nil, err)
    if r then
        check("CAROUSEL the spin took pos below 1 (the case itself)", r.spinPos0 == -1, r.spinPos0)
        check("CAROUSEL the settle lands in the middle copy", r.spinPos >= 11 and r.spinPos <= 20, r.spinPos)
        check("CAROUSEL on the option the steps chose", at(r.spinPos) == r.spinSel and r.spinSel == 9, r.spinPos .. " / " .. r.spinSel)
        check("CAROUSEL a page left from there picks a real option (5)", r.pageSel == 5, r.pageSel)
        check("CAROUSEL and settles on it in the middle copy", r.pagePos >= 11 and r.pagePos <= 20 and at(r.pagePos) == 5, r.pagePos)
    end
    local ro = old and probe(old)
    control("CAROUSEL the settle lands in the middle copy", ro and ro.spinPos >= 11 and ro.spinPos <= 20, ro and ro.spinPos)
    control("CAROUSEL a page left from there picks a real option (5)", ro and ro.pageSel == 5, ro and ro.pageSel)
end

-- ===========================================================================
-- STEPS: ZeD_MainMenuOptions.lua nextOn, wrapping down
-- ===========================================================================
section("STEPS")
do
    local now, old = both("42/media/lua/client/ZeD/ZeD_MainMenuOptions.lua")
    check("STEPS ZeD_MainMenuOptions.lua reads", now ~= nil)
    local function probe(src)
        local code = cut(src, "local function stepOff(c, i)", "\n    return nil\nend")
        if not code then return nil, "nextOn not found" end
        local W = world({ ZeD = {} })
        local ok, nextOn = run(W, code .. "\nreturn nextOn\n", "nextOn")
        if not ok then return nil, nextOn end
        local c = { options = { "a", "b", "c", "d" } }
        local res = { down1 = nextOn(c, 1, -1, true), up4 = nextOn(c, 4, 1, true), up0 = nextOn(c, 0, 1, true),
                      flat = nextOn(c, 1, -1, false) }
        W.ZeD.Settings = { scaleStepOff = function(_, i) return i == 4 end }
        res.downOff = nextOn(c, 1, -1, true)
        return res
    end
    local r, err = probe(now)
    check("STEPS nextOn runs", r ~= nil, err)
    if r then
        check("STEPS down from the first step wraps to the last", r.down1 == 4, r.down1)
        check("STEPS up from the last wraps to the first", r.up4 == 1, r.up4)
        check("STEPS up from none picks the first", r.up0 == 1, r.up0)
        check("STEPS without wrap, down from the first is none", r.flat == nil, r.flat)
        check("STEPS down from the first skips a step that is off", r.downOff == 3, r.downOff)
    end
    local ro = old and probe(old)
    control("STEPS down from the first step wraps to the last", ro and ro.down1 == 4, ro and ro.down1)
end

-- ===========================================================================
-- the rewrite leaves a file with no % operator as it is (its strings and comments full of % patterns)
-- ===========================================================================
section("KAHLUA files")
do
    for _, rel in ipairs({ "42/media/lua/shared/ZeD/Scale.lua", "42/media/lua/client/ZeD/Overrides/TextScale.lua",
                           "42/media/lua/client/ZeD/Overrides/Tooltip.lua", "42/media/lua/client/ZeD/Overrides/Belt.lua",
                           "42/media/lua/client/ZeD/Input/BumperChord.lua", "42/media/lua/client/ZeD/SafeMode.lua",
                           "42/media/lua/client/ZeD/Overrides/ScreenIcons.lua", "42/media/lua/client/ZeD/Overrides/Garment.lua" }) do
        local src = readFile(ROOT .. rel)
        check("KAHLUA " .. rel .. " has no % operator and comes through as it is", src ~= nil and kahluaPct(src) == src)
    end
end

print(string.format("coverage_bugs_sim: %d checks, %d failed", checks, failed))
os.exit(failed > 0 and 1 or 0)
