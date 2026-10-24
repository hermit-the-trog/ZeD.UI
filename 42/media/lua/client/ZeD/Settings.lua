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
require "ZeD/Tr"

ZeD = ZeD or {}

-- ---------------------------------------------------------------------------
-- INDEX <-> KEY MAPPING
-- A combo is saved in ModOptions.ini as its item's position, so a list only ever
-- grows at the END: an item inserted or moved earlier would change what every
-- player's saved choice means.
-- ---------------------------------------------------------------------------
-- (every label below is a translation key: ZeD.tr turns it into the player's language where the
-- item is added; the order of the items is what a saved choice means, so it never changes)
local baseKeys   = {"dark", "light", "hicon"}
local baseLabels = {"UI_ZeD_Settings_Dark", "UI_ZeD_Settings_Light", "UI_ZeD_Settings_HighContrast"}

local accentKeys   = {"red", "orange", "yellow", "green", "blue", "teal", "purple", "pink", "mono"}
local accentLabels = {"ContextMenu_Red", "ContextMenu_Orange", "ContextMenu_Yellow", "ContextMenu_Green", "ContextMenu_Blue",
                      "UI_ZeD_Accent_Teal", "ContextMenu_Purple", "ContextMenu_Pink", "IGUI_None"}

local sizeKeys   = {"small", "large"}
local sizeLabels = {"UI_optionscreen_Small", "UI_optionscreen_Large"}

-- UI scale (Oct 13 2026, director): Auto fits the screen (1x at 1080p, 2x at 4K,
-- nudged by the engine font-size option); the fixed steps override it.
local scaleKeys   = {"auto", 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0}
-- (no "%" in labels: ModOptions runs every label through getText, which chokes on it; the steps are
-- numbers, not words, so only Auto is a key)
local scaleLabels = {"UI_ZeD_Settings_ScaleAuto", "0.5x", "0.75x", "1x", "1.25x", "1.5x", "1.75x", "2x"}

-- Gamepad glyph display — which set of button pictures ZeD draws
-- (ZeD_PadGlyphs.lua; director, Oct 24 2026). "Auto" follows the game's
-- controller button style (the game switches it to PlayStation by itself on
-- a PlayStation pad); an explicit set forces that one; "Keyboard/mouse" and
-- "Off" draw the buttons as lettered boxes, as before the pictures.
-- (Steam Deck added Oct 24 2026, after PlayStation: nothing read this setting
-- before, so a stored index that moved changes nothing a player saw.)
local glyphKeys   = {"auto", "xbox", "ps", "deck", "nintendo", "kbm", "off"}
local glyphLabels = {"UI_ZeD_Settings_Auto", "UI_optionscreen_ControllerButtonStyle1", "UI_optionscreen_ControllerButtonStyle2", "UI_optionscreen_ControllerButtonStyle3", "Nintendo", "UI_ZeD_Settings_KeyboardMouse", "UI_Off"}   -- (Nintendo: a name, as is)

-- Input-mode lock — overrides InputModeDetector's auto detection.
-- "Auto" lets the detector decide from live input; "KBM" and "Gamepad" lock
-- the mode regardless of what's happening with sticks/keys.
local inputLockKeys   = {"auto", "kbm", "gamepad"}
local inputLockLabels = {"UI_ZeD_Settings_Auto", "UI_ZeD_Settings_KeyboardMouse", "UI_ZeD_Settings_Gamepad"}

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
-- (the labels too, for the controller's ZeD wheel on Select: ZeD_DpadWheels.lua)
ZeD.Settings.baseLabels    = baseLabels
ZeD.Settings.accentLabels  = accentLabels
ZeD.Settings.sizeLabels    = sizeLabels
ZeD.Settings.scaleKeys     = scaleKeys
ZeD.Settings.scaleLabels   = scaleLabels
ZeD.Settings.save          = function() saveModOptions() end

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
baseTheme = opts:addComboBox("baseTheme", ZeD.tr("UI_ZeD_Settings_BaseTheme"),
    ZeD.tr("UI_ZeD_Settings_BaseThemeTip"))
for i, label in ipairs(baseLabels) do
    baseTheme:addItem(ZeD.tr(label), baseKeys[i] == "dark")  -- default: dark
end

-- ----- ACCENT COLOR -----
accentColor = opts:addComboBox("accentColor", ZeD.tr("UI_ZeD_Settings_AccentColor"),
    ZeD.tr("UI_ZeD_Settings_AccentColorTip"))
for i, label in ipairs(accentLabels) do
    accentColor:addItem(ZeD.tr(label), accentKeys[i] == "orange")  -- default: orange
end

-- ----- TEXT SIZE -----
textSize = opts:addComboBox("textSize", ZeD.tr("UI_ZeD_Settings_TextSize"),
    ZeD.tr("UI_ZeD_Settings_TextSizeTip"))
for i, label in ipairs(sizeLabels) do
    textSize:addItem(ZeD.tr(label), sizeKeys[i] == "small")  -- default: small
end

-- ----- UI SCALE -----
local uiScale = opts:addComboBox("uiScale", ZeD.tr("UI_ZeD_Settings_UiScale"),
    ZeD.tr("UI_ZeD_Settings_UiScaleTip"))
for i, label in ipairs(scaleLabels) do
    uiScale:addItem((i == 1) and ZeD.tr(label) or label, i == 1)  -- default: Auto (the other steps are numbers)
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
local moodleLabels = {"UI_ZeD_Settings_MoodlesRight", "UI_ZeD_Settings_MoodlesLeft", "UI_ZeD_Settings_MoodlesBottom"}
local moodlePlace = opts:addComboBox("moodlePlace", ZeD.tr("UI_ZeD_Settings_Moodles"),
    ZeD.tr("UI_ZeD_Settings_MoodlesTip"))
for i, label in ipairs(moodleLabels) do
    moodlePlace:addItem(ZeD.tr(label), i == 1)  -- default: right, under the watch
end
ZeD.Settings.moodlePlaceOption = moodlePlace
ZeD.Settings.moodleLabels = moodleLabels

-- ----- EQUIPPED VIEW (Oct 19 2026, director: "avatar view ... and list view
-- are the two we want") -----
-- The Equip tab's two views; the toggle in its Equipped heading sets this
-- too, so the choice is remembered across saves (EquipDoll.lua reads it).
local equipView = opts:addComboBox("equipView", ZeD.tr("UI_ZeD_Settings_EquipView"),
    ZeD.tr("UI_ZeD_Settings_EquipViewTip"))
equipView:addItem(ZeD.tr("UI_ZeD_Settings_ViewList"), true)  -- default: the list
equipView:addItem(ZeD.tr("UI_ZeD_Settings_ViewDoll"), false)
ZeD.Settings.equipViewOption = equipView

-- ----- THE OTHER VIEW CHOICES (Oct 19 2026, director: "people can have all lists
-- or all grids options for the most used menus") -----
-- The inventory's view for every container that hasn't one of its own (each
-- column's List | Grid toggle still sets one container; InventoryRenderer).
local invView = opts:addComboBox("inventoryView", ZeD.tr("UI_ZeD_Settings_Inventory"),
    ZeD.tr("UI_ZeD_Settings_InventoryTip"))
invView:addItem(ZeD.tr("UI_ZeD_Settings_ViewList"), true)   -- default: the list
invView:addItem(ZeD.tr("UI_ZeD_Settings_ViewGrid"), false)
ZeD.Settings.inventoryViewOption = invView
-- The right-click menu: the strip of icons, or a list of words (ZeD_ContextList).
local ctxStyle = opts:addComboBox("contextStyle", ZeD.tr("UI_ZeD_Settings_ContextMenu"),
    ZeD.tr("UI_ZeD_Settings_ContextMenuTip"))
ctxStyle:addItem(ZeD.tr("UI_ZeD_Settings_ContextStrip"), true)   -- default: the strip
ctxStyle:addItem(ZeD.tr("UI_ZeD_Settings_ViewList"), false)
ZeD.Settings.contextStyleOption = ctxStyle
-- The watch you wear: a small one on the belt, outside the hand of its wrist
-- (WatchMini.lua; its face pops the full watch up), or the full watch in the
-- top right corner as before. No watch worn: the tape deck keys stay in the corner.
local watchPlace = opts:addComboBox("watchPlace", ZeD.tr("UI_ZeD_Settings_Watch"),
    ZeD.tr("UI_ZeD_Settings_WatchTip"))
watchPlace:addItem(ZeD.tr("UI_ZeD_Settings_WatchBelt"), true)   -- default (director, Oct 19 2026)
watchPlace:addItem(ZeD.tr("UI_ZeD_Settings_WatchCorner"), false)
ZeD.Settings.watchPlaceOption = watchPlace

-- ----- ACTION BAR (Oct 19 2026, mockup ZeDUI/mockups/zed_action_bar_v2.html; director: "ship it") -----
-- The bar over the character's head while an action runs (ZeD_ActionBar.lua reads this
-- every frame, so a change applies at once). Verbose is the default.
local actionBar = opts:addComboBox("actionBar", ZeD.tr("UI_ZeD_Settings_ActionBar"),
    ZeD.tr("UI_ZeD_Settings_ActionBarTip"))
actionBar:addItem(ZeD.tr("UI_ZeD_Settings_ActionBarVerbose"), true)   -- default
actionBar:addItem(ZeD.tr("UI_ZeD_Settings_ActionBarSimple"), false)
ZeD.Settings.actionBarOption = actionBar

-- ----- CHARACTER WINDOW ACCENT -----
-- Default: the same as the Accent color above (the last item, so saved indices keep their meaning).
local charAccent = opts:addComboBox("charAccent", ZeD.tr("UI_ZeD_Settings_CharAccent"),
    ZeD.tr("UI_ZeD_Settings_CharAccentTip"))
for i, label in ipairs(accentLabels) do
    charAccent:addItem(ZeD.tr(label), false)
end
charAccent:addItem(ZeD.tr("UI_ZeD_Settings_SameAsAccent"), true)

-- ----- WORLD WINDOW ACCENT -----
local worldAccent = opts:addComboBox("worldAccent", ZeD.tr("UI_ZeD_Settings_WorldAccent"),
    ZeD.tr("UI_ZeD_Settings_WorldAccentTip"))
for i, label in ipairs(accentLabels) do
    worldAccent:addItem(ZeD.tr(label), false)
end
worldAccent:addItem(ZeD.tr("UI_ZeD_Settings_SameAsAccent"), true)

-- ----- GLYPH DISPLAY (S91 Gamepad Phase 1) -----
-- Sets which button-prompt artwork is used in footer prompt strips.
-- Auto follows the connected controller; explicit choices override.
-- Phase 1 stores the preference; GlyphManager (Phase 4) renders from it.
glyphDisplay = opts:addComboBox("glyphDisplay", ZeD.tr("UI_ZeD_Settings_Glyphs"),
    ZeD.tr("UI_ZeD_Settings_GlyphsTip"))
for i, label in ipairs(glyphLabels) do
    glyphDisplay:addItem(ZeD.tr(label), glyphKeys[i] == "auto")  -- default: auto
end
-- the picked set's key, live while the options screen is open (ZeD_PadGlyphs reads it every draw)
ZeD.Settings.glyphOption = glyphDisplay
ZeD.Settings.glyphKey = function()
    local el = glyphDisplay.element
    return glyphKeys[(el and el.selected) or glyphDisplay:getValue() or 1] or "auto"
end

-- ----- INPUT MODE LOCK (S91 Gamepad Phase 1) -----
-- Overrides InputModeDetector's auto-detection. Useful when the detector
-- is misbehaving on a weird controller or when the player wants to pin
-- the UI to one mode. Wired directly to ZeD.Input.Detector.setLockedMode.
inputModeLock = opts:addComboBox("inputModeLock", ZeD.tr("UI_ZeD_Settings_InputLock"),
    ZeD.tr("UI_ZeD_Settings_InputLockTip"))
for i, label in ipairs(inputLockLabels) do
    inputModeLock:addItem(ZeD.tr(label), inputLockKeys[i] == "auto")  -- default: auto
end

-- ----- SAFE MODE (Oct 19 2026, director: if ZeD ever fails to open, a bad day
-- is a setting flip rather than a hotfix) -----
-- On hands the game back to its own interface (SafeMode.lua reads this at most
-- every half second, so a change applies at once); ZeD also steps aside by itself
-- for a session when it hits an error that keeps repeating.
local safeMode = opts:addComboBox("safeMode", ZeD.tr("UI_ZeD_Settings_SafeMode"),
    ZeD.tr("UI_ZeD_Settings_SafeModeTip"))
safeMode:addItem(getText("UI_Off"), true)   -- default
safeMode:addItem(ZeD.tr("UI_ZeD_Settings_SafeModeOn"), false)
ZeD.Settings.safeModeOption = safeMode

-- ----- TEST LANGUAGE (translation groundwork, Oct 20 2026) -----
-- For checking layouts: ZeD.tr (shared/ZeD/Tr.lua) returns every ZeD phrase about 40%
-- longer, accented and in brackets, so clipped or overlapping text shows without a real
-- translation. Tr.lua reads this at most every half second. Last in the list: a combo is
-- saved as its item's position, so new options only ever go at the end.
local testLanguage = opts:addComboBox("testLanguage", ZeD.tr("UI_ZeD_Settings_TestLanguage"),
    "UI_ZeD_Settings_TestLanguageTip")   -- the key: the options screen reads it through getText (its text has a % sign, which a second getText of the translated words would choke on)
testLanguage:addItem(getText("UI_Off"), true)   -- default
testLanguage:addItem(getText("UI_On"), false)
ZeD.Settings.testLanguageOption = testLanguage

-- ----- THE KEYS OF THE OPTION NAMES -----
-- ModOptions keeps each name as the text the option was made with, which is read once, here at
-- file load, so the test language could never stretch it. Each option also keeps the key of its
-- name (zedNameKey), and ZeD's own Options window (ZeD_MainMenuOptionGroups / ZeD_MainMenuOptions)
-- draws that row's name through ZeD.tr every frame instead. (The items inside a combo are
-- still read once.)
do
    local nameKeys = {
        baseTheme = "UI_ZeD_Settings_BaseTheme", accentColor = "UI_ZeD_Settings_AccentColor",
        textSize = "UI_ZeD_Settings_TextSize", uiScale = "UI_ZeD_Settings_UiScale",
        moodlePlace = "UI_ZeD_Settings_Moodles", equipView = "UI_ZeD_Settings_EquipView",
        inventoryView = "UI_ZeD_Settings_Inventory", contextStyle = "UI_ZeD_Settings_ContextMenu",
        watchPlace = "UI_ZeD_Settings_Watch", actionBar = "UI_ZeD_Settings_ActionBar",
        charAccent = "UI_ZeD_Settings_CharAccent", worldAccent = "UI_ZeD_Settings_WorldAccent",
        glyphDisplay = "UI_ZeD_Settings_Glyphs", inputModeLock = "UI_ZeD_Settings_InputLock",
        safeMode = "UI_ZeD_Settings_SafeMode", testLanguage = "UI_ZeD_Settings_TestLanguage",
    }
    for id, key in pairs(nameKeys) do
        local o = opts.dict and opts.dict[id]
        if o then
            o.zedNameKey = key
            -- the item each option starts on (its addItem marked true above): still the default here,
            -- since ModOptions.ini is read later, when vanilla builds its options screen. ZeD setup's
            -- Defaults button and the help band's "Default:" read it (Oct 21 2026, mockup zed_settings_v2)
            o.zedDefault = o.selected
        end
    end
end

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
