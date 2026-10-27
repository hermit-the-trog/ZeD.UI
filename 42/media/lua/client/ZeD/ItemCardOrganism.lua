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

-- A zone's dock: an icon button (the push button's outline, the hover wash, the
-- controller's mark) holding the zone's glyph: "+" repairs a hole (in the warning
-- colour), "x" takes a patch off, a greyed "v" is a sound zone (nothing to do).
-- zCfg.focus = the focus mark's opts when the controller is on it.
-- @return the button's rect when it can be pressed, else nil
local _dockOpts, _dockGlyph = {}, "v"
local function _dockGlyphFn(p, ix, iy, s, c)
    local f = ZeD.T.fontF1
    local tw = ZeD.TM:MeasureStringX(f, _dockGlyph)
    local th = ZeD.TM:getFontHeight(f)
    p:drawText(_dockGlyph, ix + math.floor((s - tw) / 2), iy + math.floor((s - th) / 2), c.r, c.g, c.b, c.a or 1, f)
end
local function _drawDockCell(panel, x, y, size, zCfg)
    local T = ZeD.T
    local action = zCfg.action
    _dockGlyph = (action == "repair" and "+") or (action == "remove-patch" and "x") or "v"
    local o = _dockOpts
    o.disabled = not action
    o.hover = action and ZeD.Atoms.mouseIn(panel, x, y, size, size) or false
    o.focus = action and zCfg.focus or nil
    o.tint = (action == "repair") and T.warning or nil
    o.help = action and ZeD.tr(action == "repair" and "UI_ZeD_Card_HelpDockRepair" or "UI_ZeD_Card_HelpDockPatch") or nil
    o.iconSize = size - T.px(4)
    ZeD.Molecules.drawIconButton(panel, x, y, size, _dockGlyphFn, o)
    if action then return {x = x, y = y, w = size, h = size} end
    return nil
end

-- A zone's condition: the framed strip (ZeD.Atoms.drawFillBar) in the zone's
-- colour (its patch material, else its condition), at the list rows' height
local function _drawZoneBar(panel, x, y, w, rowH, ratio, segC)
    local A = ZeD.Atoms
    local h = (A.fillBarCompactH and A.fillBarCompactH()) or ZeD.T.px(8)
    A.drawFillBar(panel, x, y + math.floor((rowH - h) / 2), w, ratio, false, segC, h)
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

    local textY  = y + math.floor((rowH - fontH) / 2)
    local pct    = math.max(0, math.min(100, zCfg.pct or 100))
    local ratio  = pct / 100
    local segC   = _zoneSegColor(zCfg)

    -- Name (mono, T.text)
    local nameStr = zCfg.name or ""
    panel:drawText(nameStr, x + T.px(4), textY,
        T.text.r, T.text.g, T.text.b, T.text.a or 1, font)

    -- Bar: the framed strip in the zone's colour (the colour says the state, the figure is plain text)
    _drawZoneBar(panel, barX, y, barW, rowH, ratio, segC)

    -- Pct (mono, right-aligned)
    local pctStr   = tostring(math.floor(pct + 0.5)) .. "%"
    local pctTextW = ZeD.TM:MeasureStringX(font, pctStr)
    panel:drawText(pctStr, pctX + pctW - pctTextW, textY,
        T.text.r, T.text.g, T.text.b, T.text.a or 1, font)

    -- Dock cell, always drawn: an icon button, greyed for a sound zone. outDockRect
    -- only when it can be pressed, so the click router skips the greyed ones.
    local outDockRect = _drawDockCell(panel, dockX + math.floor((dockW - dockH) / 2), y + math.floor((rowH - dockH) / 2), dockH, zCfg)

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

    local pct   = math.max(0, math.min(100, zCfg.pct or 100))
    local ratio = pct / 100
    local segC  = _zoneSegColor(zCfg)

    -- Name (mono, T.text)
    panel:drawText(zCfg.name or "", x, nameY,
        T.text.r, T.text.g, T.text.b, T.text.a or 1, font)

    -- Pct (right-aligned in pctW, plain text: the bar carries the colour)
    local pctStr  = tostring(math.floor(pct + 0.5)) .. "%"
    local pctTW   = tm:MeasureStringX(font, pctStr)
    panel:drawText(pctStr, pctX + pctW - pctTW, pctY,
        T.text.r, T.text.g, T.text.b, T.text.a or 1, font)

    -- Bar: the framed strip in the zone's colour
    _drawZoneBar(panel, barX, y, barW, rowH, ratio, segC)

    -- Flag (right-aligned in flagW): the word in the text colour after a square
    -- mark in the state's colour (torn, worn, the patch's material)
    local flagStr  = "-"
    local flagC    = nil
    if zCfg.dock and zCfg.dock.flag then
        flagStr = zCfg.dock.flag
        if     flagStr == "TORN"          then flagStr, flagC = ZeD.tr("UI_ZeD_Card_FlagTorn"), T.danger
        elseif flagStr == "WORN"          then flagStr, flagC = ZeD.tr("UI_ZeD_Card_FlagWorn"), T.warning
        elseif flagStr == "Leather"       then flagStr, flagC = ZeD.tr("UI_ZeD_Card_FlagLeather"), T.matLeather or T.warning
        elseif flagStr == "Denim"         then flagStr, flagC = ZeD.tr("UI_ZeD_Card_FlagDenim"),   T.matDenim   or T.info
        elseif flagStr == "Fabric"
            or flagStr == "Ripped Sheets" then flagStr, flagC = ZeD.tr("UI_ZeD_Card_FlagFabric"),  T.matFabric  or T.text
        end
        flagStr = ZeD.textCase(flagStr)
    end
    local flagTW = tm:MeasureStringX(font, flagStr)
    local ftc = flagC and T.text or T.textDim
    panel:drawText(flagStr, flagX + flagW - flagTW, flagY,
        ftc.r, ftc.g, ftc.b, ftc.a or 1, font)
    if flagC then
        local sq = T.px(6)
        ZeD.Atoms.drawStatusDot(panel, flagX + flagW - flagTW - T.px(4) - sq, flagY + math.floor((fontH - sq) / 2), flagC, sq)
    end

    -- Dock cell: the same icon button as 220w
    local outDockRect = _drawDockCell(panel, dockX + math.floor((dockW - dockH) / 2), y + math.floor((rowH - dockH) / 2), dockH, zCfg)

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
            -- the disclosure: the pointer's hover wash and its help, then the triangle and the label
            local textY  = cy + math.floor((hdrH - fontH) / 2)
            if ZeD.Atoms.mouseIn(card, x, cy, w, hdrH) then
                local hv = T.hover
                card:drawRect(x, cy, w, hdrH, hv.a, hv.r, hv.g, hv.b)
                ZeD.Help.set(card, ZeD.tr(expanded and "UI_ZeD_Inv_CatFoldHelp" or "UI_ZeD_Inv_CatOpenHelp"))
            end
            local tri = math.min(T.px(8), hdrH - T.px(4))
            local triC = T.textDim
            if expanded then ZeD.Atoms.drawTriangleDown(card, x, cy + math.floor((hdrH - tri) / 2), tri, triC)
            else ZeD.Atoms.drawTriangleRight(card, x, cy + math.floor((hdrH - tri) / 2), tri, triC) end
            local labelC = T.textHead
            local zonesTxt = ZeD.textCase(ZeD.tr("UI_ZeD_Card_Zones"))
            card:drawText(zonesTxt, x + T.px(14), textY,
                labelC.r, labelC.g, labelC.b, labelC.a or 1, font)
            local labelEndX = x + T.px(14) + tm:MeasureStringX(font, zonesTxt) + T.px(8)
            local sq = T.px(6)

            if compact then
                -- Right-aligned overall %: plain text after its status square
                local sumW = tm:MeasureStringX(font, condPctStr)
                local tc = T.text
                card:drawText(condPctStr, x + w - sumW, textY, tc.r, tc.g, tc.b, tc.a or 1, font)
                ZeD.Atoms.drawStatusDot(card, x + w - sumW - T.px(4) - sq, textY + math.floor((fontH - sq) / 2), condColor, sq)
            else
                -- Inline composition: [triangle+label][seg-bar fills][%][Dirty][Wet]
                -- The soil as tags (the library's: outlined, a square mark in the
                -- soil's colour), right side first, then % left of them, the
                -- seg-bar fills the rest.
                local chipGap   = T.px(6)
                local chips = {}
                if soil and soil.dirt then
                    chips[#chips + 1] = {label = ZeD.tr("Tooltip_clothing_dirty"), color = T.soiledDirt or T.warning}
                end
                if soil and soil.wet then
                    chips[#chips + 1] = {label = ZeD.tr("UI_ZeD_Card_WetPct", tostring(soil.wet) .. "%"),
                                         color = T.soiledWet or T.info}
                end

                -- Compute right-anchored cursor walking left
                local chipH = T.px(16)
                local rightCursor = x + w
                local chipRects = {}
                for i = #chips, 1, -1 do
                    local c = chips[i]
                    local cw = tm:MeasureStringX(T.fontF1, ZeD.Atoms.textCase(c.label)) + T.px(10) + sq + T.px(4)
                    rightCursor = rightCursor - cw
                    chipRects[i] = {x = rightCursor, w = cw, y = cy + math.floor((hdrH - chipH) / 2), h = chipH}
                    if i > 1 then rightCursor = rightCursor - chipGap end
                end
                if #chips > 0 then rightCursor = rightCursor - chipGap end

                -- Overall % (right-aligned, left of the tags): plain text after its status square
                local sumW = tm:MeasureStringX(font, condPctStr)
                local sumX = rightCursor - sumW
                local tc = T.text
                card:drawText(condPctStr, sumX, textY, tc.r, tc.g, tc.b, tc.a or 1, font)
                ZeD.Atoms.drawStatusDot(card, sumX - T.px(4) - sq, textY + math.floor((fontH - sq) / 2), condColor, sq)
                local sumLeftEdge = sumX - T.px(4) - sq - T.px(8)

                -- Seg-bar fills middle (between label end and % left edge)
                local barX = labelEndX
                local barW = sumLeftEdge - barX
                if barW > T.px(20) then
                    local barH = math.max(math.floor(fontH * 0.7), T.px(10))
                    local barY = cy + math.floor((hdrH - barH) / 2)
                    _drawZoneSegBar(card, barX, barY, barW, barH, zones)
                end

                -- Draw the tags (after seg-bar so they layer cleanly)
                for i, c in ipairs(chips) do
                    local r = chipRects[i]
                    M.drawTag(card, r.x, r.y, c.label, c.color)
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
                    -- (a flag's word is drawn in sentence case after its 6u mark and 4u gap)
                    local fW = tm:MeasureStringX(probeFont, ZeD.textCase(flagStr)) + T.px(4)
                        + ((flagStr ~= "-") and T.px(10) or 0)
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
                    -- the group's word, as a category row's: F1, sentence case, toneLo
                    local hdrTY = cy + math.floor((groupHdrH - fontH) / 2)
                    local hdrC  = T.toneLo or T.textDim
                    card:drawText(ZeD.textCase(ZeD.tr(groupName)), x, hdrTY,
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
                    focus  = card.focusFor and card:focusFor("dock_" .. i) or nil,
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
            local textY = cy + math.floor((hdrH - labelH) / 2)
            if ZeD.Atoms.mouseIn(card, x, cy, w, hdrH) then
                local hv = T.hover
                card:drawRect(x, cy, w, hdrH, hv.a, hv.r, hv.g, hv.b)
                ZeD.Help.set(card, ZeD.tr(expanded and "UI_ZeD_Inv_CatFoldHelp" or "UI_ZeD_Inv_CatOpenHelp"))
            end
            local tri = T.px(8)
            if expanded then ZeD.Atoms.drawTriangleDown(card, x, cy + math.floor((hdrH - tri) / 2), tri, T.textDim)
            else ZeD.Atoms.drawTriangleRight(card, x, cy + math.floor((hdrH - tri) / 2), tri, T.textDim) end
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
-- The help line's words for a card verb (by its id; the label is its button word)
-- ---------------------------------------------------------------------------
local VERB_HELP = {
    EQUIP = "UI_ZeD_Card_HelpEquip", UNEQUIP = "UI_ZeD_Card_HelpUnequip", DROP = "UI_ZeD_Card_HelpDrop",
    TAKE = "UI_ZeD_Card_HelpTake", EAT = "UI_ZeD_Card_HelpEat", READ = "UI_ZeD_Card_HelpRead",
    USE = "UI_ZeD_Card_HelpUse", DRINK = "UI_ZeD_Card_HelpDrink", WEAR = "UI_ZeD_Card_HelpWear",
    ["OFF HAND"] = "UI_ZeD_Card_HelpOffHand", MORE = "UI_ZeD_Card_HelpMore",
    wash = "UI_ZeD_Card_HelpWash", repair_all = "UI_ZeD_Card_HelpRepairHoles", pad_all = "UI_ZeD_Card_HelpPad",
    repair = "UI_ZeD_Card_HelpRepair", sharpen = "UI_ZeD_Card_HelpSharpen",
}
local function verbHelp(id, label)
    local k = VERB_HELP[id]
    if not k then return nil end
    return ZeD.tr(k, ZeD.btnCase(label or ""))
end

-- The care verbs (Wash, Repair, Pad, Sharpen) sorted by what the character can
-- do now (cohesion spec 9a, ZeD.Disclose.split over the card's verbAbility):
-- shown = in the band (in Show all, the ones it can't do yet greyed, each with
-- its NEEDS line), hidden = behind the folded row. One that makes no sense now
-- (Repair on a garment with no holes) is gone.
local function careVerbs(card, item)
    local list = maintenanceVerbsForItem(item)
    if #list == 0 or not ZeD.Disclose then return list, {} end
    for _, v in ipairs(list) do
        local a = card.verbAbility and card:verbAbility(v.key) or nil
        if a then v.canDo, v.sensible, v.needs, v.hint = a.canDo, a.sensible, a.needs, a.hint
        else v.canDo = true end
    end
    return ZeD.Disclose.split(list)
end

-- The care verbs' band at the card's foot (the library's band: surface 2, its
-- structure line on top, push buttons at the right); a verb the character
-- can't do yet is greyed (Show all) and still says why when pressed.
-- Returns the buttons' rects (card-local), in the verbs' order.
local _careSpec = { buttons = {} }
local function drawCareBand(card, y, w, verbs, progressActive)
    local btns = _careSpec.buttons
    for i = #btns, #verbs + 1, -1 do btns[i] = nil end
    for i, v in ipairs(verbs) do
        local b = btns[i] or {}
        btns[i] = b
        b.label, b.id = v.label, v.key
        b.disabled = (progressActive or v.canDo == false) and true or false
        b.focus = card.focusFor and card:focusFor("verb_" .. tostring(v.key)) or nil
        b.help = verbHelp(v.key, v.label)
    end
    local _, out = ZeD.Molecules.drawBand(card, 0, y, w, _careSpec)
    return out.buttons
end

-- After the card's body: the NEEDS line of each greyed care verb (Show all),
-- then the folded row of the ones the character can't do yet (Folded), with
-- its greyed verbs and their NEEDS lines while open (the library's
-- drawMoreRow). Stamps the row's and the verbs' absolute rects for the clicks
-- and the controller. Returns the height used.
local function drawCareNeeds(card, x, y, w, shown, hidden)
    local M, T, DS = ZeD.Molecules, ZeD.T, ZeD.Disclose
    card._moreRowRect, card._moreVerbRects, card._moreVerbs = nil, nil, nil
    if not DS then return 0 end
    local h = 0
    for _, v in ipairs(shown) do
        if v.canDo == false then
            h = h + M.drawNeedsLine(card, x, y + h, w, DS.needsLine(v)) + T.px(4)
        end
    end
    if #hidden == 0 then return h end
    if h > 0 then h = h + T.px(4) end
    local key = "itemcard:" .. tostring(categoryOf(card.item))
    card._moreKey = key
    for _, v in ipairs(hidden) do
        v.focus = card.focusFor and card:focusFor("more_" .. tostring(v.key)) or nil
        v.help = DS.needsLine(v)
    end
    local rh, rowRect, verbRects = M.drawMoreRow(card, x, y + h, w, hidden, key,
        { focus = card.focusFor and card:focusFor("more_row") or nil })
    local ax, ay = card:getAbsoluteX(), card:getAbsoluteY()
    if rowRect then card._moreRowRect = { x = ax + rowRect.x, y = ay + rowRect.y, w = rowRect.w, h = rowRect.h } end
    card._moreVerbs, card._moreVerbRects = hidden, {}
    for i, r in ipairs(verbRects or {}) do card._moreVerbRects[i] = { x = ax + r.x, y = ay + r.y, w = r.w, h = r.h } end
    return h + rh
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
    -- each verb's help line words and, on the one the controller is on, its focus mark
    for i, v in ipairs(headerVerbs) do
        v.help = verbHelp(v.id, v.label)
        v.focus = self.focusFor and self:focusFor("hverb_" .. i) or nil
    end
    -- the back key's focus mark (when the controller is on it) and its help line words
    local bf = self.focusFor and self:focusFor("back") or nil
    local bbo = self._backBarOpts
    if not bbo then bbo = {}; self._backBarOpts = bbo end
    bbo.focusId, bbo.focus = bf and "back" or nil, bf
    bbo.backHelp = ZeD.tr("UI_ZeD_Card_HelpBack")
    local bbH = M.drawCardBackBar(self, 0, cy, w, "",
        headerVerbs, progressActive, compact, backBarRects, bbo)
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
        -- (no fill of its own: the card's drawer surface is under it, one layer)
        local nsep = T.border
        self:drawRect(0, cy + rowH - T.px(1), w, T.px(1), nsep.a or 1, nsep.r, nsep.g, nsep.b)
        -- A press renames: the pointer's hover wash and help, the controller's mark
        local onName = false
        if not self._renaming then
            if ZeD.Atoms.mouseIn(self, 0, cy, w, rowH - T.px(1)) then
                local hv = T.hover
                self:drawRect(0, cy, w, rowH - T.px(1), hv.a, hv.r, hv.g, hv.b)
                ZeD.Help.set(self, ZeD.tr("UI_ZeD_Card_HelpRename"))
            end
            local nf = self.focusFor and self:focusFor("name_row") or nil
            if nf then onName = ZeD.Focus.mark(self, 0, cy, w, rowH - T.px(1), nf) and true or false end
        end
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
            local nc = onName and T.textOnFocus or T.text
            self:drawText(nameStr, nameHPad, cy + nameVPad,
                nc.r, nc.g, nc.b, nc.a or 1, nameFont)
            if self._renameInput then self._renameInput:setVisible(false) end
        end
        self._nameRowRect = {x = 0, y = cy, w = w, h = rowH}
        cy = cy + rowH
    end

    -- 2) Flag strip (FAV / NO-CRAFT / DISPOSE); the chip the controller is on carries the mark
    local fo = self._flagOpts
    if not fo then fo = { focusParts = {} }; self._flagOpts = fo end
    local fp = fo.focusParts
    if self.focusFor then
        fp.fav, fp.nocraft, fp.dispose =
            self:focusFor("toggle_fav"), self:focusFor("toggle_protect"), self:focusFor("toggle_unwanted")
    else
        fp.fav, fp.nocraft, fp.dispose = nil, nil, nil
    end
    local fsH = M.drawCardFlagStrip(self, 0, cy, w, marks, compact, flagRects, fo)
    self._flagRects = flagRects
    cy = cy + (fsH or 0)

    -- 3) Progress band (renders only when getActiveAction(item) ~= nil)
    cancelRect = {}
    local pbo = self._progressOpts
    if not pbo then pbo = {}; self._progressOpts = pbo end
    pbo.focus = self.focusFor and self:focusFor("cancel_band") or nil   -- Cancel's mark, under its icon
    local pbH = M.drawCardProgressBand(self, 0, cy, w, item, compact, cancelRect, pbo)
    cy = cy + (pbH or 0)
    if pbH == 0 then cancelRect = nil end

    self._headH = cy   -- chrome height = sticky head

    -- 4) Body - stenciled below chrome.
    -- Reserve bottom space for the care verbs' band when present so the body
    -- doesn't render under it AND the scrollbar ends cleanly above it.
    -- The care verbs the character can do (or, in Show all, every sensible one)
    -- sit in the band at the foot (the library's band, M.bandH() tall); none
    -- left, no band. The rest wait behind the folded row after the body.
    local maintVerbs, hiddenVerbs = careVerbs(self, item)
    local verbStripResvH = (#maintVerbs > 0) and M.bandH() or 0
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
        -- what the character can't do yet: NEEDS lines / the folded row, after the content
        contentH = (contentH or 0) + drawCareNeeds(self, bodyX, bodyY - scrollOff + (contentH or 0), innerW, maintVerbs, hiddenVerbs)
        self._contentH = (contentH or 0) + bodyPad * 2
        self:clearStencilRect()
    else
        self._moreRowRect, self._moreVerbRects, self._moreVerbs = nil, nil, nil
    end

    -- 5) The care verbs' band - drawn AFTER body so it sits at the foot, under
    --    the scrollbar's end; not part of scrollable content. Its height is the
    --    band's own (M.bandH()), the reserve above.
    if #maintVerbs > 0 then
        local rects = drawCareBand(self, self:getHeight() - verbStripResvH, w, maintVerbs, progressActive)
        for i, r in ipairs(rects or {}) do verbStripRects[i] = r end
    end

    -- 6) Stamp gamepad ring API fields
    stampGamepadFields(self, flagRects, verbStripRects, maintVerbs, cancelRect)

    -- 7) The card has no border of its own (the window's lines bound it); only
    --    the edge where it lies over a tab's content (its host sets overlayEdge)
    if self.drawOverlayEdge then self:drawOverlayEdge() end
end

-- ---------------------------------------------------------------------------
-- Public namespace exports - for Phase C integration callers
-- ---------------------------------------------------------------------------
ZeD.ItemCard.headerVerbsForContext   = headerVerbsForContext
ZeD.ItemCard.maintenanceVerbsForItem = maintenanceVerbsForItem
ZeD.ItemCard.topStatsForItem         = topStatsForItem
ZeD.ItemCard.readMarks               = readMarks
ZeD.ItemCard.categoryOf              = categoryOf
