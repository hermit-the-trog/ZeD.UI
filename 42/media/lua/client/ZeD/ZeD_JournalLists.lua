-- ZeD-UI/42/media/lua/client/ZeD/ZeD_JournalLists.lua
-- ============================================================================
-- THE JOURNAL'S LOADOUTS PAGE (handoff equip_doll_v4_loadouts, part B2; mockup
-- frame r2_08; the director: "Loadout lists should live in the journal tab")
--
-- The Journal tab's fifth page, after Recipes, in the Recipes page's pattern:
--   * a filter (All, Loadouts, Outfits: the pop-up menu's look) and a search
--     over list names and line names;
--   * Save what I carry as a loadout, Save what I wear as an outfit, New list
--     (each asks for a name: ZeD's prompt);
--   * two panes: the lists (Loadouts (n), Outfits (n), each row its icon, its
--     name and its line count, the chosen one in the selection wash) and the
--     chosen list: its name, "loadout | 9 lines", Rename, Add what I carry (an
--     outfit: Add what I wear) and Delete (asked first, in the band at the foot);
--     a loadout's lines in Gear (Any | This one) and Supplies (A day | Fixed and
--     the amount), an outfit's in Worn (Any | This one). Pressing an amount gives
--     a stepper; right-click (the pad's X) removes a line;
--   * under about 560 units the panes stack, the lists above the lines. The page
--     lives in the full card (the Journal's 480-unit drawer; director, Oct 29 2026:
--     "The updates should fit in the full card, not the half card"), so it reads
--     stacked: at 480 a narrowed list pane left the lines too little room for the
--     name beside the amount and the switch.
-- One scroll for the panes (the page scrolls as one). The data is ZeD_Lists.lua.
--
-- Hit zones are stamped each frame into win._jlZones (drawer coordinates); the
-- Character window routes clicks (JL.onClick, JL.onRightClick), the wheel
-- (JL.scroll) and the controller (JL.focusables, ids "jl:...") here.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/ZeD_Lists"
require "ZeD/ZeD_ListsMenu"

ZeD = ZeD or {}
ZeD.JournalLists = ZeD.JournalLists or {}
local JL = ZeD.JournalLists
local L = ZeD.Lists

local LIST_W   = 250    -- design units: the lists' pane
local STACK_W  = 560    -- under this the panes stack
local ROW_H    = 26     -- a list row
local LINE_H   = 36     -- a line row

local function fh(f) return ZeD.TM:getFontHeight(f) end
local function tw(f, s) return ZeD.TM:MeasureStringX(f, s) end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(n) pcall(function() getSoundManager():playUISound(n or "UIActivateButton") end) end
local function trunc(s, f, w) return ZeD.Atoms.truncateText(s, f, w) end

-- the page's own state on the window
local function st(win)
    if not win._jl then
        win._jl = { filter = "all", scroll = ZeD_ScrollbarState:new(), fold = {}, frame = 0, search = "" }
    end
    return win._jl
end
JL.state = st
function JL.scroll(win) return st(win).scroll end

local function player(win) return win and win._playerObj end
local function pnum(win) return (ZeD.playerNumOf and ZeD.playerNumOf(win)) or (win and win.playerNum) or 0 end

local function zone(win, z)
    win._jlZones = win._jlZones or {}
    win._jlZones[#win._jlZones + 1] = z
    return z
end

-- the controller's mark options for element "jl:<id>" (the window focused, the pad in use)
local _focusOpts = {}
local function focusOf(win, id)
    local F = ZeD.Input and ZeD.Input.Focus
    if F and F.isFocused and F.isFocused(win, nil, "jl:" .. id) then
        _focusOpts.win = win
        return _focusOpts
    end
    return nil
end
local function markFocus(panel, win, id, x, y, w, h)
    local fo = focusOf(win, id)
    if fo then return ZeD.Focus.mark(panel, x, y, w, h, fo) end
    return false
end

local function help(win, text)
    if ZeD.Help and ZeD.Help.set then ZeD.Help.set(win, text) end
end

-- the pointer over (x, y, w, h), inside the page's view
local function hoverRect(panel, win, x, y, w, h)
    local clip = st(win).clip
    if clip and not inRect(clip, panel:getMouseX(), panel:getMouseY()) then return false end
    if st(win).ask then return false end
    return ZeD.Atoms.mouseIn(panel, x, y, w, h)
end

-- the controller's focus id now, inside the Character window's tab content
local function focusedId(win)
    local F = ZeD.Input and ZeD.Input.Focus
    if not (F and F.liveZone and F.liveElement) then return nil end
    local fz = F.liveZone(win)
    if not (fz and fz.zone == "charTabContent") then return nil end
    local fe = F.liveElement(win)
    return fe and fe.id or nil
end

-- a push button (the library's); returns its width
local _btnOpts = {}
local function button(panel, win, id, x, y, text, fn, variant, opts)
    local T = ZeD.T
    opts = opts or {}
    local bw = opts.w or ZeD.Molecules.buttonW(text)
    local o = _btnOpts
    o.hover = hoverRect(panel, win, x, y, bw, T.buttonH)
    o.disabled = opts.disabled and true or false
    o.focus = focusOf(win, id)
    o.win = win
    o.help = opts.help
    ZeD.Molecules.drawButton(panel, x, y, bw, T.buttonH, text, variant or "default", false, nil, o)
    zone(win, { id = id, x = x, y = y, w = bw, h = T.buttonH, fn = (not opts.disabled) and fn or nil })
    return bw
end

-- an item type's picture (kept per type)
local _tex = {}
local function typeTex(ft)
    if not ft then return nil end
    local t = _tex[ft]
    if t == nil then
        t = false
        pcall(function()
            local sc = getScriptManager():FindItem(ft)
            local ic = sc and sc:getIcon()
            if ic and ic ~= "" then t = getTexture("Item_" .. ic) or getTexture(ic) or false end
        end)
        _tex[ft] = t
    end
    return t or nil
end

-- ---------------------------------------------------------------------------
-- ACTIONS
-- ---------------------------------------------------------------------------
--- Choose list id on the page (B4's Open in Journal: the page, that list chosen).
function JL.select(win, id)
    local s = st(win)
    s.sel, s.step, s.ask = id, nil, nil
    s.pinSel = true
end

local function saveCarry(win)
    local p = player(win)
    if not p then return end
    ZeD.ListsUI.askName(pnum(win), ZeD.tr("UI_ZeD_Lists_NameLoadout"), L.uniqueName(p, "loadout"), function(name)
        local l = L.saveCarry(p, L.uniqueName(p, "loadout", name))
        if l then JL.select(win, l.id) end
    end)
end

local function saveWear(win)
    local p = player(win)
    if not p then return end
    ZeD.ListsUI.askName(pnum(win), ZeD.tr("UI_ZeD_Lists_NameOutfit"), L.uniqueName(p, "outfit"), function(name)
        local l = L.saveWear(p, L.uniqueName(p, "outfit", name))
        if l then JL.select(win, l.id) end
    end)
end

-- New list: an outfit while the filter shows outfits, else a loadout
local function newList(win)
    local p = player(win)
    if not p then return end
    local kind = (st(win).filter == "outfit") and "outfit" or "loadout"
    ZeD.ListsUI.newList(p, kind, nil, function(l) if l then JL.select(win, l.id) end end)
end

local function renameList(win, id)
    local p = player(win)
    local l = L.get(p, id)
    if not l then return end
    ZeD.ListsUI.askName(pnum(win), ZeD.tr("UI_ZeD_Lists_RenameTitle"), l.name, function(name) L.rename(p, id, name) end)
end

local function addCurrent(win, id)
    local p = player(win)
    local n = L.addCurrent(p, id)
    st(win).msg = { id = id, text = ZeD.tr(n == 1 and "UI_ZeD_Lists_AddedOne" or "UI_ZeD_Lists_AddedMany", n) }
end

local function askDelete(win, id)
    local s = st(win)
    s.ask, s.step = id, nil
    s.land = "jl:ask:cancel"
end

function JL.confirmDelete(win)
    local s = st(win)
    local id = s.ask
    s.ask, s.askRects = nil, nil
    if id and L.delete(player(win), id) then
        if s.sel == id then s.sel = nil end
        s.land = "jl:new"
    end
end

function JL.cancelDelete(win)
    local s = st(win)
    s.ask, s.askRects = nil, nil
    s.land = "jl:delete"
end

local function removeLine(win, listId, lineId)
    L.removeLine(player(win), listId, lineId)
    local s = st(win)
    if s.step == lineId then s.step = nil end
end

-- a small menu of words at (sx, sy) on the screen (the context list's look)
local function menuAt(win, sx, sy, rows)
    local m = ZeD_ContextList:new(pnum(win), "cursor", sx, sy, nil, rows, nil)
    m.noHead = true   -- (the list's head names a target: this menu has none)
    m:initialise()
    m:open()
    JL.menu = m
    return m
end

local function lineMenu(win, listId, lineId)
    return function(sx, sy)
        menuAt(win, sx, sy, {
            { name = getText("ContextMenu_Remove"), category = "x", pxIcon = "trash",
              iconTexture = ZeD.PxIcon.tex("trash", 16), iconTintable = true,
              onFire = function() removeLine(win, listId, lineId) end },
        })
    end
end

local function listMenu(win, id)
    return function(sx, sy)
        menuAt(win, sx, sy, {
            { name = getText("ContextMenu_RenameBag"), category = "a", onFire = function() renameList(win, id) end },
            { name = ZeD.tr("UI_ZeD_Journal_Delete"), category = "b", onFire = function() JL.select(win, id); askDelete(win, id) end },
        })
    end
end

-- the filter's pop-up (All, Loadouts, Outfits), dropped from the select
local FILTERS = {
    { id = "all", key = "UI_All" },
    { id = "loadout", key = "UI_ZeD_Lists_FilterLoadouts" },
    { id = "outfit", key = "UI_ZeD_Lists_FilterOutfits" },
}
local function filterLabel(id)
    for _, f in ipairs(FILTERS) do if f.id == id then return ZeD.tr(f.key) end end
    return ZeD.tr("UI_All")
end
local function openFilter(win, sx, sy)
    local s = st(win)
    local rows = {}
    for _, f in ipairs(FILTERS) do
        local fid = f.id
        rows[#rows + 1] = { name = ZeD.tr(f.key), category = "f", check = function() return s.filter == fid end,
            onFire = function() s.filter = fid; s.scroll:setScrollPos(0) end }
    end
    menuAt(win, sx, sy, rows)
end

-- ---------------------------------------------------------------------------
-- WHAT THE PAGE SHOWS
-- ---------------------------------------------------------------------------
local function matches(l, q)
    if q == "" then return true end
    if string.lower(l.name or ""):find(q, 1, true) then return true end
    for _, ln in ipairs(l.lines) do
        if string.lower(ln.name or ""):find(q, 1, true) then return true end
    end
    return false
end

-- the lists shown, by kind: { loadout = {...}, outfit = {...} }
local function shown(win)
    local s = st(win)
    local p = player(win)
    local q = string.lower(s.search or "")
    local out = { loadout = {}, outfit = {} }
    for _, kind in ipairs(L.KINDS) do
        if s.filter == "all" or s.filter == kind then
            for _, l in ipairs(L.all(p, kind)) do
                if matches(l, q) then out[kind][#out[kind] + 1] = l end
            end
        end
    end
    return out
end

-- ---------------------------------------------------------------------------
-- ONE SCROLL FOR THE PANES
-- ---------------------------------------------------------------------------
local function framed(panel, win, x, y, w, h, draw)
    local T = ZeD.T
    local s = st(win)
    local sc = s.scroll
    local total = s.total or h
    local sbW = T.sp.scrollbarW
    local needs = total > h
    local drawW = needs and (w - sbW - T.px(2)) or w
    sc.visible = needs
    if needs then
        sc.x, sc.y, sc.height = x + w - sbW, y, h
        sc:setBarSize(h / total)
    else
        sc:setScrollPos(0)
    end
    -- the controller's focus kept in view (last frame's zones; only when the focus moves)
    local fid = JL._fid
    if needs and fid and fid ~= s.pinned and s.lastZones then
        for _, z in ipairs(s.lastZones) do
            if "jl:" .. z.id == fid and z.scrolls then
                local off = sc.scrollPos * (total - h)
                local m = T.px(8)
                local newOff = off
                if z.y < y + m then newOff = off - (y + m - z.y)
                elseif z.y + z.h > y + h - m then newOff = off + (z.y + z.h - (y + h - m)) end
                newOff = math.max(0, math.min(total - h, newOff))
                if newOff ~= off then sc:setScrollPos(newOff / (total - h)) end
                break
            end
        end
    end
    s.pinned = fid
    local off = needs and math.floor(sc.scrollPos * (total - h)) or 0
    s.clip = { x = x, y = y, w = w, h = h }
    panel:setStencilRect(x, y, needs and (w - sbW) or w, h)
    local first = #(win._jlZones or {})
    local bottom = draw(drawW, y - off)
    panel:clearStencilRect()
    -- the zones drawn in the view scroll with it (the scroll-follow reads them)
    for i = first + 1, #(win._jlZones or {}) do win._jlZones[i].scrolls = true end
    s.total = math.max(1, bottom - (y - off) + T.sp.sm)
    if needs then sc:draw(panel) end
end

-- ---------------------------------------------------------------------------
-- THE LISTS PANE
-- ---------------------------------------------------------------------------
local function drawListRow(panel, win, l, x, y, w)
    local T, A = ZeD.T, ZeD.Atoms
    local s = st(win)
    local h = T.px(ROW_H)
    local id = "list:" .. l.id
    local sel = (s.sel == l.id)
    if sel then
        local ac = T.accent
        panel:drawRect(x, y, w, h, T.selectionA, ac.r, ac.g, ac.b)
    end
    local hover = hoverRect(panel, win, x, y, w, h)
    if hover then
        local hv = T.hover
        panel:drawRect(x, y, w, h, hv.a, hv.r, hv.g, hv.b)
        help(win, ZeD.tr("UI_ZeD_Lists_HelpPick", l.name))
    end
    local onFocus = markFocus(panel, win, id, x, y, w, h)
    local tc = onFocus and T.textOnFocus or T.text   -- (the selection wash marks the chosen one; the words stay default)
    local isz = T.px(14)
    local ix = x + T.px(10)
    A.drawPxIcon(panel, L.icon(l.kind), ix, y + math.floor((h - isz) / 2), isz, 1, tc)
    local f2, f1 = T.fontF2, T.fontF1
    local cnt = tostring(#l.lines)
    local cw = tw(f1, cnt)
    local dc = onFocus and T.textOnFocus or T.textDim
    panel:drawText(cnt, x + w - T.px(8) - cw, y + math.floor((h - fh(f1)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f1)
    local nx = ix + isz + T.px(8)
    panel:drawText(trunc(l.name, f2, x + w - T.px(16) - cw - nx), nx, y + math.floor((h - fh(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
    A.drawDividerH(panel, x, y + h - T.hair, w)
    local lid = l.id
    zone(win, { id = id, x = x, y = y, w = w, h = h, fn = function() JL.select(win, lid); sound("UISelectListItem") end,
        menu = listMenu(win, lid) })
    return h
end

local function drawListsPane(panel, win, x, y, w)
    local T, M = ZeD.T, ZeD.Molecules
    local s = st(win)
    local lists = shown(win)
    local cy = y
    local any = false
    for _, kind in ipairs(L.KINDS) do
        if s.filter == "all" or s.filter == kind then
            local arr = lists[kind]
            local folded = s.fold[kind]
            local id = "sec:" .. kind
            local label = ZeD.tr(kind == "outfit" and "UI_ZeD_Lists_FilterOutfits" or "UI_ZeD_Lists_FilterLoadouts")
            local h = T.px(20)
            local hover = hoverRect(panel, win, x, cy, w, h)
            if hover then help(win, ZeD.tr(folded and "UI_ZeD_Lists_HelpShow" or "UI_ZeD_Lists_HelpHide", label)) end
            M.drawCategoryRow(panel, x, cy, w, label, #arr, not folded, { hover = hover, focus = focusOf(win, id), h = h, inset = T.px(6) })
            local k = kind
            zone(win, { id = id, x = x, y = cy, w = w, h = h, fn = function() s.fold[k] = not s.fold[k] end })
            cy = cy + h
            if not folded then
                for _, l in ipairs(arr) do cy = cy + drawListRow(panel, win, l, x, cy, w); any = true end
            end
        end
    end
    if not any and #L.all(player(win)) == 0 then
        cy = cy + T.px(6)
        cy = cy + M.drawEmptyLine(panel, x + T.px(8), cy, w - T.px(16), ZeD.tr("UI_ZeD_Lists_NoLists"))
    end
    return cy
end

-- ---------------------------------------------------------------------------
-- A LINE
-- ---------------------------------------------------------------------------
-- a two-way switch ("Any | This one"): returns its width; one stop, A flips it
local function drawSwitch(panel, win, id, xr, y, h, a, b, onA, fn, disabledB)
    local T, A = ZeD.T, ZeD.Atoms
    local f1 = T.fontF1
    local pad = T.px(7)
    local wa, wb = tw(f1, a) + pad * 2, tw(f1, b) + pad * 2
    local w = wa + wb
    local x = xr - w
    local hover = hoverRect(panel, win, x, y, w, h)
    local onFocus = markFocus(panel, win, id, x - T.px(2), y - T.px(2), w + T.px(4), h + T.px(4))
    local ac, s2 = T.accent, T.surf2
    for i = 1, 2 do
        local sx, sw, on, word = (i == 1) and x or (x + wa), (i == 1) and wa or wb, (i == 1) == onA, (i == 1) and a or b
        local dim = (i == 2 and disabledB) and T.disabledAlpha or 1
        if on then panel:drawRect(sx, y, sw, h, 1, ac.r, ac.g, ac.b)
        else panel:drawRect(sx, y, sw, h, (s2.a or 1), s2.r, s2.g, s2.b) end
        local tc = on and (T.textOnAccent or T.text) or T.textDim
        panel:drawText(word, sx + pad, y + math.floor((h - fh(f1)) / 2), tc.r, tc.g, tc.b, (tc.a or 1) * dim, f1)
    end
    A.frame(panel, x, y, w, h, onFocus and T.textOnFocus or T.borderS)
    if hover then help(win, ZeD.tr("UI_ZeD_Lists_HelpSwitch", a, b)) end
    -- the mouse presses a half; the pad's A flips
    zone(win, { id = id, x = x, y = y, w = w, h = h, fn = fn, click = function(mx)
        if mx < x + wa then fn(true) else fn(false) end
    end })
    return w
end

-- the amount: its words in a box; pressed, a stepper (- n +) in its place
local function drawAmount(panel, win, list, ln, xr, y, h)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local s = st(win)
    local f1 = T.fontF1
    local id = "amt:" .. ln.id
    local txt = L.amountText(ln)
    local p = player(win)
    local listId, lineId = list.id, ln.id
    local function bump(dir)
        L.setAmount(p, listId, lineId, (ln.amount or 1) + dir * L.step(ln))
    end
    if s.step == ln.id then
        local kw = h
        local vw = math.max(tw(f1, txt) + T.px(12), T.px(40))
        local w = kw * 2 + vw + T.px(4)
        local x = xr - w
        local o = _btnOpts
        o.disabled, o.focus, o.win, o.help = (ln.amount or 1) <= L.step(ln), nil, win, nil
        o.hover = hoverRect(panel, win, x, y, kw, h)
        M.drawButton(panel, x, y, kw, h, "-", "default", false, nil, o)
        zone(win, { id = "dec:" .. ln.id, x = x, y = y, w = kw, h = h, fn = function() bump(-1) end, mouseOnly = true })
        local vx = x + kw + T.px(2)
        local onFocus = markFocus(panel, win, id, vx, y, vw, h)
        A.frame(panel, vx, y, vw, h, T.accent)
        local tc = onFocus and T.textOnFocus or T.text
        panel:drawText(txt, vx + math.floor((vw - tw(f1, txt)) / 2), y + math.floor((h - fh(f1)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f1)
        o.disabled = false
        o.hover = hoverRect(panel, win, vx + vw + T.px(2), y, kw, h)
        M.drawButton(panel, vx + vw + T.px(2), y, kw, h, "+", "default", false, nil, o)
        zone(win, { id = "inc:" .. ln.id, x = vx + vw + T.px(2), y = y, w = kw, h = h, fn = function() bump(1) end, mouseOnly = true })
        if hoverRect(panel, win, vx, y, vw, h) then help(win, ZeD.tr("UI_ZeD_Lists_HelpStepDone")) end
        zone(win, { id = id, x = vx, y = y, w = vw, h = h, fn = function() s.step = nil end, cancel = function() s.step = nil end,
            dpad = function(dir)
                if dir == "left" then bump(-1); return true end
                if dir == "right" then bump(1); return true end
                s.step = nil
                return false
            end })
        return w
    end
    -- closed: a push button with the amount as its words (the library's: hover, focus mark, help)
    local w = math.max(tw(f1, txt) + T.px(14), T.px(36))
    local x = xr - w
    local o = _btnOpts
    o.hover = hoverRect(panel, win, x, y, w, h)
    o.disabled, o.focus, o.win = false, focusOf(win, id), win
    o.help = ZeD.tr("UI_ZeD_Lists_HelpAmount")
    o.font = f1
    M.drawButton(panel, x, y, w, h, txt, "default", false, { keepCase = true }, o)
    o.font = nil
    zone(win, { id = id, x = x, y = y, w = w, h = h, fn = function() s.step = lineId end })
    return w
end

local function lineSub(ln)
    local sub = L.placeText(ln.place)
    if ln.minCond then sub = sub .. ", " .. ZeD.tr("UI_ZeD_Lists_MinCond", math.floor(ln.minCond * 100 + 0.5)) end
    if ln.minFill then sub = sub .. ", " .. ZeD.tr("UI_ZeD_Lists_MinFill", math.floor(ln.minFill * 100 + 0.5)) end
    return sub
end

local function drawLine(panel, win, list, ln, x, y, w)
    local T, A = ZeD.T, ZeD.Atoms
    local p = player(win)
    local h = T.px(LINE_H)
    local ch = T.px(20)
    local cy = y + math.floor((h - ch) / 2)
    local listId, lineId = list.id, ln.id
    -- the controls, from the right: the switch, then the amount
    local right = x + w - T.px(4)
    local sw
    if ln.sec == "supply" then
        sw = drawSwitch(panel, win, "sw:" .. ln.id, right, cy, ch, ZeD.tr("UI_ZeD_Lists_PerDay"), ZeD.tr("UI_ZeD_Lists_Fixed"),
            ln.per == "day", function(pickA)
                if pickA == nil then pickA = ln.per ~= "day" end
                L.setPer(p, listId, lineId, pickA and "day" or "fixed")
            end)
    else
        sw = drawSwitch(panel, win, "sw:" .. ln.id, right, cy, ch, ZeD.tr("UI_ZeD_Lists_Any"), ZeD.tr("UI_ZeD_Lists_ThisOne"),
            ln.rule ~= "this", function(pickA)
                if pickA == nil then pickA = ln.rule == "this" end
                L.setRule(p, listId, lineId, pickA and "any" or "this")
            end, ln.itemId == nil)
    end
    right = right - sw - T.px(8)
    if ln.sec == "supply" or (ln.sec == "gear" and ln.rule ~= "this") then
        right = right - drawAmount(panel, win, list, ln, right, cy, ch) - T.px(8)
    end
    -- the row: its picture, its name and where it goes (right-click / X: remove)
    local id = "line:" .. ln.id
    local rw = right - x
    local hover = hoverRect(panel, win, x, y, rw, h)
    if hover then
        local hv = T.hover
        panel:drawRect(x, y, rw, h, hv.a, hv.r, hv.g, hv.b)
        help(win, ZeD.tr("UI_ZeD_Lists_HelpLine"))
    end
    local onFocus = markFocus(panel, win, id, x, y, rw, h)
    local isz = T.px(22)
    local tex = typeTex(ln.type)
    if tex then panel:drawTextureScaledAspect(tex, x + T.px(4), y + math.floor((h - isz) / 2), isz, isz, 1, 1, 1, 1)
    else A.drawPxIcon(panel, L.icon(list.kind), x + T.px(4), y + math.floor((h - isz) / 2), isz, 1, T.textDim) end
    local nx = x + T.px(4) + isz + T.px(8)
    local f2, f3 = T.fontF2, T.fontF3
    local ty = y + math.floor((h - fh(f2) - fh(f3)) / 2)
    local hi = onFocus and T.textOnFocus or T.toneHi or T.text
    panel:drawText(trunc(ln.name or ln.type or "?", f2, right - nx - T.px(4)), nx, ty, hi.r, hi.g, hi.b, hi.a or 1, f2)
    local dc = onFocus and T.textOnFocus or T.textDim
    panel:drawText(trunc(lineSub(ln), f3, right - nx - T.px(4)), nx, ty + fh(f2), dc.r, dc.g, dc.b, dc.a or 1, f3)
    A.drawDividerH(panel, x, y + h - T.hair, w)
    zone(win, { id = id, x = x, y = y, w = rw, h = h, menu = lineMenu(win, listId, lineId) })
    return h
end

-- ---------------------------------------------------------------------------
-- THE CHOSEN LIST
-- ---------------------------------------------------------------------------
local function drawDetailHead(panel, win, l, x, y, w)
    local T, A = ZeD.T, ZeD.Atoms
    local s = st(win)
    local f4, f3 = T.fontF4, T.fontF3
    local cy = y + T.px(8)
    local hi = T.toneHi or T.text
    local name = trunc(l.name, f4, w - T.px(8))
    panel:drawText(name, x + T.px(4), cy, hi.r, hi.g, hi.b, hi.a or 1, f4)
    local count = L.countText(l)
    if s.msg and s.msg.id == l.id then count = count .. " | " .. s.msg.text end
    local nx = x + T.px(4) + tw(f4, name) + T.px(10)
    local dc = T.textDim
    if nx + tw(f3, count) <= x + w then
        panel:drawText(count, nx, cy + fh(f4) - fh(f3) - T.px(1), dc.r, dc.g, dc.b, dc.a or 1, f3)
        cy = cy + fh(f4) + T.px(8)
    else
        cy = cy + fh(f4) + T.px(2)
        panel:drawText(trunc(count, f3, w - T.px(8)), x + T.px(4), cy, dc.r, dc.g, dc.b, dc.a or 1, f3)
        cy = cy + fh(f3) + T.px(8)
    end
    -- Rename, Add what I carry / wear, Delete (they wrap on a narrow pane)
    local id = l.id
    local bx = x + T.px(4)
    local gap = T.px(6)
    local defs = {
        { "rename", getText("ContextMenu_RenameBag"), function() renameList(win, id) end, nil, ZeD.tr("UI_ZeD_Lists_HelpRename") },
        { "add", ZeD.tr(l.kind == "outfit" and "UI_ZeD_Lists_AddWear" or "UI_ZeD_Lists_AddCarry"), function() addCurrent(win, id) end, nil,
          ZeD.tr(l.kind == "outfit" and "UI_ZeD_Lists_HelpAddWear" or "UI_ZeD_Lists_HelpAddCarry") },
        { "delete", ZeD.tr("UI_ZeD_Journal_Delete"), function() askDelete(win, id) end, "danger", ZeD.tr("UI_ZeD_Lists_HelpDelete") },
    }
    for _, d in ipairs(defs) do
        local bw = ZeD.Molecules.buttonW(d[2])
        if bx + bw > x + w and bx > x + T.px(4) then bx = x + T.px(4); cy = cy + T.buttonH + gap end
        bx = bx + button(panel, win, d[1], bx, cy, d[2], d[3], d[4], { help = d[5] }) + gap
    end
    return cy + T.buttonH + T.px(10)
end

local SEC = {
    gear   = { key = "UI_ZeD_Lists_Gear",     cap = "UI_ZeD_Lists_GearCap" },
    supply = { key = "UI_ZeD_Lists_Supplies", cap = "UI_ZeD_Lists_SuppliesCap" },
    worn   = { key = "UI_ZeD_Lists_Worn",     cap = "UI_ZeD_Lists_GearCap" },
}

local function drawDetail(panel, win, x, y, w)
    local T, M = ZeD.T, ZeD.Molecules
    local s = st(win)
    local p = player(win)
    local l = s.sel and L.get(p, s.sel) or nil
    if not l then
        s.sel = nil
        local cy = y + T.px(10)
        return cy + M.drawEmptyLine(panel, x + T.px(4), cy, w - T.px(8),
            ZeD.tr((#L.all(p) == 0) and "UI_ZeD_Lists_NoneYet" or "UI_ZeD_Lists_PickOne"))
    end
    local cy = drawDetailHead(panel, win, l, x, y, w)
    local f1 = T.fontF1
    for _, sec in ipairs(L.sections(l)) do
        local def = SEC[sec.sec] or SEC.gear
        local id = "lsec:" .. sec.sec
        local folded = s.fold[id]
        local h = T.px(20)
        local hover = hoverRect(panel, win, x, cy, w, h)
        local label = ZeD.tr(def.key)
        if hover then help(win, ZeD.tr(folded and "UI_ZeD_Lists_HelpShow" or "UI_ZeD_Lists_HelpHide", label)) end
        M.drawSectionHeader(panel, x + T.px(4), cy, w - T.px(4), label, #sec.lines, not folded, hover, nil, true, T.px(4), h, nil,
            { focus = focusOf(win, id) })
        local cap = ZeD.tr(def.cap)
        local dc = T.textDim
        if tw(f1, cap) < w * 0.5 then
            panel:drawText(cap, x + w - T.px(6) - tw(f1, cap), cy + math.floor((h - fh(f1)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f1)
        end
        local fid = id
        zone(win, { id = id, x = x, y = cy, w = w, h = h, fn = function() s.fold[fid] = not s.fold[fid] end })
        cy = cy + h
        if not folded then
            if #sec.lines == 0 then
                cy = cy + T.px(4)
                cy = cy + M.drawEmptyLine(panel, x + T.px(8), cy, w - T.px(16),
                    ZeD.tr(l.kind == "outfit" and "UI_ZeD_Lists_EmptyWorn" or "UI_ZeD_Lists_EmptySec")) + T.px(4)
            end
            for _, ln in ipairs(sec.lines) do cy = cy + drawLine(panel, win, l, ln, x, cy, w) end
        end
        cy = cy + T.px(8)
    end
    return cy
end

-- ---------------------------------------------------------------------------
-- THE TOP: the filter, the search, the three buttons
-- ---------------------------------------------------------------------------
local function searchField(win)
    if win._jlSearch then return win._jlSearch end
    local T = ZeD.T
    local f = ZeD_SearchField:new(0, 0, T.px(200), ZeD.tr("UI_ZeD_Lists_Search"))
    f:initialise()
    f:setVisible(false)
    f.onFilter = function(_, text)
        local s = st(win)
        s.search = text or ""
        s.scroll:setScrollPos(0)
    end
    win._drawerPanel:addChild(f)
    win._jlSearch = f
    return f
end

local function drawTop(panel, win, x, y, w)
    local T = ZeD.T
    local s = st(win)
    local pad = T.sp.sm
    local cy = y + pad
    local ih = T.inputH
    -- the filter (the pop-up menu's look) and the search
    local fw = math.min(T.px(170), math.floor((w - pad * 3) * 0.4))
    local fx = x + pad
    local hover = hoverRect(panel, win, fx, cy, fw, ih)
    if hover then help(win, ZeD.tr("UI_ZeD_Lists_HelpFilter")) end
    local select = ZeD.Stations and ZeD.Stations.drawSelect
    if select then select(panel, fx, cy, fw, ih, nil, filterLabel(s.filter), false, focusOf(win, "filter") ~= nil, hover) end
    local fy = cy
    zone(win, { id = "filter", x = fx, y = cy, w = fw, h = ih, fn = function()
        openFilter(win, panel:getAbsoluteX() + fx, panel:getAbsoluteY() + fy + ih + T.px(1))
    end })
    local sf = searchField(win)
    local sx, sw = fx + fw + pad, x + w - pad - (fx + fw + pad)
    if sf:getX() ~= sx or sf:getY() ~= cy then sf:setX(sx); sf:setY(cy) end
    if sf:getWidth() ~= sw or sf:getHeight() ~= ih then sf:setWidth(sw); sf:setHeight(ih) end
    s.searchShown = sw > T.px(40)
    cy = cy + ih + pad
    -- Save what I carry as a loadout, Save what I wear as an outfit, New list
    local bx = x + pad
    local gap = T.px(6)
    local defs = {
        { "carry", ZeD.tr("UI_ZeD_Lists_SaveCarry"), function() saveCarry(win) end, ZeD.tr("UI_ZeD_Lists_HelpSaveCarry") },
        { "wear", ZeD.tr("UI_ZeD_Lists_SaveWear"), function() saveWear(win) end, ZeD.tr("UI_ZeD_Lists_HelpSaveWear") },
        { "new", ZeD.tr("UI_ZeD_Lists_NewList"), function() newList(win) end, ZeD.tr("UI_ZeD_Lists_HelpNew") },
    }
    for _, d in ipairs(defs) do
        local bw = ZeD.Molecules.buttonW(d[2])
        if bx + bw > x + w - pad and bx > x + pad then bx = x + pad; cy = cy + T.buttonH + gap end
        bx = bx + button(panel, win, d[1], bx, cy, d[2], d[3], nil, { help = d[4], w = math.min(bw, w - pad * 2) }) + gap
    end
    cy = cy + T.buttonH + pad
    ZeD.Atoms.drawDividerH(panel, x, cy, w, true)
    return cy + T.px(1)
end

-- ---------------------------------------------------------------------------
-- RENDER
-- ---------------------------------------------------------------------------
function JL.render(panel, win, x, y, w, h)
    local T, M = ZeD.T, ZeD.Molecules
    local s = st(win)
    s.frame = s.frame + 1
    s.lastZones = win._jlZones
    win._jlZones = {}
    JL._fid = focusedId(win)
    if s.msg and s.msg.id ~= s.sel then s.msg = nil end
    local top = drawTop(panel, win, x, y, w)
    local bandH = s.ask and M.bandH() or 0
    local ph = y + h - top - bandH
    local stacked = w < T.px(STACK_W)
    s.stacked = stacked
    framed(panel, win, x, top, w, ph, function(dw, ty)
        if stacked then
            local cy = drawListsPane(panel, win, x, ty, dw)
            cy = cy + T.px(6)
            ZeD.Atoms.drawDividerH(panel, x, cy, dw, true)
            return drawDetail(panel, win, x + T.px(4), cy + T.px(1), dw - T.px(8))
        end
        local lw = T.px(LIST_W)
        local b1 = drawListsPane(panel, win, x, ty, lw)
        local b2 = drawDetail(panel, win, x + lw + T.px(10), ty, dw - lw - T.px(14))
        return math.max(b1, b2)
    end)
    if not stacked then
        ZeD.Atoms.drawDividerV(panel, x + T.px(LIST_W), top, ph)
    end
    -- the question before a delete: a band at the foot (Cancel and Delete)
    s.askRects = nil
    if s.ask then
        local l = L.get(player(win), s.ask)
        if not l then s.ask = nil
        else
            local by = y + h - bandH
            local _, cancel, verb = M.drawQuestionBand(panel, x, by, w,
                ZeD.tr(l.kind == "outfit" and "UI_ZeD_Lists_AskDeleteOutfit" or "UI_ZeD_Lists_AskDeleteLoadout", l.name),
                ZeD.tr("UI_ZeD_Journal_Delete"), { danger = true, win = win,
                    cancelFocus = focusOf(win, "ask:cancel"), verbFocus = focusOf(win, "ask:verb") })
            s.askRects = { cancel = cancel, verb = verb, band = { x = x, y = by, w = w, h = bandH } }
        end
    end
end

-- the drawer's children follow the page (called every frame by the Character window)
function JL.syncChildren(win, onPage)
    local f = win._jlSearch
    if not f then return end
    local s = st(win)
    local show = onPage and s.searchShown ~= false and win._drawerItem == nil and not s.ask
    if f:isVisible() ~= show then f:setVisible(show and true or false) end
    if not show and f.input and f.input:isFocused() then f.input:unfocus() end
end

-- ---------------------------------------------------------------------------
-- INPUT (routed by the Character window's drawer)
-- ---------------------------------------------------------------------------
function JL.onClick(win, x, y)
    local s = st(win)
    if s.ask then
        local r = s.askRects
        if r and inRect(r.verb, x, y) then JL.confirmDelete(win); sound(); return true end
        if r and inRect(r.cancel, x, y) then JL.cancelDelete(win); return true end
        return true   -- (the question holds the page)
    end
    local zs = win._jlZones
    if not zs then return false end
    for i = #zs, 1, -1 do
        local z = zs[i]
        if (z.fn or z.click) and inRect(z, x, y) and (not z.scrolls or inRect(s.clip, x, y)) then
            -- a press elsewhere closes an open stepper
            if s.step then
                local sid = tostring(s.step)
                local own = (z.id == "amt:" .. sid or z.id == "dec:" .. sid or z.id == "inc:" .. sid)
                if not own then
                    s.step = nil
                    if z.id:sub(1, 4) == "amt:" then return true end
                end
            end
            if z.click then z.click(x) else z.fn() end
            sound("UISelectListItem")
            return true
        end
    end
    if s.step then s.step = nil end
    return false
end

function JL.onRightClick(win, x, y)
    local s = st(win)
    if s.ask then return true end
    for i = #(win._jlZones or {}), 1, -1 do
        local z = win._jlZones[i]
        if z.menu and inRect(z, x, y) and (not z.scrolls or inRect(s.clip, x, y)) then
            z.menu(getMouseX(), getMouseY())
            return true
        end
    end
    return false
end

-- the controller's elements (ids "jl:..."): every live zone; while the question is up,
-- its two answers alone (Cancel first, where the focus lands)
function JL.focusables(win)
    local s = st(win)
    local out = {}
    if s.ask then
        local r = s.askRects
        if not r then return out end
        for _, k in ipairs({ "cancel", "verb" }) do
            local b = r[k]
            if b then
                out[#out + 1] = { x = b.x, y = b.y, w = b.w, h = b.h, id = "jl:ask:" .. k, onFocus = function() end,
                    onActivate = function(w) if k == "verb" then JL.confirmDelete(w) else JL.cancelDelete(w) end end,
                    onCancel = function(w) JL.cancelDelete(w) end }
            end
        end
        out._focusIdx = 1
        s.land = nil
        return out
    end
    local dp = win._drawerPanel
    for _, z in ipairs(win._jlZones or {}) do
        local inView = not z.scrolls or (s.clip and z.y + z.h > s.clip.y and z.y < s.clip.y + s.clip.h)
        if (z.fn or z.menu or z.dpad) and not z.mouseOnly and inView then
            local el = { x = z.x, y = z.y, w = z.w, h = z.h, id = "jl:" .. z.id, onFocus = function() end }
            if z.fn then el.onActivate = function() z.fn() end end
            if z.cancel then el.onCancel = function() z.cancel(); return true end end
            if z.menu then
                el.onContextMenu = function()
                    local ax = (dp and dp:getAbsoluteX() or 0) + z.x + ZeD.T.px(24)
                    local ay = (dp and dp:getAbsoluteY() or 0) + z.y + z.h
                    z.menu(ax, ay)
                end
            end
            if z.dpad then el.onDpadDir = function(w, e, dir) return z.dpad(dir) end end
            out[#out + 1] = el
        end
    end
    -- where the focus lands after a question or a delete
    if s.land then
        for i, e in ipairs(out) do
            if e.id == s.land then out._focusIdx = i; break end
        end
        if out._focusIdx or #out > 0 then s.land = nil end
    end
    return out
end

-- rebuild the controller's elements when the view scrolls or changes
function JL.scrollKey(win)
    local s = st(win)
    return tostring(s.scroll.scrollPos) .. ":" .. tostring(s.sel) .. ":" .. tostring(s.filter) .. ":" .. tostring(s.ask)
        .. ":" .. tostring(s.step) .. ":" .. tostring(L.gen) .. ":" .. tostring(s.search) .. ":" .. tostring(s.stacked)
end
