-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardPower.lua
-- ============================================================================
-- OBJECT CARD: GENERATOR (card definition, client)
-- The generator's own front panel in pixel art, one plate per model: the
-- red 1988 portable, the yellow contractor's set, the blue compact and the
-- 1960s military set (ZeDUI/tools/physpx, data in
-- PhysPx.lua, drawn by the shared plate template ZeD_Plate.lua; the plate is
-- picked by the generator's item). Live on it: the engine switch and its lamp,
-- the fuel gauge, the building's cord in the outlet, the OIL lamp (condition
-- under a quarter), the meters (120 volts and 60 cycles while it runs, the
-- load it carries). The engine switch turns it on or off and the outlet
-- connects or disconnects it, with vanilla's rules. Under the plate: the run
-- time left at the current draw and the fuel in litres; then condition, what
-- it powers in L/h, the indoor fumes warning, and vanilla's generator actions
-- as header verbs:
--   TURN ON / OFF  ISActivateGenerator (on needs it connected and fuel; at 50%
--                  condition or less it can fail to start, vanilla rolls that)
--   ADD FUEL       ISAddFuel per petrol can (off, under a full tank)
--   FIX            ISFixGenerator (off, under 100%, Scrap Electronics,
--                  Electricity 3 or the generator magazine)
--   CONNECT / DISCONNECT  ISPlugGenerator (off, same skill)
--   TAKE           ISTakeGenerator (disconnected)
-- All actions go through vanilla's own handlers (walk-adjacent included).
-- Its Simple form (ZeD setup's Devices row; the plain parts below, shared with
-- the grill and the laundry cards): the run time left and the fuel in large
-- type over the fuel gauge, then the engine switch and the outlet (the face's
-- own zones, gen:engine and gen:outlet) and the readings this model's face shows.
-- ============================================================================

require "ZeD/ObjectCards"
require "ZeD/ZeD_PixelParts"
require "ZeD/ZeD_Plate"
require "ZeD/PhysPx"

local OC = ZeD.ObjectCards
local P = ZeD.Px
local PL = ZeD.Plate
local UI = OC.ui
local call = OC.call
local DOT = OC.DOT

-- ============================================================================
-- THE PLAIN OBJECT CARD: the Simple form of the generator, the propane grill and the laundry faces
-- (ZeD setup's Devices row, Full or Simple: ZeD.Settings.devicesSimple).
-- It does everything the face does and shows everything it shows; only the art
-- goes. One layout: a readout block across the top (the one or two values that matter most, in large type), then
-- rows of label | value | control in the face's own order, then what the card already had under the face. Every
-- control is the face's own zone: the same fid, the same run, the same help, so the mouse, the controller and the
-- header verbs work unchanged. Read as each card draws, so switching Full / Simple applies at once.
-- Shared by ObjectCardFire.lua and ObjectCardLaundry.lua (they require this file); the radio tab's simple cards are
-- PlainFace.lua, built the same way.
-- ============================================================================
ZeD.ObjectCardPlain = ZeD.ObjectCardPlain or {}
local OP = ZeD.ObjectCardPlain
OP.BIG_PX = 26            -- the readout's large type (design units), as the radio's simple card

ZeD.trDefaults({
    UI_ZeD_PlainCard_HrsUnit = "hrs",
    UI_ZeD_PlainCard_DaysUnit = "days",
    UI_ZeD_PlainCard_Join = "%1 | %2",
})

-- true while the devices draw as simple cards
function OP.on()
    local S = ZeD.Settings
    if not (S and S.devicesSimple) then return false end
    local ok, v = pcall(S.devicesSimple)
    return ok and v == true
end

-- a row's height: a push button with room round it
local function rowH()
    local T = ZeD.T
    return math.max(T.px(24), T.buttonH + T.px(6))
end

-- one half of an on/off switch: wide enough for either word
local function segW()
    local T, tm = ZeD.T, ZeD.TM
    local f = T.fontF3
    local a = tm:MeasureStringX(f, ZeD.btnCase(ZeD.tr("UI_Off")))
    local b = tm:MeasureStringX(f, ZeD.btnCase(ZeD.tr("UI_On")))
    return math.max(a, b, T.px(14)) + 2 * T.px(8)
end

-- the selected wash (the current one of a switch or a pair), and the focus ink on the words
local _sel = { fill = { r = 0, g = 0, b = 0, a = 0 } }
local _ink = {}
local function selColors(ink)
    local T = ZeD.T
    local f = _sel.fill
    f.r, f.g, f.b, f.a = T.accent.r, T.accent.g, T.accent.b, T.selectionA
    _sel.text = ink and T.textOnFocus or nil
    return _sel
end
local function inkColors()
    _ink.text = ZeD.T.textOnFocus
    return _ink
end

local _bo = {}
local function btnOpts(hover, focus, disabled)
    local o = _bo
    o.hover, o.focus, o.disabled = hover, focus, disabled
    o.help, o.win, o.compact, o.font = nil, nil, nil, nil
    return o
end

-- the widest word of a pair (its keys share one width)
local function pairKeyW(items)
    local mw = 0
    for _, it in ipairs(items) do mw = math.max(mw, ZeD.Molecules.buttonW(it.word)) end
    return mw
end

-- a control's width: "switch" (Off | On), "button" (one push button), "pair" (keys side by side, one selected)
local function ctlW(c)
    if not c then return 0 end
    local T = ZeD.T
    if c.kind == "switch" then return 2 * segW() + T.px(2) end
    if c.kind == "pair" then return #c.items * pairKeyW(c.items) + (#c.items - 1) * T.px(2) end
    return ZeD.Molecules.buttonW(c.word)
end

-- the zone: the face's own (fid, run, help, primary)
local function stamp(card, fid, x, y, w, h, run, help, primary)
    card:zone({ fid = fid, x = x, y = y, w = w, h = h, body = true, primary = primary or nil, help = help, run = run })
end

-- an on/off switch: one control (A or a click toggles it, as the face's switch), the current half selected
local function drawSwitch(card, cx, cy, ch, c)
    local T, M, UI = ZeD.T, ZeD.Molecules, ZeD.ObjectCards.ui
    local sw = segW()
    local cw = 2 * sw + T.px(2)
    local fo = card:focusOf(c.fid)
    local ink = false
    if fo and ZeD.Focus and ZeD.Focus.mark then ink = ZeD.Focus.mark(card, cx, cy, cw, ch, fo) == true end
    local hov = UI.hovered(card, c.fid)
    for i = 1, 2 do
        local isOn = i == 2
        local sel = (c.on == true) == isOn
        local colors = sel and selColors(ink) or (ink and inkColors() or nil)
        M.drawButton(card, cx + (i - 1) * (sw + T.px(2)), cy, sw, ch, ZeD.tr(isOn and "UI_On" or "UI_Off"), "default", false,
            colors, btnOpts(hov and not sel, nil, c.run == nil))
    end
    stamp(card, c.fid, cx, cy, cw, ch, c.run, c.help, c.primary)
end

-- one push button (sel: the current one of a pair; dis: drawn dimmed, else whenever it can't act now)
local function drawKey(card, bx, by, bw, bh, word, fid, run, help, primary, sel, dis)
    local UI = ZeD.ObjectCards.ui
    if dis == nil then dis = run == nil end
    ZeD.Molecules.drawButton(card, bx, by, bw, bh, word, "default", false, sel and selColors(false) or nil,
        btnOpts(UI.hovered(card, fid), card:focusOf(fid), dis))
    stamp(card, fid, bx, by, bw, bh, run, help, primary)
end

local function drawControl(card, cx, cy, ch, c)
    if c.kind == "switch" then
        drawSwitch(card, cx, cy, ch, c)
    elseif c.kind == "pair" then
        local kw, gap = pairKeyW(c.items), ZeD.T.px(2)
        for i, it in ipairs(c.items) do
            drawKey(card, cx + (i - 1) * (kw + gap), cy, kw, ch, it.word, it.fid, it.run, it.help, it.primary, it.sel, it.dis)
        end
    else
        drawKey(card, cx, cy, ctlW(c), ch, c.word, c.fid, c.run, c.help, c.primary, c.sel)
    end
end

-- the value's width: its words (and status square), and a segmented bar after them
local function valueW(r)
    local T = ZeD.T
    local w = 0
    if r.value and r.value ~= "" then
        w = ZeD.TM:MeasureStringX(T.fontF2, r.value) + (r.dot and T.px(10) or 0)
    end
    if r.share then w = w + ZeD.Atoms.rowBarW() + ((w > 0) and T.px(8) or 0) end
    return w
end

-- the value, right-aligned in its room: the words (a status square before them), then the bar
local function drawValue(card, vx, vy, vw, lh, r, label)
    local T, A, tm = ZeD.T, ZeD.Atoms, ZeD.TM
    local right = vx + vw
    if r.share then
        local bw, bh = A.rowBarW(), T.fillBarH
        if vw >= bw then
            A.drawFillBar(card, right - bw, vy + math.floor((lh - bh) / 2), bw, r.share, false, r.shareC, bh, r.shareLabel or label)
            right = right - bw - T.px(8)
        end
    end
    if not (r.value and r.value ~= "") or right <= vx then return end
    local f2 = T.fontF2
    local s = A.truncateText(r.value, f2, right - vx - (r.dot and T.px(10) or 0))
    local sw = tm:MeasureStringX(f2, s)
    A.drawTextRight(card, s, right, vy + math.floor((lh - tm:getFontHeight(f2)) / 2), f2, T.text)
    if r.dot then A.drawStatusDot(card, right - sw - T.px(10), vy + math.floor((lh - T.px(6)) / 2), r.dot, T.px(6)) end
end

-- A row: label | value | control (the control on a line of its own when the three do not fit). Returns its height.
-- r = { label, value, dot (the status square's colour), share (0..1: a segmented bar), shareC, shareLabel, ctl }
-- ctl = { kind = "switch", fid, on, run, help, primary } | { kind = "button", fid, word, run, help, primary }
--     | { kind = "pair", items = { { fid, word, sel, run, help, primary, dis }, ... } }
--     (run nil: the control can't act now, drawn dimmed; a pair's key says dis itself: its current one is lit, not dim)
function OP.row(card, x, y, w, r)
    local T, tm, A = ZeD.T, ZeD.TM, ZeD.Atoms
    local gap = T.px(8)
    local lh = rowH()
    local f1 = T.fontF1
    local label = A.textCase(r.label or "")
    local lw = tm:MeasureStringX(f1, label)
    local c = r.ctl
    local cw = ctlW(c)
    local vw = valueW(r)
    local two = cw > 0 and (lw + gap + vw + gap + cw > w)
    local h = two and (lh + lh) or lh
    local ac = T.accent
    card:drawText(label, x, y + math.floor((lh - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
    local right = x + w
    local vx = x + lw + gap
    local bh = T.buttonH
    local cy = y + math.floor((lh - bh) / 2)
    if two then
        drawValue(card, vx, y, right - vx, lh, r, label)
        cy = cy + lh
    else
        drawValue(card, vx, y, ((cw > 0) and (right - cw - gap) or right) - vx, lh, r, label)
    end
    if c then drawControl(card, right - cw, cy, bh, c) end
    A.drawDividerH(card, x, y + h - T.line(T.borderW), w)
    return h
end

-- The readout block across the top: one or two columns of a small label over a value in large type (a unit after
-- it), an optional line of words, an optional segmented bar the full width, and the strong rule under it.
-- spec = { cols = { { label, big, unit, live (false: the value dim) }, ... }, line, lineC, bar (0..1), barLabel, barC }
function OP.readout(card, x, y, w, spec)
    local T, tm, A = ZeD.T, ZeD.TM, ZeD.Atoms
    local UI = ZeD.ObjectCards.ui
    local f1, f2 = T.fontF1, T.fontF2
    local h1, hb = tm:getFontHeight(f1), T.px(OP.BIG_PX)
    local ac, tc, dc = T.accent, T.text, T.textDim
    local y0 = y
    y = y + T.px(4)
    local cols = spec.cols or {}
    local n = math.max(1, #cols)
    local cg = T.px(16)
    local colW = math.floor((w - (n - 1) * cg) / n)
    for i, c in ipairs(cols) do
        local cx = x + (i - 1) * (colW + cg)
        card:drawText(A.truncateText(A.textCase(c.label or ""), f1, colW), cx, y, ac.r, ac.g, ac.b, 1, f1)
        local bw = UI.big(card, c.big or "--", cx, y + h1 + T.px(2), OP.BIG_PX, (c.live == false) and dc or tc) or 0
        if c.unit and c.unit ~= "" then
            card:drawText(c.unit, cx + bw + T.px(6), y + h1 + T.px(2) + hb - h1, dc.r, dc.g, dc.b, dc.a or 1, f1)
        end
    end
    y = y + h1 + T.px(2) + hb + T.px(6)
    if spec.line and spec.line ~= "" then
        local lc = spec.lineC or tc
        card:drawText(A.truncateText(spec.line, f2, w), x, y, lc.r, lc.g, lc.b, lc.a or 1, f2)
        y = y + tm:getFontHeight(f2) + T.px(4)
    end
    if spec.bar then
        A.drawFillBar(card, x, y, w, spec.bar, false, spec.barC, T.fillBarH, spec.barLabel)
        y = y + T.fillBarH + T.px(4)
    end
    y = y + T.px(2)
    A.drawDividerH(card, x, y, w, true)
    return y + T.line(T.borderW) - y0
end

-- the readings a face shows: the set of its live parts' sources, per plate id (kept)
local _srcs = {}
function OP.sources(pid)
    local key = tostring(pid)
    local f = _srcs[key]
    if f then return f end
    f = {}
    local X = ZeD.PhysPx
    local des = X and X.plates and pid and X.plates[pid]
    for _, part in ipairs(des and des.parts or {}) do
        if part.src then f[part.src] = true end
    end
    _srcs[key] = f
    return f
end

local OIL_COND = 25           -- the OIL lamp lights under a quarter's condition
-- The load meters' full scale: L/h burnt above the engine's own idle. Calibrated against vanilla's
-- own figures (IsoGenerator, B42): idle 0.02; fridge and freezer together 0.13, a lone fridge or freezer 0.08; a
-- stove, washer or dryer 0.09 each while running; a television 0.03, a radio 0.01; a battery charger 0.05; a light
-- switch 0.002 while lit; a stacked washer-dryer 0.9 (ten times the others; vanilla's figure). So a lived-in house
-- reads: the fridge and a few lights about a third of the scale, cooking on top about half, a whole house running
-- everything nine tenths, and a second house on the same generator pins the needle. Past full scale the OVERLOAD lamp
-- lights (the blue set's): vanilla adds no penalty, but the fuel burns that much faster.
local LOAD_FULL = 0.5

ZeD.ObjectCardPower = ZeD.ObjectCardPower or {}
ZeD.ObjectCardPower.LOAD_FULL = LOAD_FULL

local function isGenerator(o) return o ~= nil and instanceof(o, "IsoGenerator") end

local function canElectric(player)
    return player:getPerkLevel(Perks.Electricity) >= 3 or (call(player, "isRecipeActuallyKnown", "Generator") == true)
end

local function scriptItem(fullType)
    local sm = getScriptManager and getScriptManager()
    return sm and fullType and call(sm, "FindItem", fullType) or nil
end

-- "Fridge (0.0800 L/h)" -> "Fridge", "0.0800 L/h" (the value as vanilla writes it)
local function splitPowered(s)
    s = tostring(s or "")
    local name, val = string.match(s, "^(.-)%s*%(([^%(%)]*)%)%s*$")
    if not name then return s, nil end
    return name, val
end

local function petrolCans(player)
    local out = {}
    local inv = player:getInventory()
    local list = inv:getAllEvalRecurse(function(item)
        local fc = item:getFluidContainer()
        return fc ~= nil and fc:contains(Fluid.Petrol)
    end)
    for i = 0, list:size() - 1 do
        local it = list:get(i)
        local fc = it:getFluidContainer()
        out[#out + 1] = {
            item = it,
            amt = fc:getAmount(),
            cap = fc:getCapacity(),
            name = it:getDisplayName(),
            tex = it:getTex(),
            where = OC.whereOf(it, player),
        }
    end
    table.sort(out, function(a, b) return a.amt > b.amt end)
    return out
end

local def = { id = "generator" }

function def.resolve(player, obj)
    if not isGenerator(obj) then return nil end
    local sq = obj:getSquare()
    if not sq then return nil end
    return { obj = obj, sq = sq, key = OC.keyOf(sq, "gen") }
end

function def.valid(t)
    return t.obj ~= nil and t.obj:getSquare() ~= nil and t.obj:getObjectIndex() ~= -1
end

function def.nearby(player)
    local list = {}
    OC.eachSquare(player, OC.LEASH, function(sq)
        local objs = sq:getObjects()
        for i = 0, objs:size() - 1 do
            local o = objs:get(i)
            if isGenerator(o) then list[#list + 1] = def.resolve(player, o) end
        end
    end)
    return OC.sortTargets(list)
end

function def.refresh(t, player)
    local g = t.obj
    local d = {}
    d.fuel = g:getFuel() or 0
    d.max = call(g, "getMaxFuel") or 10
    if d.max <= 0 then d.max = 10 end
    d.pct = g:getFuelPercentage() or 0
    d.cond = g:getCondition() or 0
    d.on = g:isActivated()
    d.conn = g:isConnected()
    d.base = call(g, "getBasePowerConsumption") or 0
    d.total = call(g, "getTotalPowerUsing") or 0
    d.totalStr = call(g, "getTotalPowerUsingString")
    d.baseStr = call(g, "getBasePowerConsumptionString")
    d.items = {}
    local ip = call(g, "getItemsPowered")
    if ip then
        for i = 0, ip:size() - 1 do
            local name, val = splitPowered(ip:get(i))
            d.items[#d.items + 1] = { name = name, val = val }
        end
    end
    local sq = g:getSquare()
    d.toxic = sq ~= nil and not sq:isOutside() and sq:getBuilding() ~= nil
    d.itemType = call(g, "getGeneratorItemType")
    local si = scriptItem(d.itemType)
    d.name = (si and call(si, "getDisplayName")) or getText("ContextMenu_Generator")
    d.tex = si and call(si, "getNormalTexture") or nil
    d.cans = (not d.on and d.pct < 100) and petrolCans(player) or {}
    d.elec = canElectric(player)
    d.scrap = player:getInventory():getFirstTypeRecurse("ElectronicsScrap") ~= nil
    t.d = d

    -- verbs, with vanilla's rules. Running, adding fuel, fixing, connecting and taking it all wait
    -- for one thing the player can do right here: turn it off (the need "the generator turned off").
    local verbs = {}
    local onOK = d.on or (d.conn and d.fuel > 0)
    local function toggle(p, tt)
        ISWorldObjectContextMenu.onActivateGenerator(nil, not tt.obj:isActivated(), tt.obj, p:getPlayerNum())
    end
    t.toggle = onOK and toggle or nil
    t.plug = nil                       -- the outlet: only while it is off (below)
    local off = not d.on
    local fuelOK = off and d.pct < 100 and #d.cans > 0
    local fixOK = off and d.cond < 100 and d.elec and d.scrap
    local plugOK = off and d.elec
    local takeOK = off and not d.conn
    local primary = (d.on and "power") or (d.fuel <= 0 and fuelOK and "fuel") or (onOK and "power") or (not d.conn and plugOK and "plug") or nil
    -- what each waits for: the engine stopped first, then what it needs of its own
    local NEED_OFF = ZeD.tr("UI_ZeD_Power_NeedsOff")
    verbs[#verbs + 1] = { id = "fuel", label = getText("ContextMenu_GeneratorAddFuel"), enabled = fuelOK, primary = primary == "fuel", jump = "gen:can:1",
        sensible = d.pct < 100, needs = off and ZeD.tr("UI_ZeD_Power_NeedsCan") or NEED_OFF, hint = ZeD.tr("UI_ZeD_Power_HintFuel"),
        help = ZeD.tr("UI_ZeD_Power_HelpFuel") }
    verbs[#verbs + 1] = { id = "power", label = getText(d.on and "ContextMenu_Turn_Off" or "ContextMenu_Turn_On"), enabled = onOK, primary = primary == "power", run = toggle,
        needs = ZeD.tr(d.fuel <= 0 and "UI_ZeD_Power_NeedsFuel" or "UI_ZeD_Power_NeedsConnected"), hint = ZeD.tr("UI_ZeD_Power_HintOn"),
        help = ZeD.tr(d.on and "UI_ZeD_Power_HelpOff" or "UI_ZeD_Power_HelpOn") }
    verbs[#verbs + 1] = { id = "fix", label = ZeD.tr("UI_ZeD_Power_Fix"), enabled = fixOK, sensible = d.cond < 100,
        needs = off and ZeD.tr(d.elec and "UI_ZeD_Power_NeedsScrap" or "UI_ZeD_Power_NeedsElec") or NEED_OFF, hint = ZeD.tr("UI_ZeD_Power_HintFix"),
        help = ZeD.tr("UI_ZeD_Power_HelpFix"),
        run = function(p, tt) ISWorldObjectContextMenu.onFixGenerator(nil, tt.obj, p:getPlayerNum()) end }
    local plug = function(p, tt) ISWorldObjectContextMenu.onPlugGenerator(nil, tt.obj, p:getPlayerNum(), not tt.obj:isConnected()) end
    t.plug = plugOK and plug or nil
    verbs[#verbs + 1] = { id = "plug", label = d.conn and ZeD.tr("UI_ZeD_Power_Disconnect") or ZeD.tr("UI_ZeD_Power_Connect"), enabled = plugOK, primary = primary == "plug",
        needs = off and ZeD.tr("UI_ZeD_Power_NeedsElec") or NEED_OFF, hint = ZeD.tr(d.conn and "UI_ZeD_Power_HintDisconnect" or "UI_ZeD_Power_HintConnect"),
        help = ZeD.tr(d.conn and "UI_ZeD_Power_HelpDisconnect" or "UI_ZeD_Power_HelpConnect"), run = plug }
    verbs[#verbs + 1] = { id = "take", label = getText("ContextMenu_Take"), enabled = takeOK,
        needs = off and ZeD.tr("UI_ZeD_Power_NeedsDisconnected") or NEED_OFF, hint = ZeD.tr("UI_ZeD_Power_HintTake"),
        help = ZeD.tr("UI_ZeD_Power_HelpTake"),
        run = function(p, tt) ISWorldObjectContextMenu.onTakeGenerator(nil, tt.obj, p:getPlayerNum()) end }
    t.verbs = verbs
end

function def.title(t) return t.d and t.d.name or getText("ContextMenu_Generator") end
function def.icon(t) return t.d and t.d.tex or nil end
-- the state tag: its words, and the colour of its square mark (none for a plain tag)
function def.pill(t)
    local T = ZeD.T
    if t.d and t.d.on then return ZeD.tr("UI_ZeD_Power_PillRunning"), T.positive end
    return ZeD.tr("UI_Off"), T.textDim
end

-- "33:20" from hours
local function hhmm(hours)
    if not hours or hours <= 0 then return "00:00" end
    local h = math.floor(hours)
    local m = math.floor((hours - h) * 60)
    if h > 99 then return "99:59" end
    return (h < 10 and "0" or "") .. tostring(h) .. ":" .. (m < 10 and "0" or "") .. tostring(m)
end

-- the run time left at the current draw: its words and their key ("33:20" hrs, or days past 100 hours).
-- getTotalPowerUsing already carries the sandbox fuel factor: it is the litres burnt per game hour, so
-- fuel / draw is the run time left
local function runTime(d)
    local hrs, unitKey = "--:--", "UI_ZeD_Power_Hrs"
    if d.on then
        local draw = (d.total and d.total > 0) and d.total or d.base
        if draw and draw > 0 then
            local hh = d.fuel / draw
            if hh >= 100 then
                local days = math.floor(hh / 24)
                hrs, unitKey = (days > 999) and "999+" or tostring(days), "UI_ZeD_Power_Days"
            else
                hrs = hhmm(hh)
            end
        end
    elseif d.fuel <= 0 then
        hrs = "00:00"
    end
    return hrs, unitKey
end

-- the plate for this generator: by its item, else the one a modded set borrows
local function plateFor(d)
    local X = ZeD.PhysPx
    local id = X and (X.items[d.itemType or ""] or X.fallback.generator) or nil
    return X and X.plates[id] or nil, id
end
local function plateTex(name) return P.tex(ZeD.PhysPx.texdir .. name .. ".png") end

-- what the plate's live parts read
local function plateState(d)
    local st = {}
    st.running = d.on
    st.connected = d.conn or d.on
    st.fuel = math.max(0, math.min(1, d.fuel / d.max))
    st.service = d.cond < OIL_COND
    st.volts = d.on and 1 or 0
    st.hz = d.on and 1 or 0
    -- the load: what the powered things burn above the engine's own idle, in the sandbox's units
    local fac = tonumber(SandboxVars and SandboxVars.GeneratorFuelConsumption) or 1
    if fac <= 0 then fac = 1 end
    local extra = math.max(0, (d.total or 0) - (d.base or 0)) / fac
    st.load = d.on and math.max(0, math.min(1, extra / LOAD_FULL)) or 0
    st.overload = d.on and extra > LOAD_FULL or false
    return st
end

ZeD.ObjectCardPower.plateState = plateState

-- the plate (fixed size, centred), its two controls, and the line under it
local function drawPlate(card, x, y, w, t)
    local T = ZeD.T
    local d = t.d
    local des, pid = plateFor(d)
    if not des then return 0 end
    -- the width that fills the card, else the narrow face where the main face at the whole zoom does not fit it
    -- (the card's plate room, the same with or without its scrollbar)
    local room = card._plateRoom or w
    des = P.pick(pid, room) or des
    local Sc = ZeD.Scale
    local k = P.kFit((Sc and Sc.root and Sc.root()) or 1, des.w, room)   -- whole zoom, inside the card
    local px0 = x + PL.centre(w, des.w, k)
    local cv = P.canvas(card, px0, y, k)
    local st = plateState(d)
    PL.draw(cv, des, st, { tex = plateTex, now = getTimestampMs() })
    -- the engine switch turns it on / off; the outlet connects / disconnects (vanilla's rules: t.toggle, t.plug)
    for _, c in ipairs(PL.controls(des, st)) do
        local fid = "gen:" .. c.id
        local fn = (c.id == "engine" and t.toggle) or (c.id == "outlet" and t.plug) or nil
        -- a key (the outlet) takes the pointer's wash and the controller's mark; a knob or
        -- rocker keeps its own lit cue
        if c.kind == "turn" then
            if card._fid == fid then PL.cue(cv, c, T.accent, 0.55) end
        else
            if UI.hovered(card, fid) then PL.hoverKey(cv, c) end
            local fm = card:focusOf(fid)
            if fm then PL.markKey(card, c, px0, y, k, fm) end
        end
        card:zone({ fid = fid, x = px0 + c.x * k, y = y + c.y * k, w = c.w * k, h = c.h * k, body = true,
            help = (c.id == "engine" and ZeD.tr("UI_ZeD_Power_HelpEngine")) or (c.id == "outlet" and ZeD.tr("UI_ZeD_Power_HelpOutlet")) or nil,
            run = fn and function(cc, p) fn(p, t) end or nil })
    end
    local h = des.h * k + T.px(6)
    local hrs, unitKey = runTime(d)
    h = h + UI.pair(card, x, y + h, w, ZeD.tr("UI_ZeD_Power_RunTimeLeft"), ZeD.tr(unitKey, hrs), ZeD.tr("UI_ZeD_Power_Fuel"),
        ZeD.tr("UI_ZeD_Power_FuelOf", string.format("%.1f", d.fuel), math.floor(d.max + 0.5)))
    return h
end

-- ---------------------------------------------------------------------------
-- THE SIMPLE FORM (ZeD.ObjectCardPlain, above): the run time left and the fuel in large type, the fuel gauge as a
-- segmented bar; then the face's two controls in its order, the engine switch and the outlet, as the same zones
-- (gen:engine, gen:outlet); then the readings this model's face shows (its OIL lamp, its volt and cycle meters, its
-- load needle or OVERLOAD lamp). Condition, what it powers and the cans follow, as under the face.
-- ---------------------------------------------------------------------------
ZeD.trDefaults({
    UI_ZeD_PlainCard_OfL = "of %1 L",
    UI_ZeD_PlainCard_Engine = "Engine",
    UI_ZeD_PlainCard_Outlet = "Outlet",
    UI_ZeD_PlainCard_Connected = "Connected",
    UI_ZeD_PlainCard_NotConnected = "Not connected",
    UI_ZeD_PlainCard_OilLamp = "Oil lamp",
    UI_ZeD_PlainCard_LampLit = "Lit",
    UI_ZeD_PlainCard_LampOut = "Out",
    UI_ZeD_PlainCard_Output = "Output",
    UI_ZeD_PlainCard_Volts = "%1 V",
    UI_ZeD_PlainCard_Hz = "%1 Hz",
    UI_ZeD_PlainCard_Load = "Load",
    UI_ZeD_PlainCard_Overload = "Overload",
    UI_ZeD_PlainCard_LoadNormal = "Normal",
})

local function drawPlain(card, x, y, w, t)
    local T = ZeD.T
    local d = t.d
    local OP = ZeD.ObjectCardPlain
    local _, pid = plateFor(d)
    local F = OP.sources(pid)
    local st = plateState(d)
    local y0 = y
    local hrs, unitKey = runTime(d)
    y = y + OP.readout(card, x, y, w, {
        cols = {
            { label = ZeD.tr("UI_ZeD_Power_RunTimeLeft"), big = hrs, live = d.on,
              unit = ZeD.tr(unitKey == "UI_ZeD_Power_Days" and "UI_ZeD_PlainCard_DaysUnit" or "UI_ZeD_PlainCard_HrsUnit") },
            { label = ZeD.tr("UI_ZeD_Power_Fuel"), big = string.format("%.1f", d.fuel),
              unit = ZeD.tr("UI_ZeD_PlainCard_OfL", math.floor(d.max + 0.5)) },
        },
        bar = st.fuel, barLabel = ZeD.tr("UI_ZeD_Power_Fuel"),
    })
    -- the engine switch turns it on / off; the outlet connects / disconnects (vanilla's rules: t.toggle, t.plug)
    y = y + OP.row(card, x, y, w, {
        label = ZeD.tr("UI_ZeD_PlainCard_Engine"),
        value = ZeD.tr(d.on and "UI_ZeD_Power_PillRunning" or "UI_Off"), dot = d.on and T.positive or nil,
        ctl = { kind = "switch", fid = "gen:engine", on = d.on, help = ZeD.tr("UI_ZeD_Power_HelpEngine"),
                run = t.toggle and function(cc, p) t.toggle(p, t) end or nil },
    })
    y = y + OP.row(card, x, y, w, {
        label = ZeD.tr("UI_ZeD_PlainCard_Outlet"),
        value = ZeD.tr(st.connected and "UI_ZeD_PlainCard_Connected" or "UI_ZeD_PlainCard_NotConnected"),
        dot = st.connected and T.positive or nil,
        ctl = { kind = "button", fid = "gen:outlet", word = ZeD.tr(d.conn and "UI_ZeD_Power_Disconnect" or "UI_ZeD_Power_Connect"),
                help = ZeD.tr("UI_ZeD_Power_HelpOutlet"), run = t.plug and function(cc, p) t.plug(p, t) end or nil },
    })
    if F.service then
        y = y + OP.row(card, x, y, w, { label = ZeD.tr("UI_ZeD_PlainCard_OilLamp"),
            value = ZeD.tr(st.service and "UI_ZeD_PlainCard_LampLit" or "UI_ZeD_PlainCard_LampOut"),
            dot = st.service and T.warning or nil })
    end
    if F.volts or F.hz then
        local v = F.volts and ZeD.tr("UI_ZeD_PlainCard_Volts", d.on and 120 or 0) or nil
        local hz = F.hz and ZeD.tr("UI_ZeD_PlainCard_Hz", d.on and 60 or 0) or nil
        local out = (v and hz) and ZeD.tr("UI_ZeD_PlainCard_Join", v, hz) or (v or hz)
        y = y + OP.row(card, x, y, w, { label = ZeD.tr("UI_ZeD_PlainCard_Output"), value = out, dot = d.on and T.positive or nil })
    end
    if F.load or F.overload then
        local word, dot = nil, nil
        if F.overload then
            word = ZeD.tr(st.overload and "UI_ZeD_PlainCard_Overload" or "UI_ZeD_PlainCard_LoadNormal")
            dot = st.overload and T.danger or nil
        end
        y = y + OP.row(card, x, y, w, { label = ZeD.tr("UI_ZeD_PlainCard_Load"), value = word, dot = dot,
            share = F.load and st.load or nil, shareC = st.overload and T.danger or nil })
    end
    return y - y0
end

function def.body(card, x, y, w, t, player)
    local T = ZeD.T
    local d = t.d
    if not d then return 0 end
    local y0 = y
    local gap = T.px(8)
    if d.toxic then
        y = y + UI.warn(card, x, y, w, ZeD.tr("UI_ZeD_Power_Fumes")) + gap
    end
    -- the face, or its simple form (ZeD setup's Devices row: read as it draws, so a change applies at once)
    if ZeD.ObjectCardPlain.on() then
        y = y + drawPlain(card, x, y, w, t) + gap
    else
        y = y + drawPlate(card, x, y, w, t) + gap
    end

    -- condition
    local condC = d.cond > 50 and T.positive or T.warning
    local condTxt = tostring(d.cond) .. "%"
    if d.cond <= 50 then condTxt = ZeD.tr("UI_ZeD_Power_MayFail", condTxt) end
    y = y + UI.meter(card, x, y, w, ZeD.tr("IGUI_invpanel_Condition"), condTxt, d.cond <= 50 and T.warning or nil, d.cond, condC) + gap

    if d.on then
        y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Power_Powering"), tostring(#d.items))
        for _, it in ipairs(d.items) do
            y = y + UI.row(card, x, y, w, nil, it.name, it.val)
        end
        y = y + UI.row(card, x, y, w, nil, d.name, d.baseStr)
        local tf = T.fontF3
        local th = T.px(24)
        local tc = T.text
        local totalStr = d.totalStr or string.format("%.4f L/h", d.total or 0)
        ZeD.Atoms.drawTextRight(card, totalStr, x + w - T.px(2), y + math.floor((th - ZeD.TM:getFontHeight(tf)) / 2), tf, tc)
        local totalTxt = ZeD.tr("IGUI_Total")
        local lw = ZeD.TM:MeasureStringX(tf, totalTxt)
        local vw = ZeD.TM:MeasureStringX(tf, totalStr)
        card:drawText(totalTxt, x + w - T.px(2) - vw - T.px(12) - lw, y + math.floor((th - ZeD.TM:getFontHeight(tf)) / 2), tc.r, tc.g, tc.b, tc.a or 1, tf)
        y = y + th
    elseif #d.cans > 0 then
        y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Fire_AddFromBags"), ZeD.tr("UI_ZeD_Fire_Adds"))
        local room = math.max(0, d.max - d.fuel)
        for i, c in ipairs(d.cans) do
            local add = math.min(c.amt, room)
            local cc = c
            y = y + UI.pick(card, x, y, w, {
                tex = c.tex,
                name = ZeD.tr("UI_ZeD_Power_CanName", c.name, string.format("%.1f", c.amt), math.floor(c.cap + 0.5)),
                where = c.where,
                gain = string.format("+%.1f L", add),
                button = getText("UI_btn_add"),
                fid = "gen:can:" .. i,
                enabled = room > 0,
                help = ZeD.tr("UI_ZeD_Power_HelpAddCan", c.name),
                run = function(card2, p)
                    ISWorldObjectContextMenu.doAddFuelGenerator(nil, t.obj, {}, cc.item, p:getPlayerNum())
                end,
            })
        end
    end
    return y - y0
end

OC.register(def)
