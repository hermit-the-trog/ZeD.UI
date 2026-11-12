-- ZeD-UI/42/media/lua/client/ZeD/AnimalsTab.lua
-- ============================================================================
-- ANIMALS TAB — client; an organism: the World window's tab controller.
-- State machine routing: submode (ranch/butcher) × view (overview/zone/animal).
-- Ranch has three views: Overview (alerts + zone cards + totals), Zone detail
-- (roster list + zone info band + sort cycle) and Animal detail (vitals +
-- production + breeding + genetics). Butcher is one view: eligibility filter
-- + yield estimates.
--
-- Molecules defined here (Animals-specific, not general-purpose):
--   M-SUBM   drawSubmodeStrip        — Ranch / Butcher tab strip
--   M-SECH   drawAnimalSection       — Collapsible section header
--   M-ALERT  drawAlertRow            — Alert row (portrait + name + badge + its verb: Milk, Shear, Walk to)
--   M-MINIM  drawMiniMeter           — Compact inline fill meter with label
--   M-ZRSUM  drawZoneSummary         — Zone card with mini-meters
--   M-TOT    drawTotals              — 2-column production totals
--   M-ZINF   drawZoneInfoBand        — Zone name + count + wide meters + warnings
--   M-AROW   drawAnimalRow           — 48px roster row (checkbox + portrait + dots + badges)
--   M-AHEAD  drawAnimalHeader        — 48px portrait + name + breed + badges
--   M-AVIT   drawVitalRow            — Fill bar + text/numeric (skill-gated)
--   M-APROD  drawProductionSection   — Milk/wool/eggs (Lv5+)
--   M-ABREED drawBreedingSection     — Pregnancy/mating/trust (Lv3+)
--   M-AGEN   drawGeneticsSection     — Disorder badges (Lv7+/9+)
--   M-BSUM   drawButcherSummary      — Eligible count + total yield estimate
--   M-BROW   drawButcherRow          — 40px butcher row (weight + meat + products)
--   O-ANOVW  renderRanchOverview     — Ranch overview organism
--   O-ZNVW   renderRanchZone         — Zone detail organism
--   O-ANDTL  renderRanchAnimal       — Animal detail organism
--   O-BOVW   renderButcherOverview   — Butcher overview organism
--
-- The quick actions (an alert's verb, the roster's selection and the band that runs
-- Milk or Shear over it) are worked out in AnimalsQuick.lua, which hands every act
-- to the game's own animal menu handlers.
--
-- A Hunt sub-mode is planned but not built yet.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/AnimalsData"
require "ZeD/AnimalsAlertPoller"
require "ZeD/AnimalsStressInference"
require "ZeD/AnimalsQuick"
require "ZeD/ZeD_ContextList"
require "ZeD/SafeMode"
-- Zone creation uses DesignationZoneAnimal directly (no vanilla UI panels)

ZeD = ZeD or {}
ZeD.AnimalsTab = ZeD.AnimalsTab or {}

local AT = ZeD.AnimalsTab

-- Lazy accessors — modules may not be fully initialized at require-time
local function AD() return ZeD.AnimalsData end
local function SI() return ZeD.AnimalsStressInference end
local function AP() return ZeD.AnimalsAlertPoller end
local function QK() return ZeD.AnimalsQuick end

-- ============================================================================
-- CONTROLLER FOCUS
-- A mark shows only in the focused window while the controller is in use and
-- only for the element the World window's ring has focused (ZeD.Input.Focus:
-- liveZone / isFocused). Elements are told apart by the ids the ring gives them
-- (animals:<kind>:<key>); the rows carry their animal instead. Each element asks
-- ZeD.Focus.mark for its mark after its own fill and before its words, and draws
-- the words in T.textOnFocus when mark says so.
-- ============================================================================

local TAB_ZONE = "worldTabContent"
local _fo = { zone = TAB_ZONE }

-- the mark opts for one element (one shared table: mark reads it at once)
local function focusOpts(win, solid)
    _fo.win, _fo.solid = win, solid
    return _fo
end

-- true when the ring has the element with this id focused and its mark shows
local function isOn(win, id)
    local F = ZeD.Input and ZeD.Input.Focus
    return F ~= nil and F.isFocused ~= nil and F.isFocused(win, TAB_ZONE, id) or false
end

-- the focused element of the tab, or nil (another window, another zone, mouse in use)
local function liveEl(win)
    local F = ZeD.Input and ZeD.Input.Focus
    if not (F and F.liveZone) then return nil end
    local z = F.liveZone(win)
    if not z or z.zone ~= TAB_ZONE then return nil end
    return F.getFocusedElement(win)
end

-- the mark for an element by id; returns true when its words must use T.textOnFocus
local function markId(panel, win, id, x, y, w, h)
    if not isOn(win, id) then return false end
    return ZeD.Focus.mark(panel, x, y, w, h, focusOpts(win)) and true or false
end

-- the focus opts to hand a library control, or nil when the ring is elsewhere
local function focusFor(win, id)
    if isOn(win, id) then return focusOpts(win) end
    return nil
end

-- the plain-words line the window's footer shows while the pointer is over a part
local function help(panel, key, ...)
    if ZeD.Help and ZeD.Help.set then ZeD.Help.set(panel, ZeD.tr(key, ...)) end
end

-- sentence case for words that arrive in capitals
local function tc(s) return ZeD.textCase(s) end

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local BACK_PAD          = 4       -- space above and below the back key in its row

-- Zone detail view
local ZINF_PAD         = 6       -- zone info band internal padding
local AROW_H           = 48      -- animal roster row height
local AROW_ICON_SZ     = 32      -- portrait icon size
local AROW_DOT_SZ      = 7       -- stat dot diameter
local AROW_DOT_GAP     = 6       -- gap between dots
local AROW_PAD         = 6       -- row internal padding
local SORT_MODES       = { "name", "species", "alerts" }
local SORT_LABELS      = { name = "IGUI_Name", species = "UI_ZeD_Animals_SortSpecies", alerts = "UI_ZeD_Animals_SecAlerts" }   -- text keys, translated where drawn

-- Animal detail view
local AHEAD_ICON_SZ    = 48      -- header portrait size
local AHEAD_PAD        = 6       -- header internal padding
local VITAL_BAR_W      = 100     -- fill bar width in vital rows
local VITAL_BAR_H      = 8       -- fill bar height
local VITAL_ROW_H      = 22      -- vital row height
local SECTION_GAP      = 8       -- gap between sections

-- Butcher sub-mode
local BROW_H           = 40      -- butcher roster row height
local BROW_ICON_SZ     = 28      -- portrait in butcher row
local BROW_PAD         = 6       -- row padding

-- Approximate meat yield factors by species (fraction of body weight)
-- These are estimates for planning — not exact game mechanics.
local YIELD_FACTORS = {
    cow     = { meat = 0.45, products = { "Leather", "Bone" } },
    bull    = { meat = 0.45, products = { "Leather", "Bone" } },
    pig     = { meat = 0.50, products = { "Bone", "Fat" } },
    sow     = { meat = 0.50, products = { "Bone", "Fat" } },
    boar    = { meat = 0.50, products = { "Bone", "Fat" } },
    sheep   = { meat = 0.40, products = { "Bone" } },
    ewe     = { meat = 0.40, products = { "Bone" } },
    ram     = { meat = 0.40, products = { "Bone" } },
    chicken = { meat = 0.55, products = { "Feathers" } },
    hen     = { meat = 0.55, products = { "Feathers" } },
    rooster = { meat = 0.55, products = { "Feathers" } },
    turkey  = { meat = 0.50, products = { "Feathers", "Bone" } },
    turkeyhen = { meat = 0.50, products = { "Feathers", "Bone" } },
    rabbit  = { meat = 0.50, products = { "Bone" } },
    deer    = { meat = 0.42, products = { "Leather", "Bone" } },
    stag    = { meat = 0.42, products = { "Leather", "Bone" } },
    doe     = { meat = 0.42, products = { "Leather", "Bone" } },
    raccoon = { meat = 0.35, products = { "Bone" } },
}
local DEFAULT_YIELD = { meat = 0.40, products = { "Bone" } }
-- the product ids above -> text keys (translated where drawn)
AT.PROD_KEYS = {
    Leather  = "UI_ZeD_Animals_ProdLeather",
    Bone     = "UI_ZeD_Animals_ProdBone",
    Fat      = "Tooltip_food_Fat",
    Feathers = "UI_ZeD_Animals_ProdFeathers",
}

-- ============================================================================
-- STATE
-- State is stored on the win object to survive tab switches.
-- Prefix: _animals* to avoid collision with other tabs.
-- ============================================================================

local function getState(win)
    if not win._animalsState then
        win._animalsState = {
            submode   = "ranch",    -- "ranch" | "butcher"
            view      = "overview", -- "overview" | "zone" | "animal"
            zoneName  = nil,        -- selected zone NAME (stable ID, survives cache refresh)
            animalRef = nil,        -- selected animal (view="animal")
            prevView  = nil,        -- for back-button navigation
        }
    end
    return win._animalsState
end

--- Look up a fresh zone Java object by name from DesignationZoneAnimal.
-- Returns the zone object or nil. Always returns a current proxy, not a stale one.
local function getZoneByName(name)
    if not name then return nil end
    local allZones = DesignationZoneAnimal.getAllZones()
    if not allZones then return nil end
    for i = 0, allZones:size() - 1 do
        local z = allZones:get(i)
        if z and z.isStillStreamed and z:isStillStreamed() then
            local ok, zname = pcall(z.getName, z)
            if ok and zname == name then return z end
        end
    end
    return nil
end

local function navigate(win, view, zoneName, animalRef)
    local state = getState(win)
    state.prevView = state.view
    state.view = view
    if zoneName ~= nil then state.zoneName = zoneName end
    if animalRef ~= nil then state.animalRef = animalRef end
    -- Reset detail scroll when entering animal view
    if view == "animal" and win._animalsDetailState then
        win._animalsDetailState.scrollY = 0
    end
end

local function navigateBack(win)
    local state = getState(win)
    if state.view == "animal" and state.submode == "butcher" then
        -- an animal opened from the Butcher roster goes back to that roster
        state.view = "overview"
        state.animalRef = nil
    elseif state.view == "animal" then
        state.view = "zone"
        state.animalRef = nil
    elseif state.view == "zone" then
        state.view = "overview"
        state.zoneName = nil
        -- the roster's ticked rows belong to the zone left behind
        if win._animalsZoneState then win._animalsZoneState.sel = nil end
        -- Clear zone highlight
        local player = getSpecificPlayer(0)
        if player then
            player:resetSelectedZonesForHighlight()
            player:setSeeDesignationZone(false)
        end
    end
    -- Cancel any active rename
    win._animalsRenaming = false
    win._animalsRemoveConfirm = false
    if win._animalsRenameEntry then
        win._animalsRenameEntry:setVisible(false)
    end
end

local function switchSubmode(win, submode)
    local state = getState(win)
    state.submode = submode
    state.view = "overview"
    state.zoneName = nil
    state.animalRef = nil
end

-- ============================================================================
-- ZONE VIEW STATE
-- Separate from main state — survives zone re-entry within same tab session.
-- ============================================================================

local function getZoneViewState(win)
    if not win._animalsZoneState then
        win._animalsZoneState = {
            sortMode = "name",  -- "name" | "species" | "alerts"
            scrollY  = 0,       -- pixel offset for roster scroll
        }
    end
    return win._animalsZoneState
end

-- The roster's selection (the ticked rows), for the zone on show: another zone starts
-- with none ticked.
local function zoneSelection(win, zoneName)
    local zs = getZoneViewState(win)
    local sel = zs.sel
    if not sel or sel.zone ~= zoneName then
        sel = QK().newSelection()
        sel.zone = zoneName
        zs.sel = sel
    end
    return sel
end

local function cycleSortMode(win)
    local zs = getZoneViewState(win)
    for i, mode in ipairs(SORT_MODES) do
        if mode == zs.sortMode then
            zs.sortMode = SORT_MODES[(i % #SORT_MODES) + 1]
            zs.scrollY = 0  -- reset scroll on sort change
            return
        end
    end
    zs.sortMode = "name"
end

-- ============================================================================
-- SORT LOGIC
-- Returns a new sorted array (never mutates the input).
-- Insertion sort — Kahlua-safe, no recursion.
-- ============================================================================

local function sortAnimals(animals, mode)
    local ad = AD()
    local ap = AP()

    -- Pre-compute sort keys to avoid repeated pcalls inside comparisons
    local keyed = {}
    for i, animal in ipairs(animals) do
        local key
        if mode == "name" then
            key = string.lower(ad.getDisplayName(animal))
        elseif mode == "species" then
            -- Species first, then name within species
            key = string.lower(ad.getAnimalType(animal)) .. "|" .. string.lower(ad.getDisplayName(animal))
        elseif mode == "alerts" then
            -- Severity rank: danger=1, warn=2, info=3, good=4, neutral=5, none=9
            local SEV_RANK = { danger = 1, warn = 2, info = 3, good = 4, neutral = 5 }
            local tags = ad.getConditionTags(animal)
            local bestSev = 9
            for _, tag in ipairs(tags) do
                local rank = SEV_RANK[tag.sev] or 6
                if rank < bestSev then bestSev = rank end
            end
            -- Also check alerts from poller for this animal
            local alerts = ap.getAlerts()
            for _, alert in ipairs(alerts) do
                if alert.animal == animal then
                    local rank = ({ danger = 1, warn = 2, info = 3 })[alert.severity] or 6
                    if rank < bestSev then bestSev = rank end
                end
            end
            key = string.format("%d|%s", bestSev, string.lower(ad.getDisplayName(animal)))
        end
        keyed[i] = { animal = animal, key = key or "" }
    end

    -- Insertion sort: Kahlua's table.sort stack-overflows on large arrays
    for i = 2, #keyed do
        local current = keyed[i]
        local j = i - 1
        while j >= 1 and keyed[j].key > current.key do
            keyed[j + 1] = keyed[j]
            j = j - 1
        end
        keyed[j + 1] = current
    end

    -- Extract sorted animals
    local result = {}
    for i = 1, #keyed do
        result[i] = keyed[i].animal
    end
    return result
end

-- The zone roster sorted for the ranch view. Building the sort keys reads
-- every animal's name and (for the alerts sort) its condition tags, so the
-- result is kept for half a second and rebuilt at once when the sort mode,
-- the zone or the animals themselves change.
local SORT_CACHE_MS = 500
local function sortedRoster(zs, animals, mode, zoneName)
    local t = getTimestampMs and getTimestampMs() or 0
    local c = zs._sortCache
    local n = #animals
    if c and c.mode == mode and c.zone == zoneName and c.n == n and t - c.t < SORT_CACHE_MS then
        local same = true
        for i = 1, n do
            if animals[i] ~= c.src[i] then same = false break end
        end
        if same then return c.list end
    end
    local src = {}
    for i = 1, n do src[i] = animals[i] end
    local list = sortAnimals(animals, mode)
    zs._sortCache = { mode = mode, zone = zoneName, n = n, t = t, src = src, list = list }
    return list
end

-- ============================================================================
-- STAT DOT COLOR — maps 0–100 value to green/amber/red
-- ============================================================================

local function dotColorForValue(T, val)
    -- (the status bars' rule: ZeD.Atoms.statusColor, punch list 143)
    return ZeD.Atoms.statusColor(val / 100)
end

-- ============================================================================
-- BUTCHER HELPERS — eligibility filter + yield estimation
-- ============================================================================

local function isButcherEligible(animal)
    local ad = AD()
    if ad.isBaby(animal) then return false end
    if ad.isPregnant(animal) then return false end
    return true
end

local function getYieldInfo(animal)
    local ad = AD()
    local atype = string.lower(ad.getAnimalType(animal))
    local yf = YIELD_FACTORS[atype] or DEFAULT_YIELD
    local weight = ad.getWeight(animal)
    local estMeat = weight * yf.meat
    return {
        weight   = weight,
        estMeat  = estMeat,
        products = yf.products,
    }
end

local function getButcherState(win)
    if not win._animalsButcherState then
        win._animalsButcherState = {
            scrollY = 0,
        }
    end
    return win._animalsButcherState
end

-- ============================================================================
-- SHARED DRAWING HELPERS
-- Buttons are the library's push buttons (M.drawButton / M.drawBand); a state
-- word is a tag (M.drawTag) whose square mark carries the colour.
-- ============================================================================

-- Hit test helper for click zone tables
local function hitZone(zone, x, y)
    if not zone then return false end
    return x >= zone.x and x < zone.x + zone.w
       and y >= zone.y and y < zone.y + zone.h
end

-- A severity word (the data layer's sev, or a disorder's) as the mark colour of a
-- tag. Neutral ones carry no mark.
local function sevColor(T, sev)
    if sev == "danger" or sev == "severe" then return T.danger end
    if sev == "warn" or sev == "warning" or sev == "minor" then return T.warning end
    if sev == "good" or sev == "positive" then return T.positive end
    if sev == "info" then return T.info end
    return nil
end

-- A tag's width, as ZeD.Atoms.drawTag lays it out (5u side padding, a 6u mark and
-- 4u before the word when it has a mark), for rows that right-align their tags.
local function tagWidth(text, marked)
    local T = ZeD.T
    local w = ZeD.TM:MeasureStringX(T.fontF1, tc(text)) + T.px(10)
    if marked then w = w + T.px(10) end
    return w
end

local function drawTag(panel, x, y, text, sev)
    return ZeD.Molecules.drawTag(panel, x, y, text, sevColor(ZeD.T, sev))
end

-- the vertical centre offset for a tag (16u) in a row of height h
local function tagY(y, h)
    return y + math.floor((h - ZeD.T.px(16)) / 2)
end

-- ============================================================================
-- INLINE ZONE CREATION — draw-on-ground flow inside the Animals tab.
-- No vanilla UI panels. Uses DesignationZoneAnimal.new() directly.
--
-- State machine: idle → drawing (mouse drag) → confirm (yes/no) → idle
-- World highlight via addAreaHighlightForPlayer() (same API vanilla uses).
-- Dimension limits: 2–40 tiles per axis (matches vanilla).
-- ============================================================================

local ZONE_MIN_DIM = 2
local ZONE_MAX_DIM = 40

-- Forward declarations — gp* helpers reference these, which are defined lower
-- in the file. Without the hoist, Kahlua closures capture nil at creation
-- time. Assignments below change `local function foo` → `foo = function` so
-- the hoisted slots get filled.
local cancelZoneCreate
local confirmZoneCreate
local getZoneDimensions

local function getZoneCreateState(win)
    if not win._zoneCreate then
        win._zoneCreate = {
            active   = false,    -- create mode active
            phase    = "idle",   -- "idle" | "drawing" | "confirm"
            name     = "",       -- auto-generated zone name
            startX   = nil,      -- drag start world X
            startY   = nil,      -- drag start world Y
            endX     = nil,      -- drag end world X
            endY     = nil,      -- drag end world Y
            z        = 0,        -- floor level
            wasDown  = false,    -- mouse was down last frame (edge detection)
            -- Gamepad cursor. Separate from startX/endX so idle-phase D-pad
            -- can reposition before the first A-press. Seeded to the player's
            -- tile in startZoneCreate.
            cursorX  = nil,
            cursorY  = nil,
        }
    end
    return win._zoneCreate
end

local function startZoneCreate(win)
    local zc = getZoneCreateState(win)
    zc.active = true
    zc.phase = "idle"
    zc.startX = nil
    zc.startY = nil
    zc.endX = nil
    zc.endY = nil
    zc.wasDown = false

    -- Auto-generate zone name (find next unused number)
    local num = 1
    while DesignationZoneAnimal.getZoneByName(ZeD.tr("UI_ZeD_Animals_ZoneAutoName", num)) do
        num = num + 1
    end
    zc.name = ZeD.tr("UI_ZeD_Animals_ZoneAutoName", num)

    -- Show existing zones
    local player = getSpecificPlayer(0)
    if player then
        player:setSeeDesignationZone(true)
        zc.z = math.floor(player:getZ())
        -- Seed the gamepad cursor to the player's tile so idle-phase D-pad
        -- has a valid start point if the user goes that path.
        zc.cursorX = math.floor(player:getX())
        zc.cursorY = math.floor(player:getY())
    end

    -- Block world context menu during zone drawing
    ISWorldObjectContextMenu.disableWorldMenu = true
    -- ZeD holds the world menu off and the zones shown until this drawing ends
    -- (safe mode and the World window closing end it too: AT.endZoneDraw)
    AT._zoneDrawWin = win
end

-- ============================================================================
-- GAMEPAD ZONE-DRAW HELPERS
-- Parallel to mouse flow. State machine:
--   idle  + A → place first corner (start = cursor), phase=drawing
--   drawing + D-pad → move cursor AND endX/Y
--   drawing + A → validate dims; if ok phase=confirm, else no-op
--   drawing + B → back to idle, clear coords (keep zc.active)
--   idle + B → cancelZoneCreate (full exit)
--   confirm + A → confirmZoneCreate (commit zone, exit mode)
--   confirm + B → back to drawing for further adjustment
-- Each D-pad press moves cursor by 1 tile (no hold-repeat yet; spam the stick).
-- ============================================================================

local function gpMoveCursor(win, dx, dy)
    local zc = getZoneCreateState(win)
    if not zc.active then return end
    if zc.phase == "confirm" then return end  -- locked while confirming
    if zc.cursorX == nil then
        local player = getSpecificPlayer(0)
        if player then
            zc.cursorX = math.floor(player:getX())
            zc.cursorY = math.floor(player:getY())
        else
            zc.cursorX, zc.cursorY = 0, 0
        end
    end
    zc.cursorX = zc.cursorX + (dx or 0)
    zc.cursorY = zc.cursorY + (dy or 0)
    -- While drawing, the cursor IS the dynamic second corner.
    if zc.phase == "drawing" then
        zc.endX = zc.cursorX
        zc.endY = zc.cursorY
    end
end

local function gpConfirm(win)
    local zc = getZoneCreateState(win)
    if not zc.active then return end
    if zc.phase == "idle" then
        if zc.cursorX == nil or zc.cursorY == nil then return end
        zc.startX = zc.cursorX
        zc.startY = zc.cursorY
        zc.endX   = zc.cursorX
        zc.endY   = zc.cursorY
        zc.phase  = "drawing"
    elseif zc.phase == "drawing" then
        local _, _, wOk, hOk = getZoneDimensions(zc)
        if wOk and hOk then
            zc.phase = "confirm"
        end
        -- else: ignore A; dims invalid (too small/large). User keeps moving.
    elseif zc.phase == "confirm" then
        -- Seed post-create focus so the ring lands on the new zone card
        -- instead of falling back to idx-clamp (which drops the user on the
        -- ranch submode pill). The refresh loop reads this hint.
        win._animalsFocusAfterCreate = zc.name
        confirmZoneCreate(win)
    end
end

local function gpCancel(win)
    local zc = getZoneCreateState(win)
    if not zc.active then return end
    if zc.phase == "idle" then
        cancelZoneCreate(win)
    elseif zc.phase == "drawing" then
        zc.phase  = "idle"
        zc.startX = nil
        zc.startY = nil
        zc.endX   = nil
        zc.endY   = nil
    elseif zc.phase == "confirm" then
        zc.phase = "drawing"
    end
end

-- Hoist: assign into the forward-declared slot so the gp* helpers above see it.
cancelZoneCreate = function(win)
    local zc = getZoneCreateState(win)
    zc.active = false
    zc.phase = "idle"
    zc.startX = nil
    zc.startY = nil
    zc.endX = nil
    zc.endY = nil

    local player = getSpecificPlayer(0)
    if player then player:setSeeDesignationZone(false) end
    ISWorldObjectContextMenu.disableWorldMenu = false
    AT._zoneDrawWin = nil
end

-- Ends a zone drawing ZeD has in progress, if any: the world menu comes back
-- on and the zones are hidden again. Safe mode starting and the World window
-- closing call it; it does nothing when no drawing is under way.
function AT.endZoneDraw()
    local win = AT._zoneDrawWin
    if not win then return end
    AT._zoneDrawWin = nil
    local ok, err = pcall(cancelZoneCreate, win)
    if not ok then
        print("[ZeD] Animals: the zone drawing could not be ended cleanly: " .. tostring(err))
        -- whatever failed above, the world menu and the zones are handed back
        ISWorldObjectContextMenu.disableWorldMenu = false
        local player = getSpecificPlayer(0)
        if player then pcall(player.setSeeDesignationZone, player, false) end
    end
end

-- safe mode (SafeMode.lua): a drawing in progress ends as ZeD steps aside;
-- nothing to take over again on the way back
if ZeD.Safe and ZeD.Safe.register then
    ZeD.Safe.register("animal zones", { leave = AT.endZoneDraw, enter = function() end })
end

confirmZoneCreate = function(win)
    local zc = getZoneCreateState(win)
    local startX, startY = zc.startX, zc.startY
    local endX, endY = zc.endX, zc.endY

    -- Normalize so start < end
    if startX > endX then startX, endX = endX, startX end
    if startY > endY then startY, endY = endY, startY end
    endX = endX + 1
    endY = endY + 1

    local zone = DesignationZoneAnimal.new(zc.name, startX, startY, zc.z, endX, endY, true)
    zone:createSurroundingFence()

    -- Flag for hotsave (matches vanilla)
    local sq = getSquare(startX, startY, zc.z)
    if sq then sq:flagForHotSave() end

    -- Refresh alert poller to pick up the new zone
    AP().refreshCache()

    cancelZoneCreate(win)
end

-- ============================================================================
-- ZONE RENAME / REMOVE — called from zone detail view buttons
-- ============================================================================

local function renameZone(win)
    -- Set rename mode — the band shows Save / Cancel / Reset, the info band the text entry
    win._animalsRenaming = true

    local state = getState(win)
    local zone = getZoneByName(state.zoneName)
    if not zone then return end

    -- Create text entry as a child of the window (not the drawer panel)
    if not win._animalsRenameEntry then
        local T = ZeD.T
        local entry = ISTextEntryBox:new("", 0, 0, T.px(200), T.inputH or T.px(20))
        entry:initialise()
        entry:instantiate()
        entry:setMaxTextLength(30)
        entry.zedEntry = true   -- typed text follows the UI scale (ZeD.Text.fitEntry)
        entry:setVisible(false)
        win:addChild(entry)
        win._animalsRenameEntry = entry
    end

    -- Position and show the entry
    local entry = win._animalsRenameEntry
    entry:setText(zone:getName())
    entry:setVisible(true)
    entry:focus()
    if ZeD.selectDefault then ZeD.selectDefault(entry) end   -- (typing replaces the name offered)
end

local function commitRename(win)
    local state = getState(win)
    local zone = getZoneByName(state.zoneName)
    local entry = win._animalsRenameEntry
    if zone and entry then
        local newName = entry:getText()
        if newName then newName = string.match(newName, "^%s*(.-)%s*$") end  -- trim
        if newName and #newName > 0 then
            zone:setName(newName)
            state.zoneName = newName  -- update stored name to match
            AP().refreshCache()
        end
    end
    if entry then
        entry:setVisible(false)
        entry:unfocus()
    end
    win._animalsRenaming = false
end

local function cancelRename(win)
    local entry = win._animalsRenameEntry
    if entry then entry:setVisible(false) end
    win._animalsRenaming = false
end

local function removeZone(win)
    -- Set confirm flag — the band asks the question (Cancel and Remove) instead of the usual buttons
    win._animalsRemoveConfirm = true
end

local function confirmRemoveZone(win)
    local state = getState(win)
    local zone = getZoneByName(state.zoneName)
    if not zone then return end

    local sq = getSquare(zone:getX(), zone:getY(), zone:getZ())
    if sq then sq:flagForHotSave() end

    DesignationZoneAnimal.removeZone(zone, true)
    AP().refreshCache()
    win._animalsRemoveConfirm = false
    navigateBack(win)
end

local function cancelRemoveZone(win)
    win._animalsRemoveConfirm = false
end

-- Returns normalized width, height, valid flags.
-- Hoist: assigned into the forward-declared slot so gpConfirm above sees it.
getZoneDimensions = function(zc)
    if not zc.startX or not zc.endX then return 0, 0, false, false end
    local sx, sy, ex, ey = zc.startX, zc.startY, zc.endX, zc.endY
    if sx > ex then sx, ex = ex, sx end
    if sy > ey then sy, ey = ey, sy end
    local w = (ex - sx) + 1
    local h = (ey - sy) + 1
    local wOk = w >= ZONE_MIN_DIM and w <= ZONE_MAX_DIM
    local hOk = h >= ZONE_MIN_DIM and h <= ZONE_MAX_DIM
    return w, h, wOk, hOk
end

-- Called every frame during zone create to track mouse drag on game world
local function updateZoneCreateMouse(win)
    local zc = getZoneCreateState(win)
    if not zc.active then return end
    if zc.phase == "confirm" then return end  -- don't track during confirm

    local player = getSpecificPlayer(0)
    if not player then return end
    local cell = getCell()
    if not cell then return end
    local mouseDown = isMouseButtonDown(0)

    -- Helper: get grid square at current mouse position
    local function pickSquare()
        local mx, my = getMouseX(), getMouseY()
        local wx = screenToIsoX(0, mx, my, zc.z)
        local wy = screenToIsoY(0, mx, my, zc.z)
        return cell:getGridSquare(wx, wy, zc.z)
    end

    if zc.phase == "idle" then
        -- Start drag on mouse down
        if mouseDown and not zc.wasDown then
            local sq = pickSquare()
            if sq then
                zc.startX = sq:getX()
                zc.startY = sq:getY()
                zc.endX = zc.startX
                zc.endY = zc.startY
                zc.phase = "drawing"
            end
        end
    elseif zc.phase == "drawing" then
        -- Update end point while dragging
        if mouseDown then
            local sq = pickSquare()
            if sq then
                zc.endX = sq:getX()
                zc.endY = sq:getY()
            end
        end
        -- Release → go to confirm
        if not mouseDown and zc.wasDown then
            local w, h, wOk, hOk = getZoneDimensions(zc)
            if wOk and hOk then
                zc.phase = "confirm"
            else
                -- Invalid size — reset
                zc.phase = "idle"
                zc.startX = nil
                zc.startY = nil
                zc.endX = nil
                zc.endY = nil
            end
        end
    end

    zc.wasDown = mouseDown

    -- Draw highlight rectangle while drawing
    if zc.startX and zc.endX then
        local sx, sy, ex, ey = zc.startX, zc.startY, zc.endX, zc.endY
        if sx > ex then sx, ex = ex, sx end
        if sy > ey then sy, ey = ey, sy end
        local r, g, b, a = 0.2, 0.4, 0.9, 0.35
        local w, h, wOk, hOk = getZoneDimensions(zc)
        if not wOk or not hOk then r, g, b = 1, 0, 0 end
        addAreaHighlightForPlayer(0, sx, sy, ex + 1, ey + 1, zc.z, r, g, b, a)
    end

    -- Gamepad cursor: a 1×1 tile highlight during the idle phase so the user
    -- can see where the first corner will drop. Skipped in drawing/confirm
    -- phases since the main rect highlight subsumes it.
    if zc.phase == "idle" and zc.cursorX and zc.cursorY then
        addAreaHighlightForPlayer(0,
            zc.cursorX, zc.cursorY,
            zc.cursorX + 1, zc.cursorY + 1,
            zc.z, 0.9, 0.9, 0.2, 0.5)
    end
end

-- Render dimensions block (shared by drawing + confirm phases): width, height and
-- total in tiles. A side outside the allowed size carries a red square, the others
-- a green one; the numbers stay in the default text colour.
local function drawZoneDimensions(panel, x, y, w, zc)
    local T = ZeD.T
    local A = ZeD.Atoms
    local tm = ZeD.TM
    local lblFont = T.fontF2
    local dimFont = T.fontF3
    local zw, zh, wOk, hOk = getZoneDimensions(zc)
    local rowH = math.max(tm:getFontHeight(lblFont), tm:getFontHeight(dimFont)) + T.px(4)
    local sq = T.px(6)
    local valX = x + T.px(72)
    local curY = y

    local function row(label, value, ok)
        local ld = T.textDim
        panel:drawText(tc(label), x, curY + math.floor((rowH - tm:getFontHeight(lblFont)) / 2),
            ld.r, ld.g, ld.b, ld.a or 1, lblFont)
        if ok ~= nil then
            A.drawStatusDot(panel, valX, curY + math.floor((rowH - sq) / 2), ok and T.positive or T.danger, sq)
        end
        panel:drawText(tostring(value), valX + sq + T.px(6), curY + math.floor((rowH - tm:getFontHeight(dimFont)) / 2),
            T.text.r, T.text.g, T.text.b, T.text.a or 1, dimFont)
        curY = curY + rowH
    end
    row(getText("IGUI_DesignationZone_Type_Width"), zw, wOk)
    row(getText("IGUI_DesignationZone_Type_Height"), zh, hOk)
    row(getText("IGUI_Total"), zw * zh, nil)
    return curY - y
end

-- Zone creation view: content area (above the band)
local function renderZoneCreateContent(panel, win, x, y, w, h)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local tm = ZeD.TM
    local zc = getZoneCreateState(win)
    local pad = M.getTabPad()
    local curY = y

    -- Update mouse tracking every frame
    updateZoneCreateMouse(win)

    -- What is being made: the section head
    curY = curY + M.drawSectionHeader(panel, x + pad, curY, w - pad,
        ZeD.tr("UI_ZeD_Animals_CreateZoneTitle"), nil, true, false, nil, nil, pad, nil, true) + pad

    -- Zone name
    local f2 = T.fontF2
    local fh = tm:getFontHeight(f2)
    local ld = T.textDim
    panel:drawText(tc(getText("IGUI_Name")), x + pad, curY, ld.r, ld.g, ld.b, ld.a or 1, f2)
    panel:drawText(zc.name, x + pad + T.px(72), curY, T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
    curY = curY + fh + T.px(12)

    if zc.phase == "idle" then
        -- how to draw it, then the size limits
        for _, ln in ipairs(A.wrapText(ZeD.tr("UI_ZeD_Animals_ZoneDrawHint"), f2, w - pad * 2)) do
            panel:drawText(ln, x + pad, curY, T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
            curY = curY + fh
        end
        curY = curY + T.px(8)
        panel:drawText(ZeD.tr("UI_ZeD_Animals_ZoneSizeLimits", ZONE_MIN_DIM, ZONE_MAX_DIM), x + pad, curY,
            ld.r, ld.g, ld.b, ld.a or 1, f2)
    else
        -- drawing and confirming both show the size so far
        drawZoneDimensions(panel, x + pad, curY, w, zc)
    end
end

-- The band while a zone is being made, by phase. Its buttons are mouse-only
-- (the controller draws the zone with the D-pad and A / B); the click zones keep
-- their old names for onClick:
--   _zoneConfirmYes  Create (confirm phase)
--   _zoneConfirmNo   Cancel in the confirm phase: back to drawing
--   _zoneCancelBtn   Cancel while idle / drawing: leave zone creation
local function drawZoneCreateBand(panel, win, x, y, w)
    local M = ZeD.Molecules
    local zc = getZoneCreateState(win)

    -- Clear previous zones
    win._zoneConfirmYes = nil
    win._zoneConfirmNo = nil
    win._zoneCancelBtn = nil

    local H, out
    if zc.phase == "confirm" then
        local zw, zh = getZoneDimensions(zc)
        H, out = M.drawBand(panel, x, y, w, {
            win = win,
            status = { text = ZeD.tr("UI_ZeD_Animals_CreateZoneAsk", zw, zh) },
            buttons = {
                { label = ZeD.tr("UI_Cancel"), help = ZeD.tr("UI_ZeD_Animals_HelpZoneRedraw") },
                { label = ZeD.tr("UI_ZeD_Animals_BtnCreate"), variant = "primary", help = ZeD.tr("UI_ZeD_Animals_HelpZoneCreate") },
            },
        })
        win._zoneConfirmNo = out.buttons[1]
        win._zoneConfirmYes = out.buttons[2]
    else
        H, out = M.drawBand(panel, x, y, w, {
            win = win,
            status = (zc.phase == "drawing") and { text = ZeD.tr("UI_ZeD_Animals_ZoneReleaseHint") } or nil,
            buttons = { { label = ZeD.tr("UI_Cancel"), help = ZeD.tr("UI_ZeD_Animals_HelpZoneLeave") } },
        })
        win._zoneCancelBtn = out.buttons[1]
    end
    return H
end

-- Combined render for zone create mode (called from main render)
local function renderZoneCreateView(panel, win, x, y, w, h)
    local bandH = ZeD.Molecules.bandH()
    drawZoneCreateBand(panel, win, x, y + h - bandH, w)
    renderZoneCreateContent(panel, win, x, y, w, h - bandH)
end

-- ============================================================================
-- EMPTY STATE
-- One dim line under the list's head, a full sentence; the way out (Create zone)
-- is a button in the band.
-- ============================================================================

local function drawEmptyState(panel, win, x, y, w, h)
    local T = ZeD.T
    local M = ZeD.Molecules
    local pad = M.getTabPad()
    local hdrH = M.drawCategoryRow(panel, x, y, w, ZeD.tr("UI_ZeD_Animals_SecZones"), 0, false, { noArrow = true })
    M.drawEmptyLine(panel, x + pad, y + hdrH + T.px(8), w - pad * 2, ZeD.tr("UI_ZeD_Animals_NoZonesYet"))
end

-- ============================================================================
-- SUBMODE STRIP — RANCH / BUTCHER
-- ============================================================================

local SUBMODES = {
    { id = "ranch",   label = "UI_ZeD_Animals_SubRanch",  help = "UI_ZeD_Animals_HelpRanch" },   -- text keys: translated where drawn
    { id = "butcher", label = "IGUI_Butcher",             help = "UI_ZeD_Animals_HelpButcher" },
}

--- Draw the sub-tab strip: the library's tab (ZeD.Molecules.drawTab), the same as
-- the Journal's. The active tab is open at the bottom into its content; the strip's
-- structure line runs under the others and stops short of the active one.
-- @return tabStripH (T.tabH)
local function drawSubmodeStrip(panel, win, x, y, w)
    local T    = ZeD.T
    local A    = ZeD.Atoms
    local M    = ZeD.Molecules
    local tH   = T.tabH
    local gap  = T.sp.tabGap
    local tm   = ZeD.TM
    local state = getState(win)

    local tabX = x + T.sp.sm
    local zones = {}
    local activeX, activeW

    for _, sm in ipairs(SUBMODES) do
        local smLabel = ZeD.tr(sm.label)
        local tw = tm:MeasureStringX(T.fontF2, A.textCase(smLabel)) + T.sp.tabPadX * 2
        local isActive = (state.submode == sm.id)
        local hovered = A.mouseIn(panel, tabX, y, tw, tH)
        if hovered then help(panel, sm.help) end
        M.drawTab(panel, tabX, y, smLabel, isActive, hovered, false,
            { focus = focusFor(win, "animals:submode:" .. sm.id) })
        if isActive then activeX, activeW = tabX, tw end
        zones[#zones + 1] = { x = tabX, y = y, w = tw, h = tH, id = sm.id }
        tabX = tabX + tw + gap
    end

    -- the strip's line, around the active tab
    local ly = y + tH - T.hair
    if activeX then
        A.drawDividerH(panel, x, ly, activeX - x, true)
        A.drawDividerH(panel, activeX + activeW, ly, x + w - (activeX + activeW), true)
    else
        A.drawDividerH(panel, x, ly, w, true)
    end

    win._animalsSubmodeZones = zones
    return tH
end

-- ============================================================================
-- BACK — the library's back key in a row of its own (zone and animal views)
-- ============================================================================

local function drawBackBar(panel, win, x, y, w)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local state = getState(win)
    local sz = T.buttonH
    local h = sz + T.px(BACK_PAD) * 2

    A.surfaceFill(panel, x, y, w, h, "surf2")
    A.drawDividerH(panel, x, y + h - T.hair, w, true)

    local bx, by = x + T.px(8), y + T.px(BACK_PAD)
    local hover = A.mouseIn(panel, bx, by, sz, sz)
    if hover then
        if state.view == "zone" then help(panel, "UI_ZeD_Animals_HelpBackOverview")
        elseif state.submode == "butcher" then help(panel, "UI_ZeD_Animals_HelpBackButcher")
        else help(panel, "UI_ZeD_Animals_HelpBackZone", state.zoneName or "") end
    end
    M.drawBackButton(panel, bx, by, sz, { hover = hover, win = win, focus = focusFor(win, "animals:back:" .. tostring(state.view)) })

    -- Store click zone for back navigation (the key; the ring takes its rect too)
    win._animalsBreadcrumbZone = { x = bx, y = by, w = sz, h = sz }

    return h
end

-- ============================================================================
-- CATEGORY ROW — "v Weapons (4)": the library's row for a list's group
-- ============================================================================

local function catRow(panel, win, x, y, w, name, count, expanded, noArrow, focusId, helpKey)
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local rowH = ZeD.T.px(15)
    local hover = (not noArrow) and A.mouseIn(panel, x, y, w, rowH)
    if hover and helpKey then help(panel, helpKey) end
    return M.drawCategoryRow(panel, x, y, w, name, count, expanded, {
        hover = hover, noArrow = noArrow, focus = focusId and focusFor(win, focusId) or nil })
end

-- ============================================================================
-- M-ALERT — ALERT ROW
-- Portrait icon + animal name + species + a tag for what is wrong + one push
-- button for what to do about it: Milk, Shear, or Walk to for the rest (the
-- game's words). Row height = 36px. The button is greyed when the game would not
-- let you (no bucket, no shears, a full inventory), and the reason shows in a
-- balloon over it. On the controller the row is the stop and A presses its button.
-- ============================================================================

-- the game's word for each verb, and the help line over its button
local VERB_LABEL = { milk = "ContextMenu_Milk", shear = "ContextMenu_Shear", ["goto"] = "ContextMenu_Walk_to", feed = "ContextMenu_Feed" }
local VERB_HELP  = { milk = "UI_ZeD_Animals_HelpMilkOne", shear = "UI_ZeD_Animals_HelpShearOne", ["goto"] = "UI_ZeD_Animals_HelpGoTo" }
local function verbLabel(v) return getText(VERB_LABEL[v] or "ContextMenu_Walk_to") end

-- A greyed button's reason, as a balloon over it: after the pause for the pointer, at
-- once for the controller's focus. One card per button, rebuilt only when its words
-- change (the balloon keeps showing the card it already has).
local _whyCards = {}
local _nowOpts = { now = true }
local function whyBalloon(panel, win, key, label, why, rect, focused)
    if not why or why == "" or not (ZeD.Atoms and ZeD.Atoms.requestDetailCard) then return end
    local T = ZeD.T
    local c = _whyCards[key]
    if not c or c.title ~= label or c._why ~= why or c._col ~= T.dangerText then
        c = { title = label, lines = { { text = why, color = T.dangerText } }, _why = why, _col = T.dangerText, key = key }
        _whyCards[key] = c
    end
    ZeD.Atoms.requestDetailCard(win, key, c, panel, rect, focused and _nowOpts or nil)
end

local ALERT_ROW_H = 36
local ALERT_ICON_SZ = 24
local ALERT_PAD = 6

-- text keys (vanilla's where it has the word), drawn in sentence case
local ALERT_LABELS = {
    udder_urgent = "IGUI_Animal_Udder",
    ready_milk   = "ContextMenu_Milk",
    ready_shear  = "ContextMenu_Shear",
    thirsty      = "IGUI_Animal_Thirsty",
    hungry       = "Moodles_Hungry_lvl2",
    stressed     = "IGUI_Animal_Stressed",
    lost_mother  = "UI_ZeD_Animals_AlertOrphan",
}

-- Returns the row's height and its button: { x, y, w, h, verb, ok, why }.
local function drawAlertRow(panel, x, y, w, alert, win, idx, player)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local ad = AD()
    local animal = alert.animal
    local rowH = T.px(ALERT_ROW_H)
    -- (the controller's stop: A presses the row's button)
    local onFocus = markId(panel, win, "animals:alert:" .. tostring(idx), x, y, w, rowH)
    local ink = onFocus and T.textOnFocus or T.text
    local inkDim = onFocus and T.textOnFocus or T.textDim

    -- Portrait icon
    local portraitPath = ad.resolvePortrait(animal)
    local tex = getTexture(portraitPath)
    local iconY = y + math.floor((rowH - T.px(ALERT_ICON_SZ)) / 2)
    if tex then
        panel:drawTextureScaledAspect(tex, x + T.px(ALERT_PAD), iconY, T.px(ALERT_ICON_SZ), T.px(ALERT_ICON_SZ), 0.9, 1, 1, 1)
    end

    -- Name + species
    local nameX = x + T.px(ALERT_PAD) + T.px(ALERT_ICON_SZ) + T.px(ALERT_PAD)
    local name = ad.getDisplayName(animal)
    local atype = ad.getAnimalType(animal)
    local species = getText("IGUI_AnimalType_" .. atype) or atype

    local f2 = T.fontF2
    local fh = ZeD.TM:getFontHeight(f2)
    local textY = y + math.floor((rowH - fh * 2) / 2)

    panel:drawText(name, nameX, textY, ink.r, ink.g, ink.b, ink.a or 1, f2)
    panel:drawText(species, nameX, textY + fh, inkDim.r, inkDim.g, inkDim.b, inkDim.a or 1, f2)

    -- What to do: the verb's push button at the right (Milk and Shear are the default
    -- button, Walk to a plain one), greyed when the game would not let you
    local verb = QK().alertVerb(alert.alertType)
    local ok, why = QK().check(verb, player, animal)
    local vLabel = verbLabel(verb)
    local bw = M.buttonW(vLabel)
    local bx = x + w - T.px(ALERT_PAD) - bw
    local bHover = A.mouseIn(panel, bx, y, bw, rowH)
    local vHelp = ok and ZeD.tr(VERB_HELP[verb], name) or why
    local rbx, rby, rbw, rbh = M.drawButton(panel, bx, y, bw, rowH, vLabel, (verb ~= "goto") and "primary" or "default",
        false, nil, { compact = true, hover = bHover, disabled = not ok, win = win, help = vHelp })
    local btn = { x = rbx, y = rby, w = rbw, h = rbh, verb = verb, ok = ok, why = why }
    if not ok and (bHover or onFocus) then
        whyBalloon(panel, win, "animals:alertwhy:" .. tostring(idx), vLabel, why, btn, onFocus)
    end

    -- What is wrong: a tag with its status square, left of the button
    local label = ZeD.tr(ALERT_LABELS[alert.alertType] or "UI_ZeD_Animals_AlertDefault")
    local tw = tagWidth(label, sevColor(T, alert.severity) ~= nil)
    drawTag(panel, bx - T.px(8) - tw, tagY(y, rowH), label, alert.severity)

    -- Bottom divider
    A.drawDividerH(panel, x, y + rowH - T.px(1), w, false)

    return rowH, btn
end

--- Press an alert's verb: the game's own milk, shear or walk for that animal. Does nothing
-- when the game would not let you (the button is greyed then). The World window's
-- controller ring calls this for A on an alert row.
function AT.alertAct(win, animal, verb)
    local player = getSpecificPlayer(0)
    if not (player and animal and verb) then return false end
    return QK().act(verb, player, animal)
end
-- ============================================================================
-- M-ZRSUM — ZONE SUMMARY CARD
-- Zone name + animal count + species breakdown + 3 mini-meters (food/water/roof)
-- + male aggression warning. Clickable → navigate to zone view.
-- Returns: cardH consumed.
-- ============================================================================

local ZCARD_PAD    = 6
local ZCARD_MIN_H  = 52

-- Measure cardH ahead of the draw pass so the hover wash and the controller's
-- mark cover the full card area.
local function measureZoneCardH(summary)
    local T = ZeD.T
    local tm = ZeD.TM
    local nameH  = tm:getFontHeight(T.fontF2)
    local specH  = tm:getFontHeight(T.fontF2)
    local lblH   = tm:getFontHeight(T.fontF1)
    local fillBarH = T.fillBarH

    local h = T.px(ZCARD_PAD) + nameH + T.px(4)

    local animals = summary.animals or {}
    if #animals > 0 then
        h = h + specH + T.px(4)
    end

    h = h + lblH + T.px(2) + fillBarH + T.px(4)

    local warns = summary.maleWarnings or {}
    h = h + #warns * T.px(18)

    h = h + T.px(ZCARD_PAD)
    return math.max(T.px(ZCARD_MIN_H), h)
end

local function drawZoneSummary(panel, x, y, w, summary, win)
    local T = ZeD.T
    local A = ZeD.Atoms
    local ad = AD()

    -- pre-measured cardH so the wash and the mark cover the true card area
    local cardH = measureZoneCardH(summary)

    -- Hover wash under the words; then the controller's mark (draw order = paint order)
    local hovered = A.mouseIn(panel, x, y, w, cardH)
    if hovered then
        local hv = T.hover
        panel:drawRect(x, y, w, cardH, hv.a, hv.r, hv.g, hv.b)
        help(panel, "UI_ZeD_Animals_HelpZoneCard")
    end
    local onFocus = markId(panel, win, "animals:zonecard:" .. tostring(summary.name), x, y, w, cardH)
    local ink = onFocus and T.textOnFocus or T.text
    local inkDim = onFocus and T.textOnFocus or T.textDim

    local curY = y + T.px(ZCARD_PAD)

    -- Zone name (left) + count (right)
    local nameFont = T.fontF2
    local nameH = ZeD.TM:getFontHeight(nameFont)
    local name = summary.name or ZeD.tr("UI_ZeD_Animals_UnnamedZone")
    panel:drawText(name, x + T.px(ZCARD_PAD), curY, ink.r, ink.g, ink.b, ink.a or 1, nameFont)

    local countStr = tostring(summary.count or 0)
    local countFont = T.fontF3
    local countW = ZeD.TM:MeasureStringX(countFont, countStr)
    panel:drawText(countStr, x + w - T.px(ZCARD_PAD) - countW, curY, ink.r, ink.g, ink.b, ink.a or 1, countFont)
    curY = curY + nameH + T.px(4)

    -- Species breakdown line (e.g. "3 cow, 2 chicken")
    local animals = summary.animals or {}
    local specCounts = {}
    for _, animal in ipairs(animals) do
        local atype = ad.getAnimalType(animal)
        specCounts[atype] = (specCounts[atype] or 0) + 1
    end
    local specParts = {}
    for atype, cnt in pairs(specCounts) do
        local label = getText("IGUI_AnimalType_" .. atype) or atype
        table.insert(specParts, ZeD.tr("UI_ZeD_Animals_CountSpecies", cnt, label))
    end
    if #specParts > 0 then
        local specLine = table.concat(specParts, ", ")
        local specFont = T.fontF2
        panel:drawText(specLine, x + T.px(ZCARD_PAD), curY, inkDim.r, inkDim.g, inkDim.b, inkDim.a or 1, specFont)
        curY = curY + ZeD.TM:getFontHeight(specFont) + T.px(4)
    end

    -- Status bars — 3 across on one line: label above, framed bar below, 8u between
    local M = ZeD.Molecules
    local tm = ZeD.TM
    local barGap = T.px(8)
    local barPad = T.px(ZCARD_PAD)
    local totalBarW = w - barPad * 2
    local barW = math.floor((totalBarW - barGap * 2) / 3)
    local fillBarH = T.fillBarH
    local lblFont = T.fontF1
    local lblH = tm:getFontHeight(lblFont)

    local bars = {
        { label = tc(getText("IGUI_ItemCat_Food")),          ratio = (summary.food or 0) / 100 },
        { label = tc(getText("IGUI_FeedingTroughUI_Water")), ratio = (summary.water or 0) / 100 },
        { label = tc(ZeD.tr("UI_ZeD_Animals_Roof")),         ratio = (summary.roof or 0) / 100 },
    }

    local bx = x + barPad
    for _, bar in ipairs(bars) do
        -- Label on top
        panel:drawText(bar.label, bx, curY, inkDim.r, inkDim.g, inkDim.b, inkDim.a or 1, lblFont)
        -- Percentage right-aligned on top
        local pct = math.floor(bar.ratio * 100) .. "%"
        local pctW = tm:MeasureStringX(lblFont, pct)
        panel:drawText(pct, bx + barW - pctW, curY, ink.r, ink.g, ink.b, ink.a or 1, lblFont)
        -- Fill bar below label
        M.drawFillBar(panel, bx, curY + lblH + T.px(2), barW, bar.ratio, nil, bar.label)
        bx = bx + barW + barGap
    end
    curY = curY + lblH + T.px(2) + fillBarH + T.px(4)

    -- Male aggression warnings
    if #(summary.maleWarnings or {}) > 0 then
        for _, atype in ipairs(summary.maleWarnings) do
            local warnLabel = getText("IGUI_AnimalType_" .. atype) or atype
            drawTag(panel, x + T.px(ZCARD_PAD), curY, ZeD.tr("UI_ZeD_Animals_MalesBadge", warnLabel), "warning")
            curY = curY + T.px(18)
        end
    end

    -- cardH pre-measured above; keep the tail assertion as a defense check
    -- should any content overflow beyond what measureZoneCardH predicted.
    local drawnH = (curY - y) + T.px(ZCARD_PAD)
    if drawnH > cardH then cardH = drawnH end

    -- Bottom divider to separate cards
    A.drawDividerH(panel, x, y + cardH - T.px(1), w, false)

    -- Store click zone for zone navigation
    if not win._animalsZoneCardZones then win._animalsZoneCardZones = {} end
    table.insert(win._animalsZoneCardZones, {
        x = x, y = y, w = w, h = cardH, zoneName = summary.name
    })

    return cardH
end

-- ============================================================================
-- M-TOT — PRODUCTION TOTALS (2-column)
-- Left column: species counts. Right column: eggs/day + milk/day.
-- Returns: totalH consumed.
-- ============================================================================

local function drawTotals(panel, x, y, w, totals)
    local T = ZeD.T
    local pad = T.px(ZCARD_PAD)
    local curY = y

    local statFont = T.fontF3
    local lblFont = T.fontF2
    local rowH = ZeD.TM:getFontHeight(statFont) + T.px(4)
    local colW = math.floor((w - pad) / 2)
    local tt, td = T.text, T.textDim

    -- Left column: species counts
    local leftX = x + pad
    local leftY = curY
    local specCounts = totals.speciesCounts or {}
    -- Sort species for stable display
    local specKeys = {}
    for k, _ in pairs(specCounts) do table.insert(specKeys, k) end
    table.sort(specKeys)

    for _, atype in ipairs(specKeys) do
        local cnt = specCounts[atype]
        local label = getText("IGUI_AnimalType_" .. atype) or atype
        local valStr = tostring(cnt)

        panel:drawText(valStr, leftX, leftY, tt.r, tt.g, tt.b, tt.a or 1, statFont)
        local valW = ZeD.TM:MeasureStringX(statFont, valStr)
        panel:drawText(label, leftX + valW + T.px(6), leftY, td.r, td.g, td.b, td.a or 1, lblFont)
        leftY = leftY + rowH
    end

    -- Right column: production estimates
    local rightX = x + colW + pad
    local rightY = curY

    if totals.eggsPerDay and totals.eggsPerDay > 0 then
        local eggStr = string.format("%.1f", totals.eggsPerDay)
        panel:drawText(eggStr, rightX, rightY, tt.r, tt.g, tt.b, tt.a or 1, statFont)
        local eW = ZeD.TM:MeasureStringX(statFont, eggStr)
        panel:drawText(tc(ZeD.tr("UI_ZeD_Animals_EggsPerDay")), rightX + eW + T.px(6), rightY, td.r, td.g, td.b, td.a or 1, lblFont)
        rightY = rightY + rowH
    end

    if totals.milkPerDay and totals.milkPerDay > 0 then
        local milkStr = string.format("%.0f", totals.milkPerDay)
        panel:drawText(milkStr, rightX, rightY, tt.r, tt.g, tt.b, tt.a or 1, statFont)
        local mW = ZeD.TM:MeasureStringX(statFont, milkStr)
        panel:drawText(tc(ZeD.tr("UI_ZeD_Animals_MilkPerDay")), rightX + mW + T.px(6), rightY, td.r, td.g, td.b, td.a or 1, lblFont)
        rightY = rightY + rowH
    end

    local totalH = math.max(leftY, rightY) - curY
    return math.max(rowH, totalH)
end

-- ============================================================================
-- O-ANOVW — RANCH OVERVIEW ORGANISM
-- Composes: Alerts section → Zones section → Totals section.
-- Reads all data from AlertPoller cache. Collapsible sections.
-- The whole page scrolls as one unit: 24 animals can make 27 alerts — a page of 1961 in a 650 view, no way down to
-- the Totals, rows running under the Create zone band. win._animalsScroll is the real bar, clipped between the tab
-- strip and the band. Its height is last frame's (win._animalsOvH).
-- ============================================================================

-- the controller's stop kept in view (win._animalsOvRows: each stop's place in the page, from the last frame)
local function ovFollow(win, scroll, maxOff, h, listH)
    local el = liveEl(win)
    local r = el and el.id and win._animalsOvRows and win._animalsOvRows[el.id]
    if not r or maxOff <= 0 then return end
    local rh = r.h
    -- (the Totals' head: its rows are below it, not stops of their own)
    if el.id == "animals:disclosure:totalsExpanded" then rh = listH - r.cy end
    local off0 = math.floor(scroll.scrollPos * maxOff)
    local off1 = off0
    if r.cy < off0 then off1 = r.cy elseif r.cy + rh > off0 + h then off1 = math.min(r.cy, r.cy + rh - h) end
    if off1 ~= off0 then scroll:setScrollPos(off1 / maxOff) end
end

local function renderRanchOverview(panel, win, x, y, w, h)
    -- Force cache refresh on first render
    if not AP().isReady() then AP().refreshCache() end

    -- Reset click zones (an empty overview must not keep last frame's)
    win._animalsZoneCardZones = {}
    win._animalsSectionZones = {}
    win._animalsAlertZones = {}

    local zones = AP().getZoneList()
    if #zones == 0 then
        drawEmptyState(panel, win, x, y, w, h)
        return
    end

    local T = ZeD.T
    local M = ZeD.Molecules
    local pad = M.getTabPad()

    -- Section collapse state
    if not win._animalsOverviewState then
        win._animalsOverviewState = {
            alertsExpanded = true,
            zonesExpanded  = true,
            totalsExpanded = true,
        }
    end
    local ovState = win._animalsOverviewState

    -- the scroll: the page's height from the last frame, the bar at the right
    local scroll = win._animalsScroll
    local listH = win._animalsOvH or 0
    local needs = scroll ~= nil and listH > h
    local maxOff = math.max(0, listH - h)
    local off = 0
    if scroll then
        scroll.visible = needs
        if needs then
            scroll.x, scroll.y, scroll.height = x + w - T.sp.scrollbarW, y, h
            scroll.width = T.sp.scrollbarW
            scroll.lineH = T.px(ALERT_ROW_H)
            scroll:setBarSize(h / listH)
            ovFollow(win, scroll, maxOff, h, listH)
            off = math.floor(scroll.scrollPos * maxOff)
        else
            scroll:setScrollPos(0)
        end
    end
    if needs then w = w - T.sp.scrollbarW end
    win._animalsOvClip = { y = y, h = h }
    local rows = {}
    win._animalsOvRows = rows
    local top = y - off
    panel:setStencilRect(x, y, w, h)

    local curY = top  -- header sits flush against tab strip bottom

    -- ── ALERTS SECTION ──
    local alerts = AP().getAlerts()
    if #alerts > 0 then
        local secY = curY
        local catH = catRow(panel, win, x, curY, w, ZeD.tr("UI_ZeD_Animals_SecAlerts"), #alerts,
            ovState.alertsExpanded, false, "animals:disclosure:alertsExpanded", "UI_ZeD_Animals_HelpFold")
        table.insert(win._animalsSectionZones, {
            x = x, y = secY, w = w, h = catH, key = "alertsExpanded"
        })
        rows["animals:disclosure:alertsExpanded"] = { cy = secY - top, h = catH }
        curY = curY + catH

        if ovState.alertsExpanded then
            local player = getSpecificPlayer(0)
            for i, alert in ipairs(alerts) do
                local rh, btn = drawAlertRow(panel, x + pad, curY, w - pad * 2, alert, win, i, player)
                table.insert(win._animalsAlertZones, { x = x + pad, y = curY, w = w - pad * 2, h = rh, i = i,
                    btn = btn, animal = alert.animal, verb = btn.verb })
                rows["animals:alert:" .. tostring(i)] = { cy = curY - top, h = rh }
                curY = curY + rh
            end
        end
    end

    -- ── ZONES SECTION ── (always open: its head has no triangle and is not pressed)
    curY = curY + catRow(panel, win, x, curY, w, ZeD.tr("UI_ZeD_Animals_SecZones"), #zones, true, true, nil, nil)

    for _, zone in ipairs(zones) do
        -- Get zone name for name-based cache lookup
        local zname = ""
        if zone.getName then
            local ok, val = pcall(zone.getName, zone)
            if ok and val then zname = val end
        end
        local summary = AP().getZoneSummary(zname)
        if summary then
            local ch = drawZoneSummary(panel, x + pad, curY, w - pad * 2, summary, win)
            rows["animals:zonecard:" .. tostring(summary.name)] = { cy = curY - top, h = ch }
            curY = curY + ch
        end
    end

    -- ── TOTALS SECTION ──
    local totals = AP().getTotals()
    if totals and (totals.totalAnimals or 0) > 0 then
        local secY = curY
        local catH = catRow(panel, win, x, curY, w, ZeD.tr("UI_ZeD_Animals_SecTotals"), totals.totalAnimals,
            ovState.totalsExpanded, false, "animals:disclosure:totalsExpanded", "UI_ZeD_Animals_HelpFold")
        table.insert(win._animalsSectionZones, {
            x = x, y = secY, w = w, h = catH, key = "totalsExpanded"
        })
        rows["animals:disclosure:totalsExpanded"] = { cy = secY - top, h = catH }
        curY = curY + catH

        if ovState.totalsExpanded then
            curY = curY + drawTotals(panel, x + pad, curY, w - pad * 2, totals)
        end
    end

    win._animalsOvH = curY - top
    -- (the bar lies outside the page's clip, so the drawer's clip is all it needs; a clip set
    -- again here stayed on and hid the window's tab strip and footer, the game counts its clips)
    panel:clearStencilRect()
    if needs then
        -- (the drawer hands a press to onClick; the hover, the drag and the release are kept here)
        local mx, my = panel:getMouseX(), panel:getMouseY()
        if scroll.dragging or scroll.upPressed or scroll.downPressed then
            if isMouseButtonDown(0) then scroll:handleMouseMove(my - scroll.y) else scroll:handleMouseUp() end
        elseif mx >= scroll.x and mx < scroll.x + scroll.width and my >= scroll.y and my < scroll.y + scroll.height then
            scroll:handleMouseMove(my - scroll.y)
        end
        scroll:draw(panel)
    end
end

-- ============================================================================
-- M-ZINF — ZONE INFO BAND
-- Zone name + animal count + 3 wide fill meters (food/water/roof) +
-- male aggression warnings. Pinned at top of zone view, not scrolled.
-- Returns: bandH consumed.
-- ============================================================================

local function drawZoneInfoBand(panel, win, x, y, w, summary)
    local T = ZeD.T
    local A = ZeD.Atoms
    local ad = AD()
    local pad = T.px(ZINF_PAD)
    local curY = y + pad
    local tm = ZeD.TM

    -- Zone name (left) + count (right)
    -- During rename mode, position the text entry over the name
    local nameFont = T.fontF2
    local nameH = tm:getFontHeight(nameFont)
    local name = summary.name or ZeD.tr("UI_ZeD_Animals_UnnamedZone")
    local nameW = tm:MeasureStringX(nameFont, name)
    local renaming = win._animalsRenaming and win._animalsRenameEntry

    if renaming then
        -- Position text entry over the zone name
        -- Entry is a child of win, so convert panel coords to window coords
        local entry = win._animalsRenameEntry
        local entryW = w - pad * 2 - T.px(100)
        local panelOffX = panel:getAbsoluteX() - win:getAbsoluteX()
        local panelOffY = panel:getAbsoluteY() - win:getAbsoluteY()
        entry:setX(panelOffX + x + pad)
        entry:setY(panelOffY + curY - T.px(2))
        entry:setWidth(entryW)
        entry:setVisible(true)
    else
        -- The name is pressable (it starts a rename): the hover wash says so
        if A.mouseIn(panel, x + pad, curY, nameW, nameH) then
            local hv = T.hover
            panel:drawRect(x + pad - T.px(2), curY - T.px(1), nameW + T.px(4), nameH + T.px(2), hv.a, hv.r, hv.g, hv.b)
            help(panel, "UI_ZeD_Animals_HelpRename")
        end
        panel:drawText(name, x + pad, curY, T.text.r, T.text.g, T.text.b, T.text.a or 1, nameFont)

        -- Store name click zone for rename trigger
        win._animalsZoneNameZone = { x = x + pad, y = curY, w = nameW, h = nameH }

        -- Hide entry if not renaming
        if win._animalsRenameEntry then
            win._animalsRenameEntry:setVisible(false)
        end
    end

    local countStr = ZeD.tr((summary.count or 0) == 1 and "UI_ZeD_Animals_AnimalCountOne" or "UI_ZeD_Animals_AnimalCountMany", summary.count or 0)
    local countFont = T.fontF3
    local countW = tm:MeasureStringX(countFont, countStr)
    panel:drawText(countStr, x + w - pad - countW, curY, T.text.r, T.text.g, T.text.b, T.text.a or 1, countFont)
    -- Zone size (on same line as name, after count)
    local zoneObj = summary.zone
    if not renaming and zoneObj and zoneObj.getW and zoneObj.getH then
        local ok1, zw = pcall(zoneObj.getW, zoneObj)
        local ok2, zh = pcall(zoneObj.getH, zoneObj)
        if ok1 and ok2 then
            local sizeStr = ZeD.tr("UI_ZeD_Animals_ZoneSquares", zw * zh)
            local sizeX = x + pad + nameW + T.px(8)
            if sizeX + tm:MeasureStringX(nameFont, sizeStr) < x + w - pad - countW - T.px(8) then
                panel:drawText(sizeStr, sizeX, curY, T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, nameFont)
            end
        end
    end
    curY = curY + nameH + T.px(4)

    -- Species breakdown line
    local animals = summary.animals or {}
    local specCounts = {}
    for _, animal in ipairs(animals) do
        local atype = ad.getAnimalType(animal)
        specCounts[atype] = (specCounts[atype] or 0) + 1
    end
    local specParts = {}
    for atype, cnt in pairs(specCounts) do
        local label = getText("IGUI_AnimalType_" .. atype) or atype
        table.insert(specParts, ZeD.tr("UI_ZeD_Animals_CountSpecies", cnt, label))
    end
    if #specParts > 0 then
        local specLine = table.concat(specParts, ", ")
        local specFont = T.fontF2
        panel:drawText(specLine, x + pad, curY, T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, specFont)
        curY = curY + tm:getFontHeight(specFont) + T.px(6)
    end

    -- Status bars — 3 across, label+% on top, framed bar below, 8u gap (same as overview card)
    local M = ZeD.Molecules
    local barGap = T.px(8)
    local totalBarW = w - pad * 2
    local barW = math.floor((totalBarW - barGap * 2) / 3)
    local fillBarH = T.fillBarH
    local lblFont = T.fontF1
    local lblH = tm:getFontHeight(lblFont)

    local bars = {
        { label = tc(getText("IGUI_ItemCat_Food")),          ratio = (summary.food or 0) / 100 },
        { label = tc(getText("IGUI_FeedingTroughUI_Water")), ratio = (summary.water or 0) / 100 },
        { label = tc(ZeD.tr("UI_ZeD_Animals_Roof")),         ratio = (summary.roof or 0) / 100 },
    }

    local bx = x + pad
    for _, bar in ipairs(bars) do
        panel:drawText(bar.label, bx, curY, T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, lblFont)
        local pct = math.floor(bar.ratio * 100) .. "%"
        local pctW = tm:MeasureStringX(lblFont, pct)
        panel:drawText(pct, bx + barW - pctW, curY, T.text.r, T.text.g, T.text.b, T.text.a or 1, lblFont)
        M.drawFillBar(panel, bx, curY + lblH + T.px(2), barW, bar.ratio, nil, bar.label)
        bx = bx + barW + barGap
    end
    curY = curY + lblH + T.px(2) + fillBarH + T.px(4)

    -- Male aggression warnings
    if #(summary.maleWarnings or {}) > 0 then
        for _, atype in ipairs(summary.maleWarnings) do
            local warnLabel = ZeD.tr("UI_ZeD_Animals_MalesBadge", getText("IGUI_AnimalType_" .. atype) or atype)
            drawTag(panel, x + pad, curY, warnLabel, "warning")
            curY = curY + T.px(18)
        end
    end

    local bandH = (curY - y) + pad

    -- The pane head's bottom: a structure line
    A.drawDividerH(panel, x, y + bandH - T.px(1), w, true)

    return bandH
end

-- ============================================================================
-- M-AROW — ANIMAL ROSTER ROW (48px)
-- Portrait (32px) + name + 3 stat squares + condition tags (top line)
-- Species + sex + age text (bottom line)
-- Returns: AROW_H consumed.
-- ============================================================================

-- A roster row's readings: the portrait, name, the three
-- stats, the condition tags and the species line, read once per animal and kept
-- for SORT_CACHE_MS (as the sort is), not every frame. Only the rows drawn are
-- read. Widths are still measured as the row draws (they follow the font and scale).
local function animalRowModel(zs, animal, player)
    local now = getTimestampMs and getTimestampMs() or 0
    local rm = zs._rowModels
    if not rm or rm.player ~= player or now - rm.t >= SORT_CACHE_MS then
        rm = { t = now, player = player, rows = {} }
        zs._rowModels = rm
    end
    local m = rm.rows[animal]
    if m then return m end
    local ad = AD()
    local atype = ad.getAnimalType(animal)
    local species = getText("IGUI_AnimalType_" .. atype) or atype
    local sex = ad.isFemale(animal) and getText("IGUI_Animal_Female") or getText("IGUI_Animal_Male")
    if ad.isBaby(animal) then sex = getText("IGUI_Animal_Baby") end
    local age = ad.getAgeText(animal, player)
    local infoLine = species .. ", " .. sex
    if age and age ~= "" then infoLine = infoLine .. " | " .. age end
    m = {
        tex    = getTexture(ad.resolvePortrait(animal)),
        name   = ad.getDisplayName(animal),
        health = ad.getHealth(animal),
        hunger = ad.getHunger(animal),
        thirst = ad.getThirst(animal),
        tags   = ad.getConditionTags(animal, player),
        info   = infoLine,
    }
    rm.rows[animal] = m
    return m
end

-- checked: the row is in the selection (its box ticked); the box's rect comes back
-- with the height, for the press that ticks it.
local function drawAnimalRow(panel, x, y, w, m, hovered, onFocus, checked)
    local T = ZeD.T
    local A = ZeD.Atoms
    local tm = ZeD.TM
    local rowH = T.px(AROW_H)
    local ink = onFocus and T.textOnFocus or T.text
    local inkDim = onFocus and T.textOnFocus or T.textDim

    -- Hover highlight
    if hovered then
        local hc = T.hover
        panel:drawRect(x, y, w, rowH, hc.a or 0.08, hc.r, hc.g, hc.b)
    end

    -- The selection box at the left (the band's Milk and Shear act on the ticked rows)
    local cb = T.checkboxSz
    local cbx, cby = x + T.px(AROW_PAD), y + math.floor((rowH - cb) / 2)
    local cbHover = A.mouseIn(panel, cbx, cby, cb, cb)
    A.drawCheckbox(panel, cbx, cby, checked and true or false, cbHover, false)
    local cbRect = { x = cbx, y = cby, w = cb, h = cb, hover = cbHover }
    local px0 = cbx + cb + T.px(AROW_PAD)

    -- Portrait icon (32px, vertically centered)
    local tex = m.tex
    local iconY = y + math.floor((rowH - T.px(AROW_ICON_SZ)) / 2)
    if tex then
        panel:drawTextureScaledAspect(tex, px0, iconY, T.px(AROW_ICON_SZ), T.px(AROW_ICON_SZ), 0.9, 1, 1, 1)
    end

    -- === TOP LINE (y + 4px) ===
    local topY = y + T.px(4)
    local textX = px0 + T.px(AROW_ICON_SZ) + T.px(AROW_PAD)

    -- Name
    local nameFont = T.fontF2
    local name = m.name
    panel:drawText(name, textX, topY, ink.r, ink.g, ink.b, ink.a or 1, nameFont)
    local nameW = tm:MeasureStringX(nameFont, name)

    -- 3 stat squares (Health / Hunger / Thirst) — after name with gap
    local dotX = textX + nameW + T.px(10)
    local dotY = topY + math.floor((tm:getFontHeight(nameFont) - T.px(AROW_DOT_SZ)) / 2)

    -- Health: high = good (green), low = bad (red)
    local health = m.health
    A.drawStatusDot(panel, dotX, dotY, dotColorForValue(T, health), T.px(AROW_DOT_SZ))
    dotX = dotX + T.px(AROW_DOT_SZ) + T.px(AROW_DOT_GAP)

    -- Hunger: INVERTED — high value means MORE hungry (bad), low = fed (good)
    local hunger = m.hunger
    A.drawStatusDot(panel, dotX, dotY, dotColorForValue(T, 100 - hunger), T.px(AROW_DOT_SZ))
    dotX = dotX + T.px(AROW_DOT_SZ) + T.px(AROW_DOT_GAP)

    -- Thirst: INVERTED — high value means MORE thirsty (bad), low = hydrated (good)
    local thirst = m.thirst
    A.drawStatusDot(panel, dotX, dotY, dotColorForValue(T, 100 - thirst), T.px(AROW_DOT_SZ))
    dotX = dotX + T.px(AROW_DOT_SZ)

    -- Condition tags (right-aligned), as many as fit beside the name and squares
    local tags = m.tags
    local tagX = x + w - T.px(AROW_PAD)
    local tagRowY = tagY(topY, tm:getFontHeight(nameFont))
    for i = #tags, 1, -1 do
        local tag = tags[i]
        local tw = tagWidth(tag.label, sevColor(T, tag.sev) ~= nil)
        tagX = tagX - tw
        if tagX < dotX + T.px(8) then break end
        drawTag(panel, tagX, tagRowY, tag.label, tag.sev)
        tagX = tagX - T.px(4)
    end

    -- === BOTTOM LINE (y + 28px) ===
    local botY = y + T.px(28)
    local secFont = T.fontF5

    -- Species + sex + age
    local infoLine = m.info

    panel:drawText(infoLine, textX, botY, inkDim.r, inkDim.g, inkDim.b, inkDim.a or 1, secFont)

    -- Bottom divider
    A.drawDividerH(panel, x, y + rowH - T.px(1), w, false)

    return rowH, cbRect
end

-- ============================================================================
-- M-STRUCT — HUTCHES / FEEDING TROUGHS / HOOKS rows
-- One 34px row per structure: tile icon, name, a line of state, a tag and
-- Open (the object card; walks there first when it is out of reach).
-- ============================================================================
local STRUCT_H = 34

local function ocall(o, m, ...)
    if o == nil or not o[m] then return nil end
    local ok, r = pcall(o[m], o, ...)
    if ok then return r end
    return nil
end

local function moveableName(o, fallback)
    local ok, n = pcall(function() return ISWorldObjectContextMenu.getMoveableDisplayName(o) end)
    if ok and n and n ~= "" then return n end
    return fallback
end

-- name, the line of state, the tag word and its severity, the bleed progress (hooks)
local function structInfo(kind, o, player)
    local name, sub, badge, variant, prog
    if kind == "hutch" then
        local hk = ZeD.ObjectCards and ZeD.ObjectCards.kinds.hutch
        name = (hk and hk.nameOf and hk.nameOf(o)) or moveableName(o, getTextOrNull("ContextMenu_Hutch") or "Hutch")
        local inside = ocall(o, "getAnimalInside")
        local eggs = 0
        for i = 0, (ocall(o, "getMaxNestBox") or 3) do
            local nb = ocall(o, "getNestBox", i)
            eggs = eggs + (nb and (ocall(nb, "getEggsNb") or 0) or 0)
        end
        sub = ZeD.tr("UI_ZeD_Animals_HutchLine", inside and inside:size() or 0, ocall(o, "getMaxAnimals") or 20,
            eggs, math.floor((ocall(o, "getHutchDirt") or 0) + 0.5) .. "%")
        -- which door is open (the Open button beside it opens the card)
        if ocall(o, "isOpen") then badge, variant = ZeD.tr("UI_ZeD_Animals_BadgeDoorOpen"), "positive"
        elseif ocall(o, "isEggHatchDoorOpen") then badge, variant = ZeD.tr("UI_ZeD_Animals_BadgeHatchOpen"), "positive"
        else badge, variant = ZeD.tr("UI_ZeD_Animals_BadgeShut"), "neutral" end
    elseif kind == "trough" then
        name = moveableName(o, getTextOrNull("ContextMenu_FeedingTrough") or "Feeding Trough")
        local cont = ocall(o, "getContainer")
        local wl = ocall(o, "getWater") or 0
        if cont and not cont:getItems():isEmpty() then
            sub = ZeD.tr("UI_ZeD_Animals_TroughFeed", string.format("%.1f", ocall(o, "getCurrentFeedAmount") or 0))
            badge, variant = getText("IGUI_ItemCat_Food"), "positive"
        elseif wl > 0 then
            sub = ZeD.tr("UI_ZeD_Animals_TroughWater", string.format("%.1f", wl), string.format("%.1f", ocall(o, "getMaxWater") or 0))
            badge, variant = getText("IGUI_FeedingTroughUI_Water"), "info"
        else
            sub = ZeD.tr("Fluid_Empty"); badge, variant = getText("Fluid_Empty"), "neutral"
        end
        local linked = ocall(o, "getLinkedAnimals")
        local nLinked = linked and linked:size() or 0
        sub = sub .. " | " .. ZeD.tr(nLinked == 1 and "UI_ZeD_Animals_StructAnimalsOne" or "UI_ZeD_Animals_StructAnimalsMany", nLinked)
    else -- hook
        name = getTextOrNull("ContextMenu_ButcherHook") or "Butcher Hook"
        local a = ocall(o, "getAnimal")
        local sq = o:getSquare()
        local dist = (player and sq) and math.floor(math.sqrt((sq:getX() + 0.5 - player:getX()) ^ 2 + (sq:getY() + 0.5 - player:getY()) ^ 2) + 0.5) or 0
        if a then
            local md = a:getModData()
            local cn = ocall(a, "getCustomName")
            name = name .. " | " .. ((cn and cn ~= "") and cn or (ocall(a, "getFullName") or "?"))
            local parts = {}
            if md["leather"] then parts[#parts + 1] = ZeD.trBare("IGUI_ButcherHook_Leather") end
            local blood = tonumber(md["BloodQty"]) or 0
            if blood > 0 then parts[#parts + 1] = ZeD.tr("UI_ZeD_Animals_HookBlood", string.format("%.1f", blood)) end
            if not md["headless"] then parts[#parts + 1] = ZeD.trBare("IGUI_ButcherHook_Head") end
            if md["parts"] then parts[#parts + 1] = ZeD.trBare("IGUI_ButcherHook_Meat") end
            sub = (#parts > 0 and ZeD.tr("UI_ZeD_Animals_HookLeft", table.concat(parts, " | ")) or ZeD.tr("UI_ZeD_Animals_HookNothingLeft"))
                .. " | " .. ZeD.tr(dist == 1 and "UI_ZeD_Animals_TilesOne" or "UI_ZeD_Animals_TilesMany", dist)
            if ocall(o, "isRemovingBlood") then
                badge, variant = getText("IGUI_health_Bleeding"), "warning"
                prog = ocall(o, "getRemovingBloodProgress") or 0
            else
                badge, variant = ZeD.tr("UI_ZeD_Animals_BadgeOnHook"), "positive"
            end
        else
            sub = ZeD.tr(dist == 1 and "UI_ZeD_Animals_TilesOne" or "UI_ZeD_Animals_TilesMany", dist)
            badge, variant = getText("Fluid_Empty"), "neutral"
        end
    end
    return name, sub, badge, variant, prog
end

local function openStruct(kind, o)
    local player = getSpecificPlayer(0)
    local OC = ZeD.ObjectCards
    if not (player and OC and OC.openNear and o) then return end
    local sq = (kind == "hutch") and (ocall(o, "getEntrySq") or o:getSquare()) or o:getSquare()
    local ok, err = pcall(OC.openNear, player, kind, o, sq)
    if not ok then print("[ZeD] AnimalsTab: open " .. kind .. " failed: " .. tostring(err)) end
end

-- focusId: the ring element for this row (default: animals:struct:<kind>:<idx>)
local function drawStructRow(panel, win, x, y, w, kind, o, idx, player, focusId)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local tm = ZeD.TM
    local h = T.px(STRUCT_H)

    -- hover wash, then the controller's mark, both under the words
    local hovered = A.mouseIn(panel, x, y, w, h)
    if hovered then
        local hv = T.hover
        panel:drawRect(x, y, w, h, hv.a, hv.r, hv.g, hv.b)
        help(panel, "UI_ZeD_Animals_HelpStruct")
    end
    local onFocus = markId(panel, win, focusId or ("animals:struct:" .. kind .. ":" .. tostring(idx)), x, y, w, h)
    local ink = onFocus and T.textOnFocus or T.text
    local inkDim = onFocus and T.textOnFocus or T.textDim

    local name, sub, badge, sev, prog = structInfo(kind, o, player)
    local pad = T.px(AROW_PAD)
    local isz = T.px(22)
    local tex
    if kind == "hook" and ocall(o, "getAnimal") and AD().resolvePortrait then
        tex = getTexture(AD().resolvePortrait(o:getAnimal()))
    else
        tex = ZeD.ObjectCards and ZeD.ObjectCards.spriteIcon(o)
    end
    if tex then panel:drawTextureScaledAspect(tex, x + pad, y + math.floor((h - isz) / 2), isz, isz, 1, 1, 1, 1) end

    -- Open (right): a compact push button; pressing anywhere on the row does the same
    local openLabel = getText("IGUI_Open")
    local bw = M.buttonW(openLabel)
    local bx = x + w - pad - bw
    local rbx, rby, rbw, rbh = M.drawButton(panel, bx, y, bw, h, openLabel, "default", false, nil,
        { compact = true, hover = hovered })
    local rect = { x = rbx, y = rby, w = rbw, h = rbh }

    -- the tag, and the bleed bar for a hook
    local rx = bx - T.px(8)
    if prog then
        local pw = T.px(60)
        rx = rx - pw
        local ph = A.fillBarCompactH()
        -- (the bleed is a timed action's progress: smooth, as the hook's card draws it)
        A.drawSmoothBar(panel, rx, y + math.floor((h - ph) / 2), pw, math.max(0, math.min(1, prog)), false, nil, ph)
        rx = rx - T.px(6)
    end
    if badge then
        local tw = tagWidth(badge, sevColor(T, sev) ~= nil)
        rx = rx - tw
        drawTag(panel, rx, tagY(y, h), badge, sev)
        rx = rx - T.px(8)
    end
    local nx = x + pad + isz + T.px(8)
    local f2, f5 = T.fontF2, T.fontF5
    local ny = y + math.floor((h - tm:getFontHeight(f2) - tm:getFontHeight(f5)) / 2)
    panel:drawText(A.truncateText(name, f2, rx - nx), nx, ny, ink.r, ink.g, ink.b, ink.a or 1, f2)
    panel:drawText(A.truncateText(tc(sub), f5, rx - nx), nx, ny + tm:getFontHeight(f2), inkDim.r, inkDim.g, inkDim.b, inkDim.a or 1, f5)
    A.drawDividerH(panel, x, y + h - T.px(1), w, false)
    win._animalsStructZones[#win._animalsStructZones + 1] = { x = x, y = y, w = w, h = h, kind = kind, obj = o, idx = idx, btn = rect }
    return h
end

-- the zone's hutches and troughs, pinned under the info band
local function drawZoneStructs(panel, win, x, y, w, summary, player)
    local y0 = y
    local idx = 0
    for _, g in ipairs({ { kind = "hutch", label = "UI_ZeD_Animals_SecHutches", list = summary.hutches or {} },
                         { kind = "trough", label = "UI_ZeD_Animals_SecTroughs", list = summary.troughs or {} } }) do
        if #g.list > 0 then
            y = y + catRow(panel, win, x, y, w, ZeD.tr(g.label), #g.list, true, true, nil, nil)
            for _, o in ipairs(g.list) do
                idx = idx + 1
                y = y + drawStructRow(panel, win, x, y, w, g.kind, o, idx, player)
            end
        end
    end
    return y - y0
end

-- butcher hooks around you (scanned every two seconds)
-- The 41 x 41 walk is spread over frames. The first scan
-- runs in one frame (there is nothing to show before it); each later one walks
-- HOOK_SCAN_ROWS rows a frame while the last list stays up, and the new list
-- replaces it when the walk is done. Each hook's distance is read once before the
-- sort, not in every comparison.
local HOOK_SCAN_R = 20
local HOOK_SCAN_ROWS = 6          -- rows of the walk a frame: 41 rows in 7 frames
local HOOK_SWEEP_STALE_MS = 1000  -- a walk not stepped for this long (the view shut) starts over
local function hookSweepRows(sw, rows)
    local cell = getCell()
    local last = math.min(sw.y + rows - 1, sw.cy + HOOK_SCAN_R)
    local list = sw.list
    for yy = sw.y, last do
        for xx = sw.cx - HOOK_SCAN_R, sw.cx + HOOK_SCAN_R do
            local sq = cell:getGridSquare(xx, yy, sw.z)
            if sq then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do
                    local o = objs:get(i)
                    if instanceof(o, "IsoButcherHook") then list[#list + 1] = o end
                end
            end
        end
    end
    sw.y = last + 1
    return sw.y > sw.cy + HOOK_SCAN_R
end

local function hooksNear(win, player)
    local now = getTimestampMs()
    local c = win._animalsHookScan
    if c and now - c.t < 2000 then return c.list end
    local list = {}
    local sq0 = player and player:getCurrentSquare()
    if sq0 then
        local sw = win._animalsHookSweep
        if not sw or sw.z ~= sq0:getZ() or now - sw.tStep > HOOK_SWEEP_STALE_MS then
            sw = { cx = sq0:getX(), cy = sq0:getY(), z = sq0:getZ(), y = sq0:getY() - HOOK_SCAN_R, list = {} }
            win._animalsHookSweep = sw
        end
        sw.tStep = now
        if not hookSweepRows(sw, c and HOOK_SCAN_ROWS or (HOOK_SCAN_R * 2 + 1)) then return c.list end
        list = sw.list
    end
    win._animalsHookSweep = nil
    -- nearest first (a hook taken down while the walk ran drops out)
    if player then
        local px, py = player:getX(), player:getY()
        local keyed = {}
        for _, o in ipairs(list) do
            local s = o:getSquare()
            if s then keyed[#keyed + 1] = { o = o, d = (s:getX() - px) ^ 2 + (s:getY() - py) ^ 2 } end
        end
        table.sort(keyed, function(a, b) return a.d < b.d end)
        list = {}
        for i = 1, #keyed do list[i] = keyed[i].o end
    end
    win._animalsHookScan = { t = now, list = list }
    return list
end

local function drawHooks(panel, win, x, y, w, player)
    local hooks = hooksNear(win, player)
    if #hooks == 0 then return 0 end
    local y0 = y
    y = y + catRow(panel, win, x, y, w, ZeD.tr("UI_ZeD_Animals_SecHooks"), #hooks, true, true, nil, nil)
    for i, o in ipairs(hooks) do
        if i > 4 then break end   -- pinned: the four nearest in reading order
        y = y + drawStructRow(panel, win, x, y, w, "hook", o, i, player)
    end
    return y - y0
end

-- "In hutch" on an animal: a row that opens its hutch
local function drawInHutchRow(panel, win, x, y, w, animal, player)
    local hutch = ocall(animal, "getHutch")
    if not hutch then return 0 end
    win._animalsStructZones = {}
    local hh = drawStructRow(panel, win, x, y, w, "hutch", hutch, 1, player, "animals:hutchlink")
    win._animalsHutchLink = win._animalsStructZones[1]
    win._animalsStructZones = {}
    return hh
end

-- a section head across the detail's full width (its sections sit inside the tab pad)
local function detailHead(panel, x, y, w, text)
    local M = ZeD.Molecules
    local pad = M.getTabPad()
    return M.drawSectionHeader(panel, x, y, w + pad, text, nil, true, false, nil, nil, pad, nil, true)
end

-- ============================================================================
-- GENOME (debug: animal cheats only, as vanilla's Modify Genome)
-- Each gene's two alleles: value (and what passes to offspring), which one is
-- used, dominant, disorder. Pick an allele, then -/+ 0.05, Dominant, Switch
-- (which allele is used) or Disorder (cycles vanilla's list).
-- ============================================================================
local GENE_H = 24

-- the engine names genes in lower case ("maxweight"): vanilla's genes, worded;
-- a name not in the table gets spaced and capitalised by geneLabel below
local GENE_LABELS = {
    maxsize = "Max size", maxmilk = "Max milk", meatratio = "Meat ratio", agetogrow = "Age to grow",
    maxwool = "Max wool", maxweight = "Max weight", lifeexpectancy = "Life expectancy", resistance = "Resistance",
    strength = "Strength", fertility = "Fertility", aggressiveness = "Aggressiveness",
    thirstresistance = "Thirst resistance", hungerresistance = "Hunger resistance", milkinc = "Milk rate",
    woolinc = "Wool rate", eggsize = "Egg size", stress = "Stress", eggclutch = "Egg clutch",
}

local function geneLabel(n)
    n = tostring(n or "?")
    if GENE_LABELS[string.lower(n)] then return GENE_LABELS[string.lower(n)] end
    local s = string.gsub(n, "(%u)", " %1")
    s = string.lower(s)
    return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2)
end

local function genomeChanged(animal, disorder)
    if disorder and AnimalGene and AnimalGene.checkGeneticDisorder then pcall(AnimalGene.checkGeneticDisorder, animal) end
    if isClient() and sendAnimalGenome then pcall(sendAnimalGenome, animal) end
end

local function drawGenomeSection(panel, win, x, y, w, animal)
    if not (AnimalContextMenu and AnimalContextMenu.cheat) then return 0 end
    local list = ocall(animal, "getFullGenomeList")
    if not list or list:size() == 0 then return 0 end
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local tm = ZeD.TM
    local y0 = y
    win._animalsGenomeZones = {}
    local sel = win._animalsGenomeSel
    -- header: the section head, and a tag saying this is the cheat panel
    local hdrH = detailHead(panel, x, y, w, ZeD.tr("UI_ZeD_Animals_Genome"))
    local cheat = ZeD.tr("UI_ZeD_Animals_AnimalCheats")
    drawTag(panel, x + w - tagWidth(cheat, true) - T.px(6), tagY(y, hdrH), cheat, "info")
    y = y + hdrH + T.px(2)
    local colN = T.px(110)
    local colA = math.floor((w - colN - T.px(90)) / 2)
    local f3 = T.fontF3
    for gi = 0, list:size() - 1 do
        local gene = list:get(gi)
        local h = T.px(GENE_H)
        panel:drawText(geneLabel(ocall(gene, "getName")), x + T.px(2), y + math.floor((h - tm:getFontHeight(T.fontF2)) / 2), T.text.r, T.text.g, T.text.b, T.text.a or 1, T.fontF2)
        local dis = nil
        for k = 1, 2 do
            local al = ocall(gene, k == 1 and "getAllele1" or "getAllele2")
            if al then
                local ax = x + colN + (k - 1) * colA
                local cw, cy, ch = colA - T.px(6), y + T.px(2), h - T.px(4)
                local isSel = sel and sel.gene == gi and sel.allele == k
                -- the picked allele: the one accent wash; the controller's mark on top of it
                if isSel then
                    local ac = T.accent
                    panel:drawRect(ax, cy, cw, ch, T.selectionA, ac.r, ac.g, ac.b)
                end
                local onFocus = markId(panel, win, "animals:genome:" .. gi .. ":" .. k, ax, cy, cw, ch)
                local cur = ocall(al, "getCurrentValue") or 0
                local tr = ocall(al, "getTrueRatioValue") or 0
                local v = (tr > 0) and string.format("%.2f (%.2f)", tr, cur) or string.format("%.2f", cur)
                local used = ocall(al, "isUsed") == true
                local dy = y + math.floor((h - T.px(6)) / 2)
                if used then A.drawStatusDot(panel, ax + T.px(4), dy, T.positive, T.px(6))
                else A.drawStatusHollow(panel, ax + T.px(4), dy, T.textDim, T.px(6)) end
                local vc = onFocus and T.textOnFocus or (used and T.text or T.textDim)
                panel:drawText(v, ax + T.px(14), y + math.floor((h - tm:getFontHeight(f3)) / 2), vc.r, vc.g, vc.b, vc.a or 1, f3)
                if ocall(al, "isDominant") then
                    local dx = ax + T.px(14) + tm:MeasureStringX(f3, v) + T.px(6)
                    drawTag(panel, dx, tagY(y, h), "D", nil)
                end
                local d = ocall(al, "getGeneticDisorder")
                if d and d ~= "" then dis = d end
                win._animalsGenomeZones[#win._animalsGenomeZones + 1] = { x = ax, y = y, w = colA - T.px(6), h = h, gene = gi, allele = k, al = al, g = gene }
            end
        end
        if dis then
            drawTag(panel, x + w - tagWidth(dis, true) - T.px(6), tagY(y, h), dis, "danger")
        end
        A.drawDividerH(panel, x, y + h - T.px(1), w, false)
        y = y + h
    end
    -- controls (act on the picked allele)
    y = y + T.px(6)
    win._animalsGenomeBtns = {}
    local bx = x
    local selAl = nil
    if sel then
        for _, z in ipairs(win._animalsGenomeZones) do
            if z.gene == sel.gene and z.allele == sel.allele then selAl = z end
        end
    end
    local bh = T.buttonH
    for _, b in ipairs({ { id = "minus", label = "-0.05" }, { id = "plus", label = "+0.05" },
                         { id = "dominant", label = ZeD.tr("UI_ZeD_Animals_GeneDominant") },
                         { id = "switch", label = ZeD.tr("UI_ZeD_Animals_GeneSwitch") },
                         { id = "disorder", label = ZeD.tr("UI_ZeD_Animals_GeneDisorder") } }) do
        local bw = M.buttonW(b.label)
        if bx + bw > x + w and bx > x then bx = x; y = y + bh + T.px(4) end
        -- no allele picked: the controls have nothing to act on
        M.drawButton(panel, bx, y, bw, bh, b.label, "default", false, nil, {
            hover = A.mouseIn(panel, bx, y, bw, bh), disabled = (selAl == nil), win = win,
            focus = focusFor(win, "animals:genomebtn:" .. b.id) })
        win._animalsGenomeBtns[#win._animalsGenomeBtns + 1] = { x = bx, y = y, w = bw, h = bh, id = b.id }
        bx = bx + bw + T.px(8)
    end
    win._animalsGenomeSelAl = selAl
    y = y + bh + T.px(4)
    return y - y0
end

local function genomeAct(win, id, animal)
    local z = win._animalsGenomeSelAl
    if not (z and animal) then return end
    local al, gene = z.al, z.g
    if id == "minus" or id == "plus" then
        local v = (ocall(al, "getCurrentValue") or 0) + (id == "plus" and 0.05 or -0.05)
        pcall(al.setCurrentValue, al, math.max(0, v))
        genomeChanged(animal, false)
    elseif id == "dominant" then
        pcall(al.setDominant, al, not (ocall(al, "isDominant") == true))
        genomeChanged(animal, false)
    elseif id == "switch" then
        local a1, a2 = ocall(gene, "getAllele1"), ocall(gene, "getAllele2")
        if a1 and a2 then
            local u1 = ocall(a1, "isUsed") == true
            pcall(a1.setUsed, a1, not u1)
            pcall(a2.setUsed, a2, u1)
            genomeChanged(animal, false)
        end
    elseif id == "disorder" then
        local listD = AnimalGenomeDefinitions and AnimalGenomeDefinitions.getGeneticDisorderList and AnimalGenomeDefinitions.getGeneticDisorderList()
        if not listD then return end
        local names = {}
        if type(listD) == "table" then
            for _, v in ipairs(listD) do names[#names + 1] = tostring(v) end
        elseif listD.size then
            for i = 0, listD:size() - 1 do names[#names + 1] = tostring(listD:get(i)) end
        end
        local cur = ocall(al, "getGeneticDisorder")
        local nextD = names[1]
        if cur and cur ~= "" then
            nextD = nil
            for i, n in ipairs(names) do if n == cur then nextD = names[i + 1] end end
        end
        pcall(al.setGeneticDisorder, al, nextD)
        genomeChanged(animal, true)
    end
end

-- ============================================================================
-- O-ZNVW — RANCH ZONE DETAIL ORGANISM
-- Composes: zone info band (pinned) + roster section header with sort
-- button + scrollable animal roster rows.
-- ============================================================================

-- The zone lit on the ground while its view shows. The zone is looked up (a walk
-- over every zone) when the view's zone changes and then at most every
-- SORT_CACHE_MS, not every frame, and lit again only when its id changed or
-- anything else (the game's zone windows and context menu, ZeD's Back and zone
-- create) has turned the highlight off or changed it. (One difference from
-- looking it up every frame: a zone remade under the same name is lit within
-- SORT_CACHE_MS, not the same frame; the view steps back when its zone goes, so
-- it is not met.)
local function zoneLit(player, id)
    if not player:isSeeDesignationZone() then return false end
    local sel = player:getSelectedZonesForHighlight()
    return sel ~= nil and sel:size() == 1 and sel:get(0) == id
end

local function lightZone(player, id)
    player:setSeeDesignationZone(true)
    player:resetSelectedZonesForHighlight()
    player:addSelectedZoneForHighlight(id)
end

local function highlightZone(win, player, zoneName)
    if not player then return end
    local now = getTimestampMs and getTimestampMs() or 0
    local h = win._animalsZoneLit
    local same = h ~= nil and h.player == player and h.name == zoneName
    if same and now - h.t < SORT_CACHE_MS then
        if zoneLit(player, h.id) then return end
        -- turned off: light it again, the zone checked as the lookup would
        local z = h.zone
        if z:isStillStreamed() and z:getName() == zoneName then
            lightZone(player, h.id)
            return
        end
    end
    local zoneObj = getZoneByName(zoneName)
    if not zoneObj then
        win._animalsZoneLit = nil
        return
    end
    local id = zoneObj:getId()
    if not (same and h.id == id and zoneLit(player, id)) then lightZone(player, id) end
    win._animalsZoneLit = { player = player, name = zoneName, zone = zoneObj, id = id, t = now }
end

local function renderRanchZone(panel, win, x, y, w, h)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local state = getState(win)
    local zs = getZoneViewState(win)
    local ad = AD()
    local ap = AP()
    local tm = ZeD.TM

    if not ap.isReady() then ap.refreshCache() end

    -- Highlight this zone on the ground
    local player = getSpecificPlayer(0)
    highlightZone(win, player, state.zoneName)

    local summary = state.zoneName and ap.getZoneSummary(state.zoneName)
    if not summary then
        -- Zone no longer exists — go back to overview
        navigateBack(win)
        return
    end

    local pad = M.getTabPad()
    local scrollW = T.sp.scrollbarW

    -- Reset click zones
    win._animalsRosterZones = {}
    win._animalsSortZone = nil

    -- ── ZONE INFO BAND (pinned at top) ──
    local bandH = drawZoneInfoBand(panel, win, x, y, w, summary)

    -- ── HUTCHES / FEEDING TROUGHS (pinned below the band) ──
    win._animalsStructZones = {}
    local structH = drawZoneStructs(panel, win, x, y + bandH, w, summary, player)

    -- ── ROSTER SECTION HEADER (pinned below band) ──
    local animals = ap.getAnimalsInZone(state.zoneName)
    local sortedAnimals = sortedRoster(zs, animals, zs.sortMode, state.zoneName)
    local rosterCount = #sortedAnimals

    local secY = y + bandH + structH
    local hdrH = T.buttonH
    M.drawCategoryRow(panel, x, secY, w, getText("IGUI_SearchMode_Categories_Animals"), rosterCount, true,
        { noArrow = true, h = hdrH })

    -- Sort order: a compact push button at the head's right; pressing it cycles the order
    local sortLabel = ZeD.tr(SORT_LABELS[zs.sortMode] or "IGUI_Name")
    local sortText = ZeD.tr("UI_ZeD_Animals_SortBy", sortLabel)
    local sortW = M.buttonW(sortText)
    local sortX = x + w - pad - sortW
    local sbx, sby, sbw, sbh = M.drawButton(panel, sortX, secY, sortW, hdrH, sortText, "default", false, nil, {
        compact = true, hover = A.mouseIn(panel, sortX, secY, sortW, hdrH), win = win,
        focus = focusFor(win, "animals:sort"), help = ZeD.tr("UI_ZeD_Animals_HelpSort") })
    win._animalsSortZone = { x = sbx, y = sby, w = sbw, h = sbh }

    -- Help: the game's first-time zone note on request, in its own words (WorldRoutes.zoneHelp); the
    -- help line says its opening sentence. The note never comes up on its own under ZeD's window.
    win._animalsZoneHelpZone = nil
    local WR = ZeD.WorldRoutes
    if WR and WR.zoneHelp then
        local hx = sortX - T.px(6) - hdrH
        local hHover = A.mouseIn(panel, hx, secY, hdrH, hdrH)
        local hOn = isOn(win, "animals:zonehelp")
        local lead = WR.zoneNoteLead and WR.zoneNoteLead() or nil
        local hzx, hzy, hzw, hzh = M.drawIconButton(panel, hx, secY, hdrH, "help", {
            hover = hHover, win = win, focus = focusFor(win, "animals:zonehelp"),
            hint = ZeD.tr("UI_ZeD_Wheel_Help"), id = "animals:zonehelp" })
        if (hHover or hOn) and lead and ZeD.Help and ZeD.Help.set then ZeD.Help.set(panel, lead) end
        win._animalsZoneHelpZone = { x = hzx, y = hzy, w = hzw, h = hzh }
    end

    -- ── SCROLLABLE ROSTER ──
    local rosterTop = secY + hdrH
    local rosterH = h - (rosterTop - y)
    if rosterH <= 0 then return end

    local totalContentH = rosterCount * T.px(AROW_H)
    local maxScroll = math.max(0, totalContentH - rosterH)

    -- The controller's row: keep it in the viewport (it is drawn marked below).
    local gpFocusAnimal = nil
    do
        local fe = liveEl(win)
        if fe and fe.isRoster then gpFocusAnimal = fe.animal end
    end
    if gpFocusAnimal then
        local idx = nil
        for i = 1, #sortedAnimals do
            if sortedAnimals[i] == gpFocusAnimal then idx = i; break end
        end
        if idx then
            local itemTop = (idx - 1) * T.px(AROW_H)
            local itemBot = itemTop + T.px(AROW_H)
            if itemTop < zs.scrollY then
                zs.scrollY = itemTop
            elseif itemBot > zs.scrollY + rosterH then
                zs.scrollY = itemBot - rosterH
            end
        end
    end
    zs.scrollY = math.max(0, math.min(zs.scrollY, maxScroll))

    local needsScroll = totalContentH > rosterH
    local contentW = needsScroll and (w - scrollW) or w

    panel:setStencilRect(x, rosterTop, contentW, rosterH)

    local player = getSpecificPlayer(0)
    local mx = panel:getMouseX()
    local my = panel:getMouseY()
    local rowY = rosterTop - zs.scrollY
    local sel = zoneSelection(win, state.zoneName)

    for _, animal in ipairs(sortedAnimals) do
        if rowY + T.px(AROW_H) > rosterTop and rowY < rosterTop + rosterH then
            local isHovered = A.mouseIn(panel, x, rowY, contentW, T.px(AROW_H))
                and my >= rosterTop and my < rosterTop + rosterH
            -- the controller's mark goes under the row's words
            local onFocus = false
            if animal == gpFocusAnimal then
                onFocus = ZeD.Focus.mark(panel, x + pad, rowY, contentW - pad * 2, T.px(AROW_H), focusOpts(win))
            end
            local _, cbr = drawAnimalRow(panel, x + pad, rowY, contentW - pad * 2, animalRowModel(zs, animal, player),
                isHovered, onFocus, QK().isSelected(sel, animal))
            if isHovered then help(panel, cbr.hover and "UI_ZeD_Animals_HelpRowCheck" or "UI_ZeD_Animals_HelpAnimalRow") end
            table.insert(win._animalsRosterZones, {
                x = x, y = rowY, w = contentW, h = T.px(AROW_H), animal = animal, cb = cbr
            })
        end
        rowY = rowY + T.px(AROW_H)
    end

    panel:clearStencilRect()

    if needsScroll then
        ZeD.Molecules.scrollBar(panel, win, "an:roster", x + contentW + T.px(2), rosterTop, scrollW - T.px(2), rosterH,
            zs.scrollY, totalContentH, function(v) zs.scrollY = v end, { step = T.px(AROW_H) })
    end

    win._animalsRosterScroll = {
        top = rosterTop, h = rosterH, maxScroll = maxScroll, needsScroll = needsScroll
    }
end

-- ============================================================================
-- M-AHEAD — ANIMAL HEADER
-- 48px portrait + name + breed/species/sex + age/weight + condition tags.
-- Returns: headerH consumed.
-- ============================================================================

local function drawAnimalHeader(panel, x, y, w, animal, player)
    local T = ZeD.T
    local A = ZeD.Atoms
    local ad = AD()
    local tm = ZeD.TM
    local pad = T.px(AHEAD_PAD)
    local curY = y + pad

    -- Portrait (48px, vertically offset from top)
    local portraitPath = ad.resolvePortrait(animal)
    local tex = getTexture(portraitPath)
    if tex then
        panel:drawTextureScaledAspect(tex, x + pad, curY, T.px(AHEAD_ICON_SZ), T.px(AHEAD_ICON_SZ), 1.0, 1, 1, 1)
    end

    -- Text block right of portrait
    local textX = x + pad + T.px(AHEAD_ICON_SZ) + pad + T.px(2)

    -- Name (F4, the heading)
    local nameFont = T.fontF4
    local name = ad.getDisplayName(animal)
    panel:drawText(name, textX, curY, T.textHead.r, T.textHead.g, T.textHead.b, T.textHead.a or 1, nameFont)
    curY = curY + tm:getFontHeight(nameFont) + T.px(2)

    -- Breed + Species + Sex (F2, textDim)
    local secFont = T.fontF2
    local atype = ad.getAnimalType(animal)
    local species = getText("IGUI_AnimalType_" .. atype) or atype
    local breed = ad.getBreedName(animal)
    local sex = ad.isFemale(animal) and getText("IGUI_Animal_Female") or getText("IGUI_Animal_Male")
    if ad.isBaby(animal) then sex = getText("IGUI_Animal_Baby") end
    local idLine = ""
    if breed and breed ~= "" then idLine = breed .. " " end
    idLine = idLine .. species .. ", " .. sex
    panel:drawText(idLine, textX, curY, T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, secFont)
    curY = curY + tm:getFontHeight(secFont) + T.px(2)

    -- Age + Weight (F5, textDim)
    local microFont = T.fontF5
    local age = ad.getAgeText(animal, player)
    local weight = ad.getWeight(animal)
    local infoLine = ""
    if age and age ~= "" then infoLine = age end
    if ad.canSee(player, "weight_rough") and weight > 0 then
        if infoLine ~= "" then infoLine = infoLine .. "  |  " end
        infoLine = infoLine .. ZeD.tr("UI_ZeD_Animals_WeightKg", string.format("%.1f", weight))
    end
    if infoLine ~= "" then
        panel:drawText(infoLine, textX, curY, T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, microFont)
        curY = curY + tm:getFontHeight(microFont) + T.px(4)
    end

    -- Condition tags (a row, wrapping at the right edge)
    local tags = ad.getConditionTags(animal, player)
    if #tags > 0 then
        local bx = textX
        for _, tag in ipairs(tags) do
            local tw = tagWidth(tag.label, sevColor(T, tag.sev) ~= nil)
            if bx > textX and bx + tw > x + w - pad then
                bx = textX
                curY = curY + T.px(16) + T.px(4)
            end
            drawTag(panel, bx, curY, tag.label, tag.sev)
            bx = bx + tw + T.px(4)
        end
        curY = curY + T.px(16) + T.px(4)
    end

    local headerH = math.max(T.px(AHEAD_ICON_SZ) + pad * 2, (curY - y) + pad)

    -- The pane head's bottom: a structure line
    A.drawDividerH(panel, x, y + headerH - T.px(1), w, true)

    return headerH
end

-- ============================================================================
-- M-AVIT — VITAL ROW
-- Label (left) + text/numeric value (middle) + framed fill bar (right).
-- Text descriptor at Lv0, numeric at Lv3+. Bar colour by threshold.
-- Returns: VITAL_ROW_H consumed.
-- ============================================================================

local function drawVitalRow(panel, x, y, w, label, value, textDesc, numericDesc, canSeeNum, fillRatio, fillColor)
    local T = ZeD.T
    local A = ZeD.Atoms
    local tm = ZeD.TM

    local lblFont = T.fontF1
    local valFont = T.fontF3
    local rowH = T.px(VITAL_ROW_H)
    local valY = y + math.floor((rowH - tm:getFontHeight(valFont)) / 2)

    -- Label (left, sentence case)
    local tc2 = T.textSec
    panel:drawText(tc(label), x, valY, tc2.r, tc2.g, tc2.b, tc2.a or 1, lblFont)

    -- Fill bar (right-aligned): the framed strip, ten segments. Its help line is the row's own reading
    -- ("Hunger Peckish" until the skill shows the number): no figure the game keeps back
    local barW = T.px(VITAL_BAR_W)
    local barX = x + w - barW
    local barH = T.fillBarH
    local displayText = canSeeNum and numericDesc or textDesc
    if A.drawSegFill(panel, barX, y + math.floor((rowH - barH) / 2), barW, barH, A.FILL_SEGS,
            A.fillSegsLit(fillRatio or 0), fillColor or T.accent) and displayText and displayText ~= "" then
        ZeD.Help.set(panel, ZeD.tr("UI_ZeD_Bar_Help", tc(label), displayText))
    end

    -- Value text (between label and bar)
    if displayText and displayText ~= "" then
        local maxValW = barX - x - T.px(80) - T.px(8)  -- space between label end and bar
        local valW = tm:MeasureStringX(valFont, displayText)
        if valW > maxValW and maxValW > T.px(20) then
            -- Truncate with ellipsis
            while valW > maxValW and #displayText > 1 do
                displayText = string.sub(displayText, 1, #displayText - 1)
                valW = tm:MeasureStringX(valFont, displayText .. "...")
            end
            displayText = displayText .. "..."
        end
        local valX = barX - valW - T.px(8)
        panel:drawText(displayText, valX, valY, T.text.r, T.text.g, T.text.b, T.text.a or 1, valFont)
    end

    return rowH
end

-- A label / value row with no bar: the value at 100u, with a status square before it
-- when the value carries a status (the number stays in the default text colour).
-- Returns the row height and the x the value ends at.
local function drawTextRow(panel, x, y, label, value, mark)
    local T = ZeD.T
    local A = ZeD.Atoms
    local tm = ZeD.TM
    local rowH = T.px(VITAL_ROW_H)
    local valFont = T.fontF3
    local ty = y + math.floor((rowH - tm:getFontHeight(valFont)) / 2)
    local lc = T.textSec
    panel:drawText(tc(label), x, ty, lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)
    local vx = x + T.px(100)
    if mark then
        A.drawStatusDot(panel, vx, y + math.floor((rowH - T.px(6)) / 2), mark, T.px(6))
        vx = vx + T.px(12)
    end
    panel:drawText(value, vx, ty, T.text.r, T.text.g, T.text.b, T.text.a or 1, valFont)
    return rowH, vx + tm:MeasureStringX(valFont, value)
end

-- ============================================================================
-- VITALS SECTION — Health, Hunger, Thirst, Stress + stress sources
-- ============================================================================

local function drawVitalsSection(panel, x, y, w, animal, player)
    local T = ZeD.T
    local A = ZeD.Atoms
    local ad = AD()
    local si = SI()
    local tm = ZeD.TM
    local curY = y

    -- Section header
    curY = curY + detailHead(panel, x, curY, w, ZeD.tr("UI_ZeD_Animals_HdrVitals")) + T.px(2)

    local canSeeNum = ad.canSee(player, "health_num")

    -- Health: high = good
    local health = ad.getHealth(animal)
    local healthText = ad.getHealthText(animal, player)
    local healthNum = tostring(math.floor(health)) .. "%"
    local healthRatio = health / 100
    curY = curY + drawVitalRow(panel, x, curY, w, getText("IGUI_HealthTooltip"), health,
        healthText, healthNum, canSeeNum, healthRatio, dotColorForValue(T, health))

    -- Hunger: high = hungry (BAD) — invert for display
    local hunger = ad.getHunger(animal)
    local hungerDisplay = 100 - hunger  -- 100=full, 0=starving
    local hungerText = hunger < 20 and getText("IGUI_Animal_WellFed") or (hunger < 50 and getText("Moodles_Hungry_lvl1")
        or (hunger < 80 and getText("Moodles_Hungry_lvl2") or getText("IGUI_Animal_Starving")))
    local hungerNum = tostring(math.floor(hungerDisplay)) .. "%"
    curY = curY + drawVitalRow(panel, x, curY, w, getText("IGUI_StatsAndBody_Hunger"), hungerDisplay,
        hungerText, hungerNum, canSeeNum, hungerDisplay / 100, dotColorForValue(T, hungerDisplay))

    -- Thirst: high = thirsty (BAD) — invert for display
    local thirst = ad.getThirst(animal)
    local thirstDisplay = 100 - thirst
    local thirstText = thirst < 20 and ZeD.tr("UI_ZeD_Animals_ThirstHydrated") or (thirst < 50 and ZeD.tr("UI_ZeD_Animals_ThirstParched")
        or (thirst < 80 and getText("IGUI_Animal_Thirsty") or ZeD.tr("UI_ZeD_Animals_ThirstDehydrated")))
    local thirstNum = tostring(math.floor(thirstDisplay)) .. "%"
    curY = curY + drawVitalRow(panel, x, curY, w, getText("IGUI_StatsAndBody_Thirst"), thirstDisplay,
        thirstText, thirstNum, canSeeNum, thirstDisplay / 100, dotColorForValue(T, thirstDisplay))

    -- Stress: high = stressed (BAD) — invert for display
    local stress = ad.getStress(animal)
    local stressDisplay = 100 - stress
    local stressText = ad.getStressText(animal, player)
    local stressNum = tostring(math.floor(stressDisplay)) .. "%"
    curY = curY + drawVitalRow(panel, x, curY, w, getText("IGUI_StatsAndBody_Stress"), stressDisplay,
        stressText, stressNum, canSeeNum, stressDisplay / 100, dotColorForValue(T, stressDisplay))

    -- Stress sources line (inferred)
    if stress > 10 then
        local sources = si.inferSources(animal, player)
        if #sources > 0 then
            local srcFont = T.fontF5
            local srcText = "\226\134\146 " .. table.concat(sources, ", ")
            panel:drawText(srcText, x + T.px(4), curY,
                T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, srcFont)
            curY = curY + tm:getFontHeight(srcFont) + T.px(2)
        end
    end

    return curY - y
end

-- ============================================================================
-- M-APROD — PRODUCTION SECTION (Lv5+)
-- Milk, Wool, Eggs — only rows relevant to this animal's species.
-- ============================================================================

local function drawProductionSection(panel, x, y, w, animal, player)
    local T = ZeD.T
    local A = ZeD.Atoms
    local ad = AD()
    local tm = ZeD.TM

    if not ad.canSee(player, "production_state") then return 0 end

    local curY = y
    local hasContent = false

    -- Check if animal has any production data worth showing
    local maxMilk = ad.getMaxMilk(animal)
    local maxWool = ad.getMaxWool(animal)
    local eggsPerDay = ad.getEggsPerDay(animal)
    local isLayingNow = ad.isLaying(animal)

    if maxMilk <= 0 and maxWool <= 0 and eggsPerDay <= 0 and not isLayingNow then
        return 0  -- no production data — skip section entirely
    end

    -- Section header
    curY = curY + detailHead(panel, x, curY, w, ZeD.tr("UI_ZeD_Animals_HdrProduction")) + T.px(2)

    -- Milk row
    if maxMilk > 0 then
        local milkQty = ad.getMilkQuantity(animal)
        local milkRatio = maxMilk > 0 and (milkQty / maxMilk) or 0
        local milkText = ZeD.tr("UI_ZeD_Animals_MilkAmount", math.floor(milkQty), math.floor(maxMilk))
        local milkColor = ad.isUdderUrgent(animal) and T.danger or T.positive
        curY = curY + drawVitalRow(panel, x, curY, w, getText("ContextMenu_FoodType_Milk"), milkQty,
            milkText, milkText, true, milkRatio, milkColor)
        hasContent = true
    end

    -- Wool row
    if maxWool > 0 then
        local woolQty = ad.getWoolQuantity(animal)
        local woolRatio = maxWool > 0 and (woolQty / maxWool) or 0
        local woolText = string.format("%d/%d", math.floor(woolQty), math.floor(maxWool))
        curY = curY + drawVitalRow(panel, x, curY, w, getText("IGUI_Animal_Wool"), woolQty,
            woolText, woolText, true, woolRatio, T.positive)
        hasContent = true
    end

    -- Eggs row (text only, no bar)
    if eggsPerDay > 0 then
        local eggText = ZeD.tr("UI_ZeD_Animals_PerDay", string.format("%.1f", eggsPerDay))
        local rowH, endX = drawTextRow(panel, x, curY, ZeD.tr("UI_ZeD_Animals_Eggs"), eggText, nil)

        -- Laying tag
        if isLayingNow then
            drawTag(panel, endX + T.px(8), tagY(curY, rowH), ZeD.tr("UI_ZeD_Animals_TagLaying"), "positive")
        end
        curY = curY + rowH
        hasContent = true
    end

    -- Last milked (Lv9)
    if ad.canSee(player, "last_milked") then
        local lastMilked = ad.getLastMilkedHours(animal)
        if lastMilked then
            local hoursAgo = math.floor(lastMilked)
            curY = curY + drawTextRow(panel, x, curY, ZeD.tr("UI_ZeD_Animals_LastMilked"),
                ZeD.tr("UI_ZeD_Animals_HoursAgo", hoursAgo), nil)
        end
    end

    return hasContent and (curY - y) or 0
end

-- ============================================================================
-- M-ABREED — BREEDING SECTION (Lv3+)
-- Pregnancy, mating season, acceptance, mother/baby relationships.
-- ============================================================================

local function drawBreedingSection(panel, x, y, w, animal, player)
    local T = ZeD.T
    local A = ZeD.Atoms
    local ad = AD()
    local tm = ZeD.TM

    if not ad.canSee(player, "pregnancy_yn") then return 0 end
    if ad.isBaby(animal) then return 0 end  -- babies don't breed

    local curY = y
    local hasContent = false

    -- Section header
    curY = curY + detailHead(panel, x, curY, w, ZeD.tr("UI_ZeD_Animals_HdrBreeding")) + T.px(2)

    -- Pregnancy
    local isPregnant = ad.isPregnant(animal)
    if isPregnant then
        local pregText = getText("IGUI_Animal_Pregnant")
        if ad.canSee(player, "pregnancy_bar") then
            local current, total = ad.getPregnancyProgress(animal)
            local ratio = total > 0 and (current / total) or 0
            pregText = ZeD.tr("UI_ZeD_Animals_PregnantPct", math.floor(ratio * 100) .. "%")
            curY = curY + drawVitalRow(panel, x, curY, w, ZeD.tr("UI_ZeD_Animals_Pregnancy"), 0,
                pregText, pregText, true, ratio, T.info)
        else
            curY = curY + drawTextRow(panel, x, curY, ZeD.tr("UI_ZeD_Animals_Pregnancy"), getText("UI_Yes"), T.info)
        end
        hasContent = true
    end

    -- Mating season (Lv7)
    if ad.canSee(player, "mating_calendar") then
        local hasSeason = ad.haveMatingSeason(animal)
        if hasSeason then
            local inSeason = ad.isInMatingSeason(animal)
            curY = curY + drawTextRow(panel, x, curY, ZeD.tr("UI_ZeD_Animals_Mating"),
                ZeD.tr(inSeason and "UI_ZeD_Animals_InSeason" or "UI_ZeD_Animals_OffSeason"), inSeason and T.positive or nil)
            hasContent = true
        end
    end

    -- Player acceptance (Lv5): the number in the default colour, a square for how far it goes
    if ad.canSee(player, "acceptance_num") then
        local acceptance = ad.getPlayerAcceptance(animal, player)
        local accText = tostring(math.floor(acceptance))
        local accColor = acceptance >= ad.ACCEPT_PETTING and T.positive
            or (acceptance >= ad.ACCEPT_CALL and T.warning or T.danger)

        local rowH, endX = drawTextRow(panel, x, curY, ZeD.tr("UI_ZeD_Animals_Trust"), accText, accColor)

        -- Context hint
        local hint = ZeD.tr(acceptance >= ad.ACCEPT_PETTING and "UI_ZeD_Animals_TrustPet"
            or (acceptance >= ad.ACCEPT_CALL and "UI_ZeD_Animals_TrustCall" or "UI_ZeD_Animals_TrustNone"))
        panel:drawText(hint, endX + T.px(8), curY + math.floor((rowH - tm:getFontHeight(T.fontF5)) / 2),
            T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, T.fontF5)
        curY = curY + rowH
        hasContent = true
    end

    -- Mother/baby relationships
    if ad.needsMother(animal) then
        drawTag(panel, x, curY, ZeD.tr("UI_ZeD_Animals_AlertOrphan"), "danger")
        curY = curY + T.px(18)
        hasContent = true
    end

    return hasContent and (curY - y) or 0
end

-- ============================================================================
-- M-AGEN — GENETICS SECTION (Lv7+/Lv9+)
-- Disorder tags with descriptions. Skill-gated by AD.getVisibleDisorders.
-- ============================================================================

local function drawGeneticsSection(panel, x, y, w, animal, player)
    local T = ZeD.T
    local A = ZeD.Atoms
    local ad = AD()
    local tm = ZeD.TM

    local disorders = ad.getVisibleDisorders(animal, player)
    if #disorders == 0 then return 0 end

    local curY = y

    -- Section header
    curY = curY + detailHead(panel, x, curY, w, ZeD.tr("UI_ZeD_Animals_HdrGenetics")) + T.px(2)

    local descFont = T.fontF5

    for _, d in ipairs(disorders) do
        -- Tag: the severity is its status square (a good trait green, a severe one red)
        drawTag(panel, x, curY, d.label, d.sev)
        curY = curY + T.px(16) + T.px(2)

        -- Description below the tag
        if d.desc and d.desc ~= "" then
            panel:drawText(d.desc, x + T.px(4), curY,
                T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, descFont)
            curY = curY + tm:getFontHeight(descFont) + T.px(4)
        end
    end

    return curY - y
end

-- ============================================================================
-- O-ANDTL — ANIMAL DETAIL ORGANISM
-- Composes: header (pinned) + scrollable body (vitals + production +
-- breeding + genetics).
-- ============================================================================

local function getDetailViewState(win)
    if not win._animalsDetailState then
        win._animalsDetailState = {
            scrollY = 0,
        }
    end
    return win._animalsDetailState
end

local function renderRanchAnimal(panel, win, x, y, w, h)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local state = getState(win)
    local ds = getDetailViewState(win)
    local ad = AD()
    local animal = state.animalRef
    local player = getSpecificPlayer(0)

    if not animal then
        local pad0 = M.getTabPad()
        M.drawEmptyLine(panel, x + pad0, y + T.px(8), w - pad0 * 2, ZeD.tr("UI_ZeD_Animals_AnimalGone"))
        return
    end

    -- an animal outside the ranch that the game's Info opened keeps the game's reach (WorldRoutes.lua)
    local WR = ZeD.WorldRoutes
    if WR and WR.animalLeft and WR.animalLeft(win, animal) then
        navigateBack(win)
        return
    end

    local pad = M.getTabPad()
    local padTop = M.getTabPadTop()
    local scrollW = T.sp.scrollbarW

    -- ── HEADER (pinned at top, full width) ──
    local headerH = drawAnimalHeader(panel, x, y, w, animal, player)

    -- ── SCROLLABLE BODY ──
    local bodyTop = y + headerH
    local bodyH = h - headerH
    if bodyH <= 0 then return end

    local needsScroll = false  -- computed after render
    local contentW = w

    panel:setStencilRect(x, bodyTop, contentW, bodyH)

    local drawY = bodyTop - ds.scrollY + padTop

    -- ── IN HUTCH (opens the hutch card) ──
    win._animalsHutchLink = nil
    local hutchH = drawInHutchRow(panel, win, x + pad, drawY, contentW - pad * 2, animal, player)
    if hutchH > 0 then drawY = drawY + hutchH + T.px(SECTION_GAP) end

    -- ── VITALS ──
    local vitalsH = drawVitalsSection(panel, x + pad, drawY, contentW - pad * 2, animal, player)
    drawY = drawY + vitalsH + T.px(SECTION_GAP)

    -- ── PRODUCTION (Lv5+) ──
    local prodH = drawProductionSection(panel, x + pad, drawY, contentW - pad * 2, animal, player)
    if prodH > 0 then drawY = drawY + prodH + T.px(SECTION_GAP) end

    -- ── BREEDING (Lv3+) ──
    local breedH = drawBreedingSection(panel, x + pad, drawY, contentW - pad * 2, animal, player)
    if breedH > 0 then drawY = drawY + breedH + T.px(SECTION_GAP) end

    -- ── GENETICS (Lv7+/9+) ──
    local genH = drawGeneticsSection(panel, x + pad, drawY, contentW - pad * 2, animal, player)
    if genH > 0 then drawY = drawY + genH + T.px(SECTION_GAP) end

    -- ── GENOME (animal cheats only) ──
    win._animalsGenomeZones, win._animalsGenomeBtns = nil, nil
    local gnH = drawGenomeSection(panel, win, x + pad, drawY, contentW - pad * 2, animal)
    if gnH > 0 then drawY = drawY + gnH + T.px(SECTION_GAP) end

    -- gamepad: keep a focused genome element (or the hutch link) in view
    do
        local fe = liveEl(win)
        if fe and (fe.isGenome or fe.isGenomeBtn) then
            local ty, th
            for _, z in ipairs((fe.isGenome and win._animalsGenomeZones) or win._animalsGenomeBtns or {}) do
                if (fe.isGenome and z.gene == fe.gene and z.allele == fe.allele) or (fe.isGenomeBtn and z.id == fe.btnId) then ty, th = z.y, z.h end
            end
            if ty then
                if ty < bodyTop then ds.scrollY = math.max(0, ds.scrollY - (bodyTop - ty) - T.px(4))
                elseif ty + th > bodyTop + bodyH then ds.scrollY = ds.scrollY + (ty + th - bodyTop - bodyH) + T.px(4) end
            end
        end
    end

    panel:clearStencilRect()

    -- Compute total content height and scroll
    local totalContentH = (drawY + ds.scrollY) - bodyTop
    local maxScroll = math.max(0, totalContentH - bodyH)
    ds.scrollY = math.max(0, math.min(ds.scrollY, maxScroll))

    needsScroll = totalContentH > bodyH
    if needsScroll then
        ZeD.Molecules.scrollBar(panel, win, "an:detail", x + w - scrollW, bodyTop, scrollW - T.px(2), bodyH,
            ds.scrollY, totalContentH, function(v) ds.scrollY = v end, { step = T.px(VITAL_ROW_H) })
    end

    win._animalsDetailScroll = {
        top = bodyTop, h = bodyH, maxScroll = maxScroll, needsScroll = needsScroll
    }
end

-- ============================================================================
-- M-BSUM — BUTCHER SUMMARY BAND
-- Eligible animal count + estimated total meat yield.
-- Returns: bandH consumed.
-- ============================================================================

local function drawButcherSummary(panel, x, y, w, eligible)
    local T = ZeD.T
    local A = ZeD.Atoms
    local tm = ZeD.TM
    local pad = T.px(BROW_PAD)
    local curY = y + pad

    -- Total weight + estimated meat
    local totalWeight = 0
    local totalMeat = 0
    for _, entry in ipairs(eligible) do
        totalWeight = totalWeight + entry.yield.weight
        totalMeat = totalMeat + entry.yield.estMeat
    end

    -- Count line
    local countFont = T.fontF2
    local countStr = ZeD.tr("UI_ZeD_Animals_EligibleCount", #eligible)
    panel:drawText(countStr, x + pad, curY, T.text.r, T.text.g, T.text.b, T.text.a or 1, countFont)
    curY = curY + tm:getFontHeight(countFont) + T.px(4)

    -- Yield estimate line
    local yieldFont = T.fontF3
    local yieldStr = ZeD.tr("UI_ZeD_Animals_YieldSummary", string.format("%.1f", totalMeat), string.format("%.1f", totalWeight))
    panel:drawText(yieldStr, x + pad, curY, T.text.r, T.text.g, T.text.b, T.text.a or 1, yieldFont)
    curY = curY + tm:getFontHeight(yieldFont) + pad

    local bandH = curY - y
    -- The pane head's bottom: a structure line
    A.drawDividerH(panel, x, y + bandH - T.px(1), w, true)

    return bandH
end

-- ============================================================================
-- M-BROW — BUTCHER ROSTER ROW (40px)
-- Portrait + name + species + weight + est. meat + product tags.
-- Sorted by weight descending (heaviest first).
-- Returns: BROW_H consumed.
-- ============================================================================

local function drawButcherRow(panel, x, y, w, entry, hovered, onFocus)
    local T = ZeD.T
    local A = ZeD.Atoms
    local ad = AD()
    local tm = ZeD.TM
    local animal = entry.animal
    local yield = entry.yield
    local rowH = T.px(BROW_H)
    local ink = onFocus and T.textOnFocus or T.text
    local inkDim = onFocus and T.textOnFocus or T.textDim

    -- Hover highlight
    if hovered then
        local hc = T.hover
        panel:drawRect(x, y, w, rowH, hc.a or 0.08, hc.r, hc.g, hc.b)
    end

    -- Portrait (28px, vertically centered)
    local portraitPath = ad.resolvePortrait(animal)
    local tex = getTexture(portraitPath)
    local iconY = y + math.floor((rowH - T.px(BROW_ICON_SZ)) / 2)
    if tex then
        panel:drawTextureScaledAspect(tex, x + T.px(BROW_PAD), iconY, T.px(BROW_ICON_SZ), T.px(BROW_ICON_SZ), 0.9, 1, 1, 1)
    end

    local textX = x + T.px(BROW_PAD) + T.px(BROW_ICON_SZ) + T.px(BROW_PAD)
    local topY = y + T.px(4)
    local botY = y + T.px(22)

    -- Top line: Name + Weight (right-aligned)
    local nameFont = T.fontF2
    local name = ad.getDisplayName(animal)
    panel:drawText(name, textX, topY, ink.r, ink.g, ink.b, ink.a or 1, nameFont)

    -- Weight (right-aligned, data font)
    local weightFont = T.fontF3
    local weightStr = ZeD.tr("UI_ZeD_Animals_WeightKg", string.format("%.1f", yield.weight))
    local weightW = tm:MeasureStringX(weightFont, weightStr)
    panel:drawText(weightStr, x + w - T.px(BROW_PAD) - weightW, topY,
        ink.r, ink.g, ink.b, ink.a or 1, weightFont)

    -- Bottom line: Species + est. meat + product tags
    local secFont = T.fontF5
    local atype = ad.getAnimalType(animal)
    local species = getText("IGUI_AnimalType_" .. atype) or atype
    local sex = ZeD.tr(ad.isFemale(animal) and "UI_ZeD_Animals_SexF" or "UI_ZeD_Animals_SexM")
    local specLine = species .. " (" .. sex .. ")"
    panel:drawText(specLine, textX, botY, inkDim.r, inkDim.g, inkDim.b, inkDim.a or 1, secFont)

    -- Estimated meat (after species)
    local specW = tm:MeasureStringX(secFont, specLine)
    local meatStr = ZeD.tr("UI_ZeD_Animals_EstMeat", string.format("%.1f", yield.estMeat))
    panel:drawText(meatStr, textX + specW + T.px(6), botY,
        inkDim.r, inkDim.g, inkDim.b, inkDim.a or 1, secFont)

    -- Product tags (right-aligned on the bottom line)
    local bx = x + w - T.px(BROW_PAD)
    local ty = tagY(botY, tm:getFontHeight(secFont))
    for i = #yield.products, 1, -1 do
        local prod = ZeD.tr(AT.PROD_KEYS[yield.products[i]] or "UI_ZeD_Animals_ProdBone")
        bx = bx - tagWidth(prod, false)
        drawTag(panel, bx, ty, prod, nil)
        bx = bx - T.px(3)
    end

    -- Divider
    A.drawDividerH(panel, x, y + rowH - T.px(1), w, false)

    return rowH
end

-- ============================================================================
-- O-BOVW — BUTCHER OVERVIEW ORGANISM
-- Summary band + scrollable roster of eligible animals sorted by weight desc.
-- ============================================================================

local function renderButcherOverview(panel, win, x, y, w, h)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local ad = AD()
    local ap = AP()
    local bs = getButcherState(win)

    -- Ensure cache is ready
    if not ap.isReady() then ap.refreshCache() end

    local allAnimals = ap.getAllAnimals()

    -- Filter eligible + compute yields
    local eligible = {}
    for _, animal in ipairs(allAnimals) do
        if isButcherEligible(animal) then
            table.insert(eligible, {
                animal = animal,
                yield  = getYieldInfo(animal),
            })
        end
    end

    -- Empty state: one dim sentence, under the roster's head
    if #eligible == 0 then
        local pad0 = M.getTabPad()
        local hh = M.drawCategoryRow(panel, x, y, w, ZeD.tr("UI_ZeD_Animals_Roster"), 0, false, { noArrow = true })
        M.drawEmptyLine(panel, x + pad0, y + hh + T.px(8), w - pad0 * 2, ZeD.tr("UI_ZeD_Animals_NoEligibleYet"))
        return
    end

    -- Sort by weight descending (insertion sort — Kahlua's table.sort stack-overflows on large arrays)
    for i = 2, #eligible do
        local current = eligible[i]
        local j = i - 1
        while j >= 1 and eligible[j].yield.weight < current.yield.weight do
            eligible[j + 1] = eligible[j]
            j = j - 1
        end
        eligible[j + 1] = current
    end

    local pad = M.getTabPad()
    local scrollW = T.sp.scrollbarW

    win._animalsButcherZones = {}

    -- ── SUMMARY BAND (pinned) ──
    local summaryH = drawButcherSummary(panel, x, y, w, eligible)

    -- ── ROSTER HEAD ──
    local secY = y + summaryH
    local secH = M.drawCategoryRow(panel, x, secY, w, ZeD.tr("UI_ZeD_Animals_Roster"), #eligible, true, { noArrow = true })

    -- ── SCROLLABLE ROSTER ──
    local rosterTop = secY + secH
    local rosterH = h - (rosterTop - y)
    if rosterH <= 0 then return end

    local totalContentH = #eligible * T.px(BROW_H)
    local maxScroll = math.max(0, totalContentH - rosterH)

    -- The controller's row: keep it in the viewport. Mirror of the ranch zone.
    local gpFocusAnimal = nil
    do
        local fe = liveEl(win)
        if fe and fe.isButcher then gpFocusAnimal = fe.animal end
    end
    if gpFocusAnimal then
        local idx = nil
        for i = 1, #eligible do
            if eligible[i].animal == gpFocusAnimal then idx = i; break end
        end
        if idx then
            local itemTop = (idx - 1) * T.px(BROW_H)
            local itemBot = itemTop + T.px(BROW_H)
            if itemTop < bs.scrollY then
                bs.scrollY = itemTop
            elseif itemBot > bs.scrollY + rosterH then
                bs.scrollY = itemBot - rosterH
            end
        end
    end
    bs.scrollY = math.max(0, math.min(bs.scrollY, maxScroll))

    local needsScroll = totalContentH > rosterH
    local contentW = needsScroll and (w - scrollW) or w

    panel:setStencilRect(x, rosterTop, contentW, rosterH)

    local my = panel:getMouseY()
    local rowY = rosterTop - bs.scrollY

    for _, entry in ipairs(eligible) do
        if rowY + T.px(BROW_H) > rosterTop and rowY < rosterTop + rosterH then
            local isHovered = A.mouseIn(panel, x, rowY, contentW, T.px(BROW_H))
                and my >= rosterTop and my < rosterTop + rosterH
            if isHovered then help(panel, "UI_ZeD_Animals_HelpAnimalRow") end
            -- the controller's mark goes under the row's words
            local onFocus = false
            if entry.animal == gpFocusAnimal then
                onFocus = ZeD.Focus.mark(panel, x + pad, rowY, contentW - pad * 2, T.px(BROW_H), focusOpts(win))
            end
            drawButcherRow(panel, x + pad, rowY, contentW - pad * 2, entry, isHovered, onFocus)
            table.insert(win._animalsButcherZones, {
                x = x, y = rowY, w = contentW, h = T.px(BROW_H), animal = entry.animal
            })
        end
        rowY = rowY + T.px(BROW_H)
    end

    panel:clearStencilRect()

    if needsScroll then
        ZeD.Molecules.scrollBar(panel, win, "an:butcher", x + contentW + T.px(2), rosterTop, scrollW - T.px(2), rosterH,
            bs.scrollY, totalContentH, function(v) bs.scrollY = v end, { step = T.px(BROW_H) })
    end

    win._animalsButcherScroll = {
        top = rosterTop, h = rosterH, maxScroll = maxScroll, needsScroll = needsScroll
    }
end

-- ============================================================================
-- THE BAND + MAIN RENDER
-- ============================================================================

-- the band's click zones; a band not drawn leaves none (a stale one would answer
-- clicks on whatever is drawn there next)
local function clearBandZones(win)
    win._animalsAddZoneBtn = nil
    win._animalsZoneRenameBtn = nil
    win._animalsZoneRemoveBtn = nil
    win._animalsRemoveYes = nil
    win._animalsRemoveNo = nil
    win._animalsRenameSaveBtn = nil
    win._animalsRenameCancelBtn = nil
    win._animalsRenameResetBtn = nil
    win._animalsBulkBtns = nil
end

-- The zone view's own actions. canDo: nothing here needs the character's things, so
-- every one can be done; sensible: a zone that is not there has nothing to rename
-- or remove. ZeD.Disclose sorts them by the hidden-actions setting.
local function zoneVerbs(state)
    local has = state.zoneName ~= nil
    return {
        { id = "rename", label = getText("ContextMenu_RenameBag"), canDo = true, sensible = has,
          help = ZeD.tr("UI_ZeD_Animals_HelpRenameBtn") },
        { id = "remove", label = ZeD.tr("UI_ZeD_Animals_BtnRemoveZone"), canDo = true, sensible = has,
          help = ZeD.tr("UI_ZeD_Animals_HelpRemoveBtn") },
    }
end

-- How many animals of the zone All hungry and All milkable would pick, kept as the
-- sort is (SORT_CACHE_MS): the band greys a pick that finds none.
local function bulkCounts(zs, animals, zoneName)
    local t = getTimestampMs and getTimestampMs() or 0
    local c = zs._bulkCounts
    if c and c.zone == zoneName and c.n == #animals and t - c.t < SORT_CACHE_MS then return c end
    c = { t = t, zone = zoneName, n = #animals,
          hungry = QK().countWhere(animals, "hungry"), milkable = QK().countWhere(animals, "milkable") }
    zs._bulkCounts = c
    return c
end

-- the words a band button stands for in the ring ("animals:bulk:<id>")
local function bulkId(id) return "animals:bulk:" .. tostring(id) end

-- How the run that ended went ("Done: 3 of 3."), for a few seconds after it ends
local LAST_RUN_MS = 8000

-- the help line over each of the band's verbs for the ticked rows
local SEL_HELP = { milk = "UI_ZeD_Animals_HelpMilkSel", shear = "UI_ZeD_Animals_HelpShearSel", feed = "UI_ZeD_Animals_HelpFeedSel" }

-- The zone view's band. Three states:
--   a run going:    "Milking 2 of 5" and Stop
--   rows ticked:    Clear at the left, "3 selected", then Feed (n), Shear (n) and Milk (n),
--                   each only when it applies to a ticked animal, greyed with the reason
--                   when the tool (or, for Feed, any food they eat) is missing
--   nothing ticked: All hungry and All milkable at the left (greyed when none is),
--                   Rename and Remove zone at the right (Rename leaves first when the
--                   band is short of room: pressing the zone's name renames it too)
-- Every button is a controller stop (animals:bulk:<id>); the ring reads win._animalsBulkBtns.
local function drawZoneBand(panel, win, x, y, w, state)
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local Q = QK()
    local player = getSpecificPlayer(0)
    local zs = getZoneViewState(win)
    local animals = AP().getAnimalsInZone(state.zoneName)
    local sel = zoneSelection(win, state.zoneName)
    local selected = Q.prune(sel, animals)
    local lead, buttons, status = {}, {}, nil

    local function add(list, id, label, helpText, disabled, why, variant)
        list[#list + 1] = { id = id, label = label, help = disabled and why or helpText, disabled = disabled,
                            why = why, variant = variant, focus = focusFor(win, bulkId(id)) }
    end

    if Q.run then
        status = Q.runStatus()
        add(buttons, "stop", ZeD.tr("UI_ZeD_Animals_Stop"), ZeD.tr("UI_ZeD_Animals_HelpStopRun"), false)
    elseif #selected > 0 then
        add(lead, "clear", ZeD.tr("UI_ZeD_Animals_ClearSel"), ZeD.tr("UI_ZeD_Animals_HelpClearSel"), false)
        local verbs = Q.selectionVerbs(player, selected)
        for i, v in ipairs(verbs) do
            add(buttons, v.id, ZeD.tr("UI_ZeD_Animals_VerbCount", verbLabel(v.id), v.n),
                ZeD.tr(SEL_HELP[v.id] or SEL_HELP.milk), not v.ok, v.why, (i == #verbs) and "primary" or nil)
        end
        status = ZeD.tr(#verbs > 0 and "UI_ZeD_Animals_Selected" or "UI_ZeD_Animals_SelNothing", #selected)
    else
        local c = bulkCounts(zs, animals, state.zoneName)
        add(lead, "hungry", ZeD.tr("UI_ZeD_Animals_AllHungry"), ZeD.tr("UI_ZeD_Animals_HelpAllHungry"),
            c.hungry == 0, ZeD.tr("UI_ZeD_Animals_NoneHungry"))
        add(lead, "milkable", ZeD.tr("UI_ZeD_Animals_AllMilkable"), ZeD.tr("UI_ZeD_Animals_HelpAllMilkable"),
            c.milkable == 0, ZeD.tr("UI_ZeD_Animals_NoneMilkable"))
        -- Rename and Remove zone, as many as fit beside the picks
        local shown = ZeD.Disclose.split(zoneVerbs(state))
        local room = w - T.px(16)
        for _, b in ipairs(lead) do room = room - M.buttonW(b.label) - T.px(8) end
        local need = 0
        for _, v in ipairs(shown) do need = need + M.buttonW(v.label) + T.px(8) end
        for _, v in ipairs(shown) do
            if v.id == "rename" and need > room then
                need = need - M.buttonW(v.label) - T.px(8)
            else
                buttons[#buttons + 1] = { label = v.label, help = v.help, id = v.id }
            end
        end
        local last = Q.last
        local now = getTimestampMs and getTimestampMs() or 0
        if last and last.why and now - (last.t or 0) < LAST_RUN_MS then status = last.why end
    end

    local H, out = M.drawBand(panel, x, y, w, {
        win = win, lead = lead, buttons = buttons, status = status and { text = status } or nil })

    -- the rects: the zone verbs keep their own click zones, the rest are bulk buttons
    local bulk = {}
    local function keep(spec, rect)
        if not (spec and rect) then return end
        if spec.id == "rename" then win._animalsZoneRenameBtn = rect
        elseif spec.id == "remove" then win._animalsZoneRemoveBtn = rect
        else
            -- (sx, sy: the button's foot on the screen, where Feed's food picker opens)
            bulk[#bulk + 1] = { x = rect.x, y = rect.y, w = rect.w, h = rect.h, id = spec.id, disabled = spec.disabled,
                                sx = panel:getAbsoluteX() + rect.x, sy = panel:getAbsoluteY() + rect.y + rect.h + T.px(1) }
            -- a greyed one says why: over it with the pointer, or on it with the controller
            if spec.disabled then
                local on = isOn(win, bulkId(spec.id))
                if on or A.mouseIn(panel, rect.x, rect.y, rect.w, rect.h) then
                    whyBalloon(panel, win, bulkId(spec.id), spec.label, spec.why, rect, on)
                end
            end
        end
    end
    for i, b in ipairs(lead) do keep(b, out.lead[i]) end
    for i, b in ipairs(buttons) do keep(b, out.buttons[i]) end
    win._animalsBulkBtns = bulk
    return H
end

-- ============================================================================
-- FEED'S FOOD PICKER — a pull-down of the food the player carries (the context
-- list's look, ZeD_ContextList) under the band's Feed button. One row per food
-- the hungry ticked animals eat, with how many of them it suits and how many
-- are carried; picking one starts the feeding run. Rows are controller stops in
-- the list itself: D-pad up and down, A picks, B cancels.
-- ============================================================================

AT._feedMenu = nil

local function closeFeedMenu()
    local m = AT._feedMenu
    AT._feedMenu = nil
    if m and m._ctx and m._ctx.open then pcall(m.close, m) end
end

--- Open the food picker for the zone's ticked animals at (sx, sy) on the screen.
-- Returns false when nothing carried is food for them (the band has Feed greyed then).
function AT.openFeedPicker(win, zoneName, sx, sy)
    local Q = QK()
    local selected = Q.prune(zoneSelection(win, zoneName), AP().getAnimalsInZone(zoneName))
    Q.forgetChecks()
    local foods, _, hungry = Q.feedChoices(getSpecificPlayer(0), selected)
    if #foods == 0 then return false end
    closeFeedMenu()
    local rows = {}
    for _, c in ipairs(foods) do
        local name = c.name
        rows[#rows + 1] = {
            name = name, category = "food", iconTexture = c.tex,
            note = ZeD.tr("UI_ZeD_Animals_FeedNote", c.suits, hungry, c.have),
            onFire = function()
                -- the ticks as they are now: an animal that left the zone meanwhile is dropped
                local sel = zoneSelection(win, zoneName)
                if Q.start(getSpecificPlayer(0), "feed", Q.prune(sel, AP().getAnimalsInZone(zoneName)), name) then
                    Q.clear(sel)
                    win._animalsNavFocusTarget = bulkId("stop")
                end
            end,
        }
    end
    local m = ZeD_ContextList:new(0, "cursor", sx, sy, nil, rows, nil)
    m.headText = getText("ContextMenu_Feed")
    m:initialise()
    m:open()
    AT._feedMenu = m
    -- (B or a click outside closes the list; the controller is back on Feed)
    win._animalsNavFocusTarget = bulkId("feed")
    return true
end

--- Press one of the zone band's buttons by its id: hungry / milkable (tick those rows),
-- clear, milk / shear (run the game's action over the ticked rows), feed (open the food
-- picker), stop. A greyed one does nothing. The controller lands on the button that takes
-- the pressed one's place.
function AT.bulkPress(win, id)
    local state = getState(win)
    if state.view ~= "zone" or not state.zoneName then return false end
    local btn
    for _, b in ipairs(win._animalsBulkBtns or {}) do
        if b.id == id then
            if b.disabled then return false end
            btn = b
        end
    end
    if id == "feed" then
        local sx = btn and btn.sx or getMouseX()
        local sy = btn and btn.sy or getMouseY()
        return AT.openFeedPicker(win, state.zoneName, sx, sy)
    end
    local Q = QK()
    local animals = AP().getAnimalsInZone(state.zoneName)
    local sel = zoneSelection(win, state.zoneName)
    local land
    if id == "hungry" or id == "milkable" then
        if Q.selectWhere(sel, animals, id) > 0 then land = "clear" end
    elseif id == "clear" then
        Q.clear(sel)
        land = "hungry"
    elseif id == "milk" or id == "shear" then
        local ok = Q.start(getSpecificPlayer(0), id, Q.prune(sel, animals))
        if not ok then return false end
        Q.clear(sel)
        land = "stop"
    elseif id == "stop" then
        Q.stop()
        land = "hungry"
    else
        return false
    end
    if land then win._animalsNavFocusTarget = bulkId(land) end
    return true
end

--- Tick or clear one roster row (its box; X on the controller; a right-click on the row).
function AT.toggleSelected(win, animal)
    local state = getState(win)
    if state.view ~= "zone" or not animal then return false end
    QK().toggle(zoneSelection(win, state.zoneName), animal)
    return true
end

-- The band at the foot of the overview and the zone view: the screen's own actions,
-- and the answer to a question (Remove the zone?) or a rename in progress.
-- Returns the band's height.
local function drawTabBand(panel, win, x, y, w, view)
    local M = ZeD.Molecules
    local state = getState(win)
    clearBandZones(win)

    if view == "zone" and win._animalsRenaming then
        -- Rename: the text entry is over the name; answer with Save, Cancel or Reset
        local H, out = M.drawBand(panel, x, y, w, {
            win = win,
            status = { text = ZeD.tr("UI_ZeD_Animals_TypeNewName") },
            buttons = {
                { label = getText("IGUI_WorldMapEditor_Reset"), help = ZeD.tr("UI_ZeD_Animals_HelpRenameReset") },
                { label = ZeD.tr("UI_Cancel"), help = ZeD.tr("UI_ZeD_Animals_HelpRenameCancel") },
                { label = getText("UI_btn_save"), variant = "primary", help = ZeD.tr("UI_ZeD_Animals_HelpRenameSave") },
            },
        })
        win._animalsRenameResetBtn = out.buttons[1]
        win._animalsRenameCancelBtn = out.buttons[2]
        win._animalsRenameSaveBtn = out.buttons[3]
        return H
    elseif view == "zone" and win._animalsRemoveConfirm then
        -- Remove: a question, then Cancel and the verb (it cannot be undone)
        local H, cancelR, verbR = M.drawQuestionBand(panel, x, y, w, ZeD.tr("UI_ZeD_Animals_RemoveZoneAsk"),
            getText("ContextMenu_Remove"), { win = win, danger = true,
                cancelHelp = ZeD.tr("UI_ZeD_Animals_HelpRemoveCancel"), verbHelp = ZeD.tr("UI_ZeD_Animals_HelpRemoveDo") })
        win._animalsRemoveNo = cancelR
        win._animalsRemoveYes = verbR
        return H
    elseif view == "zone" then
        return drawZoneBand(panel, win, x, y, w, state)
    end
    -- Overview: Create zone
    local H, out = M.drawBand(panel, x, y, w, {
        win = win,
        buttons = { { label = ZeD.tr("UI_ZeD_Animals_CreateZoneBtn"), variant = "primary",
                      focus = focusFor(win, "animals:createzone"), help = ZeD.tr("UI_ZeD_Animals_HelpCreateZone") } },
    })
    win._animalsAddZoneBtn = out.buttons[1]
    return H
end

-- ============================================================================
-- MAIN RENDER — routes to submode × view
-- ============================================================================

local TAB_TOP_PAD = 13  -- aligns sub-tab strip bottom with inventory column header (matches JournalTab)

function ZeD.AnimalsTab.render(panel, win, x, y, w, h)
    local T = ZeD.T
    local M = ZeD.Molecules
    local state = getState(win)
    local zc = getZoneCreateState(win)

    -- Top padding: 13px aligns sub-tab strip bottom with inventory column header
    y = y + T.px(TAB_TOP_PAD)
    h = h - T.px(TAB_TOP_PAD)

    -- zones of the views not drawn this frame must not answer clicks or focus
    win._animalsStructZones = {}
    win._animalsHutchLink = nil
    win._animalsGenomeZones, win._animalsGenomeBtns = nil, nil
    win._animalsButcherZones = nil   -- the Butcher roster rebuilds it when drawn
    win._animalsRosterZones, win._animalsSortZone, win._animalsZoneNameZone = nil, nil, nil
    win._animalsZoneHelpZone = nil
    win._animalsZoneCardZones, win._animalsSectionZones = nil, nil
    win._animalsAlertZones, win._animalsOvClip = nil, nil   -- (not _animalsOvRows: the follow reads last frame's)
    if win._animalsScroll then win._animalsScroll.visible = false end   -- (the Ranch page's bar: it shows it)
    -- (only the view drawn this frame answers the wheel)
    win._animalsDetailScroll, win._animalsRosterScroll, win._animalsButcherScroll = nil, nil, nil
    win._animalsBreadcrumbZone = nil

    -- Zone create mode overrides everything
    if zc.active then
        clearBandZones(win)
        local tabH = drawSubmodeStrip(panel, win, x, y, w)
        renderZoneCreateView(panel, win, x, y + tabH, w, h - tabH)
        return
    end
    win._zoneConfirmYes, win._zoneConfirmNo, win._zoneCancelBtn = nil, nil, nil

    -- Sub-tab strip (always visible)
    local curY = y + drawSubmodeStrip(panel, win, x, y, w)

    -- Back (zone/animal views only)
    if state.view == "zone" or state.view == "animal" then
        curY = curY + drawBackBar(panel, win, x, curY, w)
    end

    -- The band (overview + zone detail — not animal drill-down)
    local showBand = (state.view == "overview" or state.view == "zone")
    local bandH = 0
    if showBand then
        bandH = M.bandH()
        drawTabBand(panel, win, x, y + h - bandH, w, state.view)
    else
        clearBandZones(win)
    end

    -- Remaining content area (between chrome and band)
    local contentH = (y + h) - bandH - curY

    -- Route to the right renderer
    if state.submode == "ranch" then
        if state.view == "overview" then
            renderRanchOverview(panel, win, x, curY, w, contentH)
        elseif state.view == "zone" then
            renderRanchZone(panel, win, x, curY, w, contentH)
        elseif state.view == "animal" then
            renderRanchAnimal(panel, win, x, curY, w, contentH)
        end
    elseif state.submode == "butcher" then
        if state.view == "animal" then
            -- a roster row opens the animal (the same view as the Ranch one)
            renderRanchAnimal(panel, win, x, curY, w, contentH)
        else
            -- HOOKS first (pinned), then the livestock roster
            local hookH = drawHooks(panel, win, x, curY, w, getSpecificPlayer(0))
            renderButcherOverview(panel, win, x, curY + hookH, w, contentH - hookH)
        end
    end
end

-- ============================================================================
-- CLICK HANDLER
-- ============================================================================

function ZeD.AnimalsTab.onClick(win, x, y)
    -- Zone creation mode clicks (the band's buttons)
    local zc = getZoneCreateState(win)
    if zc.active then
        if hitZone(win._zoneConfirmYes, x, y) then
            confirmZoneCreate(win)
            return true
        end
        if hitZone(win._zoneConfirmNo, x, y) then
            -- Cancel on the question: back to drawing, the corners cleared
            zc.phase = "idle"
            zc.startX = nil
            zc.endX = nil
            return true
        end
        if hitZone(win._zoneCancelBtn, x, y) then
            cancelZoneCreate(win)
            return true
        end
    end

    -- The band: Create zone
    if hitZone(win._animalsAddZoneBtn, x, y) then
        startZoneCreate(win)
        return true
    end

    -- Zone name click → start rename (like ItemCard)
    if hitZone(win._animalsZoneNameZone, x, y) and not win._animalsRenaming then
        renameZone(win)
        return true
    end
    -- Zone detail: Rename and Remove zone
    if hitZone(win._animalsZoneRenameBtn, x, y) and not win._animalsRenaming then
        renameZone(win)
        return true
    end
    if hitZone(win._animalsZoneRemoveBtn, x, y) then
        removeZone(win)
        return true
    end
    -- Rename: Save / Cancel / Reset
    if hitZone(win._animalsRenameSaveBtn, x, y) then
        commitRename(win)
        return true
    end
    if hitZone(win._animalsRenameCancelBtn, x, y) then
        cancelRename(win)
        return true
    end
    if hitZone(win._animalsRenameResetBtn, x, y) then
        -- Reset to auto-generated name
        local state = getState(win)
        local zone = getZoneByName(state.zoneName)
        if zone and win._animalsRenameEntry then
            -- Find original auto-name by zone index
            local allZones = DesignationZoneAnimal.getAllZones()
            if allZones then
                for i = 0, allZones:size() - 1 do
                    if allZones:get(i) == zone then
                        win._animalsRenameEntry:setText(ZeD.tr("UI_ZeD_Animals_ZoneAutoName", i + 1))
                        break
                    end
                end
            end
        end
        return true
    end
    -- Remove question: the verb / Cancel
    if hitZone(win._animalsRemoveYes, x, y) then
        confirmRemoveZone(win)
        return true
    end
    if hitZone(win._animalsRemoveNo, x, y) then
        cancelRemoveZone(win)
        return true
    end
    -- Zone band: the picks, Clear, Milk / Shear over the ticked rows, Stop
    for _, b in ipairs(win._animalsBulkBtns or {}) do
        if hitZone(b, x, y) then
            AT.bulkPress(win, b.id)
            return true
        end
    end

    -- Submode strip clicks
    if win._animalsSubmodeZones then
        for _, zone in ipairs(win._animalsSubmodeZones) do
            if x >= zone.x and x < zone.x + zone.w
               and y >= zone.y and y < zone.y + zone.h then
                switchSubmode(win, zone.id)
                return true
            end
        end
    end

    -- Breadcrumb back click
    if win._animalsBreadcrumbZone then
        local z = win._animalsBreadcrumbZone
        if x >= z.x and x < z.x + z.w
           and y >= z.y and y < z.y + z.h then
            navigateBack(win)
            return true
        end
    end

    -- Hutch / trough / hook rows: OPEN (or the whole row) opens the card
    if win._animalsStructZones then
        for _, sz in ipairs(win._animalsStructZones) do
            if hitZone(sz, x, y) then
                openStruct(sz.kind, sz.obj)
                return true
            end
        end
    end
    if win._animalsHutchLink and hitZone(win._animalsHutchLink, x, y) then
        local sc = win._animalsDetailScroll
        if not sc or (y >= sc.top and y < sc.top + sc.h) then
            openStruct("hutch", win._animalsHutchLink.obj)
            return true
        end
    end
    -- Genome (cheats): pick an allele, then the controls act on it
    if win._animalsGenomeZones then
        local sc = win._animalsDetailScroll
        local inView = not sc or (y >= sc.top and y < sc.top + sc.h)
        if inView then
            for _, gz in ipairs(win._animalsGenomeZones) do
                if hitZone(gz, x, y) then
                    win._animalsGenomeSel = { gene = gz.gene, allele = gz.allele }
                    return true
                end
            end
            for _, b in ipairs(win._animalsGenomeBtns or {}) do
                if hitZone(b, x, y) then
                    genomeAct(win, b.id, getState(win).animalRef)
                    return true
                end
            end
        end
    end

    -- Sort cycle click (zone view) — test before section headers
    if hitZone(win._animalsSortZone, x, y) then
        cycleSortMode(win)
        return true
    end

    -- Help (zone view): the game's zone note, asked for
    if hitZone(win._animalsZoneHelpZone, x, y) then
        AT.zoneHelp(win)
        return true
    end

    -- Section header collapse/expand clicks (overview). The page scrolls: rows out of its view take no click
    local ovClip = win._animalsOvClip
    local inOv = not ovClip or (y >= ovClip.y and y < ovClip.y + ovClip.h)
    -- An alert's button: its verb (a greyed one takes the press and does nothing)
    if inOv and win._animalsAlertZones then
        for _, az in ipairs(win._animalsAlertZones) do
            if az.btn and hitZone(az.btn, x, y) then
                if az.btn.ok then AT.alertAct(win, az.animal, az.verb) end
                return true
            end
        end
    end
    if inOv and win._animalsSectionZones and win._animalsOverviewState then
        for _, sz in ipairs(win._animalsSectionZones) do
            if hitZone(sz, x, y) then
                win._animalsOverviewState[sz.key] = not win._animalsOverviewState[sz.key]
                return true
            end
        end
    end

    -- Zone card clicks → navigate to zone view
    if inOv and win._animalsZoneCardZones then
        for _, zc in ipairs(win._animalsZoneCardZones) do
            if hitZone(zc, x, y) then
                navigate(win, "zone", zc.zoneName, nil)
                return true
            end
        end
    end

    -- Animal roster row clicks: the box ticks the row, the rest opens the animal
    if win._animalsRosterZones then
        local rs = win._animalsRosterScroll
        local inRoster = not rs or (y >= rs.top and y < rs.top + rs.h)
        for _, rz in ipairs(win._animalsRosterZones) do
            if inRoster and x >= rz.x and x < rz.x + rz.w
               and y >= rz.y and y < rz.y + rz.h then
                if rz.cb and hitZone(rz.cb, x, y) then
                    AT.toggleSelected(win, rz.animal)
                else
                    navigate(win, "animal", nil, rz.animal)
                end
                return true
            end
        end
    end

    -- Butcher roster row clicks → navigate to animal detail
    if win._animalsButcherZones then
        for _, bz in ipairs(win._animalsButcherZones) do
            if x >= bz.x and x < bz.x + bz.w
               and y >= bz.y and y < bz.y + bz.h then
                -- Navigate to animal detail but stay in butcher submode
                navigate(win, "animal", nil, bz.animal)
                return true
            end
        end
    end

    -- The Ranch page's scroll bar
    local scroll = win._animalsScroll
    if scroll and scroll.visible then
        local sp = ZeD.T.sp
        local sbX = scroll.x
        if x >= sbX and x < sbX + sp.scrollbarW then
            scroll:handleMouseDown(y - scroll.y)
            return true
        end
    end

    return false
end

-- A right-click on a roster row ticks or clears it (X on the controller does the same).
function ZeD.AnimalsTab.onRightClick(win, x, y)
    local rs = win._animalsRosterScroll
    if not win._animalsRosterZones or (rs and (y < rs.top or y >= rs.top + rs.h)) then return false end
    for _, rz in ipairs(win._animalsRosterZones) do
        if hitZone(rz, x, y) then
            return AT.toggleSelected(win, rz.animal)
        end
    end
    return false
end

function ZeD.AnimalsTab.onMouseWheel(win, del)
    local T = ZeD.T
    -- Animal detail view scroll
    local detailScroll = win._animalsDetailScroll
    if detailScroll and detailScroll.needsScroll then
        local ds = getDetailViewState(win)
        local scrollStep = T.px(VITAL_ROW_H) * 2  -- scroll by 2 rows per tick
        ds.scrollY = ds.scrollY + (del * scrollStep)
        ds.scrollY = math.max(0, math.min(ds.scrollY, detailScroll.maxScroll))
        return true
    end

    -- Zone view roster scroll
    local rosterScroll = win._animalsRosterScroll
    if rosterScroll and rosterScroll.needsScroll then
        local zs = getZoneViewState(win)
        -- positive delta = scroll DOWN (inverted)
        local scrollStep = T.px(AROW_H)  -- scroll by one row per tick
        zs.scrollY = zs.scrollY + (del * scrollStep)
        zs.scrollY = math.max(0, math.min(zs.scrollY, rosterScroll.maxScroll))
        return true
    end

    -- Butcher roster scroll
    local butcherScroll = win._animalsButcherScroll
    if butcherScroll and butcherScroll.needsScroll then
        local bs = getButcherState(win)
        local scrollStep = T.px(BROW_H)
        bs.scrollY = bs.scrollY + (del * scrollStep)
        bs.scrollY = math.max(0, math.min(bs.scrollY, butcherScroll.maxScroll))
        return true
    end


    -- The Ranch page: a row a tick
    local scroll = win._animalsScroll
    if scroll and scroll.visible then
        scroll:setScrollPos(scroll.scrollPos + del * scroll:lineStep())
        return true
    end
    return false
end

-- ============================================================================
-- PUBLIC NAVIGATION — entry points for the object cards, the World routes and
-- the World window's gamepad builder
-- ============================================================================

AT.navigate         = navigate
-- the zone view's help button: the game's first-time zone note, for the window's player
function AT.zoneHelp(win)
    local WR = ZeD.WorldRoutes
    if not (WR and WR.zoneHelp) then return false end
    local pn = 0
    local p = win and win._playerObj
    if p then
        local ok, n = pcall(function() return p:getPlayerNum() end)
        if ok and n then pn = n end
    end
    return WR.zoneHelp(pn)
end
AT.navigateBack     = navigateBack
-- The cards link back here (a bird's INFO), and the World window's gamepad
-- builder opens and edits through these.
AT.openStruct       = openStruct
AT.genomeAct        = genomeAct
function AT.showAnimal(win, animal)
    local state = getState(win)
    state.submode = "ranch"
    -- (the zone the rows count it in, getDZone as the fallback: AnimalsData.getZoneName)
    local zn = AD().getZoneName(animal)
    state.zoneName = zn
    state.view = zn and "zone" or "overview"
    navigate(win, "animal", nil, animal)
end
AT.getState         = getState
-- Exported for the World window's gamepad builder (submode live-switch on
-- focus + sort-btn A-press + roster/butcher/zonecard navigate calls).
AT.switchSubmode    = switchSubmode
AT.cycleSortMode    = cycleSortMode
AT.getZoneViewState = getZoneViewState
AT.getButcherState  = getButcherState
AT.startZoneCreate  = startZoneCreate
-- The gamepad zone-draw state machine.
AT.gpMoveCursor     = gpMoveCursor
AT.gpConfirm        = gpConfirm
AT.gpCancel         = gpCancel

-- ============================================================================
-- REGISTRATION
-- ============================================================================

function ZeD.AnimalsTab.register(dispatchTable)
    -- late-bound, so a reload of this file reaches the window
    dispatchTable["animals"] = function(...) return ZeD.AnimalsTab.render(...) end
end
