-- ZeD-UI/42/media/lua/client/ZeD/ForagingTab.lua
-- ============================================================================
-- FORAGING TAB — World Window standalone tab.
-- Surfaces vanilla foraging data: zone, radius, modifiers, categories in range,
-- recent finds. Gameplay-neutral — never reveals pre-discovery spawns.
-- Design: zed-foraging-quiet-v5.html (S70 approved).
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "Foraging/ISSearchManager"

ZeD = ZeD or {}
ZeD.ForagingTab = {}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local HERO_SCENE_W     = 112     -- terrain scene cell width
local HERO_RADIUS_W    = 88      -- radius/net cell width
local HERO_PAD         = 12      -- padding inside hero info cell
local HERO_MIN_H       = 112     -- minimum hero band height

local STANCE_ROW_H     = 26
local FOCUS_ROW_H      = 38
local FOCUS_PAD_X      = 8
local FOCUS_GAP        = 8

local DISCLOSURE_H     = 22
local SUB_HEADER_H     = 16
local GRID_ROW_H       = 17
local GRID_PAD_X       = 12
local GRID_DOT_SZ      = 6
local GRID_DOT_GAP     = 7

local FINDS_HEADER_H   = 16
local FINDS_ROW_H      = 20
local FINDS_ICON_SZ    = 14
local FINDS_ICON_GAP   = 6
local FINDS_DIST_W     = 48
local FINDS_WT_W       = 36
local FINDS_PAD_X      = 12
local FINDS_MAX        = 20      -- LIFO cap

-- ============================================================================
-- LIVE DATA GETTERS (S72 — replaces mock data with vanilla API calls)
-- ============================================================================

local ZONE_FRIENDLY_NAMES = {
    DeepForest    = "Deep Forest",
    FarmLand      = "Farmland",
    Farm          = "Farm",
    Forest        = "Forest",
    ForagingNav   = "Trail",
    Nav           = "Road",
    TownZone      = "Town",
    TrailerPark   = "Trailer Park",
    Vegitation    = "Wild Growth",
    PHForest      = "Pine Hills",
    PHMixForest   = "Pine Hills Mix",
    PRForest      = "Pine Ridge",
    FarmMixForest = "Farm Mix",
    FarmForest    = "Farm Forest",
    BirchForest   = "Birch Forest",
    BirchMixForest = "Birch Mix",
    OrganicForest = "Organic Forest",
}

-- (translation keys: the game's own season names, ZeD's for Summer, which the game splits in two)
local SEASON_MAP = {
    [0] = "IGUI_Season_Winter", "IGUI_Season_Winter", "IGUI_Season_Spring", "IGUI_Season_Spring", "IGUI_Season_Spring",
    "UI_ZeD_Forage_SeasonSummer", "UI_ZeD_Forage_SeasonSummer", "UI_ZeD_Forage_SeasonSummer",
    "IGUI_Season_Autumn", "IGUI_Season_Autumn", "IGUI_Season_Autumn", "IGUI_Season_Winter",
}

-- The words the hero chips and rows show for the ids the getters below answer with
-- (the ids are compared in code; only these keys are translated, at the point of use).
ZeD.ForagingTab.WORDS = {
    Good = "UI_ZeD_Forage_CondGood", Fair = "UI_ZeD_Forage_CondFair", Poor = "UI_ZeD_Forage_CondPoor",
    Walking = "UI_ZeD_Forage_StanceWalking", Aiming = "UI_ZeD_Forage_StanceAiming",
    Sneaking = "UI_ZeD_Forage_StanceSneaking", Searching = "UI_ZeD_Forage_StanceSearching",
    Fog = "UI_ZeD_Forage_WxFog", Storm = "UI_ZeD_Forage_WxStorm", Rain = "UI_ZeD_Forage_WxRain",
    Snow = "UI_ZeD_Forage_WxSnow", Overcast = "UI_ZeD_Forage_WxOvercast", Cloudy = "UI_ZeD_Forage_WxCloudy",
    Clear = "UI_ZeD_Forage_WxClear",
}
function ZeD.ForagingTab.word(id)
    return ZeD.tr(ZeD.ForagingTab.WORDS[id] or "UI_ZeD_Forage_Unknown")
end

local TRAIT_FRIENDLY = {
    EagleEyed   = "Eagle Eyed",   Formerscout   = "Former Scout",
    NightVision = "Night Vision",  WildernessKnowledge = "Wilderness",
    HeartyAppetite = "Hearty App.", ShortSighted = "Short Sighted",
    Cook2 = "Master Cook",  Nutritionist2 = "Expert Nutr.",
    Herbalist_Prof = "Prof. Herbalist", FirstAid = "First Aid",
}

-- 8-compass bearing from angle (radians) -----------------------------------
-- (translation keys: the letters differ between languages; translated where the find is drawn)
local COMPASS = {
    "UI_ZeD_Forage_CompassN", "UI_ZeD_Forage_CompassNE", "UI_ZeD_Forage_CompassE", "UI_ZeD_Forage_CompassSE",
    "UI_ZeD_Forage_CompassS", "UI_ZeD_Forage_CompassSW", "UI_ZeD_Forage_CompassW", "UI_ZeD_Forage_CompassNW",
}
-- ============================================================================
-- S109b — GAMEPAD FOCUS CUE HELPERS (mirror of AnimalsTab pattern).
-- Paint gate reads live focused element from FocusManager; matcher closure
-- discriminates between element types (isStance / isDropdown / isDisclosure).
-- ============================================================================

local function _gpFocusMatches(win, matcherFn)
    if not (ZeD and ZeD.Input and ZeD.Input.Focus) then return false end
    local Focus = ZeD.Input.Focus
    local zone = Focus.getFocusedZone and Focus.getFocusedZone(win)
    if not zone or zone.zone ~= "worldTabContent" then return false end
    local el = Focus.getFocusedElement and Focus.getFocusedElement(win)
    if not el then return false end
    return matcherFn(el)
end

local function _paintGpCue(panel, x, y, w, h)
    local T = ZeD.T
    if not T or not T.accent then return end
    panel:drawRect(x, y, w, h, 0.55, T.accent.r, T.accent.g, T.accent.b)
end

local function angleToBearing(rad)
    -- rad: 0 = east, pi/2 = north (PZ Y- is north)
    local deg = math.deg(rad) % 360
    local idx = math.floor((deg + 22.5) / 45) % 8 + 1
    return COMPASS[idx]
end

-- Zone name (friendly) -----------------------------------------------------
local function getZoneName(win)
    local p = win._playerObj
    if not p then return ZeD.tr("UI_ZeD_Forage_Unknown") end
    local zoneDef = forageSystem.getDefinedZoneAt(p:getX(), p:getY())
    if not zoneDef then return ZeD.tr("UI_ZeD_Forage_Unknown") end
    -- the game's own name for the zone, else ZeD's English one (a zone a mod adds)
    return getTextOrNull("IGUI_SearchMode_Zone_Names_" .. zoneDef.name) or ZONE_FRIENDLY_NAMES[zoneDef.name] or zoneDef.name
end

-- Raw zone key (for category filtering) ------------------------------------
local function getZoneKey(win)
    local p = win._playerObj
    if not p then return nil end
    local zoneDef = forageSystem.getDefinedZoneAt(p:getX(), p:getY())
    return zoneDef and zoneDef.name or nil
end

-- Season -------------------------------------------------------------------
local function getSeason()
    local gt = GameTime.getInstance()
    if not gt then return ZeD.tr("UI_ZeD_Forage_Unknown") end
    return ZeD.tr(SEASON_MAP[gt:getMonth()] or "UI_ZeD_Forage_Unknown")
end

-- Weather ------------------------------------------------------------------
local function getWeather()
    local cm = getClimateManager()
    if not cm then return "Clear" end
    local fog   = cm:getFogIntensity()
    local rain  = cm:getPrecipitationIntensity()
    local snow  = cm:getSnowStrength()
    local cloud = cm:getCloudIntensity()
    if fog  > 0.3  then return "Fog"      end
    if rain > 0.5  then return "Storm"    end
    if rain > 0.15 then return "Rain"     end
    if snow > 0.3  then return "Snow"     end
    if cloud > 0.7 then return "Overcast" end
    if cloud > 0.3 then return "Cloudy"   end
    return "Clear"
end

-- Condition summary from net modifier % ------------------------------------
local function getCondition(netMod)
    if netMod >= 10  then return "Good" end
    if netMod >= -10 then return "Fair" end
    return "Poor"
end

-- Stance label (for hero chip) ---------------------------------------------
local function getStanceLabel(win)
    local p = win._playerObj
    if not p then return "Walking" end
    if p:isAiming()   then return "Aiming"   end
    if p:isSneaking() then return "Sneaking" end
    local mgr = ISSearchManager.players[p]
    if mgr and mgr.isSearchMode then return "Searching" end
    return "Walking"
end

-- Search radius (tiles, with all modifiers) --------------------------------
local function getRadius(win)
    local p = win._playerObj
    if not p then return 0 end
    local mgr = ISSearchManager.players[p]
    if not mgr then return 0 end
    return mgr:getOverlayRadius()  -- calls updateModifiers() internally
end

-- Net modifier % (composite of multiplicative penalties/bonuses) -----------
local function getNetModifier(win)
    local p = win._playerObj
    if not p then return 0 end
    local mgr = ISSearchManager.players[p]
    if not mgr or not mgr.modifiers then return 0 end
    local m = mgr.modifiers
    local product = (m.panicPenalty or 1) * (m.bodyPenalty or 1)
                  * (m.exhaustionPenalty or 1) * (m.clothingPenalty or 1)
                  * (m.weatherPenalty or 1) * (m.movementPenalty or 1)
                  * (m.lightPenalty or 1)
    local vision  = math.max(m.aimBonus or 1, m.sneakBonus or 1)
    product = product * vision
    return math.floor((product - 1.0) * 100 + 0.5)
end

-- Categories in range -------------------------------------------------------
local function getCategories(win, zoneKey)
    local p = win._playerObj
    if not p or not zoneKey then return {} end
    local mgr = ISSearchManager.players[p]
    local perkLevel = mgr and mgr.perkLevel or p:getPerkLevel(Perks.PlantScavenging)

    local cats = {}
    local maxWeight = 0

    for catName, catDef in pairs(forageSystem.catDefs) do
        if not catDef.categoryHidden then
            local weight   = catDef.zones and catDef.zones[zoneKey] or 0
            local reqLevel = catDef.identifyCategoryLevel or 0
            local locked   = perkLevel < reqLevel

            if weight > 0 or locked then
                local label = getTextOrNull("IGUI_SearchMode_Categories_" .. catName) or catName
                cats[#cats + 1] = {
                    label = label, weight = weight, reqLevel = reqLevel,
                    locked = locked, catName = catName,
                }
                if weight > maxWeight and not locked then maxWeight = weight end
            end
        end
    end

    -- Assign status labels
    for _, c in ipairs(cats) do
        if c.locked then
            c.value = ZeD.tr("UI_ZeD_Forage_CatLocked", c.reqLevel);  c.dot = "dim";      c.glow = false
        elseif c.weight >= maxWeight and maxWeight > 0 then
            c.value = ZeD.tr("UI_ZeD_Forage_CatPeak");    c.dot = "accent";    c.glow = true
        elseif c.weight >= 20 then
            c.value = ZeD.tr("UI_ZeD_Forage_CatIn");      c.dot = "positive";  c.glow = false
        elseif c.weight >= 5 then
            c.value = ZeD.tr("UI_ZeD_Forage_CatCommon");  c.dot = "dim";       c.glow = false
        else
            c.value = ZeD.tr("UI_ZeD_Forage_CatRare");    c.dot = "info";      c.glow = false
        end
    end

    -- Sort: unlocked by weight desc, locked at bottom
    table.sort(cats, function(a, b)
        if a.locked ~= b.locked then return not a.locked end
        return a.weight > b.weight
    end)
    return cats
end

-- Active modifiers ----------------------------------------------------------
local function getModifiers(win)
    local p = win._playerObj
    if not p then return {} end
    local mgr = ISSearchManager.players[p]
    if not mgr then return {} end
    if not mgr.modifiers then mgr:updateModifiers() end
    local m = mgr.modifiers
    local mods = {}

    -- Individual traits (show each one the player has)
    for traitKey, traitDef in pairs(forageSystem.skillDefs.trait) do
        if traitDef.visionBonus and traitDef.visionBonus ~= 0 then
            local ct = CharacterTrait.get(ResourceLocation.of(traitKey))
            if ct and p:hasTrait(ct) then
                -- the game's own trait name; ZeD's short English one only if the game has none
                local tdef = CharacterTraitDefinition.getCharacterTraitDefinition(ct)
                local label = (tdef and tdef:getLabel()) or TRAIT_FRIENDLY[traitKey] or traitKey
                local v = traitDef.visionBonus
                local sign = v > 0 and "+" or ""
                mods[#mods + 1] = {
                    label = label,
                    value = sign .. string.format("%.1f", v),
                    dot   = v > 0 and "positive" or "danger",
                }
            end
        end
    end

    -- Profession bonus
    local profName = p:getDescriptor() and p:getDescriptor():getCharacterProfession()
                     and p:getDescriptor():getCharacterProfession():getName()
    if profName then
        local profDef = forageSystem.skillDefs.occupation[profName]
        if profDef and profDef.visionBonus and profDef.visionBonus > 0 then
            mods[#mods + 1] = {
                label = profDef.name or profName,
                value = "+" .. string.format("%.1f", profDef.visionBonus),
                dot   = "positive",
            }
        end
    end

    -- Multiplicative penalties (only show when not at baseline)
    local penaltyMap = {
        { key = "panicPenalty",      label = ZeD.tr("UI_ZeD_Forage_ModPanic")    },
        { key = "bodyPenalty",       label = ZeD.tr("UI_ZeD_Forage_ModHealth")   },
        { key = "exhaustionPenalty", label = ZeD.tr("UI_ZeD_Forage_ModFatigue")  },
        { key = "clothingPenalty",   label = ZeD.tr("UI_ZeD_Forage_ModClothing") },
        { key = "weatherPenalty",    label = ZeD.tr("IGUI_SearchMode_Tip_Weather_Title")  },
        { key = "movementPenalty",   label = ZeD.tr("UI_ZeD_Forage_ModMoving")   },
        { key = "lightPenalty",      label = ZeD.tr("IGUI_SearchMode_Tip_Darkness_Title") },
    }
    for _, pm in ipairs(penaltyMap) do
        local v = m[pm.key] or 1
        if v < 0.99 then
            local pct = math.floor((1 - v) * 100 + 0.5)
            local dot = pct > 20 and "danger" or "warning"
            mods[#mods + 1] = { label = pm.label, value = "-" .. pct .. "%", dot = dot }
        end
    end

    -- Aim/sneak bonuses (only when active)
    if (m.aimBonus or 1) > 1.01 then
        local pct = math.floor(((m.aimBonus or 1) - 1) * 100 + 0.5)
        mods[#mods + 1] = { label = ZeD.tr("UI_ZeD_Forage_StanceAiming"), value = "+" .. pct .. "%", dot = "positive" }
    end
    if (m.sneakBonus or 1) > 1.01 then
        local pct = math.floor(((m.sneakBonus or 1) - 1) * 100 + 0.5)
        mods[#mods + 1] = { label = ZeD.tr("UI_ZeD_Forage_StanceSneaking"), value = "+" .. pct .. "%", dot = "positive" }
    end

    return mods
end

-- Focus dropdown options (unlocked categories) ------------------------------
local function getFocusOptions(win)
    local p = win._playerObj
    local opts = { { id = "none", label = ZeD.tr("UI_ZeD_Forage_FocusAll") } }
    if not p then return opts end
    local mgr = ISSearchManager.players[p]
    local perkLevel = mgr and mgr.perkLevel or p:getPerkLevel(Perks.PlantScavenging)

    for catName, catDef in pairs(forageSystem.catDefs) do
        if not catDef.categoryHidden and perkLevel >= (catDef.identifyCategoryLevel or 0) then
            local label = getTextOrNull("IGUI_SearchMode_Categories_" .. catName) or catName
            opts[#opts + 1] = { id = catName, label = label }
        end
    end

    table.sort(opts, function(a, b)
        if a.id == "none" then return true  end
        if b.id == "none" then return false end
        return a.label < b.label
    end)
    return opts
end

-- Focus chance string for selected category ---------------------------------
local function getFocusChance(win)
    local focus = win._foragingFocus
    if not focus then return "---" end
    local catDef = forageSystem.catDefs[focus]
    if not catDef then return "---" end
    local mn = math.floor(catDef.focusChanceMin or 0)
    local mx = math.floor(catDef.focusChanceMax or 0)
    if mn <= 0 and mx <= 0 then return "---" end
    return mn .. "-" .. mx .. "%"
end

-- Vanilla reads the foraging focus only from the search window object it
-- keeps per character (sprite affinity, tracks, icon re-rolls, server zone
-- requests). ZeD never shows that window, so the chosen focus is written to
-- it here. Vanilla creates it for every player at start; createUI builds it
-- (without showing it) if it is somehow missing.
local function getSearchWindow(win, create)
    local p = win._playerObj
    if not p or not ISSearchWindow or not ISSearchWindow.players then return nil end
    local sw = ISSearchWindow.players[p]
    if not sw and create and ISSearchWindow.createUI then
        pcall(ISSearchWindow.createUI, p:getPlayerNum())
        sw = ISSearchWindow.players[p]
    end
    return sw
end

local function applyForagingFocus(win, selectedId)
    local focus = (selectedId ~= "none") and selectedId or nil
    win._foragingFocus = focus
    local sw = getSearchWindow(win, true)
    if sw then sw.searchFocusCategory = focus or "None" end
end

-- Each frame: follow the search window's category (it can be changed from
-- vanilla's own window), and fall back to no focus when the category is no
-- longer offered (perk level dropped), the way vanilla's
-- updateSearchFocusCategories does. Never leaves the field nil.
local function syncForagingFocus(win, opts)
    local sw = getSearchWindow(win, false)
    if not sw then return end
    local cat = sw.searchFocusCategory or "None"
    if cat ~= "None" then
        local offered = false
        for i = 1, #opts do
            if opts[i].id == cat then offered = true break end
        end
        if not offered then cat = "None" end
    end
    if sw.searchFocusCategory ~= cat then sw.searchFocusCategory = cat end
    win._foragingFocus = (cat ~= "None") and cat or nil
    local dd = win._forageDropdown
    local id = (cat ~= "None") and cat or "none"
    if dd and not dd.isOpen and dd.selectedId ~= id then dd.selectedId = id end
end

-- Recent finds queue (module-level, keyed by playerNum) ---------------------
ZeD.ForagingTab._findQueues = {}

-- ============================================================================
-- DOT COLOR RESOLVER
-- ============================================================================

local function getDotColor(dotType)
    local T = ZeD.T
    if dotType == "accent"   then return T.accent end
    if dotType == "positive" then return T.positive end
    if dotType == "warning"  then return T.warning end
    if dotType == "danger"   then return T.danger end
    if dotType == "info"     then return T.info end
    -- dim fallback
    return T.textDim
end

-- ============================================================================
-- CHIP DRAW HELPER
-- ============================================================================

-- The width a chip takes for its text (the chip sizes to its words).
local function chipWidth(text, T)
    return ZeD.TM:MeasureStringX(T.fontF1, text) + T.px(6) * 2
end

-- maxW (optional): the widest the chip may be; longer text ends in "..."
local function drawChip(panel, x, y, text, style, T, maxW)
    local tm = ZeD.TM
    local font = T.fontF1
    local th = tm:getFontHeight(font)
    local padX = T.px(6)
    local padY = T.px(2)
    if maxW then text = ZeD.Atoms.truncateText(text, font, maxW - padX * 2) end
    local tw = tm:MeasureStringX(font, text)
    local cw = tw + padX * 2
    local ch = th + padY * 2

    -- Background + border per style
    local bg, tc, bc
    if style == "on" then
        -- accent style — condition chip
        bg = ZeD.colorAlpha(T.accent, 0.15)
        tc = T.accentText
        bc = T.accent
    elseif style == "pos" then
        bg = ZeD.colorAlpha(T.positive, 0.12)
        tc = T.positiveText
        bc = ZeD.colorAlpha(T.positive, 0.4)
    elseif style == "warn" then
        bg = ZeD.colorAlpha(T.warning, 0.12)
        tc = T.warningText
        bc = ZeD.colorAlpha(T.warning, 0.4)
    else
        -- neutral
        bg = T.surf3
        tc = T.textDim
        bc = T.borderS
    end

    panel:drawRect(x, y, cw, ch, bg.a, bg.r, bg.g, bg.b)
    panel:drawRectBorder(x, y, cw, ch, bc.a or 0.4, bc.r, bc.g, bc.b)
    panel:drawText(text, x + padX, y + padY, tc.r, tc.g, tc.b, tc.a or 1, font)

    return cw
end

-- ============================================================================
-- DRAW: SKY ARC — sun/moon instrument gauge (Cell A of hero band)
-- ============================================================================

local SKY_ARC_RADIUS   = 44    -- semicircle radius in px
local SKY_HORIZON_Y    = 62    -- horizon line offset from top of cell
local SKY_DOT_SZ       = 8     -- celestial body diameter
local SKY_TICK_H       = 4     -- dawn/dusk tick height

local function drawSkyArc(panel, x, y, w, h)
    local T = ZeD.T
    local A = ZeD.Atoms
    local tm = ZeD.TM

    -- Read game time + season dawn/dusk
    local gt = getGameTime()
    local cm = getClimateManager()
    if not gt or not cm then return end
    local hour = gt:getTimeOfDay()
    local season = cm:getSeason()
    local dawn = season and season:getDawn() or 6.0
    local dusk = season and season:getDusk() or 21.0
    local daylight = cm:getDayLightStrength()

    -- Arc geometry (relative to cell origin)
    local centerX = math.floor(w / 2)
    local horizY  = T.px(SKY_HORIZON_Y)
    local radius  = T.px(SKY_ARC_RADIUS)

    -- Sky tint background (subtle mood color above horizon)
    -- Night: deep navy.  Day: warm amber.  Lerp by daylight strength.
    local nightR, nightG, nightB = 0.04, 0.06, 0.14
    local dayR,   dayG,   dayB   = 0.18, 0.14, 0.06
    local s = daylight
    local skyR = nightR + (dayR - nightR) * s
    local skyG = nightG + (dayG - nightG) * s
    local skyB = nightB + (dayB - nightB) * s
    local skyA = 0.04 + 0.04 * s  -- 0.04 at night → 0.08 at noon
    panel:drawRect(x, y, w, horizY, skyA, skyR, skyG, skyB)

    -- Below horizon: dark ground tint
    panel:drawRect(x, y + horizY + T.px(1), w, h - horizY - T.px(1), 0.06, 0.03, 0.03, 0.03)

    -- Arc path (column-by-column semicircle, 1px wide, above horizon only)  -- S124 scale: the loop walks screen px, so the 1 px column width stays; thickness scales
    local arcColor = T.borderS
    local arcA = 0.35
    for col = 0, radius * 2 do
        local dx = col - radius
        local rSq = radius * radius - dx * dx
        if rSq > 0 then
            local dy = math.sqrt(rSq)
            local arcY = horizY - math.floor(dy + 0.5)
            if arcY >= 0 then
                panel:drawRect(x + centerX - radius + col, y + arcY, 1, T.px(2),
                    arcA, arcColor.r, arcColor.g, arcColor.b)
            end
        end
    end

    -- Horizon line
    local bd = T.borderS
    panel:drawRect(x, y + horizY, w, T.px(1), bd.a * 0.5, bd.r, bd.g, bd.b)

    -- Dawn/dusk ticks (small vertical marks at horizon where arc meets)
    local tickColor = T.textDim
    local tickA = tickColor.a or 0.5
    panel:drawRect(x + centerX - radius, y + horizY - T.px(SKY_TICK_H), T.px(1), T.px(SKY_TICK_H) * 2 + T.px(1),
        tickA, tickColor.r, tickColor.g, tickColor.b)
    panel:drawRect(x + centerX + radius, y + horizY - T.px(SKY_TICK_H), T.px(1), T.px(SKY_TICK_H) * 2 + T.px(1),
        tickA, tickColor.r, tickColor.g, tickColor.b)

    -- Compute celestial body position
    local isDay = hour >= dawn and hour <= dusk
    local progress, dotColor
    if isDay then
        -- Day: dawn=0, dusk=1 → angle from π (left) to 0 (right)
        progress = (hour - dawn) / math.max(dusk - dawn, 0.01)
        dotColor = T.accent  -- warm amber sun
    else
        -- Night: dusk=0, dawn(next day)=1 → same arc path for moon
        local nightLen = 24 - dusk + dawn
        if hour >= dusk then
            progress = (hour - dusk) / math.max(nightLen, 0.01)
        else
            progress = (hour + 24 - dusk) / math.max(nightLen, 0.01)
        end
        dotColor = T.info  -- cool blue moon
    end
    progress = math.max(0, math.min(progress, 1))

    local angle = math.pi * (1 - progress)
    local dotX = centerX + radius * math.cos(angle)
    local dotY = horizY - radius * math.sin(angle)
    -- Draw celestial body dot
    local dotDrawX = x + math.floor(dotX) - math.floor(T.px(SKY_DOT_SZ) / 2)
    local dotDrawY = y + math.floor(dotY) - math.floor(T.px(SKY_DOT_SZ) / 2)
    A.drawStatusDot(panel, dotDrawX, dotDrawY, dotColor, T.px(SKY_DOT_SZ))

    -- Subtle glow behind the dot (larger, faint)
    local glowSz = T.px(SKY_DOT_SZ) + T.px(6)
    local glowX = x + math.floor(dotX) - math.floor(glowSz / 2)
    local glowY = y + math.floor(dotY) - math.floor(glowSz / 2)
    A.drawStatusDot(panel, glowX, glowY, ZeD.colorAlpha(dotColor, 0.12), glowSz)

    -- Phase label below horizon (centered) — no clock time (watch exploit)
    local phaseStr = isDay and ZeD.tr("UI_ZeD_Forage_Day") or ZeD.tr("UI_ZeD_Forage_Night")
    local phaseFont = T.fontF1
    local phaseW = tm:MeasureStringX(phaseFont, phaseStr)

    local phaseY = y + horizY + T.px(8)
    local phaseX = x + math.floor((w - phaseW) / 2)
    local phaseColor = T.toneLo
    panel:drawText(phaseStr, phaseX, phaseY,
        phaseColor.r, phaseColor.g, phaseColor.b, phaseColor.a or 1, phaseFont)

    -- Dawn/dusk time labels (tiny, at tick positions)
    local dawnStr = string.format("%d", math.floor(dawn))
    local duskStr = string.format("%d", math.floor(dusk))
    local smallFont = T.fontF1
    local dawnW = tm:MeasureStringX(smallFont, dawnStr)
    local labelY = y + horizY + T.px(3)
    local dimC = T.toneLo
    panel:drawText(dawnStr, x + centerX - radius - math.floor(dawnW / 2), labelY,
        dimC.r, dimC.g, dimC.b, 0.5, smallFont)
    local duskW = tm:MeasureStringX(smallFont, duskStr)
    panel:drawText(duskStr, x + centerX + radius - math.floor(duskW / 2), labelY,
        dimC.r, dimC.g, dimC.b, 0.5, smallFont)
end

-- ============================================================================
-- DRAW: HERO BAND
-- ============================================================================

local function drawHero(panel, win, x, y, w)
    local T = ZeD.T
    local A = ZeD.Atoms
    local tm = ZeD.TM
    local h = T.px(HERO_MIN_H)

    -- Cell A — Sky Arc (sun/moon instrument gauge)
    local sceneW = T.px(HERO_SCENE_W)
    drawSkyArc(panel, x, y, sceneW, h)
    -- Right border
    local bd = T.border
    panel:drawRect(x + sceneW, y, T.px(1), h, bd.a, bd.r, bd.g, bd.b)

    -- Cell C — radius/net (right side, fixed width)
    local radX = x + w - T.px(HERO_RADIUS_W)
    local radCenterX = radX + math.floor(T.px(HERO_RADIUS_W) / 2)
    -- Left border
    panel:drawRect(radX, y, T.px(1), h, bd.a, bd.r, bd.g, bd.b)

    -- Big radius number
    local radStr = string.format("%.1f", win._frameRadius or 0)
    local bigFont = T.fontF4
    local radW = tm:MeasureStringX(bigFont, radStr)
    local radH = tm:getFontHeight(bigFont)
    local radTextX = radCenterX - math.floor(radW / 2)
    local radTextY = y + T.px(16)
    local radC = T.toneNorm
    panel:drawText(radStr, radTextX, radTextY, radC.r, radC.g, radC.b, radC.a or 1, bigFont)

    -- "TILES" label
    local tilesLabel = ZeD.tr("UI_ZeD_Forage_Tiles")
    local tilesW = tm:MeasureStringX(T.fontF1, tilesLabel)
    local tilesX = radCenterX - math.floor(tilesW / 2)
    local tilesY = radTextY + radH + T.px(2)
    local tlc = T.toneLo
    panel:drawText(tilesLabel, tilesX, tilesY, tlc.r, tlc.g, tlc.b, tlc.a or 1, T.fontF1)

    -- Net modifier
    local netMod = win._frameNetMod or 0
    local netPrefix = netMod >= 0 and "+" or ""
    local netStr = netPrefix .. tostring(netMod) .. "%"
    local netColor = netMod >= 0 and T.positive or T.danger
    local netW = tm:MeasureStringX(T.fontF3, netStr)
    local netX = radCenterX - math.floor(netW / 2)
    local netY = tilesY + tm:getFontHeight(T.fontF1) + T.px(6)
    panel:drawText(netStr, netX, netY, netColor.r, netColor.g, netColor.b, netColor.a or 1, T.fontF3)

    -- "NET" label
    local netLabel = ZeD.tr("UI_ZeD_Forage_Net")
    local netLW = tm:MeasureStringX(T.fontF1, netLabel)
    local netLX = radCenterX - math.floor(netLW / 2)
    local netLY = netY + tm:getFontHeight(T.fontF3) + T.px(2)
    local nlc = T.toneLo
    panel:drawText(netLabel, netLX, netLY, nlc.r, nlc.g, nlc.b, nlc.a or 1, T.fontF1)

    -- Cell B — info (middle, between scene and radius)
    local infoX = x + sceneW + T.px(1) + T.px(HERO_PAD)

    -- Zone name (Chicago heading font)
    local zoneName = win._frameZone or ZeD.tr("UI_ZeD_Forage_Unknown")
    local zoneY = y + T.px(HERO_PAD)
    local zoneColor = T.textHead
    -- The info cell ends before the radius cell; nothing is drawn past this edge
    local infoRight = radX - T.px(HERO_PAD)
    local infoRoom = infoRight - infoX
    panel:drawText(A.truncateText(zoneName, T.fontF4, infoRoom), infoX, zoneY, zoneColor.r, zoneColor.g, zoneColor.b, zoneColor.a or 1, T.fontF4)

    -- Chip rows — bottom of info cell. Chips that do not fit beside the others wrap to a
    -- row above (as many rows as fit under the zone name); chips past the last row drop
    -- and a "+N" chip says how many.
    local chipH = tm:getFontHeight(T.fontF1) + T.px(4)
    local chipY = y + h - T.px(HERO_PAD) - chipH
    local chipGap = T.px(4)
    -- Dynamic chip styles based on live data
    local cond = win._frameCondition or "Fair"
    local condStyle = cond == "Good" and "on" or (cond == "Fair" and "pos" or "warn")
    local wx = win._frameWeather or "Clear"
    local wxStyle = (wx == "Clear" or wx == "Cloudy") and "neutral" or "warn"
    local chips = {
        { text = ZeD.ForagingTab.word(cond), style = condStyle },
        { text = ZeD.ForagingTab.word(win._frameStance or "Walking"), style = "neutral" },
        { text = win._frameSeason or ZeD.tr("UI_ZeD_Forage_Unknown"), style = "pos" },
        { text = ZeD.ForagingTab.word(wx), style = wxStyle },
    }
    local zoneBottom = zoneY + tm:getFontHeight(T.fontF4)
    local maxRows = math.floor((chipY + chipH - zoneBottom - T.px(4)) / (chipH + chipGap))
    if maxRows < 1 then maxRows = 1 end

    -- lay the chips out in rows (row index, x offset, width)
    local rowOf, xOf, wOf = {}, {}, {}
    local row, cx, shown = 1, 0, 0
    for i = 1, #chips do
        local cw = chipWidth(chips[i].text, T)
        if cw > infoRoom then cw = infoRoom end
        if cx > 0 and cx + cw > infoRoom then
            row = row + 1
            cx = 0
        end
        if row > maxRows then break end
        rowOf[i], xOf[i], wOf[i] = row, cx, cw
        cx = cx + cw + chipGap
        shown = i
    end
    local moreText = nil
    if shown < #chips then
        -- the "+N" chip follows the last shown chip; chips are given up until it fits
        while shown > 1 do
            local mw = chipWidth("+" .. tostring(#chips - shown), T)
            if xOf[shown] + wOf[shown] + chipGap + mw <= infoRoom then break end
            shown = shown - 1
        end
        moreText = "+" .. tostring(#chips - shown)
    end
    local usedRows = rowOf[shown] or 1
    local firstRowY = chipY - (usedRows - 1) * (chipH + chipGap)
    for i = 1, shown do
        drawChip(panel, infoX + xOf[i], firstRowY + (rowOf[i] - 1) * (chipH + chipGap), chips[i].text, chips[i].style, T, wOf[i])
    end
    if moreText then
        local mx = infoX + xOf[shown] + wOf[shown] + chipGap
        drawChip(panel, mx, firstRowY + (rowOf[shown] - 1) * (chipH + chipGap), moreText, "neutral", T)
    end

    -- Bottom divider (strong)
    A.drawDividerH(panel, x, y + h - T.px(1), w, true)

    return h
end

-- ============================================================================
-- DRAW: STANCE ROW
-- ============================================================================

local STANCES = {
    { id = "searching", key = "UI_ZeD_Forage_StanceSearching" },
    { id = "crouch",    key = "UI_ZeD_Forage_StanceCrouch"    },
    { id = "aim",       key = "UI_ZeD_Forage_StanceAim"       },
}

local function drawStanceRow(panel, win, x, y, w)
    local T = ZeD.T
    local A = ZeD.Atoms
    local tm = ZeD.TM
    local h = T.px(STANCE_ROW_H)
    local btnW = math.floor(w / #STANCES)

    -- Read live player state
    local player = win._playerObj
    local active = {}
    local mgr = player and ISSearchManager.getManager(player) or nil
    active.searching = mgr and mgr.isSearchMode or false
    active.crouch    = player and player:isSneaking() or false
    active.aim       = player and player:isAiming() or false

    -- Only SEARCHING is clickable; crouch + aim are read-only status
    win._forageStanceZones = {}

    for i, stance in ipairs(STANCES) do
        local bx = x + (i - 1) * btnW
        local bw = (i == #STANCES) and (w - (i - 1) * btnW) or btnW
        local isActive = active[stance.id]

        -- Background
        if isActive then
            local aBg = T.hover
            panel:drawRect(bx, y, bw, h, aBg.a or 0.15, aBg.r, aBg.g, aBg.b)
        end

        -- Border right (between buttons)
        if i < #STANCES then
            local bd = T.borderS
            panel:drawRect(bx + bw, y, T.px(1), h, bd.a, bd.r, bd.g, bd.b)
        end

        -- Label
        local tc = isActive and T.toneNorm or T.toneLo
        local stanceLabel = ZeD.tr(stance.key)
        local tw = tm:MeasureStringX(T.fontF1, stanceLabel)
        local th = tm:getFontHeight(T.fontF1)
        local tx = bx + math.floor((bw - tw) / 2)
        local ty = y + math.floor((h - th) / 2)
        panel:drawText(stanceLabel, tx, ty, tc.r, tc.g, tc.b, tc.a or 1, T.fontF1)

        -- Only SEARCHING gets a click zone (toggles search mode)
        if stance.id == "searching" then
            win._forageStanceZones[#win._forageStanceZones + 1] = {
                x = bx, y = y, w = bw, h = h, id = stance.id
            }
            -- S109b: gamepad focus cue painted over the SEARCHING tile.
            if _gpFocusMatches(win, function(el)
                    return el.isStance and el.stanceId == "searching"
                end) then
                _paintGpCue(panel, bx, y, bw, h)
            end
        end
    end

    -- Bottom divider
    A.drawDividerH(panel, x, y + h - T.px(1), w, false)

    return h
end

-- ============================================================================
-- DRAW: FOCUS ROW
-- ============================================================================

local function drawFocusRow(panel, win, x, y, w)
    local T = ZeD.T
    local tm = ZeD.TM
    local h = T.px(FOCUS_ROW_H)

    -- Lazy-create dropdown (with live options)
    local liveOpts = win._frameFocusOptions or { { id = "none", label = ZeD.tr("UI_ZeD_Forage_FocusAll") } }
    if not win._forageDropdown then
        local ddW = w - T.px(FOCUS_PAD_X) * 2 - T.px(FINDS_WT_W) - T.px(FOCUS_GAP)
        local dd = ZeD_Dropdown:new(x + T.px(FOCUS_PAD_X), y + math.floor((h - T.inputH) / 2), ddW, liveOpts, "none")
        dd.onChange = function(self, selectedId)
            applyForagingFocus(win, selectedId)
        end
        panel:addChild(dd)
        win._forageDropdown = dd
    end

    -- Reposition dropdown each frame + sync options when they change
    local dd = win._forageDropdown
    local ddW = w - T.px(FOCUS_PAD_X) * 2 - T.px(FINDS_WT_W) - T.px(FOCUS_GAP)
    dd:setX(x + T.px(FOCUS_PAD_X))
    dd:setY(y + math.floor((h - T.inputH) / 2))
    dd:setWidth(ddW)
    dd:setVisible(true)
    if #liveOpts ~= #dd.options then dd.options = liveOpts end

    -- S109b: gamepad focus cue around the dropdown box. Painted on the
    -- parent panel BEFORE the dropdown child renders — since the dropdown
    -- paints an opaque surf2 bg covering the inner area, we extend the cue
    -- 3px on each side so an accent halo remains visible around the widget.
    if _gpFocusMatches(win, function(el) return el.isDropdown end) then
        local cx = x + T.px(FOCUS_PAD_X)
        local cy = y + math.floor((h - T.inputH) / 2)
        local pad = T.px(3)
        _paintGpCue(panel, cx - pad, cy - pad, ddW + pad * 2, T.inputH + pad * 2)
    end

    -- Chance readout (right-aligned)
    local chanceStr = getFocusChance(win)
    local chanceColor = T.toneNorm
    local chanceFont = T.fontF3
    local chanceW = tm:MeasureStringX(chanceFont, chanceStr)
    local chanceX = x + w - T.px(FOCUS_PAD_X) - chanceW
    local chanceY = y + math.floor((h - tm:getFontHeight(chanceFont)) / 2)
    panel:drawText(chanceStr, chanceX, chanceY, chanceColor.r, chanceColor.g, chanceColor.b, chanceColor.a or 1, chanceFont)

    -- Bottom divider
    ZeD.Atoms.drawDividerH(panel, x, y + h - T.px(1), w, false)

    return h
end

-- ============================================================================
-- DRAW: MORE DETAIL DISCLOSURE + BODY
-- ============================================================================

local function drawDisclosure(panel, win, x, y, w)
    local T = ZeD.T
    local A = ZeD.Atoms
    local tm = ZeD.TM
    local h = T.px(DISCLOSURE_H)
    local isOpen = win._moreDetailOpen or false

    -- Check hover (suppressed when dropdown overlaps)
    local mx = panel:getMouseX()
    local my = panel:getMouseY()
    local hovered = not (win._ddBlocksHover) and mx >= x and mx < x + w and my >= y and my < y + h

    -- Background
    local bg = hovered and T.hover or T.surf2
    panel:drawRect(x, y, w, h, bg.a, bg.r, bg.g, bg.b)

    -- S109b: gamepad focus cue painted AFTER surf2 bg (which is near-opaque
    -- at 0.92 alpha). Triangle + label render on top at 45% visibility —
    -- same pattern as Animals Alerts/Totals disclosures.
    if _gpFocusMatches(win, function(el) return el.isDisclosure end) then
        _paintGpCue(panel, x, y, w, h)
    end

    -- Disclosure triangle
    local discSz = T.px(6)
    local discX = x + T.px(GRID_PAD_X)
    local discY = y + math.floor((h - discSz) / 2)
    local discColor = T.arrow
    if isOpen then
        A.drawTriangleDown(panel, discX, discY, discSz, discColor)
    else
        A.drawTriangleRight(panel, discX, discY, discSz, discColor)
    end

    -- Label
    local label = ZeD.tr("UI_ZeD_Forage_MoreDetail")
    local labelColor = T.toneNorm
    local labelX = discX + discSz + T.px(6)
    local labelY = y + math.floor((h - tm:getFontHeight(T.fontF1)) / 2)
    panel:drawText(label, labelX, labelY, labelColor.r, labelColor.g, labelColor.b, labelColor.a or 1, T.fontF1)

    -- Bottom border
    A.drawDividerH(panel, x, y + h - T.px(1), w, false)

    -- Store click zone
    win._forageDisclosureZone = { x = x, y = y, w = w, h = h }

    return h
end

-- Draw 2-column stat grid (shared by categories + modifiers)
local function drawStatGrid(panel, x, y, w, items)
    local T = ZeD.T
    local A = ZeD.Atoms
    local tm = ZeD.TM
    local cols = 2
    local colW = math.floor(w / cols)
    local rowH = T.px(GRID_ROW_H)
    local totalRows = math.ceil(#items / cols)
    local totalH = 0

    for i, item in ipairs(items) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local cx = x + col * colW
        local cy = y + row * rowH

        -- Row alpha (locked items are dimmed)
        local alpha = item.locked and 0.45 or 1.0

        -- Status dot
        local dotColor = getDotColor(item.dot)
        local dotY = cy + math.floor((rowH - T.px(GRID_DOT_SZ)) / 2)
        A.drawStatusDot(panel, cx + T.px(GRID_PAD_X), dotY, ZeD.colorAlpha(dotColor, alpha), T.px(GRID_DOT_SZ))

        -- Label
        local labelX = cx + T.px(GRID_PAD_X) + T.px(GRID_DOT_SZ) + T.px(GRID_DOT_GAP)
        local labelY = cy + math.floor((rowH - tm:getFontHeight(T.fontF1)) / 2)
        local lc = ZeD.colorAlpha(T.toneNorm, alpha)
        -- (a long label, a translator's or the game's own trait name, ends in "..." before the value)
        local valW = tm:MeasureStringX(T.fontF3, item.value)
        local labelRoom = (cx + colW - T.px(GRID_PAD_X)) - valW - T.px(6) - labelX
        panel:drawText(ZeD.Atoms.truncateText(item.label, T.fontF1, labelRoom), labelX, labelY, lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)

        -- Value: semantic color for modifier deltas, neutral for category rarity labels
        local valStr = item.value
        local dotType = item.dot
        local vc
        if dotType == "positive" or dotType == "danger" or dotType == "warning" then
            vc = ZeD.colorAlpha(getDotColor(dotType), alpha)
        else
            vc = ZeD.colorAlpha(T.toneNorm, alpha)
        end
        local valX = cx + colW - T.px(GRID_PAD_X) - valW
        local valY = cy + math.floor((rowH - tm:getFontHeight(T.fontF3)) / 2)
        panel:drawText(valStr, valX, valY, vc.r, vc.g, vc.b, vc.a or 1, T.fontF3)

        -- Right border between columns (only left column)
        if col == 0 then
            local bd = T.border
            panel:drawRect(cx + colW, cy, T.px(1), rowH, bd.a * 0.5, bd.r, bd.g, bd.b)
        end

        -- Bottom border (except last row)
        if row < totalRows - 1 then
            local bd = T.border
            panel:drawRect(cx, cy + rowH - T.px(1), colW, T.px(1), bd.a * 0.3, bd.r, bd.g, bd.b)
        end
    end

    totalH = totalRows * rowH
    return totalH
end

-- Draw sub-section header bar
local function drawSubHeader(panel, x, y, w, text, countText)
    local T = ZeD.T
    local tm = ZeD.TM
    local h = T.px(SUB_HEADER_H)

    -- Background
    local bg = T.surf2
    panel:drawRect(x, y, w, h, bg.a, bg.r, bg.g, bg.b)

    -- Top + bottom borders
    ZeD.Atoms.drawDividerH(panel, x, y, w, false)
    ZeD.Atoms.drawDividerH(panel, x, y + h - T.px(1), w, false)

    local labelY = y + math.floor((h - tm:getFontHeight(T.fontF1)) / 2)
    local slc = T.toneLo
    panel:drawText(text, x + T.px(GRID_PAD_X), labelY, slc.r, slc.g, slc.b, slc.a or 1, T.fontF1)

    -- Count (right-aligned)
    if countText then
        local cw = tm:MeasureStringX(T.fontF3, countText)
        local cx = x + w - T.px(GRID_PAD_X) - cw
        local snc = T.toneNorm
        panel:drawText(countText, cx, labelY, snc.r, snc.g, snc.b, snc.a or 1, T.fontF3)
    end

    return h
end

local function drawMoreBody(panel, win, x, y, w)
    if not win._moreDetailOpen then return 0 end

    local curY = y
    local categories = win._frameCategories or {}
    local modifiers  = win._frameModifiers  or {}
    local netMod     = win._frameNetMod     or 0

    -- Categories in Range sub-header
    local lockedCount = 0
    for _, cat in ipairs(categories) do
        if cat.locked then lockedCount = lockedCount + 1 end
    end
    local catCountStr = ZeD.tr("UI_ZeD_Forage_CatsLocked", #categories, lockedCount)
    curY = curY + drawSubHeader(panel, x, y, w, ZeD.tr("UI_ZeD_Forage_CatsInRange"), catCountStr)

    -- Categories grid
    curY = curY + drawStatGrid(panel, x, curY, w, categories)

    -- Modifiers sub-header
    local netStr = ZeD.tr("UI_ZeD_Forage_NetValue", (netMod >= 0 and "+" or "") .. tostring(netMod) .. "%")
    curY = curY + drawSubHeader(panel, x, curY, w, ZeD.tr("UI_ZeD_Forage_Modifiers"), netStr)

    -- Modifiers grid
    curY = curY + drawStatGrid(panel, x, curY, w, modifiers)

    return curY - y
end

-- ============================================================================
-- DRAW: RECENT FINDS
-- ============================================================================

local function drawFindsHeader(panel, x, y, w)
    local T = ZeD.T
    local tm = ZeD.TM
    local h = T.px(FINDS_HEADER_H)

    -- Background
    local bg = T.surf2
    panel:drawRect(x, y, w, h, bg.a, bg.r, bg.g, bg.b)

    -- Top + bottom borders
    ZeD.Atoms.drawDividerH(panel, x, y, w, false)
    ZeD.Atoms.drawDividerH(panel, x, y + h - T.px(1), w, false)

    local labelY = y + math.floor((h - tm:getFontHeight(T.fontF1)) / 2)
    local lc = T.toneLo

    -- Column headers (Lekton, uppercase)
    local colX = x + T.px(FINDS_PAD_X) + T.px(FINDS_ICON_SZ) + T.px(FINDS_ICON_GAP)
    local distLabel = ZeD.tr("UI_ZeD_Forage_HeadDist")
    panel:drawText(distLabel, colX, labelY, lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)

    -- NAME starts at its column, or after DIST's measured width plus a gap if that is further
    local nameX = math.max(colX + T.px(FINDS_DIST_W) + T.px(6),
        colX + tm:MeasureStringX(T.fontF1, distLabel) + T.px(8))

    local wtLabel = ZeD.tr("UI_ZeD_Forage_HeadWeight")
    local wtW = tm:MeasureStringX(T.fontF1, wtLabel)
    local wtX = x + w - T.px(FINDS_PAD_X) - wtW
    local nameLabel = ZeD.Atoms.truncateText(ZeD.upper(ZeD.tr("IGUI_Name")), T.fontF1, wtX - nameX - T.px(8))
    panel:drawText(nameLabel, nameX, labelY, lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)
    panel:drawText(wtLabel, wtX, labelY, lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)

    return h
end

local function drawFindsRows(panel, win, x, y, w, maxH)
    local T = ZeD.T
    local A = ZeD.Atoms
    local tm = ZeD.TM
    local finds = win._recentFinds or {}
    local h = T.px(FINDS_ROW_H)

    if #finds == 0 then
        -- Empty state
        local emptyText = ZeD.tr("UI_ZeD_Forage_FindsEmpty")
        local emptyFont = T.fontF1
        local ew = tm:MeasureStringX(emptyFont, emptyText)
        local eh = tm:getFontHeight(emptyFont)
        local emptyPad = T.px(24)
        local emptyX = x + math.floor((w - ew) / 2)
        local emptyY = y + emptyPad
        local ec = T.toneLo
        panel:drawText(emptyText, emptyX, emptyY, ec.r, ec.g, ec.b, ec.a or 1, emptyFont)

        -- Bottom border
        local totalH = emptyPad * 2 + eh
        ZeD.Atoms.drawDividerH(panel, x, y + totalH - T.px(1), w, false)
        return totalH
    end

    local totalH = 0
    for i, find in ipairs(finds) do
        local ry = y + (i - 1) * h

        -- Hover detection (suppressed when dropdown overlaps)
        local mx = panel:getMouseX()
        local my = panel:getMouseY()
        local hovered = not (win._ddBlocksHover) and mx >= x and mx < x + w and my >= ry and my < ry + h
        if hovered then
            local hbg = T.surf3
            panel:drawRect(x, ry, w, h, hbg.a, hbg.r, hbg.g, hbg.b)
        end

        local colX = x + T.px(FINDS_PAD_X)

        -- Icon placeholder (small accent-colored dot)
        local iconY = ry + math.floor((h - T.px(FINDS_ICON_SZ)) / 2)
        A.drawStatusDot(panel, colX + T.px(2), iconY + T.px(2), T.accent, T.px(FINDS_ICON_SZ) - T.px(4))
        colX = colX + T.px(FINDS_ICON_SZ) + T.px(FINDS_ICON_GAP)

        -- Distance + bearing
        local distStr = ZeD.tr("UI_ZeD_Forage_FindDist", find.dist or 0, find.bearing and ZeD.tr(find.bearing) or "?")
        local distY = ry + math.floor((h - tm:getFontHeight(T.fontF3)) / 2)
        local dnc = T.toneNorm
        panel:drawText(distStr, colX, distY, dnc.r, dnc.g, dnc.b, dnc.a or 1, T.fontF3)
        colX = colX + T.px(FINDS_DIST_W) + T.px(6)

        -- Name (Bahnschrift Body, neutral)
        local nameMaxW = x + w - T.px(FINDS_PAD_X) - T.px(FINDS_WT_W) - T.px(4) - colX
        local nameStr = find.name
        local nameW = tm:MeasureStringX(T.fontF2, nameStr)
        if nameW > nameMaxW and nameMaxW > 0 then
            -- Truncate with ellipsis
            local ellipsis = "..."
            local ellW = tm:MeasureStringX(T.fontF2, ellipsis)
            local targetW = nameMaxW - ellW
            if targetW > 0 then
                while #nameStr > 1 and tm:MeasureStringX(T.fontF2, nameStr) > targetW do
                    nameStr = string.sub(nameStr, 1, #nameStr - 1)
                end
                nameStr = nameStr .. ellipsis
            end
        end
        local nameY = ry + math.floor((h - tm:getFontHeight(T.fontF2)) / 2)
        local nnc = T.toneNorm
        panel:drawText(nameStr, colX, nameY, nnc.r, nnc.g, nnc.b, nnc.a or 1, T.fontF2)

        -- Weight (K22, dim, right-aligned)
        local wtStr = string.format("%.1f", find.weight)
        local wtW = tm:MeasureStringX(T.fontF3, wtStr)
        local wtX = x + w - T.px(FINDS_PAD_X) - wtW
        local wtY = ry + math.floor((h - tm:getFontHeight(T.fontF3)) / 2)
        local wnc = T.toneNorm
        panel:drawText(wtStr, wtX, wtY, wnc.r, wnc.g, wnc.b, wnc.a or 1, T.fontF3)

        -- Bottom border
        local bd = T.border
        panel:drawRect(x, ry + h - T.px(1), w, T.px(1), bd.a * 0.3, bd.r, bd.g, bd.b)

        totalH = totalH + h
    end

    return totalH
end

-- ============================================================================
-- RENDER (main entry point — called by ZeD_WorldWindow)
-- ============================================================================

function ZeD.ForagingTab.render(panel, win, x, y, w, h)
    local T = ZeD.T
    local curY = y

    -- Cache live data once per frame (all getters called here)
    win._frameRadius     = getRadius(win)
    win._frameNetMod     = getNetModifier(win)
    win._frameZone       = getZoneName(win)
    win._frameSeason     = getSeason()
    win._frameWeather    = getWeather()
    win._frameCondition  = getCondition(win._frameNetMod)
    win._frameStance     = getStanceLabel(win)
    local zoneKey        = getZoneKey(win)
    -- The category list, trait modifiers and focus options build tables and
    -- Java trait handles, so they are refreshed on a short timer (or at once
    -- when the zone changes) instead of every frame.
    local nowMs = getTimestampMs and getTimestampMs() or 0
    if not win._frameCategories or zoneKey ~= win._frameCatZone
            or nowMs - (win._frameCatStamp or 0) > 250 then
        win._frameCatZone      = zoneKey
        win._frameCatStamp     = nowMs
        win._frameCategories   = getCategories(win, zoneKey)
        win._frameModifiers    = getModifiers(win)
        win._frameFocusOptions = getFocusOptions(win)
    end
    syncForagingFocus(win, win._frameFocusOptions)

    -- Sync recent finds from discovery hook queue
    local playerNum = win._playerObj and win._playerObj:getPlayerNum() or 0
    win._recentFinds = ZeD.ForagingTab._findQueues[playerNum] or {}

    -- Suppress hover effects when dropdown is expanded (prevents bleed-through)
    win._ddBlocksHover = win._forageDropdown and win._forageDropdown.isOpen or false

    -- Reset click zones each frame
    win._forageStanceZones  = {}
    win._forageDisclosureZone = nil

    -- Scroll state
    local scroll = win._forageScroll
    local scrollOff = 0

    -- First pass: measure total content height for scroll
    -- (We draw directly with scroll offset applied)
    local totalContentH = T.px(HERO_MIN_H) + T.px(STANCE_ROW_H) + T.px(FOCUS_ROW_H) + T.px(DISCLOSURE_H)
    if win._moreDetailOpen then
        local catRows = math.ceil(#win._frameCategories / 2)
        local modRows = math.ceil(#win._frameModifiers / 2)
        totalContentH = totalContentH + T.px(SUB_HEADER_H) + catRows * T.px(GRID_ROW_H)
                                       + T.px(SUB_HEADER_H) + modRows * T.px(GRID_ROW_H)
    end
    totalContentH = totalContentH + T.px(FINDS_HEADER_H)
    local finds = win._recentFinds or {}
    if #finds == 0 then
        totalContentH = totalContentH + T.px(24) * 2 + T.px(16)  -- empty state approx
    else
        totalContentH = totalContentH + #finds * T.px(FINDS_ROW_H)
    end

    -- Update scrollbar
    local needsScroll = totalContentH > h
    if scroll then
        scroll.visible = needsScroll
        if needsScroll then
            scroll.barSizeRatio = h / totalContentH
            scrollOff = math.floor(scroll.scrollPos * math.max(0, totalContentH - h))
        else
            scroll.scrollPos = 0
            scrollOff = 0
        end
    end

    -- Effective content width (reserve scrollbar space when visible)
    local cw = needsScroll and (w - T.sp.scrollbarW) or w

    -- Apply scroll offset
    curY = curY - scrollOff

    -- Draw bands (use cw for content, not full w)
    curY = curY + drawHero(panel, win, x, curY, cw)
    curY = curY + drawStanceRow(panel, win, x, curY, cw)
    curY = curY + drawFocusRow(panel, win, x, curY, cw)
    curY = curY + drawDisclosure(panel, win, x, curY, cw)
    curY = curY + drawMoreBody(panel, win, x, curY, cw)
    curY = curY + drawFindsHeader(panel, x, curY, cw)
    curY = curY + drawFindsRows(panel, win, x, curY, cw, h)

    -- Draw scrollbar (on right edge)
    if scroll and scroll.visible then
        local sp = T.sp
        scroll.x = x + w - sp.scrollbarW
        scroll.y = y
        scroll.height = h
        scroll:draw(panel)
    end
end

-- ============================================================================
-- CLICK HANDLERS
-- ============================================================================

function ZeD.ForagingTab.onClick(win, x, y)
    local scroll = win._forageScroll

    -- Scrollbar click (uses raw y, not content y)
    if scroll and scroll.visible then
        local sp = ZeD.T.sp
        local sbX = scroll.x
        if x >= sbX and x < sbX + sp.scrollbarW then
            scroll:handleMouseDown(y - scroll.y)
            return true
        end
    end

    -- Zones are stored at screen coordinates (scroll already baked in during render),
    -- so compare against raw click y directly.

    -- SEARCHING toggle — calls vanilla ISSearchManager
    if win._forageStanceZones then
        local player = win._playerObj
        for _, zone in ipairs(win._forageStanceZones) do
            if x >= zone.x and x <= zone.x + zone.w
               and y >= zone.y and y <= zone.y + zone.h then
                local mgr = player and ISSearchManager.getManager(player) or nil
                if mgr then mgr:toggleSearchMode() end
                return true
            end
        end
    end

    -- More Detail disclosure
    if win._forageDisclosureZone then
        local z = win._forageDisclosureZone
        if x >= z.x and x <= z.x + z.w
           and y >= z.y and y <= z.y + z.h then
            win._moreDetailOpen = not (win._moreDetailOpen or false)
            return true
        end
    end

    return false
end

function ZeD.ForagingTab.onRightClick(win, x, y)
    -- No right-click actions in S71
    return false
end

function ZeD.ForagingTab.onMouseWheel(win, del)
    local scroll = win._forageScroll
    if scroll and scroll.visible then
        scroll:handleMouseWheel(del)
        return true
    end
    return false
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

function ZeD.ForagingTab.register(dispatchTable)
    dispatchTable["forage"] = ZeD.ForagingTab.render
end

-- ============================================================================
-- DISCOVERY HOOK — captures foraged items into Recent Finds LIFO queue
-- ============================================================================

local _origSpotIcon = nil

local function installForageHook()
    if _origSpotIcon then return end  -- already installed
    _origSpotIcon = ISSearchManager.spotIcon

    ISSearchManager.spotIcon = function(self, _icon)
        _origSpotIcon(self, _icon)

        -- Build find entry from icon data
        local px = self.character:getX()
        local py = self.character:getY()
        local ix = _icon.xCoord or px
        local iy = _icon.yCoord or py
        local dx = ix - px
        local dy = -(iy - py)  -- PZ Y+ is south, negate for math bearing
        local dist = math.floor(math.sqrt(dx * dx + dy * dy) + 0.5)
        local bearing = angleToBearing(math.atan2(dy, dx))

        -- Item display name + weight from script manager (safe — always available)
        local name = _icon.itemType or ZeD.tr("UI_ZeD_Forage_Unknown")
        local weight = 0.1
        if _icon.itemType then
            local scriptItem = ScriptManager.instance:FindItem(_icon.itemType)
            if scriptItem then
                name   = scriptItem:getDisplayName() or name
                weight = scriptItem:getActualWeight() or 0.1
            end
        end

        -- Push to LIFO queue for this player
        local playerNum = self.player  -- ISSearchManager stores playerNum
        local queue = ZeD.ForagingTab._findQueues[playerNum]
        if not queue then
            queue = {}
            ZeD.ForagingTab._findQueues[playerNum] = queue
        end
        table.insert(queue, 1, { dist = dist, bearing = bearing, name = name, weight = weight })
        -- Cap at FINDS_MAX
        while #queue > FINDS_MAX do
            queue[#queue] = nil
        end
    end
end

Events.OnGameStart.Add(installForageHook)
