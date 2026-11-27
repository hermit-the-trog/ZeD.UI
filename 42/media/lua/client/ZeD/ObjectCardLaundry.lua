-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardLaundry.lua
-- ============================================================================
-- OBJECT CARD: LAUNDRY
-- Client; one card kind for ZeD.ObjectCards (ObjectCards.lua draws the frame,
-- this def fills it). The washer, the dryer and the stacked washer-dryer each
-- show their own front panel in pixel art in the full card, as the generator and the
-- propane grill do (ZeDUI/tools/physpx d_laundry.py, data in PhysPx.lua,
-- drawn by the shared plate template ZeD_Plate.lua; the face is picked by the
-- object's class through PhysPx.laundry.classes, at the width that fills the
-- card). The face replaces the picture, never the rules: every press is
-- vanilla's own action with vanilla's own checks (the loot window handlers
-- ClothingWasherToggle / ClothingDryerToggle / CombinationWasherDryerToggle /
-- CombinationWasherDryerSetMode):
--   power      ISToggleClothingWasher / ISToggleClothingDryer /
--              ISToggleComboWasherDryer after luautils.walkAdj; needs power,
--              and water for the washer and the washer-dryer in washer mode
--   mode_wash  ISWorldObjectContextMenu.onSetComboWasherDryerMode(..,
--   mode_dry   "washer" / "dryer") when it is not already in that mode;
--              needs power
--   door       its contents in the Loot pane (ZeD_WorldWindow.selectContainer),
--              after a walk over when the machine is past the loot window's
--              reach (a square)
-- While a press's walk and action are queued every control waits for them.
-- Live on the face: the run lamp (green) or no power (red), the water meter
-- and the water in the drum (fluid against capacity, 0..5), FILL (washer mode
-- with no water), the clothes in the drum, the washer-dryer's WASH / DRY
-- lamps. The game has no wash phases and its machine runs until it is turned
-- off: while it runs the phase lamps step every PHASE_MIN game minutes as
-- dressing (washer WASH, RINSE, SPIN; dryer DRY, COOL; the washer-dryer by its
-- mode) and round again, the cycle dial reads how far the clothes inside have
-- come by the game's own numbers (the dirtiest or bloodiest item for a wash,
-- the wettest for a dry), and the drum turns once in DRUM_MS of real time (it
-- stops with the game paused). Stopped: phase lamps dark, the dial at 0.
-- Under the face: the water, what is inside, and the clothes' blood, dirt and
-- wetness in the words of the game's clothing tooltip. The band at the foot
-- says what stops it running (no power, no water), in vanilla's words.
-- Where it opens: the World window's container buttons (ContainerControls:
-- one button in place of vanilla's laundry buttons while LD.useFace says so).
-- LD.useFace is the one switch between the face and vanilla's plain controls;
-- a faces-or-simple-cards setting, when one comes, hangs there.
-- The Simple form (ZeD setup's Devices row; ZeD.ObjectCardPlain in
-- ObjectCardPower.lua): running or stopped in large type, the lit phase beside it; then the power switch, the washer-dryer's Wash | Dry keys, the
-- water, what is inside with the door's Open key, the clothes' blood, dirt and wetness, each the face's own zone
-- (ldy:power, ldy:mode_wash, ldy:mode_dry, ldy:door) with the face's run and help.
-- ============================================================================

require "ZeD/ObjectCards"
require "ZeD/ZeD_PixelParts"
require "ZeD/ZeD_Plate"
require "ZeD/PhysPx"
require "ZeD/ObjectCardPower"   -- (the plain card's parts: ZeD.ObjectCardPlain)

local OC = ZeD.ObjectCards
local P = ZeD.Px
local PL = ZeD.Plate
local UI = OC.ui
local call = OC.call

ZeD.ObjectCardLaundry = ZeD.ObjectCardLaundry or {}
local LD = ZeD.ObjectCardLaundry

LD.DRUM_MS   = 2000   -- real ms for one turn of the drum
-- The plate's phase lamps step WASH, RINSE, SPIN (DRY, COOL) every PHASE_MIN game minutes and round again. The game
-- has no such cycle (its machine runs until it is turned off: QA LA2), so they are dressing only, a machine that
-- looks busy; what the clothes are comes from the rows under the face in the game's words, and the big word stays
-- Running or Stopped. (QA LA2 took them out; the director brought them back as dressing: the director's call lamps,
-- Nov 26 2026)
LD.PHASE_MIN = 5      -- game minutes a phase lamp stays lit (12.5 s of real time at the default day length)
LD.PHASES = {
    washer = { "phWash", "phRinse", "phSpin" },
    dryer  = { "phDry", "phCool" },
}
-- when each running machine was first seen running, by its card key: { min, mode } (the lamps' steps start there)
LD._run = LD._run or {}
local ALL_PHASES = { "phWash", "phRinse", "phSpin", "phDry", "phCool" }

--- The plate id for this object ("washer", "dryer", "washer_dryer"), or nil when it is not a laundry machine.
function LD.plateId(obj)
    local X = ZeD.PhysPx
    local classes = X and X.laundry and X.laundry.classes
    if not (obj and classes) then return nil end
    for cls, pid in pairs(classes) do
        if instanceof(obj, cls) then return pid end
    end
    return nil
end

--- Faces or simple cards: true shows the machine's face card in place of vanilla's plain laundry
--- buttons; false leaves the plain controls exactly as they were. The one switch: a setting goes here.
function LD.useFace(obj)
    local pid = LD.plateId(obj)
    return pid ~= nil and ZeD.PhysPx.plates[pid] ~= nil
end

local function isCombo(obj) return obj ~= nil and instanceof(obj, "IsoCombinationWasherDryer") end

-- the machine's name as the game writes it (its tile's moveable name), else its container's title
local function nameOf(obj)
    local ok, n = pcall(ISWorldObjectContextMenu.getMoveableDisplayName, obj)
    if ok and n and n ~= "" then return n end
    local c = call(obj, "getContainer")
    local ty = c and call(c, "getType")
    local title = ty and getTextOrNull and getTextOrNull("IGUI_ContainerTitle_" .. tostring(ty))
    if title then return title end
    return call(obj, "getName") or "?"
end

local function gameMinutes()
    local gt = getGameTime and getGameTime()
    return gt and (gt:getWorldAgeHours() * 60) or 0
end

local def = { id = "laundry" }

function def.resolve(player, obj)
    local pid = LD.plateId(obj)
    if not pid then return nil end
    local sq = obj:getSquare()
    if not sq then return nil end
    return { obj = obj, sq = sq, pid = pid, key = OC.keyOf(sq, "laundry") }
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
            if LD.plateId(o) then
                local t = def.resolve(player, o)
                if t then list[#list + 1] = t end
            end
        end
    end)
    return OC.sortTargets(list)
end

-- vanilla's toggle for this machine, after the walk (the loot window handlers' perform)
local function toggle(p, t)
    local o = t.obj
    if not (o:getSquare() and luautils.walkAdj(p, o:getSquare())) then return end
    if isCombo(o) then ISTimedActionQueue.add(ISToggleComboWasherDryer:new(p, o))
    elseif instanceof(o, "IsoClothingWasher") then ISTimedActionQueue.add(ISToggleClothingWasher:new(p, o))
    else ISTimedActionQueue.add(ISToggleClothingDryer:new(p, o)) end
end

-- the washer-dryer to a mode it is not in (vanilla's own walk is inside the call)
local function setMode(p, t, mode)
    local o = t.obj
    if not isCombo(o) then return end
    if (mode == "washer") == o:isModeWasher() then return end
    ISWorldObjectContextMenu.onSetComboWasherDryerMode(p, o, mode)
end

-- The chain a press queued (the walk, then the game's toggle, mode switch or the door's opening) is kept by the
-- machine's card key and looked up in the game's queue, as the fluid card's and the generator's chainBusy do: while
-- any of it is still queued every control waits. Power pressed twice from 4 tiles (a double click, or A A) queued
-- walk, toggle, walk, toggle, and the second toggle undid the first; the face reads the old state for up to 250 ms,
-- so the press itself asks the queue. Kept by key, not on the target, so the card and its pop-out share one chain.
-- (QA LA1/OC6, Nov 26 2026)
LD._chain = LD._chain or {}
local function gameQueue(p)
    local ok, q = pcall(function() return ISTimedActionQueue.getTimedActionQueue(p) end)
    if ok and q and type(q.queue) == "table" then return q end
    return nil
end
local function inQueue(q, a)
    for i = 1, #q.queue do if q.queue[i] == a then return true end end
    return false
end
local function chainBusy(t, p)
    local list = t and LD._chain[t.key]
    if not (list and p) then return false end
    local q = gameQueue(p)
    if q then
        for i = 1, #list do if inQueue(q, list[i]) then return true end end
    end
    LD._chain[t.key] = nil
    return false
end
LD.chainBusy = chainBusy

-- Runs fn, which queues the game's actions, and keeps what it added as the machine's chain.
local function track(t, p, fn)
    local q = gameQueue(p)
    local before = {}
    if q then for i = 1, #q.queue do before[q.queue[i]] = true end end
    local ok, err = pcall(fn)
    if not ok then print("[ZeD] laundry card: queueing failed: " .. tostring(err)) end
    q = gameQueue(p)
    local list = {}
    if q then
        for i = 1, #q.queue do
            local a = q.queue[i]
            if not before[a] then list[#list + 1] = a end
        end
    end
    LD._chain[t.key] = (#list > 0) and list or nil
end

-- A control's press: refused while an earlier press's chain is still queued, else run and kept as the chain.
local function gated(fn)
    return function(p, t)
        if not (p and t) or chainBusy(t, p) then return end
        t._pl = p
        track(t, p, function() fn(p, t) end)
    end
end

-- "Too far away from <the machine>!" over his head, in the game's words
local function sayFar(p, obj)
    local OCP = ZeD.ObjectCardPower
    if OCP and OCP.sayWhy then OCP.sayWhy(p, ZeD.tr("IGUI_TradingUI_TooFarAway", nameOf(obj))) end
end

-- The door's opening at the end of the walk. The loot window lists a container only within a square of the player,
-- so from 3 tiles the Door looked for the washer in the Loot list until its tries ran out and showed nothing, with
-- no word. Now the press walks over first, as the card's own open does (ZeDOpenCardAction), and this one-tick
-- action shows it; still out of reach at the end (a wall between), it says so over his head. (QA LA4, Nov 26 2026)
ZeDLaundryDoorAction = ZeDLaundryDoorAction or ISBaseTimedAction:derive("ZeDLaundryDoorAction")
function ZeDLaundryDoorAction:isValid() return true end
function ZeDLaundryDoorAction:update() end
function ZeDLaundryDoorAction:start() end
function ZeDLaundryDoorAction:stop() ISBaseTimedAction.stop(self) end
function ZeDLaundryDoorAction:getDuration() return 1 end
function ZeDLaundryDoorAction:perform()
    local ok, err = pcall(LD.showInside, self.character, self.obj, true)
    if not ok then print("[ZeD] laundry card: the door after the walk failed: " .. tostring(err)) end
    ISBaseTimedAction.perform(self)
end
function ZeDLaundryDoorAction:new(character, obj)
    local o = ISBaseTimedAction.new(self, character)
    o.obj = obj
    o.maxTime = 1
    o.stopOnWalk, o.stopOnRun = false, false
    return o
end

--- Its contents in the Loot pane: at once when the loot window can reach it, else after a walk over (walked: the
--- walk is done, so out of reach now says why). Returns true when it showed or a walk is queued.
function LD.showInside(p, obj, walked)
    local c = obj and call(obj, "getContainer")
    local WW = ZeD_WorldWindow
    if not (p and c and WW and WW.selectContainer) then return false end
    local pn = p:getPlayerNum()
    if not WW.inReach or WW.inReach(c, pn) then
        WW.selectContainer(c, 120, pn)
        return true
    end
    local sq = (not walked) and obj:getSquare() or nil
    if sq and luautils.walkAdj(p, sq) then
        ISTimedActionQueue.add(ZeDLaundryDoorAction:new(p, obj))
        return true
    end
    sayFar(p, obj)
    return false
end
local function openDoor(p, t) LD.showInside(p, t.obj, false) end

-- the controls' presses, each behind the gate (made once: the face asks for them every frame)
local RUN = {
    power = gated(toggle),
    mode_wash = gated(function(p, t) setMode(p, t, "washer") end),
    mode_dry = gated(function(p, t) setMode(p, t, "dryer") end),
    door = gated(openDoor),
}

-- An amount of blood, dirt or water as the tooltip's bar reads it, out of 100 (any amount at least 1%)
local function pctOf(v) return math.max(1, math.min(100, math.floor(v + 0.5))) .. "%" end

-- How far the load has come by the game's numbers, 0..1: a wash takes the dirt and blood off, a dry the water out.
local function loadDone(d)
    if (d.clothes or 0) == 0 then return 0 end
    local left = d.washMode and math.max(d.dirt, d.blood) or d.wet
    return math.max(0, math.min(1, 1 - left / 100))
end

function def.refresh(t, player)
    local o = t.obj
    local d = {}
    d.combo = isCombo(o)
    d.on = o:isActivated() and true or false
    local c = o:getContainer()
    d.powered = (c ~= nil and c:isPowered()) and true or false
    d.fluid = call(o, "getFluidAmount") or 0
    d.cap = call(o, "getFluidCapacity") or 0
    -- on the house pipes the game reports 10000 of 10000 L, which says nothing
    d.piped = ((call(o, "getUsesExternalWaterSource") and call(o, "hasExternalWaterSource")) or d.cap >= 9999) and true or false   -- (the pipes report a 10000 L tank)
    -- a dryer takes no water: no water row for it
    d.dryerOnly = (not d.combo) and instanceof(o, "IsoClothingDryer") or false
    d.washMode = (not d.combo and instanceof(o, "IsoClothingWasher")) or (d.combo and o:isModeWasher()) or false
    d.hasWater = d.fluid > 0
    local items = c and c:getItems()
    d.n = items and items:size() or 0
    -- The clothes inside as the game's clothing tooltip reads them (Clothing.DoTooltip): Bloody while the blood level
    -- is above 0, Dirty from 1, Wet above 0, each out of 100; the most of each among the clothes. The card said only
    -- "n items" while the game washed a shirt from dirt 60 and blood 60 to 0 and soaked it. (QA LA2, Nov 26 2026)
    local dirt, blood, wet, nCl = 0, 0, 0, 0
    for i = 0, d.n - 1 do
        local it = items:get(i)
        if it and instanceof(it, "Clothing") then
            nCl = nCl + 1
            dirt = math.max(dirt, call(it, "getDirtiness") or 0)
            blood = math.max(blood, call(it, "getBloodLevel") or 0)
            wet = math.max(wet, call(it, "getWetness") or 0)
        end
    end
    d.clothes, d.dirt, d.blood, d.wet = nCl, dirt, blood, wet
    local states = {}
    if blood > 0 then states[#states + 1] = { key = "Tooltip_clothing_bloody", v = blood } end
    if dirt >= 1 then states[#states + 1] = { key = "Tooltip_clothing_dirty", v = dirt } end
    if wet > 0 then states[#states + 1] = { key = "Tooltip_clothing_wet", v = wet } end
    d.states = states
    d.name = nameOf(o)
    -- vanilla's checks: the switch needs power, and water in washer mode; the mode keys need power
    d.canToggle = d.powered and (d.hasWater or not d.washMode)
    d.canMode = d.combo and d.powered
    t.d = d
    t._pl = player   -- (whose queue the gate reads while the face draws: QA LA1)
    t.verbs = {}   -- (the face is the control surface: no verb row under the header)
end

function def.title(t) return t.d and t.d.name or nameOf(t.obj) end
function def.icon(t) return OC.spriteIcon(t.obj) end
function def.pill(t)
    local T = ZeD.T
    if t.d and t.d.on then return ZeD.tr("UI_ZeD_Power_PillRunning"), T.positive end
    return ZeD.tr("UI_Off"), T.textDim
end
--- The controller lands on the switch.
function def.openFocus(t) return "ldy:power" end
--- The header's pop-out button: while the face is drawn (Nov 15 2026, pop-outs; not on the plain card).
function def.popOut(t) return not ZeD.ObjectCardPlain.on() end

--- What keeps it from running, in vanilla's words (the band shows only then).
function def.status(t)
    local T = ZeD.T
    local d = t.d
    if not d then return nil end
    if not d.powered then return { text = ZeD.trBare("IGUI_RadioRequiresPowerNearby"), c = T.warning } end
    if d.washMode and not d.hasWater then return { text = ZeD.trBare("IGUI_RequiresWaterSupply"), c = T.warning } end
    return nil
end

--- The card closed with the controller on it: back to the button that opened it
--- (GAMEPAD_SPEC focus rule 7: after an action, focus returns to the start).
function def.onClose(t, card)
    local b = t.back
    t.back = nil
    local F = ZeD.Input and ZeD.Input.Focus
    if not (b and card and card._fid and F and F.focusSoon) then return end
    F.focusSoon(b.win, b.zone, function(e)
        return e.id == b.id and not (ZeD_WorldWindow.getObjectCard and ZeD_WorldWindow.getObjectCard(card.playerNum))
    end, 1)
end

-- the running part of the face: the phase lamps stepping by game minutes (dressing), the load's progress on the dial
-- (the game's numbers, QA LA2), the drum by real time. st.phase: the lamp lit, for the Simple form.
local function clockState(t, d, st)
    local key = t.key
    if not d.on then
        LD._run[key] = nil
        st.cycleF = 0
        st.phase = nil
    else
        local mode = d.washMode and "washer" or "dryer"
        local now = gameMinutes()
        local run = LD._run[key]
        if not run or run.mode ~= mode then run = { min = now, mode = mode }; LD._run[key] = run end
        local list = LD.PHASES[mode]
        local cycle = LD.PHASE_MIN * #list
        local pos = math.max(0, now - run.min) % cycle
        local i = math.min(#list, math.floor(pos / LD.PHASE_MIN) + 1)
        st[list[i]] = true
        st.phase = list[i]
        -- (the dial keeps the clothes' real progress: a dial going round with the lamps would say the load is done
        -- at every SPIN)
        st.cycleF = loadDone(d)
    end
    -- the drum: a turn in DRUM_MS while it runs, still with the game paused or the machine off
    local ms = getTimestampMs()
    local dt = t._drumMs and math.max(0, math.min(250, ms - t._drumMs)) or 0
    t._drumMs = ms
    local f = t._drumF or 0
    if d.on and getGameSpeed() > 0 then f = (f + dt / LD.DRUM_MS) % 1 end
    t._drumF = f
    st.drumF = f
end

-- The water meter is a powered display; the water in the drum is not: the meter goes dark
-- without power, the water in the drum still shows. Both are `bars` parts reading `water` in the export, and the
-- template lights bars only while st.power, so once per session each laundry face's meter (the bars part whose
-- bars are single rects; the drum's are stacks of lines) is pointed at `waterMeter`, which reads 0 without power.
local metersMarked = false
local function markMeters()
    if metersMarked then return end
    metersMarked = true
    local X = ZeD.PhysPx
    local bases = { washer = true, dryer = true, washer_dryer = true }
    for pid, des in pairs(X and X.plates or {}) do
        if bases[P.baseId(pid)] then
            for _, part in ipairs(des.parts or {}) do
                if part.t == "bars" and part.src == "water" and part.bars and part.bars[1] and #part.bars[1] == 4 then
                    part.src = "waterMeter"
                end
            end
        end
    end
end

-- what the face's live parts read
local function plateState(t, d)
    local st = {}
    for _, k in ipairs(ALL_PHASES) do st[k] = false end
    st.power = true                          -- (the plate's bars draw only "while st.power": the drum holds its water
                                             -- with the power off too; the meter reads waterMeter, below)
    st.powered = d.powered                   -- the hits' needs = "powered"
    st.running = d.on
    st.noPower = not d.powered
    local w = 0
    if d.fluid > 0 then
        w = (d.cap > 0) and math.floor(math.min(1, d.fluid / d.cap) * 5 + 0.5) or 5
        if w < 1 then w = 1 end              -- any water lights a bar
    end
    st.water = w
    markMeters()
    st.waterMeter = d.powered and w or 0     -- (the meter: dark without power; the drum keeps `water`)
    st.noWater = d.washMode and not d.hasWater
    st.hasItems = d.n > 0
    st.waterLoad = st.hasItems and w or 0    -- (the top-loader's water among the clothes: its `soak` pictures)
    st.waterBare = (not st.hasItems) and w or 0   -- (and in the empty tub: its `water` pictures)
    st.modeWash = d.combo and d.washMode
    st.modeDry = d.combo and not d.washMode
    clockState(t, d, st)
    return st
end
LD.plateState = plateState

local function plateTex(name) return P.tex(ZeD.PhysPx.texdir .. name .. ".png") end

-- each control: what it does now (nil = not now) and its help line
local function control(t, d, id)
    -- (every control waits while a press's walk and action are queued, greyed with why: QA LA1, Nov 26 2026)
    if RUN[id] and chainBusy(t, t._pl) then return nil, ZeD.tr("UI_ZeD_Craft_BadgeNeeds", ZeD.tr("UI_ZeD_Fluid_NeedsIdle")) end
    if id == "power" then
        if not d.powered then return nil, ZeD.tr("UI_ZeD_Laundry_HelpNoPower") end
        if not d.canToggle then return nil, ZeD.tr("UI_ZeD_Laundry_HelpNoWater") end
        return RUN.power, ZeD.tr(d.on and "UI_ZeD_Laundry_HelpOff" or "UI_ZeD_Laundry_HelpOn")
    elseif id == "mode_wash" or id == "mode_dry" then
        local mode = (id == "mode_wash") and "washer" or "dryer"
        local help = ZeD.tr(mode == "washer" and "UI_ZeD_Laundry_HelpWash" or "UI_ZeD_Laundry_HelpDry")
        if not d.canMode then return nil, ZeD.tr("UI_ZeD_Laundry_HelpNoPower") end
        if (mode == "washer") == d.washMode then return nil, help end
        return RUN[id], help
    elseif id == "door" then
        return RUN.door, ZeD.tr("UI_ZeD_Laundry_HelpDoor")
    end
    return nil, nil
end

--- The face on its own at (px0, y), zoom k (des: the plate picked), its controls stamped as the card's zones. The
--- card draws it (drawFace below) and so does the face's pop-out, standing in for the card (FacePop.lua; Nov 15
--- 2026, pop-outs). card: anything with zone(z), focusOf(fid) and _hoverFid, and the panel's drawing.
function LD.face(card, px0, y, k, des, t)
    local d = t.d
    local cv = P.canvas(card, px0, y, k)
    local st = plateState(t, d)
    t._st = st
    PL.draw(cv, des, st, { tex = plateTex, now = getTimestampMs() })
    for _, c in ipairs(PL.controls(des, st)) do
        local fid = "ldy:" .. c.id
        local fn, help = control(t, d, c.id)
        -- every control a key: the pointer's wash while it can act, the controller's mark always
        if fn and UI.hovered(card, fid) then PL.hoverKey(cv, c) end
        local fm = card:focusOf(fid)
        if fm then PL.markKey(card, c, px0, y, k, fm) end
        card:zone({ fid = fid, x = px0 + c.x * k, y = y + c.y * k, w = c.w * k, h = c.h * k, body = true,
            primary = (c.id == "power") or nil, help = help,
            run = fn and function(cc, p) fn(p, t) end or nil })
    end
end

--- The laundry kind (FacePop.lua opens the pop-out on the same target the card works on).
LD.def = def

-- ---------------------------------------------------------------------------
-- the wall behind the laundry machine (director, Nov 21 2026: "appliance cards that do not fill a full card width
-- should receive a background similar to the tile background we gave to the industrial dishwasher. Just a wall of
-- some sort. Keep it simple."; he picked a painted wall with a wood baseboard). The face keeps the machine's own
-- shape, so the card's width either side is wall: paint with a light stipple, and a baseboard along the machine's
-- foot. Colors as printed, shown at the paper tone like the dishwasher's tile. (Graphic cleanup, Nov 22 2026)
-- ---------------------------------------------------------------------------
local WALL_PRINTED = { paint = "#e6dfcf", speckHi = "#ece5d5", speckLo = "#ddd6c6",
                       board = "#8c6a46", boardHi = "#b48c60", boardMid = "#a07a52", boardLo = "#5e4630" }
local WALL = nil
local function wallColors()
    if WALL then return WALL end
    WALL = {}
    for key, v in pairs(WALL_PRINTED) do WALL[key] = ZeD.paperTone(P.color(v)) end
    return WALL
end
-- a small repeatable number stream (kept under 2^31: Kahlua's % breaks past it), as the dishwasher's
local function rng(seed)
    local s = (seed % 65521) + 1
    return function(n) s = (s * 75 + 74) % 65537; return s % n end
end
-- the baseboard's height in art px: about 4 inches against the machine's 27-inch front (12 on the main face, 16 @450)
local function boardH(H) return math.floor(H * 0.046 + 0.5) end
-- the paint and the baseboard from art x0 for aw, rows 0 .. H (the machine's foot at H)
local function wallField(cv, x0, aw, H)
    if aw <= 0 then return end
    local C, bb = wallColors(), boardH(H)
    P.rect(cv, x0, 0, aw, H - bb, C.paint)
    P.rect(cv, x0, H - bb, aw, bb, C.board)
    P.rect(cv, x0, H - bb, aw, 1, C.boardHi)          -- the board's lit top edge
    P.rect(cv, x0, H - bb + 1, aw, 1, C.boardMid)
    P.rect(cv, x0, H - 2, aw, 2, C.boardLo)           -- the shadow at the floor
end
-- the paint's stipple where the wall shows: a speck to every 64 art px, a fixed seed so it holds still
local function wallSpecks(cv, x0, aw, H, seed)
    if aw <= 0 then return end
    local C, r = wallColors(), rng(seed)
    local ph = H - boardH(H)
    for _ = 1, math.floor(aw * ph / 64) do
        local sx = r(aw)                                -- (one call at a time, in this order: the preview's order)
        local sy = r(ph)
        local c = (r(2) == 0) and C.speckHi or C.speckLo
        P.rect(cv, x0 + sx, sy, 1, 1, c)
    end
end
-- a column of screen pixels narrower than one art pixel at the card's edge, in the wall's colors
local function wallSliver(card, sx, sw, y, k, H)
    if sw <= 0 then return end
    local C, bb = wallColors(), boardH(H)
    local function band(y0, y1, c) card:drawRect(sx, y + y0 * k, sw, (y1 - y0) * k, 1, c.r, c.g, c.b) end
    band(0, H - bb, C.paint); band(H - bb, H - 2, C.board); band(H - 2, H, C.boardLo)
end
--- The wall across the card behind a face drawn at screen x px0 (art 0) and zoom k, filling x .. x + w (it shows
--- either side of the machine and round its edges), as the dishwasher's tileWall.
local function drawWall(card, x, y, w, px0, des, k)
    local H = des.h
    local cv = P.canvas(card, px0, y, k)
    local lg = px0 - x
    local la = math.floor(lg / k)
    local rx = px0 + des.w * k
    local rg = x + w - rx
    local ra = math.floor(rg / k)
    wallField(cv, -la, la + des.w + ra, H)
    wallSpecks(cv, -la, la, H, 7)
    wallSpecks(cv, des.w, ra, H, 13)
    wallSliver(card, x, lg - la * k, y, k, H)
    wallSliver(card, rx + ra * k, rg - ra * k, y, k, H)
end

-- ---------------------------------------------------------------------------
-- the floor round the top-loading washer (director, Nov 22 2026: "isn't one of the washer a top load? Therefore you
-- would see the floor, not the wall and baseboard"). Its face looks down into the tub, so what shows either side of
-- it is the floor, seen from above: vinyl tiles a foot square in two close shades, a few specks in each, columns from
-- the machine's sides and rows from its front, and the machine's own shadow along each side. Paper tone, as the wall.
-- (Graphic cleanup, Nov 22 2026)
-- ---------------------------------------------------------------------------
local FLOOR_PRINTED = { tileA = "#c3bdb0", tileB = "#bbb5a8", speckLo = "#a7a194", speckHi = "#d0cabd", seam = "#8e887b" }
local FLOOR = nil
local SHADOW = { r = 0, g = 0, b = 0 }
local function floorColors()
    if FLOOR then return FLOOR end
    FLOOR = {}
    for key, v in pairs(FLOOR_PRINTED) do FLOOR[key] = ZeD.paperTone(P.color(v)) end
    return FLOOR
end
-- a tile a foot square, in art px: the machine is 0.786 m wide, so a foot is 0.388 of the face's width
local function tileFt(faceW) return math.floor(faceW * 0.388 + 0.5) end
-- one side of floor from art x0 for aw, rows 0 .. H (the machine's front at H); edge = the machine's side the
-- columns start from, dir = -1 laying them leftward, 1 rightward; s = the tile
local function floorSide(cv, x0, aw, H, edge, dir, s, seed)
    if aw <= 0 then return end
    local C, r = floorColors(), rng(seed)
    local x1 = x0 + aw
    local function clip(x, y, w, h, c)
        local a, b = math.max(x, x0), math.min(x + w, x1)
        local c0, c1 = math.max(y, 0), math.min(y + h, H)
        if b > a and c1 > c0 then P.rect(cv, a, c0, b - a, c1 - c0, c) end
    end
    local cols, rows = math.floor(aw / s) + 1, math.floor(H / s) + 1
    for row = 0, rows do
        local ty = H - (row + 1) * s
        for col = 0, cols do
            local tx = (dir < 0) and (edge - (col + 1) * s) or (edge + col * s)
            clip(tx, ty, s, s, ((row + col) % 2 == 0) and C.tileA or C.tileB)
            clip(tx, ty, s, 1, C.seam)                                  -- the seam along its far edge
            clip((dir < 0) and tx or (tx + s - 1), ty, 1, s, C.seam)    -- and along its outer side
            for _ = 1, 6 do                                             -- (in this order: the preview's)
                local sx = r(s - 4)
                local sy = r(s - 4)
                local c = (r(2) == 0) and C.speckLo or C.speckHi
                clip(tx + 2 + sx, ty + 2 + sy, 1, 1, c)
            end
        end
    end
    P.rect(cv, (dir < 0) and (edge - 2) or edge, 0, 2, H, SHADOW, 0.25)   -- the machine's shadow along its side
end
-- a column of screen pixels narrower than one art pixel at the card's edge, in the floor's tile color
local function floorSliver(card, sx, sw, y, k, H)
    if sw <= 0 then return end
    local c = floorColors().tileA
    card:drawRect(sx, y, sw, H * k, 1, c.r, c.g, c.b)
end
--- The floor either side of a face drawn at screen x px0 (art 0) and zoom k, filling x .. x + w.
local function drawFloor(card, x, y, w, px0, des, k)
    local H = des.h
    local cv = P.canvas(card, px0, y, k)
    local lg = px0 - x
    local la = math.floor(lg / k)
    local rx = px0 + des.w * k
    local rg = x + w - rx
    local ra = math.floor(rg / k)
    local s = tileFt(des.w)
    floorSide(cv, -la, la, H, 0, -1, s, 7)
    floorSide(cv, des.w, ra, H, des.w, 1, s, 13)
    floorSliver(card, x, lg - la * k, y, k, H)
    floorSliver(card, rx + ra * k, rg - ra * k, y, k, H)
end

--- The room either side of a face: the floor round the top-loading washer (seen from above), the wall behind the
--- dryer and the combination washer-dryer (seen from the front).
-- Every room draw goes through this stand-in for the card: it cuts each rect to the face area (x0 .. x1, y0 .. y1)
-- and drops what is left of it outside, so no backdrop rect runs past the card's edge or its scrolled view. One
-- table kept and reused, so a frame makes no garbage. (The card already draws its body inside a stencil, so the
-- picture is the same; the draws themselves now stay inside.) (QA cleanup run, Nov 22 2026)
local ROOM_CLIP = {}
function ROOM_CLIP:drawRect(sx, sy, sw, sh, a, r, g, b)
    local cx0, cy0 = math.max(sx, self.x0), math.max(sy, self.y0)
    local cx1, cy1 = math.min(sx + sw, self.x1), math.min(sy + sh, self.y1)
    if cx1 > cx0 and cy1 > cy0 then self.card:drawRect(cx0, cy0, cx1 - cx0, cy1 - cy0, a, r, g, b) end
end
local function drawRoom(card, x, y, w, px0, des, k, faceId)
    -- the face area: the body's width and the face's rows, kept inside the card and inside the view the card
    -- scrolls its body in (card._viewY / _viewH, ObjectCards.lua: the same rect as its stencil) (QA cleanup run, Nov 22 2026)
    local x0, x1, y0, y1 = x, x + w, y, y + des.h * k
    local cw = card.getWidth and card:getWidth() or nil
    local ch = card.getHeight and card:getHeight() or nil
    if cw then x0, x1 = math.max(x0, 0), math.min(x1, cw) end
    if ch then y0, y1 = math.max(y0, 0), math.min(y1, ch) end
    if card._viewY and card._viewH then
        y0, y1 = math.max(y0, card._viewY), math.min(y1, card._viewY + card._viewH)
    end
    if x1 <= x0 or y1 <= y0 then return end   -- (the face is scrolled out of view: no room to draw)
    ROOM_CLIP.card, ROOM_CLIP.x0, ROOM_CLIP.x1, ROOM_CLIP.y0, ROOM_CLIP.y1 = card, x0, x1, y0, y1
    if P.baseId(faceId) == "washer" then drawFloor(ROOM_CLIP, x, y, w, px0, des, k)
    else drawWall(ROOM_CLIP, x, y, w, px0, des, k) end
    ROOM_CLIP.card = nil   -- (the card is not held on to between frames)
end
LD._drawRoom = drawRoom  -- (for gc_qa_cleanup_sim.lua; the card draws it through drawFace) (QA cleanup run, Nov 22 2026)

-- The face, its id and the whole zoom for a card with `room` px across and the view the body scrolls in (card._viewH).
-- Pixel art never draws at a fractional zoom (as the car, the figure frame and the icons), so, in order:
--   1. the big face at the largest whole zoom (1 or more) where it fits the width and it and the readings under it fit
--      the view's height (else the face runs past the card's bottom, and its picture with it); at 1x the widest of
--      the plate's big faces that fits;
--   2. else the narrow face (PhysPx.narrow, about 130 x 190) at the largest whole zoom that fits, centred;
--   3. else the narrow face at 1x, centred, the card's stencil clipping what runs past it. Never below 1x.
-- (QA laundry 4K, Nov 22 2026; QA laundry 1x, Nov 22 2026: 18 px past the card's bottom at 1080p and 1280x800)
local function fitFace(card, t, room, scale)
    local T, X = ZeD.T, ZeD.PhysPx
    local d = t.d
    local viewH = card._viewH
    -- what stands in the body besides the face: the top gap, the gap under it, a row each for the water (not a
    -- dryer's), what is inside and each of the clothes' states (QA LA2), and the body's closing gap
    local rows = ((d and d.dryerOnly) and 1 or 2) + #((d and d.states) or {})
    local extra = T.px(8) + T.px(6) + rows * T.px(20) + T.px(18)
    local function fits(des, k) return des.w * k <= room and (not viewH or des.h * k + extra <= viewH) end
    local des0 = P.pick(t.pid, room)
    if not des0 then return nil, t.pid, 1 end
    local k0 = math.max(1, P.k(scale))
    -- 1. the big face, the largest whole zoom first
    for k = k0, 1, -1 do
        local des, id = P.pick(t.pid, room, k)
        if des and fits(des, k) then return des, id, k end
    end
    -- (at 1x: the widest of the plate's big faces that fits, when the one picked by width does not)
    local keys = {}
    for key in pairs((X.widths and X.widths[t.pid]) or {}) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return a > b end)
    for _, key in ipairs(keys) do
        local id = X.widths[t.pid][key]
        local des = X.plates[id]
        if des and fits(des, 1) then return des, id, 1 end
    end
    -- 2. the narrow face at the largest whole zoom that fits
    local nid = X.narrow and X.narrow[t.pid]
    local nd = nid and X.plates[nid]
    if nd then
        for k = k0, 1, -1 do
            if fits(nd, k) then return nd, nid, k end
        end
        -- 3. the narrow face at 1x; the card's stencil clips what runs past it
        return nd, nid, 1
    end
    -- (a plate with no narrow face: the one picked by width at 1x, clipped the same way)
    local des, id = P.pick(t.pid, room, 1)
    return des, id, 1
end

LD._fitFace = fitFace   -- (for gc_qa_cleanup_sim.lua) (QA laundry 4K, Nov 22 2026)

-- the face (whole zoom, centred), its controls as zones, and the line under it
local function drawFace(card, x, y, w, t)
    local T = ZeD.T
    local d = t.d
    local X = ZeD.PhysPx
    if not (X and X.plates[t.pid]) then return 0 end
    -- the width that fills the card, else the narrow face where the main face at the whole zoom does not fit it
    -- (the card's plate room, the same with or without its scrollbar)
    local room = card._plateRoom or w
    local Sc = ZeD.Scale
    local des, faceId, k = fitFace(card, t, room, (Sc and Sc.root and Sc.root()) or 1)
    if not des then return 0 end
    t._face, t._k = faceId, k   -- (the face drawn and its zoom, for the QA bridge)
    local px0 = x + PL.centre(w, des.w, k)
    drawRoom(card, x, y, w, px0, des, k, faceId)  -- (behind the face: the room either side of it) (Graphic cleanup, Nov 22 2026)
    OC.faceZone(card, px0, y, des.w * k, des.h * k, t.obj)   -- (a click away from the controls pops the face out)
    LD.face(card, px0, y, k, des, t)
    local h = des.h * k + T.px(6)
    local water = (d.cap > 0) and ZeD.tr("UI_ZeD_Laundry_WaterOf", string.format("%.1f", d.fluid), math.floor(d.cap + 0.5))
        or ZeD.tr("UI_ZeD_Laundry_WaterL", string.format("%.1f", d.fluid))
    local inside = (d.n == 0) and ZeD.tr("IGUI_None") or ZeD.tr(d.n == 1 and "UI_ZeD_Laundry_ItemsOne" or "UI_ZeD_Laundry_ItemsMany", d.n)
    if d.piped then water = ZeD.tr("UI_ZeD_Laundry_WaterPiped") end
    -- (a row each: the readings are too long to share a row. None for a dryer: it takes no water)
    if not d.dryerOnly then h = h + UI.pairWide(card, x, y + h, w, ZeD.tr("UI_ZeD_Laundry_Water"), water) end
    h = h + UI.pairWide(card, x, y + h, w, ZeD.tr("UI_ZeD_Laundry_Inside"), inside)
    -- the clothes' blood, dirt and wetness, a row each as the game's tooltip has them (QA LA2, Nov 26 2026)
    for _, s in ipairs(d.states or {}) do h = h + UI.pairWide(card, x, y + h, w, ZeD.tr(s.key), pctOf(s.v)) end
    return h
end

ZeD.trDefaults({
    UI_ZeD_PlainCard_Cycle = "Cycle",
    UI_ZeD_PlainCard_Mode = "Mode",
    UI_ZeD_PlainCard_Wash = "Wash",
    UI_ZeD_PlainCard_Rinse = "Rinse",
    UI_ZeD_PlainCard_Spin = "Spin",
    UI_ZeD_PlainCard_Dry = "Dry",
    UI_ZeD_PlainCard_Cool = "Cool",
})
local PHASE_KEY = { phWash = "UI_ZeD_PlainCard_Wash", phRinse = "UI_ZeD_PlainCard_Rinse", phSpin = "UI_ZeD_PlainCard_Spin",
    phDry = "UI_ZeD_PlainCard_Dry", phCool = "UI_ZeD_PlainCard_Cool" }

-- a face control as a plain control's zone: the face's run (nil = not now) and help, by its id
local function plainRun(t, d, id)
    local fn, help = control(t, d, id)
    return fn and function(cc, p) fn(p, t) end or nil, help
end

-- The Simple form: running or stopped in large type over the load's progress (the dial); then the power switch (the
-- run lamp, NO POWER), the washer-dryer's mode keys (its WASH / DRY lamps), the water (the meter, FILL), what is
-- inside and the door, and the clothes' blood, dirt and wetness. Same zones as the face, so the mouse, the controller
-- and the opening focus are unchanged. (The big word was the made-up phase, Rinse or Spin: QA LA2, Nov 26 2026. The
-- lamps came back as dressing, so the lit phase stands small beside Running, never in its place, where it would say
-- the load was rinsing while the rows say it is still dirty: the director's call lamps, Nov 26 2026)
local function drawPlain(card, x, y, w, t)
    local T = ZeD.T
    local d = t.d
    local OP = ZeD.ObjectCardPlain
    t._face, t._k = "plain", nil   -- (for the QA bridge)
    local st = plateState(t, d)
    t._st = st
    local y0 = y
    y = y + OP.readout(card, x, y, w, {
        cols = { { label = ZeD.tr("UI_ZeD_PlainCard_Cycle"), live = d.on,
                   big = d.on and ZeD.tr("UI_ZeD_Power_PillRunning") or ZeD.tr("UI_ZeD_Plain_Stopped"),
                   unit = st.phase and ZeD.tr(PHASE_KEY[st.phase]) or nil } },
        bar = st.cycleF or 0, barLabel = ZeD.tr("UI_ZeD_PlainCard_Cycle"),
    })
    local run, help = plainRun(t, d, "power")
    local pw, pdot = ZeD.tr("UI_Off"), nil
    if d.on then pw, pdot = ZeD.tr("UI_ZeD_Power_PillRunning"), T.positive
    elseif not d.powered then pw, pdot = ZeD.tr("UI_ZeD_Plain_NoPower"), T.warning end
    y = y + OP.row(card, x, y, w, { label = ZeD.tr("IGUI_RadioPower"), value = pw, dot = pdot,
        ctl = { kind = "switch", fid = "ldy:power", on = d.on, run = run, help = help, primary = true } })
    if d.combo then
        local wr, wh = plainRun(t, d, "mode_wash")
        local dr, dh = plainRun(t, d, "mode_dry")
        y = y + OP.row(card, x, y, w, { label = ZeD.tr("UI_ZeD_PlainCard_Mode"), ctl = { kind = "pair", items = {
            { fid = "ldy:mode_wash", word = ZeD.tr("UI_ZeD_PlainCard_Wash"), sel = d.washMode, run = wr, help = wh, dis = not d.canMode },
            { fid = "ldy:mode_dry", word = ZeD.tr("UI_ZeD_PlainCard_Dry"), sel = not d.washMode, run = dr, help = dh, dis = not d.canMode },
        } } })
    end
    -- (no water row for a dryer; on the pipes the value reads "On the water pipes")
    if not d.dryerOnly then
        local water = (d.cap > 0) and ZeD.tr("UI_ZeD_Laundry_WaterOf", string.format("%.1f", d.fluid), math.floor(d.cap + 0.5))
            or ZeD.tr("UI_ZeD_Laundry_WaterL", string.format("%.1f", d.fluid))
        if d.piped then water = ZeD.tr("UI_ZeD_Laundry_WaterPiped") end
        y = y + OP.row(card, x, y, w, { label = ZeD.tr("UI_ZeD_Laundry_Water"), value = water,
            dot = st.noWater and T.warning or nil })
    end
    local inside = (d.n == 0) and ZeD.tr("IGUI_None") or ZeD.tr(d.n == 1 and "UI_ZeD_Laundry_ItemsOne" or "UI_ZeD_Laundry_ItemsMany", d.n)
    local dr2, dh2 = plainRun(t, d, "door")
    y = y + OP.row(card, x, y, w, { label = ZeD.tr("UI_ZeD_Laundry_Inside"), value = inside,
        ctl = { kind = "button", fid = "ldy:door", word = ZeD.tr("IGUI_Open"), run = dr2, help = dh2 } })
    for _, s in ipairs(d.states or {}) do
        y = y + OP.row(card, x, y, w, { label = ZeD.tr(s.key), value = pctOf(s.v) })
    end
    return y - y0
end

function def.body(card, x, y, w, t, player)
    if not t.d then return 0 end
    -- the face, or its simple form (ZeD setup's Devices row: read as it draws, so a change applies at once)
    if ZeD.ObjectCardPlain.on() then return drawPlain(card, x, y, w, t) end
    return drawFace(card, x, y, w, t)
end

OC.register(def)

--- Open the card on a machine. back = { win, zone, id }: the controller's stop to return to when it closes.
function LD.open(player, obj, back)
    if not (player and obj and ZeD_WorldWindow and ZeD_WorldWindow.openObjectCard) then return false end
    local t = def.resolve(player, obj)
    if not t then return false end
    t.back = back
    return ZeD_WorldWindow.openObjectCard(player:getPlayerNum(), { def = def, t = t }) and true or false
end

--- The World window's container button for a machine (ContainerControls, in place of vanilla's laundry buttons):
--- the gears, as the stove's settings, opening the face card.
function LD.rowSpec(playerObj, obj)
    local label = ZeD.tr("UI_ZeD_Laundry_Controls")
    local id = "obj:ZeDLaundry"
    return {
        id = id, label = label, enabled = true, icon = "gears", hint = label,
        run = function(ct, hit)
            local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow(playerObj and playerObj:getPlayerNum())
            LD.open(playerObj, obj, { win = win, zone = "worldCtl", id = "worldCtl:" .. id })
        end,
    }
end

print("[ZeD] ObjectCardLaundry: laundry card loaded")
return LD
