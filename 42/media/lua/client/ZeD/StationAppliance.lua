-- ZeD-UI/42/media/lua/client/ZeD/StationAppliance.lua
-- ============================================================================
-- APPLIANCE VIEW — client; the Craft tab bound to an oven or a microwave,
-- in place of vanilla's oven window.
-- One thing to know: this is one of the Craft tab's three station views (with
-- StationMachine and StationGeneral); CraftingTab calls render, onClick,
-- onMouseWheel, buildFocusables and focusKey on whichever is bound, so those
-- five keep the same arguments in all three.
-- Each of the game's ovens and microwaves shows its own control panel in pixel
-- art (one plate per model, fixed size, centred): the
-- 1956 green range, the 1962 red range, the 1985 grey range, the 1992 gas
-- range, the restaurant range, the convection oven, the deep fryer, the 1990
-- touchpad microwave and the 1979 dial microwave (plates baked into
-- PhysPx.lua by the tools in ZeDUI/tools/physpx — a generated file — and drawn
-- by the shared plate template ZeD_Plate.lua). The plate is
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
local MW_POWER_TXT = { "UI_ZeD_Appliance_PowerLo", "UI_ZeD_Appliance_PowerMedLo", "UI_ZeD_Appliance_PowerMed", "UI_ZeD_Appliance_PowerMedHi", "UI_ZeD_Appliance_PowerHi" }   -- keys
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
-- a narrow face ("oven_grey_n") or a width ("oven_grey@392") is its main plate's: it routes and
-- counts as the main plate does
local function baseOf(pid) return P.baseId(pid) end
local function isMwPlate(id) return id:sub(1, 3) == "mw_" end
local function isOvenPlate(id) return id:sub(1, 5) == "oven_" or baseOf(id) == "fryer" end
--- The plate and its id for a bound station: by its tile when the tile's plate fits its kind, else the kind's
--- fallback (a modded appliance borrows one).
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
    local b = baseOf(pid)
    if b == "oven_grey" then return greyPress(player, st, r, p, id) end
    if b == "oven_modern" then return modernPress(player, st, r, p, id) end
    -- (the chrome microwave has the white one's keypad)
    if b == "mw_white" or b == "mw_chrome" then return mwWhitePress(player, st, r, p, id) end
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

--- What the plate shows for an appliance now (exposed for QA probes; nothing in the mod calls it).
function SA.plateState(st)
    local _, pid = SA.plateFor(st)
    return plateState(st, pid, read(st), padOf(st))
end

-- the line under the plate: what it is doing, in words (sentence case: it is the
-- window's line, not print on the plate), and the colour of its status mark
local function stateLine(st, r)
    local T = ZeD.T
    local tc = ZeD.textCase
    if not r.powered then return tc(ZeD.tr("UI_ZeD_Appliance_NoPower")), T.warning end
    local dot = "  " .. ST.DOT .. "  "
    if st.kind == "micro" then
        local pw = tc(ZeD.tr(MW_POWER_TXT[nearestIdx(MW_POWERS, r.temp)]))
        if r.on then return tc(ZeD.tr("IGUI_invpanel_Cooking")) .. dot .. pw .. ((r.timer > 0) and (dot .. tc(ZeD.tr("UI_ZeD_Appliance_Left", mss(r.left)))) or ""), T.positive end
        return tc(ZeD.tr("UI_Off")) .. dot .. pw .. ((r.timer > 0) and (dot .. tc(ZeD.tr("UI_ZeD_Appliance_Set", mss(r.left)))) or ""), T.textDim
    end
    local heat = (r.temp > 0) and tempText(r.temp) or tc(ZeD.tr("UI_Off"))
    local mins = math.ceil(r.left / 60)
    if r.on then return tc(ZeD.tr("UI_On")) .. dot .. heat .. ((r.timer > 0) and (dot .. tc(ZeD.tr("UI_ZeD_Appliance_MinLeft", mins))) or ""), T.positive end
    return tc(ZeD.tr("UI_Off")) .. ((r.temp > 0) and (dot .. tc(ZeD.tr("UI_ZeD_Appliance_SetHeat", heat))) or "") .. ((r.timer > 0) and (dot .. tc(ZeD.tr("UI_ZeD_Appliance_TimerMin", mins))) or ""), T.textDim
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
                    row.tag, row.mode, row.p = "IGUI_invpanel_Burnt", "danger", 1
                elseif call(it, "isCooked") or (toCook > 0 and ct >= toCook) then
                    local span = math.max(1, toBurn - toCook)
                    row.p = math.max(0, math.min(1, (ct - toCook) / span))
                    if on then
                        row.tag, row.mode = "IGUI_invpanel_Burning", "danger"
                    else
                        row.tag, row.mode, row.p = "Tooltip_food_Cooked", "pos", nil   -- done and safe: no bar
                    end
                    row.left = math.max(0, math.ceil(toBurn - ct))
                else
                    row.p = toCook > 0 and math.max(0, math.min(1, ct / toCook)) or 0
                    row.tag, row.mode = on and "IGUI_invpanel_Cooking" or "UI_ZeD_Appliance_Raw", on and "warn" or "dim"
                    row.left = math.max(0, math.ceil(toCook - ct))
                end
            end
            out[#out + 1] = row
        end
    end
    return out
end

-- ----------------------------------------------------------------------------
-- THE PLAIN CARD — the Simple form of the faces (ZeD setup's Devices row, Full
-- or Simple: ZeD.Settings.devicesSimple). It does what the face does and shows
-- what it shows; only the art goes. One layout: the readout across the top (the
-- heat and the timer in large type, a microwave's time and power; the line under
-- it says what it is doing), then rows of label | value | control in the face's
-- own order, then the footer band with the face's actions (CLEAR / OFF, CANCEL
-- and START, STOP / CLEAR and START). Every control stamps the zone its face
-- control stamps (the same ids, kinds and fids), so SA.act, the mouse, the wheel
-- on a knob, the D-pad and A work as they do on the face:
--   a knob ("turn")        a stepper, - and +: its left half turns down, the
--                          right half up, the wheel and left / right turn it
--   ON and OFF keys        a switch, each half its key (the 1956 range)
--   a rocker or toggle     a switch, the whole of it the one control ("onoff")
--   ▲ / ▼                  the Adjust row's - and + ("down", "up")
--   the number pads        the Number keys row, laid out as the face lays them
--   the other keys         a button on their row (BAKE, BROIL, TIMER, POWER
--                          LEVEL, TIME COOK)
-- What the face's glass shows (a typed entry, a readout called up, the heat with
-- its unit lamp, the clock) is the Display row; the 1956 range's clock is a row.
-- ----------------------------------------------------------------------------
if ZeD.trDefaults then
    ZeD.trDefaults({
        UI_ZeD_PlainStation_Display = "Display",
        UI_ZeD_PlainStation_Bake = "Bake",
        UI_ZeD_PlainStation_Broil = "Broil",
        UI_ZeD_PlainStation_Adjust = "Adjust",
        UI_ZeD_PlainStation_Keys = "Number keys",
        UI_ZeD_PlainStation_ClearOff = "Clear / off",
        UI_ZeD_PlainStation_Start = "Start",
        UI_ZeD_PlainStation_StopClear = "Stop / clear",
        UI_ZeD_PlainStation_TimeCook = "Time cook",
        UI_ZeD_PlainStation_PowerLevel = "Power level",
    })
end

local PLAIN_MAX_W  = 480          -- design units: the full card, never wider
local PLAIN_BIG_PX = 26           -- the readout's large type (design units)
local PLAIN_BIG_MIN = 18          -- ... where 26 does not fit its half
local DASH = "--"

--- SA.simple(): true while the devices are drawn as plain cards (read as they draw: a change applies at once)
local function devicesSimple()
    local S = ZeD.Settings
    return S ~= nil and S.devicesSimple ~= nil and S.devicesSimple() == true
end
SA.simple = devicesSimple

-- (hoisted: the parts below call each other)
local plainCard

-- the face's keys that are actions: the footer band's buttons, in the face's order
local FOOT = { clearoff = "UI_ZeD_PlainStation_ClearOff", cancel = "UI_Cancel", stop = "UI_ZeD_PlainStation_StopClear",
               start = "UI_ZeD_PlainStation_Start" }
-- the keys with a row of their own: the row's label and the button's word
local KEYROW = {
    bake     = { label = "UI_ZeD_PlainStation_Bake", word = "UI_ZeD_PlainStation_Bake" },
    broil    = { label = "UI_ZeD_PlainStation_Broil", word = "UI_ZeD_PlainStation_Broil" },
    timer    = { label = "IGUI_Timer", word = "IGUI_Timer" },
    power    = { label = "UI_ZeD_PlainStation_PowerLevel", word = "UI_ZeD_PlainStation_PowerLevel" },
    timecook = { label = "UI_ZeD_PlainStation_TimeCook", word = "UI_ZeD_PlainStation_TimeCook" },
}
-- the number pads as the faces lay them: the 1992 range in two rows of five, the microwaves in rows of three
-- with 0 under 8 (each { id, column, row }, 0-based, in the face's order)
local KEYS5 = { { "d1", 0, 0 }, { "d2", 1, 0 }, { "d3", 2, 0 }, { "d4", 3, 0 }, { "d5", 4, 0 },
                { "d6", 0, 1 }, { "d7", 1, 1 }, { "d8", 2, 1 }, { "d9", 3, 1 }, { "d0", 4, 1 } }
local KEYS3 = { { "d1", 0, 0 }, { "d2", 1, 0 }, { "d3", 2, 0 }, { "d4", 0, 1 }, { "d5", 1, 1 }, { "d6", 2, 1 },
                { "d7", 0, 2 }, { "d8", 1, 2 }, { "d9", 2, 2 }, { "d0", 1, 3 } }

-- a face's plain rows and footer actions (per main plate, kept): { rows = { { t, id } }, foot = { ids } }
local _plainSpec = {}
local function plainSpec(b)
    local spec = _plainSpec[b]
    if spec then return spec end
    spec = { rows = {}, foot = {} }
    local X = PX()
    local des = X and X.plates and X.plates[b]
    local hits = des and des.hits or {}
    local mw = isMwPlate(b)
    local rows, have = spec.rows, {}
    -- what the face shows and nobody presses comes first: its glass, or the 1956 range's clock
    if b == "oven_grey" or b == "oven_modern" or mw then rows[#rows + 1] = { t = "display" } end
    if b == "oven_green" then rows[#rows + 1] = { t = "clock" } end
    for _, hh in ipairs(hits) do
        local id, kind = hh.id, hh.kind or "press"
        if kind ~= "look" and not have[id] then
            have[id] = true
            if kind == "turn" then
                rows[#rows + 1] = { t = "stepper", id = id }
            elseif id == "on" or id == "off" then
                have.on, have.off = true, true
                rows[#rows + 1] = { t = "switch2" }
            elseif id == "onoff" then
                rows[#rows + 1] = { t = "switch", id = id }
            elseif id == "up" or id == "down" then
                have.up, have.down = true, true
                rows[#rows + 1] = { t = "arrows" }
            elseif id:match("^d%d$") then
                for i = 0, 9 do have["d" .. i] = true end
                rows[#rows + 1] = { t = "keys", grid = mw and KEYS3 or KEYS5 }
            elseif FOOT[id] then
                spec.foot[#spec.foot + 1] = id
            elseif KEYROW[id] then
                rows[#rows + 1] = { t = "key", id = id }
            end
        end
    end
    if des then _plainSpec[b] = spec end   -- (kept once the plates are loaded)
    return spec
end

-- WHAT THE ROWS READ: text, status colour (x = { st, r, p, s, mw })
local function powerVal(x)
    local T, r = ZeD.T, x.r
    if r.on then return ZeD.tr("UI_On"), T.positive end
    if not r.powered then return ZeD.tr("UI_ZeD_Appliance_NoPower"), T.warning end
    return ZeD.tr("UI_Off"), nil
end
local function heatVal(x)
    local r = x.r
    if r.temp <= 0 then return ZeD.tr("UI_Off"), nil end
    return tempText(r.temp), r.on and ZeD.T.positive or nil
end
local function ovenTimerVal(x)
    local r = x.r
    if r.timer <= 0 then return ZeD.tr("UI_Off"), nil end
    if r.run > 0 then return ZeD.tr("UI_ZeD_Appliance_Left", hmm(r.left)), r.on and ZeD.T.positive or nil end
    return ZeD.tr("UI_ZeD_Appliance_Set", hmm(r.left)), nil
end
local function mwTimeVal(x)
    local r = x.r
    if r.timer <= 0 then return DASH, nil end
    if r.active then return ZeD.tr("UI_ZeD_Appliance_Left", mss(r.left)), r.on and ZeD.T.positive or nil end
    return ZeD.tr("UI_ZeD_Appliance_Set", mss(r.left)), nil
end
local function mwPowerWord(x)
    return ZeD.textCase(ZeD.tr(MW_POWER_TXT[nearestIdx(MW_POWERS, x.r.temp)]))
end
-- the face's glass: what it shows now, with its unit lamp (°F / °C) as the unit
local function displayVal(x)
    local s = x.s
    if x.mw then return s.mwText or DASH, s.cooking and ZeD.T.positive or nil end
    local t = s.vfdText or DASH
    if s.unitF then t = t .. DEG .. "F" elseif s.unitC then t = t .. DEG .. "C" end
    return t, x.r.on and ZeD.T.positive or nil
end
-- the timer key's row (the touch pads): the timer and its lamp
local function timerKeyVal(x)
    local r = x.r
    local t = (r.timer > 0) and hmm(r.left) or DASH
    return t, x.s.timerOn and ZeD.T.positive or nil
end
-- what ▲ / ▼ step now: the timer once TIMER is pressed, the heat while it bakes, nothing else
local function adjustVal(x)
    local p, r = x.p, x.r
    if p.show == "timer" then return ZeD.tr("IGUI_Timer"), nil end
    if p.show == "bake" or r.active then return ZeD.tr("IGUI_Temperature"), nil end
    return DASH, nil
end
-- the number keys: what is typed so far, in the units it will be read in
local function keysVal(x)
    local p = x.p
    if not p.entryFor then return DASH, nil end
    local e = p.entry or ""
    if p.entryFor == "time" then return (entryMS(e)), nil end
    if p.entryFor == "timer" then return (entryHM(e)), nil end
    if e == "" then return DASH, nil end
    return e .. DEG .. (isCelsius() and "C" or "F"), nil
end
local KEYVAL = {
    bake = function(x) local r = x.r; return tempText(r.temp > 0 and r.temp or BAKE_DEFAULT), nil end,
    broil = function() return tempText(OVEN_TEMPS[#OVEN_TEMPS]), nil end,
    timer = timerKeyVal,
    power = function(x) return mwPowerWord(x), nil end,
    timecook = mwTimeVal,
}

local function rowVal(x, rw)
    local t = rw.t
    if t == "display" then return displayVal(x) end
    if t == "clock" then return clock12(gameClock()), nil end
    if t == "stepper" then if rw.id == "timer" then return ovenTimerVal(x) end; return heatVal(x) end
    if t == "switch" or t == "switch2" then return powerVal(x) end
    if t == "arrows" then return adjustVal(x) end
    if t == "keys" then return keysVal(x) end
    if t == "key" then local f = KEYVAL[rw.id]; if f then return f(x) end end
    return nil, nil
end
local function rowLabel(rw)
    local t = rw.t
    if t == "display" then return ZeD.tr("UI_ZeD_PlainStation_Display") end
    if t == "clock" then return ZeD.tr("UI_DisplayOptions_Clock") end
    if t == "stepper" then return ZeD.tr(rw.id == "timer" and "IGUI_Timer" or "IGUI_Temperature") end
    if t == "switch" or t == "switch2" then return ZeD.tr("IGUI_RadioPower") end
    if t == "arrows" then return ZeD.tr("UI_ZeD_PlainStation_Adjust") end
    if t == "keys" then return ZeD.tr("UI_ZeD_PlainStation_Keys") end
    if t == "key" then return ZeD.tr(KEYROW[rw.id].label) end
    return ""
end

-- THE PARTS' SIZES
local function pRowH() local T = ZeD.T; return math.max(T.px(24), T.buttonH + T.px(6)) end
local function pKeyW() return ZeD.T.buttonH + ZeD.T.px(2) end
local function pGap() return ZeD.T.px(4) end
local function pSegW()
    local T, tm = ZeD.T, ZeD.TM
    local a = tm:MeasureStringX(T.fontF3, ZeD.btnCase(ZeD.tr("UI_Off")))
    local b = tm:MeasureStringX(T.fontF3, ZeD.btnCase(ZeD.tr("UI_On")))
    return math.max(a, b, T.px(14)) + 2 * T.px(8)
end
local function padKeyW() return ZeD.T.buttonH + ZeD.T.px(12) end
-- a row's control width (inline); a number pad sits on lines of its own
local function ctlW(rw)
    local t = rw.t
    if t == "stepper" or t == "arrows" then return 2 * pKeyW() + pGap() end
    if t == "switch" or t == "switch2" then return 2 * pSegW() + ZeD.T.px(2) end
    if t == "key" then return ZeD.Molecules.buttonW(ZeD.tr(KEYROW[rw.id].word)) end
    return 0
end
local function gridSize(grid)
    local cols, lines = 0, 0
    for _, g in ipairs(grid) do cols = math.max(cols, g[2] + 1); lines = math.max(lines, g[3] + 1) end
    return cols, lines
end

-- the large type: ZeD's distance-field heading face (the game's largest ZeD font where it is missing)
local function bigFace()
    local F = ZeD.Font
    local hf = F and F.sdf and F.sdf.head
    if hf and ZeD.Text and ZeD.Text.draw and ZeD.Text.width and ZeD.Text.zoomPx then return hf end
    return nil
end
local function bigW(text, px)
    local hf = bigFace()
    if hf then return ZeD.Text.width(hf, text, ZeD.Text.zoomPx(px)) end
    return ZeD.TM:MeasureStringX(ZeD.T.fontF4, text)
end
local function bigH()
    if bigFace() then return ZeD.T.px(PLAIN_BIG_PX) end
    return ZeD.TM:getFontHeight(ZeD.T.fontF4)
end
-- the large value in room px: 26 units, else 18, else cut short
local function bigDraw(panel, text, x, y, room, c)
    local px = PLAIN_BIG_PX
    if bigW(text, px) > room then px = PLAIN_BIG_MIN end
    local n = 0
    while #text > 1 and bigW(text, px) > room and n < 40 do text = text:sub(1, #text - 1); n = n + 1 end
    local hf = bigFace()
    -- (the smaller size sits on the larger one's baseline)
    local dy = (px < PLAIN_BIG_PX and hf) and (ZeD.T.px(PLAIN_BIG_PX) - ZeD.T.px(px)) or 0
    if hf then ZeD.Text.draw(panel, hf, text, x, y + dy, ZeD.Text.zoomPx(px), c.r, c.g, c.b, c.a or 1, "l")
    else panel:drawText(text, x, y, c.r, c.g, c.b, c.a or 1, ZeD.T.fontF4) end
end

-- the readout's two values: label, value, live (false: drawn dim)
local function readoutOf(x)
    local r, p = x.r, x.p
    if x.mw then
        local t
        if p.entryFor == "time" then t = (entryMS(p.entry or ""))
        elseif r.timer > 0 then t = mss(r.left) else t = DASH end
        return ZeD.tr("IGUI_Timer"), t, r.on or p.entryFor == "time",
               ZeD.tr("UI_ZeD_PlainStation_PowerLevel"), mwPowerWord(x), r.powered
    end
    return ZeD.tr("IGUI_Temperature"), (r.temp > 0) and tempText(r.temp) or ZeD.tr("UI_Off"), r.on,
           ZeD.tr("IGUI_Timer"), (r.timer > 0) and hmm(r.left) or DASH, r.powered and r.timer > 0
end

-- the readout block: two small labels, the two values in large type, the line saying what it is doing
local function pReadout(panel, x0, y, w, x, draw)
    local T, tm, A = ZeD.T, ZeD.TM, ZeD.Atoms
    local pad = T.px(10)
    local f1, f2 = T.fontF1, T.fontF2
    local h1, h2, hb = tm:getFontHeight(f1), tm:getFontHeight(f2), bigH()
    local h = T.px(8) + h1 + T.px(2) + hb + T.px(4) + h2 + T.px(8)
    if not draw then return h end
    local l1, v1, live1, l2, v2, live2 = readoutOf(x)
    local colW = math.floor((w - 2 * pad - (x.iconW or 0)) / 2)
    local ty = y + T.px(8)
    local by = ty + h1 + T.px(2)
    local ac, tc, dc = T.accent, T.text, T.textDim
    local cx1, cx2 = x0 + pad, x0 + pad + colW
    panel:drawText(A.textCase(l1), cx1, ty, ac.r, ac.g, ac.b, 1, f1)
    panel:drawText(A.textCase(l2), cx2, ty, ac.r, ac.g, ac.b, 1, f1)
    bigDraw(panel, v1, cx1, by, colW - T.px(8), live1 and tc or dc)
    bigDraw(panel, v2, cx2, by, colW, live2 and tc or dc)
    -- what it is doing, in words, after its status mark (the line the face has under it)
    local line, mark = stateLine(x.st, x.r)
    local sq = T.px(6)
    local ly = by + hb + T.px(4)
    A.drawStatusDot(panel, cx1, ly + math.floor((h2 - sq) / 2), mark, sq)
    local s = A.truncateText(line, f2, w - 2 * pad - sq - T.px(6))
    panel:drawText(s, cx1 + sq + T.px(6), ly, tc.r, tc.g, tc.b, tc.a or 1, f2)
    return h
end

-- one control's zone: the face's id, kind and fid (stamped only while the face would offer it: with power)
local function stamp(x, id, kind, zx, zy, zw, zh)
    if not x.enabled then return end
    local zs = x.zones
    zs[#zs + 1] = { type = "plate", fid = "craft:a:" .. id, id = id, kind = kind, pid = x.pid, x = zx, y = zy, w = zw, h = zh }
end
local _bo = {}
local _sel = { fill = { r = 0, g = 0, b = 0, a = 0 } }
local _ink = {}
local function selColors(ink)
    local T = ZeD.T
    local f = _sel.fill
    f.r, f.g, f.b, f.a = T.accent.r, T.accent.g, T.accent.b, T.selectionA
    _sel.text = ink and T.textOnFocus or nil
    return _sel
end
local function inkColors() _ink.text = ZeD.T.textOnFocus; return _ink end
-- the focus opts for a control with the controller's focus, else nil
local function focusOf(x, id)
    if x.fid ~= "craft:a:" .. id then return nil end
    return x.markOpts or true
end
local function hovered(panel, x, bx, by, bw, bh)
    return x.hoverOK and ZeD.Atoms.mouseIn(panel, bx, by, bw, bh) or false
end
local function pressedOf(x, id) return x.held == id end
-- one push button (hover, focus, the pressed shade, selected, disabled while there is no power)
local function pButton(panel, x, bx, by, bw, bh, text, id, selected, colors, noFocus)
    local o = _bo
    o.hover = hovered(panel, x, bx, by, bw, bh)
    o.focus = (not noFocus) and focusOf(x, id) or nil
    o.disabled = not x.enabled
    o.help, o.win = nil, x.win
    ZeD.Molecules.drawButton(panel, bx, by, bw, bh, text, "default", pressedOf(x, id),
        colors or (selected and selColors(false) or nil), o)
end
-- the mark over a control of two parts; true when the parts' words take the focus ink
local function markWhole(panel, x, id, cx, cy, cw, ch)
    local fo = focusOf(x, id)
    if not (fo and ZeD.Focus and ZeD.Focus.mark) then return false end
    return ZeD.Focus.mark(panel, cx, cy, cw, ch, fo ~= true and fo or nil) == true
end

-- the control's parts at (cx, cy) and their zones
local function pControl(panel, x, rw, cx, cy, ch)
    local T = ZeD.T
    local t = rw.t
    if t == "stepper" then
        -- a knob: one control, - and + (the left half turns down, the right half up)
        local kw, gap = pKeyW(), pGap()
        local ink = markWhole(panel, x, rw.id, cx, cy, 2 * kw + gap, ch)
        local col = ink and inkColors() or nil
        pButton(panel, x, cx, cy, kw, ch, "-", rw.id, false, col, true)
        pButton(panel, x, cx + kw + gap, cy, kw, ch, "+", rw.id, false, col, true)
        stamp(x, rw.id, "turn", cx, cy, 2 * kw + gap, ch)
    elseif t == "arrows" then
        -- ▲ / ▼: two keys
        local kw, gap = pKeyW(), pGap()
        pButton(panel, x, cx, cy, kw, ch, "-", "down", false)
        stamp(x, "down", "press", cx, cy, kw, ch)
        pButton(panel, x, cx + kw + gap, cy, kw, ch, "+", "up", false)
        stamp(x, "up", "press", cx + kw + gap, cy, kw, ch)
    elseif t == "switch2" then
        -- the ON and OFF keys: each half its key, the side the hand left it at selected
        local sw = pSegW()
        local on = x.r.active
        pButton(panel, x, cx, cy, sw, ch, ZeD.tr("UI_Off"), "off", not on)
        stamp(x, "off", "press", cx, cy, sw, ch)
        pButton(panel, x, cx + sw + T.px(2), cy, sw, ch, ZeD.tr("UI_On"), "on", on)
        stamp(x, "on", "press", cx + sw + T.px(2), cy, sw, ch)
    elseif t == "switch" then
        -- a rocker or a toggle: one control (a press throws it)
        local sw = pSegW()
        local on = x.r.active
        local ink = markWhole(panel, x, rw.id, cx, cy, 2 * sw + T.px(2), ch)
        for i = 1, 2 do
            local isOn = i == 2
            local sel = on == isOn
            local col = sel and selColors(ink) or (ink and inkColors() or nil)
            pButton(panel, x, cx + (i - 1) * (sw + T.px(2)), cy, sw, ch, ZeD.tr(isOn and "UI_On" or "UI_Off"), rw.id, false, col, true)
        end
        stamp(x, rw.id, "press", cx, cy, 2 * sw + T.px(2), ch)
    elseif t == "key" then
        local bw = ctlW(rw)
        pButton(panel, x, cx, cy, bw, ch, ZeD.tr(KEYROW[rw.id].word), rw.id, false)
        stamp(x, rw.id, "press", cx, cy, bw, ch)
    end
end

-- the number pad under its row's label, at the row's right edge, laid out as the face lays it
local function pKeys(panel, x, rw, right, y)
    local T = ZeD.T
    local kw, gap, bh = padKeyW(), pGap(), T.buttonH
    local cols = gridSize(rw.grid)
    local gx = right - (cols * kw + (cols - 1) * gap)
    for _, g in ipairs(rw.grid) do
        local id = g[1]
        local bx, by = gx + g[2] * (kw + gap), y + g[3] * (bh + gap)
        pButton(panel, x, bx, by, kw, bh, id:sub(2), id, false)
        stamp(x, id, "press", bx, by, kw, bh)
    end
end

-- a value at the right of its room, its status mark before it
local function pValue(panel, vx, vy, vw, lh, text, dot)
    local T, A = ZeD.T, ZeD.Atoms
    if not text or text == "" or vw <= 0 then return end
    local f2 = T.fontF2
    local s = A.truncateText(text, f2, vw - (dot and T.px(10) or 0))
    local sw = ZeD.TM:MeasureStringX(f2, s)
    local ty = vy + math.floor((lh - ZeD.TM:getFontHeight(f2)) / 2)
    A.drawTextRight(panel, s, vx + vw, ty, f2, T.text)
    if dot then A.drawStatusDot(panel, vx + vw - sw - T.px(10), vy + math.floor((lh - T.px(6)) / 2), dot, T.px(6)) end
end

-- A ROW: label | value | control (the control on a line of its own when the three do not fit; a number pad
-- always under its label)
local function pRow(panel, x0, y, w, x, rw, draw)
    local T, tm, A = ZeD.T, ZeD.TM, ZeD.Atoms
    local pad, gap = T.px(10), T.px(8)
    local lh = pRowH()
    local inner = w - 2 * pad
    local label = A.textCase(rowLabel(rw))
    local text, dot = rowVal(x, rw)
    local cw = ctlW(rw)
    local lw = tm:MeasureStringX(T.fontF1, label)
    local vw = (text and text ~= "") and (tm:MeasureStringX(T.fontF2, text) + T.px(10)) or 0
    local h
    local two = cw > 0 and (lw + gap + vw + gap + cw > inner)
    local padH = 0
    if rw.t == "keys" then
        local _, lines = gridSize(rw.grid)
        padH = lines * (T.buttonH + pGap()) - pGap() + T.px(6)
        h = lh + padH
    else
        h = two and (lh + lh) or lh
    end
    if not draw then return h end
    local ac = T.accent
    local lx = x0 + pad
    local right = x0 + w - pad
    local bh = T.buttonH
    panel:drawText(label, lx, y + math.floor((lh - tm:getFontHeight(T.fontF1)) / 2), ac.r, ac.g, ac.b, 1, T.fontF1)
    if rw.t == "keys" then
        pValue(panel, lx + lw + gap, y, right - (lx + lw + gap), lh, text, dot)
        pKeys(panel, x, rw, right, y + lh)
    elseif two then
        pValue(panel, lx + lw + gap, y, right - (lx + lw + gap), lh, text, dot)
        pControl(panel, x, rw, right - cw, y + lh + math.floor((lh - bh) / 2), bh)
    else
        local vRight = (cw > 0) and (right - cw - gap) or right
        pValue(panel, lx + lw + gap, y, vRight - (lx + lw + gap), lh, text, dot)
        if cw > 0 then pControl(panel, x, rw, right - cw, y + math.floor((lh - bh) / 2), bh) end
    end
    A.drawDividerH(panel, lx, y + h - T.line(T.borderW), inner)
    return h
end

-- THE FOOTER BAND: the power's state at the left, the face's actions at the right
local _bandSpec = { buttons = {}, status = { text = "", color = nil } }
local _bandPool = {}
local function pBand(panel, x0, y, w, x, draw)
    local M = ZeD.Molecules
    local H = M.bandH()
    if not draw then return H end
    local spec = _bandSpec
    local btns = spec.buttons
    for i = #btns, 1, -1 do btns[i] = nil end
    for i, id in ipairs(x.spec.foot) do
        local b = _bandPool[i]
        if not b then b = {}; _bandPool[i] = b end
        b.label, b.id, b.variant = ZeD.tr(FOOT[id]), id, nil
        if x.hoverOK then b.hover = nil else b.hover = false end   -- (nil: the band tests the pointer)
        b.focus = focusOf(x, id)
        b.pressed = pressedOf(x, id)
        b.disabled = not x.enabled
        b.help, b.minW, b.w = nil, nil, nil
        btns[i] = b
    end
    local text, dot = powerVal(x)
    spec.status.text, spec.status.color = text, dot or ZeD.T.textDim
    spec.win = x.win
    local _, rects = M.drawBand(panel, x0, y, w, spec)
    for i, rr in ipairs(rects.buttons or {}) do
        stamp(x, x.spec.foot[i], "press", rr.x, rr.y, rr.w, rr.h)
    end
    return H
end

-- THE CARD: readout, rows, band. draw = false measures it. Returns its height.
plainCard = function(panel, x0, y0, w, x, draw)
    local T = ZeD.T
    local y = y0
    y = y + pReadout(panel, x0, y, w, x, draw)
    if draw then ZeD.Atoms.drawDividerH(panel, x0, y, w, true) end
    y = y + T.line(T.borderW)
    for _, rw in ipairs(x.spec.rows) do y = y + pRow(panel, x0, y, w, x, rw, draw) end
    y = y + T.px(8)
    y = y + pBand(panel, x0, y, w, x, draw)
    return y - y0
end

-- this frame's reading for the card
local function plainCtx(st, pid, r, pad)
    local b = baseOf(pid)
    return { st = st, r = r, p = pad, s = plateState(st, b, r, pad), mw = st.kind == "micro", pid = b,
             spec = plainSpec(b), enabled = r.powered, zones = nil, fid = nil }
end
-- the plain card's width in a column w wide (the scrollbar's room kept, so it never changes with it)
function SA.plainW(w)
    local T = ZeD.T
    return math.min(w - T.sp.scrollbarW, T.px(PLAIN_MAX_W))
end
SA.PLAIN_POP_W = 400             -- design units: the card's width in its own window

-- ----------------------------------------------------------------------------
-- RENDER
-- ----------------------------------------------------------------------------
local function plateTex(name)
    local X = PX()
    return P.tex((X and X.texdir or "media/textures/ZeD/physpx/") .. name .. ".png")
end

-- the pop-out window (StationPopout.lua): which station each player has in its own window
SA.popped = SA.popped or {}
function SA.isPopped(player, st)
    local cur = player and SA.popped[player:getPlayerNum()]
    return cur ~= nil and st ~= nil and cur.obj == st.obj
end
local POP_ICON = "pop_out"   -- a ZeD pixel icon

--- The view's frame: the header, the plate (or the plain card), its line and what is inside, as one scroll;
--- returns the body's height (nothing while the station is popped out). opts: the pop-out window's draw
--- { noHeader = true, k = whole zoom, fid = focused id }; nil in the tab.
function SA.render(panel, win, x, y, w, h, state, st, opts)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    local player = win._playerObj
    state._lastZones = state.zones
    state.zones = {}
    if opts then state._gpFocusedId = opts.fid else state._gpFocusedId = ST.focusedId(win) end
    local fid = state._gpFocusedId
    local zones = state.zones
    local mw = st.kind == "micro"

    local headH = (opts and opts.noHeader) and 0 or ST.renderViewHeader(panel, win, x, y, w, state, st)
    -- in its own window: the tab says so and offers it back
    if not opts and SA.isPopped(player, st) then
        local line = ZeD.tr("UI_ZeD_Appliance_PoppedOut")
        local ty = y + headH + T.px(16)
        panel:drawText(line, x + math.floor((w - tm:MeasureStringX(T.fontF2, line)) / 2), ty, T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, T.fontF2)
        local bl = ZeD.tr("UI_ZeD_Appliance_PopIn")
        local bw, bh = ZeD.Molecules.buttonW(bl), T.buttonH
        local bx, by = x + math.floor((w - bw) / 2), ty + tm:getFontHeight(T.fontF2) + T.px(10)
        ZeD.Molecules.drawButton(panel, bx, by, bw, bh, bl, "default", false, nil,
            { hover = A.mouseIn(panel, bx, by, bw, bh), focus = (fid == "craft:a:popin") or nil })
        zones[#zones + 1] = { type = "popin", fid = "craft:a:popin", x = bx, y = by, w = bw, h = bh }
        ST.drawDropdownFor(panel, state, player, fid, "craft")
        return
    end
    local rows = contents(st)
    local des, pid = SA.plateFor(st)
    local Sc = ZeD.Scale
    -- Simple (ZeD setup's Devices row): the plain card in place of the plate, the same controls and zones
    local simple = devicesSimple()
    local r = read(st)
    local pad = padOf(st)
    local px_ = nil       -- the plain card's reading (Simple)
    local cardW, cardH = 0, 0
    if simple then
        px_ = plainCtx(st, pid or (mw and "mw_white" or "oven_modern"), r, pad)
        px_.iconW = (not opts) and (T.buttonH + T.px(6)) or 0
        cardW = SA.plainW(w)
        cardH = plainCard(nil, 0, 0, cardW, px_, false)
        des = nil
    end
    -- whole zoom, inside the column even with the scrollbar showing (so k never flips with the scrollbar)
    -- the width that fills the column, else the narrow face where the main face at the whole zoom does not fit
    -- it (not in its own window: opts.k)
    if des and not (opts and opts.k) then des, pid = P.pick(pid, w - T.sp.scrollbarW) end
    local k = (opts and opts.k) or (des and P.kFit((Sc and Sc.root and Sc.root()) or 1, des.w, w - T.sp.scrollbarW)) or 1
    local plH = des and des.h * k or 0

    -- Body: the plate, its line, the contents; one scrolling unit
    local lineH = tm:getFontHeight(T.fontF2)
    local rowH = T.px(30)
    local secH = T.px(20)   -- the library's section head
    local topH = simple and (cardH + T.px(10)) or (plH + T.px(6) + lineH + T.px(10))
    local totalH = T.px(8) + topH + secH + math.max(1, #rows) * rowH + T.px(10)
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
    local cyy = viewY + T.px(8) - off
    if simple then
        -- the plain card, centred, its zones the face's
        px_.zones, px_.fid, px_.markOpts, px_.win = zones, fid, opts and opts.markOpts or nil, opts and panel or nil
        px_.hoverOK = not state.stDropdownOpen
        px_.held = pad.pressId and (now() - (pad.pressT or 0) < PRESS_MS) and pad.pressId or nil
        local cx0 = x + math.floor((cw - cardW) / 2)
        plainCard(panel, cx0, cyy, cardW, px_, true)
        -- in the tab: open it in its own window (the icon button at the readout's top right)
        if not opts then
            local bs = T.buttonH
            local bx, by = cx0 + cardW - bs - T.px(6), cyy + T.px(6)
            local hint = ZeD.tr("UI_ZeD_Appliance_PopOut")
            ZeD.Molecules.drawIconButton(panel, bx, by, bs, POP_ICON,
                { hover = A.mouseIn(panel, bx, by, bs, bs), focus = (fid == "craft:a:popout") or nil,
                  hint = hint, help = hint, id = "craft:a:popout" })
            zones[#zones + 1] = { type = "popout", fid = "craft:a:popout", x = bx, y = by, w = bs, h = bs }
        end
        cyy = cyy + cardH + T.px(10)
    elseif des then
        local px0 = x + PL.centre(cw, des.w, k)
        local cv = P.canvas(panel, px0, cyy, k)
        local pst = plateState(st, pid, r, pad)
        PL.draw(cv, des, pst, { tex = plateTex, now = now() })
        -- the controls: focus cue, a key's press, the click areas (panel px). A knob keeps its
        -- own light as the focus cue (it is the hardware's); a key takes the controller's mark.
        local list = PL.controls(des, pst)
        local held = pad.pressId and (now() - (pad.pressT or 0) < PRESS_MS) and pad.pressId or nil
        for _, c in ipairs(list) do
            local cfid = "craft:a:" .. c.id
            if c.enabled then
                local zx, zy, zw, zh = px0 + c.x * k, cyy + c.y * k, c.w * k, c.h * k
                if held == c.id and c.kind ~= "turn" then PL.cue(cv, c, P.BLACK, 0.30) end
                -- the pointer over a key: the library's hover wash (a knob keeps its ring)
                if c.kind ~= "turn" and ZeD.Atoms.mouseIn(panel, zx, zy, zw, zh) and not (state.stDropdownOpen) then
                    PL.hoverKey(cv, c)
                end
                if fid == cfid then
                    if c.kind == "turn" then PL.cue(cv, c, T.accent, 0.55)
                    else PL.markKey(panel, c, px0, cyy, k, opts and opts.markOpts or nil) end
                end
                zones[#zones + 1] = { type = "plate", fid = cfid, id = c.id, kind = c.kind, pid = pid,
                                      x = zx, y = zy, w = zw, h = zh }
            end
        end
        cyy = cyy + plH + T.px(6)
        -- in the tab: open it in its own window (an icon button at the plate's top right, its hint on hover)
        if not opts then
            local bs = T.buttonH
            local bx, by = x + cw - bs - T.px(6), viewY + T.px(8) - off
            local hint = ZeD.tr("UI_ZeD_Appliance_PopOut")
            ZeD.Molecules.drawIconButton(panel, bx, by, bs, POP_ICON,
                { hover = A.mouseIn(panel, bx, by, bs, bs), focus = (fid == "craft:a:popout") or nil,
                  hint = hint, help = hint, id = "craft:a:popout" })
            zones[#zones + 1] = { type = "popout", fid = "craft:a:popout", x = bx, y = by, w = bs, h = bs }
        end
    end
    -- the line under the plate: what it is doing, in words, after a status mark (the plain card has it in its readout)
    if not simple then
        local line, mark = stateLine(st, r)
        local lf = T.fontF2
        local sq = T.px(6)
        local lw = sq + T.px(6) + tm:MeasureStringX(lf, line)
        local lx = x + math.floor((cw - lw) / 2)
        A.drawStatusDot(panel, lx, cyy + math.floor((lineH - sq) / 2), mark, sq)
        panel:drawText(line, lx + sq + T.px(6), cyy, T.text.r, T.text.g, T.text.b, T.text.a or 1, lf)
        cyy = cyy + lineH + T.px(10)
    end

    -- Contents
    ZeD.Molecules.drawSectionHeader(panel, x + T.px(10), cyy, cw - 2 * T.px(10),
        ZeD.tr(mw and "UI_ZeD_Appliance_InMicrowave" or "UI_ZeD_Appliance_InOven"), #rows, true, false, nil, true, T.px(6), secH, true)
    cyy = cyy + secH
    if #rows == 0 then
        ZeD.Molecules.drawEmptyLine(panel, x + T.px(16), cyy + T.px(8), cw - T.px(32),
            ZeD.tr(mw and "UI_ZeD_Appliance_EmptyMicrowave" or "UI_ZeD_Appliance_EmptyOven"))
    end
    for _, rw in ipairs(rows) do
        local lx = x + T.px(16)
        local isz = T.px(16)
        if rw.tex then panel:drawTextureScaledAspect(rw.tex, lx, cyy + math.floor((rowH - isz) / 2), isz, isz, 1, 1, 1, 1) end
        local barW, pctW = T.px(110), T.px(40)
        local rx = x + cw - T.px(16)
        local nameMax = rx - pctW - barW - T.px(16) - (lx + isz + T.px(6))
        -- the state as a tag (the one tag look: its status square carries the colour)
        local tagW = 0
        local tagTxt = rw.tag and ZeD.textCase(ZeD.tr(rw.tag)) or nil
        local tagMark = (rw.mode == "danger") and T.danger or ((rw.mode == "pos") and T.positive or ((rw.mode == "warn") and T.warning or nil))
        if tagTxt then tagW = tm:MeasureStringX(T.fontF1, tagTxt) + T.px(10) + (tagMark and T.px(10) or 0) + T.px(6) end
        local nstr = ZeD.CraftingCore.truncText(rw.name, T.fontF2, math.max(T.px(30), nameMax - tagW))
        local nx = lx + isz + T.px(6)
        panel:drawText(nstr, nx, cyy + math.floor((rowH - tm:getFontHeight(T.fontF2)) / 2), T.text.r, T.text.g, T.text.b, T.text.a, T.fontF2)
        if tagTxt then
            local tgx = nx + tm:MeasureStringX(T.fontF2, nstr) + T.px(6)
            ZeD.Molecules.drawTag(panel, tgx, cyy + math.floor((rowH - T.px(16)) / 2), tagTxt, tagMark)
        end
        if rw.p then
            -- the progress as the framed strip (list rows use its compact height)
            local bx = rx - pctW - barW
            local bh = A.fillBarCompactH()
            local byy = cyy + math.floor((rowH - bh) / 2)
            local fc = (rw.mode == "danger") and T.danger or ((rw.mode == "pos") and T.positive or T.accent)
            A.drawFillBar(panel, bx, byy, barW, rw.p, false, fc, bh, rw.name)   -- (ten segments; "Steak 64%")
            local ptxt = rw.left and (rw.mode == "danger" or rw.mode == "warn") and ZeD.tr("UI_ZeD_Appliance_MinShort", rw.left) or (tostring(math.floor(rw.p * 100 + 0.5)) .. "%")
            A.drawTextRight(panel, ptxt, rx, cyy + math.floor((rowH - tm:getFontHeight(T.fontF3)) / 2), T.fontF3, T.text)
        end
        A.drawDividerH(panel, x + T.px(10), cyy + rowH - T.px(1), cw - T.px(20), false)
        cyy = cyy + rowH
    end

    panel:clearStencilRect()
    if needsScroll then scroll:draw(panel) end
    if not opts then ST.drawDropdownFor(panel, state, player, fid, "craft") end
    return totalH
end

-- ----------------------------------------------------------------------------
-- INPUT
-- ----------------------------------------------------------------------------
local function hit(z, x, y) return x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h end

--- A click on a control (SA.act; the pop-out window acts through it too): a knob turns toward the half
--- clicked, a key presses; the tab's pop-out button opens the station in its own window, its "bring it
--- back" closes that window.
local function act(player, st, z, dir)
    if z.type == "popout" then if ZeD.StationPopout then ZeD.StationPopout.open(player, st) end; return end
    if z.type == "popin" then if ZeD.StationPopout then ZeD.StationPopout.close(player) end; return end
    if z.kind == "turn" then SA.turn(player, st, z.pid, z.id, dir or 1)
    else SA.press(player, st, z.pid, z.id) end
end
SA.act = act

--- A click in the view, against the zones the last render stamped; it always takes the click.
function SA.onClick(win, state, st, x, y)
    local player = win._playerObj
    if ST.viewHeaderClick(state, player, x, y) then return true end
    for _, z in ipairs(state.zones or {}) do
        if (z.type == "popout" or z.type == "popin") and hit(z, x, y) then act(player, st, z); return true end
        if z.type == "plate" and hit(z, x, y) then
            act(player, st, z, (x < z.x + z.w / 2) and -1 or 1)   -- knobs: left half down, right half up
            return true
        end
    end
    return true
end

--- The wheel: an open list scrolls, a knob under the pointer turns, else the body scrolls.
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

--- The controller's stops: the station picker, every stamped control (a knob turns on left / right), then
--- the leave-and-cancel stop; an open list's own stops instead while it is open.
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

-- the controls change with the plate, with power (an unpowered panel offers none) and with Full / Simple
function SA.focusKey(win, state, st)
    local _, pid = SA.plateFor(st)
    return "a" .. tostring(pid) .. (devicesSimple() and "/plain" or "") .. "/" .. tostring(read(st).powered) .. "/" .. tostring(#(state.zones or {}))
        .. "/" .. tostring(state.scroll and state.scroll.scrollPos or 0)
end

print("[ZeD] StationAppliance: oven and microwave plates loaded")
return SA
