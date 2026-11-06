-- ZeD-UI/42/media/lua/client/ZeD/ZeD_SurvivalGuide.lua
-- ============================================================================
-- THE SURVIVAL GUIDE (F1), the Simple look (ZeDUI/SURVIVAL_GUIDE_DRAFT.md; mockup
-- ZeDUI/mockups/zed_survival_guide_v7.html; director Nov 3 2026: "You are go for build").
--
-- A ZeD window in place of the game's guide (HOOK_MAP row 18): the game's sections and
-- topics on the left (Find at the top, sections that fold), the chosen topic on the right
-- (its clip, the game's own text, and The Rules in Numbers where the game keeps rules in
-- numbers), a band at the foot (the game's "Show the guide on startup", Previous, Next) and
-- the window's help line. Everything shown is read from the game: SurvivalGuideEntry for the
-- topics, text and clips; the game's own files for the numbers (the director's line, Nov 3:
-- the game's rules as numbers, never your world's secrets).
--
-- The game's behaviour is kept: F1 and the controller's Help wheel toggle it, it opens by
-- itself on a new game while "Show the guide on startup" is ticked, the game pauses while it
-- is open, and other windows open it on a topic (SurvivalGuide.openEntry). F1 opens it on
-- the topic for what you are doing (the active Character or World tab).
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Organisms"

ZeD = ZeD or {}
ZeD.Guide = ZeD.Guide or {}
local W = ZeD.Guide
W.windows = W.windows or {}

-- design units (1 px at 1080p; T.px scales them)
local U = {
    BODY_H = 580, LIST_W = 280, PAD = 10, HEAD_H = 40, MEASURE_CHARS = 66,
    CLIP_W = 640, PARA_GAP = 8, LINE_GAP = 3, RULES_PAD = 10, COL_GAP = 18, BAND_EDGE = 8, BAND_GAP = 8,
}
local CLIP_SRC_W, CLIP_SRC_H = 960, 480   -- the game's guide clips (Bink, 960 x 480)
-- the reading measure is the width of this many characters of ordinary English, spaces counted
-- (a pangram run on: real letters and spaces, not one letter repeated)
local MEASURE_SAMPLE = string.rep("the quick brown fox jumps over the lazy dog ", 3)

local function fh(font) return ZeD.TM:getFontHeight(font) end
local function tw(font, s) return ZeD.TM:MeasureStringX(font, s) end
-- (the game's measure leaves out spaces at the end of a string: measure them with a letter after)
local function twFull(font, s) return tw(font, s .. "x") - tw(font, "x") end
-- the width a run takes on the line, for the fit test: the larger of the two measures (QA, Nov 3 2026: on a Thai line
-- ending in a vowel mark the "x" trick came out 2 px short of the run measured as drawn)
local function twFit(font, s) return math.max(tw(font, s), twFull(font, s)) end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(name) pcall(function() getSoundManager():playUISound(name or "UIActivateButton") end) end
local function tr(k, ...) return ZeD.tr(k, ...) end
local function btnLabel(s) return ZeD.btnCase and ZeD.btnCase(s) or s end

local _fo = {}
local function focusOpts(win)
    _fo.win, _fo.focused, _fo.pad = win, true, true
    return _fo
end

-- ---------------------------------------------------------------------------
-- THE GAME'S TOPICS (SurvivalGuideEntry, in the game's order)
-- ---------------------------------------------------------------------------
-- A controller's button pictures in the game's text (<IMAGE:...XBOX_A.png...>) become the
-- button's name in brackets until the guide draws ZeD's own button pictures.
-- The game's text puts small pictures in its lines (<IMAGE:media/ui/...png,w,h>: a menu's icon, a
-- controller button). They become a marker (\1 path \1) that the reader passes through as text, and the
-- layout draws the picture in the line, a line's height square (QA, Nov 3 2026: "[Build_On_48]").
local MARK = "\1"
local function inlineImages(s)
    return (s:gsub("<%s*[Ii][Mm][Aa][Gg][Ee]%s*:%s*([^,>]+)[^>]*>", function(path)
        return MARK .. path:gsub("%s+$", "") .. MARK
    end))
end

-- KEYS AND BUTTONS IN THE TEXT (the director, Nov 4 2026: the guide follows the device you use: your own keys on
-- a keyboard, that controller's buttons on a controller, Xbox, PlayStation, Nintendo or Steam Deck). ZeD fills the
-- game's %1 %2 ... itself (entryText below) with markers the layout draws in the line: "key:<name>" a key cap (the
-- key's name in a frame, as the controller strip draws a key), "pad:<role>" ZeD's own button picture in the set the
-- glyph setting picks (ZeD_PadGlyphs), any other path a picture from the game. One object per marker, kept.
local _inl = {}
local function inlineTex(path)
    local o = _inl[path]
    if o == nil then
        local k = path:match("^key:(.+)$")
        local r = path:match("^pad:(.+)$")
        if k then o = { key = k }
        elseif r then o = { pad = { r } }
        else
            local t = getTexture(path)
            o = t and { tex = t } or false
        end
        _inl[path] = o
    end
    return o or nil
end

-- an inline thing's width at a line height s
local function inlineW(o, s)
    if o.tex then return s end
    local T = ZeD.T
    if o.key then return math.max(s, ZeD.TM:MeasureStringX(T.fontF5, o.key) + T.px(8)) end
    if o.pad then
        local G = ZeD.PadGlyphs
        local set = G and G.set()
        if set then return G.width(o.pad, G.k(s), set) end
        return math.max(s, ZeD.TM:MeasureStringX(T.fontF5, G and G.name(o.pad[1]) or o.pad[1]) + T.px(8))
    end
    return s
end

-- draws one in a line, s tall at (x, y); ink the text's colour; pal the button pictures' colours (nil: ZeD.T)
local function inlineDraw(panel, o, x, y, s, ink, pal)
    if o.tex then panel:drawTextureScaledAspect(o.tex, x, y, s, s, 1, 1, 1, 1); return end
    local T = ZeD.T
    local G = ZeD.PadGlyphs
    local set = o.pad and G and G.set()
    if set then G.draw(panel, o.pad, x, y, s, G.k(s), set, pal); return end
    local name = o.key or (G and G.name(o.pad[1]) or o.pad[1])
    local w = inlineW(o, s)
    ZeD.Atoms.frame(panel, x, y, w, s, ink)
    local f5 = T.fontF5
    local fh = ZeD.TM:getFontHeight(f5)
    panel:drawText(name, x + math.floor((w - ZeD.TM:MeasureStringX(f5, name)) / 2), y + math.floor((s - fh) / 2), ink.r, ink.g, ink.b, ink.a or 1, f5)
end

-- the game's controller names (its <JOYPAD:...> markup) as ZeD's button roles
local PAD_ROLE = { AButton = "A", BButton = "B", XButton = "X", YButton = "Y", LBumper = "LB", RBumper = "RB",
    LTrigger = "LT", RTrigger = "RT", LStick = "LS", RStick = "RS", DPadUp = "DU", DPadDown = "DD", DPadLeft = "DL",
    DPadRight = "DR", DPad = "DPAD", Menu = "START", Start = "START", View = "SEL", Back = "SEL", Select = "SEL" }

-- a key's name as the game names it
local function keyName(code)
    local ok, n = pcall(function() return getKeyName(code) end)
    if ok and n and n ~= "" then return tostring(n) end
    return tostring(code)
end

-- one of an entry's keys as text for its %n: the game's words (IGUI_...), a button picture, a game picture, or a
-- binding as your key cap (and its second key, "or", when it has one); as the game's own SurvivalGuideEntry does
local function argFor(k)
    k = tostring(k)
    if k:find("IGUI_", 1, true) then return getText(k) end
    local jp = k:match("<JOYPAD:%s*([%w_]+)")
    if jp then
        local r = PAD_ROLE[jp]
        return r and (MARK .. "pad:" .. r .. MARK) or ""
    end
    if k:find("<IMAGE", 1, true) then return k end
    local core = getCore()
    local ok, code = pcall(function() return core:getKey(k) end)
    if not ok or not code or code == 0 then return k end
    local s = MARK .. "key:" .. keyName(code) .. MARK
    local ok2, alt = pcall(function() return core:getAltKey(k) end)
    if ok2 and alt and alt ~= 0 and alt ~= code then s = s .. " " .. getText("ContextMenu_or") .. " " .. MARK .. "key:" .. keyName(alt) .. MARK end
    return s
end

-- TWO WAYS (the director, Nov 4 2026: every page that teaches an action closes with "Mouse and keyboard |
-- Controller", one short line per action). Read from the entry itself: the game gives each topic its keyboard keys
-- and its controller buttons as two lists in the same order (the %1 %2 of its two texts), so row n pairs the two.
-- A row's name is the game's own name for the binding (UI_optionscreen_binding_<name>, translated by the game);
-- a mouse button or a picture has no name of its own and the row shows its keys only. Rows that are only pictures
-- (the game's sidebar icons) and repeats are left out; a topic with no keys has no box.
-- Each row: { label | nil, kb = { inline objects }, pad = { inline objects } }.
local function cellFor(k)
    local out = {}
    if not k then return out end
    k = tostring(k)
    if k:find("<IMAGE", 1, true) then
        local path = k:match("<IMAGE:%s*([^,>]+)")
        local o = path and inlineTex((path:gsub("%s+$", "")))
        if o then out[1] = o end
        return out
    end
    local jp = k:match("<JOYPAD:%s*([%w_]+)")
    if jp then
        local r = PAD_ROLE[jp]
        if r then out[1] = inlineTex("pad:" .. r) end
        return out
    end
    if k:find("IGUI_", 1, true) then out[1] = inlineTex("key:" .. getText(k)); return out end
    local core = getCore()
    local ok, code = pcall(function() return core:getKey(k) end)
    if not ok or not code or code == 0 then return out end
    out[1] = inlineTex("key:" .. keyName(code))
    local ok2, alt = pcall(function() return core:getAltKey(k) end)
    if ok2 and alt and alt ~= 0 and alt ~= code then out[2] = inlineTex("key:" .. keyName(alt)) end
    return out
end
local function isInput(k)
    if not k then return false end
    k = tostring(k)
    return not k:find("<IMAGE", 1, true)
end
local function zedWays(t)
    local td = t.zed
    local rows = {}
    -- (a page's own rows: words on both sides)
    for _, r in ipairs(td.ways or {}) do
        rows[#rows + 1] = { kbText = W.fillTokens(tr(r[1])), padText = W.fillTokens(tr(r[2])) }
    end
    -- (the game topics' own rows, for the game's actions)
    for _, tk in ipairs(td.waysFrom or {}) do
        local gt = W._byTitle and W._byTitle[tk]
        for _, r in ipairs((gt and W.twoWays(gt)) or {}) do rows[#rows + 1] = r end
    end
    -- (every key binding, as set now)
    if td.keys and keyBinding then
        for _, b in ipairs(keyBinding) do
            local v = b.value and tostring(b.value) or ""
            if v ~= "" and not v:find("^%[") then
                local ok, code = pcall(function() return getCore():getKey(v) end)
                if ok and code and code ~= 0 then
                    rows[#rows + 1] = { label = getTextOrNull("UI_optionscreen_binding_" .. v) or v, kb = { inlineTex("key:" .. keyName(code)) }, pad = {} }
                end
            end
        end
    end
    return (#rows > 0) and rows or nil
end

local function twoWays(t)
    if t and t.zed then return zedWays(t) end
    local e = t and t.entry
    if not e then return nil end
    local ok, kb, jp = pcall(function() return e:getKeys(), e:getJoypadKeys() end)
    if not ok then return nil end
    local nk, nj = kb and kb:size() or 0, jp and jp:size() or 0
    local rows, seen = {}, {}
    if nk ~= nj and nk > 0 and nj > 0 then
        local row = { kb = {}, pad = {} }
        for i = 0, nk - 1 do
            local a = tostring(kb:get(i))
            if isInput(a) then for _, o in ipairs(cellFor(a)) do row.kb[#row.kb + 1] = o end end
        end
        for i = 0, nj - 1 do
            local b = tostring(jp:get(i))
            if b:find("<JOYPAD", 1, true) then for _, o in ipairs(cellFor(b)) do row.pad[#row.pad + 1] = o end end
        end
        if #row.kb > 0 or #row.pad > 0 then return { row } end
        return nil
    end
    for i = 0, math.max(nk, nj) - 1 do
        local a = (i < nk) and tostring(kb:get(i)) or nil
        local b = (i < nj) and tostring(jp:get(i)) or nil
        if isInput(a) or (b and b:find("<JOYPAD", 1, true)) then
            local id = tostring(a) .. "|" .. tostring(b)
            if not seen[id] then
                seen[id] = true
                local label = nil
                if a and not a:find("[<_]") then
                    local key = "UI_optionscreen_binding_" .. a
                    local s = getTextOrNull(key)
                    label = s or a
                end
                local row = { label = label, kb = cellFor(a), pad = cellFor(b) }
                if #row.kb > 0 or #row.pad > 0 then rows[#rows + 1] = row end
            end
        end
    end
    return (#rows > 0) and rows or nil
end
W.twoWays = twoWays

local STANDIN = {}
for i = 1, 9 do STANDIN[i] = "\2" .. i .. "\2" end

-- an entry's text for the device in use: the controller's own words and buttons (description_joypad) when the player
-- is on a controller and the game has them, else the keyboard's words and keys. nil: an entry the game hides.
local function entryText(e, joy)
    local desc = e:getDescription()
    if not desc then return nil end
    local raw, keys = nil, nil
    -- (the game's text has %1$s ... for its keys: it is asked with stand-ins \2 n \2 (asked with none, it warned
    -- once a topic, QA Nov 4 2026), which are then filled with ZeD's markers)
    local S = STANDIN
    if joy then
        raw = getTextOrNull(desc .. "_joypad", S[1], S[2], S[3], S[4], S[5], S[6], S[7], S[8], S[9])
        if raw then keys = e:getJoypadKeys() end
    end
    if not raw then raw, keys = getTextOrNull(desc, S[1], S[2], S[3], S[4], S[5], S[6], S[7], S[8], S[9]), e:getKeys() end
    if not raw or raw == "<IGNORE>" then return nil end
    local args = {}
    for i = 0, (keys and keys:size() or 0) - 1 do args[i + 1] = argFor(keys:get(i)) end
    raw = raw:gsub("\2(%d)\2%$s", function(d) return args[tonumber(d or "")] or "" end)
    raw = raw:gsub("\2(%d)\2", function(d) return args[tonumber(d or "")] or "" end)
    -- (a %n the game left as it was, with or without its $s)
    raw = raw:gsub("%%(%d)%$s", function(d) return args[tonumber(d or "")] or "" end)
    return (raw:gsub("%%(%d)", function(d) return args[tonumber(d or "")] or "" end))
end

-- Japanese and Chinese line breaking (kinsoku, QA Nov 4 2026: a "。" started a line): these never start a line
-- (closing marks, the long-vowel mark, small kana) and these never end one (opening marks); by code point, since
-- non-ASCII literals do not survive in a .lua file
local NO_START, NO_END = {}, {}
for _, c in ipairs({ 0x3001, 0x3002, 0xFF0C, 0xFF0E, 0xFF01, 0xFF1F, 0xFF1A, 0xFF1B, 0x300D, 0x300F, 0xFF09, 0x3015,
    0x3011, 0x3009, 0x300B, 0x30FC, 0x30FB, 0x3005, 0x3041, 0x3043, 0x3045, 0x3047, 0x3049, 0x3063, 0x3083, 0x3085,
    0x3087, 0x308E, 0x30A1, 0x30A3, 0x30A5, 0x30A7, 0x30A9, 0x30C3, 0x30E3, 0x30E5, 0x30E7, 0x30EE, 0x30F5, 0x30F6 }) do
    NO_START[c] = true
end
for _, c in ipairs({ 0x300C, 0x300E, 0xFF08, 0x3014, 0x3010, 0x3008, 0x300A }) do NO_END[c] = true end

-- a paragraph wrapped at maxW: lines of runs ({ text, x } or { tex, x, s }), x from the line's start
local function wrapRuns(para, font, maxW)
    local s = fh(font)
    local atoms = {}
    local i = 1
    while i <= #para do
        local a = para:find(MARK, i, true)
        local textPart = para:sub(i, (a or (#para + 1)) - 1)
        for word in textPart:gmatch("%s*%S+%s*") do
            local ww = twFull(font, word)
            if ww > maxW then
                -- a word wider than the line (Japanese, Chinese, Korean and Thai write a sentence without
                -- spaces: QA, Nov 3 2026) breaks between its characters (Kahlua strings are UTF-16: one
                -- character per sub)
                -- Thai: a letter keeps its vowel and tone marks, and a leading vowel keeps the letter after it
                -- (QA: "อีก" broke after its vowel mark)
                local piece, lead = "", false
                for k = 1, #word do
                    local ch = word:sub(k, k)
                    local c = string.byte(ch) or 0
                    local mark = c == 0x0E31 or (c >= 0x0E34 and c <= 0x0E3A) or (c >= 0x0E47 and c <= 0x0E4E)
                    -- (Japanese and Chinese: a closing mark stays with the character before it, an opening mark
                    -- with the one after)
                    if piece ~= "" and not mark and not lead and not NO_START[c] then
                        atoms[#atoms + 1] = { text = piece, w = twFull(font, piece) }
                        piece = ""
                    end
                    piece = piece .. ch
                    lead = (c >= 0x0E40 and c <= 0x0E44) or NO_END[c] == true
                end
                if piece ~= "" then atoms[#atoms + 1] = { text = piece, w = twFull(font, piece) } end
            else
                atoms[#atoms + 1] = { text = word, w = ww }
            end
        end
        if not a then break end
        local b = para:find(MARK, a + 1, true)
        if not b then break end
        local tex = inlineTex(para:sub(a + 1, b - 1))
        if tex then atoms[#atoms + 1] = { tex = tex, w = inlineW(tex, s) + ZeD.T.px(4) } end
        i = b + 1
    end
    local lines, cur, x = {}, {}, 0
    local function push() lines[#lines + 1] = cur; cur, x = {}, 0 end
    for _, at in ipairs(atoms) do
        if at.tex then
            if x > 0 and x + at.w > maxW then push() end
            cur[#cur + 1] = { tex = at.tex, x = x, s = s }
            x = x + at.w
        else
            local last = cur[#cur]
            local text = at.text
            if x == 0 then text = text:gsub("^%s+", "") end
            if last and last.text then
                -- (a picture the game could not find leaves no double space)
                if last.text:sub(-1) == " " then text = text:gsub("^%s+", "") end
                local joined = last.text .. text
                -- the run measured whole, its trailing space aside: pieces measured one by one add up a pixel or
                -- two short of the joined line (QA, Nov 3 2026: a Thai line 2 px past the measure)
                if last.x + twFit(font, (joined:gsub("%s+$", ""))) > maxW then
                    push()
                    text = at.text:gsub("^%s+", "")
                    cur[1] = { text = text, x = 0 }
                    x = twFull(font, text)
                else
                    last.text = joined
                    x = last.x + twFull(font, joined)
                end
            else
                if x > 0 and x + twFit(font, (text:gsub("%s+$", ""))) > maxW then
                    push()
                    text = at.text:gsub("^%s+", "")
                end
                cur[#cur + 1] = { text = text, x = x }
                x = x + twFull(font, text)
            end
        end
    end
    if #cur > 0 then push() end
    return lines
end

-- the topic's text as paragraphs (the game's <LINE> breaks), plain words
local function paragraphs(text)
    local out = {}
    local P = ZeD.Prompt
    local src = inlineImages(tostring(text or ""))
    if P and P.parseRich then
        for _, bl in ipairs(P.parseRich(src)) do
            if bl.kind ~= "image" and bl.text and bl.text ~= "" then out[#out + 1] = bl.text end
        end
    else
        for part in (src .. "<LINE>"):gmatch("(.-)<LINE>") do
            part = part:gsub("<[^>]*>", ""):gsub("^%s+", ""):gsub("%s+$", "")
            if part ~= "" then out[#out + 1] = part end
        end
    end
    return out
end

-- the sections and their topics; rebuilt on each open (the controller changes the words)
local function readTopics(joy)
    local sections, byId, flat = {}, {}, {}
    local ok, entries = pcall(function() return SurvivalGuideEntry.getAll() end)
    if not ok or not entries then return sections, byId, flat end
    local cur = nil
    for i = 0, entries:size() - 1 do
        local e = entries:get(i)
        local id = tostring(e)
        local titleKey = e:getTitle()
        if not e:getSubCategory() then
            cur = { id = id, title = getText(titleKey), titleKey = titleKey, topics = {} }
            sections[#sections + 1] = cur
        elseif cur then
            local text = entryText(e, joy)
            if text then
                local t = { id = id, entry = e, section = cur, title = getText(titleKey), titleKey = titleKey,
                            text = text, video = e:getVideo(), thumb = e:getThumbnail() }
                cur.topics[#cur.topics + 1] = t
                byId[id] = t
                flat[#flat + 1] = t
            end
        end
    end
    -- ZeD's chapters (ZeD_GuideChapters, made by ZeDUI/tools/guide/chapters.py), after the game's
    W._byTitle = {}
    for _, t in ipairs(flat) do W._byTitle[t.titleKey] = t end
    for _, ch in ipairs(ZeD.GuideChapters or {}) do
        local sec = { id = "zedch:" .. ch.id, title = tr(ch.title), titleKey = ch.title, blurbKey = ch.blurb, topics = {}, zed = true }
        sections[#sections + 1] = sec
        for _, td in ipairs(ch.topics or {}) do
            local id = sec.id .. ":" .. td.id
            local t = { id = id, section = sec, title = tr(td.title), titleKey = td.title, text = W.fillTokens(tr(td.text)), zed = td }
            sec.topics[#sec.topics + 1] = t
            byId[id] = t
            flat[#flat + 1] = t
        end
    end
    return sections, byId, flat
end

-- the tokens of ZeD's chapters as the markers the layout draws: {bind:KEYBIND_ID} {key:Binding id} {pad:A}
-- {mouse:0} {lit:Esc} (ZeDUI/tools/guide/chapters.py)
function W.fillTokens(s)
    s = tostring(s or "")
    -- (one capture, split here: Kahlua hands a second capture to the function as nil, QA Nov 4 2026)
    return (s:gsub("{(%a+:[^}]+)}", function(tok)
        tok = tostring(tok or "")
        local c = tok:find(":", 1, true)
        if not c then return "" end
        local kind, v = tok:sub(1, c - 1), tok:sub(c + 1)
        if kind == "pad" then return MARK .. "pad:" .. v .. MARK end
        if kind == "lit" then return MARK .. "key:" .. v .. MARK end
        if kind == "mouse" then return MARK .. "key:" .. getText("IGUI_mouse_btn_" .. v) .. MARK end
        local id = v
        if kind == "bind" then
            local ok, r = pcall(function() return KeybindId[v]:getId() end)
            id = ok and r or v
        end
        local ok, code = pcall(function() return getCore():getKey(id) end)
        if ok and code and code ~= 0 then return MARK .. "key:" .. keyName(code) .. MARK end
        return ""
    end))
end

-- ---------------------------------------------------------------------------
-- THE RULES IN NUMBERS (read from the game; nothing about this world's secrets)
-- ---------------------------------------------------------------------------
local Rules = {}
W.Rules = Rules

-- A topic's rules: Rules[titleKey]() gives one table ({ cols, rows, notes, title?, spoiler? }) or a list of them.
-- A table with spoiler = true (a world's setting some players would rather find out for themselves: the shutoff,
-- the helicopter, the infection's timing; the director, Nov 4 2026) shows a grey bar, "Show the numbers", until the
-- player asks (a click, or A); it stays shown while the guide is open (W.spoil, emptied when the guide opens).
W.spoil = W.spoil or {}
W._rulesC = W._rulesC or {}
function W.rulesList(t)
    local rf = t and Rules[t.titleKey]
    if not rf then return nil end
    local c = W._rulesC[t.titleKey]
    if c ~= nil then return c or nil end
    local ok, r = pcall(rf)
    if not ok or not r then W._rulesC[t.titleKey] = false; return nil end
    if r.cols then r = { r } end
    W._rulesC[t.titleKey] = (#r > 0) and r or false
    return (#r > 0) and r or nil
end
function W._rulesListRaw(t)
    local rf = t and Rules[t.titleKey]
    if not rf then return nil end
    local ok, r = pcall(rf)
    if not ok or not r then return nil end
    if r.cols then return { r } end
    return (#r > 0) and r or nil
end
function W.spoilKey(t, i) return tostring(t and t.titleKey) .. "#" .. tostring(i) end
function W.spoilHidden(t, i, tb) return tb.spoiler and not W.spoil[W.spoilKey(t, i)] end
-- shows every hidden table of a topic; true when there was one
function W.showSpoilers(t)
    local list = W.rulesList(t)
    local any = false
    for i, tb in ipairs(list or {}) do
        if W.spoilHidden(t, i, tb) then W.spoil[W.spoilKey(t, i)] = true; any = true end
    end
    return any
end

-- Skill Books: what each volume covers (the books' scripts) and multiplies (SkillBook, the
-- game's reading rules); the skills that read slower named from the game's perks.
-- a multiplier as the share of normal XP: 3 is 300%, 1.5 is 150%
local function pct(m) return tostring(math.floor((tonumber(m) or 1) * 100 + 0.5)) .. "%" end

Rules.SurvivalGuide_skill_books_title = function()
    if not SkillBook then return nil end
    local groups, order = {}, {}
    for key, sb in pairs(SkillBook) do
        if type(sb) == "table" and sb.maxMultiplier1 then
            local sig = table.concat({ sb.maxMultiplier1, sb.maxMultiplier2, sb.maxMultiplier3, sb.maxMultiplier4, sb.maxMultiplier5 }, ",")
            if not groups[sig] then groups[sig] = { sig = sig, m = { sb.maxMultiplier1, sb.maxMultiplier2, sb.maxMultiplier3, sb.maxMultiplier4, sb.maxMultiplier5 }, names = {} }; order[#order + 1] = sig end
            local name = key
            pcall(function() name = PerkFactory.getPerk(sb.perk):getName() end)
            table.insert(groups[sig].names, name)
        end
    end
    if #order == 0 then return nil end
    table.sort(order, function(a, b) return #groups[a].names > #groups[b].names end)
    local main = groups[order[1]]
    local others = {}
    for i = 2, #order do others[#others + 1] = groups[order[i]] end
    for _, g in ipairs(others) do table.sort(g.names) end
    -- the levels each volume covers, from any book of the main group (Carpentry first)
    local levels = {}
    local sm = ScriptManager and ScriptManager.instance
    for v = 1, 5 do
        pcall(function()
            local it = sm and sm:getItem("Base.BookCarpentry" .. v)
            if it then
                local lo, n = it:getLevelSkillTrained(), it:getNumLevelsTrained()
                if lo and n and n > 0 then levels[v] = { lo = lo, hi = lo + n - 1 } end
            end
        end)
    end
    local cols = { tr("UI_ZeD_Guide_SB_Vol"), tr("UI_ZeD_Guide_SB_Levels"), tr("UI_ZeD_Guide_SB_Most") }
    for _, g in ipairs(others) do cols[#cols + 1] = table.concat(g.names, ", ") end
    local rows = {}
    for v = 1, 5 do
        local r = { tostring(v), levels[v] and tr("UI_ZeD_Guide_SB_LevelRange", levels[v].lo, levels[v].hi) or "", pct(main.m[v]) }
        for _, g in ipairs(others) do r[#r + 1] = pct(g.m[v]) end
        rows[#rows + 1] = r
    end
    -- the multipliers as plain numbers (the director, Nov 3 2026: "people don't understand what [x3] means")
    local m1 = tonumber(main.m[1]) or 1
    local notes = { tr("UI_ZeD_Guide_SB_Percent", pct(m1), tostring(math.floor(10 * m1 + 0.5))),
                    tr("UI_ZeD_Guide_SB_Covers"), tr("UI_ZeD_Guide_SB_Partial") }
    if #others > 0 then notes[#notes + 1] = tr("UI_ZeD_Guide_SB_Which", #main.names) end
    return { cols = cols, rows = rows, notes = notes }
end

-- ---------------------------------------------------------------------------
-- MORE RULES (the director, Nov 4 2026: your body, food and health, skills and traits, things you run). Every number
-- read from the game or this world's settings (research: what Lua can read in 42.22); what cannot be read that way is
-- left out. A world's settings that some players would rather find out sit behind the spoiler bar.
-- ---------------------------------------------------------------------------
local function sbOpt(name)
    local ok, o = pcall(function() return getSandboxOptions():getOptionByName(name) end)
    return ok and o or nil
end
-- a world setting's name and its choice in the game's words (nil when the game has no such setting)
local function sbChoice(name)
    local o = sbOpt(name)
    if not o then return nil end
    local ok, label, val = pcall(function()
        local v
        if o.getValueTranslationByIndex then v = o:getValueTranslationByIndex(o:getValue()) else v = tostring(o:getValue()) end
        return o:getTranslatedName(), v
    end)
    if not ok then return nil end
    return tostring(label), tostring(val)
end
local function sbNumber(name)
    local o = sbOpt(name)
    if not o then return nil end
    local ok, label, v = pcall(function() return o:getTranslatedName(), o:getValue() end)
    if not ok then return nil end
    return tostring(label), v
end
local function fmt(n)
    n = tonumber(n) or 0
    if n == math.floor(n) then return tostring(math.floor(n)) end
    return string.format("%.1f", n)
end
local function perkLabel(pk)
    local ok, n = pcall(function() return pk:getName() end)
    return ok and tostring(n) or tostring(pk)
end
-- a definition's skill boosts as words: "Carpentry +4, Carving +1"
local function boostsOf(def)
    local out = {}
    pcall(function()
        local t = transformIntoKahluaTable(def:getXpBoosts())
        for pk, lv in pairs(t or {}) do out[#out + 1] = perkLabel(pk) .. " +" .. tostring(lv) end
    end)
    table.sort(out)
    return table.concat(out, ", ")
end

-- Character: the XP each level takes (the game's own getter: it scales its listed numbers when it starts), skills
-- with the same steps grouped; occupations and traits as on the character screen
local function skillTables()
    local out = {}
    local groups, order = {}, {}
    pcall(function()
        local L = PerkFactory.PerkList
        for i = 0, L:size() - 1 do
            local pk = L:get(i)
            if pk:getParent() ~= Perks.None then
                local seq = {}
                for n = 1, 10 do seq[n] = pk:getXpForLevel(n) end
                local id = table.concat(seq, ",")
                if not groups[id] then groups[id] = { seq = seq, names = {} }; order[#order + 1] = id end
                local gn = groups[id].names
                gn[#gn + 1] = perkLabel(pk)
            end
        end
    end)
    if #order > 0 then
        table.sort(order, function(a, b) return #groups[a].names > #groups[b].names end)
        local cols = { tr("UI_ZeD_Rules_Level") }
        for gi, id in ipairs(order) do
            local g = groups[id]
            cols[#cols + 1] = (gi == 1 and #g.names > 3) and tr("UI_ZeD_Rules_MostSkills") or table.concat(g.names, ", ")
        end
        local rows = {}
        for n = 1, 10 do
            local r = { tostring(n) }
            for _, id in ipairs(order) do r[#r + 1] = fmt(groups[id].seq[n]) end
            rows[#rows + 1] = r
        end
        local notes = {}
        local label, v = sbNumber("MultiplierConfig.Global")
        if label then notes[#notes + 1] = tr("UI_ZeD_Rules_WorldIs", label, fmt(v)) end
        out[#out + 1] = { title = tr("UI_ZeD_Rules_XPTitle"), cols = cols, rows = rows, notes = notes }
    end
    local occ = {}
    pcall(function()
        local L = CharacterProfessionDefinition.getProfessions()
        for i = 0, L:size() - 1 do
            local d = L:get(i)
            occ[#occ + 1] = { tostring(d:getUIName()), tostring(d:getCost()), boostsOf(d) }
        end
    end)
    if #occ > 0 then
        table.sort(occ, function(a, b) return a[1] < b[1] end)
        out[#out + 1] = { title = tr("UI_ZeD_Rules_OccTitle"), cols = { tr("UI_ZeD_Rules_Occupation"), tr("UI_ZeD_Rules_Points"), tr("UI_ZeD_Rules_Skills") }, rows = occ,
                          notes = { tr("UI_ZeD_Rules_OccNote") } }
    end
    local tra = {}
    pcall(function()
        local L = CharacterTraitDefinition.getTraits()
        for i = 0, L:size() - 1 do
            local d = L:get(i)
            if not d:isFree() then tra[#tra + 1] = { tostring(d:getUIName()), tostring(d:getCost()), boostsOf(d) } end
        end
    end)
    if #tra > 0 then
        table.sort(tra, function(a, b) return a[1] < b[1] end)
        out[#out + 1] = { title = tr("UI_ZeD_Rules_TraitTitle"), cols = { tr("UI_ZeD_Rules_Trait"), tr("UI_ZeD_Rules_Points"), tr("UI_ZeD_Rules_Skills") }, rows = tra,
                          notes = { tr("UI_ZeD_Rules_TraitNote") } }
    end
    return (#out > 0) and out or nil
end

-- Food and water: how long the food you carry keeps and what it gives (its script); this world's rot and fridge
-- settings named, not multiplied in (the game's multipliers are not readable)
-- (rules hang on a topic, never a chapter's opener: QA Nov 4 2026, the tables never showed)
Rules.SurvivalGuide_eating_drinking_title = function()
    local p = getSpecificPlayer(0)
    if not p then return nil end
    local rows, seen = {}, {}
    pcall(function()
        local items = ArrayList.new()
        p:getInventory():getAllCategoryRecurse("Food", items)
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            local ft = it:getFullType()
            if not seen[ft] then
                seen[ft] = true
                local sc = it:getScriptItem()
                local fresh, rot = sc and sc:getDaysFresh() or 0, sc and sc:getDaysTotallyRotten() or 0
                local kcal = 0
                pcall(function() kcal = it:getCalories() end)
                rows[#rows + 1] = { tostring(it:getDisplayName()), (fresh > 0 and fresh < 1000000) and fmt(fresh) or "-", (rot > 0 and rot < 1000000) and fmt(rot) or "-", fmt(kcal) }
            end
        end
    end)
    if #rows == 0 then return nil end
    table.sort(rows, function(a, b) return a[1] < b[1] end)
    local notes = {}
    for _, name in ipairs({ "FoodRotSpeed", "FridgeFactor" }) do
        local label, val = sbChoice(name)
        if label then notes[#notes + 1] = tr("UI_ZeD_Rules_WorldIs", label, val) end
    end
    return { title = tr("UI_ZeD_Rules_FoodTitle"), cols = { tr("UI_ZeD_Rules_Food"), tr("UI_ZeD_Rules_Fresh"), tr("UI_ZeD_Rules_Rotten"), tr("UI_ZeD_Rules_Calories") },
             rows = rows, notes = notes }
end

-- Farming: each crop's hours a growth stage at this world's farming speed, the water it needs and its harvest
-- (the game's farming table, there once a game runs)
Rules.SurvivalGuide_sow_seeds_title = function()
    local conf = farming_vegetableconf and farming_vegetableconf.props
    if not conf then return nil end
    local speed = 1
    pcall(function() speed = getSandboxOptions():getOptionByName("FarmingSpeedNew"):getValue() end)
    if not speed or speed <= 0 then speed = 1 end
    local rows = {}
    for name, pr in pairs(conf) do
        if type(pr) == "table" and pr.timeToGrow then
            local crop = getTextOrNull("Farming_" .. tostring(name)) or tostring(name)
            local water = pr.waterLvl and (tostring(pr.waterLvl) .. "%") or "-"
            local yield = (pr.minVeg and pr.maxVeg) and (tostring(pr.minVeg) .. "-" .. tostring(pr.maxVeg)) or "-"
            rows[#rows + 1] = { crop, fmt(pr.timeToGrow / speed), water, yield }
        end
    end
    if #rows == 0 then return nil end
    table.sort(rows, function(a, b) return a[1] < b[1] end)
    local notes = {}
    local label, v = sbNumber("FarmingSpeedNew")
    if label then notes[#notes + 1] = tr("UI_ZeD_Rules_WorldIs", label, fmt(v)) end
    notes[#notes + 1] = tr("UI_ZeD_Rules_CropNote")
    return { title = tr("UI_ZeD_Rules_CropTitle"), cols = { tr("UI_ZeD_Rules_Crop"), tr("UI_ZeD_Rules_HoursStage"), tr("UI_ZeD_Rules_Water"), tr("UI_ZeD_Rules_Harvest") },
             rows = rows, notes = notes }
end

-- this world's settings as ranges: the shutoff windows, the helicopter, how the infection works (spoilers: the
-- choice's words only, never the day the world rolled)
local function worldRows(names)
    local rows = {}
    for _, name in ipairs(names) do
        local label, val = sbChoice(name)
        if label then rows[#rows + 1] = { label, val } end
    end
    return rows
end
-- Skill Books: the books' own table, then XP for each level, occupations and traits (all about skills)
do
    local books = Rules.SurvivalGuide_skill_books_title
    Rules.SurvivalGuide_skill_books_title = function()
        local out = {}
        local ok, b = pcall(books)
        if ok and b then
            if b.cols then out[1] = b else for _, t in ipairs(b) do out[#out + 1] = t end end
        end
        for _, t in ipairs(skillTables() or {}) do out[#out + 1] = t end
        return (#out > 0) and out or nil
    end
end

Rules.SurvivalGuide_treat_water_title = function()
    local rows = worldRows({ "WaterShut", "ElecShut", "Helicopter" })
    if #rows == 0 then return nil end
    return { title = tr("UI_ZeD_Rules_WorldTitle"), cols = { tr("UI_ZeD_Rules_Setting"), tr("UI_ZeD_Rules_ThisWorld") }, rows = rows,
             notes = { tr("UI_ZeD_Rules_WorldNote") }, spoiler = true }
end
Rules.SurvivalGuide_zombie_attacks_title = function()
    local rows = worldRows({ "ZombieLore.Transmission", "ZombieLore.Mortality", "ZombieLore.Reanimate" })
    if #rows == 0 then return nil end
    return { title = tr("UI_ZeD_Rules_InfTitle"), cols = { tr("UI_ZeD_Rules_Setting"), tr("UI_ZeD_Rules_ThisWorld") }, rows = rows,
             notes = { tr("UI_ZeD_Rules_InfNote") }, spoiler = true }
end

-- ---------------------------------------------------------------------------
-- THE WINDOW
-- ---------------------------------------------------------------------------
ZeD_GuideWindow = ZeD_Window:derive("ZeD_GuideWindow")

function ZeD_GuideWindow:new(playerNum)
    local o = ZeD_Window.new(self, 0, 0, 100, 100, "")
    o.resizable = false
    o.pin = true
    o.anchorLeft, o.anchorRight, o.anchorTop, o.anchorBottom = true, false, true, false
    o.moveWithMouse = false
    o.playerNum = playerNum or 0
    o.sel = nil           -- the chosen topic's id
    o.closed = {}         -- folded sections (by id)
    o.find = ""           -- the Find text
    o.listScroll = 0      -- px
    o.scroll = 0          -- the topic's scroll, px
    o.zone = "list"       -- controller: "list" | "text" | "foot"
    o.listFocus = nil     -- controller: the row id ("s:<id>" a section, a topic id)
    o.footFocus = 3       -- controller: 1 the start-up box, 2 Previous, 3 Next
    o._hover = nil
    o._down = nil
    o:setWantKeyEvents(true)
    return o
end

function ZeD_GuideWindow:createChildren()
    ZeD_Window.createChildren(self)
    self.minimumWidth, self.minimumHeight = 0, 0
    local T = ZeD.T
    local f = ZeD_SearchField:new(0, 0, T.px(200), tr("UI_ZeD_Guide_Find"))
    f:initialise()
    local win = self
    f.onFilter = function(_, text)
        win.find = text or ""
        win.listScroll = 0
    end
    self:addChild(f)
    self._findField = f
end

-- true while this player is on a controller (the guide's words and buttons follow it as it changes)
function W.onPad(pn)
    return JoypadState and JoypadState.players and JoypadState.players[(pn or 0) + 1] ~= nil or false
end

function ZeD_GuideWindow:readTopics()
    local joy = W.onPad(self.playerNum)
    self._joyRead = joy
    self.sections, self.byId, self.flat = readTopics(joy)
    if not (self.sel and self.byId[self.sel]) then self.sel = self.flat[1] and self.flat[1].id or nil end
    self._clip, self._clipFor = nil, nil
end

function ZeD_GuideWindow:choose(id, noSound)
    local t = id and self.byId and self.byId[id]
    if not t then return end
    if self.sel ~= id then self.scroll = 0 end
    self.sel = id
    self.closed[t.section.id] = nil
    self.listFocus = id
    self._jumpList = true
    if not noSound then sound("UISelectListItem") end
end

-- the topic before or after the chosen one, in the game's order
function ZeD_GuideWindow:step(d)
    local flat = self.flat or {}
    if #flat == 0 then return end
    local at = 1
    for i, t in ipairs(flat) do if t.id == self.sel then at = i end end
    -- (Kahlua's % keeps the sign of a negative number: add the count first)
    local n = ((at - 1 + d + #flat) % #flat) + 1
    self:choose(flat[n].id)
end

-- ---------------------------------------------------------------------------
-- LAYOUT (every frame from the live tokens; local px)
-- ---------------------------------------------------------------------------
local function matches(t, q)
    if q == "" then return true end
    return string.lower(t.title):find(q, 1, true) ~= nil or string.lower(t.text):find(q, 1, true) ~= nil
end

function ZeD_GuideWindow:buildList(g)
    local T = ZeD.T
    local px = T.px
    local q = string.lower(self.find or "")
    local y = g.list.y - self.listScroll
    local rowH = T.rowH
    local catH = px(24)
    g.rows = {}
    for _, s in ipairs(self.sections or {}) do
        local shown = {}
        for _, t in ipairs(s.topics) do if matches(t, q) then shown[#shown + 1] = t end end
        if q == "" or #shown > 0 then
            local folded = q == "" and self.closed[s.id]
            g.rows[#g.rows + 1] = { x = 0, y = y, w = g.list.w, h = catH, section = s, count = #shown, folded = folded, id = "s:" .. s.id }
            y = y + catH
            if not folded then
                for _, t in ipairs(shown) do
                    g.rows[#g.rows + 1] = { x = 0, y = y, w = g.list.w, h = rowH, topic = t, id = t.id }
                    y = y + rowH
                end
            end
        end
    end
    return y + self.listScroll - g.list.y
end

-- the chosen topic laid out at width cw: the clip, the paragraphs, the rules
function ZeD_GuideWindow:buildTopic(g, cx, cw)
    local T = ZeD.T
    local A = ZeD.Atoms
    local px = T.px
    local t = self.byId and self.byId[self.sel]
    local items = {}
    local y = 0
    g.topic = t
    if not t then g.items, g.topicH = items, 0; return 0 end
    if t.video and t.video ~= "" then
        local w = math.min(cw, px(U.CLIP_W))
        local h = math.floor(w * CLIP_SRC_H / CLIP_SRC_W)
        items[#items + 1] = { kind = "clip", x = cx, y = y, w = w, h = h }
        y = y + h + px(U.PARA_GAP) * 2
    end
    -- the two ways: a three-column table (what, mouse and keyboard, controller), one line an action
    local function waysBox()
    local ways = twoWays(t)
    if ways then
        y = y + ((y > 0) and px(U.PARA_GAP) * 2 or 0)
        local pad = px(U.RULES_PAD)
        local s = fh(T.fontF2)
        local box = { kind = "ways", x = cx, y = y, w = cw, rows = {}, s = s }
        local inner = cw - pad * 2
        local colW = math.floor(inner / 3)
        box.colX = { cx + pad, cx + pad + colW, cx + pad + colW * 2 }
        box.colW = colW
        local ry = y + pad
        box.headY = ry
        box.heads = { tr("UI_ZeD_Guide_WaysKB"), tr("UI_ZeD_Guide_WaysPad") }
        ry = ry + fh(T.fontF1) + px(4)
        box.ruleY = ry
        ry = ry + px(6)
        -- (rows of words, ZeD's pages: two halves, each wrapped)
        local half = math.floor(inner / 2)
        box.halfX = { cx + pad, cx + pad + half }
        for _, r in ipairs(ways) do
            if r.kbText then
                local kl = wrapRuns(r.kbText, T.fontF2, half - px(10))
                local pl = wrapRuns(r.padText, T.fontF2, half - px(10))
                box.rows[#box.rows + 1] = { y = ry, kbLines = kl, padLines = pl }
                box.texty = true
                ry = ry + math.max(#kl, #pl, 1) * (s + px(3)) + px(5)
            else
                local lab = r.label and A.truncateText(r.label, T.fontF2, colW - px(6)) or ""
                box.rows[#box.rows + 1] = { y = ry, label = lab, kb = r.kb, pad = r.pad }
                ry = ry + s + px(6)
            end
        end
        box.h = ry - y + pad - px(6)
        items[#items + 1] = box
        y = y + box.h
    end
    end
    -- (on a controller the two ways come first, above the game's words, which often speak of the mouse: the
    -- director, Nov 4 2026, "Option 3"; the same on every page, so a controller player always finds it there)
    local padFirst = W.onPad(self.playerNum)
    if padFirst then waysBox(); y = y + px(U.PARA_GAP) * 2 end
    for i, para in ipairs(paragraphs(t.text)) do
        if i > 1 then y = y + px(U.PARA_GAP) end
        -- (the game's single <LINE> break arrives as a newline inside the paragraph: each piece
        -- starts a new line, as the game draws it)
        for piece in (para .. "\n"):gmatch("(.-)\n") do
            for _, runs in ipairs(wrapRuns(piece, T.fontF2, cw)) do
                items[#items + 1] = { kind = "line", x = cx, y = y, runs = runs }
                y = y + fh(T.fontF2) + px(U.LINE_GAP)
            end
        end
    end
    if not padFirst then waysBox() end
    for ti, rules in ipairs(W.rulesList(t) or {}) do
        y = y + px(U.PARA_GAP) * 2
        local pad = px(U.RULES_PAD)
        local inner = cw - pad * 2
        local top = y
        local ry = y + pad
        local labText = rules.title or tr("UI_ZeD_Guide_Rules")
        local lab = ZeD.upper and ZeD.upper(labText) or labText
        local box = { kind = "rules", x = cx, y = top, w = cw, label = lab, labelY = ry, cells = {}, notes = {} }
        ry = ry + fh(T.fontF1) + px(8)
      if W.spoilHidden(t, ti, rules) then
        -- (the spoiler bar, with a line on what it hides)
        box.spoilBar = { x = cx + pad, y = ry, w = inner, h = fh(T.fontF2) + px(10), text = tr("UI_ZeD_Guide_SpoilShow"), ti = ti }
        ry = ry + box.spoilBar.h + px(6)
        for li, l in ipairs(A.wrapText(tr("UI_ZeD_Guide_SpoilWhy"), T.fontF2, inner)) do
            box.notes[#box.notes + 1] = { x = cx + pad - px(12), y = ry, text = l }
            ry = ry + fh(T.fontF2) + px(U.LINE_GAP)
        end
        box.h = ry - top + pad
        items[#items + 1] = box
        y = top + box.h
      else
        local ncol = #rules.cols
        local dataW, headW = {}, {}
        for c = 1, ncol do
            local wmax = 0
            for _, r in ipairs(rules.rows) do wmax = math.max(wmax, tw(T.fontF2, r[c] or "")) end
            dataW[c] = wmax
            -- (a heading's narrowest is its longest word)
            local word = 0
            for wd in tostring(rules.cols[c]):gmatch("%S+") do word = math.max(word, tw(T.fontF1, wd)) end
            dataW[c] = math.max(dataW[c], word)
            headW[c] = tw(T.fontF1, rules.cols[c])
        end
        local gap = px(U.COL_GAP)
        local minTotal = gap * (ncol - 1)
        for c = 1, ncol do minTotal = minTotal + dataW[c] end
        local extra = math.max(0, inner - minTotal)
        local want = 0
        for c = 1, ncol do want = want + math.max(0, headW[c] - dataW[c]) end
        local widths = {}
        for c = 1, ncol do
            local need = math.max(0, headW[c] - dataW[c])
            local give = (want > 0) and math.floor(need * math.min(1, extra / want)) or 0
            widths[c] = dataW[c] + give
        end
        local colX = {}
        local x = cx + pad
        for c = 1, ncol do colX[c] = x; x = x + widths[c] + gap end
        local headLines = 1
        for c = 1, ncol do
            local lines = A.wrapText(rules.cols[c], T.fontF1, widths[c])
            headLines = math.max(headLines, #lines)
            for li, l in ipairs(lines) do
                box.cells[#box.cells + 1] = { x = colX[c], y = ry + (li - 1) * fh(T.fontF1), text = l, head = true }
            end
        end
        ry = ry + headLines * fh(T.fontF1) + px(4)
        box.ruleY = ry
        ry = ry + px(4)
        for ri, r in ipairs(rules.rows) do
            -- (the last column wraps in the room left: "Carving +1, Foraging +1, Knapping +1, Maintenance +1", QA)
            local lastW = math.max(px(40), cx + cw - pad - colX[ncol])
            local lastLines = A.wrapText(r[ncol] or "", T.fontF2, lastW)
            if #lastLines == 0 then lastLines = { "" } end
            for c = 1, ncol - 1 do box.cells[#box.cells + 1] = { x = colX[c], y = ry, text = r[c] or "", stripe = (ri % 2 == 1) } end
            local first = #box.cells + 1
            for li, l in ipairs(lastLines) do
                box.cells[#box.cells + 1] = { x = colX[ncol], y = ry + (li - 1) * fh(T.fontF2), text = l, stripe = (ri % 2 == 1) and li == 1 }
            end
            box.cells[first].rowY = ry
            box.cells[first].rowH = #lastLines * fh(T.fontF2)
            ry = ry + #lastLines * fh(T.fontF2) + px(4)
        end
        ry = ry + px(6)
        for _, note in ipairs(rules.notes or {}) do
            for li, l in ipairs(A.wrapText(note, T.fontF2, inner - px(12))) do
                box.notes[#box.notes + 1] = { x = cx + pad, y = ry, text = l, bullet = li == 1 }
                ry = ry + fh(T.fontF2) + px(U.LINE_GAP)
            end
            ry = ry + px(3)
        end
        box.h = ry - top + pad
        items[#items + 1] = box
        y = top + box.h
      end
    end
    g.items, g.topicH = items, y
    return y
end

function ZeD_GuideWindow:layout()
    local T = ZeD.T
    local Mo = ZeD.Molecules
    local px = T.px
    local g = {}
    local tbH = self:titleBarHeight()
    local pn = self.playerNum
    -- The reading measure: about 66 letters of the body text a line, never wider than the clip, and the
    -- window as wide as that needs (the director, Nov 3 2026: no gap beside the clip, and not too many
    -- words on a line for the eye to track). Large text keeps the same letters a line.
    local sbW0 = T.sp.scrollbarW
    local measure = math.min(px(U.CLIP_W), tw(T.fontF2, MEASURE_SAMPLE:sub(1, U.MEASURE_CHARS)))
    g.measure = measure
    local w = math.min(px(U.LIST_W) + px(U.PAD) * 4 + measure + sbW0, getPlayerScreenWidth(pn) - px(20))
    local bandH = Mo.bandH()
    local bodyH = math.min(px(U.BODY_H), getPlayerScreenHeight(pn) - tbH - bandH - self:footerHeight() - px(20))
    local bodyY = tbH
    local listW = px(U.LIST_W)
    local findH = T.inputH + px(U.PAD)
    local sbW = T.sp.scrollbarW
    g.body = { y = bodyY, h = bodyH }
    g.find = { x = px(U.PAD), y = bodyY + math.floor(px(U.PAD) / 2), w = listW - px(U.PAD) * 2, h = T.inputH }
    g.list = { x = 0, y = bodyY + findH, w = listW, h = bodyH - findH }
    g.head = { x = listW, y = bodyY, w = w - listW, h = px(U.HEAD_H) }
    g.text = { x = listW, y = bodyY + px(U.HEAD_H), w = w - listW, h = bodyH - px(U.HEAD_H) }
    local bandY = bodyY + bodyH
    g.band = { y = bandY, h = bandH }
    local h = bandY + bandH + self:footerHeight()

    -- the list, with a bar when it overflows (the rows then narrow)
    local lh = self:buildList(g)
    g.listNeedsBar = lh > g.list.h
    if g.listNeedsBar then
        g.list.w = listW - sbW
        lh = self:buildList(g)
    end
    local maxL = math.max(0, lh - g.list.h)
    if self.listScroll > maxL then self.listScroll = maxL; self:buildList(g) end
    -- keep the chosen row in view after a jump (F1 on a topic, Previous, Next, the pad)
    if self._jumpList then
        self._jumpList = false
        for _, r in ipairs(g.rows) do
            if r.id == (self.listFocus or self.sel) then
                if r.y < g.list.y then self.listScroll = math.max(0, self.listScroll - (g.list.y - r.y))
                elseif r.y + r.h > g.list.y + g.list.h then self.listScroll = math.min(maxL, self.listScroll + (r.y + r.h - g.list.y - g.list.h)) end
                self:buildList(g)
                break
            end
        end
    end
    self._maxL = maxL
    g.listH = lh

    -- the topic, with a bar when it overflows
    local pad = px(U.PAD) * 2
    local cw = math.min(g.measure, g.text.w - pad * 2 - sbW)
    local th = self:buildTopic(g, g.text.x + pad, cw)
    g.textNeedsBar = th + pad > g.text.h
    -- (room for the bar is kept either way, so the lines do not rewrap when it comes and goes)
    local maxS = math.max(0, th + pad * 2 - g.text.h)
    if self.scroll > maxS then self.scroll = maxS end
    self._maxS = maxS
    g.textOffY = g.text.y + pad - self.scroll

    -- the two scrollbars
    local function bar(key, visible, x, y, hh, size, pos, onScroll)
        local sb = self[key]
        if not sb then sb = ZeD_ScrollbarState:new(); sb.onScroll = onScroll; self[key] = sb end
        sb.visible = visible
        sb.width, sb.arrowH = sbW, sbW
        sb.x, sb.y, sb.height = x, y, hh
        sb:setBarSize(size)
        if not sb.dragging then sb.scrollPos = pos end
        return sb
    end
    local win = self
    g.listSb = bar("_listSb", g.listNeedsBar, listW - sbW, g.list.y, g.list.h, g.list.h / math.max(1, lh),
        maxL > 0 and math.min(1, self.listScroll / maxL) or 0, function(p) win.listScroll = math.floor(p * (win._maxL or 0) + 0.5) end)
    g.textSb = bar("_textSb", g.textNeedsBar, w - sbW, g.text.y, g.text.h, g.text.h / math.max(1, th + pad * 2),
        maxS > 0 and math.min(1, self.scroll / maxS) or 0, function(p) win.scroll = math.floor(p * (win._maxS or 0) + 0.5) end)

    -- the band: the game's start-up box at the left, Previous and Next at the right
    local bh = T.buttonH
    local fy = bandY + px(5)
    g.foot = {}
    local label = getText("IGUI_Tutorial_ShowGuide")
    g.foot[1] = { id = "startup", x = px(U.BAND_EDGE), y = fy, w = T.checkboxSz + px(6) + tw(T.fontF2, label), h = bh, label = label, check = true }
    local right = { { id = "prev", label = btnLabel(tr("UI_ZeD_Guide_Prev")) }, { id = "next", label = btnLabel(tr("UI_ZeD_Guide_Next")), primary = true } }
    local rx = w - px(U.BAND_EDGE)
    for i = #right, 1, -1 do
        local b = right[i]
        local bw = Mo.buttonW(b.label)
        rx = rx - bw
        b.x, b.y, b.w, b.h = rx, fy, bw, bh
        rx = rx - px(U.BAND_GAP)
    end
    g.foot[2], g.foot[3] = right[1], right[2]

    -- size and place: the middle of the player's screen
    if self.width ~= w then self:setWidth(w) end
    if self.height ~= h then self:setHeight(h) end
    local x = getPlayerScreenLeft(pn) + math.floor((getPlayerScreenWidth(pn) - w) / 2)
    local yy = getPlayerScreenTop(pn) + math.floor((getPlayerScreenHeight(pn) - h) / 2)
    if self.x ~= x then self:setX(x) end
    if self.y ~= yy then self:setY(yy) end
    local f = self._findField
    if f then
        if f.x ~= g.find.x then f:setX(g.find.x) end
        if f.y ~= g.find.y then f:setY(g.find.y) end
        if f.width ~= g.find.w then f:setWidth(g.find.w) end
        if f.height ~= g.find.h then f:setHeight(g.find.h) end
    end
    self._g = g
end

-- ---------------------------------------------------------------------------
-- DRAW
-- ---------------------------------------------------------------------------
-- (the list's right edge, after its scrollbar when it has one)
local function listWOf(g)
    return g.listNeedsBar and (g.list.w + ZeD.T.sp.scrollbarW) or g.list.w
end

local _bandBtns = { {}, {} }
local _bandCheck = {}
local _bandSpec = { buttons = _bandBtns }
local _catOpts = {}

-- the clip: the game's own video, or its still when the game's video effects are off
function ZeD_GuideWindow:drawClip(it, t)
    local T = ZeD.T
    local x, y = it.x, it.y + self._g.textOffY
    -- (keyed on the topic and the game's video effects option, so turning it on or off shows at once)
    local key = t.id .. (getCore():getOptionDoVideoEffects() and ":v" or ":s")
    if self._clipFor ~= key then
        self._clipFor = key
        self._clip, self._still = nil, nil
        local core = getCore()
        if core:getOptionDoVideoEffects() then
            local ok, v = pcall(getVideo, t.video, CLIP_SRC_W, CLIP_SRC_H)
            -- (a clip the game loads but cannot play shows its still: QA, sg_aiming.bik)
            local valid = false
            if ok and v then pcall(function() valid = v:isValid() end) end
            if ok and v and valid then self._clip = v end
        end
        if not self._clip then
            -- the game ships no stills for its guide clips: ZeD's own, one frame of each clip
            -- (ZeDUI/tools/guide/make_stills.py; the director, Nov 3 2026: "A still from each clip")
            local base = tostring(t.video):match("([^/\\]+)%.%w+$") or tostring(t.video):match("([^/\\]+)$") or ""
            self._still = getTexture("media/textures/ZeD/guide/" .. base .. ".png")
        end
    end
    local bg = T.surf1 or T.surf2
    self:drawRect(x, y, it.w, it.h, 1, 0, 0, 0)
    if self._clip then
        pcall(function() self._clip:RenderFrame() end)
        self:drawTextureScaled(self._clip, x, y, it.w, it.h, 1, 1, 1, 1)
    elseif self._still then
        self:drawTextureScaledAspect(self._still, x, y, it.w, it.h, 1, 1, 1, 1)
    end
    ZeD.Atoms.frame(self, x, y, it.w, it.h, T.borderS)
end

function ZeD_GuideWindow:prerender()
    local T = ZeD.T
    if not T then return end
    self.minimumWidth, self.minimumHeight = 0, 0
    self.title = getText("SurvivalGuide_WindowTitle")
    -- (picked up or put down a controller: the words and buttons change with it)
    if W.onPad(self.playerNum) ~= self._joyRead then self:readTopics() end
    local ok, err = pcall(self.layout, self)
    if not ok then ZeD.logOnce("survival guide", err); self:close(); return end
    ZeD_Window.prerender(self)
    self.minimumWidth, self.minimumHeight = 0, 0
    local g = self._g
    local A, Mo = ZeD.Atoms, ZeD.Molecules
    local w = self.width
    local px = T.px
    local tc, th, td = T.text, T.textHead, T.textDim
    local ac, hv = T.accent, T.hover
    local joy = self.joyfocus ~= nil

    -- the list and its Find
    local bs = T.borderS
    self:drawRect(g.list.x + listWOf(g), g.body.y, T.hair, g.body.h, bs.a or 1, bs.r, bs.g, bs.b)
    self:setStencilRect(g.list.x, g.list.y, g.list.w, g.list.h)
    for _, r in ipairs(g.rows) do
        if r.y + r.h >= g.list.y and r.y <= g.list.y + g.list.h then
            local focus = joy and self.zone == "list" and self.listFocus == r.id
            local hover = (not joy) and self._hover and self._hover.row == r
            if r.section then
                local o = _catOpts
                o.hover, o.h, o.inset = hover, r.h, px(U.PAD)
                o.focus = focus and focusOpts(self) or nil
                Mo.drawCategoryRow(self, r.x, r.y, r.w, r.section.title, r.count, not r.folded, o)
                if hover then ZeD.Help.set(self, tr(r.folded and "UI_ZeD_Guide_HelpOpenSection" or "UI_ZeD_Guide_HelpFoldSection", r.section.title)) end
            else
                local on = self.sel == r.id
                if on then self:drawRect(r.x, r.y, r.w, r.h, T.selectionA, ac.r, ac.g, ac.b)
                elseif hover then self:drawRect(r.x, r.y, r.w, r.h, hv.a or 1, hv.r, hv.g, hv.b) end
                if hover then ZeD.Help.set(self, tr("UI_ZeD_Guide_HelpTopic", r.topic.title)) end
                local onFocus = focus and ZeD.Focus.mark(self, r.x, r.y, r.w, r.h, focusOpts(self), nil)
                local col = onFocus and T.textOnFocus or tc
                local nx = r.x + px(U.PAD) * 2 + px(4)
                self:drawText(A.truncateText(r.topic.title, T.fontF2, r.w - (nx - r.x) - px(U.PAD)), nx, r.y + math.floor((r.h - fh(T.fontF2)) / 2), col.r, col.g, col.b, col.a or 1, T.fontF2)
            end
        end
    end
    self:clearStencilRect()
    if #g.rows == 0 then
        Mo.drawEmptyLine(self, px(U.PAD), g.list.y + px(8), g.list.w - px(U.PAD) * 2, tr("UI_ZeD_Guide_NoMatch"))
    end
    if g.listSb and g.listSb.visible then g.listSb:draw(self) end

    -- the topic's head: its title, its section, where it sits
    local t = g.topic
    if t then
        local hd = g.head
        local hx = hd.x + px(U.PAD) * 2
        local hy = hd.y + math.floor((hd.h - fh(T.fontF4)) / 2)
        self:drawText(t.title, hx, hy, th.r, th.g, th.b, th.a or 1, T.fontF4)
        local sx = hx + tw(T.fontF4, t.title) + px(10)
        local sec = ZeD.upper and ZeD.upper(t.section.title) or t.section.title
        self:drawText(sec, sx, hd.y + math.floor((hd.h - fh(T.fontF1)) / 2), td.r, td.g, td.b, td.a or 1, T.fontF1)
        local at = 1
        for i, x in ipairs(self.flat) do if x.id == t.id then at = i end end
        local where = tr("UI_ZeD_Guide_NofM", at, #self.flat)
        self:drawText(where, hd.x + hd.w - px(U.PAD) * 2 - tw(T.fontF1, where), hd.y + math.floor((hd.h - fh(T.fontF1)) / 2), td.r, td.g, td.b, td.a or 1, T.fontF1)
        A.drawDividerH(self, hd.x, hd.y + hd.h - T.hair, hd.w, false)
    end

    -- the topic: the clip, the game's words, the rules
    g.spoilBars = nil
    local ta = g.text
    self:setStencilRect(ta.x, ta.y, ta.w, ta.h)
    local oy = g.textOffY
    for _, it in ipairs(g.items or {}) do
        if it.kind == "clip" then
            self:drawClip(it, t)
            -- PZ stencils do not nest: draw the clip, then lay the topic's clip again
            self:clearStencilRect()
            self:setStencilRect(ta.x, ta.y, ta.w, ta.h)
        elseif it.kind == "line" then
            local yy = it.y + oy
            if yy + fh(T.fontF2) >= ta.y and yy <= ta.y + ta.h then
                for _, run in ipairs(it.runs) do
                    if run.tex then
                        inlineDraw(self, run.tex, it.x + run.x, yy, run.s, tc)
                    else
                        self:drawText(run.text, it.x + run.x, yy, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
                    end
                end
            end
        elseif it.kind == "ways" then
            local by = it.y + oy
            A.frame(self, it.x, by, it.w, it.h, T.border)
            local hx1, hx2 = it.colX[2], it.colX[3]
            if it.texty then hx1, hx2 = it.halfX[1], it.halfX[2] end
            self:drawText(it.heads[1], hx1, it.headY + oy, td.r, td.g, td.b, td.a or 1, T.fontF1)
            self:drawText(it.heads[2], hx2, it.headY + oy, td.r, td.g, td.b, td.a or 1, T.fontF1)
            A.drawDividerH(self, it.x + px(U.RULES_PAD), it.ruleY + oy, it.w - px(U.RULES_PAD) * 2, false)
            for _, r in ipairs(it.rows) do
                local ry = r.y + oy
                if r.kbLines then
                    for c, lines in ipairs({ r.kbLines, r.padLines }) do
                        local lx = it.halfX[c]
                        for li, runs in ipairs(lines) do
                            local ly = ry + (li - 1) * (it.s + px(3))
                            if ly + it.s >= ta.y and ly <= ta.y + ta.h then
                                for _, run in ipairs(runs) do
                                    if run.tex then inlineDraw(self, run.tex, lx + run.x, ly, run.s, tc)
                                    else self:drawText(run.text, lx + run.x, ly, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2) end
                                end
                            end
                        end
                    end
                elseif ry + it.s >= ta.y and ry <= ta.y + ta.h then
                    if r.label ~= "" then self:drawText(r.label, it.colX[1], ry, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2) end
                    for c, list in ipairs({ r.kb, r.pad }) do
                        local xx = it.colX[c + 1]
                        for _, o in ipairs(list) do
                            local ow = inlineW(o, it.s)
                            if xx + ow <= it.colX[c + 1] + it.colW then inlineDraw(self, o, xx, ry, it.s, tc) end
                            xx = xx + ow + px(4)
                        end
                    end
                end
            end
        elseif it.kind == "rules" then
            local by = it.y + oy
            local s2 = T.surf2
            if s2 then self:drawRect(it.x, by, it.w, it.h, s2.a or 1, s2.r, s2.g, s2.b) end
            A.frame(self, it.x, by, it.w, it.h, T.border)
            self:drawText(it.label, it.x + px(U.RULES_PAD), it.labelY + oy, ac.r, ac.g, ac.b, ac.a or 1, T.fontF1)
            local sbar = it.spoilBar
            if sbar then
                local s3 = T.surf3
                local hot = self._hover and self._hover.spoil == sbar
                local fill = hot and (T.hover or s3) or s3
                self:drawRect(sbar.x, sbar.y + oy, sbar.w, sbar.h, fill.a or 1, fill.r, fill.g, fill.b)
                A.frame(self, sbar.x, sbar.y + oy, sbar.w, sbar.h, T.borderS)
                local f2 = T.fontF2
                self:drawText(sbar.text, sbar.x + math.floor((sbar.w - tw(f2, sbar.text)) / 2), sbar.y + oy + math.floor((sbar.h - fh(f2)) / 2), th.r, th.g, th.b, th.a or 1, f2)
                g.spoilBars = g.spoilBars or {}
                g.spoilBars[#g.spoilBars + 1] = { x = sbar.x, y = sbar.y + oy, w = sbar.w, h = sbar.h, bar = sbar }
            end
            for _, c in ipairs(it.cells) do
                if c.head then
                    self:drawText(c.text, c.x, c.y + oy, td.r, td.g, td.b, td.a or 1, T.fontF1)
                else
                    if c.rowY and c.stripe then
                        local st = T.stripe
                        if st then self:drawRect(it.x + T.hair, c.rowY + oy - px(2), it.w - T.hair * 2, (c.rowH or fh(T.fontF2)) + px(4), st.a or 1, st.r, st.g, st.b) end
                    end
                end
            end
            for _, c in ipairs(it.cells) do
                if not c.head then self:drawText(c.text, c.x, c.y + oy, th.r, th.g, th.b, th.a or 1, T.fontF2) end
            end
            A.drawDividerH(self, it.x + px(U.RULES_PAD), it.ruleY + oy, it.w - px(U.RULES_PAD) * 2, false)
            for _, n in ipairs(it.notes) do
                local ny = n.y + oy
                if n.bullet then self:drawRect(n.x, ny + math.floor(fh(T.fontF2) / 2) - px(2), px(4), px(4), tc.a or 1, tc.r, tc.g, tc.b) end
                self:drawText(n.text, n.x + px(12), ny, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
            end
        end
    end
    self:clearStencilRect()
    if not t then
        Mo.drawEmptyLine(self, ta.x + px(U.PAD) * 2, ta.y + px(8), ta.w - px(U.PAD) * 4, tr("UI_ZeD_Guide_NoMatch"))
    end
    if g.textSb and g.textSb.visible then g.textSb:draw(self) end

    -- the band
    local check = _bandCheck
    local cf = g.foot[1]
    check.label, check.id, check.help = cf.label, cf.id, tr("UI_ZeD_Guide_HelpStartup")
    check.on = getCore():getOptionShowSurvivalGuide() and true or false
    check.hover = (not joy) and self._hover and self._hover.foot == cf or false
    check.focus = (joy and self.zone == "foot" and self.footFocus == 1) and focusOpts(self) or nil
    for i = 1, 2 do
        local b = g.foot[i + 1]
        local e = _bandBtns[i]
        e.label, e.variant, e.id = b.label, b.primary and "primary" or "default", b.id
        e.help = tr(b.id == "prev" and "UI_ZeD_Guide_HelpPrev" or "UI_ZeD_Guide_HelpNext")
        e.hover = (not joy) and self._hover and self._hover.foot == b or false
        e.pressed = self._down == b
        e.focus = (joy and self.zone == "foot" and self.footFocus == i + 1) and focusOpts(self) or nil
    end
    _bandSpec.win, _bandSpec.check = self, check
    Mo.drawBand(self, 0, g.band.y, w, _bandSpec)
end

function ZeD_GuideWindow:getFooterPrompts()
    if not self.joyfocus then return nil end
    local P = ZeD.Prompt
    local move = P and P.padNote and P.padNote(tr("UI_ZeD_Guide_DpadMove")) or tr("UI_ZeD_Guide_DpadMove")
    return { move, { glyph = "LB", label = tr("UI_ZeD_Guide_Prev") }, { glyph = "RB", label = tr("UI_ZeD_Guide_Next") },
             { glyph = "A", label = tr("UI_ZeD_Guide_Choose") }, { glyph = "B", label = getText("UI_Close") } }
end

function ZeD_GuideWindow:render() ZeD_Window.render(self) end

-- ---------------------------------------------------------------------------
-- OPEN AND CLOSE (the game pauses while the guide is open, as the game's guide does)
-- ---------------------------------------------------------------------------
function ZeD_GuideWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if self._findField and self._findField.input then pcall(function() self._findField.input:unfocus() end) end
    pcall(setGameSpeed, 1)
    local jd = JoypadState.players[self.playerNum + 1]
    if jd then
        jd.focus = self._prevFocus
        self._prevFocus = nil
        updateJoypadFocus(jd)
    end
end

-- ---------------------------------------------------------------------------
-- ACTIONS
-- ---------------------------------------------------------------------------
function ZeD_GuideWindow:pressFoot(b)
    if not b then return end
    sound("UIActivateButton")
    if b.id == "startup" then
        local core = getCore()
        core:setOptionShowSurvivalGuide(not core:getOptionShowSurvivalGuide())
        core:saveOptions()
    elseif b.id == "prev" then self:step(-1)
    elseif b.id == "next" then self:step(1) end
end

function ZeD_GuideWindow:pressRow(r)
    if not r then return end
    if r.section then
        self.closed[r.section.id] = not r.folded or nil
        if not r.folded and self.find ~= "" then self.closed[r.section.id] = nil end
        sound("UISelectListItem")
    elseif r.topic then
        self:choose(r.topic.id)
    end
end

-- ---------------------------------------------------------------------------
-- MOUSE (top-level: hit-tested here)
-- ---------------------------------------------------------------------------
function ZeD_GuideWindow:hitAt(x, y)
    local g = self._g
    if not g then return nil end
    for _, b in ipairs(g.foot) do if inRect(b, x, y) then return { foot = b } end end
    if inRect(g.list, x, y) then
        for _, r in ipairs(g.rows) do if inRect(r, x, y) then return { row = r } end end
        return { list = true }
    end
    for _, sb in ipairs(g.spoilBars or {}) do if inRect(sb, x, y) then return { spoil = sb.bar } end end
    if inRect(g.text, x, y) then return { text = true } end
    return nil
end

function ZeD_GuideWindow:closeAction()
    sound("UIActivateButton")
    self:close()
end

function ZeD_GuideWindow:onMouseDown(x, y)
    if not self:getIsVisible() then return true end
    local cb = self:closeRect()
    if cb and inRect(cb, x, y) then return true end
    if inRect(self:windowBoxRect(), x, y) then return true end
    for _, key in ipairs({ "_listSb", "_textSb" }) do
        local sb = self[key]
        if sb and sb.visible and x >= sb.x and x < sb.x + sb.width and y >= sb.y and y < sb.y + sb.height then
            sb:handleMouseDown(y - sb.y)
            return true
        end
    end
    local h = self:hitAt(x, y)
    if h and h.row then self.zone = "list"; self:pressRow(h.row) end
    if h and h.foot then self._down = h.foot end
    if h and h.spoil then
        W.spoil[W.spoilKey(self.byId and self.byId[self.sel], h.spoil.ti)] = true
        sound("UIActivateButton")
    end
    return true
end

function ZeD_GuideWindow:onMouseUp(x, y)
    local down = self._down
    self._down = nil
    if self._listSb then self._listSb:handleMouseUp() end
    if self._textSb then self._textSb:handleMouseUp() end
    local h = self:hitAt(x, y)
    if down and h and h.foot == down then self:pressFoot(down) end
    return true
end

function ZeD_GuideWindow:onMouseUpOutside(x, y)
    self._down = nil
    if self._listSb then self._listSb:handleMouseUp() end
    if self._textSb then self._textSb:handleMouseUp() end
end

function ZeD_GuideWindow:onMouseMove(dx, dy)
    for _, key in ipairs({ "_listSb", "_textSb" }) do
        local sb = self[key]
        if sb and sb.dragging then sb:handleMouseMove(self:getMouseY() - sb.y) end
    end
end
function ZeD_GuideWindow:onMouseMoveOutside(dx, dy) self:onMouseMove(dx, dy) end

function ZeD_GuideWindow:onMouseWheel(del)
    local g = self._g
    if not g then return true end
    local mx, my = self:getMouseX(), self:getMouseY()
    local step = del * ZeD.T.px(40)
    if inRect({ x = 0, y = g.list.y, w = listWOf(g), h = g.list.h }, mx, my) then
        self.listScroll = math.max(0, math.min(self._maxL or 0, self.listScroll + step))
    else
        self.scroll = math.max(0, math.min(self._maxS or 0, self.scroll + step))
    end
    return true
end

function ZeD_GuideWindow:update()
    ZeD_Window.update(self)
    for _, key in ipairs({ "_listSb", "_textSb" }) do
        local sb = self[key]
        if sb and sb.visible then
            local mx, my = self:getMouseX(), self:getMouseY()
            if sb.dragging or (mx >= sb.x and mx < sb.x + sb.width) then sb:handleMouseMove(my - sb.y) end
            if sb.dragging and not isMouseButtonDown(0) then sb:handleMouseUp() end
        end
    end
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    self.joyfocus = (jd and jd.focus == self) and jd or (W.qaJoy and self or nil)
    self._hover = self:hitAt(self:getMouseX(), self:getMouseY())
end

-- ---------------------------------------------------------------------------
-- KEYS: Escape and F1 close (typing in Find keeps its keys)
-- ---------------------------------------------------------------------------
function ZeD_GuideWindow:isKeyConsumed(key) return key == Keyboard.KEY_ESCAPE end
function ZeD_GuideWindow:onKeyPress(key)
    if key == Keyboard.KEY_ESCAPE then
        self:close()
        GameKeyboard.eatKeyPress(key)
    end
end

-- ---------------------------------------------------------------------------
-- CONTROLLER: the list (up and down, A opens a section or a topic), the topic (up and
-- down scroll), the band; LB and RB turn the topics anywhere, B closes
-- ---------------------------------------------------------------------------
function ZeD_GuideWindow:onGainJoypadFocus(joypadData) self.joyfocus = joypadData end
function ZeD_GuideWindow:onLoseJoypadFocus(joypadData) self.joyfocus = nil end

local function listIndex(self)
    local rows = (self._g and self._g.rows) or {}
    for i, r in ipairs(rows) do if r.id == (self.listFocus or self.sel) then return i, rows end end
    return 1, rows
end

function ZeD_GuideWindow:onJoypadDown(button, joypadData)
    if button == Joypad.BButton then self:close(); return end
    if button == Joypad.LBumper then self:step(-1); self.zone = "list"; return end
    if button == Joypad.RBumper then self:step(1); self.zone = "list"; return end
    if button ~= Joypad.AButton then return end
    if self.zone == "list" then
        local i, rows = listIndex(self)
        local r = rows[i]
        if r and r.section then self:pressRow(r) elseif r then self:choose(r.id, true); self.zone = "text"; sound("UISelectListItem") end
    elseif self.zone == "foot" then
        self:pressFoot(self._g and self._g.foot[self.footFocus])
    elseif self.zone == "text" then
        -- (A on the text shows the numbers a spoiler bar hides)
        if W.showSpoilers(self.byId and self.byId[self.sel]) then sound("UIActivateButton") end
    end
end

function ZeD_GuideWindow:onJoypadDirUp()
    if self.zone == "list" then
        local i, rows = listIndex(self)
        if i > 1 then
            local r = rows[i - 1]
            self.listFocus = r.id
            if r.topic then self:choose(r.id, true) end
            self._jumpList = true
            sound("UISelectListItem")
        end
    elseif self.zone == "text" then
        if self.scroll > 0 then self.scroll = math.max(0, self.scroll - ZeD.T.px(60)) else self.zone = "list" end
    elseif self.zone == "foot" then
        self.zone = "list"; sound("UISelectListItem")
    end
end

function ZeD_GuideWindow:onJoypadDirDown()
    if self.zone == "list" then
        local i, rows = listIndex(self)
        if i < #rows then
            local r = rows[i + 1]
            self.listFocus = r.id
            if r.topic then self:choose(r.id, true) end
            self._jumpList = true
            sound("UISelectListItem")
        else
            self.zone = "foot"; self.footFocus = 3; sound("UISelectListItem")
        end
    elseif self.zone == "text" then
        if self.scroll < (self._maxS or 0) then self.scroll = math.min(self._maxS or 0, self.scroll + ZeD.T.px(60))
        else self.zone = "foot"; self.footFocus = 3; sound("UISelectListItem") end
    end
end

function ZeD_GuideWindow:onJoypadDirRight()
    if self.zone == "list" then self.zone = "text"; sound("UISelectListItem")
    elseif self.zone == "foot" and self.footFocus < 3 then self.footFocus = self.footFocus + 1; sound("UISelectListItem") end
end

function ZeD_GuideWindow:onJoypadDirLeft()
    if self.zone == "text" then self.zone = "list"; sound("UISelectListItem")
    elseif self.zone == "foot" and self.footFocus > 1 then self.footFocus = self.footFocus - 1; sound("UISelectListItem") end
end

-- ---------------------------------------------------------------------------
-- F1 ON WHAT YOU ARE DOING: the open Character or World tab's topic (the game's topic keys)
-- ---------------------------------------------------------------------------
W.tabTopics = W.tabTopics or {
    char = { skills = "SurvivalGuide_skill_books_title", health = "SurvivalGuide_first_aid_title",
             thermal = "SurvivalGuide_temperature_title", cooking = "SurvivalGuide_cooking_title",
             equip = "SurvivalGuide_equip_primary_title", loot = "SurvivalGuide_backpacks_title" },
    world = { craft = "SurvivalGuide_crafting_menu_title", build = "SurvivalGuide_build_menu_title",
              forage = "SurvivalGuide_foraging_title", maps = "SurvivalGuide_map_title",
              vehicle = "SurvivalGuide_mechanics_menu_title", animals = "SurvivalGuide_animal_menu_title",
              radio = "SurvivalGuide_television_title", loot = "SurvivalGuide_backpacks_title" },
}

local function openTab(win)
    if not (win and win.isReallyVisible and win:isReallyVisible()) then return nil end
    if win._drawerMode ~= "tab" then return nil end
    return win._activeTab
end

function W.contextTopicKey()
    local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
    local ww = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    local ct, wt = openTab(cw), openTab(ww)
    -- (the window under the pointer first, then the Character window's tab, then the World's)
    if ww and wt and ww.isMouseOver and ww:isMouseOver() and W.tabTopics.world[wt] then return W.tabTopics.world[wt] end
    if ct and W.tabTopics.char[ct] then return W.tabTopics.char[ct] end
    if wt and W.tabTopics.world[wt] then return W.tabTopics.world[wt] end
    return nil
end

-- ---------------------------------------------------------------------------
-- ENTRY
-- ---------------------------------------------------------------------------
-- shared with the book (ZeD_SurvivalGuideBook.lua): the topics, their paragraphs, the inline pictures
W.readTopicList = readTopics
W.paragraphs = paragraphs
W.MARK = MARK
W.inlineTex = inlineTex
W.inlineW = inlineW
W.inlineDraw = inlineDraw
W.entryText = entryText

-- The Full look is the book, "Survive the Apocalypse" (ZeD setup, Full or simple: Survival guide). The book's
-- faces (the game's Old Standard TT, Roberto Sans, Open Sans) draw Latin, Greek and Cyrillic, so a game in
-- Chinese, Japanese, Korean, Thai or Arabic shows the window.
local NO_BOOK_LANGS = { CN = true, CH = true, JP = true, KO = true, TH = true, AR = true }
function W.useBook()
    if not (ZeD.GuideBook and ZeD.GuideBook.open) then return false end
    if ZeD.Settings and ZeD.Settings.guideSimple and ZeD.Settings.guideSimple() then return false end
    local ok, name = pcall(function() return tostring(Translator.getLanguage():name()) end)
    if ok and NO_BOOK_LANGS[name] then return false end
    return true
end

-- open on a topic: an id (tostring of a SurvivalGuideEntry) or a title key; the book or the window
function W.open(pn, want)
    W.spoil = {}
    W._rulesC = {}
    if W.useBook() then return ZeD.GuideBook.open(pn or 0, want) end
    return W.openWindow(pn, want)
end

function W.openWindow(pn, want)
    pn = pn or 0
    local win = W.windows[pn]
    if not win then
        win = ZeD_GuideWindow:new(pn)
        win:initialise()
        win:instantiate()
        W.windows[pn] = win
    end
    win:readTopics()
    if want then
        local id = want
        if not win.byId[id] then
            for _, t in ipairs(win.flat) do if t.titleKey == want then id = t.id end end
        end
        if win.byId[id] then win:choose(id, true) end
    end
    win.listFocus = win.sel
    win._jumpList = true
    if not win:isReallyVisible() then
        win:setVisible(true)
        win:addToUIManager()
        win:setAlwaysOnTop(true)
        pcall(setGameSpeed, 0)
    end
    win:bringToTop()
    win.zone = "list"
    local jd = JoypadState.players[pn + 1]
    if jd then
        if jd.focus ~= win then win._prevFocus = jd.focus end
        jd.focus = win
        jd.activeWhilePaused = true
        updateJoypadFocus(jd)
    end
    return win
end

function W.get(pn) return W.windows[pn or 0] end

function W.toggle(pn)
    local win = W.windows[pn or 0]
    if win and win:isReallyVisible() then win:close(); return end
    local B = ZeD.GuideBook
    if B and B.isOpen and B.isOpen(pn or 0) then B.close(pn or 0); return end
    W.open(pn, W.contextTopicKey())
end

function W.takeEscape()
    for _, win in pairs(W.windows) do
        if win and win:isReallyVisible() then win:close(); return true end
    end
    local B = ZeD.GuideBook
    if B and B.isOpen and B.isOpen(0) then B.close(0); return true end
    return false
end
ZeD.EscapeTakers = ZeD.EscapeTakers or {}
ZeD.EscapeTakers.guide = W.takeEscape

-- ---------------------------------------------------------------------------
-- THE GAME'S ENTRY POINTS (HOOK_MAP row 18): F1, the Help wheel, openEntry, the first run
-- ---------------------------------------------------------------------------
local function blocked()
    if MainScreen and MainScreen.instance and MainScreen.instance:isVisible() then return true end
    return SurvivalGuide and SurvivalGuide.blockSurvivalGuide
end

local function onKey(key)
    if not getCore():isKey(KeybindId.TOGGLE_SURVIVAL_GUIDE, key) then return end
    if blocked() then return end
    W.toggle(0)
end

local function onGameStart()
    if isServer() then return end
    local core = getCore()
    if not core:getOptionShowSurvivalGuide() then return end
    if tostring(core:getGameMode()) == "Tutorial" and SurvivalGuide and SurvivalGuide.blockSurvivalGuide then return end
    if isDemo and isDemo() and ISDemoPopup and ISDemoPopup.instance then return end
    W.open(0)
end

local function hook()
    if _G._zedGuideHooked or not SurvivalGuide then return end
    _G._zedGuideHooked = true
    -- the game's handlers come off the events; ZeD's take their places
    if SurvivalGuide.onKeyPressed then Events.OnKeyPressed.Remove(SurvivalGuide.onKeyPressed) end
    if SurvivalGuide.OnGameStart then Events.OnGameStart.Remove(SurvivalGuide.OnGameStart) end
    Events.OnKeyPressed.Add(onKey)
    Events.OnGameStart.Add(onGameStart)
    -- the Help wheel calls SurvivalGuide.onKeyPressed by name; other windows call openEntry
    SurvivalGuide.onKeyPressed = onKey
    SurvivalGuide.openEntry = function(entry) W.open(0, entry and tostring(entry) or nil) end
end
hook()
