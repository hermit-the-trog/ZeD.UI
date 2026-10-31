-- ZeD-UI/42/media/lua/client/ZeD/MechanicsTab.lua
-- ============================================================================
-- VEHICLE TAB — World window, contextual (replaces vanilla ISVehicleMechanics)
-- Contract: ZeDUI/mockups/zed_vehicle_mechanics_v1.html (approved Oct 13 2026,
-- director: "go with your recommendations, build it").
--
-- Shape follows the Health tab: a car figure (scanline layers baked from the
-- vanilla mechanics overlay by ZeDUI/tools/mechanics/bake_mech_figs.py) beside
-- a summary, then every part grouped by area. A part opens as a 480-wide item
-- card: back arrow, name, verbs in the header, the progress band, a stat grid,
-- an install pick list or the repair recipes, a NEEDS checklist for the
-- highlighted verb, and the part's vanilla info text. Destructive verbs confirm
-- in the footer. X / right-click on a part opens vanilla's own part menu, which
-- ZeD's context-menu hook renders.
--
-- Entry: Overrides/VehicleMechanics.lua routes ISOpenMechanicsUIAction:perform
-- (right-click Mechanics, the hood, the mechanics key) to MT.openFromAction.
-- Before an inspection the tab shows only what can be seen from outside and an
-- INSPECT button (vanilla's walk-over-and-look action). An inspection lasts
-- until the player is more than six tiles away, as vanilla closes its window.
--
-- Every layout number is a DESIGN UNIT and goes through T.px at use (S124).
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/MechFigs"
require "ZeD/MechTrailer"

ZeD = ZeD or {}
ZeD.MechanicsTab = ZeD.MechanicsTab or {}
local MT = ZeD.MechanicsTab

-- ----------------------------------------------------------------------------
-- Constants (design units unless noted)
-- ----------------------------------------------------------------------------
local REACH_TILES   = 4.5    -- tiles from the vehicle centre: the tab offers it
local KEEP_TILES    = 6      -- tiles: an inspection lasts until you walk past this (vanilla)
local PAD           = 10
local FIG_W, FIG_H  = 120, 244
local COL_GAP       = 12
local ROW_H         = 24
local CAT_H         = 15     -- the library's category row
local COLHDR_H      = 20
local SEC_H         = 20
local PICK_H        = 26
local FIX_H         = 38
local MINI_BAR_W    = 40
local PCT_W         = 34
local SCROLL_STEP   = 48
local FLASH_MS      = 1600
local ITEMS_TTL_MS  = 700

local CAT_ORDER = { "engine", "gastank", "tire", "brakes", "suspension", "lights",
                    "door", "bodywork", "seat", "dashboard", "trunk", "Other" }
local CAT_RANK = {}
for i, c in ipairs(CAT_ORDER) do CAT_RANK[c] = i end

local DOT = "|"   -- the separator: ZeD OS's pipe (director, Oct 16 2026: no middle dots)

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
local function statusColor(T, pct)
    if pct > 60 then return T.positive elseif pct > 30 then return T.warning end
    return T.danger
end
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
local function isGamepad()
    local D = ZeD and ZeD.Input and ZeD.Input.Detector
    return (D and D.getMode and D.getMode() == "gamepad") or false
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

local function endInspection(vid, chr)
    local e = INSP[vid]
    INSP[vid] = nil
    if not e then return end
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
        if v and v:getSquare() and math.floor(v:getZ()) == cz then
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
            if o and o:getSquare() and not have[o:getId()] then
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
    return chr ~= nil and v ~= nil and v:getSquare() ~= nil
        and math.floor(v:getZ()) == math.floor(chr:getZ()) and distTo(chr, v) <= REACH_TILES
end

-- Called by the World window's periodic refresh (beside the radio list).
function MT.refresh(win)
    if not win then return end
    local s = st(win)
    local chr = win._playerObj or getSpecificPlayer(0)
    if not chr then return end
    local cur = currentEntry(s)
    local curId = cur and cur.id
    s.vehicles = MT.buildVehicles(chr)
    -- inspections end past six tiles or when the vehicle is gone
    for vid, e in pairs(INSP) do
        local v = e.vehicle
        local alive = v and v:getSquare() ~= nil
        if not alive or distTo(chr, v) > KEEP_TILES then endInspection(vid, chr) end
    end
    for vid, v in pairs(PIN) do
        if not v:getSquare() or distTo(chr, v) > KEEP_TILES then PIN[vid] = nil end
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

local function collectParts(v, chr)
    local list = {}
    for i = 0, v:getPartCount() - 1 do
        local part = v:getPartByIndex(i)
        local cat = part:getCategory() or "Other"
        if cat ~= "nodisplay" then
            local m = partModel(part, chr, v)
            m.order = i
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

local function keyState(v, chr)
    local eng = v:getPartById("Engine")
    local ok, have = pcall(function() return chr:getInventory():haveThisKeyId(v:getKeyId()) end)
    if ok and have then return ZeD.tr("UI_ZeD_Veh_KeyOnYou"), "pos" end
    if v:isHotwired() then return ZeD.tr("UI_ZeD_Veh_KeyHotwired"), "pos" end
    if eng and VehicleUtils.RequiredKeyNotFound(eng, chr) then return ZeD.tr("UI_ZeD_Veh_NotFound"), "warn" end
    return ZeD.tr("UI_ZeD_Veh_KeyNotNeeded"), "pos"
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
    takeParts = "UI_ZeD_Veh_HelpTakeParts", repairLightbar = "UI_ZeD_Veh_HelpRepairLightbar",
}
local DANGER = { smash = true, takeParts = true }
-- Which available verb is the call to action (accent fill), in this order
local PRIMARY_ORDER = { "install", "fix", "repairEngine", "repairLightbar", "inflate", "uninstall",
                        "openWindow", "closeWindow", "deflate" }

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
    if kv.requireUninstalled then
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
    local key = tostring(part:getId()) .. ":" .. tostring(verb) .. ":" .. tostring(s.pick) .. ":" .. tostring(s.fixPick)
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
    local engLevel = v:getScript():getEngineRepairLevel()
    if verb == "install" or verb == "uninstall" then
        if verb == "install" then
            local picks = installPicks(part, chr, items)
            local pick = picks[s.pick]
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
        local ks = keyState(v, chr)
        rows[#rows + 1] = { ok = not keyMissing, label = getText("IGUI_ItemType_Key"), value = keyMissing and ZeD.tr("UI_ZeD_Veh_NotFound") or ks }
        for _, r in ipairs(rows) do if not r.ok and not r.soft then ok = false end end
        if verb == "takeParts" then rows[#rows + 1] = { ok = false, soft = true, label = ZeD.tr("UI_ZeD_Veh_LowersEngine"), value = "" } end
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
    else
        rows[#rows + 1] = { ok = true, label = ZeD.tr("UI_ZeD_Veh_NothingNeeded"), value = "" }
    end
    local blocker = nil
    for _, r in ipairs(rows) do if not r.ok and not r.soft then blocker = r; break end end
    return { rows = rows, chance = { success, failure }, ok = ok, blocker = blocker }
end

-- ----------------------------------------------------------------------------
-- Running verbs (vanilla handlers do the walking, equipping and queueing)
-- ----------------------------------------------------------------------------
local function runVerb(s, verb, part, chr)
    if not part then return end
    if verb == "install" then
        local picks = installPicks(part, chr, itemsFor(s, chr))
        local pick = picks[s.pick]
        if pick and pick.item then ISVehiclePartMenu.onInstallPart(chr, part, pick.item) end
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
    end
    s.items = nil   -- tools and parts move; re-read next frame
    s.needsCache, s.fixCache, s.partsCache = nil, nil, nil
end

-- Vanilla's own part menu, rendered by ZeD's context-menu hook (X / right-click)
local function partContextMenu(part, chr)
    local ui = getPlayerMechanicsUI(chr:getPlayerNum())
    if not ui or not part then return end
    ui.vehicle = part:getVehicle()
    ui.chr = chr
    local ax, ay = getMouseX() - ui:getAbsoluteX(), getMouseY() - ui:getAbsoluteY()
    pcall(ui.doPartContextMenu, ui, part, ax, ay)
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
local _browseOpts = { focusParts = {} } -- the drawer header's previous / next keys
local _backOpts = {}                   -- the card back bar's back key

-- ----------------------------------------------------------------------------
-- Car figure
-- ----------------------------------------------------------------------------
-- forward-declared together: drawFigure and the card icon both use them (Kahlua captures at creation)
local overlayInfo, partImgs, tex
local TEX = {}
tex = function(name)
    local t = TEX[name]
    if t == nil then
        t = getTexture("media/textures/ZeD/mech/zm_" .. name .. ".png") or false   -- zm_: vanilla packs share the base names
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
    local gb = tex("gridbox")
    if gb then panel:drawTextureScaledAspect(gb, fx, fy, fw, fh, 0.30, dim.r, dim.g, dim.b) end
    local prefix, props = overlayInfo(v)
    local F = ZeD.MechFigs
    local U = prefix and F and F.unions and F.unions[prefix]
    if not U then return end
    local sc = math.min(fw / U.w, fh / U.h)
    local ox = fx + math.floor((fw - U.w * sc) / 2)
    local oy = fy + math.floor((fh - U.h * sc) / 2)
    local function rectOf(key)
        local L = F.layers[key]
        if not L then return nil end
        return ox + (L.x - U.x) * sc, oy + (L.y - U.y) * sc, L.w * sc, L.h * sc
    end
    local bt = tex(prefix .. "base")
    local bx, by, bw, bh = rectOf(prefix .. "base")
    if bt and bx then panel:drawTextureScaledAspect(bt, bx, by, bw, bh, 0.45, dim.r, dim.g, dim.b) end
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
                        else c, a = statusColor(T, p.cond), 0.95 end
                        panel:drawTextureScaledAspect(t, lx, ly, lw, lh, a, c.r, c.g, c.b)
                        if hlId == p.id or workId == p.id then
                            local full = tex(key) or t
                            panel:drawTextureScaledAspect(full, lx, ly, lw, lh, 0.75, ac.r, ac.g, ac.b)
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
                s.figZones[#s.figZones + 1] = { id = p.id, x = x0 - g, y = y0 - g, w = (x1 - x0) + g * 2, h = (y1 - y0) + g * 2 }
            end
        end
    end
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
    panel:drawText(cased(label), x, y, lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)
    ZeD.Atoms.drawTextRight(panel, value, x + w, y, T.fontF3, tc)
    return math.max(T.fontF1H, T.fontF3H)
end

local function dotLine(panel, x, y, color, text, font)
    local T = ZeD.T
    font = font or T.fontF2
    local fh = ZeD.TM:getFontHeight(font)
    local d = T.px(7)
    ZeD.Atoms.drawStatusDot(panel, x, y + math.floor((fh - d) / 2), color, d)
    local tc = T.text
    panel:drawText(text, x + d + T.px(6), y, tc.r, tc.g, tc.b, tc.a or 1, font)
    return fh
end

-- A condition bar for a list row: the framed strip at the compact height, centred
-- on cy, ten segments graduated (green over 60, amber over 30, red below); its help
-- line "Condition 64%"
local function miniBar(panel, x, cy, w, pct)
    local A = ZeD.Atoms
    local h = A.fillBarCompactH()
    A.drawFillBar(panel, x, cy - math.floor(h / 2), w, math.max(0, math.min(1, pct / 100)), true, nil, h,
        ZeD.tr("IGUI_invpanel_Condition"))
end

-- The timed action now running on this vehicle (nil when idle)
local function activeAction(chr, v)
    local q = ISTimedActionQueue.getTimedActionQueue(chr)
    local a = q and q.queue and q.queue[1]
    if a and a.jobType and a.jobType ~= "" then
        if (a.vehicle == v) or (a.part and a.part.getVehicle and a.part:getVehicle() == v) then return a end
    end
    return nil
end

-- Progress band for the running vehicle action, then the success / failure flash
local function progressBand(panel, win, s, x, y, w, v, chr)
    local a = activeAction(chr, v)
    if a then
        do
            local pct = 0
            pcall(function() pct = a:getJobDelta() end)
            local rect = {}
            _cancelOpts.focus = focusFor(s, "mech:cancel")   -- Cancel's mark, drawn under its icon
            local h = ZeD.Atoms.drawProgressBand(panel, x, y, w, "active", cased(a.jobType), pct, nil, rect, false, _cancelOpts)
            if rect.w then
                stamp(s, "mech:cancel", rect.x, rect.y, rect.w, rect.h, function()
                    pcall(function() ISTimedActionQueue.clear(chr) end)
                end)
            end
            s.working = a.part and a.part.getId and a.part:getId() or nil
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

local function drawScrollbar(panel, x, top, h, total, scrollY)
    local T = ZeD.T
    local A = ZeD.Atoms
    if total <= h then return end
    local sw = T.sp.scrollbarW
    A.drawScrollTrack(panel, x, top, sw - T.px(2), h)
    local barH = math.max(T.px(20), math.floor(h * (h / total)))
    local maxS = total - h
    local frac = maxS > 0 and (scrollY / maxS) or 0
    A.drawScrollThumb(panel, x, top + math.floor((h - barH) * frac), sw - T.px(2), barH)
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
            A.drawSegFill(panel, sx, yy, sw, T.fillBarH, A.FILL_SEGS, 0)   -- (no reading: "-" above it)
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
            yy = yy + M.drawStatRow(panel, sx, yy, sw, getText("IGUI_Item"), item:getDisplayName())
        end
        if p.info and p.info ~= "" then yy = yy + M.drawStatRow(panel, sx, yy, sw, ZeD.tr("UI_ZeD_Veh_State"), p.info) end
        if p.id == "Engine" then
            yy = yy + M.drawStatRow(panel, sx, yy, sw, getText("Attributes_Type_Quality"), tostring(v:getEngineQuality()))
            yy = yy + M.drawStatRow(panel, sx, yy, sw, ZeD.tr("UI_ZeD_Veh_Power"), ZeD.tr("UI_ZeD_Veh_Hp", round(v:getEnginePower() / 10, 0)))
        end
        if p.part:getWheelFriction() > 0 and item then
            yy = yy + M.drawStatRow(panel, sx, yy, sw, ZeD.tr("UI_ZeD_Veh_Friction"), tostring(round(p.part:getWheelFriction(), 2)))
        end
        return
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
    yy = yy + dotLine(panel, sx, yy, dc, line) + T.px(8)
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
end

local function groupedParts(s, parts)
    local groups, byCat = {}, {}
    if s.sort == "cond" then
        local all = {}
        for _, p in ipairs(parts) do all[#all + 1] = p end
        table.sort(all, function(a, b)
            local ca = (a.missing or a.smashed) and -1 or a.cond
            local cb = (b.missing or b.smashed) and -1 or b.cond
            if ca == cb then return a.order < b.order end
            return ca < cb
        end)
        groups[1] = { cat = "_worst", label = ZeD.tr("UI_ZeD_Veh_WorstFirst"), parts = all }
        return groups
    end
    for _, p in ipairs(parts) do
        local g = byCat[p.cat]
        if not g then
            g = { cat = p.cat, label = catLabel(p.cat), parts = {} }
            byCat[p.cat] = g
            groups[#groups + 1] = g
        end
        g.parts[#g.parts + 1] = p
    end
    table.sort(groups, function(a, b)
        local ra, rb = CAT_RANK[a.cat] or 99, CAT_RANK[b.cat] or 99
        if ra == rb then return a.label < b.label end
        return ra < rb
    end)
    return groups
end

local function openCard(win, s, id)
    s.view, s.card, s.verb, s.confirm = "card", id, nil, nil
    s.cardScroll, s.pick, s.fixPick = 0, 1, 1
    s.items = nil
    s.needsCache, s.fixCache, s.partsCache = nil, nil, nil
    win._mechFocusTarget = "card"
end
local function closeCard(win, s)
    s.view, s.confirm = "overview", nil
    s.needsCache, s.fixCache, s.partsCache = nil, nil, nil
    win._mechFocusTarget = s.card and ("mech:row:" .. s.card) or nil
    s.card = nil
end

local function renderOverview(panel, win, s, x, y, w, h, v, chr, inspected)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local TM = ZeD.TM
    local parts = cachedParts(s, v, chr)

    -- header: browse + vehicle name + type tag
    _browseOpts.focusParts.prev = focusFor(s, "mech:prev")
    _browseOpts.focusParts.next = focusFor(s, "mech:next")
    local prevZ, nextZ = M.drawDrawerInternalHeader(panel, x, y, w,
        { idx = s.idx, total = #s.vehicles }, vehicleName(v), mechType(v), nil, _browseOpts)
    local headerH = T.px((ZeD.Spacing and ZeD.Spacing.tabHeaderH) or 37)
    if #s.vehicles > 1 then
        stamp(s, "mech:prev", prevZ.x, prevZ.y, prevZ.w, prevZ.h, function()
            s.idx = s.idx - 1; if s.idx < 1 then s.idx = #s.vehicles end
            s.scrollY, s.view, s.card = 0, "overview", nil
        end)
        stamp(s, "mech:next", nextZ.x, nextZ.y, nextZ.w, nextZ.h, function()
            s.idx = s.idx + 1; if s.idx > #s.vehicles then s.idx = 1 end
            s.scrollY, s.view, s.card = 0, "overview", nil
        end)
    end

    -- the band at the foot holds the tab's own actions; with none to offer it is not drawn
    local hood = inspected and v:getPartById("EngineDoor") or nil
    local hoodOpen = hood and hood:getDoor() and hood:getInventoryItem() and hood:getDoor():isOpen()
    local barVerbs = {
        { id = "inspect", label = getText("ContextMenu_Inspect"), variant = "primary", canDo = true, sensible = not inspected,
          help = ZeD.tr("UI_ZeD_Veh_HelpInspect"),
          fn = function() ISVehicleMenu.onMechanic(chr, v) end },
        { id = "closehood", label = getText("IGUI_CloseHood"), canDo = true, sensible = hoodOpen and true or false,
          help = ZeD.tr("UI_ZeD_Veh_HelpCloseHood"),
          fn = function()
              ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(chr, v, hood:getArea()))
              ISTimedActionQueue.add(ISCloseVehicleDoor:new(chr, v, hood))
              local e = INSP[v:getId()]
              if e then e.hood = nil end
          end },
    }
    local barShown = ZeD.Disclose.split(barVerbs)
    local bandH = (#barShown > 0) and M.bandH() or 0

    local top = y + headerH
    local TR = ZeD.MechTrailer
    local trailer = TR.isTrailer(v)
    if trailer then TR.prepare(s, v, chr) end
    local pbH = inspected and progressBand(panel, win, s, x, top, w, v, chr) or 0
    if pbH == 0 and trailer then pbH = TR.drawBand(panel, s, x, top, w, v, chr) end
    top = top + pbH
    local bodyH = h - headerH - pbH - bandH
    local scrollW = T.sp.scrollbarW
    local cw = w - scrollW
    local pad = T.px(PAD)

    local mx, my = panel:getMouseX(), panel:getMouseY()
    local mouseIn = (not isGamepad()) and mx >= x and mx < x + cw and my >= top and my < top + bodyH
    local gpId = s.gpId
    local hl = nil
    if gpId and gpId:sub(1, 9) == "mech:row:" then hl = gpId:sub(10) end
    if mouseIn then
        hl = figurePartAt(s, mx, my)
        if not hl then
            for _, z in ipairs(s.lastRows or {}) do if hit(z, mx, my) then hl = z.part end end
        end
    end
    s.hl = hl
    -- a row of the list under the pointer (inside the body)
    local function rowHover(ry, rh) return mouseIn and my >= ry and my < ry + rh end

    panel:setStencilRect(x, top, w, bodyH)
    local cy = top - s.scrollY
    local clip = { x = x, y = top, w = w, h = bodyH }
    s.bodyClip = clip

    -- zone A: figure + summary (an animal trailer's summary holds the trailer)
    local figW, figH = T.px(FIG_W), T.px(FIG_H)
    drawFigure(panel, s, x + pad, cy + pad, figW, figH, v, parts, hl, not inspected, s.working)
    local sx = x + pad + figW + T.px(COL_GAP)
    local sw = cw - (sx - x) - pad
    local sumBottom = cy
    if trailer and not (inspected and hl) then
        sumBottom = TR.drawSummary(panel, win, s, sx, cy + pad, sw, v, chr, inspected)
    elseif inspected then
        drawSummary(panel, s, sx, cy + pad, sw, v, chr, parts, hl)
    else
        local yy = cy + pad
        yy = yy + drawLabelValue(panel, sx, yy, sw, ZeD.tr("UI_ZeD_Veh_Overall"), "?") + T.px(4)
        A.drawSegFill(panel, sx, yy, sw, T.fillBarH, A.FILL_SEGS, 0)   -- (not known yet: no reading in the help line)
        yy = yy + T.fillBarH + T.px(8)
        local dc = T.textDim
        yy = yy + dotLine(panel, sx, yy, { r = dc.r, g = dc.g, b = dc.b, a = 0.6 }, ZeD.tr("UI_ZeD_Veh_NotInspected")) + T.px(8)
        A.drawDividerH(panel, sx, yy, sw, false)
        yy = yy + T.px(6)
        yy = yy + M.drawStatRow(panel, sx, yy, sw, getText("IGUI_PlayerStats_Type"), mechType(v))
        yy = yy + M.drawStatRow(panel, sx, yy, sw, ZeD.tr("UI_ZeD_Veh_Distance"), ZeD.tr(math.floor((currentEntry(s) and currentEntry(s).dist or 0) + 0.5) == 1 and "UI_ZeD_Veh_TilesOne" or "UI_ZeD_Veh_Tiles", math.floor((currentEntry(s) and currentEntry(s).dist or 0) + 0.5)))
        local ks, kc = keyState(v, chr)
        yy = yy + M.drawStatRowDot(panel, sx, yy, sw, getText("IGUI_ItemType_Key"), ks, kc == "pos" and T.positive or T.warning)
        yy = yy + TR.drawTowRow(panel, s, sx, yy, sw, v)
    end
    cy = math.max(cy + figH + pad * 2, sumBottom + pad)

    s.lastRows = {}
    -- an animal trailer's animals come before its parts
    if trailer then
        cy = TR.drawSections(panel, win, s, x, cy, cw, v, chr, clip, mouseIn and { x = mx, y = my } or nil)
    end
    if inspected then
        -- column heads (Part, Info, Cond): F5 in sentence case, a content line under; Part and
        -- Cond sort the list, the sorted one underlined
        local hh = T.px(COLHDR_H)
        A.surfaceFill(panel, x, cy, cw, hh, "surf2")
        local f5 = T.fontF5
        local f5h = TM:getFontHeight(f5)
        local ty = cy + math.floor((hh - f5h) / 2)
        local condRight = x + cw - pad
        local infoRight = condRight - T.px(MINI_BAR_W + PCT_W + 6) - T.px(10)
        local ac, tt, td = T.accent, T.text, T.textSec
        local function sortLabel(label, key, lx, rightAlign)
            label = cased(label)
            local lw = TM:MeasureStringX(f5, label)
            local px0 = rightAlign and (lx - lw) or lx
            local zid = "mech:sort:" .. key
            local zx, zw = px0 - T.px(4), lw + T.px(8)
            if rowHover(cy, hh) and mx >= zx and mx < zx + zw then
                local hv = T.hover
                panel:drawRect(zx, cy, zw, hh, hv.a, hv.r, hv.g, hv.b)
                help(panel, key == "area" and "UI_ZeD_Veh_HelpSortArea" or "UI_ZeD_Veh_HelpSortCond")
            end
            local onFocus = markAt(s, panel, zid, zx, cy, zw, hh)
            local c = onFocus and T.textOnFocus or ((s.sort == key) and tt or td)
            panel:drawText(label, px0, ty, c.r, c.g, c.b, c.a or 1, f5)
            if s.sort == key then panel:drawRect(px0, ty + f5h, lw, T.hair, c.a or 1, c.r, c.g, c.b) end
            stamp(s, zid, zx, cy, zw, hh, function() s.sort = key; s.scrollY = 0 end,
                  { clip = { x = x, y = top, w = w, h = bodyH } })
        end
        local infoHdr = cased(ZeD.tr("UI_ZeD_Veh_HdrInfo"))
        sortLabel(ZeD.tr("UI_ZeD_Veh_HdrPart"), "area", x + pad, false)
        panel:drawText(infoHdr, infoRight - TM:MeasureStringX(f5, infoHdr), ty, td.r, td.g, td.b, td.a or 1, f5)
        sortLabel(ZeD.tr("UI_ZeD_Veh_HdrCond"), "cond", condRight, true)
        A.drawDividerH(panel, x, cy + hh - T.hair, cw, false)
        cy = cy + hh

        local clip = { x = x, y = top, w = w, h = bodyH }
        for _, g in ipairs(groupedParts(s, parts)) do
            -- category row (A / click collapses)
            local ch = T.px(CAT_H)
            local collapsed = s.collapsed[g.cat]
            local catKey = g.cat
            M.drawCategoryRow(panel, x, cy, cw, g.label, #g.parts, not collapsed, {
                hover = rowHover(cy, ch), focus = focusFor(s, "mech:cat:" .. catKey), inset = pad })
            if rowHover(cy, ch) then help(panel, "UI_ZeD_Veh_HelpFold") end
            stamp(s, "mech:cat:" .. catKey, x, cy, cw, ch, function() s.collapsed[catKey] = not s.collapsed[catKey] end,
                  { clip = clip, isDisclosure = true })
            cy = cy + ch
            if not collapsed then
                for ri, p in ipairs(g.parts) do
                    local rh = T.px(ROW_H)
                    if ri % 2 == 0 then
                        local st = T.stripe
                        panel:drawRect(x, cy, cw, rh, st.a, st.r, st.g, st.b)
                    end
                    if hl == p.id and not gpId then
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
                    A.drawStatusDot(panel, x + pad, cy + math.floor((rh - d) / 2), dc, d)
                    local nameX = x + pad + d + T.px(8)
                    local infoW = (p.info and p.info ~= "") and TM:MeasureStringX(T.fontF3, p.info) or 0
                    local nameMaxW = infoRight - infoW - T.px(10) - nameX
                    local nm = p.name
                    if TM:MeasureStringX(T.fontF2, nm) > nameMaxW then nm = A.truncateText(nm, T.fontF2, nameMaxW) end
                    panel:drawText(nm, nameX, cy + math.floor((rh - T.fontF2H) / 2), ink.r, ink.g, ink.b, ink.a or 1, T.fontF2)
                    if p.info and p.info ~= "" then
                        A.drawTextRight(panel, p.info, infoRight, cy + math.floor((rh - T.fontF3H) / 2), T.fontF3, inkDim)
                    end
                    if p.missing or p.smashed then
                        -- a word for the state, as a tag with its red square
                        local label = p.missing and getText("IGUI_Missing") or ZeD.tr("UI_ZeD_Veh_Smashed")
                        local bw = TM:MeasureStringX(T.fontF1, cased(label)) + T.px(20)
                        M.drawTag(panel, condRight - bw, cy + math.floor((rh - T.px(16)) / 2), label, T.danger)
                    else
                        local barX = condRight - T.px(PCT_W + 6) - T.px(MINI_BAR_W)
                        miniBar(panel, barX, cy + math.floor(rh / 2), T.px(MINI_BAR_W), p.cond)
                        A.drawTextRight(panel, tostring(p.cond) .. "%", condRight, cy + math.floor((rh - T.fontF3H) / 2), T.fontF3, ink)
                    end
                    local z = stamp(s, "mech:row:" .. pid, x, cy, cw, rh, function() openCard(win, s, pid) end,
                                    { clip = clip, part = pid, isRow = true })
                    s.lastRows[#s.lastRows + 1] = z
                    cy = cy + rh
                end
            end
        end
    else
        -- the parts wait for an inspection (the band's Inspect): the list's head, then one dim sentence
        local ch = M.drawCategoryRow(panel, x, cy, cw, ZeD.tr("UI_ZeD_Veh_PartsLabel"), #parts, false,
            { noArrow = true, inset = pad })
        cy = cy + ch + T.px(8)
        cy = cy + M.drawEmptyLine(panel, x + pad, cy, cw - pad * 2, ZeD.tr("UI_ZeD_Veh_InspectParts", vehicleName(v))) + T.px(8)
    end
    panel:clearStencilRect()

    local total = (cy + s.scrollY) - top
    s.maxScroll = math.max(0, total - bodyH)
    if s.scrollY > s.maxScroll then s.scrollY = s.maxScroll end
    s.bodyRect = { x = x, y = top, w = w, h = bodyH }
    drawScrollbar(panel, x + w - scrollW, top, bodyH, total, s.scrollY)

    -- opened from Check Animals: scroll just enough to show the animals
    if s.showAnimals then
        s.showAnimals = nil
        if trailer and s.trAnimalsY then
            local want = math.min(s.trAnimalsEnd or s.trAnimalsY, s.trAnimalsY + T.px(CAT_H + 3 * 40))
            local delta = math.min(want - (top + bodyH), s.trAnimalsY - top)
            if delta > 0 then s.scrollY = math.min(s.maxScroll, s.scrollY + delta) end
        end
    end

    -- gamepad scroll-follow for rows and headers
    if gpId then
        local z = s.byId[gpId]
        if z and z.clip then
            if z.y < top then s.scrollY = math.max(0, s.scrollY - (top - z.y))
            elseif z.y + z.h > top + bodyH then s.scrollY = math.min(s.maxScroll, s.scrollY + (z.y + z.h - (top + bodyH))) end
        end
    end

    -- the band: Inspect before an inspection, Close hood while the hood is open
    if bandH > 0 then
        local buttons = {}
        for i, bv in ipairs(barShown) do
            buttons[i] = { label = bv.label, variant = bv.variant, help = bv.help, focus = focusFor(s, "mech:" .. bv.id) }
        end
        local _, out = M.drawBand(panel, x, y + h - bandH, w, { win = win, buttons = buttons })
        for i, bv in ipairs(barShown) do
            local r = out.buttons[i]
            stamp(s, "mech:" .. bv.id, r.x, r.y, r.w, r.h, bv.fn, { footer = true })
        end
    end
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
    if item then add(getText("IGUI_Item"), item:getDisplayName()) end
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

local function renderCard(panel, win, s, x, y, w, h, v, chr)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local TM = ZeD.TM
    local DS = ZeD.Disclose
    local part = v:getPartById(s.card)
    if not part then closeCard(win, s); return end
    local p = partModel(part, chr, v)
    local verbs = verbsFor(part, chr)
    local gpId = s.gpId
    if gpId and gpId:sub(1, 10) == "mech:verb:" then s.verb = gpId:sub(11) end

    -- Every verb with what it needs, sorted by the hidden-actions setting: the ones you can do
    -- are shown; the ones you cannot yet fold into one row after them; the ones that make
    -- no sense now are gone.
    local needs, list = {}, {}
    for _, vb in ipairs(verbs) do
        local n = needsFor(s, part, vb, chr, v)
        needs[vb] = n
        local missing = n.ok and "" or missingOf(n)
        local label = vlabel(vb)
        list[#list + 1] = {
            id = vb, label = label, canDo = n.ok, sensible = verbSensible(part, vb), danger = DANGER[vb],
            needs = (missing ~= "") and missing or ZeD.tr("UI_ZeD_Veh_RightConditions"),
            hint = ZeD.tr(VERB_HINT[vb] or "UI_ZeD_Veh_HintDefault"),
            needsLine = (missing == "") and ZeD.tr("UI_ZeD_Veh_NotNow", label) or nil,
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
    local busy = activeAction(chr, v) ~= nil

    -- header: back + name + the verbs you can do (mouse hover on a verb picks the one whose details show)
    local defs = {}
    for i, sv in ipairs(shown) do
        defs[i] = { label = sv.label, primary = (sv.id == primary), disabled = not sv.canDo, danger = sv.danger,
                    focus = focusFor(s, "mech:verb:" .. sv.id), help = sv.help }
    end
    local rects = {}
    _backOpts.focus = focusFor(s, "mech:back")
    _backOpts.focusId = _backOpts.focus and "back" or nil
    local headerH = M.drawCardBackBar(panel, x, y, w, p.name, defs, busy, false, rects, _backOpts)
    stamp(s, "mech:back", rects.back.x, rects.back.y, rects.back.w, rects.back.h, function() closeCard(win, s) end)
    local mx, my = panel:getMouseX(), panel:getMouseY()
    for i, sv in ipairs(shown) do
        local r = rects.verbs and rects.verbs[i]
        if r then
            local verb = sv.id
            stamp(s, "mech:verb:" .. verb, r.x, r.y, r.w, r.h, function()
                s.verb = verb
                if busy or not needs[verb].ok then return end
                if DANGER[verb] then s.confirm = verb; win._mechFocusTarget = "mech:confirm:no"; return end
                runVerb(s, verb, part, chr)
            end, { verb = verb })
            if not isGamepad() and hit(r, mx, my) then s.verb = verb end
        end
    end

    -- the band under the progress band: only while a question waits (Cancel and the verb)
    local top = y + headerH
    local pbH = progressBand(panel, win, s, x, top, w, v, chr)
    top = top + pbH
    local confirmH = s.confirm and M.bandH() or 0
    local bodyH = h - headerH - pbH - confirmH
    local scrollW = T.sp.scrollbarW
    local cw = w - scrollW
    local pad = T.px(12)
    local clip = { x = x, y = top, w = w, h = bodyH }

    panel:setStencilRect(x, top, w, bodyH)
    local cy = top - s.cardScroll + pad

    -- the folded row after the verbs: what you could do with the right things (A / click opens it);
    -- a verb shown greyed (the setting "show all") says what it needs right under the row
    local moreKey = "veh:part:" .. tostring(p.id)
    for _, sv in ipairs(shown) do
        if not sv.canDo then
            cy = cy + M.drawNeedsLine(panel, x + pad, cy, cw - pad * 2, DS.needsLine(sv)) + T.px(4)
        end
    end
    if #hidden > 0 then
        local mh, rowRect = M.drawMoreRow(panel, x + pad, cy, cw - pad * 2, hidden, moreKey,
            { focus = focusFor(s, "mech:more"), win = win })
        if rowRect then
            stamp(s, "mech:more", rowRect.x, rowRect.y, rowRect.w, rowRect.h, function() DS.toggle(moreKey) end, { clip = clip })
        end
        cy = cy + mh + T.px(6)
    end

    -- stat grid with the part's icon (ghosted when the part is missing)
    local icon, ghost = iconFor(p)
    cy = cy + M.drawTopStatsGrid(panel, x + pad, cy, cw - pad * 2, icon, cardStats(p, v, chr), ghost)
    cy = cy + T.px(8)
    if not p.missing and not p.smashed then
        A.drawFillBar(panel, x + pad, cy, cw - pad * 2, p.cond / 100, true, nil, nil, ZeD.tr("IGUI_invpanel_Condition"))
        cy = cy + T.fillBarH + T.px(10)
    end

    local function section(text, aside)
        local sh = M.drawSectionHeader(panel, x + pad, cy, cw - pad, text, nil, true, false, nil, nil, pad, T.px(SEC_H), true)
        if aside then A.drawTextRight(panel, cased(aside), x + cw - pad, cy + math.floor((T.px(SEC_H) - T.fontF1H) / 2), T.fontF1, T.textDim) end
        cy = cy + sh + T.px(4)
    end

    -- one pickable row: the radio, a selected wash, the controller's mark; returns the ink and the x after the radio
    local function pickRow(id, rowY, rh, sel, radioY, enabled, focusable)
        local rowX, rowW = x + pad, cw - pad * 2
        local hov = enabled and (not isGamepad()) and A.mouseIn(panel, rowX, rowY, rowW, rh, clip)
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

    -- install: pick list
    if s.verb == "install" then
        local picks = installPicks(part, chr, itemsFor(s, chr))
        local owned = 0
        for _, pk in ipairs(picks) do if not pk.none then owned = owned + 1 end end
        if s.pick > owned then s.pick = math.max(1, owned) end
        section(ZeD.tr("UI_ZeD_Veh_FromBags"), nil)
        for i, pk in ipairs(picks) do
            local rh = T.px(PICK_H)
            local sel = (not pk.none) and (i == s.pick)
            local onFocus, textX = pickRow("mech:pick:" .. tostring(i), cy, rh, sel,
                cy + math.floor((rh - A.radioSize()) / 2), not pk.none, not pk.none)
            local rc = onFocus and T.textOnFocus or (pk.none and T.textDim or T.text)
            local dimc = onFocus and T.textOnFocus or T.textDim
            panel:drawText(pk.name, textX, cy + math.floor((rh - T.fontF2H) / 2), rc.r, rc.g, rc.b, rc.a or 1, T.fontF2)
            local right = x + cw - pad - T.px(4)
            if pk.none then
                A.drawTextRight(panel, cased(ZeD.tr("UI_ZeD_Veh_NoneNearby")), right, cy + math.floor((rh - T.fontF1H) / 2), T.fontF1, dimc)
            else
                A.drawTextRight(panel, pk.loc, right, cy + math.floor((rh - T.fontF1H) / 2), T.fontF1, dimc)
                local locW = TM:MeasureStringX(T.fontF1, pk.loc)
                local pctR = right - locW - T.px(12)
                A.drawTextRight(panel, tostring(pk.cond) .. "%", pctR, cy + math.floor((rh - T.fontF3H) / 2), T.fontF3, onFocus and T.textOnFocus or T.text)
                miniBar(panel, pctR - T.px(PCT_W + 4) - T.px(MINI_BAR_W), cy + math.floor(rh / 2), T.px(MINI_BAR_W), pk.cond)
                local idx = i
                stamp(s, "mech:pick:" .. tostring(i), x + pad, cy, cw - pad * 2, rh, function() s.pick = idx end, { clip = clip })
            end
            A.drawDividerH(panel, x + pad, cy + rh - T.px(1), cw - pad * 2, false)
            cy = cy + rh
        end
        cy = cy + T.px(10)
    end

    -- repair: recipe rows (pickable; the Repair verb runs the picked one)
    if s.verb == "fix" then
        local fr = cachedFixRows(s, part, chr)
        if s.fixPick > #fr then s.fixPick = 1 end
        if not (fr[s.fixPick] and fr[s.fixPick].ok) then
            for i, r in ipairs(fr) do if r.ok then s.fixPick = i; break end end
        end
        section(ZeD.tr("UI_ZeD_Veh_RepairWith"), nil)
        for i, r in ipairs(fr) do
            local rh = T.px(FIX_H)
            local sel = (i == s.fixPick) and r.ok
            local onFocus, textX = pickRow("mech:fix:" .. tostring(i), cy, rh, sel, cy + T.px(6), r.ok, true)
            local tcl = onFocus and T.textOnFocus or (r.ok and T.text or T.textDim)
            local maxW = (x + cw - pad - T.px(4)) - textX
            local label = r.label
            if TM:MeasureStringX(T.fontF2, label) > maxW then label = A.truncateText(label, T.fontF2, maxW) end
            panel:drawText(label, textX, cy + T.px(3), tcl.r, tcl.g, tcl.b, tcl.a or 1, T.fontF2)
            local meta = r.meta .. (r.why and ("  " .. DOT .. "  " .. r.why) or "")
            if TM:MeasureStringX(T.fontF1, meta) > maxW then meta = A.truncateText(meta, T.fontF1, maxW) end
            local mc = onFocus and T.textOnFocus or T.textDim
            panel:drawText(meta, textX, cy + T.px(3) + T.fontF2H, mc.r, mc.g, mc.b, mc.a or 1, T.fontF1)
            local idx = i
            stamp(s, "mech:fix:" .. tostring(i), x + pad, cy, cw - pad * 2, rh, function() if fr[idx] and fr[idx].ok then s.fixPick = idx end end, { clip = clip })
            A.drawDividerH(panel, x + pad, cy + rh - T.px(1), cw - pad * 2, false)
            cy = cy + rh
        end
        cy = cy + T.px(10)
    end

    -- the chance of success for the highlighted verb (install / uninstall): a framed bar, the
    -- share that works filled
    local n = s.verb and needs[s.verb]
    if n and s.verb ~= "fix" then
        local sc, fc = n.chance[1], n.chance[2]
        if fc and fc > 0 then
            local bw = cw - pad * 2
            local succ = cased(ZeD.tr("UI_ZeD_Veh_SuccessPct", tostring(sc) .. "%"))
            -- (ten segments; its help line the words under it, "Success 64%")
            if A.drawFillBar(panel, x + pad, cy, bw, sc / 100, false, T.positive) then ZeD.Help.set(panel, succ) end
            cy = cy + T.fillBarH + T.px(3)
            local tt = T.text
            panel:drawText(succ, x + pad, cy, tt.r, tt.g, tt.b, tt.a or 1, T.fontF1)
            A.drawTextRight(panel, cased(ZeD.tr("UI_ZeD_Veh_FailurePct", tostring(fc) .. "%")), x + pad + bw, cy, T.fontF1, tt)
            cy = cy + T.fontF1H + T.px(10)
        end
    end

    -- ABOUT: vanilla part info text
    local about = txt("IGUI_Vehicle_CondInfo" .. p.id, nil)
    if about then
        about = string.gsub(about, "<LINE>", " ")
        section(ZeD.tr("UI_ZeD_Veh_About"), nil)
        local dc = T.textDim
        for _, ln in ipairs(A.wrapText(about, T.fontF2, cw - pad * 2)) do
            panel:drawText(ln, x + pad, cy, dc.r, dc.g, dc.b, dc.a or 1, T.fontF2)
            cy = cy + T.fontF2H
        end
        cy = cy + T.px(10)
    end
    panel:clearStencilRect()

    local total = (cy + s.cardScroll) - top
    s.maxScroll = math.max(0, total - bodyH)
    if s.cardScroll > s.maxScroll then s.cardScroll = s.maxScroll end
    s.bodyRect = { x = x, y = top, w = w, h = bodyH }
    drawScrollbar(panel, x + w - scrollW, top, bodyH, total, s.cardScroll)
    if gpId then
        local z = s.byId[gpId]
        if z and z.clip then
            if z.y < top then s.cardScroll = math.max(0, s.cardScroll - (top - z.y))
            elseif z.y + z.h > top + bodyH then s.cardScroll = math.min(s.maxScroll, s.cardScroll + (z.y + z.h - (top + bodyH))) end
        end
    end

    -- the question before the irreversible (Smash the window? Take engine parts?): Cancel and the verb
    if s.confirm then
        local verb = s.confirm
        local q = (verb == "takeParts") and ZeD.tr("UI_ZeD_Veh_ConfirmTakeParts")
                  or ZeD.tr("UI_ZeD_Veh_ConfirmSmash", string.lower(p.name))
        local fy = y + h - confirmH
        local _, cancelR, verbR = M.drawQuestionBand(panel, x, fy, w, q, vlabel(verb), { win = win, danger = true,
            cancelFocus = focusFor(s, "mech:confirm:no"), verbFocus = focusFor(s, "mech:confirm:yes"),
            cancelHelp = ZeD.tr("UI_ZeD_Veh_HelpConfirmNo"), verbHelp = ZeD.tr(VERB_HELP[verb] or "UI_ZeD_Veh_HelpDefault") })
        stamp(s, "mech:confirm:no", cancelR.x, cancelR.y, cancelR.w, cancelR.h, function() s.confirm = nil end)
        stamp(s, "mech:confirm:yes", verbR.x, verbR.y, verbR.w, verbR.h, function()
            s.confirm = nil
            runVerb(s, verb, part, chr)
        end)
    end
end

-- ----------------------------------------------------------------------------
-- Shared helpers for MechTrailer.lua (the animal trailer page)
-- ----------------------------------------------------------------------------
MT._h = {
    stamp = stamp, dotLine = dotLine, drawScrollbar = drawScrollbar, markAt = markAt, focusFor = focusFor,
    vehicleName = vehicleName, overallCond = overallCond, now = now, progressBand = progressBand,
    miniBar = miniBar, cased = cased,
}

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
    local chr = win._playerObj or getSpecificPlayer(0)
    local e = currentEntry(s)
    if s.view ~= "animal" then TR.hideAvatar(s) end
    if not chr or not e or not e.vehicle or not e.vehicle:getSquare() then
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
    if s.view == "card" and s.card and inspected then
        renderCard(panel, win, s, x, y, w, h, v, chr)
    else
        if s.view == "card" then s.view, s.card = "overview", nil end
        renderOverview(panel, win, s, x, y, w, h, v, chr, inspected)
    end
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
    for i = #s.zones, 1, -1 do
        local z = s.zones[i]
        if hit(z, x, y) and (not z.clip or hit(z.clip, x, y)) then
            if not z.disabled then pcall(function() getSoundManager():playUISound("UIActivateButton") end) end
            z.fn()
            return true
        end
    end
    -- figure part → card
    if s.view == "overview" then
        local id = figurePartAt(s, x, y)
        if id and s.bodyRect and hit(s.bodyRect, x, y) then
            local e = currentEntry(s)
            if e and INSP[e.id] then openCard(win, s, id); return true end
        end
    end
    return true
end

function MT.onRightClick(win, x, y)
    local s = st(win)
    local chr = win._playerObj or getSpecificPlayer(0)
    local e = currentEntry(s)
    if not chr or not e or not INSP[e.id] or s.view == "animal" then return true end
    local id = nil
    if s.view == "card" then id = s.card
    else
        id = figurePartAt(s, x, y)
        if not id then
            for _, z in ipairs(s.lastRows or {}) do if hit(z, x, y) and hit(z.clip, x, y) then id = z.part end end
        end
    end
    if id then partContextMenu(e.vehicle:getPartById(id), chr) end
    return true
end

function MT.onMouseWheel(win, del)
    local s = st(win)
    local step = ZeD.T.px(SCROLL_STEP) * del
    if s.view ~= "overview" then
        s.cardScroll = math.max(0, math.min(s.maxScroll or 0, s.cardScroll + step))
    else
        s.scrollY = math.max(0, math.min(s.maxScroll or 0, s.scrollY + step))
    end
    return true
end

-- ----------------------------------------------------------------------------
-- Gamepad: elements from this frame's stamped zones
-- ----------------------------------------------------------------------------
function MT.buildFocusables(win)
    local s = win and win._mech
    if not s then return {} end
    local chr = win._playerObj or getSpecificPlayer(0)
    local els = {}
    for _, z in ipairs(s.zones) do
        local zz = z
        local el = { x = zz.x, y = zz.y, w = zz.w, h = zz.h, id = zz.id,
                     isDisclosure = zz.isDisclosure,
                     onActivate = function() zz.fn() end }
        if s.view == "card" then
            el.onCancel = function()
                if s.confirm then s.confirm = nil else closeCard(win, s) end
                return true
            end
        elseif s.view == "animal" then
            el.onCancel = function() ZeD.MechTrailer.closeAnimal(win, s); return true end
        end
        if zz.isRow then
            el.onContextMenu = function()
                local e = currentEntry(s)
                if e and chr then partContextMenu(e.vehicle:getPartById(zz.part), chr) end
            end
        elseif s.view == "card" and zz.verb then
            el.onContextMenu = function()
                local e = currentEntry(s)
                if e and chr and s.card then partContextMenu(e.vehicle:getPartById(s.card), chr) end
            end
        end
        els[#els + 1] = el
    end
    return els
end

-- Signature for the World window's per-frame refresh: rebuild when the view,
-- the scroll offset or the element set changes.
function MT.focusKey(win)
    local s = win and win._mech
    if not s then return "none" end
    return tostring(s.view) .. ":" .. tostring(s.card) .. ":" .. tostring(math.floor(s.scrollY or 0)) .. ":"
        .. tostring(math.floor(s.cardScroll or 0)) .. ":" .. tostring(s.confirm) .. ":" .. tostring(#s.zones) .. ":" .. tostring(s.idx)
        .. ":" .. tostring(s.animalId)
end

-- Focus target after a view change (card opened -> first verb; card closed -> its row)
function MT.focusTargetIndex(win, els)
    local t = win and win._mechFocusTarget
    if not t then return nil end
    -- the new view's zones appear a frame later: keep the target until it lands
    win._mechFocusTries = (win._mechFocusTries or 0) + 1
    local found = ZeD.MechTrailer.focusTarget(t, els)
    for i, e in ipairs(els) do
        if found then break end
        if t == "card" and e.id:sub(1, 10) == "mech:verb:" then found = i; break end
        if e.id == t then found = i; break end
    end
    if not found and t == "card" then
        for i, e in ipairs(els) do if e.id == "mech:back" then found = i; break end end
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
    if not ZeD_WorldWindow.isOpen() then
        local ok = pcall(ZeD_WorldWindow.open, pn)
        if not ok then return false end
    end
    local win = ZeD_WorldWindow.getWindow()
    if not win then return false end
    local s = st(win)
    s.pendingId = vid
    MT.refresh(win)
    s.view, s.card, s.confirm = "overview", nil, nil
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
    if not ZeD_WorldWindow.isOpen() then
        local ok = pcall(ZeD_WorldWindow.open, chr:getPlayerNum())
        if not ok then return false end
    end
    local win = ZeD_WorldWindow.getWindow()
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
        local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
        if not win then return end
        local s = st(win)
        s.flash = { ok = success and true or false, untilMs = now() + FLASH_MS }
        s.items = nil
        s.needsCache, s.fixCache, s.partsCache = nil, nil, nil
    end)
end

print("[ZeD] MechanicsTab: Vehicle tab loaded")
return MT
