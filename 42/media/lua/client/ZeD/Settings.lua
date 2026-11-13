-- ZeD-UI/42/media/lua/client/ZeD/Settings.lua
-- ============================================================================
-- MOD OPTIONS — client; every ZeD option is registered and applied here.
-- Registration happens at FILE LOAD TIME so options appear in the MODS tab
-- of the Options screen from the main menu (before any game starts).
-- Theme application happens at OnGameStart when the game world exists.
-- One thing to know before touching it: a combo is saved by its item's
-- POSITION, so a list only ever grows at the end (first section below).
--
-- The PZAPI.ModOptions calls used here (vanilla PZAPI/ModOptions.lua):
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

-- UI scale: Auto fits the screen (1x at 1080p, 2x at 4K,
-- nudged by the engine font-size option); the fixed steps override it.
local scaleKeys   = {"auto", 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0}
-- (no "%" in labels: ModOptions runs every label through getText, which chokes on it; the steps are
-- numbers, not words, so only Auto is a key)
local scaleLabels = {"UI_ZeD_Settings_ScaleAuto", "0.5x", "0.75x", "1x", "1.25x", "1.5x", "1.75x", "2x"}

-- Gamepad glyph display — which set of button pictures ZeD draws
-- (ZeD_PadGlyphs.lua). "Auto" follows the game's
-- controller button style (the game switches it to PlayStation by itself on
-- a PlayStation pad); an explicit set forces that one; "Keyboard/mouse" and
-- "Off" draw the buttons as lettered boxes instead of pictures.
-- (Deck sits mid-list, against the grow-at-the-end rule: that was safe only
-- because nothing had shipped reading this option yet, so a stored index
-- that moved changed nothing a player saw. Never move an item again.)
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

-- Shared with the window box menu, the controller's wheels and ZeD setup
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
-- (Lua locals are only visible after their declaration line)
local baseTheme, accentColor, textSize
-- gamepad options: glyphDisplay chooses button-prompt artwork;
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

--- Sync current theme state back to ModOptions combo boxes (the window box
--- menu and the Select wheel call it after they change the theme)
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
    accentColor:addItem(ZeD.tr(label), accentKeys[i] == ZeD.DEFAULT_ACCENT)  -- default: PZ Teal
end

-- ----- TEXT SIZE -----
textSize = opts:addComboBox("textSize", ZeD.tr("UI_ZeD_Settings_TextSize"),
    ZeD.tr("UI_ZeD_Settings_TextSizeTip"))
for i, label in ipairs(sizeLabels) do
    textSize:addItem(ZeD.tr(label), sizeKeys[i] == "small")  -- default: small
end

-- ----- STATUS COLORS -----
-- Good, warning and bad everywhere (condition and health bars, their readings, checks and crosses): each theme's
-- green, yellow and red, or a blue, yellow and orange set that stays apart for every kind of color blindness
-- (ZeD.StatusColors in Tokens.lua; punch list 144). Applied with the theme (applyFromOptions, below).
local statusKeys = { "standard", "cb" }
local statusColors = opts:addComboBox("statusColors", ZeD.tr("UI_ZeD_Settings_StatusColors"), ZeD.tr("UI_ZeD_Settings_StatusColorsTip"))
statusColors:addItem(ZeD.tr("UI_ZeD_Settings_StatusStandard"), true)   -- default
statusColors:addItem(ZeD.tr("UI_ZeD_Settings_StatusColorBlind"), false)
ZeD.Settings.statusColorsOption = statusColors
ZeD.Settings.statusKeys = statusKeys

-- ----- UI SCALE -----
local uiScale = opts:addComboBox("uiScale", ZeD.tr("UI_ZeD_Settings_UiScale"),
    ZeD.tr("UI_ZeD_Settings_UiScaleTip"))
for i, label in ipairs(scaleLabels) do
    uiScale:addItem((i == 1) and ZeD.tr(label) or label, i == 1)  -- default: Auto (the other steps are numbers)
end
--- The UI scale applied (also ZeD.Settings.applyScale). idx: the item just picked (vanilla hands the new
--- index to onChange; the stored value is only updated at Apply). Without it, the stored value is used.
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
ZeD.Settings.uiScaleOption = uiScale   -- the QA scripts (ZeDUI/tools/qa) and the controller's wheel drive it like the options screen
--- The UI scale cap (the rules: ZeD.Scale.fitCap in shared/ZeD/Scale.lua): true when item i of
--- control c is UI scale's fixed step above what fits this screen. ZeD setup's slider, the Mods page's
--- drop-down and the controller's wheel dim such a step and take no pick of it. c: the option or its element.
function ZeD.Settings.scaleStepOff(c, i)
    if c == nil or not (c == uiScale or c == uiScale.element) then return false end
    local v = scaleKeys[tonumber(i) or 0]
    local Sc = ZeD.Scale
    if Sc and Sc.stepRetired and Sc.stepRetired(v) then return true end   -- 0.5x, not offered in the beta
    return (Sc and Sc.stepTooBig and Sc.stepTooBig(v)) or false
end
--- True when item i is a retired step (0.5x): the controller's wheel leaves it out; the slider dims it.
function ZeD.Settings.scaleStepRetired(i)
    local Sc = ZeD.Scale
    return (Sc and Sc.stepRetired and Sc.stepRetired(scaleKeys[tonumber(i) or 0])) or false
end
--- The help line's words while some steps are off: "2x and up: too big for this screen." (nil when none are)
function ZeD.Settings.scaleTooBigHelp()
    for i = 2, #scaleKeys do
        if ZeD.Scale and ZeD.Scale.stepTooBig and ZeD.Scale.stepTooBig(scaleKeys[i]) then
            return ZeD.tr("UI_ZeD_Settings_ScaleTooBigFrom", scaleLabels[i])
        end
    end
    return nil
end

-- ----- MOODLES -----
-- Where vanilla's moodles sit — an option because each placement suits a
-- different player; they are drawn as vanilla draws them in all
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

-- ----- EQUIPPED VIEW -----
-- The Equip tab's two views; the toggle in its Equipped heading sets this
-- too, so the choice is remembered across saves (EquipDoll.lua reads it).
local equipView = opts:addComboBox("equipView", ZeD.tr("UI_ZeD_Settings_EquipView"),
    ZeD.tr("UI_ZeD_Settings_EquipViewTip"))
equipView:addItem(ZeD.tr("UI_ZeD_Settings_ViewList"), true)  -- default: the list
equipView:addItem(ZeD.tr("UI_ZeD_Settings_ViewDoll"), false)
ZeD.Settings.equipViewOption = equipView

-- ----- RESTOCK -----
-- How the Equip tab's Restock and Unpack go (ZeD_Restock.lua reads it each time): Hardcore takes
-- from what is in reach now, Casual (the default) as containers come into reach, Accessible walks
-- the building for you. The choice lives here, never in a first-run question.
local restock = opts:addComboBox("restock", ZeD.tr("UI_ZeD_Settings_Restock"), ZeD.tr("UI_ZeD_Settings_RestockTip"))
restock:addItem(ZeD.tr("UI_ZeD_Settings_RestockHardcore"), false)
restock:addItem(ZeD.tr("UI_ZeD_Settings_RestockCasual"), true)   -- default
restock:addItem(ZeD.tr("UI_ZeD_Settings_RestockAccessible"), false)
ZeD.Settings.restockOption = restock

-- ----- THE OTHER VIEW CHOICES: all lists or all grids for the most used
-- menus -----
-- The inventory's view for every container that hasn't one of its own (each
-- column's view button still sets one container; InventoryRenderer).
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
watchPlace:addItem(ZeD.tr("UI_ZeD_Settings_WatchBelt"), true)   -- default
watchPlace:addItem(ZeD.tr("UI_ZeD_Settings_WatchCorner"), false)
ZeD.Settings.watchPlaceOption = watchPlace

-- ----- ACTION BAR -----
-- The bar over the character's head while an action runs (ZeD_ActionBar.lua reads this
-- every frame, so a change applies at once). Detailed is the default (its
-- translation key still reads "Verbose", the row's old name).
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

-- ----- GLYPH DISPLAY -----
-- Sets which button-prompt artwork is used in footer prompt strips.
-- Auto follows the connected controller; explicit choices override.
-- ZeD_PadGlyphs reads the picked set every draw (glyphKey, below).
glyphDisplay = opts:addComboBox("glyphDisplay", ZeD.tr("UI_ZeD_Settings_Glyphs"),
    ZeD.tr("UI_ZeD_Settings_GlyphsTip"))
for i, label in ipairs(glyphLabels) do
    glyphDisplay:addItem(ZeD.tr(label), glyphKeys[i] == "auto")  -- default: auto
end
--- glyphKey(): the picked set's key, live while the options screen is open (ZeD_PadGlyphs reads it every draw)
ZeD.Settings.glyphOption = glyphDisplay
ZeD.Settings.glyphKey = function()
    local el = glyphDisplay.element
    return glyphKeys[(el and el.selected) or glyphDisplay:getValue() or 1] or "auto"
end

-- ----- INPUT MODE LOCK -----
-- Overrides InputModeDetector's auto-detection. Useful when the detector
-- is misbehaving on a weird controller or when the player wants to pin
-- the UI to one mode. Wired directly to ZeD.Input.Detector.setLockedMode.
inputModeLock = opts:addComboBox("inputModeLock", ZeD.tr("UI_ZeD_Settings_InputLock"),
    ZeD.tr("UI_ZeD_Settings_InputLockTip"))
for i, label in ipairs(inputLockLabels) do
    inputModeLock:addItem(ZeD.tr(label), inputLockKeys[i] == "auto")  -- default: auto
end

-- ----- SAFE MODE: if ZeD ever fails to open, a bad day is a setting flip
-- rather than a hotfix -----
-- On hands the game back to its own interface (SafeMode.lua reads this at most
-- every half second, so a change applies at once); ZeD also steps aside by itself
-- for a session when it hits an error that keeps repeating.
local safeMode = opts:addComboBox("safeMode", ZeD.tr("UI_ZeD_Settings_SafeMode"),
    ZeD.tr("UI_ZeD_Settings_SafeModeTip"))
safeMode:addItem(getText("UI_Off"), true)   -- default
safeMode:addItem(ZeD.tr("UI_ZeD_Settings_SafeModeOn"), false)
ZeD.Settings.safeModeOption = safeMode

-- ----- TEST LANGUAGE -----
-- For checking layouts: ZeD.tr (shared/ZeD/Tr.lua) returns every ZeD phrase about 40%
-- longer, accented and in brackets, so clipped or overlapping text shows without a real
-- translation. Tr.lua reads this at most every half second. It went in at the end of the
-- list, where every new option goes: a combo is saved as its item's position.
local testLanguage = opts:addComboBox("testLanguage", ZeD.tr("UI_ZeD_Settings_TestLanguage"),
    "UI_ZeD_Settings_TestLanguageTip")   -- the key: the options screen reads it through getText (its text has a % sign, which a second getText of the translated words would choke on)
testLanguage:addItem(getText("UI_Off"), true)   -- default
testLanguage:addItem(getText("UI_On"), false)
ZeD.Settings.testLanguageOption = testLanguage

-- ----- PUT THINGS BACK (ZeD_PutBack.lua) -----
-- After an action, what it took out of a bag, a container in reach or off the floor
-- goes back there, and the hands as they were, by the game's own moves. Off for a
-- new player.
local putBack = opts:addComboBox("putBack", ZeD.tr("UI_ZeD_Settings_PutBack"), ZeD.tr("UI_ZeD_Settings_PutBackTip"))
putBack:addItem(getText("UI_Off"), true)   -- default
putBack:addItem(getText("UI_On"), false)
ZeD.Settings.putBackOption = putBack
ZeD.Settings.putBackOn = function() return (putBack:getValue() or 1) == 2 end

-- ----- MESSAGES (ZeD_Messages.lua) -----
-- Another mod's note (one OK) is kept in the Messages window instead of covering the game,
-- and a toast says it came. Both off for a new player: every addition starts
-- off (the Vanilla preset below).
-- (item 1 Off, item 2 On: ZeD setup's on/off switch and the saved values read them so)
local msgCatch = opts:addComboBox("messagesCatch", ZeD.tr("UI_ZeD_Settings_MsgCatch"), ZeD.tr("UI_ZeD_Settings_MsgCatchTip"))
msgCatch:addItem(getText("UI_Off"), true)   -- default
msgCatch:addItem(getText("UI_On"), false)
ZeD.Settings.messagesCatchOption = msgCatch
ZeD.Settings.messagesCatchOn = function() return (msgCatch:getValue() or 1) == 2 end
local msgToast = opts:addComboBox("messagesToast", ZeD.tr("UI_ZeD_Settings_MsgToast"), ZeD.tr("UI_ZeD_Settings_MsgToastTip"))
msgToast:addItem(getText("UI_Off"), true)   -- default
msgToast:addItem(getText("UI_On"), false)
ZeD.Settings.messagesToastOption = msgToast
ZeD.Settings.messagesToastOn = function() return (msgToast:getValue() or 1) == 2 end
-- the game's overhead notes ("Too heavy", "Can't reach") in ZeD's bubble and the Messages log
-- (ZeD_HaloText.lua). An addition like the others: off for a vanilla run, on in Vanilla Plus and Access.
local haloBubble = opts:addComboBox("haloBubble", ZeD.tr("UI_ZeD_Settings_HaloBubble"), ZeD.tr("UI_ZeD_Settings_HaloBubbleTip"))
haloBubble:addItem(getText("UI_Off"), true)   -- default
haloBubble:addItem(getText("UI_On"), false)
ZeD.Settings.haloBubbleOption = haloBubble
ZeD.Settings.haloBubbleOn = function() return (haloBubble:getValue() or 1) == 2 end
-- the hint strip: what you can do with what is in front of you, your key or button and the game's own words
-- (ZeD_HintStrip.lua). Always (the default), First hours, or Off. Not one of
-- the presets' additions: the presets leave it as it is.
local hintStrip = opts:addComboBox("hintStrip", ZeD.tr("UI_ZeD_Settings_HintStrip"), ZeD.tr("UI_ZeD_Settings_HintStripTip"))
hintStrip:addItem(ZeD.tr("UI_ZeD_Settings_HintAlways"), true)   -- default
hintStrip:addItem(ZeD.tr("UI_ZeD_Settings_HintFirst"), false)
hintStrip:addItem(getText("UI_Off"), false)
ZeD.Settings.hintStripOption = hintStrip
--- "always" | "first" | "off"
ZeD.Settings.hintStripMode = function() return ({ "always", "first", "off" })[hintStrip:getValue() or 1] or "always" end

-- ----- SANDBOX OPTIONS IN GAME (ZeD_SandboxInGame.lua) -----
-- A "Sandbox options" line in the pause window: this save's sandbox settings, changed
-- without starting over. Off for a new player. Single player only.
local sandboxIG = opts:addComboBox("sandboxInGame", ZeD.tr("UI_ZeD_Settings_SandboxIG"), ZeD.tr("UI_ZeD_Settings_SandboxIGTip"))
sandboxIG:addItem(getText("UI_Off"), true)   -- default
sandboxIG:addItem(getText("UI_On"), false)
ZeD.Settings.sandboxInGameOption = sandboxIG
ZeD.Settings.sandboxInGameOn = function() return (sandboxIG:getValue() or 1) == 2 end

-- ----- DIM READ ITEMS -----
-- In the item lists, books, magazines, maps and tapes already read are faded so the unread ones stand out
-- (ReadMarks.lua reads this every frame). Off for a new player: a dimmed row can look unavailable.
local dimRead = opts:addComboBox("dimRead", ZeD.tr("UI_ZeD_Settings_DimRead"), ZeD.tr("UI_ZeD_Settings_DimReadTip"))
dimRead:addItem(getText("UI_Off"), true)   -- default
dimRead:addItem(getText("UI_On"), false)
ZeD.Settings.dimReadOption = dimRead
ZeD.Settings.dimReadOn = function() return (dimRead:getValue() or 1) == 2 end

-- ----- WHAT VANILLA DOES NOT DO: each thing the vanilla game does not do
-- is a switch. Each off for a new player (every addition starts off, the
-- Vanilla preset below); off puts that part back as it was. Read every frame by
-- ZeD_Belt, ReadMarks / InventoryRenderer, ZeD_Dashboard and ZeD_Moodles, so a change applies at once.
local function onSwitch(id, nameKey, tipKey)
    local o = opts:addComboBox(id, ZeD.tr(nameKey), ZeD.tr(tipKey))
    o:addItem(getText("UI_Off"), true)   -- default
    o:addItem(getText("UI_On"), false)   -- (item 1 Off, item 2 On: ZeD setup's on/off switch and the saved values read them so)
    return o
end
local ammoBox = onSwitch("ammoBox", "UI_ZeD_Settings_AmmoBox", "UI_ZeD_Settings_AmmoBoxTip")
ZeD.Settings.ammoBoxOption = ammoBox
ZeD.Settings.ammoBoxOn = function() return (ammoBox:getValue() or 1) == 2 end
local readMarks = onSwitch("readMarks", "UI_ZeD_Settings_ReadMarks", "UI_ZeD_Settings_ReadMarksTip")
ZeD.Settings.readMarksOption = readMarks
ZeD.Settings.readMarksOn = function() return (readMarks:getValue() or 1) == 2 end
local readNext = onSwitch("readNext", "UI_ZeD_Settings_ReadNext", "UI_ZeD_Settings_ReadNextTip")
ZeD.Settings.readNextOption = readNext
ZeD.Settings.readNextOn = function() return (readNext:getValue() or 1) == 2 end
local dashLamps = onSwitch("dashLamps", "UI_ZeD_Settings_DashLamps", "UI_ZeD_Settings_DashLampsTip")
ZeD.Settings.dashLampsOption = dashLamps
ZeD.Settings.dashLampsOn = function() return (dashLamps:getValue() or 1) == 2 end
local moodleNotices = onSwitch("moodleNotices", "UI_ZeD_Settings_MoodleNotices", "UI_ZeD_Settings_MoodleNoticesTip")
ZeD.Settings.moodleNoticesOption = moodleNotices
ZeD.Settings.moodleNoticesOn = function() return (moodleNotices:getValue() or 1) == 2 end

-- ----- THE WINDOWS: SEE-THROUGH, SOLID WHILE IN USE, CONTROLLER HIGHLIGHT.
-- Also in every window's window box menu (ZeD_WindowMenu.lua) and on the
-- Select wheel. -----
-- The pick the player has made, live while the options screen is open (vanilla keeps it on
-- the control until Apply), else the stored one
local function liveIdx(opt)
    local el = opt.element
    return (el and el.selected) or opt:getValue()
end
-- See-through: one alpha for every window surface, 100 to 60 in steps of 10 (the items are
-- numbers: ModOptions runs every label through getText, which chokes on a percent sign).
-- Applied with the theme (applyFromOptions, below). Dark only: Light and High Contrast draw
-- solid whatever it says (ZeD.seeThroughWorks), and its help line says so.
local seeKeys = { 100, 90, 80, 70, 60 }
local seeThrough = opts:addComboBox("seeThrough", ZeD.tr("UI_ZeD_Settings_SeeThrough"), ZeD.tr("UI_ZeD_Settings_SeeThroughTip"))
for _, v in ipairs(seeKeys) do seeThrough:addItem(tostring(v), v == 90) end   -- default: 90
ZeD.Settings.seeThroughOption = seeThrough
ZeD.Settings.seeThroughKeys = seeKeys
ZeD.Settings.seeThroughIndex = function() return liveIdx(seeThrough) or 2 end
ZeD.Settings.seeThrough = function() return seeKeys[liveIdx(seeThrough) or 2] or 90 end
-- Solid while in use: a window goes solid while the pointer is over it or the controller is in
-- it (ZeD_Window reads this every frame). Off for a new player.
local solidInUse = opts:addComboBox("solidInUse", ZeD.tr("UI_ZeD_Settings_SolidInUse"), ZeD.tr("UI_ZeD_Settings_SolidInUseTip"))
solidInUse:addItem(getText("UI_Off"), true)   -- default
solidInUse:addItem(getText("UI_On"), false)
ZeD.Settings.solidInUseOption = solidInUse
ZeD.Settings.solidInUse = function() return (liveIdx(solidInUse) or 1) == 2 end
-- Blink the low-health pixel: the Character window's health pixel blinks at 20% health and under
-- (ZeD_Window.pixelLit reads this every frame, so a pick holds at once). Off holds it solid red,
-- for anyone who finds a blink hard to bear. On for a new player.
local healthBlink = opts:addComboBox("healthBlink", ZeD.tr("UI_ZeD_Settings_HealthBlink"),
    "UI_ZeD_Settings_HealthBlinkTip")   -- the key: its text has a % sign (see Test language)
healthBlink:addItem(getText("UI_Off"), false)
healthBlink:addItem(getText("UI_On"), true)   -- default
ZeD.Settings.healthBlinkOption = healthBlink
ZeD.Settings.healthBlink = function() return (liveIdx(healthBlink) or 2) == 2 end
-- Controller highlight: how the element the controller is on is marked (ZeD.Focus draws it and
-- reads ZeD.Settings.focusStyle() every frame). The pointing hand for a new player.
local focusKeys   = { "hand", "corners", "wash", "ants" }
local focusLabels = { "UI_ZeD_Settings_FocusHand", "UI_ZeD_Settings_FocusCorners", "UI_ZeD_Settings_FocusWash", "UI_ZeD_Settings_FocusAnts" }
local focusStyle = opts:addComboBox("focusStyle", ZeD.tr("UI_ZeD_Settings_FocusStyle"), ZeD.tr("UI_ZeD_Settings_FocusStyleTip"))
for i, label in ipairs(focusLabels) do focusStyle:addItem(ZeD.tr(label), i == 1) end   -- default: the hand
ZeD.Settings.focusStyleOption = focusStyle
ZeD.Settings.focusStyleKeys   = focusKeys
ZeD.Settings.focusStyleLabels = focusLabels
--- "hand", "corners", "wash" or "ants" (the hand when the option cannot be read)
ZeD.Settings.focusStyle = function()
    local ok, i = pcall(liveIdx, focusStyle)
    return (ok and focusKeys[tonumber(i) or 1]) or "hand"
end
-- How the controller's wheels are worked (ZeD_WheelGesture.lua reads these
-- as a wheel opens, the dead zone every frame). Wheel open: Tap, the wheel stays up; Hold, up while the direction is
-- held. Wheel commit: Flick-release, letting the stick go takes; Stick click, R3 takes. Wheel toggle mode: the stick
-- or the D-pad moves the highlight, A takes; it overrides the other two. The dead zone is the stick's magnitude for
-- a slice to highlight; release is 60% of it. The items are numbers, like See-through's.
local wheelZones = { 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60 }
local wheelOpen = opts:addComboBox("wheelOpen", ZeD.tr("UI_ZeD_Settings_WheelOpen"), ZeD.tr("UI_ZeD_Settings_WheelOpenTip"))
wheelOpen:addItem(ZeD.tr("UI_ZeD_Settings_WheelTap"), true)   -- default
wheelOpen:addItem(ZeD.tr("UI_ZeD_Settings_WheelHold"), false)
local wheelCommit = opts:addComboBox("wheelCommit", ZeD.tr("UI_ZeD_Settings_WheelCommit"), ZeD.tr("UI_ZeD_Settings_WheelCommitTip"))
wheelCommit:addItem(ZeD.tr("UI_ZeD_Settings_WheelFlick"), true)   -- default
wheelCommit:addItem(ZeD.tr("UI_ZeD_Settings_WheelClick"), false)
local wheelToggle = opts:addComboBox("wheelToggle", ZeD.tr("UI_ZeD_Settings_WheelToggle"), ZeD.tr("UI_ZeD_Settings_WheelToggleTip"))
wheelToggle:addItem(getText("UI_Off"), true)   -- default
wheelToggle:addItem(getText("UI_On"), false)
local wheelDeadZone = opts:addComboBox("wheelDeadZone", ZeD.tr("UI_ZeD_Settings_WheelDeadZone"), ZeD.tr("UI_ZeD_Settings_WheelDeadZoneTip"))
for _, v in ipairs(wheelZones) do wheelDeadZone:addItem(string.format("%.2f", v), v == 0.35) end   -- default: 0.35
ZeD.Settings.wheelOpenOption = wheelOpen
ZeD.Settings.wheelCommitOption = wheelCommit
ZeD.Settings.wheelToggleOption = wheelToggle
ZeD.Settings.wheelDeadZoneOption = wheelDeadZone
ZeD.Settings.wheelOpen = function() return ((liveIdx(wheelOpen) or 1) == 2) and "hold" or "tap" end
ZeD.Settings.wheelCommit = function() return ((liveIdx(wheelCommit) or 1) == 2) and "click" or "flick" end
ZeD.Settings.wheelToggle = function() return (liveIdx(wheelToggle) or 1) == 2 end
ZeD.Settings.wheelDeadZone = function() return wheelZones[liveIdx(wheelDeadZone) or 4] or 0.35 end
-- Hidden actions: the actions that cannot be taken right now, folded
-- under a hint row that opens, all shown greyed, or hidden. On ZeD setup only, never asked in
-- a pop-up: interruptions in this game can quickly get you killed.
local hiddenKeys   = { "folded", "all", "hide" }
local hiddenLabels = { "UI_ZeD_Settings_HiddenFolded", "UI_ZeD_Settings_HiddenAll", "UI_ZeD_Settings_HiddenHide" }
local hiddenActions = opts:addComboBox("hiddenActions", ZeD.tr("UI_ZeD_Settings_HiddenActions"), ZeD.tr("UI_ZeD_Settings_HiddenActionsTip"))
for i, label in ipairs(hiddenLabels) do hiddenActions:addItem(ZeD.tr(label), i == 1) end   -- default: folded
ZeD.Settings.hiddenActionsOption = hiddenActions
ZeD.Settings.hiddenActionsKeys   = hiddenKeys
--- "folded", "all" or "hide" ("folded" when the option cannot be read)
ZeD.Settings.hiddenActions = function()
    local ok, i = pcall(liveIdx, hiddenActions)
    return (ok and hiddenKeys[tonumber(i) or 1]) or "folded"
end

-- ----- LOADOUTS AND OUTFITS (one switch for all of it; Restock follows
-- Loadouts) -----
-- The Equip tab's Loadouts fold and its to-do, the Journal's Loadouts page, the item card's Lists mark, the
-- right-click Save to outfit / Save to loadout, the controller's Loadouts ring, and Restock with its pinned
-- list. Off hides them all and Restock does nothing; the saved loadouts and outfits stay with the character,
-- so turning it back on brings every one back. Each place asks ZeD.Lists.on() as it draws, so a change applies
-- at once. Off for a new player; a player who had ZeD before this switch keeps it on (see the additions, below).
local loadouts = opts:addComboBox("loadouts", ZeD.tr("UI_ZeD_Settings_Loadouts"), ZeD.tr("UI_ZeD_Settings_LoadoutsTip"))
loadouts:addItem(getText("UI_Off"), true)   -- default
loadouts:addItem(getText("UI_On"), false)   -- (item 1 Off, item 2 On: ZeD setup's on/off switch)
ZeD.Settings.loadoutsOption = loadouts
ZeD.Settings.loadoutsOn = function() return (loadouts:getValue() or 1) == 2 end

-- ----- THE ADDITIONS' PRESET -----
-- Vanilla (a new player's start), Vanilla Plus, Vanilla Accessible, or Custom: what the switches for the things
-- vanilla does not do are set to (the table in setUpAdditions, below). Never the look.
local additionsPreset = opts:addComboBox("additionsPreset", ZeD.tr("UI_ZeD_Settings_Preset"), ZeD.tr("UI_ZeD_Settings_PresetTip"))
additionsPreset:addItem(ZeD.tr("UI_ZeD_Settings_PresetVanilla"), true)   -- default
additionsPreset:addItem(ZeD.tr("UI_ZeD_Settings_PresetPlus"), false)
additionsPreset:addItem(ZeD.tr("UI_ZeD_Settings_PresetAccessible"), false)
additionsPreset:addItem(getText("Sandbox_Custom"), false)   -- (the game's own "Custom")
ZeD.Settings.additionsPresetOption = additionsPreset

-- ----- ZED SCREENS: players asked to turn one screen off (the belt) and keep the rest, so the mod steps
-- aside piece by piece instead of shipping as separate modules -----
-- One switch per ZeD screen that can hand itself back, under Safe mode in ZeD setup and read the same way:
-- On gives that one screen back to the game's own (what safe mode does for all of them, SafeMode.lua), Off
-- (the default) keeps it ZeD's. Not additions: the presets leave them alone. (Combos are saved by position,
-- so these stay after every older option.)
ZeD.Settings.screenOptions = {}
for _, sc in ipairs({
    { "screenWindows",   "windows",   "UI_ZeD_Settings_ScreenWindows" },
    { "screenBelt",      "belt",      "UI_ZeD_Settings_ScreenBelt" },
    { "screenWatch",     "watch",     "UI_ZeD_Settings_ScreenWatch" },
    { "screenDashboard", "dashboard", "UI_ZeD_Settings_ScreenDashboard" },
    { "screenMoodles",   "moodles",   "UI_ZeD_Settings_ScreenMoodles" },
    { "screenWheels",    "wheels",    "UI_ZeD_Settings_ScreenWheels" },
    { "screenCharInfo",  "charinfo",  "UI_ZeD_Settings_ScreenCharInfo" },
    { "screenConsole",   "console",   "UI_ZeD_Settings_ScreenConsole" },   -- (debug mode only: the Lua console)
}) do
    local o = opts:addComboBox(sc[1], ZeD.tr(sc[3]), ZeD.tr(sc[3] .. "Tip"))
    o:addItem(getText("UI_Off"), true)   -- default: ZeD's
    o:addItem(getText("UI_On"), false)   -- the game's own
    ZeD.Settings.screenOptions[sc[2]] = o
    if ZeD.Safe and ZeD.Safe.setPieceOption then ZeD.Safe.setPieceOption(sc[2], o) end
end

-- ----- THE BELT'S FORM: a full and a simple version, as for the action bar -----
-- Immersive: the leather strap and the profession buckle. Simple: the same slots and hands with no strap or buckle.
-- ZeD_Belt.lua reads it as it lays out, so a change applies at once. Immersive is the default.
local beltStyle = opts:addComboBox("beltStyle", ZeD.tr("UI_ZeD_Settings_Belt"), ZeD.tr("UI_ZeD_Settings_BeltTip"))
beltStyle:addItem(ZeD.tr("UI_ZeD_Settings_Immersive"), true)   -- default
beltStyle:addItem(ZeD.tr("UI_ZeD_Settings_ActionBarSimple"), false)
ZeD.Settings.beltStyleOption = beltStyle

-- ----- THE DEVICES' FORM -----
-- Immersive: each device drawn as its face (radios, TVs, two-way sets, ovens, microwaves, the fryer, the grill, generators,
-- washers and dryers). Simple: the same controls and readings as a plain ZeD card. Immersive is the default; Vanilla Plus
-- keeps Immersive, Vanilla Access picks Simple (the additions presets below).
local devicesStyle = opts:addComboBox("devicesStyle", ZeD.tr("UI_ZeD_Settings_Devices"), ZeD.tr("UI_ZeD_Settings_DevicesTip"))
devicesStyle:addItem(ZeD.tr("UI_ZeD_Settings_Immersive"), true)   -- default
devicesStyle:addItem(ZeD.tr("UI_ZeD_Settings_ActionBarSimple"), false)
ZeD.Settings.devicesStyleOption = devicesStyle
--- True while the devices are drawn as simple cards (read as they draw, so a change applies at once).
--- watchSimple, dashSimple, guideSimple, modsSimple and identitySimple below answer the same for theirs.
function ZeD.Settings.devicesSimple()
    local ok, v = pcall(devicesStyle.getValue, devicesStyle)
    return ok and v == 2
end

-- ----- THE WATCH'S FORM -----
-- Immersive: the watch you wear, drawn as itself (and the tape deck keys with none). Simple: a plain clock box with the
-- same readings and buttons, and a plain time box for the small one on the belt.
local watchStyle = opts:addComboBox("watchStyle", ZeD.tr("UI_ZeD_Settings_WatchStyle"), ZeD.tr("UI_ZeD_Settings_WatchStyleTip"))
watchStyle:addItem(ZeD.tr("UI_ZeD_Settings_Immersive"), true)   -- default
watchStyle:addItem(ZeD.tr("UI_ZeD_Settings_ActionBarSimple"), false)
ZeD.Settings.watchStyleOption = watchStyle
function ZeD.Settings.watchSimple()
    local ok, v = pcall(watchStyle.getValue, watchStyle)
    return ok and v == 2
end

-- ----- THE DASHBOARD'S FORM -----
-- Immersive: each car's own pixel dash (and the taxi meter, the siren controller). Simple: a plain strip with the same
-- readings, lamps and switches.
local dashStyle = opts:addComboBox("dashStyle", ZeD.tr("UI_ZeD_Settings_Dash"), ZeD.tr("UI_ZeD_Settings_DashTip"))
dashStyle:addItem(ZeD.tr("UI_ZeD_Settings_Immersive"), true)   -- default
dashStyle:addItem(ZeD.tr("UI_ZeD_Settings_ActionBarSimple"), false)
ZeD.Settings.dashStyleOption = dashStyle
function ZeD.Settings.dashSimple()
    local ok, v = pcall(dashStyle.getValue, dashStyle)
    return ok and v == 2
end

-- ----- THE SURVIVAL GUIDE'S FORM -----
-- Immersive: the guide as a printed book, Survive the Apocalypse (ZeD_SurvivalGuideBook.lua). Simple: a ZeD window with the
-- same topics, clips and numbers (ZeD_SurvivalGuide.lua).
local guideStyle = opts:addComboBox("guideStyle", ZeD.tr("UI_ZeD_Settings_Guide"), ZeD.tr("UI_ZeD_Settings_GuideTip"))
guideStyle:addItem(ZeD.tr("UI_ZeD_Settings_Immersive"), true)   -- default
guideStyle:addItem(ZeD.tr("UI_ZeD_Settings_ActionBarSimple"), false)
ZeD.Settings.guideStyleOption = guideStyle
function ZeD.Settings.guideSimple()
    local ok, v = pcall(guideStyle.getValue, guideStyle)
    return ok and v == 2
end

-- ----- THE MODS SCREEN'S FORM: a Simple view for newcomers, asked for on the Workshop -----
-- Detailed: the mods with their IDs, tags, folders, profiles and the load order. Simple: one line a mod (the box, the
-- name, one mark when something is wrong), the tabs All, On, Off and Problems, and the info pane's About only.
local modsStyle = opts:addComboBox("modsStyle", ZeD.tr("UI_ZeD_Settings_Mods"), ZeD.tr("UI_ZeD_Settings_ModsTip"))
modsStyle:addItem(ZeD.tr("UI_ZeD_Settings_ActionBarVerbose"), true)   -- default
modsStyle:addItem(ZeD.tr("UI_ZeD_Settings_ActionBarSimple"), false)
ZeD.Settings.modsStyleOption = modsStyle
function ZeD.Settings.modsSimple()
    local ok, v = pcall(modsStyle.getValue, modsStyle)
    return ok and v == 2
end

-- ----- THE IDENTITY CARD'S FORM: everything is either Immersive or Simple -----
-- Immersive: the Kentucky license. Simple: ZeD components, the same facts on the theme's surface.
local identityStyle = opts:addComboBox("identityStyle", ZeD.tr("UI_ZeD_Settings_Identity"), ZeD.tr("UI_ZeD_Settings_IdentityTip"))
identityStyle:addItem(ZeD.tr("UI_ZeD_Settings_Immersive"), true)   -- default
identityStyle:addItem(ZeD.tr("UI_ZeD_Settings_ActionBarSimple"), false)
ZeD.Settings.identityStyleOption = identityStyle
function ZeD.Settings.identitySimple()
    local ok, v = pcall(identityStyle.getValue, identityStyle)
    return ok and v == 2
end

-- ----- THE HIDDEN FACTS: Vanilla Plus gates them; only Vanilla Access opens them from the start -----
-- Find first: the guide's TV schedule opens once the character has read TV Monthly, the infection odds once they have
-- read a First Aid book (ZeD_HiddenFacts.lua). Always: both open from the start, and the crafting card's How to learn
-- names the magazine. An addition: Find first in Vanilla and Vanilla Plus, Always in Vanilla Access.
local hiddenFacts = opts:addComboBox("hiddenFacts", ZeD.tr("UI_ZeD_Settings_HiddenFacts"), ZeD.tr("UI_ZeD_Settings_HiddenFactsTip"))
hiddenFacts:addItem(ZeD.tr("UI_ZeD_Settings_FindFirst"), true)   -- default
hiddenFacts:addItem(ZeD.tr("UI_ZeD_Hidden_Always"), false)
ZeD.Settings.hiddenFactsOption = hiddenFacts
function ZeD.Settings.hiddenFactsAlways()
    local ok, v = pcall(hiddenFacts.getValue, hiddenFacts)
    return ok and v == 2
end

-- ----- RECIPES SKILLS TEACH -----
-- The skill card also lists the recipes the game teaches by itself when a skill reaches a level (RecipeIndex.lua).
-- The game never says which; so an addition, off for Vanilla and Vanilla Plus, on for Vanilla Access, Custom the
-- player's pick. Read as the card draws, so a change applies at once.
local autoLearn = onSwitch("autoLearn", "UI_ZeD_Settings_AutoLearn", "UI_ZeD_Settings_AutoLearnTip")
ZeD.Settings.autoLearnOption = autoLearn
ZeD.Settings.autoLearnOn = function() return (autoLearn:getValue() or 1) == 2 end

-- ----- RUN BUTTON ALSO SNEAKS (a controller, with Run on a button) -----
-- A hold of the game's Run button (RT in the Original layout, or wherever a player's own layout puts it, never a
-- stick click or a bumper) standing still crouches or stands; crouched and moving, it stands up and the game's run
-- carries on; a tap stays the game's. Where Run is a full push of the stick (the Default layout) it does nothing
-- (Input/RunSneak.lua reads this every frame, so a change applies at once). Off for a new player. A way of working
-- the pad, like the wheels' options, not an addition: the presets leave it.
local runSneak = opts:addComboBox("runSneak", ZeD.tr("UI_ZeD_Settings_RunSneak"), ZeD.tr("UI_ZeD_Settings_RunSneakTip"))
runSneak:addItem(getText("UI_Off"), true)   -- default
runSneak:addItem(getText("UI_On"), false)   -- (item 1 Off, item 2 On: ZeD setup's checkbox reads them so)
ZeD.Settings.runSneakOption = runSneak
ZeD.Settings.runSneakOn = function() return (liveIdx(runSneak) or 1) == 2 end

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
        statusColors = "UI_ZeD_Settings_StatusColors",
        moodlePlace = "UI_ZeD_Settings_Moodles", equipView = "UI_ZeD_Settings_EquipView",
        inventoryView = "UI_ZeD_Settings_Inventory", contextStyle = "UI_ZeD_Settings_ContextMenu",
        watchPlace = "UI_ZeD_Settings_Watch", actionBar = "UI_ZeD_Settings_ActionBar",
        charAccent = "UI_ZeD_Settings_CharAccent", worldAccent = "UI_ZeD_Settings_WorldAccent",
        glyphDisplay = "UI_ZeD_Settings_Glyphs", inputModeLock = "UI_ZeD_Settings_InputLock",
        safeMode = "UI_ZeD_Settings_SafeMode", testLanguage = "UI_ZeD_Settings_TestLanguage",
        putBack = "UI_ZeD_Settings_PutBack", seeThrough = "UI_ZeD_Settings_SeeThrough",
        solidInUse = "UI_ZeD_Settings_SolidInUse", healthBlink = "UI_ZeD_Settings_HealthBlink", focusStyle = "UI_ZeD_Settings_FocusStyle",
        hiddenActions = "UI_ZeD_Settings_HiddenActions",
        messagesCatch = "UI_ZeD_Settings_MsgCatch", messagesToast = "UI_ZeD_Settings_MsgToast", haloBubble = "UI_ZeD_Settings_HaloBubble", hintStrip = "UI_ZeD_Settings_HintStrip",
        sandboxInGame = "UI_ZeD_Settings_SandboxIG", dimRead = "UI_ZeD_Settings_DimRead",
        ammoBox = "UI_ZeD_Settings_AmmoBox", readMarks = "UI_ZeD_Settings_ReadMarks", readNext = "UI_ZeD_Settings_ReadNext",
        dashLamps = "UI_ZeD_Settings_DashLamps", moodleNotices = "UI_ZeD_Settings_MoodleNotices",
        loadouts = "UI_ZeD_Settings_Loadouts", additionsPreset = "UI_ZeD_Settings_Preset",
        screenWindows = "UI_ZeD_Settings_ScreenWindows", screenBelt = "UI_ZeD_Settings_ScreenBelt",
        screenWatch = "UI_ZeD_Settings_ScreenWatch", screenDashboard = "UI_ZeD_Settings_ScreenDashboard",
        screenMoodles = "UI_ZeD_Settings_ScreenMoodles", screenWheels = "UI_ZeD_Settings_ScreenWheels",
        screenCharInfo = "UI_ZeD_Settings_ScreenCharInfo", screenConsole = "UI_ZeD_Settings_ScreenConsole", beltStyle = "UI_ZeD_Settings_Belt",
        devicesStyle = "UI_ZeD_Settings_Devices", watchStyle = "UI_ZeD_Settings_WatchStyle", dashStyle = "UI_ZeD_Settings_Dash",
        guideStyle = "UI_ZeD_Settings_Guide", modsStyle = "UI_ZeD_Settings_Mods", identityStyle = "UI_ZeD_Settings_Identity",
        hiddenFacts = "UI_ZeD_Settings_HiddenFacts",
        wheelOpen = "UI_ZeD_Settings_WheelOpen", wheelCommit = "UI_ZeD_Settings_WheelCommit",
        wheelToggle = "UI_ZeD_Settings_WheelToggle", wheelDeadZone = "UI_ZeD_Settings_WheelDeadZone",
        autoLearn = "UI_ZeD_Settings_AutoLearn", runSneak = "UI_ZeD_Settings_RunSneak",
    }
    for id, key in pairs(nameKeys) do
        local o = opts.dict and opts.dict[id]
        if o then
            o.zedNameKey = key
            -- the item each option starts on (its addItem marked true above): still the default here,
            -- since ModOptions.ini is read later, when vanilla builds its options screen. ZeD setup's
            -- Defaults button and the help band's "Default:" read it
            o.zedDefault = o.selected
        end
    end
end

-- ----- THE ADDITIONS: THREE PRESETS AND CUSTOM. Every added feature can be
-- turned off, and every one starts off for a vanilla run. -----
-- The rules: picking a preset sets every addition at once; changing any addition by hand makes the preset read
-- Custom; Custom keeps the hand picks, so picking it again goes back to them; existing players keep what they have
-- saved (the preset reads the one their values match, else Custom). So the preset is never stored on its own
-- word: wherever it is read or applied it is set to what the additions' values make.
--   * ZeD setup (ZeD_MainMenuOptions) and the game's Mods page: a preset picked sets the addition controls live,
--     as a click on each would (pending until Apply, like every option); ZeD setup calls
--     ZeD.Settings.syncAdditionsPreset() every frame, and each addition's own onChange calls it too, so the preset
--     control shows the preset the live values make, or Custom.
--   * Apply (either screen): vanilla calls opts:apply() once every pick is stored, before ModOptions.ini is
--     written; the preset is set from the values there and, reading Custom, the set is kept in CUSTOM_FILE.
--   * The main menu and a game start: ZeD.Settings.reconcileAdditions() does the same with the stored values.
local function setUpAdditions()
    local OFF, ON = 1, 2
    local CUSTOM = 4
    local CUSTOM_FILE = "ZeD_custom_additions.txt"   -- (Zomboid/Lua: <option id>=<item>, a line each)
    -- every addition a preset sets, by option id (restock: 1 Hardcore, 2 Casual, 3 Accessible)
    local IDS = { "ammoBox", "readMarks", "readNext", "dimRead", "dashLamps", "moodleNotices",
                  "messagesCatch", "messagesToast", "putBack", "sandboxInGame", "loadouts", "restock", "devicesStyle", "watchStyle", "dashStyle",
                  "guideStyle", "modsStyle", "identityStyle", "haloBubble", "hiddenFacts", "autoLearn" }
    -- THE PRESETS, by the preset's item: the item each addition is set to. An id a preset leaves out is left as
    -- it is and does not count when the values are matched to a preset (Vanilla leaves Restock: it does nothing
    -- while Loadouts is off). A new addition joins by putting its id in IDS and a row in each preset,
    -- as the Full-or-simple rows did (Immersive for Vanilla Plus, Simple for Vanilla Accessible).
    local PRESETS = {
        -- 1 Vanilla: every addition off
        { ammoBox = OFF, readMarks = OFF, readNext = OFF, dimRead = OFF, dashLamps = OFF, moodleNotices = OFF,
          messagesCatch = OFF, messagesToast = OFF, putBack = OFF, sandboxInGame = OFF, loadouts = OFF, haloBubble = OFF,
          hiddenFacts = 1, autoLearn = OFF },
        -- 2 Vanilla Plus: every addition on, Restock Casual
        { ammoBox = ON, readMarks = ON, readNext = ON, dimRead = ON, dashLamps = ON, moodleNotices = ON,
          messagesCatch = ON, messagesToast = ON, putBack = ON, sandboxInGame = ON, loadouts = ON, restock = 2,
          devicesStyle = 1, watchStyle = 1, dashStyle = 1, guideStyle = 1, modsStyle = 1, identityStyle = 1, haloBubble = ON,
          hiddenFacts = 1, autoLearn = OFF },
        -- 3 Vanilla Accessible: every addition on, Restock Accessible
        { ammoBox = ON, readMarks = ON, readNext = ON, dimRead = ON, dashLamps = ON, moodleNotices = ON,
          messagesCatch = ON, messagesToast = ON, putBack = ON, sandboxInGame = ON, loadouts = ON, restock = 3,
          devicesStyle = 2, watchStyle = 2, dashStyle = 2, guideStyle = 2, modsStyle = 2, identityStyle = 2, haloBubble = ON,
          hiddenFacts = 2, autoLearn = ON },
    }
    ZeD.Settings.ADDITION_IDS = IDS
    ZeD.Settings.ADDITION_PRESETS = PRESETS

    local function opt(id) return opts.dict and opts.dict[id] end
    local function live(id) local o = opt(id); return o and liveIdx(o) end      -- the pick on the screen
    local function stored(id) local o = opt(id); return o and o:getValue() end  -- the value applied
    -- the preset the values make (read(id): an addition's item), else Custom
    local function presetOf(read)
        for i, set in ipairs(PRESETS) do
            local same = true
            for id, v in pairs(set) do
                if read(id) ~= v then same = false; break end
            end
            if same then return i end
        end
        return CUSTOM
    end

    -- the Custom set: kept in the file at Apply; held for the screen while a preset is tried over it
    local held = nil
    local function saveCustom(read)
        local ok, w = pcall(function() return getFileWriter(CUSTOM_FILE, true, false) end)
        if not (ok and w) then return end
        -- (a failed write must not stop Apply, and the writer closes either way. No temp-file swap: the game's
        -- Lua has no rename. Losing this file costs only the Custom memory: the values live in ModOptions.ini.)
        pcall(function()
            w:write("ZeD-UI: the additions' Custom set (ZeD setup, Preset); <option id>=<item>\n")
            for _, id in ipairs(IDS) do
                local v = read(id)
                if v then w:write(id .. "=" .. tostring(v) .. "\n") end
            end
        end)
        pcall(function() w:close() end)
    end
    -- nil when there is no file or it cannot be read (Custom then keeps the values as they are)
    local function loadCustom()
        local ok, r = pcall(function() return getFileReader(CUSTOM_FILE, false) end)
        if not (ok and r) then return nil end
        local out = {}
        local ok2 = pcall(function()
            local l = r:readLine()
            while l do
                local id, v = l:match("^(%w+)=(%d+)")
                if id then out[id] = tonumber(v) end
                l = r:readLine()
            end
        end)
        pcall(function() r:close() end)
        return ok2 and out or nil
    end

    -- a control changed as a click on it would: the options screen counts the change, the option's onChange runs
    -- (no screen built yet: the option itself)
    local function setLive(o, i)
        local el = o.element
        if not el then o:setValue(i); return end
        if el.disabled or el.selected == i then return end
        el.selected = i
        if el.onChange then el.onChange(el.target, el) end
    end

    local busy = false   -- (a preset being set: the additions' onChange leave the preset alone)
    --- The preset control set to the preset the live picks make, or Custom (ZeD setup calls it every
    --- frame, each addition's onChange too).
    function ZeD.Settings.syncAdditionsPreset()
        if busy then return end
        local el = additionsPreset.element
        if not el then return end
        local want = presetOf(live)
        if el.selected ~= want then el.selected = want end
    end
    for _, id in ipairs(IDS) do
        local o = opt(id)
        if o then o.onChange = function() ZeD.Settings.syncAdditionsPreset() end end
    end

    -- a preset picked: every addition it names set live; Custom: the held hand picks, else the saved set
    additionsPreset.onChange = function(_, sel)
        sel = tonumber(sel)
        if presetOf(live) == CUSTOM then
            held = {}
            for _, id in ipairs(IDS) do held[id] = live(id) end
        end
        local set = PRESETS[sel]
        if sel == CUSTOM then set = held or loadCustom() end
        if set then
            busy = true
            for _, id in ipairs(IDS) do
                local o, v = opt(id), set[id]
                if o and v and o.values and o.values[v] then pcall(setLive, o, v) end
            end
            busy = false
        end
        ZeD.Settings.syncAdditionsPreset()
    end

    -- Apply, on ZeD setup or the game's Mods page (MainOptions:apply calls each mod's options:apply())
    opts.apply = function(self)
        held = nil
        local want = presetOf(stored)
        if additionsPreset:getValue() ~= want then additionsPreset:setValue(want) end
        if want == CUSTOM then saveCustom(stored) end
    end

    -- A one-time repair: beta 6 added the Identity row with no preset line for it, so a player on Vanilla Access
    -- who ran beta 6 was moved to Custom with the Immersive card. Those values, Vanilla Access in every row but that one,
    -- go back to the preset. The file says it was done, so a later pick of Immersive stays; a new player gets the file too.
    local REPAIR_FILE = "ZeD_presetRepair.txt"
    -- the additions beta 6 had (IDS as it stood then): the repair compares these and nothing newer
    local REPAIR_IDS = { "ammoBox", "readMarks", "readNext", "dimRead", "dashLamps", "moodleNotices",
                         "messagesCatch", "messagesToast", "putBack", "sandboxInGame", "loadouts", "restock", "devicesStyle",
                         "watchStyle", "dashStyle", "guideStyle", "modsStyle", "identityStyle", "haloBubble" }
    local savedHas = {}   -- (the ids ModOptions.ini has a line for, read at file load below)
    local repairSeen = false
    local function repairVanillaAccess()
        if repairSeen then return end
        repairSeen = true
        local okR, r = pcall(function() return getFileReader(REPAIR_FILE, false) end)
        if okR and r then pcall(function() r:close() end); return end
        local okW, w = pcall(function() return getFileWriter(REPAIR_FILE, true, false) end)
        if not (okW and w) then return end      -- no mark, no repair: it must never run twice
        local wrote = pcall(function() w:write("beta 6 Identity row repaired\n"); w:close() end)
        if not wrote then return end
        if additionsPreset:getValue() ~= CUSTOM then return end
        local set = PRESETS[3]
        -- (only the rows beta 6 had are compared: an addition newer than beta 6, Hidden facts or any later one, has no
        -- saved line for that player and sits at its default, which must not stop the repair. Those newer rows the save
        -- has no line for are set to Vanilla Access with the Identity row.)
        for _, id in ipairs(REPAIR_IDS) do
            local v = set[id]
            local want = (id == "identityStyle") and 1 or v
            if v ~= nil and stored(id) ~= want then return end
        end
        local o = opt("identityStyle")
        if o then o:setValue(set.identityStyle) end
        local old = {}
        for _, id in ipairs(REPAIR_IDS) do old[id] = true end
        for id, v in pairs(set) do
            local on = opt(id)
            if on and not old[id] and not savedHas[id] then on:setValue(v) end
        end
    end

    --- The stored values read (the main menu, a game start): the preset set to what they make, and saved.
    function ZeD.Settings.reconcileAdditions()
        held = nil
        pcall(repairVanillaAccess)
        local want = presetOf(stored)
        if additionsPreset:getValue() == want then return end
        additionsPreset:setValue(want)
        if want == CUSTOM then saveCustom(stored) end
        saveModOptions()
    end
    -- the options window's discard: the hand picks held for Custom go with the rest
    function ZeD.Settings.forgetHeldCustom() held = nil end

    -- A player who had ZeD before the additions' switches has ZeD's lines in ModOptions.ini. An addition that
    -- was on for them with no line of its own (Loadouts had no switch; a switch newer than their last save)
    -- starts on, as they had it: existing players keep their saved settings. Read here, at file load, before the game reads the
    -- file into the options (a saved line still wins) and after the defaults above were noted.
    local WAS_ON = { "ammoBox", "readMarks", "readNext", "dashLamps", "moodleNotices", "messagesCatch", "messagesToast", "loadouts" }
    local ok, r = pcall(function() return getFileReader("ModOptions.ini", false) end)
    if ok and r then
        local had, has, val = false, {}, {}
        pcall(function()
            local l = r:readLine()
            while l do
                local id, v = l:match("|ZeD_UI|([%w_]+)|(%d*)")
                if id then had = true; has[id] = true; val[id] = tonumber(v) end
                l = r:readLine()
            end
        end)
        pcall(function() r:close() end)
        savedHas = has
        if had then
            for _, id in ipairs(WAS_ON) do
                local o = opt(id)
                if o and not has[id] then o:setValue(ON) end
            end
            -- (the Full or simple rows joined the presets after the first players had saves. A player on Vanilla
            -- Access, preset item 3, from before them gets them Simple, as the preset asks, instead of the preset
            -- reading Custom. The Identity row joined in beta 6, and Hidden facts after beta 7.)
            if val.additionsPreset == 3 then
                -- (Recipes skills teach joined the presets after the rest: item 2 is On)
                for _, id in ipairs({ "devicesStyle", "watchStyle", "dashStyle", "identityStyle", "hiddenFacts", "autoLearn" }) do
                    local o = opt(id)
                    if o and not has[id] then o:setValue(2) end
                end
            end
        end
    end
end
setUpAdditions()

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
    local accent = (accentIdx and accentKeys[accentIdx]) or ZeD.DEFAULT_ACCENT
    local size   = sizeKeys[sizeIdx or 1]     or "small"

    -- the see-through value goes in with the theme: applyTheme sets the surfaces' alpha from it,
    -- before the text colours are solved against them (the windows' own palettes follow)
    local seeIdx = (changed == seeThrough and tonumber(sel)) or (changed and pickedIdx(seeThrough)) or seeThrough:getValue()
    local see = (seeKeys[seeIdx or 2] or 90) / 100
    if see ~= ZeD.surfaceAlpha and ZeD_Window and ZeD_Window.clearPaletteCache then ZeD_Window.clearPaletteCache() end
    -- (the player's own pick: applyTheme keeps it aside and draws solid outside Dark, ZeD.seeThroughWorks)
    ZeD._seeForced = nil
    ZeD.surfaceAlpha = see
    -- the status colors too: the windows' own palettes solve their status text shades from them
    local stIdx = (changed == statusColors and tonumber(sel)) or (changed and pickedIdx(statusColors)) or statusColors:getValue()
    local status = statusKeys[stIdx or 1] or "standard"
    if status ~= ZeD.currentStatus and ZeD_Window and ZeD_Window.clearPaletteCache then ZeD_Window.clearPaletteCache() end
    ZeD.currentStatus = status

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
seeThrough.onChange       = onThemeChange
seeThrough.onChangeApply  = onThemeApply
statusColors.onChange      = onThemeChange
statusColors.onChangeApply = onThemeApply

--- The window box's menu and the Select wheel set these as ZeD setup does, and save at once
--- (no Apply there): see-through re-applies the theme with the new alpha
function ZeD.Settings.setSeeThrough(i)
    i = tonumber(i)
    if not (i and seeKeys[i]) then return end
    seeThrough:setValue(i)
    applyFromOptions()
    saveModOptions()
end
function ZeD.Settings.setSolidInUse(on)
    solidInUse:setValue(on and 2 or 1)
    saveModOptions()
end
function ZeD.Settings.setHealthBlink(on)
    healthBlink:setValue(on and 2 or 1)
    saveModOptions()
end
function ZeD.Settings.setFocusStyle(key)
    for i, k in ipairs(focusKeys) do
        if k == key then focusStyle:setValue(i); saveModOptions(); return end
    end
end

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

-- Glyph display: a copy of the pick kept on the character. Nothing reads the
-- copy back; ZeD_PadGlyphs reads the option itself (glyphKey, above).
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

--- Sync a single window's accent to ModOptions + modData (the window box menu
--- and the windows' own accent pick-up call it).
--- A window with no accent key of its own follows the Accent color option.
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
    ZeD.Settings.forgetHeldCustom()   -- (the additions' hand picks held for Custom go with the discard)
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
    ZeD.Settings.reconcileAdditions()   -- the additions' preset set to what the saved values make
end)

-- The main menu draws ZeD windows before any save loads: apply
-- the mod options there too. Vanilla's own OnMainMenuEnter handler builds the
-- options screen first, which loads the saved mod options.
Events.OnMainMenuEnter.Add(function()
    hookOptionsDiscard()
    applyScale()
    applyFromOptions()
    ZeD.Settings.reconcileAdditions()
end)

-- ---------------------------------------------------------------------------
-- CYCLING HELPER
-- The next entry of a list, wrapping at the end. The F-key shortcuts that
-- used it are gone: theme, accent and size cycle through the window box menu
-- and the controller's wheels instead. Nothing in ZeD calls it now; it stays
-- on ZeD.Settings for anything outside that still might.
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
