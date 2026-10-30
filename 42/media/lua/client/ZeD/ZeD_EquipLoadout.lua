-- ZeD-UI/42/media/lua/client/ZeD/ZeD_EquipLoadout.lua
-- ============================================================================
-- THE EQUIP TAB'S LOADOUTS: THE BAR, THE GHOSTS, THE TO-DO (handoff
-- equip_doll_v4_loadouts, parts B4 and B6; mockup frames r2_03, r2_04, r2_05,
-- r2_07; the director: "Loadout lists should live in the journal tab. They can
-- be applied/stocked in the equipment tab")
--
--   * The bar under Equipped (both views, rows of 38 units on surface 2): the
--     outfit (a check when every piece is worn), the loadout, the days (1 to 30),
--     "ready 4 of 9" (it opens the to-do), Restock with its total time (Unpack
--     when you are home from a trip), Save (what I wear as an outfit, what I
--     carry as a loadout). Nothing picked: "No outfit", "No loadout" and a dim
--     line. The full card (480 units) holds it in two rows.
--   * What's missing shows where it goes: each unmet line with a place on the
--     doll draws its item faint (36%) in a dashed accent box (EquipDoll asks
--     EL.ghosts / EL.drawGhost).
--   * The to-do opens in the drawer where the item card opens, at the full card
--     (480), with the card's back key: Restock (the default), Open in Journal,
--     Unpack (dim until you're home). The title (the loadout, "loadout | 9
--     lines", < 1 of 3 >), Applied, Load after restock (the game's carried
--     weight against what you can carry, the limit marked), the restock way, and
--     To do: a line each in one of five states (an icon and plain words). A long
--     trip shows the supplies as a table (What, Rule, Need, Have) above the gear,
--     and over the limit says by how much, the heaviest supply and the most days
--     that fit, with Make it N days. Home from a trip: Loot, Leftovers, Stays on
--     you. Taking the last of something asks first, in the band at the foot.
-- The columns of the wider mockup stack at 480. One scroll for the to-do.
-- Hit zones stamped each frame into win._elZones (drawer coords); the Character
-- window routes clicks, the wheel and the controller (ids "el:...") here.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/ZeD_Lists"
require "ZeD/ZeD_ListsMenu"
require "ZeD/ZeD_Restock"

ZeD = ZeD or {}
ZeD.EquipLoadout = ZeD.EquipLoadout or {}
local EL = ZeD.EquipLoadout
local L = ZeD.Lists
local R = ZeD.Restock

local BAR_ROW = 38      -- design units: a row of the bar
local SEL_W   = 140     -- a drop-down on the bar
local ROW_H   = 34      -- a to-do line
local TROW_H  = 24      -- a long trip's table row
local GHOST_A = 0.36    -- a missing item's picture

local function fh(f) return ZeD.TM:getFontHeight(f) end
local function tw(f, s) return ZeD.TM:MeasureStringX(f, s) end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(n) pcall(function() getSoundManager():playUISound(n or "UIActivateButton") end) end
local function trunc(s, f, w) return ZeD.Atoms.truncateText(s or "", f, math.max(0, w)) end
local function kg(v) return string.format("%.1f", v or 0) end

-- the Equip tab's own state on the window
local function st(win)
    if not win._el then
        win._el = { todo = false, scroll = ZeD_ScrollbarState:new(), fold = {}, planMs = 0 }
    end
    return win._el
end
EL.state = st
EL.pending = EL.pending or {}   -- per player: open the to-do when the Equip tab next draws (the wheel)

local function player(win) return win and win._playerObj end
local function pnum(win) return (ZeD.playerNumOf and ZeD.playerNumOf(win)) or (win and win.playerNum) or 0 end

local function zone(win, z)
    win._elZones = win._elZones or {}
    win._elZones[#win._elZones + 1] = z
    return z
end

-- the controller's mark options for element "el:<id>" (the window focused, the pad in the tab)
local _focusOpts = {}
local function focusOf(win, id)
    if win._gpFocusedEquipSlot ~= "el:" .. id then return nil end
    local F = ZeD.Input and ZeD.Input.Focus
    local z = F and F.liveZone and F.liveZone(win)
    if not (z and z.zone == "charTabContent") then return nil end
    _focusOpts.win, _focusOpts.zone = win, "charTabContent"
    return _focusOpts
end
local function markFocus(panel, win, id, x, y, w, h)
    local fo = focusOf(win, id)
    if fo then return ZeD.Focus.mark(panel, x, y, w, h, fo) end
    return false
end

local function help(win, text) if ZeD.Help and ZeD.Help.set then ZeD.Help.set(win, text) end end

-- the pointer over (x, y, w, h), inside the to-do's view while it shows
local function hoverRect(panel, win, x, y, w, h)
    local s = st(win)
    if s.todo and s.clip and s.inView and not inRect(s.clip, panel:getMouseX(), panel:getMouseY()) then return false end
    if s.ask and s.inView then return false end
    return ZeD.Atoms.mouseIn(panel, x, y, w, h)
end

-- a push button (the library's); returns its width
local _btnOpts = {}
local function button(panel, win, id, x, y, text, fn, variant, opts)
    local T = ZeD.T
    opts = opts or {}
    local bw = opts.w or ZeD.Molecules.buttonW(text)
    local bh = opts.h or T.buttonH
    local o = _btnOpts
    o.hover = hoverRect(panel, win, x, y, bw, bh)
    o.disabled = opts.disabled and true or false
    o.focus = focusOf(win, id)
    o.win = win
    o.help = opts.help
    ZeD.Molecules.drawButton(panel, x, y, bw, bh, text, variant or "default", false, opts.colors, o)
    zone(win, { id = id, x = x, y = y, w = bw, h = bh, fn = (not opts.disabled) and fn or nil, keep = opts.disabled })
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
local function itemTex(it) return it and (R.call(it, "getTex") or R.call(it, "getTexture")) or nil end

-- a small menu of words at (sx, sy) on the screen (the context list's look)
local function menuAt(win, sx, sy, rows)
    local m = ZeD_ContextList:new(pnum(win), "cursor", sx, sy, nil, rows, nil)
    m.noHead = true
    m:initialise()
    m:open()
    EL.menu = m
    return m
end
local function menuUnder(panel, win, z)
    return panel:getAbsoluteX() + z.x, panel:getAbsoluteY() + z.y + z.h + ZeD.T.px(1)
end

-- ---------------------------------------------------------------------------
-- THE PLAN (kept a second, or until the lists or the applied ones change)
-- ---------------------------------------------------------------------------
function EL.plan(win, force)
    local s = st(win)
    local p = player(win)
    if not p then return nil end
    local now = getTimestampMs()
    if force or not s.plan or s.planR ~= R.gen or s.planL ~= L.gen or now - s.planMs > 1000 then
        local ok, plan = pcall(R.plan, p, {})
        if not ok then
            if ZeD.logOnce then ZeD.logOnce("restock plan", plan) end
            plan = nil
        end
        s.plan, s.planR, s.planL, s.planMs = plan, R.gen, L.gen, now
        -- ready n of m (the loadout's lines on you in their place), the outfit's pieces worn, the load
        s.readyN, s.readyM, s.wornN, s.wornM = 0, 0, 0, 0
        for _, row in ipairs(plan and plan.rows or {}) do
            if row.list.kind == "outfit" then
                s.wornM = s.wornM + 1
                if row.state == "on" then s.wornN = s.wornN + 1 end
            else
                s.readyM = s.readyM + 1
                if row.state == "on" then s.readyN = s.readyN + 1 end
            end
        end
        if plan then
            local okL, ld = pcall(R.load, p, plan)
            s.load = okL and ld or nil
            local okO, ov = pcall(R.overLimit, p, plan)
            s.over = okO and ov or nil
        end
        s.home = R.homeNow(p)
        if s.home then
            local ok2, up = pcall(R.unpackPlan, p)
            s.unpack = ok2 and up or nil
            s.unpackSecs = (ok2 and up) and R.jobsSecs(p, R.unpackJobs(p, up), R.mode() == "accessible") or 0
        else
            s.unpack = nil
        end
    end
    return s.plan
end

local function runOf(win)
    local run = R.runs[pnum(win)]
    return run
end
local function running(win)
    local run = runOf(win)
    return run and not run.done
end

-- ---------------------------------------------------------------------------
-- ACTIONS
-- ---------------------------------------------------------------------------
local function pickList(panel, win, z, kind)
    local p = player(win)
    local o, lo = R.current(p)
    local cur = (kind == "outfit") and o or lo
    local rows = {}
    rows[#rows + 1] = { name = ZeD.tr(kind == "outfit" and "UI_ZeD_EqBar_NoOutfit" or "UI_ZeD_EqBar_NoLoadout"), category = "n",
        check = function() return cur == nil end,
        onFire = function() if kind == "outfit" then R.setOutfit(p, nil) else R.setLoadout(p, nil) end end }
    for _, l in ipairs(L.all(p, kind)) do
        local id = l.id
        rows[#rows + 1] = { name = l.name, category = "l", note = function() return tostring(#l.lines) end,
            check = function() return cur ~= nil and cur.id == id end,
            onFire = function() if kind == "outfit" then R.setOutfit(p, id) else R.setLoadout(p, id) end end }
    end
    local sx, sy = menuUnder(panel, win, z)
    menuAt(win, sx, sy, rows)
end

local function saveMenu(panel, win, z)
    local p = player(win)
    local pn = pnum(win)
    local sx, sy = menuUnder(panel, win, z)
    menuAt(win, sx, sy, {
        { name = ZeD.tr("UI_ZeD_Lists_SaveWear"), category = "a", pxIcon = L.icon("outfit"), iconTexture = ZeD.PxIcon.tex(L.icon("outfit"), 16), iconTintable = true,
          onFire = function()
              ZeD.ListsUI.askName(pn, ZeD.tr("UI_ZeD_Lists_NameOutfit"), L.uniqueName(p, "outfit"), function(name)
                  local l = L.saveWear(p, L.uniqueName(p, "outfit", name))
                  if l then R.setOutfit(p, l.id) end
              end)
          end },
        { name = ZeD.tr("UI_ZeD_Lists_SaveCarry"), category = "a", pxIcon = L.icon("loadout"), iconTexture = ZeD.PxIcon.tex(L.icon("loadout"), 16), iconTintable = true,
          onFire = function()
              ZeD.ListsUI.askName(pn, ZeD.tr("UI_ZeD_Lists_NameLoadout"), L.uniqueName(p, "loadout"), function(name)
                  local l = L.saveCarry(p, L.uniqueName(p, "loadout", name))
                  if l then R.setLoadout(p, l.id) end
              end)
          end },
    })
end

--- Open the to-do (focus lands on Restock); close it (focus back on "ready n of m").
function EL.openTodo(win)
    local s = st(win)
    s.todo, s.ask, s.step = true, nil, nil
    s.land = "v1"
    s.scroll:setScrollPos(0)
    win._equipSelected = nil
    win._gpFocusedEquipSlot = nil
    EL.plan(win, true)
end
function EL.closeTodo(win)
    local s = st(win)
    s.todo, s.ask, s.step = false, nil, nil
    s.land = "ready"
    win._gpFocusedEquipSlot = nil
end
function EL.todoOpen(win) return win ~= nil and win._el ~= nil and win._el.todo == true end

local function restock(win, kind)
    local p = player(win)
    if not p then return end
    if running(win) then R.stop(p, "user"); return end
    R.start(p, kind or "restock")
    EL.plan(win, true)
end

--- Open in Journal: the Loadouts page, that list chosen.
function EL.openJournal(win, listId)
    local strip = win._tabStripPanel
    if win._activeTab ~= "journal" and strip and strip._hitZones then
        for _, z in ipairs(strip._hitZones) do
            if z.id == "tab:journal" then strip:onMouseDown(z.x + 2, z.y + 2); break end
        end
    end
    win._activeTab = "journal"
    win._journalSubTab = 5
    if ZeD.JournalLists and listId then ZeD.JournalLists.select(win, listId) end
    st(win).todo = false
end

local function stepLoadout(win, dir)
    local p = player(win)
    local all = L.all(p, "loadout")
    if #all == 0 then return end
    local _, lo = R.current(p)
    local i = 0
    for k, l in ipairs(all) do if lo and l.id == lo.id then i = k end end
    i = i + dir
    if i < 1 then i = #all elseif i > #all then i = 1 end
    R.setLoadout(p, all[i].id)
end

local function bumpDays(win, d)
    local p = player(win)
    local _, _, days = R.current(p)
    R.setDays(p, days + d)
end

-- ---------------------------------------------------------------------------
-- THE DAYS: - n days + (one stop: A opens the stepper, Left / Right change it)
-- ---------------------------------------------------------------------------
local function daysText(n) return ZeD.tr(n == 1 and "UI_ZeD_EqBar_DayOne" or "UI_ZeD_EqBar_DayMany", n) end

local function daysW()
    local T = ZeD.T
    local kw = T.buttonH
    return kw * 2 + math.max(tw(T.fontF1, daysText(30)) + T.px(12), T.px(56)) + T.px(4)
end

local function drawDays(panel, win, x, y, h)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local s = st(win)
    local p = player(win)
    local _, _, days = R.current(p)
    local f1 = T.fontF1
    local kw = h
    local vw = daysW() - kw * 2 - T.px(4)
    local o = _btnOpts
    o.win, o.help, o.focus = win, ZeD.tr("UI_ZeD_EqBar_HelpDays"), nil
    o.disabled = days <= 1
    o.hover = hoverRect(panel, win, x, y, kw, h)
    M.drawButton(panel, x, y, kw, h, "-", "default", false, nil, o)
    zone(win, { id = "days:dec", x = x, y = y, w = kw, h = h, fn = function() bumpDays(win, -1) end, mouseOnly = true })
    local vx = x + kw + T.px(2)
    local onFocus = markFocus(panel, win, "days", vx, y, vw, h)
    A.frame(panel, vx, y, vw, h, s.step and T.accent or T.borderS)
    local txt = daysText(days)
    local tc = onFocus and T.textOnFocus or T.text
    panel:drawText(txt, vx + math.floor((vw - tw(f1, txt)) / 2), y + math.floor((h - fh(f1)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f1)
    if hoverRect(panel, win, vx, y, vw, h) then help(win, ZeD.tr("UI_ZeD_EqBar_HelpDays")) end
    o.disabled = days >= 30
    o.hover = hoverRect(panel, win, vx + vw + T.px(2), y, kw, h)
    M.drawButton(panel, vx + vw + T.px(2), y, kw, h, "+", "default", false, nil, o)
    zone(win, { id = "days:inc", x = vx + vw + T.px(2), y = y, w = kw, h = h, fn = function() bumpDays(win, 1) end, mouseOnly = true })
    zone(win, { id = "days", x = vx, y = y, w = vw, h = h, fn = function() s.step = not s.step end,
        cancel = s.step and function() s.step = nil end or nil,
        dpad = function(dir)
            if not s.step then return false end
            if dir == "left" then bumpDays(win, -1); return true end
            if dir == "right" then bumpDays(win, 1); return true end
            s.step = nil
            return false
        end })
    return daysW()
end

-- a drop-down (the pop-up menu's look): the list's name, a check when the outfit is all worn
local function drawSelect(panel, win, id, x, y, w, h, value, checkOn, fn, helpText)
    local T, A = ZeD.T, ZeD.Atoms
    local hover = hoverRect(panel, win, x, y, w, h)
    local foc = focusOf(win, id) ~= nil
    local room = w - T.sp.inputPadX * 2 - T.px(14) - (checkOn and T.px(18) or 0)
    ZeD.Stations.drawSelect(panel, x, y, w, h, nil, trunc(value, T.fontF2, room), false, foc, hover)
    if checkOn then
        local isz = T.px(14)
        A.drawPxIcon(panel, "yes", x + w - T.sp.inputPadX - T.px(5) - T.px(6) - isz, y + math.floor((h - isz) / 2), isz, 1, T.positive)
    end
    if hover and helpText then help(win, helpText) end
    local z = zone(win, { id = id, x = x, y = y, w = w, h = h })
    z.fn = function() fn(z) end
    return w
end

-- ---------------------------------------------------------------------------
-- THE BAR
-- ---------------------------------------------------------------------------
local function barParts(win)
    local T = ZeD.T
    local p = player(win)
    local o, lo, days = R.current(p)
    local s = st(win)
    local plan = EL.plan(win)
    local home = s.home and s.unpack
    local parts = {}
    parts[#parts + 1] = { k = "outfit", w = T.px(SEL_W) }
    parts[#parts + 1] = { k = "loadout", w = T.px(SEL_W) }
    parts[#parts + 1] = { k = "days", w = daysW() }
    if not (o or lo) then
        parts[#parts + 1] = { k = "empty", w = math.min(T.px(320), tw(T.fontF1, ZeD.tr("UI_ZeD_EqBar_EmptyLine")) + T.px(4)), flex = true }
    elseif lo then
        parts[#parts + 1] = { k = "ready", text = ZeD.tr("UI_ZeD_EqBar_Ready", s.readyN or 0, s.readyM or 0) }
        parts[#parts].w = tw(T.fontF1, parts[#parts].text) + T.px(6)
    end
    local verb
    if running(win) then verb = ZeD.tr("UI_ZeD_Restock_Stop")
    elseif home then verb = ZeD.tr("UI_ZeD_EqBar_UnpackTime", R.timeText(s.unpackSecs))
    else verb = ZeD.tr("UI_ZeD_EqBar_RestockTime", R.timeText(plan and plan.secs or 0)) end
    parts[#parts + 1] = { k = "verb", text = verb, w = ZeD.Molecules.buttonW(verb), right = true }
    parts[#parts + 1] = { k = "save", text = ZeD.tr("UI_ZeD_EqBar_Save"), w = ZeD.Molecules.buttonW(ZeD.tr("UI_ZeD_EqBar_Save")), right = true }
    return parts
end

-- the rows the parts take at width w: { { part, ... }, ... } (the left run, then the right buttons)
local function barRows(win, w)
    local T = ZeD.T
    local pad, gap = T.px(8), T.px(8)
    local parts = barParts(win)
    local total = pad * 2
    for _, pt in ipairs(parts) do total = total + pt.w + gap end
    if total - gap <= w then return { parts }, parts end
    -- two rows: the drop-downs and the days, then the rest
    local r1, r2 = {}, {}
    for _, pt in ipairs(parts) do
        if pt.k == "outfit" or pt.k == "loadout" or pt.k == "days" then r1[#r1 + 1] = pt else r2[#r2 + 1] = pt end
    end
    return { r1, r2 }, parts
end

function EL.barH(win, w)
    local rows = barRows(win, w)
    return ZeD.T.px(BAR_ROW) * #rows
end

function EL.drawBar(panel, win, x, y, w)
    local T, A = ZeD.T, ZeD.Atoms
    local p = player(win)
    if not p then return 0 end
    local s = st(win)
    local o, lo = R.current(p)
    local rows = barRows(win, w)
    local rh = T.px(BAR_ROW)
    local h = rh * #rows
    A.surfaceFill(panel, x, y, w, h, "surf2")
    A.drawDividerH(panel, x, y + h - T.hair, w, false)
    local pad, gap = T.px(8), T.px(8)
    local bh = T.buttonH
    for ri, row in ipairs(rows) do
        local ry = y + (ri - 1) * rh
        local by = ry + math.floor((rh - bh) / 2)
        -- the right-hand buttons first (Save at the edge, the verb before it)
        local right = x + w - pad
        for i = #row, 1, -1 do
            local pt = row[i]
            if pt.right then
                right = right - pt.w
                if pt.k == "save" then
                    local bx = right
                    button(panel, win, "save", bx, by, pt.text, nil, "default", { help = ZeD.tr("UI_ZeD_EqBar_HelpSave") })
                    local z = win._elZones[#win._elZones]
                    z.fn = function() saveMenu(panel, win, z) end
                else
                    local home = s.home and s.unpack
                    local plan = s.plan
                    local can = running(win) or (home and #R.unpackJobs(p, s.unpack) > 0) or (plan and #plan.jobs > 0)
                    button(panel, win, "verb", right, by, pt.text, function() restock(win, home and "unpack" or "restock") end, "primary",
                        { disabled = not can, help = ZeD.tr(home and "UI_ZeD_EqBar_HelpUnpack" or "UI_ZeD_EqBar_HelpRestock") })
                end
                right = right - gap
            end
        end
        local cx = x + pad
        for _, pt in ipairs(row) do
            if not pt.right then
                if pt.k == "outfit" then
                    local worn, m = s.wornN or 0, s.wornM or 0
                    drawSelect(panel, win, "outfit", cx, by, pt.w, bh, o and o.name or ZeD.tr("UI_ZeD_EqBar_NoOutfit"), o ~= nil and m > 0 and worn == m,
                        function(z) pickList(panel, win, z, "outfit") end, ZeD.tr("UI_ZeD_EqBar_HelpOutfit"))
                elseif pt.k == "loadout" then
                    drawSelect(panel, win, "loadout", cx, by, pt.w, bh, lo and lo.name or ZeD.tr("UI_ZeD_EqBar_NoLoadout"), false,
                        function(z) pickList(panel, win, z, "loadout") end, ZeD.tr("UI_ZeD_EqBar_HelpLoadout"))
                elseif pt.k == "days" then
                    drawDays(panel, win, cx, by, bh)
                elseif pt.k == "empty" then
                    local dc = T.textDim
                    local f1 = T.fontF1
                    local room = right - cx
                    panel:drawText(trunc(ZeD.tr("UI_ZeD_EqBar_EmptyLine"), f1, room), cx, ry + math.floor((rh - fh(f1)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f1)
                elseif pt.k == "ready" then
                    -- "ready 4 of 9", underlined: it opens the to-do
                    local f1 = T.fontF1
                    local ty = ry + math.floor((rh - fh(f1)) / 2)
                    local hz = hoverRect(panel, win, cx - T.px(3), by, pt.w, bh)
                    if hz then
                        local hv = T.hover
                        panel:drawRect(cx - T.px(3), by, pt.w, bh, hv.a, hv.r, hv.g, hv.b)
                        help(win, ZeD.tr("UI_ZeD_EqBar_HelpReady"))
                    end
                    local onFocus = markFocus(panel, win, "ready", cx - T.px(3), by, pt.w, bh)
                    local tc = onFocus and T.textOnFocus or T.text
                    panel:drawText(pt.text, cx, ty, tc.r, tc.g, tc.b, tc.a or 1, f1)
                    panel:drawRect(cx, ty + fh(f1), tw(f1, pt.text), T.hair, tc.a or 1, tc.r, tc.g, tc.b)
                    zone(win, { id = "ready", x = cx - T.px(3), y = by, w = pt.w, h = bh, fn = function() EL.openTodo(win) end })
                end
                cx = cx + pt.w + gap
            end
        end
    end
    -- the wheel's pick: open the to-do once the tab draws
    if EL.pending[pnum(win)] then EL.pending[pnum(win)] = nil; EL.openTodo(win) end
    return h
end

-- ---------------------------------------------------------------------------
-- THE GHOSTS: what's missing, where it goes on the doll
-- ---------------------------------------------------------------------------
--- { [doll slot id] = { tex, name } } for the unmet lines with a place on the doll.
function EL.ghosts(win, bands)
    local s = st(win)
    local plan = EL.plan(win)
    if not plan then return nil end
    local D = ZeD.EquipDoll
    local data = win._equipDollData
    local out = nil
    for _, row in ipairs(plan.rows) do
        if row.state ~= "on" then
            local pl = row.line.place or "inv"
            local id
            if pl == "hand:main" then id = "main"
            elseif pl == "hand:off" then id = "off"
            elseif pl:sub(1, 5) == "worn:" then id = D and D.slotForLoc and D.slotForLoc(pl:sub(6), bands)
            elseif pl:sub(1, 5) == "belt:" and data then
                for _, b in ipairs(data.belt or {}) do
                    if b.slot and tostring(b.slot.slotType) == pl:sub(6) then id = "belt" .. tostring(b.i); break end
                end
            end
            if id then
                out = out or {}
                if not out[id] then
                    local pk = row.picks[1]
                    out[id] = { tex = (pk and itemTex(pk.item)) or typeTex(row.line.type), name = row.line.name }
                end
            end
        end
    end
    return out
end

local function dashed(p, x, y, w, h, c, a)
    local u = ZeD.T.px(1)
    local d = ZeD.T.px(3)
    for i = 0, w - 1, d * 2 do
        local l = math.min(d, w - i)
        p:drawRect(x + i, y, l, u, a, c.r, c.g, c.b)
        p:drawRect(x + i, y + h - u, l, u, a, c.r, c.g, c.b)
    end
    for i = 0, h - 1, d * 2 do
        local l = math.min(d, h - i)
        p:drawRect(x, y + i, u, l, a, c.r, c.g, c.b)
        p:drawRect(x + w - u, y + i, u, l, a, c.r, c.g, c.b)
    end
end

--- A missing item in an empty slot box (bx, by, b): its picture at 36% in a dashed accent box.
function EL.drawGhost(panel, bx, by, b, g)
    local T = ZeD.T
    dashed(panel, bx, by, b, b, T.accent, 1)
    if g and g.tex then
        local isz = math.floor(b * 0.62)
        panel:drawTextureScaledAspect(g.tex, bx + math.floor((b - isz) / 2), by + math.floor((b - isz) / 2), isz, isz, GHOST_A, 1, 1, 1)
    end
end

-- ---------------------------------------------------------------------------
-- THE TO-DO: one scroll for its body
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
    local fid = win._gpFocusedEquipSlot
    if needs and fid and fid ~= s.pinned and s.lastZones then
        for _, z in ipairs(s.lastZones) do
            if "el:" .. z.id == fid and z.scrolls then
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
    s.inView = true
    panel:setStencilRect(x, y, needs and (w - sbW) or w, h)
    local first = #(win._elZones or {})
    local bottom = draw(drawW, y - off)
    panel:clearStencilRect()
    s.inView = false
    for i = first + 1, #(win._elZones or {}) do win._elZones[i].scrolls = true end
    s.total = math.max(1, bottom - (y - off) + T.sp.sm)
    if needs then sc:draw(panel) end
end

function EL.scrollFor(win)
    if EL.todoOpen(win) then return st(win).scroll end
    return nil
end

-- a section's head (foldable, a stop): returns its height; caption at the right in F1 dim
local function section(panel, win, id, x, y, w, label, caption)
    local T, M = ZeD.T, ZeD.Molecules
    local s = st(win)
    local folded = s.fold[id]
    local h = T.px(22)
    local hover = hoverRect(panel, win, x, y, w, h)
    if hover then help(win, ZeD.tr(folded and "UI_ZeD_Lists_HelpShow" or "UI_ZeD_Lists_HelpHide", label)) end
    M.drawSectionHeader(panel, x, y, w, label, nil, not folded, hover, nil, true, 0, h, nil, { focus = focusOf(win, id) })
    if caption and caption ~= "" then
        local f1 = T.fontF1
        local dc = T.textDim
        local cap = trunc(caption, f1, math.floor(w * 0.55))
        panel:drawText(cap, x + w - T.px(4) - tw(f1, cap), y + math.floor((h - fh(f1)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f1)
    end
    zone(win, { id = id, x = x, y = y, w = w, h = h, fn = function() s.fold[id] = not s.fold[id] end })
    return h, folded
end

-- the five states (an icon tinted by its status, the words stay default)
local STATE_ICON = { on = "yes", take = "box_down", fill = "tap", ask = "help", none = "no", far = "walk", put = "box_down", pick = "help", stay = "yes" }
local function stateTint(T, state)
    if state == "on" or state == "stay" then return T.positive end
    if state == "take" or state == "put" then return T.accent end
    if state == "fill" then return T.info end
    if state == "ask" or state == "pick" or state == "far" then return T.warning end
    return T.danger
end

-- one to-do line: the state, the picture, the name over its rule and place, where at the right
local function todoLine(panel, win, id, x, y, w, e)
    local T, A = ZeD.T, ZeD.Atoms
    local h = T.px(ROW_H)
    local hover = e.fn and hoverRect(panel, win, x, y, w, h)
    if hover then
        local hv = T.hover
        panel:drawRect(x, y, w, h, hv.a, hv.r, hv.g, hv.b)
        if e.help then help(win, e.help) end
    end
    local onFocus = e.fn and markFocus(panel, win, id, x, y, w, h) or false
    local isz = T.px(14)
    A.drawPxIcon(panel, STATE_ICON[e.state] or "no", x + T.px(4), y + math.floor((h - isz) / 2), isz, 1, onFocus and T.textOnFocus or stateTint(T, e.state))
    local psz = T.px(20)
    local px = x + T.px(4) + isz + T.px(6)
    if e.tex then panel:drawTextureScaledAspect(e.tex, px, y + math.floor((h - psz) / 2), psz, psz, e.state == "on" and 0.6 or 1, 1, 1, 1) end
    local nx = px + psz + T.px(6)
    local f2, f1 = T.fontF2, T.fontF1
    local where = e.where or ""
    local ww = math.min(tw(f1, where), math.floor((x + w - nx) * 0.48))
    local rx = x + w - T.px(4)
    local tc = onFocus and T.textOnFocus or T.text
    local dc = onFocus and T.textOnFocus or T.textDim
    local ty = y + math.floor((h - fh(f2) - fh(f1)) / 2)
    local nameRoom = rx - ww - T.px(8) - nx
    panel:drawText(trunc(e.name, f2, nameRoom), nx, ty, tc.r, tc.g, tc.b, (tc.a or 1) * (e.state == "on" and 0.75 or 1), f2)
    panel:drawText(trunc(e.sub, f1, nameRoom), nx, ty + fh(f2), dc.r, dc.g, dc.b, dc.a or 1, f1)
    local wt = trunc(where, f1, ww)
    panel:drawText(wt, rx - tw(f1, wt), y + math.floor((h - fh(f1)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f1)
    A.drawDividerH(panel, x, y + h - T.hair, w)
    if e.fn then zone(win, { id = id, x = x, y = y, w = w, h = h, fn = e.fn }) end
    return h
end

-- the words for a list line's row
local function amountWords(ln, a)
    return L.amountText({ amount = a, unit = ln.unit })
end
local function lineName(row)
    local ln = row.line
    local nm = ln.name or ln.type or "?"
    local need = row.need or 1
    if row.short and row.state ~= "none" and row.state ~= "far" then
        return ZeD.tr("UI_ZeD_Todo_NOfM", nm, amountWords(ln, math.max(0, row.got or 0)), amountWords(ln, need))
    end
    if ln.unit == "n" then
        if need > 1 then return ZeD.tr("UI_ZeD_Todo_Times", nm, amountWords(ln, need)) end
        return nm
    end
    return nm .. ", " .. amountWords(ln, need)
end
local function ruleWords(ln)
    if ln.sec == "supply" then
        return ZeD.tr(ln.per == "day" and "UI_ZeD_Todo_RuleDay" or "UI_ZeD_Todo_RuleFixed", L.amountText(ln))
    end
    return L.ruleText(ln) .. ", " .. L.placeText(ln.place)
end
local function whereWords(row, inBuilding)
    local st0 = row.state
    if st0 == "on" then return ZeD.tr("UI_ZeD_Todo_OnYou") end
    if st0 == "take" then
        if row.where then return ZeD.tr("UI_ZeD_Todo_TakeFrom", row.where) end
        return ZeD.tr("UI_ZeD_Todo_ToPlace", L.placeText(row.line.place))
    end
    if st0 == "fill" then return ZeD.tr("UI_ZeD_Todo_FillAt", row.where or "") end
    if st0 == "ask" then return ZeD.tr("UI_ZeD_Todo_AskAt", row.where or "") end
    if st0 == "far" then return ZeD.tr("UI_ZeD_Todo_FarAt", row.where or "") end
    return ZeD.tr(inBuilding and "UI_ZeD_Todo_NoneBuilding" or "UI_ZeD_Todo_NoneReach")
end

local function rowEntry(win, row, inBuilding)
    local pk = row.picks[1]
    local e = { state = row.state, name = lineName(row), sub = ruleWords(row.line), where = whereWords(row, inBuilding),
                tex = (pk and itemTex(pk.item)) or (row.fill and itemTex(row.fill.bottles[1].item))
                      or (row.items and row.items[1] and itemTex(row.items[1])) or typeTex(row.line.type) }
    if row.state == "ask" then
        local key = row.key
        e.fn = function() local s = st(win); s.ask = key; s.land = "ask:cancel" end
        e.help = ZeD.tr("UI_ZeD_Todo_HelpAsk")
    end
    return e
end

-- the title: the list's name, "loadout | 9 lines", < 1 of 3 >
local function drawTitle(panel, win, x, y, w, name, count)
    local T, M = ZeD.T, ZeD.Molecules
    local p = player(win)
    local f4, f1 = T.fontF4, T.fontF1
    local cy = y + T.px(8)
    local all = L.all(p, "loadout")
    local _, lo = R.current(p)
    local rx = x + w
    if #all > 1 then
        local bh = T.buttonH - T.px(4)
        local idx = 0
        for i, l in ipairs(all) do if lo and l.id == lo.id then idx = i end end
        rx = rx - bh
        local o = _btnOpts
        o.win, o.hint, o.help = win, ZeD.tr("UI_ZeD_Todo_Next"), ZeD.tr("UI_ZeD_Todo_HelpNext")
        o.hover, o.focus, o.disabled, o.active = hoverRect(panel, win, rx, cy, bh, bh), focusOf(win, "next"), false, false
        o.id = "el:next"
        M.drawIconButton(panel, rx, cy, bh, "arrow_right", o)
        zone(win, { id = "next", x = rx, y = cy, w = bh, h = bh, fn = function() stepLoadout(win, 1) end })
        local of = ZeD.tr("UI_ZeD_Todo_OneOf", idx, #all)
        rx = rx - T.px(6) - tw(f1, of)
        local dc = T.textDim
        panel:drawText(of, rx, cy + math.floor((bh - fh(f1)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f1)
        rx = rx - T.px(6) - bh
        o.help, o.id, o.hint = ZeD.tr("UI_ZeD_Todo_HelpPrev"), "el:prev", ZeD.tr("UI_ZeD_Todo_Prev")
        o.hover, o.focus = hoverRect(panel, win, rx, cy, bh, bh), focusOf(win, "prev")
        M.drawIconButton(panel, rx, cy, bh, "arrow_left", o)
        zone(win, { id = "prev", x = rx, y = cy, w = bh, h = bh, fn = function() stepLoadout(win, -1) end })
        rx = rx - T.px(8)
    end
    local hi = T.toneHi or T.text
    local nm = trunc(name, f4, rx - x - T.px(4))
    panel:drawText(nm, x, cy, hi.r, hi.g, hi.b, hi.a or 1, f4)
    local nx = x + tw(f4, nm) + T.px(10)
    if count and nx + tw(f1, count) <= rx then
        local dc = T.textDim
        panel:drawText(count, nx, cy + fh(f4) - fh(f1) - T.px(1), dc.r, dc.g, dc.b, dc.a or 1, f1)
    end
    return cy + fh(f4) + T.px(8) - y
end

-- a label at the left, a control at the right (Applied's rows)
local function labelRow(panel, x, y, w, h, label)
    local T = ZeD.T
    local f1 = T.fontF1
    local lc = T.toneLo or T.textDim
    panel:drawText(ZeD.textCase(label), x, y + math.floor((h - fh(f1)) / 2), lc.r, lc.g, lc.b, lc.a or 1, f1)
end

local function drawApplied(panel, win, x, y, w)
    local T, A = ZeD.T, ZeD.Atoms
    local p = player(win)
    local o, lo = R.current(p)
    local cy = y
    local h, folded = section(panel, win, "sec:applied", x, cy, w, ZeD.tr("UI_ZeD_Todo_Applied"))
    cy = cy + h + T.px(4)
    if folded then return cy end
    local bh = T.buttonH
    local rh = bh + T.px(6)
    local cw = math.min(T.px(200), math.floor(w * 0.5))
    local cx = x + w - cw
    labelRow(panel, x + T.px(4), cy, w, rh, ZeD.tr("UI_ZeD_Todo_Outfit"))
    local s = st(win)
    local worn, m = s.wornN or 0, s.wornM or 0
    drawSelect(panel, win, "outfit", cx, cy + T.px(3), cw, bh, o and o.name or ZeD.tr("UI_ZeD_EqBar_NoOutfit"), o ~= nil and m > 0 and worn == m,
        function(z) pickList(panel, win, z, "outfit") end, ZeD.tr("UI_ZeD_EqBar_HelpOutfit"))
    cy = cy + rh
    labelRow(panel, x + T.px(4), cy, w, rh, ZeD.tr("UI_ZeD_Todo_Loadout"))
    drawSelect(panel, win, "loadout", cx, cy + T.px(3), cw, bh, lo and lo.name or ZeD.tr("UI_ZeD_EqBar_NoLoadout"), false,
        function(z) pickList(panel, win, z, "loadout") end, ZeD.tr("UI_ZeD_EqBar_HelpLoadout"))
    cy = cy + rh
    labelRow(panel, x + T.px(4), cy, w, rh, ZeD.tr("UI_ZeD_Todo_Days"))
    drawDays(panel, win, x + w - daysW(), cy + T.px(3), bh)
    cy = cy + rh
    if o then
        labelRow(panel, x + T.px(4), cy, w, rh, ZeD.tr("UI_ZeD_Todo_OutfitWorn"))
        local f1 = T.fontF1
        local txt = ZeD.tr("UI_ZeD_Todo_NOfMShort", worn, m)
        local isz = T.px(12)
        local tx = x + w - T.px(4) - tw(f1, txt) - ((worn == m) and (isz + T.px(4)) or 0)
        local tc = T.text
        panel:drawText(txt, tx, cy + math.floor((rh - fh(f1)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f1)
        if worn == m and m > 0 then A.drawPxIcon(panel, "yes", x + w - T.px(4) - isz, cy + math.floor((rh - isz) / 2), isz, 1, T.positive) end
        cy = cy + rh
    end
    return cy + T.px(6)
end

-- the restock way in words, and why a run stopped
local WAY_KEY = { hardcore = "UI_ZeD_Todo_WayHardcore", casual = "UI_ZeD_Todo_WayCasual", accessible = "UI_ZeD_Todo_WayAccessible" }
local STOP_KEY = { zombie = "UI_ZeD_Restock_StoppedZombie", hurt = "UI_ZeD_Restock_StoppedHurt", key = "UI_ZeD_Restock_StoppedKey",
                   user = "UI_ZeD_Restock_StoppedUser", error = "UI_ZeD_Restock_StoppedError" }

-- Load after restock: a bar of worn and gear, supplies and the room for loot against what you can carry
local function drawLoad(panel, win, x, y, w, plan)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local p = player(win)
    local s = st(win)
    local ld = s.load
    if not ld then return y end
    local cy = y
    local h, folded = section(panel, win, "sec:load", x, cy, w, ZeD.tr("UI_ZeD_Todo_Load"), ZeD.tr("UI_ZeD_Todo_LoadOf", kg(ld.after), kg(ld.max)))
    cy = cy + h + T.px(6)
    if folded then return cy end
    local bx, bw, bhh = x + T.px(4), w - T.px(8), T.px(10)
    local scale = math.max(ld.max, ld.after) * 1.05
    if scale <= 0 then scale = 1 end
    local s2 = T.surf3 or T.surf2
    panel:drawRect(bx, cy, bw, bhh, s2.a or 1, s2.r, s2.g, s2.b)
    local wornW = math.floor(bw * math.min(ld.worn, ld.max) / scale)
    local supW = math.floor(bw * math.max(0, math.min(ld.after, ld.max) - math.min(ld.worn, ld.max)) / scale)
    local overW = math.floor(bw * math.max(0, ld.after - ld.max) / scale)
    local dim, ac, dg = T.textDim, T.accent, T.danger
    if wornW > 0 then panel:drawRect(bx, cy, wornW, bhh, 0.8, dim.r, dim.g, dim.b) end
    if supW > 0 then panel:drawRect(bx + wornW, cy, supW, bhh, 1, ac.r, ac.g, ac.b) end
    if overW > 0 then panel:drawRect(bx + wornW + supW, cy, overW, bhh, 1, dg.r, dg.g, dg.b) end
    A.frame(panel, bx, cy, bw, bhh, T.borderS)
    -- the limit
    local mx = bx + math.floor(bw * ld.max / scale)
    local tx = T.text
    panel:drawRect(mx, cy - T.px(3), T.px(2), bhh + T.px(6), 1, tx.r, tx.g, tx.b)
    cy = cy + bhh + T.px(8)
    -- the legend: a square of each colour and plain words
    local f1 = T.fontF1
    local lx = bx
    local sq = T.px(7)
    local room = math.max(0, ld.max - ld.after)
    for _, e in ipairs({ { dim, ZeD.tr("UI_ZeD_Todo_LegendWorn", kg(ld.worn)) }, { ac, ZeD.tr("UI_ZeD_Todo_LegendSupplies", kg(ld.supplies)) },
                         { T.positive, ZeD.tr("UI_ZeD_Todo_LegendRoom", kg(room)) } }) do
        local ww = sq + T.px(5) + tw(f1, e[2])
        if lx + ww > bx + bw and lx > bx then lx = bx; cy = cy + fh(f1) + T.px(4) end
        A.drawStatusDot(panel, lx, cy + math.floor((fh(f1) - sq) / 2), e[1], sq)
        local c = T.text
        panel:drawText(e[2], lx + sq + T.px(5), cy, c.r, c.g, c.b, c.a or 1, f1)
        lx = lx + ww + T.px(12)
    end
    cy = cy + fh(f1) + T.px(8)
    -- over the limit: by how much, the heaviest supply, the most days that fit; Make it N days
    local over = s.over
    if over then
        local f2 = T.fontF2
        local heavy = over.heaviest and (over.heaviest.line.name or "?") or nil
        local t = ZeD.tr("UI_ZeD_Todo_Over", kg(over.over))
        if heavy then t = t .. " " .. ZeD.tr("UI_ZeD_Todo_Heaviest", heavy) end
        if not over.perDay then -- (no supply by the day: the days change nothing)
        elseif over.fits >= 1 and over.fits < plan.days then t = t .. " " .. ZeD.tr(over.fits == 1 and "UI_ZeD_Todo_FitsOne" or "UI_ZeD_Todo_FitsMany", over.fits)
        elseif over.fits < 1 then t = t .. " " .. ZeD.tr("UI_ZeD_Todo_FitsNone") end
        local lines = A.wrapText(t, f2, bw - T.px(26))
        local lh = fh(f2) + T.px(2)
        local boxH = #lines * lh + T.px(12)
        A.frame(panel, bx, cy, bw, boxH, T.danger)
        local dsz = T.px(6)
        A.drawStatusDot(panel, bx + T.px(8), cy + T.px(6) + math.floor((fh(f2) - dsz) / 2), T.danger, dsz)
        local c = T.text
        for i, ln in ipairs(lines) do panel:drawText(ln, bx + T.px(20), cy + T.px(6) + (i - 1) * lh, c.r, c.g, c.b, c.a or 1, f2) end
        cy = cy + boxH + T.px(6)
        if over.perDay and over.fits >= 1 and over.fits < plan.days then
            local n = over.fits
            button(panel, win, "makeit", bx, cy, ZeD.tr("UI_ZeD_Todo_MakeIt", n), function() R.setDays(p, n) end, "default",
                { help = ZeD.tr("UI_ZeD_Todo_HelpMakeIt") })
            cy = cy + T.buttonH + T.px(6)
        end
    end
    -- the restock way in use, and the run going on
    local dc = T.textDim
    for _, ln in ipairs(A.wrapText(ZeD.tr(WAY_KEY[R.mode()] or WAY_KEY.casual), f1, bw)) do
        panel:drawText(ln, bx, cy, dc.r, dc.g, dc.b, dc.a or 1, f1)
        cy = cy + fh(f1) + T.px(2)
    end
    local status = EL.statusText(win)
    if status then
        cy = cy + T.px(4)
        cy = cy + M.drawNeedsLine(panel, bx, cy, bw, status) + T.px(2)
    end
    return cy + T.px(8)
end

--- The run's line: "Walking to 2 of 3 | 0:40 left", "Stopped: a zombie in view", ...
function EL.statusText(win)
    local run = runOf(win)
    local p = player(win)
    if not (run and p) then return nil end
    if run.done then
        if getTimestampMs() - (run.doneMs or 0) > 8000 then return nil end
        if run.stopped then return ZeD.tr(STOP_KEY[run.stopped] or STOP_KEY.user) end
        return ZeD.tr(run.kind == "unpack" and "UI_ZeD_Restock_DoneUnpack" or "UI_ZeD_Restock_Done")
    end
    if run.mode == "accessible" then
        local at, n, left = R.progress(p, run)
        if at then return ZeD.tr("UI_ZeD_Restock_Walking", at, n, R.timeText(left)) end
    end
    if run.mode == "casual" then return run.notice or ZeD.tr("UI_ZeD_Restock_Waiting") end
    return ZeD.tr("UI_ZeD_Restock_Taking")
end

-- the to-do's lines (days 1) or the long trip's table and the gear
local function drawTodoRows(panel, win, x, y, w, plan)
    local T = ZeD.T
    local cy = y
    local inB = plan.scan and plan.scan.building ~= nil
    local c = plan.count
    local caps = {}
    if (c.take or 0) > 0 then caps[#caps + 1] = ZeD.tr("UI_ZeD_Todo_NTake", c.take) end
    if (c.fill or 0) > 0 then caps[#caps + 1] = ZeD.tr("UI_ZeD_Todo_NFill", c.fill) end
    if (c.ask or 0) > 0 then caps[#caps + 1] = ZeD.tr("UI_ZeD_Todo_NAsk", c.ask) end
    if (c.short or 0) > 0 then caps[#caps + 1] = ZeD.tr("UI_ZeD_Todo_NShort", c.short) end
    if (c.none or 0) + (c.far or 0) > 0 then caps[#caps + 1] = ZeD.tr("UI_ZeD_Todo_NNone", (c.none or 0) + (c.far or 0)) end
    if #caps == 0 and #plan.rows > 0 then caps[1] = ZeD.tr("UI_ZeD_Todo_AllOn") end
    local perDay = false
    for _, row in ipairs(plan.rows) do if row.line.sec == "supply" and row.line.per == "day" then perDay = true end end
    local long = plan.days > 1 and perDay
    if not long then
        local h, folded = section(panel, win, "sec:todo", x, cy, w, ZeD.tr("UI_ZeD_Todo_ToDo"), table.concat(caps, " | "))
        cy = cy + h
        if folded then return cy + T.px(6) end
        if #plan.rows == 0 then
            cy = cy + T.px(6)
            cy = cy + ZeD.Molecules.drawEmptyLine(panel, x + T.px(4), cy, w - T.px(8), ZeD.tr("UI_ZeD_Todo_Nothing")) + T.px(6)
        end
        for i, row in ipairs(plan.rows) do cy = cy + todoLine(panel, win, "row:" .. row.key, x, cy, w, rowEntry(win, row, inB)) end
        return cy + T.px(8)
    end
    -- the long trip: the supplies as a table, the gear under it
    local h, folded = section(panel, win, "sec:supplies", x, cy, w, ZeD.tr("UI_ZeD_Todo_SuppliesFor", plan.days),
        ZeD.tr("UI_ZeD_Todo_SuppliesCap", plan.days))
    cy = cy + h
    if not folded then
        local f1, f2 = T.fontF1, T.fontF2
        local haveW, needW, ruleW = T.px(56), T.px(64), T.px(108)
        local hx, nx, rx = x + w - T.px(4), x + w - T.px(4) - haveW, x + w - T.px(4) - haveW - needW
        local lo = T.toneLo or T.textDim
        local hy = cy + T.px(4)
        panel:drawText(ZeD.textCase(ZeD.tr("UI_ZeD_Todo_ColWhat")), x + T.px(4), hy, lo.r, lo.g, lo.b, lo.a or 1, f1)
        local function rText(t, rr, yy, c, f) panel:drawText(t, rr - tw(f, t), yy, c.r, c.g, c.b, c.a or 1, f) end
        rText(ZeD.textCase(ZeD.tr("UI_ZeD_Todo_ColRule")), rx, hy, lo, f1)
        rText(ZeD.textCase(ZeD.tr("UI_ZeD_Todo_ColNeed")), nx, hy, lo, f1)
        rText(ZeD.textCase(ZeD.tr("UI_ZeD_Todo_ColHave")), hx, hy, lo, f1)
        cy = hy + fh(f1) + T.px(4)
        ZeD.Atoms.drawDividerH(panel, x, cy, w, false)
        cy = cy + T.hair
        for _, row in ipairs(plan.rows) do
            if row.line.sec == "supply" then
                local th = T.px(TROW_H)
                local e = rowEntry(win, row, inB)
                local isz = T.px(12)
                local onFocus = e.fn and markFocus(panel, win, "row:" .. row.key, x, cy, w, th) or false
                local tint = onFocus and T.textOnFocus or stateTint(T, row.state)
                ZeD.Atoms.drawPxIcon(panel, STATE_ICON[row.state] or "no", x + T.px(4), cy + math.floor((th - isz) / 2), isz, 1, tint)
                local psz = T.px(16)
                if e.tex then panel:drawTextureScaledAspect(e.tex, x + T.px(20), cy + math.floor((th - psz) / 2), psz, psz, 1, 1, 1, 1) end
                local c = onFocus and T.textOnFocus or T.text
                local yy = cy + math.floor((th - fh(f2)) / 2)
                local y1 = cy + math.floor((th - fh(f1)) / 2)
                panel:drawText(trunc(row.line.name, f2, rx - ruleW - x - T.px(44)), x + T.px(40), yy, c.r, c.g, c.b, c.a or 1, f2)
                rText(trunc(ruleWords(row.line), f1, ruleW - T.px(6)), rx, y1, c, f1)
                rText(amountWords(row.line, row.need), nx, y1, c, f1)
                rText(amountWords(row.line, math.max(0, row.have or 0)), hx, y1, c, f1)
                ZeD.Atoms.drawDividerH(panel, x, cy + th - T.hair, w)
                if e.fn then zone(win, { id = "row:" .. row.key, x = x, y = cy, w = w, h = th, fn = e.fn }) end
                cy = cy + th
            end
        end
    end
    cy = cy + T.px(8)
    local gearN, gearTake = 0, 0
    for _, row in ipairs(plan.rows) do
        if row.line.sec ~= "supply" then gearN = gearN + 1; if row.state ~= "on" then gearTake = gearTake + 1 end end
    end
    if gearN > 0 then
        local h2, folded2 = section(panel, win, "sec:gear", x, cy, w, ZeD.tr("UI_ZeD_Lists_Gear"), ZeD.tr("UI_ZeD_Todo_NTake", gearTake))
        cy = cy + h2
        if not folded2 then
            for _, row in ipairs(plan.rows) do
                if row.line.sec ~= "supply" then cy = cy + todoLine(panel, win, "row:" .. row.key, x, cy, w, rowEntry(win, row, inB)) end
            end
        end
    end
    return cy + T.px(8)
end

-- ---------------------------------------------------------------------------
-- UNPACK: Loot, Leftovers, Stays on you
-- ---------------------------------------------------------------------------
-- a kind with no home yet: the building's containers to pick from (kept for that building)
local function pickPlace(panel, win, z, cat)
    local p = player(win)
    local scan = R.scan(p)
    local rows, seen = {}, {}
    for _, src in ipairs(scan.sources) do
        if not src.floor and not src.vehicle then
            local k = src.name .. "|" .. src.x .. "," .. src.y .. "," .. src.z
            if not seen[k] then
                seen[k] = true
                local s0 = src
                rows[#rows + 1] = { name = src.name, category = "c", note = function() return tostring(s0.cont:getItems():size()) end,
                    onFire = function() R.setHome(p, cat, s0); EL.plan(win, true) end }
            end
        end
    end
    if #rows == 0 then rows[1] = { heading = true, category = "c", name = ZeD.tr("UI_ZeD_Todo_NoPlaces") } end
    local sx, sy = menuUnder(panel, win, z)
    menuAt(win, sx, sy, rows)
end

-- the loot grouped by type and where it goes
local function grouped(list)
    local by, out = {}, {}
    for _, e in ipairs(list) do
        local k = e.item:getFullType() .. "|" .. tostring(e.dest and e.dest.cont) .. "|" .. e.state
        local g = by[k]
        if not g then g = { e = e, n = 0, items = {} }; by[k] = g; out[#out + 1] = g end
        g.n = g.n + 1
        g.items[#g.items + 1] = e.item
    end
    return out
end

local function drawUnpack(panel, win, x, y, w, up)
    local T, A = ZeD.T, ZeD.Atoms
    local cy = y
    local h, folded = section(panel, win, "sec:loot", x, cy, w, ZeD.tr("UI_ZeD_Unpack_Loot"), ZeD.tr("UI_ZeD_Unpack_LootCap"))
    cy = cy + h
    if not folded then
        if #up.loot == 0 then
            cy = cy + T.px(6)
            cy = cy + ZeD.Molecules.drawEmptyLine(panel, x + T.px(4), cy, w - T.px(8), ZeD.tr("UI_ZeD_Unpack_NoLoot")) + T.px(6)
        end
        for _, g in ipairs(grouped(up.loot)) do
            local e0 = g.e
            local nm = R.call(e0.item, "getDisplayName") or "?"
            if g.n > 1 then nm = ZeD.tr("UI_ZeD_Todo_Times", nm, g.n) end
            local ent = { state = e0.state, name = nm, sub = ZeD.tr("UI_ZeD_Unpack_Found"), tex = itemTex(e0.item) }
            if e0.state == "put" then ent.where = e0.dest.name
            else
                ent.where = ZeD.tr("UI_ZeD_Unpack_PickPlace")
                ent.sub = ZeD.tr("UI_ZeD_Unpack_NoHome", e0.cat)
                local cat = e0.cat
                ent.help = ZeD.tr("UI_ZeD_Unpack_HelpPick")
                ent.fn = function()
                    local z = nil
                    for _, zz in ipairs(win._elZones or {}) do if zz.id == "loot:" .. cat then z = zz end end
                    if z then pickPlace(win._drawerPanel, win, z, cat) end
                end
            end
            cy = cy + todoLine(panel, win, "loot:" .. e0.cat .. ((e0.state == "put") and (":" .. e0.item:getFullType()) or ""), x, cy, w, ent)
        end
    end
    cy = cy + T.px(8)
    local h2, folded2 = section(panel, win, "sec:left", x, cy, w, ZeD.tr("UI_ZeD_Unpack_Leftovers"), ZeD.tr("UI_ZeD_Unpack_LeftoversCap"))
    cy = cy + h2
    if not folded2 then
        if #up.leftovers == 0 then
            cy = cy + T.px(6)
            cy = cy + ZeD.Molecules.drawEmptyLine(panel, x + T.px(4), cy, w - T.px(8), ZeD.tr("UI_ZeD_Unpack_NoLeftovers")) + T.px(6)
        end
        for _, g in ipairs(grouped(up.leftovers)) do
            local e0 = g.e
            local nm = R.call(e0.item, "getDisplayName") or "?"
            if g.n > 1 then nm = ZeD.tr("UI_ZeD_Todo_Times", nm, g.n) end
            local ent = { state = e0.state, name = nm, tex = itemTex(e0.item) }
            if e0.state == "stay" then ent.where, ent.sub = ZeD.tr("UI_ZeD_Unpack_StaysPacked"), ""
            else
                local d = math.max(0, math.floor((e0.spoils or 0) + 0.5))
                ent.sub = ZeD.tr(d == 1 and "UI_ZeD_Unpack_SpoilsOne" or "UI_ZeD_Unpack_Spoils", d)
                ent.where = e0.dest and e0.dest.name or ZeD.tr("UI_ZeD_Unpack_PickPlace")
            end
            cy = cy + todoLine(panel, win, "left:" .. e0.item:getFullType(), x, cy, w, ent)
        end
    end
    cy = cy + T.px(8)
    local h3, folded3 = section(panel, win, "sec:stays", x, cy, w, ZeD.tr("UI_ZeD_Unpack_Stays"), ZeD.tr("UI_ZeD_Unpack_StaysCap"))
    cy = cy + h3 + T.px(6)
    if not folded3 then
        local f2 = T.fontF2
        local dc = T.textDim
        for _, ln in ipairs(A.wrapText(table.concat(up.stays, ", "), f2, w - T.px(8))) do
            panel:drawText(ln, x + T.px(4), cy, dc.r, dc.g, dc.b, dc.a or 1, f2)
            cy = cy + fh(f2) + T.px(2)
        end
    end
    return cy + T.px(8)
end

-- ---------------------------------------------------------------------------
-- RENDER THE TO-DO
-- ---------------------------------------------------------------------------
function EL.beginFrame(win)
    local s = st(win)
    s.lastZones = win._elZones
    win._elZones = {}
end

function EL.renderTodo(panel, win, x, y, w, h)
    local T, M = ZeD.T, ZeD.Molecules
    local s = st(win)
    local p = player(win)
    if not p then return end
    local plan = EL.plan(win)
    local o, lo = R.current(p)
    local home = s.home and s.unpack ~= nil
    -- the back key and the buttons: Restock (the default), Open in Journal, Unpack (dim until you're home)
    local run = running(win)
    local restockLbl = run and ZeD.tr("UI_ZeD_Restock_Stop") or ZeD.tr("UI_ZeD_EqBar_RestockTime", R.timeText(plan and plan.secs or 0))
    local unpackLbl = ZeD.tr("UI_ZeD_EqBar_UnpackTime", R.timeText(s.unpackSecs or 0))
    local canRestock = run or (plan and #plan.jobs > 0)
    local canUnpack = home and #R.unpackJobs(p, s.unpack) > 0
    local defs
    if home then
        defs = { { id = "v1", label = run and restockLbl or unpackLbl, fn = function() restock(win, "unpack") end, primary = true, disabled = not (run or canUnpack), help = ZeD.tr("UI_ZeD_EqBar_HelpUnpack") },
                 { id = "v2", label = ZeD.tr("UI_ZeD_EqBar_Restock"), fn = function() restock(win, "restock") end, disabled = run or not canRestock, help = ZeD.tr("UI_ZeD_EqBar_HelpRestock") },
                 { id = "v3", label = ZeD.tr("UI_ZeD_EqBar_OpenJournal"), fn = function() EL.openJournal(win, lo and lo.id) end, disabled = not lo, help = ZeD.tr("UI_ZeD_EqBar_HelpJournal") } }
    else
        defs = { { id = "v1", label = restockLbl, fn = function() restock(win, "restock") end, primary = true, disabled = not canRestock, help = ZeD.tr("UI_ZeD_EqBar_HelpRestock") },
                 { id = "v2", label = ZeD.tr("UI_ZeD_EqBar_OpenJournal"), fn = function() EL.openJournal(win, lo and lo.id) end, disabled = not lo, help = ZeD.tr("UI_ZeD_EqBar_HelpJournal") },
                 { id = "v3", label = ZeD.tr("UI_ZeD_EqBar_Unpack"), fn = function() restock(win, "unpack") end, disabled = true, help = ZeD.tr("UI_ZeD_EqBar_HelpUnpackAway") } }
    end
    local verbs = {}
    for i, d in ipairs(defs) do
        verbs[i] = { label = d.label, primary = d.primary, disabled = d.disabled, help = d.help, focus = focusOf(win, d.id) }
        if s.ask then verbs[i].hover = false end
    end
    local rects = {}
    local backHover = nil
    if s.ask then backHover = false end
    local bb = M.drawCardBackBar(panel, x, y, w, "", verbs, false, false, rects,
        { win = win, focusParts = { back = focusOf(win, "back") }, backHelp = ZeD.tr("UI_ZeD_Todo_HelpBack"), backHover = backHover })
    if rects.back then zone(win, { id = "back", x = rects.back.x, y = rects.back.y, w = rects.back.w, h = rects.back.h, fn = function() EL.closeTodo(win) end }) end
    for i, r in ipairs(rects.verbs or {}) do
        local d = defs[i]
        zone(win, { id = d.id, x = r.x, y = r.y, w = r.w, h = r.h, fn = (not d.disabled) and d.fn or nil, keep = true })
    end
    -- the question before the last of something: a band at the foot
    local bandH = s.ask and M.bandH() or 0
    local top = y + bb
    framed(panel, win, x, top, w, h - bb - bandH, function(dw, ty)
        local cx, cw = x + T.px(8), dw - T.px(16)
        local cy = ty
        if home then
            cy = cy + drawTitle(panel, win, cx, cy, cw, lo and lo.name or ZeD.tr("UI_ZeD_EqBar_NoLoadout"), ZeD.tr("UI_ZeD_Unpack_BackHome"))
            return drawUnpack(panel, win, cx, cy, cw, s.unpack)
        end
        local name = lo and lo.name or (o and o.name) or ZeD.tr("UI_ZeD_EqBar_NoLoadout")
        cy = cy + drawTitle(panel, win, cx, cy, cw, name, lo and L.countText(lo) or (o and L.countText(o)) or nil)
        cy = drawApplied(panel, win, cx, cy, cw)
        if plan then
            cy = drawLoad(panel, win, cx, cy, cw, plan)
            cy = drawTodoRows(panel, win, cx, cy, cw, plan)
        end
        return cy
    end)
    s.askRects = nil
    if s.ask then
        local row = nil
        for _, r in ipairs(plan and plan.rows or {}) do if r.key == s.ask then row = r end end
        if not (row and row.state == "ask") then s.ask = nil
        else
            local by = y + h - bandH
            local _, cancel, verb = M.drawQuestionBand(panel, x, by, w, ZeD.tr("UI_ZeD_Todo_AskLast", row.line.name or "?"),
                ZeD.tr("UI_ZeD_Todo_TakeIt"), { danger = false, win = win,
                    cancelFocus = focusOf(win, "ask:cancel"), verbFocus = focusOf(win, "ask:verb") })
            s.askRects = { cancel = cancel, verb = verb }
        end
    end
end

-- ---------------------------------------------------------------------------
-- INPUT (routed by the Character window's drawer)
-- ---------------------------------------------------------------------------
local function answer(win, yes)
    local s = st(win)
    local key = s.ask
    s.ask, s.askRects = nil, nil
    if yes and key then R.confirmLast(player(win), key) end
    s.land = key and ("row:" .. key) or "v1"
    EL.plan(win, true)
end

function EL.onClick(win, x, y)
    local s = st(win)
    if s.todo and s.ask then
        local r = s.askRects
        if r and inRect(r.verb, x, y) then answer(win, true); sound(); return true end
        if r and inRect(r.cancel, x, y) then answer(win, false); return true end
        return true
    end
    local zs = win._elZones
    for i = #(zs or {}), 1, -1 do
        local z = zs[i]
        if inRect(z, x, y) and (not z.scrolls or inRect(s.clip, x, y)) then
            if z.fn then
                if s.step and z.id ~= "days" and z.id ~= "days:dec" and z.id ~= "days:inc" then s.step = nil end
                z.fn()
                sound("UISelectListItem")
                return true
            end
            if z.keep then return true end
        end
    end
    if s.step then s.step = nil end
    return s.todo   -- (the to-do holds the drawer: nothing under it takes a press)
end

local function element(win, z, dp)
    local s = st(win)
    local el = { x = z.x, y = z.y, w = z.w, h = z.h, id = "el:" .. z.id, slotType = "el:" .. z.id,
                 onFocus = function(w, e) w._gpFocusedEquipSlot = e.slotType end }
    if z.fn then el.onActivate = function() z.fn() end end
    if z.dpad then el.onDpadDir = function(w, e, dir) return z.dpad(dir) end end
    if z.cancel then el.onCancel = function() z.cancel(); return true end
    elseif s.todo then el.onCancel = function(w) EL.closeTodo(w) end end
    return el
end

--- The bar's stops (list mode), appended to the Equip tab's elements after its heading's.
function EL.barFocusables(win, elements)
    if EL.todoOpen(win) then return end
    for _, z in ipairs(win._elZones or {}) do
        if (z.fn or z.dpad) and not z.mouseOnly then elements[#elements + 1] = element(win, z) end
    end
end

--- The to-do's stops: every live zone in view; while the question is up, its two answers alone.
function EL.focusables(win)
    local s = st(win)
    local out = {}
    if s.ask then
        local r = s.askRects
        if not r then return out end
        for _, k in ipairs({ "cancel", "verb" }) do
            local b = r[k]
            if b then
                out[#out + 1] = { x = b.x, y = b.y, w = b.w, h = b.h, id = "el:ask:" .. k, slotType = "el:ask:" .. k,
                    onFocus = function(w, e) w._gpFocusedEquipSlot = e.slotType end,
                    onActivate = function(w) answer(w, k == "verb") end,
                    onCancel = function(w) answer(w, false) end }
            end
        end
        EL.land(win, out)
        if out[1] and not (win._gpFocusedEquipSlot or ""):find("^el:ask:") then
            out._focusIdx = 1
            win._gpFocusedEquipSlot = out[1].slotType
        end
        return out
    end
    for _, z in ipairs(win._elZones or {}) do
        local inView = not z.scrolls or (s.clip and z.y + z.h > s.clip.y and z.y < s.clip.y + s.clip.h)
        if (z.fn or z.dpad) and not z.mouseOnly and inView then out[#out + 1] = element(win, z) end
    end
    EL.land(win, out)
    if out[1] and not out._focusIdx and not win._gpFocusedEquipSlot then
        win._gpFocusedEquipSlot = out[1].slotType
    end
    return out
end

--- Where the focus lands after the to-do opens or closes, or a question is answered.
function EL.land(win, elements)
    local s = st(win)
    if not s.land then return end
    for i, e in ipairs(elements) do
        if e.id == "el:" .. s.land then
            elements._focusIdx = i
            win._gpFocusedEquipSlot = e.slotType
            s.land, s.landTries = nil, nil
            return
        end
    end
    -- (not there after a few builds, e.g. no loadout to show "ready": the usual seed decides)
    s.landTries = (s.landTries or 0) + 1
    if s.landTries > 5 then s.land, s.landTries = nil, nil end
end

--- What moves the stops (rebuild the controller's elements when it changes).
function EL.scrollKey(win)
    local s = win._el
    if not s then return "" end
    return tostring(s.todo) .. ":" .. tostring(s.scroll.scrollPos) .. ":" .. tostring(s.ask) .. ":" .. tostring(s.step)
        .. ":" .. tostring(R.gen) .. ":" .. tostring(L.gen) .. ":" .. tostring(#(win._elZones or {}))
end

-- ---------------------------------------------------------------------------
-- THE WHEEL: a loadout picked sets it in the bar and opens the to-do
-- ---------------------------------------------------------------------------
function EL.fromWheel(p, pn, listId)
    R.setLoadout(p, listId)
    EL.pending[pn] = true
    local H = ZeD.DpadWheels and ZeD.DpadWheels.H
    if H and H.charTab then H.charTab(p, pn, "equip") end
end
