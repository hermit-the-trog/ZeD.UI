-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuModsSeps.lua
-- ============================================================================
-- SEPARATORS IN THE LOAD ORDER (MOD_FOLDERS_SPEC.md sections 7, 8, 10, 11; MODS_LOAD_ORDER_SPEC
-- 1.3, 4; stage 3 of the Mods screen work, punch lists 37 and 41; mockups zed_mod_folders_v1 b,
-- d, d2 and v2 b)
--
-- Separators sort the load order, MO2-style: headings inside the list of mods that are on, where
-- a mod's place under a separator is its place in the order. They are ZeD's own: kept with the
-- list being edited and with each profile in Zomboid/Lua/ZeD_modprofiles.txt ("sep=" / "top="
-- lines, ZeD_ModOrder); the game's files only ever get the plain order.
--   * rows: a checkbox (every mod under it on or off at once; the mods keep their places, dimmed
--     and unnumbered while off), a triangle (collapse; the numbers jump past it), the name on a
--     rule, the count
--   * New separator... (the band, a row's menu): above the picked mod, which goes under it with
--     the mods below it down to the next separator; Rename..., Delete separator (no question: its
--     mods stay where they are, under the separator above), Move up / Move down (with its mods)
--   * mods: Move up / Move down cross a separator one step at a time; Move to top / bottom work
--     inside the section; Move to separator... (the row's menu); a drag takes the section of the
--     row it lands on; a mod that lands under a separator that is off turns off
--   * Find: a separator shows only when it holds a match ("Radio (2 of 14)"), or when its own
--     name matches (then all its mods show); a collapsed one opens for the moment
--   * the order check: a mod that needs one under a later separator is red, and the band offers
--     Move it up (the needed mod to the end of the section above)
--   * Start separators from folders: one separator per folder with mods on, in the folders'
--     order, holding only those mods, then Unfiled; each section sorted by the mods' own rules;
--     asks first when the list has separators. Folders and separators never change each other.
--   * built for 1,500 mods: the list's entries are worked out once per change (with the order
--     page's own cache); each frame draws, and makes stops for, only the entries in sight
-- ============================================================================
require "ZeD/ZeD_MainMenuMods"
require "ZeD/ZeD_MainMenuModsOrder"
require "ZeD/ZeD_MainMenuModsFolders"
require "ZeD/ZeD_ModOrder"
require "ZeD/ZeD_ModFolders"

local MM = ZeD.MainMenu
local UI = MM.ui
local O  = ZeD.ModOrder
local F  = ZeD.ModFolders

-- design units (as the load order's own rows)
local ROW_H, HEAD_H, GAP_H, SEP_H = 32, 26, 18, 30
local DOUBLE_MS = 450
local NAME_MAX = 48            -- (as folders: typing stops here)
local LIST_MAX = 300           -- (the pane lists this many of a separator's mods at most)

local EMPTY = {}

local function model() return ModSelector and ModSelector.instance and ModSelector.instance.model end
local function jlist(l)
    local t = {}
    if l then for i = 0, l:size() - 1 do t[#t + 1] = l:get(i) end end
    return t
end
local function activeSet(m)
    local s = {}
    for id, d in pairs(m and m.mods or EMPTY) do if d.isActive then s[id] = true end end
    return s
end
local function setOf(t)
    local s = {}
    for _, v in ipairs(t or EMPTY) do s[v] = true end
    return s
end

-- the separators' modes of the band's question (a name typed, or Replace asked)
local FM = ZeD_MMMods.FIELD_MODES
if FM then FM.snew = true; FM.srename = true end

-- ----------------------------------------------------------------------------
-- WHAT THE PAGE ASKS
-- ----------------------------------------------------------------------------
function ZeD_MMMods:sepsOn() return self.page == "order" and O.hasSeps(self.oLo) end

function ZeD_MMMods:sepGet(uid) return O.sepOf(self.oLo, uid) end

-- the first and last place of the mods on under separator uid (0: the top); nil when none
function ZeD_MMMods:sepRange(uid)
    local a, b
    for i, id in ipairs(self.order) do
        if (self.oZone[id] or 2) == 2 and (self.oSec[id] or 0) == uid then a = a or i; b = i end
    end
    return a, b
end

-- where a mod goes into section uid ("top" or "bottom"), in the order as it is now
function ZeD_MMMods:sepInsertAt(uid, where)
    local idx = O.secIndex(self.oLo)
    local k = idx[uid] or 0
    local lastBefore = 0
    for p, id in ipairs(self.order) do
        local z = self.oZone[id] or 2
        if z == 1 then lastBefore = p
        elseif z == 2 then
            local kk = idx[self.oSec[id] or 0] or 0
            if kk < k then lastBefore = p
            elseif kk == k then
                if where == "top" then return p end
                lastBefore = p
            else break end
        else break end
    end
    return lastBefore + 1
end

-- a separator's mods: on (in the order), off and shown here (dimmed), every installed one off
function ZeD_MMMods:sepCounts(sp)
    local m = model()
    local on = setOf(self.order)
    local onN, shown, offAll = 0, 0, 0
    for _, id in ipairs(self.order) do if (self.oZone[id] or 2) == 2 and (self.oSec[id] or 0) == sp.uid then onN = onN + 1 end end
    for _, id in ipairs(sp.ids or EMPTY) do
        if not on[id] and m and m.mods[id] then
            offAll = offAll + 1
            if not sp.on or self.oOffHere[id] then shown = shown + 1 end
        end
    end
    return onN, shown, offAll
end

-- the list's name in the band's questions: the profile in use, else "this list"
function ZeD_MMMods:sepListName()
    local p = self:profileInUse()
    return p or ZeD.tr("UI_ZeD_Seps_ListThis")
end

-- ----------------------------------------------------------------------------
-- THE LIST'S ENTRIES WITH SEPARATORS (MODS_LOAD_ORDER_SPEC 1.2 to 1.4; MOD_FOLDERS_SPEC 7, 8):
-- the pinned blocks, the top, each separator's heading with its mods (and its mods that are off,
-- dimmed, in place), the gaps Find leaves. Once per change and per Find text.
-- ----------------------------------------------------------------------------
local _orderEntries = ZeD_MMMods.orderEntries
function ZeD_MMMods:orderEntries(q, skip, heads, pfx)
    if not (heads and self:sepsOn()) then return _orderEntries(self, q, skip, heads, pfx) end
    return self:sepEntries(q, skip, pfx)
end

-- the separator heading's count: "(14)", "(4, off)", "(6 | 9 to 14 hidden)", with Find "(2 of 14)"
local function sepCount(sp, places, nHeld, q, matched, open)
    local total = #places + nHeld
    if q ~= "" then return "(" .. ZeD.tr("UI_ZeD_Order_HeadOf", matched, total) .. ")" end
    if not sp.on then return "(" .. ZeD.tr("UI_ZeD_Seps_CountOff", total) .. ")" end
    if not open and #places > 0 then
        return "(" .. ZeD.tr("UI_ZeD_Seps_CountHidden", total, places[1], places[#places]) .. ")"
    end
    return "(" .. tostring(total) .. ")"
end

-- a section's mods that are off and shown (front: above its first mod on; after[id]: under id)
function ZeD_MMMods:sepHeldOf(list, sp, onSet, all)
    local m = model()
    local zone, sec = self.oZone or EMPTY, self.oSec or EMPTY
    local uid = sp and sp.uid or 0
    local front, after, n = {}, {}, 0
    local anchor = nil
    for _, id in ipairs(list or EMPTY) do
        if onSet[id] then
            if (zone[id] or 2) == 2 and (sec[id] or 0) == uid then anchor = id end
        elseif m and m.mods[id] and ((sp and not sp.on) or self.oOffHere[id]) then
            n = n + 1
            all[#all + 1] = id
            if anchor then
                local t = after[anchor]
                if not t then t = {}; after[anchor] = t end
                t[#t + 1] = id
            else
                front[#front + 1] = id
            end
        end
    end
    return { front = front, after = after, n = n }
end

-- why a dimmed mod is off (the row's right, the help line)
function ZeD_MMMods:sepWhy(id, sp)
    if sp and not sp.on then return ZeD.tr("UI_ZeD_Seps_WhySepOff", sp.name) end
    return self.oOffHere[id] or ZeD.tr("UI_ZeD_Seps_WhyOff")
end

function ZeD_MMMods:sepEntries(q, skip, pfx)
    O.stats.views = O.stats.views + 1
    local T = ZeD.T
    local rh, hh, gh, sh = T.px(ROW_H), T.px(HEAD_H), T.px(GAP_H), T.px(SEP_H)
    local m = model()
    local I, order, zone, carried, sec = self.oInfo or EMPTY, self.order, self.oZone or EMPTY, self.oCarried or EMPTY, self.oSec or EMPTY
    local lo = self.oLo
    local picker = pfx ~= "orow:"
    local ents, byPlace, at = {}, {}, {}
    local st = { y = 0, gap = 0, n = 0, last = 0 }
    local function push(e, h)
        e.y, e.h = st.y, h
        st.y = st.y + h
        ents[#ents + 1] = e
        if e.sid then at[e.sid] = #ents end
    end
    local function flush()
        if st.gap > 0 then push({ k = "gap", text = ZeD.tr("UI_ZeD_Order_GapMore", st.gap) }, gh); st.gap = 0 end
    end
    local all = self._infoAll or EMPTY
    local function hit(id)
        if q == "" then return true end
        local e = I[id] or all[id]
        return ((e and e.hay) or string.lower(tostring(id))):find(q, 1, true) ~= nil
    end
    local function row(i, id, force)
        st.last = i
        if id == skip then return end
        if force or hit(id) then
            flush()
            push({ k = "row", i = i, id = id, num = tostring(i), name = (I[id] and I[id].name) or tostring(id), sid = pfx .. i, hid = "mods:" .. pfx .. i }, rh)
            byPlace[i] = #ents
            st.n = st.n + 1
        else
            st.gap = st.gap + 1
        end
    end
    -- the blocks' counts (their headings), each section's places
    local cnt, pinned, mz = { 0, 0, 0 }, { 0, 0, 0 }, { 0, 0, 0 }
    local helperOn = false
    local places = { [0] = {} }
    for _, sp in ipairs(lo.seps) do places[sp.uid] = {} end
    local Fp, Lp = {}, {}
    for i, id in ipairs(order) do
        local z = zone[id] or 2
        local blk = (z == 4) and 3 or z
        if z == 4 then helperOn = true end
        cnt[blk] = cnt[blk] + 1
        if (z == 1 or z == 3) and not carried[id] then pinned[blk] = pinned[blk] + 1 end
        if id ~= skip and hit(id) then mz[blk] = mz[blk] + 1 end
        if z == 1 then Fp[#Fp + 1] = i
        elseif z == 2 then local l = places[sec[id] or 0] or places[0]; l[#l + 1] = i
        else Lp[#Lp + 1] = i end
    end
    -- each section's mods that are off and shown (the page only: the picker lists mods on)
    local onSet = setOf(order)
    local held, heldIds = {}, {}
    if not picker then
        held[0] = self:sepHeldOf(lo.top, nil, onSet, heldIds)
        for _, sp in ipairs(lo.seps) do held[sp.uid] = self:sepHeldOf(sp.ids, sp, onSet, heldIds) end
        if #heldIds > 0 and m then self:infoFor(m, heldIds); all = self._infoAll or EMPTY end
    end
    local headText = ZeD_MMMods._orderHeadText
    if #Fp > 0 and (q == "" or mz[1] > 0) then
        flush()
        local t1, t2 = headText(1, cnt[1], pinned[1], mz[1], q, helperOn)
        push({ k = "head", text = t1, sub = t2 }, hh)
    end
    for _, i in ipairs(Fp) do row(i, order[i]) end
    local function heldRows(list, sp, force)
        for _, id in ipairs(list or EMPTY) do
            if force or hit(id) then
                flush()
                local hid = "ohld:" .. id
                push({ k = "held", id = id, uid = sp and sp.uid or 0, name = O.nameOf(m, all, id), why = self:sepWhy(id, sp),
                       sid = hid, hid = "mods:" .. hid, row = st.last + 0.25 }, rh)
            end
        end
    end
    local function section(sp, k)
        local pl = places[sp and sp.uid or 0] or EMPTY
        local H = held[sp and sp.uid or 0] or { front = EMPTY, after = EMPTY, n = 0 }
        local nameHit = sp ~= nil and q ~= "" and string.lower(tostring(sp.name)):find(q, 1, true) ~= nil
        local matched = 0
        if q ~= "" then
            for _, i in ipairs(pl) do if order[i] ~= skip and (nameHit or hit(order[i])) then matched = matched + 1 end end
        end
        local open = picker or q ~= "" or not sp or sp.open
        if sp then
            local hm = 0
            if q ~= "" and not picker then
                for _, id in ipairs(H.front) do if nameHit or hit(id) then hm = hm + 1 end end
                for _, i in ipairs(pl) do for _, id in ipairs(H.after[order[i]] or EMPTY) do if nameHit or hit(id) then hm = hm + 1 end end end
            end
            if q == "" or nameHit or matched + hm > 0 then
                flush()
                local cntText = sepCount(sp, pl, H.n, q, matched + hm, open)
                if picker then
                    push({ k = "head", text = sp.name, sub = cntText }, hh)
                else
                    local sid = "osep:" .. sp.uid
                    push({ k = "sep", uid = sp.uid, sp = sp, idx = k, name = sp.name, cnt = cntText, open = open, sid = sid, hid = "mods:" .. sid,
                           bid = "mods:osepbox:" .. sp.uid, tid = "mods:oseptri:" .. sp.uid, nOn = #pl, nHeld = H.n, row = st.last + 0.5 + k * 0.001 }, sh)
                end
            end
        end
        if not open then
            -- (collapsed: its rows are not drawn and count as no gap; its heading says which are hidden)
            if #pl > 0 then st.last = pl[#pl] end
            return
        end
        if not picker then heldRows(H.front, sp, nameHit) end
        for _, i in ipairs(pl) do
            row(i, order[i], nameHit)
            if not picker then heldRows(H.after[order[i]], sp, nameHit) end
        end
    end
    section(nil, 0)
    for k, sp in ipairs(lo.seps) do section(sp, k) end
    if #Lp > 0 and (q == "" or mz[3] > 0) then
        flush()
        local t1, t2 = headText(3, cnt[3], pinned[3], mz[3], q, helperOn)
        push({ k = "head", text = t1, sub = t2 }, hh)
    end
    for _, i in ipairs(Lp) do row(i, order[i]) end
    flush()
    return { ents = ents, total = st.y, byPlace = byPlace, nMatch = st.n, at = at }
end

-- ----------------------------------------------------------------------------
-- DRAWING A SEPARATOR ROW AND A DIMMED ROW (mockup v1 b)
-- ----------------------------------------------------------------------------
-- the box: ticked (its mods on), empty (off), the dash (some on, some off: spec 8.4)
local function boxState(e)
    local sp = e.sp
    if sp.on then return (e.nHeld > 0) and "mix" or "on" end
    return (e.nOn > 0) and "mix" or "off"
end

local function drawBox(p, x, y, state, hot)
    local T = ZeD.T
    local sz = T.checkboxSz
    ZeD.Atoms.drawCheckbox(p, x, y, state == "on", hot, false)
    if state == "mix" then
        local c = T.text
        local mg = T.px(3)
        local dh = math.max(T.px(2), 2)
        p:drawRect(x + mg, y + math.floor((sz - dh) / 2), sz - mg * 2, dh, c.a or 1, c.r, c.g, c.b)
    end
end

-- the entry's stop and hits, made once (kept with the entry, which lives until the next change)
function ZeD_MMMods:sepParts(e)
    if e.spec then return e.spec end
    local sp = { id = e.sid, listRow = true, col = 1, row = e.row, ry = e.y, rh = e.h }
    if e.k == "sep" then
        local uid = e.uid
        sp.sepUid = uid
        e.hit = { id = e.hid, fn = function() self:clickSep(e) end }
        e.triHit = { id = e.tid, fn = function() self:sepSelect(uid); self:sepOpenClose(uid) end }
        e.boxHit = { id = e.bid, fn = function() self:sepSelect(uid); self:sepBox(uid) end }
        e.help = ZeD.tr("UI_ZeD_Seps_HelpRow", e.name)
        e.helpBox = ZeD.tr("UI_ZeD_Seps_HelpBox", e.name)
        e.helpTri = ZeD.tr("UI_ZeD_Seps_HelpTri", e.name)
    else
        local id = e.id
        sp.heldId = id
        e.hit = { id = e.hid, fn = function() self:clickHeld(e) end }
        e.help = ZeD.tr("UI_ZeD_Seps_HelpHeld", e.why)
    end
    e.spec = sp
    return sp
end

function ZeD_MMMods:drawSepRow(e, x, ry, rw, vy, vh, gp, modal)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local f2, f3 = T.fontF2, T.fontF3
    local s2 = T.surf2
    self:sepParts(e)
    self:drawRect(x, ry, rw, e.h, 1, s2.r, s2.g, s2.b)
    local hotRow = (not gp) and (not modal) and MM.ctx.hot == e.hid
    local hotBox = (not gp) and (not modal) and MM.ctx.hot == e.bid
    local hotTri = (not gp) and (not modal) and MM.ctx.hot == e.tid
    local focus = gp and (not modal) and self.focusId == e.sid
    local onFocus = MM.rowLook(self, x, ry, rw, e.h, self.oSepSel == e.uid, hotRow or hotBox or hotTri, focus)
    self:drawRect(x, ry + e.h - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
    local cb = T.checkboxSz
    local bx = x + T.px(8)
    drawBox(self, bx, ry + math.floor((e.h - cb) / 2), boxState(e), hotBox)
    local tri = T.px(6)
    local tx = bx + cb + T.px(10)
    local tyy = ry + math.floor((e.h - tri) / 2)
    local dim = onFocus and T.textOnFocus or T.textDim
    if e.open then ZeD.Atoms.drawTriangleDown(self, tx, tyy, tri, dim) else ZeD.Atoms.drawTriangleRight(self, tx, tyy, tri, dim) end
    -- the name on a rule, its count, the rule on to the right edge
    -- (a labelled separator: its name and rules in the label's colour, dimmed while it is off)
    local lc = (not onFocus) and self:labelColor(e.sp.label) or nil
    local la = (lc and not e.sp.on) and T.disabledAlpha or 1
    local bc = lc and { r = lc.r, g = lc.g, b = lc.b, a = la } or T.border
    local midY = ry + math.floor(e.h / 2)
    local lx = tx + tri + T.px(10)
    self:drawRect(lx, midY, T.px(12), T.px(1), bc.a, bc.r, bc.g, bc.b)
    local nx = lx + T.px(20)
    local right = x + rw - T.px(10)
    local cw = MM.textW(f3, e.cnt)
    local nameW = math.max(T.px(20), right - nx - cw - T.px(24))
    if e.tnw ~= nameW then e.tnw, e.tn = nameW, ZeD.Atoms.truncateText(e.name, f2, nameW) end
    -- (the name: the label's text colour, which reads at 4.6 : 1; the rules keep the strong mark colour)
    local lt = lc and self:labelColor(e.sp.label, true)
    local ltc = lt and { r = lt.r, g = lt.g, b = lt.b, a = la } or nil
    local nc = onFocus and T.textOnFocus or ltc or (e.sp.on and T.textHead or T.textDim)
    self:drawText(e.tn, nx, ry + math.floor((e.h - MM.fontH(f2)) / 2), nc.r, nc.g, nc.b, nc.a or 1, f2)
    local cx = nx + MM.textW(f2, e.tn) + T.px(8)
    self:drawText(e.cnt, cx, ry + math.floor((e.h - MM.fontH(f3)) / 2), dim.r, dim.g, dim.b, dim.a or 1, f3)
    local rx2 = cx + cw + T.px(8)
    if rx2 < right then self:drawRect(rx2, midY, right - rx2, T.px(1), bc.a, bc.r, bc.g, bc.b) end
    if hotBox then ZeD.Help.set(self, e.helpBox)
    elseif hotTri then ZeD.Help.set(self, e.helpTri)
    elseif hotRow or focus then ZeD.Help.set(self, e.help) end
    if modal then return end
    local sp = e.spec
    sp.chosen = self.oSepSel == e.uid
    self._specs[#self._specs + 1] = sp
    local cy0, ch = math.max(ry, vy), math.min(ry + e.h, vy + vh) - math.max(ry, vy)
    local h1 = e.hit
    h1.x, h1.y, h1.w, h1.h = ax + x, ay + cy0, rw, ch
    self._hits[#self._hits + 1] = h1
    local h2 = e.triHit
    h2.x, h2.y, h2.w, h2.h = ax + tx - T.px(4), ay + cy0, tri + T.px(10), ch
    self._hits[#self._hits + 1] = h2
    local h3 = e.boxHit
    h3.x, h3.y, h3.w, h3.h = ax + bx - T.px(4), ay + cy0, cb + T.px(8), ch
    self._hits[#self._hits + 1] = h3
end

function ZeD_MMMods:drawHeldRow(e, x, ry, rw, vy, vh, gp, modal)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local f2, f3 = T.fontF2, T.fontF3
    self:sepParts(e)
    local hot = (not gp) and (not modal) and MM.ctx.hot == e.hid
    local focus = gp and (not modal) and self.focusId == e.sid
    local onFocus = MM.rowLook(self, x, ry, rw, e.h, self.oHeldSel == e.id, hot, focus)
    self:drawRect(x, ry + e.h - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
    local a = onFocus and 1 or T.disabledAlpha
    local d3 = onFocus and T.textOnFocus or T.textDim
    -- (no number: the numbers close up over it, spec 8.1; a hollow square where the dot goes)
    local numW = self._numW or MM.textW(f3, "0000")
    local nx = x + T.px(14) + numW
    local dsz = T.px(7)
    self:drawRectBorder(nx, ry + math.floor((e.h - dsz) / 2), dsz, dsz, (d3.a or 1) * a, d3.r, d3.g, d3.b)
    nx = nx + dsz + T.px(8)
    local tr = x + rw - T.px(8)
    local ww = math.min(MM.textW(f3, e.why), math.floor((tr - nx) * 0.5))
    if e.whyW ~= ww then e.whyW, e.whyT = ww, ZeD.Atoms.truncateText(e.why, f3, ww) end
    tr = tr - ww
    self:drawText(e.whyT, tr, ry + math.floor((e.h - MM.fontH(f3)) / 2), d3.r, d3.g, d3.b, (d3.a or 1) * a, f3)
    tr = tr - T.px(8)
    local maxW = tr - nx
    if e.tnw ~= maxW then e.tnw, e.tn = maxW, ZeD.Atoms.truncateText(e.name, f2, maxW) end
    local c = onFocus and T.textOnFocus or T.text
    self:drawText(e.tn, nx, ry + math.floor((e.h - MM.fontH(f2)) / 2), c.r, c.g, c.b, (c.a or 1) * a, f2)
    if hot or focus then ZeD.Help.set(self, e.help) end
    if modal then return end
    self._specs[#self._specs + 1] = e.spec
    local cy0 = math.max(ry, vy)
    local h1 = e.hit
    h1.x, h1.y, h1.w, h1.h = ax + x, ay + cy0, rw, math.min(ry + e.h, vy + vh) - cy0
    self._hits[#self._hits + 1] = h1
end

-- the stops of separator and dimmed rows out of sight: the one just above, the one just below,
-- the focused one (the D-pad lands on them, and the list follows)
function ZeD_MMMods:sepOffStops(v, k0, k1)
    local ents = v.ents
    local function add(k)
        local e = ents[k]
        if e and (e.k == "sep" or e.k == "held") then self._specs[#self._specs + 1] = self:sepParts(e) end
    end
    if k0 > 1 then add(k0 - 1) end
    add(k1)
    local kf = v.at and v.at[self.focusId or ""]
    if kf and (kf < k0 - 1 or kf > k1) then add(kf) end
end

-- ----------------------------------------------------------------------------
-- PICKING
-- ----------------------------------------------------------------------------
function ZeD_MMMods:sepScrollTo(sid, center)
    local v = self:orderView()
    local k = v.at and v.at[sid]
    local e = k and v.ents[k]
    local vh = self._list and self._list.h or 0
    if not (e and vh > 0) then return end
    if center then self.scroll = math.max(0, e.y + math.floor(e.h / 2) - math.floor(vh / 2))
    elseif e.y < self.scroll then self.scroll = e.y
    elseif e.y + e.h > self.scroll + vh then self.scroll = e.y + e.h - vh end
end

function ZeD_MMMods:sepSelect(uid, center)
    self.oSepSel, self.oHeldSel = uid, nil
    self.focusId = "osep:" .. tostring(uid)
    self:sepScrollTo(self.focusId, center)
end

function ZeD_MMMods:heldSelect(id)
    self.oSepSel, self.oHeldSel = nil, id
    self.focusId = "ohld:" .. tostring(id)
    self:sepScrollTo(self.focusId, false)
end

-- a click picks the separator (its pane); a second one soon after collapses or opens it
function ZeD_MMMods:clickSep(e)
    local t = MM.now()
    if self.oSepSel == e.uid and self._sClick and t - self._sClick < DOUBLE_MS then
        self._sClick = nil
        self:sepOpenClose(e.uid)
        return
    end
    self._sClick = t
    if self.oSepSel ~= e.uid then MM.hoverSound() end
    self.oSepSel, self.oHeldSel = e.uid, nil
    self.focusId = e.sid
end

function ZeD_MMMods:clickHeld(e)
    if self.oHeldSel ~= e.id then MM.hoverSound() end
    self.oSepSel, self.oHeldSel = nil, e.id
    self.focusId = e.sid
end

local _clickOrderRow = ZeD_MMMods.clickOrderRow
function ZeD_MMMods:clickOrderRow(i)
    self.oSepSel, self.oHeldSel = nil, nil
    return _clickOrderRow(self, i)
end

-- ----------------------------------------------------------------------------
-- MAKING, RENAMING, DELETING, COLLAPSING, MOVING SEPARATORS (spec 7.1 to 7.3)
-- ----------------------------------------------------------------------------
function ZeD_MMMods:sepAskNew()
    if self.page ~= "order" or self.pick then return end
    self._backFocus = self.focusId
    self:setConfirm("snew")
end

function ZeD_MMMods:sepAskRename(uid)
    local sp = self:sepGet(uid)
    if not sp then return end
    self._sTarget, self._fieldPre = uid, sp.name
    self._backFocus = self.focusId
    self:setConfirm("srename")
end

local _setConfirm = ZeD_MMMods.setConfirm
function ZeD_MMMods:setConfirm(mode)
    _setConfirm(self, mode)
    if mode == "srename" and self.confirm == "srename" then
        self.field:setText(self._fieldPre or "")
        if ZeD.selectDefault then ZeD.selectDefault(self.field) end   -- (typing replaces the name offered)
    end
end

local function nameTaken(lo, name, exceptUid)
    local low = string.lower(name)
    for _, sp in ipairs(lo and lo.seps or EMPTY) do
        if sp.uid ~= exceptUid and string.lower(tostring(sp.name)) == low then return sp.name end
    end
    return nil
end

-- the new separator: above the picked mod (it, and the mods under it down to the next
-- separator, go under the new one), above the picked separator, or at the end (spec 7.1)
function ZeD_MMMods:sepNew(name)
    local lo = self.oLo
    self:orderSnap()
    local sp = { uid = O.newUid(), name = name, on = true, open = true, ids = {} }
    local dup = nameTaken(lo, name, nil)
    local at = #lo.seps + 1
    if self.oSepSel then
        local _, k = self:sepGet(self.oSepSel)
        if k then at = k end
    elseif not self.oHeldSel then
        local i = self.oSel or 1
        local x = self.order[i]
        if x and (self.oZone[x] or 2) == 2 then
            local s = self.oSec[x] or 0
            local _, k = O.sepOf(lo, s)
            at = (k or 0) + 1
            for j = i, #self.order do
                local y = self.order[j]
                if (self.oZone[y] or 2) == 2 and (self.oSec[y] or 0) == s then self.oSec[y] = sp.uid end
            end
        end
    end
    table.insert(lo.seps, at, sp)
    self:orderChanged()
    self:sepSelect(sp.uid)
    self:say(ZeD.tr(dup and "UI_ZeD_Seps_SayMadeDup" or "UI_ZeD_Seps_SayMade", name))
    MM.clickSound()
end

-- a separator's label set or cleared (nil); Undo brings the last one back, as for a rename
function ZeD_MMMods:sepSetLabel(uid, key)
    local sp = self:sepGet(uid)
    if not sp or sp.label == key then return end
    self:orderSnap()
    sp.label = key
    self:orderChanged()
    self:sepSelect(uid)
end

function ZeD_MMMods:sepRename(uid, name)
    local sp = self:sepGet(uid)
    if not sp or sp.name == name then return end
    self:orderSnap()
    local old = sp.name
    sp.name = name
    self:orderChanged()
    self:sepSelect(uid)
    self:say(ZeD.tr("UI_ZeD_Seps_SayRenamed", old, name))
    MM.clickSound()
end

-- no question (spec 7.2): its mods stay where they are, now under the separator above; Undo and
-- Back bring it back
function ZeD_MMMods:sepDelete(uid)
    local sp, k = self:sepGet(uid)
    if not sp then return end
    self:orderSnap()
    local lo = self.oLo
    local prev = (k > 1) and lo.seps[k - 1] or nil
    local puid = prev and prev.uid or 0
    for _, id in ipairs(self.order) do if (self.oSec[id] or 0) == uid then self.oSec[id] = puid end end
    -- (its mods that are off go along, at its place: still off, shown dimmed so they are not lost)
    local onSet = setOf(self.order)
    local dest = prev and prev.ids or lo.top
    for _, id in ipairs(sp.ids or EMPTY) do
        if not onSet[id] then
            dest[#dest + 1] = id
            if not sp.on then self.oOffHere[id] = ZeD.tr("UI_ZeD_Seps_WhyWasUnder", sp.name) end
        end
    end
    table.remove(lo.seps, k)
    self:orderChanged()
    if prev then self:sepSelect(prev.uid) else self:orderSelectAt(self.oSel or 1, false) end
    self:say(ZeD.tr("UI_ZeD_Seps_SayDeleted", sp.name))
    MM.clickSound()
end

-- collapse or open (want: true open, false collapse, nil the other way); kept with the list
function ZeD_MMMods:sepOpenClose(uid, want)
    local sp = self:sepGet(uid)
    if not sp then return end
    if (self.find:getInternalText() or "") ~= "" then
        MM.hoverSound()
        self:say(ZeD.tr("UI_ZeD_Seps_SayFindOpen"))
        return
    end
    local open = want
    if open == nil then open = not sp.open end
    if sp.open == open then return end
    sp.open = open
    -- (a picked mod now hidden: the separator is picked instead)
    if not open and not self.oSepSel and not self.oHeldSel then
        local x = self.order[self.oSel or 1]
        if x and (self.oZone[x] or 2) == 2 and (self.oSec[x] or 0) == uid then self.oSepSel = uid end
    end
    if self.oHeldSel and not open then self.oHeldSel, self.oSepSel = nil, uid end
    self:orderChanged()
    if self.oSepSel == uid then self:sepSelect(uid) end
    MM.clickSound()
end

-- a separator and its mods up (-1) or down (1) past the next separator (spec 7.3)
function ZeD_MMMods:sepShift(uid, delta)
    local lo = self.oLo
    local sp, k = self:sepGet(uid)
    if not sp then return end
    local j = k + delta
    if j < 1 or j > #lo.seps then MM.hoverSound(); return end
    self:orderSnap()
    lo.seps[k], lo.seps[j] = lo.seps[j], lo.seps[k]
    self.order = O.secGroup(self.order, self.oZone, self.oSec, lo)
    self:orderChanged()
    self:sepSelect(uid)
    MM.hoverSound()
end

-- ----------------------------------------------------------------------------
-- ON AND OFF (spec 8): the game's own rules, as a tick on the Mods page; nothing reaches the game
-- until Accept there; Undo and Back put them back
-- ----------------------------------------------------------------------------
-- the mods that are on made to be exactly want (Undo, Back)
function ZeD_MMMods:sepMatchActive(want)
    if not (model() and want) then return end
    -- (the player's own earlier set: back exactly, as one batch; QA Nov 1 2026, mhd: one at a
    -- time, Undo lost The Only Cure+ to The Only Cure)
    local go, _, off = self:applyOnSet(want, true)
    if off or #go > 0 then self:dirty() end
end

-- after mods went on or off: the ones that went off with them (they need one) are shown dimmed
-- where they are, with the reason; the order is laid out again with every mod on now, each in its
-- section (a mod back on goes to its place, a mod new to the list to the end, spec 7.4, 7.5)
function ZeD_MMMods:sepReconcile(before, after, mine)
    local m = model()
    local all = self._infoAll or EMPTY
    local mineSet = setOf(mine)
    for id in pairs(before) do
        if not after[id] and not mineSet[id] then
            local why = nil
            for _, r in ipairs(all[id] and all[id].req or EMPTY) do
                if before[r] and not after[r] then why = ZeD.tr("UI_ZeD_Seps_WhyNeeds", O.nameOf(m, all, r)); break end
            end
            self.oOffHere[id] = why or ZeD.tr("UI_ZeD_Seps_WhyOff")
        end
    end
    for id in pairs(after) do self.oOffHere[id] = nil end
    local ids = jlist(m:getActiveMods():getMods())
    self.oInfo = self:infoFor(m, ids)
    local seq, seen = {}, {}
    local function add(id) if after[id] and not seen[id] then seen[id] = true; seq[#seq + 1] = id end end
    for _, id in ipairs(self.order) do if (self.oZone[id] or 2) == 1 then add(id) end end
    for _, id in ipairs(self.oLo.top or EMPTY) do add(id) end
    for _, sp in ipairs(self.oLo.seps) do for _, id in ipairs(sp.ids or EMPTY) do add(id) end end
    for _, id in ipairs(self.order) do add(id) end
    for _, id in ipairs(ids) do add(id) end
    self.order, self.oZone, self.oCarried, self.oSec = O.layout(seq, self.oInfo, self.oLo, false)
    self:orderChanged()
end

-- ids on: one batch (QA Nov 1 2026, msp 3d), through the Mods screen's own (modsOnBatch). Two
-- mods of the batch that conflict go on together only when both were on together when the
-- separator went off (together: that set); otherwise the first in the list goes on. A mod that
-- stays off is shown dimmed in its place with the reason.
function ZeD_MMMods:sepTurnOnBatch(ids, together, cannot)
    local _, off = self:modsOnBatch(ids, { together = together, why = self.oOffHere })
    for _, n in ipairs(off) do cannot[#cannot + 1] = n end
end

-- ids on (true) or off (false) at once. Returns what could not run, what a save keeps on, and
-- the mods on before and after. together: see sepTurnOnBatch.
function ZeD_MMMods:sepTurn(ids, on, together)
    local m = model()
    if not m then return EMPTY, EMPTY, {}, {} end
    local before = activeSet(m)
    local cannot, keptOn = {}, {}
    local SF = ZeD.ModSafety
    if on then self:sepTurnOnBatch(ids, together, cannot) end
    for _, id in ipairs(ids) do
        local d = m.mods[id]
        if d then
            if not on and d.isActive then
                -- a save's own list: a mod its world may hold stays on (its own row asks first)
                local grade = "safe"
                if m.loadGameFolder and SF and SF.forTurnOff then pcall(function() grade = SF.forTurnOff(m, d).grade end) end
                if grade ~= "safe" then keptOn[#keptOn + 1] = tostring(d.name) else m:forceActivateMods(d.modInfo, false) end
            end
        end
    end
    -- (ZeD-GUI off under the separator took ZeD picks with it: ZeD-GUI back on, any way, brings them)
    if not on and self.picksNoteOff then self:picksNoteOff(before) end
    local after = activeSet(m)
    self:sepReconcile(before, after, ids)
    self:dirty()
    return cannot, keptOn, before, after
end

-- the band's words for what else came along or went
local function extras(m, before, after, mine, turnOn)
    local mineSet = setOf(mine)
    local t = {}
    if turnOn then
        for id in pairs(after) do if not before[id] and not mineSet[id] then t[#t + 1] = m.mods[id] and tostring(m.mods[id].name) or id end end
    else
        for id in pairs(before) do if not after[id] and not mineSet[id] then t[#t + 1] = m.mods[id] and tostring(m.mods[id].name) or id end end
    end
    return t
end

-- the separator's box: every mod under it on (empty or mixed) or off (ticked)
function ZeD_MMMods:sepBox(uid)
    local m = model()
    local sp = self:sepGet(uid)
    if not (m and sp) then return end
    local onN, shown = self:sepCounts(sp)
    local turnOn = not (sp.on and shown == 0)
    self:orderSnap()
    local ids = {}
    if turnOn then
        sp.on = true
        for _, id in ipairs(sp.ids or EMPTY) do local d = m.mods[id]; if d and not d.isActive then ids[#ids + 1] = id end end
    else
        sp.on = false
        for _, id in ipairs(self.order) do if (self.oZone[id] or 2) == 2 and (self.oSec[id] or 0) == uid then ids[#ids + 1] = id end end
    end
    local cannot, keptOn, before, after = self:sepTurn(ids, turnOn, turnOn and sp.heldOn or nil)
    -- (what this separator turned off, kept until it is on again: those come back together)
    if turnOn then sp.heldOn = nil
    else
        local held = {}
        for _, id in ipairs(ids) do if before[id] and not after[id] then held[id] = true end end
        sp.heldOn = held
    end
    local n = 0
    for _, id in ipairs(ids) do if (after[id] == true) == turnOn and (before[id] == true) ~= turnOn then n = n + 1 end end
    local parts = {}
    if n == 1 then parts[1] = ZeD.tr(turnOn and "UI_ZeD_Seps_SayOnOne" or "UI_ZeD_Seps_SayOffOne", sp.name)
    else parts[1] = ZeD.tr(turnOn and "UI_ZeD_Seps_SayOnMany" or "UI_ZeD_Seps_SayOffMany", sp.name, n) end
    local more = extras(m, before, after, ids, turnOn)
    if #more > 0 then
        if turnOn then parts[#parts + 1] = ZeD.tr("UI_ZeD_Folders_SayCameAlong", #more, table.concat(more, ", "))
        else parts[#parts + 1] = ZeD.tr("UI_ZeD_Folders_SayAlsoOff", table.concat(more, ", ")) end
    end
    if #cannot > 0 then parts[#parts + 1] = ZeD.tr("UI_ZeD_Folders_SayCannot", #cannot, table.concat(cannot, ", ")) end
    if #keptOn > 0 then parts[#parts + 1] = ZeD.tr("UI_ZeD_Folders_SayKeptOn", table.concat(keptOn, ", ")) end
    self:say(table.concat(parts, " "))
    self:sepSelect(uid)
    MM.clickSound()
end

-- a dimmed mod turned on by itself (spec 8.4): back in its place; its separator's box shows the
-- mixed mark while the separator is off
function ZeD_MMMods:heldTurnOn(id)
    local m = model()
    if not (m and m.mods[id]) then return end
    self:orderSnap()
    local cannot = self:sepTurn({ id }, true)
    if #cannot > 0 then
        table.remove(self.oUndo)
        MM.hoverSound()
        self:say(ZeD.tr("UI_ZeD_Folders_SayCannot", #cannot, table.concat(cannot, ", ")))
        return
    end
    self:orderSelect(id, false)
    self:say(ZeD.tr("UI_ZeD_Seps_SayHeldOn", O.nameOf(m, self._infoAll, id)))
    MM.clickSound()
end

-- a mod that landed under a separator: a collapsed one opens; under one that is off it turns off
-- (spec 8.3). True when it turned off.
function ZeD_MMMods:sepLanded(id, uid)
    if uid == 0 then return false end
    local sp = self:sepGet(uid)
    if not sp then return false end
    sp.open = true
    if sp.on then return false end
    self:orderChanged()
    self:sepTurn({ id }, false)
    self:say(ZeD.tr("UI_ZeD_Seps_SayLandedOff", O.nameOf(model(), self._infoAll, id), sp.name))
    return true
end

-- ----------------------------------------------------------------------------
-- MOVING MODS UNDER SEPARATORS (spec 7.3; MODS_LOAD_ORDER_SPEC 8)
-- ----------------------------------------------------------------------------
-- one place: at the edge of a section, the mod crosses the separator (one step: the end of the
-- section above, or the top of the one below), its place in the order unchanged
local _move = ZeD_MMMods.move
function ZeD_MMMods:move(delta)
    if self.pick or not self:sepsOn() then return _move(self, delta) end
    if self.oSepSel then self:sepShift(self.oSepSel, delta); return end
    if self.oHeldSel then MM.hoverSound(); self:say(ZeD.tr("UI_ZeD_Seps_SayHeldFixed")); return end
    local i = self.oSel or 1
    local x = self.order[i]
    if not x or (self.oZone[x] or 2) ~= 2 then return _move(self, delta) end
    local y = self.order[i + delta]
    local sx = self.oSec[x] or 0
    if y and (self.oZone[y] or 2) == 2 and (self.oSec[y] or 0) == sx then return _move(self, delta) end
    local idx = O.secIndex(self.oLo)
    local nk = (idx[sx] or 0) + delta
    if nk < 0 or nk > #self.oLo.seps then return _move(self, delta) end
    local nuid = (nk == 0) and 0 or self.oLo.seps[nk].uid
    self:orderSnap()
    self.oSec[x] = nuid
    local off = self:sepLanded(x, nuid)
    self:orderChanged()
    if off then self:heldSelect(x) else self:orderSelectAt(i, false) end
    MM.hoverSound()
end

-- a drop or a move to a place: the mod takes the section of the row it lands by
local _moveTo = ZeD_MMMods.orderMoveTo
function ZeD_MMMods:orderMoveTo(i, j)
    if not self:sepsOn() then return _moveTo(self, i, j) end
    local x, t = self.order[i], self.order[j]
    _moveTo(self, i, j)
    if not (x and t) or x == t then return end
    if (self.oZone[x] or 2) ~= 2 or (self.oZone[t] or 2) ~= 2 then return end
    if self:orderIndexOf(x) == i then return end
    local s = self.oSec[t] or 0
    if (self.oSec[x] or 0) == s then return end
    self.oSec[x] = s
    local off = self:sepLanded(x, s)
    self:orderChanged()
    if off then self:heldSelect(x) else self:orderSelect(x, false) end
end

-- Move to top / Move to bottom (the row's menu, Ctrl+Home / End): inside the mod's section
local _toEdge = ZeD_MMMods.orderToEdge
function ZeD_MMMods:orderToEdge(dir)
    if self.pick or not self:sepsOn() then return _toEdge(self, dir) end
    if self.oSepSel or self.oHeldSel then return end
    local i = self.oSel or 1
    local x = self.order[i]
    if not x or (self.oZone[x] or 2) ~= 2 then return _toEdge(self, dir) end
    local a, b = self:sepRange(self.oSec[x] or 0)
    if not a then return end
    self:orderMoveTo(i, dir < 0 and a or b)
end

-- Move to separator...: the mod to the bottom of section uid (0: above the separators)
function ZeD_MMMods:sepMoveModTo(id, uid)
    local i = self:orderIndexOf(id)
    if not i or (self.oZone[id] or 2) ~= 2 then return end
    if (self.oSec[id] or 0) == uid then return end
    self:orderSnap()
    table.remove(self.order, i)
    local j = self:sepInsertAt(uid, "bottom")
    table.insert(self.order, j, id)
    self.oSec[id] = uid
    local passed = {}
    for k = math.min(i, j), math.max(i, j) do passed[self.order[k]] = true end
    passed[id] = nil
    self:orderDropBroken(id, passed)
    local off = self:sepLanded(id, uid)
    self:orderChanged()
    if off then self:heldSelect(id) else self:orderSelect(id, false) end
    local sp = (uid ~= 0) and self:sepGet(uid) or nil
    local name = O.nameOf(model(), self._infoAll, id)
    if not off then
        if sp then self:say(ZeD.tr("UI_ZeD_Seps_SayMovedUnder", name, sp.name)) else self:say(ZeD.tr("UI_ZeD_Seps_SayMovedTop", name)) end
    end
    MM.clickSound()
end

-- a rule made toward a mod in another section takes this mod into that section when the rule
-- moves it (MODS_LOAD_ORDER_SPEC 3.3, 3.9)
local _pickerConfirm = ZeD_MMMods.pickerConfirm
function ZeD_MMMods:pickerConfirm()
    local P = self.pick
    if not (P and P.sel and self:sepsOn()) then return _pickerConfirm(self) end
    local x, y, how = P.id, P.sel, P.how
    local i0 = self:orderIndexOf(x)
    _pickerConfirm(self)
    if (self.oZone[x] or 2) ~= 2 or (self.oZone[y] or 2) ~= 2 then return end
    local sy = self.oSec[y] or 0
    if (self.oSec[x] or 0) == sy or self:orderIndexOf(x) == i0 then return end
    -- (what moved with it sits next to y: it joins y's section too)
    local idx = O.secIndex(self.oLo)
    local ky = idx[sy] or 0
    local j = self:orderIndexOf(y)
    local step = (how == "after") and 1 or -1
    local p = j + step
    while p >= 1 and p <= #self.order do
        local z = self.order[p]
        if (self.oZone[z] or 2) ~= 2 then break end
        local kz = idx[self.oSec[z] or 0] or 0
        if (step == 1 and kz >= ky) or (step == -1 and kz <= ky) then break end
        self.oSec[z] = sy
        p = p + step
    end
    self:orderChanged()
end

-- ----------------------------------------------------------------------------
-- MOVE IT UP (spec 7.6): a mod that needs one under a later separator
-- ----------------------------------------------------------------------------
function ZeD_MMMods:sepCrossNeed()
    local c = self._sCross
    if c and c.ver == self.oVer and c.order == self.order then return c.who, c.need end
    local who, need = nil, nil
    local res = self:orderCheck()
    if res.firstBad and O.hasSeps(self.oLo) then
        local I = self.oInfo or EMPTY
        for i, id in ipairs(self.order) do
            if res.st[i] == "bad" and (self.oZone[id] or 2) == 2 then
                for _, r in ipairs(I[id] and I[id].req or EMPTY) do
                    local j = res.idx[r]
                    if j and j > i and (self.oZone[r] or 2) == 2 and (self.oSec[r] or 0) ~= (self.oSec[id] or 0) then who, need = id, r; break end
                end
            end
            if who then break end
        end
    end
    self._sCross = { ver = self.oVer, order = self.order, who = who, need = need }
    return who, need
end

-- the needed mod to the end of the section above the one that needs it (loads before all of it);
-- at the top, or when the section above is off, just above the mod that needs it
function ZeD_MMMods:sepMoveItUp()
    local who, need = self:sepCrossNeed()
    if not who then return end
    local lo = self.oLo
    local idx = O.secIndex(lo)
    local s = self.oSec[who] or 0
    local k = idx[s] or 0
    self:orderSnap()
    table.remove(self.order, self:orderIndexOf(need))
    local prevUid = nil
    if k == 1 then prevUid = 0
    elseif k > 1 and lo.seps[k - 1].on then prevUid = lo.seps[k - 1].uid end
    if prevUid ~= nil then
        table.insert(self.order, self:sepInsertAt(s, "top"), need)
        self.oSec[need] = prevUid
    else
        table.insert(self.order, self:orderIndexOf(who), need)
        self.oSec[need] = s
    end
    self:orderChanged()
    self:orderSelect(need, false)
    local m = model()
    self:say(ZeD.tr("UI_ZeD_Seps_SayMovedUp", O.nameOf(m, self.oInfo, need), O.nameOf(m, self.oInfo, who)))
    MM.clickSound()
end

-- ----------------------------------------------------------------------------
-- START SEPARATORS FROM FOLDERS (spec 11; the director's pick: only mods that are on)
-- ----------------------------------------------------------------------------
function ZeD_MMMods:sepFromFolders(confirmed)
    if self.page ~= "order" or self.pick or not F.any() then return end
    if O.hasSeps(self.oLo) and not confirmed then
        self._backFocus = self.focusId
        self:setConfirm("sreplace")
        return
    end
    if self.confirm then self:setConfirm(false) end
    local helper = O.helperId()
    local by, rest, any = {}, {}, false
    for _, id in ipairs(self.order) do
        -- (the pinned blocks and ZeD picks stay where they are: only the middle has sections)
        if id ~= helper and (self.oZone[id] or 2) == 2 then
            local fid = F.folderOf(id)
            if fid then
                local t = by[fid]
                if not t then t = {}; by[fid] = t end
                t[#t + 1] = id
                any = true
            else
                rest[#rest + 1] = id
            end
        end
    end
    if not any then MM.hoverSound(); self:say(ZeD.tr("UI_ZeD_Seps_SayFromFoldersNone")); return end
    self:orderSnap()
    local seps, seen = {}, {}
    for _, f in ipairs(F.folders()) do
        if not seen[f.id] then
            seen[f.id] = true
            local ids = by[f.id]
            if ids and #ids > 0 then seps[#seps + 1] = { uid = O.newUid(), name = f.name, on = true, open = true, ids = ids, label = F.labelOf(f.id) } end
        end
    end
    if #rest > 0 then seps[#seps + 1] = { uid = O.newUid(), name = ZeD.tr("UI_ZeD_Folders_Unfiled"), on = true, open = true, ids = rest } end
    self.oLo.seps, self.oLo.top = seps, {}
    self.oOffHere = {}
    self.oSepSel, self.oHeldSel = nil, nil
    -- (each section sorted by the mods' own rules, never across a separator; nothing on or off)
    self:orderLayout(true)
    local res = self:orderCheck()
    local made = ZeD.tr(#seps == 1 and "UI_ZeD_Seps_ProfCountOne" or "UI_ZeD_Seps_ProfCountMany", #seps)
    if res.nBad > 0 then self:say(ZeD.tr(res.nBad == 1 and "UI_ZeD_Seps_SayFromFoldersRedOne" or "UI_ZeD_Seps_SayFromFoldersRed", made, res.nBad))
    else self:say(ZeD.tr("UI_ZeD_Seps_SayFromFolders", made)) end
    if seps[1] then self:sepSelect(seps[1].uid) end
    MM.clickSound()
end

-- ----------------------------------------------------------------------------
-- THE BAND: New separator..., Start separators from folders, Move it up; the questions
-- ----------------------------------------------------------------------------
function ZeD_MMMods:sepStrip(rights, res, status, color)
    local T = ZeD.T
    local who, need = self:sepCrossNeed()
    if who then
        rights[#rights + 1] = { "smoveup", ZeD.tr("UI_ZeD_Seps_BtnMoveItUp"), function() self:sepMoveItUp() end, "default", false, ZeD.tr("UI_ZeD_Seps_HelpMoveItUp") }
        if not (self.note and MM.now() < self.note.untilMs) then
            local c = self._sRed
            if not (c and c.ver == self.oVer and c.who == who) then
                local m = model()
                local sp = O.sepOf(self.oLo, self.oSec[need])
                c = { ver = self.oVer, who = who, text = ZeD.tr("UI_ZeD_Seps_RedLater", O.nameOf(m, self.oInfo, who), O.nameOf(m, self.oInfo, need), sp and sp.name or "") }
                self._sRed = c
            end
            status, color = c.text, T.danger
        end
    end
    rights[#rights + 1] = { "snew", ZeD.tr("UI_ZeD_Seps_BtnNew"), function() self:sepAskNew() end, "default", false, ZeD.tr("UI_ZeD_Seps_HelpNew") }
    if not O.hasSeps(self.oLo) and F.any() then
        rights[#rights + 1] = { "sfolders", ZeD.tr("UI_ZeD_Seps_BtnFromFolders"), function() self:sepFromFolders(false) end, "default", false, ZeD.tr("UI_ZeD_Seps_HelpFromFolders") }
    end
    return status, color
end

local _buildStrip = ZeD_MMMods.buildStrip
function ZeD_MMMods:buildStrip(stripY, stripH, w)
    local c = self.confirm
    if c == "snew" or c == "srename" or c == "sreplace" then return self:sepConfirmStrip(stripY, stripH, w, 100000) end
    return _buildStrip(self, stripY, stripH, w)
end

function ZeD_MMMods:sepConfirmStrip(stripY, stripH, w, row)
    local T = ZeD.T
    local c = self.confirm
    local cancel = { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end }
    if c == "sreplace" then
        local n = #self.oLo.seps
        UI.stripSpecs(self, stripY, w, row, {}, {
            cancel,
            { "confirm:yes", ZeD.tr("UI_ZeD_Seps_BtnReplaceGo"), function() self:sepFromFolders(true) end, "danger", false, ZeD.tr("UI_ZeD_Seps_HelpReplace") } },
            ZeD.tr(n == 1 and "UI_ZeD_Seps_AskReplaceOne" or "UI_ZeD_Seps_AskReplaceMany", n, self:sepListName()))
        return
    end
    local text = self.field:getText() or ""
    local name = F.trim(text)
    local ask
    local used = (name ~= "") and nameTaken(self.oLo, name, (c == "srename") and self._sTarget or nil) or nil
    if used then ask = ZeD.tr("UI_ZeD_Seps_AskNameUsed", used)
    elseif c == "srename" then
        local sp = self:sepGet(self._sTarget)
        ask = ZeD.tr("UI_ZeD_Seps_AskRename", sp and sp.name or "")
    else ask = ZeD.tr("UI_ZeD_Seps_AskNew") end
    local fx = UI.stripSpecs(self, stripY, w, row, {}, {
        cancel,
        { "confirm:yes", (c == "srename") and getText("UI_btn_rename") or ZeD.tr("UI_ZeD_Seps_BtnMake"), function() self:fieldEnter() end, "primary", name == "" } },
        ask, true)
    local firstBtn = w
    for _, b in ipairs(self._specs) do if b.row == row and b.x then firstBtn = math.min(firstBtn, b.x) end end
    local fh = T.px(24)
    UI.styleEntry(self.field, fx, stripY + math.floor((stripH - fh) / 2), math.max(T.px(80), firstBtn - T.px(12) - fx), fh)
    if #text > NAME_MAX then self.field:setText(string.sub(text, 1, NAME_MAX)) end
end

local _fieldEnter = ZeD_MMMods.fieldEnter
function ZeD_MMMods:fieldEnter()
    local c = self.confirm
    if c ~= "snew" and c ~= "srename" then return _fieldEnter(self) end
    local name = F.trim(self.field:getText())
    if #name > NAME_MAX then name = string.sub(name, 1, NAME_MAX) end
    if name == "" then MM.hoverSound(); return end
    local uid = self._sTarget
    self:setConfirm(false)
    if c == "snew" then self:sepNew(name) else self:sepRename(uid, name) end
end

-- ----------------------------------------------------------------------------
-- MENUS (spec 8: A on a row, Shift+F10 or the menu key, right-click)
-- ----------------------------------------------------------------------------
-- where a menu opened from the keyboard or the controller sits: at the focused entry
function ZeD_MMMods:sepAnchor()
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local L, v = self._list, self:orderView()
    local k = (v.at and v.at[self.focusId or ""]) or v.byPlace[self.oSel or 1]
    local e = k and v.ents[k]
    if L and e then return { x = ax + L.x + T.px(60), y = ay + L.y + e.y - self.scroll, w = T.px(10), h = e.h } end
    return { x = ax + T.px(60), y = ay + T.px(60), w = T.px(10), h = T.px(10) }
end

-- a mod row's menu gets Move to separator... and New separator...
function ZeD_MMMods:sepRowItems(items, id)
    if self.page ~= "order" then return end
    items[#items + 1] = "-"
    if self:sepsOn() and (self.oZone[id] or 2) == 2 then
        items[#items + 1] = { text = ZeD.tr("UI_ZeD_Seps_MenuMoveTo"), fn = function() self:sepMoveMenu(id) end }
    end
    items[#items + 1] = { text = ZeD.tr("UI_ZeD_Seps_BtnNew"), fn = function() self:sepAskNew() end }
end

-- the pop-up of separators a mod can go under (the D-pad picks, A moves it, B leaves it)
function ZeD_MMMods:sepMoveMenu(id)
    local cur = self.oSec[id] or 0
    local items = { { text = ZeD.tr("UI_ZeD_Seps_MenuMoveHead", O.nameOf(model(), self.oInfo, id)), disabled = true }, "-" }
    items[#items + 1] = { text = ZeD.tr("UI_ZeD_Seps_MenuTop"), disabled = cur == 0, fn = function() self:sepMoveModTo(id, 0) end }
    for _, sp in ipairs(self.oLo.seps) do
        local uid = sp.uid
        local label = ZeD.Atoms.truncateText(sp.name, ZeD.T.fontF2, ZeD.T.px(260))
        if not sp.on then label = ZeD.tr("UI_ZeD_Seps_MenuOffName", label) end
        items[#items + 1] = { text = label, disabled = cur == uid, fn = function() self:sepMoveModTo(id, uid) end }
    end
    MM.openPopup("sepMove", items, self:sepAnchor(), false)
end

function ZeD_MMMods:sepMenu(uid, anchor)
    local sp, k = self:sepGet(uid)
    if not sp then return end
    local _, shown = self:sepCounts(sp)
    local ticked = sp.on and shown == 0
    local n = #self.oLo.seps
    local items = { { text = sp.name, disabled = true }, "-" }
    items[#items + 1] = { text = ZeD.tr(sp.open and "UI_ZeD_Seps_MenuCollapse" or "UI_ZeD_Seps_MenuExpand"), fn = function() self:sepOpenClose(uid) end }
    items[#items + 1] = { text = ZeD.tr(ticked and "UI_ZeD_Seps_BtnTurnOff" or "UI_ZeD_Seps_BtnTurnOn"), fn = function() self:sepBox(uid) end }
    items[#items + 1] = "-"
    items[#items + 1] = { text = ZeD.tr("UI_ZeD_Seps_MenuRename"), fn = function() self:sepAskRename(uid) end }
    items[#items + 1] = { text = ZeD.tr("UI_ZeD_Seps_MenuDelete"), fn = function() self:sepDelete(uid) end }
    items[#items + 1] = "-"
    items[#items + 1] = { text = ZeD.tr("UI_ServerSettings_ButtonMoveUp"), disabled = k <= 1, fn = function() self:sepShift(uid, -1) end }
    items[#items + 1] = { text = ZeD.tr("UI_ServerSettings_ButtonMoveDown"), disabled = k >= n, fn = function() self:sepShift(uid, 1) end }
    items[#items + 1] = "-"
    items[#items + 1] = { text = ZeD.tr("UI_ZeD_Seps_BtnNew"), fn = function() self:sepAskNew() end }
    if F.any() then items[#items + 1] = { text = ZeD.tr("UI_ZeD_Seps_BtnReplace"), fn = function() self:sepFromFolders(false) end } end
    MM.openPopup("sepRow", items, anchor or self:sepAnchor(), false)
end

function ZeD_MMMods:heldMenu(id, anchor)
    local items = { { text = O.nameOf(model(), self._infoAll, id), disabled = true }, "-",
                    { text = ZeD.tr("UI_ZeD_Seps_BtnTurnOn"), fn = function() self:heldTurnOn(id) end } }
    MM.openPopup("sepHeld", items, anchor or self:sepAnchor(), false)
end

local _orderMenu = ZeD_MMMods.orderMenu
function ZeD_MMMods:orderMenu(anchor)
    if self.page == "order" and not self.pick then
        if self.oSepSel then return self:sepMenu(self.oSepSel, anchor) end
        if self.oHeldSel then return self:heldMenu(self.oHeldSel, anchor) end
    end
    return _orderMenu(self, anchor)
end

-- a right-click on a separator or a dimmed row picks it and opens its menu there
local _rightClick = ZeD_MMMods.rightClick
function ZeD_MMMods:rightClick(mx, my)
    if self.page == "order" and not self.pick and not self.confirm and self:sepsOn() then
        local L = self._list
        local lx, ly = mx - self:getAbsoluteX(), my - self:getAbsoluteY()
        if L and lx >= L.x and lx <= L.x + L.w and ly >= L.y and ly <= L.y + L.h then
            local v = self:orderView()
            local yy = ly - L.y + self.scroll
            for k = 1, #v.ents do
                local e = v.ents[k]
                if yy >= e.y and yy < e.y + e.h then
                    local anchor = { x = mx, y = my, w = 1, h = 1 }
                    if e.k == "sep" then self.oSepSel, self.oHeldSel, self.focusId = e.uid, nil, e.sid; self:sepMenu(e.uid, anchor); return true end
                    if e.k == "held" then self.oSepSel, self.oHeldSel, self.focusId = nil, e.id, e.sid; self:heldMenu(e.id, anchor); return true end
                    break
                end
                if e.y > yy then break end
            end
        end
    end
    return _rightClick(self, mx, my)
end

-- ----------------------------------------------------------------------------
-- THE PANE: a separator's (mockup v1 b), a dimmed mod's
-- ----------------------------------------------------------------------------
local function btn(id, text, fn, disabled, help)
    return { id = id, text = text, fn = fn, variant = "default", disabled = disabled, help = help }
end

local _detModel = ZeD_MMMods.orderDetailModel
function ZeD_MMMods:orderDetailModel(rw)
    if self.page ~= "order" or not (self.oSepSel or self.oHeldSel) then return _detModel(self, rw) end
    local T = ZeD.T
    local c = self._sDetail
    if c and c.ver == self.oVer and c.sep == self.oSepSel and c.held == self.oHeldSel and c.rw == rw and c.scale == T.scale then return c end
    c = { ver = self.oVer, sep = self.oSepSel, held = self.oHeldSel, rw = rw, scale = T.scale, items = {} }
    self._sDetail = c
    if self.oSepSel then self:sepDetailItems(c.items, rw, self.oSepSel) else self:heldDetailItems(c.items, rw, self.oHeldSel) end
    return c
end

local function textItem(items, rw, s, dot, dim)
    local T = ZeD.T
    items[#items + 1] = { t = "text", dot = dot, dim = dim, lines = ZeD.Atoms.wrapText(s, T.fontF2, rw - (dot and T.px(14) or 0)) }
end

function ZeD_MMMods:sepDetailItems(items, rw, uid)
    local T = ZeD.T
    local m = model()
    local sp, k = self:sepGet(uid)
    if not sp then return end
    local onN, shown, offAll = self:sepCounts(sp)
    local ticked = sp.on and shown == 0
    items[#items + 1] = { t = "title", text = sp.name }
    local sub = sp.on and ZeD.tr(onN == 1 and "UI_ZeD_Seps_DetSubOnOne" or "UI_ZeD_Seps_DetSubOn", onN, self:sepListName())
        or ZeD.tr(offAll == 1 and "UI_ZeD_Seps_DetSubOffOne" or "UI_ZeD_Seps_DetSubOff", offAll, self:sepListName())
    items[#items + 1] = { t = "sub", text = sub }
    items[#items + 1] = { t = "btns", list = {
        btn("sbox", ZeD.tr(ticked and "UI_ZeD_Seps_BtnTurnOff" or "UI_ZeD_Seps_BtnTurnOn"), function() self:sepBox(uid) end, false, ZeD.tr("UI_ZeD_Seps_HelpBox", sp.name)),
        btn("sren", ZeD.tr("UI_ZeD_Seps_MenuRename"), function() self:sepAskRename(uid) end),
        btn("sdel", ZeD.tr("UI_ZeD_Seps_MenuDelete"), function() self:sepDelete(uid) end, false, ZeD.tr("UI_ZeD_Seps_HelpDelete")) } }
    items[#items + 1] = { t = "btns", list = {
        btn("sup", ZeD.tr("UI_ServerSettings_ButtonMoveUp"), function() self:sepShift(uid, -1) end, k <= 1),
        btn("sdown", ZeD.tr("UI_ServerSettings_ButtonMoveDown"), function() self:sepShift(uid, 1) end, k >= #self.oLo.seps),
        btn("sfold", ZeD.tr(sp.open and "UI_ZeD_Seps_MenuCollapse" or "UI_ZeD_Seps_MenuExpand"), function() self:sepOpenClose(uid) end) } }
    -- its label (ZeD's accent colours), kept with the profile's separators
    items[#items + 1] = { t = "head", text = ZeD.tr("UI_ZeD_Mods_Label") }
    items[#items + 1] = { t = "labels", sp = sp, uid = uid }
    -- under it, in order: the mods on with their numbers, the mods off dimmed
    items[#items + 1] = { t = "head", text = ZeD.tr("UI_ZeD_Seps_DetUnder"), note = "(" .. tostring(onN + offAll) .. ")" }
    local idx = {}
    for i, id in ipairs(self.order) do idx[id] = i end
    local n, w = 0, rw - T.px(14)
    for _, id in ipairs(sp.ids or EMPTY) do
        if n >= LIST_MAX then break end
        local d = m and m.mods[id]
        local name = O.nameOf(m, self._infoAll, id)
        if idx[id] then
            n = n + 1
            items[#items + 1] = { t = "text", dot = T.positive, lines = { ZeD.Atoms.truncateText(idx[id] .. "  " .. name, T.fontF2, w) } }
        elseif d then
            n = n + 1
            items[#items + 1] = { t = "text", dim = true, lines = { ZeD.Atoms.truncateText(ZeD.tr("UI_ZeD_Seps_DetOffMod", name), T.fontF2, w) } }
        else
            n = n + 1
            items[#items + 1] = { t = "text", dim = true, lines = { ZeD.Atoms.truncateText(ZeD.tr("UI_ZeD_Seps_DetMissing", id), T.fontF2, w) } }
        end
    end
    if n == 0 then textItem(items, rw, ZeD.tr("UI_ZeD_Seps_DetEmpty"), nil, true) end
    items[#items + 1] = { t = "head", text = ZeD.tr("UI_ZeD_Seps_DetBox") }
    if ticked then textItem(items, rw, ZeD.tr("UI_ZeD_Seps_DetBoxOn"))
    else textItem(items, rw, ZeD.tr((shown + onN == 1) and "UI_ZeD_Seps_DetBoxOffOne" or "UI_ZeD_Seps_DetBoxOff", shown + onN)) end
    textItem(items, rw, ZeD.tr("UI_ZeD_Seps_DetKept"), nil, true)
    if F.any() then
        items[#items + 1] = { t = "btns", list = { btn("sfrom", ZeD.tr("UI_ZeD_Seps_BtnReplace"), function() self:sepFromFolders(false) end, false, ZeD.tr("UI_ZeD_Seps_HelpFromFolders")) } }
    end
end

function ZeD_MMMods:heldDetailItems(items, rw, id)
    local T = ZeD.T
    local m = model()
    local mem = O.secMembers(self.oLo)
    local sp = mem[id] and mem[id] ~= 0 and self:sepGet(mem[id]) or nil
    items[#items + 1] = { t = "title", text = O.nameOf(m, self._infoAll, id) }
    items[#items + 1] = { t = "sub", text = sp and ZeD.tr("UI_ZeD_Seps_DetHeldSub", sp.name) or ZeD.tr("UI_ZeD_Seps_DetHeldSubTop") }
    items[#items + 1] = { t = "btns", list = { btn("hon", ZeD.tr("UI_ZeD_Seps_BtnTurnOn"), function() self:heldTurnOn(id) end) } }
    textItem(items, rw, self:sepWhy(id, sp), T.textDim)
    textItem(items, rw, ZeD.tr("UI_ZeD_Seps_DetHeldText"), nil, true)
end

-- ----------------------------------------------------------------------------
-- CONTROLLER AND KEYS (the director's pad rules: the focus returns where it was, lands on the
-- primary, the common actions cheapest)
-- ----------------------------------------------------------------------------
-- A on a separator or a dimmed row: its menu (as A on a mod row)
local _orderJoyA = ZeD_MMMods.orderJoyA
function ZeD_MMMods:orderJoyA()
    local p = (self.focusId or ""):sub(1, 5)
    if self.page == "order" and not self.pick and (p == "osep:" or p == "ohld:") then self:orderMenu(nil); return true end
    return _orderJoyA(self)
end

-- the D-pad onto a separator or a dimmed row picks it (its pane); the picked mod stays picked
local _joyDir = ZeD_MMMods.joyDir
function ZeD_MMMods:joyDir(dir)
    if self.page ~= "order" or self.pick then return _joyDir(self, dir) end
    local keep = self.oSel
    _joyDir(self, dir)
    local f = self.focusId or ""
    local p = f:sub(1, 5)
    if p == "osep:" then
        self.oSel = keep
        self.oSepSel, self.oHeldSel = tonumber(f:sub(6)), nil
        self:sepScrollTo(f)
    elseif p == "ohld:" then
        self.oSel = keep
        self.oSepSel, self.oHeldSel = nil, f:sub(6)
        self:sepScrollTo(f)
    elseif p == "orow:" then
        self.oSepSel, self.oHeldSel = nil, nil
    end
end

-- the next separator heading up (-1) or down (1) from the focus (LB / RB, Ctrl+Page Up / Down)
function ZeD_MMMods:sepJump(dir)
    local v = self:orderView()
    local ents = v.ents
    local k = (v.at and v.at[self.focusId or ""]) or v.byPlace[self.oSel or 1] or 0
    local j = k + dir
    while j >= 1 and j <= #ents do
        if ents[j].k == "sep" then self:sepSelect(ents[j].uid); MM.hoverSound(); return end
        j = j + dir
    end
end

local _joyBumper = ZeD_MMMods.joyBumper
function ZeD_MMMods:joyBumper(dir)
    if self.page == "order" and not self.confirm and not self.pick and self:sepsOn() then self:sepJump(dir); return end
    return _joyBumper(self, dir)
end

-- keys: on a separator Space its box, F2 Rename..., Delete, Left / Right collapse / open,
-- Ctrl+Up / Down move it (through move); Space on a dimmed row turns it on; Ctrl+Page Up / Down
-- jump separator to separator
local _orderKey = ZeD_MMMods.orderKey
function ZeD_MMMods:orderKey(key)
    if self.pick or self.page ~= "order" then return _orderKey(self, key) end
    local K = Keyboard
    local ctrl = isCtrlKeyDown()
    if ctrl and self:sepsOn() and (key == K.KEY_PRIOR or key == K.KEY_NEXT) then self:sepJump(key == K.KEY_PRIOR and -1 or 1); return true end
    local sel, held = self.oSepSel, self.oHeldSel
    if sel and not ctrl then
        if key == K.KEY_SPACE then self:sepBox(sel); return true end
        if key == K.KEY_F2 then self:sepAskRename(sel); return true end
        if key == K.KEY_DELETE then self:sepDelete(sel); return true end
        if key == K.KEY_LEFT then self:sepOpenClose(sel, false); return true end
        if key == K.KEY_RIGHT then self:sepOpenClose(sel, true); return true end
    elseif held and not ctrl and key == K.KEY_SPACE then
        self:heldTurnOn(held)
        return true
    end
    if (sel or held) and not ctrl and (key == K.KEY_UP or key == K.KEY_DOWN) then
        self.focusId = sel and ("osep:" .. tostring(sel)) or ("ohld:" .. tostring(held))
        self:joyDir(key == K.KEY_UP and "up" or "down")
        return true
    end
    return _orderKey(self, key)
end

local _orderPrompts = ZeD_MMMods.orderPrompts
function ZeD_MMMods:orderPrompts(f, sel, back)
    if not self.pick and self.page == "order" then
        local p = f:sub(1, 5)
        if p == "osep:" then
            return { { glyph = "A", label = ZeD.tr("UI_ZeD_Order_PromptMenu") }, { glyph = "Y", label = ZeD.tr("UI_ServerSettings_ButtonMoveUp") },
                     { glyph = "X", label = ZeD.tr("UI_ServerSettings_ButtonMoveDown") }, { glyph = "LB", label = "" },
                     { glyph = "RB", label = ZeD.tr("UI_ZeD_Seps_PromptJump") }, { glyph = "B", label = back } }
        end
        if p == "ohld:" then
            return { { glyph = "A", label = ZeD.tr("UI_ZeD_Order_PromptMenu") }, { glyph = "LB", label = "" },
                     { glyph = "RB", label = ZeD.tr("UI_ZeD_Seps_PromptJump") }, { glyph = "B", label = back } }
        end
        if p == "orow:" and self:sepsOn() then
            local t = _orderPrompts(self, f, sel, back)
            for _, g in ipairs(t) do if g.glyph == "RB" then g.label = ZeD.tr("UI_ZeD_Seps_PromptJump") end end
            return t
        end
    end
    return _orderPrompts(self, f, sel, back)
end
