-- ZeD-UI/42/media/lua/client/ZeD/Settings.lua
-- ============================================================================
-- MOD OPTIONS INTEGRATION
-- Registration happens at FILE LOAD TIME so options appear in the MODS tab
-- of the Options screen from the main menu (before any game starts).
-- Theme application happens at OnGameStart when the game world exists.
--
-- API notes (from reading ModOptions.lua source + in-game testing):
--   PZAPI.ModOptions:create(id, displayName) returns an options object
--   opts:addComboBox(id, name, tooltip) returns a combo box option
--   option:addItem(displayName, isSelected) — colon call, two args
--   option:getValue() returns integer index (1-based)
-- ============================================================================

require "PZAPI/ModOptions"
require "ZeD/Tokens"

ZeD = ZeD or {}

-- ---------------------------------------------------------------------------
-- INDEX <-> KEY MAPPING
-- ---------------------------------------------------------------------------
local baseKeys   = {"dark", "light", "hicon"}
local baseLabels = {"Dark", "Light", "High contrast"}

local accentKeys   = {"red", "orange", "yellow", "green", "blue", "teal", "purple", "pink", "mono"}
local accentLabels = {"Red", "Orange", "Yellow", "Green", "Blue", "PZ Teal", "Purple", "Pink", "None"}

local sizeKeys   = {"small", "large"}
local sizeLabels = {"Small", "Large"}

-- UI scale (Oct 13 2026, director): Auto fits the screen (1x at 1080p, 2x at 4K,
-- nudged by the engine font-size option); the fixed steps override it.
local scaleKeys   = {"auto", 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0}
-- (no "%" in labels: ModOptions runs every label through getText, which chokes on it)
local scaleLabels = {"Auto (fits the screen)", "0.5x", "0.75x", "1x", "1.25x", "1.5x", "1.75x", "2x"}

-- Gamepad glyph display — controls which button-prompt glyph set is rendered.
-- "Auto" follows InputModeDetector.getControllerType(); explicit choices
-- force a specific glyph family regardless of the connected controller; "Off"
-- suppresses button prompts entirely. Phase 1 stores the setting but UI
-- doesn't honor it yet — GlyphManager (Phase 4) consumes this.
local glyphKeys   = {"auto", "xbox", "ps", "nintendo", "kbm", "off"}
local glyphLabels = {"Auto", "Xbox", "PlayStation", "Nintendo", "Keyboard/Mouse", "Off"}

-- Input-mode lock — overrides InputModeDetector's auto detection.
-- "Auto" lets the detector decide from live input; "KBM" and "Gamepad" lock
-- the mode regardless of what's happening with sticks/keys.
local inputLockKeys   = {"auto", "kbm", "gamepad"}
local inputLockLabels = {"Auto", "Keyboard/Mouse", "Gamepad"}

local function keyToIndex(keys, key)
    for i, k in ipairs(keys) do
        if k == key then return i end
    end
    return 1
end

-- Expose for footer theme controls
ZeD.Settings = ZeD.Settings or {}
ZeD.Settings.baseKeys      = baseKeys
ZeD.Settings.accentKeys    = accentKeys
ZeD.Settings.sizeKeys      = sizeKeys
ZeD.Settings.glyphKeys     = glyphKeys
ZeD.Settings.inputLockKeys = inputLockKeys

-- Forward-declare combo box locals so syncToModOptions() can capture them
-- (Lua locals are only visible after their declaration line — Q16)
local baseTheme, accentColor, textSize
-- S91 gamepad options: glyphDisplay chooses button-prompt artwork;
-- inputModeLock overrides the InputModeDetector auto-detection.
local glyphDisplay, inputModeLock

-- Sync current theme state back to ModOptions combo boxes (called after footer button changes)
function ZeD.Settings.syncToModOptions()
    if not baseTheme then return end
    baseTheme:setValue(keyToIndex(baseKeys, ZeD.currentBase))
    accentColor:setValue(keyToIndex(accentKeys, ZeD.currentAccent))
    textSize:setValue(keyToIndex(sizeKeys, ZeD.currentSize))
    -- Also persist to player modData (belt-and-suspenders — ModOptions save can be unreliable)
    local player = getSpecificPlayer(0)
    if player then
        local md = player:getModData()
        md.ZeD_Theme = md.ZeD_Theme or {}
        md.ZeD_Theme.base   = ZeD.currentBase
        md.ZeD_Theme.accent = ZeD.currentAccent
        md.ZeD_Theme.size   = ZeD.currentSize
        -- Preserve per-window accents already in modData
        local charWin = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
        local worldWin = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
        if charWin and charWin._accentKey then md.ZeD_Theme.charAccent = charWin._accentKey end
        if worldWin and worldWin._accentKey then md.ZeD_Theme.worldAccent = worldWin._accentKey end
    end
end

-- ---------------------------------------------------------------------------
-- REGISTER AT FILE LOAD TIME (so MODS tab shows our options)
-- ---------------------------------------------------------------------------
local opts = PZAPI.ModOptions:create("ZeD_UI", "ZeD UI")

-- ----- BASE THEME -----
baseTheme = opts:addComboBox("baseTheme", "Base theme",
    "Controls surface colors, text contrast, and border weight.")
for i, label in ipairs(baseLabels) do
    baseTheme:addItem(label, baseKeys[i] == "dark")  -- default: dark
end

-- ----- ACCENT COLOR -----
accentColor = opts:addComboBox("accentColor", "Accent color",
    "Controls selection, hover, and active element colors.")
for i, label in ipairs(accentLabels) do
    accentColor:addItem(label, accentKeys[i] == "orange")  -- default: orange
end

-- ----- TEXT SIZE -----
textSize = opts:addComboBox("textSize", "Text size",
    "Controls font sizes and component dimensions.")
for i, label in ipairs(sizeLabels) do
    textSize:addItem(label, sizeKeys[i] == "small")  -- default: small
end

-- ----- UI SCALE -----
local uiScale = opts:addComboBox("uiScale", "UI scale",
    "Auto sizes the whole ZeD UI to your screen: 1x at 1080p, 2x at 4K. Pick a fixed size to override it (1x is the 1080p size).")
for i, label in ipairs(scaleLabels) do
    uiScale:addItem(label, i == 1)  -- default: Auto
end
local function applyScale()
    local v = scaleKeys[uiScale:getValue() or 1]
    if ZeD.Scale then
        ZeD.Scale.userScale = (type(v) == "number") and v or nil
        ZeD.Scale.refresh()   -- the Scale tick hook re-applies the theme and reopens the windows
    end
end
uiScale.onChange = applyScale
ZeD.Settings.applyScale = applyScale
ZeD.Settings.uiScaleOption = uiScale   -- QA bridge drives it like the options screen

-- ----- MOODLES (Oct 14 2026, director: "options would be best. each of the
-- three placements are good for different users") -----
-- Where vanilla's moodles sit; they are drawn as vanilla draws them in all
-- three (ZeD_Moodles.lua reads this option every frame, so a change applies
-- at once). A display preference: lives in the mod options, not in the save.
local moodleLabels = {"Right, under the watch", "Left edge", "Bottom, above the belt"}
local moodlePlace = opts:addComboBox("moodlePlace", "Moodles",
    "Where the moodles sit. Right: under the watch, where vanilla puts them. Left: down the left edge, below the windows. Bottom: a row above the belt (above the dashboard in a car).")
for i, label in ipairs(moodleLabels) do
    moodlePlace:addItem(label, i == 1)  -- default: right, under the watch
end
ZeD.Settings.moodlePlaceOption = moodlePlace

-- ----- CHARACTER WINDOW ACCENT -----
local charAccent = opts:addComboBox("charAccent", "Character window accent",
    "Per-window accent override for the Character window. Cycled via footer button.")
for i, label in ipairs(accentLabels) do
    charAccent:addItem(label, accentKeys[i] == "orange")  -- default: orange
end

-- ----- WORLD WINDOW ACCENT -----
local worldAccent = opts:addComboBox("worldAccent", "World window accent",
    "Per-window accent override for the World window. Cycled via footer button.")
for i, label in ipairs(accentLabels) do
    worldAccent:addItem(label, accentKeys[i] == "orange")  -- default: orange
end

-- ----- GLYPH DISPLAY (S91 Gamepad Phase 1) -----
-- Sets which button-prompt artwork is used in footer prompt strips.
-- Auto follows the connected controller; explicit choices override.
-- Phase 1 stores the preference; GlyphManager (Phase 4) renders from it.
glyphDisplay = opts:addComboBox("glyphDisplay", "Gamepad glyph display",
    "Which button icons to show in gamepad prompts. Auto follows the connected controller.")
for i, label in ipairs(glyphLabels) do
    glyphDisplay:addItem(label, glyphKeys[i] == "auto")  -- default: auto
end

-- ----- INPUT MODE LOCK (S91 Gamepad Phase 1) -----
-- Overrides InputModeDetector's auto-detection. Useful when the detector
-- is misbehaving on a weird controller or when the player wants to pin
-- the UI to one mode. Wired directly to ZeD.Input.Detector.setLockedMode.
inputModeLock = opts:addComboBox("inputModeLock", "Input mode lock",
    "Force a specific input mode. Auto lets the mod detect your active device.")
for i, label in ipairs(inputLockLabels) do
    inputModeLock:addItem(label, inputLockKeys[i] == "auto")  -- default: auto
end

-- ----- APPLY FUNCTION -----
-- Reads combo box indices and converts to our key strings
local function applyFromOptions()
    local baseIdx   = baseTheme:getValue()   or 1
    local accentIdx = accentColor:getValue()  or 2
    local sizeIdx   = textSize:getValue()     or 1

    local base   = baseKeys[baseIdx]   or "dark"
    local accent = accentKeys[accentIdx] or "orange"
    local size   = sizeKeys[sizeIdx]   or "small"

    ZeD.applyTheme(base, accent, size)
end

-- ----- ON CHANGE -----
-- Fires when the player changes a value in the MODS tab
baseTheme.onChange   = applyFromOptions
accentColor.onChange = applyFromOptions
textSize.onChange    = applyFromOptions

-- Per-window accent onChange: apply to live window if it exists
charAccent.onChange = function()
    local key = accentKeys[charAccent:getValue() or 2] or "orange"
    local win = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
    if win then win._accentKey = key end
end
worldAccent.onChange = function()
    local key = accentKeys[worldAccent:getValue() or 2] or "orange"
    local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    if win then win._accentKey = key end
end

-- Glyph display: store the selection to modData. GlyphManager (Phase 4)
-- will read it; Phase 1 just persists the user's preference.
glyphDisplay.onChange = function()
    local key = glyphKeys[glyphDisplay:getValue() or 1] or "auto"
    local player = getSpecificPlayer(0)
    if player then
        local md = player:getModData()
        md.ZeD_Gamepad = md.ZeD_Gamepad or {}
        md.ZeD_Gamepad.glyphDisplay = key
    end
end

-- Input mode lock: wire directly to the detector. "auto" clears the lock;
-- "kbm" / "gamepad" pin the mode. The detector's setLockedMode handles the
-- nil-vs-string semantics internally.
inputModeLock.onChange = function()
    local key = inputLockKeys[inputModeLock:getValue() or 1] or "auto"
    local player = getSpecificPlayer(0)
    if player then
        local md = player:getModData()
        md.ZeD_Gamepad = md.ZeD_Gamepad or {}
        md.ZeD_Gamepad.inputModeLock = key
    end
    if ZeD.Input and ZeD.Input.Detector and ZeD.Input.Detector.setLockedMode then
        if key == "auto" then
            ZeD.Input.Detector.setLockedMode(nil)
        else
            ZeD.Input.Detector.setLockedMode(key)
        end
    end
end

-- Sync a single window's accent to ModOptions + modData (called from footer button)
function ZeD.Settings.syncWindowAccent(win)
    if not win or not win._accentKey then return end
    local key = win._accentKey
    -- Determine which window this is and sync the correct ModOption
    local charWin = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
    local worldWin = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    if win == charWin and charAccent then
        charAccent:setValue(keyToIndex(accentKeys, key))
    elseif win == worldWin and worldAccent then
        worldAccent:setValue(keyToIndex(accentKeys, key))
    end
    -- Also persist to player modData
    local player = getSpecificPlayer(0)
    if player then
        local md = player:getModData()
        md.ZeD_Theme = md.ZeD_Theme or {}
        if win == charWin then md.ZeD_Theme.charAccent = key end
        if win == worldWin then md.ZeD_Theme.worldAccent = key end
    end
end

-- ---------------------------------------------------------------------------
-- APPLY SAVED SETTINGS WHEN GAME STARTS
-- ModOptions:load() runs before OnGameStart, so combo boxes already have
-- the player's saved values by the time this fires.
-- ---------------------------------------------------------------------------
Events.OnGameStart.Add(function()
    applyScale()   -- display preference: lives in the mod options, not in the save
    -- Try modData first (persists with save file), fall back to ModOptions
    local player = getSpecificPlayer(0)
    if player then
        local md = player:getModData()
        if md.ZeD_Theme then
            local base   = md.ZeD_Theme.base   or "dark"
            local accent = md.ZeD_Theme.accent  or "orange"
            local size   = md.ZeD_Theme.size    or "small"
            ZeD.applyTheme(base, accent, size)
            -- Sync global ModOptions to match
            if baseTheme then
                baseTheme:setValue(keyToIndex(baseKeys, base))
                accentColor:setValue(keyToIndex(accentKeys, accent))
                textSize:setValue(keyToIndex(sizeKeys, size))
            end
            -- Sync per-window accent ModOptions from modData
            if md.ZeD_Theme.charAccent and charAccent then
                charAccent:setValue(keyToIndex(accentKeys, md.ZeD_Theme.charAccent))
            end
            if md.ZeD_Theme.worldAccent and worldAccent then
                worldAccent:setValue(keyToIndex(accentKeys, md.ZeD_Theme.worldAccent))
            end
            -- Store per-window accents for window restore (read by restoreCharState/restoreWorldState)
            ZeD._pendingCharAccent  = md.ZeD_Theme.charAccent
            ZeD._pendingWorldAccent = md.ZeD_Theme.worldAccent
            -- Restore S91 gamepad settings if present (falls through to applyFromOptions
            -- defaults otherwise). Glyph display is stored only; input mode lock
            -- feeds the detector immediately if the detector is loaded.
            if md.ZeD_Gamepad then
                if md.ZeD_Gamepad.glyphDisplay and glyphDisplay then
                    glyphDisplay:setValue(keyToIndex(glyphKeys, md.ZeD_Gamepad.glyphDisplay))
                end
                if md.ZeD_Gamepad.inputModeLock and inputModeLock then
                    inputModeLock:setValue(keyToIndex(inputLockKeys, md.ZeD_Gamepad.inputModeLock))
                    if ZeD.Input and ZeD.Input.Detector and ZeD.Input.Detector.setLockedMode then
                        local key = md.ZeD_Gamepad.inputModeLock
                        if key == "auto" then
                            ZeD.Input.Detector.setLockedMode(nil)
                        else
                            ZeD.Input.Detector.setLockedMode(key)
                        end
                    end
                end
            end
            return
        end
    end
    applyFromOptions()
    -- Fall back: read per-window accents from ModOptions
    if charAccent then
        ZeD._pendingCharAccent = accentKeys[charAccent:getValue() or 2]
    end
    if worldAccent then
        ZeD._pendingWorldAccent = accentKeys[worldAccent:getValue() or 2]
    end
    -- Fall back: apply input mode lock from ModOptions if no modData exists
    if inputModeLock and ZeD.Input and ZeD.Input.Detector and ZeD.Input.Detector.setLockedMode then
        local key = inputLockKeys[inputModeLock:getValue() or 1] or "auto"
        if key ~= "auto" then
            ZeD.Input.Detector.setLockedMode(key)
        end
    end
end)

-- ---------------------------------------------------------------------------
-- F-KEY SHORTCUTS FOR QUICK CYCLING (dev convenience)
-- These work alongside ModOptions. The MODS tab won't reflect F-key changes
-- until reopened, but the theme updates immediately in-game.
-- ---------------------------------------------------------------------------

local function cycleNext(list, current)
    for i, v in ipairs(list) do
        if v == current then
            return list[(i % #list) + 1]
        end
    end
    return list[1]
end
ZeD.Settings.cycleNext = cycleNext

-- F-key handlers removed — theme/accent/size cycling is footer-button-only
