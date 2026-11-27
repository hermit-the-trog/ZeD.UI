-- ZeD-UI/42/media/lua/client/ZeD/FacePop.lua
-- ============================================================================
-- FACES AS POP-OUTS (client; Nov 15 2026, pop-outs: Design's handoff, part 1)
-- Every machine face a card draws pops out on its own, frameless, beside the
-- player: the two-way sets (their full view, where this began), the ordinary
-- radios, the CD player and the TVs, the ovens, the microwaves and the fryer,
-- the propane grill, the generators and the laundry. One pop-out for all of
-- them, one at a time: TwoWayFull.lua (ZeD_TwoWayFull) places it, draws its
-- shadow and strip and passes it the mouse and the controller. This file says
-- WHICH face a world object pops out with, and opens it:
--   * drivers: the radios and TVs are their own (ZeD.TwoWay, ZeD.Rtv); the
--     appliances get one over the Craft tab's plate (StationAppliance.drawPlate,
--     SA.act); the generator, the grill and the laundry get one over their
--     object cards' faces (ObjectCardPower / ObjectCardFire / ObjectCardLaundry
--     .face): the pop-out stands in for the card while the face draws on it,
--     collects the zones the face stamps and runs them as the card would.
--   * the ways in, all only with faces on (ZeD setup's Devices row on
--     Immersive) and safe mode off; with faces off nothing pops out and every
--     way in opens the card as before:
--       a left click on the machine in the world (ISObjectClickHandler.doClick:
--         not while aiming or paused, within 3 tiles on the player's floor);
--         the same machine again puts it away. The game's own click still runs
--         after (a container machine's click still shows its container);
--       A on a controller at the machine (ISButtonPrompt's Interact prompt, the
--         machine's name; it takes the oven's Turn on / off prompt);
--       the machine's own menu row: a radio's or TV's Device Options
--         (WorldRoutes.radio), an oven's or microwave's Stove settings
--         (Overrides/Stations.lua), Generator info and the propane grill's info
--         (Overrides/InfoCards.lua);
--       the cards: the face clicked away from its controls, or the header's
--         button (RadioTab, StationAppliance, ObjectCards.faceZone / popOut).
-- ============================================================================

require "ZeD/Tr"
require "ZeD/SafeMode"
require "ZeD/TwoWayFull"
require "ZeD/RtvFace"
require "ZeD/Stations"
require "ZeD/StationAppliance"
require "ZeD/ObjectCards"
require "ZeD/ObjectCardPower"
require "ZeD/ObjectCardFire"
require "ZeD/ObjectCardLaundry"

ZeD = ZeD or {}
ZeD.FacePop = ZeD.FacePop or {}
local FP = ZeD.FacePop
local TF = ZeD.TwoWayFull
local TW = ZeD.TwoWay
local P = ZeD.Px

local REFRESH_MS = 250        -- a card face's data is read again this often (the cards' OC.REFRESH: 15 sixtieths)
local CLICK_MS = 250          -- a world click and the game's radio route it sets off are one click
local OWN_FOCUS = { focused = true }

local function now() return getTimestampMs() end
local function call(o, m, ...)
    if o == nil then return nil end
    local ok, f = pcall(function() return o[m] end)
    if not (ok and f) then return nil end
    local ok2, r = pcall(f, o, ...)
    if ok2 then return r end
    return nil
end
local function root() local Sc = ZeD.Scale; return (Sc and Sc.root and Sc.root()) or 1 end

--- Faces on: ZeD setup's Devices row on Immersive (punch list 17's switch) and safe mode off.
function FP.on()
    if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on() then return false end
    local S = ZeD.Settings
    if S and S.devicesSimple then
        local ok, v = pcall(S.devicesSimple)
        if ok and v == true then return false end
    end
    return true
end

-- the room a card gives a plate (its width pick): an object card's body (ObjectCards: 480 less its margins), the
-- Craft tab's full card (480 less the scrollbar)
local function cardRoom() local T = ZeD.T; return T.px(ZeD.ObjectCards.CARD_W) - 2 * T.px(10) end
local function tabRoom() local T = ZeD.T; return T.px(480) - T.sp.scrollbarW end

-- the hits' order for the controller: the primary control first (the card's own first stop), then the order drawn
local function primaryFirst(hits)
    local out = {}
    for _, h in ipairs(hits or {}) do if h.primary then out[#out + 1] = h end end
    for _, h in ipairs(hits or {}) do if not h.primary then out[#out + 1] = h end end
    return out
end
local function hitById(dev, id)
    for _, h in ipairs((dev and dev.hits) or {}) do if h.id == id then return h end end
    return nil
end
local function noop() end
local function never() return false end
local function one() return 1 end

-- ============================================================================
-- THE OBJECT CARDS' FACES: a driver over a card kind's face (spec: kind, def, face(card, px0, y, k, des, t),
-- pick(t, room) -> des, id, names = { fid = key })
-- ============================================================================
local function cardDriver(spec)
    local D = {}
    function D.objOf(dev) return dev.obj end
    D.inReach = never                                   -- (unused: objOf names the machine, the view keeps its reach)
    -- the card's data again every REFRESH_MS; false once the machine is gone
    function D.refresh(dev, chr)
        local def = spec.def()
        local okV, valid = pcall(def.valid, dev.t)
        if not (okV and valid) then return false end
        local t = now()
        if not dev.t.d or t - (dev.at or 0) >= REFRESH_MS then
            dev.at = t
            local ok, err = pcall(def.refresh, dev.t, chr)
            if not ok then ZeD.logOnce("face pop-out " .. spec.kind, err); return false end
        end
        return dev.t.d ~= nil
    end
    function D.popFace(dev, k)
        local room = cardRoom()
        local des, id = spec.pick(dev.t, room)
        if not des then return nil, nil, k end
        return id, des, P.kFit(root(), des.w, room)     -- (whole zoom, as the card draws it)
    end
    -- the face drawn on the pop-out standing in for the card; its stamped zones become the controls
    function D.drawFace(panel, x, y, k, face)
        D._dev = face.dev      -- (one pop-out at a time: labelA reads the face's warning from it)
        local zones = {}
        panel._zones, panel._plateRoom = zones, cardRoom()
        local ok, err = pcall(spec.face, panel, x, y, k, face.des, face.dev.t)
        panel._zones = nil
        if not ok then ZeD.logOnce("face pop-out " .. spec.kind, err); return {}, nil end
        local hits = {}
        for _, z in ipairs(zones) do
            if z.fid then
                hits[#hits + 1] = { id = z.fid, x = z.x, y = z.y, w = z.w, h = z.h, knob = false, run = z.run, help = z.help,
                                    primary = z.primary, warn = z.warn }
            end
        end
        face.dev.hits = hits
        return hits, face.dev.t.d
    end
    D.hitAt = TW.hitAt
    -- a control runs as the card runs it (its zone's run, vanilla's action behind it); the data is read again soon
    function D.press(chr, dev, id)
        local h = hitById(dev, id)
        if not (h and h.run) then return end
        local ok, err = pcall(h.run, nil, chr)
        if not ok then print("[ZeD] FacePop: " .. tostring(id) .. " failed: " .. tostring(err)) end
        dev.at = 0
    end
    D.secondary, D.turn, D.holdTick = noop, noop, noop
    D.holdable, D.turnMult = never, one
    -- A's word on the pad's strip: a control's warning in place of its name (the generator's engine indoors or
    -- unable to start; the mouse reads it as the help line. QA PW1/PW4, Nov 26 2026)
    function D.labelA(id)
        local h = id and D._dev and hitById(D._dev, id)
        if h and h.warn then return h.warn end
        local key = id and spec.names[id]
        return key and ZeD.tr(key) or nil
    end
    function D.help(dev, id, h) return h and h.help or nil end
    function D.focusOrder(hits) return primaryFirst(hits) end
    return D
end

local X = function() return ZeD.PhysPx end
FP.laundry = cardDriver({ kind = "laundry", def = function() return ZeD.ObjectCardLaundry.def end,
    face = function(card, px0, y, k, des, t) return ZeD.ObjectCardLaundry.face(card, px0, y, k, des, t) end,
    pick = function(t, room) return P.pick(t.pid, room) end,
    names = { ["ldy:power"] = "IGUI_RadioPower", ["ldy:mode_wash"] = "UI_ZeD_PlainCard_Wash", ["ldy:mode_dry"] = "UI_ZeD_PlainCard_Dry",
              ["ldy:door"] = "IGUI_Open" } })
FP.generator = cardDriver({ kind = "generator", def = function() return ZeD.ObjectCardPower.def end,
    face = function(card, px0, y, k, des, t) return ZeD.ObjectCardPower.face(card, px0, y, k, des, t) end,
    pick = function(t, room)
        local des, id = ZeD.ObjectCardPower.plateFor(t.d)
        if not des then return nil, nil end
        return P.pick(id, room)
    end,
    names = { ["gen:engine"] = "UI_ZeD_PlainCard_Engine", ["gen:outlet"] = "UI_ZeD_PlainCard_Outlet" } })
FP.grill = cardDriver({ kind = "fire", def = function() return ZeD.ObjectCardFire.def end,
    face = function(card, px0, y, k, des, t) return ZeD.ObjectCardFire.grillFace(card, px0, y, k, des, t) end,
    pick = function(t, room) local x = X(); return P.pick(x and x.fallback.propane, room) end,
    names = { ["bbq:burner"] = "UI_ZeD_PlainCard_Burner", ["bbq:ignite"] = "UI_ZeD_PlainCard_Igniter", ["bbq:tank"] = "UI_ZeD_Fire_Tank" } })

-- ============================================================================
-- THE APPLIANCES (ovens, microwaves, the fryer): a driver over the Craft tab's plate. dev = { st, obj }
-- ============================================================================
local AP = {}
FP.appliance = AP
local SA = ZeD.StationAppliance
function AP.objOf(dev) return dev.obj end
AP.inReach = never
function AP.refresh(dev)
    local o = dev.obj
    local ok, here = pcall(function() return o:getSquare() ~= nil and o:getObjectIndex() >= 0 end)
    return ok and here
end
-- the full card's width pick, as the Craft tab draws it at the full card
function AP.popFace(dev, k)
    local des, pid = SA.plateFor(dev.st)
    if not des then return nil, nil, k end
    local room = tabRoom()
    des, pid = P.pick(pid, room)
    if not des then return nil, nil, k end
    return pid, des, P.kFit(root(), des.w, room)
end
function AP.drawFace(panel, x, y, k, face)
    local zones = SA.drawPlate(panel, x, y, k, face.dev.st, face.des, face.pid, {},
        { fid = face.focusId, grabId = face.grabId, markOpts = OWN_FOCUS, noHover = face.focusId ~= nil })
    local hits = {}
    for _, z in ipairs(zones) do
        hits[#hits + 1] = { id = z.fid, x = z.x, y = z.y, w = z.w, h = z.h, knob = z.kind == "turn", zone = z }
    end
    face.dev.hits = hits
    return hits, nil
end
AP.hitAt = TW.hitAt
-- a click (a knob: toward the half clicked), A; SA.act, as the tab and its window do
function AP.press(chr, dev, id, dx)
    local h = hitById(dev, id)
    if h then SA.act(chr, dev.st, h.zone, (dx and dx < 0) and -1 or 1) end
end
function AP.turn(chr, dev, id, dir)
    local h = hitById(dev, id)
    if h and h.knob then SA.act(chr, dev.st, h.zone, dir) end
end
-- a right click on a knob turns it down, as on the radios
function AP.secondary(chr, dev, id) AP.turn(chr, dev, id, -1) end
AP.holdTick, AP.holdable, AP.turnMult = noop, never, one
function AP.labelA(id) return SA.controlName(id and id:match("^craft:a:(.+)$")) end

-- ============================================================================
-- WHICH FACE AN OBJECT POPS OUT WITH
-- ============================================================================
-- a world object of the kinds that have a face, without building anything (the controller's prompt asks every tick)
local function isMachine(o)
    if not o or type(o) == "table" then return false end   -- (a Lua campfire, a card's target: not a world object)
    if instanceof(o, "IsoWaveSignal") then return TF.radioDriver(o) ~= nil end
    if instanceof(o, "IsoStove") or instanceof(o, "IsoGenerator") then return true end
    if ZeD.ObjectCardLaundry.plateId(o) then return true end
    return call(o, "isPropaneBBQ") == true
end
FP.isMachine = isMachine

--- The driver and the dev a world object pops out with, nil, nil when it has no face. st: the Craft tab's station
--- entry when it asks for its own oven.
function FP.resolve(player, obj, st)
    if not (player and obj) or type(obj) == "table" then return nil, nil end
    local m = call(obj, "getMasterObject") or obj
    local list = (m ~= obj) and { obj, m } or { obj }
    for _, o in ipairs(list) do
        if instanceof(o, "IsoWaveSignal") then
            local drv = TF.radioDriver(o)
            if drv then return drv, o end
        elseif ZeD.ObjectCardLaundry.plateId(o) then
            local t = ZeD.ObjectCardLaundry.def.resolve(player, o)
            if t then return FP.laundry, { t = t, obj = t.obj } end
        elseif instanceof(o, "IsoGenerator") then
            local t = ZeD.ObjectCardPower.def.resolve(player, o)
            if t then return FP.generator, { t = t, obj = t.obj } end
        elseif call(o, "isPropaneBBQ") == true then
            local t = ZeD.ObjectCardFire.def.resolve(player, o)
            if t and t.kind == "propane" then return FP.grill, { t = t, obj = t.obj } end
        elseif instanceof(o, "IsoStove") then
            local e = (st and st.obj == o) and st or ZeD.Stations.entryFor(player, o)
            if e and (e.kind == "oven" or e.kind == "micro") then return AP, { st = e, obj = e.obj } end
        end
    end
    return nil, nil
end

-- the World window, for the controller's way back when the pop-out closes
local function worldWin(pn)
    local w = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow(pn)
    if w and w:isReallyVisible() then return w end
    return nil
end

--- Pop out the face of a world object (win: where the controller goes back to; the World window when nil). False
--- when faces are off, the object has no face or it could not open: the caller then does what it did before.
function FP.open(player, obj, win, st)
    if not (player and obj) or not FP.on() then return false end
    local ok, drv, dev = pcall(FP.resolve, player, obj, st)
    if not (ok and drv) then
        if not ok then ZeD.logOnce("face pop-out resolve", drv) end
        return false
    end
    if dev.t then
        -- (the card's data before the first frame, as the card reads it when it opens)
        local okR = pcall(drv.refresh, dev, player)
        if not okR then return false end
        dev.at = now()
    end
    local pn = player:getPlayerNum()
    return TF.open(player, dev, win or worldWin(pn), drv) ~= nil
end

--- The same, or put away when it already shows this object (the cards' button and face, a click on the machine again).
function FP.toggle(player, obj, win, st)
    if not (player and obj) then return false end
    local pn = player:getPlayerNum()
    if TF.showingObj(pn, obj) then TF.close(pn); return true end
    return FP.open(player, obj, win, st)
end

-- ============================================================================
-- THE WAYS IN FROM THE WORLD
-- ============================================================================
-- the machine within 3 tiles (ISEntityUI.isoPanelWalkToDist) on the player's floor
local function near(player, obj)
    local ok, d, floor = pcall(function()
        local dx, dy = obj:getX() + 0.5 - player:getX(), obj:getY() + 0.5 - player:getY()
        return math.sqrt(dx * dx + dy * dy), math.floor(obj:getZ()) == math.floor(player:getZ())
    end)
    return ok and floor and d <= TF.REACH
end

FP._click = FP._click or { obj = nil, at = 0 }

-- A left click on a machine in the world (the game's click handler, before its own work): the face pops out, or goes
-- away when it shows that machine. The game's own rules first: player 1's click, alive, not aiming, not on a ladder,
-- the game not paused, the square seen; then within reach. Remembers the machine for the radio route the game's click
-- may set off next (FP.takeRadio).
function FP.worldClick(object)
    if not (object and FP.on()) then return end
    local p = getSpecificPlayer(0)
    if not p or p:isDead() or p:isAiming() or p:getVehicle() then return end
    local spd = UIManager.getSpeedControls and UIManager.getSpeedControls()
    if spd and spd:getCurrentGameSpeed() == 0 then return end
    if call(p, "isClimbingLadder") or call(p, "isIgnoreContextKey") then return end
    if not isMachine(object) and not isMachine(call(object, "getMasterObject")) then return end
    local drv, dev = FP.resolve(p, object)
    if not drv then return end
    local obj = (drv.objOf and drv.objOf(dev)) or dev
    local sq = call(obj, "getSquare")
    if not (sq and sq:isSeen(0) and near(p, obj)) then return end
    FP._click.obj, FP._click.at = obj, now()
    FP.toggle(p, obj)
end

--- The game's radio window route for a device in the world (WorldRoutes.radio asks first): true when the pop-out
--- took it. A device the world click above just handled (the game's click sets off the radio window as well): taken,
--- nothing more. Else, with faces on and a face for it, the pop-out opens (Device Options: it opens, it never toggles).
function FP.takeRadio(chr, dev)
    local c = FP._click
    if c.obj ~= nil and c.obj == dev and now() - c.at < CLICK_MS then return true end
    if not FP.on() or not TF.radioDriver(dev) then return false end
    local pn = chr:getPlayerNum()
    if TF.showingObj(pn, dev) then return true end
    return FP.open(chr, dev)
end

-- the controller's A at a machine: the Interact prompt names it (Close when it shows that machine) and opens it. It
-- takes only an empty prompt: the oven's own Turn on / off stays the game's and only turns the stove on or off
-- (the director's KISS #58 pick, over punch list 208's "Turn on opens the panel")
function FP.padPrompt(bp, dir)
    if not FP.on() then return end
    local P0 = ISButtonPrompt
    if bp.aPrompt ~= nil then return end
    local p = getSpecificPlayer(bp.player)
    if not p or p:getVehicle() then return end
    local sq1 = p:getCurrentSquare()
    local sq2 = sq1 and dir and sq1:getAdjacentSquare(dir)
    for _, sq in ipairs({ sq2 or false, sq1 or false }) do
        if sq and (sq == sq1 or not sq1:isSomethingTo(sq)) then
            local objs = sq:getObjects()
            for i = 0, objs:size() - 1 do
                local o = objs:get(i)
                if isMachine(o) then
                    local label
                    if TF.showingObj(bp.player, o) then label = ZeD.tr("UI_ZeD_Close")
                    else
                        local ok, n = pcall(ISWorldObjectContextMenu.getMoveableDisplayName, o)
                        label = (ok and n and n ~= "") and n or ZeD.tr("UI_ZeD_Prompt_Use")
                    end
                    bp:setAPrompt(label, P0.zedFacePop, o)
                    return
                end
            end
        end
    end
end

-- the hooks, once each (_zed flags: a Lua reload never wraps a wrapper); the world click handler lives in the game's
-- server folder, so they go on at boot and at game start as well as now
local function hook()
    local H = ISObjectClickHandler
    if H and H.doClick and not H._zedFacePop then
        H._zedFacePop = true
        local orig = H.doClick
        H.doClick = function(object, x, y)
            local ok, err = pcall(FP.worldClick, object)
            if not ok then ZeD.logOnce("face pop-out click", err) end
            return orig(object, x, y)
        end
    end
    local B = ISButtonPrompt
    if B and B.testInteractButtonAction and not B._zedFacePop then
        B._zedFacePop = true
        local origT = B.testInteractButtonAction
        B.testInteractButtonAction = function(self, dir)
            origT(self, dir)
            local ok, err = pcall(FP.padPrompt, self, dir)
            if not ok then ZeD.logOnce("face pop-out prompt", err) end
        end
        -- (on the prompt's own table, so ZeD's hint strip finds it by name)
        function B:zedFacePop(obj) FP.toggle(getSpecificPlayer(self.player), obj) end
    end
end
FP.hook = hook
hook()
if Events then
    if Events.OnGameBoot then Events.OnGameBoot.Add(hook) end
    if Events.OnGameStart then Events.OnGameStart.Add(hook) end
end

return FP
