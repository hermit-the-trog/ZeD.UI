-- ZeD-UI/42/media/lua/client/ZeD/ItemCardOrganism.lua
-- ============================================================================
-- ITEM CARD ORGANISM (S121 - Phase 5)
-- Assembles the Phase 1-4 atoms / molecules / facts panels into a complete
-- universal item card per locked S119 mockups v13/v15/v16.
--
-- Organism contract:
--   ZeD_ItemCard:renderBody({sourceContext, marks?})
--     sourceContext = "equipped" | "inventory" | "container" | "ground"
--     marks         = optional precomputed {fav, nocraft, dispose} from item modData
--
-- It branches on width and source context - NEVER on item class.
-- Item-type dispatch goes through ZeD.ItemFactsPanel.factsFor(item).
--
-- Loads alphabetically after ItemCard.lua (defines ZeD_ItemCard class) and
-- before ItemFactsPanel.lua (whose registry we query at runtime, not load time).
-- ============================================================================

require "ZeD/Tr"
ZeD = ZeD or {}
ZeD.ItemCard = ZeD.ItemCard or {}

-- The words on the card's verb buttons. A verb keeps its English id (the card
-- dispatches on it); the button shows the id's translation. Vanilla's own words where
-- vanilla has them.
ZeD.ItemCard.VERB_KEYS = {
    EQUIP = "UI_ZeD_Card_VerbEquip", UNEQUIP = "ContextMenu_Unequip", DROP = "ContextMenu_Drop",
    TAKE = "ContextMenu_Take", EAT = "ContextMenu_Eat", READ = "ContextMenu_Read",
    USE = "UI_ZeD_Card_VerbUse", DRINK = "ContextMenu_Drink", WEAR = "ContextMenu_Wear",
    ["OFF HAND"] = "UI_ZeD_Card_VerbOffHand", MORE = "ContextMenu_More",
    WASH = "ContextMenu_Wash", REPAIR = "ContextMenu_Repair",
    PAD = "UI_ZeD_Card_VerbPad", SHARPEN = "UI_ZeD_Card_VerbSharpen",
}
function ZeD.ItemCard.verbText(id)
    local k = ZeD.ItemCard.VERB_KEYS[id]
    if k then return ZeD.tr(k) end
    return id
end

-- The widest of the short zone words (Left, Right, Upper, Lower) in the player's
-- language, so the name column of a zone row fits them.
function ZeD.ItemCard.sideW(font)
    local tm = ZeD.TM
    local w = 0
    for _, k in ipairs({ "UI_ZeD_Card_ZoneLeft", "UI_ZeD_Card_ZoneRight", "UI_ZeD_Card_ZoneUpper", "UI_ZeD_Card_ZoneLower" }) do
        local m = tm:MeasureStringX(font, ZeD.tr(k))
        if m > w then w = m end
    end
    return w
end

-- ---------------------------------------------------------------------------
-- Internal helpers (module-scope; not exported)
-- ---------------------------------------------------------------------------

local function safeGet(item, m, ...)
    if not item then return nil end
    local fn = item[m]; if not fn then return nil end
    local ok, r = pcall(fn, item, ...); if ok then return r end; return nil
end

-- Width preset: <320 → compact 220w; ≥320 → 480w.
-- Returns (compact:bool, presetName:"220"|"480") for downstream branches.
local function widthPreset(w)
    local T = ZeD.T
    if w < T.px(320) then return true, "220" end
    return false, "480"
end

-- Resolve the active value-class string from a numeric ratio in [0..1].
-- Mirrors v13 mockup color ramp: <0.30 = bad (red), <0.60 = warn (amber),
-- ≥0.60 = positive (green). Used for the cond-dot on CONDITION rows.
local function ratioClass(r)
    if not r or r <= 0 then return "dim" end
    if r < 0.30 then return "bad"  end
    if r < 0.60 then return "warn" end
    if r < 0.85 then return nil    end
    return "good"
end

local function ratioColor(r)
    local T = ZeD.T
    local cls = ratioClass(r)
    if cls == "bad"  then return T.danger end
    if cls == "warn" then return T.warning end
    if cls == "good" then return T.positive end
    if cls == "dim"  then return T.textDim end
    return T.text
end

-- v15 anatomical zone grouping. Each entry maps the full zone name (as
-- produced by ItemCard.lua's ZONE_DISPLAY_NAMES) to its mockup group + the
-- short within-group child name. v15 mockup groups consecutive same-group
-- zones under an orange-mono section header (TORSO, UPPER ARM, ...) with the
-- child name reduced to "Upper"/"Lower"/"Left"/"Right".
-- Both entries are translation keys (the group heading, the child word); the group key
-- is also the identity that tells where one group ends and the next begins.
local ZONE_GROUP_MAP = {
    ["Upper Torso"]     = {"UI_ZeD_Card_ZoneTorso",    "UI_ZeD_Card_ZoneUpper"},
    ["Lower Torso"]     = {"UI_ZeD_Card_ZoneTorso",    "UI_ZeD_Card_ZoneLower"},
    ["Back"]            = {"UI_ZeD_Card_ZoneTorso",    "IGUI_health_Back"},
    ["Head"]            = {"IGUI_health_Head",     "IGUI_health_Head"},
    ["Neck"]            = {"IGUI_health_Head",     "IGUI_health_Neck"},
    ["Groin"]           = {"IGUI_health_Groin",    "IGUI_health_Groin"},
    ["Left Upper Arm"]  = {"UI_ZeD_Card_ZoneUpperArm", "UI_ZeD_Card_ZoneLeft"},
    ["Right Upper Arm"] = {"UI_ZeD_Card_ZoneUpperArm", "UI_ZeD_Card_ZoneRight"},
    ["Left Forearm"]    = {"UI_ZeD_Card_ZoneLowerArm", "UI_ZeD_Card_ZoneLeft"},
    ["Right Forearm"]   = {"UI_ZeD_Card_ZoneLowerArm", "UI_ZeD_Card_ZoneRight"},
    ["Left Thigh"]      = {"UI_ZeD_Card_ZoneThigh",    "UI_ZeD_Card_ZoneLeft"},
    ["Right Thigh"]     = {"UI_ZeD_Card_ZoneThigh",    "UI_ZeD_Card_ZoneRight"},
    ["Left Shin"]       = {"UI_ZeD_Card_ZoneShin",     "UI_ZeD_Card_ZoneLeft"},
    ["Right Shin"]      = {"UI_ZeD_Card_ZoneShin",     "UI_ZeD_Card_ZoneRight"},
    ["Left Foot"]       = {"UI_ZeD_Card_ZoneFoot",     "UI_ZeD_Card_ZoneLeft"},
    ["Right Foot"]      = {"UI_ZeD_Card_ZoneFoot",     "UI_ZeD_Card_ZoneRight"},
    ["Left Hand"]       = {"UI_ZeD_Card_ZoneHand",     "UI_ZeD_Card_ZoneLeft"},
    ["Right Hand"]      = {"UI_ZeD_Card_ZoneHand",     "UI_ZeD_Card_ZoneRight"},
}

-- v15 220w short labels for Facts rows: a row may carry a `short` label (translated by
-- ItemFactsPanel). Long labels overflow the narrow card, so the short one is used at
-- compact widths only - 480w keeps the full labels per spec.

-- Resolve a zone's seg-bar segment color per v15 spec - patch material
-- overrides condition for the visual; otherwise color ramps with condition.
local function _zoneSegColor(zCfg)
    local T = ZeD.T
    if zCfg.dock and zCfg.dock.flag then
        local flag = zCfg.dock.flag
        if     flag == "TORN"          then return T.danger
        elseif flag == "WORN"          then return T.warning
        elseif flag == "Leather"       then return T.matLeather or T.warning
        elseif flag == "Denim"         then return T.matDenim   or T.info
        elseif flag == "Fabric"
            or flag == "Ripped Sheets" then return T.matFabric  or T.text
        end
    end
    local ratio = math.max(0, math.min(1, (zCfg.pct or 100) / 100))
    return ratioColor(ratio)
end

-- v15 220w single-row zone layout: NAME(measured) | gap | BAR(1fr) |
-- PCT(measured) | gap | DOCK(square). Replaces S118 drawZoneRow at compact
-- widths. Row height + column widths scale with font height so larger text-
-- size presets don't clip. 480w still uses S118 - its v15 5-column layout
-- (60/36/1fr/76/22) is a S122 follow-up.
-- @return rowH, outDockRect (outDockRect = nil if no dock)
local function _drawZoneRow220(panel, x, y, w, zCfg)
    local T  = ZeD.T
    local tm = ZeD.TM
    local font  = T.fontF1
    local fontH = T.fontF1H or tm:getFontHeight(font)

    -- Row height: font height + generous breathing (8px = 4px above & below).
    -- Bar/dock track row. At fontH=10 → rowH=20; at fontH=18 → rowH=26.
    local rowH  = math.max(fontH + T.px(8), T.px(20))
    local dockH = math.max(fontH + T.px(6), T.px(18))
    local barH  = math.max(math.floor(fontH * 0.55), T.px(7))

    -- Column widths derived from text metrics - name fits widest typical
    -- short label ("Right"); pct fits "100%"; dock is square dockH.
    local nameW = math.max(ZeD.ItemCard.sideW(font) + T.px(6), T.px(40))
    local pctW  = math.max(tm:MeasureStringX(font, "100%") + T.px(4), T.px(28))
    local dockW = dockH + T.px(4)
    local gap   = T.px(6)

    local barX  = x + nameW + gap
    local pctX  = x + w - dockW - gap - pctW
    local dockX = x + w - dockW
    local barW  = pctX - barX - gap

    local barY   = y + math.floor((rowH - barH) / 2)
    local textY  = y + math.floor((rowH - fontH) / 2)
    local pct    = math.max(0, math.min(100, zCfg.pct or 100))
    local ratio  = pct / 100
    local condC  = ratioColor(ratio)
    local segC   = _zoneSegColor(zCfg)

    -- Name (mono, T.text)
    local nameStr = zCfg.name or ""
    panel:drawText(nameStr, x + T.px(4), textY,
        T.text.r, T.text.g, T.text.b, T.text.a or 1, font)

    -- Bar (surf2 bg, segC fill, borderS frame)
    panel:drawRect(barX, barY, barW, barH,
        T.surf2.a or 1, T.surf2.r, T.surf2.g, T.surf2.b)
    local fillW = math.floor(barW * ratio)
    if fillW > 0 then
        panel:drawRect(barX, barY, fillW, barH,
            segC.a or 1, segC.r, segC.g, segC.b)
    end
    panel:drawRectBorder(barX, barY, barW, barH,
        T.borderS.a or 1, T.borderS.r, T.borderS.g, T.borderS.b)

    -- Pct (mono, condition-colored, right-aligned)
    local pctStr   = tostring(math.floor(pct + 0.5)) .. "%"
    local pctTextW = ZeD.TM:MeasureStringX(font, pctStr)
    panel:drawText(pctStr, pctX + pctW - pctTextW, textY,
        condC.r, condC.g, condC.b, condC.a or 1, font)

    -- Dock cell - always rendered per v15 spec (pristine = disabled checkmark,
    -- torn = repair triangle in warning color, patched = remove-patch x in
    -- textSec). outDockRect only set when actionable so the click router
    -- skips disabled pristine docks. dockH defined above (font-scaled).
    local outDockRect = nil
    do
        local dockY = y + math.floor((rowH - dockH) / 2)
        local action  = zCfg.action  -- "repair" / "remove-patch" / nil = pristine
        local bg      = T.surf2
        local bd      = T.border
        local glyph   = "v"  -- ASCII checkmark stand-in (Q15b - Fira lacks ✓)
        local glyphC  = T.textDim
        local alpha   = 0.3  -- disabled default

        if action == "repair" then
            bd, glyphC, glyph, alpha = T.warning, T.warning, "+", 1.0
        elseif action == "remove-patch" then
            bd, glyphC, glyph, alpha = T.textSec, T.textSec, "x", 1.0
        end

        panel:drawRect(dockX, dockY, dockW, dockH,
            (bg.a or 1) * alpha, bg.r, bg.g, bg.b)
        panel:drawRectBorder(dockX, dockY, dockW, dockH,
            (bd.a or 1) * alpha, bd.r, bd.g, bd.b)
        local glyphW = ZeD.TM:MeasureStringX(font, glyph)
        panel:drawText(glyph, dockX + math.floor((dockW - glyphW) / 2),
            dockY + math.floor((dockH - fontH) / 2),
            glyphC.r, glyphC.g, glyphC.b, (glyphC.a or 1) * alpha, font)

        if action then
            outDockRect = {x = dockX, y = dockY, w = dockW, h = dockH}
        end
    end

    return rowH, outDockRect
end

-- v15 480w zone row layout: NAME(60) | gap | PCT(36, right) | gap | BAR(1fr)
-- | gap | FLAG-TEXT(measured) | gap | DOCK(22). Replaces S118 drawZoneRow
-- at non-compact widths so 480w gets full v15 spec parity.
-- @param flagWOverride  Caller-computed flag column width (max across all
--                       zones in the item) so columns align AND the column
--                       collapses for all-pristine clothing - bars expand.
-- @return rowH, outDockRect
local function _drawZoneRow480(panel, x, y, w, zCfg, flagWOverride)
    local T  = ZeD.T
    local tm = ZeD.TM
    local font  = T.fontF1
    local fontH = T.fontF1H or tm:getFontHeight(font)

    local rowH  = math.max(fontH + T.px(10), T.px(22))
    local dockH = math.max(fontH + T.px(6), T.px(20))
    local barH  = math.max(math.floor(fontH * 0.5), T.px(6))

    local nameW  = math.max(ZeD.ItemCard.sideW(font) + T.px(12), T.px(60))
    local pctW   = math.max(tm:MeasureStringX(font, "100%") + T.px(4), T.px(36))
    local flagW  = flagWOverride
                  or math.max(tm:MeasureStringX(font, ZeD.tr("UI_ZeD_Card_FlagLeather")) + T.px(8), T.px(76))
    local dockW  = dockH + T.px(4)
    local gap    = T.px(8)

    local pctX  = x + nameW + gap
    local barX  = pctX + pctW + gap
    local dockX = x + w - dockW
    local flagX = dockX - gap - flagW
    local barW  = flagX - barX - gap

    local nameY = y + math.floor((rowH - fontH) / 2)
    local pctY  = nameY
    local flagY = nameY
    local barY  = y + math.floor((rowH - barH) / 2)

    local pct   = math.max(0, math.min(100, zCfg.pct or 100))
    local ratio = pct / 100
    local condC = ratioColor(ratio)
    local segC  = _zoneSegColor(zCfg)

    -- Name (mono, T.text)
    panel:drawText(zCfg.name or "", x, nameY,
        T.text.r, T.text.g, T.text.b, T.text.a or 1, font)

    -- Pct (right-aligned in pctW, condition-colored)
    local pctStr  = tostring(math.floor(pct + 0.5)) .. "%"
    local pctTW   = tm:MeasureStringX(font, pctStr)
    panel:drawText(pctStr, pctX + pctW - pctTW, pctY,
        condC.r, condC.g, condC.b, condC.a or 1, font)

    -- Bar (surf2 bg, segC fill, borderS frame)
    panel:drawRect(barX, barY, barW, barH,
        T.surf2.a or 1, T.surf2.r, T.surf2.g, T.surf2.b)
    local fillW = math.floor(barW * ratio)
    if fillW > 0 then
        panel:drawRect(barX, barY, fillW, barH,
            segC.a or 1, segC.r, segC.g, segC.b)
    end
    panel:drawRectBorder(barX, barY, barW, barH,
        T.borderS.a or 1, T.borderS.r, T.borderS.g, T.borderS.b)

    -- Flag text (right-aligned in flagW, color = patch material / TORN / WORN)
    local flagStr  = "-"
    local flagC    = T.textDim
    if zCfg.dock and zCfg.dock.flag then
        flagStr = zCfg.dock.flag
        if     flagStr == "TORN"          then flagStr, flagC = ZeD.tr("UI_ZeD_Card_FlagTorn"), T.danger
        elseif flagStr == "WORN"          then flagStr, flagC = ZeD.tr("UI_ZeD_Card_FlagWorn"), T.warning
        elseif flagStr == "Leather"       then flagStr, flagC = ZeD.tr("UI_ZeD_Card_FlagLeather"), T.matLeather or T.warning
        elseif flagStr == "Denim"         then flagStr, flagC = ZeD.tr("UI_ZeD_Card_FlagDenim"),   T.matDenim   or T.info
        elseif flagStr == "Fabric"
            or flagStr == "Ripped Sheets" then flagStr, flagC = ZeD.tr("UI_ZeD_Card_FlagFabric"),  T.matFabric  or T.text
        end
    end
    local flagTW = tm:MeasureStringX(font, flagStr)
    panel:drawText(flagStr, flagX + flagW - flagTW, flagY,
        flagC.r, flagC.g, flagC.b, flagC.a or 1, font)

    -- Dock cell - same v15 spec as 220w (pristine = dim 'v', repair = '+'
    -- in warning, remove-patch = 'x' in textSec). outDockRect only set when
    -- actionable so click router skips disabled cells.
    local outDockRect = nil
    do
        local dockY = y + math.floor((rowH - dockH) / 2)
        local action = zCfg.action
        local bg, bd = T.surf2, T.border
        local glyph  = "v"
        local glyphC = T.textDim
        local alpha  = 0.3
        if action == "repair" then
            bd, glyphC, glyph, alpha = T.warning, T.warning, "+", 1.0
        elseif action == "remove-patch" then
            bd, glyphC, glyph, alpha = T.textSec, T.textSec, "x", 1.0
        end
        panel:drawRect(dockX, dockY, dockW, dockH,
            (bg.a or 1) * alpha, bg.r, bg.g, bg.b)
        panel:drawRectBorder(dockX, dockY, dockW, dockH,
            (bd.a or 1) * alpha, bd.r, bd.g, bd.b)
        local glyphW = tm:MeasureStringX(font, glyph)
        panel:drawText(glyph, dockX + math.floor((dockW - glyphW) / 2),
            dockY + math.floor((dockH - fontH) / 2),
            glyphC.r, glyphC.g, glyphC.b, (glyphC.a or 1) * alpha, font)
        if action then
            outDockRect = {x = dockX, y = dockY, w = dockW, h = dockH}
        end
    end

    return rowH, outDockRect
end

-- v15 multi-segment ZONES bar - N equal-width segments, each colored per
-- _zoneSegColor of the corresponding zone. Drawn inline with the disclosure
-- header at 220w (between the chevron+label and overall % summary).
local function _drawZoneSegBar(panel, x, y, w, h, zones)
    local T = ZeD.T
    if not zones or #zones == 0 then return end
    panel:drawRect(x, y, w, h,
        T.surf2.a or 1, T.surf2.r, T.surf2.g, T.surf2.b)
    panel:drawRectBorder(x, y, w, h,
        T.borderS.a or 1, T.borderS.r, T.borderS.g, T.borderS.b)
    local pad = T.px(1)
    local segGap = T.px(1)
    local innerW = w - pad * 2
    local n = #zones
    local segW = math.floor((innerW - segGap * (n - 1)) / n)
    local cx = x + pad
    for i, zCfg in ipairs(zones) do
        local sc = _zoneSegColor(zCfg)
        local thisW = (i == n) and (x + w - pad - cx) or segW
        panel:drawRect(cx, y + pad, thisW, h - pad * 2,
            sc.a or 1, sc.r, sc.g, sc.b)
        cx = cx + thisW + segGap
    end
end

-- Look up the item's category from the existing ItemCard.lua local - we need
-- this for verb resolution. Re-implementing the minimum here so we don't have
-- to touch ItemCard.lua's exports (and can't anyway, since it's file-local).
-- Mirrors getItemCategory at ItemCard.lua:38.
local function categoryOf(item)
    if not item then return "Item" end
    if safeGet(item, "getFluidContainer") then return "Fluid" end
    if instanceof(item, "HandWeapon") then
        local ammo = safeGet(item, "getAmmoType")
        if ammo and ammo ~= "" then return "Firearm" end
        return "Weapon"
    end
    local cat = safeGet(item, "getCategory")
    if cat == "Food" then return "Food" end
    if cat == "Clothing" then return "Clothing" end
    if instanceof(item, "DrainableComboItem") then return "Drainable" end
    if cat == "Literature" then return "Literature" end
    local cap = safeGet(item, "getItemCapacity")
    if cat == "Container" or (cap and cap > 0) then return "Container" end
    if instanceof(item, "Key") then return "Key" end
    if safeGet(item, "canEmitLight") then return "Light" end
    return "Item"
end

-- ---------------------------------------------------------------------------
-- Marks (FAV / NO-CRAFT / DISPOSE) - read item modData
-- modData keys established by S119 designer ruling - DO NOT rename:
--   ZeD_fav      → fav chip
--   ZeD_noCraft  → nocraft chip (matches existing S99 ActionStrip "protect" key)
--   ZeD_unwanted → dispose chip (matches existing S99 ActionStrip "unwanted" key)
-- ---------------------------------------------------------------------------
local function readMarks(item, playerNum)
    if not item then return {fav=false, nocraft=false, dispose=false} end
    local fav = safeGet(item, "isFavorite") or false
    local nc, dis = false, false
    -- no-craft is vanilla's "Unusable in Recipes" and unwanted is per player:
    -- both through ActionStrip.getState (Oct 19 2026: no-craft was a ZeD-only
    -- mark nothing read)
    if ZeD and ZeD.ActionStrip and ZeD.ActionStrip.getState then
        local ok, v = pcall(ZeD.ActionStrip.getState, item, "unwanted", playerNum)
        if ok then dis = v and true or false end
        local ok2, v2 = pcall(ZeD.ActionStrip.getState, item, "protect", playerNum)
        if ok2 then nc = v2 and true or false end
    end
    return {fav = fav, nocraft = nc, dispose = dis}
end

-- ---------------------------------------------------------------------------
-- Header verb cluster (back-bar) - primary action by source context.
-- Returns array of {label, primary, glyph?}. Drawn right-to-left by
-- drawCardBackBar; primary first in the array renders rightmost (the CTA).
-- ---------------------------------------------------------------------------
local function headerVerbsForContext(ctx, item)
    if not item then return {} end
    local cat = categoryOf(item)

    -- MORE (Oct 19 2026, the single-path audit): the item's whole context menu,
    -- in the player's chosen look, at the button: everything the card has no
    -- room for (drop, put in, off hand, rename, vanilla's and mods' options)
    -- is one press away on every card, mouse or controller.
    local VT = ZeD.ItemCard.verbText
    local more = {id = "MORE", label = VT("MORE"), primary = false, isMore = true}
    if ctx == "equipped" then
        return {
            {id = "UNEQUIP", label = VT("UNEQUIP"), primary = true},
            {id = "DROP",    label = VT("DROP"),    primary = false},
            more,
        }
    end

    if ctx == "ground" then
        return {{id = "TAKE", label = VT("TAKE"), primary = true}, more}
    end

    -- inventory + container share the same primary verb logic, modulo TAKE
    -- being needed when source is a non-player container.
    local primary
    if cat == "Clothing" then
        primary = {id = "EQUIP", label = VT("EQUIP"), primary = true}
    elseif cat == "Weapon" or cat == "Firearm" then
        primary = {id = "EQUIP", label = VT("EQUIP"), primary = true}
    elseif cat == "Food" then
        -- a food item with a verb of its own (the game's CustomContextMenu: Smoke, Drink, Chew ...)
        -- shows that verb, the game's own words; the button still runs the game's eat, which smokes,
        -- drinks or chews it (director, Oct 24 2026: "Seems weird the character would be eating a cig")
        local own = safeGet(item, "getCustomMenuOption")
        primary = {id = "EAT", label = (own and own ~= "") and tostring(own) or VT("EAT"), primary = true}
    elseif cat == "Literature" then
        primary = {id = "READ", label = VT("READ"), primary = true}
    elseif cat == "Drainable" then
        primary = {id = "USE", label = VT("USE"), primary = true}
    elseif cat == "Fluid" then
        -- DRINK (Oct 19 2026): bottles and canteens had no card verb
        local fc = safeGet(item, "getFluidContainer")
        local empty = fc and safeGet(fc, "isEmpty")
        if fc and not empty and not safeGet(item, "isSealed") then primary = {id = "DRINK", label = VT("DRINK"), primary = true} end
    elseif cat == "Container" then
        -- WEAR (Oct 19 2026): a backpack couldn't be put on from its card
        local loc = safeGet(item, "canBeEquipped")
        if (loc and loc ~= "") or safeGet(item, "getBodyLocation") then primary = {id = "WEAR", label = VT("WEAR"), primary = true} end
    else
        primary = nil
    end

    local verbs = {}
    if primary then verbs[#verbs + 1] = primary end
    -- OFF HAND (Oct 19 2026): only the context menu equipped the second hand
    if cat == "Weapon" or cat == "Firearm" then verbs[#verbs + 1] = {id = "OFF HAND", label = VT("OFF HAND"), primary = false} end
    if ctx == "container" then
        table.insert(verbs, 1, {id = "TAKE", label = VT("TAKE"), primary = (primary == nil)})
    elseif ctx == "inventory" then
        verbs[#verbs + 1] = {id = "DROP", label = VT("DROP"), primary = false}
    end
    verbs[#verbs + 1] = more
    return verbs
end

-- ---------------------------------------------------------------------------
-- Maintenance verb cluster (verb-strip) - item-type-specific maintenance
-- actions. Empty array = strip skips render entirely (books).
-- Returns array of {label, glyph?, key?}. `key` is the dispatch tag for B8
-- click router.
-- ---------------------------------------------------------------------------
local function maintenanceVerbsForItem(item)
    if not item then return {} end
    local cat = categoryOf(item)
    -- (Oct 19 2026, the single-path audit: WASH, CLEAN and COOK were drawn
    -- with nothing behind them and SHARPEN ran a repair. Now WASH washes,
    -- shown when the garment is dirty or bloody; SHARPEN sharpens, shown on a
    -- blade that isn't sharp; CLEAN and COOK are gone, as vanilla has no such
    -- action on the item: cooking happens on a heat source, and the card's
    -- progress band shows it.)
    if cat == "Clothing" then
        local verbs = {}
        local dirty = (safeGet(item, "getDirtiness") or 0) > 0 or (safeGet(item, "getBloodLevel") or 0) > 0
        local VT = ZeD.ItemCard.verbText
        if dirty then verbs[#verbs + 1] = {label = VT("WASH"), glyph = "~", key = "wash"} end
        verbs[#verbs + 1] = {label = VT("REPAIR"), glyph = "+", key = "repair_all"}
        verbs[#verbs + 1] = {label = VT("PAD"),    glyph = "#", key = "pad_all"}
        return verbs
    elseif cat == "Weapon" then
        local verbs = {{label = ZeD.ItemCard.verbText("REPAIR"), glyph = "+", key = "repair"}}
        if safeGet(item, "hasSharpness") and (safeGet(item, "getSharpness") or 1) < 1 then
            verbs[#verbs + 1] = {label = ZeD.ItemCard.verbText("SHARPEN"), glyph = "/", key = "sharpen"}
        end
        return verbs
    elseif cat == "Firearm" then
        return {{label = ZeD.ItemCard.verbText("REPAIR"), glyph = "+", key = "repair"}}
    end
    -- Food, Literature, Container, Drainable, Key, Light, Fluid → no maintenance verbs
    return {}
end

-- ---------------------------------------------------------------------------
-- TOP STATS: per-type stat row composition for the grid (480w) / list (220w).
-- Each entry: {label, value, valueClass?, dotColor?, mirrorKey?}
-- mirrorKey = "cooked" | "progress" | "condition" - used by B7 state mirror
-- to recolor this row when ItemActionManager has a matching active action.
-- ---------------------------------------------------------------------------
local function topStatsForItem(item)
    if not item then return {} end
    local cat = categoryOf(item)
    local rows = {}

    -- Universal: KIND + WEIGHT
    do
        local subtype = safeGet(item, "getDisplayCategory")
        if not subtype or subtype == "" then subtype = cat end
        rows[#rows + 1] = {label = ZeD.tr("UI_ZeD_Card_Kind"),   value = tostring(subtype)}
        local wt = safeGet(item, "getActualWeight") or safeGet(item, "getWeight") or 0
        rows[#rows + 1] = {label = ZeD.tr("UI_ZeD_Weight"), value = string.format("%.1f kg", wt)}
    end

    if cat == "Clothing" then
        local fab = safeGet(item, "getFabricType")
        if not fab or fab == "" then fab = ZeD.tr("UI_ZeD_Card_Cotton") end
        local condMax = safeGet(item, "getConditionMax") or 1
        local cond    = safeGet(item, "getCondition")    or condMax
        local r       = math.max(0, math.min(1, cond / math.max(1, condMax)))
        local pctStr  = string.format("%d%%", math.floor(r * 100 + 0.5))
        local combat  = safeGet(item, "getCombatSpeedModifier")
        local run     = safeGet(item, "getRunSpeedModifier")
        rows[#rows + 1] = {label = ZeD.tr("UI_ZeD_Card_Fabric"), value = tostring(fab)}
        rows[#rows + 1] = {label = getText("IGUI_invpanel_Condition"), value = pctStr,
            valueClass = ratioClass(r), dotColor = ratioColor(r),
            mirrorKey = "condition"}
        if combat and combat ~= 1.0 then
            local pc = math.floor((combat - 1) * 100 + 0.5)
            local cls = pc < 0 and "warn" or (pc > 0 and "good" or nil)
            rows[#rows + 1] = {label = ZeD.tr("UI_ZeD_Card_Combat"),
                value = string.format("%+d%%", pc), valueClass = cls}
        end
        if run and run ~= 1.0 then
            local pr = math.floor((run - 1) * 100 + 0.5)
            local cls = pr < 0 and "warn" or (pr > 0 and "good" or nil)
            rows[#rows + 1] = {label = ZeD.tr("UI_ZeD_Card_Run"),
                value = string.format("%+d%%", pr), valueClass = cls}
        end
    elseif cat == "Food" then
        local hung = safeGet(item, "getHungerChange")
        local thst = safeGet(item, "getThirstChange")
        if hung then
            rows[#rows + 1] = {label = getText("Tooltip_food_Hunger"),
                value = string.format("%+d", math.floor(-hung * 100 + 0.5))}
        end
        if thst then
            rows[#rows + 1] = {label = getText("Tooltip_food_Thirst"),
                value = string.format("%+d", math.floor(-thst * 100 + 0.5))}
        end
        local cooked = safeGet(item, "isCooked")
        local burnt  = safeGet(item, "isBurnt")
        local raw    = safeGet(item, "isbDangerousUncooked")
        local cookedStr, cookedClass
        if burnt          then cookedStr, cookedClass = getText("Tooltip_food_Burnt"),  "bad"
        elseif cooked     then cookedStr, cookedClass = getText("Tooltip_food_Cooked"), "good"
        elseif raw        then cookedStr, cookedClass = ZeD.tr("UI_ZeD_Card_Raw"),    "bad"
        else                   cookedStr, cookedClass = "-",      "dim" end
        rows[#rows + 1] = {label = getText("Tooltip_food_Cooked"), value = cookedStr,
            valueClass = cookedClass, mirrorKey = "cooked"}
        local rotten = safeGet(item, "isRotten")
        local fresh  = safeGet(item, "isFresh")
        if rotten then
            rows[#rows + 1] = {label = getText("Tooltip_food_Fresh"), value = getText("Tooltip_food_Rotten"), valueClass = "bad"}
        elseif fresh then
            rows[#rows + 1] = {label = getText("Tooltip_food_Fresh"), value = getText("Tooltip_food_Fresh"), valueClass = "good"}
        end
    elseif cat == "Weapon" or cat == "Firearm" then
        local condMax = safeGet(item, "getConditionMax") or 1
        local cond    = safeGet(item, "getCondition")    or condMax
        local r       = math.max(0, math.min(1, cond / math.max(1, condMax)))
        rows[#rows + 1] = {label = getText("IGUI_invpanel_Condition"),
            value = string.format("%d%%", math.floor(r * 100 + 0.5)),
            valueClass = ratioClass(r), dotColor = ratioColor(r),
            mirrorKey = "condition"}
        local mn, mx = safeGet(item, "getMinDamage"), safeGet(item, "getMaxDamage")
        if mn and mx then
            rows[#rows + 1] = {label = getText("Tooltip_weapon_Damage"),
                value = string.format("%.1f-%.1f", mn, mx)}
        end
        local reach = safeGet(item, "getMaxRange") or safeGet(item, "getMinRange")
        if reach then
            rows[#rows + 1] = {label = ZeD.tr("UI_ZeD_Card_Reach"), value = string.format("%.1f", reach)}
        end
        if cat == "Firearm" then
            local ammo = safeGet(item, "getCurrentAmmoCount") or 0
            local cap  = safeGet(item, "getMaxAmmo") or 0
            rows[#rows + 1] = {label = getText("Tooltip_weapon_Ammo"),
                value = string.format("%d/%d", ammo, cap)}
        end
    elseif cat == "Literature" then
        local pages   = safeGet(item, "getNumberOfPages") or 0
        local already = safeGet(item, "getAlreadyReadPages") or 0
        if pages > 0 then
            local r = math.max(0, math.min(1, already / pages))
            rows[#rows + 1] = {label = ZeD.tr("UI_ZeD_Card_Progress"),
                value = string.format("%d / %d", already, pages),
                valueClass = ratioClass(r), mirrorKey = "progress"}
        end
        local skill = safeGet(item, "getSkillTrained")
        if skill and skill ~= "" then
            rows[#rows + 1] = {label = getText("IGUI_Skill"), value = tostring(skill)}
        end
        local lvlMin = safeGet(item, "getLvlSkillTrained") or 0
        local lvlMax = safeGet(item, "getMaxLevelTrained") or lvlMin
        if lvlMin > 0 or lvlMax > 0 then
            rows[#rows + 1] = {label = ZeD.tr("UI_ZeD_Card_Level"),
                value = string.format("%d - %d", lvlMin, lvlMax)}
        end
    elseif cat == "Container" then
        local cap = safeGet(item, "getItemCapacity") or 0
        rows[#rows + 1] = {label = ZeD.tr("Tooltip_container_Capacity"),
            value = string.format("%d", math.floor(cap + 0.5))}
        local inner = safeGet(item, "getInventory")
        if inner then
            local count = safeGet(inner, "getItems")
            local n = (count and count.size) and count:size() or 0
            rows[#rows + 1] = {label = ZeD.tr("UI_ZeD_Card_Items"), value = tostring(n)}
        end
        local reduc = safeGet(item, "getWeightReduction")
        if reduc and reduc > 0 then
            rows[#rows + 1] = {label = ZeD.tr("UI_ZeD_Card_WeightReduce"),
                value = string.format("%d%%", math.floor(reduc + 0.5))}
        end
    elseif cat == "Drainable" then
        local used = safeGet(item, "getUsedDelta")
        if used then
            local r = math.max(0, math.min(1, used))
            rows[#rows + 1] = {label = getText("IGUI_invpanel_Remaining"),
                value = string.format("%d%%", math.floor(r * 100 + 0.5)),
                valueClass = ratioClass(r), dotColor = ratioColor(r)}
        end
    end

    return rows
end

-- ---------------------------------------------------------------------------
-- B7: state mirror - apply ItemActionManager's active-action color to the
-- top-stat row whose mirrorKey matches. Mutates `rows` in place.
-- "cooking"   → COOKED row becomes warn (active) or bad (danger/burning)
-- "reading"   → PROGRESS row becomes warn-ish during read
-- "repairing" → CONDITION row becomes warn-ish during repair
-- ---------------------------------------------------------------------------
local function mirrorActiveStateOnRows(item, rows)
    local mgr = ZeD.ItemActionManager
    if not mgr or not item or not rows then return end
    local action = mgr.getActiveAction(item)
    if not action then return end
    local kind   = action.kind  or action.label  -- accept either field
    local danger = action.mode == "danger"
    local mirror
    if kind and kind:lower():find("cook")    then mirror = "cooked"    end
    if kind and kind:lower():find("read")    then mirror = "progress"  end
    if kind and kind:lower():find("repair")  then mirror = "condition" end
    if not mirror then return end
    for _, r in ipairs(rows) do
        if r.mirrorKey == mirror then
            r.valueClass = danger and "bad" or "warn"
            r.dotColor   = nil
        end
    end
end

-- ---------------------------------------------------------------------------
-- Render helper: rebuild ZeD_ItemCard's per-frame hit rect tables to match
-- the gamepad ring API contract (lines 1395-1592 of ItemCard.lua).
--
-- `toggleRects[i]` for i in 1..3 → flag-strip chips in DEFS order: fav,
--    protect (=nocraft), unwanted (=dispose). Mapped from `markRects`.
-- `verbRects[i]` for i in 1..#maintenance → maintenance verb-strip buttons.
-- `_verbDefs[i]` mirrors maintenance verb keys (gamepad onActivate dispatch).
-- `_zoneDockRects[]` populated by clothing-body's drawZoneRow loop.
-- `_foldHitRects[]` populated by disclosure paint helpers.
-- `_cancelRect` (NEW) → progress-band cancel button (B9 wires to gamepad).
-- ---------------------------------------------------------------------------
local function stampGamepadFields(card, markRects, verbStripRects, verbList, cancelRect)
    -- toggleRects / verbRects are ABSOLUTE screen coords: update() tests them
    -- against getMouseX/Y, the gamepad ring converts them to drawer-local and
    -- the focus outline subtracts the card's absolute origin. The draw helpers
    -- stamp card-local rects, so lift them here (Oct 17 2026: left local, the
    -- chips and verbs took no clicks and the pad could never reach the card).
    local ax, ay = card:getAbsoluteX(), card:getAbsoluteY()
    local function abs(r)
        if not (r and r.x) then return nil end
        return {x = ax + r.x, y = ay + r.y, w = r.w, h = r.h}
    end

    -- Flag-strip chips → toggleRects (gamepad: fav/nocraft/dispose toggles).
    -- Existing TOGGLE_DEFS order: fav (i=1), protect (i=2), unwanted (i=3).
    card.toggleRects = card.toggleRects or {}
    card.toggleRects[1] = markRects and abs(markRects.fav)
    card.toggleRects[2] = markRects and abs(markRects.nocraft)
    card.toggleRects[3] = markRects and abs(markRects.dispose)

    -- Maintenance verb strip → verbRects + _verbDefs (gamepad: A activates).
    card.verbRects = {}
    for i, r in ipairs(verbStripRects or {}) do card.verbRects[i] = abs(r) end
    card._verbDefs = {}
    for i, v in ipairs(verbList or {}) do
        card._verbDefs[i] = {
            key      = v.key,
            iconKey  = v.glyph,            -- legacy field name; not a texture anymore
            active   = true,                -- enablement check happens at dispatch time
            tip      = v.label,
            label    = v.label,
        }
    end

    -- Progress band cancel button. Absolute coords for update()'s hit test
    -- (matches _foldHitRects / _zoneDockRects convention). cancelRect is
    -- panel-local from drawProgressBand's outRect; absolutize here.
    card._cancelRect = abs(cancelRect)
end

-- ---------------------------------------------------------------------------
-- BODY: clothing - 480w grid + zones + DefenseFacts always-expanded;
--                  220w list + zones + DefenseFacts behind a disclosure.
-- ---------------------------------------------------------------------------
local function renderClothingBody(card, item, x, y, w, compact, scrollOff, contentClipBot)
    local T  = ZeD.T
    local M  = ZeD.Molecules
    local tm = ZeD.TM
    -- Section gap scales with font so the gap between top-stats / zones /
    -- facts breathes proportionally at larger text sizes.
    local f4H = T.fontF4H or tm:getFontHeight(T.fontF4)
    local sectionGap = math.max(compact and T.px(14) or T.px(16), math.floor(f4H * 1.0))

    local cy = y

    -- Top stats (icon + 2-col grid at 480w; single-col list at 220w)
    local rows = topStatsForItem(item)
    mirrorActiveStateOnRows(item, rows)
    if compact then
        cy = cy + M.drawTopStatsList(card, x, cy, w, rows)
    else
        local tex = safeGet(item, "getTexture")
        cy = cy + M.drawTopStatsGrid(card, x, cy, w, tex, rows)
    end
    cy = cy + sectionGap

    -- Zones disclosure + zone list per v15 spec.
    -- 220w: NAME(38)|BAR(1fr)|PCT(26)|DOCK(18) single-row, grouped by anatomy.
    -- 480w: still S118 drawZoneRow until the 5-column v15 480w molecule lands.
    local zones = ZeD.ItemDetail and ZeD.ItemDetail.buildConfigs
                 and ZeD.ItemDetail.buildConfigs(item) or {}
    if #zones > 0 then
        local discKey = "clothing_zones"
        local expanded = (card._foldStates and card._foldStates[discKey]) ~= false

        -- Padding tokens scale with font height (per memory feedback_padding_preference:
        -- generous 6-10px default, 2px is nothing, 4px is "a little"). Larger
        -- text-size presets get proportional breathing room instead of
        -- clipping. Each padding value floors at the small-font baseline +
        -- scales upward as fontH grows.
        local tm     = ZeD.TM
        local font   = T.fontF1
        local fontH  = T.fontF1H or tm:getFontHeight(font)
        local function scalePad(base) return math.max(T.px(base), math.floor(fontH * 0.6)) end  -- S124 scale: base is in design units
        local hdrH   = math.max(fontH + T.px(10), T.px(24))            -- ZONES disclosure
        local groupHdrH = math.max(fontH + T.px(8), T.px(20))          -- TORSO/UPPER ARM/...
        local groupPadAbove = scalePad(10)                 -- pad above each group (after first)
        local rowGap = scalePad(5)                         -- breathe between zone rows
        local segH   = math.max(math.floor(fontH * 0.8), T.px(12))
        local padAfterSegBar              = scalePad(12)
        local padAfterSoilRow             = scalePad(8)
        local padAfterDisclosureBeforeSegBar = scalePad(8)

        -- Overall garment condition for the disclosure summary text
        local condMax = safeGet(item, "getConditionMax") or 1
        local cond    = safeGet(item, "getCondition") or condMax
        local condR   = math.max(0, math.min(1, cond / math.max(1, condMax)))
        local condPctStr = string.format("%d%%", math.floor(condR * 100 + 0.5))
        local condColor  = ratioColor(condR)

        -- Resolve item-level soil up front - used inline in the 480w
        -- disclosure header AND in the 220w soil-row-below path.
        local soil = nil
        if ZeD.ItemDetail and ZeD.ItemDetail.buildItemSoil then
            soil = ZeD.ItemDetail.buildItemSoil(item)
        end

        -- Disclosure header.
        -- 220w: chevron + ZONES label + overall %, with seg-bar + soil row
        --       drawn beneath when expanded.
        -- 480w: chevron + ZONES + seg-bar (inline middle) + % + DIRTY/WET
        --       chips (right) all on one row per v15 spec; expanded body
        --       skips the duplicate seg-bar + soil row below.
        do
            local textY  = cy + math.floor((hdrH - fontH) / 2)
            local chev   = expanded and "v" or ">"
            local chevC  = T.textSec
            local labelC = T.accent
            card:drawText(chev, x, textY,
                chevC.r, chevC.g, chevC.b, chevC.a or 1, font)
            local zonesTxt = ZeD.tr("UI_ZeD_Card_Zones")
            card:drawText(zonesTxt, x + T.px(14), textY,
                labelC.r, labelC.g, labelC.b, labelC.a or 1, font)
            local labelEndX = x + T.px(14) + tm:MeasureStringX(font, zonesTxt) + T.px(8)

            if compact then
                -- Right-aligned overall % only
                local sumW = tm:MeasureStringX(font, condPctStr)
                card:drawText(condPctStr, x + w - sumW, textY,
                    condColor.r, condColor.g, condColor.b, condColor.a or 1, font)
            else
                -- Inline composition: [chevron+label][seg-bar fills][%][DIRTY][WET]
                -- Reserve right side for chips first, then % left of chips,
                -- seg-bar fills the rest. Chip widths derive from text content.
                local chipPadX  = T.px(6)
                local chipGap   = T.px(6)
                local chips = {}
                if soil and soil.dirt then
                    chips[#chips + 1] = {label = ZeD.upper(ZeD.tr("Tooltip_clothing_dirty")), color = T.soiledDirt or T.warning, text = T.soiledDirtText}
                end
                if soil and soil.wet then
                    chips[#chips + 1] = {label = ZeD.tr("UI_ZeD_Card_WetPct", tostring(soil.wet) .. "%"),
                                         color = T.soiledWet or T.info, text = T.soiledWetText}
                end

                -- Compute right-anchored cursor walking left
                local chipH = math.max(fontH + T.px(4), T.px(16))
                local rightCursor = x + w
                local chipRects = {}
                for i = #chips, 1, -1 do
                    local c = chips[i]
                    local labelW = tm:MeasureStringX(font, c.label)
                    local cw = labelW + chipPadX * 2
                    rightCursor = rightCursor - cw
                    chipRects[i] = {x = rightCursor, w = cw, y = cy + math.floor((hdrH - chipH) / 2), h = chipH}
                    if i > 1 then rightCursor = rightCursor - chipGap end
                end
                if #chips > 0 then rightCursor = rightCursor - chipGap end

                -- Overall % (right-aligned, left of chips)
                local sumW = tm:MeasureStringX(font, condPctStr)
                local sumX = rightCursor - sumW
                card:drawText(condPctStr, sumX, textY,
                    condColor.r, condColor.g, condColor.b, condColor.a or 1, font)
                local sumLeftEdge = sumX - T.px(8)

                -- Seg-bar fills middle (between label end and % left edge)
                local barX = labelEndX
                local barW = sumLeftEdge - barX
                if barW > T.px(20) then
                    local barH = math.max(math.floor(fontH * 0.7), T.px(10))
                    local barY = cy + math.floor((hdrH - barH) / 2)
                    _drawZoneSegBar(card, barX, barY, barW, barH, zones)
                end

                -- Draw chips (after seg-bar so they layer cleanly)
                for i, c in ipairs(chips) do
                    local r = chipRects[i]
                    local col = c.color or T.text
                    card:drawRect(r.x, r.y, r.w, r.h,
                        T.surf2.a or 1, T.surf2.r, T.surf2.g, T.surf2.b)
                    card:drawRectBorder(r.x, r.y, r.w, r.h,
                        col.a or 1, col.r, col.g, col.b)
                    local lw = tm:MeasureStringX(font, c.label)
                    local lx = r.x + math.floor((r.w - lw) / 2)
                    local ly = r.y + math.floor((r.h - fontH) / 2)
                    local tcol = c.text or col
                    card:drawText(c.label, lx, ly,
                        tcol.r, tcol.g, tcol.b, tcol.a or 1, font)
                end
            end
        end
        -- Hit rect for fold toggle. ItemCard:update() compares against
        -- ABSOLUTE mouse coords, so stamp absolute (add panel offsets).
        do
            local ax = card:getAbsoluteX()
            local ay = card:getAbsoluteY()
            card._foldHitRects[#card._foldHitRects + 1] = {
                x = ax + x, y = ay + cy, w = w, h = hdrH, key = discKey,
            }
        end
        cy = cy + hdrH

        if expanded then
            -- 220w: seg-bar + soil row below the disclosure (not inline).
            -- 480w: skip - already composed inline in the disclosure header.
            if compact then
                cy = cy + padAfterDisclosureBeforeSegBar
                _drawZoneSegBar(card, x, cy, w, segH, zones)
                cy = cy + segH + padAfterSegBar

                if soil and ZeD.ItemDetail and ZeD.ItemDetail.drawSoilRow then
                    cy = cy + ZeD.ItemDetail.drawSoilRow(card, x, cy, w, soil)
                    cy = cy + padAfterSoilRow
                end
            end

            -- Per-zone rows w/ anatomical group headers. Both widths use the
            -- same grouping; 220w → _drawZoneRow220 (NAME/BAR/PCT/DOCK),
            -- 480w → _drawZoneRow480 (NAME/PCT/BAR/FLAG/DOCK).
            -- 480w flag column sized to the widest actual flag text in this
            -- item's zones - pristine-only clothing gets a collapsed column,
            -- bars expand to fill. Patched/torn items get the wider column.
            card._zoneDockRects = {}
            local maxFlagW = 0
            if not compact then
                local probeFont = T.fontF1
                local minDashW = tm:MeasureStringX(probeFont, "-") + T.px(4)
                for _, zCfg in ipairs(zones) do
                    local flagStr = "-"
                    if zCfg.dock and zCfg.dock.flag then
                        flagStr = zCfg.dock.flag
                        if flagStr == "TORN"          then flagStr = ZeD.tr("UI_ZeD_Card_FlagTorn")
                        elseif flagStr == "WORN"      then flagStr = ZeD.tr("UI_ZeD_Card_FlagWorn")
                        elseif flagStr == "Leather"   then flagStr = ZeD.tr("UI_ZeD_Card_FlagLeather")
                        elseif flagStr == "Denim"     then flagStr = ZeD.tr("UI_ZeD_Card_FlagDenim")
                        elseif flagStr == "Fabric"
                            or flagStr == "Ripped Sheets" then flagStr = ZeD.tr("UI_ZeD_Card_FlagFabric")
                        end
                    end
                    local fW = tm:MeasureStringX(probeFont, flagStr) + T.px(4)
                    if fW > maxFlagW then maxFlagW = fW end
                end
                maxFlagW = math.max(maxFlagW, minDashW)
            end
            local prevGroup = nil
            for i, zCfg in ipairs(zones) do
                local gMap      = ZONE_GROUP_MAP[zCfg.name or ""]
                local groupName = gMap and gMap[1] or "UI_ZeD_Card_ZoneOther"
                local shortName = gMap and ZeD.tr(gMap[2]) or zCfg.name

                if groupName ~= prevGroup then
                    if prevGroup ~= nil then cy = cy + groupPadAbove end
                    local hdrTY = cy + math.floor((groupHdrH - fontH) / 2)
                    local hdrC  = T.accent
                    card:drawText(ZeD.upper(ZeD.tr(groupName)), x, hdrTY,
                        hdrC.r, hdrC.g, hdrC.b, hdrC.a or 1, font)
                    cy = cy + groupHdrH
                    prevGroup = groupName
                end

                local zRow = {
                    name   = shortName,
                    pct    = zCfg.pct,
                    bar    = zCfg.bar,
                    dock   = zCfg.dock,
                    soiled = zCfg.soiled,
                    action = zCfg.action,
                }
                local rowH, outDockRect
                if compact then
                    rowH, outDockRect = _drawZoneRow220(card, x, cy, w, zRow)
                else
                    rowH, outDockRect = _drawZoneRow480(card, x, cy, w, zRow, maxFlagW)
                end
                if outDockRect and zCfg.action then
                    -- Stamp absolute coords (update() compares vs absolute mouse).
                    local ax, ay = card:getAbsoluteX(), card:getAbsoluteY()
                    card._zoneDockRects[#card._zoneDockRects + 1] = {
                        x = ax + outDockRect.x, y = ay + outDockRect.y,
                        w = outDockRect.w, h = outDockRect.h,
                        zoneIdx = i, zone = zCfg,
                        id = "dock_" .. i,
                    }
                end
                cy = cy + rowH + rowGap
            end
        end
        cy = cy + sectionGap
    end

    -- Defense Facts panel via registry. At 220w it's behind a disclosure
    -- (zones competing for vertical); at 480w always-expanded.
    local panel = ZeD.ItemFactsPanel and ZeD.ItemFactsPanel.factsFor(item)
    if panel then
        local discKey = "facts_defense"
        local hasDisc = compact and panel.hasDisclosure
        local expanded = hasDisc and ((card._foldStates and card._foldStates[discKey]) ~= false) or (not hasDisc)
        if hasDisc then
            local hdrH = T.px(18)
            local font = T.fontF2
            local labelH = T.fontF2H or ZeD.TM:MeasureStringY(font, "X")
            local chev = expanded and "v" or ">"
            local textY = cy + math.floor((hdrH - labelH) / 2)
            card:drawText(chev, x, textY, T.textSec.r, T.textSec.g, T.textSec.b, T.textSec.a, T.fontF1)
            card:drawText(panel.title or ZeD.tr("UI_ZeD_Card_Facts"), x + T.px(12), textY, T.text.r, T.text.g, T.text.b, T.text.a, font)
            -- Absolute coords for fold hit (update() compares vs absolute mouse)
            local ax, ay = card:getAbsoluteX(), card:getAbsoluteY()
            card._foldHitRects[#card._foldHitRects + 1] = {
                x = ax + x, y = ay + cy, w = w, h = hdrH, key = discKey,
            }
            cy = cy + hdrH + T.px(2)
        end
        if expanded then
            -- Skip drawFactsTitle when the disclosure header already shows
            -- the panel title (avoids duplicate "Defense Facts" at 220w).
            if not hasDisc then
                cy = cy + (M.drawFactsTitle and M.drawFactsTitle(card, x, cy, w, panel.title or ZeD.tr("UI_ZeD_Card_Facts"), compact) or 0)
            end
            cy = cy + (M.drawFactsRuleThick and M.drawFactsRuleThick(card, x, cy, w) or 0) + T.px(2)
            for gi, group in ipairs(panel.groups or {}) do
                if gi > 1 then
                    cy = cy + (M.drawFactsRuleThin and M.drawFactsRuleThin(card, x, cy, w) or 0) + T.px(2)
                end
                for _, row in ipairs(group.rows or {}) do
                    local lbl = row.label
                    if compact and lbl and row.short then
                        lbl = row.short
                    end
                    cy = cy + (M.drawFactsRow and
                        M.drawFactsRow(card, x, cy, w,
                            lbl, row.value, row.valueClass, row.isSub, row.needsProbe) or 0)
                end
            end
        end
    end

    return cy - y
end

-- ---------------------------------------------------------------------------
-- BODY: generic (food / weapon / book / container / drainable / etc.)
-- Always-expanded Facts panel; no zone list.
-- ---------------------------------------------------------------------------
local function renderGenericBody(card, item, x, y, w, compact, scrollOff, contentClipBot)
    local T  = ZeD.T
    local M  = ZeD.Molecules
    local tm = ZeD.TM
    local f4H = T.fontF4H or tm:getFontHeight(T.fontF4)
    local sectionGap = math.max(compact and T.px(14) or T.px(16), math.floor(f4H * 1.0))

    local cy = y

    -- Top stats
    local rows = topStatsForItem(item)
    mirrorActiveStateOnRows(item, rows)
    if compact then
        cy = cy + M.drawTopStatsList(card, x, cy, w, rows)
    else
        local tex = safeGet(item, "getTexture")
        cy = cy + M.drawTopStatsGrid(card, x, cy, w, tex, rows)
    end
    cy = cy + sectionGap

    -- Facts panel via registry
    local panel = ZeD.ItemFactsPanel and ZeD.ItemFactsPanel.factsFor(item)
    if panel then
        cy = cy + (M.drawFactsTitle and M.drawFactsTitle(card, x, cy, w, panel.title or ZeD.tr("UI_ZeD_Card_Facts"), compact) or 0)
        cy = cy + (M.drawFactsRuleThick and M.drawFactsRuleThick(card, x, cy, w) or 0) + T.px(2)
        for gi, group in ipairs(panel.groups or {}) do
            if gi > 1 then
                cy = cy + (M.drawFactsRuleThin and M.drawFactsRuleThin(card, x, cy, w) or 0) + T.px(2)
            end
            for _, row in ipairs(group.rows or {}) do
                local lbl = row.label
                if compact and lbl and row.short then
                    lbl = row.short
                end
                cy = cy + (M.drawFactsRow and
                    M.drawFactsRow(card, x, cy, w,
                        lbl, row.value, row.valueClass, row.isSub, row.needsProbe) or 0)
            end
        end
    end

    return cy - y
end

-- ---------------------------------------------------------------------------
-- :renderBody(ctx) - the universal organism entry.
-- ---------------------------------------------------------------------------
function ZeD_ItemCard:renderBody(ctx)
    local T = ZeD.T
    if not self.item then return end
    local w = self:getWidth()
    if w < T.px(80) then return end

    local item     = self.item
    local sourceCx = (ctx and ctx.sourceContext) or self.sourceContext or "inventory"
    local marks    = (ctx and ctx.marks) or readMarks(item, self.playerNum)
    local compact  = select(1, widthPreset(w))
    local mgr      = ZeD.ItemActionManager
    local action   = mgr and mgr.getActiveAction(item) or nil
    local progressActive = action ~= nil

    local M  = ZeD.Molecules
    local T  = ZeD.T

    -- Reset per-frame hit rect tables before paint
    self._foldHitRects  = {}
    self._zoneDockRects = {}
    local backBarRects  = {back = nil, verbs = {}}
    local flagRects     = {fav = {}, nocraft = {}, dispose = {}}
    local verbStripRects = {}
    local cancelRect    = nil

    -- Paint chrome top-down -------------------------------------------------
    local cy = 0

    -- 1) Back bar (header verbs from source context).
    -- v15 220w spec shows ONE primary verb only (UNEQUIP / EQUIP / TAKE).
    -- 480w shows primary + 1 secondary (e.g. UNEQUIP + DROP).
    -- Item name is intentionally OMITTED from the back-bar - it lives on
    -- its own full-width row below so long names don't truncate and the
    -- row can host a rename input in a future iteration.
    local headerVerbs = headerVerbsForContext(sourceCx, item)
    if compact and #headerVerbs > 1 then
        local primary
        for _, v in ipairs(headerVerbs) do
            if v.primary then primary = v; break end
        end
        -- the narrow card keeps its main verb and MORE (everything else is in MORE's menu)
        local moreV = headerVerbs[#headerVerbs].isMore and headerVerbs[#headerVerbs] or nil
        headerVerbs = primary and {primary} or {headerVerbs[1]}
        if moreV and headerVerbs[1] ~= moreV then headerVerbs[#headerVerbs + 1] = moreV end
    end
    local displayName = safeGet(item, "getDisplayName") or "???"
    local bbH = M.drawCardBackBar(self, 0, cy, w, "",
        headerVerbs, progressActive, compact, backBarRects)
    self._backBarRects   = backBarRects
    self._lastHeaderVerbs = headerVerbs  -- update() reads label by hover index
    cy = cy + (bbH or 0)

    -- 1.5) Name row - full-width below the back-bar. Title font (T.fontF4),
    --      generous vertical padding, surf1 bg matching body. Hit rect
    --      stamped to `self._nameRowRect`. When `_renaming` is true the
    --      name text is replaced by the lazy ZeD_TextInput child overlay.
    do
        local nameFont = T.fontF4
        local nameH    = T.fontF4H or ZeD.TM:getFontHeight(nameFont)
        local nameVPad = math.max(T.px(8), math.floor((T.fontF1H or T.px(10)) * 0.8))
        local nameHPad = math.max(T.px(10), math.floor((T.fontF1H or T.px(10)) * 1.0))
        local rowH     = nameH + nameVPad * 2
        local nbg      = T.surf1
        self:drawRect(0, cy, w, rowH, nbg.a or 1, nbg.r, nbg.g, nbg.b)
        local nsep = T.border
        self:drawRect(0, cy + rowH - T.px(1), w, T.px(1), nsep.a or 1, nsep.r, nsep.g, nsep.b)
        if self._renaming and self._renameInput then
            -- Position input across the name row (overlay)
            local inp = self._renameInput
            inp:setX(nameHPad)
            inp:setY(cy + math.floor((rowH - (T.inputH or rowH)) / 2))
            inp:setWidth(w - nameHPad * 2)
            inp:setVisible(true)
        else
            local nameStr = displayName
            local maxW = w - nameHPad * 2
            if ZeD.TM:MeasureStringX(nameFont, nameStr) > maxW then
                nameStr = ZeD.Atoms.truncateText(nameStr, nameFont, maxW)
            end
            local nc = T.text
            self:drawText(nameStr, nameHPad, cy + nameVPad,
                nc.r, nc.g, nc.b, nc.a or 1, nameFont)
            if self._renameInput then self._renameInput:setVisible(false) end
        end
        self._nameRowRect = {x = 0, y = cy, w = w, h = rowH}
        cy = cy + rowH
    end

    -- 2) Flag strip (FAV / NO-CRAFT / DISPOSE)
    local fsH = M.drawCardFlagStrip(self, 0, cy, w, marks, compact, flagRects)
    self._flagRects = flagRects
    cy = cy + (fsH or 0)

    -- 3) Progress band (renders only when getActiveAction(item) ~= nil)
    cancelRect = {}
    local pbH = M.drawCardProgressBand(self, 0, cy, w, item, compact, cancelRect)
    cy = cy + (pbH or 0)
    if pbH == 0 then cancelRect = nil end

    self._headH = cy   -- chrome height = sticky head

    -- 4) Body - stenciled below chrome.
    -- Reserve bottom space for the maintenance verb strip when present so the
    -- body doesn't render under it AND the scrollbar ends cleanly above it.
    -- Reserve scales with font height so larger text-size presets get
    -- proportional padding around the strip - without this, scroll content
    -- clips into the strip's visual footprint at larger fonts.
    local maintVerbs    = maintenanceVerbsForItem(item)
    local f1H_strip     = T.fontF1H or ZeD.TM:getFontHeight(T.fontF1)
    local vsBtnH        = T.px(22)                                          -- drawCardVerbStrip's hardcoded btn height
    local vsTopPad      = math.max(T.px(8), math.floor(f1H_strip * 0.7))    -- breathe above buttons
    local vsBotPad      = math.max(T.px(8), math.floor(f1H_strip * 0.7))    -- breathe below buttons (grow box room)
    local verbStripResvH = (#maintVerbs > 0) and (vsBtnH + vsTopPad + vsBotPad) or 0
    self._verbStripResvH = verbStripResvH
    local sbW = (self._sb and self._sb.visible) and self._sb.width or 0
    local bodyW = w - sbW
    local bodyH = self:getHeight() - self._headH - verbStripResvH
    if bodyH > 0 then
        self:setStencilRect(0, self._headH, bodyW, bodyH)
        -- Body inner padding scales with font height - generous breathing
        -- around the entire scrollable region per memory feedback_padding_preference.
        local bodyPad = math.max(compact and T.px(12) or T.px(14), math.floor((T.fontF1H or T.px(10)) * 1.0))
        local bodyX, bodyY = bodyPad, self._headH + bodyPad
        local scrollOff = self._scrollPixels or 0
        local innerW = bodyW - bodyPad * 2
        local cat = categoryOf(item)
        local contentH
        if cat == "Clothing" then
            contentH = renderClothingBody(self, item,
                bodyX, bodyY - scrollOff, innerW, compact, scrollOff,
                self._headH + bodyH)
        else
            contentH = renderGenericBody(self, item,
                bodyX, bodyY - scrollOff, innerW, compact, scrollOff,
                self._headH + bodyH)
        end
        self._contentH = (contentH or 0) + bodyPad * 2
        self:clearStencilRect()
    end

    -- 5) Maintenance verb strip - drawn AFTER body so it sits at the bottom
    --    of the chrome above the scrollbar; not part of scrollable content.
    --    Strip dimensions match the verbStripResvH computed above so the bg
    --    band, button position, and scroll reserve all stay in sync at any
    --    text size.
    if #maintVerbs > 0 then
        local vsRightEdge = w - (compact and T.px(8) or T.px(12))
        local vsBgY       = self:getHeight() - verbStripResvH
        local vsY         = vsBgY + vsTopPad
        local vsBg        = T.surf1
        self:drawRect(0, vsBgY, w, verbStripResvH,
            vsBg.a or 1, vsBg.r, vsBg.g, vsBg.b)
        M.drawCardVerbStrip(self, vsRightEdge, vsY, maintVerbs,
            progressActive, compact, verbStripRects)
    end

    -- 6) Stamp gamepad ring API fields
    stampGamepadFields(self, flagRects, verbStripRects, maintVerbs, cancelRect)

    -- 7) Focus outline overlay (existing S99/S118 behavior)
    if self._drawGpFocusOutline then self:_drawGpFocusOutline() end

    -- 8) 3-sided border (left / right / bottom) - preserved from prerender
    local bc = T.border
    local h  = self:getHeight()
    self:drawRect(0, 0, T.px(1), h, bc.a or 1, bc.r, bc.g, bc.b)
    self:drawRect(w - T.px(1), 0, T.px(1), h, bc.a or 1, bc.r, bc.g, bc.b)
    self:drawRect(0, h - T.px(1), w, T.px(1), bc.a or 1, bc.r, bc.g, bc.b)
end

-- ---------------------------------------------------------------------------
-- Public namespace exports - for Phase C integration callers
-- ---------------------------------------------------------------------------
ZeD.ItemCard.headerVerbsForContext   = headerVerbsForContext
ZeD.ItemCard.maintenanceVerbsForItem = maintenanceVerbsForItem
ZeD.ItemCard.topStatsForItem         = topStatsForItem
ZeD.ItemCard.readMarks               = readMarks
ZeD.ItemCard.categoryOf              = categoryOf
