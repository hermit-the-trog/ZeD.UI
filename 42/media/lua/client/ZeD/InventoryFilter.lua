-- ZeD-UI/42/media/lua/client/ZeD/InventoryFilter.lua
-- ============================================================================
-- THE INVENTORY FILTER. Client; the state, the matching and the bar drawn under
-- a column's heading, shared by the Character and World windows through
-- InventoryRenderer (which owns the Filter button beside the view button).
--
-- One filter per window: it narrows every column the window shows (the
-- Character window's inventory and bags, the World window's containers). A name
-- holding the typed text (any case), in one of the picked categories (any of
-- them). What does not match is dimmed in place, never hidden: the rows keep
-- their places, their clicks, their drags and their menus.
--
-- Saved per container, as the list or grid view is: the window's filter is written to
-- every container it is narrowing (the character's mod data, by the container's
-- key), and a window that starts showing other containers takes the filter the
-- first of them saved (none saved: the filter empties). So the crate filtered
-- for "metal" is still filtered when it is opened again, after a reload too.
-- A container with no place of its own (the floor, a car not yet saved) keeps
-- no filter: its key is the same wherever the player stands.
--
-- The matches are worked out once per change (the text, the chips, a list's
-- model being rebuilt), never per frame: the rows only look up a table.
-- ============================================================================

ZeD = ZeD or {}
ZeD.InvFilter = ZeD.InvFilter or {}
local IF = ZeD.InvFilter

local MAX_Q = 48          -- the longest text kept (characters); a name is never longer than this is useful
local DIM_A = 0.62        -- how far a row that does not match fades toward the window's base

IF.DIM_A = DIM_A

-- ---------------------------------------------------------------------------
-- STATE
-- ---------------------------------------------------------------------------

--- The window's filter, kept on its list panel (made on first use).
function IF.of(panel)
    local S = panel._zedFilter
    if S then return S end
    S = {
        open = false, q = "", ql = "", cats = {}, nCats = 0,
        gen = 1,            -- one up on every change of the text or the chips (the matches are kept by it)
        keys = {}, nKeys = 0, synced = false,
        frame = {}, nFrame = 0,   -- this frame's columns' results, in order
        aggList = {}, aggN = -1,  -- the results the last count was made from
        rects = {}, lgen = 0, barH = 0, y = 0,
        panel = panel,
    }
    panel._zedFilter = S
    return S
end

--- True while the text or a chip narrows the lists.
function IF.active(S)
    return S ~= nil and (S.ql ~= "" or S.nCats > 0)
end

-- A container key with a place of its own, so a filter saved on it means that container. The floor has none: the
-- game has one floor container, the same object wherever the player stands, so its key is "type:floor" in every
-- town. Nor has a car not yet saved: its part's key carries no database id yet ("veh:-1:..."). A filter kept on
-- either opened on every floor or unsaved car and was written on to whatever showed beside it; theirs lasts while
-- the window shows them.
local function placed(k)
    if type(k) ~= "string" or string.sub(k, 1, 5) == "type:" then return false end
    if string.sub(k, 1, 4) == "veh:" then
        local id = tonumber(string.match(k, "^veh:([^:]*):") or "")
        return id ~= nil and id >= 0
    end
    return true
end
IF.placed = placed

-- the saved filters: the character's mod data, by container key (a sim hands in a plain table as S.store)
local function store(S)
    local st = S.store
    if not st then
        local p = S.panel and S.panel._playerObj
        if not p and getPlayer then p = getPlayer() end
        if not p then return nil end
        local md = p:getModData()
        md.ZeD_Filters = md.ZeD_Filters or {}
        st = md.ZeD_Filters
    end
    if not S.swept then
        -- (once per window: a save from before this kept the floor's filter, never read now; it is let go)
        S.swept = true
        local drop = nil
        for k in pairs(st) do
            if not placed(k) then drop = drop or {}; drop[#drop + 1] = k end
        end
        for i = 1, (drop and #drop or 0) do st[drop[i]] = nil end
    end
    return st
end

--- The filter as one string: the text, then each picked category, a line each (cats in key order, so the same
--- filter always writes the same string).
function IF.encode(S)
    local list = {}
    for k, on in pairs(S.cats) do if on then list[#list + 1] = k end end
    table.sort(list)
    local s = S.q
    for i = 1, #list do s = s .. "\n" .. list[i] end
    return s
end

--- The text and a list of categories from an encoded string.
function IF.decode(s)
    s = tostring(s or "")
    local parts, i = {}, 1
    while true do
        local j = string.find(s, "\n", i, true)
        if not j then parts[#parts + 1] = string.sub(s, i); break end
        parts[#parts + 1] = string.sub(s, i, j - 1)
        i = j + 1
    end
    local q = parts[1] or ""
    local cats = {}
    for n = 2, #parts do if parts[n] ~= "" then cats[#cats + 1] = parts[n] end end
    return q, cats
end

-- the filter written to (or, empty, taken off) every container the window shows that has a place of its own
local function save(S)
    local st = store(S)
    if not st then return end
    local v = IF.active(S) and IF.encode(S) or nil
    for i = 1, S.nKeys do
        local k = S.keys[i]
        if placed(k) then st[k] = v end
    end
end

local function changed(S)
    S.gen = S.gen + 1
    save(S)
end

-- the text, one line, no longer than MAX_Q
local function setText(S, q)
    q = string.gsub(tostring(q or ""), "[\r\n]", "")
    if #q > MAX_Q then q = string.sub(q, 1, MAX_Q) end
    S.q, S.ql = q, string.lower(q)
end

-- the text and the chips together (a load, a Clear)
local function setFrom(S, q, cats)
    setText(S, q)
    S.cats, S.nCats = {}, 0
    for _, c in ipairs(cats or {}) do
        if not S.cats[c] then S.cats[c] = true; S.nCats = S.nCats + 1 end
    end
end

--- The typed text (the field's every keystroke lands here); the chips stay as they are.
function IF.setQuery(S, q)
    q = tostring(q or "")
    if q == S.q then return end
    setText(S, q)
    changed(S)
end

--- A category chip on or off (several may be on: they widen).
function IF.toggleCat(S, cat)
    if cat == nil then return end
    if S.cats[cat] then S.cats[cat] = nil; S.nCats = S.nCats - 1
    else S.cats[cat] = true; S.nCats = S.nCats + 1 end
    changed(S)
end

--- Clear: the text and the chips empty; the bar stays open.
function IF.clear(S)
    if not IF.active(S) then return end
    setFrom(S, "", nil)
    changed(S)
end

--- The Filter button: opens the bar, or shuts it and clears it (a filter never narrows behind a shut bar).
function IF.toggleOpen(S)
    if S.open then
        S.open = false
        if IF.active(S) then setFrom(S, "", nil); changed(S) end
    else
        S.open = true
        S.wantFocus = true   -- (the field takes the keys at once for a mouse player)
    end
    S.lgen = S.lgen + 1
end

--- The containers the window shows this frame, by key (keys[1..n]). When they differ from the last frame's, the
--- window takes the filter the first of them saved, and writes it to the rest; none saved: the filter empties (an
--- open bar stays open). A key with no place of its own (the floor) is kept here, so a change is still seen, but
--- never gives or takes a saved filter. Returns true when the filter changed.
function IF.sync(S, keys, n)
    local same = S.synced and n == S.nKeys
    if same then
        for i = 1, n do if S.keys[i] ~= keys[i] then same = false; break end end
    end
    if same then return false end
    S.synced = true
    for i = 1, n do S.keys[i] = keys[i] end
    for i = n + 1, S.nKeys do S.keys[i] = nil end
    S.nKeys = n
    local st = store(S)
    local saved = nil
    for i = 1, n do
        local k = keys[i]
        if st and placed(k) and st[k] then saved = st[k]; break end
    end
    local before = IF.encode(S)
    if saved then
        local q, cats = IF.decode(saved)
        setFrom(S, q, cats)
        S.open = true
    elseif IF.active(S) then
        setFrom(S, "", nil)
    end
    if IF.encode(S) ~= before then S.gen = S.gen + 1 end
    save(S)
    S.lgen = S.lgen + 1
    return true
end

-- ---------------------------------------------------------------------------
-- MATCHING (once per change)
-- ---------------------------------------------------------------------------

--- One column's matches, from its list model M (InventoryRenderer's: groups by category key, catOrder). Kept on
--- the model until the filter changes or the model is rebuilt. Fields: match (item -> true), hit (item -> where
--- the text starts in its name), total / matched (things, a stack of 6 counting 6), catNamed (category -> things
--- whose name holds the text: the chips' counts), catMatched (category -> things that match: a category row with
--- none dims), cats (the categories in the list's order), active, ql (the text, lower case).
function IF.result(S, M)
    if M._fres and M._fgen == S.gen and M._fS == S then return M._fres end
    local ql = S.ql
    local res = { match = {}, hit = {}, total = 0, matched = 0, catNamed = {}, catMatched = {}, cats = {},
                  active = IF.active(S), ql = ql }
    local useCats = S.nCats > 0
    for _, cat in ipairs(M.catOrder or {}) do
        local named, hits = 0, 0
        local catOk = (not useCats) or S.cats[cat] == true
        for _, item in ipairs(M.groups[cat] or {}) do
            local at = 1
            if ql ~= "" then at = string.find(string.lower(item:getName() or ""), ql, 1, true) end
            if at then
                named = named + 1
                if catOk then
                    hits = hits + 1
                    res.match[item] = true
                    if ql ~= "" then res.hit[item] = at end
                end
            end
            res.total = res.total + 1
        end
        res.cats[#res.cats + 1] = cat
        res.catNamed[cat], res.catMatched[cat] = named, hits
        res.matched = res.matched + hits
    end
    M._fres, M._fgen, M._fS = res, S.gen, S
    return res
end

-- two counts that read the same: totals, and the chips in order with their keys, words, numbers and picks
local function sameAgg(a, b)
    if a.total ~= b.total or a.matched ~= b.matched or #a.chips ~= #b.chips then return false end
    for i = 1, #a.chips do
        local x, y = a.chips[i], b.chips[i]
        if x.key ~= y.key or x.label ~= y.label or x.n ~= y.n or x.on ~= y.on then return false end
    end
    return true
end

--- A frame starts: no columns counted yet.
function IF.frameStart(S) S.nFrame = 0 end

--- A column drew: its result joins the window's count.
function IF.frameAdd(S, res)
    S.nFrame = S.nFrame + 1
    S.frame[S.nFrame] = res
end

--- The window's count and chips: the sum of this frame's columns. Kept while the same results are in it.
--- { total, matched, chips = { { key, label, n, on } ... } by label }. label(key) gives a category's words.
function IF.aggregate(S, label)
    local n = S.nFrame
    local same = S.agg ~= nil and n == S.aggN and S.aggGen == S.gen and S.aggTr == ZeD._trGen
    if same then
        for i = 1, n do if S.aggList[i] ~= S.frame[i] then same = false; break end end
    end
    if same then return S.agg end
    local agg = { total = 0, matched = 0, chips = {} }
    local byKey = {}
    for i = 1, n do
        local r = S.frame[i]
        S.aggList[i] = r
        agg.total, agg.matched = agg.total + r.total, agg.matched + r.matched
        for _, cat in ipairs(r.cats) do
            local c = byKey[cat]
            if not c then
                c = { key = cat, label = tostring(label and label(cat) or cat), n = 0, on = S.cats[cat] == true }
                byKey[cat] = c
                agg.chips[#agg.chips + 1] = c
            end
            c.n = c.n + (r.catNamed[cat] or 0)
        end
    end
    -- a picked category with nothing in these containers keeps its chip, so it can be let go
    for cat, on in pairs(S.cats) do
        if on and not byKey[cat] then
            local c = { key = cat, label = tostring(label and label(cat) or cat), n = 0, on = true }
            byKey[cat] = c
            agg.chips[#agg.chips + 1] = c
        end
    end
    for _, c in ipairs(agg.chips) do c.nstr = tostring(c.n) end   -- (the chip's number, made once, not per frame)
    table.sort(agg.chips, function(a, b)
        local la, lb = string.lower(a.label), string.lower(b.label)
        if la ~= lb then return la < lb end
        return a.key < b.key
    end)
    -- A column's model is built again about once a second with nothing in it changed (a new model, so new results):
    -- a count that reads the same keeps the last table, so the bar is not laid out again for it.
    if S.agg and sameAgg(S.agg, agg) then agg = S.agg end
    S.agg, S.aggN, S.aggGen, S.aggTr = agg, n, S.gen, ZeD._trGen
    return agg
end

--- The count's words: "14 of 79" while something narrows, "Nothing matches" when nothing does, else the item count.
function IF.countText(S, agg)
    if not agg then return "" end
    if IF.active(S) then
        if agg.matched == 0 then return ZeD.tr("UI_ZeD_Inv_FilterNone") end
        return ZeD.tr("UI_ZeD_Inv_FilterCount", agg.matched, agg.total)
    end
    return ZeD.tr(agg.total == 1 and "UI_ZeD_Inv_ItemsOne" or "UI_ZeD_Inv_ItemsMany", agg.total)
end

-- ---------------------------------------------------------------------------
-- THE BAR: under the heading, across the window's list side. The field (the
-- game's text box, so the keys go to it), the count, Clear; then the chips,
-- wrapped. Laid out when what it shows or its width changes, drawn every frame.
-- ---------------------------------------------------------------------------

local function chipW(T, c)
    local tm = ZeD.TM
    return tm:MeasureStringX(T.fontF1, c.label) + T.px(5) + tm:MeasureStringX(T.fontF1, c.nstr or tostring(c.n)) + T.px(12)
end

-- true when the stops in a differ from b's: a stop added, gone, or moved
local function rectsMoved(a, b)
    if #a ~= #b then return true end
    for i = 1, #a do
        local p, q = a[i], b[i]
        if p.id ~= q.id or p.x ~= q.x or p.y ~= q.y or p.w ~= q.w or p.h ~= q.h then return true end
    end
    return false
end

--- Lays the bar out for width w at panel y (S.y): S.rects (panel coords, each { x, y, w, h, view = "fbar", key,
--- id }), S.barH, and the field's and the count's places. Kept while nothing it is made from changed. S.lgen goes
--- up only when a stop is added, goes or moves: the windows build their controller stops again on it.
function IF.layout(S, w, agg)
    local T = ZeD.T
    local u = T.px(10)
    -- (numbers compared, no key string: this runs every frame the bar shows)
    if S._lagg == agg and S._lw == w and S._ly == S.y and S._lu == u and S._lih == T.inputH and S._lg == S.gen
       and S._ltr == ZeD._trGen then return end
    S._lagg, S._lw, S._ly, S._lu, S._lih, S._lg, S._ltr = agg, w, S.y, u, T.inputH, S.gen, ZeD._trGen
    local tm = ZeD.TM
    local padX, padY, gap = T.sp.sm, T.px(6), T.px(6)
    local rowH = T.inputH
    local clearTxt = ZeD.btnCase(ZeD.tr("UI_ZeD_Inv_FilterClear"))
    local clearW = tm:MeasureStringX(T.fontF3, clearTxt) + T.sp.buttonPadX * 2
    -- the count's room: its widest words for these containers, so the field does not twitch as letters land
    local tot = agg and agg.total or 0
    local cw = math.max(tm:MeasureStringX(T.fontF5, ZeD.tr("UI_ZeD_Inv_FilterCount", tot, tot)),
                        tm:MeasureStringX(T.fontF5, ZeD.tr("UI_ZeD_Inv_FilterNone")),
                        tm:MeasureStringX(T.fontF5, ZeD.tr("UI_ZeD_Inv_ItemsMany", tot)))
    local y0 = S.y
    local rects = {}
    local fw = math.max(T.px(40), w - padX * 2 - clearW - cw - gap * 2)
    rects[1] = { x = padX, y = y0 + padY, w = fw, h = rowH, view = "fbar", key = "field", id = "view:fbar:field" }
    S.countX, S.countY, S.countW = padX + fw + gap, y0 + padY, cw
    rects[2] = { x = w - padX - clearW, y = y0 + padY, w = clearW, h = rowH, view = "fbar", key = "clear", id = "view:fbar:clear" }
    -- the chips, wrapped
    local ch = tm:getFontHeight(T.fontF1) + T.px(4)
    local cg = T.px(4)
    local cx, cy = padX, y0 + padY + rowH + T.px(6)
    local any = false
    for _, c in ipairs(agg and agg.chips or {}) do
        local cwid = math.min(chipW(T, c), w - padX * 2)
        if cx > padX and cx + cwid > w - padX then cx, cy = padX, cy + ch + cg end
        rects[#rects + 1] = { x = cx, y = cy, w = cwid, h = ch, view = "fbar", key = "chip:" .. c.key,
                              id = "view:fbar:chip:" .. c.key, chip = c }
        cx = cx + cwid + cg
        any = true
    end
    local bottom = any and (cy + ch) or (y0 + padY + rowH)
    S.barH = bottom + padY + T.px(1) - y0
    -- (last: the bar's own ground, so a press between the controls is the bar's and starts no box)
    rects[#rects + 1] = { x = 0, y = y0, w = w, h = S.barH, view = "fbar", key = "bg", id = "view:fbar:bg" }
    -- (the new rects are kept even when nothing moved: a chip's rect carries this count's chip, which it draws)
    local moved = rectsMoved(rects, S.rects)
    S.rects, S.w = rects, w
    if moved then S.lgen = S.lgen + 1 end
end

-- the field: a ZeD search field (the game's text box inside) made once, a child of the list panel
local function field(S, panel)
    local f = S.field
    if f then return f end
    if not ZeD_SearchField then return nil end
    local T = ZeD.T
    f = ZeD_SearchField:new(0, 0, T.px(200), ZeD.tr("UI_ZeD_Inv_FilterPlaceholder"))
    f:initialise()
    f:setVisible(false)
    f.onFilter = function(_, text) IF.setQuery(S, text) end
    f.onSubmit = function() pcall(function() f.input:unfocus() end) end
    panel:addChild(f)
    S.field = f
    return f
end

--- Hides the field (the bar shut, or the window shows no heading).
function IF.hideField(S)
    local f = S and S.field
    if f and f:isVisible() then
        pcall(function() f.input:unfocus() end)
        f:setVisible(false)
    end
end

local _chipFocus = {}
--- Draws the bar on panel (its layout done). focusOf(id) gives the controller's mark opts for a stop, or nil.
function IF.draw(panel, S, agg, focusOf)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local tm = ZeD.TM
    local y0, w = S.y, S.w or panel:getWidth()
    ZeD.Surface.fill(panel, 0, y0, w, S.barH, "surf1")
    A.drawDividerH(panel, 0, y0 + S.barH - T.px(1), w, true)
    local active = IF.active(S)
    -- the field: placed, its text kept with the filter's (a Clear or a container's saved filter changes it)
    local fr = S.rects[1]
    local f = field(S, panel)
    if f then
        if f:getX() ~= fr.x or f:getY() ~= fr.y then f:setX(fr.x); f:setY(fr.y) end
        if f:getWidth() ~= fr.w or f:getHeight() ~= fr.h then f:setWidth(fr.w); f:setHeight(fr.h) end
        if f._lastText ~= S.q and f.input then f.input:setText(S.q); f._lastText = S.q end
        if not f:isVisible() then f:setVisible(true) end
        if S.wantFocus then
            S.wantFocus = nil
            local Fo = ZeD.Input and ZeD.Input.Focus
            if not (Fo and Fo.cuesVisible and Fo.cuesVisible()) then pcall(function() f.input:focus() end) end
        end
        local fo = focusOf and focusOf(fr.id)
        if fo then ZeD.Focus.mark(panel, fr.x, fr.y, fr.w, fr.h, fo) end
    end
    -- the count
    local txt = IF.countText(S, agg)
    local cc = (active and agg and agg.matched > 0) and (T.accentText or T.accent) or T.toneNorm
    local fh5 = tm:getFontHeight(T.fontF5)
    txt = A.truncateText(txt, T.fontF5, S.countW)
    panel:drawText(txt, S.countX, S.countY + math.floor((fr.h - fh5) / 2), cc.r, cc.g, cc.b, cc.a or 1, T.fontF5)
    -- Clear
    local cr = S.rects[2]
    M.drawButton(panel, cr.x, cr.y, cr.w, cr.h, ZeD.tr("UI_ZeD_Inv_FilterClear"), "default", false, nil, {
        compact = true, disabled = not active, hover = A.mouseIn(panel, cr.x, cr.y, cr.w, cr.h),
        focus = focusOf and focusOf(cr.id), help = ZeD.tr("UI_ZeD_Inv_FilterClearHelp") })
    -- the chips: solid accent while picked; a category with no name holding the text greys
    local f1 = T.fontF1
    local fh1 = tm:getFontHeight(f1)
    for i = 3, #S.rects do
        local r = S.rects[i]
        local c = r.chip
        if c then
            local hov = A.mouseIn(panel, r.x, r.y, r.w, r.h)
            local bg = c.on and T.accent or T.surf2
            panel:drawRect(r.x, r.y, r.w, r.h, bg.a or 1, bg.r, bg.g, bg.b)
            if hov and not c.on then local hv = T.hover; panel:drawRect(r.x, r.y, r.w, r.h, hv.a or 1, hv.r, hv.g, hv.b) end
            local fo = focusOf and focusOf(r.id)
            local onF = false
            if fo then
                _chipFocus.win, _chipFocus.zone, _chipFocus.solid = fo.win, fo.zone, c.on
                onF = ZeD.Focus.mark(panel, r.x, r.y, r.w, r.h, _chipFocus) and true or false
            end
            A.frame(panel, r.x, r.y, r.w, r.h, c.on and T.accent or T.borderS)
            local tc = (onF and T.textOnFocus) or (c.on and T.textOnAccent) or (c.n == 0 and T.textDim) or T.text
            local nc = (onF and T.textOnFocus) or (c.on and T.textOnAccent) or T.textDim
            local ty = r.y + math.floor((r.h - fh1) / 2)
            local nstr = c.nstr or tostring(c.n)
            local nw = tm:MeasureStringX(f1, nstr)
            local lab = A.truncateText(c.label, f1, r.w - T.px(17) - nw)
            panel:drawText(lab, r.x + T.px(6), ty, tc.r, tc.g, tc.b, tc.a or 1, f1)
            panel:drawText(nstr, r.x + r.w - T.px(6) - nw, ty, nc.r, nc.g, nc.b, nc.a or 1, f1)
            if hov then ZeD.Help.set(panel, ZeD.tr(c.on and "UI_ZeD_Inv_FilterChipOffHelp" or "UI_ZeD_Inv_FilterChipHelp", c.label)) end
        end
    end
end

--- Opens the controller's keyboard on the field (A on it); a mouse player's click focuses it instead.
function IF.editField(S, win)
    local f = S and S.field
    if not (f and f.input) then return end
    local pn = (win and ZeD.playerNumOf and ZeD.playerNumOf(win)) or 0
    local jd = JoypadState and JoypadState.players and JoypadState.players[pn + 1]
    if jd and OnScreenKeyboard and OnScreenKeyboard.Show then
        local ok, osk = pcall(OnScreenKeyboard.Show, pn, f.input, jd)
        if ok and osk then return end
    end
    pcall(function() f.input:focus() end)
end

--- A press on the bar or the Filter button: what = "filter" / "field" / "clear" / "chip:<category>" / "bg".
function IF.act(S, what, win)
    if what == "filter" then IF.toggleOpen(S)
    elseif what == "clear" then IF.clear(S)
    elseif what == "field" then IF.editField(S, win)
    elseif type(what) == "string" and string.sub(what, 1, 5) == "chip:" then IF.toggleCat(S, string.sub(what, 6))
    else return false end
    pcall(function() getSoundManager():playUISound("UISelectListItem") end)
    return true
end
