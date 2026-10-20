-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Belt.lua
-- ============================================================================
-- THE BELT — HOOK_MAP rows 5 + 6 (mockup ZeDUI/mockups/zed_hands_belt_v3.html)
--
-- Vanilla shows what you hold as two circles in the top-left corner
-- (ISEquippedItem) and what hangs on you as a bar of numbered squares at the
-- bottom (ISHotbar). Both become one HUD piece at the bottom centre, to the
-- director's sketch:
--     [Main Hand] ==[1]=[2]={buckle}=[3]=[4]== [Secondary hand]
-- a decorative leather strap with a buckle in the middle (decoration,
-- theme-neutral: since Oct 15 2026 the character's profession buckle, 25
-- designs, the plain KENTUCKY plate for any other), the hotbar slots as ZeD boxes on the strap (a little taller
-- than it) on either side of the buckle in key order, the hands as squares at
-- the two ends. The boxes follow the ZeD base and accent.
--
-- Vanilla's ISHotbar instance stays the data model (its slots, attachments,
-- refresh on clothing changes, key handlers); Overrides/Belt.lua parks its
-- own drawing. This file:
--   * ZeD.Belt — the belt API shared with the Equip tab (slots, keys, names,
--     what fits, attach / detach / draw, the slot list menu, drops);
--   * ZeD_BeltHUD — the organism (mouse, drag in / out, tooltips, controller).
-- Every layout number is a DESIGN UNIT and goes through T.px at use (S124).
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/ZeD_Panel"
require "ZeD/SafeMode"

ZeD = ZeD or {}
ZeD.Belt = ZeD.Belt or {}
local B = ZeD.Belt

-- ----------------------------------------------------------------------------
-- Constants (design units)
-- ----------------------------------------------------------------------------
local BOX, HAND = 44, 52
local GAP, SIDE_GAP, PAD, END_GAP = 11, 14, 12, 10   -- GAP 7 -> 11 (Oct 16 2026): each slot's strap material shows between the boxes
local BUCKLE_W, BUCKLE_H = 58, 40   -- the profession buckle's own size (58 x 40 texels, one a unit)
local STRAP_H = 30
local BOTTOM = 16          -- above the bottom of the screen
local DRAG_PX = 5          -- design units before a press becomes a drag
local WRIST = 8            -- the mini watch's gap from its hand circle (WatchMini.lua; Oct 19 2026)
local LIST_ROW_H, LIST_W = 26, 290

local DOT = "|"   -- the separator: ZeD OS's pipe (director, Oct 16 2026: no middle dots)

local function col(c) return c.r, c.g, c.b end
local function hex(h)
    local n = tonumber(string.sub(h, 2), 16) or 0
    return { r = math.floor(n / 65536) / 255, g = (math.floor(n / 256) % 256) / 255, b = (n % 256) / 255, a = 1 }
end
local LEATHER_TOP, LEATHER_BOT, LEATHER_EDGE = hex("#5c4129"), hex("#3b2a1b"), hex("#1a1108")

-- The strap in lit pixel art (director, Oct 16 2026: no stitching, more material, a light creaser line along each
-- edge; art by ZeDUI/tools/physpx/d_belt.py): the left end, a 64-pixel middle that repeats without a seam, the right
-- end, 30 texels tall, drawn at a whole multiple (like the buckle) so the pixels stay square.
local STRAP_DIR = "media/textures/ZeD/belt/strap_"
local STRAP_TEX_H, STRAP_TILE, STRAP_END = 30, 64, 8
local _strapTex = {}
local function strapTexture(part)
    local t = _strapTex[part]
    if t == nil then
        t = Texture.getSharedTexture(STRAP_DIR .. part .. ".png", 3) or false   -- 3 = nearest filtering
        _strapTex[part] = t
    end
    return t or nil
end

-- ----------------------------------------------------------------------------
-- Each slot on its own attachment material (director, Oct 16 2026: "quick look you can see what is attached to
-- what"). Every hotbar slot in vanilla comes from something worn (its AttachmentsProvided; the back slot is the
-- body, or the bag on it): the strap behind a slot's box is that thing's material. The waist belt (whatever gives
-- the belt slots) carries the buckle. Art: ZeDUI/tools/physpx/d_straps.py (the leather is d_belt.py's).
-- B.MATERIALS is open: a mod's item adds its own line (full type -> material name).
-- ----------------------------------------------------------------------------
-- (a method call that never throws; the file's own `call` is declared further down)
local function _call(o, m, ...)
    if o == nil or o[m] == nil then return nil end
    local ok, r = pcall(o[m], o, ...)
    if ok then return r end
    return nil
end

B.MATERIALS = B.MATERIALS or {}
for ft, m in pairs({
    ["Base.Belt2"] = "leather", ["Base.RopeBelt"] = "rope",
    ["Base.Bag_ALICE_BeltSus"] = "webbing_olive", ["Base.Bag_ALICE_BeltSus_Green"] = "webbing_green",
    ["Base.Bag_ALICE_BeltSus_Camo"] = "webbing_camo",
    ["Base.SCBA"] = "harness", ["Base.SCBA_notank"] = "harness",
    ["Base.Bag_NormalHikingBag"] = "pack", ["Base.Bag_BigHikingBag"] = "pack", ["Base.Bag_HikingBag_Travel"] = "pack",
    ["Base.Bag_BigHikingBag_Travel"] = "pack", ["Base.Bag_SurvivorBag"] = "pack",
    ["Base.Bag_ALICEpack"] = "webbing_olive", ["Base.Bag_ALICEpack_Army"] = "webbing_olive",
    ["Base.Bag_ALICEpack_DesertCamo"] = "webbing_olive",
    ["Base.Bag_CraftedFramepack_Large"] = "rope", ["Base.Bag_CraftedFramepack_Large2"] = "rope",
    ["Base.Bag_CraftedFramepack_Large3"] = "rope", ["Base.Bag_TarpFramepack_Large"] = "rope",
    ["Base.HolsterSimple"] = "holster_black", ["Base.HolsterSimple_Black"] = "holster_black",
    ["Base.HolsterSimple_Brown"] = "holster_brown", ["Base.HolsterSimple_Green"] = "holster_green",
    ["Base.Holster_DuctTape"] = "holster_tape", ["Base.Holster_Hide"] = "holster_hide",
    ["Base.HolsterDouble"] = "holster_brown", ["Base.HolsterShoulder"] = "holster_brown", ["Base.HolsterAnkle"] = "holster_black",
}) do if B.MATERIALS[ft] == nil then B.MATERIALS[ft] = m end end
-- a provider no one named: by the slot's kind
B.SLOT_MATERIAL = B.SLOT_MATERIAL or {
    SmallBeltLeft = "leather", SmallBeltRight = "leather", WebbingLeft = "webbing_olive", WebbingRight = "webbing_olive",
    HolsterRight = "holster_brown", HolsterLeft = "holster_brown", HolsterShoulder = "holster_brown", HolsterAnkle = "holster_black",
    BedrollBottom = "pack", BedrollBottomBig = "pack", BedrollBottomALICE = "webbing_olive", Back = "sling",
}
-- worn things that are not bags but put a harness over the back (director, Oct 16 2026: the breathing pack's back slot
-- is its harness, not the bare canvas sling); a bag on the back still wins. Open like B.MATERIALS.
B.BACK_WORN = B.BACK_WORN or {}
for ft, m in pairs({ ["Base.SCBA"] = "harness", ["Base.SCBA_notank"] = "harness" }) do
    if B.BACK_WORN[ft] == nil then B.BACK_WORN[ft] = m end
end
local MAT_DIR = "media/textures/ZeD/belt/"
local _matTex = {}
local function matTexture(mat, part)
    local key = mat .. "_" .. part
    local t = _matTex[key]
    if t == nil then
        local path = (mat == "leather") and (STRAP_DIR .. part .. ".png") or (MAT_DIR .. key .. ".png")
        t = Texture.getSharedTexture(path, 3) or false
        _matTex[key] = t
    end
    return t or nil
end
B._matTexture = matTexture

-- What closes the waist belt (director, Oct 16 2026: "rope is a knot. web/nylon belts get rectangle flat clip
-- closure"): the leather belt keeps the profession buckle; the rope belt is tied in a knot; webbing and the breathing
-- pack's nylon belt shut with the classic web-belt buckle (the director's references: GI brass on olive drab, black
-- on black nylon). Art: ZeDUI/tools/physpx/d_closures.py, 58 x 40 like the buckle.
-- B.CLOSURE is open: a mod's material adds its own line (material -> "buckle" | "knot" | "clip_brass" | "clip_black" |
-- "clip_chrome"); none = no closure.
B.CLOSURE = B.CLOSURE or {}
for m, c in pairs({ leather = "buckle", rope = "knot", webbing_olive = "clip_brass", webbing_green = "clip_brass",
                    webbing_camo = "clip_black", harness = "clip_black" }) do
    if B.CLOSURE[m] == nil then B.CLOSURE[m] = c end
end
-- the rope belt stops under the knot between these two columns of the closure's 58 (d_closures.py KNOT_CUT): each
-- rope's own strand takes over there, so the belt never shows through the knot
B.KNOT_CUT = { 14, 44 }
-- a closure's own height when it is not the buckle's 40 (the knot stands the hands' full 52 rows, for its frayed ends);
-- centred on the buckle's place either way
B.CLOSURE_H = B.CLOSURE_H or { knot = 52 }
local _closureTex = {}
local function closureTexture(kind)
    local t = _closureTex[kind]
    if t == nil then
        t = Texture.getSharedTexture(MAT_DIR .. "closure_" .. kind .. ".png", 3) or false
        _closureTex[kind] = t
    end
    return t or nil
end

-- The closure always sits between the belt's left and right slots (director, Oct 16 2026): after Belt L; before
-- Belt R when there is no Belt L; with neither (no belt worn), in the middle of the row. Returns how many slots sit
-- left of it.
function B.closureAfter(slots)
    local l, r
    for i, s in ipairs(slots) do
        local t = s and s.slot and s.slot.slotType
        if t == "SmallBeltLeft" then l = i elseif t == "SmallBeltRight" then r = i end
    end
    if l then return l end
    if r then return r - 1 end
    return math.ceil(#slots / 2)
end

-- which worn item provides each slot type (the last to provide it, as vanilla gives the slot that item's icon),
-- the bag on the back if any, and a harness worn on the back (B.BACK_WORN): { [slotType] = item, Back = bag or nil,
-- BackWorn = item or nil }
local function providers(chr)
    local out = {}
    local worn = chr and _call(chr, "getWornItems")
    if not worn then return out end
    for i = 0, worn:size() - 1 do
        local item = worn:getItemByIndex(i)
        if item and not _call(chr, "isHandItem", item) then
            local ap = _call(item, "getAttachmentsProvided")
            if ap then for j = 0, ap:size() - 1 do out[tostring(ap:get(j))] = item end end
            if _call(item, "getAttachmentReplacement") == "Bag" then out.Back = item end
            if B.BACK_WORN[tostring(_call(item, "getFullType") or "")] then out.BackWorn = item end
        end
    end
    return out
end

-- the material behind a slot type, given the providers
function B.materialFor(slotType, prov)
    local item = prov and prov[slotType]
    if item then
        local m = B.MATERIALS[tostring(_call(item, "getFullType") or "")]
        if m then return m end
        if slotType == "Back" then return "pack" end            -- some other bag on the back
    end
    if slotType == "Back" and prov and prov.BackWorn then    -- no bag, but a harness over the back
        return B.BACK_WORN[tostring(_call(prov.BackWorn, "getFullType") or "")] or "harness"
    end
    return B.SLOT_MATERIAL[slotType] or "leather"
end

-- the runs of strap from left to right: each slot's own (box plus half the gaps, the outer ones to the strap's ends),
-- the waist belt's round the buckle, neighbours of one material merged into one piece. strap = {x, w}, boxes = the
-- slot boxes in order, k = how many sit left of the buckle, gap = the gap in screen pixels, hole = {x0, x1} or nil:
-- a stretch cut out of the strap (the rope's knot eye)
function B.strapRuns(strapX, strapW, boxes, mats, waist, k, gap, hole)
    local n = #boxes
    local half = math.floor(gap / 2)
    local runs = {}
    for i = 1, n do
        local b = boxes[i]
        local x0 = (i == 1 and k >= 1) and strapX or (b.x - half)
        local x1 = (i == n and k < n) and (strapX + strapW) or (b.x + b.w + half)
        runs[i] = { x0, x1, mats[i] }
    end
    local lx0 = (k >= 1) and runs[k][2] or strapX
    local lx1 = (k < n) and runs[k + 1][1] or (strapX + strapW)
    local seq = {}
    for i = 1, k do seq[#seq + 1] = runs[i] end
    seq[#seq + 1] = { lx0, lx1, waist }
    for i = k + 1, n do seq[#seq + 1] = runs[i] end
    local out = {}
    for _, r in ipairs(seq) do
        local last = out[#out]
        if r[2] > r[1] then
            if last and last[3] == r[3] and last[2] >= r[1] - 1 then last[2] = r[2]
            else out[#out + 1] = { r[1], r[2], r[3] } end
        end
    end
    if hole then
        -- the strap cut where the knot's eye is: a run across it becomes the piece up to it and the piece after it
        local cut = {}
        for _, r in ipairs(out) do
            if r[1] < hole[2] and r[2] > hole[1] then
                if hole[1] > r[1] then cut[#cut + 1] = { r[1], hole[1], r[3] } end
                if r[2] > hole[2] then cut[#cut + 1] = { hole[2], r[2], r[3] } end
            else
                cut[#cut + 1] = r
            end
        end
        out = cut
    end
    return out
end
local BRASS_A, BRASS_B, BRASS_C = hex("#e2c070"), hex("#9c7428"), hex("#4a3812")

-- The player's profession buckle (director, Oct 15 2026; art by ZeDUI/tools/buckles/
-- gen_buckles.py: 25 stable professions, 58 x 40, one texel a design unit). Loaded with
-- nearest filtering like the main menu desk (KB Q205) and drawn at a whole multiple, so the
-- pixels stay square. A modded or unknown profession wears the plain KENTUCKY plate
-- (unemployed); a missing texture falls back to the brass frame.
local BUCKLE_DIR = "media/textures/ZeD/buckles/buckle_"
local NEAREST = 3
local _buckleTex = {}
local function buckleTexture(id)
    local t = _buckleTex[id]
    if t == nil then
        t = Texture.getSharedTexture(BUCKLE_DIR .. id .. ".png", NEAREST) or false
        _buckleTex[id] = t
    end
    return t or nil
end
local function professionId(p)
    local id = nil
    pcall(function() id = p:getDescriptor():getCharacterProfession():getName() end)
    if id == nil then return nil end
    id = string.lower(tostring(id))
    return id:match("([^:]+)$")   -- "base:farmer" -> "farmer"
end

local function call(o, m, ...)
    if o == nil then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end

-- ----------------------------------------------------------------------------
-- ZeD.Belt — slots, keys, names
-- ----------------------------------------------------------------------------
function B.hotbar(playerNum) return getPlayerHotbar and getPlayerHotbar(playerNum or 0) or nil end

-- The bound key's name for slot i ("1"), nil past the eighth (vanilla binds 1-8)
function B.keyLabel(i)
    if i < 1 or i > 8 then return nil end
    local code = getCore():getKey("Hotbar " .. tostring(i))
    if not code or code == 0 then return nil end
    local name = Keyboard.getKeyName(code)
    if not name or name == "" then return nil end
    return name
end

local SHORT = {
    Back = "BACK", SmallBeltLeft = "BELT L", SmallBeltRight = "BELT R",
    HolsterRight = "HOLSTER", HolsterLeft = "HOLSTER L", HolsterShoulder = "SHOULDER", HolsterAnkle = "ANKLE",
    WebbingLeft = "WEB L", WebbingRight = "WEB R",
    BedrollBottom = "PACK", BedrollBottomBig = "PACK", BedrollBottomALICE = "PACK",
}
function B.shortName(slotType) return SHORT[slotType] or string.upper(tostring(slotType or "")) end
function B.slotName(slot)
    if not slot then return "" end
    return getTextOrNull("IGUI_HotbarAttachment_" .. tostring(slot.slotType)) or tostring(slot.name or slot.slotType)
end
-- "BELT 3" in the inventory lists (the key that draws it)
function B.tagFor(i) return "BELT " .. tostring(B.keyLabel(i) or i) end

-- The worn item that gives a slot (Back is always there)
function B.provider(playerObj, slotType)
    if slotType == "Back" then return nil end
    local worn = playerObj and playerObj:getWornItems()
    if not worn then return nil end
    for i = 0, worn:size() - 1 do
        local it = worn:getItemByIndex(i)
        local prov = it and call(it, "getAttachmentsProvided")
        if prov then
            for j = 0, prov:size() - 1 do
                if prov:get(j) == slotType then return it end
            end
        end
    end
    return nil
end

-- 0..1 condition, or nil for items without one
function B.cond(item)
    local mx = call(item, "getConditionMax")
    if not mx or mx <= 0 then return nil end
    return math.max(0, math.min(1, (call(item, "getCondition") or 0) / mx))
end

-- Every slot: { i, slot, item, key, short, name, inHand }
function B.slots(playerNum)
    local hb = B.hotbar(playerNum)
    local out = {}
    if not (hb and hb.availableSlot) then return out end
    local chr = hb.chr or getSpecificPlayer(playerNum or 0)
    for i, slot in ipairs(hb.availableSlot) do
        local item = hb.attachedItems and hb.attachedItems[i] or nil
        out[#out + 1] = {
            i = i, slot = slot, item = item, key = B.keyLabel(i), short = B.shortName(slot.slotType),
            name = B.slotName(slot), inHand = item ~= nil and chr ~= nil and chr:isEquipped(item),
        }
    end
    return out
end

-- Does item fit slot i? (vanilla's attachment rules, not broken, not "null")
function B.fits(hb, i, item)
    local slot = hb and hb.availableSlot and hb.availableSlot[i]
    if not (slot and item) then return false end
    if not call(item, "getAttachmentType") or call(item, "isBroken") then return false end
    local ok, r = pcall(hb.canBeAttached, hb, slot, item)
    return ok and r == true
end

-- ----------------------------------------------------------------------------
-- ZeD.Belt — verbs (vanilla's own calls)
-- ----------------------------------------------------------------------------
function B.activate(playerNum, i)
    local hb = B.hotbar(playerNum)
    if not hb then return end
    if hb:isAllowedToActivateSlot() then hb:activateSlot(i) end
end

function B.attach(playerNum, item, i)
    local hb = B.hotbar(playerNum)
    local slot = hb and hb.availableSlot and hb.availableSlot[i]
    if not (slot and item) or not B.fits(hb, i, item) then return false end
    local model = slot.def.attachments[item:getAttachmentType()]
    hb:attachItem(item, model, i, slot.def, true)
    return true
end

function B.detach(playerNum, item)
    local hb = B.hotbar(playerNum)
    if hb and item then hb:removeItem(item, true) end
end

-- Equip into a hand ("p", "s" or "both"), as vanilla's hand slots do on a drop
function B.equipHand(playerNum, item, which)
    local chr = getSpecificPlayer(playerNum)
    if not (chr and item) then return end
    if isForceDropHeavyItem and isForceDropHeavyItem(item) then
        ISInventoryPaneContextMenu.equipHeavyItem(chr, item); return
    end
    local both = call(item, "isRequiresEquippedBothHands") == true
    if which == "both" then
        ISInventoryPaneContextMenu.equipWeapon(item, true, true, playerNum)
    elseif which == "s" then
        ISInventoryPaneContextMenu.equipWeapon(item, false, both, playerNum)
    else
        ISInventoryPaneContextMenu.equipWeapon(item, true, both, playerNum)
    end
end

-- What a hand accepts from a drag (vanilla ISEquippedItem:getDraggedEquippableItem)
function B.handTakes(item)
    if not item or getCore():getGameMode() == "Tutorial" then return false end
    local si = call(item, "getScriptItem")
    if si and call(si, "getReplaceWhenUnequip") then return false end
    if call(item, "IsWeapon") then return (call(item, "getCondition") or 0) > 0 end
    if call(item, "IsFood") or call(item, "IsClothing") then return false end
    return true
end

-- The slot's list (instead of vanilla's radial): what fits from the main
-- inventory, and REMOVE for what is in it. A context menu at (x, y).
function B.slotMenu(playerNum, i, x, y)
    local hb = B.hotbar(playerNum)
    local slot = hb and hb.availableSlot and hb.availableSlot[i]
    if not slot then return nil end
    local chr = hb.chr
    local context = ISContextMenu.get(playerNum, x, y)
    local any = false
    local inv = chr:getInventory():getItems()
    for n = 0, inv:size() - 1 do
        local item = inv:get(n)
        if not hb:isItemAttached(item) and call(item, "getAttachmentType") and (call(item, "getCondition") or 0) > 0
           and B.fits(hb, i, item) then
            local opt = context:addOption(item:getDisplayName(), hb, ISHotbar.onRadialAttach, item, i, slot.def.attachments[item:getAttachmentType()])
            opt.itemForTexture = item
            any = true
        end
    end
    local cur = hb.attachedItems and hb.attachedItems[i]
    if cur then
        local label = (string.gsub(getText("ContextMenu_HotbarRadialRemove", cur:getDisplayName()), "<br>", " "))
        context:addOption(label, hb, ISHotbar.onRadialRemove, cur)
        any = true
    end
    if not any then
        local o = context:addOption(getText("ContextMenu_NoWeaponsAvailable"))
        o.notAvailable = true
    end
    return context
end

-- A right-click on slot i: vanilla's slot menu (the item's own menu plus an
-- Attach list). Vanilla skips it while paused; then the item's menu, or the
-- slot's list when it is empty.
function B.rightMenu(playerNum, i, x, y)
    local hb = B.hotbar(playerNum)
    if not (hb and hb.availableSlot and hb.availableSlot[i]) then return end
    local paused = UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0
    if not paused then
        pcall(hb.doMenu, hb, i)
        return
    end
    local item = hb.attachedItems and hb.attachedItems[i]
    if item then
        ISInventoryPaneContextMenu.createMenu(playerNum, true, { item }, x or getMouseX(), y or getMouseY())
    else
        B.slotMenu(playerNum, i, x or getMouseX(), y or getMouseY())
    end
end

-- The old D-pad Left wheel's content: weapons in the bags (not on the belt)
-- and the best light (vanilla ISDPadWheels.onDisplayLeft)
function B.otherWeapons(playerObj)
    local out = {}
    local hb = B.hotbar(playerObj:getPlayerNum())
    local best, bestEq = nil, nil
    local inv = playerObj:getInventory():getItems()
    for n = 0, inv:size() - 1 do
        local item = inv:get(n)
        if instanceof(item, "HandWeapon") and item:getCondition() > 0 then
            if not (hb and hb:isItemAttached(item)) and not playerObj:isEquipped(item) then
                out[#out + 1] = { item = item, kind = "weapon" }
            end
        elseif call(item, "canEmitLight") then
            if not best or best:getLightStrength() < item:getLightStrength() then best = item end
            if playerObj:isEquipped(item) or (hb and hb:isItemAttached(item)) then  -- (vanilla's isEquippedOrAttached is local to ISDPadWheels, out of reach: its test inline; code audit Oct 17 2026)
                if not bestEq or bestEq:getLightStrength() < item:getLightStrength() then bestEq = item end
            end
        end
    end
    best = bestEq or best
    if best then out[#out + 1] = { item = best, kind = "light" } end
    return out
end

-- ----------------------------------------------------------------------------
-- ZeD_BeltHUD — the organism (player one; a top-level panel)
-- ----------------------------------------------------------------------------
ZeD_BeltHUD = ZeD_BeltHUD or ZeD_Panel:derive("ZeD_BeltHUD")

function ZeD_BeltHUD:new(playerNum)
    local o = ZeD_Panel:new(0, 0, 10, 10)
    setmetatable(o, self)
    self.__index = self
    o.playerNum = playerNum or 0
    o._zedLabel = "Belt"
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o._boxes = {}
    return o
end

function ZeD_BeltHUD:player() return getSpecificPlayer(self.playerNum) end

-- Should the belt show? (not dead, not in a vehicle seat, UI not toggled off,
-- not in safe mode: SafeMode.lua, vanilla's hotbar is back then)
function ZeD_BeltHUD:wanted()
    if ZeD.Safe.on() then return false end
    local p = self:player()
    if not p or p:isDead() then return false end
    if p:getVehicle() then return false end
    if ISUIHandler and ISUIHandler.allUIVisible == false then return false end
    if getCore():getGameMode() == "Tutorial" then return false end
    return B.hotbar(self.playerNum) ~= nil
end

-- Layout: boxes keyed for hit testing; returns the panel size
function ZeD_BeltHUD:_layout(slots)
    local T = ZeD.T
    local px = T.px
    local n = #slots
    local k = B.closureAfter(slots)       -- the buckle / knot / clip goes between Belt L and Belt R
    local boxes = {}
    local hand, box = px(HAND), px(BOX)
    local h = hand
    local x = 0
    -- the worn watch (the "Watch" option): right wrist left of the main hand,
    -- left wrist right of the off hand (the main hand is the game's right hand)
    local wItem, wPlate, wWrist = nil, nil, nil
    if ZeD.Watch and ZeD.Watch.beltWatch then wItem, wPlate, wWrist = ZeD.Watch.beltWatch(self:player()) end
    local mw, mh = px(ZeD.WatchMini and ZeD.WatchMini.W or 44), px(ZeD.WatchMini and ZeD.WatchMini.H or 46)
    local watchBox = wItem and { kind = "watch", item = wItem, plate = wPlate, wrist = wWrist, y = math.floor((h - mh) / 2), w = mw, h = mh } or nil
    if watchBox and wWrist == "right" then
        watchBox.x = x
        boxes[#boxes + 1] = watchBox
        x = x + mw + px(WRIST)
    end
    boxes[#boxes + 1] = { kind = "hand", which = "p", x = x, y = 0, w = hand, h = hand }
    x = x + hand + px(END_GAP)
    local strapX = x
    x = x + px(PAD)
    local by = math.floor((h - box) / 2)
    for i = 1, n do
        if i == k + 1 then
            if k == 0 then x = x + px(BUCKLE_W) + px(SIDE_GAP)        -- the closure opens the strap
            else x = x + px(SIDE_GAP) + px(BUCKLE_W) + px(SIDE_GAP) - px(GAP) end
        end
        boxes[#boxes + 1] = { kind = "slot", i = i, s = slots[i], x = x, y = by, w = box, h = box }
        x = x + box + px(GAP)
    end
    if n > 0 then x = x - px(GAP) end
    local buckleX
    if k == n then
        -- every slot on the left (one or none): the buckle closes the strap
        buckleX = x + px(SIDE_GAP)
        x = buckleX + px(BUCKLE_W)
    elseif k == 0 then
        buckleX = strapX + px(PAD)
    else
        buckleX = strapX + px(PAD) + k * box + (k - 1) * px(GAP) + px(SIDE_GAP)
    end
    x = x + px(PAD)
    local strapW = x - strapX
    x = x + px(END_GAP)
    boxes[#boxes + 1] = { kind = "hand", which = "s", x = x, y = 0, w = hand, h = hand }
    x = x + hand
    if watchBox and wWrist ~= "right" then
        x = x + px(WRIST)
        watchBox.x = x
        boxes[#boxes + 1] = watchBox
        x = x + mw
    end
    self._boxes = boxes
    self._strap = { x = strapX, y = math.floor((h - px(STRAP_H)) / 2), w = strapW, h = px(STRAP_H) }
    -- each slot's material, the waist belt's under the buckle: providers looked up once a second, and at once when
    -- the slots change (clothes put on or off)
    local now = getTimestampMs and getTimestampMs() or 0
    local sig = ""
    for _, bx in ipairs(boxes) do
        if bx.kind == "slot" then sig = sig .. tostring(bx.s and bx.s.slot and bx.s.slot.slotType or "") .. ";" end
    end
    if sig ~= self._provSig or not self._provAt or now - self._provAt > 1000 then
        self._provAt, self._provSig = now, sig
        self._prov = providers(self:player())
    end
    local prov = self._prov or {}
    local mats, slotBoxes = {}, {}
    for _, bx in ipairs(boxes) do
        if bx.kind == "slot" then
            slotBoxes[#slotBoxes + 1] = bx
            mats[#mats + 1] = B.materialFor(bx.s and bx.s.slot and bx.s.slot.slotType or "", prov)
        end
    end
    local waist = (prov.SmallBeltLeft or prov.SmallBeltRight) and
        B.materialFor(prov.SmallBeltLeft and "SmallBeltLeft" or "SmallBeltRight", prov) or "leather"
    self._buckle = { x = buckleX, y = math.floor((h - px(BUCKLE_H)) / 2), w = px(BUCKLE_W), h = px(BUCKLE_H) }
    -- the closure's art: 58 x 40 at the whole multiple ck, centred in the buckle's place
    local ck = math.max(1, math.floor(T.scale or 1))
    local cx = buckleX + math.floor((px(BUCKLE_W) - BUCKLE_W * ck) / 2)
    local kind = B.CLOSURE[waist]
    local hole = nil
    if kind == "knot" and closureTexture("knot") then hole = { cx + B.KNOT_CUT[1] * ck, cx + B.KNOT_CUT[2] * ck } end
    self._runs = B.strapRuns(strapX, strapW, slotBoxes, mats, waist, k, px(GAP), hole)
    self._waist = waist
    local chh = (kind and B.CLOSURE_H[kind]) or BUCKLE_H
    self._closure = { kind = kind, x = cx, y = self._buckle.y + math.floor((px(BUCKLE_H) - chh * ck) / 2), k = ck, h = chh }
    return x, h
end

-- the same box across frames (the layout rebuilds the box tables every frame)
local function sameBox(a, b)
    return a ~= nil and b ~= nil and a.kind == b.kind and a.i == b.i and a.which == b.which
end

function ZeD_BeltHUD:boxAt(x, y)
    for _, b in ipairs(self._boxes) do
        if x >= b.x and x < b.x + b.w and y >= b.y and y < b.y + b.h then return b end
    end
    return nil
end

-- The dragged items (a ZeD inventory drag sets ISMouseDrag.dragging)
local function draggedItems()
    local d = ISMouseDrag and ISMouseDrag.dragging
    if not d then return nil end
    local ok, items = pcall(ISInventoryPane.getActualItems, d)
    if ok and items and #items > 0 then return items end
    return nil
end

-- What a box would do with the current drag: "fit" / "no" / nil
function ZeD_BeltHUD:_dropState(b, items)
    if not items then return nil end
    if b.kind == "watch" then return "no" end
    if b.kind == "hand" then
        for _, it in ipairs(items) do if B.handTakes(it) then return "fit", it end end
        return "no"
    end
    local hb = B.hotbar(self.playerNum)
    for _, it in ipairs(items) do
        if it ~= (b.s and b.s.item) and B.fits(hb, b.i, it) then return "fit", it end
    end
    return "no"
end

-- ----------------------------------------------------------------------------
-- Drawing
-- ----------------------------------------------------------------------------
local function dashedBorder(p, x, y, w, h, c, t)
    local d, g = t * 4, t * 3
    local xx = x
    while xx < x + w do
        local l = math.min(d, x + w - xx)
        p:drawRect(xx, y, l, t, 1, col(c)); p:drawRect(xx, y + h - t, l, t, 1, col(c))
        xx = xx + d + g
    end
    local yy = y
    while yy < y + h do
        local l = math.min(d, y + h - yy)
        p:drawRect(x, yy, t, l, 1, col(c)); p:drawRect(x + w - t, yy, t, l, 1, col(c))
        yy = yy + d + g
    end
end

-- A filled circle in the box (x, y, s x s), built from one-pixel screen rows like ZeD.Atoms.drawStatusDot so its edge
-- is crisp at every scale; the hands are round (director, Oct 16 2026: "make primary and secondary circles not square")
local function disc(p, x, y, s, a, c)
    local rad = s / 2
    for row = 0, s - 1 do
        local dy = math.abs(row - rad + 0.5)
        local hw = math.floor(math.sqrt(math.max(0, rad * rad - dy * dy)) + 0.5)
        if hw > 0 then p:drawRect(x + math.floor(rad) - hw, y + row, hw * 2, 1, a, c.r, c.g, c.b) end
    end
end
-- its outline, t screen pixels thick
local function ring(p, x, y, s, t, a, c)
    local rad = s / 2
    local inner = math.max(0, rad - t)
    for row = 0, s - 1 do
        local dy = math.abs(row - rad + 0.5)
        local hw = math.floor(math.sqrt(math.max(0, rad * rad - dy * dy)) + 0.5)
        if hw > 0 then
            local iw = (dy < inner) and math.floor(math.sqrt(inner * inner - dy * dy) + 0.5) or 0
            local cx = x + math.floor(rad)
            if iw <= 0 then
                p:drawRect(cx - hw, y + row, hw * 2, 1, a, c.r, c.g, c.b)
            else
                p:drawRect(cx - hw, y + row, hw - iw, 1, a, c.r, c.g, c.b)
                p:drawRect(cx + iw, y + row, hw - iw, 1, a, c.r, c.g, c.b)
            end
        end
    end
end
B._disc, B._ring = disc, ring

function ZeD_BeltHUD:_drawStrap()
    local T = ZeD.T
    local s = self._strap
    local runs = self._runs or { { s.x, s.x + s.w, "leather" } }
    if strapTexture("mid") then
        -- the pixel-art straps: whole multiple k, centred on the strap's row; each run its own piece (its two
        -- cut ends and its middle repeated and clipped)
        local k = math.max(1, math.floor(T.scale or 1))
        local th, ew, tw = STRAP_TEX_H * k, STRAP_END * k, STRAP_TILE * k
        local y = s.y + math.floor((s.h - th) / 2)
        for _, r in ipairs(runs) do
            local rx0, rx1, mat = r[1], r[2], r[3]
            local L, M, R = matTexture(mat, "l"), matTexture(mat, "mid"), matTexture(mat, "r")
            if not (L and M and R) then L, M, R = strapTexture("l"), strapTexture("mid"), strapTexture("r") end
            local x0, x1 = rx0 + ew, rx1 - ew
            if x1 > x0 then
                self:setStencilRect(x0, y, x1 - x0, th)
                local xx = x0
                while xx < x1 do
                    self:drawTextureScaled(M, xx, y, tw, th, 1, 1, 1, 1)
                    xx = xx + tw
                end
                self:clearStencilRect()
            end
            self:drawTextureScaled(L, rx0, y, ew, th, 1, 1, 1, 1)
            self:drawTextureScaled(R, rx1 - ew, y, ew, th, 1, 1, 1, 1)
        end
        return
    end
    -- the art missing: the plain leather (no stitching since Oct 16 2026)
    local bands = 6
    for i = 0, bands - 1 do
        local f = i / (bands - 1)
        local y0 = s.y + math.floor(s.h * i / bands)
        local y1 = s.y + math.floor(s.h * (i + 1) / bands)
        self:drawRect(s.x, y0, s.w, y1 - y0, 1, LEATHER_TOP.r + (LEATHER_BOT.r - LEATHER_TOP.r) * f,
            LEATHER_TOP.g + (LEATHER_BOT.g - LEATHER_TOP.g) * f, LEATHER_TOP.b + (LEATHER_BOT.b - LEATHER_TOP.b) * f)
    end
    local e = T.px(1)
    self:drawRect(s.x, s.y, s.w, e, 1, col(LEATHER_EDGE))
    self:drawRect(s.x, s.y + s.h - e, s.w, e, 1, col(LEATHER_EDGE))
end

function ZeD_BeltHUD:_drawBuckle()
    local T = ZeD.T
    local b = self._buckle
    -- the closure by the waist belt's material (B.CLOSURE): the profession buckle on leather (and with no belt worn,
    -- the default leather strap), a knot on rope, the flat clip on webbing and nylon
    local c = self._closure
    local kind = c and c.kind or "buckle"
    if kind and kind ~= "buckle" then
        local tex = closureTexture(kind)
        if tex then self:drawTextureScaled(tex, c.x, c.y, BUCKLE_W * c.k, (c.h or BUCKLE_H) * c.k, 1, 1, 1, 1) end
        return
    end
    -- the profession's buckle, the largest whole multiple of 58 x 40 that fits, centred
    local p = self:player()
    local id = p and professionId(p)
    local tex = (id and buckleTexture(id)) or buckleTexture("unemployed")
    if tex then
        local k = math.max(1, math.floor(T.scale or 1))
        local w, h = 58 * k, 40 * k
        self:drawTextureScaledAspect(tex, b.x + math.floor((b.w - w) / 2), b.y + math.floor((b.h - h) / 2), w, h, 1, 1, 1, 1)
        return
    end
    local t = T.px(5)
    local half = math.floor(b.h / 2)
    -- the frame: brass, lit from above
    self:drawRect(b.x, b.y, b.w, t, 1, col(BRASS_A))
    self:drawRect(b.x, b.y + b.h - t, b.w, t, 1, col(BRASS_B))
    self:drawRect(b.x, b.y, t, half, 1, col(BRASS_A)); self:drawRect(b.x, b.y + half, t, b.h - half, 1, col(BRASS_B))
    self:drawRect(b.x + b.w - t, b.y, t, half, 1, col(BRASS_A)); self:drawRect(b.x + b.w - t, b.y + half, t, b.h - half, 1, col(BRASS_B))
    self:drawRectBorder(b.x, b.y, b.w, b.h, 1, col(BRASS_C))
    self:drawRectBorder(b.x + t, b.y + t, b.w - t * 2, b.h - t * 2, 1, col(BRASS_C))
    -- no bar across the middle (director: "doesnt work like that"); the
    -- strap shows through the open frame
end

local function wearColor(T, f)
    if f > 0.6 then return T.positive elseif f > 0.3 then return T.warning end
    return T.danger
end

function ZeD_BeltHUD:_drawBox(b, o)
    local T, tm = ZeD.T, ZeD.TM
    local p1 = T.px(1)
    local empty = not o.item
    local bg = empty and T.surf1 or T.surf2
    local round = b.kind == "hand"
    -- a fill over the whole box: the hands' a circle, the slots' a square
    local function fill(a, c)
        if round then disc(self, b.x, b.y, b.w, a, c) else self:drawRect(b.x, b.y, b.w, b.h, a, col(c)) end
    end
    fill(0.95, bg)
    if o.state == "fit" then fill(0.14, T.accent) end
    if o.state == "fitHover" then fill(0.22, T.accent) end
    -- the item, or the slot's name when empty
    if o.item then
        local tex = call(o.item, "getTex")
        local isz = b.kind == "hand" and T.px(40) or T.px(34)
        if tex then
            self:drawTextureScaledAspect(tex, b.x + math.floor((b.w - isz) / 2), b.y + math.floor((b.h - isz) / 2) - T.px(2), isz, isz,
                (o.ghost or o.inHand) and 0.25 or 1, 1, 1, 1)
        end
    elseif o.label then
        local f5 = T.fontF5
        local lw = tm:MeasureStringX(f5, o.label)
        local dc = T.textDim
        self:drawText(o.label, b.x + math.floor((b.w - lw) / 2), b.y + math.floor((b.h - tm:getFontHeight(f5)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f5)
    end
    -- border: dashed accent while drawn, accent while a drop fits, else the line (round on the hands)
    if round then
        -- (two design units: director, Oct 19 2026, "primary and secondary circles need thicker outline")
        if o.state == "fit" then ring(self, b.x, b.y, b.w, p1 * 2, 1, T.accent)
        elseif o.state == "fitHover" then ring(self, b.x, b.y, b.w, p1 * 3, 1, T.accent)
        else ring(self, b.x, b.y, b.w, p1 * 2, T.borderS.a or 1, T.borderS) end
    elseif o.inHand then
        dashedBorder(self, b.x, b.y, b.w, b.h, T.accent, p1)
    elseif o.state == "fit" then
        self:drawRectBorder(b.x, b.y, b.w, b.h, 1, col(T.accent))
    elseif o.state == "fitHover" then
        self:drawRectBorder(b.x, b.y, b.w, b.h, 1, col(T.accent))
        self:drawRectBorder(b.x + p1, b.y + p1, b.w - p1 * 2, b.h - p1 * 2, 1, col(T.accent))
    else
        self:drawRectBorder(b.x, b.y, b.w, b.h, T.borderS.a or 1, col(T.borderS))
    end
    -- the foot: IN HAND / BOTH, or the condition bar
    local f5 = T.fontF5
    if o.inHand or o.ghost then
        local tag = o.inHand and "IN HAND" or "BOTH"
        local tw = tm:MeasureStringX(f5, tag)
        local ac = T.accent
        local up = round and T.px(4) or 0                -- inside the circle's curve
        self:drawText(tag, b.x + math.floor((b.w - tw) / 2), b.y + b.h - tm:getFontHeight(f5) - p1 - up, ac.r, ac.g, ac.b, 1, f5)
    elseif o.item then
        local f = B.cond(o.item)
        if f then
            local bx, by, bw = b.x + T.px(3), b.y + b.h - T.px(5), b.w - T.px(6)
            if round then                                   -- a chord low in the circle
                bw = math.floor(b.w * 0.56); bx = b.x + math.floor((b.w - bw) / 2); by = b.y + b.h - T.px(10)
            end
            self:drawRect(bx, by, bw, T.px(3), 1, col(T.surf3))
            local fw = math.floor(bw * f)
            if fw > 0 then self:drawRect(bx, by, fw, T.px(3), 1, col(wearColor(T, f))) end
        end
    end
    -- the key that draws it
    if o.key ~= nil then
        local f1 = T.fontF1
        local txt = o.key or "-"
        local kh = tm:getFontHeight(f1)
        local kw = math.max(tm:MeasureStringX(f1, txt) + T.px(6), kh)
        local kc = o.key and T.accent or T.surf3
        self:drawRect(b.x, b.y, kw, kh, 1, col(kc))
        local tc = o.key and T.textOnAccent or T.textDim
        self:drawText(txt, b.x + math.floor((kw - tm:MeasureStringX(f1, txt)) / 2), b.y, tc.r, tc.g, tc.b, 1, f1)
    end
    -- a light or walkie that is on
    if o.lit and not o.inHand then
        local d = T.px(6)
        local lx, ly = b.x + b.w - d - T.px(3), b.y + T.px(3)
        if round then                                       -- on the circle's upper right, inside its edge
            local rad = b.w / 2
            lx = b.x + math.floor(rad + rad * 0.62 - d / 2) - T.px(2); ly = b.y + math.floor(rad - rad * 0.62 - d / 2) + T.px(2)
        end
        ZeD.Atoms.drawStatusDot(self, lx, ly, T.warning, d)
    end
    if o.state == "no" then fill(0.6, T.base) end
    if o.focus then
        local ac = T.accent
        if round then disc(self, b.x - T.px(3), b.y - T.px(3), b.w + T.px(6), 0.55, ac)
        else self:drawRect(b.x - T.px(3), b.y - T.px(3), b.w + T.px(6), b.h + T.px(6), 0.55, ac.r, ac.g, ac.b) end
    end
end

-- a small ZeD label chip above a box (the slot's name and key on hover)
function ZeD_BeltHUD:_chip(b, text)
    local T, tm = ZeD.T, ZeD.TM
    local f1 = T.fontF1
    local w = tm:MeasureStringX(f1, text) + T.px(12)
    local h = tm:getFontHeight(f1) + T.px(6)
    local x = b.x + math.floor((b.w - w) / 2)
    local y = b.y - h - T.px(6)
    self:drawRect(x, y, w, h, 0.95, col(T.surf1))
    self:drawRectBorder(x, y, w, h, 1, col(T.borderS))
    local ac = T.accent
    self:drawText(text, x + T.px(6), y + T.px(3), ac.r, ac.g, ac.b, 1, f1)
end

-- The belt draws under the safe-mode guard (SafeMode.lua): a failing frame is
-- logged once and its stencils cleared, and repeated failures hand the screen
-- back to vanilla's hotbar rather than throwing every frame.
function ZeD_BeltHUD:prerender()
    ZeD.Safe.guard(self, ZeD_BeltHUD._prerender, "belt")
end

function ZeD_BeltHUD:_prerender()
    local T = ZeD.T
    if not T then return end
    local p = self:player()
    if not self:wanted() then self._drawn = false; return end
    local slots = B.slots(self.playerNum)
    local w, h = self:_layout(slots)
    -- the buckle on the screen's centre (director, Oct 19 2026: the belt may sit off centre;
    -- the buckle is where the eye goes)
    local b = self._buckle
    local bx = b and (b.x + math.floor(b.w / 2)) or math.floor(w / 2)
    local sx = getPlayerScreenLeft(self.playerNum) + math.floor(getPlayerScreenWidth(self.playerNum) / 2) - bx
    local sy = getPlayerScreenTop(self.playerNum) + getPlayerScreenHeight(self.playerNum) - h - T.px(BOTTOM)
    if self:getX() ~= sx then self:setX(sx) end
    if self:getY() ~= sy then self:setY(sy) end
    if self:getWidth() ~= w then self:setWidth(w) end
    if self:getHeight() ~= h then self:setHeight(h) end
    self._drawn = true

    self:_drawStrap()
    self:_drawBuckle()

    local mx, my = self:getMouseX(), self:getMouseY()
    local over = (mx >= 0 and my >= 0 and mx < w and my < h) and self:boxAt(mx, my) or nil
    local dragging = (not self._out) and draggedItems() or nil
    local pri, sec = p:getPrimaryHandItem(), p:getSecondaryHandItem()
    local two = pri ~= nil and pri == sec
    local gpTarget = self._gp and not self._gp.inList and self:_gpBox() or nil
    self._hover = nil

    for _, b in ipairs(self._boxes) do
        local o = {}
        if b.kind == "watch" then
            ZeD.WatchMini.draw(self, b.x, b.y, b.plate, ZeD.Watch.miniState(p, b.item))
            if gpTarget == b then self:drawRect(b.x, b.y, b.w, b.h, 0.55, col(T.accent)) end
            if b == over and not dragging then self._hover = { b = b } end
        elseif b.kind == "hand" then
            local item = b.which == "p" and pri or (not two and sec or nil)
            o.item = item
            o.label = b.which == "p" and "PRIMARY" or "SECONDARY"
            if b.which == "s" and two then o.item = pri; o.ghost = true end
            o.lit = item and call(item, "canBeActivated") and call(item, "isActivated")
        else
            local s = b.s
            o.item, o.key, o.label, o.inHand = s.item, s.key, s.short, s.inHand
            o.lit = s.item and not instanceof(s.item, "HandWeapon") and call(s.item, "canBeActivated") and call(s.item, "isActivated")
        end
        if b.kind ~= "watch" then
            -- a drag in progress lights the boxes that take it (and dims the rest)
            if dragging then
                local st = self:_dropState(b, dragging)
                if st == "fit" then o.state = (b == over) and "fitHover" or "fit" else o.state = "no" end
            end
            o.focus = gpTarget == b
            self:_drawBox(b, o)
            if b == over and not dragging then self._hover = { b = b, item = o.item } end
        end
    end

    -- the hovered box: its name and key, and the item tooltip (not while a
    -- menu is open over the belt)
    local ctx = getPlayerContextMenu(self.playerNum)
    if ctx and ctx:isAnyVisible() then self._hover = nil end
    local hv = self._hover
    if hv and hv.b.kind == "slot" then
        local s = hv.b.s
        self:_chip(hv.b, string.upper(s.name) .. (s.key and (" " .. DOT .. " KEY " .. s.key) or ""))
    elseif hv and hv.b.kind == "hand" then
        self:_chip(hv.b, hv.b.which == "p" and "PRIMARY" or "SECONDARY")
    elseif hv and hv.b.kind == "watch" then
        local id = ZeD.WatchMini.hit(hv.b.plate, mx - hv.b.x, my - hv.b.y)
        local name = string.upper(call(hv.b.item, "getDisplayName") or "WATCH")
        local sp = ZeD.Watch.miniState(p, hv.b.item).speed
        local lbl = (id == "speed" and ("SPEED " .. DOT .. " " .. math.max(sp, 1) .. "X"))
            or (id == "start" and (sp == 0 and "START" or "PAUSE"))
            or (id == "light" and "LIGHT")
            or (id == "face" and (name .. " " .. DOT .. " " .. ((ZeD.Watch.getInstance() and ZeD.Watch.getInstance()._popped) and "TUCK AWAY" or "FULL WATCH")))
            or name
        self:_chip(hv.b, lbl)
    end
    if dragging and over and over.kind == "slot" then
        local st, it = self:_dropState(over, dragging)
        local cur = over.s.item
        if st == "fit" and cur then self:_chip(over, "REPLACE " .. string.upper(cur:getDisplayName())) end
    end
    self:_tooltip(hv and hv.item or nil, hv and hv.b or nil)

    -- dragging an item off the belt: its icon follows the pointer
    if self._out and self._out.active then
        local tex = call(self._out.item, "getTex")
        if tex then
            local isz = T.px(32)
            self:drawTextureScaledAspect(tex, mx + T.px(10), my - T.px(4), isz, isz, 0.85, 1, 1, 1)
        end
    end
    if self._gp then self:_drawPadList() end
end

function ZeD_BeltHUD:render() end

-- the vanilla item tooltip (ISToolTipInv, the same one the hotbar used),
-- standing above the hovered box and its name chip rather than following
-- the pointer over the belt
function ZeD_BeltHUD:_tooltip(item, b)
    local ctx = getPlayerContextMenu(self.playerNum)
    if item and b and not (ctx and ctx:isAnyVisible()) and not self._out then
        if not self._tip then
            self._tip = ISToolTipInv:new(item)
            self._tip:initialise()
            self._tip:addToUIManager()
            self._tip:setOwner(self)
            self._tip:setCharacter(self:player())
        else
            self._tip:setItem(item)
            -- (the belt outlives a respawn: the tooltip follows the character now playing;
            -- code audit Oct 17 2026)
            local p = self:player()
            if self._tipChr ~= p then self._tip:setCharacter(p) end
            self._tip:bringToTop()
        end
        self._tipChr = self:player()
        local T = ZeD.T
        local chipH = ZeD.TM:getFontHeight(T.fontF1) + T.px(6)
        self._tip.followMouse = false
        self._tip.anchorBottomLeft = { x = self:getAbsoluteX() + b.x, y = self:getAbsoluteY() + b.y - chipH - T.px(12) }
        self._tip:setVisible(true)
    elseif self._tip then
        self._tip:setVisible(false)
    end
end

-- ----------------------------------------------------------------------------
-- Mouse (a top-level panel gets its own events; clicks off a box pass through)
-- ----------------------------------------------------------------------------
function ZeD_BeltHUD:onMouseDown(x, y)
    if not self._drawn then return false end
    local b = self:boxAt(x, y)
    if not b then return false end
    if b.kind == "watch" then
        local id = ZeD.WatchMini.hit(b.plate, x - b.x, y - b.y)
        if id then
            pcall(function() getSoundManager():playUISound("UIActivateButton") end)
            ZeD.Watch.act(id)
        end
        return true
    end
    self._press = { b = b, x = getMouseX(), y = getMouseY() }
    if b.kind == "slot" and b.s.item and not b.s.inHand then
        self._out = { item = b.s.item, from = b, active = false }
        self:setCapture(true)
    end
    return true
end

function ZeD_BeltHUD:onMouseMove(dx, dy)
    local o = self._out
    if o and not o.active and self._press then
        local T = ZeD.T
        if math.abs(getMouseX() - self._press.x) >= T.px(DRAG_PX) or math.abs(getMouseY() - self._press.y) >= T.px(DRAG_PX) then
            o.active = true
        end
    end
end
function ZeD_BeltHUD:onMouseMoveOutside(dx, dy) self:onMouseMove(dx, dy) end

function ZeD_BeltHUD:_finishOut(x, y)
    local o = self._out
    self._out = nil
    self:setCapture(false)
    if not (o and o.active) then return false end
    -- onto a hand: draw it into that hand
    local b = (x >= 0 and y >= 0 and x < self:getWidth() and y < self:getHeight()) and self:boxAt(x, y) or nil
    if b and b.kind == "hand" then
        B.equipHand(self.playerNum, o.item, b.which)
        return true
    end
    -- into the bags (a ZeD inventory list): take it off the belt
    local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
    local ww = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    for _, win in ipairs({ cw or false, ww or false }) do  -- (a closed window is false, not a nil hole that ends ipairs early; code audit Oct 17 2026)
        local c = win and win._contentPanel
        if c and c:isReallyVisible() and c:isMouseOver() then
            B.detach(self.playerNum, o.item)
            return true
        end
    end
    return true
end

function ZeD_BeltHUD:onMouseUp(x, y)
    if not self._drawn then return false end
    if self._out and self._out.active then return self:_finishOut(x, y) end
    self._out = nil
    self:setCapture(false)
    local pr = self._press
    self._press = nil
    local b = self:boxAt(x, y)
    if not (pr and b and sameBox(pr.b, b)) then return b ~= nil end
    if b.kind == "slot" then
        pcall(function() getSoundManager():playUISound("UIActivateButton") end)
        B.activate(self.playerNum, b.i)
    end
    return true
end
function ZeD_BeltHUD:onMouseUpOutside(x, y)
    if self._out and self._out.active then self:_finishOut(x, y) end
    self._out = nil
    self._press = nil
    self:setCapture(false)
end

function ZeD_BeltHUD:onRightMouseUp(x, y)
    if not self._drawn then return false end
    local b = self:boxAt(x, y)
    if not b then return false end
    if b.kind == "watch" then return true end
    local p = self:player()
    if b.kind == "slot" then
        B.rightMenu(self.playerNum, b.i)
    else
        local item = b.which == "p" and p:getPrimaryHandItem() or p:getSecondaryHandItem()
        if item then ISInventoryPaneContextMenu.createMenu(self.playerNum, true, { item }, getMouseX(), getMouseY()) end
    end
    return true
end
function ZeD_BeltHUD:onRightMouseDown(x, y) return self._drawn and self:boxAt(x, y) ~= nil end

-- A drop from a ZeD inventory list over the belt (InventoryRenderer.handleDrop
-- asks first): attach to a slot, or equip into a hand. True when taken.
function B.takeDrop(playerNum, items)
    local hud = B._hud
    if not (hud and hud._drawn and items and #items > 0) then return false end
    local mx, my = hud:getMouseX(), hud:getMouseY()
    if mx < 0 or my < 0 or mx >= hud:getWidth() or my >= hud:getHeight() then return false end
    local b = hud:boxAt(mx, my)
    if not b or b.kind == "watch" then return true end   -- over the strap or the watch: no drop to the floor either
    local st, it = hud:_dropState(b, items)
    if st ~= "fit" then return true end
    if b.kind == "hand" then
        local two = call(it, "isTwoHandWeapon") == true or call(it, "isRequiresEquippedBothHands") == true
        B.equipHand(playerNum, it, two and "both" or b.which)
    else
        B.attach(playerNum, it, b.i)
    end
    return true
end

-- Where the small watch sits on screen: x, y, w and the side ("left" of the
-- main hand for a right-wrist watch, else "right"), or nil
function B.watchScreen()
    local hud = B._hud
    if not (hud and hud._drawn) then return nil end
    for _, b in ipairs(hud._boxes) do
        if b.kind == "watch" then
            return hud:getAbsoluteX() + b.x, hud:getAbsoluteY() + b.y, b.w, (b.wrist == "right") and "left" or "right"
        end
    end
    return nil
end

-- Where a slot's box sits on screen (the hold-a-key list opens above it)
function B.boxScreen(i)
    local hud = B._hud
    if not (hud and hud._drawn) then return nil end
    for _, b in ipairs(hud._boxes) do
        if b.kind == "slot" and b.i == i then
            return hud:getAbsoluteX() + b.x + math.floor(b.w / 2), hud:getAbsoluteY() + b.y
        end
    end
    return nil
end

-- ----------------------------------------------------------------------------
-- Controller: D-pad Left focuses the belt (Overrides/Belt.lua routes it)
-- ----------------------------------------------------------------------------
function ZeD_BeltHUD:_gpBox()
    local g = self._gp
    if not g then return nil end
    return self._boxes[g.idx]
end

function B.focus(playerNum)
    local hud = B._hud
    if not (hud and hud:wanted() and hud._drawn) then return false end
    local p = hud:player()
    -- start on the first slot (after the main hand, and the watch when it sits there)
    hud._gp = { idx = hud:_firstSlotIdx(), inList = false, row = 1, list = B.otherWeapons(p) }
    setJoypadFocus(playerNum, hud)
    p:setJoypadIgnoreAimUntilCentered(true)
    return true
end

function ZeD_BeltHUD:_firstSlotIdx()
    for i, b in ipairs(self._boxes) do if b.kind == "slot" then return i end end
    return math.min(2, #self._boxes)
end

function ZeD_BeltHUD:_leavePad()
    self._gp = nil
    setJoypadFocus(self.playerNum, nil)
end

function ZeD_BeltHUD:onJoypadDirLeft()
    local g = self._gp
    if not g or g.inList then return end
    if g.idx > 1 then g.idx = g.idx - 1 end
end
function ZeD_BeltHUD:onJoypadDirRight()
    local g = self._gp
    if not g or g.inList then return end
    if g.idx < #self._boxes then g.idx = g.idx + 1 end
end
function ZeD_BeltHUD:onJoypadDirUp()
    local g = self._gp
    if not g then return end
    if not g.inList then
        if #g.list > 0 then g.inList, g.row = true, #g.list end
    elseif g.row > 1 then g.row = g.row - 1 end
end
function ZeD_BeltHUD:onJoypadDirDown()
    local g = self._gp
    if not (g and g.inList) then return end
    if g.row < #g.list then g.row = g.row + 1 else g.inList = false end
end

function ZeD_BeltHUD:onJoypadDown(button)
    local g = self._gp
    if not g then return end
    local p = self:player()
    if button == Joypad.BButton then
        if g.inList then g.inList = false else self:_leavePad() end
        return
    end
    if g.inList then
        local e = g.list[g.row]
        if button == Joypad.AButton and e then
            if e.kind == "light" then ISDPadWheels.onToggleLight(p, e.item) else ISDPadWheels.onEquipPrimary(p, e.item) end
            self:_leavePad()
        end
        return
    end
    local b = self:_gpBox()
    if not b then return end
    if b.kind == "watch" then
        if button == Joypad.AButton then ZeD.Watch.act("start")
        elseif button == Joypad.XButton then ZeD.Watch.act("speed") end
        return
    end
    if button == Joypad.AButton then
        if b.kind == "slot" then
            B.activate(self.playerNum, b.i)
        else
            local item = b.which == "p" and p:getPrimaryHandItem() or p:getSecondaryHandItem()
            if item then ISInventoryPaneContextMenu.unequipItem(item, self.playerNum) end
        end
    elseif button == Joypad.XButton then
        local ax, ay = self:getAbsoluteX() + b.x + math.floor(b.w / 2), self:getAbsoluteY() + b.y
        local ctx
        if b.kind == "slot" then
            ctx = B.slotMenu(self.playerNum, b.i, ax, ay)
        else
            local item = b.which == "p" and p:getPrimaryHandItem() or p:getSecondaryHandItem()
            if item then ctx = ISInventoryPaneContextMenu.createMenu(self.playerNum, true, { item }, ax, ay) end
        end
        if ctx then
            ctx.origin = self
            ctx.mouseOver = 1
            setJoypadFocus(self.playerNum, ctx)
        end
    end
end

function ZeD_BeltHUD:onLoseJoypadFocus(joypadData)
    -- a context menu opened from X takes focus; come back to the belt after it
    local ctx = getPlayerContextMenu(self.playerNum)
    if not (ctx and ctx:isAnyVisible()) then self._gp = nil end
end
function ZeD_BeltHUD:onGainJoypadFocus(joypadData)
    if not self._gp then self._gp = { idx = self:_firstSlotIdx(), inList = false, row = 1, list = B.otherWeapons(self:player()) } end
end

-- IN YOUR BAGS: the rest of vanilla's D-pad Left wheel, above the belt
function ZeD_BeltHUD:_drawPadList()
    local g = self._gp
    local T, tm = ZeD.T, ZeD.TM
    local rows = g.list
    local rh = T.px(LIST_ROW_H)
    local lw = T.px(LIST_W)
    local hh = T.px(22)
    local total = hh + #rows * rh
    local x = math.floor((self:getWidth() - lw) / 2)
    local y = -total - T.px(10)
    self:drawRect(x, y, lw, total, 0.96, col(T.surf1))
    self:drawRectBorder(x, y, lw, total, 1, col(T.borderS))
    self:drawRect(x, y, lw, hh, 1, col(T.surf2))
    local f1, f2 = T.fontF1, T.fontF2
    local ac = T.accent
    self:drawText("IN YOUR BAGS", x + T.px(8), y + math.floor((hh - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
    if #rows == 0 then return end
    for n, e in ipairs(rows) do
        local ry = y + hh + (n - 1) * rh
        if g.inList and g.row == n then self:drawRect(x, ry, lw, rh, 0.55, col(T.accent)) end
        local tex = call(e.item, "getTex")
        local isz = T.px(18)
        if tex then self:drawTextureScaledAspect(tex, x + T.px(8), ry + math.floor((rh - isz) / 2), isz, isz, 1, 1, 1, 1) end
        local name = (e.kind == "light" and "Best light: " or "") .. e.item:getDisplayName()
        local tc = T.text
        self:drawText(name, x + T.px(34), ry + math.floor((rh - tm:getFontHeight(f2)) / 2), tc.r, tc.g, tc.b, 1, f2)
        local where = "INVENTORY"
        local c = e.item:getContainer()
        local bag = c and c:getContainingItem()
        if bag then where = string.upper(bag:getName()) end
        if e.item:getAttachedSlot() > 0 then where = B.tagFor(e.item:getAttachedSlot()) end
        ZeD.Atoms.drawTextRight(self, where, x + lw - T.px(8), ry + math.floor((rh - tm:getFontHeight(f1)) / 2), f1, T.textDim)
        self:drawRect(x, ry + rh - T.px(1), lw, T.px(1), 1, col(T.border))
    end
end

-- ----------------------------------------------------------------------------
-- Lifecycle: one belt for player one (vanilla's hotbar is player one only)
-- ----------------------------------------------------------------------------
function B.install()
    if B._hud then return B._hud end
    local hud = ZeD_BeltHUD:new(0)
    hud:initialise()
    hud:addToUIManager()
    hud:setVisible(true)
    B._hud = hud
    print("[ZeD] Belt: hands + hotbar belt installed")
    return hud
end
function B.getHUD() return B._hud end

-- hidden while it should not show (a top-level panel would still catch clicks)
local function visibilityTick()
    local hud = B._hud
    if not hud then return end
    local want = hud:wanted()
    if want ~= hud:getIsVisible() then hud:setVisible(want) end
    if not want then
        hud._drawn = false
        if hud._tip then hud._tip:setVisible(false) end
        if hud._gp then hud:_leavePad() end
    end
end

Events.OnGameStart.Add(function() B._hud = nil; B.install() end)
Events.OnTick.Add(visibilityTick)

print("[ZeD] Belt: module loaded")
return B
