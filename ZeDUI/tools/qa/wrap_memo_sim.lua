-- ZeDUI/tools/qa/wrap_memo_sim.lua  (Nov 7 2026, the outside performance review, items 8 and 15): the kept answers
-- of ZeD.Atoms.wrapText and ZeD.Atoms.truncateText against the code they replaced, with no game running.
-- The real shared/ZeD/Scale.lua (ZeD.TM, its measure store and ZeD.Text.measureEpoch) and the real client/ZeD/Atoms.lua
-- run on a stand-in for the engine's TextManager whose widths do not add up: every letter its own width, kerning pairs
-- (some negative), a whole string with CJK or Thai letters measured wider (as ZeD.Text.scriptFont swaps the face), the
-- engine's whole-number answer, then the role font's fractional zoom. Old and new are asked the same things in the same
-- order: every string of every language's UI.json (a sample of each), made-up edge cases (empty, spaces only, blank
-- paragraphs, no spaces, one very long word, tabs, CJK and Thai runs with no spaces), five role fonts and a game font,
-- whole, fractional, tiny, negative and endless widths, widths sliding by fractions (a drawer opening) up and down, the
-- same width asked twice, and a root-scale change part way. Every answer must be identical, line for line and byte for
-- byte. Then a frame loop counts the engine measures, the measure store's turnovers and the kept answers' hits, old
-- against new.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/wrap_memo_sim.lua
-- It prints FAIL lines, the counts, and a last line "wrap_memo_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]wrap_memo_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        if failed <= 40 then print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
    end
end

-- the engine's TextManager, a stand-in -----------------------------------------------------
local REAL = { calls = 0 }
local function kern(a, b)
    if not a then return 0 end
    local k = (a * 31 + b * 17) % 23
    if k == 0 then return -3 elseif k == 1 then return -1 elseif k == 2 then return 2 end
    return 0
end
local realTM = {
    MeasureStringX = function(_, font, s)
        REAL.calls = REAL.calls + 1
        s = tostring(s)
        local w, prev, wide = 0, nil, false
        for i = 1, #s do
            local b = string.byte(s, i)
            if b >= 0xE0 then wide = true end
            -- (UTF-8 continuation bytes are part of their letter: a letter is drawn once)
            if b < 0x80 or b >= 0xC0 then
                w = w + 3 + (b * 7) % 10 + kern(prev, b)
                prev = b
            end
        end
        if wide then w = w * 1.3 + 2 end
        return math.floor(w * (font and font.k or 1))
    end,
    MeasureStringY = function(_, font) return math.floor(16 * (font and font.k or 1)) end,
    getFontHeight = function(_, font) return math.floor(16 * (font and font.k or 1)) end,
    getFontFromEnum = function() return nil end,
}
getTextManager = function() return realTM end
getCore = function() return { getOptionFontSize = function() return 2 end } end
isServer = function() return false end
Events = nil

function require() end
ISPanel = { derive = function(self, name) local o = { Type = name }; setmetatable(o, { __index = self }); return o end }

ZeD = {}
assert(loadfile(ROOT .. "42/media/lua/shared/ZeD/Scale.lua"))()
local S, X = ZeD.Scale, ZeD.Text
X._fontsSettled, X.fallback = true, false
S._root = 1.0

local F1, F2, F3, F4, F5 = { name = "F1", k = 0.9 }, { name = "F2", k = 1.0 }, { name = "F3", k = 0.95 }, { name = "F4", k = 1.2 }, { name = "F5", k = 0.8 }
local GAME = { name = "Small", k = 1.0 }   -- (a game font: zoom 1)
local FONTS = { F1, F2, F3, F4, F5, GAME }
local function setTokens()
    ZeD.T = { fontPx = { [F1] = 11, [F2] = 13, [F3] = 11, [F4] = 15, [F5] = 9 },
              fontFace = { [F1] = 64, [F2] = 64, [F3] = 64, [F4] = 64, [F5] = 64 } }
end
setTokens()

assert(loadfile(ROOT .. "42/media/lua/client/ZeD/Atoms.lua"))()
local A = ZeD.Atoms
local newWrap, newTrunc = A.wrapText, A.truncateText
check("the real Atoms loads with the kept wraps", type(newWrap) == "function" and type(A._wrapMemo) == "table")

-- the code they replaced (Atoms.lua at 7f17686e, word for word) ------------------------------
local function oldWrap(text, font, maxW)
    local lines = {}
    if not text or text == "" then return lines end

    for paragraph in text:gmatch("[^\n]+") do
        local words = {}
        for word in paragraph:gmatch("%S+") do words[#words + 1] = word end
        local line = ""
        for _, word in ipairs(words) do
            local test = line == "" and word or (line .. " " .. word)
            if ZeD.TM:MeasureStringX(font, test) > maxW then
                if line ~= "" then lines[#lines + 1] = line end
                line = word
            else
                line = test
            end
        end
        if line ~= "" then lines[#lines + 1] = line end
    end

    if #lines == 0 then lines[1] = text end
    return lines
end
local truncateRaw
local TT_MAX = 4000
local _tt, _ttN, _ttEpoch = {}, 0, nil
local function oldTrunc(text, font, maxW)
    if maxW <= 0 then return "" end
    local X = ZeD.Text
    local epoch = X and X.measureEpoch and X.measureEpoch() or nil
    if epoch == nil or font == nil or type(text) ~= "string" then return truncateRaw(text, font, maxW) end
    if epoch ~= _ttEpoch or _ttN >= TT_MAX then _tt, _ttN, _ttEpoch = {}, 0, epoch end
    local byF = _tt[font]
    if not byF then byF = {}; _tt[font] = byF end
    local byW = byF[maxW]
    if not byW then byW = {}; byF[maxW] = byW end
    local s = byW[text]
    if s == nil then
        s = truncateRaw(text, font, maxW)
        byW[text] = s
        _ttN = _ttN + 1
    end
    return s
end
truncateRaw = function(text, font, maxW)
    if maxW <= 0 then return "" end
    local tm = ZeD.TM
    if tm:MeasureStringX(font, text) <= maxW then return text end
    local ellW = tm:MeasureStringX(font, "...")
    if maxW <= ellW then return "..." end
    local target = maxW - ellW
    local lo, hi = 1, #text
    while lo < hi do
        local mid = math.floor((lo + hi + 1) / 2)
        if tm:MeasureStringX(font, string.sub(text, 1, mid)) <= target then
            lo = mid
        else
            hi = mid - 1
        end
    end
    return string.sub(text, 1, lo) .. "..."
end

-- a fixed random stream (the same run every time) -------------------------------------------
local seed = 12345
local function rnd(n)
    seed = (seed * 1103515245 + 12345) % 2147483648
    return math.floor(seed / 65536) % n + 1
end

-- the words: every language's UI.json ------------------------------------------------------------
local function utf8char(c)
    if c < 0x80 then return string.char(c)
    elseif c < 0x800 then return string.char(0xC0 + math.floor(c / 64), 0x80 + c % 64)
    else return string.char(0xE0 + math.floor(c / 4096), 0x80 + math.floor(c / 64) % 64, 0x80 + c % 64) end
end
local function unescape(s)
    s = string.gsub(s, "\\u(%x%x%x%x)", function(h) return utf8char(tonumber(h, 16)) end)
    s = string.gsub(s, "\\(.)", function(c)
        if c == "n" then return "\n" elseif c == "t" then return "\t" elseif c == "r" then return "\r" end
        return c
    end)
    return s
end
local LANGS = { "AR", "CA", "CH", "CN", "CS", "DA", "DE", "EN", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT",
                "JP", "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
local TEXTS, perLang = {}, {}
for _, lang in ipairs(LANGS) do
    local f = io.open(ROOT .. "42/media/lua/shared/Translate/" .. lang .. "/UI.json", "rb")
    local n, kept = 0, 0
    if f then
        local all = f:read("*a")
        f:close()
        for v in string.gmatch(all, '"[%w_]+"%s*:%s*"(.-[^\\])"%s*[,}\r\n]') do
            n = n + 1
            if n % 9 == 0 then TEXTS[#TEXTS + 1] = unescape(v); kept = kept + 1 end
        end
    end
    perLang[#perLang + 1] = lang .. " " .. kept
    check("UI.json read: " .. lang, kept > 50, kept)
end
local nLang = #TEXTS
local LONG = string.rep("Supercalifragilistic", 12)
local CJK = "我们在这里生存下去直到救援到来为止所有的门都要锁好"
local THAI = "ภาษาไทยไม่มีการเว้นวรรคระหว่างคำในประโยคเดียวกัน"
local EDGE = {
    "", " ", "   ", "\n", "\n\n\n", " \n \n ", "a", "ab", "...", "a b", "  leading and trailing  ", "tabs\there\tand\tthere",
    "double  spaces   between    words", "one\nline\nper\nword", "para one has words\n\npara two after a blank",
    LONG, "short " .. LONG .. " short", LONG .. "\n" .. LONG, CJK, THAI, CJK .. " " .. THAI, "Mixed " .. CJK .. " and Latin",
    "x" .. string.rep(" y", 200), string.rep("word ", 300), "trailing newline\n", "\nleading newline",
    "%s%d%% pattern chars (and) [brackets] ^$", "r\r\nwindows\r\nlines",
}
for _, e in ipairs(EDGE) do TEXTS[#TEXTS + 1] = e end
print("wrap_memo_sim: " .. #TEXTS .. " texts (" .. nLang .. " from UI.json: " .. table.concat(perLang, ", ") .. "; " .. #EDGE .. " made up)")

local function same(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    if #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    for k in pairs(b) do if type(k) ~= "number" or k < 1 or k > #b or k ~= math.floor(k) then return false end end
    return true
end
local function show(t) return type(t) == "table" and ("{" .. #t .. ": " .. table.concat(t, " | ") .. "}") or tostring(t) end

local WIDTHS = { 0, 1, 7.5, 20, 33.3, 50, 64.99, 80, 100, 100.25, 100.75, 133.4, 160, 200.5, 240, 260, 333.33, 480, 999,
                 -5, math.huge }
local nW, nT = 0, 0
local function compareAll(label)
    for ti = 1, #TEXTS do
        local text = TEXTS[ti]
        for k = 1, 3 do
            local font = FONTS[rnd(#FONTS)]
            local w = WIDTHS[rnd(#WIDTHS)]
            if rnd(3) == 1 then w = w + rnd(1000) / 997 end
            local o, n = oldWrap(text, font, w), newWrap(text, font, w)
            nW = nW + 1
            check(label .. " wrap " .. ti .. " w " .. w, same(o, n), show(o) .. " vs " .. show(n))
            -- asked again (the kept answer) and at another fraction of the same pixel
            check(label .. " wrap again " .. ti, same(o, newWrap(text, font, w)))
            local w2 = math.floor(w) + (rnd(100) - 1) / 100
            if w2 == w2 and w ~= math.huge then
                nW = nW + 1
                check(label .. " wrap same pixel " .. ti .. " w " .. w2, same(oldWrap(text, font, w2), newWrap(text, font, w2)))
            end
            local tw = w
            if tw > 0 then
                nT = nT + 1
                local a, b = oldTrunc(text, font, tw), newTrunc(text, font, tw)
                check(label .. " cut " .. ti .. " w " .. tw, a == b, tostring(a) .. " vs " .. tostring(b))
                if tw ~= math.huge then
                    local t2 = math.floor(tw) + (rnd(100) - 1) / 100
                    if t2 > 0 then
                        nT = nT + 1
                        check(label .. " cut same pixel " .. ti .. " w " .. t2, oldTrunc(text, font, t2) == newTrunc(text, font, t2))
                    end
                end
            end
        end
    end
end

-- 1. every text, fonts and widths at random, at 1.0, then 1.75, then 0.75 -------------------------------------
compareAll("1.0")
S._root = 1.75; setTokens()
compareAll("1.75")
S._root = 0.75; setTokens()
compareAll("0.75")

-- 2. sliding widths: a drawer opening and closing by fractions, both ways, every text and font ------------------
local slides = 0
for _, font in ipairs({ F2, GAME }) do
    for ti = 1, #TEXTS, 40 do
        local text = TEXTS[ti]
        local w = 40
        while w < 420 do
            slides = slides + 1
            if not same(oldWrap(text, font, w), newWrap(text, font, w)) then check("slide up wrap " .. ti .. " w " .. w, false) end
            if oldTrunc(text, font, w) ~= newTrunc(text, font, w) then check("slide up cut " .. ti .. " w " .. w, false) end
            w = w + 1.37
        end
        while w > 30 do
            slides = slides + 1
            if not same(oldWrap(text, font, w), newWrap(text, font, w)) then check("slide down wrap " .. ti .. " w " .. w, false) end
            if oldTrunc(text, font, w) ~= newTrunc(text, font, w) then check("slide down cut " .. ti .. " w " .. w, false) end
            w = w - 1.61
        end
    end
end
check("the slides ran", slides > 10000, slides)
-- (the edge cases slide too, finer)
for _, e in ipairs(EDGE) do
    for _, font in ipairs({ F1, F4 }) do
        local w = 0.5
        while w < 300 do
            slides = slides + 1
            if not same(oldWrap(e, font, w), newWrap(e, font, w)) then check("edge slide wrap " .. e .. " w " .. w, false) end
            if oldTrunc(e, font, w) ~= newTrunc(e, font, w) then check("edge slide cut " .. e .. " w " .. w, false) end
            w = w + 0.29
        end
    end
end

-- 3. the same pixel, every fraction, both orders (the kept answer must not cross a measure inside the pixel) ----
local crossings = 0
for ti = 1, #TEXTS, 25 do
    local text = TEXTS[ti]
    for _, font in ipairs({ F2, F4 }) do
        local base = 30 + rnd(300)
        for _, order in ipairs({ { 0.99, 0.01 }, { 0.01, 0.99 } }) do
            for step = 0, 98 do
                local f = order[1] + (order[2] - order[1]) * step / 98
                local w = base + f
                local o, n = oldWrap(text, font, w), newWrap(text, font, w)
                if not same(o, n) then check("pixel wrap " .. ti .. " w " .. w, false, show(o) .. " vs " .. show(n)) end
                local a, b = oldTrunc(text, font, w), newTrunc(text, font, w)
                if a ~= b then check("pixel cut " .. ti .. " w " .. w, false, a .. " vs " .. b) end
                crossings = crossings + 1
            end
        end
    end
end
-- (a pixel with a measure inside it: the answer changes at that measure, and only there)
do
    local text = "alpha beta gamma delta"
    local font = GAME
    local first = ZeD.TM:MeasureStringX(font, "alpha beta")
    check("the probe width is whole", first == math.floor(first), first)
    -- at root 0.75 the role fonts' widths are fractions: find one inside a pixel
    local f2w = ZeD.TM:MeasureStringX(F2, "alpha beta")
    local cell = math.floor(f2w)
    local below, above = cell + (f2w - cell) / 2, f2w + (cell + 1 - f2w) / 2
    if f2w > cell then
        local b1, a1 = newWrap(text, F2, above), newWrap(text, F2, below)
        check("inside one pixel, above the measure", same(b1, oldWrap(text, F2, above)), show(b1))
        check("inside one pixel, below the measure", same(a1, oldWrap(text, F2, below)), show(a1))
        check("the two differ (the pixel holds a measure)", not same(b1, a1))
        local c1, c2 = newTrunc("alpha beta gamma", F2, above), newTrunc("alpha beta gamma", F2, below)
        check("cut inside one pixel, both sides", c1 == oldTrunc("alpha beta gamma", F2, above) and c2 == oldTrunc("alpha beta gamma", F2, below), c1 .. " / " .. c2)
    else
        check("a fractional role-font width to probe", false, f2w)
    end
end

-- 4. no epoch (the fonts still loading): straight through, same answers, nothing kept ----------------------------
X._fontsSettled = false
local before = A._wrapMemo.hits + A._wrapMemo.misses
for ti = 1, #TEXTS, 11 do
    local o, n = oldWrap(TEXTS[ti], F2, 150.5), newWrap(TEXTS[ti], F2, 150.5)
    check("fonts loading wrap " .. ti, same(o, n))
    check("fonts loading cut " .. ti, oldTrunc(TEXTS[ti], F2, 150.5) == newTrunc(TEXTS[ti], F2, 150.5))
end
check("nothing kept while the fonts load", A._wrapMemo.hits + A._wrapMemo.misses == before)
X._fontsSettled = true
-- odd arguments behave as before (nil text, a nil font)
check("nil text", same(oldWrap(nil, F2, 100), newWrap(nil, F2, 100)))
check("nil font, no epoch use", same(newWrap("a b c", nil, 100), oldWrap("a b c", nil, 100)))
check("one value back", select("#", newWrap("a b", F2, 100)) == 1 and select("#", newTrunc("a b", F2, 3)) == 1
    and select("#", newWrap(nil, F2, 100)) == 1)

-- 5. the frame loop: what a shown detail card, help balloon, needs lines, moodle note and an opening drawer cost --
-- (every ZeD.TM measure counted, kept or not)
TMC = { n = 0 }
do
    local m = ZeD.TM.MeasureStringX
    ZeD.TM.MeasureStringX = function(self, font, str) TMC.n = TMC.n + 1; return m(self, font, str) end
end
local function frames(wrap, trunc, n, nLabels, speed)
    local cardTexts, names = {}, {}
    for i = 1, nLang, 37 do
        if #cardTexts < 14 and #TEXTS[i] > 90 and not string.find(TEXTS[i], "\n") then cardTexts[#cardTexts + 1] = TEXTS[i] end
    end
    for k = 1, 70 do names[k] = TEXTS[(k * 53) % nLang + 1] end
    local labels = {}
    for k = 1, nLabels do labels[k] = TEXTS[(k * 13) % nLang + 1] .. "#" .. k end
    local MC = X._measureCache
    local calls0, flips, lastOld = REAL.calls, 0, MC.xOld
    local own, steadyCalls, steadyOwn = 0, 0, 0
    for fr = 1, n do
        local c0, t0 = REAL.calls, TMC.n
        -- (the drawer opens over the first frames, `speed` px a frame: a new fraction of a pixel each frame)
        local dw = math.min(472, 180 + fr * speed)
        for k, t in ipairs(cardTexts) do wrap(t, (k % 2 == 0) and F2 or F4, dw - 24) end
        wrap(cardTexts[1], F2, 260)
        for _, t in ipairs(names) do trunc(t, F2, dw * 0.45) end
        local mine = TMC.n - t0
        for _, t in ipairs(labels) do ZeD.TM:MeasureStringX(F3, t) end   -- (the rest of the screen's text)
        own = own + mine
        if fr > n - 100 then steadyCalls = steadyCalls + REAL.calls - c0; steadyOwn = steadyOwn + mine end
        if MC.xOld ~= lastOld then flips = flips + 1; lastOld = MC.xOld end
    end
    return { calls = REAL.calls - calls0, flips = flips, own = own, steadyCalls = steadyCalls, steadyOwn = steadyOwn }
end
local function freshStore() ZeD._trGen = (ZeD._trGen or 0) + 1; X.measureEpoch() end
S._root = 1.75; setTokens()
local function scenario(label, n, nLabels, speed)
    freshStore()
    local o = frames(oldWrap, oldTrunc, n, nLabels, speed)
    freshStore()
    local h0, m0 = A._wrapMemo.hits, A._wrapMemo.misses
    local w = frames(newWrap, newTrunc, n, nLabels, speed)
    local hits, misses = A._wrapMemo.hits - h0, A._wrapMemo.misses - m0
    for _, r in ipairs({ { "old", o }, { "new", w } }) do
        local v = r[2]
        print(string.format("wrap_memo_sim: %s, %s: wrap+cut ZeD.TM measures %d (last 100 frames %d); engine measures %d (last 100 frames %d); measure-store turnovers %d",
            label, r[1], v.own, v.steadyOwn, v.calls, v.steadyCalls, v.flips))
    end
    print(string.format("wrap_memo_sim: %s, kept wraps: %d hits, %d misses", label, hits, misses))
    check(label .. ": fewer wrap+cut measures", w.own < o.own, w.own .. " vs " .. o.own)
    check(label .. ": no wrap or cut measures once the drawer is open", w.steadyOwn == 0, w.steadyOwn)
    check(label .. ": no more engine measures", w.calls <= o.calls, w.calls .. " vs " .. o.calls)
    check(label .. ": no more measure-store turnovers", w.flips <= o.flips, w.flips .. " vs " .. o.flips)
    return o, w
end
scenario("600 frames, 1000 other labels, drawer 7.3 px a frame", 600, 1000, 7.3)
scenario("600 frames, 1000 other labels, drawer 0.6 px a frame", 600, 1000, 0.6)
local o, w = scenario("600 frames, 2950 other labels (the store near full), drawer 7.3 px a frame", 600, 2950, 7.3)
check("near full: the old wraps churn the store once open, the new do not", w.steadyCalls == 0 and o.steadyCalls > 0,
    o.steadyCalls .. " / " .. w.steadyCalls)

print(string.format("wrap_memo_sim: %d wraps and %d cuts compared at random, %d slide steps, %d one-pixel steps", nW, nT, slides, crossings))
print("wrap_memo_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
