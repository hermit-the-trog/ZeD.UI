-- ZeD-UI/42/media/lua/client/ZeD/IdentityTab.lua
-- ============================================================================
-- IDENTITY TAB — client; the Character window's Identity tab ("identity" in its
-- tab dispatch table): the character's card + traits, two styles at two widths.
--   Immersive: the Kentucky operator's license, wide (photo left, fields right)
--     or narrow (laid out like Tennessee's vertical card).
--   Simple: ZeD components on the theme's surface, wide or narrow.
--   Under the card: the Hair and beard fold, then the traits (two columns wide,
--     one narrow).
-- The style is the ZeD setup choice identityStyle (ZeD.Settings.identitySimple),
-- read at every render; the width picks wide or narrow (isTall).
-- The license keeps a fixed palette; its colored words are the player's accent
-- darkened for the cream (kyAccent). Simple and the traits use ZeD theme tokens.
-- Each layout's heights come from one place the measure and the draw share, at
-- the width as if a scroll bar shows, so the two always agree.
--
-- The license's pixel art comes from ZeDUI/tools/identity/ky_header.py.
-- QA: ZeD.IdentityTab.qaLayout "tall" / "wide", qaStyle "immersive" / "simple",
-- qaTrend "steady" / "up" / "upup" / "down", qaProf a profession id ("base:burglar").
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ZeD_HairBeard"
require "ZeD/KillTracker"

ZeD = ZeD or {}
ZeD.IdentityTab = {}

-- ============================================================================
-- THE CONCEALED CARRY PERMIT, by the game's profession id (CharacterProfession
-- toString). "yes" carries one, "revoked" has it stamped REVOKED, anyone else has
-- none. Wide: a rubber stamp over the seal. Narrow: a box under CLASS D. Simple: a
-- Carry permit row.
-- ============================================================================

local CARRY_PERMIT = {
    ["base:policeofficer"]  = "yes",
    ["base:veteran"]        = "yes",
    ["base:securityguard"]  = "yes",
    ["base:parkranger"]     = "yes",
    ["base:burgerflipper"]  = "yes",
    ["base:burglar"]        = "revoked",
}

-- ============================================================================
-- KY LICENSE COLOR PALETTE (constant, theme-independent)
-- ============================================================================

local KY = {
    blue    = { r = 27/255,  g = 28/255,  b = 146/255, a = 1.0 },
    ruleHi  = { r = 64/255,  g = 66/255,  b = 190/255, a = 1.0 },   -- the band's top rule (#4042be)
    ruleLo  = { r = 13/255,  g = 14/255,  b = 92/255,  a = 1.0 },   -- the band's bottom rule (#0d0e5c)
    cardBg  = { r = 232/255, g = 228/255, b = 218/255, a = 1.0 },
    skyBlue = { r = 140/255, g = 195/255, b = 232/255, a = 1.0 },
    red     = { r = 179/255, g = 18/255,  b = 46/255,  a = 1.0 },   -- REVOKED (#b3122e)
    name    = { r = 0.07,    g = 0.07,    b = 0.07,    a = 1.0 },   -- the name and the weight
    value   = { r = 0.1,     g = 0.1,     b = 0.1,     a = 1.0 },   -- the values
    laminate = { r = 210/255, g = 206/255, b = 198/255, a = 1.0 },
}

-- ============================================================================
-- LAYOUT CONSTANTS (design units)
-- ============================================================================

local CARD_PAD   = 8     -- padding inside drawer to card edge
local LAMINATE_W = 8     -- clear laminate border around perimeter
local PHOTO_W    = 150   -- width of the wide license's left column
local PHOTO_SIZE = 120   -- 120x120 square photo frame
local PHOTO_FULL = 250   -- the wide license's full-body photo, tall
local BODY_TOP   = 14    -- the wide license: the body's padding above the columns
local BODY_BOT   = 12    --   and below them
local BODY_GAP   = 14    --   the gap between the columns, and the right column's right padding
local SEAL_WIDE  = 96    -- the seal under the wide license's photo
local SEAL_TALL  = 56    -- the seal at the narrow license's foot
local TALL_PAD   = 12    -- the narrow license's side padding
local TALL_FULL  = 560   -- the narrow license's full-body photo, tall
local TALL_MODEL = 540   --   and the model in it, at its foot
local NAME_WIDE  = 18    -- the name's size (px), Simple's too
local NAME_TALL  = 20    -- the narrow license's surname and weight
local FORE_TALL  = 16    -- the narrow license's forename
local BIG_TALL   = 19    -- the narrow license's survived time
local BIG_SMALL  = 16    --   a step down, when a line won't fit its column
local PLAIN_PAD  = 12    -- Simple's side margin
local PLAIN_TOP  = 10    -- Simple's top and bottom margin
local PLAIN_BUST = 88    -- Simple's narrow bust box
local PLAIN_FULL_WIDE = 230  -- Simple's full-body box, wide
local PLAIN_FULL_TALL = 420  --   and narrow
local PLAIN_MODEL = 400      --   and the narrow model in it, at its foot
local BAND_UNITS = 48    -- the header band's design height
local BAND_ART   = 24    -- the header band's height in art pixels
local SHEET_W    = 256   -- ky_bg_sheet.png, the security pattern pre-tiled, in art pixels
local SHEET_H    = 128
local TRAIT_ROW_H = 23   -- least height of a trait row
local TRAIT_GAP  = 4     -- between the trait rows
local TRAIT_COL_GAP = 12 -- between the two columns of traits

-- ============================================================================
-- LICENSE CARD ROUNDED RECT (10px bevel — larger than ZeD's standard 2px)
-- Pixel-art quarter-circle: each row specifies an inset from the edge.
-- ============================================================================

local CARD_RADIUS = { 10, 7, 5, 4, 3, 2, 2, 1, 1, 1 }

local function fillRoundedCard(panel, x, y, w, h, r, g, b, a)
    local T = ZeD.T  -- design row i covers [T.px(i - 1), T.px(i)) so rows tile without gaps
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
        local rowH = T.px(i) - row  -- design row i covers [T.px(i - 1), T.px(i))
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
    -- vanilla's paint-color words where it has them (ContextMenu_*), else ZeD's
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
                -- the game's trait icon, as vanilla's character info draws it; a trait with
                -- none (a mod's, say) keeps the icon's room empty (vanilla checks it too)
                texture = traitDef:getTexture() or nil,
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
-- THE LICENSE'S OWN FACTS
-- ============================================================================

-- the weight's sign, from the game's Nutrition: + gaining, ++ gaining fast, - losing, nothing steady
local TREND_SIGN = { steady = "", up = "+", upup = "++", down = "-" }
local function weightTrend(nutrition)
    local q = ZeD.IdentityTab.qaTrend
    if q and TREND_SIGN[q] then return TREND_SIGN[q] end
    if not nutrition then return "" end
    if nutrition:isIncWeightLot() then return "++" end
    if nutrition:isIncWeight() then return "+" end
    if nutrition:isDecWeight() then return "-" end
    return ""
end

-- The game's start date and the same date four years on, MM/DD/YYYY, from the sandbox options:
-- each is the option's value from 1, and year 1 is 1993 (SandboxOptions.getFirstYear). GameTime's
-- start fields won't do: a multiplayer client's GameTime keeps its constructor's date in 2012.
local function licenseDates()
    local sv = SandboxVars
    local m, d, y = sv and sv.StartMonth, sv and sv.StartDay, sv and sv.StartYear
    if not (m and d and y) then return "--", "--" end
    y = 1992 + y
    return string.format("%02d/%02d/%04d", m, d, y), string.format("%02d/%02d/%04d", m, d, y + 4)
end

-- The DL number: the surname's first letter, then eight digits in the 2-3-3 shape, the same
-- for a name every time. Two hashes under 10000 keep every step far under 2^31 (Kahlua's %
-- breaks past it); together they make the eight digits.
local function dlNumber(sur, fore)
    local s = tostring(sur) .. "|" .. tostring(fore)
    local a, b = 7, 11
    for i = 1, #s do
        local c = string.byte(s, i) or 0
        a = (a * 31 + c) % 9973
        b = (b * 37 + c) % 9967
    end
    local n = a * 10000 + b
    local first = ZeD.upper(string.sub(tostring(sur), 1, 1))
    if first == "" then first = "X" end
    return string.format("%s%02d-%03d-%03d", first, math.floor(n / 1000000), math.floor(n / 1000) % 1000, n % 1000)
end

-- the survived time as lines, split at its commas (the narrow license)
local function splitSurvived(s)
    local out = {}
    for part in string.gmatch(s, "[^,]+") do
        out[#out + 1] = string.match(part, "^%s*(.-)%s*$") or part
    end
    if #out == 0 then out[1] = s end
    return out
end

-- the profession's definition by id (qaProf, nil when the game has no such profession)
local function profDefById(id)
    local list = CharacterProfessionDefinition.getProfessions()
    for i = 0, list:size() - 1 do
        local d = list:get(i)
        if d:getType():toString() == id then return d end
    end
    return nil
end

-- the profession's display name (Title Case: Kahlua2 doesn't support gsub function
-- replacement, so iterate words manually instead), and its id
local function professionOf(desc)
    local prof = desc and desc:getCharacterProfession() or nil
    local id = prof and prof:toString() or nil
    -- CharacterProfessionDefinition.getCharacterProfessionDefinition() gives the Lua-side
    -- definition object which has getUIName() — the translated display string
    local def = prof and CharacterProfessionDefinition.getCharacterProfessionDefinition(prof) or nil
    local q = ZeD.IdentityTab.qaProf
    if q then
        id = string.find(q, ":", 1, true) and q or ("base:" .. q)
        def = profDefById(id) or def
    end
    local raw = (def and def:getUIName()) or (prof and prof:getName()) or nil
    if not raw then return "--", id end
    local words = {}
    for word in raw:gmatch("%S+") do
        words[#words + 1] = ZeD.upper(word:sub(1, 1)) .. word:sub(2):lower()
    end
    return #words > 0 and table.concat(words, " ") or raw, id
end

-- ============================================================================
-- DATA AGGREGATION
-- ============================================================================

--- Everything the card and the traits show, read once from the player (placeholders
--- without one), and the strings the cards draw, made here rather than each frame.
--- The kill-count QA scripts read it too.
function ZeD.IdentityTab.gatherData(playerObj)
    local data = {
        surname    = ZeD.tr("UI_ZeD_Identity_Unknown"),
        forename   = "",
        weightStr  = ZeD.tr("UI_ZeD_Identity_WeightKg", "--"),
        trend      = "",
        sexStr     = "--",
        profession = "--",
        permit     = nil,
        hairStyle  = "--",
        bodyHair   = "--",
        facialHair = "--",
        hairColor  = "--",
        timeSurv   = "--",
        favWeapon  = getText("IGUI_None"),
        zKills     = "0",
        dlNo       = "--",
        issStr     = "--",
        expStr     = "--",
        posTraits  = {},
        negTraits  = {},
    }

    if playerObj then
        local desc = playerObj:getDescriptor()
        if desc then
            data.surname  = desc:getSurname()  or ZeD.tr("UI_ZeD_Identity_Unknown")
            data.forename = desc:getForename() or ""
        end

        local nutrition = playerObj:getNutrition()
        data.weightStr  = ZeD.tr("UI_ZeD_Identity_WeightKg", math.floor(nutrition:getWeight()))
        data.trend      = weightTrend(nutrition)
        data.sexStr     = playerObj:isFemale() and getText("IGUI_char_Female") or getText("IGUI_char_Male")
        local profName, profId = professionOf(desc)
        data.profession = profName
        data.permit     = profId and CARRY_PERMIT[profId] or nil
        data.hairStyle  = getHairStyleName(playerObj)
        data.bodyHair   = getBodyHairName(playerObj)
        data.facialHair = getBeardStyleName(playerObj)
        data.hairColor  = getHairColorName(playerObj)
        data.zKills     = tostring(ZeD.KillTracker.total(playerObj))   -- the Journal's total, fire kills in
        data.favWeapon  = getFavouriteWeapon(playerObj)
        data.dlNo       = dlNumber(data.surname, data.forename)
        data.issStr, data.expStr = licenseDates()

        if instanceof(playerObj, "IsoPlayer") then
            data.timeSurv = playerObj:getTimeSurvived() or "--"
        end

        data.posTraits, data.negTraits = getCharacterTraitsSorted(playerObj)
    end

    -- what the cards draw, made once here and not each frame; the separator only between two names
    local sur, fore = tostring(data.surname), tostring(data.forename)
    if sur == "" and fore == "" then
        sur = ZeD.tr("UI_ZeD_Identity_Unknown")
        data.surname = sur
    end
    local both = sur ~= "" and fore ~= ""
    data.nameComma = both and (sur .. ", " .. fore) or (sur .. fore)
    data.nameFull  = both and (fore .. " " .. sur) or (sur .. fore)
    data.surUp     = ZeD.upper(data.surname)
    data.foreUp    = ZeD.upper(data.forename)
    data.survLines = splitSurvived(tostring(data.timeSurv))
    data.small = {
        sex    = ZeD.upper(string.sub(tostring(data.sexStr), 1, 1)),
        hair   = ZeD.upper(data.hairColor),
        style  = ZeD.upper(data.hairStyle),
        facial = ZeD.upper(data.facialHair),
        body   = ZeD.upper(data.bodyHair),
        prof   = ZeD.upper(data.profession),
        kills  = data.zKills,
        fav    = ZeD.upper(data.favWeapon),
    }

    return data
end

-- ============================================================================
-- THE ART
-- ============================================================================

-- the license's pixel art, nearest filtering (3 = Atoms' pxTex), each loaded once
local _art = {}
local function kyArt(name)
    local t = _art[name]
    if t == nil then
        t = Texture.getSharedTexture("media/textures/ZeD/identity/" .. name .. ".png", 3) or false
        _art[name] = t
    end
    return t or nil
end

local _seal = nil
local function sealTex()
    if not _seal then _seal = getTexture("media/textures/ZeD/KY-seal.png") end
    return _seal
end

-- The whole number the art draws at: the band's design height over its 24 art pixels, rounded
-- down, so no art pixel blurs at 1.75x. The band is exactly this x 24 tall.
local function artScale()
    return math.max(1, math.floor(ZeD.T.px(BAND_UNITS) / BAND_ART))
end
local function bandH() return artScale() * BAND_ART end

-- the donor pill's whole number, for its 30 design units over 10 art pixels
local function donorScale()
    return math.max(1, math.floor(ZeD.T.px(30) / 10))
end

-- a piece of art at whole-number scale s (no aspect to keep at a whole number)
local function drawArt(panel, tex, x, y, s, a)
    panel:drawTextureScaled(tex, x, y, tex:getWidth() * s, tex:getHeight() * s, a or 1, 1, 1, 1)
end

-- The header band: the blue, its two rules one art pixel each, the art pinned to the ends
-- (narrow, or a card narrower than the left piece: the three lines centered). The right piece
-- drops before the two would touch.
local function drawBand(panel, x, y, w, tall)
    local T = ZeD.T
    local s, h = artScale(), bandH()
    panel:drawRect(x, y, w, h, 1, KY.blue.r, KY.blue.g, KY.blue.b)
    panel:drawRect(x, y, w, s, 1, KY.ruleHi.r, KY.ruleHi.g, KY.ruleHi.b)
    panel:drawRect(x, y + h - s, w, s, 1, KY.ruleLo.r, KY.ruleLo.g, KY.ruleLo.b)
    local l, r = kyArt("ky_head_left"), kyArt("ky_head_right")
    local lw = l and l:getWidth() * s or 0
    if tall or lw > w then
        local t = kyArt("ky_head_tall")
        if not t then return end
        local tw = t:getWidth()
        while s > 1 and tw * s > w do s = s - 1 end
        drawArt(panel, t, x + math.floor((w - tw * s) / 2), y + math.floor((h - BAND_ART * s) / 2), s)
        return
    end
    if l then drawArt(panel, l, x, y, s) end
    if r then
        local rw = r:getWidth() * s
        if lw + T.px(8) + rw <= w then drawArt(panel, r, x + w - rw, y, s) end
    end
end

-- The security pattern over the cream, at the art's whole number. ky_bg_sheet.png is the 16 x 8
-- tile pre-tiled, so a card takes a few draws and not hundreds a frame. A stencil can't nest in
-- the tab's, so each sheet is cut at the card's edge by its source rect (DrawTextureTiled draws
-- at 1:1; this is the call it makes, with the size). Rows outside the tab's view are skipped.
local function drawTiles(panel, win, x, y, w, h)
    local tex = kyArt("ky_bg_sheet")
    local jo = panel.javaObject
    if not (tex and jo) or w <= 0 or h <= 0 then return end
    local s = artScale()
    local tw, th = SHEET_W * s, SHEET_H * s
    local view = win._idView
    local right, bottom = x + w, y + h
    local vTop, vBot = view and view.y or y, view and (view.y + view.h) or bottom
    local ty = y
    while ty < bottom do
        local dh = math.min(th, bottom - ty)
        if ty + dh > vTop and ty < vBot then
            local tx = x
            while tx < right do
                local dw = math.min(tw, right - tx)
                jo:DrawSubTextureRGBA(tex, 0, 0, dw / s, dh / s, tx, ty, dw, dh, 1, 1, 1, 1)
                tx = tx + tw
            end
        end
        ty = ty + th
    end
end

-- the laminate, the band, the cream body (bare: no pattern, the full body covers it).
-- Returns the printed area: its left, the body's top, the width and the body's height.
local function drawCardShell(panel, win, x, y, w, h, tall, bare)
    local T = ZeD.T
    local pad, lam = T.px(CARD_PAD), T.px(LAMINATE_W)
    local cardX, cardW = x + pad, w - pad * 2
    fillRoundedCard(panel, cardX, y + pad, cardW, h, KY.laminate.r, KY.laminate.g, KY.laminate.b, KY.laminate.a)
    local ix, iy, iw = cardX + lam, y + pad + lam, cardW - lam * 2
    local band = bandH()
    local bodyY, bodyH = iy + band, h - lam * 2 - band
    drawBand(panel, ix, iy, iw, tall)
    panel:drawRect(ix, bodyY, iw, bodyH, 1.0, KY.cardBg.r, KY.cardBg.g, KY.cardBg.b)
    if not bare then drawTiles(panel, win, ix, bodyY, iw, bodyH) end
    borderRoundedCard(panel, cardX, y + pad, cardW, h, KY.blue.r, KY.blue.g, KY.blue.b, 0.3)
    return ix, bodyY, iw, bodyH
end

-- ============================================================================
-- THE WORDS: colors, free sizes and fits
-- ============================================================================

-- every colored word on the license: the player's accent, 62% accent and 38% black so pale
-- accents read on the cream, read fresh (one table, no churn). The card is the same cream in
-- every theme, so it takes the accent's dark variant whatever the theme (T.accent is the light
-- one under Light); a window with its own accent keeps it.
local _acc = { r = 0, g = 0, b = 0, a = 1 }
local function kyAccent(win)
    local key = win and win._accentKey
    local set = key and ZeD.AccentColors[key] or ZeD.AccentColors[ZeD.currentAccent]
    local a = set and set.dark.accent or ZeD.T.accent
    _acc.r, _acc.g, _acc.b = a.r * 0.62, a.g * 0.62, a.b * 0.62
    return _acc
end

-- the zoom for px design pixels on a free-size face, the text size included (Large grows it)
local function freeZoom(px)
    local T = ZeD.T
    return ZeD.Text.zoomPx(px * T.scale / (T.root or 1))
end

-- What the free-size words measure, kept per font and zoom while the game's measures are
-- (ZeD.Text.measureEpoch), so nothing is measured every frame.
local _fc = { ep = false, w = {}, fit = {}, lh = {}, n = 0 }
local function freeCache()
    local X = ZeD.Text
    local ep = X.measureEpoch and X.measureEpoch() or nil
    if ep == nil or ep ~= _fc.ep or _fc.n > 1000 then
        _fc.ep, _fc.w, _fc.fit, _fc.lh, _fc.n = ep, {}, {}, {}, 0
    end
    return _fc
end
local function sub2(t, a, b)
    local ta = t[a]
    if not ta then ta = {}; t[a] = ta end
    local tb = ta[b]
    if not tb then tb = {}; ta[b] = tb end
    return tb
end

local function freeW(f, s, zoom)
    local fc = freeCache()
    local c = sub2(fc.w, f, zoom)
    local v = c[s]
    if not v then
        v = ZeD.Text.width(f, s, zoom)
        c[s] = v
        fc.n = fc.n + 1
    end
    return v
end

-- a free-size line's height, whole px
local function freeLineH(f, px)
    local zoom = freeZoom(px)
    local fc = freeCache()
    local c = sub2(fc.lh, f, zoom)
    local v = c.h
    if not v then
        v = math.ceil(ZeD.Text.height(f, zoom))
        c.h = v
    end
    return v
end

local function fitRaw(f, s, room, zoom)
    if freeW(f, s, zoom) <= room then return s end
    local target = room - freeW(f, "...", zoom)
    if target <= 0 then return "" end
    local lo, hi = 0, #s
    while lo < hi do
        local mid = math.floor((lo + hi + 1) / 2)
        if ZeD.Text.width(f, string.sub(s, 1, mid), zoom) <= target then lo = mid else hi = mid - 1 end
    end
    if lo == 0 then return "" end
    return string.sub(s, 1, lo) .. "..."
end

-- free-size words cut to their room with "..." (nothing when not even a letter fits), kept
local function fitFree(f, s, room, zoom)
    s = tostring(s or "")
    if room <= 0 then return "" end
    local fc = freeCache()
    local byRoom = sub2(fc.fit, f, zoom)
    local c = byRoom[room]
    if not c then c = {}; byRoom[room] = c end
    local out = c[s]
    if out == nil then
        out = fitRaw(f, s, room, zoom)
        c[s] = out
        fc.n = fc.n + 1
    end
    return out
end

-- the name cut to its room with "..." on the distance-field face
local function fitName(name, room, zoom)
    return fitFree(ZeD.Font.sdf.head, name, room, zoom)
end

-- the weight's width at the name's size, its sign included
local function weightW(data, zoom)
    local f = ZeD.Font.sdf.head
    local w = freeW(f, data.weightStr, zoom)
    if data.trend ~= "" then w = w + ZeD.T.px(3) + freeW(f, data.trend, zoom) end
    return w
end

-- the weight at x, its sign after it (ink: the number's color, sign: the sign's)
local function drawWeight(panel, data, x, y, zoom, ink, sign)
    local X, f = ZeD.Text, ZeD.Font.sdf.head
    X.draw(panel, f, data.weightStr, x, y, zoom, ink.r, ink.g, ink.b, ink.a or 1, "l")
    if data.trend ~= "" then
        X.draw(panel, f, data.trend, x + freeW(f, data.weightStr, zoom) + ZeD.T.px(3), y, zoom,
            sign.r, sign.g, sign.b, 1, "l")
    end
end

-- The name row: the weight at the right, as large and as heavy as the name, the name in the
-- room left. The name is the card's: the weight gives way before the name keeps less than
-- a few letters, and it is never drawn over the name.
local function drawNameRow(panel, data, name, x, y, w, px, ink, sign)
    local T, X = ZeD.T, ZeD.Text
    local zoom = freeZoom(px)
    local wt = weightW(data, zoom)
    local room = w - wt - T.px(8)
    if room < T.px(48) then
        room = w
    else
        drawWeight(panel, data, x + w - wt, y, zoom, ink, sign)
    end
    local s = fitName(name, room, zoom)
    if s ~= "" then
        X.draw(panel, ZeD.Font.sdf.head, s, x, y, zoom, ink.r, ink.g, ink.b, ink.a or 1, "l")
    end
end

-- A field's two lines: the label (F1) and the value (F4), each at least the body
-- line, so a larger text never draws a value over its label
local function fieldLineHs()
    local T, tm = ZeD.T, ZeD.TM
    local bodyFH = tm:getFontHeight(T.fontF2)
    return math.max(bodyFH, tm:getFontHeight(T.fontF1)), math.max(bodyFH, tm:getFontHeight(T.fontF4))
end

-- where the window puts the model (win._identityPhotoRect, the same frame as the draw) and
-- what picks the photo (the zone: the frame, with the model's margins). One table each.
local function setPhoto(win, x, y, w, h, expanded, zx, zy, zw, zh)
    local pr = win._idPhotoR or {}
    win._idPhotoR = pr
    pr.x, pr.y, pr.w, pr.h, pr.expanded = x, y, w, h, expanded or nil
    win._identityPhotoRect = pr
    local z = win._idPhotoZ or {}
    win._idPhotoZ = z
    z.x, z.y, z.w, z.h = zx or x, zy or y, zw or w, zh or h
    win._identityPhotoZone = z
end

-- ============================================================================
-- THE WIDE LICENSE (photo and seal left, name and fields right)
-- ============================================================================

local function wideRightH()
    local T = ZeD.T
    local lblH, valH = fieldLineHs()
    return freeLineH(ZeD.Font.sdf.head, NAME_WIDE) + T.px(10)
        + (lblH + T.px(1) + valH) * 5 + (T.px(6) * 2 + T.px(1)) * 4
end

local function wideLeftH(expanded)
    local T = ZeD.T
    if expanded then return T.px(PHOTO_FULL) end
    return T.px(PHOTO_SIZE) + T.px(10) + T.px(SEAL_WIDE)
end

local function measureWideH(expanded)
    local T = ZeD.T
    return T.px(CARD_PAD) * 2 + T.px(LAMINATE_W) * 2 + bandH()
        + T.px(BODY_TOP) + math.max(wideLeftH(expanded), wideRightH()) + T.px(BODY_BOT)
end

-- one field in its own box: the label and the value each cut to the box's width
-- (nothing when not even "..." fits), never drawn over the next box
local function drawField(panel, acc, label, value, fx, fy, fw, lblH)
    local T, A = ZeD.T, ZeD.Atoms
    if fw <= ZeD.TM:MeasureStringX(T.fontF1, "...") then return end
    panel:drawText(A.truncateText(tostring(label or ""), T.fontF1, fw), fx, fy, acc.r, acc.g, acc.b, 1, T.fontF1)
    if fw <= ZeD.TM:MeasureStringX(T.fontF4, "...") then return end
    panel:drawText(A.truncateText(tostring(value or ""), T.fontF4, fw), fx, fy + lblH + T.px(1),
        KY.value.r, KY.value.g, KY.value.b, 1, T.fontF4)
end

-- a row of one or two fields and, unless it is the last, the faint rule under it; the next row's y
local function fieldRow(panel, acc, x, w, y, lblH, valH, l1, v1, l2, v2, last)
    local T = ZeD.T
    local gap = T.px(10)
    local cw = l2 and math.floor((w - gap) / 2) or w
    drawField(panel, acc, l1, v1, x, y, cw, lblH)
    if l2 then drawField(panel, acc, l2, v2, x + cw + gap, y, cw, lblH) end
    y = y + lblH + T.px(1) + valH
    if last then return y end
    panel:drawRect(x, y + T.px(6), w, T.px(1), 0.08, KY.blue.r, KY.blue.g, KY.blue.b)
    return y + T.px(6) * 2 + T.px(1)
end

-- The rubber stamp over the seal: a double-ruled box in the accent, the cream washed behind
-- it, centered on (cx, cy). Plain text can't turn, so it is set square. REVOKED is red.
local function drawStamp(panel, data, acc, cx, cy, maxW)
    if not data.permit then return end
    local T, A, X, f = ZeD.T, ZeD.Atoms, ZeD.Text, ZeD.Font.sdf.sec
    local zoom, lh = freeZoom(13), freeLineH(f, 13)
    local t = T.hair
    local frame = t * 3                      -- rule, gap, rule
    local padX, padY = T.px(8), T.px(3)
    local room = maxW - (frame + padX) * 2
    local rv = (data.permit == "revoked") and ZeD.tr("UI_ZeD_Identity_Revoked") or nil
    -- the word space between PERMIT and REVOKED: read as "a a" less "aa" (a lone space measures 0 in this face, and the
    -- stamp read "PERMITREVOKED": QA's Mac shots, Nov 10 2026), never under a quarter of the line
    local sp = 0
    if rv then sp = math.max(freeW(f, "a a", zoom) - freeW(f, "aa", zoom), math.floor(lh / 4)) end
    local rw = rv and freeW(f, rv, zoom) or 0
    local l1 = fitFree(f, ZeD.tr("UI_ZeD_Identity_StampLine1"), room, zoom)
    local l2 = fitFree(f, ZeD.tr("UI_ZeD_Identity_StampLine2"), room - sp - rw, zoom)
    local l2w = freeW(f, l2, zoom) + sp + rw
    local bw = math.max(freeW(f, l1, zoom), l2w) + (frame + padX) * 2
    local bh = lh * 2 + (frame + padY) * 2
    local bx, by = math.floor(cx - bw / 2), math.floor(cy - bh / 2)
    panel:drawRect(bx, by, bw, bh, 0.55, KY.cardBg.r, KY.cardBg.g, KY.cardBg.b)
    A.frame(panel, bx, by, bw, bh, acc, 1, t)
    A.frame(panel, bx + t * 2, by + t * 2, bw - t * 4, bh - t * 4, acc, 1, t)
    local ty = by + frame + padY
    X.draw(panel, f, l1, cx, ty, zoom, acc.r, acc.g, acc.b, 1, "c")
    local lx = math.floor(cx - l2w / 2)
    if l2 ~= "" then X.draw(panel, f, l2, lx, ty + lh, zoom, acc.r, acc.g, acc.b, 1, "l") end
    if rv then
        X.draw(panel, f, rv, lx + l2w - rw, ty + lh, zoom, KY.red.r, KY.red.g, KY.red.b, 1, "l")
    end
end

local function renderLicenseWide(panel, win, data, x, drawY, w)
    local A, T = ZeD.Atoms, ZeD.T
    local expanded = win._identityPhotoExpanded and true or false
    local ix, bodyY, iw = drawCardShell(panel, win, x, drawY, w, measureWideH(expanded) - T.px(CARD_PAD) * 2, false)
    local top = bodyY + T.px(BODY_TOP)
    local colW = T.px(PHOTO_W)
    local acc = kyAccent(win)

    -- the left column: the bust and the seal under it, or the full body across the column
    if expanded then
        local ph = T.px(PHOTO_FULL)
        panel:drawRect(ix, top, colW, ph, 1.0, KY.skyBlue.r, KY.skyBlue.g, KY.skyBlue.b)
        setPhoto(win, ix, top, colW, ph, true)
    else
        local ps = T.px(PHOTO_SIZE)
        local photoX = ix + math.floor((colW - ps) / 2)
        A.fillRounded(panel, photoX, top, ps, ps, KY.skyBlue.r, KY.skyBlue.g, KY.skyBlue.b, 1.0)
        setPhoto(win, photoX, top, ps, ps, false)
        local sz = T.px(SEAL_WIDE)
        local cx, sealY = ix + math.floor(colW / 2), top + ps + T.px(10)
        local seal = sealTex()
        if seal then panel:drawTextureScaledAspect(seal, cx - math.floor(sz / 2), sealY, sz, sz, 0.45, 1, 1, 1) end
        drawStamp(panel, data, acc, cx, sealY + math.floor(sz / 2), colW)
    end

    -- the right column: the name row, then the fields
    local dataX = ix + colW + T.px(BODY_GAP)
    local dataW = iw - colW - T.px(BODY_GAP) * 2
    drawNameRow(panel, data, data.nameComma, dataX, top, dataW, NAME_WIDE, KY.name, acc)
    local y = top + freeLineH(ZeD.Font.sdf.head, NAME_WIDE) + T.px(10)
    local lblH, valH = fieldLineHs()
    y = fieldRow(panel, acc, dataX, dataW, y, lblH, valH, getText("IGUI_char_Sex"), data.sexStr,
        ZeD.tr("UI_ZeD_Identity_Profession"), data.profession)
    y = fieldRow(panel, acc, dataX, dataW, y, lblH, valH, ZeD.tr("UI_ZeD_Identity_HairStyle"), data.hairStyle,
        ZeD.tr("UI_ZeD_Identity_BodyHair"), data.bodyHair)
    y = fieldRow(panel, acc, dataX, dataW, y, lblH, valH, ZeD.tr("UI_ZeD_Identity_HairColor"), data.hairColor,
        ZeD.tr("UI_ZeD_Identity_FacialHair"), data.facialHair)
    y = fieldRow(panel, acc, dataX, dataW, y, lblH, valH, getText("IGUI_char_Survived_For"), data.timeSurv)
    fieldRow(panel, acc, dataX, dataW, y, lblH, valH, getText("IGUI_char_Favourite_Weapon"), data.favWeapon,
        getText("IGUI_char_Zombies_Killed"), data.zKills, true)
end

-- ============================================================================
-- WIDE OR NARROW. Below a width the wide card's two-column fields are narrower than their
-- longest label (they would read "..."); there the card stands up, a vertical version of
-- the ID. Simple follows the same width.
-- QA: ZeD.IdentityTab.qaLayout = "tall" or "wide" forces one (nil: by the width);
-- win._idTall says which one drew.
-- ============================================================================

-- the labels of Simple's rows, in order (the name is its own row); the widest one
-- also decides the width
local TALL_LABELS = {
    { "v", "IGUI_char_Sex" }, { "z", "UI_ZeD_Identity_Profession" }, { "z", "UI_ZeD_Identity_HairStyle" },
    { "z", "UI_ZeD_Identity_HairColor" }, { "z", "UI_ZeD_Identity_FacialHair" }, { "z", "UI_ZeD_Identity_BodyHair" },
    { "v", "IGUI_char_Survived_For" }, { "v", "IGUI_char_Favourite_Weapon" }, { "v", "IGUI_char_Zombies_Killed" },
}
local function tallLabel(i)
    local d = TALL_LABELS[i]
    return (d[1] == "v") and getText(d[2]) or ZeD.tr(d[2])
end

-- the widest field label (F1), kept per scale, font and language
local _lblNeed, _lblSig = nil, nil
local function labelNeed()
    local T = ZeD.T
    local sig = tostring(T.scale) .. tostring(T.fontF1) .. ((ZeD.trTestOn and ZeD.trTestOn()) and "t" or "")
    if _lblNeed and _lblSig == sig then return _lblNeed end
    local m = 0
    for i = 1, #TALL_LABELS do m = math.max(m, ZeD.TM:MeasureStringX(T.fontF1, tallLabel(i))) end
    _lblNeed, _lblSig = m, sig
    return m
end

-- the narrow card at content width w? (the wide card's field box against the widest label)
local function isTall(w)
    local q = ZeD.IdentityTab.qaLayout
    if q == "tall" then return true elseif q == "wide" then return false end
    local T = ZeD.T
    local dataW = w - T.px(CARD_PAD) * 2 - T.px(LAMINATE_W) * 2 - T.px(PHOTO_W) - T.px(BODY_GAP) * 2
    local cellW = math.floor((dataW - T.px(10)) / 2)
    return cellW < labelNeed()
end
ZeD.IdentityTab.isTall = isTall

-- ============================================================================
-- THE NARROW LICENSE (Tennessee's layout)
-- ============================================================================

-- the small rows: { label key, field of data.small [, second label key, second field] }
local TALL_SMALL = {
    { "UI_ZeD_Identity_TagSex", "sex" },
    { "UI_ZeD_Identity_TagHair", "hair", "UI_ZeD_Identity_TagStyle", "style" },
    { "UI_ZeD_Identity_TagFacial", "facial", "UI_ZeD_Identity_TagBody", "body" },
    { "UI_ZeD_Identity_TagProf", "prof" },
    { "UI_ZeD_Identity_TagKills", "kills" },
    { "UI_ZeD_Identity_TagFav", "fav" },
}

-- Every height of the narrow card, one place for the measure and the draw. w is the width the
-- tab measures at (as if a scroll bar shows), so the height never hangs on the bar. The photo
-- is 44% of the width and 3:4, stretched to the column beside it when that is taller, up to
-- 1:2, the model's own shape (renderLicenseTall). On the half card what a wider card sets on
-- one line stacks when it won't fit: ISS and EXP over their dates, the small rows' pairs one
-- to a row. One table, refilled at each call.
local _tm = {}
local function tallMetrics(data, w)
    local T, tm = ZeD.T, ZeD.TM
    local sec, head = ZeD.Font.sdf.sec, ZeD.Font.sdf.head
    local m = _tm
    local lblH = tm:getFontHeight(T.fontF1)
    local dw = w - T.px(CARD_PAD) * 2 - T.px(LAMINATE_W) * 2 - T.px(TALL_PAD) * 2
    local photoW = math.floor(dw * 0.44)
    local sideW = dw - photoW - T.px(10)
    m.lblH = lblH
    m.l10, m.l11, m.l12, m.l13 = freeLineH(sec, 10), freeLineH(sec, 11), freeLineH(sec, 12), freeLineH(sec, 13)
    m.boxH = m.l12 * 2 + (T.line(2) + T.px(2)) * 2
    -- REVOKED hangs off the permit box's corner; where it would reach the DL NO label it sits in the box
    m.tagW = freeW(sec, ZeD.tr("UI_ZeD_Identity_Revoked"), freeZoom(10)) + (T.line(2) + T.px(4)) * 2
    m.tagH = m.l10 + T.line(2) * 2
    m.tagIn = data.permit == "revoked"
        and sideW + T.px(8) - m.tagW < tm:MeasureStringX(T.fontF1, ZeD.tr("UI_ZeD_Identity_TagDl")) + T.px(4)
    m.permitH = data.permit and (m.l11 * 2 + T.px(3) * 2 + (m.tagIn and (m.tagH + T.px(3)) or 0)) or 0
    m.bigH = freeLineH(head, BIG_TALL)
    local lblW = math.max(tm:MeasureStringX(T.fontF1, ZeD.tr("UI_ZeD_Identity_TagIss")),
        tm:MeasureStringX(T.fontF1, ZeD.tr("UI_ZeD_Identity_TagExp")))
    m.dateStack = lblW + T.px(4) + freeW(sec, data.issStr, freeZoom(11)) > sideW
    m.dateH = m.dateStack and (lblH + m.l11) or math.max(lblH, m.l11)
    local gap = T.px(3)
    local side = m.boxH + gap + (data.permit and (m.permitH + gap) or 0) + T.px(2)
        + lblH + m.l13 + gap + lblH + m.bigH * math.max(2, #data.survLines) + gap + m.dateH + gap + m.dateH
    m.rowH = math.max(math.floor(photoW * 4 / 3), side)
    m.surH, m.foreH = freeLineH(head, NAME_TALL), freeLineH(head, FORE_TALL)
    m.smallH = math.max(lblH, m.l13)
    -- the small rows' grid: the label columns as wide as their widest, the values sharing the rest
    local c1, c3 = 0, 0
    for i = 1, #TALL_SMALL do
        local r = TALL_SMALL[i]
        c1 = math.max(c1, tm:MeasureStringX(T.fontF1, ZeD.tr(r[1])))
        if r[3] then c3 = math.max(c3, tm:MeasureStringX(T.fontF1, ZeD.tr(r[3]))) end
    end
    local sg = T.px(6)
    local half = math.floor((dw - c1 - c3 - sg * 3) / 2)
    m.pairs = half >= freeW(sec, "0000000", freeZoom(13))
    m.c1, m.c3, m.half = m.pairs and c1 or math.max(c1, c3), c3, half
    m.smallN = m.pairs and #TALL_SMALL or (#TALL_SMALL + 2)
    m.smallTotal = m.smallH * m.smallN + gap * (m.smallN - 1)
    m.footH = math.max(T.px(SEAL_TALL), donorScale() * 10)
    m.bodyH = T.px(10) + m.rowH + T.px(10) + m.surH + m.foreH + T.px(8)
        + m.smallTotal + T.px(8) + m.footH + T.px(BODY_BOT)
    return m
end

local function measureTallH(data, w, expanded)
    local T = ZeD.T
    local bodyH = expanded and T.px(TALL_FULL) or tallMetrics(data, w).bodyH
    return T.px(CARD_PAD) * 2 + T.px(LAMINATE_W) * 2 + bandH() + bodyH
end

-- a centered free-size mono line, cut to its room
local function boxLine(panel, s, cx, y, px, room, c)
    local f, zoom = ZeD.Font.sdf.sec, freeZoom(px)
    s = fitFree(f, s, room, zoom)
    if s ~= "" then ZeD.Text.draw(panel, f, s, cx, y, zoom, c.r, c.g, c.b, 1, "c") end
end

-- a mono value at 13 px, or 11 when that does not fit, then cut, in a line h tall
local function drawMono(panel, s, x, y, room, h)
    local X, f = ZeD.Text, ZeD.Font.sdf.sec
    local px = (freeW(f, s, freeZoom(13)) > room) and 11 or 13
    local zoom = freeZoom(px)
    s = fitFree(f, s, room, zoom)
    if s ~= "" then
        X.draw(panel, f, s, x, y + math.floor((h - freeLineH(f, px)) / 2), zoom, KY.value.r, KY.value.g, KY.value.b, 1, "l")
    end
end

-- a small accent label and its date, side by side or the date under it (ISS, EXP)
local function dateRow(panel, acc, m, label, value, x, y, w)
    local T, tm = ZeD.T, ZeD.TM
    local sec, zoom = ZeD.Font.sdf.sec, freeZoom(11)
    label = ZeD.Atoms.truncateText(label, T.fontF1, w)
    local vx, vy = x, y + m.lblH
    if m.dateStack then
        panel:drawText(label, x, y, acc.r, acc.g, acc.b, 1, T.fontF1)
    else
        panel:drawText(label, x, y + math.floor((m.dateH - m.lblH) / 2), acc.r, acc.g, acc.b, 1, T.fontF1)
        vx, vy = x + tm:MeasureStringX(T.fontF1, label) + T.px(4), y + math.floor((m.dateH - m.l11) / 2)
    end
    local s = fitFree(sec, value, x + w - vx, zoom)
    if s ~= "" then ZeD.Text.draw(panel, sec, s, vx, vy, zoom, KY.value.r, KY.value.g, KY.value.b, 1, "l") end
end

-- REVOKED, a small red tag at the permit box's lower right, reaching past the box's corner,
-- or centered in the box's foot (square, as plain text can't turn)
local function drawRevokedTag(panel, x, w, bottom, m)
    local T, f = ZeD.T, ZeD.Font.sdf.sec
    local bt = T.line(2)
    local bx, by = x + w + T.px(8) - m.tagW, bottom + T.px(10) - m.tagH
    if m.tagIn then bx, by = x + math.floor((w - m.tagW) / 2), bottom - T.px(3) - m.tagH end
    panel:drawRect(bx, by, m.tagW, m.tagH, 0.85, KY.cardBg.r, KY.cardBg.g, KY.cardBg.b)
    ZeD.Atoms.frame(panel, bx, by, m.tagW, m.tagH, KY.red, 1, bt)
    ZeD.Text.draw(panel, f, ZeD.tr("UI_ZeD_Identity_Revoked"), bx + bt + T.px(4), by + bt, freeZoom(10),
        KY.red.r, KY.red.g, KY.red.b, 1, "l")
end

-- the column beside the photo: OPERATOR / CLASS D, the permit, DL NO, SURVIVED, ISS, EXP
local function drawTallSide(panel, data, m, acc, x, y, w)
    local T, A, X = ZeD.T, ZeD.Atoms, ZeD.Text
    local head = ZeD.Font.sdf.head
    local cx = x + math.floor(w / 2)
    local gap = T.px(3)
    local bt = T.line(2)
    local room = w - (bt + T.px(4)) * 2

    A.frame(panel, x, y, w, m.boxH, acc, 1, bt)
    boxLine(panel, ZeD.tr("UI_ZeD_Identity_Operator"), cx, y + bt + T.px(2), 12, room, acc)
    boxLine(panel, ZeD.tr("UI_ZeD_Identity_ClassD"), cx, y + bt + T.px(2) + m.l12, 12, room, acc)
    y = y + m.boxH + gap

    local permitBottom = nil
    if data.permit then
        panel:drawRect(x, y, w, m.permitH, 1, acc.r, acc.g, acc.b)
        local line = w - T.px(4) * 2
        boxLine(panel, ZeD.tr("UI_ZeD_Identity_PermitLine1"), cx, y + T.px(3), 11, line, KY.cardBg)
        boxLine(panel, ZeD.tr("UI_ZeD_Identity_PermitLine2"), cx, y + T.px(3) + m.l11, 11, line, KY.cardBg)
        y = y + m.permitH + gap
        permitBottom = y - gap
    end
    y = y + T.px(2)

    panel:drawText(A.truncateText(ZeD.tr("UI_ZeD_Identity_TagDl"), T.fontF1, w), x, y, acc.r, acc.g, acc.b, 1, T.fontF1)
    y = y + m.lblH
    drawMono(panel, data.dlNo, x, y, w, m.l13)
    y = y + m.l13 + gap

    panel:drawText(A.truncateText(ZeD.tr("UI_ZeD_Identity_TagSurvived"), T.fontF1, w), x, y, acc.r, acc.g, acc.b, 1, T.fontF1)
    y = y + m.lblH
    -- every line a step down when one won't fit, then cut; the lines keep the same pitch
    local lines = data.survLines
    local px = BIG_TALL
    for i = 1, #lines do
        if freeW(head, lines[i], freeZoom(BIG_TALL)) > w then px = BIG_SMALL end
    end
    local zBig = freeZoom(px)
    local inset = math.floor((m.bigH - freeLineH(head, px)) / 2)
    for i = 1, #lines do
        local s = fitFree(head, lines[i], w, zBig)
        if s ~= "" then X.draw(panel, head, s, x, y + (i - 1) * m.bigH + inset, zBig, KY.name.r, KY.name.g, KY.name.b, 1, "l") end
    end
    y = y + m.bigH * math.max(2, #lines) + gap

    dateRow(panel, acc, m, ZeD.tr("UI_ZeD_Identity_TagIss"), data.issStr, x, y, w)
    dateRow(panel, acc, m, ZeD.tr("UI_ZeD_Identity_TagExp"), data.expStr, x, y + m.dateH + gap, w)

    if permitBottom and data.permit == "revoked" then drawRevokedTag(panel, x, w, permitBottom, m) end
end

-- one small row: the label, the value in room
local function smallRow(panel, acc, m, label, value, x, vx, y, room)
    local T = ZeD.T
    panel:drawText(ZeD.tr(label), x, y + math.floor((m.smallH - m.lblH) / 2), acc.r, acc.g, acc.b, 1, T.fontF1)
    drawMono(panel, value, vx, y, room, m.smallH)
end

-- the small rows: label, value, and on two of them a second label and value beside the first
-- (or under it, on a card too narrow for the pair)
local function drawSmallRows(panel, data, acc, m, x, y, w)
    local T = ZeD.T
    local gap = T.px(6)
    local step = m.smallH + T.px(3)
    local vx = x + m.c1 + gap
    for i = 1, #TALL_SMALL do
        local r = TALL_SMALL[i]
        if r[3] and m.pairs then
            local lx = vx + m.half + gap
            smallRow(panel, acc, m, r[1], data.small[r[2]], x, vx, y, m.half)
            smallRow(panel, acc, m, r[3], data.small[r[4]], lx, lx + m.c3 + gap, y, m.half)
        else
            smallRow(panel, acc, m, r[1], data.small[r[2]], x, vx, y, x + w - vx)
            if r[3] then
                y = y + step
                smallRow(panel, acc, m, r[3], data.small[r[4]], x, vx, y, x + w - vx)
            end
        end
        y = y + step
    end
end

-- the state, large and faint, behind the fields: 64 design units over the body's foot,
-- at the art's whole number, or the next one down while it is wider than the card
local function drawWatermark(panel, ix, iw, bottom)
    local tex = kyArt("ky_watermark")
    if not tex then return end
    local s = artScale()
    local tw = tex:getWidth()
    while s > 1 and tw * s > iw do s = s - 1 end
    if tw * s > iw then return end
    drawArt(panel, tex, ix + math.floor((iw - tw * s) / 2), bottom - ZeD.T.px(64) - tex:getHeight() * s, s, 0.9)
end

-- the foot: the faded seal at the left, the donor pill at the right, on the same bottom line
local function drawTallFoot(panel, m, x, y, w)
    local T = ZeD.T
    local bottom = y + m.footH
    local sz = T.px(SEAL_TALL)
    local seal = sealTex()
    if seal then panel:drawTextureScaledAspect(seal, x, bottom - sz, sz, sz, 0.4, 1, 1, 1) end
    local donor = kyArt("ky_donor")
    if not donor then return end
    local ds, dw = donorScale(), donor:getWidth()
    while ds > 1 and sz + T.px(8) + dw * ds > w do ds = ds - 1 end
    if sz + T.px(8) + dw * ds <= w then
        drawArt(panel, donor, x + w - dw * ds, bottom - donor:getHeight() * ds, ds)
    end
end

local function renderLicenseTall(panel, win, data, x, drawY, w, layoutW)
    local A, T = ZeD.Atoms, ZeD.T
    local expanded = win._identityPhotoExpanded and true or false
    local totalH = measureTallH(data, layoutW, expanded) - T.px(CARD_PAD) * 2
    local m = tallMetrics(data, layoutW)
    local ix, bodyY, iw, bodyH = drawCardShell(panel, win, x, drawY, w, totalH, true, expanded)

    -- the full body: the whole card under the header, the model at its foot
    if expanded then
        panel:drawRect(ix, bodyY, iw, bodyH, 1.0, KY.skyBlue.r, KY.skyBlue.g, KY.skyBlue.b)
        local mh = T.px(TALL_MODEL)
        setPhoto(win, ix, bodyY + bodyH - mh, iw, mh, true, ix, bodyY, iw, bodyH)
        return
    end

    drawWatermark(panel, ix, iw, bodyY + bodyH)
    local acc = kyAccent(win)
    local dx, dw = ix + T.px(TALL_PAD), iw - T.px(TALL_PAD) * 2
    local y = bodyY + T.px(10)

    -- the photo, and the column beside it. The model scales with its rect's height (AnimatedModel's
    -- camera) and past 1:2 would show only the middle of the face, so the frame stops at 1:2, the
    -- row's top; where the column runs longer (the half card) the cream shows under the photo.
    local pw = math.floor(dw * 0.44)
    local ph = math.min(m.rowH, pw * 2)
    A.fillRounded(panel, dx, y, pw, ph, KY.skyBlue.r, KY.skyBlue.g, KY.skyBlue.b, 1.0)
    setPhoto(win, dx, y, pw, ph, false)
    drawTallSide(panel, data, m, acc, dx + pw + T.px(10), y, dw - pw - T.px(10))
    y = y + m.rowH + T.px(10)

    -- the name big, the surname over the forename; the weight beside the surname
    drawNameRow(panel, data, data.surUp, dx, y, dw, NAME_TALL, KY.name, acc)
    y = y + m.surH
    local zoom = freeZoom(FORE_TALL)
    local fore = fitName(data.foreUp, dw, zoom)
    if fore ~= "" then
        ZeD.Text.draw(panel, ZeD.Font.sdf.head, fore, dx, y, zoom, KY.name.r, KY.name.g, KY.name.b, 1, "l")
    end
    y = y + m.foreH + T.px(8)

    drawSmallRows(panel, data, acc, m, dx, y, dw)
    drawTallFoot(panel, m, dx, y + m.smallTotal + T.px(8), dw)
end

-- ============================================================================
-- SIMPLE, WIDE AND NARROW: ZeD's own components on the theme's surface; label / value
-- rows, labels in the accent, no rules
-- ============================================================================

local function simpleRowH()
    local T, tm = ZeD.T, ZeD.TM
    return math.max(tm:getFontHeight(T.fontF1), tm:getFontHeight(T.fontF2)) + T.px(8)
end

-- the width of Simple's rows at the width the tab measures at, so the wrapping never hangs on
-- the scroll bar
local function simpleRowW(layoutW, tall)
    local T = ZeD.T
    local w = layoutW - T.px(PLAIN_PAD) * 2
    if tall then return w end
    return w - T.px(PHOTO_SIZE) - T.px(BODY_GAP)
end

-- The label of Simple's row i. The game's English writes its three (TALL_LABELS' "v") in title
-- case and the card reads in sentence case, so English lowers all but the first letter; the
-- other languages keep the game's words (German's nouns keep their capitals).
local _rowLabel = {}
local function simpleLabel(i)
    local s = tallLabel(i)
    if TALL_LABELS[i][1] ~= "v" then return s end
    local c = _rowLabel[s]
    if not c then
        local ok, lang = pcall(function() return Translator.getLanguage():name() end)
        c = (ok and lang == "EN") and (string.sub(s, 1, 1) .. string.lower(string.sub(s, 2))) or s
        _rowLabel[s] = c
    end
    return c
end

-- a value's lines under its label: split at its commas, as many parts to a line as fit, a part
-- too wide for the row cut with "..."
local function valueLines(value, w)
    local T, tm, A = ZeD.T, ZeD.TM, ZeD.Atoms
    local f = T.fontF2
    local parts = splitSurvived(value)
    local out, cur = {}, parts[1]
    for i = 2, #parts do
        local joined = cur .. ", " .. parts[i]
        if tm:MeasureStringX(f, joined .. ",") <= w then
            cur = joined
        else
            out[#out + 1] = A.truncateText(cur .. ",", f, w)
            cur = parts[i]
        end
    end
    out[#out + 1] = A.truncateText(cur, f, w)
    return out
end

-- Simple's rows at width w, one place for the measure and the draw: { label, lines, lineW, beside }
-- and h, the rows' whole height. A row is the label with the value beside it while the two fit;
-- else the value goes under the label, right-aligned (the half card). Kept with the data, which
-- is made anew every 30 frames (half a second at 60 fps), so nothing is measured every frame.
local function simpleRows(data, w)
    local T, tm, A = ZeD.T, ZeD.TM, ZeD.Atoms
    local c = data._rows
    if c and c.w == w and c.scale == T.scale and c.f1 == T.fontF1 and c.f2 == T.fontF2 then return c end
    c = { w = w, scale = T.scale, f1 = T.fontF1, f2 = T.fontF2, h = 0 }
    data._rows = c
    local gap, rh, valH = T.px(8), simpleRowH(), tm:getFontHeight(T.fontF2)
    local function add(label, value)
        value = tostring(value or "")
        local r = { label = A.truncateText(label, T.fontF1, w) }
        r.beside = tm:MeasureStringX(T.fontF1, label) + gap + tm:MeasureStringX(T.fontF2, value) <= w
        r.lines = r.beside and { value } or valueLines(value, w)
        r.lineW = {}
        for i = 1, #r.lines do r.lineW[i] = tm:MeasureStringX(T.fontF2, r.lines[i]) end
        c[#c + 1] = r
        c.h = c.h + rh + (r.beside and 0 or valH * #r.lines)
    end
    local vals = { data.sexStr, data.profession, data.hairStyle, data.hairColor, data.facialHair,
        data.bodyHair, data.timeSurv, data.favWeapon, data.zKills }
    for i = 1, #TALL_LABELS do add(simpleLabel(i), vals[i]) end
    if data.permit then
        add(ZeD.tr("UI_ZeD_Identity_CarryPermit"),
            ZeD.tr(data.permit == "revoked" and "UI_ZeD_Identity_CarryRevoked" or "UI_ZeD_Identity_CarryYes"))
    end
    return c
end

local function measureSimpleH(data, tall, expanded, layoutW)
    local T = ZeD.T
    local nameH = freeLineH(ZeD.Font.sdf.head, NAME_WIDE)
    local margins = T.px(PLAIN_TOP) * 2
    local rowsH = simpleRows(data, simpleRowW(layoutW, tall)).h
    if not tall then
        local ph = T.px(expanded and PLAIN_FULL_WIDE or PHOTO_SIZE)
        return margins + math.max(ph, nameH + T.px(6) + rowsH)
    end
    if expanded then
        return margins + T.px(PLAIN_FULL_TALL) + T.px(8) + nameH + T.px(6) + rowsH
    end
    return margins + math.max(T.px(PLAIN_BUST), nameH * 3) + T.px(8) + rowsH
end

-- the avatar's box: surface-2 with the strong border, the model inside the border at the box's
-- foot, modelH tall (nil: the whole box)
local function drawSimplePhoto(panel, win, x, y, w, h, expanded, modelH)
    local T = ZeD.T
    local s = T.surf2
    panel:drawRect(x, y, w, h, s.a or 1, s.r, s.g, s.b)
    ZeD.Atoms.frame(panel, x, y, w, h, T.borderS)
    local t = T.hair
    local mh = math.min(modelH or h, h - t * 2)
    setPhoto(win, x + t, y + h - t - mh, w - t * 2, mh, expanded, x, y, w, h)
end

-- the rows: the label at the left (F1, the accent as text), the value at the right (F2),
-- beside the label or under it (simpleRows)
local function drawSimpleRows(panel, data, x, y, w, rowW)
    local T, tm = ZeD.T, ZeD.TM
    local rows = simpleRows(data, rowW)
    local rh = simpleRowH()
    local lblH, valH = tm:getFontHeight(T.fontF1), tm:getFontHeight(T.fontF2)
    local lc, vc = T.accentText, T.text
    for i = 1, #rows do
        local r = rows[i]
        if r.label ~= "" then
            panel:drawText(r.label, x, y + math.floor((rh - lblH) / 2), lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)
        end
        local vy = r.beside and (y + math.floor((rh - valH) / 2)) or (y + rh - T.px(4))
        for j = 1, #r.lines do
            if r.lines[j] ~= "" then
                panel:drawText(r.lines[j], x + w - r.lineW[j], vy, vc.r, vc.g, vc.b, vc.a or 1, T.fontF2)
            end
            vy = vy + valH
        end
        y = y + rh + (r.beside and 0 or valH * #r.lines)
    end
end

-- the narrow bust: the box beside the name, the weight and the profession, the block at the
-- box's foot. On the half card the name takes two lines when one would cut it, and the
-- profession its own line when it won't fit beside the weight, in F5 when F3 won't fit that.
local function drawSimpleBust(panel, win, data, x, y, w)
    local T, tm, X, head = ZeD.T, ZeD.TM, ZeD.Text, ZeD.Font.sdf.head
    local box = T.px(PLAIN_BUST)
    local nameH = freeLineH(head, NAME_WIDE)
    local topH = math.max(box, nameH * 3)
    drawSimplePhoto(panel, win, x, y, box, box, false)
    local tx = x + box + T.px(12)
    local tw = w - box - T.px(12)
    local zoom = freeZoom(NAME_WIDE)
    local tc, sc = T.text, T.textSec
    local twoLines = freeW(head, data.nameFull, zoom) > tw and data.forename ~= "" and data.surname ~= ""
    local wt = weightW(data, zoom)
    local profF = T.fontF3
    local profW = tm:MeasureStringX(profF, data.profession)
    local profBeside = wt + T.px(8) + profW <= tw
    if not profBeside and profW > tw then
        profF = T.fontF5
        profW = tm:MeasureStringX(profF, data.profession)
    end
    local profH = tm:getFontHeight(profF)
    local ty = y + topH - nameH * (twoLines and 3 or 2) - (profBeside and 0 or profH)
    if twoLines then
        X.draw(panel, head, fitName(data.forename, tw, zoom), tx, ty, zoom, tc.r, tc.g, tc.b, tc.a or 1, "l")
        ty = ty + nameH
        X.draw(panel, head, fitName(data.surname, tw, zoom), tx, ty, zoom, tc.r, tc.g, tc.b, tc.a or 1, "l")
    else
        X.draw(panel, head, fitName(data.nameFull, tw, zoom), tx, ty, zoom, tc.r, tc.g, tc.b, tc.a or 1, "l")
    end
    ty = ty + nameH
    if wt <= tw then drawWeight(panel, data, tx, ty, zoom, tc, T.accentText) end
    if profBeside then
        panel:drawText(data.profession, tx + tw - profW, ty + nameH - profH, sc.r, sc.g, sc.b, sc.a or 1, profF)
    else
        panel:drawText(ZeD.Atoms.truncateText(data.profession, profF, tw), tx, ty + nameH, sc.r, sc.g, sc.b, sc.a or 1, profF)
    end
    return topH
end

local function renderSimple(panel, win, data, x, drawY, w, tall, layoutW)
    local T = ZeD.T
    local rowW = simpleRowW(layoutW, tall)
    local expanded = win._identityPhotoExpanded and true or false
    local px, pw = x + T.px(PLAIN_PAD), w - T.px(PLAIN_PAD) * 2
    local y = drawY + T.px(PLAIN_TOP)
    local nameH = freeLineH(ZeD.Font.sdf.head, NAME_WIDE)
    if not tall then
        local box = T.px(PHOTO_SIZE)
        drawSimplePhoto(panel, win, px, y, box, T.px(expanded and PLAIN_FULL_WIDE or PHOTO_SIZE), expanded)
        local tx, tw = px + box + T.px(BODY_GAP), pw - box - T.px(BODY_GAP)
        drawNameRow(panel, data, data.nameFull, tx, y, tw, NAME_WIDE, T.text, T.accentText)
        drawSimpleRows(panel, data, tx, y + nameH + T.px(6), tw, rowW)
    elseif expanded then
        local fh = T.px(PLAIN_FULL_TALL)
        drawSimplePhoto(panel, win, px, y, pw, fh, true, T.px(PLAIN_MODEL))
        y = y + fh + T.px(8)
        drawNameRow(panel, data, data.nameFull, px, y, pw, NAME_WIDE, T.text, T.accentText)
        drawSimpleRows(panel, data, px, y + nameH + T.px(6), pw, rowW)
    else
        y = y + drawSimpleBust(panel, win, data, px, y, pw)
        drawSimpleRows(panel, data, px, y + T.px(8), pw, rowW)
    end
end

-- ============================================================================
-- ZONE B HEIGHT — traits section
-- ============================================================================

-- a trait row's height: the line and 3 units over and under it, at least TRAIT_ROW_H
local function traitRowH()
    local T = ZeD.T
    return math.max(T.px(TRAIT_ROW_H), ZeD.TM:getFontHeight(T.fontF2) + T.px(6))
end

local function measureZoneBH(data, cols)
    local T = ZeD.T
    local pad   = T.sp.sm
    local h = pad + T.px(20) + T.sp.afterGroove  -- section head (20u, its line under it)

    -- Positive traits
    if #data.posTraits > 0 then
        h = h + T.px(15) + T.sp.xs  -- "Positive" category row (15u)
        local rows = math.ceil(#data.posTraits / cols)
        h = h + rows * (traitRowH() + T.px(TRAIT_GAP))
        h = h + T.sp.sm
    end

    -- Negative traits
    if #data.negTraits > 0 then
        h = h + T.px(15) + T.sp.xs  -- "Negative" category row (15u)
        local rows = math.ceil(#data.negTraits / cols)
        h = h + rows * (traitRowH() + T.px(TRAIT_GAP))
        h = h + T.sp.sm
    end

    return h
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

local _traitIds = {}   -- (a trait's controller id, "identity:trait:<name>", made once)
local WHITE = { r = 1, g = 1, b = 1 }   -- (the trait icons keep their own colors)

--- A trait row's places across: the icon (18 units, the game's own size), the dot, the name.
--- (one table, made again only when the row height or the theme changes)
local _traitLay = {}
function ZeD.IdentityTab.traitRowLayout(rh)
    local T = ZeD.T
    local L = _traitLay
    if L.rh == rh and L.T == T then return L end
    local icon = math.min(T.px(18), rh)
    local dot = T.px(8)
    local dotX = icon + T.px(6)
    L.rh, L.T = rh, T
    L.icon, L.iconX, L.iconY = icon, 0, math.floor((rh - icon) / 2)
    L.dot, L.dotX, L.nameX = dot, dotX, dotX + dot + T.px(8)
    return L
end
local function renderTraitRow(panel, win, trait, tx, ty, tw, color)
    local T = ZeD.T
    local A = ZeD.Atoms
    local rh = traitRowH()
    local bodyH = ZeD.TM:getFontHeight(T.fontF2)

    -- its description shows on hover and on controller focus (drawTraitHint); the
    -- zone is kept for both
    local key = trait.name ~= nil and _traitIds[trait.name] or nil
    if not key then
        key = "identity:trait:" .. tostring(trait.name)
        if trait.name ~= nil then _traitIds[trait.name] = key end
    end
    local zones = win._idTraitZones
    local n = (zones.n or #zones) + 1
    zones.n = n
    local z = zones[n] or {}
    z.x, z.y, z.w, z.h, z.id, z.name, z.desc = tx, ty, tw, rh, key, trait.name, trait.desc
    zones[n] = z

    -- the hover wash and the controller's mark under the words
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

    -- the trait's icon, the dot (good or bad), then the name
    local lay = ZeD.IdentityTab.traitRowLayout(rh)
    if trait.texture then
        A.drawIcon(panel, trait.texture, tx + lay.iconX, ty + lay.iconY, lay.icon, 1, WHITE)
    end
    local sq = lay.dot
    panel:drawRect(tx + lay.dotX, ty + math.floor((rh - sq) / 2), sq, sq, color.a or 1, color.r, color.g, color.b)
    local nameX = tx + lay.nameX
    local nameY = ty + math.floor((rh - bodyH) / 2)
    local nc = focused and T.textOnFocus or T.text
    panel:drawText(A.truncateText(trait.name, T.fontF2, tx + tw - nameX), nameX, nameY,
        nc.r, nc.g, nc.b, nc.a or 1, T.fontF2)
end

local function renderTraitGroup(panel, win, traits, label, x, curY, contentW, color, cols)
    local T    = ZeD.T

    -- Category row ("Positive (3)": the count is in the label), not folding
    curY = curY + ZeD.Molecules.drawCategoryRow(panel, x, curY, contentW, label, nil, true, { noArrow = true, inset = 0 }) + T.sp.xs

    -- The grid: two columns wide, one narrow
    local gap = T.px(TRAIT_COL_GAP)
    local pitch = traitRowH() + T.px(TRAIT_GAP)
    local colW = (cols > 1) and math.floor((contentW - gap * (cols - 1)) / cols) or contentW
    for i, trait in ipairs(traits) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local tx = x + col * (colW + gap)
        local ty = curY + row * pitch
        renderTraitRow(panel, win, trait, tx, ty, colW, color)
    end

    local rows = math.ceil(#traits / cols)
    curY = curY + rows * pitch + T.sp.sm
    return curY
end

local function renderZoneB(panel, win, data, x, drawY, w, cols)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local pad  = T.sp.sm
    local contentW = w - pad * 2

    local curY = drawY + pad

    local totalCount = #data.posTraits + #data.negTraits

    -- Section head (20u, sentence case, the total at the right, the content line under it); not folding
    curY = curY + ZeD.Molecules.drawSectionHeader(panel, x + pad, curY, contentW, getText("IGUI_char_Traits"),
        totalCount > 0 and totalCount or nil, true, false, nil, nil, nil, nil, true) + T.sp.afterGroove

    if totalCount == 0 then
        ZeD.Molecules.drawEmptyLine(panel, x + pad, curY, contentW, ZeD.tr("UI_ZeD_Identity_NoTraits"))
        return
    end

    -- Positive traits
    if #data.posTraits > 0 then
        curY = renderTraitGroup(panel, win, data.posTraits,
            ZeD.tr("UI_ZeD_Identity_TraitsPositive", #data.posTraits),
            x + pad, curY, contentW, T.positive, cols)
    end

    -- Negative traits
    if #data.negTraits > 0 then
        curY = renderTraitGroup(panel, win, data.negTraits,
            ZeD.tr("UI_ZeD_Identity_TraitsNegative", #data.negTraits),
            x + pad, curY, contentW, T.danger, cols)
    end
end

-- ============================================================================
-- MAIN RENDERER
-- ============================================================================

-- Simple or Immersive, read fresh (ZeD setup; QA: qaStyle)
local function useSimple()
    local q = ZeD.IdentityTab.qaStyle
    if q == "simple" then return true elseif q == "immersive" then return false end
    local S = ZeD.Settings
    return (S and S.identitySimple and S.identitySimple()) and true or false
end

local function measureZoneA(data, tall, simple, expanded, layoutW)
    if simple then return measureSimpleH(data, tall, expanded, layoutW) end
    if tall then return measureTallH(data, layoutW, expanded) end
    return measureWideH(expanded)
end

local function renderZoneA(panel, win, data, x, drawY, w, tall, simple, layoutW)
    if simple then
        renderSimple(panel, win, data, x, drawY, w, tall, layoutW)
    elseif tall then
        renderLicenseTall(panel, win, data, x, drawY, w, layoutW)
    else
        renderLicenseWide(panel, win, data, x, drawY, w)
    end
end

function ZeD.IdentityTab.render(panel, win, x, y, w, h)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local M    = ZeD.Molecules
    local I    = ZeD.IdentityTab

    -- Throttled data refresh (QA's forced trend and profession show at once)
    win._identityTimer = (win._identityTimer or 0) + 1
    if win._identityTimer >= 30 or not win._identityCache
       or win._idQaTrend ~= I.qaTrend or win._idQaProf ~= I.qaProf then
        win._identityTimer = 0
        win._idQaTrend, win._idQaProf = I.qaTrend, I.qaProf
        win._identityCache = I.gatherData(win._playerObj)
    end
    local data = win._identityCache

    -- Pinned tab header (37 design units, not in scroll content)
    local tabHeaderH = M.getTabHeaderH()

    -- Stamp the disclosure hit-zone EARLY, as SkillsTab and HealthTab do. The
    -- tab header is a disclosure that toggles the license photo between bust
    -- (collapsed) and full-body (expanded). The focusable builder in
    -- ZeD_CharacterWindow reads _identityFigureZone each frame; a zone stamped
    -- at the end of render is still nil on the first prerender after a tab
    -- switch, so stamping at the top is what puts the disclosure in element[1].
    win._identityFigureZone = { x = x, y = y, w = w, h = tabHeaderH }

    -- ================================================================
    -- SCROLL (starts below pinned header)
    -- ================================================================
    local scroll  = win._identityScroll
    local scrollW = T.sp.scrollbarW

    -- Hair and beard (ZeD_HairBeard.lua): a fold under the license; Cut sits in it, beside its
    -- Hair | Beard switch. The card has no footer band (nothing on the whole card to do).
    local HB = ZeD.HairBeard
    local hbL = HB and HB.layout(win, w - T.sp.scrollbarW) or nil
    local zoneHH = hbL and hbL.h or 0

    -- wide or narrow by the width, measured as if a scroll bar shows; the
    -- heights hang on this width alone, so they agree with the draw with or without the bar
    local layoutW = w - T.sp.scrollbarW
    local tall = isTall(layoutW)
    local simple = useSimple()
    win._idTall, win._idSimple = tall, simple
    local traitCols = tall and 1 or 2
    local zoneAH = measureZoneA(data, tall, simple, win._identityPhotoExpanded, layoutW)
    local zoneBH = measureZoneBH(data, traitCols)
    local totalContentH = zoneAH + zoneHH + zoneBH

    local scrollY = y + tabHeaderH
    local scrollH = h - tabHeaderH
    local needsScroll = totalContentH > scrollH
    scroll.visible = needsScroll
    -- (a make-up item's Make Up option: the Hair and beard section into view, ZeD_HairBeard.showMakeUp)
    if HB and HB.takeScroll and HB.takeScroll(win) and needsScroll then
        scroll:setScrollPos(math.min(1, zoneAH / math.max(1, totalContentH - scrollH)))
    end
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

    -- The grid-scroll pseudo-zone, as on the Thermal tab: one stop over the
    -- visible region below the tab header; D-pad up/down scrolls, and at the
    -- ends it falls through to the spatial pick, back to the disclosure above.
    -- The tab's own stops (the Hair and beard rows, each trait:
    -- IdentityTab.focusables) take its place; ZeD_CharacterWindow falls back
    -- to this zone only when IdentityTab.focusables is missing. Stamped only
    -- when scroll is actually needed; otherwise nil (builder skips).
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
    -- ZONE A: the card
    -- ================================================================
    renderZoneA(panel, win, data, x, drawY, contentW, tall, simple, layoutW)

    -- the help band over the photo (the model on it takes the click, the hover reads here)
    local pz = win._identityPhotoZone
    if pz and ZeD.Help and A.mouseIn(panel, pz.x, pz.y, pz.w, pz.h, win._idView) then
        ZeD.Help.set(win, ZeD.tr(win._identityPhotoExpanded and "UI_ZeD_Identity_HelpPhotoBack" or "UI_ZeD_Identity_HelpPhoto"))
    end

    -- ================================================================
    -- ZONE H: Hair and beard
    -- ================================================================
    if hbL then HB.draw(panel, win, hbL, x, drawY + zoneAH, contentW, scrollY, scrollH) end

    -- ================================================================
    -- ZONE B: Traits
    -- ================================================================
    -- (the trait zones' list and tables are the window's, refilled each frame: zones.n are live)
    local tz = win._idTraitZoneList or {}
    win._idTraitZoneList = tz
    tz.n = 0
    win._idTraitZones = tz
    renderZoneB(panel, win, data, x, drawY + zoneAH + zoneHH, contentW, traitCols)
    for i = tz.n + 1, #tz do tz[i] = nil end

    panel:clearStencilRect()

    -- the model joins the card in this frame, not the next (its rect was just published)
    if win._placeIdentityModel then win._placeIdentityModel(w) end

    -- Pinned tab header: the disclosure arrow turns with _identityPhotoExpanded
    -- (collapsed = bust, right-pointing; expanded = full body, down). A on it
    -- (controller), the header click (mouse) and a click on the photo all toggle it.
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

local function traitOnFocus() end   -- (a trait is read, not pressed: one callback for every trait's stop)

--- The controller's stops below the disclosure: Hair and beard's, then each trait
--- (ZeD_CharacterWindow's Identity aggregator puts the disclosure first).
function ZeD.IdentityTab.focusables(win)
    local out = {}
    if ZeD.HairBeard then
        for _, e in ipairs(ZeD.HairBeard.focusables(win)) do out[#out + 1] = e end
    end
    for _, z in ipairs(win._idTraitZones or {}) do
        out[#out + 1] = { x = z.x, y = z.y, w = z.w, h = z.h, id = z.id, onFocus = traitOnFocus }
    end
    return out
end

--- A click in the tab's content (the hair rows, the switch, Out of reach, Cut); the photo's
--- frame around the model picks the photo as the model does. True when the click was the tab's.
function ZeD.IdentityTab.onClick(win, x, y)
    if ZeD.HairBeard ~= nil and ZeD.HairBeard.onClick(win, x, y) then return true end
    local z, v = win._identityPhotoZone, win._idView
    if z and x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h
       and (not v or (y >= v.y and y < v.y + v.h)) then
        win._identityPhotoExpanded = not win._identityPhotoExpanded
        win._identityCustomZoom = 0
        if win._identityScroll then win._identityScroll:setScrollPos(0) end
        return true
    end
    return false
end

--- What moves the stops, as one string, for the window's rebuild check.
function ZeD.IdentityTab.scrollKey(win)
    local sc = win._identityScroll
    return tostring(sc and sc.scrollPos or 0) .. ":" .. (ZeD.HairBeard and ZeD.HairBeard.key(win) or "")
        .. ":" .. tostring(#(win._idTraitZones or {}))
        .. ":" .. tostring(win._identityPhotoExpanded) .. tostring(win._idTall) .. tostring(win._idSimple)
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

--- Put the tab's renderer in a window's tab dispatch table (the Character
--- window's, under "identity").
function ZeD.IdentityTab.register(dispatchTable)
    dispatchTable["identity"] = ZeD.IdentityTab.render
end
