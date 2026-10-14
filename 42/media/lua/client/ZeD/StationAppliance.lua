-- ZeD-UI/42/media/lua/client/ZeD/StationAppliance.lua
-- ============================================================================
-- APPLIANCE VIEW — the Craft tab bound to an oven or a microwave (HOOK_MAP 14)
-- Ovens and microwaves are 1993 hardware, so their controls are a physical
-- panel: a temperature (oven) or power (microwave) knob, a timer knob, a green
-- readout, a power lamp and an ON / OFF key; the oven adds vanilla's °F / °C
-- switch. Under the panel, "In the oven" lists what is cooking with the item
-- card's cooking reading (cooking, then burning).
-- Java contract (vanilla ISOvenUI / ISMicrowaveUI):
--   IsoStove: getMaxTemperature / setMaxTemperature, getTimer / setTimer (s),
--             isRunningFor (s), Activated, sync, syncSpriteGridObjects,
--             getContainer():isPowered()
--   on / off: sendClientCommand(player, 'stove', 'setOvenParamsAndToggle',
--             { x, y, z, timer, maxTemperature })
--   °F / °C : getCore():setCelsius(bool) + saveOptions()
-- Knobs: click the left half to turn down, the right half to turn up, or use
-- the wheel; on a controller the D-pad turns a focused knob one stop.
-- ============================================================================

require "ZeD/Stations"

ZeD = ZeD or {}
ZeD.StationAppliance = ZeD.StationAppliance or {}
local SA = ZeD.StationAppliance
local ST = ZeD.Stations
local call = ST.call

local DEG = string.char(176)

-- Knob stops (vanilla ISOvenUI / ISMicrowaveUI addKnobValues)
local OVEN_TEMPS   = { 0, 50, 100, 150, 200, 250, 300 }              -- °C
local OVEN_TIMES   = { 0, 1, 2, 3, 4, 5, 10, 15, 20, 25, 30, 40, 50, 60, 90, 120 }
local MW_POWERS    = { 50, 70, 90, 110, 130 }
local MW_POWER_TXT = { "LO", "MED-LO", "MED", "MED-HI", "HI" }
local MW_TIMES     = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 45, 60 }

local function hex(h)
    local n = tonumber(string.sub(h, 2), 16) or 0
    return { r = math.floor(n / 65536) / 255, g = (math.floor(n / 256) % 256) / 255, b = (n % 256) / 255, a = 1 }
end

-- Hardware palettes: cream enamel range, black plastic microwave
local PAL = {
    oven = {
        top = hex("#D9D5C9"), bot = hex("#C9C4B5"), edge = hex("#6A675E"), text = hex("#1C1B17"),
        knob = hex("#CFC9BB"), knobHi = hex("#F4F1EA"), knobEdge = hex("#5C584E"), pointer = hex("#1C1B17"),
        key = hex("#EFECE4"), keyText = hex("#1C1B17"), keyEdge = hex("#6A675E"),
        brand = "Premium Technologies  " .. ST.DOT .. "  RANGE",
    },
    micro = {
        top = hex("#2B2B2B"), bot = hex("#1D1D1D"), edge = hex("#000000"), text = hex("#D8D8D8"),
        knob = hex("#343434"), knobHi = hex("#6A6A6A"), knobEdge = hex("#000000"), pointer = hex("#E0E0E0"),
        key = hex("#3A3A3A"), keyText = hex("#E0E0E0"), keyEdge = hex("#000000"),
        brand = "ValuTech  " .. ST.DOT .. "  MICRO-WAVE 700",
    },
}
local LCD_BG, LCD_EDGE = hex("#0F1A10"), hex("#4A4A40")
local LCD_ON, LCD_DIM  = hex("#66EE66"), hex("#3A8A3A")
local LAMP_ON, LAMP_OFF, LAMP_RIM = hex("#FF6A2A"), hex("#5A2A1A"), hex("#2A1208")

-- ----------------------------------------------------------------------------
-- STATE READING
-- ----------------------------------------------------------------------------
local function nearestIdx(list, v)
    local best, bd = 1, nil
    for i, x in ipairs(list) do
        local dd = math.abs(x - (v or 0))
        if not bd or dd < bd then best, bd = i, dd end
    end
    return best
end

local function isCelsius() return getCore() and getCore():isCelsius() end

-- °C oven value as the dial reads it: Fahrenheit rounded to the dial's 25s
local function tempText(c)
    if (c or 0) <= 0 then return "OFF" end
    if isCelsius() then return tostring(math.floor(c + 0.5)) .. DEG .. "C" end
    local f = c * 9 / 5 + 32
    return tostring(math.floor(f / 25 + 0.5) * 25) .. DEG .. "F"
end

local function lists(kind)
    if kind == "micro" then return MW_POWERS, MW_TIMES end
    return OVEN_TEMPS, OVEN_TIMES
end

-- Minutes the timer knob shows: what is left while running, else the setting
local function timerMinutes(obj)
    local t = call(obj, "getTimer") or 0
    local run = call(obj, "isRunningFor") or 0
    if run > 0 then return math.max(0, math.ceil((t - run) / 60)) end
    return math.floor(t / 60 + 0.5)
end

local function clockText(obj)
    local t = call(obj, "getTimer") or 0
    local run = call(obj, "isRunningFor") or 0
    local on = call(obj, "Activated")
    local sec
    if on and run > 0 and t > 0 then sec = math.max(0, t - run)
    elseif t > 0 then sec = t
    else return on and "ON" or "--:--" end
    sec = math.floor(sec + 0.5)
    return string.format("%02d:%02d", math.floor(sec / 60), sec % 60)
end

-- ----------------------------------------------------------------------------
-- CONTROLS
-- ----------------------------------------------------------------------------
local function apply(obj)
    call(obj, "sync")
    call(obj, "syncSpriteGridObjects", false, true)
end

function SA.stepHeat(st, dir)
    local obj = st.obj
    local heats = lists(st.kind)
    local i = nearestIdx(heats, call(obj, "getMaxTemperature"))
    i = math.max(1, math.min(#heats, i + dir))
    call(obj, "setMaxTemperature", heats[i])
    apply(obj)
end

function SA.stepTimer(st, dir)
    local obj = st.obj
    local _, times = lists(st.kind)
    local i = nearestIdx(times, timerMinutes(obj))
    i = math.max(1, math.min(#times, i + dir))
    local min = times[i]
    local run = call(obj, "isRunningFor") or 0
    -- While running, the knob reads time left, so the new stop is time left too
    local sec = min * 60
    if run > 0 and min > 0 then sec = run + sec end
    call(obj, "setTimer", sec)
    apply(obj)
end

function SA.toggle(player, st)
    local obj = st.obj
    local c = call(obj, "getContainer")
    if not (c and call(c, "isPowered")) then return end
    local args = { x = obj:getX(), y = obj:getY(), z = obj:getZ(),
                   timer = call(obj, "getTimer") or 0, maxTemperature = call(obj, "getMaxTemperature") or 0 }
    sendClientCommand(player, "stove", "setOvenParamsAndToggle", args)
end

function SA.toggleUnits()
    local core = getCore()
    if not core then return end
    core:setCelsius(not core:isCelsius())
    core:saveOptions()
end

-- ----------------------------------------------------------------------------
-- CONTENTS — what is cooking, with the item card's reading
-- ----------------------------------------------------------------------------
local function contents(st)
    local out = {}
    local c = call(st.obj, "getContainer")
    local items = c and call(c, "getItems")
    if not items then return out end
    local on = call(st.obj, "Activated")
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it then
            local row = { item = it, name = call(it, "getDisplayName") or "?", tex = call(it, "getTex") }
            if instanceof(it, "Food") and call(it, "isCookable") then
                local ct = call(it, "getCookingTime") or 0
                local toCook = call(it, "getMinutesToCook") or 0
                local toBurn = call(it, "getMinutesToBurn") or 0
                if call(it, "isBurnt") then
                    row.tag, row.mode, row.p = "BURNT", "danger", 1
                elseif call(it, "isCooked") or (toCook > 0 and ct >= toCook) then
                    local span = math.max(1, toBurn - toCook)
                    row.p = math.max(0, math.min(1, (ct - toCook) / span))
                    if on then
                        row.tag, row.mode = "BURNING", "danger"
                    else
                        row.tag, row.mode, row.p = "COOKED", "pos", nil   -- done and safe: no bar
                    end
                    row.left = math.max(0, math.ceil(toBurn - ct))
                else
                    row.p = toCook > 0 and math.max(0, math.min(1, ct / toCook)) or 0
                    row.tag, row.mode = on and "COOKING" or "RAW", on and "warn" or "dim"
                    row.left = math.max(0, math.ceil(toCook - ct))
                end
            end
            out[#out + 1] = row
        end
    end
    return out
end

-- ----------------------------------------------------------------------------
-- DRAWING HELPERS
-- ----------------------------------------------------------------------------
local function disc(panel, cx, cy, r, c, a)
    ZeD.Atoms.drawStatusDot(panel, math.floor(cx - r), math.floor(cy - r), { r = c.r, g = c.g, b = c.b, a = a or 1 }, math.floor(r * 2))
end

-- A radial run of small squares (the knob's pointer line), deg 0 = up.
local function run(panel, cx, cy, deg, r0, r1, c, thick)
    local a = (deg - 90) * math.pi / 180
    local ca, sa = math.cos(a), math.sin(a)
    local t = math.max(1, thick)
    local r = r0
    while r <= r1 do
        panel:drawRect(math.floor(cx + ca * r - t / 2), math.floor(cy + sa * r - t / 2), t, t, c.a or 1, c.r, c.g, c.b)
        r = r + 1
    end
end

local function knob(panel, cx, cy, r, pal, frac, focused)
    local T = ZeD.T
    if focused then disc(panel, cx, cy, r + T.px(4), T.accent, 0.55) end
    disc(panel, cx, cy, r + T.px(2), pal.knobEdge)
    disc(panel, cx, cy, r, pal.knob)
    disc(panel, cx - r * 0.15, cy - r * 0.2, r * 0.62, pal.knobHi, 0.55)
    local deg = -135 + 270 * math.max(0, math.min(1, frac))
    run(panel, cx, cy, deg, r * 0.18, r * 0.82, pal.pointer, T.px(4))
end

local function centerText(panel, text, cx, y, font, c, a)
    local w = ZeD.TM:MeasureStringX(font, text)
    panel:drawText(text, math.floor(cx - w / 2), y, c.r, c.g, c.b, a or c.a or 1, font)
end

-- ----------------------------------------------------------------------------
-- RENDER
-- ----------------------------------------------------------------------------
function SA.render(panel, win, x, y, w, h, state, st)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    local player = win._playerObj
    state._lastZones = state.zones
    state.zones = {}
    state._gpFocusedId = ST.focusedId(win)
    local fid = state._gpFocusedId
    local zones = state.zones
    local obj = st.obj
    local mw = st.kind == "micro"
    local pal = mw and PAL.micro or PAL.oven

    local headH = ST.renderViewHeader(panel, win, x, y, w, state, st)
    local rows = contents(st)

    -- Body: chassis + contents, one scrolling unit
    local chH = T.px(132)
    local rowH = T.px(30)
    local secH = T.sp.catHdrH
    local totalH = T.px(8) + chH + T.px(8) + secH + math.max(1, #rows) * rowH + T.px(10)
    local viewY, viewH = y + headH, h - headH
    local scroll = state.scroll
    local needsScroll = totalH > viewH
    scroll.visible = needsScroll
    local cw = needsScroll and (w - T.sp.scrollbarW) or w
    local off = 0
    if needsScroll then
        scroll.x, scroll.y, scroll.height = x + w - T.sp.scrollbarW, viewY, viewH
        scroll:setBarSize(viewH / totalH)
        off = math.floor(scroll.scrollPos * (totalH - viewH))
    else
        scroll:setScrollPos(0)
    end
    ST.followFocus(state, scroll, fid, viewY, viewH, totalH)
    panel:setStencilRect(x, viewY, cw, viewH)

    -- Chassis (vertical gradient in bands)
    local cx0, cy0, cwid = x + T.px(10), viewY + T.px(8) - off, cw - T.px(20)
    local bands = 12
    for i = 0, bands - 1 do
        local f = i / (bands - 1)
        local r = pal.top.r + (pal.bot.r - pal.top.r) * f
        local g = pal.top.g + (pal.bot.g - pal.top.g) * f
        local b = pal.top.b + (pal.bot.b - pal.top.b) * f
        local by0 = cy0 + math.floor(chH * i / bands)
        local by1 = cy0 + math.floor(chH * (i + 1) / bands)
        panel:drawRect(cx0, by0, cwid, by1 - by0, 1, r, g, b)
    end
    panel:drawRectBorder(cx0, cy0, cwid, chH, 1, pal.edge.r, pal.edge.g, pal.edge.b)

    local heats, times = lists(st.kind)
    local hi = nearestIdx(heats, call(obj, "getMaxTemperature"))
    local ti = nearestIdx(times, timerMinutes(obj))
    local kr = T.px(29)
    local colW = T.px(96)
    local kcy = cy0 + T.px(12) + kr

    -- Left knob: temperature / power
    local lkx = cx0 + T.px(12) + math.floor(colW / 2)
    knob(panel, lkx, kcy, kr, pal, (hi - 1) / (#heats - 1), fid == "craft:a:heat")
    local ly = kcy + kr + T.px(6)
    centerText(panel, mw and "POWER" or "TEMP", lkx, ly, T.fontF1, pal.text)
    local ticks = mw and "LO  .  .  .  HI" or (isCelsius() and ("OFF  100  200  300" .. DEG .. "C") or ("OFF  200  400  575" .. DEG .. "F"))
    centerText(panel, ticks, lkx, ly + tm:getFontHeight(T.fontF1), T.fontF5, pal.text, 0.75)
    zones[#zones + 1] = { type = "aHeat", fid = "craft:a:heat", x = lkx - kr - T.px(4), y = kcy - kr - T.px(4), w = kr * 2 + T.px(8), h = kr * 2 + T.px(8) }

    -- Right knob: timer
    local rkx = cx0 + cwid - T.px(12) - math.floor(colW / 2)
    knob(panel, rkx, kcy, kr, pal, (ti - 1) / (#times - 1), fid == "craft:a:timer")
    centerText(panel, "TIMER", rkx, ly, T.fontF1, pal.text)
    centerText(panel, mw and "0 - 60 MIN" or "0 - 120 MIN", rkx, ly + tm:getFontHeight(T.fontF1), T.fontF5, pal.text, 0.75)
    zones[#zones + 1] = { type = "aTimer", fid = "craft:a:timer", x = rkx - kr - T.px(4), y = kcy - kr - T.px(4), w = kr * 2 + T.px(8), h = kr * 2 + T.px(8) }

    -- Centre: readout, lamp, ON / OFF, °F / °C
    local midX = math.floor((lkx + rkx) / 2)
    local lcdW, lcdH = T.px(132), T.px(44)
    local lcdX, lcdY = midX - math.floor(lcdW / 2), cy0 + T.px(14)
    panel:drawRect(lcdX, lcdY, lcdW, lcdH, 1, LCD_BG.r, LCD_BG.g, LCD_BG.b)
    panel:drawRectBorder(lcdX, lcdY, lcdW, lcdH, 1, LCD_EDGE.r, LCD_EDGE.g, LCD_EDGE.b)
    panel:drawRectBorder(lcdX + 1, lcdY + 1, lcdW - 2, lcdH - 2, 1, LCD_EDGE.r, LCD_EDGE.g, LCD_EDGE.b)
    local clock = clockText(obj)
    local small = mw and MW_POWER_TXT[hi] or tempText(heats[hi])
    local bigF, smallF = T.fontF4, T.fontF1
    local bw = tm:MeasureStringX(bigF, clock)
    local sw = tm:MeasureStringX(smallF, small)
    local tx = midX - math.floor((bw + T.px(8) + sw) / 2)
    panel:drawText(clock, tx, lcdY + math.floor((lcdH - tm:getFontHeight(bigF)) / 2), LCD_ON.r, LCD_ON.g, LCD_ON.b, 1, bigF)
    panel:drawText(small, tx + bw + T.px(8), lcdY + math.floor((lcdH - tm:getFontHeight(smallF)) / 2) + T.px(2), LCD_DIM.r, LCD_DIM.g, LCD_DIM.b, 1, smallF)

    local on = call(obj, "Activated") and true or false
    local cont = call(obj, "getContainer")
    local powered = cont and call(cont, "isPowered") and true or false
    local keyW, keyH = T.px(64), T.px(22)
    local swW = mw and 0 or T.px(64)
    local lampSz = T.px(10)
    local rowW = lampSz + T.px(6) + keyW + (mw and 0 or (T.px(8) + swW))
    local rx0 = midX - math.floor(rowW / 2)
    local ry = lcdY + lcdH + T.px(10)
    local lamp = on and LAMP_ON or LAMP_OFF
    disc(panel, rx0 + lampSz / 2, ry + keyH / 2, lampSz / 2 + 1, LAMP_RIM)
    disc(panel, rx0 + lampSz / 2, ry + keyH / 2, lampSz / 2, lamp)
    local kx = rx0 + lampSz + T.px(6)
    panel:drawRect(kx, ry, keyW, keyH, powered and 1 or 0.45, pal.key.r, pal.key.g, pal.key.b)
    panel:drawRectBorder(kx, ry, keyW, keyH, 1, pal.keyEdge.r, pal.keyEdge.g, pal.keyEdge.b)
    panel:drawRect(kx, ry + keyH - T.px(2), keyW, T.px(2), 1, pal.keyEdge.r, pal.keyEdge.g, pal.keyEdge.b)
    centerText(panel, "ON/OFF", kx + keyW / 2, ry + math.floor((keyH - tm:getFontHeight(T.fontF1)) / 2), T.fontF1, pal.keyText, powered and 1 or 0.45)
    if fid == "craft:a:power" then
        local ac = T.accent
        panel:drawRect(kx, ry, keyW, keyH, 0.55, ac.r, ac.g, ac.b)
    end
    zones[#zones + 1] = { type = "aPower", fid = "craft:a:power", x = kx, y = ry, w = keyW, h = keyH }
    if not mw then
        local sx = kx + keyW + T.px(8)
        local cel = isCelsius()
        local f = T.fontF1
        local fW = tm:MeasureStringX(f, DEG .. "F")
        local trW, trH = T.px(24), T.px(12)
        local tyy = ry + math.floor((keyH - trH) / 2)
        panel:drawText(DEG .. "F", sx, ry + math.floor((keyH - tm:getFontHeight(f)) / 2), pal.text.r, pal.text.g, pal.text.b, cel and 0.5 or 1, f)
        local trX = sx + fW + T.px(4)
        panel:drawRect(trX, tyy, trW, trH, 1, pal.knob.r, pal.knob.g, pal.knob.b)
        panel:drawRectBorder(trX, tyy, trW, trH, 1, pal.edge.r, pal.edge.g, pal.edge.b)
        local nubW = math.floor(trW / 2) - T.px(2)
        local nubX = cel and (trX + trW - T.px(2) - nubW) or (trX + T.px(2))
        panel:drawRect(nubX, tyy + T.px(2), nubW, trH - T.px(4), 1, pal.pointer.r, pal.pointer.g, pal.pointer.b)
        panel:drawText(DEG .. "C", trX + trW + T.px(4), ry + math.floor((keyH - tm:getFontHeight(f)) / 2), pal.text.r, pal.text.g, pal.text.b, cel and 1 or 0.5, f)
        local swTotal = fW + T.px(4) + trW + T.px(4) + tm:MeasureStringX(f, DEG .. "C")
        if fid == "craft:a:units" then
            local ac = T.accent
            panel:drawRect(sx - T.px(2), ry, swTotal + T.px(4), keyH, 0.55, ac.r, ac.g, ac.b)
        end
        zones[#zones + 1] = { type = "aUnits", fid = "craft:a:units", x = sx - T.px(2), y = ry, w = swTotal + T.px(4), h = keyH }
    end

    centerText(panel, pal.brand, cx0 + cwid / 2, cy0 + chH - T.px(16), T.fontF5, pal.text, 0.7)

    -- Contents
    local cyy = cy0 + chH + T.px(8)
    ZeD.Molecules.drawSectionHeader(panel, x + T.px(10), cyy, cw - T.px(20),
        mw and "IN THE MICROWAVE" or "IN THE OVEN", #rows, true, false, T.fontF1, true, T.px(6), secH, true)
    cyy = cyy + secH
    if #rows == 0 then
        panel:drawText("Empty", x + T.px(16), cyy + math.floor((rowH - tm:getFontHeight(T.fontF2)) / 2),
            T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, T.fontF2)
    end
    for _, r in ipairs(rows) do
        local lx = x + T.px(16)
        local isz = T.px(16)
        if r.tex then panel:drawTextureScaledAspect(r.tex, lx, cyy + math.floor((rowH - isz) / 2), isz, isz, 1, 1, 1, 1) end
        local barW, pctW = T.px(110), T.px(40)
        local rx = x + cw - T.px(16)
        local nameMax = rx - pctW - barW - T.px(16) - (lx + isz + T.px(6))
        local tagW = 0
        if r.tag then tagW = tm:MeasureStringX(T.fontF1, r.tag) + T.px(10) + T.px(6) end
        local nstr = ZeD.CraftingCore.truncText(r.name, T.fontF2, math.max(T.px(30), nameMax - tagW))
        local nx = lx + isz + T.px(6)
        panel:drawText(nstr, nx, cyy + math.floor((rowH - tm:getFontHeight(T.fontF2)) / 2), T.text.r, T.text.g, T.text.b, T.text.a, T.fontF2)
        if r.tag then
            local col = (r.mode == "danger") and T.danger or ((r.mode == "pos") and T.positive or ((r.mode == "warn") and T.accent or T.textDim))
            local tgx = nx + tm:MeasureStringX(T.fontF2, nstr) + T.px(6)
            local th = T.px(14)
            local tgy = cyy + math.floor((rowH - th) / 2)
            panel:drawRectBorder(tgx, tgy, tagW - T.px(6), th, col.a or 1, col.r, col.g, col.b)
            panel:drawText(r.tag, tgx + T.px(5), tgy + math.floor((th - tm:getFontHeight(T.fontF1)) / 2), col.r, col.g, col.b, col.a or 1, T.fontF1)
        end
        if r.p then
            local bx = rx - pctW - barW
            local bh = T.px(6)
            local byy = cyy + math.floor((rowH - bh) / 2)
            local s2 = T.surf2
            panel:drawRect(bx, byy, barW, bh, s2.a, s2.r, s2.g, s2.b)
            panel:drawRectBorder(bx, byy, barW, bh, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
            local fc = (r.mode == "danger") and T.danger or ((r.mode == "pos") and T.positive or T.accent)
            panel:drawRect(bx + T.px(1), byy + T.px(1), math.floor((barW - T.px(2)) * r.p), bh - T.px(2), 1, fc.r, fc.g, fc.b)
            local ptxt = r.left and (r.mode == "danger" or r.mode == "warn") and (tostring(r.left) .. "m") or (tostring(math.floor(r.p * 100 + 0.5)) .. "%")
            A.drawTextRight(panel, ptxt, rx, cyy + math.floor((rowH - tm:getFontHeight(T.fontF3)) / 2), T.fontF3,
                r.mode == "danger" and T.danger or T.text)
        end
        A.drawDividerH(panel, x + T.px(10), cyy + rowH - T.px(1), cw - T.px(20), false)
        cyy = cyy + rowH
    end

    panel:clearStencilRect()
    if needsScroll then scroll:draw(panel) end
    ST.drawDropdownFor(panel, state, player, fid, "craft")
end

-- ----------------------------------------------------------------------------
-- INPUT
-- ----------------------------------------------------------------------------
local function hit(z, x, y) return x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h end

local function act(player, st, z, dir)
    if z.type == "aHeat" then SA.stepHeat(st, dir or 1)
    elseif z.type == "aTimer" then SA.stepTimer(st, dir or 1)
    elseif z.type == "aPower" then SA.toggle(player, st)
    elseif z.type == "aUnits" then SA.toggleUnits() end
end

function SA.onClick(win, state, st, x, y)
    local player = win._playerObj
    if ST.viewHeaderClick(state, player, x, y) then return true end
    for _, z in ipairs(state.zones or {}) do
        if z.type ~= "stationDropdown" and hit(z, x, y) then
            local dir = (x < z.x + z.w / 2) and -1 or 1   -- knobs: left half down, right half up
            act(player, st, z, dir)
            return true
        end
    end
    return true
end

function SA.onMouseWheel(win, state, st, del, x, y)
    if state.stDropdownOpen then return ST.dropdownWheel(state, del) end
    for _, z in ipairs(state.zones or {}) do
        if (z.type == "aHeat" or z.type == "aTimer") and hit(z, x, y) then
            act(win._playerObj, st, z, del > 0 and -1 or 1)   -- wheel up turns up
            return true
        end
    end
    if state.scroll and state.scroll.visible then state.scroll:handleMouseWheel(del) end
    return true
end

function SA.buildFocusables(win, state, st)
    if state.stDropdownOpen then return ST.dropdownFocusables(state, win._playerObj, "craft") end
    local out = {}
    local sel = ST.selectFocusable(state)
    if sel then out[#out + 1] = sel end
    for _, z in ipairs(state.zones or {}) do
        if z.fid then
            local el = {
                x = z.x, y = z.y, w = z.w, h = z.h, id = z.fid, craftKind = z.type, zone = z,
                onFocus = function(w, e) end,
                onActivate = function(w, e) act(w._playerObj, st, e.zone, 1) end,
            }
            if z.type == "aHeat" or z.type == "aTimer" then
                -- D-pad left / right turns the knob one stop; up / down navigates
                el.onDpadDir = function(w, e, dir)
                    if dir == "left" then act(w._playerObj, st, e.zone, -1); return true end
                    if dir == "right" then act(w._playerObj, st, e.zone, 1); return true end
                    return false
                end
            end
            out[#out + 1] = el
        end
    end
    ST.addLeaveCancel(out, win, "craft")
    return out
end

function SA.focusKey(win, state, st)
    return "a" .. tostring(st.kind) .. "/" .. tostring(state.scroll and state.scroll.scrollPos or 0)
end

print("[ZeD] StationAppliance: oven and microwave view loaded")
return SA
