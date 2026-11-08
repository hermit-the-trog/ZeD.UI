-- ZeD-UI/42/media/lua/client/ZeD/RadioTab.lua
-- ============================================================================
-- RADIO TAB — client; the radios' tab in both windows.
--
-- Plugs into BOTH ZeD_CharacterWindow's TAB_RENDERERS and ZeD_WorldWindow's
-- WORLD_TAB_RENDERERS via the shared register() entry point. The drawing is
-- identical in both windows; only the radio discovery source
-- differs (equipped on player vs in-range world objects). Each window's
-- refresh loop writes what it found to win._radios before render() runs,
-- so render() itself only reads.
-- One thing to know: everything the mouse or the controller can press is a
-- rect the drawing stamped on win this frame (win._radio*Zone, the face's
-- win._radioTw.hits); the click router and the focus builder read those,
-- they never measure the layout again.
--
-- FACES: a radio with a face of its own is drawn as that face: the two-way
-- sets (TwoWayFace.lua), the ordinary radios, the CD player and the TVs
-- (RtvFace.lua). The chassis drawn in this file is the SIMPLE CARD, reached
-- through one function, ZeD.RadioTab.drawSimple: the card for a radio with
-- no face (a modded one). The simple card has no brand strip at its foot:
-- a face carries its own brand.
--
-- THE DRAWN CHASSIS has two visual tiers, picked at runtime by
-- deviceData:getIsHighTier():
--   - Premium Technologies (silver Pioneer-style hi-fi, cyan VFD, green-VFD CD)
--   - ValuTech            (cheap black plastic, backlit amber LCD, no CD)
--
-- LAYER STRUCTURE INSIDE THIS FILE:
--   - Forward decls (closure capture per Kahlua's create-time binding)
--   - Data discovery: buildEquippedRadios, buildWorldRadios
--   - Wave cache helper (cosmetic 64-column harmonic, seeded per radio)
--   - Chassis molecules: radioMainDisplay, radioControlStrip, radioPresetBank,
--     radioSignalWave, cdPlayerModule
--   - Organisms: renderPremium, renderValutech, renderDrawer
--   - Faces: drawSimple, faceFor, wantW, renderTwoWay (any face, its footer
--     and its scrollbar)
--   - Top-level: render (with browse header), then the click router, the
--     wheel and the right-click, register, and the controller's focusables
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/TwoWayFace"
require "ZeD/TwoWayFull"
require "ZeD/RtvFace"
require "ZeD/PlainFace"
require "ZeD/WorldRoutes"

ZeD = ZeD or {}
ZeD.RadioTab = ZeD.RadioTab or {}

-- Forward decls — Kahlua closures capture free names at creation time, so
-- helpers used inside other helpers must be declared as locals before any
-- function that references them.
local renderPremium
local renderValutech
local renderDrawer
local radioMainDisplay
local radioControlStrip
local radioPresetBank
local radioSignalWave
local cdPlayerModule
-- render() drives the SEEK hold-to-repeat advance, so it needs sight of
-- _channelStep before that local's definition further down.
local _channelStep

-- ============================================================================
-- DATA DISCOVERY
-- ============================================================================

-- Lookup: PZ radio item check. Both inventory items (Radio class) and world
-- IsoWaveSignal objects expose getDeviceData(). We probe the method via
-- direct field access (Kahlua: indexing an exposed class returns the method
-- as a callable, or nil if not exposed) — avoids the "Tried to call nil"
-- log spam that pcall produces on missing methods.
local function _hasDeviceData(obj)
    if obj == nil or obj.getDeviceData == nil then return false end
    local dd = obj:getDeviceData()
    return dd ~= nil, dd
end

-- The slot a radio sits in, in the player's language. The tags themselves ("Primary",
-- "Secondary", "Back", "Floor") are ids: they key the wave cache and stay English.
function ZeD.RadioTab.locationName(tag)
    if tag == "Primary" then return ZeD.tr("UI_ZeD_Radio_LocPrimary") end
    if tag == "Secondary" then return ZeD.tr("UI_ZeD_Radio_LocSecondary") end
    if tag == "Back" then return ZeD.tr("UI_ZeD_Radio_LocBack") end
    if tag == "Floor" then return getText("ContextMenu_Floor") end
    if tag == "Carried" then return getText("IGUI_InventoryTooltip") end   -- in a bag or the inventory (WorldRoutes.lua)
    if tag == "Vehicle" then return getText("UI_optionscreen_binding_Vehicle") end   -- a car's device part (WorldRoutes.lua)
    return tag or ""
end

-- a radio's place in a tab list (by its owner: the item, the set or the part), nil when it is not there
function ZeD.RadioTab.indexOf(list, dev)
    if dev == nil then return nil end
    for i, e in ipairs(list or {}) do
        if e.radioInstance == dev then return i end
    end
    return nil
end

--- Scan the player's equipped slots for radios.
--- Mirrors vanilla ISRadioWindow's scan — hand items + back-clothing slot.
--- Returns array of entries each shaped:
---   { radioInstance, deviceData, locationTag, kind = "equipped", cacheKey }
--- locationTag is the slot's id (Primary / Secondary / Back); the drawer
--- header shows it in the player's language (locationName above).
function ZeD.RadioTab.buildEquippedRadios(playerObj)
    local out = {}
    if playerObj == nil then return out end

    local function tryAdd(item, tag)
        if item == nil then return end
        if not instanceof(item, "Radio") then return end
        local has, dd = _hasDeviceData(item)
        if not has then return end
        -- Stable cache key per equipped slot. The slot tag is unique within an
        -- equipped scan (Primary / Secondary / Back), so it's a reliable key
        -- without needing getID() (which IsoWaveSignal/Radio inheritance can
        -- omit and produce "Tried to call nil" log spam).
        out[#out + 1] = {
            radioInstance = item,
            deviceData    = dd,
            locationTag   = tag,
            kind          = "equipped",
            cacheKey      = "eq:" .. tag,
        }
    end

    tryAdd(playerObj:getPrimaryHandItem(),   "Primary")
    tryAdd(playerObj:getSecondaryHandItem(), "Secondary")
    -- Back-clothing slot — ISRadioWindow checks this so portable radios slung
    -- on the player's back register too.
    if playerObj.getClothingItem_Back then
        tryAdd(playerObj:getClothingItem_Back(), "Back")
    end
    -- a radio opened from a bag or the inventory (WorldRoutes.radio pins it): listed while it stays on the player
    local pin = ZeD.RadioTab._carried and ZeD.RadioTab._carried[playerObj:getPlayerNum()]
    if pin then
        local okC, still = pcall(function()
            local c = pin:getContainer()
            return c ~= nil and c:isInCharacterInventory(playerObj)
        end)
        if okC and still and not ZeD.RadioTab.indexOf(out, pin) then tryAdd(pin, "Carried") end
        if not (okC and still) then ZeD.RadioTab._carried[playerObj:getPlayerNum()] = nil end
    end

    return out
end

--- Scan the 3x3 grid around the player for IsoWaveSignal radios.
--- Mirrors buildWorldContainers (ZeD_WorldWindow.lua) for reach semantics:
--- canReachTo wall check + safehouse loot permission. Returns entries shaped:
---   { radioInstance, deviceData, locationTag, kind = "world", distance, cacheKey }
--- sorted by distance ascending; a device a route pinned is added at the end
--- when the scan missed it.
function ZeD.RadioTab.buildWorldRadios(playerObj)
    local out = {}
    if playerObj == nil then return out end

    local cell = getCell()
    if cell == nil then return out end

    local cx = math.floor(playerObj:getX())
    local cy = math.floor(playerObj:getY())
    local cz = math.floor(playerObj:getZ())
    local currentSq = playerObj:getCurrentSquare()

    for dy = -1, 1 do
        for dx = -1, 1 do
            local gs = cell:getGridSquare(cx + dx, cy + dy, cz)
            -- Wall-pass check: player must be able to reach the neighbor sq.
            if gs and gs ~= currentSq and currentSq then
                if not currentSq:canReachTo(gs) then gs = nil end
            end
            -- Safehouse loot permission (matches container reach).
            if gs and isClient() and SafeHouse and SafeHouse.isSafehouseAllowLoot then
                if not SafeHouse.isSafehouseAllowLoot(gs, playerObj) then
                    gs = nil
                end
            end
            if gs then
                local objs = gs:getObjects()
                if objs then
                    for i = 0, objs:size() - 1 do
                        local o = objs:get(i)
                        if instanceof(o, "IsoWaveSignal") then
                            local has, dd = _hasDeviceData(o)
                            if has then
                                local distSq = dx * dx + dy * dy
                                -- Use world coordinates as the stable cache
                                -- key. IsoWaveSignal occupies a fixed tile
                                -- so x/y/z is stable for the life of the
                                -- object, and uniquely identifies it among
                                -- all radios in range.
                                local ox = math.floor(o:getX() or 0)
                                local oy = math.floor(o:getY() or 0)
                                local oz = math.floor(o:getZ() or 0)
                                out[#out + 1] = {
                                    radioInstance = o,
                                    deviceData    = dd,
                                    locationTag   = "Floor",
                                    kind          = "world",
                                    distance      = math.sqrt(distSq),
                                    cacheKey      = string.format("w:%d,%d,%d", ox, oy, oz),
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(out, function(a, b) return a.distance < b.distance end)
    -- a device a route opened the tab on (a TV across the room, a car's device part) stays on the
    -- list while it is within the game's reach for its window (WorldRoutes.lua)
    if ZeD.WorldRoutes and ZeD.WorldRoutes.addPinned then out = ZeD.WorldRoutes.addPinned(playerObj, out) end
    return out
end

-- ============================================================================
-- WAVE CACHE — cosmetic harmonic sine generator, seeded per radio
-- The signal wave ALWAYS renders, even powered off: the power state only
-- dims the line color, so the layout never shifts with a switch flip.
-- ============================================================================

-- Build a 64-column wave from a stable integer seed. Three sine harmonics with
-- different periods + a small noise floor — same numbers in, same wave out.
-- Returns array of normalized heights in [-1, 1] for the caller to scale.
local function _buildWave(seed, columns)
    local cols = columns or 64
    local out = {}
    -- Seed-perturbed harmonic constants — tiny offsets so different radios
    -- look distinct without using a real PRNG (which would be per-call,
    -- breaking the cache invariant).
    local s = (seed or 0)
    local p1 = 0.18 + ((s % 7) * 0.011)
    local p2 = 0.42 + ((s % 13) * 0.013)
    local p3 = 0.71 + ((s % 17) * 0.009)
    local a1 = 0.55
    local a2 = 0.30
    local a3 = 0.15
    -- A small deterministic noise layer keeps the wave from being too clean.
    local noiseSeed = (s * 1103515245 + 12345) % 2147483648
    for i = 1, cols do
        local t = (i - 1)
        local v = a1 * math.sin(t * p1)
              + a2 * math.sin(t * p2 + 1.7)
              + a3 * math.sin(t * p3 + 3.1)
        -- Per-column deterministic noise, ~5% amplitude.
        noiseSeed = (noiseSeed * 1103515245 + 12345) % 2147483648
        local n = ((noiseSeed % 1000) / 1000.0 - 0.5) * 0.10
        out[i] = v + n
    end
    return out
end

-- Cached wave fetch keyed by the entry's stable cacheKey (computed at build
-- time — equipped slot tag for char, world coords for world objects). Cache
-- lives on the window so it follows the radio refresh lifecycle. The seed is
-- derived from the key string so the cached content is stable across reopens.
local function _getWave(win, cacheKey, columns)
    if win == nil or cacheKey == nil then return nil end
    win._radioWaveCache = win._radioWaveCache or {}
    local cached = win._radioWaveCache[cacheKey]
    if cached and #cached == (columns or 64) then return cached end
    -- Hash the key string into a deterministic integer seed.
    local seed = 0
    for i = 1, #cacheKey do
        seed = (seed * 31 + cacheKey:byte(i)) % 2147483647
    end
    local wave = _buildWave(seed, columns)
    win._radioWaveCache[cacheKey] = wave
    return wave
end

-- ============================================================================
-- CHASSIS MOLECULES — radio-specific, kept here rather than Molecules.lua
-- because they are tightly coupled to the radio chassis layout grammar.
-- ============================================================================

-- Helper: a silkscreen label printed straight onto the chassis, in the
-- given colour (F1 unless a font is passed).
local function _silk(panel, x, y, text, color, font)
    local T = ZeD.T
    panel:drawText(text, x, y, color.r, color.g, color.b, color.a or 1.0, font or T.fontF1)
end

-- Helper: read a deviceData getter via field probe — if the method isn't
-- exposed on this radio's Java class, the field is nil and we return the
-- fallback silently. Avoids the "Tried to call nil" log spam that pcall
-- triggers when a defensive call hits an unexposed method.
local function _safeGet(dd, fnName, fallback)
    if dd == nil then return fallback end
    local fn = dd[fnName]
    if fn == nil then return fallback end
    local v = fn(dd)
    if v == nil then return fallback end
    return v
end

-- PZ stores channel as MHz × 1000 (vanilla RWMGeneral:setInfoLines
-- displays getChannel()/1000 .. " MHz" — so 88000 = 88 MHz, 96500 = 96.5 MHz).
-- Always render as MHz with one decimal so the 0.1-step seek granularity is
-- visible (88.0 → 88.1 → 88.2 ...).
-- Split formatted frequency into number + unit pair so the renderer can
-- draw the number large and the unit smaller alongside.
local function _splitFrequency(hz)
    if hz == nil or hz == 0 then return "---.-", "MHz" end
    return string.format("%.1f", hz / 1000), "MHz"
end

----------------------------------------------------------------------
-- M: radioMainDisplay
-- The VFD (Premium) or LCD (ValuTech) main display. Brand-conditional palette.
-- Layout (top to bottom):
--   - status chip row (AM / FM / STEREO) — text-only chips
--   - BATT (4 segs) + VOL (8 segs) bars
--   - main zone: the frequency large beside the RANGE / SIG column; the
--     station name on its own row at the bottom
-- One display colour per tier (a TV tube is white, but this is a radio): the
-- VFD stays in the cyan family, the LCD dark-on-amber — never multi-colour.
----------------------------------------------------------------------
function radioMainDisplay(panel, x, y, w, h, brand, dd)
    local T = ZeD.T
    local A = ZeD.Atoms
    local TM = ZeD.TM

    -- Brand palette select. Backlit substrate (cyan-VFD-blue / amber-LCD)
    -- shows ONLY when power is on. Powered-off mirrors real-hardware off
    -- states: a non-backlit LCD reads as light silvery-grey glass with the
    -- segments faintly visible; an unlit VFD tube reads as near-black.
    --
    -- "Power on" = user flipped the switch AND the device has usable power.
    -- A dead battery (or no battery on a battery-powered unit, with no
    -- alternate source) means the display stays blank — preventing an
    -- exploit where a depleted radio could still be used as a passive data
    -- readout. Mirrors vanilla ISRadioAction:isReallyRunning logic.
    local userOn       = _safeGet(dd, "getIsTurnedOn",       false)
    local batPowered   = _safeGet(dd, "getIsBatteryPowered", true)
    local batCharge    = _safeGet(dd, "getPower",            0)
    local hasBatItem   = _safeGet(dd, "getHasBattery",       false)
    local extPower     = ZeD.RadioOps.canBePoweredHere(dd)
    local hasUsablePower
    if batPowered then
        hasUsablePower = hasBatItem and type(batCharge) == "number" and batCharge > 0
    else
        hasUsablePower = extPower
    end
    local power_now = userOn and hasUsablePower
    -- Non-backlit STN LCD glass has a characteristic grey-green / olive tint,
    -- as on an old car stereo. Roughly #8E8F72.
    local lcdOffBg = { r = 0.557, g = 0.561, b = 0.447, a = 1.0 }
    local vfdOffBg = { r = 0.10, g = 0.10, b = 0.10, a = 1.0 }  -- ~ #1A1A1A unlit tube
    local fgBright, fgDim, fgOff, bg
    if brand == "premium" then
        bg       = power_now and T.radio.vfd.bg or vfdOffBg
        fgBright = T.radio.vfd.bright
        fgDim    = T.radio.vfd.dim
        -- When off, unlit-segment color becomes a near-bg shade so chips and
        -- bar pips read as uniform dark ghosts on the unlit tube — not bright
        -- cyan still showing on a dark background.
        fgOff    = power_now and T.radio.vfd.off
                              or { r = 0.16, g = 0.16, b = 0.16, a = 1.0 }
    else
        bg       = power_now and T.radio.lcd.bg or lcdOffBg
        fgBright = T.radio.lcd.fg
        fgDim    = T.radio.lcd.fgDim
        -- When off, the LCD's "unlit segment" amber-orange (#C47015) would
        -- read as bright orange dots on the grey-green off-glass. Override to
        -- the dark digit color so all segments — lit OR unlit — paint as one
        -- uniform dark LCD readout. Real STN LCDs work this way: the panel
        -- isn't backlit, but every segment that exists is faintly visible as
        -- the same dark grey.
        fgOff    = power_now and T.radio.lcd.segOff or T.radio.lcd.fg
    end

    -- Black inset frame (2px) around the entire display so the LCD/VFD reads
    -- as a recessed window in the chassis. Painted FIRST then the substrate
    -- fills the interior; subsequent content (chips, bars, frequency, data
    -- column) lays out against the post-frame interior bounds.
    local frameW = T.px(2)
    panel:drawRect(x,                  y,                  w,      frameW, 1.0, 0, 0, 0)
    panel:drawRect(x,                  y + h - frameW,     w,      frameW, 1.0, 0, 0, 0)
    panel:drawRect(x,                  y,                  frameW, h,      1.0, 0, 0, 0)
    panel:drawRect(x + w - frameW,     y,                  frameW, h,      1.0, 0, 0, 0)
    -- Shrink to interior; all subsequent layout uses the smaller box.
    x = x + frameW
    y = y + frameW
    w = w - frameW * 2
    h = h - frameW * 2

    -- Display substrate fill, interior of the frame.
    panel:drawRect(x, y, w, h, bg.a or 1.0, bg.r, bg.g, bg.b)

    local pad = T.px(8)
    local cx = x + pad
    local cy = y + pad
    local maxX = x + w - pad
    local font = T.fontF3   -- mono digits / chip text

    -- "power" downstream uses the effective on-state computed above (user
    -- switched on AND device has usable power). Other fields are read fresh.
    local power     = power_now
    local hasBat    = hasBatItem
    local battery   = batCharge
    local hasSignal = _safeGet(dd, "isReceivingSignal",   false)
    local channel   = _safeGet(dd, "getChannel",          0)
    local volF      = _safeGet(dd, "getDeviceVolume",     0.5)
    local minHz     = _safeGet(dd, "getMinChannelRange",  75000)
    local maxHz     = _safeGet(dd, "getMaxChannelRange",  1000000)

    if type(volF)    ~= "number" then volF    = 0.5 end
    if type(battery) ~= "number" then battery = 0 end

    -- =========== ROW 1 — status chip row ===========
    -- Chips paint as a square and a word (M.drawStatusChip): filled for on,
    -- outlined for off. AM, FM, STEREO, on both tiers; only FM ever lights.
    -- STEREO is cosmetic (always off — no engine reading for it).
    local fontHrow1 = TM:getFontHeight(font)
    local row1Y = cy
    local hasFreq = (type(channel) == "number") and channel > 0
    -- PZ has no real AM band — radios are FM-only in lore. Light FM when the
    -- radio is powered + has a tuned frequency; AM chip stays as decorative
    -- silkscreen-off so the chassis still reads as a real AM/FM unit, but
    -- never lights.
    local amOn = false
    local fmOn = power and hasFreq
    local stereoOn = false  -- cosmetic chip; no engine reading

    -- When display is off, all chip squares paint as FILLED dark segments
    -- (matching real STN LCD behavior where every segment is faintly visible
    -- as the same dark grey when the panel isn't backlit). Both the square
    -- and the label dim to ~35% alpha — same treatment as the BATT/VOL bars
    -- so the off-display reads as a single uniformly-faded ghost.
    local cursor = cx
    local amShow     = (not power) or amOn
    local fmShow     = (not power) or fmOn
    local stereoShow = (not power) or stereoOn
    local chipOnC    = fgBright
    local chipOffC   = fgOff
    if not power then
        chipOnC  = { r = fgBright.r, g = fgBright.g, b = fgBright.b, a = (fgBright.a or 1.0) * 0.35 }
        chipOffC = { r = fgOff.r,    g = fgOff.g,    b = fgOff.b,    a = (fgOff.a    or 1.0) * 0.35 }
    end
    cursor = cursor + ZeD.Molecules.drawStatusChip(panel, cursor, row1Y, "AM",     amShow,     chipOnC, chipOffC, font) + T.px(12)
    cursor = cursor + ZeD.Molecules.drawStatusChip(panel, cursor, row1Y, "FM",     fmShow,     chipOnC, chipOffC, font) + T.px(12)
    cursor = cursor + ZeD.Molecules.drawStatusChip(panel, cursor, row1Y, ZeD.tr("UI_ZeD_Radio_Stereo"), stereoShow, chipOnC, chipOffC, font) + T.px(12)

    cy = row1Y + fontHrow1 + T.px(10)

    -- =========== ROW 2 — BATT + VOL bars ===========
    local labelFont = T.fontF1
    local labelH = TM:getFontHeight(labelFont)
    local barH   = T.px(12)

    -- BATT label + 4 segments
    local battLabel = ZeD.tr("UI_ZeD_Radio_Batt")
    _silk(panel, cx, cy + math.floor((barH - labelH) / 2), battLabel, fgDim, labelFont)
    local battLabelW = TM:MeasureStringX(labelFont, battLabel)
    local battSegX = cx + battLabelW + T.px(6)
    local battSegW = T.px(80)
    -- battery is 0..1; gate on (power AND hasBattery) so an absent or removed
    -- battery cell reads as empty rather than full.
    local battK = 0
    if power and hasBat and type(battery) == "number" then
        battK = math.floor(battery * 4 + 0.5)
        if battK < 0 then battK = 0 end
        if battK > 4 then battK = 4 end
    end
    -- Dim the bars when the display is off so they recede behind the text.
    local barAlpha = power and 1.0 or 0.35
    local barOnC  = { r = fgBright.r, g = fgBright.g, b = fgBright.b, a = (fgBright.a or 1) * barAlpha }
    local barOffC = { r = fgOff.r,    g = fgOff.g,    b = fgOff.b,    a = (fgOff.a    or 1) * barAlpha }
    A.drawSegBar(panel, battSegX, cy, battSegW, barH, 4, battK, barOnC, barOffC, T.px(2))

    -- VOL label + 8 segments (positioned after BATT bar with breathing room)
    local volLabelX = battSegX + battSegW + T.px(18)
    local volLabel = ZeD.tr("UI_ZeD_Radio_Vol")
    _silk(panel, volLabelX, cy + math.floor((barH - labelH) / 2), volLabel, fgDim, labelFont)
    local volLabelW = TM:MeasureStringX(labelFont, volLabel)
    local volSegX = volLabelX + volLabelW + T.px(6)
    local volSegW = math.max(0, maxX - volSegX)
    local volK = power and math.floor(volF * 8 + 0.5) or 0
    if volK < 0 then volK = 0 end
    if volK > 8 then volK = 8 end
    A.drawSegBar(panel, volSegX, cy, volSegW, barH, 8, volK, barOnC, barOffC, T.px(2))

    cy = cy + barH + T.px(14)

    -- =========== ROW 3 — Big frequency (left) + data column (right) ===========
    -- Frequency painted in UIFont.Cred1 (largest standard font ~30px) so the
    -- station number is the visual anchor of the chassis. Unit suffix in mono
    -- F3 alongside the digits. Channel name in F2 below the frequency.
    local freqFont    = ZeD.Font.sdf.head; local freqZoom = ZeD.Text.zoomPx(30)   -- 30 px design digits on the distance-field heading face (UIFont.Cred1 only renders at 1x)
    local unitFont    = T.fontF2
    local channelFont = T.fontF2
    -- Text colors don't gate on power — when the display is off the grey
    -- bg makes everything read as dim naturally. Keeping the text in the
    -- normal palette avoids it disappearing entirely on the grey face.
    local freqColor   = fgBright

    -- When off, the freq display reads as a placeholder "---.- MHz" with the
    -- station name line suppressed entirely (real LCDs go blank when unlit).
    local freqDigits, freqUnit
    if power then
        freqDigits, freqUnit = _splitFrequency(channel)
    else
        freqDigits, freqUnit = "---.-", "MHz"
    end
    local freqDigitsH = ZeD.Text.height(freqFont, freqZoom)
    local channelH    = TM:getFontHeight(channelFont)

    -- Layout: freq + data column on the SAME centered row; station-name
    -- gets its OWN full-width row anchored to the bottom edge of the LCD,
    -- spanning past the data column (so long station names don't collide
    -- with RANGE / SIG values). Frequency digits stay in the same Y
    -- regardless of power so toggling on/off doesn't shift them.
    local nameRowH   = channelH
    local nameRowY   = y + h - pad - nameRowH
    local nameGap    = T.px(6)
    -- The freq+data block centers in the vertical space ABOVE the name row.
    local freqAvailH = nameRowY - nameGap - cy
    local row3StartY = cy + math.max(0, math.floor((freqAvailH - freqDigitsH) / 2))

    ZeD.Text.draw(panel, freqFont, freqDigits, cx, row3StartY, freqZoom, freqColor.r, freqColor.g, freqColor.b, freqColor.a or 1.0, "l")
    local freqDigitsW = ZeD.Text.width(freqFont, freqDigits, freqZoom)

    -- Unit suffix (kHz / MHz) at lower-right corner of the frequency block —
    -- baseline-aligned with bottom of the digits.
    if freqUnit ~= "" then
        local unitH = TM:getFontHeight(unitFont)
        local unitX = cx + freqDigitsW + T.px(6)
        local unitY = row3StartY + (freqDigitsH - unitH) - T.px(2)
        panel:drawText(freqUnit, unitX, unitY,
            freqColor.r, freqColor.g, freqColor.b, freqColor.a or 1.0, unitFont)
    end

    -- ============ Station-name row (own line, full width) ============
    -- The station's name from the engine (getZomboidRadio():getChannelName),
    -- "Unknown Frequency" where it has none, a play-arrow prefix either way.
    -- Anchored at the bottom edge of the LCD so it spans the full width
    -- (past the data column on the right). Allows long station names like
    -- "Automated Emergency Broadcast System" without colliding with SIG/RANGE.
    if power then
        local channelName = ZeD.tr("UI_ZeD_Radio_UnknownFreq")
        local zr = (getZomboidRadio ~= nil) and getZomboidRadio() or nil
        if zr ~= nil and zr.getChannelName ~= nil
           and type(channel) == "number" and channel > 0 then
            local resolved = zr:getChannelName(channel)
            if type(resolved) == "string" and resolved ~= "" then
                channelName = resolved
            end
        end
        local nameColor = fgDim
        local nameStr = "> " .. channelName
        -- Truncate to fit display width with ellipsis if too long.
        local nameW = TM:MeasureStringX(channelFont, nameStr)
        local nameMaxW = maxX - cx
        if nameW > nameMaxW then
            local ell = "..."
            local ellW = TM:MeasureStringX(channelFont, ell)
            local trimmed = nameStr
            while #trimmed > 1 and (TM:MeasureStringX(channelFont, trimmed) + ellW) > nameMaxW do
                trimmed = trimmed:sub(1, #trimmed - 1)
            end
            nameStr = trimmed .. ell
        end
        panel:drawText(nameStr, cx, nameRowY,
            nameColor.r, nameColor.g, nameColor.b, nameColor.a or 1.0, channelFont)
    end

    -- Right-side data column: RANGE / SIG readouts. Vertically centered in
    -- row 3 alongside the frequency block. Each row = label left + right-
    -- aligned value. (This is the AM/FM chassis only: the two-way sets
    -- carry their 2-WAY readout on their own faces.)
    local dataLabels = {
        { label = ZeD.upper(ZeD.tr("IGUI_RadioStrength")), value = string.format("%d-%d MHz", math.floor(minHz / 1000), math.floor(maxHz / 1000)) },
        { label = ZeD.tr("UI_ZeD_Radio_Sig"),   value = (power and hasSignal) and ZeD.tr("UI_ZeD_Radio_SigGood") or (power and ZeD.tr("UI_ZeD_Radio_SigWeak") or "-") },
    }
    local dataFont = T.fontF2
    local dataLineH = TM:getFontHeight(dataFont) + T.px(6)
    local dataBlockH = #dataLabels * dataLineH
    local dataColX  = cx + math.floor(w * 0.55)
    -- Data column centers against the SAME vertical space as the freq digits
    -- (above the name row) so it sits beside the freq, not below it.
    local dataStartY = cy + math.max(0, math.floor((freqAvailH - dataBlockH) / 2))
    local dataY = dataStartY
    for _, row in ipairs(dataLabels) do
        local labelColor = fgDim
        panel:drawText(row.label, dataColX, dataY,
            labelColor.r, labelColor.g, labelColor.b, labelColor.a or 1.0, dataFont)
        local valW = TM:MeasureStringX(dataFont, row.value)
        local valColor = fgBright
        panel:drawText(row.value, maxX - valW, dataY,
            valColor.r, valColor.g, valColor.b, valColor.a or 1.0, dataFont)
        dataY = dataY + dataLineH
    end
end

----------------------------------------------------------------------
-- M: radioControlStrip
-- Recessed dark panel containing the power button + SEEK group + VOL group.
-- All buttons are flat-variant drawButton with chassis tokens.
-- It only draws and stamps the click zones; the click router below acts.
----------------------------------------------------------------------
function radioControlStrip(panel, x, y, w, h, brand, dd, win)
    local T = ZeD.T
    local A = ZeD.Atoms
    local TM = ZeD.TM
    -- Reset per-frame click-zone slots that this molecule owns. Other molecules
    -- own their own slots and clear them in their own renders.
    if win then
        win._radioPwrZone        = nil
        win._radioSeekBtnZones   = {}  -- [1] = down, [2] = up (the two grey buttons)
        win._radioVolBtnZones    = {}  -- [1] = down, [2] = up
    end

    local rec, btnColors, silkColor
    if brand == "premium" then
        rec = T.radio.pt
        btnColors = { bg = rec.btnBg, border = rec.btnBorder, text = rec.btnText, font = T.fontF1 }
        silkColor = rec.silkScreen
    else
        rec = T.radio.vt
        btnColors = { bg = rec.btnBg, border = rec.btnBorder, text = rec.btnText, font = T.fontF1 }
        silkColor = rec.silkScreen
    end

    -- Recessed control-strip host
    A.recessedPanel(panel, x, y, w, h, rec.recessedBg, rec.recessedHi, rec.recessedSh)

    local pad      = T.px(10)
    local pwrBtnH  = T.px(30)
    local pillH    = T.px(14)    -- SEEK/VOL pills: deliberately thinner than the buttons
    local pwrBtnY  = y + math.floor((h - pwrBtnH) / 2)
    local pillY    = y + math.floor((h - pillH) / 2)
    local cx       = x + pad
    local maxX     = x + w - pad
    local labelFont = T.fontF1
    local labelH    = TM:getFontHeight(labelFont)

    -- ============ Power button ============
    -- A small black button with a red status square and the ON / OFF word.
    -- Single button (not separate icon + button). Status square painted inside
    -- the button, left edge, with the label centered after.
    local power = _safeGet(dd, "getIsTurnedOn", false)
    local pwrLabel = power and ZeD.upper(ZeD.tr("UI_On")) or ZeD.upper(ZeD.tr("UI_Off"))
    local pwrBtnW  = T.px(60)
    if win then
        win._radioPwrZone = { x = cx, y = pwrBtnY, w = pwrBtnW, h = pwrBtnH }
    end
    ZeD.Molecules.drawButton(panel, cx, pwrBtnY, pwrBtnW, pwrBtnH, "", "flat", false, btnColors)
    -- Status indicator square inside the button at left edge
    local dotSz = T.px(10)
    local dotX  = cx + T.px(6)
    local dotY  = pwrBtnY + math.floor((pwrBtnH - dotSz) / 2)
    local dotColor = power and { r = 0.85, g = 0.30, b = 0.20, a = 1.0 }
                            or { r = 0.50, g = 0.10, b = 0.05, a = 1.0 }
    panel:drawRect(dotX, dotY, dotSz, dotSz, dotColor.a, dotColor.r, dotColor.g, dotColor.b)
    -- Label drawn on the remaining space, right of dot
    local labelArea = pwrBtnW - dotSz - T.px(12)  -- room after dot+pad
    pwrLabel        = ZeD.Atoms.truncateText(pwrLabel, labelFont, labelArea)   -- the game's word for On / Off can be long
    local labelW    = TM:MeasureStringX(labelFont, pwrLabel)
    local labelTx   = dotX + dotSz + T.px(6) + math.floor((labelArea - labelW) / 2)
    local labelTy   = pwrBtnY + math.floor((pwrBtnH - labelH) / 2)
    panel:drawText(pwrLabel, labelTx, labelTy,
        btnColors.text.r, btnColors.text.g, btnColors.text.b, 1.0, labelFont)
    cx = cx + pwrBtnW + T.px(20)

    -- ============ Helper: draw a SEEK/VOL group ============
    -- Layout: outside silkscreen label ("SEEK"/"VOL") + `-` silkscreen +
    -- TWO grey buttons (the actual click targets) + `+` silkscreen.
    -- The `-` and `+` glyphs are decorative direction labels OUTSIDE the
    -- buttons; the buttons themselves do the seek/volume up-down work
    -- (left button = down/decrement, right button = up/increment).
    local function drawGroup(label, gx, groupW, groupKey)
        local labelCenterY = y + math.floor((h - labelH) / 2)
        local lLabelW = TM:MeasureStringX(labelFont, label)
        local minusW  = TM:MeasureStringX(labelFont, "-")
        local plusW   = TM:MeasureStringX(labelFont, "+")
        local pillW = math.floor((groupW
            - lLabelW           -- "SEEK" / "VOL" silkscreen
            - T.px(10)                -- gap after label
            - minusW            -- `-` glyph (label, not interactive)
            - T.px(10)                -- gap
            - T.px(10)                -- gap between buttons
            - T.px(10)                -- gap before plus
            - plusW             -- `+` glyph (label, not interactive)
        ) / 2)
        if pillW < T.px(36) then pillW = T.px(36) end

        local lx = gx
        -- Outside silkscreen label ("SEEK" / "VOL")
        panel:drawText(label, lx, labelCenterY,
            silkColor.r, silkColor.g, silkColor.b, silkColor.a or 1.0, labelFont)
        lx = lx + lLabelW + T.px(10)

        -- `-` silkscreen direction label (NOT interactive — outside-the-button)
        panel:drawText("-", lx, labelCenterY,
            silkColor.r, silkColor.g, silkColor.b, silkColor.a or 1.0, labelFont)
        lx = lx + minusW + T.px(10)

        -- Down button (left grey) — decrement action
        local downZone = { x = lx, y = pillY, w = pillW, h = pillH }
        ZeD.Molecules.drawButton(panel, lx, pillY, pillW, pillH, "", "flat", false, btnColors)
        lx = lx + pillW + T.px(10)

        -- Up button (right grey) — increment action
        local upZone = { x = lx, y = pillY, w = pillW, h = pillH }
        ZeD.Molecules.drawButton(panel, lx, pillY, pillW, pillH, "", "flat", false, btnColors)
        lx = lx + pillW + T.px(10)

        if win then
            if groupKey == "seek" then
                win._radioSeekBtnZones = { downZone, upZone }
            else
                win._radioVolBtnZones = { downZone, upZone }
            end
        end

        -- `+` silkscreen direction label (NOT interactive — outside-the-button)
        panel:drawText("+", lx, labelCenterY,
            silkColor.r, silkColor.g, silkColor.b, silkColor.a or 1.0, labelFont)
        return lx + plusW
    end

    -- Split remaining horizontal space evenly between SEEK and VOL.
    local groupsAvail = maxX - cx - T.px(16)  -- 16px gap between groups
    local groupW = math.floor(groupsAvail / 2)
    local seekEnd = drawGroup(ZeD.tr("UI_ZeD_Radio_Seek"), cx, groupW, "seek")
    drawGroup(ZeD.tr("UI_ZeD_Radio_Vol"), seekEnd + T.px(16), groupW, "vol")
end

----------------------------------------------------------------------
-- M: radioPresetBank
-- Recessed panel containing N preset slot buttons + add/remove. Slot count
-- comes from the device's PresetContainer (deviceData:getDevicePresets()),
-- with a defensive 8-slot fallback for radios that don't expose presets.
----------------------------------------------------------------------
function radioPresetBank(panel, x, y, w, h, brand, dd, win)
    local T = ZeD.T
    local A = ZeD.Atoms
    local rec, btnColors
    if brand == "premium" then
        rec = T.radio.pt
        btnColors = { bg = rec.btnBg, border = rec.btnBorder, text = rec.btnText, font = T.fontF2 }
    else
        rec = T.radio.vt
        btnColors = { bg = rec.btnBg, border = rec.btnBorder, text = rec.btnText, font = T.fontF2 }
    end
    if win then
        win._radioPresetZones    = {}
        win._radioPresetAddZone  = nil
    end

    -- Recessed bank host
    A.recessedPanel(panel, x, y, w, h, rec.recessedBg, rec.recessedHi, rec.recessedSh)

    local pad = T.px(10)
    local cx  = x + pad
    local cy  = y + pad
    local btnH = h - pad * 2

    -- Slot count probe — falls through to 8 if the engine path is unexposed.
    -- Buttons always read as their slot number (1..N) — 1993-era hardware
    -- aesthetic, no dynamic LCD per button.
    local maxSlots = 8
    if dd.getDevicePresets ~= nil then
        local pc = dd:getDevicePresets()
        if pc ~= nil and pc.getMaxPresets ~= nil then
            local mx = pc:getMaxPresets()
            if type(mx) == "number" and mx > 0 then maxSlots = mx end
        end
    end
    -- At most 8 slots show.
    local visible = math.min(maxSlots, 8)

    -- Add button anchors to the right edge, about two slots wide.
    local addBtnW  = btnH * 2 + T.px(6)   -- ~2 squares
    local addX     = x + w - pad - addBtnW
    -- Available width for the slot row.
    local slotsAreaEnd = addX - T.px(10)
    local slotsAreaW   = slotsAreaEnd - cx
    if slotsAreaW < 0 then slotsAreaW = 0 end

    -- Slot width derived from available space — divide evenly with 4px gaps.
    local gap = T.px(4)
    local slotW = math.floor((slotsAreaW - (visible - 1) * gap) / visible)
    if slotW < T.px(24) then slotW = T.px(24) end

    for i = 1, visible do
        local sx = cx + (i - 1) * (slotW + gap)
        ZeD.Molecules.drawButton(panel, sx, cy, slotW, btnH, tostring(i),
            "flat", false, btnColors)
        if win then
            win._radioPresetZones[i] = { x = sx, y = cy, w = slotW, h = btnH }
        end
    end

    -- Add button — hard accent orange (T.accent was rendering as fallback grey
    -- through the flat-button color path; bypass the theme indirection and
    -- paint directly so the orange is guaranteed across themes/reloads).
    -- Brighter shade in assign mode = "armed for slot pick" cue.
    local assignMode = win and win._radioPresetAssignMode == true
    local addBg     = assignMode
        and { r = 1.00, g = 0.60, b = 0.20, a = 1.0 }   -- accent bright
        or  { r = 0.85, g = 0.48, b = 0.12, a = 1.0 }   -- accent
    local addBorder = { r = 1.00, g = 0.66, b = 0.26, a = 1.0 }
    local addText   = { r = 0.06, g = 0.06, b = 0.06, a = 1.0 }
    local addBtnColors = {
        bg = addBg, border = addBorder, text = addText, font = ZeD.T.fontF2,
    }
    ZeD.Molecules.drawButton(panel, addX, cy, addBtnW, btnH, "+", "flat", false, addBtnColors)
    if win then
        win._radioPresetAddZone = { x = addX, y = cy, w = addBtnW, h = btnH }
    end
end

----------------------------------------------------------------------
-- M: radioSignalWave (Premium-only)
-- 64-column harmonic sine, seeded by entry.cacheKey hash. Renders ALWAYS; power
-- state only multiplies the line color alpha. Drawn as
-- thin vertical 1px lines centered on the midline, height = abs(value) * h/2.
----------------------------------------------------------------------
function radioSignalWave(panel, x, y, w, h, win, cacheKey, power)
    local T = ZeD.T
    local cols = 64
    local wave = _getWave(win, cacheKey, cols)
    if wave == nil then return end

    -- Substrate (matches VFD background so the wave reads as part of the display).
    local bg = T.radio.vfd.bg
    panel:drawRect(x, y, w, h, bg.a or 1.0, bg.r, bg.g, bg.b)
    -- Center reference line (1px dim cyan)
    local mid = y + math.floor(h / 2)
    local dim = T.radio.vfd.dim
    panel:drawRect(x, mid, w, T.px(1), 0.30, dim.r, dim.g, dim.b)

    -- Each column gets a vertical line whose height = |wave[i]| * h/2.
    local colW = math.max(T.px(1), math.floor((w - (cols - 1) * T.px(1)) / cols))  -- (cols - 1) one-px gaps
    local lineCol = T.radio.vfd.bright
    local lineA   = power and (lineCol.a or 1.0) or ((lineCol.a or 1.0) * 0.32)
    for i = 1, cols do
        local cx = x + (i - 1) * colW
        local vh = math.floor(math.abs(wave[i]) * (h / 2 - T.px(1)))
        if vh > 0 then
            local cy = (wave[i] >= 0) and (mid - vh) or mid
            panel:drawRect(cx, cy, colW, vh, lineA, lineCol.r, lineCol.g, lineCol.b)
        end
    end

    -- Corner labels (SIG / + / −) — silkscreen-style on the chassis behind the wave.
    local font = T.fontF1
    local labelColor = T.radio.vfd.dim
    panel:drawText(ZeD.tr("UI_ZeD_Radio_Sig"), x + T.px(4), y + T.px(2), labelColor.r, labelColor.g, labelColor.b, labelColor.a or 1.0, font)
    panel:drawText("+", x + T.px(4), y + T.px(4), labelColor.r, labelColor.g, labelColor.b, 0.7, font)
    panel:drawText("-", x + T.px(4), y + h - ZeD.TM:getFontHeight(font) - T.px(2), labelColor.r, labelColor.g, labelColor.b, 0.7, font)
end

----------------------------------------------------------------------
-- M: cdPlayerModule (Premium-only)
-- Recessed dark panel with green-VFD strip + 7-button transport grid.
-- Reads the device data's hasMedia / getMediaIndex / isPlayingMedia.
----------------------------------------------------------------------
function cdPlayerModule(panel, x, y, w, h, dd, win)
    local T = ZeD.T
    local A = ZeD.Atoms
    local rec = T.radio.pt
    local cd  = T.radio.cd
    if win then win._radioCDZones = {} end

    A.recessedPanel(panel, x, y, w, h, rec.recessedBg, rec.recessedHi, rec.recessedSh)

    local pad = T.px(6)
    local cx = x + pad
    local cy = y + pad

    -- Brand silkscreen
    _silk(panel, cx, cy, "PT-CD200  *  1-BIT BITSTREAM  *  8X OVERSAMPLING", rec.silkScreen, T.fontF1)
    cy = cy + ZeD.TM:getFontHeight(T.fontF1) + T.px(2)

    -- Green-VFD strip
    local vfdH = math.max(T.px(20), math.floor((h - (cy - y) - pad) / 2))
    panel:drawRect(cx, cy, w - pad * 2, vfdH, cd.bg.a or 1.0, cd.bg.r, cd.bg.g, cd.bg.b)
    -- Inner shadow on the green VFD
    panel:drawRect(cx, cy, w - pad * 2, T.px(1), 0.55, 0, 0, 0)

    -- Read media state (defensively).
    local hasMedia  = _safeGet(dd, "hasMedia", false)
    local playing   = _safeGet(dd, "isPlayingMedia", false)
    local mediaIdx  = _safeGet(dd, "getMediaIndex", -1)

    local cdFont = T.fontF3
    local mediaText
    if hasMedia and type(mediaIdx) == "number" and mediaIdx >= 0 then
        mediaText = ZeD.tr("UI_ZeD_Radio_CdTrack", string.format("%02d", mediaIdx + 1), playing and ZeD.upper(ZeD.tr("IGUI_media_play")) or ZeD.upper(ZeD.tr("IGUI_media_stop")))
    elseif hasMedia then
        mediaText = ZeD.tr("UI_ZeD_Radio_CdLoaded")
    else
        mediaText = ZeD.tr("UI_ZeD_Radio_CdNone")
    end
    local txtColor = hasMedia and cd.bright or cd.dim
    panel:drawText(mediaText, cx + T.px(4), cy + math.floor((vfdH - ZeD.TM:getFontHeight(cdFont)) / 2),
        txtColor.r, txtColor.g, txtColor.b, txtColor.a or 1.0, cdFont)

    cy = cy + vfdH + T.px(4)

    -- 7-button transport grid: << | > play | ▲ eject | || pause | [] stop | >> | ●
    local btnColors = { bg = rec.btnBg, border = rec.btnBorder, text = rec.btnText, font = T.fontF1 }
    local btnW = math.floor((w - pad * 2 - 6 * T.px(2)) / 7)  -- 6 gaps of 2 px between 7 buttons
    local btnH = math.min(T.px(18), (y + h - pad) - cy)
    if btnH < T.px(8) then btnH = T.px(8) end
    local glyphs = { "<<", ">", "^", "||", "[]", ">>", "*" }
    for i, g in ipairs(glyphs) do
        local bx = cx + (i - 1) * (btnW + T.px(2))
        ZeD.Molecules.drawButton(panel, bx, cy, btnW, btnH, g, "flat", false, btnColors)
        if win then
            win._radioCDZones[i] = { x = bx, y = cy, w = btnW, h = btnH }
        end
    end
end

-- ============================================================================
-- ORGANISMS — chassis assembly per tier
-- ============================================================================

----------------------------------------------------------------------
-- O: renderPremium — silver Pioneer-style hi-fi chassis assembly
-- Top-down sections with 6-8px padding between.
----------------------------------------------------------------------
function renderPremium(panel, x, y, w, h, win, radioEntry)
    local T = ZeD.T
    local pt = T.radio.pt
    local dd = radioEntry.deviceData
    local cacheKey = radioEntry.cacheKey

    -- Chassis fill — silver, edge-to-edge.
    panel:drawRect(x, y, w, h, pt.chassisBg.a or 1.0,
        pt.chassisBg.r, pt.chassisBg.g, pt.chassisBg.b)

    local pad = T.px(10)
    local cy = y + pad
    local innerW = w - pad * 2
    local cx = x + pad

    -- 1. Control strip — beefier (50px) for power button + recessed pills.
    local stripH = T.px(50)
    if cy + stripH <= y + h - pad then
        radioControlStrip(panel, cx, cy, innerW, stripH, "premium", dd, win)
        cy = cy + stripH + T.px(8)
    end

    -- 2. Preset bank — taller buttons, easy targets.
    local presetH = T.px(50)
    if cy + presetH <= y + h - pad then
        radioPresetBank(panel, cx, cy, innerW, presetH, "premium", dd, win)
        cy = cy + presetH + T.px(8)
    end

    -- 3. Main display — 150 tall so the big frequency has room, with the
    -- signal wave beside it on the right (32% of the width, at most 160).
    local displayH = T.px(150)
    local power = _safeGet(dd, "getIsTurnedOn", false)
    if cy + displayH <= y + h - pad then
        local waveW = math.min(T.px(160), math.floor(innerW * 0.32))
        local mainW = innerW - waveW - T.px(4)
        radioMainDisplay(panel, cx, cy, mainW, displayH, "premium", dd)
        radioSignalWave(panel, cx + mainW + T.px(4), cy, waveW, displayH, win, cacheKey, power)
        cy = cy + displayH + T.px(8)
    end

    -- 4. CD player module — recessed (no brand strip at the foot: the CD
    -- module has the room it took)
    local cdH = T.px(64)
    if cy + cdH <= y + h - pad then
        cdPlayerModule(panel, cx, cy, innerW, cdH, dd, win)
        cy = cy + cdH + T.px(8)
    end
end

----------------------------------------------------------------------
-- O: renderValutech — cheap black plastic chassis assembly
-- Same layout as Premium MINUS signal wave + CD module.
----------------------------------------------------------------------
function renderValutech(panel, x, y, w, h, win, radioEntry)
    local T = ZeD.T
    local vt = T.radio.vt
    local dd = radioEntry.deviceData

    panel:drawRect(x, y, w, h, vt.chassisBg.a or 1.0,
        vt.chassisBg.r, vt.chassisBg.g, vt.chassisBg.b)

    local pad = T.px(10)
    local cy = y + pad
    local innerW = w - pad * 2
    local cx = x + pad

    -- 1. Control strip — 50px gives the power button + pills proper breathing room.
    local stripH = T.px(50)
    if cy + stripH <= y + h - pad then
        radioControlStrip(panel, cx, cy, innerW, stripH, "valutech", dd, win)
        cy = cy + stripH + T.px(8)
    end

    -- 2. Preset bank — 50px for the larger numbered buttons.
    local presetH = T.px(50)
    if cy + presetH <= y + h - pad then
        radioPresetBank(panel, cx, cy, innerW, presetH, "valutech", dd, win)
        cy = cy + presetH + T.px(8)
    end

    -- 3. Main display — full innerW, 150 tall so the big frequency reads.
    local displayH = T.px(150)
    if cy + displayH <= y + h - pad then
        radioMainDisplay(panel, cx, cy, innerW, displayH, "valutech", dd)
        cy = cy + displayH + T.px(8)
    end

    -- 4. (no CD module on ValuTech, and no brand strip at the foot)
end

----------------------------------------------------------------------
-- O: renderDrawer — brand dispatch
----------------------------------------------------------------------
function renderDrawer(panel, x, y, w, h, win, radioEntry)
    -- Each module clears only its own click rects, and a module the chassis skips (the CD
    -- player on a ValuTech, any module the height leaves out) would keep the last radio's: a click there would work the CD
    -- transport of the wrong radio and the controller would have stops on nothing. Every module's rects go first, each frame.
    if win then
        win._radioPwrZone, win._radioSeekBtnZones, win._radioVolBtnZones = nil, nil, nil
        win._radioPresetZones, win._radioPresetAddZone, win._radioCDZones = nil, nil, nil
    end
    if radioEntry == nil or radioEntry.deviceData == nil then
        -- Defensive: caller already checked but guard anyway.
        return
    end
    local highTier = _safeGet(radioEntry.deviceData, "getIsHighTier", false)
    if highTier then
        renderPremium(panel, x, y, w, h, win, radioEntry)
    else
        renderValutech(panel, x, y, w, h, win, radioEntry)
    end
end

-- THE SIMPLE CARD: the drawn chassis, the one way in to it. Its clicks and controller stops are the
-- chassis' own (onClick and buildFocusables below, by the rects it stamps on the window).
function ZeD.RadioTab.drawSimple(panel, x, y, w, h, win, radioEntry)
    renderDrawer(panel, x, y, w, h, win, radioEntry)
end

-- faces or simple cards. TODO: nothing sets this yet, so it stays true; the
-- planned ZeD setup switch would flip it (faces by default). The two-way sets
-- keep their faces either way (faceFor reads it only after them). ZeD setup's
-- Devices row is a different axis: Simple wraps a face as a plain card.
ZeD.RadioTab.useFaces = true

-- the face a radio tab entry is drawn as: its driver (ZeD.TwoWay or ZeD.Rtv), plate id and plate; nil for the
-- simple card. ZeD setup's Devices row (Full or Simple): Simple draws the plain card over the same
-- driver (PlainFace.lua: ZeD.PlainFace.wrap, its own size in place of the plate). The drawn chassis stays only for
-- a radio with no face at all (a modded one).
local function _simple()
    return ZeD.PlainFace ~= nil and ZeD.Settings ~= nil and ZeD.Settings.devicesSimple ~= nil and ZeD.Settings.devicesSimple() == true
end
function ZeD.RadioTab.faceFor(entry)
    local pid, des = ZeD.TwoWay.plateFor(entry)
    if des then
        if _simple() then return ZeD.PlainFace.wrap(ZeD.TwoWay), pid, ZeD.PlainFace.des(ZeD.TwoWay, pid) end
        return ZeD.TwoWay, pid, des
    end
    if ZeD.RadioTab.useFaces == false then return nil, nil, nil end
    pid, des = ZeD.Rtv.plateFor(entry)
    if des then
        if _simple() then return ZeD.PlainFace.wrap(ZeD.Rtv), pid, ZeD.PlainFace.des(ZeD.Rtv, pid) end
        return ZeD.Rtv, pid, des
    end
    return nil, nil, nil
end

-- ============================================================================
-- THE TWO-WAY RADIOS
-- A radio whose device data is two-way is drawn as its own face (TwoWayFace.lua)
-- in place of the AM/FM chassis: a walkie (or the ManPack) centred in a 220-wide
-- panel at the content's left edge, a ham set centred across the drawer, at the
-- plates' whole zoom; the footer names the brand and "* 2-WAY PORTABLE" / "BASE
-- SET". The header's full view button (and a click on the face away from its
-- controls) shows the face on its own (TwoWayFull.lua). The body (face and
-- footer) scrolls as one unit when the window is shorter than the face.
-- win._radioTw = { dev, pid, des, k, hits, face rect, ... } while a face of any
-- kind is shown (renderTwoWay draws the ordinary radios, the TVs and the plain
-- card the same way).
-- ============================================================================
local FULL_ICON, FOLD_ICON = "expand", "contract"   -- ZeD pixel icons

local function _twFocusId(win)
    local Focus = ZeD.Input and ZeD.Input.Focus
    if not (Focus and Focus.liveZone and Focus.liveElement) then return nil end
    local fz = Focus.liveZone(win)
    local zn = fz and fz.zone
    if zn ~= "charTabContent" and zn ~= "worldTabContent" then return nil end
    local el = Focus.liveElement(win)
    return el and el.id or nil
end

-- the drawer header's browse keys take the controller's mark themselves: its opts and the mark's (reused each frame)
local _browseOpts, _browseMark = {}, {}

--- The width (screen px) the radio's face needs, nil when the tab is not on one; the window gives it the half card
--- or the full card, whichever holds that (limit: the widest card the window lets the drawer be). A walkie needs
--- its panel, the face and its margins at the plates' whole zoom — only as wide as the graphic, and a card
--- is always the half card or the full card: the half card wherever one of its widths fits it,
--- else the 220 panel (the full card). A ham set needs its own width. Where
--- that is more than limit, the set's narrow face is drawn (render below), which needs a walkie's panel.
--- The ordinary radios and the CD player: the half card wherever one of their widths fits it, else the
--- full card (the hand-built radio at 0.75 and 1.5); the TVs: the full card (RtvFace.wantW).
function ZeD.RadioTab.wantW(win, base, limit)
    local r = win and win._radios and win._radios[win._radioIdx or 1]
    local drv, pid, des = ZeD.RadioTab.faceFor(r)
    if not des then return nil end
    if drv.plain then return drv.wantW(pid, des) end      -- the plain card: the half card, a TV's the full card
    local T, Sc = ZeD.T, ZeD.Scale
    local k = ZeD.Px.k((Sc and Sc.root and Sc.root()) or 1)
    if drv == ZeD.Rtv then return ZeD.Rtv.wantW(pid, des, k, limit) end
    local panel = ZeD.TwoWay.PANEL_W * k + T.sp.scrollbarW
    if des.w < ZeD.TwoWay.PANEL_W then
        local _, _, pw = ZeD.TwoWay.halfFace(pid, k)
        if pw then return pw * k + T.sp.scrollbarW end
        return panel
    end
    local wide = des.w * k + T.sp.scrollbarW
    if limit and wide > limit and ZeD.TwoWay.narrowOf(pid) then return panel end
    return wide
end

-- the full view button at the header's right end: an icon button (square, the standard
-- button height) that names itself after the shared pause; returns its rect
local _fullOpts = {}
local function _drawFullButton(panel, win, x, y, w, headerH, open, fid)
    local T = ZeD.T
    local bs = T.buttonH
    local bx, by = x + w - T.px(10) - bs, y + math.floor((headerH - bs) / 2)
    local o = _fullOpts
    o.hover = ZeD.Atoms.mouseIn(panel, bx, by, bs, bs)
    o.focus = (fid == "radio:full") and { win = win } or nil
    o.win = win
    o.hint = ZeD.tr(open and "UI_ZeD_Radio_CloseFullView" or "UI_ZeD_Radio_FullView")
    o.id = "radio:fullbtn"
    o.help = o.hint
    ZeD.Molecules.drawIconButton(panel, bx, by, bs, open and FOLD_ICON or FULL_ICON, o)
    return { x = bx, y = by, w = bs, h = bs }
end

-- where a control's list opens (screen px): under the control
local function _menuAt(tw, h)
    local p = tw and tw.panel
    if not (p and h) then return nil end
    return { x = p:getAbsoluteX() + h.x, y = p:getAbsoluteY() + h.y + h.h }
end
local function _hitById(tw, id)
    for _, hh in ipairs((tw and tw.hits) or {}) do if hh.id == id then return hh end end
    return nil
end
ZeD.RadioTab._menuAt, ZeD.RadioTab._hitById = _menuAt, _hitById

-- the face, its footer and the scrollbar under the header (y, h: the body). drv: the face's driver, ZeD.TwoWay or
-- ZeD.Rtv (the ordinary radios and the TVs, which have no footer: the brand is on the face)
local function renderTwoWay(panel, win, x, y, w, h, current, pid, des, drv)
    local T = ZeD.T
    local TW = drv or ZeD.TwoWay
    local Sc = ZeD.Scale
    local sbW = T.sp.scrollbarW
    -- the plates' whole zoom (a whole step down only when the drawer cannot hold the face; it never flips with the scrollbar)
    -- (the plain card, PlainFace.lua: no zoom and no margin; the drawer's width and as tall as its rows)
    local plain = TW.plain == true
    local k = plain and 1 or ZeD.Px.kFit((Sc and Sc.root and Sc.root()) or 1, TW.slotW(des), w - sbW)
    local pad = TW.PAD * k
    local footH = TW.footer and T.px(22) or 0
    local faceH = plain and TW.height(current.radioInstance, pid, w - sbW) or des.h * k
    local contentH = pad + faceH + pad + footH
    local scroll = win._radioScroll
    if not scroll then scroll = ZeD_ScrollbarState:new(); win._radioScroll = scroll end
    local needs = contentH > h
    scroll.visible = needs
    local cw = needs and (w - sbW) or w
    local off = 0
    if needs then
        scroll.x, scroll.y, scroll.height = x + w - sbW, y, h
        scroll:setBarSize(h / contentH)
        -- (the drawer passes the radio tab its presses only: the drag and the release are read here)
        if scroll.dragging and isMouseButtonDown(0) then scroll:handleMouseMove(panel:getMouseY() - scroll.y)
        elseif (scroll.dragging or scroll.upPressed or scroll.downPressed) and not isMouseButtonDown(0) then scroll:handleMouseUp() end
        off = math.floor(scroll.scrollPos * (contentH - h))
    else
        scroll:setScrollPos(0)
    end
    -- centred across the drawer: a walkie's drawer is its own panel, a ham set's the full drawer
    local faceW = plain and cw or des.w * k
    local fx = x + math.floor((cw - faceW) / 2)
    local fy0 = y + pad                                       -- the face's top, scrolled to the top
    local tw = win._radioTw
    local dev = current.radioInstance
    if not (tw and tw.dev == dev) then tw = { dev = dev }; win._radioTw = tw end
    tw.drv, tw.panel = TW, panel
    -- the controller: the focused control kept in view
    local fid = _twFocusId(win)
    local fctl = fid and fid:match("^radio:tw:(.+)$")
    if needs and fctl and tw.follow ~= fid then
        tw.follow = fid
        for _, hh in ipairs(tw.hits or {}) do
            if hh.id == fctl then
                local cy = hh.y - (tw.fy or fy0) + pad                  -- its top within the body
                local newOff = off
                if cy < off then newOff = cy elseif cy + hh.h > off + h then newOff = cy + hh.h - h end
                newOff = math.max(0, math.min(contentH - h, newOff))
                if newOff ~= off then scroll:setScrollPos(newOff / (contentH - h)); off = newOff end
            end
        end
    end
    local fy = fy0 - off
    panel:setStencilRect(x, y, cw, h)
    -- a held key (the mouse): a short press acts on the release, a long one names / stores (MEM, the army set's 1..6)
    local chr = win._playerObj
    local press = tw.press
    if press and not press.fired then
        if isMouseButtonDown(0) then TW.holdTick(press, chr, dev, nil)
        else
            press.fired = true
            TW.press(chr, dev, press.id, nil, _menuAt(tw, _hitById(tw, press.id)))
        end
    end
    if press and press.fired and not isMouseButtonDown(0) then tw.press = nil end
    local hov = TW.hitAt(tw.hits, panel:getMouseX(), panel:getMouseY())
    local hits = TW.drawFace(panel, fx, fy, k, { dev = dev, pid = pid, des = des, focusId = fctl,
        hoverId = (not fctl) and hov and hov.id or nil, pressId = tw.press and tw.press.id or nil,
        w = faceW, minH = needs and 0 or h, win = win })
    -- the footer: at the drawer's foot, or under the face when the body scrolls
    if TW.footer then
        local footY = math.max(fy + des.h * k + pad, y + h - footH)
        TW.footer(panel, x, footY, cw, footH, pid, _safeGet(current.deviceData, "getIsHighTier", false))
    end
    panel:clearStencilRect()
    if needs then scroll:draw(panel) end
    tw.pid, tw.des, tw.k, tw.hits, tw.fy = pid, des, k, hits, fy
    tw.face = { x = fx, y = fy, w = faceW, h = faceH }
    tw.view = { x = x, y = y, w = cw, h = h }
end

-- ============================================================================
-- TOP-LEVEL TAB RENDERER
-- ============================================================================

--- Render the radio tab content into the drawer.
--- @param panel  The drawer ISPanel
--- @param win    The window owning the drawer (Char or World)
--- @param x, y   Top-left of the tab content area in panel-local coords
--- @param w, h   Available drawing region
function ZeD.RadioTab.render(panel, win, x, y, w, h)
    local T = ZeD.T
    if T == nil then return end

    -- ---- Hold-to-repeat for SEEK ----
    -- The press itself already fired one step (mouse: in onClick; gamepad: in
    -- onHoldActivate at the A_HOLD_MS threshold). After a 250ms grace the
    -- auto-repeat kicks in on an accelerating interval: 200ms → 100ms → 50ms
    -- → 25ms as hold time grows. Released immediately when the source button
    -- is no longer down — mouse uses isMouseButtonDown(0); the gamepad path
    -- polls JoypadButton.A:isDown on the captured joypad id.
    if win._radioSeekHold then
        local hold = win._radioSeekHold
        local stillDown
        if hold.source == "gamepad" then
            stillDown = hold.jid ~= nil
                        and JoypadButton and JoypadButton.A
                        and JoypadButton.A:isDown(hold.jid)
        else
            stillDown = isMouseButtonDown(0)
        end
        if not stillDown then
            win._radioSeekHold = nil
        else
            local now = getTimestampMs()
            local elapsed = now - hold.startMs
            if elapsed >= 250 then
                local interval
                if     elapsed < 1000 then interval = 200
                elseif elapsed < 2500 then interval = 100
                elseif elapsed < 5000 then interval = 50
                else                       interval = 25
                end
                if (now - hold.lastFireMs) >= interval then
                    local r = (win._radios or {})[win._radioIdx or 1]
                    if r and r.deviceData then
                        _channelStep(r.deviceData, hold.dir)
                    end
                    hold.lastFireMs = now
                end
            end
        end
    end

    local radios = win._radios or {}

    -- Empty state — one line, no header.
    if #radios == 0 then
        -- drop any stale gamepad focus id so the seed gate fires fresh
        -- next time a radio is equipped (the gate only writes on nil).
        win._gpFocusedRadioCtl = nil
        -- one dim F2 line at the list's text inset, a full sentence (no header here: 10u from the top)
        ZeD.Molecules.drawEmptyLine(panel, x + T.px(10), y + T.px(10), w - T.px(20), ZeD.tr("UI_ZeD_Radio_None"))
        return
    end

    -- the tab stays on the radio it was opened on or browsed to while the list re-sorts by distance
    if win._radioFollow then
        local at = ZeD.RadioTab.indexOf(radios, win._radioFollow)
        if at then win._radioIdx = at else win._radioFollow = nil end
    end

    -- Clamp index defensively (window refresh may have shrunk the list mid-frame).
    local idx = win._radioIdx or 1
    if idx < 1 then idx = 1 end
    if idx > #radios then idx = #radios end
    win._radioIdx = idx

    local current = radios[idx]
    local subtitle = getText("IGUI_ItemType_Radio")
    if current and current.deviceData then
        local n = _safeGet(current.deviceData, "getDeviceName", "")
        if type(n) == "string" and n ~= "" then
            -- Strip mod prefix; preserve engine title-case (it's an item name,
            -- not branding — uppercasing it makes it look like a tier label).
            local trimmed = n:match("^[^%.]+%.(.+)$")
            subtitle = trimmed or n
        end
    end

    -- Standard ZeD drawer-header strip height — sourced from the spacing token.
    local headerH = (T.sp and T.sp.tabHeaderH) or T.px(37)
    -- a radio with a face: its own face (renderTwoWay above); a two-way set's full view button in the header
    local fDrv, twPid, twDes = ZeD.RadioTab.faceFor(current)
    local isTw = fDrv == ZeD.TwoWay
    if not twDes then win._radioTw, win._radioFullZone = nil, nil end
    if not isTw then win._radioFullZone = nil end
    -- the width that fills the card: a walkie's for the half card
    -- (the drawer is that card wherever one fits; centred in the drawer, its margins its own); a ham set's for
    -- the drawer as a machine plate's. A ham set the tab cannot hold at the plates' whole zoom: its narrow face
    -- (the drawer is then a walkie's width). The ordinary radios and the TVs the same way (RtvFace.pickFace).
    if twDes and not fDrv.plain then
        local Sc = ZeD.Scale
        local k0 = ZeD.Px.k((Sc and Sc.root and Sc.root()) or 1)
        if not isTw then
            twPid, twDes = ZeD.Rtv.pickFace(twPid, w - T.sp.scrollbarW, k0)
        elseif twDes.w < ZeD.TwoWay.PANEL_W then
            local hPid, hDes = ZeD.TwoWay.halfFace(twPid, k0)
            if hDes then twPid, twDes = hPid, hDes end
        else
            local fPid, fw = ZeD.Px.pickWidth(twPid, w - T.sp.scrollbarW, k0)
            local nPid, nDes = ZeD.TwoWay.narrowOf(twPid)
            if fw then twPid, twDes = fPid, ZeD.PhysPx.plates[fPid]
            elseif nDes and twDes.w * k0 > w - T.sp.scrollbarW then twPid, twDes = nPid, nDes end
        end
    end
    -- a walkie's tab is only as wide as its face: its name shows when it fits whole (the face and the footer carry the
    -- brand), never cut to a few letters (the header molecule's own measures)
    -- (a walkie's wider faces, 237 px at 1.25, are still a walkie's tab; so is an ordinary radio's, which has no
    -- full view button)
    local fullW = isTw and (T.buttonH + T.px(8)) or 0
    if twDes and ((isTw and (twDes.w < ZeD.TwoWay.PANEL_W or not ZeD.TwoWay.isBase(twPid)))
            or (not isTw and not ZeD.Rtv.isTv(twPid))) then
        local tm = ZeD.TM
        local loc = (current and ZeD.RadioTab.locationName(current.locationTag) or "-") .. " (" .. tostring(idx) .. ")"
        local used = T.px(10) + T.px(24) + T.px(6) + tm:MeasureStringX(T.fontF1, loc) + 2 * T.px(12) + T.px(6) + T.px(24) + T.px(10)
        local room = w - used - T.px(10) - fullW
        if tm:MeasureStringX(T.fontF2, subtitle) > room then subtitle = "" end
    end
    -- 1. Drawer-internal header strip (browse + subtitle + location pill).
    -- Header molecule returns the prev/next browse-button rects so onClick
    -- can hit-test them; stash on win like the other radio click zones.
    -- The browse key the controller is on carries its mark under the triangle (the header's own option).
    local hfid = _twFocusId(win)
    _browseOpts.focusId = (hfid == "radio:browsePrev" and "prev") or (hfid == "radio:browseNext" and "next") or nil
    _browseOpts.focus = _browseOpts.focusId and _browseMark or nil
    _browseMark.win = win
    local prevZone, nextZone = ZeD.Molecules.drawDrawerInternalHeader(panel, x, y, w,
        { idx = idx, total = #radios }, subtitle, current and ZeD.RadioTab.locationName(current.locationTag) or "",
        (twDes and isTw) and fullW or nil, _browseOpts)
    win._radioBrowsePrevZone = prevZone
    win._radioBrowseNextZone = nextZone

    -- 2. Chassis below the header: the face, or the simple card.
    if twDes then
        if isTw then
            local pn = win._playerObj and win._playerObj:getPlayerNum() or 0
            local open = ZeD.TwoWayFull.showing(pn) == current.radioInstance
            win._radioFullZone = _drawFullButton(panel, win, x, y, w, headerH, open, _twFocusId(win))
        end
        -- (its clip is set and cleared once, as every tab's: a clip set again here outlived the frame's drawer and cut
        -- off what drew after it, the full view among them)
        renderTwoWay(panel, win, x, y + headerH, w, h - headerH, current, twPid, twDes, fDrv)
    else
        ZeD.RadioTab.drawSimple(panel, x, y + headerH, w, h - headerH, win, current)
    end

    -- 3. The controller's mark (ZeD.Focus.mark) on the focused chassis control, painted after
    -- the chassis: the keys' printing is the hardware's own. Only the focused window, the
    -- controller in use, and the radio tab's controls ("radio:..." ids).
    local fid = _twFocusId(win)
    if fid and fid:sub(1, 6) == "radio:" then
        -- Resolve the focused id to its stamped rect zone. Mirrors the click router's
        -- zone lookup: same rect, same paint surface.
        local zr = nil
        if     fid == "radio:power"       then zr = win._radioPwrZone
        elseif fid == "radio:seek-"       then zr = win._radioSeekBtnZones and win._radioSeekBtnZones[1]
        elseif fid == "radio:seek+"       then zr = win._radioSeekBtnZones and win._radioSeekBtnZones[2]
        elseif fid == "radio:vol-"        then zr = win._radioVolBtnZones  and win._radioVolBtnZones[1]
        elseif fid == "radio:vol+"        then zr = win._radioVolBtnZones  and win._radioVolBtnZones[2]
        elseif fid == "radio:presetAdd"   then zr = win._radioPresetAddZone
        else
            -- Indexed forms: radio:preset:N or radio:cd:N
            local kind, nStr = fid:match("^radio:([%a]+):(%d+)$")
            local n = tonumber(nStr or "")
            if n then
                if     kind == "preset" then zr = win._radioPresetZones and win._radioPresetZones[n]
                elseif kind == "cd"     then zr = win._radioCDZones     and win._radioCDZones[n]
                end
            end
        end
        if zr and (zr.w or 0) > 0 then
            ZeD.Focus.mark(panel, zr.x, zr.y, zr.w, zr.h, { win = win })
        end
    end
end

-- ============================================================================
-- CLICK HANDLER
-- ============================================================================

-- Hit-test helper: true when (x, y) lies inside the zone (no zone: false).
local function _hitZone(zone, x, y)
    if not zone then return false end
    return x >= zone.x and x < zone.x + zone.w
       and y >= zone.y and y < zone.y + zone.h
end

-- Seek step, in the channel's own units (88000 is 88.0 MHz, as above): 100,
-- a tenth of the displayed MHz, so every station tunable in PZ is reachable;
-- skipping in larger steps would leave stations unreachable. A radio whose
-- range tops 1,500,000 steps 100000 instead.
local function _seekStep(dd)
    local maxHz = _safeGet(dd, "getMaxChannelRange", 1000000)
    if type(maxHz) ~= "number" or maxHz <= 1500000 then return 100 end
    return 100000
end

local function _clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- ----------------- Action functions -----------------

local function _browsePrev(win)
    local n = (win._radios and #win._radios) or 0
    if n <= 1 then return end
    local idx = (win._radioIdx or 1) - 1
    if idx < 1 then idx = n end
    win._radioIdx = idx
    win._radioFollow = win._radios[idx] and win._radios[idx].radioInstance or nil
    -- Cancel any pending preset-assign that was queued for the old radio.
    win._radioPresetAssignMode = false
end

local function _browseNext(win)
    local n = (win._radios and #win._radios) or 0
    if n <= 1 then return end
    local idx = (win._radioIdx or 1) + 1
    if idx > n then idx = 1 end
    win._radioIdx = idx
    win._radioFollow = win._radios[idx] and win._radios[idx].radioInstance or nil
    win._radioPresetAssignMode = false
end

local function _powerToggle(dd)
    if dd == nil or dd.setIsTurnedOn == nil or dd.getIsTurnedOn == nil then return end
    -- setIsTurnedOn asks canBePoweredHere, which throws for a set with no square: nothing to switch there
    if not ZeD.RadioOps.poweredHere(dd) then return end
    dd:setIsTurnedOn(not dd:getIsTurnedOn())
end

-- Bound to the file-local forward decl above so render() can reference it.
_channelStep = function(dd, dir)
    if dd == nil or dd.setChannel == nil or dd.getChannel == nil then return end
    local cur = dd:getChannel() or 0
    local minHz = _safeGet(dd, "getMinChannelRange", 75000)
    local maxHz = _safeGet(dd, "getMaxChannelRange", 1000000)
    local step  = _seekStep(dd)
    dd:setChannel(_clamp(cur + dir * step, minHz, maxHz))
end

local function _volStep(dd, dir)
    if dd == nil or dd.setDeviceVolume == nil or dd.getDeviceVolume == nil then return end
    local cur = dd:getDeviceVolume() or 0.5
    local nextV = _clamp(cur + dir * 0.125, 0.0, 1.0)
    dd:setDeviceVolume(nextV)
end

local function _presetApply(dd, slotIdx)
    if dd == nil or dd.getDevicePresets == nil or dd.setChannel == nil then return end
    local pc = dd:getDevicePresets()
    if pc == nil or pc.getPresets == nil then return end
    local list = pc:getPresets()
    if list == nil or list.size == nil or list.get == nil then return end
    if slotIdx < 1 or slotIdx > list:size() then return end
    local entry = list:get(slotIdx - 1)
    if entry == nil or entry.getFrequency == nil then return end
    local freq = entry:getFrequency()
    if type(freq) == "number" and freq > 0 then dd:setChannel(freq) end
end

-- Toggle preset assign mode: while ON, the next slot click stores the
-- current station to that slot (overwriting if filled). Flag lives on the
-- window so per-frame renderers can paint the `+` button brighter as a cue.
local function _presetToggleAssign(win)
    win._radioPresetAssignMode = not (win._radioPresetAssignMode == true)
end

-- Store the current frequency at slotIdx, overwriting if filled. If the list
-- has fewer entries than slotIdx, gap entries are inserted with frequency 0
-- (rendered as plain slot numbers) so the user's chosen slot N is honored
-- exactly.
local function _presetStore(dd, slotIdx)
    if dd == nil or dd.getDevicePresets == nil or dd.getChannel == nil then return end
    local pc = dd:getDevicePresets()
    if pc == nil or pc.getPresets == nil or pc.getMaxPresets == nil then return end
    local list = pc:getPresets()
    if list == nil or list.size == nil then return end
    local maxSlots = pc:getMaxPresets() or 8
    if slotIdx < 1 or slotIdx > maxSlots then return end

    local cur = dd:getChannel() or 0
    if cur <= 0 then return end

    -- Extend the list with empty (freq=0) gap entries up to slotIdx if needed.
    if list.add ~= nil and PresetEntry ~= nil and PresetEntry.new ~= nil then
        while list:size() < slotIdx do
            local idx = list:size() + 1
            list:add(PresetEntry.new("Preset " .. tostring(idx), 0))
        end
    end

    -- Mutate the target entry's frequency to current channel.
    if list.get ~= nil and list:size() >= slotIdx then
        local entry = list:get(slotIdx - 1)
        if entry ~= nil and entry.setFrequency ~= nil then
            entry:setFrequency(cur)
        end
    end

    if dd.transmitPresets ~= nil then dd:transmitPresets() end
end

-- CD transport stub — only Premium chassis surfaces these. Buttons:
-- 1: <<       2: > play     3: ^ eject    4: || pause
-- 5: [] stop  6: >>          7: * record
local function _cdTransport(dd, btnIdx)
    if dd == nil then return end
    if btnIdx == 2 then  -- play
        if dd.StartPlayMedia ~= nil then dd:StartPlayMedia() end
    elseif btnIdx == 5 then  -- stop
        if dd.StopPlayMedia ~= nil then dd:StopPlayMedia() end
    end
    -- <<, >>, eject, pause, record: not wired yet (the engine's calls for these are less dependable)
end

--- Click router — called from each window's drawer.onMouseDown when the
--- active tab is "radio". Coordinates are panel-local (relative to the drawer).
--- Returns true when the click was the tab's.
function ZeD.RadioTab.onClick(win, x, y)
    if win == nil then return false end

    -- Browse arrows in the drawer header
    if _hitZone(win._radioBrowsePrevZone, x, y) then
        _browsePrev(win); return true
    end
    if _hitZone(win._radioBrowseNextZone, x, y) then
        _browseNext(win); return true
    end

    -- a face: the full view button (two-way sets), the scrollbar, the face's controls; a click on a two-way face away
    -- from them opens full view
    local tw = win._radioTw
    local cur = win._radios and win._radios[win._radioIdx or 1]
    if tw and cur and cur.radioInstance == tw.dev then
        local TW, chr = tw.drv or ZeD.TwoWay, win._playerObj
        local isTw = TW == ZeD.TwoWay
        if isTw and _hitZone(win._radioFullZone, x, y) then ZeD.TwoWayFull.toggle(chr, tw.dev, win); return true end
        local sc = win._radioScroll
        if sc and sc.visible and x >= sc.x and x < sc.x + sc.width and y >= sc.y and y < sc.y + sc.height then
            sc:handleMouseDown(y - sc.y); return true
        end
        if not _hitZone(tw.view, x, y) then return true end
        local h = TW.hitAt(tw.hits, x, y)
        if h then
            -- (a key that opens a list, as a held one, acts on the release: RtvFace.onRelease)
            if (TW.onRelease or TW.holdable)(h.id) then tw.press = { id = h.id, t0 = getTimestampMs(), fired = false }
            elseif h.knob then TW.press(chr, tw.dev, h.id, x - (h.x + h.w / 2), _menuAt(tw, h))
            else
                tw.press = { id = h.id, t0 = getTimestampMs(), fired = true }    -- shaded while held; it acts on the press
                TW.press(chr, tw.dev, h.id, nil, _menuAt(tw, h))
            end
            return true
        end
        if isTw and _hitZone(tw.face, x, y) then ZeD.TwoWayFull.open(chr, tw.dev, win) end
        return true
    end

    -- Everything else needs a current radio
    local radios = win._radios or {}
    local idx = win._radioIdx or 1
    local current = radios[idx]
    if current == nil or current.deviceData == nil then return false end
    local dd = current.deviceData

    -- Power
    if _hitZone(win._radioPwrZone, x, y) then
        _powerToggle(dd); return true
    end

    -- SEEK group — the two grey buttons are the actual click targets.
    -- Left button = down (decrement), right button = up (increment).
    -- The `-` and `+` silkscreen glyphs around them are decorative labels.
    -- Press also arms the hold-to-repeat state so render() can fire repeat
    -- steps on an accelerating interval while the mouse stays pressed.
    if win._radioSeekBtnZones then
        if _hitZone(win._radioSeekBtnZones[1], x, y) then
            _channelStep(dd, -1)
            win._radioSeekHold = { dir = -1, startMs = getTimestampMs(),
                                   lastFireMs = getTimestampMs() }
            return true
        end
        if _hitZone(win._radioSeekBtnZones[2], x, y) then
            _channelStep(dd,  1)
            win._radioSeekHold = { dir =  1, startMs = getTimestampMs(),
                                   lastFireMs = getTimestampMs() }
            return true
        end
    end

    -- VOL group — same down/up convention.
    if win._radioVolBtnZones then
        if _hitZone(win._radioVolBtnZones[1], x, y) then
            _volStep(dd, -1); return true
        end
        if _hitZone(win._radioVolBtnZones[2], x, y) then
            _volStep(dd,  1); return true
        end
    end

    -- Preset slots — branch on assign mode:
    --   assign-mode ON  : click stores the current station to the chosen slot
    --                     (overwrites if already filled), then exits the mode
    --   assign-mode OFF : click applies the stored frequency to the radio
    if win._radioPresetZones then
        for i, z in ipairs(win._radioPresetZones) do
            if _hitZone(z, x, y) then
                if win._radioPresetAssignMode then
                    _presetStore(dd, i)
                    win._radioPresetAssignMode = false
                else
                    _presetApply(dd, i)
                end
                return true
            end
        end
    end

    -- `+` button — toggles assign mode. Clicking `+` while already in assign
    -- mode cancels back to normal mode without storing anything.
    if _hitZone(win._radioPresetAddZone, x, y) then
        _presetToggleAssign(win)
        return true
    end

    -- CD transport (the zones only the Premium chassis' CD module stamps)
    if win._radioCDZones then
        for i, z in ipairs(win._radioCDZones) do
            if _hitZone(z, x, y) then
                _cdTransport(dd, i); return true
            end
        end
    end

    return false
end

-- the D-pad or the wheel turning a knob: held or spun, the tuning runs faster (s = { t, streak })
local function _turnStreak(s, gap)
    local t = getTimestampMs()
    if t - s.t < gap then s.streak = s.streak + 1 else s.streak = 0 end
    s.t = t
    return s.streak
end

--- The mouse wheel over a face (both windows' drawers ask while the radio tab is up): the knob under the
--- pointer turns, anywhere else the body scrolls. Returns true when it used the wheel.
function ZeD.RadioTab.onWheel(win, del, x, y)
    local tw = win and win._radioTw
    if not tw then return false end
    local TW = tw.drv or ZeD.TwoWay
    local h = _hitZone(tw.view, x, y) and TW.hitAt(tw.hits, x, y) or nil
    if h and h.knob then
        win._radioWheel = win._radioWheel or { t = 0, streak = 0 }
        local n = _turnStreak(win._radioWheel, 160)   -- (a brisk hand spins about 10 notches a second: a 110 ms gap sat right on it)
        local mult = (h.id == "tune") and TW.turnMult(tw.pid, n) or 1
        TW.turn(win._playerObj, tw.dev, h.id, del > 0 and -1 or 1, mult)
        return true
    end
    local sc = win._radioScroll
    if sc and sc.visible then sc:handleMouseWheel(del); return true end
    return false
end

--- A right-click on a face's control: its second meaning (MEM names, a preset key stores, a knob
--- turns down). Returns true when it was on the face.
function ZeD.RadioTab.onRightClick(win, x, y)
    local tw = win and win._radioTw
    if not tw then return false end
    local TW = tw.drv or ZeD.TwoWay
    local h = _hitZone(tw.view, x, y) and TW.hitAt(tw.hits, x, y) or nil
    if h then TW.secondary(win._playerObj, tw.dev, h.id, nil) end
    return h ~= nil
end

--- Register the radio tab into a tab-renderer dispatch table.
--- Called by both ZeD_CharacterWindow and ZeD_WorldWindow at module-load time.
function ZeD.RadioTab.register(dispatchTable)
    dispatchTable["radio"] = ZeD.RadioTab.render
end

-- ============================================================================
-- FOCUSABLE BUILDER — ring elements for the host window's tab-content
-- ============================================================================
-- Called each frame from the per-window panel-focusable dispatcher
-- (_buildPanelFocusables in Char, _buildWorldPanelFocusables in World) when
-- the Radio tab is active. Returns elements for LB/RB/D-pad navigation in
-- click-router scan order so cone-nav L→R / U→D feels natural; for the
-- simple card:
--   [browsePrev, browseNext, power, seek-, seek+, vol-, vol+,
--    preset:1..N, presetAdd, cd:1..7 (Premium only)]
-- and for a face, the order its own builder below gives.
-- Mouse and gamepad share the same panel-local rect zones (_radioPwrZone,
-- _radioSeekBtnZones, _radioPresetZones, etc.) populated by the chassis
-- molecules each render — builder + render stay in lock-step.

-- An ordinary radio's or a TV's face: its controls first, power first (the pad rule: focus lands on
-- the primary control), then the rest in reading order, then the header's
-- browse keys. A presses (a list opens under the key, and the focus comes back to the key when it closes), held (or
-- X) a preset stores; up / down on a knob turns it, left / right walk on. The focus stays on the key it pressed.
local function _rtvFocusables(win, tw)
    local R = ZeD.Rtv
    local dev = tw.dev
    local elements = {}
    local onFocus = function(w, e) w._gpFocusedRadioCtl = e.id end
    for _, h in ipairs(R.focusOrder(tw.hits, tw.k)) do
        local id = h.id
        local el = { x = h.x, y = h.y, w = h.w, h = h.h, id = "radio:tw:" .. id, onFocus = onFocus }
        if h.knob then
            if id == "volpwr" then el.onActivate = function(w) R.press(w._playerObj, dev, "volpwr") end end
            el.onDpadDir = function(w, e, dir)
                if dir ~= "up" and dir ~= "down" then return false end
                w._radioPadTurn = w._radioPadTurn or { t = 0, streak = 0 }
                local n = _turnStreak(w._radioPadTurn, 260)
                R.turn(w._playerObj, dev, id, dir == "up" and 1 or -1, (id == "tune") and R.turnMult(tw.pid, n) or 1)
                return true
            end
        else
            el.onActivate = function(w)
                local t = w._radioTw
                R.press(w._playerObj, dev, id, nil, _menuAt(t, _hitById(t, id)))
            end
            if R.holdable(id) then
                el.onHoldActivate = function(w) R.secondary(w._playerObj, dev, id) end
                el.onContextMenu = function(w) R.secondary(w._playerObj, dev, id) end
            end
        end
        elements[#elements + 1] = el
    end
    local function addHeader(z, id, fn)
        if z and (z.w or 0) > 0 then elements[#elements + 1] = { x = z.x, y = z.y, w = z.w, h = z.h, id = id, onFocus = onFocus, onActivate = fn } end
    end
    addHeader(win._radioBrowsePrevZone, "radio:browsePrev", function(w) _browsePrev(w); w._gpFocusedRadioCtl = nil end)
    addHeader(win._radioBrowseNextZone, "radio:browseNext", function(w) _browseNext(w); w._gpFocusedRadioCtl = nil end)
    if elements[1] and win._gpFocusedRadioCtl == nil then win._gpFocusedRadioCtl = elements[1].id end
    return elements
end

-- The plain card (PlainFace.lua, Devices: Simple): its controls in the order it draws them (the face's order: power
-- first, top to bottom, then the footer band), then the header's browse keys. A presses (a list opens under the key);
-- held (or X) a preset key stores and MEM names. A stepper is one stop: left / right turn it (the tuning faster
-- while held), up / down move on, since the card is a column.
local function _plainFocusables(win, tw)
    local D = tw.drv
    local dev = tw.dev
    local elements = {}
    local onFocus = function(w, e) w._gpFocusedRadioCtl = e.id end
    for _, h in ipairs(D.focusOrder(tw.hits)) do
        local id = h.id
        local el = { x = h.x, y = h.y, w = h.w, h = h.h, id = "radio:tw:" .. id, onFocus = onFocus }
        if h.knob then
            el.onDpadDir = function(w, e, dir)
                if dir ~= "left" and dir ~= "right" then return false end
                w._radioPadTurn = w._radioPadTurn or { t = 0, streak = 0 }
                local n = _turnStreak(w._radioPadTurn, 260)
                D.turn(w._playerObj, dev, id, dir == "right" and 1 or -1, (id == "tune") and D.turnMult(tw.pid, n) or 1)
                return true
            end
        else
            el.onActivate = function(w)
                local t = w._radioTw
                D.press(w._playerObj, dev, id, nil, _menuAt(t, _hitById(t, id)))
            end
            if D.holdable(id) then
                el.onHoldActivate = function(w) D.secondary(w._playerObj, dev, id, nil) end
                el.onContextMenu = function(w) D.secondary(w._playerObj, dev, id, nil) end
            end
        end
        elements[#elements + 1] = el
    end
    local function addHeader(z, id, fn)
        if z and (z.w or 0) > 0 then elements[#elements + 1] = { x = z.x, y = z.y, w = z.w, h = z.h, id = id, onFocus = onFocus, onActivate = fn } end
    end
    addHeader(win._radioBrowsePrevZone, "radio:browsePrev", function(w) _browsePrev(w); w._gpFocusedRadioCtl = nil end)
    addHeader(win._radioBrowseNextZone, "radio:browseNext", function(w) _browseNext(w); w._gpFocusedRadioCtl = nil end)
    if elements[1] and win._gpFocusedRadioCtl == nil then win._gpFocusedRadioCtl = elements[1].id end
    return elements
end

--- The controller's stops on the radio tab (both windows call it while the tab is up): the plain card's, an
--- ordinary radio's or a TV's face, a two-way face, else the simple card's stamped zones.
function ZeD.RadioTab.buildFocusables(win)
    if not win then return {} end
    local rtw = win._radioTw
    local rcur = win._radios and win._radios[win._radioIdx or 1]
    -- the plain card (Devices: Simple): its rows top to bottom, then its footer band (above)
    if rtw and rtw.drv and rtw.drv.plain and rcur and rcur.radioInstance == rtw.dev and rtw.hits then
        return _plainFocusables(win, rtw)
    end
    -- an ordinary radio's or a TV's face (above)
    if rtw and rtw.drv == ZeD.Rtv and rcur and rcur.radioInstance == rtw.dev and rtw.hits then
        return _rtvFocusables(win, rtw)
    end
    local elements = {}

    -- Append helper. Per-zone nil guard skips controls whose rect wasn't
    -- stamped this frame (radio tab not yet rendered, ValuTech without a
    -- CD slot, etc.) — that's how empty-state filtering happens naturally
    -- without an explicit gate.
    local function addZone(z, id, onAct)
        if z == nil or (z.w or 0) <= 0 then return end
        elements[#elements + 1] = {
            x = z.x, y = z.y, w = z.w, h = z.h, id = id,
            onFocus    = function(w, el) w._gpFocusedRadioCtl = el.id end,
            onActivate = onAct,
        }
    end

    -- Re-fetch deviceData on every press, never capture. Browse-prev/next
    -- mutates win._radioIdx mid-focus; a captured dd would tune the OLD
    -- radio after a swap. Re-fetch keeps the gamepad path 1:1 with the
    -- click router's per-click lookup.
    local function curDD()
        local r = win._radios
        if r == nil then return nil end
        local cur = r[win._radioIdx or 1]
        return cur and cur.deviceData or nil
    end

    -- ---- Drawer header browse buttons -------------------------------------
    -- _browsePrev/_browseNext clear preset-assign mode internally; we also
    -- nil out _gpFocusedRadioCtl because preset count and CD presence may
    -- differ between radios, leaving the previous element id invalid.
    addZone(win._radioBrowsePrevZone, "radio:browsePrev",
        function(w) _browsePrev(w); w._gpFocusedRadioCtl = nil end)
    addZone(win._radioBrowseNextZone, "radio:browseNext",
        function(w) _browseNext(w); w._gpFocusedRadioCtl = nil end)

    -- ---- A two-way face: the full view button, then the face's controls in reading order. A presses, held (or
    -- X) MEM names and the army set's 1..6 store; up / down on a knob turns it, left / right walk on.
    local tw = win._radioTw
    local cur = win._radios and win._radios[win._radioIdx or 1]
    if tw and cur and cur.radioInstance == tw.dev and tw.hits then
        local TW = ZeD.TwoWay
        local dev = tw.dev
        addZone(win._radioFullZone, "radio:full", function(w) ZeD.TwoWayFull.toggle(w._playerObj, dev, w) end)
        for _, h in ipairs(TW.readingOrder(tw.hits, tw.k)) do
            local id = h.id
            local el = { x = h.x, y = h.y, w = h.w, h = h.h, id = "radio:tw:" .. id,
                         onFocus = function(w, e) w._gpFocusedRadioCtl = e.id end }
            if h.knob then
                if id == "vol" then el.onActivate = function(w) TW.press(w._playerObj, dev, "vol") end end
                el.onDpadDir = function(w, e, dir)
                    if dir ~= "up" and dir ~= "down" then return false end
                    w._radioPadTurn = w._radioPadTurn or { t = 0, streak = 0 }
                    local n = _turnStreak(w._radioPadTurn, 260)
                    TW.turn(w._playerObj, dev, id, dir == "up" and 1 or -1, (id == "tune") and TW.turnMult(tw.pid, n) or 1)
                    return true
                end
            else
                el.onActivate = function(w) TW.press(w._playerObj, dev, id) end
                if TW.holdable(id) then
                    el.onHoldActivate = function(w) TW.secondary(w._playerObj, dev, id, nil) end
                    el.onContextMenu = function(w) TW.secondary(w._playerObj, dev, id, nil) end
                end
            end
            elements[#elements + 1] = el
        end
        if elements[1] and win._gpFocusedRadioCtl == nil then win._gpFocusedRadioCtl = elements[1].id end
        return elements
    end

    -- ---- Power -----------------------------------------------------------
    addZone(win._radioPwrZone, "radio:power",
        function() local dd = curDD(); if dd then _powerToggle(dd) end end)

    -- ---- Seek (channel) --------------------------------------------------
    -- A tap → one step (parity with mouse single-click). A hold ≥ A_HOLD_MS
    -- (350ms in FocusManager) → onHoldActivate fires one step AND arms the
    -- same _radioSeekHold state machine that mouse uses, tagged source=
    -- "gamepad" so the render loop polls JoypadButton.A:isDown for the
    -- disarm check. After arming, the existing 4-tier acceleration applies:
    -- 250ms grace → 200ms → 100ms → 50ms → 25ms intervals.
    if win._radioSeekBtnZones then
        for i, dir in ipairs({ -1, 1 }) do
            local z = win._radioSeekBtnZones[i]
            local id = (dir < 0) and "radio:seek-" or "radio:seek+"
            if z and (z.w or 0) > 0 then
                local stepDir = dir  -- capture by value
                elements[#elements + 1] = {
                    x = z.x, y = z.y, w = z.w, h = z.h, id = id,
                    onFocus    = function(w, el) w._gpFocusedRadioCtl = el.id end,
                    onActivate = function()
                        local dd = curDD()
                        if dd then _channelStep(dd, stepDir) end
                    end,
                    onHoldActivate = function(w)
                        local dd = curDD()
                        if dd == nil then return end
                        _channelStep(dd, stepDir)
                        local jd = getJoypadData and getJoypadData(0)
                        local jid = jd and jd.id or nil
                        local now = getTimestampMs()
                        w._radioSeekHold = {
                            dir = stepDir, source = "gamepad", jid = jid,
                            startMs = now, lastFireMs = now,
                        }
                    end,
                }
            end
        end
    end

    -- ---- Volume ----------------------------------------------------------
    -- Volume is single-fire on mouse too — already at parity.
    if win._radioVolBtnZones then
        addZone(win._radioVolBtnZones[1], "radio:vol-",
            function() local dd = curDD(); if dd then _volStep(dd, -1) end end)
        addZone(win._radioVolBtnZones[2], "radio:vol+",
            function() local dd = curDD(); if dd then _volStep(dd,  1) end end)
    end

    -- ---- Preset slots ----------------------------------------------------
    -- Assign-mode-aware: store flips the mode off, otherwise apply — the
    -- same branch the click router takes. _presetApply and
    -- _presetStore both handle empty-slot and out-of-bounds cases internally.
    if win._radioPresetZones then
        for i = 1, #win._radioPresetZones do
            local slot = i  -- capture by value, not loop alias
            addZone(win._radioPresetZones[i], "radio:preset:" .. i,
                function(w)
                    local dd = curDD()
                    if dd == nil then return end
                    if w._radioPresetAssignMode then
                        _presetStore(dd, slot)
                        w._radioPresetAssignMode = false
                    else
                        _presetApply(dd, slot)
                    end
                end)
        end
    end

    -- ---- Preset-add ("+") toggle ----------------------------------------
    -- Element id stays "radio:presetAdd" across the toggle, so the seed
    -- gate leaves focus alone — A again cancels assign mode without the
    -- player having to D-pad away. Single-button enter-and-cancel mirrors
    -- the mouse cursor staying put.
    addZone(win._radioPresetAddZone, "radio:presetAdd",
        function(w) _presetToggleAssign(w) end)

    -- ---- CD transport (Premium-only) ------------------------------------
    -- The rects cdPlayerModule stamped; only the Premium chassis draws it, and
    -- nothing else sets or clears _radioCDZones.
    if win._radioCDZones then
        for i = 1, #win._radioCDZones do
            local btn = i
            addZone(win._radioCDZones[i], "radio:cd:" .. i,
                function() local dd = curDD(); if dd then _cdTransport(dd, btn) end end)
        end
    end

    -- Seed gate — only writes on nil so D-pad onFocus updates are never
    -- stomped between frames.
    if elements[1] and win._gpFocusedRadioCtl == nil then
        win._gpFocusedRadioCtl = elements[1].id
    end
    return elements
end
