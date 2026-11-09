-- ZeD-UI/42/media/lua/client/ZeD/EquipmentTab.lua
-- ============================================================================
-- EQUIPMENT TAB — client; the Character window's Equip drawer (an organism-
-- scale tab renderer, registered as "equip" in the drawer dispatch table).
-- Three faces: the grouped slot list (worn and held slots, the belt's hotbar
-- rows, the defense dashboard at the foot), the doll view (EquipDoll.lua),
-- and card mode — a selected slot hands its item to a ZeD_ItemCard child.
-- Everything else draws immediate-mode into the drawer panel, stamping zones
-- on the window each frame; CharacterWindow routes clicks and the controller
-- through those zones.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/ZeD_BodyFigure"
require "ZeD/ProtectionTab"
require "ZeD/EquipDoll"
require "ZeD/ZeD_EquipLoadout"
require "ZeD/ZeD_RestockPin"

ZeD = ZeD or {}
ZeD.EquipmentTab = {}

-- The tab's data refreshes run on the clock, not on frames drawn: 15 frames is 250 ms at 60 FPS
-- but runs 2.4-4 times as often at 144-240 Hz. True once periodMs has
-- passed since owner[key] (or on the first call, or forced: the cache was dropped). The runs keep a
-- beat of periodMs; a forced run, or one after a gap (the tab not drawn), starts the period again,
-- as the frame count went back to 0. A window's first run starts at its own
-- phase (owner._zedPhase, shared by the tabs of one window), so windows opened together don't
-- refresh on the same frame. Only differences of the clock are taken (no %: it is past 2^31).
local function dueMs(owner, key, periodMs, force)
    local now = getTimestampMs()
    local last = owner[key]
    if not force and last and now >= last and now - last < periodMs then return false end
    if last == nil then
        local ph = owner._zedPhase
        if not ph then
            ZeD._throttleN = (ZeD._throttleN or 0) + 1
            local g = ZeD._throttleN * 0.6180339887
            ph = g - math.floor(g)
            owner._zedPhase = ph
        end
        owner[key] = now - math.floor(ph * periodMs)
    elseif force or now < last or now - last >= periodMs * 2 then
        owner[key] = now               -- (forced, or after a gap: the period starts again)
    else
        owner[key] = last + periodMs   -- (on the beat: a late frame doesn't stretch the next period)
    end
    return true
end

-- ============================================================================
-- SLOT DEFINITIONS
-- Each group has an ordered list of slots. Each slot has a 3-letter type code,
-- a display label, and the PZ body location strings it maps to.
-- First worn item matching any location in the array fills the slot.
-- ============================================================================

local EQUIP_GROUPS = {
    { id = "head", key = "UI_ZeD_Equip_GroupHead", slots = {
        { type = "HAT", vkey = "UI_ClothingType_Hat",   locs = {"hat", "fullhat", "sweaterhat", "jackethat", "jackethatbulky", "fullsuithead", "fullsuitheadscba"} },
        { type = "EYE", key = "UI_ZeD_Equip_Eyewear",   locs = {"eyes", "lefteye", "righteye"} },
        { type = "MSK", vkey = "UI_ClothingType_Mask",  locs = {"mask", "maskeyes", "maskfull"} },
        { type = "EAR", vkey = "UI_ClothingType_Ears",  locs = {"ears", "eartop"} },
        { type = "SCF", vkey = "UI_ClothingType_Scarf", locs = {"scarf", "necktexture"} },
    }},
    { id = "torso", key = "UI_ZeD_Equip_GroupTorso", slots = {
        { type = "OUT", key = "UI_ZeD_Equip_Outer",         locs = {"jacket", "jacketdown", "jacketbulky", "jacketsuit", "boilersuit", "fullsuit", "fulltop", "bathrobe", "fullrobe", "bodycostume", "sweater", "jersey"} },
        { type = "INR", key = "UI_ZeD_Equip_Inner",         locs = {"tshirt", "tanktop", "shirt", "shortsleeveshirt", "torso1", "torso1legs1", "torsoextra"} },
        { type = "VST", vkey = "UI_ClothingType_Vest",      locs = {"torsoextravest", "torsoextravestbullet", "cuirass", "gorget", "vesttexture", "shoulderholster"} },
        { type = "UND", vkey = "UI_ClothingType_Underwear", locs = {"underwear", "underweartop", "underwearbottom", "underwearextra1", "underwearextra2"} },
        { type = "NKL", vkey = "UI_ClothingType_Neck",      locs = {"necklace", "necklacelong", "neck"} },
    }},
    { id = "arms", key = "UI_ZeD_Equip_GroupArms", slots = {
        { type = "GLV", vkey = "UI_ClothingType_Hands", locs = {"hands", "handsleft", "handsright"} },
        { type = "WCH", key = "UI_ZeD_Equip_Wrist",     locs = {"leftwrist", "rightwrist"} },
        { type = "RNG", key = "UI_ZeD_Equip_Ring",      locs = {"leftmiddlefinger", "rightmiddlefinger", "leftringfinger", "rightringfinger"} },
        { type = "ARM", key = "UI_ZeD_Equip_Arms",      locs = {"leftarm", "rightarm", "forearmleft", "forearmright", "elbowleft", "elbowright"} },
        { type = "SHD", key = "UI_ZeD_Equip_Shoulder",  locs = {"shoulderpadleft", "shoulderpadright", "sportshoulderpad", "sportshoulderpaddontop"} },
    }},
    { id = "legs", key = "UI_ZeD_Equip_GroupLegs", slots = {
        { type = "PNT", vkey = "UI_ClothingType_Pants", locs = {"pants", "pantsskinny", "pantsextra", "shortpants", "shortsshort", "legs1", "skirt", "longskirt", "dress", "longdress"} },
        { type = "SOC", vkey = "UI_ClothingType_Socks", locs = {"socks"} },
        { type = "BOT", vkey = "UI_ClothingType_Shoes", locs = {"shoes"} },
        { type = "KNE", key = "UI_ZeD_Equip_KneeLeg",   locs = {"kneeleft", "kneeright", "calfleft", "calfright", "calflefttexture", "calfrighttexture", "thighleft", "thighright", "gaiterleft", "gaiterright"} },
    }},
    { id = "held", key = "UI_ZeD_Equip_GroupHeld", slots = {
        { type = "PRI", vkey = "IGUI_PrimaryTooltip",   locs = {"__primary"} },
        { type = "SEC", vkey = "IGUI_SecondaryTooltip", locs = {"__secondary"} },
        { type = "BAG", key = "UI_ZeD_Equip_BackBag",   locs = {"back", "satchel"} },
        { type = "BLT", vkey = "UI_ClothingType_Belt",  locs = {"belt", "beltextra", "fannypackfront", "fannypackback", "webbing", "ankleholster", "ammostrap"} },
    }},
}

--- The words for a group or a slot: vanilla's own text where it has the same words
--- (vkey), else ZeD's (key). Looked up where drawn and measured, so the language applies.
function ZeD.EquipmentTab.wordsOf(def)
    if not def then return "" end
    if def.vkey then return getText(def.vkey) end
    if def.key then return ZeD.tr(def.key) end
    return def.type or def.id or ""
end

-- A slot's short words ("Glv" for Gloves, "Inr" for Inner): the SLOT column takes them
-- before an item's name is cut — at the half card the names otherwise read "T-shi..."
-- beside a whole "Inner". Words of four letters or fewer stay whole. Through ZeD.tr,
-- so a language gives its own.
local SHORT_KEY = {
    HAT = "UI_ZeD_Equip_Short_HAT", EYE = "UI_ZeD_Equip_Short_EYE", MSK = "UI_ZeD_Equip_Short_MSK",
    EAR = "UI_ZeD_Equip_Short_EAR", SCF = "UI_ZeD_Equip_Short_SCF",
    OUT = "UI_ZeD_Equip_Short_OUT", INR = "UI_ZeD_Equip_Short_INR", VST = "UI_ZeD_Equip_Short_VST",
    UND = "UI_ZeD_Equip_Short_UND", NKL = "UI_ZeD_Equip_Short_NKL",
    GLV = "UI_ZeD_Equip_Short_GLV", WCH = "UI_ZeD_Equip_Short_WCH", RNG = "UI_ZeD_Equip_Short_RNG",
    ARM = "UI_ZeD_Equip_Short_ARM", SHD = "UI_ZeD_Equip_Short_SHD",
    PNT = "UI_ZeD_Equip_Short_PNT", SOC = "UI_ZeD_Equip_Short_SOC", BOT = "UI_ZeD_Equip_Short_BOT",
    KNE = "UI_ZeD_Equip_Short_KNE",
    PRI = "UI_ZeD_Equip_Short_PRI", SEC = "UI_ZeD_Equip_Short_SEC", BAG = "UI_ZeD_Equip_Short_BAG",
    BLT = "UI_ZeD_Equip_Short_BLT",
}
function ZeD.EquipmentTab.shortOf(def)
    local k = def and SHORT_KEY[def.type]
    if k then return ZeD.tr(k) end
    return ZeD.EquipmentTab.wordsOf(def)
end

-- Build reverse lookup: PZ body location string → {groupIdx, slotIdx}
-- All keys stored lowercase for case-insensitive matching.
local LOCATION_TO_SLOT = {}
for gi, group in ipairs(EQUIP_GROUPS) do
    for si, slot in ipairs(group.slots) do
        for _, loc in ipairs(slot.locs) do
            if loc:sub(1, 2) ~= "__" then
                LOCATION_TO_SLOT[string.lower(loc)] = { gi = gi, si = si }
            end
        end
    end
end

-- ============================================================================
-- LAYOUT CONSTANTS
-- ============================================================================

local GROUP_H    = 15  -- group header height (the library's category row, matches T.sp.catHdrH)

-- The controller is on this element of the tab: the window has the focus, the
-- controller is in use (Focus.liveZone) and the focus is in the tab's zone.
-- Returns the focus mark's opts when it is, else nil.
local _eqFocus = {}
local function eqFocus(win, id)
    if not (win and id ~= nil and win._gpFocusedEquipSlot == id) then return nil end
    local Focus = ZeD.Input and ZeD.Input.Focus
    local z = Focus and Focus.liveZone and Focus.liveZone(win)
    if not (z and z.zone == "charTabContent") then return nil end
    _eqFocus.win, _eqFocus.zone = win, "charTabContent"
    return _eqFocus
end

-- The pointer is on (x, y, w, h) of the list (inside its scroll view, which the
-- tab stamps as win._equipRowClip), and the controller's mark is not showing
local function eqHover(panel, win, x, y, w, h)
    local c = win and win._equipRowClip
    local my = panel:getMouseY()
    if c and (my < c.y0 or my >= c.y1) then return false end
    return ZeD.Atoms.mouseIn(panel, x, y, w, h)
end

-- A row's condition: the framed strip (ZeD.Atoms.drawFillBar, ten segments) at the list
-- rows' compact height, its middle at cy, in the condition's colours. True while the
-- pointer is on it (its help line: "Condition 64%")
local function eqCondition(panel, x, cy, w, f)
    if not f or w <= 0 then return false end
    local A = ZeD.Atoms
    local ch = (A.fillBarCompactH and A.fillBarCompactH()) or ZeD.T.px(8)
    return A.drawFillBar(panel, x, cy - math.floor(ch / 2), w, f, true, nil, ch, ZeD.tr("IGUI_invpanel_Condition"))
end
local COND_BAR_W = 80  -- condition bar width
local PROT_COL_W = 32  -- protection stat column width

-- Pre-computed label column width (widest label across all slots, measured lazily)
local _labelColW = nil
local _labelColWScale = nil  -- re-measure when T.scale (root x text size) changes
local function getLabelColW()
    -- re-measured when the scale changes, or the test language is switched
    local sig = tostring(ZeD.T.scale) .. (ZeD.trTestOn() and "t" or "")
    if _labelColW and _labelColWScale == sig then return _labelColW end
    local tm = ZeD.TM
    local T = ZeD.T
    local maxW = 0
    for _, group in ipairs(EQUIP_GROUPS) do
        for _, slot in ipairs(group.slots) do
            -- measured in F1, the font the SLOT column draws in (it was measured
            -- in the narrower F5, so every label cut to "I..." even at Small)
            local w = tm:MeasureStringX(T.fontF1, ZeD.EquipmentTab.wordsOf(slot))
            if w > maxW then maxW = w end
        end
    end
    _labelColW = math.ceil(maxW + T.sp.sm * 2)   -- the row draws it inset by padX either side
    _labelColWScale = sig
    return _labelColW
end

-- The SLOT column at its short words, measured the same way
local _shortColW, _shortColWScale = nil, nil
local function getShortColW()
    local sig = tostring(ZeD.T.scale) .. (ZeD.trTestOn() and "t" or "")
    if _shortColW and _shortColWScale == sig then return _shortColW end
    local tm, T = ZeD.TM, ZeD.T
    local maxW = 0
    for _, group in ipairs(EQUIP_GROUPS) do
        for _, slot in ipairs(group.slots) do
            local w = tm:MeasureStringX(T.fontF1, ZeD.EquipmentTab.shortOf(slot))
            if w > maxW then maxW = w end
        end
    end
    _shortColW = math.ceil(maxW + T.sp.sm * 2)
    _shortColWScale = sig
    return _shortColW
end

-- The protection and weight columns as narrow as what they hold: a protection column its
-- dot or its head word ("Bite"), the weight its number ("00.0") or "Wt", each with 2u
-- either side; measured the same way
local PROT_HEADS = { "IGUI_health_Bite", "UI_ZeD_Equip_ColScratch", "UI_ZeD_Equip_ColBullet" }
local _narrowProtW, _narrowWtW, _narrowSig = nil, nil, nil
local function getNarrowColW()
    local sig = tostring(ZeD.T.scale) .. (ZeD.trTestOn() and "t" or "")
    if _narrowProtW and _narrowSig == sig then return _narrowProtW, _narrowWtW end
    local tm, T = ZeD.TM, ZeD.T
    local p = T.px(6)   -- (the dot)
    for _, k in ipairs(PROT_HEADS) do p = math.max(p, tm:MeasureStringX(T.fontF5, ZeD.tr(k))) end
    local wt = math.max(tm:MeasureStringX(T.fontF1, "00.0"), tm:MeasureStringX(T.fontF5, ZeD.tr("UI_ZeD_Equip_ColWeight")))
    _narrowProtW = math.ceil(p + T.px(4))
    _narrowWtW = math.ceil(wt + T.px(4))
    _narrowSig = sig
    return _narrowProtW, _narrowWtW
end

-- The widest worn item's name (F2), kept per name and scale: the list stamps it as
-- win._equipNameNeed each frame, and the SLOT column shortens when the names lack it
local _nameW, _nameWSig = {}, nil
local function nameWidth(name)
    local sig = tostring(ZeD.T.scale)
    if _nameWSig ~= sig then _nameW = {}; _nameWSig = sig end
    local w = _nameW[name]
    if not w then w = ZeD.TM:MeasureStringX(ZeD.T.fontF2, name); _nameW[name] = w end
    return w
end

-- Default resizable column widths (matches inventory renderer pattern)
local DIV_W = 6  -- divider hit zone width
local function getDefaultColWidths(scale)
    local T = ZeD.T
    return {
        slot = getLabelColW() + T.px(4),
        cond = T.px(COND_BAR_W) + T.px(4),
        wt   = math.floor(40 * scale),
    }
end

-- Shared column layout: NAME SLOT COND BITE SCR BUL WT
-- Returns table of column X positions and widths
local function calcEquipColumns(w, win)
    local T     = ZeD.T
    local sp    = T.sp
    local scale = T.scale or 1
    local padX  = sp.sm
    local rowH  = T.rowH
    local iconW = rowH - T.px(8)
    local iconGap = sp.iconGap or T.px(6)

    -- Resizable column widths from win state
    local cw = win and win._equipColWidths
    if not cw then cw = getDefaultColWidths(scale) end
    local slotColW = cw.slot
    local condColW = cw.cond
    local wtColW   = cw.wt

    -- Fixed-width protection columns
    local protColW = math.floor(PROT_COL_W * scale)

    -- Name fills remaining space
    local rightCols = slotColW + condColW + protColW * 3 + wtColW + padX
    local nameX = padX + iconW + iconGap
    local nameW = w - nameX - rightCols
    -- the names lack room at the full slot words (the half card): the slot words shorten
    -- first ("Glv", "Inr"), before a name is cut. A width the player dragged stays theirs;
    -- the row then picks the words that fit it.
    -- Short words alone are not enough: the columns to the right (a 84u condition column,
    -- three 32u protection columns, a 40u weight column) want 270u of a ~205u half card,
    -- so the name would sit at its 40u least and protection and weight would draw past
    -- the card's edge. So, while the widest worn name lacks room, in turn: the slot
    -- words shorten (4u pads); the condition bar goes to its least (ten segments,
    -- ZeD.Atoms.fillBarMinW); protection and weight become as narrow as what they hold
    -- and the right margin 4u; then the name keeps the room it needs and the columns
    -- that no longer fit inside the card are left out from the right (weight, then the
    -- three protection columns together).
    local slotShort, slotPad, wtPad, protOn, wtOn = false, padX, padX, true, true
    local need = (win and win._equipNameNeed) or 0
    if not (win and win._equipColWidths) and nameW < need then
        local tight = T.px(4)
        local sw = getShortColW() - sp.sm * 2 + tight * 2
        if sw < slotColW then
            nameW = nameW + (slotColW - sw)
            slotColW = sw
            slotShort, slotPad = true, tight
        end
        if nameW < need then
            local cmin = ZeD.Atoms.fillBarMinW() + T.px(4)
            if cmin < condColW then
                nameW = nameW + (condColW - cmin)
                condColW = cmin
            end
        end
        if nameW < need then
            local pw, ww = getNarrowColW()
            if pw < protColW then
                nameW = nameW + (protColW - pw) * 3
                protColW = pw
            end
            if ww < wtColW then
                nameW = nameW + (wtColW - ww)
                wtColW = ww
            end
            nameW = nameW + padX - tight   -- (the right margin)
            wtPad = T.px(2)
        end
        if nameW < need then
            local room = nameW + protColW * 3 + wtColW   -- (the name and the columns after COND)
            local rest = room - need
            if rest < protColW * 3 + wtColW then wtOn = false end
            if rest < protColW * 3 then protOn = false end
            nameW = room - (protOn and protColW * 3 or 0) - (wtOn and wtColW or 0)
        end
    end
    if nameW < T.px(40) then nameW = T.px(40) end

    -- Column order: NAME SLOT COND BITE SCR BUL WT
    local slotX = nameX + nameW
    local condX = slotX + slotColW
    local biteX = condX + condColW
    local scrX  = biteX + protColW
    local bulX  = scrX + protColW
    local wtX   = bulX + protColW

    return {
        padX = padX, iconW = iconW, iconGap = iconGap,
        nameX = nameX, nameW = nameW,
        slotX = slotX, slotColW = slotColW, slotShort = slotShort, slotPad = slotPad,
        condX = condX, condColW = condColW,
        biteX = biteX, scrX = scrX, bulX = bulX, protColW = protColW, protOn = protOn,
        wtX = wtX, wtColW = wtColW, wtPad = wtPad, wtOn = wtOn,
    }
end

-- ============================================================================
-- HELPERS
-- ============================================================================

local safeGet = ZeD.Atoms.safeGet

-- Condition ratio for an item (0..1)
local function condRatio(item)
    if not item then return 0 end
    local c = safeGet(item, "getCondition") or 0
    local m = safeGet(item, "getConditionMax") or 1
    if m <= 0 then m = 1 end
    return math.max(0, math.min(1, c / m))
end

-- Protection stats for an item
local function getProtection(item)
    if not item then return { bite = 0, scratch = 0, bullet = 0 } end
    local bite = safeGet(item, "getBiteDefense") or 0
    local scratch = safeGet(item, "getScratchDefense") or 0
    local bullet = 0
    local parts = safeGet(item, "getCoveredParts")
    if parts and parts:size() > 0 then
        local part = parts:get(0)
        bullet = safeGet(item, "getDefForPart", part, false, true) or 0
    end
    return { bite = bite, scratch = scratch, bullet = bullet }
end

-- Get item texture for swatch
local function getItemTexture(item)
    if not item then return nil end
    local tex = safeGet(item, "getTexture")
    if tex then return tex end
    local icon = safeGet(item, "getIcon")
    if icon then return getTexture("Item_" .. icon .. ".png") end
    return nil
end

-- Count attachments on clothing
local function getAttachCount(item)
    if not item then return 0 end
    local patches = safeGet(item, "getPatchesNumber")
    return patches or 0
end

-- ============================================================================
-- DATA GATHERING (throttled)
-- ============================================================================

function ZeD.EquipmentTab.gatherData(playerObj)
    local character = playerObj

    -- Build empty slot grid from definitions
    local groups = {}
    for gi, gDef in ipairs(EQUIP_GROUPS) do
        local g = { id = gDef.id, key = gDef.key, vkey = gDef.vkey, slots = {} }
        for si, sDef in ipairs(gDef.slots) do
            g.slots[si] = {
                type   = sDef.type,
                key    = sDef.key,
                vkey   = sDef.vkey,
                item   = nil,
                cond   = 0,
                tex    = nil,
                attach = 0,
            }
        end
        groups[gi] = g
    end

    -- Fill slots from worn items — vanilla pattern: getWornItems(), 1-based,
    -- wornItem:getLocation() for the body location string (not getBodyLocation()).
    -- The game keeps worn items innermost first (WornItems.setItem inserts by
    -- the BodyLocations.lua order, "declared in render-order"), so the list is read from its end: the
    -- first item a slot takes is its outermost layer (a jacket over a sweater shows the jacket), as
    -- the doll (EquipDoll.gather) leads with it.
    local wornItems = character:getWornItems()
    if wornItems then
        for i = wornItems:size(), 1, -1 do
            local wornItem = wornItems:get(i - 1)
            if wornItem then
                local item = wornItem:getItem()
                local loc  = wornItem:getLocation()
                if item and loc then
                    -- PZ returns "base:tshirt", "base:pants" etc. — strip group prefix
                    local locStr = string.lower(tostring(loc))
                    local colon  = locStr:find(":")
                    if colon then locStr = locStr:sub(colon + 1) end
                    -- vanilla writes some with underscores (jacket_bulky, pants_skinny,
                    -- jackethat_bulky, knee_left); the slot table keeps them without
                    locStr = locStr:gsub("_", "")
                    local mapping = LOCATION_TO_SLOT[locStr]
                    if mapping then
                        local slot = groups[mapping.gi].slots[mapping.si]
                        -- Only fill if empty: the first match in worn order wins
                        if not slot.item then
                            slot.item   = item
                            slot.cond   = condRatio(item)
                            slot.tex    = getItemTexture(item)
                            slot.attach = getAttachCount(item)
                            slot.prot   = getProtection(item)
                        end
                    end
                end
            end
        end
    end

    -- Special: primary/secondary hand items
    local pri = character:getPrimaryHandItem()
    local sec = character:getSecondaryHandItem()
    for si, sDef in ipairs(EQUIP_GROUPS[5].slots) do
        if sDef.type == "PRI" and pri then
            groups[5].slots[si].item   = pri
            groups[5].slots[si].cond   = condRatio(pri)
            groups[5].slots[si].tex    = getItemTexture(pri)
            groups[5].slots[si].attach = 0
            groups[5].slots[si].prot   = getProtection(pri)
        elseif sDef.type == "SEC" and sec then
            if sec ~= pri then
                groups[5].slots[si].item   = sec
                groups[5].slots[si].cond   = condRatio(sec)
                groups[5].slots[si].tex    = getItemTexture(sec)
                groups[5].slots[si].attach = 0
                groups[5].slots[si].prot   = getProtection(sec)
            end
        end
    end

    return {
        groups   = groups,
        player   = playerObj,
        isFemale = playerObj:isFemale(),
    }
end

-- ============================================================================
-- DEFENSE DASHBOARD — the protection overview that took the Protection tab's
-- place: body figure + aggregate stats at the foot of this tab.
-- ProtectionTab.lua still computes the data and colours; headers and rows
-- come from the molecules every tab shares.
-- ============================================================================

local function _ensureDefBodyFigure(win)
    local T = ZeD.T
    if not win._equipDefBodyFigure then
        local fig = ZeD_BodyFigure:new(0, 0, T.px(100), T.px(100))
        fig:initialise()
        fig:loadTextures()
        win._equipDefBodyFigure = fig
    end
    return win._equipDefBodyFigure
end

local function _drawDefenseFigure(panel, win, protData, px, py, pw, ph)
    local fig = _ensureDefBodyFigure(win)
    if protData.isFemale ~= nil then
        fig:setSex(protData.isFemale)
    end
    fig:clearColors()
    local ALL_PARTS    = ZeD.ProtectionTab.ALL_PARTS
    local PART_TO_FIG  = ZeD.ProtectionTab.PART_TO_FIGURE
    local colorForDef  = ZeD.ProtectionTab.protectionColorForDef
    for _, partStr in ipairs(ALL_PARTS) do
        local def       = protData.partDefense[partStr] or -1
        local color     = colorForDef(def)
        local figureName = PART_TO_FIG[partStr]
        if figureName then
            fig:setPartColor(figureName, color.r, color.g, color.b, 0.65)
        end
    end
    fig.selectedPart = win._equipDefHoveredPart or nil
    fig:drawAt(panel, px, py, pw, ph)
end

local function _measureDefenseDashboard(win, protData, w)
    local T    = ZeD.T
    local headerH = ZeD.Molecules.getTabHeaderH()
    -- The defense body always shows (no disclosure of its own); the pinned
    -- header toggles the equipped INVENTORY list instead.
    local pad    = ZeD.Molecules.getTabPad()
    local figH = T.sp.figureH
    local rightColH = ZeD.ProtectionTab._measureRightColumn(protData)
    -- no top padding here: render puts figureGap above the body instead
    local contentH = math.max(figH, rightColH) + pad
    return headerH + contentH
end

-- Hover detail view: shows per-part defense stats (like Thermal tab rollover)
local function _drawDefenseDetailView(panel, win, protData, partName, rx, ry, rw)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local M    = ZeD.Molecules
    local tierColor = ZeD.ProtectionTab.tierColor

    -- Resolve figure display name → PZ part key
    local FIGURE_TO_PART = ZeD.ProtectionTab.FIGURE_TO_PART
    local partStr = FIGURE_TO_PART[partName]
    if not partStr then return end

    local ps = protData.partStats[partStr]
    if not ps then return end

    local curY = ry

    -- Defense stat rows with fill bars
    local rowGap = T.sp.sm
    local rows = {
        { label = getText("IGUI_health_Bite"),    val = ps.bite },
        { label = getText("IGUI_health_Scratch"), val = ps.scratch },
        { label = getText("IGUI_health_Bullet"),  val = ps.bullet },
    }

    for _, row in ipairs(rows) do
        local val = math.max(0, row.val)
        local pct = val / 100
        local fc  = tierColor(val)
        local valStr = val .. "%"
        local rowH = M.drawStatBarRow(panel, rx, curY, rw, valStr, row.label, pct, fc)
        curY = curY + rowH + rowGap
    end

    -- Layers count
    curY = curY + T.sp.sm
    local layerStr = (ps.layers == 1) and ZeD.tr("UI_ZeD_Equip_LayerOne", ps.layers) or ZeD.tr("UI_ZeD_Equip_LayerMany", ps.layers)
    A.drawSecondary(panel, layerStr, rx, curY)
end

-- Stacked stat helper with status dot: label (secondary) on line 1, dot + value (body, neutral) on line 2
local function _drawStackedStatDot(panel, x, y, label, value, dotColor, dotSz, dotGap)
    local T = ZeD.T
    local A = ZeD.Atoms
    local secH  = ZeD.TM:getFontHeight(T.fontF1)
    local bodyH = ZeD.TM:getFontHeight(T.fontF2)
    local labelValueGap = T.sp.xs
    local afterGap      = T.sp.sm

    panel:drawText(ZeD.textCase(label), x, y, T.toneLo.r, T.toneLo.g, T.toneLo.b, T.toneLo.a, T.fontF1)
    local valY = y + secH + labelValueGap
    A.drawStatusDot(panel, x, valY + math.floor((bodyH - dotSz) / 2), dotColor, dotSz)
    A.drawBody(panel, value, x + dotSz + dotGap, valY)

    return secH + labelValueGap + bodyH + afterGap
end

local function _drawDefenseDashboard(panel, win, protData, x, y, w, bodyOnly)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local M  = ZeD.Molecules
    local tierColor  = ZeD.ProtectionTab.tierColor
    local gradeColor = ZeD.ProtectionTab.gradeColor

    -- The defense body always shows. Nothing in ZeD calls this with
    -- bodyOnly=false any more; the header-drawing path stays for safety.
    local headerH = ZeD.Molecules.getTabHeaderH()

    local pad = ZeD.Molecules.getTabPad()
    if not bodyOnly then
        M.drawSectionHeader(panel, x, y, w, ZeD.tr("UI_ZeD_Equip_Defense"), nil, true, false, T.fontF4, nil, pad, headerH)
    end

    -- --- Dashboard content ---
    local secH  = ZeD.TM:getFontHeight(T.fontF1)

    local figW = T.sp.figureW
    local figH = T.sp.figureH
    local contentY = y + headerH
    local layout = ZeD.Molecules.layoutZoneA(x, contentY, w, figW, figH)

    -- Left column: body figure
    _drawDefenseFigure(panel, win, protData, layout.figX, layout.figY, figW, figH)

    -- Right column: hover detail OR default stats
    local rightX = layout.rightX
    local rightW = layout.rightW
    local hoveredPart = win._equipDefHoveredPart
    if hoveredPart and ZeD.ProtectionTab.FIGURE_TO_PART[hoveredPart] then
        _drawDefenseDetailView(panel, win, protData, hoveredPart,
            layout.rightX, layout.rightY, layout.rightW)
    else
        local statY = layout.rightY

        -- Letter grade box
        local gradeBoxColor = gradeColor(protData.grade)
        local titleFH = T.fontF4H or ZeD.TM:getFontHeight(T.fontF4)
        local gradeLetterW = ZeD.TM:MeasureStringX(T.fontF4, protData.grade)
        local boxH = secH * 2 + T.sp.xs + T.px(8)
        local boxW = math.max(gradeLetterW + T.px(12), boxH)
        local boxX = rightX
        local boxY = statY

        -- the grade in an outlined box (no tinted fill); its colour is the square mark before the label
        local bs = T.borderS
        A.borderRounded(panel, boxX, boxY, boxW, boxH, bs.r, bs.g, bs.b, bs.a or 1)

        local gx = boxX + math.floor((boxW - gradeLetterW) / 2)
        local gy = boxY + math.floor((boxH - titleFH) / 2)  -- the grade letter (F4) centred in the box
        panel:drawText(protData.grade, gx, gy, T.toneNorm.r, T.toneNorm.g, T.toneNorm.b, T.toneNorm.a, T.fontF4)

        local lblX = boxX + boxW + T.sp.sm
        local lblRoom = rightX + rightW - lblX
        local dotSz = T.px(6)
        local dotGap = T.px(4)
        A.drawStatusDot(panel, lblX, boxY + T.px(4) + math.floor((secH - dotSz) / 2), gradeBoxColor, dotSz)
        panel:drawText(A.truncateText(ZeD.textCase(ZeD.tr("UI_ZeD_Equip_OverallGrade")), T.fontF1, lblRoom - dotSz - dotGap), lblX + dotSz + dotGap, boxY + T.px(4), T.toneLo.r, T.toneLo.g, T.toneLo.b, T.toneLo.a, T.fontF1)
        local avgStr = ZeD.tr("UI_ZeD_Equip_AvgBite", protData.avgBiteDef .. "%")
        local avgY = boxY + T.px(4) + secH + T.sp.xs
        A.drawStatusDot(panel, lblX, avgY + math.floor((secH - dotSz) / 2), tierColor(protData.avgBiteDef), dotSz)
        -- the box has no room for a second line, so a long line ends in "..." at the column edge
        avgStr = A.truncateText(avgStr, T.fontF3, lblRoom - dotSz - dotGap)
        panel:drawText(avgStr, lblX + dotSz + dotGap, avgY, T.toneNorm.r, T.toneNorm.g, T.toneNorm.b, T.toneNorm.a, T.fontF3)

        statY = statY + boxH + T.sp.sm

        -- Divider below grade
        A.drawDividerH(panel, rightX, statY, rightW, false)
        statY = statY + T.px(1) + T.sp.afterLine

        -- Stacked stat rows (label on line 1, dot + value on line 2)
        local dotSz = T.px(6)
        local dotGap = T.px(4)
        local worstValue
        if protData.worstPart.biteDef < 0 then
            worstValue = ZeD.tr("UI_ZeD_Equip_ZoneUncovered", ZeD.partLabel(protData.worstPart.name))
        else
            worstValue = ZeD.tr("UI_ZeD_Equip_ZonePct", ZeD.partLabel(protData.worstPart.name), protData.worstPart.biteDef .. "%")
        end
        local h1 = _drawStackedStatDot(panel, rightX, statY, ZeD.tr("UI_ZeD_Equip_WorstZone"), worstValue, T.danger, dotSz, dotGap)
        statY = statY + h1

        if protData.bestPart.biteDef >= 0 then
            local bestStr = ZeD.tr("UI_ZeD_Equip_ZonePct", ZeD.partLabel(protData.bestPart.name), protData.bestPart.biteDef .. "%")
            local h2 = _drawStackedStatDot(panel, rightX, statY, ZeD.tr("UI_ZeD_Equip_BestZone"), bestStr, tierColor(protData.bestPart.biteDef), dotSz, dotGap)
            statY = statY + h2
        end

        local h3 = _drawStackedStatDot(panel, rightX, statY, ZeD.tr("UI_ZeD_Equip_Garments"), ZeD.tr("UI_ZeD_Equip_GarmentsEquipped", protData.totalGarments), T.positive, dotSz, dotGap)
        statY = statY + h3
    end

    local rightColH = ZeD.ProtectionTab._measureRightColumn(protData)
    local totalH = math.max(figH, rightColH) + pad * 2
    return headerH + totalH
end

-- ============================================================================
-- LIST MODE: draw group headers + slot rows
-- ============================================================================

-- A group's row ("v Hands (2)"): the library's category row, as the inventory's;
-- the pointer's hover wash and the controller's focus mark under its words
local _grpOpts = {}
local function _drawGroupHeader(panel, win, group, expanded, x, y, w)
    local T = ZeD.T
    local h = T.px(GROUP_H)
    local hovered = eqHover(panel, win, x, y, w, h)

    -- Count equipped items
    local count = 0
    for _, s in ipairs(group.slots) do
        if s.item then count = count + 1 end
    end

    local o = _grpOpts
    o.hover, o.h, o.inset = hovered, h, T.sp.sm + T.px(2)
    o.focus = eqFocus(win, "__group_" .. tostring(group.id))
    ZeD.Molecules.drawCategoryRow(panel, x, y, w, ZeD.EquipmentTab.wordsOf(group), count, expanded, o)
    if hovered then ZeD.Help.set(panel, ZeD.tr(expanded and "UI_ZeD_Inv_CatFoldHelp" or "UI_ZeD_Inv_CatOpenHelp")) end
end

local function _drawSlotRow(panel, slot, selected, x, y, w, rowIdx, win)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM
    local empty = not slot.item
    local rowH = T.rowH

    -- Alternating row stripe
    if rowIdx and rowIdx % 2 == 1 then
        local st = T.stripe
        panel:drawRect(x, y, w, rowH, st.a, st.r, st.g, st.b)
    end

    -- The row's states under its words: selected (the T.selectionA wash, the
    -- card is open on it), else the pointer's hover (a row with a thing in it:
    -- a press opens its card); a dragged row dimmed; then the controller's focus
    -- mark, which says when the words switch to T.textOnFocus.
    if selected then
        local ac = T.accent
        panel:drawRect(x, y, w, rowH, T.selectionA or 0.30, ac.r, ac.g, ac.b)
    elseif slot.item and eqHover(panel, win, x, y, w, rowH) then
        local hv = T.hover
        panel:drawRect(x, y, w, rowH, hv.a, hv.r, hv.g, hv.b)
        ZeD.Help.set(panel, ZeD.tr("UI_ZeD_Doll_SlotHelp", safeGet(slot.item, "getDisplayName") or "?"))
    end

    -- Being dragged: dimmed, as the inventory lists dim the rows they carry
    if slot.item and ZeD.EquipmentTab.draggedItem(win) == slot.item then
        local s1 = T.surf1
        panel:drawRect(x, y, w, rowH, 0.4, s1.r, s1.g, s1.b)
    end

    local fo = eqFocus(win, slot.type)
    local washed = fo and ZeD.Focus.mark(panel, x, y, w, rowH, fo) or false

    -- Column layout: NAME SLOT COND BITE SCR BUL WT
    local c = calcEquipColumns(w, win)

    local bodyFH = tm:getFontHeight(T.fontF2)
    local secFH = tm:getFontHeight(T.fontF1)
    local secTextY = y + math.floor((rowH - secFH) / 2)

    -- Icon
    local iconX = x + c.padX
    local iconY = y + math.floor((rowH - c.iconW) / 2)
    if slot.tex then
        panel:drawTextureScaledAspect(slot.tex, iconX, iconY, c.iconW, c.iconW, 1, 1, 1, 1)
    end

    -- Name
    local textY = y + math.floor((rowH - bodyFH) / 2)
    if empty then
        local dc = washed and T.textOnFocus or (T.textDim or T.textSec)
        panel:drawText("---", x + c.nameX, textY, dc.r, dc.g, dc.b, dc.a or 0.28, T.fontF2)
    else
        local name = safeGet(slot.item, "getDisplayName") or safeGet(slot.item, "getName") or "?"
        local nameColor = washed and T.textOnFocus or (selected and T.toneHi or T.text)
        name = A.truncateText(name, T.fontF2, c.nameW)
        panel:drawText(name, x + c.nameX, textY,
            nameColor.r, nameColor.g, nameColor.b, nameColor.a or 1, T.fontF2)
    end

    -- Slot label (truncated to fit column)
    -- (the short words when the column took them, or when the full ones do not fit it)
    local slotRoom = c.slotColW - c.slotPad * 2
    local typeStr = ZeD.EquipmentTab.wordsOf(slot)
    if c.slotShort or tm:MeasureStringX(T.fontF1, typeStr) > slotRoom then
        typeStr = ZeD.EquipmentTab.shortOf(slot)
    end
    local typeColor = washed and T.textOnFocus or T.toneHi
    typeStr = A.truncateText(typeStr, T.fontF1, slotRoom)
    panel:drawText(typeStr, x + c.slotX + c.slotPad, secTextY,
        typeColor.r, typeColor.g, typeColor.b, typeColor.a or 0.9, T.fontF1)

    -- Condition: the framed strip, as the inventory lists'
    if slot.item then
        local condMax = safeGet(slot.item, "getConditionMax") or 0
        if condMax and condMax > 0 then
            eqCondition(panel, x + c.condX + T.px(2), y + math.floor(rowH / 2), c.condColW - T.px(4), slot.cond)
        end
    end

    -- Protection columns (bite / scratch / bullet) — colored status dots
    if slot.item and slot.prot and c.protOn then
        local p = slot.prot
        local tierColor = ZeD.ProtectionTab.tierColor
        local dotSz = T.px(6)
        local dotY = y + math.floor((rowH - dotSz) / 2)
        local function drawProtDot(val, colX)
            if val > 0 then
                A.drawStatusDot(panel, x + colX + math.floor((c.protColW - dotSz) / 2), dotY, tierColor(val), dotSz)
            end
        end
        drawProtDot(p.bite, c.biteX)
        drawProtDot(p.scratch, c.scrX)
        drawProtDot(p.bullet, c.bulX)
    end

    -- Weight
    if slot.item and c.wtOn then
        local wt = safeGet(slot.item, "getUnequippedWeight") or 0
        local wtStr = string.format("%.1f", wt)
        A.drawTextRight(panel, wtStr, x + c.wtX + c.wtColW - c.wtPad, secTextY)
    end

    -- Bottom divider
    A.drawDividerH(panel, x, y + rowH - T.px(1), w, false)
end

-- ============================================================================
-- THE BELT (HOOK_MAP rows 5 + 6) — the hotbar's slots under HELD + BELT
-- A sub-header ("THE BELT | KEYS", "SLOT | WHAT GIVES IT"), then one row per
-- slot in key order: the key in an accent badge, the item's icon, its name
-- (or "Empty") over the slot's name and the worn item that gives the slot,
-- the condition bar in the COND column, then IN HAND and the verb (DETACH,
-- PUT BACK or ATTACH) at the right edge. Zones in win._equipBeltZones
-- (CharacterWindow routes clicks; ATTACH opens the slot's list, as holding
-- the slot's key does).
-- ============================================================================
-- the slots shown: all of them while HELD + BELT is open, the filled ones
-- while it is folded (as the group's own rows do)
local function _beltSlots(win, expanded)
    local B = ZeD.Belt
    if not (B and B.slots) then return {} end
    local ok, slots = pcall(B.slots, win.playerNum or 0)
    if not ok or not slots then return {} end
    if expanded then return slots end
    local out = {}
    for _, s in ipairs(slots) do if s.item then out[#out + 1] = s end end
    return out
end

-- two lines: the item over the slot
local function _beltRowH()
    local T, tm = ZeD.T, ZeD.TM
    return math.floor(math.max(T.rowH, tm:getFontHeight(T.fontF2) + tm:getFontHeight(T.fontF1) + T.px(8)))
end

-- the In hand tag: the library's tag (16u, outlined, F1, sentence case), as the
-- inventory lists' Belt n; its width first (it is laid out before it is drawn)
local function _beltTagW(text)
    local T = ZeD.T
    return ZeD.TM:MeasureStringX(T.fontF1, ZeD.Atoms.textCase(text)) + T.px(10)
end
local _beltTagOpts = {}
local function _beltTag(panel, text, x, y, ink)
    _beltTagOpts.textColor = ink
    return ZeD.Molecules.drawTag(panel, x, y, text, nil, _beltTagOpts)
end

local function _drawBeltRows(panel, win, slots, x, y, w, zones)
    local T, A, tm = ZeD.T, ZeD.Atoms, ZeD.TM
    local B = ZeD.Belt
    local c = calcEquipColumns(w, win)
    local DOT = " | "   -- the separator: ZeD's pipe, never a middle dot
    local f1, f2 = T.fontF1, T.fontF2
    local f1h, f2h = tm:getFontHeight(f1), tm:getFontHeight(f2)
    -- sub-header, in the category rows' height and type (sentence case), with no
    -- fill of its own: the window body is under it, one layer
    local hh = T.px(GROUP_H)
    local lo = T.toneLo
    local hy = y + math.floor((hh - f1h) / 2)
    -- the two heads keep to their own sides: short of room each is cut in its own share, the
    -- right one gets at most half (with Large text on a narrow card "The belt | keys"
    -- otherwise runs into "Slot | what gives it")
    local headL = ZeD.textCase(ZeD.tr("UI_ZeD_Equip_BeltHeadLeft"))
    local cap = ZeD.textCase(ZeD.tr("UI_ZeD_Equip_BeltHeadRight"))
    local hRoom = w - c.padX * 2 - T.px(2) - T.px(8)
    local lw, rw = tm:MeasureStringX(f1, headL), tm:MeasureStringX(f1, cap)
    if lw + rw > hRoom then
        rw = math.min(rw, math.max(math.floor(hRoom / 2), hRoom - lw))
        lw = hRoom - rw
        headL = A.truncateText(headL, f1, lw)
        cap = A.truncateText(cap, f1, rw)
    end
    panel:drawText(headL, x + c.padX + T.px(2), hy, lo.r, lo.g, lo.b, lo.a or 1, f1)
    panel:drawText(cap, x + w - c.padX - tm:MeasureStringX(f1, cap), hy, lo.r, lo.g, lo.b, lo.a or 1, f1)
    A.drawDividerH(panel, x, y + hh - T.px(1), w, false)
    y = y + hh

    local rowH = _beltRowH()
    local player = win._playerObj
    local keyW = math.max(tm:MeasureStringX(f1, "0") + T.px(8), f1h + T.px(4))
    local keyH = f1h + T.px(4)
    for ri, s in ipairs(slots) do
        if ri % 2 == 1 then local st = T.stripe; panel:drawRect(x, y, w, rowH, st.a, st.r, st.g, st.b) end
        local fid = "belt:" .. tostring(s.i)
        -- the pointer's hover wash, then the controller's focus mark (the row is one stop: A runs its verb)
        local rowHover = eqHover(panel, win, x, y, w, rowH)
        if rowHover then
            local hv = T.hover
            panel:drawRect(x, y, w, rowH, hv.a, hv.r, hv.g, hv.b)
        end
        local foB = eqFocus(win, fid)
        local washB = foB and ZeD.Focus.mark(panel, x, y, w, rowH, foB) or false
        -- the key (an outlined "-" past the eighth slot, which has none)
        local kx = x + c.padX
        local ky = y + math.floor((rowH - keyH) / 2)
        local kt = s.key or "-"
        local ktx = kx + math.floor((keyW - tm:MeasureStringX(f1, kt)) / 2)
        if s.key then
            local ac = T.accent
            panel:drawRect(kx, ky, keyW, keyH, ac.a or 1, ac.r, ac.g, ac.b)
            local tc = T.textOnAccent
            panel:drawText(kt, ktx, ky + T.px(2), tc.r, tc.g, tc.b, 1, f1)
        else
            local dc = T.textDim
            panel:drawRectBorder(kx, ky, keyW, keyH, dc.a or 1, dc.r, dc.g, dc.b)
            panel:drawText(kt, ktx, ky + T.px(2), dc.r, dc.g, dc.b, dc.a or 1, f1)
        end
        -- the icon
        local iconX = kx + keyW + T.px(6)
        local iconY = y + math.floor((rowH - c.iconW) / 2)
        if s.item then
            local tex = safeGet(s.item, "getTex")
            if tex then panel:drawTextureScaledAspect(tex, iconX, iconY, c.iconW, c.iconW, 1, 1, 1, 1) end
        end
        -- the verb at the right edge, IN HAND before it
        local action, label
        if s.item and s.inHand then action, label = "putback", ZeD.tr("UI_ZeD_Equip_PutBack")
        elseif s.item then action, label = "detach", ZeD.tr("UI_ZeD_Equip_Detach")
        else action, label = "attach", ZeD.tr("ContextMenu_Attach") end
        local inHandTxt = ZeD.tr("UI_ZeD_Equip_InHand")
        -- (a push button inside a list row: T.buttonH - 4u, the label measured as it draws)
        local bh = math.min(rowH - T.px(6), T.buttonH - T.px(4))
        local bw = ZeD.Molecules.buttonW(label)
        local bx = x + w - c.padX - bw
        local by = y + math.floor((rowH - bh) / 2)
        local rightEdge = bx
        if s.inHand then rightEdge = bx - T.px(6) - _beltTagW(inHandTxt) end
        -- the item over the slot and what gives it: the name stops at the
        -- COND column (its bar sits beside it), the slot line runs under both
        -- (the name stops before the verb too: with Large text the verb
        -- otherwise sat over the name)
        local tx = iconX + c.iconW + c.iconGap
        local textW = math.min(x + c.condX - T.px(6), rightEdge - T.px(8)) - tx
        local subW = rightEdge - T.px(8) - tx
        local ty = y + math.floor((rowH - f2h - f1h - T.px(2)) / 2)
        if s.item then
            local tc = washB and T.textOnFocus or T.text
            panel:drawText(A.truncateText(safeGet(s.item, "getDisplayName") or "?", f2, textW), tx, ty, tc.r, tc.g, tc.b, tc.a or 1, f2)
        else
            local dc = washB and T.textOnFocus or T.textDim
            panel:drawText(ZeD.tr("UI_ZeD_Equip_Empty"), tx, ty, dc.r, dc.g, dc.b, dc.a or 1, f2)
        end
        local prov = B.provider(player, s.slot.slotType)
        local from = prov and ZeD.tr("UI_ZeD_Equip_BeltFrom", safeGet(prov, "getDisplayName") or "") or ZeD.tr("UI_ZeD_Equip_BeltAlways")
        local sub = ZeD.textCase(B.slotName(s.slot)) .. DOT .. from
        local th = washB and T.textOnFocus or T.toneHi
        panel:drawText(A.truncateText(sub, f1, subW), tx, ty + f2h + T.px(2), th.r, th.g, th.b, th.a or 0.9, f1)
        -- condition, in the COND column level with the name: the framed strip
        -- (left out when the verb takes its room: the item's card still shows it)
        local f = s.item and (x + c.condX + c.condColW - T.px(2) <= rightEdge - T.px(6)) and B.cond(s.item)
        local condHov = f and eqCondition(panel, x + c.condX + T.px(2), ty + math.floor(f2h / 2), c.condColW - T.px(4), f)
        local btnHover = rowHover and A.mouseIn(panel, bx, by, bw, bh)
        if rowHover and not condHov then   -- (on the strip the help line keeps its condition)
            ZeD.Help.set(panel, ZeD.tr("UI_ZeD_Equip_BeltRowHelp", s.item and (safeGet(s.item, "getDisplayName") or "?") or ZeD.tr("UI_ZeD_Equip_Empty"), ZeD.btnCase(label)))
        end
        ZeD.Molecules.drawButton(panel, bx, by, bw, bh, label, action == "attach" and "primary" or "default", false, nil,
            { hover = btnHover, win = win })
        if s.inHand then
            _beltTag(panel, inHandTxt, bx - T.px(6) - _beltTagW(inHandTxt), y + math.floor((rowH - T.px(16)) / 2), washB and T.textOnFocus or nil)
        end
        zones[#zones + 1] = { x = x, y = y, w = w, h = rowH, i = s.i, item = s.item, action = action,
                              btn = { x = bx, y = by, w = bw, h = bh }, fid = fid }
        win._equipSlotYMap[fid] = y
        A.drawDividerH(panel, x, y + rowH - T.px(1), w, false)
        y = y + rowH
    end
    return y
end

--- Run a belt row's verb (mouse and controller).
function ZeD.EquipmentTab.beltAction(win, zone, absX, absY)
    local B = ZeD.Belt
    if not (B and zone) then return end
    local pn = win.playerNum or 0
    if zone.action == "detach" and zone.item then B.detach(pn, zone.item)
    elseif zone.action == "putback" then B.activate(pn, zone.i)
    elseif zone.action == "attach" then B.slotMenu(pn, zone.i, absX or getMouseX(), absY or getMouseY()) end
end

-- ============================================================================
-- COLUMN HEADER BAR — labels above the slot list
-- ============================================================================

local EQUIP_HDR_H = (ZeD.Spacing and ZeD.Spacing.colHdrH) or 20  -- design units: a copy of T.sp.colHdrH cached at load would miss a scale change; every use goes through T.px

local function _drawEquipHeader(panel, x, y, w, win)
    local T  = ZeD.T
    local A  = ZeD.Atoms
    local tm = ZeD.TM

    -- Background: the column heads' surface, claimed over the body (one layer)
    ZeD.Atoms.surfaceFill(panel, x, y, w, T.px(EQUIP_HDR_H), "surf2")

    -- Column layout (shared with _drawSlotRow)
    local cl = calcEquipColumns(w, win)

    local secFH = tm:getFontHeight(T.fontF5)
    local textY = y + math.floor((T.px(EQUIP_HDR_H) - secFH) / 2)
    local c = T.toneNorm

    -- Center helper
    local function drawCentered(label, colStart, colW)
        label = ZeD.Atoms.truncateText(label, T.fontF5, colW)   -- the game's column words can be long
        local tw = tm:MeasureStringX(T.fontF5, label)
        local tx = x + colStart + math.floor((colW - tw) / 2)
        panel:drawText(label, tx, textY, c.r, c.g, c.b, c.a or 0.92, T.fontF5)
    end

    -- Column order: NAME SLOT COND BITE SCR BUL WT
    panel:drawText(ZeD.tr("IGUI_Name"), x + cl.nameX, textY, c.r, c.g, c.b, c.a or 0.92, T.fontF5)
    drawCentered(ZeD.tr("UI_ZeD_Equip_ColSlot"), cl.slotX, cl.slotColW)
    drawCentered(ZeD.tr("UI_ZeD_Equip_ColCond"), cl.condX, cl.condColW)
    if cl.protOn then   -- (left out when the card is too narrow for them)
        drawCentered(ZeD.tr("IGUI_health_Bite"), cl.biteX, cl.protColW)
        drawCentered(ZeD.tr("UI_ZeD_Equip_ColScratch"), cl.scrX,  cl.protColW)
        drawCentered(ZeD.tr("UI_ZeD_Equip_ColBullet"), cl.bulX,  cl.protColW)
    end
    if cl.wtOn then
        A.drawTextRight(panel, ZeD.tr("UI_ZeD_Equip_ColWeight"), x + cl.wtX + cl.wtColW - cl.wtPad, textY, T.fontF5, c)
    end

    -- Divider hit zones for column resize (6px wide, centered on column edge)
    local divZones = {}
    divZones[#divZones + 1] = { col = "slot", x = x + cl.slotX - T.px(DIV_W) / 2, y = y, w = T.px(DIV_W), h = T.px(EQUIP_HDR_H) }
    divZones[#divZones + 1] = { col = "cond", x = x + cl.condX - T.px(DIV_W) / 2, y = y, w = T.px(DIV_W), h = T.px(EQUIP_HDR_H) }
    if cl.wtOn then
        divZones[#divZones + 1] = { col = "wt",   x = x + cl.wtX   - T.px(DIV_W) / 2, y = y, w = T.px(DIV_W), h = T.px(EQUIP_HDR_H) }
    end
    if win then win._equipDivZones = divZones end

    -- Divider hover feedback (2px accent line)
    local mx, my = panel:getMouseX(), panel:getMouseY()
    local colDrag = win and win._equipColDrag
    if not colDrag then
        for _, dz in ipairs(divZones) do
            if mx >= dz.x and mx < dz.x + dz.w and my >= dz.y and my < dz.y + dz.h then
                local ac = T.accent
                panel:drawRect(dz.x + T.px(DIV_W) / 2 - T.px(1), y, T.px(2), T.px(EQUIP_HDR_H), ac.a, ac.r, ac.g, ac.b)
                break
            end
        end
    end

    -- Active drag feedback (full-height accent line)
    if colDrag then
        local divX
        if colDrag.col == "slot" then divX = x + cl.slotX
        elseif colDrag.col == "cond" then divX = x + cl.condX
        else divX = x + cl.wtX end
        local ac = T.accent
        panel:drawRect(divX - T.px(1), y, T.px(2), panel:getHeight() - y, ac.a, ac.r, ac.g, ac.b)
    end

    A.drawDividerH(panel, x, y + T.px(EQUIP_HDR_H) - T.px(1), w, true)
end

-- ============================================================================
-- ACTION HANDLER
-- CharacterWindow routes a card-mode verb here (win._equipActionZones, and
-- the controller's A on an action element), named by actionId.
-- ============================================================================

--- Runs a card-mode verb ("unequip" / "drop") on the selected slot's item.
function ZeD.EquipmentTab._handleAction(win, actionId, slot)
    if not slot or not slot.item then return end
    local player = win._playerObj
    if not player then return end

    if actionId == "unequip" then
        -- The game's own unequip for clothing and hand items alike (ISUnequipAction, through
        -- ISInventoryPaneContextMenu.unequipItem: it also puts out a lit candle or lantern). Emptying
        -- the hand directly never reached a server: on a rejoin the item was back in the hand.
        ISInventoryPaneContextMenu.unequipItem(slot.item, player:getPlayerNum())
        win._equipSelected = nil
        win._equipCache = nil

    elseif actionId == "drop" then
        -- Vanilla drop handles unequip + transfer to ground
        -- dropItem expects playerNum (integer), not playerObj
        local pNum = player:getPlayerNum()
        ISInventoryPaneContextMenu.dropItem(slot.item, pNum)
        win._equipSelected = nil
        win._equipCache = nil

    end
end

-- ============================================================================
-- DRAG SOURCE
-- A press on a worn or held item (a list row, or a doll slot) waits. Released
-- without moving it is the click it always was (the item card). Moved off the
-- slot it becomes the inventory lists' own drag: the same DragState molecule
-- (ghost, the belt's drop cue, the curtain tab) and the same drop handler
-- (InventoryRenderer.handleDrop: the container columns, the World window, a
-- rolled tab, the belt, the floor). Nothing here unequips: handleDrop queues
-- vanilla's transfer (ISTransferAction takes the item off) or vanilla's drop
-- (ISInventoryPaneContextMenu.dropItem), so a refusing action refuses as in
-- vanilla. The drawer owns the mouse (it captures it, as the column dividers
-- do); the drag state lives on the window (win._equipDrag).
-- ============================================================================

local function equipDrag(win)
    local d = win._equipDrag
    if not d then
        d = ZeD.Molecules.DragState:new()
        win._equipDrag = d
    end
    return d
end

-- The filled slot under (x, y), drawer-local: a list row, or a doll slot
local function slotZoneAt(win, x, y)
    for _, zone in ipairs(win._equipSlotZones or {}) do
        if zone.item
           and x >= zone.x and x <= zone.x + zone.w
           and y >= zone.y and y <= zone.y + zone.h then
            return zone
        end
    end
    return nil
end

-- The click: the slot's item card
local function selectSlot(win, slotType)
    win._equipSelected = slotType
    win._equipCache = nil              -- force fresh data for the card
    win._gpFocusedEquipSlot = nil      -- reseed to the back button
end

--- The item being dragged (a drag that has started), for the dim on its slot.
function ZeD.EquipmentTab.draggedItem(win)
    local d = win and win._equipDrag
    if d and d:isActive() and d.items then return d.items[1] end
    return nil
end

--- True while the drag is pending or running (the drawer then owns the mouse).
function ZeD.EquipmentTab.dragBusy(win)
    local d = win and win._equipDrag
    return d ~= nil and (d:isActive() or d:isPending())
end

--- Mouse down on the drawer, list mode or doll: true when a filled slot took the press.
function ZeD.EquipmentTab.pressSlot(win, panel, x, y)
    if win._equipSelected then return false end
    local zone = slotZoneAt(win, x, y)
    if not zone then return false end
    local d = equipDrag(win)
    d:cancel()
    win._equipPress = zone
    d:beginPending({ zone.item }, zone.item, getMouseX(), getMouseY())
    return true
end

--- Mouse move on the drawer: past the threshold the press becomes a drag. True while it is the drag's.
function ZeD.EquipmentTab.dragMove(win, panel)
    local d = win._equipDrag
    if not d then return false end
    if d:isPending() then
        -- the button came up where this drawer never heard it (a release the engine
        -- did not route here): the press is over, never a drag
        if isMouseButtonDown and not isMouseButtonDown(0) then
            d:cancel()
            win._equipPress = nil
            return false
        end
        if d:checkThreshold(getMouseX(), getMouseY()) then
            win._equipPress = nil
            panel:setCapture(true)
        end
        return true
    elseif d:isActive() then
        d:updateGhostPos(getMouseX(), getMouseY())
        return true
    end
    return false
end

-- Where a release lands. Back on the Equip tab (the drawer) is nothing; the
-- rest is the inventory's own handleDrop, with the item's container as the
-- source (so its own column, or the same bag, is no move).
local function dropEquipped(win, panel, items)
    local item = items and items[1]
    local content = win._contentPanel
    if not (item and content) then return end
    local mx, my = getMouseX(), getMouseY()
    local ax, ay = panel:getAbsoluteX(), panel:getAbsoluteY()
    if mx >= ax and mx < ax + panel:getWidth() and my >= ay and my < ay + panel:getHeight() then return end
    local src = item:getContainer()
    if not src then return end
    ZeD.InventoryRenderer.handleDrop(content, items, src)
end

--- Mouse up on the drawer (or outside it): the drop, or the plain click. True when it was the press's.
function ZeD.EquipmentTab.dragRelease(win, panel)
    local d = win._equipDrag
    if not d then return false end
    if d:isActive() then
        local items = d:complete()
        panel:setCapture(false)
        win._equipPress = nil
        dropEquipped(win, panel, items)
        win._equipCache = nil
        return true
    end
    if d:isPending() then
        d:cancel()
        local zone = win._equipPress
        win._equipPress = nil
        if zone then selectSlot(win, zone.type) end
        return true
    end
    return false
end

--- Right button during a drag (or a press): the drag is called off, nothing is selected.
function ZeD.EquipmentTab.dragCancel(win, panel)
    local d = win._equipDrag
    if not (d and (d:isActive() or d:isPending())) then return false end
    local wasActive = d:isActive()
    d:cancel()
    win._equipPress = nil
    if wasActive then panel:setCapture(false) end
    return true
end

-- ============================================================================
-- RENDERER
-- ============================================================================

--- The tab's frame: card mode (a ZeD_ItemCard child), the doll view, or the
--- grouped list with the belt rows, the loadouts' fold and the defense body.
function ZeD.EquipmentTab.render(panel, win, x, y, w, h)
    local T   = ZeD.T
    win._equipPanel = panel   -- (the drawer its zones are stamped in: a drop reads the pointer there, EquipDoll.takeDrop)

    -- Throttled data refresh (every 250 ms on the clock: 15 frames at 60 FPS)
    if dueMs(win, "_equipAt", 250, not win._equipCache) then
        win._equipCache = ZeD.EquipmentTab.gatherData(win._playerObj)
    end
    local data = win._equipCache

    -- Ensure state tables
    win._equipExpanded   = win._equipExpanded or {head = false, torso = false, arms = false, legs = false, held = false}
    win._equipGroupZones = win._equipGroupZones or {}
    win._equipSlotZones  = win._equipSlotZones or {}

    -- ================================================================
    -- CARD MODE — selected slot inspection
    -- ================================================================
    -- a new selection starts at its outermost layer
    if win._equipSelected ~= win._equipSelPrev then
        win._equipSelPrev = win._equipSelected
        win._equipLayer = 1
    end
    win._equipLayerZones = nil
    win._equipDollEmpty = nil
    win._equipDollShown = false   -- the doll's model + line layer follow this (CharacterWindow)
    win._equipViewZones = nil
    -- The loadouts' bar and to-do (ZeD_EquipLoadout.lua): the to-do opens where the card opens
    local EL = ZeD.EquipLoadout
    if EL then EL.beginFrame(win) end
    if EL and EL.todoOpen(win) then
        if panel._equipCard then panel._equipCard:setVisible(false) end
        win._equipSelected = nil
        win._equipSlotZones, win._equipBeltZones, win._equipGroupZones = {}, {}, {}
        win._equipDefenseZone = nil
        if win._equipScroll then win._equipScroll.visible = false end
        EL.renderTodo(panel, win, x, y, w, h)
        return
    end
    if win._equipSelected then
        -- Find the selected slot data: a doll slot (its layers), or a list row
        local selSlot = nil
        local layerIdx, layerN = 1, 1
        local Doll = ZeD.EquipDoll
        if Doll.isDollKey(win._equipSelected) then
            local item
            item, layerIdx, layerN = Doll.selection(win)
            if item then selSlot = { item = item } end
        else
            for _, g in ipairs(data.groups) do
                for _, s in ipairs(g.slots) do
                    if s.type == win._equipSelected then
                        selSlot = s
                        break
                    end
                end
                if selSlot then break end
            end
        end

        -- If selected item was unequipped externally, revert to list mode
        if not selSlot or not selSlot.item then
            win._equipSelected = nil
        else
            -- Card mode delegates to a ZeD_ItemCard child — the same organism
            -- the inventory drawer uses. The tab keeps its own card instance
            -- apart from win._itemCard since the two render at different
            -- surfaces. The back arrow clears _equipSelected.
            local card = panel._equipCard
            if not card then
                card = ZeD_ItemCard:new(x, y, w, h, "drawer", win.playerNum or 0)
                card:initialise()
                panel:addChild(card)
                panel._equipCard = card
                card.onBackClick = function(self)
                    win._equipSelected = nil
                end
                card._gpZone = "charTabContent"   -- its controller cue shows when the tab's zone has focus
            end
            -- A doll slot with layers: the layer strip under the card
            local cardH = h
            if (layerN or 1) > 1 then
                cardH = h - Doll.layerStripH()
                Doll.drawLayerStrip(panel, win, x, y + cardH, w, layerIdx, layerN, panel:getMouseX(), panel:getMouseY())
            end
            -- Per-frame sync: bounds, item, source context
            card:setX(x)
            card:setY(y)
            card:setWidth(w)
            card:setHeight(cardH)
            card._fillH = (cardH ~= h) and cardH or nil
            if card.item ~= selSlot.item then card:setItem(selSlot.item) end
            card.sourceContext = "equipped"
            card:setVisible(true)
            -- The card draws itself through the ISPanel child lifecycle after
            -- this function returns; its back bar, content and scrollbar are
            -- its own, so card mode draws nothing else here.
            return
        end
    end

    -- Hide the equip card when not in card mode (so it doesn't ghost-render
    -- over list mode). Lazy hide — instance lives across mode swaps.
    if panel._equipCard then panel._equipCard:setVisible(false) end

    -- ================================================================
    -- LIST MODE — grouped slot list
    -- ================================================================
    local scroll = win._equipScroll

    -- Throttled protection data refresh (every 250 ms on the clock: 15 frames at 60 FPS)
    if dueMs(win, "_equipProtAt", 250, not win._equipProtCache) then
        win._equipProtCache = ZeD.ProtectionTab.gatherData(win._playerObj)
    end
    local protData = win._equipProtCache

    -- Ensure list-expanded state — pinned "Equipped" header toggles slot
    -- list visibility; defense body is always shown at the bottom.
    if win._equipListExpanded == nil then win._equipListExpanded = true end

    -- Pinned header: standard ZeD drawer-header strip (T.sp.tabHeaderH).
    -- Column headers (20px) always in scroll area
    local headerH = T.sp.tabHeaderH or T.px(37)
    local listExpanded = win._equipListExpanded
    -- the loadouts: a fold under the doll and the lists, shut until opened, in both views
    -- (ZeD_EquipLoadout.lua). It is measured and drawn at the doll's width, so its rows
    -- do not change with the scrollbar.
    local loW = w - T.sp.scrollbarW
    local loH = EL and EL.sectionH(win, loW) or 0

    -- Measure scrollable content
    local defDashH = _measureDefenseDashboard(win, protData, w)
    -- Defense body always visible; subtract the molecule's headerH that
    -- _measureDefenseDashboard reserves for its own pinned header (we're
    -- not using a pinned header for defense any more).
    local defBodyH = math.max(0, defDashH - headerH)
    local slotRowH = T.rowH
    local groupHeaderH_pre = T.px(GROUP_H)
    local hasDefBody = defBodyH > 0
    -- Layout: equipped inventory list first (collapsible), defense body below
    -- (always visible). T.sp.figurePadTop is the canonical gap above body
    -- figures across Health/Protection/Thermal — using it here keeps spacing
    -- consistent with the rest of the mod.
    local figureGap = T.sp.figurePadTop or T.px(12)
    local totalH = 0
    local Doll = ZeD.EquipDoll
    local dollView = listExpanded and Doll.view() == "doll"
    -- the doll fits the viewport before any scrollbar; measured from last frame's data
    local dollH = 0
    if dollView then
        if not win._equipDollData then win._equipDollData = Doll.gather(win._playerObj, win.playerNum or 0) end
        dollH = Doll.measure(win, w - T.sp.scrollbarW, h - headerH)
        totalH = totalH + dollH
    elseif listExpanded then
        totalH = totalH + T.px(EQUIP_HDR_H)
        for gi, g in ipairs(data.groups) do
            totalH = totalH + groupHeaderH_pre
            if g.id == "held" then totalH = totalH + groupHeaderH_pre + #_beltSlots(win, win._equipExpanded[g.id]) * _beltRowH() end
            if win._equipExpanded[g.id] then
                totalH = totalH + #g.slots * slotRowH
            else
                for _, s in ipairs(g.slots) do
                    if s.item then totalH = totalH + slotRowH end
                end
            end
        end
    end
    totalH = totalH + loH
    if hasDefBody then
        if listExpanded then totalH = totalH + figureGap end
        totalH = totalH + defBodyH
    end

    -- Scroll setup — scrollbar starts below pinned header
    local scrollY = y + headerH
    local scrollH = h - headerH
    local needsScroll = totalH > scrollH
    scroll.visible = needsScroll
    local scrollW = T.sp.scrollbarW
    local contentW = needsScroll and (w - scrollW) or w
    if needsScroll then
        scroll.x = x + w - scrollW
        scroll.y = scrollY
        scroll.height = scrollH
        scroll:setBarSize(scrollH / math.max(1, totalH))
    else
        scroll:setScrollPos(0)
    end

    -- Gamepad scroll-follow — ensure the currently focused equip slot is
    -- within the viewport before computing scrollOff. Reads last frame's
    -- stamped absolute Y from _equipSlotYMap (populated inside the slot loop
    -- below). One-frame lag is imperceptible; matches InventoryRenderer's
    -- pattern. Disclosure is in the pinned header (always visible), so skip.
    if needsScroll
       and win._gpFocusedEquipSlot
       and win._gpFocusedEquipSlot ~= "__disclosure" then
        local yMap = win._equipSlotYMap
        local focAbsY = yMap and yMap[win._gpFocusedEquipSlot]
        if focAbsY then
            local span   = math.max(1, totalH - scrollH)
            local oldOff = math.floor(scroll.scrollPos * span)
            local logicalY = focAbsY - scrollY + oldOff
            if logicalY < oldOff then
                scroll:setScrollPos(logicalY / span)
            elseif logicalY + T.rowH > oldOff + scrollH then
                scroll:setScrollPos((logicalY + T.rowH - scrollH) / span)
            end
        end
    end
    -- Fresh map for this frame's stamps (cleared each frame so stale rows don't linger)
    win._equipSlotYMap = {}

    local scrollOff = 0
    if needsScroll then
        scrollOff = math.floor(scroll.scrollPos * math.max(0, totalH - scrollH))
    end

    -- Scrollable content (stencil below pinned header)
    panel:setStencilRect(x, scrollY, contentW, scrollH)
    -- (the rows' hover is tested inside this view only: eqHover)
    win._equipRowClip = win._equipRowClip or {}
    win._equipRowClip.y0, win._equipRowClip.y1 = scrollY, scrollY + scrollH
    local drawY = scrollY - scrollOff

    -- Zone arrays — reset indices
    local gzi = 0
    local szi = 0
    local beltZones = {}

    if dollView then
        -- the doll in place of the list (EquipDoll.lua); it stamps the slot,
        -- belt and photo zones itself
        win._equipGroupZones = {}
        local dh = Doll.draw(panel, win, x, drawY, w - T.sp.scrollbarW, h - headerH, panel:getMouseX(), panel:getMouseY())
        szi = #win._equipSlotZones
        beltZones = win._equipBeltZones or {}
        win._equipDollShown = true
        win._equipDollClip = { x = x, y = scrollY, w = contentW, h = scrollH }
        win._equipDollPanel = panel
        drawY = drawY + dh
    elseif listExpanded then
        -- Column headers FIRST — equipped inventory list is the most-accessed
        -- region of this drawer.
        -- the widest worn name: the SLOT column shortens when the names lack it
        local need = 0
        for _, g in ipairs(data.groups) do
            for _, s in ipairs(g.slots) do
                if s.item then
                    local nw = nameWidth(safeGet(s.item, "getDisplayName") or "?")
                    if nw > need then need = nw end
                end
            end
        end
        win._equipNameNeed = need
        _drawEquipHeader(panel, x, drawY, contentW, win)
        drawY = drawY + T.px(EQUIP_HDR_H)

        for gi, g in ipairs(data.groups) do
            local expanded = win._equipExpanded[g.id]
            -- Group header
            _drawGroupHeader(panel, win, g, expanded, x, drawY, contentW)

            -- Store group zone + stamp Y for scroll-follow (keyed by group focus id)
            gzi = gzi + 1
            win._equipGroupZones[gzi] = { x = x, y = drawY, w = contentW, h = T.px(GROUP_H), id = g.id }
            win._equipSlotYMap["__group_" .. tostring(g.id)] = drawY
            drawY = drawY + T.px(GROUP_H)

            -- Slot rows:
            -- Expanded: show all slots
            -- Collapsed: show only slots with equipped items (hide empty)
            for si, s in ipairs(g.slots) do
                local showSlot = expanded or (s.item ~= nil)
                if showSlot then
                    local isSelected = win._equipSelected == s.type
                    _drawSlotRow(panel, s, isSelected, x, drawY, contentW, si, win)

                    -- Store slot zone + stamp Y for gamepad scroll-follow (only if item present)
                    if s.item then
                        szi = szi + 1
                        win._equipSlotZones[szi] = { x = x, y = drawY, w = contentW, h = T.rowH, type = s.type, item = s.item }
                        win._equipSlotYMap[s.type] = drawY
                    end
                    drawY = drawY + T.rowH
                end
            end
            if g.id == "held" then
                drawY = _drawBeltRows(panel, win, _beltSlots(win, expanded), x, drawY, contentW, beltZones)
            end
        end
    end
    win._equipBeltZones = beltZones

    -- the loadouts' fold, under the doll and the lists
    if EL and loH > 0 then
        drawY = drawY + EL.drawSection(panel, win, x, drawY, loW, { x = x, y = scrollY, w = contentW, h = scrollH })
    end

    -- Defense body (figure + stats) — always shown at the bottom of the tab,
    -- regardless of inventory list expansion. figureGap (T.sp.figurePadTop,
    -- the canonical figure-top padding) sits between the list and the body.
    if hasDefBody then
        if listExpanded then drawY = drawY + figureGap end
        _drawDefenseDashboard(panel, win, protData, x, drawY - headerH, contentW, true)
        -- Gamepad: stamp body figure part Y values into yMap so scroll-follow
        -- can bring focused parts into viewport. drawAt sets the figure's
        -- internal drawAtS/X/Y, so getPartRects returns correct
        -- screen-relative coords here.
        local fig = win._equipDefBodyFigure
        if fig and fig.getPartRects then
            for _, r in ipairs(fig:getPartRects()) do
                win._equipSlotYMap["__part_" .. tostring(r.name)] = r.y
            end
        end
        drawY = drawY + defBodyH
    end

    -- Trim excess zones
    for i = gzi + 1, #win._equipGroupZones do win._equipGroupZones[i] = nil end
    for i = szi + 1, #win._equipSlotZones  do win._equipSlotZones[i]  = nil end

    panel:clearStencilRect()

    -- Pinned header — "Equipped"; it toggles the inventory list's visibility
    -- (the defense body always shows at the bottom of the tab). The pointer's
    -- hover wash and the controller's focus mark are the header's own
    -- (drawTabHeader), under its words.
    do
        local hdrHover = ZeD.Atoms.mouseIn(panel, x, y, w, headerH)
        ZeD.Molecules.drawTabHeader(panel, x, y, w, ZeD.tr("UI_ZeD_Equip_Equipped"), listExpanded, hdrHover, nil,
            { focus = eqFocus(win, "__disclosure") })
        if hdrHover then ZeD.Help.set(panel, ZeD.tr(listExpanded and "UI_ZeD_Inv_CatFoldHelp" or "UI_ZeD_Inv_CatOpenHelp")) end
    end
    -- List | Doll, at the heading's right edge
    Doll.drawToggle(panel, win, x, y, w, headerH, panel:getMouseX(), panel:getMouseY())
    -- The old field name stays (_equipDefenseZone): CharacterWindow's click
    -- and pad routing read it. It points at the "Equipped" disclosure; the
    -- zone works as it always did.
    win._equipDefenseZone = { x = x, y = y, w = w, h = headerH }

    if scroll.visible then
        scroll:draw(panel)
    end
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

-- Expose helpers for ZeD_CharacterWindow column drag
ZeD.EquipmentTab.getDefaultColWidths = getDefaultColWidths
ZeD.EquipmentTab.getLabelColW = getLabelColW

--- Hooks "equip" into the drawer's dispatch table (CharacterWindow calls it once).
function ZeD.EquipmentTab.register(dispatchTable)
    -- looked up at draw time, so a hot reload of this file takes effect
    dispatchTable["equip"] = function(...) return ZeD.EquipmentTab.render(...) end
end
