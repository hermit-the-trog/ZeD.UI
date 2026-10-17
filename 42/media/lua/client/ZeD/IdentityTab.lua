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
    if not hc then return "Unknown" end
    local r, g, b = hc:getRedFloat(), hc:getGreenFloat(), hc:getBlueFloat()
    local brightness = r * 0.299 + g * 0.587 + b * 0.114
    if brightness > 0.75 then
        if r > 0.85 and g > 0.85 then return "White" end
        return "Blonde"
    elseif brightness > 0.5 then
        if r > g + 0.15 then return "Auburn" end
        return "Light Brown"
    elseif brightness > 0.3 then
        if r > g + 0.1 and r > 0.45 then return "Red" end
        if r > 0.35 and g > 0.25 then return "Brown" end
        return "Dark Brown"
    elseif brightness > 0.15 then
        if r > g + 0.08 then return "Dark Red" end
        return "Dark Brown"
    end
    return "Black"
end

local function getHairStyleName(char)
    local hairModel = char:getHumanVisual():getHairModel()
    if not hairModel or hairModel == "" then return "Bald" end
    local style
    if char:isFemale() then
        style = getHairStylesInstance():FindFemaleStyle(hairModel)
    else
        style = getHairStylesInstance():FindMaleStyle(hairModel)
    end
    if style and style:getName() and style:getName() ~= "" then
        return getText("IGUI_Hair_" .. style:getName())
    end
    return "Bald"
end

local function getBeardStyleName(char)
    if char:isFemale() then return "N/A" end
    local beardModel = char:getHumanVisual():getBeardModel()
    if not beardModel or beardModel == "" then return "None" end
    local style = getBeardStylesInstance():FindStyle(beardModel)
    if style and style:getName() and style:getName() ~= "" then
        return getText("IGUI_Beard_" .. style:getName())
    end
    return "None"
end

local function getBodyHairName(char)
    local idx = char:getHumanVisual():getBodyHairIndex()
    if not idx or idx <= 0 then return "None" end
    local names = { "Light", "Normal", "Heavy", "Very Heavy" }
    return names[idx] or ("Level " .. idx)
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
    return best or "None"
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
        surname    = "Unknown",
        forename   = "",
        weightStr  = "-- kg",
        sexStr     = "--",
        profession = "--",
        hairStyle  = "--",
        bodyHair   = "--",
        facialHair = "--",
        hairColor  = "--",
        timeSurv   = "--",
        favWeapon  = "None",
        zKills     = "0",
        posTraits  = {},
        negTraits  = {},
    }

    if not playerObj then return data end

    local desc = playerObj:getDescriptor()
    if desc then
        data.surname  = desc:getSurname()  or "Unknown"
        data.forename = desc:getForename() or ""
    end

    local weight = math.floor(playerObj:getNutrition():getWeight())
    data.weightStr  = weight .. " kg"
    data.sexStr     = playerObj:isFemale() and "Female" or "Male"
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
            words[#words + 1] = word:sub(1, 1):upper() .. word:sub(2):lower()
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
    local headH = ZeD.TM:getFontHeight(T.fontF4)
    local pad   = T.sp.sm
    local h = pad + T.sp.beforeHead + headH + T.sp.headGap + T.px(2) + T.sp.afterGroove  -- heading + groove

    -- Positive traits
    if #data.posTraits > 0 then
        local secH = ZeD.TM:getFontHeight(T.fontF1)
        h = h + secH + T.sp.xs  -- "POSITIVE" subheading
        local rows = math.ceil(#data.posTraits / 2)
        h = h + rows * (T.px(TRAIT_ROW_H) + T.px(2))
        h = h + T.sp.sm
    end

    -- Negative traits
    if #data.negTraits > 0 then
        local secH = ZeD.TM:getFontHeight(T.fontF1)  -- F1 Lo for NEGATIVE label
        h = h + secH + T.sp.xs  -- "NEGATIVE" subheading
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
        { "Sex",        data.sexStr,     "Profession",  data.profession },
        { "Hair Style", data.hairStyle,  "Body Hair",   data.bodyHair   },
        { "Hair Color", data.hairColor,  "Facial Hair", data.facialHair },
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
    panel:drawText("Time Survived", dataX, rowY,
        KY.inkDim.r, KY.inkDim.g, KY.inkDim.b, KY.inkDim.a, T.fontF1)
    rowY = rowY + bodyFH + T.px(1)
    panel:drawText(data.timeSurv, dataX, rowY, 0.1, 0.1, 0.1, 1.0, T.fontF4)
    rowY = rowY + bodyFH + T.px(10)
    panel:drawRect(dataX, rowY - T.px(4), dataW, T.px(1),
        0.08, KY.blue.r, KY.blue.g, KY.blue.b)

    -- Favorite Weapon | Zombies Killed
    rowY = rowY + T.px(4)
    panel:drawText("Favorite Weapon", dataX, rowY,
        KY.inkDim.r, KY.inkDim.g, KY.inkDim.b, KY.inkDim.a, T.fontF1)
    panel:drawText(data.favWeapon, dataX, rowY + bodyFH + T.px(1),
        0.1, 0.1, 0.1, 1.0, T.fontF4)
    panel:drawText("Zombies Killed", dataX + colW, rowY,
        KY.inkDim.r, KY.inkDim.g, KY.inkDim.b, KY.inkDim.a, T.fontF1)
    panel:drawText(data.zKills, dataX + colW, rowY + bodyFH + T.px(1),
        0.1, 0.1, 0.1, 1.0, T.fontF4)
end

-- ============================================================================
-- RENDERER — ZONE B: Character Traits
-- ============================================================================

local function renderTraitRow(panel, trait, tx, ty, tw, color)
    local T = ZeD.T
    local bodyH = ZeD.TM:getFontHeight(T.fontF2)

    -- Row background
    panel:drawRect(tx, ty, tw, T.px(TRAIT_ROW_H),
        0.30, color.r, color.g, color.b)

    -- Icon
    if trait.texture then
        local iconPad = math.floor((T.px(TRAIT_ROW_H) - T.px(TRAIT_ICON_SZ)) / 2)
        panel:drawTextureScaledAspect(trait.texture, tx + iconPad, ty + iconPad, T.px(trait.texture:getWidth()), T.px(trait.texture:getHeight()), 1.0, 1.0, 1.0, 1.0)
    end

    -- Name
    local nameX = tx + T.px(TRAIT_ICON_SZ) + T.px(12)
    local nameY = ty + math.floor((T.px(TRAIT_ROW_H) - bodyH) / 2)
    panel:drawText(trait.name, nameX, nameY,
        T.toneNorm.r, T.toneNorm.g, T.toneNorm.b, T.toneNorm.a, T.fontF2)
end

local function renderTraitGroup(panel, traits, label, x, curY, contentW, color)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local secH = ZeD.TM:getFontHeight(T.fontF1)

    -- Subheading (F1 Lo)
    panel:drawText(label, x, curY, T.toneLo.r, T.toneLo.g, T.toneLo.b, T.toneLo.a, T.fontF1)
    curY = curY + secH + T.sp.xs

    -- Two-column grid
    local gap = T.sp.sm
    local colW = math.floor((contentW - gap) / 2)
    for i, trait in ipairs(traits) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local tx = x + col * (colW + gap)
        local ty = curY + row * (T.px(TRAIT_ROW_H) + T.px(2))
        renderTraitRow(panel, trait, tx, ty, colW, color)
    end

    local rows = math.ceil(#traits / 2)
    curY = curY + rows * (T.px(TRAIT_ROW_H) + T.px(2)) + T.sp.sm
    return curY
end

local function renderZoneB(panel, win, data, x, drawY, w)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local pad  = T.sp.sm
    local headH = ZeD.TM:getFontHeight(T.fontF4)
    local contentW = w - pad * 2

    local curY = drawY + pad

    -- Heading (F4 Norm)
    panel:drawText("Traits", x + pad, curY, T.toneNorm.r, T.toneNorm.g, T.toneNorm.b, T.toneNorm.a, T.fontF4)
    curY = curY + T.sp.beforeHead + headH + T.sp.headGap

    -- Groove divider
    A.drawGroove(panel, x + pad, curY, contentW)
    curY = curY + T.px(2) + T.sp.afterGroove

    local totalCount = #data.posTraits + #data.negTraits

    if totalCount == 0 then
        A.drawSecondary(panel, "No traits", x + pad, curY, T.textDim)
        return
    end

    -- Positive traits
    if #data.posTraits > 0 then
        curY = renderTraitGroup(panel, data.posTraits,
            "POSITIVE (" .. #data.posTraits .. ")",
            x + pad, curY, contentW, T.positive)
    end

    -- Negative traits
    if #data.negTraits > 0 then
        curY = renderTraitGroup(panel, data.negTraits,
            "NEGATIVE (" .. #data.negTraits .. ")",
            x + pad, curY, contentW, T.danger)
    end
end

-- ============================================================================
-- MAIN RENDERER
-- ============================================================================

function ZeD.IdentityTab.render(panel, win, x, y, w, h)
    local T    = ZeD.T
    local M    = ZeD.Molecules
    local pad  = M.getTabPad()      -- 8px outer pad (unused in identity content but kept for future)
    local padTop = M.getTabPadTop() -- 8px top pad below pinned header

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

    local zoneAH = measureZoneAH()
    local zoneBH = measureZoneBH(data)
    local totalContentH = zoneAH + zoneBH

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

    panel:setStencilRect(x, scrollY, contentW, scrollH)

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
    -- ZONE B: Traits
    -- ================================================================
    renderZoneB(panel, win, data, x, drawY + zoneAH, contentW)

    panel:clearStencilRect()

    -- S104 — gamepad focus cue on the tab-header disclosure. 0.55α T.accent
    -- over the header rect, drawn BEFORE drawTabHeader so the chevron + text
    -- render on top. Gated on the live focused element shape (isDisclosure)
    -- so the cue clears the moment LB/RB bumpers away. Mirrors Thermal/
    -- Health/Skills exactly.
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        if Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() == win
           and Focus.getFocusedElement then
            local el = Focus.getFocusedElement(win)
            if el and el.isDisclosure then
                local ac = T.accent
                panel:drawRect(x, y, w, tabHeaderH, 0.55, ac.r, ac.g, ac.b)
            end
        end
    end

    -- Pinned tab header — disclosure arrow rotates with _identityPhotoExpanded.
    -- Collapsed (bust) → right-pointing chevron; expanded (full body) → down.
    -- L/R tree-nav (gamepad) + header click (mouse) + photo click (mouse on
    -- ISUI3DModel) all converge on the same _identityPhotoExpanded toggle.
    M.drawTabHeader(panel, x, y, w, "Identity", win._identityPhotoExpanded)

    if needsScroll then
        scroll:draw(panel)
    end
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

function ZeD.IdentityTab.register(dispatchTable)
    dispatchTable["identity"] = ZeD.IdentityTab.render
end
