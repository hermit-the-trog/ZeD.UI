-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardLaundry.lua
-- ============================================================================
-- OBJECT CARD: LAUNDRY (Oct 30 2026; HANDOFF_radio_tv_laundry_20261030.md,
-- the director: "Washer and dryer I trust you. Do those so we can ship that
-- too.") The washer, the dryer and the stacked washer-dryer each show their
-- own front panel in pixel art in the full card, as the generator and the
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
--   door       its contents in the Loot pane (ZeD_WorldWindow.selectContainer)
-- Live on the face: the run lamp (green) or no power (red), the water meter
-- and the water in the drum (fluid against capacity, 0..5), FILL (washer mode
-- with no water), the clothes in the drum, the washer-dryer's WASH / DRY
-- lamps. The game has no wash phases, so the clock makes them: while it runs
-- the phase lamps step every PHASE_MIN game minutes (washer WASH, RINSE, SPIN;
-- dryer DRY, COOL; the washer-dryer by its mode) and round again, the cycle
-- dial follows them 0 to 1, and the drum turns once in DRUM_MS of real time
-- (it stops with the game paused). Stopped: phase lamps dark, the dial at 0.
-- Under the face: the water and what is inside. The band at the foot says
-- what stops it running (no power, no water), in vanilla's words.
-- Where it opens: the World window's container buttons (ContainerControls:
-- one button in place of vanilla's laundry buttons while LD.useFace says so).
-- LD.useFace is the one switch between the face and today's plain controls
-- (punch list 17, "faces or simple cards", will hang its setting there).
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

ZeD.ObjectCardLaundry = ZeD.ObjectCardLaundry or {}
local LD = ZeD.ObjectCardLaundry

LD.PHASE_MIN = 5      -- game minutes a phase lamp stays lit (12.5 s of real time at the default day length)
LD.DRUM_MS   = 2000   -- real ms for one turn of the drum
LD.PHASES = {
    washer = { "phWash", "phRinse", "phSpin" },
    dryer  = { "phDry", "phCool" },
}
local ALL_PHASES = { "phWash", "phRinse", "phSpin", "phDry", "phCool" }

-- when each running machine was first seen running, by its card key: { min, mode } (the clock's phases start there)
LD._run = LD._run or {}

-- the plate id for this object ("washer", "dryer", "washer_dryer"), or nil when it is not a laundry machine
function LD.plateId(obj)
    local X = ZeD.PhysPx
    local classes = X and X.laundry and X.laundry.classes
    if not (obj and classes) then return nil end
    for cls, pid in pairs(classes) do
        if instanceof(obj, cls) then return pid end
    end
    return nil
end

-- Faces or simple cards (punch list 17): true shows the machine's face card in place of vanilla's plain laundry
-- buttons; false leaves today's plain controls exactly as they were. The one switch: the setting goes here.
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

-- its contents in the Loot pane (the container the World window already lists)
local function openDoor(p, t)
    local c = call(t.obj, "getContainer")
    if c and ZeD_WorldWindow and ZeD_WorldWindow.selectContainer then ZeD_WorldWindow.selectContainer(c, 120) end
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
    d.washMode = (not d.combo and instanceof(o, "IsoClothingWasher")) or (d.combo and o:isModeWasher()) or false
    d.hasWater = d.fluid > 0
    local items = c and c:getItems()
    d.n = items and items:size() or 0
    d.name = nameOf(o)
    -- vanilla's checks: the switch needs power, and water in washer mode; the mode keys need power
    d.canToggle = d.powered and (d.hasWater or not d.washMode)
    d.canMode = d.combo and d.powered
    t.d = d
    t.verbs = {}   -- (the face is the control surface: no verb row under the header)
end

function def.title(t) return t.d and t.d.name or nameOf(t.obj) end
function def.icon(t) return OC.spriteIcon(t.obj) end
function def.pill(t)
    local T = ZeD.T
    if t.d and t.d.on then return ZeD.tr("UI_ZeD_Power_PillRunning"), T.positive end
    return ZeD.tr("UI_Off"), T.textDim
end
-- the controller lands on the switch
function def.openFocus(t) return "ldy:power" end

-- what keeps it from running, in vanilla's words (the band shows only then)
function def.status(t)
    local T = ZeD.T
    local d = t.d
    if not d then return nil end
    if not d.powered then return { text = ZeD.trBare("IGUI_RadioRequiresPowerNearby"), c = T.warning } end
    if d.washMode and not d.hasWater then return { text = ZeD.trBare("IGUI_RequiresWaterSupply"), c = T.warning } end
    return nil
end

-- the card closed with the controller on it: back to the button that opened it (the director's pad rule 1)
function def.onClose(t, card)
    local b = t.back
    t.back = nil
    local F = ZeD.Input and ZeD.Input.Focus
    if not (b and card and card._fid and F and F.focusSoon) then return end
    F.focusSoon(b.win, b.zone, function(e)
        return e.id == b.id and not (ZeD_WorldWindow.getObjectCard and ZeD_WorldWindow.getObjectCard())
    end, 1)
end

-- the clock's part of the face: phase lamps and the cycle dial by game minutes, the drum by real time
local function clockState(t, d, st)
    local key = t.key
    local mode = d.washMode and "washer" or "dryer"
    local run = LD._run[key]
    if not d.on then
        LD._run[key] = nil
        st.cycleF = 0
    else
        local now = gameMinutes()
        if not run or run.mode ~= mode then run = { min = now, mode = mode }; LD._run[key] = run end
        local list = LD.PHASES[mode]
        local cycle = LD.PHASE_MIN * #list
        local pos = math.max(0, now - run.min) % cycle
        local i = math.min(#list, math.floor(pos / LD.PHASE_MIN) + 1)
        st[list[i]] = true
        st.cycleF = pos / cycle
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

-- The water meter is a powered display; the water in the drum is not (director, Oct 30 2026: "the meter goes dark
-- without power, the water in the drum still shows"). Both are `bars` parts reading `water` in the export, and the
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
    st.modeWash = d.combo and d.washMode
    st.modeDry = d.combo and not d.washMode
    clockState(t, d, st)
    return st
end
LD.plateState = plateState

local function plateTex(name) return P.tex(ZeD.PhysPx.texdir .. name .. ".png") end

-- each control: what it does now (nil = not now) and its help line
local function control(t, d, id)
    if id == "power" then
        if not d.powered then return nil, ZeD.tr("UI_ZeD_Laundry_HelpNoPower") end
        if not d.canToggle then return nil, ZeD.tr("UI_ZeD_Laundry_HelpNoWater") end
        return toggle, ZeD.tr(d.on and "UI_ZeD_Laundry_HelpOff" or "UI_ZeD_Laundry_HelpOn")
    elseif id == "mode_wash" or id == "mode_dry" then
        local mode = (id == "mode_wash") and "washer" or "dryer"
        local help = ZeD.tr(mode == "washer" and "UI_ZeD_Laundry_HelpWash" or "UI_ZeD_Laundry_HelpDry")
        if not d.canMode then return nil, ZeD.tr("UI_ZeD_Laundry_HelpNoPower") end
        if (mode == "washer") == d.washMode then return nil, help end
        return function(p, tt) setMode(p, tt, mode) end, help
    elseif id == "door" then
        return openDoor, ZeD.tr("UI_ZeD_Laundry_HelpDoor")
    end
    return nil, nil
end

-- the face (whole zoom, centred), its controls as zones, and the line under it
local function drawFace(card, x, y, w, t)
    local T = ZeD.T
    local d = t.d
    local X = ZeD.PhysPx
    if not (X and X.plates[t.pid]) then return 0 end
    -- the width that fills the card, else the narrow face where the main face at the whole zoom does not fit it
    -- (the card's plate room, the same with or without its scrollbar)
    local room = card._plateRoom or w
    local des, faceId = P.pick(t.pid, room)
    if not des then return 0 end
    t._face, t._k = faceId, nil   -- (the face drawn and its zoom, for the QA bridge)
    local Sc = ZeD.Scale
    local k = P.kFit((Sc and Sc.root and Sc.root()) or 1, des.w, room)   -- whole zoom, inside the card
    t._k = k
    local px0 = x + PL.centre(w, des.w, k)
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
    local h = des.h * k + T.px(6)
    local water = (d.cap > 0) and ZeD.tr("UI_ZeD_Laundry_WaterOf", string.format("%.1f", d.fluid), math.floor(d.cap + 0.5))
        or ZeD.tr("UI_ZeD_Laundry_WaterL", string.format("%.1f", d.fluid))
    local inside = (d.n == 0) and ZeD.tr("IGUI_None") or ZeD.tr(d.n == 1 and "UI_ZeD_Laundry_ItemsOne" or "UI_ZeD_Laundry_ItemsMany", d.n)
    h = h + UI.pair(card, x, y + h, w, ZeD.tr("UI_ZeD_Laundry_Water"), water, ZeD.tr("UI_ZeD_Laundry_Inside"), inside)
    return h
end

function def.body(card, x, y, w, t, player)
    if not t.d then return 0 end
    return drawFace(card, x, y, w, t)
end

OC.register(def)

-- Open the card on a machine. back = { win, zone, id }: the controller's stop to return to when it closes.
function LD.open(player, obj, back)
    if not (player and obj and ZeD_WorldWindow and ZeD_WorldWindow.openObjectCard) then return false end
    local t = def.resolve(player, obj)
    if not t then return false end
    t.back = back
    return ZeD_WorldWindow.openObjectCard(player:getPlayerNum(), { def = def, t = t }) and true or false
end

-- The World window's container button for a machine (ContainerControls, in place of vanilla's laundry buttons):
-- the gears, as the stove's settings, opening the face card.
function LD.rowSpec(playerObj, obj)
    local label = ZeD.tr("UI_ZeD_Laundry_Controls")
    local id = "obj:ZeDLaundry"
    return {
        id = id, label = label, enabled = true, icon = "gears", hint = label,
        run = function(ct, hit)
            local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
            LD.open(playerObj, obj, { win = win, zone = "worldCtl", id = "worldCtl:" .. id })
        end,
    }
end

print("[ZeD] ObjectCardLaundry: laundry card loaded")
return LD
