-- ZeDUI/tools/qa/guide_ads_sim.lua  (Nov 7 2026, Build): the survival guide's ads (punch list 98) with no game running.
-- The real ZeD_SurvivalGuideBook.lua runs on Lua 5.1 stubs of the game. A made-up book is laid out and dealt: no ad
-- twice, half and pair alternate, a slot with no ad left falls through (third, then NOTES; a whole page to NOTES),
-- the same seed deals the same book, another seed another order, and a new layout (text size, pad wording) keeps
-- the order. Then every page is drawn on a recording panel: the textures load only when their page draws, at their
-- design size times u, in the text block, inside the page.
-- Last, THE COUNT: an estimate of how many slots the real book asks for at Small and Large text, keyboard and pad,
-- from the game's English text (SurvivalGuide.json, ZeD's UI.json), the faces' own widths (the game's .fnt files)
-- and modeled rules tables (their rows come from the game's data at run time: rows guessed, see ROWS below). It is an
-- estimate; the -debug console line "ZeD guide ads (...)" (B.adReport) gives the real count in the game.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/guide_ads_sim.lua
-- It prints FAIL lines and a last line "guide_ads_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]guide_ads_sim%.lua$", "")
local PZ = "E:/Project Zomboid/steamapps/common/ProjectZomboid/media/"

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

-- ---------------------------------------------------------------------------
-- THE STUBS
-- ---------------------------------------------------------------------------
-- the faces' advance widths from the game's .fnt files (atlas px); without the game, 16 a character
local FNT = { SdfOldRegular = "SdfOldRegular", SdfOldBold = "SdfOldBold", SdfOldItalic = "SdfOldItalic",
              SdfRobertoSans = "sdfRobertoSans", SdfRegular = "sdfRegular", SdfBold = "sdfBold", SdfItalic = "sdfItalic" }
local ADV = {}
local realFonts = true
for slot, file in pairs(FNT) do
    local f = io.open(PZ .. "fonts/" .. file .. ".fnt", "r")
    local t = {}
    if f then
        for line in f:lines() do
            local id, xa = line:match("^char id=(%d+).-xadvance=(%-?%d+)")
            if id then t[tonumber(id)] = tonumber(xa) end
        end
        f:close()
    else
        realFonts = false
    end
    ADV[slot] = t
end
local function measure(font, s)
    local t = ADV[font] or {}
    local w = 0
    for i = 1, #s do w = w + (t[s:byte(i)] or (realFonts and t[120] or 16) or 16) end
    return w
end

UIFont = setmetatable({}, { __index = function(_, k) return k end })   -- (a face is its slot's name here)
getTextManager = function() return { MeasureStringX = function(_, font, s) return measure(font, tostring(s)) end } end
require = function() return nil end
ISPanelJoypad = { derive = function(_, name) local c = { Type = name }; c.__index = c; return c end }
local debugOn = false
isDebugEnabled = function() return debugOn end
local printed = {}
local realPrint = print
print = function(s, ...) if type(s) == "string" and s:find("^ZeD guide ads") then printed[#printed + 1] = s else realPrint(s, ...) end end
getCore = function() return { getOptionDoVideoEffects = function() return false end } end
getTexture = function() return nil end

-- the textures: what loads, with what flags
local loads = {}
Texture = { getSharedTexture = function(path, flags) loads[#loads + 1] = { path = path, flags = flags }; return { path = path } end }

-- the save and the character the seed is read from
local WORLD, FORE, SUR = "Sim Save", "Kate", "Bowman"
getWorld = function() return { getWorld = function() return WORLD end } end
getSpecificPlayer = function()
    return { getDescriptor = function() return { getForename = function() return FORE end, getSurname = function() return SUR end } end }
end

-- English words: ZeD's UI.json from the repo (for the count; the checks run on keys if it is missing)
local EN = {}
local function readJson(path, into)
    local f = io.open(path, "r")
    if not f then return false end
    for line in f:lines() do
        local k, v = line:match('^%s*"([^"]+)"%s*:%s*"(.*)"%s*,?%s*$')
        if k then into[k] = (v:gsub('\\"', '"'):gsub("\\n", "\n"):gsub("\\\\", "\\")) end
    end
    f:close()
    return true
end
readJson(ROOT .. "42/media/lua/shared/Translate/EN/UI.json", EN)

local logs = {}
ZeD = {
    tr = function(k, ...)
        local s = EN[k] or k
        local a = { ... }
        for i = 1, 4 do if a[i] ~= nil then s = s:gsub("%%" .. i, tostring(a[i])) end end
        return s
    end,
    logOnce = function(k, e) logs[#logs + 1] = tostring(k) .. ": " .. tostring(e) end,
    T = { scale = 1, root = 1 },
}
local onPad = false
local SECTIONS = {}
ZeD.Guide = {
    MARK = "\1",
    inlineTex = function(path) return { key = path } end,
    inlineW = function(_, s) return s * 1.6 end,   -- (a key cap: its name in a frame, about 1.6 lines wide)
    inlineDraw = noop,
    paragraphs = function(text)
        local out = {}
        for part in (tostring(text or "") .. "<LINE>"):gmatch("(.-)<LINE>") do
            part = part:gsub("<[^>]*>", ""):gsub("^%s+", ""):gsub("%s+$", "")
            if part ~= "" then out[#out + 1] = part end
        end
        return out
    end,
    twoWays = function(t) return t._ways end,
    Rules = {},
    rulesList = function(t) return t._rules end,
    spoilHidden = function() return false end,
    onPad = function() return onPad end,
    readTopicList = function()
        local byId, flat = {}, {}
        for _, s in ipairs(SECTIONS) do for _, t in ipairs(s.topics) do byId[t.id] = t; flat[#flat + 1] = t end end
        return SECTIONS, byId, flat
    end,
}

dofile(ROOT .. "42/media/lua/client/ZeD/ZeD_SurvivalGuideBook.lua")
local B = ZeD.GuideBook
local A = ZeD.GuideAds
local S = A.size
check("the book file loads and has the ads", B and A and B.paginate and B.dealAds and ZeD_GuideBook and ZeD_GuideBook.drawFiller)

local U_ = { PW = 520, PH = 690, M = 40, MT = 30, FOOT = 26 }   -- (the book's page in design units, as U)

local function newBook() return setmetatable({ playerNum = 0, _clips = {} }, ZeD_GuideBook) end
local function setText(m) ZeD.T.scale = m; B.applyType() end

-- ---------------------------------------------------------------------------
-- A MADE-UP BOOK: chapters of topics of known lengths, clips on most, rules tables on some
-- ---------------------------------------------------------------------------
local WORDS = { "the", "water", "survive", "a", "door", "careful", "zombies", "fence", "of", "food", "always", "quiet",
                "to", "barricade", "and", "keep", "running", "window", "noise", "dead" }
local function text(n, seed)
    local w = {}
    for i = 1, n do w[i] = WORDS[((i * 7 + seed * 3) % #WORDS) + 1] end
    local s = table.concat(w, " ")
    return s:sub(1, 1):upper() .. s:sub(2) .. "."
end
local function rows(n, cols)
    local r = {}
    for i = 1, n do
        local row = {}
        for c = 1, cols do row[c] = (c == 1) and ("Row " .. i) or tostring(i * c) end
        r[i] = row
    end
    return r
end
local function madeUpBook()
    local secs = {}
    local n = 0
    for si = 1, 9 do
        local id = (si == 4) and "zedch:firstdays" or ("s" .. si)
        local s = { id = id, title = "Chapter " .. si, titleKey = "T_s" .. si, topics = {} }
        for ti = 1, 6 do
            n = n + 1
            local t = { id = id .. ":" .. ti, section = s, title = "Topic " .. si .. "." .. ti, titleKey = "T_" .. si .. "_" .. ti,
                        text = text(30 + ((n * 37) % 170), n) .. "<LINE>" .. text(20 + ((n * 13) % 60), n + 1) }
            if (n % 3) ~= 0 then t.video = "media/videos/t" .. n .. ".bk2" end
            if (n % 4) == 0 then t._ways = { { label = "Walk", kb = { { key = "W" } }, pad = { { key = "LS" } } },
                                             { label = "Run", kb = { { key = "Shift" } }, pad = { { key = "LB" } } } } end
            -- (a rules table on every seventh topic, but never a chapter's first: as the game's)
            if ti > 1 and (n % 7) == 0 then
                ZeD.Guide.Rules[t.titleKey] = function() end
                t._rules = { { title = "Numbers " .. n, cols = { "Thing", "Value", "More" }, rows = rows(3 + (n % 5) * 4, 3), notes = { "A note." } } }
                if n % 2 == 0 then t._rules[2] = { title = "Long " .. n, cols = { "Item", "Days" }, rows = rows(30, 2), notes = { "One.", "Two." } } end
                -- (two topics' tables behind a spoiler bar, as the game's world settings: their feet are dealt last)
                if n % 14 == 7 then t._rules[1].spoiler = true end
            end
            s.topics[#s.topics + 1] = t
        end
        secs[#secs + 1] = s
    end
    return secs
end

-- every ad a laid-out book shows, in the order it was dealt (page order, the feet of spoiler rules pages last, as
-- B.dealAds deals them); and a signature of the whole deal, in page order
local function dealt(bk)
    local names, sig, blocks = {}, {}, {}
    local later = {}
    local function take(i, f, spoil)
        for _, b in ipairs(f.ads or {}) do
            blocks[#blocks + 1] = { page = i, k = b.k, y = b.y, y1 = f.y1, names = b.names, spoil = spoil }
            for _, nm in ipairs(b.names or {}) do names[#names + 1] = nm end
        end
    end
    for i, p in ipairs(bk.pages) do
        if p.kind == "ad" then
            sig[#sig + 1] = i .. ":full=" .. tostring(p.ad)
            if p.ad and p.ad ~= "house" then names[#names + 1] = p.ad end
            if p.ad == "house" then names[#names + 1] = "house" end
        end
        local fills = {}
        if p.kind == "flow" then for _, it in ipairs(p.items) do if it.k == "filler" then fills[#fills + 1] = it end end end
        if p.kind == "rules" and p.filler then fills[#fills + 1] = p.filler end
        for _, f in ipairs(fills) do
            for _, b in ipairs(f.ads or {}) do sig[#sig + 1] = i .. ":" .. b.k .. "=" .. table.concat(b.names or {}, "+") end
            if p.kind == "rules" and p.rules and p.rules.spoiler then later[#later + 1] = { i, f } else take(i, f, false) end
        end
    end
    for _, l in ipairs(later) do take(l[1], l[2], true) end
    return names, table.concat(sig, " "), blocks
end
-- the names of one size in the order a book dealt them
local function orderOf(names, prefix)
    local out = {}
    for _, nm in ipairs(names) do if nm:sub(1, #prefix) == prefix then out[#out + 1] = nm end end
    return out
end
local function isPrefix(a, b)   -- a is the start of b, or b of a
    for i = 1, math.min(#a, #b) do if a[i] ~= b[i] then return false end end
    return true
end
local VALID = { house = true }
for _, k in ipairs({ "full", "half", "third", "quarter" }) do for _, nm in ipairs(A[k]) do VALID[nm] = true end end

-- ---------------------------------------------------------------------------
section("the generator: every value below 2^31, never 0")
-- ---------------------------------------------------------------------------
do
    local okRange, okInt = true, true
    for _, s0 in ipairs({ 1, 2, 16807, 2147483646, 123456789, B.hashSeed("x") }) do
        local x = s0
        for _ = 1, 50000 do
            x = B.pmNext(x)
            if x < 1 or x >= 2147483647 then okRange = false end
            if x ~= math.floor(x) then okInt = false end
        end
    end
    check("pmNext stays in 1 .. 2^31 - 2", okRange)
    check("pmNext stays whole", okInt)
    -- (Park and Miller's published check: from 1, the 10000th value is 1043618065)
    local x = 1
    for _ = 1, 10000 do x = B.pmNext(x) end
    check("pmNext is the minimal standard generator", x == 1043618065, x)
    local long = string.rep("Knox County survivor ", 200)
    local h = B.hashSeed(long)
    check("hashSeed of a long string is in range", h >= 1 and h < 2147483647 and h == math.floor(h), h)
    check("hashSeed is stable", B.hashSeed("Sim Save|Kate Bowman") == B.hashSeed("Sim Save|Kate Bowman"))
    check("hashSeed tells two names apart", B.hashSeed("Sim Save|Kate Bowman") ~= B.hashSeed("Sim Save|Baldspot Bowman"))
end

-- ---------------------------------------------------------------------------
section("the deck: each size shuffled from the seed, the house ad among the full pages")
-- ---------------------------------------------------------------------------
do
    local d = B.adDeck(B.hashSeed("a"))
    local function perm(list, of)
        local want = {}
        for _, v in ipairs(of) do want[v] = (want[v] or 0) + 1 end
        for _, v in ipairs(list) do want[v] = (want[v] or 0) - 1 end
        for _, c in pairs(want) do if c ~= 0 then return false end end
        return #list == #of
    end
    local fullPlus = { "house" }
    for _, v in ipairs(A.full) do fullPlus[#fullPlus + 1] = v end
    check("full deck: the 3 ads and the house ad", perm(d.full, fullPlus))
    check("half deck: the 7", perm(d.half, A.half))
    check("third deck: the 12", perm(d.third, A.third))
    check("quarter deck: the 12", perm(d.quarter, A.quarter))
    local d2 = B.adDeck(B.hashSeed("a"))
    check("the same seed, the same deck", table.concat(d.third, ",") == table.concat(d2.third, ",") and table.concat(d.full, ",") == table.concat(d2.full, ","))
    local differ = 0
    for i = 1, 20 do
        local x, y = B.adDeck(B.hashSeed("save|" .. i)), B.adDeck(B.hashSeed("save|" .. (i + 100)))
        if table.concat(x.third, ",") .. table.concat(x.quarter, ",") ~= table.concat(y.third, ",") .. table.concat(y.quarter, ",") then differ = differ + 1 end
    end
    check("other seeds, other decks (20 pairs)", differ == 20, differ)
    -- the house ad moves: over 40 seeds it lands in each of the four places
    local at = {}
    for i = 1, 40 do
        local dd = B.adDeck(B.hashSeed("book " .. i))
        for j, v in ipairs(dd.full) do if v == "house" then at[j] = true end end
    end
    check("the house ad takes every place in the full-page order", at[1] and at[2] and at[3] and at[4])
end

-- ---------------------------------------------------------------------------
section("a book laid out and dealt: no repeats, every slot as planned")
-- ---------------------------------------------------------------------------
SECTIONS = madeUpBook()
setText(1)
local bk = newBook()
bk:readTopics(1)
check("no error logged laying out", #logs == 0, logs[1])
local names, sig1, blocks = dealt(bk)
do
    local seen, dup = {}, nil
    for _, nm in ipairs(names) do
        if seen[nm] then dup = nm end
        seen[nm] = true
    end
    check("no ad twice in one book", dup == nil, dup)
    local bad = nil
    for _, nm in ipairs(names) do if not VALID[nm] then bad = nm end end
    check("every ad is on the list", bad == nil, bad)
    local st = bk.adStats
    check("the made-up book has whole-page slots", st.full >= 2, st.full)
    check("the made-up book has 310 slots", st.ask310 >= 3, st.ask310)
    -- full pages in the deck's order
    local d = B.adDeck(bk._adSeed)
    local fullSeq = {}
    for _, p in ipairs(bk.pages) do if p.kind == "ad" then fullSeq[#fullSeq + 1] = p.ad end end
    local inOrder = true
    for i, v in ipairs(fullSeq) do
        if i <= #d.full then inOrder = inOrder and v == d.full[i] else inOrder = inOrder and v == false end
    end
    check("whole pages take the full deck in order, then NOTES", inOrder, table.concat((function() local o = {} for i, v in ipairs(fullSeq) do o[i] = tostring(v) end return o end)(), ","))
    -- each size dealt in its deck's order
    check("halves in deck order", isPrefix(orderOf(names, "half_"), d.half))
    check("thirds in deck order", isPrefix(orderOf(names, "third_"), d.third))
    check("quarters in deck order", isPrefix(orderOf(names, "quarter_"), d.quarter))
    -- alternation: half, pair, half, pair... while both lists last
    local seq = {}
    for _, b in ipairs(blocks) do if b.k == "half" or b.k == "pair" then seq[#seq + 1] = b.k end end
    local alt, halves, pairs_ = true, 0, 0
    for i, k in ipairs(seq) do
        local bothLeft = halves < #A.half and pairs_ * 2 + 2 <= #A.quarter
        if bothLeft then
            local want = (i % 2 == 1) and "half" or "pair"
            if k ~= want then alt = false end
        end
        if k == "half" then halves = halves + 1 else pairs_ = pairs_ + 1 end
    end
    check("a half, then a pair, while both last", alt and #seq >= 2, table.concat(seq, ","))
    -- every block inside its slot; 310 and 205 tall; NOTES last
    local fits, gaps, notesLast = true, true, true
    local byFill = {}
    for _, b in ipairs(blocks) do
        local h = (b.k == "half" or b.k == "pair") and S.half[2] or (b.k == "third" and S.third[2]) or 0
        if b.y + h > b.y1 + 0.001 then fits = false end
    end
    for _, p in ipairs(bk.pages) do
        local fills = {}
        if p.kind == "flow" then for _, it in ipairs(p.items) do if it.k == "filler" then fills[#fills + 1] = it end end end
        if p.kind == "rules" and p.filler then fills[#fills + 1] = p.filler end
        for _, f in ipairs(fills) do
            local ads = f.ads or {}
            for i = 2, #ads do
                local prev = ads[i - 1]
                local h = (prev.k == "half" or prev.k == "pair") and S.half[2] or (prev.k == "third" and S.third[2]) or nil
                if h and math.abs(ads[i].y - (prev.y + h + 18)) > 0.001 then gaps = false end
                if prev.k == "notes" then notesLast = false end
            end
        end
    end
    check("every ad inside its slot (never over the foot or the folio)", fits)
    check("18 after each ad", gaps)
    check("NOTES only last", notesLast)
    -- the First Days checklist: first in the first First Days filler with room
    local firstFD = nil
    for _, p in ipairs(bk.pages) do
        if p.kind == "flow" and p.section and p.section.id == "zedch:firstdays" then
            for _, it in ipairs(p.items) do if it.k == "filler" and not firstFD then firstFD = it end end
        end
    end
    check("the made-up book has a First Days filler", firstFD ~= nil)
    if firstFD then
        local ch = bk:drawChecklist(0, 440, 0, 1, true)
        local wantCheck = firstFD.y1 - firstFD.y >= ch
        check("the checklist first when it fits", (not wantCheck) or (firstFD.ads[1] and firstFD.ads[1].k == "check"))
    end
    -- a rules page's foot is dealt too
    local rulesFill = 0
    for _, p in ipairs(bk.pages) do if p.kind == "rules" and p.filler and p.filler.ads and #p.filler.ads > 0 then rulesFill = rulesFill + 1 end end
    check("rules pages' feet take fillers", rulesFill >= 1, rulesFill)
    -- the feet of spoiler rules pages are dealt after every other slot: for each size, every ad on a hidden foot
    -- sits later in the deck than every ad in plain sight (and the alternation above runs across both passes)
    local pos = {}
    for _, k in ipairs({ "half", "third", "quarter" }) do for j, nm in ipairs(d[k]) do pos[nm] = j end end
    local plainMax, spoilMin, spoilAds = {}, {}, 0
    for _, b in ipairs(blocks) do
        for _, nm in ipairs(b.names or {}) do
            local size = nm:match("^(%a+)_")
            if b.spoil then
                spoilAds = spoilAds + 1
                spoilMin[size] = math.min(spoilMin[size] or 99, pos[nm])
            else
                plainMax[size] = math.max(plainMax[size] or 0, pos[nm])
            end
        end
    end
    local spoilFirst = true
    for size, m in pairs(spoilMin) do if m <= (plainMax[size] or 0) then spoilFirst = false end end
    check("the made-up book deals ads to a spoiler page's foot", spoilAds >= 1, spoilAds)
    local spoilFoot = false
    for _, p in ipairs(bk.pages) do if p.kind == "rules" and p.rules.spoiler and p.filler then spoilFoot = true end end
    check("the made-up book has a spoiler rules page with a foot", spoilFoot)
    check("spoiler pages' feet dealt after every slot in plain sight", spoilFirst)
end

-- ---------------------------------------------------------------------------
section("the same seed, the same book; another character, another order")
-- ---------------------------------------------------------------------------
do
    local again = newBook()
    again:readTopics(1)
    local _, sig2 = dealt(again)
    check("laid out again: the same deal", sig1 == sig2)
    bk:readTopics(1)
    local _, sig3 = dealt(bk)
    check("the same panel laid out again: the same deal", sig1 == sig3)
    FORE = "Baldspot"
    local other = newBook()
    other:readTopics(1)
    local _, sig4 = dealt(other)
    check("another character: another deal", sig4 ~= sig1)
    FORE = "Kate"
    WORLD = "Another Save"
    local other2 = newBook()
    other2:readTopics(1)
    local _, sig5 = dealt(other2)
    check("another save: another deal", sig5 ~= sig1)
    WORLD = "Sim Save"
    -- (and the scale alone changes nothing: 4K at 1.75x deals as 1080p)
    local big = newBook()
    big:readTopics(1.75)
    local _, sig6 = dealt(big)
    check("u 1.75: the same deal as u 1", sig6 == sig1)
end

-- ---------------------------------------------------------------------------
section("a new layout deals again from the same seed: the order stays")
-- ---------------------------------------------------------------------------
do
    local small = newBook()
    small:readTopics(1)
    local nS, sigS = dealt(small)
    setText(1.15)
    local large = newBook()
    large:readTopics(1)
    local nL, sigL = dealt(large)
    onPad = true
    local pad = newBook()
    pad:readTopics(1)
    local nP, sigP = dealt(pad)
    onPad = false
    setText(1)
    check("Large text lays the book out differently", #large.pages ~= #small.pages or sigL ~= sigS)
    check("pad wording lays the book out differently", sigP ~= sigS)
    for _, pre in ipairs({ "half_", "third_", "quarter_" }) do
        check("Small and Large keep the " .. pre .. " order", isPrefix(orderOf(nS, pre), orderOf(nL, pre)))
        check("keyboard and pad keep the " .. pre .. " order", isPrefix(orderOf(nS, pre), orderOf(nP, pre)))
    end
    local fS, fL = {}, {}
    for _, p in ipairs(small.pages) do if p.kind == "ad" then fS[#fS + 1] = tostring(p.ad) end end
    for _, p in ipairs(large.pages) do if p.kind == "ad" then fL[#fL + 1] = tostring(p.ad) end end
    check("Small and Large keep the full-page order", isPrefix(fS, fL), table.concat(fS, ",") .. " / " .. table.concat(fL, ","))
end

-- ---------------------------------------------------------------------------
section("too few ads: a slot falls through, never a repeat")
-- ---------------------------------------------------------------------------
do
    local saved = { full = A.full, half = A.half, third = A.third, quarter = A.quarter }
    A.full, A.half, A.third, A.quarter = { saved.full[1] }, { saved.half[1] }, { saved.third[1] }, { saved.quarter[1], saved.quarter[2] }
    local few = newBook()
    few:readTopics(1)
    local n, _, bl = dealt(few)
    local seen, dup = {}, nil
    for _, nm in ipairs(n) do if seen[nm] then dup = nm end; seen[nm] = true end
    check("no repeat with 5 ads", dup == nil, dup)
    local st = few.adStats
    check("whole pages past the house ad and the one full ad are NOTES", st.fullMiss == math.max(0, st.full - 2), st.full .. "/" .. st.fullMiss)
    check("310 slots with nothing left are counted", st.miss310 == st.ask310 - 2, st.ask310 .. "/" .. st.miss310)
    local kinds = {}
    for _, b in ipairs(bl) do kinds[b.k] = (kinds[b.k] or 0) + 1 end
    check("one half and one pair, no more", kinds.half == 1 and kinds.pair == 1, tostring(kinds.half) .. "/" .. tostring(kinds.pair))
    check("one third, no more", kinds.third == 1, kinds.third)
    -- with one of each, a page in plain sight gets it before any foot behind a spoiler bar
    local hidden = nil
    for _, b in ipairs(bl) do if b.spoil and b.k ~= "notes" then hidden = b.k end end
    check("too few ads: a foot behind a spoiler bar gets none while plain pages ask", hidden == nil, hidden)
    -- a 310 slot with neither left falls to the third or to NOTES, in the same filler
    local fell = false
    for _, p in ipairs(few.pages) do
        if p.kind == "flow" then
            for _, it in ipairs(p.items) do
                if it.k == "filler" and it.ads and it.ads[1] and (it.ads[1].k == "third" or it.ads[1].k == "notes") and it.y1 - it.y >= S.half[2] then fell = true end
            end
        end
    end
    check("a 310 slot with no ad left falls through", fell)
    -- a pair needs two quarters: with one left, a half (none here), else on
    A.quarter = { saved.quarter[1] }
    local odd = newBook()
    odd:readTopics(1)
    local _, _, bo = dealt(odd)
    local pairsSeen = 0
    for _, b in ipairs(bo) do if b.k == "pair" then pairsSeen = pairsSeen + 1 end end
    check("one quarter left: never a pair", pairsSeen == 0)
    A.full, A.half, A.third, A.quarter = saved.full, saved.half, saved.third, saved.quarter
end

-- ---------------------------------------------------------------------------
section("drawing: each texture when its page first draws, at its size, in the text block")
-- ---------------------------------------------------------------------------
do
    local draws = {}
    local book = newBook()
    book:readTopics(1.75)
    local u = 1.75
    local before = #loads
    -- the recording panel: the book's own fields and methods, the panel's drawing calls recorded or ignored
    local P = {}
    for k, v in pairs(book) do P[k] = v end
    setmetatable(P, { __index = function(_, k)
        if k == "drawTextureScaled" then
            return function(_, tex, x, y, w, h, a, r, g, b) draws[#draws + 1] = { tex = tex, x = x, y = y, w = w, h = h, c = a + r + g + b } end
        end
        if ZeD_GuideBook[k] then return ZeD_GuideBook[k] end
        if k:find("^get") then return function() return 0 end end
        if k:find("^draw") then return noop end
        return nil
    end })
    -- draw the first spread only (the blank page and the title page): no ad loads
    local W, X0, Y0 = U_.PW * u, 100, 50
    P:drawPage(1, X0, Y0, W, u)
    P:drawPage(2, X0 + W, Y0, W, u)
    check("the front matter loads no ad", #loads == before, #loads - before)
    local sigBefore = select(2, dealt(book))
    local okAll, outside, wrongSize, wrongX, white, whole = true, nil, nil, nil, true, true
    local function rnd(v) return math.floor(v + 0.5) end
    local adOf = {}   -- the texture path each draw used, per page
    for i = 1, #book.pages do
        local x = (i % 2 == 1) and X0 or X0 + W
        local n0 = #draws
        local ok, err = pcall(P.drawPage, P, i, x, Y0, W, u)
        if not ok then okAll = false; print("  page " .. i .. ": " .. tostring(err)) end
        local p = book.pages[i]
        for j = n0 + 1, #draws do
            local d = draws[j]
            local name = d.tex.path:match("([^/]+)%.png$")
            local size = name:match("^(%a+)_")
            local s = S[size]
            -- (design size times u, rounded to whole pixels)
            if d.w ~= rnd(s[1] * u) or d.h ~= rnd(s[2] * u) then wrongSize = name end
            for _, v in ipairs({ d.x, d.y, d.w, d.h }) do if v ~= math.floor(v) then whole = false end end
            if d.c ~= 4 then white = false end
            local tx = x + U_.M * u
            -- (a pair's second quarter: the first's rounded right edge plus the rounded 10 gutter)
            local q2 = rnd(tx) + rnd(S.quarter[1] * u) + rnd(10 * u)
            if size == "full" then
                if d.x ~= rnd(tx) or d.y ~= rnd(Y0 + U_.MT * u) then wrongX = name end
            elseif not (d.x == rnd(tx) or (size == "quarter" and d.x == q2)) then
                wrongX = name
            end
            -- inside the page's text block (to the rounding, 1.5 px): never under the foot's folio line
            if d.x < x + U_.M * u - 1.5 or d.x + d.w > x + (U_.PW - U_.M) * u + 1.5 or d.y + d.h > Y0 + (U_.PH - U_.FOOT) * u + 1.5 or d.y < Y0 + U_.MT * u - 1.5 then outside = name end
            adOf[i] = adOf[i] or {}
            adOf[i][#adOf[i] + 1] = name
        end
        -- what the page drew is what was dealt to it
        local want = {}
        if p.kind == "ad" and p.ad and p.ad ~= "house" then want[1] = p.ad end
        local fills = {}
        if p.kind == "flow" then for _, it in ipairs(p.items) do if it.k == "filler" then fills[#fills + 1] = it end end end
        if p.kind == "rules" and p.filler then fills[#fills + 1] = p.filler end
        for _, f in ipairs(fills) do for _, b in ipairs(f.ads or {}) do for _, nm in ipairs(b.names or {}) do want[#want + 1] = nm end end end
        check("page " .. i .. " draws what was dealt to it", table.concat(want, ",") == table.concat(adOf[i] or {}, ","), table.concat(want, ",") .. " / " .. table.concat(adOf[i] or {}, ","))
    end
    check("every page draws without an error", okAll)
    check("every ad at its design size times u, rounded", wrongSize == nil, wrongSize)
    check("every ad on whole pixels (x, y, width, height)", whole)
    check("full ads at the text block's corner, fillers at its left (a pair's second after a 10 gutter)", wrongX == nil, wrongX)
    check("every ad inside the text block", outside == nil, outside)
    check("drawn untinted (1, 1, 1, 1)", white)
    -- a pair's two quarters level, the gutter between them the rounded 10
    local level, pairsDrawn, gutterOk = true, 0, true
    for i = 2, #draws do
        local a, b = draws[i - 1], draws[i]
        if a.tex.path:find("/quarter_") and b.tex.path:find("/quarter_") and b.x > a.x then
            pairsDrawn = pairsDrawn + 1
            if a.y ~= b.y then level = false end
            if b.x - (a.x + a.w) ~= rnd(10 * u) then gutterOk = false end
        end
    end
    check("the drawn book has a pair", pairsDrawn >= 1, pairsDrawn)
    check("a pair's two quarters level", level)
    check("a pair's gutter the rounded 10", gutterOk)
    -- each texture loaded once, flags 2 (crisp when enlarged, linear when shrunk, uncompressed), from the ads' folder
    local count, flagsOk, dirOk = {}, true, true
    for j = before + 1, #loads do
        local l = loads[j]
        count[l.path] = (count[l.path] or 0) + 1
        if l.flags ~= 2 then flagsOk = false end
        if not l.path:find("^media/textures/ZeD/guide/ads/") then dirOk = false end
    end
    local once = true
    for _, c in pairs(count) do if c > 1 then once = false end end
    check("each texture loaded once", once)
    check("loaded with flags 2", flagsOk)
    check("loaded from media/textures/ZeD/guide/ads/", dirOk)
    -- drawing changes nothing about the deal
    check("turning the pages never deals again", select(2, dealt(book)) == sigBefore)
    -- the house ad page draws the Lua ad (no texture); a page past the full ads draws NOTES (no texture)
    local house, notesPage = nil, nil
    for i, p in ipairs(book.pages) do
        if p.kind == "ad" and p.ad == "house" then house = i end
    end
    if house then check("the house ad's page draws no texture", adOf[house] == nil) end
    local fp = { kind = "ad", ad = false }
    local n0 = #draws
    P:drawFullAd(fp, X0, Y0, W, u)
    check("a whole page with no full ad left draws NOTES, no texture", #draws == n0)
    -- the spoiler: a hidden rules page draws no filler; shown, it does
    local rp = nil
    for i, p in ipairs(book.pages) do if p.kind == "rules" and p.filler and p.filler.ads and p.filler.ads[1] and p.filler.ads[1].names then rp = p end end
    if rp then
        ZeD.Guide.spoilHidden = function() return true end
        local m0 = #draws
        P:drawRulesPage(rp, X0, Y0, W, u)
        check("a rules page behind its spoiler bar draws no ad", #draws == m0)
        ZeD.Guide.spoilHidden = function() return false end
        P:drawRulesPage(rp, X0, Y0, W, u)
        check("shown, it draws its foot's ads", #draws > m0)
        check("showing the numbers deals nothing again", select(2, dealt(book)) == sigBefore)
    end
end

-- ---------------------------------------------------------------------------
section("the -debug count line")
-- ---------------------------------------------------------------------------
do
    debugOn = true
    printed = {}
    local b2 = newBook()
    b2:readTopics(1)
    b2:readTopics(1)
    debugOn = false
    check("the count prints once for a layout", #printed == 1, #printed)
    check("it names the slots", printed[1] and printed[1]:find("full pages") and printed[1]:find("310 slots") and printed[1]:find("205 slots"), printed[1])
end

-- ---------------------------------------------------------------------------
-- THE COUNT: the real book's slots, estimated (see the header)
-- ---------------------------------------------------------------------------
-- ROWS: the rules tables' rows, which the game reads from its data at run time (guesses, from the code's notes and
-- the game's lists): Skill Books' 5 volumes, XP 10 levels, ~30 occupations, ~97 traits (in 16s: long skills
-- column), ~25 foods in a stocked bag, 55 crops, 3 world settings twice
local ROWS = {
    SurvivalGuide_skill_books_title = { { 5, 4, 8 }, { 10, 4, 6 }, { 30, 3, 40 }, { 97, 3, 40 } },
    SurvivalGuide_eating_drinking_title = { { 25, 4, 6 } },
    SurvivalGuide_sow_seeds_title = { { 55, 4, 6 } },
    SurvivalGuide_treat_water_title = { { 3, 2, 12 } },
    SurvivalGuide_zombie_attacks_title = { { 3, 2, 12 } },
}
-- (the world's settings, behind a spoiler bar in the game: their feet are dealt last)
local SPOILER = { SurvivalGuide_treat_water_title = true, SurvivalGuide_zombie_attacks_title = true }
local function realBook(pad)
    local SG = {}
    local order = {}
    local f = io.open(PZ .. "lua/shared/Translate/EN/SurvivalGuide.json", "r")
    if not f then return nil end
    for line in f:lines() do
        local k, v = line:match('^%s*"([^"]+)"%s*:%s*"(.*)"%s*,?%s*$')
        if k then SG[k] = v:gsub('\\"', '"'); order[#order + 1] = k end
    end
    f:close()
    local stills = {}
    local secs, cur = {}, nil
    local function keyMarks(s, n)
        -- (the game's %1 or %1$s: a key cap, as entryText fills them)
        return (s:gsub("%%(%d)%$s", "\1key:K\1"):gsub("%%(%d)", "\1key:K\1"))
    end
    for _, k in ipairs(order) do
        local stem = k:match("^SurvivalGuide_(.+)_title$")
        if stem then
            if SG["SurvivalGuide_" .. stem .. "_category_image"] then
                cur = { id = stem, title = SG[k], titleKey = k, topics = {} }
                secs[#secs + 1] = cur
            elseif cur then
                local d = SG["SurvivalGuide_" .. stem .. "_description"]
                if pad and SG["SurvivalGuide_" .. stem .. "_description_joypad"] then d = SG["SurvivalGuide_" .. stem .. "_description_joypad"] end
                if d and d ~= "<IGNORE>" then
                    local nKeys = 0
                    for _ in d:gmatch("%%%d") do nKeys = nKeys + 1 end
                    local t = { id = stem, section = cur, title = SG[k], titleKey = k, text = keyMarks(d), video = "media/videos/" .. stem .. ".bk2" }
                    if nKeys > 0 then
                        t._ways = {}
                        for i = 1, nKeys do t._ways[i] = { label = "Action", kb = { { key = "K" } }, pad = { { key = "A" } } } end
                    end
                    if ROWS[k] then
                        ZeD.Guide.Rules[k] = function() end
                        t._rules = {}
                        for ri, r in ipairs(ROWS[k]) do
                            local cols = {}
                            for c = 1, r[2] do cols[c] = "Column " .. c end
                            local rr = {}
                            for i = 1, r[1] do
                                local row = { "Name of row " .. i }
                                for c = 2, r[2] do row[c] = (c == r[2]) and string.rep("x", r[3]) or tostring(i * 10) end
                                rr[i] = row
                            end
                            t._rules[ri] = { title = "Table " .. ri, cols = cols, rows = rr, notes = { "A note on the numbers, a line or two long, as the game's own notes run.", "Another note." },
                                             spoiler = SPOILER[k] }
                        end
                    end
                    cur.topics[#cur.topics + 1] = t
                end
            end
        end
    end
    -- ZeD's chapters, from their generated list and the English UI.json
    ZeD.GuideChapters = nil
    local okCh = pcall(dofile, ROOT .. "42/media/lua/client/ZeD/ZeD_GuideChapters.lua")
    for _, ch in ipairs((okCh and ZeD.GuideChapters) or {}) do
        local sec = { id = "zedch:" .. ch.id, title = EN[ch.title] or ch.title, titleKey = ch.title, blurbKey = ch.blurb, topics = {}, zed = true }
        secs[#secs + 1] = sec
        for _, td in ipairs(ch.topics or {}) do
            local function fill(s) return (tostring(s or ""):gsub("{(%a+:[^}]+)}", "\1key:K\1")) end
            local t = { id = sec.id .. ":" .. td.id, section = sec, title = EN[td.title] or td.title, titleKey = td.title, text = fill(EN[td.text] or td.text) }
            local ways = {}
            for _, r in ipairs(td.ways or {}) do ways[#ways + 1] = { kbText = fill(EN[r[1]] or r[1]), padText = fill(EN[r[2]] or r[2]) } end
            for _ in ipairs(td.waysFrom or {}) do ways[#ways + 1] = { label = "Action", kb = { { key = "K" } }, pad = { { key = "A" } } } end
            if td.keys then for i = 1, 60 do ways[#ways + 1] = { label = "Binding " .. i, kb = { { key = "K" } }, pad = {} } end end
            if #ways > 0 then t._ways = ways end
            sec.topics[#sec.topics + 1] = t
        end
    end
    return secs
end

section("THE COUNT (estimate: the real English text and faces, modeled rules tables)")
do
    local results = {}
    for _, m in ipairs({ { 1, "Small" }, { 1.15, "Large" } }) do
        for _, pd in ipairs({ false, true }) do
            local secs = realBook(pd)
            if not secs then print("  (no game files: the count is skipped)"); break end
            SECTIONS = secs
            onPad = pd
            setText(m[1])
            local b = newBook()
            b:readTopics(1)
            local st = b.adStats
            local line = string.format("  %s text, %s: %d pages; whole pages %d (%d NOTES); 310 slots %d (%d with nothing left); 205 slots %d (%d with nothing left); NOTES blocks %d; dealt full %d/4, half %d/7, quarter %d/12, third %d/12",
                m[2], pd and "pad" or "keyboard", #b.pages, st.full, st.fullMiss, st.ask310, st.miss310, st.ask205, st.miss205, st.notes,
                st.at.full, st.at.half, st.at.quarter, st.at.third)
            realPrint(line)
            results[#results + 1] = st
            -- (no repeats in the real book either)
            local n = dealt(b)
            local seen, dup = {}, nil
            for _, nm in ipairs(n) do if seen[nm] then dup = nm end; seen[nm] = true end
            check("the real book (" .. m[2] .. ", " .. (pd and "pad" or "keyboard") .. "): no ad twice", dup == nil, dup)
        end
    end
    onPad = false
    setText(1)
    check("no error logged in the count", #logs == 0, logs[1])
end

realPrint(string.format("guide_ads_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
