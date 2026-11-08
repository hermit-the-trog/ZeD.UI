-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuModsOrder.lua
-- ============================================================================
-- THE MODS SCREEN'S LOAD ORDER AND MAP ORDER PAGES. Client-side; part of the
-- ZeD_MMMods organism (pages of the window ZeD_MainMenuMods.lua builds).
--
--   * built for 1,500 mods: the order check, the place numbers, the gap counts and the
--     list's rows are worked out once per change and kept (oVer counts the changes); each frame
--     draws, and makes controller stops for, only the rows in sight (one either side, and the
--     chosen one)
--   * Find in the load order: only the matches, each with its real place number, the
--     gaps counted ("38 more"); A / Return / a double-click shows the match in the full list
--   * pins: Load first / Load last blocks, with the mods they carry; ZeD picks kept
--     last by ZeD, shown and explained
--   * your rules: Load after... / Load before... from a picker of the other mods, kept
--     through Auto and profile loads, shown on the row, removable; circles refused with a reason
--   * moves: one place (Y / X, Ctrl+Up / Down, Move up / Move down), to the top or the
--     bottom of the block (the row's menu, Ctrl+Home / End), drag (not while Find has text),
--     Undo (the band, Ctrl+Z)
--   * held until Done; Done keeps the list's pins and rules (ZeD_ModOrder)
--
-- Separators and sections are ZeD_MainMenuModsSeps.lua:
-- the list's entries, the separator rows, their pane and menu; this file keeps each mod's section
-- (oSec) through every change, Undo and Back.
-- ============================================================================
require "ZeD/ZeD_MainMenuMods"
require "ZeD/ZeD_ModOrder"
local MM = ZeD.MainMenu
local UI = MM.ui
local O  = ZeD.ModOrder

-- design units
local ROW_H, HEAD_H, GAP_H, FIND_H, TITLE_H = 32, 26, 18, 34, 26
local DETAIL_PAD = 12
local LIST_SHARE = 0.5
local UNDO_MAX = 30
local DRAG_PX = 6
local DOUBLE_MS = 450

local EMPTY = {}

local function model() return ModSelector and ModSelector.instance and ModSelector.instance.model end
local function jlist(l)
    local t = {}
    if l then for i = 0, l:size() - 1 do t[#t + 1] = l:get(i) end end
    return t
end

-- a tag's width, as the library draws it (ZeD.Atoms.drawTag: 5u sides, a 6u mark and its gap)
local function tagW(text, marked)
    local T = ZeD.T
    return MM.textW(T.fontF1, ZeD.textCase(text)) + T.px(10) + (marked and T.px(10) or 0)
end

-- ----------------------------------------------------------------------------
-- SET-UP: the picker's own Find field; what the screen keeps between pages
-- ----------------------------------------------------------------------------
local _createChildren = ZeD_MMMods.createChildren
function ZeD_MMMods:createChildren()
    _createChildren(self)
    self.find.onTextChange = function() self.scroll = 0 end
    self.pfind = UI.newEntry(self)        -- the Load after... picker's Find
    self.pfind.onTextChange = function() if self.pick then self.pick.scroll = 0 end end
    self.pfind.onCommandEntered = function() self._enterAt = MM.now(); self.pfind:unfocus() end
    self.pfind:setVisible(false)
end

local _onShow = ZeD_MMMods.onShow
function ZeD_MMMods:onShow()
    _onShow(self)
    self._infoAll = nil           -- (vanilla reloads its records when the screen opens)
    self.pick, self._drag, self.oUndo = nil, nil, nil
    if self.pfind then self.pfind:setText(""); self.pfind:setVisible(false) end
end

--- Each mod's needs and wishes, read from the game once and kept while the screen is up.
function ZeD_MMMods:infoFor(m, ids)
    local c = self._infoAll
    if not c then c = {}; self._infoAll = c end
    local miss = {}
    for _, id in ipairs(ids) do if not c[id] then miss[#miss + 1] = id end end
    if #miss > 0 then for id, e in pairs(O.readInfo(m, miss)) do c[id] = e end end
    local I = {}
    for _, id in ipairs(ids) do I[id] = c[id] end
    return I
end

--- A mod turned on (on the Mods page, by a profile) while the list has pins or rules: the order
--- is laid out again (a new mod goes to the end, above the Load last block).
function ZeD_MMMods:relayoutList()
    local m = model()
    if not m then return end
    local lo = O.getLo(O.listKey(m))
    if O.isEmpty(lo) then return end
    local ids = jlist(m:getActiveMods():getMods())
    local order = O.layout(O.seqFrom(lo, ids), self:infoFor(m, ids), lo, false)
    self:saveOrder(order)
end

-- A seam for section headings while the list is built: called before place i, push(entry, height)
-- adds one. A deliberate no-op — ZeD_MainMenuModsSeps builds its separator rows by wrapping
-- orderEntries instead, so nothing overrides this.
function ZeD_MMMods:orderSectionHook(ents, i, q, push) end

-- ----------------------------------------------------------------------------
-- ENTERING AND LEAVING
-- ----------------------------------------------------------------------------
--- Open the load order page ("order") or the map order page ("maps").
function ZeD_MMMods:enterOrder(page)
    local m = model()
    if not m then return end
    MM.clickSound()
    self.confirm = false
    -- (the Mods page's Find comes back on leaving; this page's starts empty and is never saved)
    self._listFind = self.find:getInternalText() or ""
    self.find:setText("")
    if self.find:isFocused() then self.find:unfocus() end
    self.oUndo, self.pick, self._drag = {}, nil, nil
    if page == "order" then
        local ids = jlist(m:getActiveMods():getMods())
        self.oInfo = self:infoFor(m, ids)
        self.oKey = O.listKey(m)
        self.oLo = O.getLo(self.oKey)
        self.order, self.oZone, self.oCarried, self.oSec = O.layout(O.seqFrom(self.oLo, ids), self.oInfo, self.oLo, false)
    else
        self.order = jlist(m:getAllMapsInOrder())
        self.oInfo, self.oLo, self.oZone, self.oCarried, self.oSec = {}, O.copyLo(nil), {}, {}, {}
    end
    -- (separators: nothing picked; what was on when the page opened, for Back)
    self.oSepSel, self.oHeldSel, self.oOffHere = nil, nil, {}
    self._oActive0 = {}
    for _, id in ipairs(page == "order" and self.order or EMPTY) do self._oActive0[id] = true end
    -- (and which mod took ZeD picks off, if one did: Back puts that memory back with the set)
    self._oPicksOffWith0 = self._picksOffWith
    self._orderStart = table.concat(self.order, ";")
    self.page = page
    self.oSel = 1
    self.scroll = 0
    self.focusId = "orow:1"
    self:orderChanged()
end

--- keep = true writes the order (vanilla's correctAndSaveModOrder / getMapOrder) and the list's
--- pins and rules; false leaves both as they were.
function ZeD_MMMods:leaveOrder(keep)
    local m = model()
    if keep and m then
        if self.page == "order" then
            self:saveOrder(self.order)
            O.putLo(self.oKey or O.listKey(m), self.oLo, true)
        else
            local mo = m:getActiveMods():getMapOrder()
            mo:clear()
            for _, name in ipairs(self.order) do mo:add(name) end
        end
        self:say(ZeD.tr(self.page == "order" and "UI_ZeD_Mods_SayOrderSet" or "UI_ZeD_Mods_SayMapsSet"))
    elseif m and self.page == "order" and self.sepMatchActive then
        -- (Back: a separator's box turned mods on or off here; they go back as they were)
        self:sepMatchActive(self._oActive0)
        -- (a separator box here may have cleared the ZeD picks memory: it goes back with the set)
        if self.restorePicksOffWith then self:restorePicksOffWith(self._oPicksOffWith0) end
    end
    self.oSepSel, self.oHeldSel = nil, nil
    MM.clickSound()
    self:closePicker(true)
    if self.find:isFocused() then self.find:unfocus() end
    self.find:setText(self._listFind or "")
    self.page = "list"
    self.scroll = 0
    self.focusId = nil
    self.oUndo = nil
end

-- Done: laid out once more (your rules and pins), then kept; never while a row is red
function ZeD_MMMods:orderDone()
    if self.page == "order" then
        if self:orderCheck().firstBad then self:say(ZeD.tr("UI_ZeD_Mods_RuleFix")); MM.hoverSound(); return end
        self.order, self.oZone, self.oCarried, self.oSec = O.layout(self:orderSeq(), self.oInfo, self.oLo, false)
        self:orderChanged()
    end
    self:leaveOrder(true)
end

-- ----------------------------------------------------------------------------
-- CHANGES, THE CHECK, UNDO
-- ----------------------------------------------------------------------------
function ZeD_MMMods:orderChanged()
    self.oVer = (self.oVer or 0) + 1
    -- (the separators' lists follow the order: once per change)
    if self.page == "order" and O.hasSeps(self.oLo) then O.secSync(self.oLo, self.order, self.oZone, self.oSec) end
end

-- the order to lay out from: with separators, each section's mods in their lists' order (so the
-- mods that are off keep their places when they come back on), then the rest of the order
function ZeD_MMMods:orderSeq()
    if self.page ~= "order" or not O.hasSeps(self.oLo) then return self.order end
    local seq, seen, on = {}, {}, {}
    for _, id in ipairs(self.order) do on[id] = true end
    local function add(id) if on[id] and not seen[id] then seen[id] = true; seq[#seq + 1] = id end end
    for _, id in ipairs(self.order) do if (self.oZone[id] or 2) == 1 then add(id) end end
    for _, id in ipairs(self.oLo.top or EMPTY) do add(id) end
    for _, sp in ipairs(self.oLo.seps) do for _, id in ipairs(sp.ids or EMPTY) do add(id) end end
    for _, id in ipairs(self.order) do add(id) end
    return seq
end

-- the order check, worked out once per change, not per frame
function ZeD_MMMods:orderCheck()
    local c = self._oCheck
    if c and c.ver == self.oVer and c.order == self.order then return c.res end
    local res
    if self.page == "order" then res = O.check(self.order, self.oInfo or EMPTY, self.oLo, self.oZone)
    else res = { st = {}, idx = {}, nBad = 0, nSoft = 0 } end
    self._oCheck = { ver = self.oVer, order = self.order, res = res }
    return res
end

--- The per-row states and the first red row, kept for older callers of this shape.
function ZeD_MMMods:orderStates()
    local r = self:orderCheck()
    return r.st, r.firstBad
end

local function copyArr(t) local o = {}; for i, v in ipairs(t or EMPTY) do o[i] = v end; return o end
local function copyMap(t) local o = {}; for k, v in pairs(t or EMPTY) do o[k] = v end; return o end

function ZeD_MMMods:orderSnap()
    local u = self.oUndo
    if not u then u = {}; self.oUndo = u end
    u[#u + 1] = { order = copyArr(self.order), lo = O.copyLo(self.oLo), zone = copyMap(self.oZone), carried = copyMap(self.oCarried), sel = self.oSel,
                  sec = copyMap(self.oSec), offHere = copyMap(self.oOffHere), sepSel = self.oSepSel,
                  picksOffWith = self._picksOffWith }   -- (which mod took ZeD picks off, for Undo)
    if #u > UNDO_MAX then table.remove(u, 1) end
end

function ZeD_MMMods:orderUndo()
    local u = self.oUndo
    if not (u and #u > 0) then return end
    local s = table.remove(u)
    self.order, self.oLo, self.oZone, self.oCarried = s.order, s.lo, s.zone, s.carried
    self.oSec, self.oOffHere = s.sec or {}, s.offHere or {}
    -- (a separator's box turned mods on or off: they go back with the order)
    if self.page == "order" and self.sepMatchActive then
        local want = {}
        for _, id in ipairs(s.order) do want[id] = true end
        self:sepMatchActive(want)
        -- (the ZeD picks memory kept with that step comes back with its mods)
        if self.restorePicksOffWith then self:restorePicksOffWith(s.picksOffWith) end
    end
    self:orderChanged()
    self:orderSelectAt(s.sel or 1, false)
    if s.sepSel and self.sepSelect then self:sepSelect(s.sepSel) end
    MM.clickSound()
    self:say(ZeD.tr("UI_ZeD_Order_SayUndone"))
end

-- lays the order out again: after a pin, a rule, Auto (auto = true)
function ZeD_MMMods:orderLayout(auto)
    self.order, self.oZone, self.oCarried, self.oSec = O.layout(self:orderSeq(), self.oInfo, self.oLo, auto)
    self:orderChanged()
end

-- the mod's place now
function ZeD_MMMods:orderIndexOf(id)
    for i, x in ipairs(self.order) do if x == id then return i end end
    return nil
end

-- picks place i, the controller's focus on it, scrolled into sight (center = in the middle)
function ZeD_MMMods:orderSelectAt(i, center)
    i = math.max(1, math.min(#self.order, i or 1))
    self.oSel = i
    self.oSepSel, self.oHeldSel = nil, nil
    self.focusId = "orow:" .. i
    local v = self:orderView()
    local k = v.byPlace[i]
    local e = k and v.ents[k]
    local vh = self._list and self._list.h or 0
    if not (e and vh > 0) then return end
    if center then self.scroll = math.max(0, e.y + math.floor(e.h / 2) - math.floor(vh / 2))
    elseif e.y < self.scroll then self.scroll = e.y
    elseif e.y + e.h > self.scroll + vh then self.scroll = e.y + e.h - vh end
end

function ZeD_MMMods:orderSelect(id, center)
    local i = self:orderIndexOf(id)
    if i then self:orderSelectAt(i, center) end
end

-- the first and last place of the block place i is in
function ZeD_MMMods:orderBlockRange(i)
    local z = self.oZone[self.order[i]] or 2
    local a, b = i, i
    while a > 1 and (self.oZone[self.order[a - 1]] or 2) == z do a = a - 1 end
    while b < #self.order and (self.oZone[self.order[b + 1]] or 2) == z do b = b + 1 end
    return a, b
end

-- ----------------------------------------------------------------------------
-- MOVES: a move out of a block unpins; a move that breaks a rule removes the rule
-- ----------------------------------------------------------------------------
-- a manual move put x past the mods in passed: a rule between x and one of them that is no
-- longer kept goes (the player's latest word); the band says so, Undo brings it back
function ZeD_MMMods:orderDropBroken(x, passed)
    local rules = self.oLo.rules
    local removed = nil
    local idx = nil
    for k = #rules, 1, -1 do
        local r = rules[k]
        local y = (r.id == x and r.other) or (r.other == x and r.id) or nil
        if y and passed[y] then
            if not idx then idx = {}; for i, id in ipairs(self.order) do idx[id] = i end end
            if O.ruleKept(idx, r) == false then table.remove(rules, k); removed = removed or r end
        end
    end
    if removed then
        local m = model()
        local key = removed.how == "after" and "UI_ZeD_Order_SayRuleGoneAfter" or "UI_ZeD_Order_SayRuleGoneBefore"
        self:say(ZeD.tr(key, O.nameOf(m, self.oInfo, removed.id == x and removed.other or removed.id)))
    end
    return removed
end

-- pinned in the block it sits in? ("first" | "last" | nil)
function ZeD_MMMods:orderPinHere(id)
    local pin = O.pinOf(self.oLo, id)
    local z = self.oZone[id]
    if (pin == "first" and z == 1) or (pin == "last" and z == 3) then return pin end
    return nil
end

-- why a row cannot cross into the next block (nil: it can, by unpinning)
function ZeD_MMMods:orderEdgeWhy(id)
    local m = model()
    if self.oCarried[id] then return ZeD.tr("UI_ZeD_Order_SayCarriedStays", O.nameOf(m, self.oInfo, id)) end
    return ZeD.tr("UI_ZeD_Order_SayBlockEdge")
end

--- One place up (-1) or down (1): a swap, never a layout.
function ZeD_MMMods:move(delta)
    if self.pick or not self.order then return end
    local i = self.oSel or 1
    local j = i + delta
    if j < 1 or j > #self.order then return end
    local a, b = self.order[i], self.order[j]
    if self.page ~= "order" then
        self.order[i], self.order[j] = b, a
        self:orderChanged()
        self:orderSelectAt(j, false)
        MM.hoverSound()
        return
    end
    local helper = O.helperId()
    if a == helper or b == helper then self:say(ZeD.tr("UI_ZeD_Order_SayHelperFixed")); MM.hoverSound(); return end
    if (self.oZone[a] or 2) ~= (self.oZone[b] or 2) then
        local pin = self:orderPinHere(a)
        if not pin then self:say(self:orderEdgeWhy(a)); MM.hoverSound(); return end
        -- out of its block: unpinned, at the nearest place outside it
        self:orderSnap()
        O.setPin(self.oLo, a, nil)
        self:orderLayout(false)
        self:orderSelect(a, false)
        self:say(ZeD.tr(pin == "first" and "UI_ZeD_Order_SayUnpinnedFirst" or "UI_ZeD_Order_SayUnpinnedLast", O.nameOf(model(), self.oInfo, a)))
        MM.clickSound()
        return
    end
    self:orderSnap()
    self.order[i], self.order[j] = b, a
    self:orderDropBroken(a, { [b] = true })
    self:orderChanged()
    self:orderSelectAt(j, false)
    MM.hoverSound()
end

-- the mod at place i to place j inside its block (top / bottom, a drop); a pinned row dropped
-- outside its block is unpinned first
function ZeD_MMMods:orderMoveTo(i, j)
    local x = self.order[i]
    if not x or x == O.helperId() then self:say(ZeD.tr("UI_ZeD_Order_SayHelperFixed")); return end
    local a, b = self:orderBlockRange(i)
    local pin = nil
    if j < a or j > b then
        pin = self:orderPinHere(x)
        if not pin then self:say(self:orderEdgeWhy(x)); MM.hoverSound(); return end
    end
    self:orderSnap()
    if pin then
        O.setPin(self.oLo, x, nil)
        self:orderLayout(false)
        i = self:orderIndexOf(x)
        a, b = self:orderBlockRange(i)
    end
    j = math.max(a, math.min(b, j))
    if j == i and not pin then table.remove(self.oUndo); return end
    local passed = {}
    local lo_, hi_ = math.min(i, j), math.max(i, j)
    for k = lo_, hi_ do passed[self.order[k]] = true end
    passed[x] = nil
    table.remove(self.order, i)
    table.insert(self.order, j, x)
    if not self:orderDropBroken(x, passed) and pin then
        self:say(ZeD.tr(pin == "first" and "UI_ZeD_Order_SayUnpinnedFirst" or "UI_ZeD_Order_SayUnpinnedLast", O.nameOf(model(), self.oInfo, x)))
    end
    self:orderChanged()
    self:orderSelectAt(j, false)
    MM.clickSound()
end

-- to the top (-1) or the bottom (1) of its block (Move to top / Move to bottom, Ctrl+Home / End)
function ZeD_MMMods:orderToEdge(dir)
    if self.pick or self.page ~= "order" then return end
    local i = self.oSel or 1
    local a, b = self:orderBlockRange(i)
    self:orderMoveTo(i, dir < 0 and a or b)
end

-- Auto: the mods' own rules first, then requirements, pins and your rules
function ZeD_MMMods:autoSort()
    if self.page ~= "order" or self.pick then return end
    local id = self.order[self.oSel or 1]
    self:orderSnap()
    self:orderLayout(true)
    if id then self:orderSelect(id, false) end
    MM.clickSound()
end

-- ----------------------------------------------------------------------------
-- PINS
-- ----------------------------------------------------------------------------
-- which = "first" | "last" | nil (Unpin)
function ZeD_MMMods:orderPin(which)
    local id = self.order[self.oSel or 1]
    if not id or self.page ~= "order" then return end
    if id == O.helperId() then self:say(ZeD.tr("UI_ZeD_Order_SayHelperFixed")); return end
    local was = O.pinOf(self.oLo, id)
    self:orderSnap()
    O.setPin(self.oLo, id, which)
    self:orderLayout(false)
    self:orderSelect(id, false)
    local name = O.nameOf(model(), self.oInfo, id)
    if which == "first" then self:say(ZeD.tr("UI_ZeD_Order_SayPinnedFirst", name))
    elseif which == "last" then self:say(ZeD.tr("UI_ZeD_Order_SayPinnedLast", name))
    elseif was then self:say(ZeD.tr(was == "first" and "UI_ZeD_Order_SayUnpinnedFirst" or "UI_ZeD_Order_SayUnpinnedLast", name)) end
    MM.clickSound()
end

function ZeD_MMMods:orderRemoveRule(r)
    self:orderSnap()
    O.removeRule(self.oLo, r)
    self:orderChanged()
    self:say(ZeD.tr("UI_ZeD_Order_SayRuleRemoved"))
    MM.clickSound()
end

function ZeD_MMMods:orderRemoveRules()
    local id = self.order[self.oSel or 1]
    if not id then return end
    self:orderSnap()
    O.removeRulesOf(self.oLo, id)
    self:orderChanged()
    self:say(ZeD.tr("UI_ZeD_Order_SayRulesRemoved", O.nameOf(model(), self.oInfo, id)))
    MM.clickSound()
end

-- ----------------------------------------------------------------------------
-- THE LIST'S ENTRIES: rows, the blocks' headings, the gaps Find leaves. Made once per change
-- (and per Find text); the frame only walks the ones in sight.
-- ----------------------------------------------------------------------------
local function headText(blk, cnt, pinned, mz, q, helperOn)
    local parts = {}
    if q ~= "" then
        parts[1] = ZeD.tr("UI_ZeD_Order_HeadOf", mz, cnt)
    else
        local pins = pinned
        if pins > 0 then parts[#parts + 1] = ZeD.tr("UI_ZeD_Order_HeadPinned", pins) end
        local carried = cnt - pins - ((blk == 3 and helperOn) and 1 or 0)
        if carried > 0 then parts[#parts + 1] = ZeD.tr("UI_ZeD_Order_HeadCarried", carried) end
        if blk == 3 and helperOn then parts[#parts + 1] = ZeD.tr("UI_ZeD_Order_HeadPicks") end
    end
    return ZeD.upper(ZeD.tr(blk == 1 and "UI_ZeD_Order_HeadFirst" or "UI_ZeD_Order_HeadLast")), "(" .. table.concat(parts, ", ") .. ")"
end

ZeD_MMMods._orderHeadText = headText

--- q: Find's text (lower case); skip: a mod left out (the picker's own); heads: the blocks'
--- headings; pfx: the stops' prefix ("orow:" the page, "lp:" the picker).
function ZeD_MMMods:orderEntries(q, skip, heads, pfx)
    O.stats.views = O.stats.views + 1
    local T = ZeD.T
    local rh, hh, gh = T.px(ROW_H), T.px(HEAD_H), T.px(GAP_H)
    local I, order, zone, carried = self.oInfo or EMPTY, self.order, self.oZone or EMPTY, self.oCarried or EMPTY
    local ents, byPlace = {}, {}
    local y, gap, nMatch = 0, 0, 0
    local function push(e, h) e.y, e.h = y, h; y = y + h; ents[#ents + 1] = e end
    local function flush()
        if gap > 0 then push({ k = "gap", text = ZeD.tr("UI_ZeD_Order_GapMore", gap) }, gh); gap = 0 end
    end
    local cnt, pinned, mz, match = { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, {}
    local helperOn = false
    for i, id in ipairs(order) do
        local z = zone[id] or 2
        local blk = (z == 4) and 3 or z
        if z == 4 then helperOn = true end
        cnt[blk] = cnt[blk] + 1
        if (z == 1 or z == 3) and not carried[id] then pinned[blk] = pinned[blk] + 1 end
        local ok = id ~= skip and (q == "" or ((I[id] and I[id].hay) or string.lower(tostring(id))):find(q, 1, true) ~= nil)
        match[i] = ok
        if ok then mz[blk] = mz[blk] + 1; nMatch = nMatch + 1 end
    end
    local lastBlk = nil
    for i, id in ipairs(order) do
        local z = zone[id] or 2
        local blk = (z == 4) and 3 or z
        if heads and blk ~= lastBlk then
            lastBlk = blk
            if (blk == 1 or blk == 3) and (q == "" or mz[blk] > 0) then
                flush()
                local t1, t2 = headText(blk, cnt[blk], pinned[blk], mz[blk], q, helperOn)
                push({ k = "head", text = t1, sub = t2 }, hh)
            end
        end
        if heads then self:orderSectionHook(ents, i, q, push) end
        if id == skip then
            -- (the picked mod itself is not listed; no gap for it)
        elseif match[i] then
            flush()
            push({ k = "row", i = i, id = id, num = tostring(i), name = (I[id] and I[id].name) or tostring(id),
                   sid = pfx .. i, hid = "mods:" .. pfx .. i }, rh)
            byPlace[i] = #ents
        else
            gap = gap + 1
        end
    end
    flush()
    return { ents = ents, total = y, byPlace = byPlace, nMatch = nMatch }
end

-- the page's own list (kept per change and per Find text)
function ZeD_MMMods:orderView()
    local q = ""
    if self.page == "order" then q = string.lower(tostring(self.find:getInternalText() or "")) end
    local rh = ZeD.T.px(ROW_H)
    local v = self._oView
    if v and v.ver == self.oVer and v.q == q and v.rh == rh and v.order == self.order then return v end
    v = self:orderEntries(q, nil, self.page == "order", "orow:")
    v.ver, v.q, v.rh, v.order = self.oVer, q, rh, self.order
    -- the row tags: pins, carried, rules
    local pinOf, ruled = {}, {}
    for _, p in ipairs(self.oLo and self.oLo.first or EMPTY) do pinOf[p] = "first" end
    for _, p in ipairs(self.oLo and self.oLo.last or EMPTY) do pinOf[p] = "last" end
    for _, r in ipairs(self.oLo and self.oLo.rules or EMPTY) do ruled[r.id] = true end
    v.pinOf, v.ruled = pinOf, ruled
    if q ~= "" then v.countText = ZeD.tr("UI_ZeD_Order_FindCount", v.nMatch, #self.order) end
    self._oView = v
    return v
end

-- the first entry whose bottom is below y (entries are in y order)
local function firstFrom(ents, y)
    local a, b = 1, #ents
    if b == 0 then return 1 end
    while a < b do
        local mid = math.floor((a + b) / 2)
        if ents[mid].y + ents[mid].h <= y then a = mid + 1 else b = mid end
    end
    return a
end

-- a row's stop when it is out of sight (entries k0 .. k1 - 1 are in sight and have theirs)
function ZeD_MMMods:orderOffStop(ents, kk, k0, k1)
    if not kk or kk < 1 or (kk >= k0 and kk < k1) then return end
    local e = ents[kk]
    if not (e and e.k == "row") then return end
    local sp = e.spec
    if not sp then sp = { id = e.sid, listRow = true, row = e.i, col = 1, index = e.i, ry = e.y, rh = e.h }; e.spec = sp end
    self._specs[#self._specs + 1] = sp
end

-- ----------------------------------------------------------------------------
-- FIND (both pages): the label, the field, the count of matches, Clear; a controller stop
-- (D-pad Up from the first row, then A)
-- ----------------------------------------------------------------------------
--- The Find bar for `entry` (the page's own field when nil); modal = drawn under the
--- picker, so no stops or hits are made for it.
function ZeD_MMMods:findBar(x, fY, w, fH, entry, idp, countText, modal)
    local T = ZeD.T
    entry = entry or self.find
    idp = idp or "find"
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local f2, f3, c, d = T.fontF2, T.fontF3, T.text, T.textDim
    local label = ZeD.tr("UI_ZeD_Options_Find")
    self:drawText(label, x + T.px(8), fY + math.floor((fH - MM.fontH(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
    local ex = x + T.px(8) + MM.textW(f2, label) + T.px(8)
    local right = x + w - T.px(8)
    local cache = self._fb
    if not cache then cache = {}; self._fb = cache end
    local sp = cache[idp]
    if not sp then
        sp = {
            -- (row 99990: past the list's rows, so the controller never lands here first)
            field = { id = idp, noDraw = true, row = 99990, col = 1, fn = function() entry:focus() end, help = ZeD.tr("UI_ZeD_Order_HelpFind") },
            clear = { id = idp .. ":clear", text = ZeD.tr("UI_ZeD_Order_Clear"), variant = "default", row = 99990, col = 2,
                      fn = function() entry:setText(""); if entry.onTextChange then entry.onTextChange() end; if entry:isFocused() then entry:unfocus() end end,
                      help = ZeD.tr("UI_ZeD_Order_HelpClear") },
            hit = { id = "mods:" .. idp, fn = function() entry:focus() end },
        }
        cache[idp] = sp
    end
    local has = (entry:getInternalText() or "") ~= ""
    if has then
        local cl = sp.clear
        cl.w, cl.h = ZeD.Molecules.buttonW(cl.text), T.buttonH
        cl.x, cl.y = right - cl.w, fY + math.floor((fH - cl.h) / 2)
        if not modal then self._specs[#self._specs + 1] = cl end
        right = cl.x - T.px(6)
    end
    if countText then
        local cw = MM.textW(f3, countText)
        self:drawText(countText, right - cw, fY + math.floor((fH - MM.fontH(f3)) / 2), d.r, d.g, d.b, d.a or 1, f3)
        right = right - cw - T.px(8)
    end
    local eh = T.px(24)
    UI.styleEntry(entry, ex, fY + math.floor((fH - eh) / 2), math.max(T.px(60), right - ex), eh)
    if modal then return end
    local fs = sp.field
    fs.x, fs.y, fs.w, fs.h = entry.x, entry.y, entry.width, entry.height
    self._specs[#self._specs + 1] = fs
    local hit = sp.hit
    hit.x, hit.y, hit.w, hit.h = ax + entry.x, ay + entry.y, entry.width, entry.height
    self._hits[#self._hits + 1] = hit
    local gp = MM.gamepad()
    if gp and self.focusId == idp then
        ZeD.Focus.mark(self, entry.x - T.px(2), entry.y - T.px(2), entry.width + T.px(4), entry.height + T.px(4), MM.focusOpts())
        ZeD.Help.set(self, fs.help)
    elseif (not gp) and MM.ctx.hot == hit.id then
        ZeD.Help.set(self, fs.help)
    end
end

-- ----------------------------------------------------------------------------
-- DRAWING THE PAGE
-- ----------------------------------------------------------------------------
-- a row's tags at its right: built once per row per change
local function rowTags(self, e, v)
    if e.tags and e.tagsVer == v.ver then return e.tags end
    local T = ZeD.T
    local t = {}
    local id = e.id
    local z = self.oZone[id]
    if id == O.helperId() and self.page == "order" then t[#t + 1] = { ZeD.tr("UI_ZeD_Order_TagKeptByZeD"), T.accent }
    else
        local pin = v.pinOf[id]
        if pin == "first" then t[#t + 1] = { ZeD.tr("UI_ZeD_Order_TagFirst"), T.accent }
        elseif pin == "last" then t[#t + 1] = { ZeD.tr("UI_ZeD_Order_TagLast"), z == 3 and T.accent or T.warning } end
        if self.oCarried[id] then t[#t + 1] = { ZeD.tr("UI_ZeD_Order_TagCarried"), nil } end
        if v.ruled[id] then t[#t + 1] = { ZeD.tr("UI_ZeD_Order_TagRule"), nil } end
    end
    for _, g in ipairs(t) do g[3] = tagW(g[1], g[2] ~= nil) end
    e.tags, e.tagsVer = t, v.ver
    return t
end

-- a red row's reason at its right ("needs Antenna Parts (402)"), once per change
local function rowHint(self, e, v, res)
    if e.hintVer == v.ver then return e.hint end
    e.hintVer, e.hint = v.ver, nil
    if res.st[e.i] ~= "bad" then return nil end
    local I = self.oInfo or EMPTY
    local m = model()
    for _, r in ipairs(I[e.id] and I[e.id].req or EMPTY) do
        local j = res.idx[r]
        if not j then e.hint = ZeD.tr("UI_ZeD_Order_HintNeedsOff", O.nameOf(m, I, r)); break end
        if j > e.i then e.hint = ZeD.tr("UI_ZeD_Order_HintNeedsAt", O.nameOf(m, I, r), j); break end
    end
    return e.hint
end

-- the words the help line gives for a row under the pointer or the focus
local function rowHelp(self, e, v)
    if e.helpVer == v.ver then return e.help end
    local m = model()
    local name = e.name
    if self.page ~= "order" then e.help = ZeD.tr("UI_ZeD_Order_HelpMapRow")
    elseif e.id == O.helperId() then e.help = ZeD.tr("UI_ZeD_Order_SayHelperFixed")
    elseif v.q ~= "" then e.help = ZeD.tr("UI_ZeD_Order_HelpMatch", name, e.i, #self.order)
    elseif self.oCarried[e.id] then e.help = ZeD.tr("UI_ZeD_Order_HelpCarried", O.nameOf(m, self.oInfo, self:orderNeeder(e.id) or e.id))
    else e.help = ZeD.tr("UI_ZeD_Order_HelpRow") end
    e.helpVer = v.ver
    return e.help
end

-- the mod in the same block that needs id (why id is carried)
function ZeD_MMMods:orderNeeder(id)
    local I = self.oInfo or EMPTY
    local z = self.oZone[id]
    for _, x in ipairs(self.order) do
        if x ~= id and self.oZone[x] == z then
            for _, r in ipairs(I[x] and I[x].req or EMPTY) do if r == id then return x end end
        end
    end
    -- (carried down: it needs one of the block's mods)
    for _, r in ipairs(I[id] and I[id].req or EMPTY) do if self.oZone[r] == z then return r end end
    return nil
end

function ZeD_MMMods:drawOrderRow(e, v, res, x, ry, rw, gp, modal)
    local T = ZeD.T
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local isSel = e.i == self.oSel and not self.oSepSel and not self.oHeldSel
    local hot = (not gp) and (not modal) and MM.ctx.hot == e.hid
    local focus = gp and (not modal) and self.focusId == e.sid
    local onFocus = MM.rowLook(self, x, ry, rw, e.h, isSel, hot, focus)
    self:drawRect(x, ry + e.h - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
    local d3 = onFocus and T.textOnFocus or T.textDim
    local numW = self._numW
    self:drawText(e.num, x + T.px(6) + numW - MM.textW(f3, e.num), ry + math.floor((e.h - MM.fontH(f3)) / 2), d3.r, d3.g, d3.b, d3.a or 1, f3)
    local nx = x + T.px(14) + numW
    if self.page == "order" then
        local s = res.st[e.i]
        local col = (s == "bad" and T.danger) or (s == "soft" and T.warning) or T.positive
        local dsz = T.px(7)
        ZeD.Atoms.drawStatusDot(self, nx, ry + math.floor((e.h - dsz) / 2), col, dsz)
        nx = nx + dsz + T.px(8)
    end
    local tr = x + rw - T.px(8)
    if self.page == "order" then
        for _, g in ipairs(rowTags(self, e, v)) do
            tr = tr - g[3]
            local b = T.base
            self:drawRect(tr, ry + math.floor((e.h - T.px(16)) / 2), g[3], T.px(16), 1, b.r, b.g, b.b)
            ZeD.Molecules.drawTag(self, tr, ry + math.floor((e.h - T.px(16)) / 2), g[1], g[2], { font = f1 })
            tr = tr - T.px(6)
        end
        local hint = rowHint(self, e, v, res)
        if hint then
            local hw = math.min(MM.textW(f3, hint), math.floor((tr - nx) * 0.5))
            if e.hintW ~= hw then e.hintW, e.hintT = hw, ZeD.Atoms.truncateText(hint, f3, hw) end
            tr = tr - hw
            self:drawText(e.hintT, tr, ry + math.floor((e.h - MM.fontH(f3)) / 2), d3.r, d3.g, d3.b, d3.a or 1, f3)
            tr = tr - T.px(8)
        end
    end
    local maxW = tr - nx
    if e.tnw ~= maxW then e.tnw, e.tn = maxW, ZeD.Atoms.truncateText(e.name, f2, maxW) end
    local c = onFocus and T.textOnFocus or T.textHead
    self:drawText(e.tn, nx, ry + math.floor((e.h - MM.fontH(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
    if hot or focus then ZeD.Help.set(self, rowHelp(self, e, v)) end
end

-- a click picks the row; a second one soon after shows a match in the full list (Find)
function ZeD_MMMods:clickOrderRow(i)
    local t = MM.now()
    if self.oSel == i and self._oClick and t - self._oClick < DOUBLE_MS then
        self._oClick = nil
        local v = self._oView
        if v and v.q ~= "" then self:orderShowInFull(i) end
        return
    end
    self._oClick = t
    if self.oSel ~= i then MM.hoverSound() end
    self.oSel = i
    self.focusId = "orow:" .. i
end

-- Find's "where does it sit": Find cleared, the full list, the mod in the middle
function ZeD_MMMods:orderShowInFull(i)
    local id = self.order[i or self.oSel or 1]
    self.find:setText("")
    if self.find:isFocused() then self.find:unfocus() end
    MM.clickSound()
    if id then self:orderSelect(id, true) end
end

-- the row hit: a press starts a drag (not while Find has text)
local function rowHit(self, e)
    local h = e.hit
    if h then return h end
    local i = e.i
    h = { id = e.hid, fn = function() self:clickOrderRow(i) end }
    h.drag = function(mx, my)
        local d = self._drag
        if not d then
            if self.pick or (self._oView and self._oView.q ~= "") then return end
            local id = self.order[i]
            if self.page == "order" and id == O.helperId() then return end
            self._drag = { from = i, y0 = my, my = my, on = false }
            return
        end
        d.my = my
        if not d.on and math.abs(my - d.y0) > ZeD.T.px(DRAG_PX) then d.on = true end
    end
    e.hit = h
    return h
end

-- the place a drag would drop at (the row under the pointer)
function ZeD_MMMods:orderDropAt(my)
    local L = self._list
    local v = self._oView
    if not (L and v) then return nil end
    local yy = my - self:getAbsoluteY() - L.y + self.scroll
    local ents = v.ents
    local k = firstFrom(ents, yy)
    local e = ents[k]
    while e and e.k ~= "row" do k = k + 1; e = ents[k] end
    if not e then e = ents[#ents]; while e and e.k ~= "row" do k = k - 1; e = ents[k] end end
    return e
end

-- the drag, every frame while it runs: the list follows near its edges; the release drops
function ZeD_MMMods:orderDragStep()
    local d = self._drag
    if not d then return end
    local L = self._list
    if not ZeD.MouseTick.down() then
        self._drag = nil
        if d.on then
            local e = self:orderDropAt(d.my)
            if e and e.i ~= d.from then
                if self.page == "order" then self:orderMoveTo(d.from, e.i)
                else
                    local x = table.remove(self.order, d.from)
                    table.insert(self.order, e.i, x)
                    self:orderChanged()
                    self:orderSelectAt(e.i, false)
                end
            end
        end
        return
    end
    if d.on and L then
        local T = ZeD.T
        local my = getMouseY() - self:getAbsoluteY()
        d.my = getMouseY()
        if my < L.y + T.px(20) then self.scroll = math.max(0, self.scroll - T.px(12))
        elseif my > L.y + L.h - T.px(20) then self.scroll = self.scroll + T.px(12) end
    end
end

function ZeD_MMMods:drawOrderHead(e, x, ry, rw)
    local T = ZeD.T
    local f1, f3 = T.fontF1, T.fontF3
    local la, d = T.accent, T.textDim
    local ty = ry + math.floor((e.h - MM.fontH(f1)) / 2)
    self:drawText(e.text, x + T.px(10), ty, la.r, la.g, la.b, la.a or 1, f1)
    local sx = x + T.px(10) + MM.textW(f1, e.text) + T.px(8)
    self:drawText(e.sub, sx, ry + math.floor((e.h - MM.fontH(f3)) / 2), d.r, d.g, d.b, d.a or 1, f3)
    local lx = sx + MM.textW(f3, e.sub) + T.px(8)
    if lx < x + rw - T.px(10) then
        local bc = T.border
        self:drawRect(lx, ry + math.floor(e.h / 2), x + rw - T.px(10) - lx, T.px(1), bc.a, bc.r, bc.g, bc.b)
    end
    self:drawRect(x, ry + e.h - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
end

function ZeD_MMMods:drawOrderGap(e, x, ry, rw)
    local T = ZeD.T
    local f1, d = T.fontF1, T.textDim
    local s2 = T.surf2
    self:drawRect(x, ry, rw, e.h, 1, s2.r, s2.g, s2.b)
    self:drawText(e.text, x + T.px(44), ry + math.floor((e.h - MM.fontH(f1)) / 2), d.r, d.g, d.b, d.a or 1, f1)
    self:drawRect(x, ry + e.h - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
end

--- The load / map order page: Find, the list, the picked mod's pane (and the picker over the list).
function ZeD_MMMods:drawOrder(x, y, w, h)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local gp = MM.gamepad()
    local isOrder = self.page == "order"
    local modal = self.pick ~= nil
    local listW = math.floor(w * LIST_SHARE)
    UI.insetBox(self, x, y, listW, h)
    local top = y + T.px(1)
    local v = self:orderView()
    if isOrder then
        local fH = T.px(FIND_H)
        ZeD.Surface.fill(self, x + T.px(1), top, listW - 2 * T.px(1), fH - T.px(1), "surf2")
        ZeD.Atoms.drawDividerH(self, x, top + fH - T.px(1), listW, true)
        self:findBar(x, top, listW, fH, self.find, "find", v.countText, modal)
        self.find:setVisible(true)
        top = top + fH
    else
        self.find:setVisible(false)
    end
    -- (with folders: the line saying this is the load order, not the collection: ZeD_MainMenuModsFolders)
    if self.listLine and isOrder then top = self:listLine(x, top, listW, "order") end
    local vy, vh = top, y + h - T.px(1) - top
    local res = self:orderCheck()
    local total = v.total
    self.scroll = math.max(0, math.min(self.scroll, math.max(0, total - vh)))
    local L = self._oListT
    if not L then L = {}; self._oListT = L end
    L.x, L.y, L.w, L.h = x, vy, listW, vh
    self._list = L
    local over = total > vh
    local sbW = T.sp.scrollbarW
    local rx, rw = x + T.px(1), listW - 2 * T.px(1) - (over and sbW or 0)
    self._numW = MM.textW(T.fontF3, "0000")
    local ents = v.ents
    if #ents == 0 then
        local msg = (v.q ~= "") and ZeD.tr("UI_ZeD_Order_NoMatch", tostring(self.find:getInternalText() or "")) or ZeD.tr("UI_ZeD_Mods_EmptyNone")
        ZeD.Molecules.drawEmptyLine(self, x + T.px(12), vy + T.px(8), listW - T.px(24), msg)
    end
    self:setStencilRect(x + T.px(1), vy, listW - 2 * T.px(1), vh)
    local k0 = firstFrom(ents, self.scroll)
    -- stops: the row before the ones in sight, the rows in sight, the one after, the chosen one
    local kSel = v.byPlace[self.oSel or 1]
    local kPrev = k0 - 1
    while kPrev >= 1 and ents[kPrev].k ~= "row" do kPrev = kPrev - 1 end
    local k = k0
    local lastRow = nil
    while k <= #ents do
        local e = ents[k]
        local ry = vy + e.y - self.scroll
        if ry >= vy + vh then
            -- (the row after the ones in sight is a stop too)
            local kk = k
            while kk <= #ents and ents[kk].k ~= "row" do kk = kk + 1 end
            lastRow = kk <= #ents and kk or nil
            break
        end
        if e.k == "row" then
            self:drawOrderRow(e, v, res, rx, ry, rw, gp, modal)
            if not modal then
                local sp = e.spec
                if not sp then sp = { id = e.sid, listRow = true, row = e.i, col = 1, index = e.i, ry = e.y, rh = e.h }; e.spec = sp end
                self._specs[#self._specs + 1] = sp
                local hit = rowHit(self, e)
                local cy0 = math.max(ry, vy)
                hit.x, hit.y, hit.w, hit.h = ax + x, ay + cy0, rw, math.min(ry + e.h, vy + vh) - cy0
                self._hits[#self._hits + 1] = hit
            end
        elseif e.k == "head" then self:drawOrderHead(e, rx, ry, rw)
        elseif e.k == "sep" then self:drawSepRow(e, rx, ry, rw, vy, vh, gp, modal)
        elseif e.k == "held" then self:drawHeldRow(e, rx, ry, rw, vy, vh, gp, modal)
        else self:drawOrderGap(e, rx, ry, rw) end
        k = k + 1
    end
    if not modal then
        self:orderOffStop(ents, kPrev, k0, k)
        self:orderOffStop(ents, lastRow, k0, k)
        if kSel ~= kPrev and kSel ~= lastRow then self:orderOffStop(ents, kSel, k0, k) end
        if self.sepOffStops then self:sepOffStops(v, k0, k) end
    end
    -- the drag's drop line
    local d = self._drag
    if d and d.on then
        local e = self:orderDropAt(d.my)
        if e then
            local ly = vy + e.y - self.scroll + ((e.i > d.from) and e.h or 0) - T.px(1)
            local ac = T.accent
            self:drawRect(rx, ly, rw, T.px(2), 1, ac.r, ac.g, ac.b)
        end
    end
    self:clearStencilRect()
    if over then self:orderScrollBar(x + listW - T.px(1) - sbW, vy, sbW, vh, total) end
    self:orderDragStep()
    -- the picked mod's pane
    local px0, pw0 = x + listW + T.px(12), w - listW - T.px(12)
    self:drawOrderDetail(px0, y, pw0, h, modal)
    if modal then self:drawLoadPicker(x, vy, listW, vh) end
end

function ZeD_MMMods:orderScrollBar(sx, vy, sbW, vh, total)
    MM.scrollBar(self, "mods:otrack", sx, vy, sbW, vh, self.scroll, total, function(v) self.scroll = v end, { step = ZeD.T.px(ROW_H), noHit = self.pick and true or nil })
end

-- ----------------------------------------------------------------------------
-- THE PICKED MOD'S PANE: where it loads, its own rules, your rules,
-- the pins; its buttons. Worked out once per change and per pick, drawn each frame.
-- ----------------------------------------------------------------------------
-- a button spec of the pane (kept with the pane's model)
local function paneBtn(id, text, fn, disabled, help)
    return { id = id, text = text, fn = fn, variant = "default", disabled = disabled, help = help }
end

-- the pane's lines: { t = "title" | "sub" | "head" | "text" | "btns" | "rule", ... }
function ZeD_MMMods:orderDetailModel(rw)
    local T = ZeD.T
    local q = self._oView and self._oView.q or ""
    local c = self._oDetail
    if c and c.ver == self.oVer and c.sel == self.oSel and c.rw == rw and c.q == q and c.scale == T.scale and c.page == self.page then return c end
    c = { ver = self.oVer, sel = self.oSel, rw = rw, q = q, scale = T.scale, page = self.page, items = {} }
    self._oDetail = c
    if self.page == "order" then self:orderDetailItems(c.items, rw, q ~= "") else self:mapDetailItems(c.items, rw) end
    return c
end

local function addText(items, rw, s, dot, dim)
    local T = ZeD.T
    items[#items + 1] = { t = "text", dot = dot, dim = dim, lines = ZeD.Atoms.wrapText(s, T.fontF2, rw - (dot and T.px(14) or 0)) }
end

function ZeD_MMMods:mapDetailItems(items, rw)
    local m = model()
    local sel = self.order[self.oSel or 1]
    items[#items + 1] = { t = "title", text = tostring(sel or "") }
    items[#items + 1] = { t = "btns", list = {
        paneBtn("up", ZeD.tr("UI_ServerSettings_ButtonMoveUp"), function() self:move(-1) end, (self.oSel or 1) <= 1),
        paneBtn("down", ZeD.tr("UI_ServerSettings_ButtonMoveDown"), function() self:move(1) end, (self.oSel or 1) >= #self.order) } }
    local conf = {}
    pcall(function() conf = jlist(m:getMapConflicts(sel)) end)
    if #conf > 0 then addText(items, rw, ZeD.tr("UI_ZeD_Mods_MapShares", table.concat(conf, ", "))) end
    addText(items, rw, ZeD.tr("UI_ZeD_Mods_MapRule"))
end

local WISH = {
    { kept = "UI_ZeD_Order_DetWishAfterKept", pin = "UI_ZeD_Order_DetWishAfterPin", rule = "UI_ZeD_Order_DetWishAfterRule", no = "UI_ZeD_Order_DetWishAfterNot" },
    { kept = "UI_ZeD_Order_DetWishBeforeKept", pin = "UI_ZeD_Order_DetWishBeforePin", rule = "UI_ZeD_Order_DetWishBeforeRule", no = "UI_ZeD_Order_DetWishBeforeNot" },
}
local RULE = {
    after = { kept = "UI_ZeD_Order_DetRuleAfterKept", no = "UI_ZeD_Order_DetRuleAfterNot", off = "UI_ZeD_Order_DetRuleAfterOff", missing = "UI_ZeD_Order_DetRuleAfterMissing" },
    before = { kept = "UI_ZeD_Order_DetRuleBeforeKept", no = "UI_ZeD_Order_DetRuleBeforeNot", off = "UI_ZeD_Order_DetRuleBeforeOff", missing = "UI_ZeD_Order_DetRuleBeforeMissing" },
}

-- the mod's own rules, each with what became of it
function ZeD_MMMods:ownRuleItems(items, rw, id, i, res)
    local T = ZeD.T
    local m = model()
    local I = self.oInfo or EMPTY
    local e = I[id] or { req = EMPTY, after = EMPTY, before = EMPTY }
    local pair = O.pairKeys(self.oLo)
    items[#items + 1] = { t = "head", text = ZeD.tr("UI_ZeD_Order_DetOwnRules") }
    local n = 0
    for _, r in ipairs(e.req) do
        local j = res.idx[r]
        local nm = O.nameOf(m, I, r)
        n = n + 1
        if not j then addText(items, rw, ZeD.tr("UI_ZeD_Order_DetNeedsOff", nm), T.danger)
        elseif j > i then addText(items, rw, ZeD.tr("UI_ZeD_Order_DetNeedsLater", nm, j), T.danger)
        elseif self.oCarried[r] and self.oZone[r] == 1 and self.oZone[id] == 1 then addText(items, rw, ZeD.tr("UI_ZeD_Order_DetNeedsCarried", nm), T.positive)
        else addText(items, rw, ZeD.tr("UI_ZeD_Order_DetNeedsKept", nm, j), T.positive) end
    end
    for pass = 1, 2 do
        local list = (pass == 1) and e.after or e.before
        for _, w in ipairs(list) do
            local j = res.idx[w]
            if j then
                n = n + 1
                local nm = O.nameOf(m, I, w)
                local kept = (pass == 1 and j < i) or (pass == 2 and j > i)
                local K = WISH[pass]
                if kept then addText(items, rw, ZeD.tr(K.kept, nm, j), T.positive)
                else
                    local why = O.overridden(pair, self.oZone, id, w)
                    if why == "pin" then addText(items, rw, ZeD.tr(K.pin, nm), T.textDim)
                    elseif why == "rule" then addText(items, rw, ZeD.tr(K.rule, nm), T.textDim)
                    else addText(items, rw, ZeD.tr(K.no, nm, j), T.warning) end
                end
            end
        end
    end
    if n == 0 then addText(items, rw, ZeD.tr("UI_ZeD_Order_DetOwnNone"), T.positive) end
end

-- your rules on the mod, each with Remove
function ZeD_MMMods:yourRuleItems(items, rw, id, res)
    local T = ZeD.T
    local m = model()
    local mine = O.rulesOf(self.oLo, id)
    items[#items + 1] = { t = "head", text = ZeD.tr("UI_ZeD_Order_DetYourRules"), note = "(" .. #mine .. ")" }
    if #mine == 0 then addText(items, rw, ZeD.tr("UI_ZeD_Order_DetRulesNone"), nil, true); return end
    for n, x in ipairs(mine) do
        local r = x.r
        local nm = O.nameOf(m, self.oInfo, r.other)
        local K = RULE[r.how] or RULE.after
        local text, dot, dim
        local d = m and m.mods and m.mods[r.other]
        if not d then text, dot, dim = ZeD.tr(K.missing, r.other), T.textDim, true
        elseif not res.idx[r.other] then text, dot, dim = ZeD.tr(K.off, nm), T.textDim, true
        elseif O.ruleKept(res.idx, r) then text, dot = ZeD.tr(K.kept, nm, res.idx[r.other]), T.positive
        else text, dot = ZeD.tr(K.no, nm, res.idx[r.other]), T.warning end
        local btn = paneBtn("orule:" .. n, ZeD.tr("UI_ZeD_Order_BtnRemove"), function() self:orderRemoveRule(r) end, false, ZeD.tr("UI_ZeD_Order_HelpRemove"))
        local bw = ZeD.Molecules.buttonW(btn.text)
        items[#items + 1] = { t = "rule", dot = dot, dim = dim, btn = btn,
                              lines = ZeD.Atoms.wrapText(text, T.fontF2, rw - T.px(14) - bw - T.px(8)) }
    end
end

-- the pin's own words in the pane: pinned, kept by ZeD, or carried, and why
function ZeD_MMMods:pinItems(items, rw, id)
    local T = ZeD.T
    local m = model()
    local pin = O.pinOf(self.oLo, id)
    local z = self.oZone[id]
    if id == O.helperId() then
        items[#items + 1] = { t = "head", text = ZeD.tr("UI_ZeD_Order_TagKeptByZeD") }
        addText(items, rw, ZeD.tr("UI_ZeD_Order_DetHelper"))
    elseif pin == "first" then
        items[#items + 1] = { t = "head", text = ZeD.tr("UI_ZeD_Order_DetPinnedFirst") }
        addText(items, rw, ZeD.tr("UI_ZeD_Order_DetPinnedFirstText"))
    elseif pin == "last" and z == 3 then
        items[#items + 1] = { t = "head", text = ZeD.tr("UI_ZeD_Order_DetPinnedLast") }
        addText(items, rw, ZeD.tr("UI_ZeD_Order_DetPinnedLastText"))
    elseif pin == "last" then
        items[#items + 1] = { t = "head", text = ZeD.tr("UI_ZeD_Order_DetPinnedLast") }
        addText(items, rw, ZeD.tr("UI_ZeD_Order_DetPinNotKept", O.nameOf(m, self.oInfo, self:orderNeeder(id) or id)), T.warning)
    elseif self.oCarried[id] then
        items[#items + 1] = { t = "head", text = ZeD.tr("UI_ZeD_Order_TagCarried") }
        local key = (z == 1) and "UI_ZeD_Order_DetCarriedFirst" or "UI_ZeD_Order_DetCarriedLast"
        addText(items, rw, ZeD.tr(key, O.nameOf(m, self.oInfo, self:orderNeeder(id) or id)))
    end
end

function ZeD_MMMods:orderDetailItems(items, rw, finding)
    local T = ZeD.T
    local i = self.oSel or 1
    local id = self.order[i]
    if not id then return end
    local res = self:orderCheck()
    local helper = id == O.helperId()
    local pin = O.pinOf(self.oLo, id)
    items[#items + 1] = { t = "title", text = O.nameOf(model(), self.oInfo, id) }
    local where = ZeD.tr("UI_ZeD_Order_DetLoadsAt", i, #self.order)
    if helper then where = where .. " | " .. ZeD.tr("UI_ZeD_Order_TagKeptByZeD")
    elseif pin then where = where .. " | " .. ZeD.tr(pin == "first" and "UI_ZeD_Order_DetPinnedFirstLow" or "UI_ZeD_Order_DetPinnedLastLow")
    elseif self.oCarried[id] then where = where .. " | " .. ZeD.tr("UI_ZeD_Order_DetCarriedLow") end
    items[#items + 1] = { t = "sub", text = where }
    if not helper then
        local row1 = {}
        if finding then row1[#row1 + 1] = paneBtn("ofull", ZeD.tr("UI_ZeD_Order_BtnShowFull"), function() self:orderShowInFull(i) end, false, ZeD.tr("UI_ZeD_Order_HelpShowFull")) end
        row1[#row1 + 1] = paneBtn("oafter", ZeD.tr("UI_ZeD_Order_LoadAfter"), function() self:openPicker("after") end, false, ZeD.tr("UI_ZeD_Order_HelpLoadAfter"))
        row1[#row1 + 1] = paneBtn("obefore", ZeD.tr("UI_ZeD_Order_LoadBefore"), function() self:openPicker("before") end, false, ZeD.tr("UI_ZeD_Order_HelpLoadBefore"))
        items[#items + 1] = { t = "btns", list = row1 }
        local row2 = {
            paneBtn("up", ZeD.tr("UI_ServerSettings_ButtonMoveUp"), function() self:move(-1) end, i <= 1),
            paneBtn("down", ZeD.tr("UI_ServerSettings_ButtonMoveDown"), function() self:move(1) end, i >= #self.order or self.order[i + 1] == O.helperId()) }
        if pin == "first" then row2[#row2 + 1] = paneBtn("ounpin", ZeD.tr("UI_ZeD_Order_Unpin"), function() self:orderPin(nil) end, false, ZeD.tr("UI_ZeD_Order_HelpUnpin"))
        else row2[#row2 + 1] = paneBtn("ofirst", ZeD.tr("UI_ZeD_Order_LoadFirst"), function() self:orderPin("first") end, false, ZeD.tr("UI_ZeD_Order_HelpLoadFirst")) end
        if pin == "last" then row2[#row2 + 1] = paneBtn("ounpin2", ZeD.tr("UI_ZeD_Order_Unpin"), function() self:orderPin(nil) end, false, ZeD.tr("UI_ZeD_Order_HelpUnpin"))
        else row2[#row2 + 1] = paneBtn("olast", ZeD.tr("UI_ZeD_Order_LoadLast"), function() self:orderPin("last") end, false, ZeD.tr("UI_ZeD_Order_HelpLoadLast")) end
        items[#items + 1] = { t = "btns", list = row2 }
    end
    self:pinItems(items, rw, id)
    self:ownRuleItems(items, rw, id, i, res)
    if not helper then self:yourRuleItems(items, rw, id, res) end
    if res.firstBad then addText(items, rw, ZeD.tr("UI_ZeD_Mods_RuleFix"), T.danger) end
    items[#items + 1] = { t = "head", text = ZeD.tr("UI_ZeD_Order_DetKept") }
    addText(items, rw, ZeD.tr("UI_ZeD_Order_DetKeptText"), nil, true)
end

function ZeD_MMMods:drawOrderDetail(px0, y, pw0, h, modal)
    local T = ZeD.T
    ZeD.Atoms.frame(self, px0, y, pw0, h, T.borderS)
    local rx = px0 + T.px(DETAIL_PAD)
    local rw = pw0 - T.px(DETAIL_PAD) * 2
    local bottom = y + h - T.px(DETAIL_PAD)
    local cy = y + T.px(DETAIL_PAD)
    local f1, f2 = T.fontF1, T.fontF2
    local lh = MM.fontH(f2) + T.px(3)
    local bh = T.buttonH
    local rowN = 500
    for _, it in ipairs(self:orderDetailModel(rw).items) do
        if cy > bottom then break end
        if it.t == "title" then
            local hf = ZeD.Font.sdf.head
            local z = 20 * (T.scale or 1) / (hf.face or 64)
            local tc = T.textHead
            if it.tw ~= rw then it.tw, it.tt = rw, ZeD.Atoms.truncateText(it.text, T.fontF4, rw) end
            ZeD.Text.draw(self, hf, it.tt, rx, cy, z, tc.r, tc.g, tc.b, tc.a or 1, "l")
            cy = cy + math.floor(ZeD.Text.height(hf, z)) + T.px(2)
        elseif it.t == "sub" then
            local d = T.textDim
            self:drawText(it.text, rx, cy, d.r, d.g, d.b, d.a or 1, f2)
            cy = cy + lh + T.px(6)
        elseif it.t == "head" then
            cy = cy + T.px(6)
            local la = T.accent
            self:drawText(it.text, rx, cy, la.r, la.g, la.b, la.a or 1, f1)
            if it.note then
                local d = T.textDim
                self:drawText(it.note, rx + MM.textW(f1, it.text) + T.px(6), cy, d.r, d.g, d.b, d.a or 1, T.fontF3)
            end
            cy = cy + MM.fontH(f1) + T.px(3)
            local bc = T.border
            self:drawRect(rx, cy, rw, T.px(1), bc.a, bc.r, bc.g, bc.b)
            cy = cy + T.px(6)
        elseif it.t == "labels" then
            -- a separator's label swatches (ZeD_MainMenuModsFolders: labelSwatches)
            rowN = rowN + 1
            local uid = it.uid
            cy = self:labelSwatches(rx, cy + T.px(2), it.sp.label, function(k) self:sepSetLabel(uid, k) end, rowN, y, bottom - y, "slabel", modal) + T.px(8)
        elseif it.t == "btns" then
            local bx = rx
            rowN = rowN + 1
            for ci, b in ipairs(it.list) do
                local bw = ZeD.Molecules.buttonW(b.text)
                if bx + bw > rx + rw and bx > rx then bx = rx; cy = cy + bh + T.px(6); rowN = rowN + 1 end
                b.x, b.y, b.w, b.h, b.row, b.col = bx, cy, bw, bh, rowN, ci
                if not modal and cy + bh <= bottom then self._specs[#self._specs + 1] = b end
                bx = bx + bw + T.px(6)
            end
            cy = cy + bh + T.px(8)
        else
            local tx = rx + (it.dot and T.px(14) or 0)
            local c = it.dim and T.textDim or T.text
            local ly = cy
            if it.dot then
                local dsz = T.px(7)
                ZeD.Atoms.drawStatusDot(self, rx, cy + math.floor((MM.fontH(f2) - dsz) / 2), it.dot, dsz)
            end
            for _, l in ipairs(it.lines) do
                self:drawText(l, tx, ly, c.r, c.g, c.b, c.a or 1, f2)
                ly = ly + lh
            end
            if it.t == "rule" then
                rowN = rowN + 1
                local b = it.btn
                b.w, b.h = ZeD.Molecules.buttonW(b.text), bh
                b.x, b.y, b.row, b.col = rx + rw - b.w, cy, rowN, 1
                if not modal and cy + bh <= bottom then self._specs[#self._specs + 1] = b end
                ly = math.max(ly, cy + bh + T.px(4))
            end
            cy = ly + T.px(2)
        end
    end
end

-- ----------------------------------------------------------------------------
-- THE ROW'S MENU: A on a row, Shift+F10 or the menu key, right-click
-- ----------------------------------------------------------------------------
function ZeD_MMMods:orderMenu(anchor)
    if self.page ~= "order" or self.pick then return end
    local i = self.oSel or 1
    local id = self.order[i]
    if not id then return end
    if id == O.helperId() then self:say(ZeD.tr("UI_ZeD_Order_SayHelperFixed")); MM.hoverSound(); return end
    local pin = O.pinOf(self.oLo, id)
    local items = { { text = O.nameOf(model(), self.oInfo, id), disabled = true }, "-" }
    if self._oView and self._oView.q ~= "" then
        items[#items + 1] = { text = ZeD.tr("UI_ZeD_Order_BtnShowFull"), fn = function() self:orderShowInFull(i) end }
        items[#items + 1] = "-"
    end
    if pin == "first" then items[#items + 1] = { text = ZeD.tr("UI_ZeD_Order_Unpin"), fn = function() self:orderPin(nil) end }
    else items[#items + 1] = { text = ZeD.tr("UI_ZeD_Order_LoadFirst"), fn = function() self:orderPin("first") end } end
    if pin == "last" then items[#items + 1] = { text = ZeD.tr("UI_ZeD_Order_Unpin"), fn = function() self:orderPin(nil) end }
    else items[#items + 1] = { text = ZeD.tr("UI_ZeD_Order_LoadLast"), fn = function() self:orderPin("last") end } end
    items[#items + 1] = { text = ZeD.tr("UI_ZeD_Order_LoadAfter"), fn = function() self:openPicker("after") end }
    items[#items + 1] = { text = ZeD.tr("UI_ZeD_Order_LoadBefore"), fn = function() self:openPicker("before") end }
    items[#items + 1] = "-"
    items[#items + 1] = { text = ZeD.tr("UI_ZeD_Order_MoveTop"), fn = function() self:orderToEdge(-1) end }
    items[#items + 1] = { text = ZeD.tr("UI_ZeD_Order_MoveBottom"), fn = function() self:orderToEdge(1) end }
    if #O.rulesOf(self.oLo, id) > 0 then
        items[#items + 1] = "-"
        items[#items + 1] = { text = ZeD.tr("UI_ZeD_Order_RemoveRules"), fn = function() self:orderRemoveRules() end }
    end
    -- (separators: Move to separator..., New separator...: ZeD_MainMenuModsSeps)
    if self.sepRowItems then self:sepRowItems(items, id) end
    if not anchor then
        -- (at the row: from the controller or the keyboard)
        local T = ZeD.T
        local L, v = self._list, self:orderView()
        local k = v.byPlace[i]
        local e = k and v.ents[k]
        local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
        if L and e then anchor = { x = ax + L.x + T.px(60), y = ay + L.y + e.y - self.scroll, w = T.px(10), h = e.h }
        else anchor = { x = ax + T.px(60), y = ay + T.px(60), w = T.px(10), h = T.px(10) } end
    end
    MM.openPopup("orderRow", items, anchor, false)
end

-- a right-click on a row (the glass passes it on): picks the row and opens its menu there
function ZeD_MMMods:rightClick(mx, my)
    if self.page ~= "order" or self.pick or self.confirm then return false end
    local L = self._list
    local lx, ly = mx - self:getAbsoluteX(), my - self:getAbsoluteY()
    if not (L and lx >= L.x and lx <= L.x + L.w and ly >= L.y and ly <= L.y + L.h) then return false end
    local e = self:orderDropAt(my)
    if not e then return false end
    self.oSel = e.i
    self.focusId = e.sid
    self:orderMenu({ x = mx, y = my, w = 1, h = 1 })
    return true
end

-- ----------------------------------------------------------------------------
-- THE LOAD AFTER... / LOAD BEFORE... PICKER
-- ----------------------------------------------------------------------------
function ZeD_MMMods:openPicker(how)
    if self.page ~= "order" then return end
    local id = self.order[self.oSel or 1]
    if not id then return end
    if id == O.helperId() then self:say(ZeD.tr("UI_ZeD_Order_SayHelperFixed")); return end
    MM.ctx.open = nil
    local I = self.oInfo
    local name = O.nameOf(model(), I, id)
    local P = { id = id, how = how, sel = nil, scroll = 0, why = {}, back = self.focusId, name = name,
                title = ZeD.tr(how == "after" and "UI_ZeD_Order_PickTitleAfter" or "UI_ZeD_Order_PickTitleBefore", name),
                band = ZeD.tr(how == "after" and "UI_ZeD_Order_PickBandAfter" or "UI_ZeD_Order_PickBandBefore", name) }
    -- worked out once: what must load after it (it is needed) and before it (it needs), and the
    -- circles your other rules would close (a rule on the same pair is replaced, so it does not count)
    P.reqAfter = O.reach(I, nil, id, false, true)
    P.reqBefore = O.reach(I, nil, id, true, true)
    local others, mine = { rules = {} }, {}
    for _, r in ipairs(self.oLo.rules) do
        if r.id == id or r.other == id then mine[#mine + 1] = r else others.rules[#others.rules + 1] = r end
    end
    local back = how == "before"
    P.circle = O.reach(I, others, id, back, false)
    P.via = {}
    for _, r in ipairs(mine) do
        local p = (r.id == id) and r.other or r.id
        local pAfter = (r.id == id and r.how == "before") or (r.other == id and r.how == "after")
        if pAfter ~= back then
            local s = O.reach(I, others, p, back, false)
            s[p] = true
            P.via[#P.via + 1] = { p = p, s = s }
        end
    end
    self.pick = P
    self.pfind:setText("")
    self.pfind:setVisible(true)
    if MM.gamepad() then P.wantFirst = true else self.pfind:focus() end
    MM.clickSound()
end

function ZeD_MMMods:closePicker(quiet)
    local P = self.pick
    if not P then return end
    self.pick = nil
    if self.pfind:isFocused() then self.pfind:unfocus() end
    self.pfind:setVisible(false)
    -- (the controller goes back to the row it came from)
    self.focusId = P.back or ("orow:" .. (self.oSel or 1))
    if not quiet then MM.clickSound() end
end

-- why the picker greys a mod (nil: it can be chosen), and its short word at the row's right
function ZeD_MMMods:pickWhy(y)
    local P = self.pick
    if not P then return nil end
    local c = P.why[y]
    if c ~= nil then return c and c[1] or nil, c and c[2] or nil end
    local m = model()
    local I = self.oInfo
    local x = P.id
    local nx, ny = P.name, O.nameOf(m, I, y)
    local zx, zy = self.oZone[x] or 2, self.oZone[y] or 2
    local circ = P.circle[y]
    if not circ then for _, v in ipairs(P.via) do if v.p ~= y and v.s[y] then circ = true; break end end end
    local why, short
    if P.how == "after" then
        if y == O.helperId() then why, short = ZeD.tr("UI_ZeD_Order_SayHelperFixed"), ZeD.tr("UI_ZeD_Order_ShortLast")
        elseif P.reqAfter[y] then why, short = ZeD.tr("UI_ZeD_Order_WhyNeedsIt", ny, nx), ZeD.tr("UI_ZeD_Order_ShortNeedsIt")
        elseif circ then why, short = ZeD.tr("UI_ZeD_Order_WhyCircleAfter", ny, nx), ZeD.tr("UI_ZeD_Order_ShortCircle")
        elseif zy > zx and zy == 3 then why, short = ZeD.tr("UI_ZeD_Order_WhyBlockLast", nx), ZeD.tr("UI_ZeD_Order_ShortPinned") end
    else
        if P.reqBefore[y] then why, short = ZeD.tr("UI_ZeD_Order_WhyItNeeds", ny), ZeD.tr("UI_ZeD_Order_ShortNeeded")
        elseif circ then why, short = ZeD.tr("UI_ZeD_Order_WhyCircleBefore", ny, nx), ZeD.tr("UI_ZeD_Order_ShortCircle")
        elseif zy < zx and zy == 1 then why, short = ZeD.tr("UI_ZeD_Order_WhyBlockFirst", nx), ZeD.tr("UI_ZeD_Order_ShortPinned") end
    end
    P.why[y] = why and { why, short } or false
    return why, short
end

-- picks a mod in the picker (a greyed one says why instead)
function ZeD_MMMods:pickChoose(y, confirm)
    local P = self.pick
    if not P then return end
    local why = self:pickWhy(y)
    if why then self:say(why); MM.hoverSound(); return end
    if P.sel ~= y then MM.hoverSound() end
    P.sel = y
    P.explain = nil
    if confirm then self:pickerConfirm(); return end
    -- (the controller lands on the primary: Load after)
    if MM.gamepad() then self.focusId = "lp:ok" end
end

-- Load after / Load before: the rule kept, the mod moved now
function ZeD_MMMods:pickerConfirm()
    local P = self.pick
    if not (P and P.sel) then return end
    local x, y, how = P.id, P.sel, P.how
    self:orderSnap()
    O.addRule(self.oLo, x, how, y)
    local zx, zy = self.oZone[x] or 2, self.oZone[y] or 2
    if zx == zy then
        O.place(self.order, self.oInfo, x, how, y)
    else
        -- (the other mod is in another block: this one goes to the nearest place of its own block)
        local i = self:orderIndexOf(x)
        local a, b = self:orderBlockRange(i)
        if how == "after" and zy < zx and a ~= i then O.place(self.order, self.oInfo, x, "before", self.order[a])
        elseif how == "before" and zy > zx and b ~= i then O.place(self.order, self.oInfo, x, "after", self.order[b]) end
    end
    self:orderChanged()
    local m = model()
    local nx, ny = O.nameOf(m, self.oInfo, x), O.nameOf(m, self.oInfo, y)
    self:closePicker(true)
    self:orderSelect(x, false)
    self:say(ZeD.tr(how == "after" and "UI_ZeD_Order_SayRuleAfter" or "UI_ZeD_Order_SayRuleBefore", nx, ny))
    MM.clickSound()
end

-- the picker's list (kept per Find text and change)
function ZeD_MMMods:pickView()
    local P = self.pick
    local q = string.lower(tostring(self.pfind:getInternalText() or ""))
    local rh = ZeD.T.px(ROW_H)
    local v = P.view
    if v and v.q == q and v.ver == self.oVer and v.rh == rh then return v end
    v = self:orderEntries(q, P.id, true, "lp:")
    v.q, v.ver, v.rh = q, self.oVer, rh
    v.countText = (q ~= "") and ZeD.tr("UI_ZeD_Order_FindCount", v.nMatch, #self.order - 1) or nil
    P.view = v
    return v
end

-- the picker's row hit and stop, made once per row
local function pickRowParts(self, e)
    if e.pspec then return e.pspec, e.hit end
    local id = e.id
    -- (listRow: the picker draws its rows itself; without it the window drew each stop as a
    -- button with no text, "nil", over the names and below the list)
    local sp = { id = e.sid, lpRow = true, listRow = true, listId = "lpick", row = e.i, col = 1, ry = e.y, rh = e.h, clip = {},
                 fn = function() self:pickChoose(id, false) end }
    local hit = { id = e.hid }
    hit.fn = function()
        local t = MM.now()
        local P = self.pick
        if P and P.sel == id and self._pClick and t - self._pClick < DOUBLE_MS then self._pClick = nil; self:pickChoose(id, true); return end
        self._pClick = t
        self.focusId = e.sid
        self:pickChoose(id, false)
    end
    e.pspec, e.hit = sp, hit
    return sp, hit
end

function ZeD_MMMods:drawLoadPicker(x, y, w, h)
    local T = ZeD.T
    local P = self.pick
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local gp = MM.gamepad()
    local px, pw = x + T.px(16), w - T.px(32)
    local py, ph = y + T.px(12), h - T.px(24)
    -- the list under the picker is covered edge to edge (its rows showed in the margin above the title)
    local bs = T.base
    self:drawRect(x + T.px(1), y, w - 2 * T.px(1), h, 1, bs.r, bs.g, bs.b)
    ZeD.Atoms.drawHardShadow(self, px, py, pw, ph)
    local s1, s2 = T.surf1, T.surf2
    self:drawRect(px, py, pw, ph, 1, s1.r, s1.g, s1.b)
    ZeD.Atoms.frame(self, px, py, pw, ph, T.borderS)
    local tH = T.px(TITLE_H)
    self:drawRect(px + T.px(1), py + T.px(1), pw - T.px(2), tH, 1, s2.r, s2.g, s2.b)
    local tc = T.textHead
    if P.ttw ~= pw then P.ttw, P.tt = pw, ZeD.Atoms.truncateText(P.title, T.fontF2, pw - T.px(20)) end
    self:drawText(P.tt, px + T.px(10), py + math.floor((tH - MM.fontH(T.fontF2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
    local v = self:pickView()
    local fY = py + tH + T.px(4)
    local fH = T.px(FIND_H)
    self:findBar(px, fY, pw, fH, self.pfind, "lpfind", v.countText, false)
    -- the foot: what Load after does, then Cancel and Load after
    local bh = T.buttonH
    local footY = py + ph - T.px(8) - bh
    local textW0 = pw - T.px(20)
    if not P.explain or P.explainW ~= textW0 then
        local s
        if P.sel then
            local m = model()
            s = ZeD.tr(P.how == "after" and "UI_ZeD_Order_PickExplainAfter" or "UI_ZeD_Order_PickExplainBefore", P.name, O.nameOf(m, self.oInfo, P.sel))
        else
            s = ZeD.tr(P.how == "after" and "UI_ZeD_Order_PickNoneAfter" or "UI_ZeD_Order_PickNoneBefore", P.name)
        end
        P.explain, P.explainW = ZeD.Atoms.wrapText(s, T.fontF2, textW0), textW0
    end
    local lh = MM.fontH(T.fontF2) + T.px(2)
    local ty = footY - T.px(8) - #P.explain * lh
    local c = T.text
    for n, l in ipairs(P.explain) do self:drawText(l, px + T.px(10), ty + (n - 1) * lh, c.r, c.g, c.b, c.a or 1, T.fontF2) end
    local btns = P.btns
    if not btns then
        btns = {
            cancel = { id = "lp:cancel", text = getText("UI_btn_cancel"), variant = "default", fn = function() self:closePicker(false) end, row = 900, col = 1 },
            ok = { id = "lp:ok", text = ZeD.tr(P.how == "after" and "UI_ZeD_Order_BtnLoadAfter" or "UI_ZeD_Order_BtnLoadBefore"), variant = "primary",
                   fn = function() self:pickerConfirm() end, row = 900, col = 2 },
        }
        P.btns = btns
    end
    local ok, cancel = btns.ok, btns.cancel
    ok.w, ok.h = ZeD.Molecules.buttonW(ok.text), bh
    cancel.w, cancel.h = ZeD.Molecules.buttonW(cancel.text), bh
    ok.x, ok.y = px + pw - T.px(10) - ok.w, footY
    cancel.x, cancel.y = px + T.px(10), footY
    ok.disabled = P.sel == nil
    self._specs[#self._specs + 1] = cancel
    self._specs[#self._specs + 1] = ok
    -- the list
    local lx, ly = px + T.px(10), fY + fH + T.px(4)
    local lw, lhh = pw - T.px(20), ty - T.px(8) - (fY + fH + T.px(4))
    UI.insetBox(self, lx, ly, lw, lhh, true)
    self:drawPickRows(v, lx, ly, lw, lhh, gp, ax, ay)
end

function ZeD_MMMods:drawPickRows(v, lx, ly, lw, lhh, gp, ax, ay)
    local T = ZeD.T
    local P = self.pick
    local vy, vh = ly + T.px(1), lhh - T.px(2)
    P.vh = vh
    local box = P.box
    if not box then box = {}; P.box = box end
    box.x, box.y, box.w, box.h = lx, vy, lw, vh
    P.scroll = math.max(0, math.min(P.scroll, math.max(0, v.total - vh)))
    local ents = v.ents
    local rx, rw = lx + T.px(1), lw - T.px(2)
    local f2, f3 = T.fontF2, T.fontF3
    local numW = self._numW or MM.textW(f3, "0000")
    if #ents == 0 then
        ZeD.Molecules.drawEmptyLine(self, lx + T.px(10), vy + T.px(8), lw - T.px(20), ZeD.tr("UI_ZeD_Order_NoMatch", tostring(self.pfind:getInternalText() or "")))
    end
    self:setStencilRect(rx, vy, rw, vh)
    local k = firstFrom(ents, P.scroll)
    if k > 1 then k = k - 1 end
    while k <= #ents do
        local e = ents[k]
        local ry = vy + e.y - P.scroll
        if ry >= vy + vh + T.px(ROW_H) then break end
        if e.k == "row" then
            local sp, hit = pickRowParts(self, e)
            sp.x, sp.y, sp.w, sp.h = rx, ry, rw, e.h
            sp.clip.y, sp.clip.h = vy, vh
            self._specs[#self._specs + 1] = sp
            if P.wantFirst and ry >= vy then P.wantFirst = nil; self.focusId = sp.id end
            local why, short = self:pickWhy(e.id)
            if ry + e.h > vy and ry < vy + vh then
                local hot = (not gp) and MM.ctx.hot == e.hid
                local focus = gp and self.focusId == e.sid
                local onFocus = MM.rowLook(self, rx, ry, rw, e.h, P.sel == e.id, hot, focus)
                self:drawRect(rx, ry + e.h - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
                local a = why and T.disabledAlpha or 1
                local d3 = onFocus and T.textOnFocus or T.textDim
                self:drawText(e.num, rx + T.px(6) + numW - MM.textW(f3, e.num), ry + math.floor((e.h - MM.fontH(f3)) / 2), d3.r, d3.g, d3.b, (d3.a or 1) * a, f3)
                local nx = rx + T.px(14) + numW
                local tr = rx + rw - T.px(8)
                if short then
                    local sw = MM.textW(f3, short)
                    tr = tr - sw
                    self:drawText(short, tr, ry + math.floor((e.h - MM.fontH(f3)) / 2), d3.r, d3.g, d3.b, d3.a or 1, f3)
                    tr = tr - T.px(8)
                end
                local maxW = tr - nx
                if e.tnw ~= maxW then e.tnw, e.tn = maxW, ZeD.Atoms.truncateText(e.name, f2, maxW) end
                local c = onFocus and T.textOnFocus or T.textHead
                self:drawText(e.tn, nx, ry + math.floor((e.h - MM.fontH(f2)) / 2), c.r, c.g, c.b, (c.a or 1) * a, f2)
                local cy0 = math.max(ry, vy)
                hit.x, hit.y, hit.w, hit.h = ax + rx, ay + cy0, rw, math.min(ry + e.h, vy + vh) - cy0
                self._hits[#self._hits + 1] = hit
                if (hot or focus) and why then ZeD.Help.set(self, why) end
            end
        elseif ry + e.h > vy and ry < vy + vh then
            if e.k == "head" then self:drawOrderHead(e, rx, ry, rw) else self:drawOrderGap(e, rx, ry, rw) end
        end
        k = k + 1
    end
    self:clearStencilRect()
end

-- ----------------------------------------------------------------------------
-- THE BAND: Back; Undo while there is one; Auto; Done (greyed while a row is red)
-- ----------------------------------------------------------------------------
function ZeD_MMMods:orderStrip(stripY, w, row)
    local T = ZeD.T
    local isOrder = self.page == "order"
    if self.pick then
        UI.stripSpecs(self, stripY, w, row, {}, {}, self.pick.band, true, T.accent)
        return
    end
    local res = self:orderCheck()
    local status, color = nil, nil
    if self.note and MM.now() < self.note.untilMs then
        status, color = self.note.text, T.accent
    elseif isOrder and res.nBad > 0 then
        local v = self:orderView()
        local rc = self._redTxt
        if not (rc and rc.ver == v.ver and rc.q == v.q) then
            local shown = 0
            if v.q ~= "" then for _, e in ipairs(v.ents) do if e.k == "row" and res.st[e.i] == "bad" then shown = shown + 1 end end end
            local text = ZeD.tr(res.nBad == 1 and "UI_ZeD_Order_RedOne" or "UI_ZeD_Order_RedMany", res.nBad)
            if v.q ~= "" and shown < res.nBad then text = ZeD.tr("UI_ZeD_Order_RedHidden", text) end
            rc = { ver = v.ver, q = v.q, text = text }
            self._redTxt = rc
        end
        status, color = rc.text, T.danger
    end
    local rights = {}
    if self.oUndo and #self.oUndo > 0 then
        rights[#rights + 1] = { "undo", ZeD.tr("UI_ZeD_Order_BtnUndo"), function() self:orderUndo() end, "default", false, ZeD.tr("UI_ZeD_Order_HelpUndo") }
    end
    -- (separators: New separator..., Start separators from folders, Move it up)
    if isOrder and self.sepStrip then status, color = self:sepStrip(rights, res, status, color) end
    rights[#rights + 1] = { "auto", ZeD.tr("UI_ZeD_Mods_BtnAuto"), function() self:autoSort() end, "default", not isOrder, ZeD.tr("UI_ZeD_Order_HelpAuto") }
    rights[#rights + 1] = { "done", getText("UI_mods_Done"), function() self:orderDone() end, "primary", isOrder and res.firstBad ~= nil }
    UI.stripSpecs(self, stripY, w, row, { { "back", getText("UI_btn_back"), function() self:leaveOrder(false) end } }, rights, status, true, color)
end

-- ----------------------------------------------------------------------------
-- CONTROLLER AND KEYS. The pad rules here as everywhere: the focus returns where it
-- was, lands on the primary, and the common actions are cheapest.
-- ----------------------------------------------------------------------------
--- A: on a row, its menu (with Find: the match in the full list); true = handled.
function ZeD_MMMods:orderJoyA()
    local f = self.focusId or ""
    if f:sub(1, 5) ~= "orow:" or self.pick then return false end
    if self.page ~= "order" then return true end     -- (map order: a row only picks; X / Y move it)
    local v = self._oView
    if v and v.q ~= "" then self:orderShowInFull(self.oSel) else self:orderMenu(nil) end
    return true
end

function ZeD_MMMods:orderJoyB()
    if not self.pick then return false end
    if self.pfind:isFocused() then self.pfind:unfocus() else self:closePicker(false) end
    return true
end

function ZeD_MMMods:orderEscape()
    if self.pick then self:closePicker(false); return true end
    if (self.find:getInternalText() or "") ~= "" then
        self.find:setText("")
        self.scroll = 0
        local id = self.order[self.oSel or 1]
        if id then self:orderSelect(id, true) end
        return true
    end
    return false
end

--- A page of rows up (-1) or down (1): LB / RB, Page Up / Page Down. Heading, gap and
--- separator entries are skipped: only mod rows count toward the page.
function ZeD_MMMods:orderPage(dir)
    local P = self.pick
    local v = P and self:pickView() or self:orderView()
    local L = P and P.box or self._list
    local per = math.max(1, math.floor(((L and L.h) or ZeD.T.px(320)) / ZeD.T.px(ROW_H)) - 1)
    local ents = v.ents
    local f = self.focusId or ""
    local k = nil
    for kk, e in ipairs(ents) do if e.k == "row" and e.sid == f then k = kk; break end end
    if not k then k = P and 1 or (v.byPlace[self.oSel or 1] or 1) end
    local n, last = 0, nil
    while k >= 1 and k <= #ents and n < per do
        k = k + dir
        local e = ents[k]
        if e and e.k == "row" then n = n + 1; last = e end
    end
    if not last then return end
    MM.hoverSound()
    if P then
        self.focusId = last.sid
        if last.y < P.scroll then P.scroll = last.y elseif last.y + last.h > P.scroll + (P.vh or 0) then P.scroll = last.y + last.h - (P.vh or 0) end
    else
        self:orderSelectAt(last.i, false)
    end
end

--- Keys (true = handled): Ctrl+F Find, Ctrl+Up / Down move, Ctrl+Home / End to the block's ends,
--- Page Up / Down, Ctrl+Z Undo, Shift+F10 or the menu key the row's menu, Return Done (or with
--- Find, the match in the full list).
function ZeD_MMMods:orderKey(key)
    local K = Keyboard
    local ctrl, shift = isCtrlKeyDown(), isShiftKeyDown()
    if self.pick then
        if self.pfind:isFocused() then return false end
        if key == K.KEY_RETURN then
            local f = self.focusId or ""
            local P = self.pick
            if f:sub(1, 3) == "lp:" and f ~= "lp:ok" and f ~= "lp:cancel" then
                for _, e in ipairs(P.view and P.view.ents or EMPTY) do
                    if e.sid == f and e.id ~= P.sel then self:pickChoose(e.id, false); return true end
                end
            end
            if P.sel then self:pickerConfirm() end
            return true
        end
        if ctrl and key == K.KEY_F then self.pfind:focus(); return true end
        if key == K.KEY_PRIOR or key == K.KEY_NEXT then self:orderPage(key == K.KEY_PRIOR and -1 or 1); return true end
        if key == K.KEY_UP or key == K.KEY_DOWN then
            if (self.focusId or ""):sub(1, 3) ~= "lp:" then
                local v = self:pickView()
                for _, e in ipairs(v.ents) do if e.k == "row" then self.focusId = e.sid; return true end end
            end
            self:joyDir(key == K.KEY_UP and "up" or "down")
            return true
        end
        return false
    end
    if ctrl and key == K.KEY_F and self.page == "order" then self.find:focus(); return true end
    if ctrl and key == K.KEY_Z then self:orderUndo(); return true end
    if ctrl and (key == K.KEY_UP or key == K.KEY_DOWN) then self:move(key == K.KEY_UP and -1 or 1); return true end
    if ctrl and K.KEY_HOME and key == K.KEY_HOME then self:orderToEdge(-1); return true end
    if ctrl and K.KEY_END and key == K.KEY_END then self:orderToEdge(1); return true end
    if key == K.KEY_PRIOR or key == K.KEY_NEXT then self:orderPage(key == K.KEY_PRIOR and -1 or 1); return true end
    if (K.KEY_APPS and key == K.KEY_APPS) or (shift and key == K.KEY_F10) then self:orderMenu(nil); return true end
    if key == K.KEY_RETURN then
        local v = self._oView
        if self.page == "order" and v and v.q ~= "" then self:orderShowInFull(self.oSel) else self:orderDone() end
        return true
    end
    return false
end

--- The footer's controller prompts on these pages.
function ZeD_MMMods:orderPrompts(f, sel, back)
    if self.pick then
        if f:sub(1, 3) == "lp:" and f ~= "lp:ok" and f ~= "lp:cancel" then
            return { { glyph = "A", label = ZeD.tr("UI_ZeD_Order_PromptPick") }, { glyph = "LB", label = "" }, { glyph = "RB", label = ZeD.tr("UI_ZeD_Order_PromptPage") }, { glyph = "B", label = getText("UI_Cancel") } }
        end
        return { { glyph = "A", label = sel }, { glyph = "B", label = getText("UI_Cancel") } }
    end
    if f:sub(1, 5) == "orow:" then
        local t = {}
        if self.page == "order" then
            local v = self._oView
            t[#t + 1] = { glyph = "A", label = ZeD.tr((v and v.q ~= "") and "UI_ZeD_Order_PromptShow" or "UI_ZeD_Order_PromptMenu") }
        end
        t[#t + 1] = { glyph = "Y", label = ZeD.tr("UI_ServerSettings_ButtonMoveUp") }
        t[#t + 1] = { glyph = "X", label = ZeD.tr("UI_ServerSettings_ButtonMoveDown") }
        t[#t + 1] = { glyph = "LB", label = "" }
        t[#t + 1] = { glyph = "RB", label = ZeD.tr("UI_ZeD_Order_PromptPage") }
        t[#t + 1] = { glyph = "B", label = back }
        return t
    end
    return { { glyph = "A", label = sel }, { glyph = "B", label = back } }
end
