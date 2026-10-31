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

local DROPDOWN_W        = 190     -- the category drop-down in the header strip (at most half the card)

local DISCLOSURE_H     = 20      -- the library section head
local SUB_HEADER_H     = 15      -- the library category row
local GRID_ROW_H       = 17
local GRID_PAD_X       = 12
local GRID_DOT_SZ      = 6
local GRID_DOT_GAP     = 7

local FINDS_HEADER_H   = 20      -- a column head
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
-- discriminates between element types (isSearch / isDropdown / isDisclosure).
-- ============================================================================

-- (only while the mark may show: this window has the controller and the pad is in use)
local function _gpFocusMatches(win, matcherFn)
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    if not (Focus and Focus.isFocused and Focus.isFocused(win, "worldTabContent")) then return false end
    local el = Focus.liveElement(win)
    if not el then return false end
    return matcherFn(el)
end

-- the controller's mark on an element, drawn before its words; true = the words
-- switch to T.textOnFocus
local function _paintGpCue(panel, x, y, w, h)
    if not (ZeD.Focus and ZeD.Focus.mark) then return false end
    return ZeD.Focus.mark(panel, x, y, w, h)
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

-- The hero's facts as tags (the one tag look: a 1u outline, F1 in sentence case, a
-- status square when the fact is a status). style: "pos" (a good state), "warn"
-- (a poor one), anything else: no mark.
local function chipMark(style, T)
    if style == "pos" then return T.positive end
    if style == "warn" then return T.warning end
    return nil
end

-- The width a tag takes for its text (the tag sizes to its words).
local function chipWidth(text, T, style)
    local w = ZeD.TM:MeasureStringX(T.fontF1, ZeD.textCase(text)) + T.px(5) * 2
    if chipMark(style, T) then w = w + T.px(6) + T.px(4) end
    return w
end

-- maxW (optional): the widest the tag may be; longer text ends in "..."
local function drawChip(panel, x, y, text, style, T, maxW)
    local mark = chipMark(style, T)
    local s = ZeD.textCase(text)
    if maxW then
        local room = maxW - T.px(5) * 2 - (mark and T.px(10) or 0)
        s = ZeD.Atoms.truncateText(s, T.fontF1, room)
    end
    local cw = ZeD.Molecules.drawTag(panel, x, y, s, mark, { keepCase = true })
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
    -- (no glow behind it: a soft glow is not of the period)

    -- Phase label below horizon (centered) — no clock time (watch exploit)
    local phaseStr = ZeD.textCase(isDay and ZeD.tr("UI_ZeD_Forage_Day") or ZeD.tr("UI_ZeD_Forage_Night"))
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

    -- "Tiles" label
    local tilesLabel = ZeD.textCase(ZeD.tr("UI_ZeD_Forage_Tiles"))
    local tilesW = tm:MeasureStringX(T.fontF1, tilesLabel)
    local tilesX = radCenterX - math.floor(tilesW / 2)
    local tilesY = radTextY + radH + T.px(2)
    local tlc = T.toneLo
    panel:drawText(tilesLabel, tilesX, tilesY, tlc.r, tlc.g, tlc.b, tlc.a or 1, T.fontF1)

    -- Net modifier
    local netMod = win._frameNetMod or 0
    local netPrefix = netMod >= 0 and "+" or ""
    local netStr = netPrefix .. tostring(netMod) .. "%"
    -- the words in the default ink; the status square before them carries good or bad
    local netColor = netMod >= 0 and T.positive or T.danger
    local sq = T.px(6)
    local netW = tm:MeasureStringX(T.fontF3, netStr)
    local netX = radCenterX - math.floor((netW + sq + T.px(4)) / 2) + sq + T.px(4)
    local netY = tilesY + tm:getFontHeight(T.fontF1) + T.px(6)
    A.drawStatusDot(panel, netX - sq - T.px(4), netY + math.floor((tm:getFontHeight(T.fontF3) - sq) / 2), netColor, sq)
    local tx = T.text
    panel:drawText(netStr, netX, netY, tx.r, tx.g, tx.b, tx.a or 1, T.fontF3)

    -- "Net" label
    local netLabel = ZeD.textCase(ZeD.tr("UI_ZeD_Forage_Net"))
    local netLW = tm:MeasureStringX(T.fontF1, netLabel)
    local netLX = radCenterX - math.floor(netLW / 2)
    local netLY = netY + tm:getFontHeight(T.fontF3) + T.px(2)
    local nlc = T.toneLo
    panel:drawText(netLabel, netLX, netLY, nlc.r, nlc.g, nlc.b, nlc.a or 1, T.fontF1)

    -- Cell B — info (middle, between scene and radius)
    local infoX = x + sceneW + T.px(1) + T.px(HERO_PAD)

    -- (the place name is the card's header, drawn by drawHeader; Oct 30 2026)
    -- The info cell ends before the radius cell; nothing is drawn past this edge
    local infoRight = radX - T.px(HERO_PAD)
    local infoRoom = infoRight - infoX

    -- Chip rows — the block centred in the info cell. Chips that do not fit beside the
    -- others wrap to a row below (as many rows as fit in the cell); chips past the last
    -- row drop and a "+N" chip says how many.
    local chipH = T.px(16)   -- the tag's height
    local chipGap = T.px(4)
    -- Dynamic chip styles based on live data (good and fair conditions read as good)
    local cond = win._frameCondition or "Fair"
    local condStyle = (cond == "Good" or cond == "Fair") and "pos" or "warn"
    local wx = win._frameWeather or "Clear"
    local wxStyle = (wx == "Clear" or wx == "Cloudy") and "neutral" or "warn"
    local chips = {
        { text = ZeD.ForagingTab.word(cond), style = condStyle },
        { text = ZeD.ForagingTab.word(win._frameStance or "Walking"), style = "neutral" },
        { text = win._frameSeason or ZeD.tr("UI_ZeD_Forage_Unknown"), style = "neutral" },
        { text = ZeD.ForagingTab.word(wx), style = wxStyle },
    }
    local maxRows = math.floor((h - T.px(HERO_PAD) * 2 + chipGap) / (chipH + chipGap))
    if maxRows < 1 then maxRows = 1 end

    -- lay the chips out in rows (row index, x offset, width)
    local rowOf, xOf, wOf = {}, {}, {}
    local row, cx, shown = 1, 0, 0
    for i = 1, #chips do
        local cw = chipWidth(chips[i].text, T, chips[i].style)
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
            local mw = chipWidth("+" .. tostring(#chips - shown), T, "neutral")
            if xOf[shown] + wOf[shown] + chipGap + mw <= infoRoom then break end
            shown = shown - 1
        end
        moreText = "+" .. tostring(#chips - shown)
    end
    local usedRows = rowOf[shown] or 1
    local blockH = usedRows * chipH + (usedRows - 1) * chipGap
    local firstRowY = y + math.floor((h - blockH) / 2)
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
-- DRAW: HEADER STRIP AND BAND (Oct 30 2026)
-- The header strip (the standard height): the place name on the left, the
-- category drop-down on the right (with its chance readout before it). The band
-- at the card's foot: Crouch and Aim on the left as read-only status, Search
-- (Stop searching while it is on) on the right as the one main action.
-- ============================================================================

-- the matchers for the controller's focus (module level: nothing allocated per frame)
local function _isDropdownEl(el) return el.isDropdown end
local function _isSearchEl(el) return el.isSearch end

local function drawHeader(panel, win, x, y, w)
    local T = ZeD.T
    local M = ZeD.Molecules
    local tm = ZeD.TM
    local h = M.getTabHeaderH()
    local pad = M.getTabPad()

    -- the focus drop-down, lazily made (with live options), then placed each frame
    local liveOpts = win._frameFocusOptions or { { id = "none", label = ZeD.tr("UI_ZeD_Forage_FocusAll") } }
    local ddW = math.min(T.px(DROPDOWN_W), math.floor(w * 0.5))
    local ddX = x + w - pad - ddW
    local ddY = y + math.floor((h - T.inputH) / 2)
    if not win._forageDropdown then
        local dd = ZeD_Dropdown:new(ddX, ddY, ddW, liveOpts, "none")
        dd.onChange = function(self, selectedId)
            applyForagingFocus(win, selectedId)
        end
        panel:addChild(dd)
        win._forageDropdown = dd
    end
    local dd = win._forageDropdown
    dd:setX(ddX)
    dd:setY(ddY)
    dd:setWidth(ddW)
    dd:setVisible(true)
    if #liveOpts ~= #dd.options then dd.options = liveOpts end

    -- The controller's mark around the dropdown box, on the parent panel BEFORE
    -- the dropdown child renders: the dropdown paints its own box over the inner
    -- area, so the mark's rect reaches 3u past it on each side.
    if _gpFocusMatches(win, _isDropdownEl) then
        local pd = T.px(3)
        _paintGpCue(panel, ddX - pd, ddY - pd, ddW + pd * 2, T.inputH + pd * 2)
    end

    -- the chance readout before the drop-down (only while a category is chosen)
    local right = ddX - T.px(8)
    local chanceStr = getFocusChance(win)
    if chanceStr ~= "---" then
        local cf = T.fontF3
        local cc = T.toneNorm
        local chanceW = tm:MeasureStringX(cf, chanceStr)
        panel:drawText(chanceStr, right - chanceW, y + math.floor((h - tm:getFontHeight(cf)) / 2), cc.r, cc.g, cc.b, cc.a or 1, cf)
        right = right - chanceW - T.px(8)
    end

    -- the place name (the library's tab head, no fold), cut to the room left of the readout
    local name = ZeD.Atoms.textCase(win._frameZone or ZeD.tr("UI_ZeD_Forage_Unknown"))
    name = ZeD.Atoms.truncateText(name, T.fontF4, right - (x + pad))
    M.drawTabHeader(panel, x, y, w, name, true, false, true)
    return h
end

-- one read-only status: a filled square and bright words while on, a hollow one and
-- dim words while off; returns the x after it (nothing to press, no focus stop)
local function drawStatusWord(panel, x, y, bandH, label, on)
    local T = ZeD.T
    local A = ZeD.Atoms
    local f2 = T.fontF2
    local sq = T.px(6)
    local sy = y + math.floor((bandH - sq) / 2)
    if on then A.drawStatusDot(panel, x, sy, T.positive, sq)
    else A.drawStatusHollow(panel, x, sy, T.textDim, sq) end
    local tc = on and T.text or T.textDim
    panel:drawText(label, x + sq + T.px(6), y + math.floor((bandH - ZeD.TM:getFontHeight(f2)) / 2),
        tc.r, tc.g, tc.b, tc.a or 1, f2)
    return x + sq + T.px(6) + ZeD.TM:MeasureStringX(f2, label)
end

local _bandBtn = {}
local _bandSpec = { buttons = { _bandBtn } }

local function drawBandRow(panel, win, x, y, w)
    local T = ZeD.T
    local M = ZeD.Molecules
    local H = M.bandH()
    local player = win._playerObj
    local mgr = player and ISSearchManager.getManager(player) or nil
    local searching = mgr and mgr.isSearchMode or false

    -- Search / Stop searching: the main action (the same toggle the search row had);
    -- it is as wide as the longer word, so the band does not change shape
    local b = _bandBtn
    b.label = ZeD.tr(searching and "UI_ZeD_Forage_BtnStopSearch" or "UI_ZeD_Forage_BtnSearch")
    b.minW = M.buttonW(ZeD.tr("UI_ZeD_Forage_BtnStopSearch"))
    b.variant = "primary"
    b.focus = _gpFocusMatches(win, _isSearchEl) and true or nil
    b.help = ZeD.tr("UI_ZeD_Forage_SearchHelp")
    b.hover = win._ddBlocksHover and false or nil
    _bandSpec.win = win
    local _, out = M.drawBand(panel, x, y, w, _bandSpec)
    win._forageSearchBtn = out.buttons[1]

    -- Crouch and Aim, read-only status at the left
    local limit = (out.buttons[1] and out.buttons[1].x or (x + w)) - T.px(8)
    local sx = x + T.px(8)
    local crouch = player and player:isSneaking() or false
    local aim = player and player:isAiming() or false
    local cl = ZeD.tr("UI_ZeD_Forage_StanceCrouch")
    local al = ZeD.tr("UI_ZeD_Forage_StanceAim")
    sx = drawStatusWord(panel, sx, y, H, cl, crouch) + T.px(14)
    if sx + T.px(12) + ZeD.TM:MeasureStringX(T.fontF2, al) <= limit then
        drawStatusWord(panel, sx, y, H, al, aim)
    end
    return H
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
    local hovered = not (win._ddBlocksHover) and A.mouseIn(panel, x, y, w, h)
    if hovered then ZeD.Help.set(panel, ZeD.tr("UI_ZeD_Forage_MoreHelp")) end

    -- The library section head (triangle, F1 sentence case, the content line under
    -- it), its triangle at the grid's text inset and its strip reaching the edge
    local inset = T.px(GRID_PAD_X)
    local focus = _gpFocusMatches(win, function(el) return el.isDisclosure end) and true or nil
    ZeD.Molecules.drawSectionHeader(panel, x + inset, y, w - inset, ZeD.tr("UI_ZeD_Forage_MoreDetail"), nil, isOpen, hovered,
        nil, false, inset, h, false, focus and { focus = {} } or nil)

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
        local alpha = item.locked and T.disabledAlpha or 1.0

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

        -- Value in the default ink: the status square before the label carries good or bad
        local valStr = item.value
        local vc = ZeD.colorAlpha(T.text, alpha)
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

-- A group inside the detail: the library's category row (15u, F1 toneLo, sentence
-- case, a content line under it; no triangle: the groups do not fold), with its
-- summary right-aligned in F3 ("3 / 1 locked", "+5% net")
local function drawSubHeader(panel, x, y, w, text, countText)
    local T = ZeD.T
    local tm = ZeD.TM
    local h = ZeD.Molecules.drawCategoryRow(panel, x, y, w, text, nil, true,
        { noArrow = true, inset = T.px(GRID_PAD_X), h = T.px(SUB_HEADER_H) })

    -- Summary (right-aligned)
    if countText then
        local s = ZeD.textCase(countText)
        local cw = tm:MeasureStringX(T.fontF3, s)
        local cx = x + w - T.px(GRID_PAD_X) - cw
        local snc = T.textDim
        panel:drawText(s, cx, y + math.floor((h - tm:getFontHeight(T.fontF3)) / 2), snc.r, snc.g, snc.b, snc.a or 1, T.fontF3)
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
    local f5 = T.fontF5

    -- Column heads (20u, F5, sentence case): surface 2 drawn once over the body,
    -- a content line above and under
    ZeD.Surface.fill(panel, x, y, w, h, "surf2")
    ZeD.Atoms.drawDividerH(panel, x, y, w, false)
    ZeD.Atoms.drawDividerH(panel, x, y + h - T.px(1), w, false)

    local labelY = y + math.floor((h - tm:getFontHeight(f5)) / 2)
    local lc = T.textDim

    local colX = x + T.px(FINDS_PAD_X) + T.px(FINDS_ICON_SZ) + T.px(FINDS_ICON_GAP)
    local distLabel = ZeD.textCase(ZeD.tr("UI_ZeD_Forage_HeadDist"))
    panel:drawText(distLabel, colX, labelY, lc.r, lc.g, lc.b, lc.a or 1, f5)

    -- Name starts at its column, or after Dist's measured width plus a gap if that is further
    local nameX = math.max(colX + T.px(FINDS_DIST_W) + T.px(6),
        colX + tm:MeasureStringX(f5, distLabel) + T.px(8))

    local wtLabel = ZeD.textCase(ZeD.tr("UI_ZeD_Forage_HeadWeight"))
    local wtW = tm:MeasureStringX(f5, wtLabel)
    local wtX = x + w - T.px(FINDS_PAD_X) - wtW
    local nameLabel = ZeD.Atoms.truncateText(ZeD.tr("IGUI_Name"), f5, wtX - nameX - T.px(8))
    panel:drawText(nameLabel, nameX, labelY, lc.r, lc.g, lc.b, lc.a or 1, f5)
    panel:drawText(wtLabel, wtX, labelY, lc.r, lc.g, lc.b, lc.a or 1, f5)

    return h
end

local function drawFindsRows(panel, win, x, y, w, maxH)
    local T = ZeD.T
    local A = ZeD.Atoms
    local tm = ZeD.TM
    local finds = win._recentFinds or {}
    local h = T.px(FINDS_ROW_H)

    if #finds == 0 then
        -- Empty state: the library's empty line, at the list's text inset, 8u under its head
        local tx = x + T.px(FINDS_PAD_X)
        local eh = ZeD.Molecules.drawEmptyLine(panel, tx, y + T.px(8), w - T.px(FINDS_PAD_X) * 2,
            ZeD.textCase(ZeD.tr("UI_ZeD_Forage_FindsEmpty")))
        return T.px(8) + eh + T.px(8)
    end

    local totalH = 0
    for i, find in ipairs(finds) do
        local ry = y + (i - 1) * h

        -- Hover detection (suppressed when dropdown overlaps)
        local mx = panel:getMouseX()
        local my = panel:getMouseY()
        local hovered = not (win._ddBlocksHover) and mx >= x and mx < x + w and my >= ry and my < ry + h
        if hovered then
            local hv = T.hover
            panel:drawRect(x, ry, w, h, hv.a, hv.r, hv.g, hv.b)
        end

        local colX = x + T.px(FINDS_PAD_X)

        -- Icon placeholder (small accent-colored dot)
        local iconY = ry + math.floor((h - T.px(FINDS_ICON_SZ)) / 2)
        A.drawStatusDot(panel, colX + T.px(2), iconY + T.px(2), T.accent, T.px(FINDS_ICON_SZ) - 2 * T.px(2))
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
    win._forageSearchBtn = nil
    win._forageDisclosureZone = nil

    -- The pinned parts: the header strip on top and the band at the foot; the body
    -- between them scrolls as one unit (Oct 30 2026)
    local M = ZeD.Molecules
    local hdrH = drawHeader(panel, win, x, y, w)
    local bandH = M.bandH()
    drawBandRow(panel, win, x, y + h - bandH, w)
    local bodyTop = y + hdrH
    local bodyH = h - hdrH - bandH
    win._forageBodyTop, win._forageBodyBottom = bodyTop, bodyTop + bodyH
    h = bodyH
    curY = bodyTop

    -- Scroll state
    local scroll = win._forageScroll
    local scrollOff = 0

    -- First pass: measure total content height for scroll
    -- (We draw directly with scroll offset applied)
    local totalContentH = T.px(HERO_MIN_H) + T.px(DISCLOSURE_H)
    if win._moreDetailOpen then
        local catRows = math.ceil(#win._frameCategories / 2)
        local modRows = math.ceil(#win._frameModifiers / 2)
        totalContentH = totalContentH + T.px(SUB_HEADER_H) + catRows * T.px(GRID_ROW_H)
                                       + T.px(SUB_HEADER_H) + modRows * T.px(GRID_ROW_H)
    end
    totalContentH = totalContentH + T.px(FINDS_HEADER_H)
    local finds = win._recentFinds or {}
    if #finds == 0 then
        totalContentH = totalContentH + T.px(8) * 2 + ZeD.TM:getFontHeight(T.fontF2)  -- the empty line (one line)
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

    -- Draw the body (use cw for content, not full w), clipped between header and band
    panel:setStencilRect(x, bodyTop, w, bodyH)
    curY = curY + drawHero(panel, win, x, curY, cw)
    curY = curY + drawDisclosure(panel, win, x, curY, cw)
    curY = curY + drawMoreBody(panel, win, x, curY, cw)
    curY = curY + drawFindsHeader(panel, x, curY, cw)
    curY = curY + drawFindsRows(panel, win, x, curY, cw, h)
    panel:clearStencilRect()

    -- Draw scrollbar (on right edge, beside the body)
    if scroll and scroll.visible then
        local sp = T.sp
        scroll.x = x + w - sp.scrollbarW
        scroll.y = bodyTop
        scroll.height = bodyH
        scroll:draw(panel)
    end
end

-- ============================================================================
-- CLICK HANDLERS
-- ============================================================================

-- Search mode on or off: vanilla's own toggle (the button and the controller's A)
function ZeD.ForagingTab.toggleSearch(win)
    local player = win and win._playerObj
    local mgr = player and ISSearchManager.getManager(player) or nil
    if mgr and mgr.toggleSearchMode then mgr:toggleSearchMode() end
end

function ZeD.ForagingTab.onClick(win, x, y)
    local scroll = win._forageScroll

    -- Scrollbar click (uses raw y, not content y)
    if scroll and scroll.visible then
        local sp = ZeD.T.sp
        local sbX = scroll.x
        if x >= sbX and x < sbX + sp.scrollbarW and y >= scroll.y and y < scroll.y + scroll.height then
            scroll:handleMouseDown(y - scroll.y)
            return true
        end
    end

    -- Zones are stored at screen coordinates (scroll already baked in during render),
    -- so compare against raw click y directly.

    -- Search / Stop searching (the band's button) — calls vanilla ISSearchManager
    local sb = win._forageSearchBtn
    if sb and x >= sb.x and x <= sb.x + sb.w and y >= sb.y and y <= sb.y + sb.h then
        ZeD.ForagingTab.toggleSearch(win)
        return true
    end

    -- More Detail disclosure (only where the body shows it: not under the header or the band)
    if win._forageDisclosureZone and y >= (win._forageBodyTop or 0) and y < (win._forageBodyBottom or 0) then
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
