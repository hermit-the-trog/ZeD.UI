-- ZeD-UI/42/media/lua/client/ZeD/StationAppliance.lua
-- ============================================================================
-- APPLIANCE VIEW — the Craft tab bound to an oven or a microwave (HOOK_MAP 14)
-- Each of the game's ovens and microwaves shows its own control panel in pixel
-- art (director, Oct 16 2026: one plate per model, fixed size, centred): the
-- 1956 green range, the 1962 red range, the 1985 grey range, the 1992 gas
-- range, the restaurant range, the convection oven, the deep fryer, the 1990
-- touchpad microwave and the 1979 dial microwave (ZeDUI/tools/physpx, data in
-- PhysPx.lua, drawn by the shared plate template ZeD_Plate.lua). The plate is
-- picked by the object's tile; a modded oven or microwave borrows one.
--
-- Every panel drives vanilla's state, nothing more: on / off, the temperature
-- (the oven's stops 0, 50 ... 300 °C; the microwave's five powers) and the
-- timer. Knobs turn a stop a click (the left half down, the right half up, or
-- the wheel; the D-pad on a controller). The touch pads work like the real
-- ones:
--   1985 range   BAKE starts it (at the set heat, 200 °C when unset), BROIL
--                at the top heat; TIMER then ▲ / ▼ set the timer, else ▲ / ▼
--                step the heat; CLEAR / OFF turns it off and clears the timer
--   1992 range   BAKE then the number pads type the heat in the player's units
--                (it lands on the nearest stop), TIMER then the pads type
--                hours and minutes; START sets it going, CANCEL turns it off
--   microwave    the number pads type minutes and seconds (TIME COOK starts a
--                fresh entry), POWER LEVEL steps the power down a level, START
--                cooks, STOP / CLEAR pauses (START goes on) or clears
-- The temperature prints in the player's own unit (the game options; there is
-- no unit switch on a stove). Under the plate a line says what it is doing;
-- under that, "In the oven" lists what is cooking with the item card's cooking
-- reading (cooking, then burning).
-- Java contract (vanilla ISOvenUI / ISMicrowaveUI):
--   IsoStove: getMaxTemperature / setMaxTemperature, getTimer / setTimer (s),
--             isRunningFor (s), Activated, sync, syncSpriteGridObjects,
--             getContainer():isPowered()
--   on / off: sendClientCommand(player, 'stove', 'setOvenParamsAndToggle',
--             { x, y, z, timer, maxTemperature })
-- ============================================================================

require "ZeD/Stations"
require "ZeD/ZeD_PixelParts"
require "ZeD/ZeD_Plate"
require "ZeD/PhysPx"

ZeD = ZeD or {}
ZeD.StationAppliance = ZeD.StationAppliance or {}
local SA = ZeD.StationAppliance
local ST = ZeD.Stations
local P = ZeD.Px
local PL = ZeD.Plate
local call = ST.call

local DEG = string.char(176)

-- Knob stops (vanilla ISOvenUI / ISMicrowaveUI addKnobValues)
local OVEN_TEMPS   = { 0, 50, 100, 150, 200, 250, 300 }              -- °C
local OVEN_TIMES   = { 0, 1, 2, 3, 4, 5, 10, 15, 20, 25, 30, 40, 50, 60, 90, 120 }
local MW_POWERS    = { 50, 70, 90, 110, 130 }
local MW_POWER_TXT = { "LO", "MED-LO", "MED", "MED-HI", "HI" }
local MW_TIMES     = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 45, 60 }
local OVEN_MAX_MIN = 120          -- the ovens' timers run to two hours (the dials' scale)
local MW_MAX_SEC   = 3600         -- a microwave's to an hour
local BAKE_DEFAULT = 200          -- °C: BAKE with nothing set (350 °F lands nearest 200 °C)
local ENTRY_MS     = 20000        -- a typed entry nobody starts is dropped (the real pads time out too)
local SHOW_MS      = 6000         -- a readout called up (BAKE, TIMER, a step) shows this long
local PRESS_MS     = 140          -- a pressed key's shade

local PX = function() return ZeD.PhysPx end

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
local function now() return getTimestampMs() end

local function lists(kind)
    if kind == "micro" then return MW_POWERS, MW_TIMES end
    return OVEN_TEMPS, OVEN_TIMES
end

-- what the appliance is doing now: power, on, the heat, the timer and the time left on it (s)
local function read(st)
    local obj = st.obj
    local r = {}
    local cont = call(obj, "getContainer")
    r.powered = (cont and call(cont, "isPowered")) and true or false
    r.active = call(obj, "Activated") and true or false
    r.on = r.active and r.powered
    r.temp = call(obj, "getMaxTemperature") or 0
    r.timer = call(obj, "getTimer") or 0
    r.run = call(obj, "isRunningFor") or 0
    r.left = 0
    if r.timer > 0 then r.left = (r.run > 0) and math.max(0, r.timer - r.run) or r.timer end
    return r
end

-- Minutes the timer knob shows: what is left while running, else the setting
local function timerMinutes(obj)
    local t = call(obj, "getTimer") or 0
    local run = call(obj, "isRunningFor") or 0
    if run > 0 then return math.max(0, math.ceil((t - run) / 60)) end
    return math.floor(t / 60 + 0.5)
end

-- the plate for this appliance: by its tile, else what its kind borrows
local function spriteName(obj)
    local spr = call(obj, "getSprite")
    return spr and call(spr, "getName") or nil
end
local function isMwPlate(id) return id:sub(1, 3) == "mw_" end
local function isOvenPlate(id) return id:sub(1, 5) == "oven_" or id == "fryer" end
function SA.plateFor(st)
    local X = PX()
    if not X then return nil, nil end
    local id = X.tiles[spriteName(st.obj) or ""]
    if id and not ((st.kind == "micro" and isMwPlate(id)) or (st.kind ~= "micro" and isOvenPlate(id))) then id = nil end
    id = id or X.fallback[st.kind] or "oven_modern"
    return X.plates[id], id
end

-- ----------------------------------------------------------------------------
-- READOUTS
-- ----------------------------------------------------------------------------
local function gameClock()
    local gt = getGameTime and getGameTime()
    local h = gt and gt:getHour() or 10
    local m = gt and gt:getMinutes() or 8
    return h, m
end
-- the 12-hour clock the displays show when idle ("10:08")
local function clock12(h, m)
    local h12 = h % 12
    if h12 == 0 then h12 = 12 end
    return string.format("%d:%02d", h12, m)
end
-- an oven timer: hours and minutes ("0:24", "2:00")
local function hmm(sec)
    local m = math.ceil((sec or 0) / 60)
    return string.format("%d:%02d", math.floor(m / 60), m % 60)
end
-- a microwave timer: minutes and seconds ("0:47", "60:00")
local function mss(sec)
    local s = math.ceil(sec or 0)
    return string.format("%d:%02d", math.floor(s / 60), s % 60)
end
-- a temperature in the player's units, as the displays and the line show it (°F to the nearest 5)
local function tempFig(c)
    if isCelsius() then return tostring(math.floor(c + 0.5)) end
    return tostring(math.floor((c * 9 / 5 + 32) / 5 + 0.5) * 5)
end
local function tempText(c) return tempFig(c) .. DEG .. (isCelsius() and "C" or "F") end

-- typed entries: a microwave's minutes and seconds (up to 4 figures), an oven timer's hours
-- and minutes (up to 3), an oven's heat as typed (up to 3)
local function entryMS(e)
    local d = string.rep("0", 4 - #e) .. e
    return string.format("%d:%s", tonumber(d:sub(1, 2)), d:sub(3, 4)), tonumber(d:sub(1, 2)) * 60 + tonumber(d:sub(3, 4))
end
local function entryHM(e)
    local d = string.rep("0", 3 - #e) .. e
    return string.format("%d:%s", tonumber(d:sub(1, 1)), d:sub(2, 3)), tonumber(d:sub(1, 1)) * 60 + tonumber(d:sub(2, 3))
end

-- ----------------------------------------------------------------------------
-- CONTROLS (vanilla's calls)
-- ----------------------------------------------------------------------------
local function apply(obj)
    call(obj, "sync")
    call(obj, "syncSpriteGridObjects", false, true)
end

local function setTemp(st, c) call(st.obj, "setMaxTemperature", c); apply(st.obj) end
-- the timer to sec seconds left (while it runs, vanilla counts from the start)
local function setLeft(st, sec)
    local run = call(st.obj, "isRunningFor") or 0
    if run > 0 and sec > 0 then sec = run + sec end
    call(st.obj, "setTimer", sec)
    apply(st.obj)
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
    local _, times = lists(st.kind)
    local i = nearestIdx(times, timerMinutes(st.obj))
    i = math.max(1, math.min(#times, i + dir))
    setLeft(st, times[i] * 60)      -- while running, the knob reads time left, so the new stop is time left too
end

-- on / off: vanilla's command, carrying the heat and the timer (time left while it runs, as vanilla's knob reads it)
function SA.toggle(player, st, timerSec)
    local obj = st.obj
    local c = call(obj, "getContainer")
    if not (c and call(c, "isPowered")) then return end
    if timerSec == nil then
        local r = read(st)
        timerSec = (r.run > 0 and r.timer > 0) and math.ceil(r.left / 60) * 60 or r.timer
    end
    local args = { x = obj:getX(), y = obj:getY(), z = obj:getZ(), timer = timerSec, maxTemperature = call(obj, "getMaxTemperature") or 0 }
    sendClientCommand(player, "stove", "setOvenParamsAndToggle", args)
end
local function switch(player, st, on)
    if (call(st.obj, "Activated") and true or false) ~= on then SA.toggle(player, st) end
end

-- ----------------------------------------------------------------------------
-- KEYPADS — each appliance keeps its pad's memory: a typed entry and what it
-- is for, a readout called up, the key last pressed
-- ----------------------------------------------------------------------------
SA._pads = SA._pads or {}
local function padOf(st)
    local p = SA._pads[st.key]
    if not p then p = {}; SA._pads[st.key] = p end
    local t = now()
    if p.entry and t - (p.t or 0) > ENTRY_MS then p.entry, p.entryFor = nil, nil end
    if p.show and t - (p.t or 0) > SHOW_MS then p.show = nil end
    return p
end
local function touch(p, id) p.t = now(); p.pressId, p.pressT = id, p.t end
local function digitOf(id) return id:match("^d(%d)$") end

-- the 1985 range (LECTROMAX): BAKE, BROIL, TIMER, ▲ / ▼, CLEAR / OFF
local function greyPress(player, st, r, p, id)
    if id == "bake" then
        if not r.active then
            if r.temp <= 0 then setTemp(st, BAKE_DEFAULT) end
            switch(player, st, true)
        end
        p.show = "bake"
    elseif id == "broil" then
        setTemp(st, OVEN_TEMPS[#OVEN_TEMPS])
        if not r.active then switch(player, st, true) end
        p.show = "bake"
    elseif id == "timer" then
        p.show = "timer"
    elseif id == "up" or id == "down" then
        local dir = (id == "up") and 1 or -1
        if p.show == "timer" then
            SA.stepTimer(st, dir)
        elseif p.show == "bake" or r.active then
            local i = math.max(2, math.min(#OVEN_TEMPS, nearestIdx(OVEN_TEMPS, r.temp) + dir))   -- OFF only by CLEAR / OFF
            setTemp(st, OVEN_TEMPS[i])
            p.show = "bake"
        end
    elseif id == "clearoff" then
        if r.active then SA.toggle(player, st, 0) elseif r.timer > 0 then setLeft(st, 0) end   -- off, the timer cleared
        p.show = nil
    end
end

-- the 1992 range (PREMIUM TECHNOLOGIES): BAKE / TIMER then the number pads, START, CANCEL, BROIL
local function modernPress(player, st, r, p, id)
    local d = digitOf(id)
    if id == "bake" then
        p.entryFor, p.entry, p.show = "bake", "", "bake"
    elseif id == "timer" then
        p.entryFor, p.entry, p.show = "timer", "", "timer"
    elseif d then
        if not p.entryFor then p.entryFor, p.entry, p.show = "bake", "", "bake" end
        local cap = 3
        p.entry = ((p.entry or "") .. d):sub(-cap)
    elseif id == "broil" then
        setTemp(st, OVEN_TEMPS[#OVEN_TEMPS])
        if not r.active then switch(player, st, true) end
        p.entry, p.entryFor, p.show = nil, nil, "bake"
    elseif id == "start" then
        if p.entryFor == "bake" then
            local c = r.temp > 0 and r.temp or BAKE_DEFAULT
            local v = tonumber(p.entry or "")
            if v then
                if not isCelsius() then v = (v - 32) * 5 / 9 end
                c = OVEN_TEMPS[math.max(2, nearestIdx(OVEN_TEMPS, v))]       -- the nearest stop the oven has (never OFF)
            end
            if c ~= r.temp then setTemp(st, c) end
            if not r.active then switch(player, st, true) end
            p.show = "bake"
        elseif p.entryFor == "timer" then
            if p.entry and p.entry ~= "" then
                local _, mins = entryHM(p.entry)
                setLeft(st, math.min(OVEN_MAX_MIN, mins) * 60)
            end
            p.show = "timer"
        elseif not r.active and r.temp > 0 then
            switch(player, st, true)
            p.show = "bake"
        end
        p.entry, p.entryFor = nil, nil
    elseif id == "cancel" then
        if r.active then SA.toggle(player, st, 0) elseif r.timer > 0 then setLeft(st, 0) end
        p.entry, p.entryFor, p.show = nil, nil, nil
    end
end

-- the 1990 microwave (VALUTECH): the number pads type minutes and seconds
local function mwWhitePress(player, st, r, p, id)
    local d = digitOf(id)
    if id == "timecook" then
        p.entryFor, p.entry = "time", ""
    elseif d then
        if p.entryFor ~= "time" then p.entryFor, p.entry = "time", "" end
        p.entry = ((p.entry or "") .. d):sub(-4)
    elseif id == "power" then
        local i = nearestIdx(MW_POWERS, r.temp) - 1          -- HI, MED-HI ... LO, then round to HI again
        if i < 1 then i = #MW_POWERS end
        setTemp(st, MW_POWERS[i])
        p.show = "power"
    elseif id == "start" then
        if p.entryFor == "time" and p.entry and p.entry ~= "" then
            local _, sec = entryMS(p.entry)
            sec = math.max(1, math.min(MW_MAX_SEC, sec))
            if r.active then setLeft(st, sec)
            else SA.toggle(player, st, sec) end
            p.paused = nil
        elseif not r.active and r.timer > 0 then
            SA.toggle(player, st, math.ceil(r.left))         -- go on from where STOP left it
            p.paused = nil
        end
        p.entry, p.entryFor = nil, nil
    elseif id == "stop" then
        if r.active then
            if r.timer > 0 then SA.toggle(player, st, math.max(1, math.ceil(r.left)))   -- paused: START goes on
            else SA.toggle(player, st, 0) end
            p.paused = true
        else
            if r.timer > 0 then setLeft(st, 0) end
            p.entry, p.entryFor, p.paused = nil, nil, nil
        end
    end
end

-- one press on a plate's control (A, a click)
function SA.press(player, st, pid, id, dir)
    local r = read(st)
    if not r.powered then return end
    local p = padOf(st)
    touch(p, id)
    if pid == "oven_grey" then return greyPress(player, st, r, p, id) end
    if pid == "oven_modern" then return modernPress(player, st, r, p, id) end
    if pid == "mw_white" then return mwWhitePress(player, st, r, p, id) end
    if id == "on" then switch(player, st, true)
    elseif id == "off" then switch(player, st, false)
    elseif id == "onoff" or id == "start" then SA.toggle(player, st)
    elseif id == "heat" or id == "power" then SA.stepHeat(st, dir or 1)
    elseif id == "timer" then SA.stepTimer(st, dir or 1) end
end

-- a knob turned a stop (the wheel, the D-pad, a click on one half)
function SA.turn(player, st, pid, id, dir)
    if not read(st).powered then return end
    touch(padOf(st), nil)
    if id == "heat" or id == "power" then SA.stepHeat(st, dir) elseif id == "timer" then SA.stepTimer(st, dir) end
end

-- ----------------------------------------------------------------------------
-- THE PLATE'S STATE — what its live parts read
-- ----------------------------------------------------------------------------
local function plateState(st, pid, r, p)
    local s = {}
    s.powered, s.power = r.powered, r.powered
    s.on = r.on                     -- lamps: lit while it is on and has power
    s.switched = r.active           -- switches and keys: where the hand left them, power or not
    s.celsius = isCelsius() and true or false
    s.hour, s.minute = gameClock()
    if st.kind == "micro" then
        local i = nearestIdx(MW_POWERS, r.temp)
        s.mwPowerIdx, s.mwPower = i - 1, i
        s.cooking = r.on
        s.timerF60 = math.min(1, r.left / MW_MAX_SEC)
        if p.entryFor == "time" then s.mwText = entryMS(p.entry or "")
        elseif r.active or r.timer > 0 then s.mwText = mss(r.left)
        else s.mwText = clock12(s.hour, s.minute) end
        return s
    end
    s.ovenStop = nearestIdx(OVEN_TEMPS, r.temp) - 1
    s.timerF = math.min(1, r.left / (OVEN_MAX_MIN * 60))
    s.timerOn = r.timer > 0 or p.show == "timer" or p.entryFor == "timer"
    -- the display: a typed entry, a readout called up, the heat while it bakes, the timer, the clock
    local showTemp = false
    if p.entryFor == "bake" then
        if p.entry and p.entry ~= "" then s.vfdText = p.entry; showTemp = true
        else s.vfdText = tempFig(r.temp > 0 and r.temp or BAKE_DEFAULT); showTemp = true end
    elseif p.entryFor == "timer" then
        s.vfdText = (p.entry and p.entry ~= "") and entryHM(p.entry) or hmm(r.left)
    elseif p.show == "timer" then
        s.vfdText = hmm(r.left)
    elseif (p.show == "bake" or r.active) and r.temp > 0 then
        s.vfdText = tempFig(r.temp); showTemp = true
    elseif r.timer > 0 then
        s.vfdText = hmm(r.left)
    else
        s.vfdText = clock12(s.hour, s.minute)
    end
    s.unitF = showTemp and not s.celsius
    s.unitC = showTemp and s.celsius
    return s
end

-- what the plate shows for an appliance now (exposed for QA probes)
function SA.plateState(st)
    local _, pid = SA.plateFor(st)
    return plateState(st, pid, read(st), padOf(st))
end

-- the line under the plate: what it is doing, in words
local function stateLine(st, r)
    if not r.powered then return "NO POWER" end
    local dot = "  " .. ST.DOT .. "  "
    if st.kind == "micro" then
        local pw = MW_POWER_TXT[nearestIdx(MW_POWERS, r.temp)]
        if r.on then return "COOKING" .. dot .. pw .. ((r.timer > 0) and (dot .. mss(r.left) .. " LEFT") or "") end
        return "OFF" .. dot .. pw .. ((r.timer > 0) and (dot .. mss(r.left) .. " SET") or "")
    end
    local heat = (r.temp > 0) and tempText(r.temp) or "OFF"
    local mins = math.ceil(r.left / 60)
    if r.on then return "ON" .. dot .. heat .. ((r.timer > 0) and (dot .. mins .. " MIN LEFT") or "") end
    return "OFF" .. ((r.temp > 0) and (dot .. "SET " .. heat) or "") .. ((r.timer > 0) and (dot .. "TIMER " .. mins .. " MIN") or "")
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
-- RENDER
-- ----------------------------------------------------------------------------
local function plateTex(name)
    local X = PX()
    return P.tex((X and X.texdir or "media/textures/ZeD/physpx/") .. name .. ".png")
end

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
    local mw = st.kind == "micro"

    local headH = ST.renderViewHeader(panel, win, x, y, w, state, st)
    local rows = contents(st)
    local des, pid = SA.plateFor(st)
    local Sc = ZeD.Scale
    local k = P.k((Sc and Sc.root and Sc.root()) or 1)
    local plH = des and des.h * k or 0

    -- Body: the plate, its line, the contents; one scrolling unit
    local lineH = tm:getFontHeight(T.fontF1)
    local rowH = T.px(30)
    local secH = T.sp.catHdrH
    local totalH = T.px(8) + plH + T.px(6) + lineH + T.px(10) + secH + math.max(1, #rows) * rowH + T.px(10)
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

    -- the plate, fixed size, centred
    local r = read(st)
    local pad = padOf(st)
    local cyy = viewY + T.px(8) - off
    if des then
        local px0 = x + PL.centre(cw, des.w, k)
        local cv = P.canvas(panel, px0, cyy, k)
        local pst = plateState(st, pid, r, pad)
        PL.draw(cv, des, pst, { tex = plateTex, now = now() })
        -- the controls: focus cue, a key's press, the click areas (panel px)
        local list = PL.controls(des, pst)
        local held = pad.pressId and (now() - (pad.pressT or 0) < PRESS_MS) and pad.pressId or nil
        for _, c in ipairs(list) do
            local cfid = "craft:a:" .. c.id
            if c.enabled then
                if held == c.id and c.kind ~= "turn" then PL.cue(cv, c, P.BLACK, 0.30) end
                if fid == cfid then PL.cue(cv, c, T.accent, 0.55) end
                zones[#zones + 1] = { type = "plate", fid = cfid, id = c.id, kind = c.kind, pid = pid,
                                      x = px0 + c.x * k, y = cyy + c.y * k, w = c.w * k, h = c.h * k }
            end
        end
        cyy = cyy + plH + T.px(6)
    end
    -- the line under the plate
    local line = stateLine(st, r)
    local lw = tm:MeasureStringX(T.fontF1, line)
    local lc = r.powered and T.text or T.warning
    panel:drawText(line, x + math.floor((cw - lw) / 2), cyy, lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)
    cyy = cyy + lineH + T.px(10)

    -- Contents
    ZeD.Molecules.drawSectionHeader(panel, x + T.px(10), cyy, cw - T.px(20),
        mw and "IN THE MICROWAVE" or "IN THE OVEN", #rows, true, false, T.fontF1, true, T.px(6), secH, true)
    cyy = cyy + secH
    if #rows == 0 then
        panel:drawText("Empty", x + T.px(16), cyy + math.floor((rowH - tm:getFontHeight(T.fontF2)) / 2),
            T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, T.fontF2)
    end
    for _, rw in ipairs(rows) do
        local lx = x + T.px(16)
        local isz = T.px(16)
        if rw.tex then panel:drawTextureScaledAspect(rw.tex, lx, cyy + math.floor((rowH - isz) / 2), isz, isz, 1, 1, 1, 1) end
        local barW, pctW = T.px(110), T.px(40)
        local rx = x + cw - T.px(16)
        local nameMax = rx - pctW - barW - T.px(16) - (lx + isz + T.px(6))
        local tagW = 0
        if rw.tag then tagW = tm:MeasureStringX(T.fontF1, rw.tag) + T.px(10) + T.px(6) end
        local nstr = ZeD.CraftingCore.truncText(rw.name, T.fontF2, math.max(T.px(30), nameMax - tagW))
        local nx = lx + isz + T.px(6)
        panel:drawText(nstr, nx, cyy + math.floor((rowH - tm:getFontHeight(T.fontF2)) / 2), T.text.r, T.text.g, T.text.b, T.text.a, T.fontF2)
        if rw.tag then
            local col = (rw.mode == "danger") and T.danger or ((rw.mode == "pos") and T.positive or ((rw.mode == "warn") and T.accent or T.textDim))
            local tgx = nx + tm:MeasureStringX(T.fontF2, nstr) + T.px(6)
            local th = T.px(14)
            local tgy = cyy + math.floor((rowH - th) / 2)
            panel:drawRectBorder(tgx, tgy, tagW - T.px(6), th, col.a or 1, col.r, col.g, col.b)
            panel:drawText(rw.tag, tgx + T.px(5), tgy + math.floor((th - tm:getFontHeight(T.fontF1)) / 2), col.r, col.g, col.b, col.a or 1, T.fontF1)
        end
        if rw.p then
            local bx = rx - pctW - barW
            local bh = T.px(6)
            local byy = cyy + math.floor((rowH - bh) / 2)
            local s2 = T.surf2
            panel:drawRect(bx, byy, barW, bh, s2.a, s2.r, s2.g, s2.b)
            panel:drawRectBorder(bx, byy, barW, bh, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
            local fc = (rw.mode == "danger") and T.danger or ((rw.mode == "pos") and T.positive or T.accent)
            panel:drawRect(bx + T.px(1), byy + T.px(1), math.floor((barW - T.px(2)) * rw.p), bh - T.px(2), 1, fc.r, fc.g, fc.b)
            local ptxt = rw.left and (rw.mode == "danger" or rw.mode == "warn") and (tostring(rw.left) .. "m") or (tostring(math.floor(rw.p * 100 + 0.5)) .. "%")
            A.drawTextRight(panel, ptxt, rx, cyy + math.floor((rowH - tm:getFontHeight(T.fontF3)) / 2), T.fontF3,
                rw.mode == "danger" and T.danger or T.text)
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

-- a click on a control: a knob turns toward the half clicked, a key presses
local function act(player, st, z, dir)
    if z.kind == "turn" then SA.turn(player, st, z.pid, z.id, dir or 1)
    else SA.press(player, st, z.pid, z.id) end
end

function SA.onClick(win, state, st, x, y)
    local player = win._playerObj
    if ST.viewHeaderClick(state, player, x, y) then return true end
    for _, z in ipairs(state.zones or {}) do
        if z.type == "plate" and hit(z, x, y) then
            act(player, st, z, (x < z.x + z.w / 2) and -1 or 1)   -- knobs: left half down, right half up
            return true
        end
    end
    return true
end

function SA.onMouseWheel(win, state, st, del, x, y)
    if state.stDropdownOpen then return ST.dropdownWheel(state, del) end
    for _, z in ipairs(state.zones or {}) do
        if z.type == "plate" and z.kind == "turn" and hit(z, x, y) then
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
                x = z.x, y = z.y, w = z.w, h = z.h, id = z.fid, craftKind = z.kind, zone = z,
                onFocus = function(w, e) end,
                onActivate = function(w, e) act(w._playerObj, st, e.zone, 1) end,
            }
            if z.kind == "turn" then
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

-- the controls change with the plate and with power (an unpowered panel offers none)
function SA.focusKey(win, state, st)
    local _, pid = SA.plateFor(st)
    return "a" .. tostring(pid) .. "/" .. tostring(read(st).powered) .. "/" .. tostring(#(state.zones or {}))
        .. "/" .. tostring(state.scroll and state.scroll.scrollPos or 0)
end

print("[ZeD] StationAppliance: oven and microwave plates loaded")
return SA
