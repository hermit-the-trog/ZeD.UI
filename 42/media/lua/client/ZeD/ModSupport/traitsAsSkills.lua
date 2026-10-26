-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/traitsAsSkills.lua
-- ============================================================================
-- SUPPORT FOR TRAITS AS SKILLS (mod id traitsAsSkills, Workshop 3784847437, by GersonRess)
-- Mockup zed_traits_tab_v1, approved "as recommended" Oct 26 2026.
--
-- The mod turns traits into ladders that level up and down with play and puts a
-- Traits tab in the game's Character window, which ZeD never shows. This is that
-- tab in ZeD's Character window, right after Skills, there only while the mod is
-- on: one row per ladder drawn like a Skills row (the level in the square, the
-- progress as the row's fill), ten small steps with a green or red line under the
-- steps that hold a good or bad trait, the trait you have now at the right (NEW
-- until the tab has been opened once since it came). Categories fold; Mind and
-- Physical first, Skills last (the mockup's order). Find and All | With a trait
-- narrow the list. The details at the foot follow the focused (or hovered) row:
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

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.traitsAsSkills = S

local TAB_ID = "traits"

-- design units
local PAD, ROW_H, CAT_H, BADGE_W, NAME_W, STEP_W, STEP_H, STEP_GAP, DET_H, FIND_W, KEY_W = 10, 26, 26, 20, 112, 12, 13, 2, 218, 150, 76
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
        st = { scroll = ZeD_ScrollbarState:new(), tick = 999, rows = {}, byId = {}, zones = {}, els = {} }
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

local function layout(st, w)
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
    if #vis == 0 then
        add(L, { kind = "empty", x = x, y = y + T.px(4) })
        y = y + T.px(4) + F(2) + T.px(12)
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
            y = y + T.px(CAT_H)
            if not shut then
                for i, r in ipairs(rs) do
                    y = y + T.px(2)
                    add(L, { kind = "row", row = r, odd = i % 2 == 0, x = x, y = y, w = cw, h = T.px(ROW_H) })
                    y = y + T.px(ROW_H)
                end
            end
        end
    end
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
local function isFoc(win, id) local el = focusedEl(win); return el ~= nil and el.id == id end

local function fillColour(T, r)
    if r.level >= 10 then return T.warning end
    if r.frac >= 0.75 then return T.danger end
    if r.frac >= 0.4 then return T.warning end
    return T.positive
end

local function drawCredit(panel, win, st, it, y)
    local T = ZeD.T
    local c = T.toneLo or T.textDim
    local mi = getModInfoByID and getModInfoByID(MOD_ID)
    local name = mi and mi:getName() or "Traits As Skills"
    local author = nil
    if mi then local ok, a = pcall(function() return mi:getAuthor() end); if ok and a and a ~= "" then author = a end end
    local text = author and tr("UI_ZeD_TAS_Credit", name, author) or name
    panel:drawText(text, it.x, y + math.floor((it.h - F(5)) / 2), c.r, c.g, c.b, c.a or 1, T.fontF5)
    -- All | With a trait
    local withT = 0
    for _, r in ipairs(st.rows) do if #r.now > 0 then withT = withT + 1 end end
    local labels = { tr("UI_ZeD_TAS_All", #st.rows), tr("UI_ZeD_TAS_WithTrait", withT) }
    local f = T.fontF5
    local ws = {}
    local tw = 0
    for i, l in ipairs(labels) do ws[i] = ZeD.TM:MeasureStringX(f, l) + T.px(16); tw = tw + ws[i] end
    local bx = it.x + it.w - tw
    local bs, ac = T.borderS, T.accent
    st.only = {}
    local foc = isFoc(win, "tas:only")
    for i, l in ipairs(labels) do
        local on = (i == 2) == (S.only == true)
        if on then panel:drawRect(bx, y, ws[i], it.h, 1, ac.r, ac.g, ac.b) end
        local tc = on and T.textOnAccent or T.text
        panel:drawText(l, bx + T.px(8), y + math.floor((it.h - F(5)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f)
        if i > 1 then panel:drawRect(bx, y, T.px(1), it.h, bs.a or 1, bs.r, bs.g, bs.b) end
        if foc and on then ZeD.Atoms.drawAccentRing(panel, bx, y, ws[i], it.h, T.px(2), T.accentBright) end
        st.only[#st.only + 1] = { x = bx, y = y, w = ws[i], h = it.h, val = (i == 2) }
        bx = bx + ws[i]
    end
    panel:drawRectBorder(it.x + it.w - tw, y, tw, it.h, bs.a or 1, bs.r, bs.g, bs.b)
end

local function drawSum(panel, st, it, y)
    local T = ZeD.T
    local good, bad, none = 0, 0, 0
    for _, r in ipairs(st.rows) do
        if #r.now == 0 then none = none + 1 end
        for _, t in ipairs(r.now) do if tinfo(t).bad then bad = bad + 1 else good = good + 1 end end
    end
    local dsz = T.px(8)
    local x = it.x
    local tc = T.text
    local dy = y + math.floor((F(1) - dsz) / 2)
    local function part(dot, text)
        if dot == "pos" then ZeD.Atoms.drawStatusDot(panel, x, dy, T.positive, dsz)
        elseif dot == "neg" then ZeD.Atoms.drawStatusDot(panel, x, dy, T.danger, dsz)
        else ZeD.Atoms.drawStatusRing(panel, x, dy, T.toneLo or T.textDim, dsz) end
        x = x + dsz + T.px(5)
        panel:drawText(text, x, y, tc.r, tc.g, tc.b, tc.a or 1, T.fontF1)
        x = x + ZeD.TM:MeasureStringX(T.fontF1, text) + T.px(14)
    end
    part("pos", tr("UI_ZeD_TAS_Good", good))
    part("neg", tr("UI_ZeD_TAS_Bad", bad))
    part("off", tr("UI_ZeD_TAS_NoTraitN", none))
end

local function drawCat(panel, win, it, y, mx, my)
    local T = ZeD.T
    local foc = isFoc(win, "tas:cat:" .. it.cat)
    local hov = mx and mx >= it.x and mx < it.x + it.w and my >= y and my < y + it.h
    local ac, bd = T.accent, T.border
    if foc then panel:drawRect(it.x, y, it.w, it.h, 0.55, ac.r, ac.g, ac.b)
    elseif hov then panel:drawRect(it.x, y, it.w, it.h, 0.22, ac.r, ac.g, ac.b) end
    panel:drawRect(it.x, y + it.h - T.px(1), it.w, T.px(1), bd.a or 1, bd.r, bd.g, bd.b)
    local c = foc and T.textOnFocus or (T.toneLo or T.textDim)
    local tri = T.px(5)
    local ty = y + math.floor((it.h - tri) / 2)
    if it.shut then ZeD.Atoms.drawTriangleRight(panel, it.x + T.px(2), ty, tri, c)
    else ZeD.Atoms.drawTriangleDown(panel, it.x + T.px(2), ty, tri, c) end
    local nx = it.x + T.px(2) + tri + T.px(8)
    local name = catName(it.cat)
    panel:drawText(name, nx, y + math.floor((it.h - F(2)) / 2), c.r, c.g, c.b, c.a or 1, T.fontF2)
    local n = "(" .. it.n .. ")"
    panel:drawText(n, nx + ZeD.TM:MeasureStringX(T.fontF2, name) + T.px(6), y + math.floor((it.h - F(1)) / 2), c.r, c.g, c.b, c.a or 1, T.fontF1)
end

local function drawRow(panel, win, st, it, y, mx, my)
    local T = ZeD.T
    local r = it.row
    local sel = st.sel == r.id
    local foc = isFoc(win, "tas:row:" .. r.id)
    local hov = mx and mx >= it.x and mx < it.x + it.w and my >= y and my < y + it.h
    local ac = T.accent
    if it.odd then local s = T.stripe; panel:drawRect(it.x, y, it.w, it.h, s.a or 1, s.r, s.g, s.b) end
    if sel then panel:drawRect(it.x, y, it.w, it.h, 1, ac.r, ac.g, ac.b)
    else
        if foc then panel:drawRect(it.x, y, it.w, it.h, 0.55, ac.r, ac.g, ac.b)
        elseif hov then panel:drawRect(it.x, y, it.w, it.h, 0.22, ac.r, ac.g, ac.b) end
        -- the progress as the row's fill (Skills' colours)
        if r.level > 0 then
            local fc = fillColour(T, r)
            local fw = (r.level >= 10) and it.w or math.floor(it.w * r.frac)
            if fw > 0 then panel:drawRect(it.x, y, fw, it.h, 0.32, fc.r, fc.g, fc.b) end
        end
    end
    if foc then ZeD.Atoms.drawAccentRing(panel, it.x, y, it.w, it.h, T.px(2), T.accentBright) end
    local ink = sel and T.textOnAccent or (foc and T.textOnFocus or T.text)
    -- the level square
    local bw = T.px(BADGE_W)
    local s3 = T.surf3
    panel:drawRect(it.x, y, bw, it.h, sel and 0.15 or 0.6, sel and 0 or s3.r, sel and 0 or s3.g, sel and 0 or s3.b)
    local lv = tostring(r.level)
    local lc = (r.level == 0 and not sel) and (T.toneLo or T.textDim) or ink
    panel:drawText(lv, it.x + math.floor((bw - ZeD.TM:MeasureStringX(T.fontF2, lv)) / 2), y + math.floor((it.h - F(2)) / 2), lc.r, lc.g, lc.b, lc.a or 1, T.fontF2)
    -- the name
    local nx = it.x + bw + T.px(6)
    panel:drawText(ZeD.Atoms.truncateText(r.name, T.fontF2, T.px(NAME_W)), nx, y + math.floor((it.h - F(2)) / 2), ink.r, ink.g, ink.b, ink.a or 1, T.fontF2)
    -- the ten steps
    local sx = nx + T.px(NAME_W) + T.px(6)
    local sw, sh, sg = T.px(STEP_W), T.px(STEP_H), T.px(STEP_GAP)
    local sy = y + math.floor((it.h - sh) / 2)
    local bs, s1, bdc = T.borderS, T.surf1, T.surf4 or T.surf3
    it.steps = {}
    for L = 1, 10 do
        local x0 = sx + (L - 1) * (sw + sg)
        panel:drawRect(x0, sy, sw, sh, 1, s1.r, s1.g, s1.b)
        if L <= r.level then
            local tx = T.text
            panel:drawRect(x0, sy, sw, sh, 0.8, tx.r, tx.g, tx.b)
        elseif L == r.level + 1 and r.level < 10 and r.frac > 0 then
            local tx = T.text
            panel:drawRect(x0, sy, math.floor(sw * r.frac), sh, 0.45, tx.r, tx.g, tx.b)
        end
        panel:drawRectBorder(x0, sy, sw, sh, bs.a or 1, bs.r, bs.g, bs.b)
        local lineC = (r.steps[L] == "+" and T.positive) or (r.steps[L] == "-" and T.danger) or bdc
        panel:drawRect(x0, sy + sh - T.px(3), sw, T.px(3), 1, lineC.r, lineC.g, lineC.b)
        if L == r.level then
            local th = T.textHead or T.text
            panel:drawRectBorder(x0 - T.px(2), sy - T.px(2), sw + T.px(4), sh + T.px(4), th.a or 1, th.r, th.g, th.b)
        end
        it.steps[L] = { x = x0, y = sy, w = sw, h = sh }
    end
    -- the trait now, or No trait; NEW since the tab was last opened
    local cx = sx + 10 * (sw + sg) + T.px(6)
    local cw = it.x + it.w - T.px(6) - cx
    if #r.now == 0 then
        local c = sel and T.textOnAccent or (T.toneLo or T.textDim)
        local text = tr("UI_ZeD_TAS_NoTrait")
        local tw = ZeD.TM:MeasureStringX(T.fontF2, text) + T.px(13)
        local x0 = it.x + it.w - T.px(6) - tw
        ZeD.Atoms.drawStatusRing(panel, x0, y + math.floor((it.h - T.px(8)) / 2), c, T.px(8))
        panel:drawText(text, x0 + T.px(13), y + math.floor((it.h - F(2)) / 2), c.r, c.g, c.b, c.a or 1, T.fontF2)
    else
        local isNew = false
        local parts = {}
        for _, t in ipairs(r.now) do
            parts[#parts + 1] = t
            if st.newSet and st.newSet[t] then isNew = true end
        end
        local newW = isNew and (ZeD.TM:MeasureStringX(T.fontF5, tr("UI_ZeD_TAS_New")) + T.px(11)) or 0
        -- right-aligned: measure the whole chip
        local dsz = T.px(8)
        local total = newW
        local texts = {}
        for i, t in ipairs(parts) do
            texts[i] = tinfo(t).label
            total = total + dsz + T.px(5) + ZeD.TM:MeasureStringX(T.fontF2, texts[i]) + (i > 1 and T.px(8) or 0)
        end
        local x0 = math.max(cx, it.x + it.w - T.px(6) - total)
        local maxX = it.x + it.w - T.px(6) - newW
        for i, t in ipairs(parts) do
            if i > 1 then x0 = x0 + T.px(8) end
            if x0 + dsz >= maxX then break end
            ZeD.Atoms.drawStatusDot(panel, x0, y + math.floor((it.h - dsz) / 2), tinfo(t).bad and T.danger or T.positive, dsz)
            x0 = x0 + dsz + T.px(5)
            local txt = ZeD.Atoms.truncateText(texts[i], T.fontF2, maxX - x0)
            panel:drawText(txt, x0, y + math.floor((it.h - F(2)) / 2), ink.r, ink.g, ink.b, ink.a or 1, T.fontF2)
            x0 = x0 + ZeD.TM:MeasureStringX(T.fontF2, txt)
        end
        if isNew then
            local nx2 = it.x + it.w - T.px(6) - newW + T.px(5)
            local nw, nh = newW - T.px(5), T.px(13)
            local ny = y + math.floor((it.h - nh) / 2)
            local bc = sel and T.textOnAccent or T.accent
            panel:drawRectBorder(nx2, ny, nw, nh, 1, bc.r, bc.g, bc.b)
            local tc = sel and T.textOnAccent or (T.accentText or T.accentBright)
            panel:drawText(tr("UI_ZeD_TAS_New"), nx2 + T.px(3), ny + math.floor((nh - F(5)) / 2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF5)
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

local function drawDetail(panel, win, st, x, y, w, h)
    local T = ZeD.T
    local s2, bs = T.surf2, T.borderS
    panel:drawRect(x, y, w, h, 1, s2.r, s2.g, s2.b)
    panel:drawRect(x, y, w, T.px(1), bs.a or 1, bs.r, bs.g, bs.b)
    local p = win._playerObj
    local r = st.byId[st.hover or st.sel or ""]
    local pad = T.px(PAD)
    local ix, iw = x + pad, w - pad * 2
    local dim, tc = T.toneLo or T.textDim, T.text
    panel:setStencilRect(x, y + T.px(1), w, h - T.px(1))
    if not r or not p then
        local lines = ZeD.Atoms.wrapText(tr("UI_ZeD_TAS_Pick"), T.fontF2, iw)
        for i, l in ipairs(lines) do panel:drawText(l, ix, y + T.px(12) + (i - 1) * F(2), dim.r, dim.g, dim.b, dim.a or 1, T.fontF2) end
        panel:clearStencilRect()
        return
    end
    local cy = y + T.px(8)
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
            panel:drawText(ZeD.Atoms.truncateText(lab, T.fontF5, lw), x0 + T.px(2), cy + segH + T.px(3), lc.r, lc.g, lc.b, lc.a or 1, T.fontF5)
        end
    end
    local mxp = px(r.level) + math.floor((px(r.level + 1) - px(r.level)) * math.min(r.frac, 0.999))
    ZeD.Atoms.drawTriangleDown(panel, mxp - T.px(5), cy - T.px(6), T.px(10), T.accentBright)
    local tickY = cy + segH + T.px(3) + F(5) + T.px(2)
    for L = 0, 10 do
        local s = tostring(L)
        local cx = px(L) + math.floor((px(L + 1) - px(L)) / 2) - math.floor(ZeD.TM:MeasureStringX(T.fontF5, s) / 2)
        panel:drawText(s, cx, tickY, dim.r, dim.g, dim.b, dim.a or 1, T.fontF5)
    end
    cy = tickY + F(5) + T.px(6)
    -- key / value lines
    local vx, vw = ix + T.px(KEY_W) + T.px(8), iw - T.px(KEY_W) - T.px(8)
    local bottom = y + h - T.px(6)
    local function kv(k, v, bar)
        if cy >= bottom then return end
        panel:drawText(ZeD.upper(k), ix, cy + T.px(2), dim.r, dim.g, dim.b, dim.a or 1, T.fontF5)
        local lines = ZeD.Atoms.wrapText(v or "", T.fontF2, vw - (bar and T.px(170) or 0))
        for i, l in ipairs(lines) do
            if cy + F(2) > bottom + T.px(4) then break end
            panel:drawText(l, vx, cy, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
            if i == 1 and bar then
                local bx = vx + ZeD.TM:MeasureStringX(T.fontF2, l) + T.px(8)
                local s4 = T.surf4 or T.surf3
                local ac = T.accent
                local bw2 = math.min(T.px(160), ix + iw - bx)
                if bw2 > T.px(20) then
                    panel:drawRect(bx, cy + math.floor((F(2) - T.px(5)) / 2), bw2, T.px(5), 1, s4.r, s4.g, s4.b)
                    panel:drawRect(bx, cy + math.floor((F(2) - T.px(5)) / 2), math.floor(bw2 * bar), T.px(5), 1, ac.r, ac.g, ac.b)
                end
            end
            cy = cy + F(2)
        end
        cy = cy + T.px(3)
    end
    local ptext, pbar = progressText(p, r)
    kv(tr("UI_ZeD_TAS_KProgress"), ptext, pbar)
    local gains, losses = actionLists(r.def)
    if gains then
        kv(getText("UI_TAS_Gain"), (#gains > 0) and table.concat(gains, ", ") or tr("UI_ZeD_TAS_NoneList"))
        kv(getText("UI_TAS_Lose"), (#losses > 0) and table.concat(losses, ", ") or tr("UI_ZeD_TAS_NoneList"))
    end
    local uL, ug, ul = firstChange(r, 1)
    local dL, dg, dl = firstChange(r, -1)
    local up = uL and tr("UI_ZeD_TAS_At", uL, chText(ug, ul)) or tr("UI_ZeD_TAS_NoChangeAbove")
    if dL then up = up .. " | " .. tr("UI_ZeD_TAS_DownAt", dL, chText(dg, dl)) end
    kv(tr("UI_ZeD_TAS_KLevelUp"), up)
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
    kv(tr("UI_ZeD_TAS_KNow"), now)
    panel:clearStencilRect()
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
    local L = layout(st, w - T.sp.scrollbarW)
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
    if not (mx >= x and mx < x + w and my >= sy and my < sy + sh) then mx, my = nil, nil end
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
                local c = T.toneLo or T.textDim
                panel:drawText(tr("UI_ZeD_TAS_Nothing", S.find), it.x, dy, c.r, c.g, c.b, c.a or 1, T.fontF2)
            elseif k == "cat" then drawCat(panel, win, it, dy, mx, my)
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
            if (k == "cat" or k == "row") then
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
    if isFoc(win, "tas:find") then
        local f = st.findRect
        ZeD.Atoms.drawAccentRing(panel, f.x - T.px(2), f.y - T.px(2), f.w + T.px(4), f.h + T.px(4), T.px(2), T.accentBright)
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
        if sh2.L == sh2.row.level then body = body .. "\n" .. tr("UI_ZeD_TAS_Here") end
        ZeD.HairBeard.balloon(panel, tr("UI_ZeD_TAS_StepTitle", sh2.row.name, sh2.L), body, sh2.x, sh2.y, sh2.w, sh2.h,
            { x = x, y = y, w = w, h = h })
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
            elseif it.kind == "row" then st.sel = it.row.id end
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
    iconName = "traits-tab-white", icon = getTexture("media/textures/ZeD/TabIcons/traits-tab-white.png"),
    label = function() return getText("UI_TAS_Tab") end,
    render = S.render,
    scroll = function(win) return win._tas and win._tas.scroll or nil end,
    onClick = S.onClick,
    buildFocusables = S.buildFocusables,
    scrollKey = S.scrollKey,
    onWindowFrame = S.onWindowFrame,
})
