-- ZeD-UI/42/media/lua/shared/ZeD/Tr.lua
-- ============================================================================
-- TRANSLATION HELPER
--
-- THE RULE: new visible text goes in Translate/EN/UI.json under a UI_ZeD_<Area>_<What> key
-- (UI_ZeD_Card_Needs, UI_ZeD_ActionBar_Reading...) and is drawn through ZeD.tr. Never a
-- bare English phrase in the code. If the game already has the same phrase, use the game's key
-- instead (ZeD.tr("IGUI_health_Left_Foot") works with any key): the game's wording wins, so the
-- phrase arrives translated in every language the game ships. Words built from parts get ONE key with placeholders
-- (%1 to %4), never glued pieces, because word order changes between languages.
--
--   ZeD.tr(key, a, b, c, d)    the text for key in the player's language. %1..%4 take the
--                              arguments (numbers print without a trailing ".0").
--                              A key the translation files lack gives the English that
--                              ZeD.trDefault registered for it, and failing that the key.
--   ZeD.trBare(key, ...)       the same text without the colon, full stop and spaces the game puts at
--                              the end of a label or message ("Map:" -> "Map"); for borrowed wording.
--   ZeD.trPlain(key, ...)      the same text, never stretched by the test language (fixed cells).
--   Capitals: a tag or column head the game spells in lower case is drawn ZeD.upper(ZeD.tr(key)).
--   ZeD.trEnglish(key, ...)    the registered English for key, whatever the player's language.
--   ZeD.trDefault(key, text)   registers the English fallback for a key, in code, so a
--                              missing or broken translation file never shows raw keys.
--   ZeD.trDefaults({ key = text, ... })   the same for several keys at once.
--   ZeD.trTestOn()             true while the hidden test language is on.
--   ZeD.trStretch(text)        what the test language makes of a phrase (QA bridge).
--
-- TEST LANGUAGE: with the Test language option On (Options > Mods > ZeD-GUI), ZeD.tr
-- returns every ZeD phrase about 40% longer, accented and in brackets, e.g.
-- "[Ŕéàďìñĝ ŕéàďìñĝ]", so a screen that clips, overlaps or loses its brackets shows up
-- without waiting for a real translation. Placeholders (%1..%4) and markup tags
-- (<LINE>, <RGB:1,1,1>) stay intact; the extra length is repeated vowels.
--
-- The accented letters are written as character codes so the file does not depend on
-- how the game reads its encoding. Every one is in Latin-1 or Latin Extended-A, which the
-- ZeD fonts carry. B F M P Q V X have no such form and stay plain.
-- ============================================================================

ZeD = ZeD or {}

-- the English fallbacks (kept on ZeD so a reload of this file keeps them)
local defaults = ZeD._trDefaults or {}
ZeD._trDefaults = defaults

-- Stored the way the game hands a template back (see lookup, below): a literal percent sign is
-- written "%%" in UI.json, as in vanilla's files, and kept here as a single "%".
function ZeD.trDefault(key, text)
    if key ~= nil and text ~= nil then
        defaults[tostring(key)] = (tostring(text):gsub("%%%%", "%%"))
    end
end

function ZeD.trDefaults(tbl)
    if type(tbl) ~= "table" then return end
    for k, v in pairs(tbl) do ZeD.trDefault(k, v) end
end

-- ---------------------------------------------------------------------------
-- The test language
-- ---------------------------------------------------------------------------
local READ_MS   = 500     -- the option is read at most this often
local CACHE_MAX = 2000    -- stretched phrases kept; past that the oldest drops

local st = ZeD._trState or { on = false, nextRead = 0 }
ZeD._trState = st

-- A combo is saved as its item's position: 1 = Off, 2 = On.
local function readOption()
    local o = ZeD.Settings and ZeD.Settings.testLanguageOption
    if not o then return false end
    local ok, v = pcall(o.getValue, o)
    return ok and v == 2
end

local checkLanguage = nil   -- (set below, with the template cache it clears)

local function testOn()
    if not getTimestampMs then return false end   -- no clock: a server, never the test language
    local now = getTimestampMs()
    if now >= st.nextRead then
        st.nextRead = now + READ_MS
        st.on = readOption()
        if checkLanguage then checkLanguage() end
    end
    return st.on
end
ZeD.trTestOn = testOn

-- ASCII letter -> accented look-alike, by character code
local CODES = {
    A = 192, C = 264, D = 270, E = 201, G = 284, H = 292, I = 204, J = 308, K = 310,
    L = 313, N = 209, O = 212, R = 340, S = 352, T = 356, U = 219, W = 372, Y = 221, Z = 381,
    a = 224, c = 265, d = 271, e = 233, g = 285, h = 293, i = 236, j = 309, k = 311,
    l = 314, n = 241, o = 244, r = 341, s = 353, t = 357, u = 251, w = 373, y = 253, z = 382,
}
local MAP = {}
for ch, code in pairs(CODES) do MAP[ch] = string.char(code) end

local VOWEL = { a = true, e = true, i = true, o = true, u = true, A = true, E = true, I = true, O = true, U = true }

-- The stretched phrases, keyed by the English they came from; oldest dropped first.
local cache, order, head, count = {}, {}, 1, 0

-- A placeholder (%1..%4) or a markup tag (<LINE>, <RGB:1,1,1>, </...>) at position i:
-- the text of it, else nil. These pass through untouched.
local function keepAt(s, i)
    local c = s:sub(i, i)
    if c == "%" then
        local d = s:sub(i + 1, i + 1)
        if d == "1" or d == "2" or d == "3" or d == "4" then return "%" .. d end
    elseif c == "<" then
        local j = s:find(">", i, true)
        if j and j - i < 40 and s:sub(i + 1, i + 1):match("[%a/]") then return s:sub(i, j) end
    end
    return nil
end

local function stretch(s)
    local hit = cache[s]
    if hit then return hit end

    local txt, vow, isLetter, n = {}, {}, {}, 0
    local visible, letters = 0, 0
    local i, len = 1, #s
    while i <= len do
        local keep = keepAt(s, i)
        n = n + 1
        if keep then
            txt[n] = keep
            i = i + #keep
        else
            local c = s:sub(i, i)
            txt[n] = MAP[c] or c
            vow[n] = VOWEL[c] and true or false
            local letter = (c:match("%a") ~= nil) or (c:byte() or 0) >= 128
            isLetter[n] = letter
            visible = visible + 1
            if letter then letters = letters + 1 end
            i = i + 1
        end
    end

    local result
    if letters == 0 then
        result = s   -- digits and signs only: nothing to translate
    else
        local extra = math.floor(visible * 0.4 + 0.5)
        if extra < 1 then extra = 1 end
        -- the places that grow: vowels, or any letter when the phrase has none
        local cands = {}
        for k = 1, n do if vow[k] then cands[#cands + 1] = k end end
        if #cands == 0 then
            for k = 1, n do if isLetter[k] then cands[#cands + 1] = k end end
        end
        local dup = {}
        local nc = #cands
        local given = 0
        for ci = 1, nc do
            local upto = math.floor(ci * extra / nc)   -- spread the extras evenly
            dup[cands[ci]] = upto - given
            given = upto
        end
        local parts = {}
        for k = 1, n do
            local d = dup[k]
            if d and d > 0 then parts[k] = string.rep(txt[k], d + 1) else parts[k] = txt[k] end
        end
        result = "[" .. table.concat(parts) .. "]"
    end

    -- remember it; drop the oldest once the cache is full
    cache[s] = result
    count = count + 1
    order[count] = s
    if count - head + 1 > CACHE_MAX then
        cache[order[head]] = nil
        order[head] = nil
        head = head + 1
    end
    return result
end
ZeD.trStretch = stretch

-- ---------------------------------------------------------------------------
-- ZeD.tr
-- ---------------------------------------------------------------------------
-- The template for key from the translation files (%1..%4 intact, "%%" read as "%"), or nil.
--
-- B42's getText / getTextOrNull run the loaded text through Java's String.formatted (the
-- loader turns %1 into %1$s). Asked with no arguments, a text that has a placeholder throws
-- MissingFormatArgumentException inside the game, which logs a warning and hands back the raw
-- "%1$s" form. So the template is asked for with "%1".."%4" as the arguments: the game fills
-- its own placeholders with ours, and ZeD fills them below. Templates are kept per key (one
-- Java call per key, not per frame) and dropped when the game's language changes.
local TPL_MAX = 8000
local tpl, tplCount, tplLang = {}, 0, nil

local function languageNow()
    local ok, l = pcall(function() return Translator.getLanguage() end)
    if ok then return l end
    return nil
end

local function lookup(key)
    local t = tpl[key]
    if t ~= nil then
        if t == false then return nil end
        return t
    end
    local s = nil
    if getTextOrNull then
        s = getTextOrNull(key, "%1", "%2", "%3", "%4")
    elseif getText then
        s = getText(key, "%1", "%2", "%3", "%4")
        if s == key then s = nil end
    end
    if tplCount >= TPL_MAX then tpl, tplCount = {}, 0 end
    if s ~= nil then tpl[key] = s else tpl[key] = false end
    tplCount = tplCount + 1
    return s
end

-- the language is checked as often as the test option; a change drops the templates and bumps
-- ZeD._trGen, so other caches of translated words (InventoryRenderer.catLabel) can drop theirs
ZeD._trGen = ZeD._trGen or 0
checkLanguage = function()
    local l = languageNow()
    if l ~= tplLang then
        tplLang = l
        tpl, tplCount = {}, 0
        ZeD._trGen = ZeD._trGen + 1
    end
end

-- ---------------------------------------------------------------------------
-- ZeD.upper(s): s in capitals, for every language
--
-- Headings drawn in capitals go through here rather than string.upper. Kahlua's string.upper
-- is Java's, so it already capitalises most letters beyond ASCII, but not the way a heading
-- wants them: it turns the German sharp s into "SS" (the heading grows), keeps the Greek
-- accents on capitals (the capitals-only convention drops them), and writes the Turkish i as a
-- plain I. This table sets those right and spells out the letters ZeD's fonts carry:
-- Latin-1 Supplement, Latin Extended-A, the Romanian comma letters, Greek, Cyrillic. A letter
-- not in the table goes to string.upper one character at a time (Vietnamese, say); a
-- character with no capital stays as it is.
--   * the German sharp s stays as it is (one character, so a heading never grows);
--   * Greek final sigma becomes the plain capital sigma; accented vowels lose the accent
--     (a dieresis stays, as capitals keep it);
--   * Turkish and Azeri (the game's language is TR or AZ): i -> dotted capital I, dotless i -> I.
--
-- Results are cached per string, 512 at most; past that the oldest drops. A change of the
-- game's language starts the cache over (the Turkish rule depends on it).
-- Written with character codes only, so the file does not depend on how the game reads its
-- encoding.
-- ---------------------------------------------------------------------------
local UPPER_MAX = 512
local upCache, upOrder, upHead, upCount = {}, {}, 1, 0
local upGen = -1
local turkic = false
local UPC = nil   -- character code -> its capital, as a one-character string
local DOTTED_I = string.char(304)

local function buildUpperTable()
    local m = {}
    local function put(lo, hi) m[lo] = string.char(hi) end
    -- Latin-1 Supplement: a-grave .. thorn minus the division sign; the sharp s stays; y-dieresis
    for c = 224, 254 do if c ~= 247 then put(c, c - 32) end end
    put(223, 223)
    put(255, 376)
    -- Latin Extended-A: pairs where the small letter is odd, even, odd, even in turn
    for c = 257, 311, 2 do put(c, c - 1) end
    for c = 314, 328, 2 do put(c, c - 1) end
    for c = 331, 375, 2 do put(c, c - 1) end
    for c = 378, 382, 2 do put(c, c - 1) end
    put(305, 73)    -- dotless i -> I (after the loop, which pairs it with the dotted one)
    put(383, 83)    -- long s -> S
    -- Romanian comma letters (s and t with comma below)
    put(537, 536)
    put(539, 538)
    -- Greek: alpha .. omega (final sigma is the plain capital sigma), accents dropped
    for c = 945, 969 do put(c, c - 32) end
    put(962, 931)
    put(940, 913)   -- alpha tonos
    put(941, 917)   -- epsilon tonos
    put(942, 919)   -- eta tonos
    put(943, 921)   -- iota tonos
    put(972, 927)   -- omicron tonos
    put(973, 933)   -- upsilon tonos
    put(974, 937)   -- omega tonos
    put(912, 938)   -- iota with dieresis and tonos
    put(944, 939)   -- upsilon with dieresis and tonos
    -- Cyrillic: a-ya, the yo block, the historic and extended letters (pairs, small letter odd)
    for c = 1072, 1103 do put(c, c - 32) end
    for c = 1104, 1119 do put(c, c - 80) end
    for c = 1121, 1153, 2 do put(c, c - 1) end
    for c = 1163, 1215, 2 do put(c, c - 1) end
    for c = 1218, 1230, 2 do put(c, c - 1) end
    put(1231, 1216)
    for c = 1233, 1327, 2 do put(c, c - 1) end
    return m
end

-- true when the game's language writes the capital of i with a dot
local function turkicNow()
    local ok, name = pcall(function() return Translator.getLanguage():name() end)
    if not ok then return false end
    return name == "TR" or name == "AZ"
end

function ZeD.upper(s)
    if s == nil then return "" end
    if type(s) ~= "string" then s = tostring(s) end
    testOn()   -- keeps the language check ticking, as ZeD.tr does
    if upGen ~= ZeD._trGen then
        upGen = ZeD._trGen
        turkic = turkicNow()
        upCache, upOrder, upHead, upCount = {}, {}, 1, 0
    end
    local hit = upCache[s]
    if hit then return hit end

    local result
    if not s:find("[^ -~]") and not (turkic and s:find("i", 1, true)) then
        result = string.upper(s)   -- plain ASCII (and no Turkish i): nothing special
    else
        if not UPC then UPC = buildUpperTable() end
        local parts = {}
        for i = 1, #s do
            local c = s:byte(i)
            local r
            if c < 128 then
                if c >= 97 and c <= 122 then
                    if c == 105 and turkic then r = DOTTED_I else r = string.char(c - 32) end
                else
                    r = s:sub(i, i)
                end
            else
                r = UPC[c]
                if r == nil then
                    local ch = s:sub(i, i)
                    r = string.upper(ch)
                    if #r ~= 1 then r = ch end
                end
            end
            parts[i] = r
        end
        result = table.concat(parts)
    end

    -- remember it; drop the oldest once the cache is full
    upCache[s] = result
    upCount = upCount + 1
    upOrder[upCount] = s
    if upCount - upHead + 1 > UPPER_MAX then
        upCache[upOrder[upHead]] = nil
        upOrder[upHead] = nil
        upHead = upHead + 1
    end
    return result
end

local function argText(v)
    if type(v) == "number" then return tostring(v) end
    return v
end

-- %1..%4 of s from the four arguments. With no arguments at all the template comes back as it
-- is; otherwise a nil argument reads as "" (as the game's getText does).
local _f1, _f2, _f3, _f4 = nil, nil, nil, nil
local function fillOne(d)
    local v
    if d == "1" then v = _f1 elseif d == "2" then v = _f2 elseif d == "3" then v = _f3 else v = _f4 end
    if v == nil then return "" end
    return tostring(v)
end
local function fill(s, a1, a2, a3, a4)
    if a1 == nil and a2 == nil and a3 == nil and a4 == nil then return s end
    _f1, _f2, _f3, _f4 = a1, a2, a3, a4
    local out = s:gsub("%%([1-4])", fillOne)
    _f1, _f2, _f3, _f4 = nil, nil, nil, nil
    return out
end

-- The phrases asked for with up to two text arguments are kept (Oct 22 2026, the drawing-cost
-- work: the windows ask for the same column heads, counts and tags every frame), until the
-- language or the test language changes, or TRM_MAX are kept. A missing key is never kept (its
-- English default may be registered later).
local TRM_MAX = 4000
local SEP, NILA = string.char(1), string.char(2)
local trm, trmN, trmGen, trmOn = {}, 0, nil, nil
function ZeD.tr(key, ...)
    if key == nil then return "" end
    key = tostring(key)
    local a1, a2, a3, a4 = ...
    a1, a2, a3, a4 = argText(a1), argText(a2), argText(a3), argText(a4)

    local on = testOn()
    if trmGen ~= ZeD._trGen or trmOn ~= on or trmN >= TRM_MAX then trm, trmN, trmGen, trmOn = {}, 0, ZeD._trGen, on end
    local mk = nil
    if a3 == nil and a4 == nil and (a1 == nil or type(a1) == "string") and (a2 == nil or type(a2) == "string") then
        if a1 == nil and a2 == nil then mk = key
        else mk = key .. SEP .. (a1 or NILA) .. SEP .. (a2 or NILA) end
        local hit = trm[mk]
        if hit then return hit end
    end
    local raw = lookup(key)
    if raw == nil then raw = defaults[key] end
    if raw == nil then return key end   -- a missing key stays visibly raw
    if on then raw = stretch(raw) end
    local out = fill(raw, a1, a2, a3, a4)
    if mk then
        trm[mk] = out
        trmN = trmN + 1
    end
    return out
end

-- ZeD.trBare(key, a, b, c, d): ZeD.tr, minus the punctuation the game hangs on a label or a
-- sentence: trailing spaces, colons and full stops ("Map:", "Mods :", "Too dark to read.").
-- For a tag, a column head or a row label that borrows the game's wording ("game wording
-- wins") where the game's own text is a form label or a message. The Chinese and Japanese
-- full-width colon and the ideographic full stop go too. The test language stretches the
-- bare text, so its brackets still close the phrase.
local FW_COLON, IDEO_STOP = string.char(65306), string.char(12290)
local bareCache, bareCount = {}, 0
local function bareEnd(s)
    local hit = bareCache[s]
    if hit then return hit end
    local out = s
    while true do
        local cut = out:gsub("[%s:%.]+$", "")
        local last = cut:sub(#cut, #cut)
        if last == FW_COLON or last == IDEO_STOP then cut = cut:sub(1, #cut - 1) end
        if cut == out then break end
        out = cut
    end
    if out == "" then out = s end   -- never strip a text to nothing
    if bareCount >= 256 then bareCache, bareCount = {}, 0 end
    bareCache[s] = out
    bareCount = bareCount + 1
    return out
end

function ZeD.trBare(key, ...)
    if key == nil then return "" end
    key = tostring(key)
    local a1, a2, a3, a4 = ...
    a1, a2, a3, a4 = argText(a1), argText(a2), argText(a3), argText(a4)

    local on = testOn()
    local raw = lookup(key)
    if raw == nil then raw = defaults[key] end
    if raw == nil then return key end   -- a missing key stays visibly raw
    raw = bareEnd(raw)
    if on then raw = stretch(raw) end
    return fill(raw, a1, a2, a3, a4)
end

-- ZeD.trPlain(key, a, b, c, d): the translation exactly as ZeD.tr gives it, but never
-- stretched by the test language. For text that sits in a fixed-size cell by design
-- (the watch's LCD day cell, say), where stretching would only test the wrong thing.
function ZeD.trPlain(key, ...)
    if key == nil then return "" end
    key = tostring(key)
    local a1, a2, a3, a4 = ...
    a1, a2, a3, a4 = argText(a1), argText(a2), argText(a3), argText(a4)

    testOn()   -- keeps the language check ticking, as ZeD.tr does
    local raw = lookup(key)
    if raw == nil then raw = defaults[key] end
    if raw == nil then return key end
    return fill(raw, a1, a2, a3, a4)
end

-- ZeD.trEnglish(key, a, b, c, d): the English ZeD.trDefault registered for key, whatever
-- the player's language (the key itself when none is registered). For things that were
-- printed in English on the real hardware, such as an LCD watch's day names.
function ZeD.trEnglish(key, ...)
    if key == nil then return "" end
    key = tostring(key)
    local a1, a2, a3, a4 = ...
    a1, a2, a3, a4 = argText(a1), argText(a2), argText(a3), argText(a4)
    local raw = defaults[key]
    if raw == nil then return key end
    return fill(raw, a1, a2, a3, a4)
end

-- ---------------------------------------------------------------------------
-- The English for every key in Translate/EN/UI.json, so a missing file shows words.
-- (UI.json is the source of truth; keep the two in step.)
-- ---------------------------------------------------------------------------
ZeD.trDefaults({
    UI_ZeD_ModName = "ZeD-GUI",
    UI_ZeD_ModDesc = "Total UI overhaul for Project Zomboid",

    UI_ZeD_Settings_BaseTheme = "Base theme",
    UI_ZeD_Settings_AccentColor = "Accent color",
    UI_ZeD_Settings_TextSize = "Text size",
    UI_ZeD_Settings_Dark = "Dark",
    UI_ZeD_Settings_Light = "Light",
    UI_ZeD_Settings_HighContrast = "High contrast",

    UI_ZeD_Accent_Teal = "PZ Teal",

    UI_ZeD_Status_Danger = "Danger",
    UI_ZeD_Status_Warning = "Warning",
    UI_ZeD_Status_Info = "Info",

    UI_ZeD_Close = "Close",
    UI_ZeD_NoResults = "No results",
    UI_ZeD_Weight = "Weight",
})
