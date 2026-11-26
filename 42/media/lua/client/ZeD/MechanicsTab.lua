-- ZeD-UI/42/media/lua/client/ZeD/MechanicsTab.lua
-- ============================================================================
-- VEHICLE TAB — World window, contextual (replaces vanilla ISVehicleMechanics)
-- Client. A full tab renderer: immediate-mode drawing off the World window's
-- dispatch table, state kept on the window (win._mech).
--
-- Two columns, as Crafting and Building (CraftingCore's split measure): the part list
-- on the left (By section: the game's categories, a part under the one that has to come
-- off first, from the parts' own install tables; By condition: worst first, earned at
-- Mechanics level 4); on the right the car diagram (scanline layers baked from the
-- vanilla mechanics overlay by ZeDUI/tools/mechanics/bake_mech_figs.py, MechFigs) with
-- the vehicle's summary, or, a part chosen, its card: the step before, the readings and
-- where the work is done, the install pick list or the repair recipes, a NEEDS line for
-- each greyed verb, the part's vanilla info text. A click or A on a row chooses the part,
-- the same row again or B brings the diagram back; no back arrow, no second screen. The
-- footer holds Sort and the chosen part's verbs (lit, or greyed with what they need in
-- the card); destructive verbs confirm in it. X / right-click on a part opens vanilla's
-- own part menu, which ZeD's context-menu hook renders. Another mod's support file can
-- add to a part's verbs and follow the part menu through MT.addExtras (EXTRAS below).
--
-- On a server with vehicle claims on (ZeD_ExtrasCards.lua): who holds the car in the
-- summary, Claim or Release in the footer, Uninstall and Take Parts grayed on another's.
--
-- Entry: Overrides/VehicleMechanics.lua routes ISOpenMechanicsUIAction:perform
-- (right-click Mechanics, the hood, the mechanics key) to MT.openFromAction.
-- Before an inspection the tab shows only what can be seen from outside and an
-- INSPECT button (vanilla's walk-over-and-look action). An inspection lasts
-- until the player is more than six tiles away, as vanilla closes its window.
--
-- Every layout number is a DESIGN UNIT and goes through T.px at use.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/MechFigs"
require "ZeD/MechTrailer"
require "ZeD/ZeD_Popups"
require "ZeD/RadioTab"   -- (ZeD.SubTabs, the sub-page tab strip)

ZeD = ZeD or {}
ZeD.MechanicsTab = ZeD.MechanicsTab or {}
local MT = ZeD.MechanicsTab

-- ----------------------------------------------------------------------------
-- Constants (design units unless noted)
-- ----------------------------------------------------------------------------
local REACH_TILES   = 4.5    -- tiles from the vehicle centre: the tab offers it
local KEEP_TILES    = 6      -- tiles: an inspection lasts until you walk past this (vanilla)
local PAD           = 10
local FIG_H         = 258    -- the most height the diagram takes in the right column (the figures are at most 169 rows since Nov 22 2026; drawFigure uses only what its zoom needs)
local COL_GAP       = 12
local ROW_H         = 24
local CAT_H         = 15     -- the library's category row
local SEC_H         = 20
-- a card section's head: the category row (the one section style, punch list 175 D6), no fold triangle
-- (it does not fold), SEC_H tall, its words at the card's inset
local _secO = { noArrow = true }
local function _secOpts(pad) _secO.h, _secO.inset = ZeD.T.px(SEC_H), pad; return _secO end
local FIX_H         = 38
local MINI_BAR_W    = 40
local LIST_BAR_W    = 24     -- the part list's bar, in its narrower column
local PCT_W         = 34
local SCROLL_STEP   = 48
local FLASH_MS      = 1600
local ITEMS_TTL_MS  = 700

local CAT_ORDER = { "engine", "gastank", "tire", "brakes", "suspension", "lights",
                    "door", "bodywork", "seat", "dashboard", "trunk", "Other" }
local CAT_RANK = {}
for i, c in ipairs(CAT_ORDER) do CAT_RANK[c] = i end

local DOT = "|"   -- the separator: ZeD's pipe, never a middle dot

-- Inspections survive the World window closing (keyed by vehicle id):
-- { vehicle = BaseVehicle, hood = VehiclePart|nil }
local INSP = MT._insp or {}   -- kept across a hot reload of this file
MT._insp = INSP
-- Vehicles opened on purpose (a trailer's Check Animals, the towing link):
-- they stay in the list to six tiles, as an inspection does. { [id] = BaseVehicle }
local PIN = MT._pin or {}
MT._pin = PIN

-- ----------------------------------------------------------------------------
-- Small helpers
-- ----------------------------------------------------------------------------
local function txt(key, fallback)
    local t = getTextOrNull and getTextOrNull(key) or nil
    return t or fallback
end
local function round(n, dp)
    local m = 10 ^ (dp or 0)
    return math.floor(n * m + 0.5) / m
end
-- words that arrive in capitals read in sentence case (ZeD.textCase)
local function cased(s) return ZeD.textCase(tostring(s or "")) end
-- the plain-words line the window's footer shows while the pointer is over a part
local function help(panel, key, ...)
    if ZeD.Help and ZeD.Help.set then ZeD.Help.set(panel, ZeD.tr(key, ...)) end
end
local function now() return (getTimestampMs and getTimestampMs()) or 0 end
local function hit(z, x, y) return z ~= nil and x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h end
-- (the status bars' rule, so a reading and its bar agree: ZeD.Atoms.statusColor, punch list 143)
local function statusColor(T, pct) return ZeD.Atoms.statusColor(pct / 100) end
local function thousands(n)
    local s = tostring(math.floor(n + 0.5))
    local out = ""
    while string.len(s) > 3 do
        out = "," .. string.sub(s, -3) .. out
        s = string.sub(s, 1, string.len(s) - 3)
    end
    return s .. out
end
local function partName(id) return txt("IGUI_VehiclePart" .. tostring(id), tostring(id)) end
local function catLabel(cat) return cased(txt("IGUI_VehiclePartCat" .. tostring(cat), tostring(cat))) end
-- pn: the window's player (players 2-4 are always on a controller)
local function isGamepad(pn)
    local D = ZeD and ZeD.Input and ZeD.Input.Detector
    return (D and D.getMode and D.getMode(pn) == "gamepad") or false
end
local function mechLevel(chr) return chr:getPerkLevel(Perks.Mechanics) end

local function st(win)
    local s = win._mech
    if not s then
        s = { vehicles = {}, idx = 1, view = "overview", card = nil, verb = nil,
              scrollY = 0, cardScroll = 0, sort = "area", collapsed = {},
              pick = 1, fixPick = 1, zones = {}, byId = {}, confirm = nil,
              flash = nil, maxScroll = 0 }
        win._mech = s
    end
    return s
end
MT.getState = st

local function currentEntry(s) return s.vehicles[s.idx] end

-- ----------------------------------------------------------------------------
-- Vehicles in reach + inspection lifecycle
-- ----------------------------------------------------------------------------
local function setMechOpen(v, on, chr)
    pcall(function() v:setMechanicUIOpen(on) end)
    -- vanilla toggles physics with its window; never switch it off under a driver
    if on or not (chr and chr:getVehicle() == v) then
        pcall(function() v:setActiveInBullet(on) end)
    end
end

local function distTo(chr, v)
    local dx, dy = v:getX() - chr:getX(), v:getY() - chr:getY()
    return math.sqrt(dx * dx + dy * dy)
end

-- True when the car is gone from the world. getSquare() only looks up the ground at the car's last x, y, z, so a car
-- the game removed (a wreck scrapped with the torch, an admin, a mod) still has one; the car itself knows (QA B7-6).
-- Shared: the seat windows and the Maskarad's mod support call it too.
function ZeD.carGone(v)
    if v == nil then return true end
    local ok, removed = pcall(function() return v:isRemovedFromWorld() end)
    if ok and removed == true then return true end
    return v:getSquare() == nil   -- (unloaded ground)
end
local carGone = ZeD.carGone

local function endInspection(vid, chr, gone)
    local e = INSP[vid]
    INSP[vid] = nil   -- (keyed by the car's id, which the game hands to the next car it adds: always dropped) (QA B7-6)
    if not e then return end
    if gone then return end   -- (a car that is gone has no hood to close, no mechanic flag to clear) (QA B7-6)
    local v, hood = e.vehicle, e.hood
    if v then setMechOpen(v, false, chr) end
    -- vanilla closes the hood it opened when the window closes at the hood
    if v and hood and chr then
        pcall(function()
            if hood:getDoor() and hood:getDoor():isOpen() and v:isInArea(hood:getArea(), chr) then
                ISTimedActionQueue.add(ISCloseVehicleDoor:new(chr, v, hood))
            end
        end)
    end
end

-- The look ends (and the hood it opened shuts, as vanilla's window does) when the World window closes while he
-- stands at the hood (QA K1-9). Called from the World window's close. Past the hood's reach nothing is closed.
function MT.endLooks(chr)
    if not chr then return end
    local ids = {}
    for vid in pairs(INSP) do ids[#ids + 1] = vid end   -- (collected first: endInspection clears entries)
    for _, vid in ipairs(ids) do
        local e = INSP[vid]
        local v = e and e.vehicle
        if v then endInspection(vid, chr, carGone(v)) end
    end
end

-- E at a hood that is open on a car already looked at: end the look and shut the hood instead of looking again
-- (QA K1-9). True when it did so, so the caller skips vanilla's look.
function MT.closeHoodLook(chr, vehicle, part)
    if not (chr and vehicle and part) then return false end
    local vid = vehicle:getId()
    if not INSP[vid] then return false end
    local ok, open = pcall(function() return part:getDoor() ~= nil and part:getDoor():isOpen() end)
    if not (ok and open) then return false end
    local e = INSP[vid]
    e.hood = e.hood or part   -- (the hood he stands at is the one to shut, whoever opened it)
    endInspection(vid, chr, false)
    return true
end

function MT.buildVehicles(chr)
    local out = {}
    if not chr then return out end
    local cell = getCell()
    local set = cell and cell:getVehicles()
    if not set then return out end
    local cz = math.floor(chr:getZ())
    local inside = chr:getVehicle()
    local it = set:iterator()
    while it:hasNext() do
        local v = it:next()
        if v and not carGone(v) and math.floor(v:getZ()) == cz then
            local d = distTo(chr, v)
            local vid = v:getId()
            if d <= REACH_TILES or ((INSP[vid] or PIN[vid]) and d <= KEEP_TILES) or inside == v then
                out[#out + 1] = { vehicle = v, id = vid, dist = d }
            end
        end
    end
    -- a car and the trailer it tows come as a pair (TOWING / TOWED BY link them)
    local have = {}
    for _, e in ipairs(out) do have[e.id] = true end
    local n = #out
    for i = 1, n do
        local v = out[i].vehicle
        local ok1, a = pcall(function() return v:getVehicleTowing() end)
        local ok2, b = pcall(function() return v:getVehicleTowedBy() end)
        for _, o in ipairs({ ok1 and a or false, ok2 and b or false }) do
            if o and not carGone(o) and not have[o:getId()] then
                have[o:getId()] = true
                out[#out + 1] = { vehicle = o, id = o:getId(), dist = distTo(chr, o) }
            end
        end
    end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    return out
end

function MT.pin(v) if v then PIN[v:getId()] = v end end

-- Within the tab's reach (vanilla's trailer menus skip their walk from here)
function MT.inReach(chr, v)
    return chr ~= nil and v ~= nil and not carGone(v)
        and math.floor(v:getZ()) == math.floor(chr:getZ()) and distTo(chr, v) <= REACH_TILES
end

-- Called by the World window's periodic refresh (beside the radio list).
function MT.refresh(win)
    if not win then return end
    local s = st(win)
    local chr = win._playerObj or getSpecificPlayer(win.playerNum or 0)
    if not chr then return end
    local cur = currentEntry(s)
    local curId = cur and cur.id
    s.vehicles = MT.buildVehicles(chr)
    -- inspections end past six tiles or when the vehicle is gone
    for vid, e in pairs(INSP) do
        local v = e.vehicle
        local alive = v and not carGone(v)   -- (QA B7-6)
        if not alive or distTo(chr, v) > KEEP_TILES then endInspection(vid, chr, not alive) end
    end
    for vid, v in pairs(PIN) do
        if carGone(v) or distTo(chr, v) > KEEP_TILES then PIN[vid] = nil end   -- (QA B7-6)
    end
    local want = s.pendingId or curId
    s.idx = 1
    if want then
        for i, e in ipairs(s.vehicles) do if e.id == want then s.idx = i end end
    end
    if s.pendingId then
        for _, e in ipairs(s.vehicles) do if e.id == s.pendingId then s.pendingId = nil; break end end
    end
    local nc = currentEntry(s)
    if (nc and nc.id) ~= curId then
        s.view, s.card, s.verb, s.confirm = "overview", nil, nil, nil
        s.animal, s.animalId = nil, nil
        s.scrollY, s.cardScroll = 0, 0
    end
end

function MT.isVisible(win)
    local s = win and win._mech
    return s ~= nil and #s.vehicles > 0
end

-- ----------------------------------------------------------------------------
-- Part model
-- ----------------------------------------------------------------------------
local function isMissing(part)
    local it = part:getItemType()
    return it ~= nil and not it:isEmpty() and part:getInventoryItem() == nil and part:getTable("install") ~= nil
end
local function isSmashed(part)
    local w = part:getWindow()
    return w ~= nil and w:isDestroyed()
end

local function partInfo(part, chr, v)
    if isMissing(part) then return "" end
    local id, item = part:getId(), part:getInventoryItem()
    if id == "Battery" and item and item.getCurrentUsesFloat then
        return ZeD.tr("UI_ZeD_Veh_Charge", math.floor(item:getCurrentUsesFloat() * 100) .. "%")
    end
    if part:isContainer() and part:getContainerContentType() then
        local ct, amt, cap = part:getContainerContentType(), part:getContainerContentAmount(), part:getContainerCapacity()
        if ct == "Air" then return ZeD.tr("UI_ZeD_Veh_PsiOf", math.floor(amt + 0.5), math.floor(cap)) end
        return tostring(round(amt, 1)) .. " / " .. tostring(math.floor(cap))
    end
    local door = part:getDoor()
    if door then
        if door:isOpen() then return ZeD.tr("UI_ZeD_Veh_StOpen") end
        if door:isLockBroken() then return ZeD.tr("IGUI_LockBroken") end
        if door:isLocked() then return getText("EC_Locked") end
        return ZeD.tr("UI_ZeD_Veh_StClosed")
    end
    local w = part:getWindow()
    if w then
        if not w:isDestroyed() and w:isOpenable() and w:isOpen() then return ZeD.tr("UI_ZeD_Veh_StOpen") end
        return ""
    end
    if part:getItemContainer() then
        local seat = part:getContainerSeatNumber()
        if seat and seat > -1 and v:isSeatOccupied(seat) then return ZeD.tr("UI_ZeD_Veh_StOccupied") end
        local ok, s = pcall(function()
            return tostring(round(part:getItemContainer():getCapacityWeight(), 1)) .. " / " .. tostring(part:getContainerCapacity(chr))
        end)
        return ok and s or ""
    end
    return ""
end

local function partModel(part, chr, v)
    local missing, smashed = isMissing(part), isSmashed(part)
    return {
        part = part, id = part:getId(), cat = part:getCategory() or "Other",
        name = partName(part:getId()),
        cond = missing and 0 or part:getCondition(),
        missing = missing, smashed = smashed,
        info = partInfo(part, chr, v),
    }
end

-- the part ids an install / uninstall table names ("A;B" or one id)
local function idsIn(val)
    local out = {}
    if type(val) == "string" then
        for id in string.gmatch(val, "[^;]+") do out[#out + 1] = id end
    end
    return out
end

-- The part a part sits under in the list By section: the one that has to
-- come off first (its table's requireUninstalled: a brake or a suspension under its tire), from
-- the game's own install tables, so modded cars group as their scripts say. A window sits under
-- the door it needs (the door's table asks for the window off first, but the window is in the
-- door); the engine bay's parts sit under the hood. nil: a top row.
local function parentOf(v, part)
    local id = part:getId()
    for _, key in ipairs({ "uninstall", "install" }) do
        local kv = part:getTable(key)
        if kv and kv.requireUninstalled then
            for _, q in ipairs(idsIn(kv.requireUninstalled)) do
                local qp = v:getPartById(q)
                if qp and q ~= id and not (part:getDoor() and qp:getWindow()) then return q end
            end
        end
    end
    if part:getWindow() then
        local kv = part:getTable("install")
        if kv and kv.requireInstalled then
            for _, q in ipairs(idsIn(kv.requireInstalled)) do
                local qp = v:getPartById(q)
                if qp and qp:getDoor() then return q end
            end
        end
    end
    local ok, area = pcall(function() return part:getArea() end)
    if ok and area == "Engine" and id ~= "EngineDoor" and v:getPartById("EngineDoor") then return "EngineDoor" end
    return nil
end

local function collectParts(v, chr)
    local list = {}
    for i = 0, v:getPartCount() - 1 do
        local part = v:getPartByIndex(i)
        local cat = part:getCategory() or "Other"
        if cat ~= "nodisplay" then
            local m = partModel(part, chr, v)
            m.order = i
            m.parent = parentOf(v, part)
            local door = part:getDoor()
            m.locked = door ~= nil and door:isLocked() and not door:isOpen()
            list[#list + 1] = m
        end
    end
    return list
end

-- The part models for the overview, rebuilt about four times a second (and
-- right after an action) instead of every frame: each one reads a handful of
-- Java getters and builds strings.
local PARTS_CACHE_MS = 250
local function cachedParts(s, v, chr)
    local c = s.partsCache
    local vid = v:getId()
    local t = now()
    if c and c.vid == vid and t - c.t < PARTS_CACHE_MS then return c.list end
    local list = collectParts(v, chr)
    local byId = {}
    for _, p in ipairs(list) do byId[p.id] = p end
    s.partsCache = { vid = vid, t = t, list = list }
    s.partById = byId
    return list
end

-- vanilla ISVehicleMechanics:recalculGeneralCondition (missing items count as 0)
local function overallCond(v)
    local total, n = 0, 0
    for i = 0, v:getPartCount() - 1 do
        local part = v:getPartByIndex(i)
        local c = part:getCondition()
        local it = part:getItemType()
        if it and not it:isEmpty() and not part:getInventoryItem() then c = 0 end
        total, n = total + c, n + 1
    end
    if n == 0 then return 0 end
    return math.floor(total / n + 0.5)
end

local function vehicleName(v)
    local sc = v:getScript()
    local carName = sc:getCarModelName() or sc:getName()
    local name = txt("IGUI_VehicleName" .. tostring(carName), tostring(carName))
    if string.find(sc:getName(), "Burnt") then
        local unburnt = (string.gsub(sc:getName(), "Burnt", ""))
        local n2 = txt("IGUI_VehicleName" .. unburnt, nil)
        if n2 then name = n2 end
        name = getText("IGUI_VehicleNameBurntCar", name)
    end
    return name
end
local function mechType(v)
    return txt("IGUI_VehicleType_" .. tostring(v:getScript():getMechanicType()), "")
end
-- (QA's visual bug B11, Nov 20 2026: "Tire - Regular (Standard Ve..." was cut, and the cut part repeats the tab's
-- "Standard". A name ending in "(<this car's type> ...)" drops that tail: "Tire - Regular" on a standard car.
-- A name for another type of car keeps it.)
function MT.forThisCar(name, v)
    if type(name) ~= "string" or not v then return name end
    local ok, mt = pcall(mechType, v)
    if not ok or type(mt) ~= "string" or mt == "" then return name end
    if string.sub(name, -1) ~= ")" then return name end
    local i = string.find(name, " (" .. mt, 1, true)
    if i and i > 1 then return string.sub(name, 1, i - 1) end
    return name
end

-- hoodRule true: the hood's rule for the engine-work rows (anyone may work on a car once a door or window is open).
-- Otherwise the ignition's: the key the car starts with (QA K1-11)
local function keyState(v, chr, hoodRule)
    local eng = v:getPartById("Engine")
    local ok, have = pcall(function() return chr:getInventory():haveThisKeyId(v:getKeyId()) end)
    if ok and have then return ZeD.tr("UI_ZeD_Veh_KeyOnYou"), "pos" end
    if not hoodRule then
        -- a key left in the ignition starts the car (the game's own words, without its full stop)
        local inIgn = false
        pcall(function() inIgn = v:isKeysInIgnition() == true end)
        if inIgn then
            local w = txt("Tooltip_Dashboard_KeysIgnition", "Key in ignition")
            return (string.gsub(w, "%.$", "")), "pos"
        end
    end
    if v:isHotwired() then return ZeD.tr("UI_ZeD_Veh_KeyHotwired"), "pos" end
    if hoodRule then
        if eng and VehicleUtils.RequiredKeyNotFound(eng, chr) then return ZeD.tr("UI_ZeD_Veh_NotFound"), "warn" end
        return ZeD.tr("UI_ZeD_Veh_KeyNotNeeded"), "pos"
    end
    -- Not needed only when the sandbox lets anyone start a car (VehicleEasyUse); else he has no key for it
    if SandboxVars and SandboxVars.VehicleEasyUse then return ZeD.tr("UI_ZeD_Veh_KeyNotNeeded"), "pos" end
    return ZeD.tr("UI_ZeD_Dash_PromptNoKey"), "warn"
end

-- ----------------------------------------------------------------------------
-- Items within reach (VehicleUtils.getItems = bags + nearby containers), cached
-- ----------------------------------------------------------------------------
local function itemsFor(s, chr)
    local t = now()
    if not s.items or t - (s.itemsAt or 0) > ITEMS_TTL_MS then
        local ok, byType, byTag = pcall(VehicleUtils.getItems, chr:getPlayerNum())
        s.items = { type = (ok and byType) or {}, tag = (ok and byTag) or {} }
        s.itemsAt = t
    end
    return s.items
end

local function locOf(item, chr)
    local c = item:getContainer()
    if not c then return "" end
    if c == chr:getInventory() then return getText("IGUI_Controller_Inventory") end
    if c:getType() == "floor" then return getText("ContextMenu_Floor") end
    local ci = c:getContainingItem()
    if ci then return ci:getName() end
    local ok, vp = pcall(function() return c:getVehiclePart() end)
    if ok and vp then return partName(vp:getId()) end
    -- a container renamed the game's way goes by its own name (ISInventoryPage) (L1-7)
    local custom = c.getCustomName and c:getCustomName()
    if custom then return custom end
    return txt("IGUI_ContainerTitle_" .. tostring(c:getType()), tostring(c:getType()))
end

-- ----------------------------------------------------------------------------
-- Verbs (mirror ISVehicleMechanics:doPartContextMenu)
-- ----------------------------------------------------------------------------
-- text keys (vanilla's where it has the word); vlabel() gives the word shown (buttons put it in sentence case)
local VERB_LABEL = {
    install = "IGUI_Install", uninstall = "IGUI_Uninstall", fix = "IGUI_Repair", inflate = "UI_ZeD_Veh_VInflate",
    deflate = "UI_ZeD_Veh_VDeflate", openWindow = "ContextMenu_Open_window", closeWindow = "ContextMenu_Close_window",
    smash = "UI_ZeD_Veh_VSmash", repairEngine = "IGUI_RepairEngine", takeParts = "UI_ZeD_Veh_VTakeParts",
    repairLightbar = "IGUI_Repair",
}
local function vlabel(id) return ZeD.tr(VERB_LABEL[id] or tostring(id)) end
-- what a verb does, for the folded row ("With a pump you could ...") and the footer's help line
local VERB_HINT = {
    install = "UI_ZeD_Veh_HintInstall", uninstall = "UI_ZeD_Veh_HintUninstall", fix = "UI_ZeD_Veh_HintFix",
    inflate = "UI_ZeD_Veh_HintInflate", deflate = "UI_ZeD_Veh_HintDeflate", openWindow = "UI_ZeD_Veh_HintOpenWindow",
    closeWindow = "UI_ZeD_Veh_HintCloseWindow", smash = "UI_ZeD_Veh_HintSmash", repairEngine = "UI_ZeD_Veh_HintRepairEngine",
    takeParts = "UI_ZeD_Veh_HintTakeParts", repairLightbar = "UI_ZeD_Veh_HintRepairLightbar",
}
local VERB_HELP = {
    install = "UI_ZeD_Veh_HelpInstall", uninstall = "UI_ZeD_Veh_HelpUninstall", fix = "UI_ZeD_Veh_HelpFix",
    inflate = "UI_ZeD_Veh_HelpInflate", deflate = "UI_ZeD_Veh_HelpDeflate", openWindow = "UI_ZeD_Veh_HelpOpenWindow",
    closeWindow = "UI_ZeD_Veh_HelpCloseWindow", smash = "UI_ZeD_Veh_HelpSmash", repairEngine = "UI_ZeD_Veh_HelpRepairEngine",
    -- (QA M1, Nov 26 2026: ZeD said the engine "loses condition"; the game sets it to 0 and says so in its own words)
    takeParts = "Tooltip_vehicle_TakeEnginePartsWarning", repairLightbar = "UI_ZeD_Veh_HelpRepairLightbar",
}
local DANGER = { smash = true, takeParts = true }
-- Which available verb is the call to action (accent fill), in this order
local PRIMARY_ORDER = { "install", "fix", "repairEngine", "repairLightbar", "inflate", "uninstall",
                        "openWindow", "closeWindow", "deflate" }

-- ----------------------------------------------------------------------------
-- EXTRAS -- the general way for another mod's support file (ModSupport/<mod id>.lua)
-- to follow that mod in this tab without touching this file. Nothing changes until an
-- extra is registered. An extra is a table:
--   verbs(part, chr, list)  -> the chosen part's verb ids (list: as built here): a new
--                              list, or nil to keep it
--   verb = { [id] = def }   the extra's own verbs: def.label, def.help, def.hint (text
--                              keys, through ZeD.tr), def.primary (the accent fill when it
--                              can be done), def.needs(part, chr, vehicle) -> { ok, rows,
--                              line, short } (rows: the card's NEEDS rows; line: the NEEDS
--                              line as it stands; short: the folded row's "With ..." words,
--                              "" for none), def.run(part, chr, vehicle)
--   partMenu(part, chr, ui) after the game's part menu is built from ui (X / right-click)
-- Every call goes through pcall; an error leaves the tab as built here.
-- Users today: ModSupport/MaskaradsSummerCar.lua (all three).
-- ----------------------------------------------------------------------------
MT.extras = MT.extras or {}
local EXTRA_VERBS = MT._extraVerbs or {}      -- kept across a hot reload of this file
MT._extraVerbs = EXTRA_VERBS
-- an extra's verbs into this file's word and order tables (they are rebuilt on a reload)
local function registerVerbs(def)
    for vid, vd in pairs(def.verb or {}) do
        EXTRA_VERBS[vid] = vd
        VERB_LABEL[vid], VERB_HINT[vid], VERB_HELP[vid] = vd.label, vd.hint, vd.help
        local have = false
        for _, p in ipairs(PRIMARY_ORDER) do if p == vid then have = true end end
        if vd.primary and not have then PRIMARY_ORDER[#PRIMARY_ORDER + 1] = vid end
    end
end
function MT.addExtras(id, def)
    for i, e in ipairs(MT.extras) do
        if e.id == id then table.remove(MT.extras, i); break end
    end
    def.id = id
    MT.extras[#MT.extras + 1] = def
    registerVerbs(def)
end
-- (a hot reload of this file: the extras registered before it keep their words and order)
for _, e in ipairs(MT.extras) do registerVerbs(e) end

local function verbsFor(part, chr)
    local verbs = {}
    local function add(id) verbs[#verbs + 1] = id end
    local item = part:getInventoryItem()
    local itype = part:getItemType()
    local hasType = itype ~= nil and not itype:isEmpty()
    if part:getId() == "Engine" then add("repairEngine") end
    if part:getId() == "lightbar" then add("repairLightbar") end
    if hasType and not item and part:getTable("install") then add("install") end
    if hasType and item then
        local fixes = FixingManager.getFixes(item)
        if part:getScriptPart():isRepairMechanic() and fixes and not fixes:isEmpty() then add("fix") end
    end
    if part:isContainer() and part:getContainerContentType() == "Air" and item then
        add("inflate"); add("deflate")
    end
    local window = part:getWindow()
    if window and (not hasType or item) and window:isOpenable() and not window:isDestroyed() and chr:getVehicle() then
        if window:isOpen() then add("closeWindow") else add("openWindow") end
    end
    if hasType and item and part:getTable("uninstall") then add("uninstall") end
    if window and (not hasType or item) and not window:isDestroyed() then add("smash") end
    if part:getId() == "Engine" then add("takeParts") end
    for _, e in ipairs(MT.extras) do
        if e.verbs then
            local okE, out = pcall(e.verbs, part, chr, verbs)
            if okE and type(out) == "table" then verbs = out end
        end
    end
    return verbs
end

-- Requirement rows for an install / uninstall table (vanilla doMenuTooltip)
local function tableNeeds(rows, part, chr, v, key, items)
    local kv = part:getTable(key)
    if not kv then return nil end
    if VehicleUtils.RequiredKeyNotFound(part, chr) then
        rows[#rows + 1] = { ok = false, label = getText("IGUI_ItemType_Key"), value = ZeD.tr("UI_ZeD_Veh_NotFound") }
    end
    if kv.items then
        for _, itemTable in ipairs(VehicleUtils.getItemScripts(kv.items)) do
            local names, seen, have, where = {}, {}, false, nil
            for _, thing in ipairs(itemTable.scripts) do
                if thing.script then
                    local nm = thing.script:getDisplayName()
                    if not seen[nm] then seen[nm] = true; names[#names + 1] = nm end
                    local owned = items.type[thing.script:getFullName()]
                    if owned and #owned > 0 and not have then have = true; where = locOf(owned[1], chr) end
                elseif thing.unknownType then names[#names + 1] = tostring(thing.unknownType)
                elseif thing.unknownTag then names[#names + 1] = tostring(thing.unknownTag) end
            end
            local label = names[1] or "?"
            if #names == 2 then label = ZeD.tr("UI_ZeD_Veh_OrOne", names[1], names[2])
            elseif #names > 2 then label = ZeD.tr("UI_ZeD_Veh_OrMore", names[1], #names - 1) end
            rows[#rows + 1] = { ok = have, label = label, value = have and "1/1" or "0/1", kicker = where }
        end
    end
    if kv.recipes and kv.recipes ~= "" then
        for _, r in ipairs(kv.recipes:split(";")) do
            local known = chr:isRecipeActuallyKnown(r)
            rows[#rows + 1] = { ok = known, label = getRecipeDisplayName(r), value = known and ZeD.tr("UI_ZeD_Veh_Known") or getText("IGUI_ItemCat_Unknown"), kicker = ZeD.tr("UI_ZeD_Veh_KRecipe") }
        end
    end
    -- (QA M10c, Nov 26 2026: only the uninstall test asks for this part off first; the game's InstallTest
    -- ignores it, so a brake goes on under its tire and the row only ever said no to a lit Install)
    if key == "uninstall" and kv.requireUninstalled then
        local o = v:getPartById(kv.requireUninstalled)
        if o then
            local on = o:getInventoryItem() ~= nil
            rows[#rows + 1] = { ok = not on, label = partName(o:getId()), value = on and getText("UI_WorkshopServerItemState_Installed") or ZeD.tr("UI_ZeD_Veh_Removed"), kicker = ZeD.tr("UI_ZeD_Veh_KMustBeOff") }
        end
    end
    if kv.requireEmpty then
        local seat = part:getContainerSeatNumber()
        local occupied = seat ~= nil and seat ~= -1 and v:isSeatOccupied(seat)
        local hasContent = round(part:getContainerContentAmount(), 3) > 0
        local cont = part:getItemContainer()
        local notEmpty = occupied or hasContent or (cont ~= nil and not cont:isEmpty())
        rows[#rows + 1] = { ok = not notEmpty, label = ZeD.tr("UI_ZeD_Veh_PartEmpty", partName(part:getId())),
                            value = notEmpty and (hasContent and ZeD.tr("UI_ZeD_Veh_AmountLeft", round(part:getContainerContentAmount(), 1)) or ZeD.tr("UI_ZeD_Veh_NotEmpty")) or getText("Fluid_Empty"),
                            kicker = ZeD.trBare("IGUI_CraftingWindow_IsEmpty") }
    end
    if key == "install" and kv.requireInstalled then
        for _, id in ipairs(kv.requireInstalled:split(";")) do
            local o = v:getPartById(id)
            local on = o ~= nil and o:getInventoryItem() ~= nil
            rows[#rows + 1] = { ok = on, label = partName(id), value = on and getText("UI_WorkshopServerItemState_Installed") or getText("IGUI_Missing"), kicker = ZeD.tr("UI_ZeD_Veh_KMustBeOn") }
        end
    end
    local perks = kv.skills
    if perks and perks ~= "" then
        for _, perk in ipairs(perks:split(";")) do
            local name, level = VehicleUtils.split(perk, ":")
            local need = tonumber(level) or 0
            local have = chr:getPerkLevel(Perks.FromString(name))
            rows[#rows + 1] = { ok = have >= need, soft = true, label = txt("IGUI_perks_" .. name, name),
                                value = tostring(have) .. " / " .. tostring(need), kicker = (have < need) and ZeD.tr("UI_optionscreen_recommended") or nil }
        end
    end
    local success, failure = VehicleUtils.calculateInstallationSuccess(perks, chr)
    return success, failure
end

local function toolRow(rows, label, item, chr)
    rows[#rows + 1] = { ok = item ~= nil, label = label, value = item and "1/1" or "0/1", kicker = item and locOf(item, chr) or nil }
end

-- Install candidates: every compatible item within reach, then the types you lack.
local function installPicks(part, chr, items)
    local picks = {}
    local itype = part:getItemType()
    if not itype then return picks end
    for i = 0, itype:size() - 1 do
        local full = itype:get(i)
        local owned = items.type[full]
        if owned and #owned > 0 then
            for _, it in ipairs(owned) do
                picks[#picks + 1] = { item = it, name = it:getDisplayName(), cond = it:getCondition(), loc = locOf(it, chr) }
            end
        end
    end
    table.sort(picks, function(a, b) return a.cond > b.cond end)
    for i = 0, itype:size() - 1 do
        local full = itype:get(i)
        local owned = items.type[full]
        if not owned or #owned == 0 then
            local sc = getItem(full)
            picks[#picks + 1] = { none = true, name = sc and getItemName(full) or tostring(full) }
        end
    end
    return picks
end

-- The spare picked, kept as the item itself (s.pickItem), not its row: the rows are rebuilt from items read again
-- every 700 ms and sorted by condition, so a spare brought near after the pick moved every row under it and Install
-- put on another one (QA M3, Nov 26 2026). With none picked yet, or the picked one gone from reach, the first row is
-- taken and kept. s.pick follows it for the pad's rows.
local function pickedInstall(s, picks)
    local first, firstI = nil, nil
    for i, pk in ipairs(picks) do
        if not pk.none then
            if s.pickItem ~= nil and pk.item == s.pickItem then s.pick = i; return pk end
            if not first then first, firstI = pk, i end
        end
    end
    if first then s.pick, s.pickItem = firstI, first.item end
    return first
end

-- Repair recipes (FixingManager), one row per fixing x fixer
local function fixRows(part, chr)
    local rows = {}
    local item = part:getInventoryItem()
    if not item then return rows end
    local fixes = FixingManager.getFixes(item)
    if not fixes then return rows end
    for fi = 0, fixes:size() - 1 do
        local fixing = fixes:get(fi)
        local global = fixing:getGlobalItem()
        local globalName, globalOk = nil, true
        if global then
            local gname = global:getFixerName()
            local full = fixing:getModule():getName() .. "." .. gname
            globalName = getItem(full) and getItemName(full) or gname
            if global:getNumberOfUse() > 1 then globalName = globalName .. " (" .. tostring(global:getNumberOfUse()) .. ")" end
            globalOk = fixing:haveGlobalItem(chr) ~= nil
        end
        for xi = 0, fixing:getFixers():size() - 1 do
            local fixer = fixing:getFixers():get(xi)
            local full = fixing:getModule():getName() .. "." .. fixer:getFixerName()
            local nm = getItem(full) and getItemName(full) or fixer:getFixerName()
            local n = fixer:getNumberOfUse()
            local label = (n > 1 and ZeD.tr("UI_ZeD_Veh_CountName", n, nm) or nm) .. (globalName and (" + " .. globalName) or "")
            local have = fixing:haveThisFixer(chr, fixer, item) ~= nil and fixing:countUses(chr, fixer, item) >= n
            local skillsOk, skillParts = true, {}
            local skills = fixer:getFixerSkills()
            if skills then
                for k = 0, skills:size() - 1 do
                    local sk = skills:get(k)
                    local perk = Perks.FromString(sk:getSkillName())
                    local lvl = chr:getPerkLevel(perk)
                    if lvl < sk:getSkillLevel() then skillsOk = false end
                    skillParts[#skillParts + 1] = PerkFactory.getPerk(perk):getName() .. " " .. tostring(sk:getSkillLevel())
                end
            end
            local repaired = math.ceil(FixingManager.getCondRepaired(item, chr, fixing, fixer))
            local success = math.ceil(100 - FixingManager.getChanceOfFail(item, chr, fixing, fixer))
            local meta = table.concat(skillParts, " " .. DOT .. " ")
            meta = (meta ~= "" and (meta .. " " .. DOT .. " ") or "") .. ZeD.tr("UI_ZeD_Veh_FixOutcome", tostring(repaired) .. "%", tostring(success) .. "%")
            local why = nil
            if not have then why = ZeD.tr("UI_ZeD_Veh_FixMissing", nm)
            elseif not globalOk then why = ZeD.tr("UI_ZeD_Veh_FixMissing", tostring(globalName))
            elseif not skillsOk then why = ZeD.tr("UI_ZeD_Veh_FixSkillLow") end
            rows[#rows + 1] = { fixingNum = fi, fixerNum = xi, label = label, meta = meta,
                                ok = have and globalOk and skillsOk, why = why }
        end
    end
    return rows
end

-- fixRows for the render paths, held for the same 300 ms as needsFor and
-- dropped by every action. Each call walks every fixer through the inventory.
local function cachedFixRows(s, part, chr)
    local key = part:getId()
    local c = s.fixCache
    local t = now()
    if c and c.key == key and t - c.t < 300 then return c.rows end
    local rows = fixRows(part, chr)
    s.fixCache = { key = key, t = t, rows = rows }
    return rows
end

-- Needs + availability for one verb. Returns { rows, chance = {s, f}, ok, blocker }
local needsCompute
local function needsFor(s, part, verb, chr, v)
    local key = tostring(part:getId()) .. ":" .. tostring(verb) .. ":" .. tostring(s.pick) .. ":" .. tostring(s.pickItem) .. ":" .. tostring(s.fixPick)
    s.needsCache = s.needsCache or {}
    local c = s.needsCache[key]
    local t = now()
    if c and t - c.t < 300 then return c.v end
    local val = needsCompute(s, part, verb, chr, v)
    s.needsCache[key] = { t = t, v = val }
    return val
end
needsCompute = function(s, part, verb, chr, v)
    local rows, items = {}, itemsFor(s, chr)
    local success, failure = 100, 0
    local ok = true
    local line, short = nil, nil   -- an extra's own NEEDS line and folded-row words
    local engLevel = v:getScript():getEngineRepairLevel()
    if verb == "install" or verb == "uninstall" then
        if verb == "install" then
            local picks = installPicks(part, chr, items)
            local pick = pickedInstall(s, picks)
            if pick and not pick.none then
                rows[#rows + 1] = { ok = true, label = pick.name, value = tostring(pick.cond) .. "%", kicker = pick.loc }
            else
                rows[#rows + 1] = { ok = false, label = ZeD.tr("UI_ZeD_Veh_NeedPart"), what = ZeD.tr("UI_ZeD_Veh_NeedPartWhat"),
                                    value = ZeD.tr("IGUI_None"), kicker = ZeD.tr("UI_ZeD_Veh_KWithinReach") }
                ok = false
            end
        end
        local sc, fc = tableNeeds(rows, part, chr, v, verb, items)
        success, failure = sc or 100, fc or 0
        -- (QA M10a, Nov 26 2026: the battery's uninstall test also wants the engine off (Vehicles.UninstallTest.Battery);
        -- its tooltip never says so, and the card read "Uninstall is not possible right now." with no reason)
        local ukv = (verb == "uninstall") and part:getTable("uninstall") or nil
        if ukv and type(ukv.test) == "string" and string.find(ukv.test, "Battery", 1, true) then
            local running = false
            pcall(function() running = v:isEngineStarted() or v:isEngineRunning() end)
            if running then
                rows[#rows + 1] = { ok = false, label = partName("Engine"), value = getText("UI_On"), kicker = ZeD.tr("UI_ZeD_Veh_KMustBeOff") }
            end
        end
        local can = false
        pcall(function()
            if verb == "install" then can = v:canInstallPart(chr, part) else can = v:canUninstallPart(chr, part) end
        end)
        ok = ok and can
    elseif verb == "inflate" then
        local pump = nil
        pcall(function() pump = chr:getInventory():getFirstTypeRecurse("TirePump") end)
        toolRow(rows, getItemName("Base.TirePump") or "Tire Pump", pump, chr)
        local amt, cap = part:getContainerContentAmount(), part:getContainerCapacity()
        local roomy = amt < cap + 5
        rows[#rows + 1] = { ok = roomy, label = ZeD.tr("UI_ZeD_Veh_BelowPsi", cap + 5), value = ZeD.tr("UI_ZeD_Veh_Psi", math.floor(amt + 0.5)) }
        ok = pump ~= nil and roomy
    elseif verb == "deflate" then
        local amt = part:getContainerContentAmount()
        rows[#rows + 1] = { ok = amt > 0, label = ZeD.tr("UI_ZeD_Veh_AirInTire"), value = ZeD.tr("UI_ZeD_Veh_Psi", math.floor(amt + 0.5)) }
        ok = amt > 0
    elseif verb == "repairEngine" or verb == "takeParts" then
        local wrench = ISVehicleMechanics:getWrench(chr)
        local lvl = mechLevel(chr)
        if verb == "repairEngine" then
            rows[#rows + 1] = { ok = part:getCondition() < 100, label = ZeD.tr("UI_ZeD_Veh_EngineBelow", "100%"), value = tostring(part:getCondition()) .. "%" }
        else
            rows[#rows + 1] = { ok = part:getCondition() > 10, label = ZeD.tr("UI_ZeD_Veh_EngineAbove", "10%"), value = tostring(part:getCondition()) .. "%" }
        end
        rows[#rows + 1] = { ok = lvl >= engLevel, label = txt("IGUI_perks_Mechanics", "Mechanics"), value = tostring(lvl) .. " / " .. tostring(engLevel), kicker = ZeD.tr("UI_ZeD_Veh_KRequired") }
        toolRow(rows, getItemName("Base.Wrench") or "Wrench", wrench, chr)
        local partsOk = true
        if verb == "repairEngine" then
            local n = chr:getInventory():getNumberOfItem("EngineParts", false, true)
            partsOk = n > 0
            rows[#rows + 1] = { ok = partsOk, label = getItemName("Base.EngineParts") or "Spare Engine Parts", value = tostring(n) }
        end
        local keyMissing = VehicleUtils.RequiredKeyNotFound(part, chr)
        local ks = keyState(v, chr, true)   -- (the hood's rule here, QA K1-11)
        rows[#rows + 1] = { ok = not keyMissing, label = getText("IGUI_ItemType_Key"), value = keyMissing and ZeD.tr("UI_ZeD_Veh_NotFound") or ks }
        for _, r in ipairs(rows) do if not r.ok and not r.soft then ok = false end end
        -- (QA M1, Nov 26 2026: the game's own warning, not a softer one)
        if verb == "takeParts" then rows[#rows + 1] = { ok = false, soft = true, label = getText("Tooltip_vehicle_TakeEnginePartsWarning"), value = "" } end
    elseif verb == "repairLightbar" then
        local lvl = mechLevel(chr)
        local sd = ISVehicleMechanics:getScrewdriver(chr)
        local hasBar = false
        pcall(function() hasBar = chr:getInventory():containsTag(ItemTag.LIGHTBAR) end)
        rows[#rows + 1] = { ok = part:getCondition() < 100, label = ZeD.tr("UI_ZeD_Veh_Below", "100%"), value = tostring(part:getCondition()) .. "%" }
        rows[#rows + 1] = { ok = lvl >= engLevel, label = txt("IGUI_perks_Mechanics", "Mechanics"), value = tostring(lvl) .. " / " .. tostring(engLevel), kicker = ZeD.tr("UI_ZeD_Veh_KRequired") }
        toolRow(rows, getItemName("Base.Screwdriver") or "Screwdriver", sd, chr)
        rows[#rows + 1] = { ok = hasBar, label = partName("lightbar"), value = hasBar and "1/1" or "0/1" }
        for _, r in ipairs(rows) do if not r.ok and not r.soft then ok = false end end
    elseif verb == "fix" then
        local fr = cachedFixRows(s, part, chr)
        local any = false
        for _, r in ipairs(fr) do if r.ok then any = true end end
        ok = any
        if not any then rows[#rows + 1] = { ok = false, label = ZeD.tr("UI_ZeD_Veh_NoRecipeMaterials"), what = ZeD.tr("UI_ZeD_Veh_NeedFixWhat"), value = "" } end
    elseif EXTRA_VERBS[verb] then
        local okX, r = pcall(EXTRA_VERBS[verb].needs, part, chr, v)
        if okX and type(r) == "table" then
            if type(r.rows) == "table" then rows = r.rows end
            ok, line, short = r.ok == true, r.line, r.short
        else
            rows[#rows + 1] = { ok = false, label = ZeD.tr("UI_ZeD_Veh_RightConditions"), value = "" }
            ok = false
        end
    else
        rows[#rows + 1] = { ok = true, label = ZeD.tr("UI_ZeD_Veh_NothingNeeded"), value = "" }
    end
    -- a server's vehicle claims: the server refuses this at the end of the wait, so it grays here first (ZeD_Extras.lua)
    local claimed = (verb == "uninstall" or verb == "takeParts") and ZeD.Extras and ZeD.Extras.partsBlock(v) or nil
    if claimed then
        rows[#rows + 1] = { ok = false, label = ZeD.tr("UI_ZeD_Ex_ClaimedBy", claimed), value = "" }
        ok = false
    end
    local blocker = nil
    for _, r in ipairs(rows) do if not r.ok and not r.soft then blocker = r; break end end
    return { rows = rows, chance = { success, failure }, ok = ok, blocker = blocker, line = line, short = short }
end

-- ----------------------------------------------------------------------------
-- Running verbs (vanilla handlers do the walking, equipping and queueing)
-- ----------------------------------------------------------------------------
-- the player's queue of timed actions (nil when the game has none to give)
local function gameQueue(chr)
    local ok, q = pcall(function() return ISTimedActionQueue.getTimedActionQueue(chr) end)
    if ok and q and q.queue then return q end
    return nil
end
local function inQueue(q, a)
    for i = 1, #q.queue do if q.queue[i] == a then return true end end
    return false
end

-- The whole chain a verb queued (the walk, the item moves, the equip, the hood, the job itself) is kept on the
-- state (s.queued) and looked up in the game's queue, as the Craft tab's craftBusy does: the busy test read only the
-- head of the queue and only an action with a job name, so a second press during the walk, or on a repair (which
-- names no vehicle), queued the whole chain again: two repairs, two sets of materials, a hood left open (QA M2,
-- Nov 26 2026). The list empties itself once none of it is left.
local function chainBusy(s, chr)
    local list = s and s.queued
    if not list then return false end
    local q = gameQueue(chr)
    local busy = false
    if q then
        for i = 1, #list do
            if inQueue(q, list[i]) then busy = true; break end
        end
    end
    if not busy then s.queued, s.queuedLabel, s.queuedV, s.queuedPart = nil, nil, nil, nil end
    return busy
end

-- The band's Cancel: the game's own stop (the running action stops, the queue empties), then anything of the
-- chain still there taken out. The band showed only once the job itself ran, so a Cancel pressed as the walk
-- handed over found no band and the uninstall still happened (QA M9, Nov 26 2026).
local function cancelChain(s, chr)
    pcall(function() ISTimedActionQueue.clear(chr) end)
    local q = gameQueue(chr)
    local list = s.queued or {}
    if q then
        for i = #list, 1, -1 do
            local a = list[i]
            if inQueue(q, a) then
                pcall(function() q:removeFromQueue(a) end)
                pcall(function() a:forceCancel() end)
            end
        end
    end
    s.queued, s.queuedLabel, s.queuedV, s.queuedPart = nil, nil, nil, nil
end
MT.cancelChain = cancelChain

-- Paused (game speed 0), as the game's part menu asks (ISVehicleMechanics:doPartContextMenu): nothing is
-- queued and the player is told why. The tab's verbs, the question's Yes and the right-click queued at any
-- speed and said nothing (QA M11, M12, Nov 26 2026).
local function say(chr, text)
    if HaloTextHelper and HaloTextHelper.addBadText then pcall(HaloTextHelper.addBadText, chr, text) end
end
local function refusePaused(chr)
    local ok, spd = pcall(function() return UIManager.getSpeedControls():getCurrentGameSpeed() end)
    if not (ok and spd == 0) then return false end
    say(chr, ZeD.tr("UI_ZeD_Char_PausedLook"))
    return true
end

-- the verbs that work on the item the part holds
local NEEDS_ITEM = { uninstall = true, fix = true, inflate = true, deflate = true }

-- one console line for a press the tab turns down, every time, with the part and the test that held it (QA's
-- M3 hunt, Nov 26 2026: a logOnce line printed once and hid the next refusals)
local function vehNote(verb, part, why)
    local pid = "?"
    pcall(function() pid = tostring(part and part:getId()) end)
    print("[ZeD] Vehicle tab: " .. tostring(verb) .. " on " .. pid .. ": " .. tostring(why))
end

local function runVerb(s, verb, part, chr)
    if not part then return end
    if chainBusy(s, chr) then vehNote(verb, part, "refused (chainBusy, " .. tostring(s.queued and #s.queued) .. " kept)"); return end   -- (asked at the press: two presses in one frame saw the same idle card. M2)
    if refusePaused(chr) then vehNote(verb, part, "refused (paused)"); return end
    -- the parts are read four times a second, so a press can land on a part already taken off; the game's start
    -- check then dropped the chain and said nothing (QA M13, Nov 26 2026)
    if NEEDS_ITEM[verb] and part:getInventoryItem() == nil then
        say(chr, ZeD.tr("UI_ZeD_Veh_PartGone", partName(part:getId())))
        s.needsCache, s.fixCache, s.partsCache = nil, nil, nil
        return
    end
    -- what the queue held before, so the chain this press adds can be kept (M2)
    local q0 = gameQueue(chr)
    local before = {}
    if q0 then for i = 1, #q0.queue do before[q0.queue[i]] = true end end
    if verb == "install" then
        local picks = installPicks(part, chr, itemsFor(s, chr))
        local pick = pickedInstall(s, picks)   -- (the item picked, not its row: M3)
        if pick and pick.item then ISVehiclePartMenu.onInstallPart(chr, part, pick.item)
        else vehNote(verb, part, "no spare to put on (pick " .. tostring(s.pick) .. ")") end
    elseif verb == "uninstall" then ISVehiclePartMenu.onUninstallPart(chr, part)
    elseif verb == "inflate" then ISVehiclePartMenu.onInflateTire(chr, part)
    elseif verb == "deflate" then ISVehiclePartMenu.onDeflateTire(chr, part)
    elseif verb == "openWindow" then ISVehiclePartMenu.onOpenCloseWindow(chr, part, true)
    elseif verb == "closeWindow" then ISVehiclePartMenu.onOpenCloseWindow(chr, part, false)
    elseif verb == "smash" then ISVehiclePartMenu.onSmashWindow(chr, part)
    elseif verb == "repairEngine" then ISVehicleMechanics.onRepairEngine(chr, part)
    elseif verb == "takeParts" then ISVehicleMechanics.onTakeEngineParts(chr, part)
    elseif verb == "repairLightbar" then ISVehicleMechanics.onRepairLightbar(chr, part)
    elseif verb == "fix" then
        local r = fixRows(part, chr)[s.fixPick]
        if r and r.ok then
            ISInventoryPaneContextMenu.onFix(part:getInventoryItem(), chr:getPlayerNum(), r.fixingNum, r.fixerNum, part)
        end
    elseif EXTRA_VERBS[verb] then
        local okR, err = pcall(EXTRA_VERBS[verb].run, part, chr, part:getVehicle())
        if not okR then print("[ZeD] Vehicle tab: verb " .. tostring(verb) .. ": " .. tostring(err)) end
    end
    local q = gameQueue(chr)
    if q then
        local list = {}
        for i = 1, #q.queue do
            local a = q.queue[i]
            if not before[a] then list[#list + 1] = a end
        end
        if #list > 0 then
            s.queued, s.queuedLabel, s.queuedV, s.queuedPart = list, vlabel(verb), part:getVehicle(), part:getId()
        else
            vehNote(verb, part, "queued nothing")
        end
    end
    s.items = nil   -- tools and parts move; re-read next frame
    s.needsCache, s.fixCache, s.partsCache = nil, nil, nil
end

-- Vanilla's own part menu, rendered by ZeD's context-menu hook (X / right-click)
-- at: the screen point to open it at (the pad's focused row), else the pointer; win: where the pad goes back
-- (QA M11, Nov 26 2026: on a pad the menu opened at 0,0 under a hidden pointer, and its origin was the hidden
-- mechanics window, so B left the pad on nothing. Now it opens at the row and B hands the pad back to the window.)
local function partContextMenu(part, chr, win, atX, atY)
    if refusePaused(chr) then return end   -- (the game's menu returns at speed 0 and says nothing: here it says why. M11)
    local ui = getPlayerMechanicsUI(chr:getPlayerNum())
    if not ui or not part then return end
    ui.vehicle = part:getVehicle()
    ui.chr = chr
    local sx, sy = atX or getMouseX(), atY or getMouseY()
    local ax, ay = sx - ui:getAbsoluteX(), sy - ui:getAbsoluteY()
    pcall(ui.doPartContextMenu, ui, part, ax, ay)
    local ctx = ui.context
    if win and win._mech then win._mech.partMenu = ctx end   -- (B shuts it first: closePartMenu, M11)
    -- (QA's M11 hunt, Nov 26 2026: the shown menu read 0,0 though its anchor was the row's point; what the game
    -- built, to the console)
    pcall(function()
        local vis, nopt = "?", "?"
        if ctx then
            pcall(function() vis = tostring(ctx:getIsVisible()) end)
            pcall(function() nopt = tostring(ctx.numOptions or (ctx.options and #ctx.options)) end)
        end
        print("[ZeD] Vehicle tab: part menu at " .. tostring(sx) .. "," .. tostring(sy) .. " (given " .. tostring(atX) .. ","
            .. tostring(atY) .. "): menu " .. tostring(ctx ~= nil) .. ", shown " .. vis .. ", options " .. nopt)
    end)
    local pn = chr:getPlayerNum()
    if ctx and win and JoypadState and JoypadState.players and JoypadState.players[pn + 1] then
        local shown = false
        pcall(function() shown = ctx:getIsVisible() end)
        if shown then
            ctx.origin = win
            ctx.mouseOver = 1
            setJoypadFocus(pn, ctx)
        end
    end
    -- (a mod's support file follows that mod's own options in the menu just built: EXTRAS)
    for _, e in ipairs(MT.extras) do
        if e.partMenu then pcall(e.partMenu, part, chr, ui) end
    end
end

-- ----------------------------------------------------------------------------
-- Zone stamping: one list feeds mouse clicks and the gamepad ring. The controller's
-- mark is not painted here: each element asks ZeD.Focus.mark for it while it draws
-- (markAt, or the focus opts a library control takes), under its words.
-- ----------------------------------------------------------------------------
local function stamp(s, id, x, y, w, h, fn, opts)
    local z = { id = id, x = x, y = y, w = w, h = h, fn = fn }
    if opts then for k, val in pairs(opts) do z[k] = val end end
    s.zones[#s.zones + 1] = z
    s.byId[id] = z
    return z
end

-- The id of the zone the controller has focused, while its mark shows (the focused
-- window, pad in use); nil otherwise
local function gpFocusedId(win)
    local Focus = ZeD.Input and ZeD.Input.Focus
    if not (Focus and Focus.liveZone) then return nil end
    local zone = Focus.liveZone(win)
    if not zone or zone.zone ~= "worldTabContent" then return nil end
    local el = Focus.getFocusedElement and Focus.getFocusedElement(win)
    local id = el and el.id
    if id and id:sub(1, 5) == "mech:" then return id end
    return nil
end

-- the mark opts for a control that takes them (one shared table: mark reads it at once)
local _mfo = { zone = "worldTabContent" }
local function focusFor(s, id)
    if id ~= nil and s.gpId == id then
        _mfo.win, _mfo.solid = s.win, false
        return _mfo
    end
    return nil
end

-- the mark for an element drawn here, after its fill and before its words; true when
-- its words must switch to T.textOnFocus
local function markAt(s, panel, id, x, y, w, h, solid)
    if id == nil or s.gpId ~= id then return false end
    _mfo.win, _mfo.solid = s.win, solid and true or false
    return ZeD.Focus.mark(panel, x, y, w, h, _mfo) and true or false
end

-- opts for the library parts that take the controller's focus themselves (reused each frame)
local _cancelOpts = {}                 -- the progress band's Cancel
-- the vehicles' tab strip (ZeD.SubTabs, RadioTab.lua): its opts; the mark goes on the tab the controller is on
local _stripFocus = { s = nil }
local _stripOpts = { focusOf = function(i) local s = _stripFocus.s; return s and focusFor(s, "mech:veh:" .. i) or nil end }

-- A car's number among cars of its name: given the first time it is seen and kept for the session, so
-- "Chevalier Nyala (1)" stays with its car. (QA M13b, Nov 26 2026: the number was the tab's place in a list
-- sorted by distance, and two Nyalas swapped names as he walked from one to the other.)
local VEH_NUM = MT._vehNum or { byId = {}, top = {} }   -- (kept across a hot reload of this file)
MT._vehNum = VEH_NUM
function MT.vehicleNumber(name, id)
    local e = VEH_NUM.byId[id]
    if e and e.name == name then return e.num end
    local n = (VEH_NUM.top[name] or 0) + 1
    VEH_NUM.top[name] = n
    VEH_NUM.byId[id] = { name = name, num = n }
    return n
end

local _vehTabItems = {}
--- The vehicles' tabs: each one's name (two of the same name carry their own number, "Chevalier Nyala (2)");
--- the help line names it and its type.
-- list is s.vehicles: entries { vehicle = v, id, dist } from MT.buildVehicles, not the vehicles themselves
function MT.vehicleTabItems(list)
    local seen = {}
    for i, e in ipairs(list or {}) do
        local n = vehicleName(e.vehicle)
        seen[n] = (seen[n] or 0) + 1
    end
    for i, e in ipairs(list or {}) do
        local v = e.vehicle
        local n = vehicleName(v)
        local it = _vehTabItems[i] or {}
        _vehTabItems[i] = it
        it.label = (seen[n] > 1) and (n .. " (" .. tostring(MT.vehicleNumber(n, e.id or v:getId())) .. ")") or n
        local ty = mechType(v)
        it.help = (ty ~= "") and (n .. " | " .. ty) or n
    end
    for i = #_vehTabItems, #(list or {}) + 1, -1 do _vehTabItems[i] = nil end
    return _vehTabItems
end

-- a vehicle tab's press: that vehicle, its list from the top and no part chosen (the pager's old reset)
local _vehTabFns = {}
function MT.vehicleTabFn(s, i)
    local by = _vehTabFns[s]
    if not by then by = {}; _vehTabFns[s] = by end
    local fn = by[i]
    if not fn then
        fn = function()
            if s.idx == i then return end
            s.idx = i
            s.scrollY, s.cardScroll, s.card, s.confirm = 0, 0, nil, nil
        end
        by[i] = fn
    end
    return fn
end

-- ----------------------------------------------------------------------------
-- Car figure
-- ----------------------------------------------------------------------------
-- forward-declared together: drawFigure and the card icon both use them (Kahlua captures at creation)
local overlayInfo, partImgs, tex
local TEX = {}
tex = function(name)
    local t = TEX[name]
    if t == nil then
        -- zm_: vanilla packs share the base names. Nearest filtering (3, as ZeD_PixelParts' textures): the
        -- figures are pixel art and blur when filtered linearly
        local path = "media/textures/ZeD/mech/zm_" .. name .. ".png"
        t = (Texture and Texture.getSharedTexture and Texture.getSharedTexture(path, 3)) or getTexture(path) or false
        TEX[name] = t
    end
    return t or nil
end

overlayInfo = function(v)
    local OV = ISCarMechanicsOverlay
    if not OV or not OV.CarList then return nil, nil end
    local name = v:getScriptName()
    local sc = v:getScript()
    if sc and sc:getCarMechanicsOverlay() then name = sc:getCarMechanicsOverlay() end
    local props = OV.CarList[name]
    return props and props.imgPrefix or nil, props
end
partImgs = function(props, id)
    local OV = ISCarMechanicsOverlay
    local pp = (props and props.PartList and props.PartList[id]) or (OV and OV.PartList and OV.PartList[id])
    if not pp or not pp.img then return nil end
    if pp.multipleImg then return pp.img end
    return { pp.img }
end

local function drawFigure(panel, s, fx, fy, fw, fh, v, parts, hlId, unknown, workId)
    local T = ZeD.T
    local dim = T.textDim
    s.figZones = {}
    -- (no grid box behind the car any more: the director wants the parts with no frame) (Graphic cleanup, Nov 22 2026)
    local prefix, props = overlayInfo(v)
    local F = ZeD.MechFigs
    local U = prefix and F and F.unions and F.unions[prefix]
    if not U then return fh end
    -- (Car parts to the sides, Nov 22 2026) every part now stands beside the car, so each figure is only the
    -- car's height. One zoom for every body shape, fitted to the biggest figure (so a trailer and a car keep
    -- their sizes and the summary below does not jump between vehicles), in whole screen pixels per art
    -- pixel (1080p and 1280x800 1x, 4K at 1.75 2x) so the pixel art stays even, never below 1x: a box too
    -- small for 1x (a narrowed drawer) shows the figure at 1x, centred and clipped by the column. The box is
    -- then only as tall as that figure: the rest goes to the summary under it.
    if not F.maxW then
        local mw, mh = 1, 1
        for _, u in pairs(F.unions) do
            if u.w > mw then mw = u.w end
            if u.h > mh then mh = u.h end
        end
        F.maxW, F.maxH = mw, mh
    end
    local sc = math.min(fw / F.maxW, fh / F.maxH)
    sc = math.max(1, math.floor(sc + 1e-6))   -- a whole zoom, at least 1 (QA, Nov 22 2026)
    local boxH = F.maxH * sc
    local ox = fx + math.floor((fw - U.w * sc) / 2)
    local oy = fy + math.floor((boxH - U.h * sc) / 2)
    local function rectOf(key)
        local L = F.layers[key]
        if not L then return nil end
        return ox + (L.x - U.x) * sc, oy + (L.y - U.y) * sc, L.w * sc, L.h * sc
    end
    -- the figure's alphas by theme (Car diagram per theme, Nov 22 2026; the director: "on a light screen or on the
    -- light theme, the vehicle diagram looks muddy"): the theme's mechFig token (Tokens.lua), Dark's numbers when a
    -- theme sets none. lift takes a status color that far toward white for the fill (Light's are dark text colors);
    -- each lifted color is made once and kept.
    local look = T.mechFig
    if not look then
        F._look = F._look or { baseA = 0.45, washA = 0.22, partA = 0.70, wearA = 0.90, lift = 0 }
        look = F._look
    end
    local function fill(c)
        local k = look.lift or 0
        if k <= 0 then return c end
        F._lifted = F._lifted or {}
        local e = F._lifted[c]
        if not e or e.k ~= k then
            e = { k = k, col = ZeD.colorBlend(c, { r = 1, g = 1, b = 1 }, k) }
            F._lifted[c] = e
        end
        return e.col
    end
    local bt = tex(prefix .. "base")
    local bx, by, bw, bh = rectOf(prefix .. "base")
    if bt and bx then
        panel:drawTextureScaledAspect(bt, bx, by, bw, bh, look.baseA, dim.r, dim.g, dim.b)
        -- (Car parts to the sides, Nov 22 2026; the director: the parts with no condition of their own, "the frame,
        -- the roof, tow hitch, etc., could those take on the average condition color of the vehicle? Very light
        -- alpha on that.") They are all in the base layer: a light wash of the vehicle's overall condition color
        -- (the summary's Overall, the parts' own bands), so the car reads as a whole. No wear on it; none on an
        -- uninspected car, whose condition is not known yet.
        if not unknown then
            local oc = fill(statusColor(T, overallCond(v)))
            panel:drawTextureScaledAspect(bt, bx, by, bw, bh, look.washA, oc.r, oc.g, oc.b)
        end
    end
    local pulse = 0.35 + 0.5 * (0.5 + 0.5 * math.sin(now() / 260))
    local ac = T.accent
    for _, p in ipairs(parts) do
        local imgs = partImgs(props, p.id)
        if imgs then
            local x0, y0, x1, y1
            for _, img in ipairs(imgs) do
                local key = prefix .. img
                local lx, ly, lw, lh = rectOf(key)
                if lx then
                    local rimOnly = unknown or p.missing or p.smashed
                    local t = tex(key .. (rimOnly and "_rim" or ""))
                    if t then
                        local c, a
                        if unknown then c, a = dim, 0.55
                        elseif rimOnly then c, a = T.danger, pulse
                        -- (the director, Nov 22 2026: the parts were "shockingly bright compared to other UI elements";
                        -- the condition color now sits at the lit part's own strength, not near full)
                        else c, a = fill(statusColor(T, p.cond)), look.partA end
                        panel:drawTextureScaledAspect(t, lx, ly, lw, lh, a, c.r, c.g, c.b)
                        -- (Car wear, Nov 22 2026; the director: a red part "would have a lot of rust spots all over
                        -- it", a yellow one "a little bit of rust or a scratch", green "pristine") the part's wear,
                        -- baked to its shape, over the tint and untinted (the rust keeps its own colour). The band is
                        -- statusColor's: four or five segments lit is green (none), two or three yellow (light),
                        -- one or none red (heavy). A missing, smashed or uninspected part keeps its rim alone.
                        if not rimOnly then
                            local lit = ZeD.Atoms.statusSegsLit((p.cond or 0) / 100)
                            local wt = (lit <= 1 and tex(key .. "_wear2")) or (lit <= 3 and tex(key .. "_wear1")) or nil
                            if wt then panel:drawTextureScaledAspect(wt, lx, ly, lw, lh, look.wearA, 1, 1, 1) end
                        end
                        if hlId == p.id or workId == p.id then
                            local full = tex(key) or t
                            panel:drawTextureScaledAspect(full, lx, ly, lw, lh, 0.75, ac.r, ac.g, ac.b)
                            -- and its outline in the text colour, so the lit part never rests on
                            -- colour alone (the colourblind modes)
                            local rim = tex(key .. "_rim")
                            if rim then
                                local oc = T.text
                                panel:drawTextureScaledAspect(rim, lx, ly, lw, lh, 1, oc.r, oc.g, oc.b)
                            end
                        end
                    end
                    x0 = x0 and math.min(x0, lx) or lx
                    y0 = y0 and math.min(y0, ly) or ly
                    x1 = x1 and math.max(x1, lx + lw) or (lx + lw)
                    y1 = y1 and math.max(y1, ly + lh) or (ly + lh)
                end
            end
            if x0 then
                local g = T.px(2)
                local z = { id = p.id, x = x0 - g, y = y0 - g, w = (x1 - x0) + g * 2, h = (y1 - y0) + g * 2 }
                s.figZones[#s.figZones + 1] = z
                -- the lit part also gets a box in the text colour around it: a thin part (the
                -- muffler) lit only by its own outline reads as its neighbours in greyscale
                if hlId == p.id then ZeD.Atoms.frame(panel, z.x, z.y, z.w, z.h, T.text) end
            end
        end
    end
    return boxH   -- the height the figure took (Car parts to the sides, Nov 22 2026)
end

local function figurePartAt(s, x, y)
    local best, bestA = nil, nil
    for _, z in ipairs(s.figZones or {}) do
        if hit(z, x, y) then
            local a = z.w * z.h
            if not bestA or a < bestA then best, bestA = z.id, a end
        end
    end
    return best
end

-- ----------------------------------------------------------------------------
-- Shared pieces
-- ----------------------------------------------------------------------------
local function drawLabelValue(panel, x, y, w, label, value)
    local T = ZeD.T
    local lc, tc = T.textSec, T.text
    local A = ZeD.Atoms
    local lt = A.truncateText(cased(label), T.fontF1, w)
    panel:drawText(lt, x, y, lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)
    -- the value is cut to the room after its label, never drawn over it
    local room = w - ZeD.TM:MeasureStringX(T.fontF1, lt) - T.px(8)
    if room > 0 then A.drawTextRight(panel, A.truncateText(value, T.fontF3, room), x + w, y, T.fontF3, tc) end
    return math.max(T.fontF1H, T.fontF3H)
end

-- w: the line's width; the words are cut with "..." to the room after the dot
-- (uncut, a long line ran off the card's right edge)
local function dotLine(panel, x, y, w, color, text, font)
    local T = ZeD.T
    font = font or T.fontF2
    local fh = ZeD.TM:getFontHeight(font)
    local d = T.px(7)
    ZeD.Atoms.drawStatusDot(panel, x, y + math.floor((fh - d) / 2), color, d)
    local tc = T.text
    local tx = x + d + T.px(6)
    text = ZeD.Atoms.truncateText(text, font, math.max(0, x + w - tx))
    panel:drawText(text, tx, y, tc.r, tc.g, tc.b, tc.a or 1, font)
    return fh
end

-- A condition bar for a list row: the framed strip at the compact height, centred
-- on cy, a status bar's five segments (green over 60, amber over 20, red below); its help
-- line "Condition 64%"
local function miniBar(panel, x, cy, w, pct)
    local A = ZeD.Atoms
    local h = A.fillBarCompactH()
    A.drawFillBar(panel, x, cy - math.floor(h / 2), w, math.max(0, math.min(1, pct / 100)), true, nil, h,
        ZeD.tr("IGUI_invpanel_Condition"))
end

-- The timed action now running on this vehicle (nil when idle)
local function activeAction(chr, v)
    local q = gameQueue(chr)
    if not q then return nil end
    -- the running one is q.current (42.22: queue[1] can still hold the one just finished); a current the queue
    -- no longer holds is a stale one left by a cleared queue (QA M9, Nov 26 2026)
    local a = q.current
    if not (a and inQueue(q, a)) then a = q.queue[1] end
    if a and a.jobType and a.jobType ~= "" then
        if (a.vehicle == v) or (a.part and a.part.getVehicle and a.part:getVehicle() == v) then return a end
    end
    return nil
end

-- Progress band for the running vehicle action, then the success / failure flash
local function progressBand(panel, win, s, x, y, w, v, chr)
    local a = activeAction(chr, v)
    -- (the chain the tab queued shows the band from its first step, the walk, with Cancel on it: QA M2, M9, Nov 26 2026)
    local chain = (a == nil) and chainBusy(s, chr) and s.queuedV == v
    if a or chain then
        do
            local pct = 0
            if a then pcall(function() pct = a:getJobDelta() end) end
            local rect = {}
            _cancelOpts.focus = focusFor(s, "mech:cancel")   -- Cancel's mark, drawn under its icon
            -- (QA's visual noise audit 18, Nov 20 2026: the action bar over the head already shows this job; the
            -- band keeps its bar and loses its percent. Bug B11: no "(Standard Vehicle)" on a standard car.)
            _cancelOpts.noPercent = true
            local label = a and cased(MT.forThisCar(a.jobType, v))
                          or (cased(s.queuedLabel or "") .. " " .. DOT .. " " .. cased(partName(s.queuedPart)))
            local h = ZeD.Atoms.drawProgressBand(panel, x, y, w, "active", label, pct, nil, rect, false, _cancelOpts)
            if rect.w then
                stamp(s, "mech:cancel", rect.x, rect.y, rect.w, rect.h, function() cancelChain(s, chr) end)
            end
            if a then s.working = a.part and a.part.getId and a.part:getId() or nil else s.working = s.queuedPart end
            return h
        end
    end
    s.working = nil
    local f = s.flash
    if f and now() < f.untilMs then
        return ZeD.Atoms.drawProgressBand(panel, x, y, w, f.ok and "active" or "danger", f.ok and getText("UI_mods_Done") or cased(ZeD.tr("UI_ZeD_Veh_Failed")), 1, nil, nil, false)
    end
    return 0
end

local function drawScrollbar(panel, win, key, x, top, h, total, scrollY, set)
    if total <= h then return end
    ZeD.Molecules.scrollBar(panel, win, key, x, top, ZeD.T.sp.scrollbarW, h, scrollY, total, set)
end

-- ----------------------------------------------------------------------------
-- Overview (figure + summary + part list)
-- ----------------------------------------------------------------------------
local function drawSummary(panel, s, sx, sy, sw, v, chr, parts, hl)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local yy = sy
    local p = hl and s.partById and s.partById[hl]
    if p then
        local hc = T.text
        panel:drawText(p.name, sx, yy, hc.r, hc.g, hc.b, hc.a or 1, T.fontF4)
        yy = yy + T.fontF4H
        local dc = T.textDim
        panel:drawText(catLabel(p.cat), sx, yy, dc.r, dc.g, dc.b, dc.a or 1, T.fontF1)
        yy = yy + T.fontF1H + T.px(10)
        yy = yy + drawLabelValue(panel, sx, yy, sw, getText("IGUI_invpanel_Condition"), (p.missing or p.smashed) and "-" or (tostring(p.cond) .. "%")) + T.px(4)
        if p.missing or p.smashed then
            A.drawSegFill(panel, sx, yy, sw, T.fillBarH, A.STATUS_SEGS, 0)   -- (no reading: "-" above it)
        else
            A.drawFillBar(panel, sx, yy, sw, p.cond / 100, true, nil, nil, ZeD.tr("IGUI_invpanel_Condition"))
        end
        yy = yy + T.fillBarH + T.px(10)
        local item = p.part:getInventoryItem()
        if p.missing then
            yy = yy + M.drawStatRowDot(panel, sx, yy, sw, getText("IGUI_Item"), getText("IGUI_Missing"), T.danger)
        elseif p.smashed then
            yy = yy + M.drawStatRowDot(panel, sx, yy, sw, getText("IGUI_Item"), ZeD.tr("UI_ZeD_Veh_Smashed"), T.danger)
        elseif item then
            yy = yy + M.drawStatRow(panel, sx, yy, sw, getText("IGUI_Item"), MT.forThisCar(item:getDisplayName(), v))
        end
        if p.info and p.info ~= "" then yy = yy + M.drawStatRow(panel, sx, yy, sw, ZeD.tr("UI_ZeD_Veh_State"), p.info) end
        if p.id == "Engine" then
            yy = yy + M.drawStatRow(panel, sx, yy, sw, getText("Attributes_Type_Quality"), tostring(v:getEngineQuality()))
            yy = yy + M.drawStatRow(panel, sx, yy, sw, ZeD.tr("UI_ZeD_Veh_Power"), ZeD.tr("UI_ZeD_Veh_Hp", round(v:getEnginePower() / 10, 0)))
        end
        if p.part:getWheelFriction() > 0 and item then
            yy = yy + M.drawStatRow(panel, sx, yy, sw, ZeD.tr("UI_ZeD_Veh_Friction"), tostring(round(p.part:getWheelFriction(), 2)))
        end
        return yy
    end
    local ov = overallCond(v)
    yy = yy + drawLabelValue(panel, sx, yy, sw, ZeD.tr("UI_ZeD_Veh_Overall"), tostring(ov) .. "%") + T.px(4)
    A.drawFillBar(panel, sx, yy, sw, ov / 100, true, nil, nil, ZeD.tr("UI_ZeD_Veh_Overall"))
    yy = yy + T.fillBarH + T.px(8)
    local miss, worn = 0, 0
    for _, q in ipairs(parts) do
        if q.missing or q.smashed then miss = miss + 1 elseif q.cond <= 60 then worn = worn + 1 end
    end
    local dc = (miss > 0 and T.danger) or (worn > 0 and T.warning) or T.positive
    local line = (miss == 0 and worn == 0) and ZeD.tr("UI_ZeD_Veh_NothingNeedsWork")
                 or ZeD.tr("UI_ZeD_Veh_MissingWorn", miss, worn)
    yy = yy + dotLine(panel, sx, yy, sw, dc, line) + T.px(8)
    A.drawDividerH(panel, sx, yy, sw, false)
    yy = yy + T.px(6)
    local eng = v:getPartById("Engine")
    if eng then
        yy = yy + M.drawStatRow(panel, sx, yy, sw, getText("IGUI_VehiclePartEngine"), ZeD.tr("UI_ZeD_Veh_Hp", round(v:getEnginePower() / 10, 0)))
        yy = yy + M.drawStatRow(panel, sx, yy, sw, getText("Attributes_Type_Quality"), tostring(v:getEngineQuality()))
        yy = yy + M.drawStatRow(panel, sx, yy, sw, ZeD.tr("UI_ZeD_Veh_Loudness"), tostring(v:getEngineLoudness()))
    end
    yy = yy + M.drawStatRow(panel, sx, yy, sw, getText("IGUI_char_Weight"), thousands(v:getMass()))
    local gas = v:getPartById("GasTank")
    if gas and gas:getInventoryItem() then
        yy = yy + M.drawStatRow(panel, sx, yy, sw, getText("IGUI_GlobalObject_Fuel"),
            tostring(round(gas:getContainerContentAmount(), 1)) .. " / " .. tostring(math.floor(gas:getContainerCapacity())))
    end
    local bat = v:getPartById("Battery")
    if bat then
        local bi = bat:getInventoryItem()
        if bi and bi.getCurrentUsesFloat then
            yy = yy + M.drawStatRow(panel, sx, yy, sw, getText("IGUI_VehiclePartBattery"), ZeD.tr("UI_ZeD_Veh_Charge", math.floor(bi:getCurrentUsesFloat() * 100) .. "%"))
        else
            yy = yy + M.drawStatRowDot(panel, sx, yy, sw, getText("IGUI_VehiclePartBattery"), getText("IGUI_Missing"), T.danger)
        end
    end
    local ks, kc = keyState(v, chr)
    yy = yy + M.drawStatRowDot(panel, sx, yy, sw, getText("IGUI_ItemType_Key"), ks, kc == "pos" and T.positive or T.warning)
    yy = yy + ZeD.MechTrailer.drawTowRow(panel, s, sx, yy, sw, v)
    if ZeD.ExtrasCards then yy = yy + ZeD.ExtrasCards.statRow(panel, sx, yy, sw, v) end
    return yy
end

-- ----------------------------------------------------------------------------
-- Part card
-- ----------------------------------------------------------------------------
local function cardStats(p, v, chr)
    local T = ZeD.T
    local part, item = p.part, p.part:getInventoryItem()
    local rows = {}
    local function add(label, value, dot) rows[#rows + 1] = { label = label, value = value, dotColor = dot } end
    if p.missing then add(getText("IGUI_invpanel_Condition"), getText("IGUI_Missing"), T.danger)
    elseif p.smashed then add(getText("IGUI_invpanel_Condition"), ZeD.tr("UI_ZeD_Veh_Smashed"), T.danger)
    else add(getText("IGUI_invpanel_Condition"), tostring(p.cond) .. "%", statusColor(T, p.cond)) end
    if item then add(getText("IGUI_Item"), MT.forThisCar(item:getDisplayName(), v)) end
    if part:getId() == "Engine" then
        add(getText("Attributes_Type_Quality"), tostring(v:getEngineQuality()))
        add(ZeD.tr("UI_ZeD_Veh_Loudness"), tostring(v:getEngineLoudness()))
        add(ZeD.tr("UI_ZeD_Veh_Power"), ZeD.tr("UI_ZeD_Veh_Hp", round(v:getEnginePower() / 10, 0)))
        local ks, kc = keyState(v, chr)
        add(getText("IGUI_ItemType_Key"), ks, kc == "pos" and T.positive or T.warning)
    end
    if item and part:getTable("install") then add(getText("IGUI_char_Weight"), tostring(round(item:getWeight(), 0))) end
    if item and instanceof(item, "DrainableComboItem") then add(getText("IGUI_invpanel_Remaining"), tostring(round(item:getCurrentUsesFloat() * 100, 0)) .. "%") end
    if item and part:isContainer() and part:getContainerContentType() then
        local ct, amt, cap = part:getContainerContentType(), part:getContainerContentAmount(), part:getContainerCapacity()
        if ct == "Air" then
            local c = (amt < cap * 0.6 and T.danger) or (amt < cap * 0.9 and T.warning) or T.positive
            add(ZeD.tr("UI_ZeD_Veh_Pressure"), ZeD.tr("UI_ZeD_Veh_PsiOf", math.floor(amt + 0.5), math.floor(cap)), c)
        else
            add(ct == "Gasoline" and getText("IGUI_GlobalObject_Fuel") or ct, tostring(round(amt, 1)) .. " / " .. tostring(math.floor(cap)))
        end
    elseif item and part:getItemContainer() then
        local seat = part:getContainerSeatNumber()
        if seat > -1 and v:isSeatOccupied(seat) then add(ZeD.tr("UI_ZeD_Veh_Seat"), ZeD.tr("UI_ZeD_Veh_StOccupied"))
        else add(getText("Fluid_Capacity"), tostring(round(part:getItemContainer():getCapacityWeight(), 2)) .. " / " .. tostring(part:getContainerCapacity(chr))) end
    end
    if item and item:getBrakeForce() > 0 then add(ZeD.tr("UI_ZeD_Veh_Braking"), tostring(round(v:getBrakingForce(), 1))) end
    if item and item:getEngineLoudness() > 0 then add(ZeD.tr("UI_ZeD_Veh_Loudness"), "x" .. tostring(round(1 + (100 - part:getEngineLoudness()) / 100, 2))) end
    local door = part:getDoor()
    if door then
        add(ZeD.tr("UI_ZeD_Veh_StOpen"), door:isOpen() and getText("UI_Yes") or getText("UI_No"))
        add(getText("EC_Locked"), door:isLocked() and getText("UI_Yes") or getText("UI_No"))
        if door:isLockBroken() then add(ZeD.tr("UI_ZeD_Veh_Lock"), getText("Tooltip_broken"), T.danger) end
    end
    local w = part:getWindow()
    if w and w:isOpenable() and not w:isDestroyed() then add(ZeD.tr("UI_ZeD_Veh_StOpen"), w:isOpen() and getText("UI_Yes") or getText("UI_No")) end
    if part:getModData().temperature then add(ZeD.tr("UI_ZeD_Veh_Temp"), tostring(round(part:getModData().temperature, 1))) end
    if part:getWheelFriction() > 0 and item then add(ZeD.tr("UI_ZeD_Veh_Friction"), tostring(round(part:getWheelFriction(), 2))) end
    if part:getItemType() and not part:getItemType():isEmpty() then add(getText("IGUI_PlayerStats_Type"), mechType(v)) end
    return rows
end

local function iconFor(p)
    local item = p.part:getInventoryItem()
    if item then return item:getTex(), false end
    local it = p.part:getItemType()
    if it and not it:isEmpty() then
        local sc = getItem(it:get(0))
        if sc then return sc:getNormalTexture(), true end
    end
    -- no item (the engine): its glyph from the car figure
    local prefix, props = overlayInfo(p.part:getVehicle())
    local imgs = prefix and partImgs(props, p.id)
    if imgs and imgs[1] then return tex(prefix .. imgs[1]), p.missing end
    return nil, p.missing
end

-- What a verb is missing, in plain words: the requirements it does not meet (the ones
-- it meets are not listed: a verb you can press has them all). A requirement may carry
-- its own words (what); its kicker says how ("must be off", "recipe").
local function missingOf(n)
    local names = {}
    for _, r in ipairs(n.rows) do
        if not r.ok and not r.soft then
            local lbl = r.what or r.label
            local need = r.value and string.match(tostring(r.value), "^%d+ / (%d+)$")
            if need then lbl = lbl .. " " .. need end
            if not r.what and r.kicker and r.kicker ~= "" then lbl = lbl .. " (" .. string.lower(cased(r.kicker)) .. ")" end
            names[#names + 1] = lbl
        end
    end
    return table.concat(names, ", ")
end

-- A verb that makes no sense for the part as it is now is gone, not greyed: no repair for
-- a perfect part, no pump for a full tire, no air to let out of an empty one.
local function verbSensible(part, vb)
    if vb == "repairEngine" or vb == "repairLightbar" then return part:getCondition() < 100 end
    if vb == "inflate" then return part:getContainerContentAmount() < part:getContainerCapacity() + 5 end
    if vb == "deflate" then return part:getContainerContentAmount() > 0 end
    return true
end

-- ----------------------------------------------------------------------------
-- The part list's order. By section: the game's part
-- categories, a part under the one it hangs off (parentOf); By condition: worst
-- first, earned at Mechanics level 4.
-- ----------------------------------------------------------------------------
local COND_LEVEL = 4   -- the Mechanics level that earns By condition
local CHILD_IN   = 12  -- a part under another: its row indented this much

local function condEarned(chr) return chr ~= nil and mechLevel(chr) >= COND_LEVEL end
-- the greyed choice's words: "Mechanics Level 4" from words the game and ZeD already have
local function condGateText() return ZeD.tr("UI_ZeD_Craft_SkillLevel", getText("IGUI_perks_Mechanics"), COND_LEVEL) end

local function groupedParts(s, parts, chr)
    if s.sort == "cond" and condEarned(chr) then
        local all = {}
        for _, p in ipairs(parts) do all[#all + 1] = p end
        table.sort(all, function(a, b)
            local ca = (a.missing or a.smashed) and -1 or a.cond
            local cb = (b.missing or b.smashed) and -1 or b.cond
            if ca == cb then return a.order < b.order end
            return ca < cb
        end)
        local rows = {}
        for i, p in ipairs(all) do rows[i] = { p = p, depth = 0 } end
        return { { cat = "_worst", label = ZeD.tr("UI_ZeD_Veh_WorstFirst"), rows = rows } }
    end
    -- By section: each top part with the parts under it, walked in the vehicle's own order
    local byId, kids, roots = {}, {}, {}
    for _, p in ipairs(parts) do byId[p.id] = p end
    for _, p in ipairs(parts) do
        local par = p.parent
        if par and par ~= p.id and byId[par] then
            local k = kids[par]
            if not k then k = {}; kids[par] = k end
            k[#k + 1] = p
        else
            roots[#roots + 1] = p
        end
    end
    local groups, byCat, seen = {}, {}, {}
    local function groupFor(cat)
        local g = byCat[cat]
        if not g then
            g = { cat = cat, label = catLabel(cat), rows = {} }
            byCat[cat] = g
            groups[#groups + 1] = g
        end
        return g
    end
    local function walk(g, p, depth)
        if seen[p.id] then return end
        seen[p.id] = true
        g.rows[#g.rows + 1] = { p = p, depth = depth }
        for _, c in ipairs(kids[p.id] or {}) do walk(g, c, depth + 1) end
    end
    for _, p in ipairs(roots) do
        -- the hood with the engine bay under it heads Under hood, whatever its own category
        local cat = (p.id == "EngineDoor" and kids[p.id]) and "engine" or p.cat
        walk(groupFor(cat), p, 0)
    end
    for _, p in ipairs(parts) do   -- (a link that runs in a circle: the part keeps a row of its own)
        if not seen[p.id] then walk(groupFor(p.cat), p, 0) end
    end
    table.sort(groups, function(a, b)
        local ra, rb = CAT_RANK[a.cat] or 99, CAT_RANK[b.cat] or 99
        if ra == rb then return a.label < b.label end
        return ra < rb
    end)
    return groups
end

-- The part that has to be dealt with before this one can be installed or uninstalled
-- (the card's first line): { id, text } or nil. The game's own words.
local function stepBefore(v, part, verb)
    local kv = part:getTable(verb == "install" and "install" or "uninstall")
    if not kv then return nil end
    -- (QA M10c, Nov 26 2026: an install never needs a part off first; the game's InstallTest skips requireUninstalled)
    for _, q in ipairs(verb == "install" and {} or idsIn(kv.requireUninstalled)) do
        local qp = v:getPartById(q)
        if qp and qp:getInventoryItem() then
            return { id = q, text = getText("Tooltip_vehicle_requireUnistalled", partName(q)), off = true }
        end
    end
    if verb == "install" then
        for _, q in ipairs(idsIn(kv.requireInstalled)) do
            local qp = v:getPartById(q)
            if qp and not qp:getInventoryItem() and qp:getTable("install") then
                return { id = q, text = getText("Tooltip_vehicle_requireInstalled", partName(q)) }
            end
        end
    end
    return nil
end

-- The odds, in percent, that an install or uninstall damages the part, from the game's two numbers
-- (VehicleUtils.calculateInstallationSuccess). An install that misses the success roll damages the
-- item only on a second roll under the failure share (ISInstallVehiclePart:complete: 35% of 35% at
-- Mechanics 0, about 12); an uninstall that misses always damages the part (ISUninstallVehiclePart:
-- ZombRand(failure) < 100 is always true). (QA M16c, Nov 26 2026)
function MT.damageOdds(verb, success, failure)
    local miss = math.max(0, 100 - (success or 100))
    if verb == "uninstall" then return miss end
    return math.floor(miss * math.max(0, failure or 0) / 100 + 0.5)
end

-- A part with repair recipes the game will not run on the car (not a repair-mechanic part): its
-- tooltip says "Can be repaired once uninstalled." (ISVehicleMechanics:doMenuTooltip). (QA M10f, Nov 26 2026)
function MT.repairOnlyOff(part)
    local yes = false
    pcall(function()
        local item = part:getInventoryItem()
        local itype = part:getItemType()
        if item and itype and not itype:isEmpty() and not part:getScriptPart():isRepairMechanic() then
            local fixes = FixingManager.getFixes(item)
            yes = fixes ~= nil and not fixes:isEmpty()
        end
    end)
    return yes
end

-- Where the game walks the character to work on the part: its area in words
local function workPlace(part)
    local ok, area = pcall(function() return part:getArea() end)
    if not ok or not area or area == "" then return nil end
    if area == "Engine" then return catLabel("engine") end
    return cased(partName(area))
end

local function openCard(win, s, id)
    s.card, s.verb, s.confirm, s.sortOpen = id, nil, nil, nil
    s.cardScroll, s.pick, s.fixPick = 0, 1, 1
    s.pickItem = nil   -- (M3: the new part's best spare is taken at its first draw)
    s.items = nil
    s.needsCache, s.fixCache, s.partsCache = nil, nil, nil
    win._mechFocusTarget = "card"
end
local function closeCard(win, s)
    s.confirm, s.sortOpen = nil, nil
    s.cardScroll = 0
    s.needsCache, s.fixCache, s.partsCache = nil, nil, nil
    win._mechFocusTarget = s.card and ("mech:row:" .. s.card) or nil
    s.card = nil
end

-- ----------------------------------------------------------------------------
-- The chosen part's verbs and what each needs (the card and the footer share it)
-- ----------------------------------------------------------------------------
local function cardModel(s, part, chr, v)
    local DS = ZeD.Disclose
    local verbs = verbsFor(part, chr)
    local gpId = s.gpId
    if gpId and gpId:sub(1, 10) == "mech:verb:" then s.verb = gpId:sub(11) end
    -- every verb with what it needs, sorted by the hidden-actions setting: the ones you can do
    -- are shown; the ones you cannot yet fold into one row in the card; the ones that make no
    -- sense now are gone
    local needs, list = {}, {}
    for _, vb in ipairs(verbs) do
        local n = needsFor(s, part, vb, chr, v)
        needs[vb] = n
        local missing = n.ok and "" or missingOf(n)
        local label = vlabel(vb)
        list[#list + 1] = {
            id = vb, label = label, canDo = n.ok, sensible = verbSensible(part, vb), danger = DANGER[vb],
            needs = (n.short ~= nil) and n.short or ((missing ~= "") and missing or ZeD.tr("UI_ZeD_Veh_RightConditions")),
            hint = ZeD.tr(VERB_HINT[vb] or "UI_ZeD_Veh_HintDefault"),
            needsLine = n.line or ((missing == "") and ZeD.tr("UI_ZeD_Veh_NotNow", label) or nil),
            help = ZeD.tr(VERB_HELP[vb] or "UI_ZeD_Veh_HelpDefault"),
        }
    end
    local shown, hidden = DS.split(list)
    local byId = {}
    for _, sv in ipairs(shown) do byId[sv.id] = sv end
    local primary = nil
    for _, vb in ipairs(PRIMARY_ORDER) do
        if byId[vb] and byId[vb].canDo then primary = vb; break end
    end
    if not (s.verb and byId[s.verb]) then
        s.verb = primary
        if not s.verb then
            for _, vb in ipairs(PRIMARY_ORDER) do if byId[vb] then s.verb = vb; break end end
        end
        if not s.verb and shown[1] then s.verb = shown[1].id end
    end
    return { part = part, p = partModel(part, chr, v), needs = needs, shown = shown, hidden = hidden,
             verbs = verbs, primary = primary, busy = chainBusy(s, chr) or activeAction(chr, v) ~= nil }   -- (the whole chain: M2)
end

-- run a verb from the footer (a destructive one asks first)
local function pressVerb(win, s, cm, verb, chr)
    vehNote(verb, cm.part, "pressed")
    s.verb = verb
    -- (a refused press says why in the console, once per reason: QA's M3 second pass found Install doing nothing
    -- after a pick and the screen gave no reason, Nov 26 2026)
    -- (asked live, not from cm: cm is the card as it was drawn when the button was stamped, and a press can come
    -- from a stamp a frame or more old (QA's M3: "busy" with nothing queued, the card's busy left from the last
    -- chain). Nov 26 2026)
    local v = cm.part and cm.part:getVehicle()
    local cb = chainBusy(s, chr)
    local aa = (v ~= nil) and activeAction(chr, v) or nil
    local n = nil
    if cm.part and v then pcall(function() n = needsFor(s, cm.part, verb, chr, v) end) end
    n = n or cm.needs[verb]
    local why = (cb and "chainBusy") or (aa and ("activeAction " .. tostring(aa.Type or aa.jobType))) or ((not (n and n.ok)) and "needs") or nil
    if why then vehNote(verb, cm.part, "refused (" .. why .. ")"); return end
    if DANGER[verb] then
        if refusePaused(chr) then return end   -- (no question to answer while paused: M12)
        s.confirm = verb; win._mechFocusTarget = "mech:confirm:no"; return
    end
    runVerb(s, verb, cm.part, chr)
end

-- ----------------------------------------------------------------------------
-- Left: the part list
-- ----------------------------------------------------------------------------
local function renderList(panel, win, s, x, top, w, bodyH, v, chr, inspected, parts, trailer, mouse)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local TM = ZeD.TM
    local scrollW = T.sp.scrollbarW
    local cw = w - scrollW
    local pad = T.px(PAD)
    local gpId, hl = s.gpId, s.hl
    local clip = { x = x, y = top, w = w, h = bodyH }
    s.listClip = clip
    local mx, my = mouse and mouse.x or -1, mouse and mouse.y or -1
    local function rowHover(ry, rh) return mouse ~= nil and my >= ry and my < ry + rh end

    panel:setStencilRect(x, top, w, bodyH)
    local cy = top - s.scrollY
    s.lastRows = {}
    -- an animal trailer's animals come before its parts
    if trailer then
        s.bodyClip = clip
        cy = ZeD.MechTrailer.drawSections(panel, win, s, x, cy, cw, v, chr, clip, mouse)
    end
    if inspected then
        -- (QA's visual noise audit 11, Nov 20 2026: the column heads Part and Cond went; they were a second sort
        -- control under the footer's Sort, which keeps both sorts for the mouse and the controller)
        local condRight = x + cw - pad

        for _, g in ipairs(groupedParts(s, parts, chr)) do
            -- category row (A / click folds it)
            local ch = T.px(CAT_H)
            local collapsed = s.collapsed[g.cat]
            local catKey = g.cat
            M.drawCategoryRow(panel, x, cy, cw, g.label, #g.rows, not collapsed, {
                hover = rowHover(cy, ch), focus = focusFor(s, "mech:cat:" .. catKey), inset = pad })
            if rowHover(cy, ch) then help(panel, "UI_ZeD_Veh_HelpFold") end
            stamp(s, "mech:cat:" .. catKey, x, cy, cw, ch, function() s.collapsed[catKey] = not s.collapsed[catKey] end,
                  { clip = clip, isDisclosure = true, pane = "list" })
            cy = cy + ch
            if not collapsed then
                for ri, row in ipairs(g.rows) do
                    local p = row.p
                    local rh = T.px(ROW_H)
                    if ri % 2 == 0 then
                        local sp = T.stripe
                        panel:drawRect(x, cy, cw, rh, sp.a, sp.r, sp.g, sp.b)
                    end
                    if s.card == p.id then
                        local ac = T.accent
                        panel:drawRect(x, cy, cw, rh, T.selectionA, ac.r, ac.g, ac.b)
                    elseif hl == p.id and not gpId then
                        local hv = T.hover
                        panel:drawRect(x, cy, cw, rh, hv.a, hv.r, hv.g, hv.b)
                    end
                    if rowHover(cy, rh) then help(panel, "UI_ZeD_Veh_HelpPartRow") end
                    local pid = p.id
                    local onFocus = markAt(s, panel, "mech:row:" .. pid, x, cy, cw, rh)
                    local ink = onFocus and T.textOnFocus or T.text
                    local inkDim = onFocus and T.textOnFocus or T.textDim
                    local dc = (p.missing or p.smashed) and T.danger or statusColor(T, p.cond)
                    local d = T.px(7)
                    local indent = T.px(CHILD_IN) * row.depth
                    A.drawStatusDot(panel, x + pad + indent, cy + math.floor((rh - d) / 2), dc, d)
                    local nameX = x + pad + indent + d + T.px(8)
                    -- the right end: the state as a red tag (Missing, Smashed), or the bar and percent;
                    -- a locked door says so before them
                    local rightX
                    if p.missing or p.smashed then
                        local label = p.missing and getText("IGUI_Missing") or ZeD.tr("UI_ZeD_Veh_Smashed")
                        local bw = TM:MeasureStringX(T.fontF1, cased(label)) + T.px(20)
                        rightX = condRight - bw
                        M.drawTag(panel, rightX, cy + math.floor((rh - T.px(16)) / 2), label, T.danger)
                    else
                        -- (QA's visual noise audit 11, Nov 20 2026: the square, a bar and the percent read the
                        -- condition three ways; the square and the percent stay, the bar goes)
                        A.drawTextRight(panel, tostring(p.cond) .. "%", condRight, cy + math.floor((rh - T.fontF3H) / 2), T.fontF3, ink)
                        rightX = condRight - T.px(PCT_W)
                    end
                    if p.locked then
                        local lw = cased(getText("EC_Locked"))
                        local lwW = TM:MeasureStringX(T.fontF1, lw)
                        if rightX - T.px(6) - lwW > nameX + T.px(40) then
                            rightX = rightX - T.px(6) - lwW
                            panel:drawText(lw, rightX, cy + math.floor((rh - T.fontF1H) / 2), inkDim.r, inkDim.g, inkDim.b, inkDim.a or 1, T.fontF1)
                        end
                    end
                    local nameMaxW = rightX - T.px(8) - nameX
                    local nm = p.name
                    if TM:MeasureStringX(T.fontF2, nm) > nameMaxW then nm = A.truncateText(nm, T.fontF2, math.max(0, nameMaxW)) end
                    panel:drawText(nm, nameX, cy + math.floor((rh - T.fontF2H) / 2), ink.r, ink.g, ink.b, ink.a or 1, T.fontF2)
                    -- a click or A chooses the part; the chosen row again brings the diagram back
                    local z = stamp(s, "mech:row:" .. pid, x, cy, cw, rh, function()
                        if s.card == pid then closeCard(win, s) else openCard(win, s, pid) end
                    end, { clip = clip, part = pid, isRow = true, pane = "list" })
                    s.lastRows[#s.lastRows + 1] = z
                    cy = cy + rh
                end
            end
        end
    else
        -- the parts wait for an inspection (the footer's Inspect): the list's head, then one dim sentence
        local ch = M.drawCategoryRow(panel, x, cy, cw, ZeD.tr("UI_ZeD_Veh_PartsLabel"), #parts, false,
            { noArrow = true, inset = pad })
        cy = cy + ch + T.px(8)
        cy = cy + M.drawEmptyLine(panel, x + pad, cy, cw - pad * 2, ZeD.tr("UI_ZeD_Veh_InspectParts", vehicleName(v))) + T.px(8)
    end
    panel:clearStencilRect()

    local total = (cy + s.scrollY) - top
    s.maxScroll = math.max(0, total - bodyH)
    if s.scrollY > s.maxScroll then s.scrollY = s.maxScroll end
    drawScrollbar(panel, s.win, "mech:list", x + w - scrollW, top, bodyH, total, s.scrollY, function(v) s.scrollY = v end)

    -- opened from Check Animals: scroll just enough to show the animals
    if s.showAnimals then
        s.showAnimals = nil
        if trailer and s.trAnimalsY then
            local want = math.min(s.trAnimalsEnd or s.trAnimalsY, s.trAnimalsY + T.px(CAT_H + 3 * 40))
            local delta = math.min(want - (top + bodyH), s.trAnimalsY - top)
            if delta > 0 then s.scrollY = math.min(s.maxScroll, s.scrollY + delta) end
        end
    end
end

-- ----------------------------------------------------------------------------
-- Right, no part chosen: the car diagram and the vehicle's summary
-- ----------------------------------------------------------------------------
local function renderDiagram(panel, win, s, x, top, w, bodyH, v, chr, inspected, parts, trailer)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local scrollW = T.sp.scrollbarW
    local cw = w - scrollW
    local pad = T.px(PAD)
    local clip = { x = x, y = top, w = w, h = bodyH }
    s.rightClip = clip
    panel:setStencilRect(x, top, w, bodyH)
    local cy = top - s.cardScroll + pad
    local figW, figH = cw - pad * 2, T.px(FIG_H)
    -- FIG_H is the most the figure may take; it hands back what it used (Car parts to the sides, Nov 22 2026)
    figH = drawFigure(panel, s, x + pad, cy, figW, figH, v, parts, s.hl, not inspected, s.working) or figH
    s.figClip = clip
    cy = cy + figH + T.px(COL_GAP)
    local sx, sw = x + pad, cw - pad * 2
    if trailer then
        s.bodyClip = clip
        cy = ZeD.MechTrailer.drawSummary(panel, win, s, sx, cy, sw, v, chr, inspected) or cy
    elseif inspected then
        cy = drawSummary(panel, s, sx, cy, sw, v, chr, parts, nil) or cy
    else
        local yy = cy
        yy = yy + drawLabelValue(panel, sx, yy, sw, ZeD.tr("UI_ZeD_Veh_Overall"), "?") + T.px(4)
        A.drawSegFill(panel, sx, yy, sw, T.fillBarH, A.STATUS_SEGS, 0)   -- (not known yet: no reading in the help line)
        yy = yy + T.fillBarH + T.px(8)
        local dc = T.textDim
        yy = yy + dotLine(panel, sx, yy, sw, { r = dc.r, g = dc.g, b = dc.b, a = 0.6 }, ZeD.tr("UI_ZeD_Veh_NotInspected")) + T.px(8)
        A.drawDividerH(panel, sx, yy, sw, false)
        yy = yy + T.px(6)
        yy = yy + M.drawStatRow(panel, sx, yy, sw, getText("IGUI_PlayerStats_Type"), mechType(v))
        local dist = math.floor((currentEntry(s) and currentEntry(s).dist or 0) + 0.5)
        yy = yy + M.drawStatRow(panel, sx, yy, sw, ZeD.tr("UI_ZeD_Veh_Distance"), ZeD.tr(dist == 1 and "UI_ZeD_Veh_TilesOne" or "UI_ZeD_Veh_Tiles", dist))
        local ks, kc = keyState(v, chr)
        yy = yy + M.drawStatRowDot(panel, sx, yy, sw, getText("IGUI_ItemType_Key"), ks, kc == "pos" and T.positive or T.warning)
        yy = yy + ZeD.MechTrailer.drawTowRow(panel, s, sx, yy, sw, v)
        if ZeD.ExtrasCards then yy = yy + ZeD.ExtrasCards.statRow(panel, sx, yy, sw, v) end
        cy = yy
    end
    panel:clearStencilRect()
    local total = (cy + pad + s.cardScroll) - top
    s.maxRight = math.max(0, total - bodyH)
    if s.cardScroll > s.maxRight then s.cardScroll = s.maxRight end
    drawScrollbar(panel, s.win, "mech:card", x + w - scrollW, top, bodyH, total, s.cardScroll, function(v) s.cardScroll = v end)
end

-- ----------------------------------------------------------------------------
-- Right, a part chosen: its card. The verbs are in the footer.
-- ----------------------------------------------------------------------------
local function renderCardBody(panel, win, s, x, top, w, bodyH, v, chr, cm)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local TM = ZeD.TM
    local DS = ZeD.Disclose
    local part, p = cm.part, cm.p
    local scrollW = T.sp.scrollbarW
    local cw = w - scrollW
    local pad = T.px(PAD)
    local clip = { x = x, y = top, w = w, h = bodyH }
    s.rightClip = clip
    local iw = cw - pad * 2

    panel:setStencilRect(x, top, w, bodyH)
    local cy = top - s.cardScroll + pad

    -- the part: its icon (ghosted when it is missing), its name, its category
    local icon, ghost = iconFor(p)
    local isz = T.px(36)
    local bg, bd = T.surf2, ghost and T.danger or T.borderS
    if not ghost then panel:drawRect(x + pad, cy, isz, isz, bg.a, bg.r, bg.g, bg.b) end
    panel:drawRectBorder(x + pad, cy, isz, isz, bd.a or 1, bd.r, bd.g, bd.b)
    if icon then A.drawIcon(panel, icon, x + pad + T.px(3), cy + T.px(3), isz - T.px(6), ghost and 0.3 or 1.0, T.iconWhite) end
    local tx = x + pad + isz + T.px(8)
    local tw = x + pad + iw - tx
    local hc, dcl = T.text, T.textDim
    local nm = p.name
    if TM:MeasureStringX(T.fontF4, nm) > tw then nm = A.truncateText(nm, T.fontF4, tw) end
    panel:drawText(nm, tx, cy, hc.r, hc.g, hc.b, hc.a or 1, T.fontF4)
    panel:drawText(A.truncateText(catLabel(p.cat), T.fontF1, tw), tx, cy + T.fontF4H, dcl.r, dcl.g, dcl.b, dcl.a or 1, T.fontF1)
    cy = cy + math.max(isz, T.fontF4H + T.fontF1H) + T.px(10)

    -- the step before: the part that has to come off (or go on) first, and a key
    -- that chooses it
    local sb = nil
    if s.verb == "install" or s.verb == "uninstall" then sb = stepBefore(v, part, s.verb) end
    if not sb then
        -- every verb the part has, the folded ones too: a brake blocked only by its tire has its
        -- Uninstall folded away
        for _, vb in ipairs(cm.verbs) do
            if vb == "install" or vb == "uninstall" then sb = stepBefore(v, part, vb); if sb then break end end
        end
    end
    -- (QA's visual noise audit 16, Nov 20 2026: the game's "Rear Left Tire need to be uninstalled first", then the
    -- button, then the greyed verb's needs line said one thing three times. Now one row in ZeD's words, "Take off
    -- first:" and the button; the verb that step blocks draws no needs line of its own.)
    local sbId = nil
    if sb then
        local bh = T.buttonH
        local lead = ZeD.tr(sb.off and "UI_ZeD_Veh_TakeOffFirst" or "UI_ZeD_Veh_PutOnFirst")
        local leadW = TM:MeasureStringX(T.fontF2, lead)
        local label = cased(partName(sb.id))
        local bx = x + pad + leadW + T.px(8)
        local bw = math.min(x + pad + iw - bx, M.buttonW(label))
        if bw < T.px(60) then   -- (no room beside the words: the button goes under them)
            bx, bw = x + pad, math.min(iw, M.buttonW(label))
        end
        local tc0 = T.text
        local lineY = (bx == x + pad) and cy or (cy + math.floor((bh - T.fontF2H) / 2))
        panel:drawText(lead, x + pad, lineY, tc0.r, tc0.g, tc0.b, tc0.a or 1, T.fontF2)
        if bx == x + pad then cy = cy + T.fontF2H + T.px(4) end
        local onFocus = focusFor(s, "mech:step")
        M.drawButton(panel, bx, cy, bw, bh, label, "default", false, nil,
            { focus = onFocus, win = win, help = ZeD.tr("UI_ZeD_Veh_HelpPartRow") })
        local toId = sb.id
        stamp(s, "mech:step", bx, cy, bw, bh, function() openCard(win, s, toId) end, { clip = clip, pane = "right" })
        cy = cy + bh + T.px(10)
        sbId = sb.id
    end

    -- a verb shown greyed says what it needs; the folded row after: what you could do with the
    -- right things (A / click opens it)
    local moreKey = "veh:part:" .. tostring(p.id)
    for _, sv in ipairs(cm.shown) do
        if not sv.canDo and not (sbId and (sv.id == "install" or sv.id == "uninstall") and (stepBefore(v, part, sv.id) or {}).id == sbId) then
            cy = cy + M.drawNeedsLine(panel, x + pad, cy, iw, DS.needsLine(sv)) + T.px(4)
        end
    end
    if #cm.hidden > 0 then
        local mh, rowRect = M.drawMoreRow(panel, x + pad, cy, iw, cm.hidden, moreKey,
            { focus = focusFor(s, "mech:more"), win = win })
        if rowRect then
            stamp(s, "mech:more", rowRect.x, rowRect.y, rowRect.w, rowRect.h, function() DS.toggle(moreKey) end, { clip = clip, pane = "right" })
        end
        cy = cy + mh + T.px(6)
    end
    -- (QA M10f, Nov 26 2026: a part the game repairs only off the car, no Repair here; the game's tooltip line)
    if MT.repairOnlyOff(part) then
        cy = cy + M.drawEmptyLine(panel, x + pad, cy, iw, getText("Tooltip_RepairableUninstalled")) + T.px(6)
    end

    -- the readings: condition and what the part carries beyond it (pressure, charge, fuel...),
    -- and where the work is done
    local stats = cardStats(p, v, chr)
    local place = workPlace(part)
    -- (QA's visual noise audit 16, Nov 20 2026: "Location  Front Left Tire" under the title "Front Left Tire": the
    -- row goes when it only repeats the title)
    if place and string.lower(place) == string.lower(p.name or "") then place = nil end
    if place then stats[#stats + 1] = { label = getText("IGUI_AttachedItems_Location"), value = place } end
    cy = cy + M.drawTopStatsList(panel, x + pad, cy, iw, stats)
    cy = cy + T.px(8)
    if not p.missing and not p.smashed then
        A.drawFillBar(panel, x + pad, cy, iw, p.cond / 100, true, nil, nil, ZeD.tr("IGUI_invpanel_Condition"))
        cy = cy + T.fillBarH + T.px(10)
    end

    local function section(text)
        -- (punch list 175, D6: the one section style, the small mono line, as Moodles, Fitness and Presets)
        local sh = M.drawCategoryRow(panel, x, cy, cw, text, nil, true, _secOpts(pad))
        cy = cy + sh + T.px(4)
    end

    -- one pickable row: the radio, a selected wash, the controller's mark; returns the ink and the x after the radio
    local function pickRow(id, rowY, rh, sel, radioY, enabled, focusable)
        local rowX, rowW = x + pad, iw
        local hov = enabled and (not isGamepad(ZeD.playerNumOf(win))) and A.mouseIn(panel, rowX, rowY, rowW, rh, clip)
        if sel then
            local ac = T.accent
            panel:drawRect(rowX, rowY, rowW, rh, T.selectionA, ac.r, ac.g, ac.b)
        elseif hov then
            local hv = T.hover
            panel:drawRect(rowX, rowY, rowW, rh, hv.a, hv.r, hv.g, hv.b)
        end
        local onFocus = focusable and markAt(s, panel, id, rowX, rowY, rowW, rh) or false
        local rx = rowX + T.px(4)
        local rs = A.drawRadio(panel, rx, radioY, sel and true or false, { hover = hov, disabled = not enabled })
        return onFocus, rx + rs + T.px(8)
    end

    -- install: the spares in reach and where each is
    if s.verb == "install" then
        local picks = installPicks(part, chr, itemsFor(s, chr))
        pickedInstall(s, picks)   -- (the picked item keeps its tick whatever row it moves to: M3)
        section(ZeD.tr("UI_ZeD_Veh_FromBags"))
        for i, pk in ipairs(picks) do
            local rh = T.px(FIX_H)
            local sel = (not pk.none) and (pk.item == s.pickItem)
            local onFocus, textX = pickRow("mech:pick:" .. tostring(i), cy, rh, sel,
                cy + T.px(6), not pk.none, not pk.none)
            local rc = onFocus and T.textOnFocus or (pk.none and T.textDim or T.text)
            local dimc = onFocus and T.textOnFocus or T.textDim
            local maxW = (x + pad + iw - T.px(4)) - textX
            local nmk = MT.forThisCar(pk.name, v)
            if TM:MeasureStringX(T.fontF2, nmk) > maxW then nmk = A.truncateText(nmk, T.fontF2, maxW) end
            panel:drawText(nmk, textX, cy + T.px(3), rc.r, rc.g, rc.b, rc.a or 1, T.fontF2)
            -- the second line: where it is and its condition (or that none is near)
            local ly = cy + T.px(3) + T.fontF2H
            if pk.none then
                panel:drawText(cased(ZeD.tr("UI_ZeD_Veh_NoneNearby")), textX, ly, dimc.r, dimc.g, dimc.b, dimc.a or 1, T.fontF1)
            else
                local right = x + pad + iw - T.px(4)
                A.drawTextRight(panel, tostring(pk.cond) .. "%", right, ly, T.fontF1, onFocus and T.textOnFocus or T.text)
                local loc = A.truncateText(pk.loc, T.fontF1, math.max(0, right - T.px(40) - textX))
                panel:drawText(loc, textX, ly, dimc.r, dimc.g, dimc.b, dimc.a or 1, T.fontF1)
                local idx, it = i, pk.item
                stamp(s, "mech:pick:" .. tostring(i), x + pad, cy, iw, rh, function() s.pick, s.pickItem = idx, it end, { clip = clip, pane = "right" })
            end
            A.drawDividerH(panel, x + pad, cy + rh - T.px(1), iw, false)
            cy = cy + rh
        end
        cy = cy + T.px(10)
    end

    -- repair: recipe rows (pickable; Repair in the footer runs the picked one)
    if s.verb == "fix" then
        local fr = cachedFixRows(s, part, chr)
        if s.fixPick > #fr then s.fixPick = 1 end
        if not (fr[s.fixPick] and fr[s.fixPick].ok) then
            for i, r in ipairs(fr) do if r.ok then s.fixPick = i; break end end
        end
        section(ZeD.tr("UI_ZeD_Veh_RepairWith"))
        for i, r in ipairs(fr) do
            local rh = T.px(FIX_H)
            local sel = (i == s.fixPick) and r.ok
            local onFocus, textX = pickRow("mech:fix:" .. tostring(i), cy, rh, sel, cy + T.px(6), r.ok, true)
            local tcl = onFocus and T.textOnFocus or (r.ok and T.text or T.textDim)
            local maxW = (x + pad + iw - T.px(4)) - textX
            local label = r.label
            if TM:MeasureStringX(T.fontF2, label) > maxW then label = A.truncateText(label, T.fontF2, maxW) end
            panel:drawText(label, textX, cy + T.px(3), tcl.r, tcl.g, tcl.b, tcl.a or 1, T.fontF2)
            local meta = r.meta .. (r.why and ("  " .. DOT .. "  " .. r.why) or "")
            if TM:MeasureStringX(T.fontF1, meta) > maxW then meta = A.truncateText(meta, T.fontF1, maxW) end
            local mc = onFocus and T.textOnFocus or T.textDim
            panel:drawText(meta, textX, cy + T.px(3) + T.fontF2H, mc.r, mc.g, mc.b, mc.a or 1, T.fontF1)
            local idx = i
            stamp(s, "mech:fix:" .. tostring(i), x + pad, cy, iw, rh, function() if fr[idx] and fr[idx].ok then s.fixPick = idx end end, { clip = clip, pane = "right" })
            A.drawDividerH(panel, x + pad, cy + rh - T.px(1), iw, false)
            cy = cy + rh
        end
        cy = cy + T.px(10)
    end

    -- the chance of success for the highlighted verb (install / uninstall): a framed bar, the
    -- share that works filled
    local n = s.verb and cm.needs[s.verb]
    if n and s.verb ~= "fix" then
        local sc, fc = n.chance[1], n.chance[2]
        if fc and fc > 0 then
            local succ = cased(ZeD.tr("UI_ZeD_Veh_SuccessPct", tostring(sc) .. "%"))
            if A.drawFillBar(panel, x + pad, cy, iw, sc / 100, false, T.positive) then ZeD.Help.set(panel, succ) end
            cy = cy + T.fillBarH + T.px(3)
            local tt = T.text
            panel:drawText(succ, x + pad, cy, tt.r, tt.g, tt.b, tt.a or 1, T.fontF1)
            -- (QA M16c, Nov 26 2026: the right side said "Failure 35%", the game's second roll, beside 65% success; the
            -- real odds the part is damaged, in the game's words, "Chance of damage:")
            A.drawTextRight(panel, getText("Tooltip_chanceFailure") .. " " .. tostring(MT.damageOdds(s.verb, sc, fc)) .. "%", x + pad + iw, cy, T.fontF1, tt)
            cy = cy + T.fontF1H + T.px(10)
        end
    end

    -- ABOUT: the game's part info text
    local about = txt("IGUI_Vehicle_CondInfo" .. p.id, nil)
    if about then
        about = string.gsub(about, "<LINE>", " ")
        section(ZeD.tr("UI_ZeD_Veh_About"))
        local dc = T.textDim
        for _, ln in ipairs(A.wrapText(about, T.fontF2, iw)) do
            panel:drawText(ln, x + pad, cy, dc.r, dc.g, dc.b, dc.a or 1, T.fontF2)
            cy = cy + T.fontF2H
        end
        cy = cy + T.px(10)
    end
    panel:clearStencilRect()

    local total = (cy + s.cardScroll) - top
    s.maxRight = math.max(0, total - bodyH)
    if s.cardScroll > s.maxRight then s.cardScroll = s.maxRight end
    drawScrollbar(panel, s.win, "mech:card", x + w - scrollW, top, bodyH, total, s.cardScroll, function(v) s.cardScroll = v end)
end

-- ----------------------------------------------------------------------------
-- The footer (the band at the foot, both columns): Sort at the left; the chosen part's
-- verbs at the right (the main one last), lit or greyed; with no part chosen, Inspect
-- before an inspection and Close hood while the hood is open. A question in its place
-- before a destructive verb.
-- ----------------------------------------------------------------------------
local _footBtns = {}
local _footSpec = { buttons = _footBtns }
local _footOrder = {}

local function sortModes(chr)
    local earned = condEarned(chr)
    return {
        { id = "area", label = getText("IGUI_invpanel_Category") },
        { id = "cond", label = getText("IGUI_invpanel_Condition"), disabled = not earned,
          aside = (not earned) and condGateText() or nil },
    }
end

local function renderFooter(panel, win, s, x, y, w, v, chr, inspected, cm, barShown)
    local T = ZeD.T
    local M = ZeD.Molecules
    local bh = T.buttonH
    local gap, edge = T.px(8), T.px(8)

    if s.confirm == "xrelease" then
        ZeD.ExtrasCards.releaseBand(panel, win, s, x, y, w, v, MT._h)
        return
    end
    if s.confirm and cm then
        local verb = s.confirm
        -- (QA M1, Nov 26 2026: the question is the game's warning, "This will set engine condition to 0.", beside
        -- the Take parts button; "the engine loses condition" read as a dent)
        local q = (verb == "takeParts") and getText("Tooltip_vehicle_TakeEnginePartsWarning")
                  or ZeD.tr("UI_ZeD_Veh_ConfirmSmash", string.lower(cm.p.name))
        local _, cancelR, verbR = M.drawQuestionBand(panel, x, y, w, q, vlabel(verb), { win = win, danger = true,
            cancelFocus = focusFor(s, "mech:confirm:no"), verbFocus = focusFor(s, "mech:confirm:yes"),
            cancelHelp = ZeD.tr("UI_ZeD_Veh_HelpConfirmNo"), verbHelp = ZeD.tr(VERB_HELP[verb] or "UI_ZeD_Veh_HelpDefault") })
        stamp(s, "mech:confirm:no", cancelR.x, cancelR.y, cancelR.w, cancelR.h, function() s.confirm = nil end, { footer = true })
        stamp(s, "mech:confirm:yes", verbR.x, verbR.y, verbR.w, verbR.h, function()
            s.confirm = nil
            runVerb(s, verb, cm.part, chr)
        end, { footer = true })
        return
    end

    -- the buttons: the chosen part's verbs, or the tab's own (Inspect, Close hood)
    for i = #_footBtns, 1, -1 do _footBtns[i] = nil end
    for i = #_footOrder, 1, -1 do _footOrder[i] = nil end
    if cm then
        local mainSv = nil
        for _, sv in ipairs(cm.shown) do
            if sv.id == cm.primary then mainSv = sv else _footOrder[#_footOrder + 1] = sv end
        end
        if mainSv then _footOrder[#_footOrder + 1] = mainSv end
        for _, sv in ipairs(_footOrder) do
            _footBtns[#_footBtns + 1] = {
                label = sv.label, id = sv.id, disabled = (not sv.canDo) or cm.busy,
                variant = (sv.id == cm.primary) and "primary" or (sv.danger and "danger" or nil),
                focus = focusFor(s, "mech:verb:" .. sv.id), help = sv.help, verb = true, canDo = sv.canDo }
        end
    else
        for _, bv in ipairs(barShown) do
            _footBtns[#_footBtns + 1] = { label = bv.label, id = bv.id, variant = bv.variant, help = bv.help, disabled = bv.disabled,
                                          focus = focusFor(s, "mech:" .. bv.id), fn = bv.fn }
        end
    end

    -- Sort at the left (inspected only): "Sort: Category"; short of room the choice alone
    local showSort = inspected
    local modes = showSort and sortModes(chr) or nil
    local cur = (s.sort == "cond" and condEarned(chr)) and 2 or 1
    local sortLabel, sortW, tight = nil, 0, false
    local function buttonsW()
        local bw = 0
        for _, b in ipairs(_footBtns) do bw = bw + M.buttonW(b.label) + gap end
        return bw
    end
    if showSort then
        local full = ZeD.tr("UI_ZeD_Craft_SortPick", modes[cur].label)
        local fullW = 0
        for _, m in ipairs(modes) do fullW = math.max(fullW, M.popupMenuW(ZeD.tr("UI_ZeD_Craft_SortPick", m.label))) end
        sortLabel, sortW = full, fullW
        if edge * 2 + sortW + gap + buttonsW() > w then
            sortLabel, tight = modes[cur].label, true
            sortW = 0
            for _, m in ipairs(modes) do sortW = math.max(sortW, M.popupMenuW(m.label, true)) end
        end
    end
    -- still short of room: the greyed verbs leave the footer first (the card says what each
    -- needs), then the first ones; the main one always stays
    local room = w - edge * 2 - (showSort and (sortW + gap) or 0)
    local function dropOne(pred)
        for i, b in ipairs(_footBtns) do
            if pred(b) and i < #_footBtns then table.remove(_footBtns, i); return true end
        end
        return false
    end
    while buttonsW() > room and dropOne(function(b) return b.verb and not b.canDo end) do end
    while buttonsW() > room and dropOne(function() return true end) do end

    _footSpec.win = win
    local _, out = M.drawBand(panel, x, y, w, _footSpec)
    for i, b in ipairs(_footBtns) do
        local r = out.buttons[i]
        if r then
            if b.verb then
                local verb = b.id
                stamp(s, "mech:verb:" .. verb, r.x, r.y, r.w, r.h, function() pressVerb(win, s, cm, verb, chr) end,
                      { verb = verb, footer = true, disabled = b.disabled })
                if not isGamepad(ZeD.playerNumOf(win)) and hit(r, panel:getMouseX(), panel:getMouseY()) then s.verb = verb end
            else
                stamp(s, "mech:" .. b.id, r.x, r.y, r.w, r.h, b.fn, { footer = true, disabled = b.disabled })
                -- (a button's help comes under the mouse; a gray one says why under the controller's mark too)
                if b.disabled and s.gpId == "mech:" .. b.id then ZeD.Help.set(panel, b.help) end
            end
        end
    end

    if showSort then
        local by = y + T.px(5)
        local sx = x + edge
        local mx, my = panel:getMouseX(), panel:getMouseY()
        local hov = (not isGamepad(ZeD.playerNumOf(win))) and mx >= sx and mx < sx + sortW and my >= by and my < by + bh
        M.drawPopupMenu(panel, sx, by, sortW, bh, sortLabel, hov or s.sortOpen == true, focusFor(s, "mech:sortMenu"), false,
            modes[cur].label, tight)
        if hov then ZeD.Help.set(panel, ZeD.tr("UI_ZeD_Craft_SortHelp")) end
        stamp(s, "mech:sortMenu", sx, by, sortW, bh, function() s.sortOpen = not s.sortOpen end, { footer = true })
        s.sortGeo = { x = sx, y = by - M.popupListH(#modes), w = sortW, modes = modes, cur = modes[cur].id,
                      by = by, bh = bh }   -- (by, bh: the box, inside the list for ZeD.Popups)
    else
        s.sortOpen, s.sortGeo = nil, nil
    end
end

-- ZeD.Popups' hooks for the footer's Sort list (ZeD_Popups.lua)
function MT.sortIsOpen(s) return s.sortOpen == true end
function MT.closeSort(s) s.sortOpen = nil end

-- The footer's Sort list, open: drawn last, over the columns, upward from its box
local _sortListOpts = {}
local function renderSortList(panel, s, chr)
    local g = s.sortGeo
    if not (s.sortOpen and g) then return end
    local M = ZeD.Molecules
    local hoverId = nil
    if not isGamepad(chr and chr:getPlayerNum()) and s.sortZones then
        local mx, my = panel:getMouseX(), panel:getMouseY()
        for _, z in ipairs(s.sortZones) do if hit(z, mx, my) then hoverId = z.id end end
    end
    _sortListOpts.minW = g.w
    _sortListOpts.focusId = nil
    local gp = s.gpId
    if gp and gp:sub(1, 13) == "mech:sortRow:" then
        _sortListOpts.focusId = gp:sub(14)
        _sortListOpts.focus = focusFor(s, gp)
    end
    local lw, lh, zs = M.drawSortMenuList(panel, g.x, g.y, g.modes, g.cur, hoverId, _sortListOpts)
    s.sortZones = zs
    -- the list and its box count as inside; a press elsewhere, the tab hidden, an action or a walk shuts it
    -- (ZeD_Popups.lua, the director, Nov 23 2026)
    if ZeD.Popups then
        local po = ZeD.Popups.opts(s, "mech:sort", MT.sortIsOpen, chr and chr:getPlayerNum() or 0)
        ZeD.Popups.shownAt(po.key, panel, MT.closeSort, po, g.x, g.y, lw, lh, g.x, g.by, g.w, g.bh)
    end
    for _, z in ipairs(zs) do
        local id = z.id
        if z.disabled and hoverId == id then ZeD.Help.set(panel, condGateText()) end
        stamp(s, "mech:sortRow:" .. id, z.x, z.y, z.w, z.h, function()
            if z.disabled then return end
            s.sort, s.scrollY, s.sortOpen = id, 0, nil
            s.win._mechFocusTarget = "mech:sortMenu"
        end, { footer = true, sortRow = true })
    end
end

-- ----------------------------------------------------------------------------
-- The tab: the header, the two columns, the footer
-- ----------------------------------------------------------------------------
local MIN_RIGHT_W = 160   -- the right pane's least width beside the list; under it the two stack
--- Where the list and the right pane (the diagram or the part card) go in the body. Side by side the list is
--- the Craft tab's split (240u). On the half card (220u) that left the right pane a negative width (4K: 385 px
--- tab, 420 list, -37 right): the rows ran past the tab, and the card, the install picks and the NEEDS lines
--- drew nowhere while the footer's verbs still ran on the hidden pick. There the list sits over the right
--- pane, each the full width with its own scroll, half the height each, as the Cooking tab does (CK.layout,
--- QA K11). The controller moves between them as between columns. (QA M8, Nov 26 2026)
--- Returns { stacked, list = {x,y,w,h}, right = {x,y,w,h}, line = {w,h}, splitX, splitY }.
function MT.layout(x, top, w, bodyH)
    local T = ZeD.T
    local CC = ZeD.CraftingCore
    local split = T.px((CC and CC.PANE_W_SPLIT) or 240)
    local lw = T.px(1)
    if w >= split + lw + T.px(MIN_RIGHT_W) then
        return { stacked = false, line = { w = lw, h = bodyH },
                 list = { x = x, y = top, w = split, h = bodyH },
                 right = { x = x + split + lw, y = top, w = w - split - lw, h = bodyH },
                 splitX = x + split, splitY = nil }
    end
    local lh = math.max(0, math.floor((bodyH - lw) / 2))
    return { stacked = true, line = { w = w, h = lw },
             list = { x = x, y = top, w = w, h = lh },
             right = { x = x, y = top + lh + lw, w = w, h = math.max(0, bodyH - lh - lw) },
             splitX = nil, splitY = top + lh }
end

local function renderSplit(panel, win, s, x, y, w, h, v, chr, inspected)
    local T = ZeD.T
    local M = ZeD.Molecules
    local parts = cachedParts(s, v, chr)

    -- row 1: the vehicles' tab strip (punch list 175, C4: a tab per vehicle, as Animals picks Ranch or
    -- Butcher), at the row's foot; the shown vehicle's type as a tag at the right. A tab's press (or A)
    -- shows that vehicle; with one vehicle its tab is no stop.
    local headerH = T.stripH   -- row 1
    local tag = mechType(v)
    local tagW = 0
    if tag ~= "" then
        local pillH = T.px(16)
        tagW = ZeD.Atoms.tagW(tag, false)
        if tagW * 3 < w then
            M.drawTag(panel, x + w - T.px(10) - tagW, y + math.floor((headerH - pillH) / 2), tag, nil)
            tagW = tagW + T.px(16)
        else
            tagW = 0
        end
    end
    local items = MT.vehicleTabItems(s.vehicles)
    local gp = s.gpId
    _stripFocus.s = s
    _stripOpts.focus = gp and tonumber(gp:match("^mech:veh:(%d+)$") or "") or nil
    _stripOpts.rightReserve, _stripOpts.noHover, _stripOpts.win = tagW, isGamepad(ZeD.playerNumOf(win)), win
    local _, tabZones = ZeD.SubTabs.draw(panel, x, y + headerH - T.tabH, w, items, s.idx, _stripOpts)
    if #s.vehicles > 1 then
        for _, z in ipairs(tabZones) do
            stamp(s, "mech:veh:" .. z.idx, z.x, z.y, z.w, z.h, MT.vehicleTabFn(s, z.idx))
        end
    end

    -- the chosen part (only after an inspection; a part that is gone lets the card go)
    local cm = nil
    if s.card and inspected then
        local part = v:getPartById(s.card)
        if part then cm = cardModel(s, part, chr, v) else s.card = nil end
    elseif s.card then
        s.card = nil
    end
    s.cmPrimary = cm and cm.primary or nil   -- (the opened card's focus target, MT.focusTargetIndex; QA M5)

    -- the tab's own actions, for the footer with no part chosen
    local hood = inspected and v:getPartById("EngineDoor") or nil
    local hoodOpen = hood and hood:getDoor() and hood:getInventoryItem() and hood:getDoor():isOpen()
    local barVerbs = {
        { id = "inspect", label = getText("ContextMenu_Inspect"), variant = "primary", canDo = true, sensible = not inspected,
          help = ZeD.tr("UI_ZeD_Veh_HelpInspect"),
          fn = function() if not refusePaused(chr) then ISVehicleMenu.onMechanic(chr, v) end end },   -- (M12)
        { id = "closehood", label = getText("IGUI_CloseHood"), canDo = true, sensible = hoodOpen and true or false,
          help = ZeD.tr("UI_ZeD_Veh_HelpCloseHood"),
          fn = function()
              if refusePaused(chr) then return end   -- (M12)
              ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(chr, v, hood:getArea()))
              ISTimedActionQueue.add(ISCloseVehicleDoor:new(chr, v, hood))
              local e = INSP[v:getId()]
              if e then e.hood = nil end
          end },
    }
    local barShown = ZeD.Disclose.split(barVerbs)
    if ZeD.ExtrasCards then ZeD.ExtrasCards.vehicleBar(barShown, s, win, v) end   -- (a server's vehicle claims)
    local hasFooter = inspected or cm ~= nil or #barShown > 0
    local bandH = hasFooter and M.bandH() or 0

    local top = y + headerH
    local TR = ZeD.MechTrailer
    local trailer = TR.isTrailer(v)
    if trailer then TR.prepare(s, v, chr) end
    local pbH = inspected and progressBand(panel, win, s, x, top, w, v, chr) or 0
    if pbH == 0 and trailer then pbH = TR.drawBand(panel, s, x, top, w, v, chr) end
    top = top + pbH
    local bodyH = h - headerH - pbH - bandH

    -- the columns: CraftingCore's split measure for the list, the rest for the right; on the half card the
    -- list over the right pane (MT.layout, QA M8)
    local L = MT.layout(x, top, w, bodyH)
    local LP, RP = L.list, L.right
    s.splitX, s.splitY = L.splitX, L.splitY

    -- what is lit: the controller's row, or the row or diagram part under the pointer
    local mx, my = panel:getMouseX(), panel:getMouseY()
    local free = (not isGamepad(ZeD.playerNumOf(win))) and not s.sortOpen
    local inList = free and hit(LP, mx, my)
    local inRight = free and hit(RP, mx, my)
    local gpId = s.gpId
    local hl = nil
    if gpId and gpId:sub(1, 9) == "mech:row:" then hl = gpId:sub(10) end
    if inList then
        for _, z in ipairs(s.lastRows or {}) do if hit(z, mx, my) then hl = z.part end end
    elseif inRight and not cm then
        hl = figurePartAt(s, mx, my)
    end
    s.hl = hl

    renderList(panel, win, s, LP.x, LP.y, LP.w, LP.h, v, chr, inspected, parts, trailer, inList and { x = mx, y = my } or nil)
    local bd, ln = T.borderS, L.line
    if L.stacked then
        panel:drawRect(x, LP.y + LP.h, w, ln.h, bd.a or 1, bd.r, bd.g, bd.b)
    else
        panel:drawRect(LP.x + LP.w, top, ln.w, bodyH, bd.a or 1, bd.r, bd.g, bd.b)
    end
    if cm then
        renderCardBody(panel, win, s, RP.x, RP.y, RP.w, RP.h, v, chr, cm)
    else
        renderDiagram(panel, win, s, RP.x, RP.y, RP.w, RP.h, v, chr, inspected, parts, trailer)
    end

    -- gamepad scroll-follow, in the column the focused element is in
    if not (gpId and s.byId[gpId] and s.byId[gpId].pane == "right") then s._followRight = nil end
    if gpId then
        local z = s.byId[gpId]
        if z and z.clip then
            local c = z.clip
            if z.pane == "right" then
                -- (Nov 16 2026, punch list 258: once, as the focus lands, so the pad scroll (FocusManager.lua) can
                -- bring the lines above the first verb into view without this pulling the card back)
                if s._followRight ~= gpId then
                    s._followRight = gpId
                    if z.y < c.y then s.cardScroll = math.max(0, s.cardScroll - (c.y - z.y))
                    elseif z.y + z.h > c.y + c.h then s.cardScroll = math.min(s.maxRight or 0, s.cardScroll + (z.y + z.h - (c.y + c.h))) end
                end
            else
                s._followRight = nil
                if z.y < c.y then s.scrollY = math.max(0, s.scrollY - (c.y - z.y))
                elseif z.y + z.h > c.y + c.h then s.scrollY = math.min(s.maxScroll or 0, s.scrollY + (z.y + z.h - (c.y + c.h))) end
            end
        end
    end

    if hasFooter then renderFooter(panel, win, s, x, y + h - bandH, w, v, chr, inspected, cm, barShown) end
    renderSortList(panel, s, chr)
end

-- ----------------------------------------------------------------------------
-- Shared helpers for MechTrailer.lua (the animal trailer page)
-- ----------------------------------------------------------------------------
MT._h = {
    stamp = stamp, dotLine = dotLine, drawScrollbar = drawScrollbar, markAt = markAt, focusFor = focusFor,
    vehicleName = vehicleName, overallCond = overallCond, now = now, progressBand = progressBand,
    miniBar = miniBar, cased = cased,
}
-- For the sims only (ZeDUI/tools/qa/summercar_sim.lua): these are file locals.
MT._test = { verbsFor = verbsFor, needsFor = needsFor, runVerb = runVerb, partContextMenu = partContextMenu,
             cardModel = cardModel, chainBusy = chainBusy, pressVerb = pressVerb, pickedInstall = pickedInstall }

-- ----------------------------------------------------------------------------
-- Entry: renderer registered in the World window's dispatch table
-- ----------------------------------------------------------------------------
function MT.render(panel, win, x, y, w, h)
    local T = ZeD.T
    if not T then return end
    local s = st(win)
    s.zones, s.byId = {}, {}
    s.panel, s.gpId, s.win = panel, gpFocusedId(win), win
    local TR = ZeD.MechTrailer
    local chr = win._playerObj or getSpecificPlayer(win.playerNum or 0)
    local e = currentEntry(s)
    if s.view ~= "animal" then TR.hideAvatar(s) end
    if not chr or not e or not e.vehicle or carGone(e.vehicle) then   -- (QA B7-6)
        TR.hideAvatar(s)
        -- nothing to list: one dim sentence at the text inset
        local pad0 = T.px(PAD)
        ZeD.Molecules.drawEmptyLine(panel, x + pad0, y + T.px(8), w - pad0 * 2, ZeD.tr("UI_ZeD_Veh_NoVehicleReach"))
        return
    end
    local v = e.vehicle
    local inspected = INSP[v:getId()] ~= nil
    if s.view == "animal" then
        if TR.isTrailer(v) and TR.renderAnimal(panel, win, s, x, y, w, h, v, chr) then return end
        TR.hideAvatar(s)
        s.view, s.animal, s.animalId = "overview", nil, nil
    end
    s.view = "overview"
    renderSplit(panel, win, s, x, y, w, h, v, chr, inspected)
end

function MT.register(dispatch)
    -- wrapper, so a hot-reloaded module replaces the renderer the window calls
    dispatch["vehicle"] = function(...) return ZeD.MechanicsTab.render(...) end
end

-- ----------------------------------------------------------------------------
-- Mouse
-- ----------------------------------------------------------------------------
function MT.onClick(win, x, y)
    local s = st(win)
    -- the Sort list, open: a press on one of its choices picks it, anywhere else shuts it
    if s.sortOpen then
        for i = #s.zones, 1, -1 do
            local z = s.zones[i]
            if (z.sortRow or z.id == "mech:sortMenu") and hit(z, x, y) then
                pcall(function() ZeD.uiSound("UIActivateButton") end)
                z.fn()
                return true
            end
        end
        s.sortOpen = nil
        return true
    end
    for i = #s.zones, 1, -1 do
        local z = s.zones[i]
        if hit(z, x, y) and (not z.clip or hit(z.clip, x, y)) then
            if not z.disabled then pcall(function() ZeD.uiSound("UIActivateButton") end) end
            z.fn()
            return true
        end
    end
    -- a part on the diagram chooses it, as its row does
    if not s.card and s.figClip and hit(s.figClip, x, y) then
        local id = figurePartAt(s, x, y)
        local e = currentEntry(s)
        if id and e and INSP[e.id] then openCard(win, s, id); return true end
    end
    return true
end

function MT.onRightClick(win, x, y)
    local s = st(win)
    local chr = win._playerObj or getSpecificPlayer(win.playerNum or 0)
    local e = currentEntry(s)
    if not chr or not e or not INSP[e.id] or s.view == "animal" then return true end
    local id = nil
    for _, z in ipairs(s.lastRows or {}) do if hit(z, x, y) and hit(z.clip, x, y) then id = z.part end end
    if not id then
        if s.card and s.rightClip and hit(s.rightClip, x, y) then id = s.card
        elseif not s.card and s.figClip and hit(s.figClip, x, y) then id = figurePartAt(s, x, y) end
    end
    -- (at the press's own point on screen, not the pointer: a pad's X arrives here too, with the pointer hidden at
    -- 0,0, and the menu opened in the corner. QA M11 second pass, Nov 26 2026)
    local ax, ay = nil, nil
    if s.panel then ax, ay = s.panel:getAbsoluteX() + x, s.panel:getAbsoluteY() + y end
    if id then partContextMenu(e.vehicle:getPartById(id), chr, win, ax, ay) end
    return true
end

-- The wheel scrolls the column under the pointer; it never closes the card
function MT.onMouseWheel(win, del)
    local s = st(win)
    local step = ZeD.T.px(SCROLL_STEP) * del
    if s.view == "animal" then
        s.cardScroll = math.max(0, math.min(s.maxScroll or 0, s.cardScroll + step))
        return true
    end
    local mx = s.panel and s.panel:getMouseX() or 0
    local my = s.panel and s.panel:getMouseY() or 0
    if (s.splitX and mx > s.splitX) or (s.splitY and my > s.splitY) then   -- (stacked on the half card: QA M8)
        s.cardScroll = math.max(0, math.min(s.maxRight or 0, s.cardScroll + step))
    else
        s.scrollY = math.max(0, math.min(s.maxScroll or 0, s.scrollY + step))
    end
    return true
end

-- ----------------------------------------------------------------------------
-- Gamepad: elements from this frame's stamped zones. A on a row chooses the part (its
-- card in the right column), B shuts the card (or the open Sort list); B with neither
-- leaves the tab as before.
-- ----------------------------------------------------------------------------
-- B with the part menu up shuts the menu and nothing else, whatever drives the pad. The hand-back above needs
-- a joined pad (setJoypadFocus); with none, B went on to the card and the menu stayed up (QA M11 second pass,
-- Nov 26 2026). Returns true when it shut one.
local function closePartMenu(s)
    local ctx = s and s.partMenu
    if not ctx then return false end
    s.partMenu = nil
    local shown = false
    pcall(function() shown = ctx:getIsVisible() end)
    if not shown then return false end
    pcall(function() ctx:setVisible(false) end)
    pcall(function() if ctx.hideAndChildren then ctx:hideAndChildren() end end)
    return true
end
MT.closePartMenu = closePartMenu

-- The screen point for the game's part menu opened from the pad: the focused stop's lower left, not the
-- hidden pointer (QA M11, Nov 26 2026)
local function padMenuAt(s, z)
    local p = s.panel
    if not (p and z) then return nil, nil end
    return p:getAbsoluteX() + z.x, p:getAbsoluteY() + z.y + z.h
end

function MT.buildFocusables(win)
    local s = win and win._mech
    if not s then return {} end
    local chr = win._playerObj or getSpecificPlayer(win.playerNum or 0)
    local els = {}
    for _, z in ipairs(s.zones) do
        local zz = z
        -- with the Sort list open the pad walks its choices and its box only
        if not s.sortOpen or zz.sortRow or zz.id == "mech:sortMenu" then
            local el = { x = zz.x, y = zz.y, w = zz.w, h = zz.h, id = zz.id,
                         isDisclosure = zz.isDisclosure, disabled = zz.disabled,
                         onActivate = function() zz.fn() end }
            if s.view == "animal" then
                el.onCancel = function() ZeD.MechTrailer.closeAnimal(win, s); return true end
            elseif s.sortOpen then
                el.onCancel = function() s.sortOpen = nil; win._mechFocusTarget = "mech:sortMenu"; return true end
            elseif s.confirm or s.card then
                el.onCancel = function()
                    if s.confirm == "xrelease" then win._mechFocusTarget = "mech:xrelease" end
                    if s.confirm then s.confirm = nil else closeCard(win, s) end
                    return true
                end
            end
            -- (B shuts an open part menu first; with none up it does what it did: false lets the window's own B run)
            do
                local inner = el.onCancel
                el.onCancel = function(w2, e2)
                    if closePartMenu(s) then return true end
                    if inner then return inner(w2, e2) end
                    return false
                end
            end
            if zz.isRow then
                el.onContextMenu = function()
                    local e = currentEntry(s)
                    local ax, ay = padMenuAt(s, zz)
                    if e and chr then partContextMenu(e.vehicle:getPartById(zz.part), chr, win, ax, ay) end
                end
            elseif s.card and zz.verb then
                el.onContextMenu = function()
                    local e = currentEntry(s)
                    local ax, ay = padMenuAt(s, zz)
                    if e and chr and s.card then partContextMenu(e.vehicle:getPartById(s.card), chr, win, ax, ay) end
                end
            end
            -- (Nov 16 2026, punch list 258: the right column, the part card or the diagram, is one scrolled view:
            -- Up from its first verb shows the lines above it, Down past its last reads on (FocusManager.lua))
            -- (the card's verbs in the band read it too, for a card with no stop of its own in the column)
            local rc = (zz.pane == "right" and zz.clip)
                or (s.card and type(zz.id) == "string" and zz.id:sub(1, 10) == "mech:verb:" and s.rightClip) or nil
            if rc and not s.sortOpen and (s.maxRight or 0) > 0 then
                local Fo = ZeD.Input and ZeD.Input.Focus
                local c = rc
                el.scrollView = Fo and Fo.scrollView and Fo.scrollView("mech:right", c.y, c.h, s.cardScroll or 0, s.maxRight,
                    function(n) s.cardScroll = n end) or nil
                el.scrollFixed = (zz.pane ~= "right") or nil   -- (a verb in the band stays where it is)
            end
            els[#els + 1] = el
        end
    end
    return els
end

-- Signature for the World window's per-frame refresh: rebuild when the chosen part,
-- a scroll offset or the element set changes.
function MT.focusKey(win)
    local s = win and win._mech
    if not s then return "none" end
    return tostring(s.view) .. ":" .. tostring(s.card) .. ":" .. tostring(math.floor(s.scrollY or 0)) .. ":"
        .. tostring(math.floor(s.cardScroll or 0)) .. ":" .. tostring(s.confirm) .. ":" .. tostring(#s.zones) .. ":" .. tostring(s.idx)
        .. ":" .. tostring(s.animalId) .. ":" .. tostring(s.sortOpen) .. ":" .. tostring(s.verb) .. ":" .. tostring(s.xbar)
end

-- Focus target after a change (card opened -> its first lit verb; card closed -> its row;
-- the Sort list shut -> its box)
function MT.focusTargetIndex(win, els)
    local t = win and win._mechFocusTarget
    if not t then return nil end
    -- the new view's zones appear a frame later: keep the target until it lands
    win._mechFocusTries = (win._mechFocusTries or 0) + 1
    local found = ZeD.MechTrailer.focusTarget(t, els)
    if not found and t == "card" then
        -- (QA M5, Nov 26 2026: the footer draws the main verb last, so the first lit stop was a secondary one and
        -- A A deflated a tire or took the engine's parts; the main (accent) verb first)
        local s = win._mech
        local main = s and s.cmPrimary and ("mech:verb:" .. s.cmPrimary) or nil
        if main then
            for i, e in ipairs(els) do
                if e.id == main and not e.disabled then found = i; break end
            end
        end
    end
    if not found and t == "card" then
        local firstVerb = nil
        for i, e in ipairs(els) do
            if e.id:sub(1, 10) == "mech:verb:" then
                if not e.disabled then found = i; break end
                firstVerb = firstVerb or i
            end
        end
        found = found or firstVerb
        if not found then
            for i, e in ipairs(els) do
                if e.id == "mech:step" or e.id:sub(1, 9) == "mech:pick" or e.id:sub(1, 8) == "mech:fix" then found = i; break end
            end
        end
    end
    if not found then
        for i, e in ipairs(els) do if e.id == t then found = i; break end end
    end
    if found or win._mechFocusTries > 10 then
        win._mechFocusTarget, win._mechFocusTries = nil, 0
    end
    return found
end

-- ----------------------------------------------------------------------------
-- Vanilla entry (Overrides/VehicleMechanics.lua): the inspect action finished
-- ----------------------------------------------------------------------------
function MT.openFromAction(chr, vehicle, usedHood)
    if not chr or not vehicle then return false end
    if not (ZeD_WorldWindow and ZeD_WorldWindow.open and ZeD_WorldWindow.getWindow) then return false end
    local pn = chr:getPlayerNum()
    local vid = vehicle:getId()
    local prev = INSP[vid]
    INSP[vid] = { vehicle = vehicle, hood = usedHood or (prev and prev.hood) }
    setMechOpen(vehicle, true, chr)
    if not ZeD_WorldWindow.isOpen(pn) then
        local ok = pcall(ZeD_WorldWindow.open, pn)
        if not ok then return false end
    end
    local win = ZeD_WorldWindow.getWindow(pn)
    if not win then return false end
    local s = st(win)
    s.pendingId = vid
    MT.refresh(win)
    s.view, s.card, s.confirm = "overview", nil, nil
    -- the inspection brings the tab into view as the tab's key does: the halves unfolded (a side rolled by hand stays),
    -- the window unrolled, its hover roll-up held from now (an unpinned window rolls up while the pointer is on the
    -- world, and an active Vehicle tab rolled away showed nothing: QA b12 round 2)
    if win._halves and ZeD.Halves and ZeD.Halves.showAll then ZeD.Halves.showAll(win) end
    if win.windowShaded then win._autoShaded = false; win:setWindowShaded(false) end
    win._outSince = getTimestampMs() + 500
    -- the tab strip stamps its hit zones while drawing: try now, then for a few ticks
    local tries = 0
    local function attempt()
        tries = tries + 1
        if win._activeTab == "vehicle" then return true end
        local strip = win._actionTabStrip
        if strip and strip._hitZones then
            for _, z in ipairs(strip._hitZones) do
                if z.id == "tab:vehicle" then strip:onMouseDown(z.x + 2, z.y + 2); return true end
            end
        end
        return false
    end
    if not attempt() then
        local function tick()
            if attempt() or tries >= 20 then Events.OnTick.Remove(tick) end
        end
        Events.OnTick.Add(tick)
    end
    return true
end

function MT.isInspected(vehicle)
    return vehicle ~= nil and INSP[vehicle:getId()] ~= nil
end

-- Vanilla entry (Overrides/TrailerAnimals.lua): Check Animal(s) in Trailer.
-- Opens the Vehicle tab on the trailer, scrolled to its animals.
function MT.openTrailer(chr, vehicle)
    if not chr or not vehicle then return false end
    if not (ZeD_WorldWindow and ZeD_WorldWindow.openTab and ZeD_WorldWindow.getWindow) then return false end
    PIN[vehicle:getId()] = vehicle
    if not ZeD_WorldWindow.isOpen(chr:getPlayerNum()) then
        local ok = pcall(ZeD_WorldWindow.open, chr:getPlayerNum())
        if not ok then return false end
    end
    local win = ZeD_WorldWindow.getWindow(chr:getPlayerNum())
    if not win then return false end
    local s = st(win)
    s.pendingId = vehicle:getId()
    MT.refresh(win)
    ZeD.MechTrailer.hideAvatar(s)
    s.view, s.card, s.confirm, s.animal, s.animalId = "overview", nil, nil, nil, nil
    s.collapsed["_animals"] = nil
    s.showAnimals = true
    win._mechFocusTarget = "animals"
    ZeD_WorldWindow.openTab(chr:getPlayerNum(), "vehicle")
    return true
end

-- Success / failure of an install or uninstall (vanilla flashes its window)
if Events and Events.OnMechanicActionDone then
    Events.OnMechanicActionDone.Add(function(chr, success)
        -- the window of the character whose action finished
        local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow(chr and chr:getPlayerNum())
        if not win then return end
        local s = st(win)
        s.flash = { ok = success and true or false, untilMs = now() + FLASH_MS }
        s.items = nil
        s.needsCache, s.fixCache, s.partsCache = nil, nil, nil
    end)
end

print("[ZeD] MechanicsTab: Vehicle tab loaded")
return MT
