-- ZeDUI/tools/qa/guide_contents_sim.lua  (Nov 7 2026, Build): the survival guide book's contents over as many pages
-- as it needs, with no game running. The director, Nov 7 2026: "2-3 pages, however many pages it needs. I'm sure
-- it'll expand." The real ZeD_SurvivalGuideBook.lua runs on Lua 5.1 stubs of the game (as guide_ads_sim.lua).
-- The real book is built in every language the sim can load (the game's SurvivalGuide.json for the game's sections
-- and topics, ZeD's UI.json for the blurbs and ZeD's chapters), measured with the faces' own widths (the game's .fnt
-- files; a character the faces lack is taken wide, as guide_ads_sim.lua's house ad), at Small and Large text, in the
-- keyboard's and the pad's wording, with its 20 sections and with 30 and 45 (sections a mod could add, one with no
-- topics). Each layout must have:
--   no row past the body text's bottom, no row split over two pages, rows in order without overlapping;
--   every section with a page once, in order, and none without a page;
--   each row's page number the page its chapter really starts on (printed = index + 1), that page the chapter's own;
--   a blurb wider than its room wrapped (every line inside the room before the page number), a title inside the
--   text block, a later page's heading with "continued", inside the text block;
--   the introduction on a right-hand page, facing the last contents page (or after one left-hand page);
--   that left-hand page, when there is one, the publisher's house ad (the director, Nov 7 2026) and no text page (no
--   chapter, topic or row on it, no section for the thumbs); the house ad once in the book either way (a book with
--   no front page deals it among the whole pages, as before, when they reach its place in the deck); every other ad
--   dealt as it was with that page blank (the whole pages the same order with the house ad left out, every filler the same);
--   the strip's Contents button, Home and the pad's Y on the first contents page;
--   drawn: every word above the bottom, the number clear of the blurb, and a click on each row opening its chapter;
--   page 1 the copyright page (punch list 103): its block in the body face at U.CAP, every word of its keys, inside
--   the text block's sides, bottom-aligned to the text foot and never past it, under the top margin, no folio; the
--   title page's division with its LLC; and every other page as it is laid out with page 1 blank (the book before).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/guide_contents_sim.lua   (CONTENTS_DUMP=<code> lists a language's rows)
-- It prints FAIL lines and a last line "guide_contents_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]guide_contents_sim%.lua$", "")
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
-- the faces' advance widths from the game's .fnt files (atlas px)
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

UIFont = setmetatable({}, { __index = function(_, k) return k end })   -- (a face is its slot's name here)
getTextManager = function() return { MeasureStringX = function(_, font, s) return measureCp(font, tostring(s)) end } end
require = function() return nil end
ISPanelJoypad = { derive = function(_, name) local c = { Type = name }; c.__index = c; return c end }
isDebugEnabled = function() return false end
getCore = function() return { getOptionDoVideoEffects = function() return false end } end
getTexture = function() return nil end
Texture = { getSharedTexture = function(path) return { path = path } end }
getWorld = function() return { getWorld = function() return "Sim Save" end } end
getSpecificPlayer = function()
    return { getDescriptor = function() return { getForename = function() return "Kate" end, getSurname = function() return "Bowman" end } end }
end
Keyboard = { KEY_ESCAPE = 1, KEY_LEFT = 203, KEY_RIGHT = 205, KEY_PRIOR = 201, KEY_NEXT = 209, KEY_HOME = 199 }
Joypad = { AButton = 0, BButton = 1, XButton = 2, YButton = 3, LBumper = 4, RBumper = 5 }

local function readJson(path, into, order)
    local f = io.open(path, "r")
    if not f then return false end
    for line in f:lines() do
        local k, v = line:match('^%s*"([^"]+)"%s*:%s*"(.*)"%s*,?%s*$')
        if k then
            into[k] = (v:gsub('\\"', '"'):gsub("\\n", "\n"):gsub("\\\\", "\\"))
            if order then order[#order + 1] = k end
        end
    end
    f:close()
    return true
end
local EN = {}
readJson(ROOT .. "42/media/lua/shared/Translate/EN/UI.json", EN)
local cur = EN

local logs = {}
ZeD = {
    tr = function(k, ...)
        local s = cur[k] or EN[k] or k
        local a = { ... }
        for i = 1, 4 do if a[i] ~= nil then local v = tostring(a[i]); s = s:gsub("%%" .. i, function() return v end) end end
        return s
    end,
    upper = upperU,
    logOnce = function(k, e) logs[#logs + 1] = tostring(k) .. ": " .. tostring(e) end,
    T = { scale = 1, root = 1 },
}
local onPad = false
local SECTIONS = {}
ZeD.Guide = {
    MARK = "\1",
    inlineTex = function(path) return { key = path } end,
    inlineW = function(_, s) return s * 1.6 end,
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

-- (the book as it was before its copyright page, page 1 blank: its own copy of the file with that one page changed,
-- loaded first under its own tables, so each layout can be laid out both ways and compared page for page)
local BLANK_BOOK, BLANK_B = nil, nil
do
    local f = io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_SurvivalGuideBook.lua", "rb")
    local src = f and f:read("*a") or ""
    if f then f:close() end
    local patched, n = src:gsub('{ kind = "copyright" }, { kind = "title" }', '{ kind = "blank" }, { kind = "title" }')
    local chunk = (n == 1) and loadstring(patched, "=ZeD_SurvivalGuideBook (page 1 blank)") or nil
    if chunk then
        chunk()
        BLANK_BOOK, BLANK_B = ZeD_GuideBook, ZeD.GuideBook
    end
    ZeD.GuideBook, ZeD_GuideBook = nil, nil
end

dofile(ROOT .. "42/media/lua/client/ZeD/ZeD_SurvivalGuideBook.lua")
local B = ZeD.GuideBook
check("the book with page 1 blank loads beside it (the copyright page's control)", BLANK_BOOK ~= nil and BLANK_B ~= B and BLANK_BOOK ~= ZeD_GuideBook)
check("the book file loads and lays out its contents", B and B.paginate and B.contentsLayout and ZeD_GuideBook and ZeD_GuideBook.drawContentsPage)
check("the faces' widths come from the game's .fnt files", realFonts)

local U_ = { PW = 520, PH = 690, M = 40, MT = 30, FOOT = 26 }   -- (the book's page in design units, as U)
local function setText(m) ZeD.T.scale = m; B.applyType() end
local function newBook() return setmetatable({ playerNum = 0, _clips = {} }, ZeD_GuideBook) end

-- ---------------------------------------------------------------------------
-- THE REAL BOOK in a language: the game's sections and topics (its SurvivalGuide.json in that language, English
-- where a key is missing), ZeD's chapters and blurbs (ZeD's UI.json); modeled rules tables (as guide_ads_sim.lua)
-- ---------------------------------------------------------------------------
local ROWS = {
    SurvivalGuide_skill_books_title = { { 5, 4, 8 }, { 10, 4, 6 }, { 30, 3, 40 }, { 97, 3, 40 } },
    SurvivalGuide_eating_drinking_title = { { 25, 4, 6 } },
    SurvivalGuide_sow_seeds_title = { { 55, 4, 6 } },
    SurvivalGuide_treat_water_title = { { 3, 2, 12 } },
    SurvivalGuide_zombie_attacks_title = { { 3, 2, 12 } },
}
local SPOILER = { SurvivalGuide_treat_water_title = true, SurvivalGuide_zombie_attacks_title = true }
local GAME_EN, GAME_ORDER = {}, {}
local haveGame = readJson(PZ .. "lua/shared/Translate/EN/SurvivalGuide.json", GAME_EN, GAME_ORDER)
ZeD.GuideChapters = nil
pcall(dofile, ROOT .. "42/media/lua/client/ZeD/ZeD_GuideChapters.lua")
local CHAPTERS = ZeD.GuideChapters or {}

local function realBook(code, pad)
    local SG = {}
    if code ~= "EN" then readJson(PZ .. "lua/shared/Translate/" .. code .. "/SurvivalGuide.json", SG) end
    local function g(k) return SG[k] or GAME_EN[k] end
    local function L(k) return cur[k] or EN[k] or k end
    local secs, sec = {}, nil
    local function keyMarks(s) return (s:gsub("%%(%d)%$s", "\1key:K\1"):gsub("%%(%d)", "\1key:K\1")) end
    for _, k in ipairs(GAME_ORDER) do
        local stem = k:match("^SurvivalGuide_(.+)_title$")
        if stem then
            if GAME_EN["SurvivalGuide_" .. stem .. "_category_image"] then
                sec = { id = stem, title = g(k), titleKey = k, topics = {} }
                secs[#secs + 1] = sec
            elseif sec then
                local d = GAME_EN["SurvivalGuide_" .. stem .. "_description"] and g("SurvivalGuide_" .. stem .. "_description")
                if pad and GAME_EN["SurvivalGuide_" .. stem .. "_description_joypad"] then d = g("SurvivalGuide_" .. stem .. "_description_joypad") end
                if d and d ~= "<IGNORE>" then
                    local nKeys = 0
                    for _ in d:gmatch("%%%d") do nKeys = nKeys + 1 end
                    local t = { id = stem, section = sec, title = g(k), titleKey = k, text = keyMarks(d), video = "media/videos/" .. stem .. ".bk2" }
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
                            t._rules[ri] = { title = "Table " .. ri, cols = cols, rows = rr, notes = { "A note on the numbers.", "Another note." }, spoiler = SPOILER[k] }
                        end
                    end
                    sec.topics[#sec.topics + 1] = t
                end
            end
        end
    end
    for _, ch in ipairs(CHAPTERS) do
        local s = { id = "zedch:" .. ch.id, title = L(ch.title), titleKey = ch.title, blurbKey = ch.blurb, topics = {}, zed = true }
        secs[#secs + 1] = s
        for _, td in ipairs(ch.topics or {}) do
            local function fill(x) return (tostring(x or ""):gsub("{(%a+:[^}]+)}", "\1key:K\1")) end
            local t = { id = s.id .. ":" .. td.id, section = s, title = L(td.title), titleKey = td.title, text = fill(L(td.text)) }
            local ways = {}
            for _, r in ipairs(td.ways or {}) do ways[#ways + 1] = { kbText = fill(L(r[1])), padText = fill(L(r[2])) } end
            for _ in ipairs(td.waysFrom or {}) do ways[#ways + 1] = { label = "Action", kb = { { key = "K" } }, pad = { { key = "A" } } } end
            if td.keys then for i = 1, 60 do ways[#ways + 1] = { label = "Binding " .. i, kb = { { key = "K" } }, pad = {} } end end
            if #ways > 0 then t._ways = ways end
            s.topics[#s.topics + 1] = t
        end
    end
    return secs
end

-- the book with n sections: the real ones, then sections a mod could add (each a copy of a real one under its own
-- id, its title numbered, one or two short topics; every third with no blurb of its own; the eighth with no topics)
local function withSections(real, n)
    local out = {}
    for i = 1, math.min(n, #real) do out[i] = real[i] end
    local k = 0
    while #out < n do
        k = k + 1
        local src = real[(k - 1) % #real + 1]
        local s = { id = "mod" .. k, title = src.title .. " " .. k, titleKey = (k % 3 == 0) and ("Mod_" .. k .. "_title") or src.titleKey,
                    blurbKey = (k % 3 ~= 0) and src.blurbKey or nil, topics = {} }
        if k ~= 8 then
            for ti = 1, math.min(1 + (k % 2), #src.topics) do
                local t0 = src.topics[ti]
                s.topics[ti] = { id = "mod" .. k .. ":" .. ti, section = s, title = t0.title, titleKey = "Mod_" .. k .. "_" .. ti, text = t0.text, video = t0.video }
            end
        end
        out[#out + 1] = s
    end
    return out
end

-- ---------------------------------------------------------------------------
-- THE CHECKS of one laid-out book (u 1): returns the faults found and a line on the contents' pages
-- ---------------------------------------------------------------------------
local LANGS = { "AR", "CA", "CH", "CN", "CS", "DA", "DE", "EN", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT",
                "JP", "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
local function spreadOf(i) return math.floor((i + 1) / 2) end

-- the deal of a page list: the whole pages' ads in page order (the front page left out) and a signature of every
-- filler's ads
local function dealOf(P)
    local full, fill = {}, {}
    for i, p in ipairs(P) do
        if p.kind == "ad" and not p.front then full[#full + 1] = tostring(p.ad) end
        local fs = {}
        if p.kind == "flow" then for _, it in ipairs(p.items) do if it.k == "filler" then fs[#fs + 1] = it end end end
        if p.kind == "rules" and p.filler then fs[#fs + 1] = p.filler end
        for _, f in ipairs(fs) do
            for _, b in ipairs(f.ads or {}) do fill[#fill + 1] = i .. ":" .. b.k .. "=" .. table.concat(b.names or {}, "+") end
        end
    end
    return full, table.concat(fill, " ")
end

-- THE HOUSE AD UP FRONT (the director, Nov 7 2026): the page before the introduction, when the contents takes an
-- even count, is the house ad and no text page; the house ad once in the book; every other ad as it was dealt with
-- that page blank (the deal before Nov 7)
local function houseFaults(bk, u, no)
    local P, n = bk.pages, bk.contentsPages or 0
    local fp = (n % 2 == 0) and P[3 + n] or nil
    if fp and not (fp.kind == "ad" and fp.front and fp.ad == "house") then no("the page before the introduction is not the house ad") end
    local fronts, houses = 0, 0
    for i, p in ipairs(P) do
        if p.front then
            fronts = fronts + 1
            if p ~= fp then no("a front house ad page at " .. i .. ", not before the introduction") end
        end
        if p.kind == "ad" and p.ad == "house" then houses = houses + 1 end
        for _, b in ipairs((p.kind == "rules" and p.filler and p.filler.ads) or {}) do
            for _, nm in ipairs(b.names or {}) do if nm == "house" then houses = houses + 1 end end
        end
    end
    if fronts ~= (fp and 1 or 0) then no("front house ad pages: " .. fronts) end
    if fp then
        local at = 3 + n
        if fp.si or fp.section or fp.items then no("the house ad page has a section or text") end
        for k, i in pairs(bk.sectionPage) do if i == at then no("chapter " .. tostring(k) .. " starts on the house ad page") end end
        for k, i in pairs(bk.pageOf) do if i == at then no("topic " .. tostring(k) .. " is on the house ad page") end end
    end
    -- once: up front, or (no front page) dealt among the whole pages when they reach its place in the deck
    local deck = B.adDeck(bk._adSeed or 1)
    local place = 99
    for j, v in ipairs(deck.full) do if v == "house" then place = j end end
    local wantH = (fp or place <= ((bk.adStats and bk.adStats.full) or 0)) and 1 or 0
    if houses ~= wantH then no(string.format("the house ad %d times in the book (%d wanted)", houses, wantH)) end
    if not fp then return end
    -- the rest as dealt with that page blank: the fillers the same, the whole pages the same order less the house ad
    local textW_ = (U_.PW - U_.M * 2) * u
    local full, fill = dealOf(P)
    local today = {}
    for i, p in ipairs(P) do today[i] = (p == fp) and { kind = "blank" } or p end
    local okT = pcall(B.dealAds, bk, today, u, textW_)
    local wasFull, wasFill = dealOf(today)
    pcall(B.dealAds, bk, P, u, textW_)   -- (the book's own deal back)
    local reFull, reFill = dealOf(P)
    if not okT then no("the deal with that page blank fails") end
    if table.concat(reFull, ",") ~= table.concat(full, ",") or reFill ~= fill then no("dealing again changes the deal") end
    -- (unless a whole page ran past the full ads: it then takes the smaller ads, Nov 7 2026, and with the house ad
    -- back in the deck that page would have had a full ad, so the smaller ads after it move on by design)
    local ranOut = false
    for _, v in ipairs(full) do if v == "false" then ranOut = true end end
    if wasFill ~= fill and not ranOut then no("a filler's ads differ from the deal with that page blank") end
    local less = {}
    for _, v in ipairs(wasFull) do if v ~= "house" then less[#less + 1] = v end end
    local same = #full == #wasFull
    for i, v in ipairs(less) do if full[i] ~= v then same = false end end
    -- (and from there on, the deck less the house ad, then NOTES)
    local rest = B.adDeck(bk._adSeed or 1, true).full
    for i = 1, #full do if full[i] ~= tostring(rest[i] or false) then same = false end end
    if not same then no("the whole pages are not the old order less the house ad: " .. table.concat(full, ",") .. " / " .. table.concat(wasFull, ",")) end
end

local function faults(bk, u, m)
    local bad = {}
    local function no(msg) if #bad < 6 then bad[#bad + 1] = msg end end
    local P = bk.pages
    local cu = u * m
    local tw = (U_.PW - U_.M * 2) * u
    local bottom = (U_.PH - U_.FOOT - U_.MT) * u
    local top = (U_.MT + 28 + 18) * u
    local n = bk.contentsPages or 0
    -- the front matter
    if not (P[1] and P[1].kind == "copyright" and P[2] and P[2].kind == "title") then no("the copyright page and the title page do not lead") end
    if bk.contentsPage ~= 3 then no("the first contents page is not page 3: " .. tostring(bk.contentsPage)) end
    if n < 1 then no("no contents page") end
    for i = 3, 2 + n do
        local p = P[i]
        if not (p and p.kind == "contents" and p.part == i - 2) then no("page " .. i .. " is not contents part " .. (i - 2)) end
    end
    if P[3 + n] and P[3 + n].kind == "contents" then no("a contents page past the count") end
    local ip = bk.introPage
    if not (ip and P[ip] and P[ip].kind == "intro") then no("no introduction at introPage " .. tostring(ip))
    else
        if ip % 2 ~= 0 then no("the introduction on a left-hand page (" .. ip .. ")") end
        if n % 2 == 1 and ip ~= 3 + n then no("the introduction does not face the last contents page") end
        if n % 2 == 0 and not (ip == 4 + n and P[3 + n].kind == "ad" and P[3 + n].front) then no("an even contents count without its one left-hand page") end
    end
    if #P % 2 ~= 0 then no("an odd page count") end
    houseFaults(bk, u, no)
    -- the rows
    local rows = {}
    for i = 3, 2 + n do
        local p = P[i]
        if p and p.kind == "contents" then
            local hw = measureCp("SdfRobertoSans", p.head) * p.headPx / 48
            if hw > tw + 0.01 then no(string.format("page %d's heading %.1f wide in %.1f", i, hw, tw)) end
            local cont = upperU(ZeD.tr("UI_ZeD_Guide_BookContinued"))
            if (p.part > 1) ~= (p.head:find(cont, 1, true) ~= nil) then no("page " .. i .. "'s heading and \"continued\" disagree: " .. p.head) end
            local prevEnd = top - 0.001
            if #p.rows == 0 and #bk.sections > 0 then no("contents page " .. i .. " has no rows") end
            for _, r in ipairs(p.rows) do
                r._on = i
                rows[#rows + 1] = r
                if r.y < prevEnd - 0.001 then no(string.format("page %d: row %d overlaps the row before", i, r.si)) end
                if r.y + r.h > bottom + 0.001 then no(string.format("page %d: row %d ends at %.1f, past the text bottom %.1f", i, r.si, r.y + r.h, bottom)) end
                -- (no row split: a row's lines all in its own box, on one page)
                local lastBase = r.y + 13 * cu + (#r.titles - 1 + #r.blurbs) * 12 * cu
                if lastBase + 4 * cu > r.y + r.h + 0.001 then no("row " .. r.si .. "'s lines run past its box") end
                prevEnd = r.y + r.h
                -- the words: the title inside the text block, each blurb line inside the room before the number
                local pw = measureCp("SdfBold", r.num) * 10 * cu / 32
                local room = tw - 24 * cu - pw - 16 * u
                for _, l in ipairs(r.titles) do
                    if measureCp("SdfBold", l.s) * 10 * cu / 32 > tw - 24 * cu + 0.01 then no("row " .. r.si .. "'s title past the text block: " .. l.s) end
                end
                for _, l in ipairs(r.blurbs) do
                    local w = math.max(l.w, measureCp("SdfRegular", l.s) * 9.5 * cu / 32)
                    if w > room + 0.01 then no(string.format("row %d's blurb line %.1f wide in %.1f: %s", r.si, w, room, l.s)) end
                end
                -- the number: the page the chapter starts on, as printed
                local s = bk.sections[r.si]
                if not s or s.id ~= r.sid then no("row " .. r.si .. " is not its section") end
                if r.page ~= bk.sectionPage[r.sid] then no("row " .. r.si .. "'s page is not its chapter's") end
                if r.num ~= tostring((r.page or -99) + 1) then no(string.format("row %d prints %s for page index %s", r.si, tostring(r.num), tostring(r.page))) end
                local cp = r.page and P[r.page]
                if not (cp and cp.kind == "flow" and cp.si == r.si and cp.items[1] and cp.items[1].k == "label") then no("row " .. r.si .. "'s page is not its chapter's opener") end
            end
        end
    end
    -- every section with a page once, in order; none without
    local want = {}
    for si, s in ipairs(bk.sections) do if bk.sectionPage[s.id] then want[#want + 1] = si end end
    local got = {}
    for _, r in ipairs(rows) do got[#got + 1] = r.si end
    if table.concat(want, ",") ~= table.concat(got, ",") then no("the rows " .. table.concat(got, ",") .. " are not the sections " .. table.concat(want, ",")) end
    -- every page index the book keeps is a real page of the right kind
    for _, s in ipairs(bk.sections) do
        for _, t in ipairs(s.topics) do
            local i = bk.pageOf[t.id]
            if not (i and P[i] and (P[i].kind == "flow")) then no("topic " .. t.id .. "'s page " .. tostring(i) .. " is not a flow page") end
        end
    end
    return bad, rows
end

-- the contents spreads drawn on a recording book: every word's baseline, the numbers and the leaders; then a click
-- on each row; then the Contents button, Home and the pad's Y
local function drawCheck(bk, u, m)
    local bad = {}
    local function no(msg) if #bad < 6 then bad[#bad + 1] = msg end end
    local cu = u * m
    local W, X0, Y0 = U_.PW * u, 100, 50
    local bottom = Y0 + (U_.PH - U_.FOOT - U_.MT) * u
    local texts = {}
    bk.drawTextZoomed = function(_, s, x, y, z, r, g, b, a, font)
        local f = ({ SdfRobertoSans = 56, SdfRegular = 35, SdfBold = 35, SdfItalic = 35 })[font] or 25
        texts[#texts + 1] = { s = s, x = x, base = y + f * z, z = z, font = font }
    end
    bk.drawRect, bk.drawRectBorder, bk.drawTextureScaled, bk.drawTextureScaledAspect = noop, noop, noop, noop
    bk.getMouseX, bk.getMouseY, bk.getAbsoluteX, bk.getAbsoluteY = function() return -1 end, function() return -1 end, function() return 0 end, function() return 0 end
    bk._g = { left = { x = X0, y = Y0, w = W, h = U_.PH * u }, right = { x = X0 + W, y = Y0, w = W, h = U_.PH * u } }
    local first, last = spreadOf(bk.contentsPage), spreadOf(bk.introPage)
    local clicked, okClicks = 0, 0
    for sp = first, last do
        bk.spread = sp
        bk._contentsRows = {}
        local li = sp * 2 - 1
        local all = {}
        for side = 0, 1 do
            texts = {}
            bk:drawPage(li + side, X0 + side * W, Y0, W, u, { x = -1, y = -1 })
            -- (the contents pages' words only: the introduction's are not this sim's)
            local p = bk.pages[li + side]
            for _, t in ipairs(texts) do
                all[#all + 1] = t
                -- (the folio is the foot's, under the text bottom by design)
                local folio = t.base > Y0 + (U_.PH - 20) * u
                if p and p.kind == "contents" and not folio and t.base > bottom + 0.01 then
                    no(string.format("page %d: \"%s\" drawn at %.1f, past the text bottom %.1f", li + side, t.s, t.base, bottom))
                end
            end
        end
        texts = all
        -- each row's number: right-aligned, clear of its blurb's last line by the leader's room
        for _, r in ipairs(bk._contentsRows) do
            local p = bk.pages[r.onPage]
            local row
            for _, rr in ipairs(p.rows) do if rr.si == r.si then row = rr end end
            local x = (r.onPage % 2 == 1) and X0 or (X0 + W)
            local tx = x + U_.M * u
            local numT
            for _, t in ipairs(texts) do if t.s == row.num and math.abs(t.base - (Y0 + row.y + 13 * cu + (#row.titles - 1 + #row.blurbs) * 12 * cu)) < 0.01 then numT = t end end
            if not numT then no("row " .. r.si .. "'s number not drawn on its last line")
            else
                local blurbEnd = tx + 24 * cu + row.blurbs[#row.blurbs].w
                if numT.x < blurbEnd + 8 * u - 0.01 then no(string.format("row %d's number at %.1f runs into its blurb (ends %.1f)", r.si, numT.x, blurbEnd)) end
            end
        end
        -- a click on each row opens its chapter's spread
        for _, r in ipairs(bk._contentsRows) do
            bk.spread = sp
            clicked = clicked + 1
            bk:onMouseDown(r.x + 10 * u, r.y + r.h / 2)
            if bk.spread == spreadOf(r.page) then okClicks = okClicks + 1 else no("a click on row " .. r.si .. " opened spread " .. bk.spread .. ", not " .. spreadOf(r.page)) end
        end
        bk.spread = sp
    end
    local nRows = 0
    for i = 3, 2 + bk.contentsPages do nRows = nRows + #bk.pages[i].rows end
    if clicked ~= nRows then no("clicked " .. clicked .. " rows of " .. nRows) end
    -- the Contents button, Home and Y: the first contents page
    local function onFirst() local i = bk.spread * 2 - 1; return bk.pages[i] and bk.pages[i].kind == "contents" and bk.pages[i].part == 1 end
    bk.spread = spreadOf(bk.introPage) + 3
    bk:press("toc")
    if not onFirst() then no("Contents opens spread " .. bk.spread) end
    bk.spread = 9
    bk:onKeyPress(Keyboard.KEY_HOME)
    if not onFirst() then no("Home opens spread " .. bk.spread) end
    bk.spread = 9
    bk:onJoypadDown(Joypad.YButton)
    if not onFirst() then no("Y opens spread " .. bk.spread) end
    return bad
end

-- ---------------------------------------------------------------------------
-- THE COPYRIGHT PAGE (punch list 103, docs/handoffs/HANDOFF_design_guide_copyright_20261107.md): page 1, drawn on a
-- recording book. Its block in the body face at U.CAP (times the text size), every line inside the text block's
-- sides (measured with the face's own widths), the block bottom-aligned to the text block's foot (its last line's
-- descender, the face's deepest of g, j, p, q and y from its .fnt, never past the foot; the book's own quarter-size
-- descender on it) and its top under the top margin; the lines in order, never closer than their lead; every word of
-- the keys drawn, in order, nothing else; no folio. The title page beside it names the division with its " LLC".
-- ---------------------------------------------------------------------------
local OLD_DESC = 0    -- (the face's descender in atlas px, from SdfOldRegular.fnt: below the baseline)
do
    local f = io.open(PZ .. "fonts/SdfOldRegular.fnt", "r")
    if f then
        local base, padB = 25, 0
        for line in f:lines() do
            local pb = line:match("padding=%d+,%d+,(%d+),%d+")
            if pb then padB = tonumber(pb) end
            local b = line:match("^common .-base=(%d+)")
            if b then base = tonumber(b) end
            local id = line:match("^char id=(%d+)")
            if id and ({ [103] = true, [106] = true, [112] = true, [113] = true, [121] = true })[tonumber(id)] then
                local h, yo = tonumber(line:match("height=(%d+)")), tonumber(line:match("yoffset=(%-?%d+)"))
                OLD_DESC = math.max(OLD_DESC, yo + h - padB - base)
            end
        end
        f:close()
    end
end
local BOOK_DESC = 0.25   -- (the book's COPY_DESC)
local function squash(s) return (tostring(s):gsub("%s+", "")) end
local function copyrightCheck(bk, u, m)
    local bad = {}
    local function no(msg) if #bad < 6 then bad[#bad + 1] = msg end end
    local W, X0, Y0 = U_.PW * u, 100, 50
    local texts = {}
    bk.drawTextZoomed = function(_, s, x, y, z, r, g, b, a, font)
        local fb = ({ SdfRobertoSans = 56, SdfRegular = 35, SdfBold = 35, SdfItalic = 35 })[font] or 25
        texts[#texts + 1] = { s = s, x = x, base = y + fb * z, z = z, font = font }
    end
    bk.drawRect, bk.drawRectBorder, bk.drawTextureScaled, bk.drawTextureScaledAspect = noop, noop, noop, noop
    bk.getAbsoluteX, bk.getAbsoluteY = function() return 0 end, function() return 0 end
    bk:drawPage(1, X0, Y0, W, u)
    local px = 10 * m * u
    local tx0, tx1 = X0 + U_.M * u, X0 + W - U_.M * u
    local foot = Y0 + (U_.PH - U_.FOOT) * u
    local info = { lines = #texts, px = px }
    if #texts == 0 then no("nothing drawn on page 1"); return bad, info end
    local prev = nil
    for i, t in ipairs(texts) do
        if t.font ~= "SdfOldRegular" then no("line " .. i .. " in " .. tostring(t.font) .. ", not the body face: " .. t.s) end
        local tpx = t.z * 32
        if math.abs(tpx - px) > 0.001 then no(string.format("line %d at %.2f px, not U.CAP %.2f", i, tpx, px)) end
        local w = measureCp("SdfOldRegular", t.s) * t.z
        if t.x < tx0 - 0.01 then no(string.format("line %d starts at %.1f, left of the text block %.1f", i, t.x, tx0)) end
        if math.abs(t.x - tx0) > 0.01 then no(string.format("line %d not left aligned (%.1f, %.1f)", i, t.x, tx0)) end
        if t.x + w > tx1 + 0.01 then no(string.format("line %d ends at %.1f, past the text block %.1f: %s", i, t.x + w, tx1, t.s)) end
        if t.base > foot - OLD_DESC * t.z + 0.01 then no(string.format("line %d's descender at %.1f, past the foot %.1f", i, t.base + OLD_DESC * t.z, foot)) end
        if prev and t.base < prev.base + tpx * 1.2 - 0.01 then no(string.format("line %d %.1f under the line before (lead %.1f)", i, t.base - prev.base, tpx * 1.2)) end
        prev = t
    end
    local first, last = texts[1], texts[#texts]
    info.top, info.bottom = first.base - px - Y0, last.base + BOOK_DESC * px - Y0
    if math.abs(last.base + BOOK_DESC * px - foot) > 0.01 then no(string.format("the block's foot at %.2f, not on the text foot %.2f", last.base + BOOK_DESC * px, foot)) end
    if first.base - px < Y0 + U_.MT * u - 0.01 then no(string.format("the block's top at %.1f, over the top margin %.1f", first.base - px, Y0 + U_.MT * u)) end
    if last.s ~= "10 9 8 7 6 5 4 3 2 1" then no("the printing line is not last: " .. last.s) end
    -- every word, in order, nothing else (the wrap only adds line breaks)
    local want = ZeD.tr("UI_ZeD_Guide_BookTitle") .. ": " .. ZeD.tr("UI_ZeD_Guide_BookSub1") .. " " .. ZeD.tr("UI_ZeD_Guide_BookSub2")
        .. ZeD.tr("UI_ZeD_Guide_BookEdition") .. ZeD.tr("UI_ZeD_Guide_CopyBy")
    for k = 1, 5 do want = want .. ZeD.tr("UI_ZeD_Guide_Copy" .. k) end
    want = want .. "10 9 8 7 6 5 4 3 2 1"
    local got = {}
    for _, t in ipairs(texts) do got[#got + 1] = t.s end
    if squash(table.concat(got)) ~= squash(want) then no("the drawn words are not the keys' words") end
    for k = 1, 5 do
        if ZeD.tr("UI_ZeD_Guide_Copy" .. k) == "UI_ZeD_Guide_Copy" .. k then no("UI_ZeD_Guide_Copy" .. k .. " has no text") end
    end
    if not ZeD.tr("UI_ZeD_Guide_Copy1"):find("\194\169 1984, 1987", 1, true) then no("the copyright line lacks the (c) and both years") end
    -- no folio: nothing in the folio's face, nothing under the text foot
    for _, t in ipairs(texts) do
        if t.font == "SdfBold" or t.base > foot + 0.01 then no("a folio on the copyright page: " .. t.s) end
    end
    -- the title page: the division with its LLC
    texts = {}
    bk:drawPage(2, X0 + W, Y0, W, u)
    local div = ZeD.tr("UI_ZeD_Guide_BookDivision")
    local found = false
    for _, t in ipairs(texts) do if t.s == div then found = true end end
    if not found then no("the title page does not draw the division") end
    if not div:find(" LLC$") then no("the division has no LLC: " .. div) end
    return bad, info
end

-- the page list as a string, page by page (page 1 left out): every page's kind, chapter, part, ad and items with
-- their places and ads, every contents row with its number; the chapters' and topics' pages; the deal's count
local function pagesSig(bk)
    local out = {}
    local function r2(v) return v and string.format("%.3f", v) or "-" end
    for i = 2, #bk.pages do
        local p = bk.pages[i]
        local s = { i, p.kind, tostring(p.si), tostring(p.part), tostring(p.ad), tostring(p.front) }
        for _, it in ipairs(p.items or {}) do
            local a = {}
            for _, b in ipairs(it.ads or {}) do a[#a + 1] = b.k .. "=" .. table.concat(b.names or {}, "+") .. "@" .. r2(b.y) end
            s[#s + 1] = tostring(it.k) .. "@" .. r2(it.y) .. "/" .. r2(it.y1) .. "[" .. table.concat(a, ",") .. "]"
        end
        if p.filler then
            local a = {}
            for _, b in ipairs(p.filler.ads or {}) do a[#a + 1] = b.k .. "=" .. table.concat(b.names or {}, "+") .. "@" .. r2(b.y) end
            s[#s + 1] = "filler@" .. r2(p.filler.y) .. "[" .. table.concat(a, ",") .. "]"
        end
        for _, r in ipairs(p.rows or {}) do s[#s + 1] = "row" .. r.si .. "@" .. r2(r.y) .. "=" .. tostring(r.num) end
        out[#out + 1] = table.concat(s, " ")
    end
    local keys = {}
    for k, v in pairs(bk.sectionPage) do keys[#keys + 1] = "s:" .. tostring(k) .. "=" .. v end
    for k, v in pairs(bk.pageOf) do keys[#keys + 1] = "t:" .. tostring(k) .. "=" .. v end
    table.sort(keys)
    out[#out + 1] = table.concat(keys, " ")
    out[#out + 1] = string.format("n%d c%s/%s i%s", #bk.pages, tostring(bk.contentsPage), tostring(bk.contentsPages), tostring(bk.introPage))
    if bk.adStats then out[#out + 1] = B.adReport(bk) end
    return out
end
-- the same layout with page 1 blank (the book before the copyright page): nothing but page 1 differs
local function sameAsBlank(bk)
    if not BLANK_BOOK then return false, "no blank-page book" end
    BLANK_B.applyType()   -- (its own copy of the type sizes: at this layout's text size)
    local bb = setmetatable({ playerNum = 0, _clips = {} }, BLANK_BOOK)
    local ok, err = pcall(bb.readTopics, bb, bk._u or 1)
    if not ok then return false, "the blank-page book does not lay out: " .. tostring(err) end
    if not (bb.pages[1] and bb.pages[1].kind == "blank") then return false, "the control's page 1 is not blank" end
    local a, b = pagesSig(bk), pagesSig(bb)
    if #a ~= #b then return false, string.format("%d page lines against %d", #a, #b) end
    for i = 1, #a do
        if a[i] ~= b[i] then return false, "differs at line " .. i .. ": " .. a[i]:sub(1, 160) .. " / " .. b[i]:sub(1, 160) end
    end
    return true
end

-- ---------------------------------------------------------------------------
section("the old measure: EN at Small fits 18 rows a page, at Large 15 (one-line rows)")
-- ---------------------------------------------------------------------------
do
    cur = EN
    local secs = {}
    for i = 1, 40 do secs[i] = { id = "x" .. i, title = "Chapter", titleKey = "X_" .. i, topics = {} } end
    local bk = { sections = secs }
    for _, m in ipairs({ { 1, 18 }, { 1.15, 15 } }) do
        setText(m[1])
        local pages = B.contentsLayout(bk, 1, function() return "99" end)
        check(string.format("x%.2f: %d rows on the first page", m[1], m[2]), #pages[1].rows == m[2], #pages[1].rows)
        check(string.format("x%.2f: rows 31 px apart times the text size", m[1]), math.abs(pages[1].rows[2].y - pages[1].rows[1].y - 31 * m[1]) < 0.001)
        check(string.format("x%.2f: the list starts 76 from the page's top", m[1]), math.abs(pages[1].rows[1].y - 76) < 0.001)
    end
    setText(1)
    -- a section with no page gets no row; an empty book still has its one contents page
    local pages = B.contentsLayout(bk, 1, function(s) return (s.id ~= "x2") and "9" or nil end)
    local has2 = false
    for _, p in ipairs(pages) do for _, r in ipairs(p.rows) do if r.sid == "x2" then has2 = true end end end
    check("a section with no page gets no row", not has2)
    check("no sections: one contents page", #B.contentsLayout({ sections = {} }, 1, function() return "9" end) == 1)
end

-- ---------------------------------------------------------------------------
section("every language, Small and Large text, keyboard and pad, 20, 30 and 45 sections")
-- ---------------------------------------------------------------------------
local summary = {}
local fronts, books = 0, 0   -- (layouts with the house ad up front, of all laid out)
local copy = { n = 0, top = math.huge, at = "" }   -- (the copyright pages checked, and the tallest block's top)
do
    if not haveGame then print("  (no game files: the real books are skipped)") end
    local folders = {}
    local okLs, pipe = pcall(io.popen, 'dir /b /ad "' .. (ROOT ~= "" and ROOT or ".\\") .. '42\\media\\lua\\shared\\Translate"')
    if okLs and pipe then
        local listed = {}
        for _, l in ipairs(LANGS) do listed[l] = true end
        local extra = nil
        for d in pipe:lines() do if d:match("^%u[%u_]*$") and not listed[d] then extra = d end end
        pipe:close()
        check("every Translate folder is on the list", extra == nil, extra)
    end
    for _, code in ipairs(haveGame and LANGS or {}) do
        local t = {}
        local okL = readJson(ROOT .. "42/media/lua/shared/Translate/" .. code .. "/UI.json", t)
        check("ZeD's words in " .. code, okL)
        cur = okL and t or EN
        local line = { code }
        for _, pd in ipairs({ false, true }) do
            onPad = pd
            local real = realBook(code, pd)
            for _, m in ipairs({ { 1, "Small" }, { 1.15, "Large" } }) do
                setText(m[1])
                for _, n in ipairs({ 20, 30, 45 }) do
                    SECTIONS = withSections(real, n)
                    local nLogs = #logs
                    local bk = newBook()
                    local ok, err = pcall(bk.readTopics, bk, 1)
                    local name = string.format("%s %s %s %d sections", code, m[2], pd and "pad" or "keyboard", n)
                    check(name .. ": lays out", ok and #logs == nLogs, err or logs[#logs])
                    if ok then
                        local bad, rows = faults(bk, 1, m[1])
                        books = books + 1
                        if bk.pages[3 + bk.contentsPages] and bk.pages[3 + bk.contentsPages].front then fronts = fronts + 1 end
                        check(name .. ": the contents", #bad == 0, table.concat(bad, "; "))
                        local okD, bad2 = pcall(drawCheck, bk, 1, m[1])
                        check(name .. ": drawn and clicked", okD and #bad2 == 0, okD and table.concat(bad2, "; ") or bad2)
                        local okC, bad3, ci = pcall(copyrightCheck, bk, 1, m[1])
                        check(name .. ": the copyright page", okC and #bad3 == 0, okC and table.concat(bad3, "; ") or bad3)
                        if okC and ci.top then
                            copy.n = copy.n + 1
                            if ci.top < copy.top then copy.top, copy.at = ci.top, string.format("%s %s %s, %d lines", code, m[2], pd and "pad" or "keyboard", ci.lines) end
                        end
                        local okS, why = sameAsBlank(bk)
                        check(name .. ": nothing but page 1 differs from the book with page 1 blank", okS, why)
                        local per, wraps = {}, 0
                        for i = 3, 2 + bk.contentsPages do per[#per + 1] = #bk.pages[i].rows end
                        for _, r in ipairs(rows) do if #r.blurbs > 1 or #r.titles > 1 then wraps = wraps + 1 end end
                        if not pd then line[#line + 1] = string.format("%s %d: %s%s", m[2], n, table.concat(per, "+"), wraps > 0 and string.format(" (%d wrap)", wraps) or "") end
                        if os.getenv("CONTENTS_DUMP") == code and n == 20 and not pd then
                            print(string.format("  %s %s: %d contents pages, intro page %d, %d pages", code, m[2], bk.contentsPages, bk.introPage, #bk.pages))
                            for _, r in ipairs(rows) do
                                local bl = {}
                                for _, l in ipairs(r.blurbs) do bl[#bl + 1] = l.s end
                                print(string.format("    p%d y %6.1f h %5.1f  %2d. %s | %s .... %s", r._on, r.y, r.h, r.si, r.titles[1].s, table.concat(bl, " / "), r.num))
                            end
                        end
                    end
                end
            end
        end
        summary[#summary + 1] = "  " .. table.concat(line, "; ")
    end
    onPad = false
    cur = EN
    setText(1)
end
if books > 0 then
    print(string.format("-- the house ad up front in %d of %d layouts (the rest: an odd contents count, the house ad dealt as before)", fronts, books))
    check("both front matters among the layouts (with and without the house ad up front)", fronts > 0 and fronts < books, fronts .. "/" .. books)
end
if copy.n > 0 then
    print(string.format("-- the copyright page in %d layouts: the tallest block's top %.1f from the page's top (%s; the top margin %d, the foot %d)",
        copy.n, copy.top, copy.at, U_.MT, U_.PH - U_.FOOT))
end
print("-- rows on each contents page, keyboard (wrap = rows that took a second line)")
for _, l in ipairs(summary) do print(l) end

print(string.format("guide_contents_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
