-- ZeD-UI/42/media/lua/client/ZeD/IdentityTab.lua
-- ============================================================================
-- IDENTITY TAB — KY driver's license card + character traits.
--   Zone A: License card (bust portrait left, data fields right)
--   Zone B: Traits (positive/negative badges, two-column grid with icons)
-- Fixed KY color palette for the license. Traits use ZeD theme tokens.
--
-- Reference: Late-1980s Indiana operator's license layout.
-- Code ported from CharInfoOverhaul/CharInfoPanel.lua.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ZeD_HairBeard"

ZeD = ZeD or {}
ZeD.IdentityTab = {}

-- ============================================================================
-- KY LICENSE COLOR PALETTE (constant, theme-independent)
-- ============================================================================

local KY = {
    blue    = { r = 27/255,  g = 28/255,  b = 146/255, a = 1.0 },
    cardBg  = { r = 232/255, g = 228/255, b = 218/255, a = 1.0 },
    skyBlue = { r = 140/255, g = 195/255, b = 232/255, a = 1.0 },
    ink     = { r = 30/255,  g = 50/255,  b = 80/255,  a = 1.0 },
    inkDim  = { r = 30/255,  g = 50/255,  b = 80/255,  a = 0.65 },
    laminate = { r = 210/255, g = 206/255, b = 198/255, a = 1.0 },
}

-- ============================================================================
-- LAYOUT CONSTANTS
-- ============================================================================

local CARD_PAD   = 8     -- padding inside drawer to card edge
local LAMINATE_W = 8     -- clear laminate border around perimeter
local PHOTO_W    = 150   -- width of the left column (photo + padding)
local PHOTO_SIZE = 120   -- 120x120 square photo frame
local FIELD_PAD  = 16    -- inner padding within card body for text fields
local TRAIT_ROW_H = 28   -- height of each trait row in the grid
local TRAIT_ICON_SZ = 18 -- trait icon size

-- ============================================================================
-- LICENSE CARD ROUNDED RECT (10px bevel — larger than ZeD's standard 2px)
-- Pixel-art quarter-circle: each row specifies an inset from the edge.
-- ============================================================================

local CARD_RADIUS = { 10, 7, 5, 4, 3, 2, 2, 1, 1, 1 }

local function fillRoundedCard(panel, x, y, w, h, r, g, b, a)
    local T = ZeD.T  -- S124 scale: design row i covers [T.px(i - 1), T.px(i)) so rows tile without gaps
    -- Top rounded rows
    for i, inset in ipairs(CARD_RADIUS) do
        panel:drawRect(x + T.px(inset), y + T.px(i - 1), w - T.px(inset) * 2, T.px(i) - T.px(i - 1), a, r, g, b)
    end
    -- Bottom rounded rows
    for i, inset in ipairs(CARD_RADIUS) do
        panel:drawRect(x + T.px(inset), y + h - T.px(i), w - T.px(inset) * 2, T.px(i) - T.px(i - 1), a, r, g, b)
    end
    -- Middle fill
    local midTop = T.px(#CARD_RADIUS)
    local midH   = h - midTop * 2
    if midH > 0 then
        panel:drawRect(x, y + midTop, w, midH, a, r, g, b)
    end
end

local function borderRoundedCard(panel, x, y, w, h, r, g, b, a)
    local T = ZeD.T
    -- Top bevel outline (1px edge, not full scanlines)
    for i, inset in ipairs(CARD_RADIUS) do
        local row = T.px(i - 1)
        local rowH = T.px(i) - row  -- S124 scale: design row i covers [T.px(i - 1), T.px(i))
        if i == 1 then
            -- Outermost row: full scanline (the tip of the bevel)
            panel:drawRect(x + T.px(inset), y + row, w - T.px(inset) * 2, rowH, a, r, g, b)
        else
            local prevInset = CARD_RADIUS[i - 1]
            local step = T.px(prevInset) - T.px(inset)
            if step > 0 then
                panel:drawRect(x + T.px(inset), y + row, step, rowH, a, r, g, b)
                panel:drawRect(x + w - T.px(inset) - step, y + row, step, rowH, a, r, g, b)
            else
                panel:drawRect(x + T.px(inset), y + row, T.px(1), rowH, a, r, g, b)
                panel:drawRect(x + w - T.px(inset) - T.px(1), y + row, T.px(1), rowH, a, r, g, b)
            end
        end
    end
    -- Bottom bevel outline (1px edge)
    for i, inset in ipairs(CARD_RADIUS) do
        local row = h - T.px(i)
        local rowH = T.px(i) - T.px(i - 1)
        if i == 1 then
            panel:drawRect(x + T.px(inset), y + row, w - T.px(inset) * 2, rowH, a, r, g, b)
        else
            local prevInset = CARD_RADIUS[i - 1]
            local step = T.px(prevInset) - T.px(inset)
            if step > 0 then
                panel:drawRect(x + T.px(inset), y + row, step, rowH, a, r, g, b)
                panel:drawRect(x + w - T.px(inset) - step, y + row, step, rowH, a, r, g, b)
            else
                panel:drawRect(x + T.px(inset), y + row, T.px(1), rowH, a, r, g, b)
                panel:drawRect(x + w - T.px(inset) - T.px(1), y + row, T.px(1), rowH, a, r, g, b)
            end
        end
    end
    -- Side edges
    local midTop = T.px(#CARD_RADIUS)
    local midH   = h - midTop * 2
    if midH > 0 then
        panel:drawRect(x,         y + midTop, T.px(1), midH, a, r, g, b)
        panel:drawRect(x + w - T.px(1), y + midTop, T.px(1), midH, a, r, g, b)
    end
end

-- ============================================================================
-- DATA HELPERS (ported from CharInfoOverhaul CharInfoPanel.lua)
-- ============================================================================

local function getHairColorName(char)
    local hc = char:getHumanVisual():getHairColor()
    if not hc then return ZeD.tr("UI_ZeD_Identity_Unknown") end
    local r, g, b = hc:getRedFloat(), hc:getGreenFloat(), hc:getBlueFloat()
    local brightness = r * 0.299 + g * 0.587 + b * 0.114
    -- vanilla's paint-colour words where it has them (ContextMenu_*), else ZeD's
    if brightness > 0.75 then
        if r > 0.85 and g > 0.85 then return getText("ContextMenu_White") end
        return ZeD.tr("UI_ZeD_Identity_HairBlonde")
    elseif brightness > 0.5 then
        if r > g + 0.15 then return ZeD.tr("UI_ZeD_Identity_HairAuburn") end
        return getText("ContextMenu_Light_Brown")
    elseif brightness > 0.3 then
        if r > g + 0.1 and r > 0.45 then return getText("ContextMenu_Red") end
        if r > 0.35 and g > 0.25 then return getText("ContextMenu_Brown") end
        return ZeD.tr("UI_ZeD_Identity_HairDarkBrown")
    elseif brightness > 0.15 then
        if r > g + 0.08 then return ZeD.tr("UI_ZeD_Identity_HairDarkRed") end
        return ZeD.tr("UI_ZeD_Identity_HairDarkBrown")
    end
    return getText("ContextMenu_Black")
end

local function getHairStyleName(char)
    local hairModel = char:getHumanVisual():getHairModel()
    if not hairModel or hairModel == "" then return getText("IGUI_Hair_Bald") end
    local style
    if char:isFemale() then
        style = getHairStylesInstance():FindFemaleStyle(hairModel)
    else
        style = getHairStylesInstance():FindMaleStyle(hairModel)
    end
    if style and style:getName() and style:getName() ~= "" then
        return getText("IGUI_Hair_" .. style:getName())
    end
    return getText("IGUI_Hair_Bald")
end

local function getBeardStyleName(char)
    if char:isFemale() then return ZeD.tr("UI_ZeD_Identity_NotApplicable") end
    local beardModel = char:getHumanVisual():getBeardModel()
    if not beardModel or beardModel == "" then return getText("IGUI_None") end
    local style = getBeardStylesInstance():FindStyle(beardModel)
    if style and style:getName() and style:getName() ~= "" then
        return getText("IGUI_Beard_" .. style:getName())
    end
    return getText("IGUI_None")
end

local function getBodyHairName(char)
    local idx = char:getHumanVisual():getBodyHairIndex()
    if not idx or idx <= 0 then return getText("IGUI_None") end
    if idx == 1 then return ZeD.tr("UI_ZeD_Identity_BodyHairLight") end
    if idx == 2 then return ZeD.tr("UI_ZeD_Identity_BodyHairNormal") end
    if idx == 3 then return ZeD.tr("UI_ZeD_Identity_BodyHairHeavy") end
    if idx == 4 then return ZeD.tr("UI_ZeD_Identity_BodyHairVeryHeavy") end
    return ZeD.tr("UI_ZeD_Identity_BodyHairLevel", idx)
end

local function getFavouriteWeapon(char)
    local best, bestCount = nil, 0
    for key, val in pairs(char:getModData()) do
        local weapon = string.match(key, "^Fav:(.+)")
        if weapon and val > bestCount then
            best = weapon
            bestCount = val
        end
    end
    return best or getText("IGUI_None")
end

-- ============================================================================
-- TRAIT DATA (ported from CharInfoOverhaul)
-- ============================================================================

local function getCharacterTraitsSorted(char)
    local positive, negative = {}, {}
    local knownTraits = char:getCharacterTraits():getKnownTraits()
    if not knownTraits then return positive, negative end

    for i = 0, knownTraits:size() - 1 do
        local traitId = knownTraits:get(i)
        local traitDef = CharacterTraitDefinition.getCharacterTraitDefinition(traitId)
        if traitDef then
            local entry = {
                name    = traitDef:getLabel() or traitId,
                desc    = traitDef:getDescription() or "",
                cost    = traitDef:getCost(),
                texture = traitDef:getTexture(),
            }
            if entry.cost >= 0 then
                table.insert(positive, entry)
            else
                table.insert(negative, entry)
            end
        end
    end

    table.sort(positive, function(a, b) return a.name < b.name end)
    table.sort(negative, function(a, b) return a.name < b.name end)
    return positive, negative
end

-- ============================================================================
-- DATA AGGREGATION
-- ============================================================================

function ZeD.IdentityTab.gatherData(playerObj)
    local data = {
        surname    = ZeD.tr("UI_ZeD_Identity_Unknown"),
        forename   = "",
        weightStr  = ZeD.tr("UI_ZeD_Identity_WeightKg", "--"),
        sexStr     = "--",
        profession = "--",
        hairStyle  = "--",
        bodyHair   = "--",
        facialHair = "--",
        hairColor  = "--",
        timeSurv   = "--",
        favWeapon  = getText("IGUI_None"),
        zKills     = "0",
        posTraits  = {},
        negTraits  = {},
    }

    if not playerObj then return data end

    local desc = playerObj:getDescriptor()
    if desc then
        data.surname  = desc:getSurname()  or ZeD.tr("UI_ZeD_Identity_Unknown")
        data.forename = desc:getForename() or ""
    end

    local weight = math.floor(playerObj:getNutrition():getWeight())
    data.weightStr  = ZeD.tr("UI_ZeD_Identity_WeightKg", weight)
    data.sexStr     = playerObj:isFemale() and getText("IGUI_char_Female") or getText("IGUI_char_Male")
    if desc and desc:getCharacterProfession() then
        local prof    = desc:getCharacterProfession()
        -- CharacterProfessionDefinition.getCharacterProfessionDefinition() gives the Lua-side
        -- definition object which has getUIName() — the translated display string
        local profDef = CharacterProfessionDefinition.getCharacterProfessionDefinition(prof)
        local raw = (profDef and profDef:getUIName()) or prof:getName() or "--"
        -- Title Case: Kahlua2 doesn't support gsub function replacement,
        -- so iterate words manually instead
        local words = {}
        for word in raw:gmatch("%S+") do
            words[#words + 1] = ZeD.upper(word:sub(1, 1)) .. word:sub(2):lower()
        end
        data.profession = #words > 0 and table.concat(words, " ") or raw
    end
    data.hairStyle  = getHairStyleName(playerObj)
    data.bodyHair   = getBodyHairName(playerObj)
    data.facialHair = getBeardStyleName(playerObj)
    data.hairColor  = getHairColorName(playerObj)
    data.zKills     = tostring(playerObj:getZombieKills())
    data.favWeapon  = getFavouriteWeapon(playerObj)

    if instanceof(playerObj, "IsoPlayer") then
        data.timeSurv = playerObj:getTimeSurvived() or "--"
    end

    data.posTraits, data.negTraits = getCharacterTraitsSorted(playerObj)

    return data
end

-- ============================================================================
-- ZONE A HEIGHT — license card (header + body)
-- ============================================================================

local function measureZoneAH()
    local T = ZeD.T
    local secFH  = ZeD.TM:getFontHeight(T.fontF1)
    local bodyFH = ZeD.TM:getFontHeight(T.fontF2)
    local headerH = secFH + bodyFH + T.px(20)
    local bodyH  = T.px(FIELD_PAD)                          -- top padding
    bodyH = bodyH + secFH + T.px(12)                        -- name row + gap
    bodyH = bodyH + (bodyFH * 2 + T.px(10)) * 3             -- 3 field rows
    bodyH = bodyH + T.px(4) + bodyFH + T.px(1) + bodyFH + T.px(10)      -- time survived
    bodyH = bodyH + T.px(4) + bodyFH + T.px(1) + bodyFH           -- weapon + kills
    bodyH = bodyH + T.px(FIELD_PAD)                          -- bottom padding
    return T.px(CARD_PAD) + T.px(LAMINATE_W) + headerH + bodyH + T.px(LAMINATE_W) + T.px(CARD_PAD)
end

-- ============================================================================
-- ZONE B HEIGHT — traits section
-- ============================================================================

local function measureZoneBH(data)
    local T = ZeD.T
    local pad   = T.sp.sm
    local h = pad + T.px(20) + T.sp.afterGroove  -- section head (20u, its line under it)

    -- Positive traits
    if #data.posTraits > 0 then
        h = h + T.px(15) + T.sp.xs  -- "Positive" category row (15u)
        local rows = math.ceil(#data.posTraits / 2)
        h = h + rows * (T.px(TRAIT_ROW_H) + T.px(2))
        h = h + T.sp.sm
    end

    -- Negative traits
    if #data.negTraits > 0 then
        h = h + T.px(15) + T.sp.xs  -- "Negative" category row (15u)
        local rows = math.ceil(#data.negTraits / 2)
        h = h + rows * (T.px(TRAIT_ROW_H) + T.px(2))
        h = h + T.sp.sm
    end

    return h
end

-- ============================================================================
-- RENDERER — ZONE A: License card background
-- ============================================================================

local function renderLicenseBackground(panel, win, x, drawY, w)
    local A   = ZeD.Atoms
    local T   = ZeD.T
    local pad = T.px(CARD_PAD)
    local lam = T.px(LAMINATE_W)
    local secFH  = ZeD.TM:getFontHeight(T.fontF1)
    local bodyFH = ZeD.TM:getFontHeight(T.fontF2)
    local headerH = secFH + bodyFH + T.px(20)

    -- Outer laminate shell (rounded corners)
    local cardX = x + pad
    local cardW = w - pad * 2
    local cardBodyH = measureZoneAH() - T.px(CARD_PAD) * 2 - T.px(LAMINATE_W) * 2 - headerH
    local totalH = lam * 2 + headerH + cardBodyH

    fillRoundedCard(panel, cardX, drawY + pad, cardW, totalH,
        KY.laminate.r, KY.laminate.g, KY.laminate.b, KY.laminate.a)

    -- Inner printed area (square corners, inset by laminate width)
    local innerX = cardX + lam
    local innerY = drawY + pad + lam
    local innerW = cardW - lam * 2

    -- KY header strip (blue rect + texture overlay)
    panel:drawRect(innerX, innerY, innerW, headerH,
        1.0, KY.blue.r, KY.blue.g, KY.blue.b)
    local headerTex = getTexture("media/textures/ZeD/Kentucky-dl-head.png")
    if headerTex then
        panel:drawTextureScaledAspect(headerTex, innerX, innerY, innerW, headerH, 1.0, 1.0, 1.0, 1.0)
    end

    -- Card body (cream rect)
    local innerCardY = innerY + headerH
    panel:drawRect(innerX, innerCardY, innerW, cardBodyH,
        1.0, KY.cardBg.r, KY.cardBg.g, KY.cardBg.b)

    -- Sky blue photo frame (120x120 bust or full left column expanded)
    -- Coords hoisted so we can publish to win for avatar overlay positioning (Q52)
    local photoX = innerX + math.floor((T.px(PHOTO_W) - T.px(PHOTO_SIZE)) / 2)
    local photoY = innerCardY + T.px(FIELD_PAD)
    if win._identityPhotoExpanded then
        panel:drawRect(innerX, innerCardY, T.px(PHOTO_W), cardBodyH,
            1.0, KY.skyBlue.r, KY.skyBlue.g, KY.skyBlue.b)
        win._identityPhotoRect = { x = innerX, y = innerCardY, w = T.px(PHOTO_W), h = cardBodyH, expanded = true }
    else
        A.fillRounded(panel, photoX, photoY, T.px(PHOTO_SIZE), T.px(PHOTO_SIZE),
            KY.skyBlue.r, KY.skyBlue.g, KY.skyBlue.b, 1.0)
        win._identityPhotoRect = { x = photoX, y = photoY, w = T.px(PHOTO_SIZE), h = T.px(PHOTO_SIZE) }
    end
    -- Click zone for toggle (covers the left photo column area)
    win._identityPhotoZone = { x = innerX, y = innerCardY, w = T.px(PHOTO_W), h = cardBodyH }

    -- Thin border around the outer laminate edge (10px bevel)
    borderRoundedCard(panel, cardX, drawY + pad, cardW, totalH,
        KY.blue.r, KY.blue.g, KY.blue.b, 0.3)
end

-- ============================================================================
-- RENDERER — ZONE A: License card text overlay
-- ============================================================================

local function renderLicenseText(panel, win, data, x, drawY, w)
    local T    = ZeD.T
    local pad  = T.px(CARD_PAD)
    local lam  = T.px(LAMINATE_W)
    local secFH  = ZeD.TM:getFontHeight(T.fontF1)
    local bodyFH = ZeD.TM:getFontHeight(T.fontF2)
    local headerH = secFH + bodyFH + T.px(20)

    local cardY = drawY + pad + lam + headerH
    local dataX = x + pad + lam + T.px(PHOTO_W) + T.px(FIELD_PAD)
    local dataW = w - pad * 2 - lam * 2 - T.px(PHOTO_W) - T.px(FIELD_PAD) * 2
    local rowY  = cardY + T.px(FIELD_PAD)

    -- Name row
    local displayName = data.surname .. ", " .. data.forename
    local tm = ZeD.TM
    ZeD.Text.draw(panel, ZeD.Font.sdf.head, displayName, dataX, rowY, ZeD.Text.zoomPx(17), 0.07, 0.07, 0.07, 1.0, "l")   -- S124: 17 px design heading on the distance-field face

    -- Weight pill
    local wtW = tm:MeasureStringX(T.fontF2, data.weightStr)
    local pillX = dataX + dataW - wtW - T.px(12)
    local pillY = rowY + T.px(2)
    panel:drawRect(pillX, pillY, wtW + T.px(10), bodyFH + T.px(4),
        0.1, KY.blue.r, KY.blue.g, KY.blue.b)
    panel:drawText(data.weightStr, pillX + T.px(5), pillY + T.px(2),
        KY.ink.r, KY.ink.g, KY.ink.b, 0.85, T.fontF2)
    rowY = rowY + bodyFH + T.px(12)

    -- Two-column data grid
    local colW = math.floor(dataW / 2)
    local fields = {
        { getText("IGUI_char_Sex"),                data.sexStr,     ZeD.tr("UI_ZeD_Identity_Profession"), data.profession },
        { ZeD.tr("UI_ZeD_Identity_HairStyle"),     data.hairStyle,  ZeD.tr("UI_ZeD_Identity_BodyHair"),   data.bodyHair   },
        { ZeD.tr("UI_ZeD_Identity_HairColor"),     data.hairColor,  ZeD.tr("UI_ZeD_Identity_FacialHair"), data.facialHair },
    }
    for _, row in ipairs(fields) do
        panel:drawText(row[1], dataX, rowY,
            KY.inkDim.r, KY.inkDim.g, KY.inkDim.b, KY.inkDim.a, T.fontF1)
        panel:drawText(row[2], dataX, rowY + bodyFH + T.px(1),
            0.1, 0.1, 0.1, 1.0, T.fontF4)
        panel:drawText(row[3], dataX + colW, rowY,
            KY.inkDim.r, KY.inkDim.g, KY.inkDim.b, KY.inkDim.a, T.fontF1)
        panel:drawText(row[4], dataX + colW, rowY + bodyFH + T.px(1),
            0.1, 0.1, 0.1, 1.0, T.fontF4)
        rowY = rowY + bodyFH * 2 + T.px(10)
        panel:drawRect(dataX, rowY - T.px(4), dataW, T.px(1),
            0.08, KY.blue.r, KY.blue.g, KY.blue.b)
    end

    -- Time Survived
    rowY = rowY + T.px(4)
    panel:drawText(ZeD.tr("IGUI_char_Survived_For"), dataX, rowY,
        KY.inkDim.r, KY.inkDim.g, KY.inkDim.b, KY.inkDim.a, T.fontF1)
    rowY = rowY + bodyFH + T.px(1)
    panel:drawText(data.timeSurv, dataX, rowY, 0.1, 0.1, 0.1, 1.0, T.fontF4)
    rowY = rowY + bodyFH + T.px(10)
    panel:drawRect(dataX, rowY - T.px(4), dataW, T.px(1),
        0.08, KY.blue.r, KY.blue.g, KY.blue.b)

    -- Favorite Weapon | Zombies Killed
    rowY = rowY + T.px(4)
    panel:drawText(getText("IGUI_char_Favourite_Weapon"), dataX, rowY,
        KY.inkDim.r, KY.inkDim.g, KY.inkDim.b, KY.inkDim.a, T.fontF1)
    panel:drawText(data.favWeapon, dataX, rowY + bodyFH + T.px(1),
        0.1, 0.1, 0.1, 1.0, T.fontF4)
    panel:drawText(getText("IGUI_char_Zombies_Killed"), dataX + colW, rowY,
        KY.inkDim.r, KY.inkDim.g, KY.inkDim.b, KY.inkDim.a, T.fontF1)
    panel:drawText(data.zKills, dataX + colW, rowY + bodyFH + T.px(1),
        0.1, 0.1, 0.1, 1.0, T.fontF4)
end

-- ============================================================================
-- RENDERER — ZONE B: Character Traits
-- ============================================================================

-- the controller's focused element, when it is one of this window's
local function focusedId(win)
    local Focus = ZeD.Input and ZeD.Input.Focus
    if not (Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() == win and Focus.getFocusedElement) then return nil end
    local el = Focus.getFocusedElement(win)
    return el and el.id or nil
end

local function renderTraitRow(panel, win, trait, tx, ty, tw, color)
    local T = ZeD.T
    local A = ZeD.Atoms
    local rh = T.px(TRAIT_ROW_H)
    local bodyH = ZeD.TM:getFontHeight(T.fontF2)

    -- its description on hover and on controller focus (mockup zed_traits_tab_v1: the
    -- no-mod scene's descriptions belong here); the zone is kept for both
    local key = "identity:trait:" .. tostring(trait.name)
    local zones = win._idTraitZones
    zones[#zones + 1] = { x = tx, y = ty, w = tw, h = rh, id = key, name = trait.name, desc = trait.desc }

    -- the cell: a content line round it, the hover wash, the controller's mark
    -- under the words (no tinted fill: the square at the right carries good or bad)
    local hover = A.mouseIn(panel, tx, ty, tw, rh, win._idView)   -- (the tab's view bounds the hover)
    if hover then
        local hv = T.hover
        panel:drawRect(tx, ty, tw, rh, hv.a, hv.r, hv.g, hv.b)
    end
    local focused = false
    local F = ZeD.Input and ZeD.Input.Focus
    if F and F.isFocused and F.isFocused(win, nil, key) then
        focused = ZeD.Focus.mark(panel, tx, ty, tw, rh, { win = win })
    end
    A.frame(panel, tx, ty, tw, rh, T.border)

    -- Icon
    if trait.texture then
        local iconPad = math.floor((rh - T.px(TRAIT_ICON_SZ)) / 2)
        panel:drawTextureScaledAspect(trait.texture, tx + iconPad, ty + iconPad, T.px(trait.texture:getWidth()), T.px(trait.texture:getHeight()), 1.0, 1.0, 1.0, 1.0)
    end

    -- the status square (good or bad), then the name
    local sq = T.px(6)
    local markX = tx + tw - sq - T.px(8)
    A.drawStatusDot(panel, markX, ty + math.floor((rh - sq) / 2), color, sq)
    local nameX = tx + T.px(TRAIT_ICON_SZ) + T.px(12)
    local nameY = ty + math.floor((rh - bodyH) / 2)
    local nc = focused and T.textOnFocus or T.text
    panel:drawText(A.truncateText(trait.name, T.fontF2, markX - nameX - T.px(6)), nameX, nameY,
        nc.r, nc.g, nc.b, nc.a or 1, T.fontF2)
end

local function renderTraitGroup(panel, win, traits, label, x, curY, contentW, color)
    local T    = ZeD.T

    -- Category row ("Positive (3)": the count is in the label), not folding
    curY = curY + ZeD.Molecules.drawCategoryRow(panel, x, curY, contentW, label, nil, true, { noArrow = true, inset = 0 }) + T.sp.xs

    -- Two-column grid
    local gap = T.sp.sm
    local colW = math.floor((contentW - gap) / 2)
    for i, trait in ipairs(traits) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local tx = x + col * (colW + gap)
        local ty = curY + row * (T.px(TRAIT_ROW_H) + T.px(2))
        renderTraitRow(panel, win, trait, tx, ty, colW, color)
    end

    local rows = math.ceil(#traits / 2)
    curY = curY + rows * (T.px(TRAIT_ROW_H) + T.px(2)) + T.sp.sm
    return curY
end

local function renderZoneB(panel, win, data, x, drawY, w)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local pad  = T.sp.sm
    local contentW = w - pad * 2

    local curY = drawY + pad

    -- Section head (20u, sentence case, the content line under it); not folding
    curY = curY + ZeD.Molecules.drawSectionHeader(panel, x + pad, curY, contentW, getText("IGUI_char_Traits"),
        nil, true, false, nil, nil, nil, nil, true) + T.sp.afterGroove

    local totalCount = #data.posTraits + #data.negTraits

    if totalCount == 0 then
        ZeD.Molecules.drawEmptyLine(panel, x + pad, curY, contentW, ZeD.tr("UI_ZeD_Identity_NoTraits"))
        return
    end

    -- Positive traits
    if #data.posTraits > 0 then
        curY = renderTraitGroup(panel, win, data.posTraits,
            ZeD.tr("UI_ZeD_Identity_TraitsPositive", #data.posTraits),
            x + pad, curY, contentW, T.positive)
    end

    -- Negative traits
    if #data.negTraits > 0 then
        curY = renderTraitGroup(panel, win, data.negTraits,
            ZeD.tr("UI_ZeD_Identity_TraitsNegative", #data.negTraits),
            x + pad, curY, contentW, T.danger)
    end
end

-- ============================================================================
-- MAIN RENDERER
-- ============================================================================

function ZeD.IdentityTab.render(panel, win, x, y, w, h)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local M    = ZeD.Molecules

    -- Throttled data refresh
    win._identityTimer = (win._identityTimer or 0) + 1
    if win._identityTimer >= 30 or not win._identityCache then
        win._identityTimer = 0
        win._identityCache = ZeD.IdentityTab.gatherData(win._playerObj)
    end
    local data = win._identityCache

    -- Pinned tab header (37px, not in scroll content)
    local tabHeaderH = M.getTabHeaderH()

    -- S104 (Q100): stamp the disclosure hit-zone EARLY — mirrors SkillsTab
    -- and HealthTab. Tab header becomes a disclosure that toggles the
    -- license photo between bust (collapsed) and full-body (expanded). The
    -- focusable builder in ZeD_CharacterWindow reads _identityFigureZone
    -- each frame; stamping at the top guarantees the first prerender after
    -- a tab switch sees valid bounds and the disclosure lands in element[1].
    win._identityFigureZone = { x = x, y = y, w = w, h = tabHeaderH }

    -- ================================================================
    -- SCROLL (starts below pinned header)
    -- ================================================================
    local scroll  = win._identityScroll
    local scrollW = T.sp.scrollbarW

    -- Hair and beard (ZeD_HairBeard.lua): a fold under the license; Cut sits in it, beside its
    -- Hair | Beard switch. The card has no footer band (nothing on the whole card to do; Oct 30 2026).
    local HB = ZeD.HairBeard
    local hbL = HB and HB.layout(win, w - T.sp.scrollbarW) or nil
    local zoneHH = hbL and hbL.h or 0

    local zoneAH = measureZoneAH()
    local zoneBH = measureZoneBH(data)
    local totalContentH = zoneAH + zoneHH + zoneBH

    local scrollY = y + tabHeaderH
    local scrollH = h - tabHeaderH
    local needsScroll = totalContentH > scrollH
    scroll.visible = needsScroll
    local contentW = w
    if needsScroll then
        scroll.x = x + w - scrollW
        scroll.y = scrollY
        scroll.height = scrollH
        scroll:setBarSize(scrollH / math.max(1, totalContentH))
        contentW = w - scrollW
    else
        scroll:setScrollPos(0)
    end

    -- S104: grid-scroll pseudo-zone (Thermal parity). Identity content is
    -- pure readout — license card + traits list — so no individual row is
    -- focusable. Instead, a single pseudo-focusable covers the visible
    -- region below the tab header; D-pad up/down scrolls, and at bounds
    -- falls through to cone nav back to the disclosure above. Stamped
    -- only when scroll is actually needed; otherwise nil (builder skips).
    if needsScroll then
        win._identityGridScrollZone = { x = x, y = scrollY, w = contentW, h = scrollH }
    else
        win._identityGridScrollZone = nil
    end

    -- the controller's focus stays in view (once per newly focused stop); the
    -- disclosure takes the tab back to the top
    if needsScroll then ZeD.IdentityTab.followFocus(win, scroll, scrollY, scrollH, totalContentH) end

    panel:setStencilRect(x, scrollY, contentW, scrollH)
    win._idView = { x = x, y = scrollY, w = contentW, h = scrollH }   -- (what the pointer may hover)

    local scrollOff = 0
    if needsScroll then
        scrollOff = math.floor(scroll.scrollPos * math.max(0, totalContentH - scrollH))
    end
    win._identityScrollOff = scrollOff
    local drawY = scrollY - scrollOff

    -- ================================================================
    -- ZONE A: License Card
    -- ================================================================
    renderLicenseBackground(panel, win, x, drawY, contentW)

    -- KY seal — below bust in non-expanded, hidden in expanded (full-body covers area)
    if not win._identityPhotoExpanded then
        local secFH  = ZeD.TM:getFontHeight(T.fontF1)
        local bodyFH = ZeD.TM:getFontHeight(T.fontF2)
        local cardHeaderH = secFH + bodyFH + T.px(20)
        local cardY = drawY + T.px(CARD_PAD) + T.px(LAMINATE_W) + cardHeaderH
        local sealTex = getTexture("media/textures/ZeD/KY-seal.png")
        if sealTex then
            -- Below the 120x120 photo frame
            local sealSz = T.px(PHOTO_SIZE)  -- 120x120, same as photo frame
            local sealX = x + T.px(CARD_PAD) + T.px(LAMINATE_W) + math.floor((T.px(PHOTO_W) - sealSz) / 2)
            local sealY = cardY + T.px(FIELD_PAD) + T.px(PHOTO_SIZE) + T.px(8)
            panel:drawTextureScaledAspect(sealTex, sealX, sealY, sealSz, sealSz, 0.5, 1, 1, 1)
        end
    end

    renderLicenseText(panel, win, data, x, drawY, contentW)

    -- ================================================================
    -- ZONE H: Hair and beard
    -- ================================================================
    if hbL then HB.draw(panel, win, hbL, x, drawY + zoneAH, contentW, scrollY, scrollH) end

    -- ================================================================
    -- ZONE B: Traits
    -- ================================================================
    win._idTraitZones = {}
    renderZoneB(panel, win, data, x, drawY + zoneAH + zoneHH, contentW)

    panel:clearStencilRect()

    -- Pinned tab header: the disclosure arrow turns with _identityPhotoExpanded
    -- (collapsed = bust, right-pointing; expanded = full body, down). L/R tree-nav
    -- (gamepad), the header click (mouse) and a click on the photo all toggle it.
    -- The hover wash and the controller's mark come with the molecule.
    local hdrHover = A.mouseIn(panel, x, y, w, tabHeaderH)
    if hdrHover and ZeD.Help then ZeD.Help.set(win, ZeD.tr("UI_ZeD_Identity_HelpHeader")) end
    local F = ZeD.Input and ZeD.Input.Focus
    local hdrFocus = (F and F.isFocused and F.isFocused(win, nil, "identity:__disclosure")) and { win = win } or nil
    M.drawTabHeader(panel, x, y, w, ZeD.tr("UI_ZeD_Char_TabIdentity"), win._identityPhotoExpanded, hdrHover, nil,
        { focus = hdrFocus })

    if needsScroll then
        scroll:draw(panel)
    end

    -- hover cards last: a hair row's hint (asked of the window's overlay), a trait's
    -- description (hover) and the controller's focused one (drawn here, beside it)
    if HB then HB.drawHints(panel, win) end
    ZeD.IdentityTab.drawTraitHint(panel, win, x, scrollY, contentW, scrollH)
end

-- a trait's description: on hover (the shared detail card, after its pause) and on
-- controller focus (at once, under the trait)
function ZeD.IdentityTab.drawTraitHint(panel, win, vx, vy, vw, vh)
    local zones = win._idTraitZones
    if not zones then return end
    local F = ZeD.Input and ZeD.Input.Focus
    local live = F and F.liveElement and F.liveElement(win)
    local fid = live and live.id or nil
    local hit, focused = nil, false
    for _, z in ipairs(zones) do
        if fid == z.id then hit, focused = z, true; break end
    end
    if not hit and not (F and F.cuesVisible and F.cuesVisible()) then
        local mx, my = panel:getMouseX(), panel:getMouseY()
        if mx >= vx and mx < vx + vw and my >= vy and my < vy + vh then
            for _, z in ipairs(zones) do
                if mx >= z.x and mx < z.x + z.w and my >= z.y and my < z.y + z.h then hit = z end
            end
        end
    end
    if not hit then return end
    local HB = ZeD.HairBeard
    if HB then
        HB.hoverCard(panel, win, hit.id, hit.name, (hit.desc and hit.desc ~= "") and hit.desc or nil, hit, focused)
    end
end

-- keep the focused stop in view: scroll by the least that shows it whole
function ZeD.IdentityTab.followFocus(win, scroll, viewY, viewH, contentH)
    local id = focusedId(win)
    if not id or id == win._idLastPinned then return end
    win._idLastPinned = id
    local Focus = ZeD.Input.Focus
    local el = Focus.getFocusedElement(win)
    if not el then return end
    local maxOff = math.max(1, contentH - viewH)
    local off = math.floor((scroll.scrollPos or 0) * maxOff)
    local newOff = off
    if el.isDisclosure then newOff = 0
    elseif el.y < viewY then newOff = off - (viewY - el.y) - ZeD.T.px(6)
    elseif el.y + el.h > viewY + viewH then newOff = off + (el.y + el.h - viewY - viewH) + ZeD.T.px(6) end
    newOff = math.max(0, math.min(maxOff, newOff))
    if newOff ~= off then scroll:setScrollPos(newOff / maxOff) end
end

-- the controller's stops below the disclosure: Hair and beard's, then each trait
function ZeD.IdentityTab.focusables(win)
    local out = {}
    if ZeD.HairBeard then
        for _, e in ipairs(ZeD.HairBeard.focusables(win)) do out[#out + 1] = e end
    end
    for _, z in ipairs(win._idTraitZones or {}) do
        out[#out + 1] = { x = z.x, y = z.y, w = z.w, h = z.h, id = z.id, onFocus = function() end }
    end
    return out
end

-- a click in the tab's content (the hair rows, the switch, Out of reach, Cut)
function ZeD.IdentityTab.onClick(win, x, y)
    return ZeD.HairBeard ~= nil and ZeD.HairBeard.onClick(win, x, y)
end

-- what moves the stops, for the window's rebuild check
function ZeD.IdentityTab.scrollKey(win)
    local sc = win._identityScroll
    return tostring(sc and sc.scrollPos or 0) .. ":" .. (ZeD.HairBeard and ZeD.HairBeard.key(win) or "")
        .. ":" .. tostring(#(win._idTraitZones or {}))
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

function ZeD.IdentityTab.register(dispatchTable)
    dispatchTable["identity"] = ZeD.IdentityTab.render
end
