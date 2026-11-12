-- ZeD-UI/42/media/lua/client/ZeD/TabFind.lua
-- ============================================================================
-- TAB FIND — client; the Find field in the heading of the Character window's
-- Skills and Equipment tabs, and the matching behind it.
-- Skills matches a skill's name, its group's name (a group that matches keeps
-- all its skills) and the Training materials rows. Equipment matches a worn
-- item's name, its slot's words and the body parts it covers. Rows that don't
-- match are dimmed in place, never hidden, so nothing moves under the pointer;
-- the controller's hand skips them.
-- Each tab keeps its own text on the window (win._find): it stays while the
-- window is open, across tab switches, and goes with the window when it closes.
-- One thing to know: matches are worked out once per text (and again when the
-- tab's data refreshes) and kept; the tabs only look them up while they draw.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.TabFind = ZeD.TabFind or {}
local F = ZeD.TabFind

local FIELD_W   = 200   -- the field's width at its widest (design units)
local FIELD_MIN = 64    -- narrower than this and the heading has no field
local DIM_A     = 0.65  -- a row that doesn't match: the window's base over it at this much

F.TABS = { "skills", "equip" }

-- ============================================================================
-- MATCHING (no drawing; ZeDUI/tools/qa/tab_search_sim.lua runs these as they are)
-- ============================================================================

-- Lower-cased words, kept: the same few hundred names come back every refresh
local _low, _lowN = {}, 0
local function low(s)
    if s == nil then return "" end
    local r = _low[s]
    if r then return r end
    r = string.lower(tostring(s))
    if _lowN > 4000 then _low, _lowN = {}, 0 end
    _low[s] = r
    _lowN = _lowN + 1
    return r
end
F.low = low

--- The typed text as it is matched: lower case, spaces trimmed off both ends; "" for none.
function F.norm(text)
    if text == nil or text == "" then return "" end
    local q = low(text)
    q = (string.gsub(q, "^%s+", ""))
    q = (string.gsub(q, "%s+$", ""))
    return q
end

--- Where q (already F.norm'ed, not empty) sits in s: its first and last place, or nil.
--- A plain find, so the typed text is never read as a pattern.
function F.find(s, q)
    if s == nil or q == nil or q == "" then return nil end
    return string.find(low(s), q, 1, true)
end

--- The Skills tab's matches for q over the tab's groups (each { name, skills = { { name } } })
--- and the Training materials rows (each { label, disp }). Returns
---   { q, total, shown, skill = { [name] = true }, group = { [group name] = skills kept },
---     groupHit = { [group name] = true }, train = { [label] = true } }
function F.matchSkills(cats, training, q)
    local r = { q = q, total = 0, shown = 0, skill = {}, group = {}, groupHit = {}, train = {} }
    for _, g in ipairs(cats or {}) do
        local gHit = F.find(g.name, q) ~= nil
        if gHit then r.groupHit[g.name] = true end
        local n = 0
        for _, s in ipairs(g.skills or {}) do
            r.total = r.total + 1
            -- a group whose name matches keeps every skill in it
            if gHit or F.find(s.name, q) then
                r.skill[s.name] = true
                n = n + 1
            end
        end
        r.group[g.name] = n
        r.shown = r.shown + n
    end
    -- a training row is a skill's books: kept by the skill's own name, or with the skill
    for _, t in ipairs(training or {}) do
        local disp = t.disp or t.label
        if F.find(disp, q) or r.skill[disp] then r.train[t.label] = true end
    end
    return r
end

--- One worn thing against q: "name" (its name holds the text), "slot" (one of the slot's
--- words does), or "covers" with the body parts it covers that hold the text; nil for none.
--- words: a string or a list of strings; parts: the body parts' names in the game's words.
function F.matchItem(name, words, parts, q)
    if F.find(name, q) then return "name" end
    if type(words) == "string" then
        if F.find(words, q) then return "slot" end
    elseif words then
        for _, w in ipairs(words) do
            if F.find(w, q) then return "slot" end
        end
    end
    local hits = nil
    for _, p in ipairs(parts or {}) do
        if F.find(p, q) then
            hits = hits or {}
            hits[#hits + 1] = p
        end
    end
    if hits then return "covers", hits end
    return nil
end

--- The Equipment list's matches for q over its groups (EquipmentTab.gatherData's: each
--- { id, slots = { { type, item } } }). wordsOf(slot) gives the slot's words, infoOf(item)
--- { name, parts }. Returns { q, worn, shown, hit = { [slot type] = "name" | "slot" | "covers" },
--- covers = { [slot type] = { part, ... } }, group = { [group id] = rows kept } }
function F.matchEquip(groups, q, wordsOf, infoOf)
    local r = { q = q, worn = 0, shown = 0, hit = {}, covers = {}, group = {} }
    for _, g in ipairs(groups or {}) do
        local n = 0
        for _, s in ipairs(g.slots or {}) do
            if s.item then
                r.worn = r.worn + 1
                local inf = infoOf(s.item)
                local why, parts = F.matchItem(inf.name, wordsOf(s), inf.parts, q)
                if why then
                    r.hit[s.type] = why
                    if parts then r.covers[s.type] = parts end
                    n = n + 1
                    r.shown = r.shown + 1
                end
            end
        end
        r.group[g.id] = n
    end
    return r
end

--- The Doll view's matches for q: boxes = { { key = "doll:torso", words = "Torso",
--- items = { item, ... } } } (every layer of a slot counts). Returns { q, worn, shown,
--- hit = { [key] = why } }; a box with nothing in it never matches.
function F.matchBoxes(boxes, q, infoOf)
    local r = { q = q, worn = 0, shown = 0, hit = {}, covers = {}, group = {} }
    for _, b in ipairs(boxes or {}) do
        local items = b.items or {}
        if items[1] then
            r.worn = r.worn + 1
            local why = nil
            for _, it in ipairs(items) do
                local inf = infoOf(it)
                why = F.matchItem(inf.name, b.words, inf.parts, q)
                if why then break end
            end
            if why then
                r.hit[b.key] = why
                r.shown = r.shown + 1
            end
        end
    end
    return r
end

-- ============================================================================
-- WHAT A WORN ITEM IS CALLED AND COVERS (kept per item)
-- ============================================================================
local _info, _infoN = {}, 0
local function infoOf(item)
    local inf = _info[item]
    if inf then return inf end
    inf = { name = "", parts = {} }
    local ok, nm = pcall(function() return item:getDisplayName() end)
    if ok and nm then inf.name = nm end
    -- the body parts in the game's own words (BloodBodyPartType's display names, as the
    -- game's garment window lists them); a held tool covers nothing
    local okp, cp = pcall(function() return item:getCoveredParts() end)
    if okp and cp then
        for i = 0, cp:size() - 1 do
            local okn, pn = pcall(function() return cp:get(i):getDisplayName() end)
            if okn and pn and pn ~= "" then inf.parts[#inf.parts + 1] = pn end
        end
    end
    if _infoN > 256 then _info, _infoN = {}, 0 end
    _info[item] = inf
    _infoN = _infoN + 1
    return inf
end
F.infoOf = infoOf

-- ============================================================================
-- PER WINDOW: the text, the kept matches
-- ============================================================================

--- The text typed on a tab of the window ("" when none).
function F.text(win, tab)
    local t = win and win._find
    return t and t[tab] or ""
end

--- Sets a tab's text (the field's own keystrokes come here, and the sims).
function F.setText(win, tab, text)
    win._find = win._find or {}
    win._find[tab] = text or ""
end

local function query(win, tab)
    local q = F.norm(F.text(win, tab))
    if q == "" then return nil end
    return q
end

local function wordsOfSlot(s)
    local ET = ZeD.EquipmentTab
    return ET and ET.wordsOf(s) or ""
end

--- The Skills tab's matches (F.matchSkills) for its data, or nil when nothing is typed.
function F.skills(win, data, training)
    local q = query(win, "skills")
    if not q then win._findSkills = nil; return nil end
    local c = win._findSkills
    if not (c and c.q == q and c.data == data and c.training == training) then
        c = { q = q, data = data, training = training,
              res = F.matchSkills(data and data.categories, training, q) }
        win._findSkills = c
    end
    win._findCount = win._findCount or {}
    win._findCount.skills = c.res
    return c.res
end

--- The Equipment list's matches (F.matchEquip), or nil when nothing is typed.
function F.equip(win, data)
    local q = query(win, "equip")
    if not q then win._findEquip = nil; return nil end
    local c = win._findEquip
    if not (c and c.q == q and c.data == data and c.view == "list") then
        c = { q = q, data = data, view = "list",
              res = F.matchEquip(data and data.groups, q, wordsOfSlot, infoOf) }
        win._findEquip = c
    end
    win._findCount = win._findCount or {}
    win._findCount.equip = c.res
    return c.res
end

-- the doll's boxes as F.matchBoxes takes them, from EquipDoll.gather's data
local function dollBoxes(data)
    local D = ZeD.EquipDoll
    local out = {}
    if not (data and D) then return out end
    for _, def in ipairs(D.SLOTS or {}) do
        local s = data.slots and data.slots[def.id]
        if s then out[#out + 1] = { key = "doll:" .. def.id, words = ZeD.tr(def.key), items = s.items } end
    end
    for _, sm in ipairs(D.SMALL or {}) do
        local s = data.small and data.small[sm.id]
        if s then out[#out + 1] = { key = "doll:" .. sm.id, words = ZeD.tr(sm.place), items = s.items } end
    end
    out[#out + 1] = { key = "doll:main", words = ZeD.tr("UI_ZeD_Doll_Main"), items = { data.main } }
    out[#out + 1] = { key = "doll:off", words = ZeD.tr("UI_ZeD_Doll_Off"), items = { data.off } }
    for _, bs in ipairs(data.belt or {}) do
        if bs.item then
            out[#out + 1] = { key = "doll:belt" .. tostring(bs.i),
                              words = ZeD.tr("UI_ZeD_Doll_BeltSlot", tostring(bs.key or bs.i)), items = { bs.item } }
        end
    end
    return out
end

--- The Doll view's matches (F.matchBoxes) for the doll's data, or nil when nothing is typed.
function F.doll(win, data)
    local q = query(win, "equip")
    if not q then win._findEquip = nil; return nil end
    local c = win._findEquip
    if not (c and c.q == q and c.data == data and c.view == "doll") then
        c = { q = q, data = data, view = "doll", res = F.matchBoxes(dollBoxes(data), q, infoOf) }
        win._findEquip = c
    end
    win._findCount = win._findCount or {}
    win._findCount.equip = c.res
    return c.res
end

--- True when a skill row is dimmed (something typed, the skill not kept).
function F.skillOff(win, name)
    local c = win and win._findSkills
    return c ~= nil and not c.res.skill[name]
end

--- True when a Training materials row (by its skill id) is dimmed.
function F.trainOff(win, label)
    local c = win and win._findSkills
    return c ~= nil and not c.res.train[label]
end

--- True when an Equipment stop (a list slot's type, a doll box's key, a belt row's id) is dimmed.
function F.equipOff(win, key)
    local c = win and win._findEquip
    return c ~= nil and not c.res.hit[key]
end

--- True when a list group's heading is dimmed (nothing in it matches).
function F.equipGroupOff(win, id)
    local c = win and win._findEquip
    return c ~= nil and c.view == "list" and (c.res.group[id] or 0) == 0
end

--- True while something is typed on the tab.
function F.active(win, tab) return query(win, tab) ~= nil end

-- ============================================================================
-- DRAWING HELPERS (the tabs call these as they draw)
-- ============================================================================

--- A row that doesn't match: the window's base over it, so it reads dimmed in place.
function F.dim(panel, x, y, w, h)
    local b = ZeD.T.base
    panel:drawRect(x, y, w, h, DIM_A, b.r, b.g, b.b)
end

--- A 1u accent line under the part of text (drawn at x, y in font) that holds q; kept
--- left of maxX. Draws nothing when the drawn text doesn't hold it (a name cut short).
function F.underline(panel, text, font, x, y, q, maxX)
    local s, e = F.find(text, q)
    if not s then return end
    local T, tm = ZeD.T, ZeD.TM
    local ux = x + tm:MeasureStringX(font, string.sub(text, 1, s - 1))
    local uw = tm:MeasureStringX(font, string.sub(text, s, e))
    if maxX and ux + uw > maxX then uw = maxX - ux end
    if uw <= 0 then return end
    local ac = T.accent
    panel:drawRect(ux, y + tm:getFontHeight(font), uw, T.px(1), 1, ac.r, ac.g, ac.b)
end

--- Where a tab heading's title ends (ZeD.Molecules.drawTabHeader's own layout).
function F.titleRight(x, title)
    local T, tm = ZeD.T, ZeD.TM
    local font = T.fontF4
    local discSz = math.max(T.px(8), math.floor(tm:getFontHeight(font) * 0.5))
    return x + T.px(8) + discSz + T.px(6) + tm:MeasureStringX(font, ZeD.Atoms.textCase(title))
end

local HINT_KEY = { skills = "UI_ZeD_Find_SkillsHint", equip = "UI_ZeD_Find_EquipHint" }
local HELP_KEY = { skills = "UI_ZeD_Find_HelpSkills", equip = "UI_ZeD_Find_HelpEquip" }
local NONE_KEY = { skills = "UI_ZeD_Find_SkillsNone", equip = "UI_ZeD_Find_EquipNone" }
local LOOKS_KEY = { skills = "UI_ZeD_Find_SkillsLooks", equip = "UI_ZeD_Find_EquipLooks" }

local function help(win, text)
    if ZeD.Help and ZeD.Help.set then ZeD.Help.set(win, text) end
end

--- The field's place on the tab (drawer coordinates), or nil when the heading has no room.
function F.rect(win, tab)
    local r = win and win._findRect
    return r and r[tab] or nil
end

--- The Find part of a tab's heading: the field's place at the right (ending at right),
--- the count left of it ("3 of 35") while something is typed. focus = the controller's
--- mark options when the field has the focus. Returns where the heading's own stop should
--- end (the count's or the field's left edge, less a gap); right when there is no field.
function F.drawHead(panel, win, tab, x, y, headerH, titleRight, right, focus)
    local T, tm = ZeD.T, ZeD.TM
    local gap = T.px(8)
    local rects = win._findRect or {}
    win._findRect = rects
    local fw = math.min(T.px(FIELD_W), right - titleRight - gap)
    if fw < T.px(FIELD_MIN) then
        rects[tab] = nil
        return right
    end
    local fh = T.inputH
    local fx = right - fw
    local fy = y + math.floor((headerH - fh) / 2)
    local r = rects[tab] or {}
    rects[tab] = r
    r.x, r.y, r.w, r.h, r.drawn = fx, fy, fw, fh, true
    local left = fx
    local res = F.active(win, tab) and win._findCount and win._findCount[tab]
    if res then
        local s = ZeD.tr("UI_ZeD_Find_Count", res.shown, tab == "skills" and res.total or res.worn)
        local font = T.fontF1
        local cw = tm:MeasureStringX(font, s)
        local cx = fx - gap - cw
        if cx >= titleRight + gap then
            local c = res.shown > 0 and T.accent or T.textDim
            panel:drawText(s, cx, y + math.floor((headerH - tm:getFontHeight(font)) / 2), c.r, c.g, c.b, c.a or 1, font)
            left = cx
        end
    end
    -- the controller's mark: its wash sits under the field (the field draws its own accent
    -- frame); the hand is drawn on top of everything in the window's overlay pass
    if focus and ZeD.Focus and ZeD.Focus.mark then ZeD.Focus.mark(panel, fx, fy, fw, fh, focus) end
    local f = win._findFields and win._findFields[tab]
    if f then f._padFocus = focus ~= nil end
    if ZeD.Atoms.mouseIn(panel, fx, fy, fw, fh) then
        help(win, ZeD.tr((f and f._overClear) and "UI_ZeD_Find_HelpClear" or HELP_KEY[tab]))
    end
    return left - gap
end

--- True when the pointer is over the tab's field (the heading's hover wash stays off it).
function F.overField(win, tab, panel)
    local r = F.rect(win, tab)
    if not r then return false end
    local mx, my = panel:getMouseX(), panel:getMouseY()
    return mx >= r.x - ZeD.T.px(8) and mx < r.x + r.w and my >= r.y and my < r.y + r.h
end

-- the empty result's lines, wrapped to w
local function emptyLines(win, tab, w)
    local T, A = ZeD.T, ZeD.Atoms
    local main = A.wrapText(ZeD.tr(NONE_KEY[tab], F.text(win, tab)), T.fontF2, w) or {}
    local sub = A.wrapText(ZeD.tr(LOOKS_KEY[tab]), T.fontF1, w) or {}
    return main, sub
end

--- The empty result's height in a tab w wide (its lines, then the Clear key).
function F.emptyH(win, tab, w)
    local T, tm = ZeD.T, ZeD.TM
    local pad = T.px(10)
    local main, sub = emptyLines(win, tab, w - pad * 2)
    return pad + #main * tm:getFontHeight(T.fontF2) + T.px(2) + #sub * tm:getFontHeight(T.fontF1)
        + T.px(10) + T.buttonH + pad
end

--- Draws the empty result at (x, y), w wide: what was asked for, what the field looks at,
--- and Clear as the default key. focus = the Clear key's mark options. Returns its height.
--- Stamps the key's place (win._findClearBtn[tab]) for the mouse and the controller.
function F.drawEmpty(panel, win, tab, x, y, w, focus)
    local T, tm = ZeD.T, ZeD.TM
    local pad = T.px(10)
    local main, sub = emptyLines(win, tab, w - pad * 2)
    local cy = y + pad
    local tc, dc = T.text, T.textDim
    local h2, h1 = tm:getFontHeight(T.fontF2), tm:getFontHeight(T.fontF1)
    for _, ln in ipairs(main) do
        panel:drawText(ln, x + pad, cy, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        cy = cy + h2
    end
    cy = cy + T.px(2)
    for _, ln in ipairs(sub) do
        panel:drawText(ln, x + pad, cy, dc.r, dc.g, dc.b, dc.a or 1, T.fontF1)
        cy = cy + h1
    end
    cy = cy + T.px(10)
    local label = ZeD.tr("UI_ZeD_Find_Clear")
    local bw, bh = ZeD.Molecules.buttonW(label), T.buttonH
    local hover = ZeD.Atoms.mouseIn(panel, x + pad, cy, bw, bh)
    if hover then help(win, ZeD.tr("UI_ZeD_Find_HelpClear")) end
    ZeD.Molecules.drawButton(panel, x + pad, cy, bw, bh, label, "primary", false, nil,
        { hover = hover, focus = focus, win = win })
    local bs = win._findClearBtn or {}
    win._findClearBtn = bs
    local b = bs[tab] or {}
    bs[tab] = b
    b.x, b.y, b.w, b.h, b.drawn = x + pad, cy, bw, bh, true
    return cy + bh + pad - y
end

-- ============================================================================
-- THE FIELDS (one per tab, children of the drawer)
-- ============================================================================

-- A Find field with a clear box at its right while it holds text.
ZeD_TabFindField = ZeD_SearchField:derive("ZeD_TabFindField")

function ZeD_TabFindField:prerender()
    ZeD_SearchField.prerender(self)
    local T = ZeD.T
    local has = self:getText() ~= ""
    if self.input then
        -- the typing room stops short of the clear box
        local iw = self.width - T.px(self.iconAreaW) - (has and self.height or 0)
        if self.input:getWidth() ~= iw then self.input:setWidth(iw) end
    end
    -- focused (the controller's, or the keyboard's caret in it): the accent frame
    local typing = self.input and self.input.isFocused and self.input:isFocused()
    if self._padFocus or typing then
        local ac = T.accent
        self:drawRectBorder(0, 0, self.width, self.height, 1, ac.r, ac.g, ac.b)
    end
end

function ZeD_TabFindField:render()
    ZeD_SearchField.render(self)
    self._overClear = false
    if self:getText() == "" then self._clearR = nil; return end
    local T, tm = ZeD.T, ZeD.TM
    local s = self.height - T.px(6)
    local cx, cy = self.width - s - T.px(3), T.px(3)
    self._clearR = { x = cx, y = cy, w = s, h = s }
    local mx, my = self:getMouseX(), self:getMouseY()
    self._overClear = mx >= cx and mx < cx + s and my >= cy and my < cy + s
    local bs = T.borderS
    local s2 = T.surf2
    self:drawRect(cx, cy, s, s, s2.a or 1, s2.r, s2.g, s2.b)
    self:drawRectBorder(cx, cy, s, s, bs.a or 1, bs.r, bs.g, bs.b)
    local c = self._overClear and T.text or T.textDim
    local font = T.fontF1
    self:drawText("x", cx + math.floor((s - tm:MeasureStringX(font, "x")) / 2),
        cy + math.floor((s - tm:getFontHeight(font)) / 2) - T.px(1), c.r, c.g, c.b, c.a or 1, font)
end

function ZeD_TabFindField:onMouseDown(x, y)
    local r = self._clearR
    if r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h then
        if self.zedWin then F.clear(self.zedWin, self.zedTab) end
        return true
    end
    return false
end

-- the tab's field, made the first time the tab shows (as a child of the drawer)
local function makeField(win, tab, drawer)
    local f = ZeD_TabFindField:new(0, 0, ZeD.T.px(FIELD_W), ZeD.tr(HINT_KEY[tab]))
    f:initialise()
    f:setVisible(false)
    f.zedWin, f.zedTab = win, tab
    f.onFilter = function(_, text)
        F.setText(win, tab, text)
    end
    drawer:addChild(f)
    win._findFields = win._findFields or {}
    win._findFields[tab] = f
    -- a text kept from before (a tab shown again after the field was made): back in the box
    local t = F.text(win, tab)
    if t ~= "" and f.input then f.input:setText(t); f._lastText = t end
    return f
end

--- Every frame of the Character window (ZeD_CharacterWindow.extFrame): each tab's field
--- shows only while its tab shows in the drawer and drew its heading last frame, at the
--- place it gave.
function F.onWindowFrame(win, drawerW)
    local drawer = win._drawerPanel
    if not drawer then return end
    local rects = win._findRect or {}
    for _, tab in ipairs(F.TABS) do
        local show = win._activeTab == tab and win._drawerMode == "tab" and (drawerW or 0) > 0
        local r = rects[tab]
        local f = win._findFields and win._findFields[tab]
        if show and not f and r then f = makeField(win, tab, drawer) end
        local on = show and r ~= nil and r.drawn == true and r.x + r.w <= drawerW
        if r then r.drawn, r.live = false, on end
        local cb = win._findClearBtn and win._findClearBtn[tab]
        if cb then cb.live = show and cb.drawn == true; cb.drawn = false end
        if f then
            if on then
                if f:getX() ~= r.x or f:getY() ~= r.y then f:setX(r.x); f:setY(r.y) end
                if f:getWidth() ~= r.w or f:getHeight() ~= r.h then f:setWidth(r.w); f:setHeight(r.h) end
                -- placeholder words follow the language
                f.placeholder = ZeD.tr(HINT_KEY[tab])
            end
            if f:isVisible() ~= on then f:setVisible(on) end
        end
    end
end

--- Clears a tab's text: every row shows again, and with the controller the hand goes to the field.
function F.clear(win, tab)
    F.setText(win, tab, "")
    local f = win._findFields and win._findFields[tab]
    if f then f:clear() end
    local KB = ZeD.Keyboard
    if KB and KB.instance and f and KB.instance.textEntryBox == f.input then KB.hide() end
    win._findLand = { tab = tab, to = "field" }
    pcall(function() getSoundManager():playUISound("UIActivateButton") end)
end

--- The keyboard's Accept (RT): the hand lands on the first match.
function F.accepted(win, tab)
    local f = win._findFields and win._findFields[tab]
    if f and f.input and f.input.unfocus then pcall(function() f.input:unfocus() end) end
    win._findLand = { tab = tab, to = "match" }
end

--- A on the field: ZeD's pad keyboard on it (the text narrows the tab as each key goes in);
--- RT accepts, B puts the text back. Only the controller's A comes here (a click goes to the
--- field itself), so the keyboard opens whether or not a pad is bound to the player (a press the
--- QA bridge drives has none). Without the game's keyboard call, the field takes the caret.
function F.edit(win, tab)
    local f = win._findFields and win._findFields[tab]
    if not (f and f.input) then return end
    local p = win._playerObj
    local pn = (p and p.getPlayerNum and p:getPlayerNum()) or win.playerNum or 0
    local jd = JoypadState and JoypadState.players and JoypadState.players[pn + 1]
    if OnScreenKeyboard and OnScreenKeyboard.Show then
        local ok, osk = pcall(OnScreenKeyboard.Show, pn, f.input, jd)
        if ok and osk then
            osk.onAccept = function() F.accepted(win, tab) end
            if jd and jd.focus ~= osk then
                osk.prevFocus = jd.focus
                jd.focus = osk
                if updateJoypadFocus then updateJoypadFocus(jd) end
            end
            -- the hand stays on the field under the keyboard (B puts it back there)
            F.focusId(win, tab .. ":find", true)
            return
        end
    end
    f.input:focus()
end

--- A press in the drawer (x, y in its coordinates) on the active tab: the field's clear box
--- or the empty result's Clear. True when it took the press.
function F.onClick(win, x, y)
    local tab = win._activeTab
    if tab ~= "skills" and tab ~= "equip" then return false end
    local f = win._findFields and win._findFields[tab]
    local r = F.rect(win, tab)
    local cr = f and f:isVisible() and f._clearR
    if r and cr and x >= r.x + cr.x and x < r.x + cr.x + cr.w and y >= r.y + cr.y and y < r.y + cr.y + cr.h then
        F.clear(win, tab)
        return true
    end
    local b = win._findClearBtn and win._findClearBtn[tab]
    if b and b.live and F.active(win, tab) and x >= b.x and x < b.x + b.w and y >= b.y and y < b.y + b.h then
        F.clear(win, tab)
        return true
    end
    return false
end

--- Hides the pad keyboard if it is typing into one of the window's fields (the window closing).
function F.onClose(win)
    local KB = ZeD.Keyboard
    local k = KB and KB.instance
    if not (k and k.textEntryBox) then return end
    for _, tab in ipairs(F.TABS) do
        local f = win._findFields and win._findFields[tab]
        if f and k.textEntryBox == f.input then KB.hide() end
    end
end

-- ============================================================================
-- THE CONTROLLER'S STOPS
-- ============================================================================
local _stopFns = {}
local function stopFns(tab)
    local s = _stopFns[tab]
    if s then return s end
    s = {
        onFocus = function(w, el) w._gpFocusedEquipSlot = el.slotType end,
        edit = function(w) F.edit(w, tab) end,
        clear = function(w) F.clear(w, tab) end,
    }
    _stopFns[tab] = s
    return s
end

--- Adds the tab's Find stops to a list of the controller's stops: the field (A types, X
--- clears) and, with nothing matching, the empty result's Clear.
function F.stops(win, tab, elements)
    local fn = stopFns(tab)
    local r = F.rect(win, tab)
    if r and r.live then
        elements[#elements + 1] = { x = r.x, y = r.y, w = r.w, h = r.h, id = tab .. ":find", slotType = "__find",
            findField = true, onFocus = fn.onFocus, onActivate = fn.edit, onContextMenu = fn.clear }
    end
    local b = win._findClearBtn and win._findClearBtn[tab]
    if b and b.live and F.active(win, tab) then
        elements[#elements + 1] = { x = b.x, y = b.y, w = b.w, h = b.h, id = tab .. ":findclear", slotType = "__findclear",
            findClear = true, onFocus = fn.onFocus, onActivate = fn.clear, onContextMenu = fn.clear }
    end
end

--- Where the hand lands after a clear (the field) or the keyboard's Accept (the first
--- stop isHit(el) says matches; the field when none does). Sets elements._focusIdx and
--- elements._findLand (the window rebuilds its stops at once). Called by the tab's builder.
function F.land(win, tab, elements, isHit)
    local L = win._findLand
    if not (L and L.tab == tab) or #elements == 0 then return end
    local fieldIdx, first = nil, nil
    for i, el in ipairs(elements) do
        if el.findField then fieldIdx = i end
        if not first and L.to == "match" and isHit(el) then first = i end
    end
    local idx = first or fieldIdx
    if not idx then return end
    win._findLand = nil
    elements._focusIdx = idx
    elements._findLand = true
    local el = elements[idx]
    if el.onFocus then el.onFocus(win, el) end
end

--- After a landing (F.land) is taken: the window's focus moves into the tab's zone too. Setting
--- the tab's stop alone leaves the hand wherever the window's focus was (the tab strip's Loot key,
--- say), since the keyboard held the controller meanwhile.
function F.handIntoTab(w)
    for zi, z in ipairs(w and w._focusRing or {}) do
        if z.zone == "charTabContent" then
            w._focusIdx = zi
            w._navLast = nil
            w._focusPendingEntry = nil
            return true
        end
    end
    return false
end

-- the controller's focus onto the stop with this id in the tab's zone (as a D-pad move; quiet = no sound)
function F.focusId(w, id, quiet)
    for zi, z in ipairs(w._focusRing or {}) do
        if z.zone == "charTabContent" then
            for j, e in ipairs(z.elements or {}) do
                if e.id == id then
                    w._focusIdx = zi
                    z.focusedElementIdx = j
                    if e.onFocus then e.onFocus(w, e) end
                    if not quiet then pcall(function() getSoundManager():playUISound("UISelectListItem") end) end
                    return true
                end
            end
        end
    end
    return false
end

--- The Skills tab's up and down order at its top. The heading holds the disclosure (left)
--- and the Find field (right); under it, the key line a mod adds (the Transcribe key) and
--- then the skill rows. A cone from a row's centre missed a key at the far right and went
--- on past it, so the order is set here:
---   Up from a top row (the first row of each column)  -> the first key, else as before
---   Up from a key                                     -> the field, else the disclosure
---   Down from the field or the disclosure             -> the first key, else as before
--- Rows without a key above them, and everything else, move as the cone sends them.
local _rowUp = {}
function F.skillsPadOrder(elements)
    local field, disc, firstKey = nil, nil, nil
    local topY = {}
    for _, el in ipairs(elements) do
        if el.findField then field = el
        elseif el.isDisclosure then disc = el
        elseif el.skillsStopId and not firstKey then firstKey = el
        elseif el.skillName then
            local t = topY[el.x]
            if not t or el.y < t then topY[el.x] = el.y end
        end
    end
    if not firstKey then return end
    local keyId = firstKey.id
    local upTo = field and field.id or (disc and disc.id)
    for _, el in ipairs(elements) do
        if el.skillName and topY[el.x] == el.y then
            local prev = el.onDpadDir
            local f = _rowUp[prev or false]
            if not f then
                f = function(w, e, dir)
                    if prev and prev(w, e, dir) then return true end
                    if dir == "up" then return F.focusId(w, e._findUpTo) end
                    return false
                end
                _rowUp[prev or false] = f
            end
            el.onDpadDir, el._findUpTo = f, keyId
        elseif el.skillsStopId and upTo then
            el.onDpadDir, el._findUpTo = F._keyDpad, upTo
        elseif (el == field or el == disc) then
            el.onDpadDir, el._findDownTo = F._headDpad, keyId
        end
    end
end
function F._keyDpad(w, e, dir)
    if dir == "up" and e._findUpTo then return F.focusId(w, e._findUpTo) end
    return false
end
function F._headDpad(w, e, dir)
    if dir == "down" and e._findDownTo then return F.focusId(w, e._findDownTo) end
    return false
end
