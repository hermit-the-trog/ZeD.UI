-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardHutch.lua
-- ============================================================================
-- OBJECT CARD: HUTCH (HOOK_MAP row 20; mockup zed_animal_cards_v1.html)
-- Vanilla's two-tab Hutch window (egg laying boxes, coop roosting) becomes one
-- card in the World window's card drawer:
--   * the two doors as lamps, with OPEN / CLOSE DOOR and OPEN / CLOSE HATCH;
--   * EGG LAYING BOXES: each box's eggs (vanilla's ten slots) or the hen
--     sitting in it, GRAB per box and GRAB EGGS for every free box;
--   * COOP ROOSTING: every bird with GRAB (a dead one is taken as a corpse)
--     and INFO (the bird in the Animals tab);
--   * FLOOR: dirtiness in vanilla's colours, CLEAN and what cleaning takes;
--   * PUT IN when you carry a bird the hutch takes (vanilla: world menu only).
-- Vanilla's rules stay: no eggs while a hen sits on them; the boxes are out of
-- reach with both doors shut, the perches with the main door shut; the card
-- closes past 5 tiles of the entry square. Every action is vanilla's own
-- timed action, queued as the vanilla window queues it.
-- ============================================================================

require "ZeD/ObjectCards"

local OC = ZeD.ObjectCards
local UI = OC.ui
local call = OC.call
local DOT = OC.DOT

local function txt(k, fb) local s = getTextOrNull and getTextOrNull(k) return s or fb or k end
local function col(c) return c.r, c.g, c.b end
local function notBroken(item) return not item:isBroken() end

local BOX_H, BIRD_H = 104, 30

local def = { id = "hutch", leash = 5 }

local function masterOf(o)
    if not (o and instanceof(o, "IsoHutch")) then return nil end
    return call(o, "getHutch") or o
end

function def.resolve(player, obj)
    local h = masterOf(obj)
    if not (h and h:getSquare()) then return nil end
    -- the leash is vanilla's: 5 tiles from the entry square
    local sq = call(h, "getEntrySq") or h:getSquare()
    return { obj = h, sq = sq, key = OC.keyOf(h:getSquare(), "hutch") }
end

function def.valid(t)
    local h = t.obj
    return h ~= nil and h:getSquare() ~= nil and (call(h, "getObjectIndex") or 0) >= 0
end

-- hutches within reach, for the browse arrows
function def.nearby(player)
    local seen, out = {}, {}
    OC.eachSquare(player, def.leash + 1, function(sq)
        local objs = sq:getObjects()
        for i = 0, objs:size() - 1 do
            local m = masterOf(objs:get(i))
            if m and not seen[m] then
                seen[m] = true
                local t = def.resolve(player, m)
                if t then out[#out + 1] = t end
            end
        end
    end)
    return OC.sortTargets(out)
end

-- ---------------------------------------------------------------------------
-- ACTIONS (vanilla's, as ISHutchUI / ISHutchMenu queue them)
-- ---------------------------------------------------------------------------
local function unequipHands(p)
    local prim, sec = p:getPrimaryHandItem(), p:getSecondaryHandItem()
    if prim then ISTimedActionQueue.add(ISUnequipAction:new(p, prim, 50)) end
    if sec and sec ~= prim then ISTimedActionQueue.add(ISUnequipAction:new(p, sec, 50)) end
end

-- Vanilla's queue drops whatever waits behind a finished ISHutchGrabEgg, so
-- several boxes chain: the first is queued now, the rest one at a time from
-- the refresh once you are idle (t.eggChain; any other verb cancels it).
local function grabEggs(p, h, boxes, t)
    if #boxes == 0 then return end
    if not luautils.walkAdj(p, h:getEntrySq()) then return end
    unequipHands(p)
    ISTimedActionQueue.add(ISHutchGrabEgg:new(p, boxes[1].nest, h))
    if t then
        t.eggChain = {}
        for k = 2, #boxes do t.eggChain[#t.eggChain + 1] = boxes[k].nest end
    end
end

local function chainEggs(t, player)
    local chain = t.eggChain
    if not (chain and #chain > 0) then return end
    if ISTimedActionQueue.isPlayerDoingAction(player) then return end
    while #chain > 0 do
        local nest = table.remove(chain, 1)
        if (call(nest, "getEggsNb") or 0) > 0 then
            ISTimedActionQueue.add(ISHutchGrabEgg:new(player, nest, t.obj))
            return
        end
    end
end

local function grabBird(p, h, b)
    if not luautils.walkAdj(p, h:getEntrySq()) then return end
    unequipHands(p)
    if b.dead and b.body then
        ISTimedActionQueue.add(ISHutchGrabCorpseAction:new(p, b.i, h))
    else
        ISTimedActionQueue.add(ISHutchGrabAnimal:new(p, b.i, h))
    end
end

local function clean(p, h)
    if not luautils.walkAdj(p, h:getEntrySq()) then return end
    local inv = p:getInventory()
    local water = inv:getFirstWaterFluidSources(true, true)
    local bleach = inv:getFirstCleaningFluidSources()
    local mop = inv:getFirstTagEvalRecurse(ItemTag.CLEAN_STAINS, notBroken)
    ISWorldObjectContextMenu.equip(p, p:getPrimaryHandItem(), mop, true, false)
    ISTimedActionQueue.add(ISHutchCleanFloor:new(p, h, water, mop, bleach))
end

-- INFO: the bird in the Animals tab (its zone, then the animal view)
local function showBird(p, animal)
    local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end
    if ZeD_WorldWindow.openTab then ZeD_WorldWindow.openTab(p:getPlayerNum(), "animals") end
    win = ZeD_WorldWindow.getWindow()
    local AT = ZeD.AnimalsTab
    if win and AT and AT.showAnimal then AT.showAnimal(win, animal) end
end

-- ---------------------------------------------------------------------------
-- REFRESH
-- ---------------------------------------------------------------------------
-- vanilla's names (Henhouse, Turkeyhouse): the hutch type from its tiles
local function hutchName(h)
    local spr = h:getSprite() and h:getSprite():getName()
    local defs = HutchDefinitions and HutchDefinitions.hutchs
    if spr and defs then
        for k, d in pairs(defs) do
            local hit = d.baseSprite == spr
            for _, e in ipairs(d.eggHatchDoors or {}) do if e.sprite == spr or e.closedSprite == spr then hit = true end end
            for _, e in ipairs(d.extraSprites or {}) do if e.sprite == spr or e.spriteOpen == spr then hit = true end end
            if hit then return txt("ContextMenu_Hutch_" .. k, txt("ContextMenu_Hutch", "Hutch")) end
        end
    end
    return txt("ContextMenu_Hutch", "Hutch")
end

local function birdName(a)
    local n = call(a, "getCustomName")
    if n and n ~= "" then return n end
    return call(a, "getFullName") or (ZeD.AnimalsData and ZeD.AnimalsData.getDisplayName(a)) or "?"
end

local function birdSub(a)
    local AD = ZeD.AnimalsData
    local atype = AD and AD.getAnimalType(a) or (call(a, "getAnimalType") or "")
    local species = txt("IGUI_AnimalType_" .. tostring(atype), tostring(atype))
    local key = "UI_ZeD_Hutch_SubAdult"
    if AD and AD.isBaby(a) then key = "UI_ZeD_Hutch_SubYoung" end
    return ZeD.tr(key, ZeD.upper(species))
end

function def.refresh(t, player)
    local h = t.obj
    chainEggs(t, player)
    local d = {}
    d.name = hutchName(h)
    d.icon = OC.spriteIcon(h)
    d.doorOpen = h:isOpen() == true
    d.hatchOpen = h:isEggHatchDoorOpen() == true
    d.allClosed = h:isAllDoorClosed() == true
    d.boxesShown = not d.allClosed   -- vanilla covers the boxes only with both doors shut
    d.roostShown = d.doorOpen        -- and the perches with the main door shut

    -- nest boxes
    d.boxes = {}
    d.eggs, d.free = 0, {}
    local nb = (call(h, "getMaxNestBox") or 3) + 1
    for i = 0, nb - 1 do
        local nest = call(h, "getNestBox", i)
        local eggs = nest and (call(nest, "getEggsNb") or 0) or 0
        local hen = call(h, "getAnimalInNestBox", i)
        local b = { i = i, nest = nest, eggs = eggs, hen = hen, henName = hen and birdName(hen) }
        d.boxes[#d.boxes + 1] = b
        d.eggs = d.eggs + eggs
        if nest and eggs > 0 and not hen then d.free[#d.free + 1] = b end
    end
    d.full = call(h, "haveRoomForNewEggs") == false

    -- perches
    d.max = call(h, "getMaxAnimals") or 20
    d.birds = {}
    for i = 0, d.max - 1 do
        local a = call(h, "getAnimal", i)
        if a then
            local dead = call(a, "isDead") == true
            d.birds[#d.birds + 1] = { i = i, a = a, dead = dead, body = dead and call(h, "getDeadBody", i) or nil,
                name = birdName(a), sub = birdSub(a), tex = ZeD.AnimalsData and getTexture(ZeD.AnimalsData.resolvePortrait(a)) }
        end
    end

    -- floor
    d.dirt = call(h, "getHutchDirt") or 0
    local inv = player:getInventory()
    local waters = inv:getAllWaterFluidSources(true)
    d.water = (waters and not waters:isEmpty()) and inv:getFirstWaterFluidSources(true, true) or nil
    d.mop = inv:getFirstTagEvalRecurse(ItemTag.CLEAN_STAINS, notBroken)
    d.bleach = inv:getFirstCleaningFluidSources()

    -- a bird in hand
    local held = player:getPrimaryHandItem()
    if held and instanceof(held, "AnimalInventoryItem") then
        local a = held:getAnimal()
        if a and call(a, "canBePutInHutch", h) then d.carry = a end
    end
    local inside = call(h, "getAnimalInside")
    d.count = inside and inside:size() or #d.birds
    t.d = d

    -- verbs
    local verbs, needs = {}, {}
    local function doorVerb(primary)
        verbs[#verbs + 1] = { id = "door", label = ZeD.upper(d.doorOpen and txt("ContextMenu_Close_door", "Close Door") or txt("ContextMenu_Open_door", "Open Door")),
            primary = primary, run = function(p, tt) tt.eggChain = nil; ISHutchMenu.onToggleDoor(tt.obj, p) end }
    end
    local function hatchVerb()
        verbs[#verbs + 1] = { id = "hatch", label = d.hatchOpen and ZeD.tr("UI_ZeD_Hutch_CloseHatch") or ZeD.tr("UI_ZeD_Hutch_OpenHatch"),
            run = function(p, tt) tt.eggChain = nil; ISHutchMenu.onToggleEggHatchDoor(tt.obj, p) end }
    end
    local canClean = d.dirt > 0 and d.water ~= nil and d.mop ~= nil
    if d.allClosed then
        doorVerb(true)
        hatchVerb()
    else
        verbs[#verbs + 1] = { id = "eggs", label = ZeD.upper(txt("IGUI_Hutch_GrabEggs", "Grab Eggs")), primary = #d.free > 0,
            enabled = #d.free > 0, run = function(p, tt) grabEggs(p, tt.obj, tt.d.free, tt) end }
    end
    verbs[#verbs + 1] = { id = "clean", label = ZeD.upper(txt("IGUI_Hutch_Clean", "Clean")), enabled = canClean,
        run = function(p, tt) tt.eggChain = nil; clean(p, tt.obj) end }
    if not d.allClosed then
        doorVerb(false)
        hatchVerb()
    end
    if d.carry then
        local full = d.count >= d.max
        verbs[#verbs + 1] = { id = "putin", label = ZeD.tr("UI_ZeD_Hutch_PutIn"), enabled = not d.allClosed and not full,
            run = function(p, tt) tt.eggChain = nil; ISHutchMenu.onPutAnimalInsideHutch(tt.obj, p) end }
        if d.allClosed then needs[#needs + 1] = ZeD.tr("UI_ZeD_Hutch_PutInNeeds", txt("IGUI_PutAnimalInHutch_DoorsClosed", "You need to have either door or eggs door open."))
        elseif full then needs[#needs + 1] = ZeD.tr("UI_ZeD_Hutch_PutInNeeds", txt("IGUI_PutAnimalInHutch_HutchFull", "Hutch is full.")) end
    end
    t.verbs, t.needs = verbs, needs
end

def.nameOf = hutchName   -- the Animals tab names hutch rows the same way

function def.title(t) return t.d and t.d.name or txt("ContextMenu_Hutch", "Hutch") end
function def.icon(t) return t.d and t.d.icon or nil end
function def.pill(t)
    local T = ZeD.T
    local d = t.d
    if not d then return nil end
    if d.allClosed then return ZeD.tr("UI_ZeD_Hutch_PillShut"), T.textDim end
    return ZeD.upper(ZeD.tr("IGUI_Open")), T.positive
end

-- the controller lands on the first box with eggs to take, else the verbs
function def.openFocus(t)
    local d = t.d
    if d and d.boxesShown and #d.free > 0 then return "hutch:box:" .. d.free[1].i end
    return nil
end

-- ---------------------------------------------------------------------------
-- BODY
-- ---------------------------------------------------------------------------
local EGG_TEX = nil
local function eggTex()
    if EGG_TEX == nil then EGG_TEX = getTexture("Item_Egg") or getTexture("media/textures/Item_Egg.png") or false end
    return EGG_TEX or nil
end

-- hatched plate where vanilla covers what a shut door hides
local function closedPlate(card, x, y, w, label)
    local T, tm = ZeD.T, ZeD.TM
    local h = T.px(46)
    card:drawRect(x, y, w, h, 1, col(T.surf2))
    -- light hatching (the fluid card's band language)
    local step = T.px(4)
    local hy = y + step
    while hy < y + h do
        card:drawRect(x + T.px(1), hy, w - 2 * T.px(1), T.px(1), 0.5, col(T.surf1))
        hy = hy + step
    end
    card:drawRectBorder(x, y, w, h, T.borderS.a or 1, col(T.borderS))
    local f1 = T.fontF1
    local lw = tm:MeasureStringX(f1, label)
    card:drawRect(x + math.floor((w - lw) / 2) - T.px(8), y + math.floor((h - T.px(18)) / 2), lw + 2 * T.px(8), T.px(18), 1, col(T.surf1))
    card:drawText(label, x + math.floor((w - lw) / 2), y + math.floor((h - tm:getFontHeight(f1)) / 2), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f1)
    return h
end

local function drawBox(card, x, y, w, t, b)
    local T, tm = ZeD.T, ZeD.TM
    local h = T.px(BOX_H)
    local fid = "hutch:box:" .. b.i
    local focused = card._fid == fid
    card:drawRect(x, y, w, h, 1, col(T.surf2))
    card:drawRectBorder(x, y, w, h, T.borderS.a or 1, col(T.borderS))
    local f1 = T.fontF1
    local ac = T.accent
    card:drawText(ZeD.tr("UI_ZeD_Hutch_Box", b.i + 1), x + T.px(6), y + T.px(5), ac.r, ac.g, ac.b, 1, f1)
    ZeD.Atoms.drawTextRight(card, tostring(b.eggs), x + w - T.px(6), y + T.px(5), f1, T.textDim)
    local cy = y + T.px(5) + tm:getFontHeight(f1) + T.px(5)
    if b.hen then
        local tex = ZeD.AnimalsData and getTexture(ZeD.AnimalsData.resolvePortrait(b.hen))
        local isz = T.px(24)
        if tex then card:drawTextureScaledAspect(tex, x + math.floor((w - isz) / 2), cy, isz, isz, 1, 1, 1, 1) end
        local f2, f5 = T.fontF2, T.fontF5
        local nm = ZeD.CraftingCore.truncText(b.henName or "?", f2, w - T.px(8))
        card:drawText(nm, x + math.floor((w - tm:MeasureStringX(f2, nm)) / 2), cy + isz + T.px(2), T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
        local sub = ZeD.tr("UI_ZeD_Hutch_Sitting", b.eggs)
        card:drawText(sub, x + math.floor((w - tm:MeasureStringX(f5, sub)) / 2), cy + isz + T.px(2) + tm:getFontHeight(f2),
            T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f5)
    else
        -- vanilla's ten egg slots: two rows of five, empty ones faint
        local tex = eggTex()
        local esz = math.min(T.px(14), math.floor((w - T.px(12)) / 5) - T.px(2))
        local gx = x + math.floor((w - (esz + T.px(2)) * 5) / 2)
        for k = 0, 9 do
            local ex = gx + (k % 5) * (esz + T.px(2))
            local ey = cy + math.floor(k / 5) * (esz + T.px(4))
            local a = (k < b.eggs) and 1 or 0.2
            if tex then card:drawTextureScaledAspect(tex, ex, ey, esz, esz, a, 1, 1, 1)
            else local eg = ZeD.T.textHead; ZeD.Atoms.drawStatusDot(card, ex, ey, { r = eg.r, g = eg.g, b = eg.b, a = a }, esz) end
        end
    end
    -- GRAB (bottom)
    local label = b.hen and ZeD.tr("UI_ZeD_Hutch_HenSitting") or ZeD.upper(ZeD.tr("IGUI_Hutch_Grab"))
    local enabled = (not b.hen) and b.eggs > 0 and b.nest ~= nil
    local bw = math.min(w - T.px(12), UI.buttonW(label))
    local by = y + h - T.px(6) - T.px(20)
    UI.button(card, x + T.px(6), by, label, { h = T.px(20), w = bw, disabled = not enabled, focused = focused })
    local bb = b
    card:zone({ fid = fid, x = x + T.px(6), y = by, w = bw, h = T.px(20), body = true,
        run = enabled and function(c, p) grabEggs(p, t.obj, { bb }, t) end or nil })
    return h
end

local function drawBird(card, x, y, w, t, b)
    local T, tm = ZeD.T, ZeD.TM
    local h = T.px(BIRD_H)
    local isz = T.px(22)
    if b.tex then card:drawTextureScaledAspect(b.tex, x + T.px(2), y + math.floor((h - isz) / 2), isz, isz, 1, 1, 1, 1) end
    local grabTxt, infoTxt = ZeD.upper(ZeD.tr("IGUI_Hutch_Grab")), ZeD.upper(ZeD.tr("IGUI_Animal_Info"))
    local gw, iw = UI.buttonW(grabTxt), UI.buttonW(infoTxt)
    local ix = x + w - T.px(2) - iw
    local gx = ix - T.px(4) - gw
    local by = y + math.floor((h - T.px(20)) / 2)
    local gf, inf = "hutch:bird:" .. b.i .. ":grab", "hutch:bird:" .. b.i .. ":info"
    UI.button(card, gx, by, grabTxt, { h = T.px(20), w = gw, focused = card._fid == gf })
    UI.button(card, ix, by, infoTxt, { h = T.px(20), w = iw, focused = card._fid == inf })
    local bb = b
    card:zone({ fid = gf, x = gx, y = by, w = gw, h = T.px(20), body = true, run = function(c, p) t.eggChain = nil; grabBird(p, t.obj, bb) end })
    card:zone({ fid = inf, x = ix, y = by, w = iw, h = T.px(20), body = true, run = function(c, p) showBird(p, bb.a) end })
    local rx = gx - T.px(8)
    if b.dead then
        local deadTxt = ZeD.upper(ZeD.tr("IGUI_DesignationZone_Dead"))
        local tw = UI.tagW(deadTxt)
        UI.tag(card, rx - tw, y + math.floor((h - T.px(16)) / 2), deadTxt, T.danger)
        rx = rx - tw - T.px(8)
    end
    local f2, f5 = T.fontF2, T.fontF5
    local nx = x + T.px(2) + isz + T.px(8)
    local ny = y + math.floor((h - tm:getFontHeight(f2) - tm:getFontHeight(f5)) / 2)
    card:drawText(ZeD.CraftingCore.truncText(b.name, f2, rx - nx), nx, ny, T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
    card:drawText(ZeD.CraftingCore.truncText(b.sub, f5, rx - nx), nx, ny + tm:getFontHeight(f2), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f5)
    card:drawRect(x, y + h - T.px(1), w, T.px(1), T.border.a or 1, col(T.border))
    return h
end

-- a line of status dots: { ok = true/false/nil (nil = optional), text }
local function checklist(card, x, y, w, items)
    local T, tm = ZeD.T, ZeD.TM
    local f1 = T.fontF1
    local lh = T.px(18)
    local cx, cy = x, y
    for _, it in ipairs(items) do
        local tw = tm:MeasureStringX(f1, it.text) + T.px(13) + T.px(14)
        if cx > x and cx + tw > x + w then cx = x; cy = cy + lh end
        local dy = cy + math.floor((lh - T.px(7)) / 2)
        if it.ok == nil then ZeD.Atoms.drawStatusRing(card, cx, dy, T.textDim, T.px(7))
        else ZeD.Atoms.drawStatusDot(card, cx, dy, it.ok and T.positive or T.danger, T.px(7)) end
        card:drawText(it.text, cx + T.px(13), cy + math.floor((lh - tm:getFontHeight(f1)) / 2), T.text.r, T.text.g, T.text.b, T.text.a or 1, f1)
        cx = cx + tw
    end
    return cy + lh - y
end

function def.body(card, x, y, w, t, player)
    local T = ZeD.T
    local d = t.d
    if not (d and def.valid(t)) then return 0 end
    local y0 = y
    local gap = T.px(8)
    local HW = UI.HW

    -- doors: two lamps, labels in the card's text colour
    local tm = ZeD.TM
    local f1 = T.fontF1
    local lx = x + T.px(2)
    for _, door in ipairs({ { d.doorOpen, d.doorOpen and ZeD.tr("UI_ZeD_Hutch_DoorOpen") or ZeD.tr("UI_ZeD_Hutch_DoorShut") },
                            { d.hatchOpen, d.hatchOpen and ZeD.tr("UI_ZeD_Hutch_HatchOpen") or ZeD.tr("UI_ZeD_Hutch_HatchShut") } }) do
        UI.led(card, lx, y + T.px(5), HW.green, door[1], nil)
        card:drawText(door[2], lx + T.px(14), y + T.px(9) - math.floor(tm:getFontHeight(f1) / 2), T.text.r, T.text.g, T.text.b, T.text.a or 1, f1)
        lx = lx + T.px(14) + tm:MeasureStringX(f1, door[2]) + T.px(22)
    end
    y = y + T.px(18) + gap
    if t.needs and #t.needs > 0 then y = y + UI.needs(card, x, y, w, t.needs) + gap end

    -- egg laying boxes
    y = y + UI.section(card, x, y, w, ZeD.upper(txt("IGUI_Hutch_EggLayingBox", "Egg Laying Boxes")),
        d.boxesShown and ZeD.tr("UI_ZeD_Hutch_EggsBoxes", d.eggs, #d.boxes) or ZeD.tr("UI_ZeD_Hutch_Boxes", #d.boxes))
    y = y + T.px(6)
    if not d.boxesShown then
        y = y + closedPlate(card, x, y, w, ZeD.tr("UI_ZeD_Hutch_BothShut"))
    else
        local n = #d.boxes
        local bgap = T.px(6)
        local bw = math.floor((w - bgap * (n - 1)) / n)
        for k, b in ipairs(d.boxes) do drawBox(card, x + (k - 1) * (bw + bgap), y, bw, t, b) end
        y = y + T.px(BOX_H)
        if d.full then
            y = y + T.px(6)
            y = y + UI.needs(card, x, y, w, { ZeD.tr("UI_ZeD_Hutch_BoxesFull") })
        end
    end
    y = y + gap

    -- coop roosting
    y = y + UI.section(card, x, y, w, ZeD.upper(txt("IGUI_Hutch_CoopRoosting", "Coop Roosting")), tostring(d.count) .. " / " .. tostring(d.max))
    if not d.roostShown then
        y = y + T.px(6)
        y = y + closedPlate(card, x, y, w, ZeD.tr("UI_ZeD_Hutch_DoorShut"))
    elseif #d.birds == 0 then
        y = y + T.px(4)
        y = y + UI.para(card, x + T.px(2), y, w, ZeD.tr("UI_ZeD_Hutch_NoBirds"), T.textDim)
    else
        for _, b in ipairs(d.birds) do y = y + drawBird(card, x, y, w, t, b) end
    end
    y = y + gap

    -- floor
    y = y + UI.section(card, x, y, w, ZeD.upper(ZeD.tr("ContextMenu_Floor")), "")
    y = y + T.px(4)
    local dirt = math.max(0, math.min(100, d.dirt))
    local fc = (dirt > 70 and T.danger) or (dirt > 40 and T.warning) or T.positive
    -- (vanilla's IGUI_Hutch_Dirt takes an argument: reading it bare warns every frame)
    y = y + UI.meter(card, x, y, w, ZeD.tr("UI_ZeD_Hutch_Dirtiness"), tostring(math.floor(dirt + 0.5)) .. "%", nil, dirt, fc)
    if d.dirt > 0 then
        y = y + T.px(6)
        y = y + checklist(card, x, y, w, {
            { ok = d.water ~= nil, text = d.water and ZeD.tr("UI_ZeD_Hutch_WaterNamed", call(d.water, "getDisplayName") or "") or ZeD.tr("UI_ZeD_Hutch_Water") },
            { ok = d.mop ~= nil, text = d.mop and ZeD.tr("UI_ZeD_Hutch_MopNamed", call(d.mop, "getDisplayName") or "") or ZeD.tr("UI_ZeD_Hutch_Mop") },
            { ok = d.bleach and true or nil, text = ZeD.tr("UI_ZeD_Hutch_Bleach") },
        })
    end
    return y - y0
end

OC.register(def)
print("[ZeD] ObjectCardHutch: hutch card loaded")
return def
