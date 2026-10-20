-- ZeD-UI/42/media/lua/client/ZeD/AnimalsTab.lua
-- ============================================================================
-- ANIMALS TAB — World Window tab controller.
-- State machine routing: submode (ranch/butcher) × view (overview/zone/animal).
-- Session B: Ranch Overview molecules + O-ANOVW organism.
-- Session C: Zone Detail View — roster list + zone info band + sort cycle.
-- Session D: Animal Detail View — vitals + production + breeding + genetics.
-- Session E: Butcher sub-mode — eligibility filter + yield estimates.
--
-- Molecules defined here (Animals-specific, not general-purpose):
--   M-SUBM   drawSubmodeStrip        — Ranch / Butcher tab strip
--   M-SECH   drawAnimalSection       — Collapsible section header
--   M-ALERT  drawAlertRow            — Alert row (portrait + name + badge)
--   M-MINIM  drawMiniMeter           — Compact inline fill meter with label
--   M-ZRSUM  drawZoneSummary         — Zone card with mini-meters
--   M-TOT    drawTotals              — 2-column production totals
--   M-ZINF   drawZoneInfoBand        — Zone name + count + wide meters + warnings
--   M-AROW   drawAnimalRow           — 48px roster row (portrait + dots + badges)
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
-- Design: zed-animals-v2-fira.html (S84 approved).
-- Hunt sub-mode deferred to Phase 2.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/AnimalsData"
require "ZeD/AnimalsAlertPoller"
require "ZeD/AnimalsStressInference"
require "ZeD/SafeMode"
-- Zone creation uses DesignationZoneAnimal directly (no vanilla UI panels)

ZeD = ZeD or {}
ZeD.AnimalsTab = ZeD.AnimalsTab or {}

local AT = ZeD.AnimalsTab

-- Lazy accessors — modules may not be fully initialized at require-time (Q21)
local function AD() return ZeD.AnimalsData end
local function SI() return ZeD.AnimalsStressInference end
local function AP() return ZeD.AnimalsAlertPoller end

-- ============================================================================
-- S109 — GAMEPAD FOCUS CUE HELPERS
-- Paint gate reads live focused element from FocusManager (S101 pattern:
-- avoid persistent _gpFocused* fields for multi-element-type zones since they
-- mis-paint on first frame). Render paths pre-paint a 0.55α accent rect over
-- element bounds BEFORE the content draws so content renders on top of the
-- cue. Matcher closure discriminates between element types (isRoster / isZone
-- Card / isDisclosure / ...).
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

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local BREADCRUMB_H     = 20      -- matches inventory column header height
local EMPTY_PAD        = 40      -- padding for empty state text

-- Zone detail view
local ZINF_PAD         = 6       -- zone info band internal padding
local AROW_H           = 48      -- animal roster row height
local AROW_ICON_SZ     = 32      -- portrait icon size
local AROW_DOT_SZ      = 7       -- stat dot diameter
local AROW_DOT_GAP     = 6       -- gap between dots
local AROW_PAD         = 6       -- row internal padding
local SORT_MODES       = { "name", "species", "alerts" }
local SORT_LABELS      = { name = "Name", species = "Species", alerts = "Alerts" }

-- Footer
local FOOTER_H         = 32      -- footer strip height

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
-- Insertion sort — Kahlua-safe, no recursion (Q35).
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

    -- Insertion sort (Q35: Kahlua table.sort stack-overflows on large arrays)
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
    if val > 60 then return T.positive end
    if val > 30 then return T.warning end
    return T.danger
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
-- DRAW BUTTON — reusable outline button with hover highlight.
-- Returns: { x, y, w, h } click zone table.
-- Variants: "accent" (primary), "positive", "danger", "neutral" (default).
-- ============================================================================

local BTN_H = 22  -- standard ZeD button height (T.buttonH equiv)

local function drawBtn(panel, x, y, label, variant, font)
    local T = ZeD.T
    local A = ZeD.Atoms
    local tm = ZeD.TM
    local btnFont = font or T.fontF4 or ZeD.T.fontF2
    label = ZeD.btnCase(label)   -- sentence case, never all caps
    local btnW = tm:MeasureStringX(btnFont, label) + T.px(16)
    local btnH = T.px(BTN_H)

    -- Pick border/text color by variant
    local color
    if variant == "accent" then
        color = T.accent
    elseif variant == "positive" then
        color = T.positive
    elseif variant == "danger" then
        color = T.danger
    else
        color = T.borderS or T.border
    end

    -- Rounded border (System 7 style)
    A.borderRounded(panel, x, y, btnW, btnH, color.r, color.g, color.b, color.a or 1)

    -- Hover highlight (rounded fill)
    local mx = panel:getMouseX()
    local my = panel:getMouseY()
    if mx >= x and mx < x + btnW and my >= y and my < y + btnH then
        A.fillRounded(panel, x + T.px(1), y + T.px(1), btnW - T.px(2), btnH - T.px(2), color.r, color.g, color.b, 0.1)
    end

    -- Label centered
    local lblW = tm:MeasureStringX(btnFont, label)
    local lblY = y + math.floor((btnH - tm:getFontHeight(btnFont)) / 2)
    local textColor = (variant == "neutral") and T.textDim or color
    panel:drawText(label, x + math.floor((btnW - lblW) / 2), lblY,
        textColor.r, textColor.g, textColor.b, (variant == "neutral") and 0.7 or 1.0, btnFont)

    return { x = x, y = y, w = btnW, h = btnH }
end

-- Hit test helper for click zone tables
local function hitZone(zone, x, y)
    if not zone then return false end
    return x >= zone.x and x < zone.x + zone.w
       and y >= zone.y and y < zone.y + zone.h
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

-- Forward declarations (Q104/Q105) — gp* helpers reference these which are
-- defined lower in the file. Without the hoist, Kahlua closures capture nil
-- at creation time. Assignments below change `local function foo` →
-- `foo = function` so the hoisted slots get filled.
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
            -- S109a: gamepad cursor. Separate from startX/endX so idle-phase
            -- D-pad can reposition before the first A-press. Seeded to player
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
    while DesignationZoneAnimal.getZoneByName("Livestock Zone #" .. num) do
        num = num + 1
    end
    zc.name = "Livestock Zone #" .. num

    -- Show existing zones
    local player = getSpecificPlayer(0)
    if player then
        player:setSeeDesignationZone(true)
        zc.z = math.floor(player:getZ())
        -- S109a: seed gamepad cursor to player tile so idle-phase D-pad has
        -- a valid start point if the user goes that path.
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
-- S109a — GAMEPAD ZONE-DRAW HELPERS
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
        -- S109a: seed post-create focus so the ring lands on the new zone
        -- card instead of falling back to idx-clamp (which drops the user on
        -- the ranch submode pill). Refresh loop reads this hint.
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

-- Q104 hoist: assign into forward-declared slot so gp* helpers above see it.
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
    -- Set rename mode — footer will show SAVE/CANCEL, info band shows text entry
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
    -- Set confirm flag — footer will show YES/NO instead of normal buttons
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

-- Returns normalized width, height, valid flags
-- Q104 hoist: assigned into forward-declared slot so gpConfirm above sees it.
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

    -- S109a: Gamepad cursor 1×1 tile highlight during idle phase so the user
    -- can see where the first corner will drop. Skipped in drawing/confirm
    -- phases since the main rect highlight subsumes it.
    if zc.phase == "idle" and zc.cursorX and zc.cursorY then
        addAreaHighlightForPlayer(0,
            zc.cursorX, zc.cursorY,
            zc.cursorX + 1, zc.cursorY + 1,
            zc.z, 0.9, 0.9, 0.2, 0.5)
    end
end

-- Render dimensions block (shared by drawing + confirm phases)
local function drawZoneDimensions(panel, x, y, w, zc)
    local T = ZeD.T
    local tm = ZeD.TM
    local lblFont = T.fontF1 or ZeD.T.fontF2
    local dimFont = T.fontF3 or ZeD.T.fontF2
    local lblColor = T.textSec or T.textDim
    local zw, zh, wOk, hOk = getZoneDimensions(zc)
    local curY = y

    panel:drawText("WIDTH", x, curY, lblColor.r, lblColor.g, lblColor.b, 0.7, lblFont)
    local wc = wOk and T.text or T.danger
    panel:drawText(tostring(zw), x + T.px(60), curY, wc.r, wc.g, wc.b, 1.0, dimFont)
    curY = curY + tm:getFontHeight(dimFont) + T.px(4)

    panel:drawText("LENGTH", x, curY, lblColor.r, lblColor.g, lblColor.b, 0.7, lblFont)
    local hc = hOk and T.text or T.danger
    panel:drawText(tostring(zh), x + T.px(60), curY, hc.r, hc.g, hc.b, 1.0, dimFont)
    curY = curY + tm:getFontHeight(dimFont) + T.px(4)

    panel:drawText("TOTAL", x, curY, lblColor.r, lblColor.g, lblColor.b, 0.7, lblFont)
    panel:drawText(tostring(zw * zh), x + T.px(60), curY, T.text.r, T.text.g, T.text.b, 1.0, dimFont)
    curY = curY + tm:getFontHeight(dimFont)

    return curY - y
end

-- Zone creation view: content area (above footer)
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

    -- Breadcrumb-style header: "Create Livestock Zone" — 20px, F1, toneLo
    local hdrH = T.sp.colHdrH or T.px(20)
    local hdrFont = T.fontF1 or ZeD.T.fontF2
    local hdrFH = tm:getFontHeight(hdrFont)
    local s2 = T.surf2
    panel:drawRect(x, curY, w, hdrH, s2.a, s2.r, s2.g, s2.b)
    A.drawSecondary(panel, "CREATE LIVESTOCK ZONE", x + T.px(6), curY + math.floor((hdrH - hdrFH) / 2), T.toneLo)
    A.drawDividerH(panel, x, curY + hdrH - T.px(1), w, true)
    curY = curY + hdrH + pad

    -- Zone name
    local valFont = T.fontF3 or ZeD.T.fontF2
    local lblColor = T.textSec or T.textDim
    local nameFont = T.fontF4 or ZeD.T.fontF2
    local nc = T.toneNorm
    A.drawSecondary(panel, "NAME", x + pad, curY, lblColor)
    panel:drawText(zc.name, x + pad + T.px(60), curY, nc.r, nc.g, nc.b, nc.a or 1, nameFont)
    curY = curY + tm:getFontHeight(valFont) + T.px(12)

    if zc.phase == "idle" then
        local hintFont = T.fontF4 or ZeD.T.fontF2
        local tc = T.toneNorm
        panel:drawText("Click and drag on the ground to draw your zone rectangle.", x + pad, curY,
            tc.r, tc.g, tc.b, tc.a or 1, hintFont)
        curY = curY + tm:getFontHeight(hintFont) + T.px(8)

        local dataFont = T.fontF3 or ZeD.T.fontF2
        local hi = T.toneHi or T.text
        panel:drawText("Min 2x2, max 40x40 tiles", x + pad, curY,
            hi.r, hi.g, hi.b, hi.a or 1, dataFont)

    elseif zc.phase == "drawing" then
        curY = curY + drawZoneDimensions(panel, x + pad, curY, w, zc)
        -- "Release to set zone" hint rendered in footer

    elseif zc.phase == "confirm" then
        curY = curY + drawZoneDimensions(panel, x + pad, curY, w, zc)
        -- "Create this zone?" prompt rendered in footer
    end
end

-- Zone creation footer strip: phase-dependent buttons
local function drawZoneCreateFooter(panel, win, x, y, w)
    local T = ZeD.T
    local A = ZeD.Atoms
    local zc = getZoneCreateState(win)
    local pad = T.px(6)
    local btnFont = T.fontF5 or ZeD.T.fontF2
    local btnH = T.px(BTN_H)

    A.drawDividerH(panel, x, y, w, false)
    local btnY = y + math.floor((T.px(FOOTER_H) - btnH) / 2)
    local bx = x + pad

    -- Clear previous zones
    win._zoneConfirmYes = nil
    win._zoneConfirmNo = nil
    win._zoneCancelBtn = nil

    if zc.phase == "confirm" then
        -- YES + NO + CANCEL + prompt
        win._zoneConfirmYes = drawBtn(panel, bx, btnY, "Yes", "positive", btnFont)
        bx = bx + win._zoneConfirmYes.w + T.px(6)
        win._zoneConfirmNo = drawBtn(panel, bx, btnY, "No", "danger", btnFont)
        bx = bx + win._zoneConfirmNo.w + T.px(6)
        win._zoneCancelBtn = drawBtn(panel, bx, btnY, "Cancel", "neutral", btnFont)
        bx = bx + win._zoneCancelBtn.w + T.px(8)
        local promptFont = T.fontF3 or ZeD.T.fontF2
        local nc = T.toneNorm
        local promptY = btnY + math.floor((btnH - ZeD.TM:getFontHeight(promptFont)) / 2)
        panel:drawText("Create this zone?", bx, promptY, nc.r, nc.g, nc.b, nc.a or 1, promptFont)
    elseif zc.phase == "drawing" then
        -- CANCEL + "Release to set zone" hint
        win._zoneCancelBtn = drawBtn(panel, bx, btnY, "Cancel", "neutral", btnFont)
        bx = bx + win._zoneCancelBtn.w + T.px(8)
        local hintFont = T.fontF3 or ZeD.T.fontF2
        local nc = T.toneNorm
        local hintY = btnY + math.floor((btnH - ZeD.TM:getFontHeight(hintFont)) / 2)
        panel:drawText("Release to set zone", bx, hintY, nc.r, nc.g, nc.b, nc.a or 1, hintFont)
    else
        -- Just CANCEL (idle)
        win._zoneCancelBtn = drawBtn(panel, bx, btnY, "Cancel", "neutral", btnFont)
    end

    return T.px(FOOTER_H)
end

-- Combined render for zone create mode (called from main render)
local function renderZoneCreateView(panel, win, x, y, w, h)
    local T = ZeD.T
    -- Footer at bottom
    local footerY = y + h - T.px(FOOTER_H)
    drawZoneCreateFooter(panel, win, x, footerY, w)

    -- Content above footer
    local contentH = h - T.px(FOOTER_H)
    renderZoneCreateContent(panel, win, x, y, w, contentH)
end

-- ============================================================================
-- EMPTY STATE
-- ============================================================================

local function drawEmptyState(panel, win, x, y, w, h)
    local T = ZeD.T
    local tm = ZeD.TM

    -- Measure content block to center it vertically
    local iconSz = T.px(32)
    local font = T.fontF2 or ZeD.T.fontF2
    local title = "No livestock zones"
    local titleH = tm:getFontHeight(font)
    local blockH = iconSz + T.px(10) + titleH
    local contentH = h - T.px(FOOTER_H)  -- above footer
    local cy = y + math.floor((contentH - blockH) / 2)

    -- Icon (centered)
    local iconTex = getTexture(AD().ZONE_ICON_OFF)
    if iconTex then
        local iconX = x + math.floor((w - iconSz) / 2)
        panel:drawTextureScaledAspect(iconTex, iconX, cy, iconSz, iconSz, 0.4, 1, 1, 1)
        cy = cy + iconSz + T.px(10)
    end

    -- Title (centered) — F2 lo
    local tw = tm:MeasureStringX(font, title)
    local lo = T.toneLo
    panel:drawText(title, x + math.floor((w - tw) / 2), cy, lo.r, lo.g, lo.b, lo.a or 1, font)
    -- Hint text rendered in footer by drawFooterStrip
end

-- ============================================================================
-- SUBMODE STRIP — RANCH / BUTCHER
-- ============================================================================

local SUBMODES = {
    { id = "ranch",   label = "Ranch" },
    { id = "butcher", label = "Butcher" },
}

--- Draw sub-tab strip — same System 6 pattern as JournalTab.
-- Active tab: surf1 fill, top+left+right border, open bottom.
-- Inactive: text only. Bottom border spans full width.
-- @return tabStripH (T.tabH)
local function drawSubmodeStrip(panel, win, x, y, w)
    local T    = ZeD.T
    local tH   = T.tabH
    local padH = T.sp.md
    local gap  = T.sp.tabGap
    local bc   = T.borderS
    local tm   = ZeD.TM
    local state = getState(win)

    -- Bottom border (full width, separates strip from content)
    panel:drawRect(x, y + tH - T.px(1), w, T.px(1), bc.a, bc.r, bc.g, bc.b)

    local tabX = x + T.sp.sm
    local zones = {}

    for i, sm in ipairs(SUBMODES) do
        local tw = tm:MeasureStringX(T.fontF1, sm.label) + padH * 2
        local isActive = (state.submode == sm.id)

        -- S109: gamepad focus cue — 0.55α accent over pill bounds. Paints
        -- under active fill so the active border still reads. Gate on live
        -- focused element's submodeId (avoids stale-state mispaint).
        local isGpFocused = _gpFocusMatches(win, function(el)
            return el.isSubmode and el.submodeId == sm.id
        end)

        if isActive then
            -- Active: surf1 fill, top+left+right border, open bottom
            panel:drawRect(tabX, y, tw, tH, T.surf1.a, T.surf1.r, T.surf1.g, T.surf1.b)
            if isGpFocused then
                _paintGpCue(panel, tabX, y, tw, tH)
            end
            panel:drawRect(tabX, y, tw, T.px(1), bc.a, bc.r, bc.g, bc.b)           -- top
            panel:drawRect(tabX, y, T.px(1), tH, bc.a, bc.r, bc.g, bc.b)           -- left
            panel:drawRect(tabX + tw - T.px(1), y, T.px(1), tH, bc.a, bc.r, bc.g, bc.b)  -- right
            -- Erase bottom border behind active tab (open bottom)
            panel:drawRect(tabX + T.px(1), y + tH - T.px(1), tw - T.px(2), T.px(1),
                T.surf1.a, T.surf1.r, T.surf1.g, T.surf1.b)

            local textY = y + math.floor((tH - tm:getFontHeight(T.fontF1)) / 2)
            panel:drawText(sm.label, tabX + padH, textY,
                T.toneNorm.r, T.toneNorm.g, T.toneNorm.b, T.toneNorm.a or 1, T.fontF1)
        else
            if isGpFocused then
                _paintGpCue(panel, tabX, y, tw, tH)
            end
            local textY = y + math.floor((tH - tm:getFontHeight(T.fontF1)) / 2)
            panel:drawText(sm.label, tabX + padH, textY,
                T.toneNorm.r, T.toneNorm.g, T.toneNorm.b, T.toneNorm.a or 1, T.fontF1)
        end

        zones[#zones + 1] = { x = tabX, y = y, w = tw, h = tH, id = sm.id }
        tabX = tabX + tw + gap
    end

    win._animalsSubmodeZones = zones
    return tH
end

-- ============================================================================
-- BREADCRUMB — back arrow + location
-- ============================================================================

local function drawBreadcrumb(panel, win, x, y, w)
    local T = ZeD.T
    local A = ZeD.Atoms
    local state = getState(win)
    local font = T.fontF5 or ZeD.T.fontF2
    local pad = T.px(6)

    -- S109: gamepad focus cue painted FIRST so text + triangle render on top.
    if _gpFocusMatches(win, function(el) return el.isBreadcrumb end) then
        _paintGpCue(panel, x, y, w, T.px(BREADCRUMB_H))
    end

    -- Back triangle
    local triSz = T.px(8)
    local triY = y + math.floor((T.px(BREADCRUMB_H) - triSz) / 2)
    A.drawTriangleLeft(panel, x + pad, triY, triSz, { r = T.accent.r, g = T.accent.g, b = T.accent.b, a = 0.9 })   -- colour table, not four numbers

    -- Label
    local label = ""
    if state.view == "animal" and state.zoneName then
        label = state.zoneName
    elseif state.view == "zone" then
        label = "Overview"
    end

    local tx = x + pad + triSz + T.px(6)
    local fh = ZeD.TM:getFontHeight(font)
    panel:drawText(label, tx, y + math.floor((T.px(BREADCRUMB_H) - fh) / 2),
        T.accent.r, T.accent.g, T.accent.b, 0.9, font)

    -- Bottom divider (matches column header)
    A.drawDividerH(panel, x, y + T.px(BREADCRUMB_H) - T.px(1), w, true)

    -- Store click zone for back navigation
    win._animalsBreadcrumbZone = { x = x, y = y, w = w, h = T.px(BREADCRUMB_H) }

    return T.px(BREADCRUMB_H)
end

-- ============================================================================
-- ============================================================================
-- CATEGORY HEADER — matches inventory list category rows exactly.
-- surf2 bg, fontF1 mono, toneLo color, "v NAME (N)" format, soft divider.
-- Returns: catHdrH consumed.
-- ============================================================================

local function drawCatHeader(panel, x, y, w, name, count, expanded, hovered, noArrow)
    local T = ZeD.T
    local A = ZeD.Atoms
    local tm = ZeD.TM
    local catH = T.sp.colHdrH or T.px(20)  -- matches inventory column header (20px)
    local font = T.fontF1 or ZeD.T.fontF2
    local fh = tm:getFontHeight(font)

    -- Background (surf2, or subtle hover highlight)
    if hovered and not noArrow then
        panel:drawRect(x, y, w, catH, 0.06, T.text.r, T.text.g, T.text.b)
    else
        local s2 = T.surf2
        panel:drawRect(x, y, w, catH, s2.a, s2.r, s2.g, s2.b)
    end

    -- Label: "v NAME (N)" or "> NAME (N)" — or no arrow
    local label = ""
    if not noArrow then
        label = expanded and "v " or "> "
    end
    label = label .. string.upper(name)
    if count then label = label .. " (" .. tostring(count) .. ")" end

    local textY = y + math.floor((catH - fh) / 2)
    local col = T.toneLo
    A.drawSecondary(panel, label, x + T.px(6), textY, col)

    -- Soft divider at bottom
    A.drawDividerH(panel, x, y + catH - T.px(1), w, false)

    return catH
end

-- ============================================================================
-- M-ALERT — ALERT ROW
-- Portrait icon + animal name + species + severity badge.
-- Row height = 36px. Clickable (navigates to animal detail in future).
-- ============================================================================

local ALERT_ROW_H = 36
local ALERT_ICON_SZ = 24
local ALERT_PAD = 6

local SEV_VARIANT = {
    danger = "danger",
    warn   = "warning",
    info   = "info",
}

local ALERT_LABELS = {
    udder_urgent = "UDDER",
    ready_milk   = "MILK",
    ready_shear  = "SHEAR",
    thirsty      = "THIRSTY",
    hungry       = "HUNGRY",
    stressed     = "STRESSED",
    lost_mother  = "ORPHAN",
}

local function drawAlertRow(panel, x, y, w, alert)
    local T = ZeD.T
    local A = ZeD.Atoms
    local ad = AD()
    local animal = alert.animal

    -- Row background (subtle hover surface)
    panel:drawRect(x, y, w, T.px(ALERT_ROW_H), 0.04, 1, 1, 1)

    -- Portrait icon
    local portraitPath = ad.resolvePortrait(animal)
    local tex = getTexture(portraitPath)
    local iconY = y + math.floor((T.px(ALERT_ROW_H) - T.px(ALERT_ICON_SZ)) / 2)
    if tex then
        panel:drawTextureScaledAspect(tex, x + T.px(ALERT_PAD), iconY, T.px(ALERT_ICON_SZ), T.px(ALERT_ICON_SZ), 0.9, 1, 1, 1)
    end

    -- Name + species
    local nameX = x + T.px(ALERT_PAD) + T.px(ALERT_ICON_SZ) + T.px(ALERT_PAD)
    local name = ad.getDisplayName(animal)
    local atype = ad.getAnimalType(animal)
    local species = getText("IGUI_AnimalType_" .. atype) or atype

    local nameFont = T.fontF2 or ZeD.T.fontF2
    local secFont = T.fontF4 or ZeD.T.fontF2
    local nameH = ZeD.TM:getFontHeight(nameFont)
    local secH = ZeD.TM:getFontHeight(secFont)
    local textBlockH = nameH + secH
    local textY = y + math.floor((T.px(ALERT_ROW_H) - textBlockH) / 2)

    panel:drawText(name, nameX, textY, T.text.r, T.text.g, T.text.b, 1.0, nameFont)
    panel:drawText(species, nameX, textY + nameH, T.textDim.r, T.textDim.g, T.textDim.b, 0.6, secFont)

    -- Severity badge (right-aligned)
    local badgeLabel = ALERT_LABELS[alert.alertType] or "ALERT"
    local variant = SEV_VARIANT[alert.severity] or "info"
    local badgeFont = T.fontF4 or ZeD.T.fontF2
    local badgeW = ZeD.TM:MeasureStringX(badgeFont, badgeLabel) + (T.sp.badgePadX or T.px(4)) * 2
    local badgeH = ZeD.TM:getFontHeight(badgeFont) + (T.sp.badgePadY or T.px(2)) * 2
    local badgeX = x + w - badgeW - T.px(ALERT_PAD)
    local badgeY = y + math.floor((T.px(ALERT_ROW_H) - badgeH) / 2)
    A.drawBadge(panel, badgeLabel, badgeX, badgeY, variant, false, badgeFont, true)

    -- Bottom divider
    A.drawDividerH(panel, x, y + T.px(ALERT_ROW_H) - T.px(1), w, false)

    return T.px(ALERT_ROW_H)
end
-- ============================================================================
-- M-ZRSUM — ZONE SUMMARY CARD
-- Zone name + animal count + species breakdown + 3 mini-meters (food/water/roof)
-- + male aggression warning. Clickable → navigate to zone view.
-- Returns: cardH consumed.
-- ============================================================================

local ZCARD_PAD    = 6
local ZCARD_MIN_H  = 52

-- S109a: measure cardH ahead of the draw pass so bg + gamepad focus cue can
-- cover the full card area (previously both were clamped to ZCARD_MIN_H,
-- leaving a strip of un-cued card below the bars — visible on focus).
local function measureZoneCardH(summary)
    local T = ZeD.T
    local tm = ZeD.TM
    local nameH  = tm:getFontHeight(T.fontF2 or ZeD.T.fontF2)
    local specH  = tm:getFontHeight(T.fontF4 or ZeD.T.fontF2)
    local lblH   = tm:getFontHeight(T.fontF1 or ZeD.T.fontF2)
    local fillBarH = T.fillBarH or T.px(8)

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

    -- S109a: pre-measured cardH so bg + focus cue cover the true card area.
    local cardH = measureZoneCardH(summary)

    -- Card background (draw first — PZ immediate mode, call order = paint order)
    local cardBg = T.surf2 or T.surf1
    panel:drawRect(x, y, w, cardH, 0.06, cardBg.r, cardBg.g, cardBg.b)

    -- S109: gamepad focus cue painted over card bg (below content draws).
    if _gpFocusMatches(win, function(el)
            return el.isZoneCard and el.zoneName == summary.name
        end) then
        _paintGpCue(panel, x, y, w, cardH)
    end

    local curY = y + T.px(ZCARD_PAD)

    -- Zone name (left) + count (right)
    local nameFont = T.fontF2 or ZeD.T.fontF2
    local nameH = ZeD.TM:getFontHeight(nameFont)
    local name = summary.name or "Unnamed Zone"
    panel:drawText(name, x + T.px(ZCARD_PAD), curY, T.text.r, T.text.g, T.text.b, 1.0, nameFont)

    local countStr = tostring(summary.count or 0)
    local countFont = T.fontF3 or ZeD.T.fontF2
    local countW = ZeD.TM:MeasureStringX(countFont, countStr)
    panel:drawText(countStr, x + w - T.px(ZCARD_PAD) - countW, curY,
        T.accent.r, T.accent.g, T.accent.b, 1.0, countFont)
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
        table.insert(specParts, tostring(cnt) .. " " .. label)
    end
    if #specParts > 0 then
        local specLine = table.concat(specParts, ", ")
        local specFont = T.fontF4 or ZeD.T.fontF2
        panel:drawText(specLine, x + T.px(ZCARD_PAD), curY,
            T.textDim.r, T.textDim.g, T.textDim.b, 0.6, specFont)
        curY = curY + ZeD.TM:getFontHeight(specFont) + T.px(4)
    end

    -- Status bars — 3 across on one line: LABEL above, fill bar below, 8px gap between
    local M = ZeD.Molecules
    local tm = ZeD.TM
    local barGap = T.px(8)
    local barPad = T.px(ZCARD_PAD)
    local totalBarW = w - barPad * 2
    local barW = math.floor((totalBarW - barGap * 2) / 3)
    local fillBarH = T.fillBarH
    local lblFont = T.fontF1 or ZeD.T.fontF2
    local lblH = tm:getFontHeight(lblFont)
    local lblColor = T.textSec or T.textDim

    local foodRatio  = (summary.food or 0) / 100
    local waterRatio = (summary.water or 0) / 100
    local roofRatio  = (summary.roof or 0) / 100

    local bars = {
        { label = "FOOD",  ratio = foodRatio },
        { label = "WATER", ratio = waterRatio },
        { label = "ROOF",  ratio = roofRatio },
    }

    local bx = x + barPad
    for _, bar in ipairs(bars) do
        -- Label on top
        A.drawSecondary(panel, bar.label, bx, curY, lblColor)
        -- Percentage right-aligned on top
        local pct = math.floor(bar.ratio * 100) .. "%"
        local pctW = tm:MeasureStringX(lblFont, pct)
        panel:drawText(pct, bx + barW - pctW, curY, T.text.r, T.text.g, T.text.b, 0.7, lblFont)
        -- Fill bar below label
        M.drawFillBar(panel, bx, curY + lblH + T.px(2), barW, bar.ratio)
        bx = bx + barW + barGap
    end
    curY = curY + lblH + T.px(2) + fillBarH + T.px(4)

    -- Male aggression warnings
    if #(summary.maleWarnings or {}) > 0 then
        for _, atype in ipairs(summary.maleWarnings) do
            local warnLabel = getText("IGUI_AnimalType_" .. atype) or atype
            A.drawBadge(panel, warnLabel .. " MALES", x + T.px(ZCARD_PAD), curY, "warning", false, T.fontF5 or ZeD.T.fontF2, true)
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

    local statFont = T.fontF3 or ZeD.T.fontF2
    local lblFont = T.fontF4 or ZeD.T.fontF2
    local rowH = ZeD.TM:getFontHeight(statFont) + T.px(4)
    local colW = math.floor((w - pad) / 2)

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

        panel:drawText(valStr, leftX, leftY, T.accent.r, T.accent.g, T.accent.b, 1.0, statFont)
        local valW = ZeD.TM:MeasureStringX(statFont, valStr)
        panel:drawText(label, leftX + valW + T.px(6), leftY + T.px(1), T.textDim.r, T.textDim.g, T.textDim.b, 0.7, lblFont)
        leftY = leftY + rowH
    end

    -- Right column: production estimates
    local rightX = x + colW + pad
    local rightY = curY

    if totals.eggsPerDay and totals.eggsPerDay > 0 then
        local eggStr = string.format("%.1f", totals.eggsPerDay)
        panel:drawText(eggStr, rightX, rightY, T.accent.r, T.accent.g, T.accent.b, 1.0, statFont)
        local eW = ZeD.TM:MeasureStringX(statFont, eggStr)
        panel:drawText("eggs/day", rightX + eW + T.px(6), rightY + T.px(1), T.textDim.r, T.textDim.g, T.textDim.b, 0.7, lblFont)
        rightY = rightY + rowH
    end

    if totals.milkPerDay and totals.milkPerDay > 0 then
        local milkStr = string.format("%.0f", totals.milkPerDay)
        panel:drawText(milkStr, rightX, rightY, T.accent.r, T.accent.g, T.accent.b, 1.0, statFont)
        local mW = ZeD.TM:MeasureStringX(statFont, milkStr)
        panel:drawText("milk/day", rightX + mW + T.px(6), rightY + T.px(1), T.textDim.r, T.textDim.g, T.textDim.b, 0.7, lblFont)
        rightY = rightY + rowH
    end

    local totalH = math.max(leftY, rightY) - curY
    return math.max(rowH, totalH)
end

-- ============================================================================
-- O-ANOVW — RANCH OVERVIEW ORGANISM
-- Composes: Alerts section → Zones section → Totals section.
-- Reads all data from AlertPoller cache. Collapsible sections.
-- ============================================================================

local function renderRanchOverview(panel, win, x, y, w, h)
    -- Force cache refresh on first render
    if not AP().isReady() then AP().refreshCache() end

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

    -- Reset click zones
    win._animalsZoneCardZones = {}
    win._animalsSectionZones = {}

    local curY = y  -- header sits flush against tab strip bottom

    local catH = T.sp.colHdrH or T.px(20)  -- 20px, matches inventory column header

    -- ── ALERTS SECTION ──
    local alerts = AP().getAlerts()
    if #alerts > 0 then
        local secY = curY
        local mx = panel:getMouseX()
        local my = panel:getMouseY()
        local hovered = mx >= x and mx < x + w and my >= curY and my < curY + catH
        drawCatHeader(panel, x, curY, w, "Alerts", #alerts, ovState.alertsExpanded, hovered)
        -- S109: gamepad focus cue painted AFTER header (surf2 bg is 0.92α,
        -- would dim cue to invisibility if painted under). Text + chevron
        -- render at ~45% visibility through the 0.55α overlay — legible.
        if _gpFocusMatches(win, function(el)
                return el.isDisclosure and el.sectionKey == "alertsExpanded"
            end) then
            _paintGpCue(panel, x, curY, w, catH)
        end
        table.insert(win._animalsSectionZones, {
            x = x, y = secY, w = w, h = catH, key = "alertsExpanded"
        })
        curY = curY + catH

        if ovState.alertsExpanded then
            for _, alert in ipairs(alerts) do
                curY = curY + drawAlertRow(panel, x + pad, curY, w - pad * 2, alert)
            end
        end
    end

    -- ── ZONES SECTION ──
    local secY = curY
    local mx = panel:getMouseX()
    local my = panel:getMouseY()
    local hovered = mx >= x and mx < x + w and my >= curY and my < curY + catH
    drawCatHeader(panel, x, curY, w, "Zones", #zones, true, false, true)
    table.insert(win._animalsSectionZones, {
        x = x, y = secY, w = w, h = catH, key = "zonesExpanded"
    })
    curY = curY + catH

    if ovState.zonesExpanded then
        for _, zone in ipairs(zones) do
            -- Get zone name for name-based cache lookup
            local zname = ""
            if zone.getName then
                local ok, val = pcall(zone.getName, zone)
                if ok and val then zname = val end
            end
            local summary = AP().getZoneSummary(zname)
            if summary then
                curY = curY + drawZoneSummary(panel, x + pad, curY, w - pad * 2, summary, win)
            end
        end
    end

    -- ── TOTALS SECTION ──
    local totals = AP().getTotals()
    if totals and (totals.totalAnimals or 0) > 0 then
        secY = curY
        hovered = mx >= x and mx < x + w and my >= curY and my < curY + catH
        drawCatHeader(panel, x, curY, w, "Totals", totals.totalAnimals, ovState.totalsExpanded, hovered)
        -- S109: gamepad focus cue painted AFTER (see alerts comment above).
        if _gpFocusMatches(win, function(el)
                return el.isDisclosure and el.sectionKey == "totalsExpanded"
            end) then
            _paintGpCue(panel, x, curY, w, catH)
        end
        table.insert(win._animalsSectionZones, {
            x = x, y = secY, w = w, h = catH, key = "totalsExpanded"
        })
        curY = curY + catH

        if ovState.totalsExpanded then
            curY = curY + drawTotals(panel, x + pad, curY, w - pad * 2, totals)
        end
    end

    win._animalsContentH = curY - y
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
    local nameFont = T.fontF2 or ZeD.T.fontF2
    local nameH = tm:getFontHeight(nameFont)
    local name = summary.name or "Unnamed Zone"

    if win._animalsRenaming and win._animalsRenameEntry then
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
        -- Draw name as clickable text (hover underline hint)
        local mx = panel:getMouseX()
        local my = panel:getMouseY()
        local nameW = tm:MeasureStringX(nameFont, name)
        local nameHovered = mx >= x + pad and mx < x + pad + nameW
            and my >= curY and my < curY + nameH
        local nameCol = nameHovered and T.accent or T.text
        panel:drawText(name, x + pad, curY, nameCol.r, nameCol.g, nameCol.b, 1.0, nameFont)

        -- Store name click zone for rename trigger
        win._animalsZoneNameZone = { x = x + pad, y = curY, w = nameW, h = nameH }

        -- Hide entry if not renaming
        if win._animalsRenameEntry then
            win._animalsRenameEntry:setVisible(false)
        end
    end

    local countStr = tostring(summary.count or 0) .. " animals"
    local countFont = T.fontF3 or ZeD.T.fontF2
    local countW = tm:MeasureStringX(countFont, countStr)
    panel:drawText(countStr, x + w - pad - countW, curY,
        T.accent.r, T.accent.g, T.accent.b, 0.9, countFont)
    -- Zone size (on same line as name, after count)
    local zoneObj = summary.zone
    if zoneObj and zoneObj.getW and zoneObj.getH then
        local ok1, zw = pcall(zoneObj.getW, zoneObj)
        local ok2, zh = pcall(zoneObj.getH, zoneObj)
        if ok1 and ok2 then
            local sizeStr = tostring(zw * zh) .. " sq."
            local sizeFont = T.fontF5 or ZeD.T.fontF2
            panel:drawText(sizeStr, x + pad + tm:MeasureStringX(nameFont, name) + T.px(8),
                curY + T.px(2), T.textDim.r, T.textDim.g, T.textDim.b, 0.5, sizeFont)
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
        table.insert(specParts, tostring(cnt) .. " " .. label)
    end
    if #specParts > 0 then
        local specLine = table.concat(specParts, ", ")
        local specFont = T.fontF5 or ZeD.T.fontF2
        panel:drawText(specLine, x + pad, curY,
            T.textDim.r, T.textDim.g, T.textDim.b, 0.6, specFont)
        curY = curY + tm:getFontHeight(specFont) + T.px(6)
    end

    -- Status bars — 3 across, label+% on top, fill bar below, 8px gap (same as overview card)
    local M = ZeD.Molecules
    local barGap = T.px(8)
    local totalBarW = w - pad * 2
    local barW = math.floor((totalBarW - barGap * 2) / 3)
    local fillBarH = T.fillBarH
    local lblFont = T.fontF1 or ZeD.T.fontF2
    local lblH = tm:getFontHeight(lblFont)
    local lblColor = T.textSec or T.textDim

    local foodRatio  = (summary.food or 0) / 100
    local waterRatio = (summary.water or 0) / 100
    local roofRatio  = (summary.roof or 0) / 100

    local bars = {
        { label = "FOOD",  ratio = foodRatio },
        { label = "WATER", ratio = waterRatio },
        { label = "ROOF",  ratio = roofRatio },
    }

    local bx = x + pad
    for _, bar in ipairs(bars) do
        A.drawSecondary(panel, bar.label, bx, curY, lblColor)
        local pct = math.floor(bar.ratio * 100) .. "%"
        local pctW = tm:MeasureStringX(lblFont, pct)
        panel:drawText(pct, bx + barW - pctW, curY, T.text.r, T.text.g, T.text.b, 0.7, lblFont)
        M.drawFillBar(panel, bx, curY + lblH + T.px(2), barW, bar.ratio)
        bx = bx + barW + barGap
    end
    curY = curY + lblH + T.px(2) + fillBarH + T.px(4)

    -- Male aggression warnings
    if #(summary.maleWarnings or {}) > 0 then
        for _, atype in ipairs(summary.maleWarnings) do
            local warnLabel = (getText("IGUI_AnimalType_" .. atype) or atype) .. " MALES"
            A.drawBadge(panel, warnLabel, x + pad, curY, "warning", false, T.fontF5 or ZeD.T.fontF2, true)
            curY = curY + T.px(18)
        end
    end

    local bandH = (curY - y) + pad

    -- Bottom groove divider
    A.drawDividerH(panel, x, y + bandH - T.px(1), w, true)

    return bandH
end

-- ============================================================================
-- M-AROW — ANIMAL ROSTER ROW (48px)
-- Portrait (32px) + name + 3 stat dots + condition badges (top line)
-- Species + sex + age text (bottom line)
-- Returns: AROW_H consumed.
-- ============================================================================

local function drawAnimalRow(panel, x, y, w, animal, player, hovered)
    local T = ZeD.T
    local A = ZeD.Atoms
    local ad = AD()
    local tm = ZeD.TM

    -- Hover highlight
    if hovered then
        local hc = T.hover
        panel:drawRect(x, y, w, T.px(AROW_H), hc.a or 0.08, hc.r, hc.g, hc.b)
    end

    -- Portrait icon (32px, vertically centered)
    local portraitPath = ad.resolvePortrait(animal)
    local tex = getTexture(portraitPath)
    local iconY = y + math.floor((T.px(AROW_H) - T.px(AROW_ICON_SZ)) / 2)
    if tex then
        panel:drawTextureScaledAspect(tex, x + T.px(AROW_PAD), iconY, T.px(AROW_ICON_SZ), T.px(AROW_ICON_SZ), 0.9, 1, 1, 1)
    end

    -- === TOP LINE (y + 4px) ===
    local topY = y + T.px(4)
    local textX = x + T.px(AROW_PAD) + T.px(AROW_ICON_SZ) + T.px(AROW_PAD)

    -- Name
    local nameFont = T.fontF2 or ZeD.T.fontF2
    local name = ad.getDisplayName(animal)
    panel:drawText(name, textX, topY, T.text.r, T.text.g, T.text.b, 1.0, nameFont)
    local nameW = tm:MeasureStringX(nameFont, name)

    -- 3 stat dots (Health / Hunger / Thirst) — after name with gap
    local dotX = textX + nameW + T.px(10)
    local dotY = topY + math.floor((tm:getFontHeight(nameFont) - T.px(AROW_DOT_SZ)) / 2)

    -- Health: high = good (green), low = bad (red)
    local health = ad.getHealth(animal)
    A.drawStatusDot(panel, dotX, dotY, dotColorForValue(T, health), T.px(AROW_DOT_SZ))
    dotX = dotX + T.px(AROW_DOT_SZ) + T.px(AROW_DOT_GAP)

    -- Hunger: INVERTED — high value means MORE hungry (bad), low = fed (good)
    local hunger = ad.getHunger(animal)
    A.drawStatusDot(panel, dotX, dotY, dotColorForValue(T, 100 - hunger), T.px(AROW_DOT_SZ))
    dotX = dotX + T.px(AROW_DOT_SZ) + T.px(AROW_DOT_GAP)

    -- Thirst: INVERTED — high value means MORE thirsty (bad), low = hydrated (good)
    local thirst = ad.getThirst(animal)
    A.drawStatusDot(panel, dotX, dotY, dotColorForValue(T, 100 - thirst), T.px(AROW_DOT_SZ))

    -- Condition badges (right-aligned)
    local tags = ad.getConditionTags(animal, player)
    local badgeFont = T.fontF5 or ZeD.T.fontF2
    local badgePadX = T.sp and T.sp.badgePadX or T.px(4)
    local badgeX = x + w - T.px(AROW_PAD)
    for i = #tags, 1, -1 do
        local tag = tags[i]
        local variant = tag.sev
        if variant == "good" then variant = "positive" end
        -- Measure badge width without drawing (text width + 2× padding)
        local badgeText = string.upper(tag.label)
        local bw = tm:MeasureStringX(badgeFont, badgeText) + badgePadX * 2
        badgeX = badgeX - bw - T.px(4)
        A.drawBadge(panel, tag.label, badgeX, topY, variant, false, badgeFont, true)
    end

    -- === BOTTOM LINE (y + 28px) ===
    local botY = y + T.px(28)
    local secFont = T.fontF5 or ZeD.T.fontF2

    -- Species + sex + age
    local atype = ad.getAnimalType(animal)
    local species = getText("IGUI_AnimalType_" .. atype) or atype
    local sex = ad.isFemale(animal) and "Female" or "Male"
    if ad.isBaby(animal) then sex = "Baby" end
    local age = ad.getAgeText(animal, player)
    local infoLine = species .. ", " .. sex
    if age and age ~= "" then infoLine = infoLine .. " | " .. age end

    panel:drawText(infoLine, textX, botY, T.textDim.r, T.textDim.g, T.textDim.b, 0.6, secFont)

    -- Bottom divider
    A.drawDividerH(panel, x, y + T.px(AROW_H) - T.px(1), w, false)

    return T.px(AROW_H)
end

-- ============================================================================
-- M-STRUCT — HUTCHES / FEEDING TROUGHS / HOOKS rows (HOOK_MAP 20-22)
-- One 34px row per structure: tile icon, name, a line of state, a badge and
-- OPEN (the object card; walks there first when it is out of reach).
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
        sub = tostring(inside and inside:size() or 0) .. " / " .. tostring(ocall(o, "getMaxAnimals") or 20) .. " BIRDS | "
            .. eggs .. " EGGS | DIRT " .. math.floor((ocall(o, "getHutchDirt") or 0) + 0.5) .. "%"
        -- which door is open (the OPEN button beside it opens the card)
        if ocall(o, "isOpen") then badge, variant = "Door open", "positive"
        elseif ocall(o, "isEggHatchDoorOpen") then badge, variant = "Hatch open", "positive"
        else badge, variant = "Shut", "neutral" end
    elseif kind == "trough" then
        name = moveableName(o, getTextOrNull("ContextMenu_FeedingTrough") or "Feeding Trough")
        local cont = ocall(o, "getContainer")
        local wl = ocall(o, "getWater") or 0
        if cont and not cont:getItems():isEmpty() then
            sub = string.format("FEED %.1f", ocall(o, "getCurrentFeedAmount") or 0); badge, variant = "Food", "positive"
        elseif wl > 0 then
            sub = string.format("WATER %.1f / %.1f L", wl, ocall(o, "getMaxWater") or 0); badge, variant = "Water", "info"
        else
            sub = "EMPTY"; badge, variant = "Empty", "neutral"
        end
        local linked = ocall(o, "getLinkedAnimals")
        sub = sub .. " | " .. tostring(linked and linked:size() or 0) .. " ANIMALS"
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
            if md["leather"] then parts[#parts + 1] = "LEATHER" end
            local blood = tonumber(md["BloodQty"]) or 0
            if blood > 0 then parts[#parts + 1] = string.format("BLOOD %.1f L", blood) end
            if not md["headless"] then parts[#parts + 1] = "HEAD" end
            if md["parts"] then parts[#parts + 1] = "MEAT" end
            sub = (#parts > 0 and (table.concat(parts, " | ") .. " LEFT") or "NOTHING LEFT") .. " | " .. dist .. " TILES"
            if ocall(o, "isRemovingBlood") then
                badge, variant = "Bleeding", "warning"
                prog = ocall(o, "getRemovingBloodProgress") or 0
            else
                badge, variant = "On hook", "positive"
            end
        else
            sub = tostring(dist) .. " TILES"
            badge, variant = "Empty", "neutral"
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

local function drawStructRow(panel, win, x, y, w, kind, o, idx, player)
    local T = ZeD.T
    local A = ZeD.Atoms
    local tm = ZeD.TM
    local h = T.px(STRUCT_H)
    if _gpFocusMatches(win, function(el) return el.isStruct and el.structIdx == idx end) then
        _paintGpCue(panel, x, y, w, h)
    end
    local name, sub, badge, variant, prog = structInfo(kind, o, player)
    local pad = T.px(AROW_PAD)
    local isz = T.px(22)
    local tex
    if kind == "hook" and ocall(o, "getAnimal") and AD().resolvePortrait then
        tex = getTexture(AD().resolvePortrait(o:getAnimal()))
    else
        tex = ZeD.ObjectCards and ZeD.ObjectCards.spriteIcon(o)
    end
    if tex then panel:drawTextureScaledAspect(tex, x + pad, y + math.floor((h - isz) / 2), isz, isz, 1, 1, 1, 1) end
    -- OPEN (right)
    local bf = T.fontF5 or T.fontF2
    local bw = tm:MeasureStringX(bf, "Open") + T.px(16)
    local bx = x + w - pad - bw
    local by = y + math.floor((h - T.px(BTN_H)) / 2)
    local rect = drawBtn(panel, bx, by, "Open", "neutral", bf)
    -- badge (and the bleed bar for a hook)
    local rx = bx - T.px(8)
    local badgePadX = T.sp and T.sp.badgePadX or T.px(4)
    if prog then
        local pw = T.px(60)
        rx = rx - pw
        local py = y + math.floor((h - T.px(6)) / 2)
        panel:drawRect(rx, py, pw, T.px(6), 1, T.surf1.r, T.surf1.g, T.surf1.b)
        panel:drawRect(rx, py, math.floor(pw * math.max(0, math.min(1, prog))), T.px(6), 1, T.accent.r, T.accent.g, T.accent.b)
        rx = rx - T.px(6)
    end
    if badge then
        local bwid = tm:MeasureStringX(bf, string.upper(badge)) + badgePadX * 2
        rx = rx - bwid
        A.drawBadge(panel, badge, rx, y + math.floor((h - tm:getFontHeight(bf)) / 2) - T.px(2), variant, false, bf, true)
        rx = rx - T.px(8)
    end
    local nx = x + pad + isz + T.px(8)
    local f2 = T.fontF2
    local ny = y + math.floor((h - tm:getFontHeight(f2) - tm:getFontHeight(bf)) / 2)
    local trunc = ZeD.CraftingCore and ZeD.CraftingCore.truncText or function(s) return s end
    panel:drawText(trunc(name, f2, rx - nx), nx, ny, T.text.r, T.text.g, T.text.b, 1, f2)
    panel:drawText(trunc(sub, bf, rx - nx), nx, ny + tm:getFontHeight(f2), T.textDim.r, T.textDim.g, T.textDim.b, 0.7, bf)
    A.drawDividerH(panel, x, y + h - T.px(1), w, false)
    win._animalsStructZones[#win._animalsStructZones + 1] = { x = x, y = y, w = w, h = h, kind = kind, obj = o, idx = idx, btn = rect }
    return h
end

-- the zone's hutches and troughs, pinned under the info band
local function drawZoneStructs(panel, win, x, y, w, summary, player)
    local T = ZeD.T
    local y0 = y
    local catH = T.sp.colHdrH or T.px(20)
    local idx = 0
    for _, g in ipairs({ { kind = "hutch", label = "Hutches", list = summary.hutches or {} },
                         { kind = "trough", label = "Feeding Troughs", list = summary.troughs or {} } }) do
        if #g.list > 0 then
            drawCatHeader(panel, x, y, w, g.label, #g.list, true, false, true)
            y = y + catH
            for _, o in ipairs(g.list) do
                idx = idx + 1
                y = y + drawStructRow(panel, win, x, y, w, g.kind, o, idx, player)
            end
        end
    end
    return y - y0
end

-- butcher hooks around you (scanned every two seconds)
local HOOK_SCAN_R = 20
local function hooksNear(win, player)
    local now = getTimestampMs()
    local c = win._animalsHookScan
    if c and now - c.t < 2000 then return c.list end
    local list = {}
    local sq0 = player and player:getCurrentSquare()
    if sq0 then
        local cell = getCell()
        for yy = sq0:getY() - HOOK_SCAN_R, sq0:getY() + HOOK_SCAN_R do
            for xx = sq0:getX() - HOOK_SCAN_R, sq0:getX() + HOOK_SCAN_R do
                local sq = cell:getGridSquare(xx, yy, sq0:getZ())
                if sq then
                    local objs = sq:getObjects()
                    for i = 0, objs:size() - 1 do
                        local o = objs:get(i)
                        if instanceof(o, "IsoButcherHook") then list[#list + 1] = o end
                    end
                end
            end
        end
    end
    -- nearest first
    if player then
        local function d2(o) local s = o:getSquare(); return (s:getX() - player:getX()) ^ 2 + (s:getY() - player:getY()) ^ 2 end
        table.sort(list, function(a, b) return d2(a) < d2(b) end)
    end
    win._animalsHookScan = { t = now, list = list }
    return list
end

local function drawHooks(panel, win, x, y, w, player)
    local T = ZeD.T
    local hooks = hooksNear(win, player)
    if #hooks == 0 then return 0 end
    local y0 = y
    drawCatHeader(panel, x, y, w, "Hooks", #hooks, true, false, true)
    y = y + (T.sp.colHdrH or T.px(20))
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
    local T = ZeD.T
    local h = T.px(STRUCT_H)
    if _gpFocusMatches(win, function(el) return el.isHutchLink end) then _paintGpCue(panel, x, y, w, h) end
    win._animalsStructZones = {}
    local hh = drawStructRow(panel, win, x, y, w, "hutch", hutch, 1, player)
    win._animalsHutchLink = win._animalsStructZones[1]
    win._animalsStructZones = {}
    return hh
end

-- ============================================================================
-- GENOME (debug: animal cheats only, as vanilla's Modify Genome)
-- Each gene's two alleles: value (and what passes to offspring), which one is
-- used, dominant, disorder. Pick an allele, then -/+ 0.05, DOMINANT, SWITCH
-- (which allele is used) or DISORDER (cycles vanilla's list).
-- ============================================================================
local GENE_H = 24

-- the engine names genes in lower case ("maxweight"): vanilla's 19, worded
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
    local tm = ZeD.TM
    local y0 = y
    win._animalsGenomeZones = {}
    local sel = win._animalsGenomeSel
    -- header
    local hdrFont = T.fontF1
    local info = T.info or T.accent
    panel:drawText("GENOME", x, y, info.r, info.g, info.b, 1, hdrFont)
    local tagX = x + tm:MeasureStringX(hdrFont, "GENOME") + T.px(8)
    A.drawBadge(panel, "Animal cheats", tagX, y - T.px(2), "info", false, T.fontF5 or hdrFont, true)
    A.drawDividerH(panel, x, y + T.px(20) - T.px(1), w, false)
    y = y + T.px(22)
    local colN = T.px(110)
    local colA = math.floor((w - colN - T.px(90)) / 2)
    local f3, f5 = T.fontF3, T.fontF5 or T.fontF2
    for gi = 0, list:size() - 1 do
        local gene = list:get(gi)
        local h = T.px(GENE_H)
        panel:drawText(geneLabel(ocall(gene, "getName")), x + T.px(2), y + math.floor((h - tm:getFontHeight(T.fontF2)) / 2), T.text.r, T.text.g, T.text.b, 1, T.fontF2)
        local dis = nil
        for k = 1, 2 do
            local al = ocall(gene, k == 1 and "getAllele1" or "getAllele2")
            if al then
                local ax = x + colN + (k - 1) * colA
                local isSel = sel and sel.gene == gi and sel.allele == k
                local gpSel = _gpFocusMatches(win, function(el) return el.isGenome and el.gene == gi and el.allele == k end)
                if isSel or gpSel then _paintGpCue(panel, ax, y + T.px(2), colA - T.px(6), h - T.px(4)) end
                local cur = ocall(al, "getCurrentValue") or 0
                local tr = ocall(al, "getTrueRatioValue") or 0
                local v = (tr > 0) and string.format("%.2f (%.2f)", tr, cur) or string.format("%.2f", cur)
                local used = ocall(al, "isUsed") == true
                local dy = y + math.floor((h - T.px(6)) / 2)
                if used then A.drawStatusDot(panel, ax + T.px(4), dy, T.positive, T.px(6))
                else A.drawStatusRing(panel, ax + T.px(4), dy, T.textDim, T.px(6)) end
                local vc = used and T.text or T.textDim
                panel:drawText(v, ax + T.px(14), y + math.floor((h - tm:getFontHeight(f3)) / 2), vc.r, vc.g, vc.b, 1, f3)
                if ocall(al, "isDominant") then
                    local dx = ax + T.px(14) + tm:MeasureStringX(f3, v) + T.px(6)
                    panel:drawText("D", dx, y + math.floor((h - tm:getFontHeight(f3)) / 2), T.accent.r, T.accent.g, T.accent.b, 1, f3)
                end
                local d = ocall(al, "getGeneticDisorder")
                if d and d ~= "" then dis = d end
                win._animalsGenomeZones[#win._animalsGenomeZones + 1] = { x = ax, y = y, w = colA - T.px(6), h = h, gene = gi, allele = k, al = al, g = gene }
            end
        end
        if dis then
            A.drawBadge(panel, dis, x + w - T.px(88), y + math.floor((h - tm:getFontHeight(f5)) / 2) - T.px(2), "danger", false, f5, true)
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
    for _, b in ipairs({ { id = "minus", label = "-0.05" }, { id = "plus", label = "+0.05" }, { id = "dominant", label = "Dominant" },
                         { id = "switch", label = "Switch" }, { id = "disorder", label = "Disorder" } }) do
        if _gpFocusMatches(win, function(el) return el.isGenomeBtn and el.btnId == b.id end) then
            local bw = tm:MeasureStringX(f5, b.label) + T.px(16)
            _paintGpCue(panel, bx, y, bw, T.px(BTN_H))
        end
        local r = drawBtn(panel, bx, y, b.label, selAl and "neutral" or "neutral", f5)
        r.id = b.id
        win._animalsGenomeBtns[#win._animalsGenomeBtns + 1] = r
        bx = bx + r.w + T.px(4)
    end
    win._animalsGenomeSelAl = selAl
    y = y + T.px(BTN_H) + T.px(4)
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
-- cycle + scrollable animal roster rows.
-- Replaces Session A stub.
-- ============================================================================

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
    local zoneObj = getZoneByName(state.zoneName)
    if player and zoneObj then
        player:setSeeDesignationZone(true)
        player:resetSelectedZonesForHighlight()
        player:addSelectedZoneForHighlight(zoneObj:getId())
    end

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
    local catH = T.sp.colHdrH or T.px(20)
    drawCatHeader(panel, x, secY, w, "Animals", rosterCount, true, false)

    -- Sort label (right-aligned in category header)
    local sortFont = T.fontF5 or ZeD.T.fontF2
    local sortLabel = SORT_LABELS[zs.sortMode] or "Name"
    local sortText = "Sort: " .. sortLabel
    local sortTextW = tm:MeasureStringX(sortFont, sortText)
    local sortX = x + w - pad - sortTextW
    local sortTY = secY + math.floor((catH - tm:getFontHeight(sortFont)) / 2)
    local sortZoneX = sortX - T.px(4)
    local sortZoneW = sortTextW + T.px(8)
    -- S109: gamepad focus cue painted under sort text.
    if _gpFocusMatches(win, function(el) return el.isSort end) then
        _paintGpCue(panel, sortZoneX, secY, sortZoneW, catH)
    end
    panel:drawText(sortText, sortX, sortTY,
        T.accent.r, T.accent.g, T.accent.b, 0.8, sortFont)
    win._animalsSortZone = { x = sortZoneX, y = secY, w = sortZoneW, h = catH }

    -- ── SCROLLABLE ROSTER ──
    local rosterTop = secY + catH
    local rosterH = h - (rosterTop - y)
    if rosterH <= 0 then return end

    local totalContentH = rosterCount * T.px(AROW_H)
    local maxScroll = math.max(0, totalContentH - rosterH)

    -- S109: gamepad scroll-follow — keep the focused roster row in viewport.
    -- Resolve focused animal via live element (Q95: don't rely on persistent
    -- _gpFocused* as sole source). One-frame lag; imperceptible.
    local gpFocusAnimal = nil
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        if Focus and Focus.getFocusedZone then
            local fz = Focus.getFocusedZone(win)
            if fz and fz.zone == "worldTabContent" then
                local fe = Focus.getFocusedElement and Focus.getFocusedElement(win)
                if fe and fe.isRoster then gpFocusAnimal = fe.animal end
            end
        end
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

    for _, animal in ipairs(sortedAnimals) do
        if rowY + T.px(AROW_H) > rosterTop and rowY < rosterTop + rosterH then
            local isHovered = mx >= x and mx < x + contentW
                and my >= rowY and my < rowY + T.px(AROW_H)
            -- S109: gamepad focus cue painted before row content.
            if animal == gpFocusAnimal then
                _paintGpCue(panel, x + pad, rowY, contentW - pad * 2, T.px(AROW_H))
            end
            drawAnimalRow(panel, x + pad, rowY, contentW - pad * 2, animal, player, isHovered)
            table.insert(win._animalsRosterZones, {
                x = x, y = rowY, w = contentW, h = T.px(AROW_H), animal = animal
            })
        end
        rowY = rowY + T.px(AROW_H)
    end

    panel:clearStencilRect()

    -- Scrollbar (uses A.drawScrollTrack/Thumb if available, else inline)
    if needsScroll then
        local sbX = x + contentW + T.px(2)
        A.drawScrollTrack(panel, sbX, rosterTop, scrollW - T.px(2), rosterH)
        local barH = math.max(T.px(20), math.floor(rosterH * (rosterH / totalContentH)))
        local scrollFrac = maxScroll > 0 and (zs.scrollY / maxScroll) or 0
        local barY = rosterTop + math.floor((rosterH - barH) * scrollFrac)
        A.drawScrollThumb(panel, sbX, barY, scrollW - T.px(2), barH)
    end

    win._animalsRosterScroll = {
        top = rosterTop, h = rosterH, maxScroll = maxScroll, needsScroll = needsScroll
    }
end

-- ============================================================================
-- M-AHEAD — ANIMAL HEADER
-- 48px portrait + name + breed/species/sex + age/weight + condition badges.
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

    -- Name (F2, accent)
    local nameFont = T.fontF2 or ZeD.T.fontF2
    local name = ad.getDisplayName(animal)
    panel:drawText(name, textX, curY, T.accent.r, T.accent.g, T.accent.b, 1.0, nameFont)
    curY = curY + tm:getFontHeight(nameFont) + T.px(2)

    -- Breed + Species + Sex (F4, textDim)
    local secFont = T.fontF4 or ZeD.T.fontF2
    local atype = ad.getAnimalType(animal)
    local species = getText("IGUI_AnimalType_" .. atype) or atype
    local breed = ad.getBreedName(animal)
    local sex = ad.isFemale(animal) and "Female" or "Male"
    if ad.isBaby(animal) then sex = "Baby" end
    local idLine = ""
    if breed and breed ~= "" then idLine = breed .. " " end
    idLine = idLine .. species .. ", " .. sex
    panel:drawText(idLine, textX, curY, T.textDim.r, T.textDim.g, T.textDim.b, 0.7, secFont)
    curY = curY + tm:getFontHeight(secFont) + T.px(2)

    -- Age + Weight (F5, textDim)
    local microFont = T.fontF5 or ZeD.T.fontF2
    local age = ad.getAgeText(animal, player)
    local weight = ad.getWeight(animal)
    local infoLine = ""
    if age and age ~= "" then infoLine = age end
    if ad.canSee(player, "weight_rough") and weight > 0 then
        if infoLine ~= "" then infoLine = infoLine .. "  |  " end
        infoLine = infoLine .. string.format("%.1f kg", weight)
    end
    if infoLine ~= "" then
        panel:drawText(infoLine, textX, curY, T.textDim.r, T.textDim.g, T.textDim.b, 0.6, microFont)
        curY = curY + tm:getFontHeight(microFont) + T.px(4)
    end

    -- Condition badges (horizontal row)
    local tags = ad.getConditionTags(animal, player)
    if #tags > 0 then
        local badgeFont = T.fontF5 or ZeD.T.fontF2
        local bx = textX
        for _, tag in ipairs(tags) do
            local variant = tag.sev
            if variant == "good" then variant = "positive" end
            local bw = A.drawBadge(panel, tag.label, bx, curY, variant, false, badgeFont, true)
            bx = bx + bw + T.px(4)
        end
        curY = curY + tm:getFontHeight(badgeFont) + (T.sp and T.sp.badgePadY or T.px(2)) * 2 + T.px(4)
    end

    local headerH = math.max(T.px(AHEAD_ICON_SZ) + pad * 2, (curY - y) + pad)

    -- Groove divider
    A.drawDividerH(panel, x, y + headerH - T.px(1), w, true)

    return headerH
end

-- ============================================================================
-- M-AVIT — VITAL ROW
-- Label (left) + text/numeric value (middle) + fill bar (right).
-- Text descriptor at Lv0, numeric at Lv3+. Color by threshold.
-- Returns: VITAL_ROW_H consumed.
-- ============================================================================

local function drawVitalRow(panel, x, y, w, label, value, textDesc, numericDesc, canSeeNum, fillRatio, fillColor)
    local T = ZeD.T
    local tm = ZeD.TM

    local lblFont = T.fontF1 or ZeD.T.fontF2
    local valFont = T.fontF3 or ZeD.T.fontF2
    local valY = y + math.floor((T.px(VITAL_ROW_H) - tm:getFontHeight(valFont)) / 2)

    -- Label (left, uppercase, textSec)
    local tc = T.textSec or T.textDim
    panel:drawText(string.upper(label), x, valY, tc.r, tc.g, tc.b, tc.a or 0.7, lblFont)

    -- Fill bar (right-aligned)
    local barX = x + w - T.px(VITAL_BAR_W)
    local barY = y + math.floor((T.px(VITAL_ROW_H) - T.px(VITAL_BAR_H)) / 2)

    -- Bar background
    local bg = T.surf3 or T.surf1
    panel:drawRect(barX, barY, T.px(VITAL_BAR_W), T.px(VITAL_BAR_H), bg.a or 0.3, bg.r, bg.g, bg.b)

    -- Bar fill
    fillRatio = math.max(0, math.min(1, fillRatio or 0))
    if fillRatio > 0 then
        local fillW = math.max(T.px(1), math.floor(T.px(VITAL_BAR_W) * fillRatio))
        panel:drawRect(barX, barY, fillW, T.px(VITAL_BAR_H), (fillColor.a or 1) * 0.7, fillColor.r, fillColor.g, fillColor.b)
    end

    -- Bar border
    local bc = T.border or T.borderS
    panel:drawRectBorder(barX, barY, T.px(VITAL_BAR_W), T.px(VITAL_BAR_H), bc.a or 0.3, bc.r, bc.g, bc.b)

    -- Value text (between label and bar)
    local displayText = canSeeNum and numericDesc or textDesc
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
        panel:drawText(displayText, valX, valY, T.text.r, T.text.g, T.text.b, 0.8, valFont)
    end

    return T.px(VITAL_ROW_H)
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
    local hdrFont = T.fontF1 or ZeD.T.fontF2
    local hdrH = T.px(20)
    local hdrColor = T.textHead or T.textSec
    panel:drawText("VITALS", x, curY, hdrColor.r, hdrColor.g, hdrColor.b, hdrColor.a or 0.8, hdrFont)
    A.drawDividerH(panel, x, curY + hdrH - T.px(1), w, false)
    curY = curY + hdrH + T.px(2)

    local canSeeNum = ad.canSee(player, "health_num")

    -- Health: high = good
    local health = ad.getHealth(animal)
    local healthText = ad.getHealthText(animal, player)
    local healthNum = tostring(math.floor(health)) .. "%"
    local healthRatio = health / 100
    curY = curY + drawVitalRow(panel, x, curY, w, "Health", health,
        healthText, healthNum, canSeeNum, healthRatio, dotColorForValue(T, health))

    -- Hunger: high = hungry (BAD) — invert for display
    local hunger = ad.getHunger(animal)
    local hungerDisplay = 100 - hunger  -- 100=full, 0=starving
    local hungerText = hunger < 20 and "Well-fed" or (hunger < 50 and "Peckish" or (hunger < 80 and "Hungry" or "Starving"))
    local hungerNum = tostring(math.floor(hungerDisplay)) .. "%"
    curY = curY + drawVitalRow(panel, x, curY, w, "Hunger", hungerDisplay,
        hungerText, hungerNum, canSeeNum, hungerDisplay / 100, dotColorForValue(T, hungerDisplay))

    -- Thirst: high = thirsty (BAD) — invert for display
    local thirst = ad.getThirst(animal)
    local thirstDisplay = 100 - thirst
    local thirstText = thirst < 20 and "Hydrated" or (thirst < 50 and "Parched" or (thirst < 80 and "Thirsty" or "Dehydrated"))
    local thirstNum = tostring(math.floor(thirstDisplay)) .. "%"
    curY = curY + drawVitalRow(panel, x, curY, w, "Thirst", thirstDisplay,
        thirstText, thirstNum, canSeeNum, thirstDisplay / 100, dotColorForValue(T, thirstDisplay))

    -- Stress: high = stressed (BAD) — invert for display
    local stress = ad.getStress(animal)
    local stressDisplay = 100 - stress
    local stressText = ad.getStressText(animal, player)
    local stressNum = tostring(math.floor(stressDisplay)) .. "%"
    curY = curY + drawVitalRow(panel, x, curY, w, "Stress", stressDisplay,
        stressText, stressNum, canSeeNum, stressDisplay / 100, dotColorForValue(T, stressDisplay))

    -- Stress sources line (inferred)
    if stress > 10 then
        local sources = si.inferSources(animal, player)
        if #sources > 0 then
            local srcFont = T.fontF5 or ZeD.T.fontF2
            local srcText = "\226\134\146 " .. table.concat(sources, ", ")
            panel:drawText(srcText, x + T.px(4), curY,
                T.textDim.r, T.textDim.g, T.textDim.b, 0.5, srcFont)
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
    local hdrFont = T.fontF1 or ZeD.T.fontF2
    local hdrH = T.px(20)
    local hdrColor = T.textHead or T.textSec
    panel:drawText("PRODUCTION", x, curY, hdrColor.r, hdrColor.g, hdrColor.b, hdrColor.a or 0.8, hdrFont)
    A.drawDividerH(panel, x, curY + hdrH - T.px(1), w, false)
    curY = curY + hdrH + T.px(2)

    -- Milk row
    if maxMilk > 0 then
        local milkQty = ad.getMilkQuantity(animal)
        local milkRatio = maxMilk > 0 and (milkQty / maxMilk) or 0
        local milkText = string.format("%d/%d ml", math.floor(milkQty), math.floor(maxMilk))
        local milkColor = ad.isUdderUrgent(animal) and T.danger or T.positive
        curY = curY + drawVitalRow(panel, x, curY, w, "Milk", milkQty,
            milkText, milkText, true, milkRatio, milkColor)
        hasContent = true
    end

    -- Wool row
    if maxWool > 0 then
        local woolQty = ad.getWoolQuantity(animal)
        local woolRatio = maxWool > 0 and (woolQty / maxWool) or 0
        local woolText = string.format("%d/%d", math.floor(woolQty), math.floor(maxWool))
        curY = curY + drawVitalRow(panel, x, curY, w, "Wool", woolQty,
            woolText, woolText, true, woolRatio, T.positive)
        hasContent = true
    end

    -- Eggs row (text only, no bar)
    if eggsPerDay > 0 then
        local valFont = T.fontF3 or ZeD.T.fontF2
        local lblFont = T.fontF1 or ZeD.T.fontF2
        local rowY = curY + math.floor((T.px(VITAL_ROW_H) - tm:getFontHeight(valFont)) / 2)
        local lblColor = T.textSec or T.textDim
        panel:drawText("EGGS", x, rowY, lblColor.r, lblColor.g, lblColor.b, lblColor.a or 0.7, lblFont)
        local eggText = string.format("%.1f/day", eggsPerDay)
        panel:drawText(eggText, x + T.px(80), rowY, T.text.r, T.text.g, T.text.b, 0.8, valFont)

        -- Laying badge
        if isLayingNow then
            A.drawBadge(panel, "LAYING", x + T.px(80) + tm:MeasureStringX(valFont, eggText) + T.px(8),
                curY + math.floor((T.px(VITAL_ROW_H) - T.px(14)) / 2), "positive", false, T.fontF5 or ZeD.T.fontF2, true)
        end
        curY = curY + T.px(VITAL_ROW_H)
        hasContent = true
    end

    -- Last milked (Lv9)
    if ad.canSee(player, "last_milked") then
        local lastMilked = ad.getLastMilkedHours(animal)
        if lastMilked then
            local valFont = T.fontF3 or ZeD.T.fontF2
            local lblFont = T.fontF1 or ZeD.T.fontF2
            local rowY = curY + math.floor((T.px(VITAL_ROW_H) - tm:getFontHeight(valFont)) / 2)
            local lblColor = T.textSec or T.textDim
            panel:drawText("LAST MILKED", x, rowY, lblColor.r, lblColor.g, lblColor.b, lblColor.a or 0.7, lblFont)
            local hoursAgo = math.floor(lastMilked)
            local milkedText = hoursAgo .. "h ago"
            panel:drawText(milkedText, x + T.px(100), rowY, T.textDim.r, T.textDim.g, T.textDim.b, 0.6, valFont)
            curY = curY + T.px(VITAL_ROW_H)
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
    local hdrFont = T.fontF1 or ZeD.T.fontF2
    local hdrH = T.px(20)
    local hdrColor = T.textHead or T.textSec
    panel:drawText("BREEDING", x, curY, hdrColor.r, hdrColor.g, hdrColor.b, hdrColor.a or 0.8, hdrFont)
    A.drawDividerH(panel, x, curY + hdrH - T.px(1), w, false)
    curY = curY + hdrH + T.px(2)

    -- Pregnancy
    local isPregnant = ad.isPregnant(animal)
    if isPregnant then
        local pregText = "Pregnant"
        if ad.canSee(player, "pregnancy_bar") then
            local current, total = ad.getPregnancyProgress(animal)
            local ratio = total > 0 and (current / total) or 0
            pregText = string.format("Pregnant - %d%%", math.floor(ratio * 100))
            curY = curY + drawVitalRow(panel, x, curY, w, "Pregnancy", 0,
                pregText, pregText, true, ratio, T.info)
        else
            local valFont = T.fontF3 or ZeD.T.fontF2
            local lblFont = T.fontF1 or ZeD.T.fontF2
            local rowY = curY + math.floor((T.px(VITAL_ROW_H) - tm:getFontHeight(valFont)) / 2)
            local lblColor = T.textSec or T.textDim
            panel:drawText("PREGNANCY", x, rowY, lblColor.r, lblColor.g, lblColor.b, lblColor.a or 0.7, lblFont)
            panel:drawText("Yes", x + T.px(100), rowY, T.info.r, T.info.g, T.info.b, 0.9, valFont)
            curY = curY + T.px(VITAL_ROW_H)
        end
        hasContent = true
    end

    -- Mating season (Lv7)
    if ad.canSee(player, "mating_calendar") then
        local hasSeason = ad.haveMatingSeason(animal)
        if hasSeason then
            local inSeason = ad.isInMatingSeason(animal)
            local valFont = T.fontF3 or ZeD.T.fontF2
            local lblFont = T.fontF1 or ZeD.T.fontF2
            local rowY = curY + math.floor((T.px(VITAL_ROW_H) - tm:getFontHeight(valFont)) / 2)
            local lblColor = T.textSec or T.textDim
            panel:drawText("MATING", x, rowY, lblColor.r, lblColor.g, lblColor.b, lblColor.a or 0.7, lblFont)
            local seasonText = inSeason and "In season" or "Off season"
            local seasonColor = inSeason and T.positive or T.textDim
            panel:drawText(seasonText, x + T.px(100), rowY, seasonColor.r, seasonColor.g, seasonColor.b, 0.8, valFont)
            curY = curY + T.px(VITAL_ROW_H)
            hasContent = true
        end
    end

    -- Player acceptance (Lv5)
    if ad.canSee(player, "acceptance_num") then
        local acceptance = ad.getPlayerAcceptance(animal, player)
        local accText = tostring(math.floor(acceptance))
        local accColor = acceptance >= ad.ACCEPT_PETTING and T.positive
            or (acceptance >= ad.ACCEPT_CALL and T.warning or T.danger)

        local valFont = T.fontF3 or ZeD.T.fontF2
        local lblFont = T.fontF1 or ZeD.T.fontF2
        local rowY = curY + math.floor((T.px(VITAL_ROW_H) - tm:getFontHeight(valFont)) / 2)
        local lblColor = T.textSec or T.textDim
        panel:drawText("TRUST", x, rowY, lblColor.r, lblColor.g, lblColor.b, lblColor.a or 0.7, lblFont)
        panel:drawText(accText, x + T.px(100), rowY, accColor.r, accColor.g, accColor.b, 0.9, valFont)

        -- Context hint
        local hintFont = T.fontF5 or ZeD.T.fontF2
        local hint = acceptance >= ad.ACCEPT_PETTING and "Can pet" or (acceptance >= ad.ACCEPT_CALL and "Can call" or "Untrusting")
        local hintW = tm:MeasureStringX(valFont, accText)
        panel:drawText(hint, x + T.px(100) + hintW + T.px(8), rowY + T.px(1),
            T.textDim.r, T.textDim.g, T.textDim.b, 0.5, hintFont)
        curY = curY + T.px(VITAL_ROW_H)
        hasContent = true
    end

    -- Mother/baby relationships
    if ad.needsMother(animal) then
        A.drawBadge(panel, "ORPHAN", x, curY, "danger", false, T.fontF5 or ZeD.T.fontF2, true)
        curY = curY + T.px(18)
        hasContent = true
    end

    return hasContent and (curY - y) or 0
end

-- ============================================================================
-- M-AGEN — GENETICS SECTION (Lv7+/Lv9+)
-- Disorder badges with descriptions. Skill-gated by AD.getVisibleDisorders.
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
    local hdrFont = T.fontF1 or ZeD.T.fontF2
    local hdrH = T.px(20)
    local hdrColor = T.textHead or T.textSec
    panel:drawText("GENETICS", x, curY, hdrColor.r, hdrColor.g, hdrColor.b, hdrColor.a or 0.8, hdrFont)
    A.drawDividerH(panel, x, curY + hdrH - T.px(1), w, false)
    curY = curY + hdrH + T.px(2)

    local badgeFont = T.fontF5 or ZeD.T.fontF2
    local descFont = T.fontF5 or ZeD.T.fontF2

    for _, d in ipairs(disorders) do
        -- Severity → badge variant
        local variant = "info"
        if d.sev == "positive" then variant = "positive"
        elseif d.sev == "severe" then variant = "danger"
        elseif d.sev == "minor" then variant = "warning"
        end

        -- Badge
        A.drawBadge(panel, d.label, x, curY, variant, false, badgeFont, true)
        curY = curY + tm:getFontHeight(badgeFont) + (T.sp and T.sp.badgePadY or T.px(2)) * 2 + T.px(2)

        -- Description below badge
        if d.desc and d.desc ~= "" then
            panel:drawText(d.desc, x + T.px(4), curY,
                T.textDim.r, T.textDim.g, T.textDim.b, 0.5, descFont)
            curY = curY + tm:getFontHeight(descFont) + T.px(4)
        end
    end

    return curY - y
end

-- ============================================================================
-- O-ANDTL — ANIMAL DETAIL ORGANISM
-- Composes: header (pinned) + scrollable body (vitals + production +
-- breeding + genetics). Replaces Session A stub.
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
        drawEmptyState(panel, win, x, y, w, h)
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
        local Focus = ZeD.Input and ZeD.Input.Focus
        local fz = Focus and Focus.getFocusedZone and Focus.getFocusedZone(win)
        local fe = fz and fz.zone == "worldTabContent" and Focus.getFocusedElement and Focus.getFocusedElement(win)
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
        local sbX = x + w - scrollW
        A.drawScrollTrack(panel, sbX, bodyTop, scrollW - T.px(2), bodyH)
        local barH = math.max(T.px(20), math.floor(bodyH * (bodyH / totalContentH)))
        local scrollFrac = maxScroll > 0 and (ds.scrollY / maxScroll) or 0
        local barY = bodyTop + math.floor((bodyH - barH) * scrollFrac)
        A.drawScrollThumb(panel, sbX, barY, scrollW - T.px(2), barH)
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
    local countFont = T.fontF2 or ZeD.T.fontF2
    local countStr = tostring(#eligible) .. " eligible"
    panel:drawText(countStr, x + pad, curY, T.text.r, T.text.g, T.text.b, 1.0, countFont)
    curY = curY + tm:getFontHeight(countFont) + T.px(4)

    -- Yield estimate line
    local yieldFont = T.fontF3 or ZeD.T.fontF2
    local yieldStr = string.format("Est. %.1f kg meat  |  %.1f kg total weight", totalMeat, totalWeight)
    panel:drawText(yieldStr, x + pad, curY, T.accent.r, T.accent.g, T.accent.b, 0.8, yieldFont)
    curY = curY + tm:getFontHeight(yieldFont) + pad

    local bandH = curY - y
    A.drawDividerH(panel, x, y + bandH - T.px(1), w, true)

    return bandH
end

-- ============================================================================
-- M-BROW — BUTCHER ROSTER ROW (40px)
-- Portrait + name + species + weight (bold) + est. meat + product badges.
-- Sorted by weight descending (heaviest first).
-- Returns: BROW_H consumed.
-- ============================================================================

local function drawButcherRow(panel, x, y, w, entry, hovered)
    local T = ZeD.T
    local A = ZeD.Atoms
    local ad = AD()
    local tm = ZeD.TM
    local animal = entry.animal
    local yield = entry.yield

    -- Hover highlight
    if hovered then
        local hc = T.hover
        panel:drawRect(x, y, w, T.px(BROW_H), hc.a or 0.08, hc.r, hc.g, hc.b)
    end

    -- Portrait (28px, vertically centered)
    local portraitPath = ad.resolvePortrait(animal)
    local tex = getTexture(portraitPath)
    local iconY = y + math.floor((T.px(BROW_H) - T.px(BROW_ICON_SZ)) / 2)
    if tex then
        panel:drawTextureScaledAspect(tex, x + T.px(BROW_PAD), iconY, T.px(BROW_ICON_SZ), T.px(BROW_ICON_SZ), 0.9, 1, 1, 1)
    end

    local textX = x + T.px(BROW_PAD) + T.px(BROW_ICON_SZ) + T.px(BROW_PAD)
    local topY = y + T.px(4)
    local botY = y + T.px(22)

    -- Top line: Name + Weight (right-aligned, bold)
    local nameFont = T.fontF2 or ZeD.T.fontF2
    local name = ad.getDisplayName(animal)
    panel:drawText(name, textX, topY, T.text.r, T.text.g, T.text.b, 1.0, nameFont)

    -- Weight (right-aligned, accent, data font)
    local weightFont = T.fontF3 or ZeD.T.fontF2
    local weightStr = string.format("%.1f kg", yield.weight)
    local weightW = tm:MeasureStringX(weightFont, weightStr)
    panel:drawText(weightStr, x + w - T.px(BROW_PAD) - weightW, topY,
        T.accent.r, T.accent.g, T.accent.b, 1.0, weightFont)

    -- Bottom line: Species + est. meat + product badges
    local secFont = T.fontF5 or ZeD.T.fontF2
    local atype = ad.getAnimalType(animal)
    local species = getText("IGUI_AnimalType_" .. atype) or atype
    local sex = ad.isFemale(animal) and "F" or "M"
    local specLine = species .. " (" .. sex .. ")"
    panel:drawText(specLine, textX, botY, T.textDim.r, T.textDim.g, T.textDim.b, 0.6, secFont)

    -- Estimated meat (after species)
    local specW = tm:MeasureStringX(secFont, specLine)
    local meatStr = string.format("| ~%.1f kg meat", yield.estMeat)
    panel:drawText(meatStr, textX + specW + T.px(6), botY,
        T.textDim.r, T.textDim.g, T.textDim.b, 0.5, secFont)

    -- Product badges (right-aligned on bottom line)
    local badgeFont = T.fontF5 or ZeD.T.fontF2
    local badgePadX = T.sp and T.sp.badgePadX or T.px(4)
    local bx = x + w - T.px(BROW_PAD)
    for i = #yield.products, 1, -1 do
        local prod = yield.products[i]
        local badgeText = string.upper(prod)
        local bw = tm:MeasureStringX(badgeFont, badgeText) + badgePadX * 2
        bx = bx - bw - T.px(3)
        A.drawBadge(panel, prod, bx, botY, "neutral", false, badgeFont, true)
    end

    -- Divider
    A.drawDividerH(panel, x, y + T.px(BROW_H) - T.px(1), w, false)

    return T.px(BROW_H)
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

    -- Empty state
    if #eligible == 0 then
        local font = T.fontF4 or ZeD.T.fontF2
        local text = "No eligible animals"
        local tw = ZeD.TM:MeasureStringX(font, text)
        panel:drawText(text, x + math.floor((w - tw) / 2), y + T.px(EMPTY_PAD),
            T.textDim.r, T.textDim.g, T.textDim.b, 0.6, font)

        local hint = "Adults only, excludes pregnant"
        local hintFont = T.fontF5 or ZeD.T.fontF2
        local hw = ZeD.TM:MeasureStringX(hintFont, hint)
        panel:drawText(hint, x + math.floor((w - hw) / 2), y + T.px(EMPTY_PAD) + T.px(20),
            T.textDim.r, T.textDim.g, T.textDim.b, 0.4, hintFont)
        return
    end

    -- Sort by weight descending (insertion sort, Q35)
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

    -- ── SECTION HEADER ──
    local secY = y + summaryH
    local secH = M.drawSectionHeader(panel, x + pad, secY, w - pad,
        "Roster", #eligible, true, false,
        T.fontF4, true, pad, nil, true)

    -- ── SCROLLABLE ROSTER ──
    local rosterTop = secY + secH
    local rosterH = h - (rosterTop - y)
    if rosterH <= 0 then return end

    local totalContentH = #eligible * T.px(BROW_H)
    local maxScroll = math.max(0, totalContentH - rosterH)

    -- S109: gamepad scroll-follow for butcher roster. Mirror of ranch zone.
    local gpFocusAnimal = nil
    do
        local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
        if Focus and Focus.getFocusedZone then
            local fz = Focus.getFocusedZone(win)
            if fz and fz.zone == "worldTabContent" then
                local fe = Focus.getFocusedElement and Focus.getFocusedElement(win)
                if fe and fe.isButcher then gpFocusAnimal = fe.animal end
            end
        end
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

    local mx = panel:getMouseX()
    local my = panel:getMouseY()
    local rowY = rosterTop - bs.scrollY

    for _, entry in ipairs(eligible) do
        if rowY + T.px(BROW_H) > rosterTop and rowY < rosterTop + rosterH then
            local isHovered = mx >= x and mx < x + contentW
                and my >= rowY and my < rowY + T.px(BROW_H)
            -- S109: gamepad focus cue painted before row content.
            if entry.animal == gpFocusAnimal then
                _paintGpCue(panel, x + pad, rowY, contentW - pad * 2, T.px(BROW_H))
            end
            drawButcherRow(panel, x + pad, rowY, contentW - pad * 2, entry, isHovered)
            table.insert(win._animalsButcherZones, {
                x = x, y = rowY, w = contentW, h = T.px(BROW_H), animal = entry.animal
            })
        end
        rowY = rowY + T.px(BROW_H)
    end

    panel:clearStencilRect()

    if needsScroll then
        local sbX = x + contentW + T.px(2)
        A.drawScrollTrack(panel, sbX, rosterTop, scrollW - T.px(2), rosterH)
        local barH = math.max(T.px(20), math.floor(rosterH * (rosterH / totalContentH)))
        local scrollFrac = maxScroll > 0 and (bs.scrollY / maxScroll) or 0
        local barY = rosterTop + math.floor((rosterH - barH) * scrollFrac)
        A.drawScrollThumb(panel, sbX, barY, scrollW - T.px(2), barH)
    end

    win._animalsButcherScroll = {
        top = rosterTop, h = rosterH, maxScroll = maxScroll, needsScroll = needsScroll
    }
end

-- ============================================================================
-- FOOTER + MAIN RENDER
-- ============================================================================

-- ============================================================================
-- FOOTER STRIP — "+ Create zone" and "Map view" buttons (matches mockup)
-- Rendered at bottom of overview/butcher views.
-- ============================================================================

local function drawFooterStrip(panel, win, x, y, w, view)
    local T = ZeD.T
    local A = ZeD.Atoms
    local btnFont = T.fontF5 or ZeD.T.fontF2
    local btnH = T.px(BTN_H)

    A.drawDividerH(panel, x, y, w, false)

    local pad = T.px(6)
    local btnY = y + math.floor((T.px(FOOTER_H) - btnH) / 2)
    local bx = x + pad

    -- Clear all footer button zones
    win._animalsAddZoneBtn = nil
    win._animalsZoneRenameBtn = nil
    win._animalsZoneRemoveBtn = nil

    -- Also clear confirm/rename zones
    win._animalsRemoveYes = nil
    win._animalsRemoveNo = nil
    win._animalsRenameSaveBtn = nil
    win._animalsRenameCancelBtn = nil

    if view == "zone" and win._animalsRenaming then
        -- Rename mode: YES + NO + RESET + hint (matches ItemCard)
        win._animalsRenameSaveBtn = drawBtn(panel, bx, btnY, "Yes", "positive", btnFont)
        bx = bx + win._animalsRenameSaveBtn.w + T.px(6)
        win._animalsRenameCancelBtn = drawBtn(panel, bx, btnY, "No", "neutral", btnFont)
        bx = bx + win._animalsRenameCancelBtn.w + T.px(6)
        win._animalsRenameResetBtn = drawBtn(panel, bx, btnY, "Reset", "neutral", btnFont)
        bx = bx + win._animalsRenameResetBtn.w + T.px(8)
        local hintFont = T.fontF3 or ZeD.T.fontF2
        local nc = T.toneNorm
        local hintY = btnY + math.floor((btnH - ZeD.TM:getFontHeight(hintFont)) / 2)
        panel:drawText("Type new name", bx, hintY, nc.r, nc.g, nc.b, nc.a or 1, hintFont)
    elseif view == "zone" and win._animalsRemoveConfirm then
        -- Remove confirmation: YES + NO + prompt
        win._animalsRemoveYes = drawBtn(panel, bx, btnY, "Yes", "positive", btnFont)
        bx = bx + win._animalsRemoveYes.w + T.px(6)
        win._animalsRemoveNo = drawBtn(panel, bx, btnY, "No", "danger", btnFont)
        bx = bx + win._animalsRemoveNo.w + T.px(8)
        local promptFont = T.fontF3 or ZeD.T.fontF2
        local nc = T.toneNorm
        local promptY = btnY + math.floor((btnH - ZeD.TM:getFontHeight(promptFont)) / 2)
        panel:drawText("Remove zone?", bx, promptY, nc.r, nc.g, nc.b, nc.a or 1, promptFont)
    elseif view == "zone" then
        -- Zone detail footer: Remove only (rename via clicking zone name)
        win._animalsZoneRemoveBtn = drawBtn(panel, bx, btnY, "Remove", "danger", btnFont)
    else
        -- Overview footer: Create Zone + hint
        win._animalsAddZoneBtn = drawBtn(panel, bx, btnY, "+ Create zone", "accent", btnFont)
        -- S109: gamepad focus cue overlays drawBtn's outlined-button output.
        if _gpFocusMatches(win, function(el) return el.isCreateZone end) then
            local z = win._animalsAddZoneBtn
            _paintGpCue(panel, z.x, z.y, z.w, z.h)
        end
        bx = bx + win._animalsAddZoneBtn.w + T.px(8)
        local hintFont = T.fontF3 or ZeD.T.fontF2
        local nc = T.toneNorm
        local hintY = btnY + math.floor((btnH - ZeD.TM:getFontHeight(hintFont)) / 2)
        panel:drawText("Create an Animal zone to get started", bx, hintY,
            nc.r, nc.g, nc.b, nc.a or 1, hintFont)
    end

    return T.px(FOOTER_H)
end

-- ============================================================================
-- MAIN RENDER — routes to submode × view
-- ============================================================================

local TAB_TOP_PAD = 13  -- aligns sub-tab strip bottom with inventory column header (matches JournalTab)

function ZeD.AnimalsTab.render(panel, win, x, y, w, h)
    local T = ZeD.T
    local state = getState(win)
    local zc = getZoneCreateState(win)

    -- Top padding: 13px aligns sub-tab strip bottom with inventory column header
    y = y + T.px(TAB_TOP_PAD)
    h = h - T.px(TAB_TOP_PAD)

    -- Zone create mode overrides everything
    if zc.active then
        local tabH = drawSubmodeStrip(panel, win, x, y, w)
        renderZoneCreateView(panel, win, x, y + tabH, w, h - tabH)
        return
    end

    -- Sub-tab strip (always visible)
    local curY = y + drawSubmodeStrip(panel, win, x, y, w)

    -- Breadcrumb (zone/animal views only)
    if state.view == "zone" or state.view == "animal" then
        curY = curY + drawBreadcrumb(panel, win, x, curY, w)
    end

    -- Footer strip (overview + zone detail — not animal drill-down)
    local footerY = y + h - T.px(FOOTER_H)
    local showFooter = (state.view == "overview" or state.view == "zone")
    if showFooter then
        drawFooterStrip(panel, win, x, footerY, w, state.view)
    end

    -- Remaining content area (between chrome and footer)
    local contentH = (showFooter and footerY or (y + h)) - curY

    -- zones of the views not drawn this frame must not answer clicks or focus
    win._animalsStructZones = {}
    win._animalsHutchLink = nil
    win._animalsGenomeZones, win._animalsGenomeBtns = nil, nil
    win._animalsButcherZones = nil   -- the Butcher roster rebuilds it when drawn

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
    -- Zone creation mode clicks (footer buttons)
    local zc = getZoneCreateState(win)
    if zc.active then
        if hitZone(win._zoneConfirmYes, x, y) then
            confirmZoneCreate(win)
            return true
        end
        if hitZone(win._zoneConfirmNo, x, y) then
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

    -- Footer: + Create Zone button
    if hitZone(win._animalsAddZoneBtn, x, y) then
        startZoneCreate(win)
        return true
    end

    -- Zone name click → start rename (like ItemCard)
    if hitZone(win._animalsZoneNameZone, x, y) and not win._animalsRenaming then
        renameZone(win)
        return true
    end
    -- Zone detail: Remove button
    if hitZone(win._animalsZoneRemoveBtn, x, y) then
        removeZone(win)
        return true
    end
    -- Rename: YES (save) / NO (cancel) / RESET
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
                        win._animalsRenameEntry:setText("Livestock Zone #" .. (i + 1))
                        break
                    end
                end
            end
        end
        return true
    end
    -- Remove confirmation: YES / NO
    if hitZone(win._animalsRemoveYes, x, y) then
        confirmRemoveZone(win)
        return true
    end
    if hitZone(win._animalsRemoveNo, x, y) then
        cancelRemoveZone(win)
        return true
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

    -- Section header collapse/expand clicks (overview)
    if win._animalsSectionZones and win._animalsOverviewState then
        for _, sz in ipairs(win._animalsSectionZones) do
            if hitZone(sz, x, y) then
                win._animalsOverviewState[sz.key] = not win._animalsOverviewState[sz.key]
                return true
            end
        end
    end

    -- Zone card clicks → navigate to zone view
    if win._animalsZoneCardZones then
        for _, zc in ipairs(win._animalsZoneCardZones) do
            if hitZone(zc, x, y) then
                navigate(win, "zone", zc.zoneName, nil)
                return true
            end
        end
    end

    -- Animal roster row clicks → navigate to animal detail
    if win._animalsRosterZones then
        for _, rz in ipairs(win._animalsRosterZones) do
            if x >= rz.x and x < rz.x + rz.w
               and y >= rz.y and y < rz.y + rz.h then
                navigate(win, "animal", nil, rz.animal)
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

    -- Scrollbar click (future overview scroll)
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

function ZeD.AnimalsTab.onRightClick(win, x, y)
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
        -- Q5: positive delta = scroll DOWN (inverted)
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


    -- Overview scroll (future)
    local scroll = win._animalsScroll
    if scroll and scroll.visible then
        scroll:handleMouseWheel(del)
        return true
    end
    return false
end

-- ============================================================================
-- PUBLIC NAVIGATION — called by roster/zone click handlers in future sessions
-- ============================================================================

AT.navigate         = navigate
AT.navigateBack     = navigateBack
-- HOOK_MAP 20-22: the cards link back here (a bird's INFO), and the World
-- window's gamepad builder opens and edits through these.
AT.openStruct       = openStruct
AT.genomeAct        = genomeAct
function AT.showAnimal(win, animal)
    local state = getState(win)
    state.submode = "ranch"
    local zn = nil
    local dz = ocall(animal, "getDZone")
    if dz then zn = ocall(dz, "getName") end
    state.zoneName = zn
    state.view = zn and "zone" or "overview"
    navigate(win, "animal", nil, animal)
end
AT.getState         = getState
-- S109: exported for World window gamepad builder (submode live-switch on
-- focus + sort-btn A-press + roster/butcher/zonecard navigate calls).
AT.switchSubmode    = switchSubmode
AT.cycleSortMode    = cycleSortMode
AT.getZoneViewState = getZoneViewState
AT.getButcherState  = getButcherState
AT.startZoneCreate  = startZoneCreate
-- S109a: gamepad zone-draw state machine.
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
