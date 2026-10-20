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
-- A combo is saved in ModOptions.ini as its item's position, so a list only ever
-- grows at the END: an item inserted or moved earlier would change what every
-- player's saved choice means.
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

-- The two window-accent combos carry one more item after the colours: "Same as
-- Accent color", which means no override of their own. It is last, so saved
-- indices keep their meaning. Its key is nil.
local accentFollowIdx = #accentKeys + 1
local function windowAccentIndex(key)
    for i, k in ipairs(accentKeys) do
        if k == key then return i end
    end
    return accentFollowIdx
end

-- ModOptions.ini written now: vanilla re-reads it every time it builds the
-- options screen, so a change made in game that is not saved is lost at the
-- main menu and for the next character.
local function saveModOptions()
    if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.save then
        pcall(PZAPI.ModOptions.save, PZAPI.ModOptions)
    end
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

-- The character's own copy of the theme in its modData. It follows the mod
-- options and is never read back over them: the options are the one source for
-- the base theme, the accent and the text size.
local function copyThemeToCharacter()
    local player = getSpecificPlayer(0)
    if not player then return end
    local md = player:getModData()
    md.ZeD_Theme = md.ZeD_Theme or {}
    md.ZeD_Theme.base   = ZeD.currentBase
    md.ZeD_Theme.accent = ZeD.currentAccent
    md.ZeD_Theme.size   = ZeD.currentSize
end

-- Sync current theme state back to ModOptions combo boxes (called after footer button changes)
function ZeD.Settings.syncToModOptions()
    if not baseTheme then return end
    baseTheme:setValue(keyToIndex(baseKeys, ZeD.currentBase))
    accentColor:setValue(keyToIndex(accentKeys, ZeD.currentAccent))
    textSize:setValue(keyToIndex(sizeKeys, ZeD.currentSize))
    copyThemeToCharacter()
    saveModOptions()
end

-- ---------------------------------------------------------------------------
-- REGISTER AT FILE LOAD TIME (so MODS tab shows our options)
-- ---------------------------------------------------------------------------
local opts = PZAPI.ModOptions:create("ZeD_UI", "ZeD-GUI")

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
-- idx: the item just picked (vanilla hands the new index to onChange; the stored
-- value is only updated at Apply). Without it, the stored value is used.
local function applyScale(idx)
    local v = scaleKeys[tonumber(idx) or uiScale:getValue() or 1]
    if ZeD.Scale then
        ZeD.Scale.userScale = (type(v) == "number") and v or nil
        ZeD.Scale.refresh()   -- the Scale tick hook re-applies the theme and reopens the windows
    end
end
-- (onChange and onChangeApply both get the option, then the new index)
uiScale.onChange = function(_, sel) applyScale(sel) end
uiScale.onChangeApply = function(_, sel) applyScale(sel) end
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

-- ----- EQUIPPED VIEW (Oct 19 2026, director: "avatar view ... and list view
-- are the two we want") -----
-- The Equip tab's two views; the toggle in its Equipped heading sets this
-- too, so the choice is remembered across saves (EquipDoll.lua reads it).
local equipView = opts:addComboBox("equipView", "Equipped items",
    "How the Equip tab shows what you wear: a list, or your character with each slot beside the place it is worn.")
equipView:addItem("List", true)  -- default: the list
equipView:addItem("Doll", false)
ZeD.Settings.equipViewOption = equipView

-- ----- THE OTHER VIEW CHOICES (Oct 19 2026, director: "people can have all lists
-- or all grids options for the most used menus") -----
-- The inventory's view for every container that hasn't one of its own (each
-- column's List | Grid toggle still sets one container; InventoryRenderer).
local invView = opts:addComboBox("inventoryView", "Inventory",
    "How containers show their items unless you set one with its List | Grid toggle: a list with columns, or a grid of icons.")
invView:addItem("List", true)   -- default: the list
invView:addItem("Grid", false)
ZeD.Settings.inventoryViewOption = invView
-- The right-click menu: the strip of icons, or a list of words (ZeD_ContextList).
local ctxStyle = opts:addComboBox("contextStyle", "Context menu",
    "The right-click menu: a strip of icons with the target and what the action needs, or a list, one action to a row, as the game's own.")
ctxStyle:addItem("Icon strip", true)   -- default: the strip
ctxStyle:addItem("List", false)
ZeD.Settings.contextStyleOption = ctxStyle
-- The watch you wear: a small one on the belt, outside the hand of its wrist
-- (WatchMini.lua; its face pops the full watch up), or the full watch in the
-- top right corner as before. No watch worn: the tape deck keys stay in the corner.
local watchPlace = opts:addComboBox("watchPlace", "Watch",
    "Where the watch you wear shows: small on the belt beside the hand of its wrist (press its face for the full watch, which you can drag anywhere), or the full watch in the top right corner.")
watchPlace:addItem("On the belt", true)   -- default (director, Oct 19 2026)
watchPlace:addItem("Corner", false)
ZeD.Settings.watchPlaceOption = watchPlace

-- ----- ACTION BAR (Oct 19 2026, mockup ZeDUI/mockups/zed_action_bar_v2.html; director: "ship it") -----
-- The bar over the character's head while an action runs (ZeD_ActionBar.lua reads this
-- every frame, so a change applies at once). Verbose is the default.
local actionBar = opts:addComboBox("actionBar", "Action bar",
    "The bar over your character's head while it works. Verbose: what it is doing, with what, how far, and what comes next. Simple: ten segments, no words.")
actionBar:addItem("Verbose", true)   -- default
actionBar:addItem("Simple", false)
ZeD.Settings.actionBarOption = actionBar

-- ----- CHARACTER WINDOW ACCENT -----
-- Default: the same as the Accent color above (the last item, so saved indices keep their meaning).
local charAccent = opts:addComboBox("charAccent", "Character window accent",
    "An accent of its own for the Character window, or the same as Accent color. Cycled via footer button.")
for i, label in ipairs(accentLabels) do
    charAccent:addItem(label, false)
end
charAccent:addItem("Same as Accent color", true)

-- ----- WORLD WINDOW ACCENT -----
local worldAccent = opts:addComboBox("worldAccent", "World window accent",
    "An accent of its own for the World window, or the same as Accent color. Cycled via footer button.")
for i, label in ipairs(accentLabels) do
    worldAccent:addItem(label, false)
end
worldAccent:addItem("Same as Accent color", true)

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

-- ----- SAFE MODE (Oct 19 2026, director: if ZeD ever fails to open, a bad day
-- is a setting flip rather than a hotfix) -----
-- On hands the game back to its own interface (SafeMode.lua reads this at most
-- every half second, so a change applies at once); ZeD also steps aside by itself
-- for a session when it hits an error that keeps repeating.
local safeMode = opts:addComboBox("safeMode", "Safe mode",
    "On: ZeD UI steps aside and the game's own interface is used (its inventory, hotbar, clock, moodles and dashboard) until you turn it Off. Use it if ZeD UI ever fails to open. ZeD UI also steps aside by itself, for the rest of a session, if it hits an error that keeps repeating.")
safeMode:addItem("Off", true)   -- default
safeMode:addItem("On: the game's own interface", false)
ZeD.Settings.safeModeOption = safeMode

-- ----- APPLY FUNCTION -----
-- The index the player has picked in a combo. While the options screen is open
-- vanilla keeps the pick on the control and stores it in the option only at
-- Apply, so the option's own value is stale until then; the control is read
-- first, the option after.
local function pickedIdx(opt)
    local el = opt.element
    return (el and el.selected) or opt:getValue()
end

-- Reads the three theme combos and converts the indices to our key strings.
-- `changed` / `sel`: the combo that just changed and the new index vanilla hands
-- to onChange; the other two are read as picked. With no arguments (game start,
-- main menu) the stored values are used.
local function applyFromOptions(changed, sel)
    local baseIdx, accentIdx, sizeIdx
    if changed then
        baseIdx   = (changed == baseTheme   and tonumber(sel)) or pickedIdx(baseTheme)
        accentIdx = (changed == accentColor and tonumber(sel)) or pickedIdx(accentColor)
        sizeIdx   = (changed == textSize    and tonumber(sel)) or pickedIdx(textSize)
    else
        baseIdx, accentIdx, sizeIdx = baseTheme:getValue(), accentColor:getValue(), textSize:getValue()
    end

    local base   = baseKeys[baseIdx or 1]     or "dark"
    local accent = accentKeys[accentIdx or 2] or "orange"
    local size   = sizeKeys[sizeIdx or 1]     or "small"

    ZeD.applyTheme(base, accent, size)
end
-- ----- ON CHANGE -----
-- Fires when the player changes a value in the MODS tab (the new index comes
-- with it, so the change shows at once). onChangeApply fires at Apply, so a
-- value is also committed where there was no live preview.
local function onThemeChange(opt, sel) applyFromOptions(opt, sel) end
local function onThemeApply(opt, sel)
    applyFromOptions(opt, sel)
    copyThemeToCharacter()
end
baseTheme.onChange   = onThemeChange
accentColor.onChange = onThemeChange
textSize.onChange    = onThemeChange
baseTheme.onChangeApply   = onThemeApply
accentColor.onChangeApply = onThemeApply
textSize.onChangeApply    = onThemeApply

-- Per-window accent: apply to the live window if it exists, and to the one the
-- next open restores. The saved window state carries its own accent which the
-- next open prefers, so the pick is written there too (Options wins over it).
local function setWindowAccent(getWin, pendingField, stateKey, idx)
    local key = accentKeys[tonumber(idx) or accentFollowIdx]   -- nil: follows Accent color
    local win = getWin and getWin()
    if win then win._accentKey = key end
    ZeD[pendingField] = key
    local player = getSpecificPlayer(0)
    if player then
        local md = player:getModData()
        local st = md.ZeD_WinState and md.ZeD_WinState[stateKey]
        if st then st.accentKey = key end
    end
end
local function onCharAccent(_, sel)
    setWindowAccent(ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow, "_pendingCharAccent", "char", sel)
end
local function onWorldAccent(_, sel)
    setWindowAccent(ZeD_WorldWindow and ZeD_WorldWindow.getWindow, "_pendingWorldAccent", "world", sel)
end
charAccent.onChange  = onCharAccent
charAccent.onChangeApply  = onCharAccent
worldAccent.onChange = onWorldAccent
worldAccent.onChangeApply = onWorldAccent

-- Glyph display: store the selection to modData. GlyphManager (Phase 4)
-- will read it; Phase 1 just persists the user's preference.
glyphDisplay.onChange = function(_, sel)
    local key = glyphKeys[tonumber(sel) or glyphDisplay:getValue() or 1] or "auto"
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
inputModeLock.onChange = function(_, sel)
    local key = inputLockKeys[tonumber(sel) or inputModeLock:getValue() or 1] or "auto"
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

-- Sync a single window's accent to ModOptions + modData (called from footer button).
-- A window with no accent key of its own follows the Accent color option.
function ZeD.Settings.syncWindowAccent(win)
    if not win then return end
    local key = win._accentKey
    -- Determine which window this is and sync the correct ModOption
    local charWin = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
    local worldWin = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    if win == charWin and charAccent then
        charAccent:setValue(windowAccentIndex(key))
        ZeD._pendingCharAccent = key
    elseif win == worldWin and worldAccent then
        worldAccent:setValue(windowAccentIndex(key))
        ZeD._pendingWorldAccent = key
    else
        return
    end
    -- Also persist to player modData (a copy that follows the options)
    local player = getSpecificPlayer(0)
    if player then
        local md = player:getModData()
        md.ZeD_Theme = md.ZeD_Theme or {}
        if win == charWin then md.ZeD_Theme.charAccent = key end
        if win == worldWin then md.ZeD_Theme.worldAccent = key end
    end
    saveModOptions()
end

-- The input mode lock from its stored value: "auto" leaves the detector alone
-- when it has no lock to clear (game start), `clear` also lifts a lock (discard).
local function applyInputLock(clear)
    if not (inputModeLock and ZeD.Input and ZeD.Input.Detector and ZeD.Input.Detector.setLockedMode) then return end
    local key = inputLockKeys[inputModeLock:getValue() or 1] or "auto"
    if key ~= "auto" then
        ZeD.Input.Detector.setLockedMode(key)
    elseif clear then
        ZeD.Input.Detector.setLockedMode(nil)
    end
end

-- The per-window accents the next open of each window starts from (nil: follow Accent color).
-- Each window also remembers its own accent in the character's saved window state, and
-- the next open prefers that over the pending value: with a character loaded, the saved
-- one is brought to the option's pick too, so a pick made at the main menu is not
-- overridden by the accent the window was last closed with.
local function applyWindowAccentsFromOptions()
    if charAccent then
        ZeD._pendingCharAccent = accentKeys[charAccent:getValue() or accentFollowIdx]
    end
    if worldAccent then
        ZeD._pendingWorldAccent = accentKeys[worldAccent:getValue() or accentFollowIdx]
    end
    local player = getSpecificPlayer(0)
    local ws = player and player:getModData().ZeD_WinState
    if ws then
        if ws.char then ws.char.accentKey = ZeD._pendingCharAccent end
        if ws.world then ws.world.accentKey = ZeD._pendingWorldAccent end
    end
end

-- Everything from the stored option values. The options window's discard runs this
-- (see hookOptionsDiscard below): the controls are back at the stored picks, but the
-- live preview of the discarded ones (theme, scale) would otherwise stay on screen.
function ZeD.Settings.reapplyFromOptions()
    applyScale()
    applyFromOptions()
    applyWindowAccentsFromOptions()
    local charWin = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
    local worldWin = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    if charWin then charWin._accentKey = ZeD._pendingCharAccent end
    if worldWin then worldWin._accentKey = ZeD._pendingWorldAccent end
    applyInputLock(true)
end

-- The options window's DISCARD (and the footer's discard-and-stay, which goes through
-- it) puts the controls back but does not call the handlers above, so it is wrapped
-- once to re-apply the stored values afterwards. The window's file loads in its own
-- order, so the wrap is made when the menu or a game starts, not at file load.
local discardHooked = false
local function hookOptionsDiscard()
    if discardHooked or not (ZeD_MMOptions and ZeD_MMOptions.discard) then return end
    discardHooked = true
    local plainDiscard = ZeD_MMOptions.discard
    ZeD_MMOptions.discard = function(self, ...)
        local r = plainDiscard(self, ...)
        pcall(ZeD.Settings.reapplyFromOptions)
        return r
    end
end

-- ---------------------------------------------------------------------------
-- APPLY SAVED SETTINGS WHEN GAME STARTS
-- ModOptions:load() runs before OnGameStart, so combo boxes already have
-- the player's saved values by the time this fires. The mod options are the
-- one source for the theme, the accents and the gamepad choices: what the
-- player picks there applies to every character, and a copy kept in a
-- character's own data never overrides it.
-- ---------------------------------------------------------------------------
Events.OnGameStart.Add(function()
    hookOptionsDiscard()
    applyScale()   -- display preference: lives in the mod options, not in the save
    applyFromOptions()
    applyWindowAccentsFromOptions()   -- read by restoreCharState / restoreWorldState
    applyInputLock(false)
end)

-- The main menu (Oct 14 2026) draws ZeD windows before any save loads: apply
-- the mod options there too. Vanilla's own OnMainMenuEnter handler builds the
-- options screen first, which loads the saved mod options.
Events.OnMainMenuEnter.Add(function()
    hookOptionsDiscard()
    applyScale()
    applyFromOptions()
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
