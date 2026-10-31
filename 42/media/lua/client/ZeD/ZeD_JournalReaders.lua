-- ZeD-UI/42/media/lua/client/ZeD/ZeD_JournalReaders.lua
-- ============================================================================
-- THE JOURNAL TAB'S QUICK LOOKS AND NOTES (mockup zed_reader_v2; director Oct
-- 16 2026: "Both full and character menu are needed"; papers "Only while
-- carried", unread "Listed dim", the log box "Writes into a notebook")
--
-- Two sub-tabs of the Character window's Journal tab, drawn into the drawer:
--   * Papers: the newspapers, flyers and brochures the character carries, by
--     their real names, unread ones dim. A press opens the quick look: the page
--     small, what it is, its places (vanilla's Show on map) and its words, the
--     whole tab scrolling as one. A piece not read yet shows only its paper and
--     a Read button (vanilla's own Read action: the words, the read mark and
--     the places come from reading it). Open full pops the full reader.
--   * Notebooks: the notebooks, journals and diaries carried; the page small
--     and a quick-note field under it. Write adds the line to the page as a
--     short timed action (ZeD_WriteNoteAction: vanilla's light, pencil and lock
--     rules). Open full is vanilla's Write / Read note (ZeD's full page).
-- Also the log box's "Into": the Journal's Save can write the entry into a
-- carried notebook too; the log keeps where it went ("Supply runs, page 3").
--
-- Hit zones are stamped each frame into win._jrZones (drawer coordinates); the
-- Character window routes clicks (J.onClick), the wheel (J.scroll) and the
-- controller (J.focusables) here.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/ZeD_PrintPage"
require "ZeD/ZeD_Reader"
require "ZeD/ZeD_WriteNoteAction"

ZeD = ZeD or {}
ZeD.JournalReaders = ZeD.JournalReaders or {}
local J = ZeD.JournalReaders
local P = ZeD.Print
local N = ZeD.Notes

-- the page's paper and ink (as the full reader's)
local PAPER   = { r = 0.91, g = 0.886, b = 0.824 }
local INK     = { r = 0.141, g = 0.133, b = 0.118 }
local RULE    = { r = 0.725, g = 0.776, b = 0.839 }
local MARGIN  = { r = 0.827, g = 0.604, b = 0.573 }

local FILTERS = {
    { id = "all",   key = "UI_All" },                  -- (the game's own "All")
    { id = "news",  key = "UI_ZeD_Papers_FilterNews" },
    { id = "flyer", key = "UI_ZeD_Papers_FilterFlyers" },
    { id = "map",   key = "UI_ZeD_Papers_FilterOnMap" },
}

local function fh(f) return ZeD.TM:getFontHeight(f) end
local function tw(f, s) return ZeD.TM:MeasureStringX(f, s) end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(n) pcall(function() getSoundManager():playUISound(n or "UIActivateButton") end) end
local function trunc(s, f, w) return ZeD.Atoms.truncateText(s, f, w) end

-- the tab's own state on the window
local function st(win)
    if not win._jr then
        win._jr = { filter = "all", scroll = ZeD_ScrollbarState:new(), nbPage = {}, frame = 0 }
    end
    return win._jr
end

function J.scroll(win) return st(win).scroll end

-- the live controller focus inside the Character window's tab content (the focused
-- window, the controller in use: the library's liveZone / liveElement)
local function focusedId(win)
    local F = ZeD.Input and ZeD.Input.Focus
    if not (F and F.liveZone and F.liveElement) then return nil end
    local fz = F.liveZone(win)
    if not (fz and fz.zone == "charTabContent") then return nil end
    local fe = F.liveElement(win)
    return fe and fe.id or nil
end

local function zone(win, z)
    win._jrZones = win._jrZones or {}
    win._jrZones[#win._jrZones + 1] = z
    return z
end

-- The controller's mark options for the element with this id: set only when the
-- window is the focused one, the controller is in use and that element has the focus.
local _focusOpts = {}
local function focusOf(win, id)
    local F = ZeD.Input and ZeD.Input.Focus
    if F and F.isFocused and F.isFocused(win, nil, id) then
        _focusOpts.win = win
        return _focusOpts
    end
    return nil
end

-- The controller's mark under an element's words; true when the words must switch to
-- T.textOnFocus (the wash style).
local function markFocus(panel, win, id, x, y, w, h)
    local fo = focusOf(win, id)
    if fo then return ZeD.Focus.mark(panel, x, y, w, h, fo) end
    return false
end

-- the footer help line's words for what the pointer is over
local function help(win, text)
    if ZeD.Help and ZeD.Help.set then ZeD.Help.set(win, text) end
end

-- the pointer over (x, y, w, h) with the mouse in use, inside the tab's view
local function hoverRect(panel, win, x, y, w, h)
    local clip = st(win).clip
    if st(win).showOpen then return false end   -- (the band's Show list is open over the page)
    if clip and not inRect(clip, panel:getMouseX(), panel:getMouseY()) then return false end
    return ZeD.Atoms.mouseIn(panel, x, y, w, h)
end

-- a push button (the library's: the hover wash, the controller's mark and the footer's
-- help come with it); a disabled one is the whole button at the disabled look, and inert
local _btnOpts = {}
local function button(panel, win, id, x, y, text, fn, variant, opts)
    local T = ZeD.T
    opts = opts or {}
    local bw = opts.w or (tw(T.fontF3, ZeD.btnCase(text)) + T.sp.md * 2)
    local bh = T.buttonH
    local o = _btnOpts
    o.hover = hoverRect(panel, win, x, y, bw, bh)
    o.disabled = opts.disabled and true or false
    o.focus = focusOf(win, "jr:" .. id)
    o.win = win
    o.help = opts.help
    ZeD.Molecules.drawButton(panel, x, y, bw, bh, text, variant or "default", false, nil, o)
    zone(win, { id = id, x = x, y = y, w = bw, h = bh, fn = (not opts.disabled) and fn or nil, cancel = opts.cancel })
    return bw
end

-- the back key: an icon button with a left triangle, the same on every card and drawer
local function backButton(panel, win, id, x, y, fn)
    local T = ZeD.T
    local sz = T.buttonH
    local o = _btnOpts
    o.hover = hoverRect(panel, win, x, y, sz, sz)
    o.disabled = false
    o.focus = focusOf(win, "jr:" .. id)
    o.win = win
    o.help = ZeD.tr("UI_ZeD_Papers_HelpBack")
    ZeD.Molecules.drawBackButton(panel, x, y, sz, o)
    zone(win, { id = id, x = x, y = y, w = sz, h = sz, fn = fn, cancel = fn })
    return sz
end

-- ---------------------------------------------------------------------------
-- WHAT THE CHARACTER CARRIES (every bag, a scan every half second)
-- ---------------------------------------------------------------------------
local function scan(inv, papers, seen, books)
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        local m = P.media(it)
        if m and m.id then
            if not seen[m.id] then seen[m.id] = true; papers[#papers + 1] = { item = it, m = m } end
        elseif it:getCategory() == "Literature" and it:canBeWrite() then
            books[#books + 1] = it
        end
        if instanceof(it, "InventoryContainer") then scan(it:getInventory(), papers, seen, books) end
    end
end

local function isRead(playerObj, m)
    local ok, r = pcall(function() return playerObj:isPrintMediaRead(m.id) or playerObj:isPrintMediaRead(m.title) end)
    return ok and r or false
end

local thumbs = {}
local function flyerPic(id)
    if thumbs[id] == nil then
        thumbs[id] = getTexture("media/textures/printMedia/FlyerPics/" .. id:sub(1, 1):upper() .. id:sub(2) .. ".png") or false
    end
    return thumbs[id] or nil
end

local function gather(win, force)
    local s = st(win)
    s.frame = s.frame + 1
    if not force and s.carried and s.frame - (s.scanAt or 0) < 30 then return s.carried end
    s.scanAt = s.frame
    local p = win._playerObj
    local papers, books = {}, {}
    if p then scan(p:getInventory(), papers, {}, books) end
    for _, e in ipairs(papers) do
        e.id = e.m.id
        e.title = P.title(e.m)
        e.kind = P.kind(e.item)
        e.date = e.title:match(" %- (.+)$")
        e.read = isRead(p, e.m)
        e.places = #P.places(e.m)
    end
    -- read first, then the rest; each by name
    table.sort(papers, function(a, b)
        if a.read ~= b.read then return a.read end
        return a.title < b.title
    end)
    s.carried = { papers = papers, books = books }
    return s.carried
end

function J.refresh(win) gather(win, true) end

-- ---------------------------------------------------------------------------
-- ONE SCROLL FOR THE WHOLE SUB-TAB (never a scroll inside a scroll)
-- ---------------------------------------------------------------------------
-- draw(drawW, top) lays the content out from `top` and returns its bottom.
-- The height is last frame's (a frame late on a change: never seen).
local function framed(panel, win, key, x, y, w, h, draw)
    local T = ZeD.T
    local s = st(win)
    local sc = s.scroll
    if s.key ~= key then s.key = key; sc:setScrollPos(0); s.total = nil end
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
    local fid = J._fid
    if needs and fid and fid ~= s.pinned and s.lastZones then
        for _, z in ipairs(s.lastZones) do
            if "jr:" .. z.id == fid and not z.dpad then
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
    local top = y - off
    local bottom = draw(drawW, top)
    panel:clearStencilRect()
    s.total = math.max(1, bottom - top + T.sp.sm)
    if needs then sc:draw(panel) end
end

-- ---------------------------------------------------------------------------
-- PAPERS: the list
-- ---------------------------------------------------------------------------
local function thumb(panel, e, x, y, w, h, a)
    local tex = (e.kind == "Flyer" or e.kind == "Brochure") and flyerPic(e.id) or nil
    if tex then
        panel:drawTextureScaledAspect(tex, x, y, w, h, a, 1, 1, 1)
    else
        local pg = P.page(e.m)
        if pg then
            local k = math.min(w / pg.w, h / pg.h)
            P.drawArt(panel, pg, x + math.floor((w - pg.w * k) / 2), y + math.floor((h - pg.h * k) / 2), k, a)
        else
            panel:drawRect(x, y, w, h, a, PAPER.r, PAPER.g, PAPER.b)
        end
    end
    local bd = ZeD.T.border
    panel:drawRectBorder(x, y, w, h, bd.a * 0.5, bd.r, bd.g, bd.b)
end

local function subLine(e)
    local s = P.kindName(e.kind)
    if e.date then s = s .. " | " .. e.date end
    if e.read and e.places > 0 then s = s .. " | " .. (e.places == 1 and ZeD.tr("UI_ZeD_Papers_PlaceOne") or ZeD.tr("UI_ZeD_Papers_PlaceMany", e.places)) end
    return s
end

local function filtered(win, papers)
    local s = st(win)
    local q = string.lower(win._flyerSearchText or "")
    local out = {}
    for _, e in ipairs(papers) do
        local f = s.filter
        local ok = f == "all"
            or (f == "news" and e.kind == "Newspaper")
            or (f == "flyer" and (e.kind == "Flyer" or e.kind == "Brochure"))
            or (f == "map" and e.read and e.places > 0)
        if ok and q ~= "" and not string.lower(e.title):find(q, 1, true) then ok = false end
        if ok then out[#out + 1] = e end
    end
    return out
end

local function openPaper(win, id)
    local s = st(win)
    s.paperOpen = id
    sound("UISelectListItem")
end

local function renderPaperList(panel, win, x, y, w, h, carried)
    local T = ZeD.T
    local A = ZeD.Atoms
    local pad = ZeD.Molecules.getTabPad()
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local s = st(win)
    framed(panel, win, "papers", x, y, w, h, function(dw, top)
        local cy = top + T.sp.sm
        local lx, lw = x + pad, dw - pad * 2
        -- how many, read, with places
        local nRead, nMap = 0, 0
        for _, e in ipairs(carried.papers) do
            if e.read then nRead = nRead + 1 end
            if e.read and e.places > 0 then nMap = nMap + 1 end
        end
        local count
        if nMap > 0 then count = ZeD.tr("UI_ZeD_Papers_CountWithPlaces", nRead, #carried.papers, nMap)
        else count = ZeD.tr("UI_ZeD_Papers_Count", nRead, #carried.papers) end
        local dc = T.textDim
        panel:drawText(count, lx, cy, dc.r, dc.g, dc.b, dc.a or 1, f3)
        cy = cy + fh(f3) + T.sp.sm
        -- (the filters, four radio buttons here until Oct 30 2026, are the band's Show pop-up)
        local hv = T.hover
        A.drawDividerH(panel, x, cy, dw)
        cy = cy + T.px(1)
        local list = filtered(win, carried.papers)
        if #list == 0 then
            local msg = (#carried.papers == 0) and ZeD.tr("UI_ZeD_Papers_NoneCarried") or ZeD.tr("UI_ZeD_Papers_NoneMatch")
            cy = cy + T.px(8)
            return cy + ZeD.Molecules.drawEmptyLine(panel, lx, cy, lw, msg)
        end
        local thW, thH = T.px(36), T.px(48)
        local rowH = thH + T.px(12)
        for _, e in ipairs(list) do
            local zid = "paper:" .. e.id
            local r = { x = x, y = cy, w = dw, h = rowH }
            -- the hover wash, then the controller's mark: both under the words
            local hover = hoverRect(panel, win, r.x, r.y, r.w, r.h)
            if hover then
                panel:drawRect(r.x, r.y, r.w, r.h, hv.a, hv.r, hv.g, hv.b)
                help(win, ZeD.tr("UI_ZeD_Papers_HelpOpen", e.title))
            end
            local swapped = markFocus(panel, win, "jr:" .. zid, r.x, r.y, r.w, r.h)
            -- unread: listed, dim
            local a = e.read and 1 or T.disabledAlpha
            thumb(panel, e, lx, cy + T.px(6), thW, thH, a)
            -- the read state, right: a square and plain words (full when read, hollow when not)
            local state = e.read and ZeD.tr("UI_ZeD_Papers_StateRead") or ZeD.tr("UI_ZeD_Papers_StateUnread")
            local sw = tw(f3, state)
            local dsz = T.px(6)
            local sx = lx + lw - sw
            local tc = swapped and T.textOnFocus or T.text
            panel:drawText(state, sx, cy + T.px(8), tc.r, tc.g, tc.b, a, f3)
            local my = cy + T.px(8) + math.floor((fh(f3) - dsz) / 2)
            if e.read then A.drawStatusDot(panel, sx - dsz - T.px(5), my, T.positive, dsz)
            else A.drawStatusHollow(panel, sx - dsz - T.px(5), my, T.textDim, dsz) end
            local nx = lx + thW + T.sp.md
            local nw = sx - dsz - T.px(12) - nx
            local hi = swapped and T.textOnFocus or T.toneHi
            panel:drawText(trunc(e.title, f2, nw), nx, cy + T.px(6), hi.r, hi.g, hi.b, (hi.a or 1) * a, f2)
            local sc = swapped and T.textOnFocus or dc
            panel:drawText(trunc(subLine(e), f3, lw - thW - T.sp.md), nx, cy + T.px(8) + fh(f2), sc.r, sc.g, sc.b, (sc.a or 1) * a, f3)
            A.drawDividerH(panel, x, cy + rowH - T.px(1), dw)
            zone(win, { id = zid, x = r.x, y = r.y, w = r.w, h = r.h, fn = function() openPaper(win, e.id) end })
            cy = cy + rowH
        end
        return cy
    end)
end

-- ---------------------------------------------------------------------------
-- PAPERS: the quick look
-- ---------------------------------------------------------------------------
local function readPiece(win, e)
    local pn = win._playerObj:getPlayerNum()
    sound("UIActivateButton")
    -- vanilla's own Read (Inspect): its checks, its time; the reader opens when it ends
    ISInventoryPaneContextMenu.onLiteratureItems({ e.item }, pn)
end

-- a section head (20u, sentence case, its content line under it), not folding; returns the y under it
local function section(panel, label, x, y, w)
    local T = ZeD.T
    local hh = ZeD.Molecules.drawSectionHeader(panel, x, y, w, label, nil, true, false, nil, nil, nil, nil, true)
    return y + hh + T.px(6)
end

-- the words, in the theme's faces at a size readable in the tab
local function drawWords(panel, blocks, x, y, w)
    local T = ZeD.T
    local A = ZeD.Atoms
    local f2, f3, f4 = T.fontF2, T.fontF3, T.fontF4
    local tc, hi, dc = T.text, T.toneHi, T.textDim
    for _, b in ipairs(blocks) do
        if b.kind == "head" then
            y = y + T.px(8)
            for _, l in ipairs(A.wrapText(b.text, f4, w)) do
                panel:drawText(l, x, y, hi.r, hi.g, hi.b, hi.a or 1, f4)
                y = y + fh(f4) + T.px(2)
            end
            y = y + T.px(4)
        elseif b.kind == "pic" then
            local lines = A.wrapText(ZeD.tr("UI_ZeD_Reader_Picture", b.text), f3, w - T.px(16))
            local bh = #lines * (fh(f3) + T.px(2)) + T.px(12)
            local bs = T.borderS
            panel:drawRectBorder(x, y, w, bh, bs.a, bs.r, bs.g, bs.b)
            local yy = y + T.px(6)
            for _, l in ipairs(lines) do panel:drawText(l, x + T.px(8), yy, dc.r, dc.g, dc.b, dc.a or 1, f3); yy = yy + fh(f3) + T.px(2) end
            y = y + bh + T.px(8)
        elseif b.kind == "kicker" or b.kind == "cont" then
            for _, l in ipairs(A.wrapText(b.text, f3, w)) do
                panel:drawText(l, x, y, dc.r, dc.g, dc.b, dc.a or 1, f3)
                y = y + fh(f3) + T.px(2)
            end
            y = y + T.px(6)
        else
            local text = b.dateline and (b.dateline .. " - " .. b.text) or b.text
            local first = true
            for _, l in ipairs(A.wrapText(text, f2, w)) do
                panel:drawText(l, x, y, tc.r, tc.g, tc.b, tc.a or 1, f2)
                -- the dateline in bold: drawn again a pixel over
                if first and b.dateline then panel:drawText(b.dateline, x + 1, y, tc.r, tc.g, tc.b, tc.a or 1, f2) end
                first = false
                y = y + fh(f2) + T.px(2)
            end
            y = y + T.px(6)
        end
    end
    return y
end

local function renderPaperLook(panel, win, x, y, w, h, e)
    local T = ZeD.T
    local s = st(win)
    local pad = ZeD.Molecules.getTabPad()
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local back = function() s.paperOpen = nil; sound("UISelectListItem") end
    local p = win._playerObj
    framed(panel, win, "paper:" .. e.id, x, y, w, h, function(dw, top)
        local cy = top + T.sp.sm
        local lx, lw = x + pad, dw - pad * 2
        -- the bar: Back, the name, Open full (a piece read already)
        local bw = backButton(panel, win, "back", lx, cy, back)
        local ofw = 0
        if e.read then
            local label = ZeD.tr("UI_ZeD_Papers_OpenFull")
            ofw = tw(f3, ZeD.btnCase(label)) + T.sp.md * 2
            button(panel, win, "full", lx + lw - ofw, cy, label, function()
                ZeD.Reader.openPrint(p, e.item)
            end, "default", { cancel = back })
        end
        local hi = T.toneHi
        local tx = lx + bw + T.sp.md
        panel:drawText(trunc(e.title, f2, lx + lw - ofw - T.sp.md - tx), tx, cy + math.floor((T.buttonH - fh(f2)) / 2), hi.r, hi.g, hi.b, hi.a or 1, f2)
        cy = cy + T.buttonH + T.sp.md
        -- the page small, and what it is beside it
        local pg = P.page(e.m)
        local thW = math.min(T.px(220), math.floor(lw * 0.45))
        local thH = pg and math.floor(thW * pg.h / pg.w) or math.floor(thW * 1.4)
        if pg and e.read then P.draw(panel, pg, lx, cy, thW / pg.w) else thumb(panel, e, lx, cy, thW, thH, 1) end
        local bd = T.border
        panel:drawRectBorder(lx, cy, thW, thH, bd.a * 0.5, bd.r, bd.g, bd.b)
        local rx = lx + thW + T.sp.md
        local rw = lx + lw - rx
        local ry = section(panel, ZeD.tr("UI_ZeD_Reader_HeadPiece"), rx, cy, rw)
        local ac, tc = T.textDim, T.text
        local function kv(k, v, dot)
            panel:drawText(ZeD.textCase(k), rx, ry + T.px(2), ac.r, ac.g, ac.b, ac.a or 1, f1)
            local vx = rx + T.px(52)
            if dot then
                local dsz = T.px(6)
                ZeD.Atoms.drawStatusDot(panel, vx, ry + math.floor((fh(f2) - dsz) / 2), dot, dsz)
                vx = vx + dsz + T.px(6)
            end
            panel:drawText(trunc(v, f2, rx + rw - vx), vx, ry, tc.r, tc.g, tc.b, tc.a or 1, f2)
            ry = ry + fh(f2) + T.px(5)
        end
        kv(ZeD.tr("UI_ZeD_Reader_LabelKind"), P.kindName(e.kind))
        if e.date then kv(ZeD.tr("UI_ZeD_Reader_LabelDate"), e.date) end
        kv(ZeD.tr("UI_ZeD_Reader_LabelRead"), e.read and getText("UI_Yes") or ZeD.tr("UI_ZeD_Reader_NotYet"), e.read and T.positive or T.textDim)
        ry = ry + T.sp.sm
        if not e.read then
            -- reading is vanilla's action: light, time, then the words and the places
            local dark = p:tooDarkToRead()
            button(panel, win, "read", rx, ry, getText("ContextMenu_Read"), function() readPiece(win, e) end, "primary",
                { disabled = dark, cancel = back, help = ZeD.tr("UI_ZeD_Papers_HelpRead") })
            ry = ry + T.buttonH + T.px(4)
            if dark then
                -- why it is greyed: one NEEDS line
                ry = ry + ZeD.Molecules.drawNeedsLine(panel, rx, ry, rw, ZeD.tr("UI_ZeD_Papers_TooDark")) + T.px(2)
            end
        elseif e.places > 0 then
            ry = section(panel, ZeD.tr("UI_ZeD_Reader_HeadPlaces"), rx, ry + T.sp.sm, rw)
            local places = P.places(e.m)
            for i, loc in ipairs(places) do
                local label = (#places == 1) and ZeD.tr("UI_ZeD_Reader_ShowOnMap") or ZeD.tr("UI_ZeD_Papers_ShowPlaceN", i)
                button(panel, win, "place:" .. i, rx, ry, label, function()
                    P.showOnMap(p, loc)
                end, "primary", { cancel = back })
                ry = ry + T.buttonH + T.px(4)
            end
        end
        cy = math.max(cy + thH, ry) + T.sp.md
        if not e.read then return cy end
        -- the words (vanilla's Print_Text): the stories as headings and paragraphs
        local blocks = P.words(e.m)
        if #blocks == 0 then return cy end
        local heads = P.headlines(pg)
        local label = ZeD.tr("UI_ZeD_Papers_HeadWords")
        if #heads > 1 then label = ZeD.tr("UI_ZeD_Papers_HeadStories", #heads) end
        cy = section(panel, label, lx, cy, lw)
        local wordsTop = cy
        cy = drawWords(panel, blocks, lx, cy, lw)
        -- (the controller scrolls the words with the D-pad from here)
        zone(win, { id = "words", x = x, y = math.max(wordsTop, s.clip.y), w = dw, h = math.min(cy, s.clip.y + s.clip.h) - math.max(wordsTop, s.clip.y), cancel = back,
            dpad = function(dir)
                local sc = s.scroll
                if dir == "down" and sc.scrollPos < 1 then sc:setScrollPos(sc.scrollPos + 0.08); return true end
                if dir == "up" and sc.scrollPos > 0 then sc:setScrollPos(sc.scrollPos - 0.08); return true end
                return false
            end })
        return cy
    end)
end

-- ---------------------------------------------------------------------------
-- PAPERS: the band (Oct 30 2026, punch list 21): Show (All, News, Flyers, On map)
-- as a System 7 pop-up menu at the left; its list opens upward over the page.
-- In a quick look the box is greyed (the list is not shown).
-- ---------------------------------------------------------------------------
local SHOW_MODES = {}   -- the Show list's choices {id, label}: made once, labels refreshed
local _papersBand = {}
local _showListOpts = {}

local function showModes()
    for i, f in ipairs(FILTERS) do
        local m = SHOW_MODES[i] or {}
        SHOW_MODES[i] = m
        m.id, m.label = f.id, ZeD.textCase(ZeD.tr(f.key))
    end
    return SHOW_MODES
end

-- the Show box's width: the longest choice it can carry (the band keeps its shape); kept
-- per scale, font and language
local function showBoxW(s, modes)
    local T = ZeD.T
    local c = s.showW
    local lang = ZeD.trTestOn() and 1 or 0
    if c and c.scale == T.scale and c.font == T.fontF1 and c.lang == lang then return c.w end
    local w = 0
    for _, m in ipairs(modes) do w = math.max(w, ZeD.Molecules.popupMenuW(ZeD.tr("UI_ZeD_Craft_ShowToggle", m.label))) end
    s.showW = { scale = T.scale, font = T.fontF1, lang = lang, w = w }
    return w
end

-- shut the Show list; the controller goes back to its box
local function closeShow(s)
    s.showOpen, s.showZones = nil, nil
    s.land = "jr:show"
end

local function drawPapersBand(panel, win, x, y, w, frozen)
    local T, M, A = ZeD.T, ZeD.Molecules, ZeD.Atoms
    local s = st(win)
    _papersBand.win = win
    M.drawBand(panel, x, y, w, _papersBand)
    local modes = showModes()
    local bh = T.buttonH
    local bx, by = x + T.px(8), y + T.px(5)
    local bw = math.min(showBoxW(s, modes), w - T.px(16))
    if frozen then s.showOpen, s.showZones = nil, nil end
    local open = s.showOpen == true
    local F = ZeD.Input and ZeD.Input.Focus
    local cues = F and F.cuesVisible and F.cuesVisible() or false
    local hov = (not frozen) and (not open) and (not cues) and A.mouseIn(panel, bx, by, bw, bh)
    if hov then help(win, ZeD.tr("UI_ZeD_Papers_HelpShow")) end
    local cur = ""
    for _, m in ipairs(modes) do if m.id == s.filter then cur = m.label end end
    M.drawPopupMenu(panel, bx, by, bw, bh, ZeD.tr("UI_ZeD_Craft_ShowToggle", cur), hov or open,
        (not frozen) and focusOf(win, "jr:show") or nil, frozen)
    if frozen then return end
    zone(win, { id = "show", x = bx, y = by, w = bw, h = bh, fixed = true, fn = function() s.showOpen = true end })
    if not open then return end
    -- the list, open: last, upward from the box (the page's band is at its foot)
    local hoverId = nil
    if not cues then
        local mx, my = panel:getMouseX(), panel:getMouseY()
        for _, z in ipairs(s.showZones or {}) do
            if mx >= z.x and mx < z.x + z.w and my >= z.y and my < z.y + z.h then hoverId = z.id; break end
        end
    end
    local mo = _showListOpts
    mo.minW, mo.focusId, mo.focus = bw, nil, nil
    for _, m in ipairs(modes) do
        local f = focusOf(win, "jr:showRow:" .. m.id)
        if f then mo.focusId, mo.focus = m.id, f; break end
    end
    local _, _, zs = M.drawSortMenuList(panel, bx, by - M.popupListH(#modes), modes, s.filter, hoverId, mo)
    s.showZones = zs
    for _, z in ipairs(zs) do
        local fid = z.id
        zone(win, { id = "showRow:" .. fid, x = z.x, y = z.y, w = z.w, h = z.h, fixed = true, row = true,
            fn = function() s.filter = fid; s.scroll:setScrollPos(0); closeShow(s) end,
            cancel = function() closeShow(s) end })
    end
end

function J.renderPapers(panel, win, x, y, w, h)
    J._fid = focusedId(win)
    local s = st(win)
    local carried = gather(win)
    -- the page above its band
    local bodyH = h - ZeD.Molecules.bandH()
    local look = nil
    if s.paperOpen then
        for _, e in ipairs(carried.papers) do
            if e.id == s.paperOpen then look = e; break end
        end
        if not look then s.paperOpen = nil end   -- (put down or dropped: back to the list)
    end
    if look then renderPaperLook(panel, win, x, y, w, bodyH, look)
    else renderPaperList(panel, win, x, y, w, bodyH, carried) end
    drawPapersBand(panel, win, x, y + bodyH, w, look ~= nil)
end

-- the band's Show list is open (its rows alone hold the controller) / shut it
function J.listOpen(win)
    local s = st(win)
    return s.showOpen == true and s.showZones ~= nil
end
function J.shutList(win)
    local s = st(win)
    s.showOpen, s.showZones = nil, nil
end

-- ---------------------------------------------------------------------------
-- NOTEBOOKS
-- ---------------------------------------------------------------------------
local function noteField(win)
    if win._jrNote then return win._jrNote end
    local T = ZeD.T
    local e = ZeD_TextEntry:new(0, 0, T.px(200), T.px(40), "")
    e.maxLines = 2
    e.maxLength = N.LETTERS * 2
    e:initialise()
    e:setVisible(false)
    win._drawerPanel:addChild(e)
    e.onSubmit = function() J.writeNote(win) end
    win._jrNote = e
    return e
end

-- the book shown, and its page
local function current(win, books)
    local s = st(win)
    local q = string.lower(win._flyerSearchText or "")
    local list = {}
    for _, b in ipairs(books) do
        local ok = true
        if q ~= "" then
            ok = string.lower(b:getName()):find(q, 1, true) ~= nil
            if not ok then
                for i = 1, b:getPageToWrite() do
                    if string.lower(N.page(b, i)):find(q, 1, true) then ok = true; break end
                end
            end
        end
        if ok then list[#list + 1] = b end
    end
    local sel = nil
    for _, b in ipairs(list) do if b:getID() == s.nbId then sel = b end end
    sel = sel or list[1]
    s.nbId = sel and sel:getID() or nil
    return list, sel
end

local function pageOf(win, b)
    local s = st(win)
    local id = b:getID()
    if not s.nbPage[id] then s.nbPage[id] = math.max(1, N.lastWritten(b)) end
    s.nbPage[id] = math.max(1, math.min(b:getPageToWrite(), s.nbPage[id]))
    return s.nbPage[id]
end

function J.writeNote(win)
    local s = st(win)
    local p = win._playerObj
    local books = gather(win).books
    local _, b = current(win, books)
    local e = win._jrNote
    if not (b and e) then return end
    local text = (e:getText() or ""):gsub("\n", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then e:focus(); return end
    local why = N.why(p, b)
    if why then s.msg = why; return end
    local page = pageOf(win, b)
    if not N.fits(N.append(N.page(b, page), text)) then s.msg = ZeD.tr("UI_ZeD_Notebook_NoRoomPage"); return end
    s.msg = nil
    sound("UIActivateButton")
    s.pending = N.write(p, b, page, text, function()
        if win._jrNote then win._jrNote:clear() end
        s.pending = nil
    end)
end

local function bookSub(p, b)
    local kind = N.kind(b)
    local n, all = N.pagesWritten(b), b:getPageToWrite()
    if N.otherLock(p, b) then return n == 1 and ZeD.tr("UI_ZeD_Notebook_SubLockedOne") or ZeD.tr("UI_ZeD_Notebook_SubLockedMany", n) end
    if n == 0 then return ZeD.tr("UI_ZeD_Notebook_SubBlank", kind, all) end
    return ZeD.tr("UI_ZeD_Notebook_SubWritten", kind, n, all)
end

-- the page small: ruled paper with its margin, the writing in ink; as tall as its
-- writing and two more rules (the quick note under it stays in view in a short drawer)
local function miniPage(panel, b, page, x, y, w)
    local T = ZeD.T
    local f = T.fontF2
    local lh = fh(f) + T.px(6)
    local text = N.page(b, page)
    local margin = T.px(28)
    local lines = {}
    for l in (text .. "\n"):gmatch("(.-)\n") do
        if l == "" then lines[#lines + 1] = ""
        else for _, wl in ipairs(ZeD.Atoms.wrapText(l, f, w - margin - T.px(12))) do lines[#lines + 1] = wl end end
    end
    if text == "" then lines = {} end
    local rows = math.max(4, math.min(N.LINES, #lines + 2), #lines)
    local ph = T.px(10) + rows * lh + T.px(10)
    panel:drawRect(x, y, w, ph, 1, PAPER.r, PAPER.g, PAPER.b)
    panel:drawRect(x + margin, y, T.px(1), ph, 1, MARGIN.r, MARGIN.g, MARGIN.b)
    for i = 1, rows do
        panel:drawRect(x + margin + T.px(1), y + T.px(10) + lh * i - T.px(1), w - margin - T.px(1), T.px(1), 1, RULE.r, RULE.g, RULE.b)
    end
    for i, l in ipairs(lines) do
        panel:drawText(l, x + margin + T.px(6), y + T.px(10) + lh * (i - 1) + (lh - fh(f)) - T.px(3), INK.r, INK.g, INK.b, 1, f)
    end
    return ph
end

function J.renderNotebooks(panel, win, x, y, w, h)
    local T = ZeD.T
    J._fid = focusedId(win)
    local s = st(win)
    local p = win._playerObj
    local carried = gather(win)
    local list, b = current(win, carried.books)
    local field = noteField(win)
    local pad = ZeD.Molecules.getTabPad()
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local fieldShown = false
    framed(panel, win, "notebooks", x, y, w, h, function(dw, top)
        local cy = top + T.sp.sm
        local lx, lw = x + pad, dw - pad * 2
        if #list == 0 then
            local msg = (#carried.books == 0) and ZeD.tr("UI_ZeD_Notebook_NoneCarried") or ZeD.tr("UI_ZeD_Notebook_NoneMatch")
            cy = cy + T.px(8)
            return cy + ZeD.Molecules.drawEmptyLine(panel, lx, cy, lw, msg)
        end
        -- the books: side by side with the page when the drawer is wide, above it when not
        local split = dw >= T.px(560)
        local listW = split and T.px(200) or dw
        local rowH = fh(f2) + fh(f3) + T.px(14)
        local ly = cy
        local ac, hi, dc = T.accent, T.toneHi, T.textDim
        for _, nb in ipairs(list) do
            local zid = "book:" .. nb:getID()
            local r = { x = x, y = ly, w = listW, h = rowH }
            -- the picked book: the one accent wash; the hover wash over it; the controller's mark
            if nb == b then panel:drawRect(r.x, r.y, r.w, r.h, T.selectionA or 0.30, ac.r, ac.g, ac.b) end
            local hover = hoverRect(panel, win, r.x, r.y, r.w, r.h)
            if hover then
                local hv = T.hover
                panel:drawRect(r.x, r.y, r.w, r.h, hv.a, hv.r, hv.g, hv.b)
                help(win, ZeD.tr("UI_ZeD_Notebook_HelpPick", nb:getName()))
            end
            local swapped = markFocus(panel, win, "jr:" .. zid, r.x, r.y, r.w, r.h)
            local nc = swapped and T.textOnFocus or hi
            local sc = swapped and T.textOnFocus or dc
            panel:drawText(trunc(nb:getName(), f2, listW - pad * 2), x + pad, ly + T.px(6), nc.r, nc.g, nc.b, nc.a or 1, f2)
            panel:drawText(trunc(bookSub(p, nb), f3, listW - pad * 2), x + pad, ly + T.px(8) + fh(f2), sc.r, sc.g, sc.b, sc.a or 1, f3)
            ZeD.Atoms.drawDividerH(panel, x, ly + rowH - T.px(1), listW)
            local id = nb:getID()
            zone(win, { id = zid, x = r.x, y = r.y, w = r.w, h = r.h, fn = function()
                s.nbId = id; s.msg = nil; sound("UISelectListItem")
            end })
            ly = ly + rowH
        end
        local px, pw, py
        if split then
            px, pw, py = x + listW + T.sp.md, dw - listW - T.sp.md - pad, cy
        else
            px, pw, py = lx, lw, ly + T.sp.md
        end
        -- the page bar: < Page n of N >, Open full
        local page = pageOf(win, b)
        local all = b:getPageToWrite()
        local bx = px
        bx = bx + button(panel, win, "prev", bx, py, "<", function() s.nbPage[b:getID()] = page - 1; s.msg = nil end, "default", { disabled = page <= 1 }) + T.px(6)
        local pl = ZeD.tr("UI_ZeD_Reader_PageOf", page, all)
        panel:drawText(pl, bx, py + math.floor((T.buttonH - fh(f3)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f3)
        bx = bx + tw(f3, pl) + T.px(6)
        button(panel, win, "next", bx, py, ">", function() s.nbPage[b:getID()] = page + 1; s.msg = nil end, "default", { disabled = page >= all })
        local other = N.otherLock(p, b)
        local editable = N.hasWritingTool(p) and not other
        local canOpen = editable or not b:isEmptyPages()
        local fl = ZeD.tr("UI_ZeD_Papers_OpenFull")
        local fw = tw(f3, ZeD.btnCase(fl)) + T.sp.md * 2
        button(panel, win, "full", px + pw - fw, py, fl, function()
            ISInventoryPaneContextMenu.onWriteSomething(b, editable, p:getPlayerNum())
        end, "default", { disabled = not canOpen or p:tooDarkToRead() })
        py = py + T.buttonH + T.sp.sm
        py = py + miniPage(panel, b, page, px, py, pw) + T.sp.sm
        -- the quick note: a line onto this page
        local why = N.why(p, b)
        local wl = ZeD.tr("UI_ZeD_Notebook_Write")
        local ww = tw(f3, ZeD.btnCase(wl)) + T.sp.md * 2
        local fh2 = T.px(40)
        local fr = { x = px, y = py, w = pw - ww - T.sp.sm, h = fh2 }
        field.placeholder = ZeD.tr("UI_ZeD_Notebook_AddLine", page)
        if fr.x ~= field.x or fr.y ~= field.y then field:setX(fr.x); field:setY(fr.y) end
        if fr.w ~= field.width or fr.h ~= field.height then field:setWidth(fr.w); field:setHeight(fr.h) end
        local bs = T.borderS
        panel:drawRectBorder(fr.x, fr.y, fr.w, fr.h, bs.a, bs.r, bs.g, bs.b)
        -- (the field shows only whole, inside the tab's view)
        fieldShown = why == nil and fr.y >= s.clip.y and fr.y + fr.h <= s.clip.y + s.clip.h
        local writing = s.pending and ISTimedActionQueue.hasAction(s.pending)
        if not writing then s.pending = nil end
        button(panel, win, "write", px + pw - ww, py, wl, function() J.writeNote(win) end, "primary", { disabled = why ~= nil or writing })
        py = py + fh2 + T.px(6)
        -- the line under it: why not, or what is left
        local status
        if writing then status = ZeD.tr("UI_ZeD_Notebook_Writing")
        elseif s.msg then status = s.msg
        elseif why then status = why
        else
            local left = N.LINES - N.linesOf(N.page(b, page))
            status = (left == 1) and ZeD.tr("UI_ZeD_Notebook_ReadyOne") or ZeD.tr("UI_ZeD_Notebook_ReadyMany", left)
        end
        panel:drawText(trunc(status, f3, pw), px, py, dc.r, dc.g, dc.b, dc.a or 1, f3)
        py = py + fh(f3)
        return math.max(ly, py)
    end)
    field:setVisible(fieldShown)
    if not fieldShown and field._entry and field._entry:isFocused() then field._entry:unfocus() end
end

-- the drawer's children follow the sub-tab (called every frame by the Character window)
function J.syncChildren(win, onNotebooks)
    if not onNotebooks and win._jrNote and win._jrNote:isVisible() then
        if win._jrNote._entry then win._jrNote._entry:unfocus() end
        win._jrNote:setVisible(false)
    end
end

-- the search box's words for the sub-tab
function J.searchHint(sub)
    if sub == 2 then return ZeD.tr("UI_ZeD_Notebook_Find") end
    return ZeD.tr("UI_ZeD_Papers_Find")
end

-- the search box shows on the lists, not in a quick look
function J.searchVisible(win, sub)
    if sub == 3 then return not st(win).paperOpen end
    return sub == 2
end

-- ---------------------------------------------------------------------------
-- THE LOG BOX'S "INTO" (the Journal sub-tab's Save)
-- ---------------------------------------------------------------------------
local function logBook(win)
    local s = st(win)
    if not s.logInto then return nil end
    for _, b in ipairs(gather(win).books) do
        if b:getID() == s.logInto then return b end
    end
    s.logInto = nil   -- (no longer carried: the log only)
    return nil
end

-- the picker, a push button left of Save (it cycles the log only, then each carried
-- notebook); returns its width
function J.drawLogInto(panel, win, x, y, maxW, h)
    local T = ZeD.T
    J._fid = J._fid or focusedId(win)
    local s = st(win)
    local books = gather(win).books
    if #books == 0 then s.logInto = nil; return 0 end
    local b = logBook(win)
    local label = ZeD.tr("UI_ZeD_Notebook_Into", b and b:getName() or ZeD.tr("UI_ZeD_Notebook_LogOnly"))
    local f3 = T.fontF3
    local pw = math.min(maxW, ZeD.Molecules.buttonW(label))
    local o = _btnOpts
    o.hover = ZeD.Atoms.mouseIn(panel, x, y, pw, h)
    o.disabled = false
    o.focus = focusOf(win, "jr:into")
    o.win = win
    o.help = ZeD.tr("UI_ZeD_Notebook_HelpInto")
    ZeD.Molecules.drawButton(panel, x, y, pw, h, trunc(label, f3, pw - T.sp.md * 2), b ~= nil and "primary" or "default", false, nil, o)
    zone(win, { id = "into", x = x, y = y, w = pw, h = h, fn = function()
        -- the log only, then each carried notebook in turn
        local nextId = nil
        if not b then nextId = books[1]:getID()
        else
            for i, nb in ipairs(books) do
                if nb == b then nextId = books[i + 1] and books[i + 1]:getID() or nil; break end
            end
        end
        s.logInto = nextId
        s.logMsg = nil
        sound("UISelectListItem")
    end })
    -- why the last Save did not write, or that it is writing
    local note = nil
    if s.logPending and ISTimedActionQueue.hasAction(s.logPending) then note = ZeD.tr("UI_ZeD_Notebook_Writing")
    else s.logPending = nil; note = s.logMsg end
    if note then
        local dc = T.textDim
        local f3 = T.fontF3
        panel:drawText(trunc(note, f3, maxW - pw - T.sp.sm), x + pw + T.sp.sm, y + math.floor((h - fh(f3)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f3)
    end
    return pw
end

-- a log entry, as the Journal's Save makes it; `source` names where it was written too
function J.addLogEntry(win, text, source)
    local gt = getGameTime()
    local md = win._playerObj:getModData()
    md.ZeD_Journal = md.ZeD_Journal or { entries = {} }
    md.ZeD_Journal.entries = md.ZeD_Journal.entries or {}
    local survDay = math.floor((win._playerObj:getHoursSurvived() or 0) / 24) + 1
    table.insert(md.ZeD_Journal.entries, 1, {
        month  = gt:getMonth(),
        day    = gt:getDay(),
        year   = gt:getYear(),
        hour   = gt:getHour(),
        minute = math.floor((gt:getTimeOfDay() % 1) * 60),
        survivalDay = survDay,
        text   = text,
        source = source,
    })
    win._journalCache = nil
end

-- Save with a notebook picked: the character writes it there, then the log keeps it.
-- Returns true when it took the save (written, writing, or why not shown).
function J.saveLog(win, text)
    local s = st(win)
    local b = logBook(win)
    if not b then return false end
    local p = win._playerObj
    text = text:gsub("\n", " "):gsub("^%s+", ""):gsub("%s+$", "")
    local why = N.why(p, b)
    if why then s.logMsg = why; return true end
    local page = N.pageFor(b, text)
    if not page then s.logMsg = ZeD.tr("UI_ZeD_Notebook_NoRoomIn", b:getName()); return true end
    s.logMsg = nil
    local name = b:getName()
    s.logPending = N.write(p, b, page, text, function(pg)
        J.addLogEntry(win, text, { name = name, page = pg })
        if win._journalInput then win._journalInput:clear() end
    end)
    return true
end

-- ---------------------------------------------------------------------------
-- INPUT (routed by the Character window's drawer)
-- ---------------------------------------------------------------------------
function J.onClick(win, x, y)
    -- the Journal's delete question (a band at the foot of the log) takes its own buttons
    local JT = ZeD.JournalTab
    if JT and JT.onAskClick and JT.onAskClick(win, x, y) then return true end
    local zs = win._jrZones
    if not zs then return false end
    local s = st(win)
    -- the band's Show list open (Papers): it takes every click (a choice, or shut)
    if s.showOpen and (win._journalSubTab or 1) == 3 then
        for i = #zs, 1, -1 do
            local z = zs[i]
            if z.row and z.fn and inRect(z, x, y) then z.fn(); return true end
        end
        closeShow(s)
        return true
    end
    for i = #zs, 1, -1 do
        local z = zs[i]
        -- (the band's and Into's zones are outside the page's scrolling view)
        if z.fn and inRect(z, x, y) and (not s.clip or inRect(s.clip, x, y) or z.id == "into" or z.fixed) then
            z.fn()
            return true
        end
    end
    return false
end

-- the controller's elements (ids "jr:..."): every live zone; B goes back in a quick look.
-- The band's Show list open: its rows alone (the current choice first); shut, the focus
-- lands back on its box.
function J.focusables(win)
    local out = {}
    local s = st(win)
    local rowsOnly = J.listOpen(win)
    for _, z in ipairs(win._jrZones or {}) do
        if (z.fn or z.dpad) and ((z.row == true) == rowsOnly) then
            local el = {
                x = z.x, y = z.y, w = z.w, h = z.h,
                id = "jr:" .. z.id,
                onFocus = function() end,
            }
            if z.fn then el.onActivate = function() z.fn() end end
            if z.cancel then el.onCancel = function() z.cancel() end end
            if z.dpad then
                el.isGridScroll = true
                el.onDpadDir = function(w, e, dir) return z.dpad(dir) end
            end
            out[#out + 1] = el
        end
    end
    -- where the focus lands: the current choice in the open list; back on the box after it
    local land = rowsOnly and ("jr:showRow:" .. tostring(s.filter)) or s.land
    if land then
        for i, e in ipairs(out) do
            if e.id == land then out._focusIdx = i; break end
        end
        if not rowsOnly and #out > 0 then s.land = nil end
    end
    -- (Oct 30 2026, punch list 21 a-f: the open Show list is modal: Up / Down stop at its ends)
    if rowsOnly and #out > 0 then out._menuRows = true end
    return out
end

-- rebuild the controller's elements when the view scrolls or changes
function J.scrollKey(win)
    local s = st(win)
    return tostring(s.key) .. ":" .. tostring(s.scroll.scrollPos) .. ":" .. tostring(s.nbId) .. ":" .. tostring(s.filter)
        .. ":" .. tostring(s.showOpen) .. ":" .. tostring(s.paperOpen)
end

-- the log box's Into shows (a notebook is carried to write in)
function J.intoShown(win)
    return #gather(win).books > 0
end

-- each frame: zones start empty (the renderers stamp them); last frame's kept for the scroll-follow
function J.beginFrame(win)
    local s = st(win)
    s.lastZones = win._jrZones
    win._jrZones = {}
    J._fid = focusedId(win)
end
