-- ZeD-UI/42/media/lua/client/ZeD/MechTrailer.lua
-- ============================================================================
-- ANIMAL TRAILER PAGE — the Vehicle tab's page for an animal trailer
-- (HOOK_MAP row 23, mockup ZeDUI/mockups/zed_trailer_animals_v1.html)
--
-- Vanilla shows a trailer's animals in ISVehicleAnimalUI: a space bar, an
-- Add Animal button and a grid of 3D figures with right-click menus. Here the
-- trailer's own page in the Vehicle tab reads its animals before its parts:
--   * the summary beside the figure: SPACE (a floor bar of what each animal
--     takes and what is left), the trunk lid, the Food Container and the Egg
--     Container (OPEN shows them in the Loot pane), how many are thirsty, and
--     the towing link (a car and its trailer point at each other);
--   * ANIMALS: one row per animal (portrait, needs, tags, space taken);
--   * LOAD FROM HERE: what vanilla's Add Animal offers, with PUT IN or
--     vanilla's reason;
--   * an animal's card: REMOVE / GRAB / INFO, vanilla's 3D figure with its
--     trailer framing, vitals, GIVE WATER and FEED from what you carry.
-- Every verb waits for the trunk lid, as vanilla's menus do; the animals
-- still read with it shut. The verbs call vanilla's own functions.
--
-- MechanicsTab.lua owns the page and hands this module its shared helpers
-- (ZeD.MechanicsTab._h: stamp, markAt, focusFor, dotLine...). Everything here is
-- looked up at call time, so either file can be hot-reloaded alone.
-- Every layout number is a DESIGN UNIT and goes through T.px at use (S124).
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/AnimalsData"

ZeD = ZeD or {}
ZeD.MechTrailer = ZeD.MechTrailer or {}
local TR = ZeD.MechTrailer

-- ----------------------------------------------------------------------------
-- Constants (design units unless noted)
-- ----------------------------------------------------------------------------
local PAD         = 10
local CAT_H       = 15     -- category row (the part list's)
local AROW_H      = 40     -- animal row
local PORT_SZ     = 28     -- portrait in an animal row
local LROW_H      = 34     -- load-from-here row
local LPORT_SZ    = 24
local SPACE_H     = 10     -- the floor bar
local SROW_H      = 22     -- summary row
local DOT_SZ      = 7
local AV_W, AV_H  = 128, 160   -- 3D figure box (vanilla's 160x200, same shape)
local VROW_H      = 20     -- vital row on the card
local VBAR_W      = 40
local PICK_H      = 32     -- GIVE WATER / FEED row
local SEC_H       = 20
local LOAD_TTL_MS = 500    -- the 12x12 scan for animals near the back is cached this long
local ITEMS_TTL_MS = 700   -- water and feed lists
local THIRST_MIN  = 0.1    -- vanilla offers water / feed past these (ISVehicleAnimalUI)
local HUNGER_MIN  = 0.1

local DOT = "|"   -- the separator: ZeD OS's pipe (director, Oct 16 2026: no middle dots)

-- ----------------------------------------------------------------------------
-- Small helpers
-- ----------------------------------------------------------------------------
local function H() return ZeD.MechanicsTab._h end
local function AD() return ZeD.AnimalsData end
local function txt(key, fallback)
    local t = getTextOrNull and getTextOrNull(key) or nil
    return t or fallback
end
-- words that arrive in capitals read in sentence case (ZeD.textCase)
local function cased(s) return ZeD.textCase(tostring(s or "")) end
-- the plain-words line the window's footer shows while the pointer is over a part
local function help(panel, key, ...)
    if ZeD.Help and ZeD.Help.set then ZeD.Help.set(panel, ZeD.tr(key, ...)) end
end
local function call(o, m, ...)
    if not o then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end
-- space in whole units (vanilla's sizes carry decimals: a ewe takes 89.6)
local function fmt(n) return tostring(math.floor((n or 0) + 0.5)) end
local function statusColor(T, pct)
    if pct > 60 then return T.positive elseif pct > 30 then return T.warning end
    return T.danger
end
local TEXCACHE = {}
local function texture(path)
    if not path then return nil end
    local t = TEXCACHE[path]
    if t == nil then
        t = getTexture(path) or false
        TEXCACHE[path] = t
    end
    return t or nil
end

function TR.isTrailer(v)
    local n = call(v, "getAnimalTrailerSize")
    return n ~= nil and n > 0
end

-- the trunk lid: vanilla looks for these three part ids, in this order
local function lidPart(v)
    return v:getPartById("TrunkDoor") or v:getPartById("DoorRear") or v:getPartById("TrunkDoorOpened")
end
function TR.lidOpen(v)
    local p = lidPart(v)
    local d = p and p:getDoor()
    if d then return d:isOpen() end
    return true
end

-- the square vanilla walks to before every trailer verb
local function entrySq(v)
    local vec = v:getAreaCenter("AnimalEntry")
    if not vec then return nil end
    return getSquare(vec:getX(), vec:getY(), v:getZ())
end

-- ----------------------------------------------------------------------------
-- Animals inside
-- ----------------------------------------------------------------------------
local function animalId(a)
    local ok, id = pcall(function() return a:getAnimalID() end)
    if ok then return id end
    return nil
end

local function stat(a, which)
    local ok, val = pcall(function() return a:getStats():get(which) end)
    return (ok and val) or 0
end

local function speciesLabel(atype)
    return txt("IGUI_AnimalType_" .. tostring(atype), tostring(atype))
end

-- The row model: name, space, needs and tags for one animal in the trailer
local function model(a, chr)
    local ad = AD()
    local dead = call(a, "isDead") and true or false
    local name = ad.getDisplayName(a)
    if dead then name = getText("IGUI_Item_AnimalCorpse", name) end
    local m = {
        a = a, id = animalId(a), dead = dead, name = name,
        size = call(a, "getAnimalTrailerSize") or 0,
        thirst = stat(a, CharacterStat.THIRST), hunger = stat(a, CharacterStat.HUNGER),
        stress = ad.getStress(a), health = ad.getHealth(a),
        atype = ad.getAnimalType(a), female = ad.isFemale(a), baby = ad.isBaby(a),
    }
    local tags = {}
    if dead then
        tags[1] = { label = getText("IGUI_DesignationZone_Dead"), sev = "danger" }
    else
        if m.thirst >= 0.5 then tags[#tags + 1] = { label = getText("IGUI_Animal_Thirsty"), sev = "danger" }
        elseif m.thirst >= THIRST_MIN then tags[#tags + 1] = { label = getText("IGUI_Animal_Thirsty"), sev = "warning" } end
        if m.hunger >= 0.5 then tags[#tags + 1] = { label = getText("Moodles_Hungry_lvl2"), sev = "danger" }
        elseif m.hunger >= HUNGER_MIN then tags[#tags + 1] = { label = getText("Moodles_Hungry_lvl2"), sev = "warning" } end
        if m.stress >= 50 then tags[#tags + 1] = { label = getText("IGUI_Animal_Stressed"), sev = "warning" } end
    end
    m.tags = tags
    return m
end

local function animalsOf(v)
    local out = {}
    local list = call(v, "getAnimals")
    if not list then return out end
    for i = 0, list:size() - 1 do out[#out + 1] = list:get(i) end
    return out
end

-- Segment colours for the floor bar, one per kind of animal (theme-aware)
local function palette(T)
    local cb = ZeD.colorBlend
    return { T.accent, T.info, cb(T.accent, T.text, 0.45), cb(T.info, T.text, 0.45),
             cb(T.accent, T.info, 0.5), T.textDim }
end

-- Once per frame, before the page draws: the animals, their colours and the
-- space each kind takes (s.trModels / s.trColors / s.trGroups)
function TR.prepare(s, v, chr)
    local T = ZeD.T
    local pal = palette(T)
    local ms, colors, groups, byType = {}, {}, {}, {}
    for _, a in ipairs(animalsOf(v)) do
        local m = model(a, chr)
        ms[#ms + 1] = m
        local g = byType[m.atype]
        if not g then
            g = { atype = m.atype, label = speciesLabel(m.atype), size = 0 }
            byType[m.atype] = g
            groups[#groups + 1] = g
            colors[m.atype] = pal[((#groups - 1) % #pal) + 1]
        end
        g.size = g.size + m.size
    end
    s.trModels, s.trColors, s.trGroups = ms, colors, groups
end

-- Portrait for an animal, or for a carcass from what it was (its mod data)
local function bodyProxy(body)
    local md = body:getModData()
    return {
        getAnimalType = function() return md["AnimalType"] or "unknown" end,
        getData = function()
            return { getBreed = function() return { getName = function() return md["AnimalBreed"] or "" end } end }
        end,
    }
end
local function portraitOf(a) return texture(AD().resolvePortrait(a)) end

-- ----------------------------------------------------------------------------
-- What the player carries: water sources and the feed an animal eats
-- (AnimalContextMenu.doWaterAnimalMenu / doFeedFromHandMenu)
-- ----------------------------------------------------------------------------
local function locOf(item, chr)
    if item == chr:getPrimaryHandItem() or item == chr:getSecondaryHandItem() then return ZeD.tr("UI_ZeD_Veh_LocInHand") end
    local c = item:getContainer()
    if not c then return "" end
    if c == chr:getInventory() then return getText("IGUI_Controller_Inventory") end
    local ci = c:getContainingItem()
    if ci then return ci:getName() end
    return ""
end

local function waterSources(chr)
    local out, seen = {}, {}
    local ok, items = pcall(function() return chr:getInventory():getAllWaterFluidSources(true) end)
    if not ok or not items then return out end
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        local ml = 0
        pcall(function() ml = it:getFluidContainer():getAmount() * 1000 end)
        local key = it:getName() .. ":" .. tostring(math.floor(ml + 0.5))
        if not seen[key] then
            seen[key] = true
            out[#out + 1] = { item = it, name = it:getName(),
                              meta = ZeD.tr("UI_ZeD_Veh_WaterMeta", locOf(it, chr), math.floor(ml + 0.5)) }
        end
    end
    return out
end

local function feedTest(item, milkType)
    local fc = item:getFluidContainer()
    if fc and ((milkType and fc:isPureFluid(Fluid.Get(milkType))) or fc:isPureFluid(Fluid.AnimalMilk)) then return true end
    if item:isAnimalFeed() then return true end
    return instanceof(item, "Food") and (item:getFoodType() == "Fruits" or item:getFoodType() == "Vegetables" or item:getMilkType())
        and item:getHungerChange() < 0 and not item:isRotten() and not item:isSpice()
end

local function feedFoods(chr, a)
    local out = {}
    local foodList = call(a, "getEatTypePossibleFromHand")
    if not foodList then return out end
    local milkType = nil
    pcall(function() milkType = a:getBreed():getMilkType() end)
    local ok, foods = pcall(function()
        return chr:getInventory():getAllEvalRecurse(function(item)
            local ok2, r = pcall(feedTest, item, milkType)
            return ok2 and r or false
        end)
    end)
    if not ok or not foods then return out end
    local byText = {}
    for i = 0, foods:size() - 1 do
        local f = foods:get(i)
        local testType, testType2 = f:getFullType(), nil
        local fc = f:getFluidContainer()
        if fc and milkType and fc:isPureFluid(Fluid.Get(milkType)) then testType = milkType end
        if fc and fc:isPureFluid(Fluid.AnimalMilk) then testType = "AnimalMilk" end
        if instanceof(f, "Food") then testType2 = f:getFoodType() end
        if f:isAnimalFeed() then testType = f:getAnimalFeedType() end
        if foodList:contains(testType) or (testType2 and foodList:contains(testType2)) then
            local text = f:getDisplayName()
            if fc then text = fc:getUiName() end
            local e = byText[text]
            if e then e.n = e.n + 1
            else
                e = { item = f, name = text, n = 1, loc = locOf(f, chr) }
                byText[text] = e
                out[#out + 1] = e
            end
        end
    end
    return out
end

local function carried(s, chr, a)
    local t = H().now()
    local c = s.trItems
    if c and c.a == a and t - c.at < ITEMS_TTL_MS then return c end
    c = { a = a, at = t, water = waterSources(chr), feed = feedFoods(chr, a) }
    s.trItems = c
    return c
end

-- ----------------------------------------------------------------------------
-- LOAD FROM HERE: what vanilla's Add Animal offers (ISVehicleMenu.doAnimalSubMenu)
-- ----------------------------------------------------------------------------
local function tilesFromBack(d)
    local n = math.floor(d + 0.5)
    if n < 1 then return ZeD.tr("UI_ZeD_Veh_AtBack") end
    return ZeD.tr(n == 1 and "UI_ZeD_Veh_TileFromBack" or "UI_ZeD_Veh_TilesFromBack", n)
end

local function loadCandidates(s, v, chr)
    local t = H().now()
    local c = s.trLoad
    if c and c.vid == v:getId() and t - c.at < LOAD_TTL_MS then return c.list end
    local list = {}
    local tooFar = getText("Tooltip_Animal_TooFarFromTrailer")
    local tooBig = getText("Tooltip_Animal_TooBigForTrailer")
    local ad = AD()
    local hand = chr:getPrimaryHandItem()
    -- a carcass in your hands
    if hand and hand:getType() == "CorpseAnimal" then
        local body = call(hand, "getDeadBodyObject")
        if body and call(body, "isAnimal") and not call(body, "isAnimalSkeleton") then
            local ok = v:canAddAnimalInTrailer(body)
            local nm = body:getCustomName()
            list[#list + 1] = {
                key = "held", held = true, port = bodyProxy(body),
                name = getText("IGUI_Item_AnimalCorpse", nm or speciesLabel(body:getModData()["AnimalType"])),
                size = body:getModData()["animalTrailerSize"] or 0, loc = ZeD.tr("UI_ZeD_Veh_InYourHands"), dist = 0,
                ok = ok, why = (not ok) and tooBig or nil,
                run = function() ISVehicleMenu.onAddAnimalFromHandsInTrailer(chr, body, v) end,
            }
        end
    end
    -- an animal in your hands
    if instanceof(hand, "AnimalInventoryItem") then
        local a = hand:getAnimal()
        if a then
            local ok = v:canAddAnimalInTrailer(a)
            list[#list + 1] = {
                key = "held", held = true, port = a, name = ad.getDisplayName(a),
                size = call(a, "getAnimalTrailerSize") or 0, loc = ZeD.tr("UI_ZeD_Veh_InYourHands"), dist = 0,
                ok = ok, why = (not ok) and tooBig or nil,
                run = function() ISVehicleMenu.onAddAnimalFromHandsInTrailer(chr, hand, v) end,
            }
        end
    end
    -- animals and carcasses near the trailer (vanilla's 12x12 box)
    local vsq = v:getSquare()
    if vsq then
        local z = vsq:getZ()
        for x = vsq:getX() - 6, vsq:getX() + 5 do
            for y = vsq:getY() - 6, vsq:getY() + 5 do
                local sq = getSquare(x, y, z)
                if sq then
                    local animals = sq:getAnimals()
                    for i = 0, animals:size() - 1 do
                        local a = animals:get(i)
                        local reach = 3
                        -- vanilla: more range when the animal is on your leash
                        if call(a:getData(), "getAttachedPlayer") == chr then reach = 5 end
                        local d = v:getAreaDist("AnimalEntry", a)
                        local ok, why = true, nil
                        if d > reach then ok, why = false, tooFar
                        elseif not v:canAddAnimalInTrailer(a) then ok, why = false, tooBig end
                        list[#list + 1] = {
                            key = "a" .. tostring(animalId(a) or i), port = a, name = ad.getDisplayName(a),
                            size = call(a, "getAnimalTrailerSize") or 0, loc = tilesFromBack(d), dist = d,
                            ok = ok, why = why,
                            run = function() ISVehicleMenu.onAddAnimalInTrailer(chr, a, v) end,
                        }
                    end
                    local bodies = sq:getDeadBodys()
                    for i = 0, bodies:size() - 1 do
                        local b = bodies:get(i)
                        if b:isAnimal() and b:getSquare() and not b:isAnimalSkeleton() then
                            local bs = b:getSquare()
                            local d = v:getAreaDist("AnimalEntry", bs:getX(), bs:getY(), bs:getZ())
                            local ok, why = true, nil
                            if d > 3 then ok, why = false, tooFar
                            elseif not v:canAddAnimalInTrailer(b) then ok, why = false, tooBig end
                            local nm = b:getCustomName()
                            list[#list + 1] = {
                                key = "b" .. tostring(x) .. "_" .. tostring(y) .. "_" .. tostring(i), port = bodyProxy(b),
                                name = getText("IGUI_Item_AnimalCorpse", nm or speciesLabel(b:getModData()["AnimalType"])),
                                size = b:getModData()["animalTrailerSize"] or 0, loc = tilesFromBack(d), dist = d,
                                ok = ok, why = why,
                                run = function() ISVehicleMenu.onAddAnimalInTrailer(chr, b, v) end,
                            }
                        end
                    end
                end
            end
        end
    end
    -- what you hold first, then what can go in, nearest first
    table.sort(list, function(p, q)
        if p.held ~= q.held then return p.held == true end
        if p.ok ~= q.ok then return p.ok end
        return p.dist < q.dist
    end)
    s.trLoad = { vid = v:getId(), at = t, list = list }
    return list
end

-- ----------------------------------------------------------------------------
-- Verbs (vanilla's own calls; every one starts with the walk to the back)
-- ----------------------------------------------------------------------------
local function toggleLid(chr, v)
    local p = lidPart(v)
    if not (p and p:getDoor()) then return end
    if not v:isInArea(p:getArea(), chr) then
        ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(chr, v, p:getArea()))
    end
    if p:getDoor():isOpen() then ISVehicleMenu.onCloseDoor(chr, p) else ISVehicleMenu.onOpenDoor(chr, p) end
end

-- OPEN on a container: walk into its area (vanilla only lists it from there),
-- then show it in the Loot pane
local function openContainer(chr, v, part)
    local inv = part:getItemContainer()
    if not inv then return end
    if not v:isInArea(part:getArea(), chr) then
        ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(chr, v, part:getArea()))
    end
    if ZeD_WorldWindow and ZeD_WorldWindow.selectContainer then ZeD_WorldWindow.selectContainer(inv, 900) end
end

local function showInfo(chr, a)
    if not (ZeD_WorldWindow and ZeD_WorldWindow.openTab) then return end
    ZeD_WorldWindow.openTab(chr:getPlayerNum(), "animals")
    local win = ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    local AT = ZeD.AnimalsTab
    if win and AT and AT.showAnimal then AT.showAnimal(win, a) end
end

local function runVerb(id, chr, v, a)
    if id == "info" then showInfo(chr, a); return end
    local sq = entrySq(v)
    if not (sq and luautils.walkAdj(chr, sq)) then return end
    ISTimedActionQueue.add(ISRemoveAnimalFromTrailer:new(chr, v, a, id == "grab"))
end

-- Car <-> trailer: one press switches pages
local function towLink(v)
    local by = call(v, "getVehicleTowedBy")
    if by then return by, "towedBy" end   -- internal ids; the row translates them where it draws
    local towing = call(v, "getVehicleTowing")
    if towing then return towing, "towing" end
    return nil, nil
end
function TR.goTo(s, other)
    local MT = ZeD.MechanicsTab
    if MT.pin then MT.pin(other) end
    s.pendingId = other:getId()
    if s.win then MT.refresh(s.win) end
end

-- ----------------------------------------------------------------------------
-- The running trailer action: a band with its progress and the cancel X
-- ----------------------------------------------------------------------------
-- text keys: the band translates its label where it draws
local ACT_LABEL = {
    ISAddAnimalInTrailer = "UI_ZeD_Veh_ActPuttingIn", ISRemoveAnimalFromTrailer = "UI_ZeD_Veh_ActTakingOut",
    ISGiveWaterToAnimal = "UI_ZeD_Veh_ActGivingWater", ISFeedAnimalFromHand = "UI_ZeD_Veh_ActFeeding",
    ISOpenVehicleDoor = "UI_ZeD_Veh_ActOpeningLid", ISCloseVehicleDoor = "UI_ZeD_Veh_ActClosingLid",
    ISUnlockVehicleDoor = "UI_ZeD_Veh_ActUnlockingLid",
}
local function ours(a, v)
    if a.vehicle == v then return true end
    if a.animal then
        local av = call(a.animal, "getVehicle")
        if av == v then return true end
    end
    return false
end
local function trailerAction(chr, v)
    local q = ISTimedActionQueue.getTimedActionQueue(chr)
    local list = q and q.queue
    if not list or #list == 0 then return nil, nil end
    local target = nil
    for _, a in ipairs(list) do
        if ACT_LABEL[a.Type] and ours(a, v) then target = a; break end
    end
    if not target then return nil, nil end
    local label = ACT_LABEL[target.Type]
    if target.Type == "ISRemoveAnimalFromTrailer" and target.grab then label = "UI_ZeD_Veh_ActGrabbing" end
    if list[1] ~= target then label = "UI_ZeD_Veh_ActWalkingBack" end
    return list[1], label
end

local _cancelOpts = {}   -- the progress band's Cancel: its focus opts, reused each frame
local _backOpts = {}     -- the card back bar's back key
function TR.drawBand(panel, s, x, y, w, v, chr)
    local head, label = trailerAction(chr, v)
    if not head then return 0 end
    local pct = 0
    pcall(function() pct = head:getJobDelta() end)
    if label == "UI_ZeD_Veh_ActWalkingBack" then pct = 0 end
    local rect = {}
    _cancelOpts.focus = H().focusFor(s, "mech:cancel")   -- Cancel's mark, drawn under its icon
    local h = ZeD.Atoms.drawProgressBand(panel, x, y, w, "active", cased(ZeD.tr(label)), pct, nil, rect, false, _cancelOpts)
    if rect.w then
        H().stamp(s, "mech:cancel", rect.x, rect.y, rect.w, rect.h, function()
            pcall(function() ISTimedActionQueue.clear(chr) end)
        end)
    end
    return h
end

-- ----------------------------------------------------------------------------
-- Drawing pieces
-- ----------------------------------------------------------------------------
local function sumLabel(panel, x, y, rh, label)
    local T = ZeD.T
    local lc = T.textSec or T.toneLo
    label = cased(label)
    panel:drawText(label, x, y + math.floor((rh - T.fontF1H) / 2), lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)
    return ZeD.TM:MeasureStringX(T.fontF1, label)
end
-- right-aligned text; returns its left edge
local function rText(panel, right, y, rh, text, font, color)
    local T = ZeD.T
    font = font or T.fontF3
    local fh = ZeD.TM:getFontHeight(font)
    local tw = ZeD.TM:MeasureStringX(font, text)
    local c = color or T.text
    panel:drawText(text, right - tw, y + math.floor((rh - fh) / 2), c.r, c.g, c.b, c.a or 1, font)
    return right - tw
end
local function rDot(panel, right, y, rh, color)
    local d = ZeD.T.px(DOT_SZ)
    ZeD.Atoms.drawStatusDot(panel, right - d, y + math.floor((rh - d) / 2), color, d)
    return right - d
end

-- a summary row's height: the small push button inside it fits with room
local function srowH()
    local T = ZeD.T
    return math.max(T.px(SROW_H), T.buttonH - T.px(4) + T.px(2))
end

-- A push button inside a row (the library's, compact), right-aligned at `right`, centred in
-- the row height rh. One that cannot be pressed now is the same button greyed (0.42); it
-- still takes focus, and the line beside or under it says what it needs.
-- opts.clip: the body rect the row scrolls in (a button under the header is not hovered)
local function rowButton(panel, s, right, y, rh, label, variant, id, fn, enabled, opts)
    local T = ZeD.T
    local M = ZeD.Molecules
    local hp = H()
    local bw = M.buttonW(label)
    local bx = right - bw
    local clip = opts and opts.clip
    local hov = ZeD.Atoms.mouseIn(panel, bx, y, bw, rh, clip)
    local _, by, _, bh = M.drawButton(panel, bx, y, bw, rh, label, variant, false, nil, {
        compact = true, disabled = not enabled, hover = hov, win = s.win, focus = hp.focusFor(s, id), help = opts and opts.help })
    local o = { disabled = not enabled }
    if opts then for k, val in pairs(opts) do o[k] = val end end
    hp.stamp(s, id, bx, by, bw, bh, enabled and fn or function() end, o)
    return bw
end

-- The floor: each animal's share of the trailer's space, in list order, inside the same
-- framed strip every bar has (a dark well, a 1u frame, flat fills); what runs past the limit
-- hatched red (vanilla adds newborns without checking)
local function drawSpaceBar(panel, x, y, w, ms, cap, used, colors)
    local T = ZeD.T
    local A = ZeD.Atoms
    local h = T.fillBarH
    local bw = T.line(T.borderW)
    local bg = T.base
    panel:drawRect(x, y, w, h, 1, bg.r, bg.g, bg.b)
    local inX, inY, inW, inH = x + bw, y + bw, w - bw * 2, h - bw * 2
    local span = math.max(cap, used, 1)
    local cx = inX
    for _, m in ipairs(ms) do
        local segW = math.floor(inW * m.size / span + 0.5)
        if segW > 0 then
            local c = colors[m.atype] or T.accent
            panel:drawRect(cx, inY, math.min(segW, inX + inW - cx), inH, m.dead and 0.45 or 1, c.r, c.g, c.b)
            cx = cx + segW
            if cx < inX + inW then panel:drawRect(cx - T.hair, inY, T.hair, inH, 1, bg.r, bg.g, bg.b) end
        end
    end
    if used > cap + 0.001 then
        local capX = x + math.floor(w * cap / span + 0.5)
        local dg = T.danger
        local step, sw = T.px(4), T.px(2)
        local hx = capX + T.px(1)
        while hx < x + w - bw do
            panel:drawRect(hx, inY, math.min(sw, x + w - bw - hx), inH, 1, dg.r, dg.g, dg.b)
            hx = hx + step
        end
        panel:drawRect(capX, y - T.px(2), T.hair, h + 2 * T.px(2), 1, dg.r, dg.g, dg.b)
    end
    A.frame(panel, x, y, w, h, T.borderS, nil, bw)
    return h
end

local function containerInfo(part, chr)
    local c = part and part:getItemContainer()
    if not c then return nil end
    local items = c:getItems()
    local n = items:size()
    local byType, best, bestN, allEggs = {}, nil, 0, n > 0
    for i = 0, n - 1 do
        local it = items:get(i)
        local ft = it:getFullType()
        byType[ft] = (byType[ft] or 0) + 1
        if byType[ft] > bestN then best, bestN = it, byType[ft] end
        if not string.find(it:getType(), "Egg") then allEggs = false end
    end
    local w, cap = 0, 0
    pcall(function() w = c:getCapacityWeight() end)
    pcall(function() cap = part:getContainerCapacity(chr) end)
    return { n = n, best = best, bestN = bestN, allEggs = allEggs, weight = w, cap = cap }
end

-- The Food Container and the Egg Container: what is inside, how full, and Open (which shows
-- it in the Loot pane). Open waits for the trunk lid (one line under both rows says so).
-- Returns the row's height, 0 when the trailer has no such container.
local function containerRow(panel, s, sx, yy, sw, v, chr, partId, label, open, eggs)
    local part = v:getPartById(partId)
    local info = containerInfo(part, chr)
    if not info then return 0 end
    local T, TM, A = ZeD.T, ZeD.TM, ZeD.Atoms
    local srh = srowH()
    local lw = sumLabel(panel, sx, yy, srh, label)
    local bw = rowButton(panel, s, sx + sw, yy, srh, getText("IGUI_Open"), "default", "mech:open:" .. partId,
        function() openContainer(chr, v, part) end, open, { clip = s.bodyClip, help = ZeD.tr("UI_ZeD_Veh_HelpOpenBox") })
    local r = sx + sw - bw - T.px(8)
    local wt = string.format("%.1f / %d", info.weight, math.floor(info.cap + 0.5))
    r = rText(panel, r, yy, srh, wt, T.fontF3) - T.px(6)
    local barW = T.px(36)
    local bh = A.fillBarCompactH()
    -- ten segments; the help line the box's name and its weight ("Trunk 12.5 / 40")
    if A.drawFillBar(panel, r - barW, yy + math.floor((srh - bh) / 2), barW, info.cap > 0 and info.weight / info.cap or 0, false, nil, bh) then
        ZeD.Help.set(panel, ZeD.tr("UI_ZeD_Bar_Help", label, wt))
    end
    r = r - barW - T.px(8)
    local what
    if info.n == 0 then what = getText("Fluid_Empty")
    elseif eggs and info.allEggs then what = ZeD.tr(info.n == 1 and "UI_ZeD_Veh_EggOne" or "UI_ZeD_Veh_EggMany", info.n)
    else
        what = info.best:getDisplayName() .. " " .. DOT .. " " .. tostring(info.bestN)
        if info.n > info.bestN then what = what .. " +" .. tostring(info.n - info.bestN) end
    end
    local avail = r - (sx + lw + T.px(8))
    if avail > T.px(20) then
        if TM:MeasureStringX(T.fontF3, what) > avail then what = ZeD.Atoms.truncateText(what, T.fontF3, avail) end
        rText(panel, r, yy, srh, what, T.fontF3)
    end
    return srh
end

-- the towing link's key: a right triangle
local function nextGlyph(p, x, y, sz, c)
    local t = math.max(ZeD.T.px(6), math.floor(sz * 0.6))
    ZeD.Atoms.drawTriangleRight(p, x + math.floor((sz - t) / 2), y + math.floor((sz - t) / 2), t, c)
end

-- Towed by / Towing row, for any vehicle hitched to another; the key switches to the other one
function TR.drawTowRow(panel, s, sx, yy, sw, v)
    local other, label = towLink(v)
    if not other then return 0 end
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local srh = srowH()
    local lw = sumLabel(panel, sx, yy, srh, ZeD.tr(label == "towing" and "UI_ZeD_Veh_Towing" or "UI_ZeD_Veh_TowedBy"))
    local sz = T.buttonH - T.px(4)
    local bx = sx + sw - sz
    local by = yy + math.floor((srh - sz) / 2)
    local clip = s.bodyClip
    local hov = A.mouseIn(panel, bx, by, sz, sz, clip)
    M.drawIconButton(panel, bx, by, sz, nextGlyph, { hover = hov, win = s.win, id = "mech:tow",
        hint = ZeD.tr("UI_ZeD_Veh_HintGoTow"), help = ZeD.tr("UI_ZeD_Veh_HelpGoTow"), focus = H().focusFor(s, "mech:tow") })
    H().stamp(s, "mech:tow", bx, by, sz, sz, function() TR.goTo(s, other) end, { clip = clip })
    local name = H().vehicleName(other)
    if label == "towing" and TR.isTrailer(other) then
        local n = #animalsOf(other)
        name = name .. " " .. DOT .. " " .. ZeD.tr(n == 1 and "UI_ZeD_Animals_AnimalCountOne" or "UI_ZeD_Animals_AnimalCountMany", n)
    end
    local r = bx - T.px(8)
    local avail = r - (sx + lw + T.px(8))
    if ZeD.TM:MeasureStringX(T.fontF3, name) > avail then name = A.truncateText(name, T.fontF3, avail) end
    rText(panel, r, yy, srh, name, T.fontF3)
    return srh
end

-- ----------------------------------------------------------------------------
-- Summary (beside the figure). Returns the y below it.
-- ----------------------------------------------------------------------------
function TR.drawSummary(panel, win, s, sx, sy, sw, v, chr, inspected)
    local T, A, M, TM = ZeD.T, ZeD.Atoms, ZeD.Molecules, ZeD.TM
    local ms, colors, groups = s.trModels or {}, s.trColors or {}, s.trGroups or {}
    local yy = sy
    local cap = v:getAnimalTrailerSize()
    local used = v:getCurrentTotalAnimalSize()
    local over = used > cap + 0.001

    -- Space: used of the trailer's size, then the floor bar and its key
    local rh = math.max(T.fontF1H, T.fontF3H)
    sumLabel(panel, sx, yy, rh, ZeD.tr("UI_ZeD_Veh_Space"))
    local val = over and ZeD.tr("UI_ZeD_Veh_SpaceOver", fmt(used), fmt(cap), fmt(used - cap))
                or ZeD.tr("UI_ZeD_Veh_SpaceLeft", fmt(used), fmt(cap), fmt(cap - used))
    local left = rText(panel, sx + sw, yy, rh, val, T.fontF3)
    if over then rDot(panel, left - T.px(5), yy, rh, T.danger) end
    yy = yy + rh + T.px(4)
    yy = yy + drawSpaceBar(panel, sx, yy, sw, ms, cap, used, colors) + T.px(5)
    if #groups > 0 then
        local kx = sx
        local f1 = T.fontF1
        local sq = T.px(6)
        local dc = T.textDim
        for _, g in ipairs(groups) do
            local lbl = cased(g.label) .. " " .. fmt(g.size)
            local lw = TM:MeasureStringX(f1, lbl)
            if kx + sq + T.px(4) + lw > sx + sw then break end
            local c = colors[g.atype] or T.accent
            panel:drawRect(kx, yy + math.floor((T.fontF1H - sq) / 2), sq, sq, 1, c.r, c.g, c.b)
            panel:drawText(lbl, kx + sq + T.px(4), yy, dc.r, dc.g, dc.b, dc.a or 1, f1)
            kx = kx + sq + T.px(4) + lw + T.px(10)
        end
        yy = yy + T.fontF1H
    end
    yy = yy + T.px(6)
    A.drawDividerH(panel, sx, yy, sw, false)
    yy = yy + T.px(6)

    local srh = srowH()
    local open = TR.lidOpen(v)
    -- Trunk lid: vanilla shuts every loading option behind it
    local lid = lidPart(v)
    if lid and lid:getDoor() then
        sumLabel(panel, sx, yy, srh, ZeD.tr("IGUI_VehiclePartTrunkDoor"))
        local bw = rowButton(panel, s, sx + sw, yy, srh, open and getText("UI_Close") or getText("IGUI_Open"), open and "default" or "primary", "mech:lid",
            function() toggleLid(chr, v) end, true, { clip = s.bodyClip, help = ZeD.tr(open and "UI_ZeD_Veh_HelpCloseLid" or "UI_ZeD_Veh_HelpOpenLid") })
        local l2 = rText(panel, sx + sw - bw - T.px(8), yy, srh, open and ZeD.tr("UI_ZeD_Veh_StOpen") or ZeD.tr("UI_ZeD_Animals_BadgeShut"), T.fontF3)
        rDot(panel, l2 - T.px(5), yy, srh, open and T.positive or T.textDim)
        yy = yy + srh
    end
    -- the Food Container they eat from, the Egg Container hens lay in
    local fh = containerRow(panel, s, sx, yy, sw, v, chr, "TrailerAnimalFood", getText("IGUI_ItemCat_Food"), open, false)
    yy = yy + fh
    local eh = containerRow(panel, s, sx, yy, sw, v, chr, "TrailerAnimalEggs", ZeD.tr("UI_ZeD_Animals_Eggs"), open, true)
    yy = yy + eh
    if not open and (fh > 0 or eh > 0) then
        yy = yy + M.drawNeedsLine(panel, sx, yy, sw,
            ZeD.Disclose.needsLine({ label = getText("IGUI_Open"), needs = ZeD.tr("UI_ZeD_Veh_NeedLid") })) + T.px(4)
    end
    -- Thirsty: a trailer holds no water, they are watered by hand
    local alive, thirsty = 0, 0
    for _, m in ipairs(ms) do
        if not m.dead then
            alive = alive + 1
            if m.thirst >= THIRST_MIN then thirsty = thirsty + 1 end
        end
    end
    if alive > 0 then
        sumLabel(panel, sx, yy, srh, getText("IGUI_Animal_Thirsty"))
        local tt = (thirsty > 0) and ZeD.tr("UI_ZeD_Veh_ThirstyCount", thirsty, alive) or ZeD.tr("IGUI_None")
        local l3 = rText(panel, sx + sw, yy, srh, tt, T.fontF3)
        rDot(panel, l3 - T.px(5), yy, srh, thirsty > 0 and T.danger or T.positive)
        yy = yy + srh
    end
    yy = yy + TR.drawTowRow(panel, s, sx, yy, sw, v)
    if inspected then
        local h = H()
        local ov = h.overallCond(v)
        yy = yy + ZeD.Molecules.drawStatRowDot(panel, sx, yy, sw, ZeD.tr("UI_ZeD_Veh_Overall"), tostring(ov) .. "%", statusColor(T, ov))
    end
    return yy
end

-- ----------------------------------------------------------------------------
-- ANIMALS and LOAD FROM HERE (below the figure). Returns the y below them.
-- ----------------------------------------------------------------------------
-- a tag's mark colour for a severity word
local function sevMark(T, sev)
    if sev == "danger" then return T.danger elseif sev == "warning" then return T.warning end
    return nil
end

-- the list's group row ("v Animals (3)", the library's), with a column word at its right
local function catRow(panel, s, x, cy, cw, key, label, count, aside, clip, hover)
    local T = ZeD.T
    local ch = T.px(CAT_H)
    local pad = T.px(PAD)
    local id = "mech:cat:" .. key
    local hov = hover ~= nil and hover.y >= cy and hover.y < cy + ch and hover.x >= x and hover.x < x + cw
    ZeD.Molecules.drawCategoryRow(panel, x, cy, cw, label, count, not s.collapsed[key],
        { hover = hov, focus = H().focusFor(s, id), inset = pad })
    if aside then
        ZeD.Atoms.drawTextRight(panel, cased(aside), x + cw - pad, cy + math.floor((ch - T.fontF1H) / 2), T.fontF1, T.textDim)
    end
    H().stamp(s, id, x, cy, cw, ch, function() s.collapsed[key] = not s.collapsed[key] end,
        { clip = clip, isDisclosure = true })
    return ch
end

local function drawAnimalRow(panel, win, s, x, y, w, m, idx, clip, hovered)
    local T, A, M, TM = ZeD.T, ZeD.Atoms, ZeD.Molecules, ZeD.TM
    local h = H()
    local rh = T.px(AROW_H)
    local pad = T.px(PAD)
    if idx % 2 == 0 then
        local st = T.stripe
        panel:drawRect(x, y, w, rh, st.a, st.r, st.g, st.b)
    end
    if hovered then
        local hv = T.hover
        panel:drawRect(x, y, w, rh, hv.a, hv.r, hv.g, hv.b)
        help(panel, "UI_ZeD_Veh_HelpAnimalRow")
    end
    local id = "mech:an:" .. tostring(m.id or idx)
    local onFocus = h.markAt(s, panel, id, x, y, w, rh)
    local ink = onFocus and T.textOnFocus or T.text
    local inkDim = onFocus and T.textOnFocus or T.textDim
    local ps = T.px(PORT_SZ)
    local tex = portraitOf(m.a)
    if tex then
        panel:drawTextureScaledAspect(tex, x + pad, y + math.floor((rh - ps) / 2), ps, ps, m.dead and 0.45 or 0.95, 1, 1, 1)
    end
    local tx = x + pad + ps + T.px(8)
    -- the space column: what this animal takes
    local right = x + w - pad
    local szs = fmt(m.size)
    A.drawTextRight(panel, szs, right, y + math.floor((rh - T.fontF3H) / 2), T.fontF3, ink)
    right = right - math.max(TM:MeasureStringX(T.fontF3, szs), TM:MeasureStringX(T.fontF1, cased(ZeD.tr("UI_ZeD_Veh_Space")))) - T.px(12)
    -- tags, right-aligned before it: the word, and its square
    local f1 = T.fontF1
    local bx = right
    for i = #m.tags, 1, -1 do
        local tg = m.tags[i]
        local bw = TM:MeasureStringX(f1, cased(tg.label)) + T.px(20)
        if bx - bw < tx + T.px(60) then break end   -- the name keeps its room
        bx = bx - bw
        M.drawTag(panel, bx, y + math.floor((rh - T.px(16)) / 2), tg.label, sevMark(T, tg.sev))
        bx = bx - T.px(4)
    end
    -- name and the three needs squares (health, hunger, thirst) above the species line
    local blockH = T.fontF2H + T.px(2) + T.fontF1H
    local ty = y + math.floor((rh - blockH) / 2)
    local d = T.px(DOT_SZ)
    local dotsW = d * 3 + T.px(5) * 2 + T.px(8)
    local nameMax = bx - T.px(6) - tx - dotsW
    local nm = m.name
    if TM:MeasureStringX(T.fontF2, nm) > nameMax then nm = A.truncateText(nm, T.fontF2, math.max(T.px(20), nameMax)) end
    panel:drawText(nm, tx, ty, ink.r, ink.g, ink.b, ink.a or 1, T.fontF2)
    local dx = tx + TM:MeasureStringX(T.fontF2, nm) + T.px(8)
    local dy = ty + math.floor((T.fontF2H - d) / 2)
    local off = { r = T.textDim.r, g = T.textDim.g, b = T.textDim.b, a = 0.35 }
    local cols
    if m.dead then cols = { T.danger, off, off }
    else
        cols = { statusColor(T, m.health), statusColor(T, 100 - m.hunger * 100), statusColor(T, 100 - m.thirst * 100) }
    end
    for i = 1, 3 do
        A.drawStatusDot(panel, dx, dy, cols[i], d)
        dx = dx + d + T.px(5)
    end
    -- species, sex, age
    local ad = AD()
    local sex = m.baby and getText("IGUI_Animal_Baby") or (m.female and getText("IGUI_Animal_Female") or getText("IGUI_Animal_Male"))
    local sub = speciesLabel(m.atype) .. ", " .. sex
    local age = ad.getAgeText(m.a, (win and win._playerObj) or getSpecificPlayer(0))
    if age and age ~= "" then sub = sub .. " " .. DOT .. " " .. age end
    local subMax = bx - T.px(6) - tx
    if TM:MeasureStringX(f1, sub) > subMax then sub = A.truncateText(sub, f1, math.max(T.px(20), subMax)) end
    panel:drawText(sub, tx, ty + T.fontF2H + T.px(2), inkDim.r, inkDim.g, inkDim.b, inkDim.a or 1, f1)
    A.drawDividerH(panel, x, y + rh - T.px(1), w, false)
    local a = m.a
    h.stamp(s, id, x, y, w, rh, function() TR.openAnimal(win, s, a) end, { clip = clip })
    return rh
end

local function drawLoadRow(panel, s, x, y, w, c, clip, primary, open)
    local T, A, M, TM = ZeD.T, ZeD.Atoms, ZeD.Molecules, ZeD.TM
    local rh = T.px(LROW_H)
    local pad = T.px(PAD)
    local ps = T.px(LPORT_SZ)
    local tex = portraitOf(c.port)
    if tex then
        panel:drawTextureScaledAspect(tex, x + pad, y + math.floor((rh - ps) / 2), ps, ps, c.ok and 0.95 or 0.5, 1, 1, 1)
    end
    local tx = x + pad + ps + T.px(8)
    local enabled = c.ok and open
    local bw = rowButton(panel, s, x + w - pad, y, rh, ZeD.tr("UI_ZeD_Veh_PutIn"), primary and "primary" or "default", "mech:load:" .. c.key,
        c.run, enabled, { clip = clip, help = ZeD.tr("UI_ZeD_Veh_HelpPutIn") })
    local right = x + w - pad - bw - T.px(12)
    local szs = fmt(c.size)
    A.drawTextRight(panel, szs, right, y + math.floor((rh - T.fontF3H) / 2), T.fontF3, c.ok and T.text or T.textDim)
    right = right - TM:MeasureStringX(T.fontF3, szs) - T.px(10)
    local blockH = T.fontF2H + T.px(1) + T.fontF1H
    local ty = y + math.floor((rh - blockH) / 2)
    local maxW = right - tx
    local nm = c.name
    if TM:MeasureStringX(T.fontF2, nm) > maxW then nm = A.truncateText(nm, T.fontF2, math.max(T.px(20), maxW)) end
    local tc = c.ok and T.text or T.textDim
    panel:drawText(nm, tx, ty, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
    local dc = T.textDim
    panel:drawText(c.loc, tx, ty + T.fontF2H + T.px(1), dc.r, dc.g, dc.b, dc.a or 1, T.fontF1)
    local hh = rh
    -- what keeps it from going in: a NEEDS line under the row, in vanilla's words
    if c.why then
        local nh = M.drawNeedsLine(panel, tx, y + rh - T.px(2), x + w - pad - tx, c.why)
        hh = rh - T.px(2) + nh + T.px(4)
    end
    A.drawDividerH(panel, x, y + hh - T.px(1), w, false)
    return hh
end

-- hover = { x, y } of the mouse when it is over the page body (nil otherwise)
function TR.drawSections(panel, win, s, x, cy, cw, v, chr, clip, hover)
    local T, M = ZeD.T, ZeD.Molecules
    local pad = T.px(PAD)
    local ms = s.trModels or {}
    local open = TR.lidOpen(v)
    if not open then
        cy = cy + M.drawNeedsLine(panel, x + pad, cy, cw - pad * 2, getText("Tooltip_Animal_OpenTrunkDoor")) + T.px(6)
    end
    -- Animals
    s.trAnimalsY = cy
    cy = cy + catRow(panel, s, x, cy, cw, "_animals", getText("IGUI_ScavengeUI_Animals"), #ms, ZeD.tr("UI_ZeD_Veh_Space"), clip, hover)
    if not s.collapsed["_animals"] then
        if #ms == 0 then
            cy = cy + T.px(8)
            cy = cy + M.drawEmptyLine(panel, x + pad, cy, cw - pad * 2, ZeD.tr("UI_ZeD_Veh_NoAnimalsHere")) + T.px(8)
        end
        for i, m in ipairs(ms) do
            local rh = T.px(AROW_H)
            local hovered = hover ~= nil and hover.y >= cy and hover.y < cy + rh and hover.x >= x and hover.x < x + cw
            cy = cy + drawAnimalRow(panel, win, s, x, cy, cw, m, i, clip, hovered)
        end
    end
    s.trAnimalsEnd = cy
    -- Load from here: only with the lid open (vanilla greys Add Animal behind it)
    if open then
        local cands = loadCandidates(s, v, chr)
        if #cands > 0 then
            cy = cy + catRow(panel, s, x, cy, cw, "_load", ZeD.tr("UI_ZeD_Veh_LoadFromHere"), #cands, ZeD.tr("UI_ZeD_Veh_SizeHdr"), clip, hover)
            if not s.collapsed["_load"] then
                local firstOk = nil
                for i, c in ipairs(cands) do if c.ok then firstOk = i; break end end
                for i, c in ipairs(cands) do
                    cy = cy + drawLoadRow(panel, s, x, cy, cw, c, clip, i == firstOk, open)
                end
            end
        end
    end
    return cy
end

-- ----------------------------------------------------------------------------
-- The animal's card
-- ----------------------------------------------------------------------------
function TR.openAnimal(win, s, a)
    s.view, s.animal, s.animalId = "animal", a, animalId(a)
    s.cardScroll = 0
    s.trItems = nil
    win._mechFocusTarget = "animal"
end

function TR.hideAvatar(s)
    local av = s and s.avatar
    if av and av:getIsVisible() then av:setVisible(false) end
end

function TR.closeAnimal(win, s)
    local id = s.animalId
    s.view, s.animal, s.animalId = "overview", nil, nil
    win._mechFocusTarget = id and ("mech:an:" .. tostring(id)) or "animals"
    TR.hideAvatar(s)
end

local function findAnimal(v, s)
    for _, a in ipairs(animalsOf(v)) do
        if a == s.animal or (s.animalId ~= nil and animalId(a) == s.animalId) then return a end
    end
    return nil
end

-- Vanilla's 3D figure (ISVehicleAnimal3DModel), a child of the tab panel. It
-- hides itself when the card stops placing it (another tab, view or window).
local function ensureAvatar(s, panel, a)
    local av = s.avatar
    if av and av._zedHost ~= panel then
        pcall(function() av:setVisible(false); av._zedHost:removeChild(av) end)
        s.avatar, av = nil, nil
    end
    if not av then
        if not ISVehicleAnimal3DModel then return nil end
        local ok, made = pcall(function()
            local p = ISVehicleAnimal3DModel:new(0, 0, 10, 10)
            panel:addChild(p)
            p._zedHost = panel
            local base = p.prerender
            p.prerender = function(self)
                local seen = self._zedSeen or 0
                if H().now() - seen > 200 then self:setVisible(false); return end
                if base then return base(self) end
            end
            return p
        end)
        if not ok then
            print("[ZeD] MechTrailer: 3D figure failed: " .. tostring(made))
            return nil
        end
        s.avatar, av = made, made
    end
    if av._zedAnimal ~= a then
        pcall(function()
            av:setAnimSetName(a:GetAnimSetName())
            av:setCharacter(a)
            av:setDirection(IsoDirections.S)
        end)
        av._zedAnimal = a
    end
    return av
end

local function placeAvatar(s, panel, a, x, y, w, h, top, bodyH)
    local av = ensureAvatar(s, panel, a)
    if not av then return end
    av._zedSeen = H().now()
    if av:getX() ~= x then av:setX(x) end
    if av:getY() ~= y then av:setY(y) end
    if av:getWidth() ~= w then av:setWidth(w) end
    if av:getHeight() ~= h then av:setHeight(h) end
    -- vanilla's trailer framing (ISVehicleAnimalUI:prerenderScrollPanel)
    pcall(function()
        local def = AnimalAvatarDefinition and AnimalAvatarDefinition[a:getAnimalType()]
        if def then
            local size = a:getData():getSize()
            av:setZoom(def.trailerZoom * size)
            av:setXOffset(def.trailerXoffset * size)
            av:setYOffset(def.trailerYoffset * size)
            av:setDirection(def.trailerDir)
        end
        av:setVariable("TrailerAnimation", a:isDead() and "dead" or "idle1")
    end)
    local inView = y >= top and y + h <= top + bodyH
    if av:getIsVisible() ~= inView then av:setVisible(inView) end
end

-- vital row: label, a word with its status square, a short framed bar (good = full)
local function vital(panel, x, y, w, label, value, pct, dotColor)
    local T = ZeD.T
    local A = ZeD.Atoms
    local rh = T.px(VROW_H)
    sumLabel(panel, x, y, rh, label)
    local right = x + w
    if pct then
        local bw = T.px(VBAR_W)
        local bh = A.fillBarCompactH()
        -- ten segments; the help line the row's own reading ("Hunger Peckish": the word, as the Animals
        -- tab gives it, no figure the game keeps back)
        if A.drawFillBar(panel, right - bw, y + math.floor((rh - bh) / 2), bw, math.max(0, math.min(1, pct / 100)), true, nil, bh) then
            ZeD.Help.set(panel, ZeD.tr("UI_ZeD_Bar_Help", label, value))
        end
        right = right - bw - T.px(8)
    end
    local l = rText(panel, right, y, rh, value, T.fontF3)
    if dotColor then rDot(panel, l - T.px(5), y, rh, dotColor) end
    return rh
end

local function hungerWord(h)
    if h < 20 then return getText("IGUI_Animal_WellFed") elseif h < 50 then return getText("Moodles_Hungry_lvl1")
    elseif h < 80 then return getText("Moodles_Hungry_lvl2") end
    return getText("IGUI_Animal_Starving")
end
local function thirstWord(t)
    if t < 20 then return ZeD.tr("UI_ZeD_Animals_ThirstHydrated") elseif t < 50 then return ZeD.tr("UI_ZeD_Animals_ThirstParched")
    elseif t < 80 then return getText("IGUI_Animal_Thirsty") end
    return ZeD.tr("UI_ZeD_Animals_ThirstDehydrated")
end

-- Returns false when the animal has left the trailer (the caller shows the page)
function TR.renderAnimal(panel, win, s, x, y, w, h, v, chr)
    local T, A, M, TM = ZeD.T, ZeD.Atoms, ZeD.Molecules, ZeD.TM
    local DS = ZeD.Disclose
    local hp = H()
    local a = findAnimal(v, s)
    if not a then TR.closeAnimal(win, s); return false end
    s.animal = a
    local m = model(a, chr)
    local ad = AD()
    local open = TR.lidOpen(v)
    local busyHead = trailerAction(chr, v)
    local busy = busyHead ~= nil
    local canPick = call(a, "canBePicked", chr) and true or false
    local lid = lidPart(v)
    local lidNeed = ZeD.tr("UI_ZeD_Veh_NeedLid")

    -- The verbs. Every one waits for the trunk lid; Grab also for an animal you can lift. The ones
    -- you can do are shown, the rest fold into one row after them (a carcass has no Info).
    local list = {
        { id = "remove", label = getText("ContextMenu_Remove"), canDo = open, sensible = true, needs = lidNeed,
          hint = ZeD.tr("UI_ZeD_Veh_HintRemoveAnimal"), primary = m.dead, help = ZeD.tr("UI_ZeD_Veh_HelpRemoveAnimal") },
        { id = "grab", label = getText("ContextMenu_Grab"), canDo = open and canPick, sensible = true, needs = lidNeed,
          needsLine = (open and not canPick) and ZeD.tr("UI_ZeD_Veh_GrabWhy", getText("Tooltip_Animal_TooHeavy")) or nil,
          hint = ZeD.tr("UI_ZeD_Veh_HintGrabAnimal"), help = ZeD.tr("UI_ZeD_Veh_HelpGrabAnimal") },
        { id = "info", label = getText("ContextMenu_Info"), canDo = true, sensible = not m.dead,
          help = ZeD.tr("UI_ZeD_Veh_HelpInfoAnimal") },
    }
    local shown, hidden = DS.split(list)

    -- header: back, name, the verbs you can do
    local defs = {}
    for i, vb in ipairs(shown) do
        defs[i] = { label = vb.label, primary = vb.primary and vb.canDo, disabled = not vb.canDo,
                    focus = hp.focusFor(s, "mech:av:" .. vb.id), help = vb.help }
    end
    local rects = {}
    _backOpts.focus = hp.focusFor(s, "mech:back")
    _backOpts.focusId = _backOpts.focus and "back" or nil
    local headerH = M.drawCardBackBar(panel, x, y, w, m.name, defs, busy, false, rects, _backOpts)
    hp.stamp(s, "mech:back", rects.back.x, rects.back.y, rects.back.w, rects.back.h, function() TR.closeAnimal(win, s) end)
    for i, vb in ipairs(shown) do
        local r = rects.verbs and rects.verbs[i]
        if r then
            hp.stamp(s, "mech:av:" .. vb.id, r.x, r.y, r.w, r.h, function()
                if busy or not vb.canDo then return end
                runVerb(vb.id, chr, v, a)
            end, { disabled = busy or not vb.canDo })
        end
    end

    -- the band: Open lid, while the lid is shut and nothing is running (the verbs wait for it)
    local lidBtn = (not open) and lid ~= nil and lid:getDoor() ~= nil and not busy
    local bandH = lidBtn and M.bandH() or 0
    local top = y + headerH
    local pbH = TR.drawBand(panel, s, x, top, w, v, chr)
    top = top + pbH
    local bodyH = h - headerH - pbH - bandH
    local scrollW = T.sp.scrollbarW
    local cw = w - scrollW
    local pad = T.px(12)
    local clip = { x = x, y = top, w = w, h = bodyH }
    local gpId = s.gpId

    panel:setStencilRect(x, top, w, bodyH)
    local cy = top - s.cardScroll + pad

    -- a verb shown greyed (the setting "show all") says what it needs; the others are one folded row
    for _, vb in ipairs(shown) do
        if not vb.canDo then
            cy = cy + M.drawNeedsLine(panel, x + pad, cy, cw - pad * 2, DS.needsLine(vb)) + T.px(4)
        end
    end
    if #hidden > 0 then
        local mh, rowRect = M.drawMoreRow(panel, x + pad, cy, cw - pad * 2, hidden, "veh:animal",
            { focus = hp.focusFor(s, "mech:more"), win = win })
        if rowRect then
            hp.stamp(s, "mech:more", rowRect.x, rowRect.y, rowRect.w, rowRect.h, function() DS.toggle("veh:animal") end, { clip = clip })
        end
        cy = cy + mh + T.px(6)
    end

    -- vanilla's 3D figure beside the vitals
    local aw, ah = T.px(AV_W), T.px(AV_H)
    local ax, ay = x + pad, cy
    A.surfaceFill(panel, ax, ay, aw, ah, "surf2")
    A.frame(panel, ax, ay, aw, ah, T.borderS)
    local gx = ax + aw + T.px(12)
    local gw = x + cw - pad - gx
    local vy = cy
    local cap = v:getAnimalTrailerSize()
    if m.dead then
        vy = vy + vital(panel, gx, vy, gw, ZeD.tr("UI_ZeD_Veh_State"), getText("IGUI_DesignationZone_Dead"), nil, T.danger)
    else
        local health = m.health
        local ht = ad.getHealthText(a, chr)
        if not ht or ht == "" then ht = tostring(math.floor(health)) .. "%" end
        vy = vy + vital(panel, gx, vy, gw, getText("IGUI_HealthTooltip"), ht, health)
        local hu = m.hunger * 100
        vy = vy + vital(panel, gx, vy, gw, getText("IGUI_StatsAndBody_Hunger"), hungerWord(hu), 100 - hu)
        local th = m.thirst * 100
        vy = vy + vital(panel, gx, vy, gw, getText("IGUI_StatsAndBody_Thirst"), thirstWord(th), 100 - th)
        local st = ad.getStressText(a, chr)
        if not st or st == "" then st = tostring(math.floor(m.stress)) .. "%" end
        vy = vy + vital(panel, gx, vy, gw, getText("IGUI_StatsAndBody_Stress"), st, 100 - m.stress)
        if ad.canSee(chr, "weight_rough") then
            local kg = ad.getWeight(a)
            if kg > 0 then vy = vy + vital(panel, gx, vy, gw, getText("IGUI_char_Weight"), ZeD.tr("UI_ZeD_Animals_WeightKg", string.format("%.0f", kg))) end
        end
    end
    vy = vy + vital(panel, gx, vy, gw, ZeD.tr("UI_ZeD_Veh_Space"), ZeD.tr("UI_ZeD_Veh_OfCap", fmt(m.size), fmt(cap)))
    local figTop = cy
    cy = cy + math.max(ah, vy - cy) + T.px(12)

    local function section(text, aside)
        local sh = M.drawSectionHeader(panel, x + pad, cy, cw - pad, text, nil, true, false, nil, nil, pad, T.px(SEC_H), true)
        if aside then A.drawTextRight(panel, cased(aside), x + cw - pad, cy + math.floor((T.px(SEC_H) - T.fontF1H) / 2), T.fontF1, T.textDim) end
        cy = cy + sh + T.px(4)
    end
    local function dimLine(text)
        cy = cy + M.drawEmptyLine(panel, x + pad, cy, cw - pad * 2, text) + T.px(4)
    end
    -- a pick row: a status square, name over a line of where it is, and its button
    local function pickRow(id, dotC, name, meta, label, fn, helpText)
        local rh = T.px(PICK_H)
        local d = T.px(DOT_SZ)
        A.drawStatusDot(panel, x + pad, cy + math.floor((rh - d) / 2), dotC, d)
        local bw = rowButton(panel, s, x + cw - pad, cy, rh, label, "default", id, fn, open and not busy, { clip = clip, help = helpText })
        local tx = x + pad + d + T.px(8)
        local maxW = x + cw - pad - bw - T.px(10) - tx
        local blockH = T.fontF2H + T.px(1) + T.fontF1H
        local ty = cy + math.floor((rh - blockH) / 2)
        local nm = name
        if TM:MeasureStringX(T.fontF2, nm) > maxW then nm = A.truncateText(nm, T.fontF2, math.max(T.px(20), maxW)) end
        local tc = T.text
        panel:drawText(nm, tx, ty, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        local dc = T.textDim
        panel:drawText(meta, tx, ty + T.fontF2H + T.px(1), dc.r, dc.g, dc.b, dc.a or 1, T.fontF1)
        A.drawDividerH(panel, x + pad, cy + rh - T.px(1), cw - pad * 2, false)
        cy = cy + rh
    end

    if not m.dead then
        local have = carried(s, chr, a)
        -- Water: shown when vanilla offers it (thirst past 10%)
        if m.thirst >= THIRST_MIN then
            section(getText("ContextMenu_WaterAnimal"), ZeD.tr("UI_ZeD_Veh_FromYourBags"))
            if not open then
                cy = cy + M.drawNeedsLine(panel, x + pad, cy, cw - pad * 2,
                    DS.needsLine({ label = getText("ContextMenu_WaterAnimal"), needs = lidNeed })) + T.px(4)
            end
            if #have.water == 0 then dimLine(getText("ContextMenu_NoWaterItemFound")) end
            for i, wsrc in ipairs(have.water) do
                local item = wsrc.item
                pickRow("mech:water:" .. tostring(i), T.info, wsrc.name, wsrc.meta, getText("IGUI_FeedingTroughUI_Water"), function()
                    AnimalContextMenu.onGiveWater(chr, a, item)
                end, ZeD.tr("UI_ZeD_Veh_HelpGiveWater"))
            end
            cy = cy + T.px(10)
        end
        -- Feed: what it eats from what you carry (hunger past 10%)
        if m.hunger >= HUNGER_MIN then
            section(getText("ContextMenu_Feed"), ZeD.tr("UI_ZeD_Veh_WhatItEats"))
            if not open then
                cy = cy + M.drawNeedsLine(panel, x + pad, cy, cw - pad * 2,
                    DS.needsLine({ label = getText("ContextMenu_Feed"), needs = lidNeed })) + T.px(4)
            end
            if #have.feed == 0 then dimLine(ZeD.tr("UI_ZeD_Veh_NothingItEats")) end
            for i, f in ipairs(have.feed) do
                local item = f.item
                local nm = f.name .. ((f.n > 1) and (" " .. DOT .. " " .. tostring(f.n)) or "")
                pickRow("mech:feed:" .. tostring(i), T.positive, nm, f.loc, getText("ContextMenu_Feed"), function()
                    AnimalContextMenu.onFeedAnimalFood(chr, a, item)
                end, ZeD.tr("UI_ZeD_Veh_HelpFeed"))
            end
            cy = cy + T.px(10)
        end
    end
    panel:clearStencilRect()

    placeAvatar(s, panel, a, ax, figTop, aw, ah, top, bodyH)

    local total = (cy + s.cardScroll) - top
    s.maxScroll = math.max(0, total - bodyH)
    if s.cardScroll > s.maxScroll then s.cardScroll = s.maxScroll end
    s.bodyRect = clip
    hp.drawScrollbar(panel, x + w - scrollW, top, bodyH, total, s.cardScroll)
    if gpId then
        local z = s.byId[gpId]
        if z and z.clip then
            if z.y < top then s.cardScroll = math.max(0, s.cardScroll - (top - z.y))
            elseif z.y + z.h > top + bodyH then s.cardScroll = math.min(s.maxScroll, s.cardScroll + (z.y + z.h - (top + bodyH))) end
        end
    end

    -- the band: Open lid
    if lidBtn then
        local _, out = M.drawBand(panel, x, y + h - bandH, w, { win = win, buttons = {
            { label = getText("ContextMenu_OpenLid"), variant = "primary", focus = hp.focusFor(s, "mech:openlid"),
              help = ZeD.tr("UI_ZeD_Veh_HelpOpenLid") } } })
        local r = out.buttons[1]
        hp.stamp(s, "mech:openlid", r.x, r.y, r.w, r.h, function() toggleLid(chr, v) end, { footer = true })
    end
    return true
end

-- Gamepad focus after the page opens on the animals or a card closes
function TR.focusTarget(t, els)
    if t == "animal" then
        for i, e in ipairs(els) do if e.id:sub(1, 8) == "mech:av:" then return i end end
        for i, e in ipairs(els) do if e.id == "mech:back" then return i end end
    elseif t == "animals" then
        for i, e in ipairs(els) do if e.id:sub(1, 8) == "mech:an:" then return i end end
        for i, e in ipairs(els) do if e.id == "mech:cat:_animals" then return i end end
    end
    return nil
end

print("[ZeD] MechTrailer: animal trailer page loaded")
return TR
