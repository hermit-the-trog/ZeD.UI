-- ZeDUI/tools/qa/guide_ads_sim.lua  (Nov 7 2026, Build): the survival guide's ads (punch list 98) with no game running.
-- The real ZeD_SurvivalGuideBook.lua runs on Lua 5.1 stubs of the game. A made-up book is laid out and dealt: no ad
-- twice, half and pair alternate, a slot with no ad left falls through (third, then NOTES; a whole page past the
-- full ads to the smaller ads, then NOTES), the same seed deals the same book, another seed another order, and a new
-- layout (text size, pad wording) keeps the order. The First Days checklist prints exactly once, in its chapter, at
-- Small and Large, keyboard and pad (in a filler with the room, else a block of its own at the chapter's end). Then
-- every page is drawn on a recording panel: the textures load only when their page draws, at their design size times
-- u, in the text block, inside the page. Last of all, the checklist once in the real book in every language.
-- Last, THE COUNT: an estimate of how many slots the real book asks for at Small and Large text, keyboard and pad,
-- from the game's English text (SurvivalGuide.json, ZeD's UI.json), the faces' own widths (the game's .fnt files)
-- and modeled rules tables (their rows come from the game's data at run time: rows guessed, see ROWS below). It is an
-- estimate; the -debug console line "ZeD guide ads (...)" (B.adReport) gives the real count in the game.
-- Then THE HOUSE AD (Nov 7 2026): the publisher's ad laid out in every language's UI.json at Small and Large text,
-- every line measured again and kept inside the frame (see that section); HOUSEAD_DUMP=<code> lists a language's lines.
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
        if (p.kind == "rules" or p.kind == "ad") and p.filler then fills[#fills + 1] = p.filler end
        for _, f in ipairs(fills) do
            for _, b in ipairs(f.ads or {}) do sig[#sig + 1] = i .. ":" .. b.k .. "=" .. table.concat(b.names or {}, "+") end
            if p.kind == "rules" and p.rules and p.rules.spoiler then later[#later + 1] = { i, f } else take(i, f, false) end
        end
    end
    for _, l in ipairs(later) do take(l[1], l[2], true) end
    return names, table.concat(sig, " "), blocks
end
-- THE FIRST DAYS CHECKLIST in a laid-out book: every place it prints (a filler's "check" block or a flow page's
-- "check" item), and what is wrong with each: off its chapter, past the text's foot, over the text above it, under
-- a filler that starts inside it, or taller than its filler
local function checklists(bk, u)
    u = u or 1
    local out, bad = {}, {}
    local bottom = (U_.PH - U_.FOOT - U_.MT) * u
    local h = bk:drawChecklist(0, (U_.PW - U_.M * 2) * u, 0, u, true)
    for i, p in ipairs(bk.pages) do
        local fills = {}
        if p.kind == "flow" then for _, it in ipairs(p.items) do if it.k == "filler" then fills[#fills + 1] = it end end end
        if (p.kind == "rules" or p.kind == "ad") and p.filler then fills[#fills + 1] = p.filler end
        for _, f in ipairs(fills) do
            for _, b in ipairs(f.ads or {}) do
                if b.k == "check" then
                    out[#out + 1] = { page = i, how = "filler", y = b.y, h = h }
                    if b.y + h > f.y1 + 0.001 then bad[#bad + 1] = "page " .. i .. ": taller than its filler" end
                end
            end
        end
        if p.kind == "flow" then
            local above = nil
            for j, it in ipairs(p.items) do
                if it.k == "check" then
                    out[#out + 1] = { page = i, how = "flow", y = it.y, h = h }
                    -- (the text above it ends at a baseline: its descenders reach 0.3 of the text size under it)
                    if above and it.y < above + 12.5 * 0.3 * u * 1.15 then bad[#bad + 1] = "page " .. i .. ": over the text above it" end
                    if it.y + h > bottom + 0.001 then bad[#bad + 1] = "page " .. i .. ": past the foot" end
                    if (p.endY or 0) < it.y + h - 0.001 then bad[#bad + 1] = "page " .. i .. ": the page ends inside it" end
                    for k = j + 1, #p.items do
                        local nx = p.items[k]
                        if nx.k ~= "filler" then bad[#bad + 1] = "page " .. i .. ": text after it on its page"
                        elseif nx.y < it.y + h then bad[#bad + 1] = "page " .. i .. ": its filler starts inside it" end
                    end
                elseif it.k ~= "filler" then
                    above = math.max(above or 0, it.y + (it.h or 0))
                end
            end
        end
    end
    for _, c in ipairs(out) do
        local p = bk.pages[c.page]
        if not (p.section and p.section.id == "zedch:firstdays") then bad[#bad + 1] = "page " .. c.page .. ": outside First Days" end
    end
    return out, bad
end
local function where(cs)
    local o = {}
    for _, c in ipairs(cs) do o[#o + 1] = c.how .. " p" .. c.page end
    return #o > 0 and table.concat(o, ", ") or "nowhere"
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
    check("whole pages take the full deck in order, then none", inOrder, table.concat((function() local o = {} for i, v in ipairs(fullSeq) do o[i] = tostring(v) end return o end)(), ","))
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
        if (p.kind == "rules" or p.kind == "ad") and p.filler then fills[#fills + 1] = p.filler end
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
    local cs, cbad = checklists(bk)
    check("the made-up book prints the checklist once", #cs == 1, where(cs))
    check("the made-up book's checklist in place", #cbad == 0, cbad[1])
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
section("the First Days checklist: once, in its chapter, at every size and wording (QA, Nov 7 2026)")
-- ---------------------------------------------------------------------------
-- At Small text no First Days page had a filler with the room, so it never printed. Now: the first filler with the
-- room as before, else a block of its own at the chapter's end (on a new page when the last has no room). The
-- chapter's last topic is run at 40 lengths and the checklist's lines at 1 to 3 times their length, at Small and
-- Large, keyboard and pad, so every way it can land is seen: in a filler, at the end of the last page, on a page of
-- its own.
do
    local saved = {}
    for i = 1, 7 do saved[i] = EN["UI_ZeD_Guide_Check" .. i] end
    local last = SECTIONS[4].topics[#SECTIONS[4].topics]
    local savedText = last.text
    local seen, fails, n = { filler = 0, flow = 0, newPage = 0 }, {}, 0
    for _, m in ipairs({ 1, 1.15 }) do
        for _, pd in ipairs({ false, true }) do
            setText(m)
            onPad = pd
            for rep = 1, 3 do
                for i = 1, 7 do EN["UI_ZeD_Guide_Check" .. i] = string.rep((saved[i] or ("Item " .. i)) .. " ", rep) end
                for len = 1, 40 do
                    last.text = text(len * 9, len)
                    local b = newBook()
                    b:readTopics(1)
                    n = n + 1
                    local cs, cbad = checklists(b)
                    local tag = string.format("%s %s x%d len %d", m == 1 and "Small" or "Large", pd and "pad" or "keyboard", rep, len)
                    if #cs ~= 1 then fails[#fails + 1] = tag .. ": " .. where(cs) end
                    if cbad[1] then fails[#fails + 1] = tag .. ": " .. cbad[1] end
                    if cs[1] then
                        seen[cs[1].how] = seen[cs[1].how] + 1
                        local p = b.pages[cs[1].page]
                        if cs[1].how == "flow" and p.items[2] and p.items[2].k == "check" then seen.newPage = seen.newPage + 1 end
                    end
                end
            end
        end
    end
    for i = 1, 7 do EN["UI_ZeD_Guide_Check" .. i] = saved[i] end
    last.text = savedText
    onPad = false
    setText(1)
    check("the checklist prints exactly once, in its chapter, never split or over text (" .. n .. " layouts)", #fails == 0, fails[1])
    check("some layouts print it in a filler (as before)", seen.filler > 0, seen.filler)
    check("some layouts print it on a page of its own", seen.newPage > 0, seen.newPage)
    realPrint(string.format("  %d layouts: in a filler %d, after the chapter's text %d, on a new page %d", n, seen.filler, seen.flow - seen.newPage, seen.newPage))
    -- (the real checklist is taller than a third of a page, so a last page with room for it always has a filler
    -- that takes it: under the chapter's text on the same page only happens for a shorter one. Run with a
    -- checklist measured 60 tall so that way is seen too)
    local realCheck = ZeD_GuideBook.drawChecklist
    ZeD_GuideBook.drawChecklist = function(self, tx, tw_, by, u, measureOnly)
        if measureOnly then return 60 * u end
        return realCheck(self, tx, tw_, by, u, measureOnly)
    end
    local short = { filler = 0, flow = 0, newPage = 0 }
    local shortFails = {}
    -- (a small book of three one-topic chapters, First Days the second, its topic at 60 lengths)
    local savedSecs = SECTIONS
    local fd = { id = "zedch:firstdays", title = "First Days", titleKey = "T_fd", topics = {} }
    local one = { id = "zedch:firstdays:1", section = fd, title = "Topic", titleKey = "T_fd_1", text = "" }
    fd.topics[1] = one
    local function chap(id, k)
        local s = { id = id, title = "Chapter " .. id, titleKey = "T_" .. id, topics = {} }
        s.topics[1] = { id = id .. ":1", section = s, title = "Topic " .. id, titleKey = "T_" .. id .. "_1", text = text(120, k) }
        return s
    end
    SECTIONS = { chap("a", 1), fd, chap("b", 2) }
    for len = 1, 60 do
        one.text = text(len * 9, len)
        local b = newBook()
        b:readTopics(1)
        local cs, cbad = checklists(b)
        if #cs ~= 1 or cbad[1] then shortFails[#shortFails + 1] = "len " .. len .. ": " .. where(cs) .. " " .. tostring(cbad[1]) end
        if cs[1] then
            local p = b.pages[cs[1].page]
            local own = cs[1].how == "flow" and p.items[2] and p.items[2].k == "check"
            short[own and "newPage" or cs[1].how] = short[own and "newPage" or cs[1].how] + 1
        end
    end
    ZeD_GuideBook.drawChecklist = realCheck
    SECTIONS = savedSecs
    check("a short checklist: once, in place (60 layouts)", #shortFails == 0, shortFails[1])
    check("a short checklist: some layouts print it under the chapter's text", short.flow > 0, short.flow)
    -- drawn: the book draws it once, wherever it landed
    for _, rep in ipairs({ 1, 3 }) do
        for i = 1, 7 do EN["UI_ZeD_Guide_Check" .. i] = string.rep((saved[i] or ("Item " .. i)) .. " ", rep) end
        local b = newBook()
        b:readTopics(1)
        local drawn = 0
        local P = {}
        for k, v in pairs(b) do P[k] = v end
        setmetatable(P, { __index = function(_, k)
            if k == "drawChecklist" then
                return function(self, tx, tw_, by, u, measureOnly)
                    if not measureOnly then drawn = drawn + 1 end
                    return ZeD_GuideBook.drawChecklist(self, tx, tw_, by, u, true)
                end
            end
            if ZeD_GuideBook[k] then return ZeD_GuideBook[k] end
            if k:find("^get") then return function() return 0 end end
            if k:find("^draw") then return noop end
            return nil
        end })
        for i = 1, #b.pages do P:drawPage(i, 0, 0, U_.PW, 1) end
        check("drawn once (checklist lines x" .. rep .. ", " .. where((checklists(b))) .. ")", drawn == 1, drawn)
    end
    for i = 1, 7 do EN["UI_ZeD_Guide_Check" .. i] = saved[i] end
end

-- ---------------------------------------------------------------------------
section("a checklist that throws: the book still lays out, without it, and logs once")
-- ---------------------------------------------------------------------------
do
    local realCheck = ZeD_GuideBook.drawChecklist
    ZeD_GuideBook.drawChecklist = function() error("checklist boom") end
    local nLogs = #logs
    local b = newBook()
    local ok, err = pcall(b.readTopics, b, 1)
    local ok2, err2 = ok and pcall(b.readTopics, b, 1)
    ZeD_GuideBook.drawChecklist = realCheck
    check("a throwing checklist does not stop the layout", ok and ok2, tostring(err) .. " " .. tostring(err2))
    check("the book is laid out", b.pages and #b.pages > 0, b.pages and #b.pages)
    local found = 0
    for _, p in ipairs(b.pages or {}) do
        for _, it in ipairs(p.items or {}) do
            if it.k == "check" or (it.k == "filler" and it.check) then found = found + 1 end
            for _, a in ipairs(it.ads or {}) do if a.k == "check" then found = found + 1 end end
        end
        for _, a in ipairs((p.filler and p.filler.ads) or {}) do if a.k == "check" then found = found + 1 end end
    end
    check("no checklist block in that layout", found == 0, found)
    local hits = 0
    for i = nLogs + 1, #logs do if logs[i]:find("^survival guide checklist") then hits = hits + 1 end end
    check("the failure is logged (by logOnce)", hits >= 1, table.concat(logs, " | ", nLogs + 1))
    for i = #logs, nLogs + 1, -1 do logs[i] = nil end   -- (the planted failure is not a real one: the count below wants none)
    local b2 = newBook()
    b2:readTopics(1)
    check("the checklist is back once it measures again", #(checklists(b2)) == 1, where((checklists(b2))))
end

-- ---------------------------------------------------------------------------
section("a whole page with no full ad left: the smaller ads, then NOTES (QA, Nov 7 2026)")
-- ---------------------------------------------------------------------------
-- At Large text with pad wording the real book has more whole pages than full ads; the ones past them took NOTES
-- while halves and quarters went unused. Now such a page is a filler over its whole text block.
do
    local saved = A.full
    A.full = {}   -- (the house ad alone: every whole page past the first runs out)
    local b = newBook()
    b:readTopics(1)
    local whole, withAds, notesOnly, firstOk, inBlock = 0, 0, 0, true, true
    for _, p in ipairs(b.pages) do
        if p.kind == "ad" and p.ad == false then
            whole = whole + 1
            local ads = p.filler and p.filler.ads or {}
            if ads[1] and ads[1].k ~= "notes" then withAds = withAds + 1 end
            if #ads == 1 and ads[1].k == "notes" then notesOnly = notesOnly + 1 end
            -- (from the top of the text block: a half or pair first while they last)
            if ads[1] and math.abs(ads[1].y - U_.MT) > 0.001 then firstOk = false end
            for _, bl in ipairs(ads) do
                local hh = (bl.k == "half" or bl.k == "pair") and S.half[2] or (bl.k == "third" and S.third[2]) or 0
                if bl.y < U_.MT - 0.001 or bl.y + hh > p.filler.y1 + 0.001 or p.filler.y1 > U_.PH - U_.FOOT then inBlock = false end
            end
        end
    end
    check("the made-up book has whole pages past the full ads", whole >= 1, whole)
    check("each takes the smaller ads before NOTES", withAds == whole, withAds .. "/" .. whole)
    check("from the top of the text block", firstOk)
    check("inside the text block, over the foot", inBlock)
    local first = nil
    for _, p in ipairs(b.pages) do if p.kind == "ad" and p.ad == false and not first then first = p end end
    if first then
        local k = {}
        for _, bl in ipairs(first.filler.ads) do k[#k + 1] = bl.k end
        check("the first such page: a half or a pair, then a third", (k[1] == "half" or k[1] == "pair") and k[2] == "third", table.concat(k, ","))
        realPrint("  a whole page with no full ad left: " .. table.concat(k, ", "))
    end
    -- still no repeats, the house ad still a whole page of its own, in page order
    local nms = dealt(b)
    local seenN, dup = {}, nil
    for _, nm in ipairs(nms) do if seenN[nm] then dup = nm end; seenN[nm] = true end
    check("no repeats with whole pages taking the smaller ads", dup == nil, dup)
    local houses = 0
    for _, p in ipairs(b.pages) do if p.kind == "ad" and p.ad == "house" then houses = houses + 1; if p.filler then houses = 99 end end end
    check("the house ad as before: one whole page, no filler on it", houses == 1, houses)
    -- the whole pages dealt in page order with the fillers: a later page never holds an earlier ad of a size
    local d = B.adDeck(b._adSeed)
    local _, _, bl = dealt(b)
    local pos, okOrder, lastPos = {}, true, {}
    for _, kk in ipairs({ "half", "third", "quarter" }) do for j, nm in ipairs(d[kk]) do pos[nm] = j end end
    for _, x in ipairs(bl) do
        if not x.spoil then
            for _, nm in ipairs(x.names or {}) do
                local size = nm:match("^(%a+)_")
                if pos[nm] < (lastPos[size] or 0) then okOrder = false end
                lastPos[size] = pos[nm]
            end
        end
    end
    check("whole pages and fillers dealt together in page order", okOrder)
    -- with nothing smaller left either, the page is NOTES over the whole block, as before
    local sh, st_, sq = A.half, A.third, A.quarter
    A.half, A.third, A.quarter = {}, {}, {}
    local e = newBook()
    e:readTopics(1)
    local allNotes = true
    for _, p in ipairs(e.pages) do
        if p.kind == "ad" and p.ad == false then
            local ads = p.filler and p.filler.ads or {}
            if not (#ads == 1 and ads[1].k == "notes" and math.abs(ads[1].y - U_.MT) < 0.001) then allNotes = false end
        end
    end
    check("nothing left at all: NOTES over the whole text block", allNotes)
    A.half, A.third, A.quarter = sh, st_, sq
    A.full = saved
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
    check("whole pages past the house ad and the one full ad have no full ad", st.fullMiss == math.max(0, st.full - 2), st.full .. "/" .. st.fullMiss)
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
        if (p.kind == "rules" or p.kind == "ad") and p.filler then fills[#fills + 1] = p.filler end
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
-- (pad: the pad wording; lang: the game's language folder for its SurvivalGuide.json, English where it lacks a key;
-- TX: ZeD's words in that language, English where it lacks one)
local function realBook(pad, lang, TX)
    local SG = {}
    local order = {}
    local f = io.open(PZ .. "lua/shared/Translate/EN/SurvivalGuide.json", "r")
    if not f then return nil end
    for line in f:lines() do
        local k, v = line:match('^%s*"([^"]+)"%s*:%s*"(.*)"%s*,?%s*$')
        if k then SG[k] = v:gsub('\\"', '"'); order[#order + 1] = k end
    end
    f:close()
    if lang and lang ~= "EN" then
        local fl = io.open(PZ .. "lua/shared/Translate/" .. lang .. "/SurvivalGuide.json", "r")
        if fl then
            for line in fl:lines() do
                local k, v = line:match('^%s*"([^"]+)"%s*:%s*"(.*)"%s*,?%s*$')
                if k and SG[k] and v ~= "" then SG[k] = v:gsub('\\"', '"') end
            end
            fl:close()
        end
    end
    local EN = TX or EN
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
            local line = string.format("  %s text, %s: %d pages; whole pages %d (%d with no full ad left); 310 slots %d (%d with nothing left); 205 slots %d (%d with nothing left); NOTES blocks %d; dealt full %d/4, half %d/7, quarter %d/12, third %d/12",
                m[2], pd and "pad" or "keyboard", #b.pages, st.full, st.fullMiss, st.ask310, st.miss310, st.ask205, st.miss205, st.notes,
                st.at.full, st.at.half, st.at.quarter, st.at.third)
            local cs, cbad = checklists(b)
            line = line .. "; First Days checklist: " .. where(cs)
            realPrint(line)
            results[#results + 1] = st
            check("the real book (" .. m[2] .. ", " .. (pd and "pad" or "keyboard") .. "): the checklist prints once", #cs == 1, where(cs))
            check("the real book (" .. m[2] .. ", " .. (pd and "pad" or "keyboard") .. "): the checklist in place", #cbad == 0, cbad[1])
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

-- ---------------------------------------------------------------------------
-- THE HOUSE AD (QA, Nov 7 2026: its deck ran past the frame at Large text and in German at Small; its price touched
-- its box at Large). Laid out in every language at Small and Large text with the faces' own widths (the game's .fnt
-- files, by character; a character the faces lack is taken wide: Chinese, Japanese and Korean a full em and a bit,
-- Thai 0.7 em with its marks 0.15, anything else the face's widest), every line is measured again here and must sit
-- inside its part of the frame (the frame's padding, the titles' box, the price box less half the price's size each
-- side, the coupon's 10) and nothing may pass the frame's bottom; the coupon keeps its Name and Address.
-- English at Small text draws as it did before the fix (it fit then), and the old layout is run beside it to show
-- the sim sees what QA saw.
-- ---------------------------------------------------------------------------
section("the house ad: every language at Small and Large text, inside its frame")
local LANGS = { "AR", "CA", "CH", "CN", "CS", "DA", "DE", "EN", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT",
                "JP", "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
local AD1 = { "Head", "Deck", "Body", "T1", "T2", "T3", "T4", "T5", "Price", "Coupon", "Name", "Address" }
do
    -- (every language folder is on the list)
    local listed = {}
    for _, l in ipairs(LANGS) do listed[l] = true end
    local okLs, pipe = pcall(io.popen, 'dir /b /ad "' .. (ROOT ~= "" and ROOT or ".\\") .. '42\\media\\lua\\shared\\Translate"')
    if okLs and pipe then
        local extra = nil
        for d in pipe:lines() do if d:match("^%u[%u_]*$") and not listed[d] then extra = d end end
        pipe:close()
        check("every Translate folder is on the house ad's list", extra == nil, extra)
    end
end

-- UTF-8 into code points
local function cps(s)
    local out, i = {}, 1
    while i <= #s do
        local b = s:byte(i)
        local n = (b >= 0xF0 and 3) or (b >= 0xE0 and 2) or (b >= 0xC0 and 1) or 0
        local cp = (n == 0) and b or ((n == 1 and b - 0xC0) or (n == 2 and b - 0xE0) or (b - 0xF0))
        for k = 1, n do cp = cp * 64 + ((s:byte(i + k) or 0x80) - 0x80) end
        out[#out + 1] = cp
        i = i + n + 1
    end
    return out
end
local function utf8(cp)
    if cp < 0x80 then return string.char(cp) end
    if cp < 0x800 then return string.char(0xC0 + math.floor(cp / 64), 0x80 + cp % 64) end
    if cp < 0x10000 then return string.char(0xE0 + math.floor(cp / 4096), 0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64) end
    return string.char(0xF0 + math.floor(cp / 262144), 0x80 + math.floor(cp / 4096) % 64, 0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64)
end
local SIZE = { SdfRobertoSans = 48 }
local WIDEST = {}
for slot, t in pairs(ADV) do
    local mx = 16
    for id, a in pairs(t) do if id < 0x2000 and a > mx then mx = a end end
    WIDEST[slot] = mx
end
local function advOf(font, cp)
    local t, size = ADV[font] or {}, SIZE[font] or 32
    if t[cp] then return t[cp] end
    if cp >= 0x2E80 then return size * 1.05 end
    if cp >= 0x0E00 and cp <= 0x0E7F then
        if cp == 0x0E31 or (cp >= 0x0E34 and cp <= 0x0E3A) or (cp >= 0x0E47 and cp <= 0x0E4E) then return size * 0.15 end
        return size * 0.7
    end
    return WIDEST[font] or 32
end
local function measureCp(font, s)
    local w = 0
    for _, cp in ipairs(cps(s)) do w = w + advOf(font, cp) end
    return w
end
-- the sim's own width of a drawn line: the whole string, or its words and spaces as the book spaces them, the wider
local function simW(f, s, px)
    local size = SIZE[f.slot] or 32
    local sp = math.max(measureCp(f.slot, "a a") - measureCp(f.slot, "aa"), size * 0.25)
    local nat, n = 0, 0
    for wd in s:gmatch("%S+") do nat = nat + measureCp(f.slot, wd); n = n + 1 end
    nat = nat + math.max(0, n - 1) * sp
    return math.max(nat, measureCp(f.slot, s)) * px / size
end
-- capitals as the game's ZeD.upper makes them (Latin-1 and Latin Extended-A, Greek, Cyrillic; sharp s to SS)
local function upperU(s)
    local out = {}
    for _, cp in ipairs(cps(s)) do
        local u = cp
        if cp >= 97 and cp <= 122 then u = cp - 32
        elseif cp == 0xDF then out[#out + 1] = "SS"; u = nil
        elseif (cp >= 0xE0 and cp <= 0xFE and cp ~= 0xF7) then u = cp - 32
        elseif cp == 0xFF then u = 0x178
        elseif cp >= 0x100 and cp <= 0x17F and cp % 2 == 1 then u = cp - 1
        elseif cp >= 0x3B1 and cp <= 0x3C9 and cp ~= 0x3C2 then u = cp - 32
        elseif cp >= 0x430 and cp <= 0x44F then u = cp - 32
        elseif cp >= 0x450 and cp <= 0x45F then u = cp - 80 end
        if u then out[#out + 1] = utf8(u) end
    end
    return table.concat(out)
end

local LANG = {}
local function readLang(code)
    local t = {}
    if not readJson(ROOT .. "42/media/lua/shared/Translate/" .. code .. "/UI.json", t) then return nil end
    return t
end
local savedTr, savedUpper, savedTM = ZeD.tr, ZeD.upper, getTextManager
local cur = EN
ZeD.tr = function(k) return cur[k] or EN[k] or k end
ZeD.upper = upperU
getTextManager = function() return { MeasureStringX = function(_, font, s) return measureCp(font, tostring(s)) end } end

local PW, Ufix = 520, 1
-- every check of one layout; returns a list of what is wrong
local function faults(L, u)
    local bad = {}
    local function no(msg) bad[#bad + 1] = msg end
    local fr = L.frame
    local inTop, inBot = fr.y + fr.lw, fr.y + fr.h - fr.lw
    local ix, iw = U_.M * u + 14 * u, PW * u - U_.M * u * 2 - 28 * u
    if math.abs(L.inner.x - ix) > 0.01 or math.abs(L.inner.w - iw) > 0.01 then no("the inner width is not the frame's less its 14 each side") end
    local last = { t = -1 }
    for _, o in ipairs(L.ops) do
        local bottom = (o.k == "t") and (o.y + o.px * 0.3) or (o.y + o.h)
        local topY = (o.k == "t") and (o.y - o.px * 0.8) or o.y
        if bottom > inBot + 0.01 and not (o.k == "b" and o.y < inTop) then no("past the frame's bottom: " .. tostring(o.s or o.k)) end
        if topY < fr.y - 0.01 then no("above the frame: " .. tostring(o.s or o.k)) end
        if o.k == "t" then
            local w = simW(o.f, o.s, o.px)
            if o.w + 0.01 < w then no("the layout measured narrower than the sim: " .. o.s) end
            local x0, x1
            if o.box == "inner" then x0, x1 = ix, ix + iw
            elseif o.box == "list" then x0, x1 = L.list.x + L.list.pad, L.list.x + L.list.w - L.list.pad
            elseif o.box == "price" then x0, x1 = L.price.x + L.price.pad, L.price.x + L.price.w - L.price.pad
            elseif o.box == "coupon" then x0, x1 = L.coupon.x + L.coupon.pad, L.coupon.x + L.coupon.w - L.coupon.pad end
            if not x0 or o.x < x0 - 0.01 or o.x + w > x1 + 0.01 then
                no(string.format("%s past its %s: %.1f..%.1f in %.1f..%.1f", o.s, tostring(o.box), o.x, o.x + w, x0 or -1, x1 or -1))
            end
            local box = (o.box == "list" and L.list) or (o.box == "price" and L.price) or (o.box == "coupon" and L.coupon) or nil
            if box and (o.y - o.px * 0.75 < box.y - 0.01 or o.y + o.px * 0.25 > box.y + box.h + 0.01) then no("outside its box, up or down: " .. o.s) end
        end
    end
    if L.list.x < ix - 0.01 or L.list.x + L.list.w + 10 * u > L.price.x + 0.01 then no("the titles' box runs into the price") end
    if L.price.x + L.price.w > ix + iw + 0.01 then no("the price box past the frame's padding") end
    for _, o in ipairs(L.ops) do
        if o.k == "t" and o.box == "price" and L.price.pad < o.px * 0.5 - 0.01 then no("the price's padding under half its size") end
        if o.k == "r" and o.role == "write" and o.w < 40 * u - 0.01 then no(string.format("a writing line %.1f wide, under 40", o.w)) end
    end
    if not L.coupon then no("no coupon")
    elseif L.lines ~= 2 then no("the coupon lost its Name or Address") end
    return bad
end
local F_ = { head = { slot = "SdfRobertoSans" }, sansB = { slot = "SdfBold" }, text = { slot = "SdfOldRegular" }, textB = { slot = "SdfOldBold" } }

local summary = {}
local worst = {}
for _, code in ipairs(LANGS) do
    local t = readLang(code)
    check("the house ad's words in " .. code, t ~= nil)
    if t then
        local missing = nil
        for _, k in ipairs(AD1) do if not t["UI_ZeD_Guide_Ad1_" .. k] then missing = k end end
        check(code .. " has every UI_ZeD_Guide_Ad1_ key", missing == nil, missing)
        cur = t
        LANG[code] = t
        local row = { code }
        for _, m in ipairs({ { 1, "Small" }, { 1.15, "Large" } }) do
            setText(m[1])
            local okL, L = pcall(B.houseAdLayout, PW, Ufix)
            check(code .. " " .. m[2] .. ": the house ad lays out", okL, L)
            if okL then
                -- (HOUSEAD_DUMP=DE in the environment lists DE's layouts, line by line)
                if os.getenv("HOUSEAD_DUMP") == code then
                    realPrint(string.format("  %s %s (gaps %.2f, inner %.1f..%.1f, price box %.1f wide at %.1f, pad %.1f):", code, m[2], L.g, L.inner.x, L.inner.x + L.inner.w, L.price.w, L.price.x, L.price.pad))
                    for _, o in ipairs(L.ops) do
                        if o.k == "t" then realPrint(string.format("    %-6s x %6.1f..%6.1f  y %6.1f  %5.2f px  %s", o.box, o.x, o.x + o.w, o.y, o.px, o.s)) end
                    end
                end
                local bad = faults(L, Ufix)
                check(code .. " " .. m[2] .. ": every line inside the frame, nothing past its bottom", #bad == 0, bad[1])
                local deckN = 0
                for _, o in ipairs(L.ops) do if o.k == "t" and o.f.slot == "SdfBold" and o.box == "inner" then deckN = deckN + 1 end end
                local down = {}
                for _, k in ipairs({ "deck", "items", "coupon", "body", "head" }) do
                    if L.sz[k] < ({ deck = 14, items = 12.5, coupon = 11, body = 12.5, head = 30 })[k] * m[1] * Ufix - 0.001 then down[#down + 1] = k end
                end
                if L.headPx < 30 * m[1] * Ufix - 0.001 and L.sz.head >= 30 * m[1] * Ufix - 0.001 then down[#down + 1] = "head (a word)" end
                row[#row + 1] = string.format("%s deck %d line%s%s%s", m[2], deckN, deckN == 1 and "" or "s",
                    (L.g < 1) and string.format(", gaps %d%%", L.g * 100) or "", (#down > 0) and (", down: " .. table.concat(down, "+")) or "")
                if L.g < 1 or #down > 0 then worst[#worst + 1] = code .. " " .. m[2] end
            end
        end
        summary[#summary + 1] = "  " .. table.concat(row, "; ")
    end
end
cur = EN
setText(1)
for _, l in ipairs(summary) do realPrint(l) end
realPrint("  (closed up or a size down: " .. ((#worst > 0) and table.concat(worst, ", ") or "none") .. ")")

-- ---------------------------------------------------------------------------
-- the old layout (the drawAdPage of Nov 6), run in the same model: what QA saw, and English at Small as it was
-- ---------------------------------------------------------------------------
local function oldAd(u, m)
    local ops = {}
    local function tw(f, s, px) return measureCp(f.slot, s) * px / (SIZE[f.slot] or 32) end
    local function spw(f, px) local size = SIZE[f.slot] or 32; return math.max(measureCp(f.slot, "a a") - measureCp(f.slot, "aa"), size * 0.25) * px / size end
    local function wrap(s, f, px, lim)
        local lines, curL, cw = {}, nil, 0
        local sp = spw(f, px)
        for wd in s:gmatch("%S+") do
            local ww = tw(f, wd, px)
            if curL and cw + sp + ww > lim then lines[#lines + 1] = curL; curL, cw = nil, 0 end
            if curL then curL, cw = curL .. " " .. wd, cw + sp + ww else curL, cw = wd, ww end
        end
        if curL then lines[#lines + 1] = curL end
        return lines
    end
    local TEXT, DECK, OPEN, CAP, LEAD = 12.5 * m, 14 * m, 30 * m, 10 * m, 1.42
    local function T(k) return cur["UI_ZeD_Guide_Ad1_" .. k] or EN["UI_ZeD_Guide_Ad1_" .. k] end
    local function add(o) ops[#ops + 1] = o end
    local function centre(f, s, cx, y, px, box) local w = tw(f, s, px); add({ k = "t", s = s, x = cx - w / 2, y = y, px = px, w = w, f = f, box = box }) end
    local w = PW * u
    local mm = U_.M * u
    local tx, tw_ = mm, w - mm * 2
    local cx = w / 2
    local top, bot = U_.MT * u, (U_.PH - U_.FOOT - 6) * u
    local ix, iw = tx + 14 * u, tw_ - 28 * u
    local yy = top + 16 * u + OPEN * u
    centre(F_.head, upperU(T("Head")), cx, yy, OPEN * u, "inner")
    yy = yy + DECK * u * 1.6
    centre(F_.sansB, T("Deck"), cx, yy, DECK * u, "inner")
    yy = yy + TEXT * u * 0.8
    add({ k = "r", x = ix, y = yy, w = iw, h = math.max(1, u) })
    local px = TEXT * u
    local lineH = px * LEAD
    for _, l in ipairs(wrap(T("Body"), F_.text, px, iw)) do yy = yy + lineH; add({ k = "t", s = l, x = ix, y = yy, px = px, f = F_.text, box = "inner" }) end
    yy = yy + lineH * 0.8
    local boxY = yy
    local priceW = 92 * u
    local listW = iw - priceW - 10 * u
    local sq = math.floor(px * 0.8)
    for i = 1, 5 do
        yy = yy + lineH * 1.15
        add({ k = "b", x = ix + 8 * u, y = yy - sq, w = sq, h = sq })
        add({ k = "t", s = T("T" .. i), x = ix + 8 * u + sq + 8 * u, y = yy, px = px, f = F_.textB, box = "list" })
    end
    yy = yy + lineH * 0.6
    add({ k = "b", x = ix, y = boxY, w = listW, h = yy - boxY })
    local pY, pH = boxY + 10 * u, 70 * u
    add({ k = "r", x = ix + iw - priceW, y = pY, w = priceW, h = pH })
    local pc = ix + iw - priceW / 2
    local pw = {}
    for wd in T("Price"):gmatch("%S+") do pw[#pw + 1] = wd end
    local half = math.ceil(#pw / 2)
    centre(F_.sansB, upperU(table.concat(pw, " ", 1, half)), pc, pY + pH * 0.42, DECK * u, "price")
    if #pw > half then centre(F_.sansB, upperU(table.concat(pw, " ", half + 1)), pc, pY + pH * 0.78, DECK * u, "price") end
    yy = yy + 16 * u
    local cY = yy
    local cH = bot - 14 * u - cY
    if cH > 60 * u then
        local dash, gapD = 6 * u, 4 * u
        local xx = ix
        while xx < ix + iw do
            local dw = math.min(dash, ix + iw - xx)
            add({ k = "r", x = xx, y = cY, w = dw, h = math.max(1, u) })
            add({ k = "r", x = xx, y = cY + cH, w = dw, h = math.max(1, u) })
            xx = xx + dash + gapD
        end
        local yy2 = cY
        while yy2 < cY + cH do
            local dh = math.min(dash, cY + cH - yy2)
            add({ k = "r", x = ix, y = yy2, w = math.max(1, u), h = dh })
            add({ k = "r", x = ix + iw, y = yy2, w = math.max(1, u), h = dh })
            yy2 = yy2 + dash + gapD
        end
        local cy2 = cY + 6 * u
        local cpx = CAP * u * 1.1
        for _, l in ipairs(wrap(T("Coupon"), F_.text, cpx, iw - 20 * u)) do cy2 = cy2 + cpx * 1.35; add({ k = "t", s = l, x = ix + 10 * u, y = cy2, px = cpx, f = F_.text, box = "coupon" }) end
        for _, k in ipairs({ "Name", "Address" }) do
            cy2 = cy2 + cpx * 2.2
            if cy2 > cY + cH - 4 * u then break end
            local lab = T(k)
            add({ k = "t", s = lab, x = ix + 10 * u, y = cy2, px = cpx, f = F_.sansB, box = "coupon" })
            local lx = ix + 10 * u + tw(F_.sansB, lab, cpx) + 8 * u
            add({ k = "r", x = lx, y = cy2 + 2 * u, w = ix + iw - 10 * u - lx, h = math.max(1, u) })
        end
    end
    return ops, { ix = ix, iw = iw, priceX = ix + iw - priceW, priceW = priceW }
end
-- the widest the old layout drew a line past its frame's padding (or its price past the box), in px
local function oldOver(code, m)
    cur = LANG[code] or EN
    local ops, g = oldAd(1, m)
    local over = { deck = 0, price = 9999 }
    for _, o in ipairs(ops) do
        if o.k == "t" and o.f == F_.sansB and o.box == "inner" then
            local w = simW(o.f, o.s, o.px)
            over.deck = math.max(g.ix - o.x, o.x + w - (g.ix + g.iw))
        end
        if o.k == "t" and o.box == "price" then
            local w = simW(o.f, o.s, o.px)
            over.price = math.min(over.price, o.x - g.priceX, g.priceX + g.priceW - (o.x + w))
        end
    end
    cur = EN
    return over
end
do
    local enS, enL, deS = oldOver("EN", 1), oldOver("EN", 1.15), oldOver("DE", 1)
    check("the old layout: English at Small fit (its deck inside the padding)", enS.deck <= 0, enS.deck)
    check("the old layout: English at Large ran its deck past the padding, as QA saw", enL.deck > 14, enL.deck)
    check("the old layout: German at Small ran its deck past the padding, as QA saw", deS.deck > 14, deS.deck)
    check("the old layout: English at Large left the price under 2 px clear, as QA saw", enL.price < 2, enL.price)
    realPrint(string.format("  old layout: EN Small deck %.1f px inside, price %.1f px clear; EN Large deck %.1f px over, price %.1f clear; DE Small deck %.1f px over",
        -enS.deck, enS.price, enL.deck, enL.price, deS.deck))
    local oldBad = {}
    for _, code in ipairs(LANGS) do
        for _, m in ipairs({ 1, 1.15 }) do if oldOver(code, m).deck > 0 then oldBad[#oldBad + 1] = code .. (m == 1 and " S" or " L") end end
    end
    realPrint("  old layout, deck past the padding: " .. table.concat(oldBad, ", "))

    -- English at Small: the new layout draws what the old one drew, the same draws (in another order: the price box
    -- now before the titles), every rule and box to the thousandth, every line at its place (a centered line may move
    -- under a pixel: it now centers on its words and spaces as the pages space them, when that is the wider)
    setText(1)
    local L = B.houseAdLayout(PW, 1)
    local old = oldAd(1, 1)
    local missing, moved = nil, 0
    for _, o in ipairs(old) do
        local hit = false
        for j = L.frame.lw + 1, #L.ops do
            local n = L.ops[j]
            if n.k == o.k and (o.s == nil or n.s == o.s) and math.abs(n.x - o.x) <= ((o.k == "t") and 1 or 0.001) and math.abs(n.y - o.y) <= 0.001
               and (o.k == "t" or (math.abs(n.w - o.w) <= 0.001 and math.abs(n.h - o.h) <= 0.001)) then
                hit = true
                moved = math.max(moved, math.abs(n.x - o.x))
                break
            end
        end
        if not hit then missing = string.format("%s %s at %.2f,%.2f", o.k, tostring(o.s), o.x, o.y) end
    end
    check("English at Small draws as before the fix", missing == nil and #L.ops == #old + L.frame.lw, missing or (#L.ops .. " / " .. (#old + L.frame.lw)))
    check("English at Small: nothing closed up or a size down", L.g == 1 and L.sz.deck == 14 and L.sz.items == 12.5)
    realPrint(string.format("  English at Small against the old layout: the same %d draws, the most a line moved %.2f px", #old, moved))
end

-- ---------------------------------------------------------------------------
-- words too long for any line: cut between characters, nothing lost, Thai at a syllable's edge; a page of words
-- far too long closes its gaps, steps parts down and still keeps inside the frame; a headline word too wide takes
-- the headline a size down; long Name and Address wrap; a page flooded past the frame leaves a box out whole
-- ---------------------------------------------------------------------------
do
    setText(1.15)
    local long = {}
    for k, v in pairs(LANG.JP) do long[k] = v end
    long.UI_ZeD_Guide_Ad1_Deck = string.rep(LANG.JP.UI_ZeD_Guide_Ad1_Deck, 3)
    cur = long
    local L = B.houseAdLayout(PW, 1)
    local deck = {}
    for _, o in ipairs(L.ops) do if o.k == "t" and o.f.slot == "SdfBold" and o.box == "inner" then deck[#deck + 1] = o.s end end
    check("a Japanese deck three times over wraps to lines", #deck >= 3, #deck)
    check("cut between characters, nothing lost", table.concat(deck) == long.UI_ZeD_Guide_Ad1_Deck)
    local bad = faults(L, 1)
    check("a long Japanese deck keeps inside the frame", #bad == 0, bad[1])
    -- Thai: no line starts on a mark, a vowel that follows its consonant, the repeat or abbreviation mark; none ends
    -- on a vowel written before its consonant; a cut inside a word falls where a syllable surely starts or ends
    -- (before a leading vowel, after sara a or sara am, or beside a letter that is not Thai)
    local function thNoStart(c) return c and ((c >= 0x0E2F and c <= 0x0E3A) or (c >= 0x0E45 and c <= 0x0E4E)) end
    local function thLead(c) return c and c >= 0x0E40 and c <= 0x0E44 end
    local function thai(c) return c and c >= 0x0E00 and c <= 0x0E7F end
    local thSrc = {}
    for k, v in pairs(LANG.TH) do if k:find("^UI_ZeD_Guide_Ad1_") then thSrc[#thSrc + 1] = v end end
    local onMark, onLead, badCut, cuts = nil, nil, nil, 0
    for _, m in ipairs({ 1, 1.15, 1.6 }) do
        setText(m)
        local ops = {}
        cur = LANG.TH
        for _, o in ipairs(B.houseAdLayout(PW, 1).ops) do if o.k == "t" then ops[#ops + 1] = o end end
        for i, o in ipairs(ops) do
            local c = cps(o.s)
            if thNoStart(c[1]) then onMark = o.s end
            if thLead(c[#c]) then onLead = o.s end
            local n = ops[i + 1]
            if n and n.box == o.box and n.f == o.f then
                -- (a cut inside a word: the two lines' ends meet with no space in the source)
                local joined = o.s .. n.s
                for _, src in ipairs(thSrc) do
                    if src:find(joined, 1, true) then
                        cuts = cuts + 1
                        local a, b = c[#c], cps(n.s)[1]
                        if thai(a) and thai(b) and not (thLead(b) or a == 0x0E30 or a == 0x0E33) then badCut = o.s .. " / " .. n.s end
                        break
                    end
                end
            end
        end
    end
    check("no Thai line starts on a mark or a following vowel", onMark == nil, onMark)
    check("no Thai line ends on a leading vowel", onLead == nil, onLead)
    check("Thai cut inside words (at 1.6 at least)", cuts > 0, cuts)
    check("every Thai cut inside a word falls at a syllable's edge", badCut == nil, badCut)
    realPrint(string.format("  Thai: %d cuts inside a word at Small, Large and 1.6, each at a syllable's edge", cuts))
    cur = LANG.TH
    -- far too many words: the gaps close, the parts that wrapped step down, nothing past the frame
    local huge = {}
    for k, v in pairs(LANG.DE) do huge[k] = v end
    huge.UI_ZeD_Guide_Ad1_Deck = string.rep(LANG.DE.UI_ZeD_Guide_Ad1_Deck .. " ", 4)
    huge.UI_ZeD_Guide_Ad1_Body = string.rep(LANG.DE.UI_ZeD_Guide_Ad1_Body .. " ", 2)
    for i = 1, 5 do huge["UI_ZeD_Guide_Ad1_T" .. i] = LANG.DE["UI_ZeD_Guide_Ad1_T" .. i] .. " " .. LANG.DE.UI_ZeD_Guide_Ad1_T1 end
    cur = huge
    setText(1.15)
    local H = B.houseAdLayout(PW, 1)
    check("too many words: the gaps close up", H.g < 1, H.g)
    check("too many words: the deck a size down", H.sz.deck < 14 * 1.15 - 0.001, H.sz.deck)
    local inBot = H.frame.y + H.frame.h - H.frame.lw
    local past = nil
    for i, o in ipairs(H.ops) do
        local b = (o.k == "t") and (o.y + o.px * 0.3) or (o.y + o.h)
        if i > H.frame.lw and b > inBot + 0.01 then past = o.s or o.k end
    end
    check("too many words: nothing past the frame's bottom", past == nil, past)
    -- a price too long for two lines in the box: a size down
    local dear = {}
    for k, v in pairs(LANG.EN) do dear[k] = v end
    dear.UI_ZeD_Guide_Ad1_Price = "Only $4.95 each or three for $12.95 postage paid anywhere in Kentucky"
    cur = dear
    setText(1)
    local D = B.houseAdLayout(PW, 1)
    local pls = {}
    for _, o in ipairs(D.ops) do if o.k == "t" and o.box == "price" then pls[#pls + 1] = o end end
    check("a long price a size down", pls[1] and pls[1].px < 14 - 0.001, pls[1] and pls[1].px)
    local badD = faults(D, 1)
    check("a long price keeps inside its box", #badD == 0, badD[1])

    -- a headline word too wide for the frame, in a language that spaces its words: the headline a size down (22 at
    -- Small), the word whole; a Chinese or Japanese headline too long for a line wraps at its own size instead
    local wideHead = {}
    for k, v in pairs(LANG.EN) do wideHead[k] = v end
    wideHead.UI_ZeD_Guide_Ad1_Head = "The Uberlebenshandbuchregal"
    cur = wideHead
    setText(1)
    local WH = B.houseAdLayout(PW, 1)
    local whole, headN = false, 0
    for _, o in ipairs(WH.ops) do
        if o.k == "t" and o.f.slot == "SdfRobertoSans" then
            headN = headN + 1
            if o.s:find("UBERLEBENSHANDBUCHREGAL", 1, true) then whole = true end
        end
    end
    check("a headline word too wide at 30 is wider than the frame (the test is real)", simW(F_.head, "UBERLEBENSHANDBUCHREGAL", 30) > WH.inner.w, simW(F_.head, "UBERLEBENSHANDBUCHREGAL", 30))
    check("a headline word too wide: the headline a size down", math.abs(WH.headPx - 22) < 0.001, WH.headPx)
    check("a headline word too wide: the word kept whole", whole, headN)
    local badWH = faults(WH, 1)
    check("a headline word too wide keeps inside the frame", #badWH == 0, badWH[1])
    local jpHead = {}
    for k, v in pairs(LANG.JP) do jpHead[k] = v end
    jpHead.UI_ZeD_Guide_Ad1_Head = string.rep(LANG.JP.UI_ZeD_Guide_Ad1_Head, 3)
    cur = jpHead
    local JH = B.houseAdLayout(PW, 1)
    local jpN = 0
    for _, o in ipairs(JH.ops) do if o.k == "t" and o.f.slot == "SdfRobertoSans" then jpN = jpN + 1 end end
    check("a long Japanese headline wraps at its own size", math.abs(JH.headPx - 30) < 0.001 and jpN > 1, JH.headPx .. " / " .. jpN)
    local badJH = faults(JH, 1)
    check("a long Japanese headline keeps inside the frame", #badJH == 0, badJH[1])

    -- Name and Address wider than the coupon: wrapped, a writing line of at least 40 after each, both kept
    local longLab = {}
    for k, v in pairs(LANG.DE) do longLab[k] = v end
    longLab.UI_ZeD_Guide_Ad1_Name = "Vor- und Nachname des Empfaengers, wie er auf dem Briefkasten steht"
    longLab.UI_ZeD_Guide_Ad1_Address = "Vollstaendige Anschrift mit Strasse, Hausnummer, Postleitzahl und Ort, bitte in Druckbuchstaben"
    cur = longLab
    for _, m in ipairs({ 1, 1.15 }) do
        setText(m)
        local LL = B.houseAdLayout(PW, 1)
        local labN = 0
        for _, o in ipairs(LL.ops) do if o.k == "t" and o.f.slot == "SdfBold" and o.box == "coupon" then labN = labN + 1 end end
        check("long Name and Address wrap (" .. m .. ")", labN > 2, labN)
        local badLL = faults(LL, 1)
        check("long Name and Address keep inside the coupon, both with a writing line (" .. m .. ")", #badLL == 0, badLL[1])
    end

    -- words so many the smallest try still runs past the frame: what is left out goes with its box, never a box
    -- without its words or words without their box
    local flood = {}
    for k, v in pairs(LANG.DE) do flood[k] = v end
    flood.UI_ZeD_Guide_Ad1_Body = string.rep(LANG.DE.UI_ZeD_Guide_Ad1_Body .. " ", 6)
    for i = 1, 5 do flood["UI_ZeD_Guide_Ad1_T" .. i] = string.rep(LANG.DE["UI_ZeD_Guide_Ad1_T" .. i] .. " ", 3) end
    cur = flood
    setText(1.15)
    local FL = B.houseAdLayout(PW, 1)
    local dropped = {}
    for k in pairs(FL.dropped or {}) do dropped[#dropped + 1] = k end
    table.sort(dropped)
    check("flooded: the last try runs past the frame (the test is real)", #dropped > 0)
    local has = { priceBox = false, priceText = false, listBox = false, listText = false, tick = false }
    for _, o in ipairs(FL.ops) do
        if o.k == "r" and math.abs(o.x - FL.price.x) < 0.001 and math.abs(o.w - FL.price.w) < 0.001 then has.priceBox = true end
        if o.k == "t" and o.box == "price" then has.priceText = true end
        if o.k == "b" and math.abs(o.x - FL.list.x) < 0.001 and math.abs(o.w - FL.list.w) < 0.001 then has.listBox = true end
        if o.k == "b" and o.w < 20 then has.tick = true end
        if o.k == "t" and o.box == "list" then has.listText = true end
    end
    check("flooded: the price box and its words together", has.priceBox == has.priceText)
    check("flooded: the titles' box, its tick boxes and its titles together", has.listBox == has.listText and has.tick == has.listText)
    local inBotF = FL.frame.y + FL.frame.h - FL.frame.lw
    local pastF = nil
    for i, o in ipairs(FL.ops) do
        local b = (o.k == "t") and (o.y + o.px * 0.3) or (o.y + o.h)
        if i > FL.frame.lw and b > inBotF + 0.01 then pastF = o.s or o.k end
    end
    check("flooded: nothing past the frame's bottom", pastF == nil, pastF)
    realPrint("  flooded (German, six times the paragraph, three times the titles, Large): left out " .. table.concat(dropped, ", ")
        .. string.format("; price %s, titles %s", has.priceText and "kept" or "left out", has.listText and "kept" or "left out"))
    cur = EN
    setText(1)
end

-- ---------------------------------------------------------------------------
-- the layout kept: laid out once while nothing changes; again for a new text size, language or measure epoch
-- ---------------------------------------------------------------------------
do
    local epoch = 1
    ZeD.Text = { measureEpoch = function() return epoch end }
    local bk2 = newBook()
    setText(1)
    local a = bk2:houseAd(PW, 1)
    check("kept: the same layout the next frame", bk2:houseAd(PW, 1) == a)
    setText(1.15)
    local b = bk2:houseAd(PW, 1)
    check("kept: a new text size lays it out again", b ~= a)
    cur = LANG.DE
    local c = bk2:houseAd(PW, 1)
    check("kept: a new language lays it out again", c ~= b)
    epoch = 2
    local d = bk2:houseAd(PW, 1)
    check("kept: a new measure epoch lays it out again", d ~= c)
    check("kept: a new unit lays it out again", bk2:houseAd(PW, 1.75) ~= d)
    epoch = nil
    local e1 = bk2:houseAd(PW, 1)
    check("kept: no epoch (the fonts loading), laid out each frame", bk2:houseAd(PW, 1) ~= e1)
    ZeD.Text = nil
    -- drawn: one draw per item of the list, at the page's corner
    local rec = {}
    local P = setmetatable({}, { __index = function(_, k)
        if k == "drawTextZoomed" then return function(_, s, x, y) rec[#rec + 1] = { k = "t", s = s, x = x } end end
        if k == "drawRect" then return function(_, x, y) rec[#rec + 1] = { k = "r", x = x } end end
        if k == "drawRectBorder" then return function(_, x, y) rec[#rec + 1] = { k = "b", x = x } end end
        if ZeD_GuideBook[k] then return ZeD_GuideBook[k] end
        if k:find("^get") then return function() return 0 end end
        return nil
    end })
    setText(1)
    cur = EN
    P:drawAdPage(700, 40, PW, 1)
    local L = P._houseAd and P._houseAd.L
    local ok = L and #rec == #L.ops
    if ok then for i, o in ipairs(L.ops) do if rec[i].k ~= o.k or math.abs(rec[i].x - (700 + o.x)) > 0.001 then ok = false end end end
    check("drawn: the kept list, at the page's corner", ok, #rec)
end

-- ---------------------------------------------------------------------------
-- THE FIRST DAYS CHECKLIST IN EVERY LANGUAGE: the real book (the game's SurvivalGuide.json in that language, ZeD's
-- UI.json in that language, English where either lacks a key; the faces' widths as the house ad's, by character)
-- at Small and Large text, keyboard and pad: the checklist prints once, in its chapter, in place.
-- ---------------------------------------------------------------------------
section("the First Days checklist in every language: once, at Small and Large, keyboard and pad")
do
    local bad, n, how = {}, 0, { filler = 0, flow = 0 }
    local maxH, maxAt = 0, ""
    for _, code in ipairs(LANGS) do
        local L = LANG[code] or readLang(code)
        if L then
            cur = L
            local TX = setmetatable({}, { __index = function(_, k) return L[k] or EN[k] end })
            for _, m in ipairs({ 1, 1.15 }) do
                for _, pd in ipairs({ false, true }) do
                    local secs = realBook(pd, code, TX)
                    if secs then
                        SECTIONS = secs
                        onPad = pd
                        setText(m)
                        local b = newBook()
                        b:readTopics(1)
                        n = n + 1
                        local cs, cbad = checklists(b)
                        local tag = string.format("%s %s %s", code, m == 1 and "Small" or "Large", pd and "pad" or "keyboard")
                        if #cs ~= 1 then bad[#bad + 1] = tag .. ": " .. where(cs) end
                        if cbad[1] then bad[#bad + 1] = tag .. ": " .. cbad[1] end
                        if cs[1] then how[cs[1].how] = how[cs[1].how] + 1 end
                        if cs[1] and cs[1].h > maxH then maxH, maxAt = cs[1].h, tag end
                    end
                end
            end
        end
    end
    cur = EN
    onPad = false
    setText(1)
    check("the checklist prints once and in place in every language (" .. n .. " books)", #bad == 0 and n > 0, bad[1] or n)
    realPrint(string.format("  %d books: in a filler %d, its own block %d; the tallest checklist %.0f (%s), the page's text %d",
        n, how.filler, how.flow, maxH, maxAt, U_.PH - U_.FOOT - U_.MT * 2))
end

ZeD.tr, ZeD.upper, getTextManager = savedTr, savedUpper, savedTM
setText(1)

realPrint(string.format("guide_ads_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
