-- ZeDUI/tools/qa/guide_lang_sim.lua  (Nov 11 2026, Build; punch list 154)
-- Which survival guide a game's language gets: the book, or the plain window where the book's faces can't draw the
-- language (Chinese, Japanese, Korean, Thai). AR is the game's Argentine Spanish, not Arabic: it gets the book (it was
-- on the window's list by that misreading, so Argentine players got the window). With no game running, the list and
-- W.useBook cut from the real ZeD_SurvivalGuide.lua, on stubs.
-- KINSOKU (from zedqa_kinsoku.lua, Nov 12 2026): the window's wrapRuns, cut from the same file, on Japanese and
-- Chinese paragraphs at many widths: no laid-out line starts with a closing mark, the long-vowel mark or a small kana,
-- none ends with an opening mark (by code point). Kahlua strings are UTF-16, one Lua character a letter; under Lua 5.1
-- each letter is one private byte here, read back as its code point by the chunk's own string.byte.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/guide_lang_sim.lua
-- It prints FAIL lines and a last line "guide_lang_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]guide_lang_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end

local f = io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_SurvivalGuide.lua", "rb"); local src = f:read("*a"):gsub("\r\n", "\n"); f:close()   -- (the file may have CRLF line ends)
local a = src:find("local NO_BOOK_LANGS", 1, true)
local b = a and src:find("\nend\n", src:find("function W.useBook()", a, true), true)
check("the language list and useBook are found in ZeD_SurvivalGuide.lua", a and b)
if not (a and b) then print("guide_lang_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end
local W = {}
local LANG = "EN"
ZeD = { GuideBook = { open = function() end }, Settings = { guideSimple = function() return false end } }
Translator = { getLanguage = function() return { name = function() return LANG end } end }
assert(loadstring("local W = ...\n" .. src:sub(a, b + 4)))(W)
for _, L in ipairs({ "EN", "ES", "AR", "PTBR", "RU", "UA", "PL", "DE" }) do
    LANG = L
    check(L .. " gets the book" .. (L == "AR" and " (Argentine Spanish)" or ""), W.useBook() == true)
end
for _, L in ipairs({ "CN", "CH", "JP", "KO", "TH" }) do
    LANG = L
    check(L .. " gets the window (the book's faces can't draw it)", W.useBook() == false)
end
LANG = "AR"
ZeD.Settings.guideSimple = function() return true end
check("Simple set: the window, whatever the language", W.useBook() == false)
-- (from zedqa_guide_ads.lua: the Simple look has no ads) the window deals and draws none
check("the window (the Simple look) has no ads", not src:find("GuideAds", 1, true) and not src:find("dealAds", 1, true)
    and not src:find("guide/ads/", 1, true))

-- KINSOKU: the real wrapRuns on Japanese and Chinese paragraphs
do
    local ka = src:find("\nlocal NO_START, NO_END", 1, true)
    local END = "\n    return lines\nend\n"
    local kb = ka and src:find(END, ka, true)
    check("NO_START, NO_END and wrapRuns are found in ZeD_SurvivalGuide.lua", ka and kb)
    if ka and kb then
        local NOS = { 0x3001, 0x3002, 0xFF0C, 0xFF0E, 0xFF01, 0xFF1F, 0xFF1A, 0xFF1B, 0x300D, 0x300F, 0xFF09, 0x3015,
            0x3011, 0x3009, 0x300B, 0x30FC, 0x30FB, 0x3005, 0x3041, 0x3043, 0x3045, 0x3047, 0x3049, 0x3063, 0x3083,
            0x3085, 0x3087, 0x308E, 0x30A1, 0x30A3, 0x30A5, 0x30A7, 0x30A9, 0x30C3, 0x30E3, 0x30E5, 0x30E7, 0x30EE,
            0x30F5, 0x30F6 }   -- (zedqa_kinsoku.lua's lists, written again here so a change to the mod's shows)
        local NOE = { 0x300C, 0x300E, 0xFF08, 0x3014, 0x3010, 0x3008, 0x300A }
        local LET = { 0x65E5, 0x672C, 0x8A9E, 0x6C34, 0x98DF, 0x3042, 0x304B, 0x30AB, 0x30B5, 0x4E2D, 0x6587 }
        local cp, byteOf, isNoS, isNoE = {}, {}, {}, {}
        local nb = 0x80
        local function add(c) if not byteOf[c] then byteOf[c] = string.char(nb); cp[nb] = c; nb = nb + 1 end end
        for _, c in ipairs(NOS) do add(c); isNoS[c] = true end
        for _, c in ipairs(NOE) do add(c); isNoE[c] = true end
        for _, c in ipairs(LET) do add(c) end
        local S = setmetatable({ byte = function(s, i) local c = string.byte(s, i); return c and (cp[c] or c) end }, { __index = string })
        local env = setmetatable({ string = S, ZeD = { TM = {
                getFontHeight = function() return 20 end,
                MeasureStringX = function(_, _, s) return #s * 16 end },   -- (a CJK face: every letter the same width)
            T = { px = function(n) return n end } } }, { __index = _G })
        local head = table.concat({
            "local MARK = string.char(1)",
            "local function fh(f) return ZeD.TM:getFontHeight(f) end",
            "local function tw(f, s) return ZeD.TM:MeasureStringX(f, s) end",
            "local function twFull(f, s) return tw(f, s .. 'x') - tw(f, 'x') end",
            "local function twFit(f, s) return math.max(tw(f, s), twFull(f, s)) end",
            "local function inlineTex() return nil end",
            "local function inlineW() return 0 end", "" }, "\n")
        local chunk = assert(loadstring(head .. src:sub(ka + 1, kb + #END - 1) .. "return wrapRuns\n"))
        setfenv(chunk, env)
        local wrapRuns = chunk()
        -- paragraphs: letters with the marks where Japanese and Chinese put them (closing marks after a letter, in
        -- runs; small kana and the long-vowel mark after a letter; opening marks before one)
        local seed = 12345
        local function rnd(n) seed = (seed * 1103515245 + 12345) % 2147483648; return seed % n + 1 end
        local function para(len)
            local t = {}
            while #t < len do
                local r = rnd(10)
                if r <= 5 then t[#t + 1] = byteOf[LET[rnd(#LET)]]
                elseif r <= 8 then
                    t[#t + 1] = byteOf[LET[rnd(#LET)]]
                    for _ = 1, rnd(3) do t[#t + 1] = byteOf[NOS[rnd(#NOS)]] end
                else
                    for _ = 1, rnd(2) do t[#t + 1] = byteOf[NOE[rnd(#NOE)]] end
                    t[#t + 1] = byteOf[LET[rnd(#LET)]]
                end
            end
            return table.concat(t)
        end
        local lines, badS, badE, lost = 0, {}, {}, 0
        for n = 1, 60 do
            local p = para(40 + rnd(160))
            for _, cols in ipairs({ 7, 9, 12, 17, 23, 31 }) do
                local all = {}
                for _, runs in ipairs(wrapRuns(p, "F2", cols * 16)) do
                    local tx = {}
                    for _, r in ipairs(runs) do if r.text then tx[#tx + 1] = r.text end end
                    local line = table.concat(tx)
                    all[#all + 1] = line
                    if #line > 0 then
                        lines = lines + 1
                        local a1, z1 = S.byte(line, 1), S.byte(line, #line)
                        if isNoS[a1] and #badS < 5 then badS[#badS + 1] = string.format("para %d at %d: U+%04X", n, cols, a1) end
                        if isNoE[z1] and #badE < 5 then badE[#badE + 1] = string.format("para %d at %d: U+%04X", n, cols, z1) end
                    end
                end
                if table.concat(all) ~= p then lost = lost + 1 end
            end
        end
        check("KINSOKU: the paragraphs wrap to many lines", lines > 1000, lines)
        check("KINSOKU: no line starts with a closing mark, long-vowel mark or small kana", #badS == 0, table.concat(badS, ", "))
        check("KINSOKU: no line ends with an opening mark", #badE == 0, table.concat(badE, ", "))
        check("KINSOKU: every letter is kept, in order", lost == 0, lost)
    end
end

print("guide_lang_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
