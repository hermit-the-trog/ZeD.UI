-- ZeDUI/tools/qa/balloon_cjk_sim.lua  (Nov 12 2026, bug 158: Chinese letters missing from the speech balloon)
-- QA's Mac, with the game in Simplified Chinese: the four letters U+641C U+522E U+72B6 U+6001 ("scavenge status")
-- drew as the first two, with no gap where the last two belonged. The cause: under Chinese the game's own faces
-- stand in for ZeD's (ZeD.Text.fallback), and the game's Chinese face is Noto Sans TC, a traditional set with no
-- simplified-only letters (U+72B6 and U+6001 among them); AngelCodeFont skips a letter its font lacks and advances
-- nothing. ZeD's script swap (Noto Sans SC on Cred1) was off while the game's faces stood in, and the game's CN font
-- list reloads Cred1 with its credits face, so Noto Sans SC was not even loaded under Chinese.
--
-- This runs the real shared/ZeD/Scale.lua, client/ZeD/Overrides/TextScale.lua and client/ZeD/ZeD_Bubbles.lua on a
-- stand-in for the engine's text manager that reads the real .fnt files (ZeD's and the game's) and measures the way
-- AngelCodeFont does: a letter's advance, the last letter's width, a letter the font lacks 0 wide and drawn as
-- nothing; the line height is the lowest reach of any letter. The slots are filled from the real font lists the way
-- TextManager.Init does (EN's list, then the language's over it; each file found as getFontFilePath finds it, the
-- mod's copy first), at font size 1x and ZeD's root scale 2 (4K).
-- Strings are made the way the game hands them to Lua: one Lua character per letter (a Java string). In the game's
-- own Kahlua, string.char of a code point gives exactly that; under real Lua 5.1 the sim stands in for it
-- (string.char of a code point past 255 gives one private byte the stand-in text manager reads back as the letter).
-- The PC probe's string, its UTF-8 bytes through string.char, is twelve Latin-1 characters, not four letters.
-- Checked in English and in Simplified Chinese:
--   LINE     the real line is four characters; the balloon keeps it whole (one line), and B.drawLine draws it in a
--            face that has all four letters (Noto Sans SC on Cred1), its width the one the balloon was sized by
--   CAUSE    (Chinese) the game's stand-in lacks U+72B6 and U+6001: in it the line measures as wide as its first two
--            letters; with the game's own CN list Cred1 is the credits face and the line could only reach the
--            Japanese face, which lacks U+6001 (so ZeD's CN list matters)
--   DRAW     ISUIElement drawText / Right / Centre and the lean drawText in the roles' fonts draw the line in a face
--            with all its letters, where ZeD.TM measures it (right edge at x, centre at x)
--   KEEP     a line the face draws whole (Latin, or letters both Chinese faces share) takes the original call, as before
--   PROBE    the byte string draws in the face it always did (no swap): its Latin-1 characters, the 0x80-0x9F ones as
--            nothing, which is the mojibake the PC probe saw
--   LISTS    ZeD's CN, CH, JP, KO and TH font lists are the game's own minus Cred1
-- With an older Scale.lua given (ZED_OLD_SCALE, or the third argument under Kahlua) it also shows that code drawing
-- the line in the stand-in with two of its four letters.
--
-- Run from the repo root:  lua51 ZeDUI/tools/qa/balloon_cjk_sim.lua [game folder]
-- or in the game's own Kahlua (KRun.java beside this file; compile it once with any JDK: javac -d <dir> KRun.java):
--   "<game>/jre64/bin/java" -Duser.dir="<game>" -cp "<dir>;<game>/projectzomboid.jar" KRun <this file, absolute>
--       <repo root, absolute> <game folder> [old Scale.lua]
-- The game folder defaults to E:/Project Zomboid/steamapps/common/ProjectZomboid (ZED_PZ overrides it under Lua).
-- Prints FAIL lines, what each case drew, and "balloon_cjk_sim: N checks, M failed"; exits 1 if any failed.

local KAHLUA = kread ~= nil
local ROOT, GAME, OLD
if KAHLUA then
    ROOT = arg[1] or ""
    GAME = arg[2] or "E:/Project Zomboid/steamapps/common/ProjectZomboid"
    OLD = arg[3]
else
    ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]balloon_cjk_sim%.lua$", "")
    GAME = (arg and arg[1]) or os.getenv("ZED_PZ") or "E:/Project Zomboid/steamapps/common/ProjectZomboid"
    OLD = os.getenv("ZED_OLD_SCALE")
end
if ROOT ~= "" and not string.find(ROOT, "[/\\]$") then ROOT = ROOT .. "/" end

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function finish()
    print("balloon_cjk_sim: " .. checks .. " checks, " .. failed .. " failed" .. (KAHLUA and " (the game's Kahlua)" or " (Lua 5.1)"))
    if KAHLUA then KRUN_EXIT = (failed > 0) and 1 or 0 else os.exit(failed > 0 and 1 or 0) end
end

-- files ------------------------------------------------------------------------------------------------------------
local TEXT = {}
local function readFile(p)
    local t = TEXT[p]
    if t ~= nil then return t or nil end
    if KAHLUA then
        t = kread(p)
    else
        local f = io.open(p, "rb")
        if f then t = f:read("*a"); f:close() end
    end
    TEXT[p] = t or false
    return t
end
local function loadFile(p)
    if KAHLUA then return kload(p) end
    return loadfile(p)
end
local function run(p)
    local fn, err = loadFile(p)
    if not fn then error("sim: cannot load " .. p .. ": " .. tostring(err)) end
    local realPrint = print
    print = function() end
    local ok, e = pcall(fn)
    print = realPrint
    if not ok then error("sim: " .. p .. " threw: " .. tostring(e)) end
end

-- strings the way the game makes them ------------------------------------------------------------------------------
local CP   -- CP(s, i): the letter at i, as the game reads it (string.byte of a Java string's character)
if KAHLUA then
    CP = function(s, i) return string.byte(s, i) end
else
    local nativeChar, POOL, BACK, nextB = string.char, {}, {}, 0xC0
    local function map(cp)
        if cp < 256 then return cp end
        local b = POOL[cp]
        if not b then
            if nextB > 0xDF then error("sim: more than 32 letters past U+00FF") end
            b = nextB
            nextB = nextB + 1
            POOL[cp], BACK[b] = b, cp
        end
        return b
    end
    -- (Kahlua's string.char takes code points; the production code probes faces with it)
    string.char = function(...)
        local t = { ... }
        for i = 1, select("#", ...) do t[i] = map(t[i]) end
        return nativeChar(unpack(t))
    end
    CP = function(s, i)
        local b = string.byte(s, i)
        return b and (BACK[b] or b)
    end
end
local U = string.char
local LINE = U(0x641C, 0x522E, 0x72B6, 0x6001)     -- "scavenge status", simplified
local TRAD = U(0x641C, 0x522E)                     -- "scavenge": in both Chinese faces
local MAP = U(0x5730, 0x56FE)                      -- "map": U+56FE is simplified-only
local LATIN = "Condition 87%"
local BYTES = string.char(0xE6, 0x90, 0x9C, 0xE5, 0x88, 0xAE, 0xE7, 0x8A, 0xB6, 0xE6, 0x80, 0x81)   -- the PC probe's

-- fonts: the real .fnt files, measured as AngelCodeFont does -------------------------------------------------------
local FONTS = {}
local function fontAt(path)
    local f = FONTS[path]
    if f then return f end
    local t = readFile(path)
    if not t then error("sim: no font file " .. path) end
    f = { path = path, text = t, sdf = false, g = {}, lh = 0 }
    for id, h, y in string.gmatch(t, "char id=(%d+)[^\n]-height=(%d+)[^\n]-yoffset=(%-?%d+)") do
        if id ~= "32" then
            local r = tonumber(h) + tonumber(y)
            if r > f.lh then f.lh = r end
        end
    end
    FONTS[path] = f
    return f
end
local function glyph(f, cp)
    local g = f.g[cp]
    if g == nil then
        g = false
        local a = string.find(f.text, "\nchar id=" .. cp .. " ", 1, true)
        if a then
            local line = string.match(f.text, "[^\n]+", a + 1)
            g = { adv = tonumber(string.match(line, "xadvance=(%-?%d+)")), w = tonumber(string.match(line, "width=(%-?%d+)")),
                  y = tonumber(string.match(line, "yoffset=(%-?%d+)")), h = tonumber(string.match(line, "height=(%-?%d+)")) }
        end
        f.g[cp] = g
    end
    return g or nil
end

UIFont = {}
local SLOT_NAMES = { "Small", "Medium", "Large", "NewSmall", "NewMedium", "NewLarge", "Code", "CodeSmall", "CodeMedium",
    "CodeLarge", "Cred1", "Cred2", "MainMenu1", "MainMenu2", "Title", "Massive", "Dialogue", "Intro", "DebugConsole",
    "Handwritten" }
local NAME_OF = {}
-- (strings, not tables: ZeD.Text tells a font entry from a UIFont by type, and the game's UIFont is a Java object)
for _, n in ipairs(SLOT_NAMES) do UIFont[n] = "UIFont." .. n; NAME_OF[UIFont[n]] = n end
local SLOTPATH, SLOTSDF = {}, {}
local function slotFont(u)
    local p = SLOTPATH[u]
    if not p then error("sim: nothing in slot " .. tostring(NAME_OF[u])) end
    local f = fontAt(p)
    if SLOTSDF[u] then f.sdf = true end
    return f
end

local TMs = {}
function TMs:MeasureStringX(u, s)
    local f = slotFont(u)
    s = tostring(s)
    local n, w, best = #s, 0, 0
    for i = 1, n do
        local c = CP(s, i)
        if c == 10 then
            w = 0
        else
            local g = glyph(f, c)
            if g then
                if i < n then w = w + g.adv else w = w + g.w end
                if w > best then best = w end
            end
        end
    end
    return best
end
local function inkOf(u, s)
    local f = slotFont(u)
    local top, bot = 1000000, 0
    for i = 1, #s do
        local c = CP(s, i)
        local g = (c ~= 32 and c ~= 10) and glyph(f, c) or nil
        if g then
            if g.y < top then top = g.y end
            if g.y + g.h > bot then bot = g.y + g.h end
        end
    end
    return top, bot
end
function TMs:MeasureStringYOffset(u, s) local top = inkOf(u, tostring(s)); return top end
function TMs:MeasureStringYReal(u, s) local top, bot = inkOf(u, tostring(s)); return bot - top end
function TMs:MeasureStringY(u, s) local n = 1; for _ in string.gmatch(tostring(s), "\n") do n = n + 1 end; return n * slotFont(u).lh end
function TMs:getFontHeight(u) return slotFont(u).lh end
function TMs:isSdf(u) return slotFont(u).sdf end
function TMs:getFontFromEnum() return nil end

-- the font lists, merged as TextManager.Init merges them ------------------------------------------------------------
local function readList(path)
    local t = path and readFile(path)
    if not t then return nil end
    local out = {}
    for name, body in string.gmatch(t, "font%s+(%w+)%s*{([^}]*)}") do
        local fnt = string.match(body, "fnt%s*=%s*([^,%s]+)")
        local typ = string.match(body, "type%s*=%s*([^,%s]+)")
        out[name] = { fnt = fnt, sdf = (typ ~= nil and string.lower(typ) == "sdf") }
    end
    return out
end
local function exists(rel)   -- the mod's file first, as ZomboidFileSystem finds it
    local p = ROOT .. "42/" .. rel
    if readFile(p) then return p end
    p = GAME .. "/" .. rel
    if readFile(p) then return p end
    return nil
end
local function fontPath(lang, scale, fnt)   -- TextManager.getFontFilePath
    local p = exists("media/fonts/" .. lang .. "/" .. scale .. "/" .. fnt) or exists("media/fonts/" .. lang .. "/" .. fnt)
    if not p and lang ~= "EN" then
        p = exists("media/fonts/EN/" .. scale .. "/" .. fnt) or exists("media/fonts/EN/" .. fnt)
    end
    return p or exists("media/fonts/" .. fnt) or exists("media/" .. fnt)
end
local function setLanguage(lang, langList)
    local merged = {}
    for k, v in pairs(readList(ROOT .. "42/media/fonts/EN/fonts.txt")) do merged[k] = v end
    if lang ~= "EN" then
        local l = readList(langList or exists("media/fonts/" .. lang .. "/fonts.txt"))
        if not l then error("sim: no " .. lang .. " font list") end
        for k, v in pairs(l) do merged[k] = v end
    end
    SLOTPATH, SLOTSDF = {}, {}
    for name, e in pairs(merged) do
        local u = UIFont[name]
        if u then
            SLOTPATH[u] = fontPath(lang, "1x", e.fnt)
            SLOTSDF[u] = e.sdf
        end
    end
    return merged
end

-- the game around ZeD's text code -----------------------------------------------------------------------------------
LANG = "EN"
getCore = function()
    return { getOptionFontSize = function() return 2 end, getOptionEnableDyslexicFont = function() return false end,
             getScreenWidth = function() return 3840 end, getScreenHeight = function() return 2160 end }
end
isServer = function() return false end
Translator = { getLanguage = function() return { name = function() return LANG end } end }
getTimestampMs = function() return 1000 end
function require() end
Events = nil

local function newVanillaElement()
    ISUIElement = {}
    function ISUIElement:drawText(str, x, y, r, g, b, a, font)
        if self.javaObject ~= nil then
            if self.isCollapsed then return end
            self.javaObject:DrawText(font or UIFont.Small, str, x, y, r, g, b, a)
        end
    end
    function ISUIElement:drawTextRight(str, x, y, r, g, b, a, font)
        if self.javaObject ~= nil and str ~= nil then
            if self.isCollapsed then return end
            self.javaObject:DrawTextRight(font or UIFont.Small, str, x, y, r, g, b, a)
        end
    end
    function ISUIElement:drawTextCentre(str, x, y, r, g, b, a, font)
        if self.javaObject ~= nil then
            if self.isCollapsed then return end
            self.javaObject:DrawTextCentre(font or UIFont.Small, str, x, y, r, g, b, a)
        end
    end
    function ISUIElement:drawRectBorder() end
end
-- a Java UI element that writes down what it is asked to draw
local function javaRecorder()
    local rec = {}
    local jo = { rec = rec }
    function jo:DrawText(font, str, x, y, a1, a2, a3, a4, a5)
        if a5 ~= nil then rec[#rec + 1] = { font = font, str = str, x = x, y = y, z = a1 }
        else rec[#rec + 1] = { font = font, str = str, x = x, y = y, z = 1, native = true } end
    end
    function jo:DrawTextRight(font, str, x, y) rec[#rec + 1] = { font = font, str = str, x = x, y = y, z = 1, native = true, align = "r" } end
    function jo:DrawTextCentre(font, str, x, y) rec[#rec + 1] = { font = font, str = str, x = x, y = y, z = 1, native = true, align = "c" } end
    return jo, rec
end

-- ZeD's role entries, as Tokens.lua has them
local function roleEntries()
    local function e(slot, px) return { font = UIFont[slot], px = px, face = 64, lineH = 77, sdf = true } end
    return { sec = e("MainMenu2", 11), body = e("MainMenu1", 13), stat = e("Title", 11), head = e("Massive", 15), title = e("Cred2", 9) }
end
do
    local tok = readFile(ROOT .. "42/media/lua/shared/ZeD/Tokens.lua") or ""
    for role, slot in pairs({ sec = "MainMenu2", body = "MainMenu1", stat = "Title", head = "Massive", title = "Cred2" }) do
        check("Tokens.lua: the " .. role .. " role is on " .. slot,
            string.find(tok, role .. "%s*=%s*{%s*font%s*=%s*UIFont%." .. slot) ~= nil)
    end
end

-- load ZeD's text code fresh for a language and set the tokens the way ZeD.applyTheme does
local function boot(lang, langList, scalePath)
    LANG = lang
    setLanguage(lang, langList)
    getTextManager = function() return TMs end
    ZeD = { upper = string.upper }
    run(scalePath or (ROOT .. "42/media/lua/shared/ZeD/Scale.lua"))
    local X = ZeD.Text
    ZeD.Scale._root = 2
    ZeD.Font = { sdf = roleEntries() }
    local fb = X.checkRoleFonts()
    local SD = ZeD.Font.sdf
    local entries = { SD.sec, SD.body, SD.stat, SD.head, SD.title }
    local px = { 11, 13, 11, 15, 9 }
    local T = { fontPx = {}, fontFace = {}, scale = 2, root = 2, text = { r = 1, g = 1, b = 1, a = 1 } }
    for i = 1, 5 do
        if fb then
            T["fontF" .. i] = X.roleFallbackFont(px[i])
        else
            local e = entries[i]
            T["fontF" .. i] = e.font
            T.fontPx[e.font] = px[i]
            T.fontFace[e.font] = e.face or 64
        end
    end
    ZeD.T = T
    ZeD.Px = { textWidth = function(s) return #tostring(s) * 6 end, k = function() return 1 end,
               rect = function() end, rects = function() end, text = function() end }
    ZeD.PixelFonts = {}
    run(ROOT .. "42/media/lua/client/ZeD/ZeD_Bubbles.lua")
    if not scalePath then
        newVanillaElement()
        run(ROOT .. "42/media/lua/client/ZeD/Overrides/TextScale.lua")
    end
    return X, T, fb
end

-- every letter of s (but spaces) in the font in slot u; and how many
local function whole(u, s)
    local f = slotFont(u)
    local have, n = 0, 0
    for i = 1, #s do
        local c = CP(s, i)
        if c ~= 32 then
            n = n + 1
            if glyph(f, c) then have = have + 1 end
        end
    end
    return have == n, have, n
end
local function near(a, b) return math.abs(a - b) < 0.01 end

-- the balloon: say the line, lay it out, draw it on a canvas that writes down the draw
local function balloon(X, s)
    local B = ZeD.Bubbles
    local sp = B.say(0, s)
    local rec = {}
    local el = {}
    function el:drawTextZoomed(str, x, y, z, r, g, b, a, font) rec[#rec + 1] = { str = str, x = x, y = y, z = z, font = font } end
    local cv = { el = el, ox = 100, oy = 200, k = 2 }
    if sp then B.drawLine(cv, sp.lines[1], 0, 0, { r = 1, g = 1, b = 1 }, 1, "c") end
    return sp, rec[1]
end

local function report(tag, d, s)
    if not d then print(tag .. ": nothing drawn"); return end
    local _, have, n = whole(d.font, s)
    print(string.format("%s: %s, %s of %s letters, zoom %.3f", tag, tostring(NAME_OF[d.font]), tostring(have), tostring(n), d.z))
end

-- one language ------------------------------------------------------------------------------------------------------
local function language(lang)
    local X, T, fb = boot(lang)
    local tag = lang .. ": "
    check(tag .. "the fonts settle", X._fontsSettled == true)
    check(tag .. "the game's faces stand in only under Chinese", fb == (lang == "CN"), tostring(fb))
    check(tag .. "the line is four characters, the third U+72B6", #LINE == 4 and CP(LINE, 3) == 0x72B6, #LINE)
    check(tag .. "the probe's string is twelve characters", #BYTES == 12 and CP(BYTES, 2) == 0x90, #BYTES)
    check(tag .. "Cred1 holds ZeD's Noto Sans SC", string.find(SLOTPATH[UIFont.Cred1] or "", "sdf/notoSC.fnt", 1, true) ~= nil,
        SLOTPATH[UIFont.Cred1])
    local SF = X._scriptFonts
    X.scriptFont("")   -- (looks the faces up)
    check(tag .. "the script faces are found (Noto Sans SC and the Japanese face)", #SF.fonts == 2, #SF.fonts)

    if lang == "CN" then
        local f2 = T.fontF2
        check("CAUSE: the stand-in is the game's Chinese face", string.find(SLOTPATH[f2] or "", "Chinese.fnt", 1, true) ~= nil, SLOTPATH[f2])
        check("CAUSE: it lacks U+72B6 and U+6001", not glyph(slotFont(f2), 0x72B6) and not glyph(slotFont(f2), 0x6001))
        check("CAUSE: it has U+641C and U+522E", glyph(slotFont(f2), 0x641C) ~= nil and glyph(slotFont(f2), 0x522E) ~= nil)
        local tm = X.realTM()
        check("CAUSE: in it the line is as wide as its first two letters (no gap)",
            tm:MeasureStringX(f2, LINE) == tm:MeasureStringX(f2, TRAD) - glyph(slotFont(f2), 0x522E).w + glyph(slotFont(f2), 0x522E).adv
            or tm:MeasureStringX(f2, LINE) == tm:MeasureStringX(f2, TRAD), tm:MeasureStringX(f2, LINE))
    end

    -- LINE: the balloon
    local sp, d = balloon(X, LINE)
    check(tag .. "LINE the balloon keeps the line whole, one line", sp and sp.text == LINE and #sp.lines == 1 and sp.lines[1] == LINE)
    check(tag .. "LINE drawn", d ~= nil and d.str == LINE)
    if d then
        local ok, have, n = whole(d.font, LINE)
        check(tag .. "LINE drawn in a face with all four letters", ok, NAME_OF[d.font] .. " " .. have .. "/" .. n)
        check(tag .. "LINE drawn in Noto Sans SC", d.font == UIFont.Cred1, NAME_OF[d.font])
        local w = X.realTM():MeasureStringX(d.font, LINE) * d.z
        check(tag .. "LINE the balloon is sized by the face it is drawn in", sp.tw == math.ceil(w / 2), sp.tw .. " vs " .. w / 2)
        report(tag .. "balloon", d, LINE)
    end
    -- the head notes and notices take the same line drawing
    local n = ZeD.Bubbles.note(0, LINE, "bad")
    check(tag .. "LINE a head note keeps it whole", n and n.lines[1] == LINE)

    -- DRAW: the text draws through ISUIElement and the lean draw
    for i = 1, 5 do
        local f = T["fontF" .. i]
        local jo, rec = javaRecorder()
        local el = setmetatable({ javaObject = jo, isCollapsed = false }, { __index = ISUIElement })
        el:drawText(LINE, 10, 20, 1, 1, 1, 1, f)
        local r = rec[1]
        local ok = r and r.str == LINE and whole(r.font, LINE)
        check(tag .. "DRAW drawText F" .. i .. " in a face with all four letters", ok, r and NAME_OF[r.font])
        local tw = ZeD.TM:MeasureStringX(f, LINE)
        check(tag .. "DRAW drawText F" .. i .. " measures what it draws", r and near(tw, X.realTM():MeasureStringX(r.font, LINE) * r.z),
            r and (tw .. " vs " .. X.realTM():MeasureStringX(r.font, LINE) * r.z))
        el:drawTextRight(LINE, 300, 20, 1, 1, 1, 1, f)
        local rr = rec[2]
        check(tag .. "DRAW drawTextRight F" .. i .. " ends at x", rr and not rr.native and near(rr.x + tw, 300), rr and rr.x)
        el:drawTextCentre(LINE, 300, 20, 1, 1, 1, 1, f)
        local rc = rec[3]
        check(tag .. "DRAW drawTextCentre F" .. i .. " is centred on x", rc and not rc.native and near(rc.x + tw / 2, 300), rc and rc.x)
        local lean = { javaObject = jo, isCollapsed = false }
        ZeD.LeanDraw.drawText(lean, LINE, 10, 20, 1, 1, 1, 1, f)
        local rl = rec[4]
        check(tag .. "DRAW lean drawText F" .. i .. " in a face with all four letters", rl and whole(rl.font, LINE), rl and NAME_OF[rl.font])
        if i == 2 then report(tag .. "drawText F2", r, LINE) end
    end
    -- the pixel faces' stand-in words and the radio displays go through ZeD.Text.faceFor
    local sf = X.faceFor(T.fontF1, LINE, 1)
    check(tag .. "DRAW faceFor(F1) picks a face with all four letters", whole(sf, LINE), NAME_OF[sf])
    check(tag .. "DRAW faceFor(F1) for the map word", whole((X.faceFor(T.fontF1, MAP, 1)), MAP))
    -- the 5 x 7 pixel face (the radio and TV screens): a word it cannot spell draws in the F1 face, or in the face
    -- that has its letters. (The game's Kahlua only: the pixel faces name hundreds of letters past U+00FF, more than
    -- the Lua 5.1 stand-in has bytes for.)
    local okP, errP = KAHLUA, nil
    if KAHLUA then
        okP, errP = pcall(function()
            run(ROOT .. "42/media/lua/client/ZeD/PixelFonts.lua")
            run(ROOT .. "42/media/lua/client/ZeD/PixelFontsExt.lua")
            run(ROOT .. "42/media/lua/client/ZeD/ZeD_PixelParts.lua")
        end)
        check(tag .. "PIXEL the pixel faces load", okP, errP)
    end
    if okP then
        local prec = {}
        local pel = {}
        function pel:drawTextZoomed(str, x, y, z, r, g, b, a, font) prec[#prec + 1] = { str = str, font = font, z = z } end
        function pel:drawRect() end
        ZeD.Px.text({ el = pel, ox = 0, oy = 0, k = 2 }, LINE, 0, 0, { r = 1, g = 1, b = 1 }, "57", 1, "l")
        local pd = prec[1]
        check(tag .. "PIXEL a Chinese word draws in a face with all four letters", pd and pd.str == LINE and whole(pd.font, LINE),
            pd and NAME_OF[pd.font])
        prec = {}
        ZeD.Px.text({ el = pel, ox = 0, oy = 0, k = 2 }, "TUNED", 0, 0, { r = 1, g = 1, b = 1 }, "57", 1, "l")
        check(tag .. "PIXEL a word it spells stays pixels", #prec == 0, #prec)
        if pd then report(tag .. "pixel face word", pd, LINE) end
    end

    -- KEEP: lines the face draws whole stay on the original calls
    local keep = { LATIN }
    if lang == "CN" then keep[2] = TRAD end
    for _, s in ipairs(keep) do
        local jo, rec = javaRecorder()
        local el = setmetatable({ javaObject = jo, isCollapsed = false }, { __index = ISUIElement })
        el:drawText(s, 10, 20, 1, 1, 1, 1, T.fontF2)
        local r = rec[1]
        if fb then
            check(tag .. "KEEP " .. (s == LATIN and "Latin" or "U+641C U+522E") .. " takes the game's own call in the stand-in",
                r and r.native and r.font == T.fontF2, r and NAME_OF[r.font])
        else
            check(tag .. "KEEP Latin stays on the role font", r and r.font == T.fontF2, r and NAME_OF[r.font])
        end
        check(tag .. "KEEP no swap for it", X.scriptFont(s) == false)
    end

    -- PROBE: the PC probe's twelve characters
    local psp, pd = balloon(X, BYTES)
    check(tag .. "PROBE no swap for the byte string", X.scriptFont(BYTES) == false)
    check(tag .. "PROBE drawn in the balloon's own face", pd and pd.font == ZeD.Font.sdf.stat.font, pd and NAME_OF[pd.font])
    if pd then
        local _, have, nn = whole(pd.font, BYTES)
        check(tag .. "PROBE twelve characters, the 0x80-0x9F ones draw nothing", nn == 12 and have == 6, have .. "/" .. nn)
        report(tag .. "probe bytes", pd, BYTES)
    end
end

language("EN")
language("CN")

-- CAUSE, the list: with the game's own CN list, Cred1 is its credits face and the line can only reach the Japanese face
do
    local X = boot("CN", GAME .. "/media/fonts/CN/fonts.txt")
    X.scriptFont("")
    check("CAUSE: with the game's CN list Cred1 is not Noto Sans SC", string.find(SLOTPATH[UIFont.Cred1] or "", "notoSC", 1, true) == nil,
        SLOTPATH[UIFont.Cred1])
    local _, d = balloon(X, LINE)
    local ok, have = false, 0
    if d then ok, have = whole(d.font, LINE) end
    check("CAUSE: with the game's CN list the line loses U+6001", d and not ok and have == 3, d and (NAME_OF[d.font] .. " " .. have))
    report("CN, the game's own list", d, LINE)
end

-- the code as it was, if given
if OLD and OLD ~= "" then
    local X = boot("CN", nil, OLD)
    local _, d = balloon(X, LINE)
    local ok, have = false, 0
    if d then ok, have = whole(d.font, LINE) end
    check("OLD: the old code drew the line in the stand-in with two of four letters", d and not ok and have == 2,
        d and (NAME_OF[d.font] .. " " .. have))
    report("CN, old Scale.lua", d, LINE)
end

-- LISTS: ZeD's copies are the game's own minus Cred1
for _, L in ipairs({ "CN", "CH", "JP", "KO", "TH" }) do
    local mine = readList(ROOT .. "42/media/fonts/" .. L .. "/fonts.txt")
    local game = readList(GAME .. "/media/fonts/" .. L .. "/fonts.txt")
    check("LISTS " .. L .. ": ZeD ships the list", mine ~= nil)
    if mine and game then
        local same = mine.Cred1 == nil
        for k, v in pairs(game) do
            if k ~= "Cred1" and not (mine[k] and mine[k].fnt == v.fnt and mine[k].sdf == v.sdf) then same = false end
        end
        for k, _ in pairs(mine) do if not game[k] then same = false end end
        check("LISTS " .. L .. ": the game's list minus Cred1", same)
    end
end

finish()
