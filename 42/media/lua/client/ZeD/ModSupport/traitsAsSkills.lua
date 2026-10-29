-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/traitsAsSkills.lua
-- ============================================================================
-- SUPPORT FOR TRAITS AS SKILLS (mod id traitsAsSkills, Workshop 3784847437, by GersonRess)
-- Mockup zed_traits_tab_v1, approved "as recommended" Oct 26 2026.
--
-- The mod turns traits into ladders that level up and down with play and puts a
-- Traits tab in the game's Character window, which ZeD never shows. This is that
-- tab in ZeD's Character window, right after Skills, there only while the mod is
-- on: one row per ladder drawn like a Skills row (the level in the square, the
-- progress as the row's fill), ten small steps framed green or red where they hold
-- a good or bad trait, the trait you have now at the right (a New tag until the tab
-- has been opened once since it came). Categories fold (section heads); Mind and
-- Physical first, Skills last (the mockup's order). Find and the All | With a trait
-- radio buttons narrow the list. The details at the foot follow the focused (or
-- hovered) row:
-- the whole ladder, the XP to the next level (or the skill it follows, or the
-- weight), the mod's Gain and Lose lists in its own words, what the next level
-- up or down changes, and the trait's description from the game.
--
-- Everything is read from the mod: its registry (TAS.Spectrum.registry, so ladders
-- other mods register land here too), its state (TAS.ClientState, which asks the
-- server about once a second in multiplayer), its level maths (Spectrum.getLevelInfo),
-- its actions (TAS.XP.actions) and its words (UI_TAS_*). Its own panel is never shown.
-- ============================================================================

local MOD_ID = "traitsAsSkills"

local function modOn()
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    for i = 0, list:size() - 1 do
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
if not modOn() then return end

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ZeD_CharacterWindow"
require "ZeD/ZeD_HairBeard"
require "TAS/TASSpectrum"
require "TAS/TASClientState"
-- the other mods' rows on this tab (Evolving Traits World): ZeD.TraitsTab
require "ZeD/ModSupport/TraitsTab"

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.traitsAsSkills = S

local TAB_ID = "traits"

-- design units
local PAD, CAT_H, BADGE_W, NAME_W, STEP_W, STEP_H, STEP_GAP, DET_H, FIND_W, KEY_W = 10, 20, 20, 112, 12, 13, 2, 218, 150, 76
-- the mockup's order: Mind and Physical first, Skills (ladders that follow skills) last
local CAT_ORDER = { "inteligencia", "physical", "behavior", "social", "trade", "survival", "combat", "other", "skills" }

S.find = ""
S.only = false
S.closed = {}

local function tr(k, ...) return ZeD.tr(k, ...) end
local function F(n) return ZeD.TM:getFontHeight(ZeD.T["fontF" .. n]) end
local function Spectrum() return TAS and TAS.Spectrum end

-- ---------------------------------------------------------------------------
-- the game's traits (labels, descriptions, good or bad), read once
-- ---------------------------------------------------------------------------
local _tinfo = {}
local function tinfo(name)
    local t = _tinfo[name]
    if t then return t end
    t = { label = tostring(name), desc = "", bad = false }
    local ok = pcall(function()
        local tr_ = TAS.Trait.get(name)
        local d = tr_ and CharacterTraitDefinition.getCharacterTraitDefinition(tr_)
        if d then
            t.label = d:getLabel() or t.label
            t.desc = d:getDescription() or ""
            t.bad = d:getCost() < 0
            t.trait = tr_
        end
    end)
    if not ok then t.label = tostring(name) end
    _tinfo[name] = t
    return t
end
local function owns(p, name)
    local t = tinfo(name).trait
    if not t then return false end
    local ok, r = pcall(function() return p:hasTrait(t) end)
    return ok and r == true
end
local function bandTraits(b)
    if type(b.trait) == "table" then return b.trait end
    if b.trait then return { b.trait } end
    return {}
end
local function catName(cat)
    return getTextOrNull("UI_TAS_Category_" .. tostring(cat)) or getText("UI_TAS_Category_other")
end

-- ---------------------------------------------------------------------------
-- STATE
-- ---------------------------------------------------------------------------
local function state(win)
    local st = win._tas
    if not st then
        st = { scroll = ZeD_ScrollbarState:new(), detScroll = ZeD_ScrollbarState:new(), tick = 999, rows = {}, byId = {}, zones = {}, els = {} }
        win._tas = st
    end
    return st
end

-- one ladder as it stands for this character
local function readRow(p, def)
    local Sp = Spectrum()
    local r = { def = def, id = def.id, name = Sp.getDisplayName(def), cat = Sp.getCategory(def), bands = def.bands }
    local okS, s = pcall(TAS.ClientState.get, def.id)
    s = okS and s or nil
    r.kind = (def.source == "weight") and "weight" or ((def.source == "skill") and "skill" or "xp")
    r.level, r.frac, r.into, r.next = 0, 0, 0, Sp.getXpForLevel(def, 1) or 1
    if s and s.dynamic then
        local lv = tonumber(s.level) or 0
        r.level = math.max(0, math.min(10, math.floor(lv)))
        r.frac = (r.level >= 10) and 1 or math.max(0, lv - r.level)
        r.weight = s.weight
    elseif s then
        local level, into, nxt = Sp.getLevelInfo(def, s.base or 0, s.netXP or 0)
        r.level, r.into, r.next = level, into or 0, nxt or 1
        r.frac = (level >= 10) and 1 or ((nxt and nxt > 0) and math.max(0, math.min(1, (into or 0) / nxt)) or 0)
    end
    -- the traits a level holds (of a pair, only the one the character has)
    r.at = function(L)
        local out = {}
        for _, b in ipairs(def.bands) do
            if L >= b.min and L <= (b.max or 10) then
                local list = bandTraits(b)
                for _, t in ipairs(list) do
                    if type(b.trait) ~= "table" or owns(p, t) then out[#out + 1] = t end
                end
            end
        end
        return out
    end
    -- the traits the character has from this ladder now
    r.now = {}
    local seen = {}
    for _, b in ipairs(def.bands) do
        for _, t in ipairs(bandTraits(b)) do
            if not seen[t] and owns(p, t) then seen[t] = true; r.now[#r.now + 1] = t end
        end
    end
    -- the steps: which ranges hold a good or bad trait
    r.steps = {}
    for L = 1, 10 do
        local sign = nil
        for _, b in ipairs(def.bands) do
            if L >= b.min and L <= (b.max or 10) then
                local list = bandTraits(b)
                if list[1] then sign = tinfo(list[1]).bad and "-" or "+"; break end
            end
        end
        r.steps[L] = sign
    end
    return r
end

local function refresh(win, st, p, force)
    pcall(TAS.ClientState.request)
    st.tick = (st.tick or 0) + 1
    if not force and st.tick < 30 and st.player == p then return end
    st.tick, st.player = 0, p
    local rows, byId = {}, {}
    for _, def in pairs(Spectrum().registry) do
        local ok, r = pcall(readRow, p, def)
        if ok and r then rows[#rows + 1] = r; byId[r.id] = r end
    end
    st.rows, st.byId = rows, byId
    -- NEW: traits that came since the tab was last opened (kept on the character)
    local md = p:getModData()
    if not md.ZeD_TASSeen then
        md.ZeD_TASSeen = {}
        for _, r in ipairs(rows) do for _, t in ipairs(r.now) do md.ZeD_TASSeen[t] = true end end
    end
    if st.visitStart then
        st.visitStart = false
        st.newSet = {}
        for _, r in ipairs(rows) do
            for _, t in ipairs(r.now) do if not md.ZeD_TASSeen[t] then st.newSet[t] = true end end
        end
        md.ZeD_TASSeen = {}
        for _, r in ipairs(rows) do for _, t in ipairs(r.now) do md.ZeD_TASSeen[t] = true end end
    end
end

local function catKnown(c)
    for _, k in ipairs(CAT_ORDER) do if k == c then return true end end
    return false
end

local function matches(r, q)
    if q == "" then return true end
    if string.find(string.lower(r.name), q, 1, true) then return true end
    for _, b in ipairs(r.bands) do
        for _, t in ipairs(bandTraits(b)) do
            if string.find(string.lower(tinfo(t).label), q, 1, true) then return true end
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- LAYOUT (content coordinates; drawn at y - scroll offset)
-- ---------------------------------------------------------------------------
local function add(L, it) L.items[#L.items + 1] = it; return it end

local function layout(st, w, win)
    local T = ZeD.T
    local L = { items = {} }
    local x, y = T.px(PAD), T.px(8)
    local cw = w - T.px(PAD) * 2
    add(L, { kind = "credit", x = x, y = y, w = cw, h = math.max(F(5), T.px(18)) })
    y = y + math.max(F(5), T.px(18)) + T.px(8)
    add(L, { kind = "sum", x = x, y = y })
    y = y + F(1) + T.px(10)
    local q = string.lower(S.find or "")
    local vis = {}
    for _, r in ipairs(st.rows) do
        if (not S.only or #r.now > 0) and matches(r, q) then vis[#vis + 1] = r end
    end
    -- (the other mods' rows count too: Nothing matches only when no row at all is left)
    local _, _, extShown = ZeD.TraitsTab.counts(win, q, S.only)
    if #vis == 0 and extShown == 0 then
        local lines = ZeD.Atoms.wrapText(tr("UI_ZeD_TAS_Nothing", S.find), ZeD.T.fontF2, cw)
        local eh = #lines * (F(2) + T.px(2)) - T.px(2)
        add(L, { kind = "empty", x = x, y = y + T.px(8), w = cw, h = eh })
        y = y + T.px(8) + eh + T.px(12)
    end
    local cats = {}
    for _, c in ipairs(CAT_ORDER) do cats[#cats + 1] = c end
    local function catOf(r) return catKnown(r.cat) and r.cat or "other" end
    for _, c in ipairs(cats) do
        local rs = {}
        for _, r in ipairs(vis) do if catOf(r) == c then rs[#rs + 1] = r end end
        if #rs > 0 then
            table.sort(rs, function(a, b) return a.name < b.name end)
            local shut = S.closed[c] and q == ""
            y = y + T.px(6)
            add(L, { kind = "cat", cat = c, n = #rs, shut = shut, x = x, y = y, w = cw, h = T.px(CAT_H) })
            y = y + T.px(CAT_H) + T.sp.afterGroove
            if not shut then
                local rh = F(1) + T.px(8)   -- Skills' row height (grows with Large text)
                for i, r in ipairs(rs) do
                    add(L, { kind = "row", row = r, odd = i % 2 == 0, x = x, y = y, w = cw, h = rh })
                    y = y + rh + T.sp.rowGap
                end
            end
        end
    end
    -- the other mods' rows (ZeD.TraitsTab), each mod under a section head with its name
    y = ZeD.TraitsTab.layout(win, L, x, y, cw, q, S.only)
    L.h = y + T.px(12)
    return L
end

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------
local function focusedEl(win)
    local Fo = ZeD.Input and ZeD.Input.Focus
    if not (Fo and Fo.getFocusedWindow and Fo.getFocusedWindow() == win and Fo.getFocusedElement) then return nil end
    local el = Fo.getFocusedElement(win)
    if el and el.tas then return el end
    return nil
end
-- The controller's mark options for the element with this id: set only when the window is
-- the focused one, the controller is in use and that element has the focus.
local _focusOpts = {}
local function focusOf(win, id)
    local Fo = ZeD.Input and ZeD.Input.Focus
    if Fo and Fo.isFocused and Fo.isFocused(win, nil, id) then
        _focusOpts.win = win
        return _focusOpts
    end
    return nil
end

-- the footer help line's words for what the pointer is over
local function help(win, text)
    if ZeD.Help and ZeD.Help.set then ZeD.Help.set(win, text) end
end

-- a row is as tall as Skills' rows (the small font's height and 8u), so it grows with Large text
local function rowH()
    return F(1) + ZeD.T.px(8)
end

-- the progress as the row's fill, in Skills' colours and strengths (SkillsTab getProgressColors)
local function fillColour(T, r)
    if r.level >= 10 then return T.warning, 0.55 end
    if r.frac >= 0.75 then return T.danger, 0.45 end
    if r.frac >= 0.4 then return T.warning, 0.45 end
    return T.positive, 0.45
end

local function drawCredit(panel, win, st, it, y)
    local T = ZeD.T
    local A = ZeD.Atoms
    local c = T.toneLo or T.textDim
    local mi = getModInfoByID and getModInfoByID(MOD_ID)
    local name = mi and mi:getName() or "Traits As Skills"
    local author = nil
    if mi then local ok, a = pcall(function() return mi:getAuthor() end); if ok and a and a ~= "" then author = a end end
    local text = author and tr("UI_ZeD_TAS_Credit", name, author) or name
    panel:drawText(text, it.x, y + math.floor((it.h - F(5)) / 2), c.r, c.g, c.b, c.a or 1, T.fontF5)
    -- All | With a trait: one of two, System 7 radio buttons (each half pressable)
    local withT = 0
    for _, r in ipairs(st.rows) do if #r.now > 0 then withT = withT + 1 end end
    -- (the other mods' rows on this tab count in both halves)
    local extAll, extWith = ZeD.TraitsTab.counts(win, "", false)
    local labels = { tr("UI_ZeD_TAS_All", #st.rows + extAll), tr("UI_ZeD_TAS_WithTrait", withT + extWith) }
    local f = T.fontF2
    local rs = A.radioSize()
    local ws = {}
    local total = 0
    for i, l in ipairs(labels) do
        ws[i] = T.px(8) + rs + T.px(8) + ZeD.TM:MeasureStringX(f, l) + T.px(8)
        total = total + ws[i]
    end
    local bx = it.x + it.w - total
    local hv = T.hover
    st.only = {}
    local fo = focusOf(win, "tas:only")
    for i, l in ipairs(labels) do
        local on = (i == 2) == (S.only == true)
        local hover = A.mouseIn(panel, bx, y, ws[i], it.h)
        if hover then
            panel:drawRect(bx, y, ws[i], it.h, hv.a, hv.r, hv.g, hv.b)
            help(win, tr("UI_ZeD_TAS_HelpOnly", l))
        end
        local tc = T.text
        if fo and on and ZeD.Focus.mark(panel, bx, y, ws[i], it.h, fo) then tc = T.textOnFocus end
        A.drawRadio(panel, bx + T.px(8), y + math.floor((it.h - rs) / 2), on, { hover = hover })
        panel:drawText(l, bx + T.px(8) + rs + T.px(8), y + math.floor((it.h - F(2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f)
        st.only[#st.only + 1] = { x = bx, y = y, w = ws[i], h = it.h, val = (i == 2) }
        bx = bx + ws[i]
    end
end

-- the summary line: positive, negative and no-trait counts, each with its square mark
local function drawSum(panel, st, it, y)
    local T = ZeD.T
    local good, bad, none = 0, 0, 0
    for _, r in ipairs(st.rows) do
        if #r.now == 0 then none = none + 1 end
        for _, t in ipairs(r.now) do if tinfo(t).bad then bad = bad + 1 else good = good + 1 end end
    end
    local dsz = T.px(6)
    local x = it.x
    local tc = T.text
    local dy = y + math.floor((F(1) - dsz) / 2)
    local function part(dot, text)
        if dot == "pos" then ZeD.Atoms.drawStatusDot(panel, x, dy, T.positive, dsz)
        elseif dot == "neg" then ZeD.Atoms.drawStatusDot(panel, x, dy, T.danger, dsz)
        else ZeD.Atoms.drawStatusHollow(panel, x, dy, T.toneLo or T.textDim, dsz) end
        x = x + dsz + T.px(6)
        panel:drawText(text, x, y, tc.r, tc.g, tc.b, tc.a or 1, T.fontF1)
        x = x + ZeD.TM:MeasureStringX(T.fontF1, text) + T.px(14)
    end
    -- (Identity's wording: Positive / Negative)
    part("pos", ZeD.textCase(tr("UI_ZeD_Identity_TraitsPositive", good)))
    part("neg", ZeD.textCase(tr("UI_ZeD_Identity_TraitsNegative", bad)))
    part("off", ZeD.textCase(tr("UI_ZeD_TAS_NoTraitN", none)))
end

-- a category: the section head (folds; the count of ladders after it)
local function drawCat(panel, win, it, y, mx, my)
    local hov = mx ~= nil and mx >= it.x and mx < it.x + it.w and my >= y and my < y + it.h
    if hov then help(win, tr(it.shut and "UI_ZeD_TAS_HelpCatShow" or "UI_ZeD_TAS_HelpCatHide", catName(it.cat))) end
    ZeD.Molecules.drawSectionHeader(panel, it.x, y, it.w, catName(it.cat), it.n, not it.shut, hov, nil, nil, nil, nil, nil,
        { focus = focusOf(win, "tas:cat:" .. it.cat) })
end

local function drawRow(panel, win, st, it, y, mx, my)
    local T = ZeD.T
    local A = ZeD.Atoms
    local r = it.row
    local sel = st.sel == r.id
    local hov = mx ~= nil and mx >= it.x and mx < it.x + it.w and my >= y and my < y + it.h
    local ac = T.accent
    if it.odd then local s = T.stripe; panel:drawRect(it.x, y, it.w, it.h, s.a or 1, s.r, s.g, s.b) end
    -- the progress as the row's fill (Skills' colours), then the wash for the picked row, the
    -- hover wash and the controller's mark: all under the words
    if r.level > 0 then
        local fc, fa = fillColour(T, r)
        local fw = (r.level >= 10) and it.w or math.floor(it.w * r.frac)
        if fw > 0 then panel:drawRect(it.x, y, fw, it.h, fa, fc.r, fc.g, fc.b) end
    end
    if sel then panel:drawRect(it.x, y, it.w, it.h, T.selectionA or 0.30, ac.r, ac.g, ac.b) end
    if hov then
        local hv = T.hover
        panel:drawRect(it.x, y, it.w, it.h, hv.a, hv.r, hv.g, hv.b)
        help(win, tr("UI_ZeD_TAS_HelpRow", r.name))
    end
    local ink = T.text
    local fo = focusOf(win, "tas:row:" .. r.id)
    if fo and ZeD.Focus.mark(panel, it.x, y, it.w, it.h, fo) then ink = T.textOnFocus end
    -- the level square (Skills' strengths)
    local bw = T.px(BADGE_W)
    local s3 = T.surf3
    panel:drawRect(it.x, y, bw, it.h, r.level > 0 and 0.25 or 0.12, s3.r, s3.g, s3.b)
    local lv = tostring(r.level)
    local lc = (r.level == 0) and T.textDim or ink
    panel:drawText(lv, it.x + math.floor((bw - ZeD.TM:MeasureStringX(T.fontF2, lv)) / 2), y + math.floor((it.h - F(2)) / 2),
        lc.r, lc.g, lc.b, (r.level == 0) and ((lc.a or 1) * 0.7) or (lc.a or 1), T.fontF2)
    -- the name
    local nx = it.x + bw + T.px(6)
    panel:drawText(A.truncateText(r.name, T.fontF2, T.px(NAME_W)), nx, y + math.floor((it.h - F(2)) / 2), ink.r, ink.g, ink.b, ink.a or 1, T.fontF2)
    -- the ten steps: framed cells (the standard meter), lit up to the level; a step that
    -- holds a good or bad trait has a green or red frame
    local sx = nx + T.px(NAME_W) + T.px(6)
    local sw, sh, sg = T.px(STEP_W), T.px(STEP_H), T.px(STEP_GAP)
    local sy = y + math.floor((it.h - sh) / 2)
    local bs, bdc = T.borderS, T.base
    it.steps = {}
    for L = 1, 10 do
        local x0 = sx + (L - 1) * (sw + sg)
        panel:drawRect(x0, sy, sw, sh, 1, bdc.r, bdc.g, bdc.b)
        local tx = T.text
        if L <= r.level then
            panel:drawRect(x0, sy, sw, sh, 1, tx.r, tx.g, tx.b)
        elseif L == r.level + 1 and r.level < 10 and r.frac > 0 then
            panel:drawRect(x0, sy, math.floor(sw * r.frac), sh, 1, tx.r, tx.g, tx.b)
        end
        local frameC = (r.steps[L] == "+" and T.positive) or (r.steps[L] == "-" and T.danger) or bs
        A.frame(panel, x0, sy, sw, sh, frameC)
        if L == r.level then
            local th = T.textHead or T.text
            A.frame(panel, x0 - T.px(2), sy - T.px(2), sw + T.px(4), sh + T.px(4), th)
        end
        it.steps[L] = { x = x0, y = sy, w = sw, h = sh }
    end
    -- the trait now, or No trait; New since the tab was last opened
    local cx = sx + 10 * (sw + sg) + T.px(6)
    local dsz = T.px(6)
    if #r.now == 0 then
        local c = T.toneLo or T.textDim
        local text = tr("UI_ZeD_TAS_NoTrait")
        local tw = ZeD.TM:MeasureStringX(T.fontF2, text) + dsz + T.px(7)
        local x0 = it.x + it.w - T.px(6) - tw
        A.drawStatusHollow(panel, x0, y + math.floor((it.h - dsz) / 2), c, dsz)
        panel:drawText(text, x0 + dsz + T.px(7), y + math.floor((it.h - F(2)) / 2), c.r, c.g, c.b, c.a or 1, T.fontF2)
    else
        local isNew = false
        local parts = {}
        for _, t in ipairs(r.now) do
            parts[#parts + 1] = t
            if st.newSet and st.newSet[t] then isNew = true end
        end
        local newText = tr("UI_ZeD_TAS_New")
        -- the New tag: the one tag look with the accent square (16u, its words in sentence case)
        local newW = isNew and (ZeD.TM:MeasureStringX(T.fontF1, ZeD.textCase(newText)) + T.px(20) + T.px(6)) or 0
        -- right-aligned: measure the whole chip
        local total = newW
        local texts = {}
        for i, t in ipairs(parts) do
            texts[i] = tinfo(t).label
            total = total + dsz + T.px(6) + ZeD.TM:MeasureStringX(T.fontF2, texts[i]) + (i > 1 and T.px(8) or 0)
        end
        local x0 = math.max(cx, it.x + it.w - T.px(6) - total)
        local maxX = it.x + it.w - T.px(6) - newW
        for i, t in ipairs(parts) do
            if i > 1 then x0 = x0 + T.px(8) end
            if x0 + dsz >= maxX then break end
            A.drawStatusDot(panel, x0, y + math.floor((it.h - dsz) / 2), tinfo(t).bad and T.danger or T.positive, dsz)
            x0 = x0 + dsz + T.px(6)
            local txt = A.truncateText(texts[i], T.fontF2, maxX - x0)
            panel:drawText(txt, x0, y + math.floor((it.h - F(2)) / 2), ink.r, ink.g, ink.b, ink.a or 1, T.fontF2)
            x0 = x0 + ZeD.TM:MeasureStringX(T.fontF2, txt)
        end
        if isNew then
            local th = T.px(16)
            ZeD.Molecules.drawTag(panel, it.x + it.w - T.px(6) - newW + T.px(6), y + math.floor((it.h - th) / 2), newText, T.accent)
        end
    end
end

-- what moving to level L changes
local function changesAt(r, L)
    if L < 0 or L > 10 then return nil end
    local a, b = r.at(r.level), r.at(L)
    local ina, inb = {}, {}
    for _, t in ipairs(a) do ina[t] = true end
    for _, t in ipairs(b) do inb[t] = true end
    local gain, lose = {}, {}
    for _, t in ipairs(b) do if not ina[t] then gain[#gain + 1] = t end end
    for _, t in ipairs(a) do if not inb[t] then lose[#lose + 1] = t end end
    return gain, lose
end
local function chText(gain, lose)
    local p = {}
    for _, t in ipairs(gain) do p[#p + 1] = tr("UI_ZeD_TAS_GainT", tinfo(t).label) end
    for _, t in ipairs(lose) do p[#p + 1] = tr("UI_ZeD_TAS_LoseT", tinfo(t).label) end
    if #p == 0 then return tr("UI_ZeD_TAS_NoChange") end
    return table.concat(p, ", ")
end
local function firstChange(r, dir)
    local L = r.level + dir
    while L >= 0 and L <= 10 do
        local g, l = changesAt(r, L)
        if g and (#g > 0 or #l > 0) then return L, g, l end
        L = L + dir
    end
    return nil
end

-- the mod's Gain / Lose lists in its words ("Reading books or magazines +10 XP per 50 pages")
local function fmtEntry(e, sign)
    local name = getTextOrNull("UI_TAS_Action_" .. tostring(e.action)) or tostring(e.action)
    if e.min and e.max then name = name .. " " .. e.min .. "-" .. e.max .. " kg" end
    local v = e.xp or e.xpPerHour or e.xpPerDay
    if type(v) == "table" then v = table.concat(v, "-")
    elseif type(v) == "number" and v < 1 then v = "x" .. tostring(v) end
    local suffix = e.xpPerHour and "/h" or (e.xpPerDay and "/d" or "")
    local value = ((sign > 0) and "+" or "-") .. tostring(v) .. " XP" .. suffix
    if e.everyPages then value = value .. " " .. getText("UI_TAS_EveryPages", tostring(e.everyPages)) end
    return name .. " " .. value
end
local function actionLists(def)
    local A = TAS.XP and TAS.XP.actions and TAS.XP.actions[def.id]
    if not A then return nil end
    local g, l = {}, {}
    for _, e in ipairs(A.good or {}) do g[#g + 1] = fmtEntry(e, 1) end
    for _, e in ipairs(A.goodPassive or {}) do g[#g + 1] = fmtEntry(e, 1) end
    for _, e in ipairs(A.bad or {}) do l[#l + 1] = fmtEntry(e, -1) end
    for _, e in ipairs(A.badPassive or {}) do l[#l + 1] = fmtEntry(e, -1) end
    return g, l
end

local function joinAnd(list)
    if #list == 0 then return "" end
    if #list == 1 then return list[1] end
    local head = {}
    for i = 1, #list - 1 do head[i] = list[i] end
    return tr("UI_ZeD_TAS_And", table.concat(head, ", "), list[#list])
end

local function progressText(p, r)
    if r.kind == "weight" then
        local wkg = r.weight or (p:getNutrition() and p:getNutrition():getWeight()) or 0
        return tr("UI_ZeD_TAS_WeightKg", tostring(math.floor(wkg * 10 + 0.5) / 10)), nil
    end
    if r.kind == "skill" then
        local perks = r.def.perks or (r.def.perk and { r.def.perk }) or {}
        local names, total = {}, 0
        for _, pk in ipairs(perks) do
            local nm = PerkFactory.getPerkName(pk)
            if nm then names[#names + 1] = nm end
            local ok, v = pcall(TAS.Spectrum.getPerkFractionalLevel, p, pk)
            total = total + ((ok and v) or 0)
        end
        local avg = (#perks > 0) and (math.floor(total / #perks * 10) / 10) or r.level
        local key = (#perks > 1) and "UI_ZeD_TAS_FollowsAvg" or "UI_ZeD_TAS_Follows"
        return tr(key, joinAnd(names), tostring(avg)), r.frac
    end
    if r.level >= 10 then return tr("UI_ZeD_TAS_TopLevel"), nil end
    return tr("UI_ZeD_TAS_XpTo", math.floor(r.into), math.floor(r.next), r.level + 1), r.frac
end

-- the key / value lines of the details: what the progress is, the mod's Gain and Lose lists,
-- what the next level up or down changes, and what the traits are now
local function detailItems(p, r)
    local items = {}
    local ptext, pbar = progressText(p, r)
    items[#items + 1] = { k = tr("UI_ZeD_TAS_KProgress"), v = ptext, bar = pbar }
    local gains, losses = actionLists(r.def)
    if gains then
        items[#items + 1] = { k = getText("UI_TAS_Gain"), v = (#gains > 0) and table.concat(gains, ", ") or tr("UI_ZeD_TAS_NoneList") }
        items[#items + 1] = { k = getText("UI_TAS_Lose"), v = (#losses > 0) and table.concat(losses, ", ") or tr("UI_ZeD_TAS_NoneList") }
    end
    local uL, ug, ul = firstChange(r, 1)
    local dL, dg, dl = firstChange(r, -1)
    local up = uL and tr("UI_ZeD_TAS_At", uL, chText(ug, ul)) or tr("UI_ZeD_TAS_NoChangeAbove")
    if dL then up = up .. " | " .. tr("UI_ZeD_TAS_DownAt", dL, chText(dg, dl)) end
    items[#items + 1] = { k = tr("UI_ZeD_TAS_KLevelUp"), v = up }
    local now
    if #r.now == 0 then now = tr("UI_ZeD_TAS_NowNone")
    else
        local parts = {}
        for _, t in ipairs(r.now) do
            local i = tinfo(t)
            parts[#parts + 1] = i.label .. ": " .. ((i.desc ~= "") and i.desc or tr("UI_ZeD_TAS_NoDesc"))
        end
        now = table.concat(parts, " ")
    end
    items[#items + 1] = { k = tr("UI_ZeD_TAS_KNow"), v = now }
    return items
end

-- the height of the title row, the ladder and its ticks (before the key / value lines)
local function ladderTopH()
    local T = ZeD.T
    return T.px(8) + F(4) + T.px(8) + T.px(14) + T.px(3) + F(5) + T.px(2) + F(5) + T.px(6)
end

-- the wrapped lines of every item at a width, and the height of the lines (nothing is dropped)
local function layoutItems(items, iw)
    local T = ZeD.T
    local vw = iw - T.px(KEY_W) - T.px(8)
    local h = 0
    for _, it in ipairs(items) do
        it.lines = ZeD.Atoms.wrapText(it.v or "", T.fontF2, math.max(T.px(40), vw - (it.bar and T.px(170) or 0)))
        h = h + #it.lines * F(2) + T.px(3)
    end
    return h
end

local function drawDetail(panel, win, st, x, y, w, h)
    local T = ZeD.T
    local A = ZeD.Atoms
    local bs = T.borderS
    A.surfaceFill(panel, x, y, w, h, "surf2")
    A.drawDividerH(panel, x, y, w, true)
    st.detRect = { x = x, y = y, w = w, h = h }
    local sc = st.detScroll
    sc.visible = false
    local p = win._playerObj
    -- another mod's row (ZeD.TraitsTab): its own support draws its details
    local extId = st.hover or st.sel
    if extId and not st.byId[extId] and ZeD.TraitsTab.drawDetail(panel, win, extId, x, y, w, h, sc) then return end
    local r = st.byId[st.hover or st.sel or ""]
    local pad = T.px(PAD)
    local ix, iw = x + pad, w - pad * 2
    local dim, tc = T.toneLo or T.textDim, T.text
    local innerH = h - T.px(1)
    panel:setStencilRect(x, y + T.px(1), w, innerH)
    if not r or not p then
        local lines = A.wrapText(tr("UI_ZeD_TAS_Pick"), T.fontF2, iw)
        for i, l in ipairs(lines) do panel:drawText(l, ix, y + T.px(12) + (i - 1) * F(2), dim.r, dim.g, dim.b, dim.a or 1, T.fontF2) end
        panel:clearStencilRect()
        return
    end
    -- the content, measured first: a panel too short for it scrolls (a scrollbar, the wheel over it)
    -- instead of dropping lines
    local items = detailItems(p, r)
    local sbW = T.sp.scrollbarW
    local contentH = ladderTopH() + layoutItems(items, iw) + T.px(6)
    local needs = contentH > innerH
    if needs then
        iw = iw - sbW
        contentH = ladderTopH() + layoutItems(items, iw) + T.px(6)
    end
    if st.detKey ~= r.id then st.detKey = r.id; sc:setScrollPos(0) end
    local off = 0
    if needs then
        sc.visible = true
        sc.x, sc.y, sc.height = x + w - sbW, y + T.px(1), innerH
        sc:setBarSize(innerH / contentH)
        off = math.floor(sc.scrollPos * (contentH - innerH))
        panel:setStencilRect(x, y + T.px(1), w - sbW, innerH)
    else
        sc:setScrollPos(0)
    end
    local cy = y + T.px(8) - off
    -- the title row
    local th = T.textHead or tc
    panel:drawText(r.name, ix, cy, th.r, th.g, th.b, th.a or 1, T.fontF4)
    local lvText = tr("UI_ZeD_TAS_LevelOf", r.level)
    local lx = ix + ZeD.TM:MeasureStringX(T.fontF4, r.name) + T.px(10)
    panel:drawText(lvText, lx, cy + F(4) - F(1), dim.r, dim.g, dim.b, dim.a or 1, T.fontF1)
    local catT = tr("UI_ZeD_TAS_Category", catName(catKnown(r.cat) and r.cat or "other"))
    panel:drawText(catT, ix + iw - ZeD.TM:MeasureStringX(T.fontF1, catT), cy + F(4) - F(1), dim.r, dim.g, dim.b, dim.a or 1, T.fontF1)
    cy = cy + F(4) + T.px(8)
    -- the ladder: each range, its trait under it, a mark where you stand, the levels
    local function px(L) return ix + math.floor(L / 11 * iw) end
    local segH = T.px(14)
    for _, b in ipairs(r.bands) do
        local list = bandTraits(b)
        local bad = list[1] and tinfo(list[1]).bad
        local inb = r.level >= b.min and r.level <= (b.max or 10)
        local x0, x1 = px(b.min), px((b.max or 10) + 1)
        local col = (not list[1]) and T.surf1 or (bad and T.danger or T.positive)
        if list[1] then panel:drawRect(x0, cy, x1 - x0 - T.px(2), segH, 0.3, col.r, col.g, col.b)
        else panel:drawRect(x0, cy, x1 - x0 - T.px(2), segH, 1, col.r, col.g, col.b) end
        local bc = list[1] and col or bs
        panel:drawRectBorder(x0, cy, x1 - x0 - T.px(2), segH, 0.8, bc.r, bc.g, bc.b)
        if inb then panel:drawRectBorder(x0 + T.px(1), cy + T.px(1), x1 - x0 - T.px(4), segH - T.px(2), 1, th.r, th.g, th.b) end
        local names = {}
        for _, t in ipairs(list) do names[#names + 1] = tinfo(t).label end
        local lab = (#names > 0) and table.concat(names, " / ") or tr("UI_ZeD_TAS_NoneShort")
        local lc = inb and th or dim
        -- ranges can overlap (Courage): a name stops where the next range starts
        local lw = x1 - x0 - T.px(4)
        for _, b2 in ipairs(r.bands) do
            if b2.min > b.min then lw = math.min(lw, px(b2.min) - x0 - T.px(4)) end
        end
        if lw > T.px(6) then
            panel:drawText(A.truncateText(lab, T.fontF5, lw), x0 + T.px(2), cy + segH + T.px(3), lc.r, lc.g, lc.b, lc.a or 1, T.fontF5)
        end
    end
    local mxp = px(r.level) + math.floor((px(r.level + 1) - px(r.level)) * math.min(r.frac, 0.999))
    A.drawTriangleDown(panel, mxp - T.px(5), cy - T.px(6), T.px(10), T.accentBright)
    local tickY = cy + segH + T.px(3) + F(5) + T.px(2)
    for L = 0, 10 do
        local s = tostring(L)
        local cx = px(L) + math.floor((px(L + 1) - px(L)) / 2) - math.floor(ZeD.TM:MeasureStringX(T.fontF5, s) / 2)
        panel:drawText(s, cx, tickY, dim.r, dim.g, dim.b, dim.a or 1, T.fontF5)
    end
    cy = tickY + F(5) + T.px(6)
    -- key / value lines: the key in the small font, sentence case; the value wrapped, all of it
    local vx = ix + T.px(KEY_W) + T.px(8)
    for _, it in ipairs(items) do
        panel:drawText(ZeD.textCase(it.k), ix, cy + T.px(2), dim.r, dim.g, dim.b, dim.a or 1, T.fontF1)
        for i, l in ipairs(it.lines) do
            panel:drawText(l, vx, cy, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
            if i == 1 and it.bar then
                -- the framed strip beside the first line (the standard amount bar)
                local bx = vx + ZeD.TM:MeasureStringX(T.fontF2, l) + T.px(8)
                local bw2 = math.min(T.px(160), ix + iw - bx)
                if bw2 > T.px(20) then
                    A.drawFillBar(panel, bx, cy + math.floor((F(2) - T.fillBarH) / 2), bw2, it.bar, false, T.accent)
                end
            end
            cy = cy + F(2)
        end
        cy = cy + T.px(3)
    end
    panel:clearStencilRect()
    if needs then sc:draw(panel) end
end

-- keep the controller's focus in view (once per newly focused stop)
local function followFocus(win, st, viewH, maxOff)
    local el = focusedEl(win)
    if not el or not el.cy or el.id == st.lastPinned then return end
    st.lastPinned = el.id
    local off = st.off or 0
    local newOff = off
    if el.cy < off then newOff = el.cy - ZeD.T.px(6)
    elseif el.cy + el.h > off + viewH then newOff = el.cy + el.h - viewH + ZeD.T.px(6) end
    newOff = math.max(0, math.min(maxOff, newOff))
    if newOff ~= off and maxOff > 0 then st.scroll:setScrollPos(newOff / maxOff) end
end

function S.render(panel, win, x, y, w, h)
    local T = ZeD.T
    local st = state(win)
    local p = win._playerObj
    if not p then return end
    if not st.visiting then st.visiting = true; st.visitStart = true; st.tick = 999 end
    refresh(win, st, p)
    local M = ZeD.Molecules
    local headH = M.getTabHeaderH()
    -- the details keep their height, but never more than half the tab (a short window keeps rows to walk)
    local detH = math.min(T.px(DET_H), math.floor((h - headH) / 2))
    local sy, sh = y + headH, h - headH - detH
    local scroll = st.scroll
    local L = layout(st, w - T.sp.scrollbarW, win)
    st.L = L
    local needs = L.h > sh
    scroll.visible = needs
    local maxOff = math.max(0, L.h - sh)
    if needs then
        scroll.x, scroll.y, scroll.height = x + w - T.sp.scrollbarW, sy, sh
        scroll:setBarSize(sh / math.max(1, L.h))
    else
        scroll:setScrollPos(0)
    end
    followFocus(win, st, sh, maxOff)
    local off = needs and math.floor(scroll.scrollPos * maxOff) or 0
    st.off, st.sy = off, sy
    local mx, my = panel:getMouseX(), panel:getMouseY()
    local Fo = ZeD.Input and ZeD.Input.Focus
    -- (the mouse's hover goes quiet while the controller's mark shows)
    if not (mx >= x and mx < x + w and my >= sy and my < sy + sh) or (Fo and Fo.cuesVisible and Fo.cuesVisible()) then mx, my = nil, nil end
    -- the focused row picks itself (the details follow focus with no press)
    local fe = focusedEl(win)
    if fe and fe.rowId then st.sel = fe.rowId end
    st.zones, st.hover, st.stepHover = {}, nil, nil
    panel:setStencilRect(x, sy, w, sh)
    for _, it in ipairs(L.items) do
        local dy = sy + it.y - off
        local ih = it.h or T.px(20)
        if dy + ih >= sy and dy <= sy + sh then
            local k = it.kind
            if k == "credit" then drawCredit(panel, win, st, it, dy)
            elseif k == "sum" then drawSum(panel, st, it, dy)
            elseif k == "empty" then
                ZeD.Molecules.drawEmptyLine(panel, it.x, dy, it.w, tr("UI_ZeD_TAS_Nothing", S.find))
            elseif k == "cat" then drawCat(panel, win, it, dy, mx, my)
            elseif k == "ext" then
                -- another mod's item (ZeD.TraitsTab); a hovered row of it feeds the details
                local hid = ZeD.TraitsTab.drawItem(panel, win, it, dy, mx, my, st.sel)
                if hid then st.hover = hid end
            elseif k == "row" then
                drawRow(panel, win, st, it, dy, mx, my)
                if mx and mx >= it.x and mx < it.x + it.w and my >= dy and my < dy + it.h then
                    st.hover = it.row.id
                    for L2, s in ipairs(it.steps or {}) do
                        if mx >= s.x - T.px(1) and mx < s.x + s.w + T.px(1) and my >= s.y - T.px(2) and my < s.y + s.h + T.px(2) then
                            st.stepHover = { row = it.row, L = L2, x = s.x, y = s.y, w = s.w, h = s.h }
                        end
                    end
                end
            end
            if (k == "cat" or k == "row" or k == "ext") then
                local zy0, zy1 = math.max(sy, dy), math.min(sy + sh, dy + it.h)
                if zy1 > zy0 then st.zones[#st.zones + 1] = { x = it.x, y = zy0, w = it.w, h = zy1 - zy0, item = it } end
            end
        end
    end
    panel:clearStencilRect()
    panel:setStencilRect(0, 0, panel:getWidth(), panel:getHeight())
    drawDetail(panel, win, st, x, y + h - detH, w, detH)
    -- the header: the tab's name; Find at its right (a text box placed by onWindowFrame)
    M.drawTabHeader(panel, x, y, w, getText("UI_TAS_Tab"), false, false, true)
    local fh = T.inputH or T.px(22)
    st.findRect = { x = x + w - T.px(PAD) - T.px(FIND_W), y = y + math.floor((headH - fh) / 2), w = T.px(FIND_W), h = fh }
    local findFocus = focusOf(win, "tas:find")
    if findFocus then
        local f = st.findRect
        ZeD.Focus.mark(panel, f.x, f.y, f.w, f.h, findFocus)
    end
    if needs then scroll:draw(panel) end
    -- a step names its trait and level
    local sh2 = st.stepHover
    if sh2 then
        local names = {}
        for _, b in ipairs(sh2.row.bands) do
            if sh2.L >= b.min and sh2.L <= (b.max or 10) then
                for _, t in ipairs(bandTraits(b)) do names[#names + 1] = tinfo(t).label end
            end
        end
        local body = (#names > 0) and names[1] or tr("UI_ZeD_TAS_NoTrait")
        for i = 2, #names do body = tr("UI_ZeD_TAS_Or", body, names[i]) end
        local lines = { body }
        if sh2.L == sh2.row.level then lines[#lines + 1] = tr("UI_ZeD_TAS_Here") end
        -- the shared detail card, asked of the window's overlay (it appears after the shared pause)
        ZeD.HairBeard.hoverCard(panel, win, "tas:step:" .. tostring(sh2.row.id) .. ":" .. tostring(sh2.L),
            tr("UI_ZeD_TAS_StepTitle", sh2.row.name, sh2.L), lines, sh2, false)
    end
    st.rendered = true
end

-- ---------------------------------------------------------------------------
-- INPUT
-- ---------------------------------------------------------------------------
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end

local function setOnly(st, v)
    S.only = v
    st.scroll:setScrollPos(0)
end

function S.onClick(win, x, y)
    local st = state(win)
    local sc = st.scroll
    if sc.visible and x >= sc.x and x < sc.x + sc.width and y >= sc.y and y < sc.y + sc.height then
        sc:handleMouseDown(y - sc.y)
        return
    end
    local ds = st.detScroll
    if ds and ds.visible and x >= ds.x and x < ds.x + ds.width and y >= ds.y and y < ds.y + ds.height then
        ds:handleMouseDown(y - ds.y)
        return
    end
    for _, o in ipairs(st.only or {}) do
        local oy = o.y
        if x >= o.x and x < o.x + o.w and y >= oy and y < oy + o.h then
            setOnly(st, o.val); getSoundManager():playUISound("UIActivateButton"); return
        end
    end
    for _, z in ipairs(st.zones or {}) do
        if inRect(z, x, y) then
            local it = z.item
            if it.kind == "cat" then S.closed[it.cat] = not S.closed[it.cat]
            elseif it.kind == "row" then st.sel = it.row.id
            elseif it.kind == "ext" then
                -- another mod's item: it folds its own heads; a row comes back to be picked
                local id = ZeD.TraitsTab.click(win, it)
                if id then st.sel = id end
            end
            getSoundManager():playUISound("UIActivateButton")
            return
        end
    end
end

-- the Find box with the controller: the game's on-screen keyboard
local function editFind(win, st)
    local f = st.field
    if not (f and f.input) then return end
    local p = win._playerObj
    local pn = p and p:getPlayerNum() or 0
    local jd = JoypadState.players[pn + 1]
    if jd and OnScreenKeyboard and OnScreenKeyboard.Show then
        local ok, osk = pcall(OnScreenKeyboard.Show, pn, f.input, jd)
        if ok and osk then return end
    end
    f.input:focus()
end

-- the controller's stops: Find, All | With a trait, each category, each row
function S.buildFocusables(win)
    local st = win._tas
    if not (st and st.L and st.sy) then return {} end
    local out = {}
    local fr = st.findRect
    if fr then
        out[#out + 1] = { x = fr.x, y = fr.y, w = fr.w, h = fr.h, id = "tas:find", tas = true,
            onFocus = function() end, onActivate = function(w) editFind(w, st) end }
    end
    local L = st.L
    for _, it in ipairs(L.items) do
        local dy = st.sy + it.y - (st.off or 0)
        if it.kind == "credit" then
            local o = st.only and st.only[1]
            local o2 = st.only and st.only[2]
            if o and o2 then
                out[#out + 1] = { x = o.x, y = dy, w = o2.x + o2.w - o.x, h = it.h, cy = it.y, id = "tas:only", tas = true,
                    onFocus = function() end,
                    onActivate = function() setOnly(st, not S.only) end,
                    onDpadDir = function(w, el, dir)
                        if dir == "left" and S.only then setOnly(st, false); return true end
                        if dir == "right" and not S.only then setOnly(st, true); return true end
                        return false
                    end }
            end
        elseif it.kind == "cat" then
            local c = it.cat
            out[#out + 1] = { x = it.x, y = dy, w = it.w, h = it.h, cy = it.y, id = "tas:cat:" .. c, tas = true,
                onFocus = function() end, onActivate = function() S.closed[c] = not S.closed[c] end }
        elseif it.kind == "row" then
            local id = it.row.id
            out[#out + 1] = { x = it.x, y = dy, w = it.w, h = it.h, cy = it.y, id = "tas:row:" .. id, tas = true, rowId = id,
                onFocus = function() st.sel = id end, onActivate = function() end }
        elseif it.kind == "ext" then
            -- another mod's head or row (ZeD.TraitsTab); its stop carries tas = true and rowId
            local el = ZeD.TraitsTab.focusable(win, it, dy)
            if el then out[#out + 1] = el end
        end
    end
    return out
end

function S.scrollKey(win)
    local st = win._tas
    if not st then return nil end
    local n = st.L and #st.L.items or 0
    local closed = {}
    for c, v in pairs(S.closed) do if v then closed[#closed + 1] = c end end
    table.sort(closed)
    return tostring(st.off or 0) .. ":" .. tostring(S.only) .. ":" .. tostring(S.find) .. ":" .. n .. ":" .. table.concat(closed, ",")
end

-- every frame, any tab: the Find box shows only on this tab
function S.onWindowFrame(win, drawerW)
    local st = win._tas
    local show = win._activeTab == TAB_ID and win._drawerMode == "tab" and not win._drawerItem and (drawerW or 0) > 0
    if st and not show then st.visiting = false end
    if not show and not (st and st.field) then return end
    st = state(win)
    local dp = win._drawerPanel
    if not st.field and dp then
        local f = ZeD_SearchField:new(0, 0, ZeD.T.px(FIND_W), tr("UI_ZeD_TAS_Find"))
        f:initialise()
        f:setVisible(false)
        f.onFilter = function(_, text)
            S.find = text or ""
            st.scroll:setScrollPos(0)
        end
        dp:addChild(f)
        st.field = f
    end
    local f = st.field
    if not f then return end
    local r = st.findRect
    local on = (show and st.rendered and r ~= nil and r.x + r.w <= drawerW) and true or false
    st.rendered = false
    if on then
        f:setX(r.x); f:setY(r.y); f:setWidth(r.w); f:setHeight(r.h)
    end
    if f:isVisible() ~= on then f:setVisible(on) end
end

-- ---------------------------------------------------------------------------
-- THE TAB
-- ---------------------------------------------------------------------------
-- its lit pixel-art icon, as every other tab's (ZeDUI/tools/tabpx/icons.py "traits", drawn by ZeD_TabPx.lua)
require "ZeD/ZeD_TabPx"
if ZeD.TabPx and ZeD.TabPx.ICONS then ZeD.TabPx.ICONS[TAB_ID] = true end

ZeD_CharacterWindow.addTab({
    id = TAB_ID, after = "skills", group = 2, glyph = "T",
    iconName = "traits-tab-white",
    label = function() return getText("UI_TAS_Tab") end,
    render = S.render,
    -- (the wheel scrolls the details when the pointer is over them, the list otherwise)
    scroll = function(win)
        local st = win._tas
        if not st then return nil end
        local ds, r, dp = st.detScroll, st.detRect, win._drawerPanel
        if ds and ds.visible and r and dp then
            local mx, my = dp:getMouseX(), dp:getMouseY()
            if ds.dragging or (mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h) then return ds end
        end
        return st.scroll
    end,
    onClick = S.onClick,
    buildFocusables = S.buildFocusables,
    scrollKey = S.scrollKey,
    onWindowFrame = S.onWindowFrame,
})
