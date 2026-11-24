-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuOptionGroups.lua
-- ============================================================================
-- OPTIONS, GROUPED LIKE A MODERN GAME. Client-side; the Options window's
-- grouping model: data tables and the build that files vanilla's rows into them.
--
-- Vanilla's eight pages (Display & Performance, UI, Audio, Key Bindings,
-- Accessibility, Controller, Multiplayer, Mods) mix kinds: the UI page holds the
-- camera and the aiming reticle, Accessibility holds auto-drink and the radial
-- menu. ZeD's Options window still READS vanilla's pages (ZeD_MainMenuOptions);
-- this file only re-files the rows it finds into groups and sections, by each
-- option's own name (GameOption.name), and marks:
--   * moot: does nothing with ZeD active (greyed, inert, the reason under it)
--   * only: still works, with a note on where or how ("Multiplayer only", "Item and ZeD tooltips")
-- and builds ZeD setup: ZeD's own options and the game settings ZeD's look
-- depends on, the same controls (one value, two places to reach it).
-- (Nov 15 2026, add-on hooks) An add-on's own options can join ZeD setup as a
-- group of their own: ZeD.Options.addGroup, shared/ZeD/AddonOptions.lua.
--
-- An option this table doesn't name (a new vanilla option, a mod's control on
-- a vanilla page) lands in its old page's group under "Other": nothing is lost.
-- ============================================================================

ZeD = ZeD or {}
ZeD.MainMenu = ZeD.MainMenu or {}
local MM = ZeD.MainMenu
local G = {}
MM.optionGroups = G

-- vanilla's pages, by their titles
local function pageId(raw)
    local ids = {
        display = "UI_optionscreen_display", ui = "UI_optionscreen_UI", audio = "UI_optionscreen_audio",
        keys = "UI_optionscreen_keybinding", access = "UI_optionscreen_accessibility",
        controller = "UI_optionscreen_controller", mp = "UI_optionscreen_multiplayer", mods = "UI_mainscreen_mods",
    }
    for id, key in pairs(ids) do if raw == getText(key) then return id end end
    return nil
end
G.pageId = pageId

--- The words in the tables below are translation keys, turned into the player's language where
--- they show (G.text): ZeD's own (UI_ZeD_...) through ZeD.tr, the game's own words (UI_optionscreen_audio,
--- UI_DisplayOptions_Camera...) through getText, all-caps ones in sentence case. Anything else, such as
--- words a window has already put into the player's language, passes through as it is.
function G.text(s)
    if type(s) ~= "string" or s == "" then return s end
    if s:sub(1, 7) == "UI_ZeD_" then return ZeD.tr(s) end
    if not s:find(" ", 1, true) and s:find("^%a+_%w[%w_]*$") then
        local t = getTextOrNull(s)
        if t then return ZeD.btnCase(t) end
    end
    return s
end

-- the groups, in order; each section lists vanilla option names, or takes a
-- whole page's rows (from = "keys" | "controller" | "mods")
G.GROUPS = {
    { id = "zed", title = "UI_ZeD_Options_GroupZed", setup = true },
    { id = "display", title = "UI_ZeD_Options_GroupDisplay", sections = {
        { "UI_ZeD_Options_SecScreen", { "displayMode", "fullscreen", "borderless", "resolution", "framerate", "vsync", "focusloss", "lockCursorToWindow" } },
    } },
    { id = "graphics", title = "UI_ZeD_Options_GroupGraphics", sections = {
        { "UI_DisplayOptions_Textures", { "texcompress", "maxTextureSize", "maxVehicleTextureSize", "simpleClothingTex", "simpleWeaponTex",
                        "highResPlacedItems", "perf_3Ditems" } },
        { "Sandbox_WorldOptions", { "lightingFPS", "fogQuality", "waterQuality", "perf_puddles", "puddlesQuality", "precipOption",
                     "precipitationSpeedMultiplier", "perf_reflections", "perf_skybox", "bloodDecals", "corpseShadows" } },
        { "UI_ZeD_Options_SecEffects", { "screenFilter", "doVideoEffects", "doWindSpriteEffects", "doDoorSpriteEffects", "viewConeOpacity",
                       "searchModeOverlayEffect", "usePhysicsHitReaction", "maxActiveRagdolls", "zombieUpdateOpt" } },
    } },
    { id = "audio", title = "UI_optionscreen_binding_Audio", sections = {
        { "IGUI_RadioVolume", { "soundVolume", "musicVolume", "jumpscareVolume", "vehicleEngineVolume" } },
        { "GameSound_Category_Music", { "musicLibrary", "__audioButton", "musicActionStyle" } },   -- (__audioButton: the library's Reload)
        { "UI_ZeD_Options_SecVoice", { "voiceEnable", "voiceRecordDevice", "voiceMode", "voiceVADMode", "voiceAGCMode", "voiceVolumeMic",
                          "voiceVolumePlayers" } },
        { "UI_ZeD_Options_SecStreaming", { "streamerMode" } },
    } },
    { id = "controls", title = "UI_ZeD_Options_GroupControls", sections = {
        { "SurvivalGuide_movement_title", { "toggleToRun", "dblTapRunToSprint", "toggleToSprint", "toggleToAim", "autoProneAtk" } },
        { "UI_ZeD_Options_SecMenus", { "radialMenuKeyToggle", "reloadRadialInstant", "enableLeftJoystickRadialMenu", "singleContextMenu",
                     "cycleContainerKey", "shoulderButtonContainerSwitch" } },
        { "UI_ZeD_Options_SecMouse", { "ignoreMouseWheelAcceleration", "mapHorizontalMouseWheelToVertical" } },
        { "UI_optionscreen_controller", from = "controller" },
        { "UI_optionscreen_keybinding", from = "keys" },
    } },
    { id = "gameplay", title = "UI_optionscreen_game", sections = {
        { "UI_DisplayOptions_Camera", { "zoom", "zoomLevels", "autoZoom", "panCameraWhileAiming", "panCameraWhileDriving" } },
        { "IGUI_perks_Aiming", { "reticleMode", "showAimTexture", "aimTexture", "showReticleTexture", "reticleTexture",
                      "showValidTargetReticleTexture", "validTargetReticleTexture", "targetColor", "noTargetColor",
                      "crosshairTexture", "maxCrosshairOffset", "reticleCameraZoom" } },
        { "UI_DisplayOptions_Cursor", { "iso_cursor", "showCursorWhileAiming", "meleeOutline" } },
        { "UI_ZeD_Options_SecOnItsOwn", { "autoDrink", "keyInIgnition", "autoWalkContainer", "timedActionGameSpeedReset", "mapViewPause",
                          "dropItemsOnSquareCenter", "autoRevealPrintMediaMapLocations" } },
        { "IGUI_Gametime_Multiplayer", { "showUsername", "mpTextColor", "populateServerListOnStart" } },
    } },
    { id = "interface", title = "UI_ZeD_Options_GroupInterface", sections = {
        { "UI_ZeD_Options_SecText", { "fontSize", "contextMenuFont", "inventoryFont", "tooltipFont" } },
        { "UI_ZeD_Options_SecHud", { "moodleSize", "sidebarSize", "inventoryContainerSize", "actionProgressBarSize" } },
        { "UI_DisplayOptions_Clock", { "clockFormat", "clockSize", "clock24hour", "temperatureDisplay" } },
        { "UI_ZeD_Options_SecHighlights", { "doContainerOutline", "objHighColor", "worldItemHighlightColor" } },
        { "UI_btn_help", { "showCraftingXP", "showItemModInfo", "showSurvivalGuide" } },
        { "UI_ZeD_Options_SecRendering", { "UIFBO", "UIRenderFPS" } },
        { "UI_DisplayOptions_Language", { "language", "comlang" } },
    } },
    { id = "access", title = "UI_optionscreen_accessibility", sections = {
        { "UI_ZeD_Options_SecColors", { "goodHighColor", "badHighColor", "colorblindPatterns" } },
        { "UI_ZeD_Options_SecReading", { "enableDyslexicFont" } },
        { "SurvivalGuide_weather_title", { "disableLightningDuringStorms" } },
    } },
    { id = "mods", title = "UI_mainscreen_mods", sections = { { nil, from = "mods" } } },
}

-- where an option the table doesn't name goes: its old page's group
local FALLBACK = { display = "graphics", ui = "interface", audio = "audio", keys = "controls", access = "gameplay",
                   mp = "gameplay", controller = "controls", mods = "mods" }

-- Settings that do nothing with ZeD active: greyed, inert, the reason in the
-- row and the help band. Each one sets a vanilla surface ZeD replaces, and no
-- ZeD code reads it (no getOption* call names it).
G.MOOT = {
    inventoryFont = "UI_ZeD_Options_MootInventoryFont",
    contextMenuFont = "UI_ZeD_Options_MootContextMenuFont",
    inventoryContainerSize = "UI_ZeD_Options_MootContainerSize",
    clockSize = "UI_ZeD_Options_MootClockSize",
    clockFormat = "UI_ZeD_Options_MootClockFormat",
    showCraftingXP = "UI_ZeD_Options_MootCraftingXP",
    shoulderButtonContainerSwitch = "UI_ZeD_Options_MootShoulderButtons",
    cycleContainerKey = "UI_ZeD_Options_MootCycleContainer",
}
-- Still working, but only somewhere: { the line under its name, the help band's words }
-- (the Dyslexic font replaces ZeD's text fonts with the game's own dyslexic ones, and
-- the Tooltip font sizes ZeD's tooltips as well as the item tooltip's facts)
G.ONLY = {
    enableDyslexicFont = { "UI_ZeD_Options_OnlyDyslexic", "UI_ZeD_Options_OnlyDyslexicHelp" },
    sidebarSize = { "UI_ZeD_Options_OnlySidebar", "UI_ZeD_Options_OnlySidebarHelp" },
    tooltipFont = { "UI_ZeD_Options_OnlyTooltip", "UI_ZeD_Options_OnlyTooltipHelp" },
}

-- ZeD setup: the game settings ZeD's look depends on: { name, its group, its section, why ZeD uses it }
-- (the group and section are translation keys, shown as "Also in <group> | <section>")
-- (QA's visual noise audit, ZeD setup, Nov 20 2026: Font size, Tooltip font, Moodle size, 24-hour clock, Temperature
-- and Video effects were one control in two places in one window. The mirrors are dropped: each lives on its own
-- page, and Find reaches it there. The list is empty, so the build below adds no copies.)
G.SETUP_GAME = {}

-- ZeD setup: ZeD's own options in groups, each with the control it is drawn with.
-- The value is still the combo's item (ModOptions saves that number), so a saved choice keeps
-- its meaning; only the drawing changes (ZeD_MainMenuOptions' drawControl). The controls are
-- System 7's: a radio button for one of a few, a pop-up menu for one of many, a checkbox
-- for on or off.
--   "radio"  radio buttons in a row, the pick filled (two or three choices)
--   "swatch" the nine accents as colour wells; the window accents add "Same as Accent"
--   "scale"  a stepped slider: Auto at the left, then the fixed sizes (See-through: 100 to 60)
--   "onoff"  a checkbox (item 1 Off, item 2 On)
--   nil      the pop-up menu (a long list of names)
-- A control too wide for the space (a long translation, the test language) is drawn as the drop-down.
-- { group title, { { option id, style, danger = , under = the line under its name,
--   short = shorter words for a switch's choices or the slider's steps, by item (the drop-down
--   on the Mods page keeps the full ones) } } }
-- An option of ZeD's this table doesn't name (a new one) lands under Other, as a drop-down.
-- (beta 21) the switches Style replaced, never shown; the groups Lite leaves out (the director: "If vanilla does it,
-- so does Lite"; the additions and the chords are ZeD's own, set as Lite has them)
G.RETIRED = { "beltStyle", "devicesStyle", "watchStyle", "dashStyle", "guideStyle", "identityStyle", "modsStyle", "actionBar" }
G.LITE_HIDES = { UI_ZeD_Options_ZedAdditions = true, UI_ZeD_Options_ZedChords = true }
G.ZED_GROUPS = {
    -- (the windows' See-through is the stepped slider under Text size, Solid while in use a
    -- checkbox under it; Controller highlight leads Controls as a pop-up menu with a live sample
    -- beside it; Hidden actions closes Windows as a pop-up menu. No row for theme squares: the
    -- windows have none, and each window box's menu, ZeD_WindowMenu.lua, holds Theme, Accent
    -- and Text size.)
    -- (QA's visual noise audit, ZeD setup, Nov 20 2026: the page went from about 68 rows to about 45. Map light moved
    -- to the Maps tab's own switch; Solid while in use is the rule now, the low-health pixel holds solid red and the
    -- item-colored tiles follow Style, so their three rows went; Status colors stays until the bars and checks read
    -- the game's own Accessibility colors, since it is the only way to the color-blind set. G.SETUP_HIDDEN below.)
    { "UI_ZeD_Options_ZedLook", { { "lookStyle", "radio" }, { "baseTheme", "radio" }, { "accentColor", "swatch" }, { "statusColors", "radio" }, { "textSize", "radio" }, { "seeThrough", "scale" }, { "uiScale", "scale", short = { "UI_ZeD_Settings_Auto" } } } },
    -- (One row per family, each offering ZeD's full vision or a plainer one, with one phrase for
    -- the two forms: Immersive or simple, for the rows drawn as the thing itself or as a plain
    -- card, the Identity card (once in Look) among them. The Action bar (in HUD) and the Mods
    -- screen (in Windows) are Detailed or simple; Context menu and Equipped items choose a
    -- layout, so they sit in Windows by Inventory. A row can move between groups freely: every
    -- option keeps its items in order, so saved choices keep their meaning.)
    -- (everything vanilla does not do, in one group after the look, the preset first; the
    -- presets' table is in Settings.lua's setUpAdditions. Put back, Messages and Sandbox in game
    -- have no groups of their own; Ammo on the belt, Moodle notices and Dashboard lamps (once in
    -- HUD) and the read marks (once in Windows) live here too. An add-on's switches join this group with
    -- ZeD.Options.addRows: the add-on ZeD-GUI: Loadouts puts Loadouts and outfits, and Restock, after Hidden facts.)
    { "UI_ZeD_Options_ZedAdditions", { { "additionsPreset", "radio", short = { "UI_ZeD_Settings_PresetVanilla", "UI_ZeD_Options_PresetPlus", "UI_ZeD_Options_PresetAccessible", "Sandbox_Custom" } },
        -- (QA's visual noise audit, Nov 20 2026: Read marks, Next level on skill books and Dim read items are one
        -- three-way row; Keep notes in Messages and its toast one; Hidden facts takes Recipes skills teach. Each such
        -- row works the options under it, G.MERGED below.)
        { "ammoBox", "onoff" }, { "readMarks", "radio", merge = "readMarks" }, { "dashLamps", "onoff" },
        { "moodleNotices", "onoff" }, { "messagesCatch", "radio", merge = "messages" }, { "haloBubble", "onoff" }, { "hintStrip", "radio" }, { "putBack", "onoff" },
        { "sandboxInGame", "onoff", under = "UI_ZeD_Options_UnderSandboxIG" }, { "hiddenFacts", "radio", merge = "hiddenFacts" },
        -- (a row with showIf = another option's id is hidden while that one is off. The audit: hiding is quieter
        -- than the dimmed row with its reason line.)
        -- (Nov 15 2026, appliances: Additional appliance support, Appliances.lua)
        { "appliances", "onoff" } } },
    -- (the audit: Inventory has the view button in every column header, Equipped items the Equip tab's own switch,
    -- the window accents each window's menu; Hidden actions has one-word choices, the help band explains them)
    { "UI_ZeD_Options_ZedWindows", { { "contextStyle", "radio" }, { "wornInList", "radio" }, { "uiSounds", "radio" }, { "hiddenActions", "radio" } } },
    -- (Lite's clock is always in the corner: the Watch row shows in Full only)
    { "UI_ZeD_Options_ZedHud", { { "moodlePlace", "radio", short = { "UI_ZeD_Options_MoodlesRight", "UI_ZeD_Options_MoodlesLeft", "UI_ZeD_Options_MoodlesBottom" } }, { "watchPlace", "radio", fullOnly = true } } },
    -- (the button pictures: Auto, which follows the game's own controller button style, or Letters; how the wheels are
    -- worked, one pop-up for open, commit and toggle mode; then the Run button that also crouches, Input/RunSneak.lua)
    { "UI_ZeD_Options_ZedControls", { { "focusStyle" }, { "glyphDisplay", "radio", merge = "glyphs" },
        { "wheelOpen", nil, merge = "wheels" }, { "wheelDeadZone", "scale" }, { "runSneak", "onoff" } } },
    -- (the twelve chords, ZeD_QuickChords; not ModOptions: rows of their own)
    { "UI_ZeD_Options_ZedChords", {}, chords = true },
    -- (the eight screens a player can give back (the game's error box the eighth, Nov 22 2026) are one row of check boxes under Safe mode, the sentence they shared
    -- said once in the help: ticked, that screen is the game's own. Playing with (the input mode lock) moved here from
    -- Controls; the Lua console's switch and the test language show in debug mode only.)
    { "UI_ZeD_Options_ZedTrouble", { { "safeMode", "onoff", under = "UI_ZeD_Options_UnderSafeMode" },
                                     { "screenWindows", nil, merge = "screens" },
                                     { "inputModeLock", "radio", short = { "UI_ZeD_Settings_Auto", "UI_ZeD_Welcome_MouseKeys", "UI_ZeD_Welcome_Controller" } },
                                     { "screenConsole", "onoff", under = "UI_ZeD_Options_UnderScreenConsole", debugOnly = true },
                                     { "testLanguage", "onoff", debugOnly = true } } },
}

-- (QA's visual noise audit, Nov 20 2026) ZeD's options that keep working but have no row on ZeD setup: kept and saved
-- as before (QA's runners and the Mods page still set them), never under Other. The ones a merged row works are here
-- too. ZeD setup's Defaults still puts each back.
G.SETUP_HIDDEN = { "mapLight", "solidInUse", "healthBlink", "gridTint", "inventoryView", "equipView", "charAccent", "worldAccent",
                   "readNext", "dimRead", "messagesToast", "autoLearn", "wheelCommit", "wheelToggle",
                   "screenBelt", "screenWatch", "screenDashboard", "screenMoodles", "screenWheels", "screenCharInfo", "screenErrorBox" }

-- (QA's visual noise audit, Nov 20 2026) One row on ZeD setup that reads and writes several options. Not an option of
-- its own: what it shows is read from the options under it each time, and a pick sets each of them as a click on its
-- own control would (counted for Apply, its onChange run).
--   ids    the options it works
--   items  { the choice's words (a translation key), { [option id] = the item it sets } }
--   read   the choice the options' live picks make (v: option id -> item)
--   ticks  instead of items: a row of check boxes, { option id, its words }; ticked = item 2
G.MERGED = {
    readMarks = { name = "UI_ZeD_Settings_ReadMarks", tip = "UI_ZeD_Options_ReadTrioTip", ids = { "readMarks", "readNext", "dimRead" },
        items = { { "UI_Off", { readMarks = 1, readNext = 1, dimRead = 1 } },
                  { "UI_ZeD_Options_ReadMarksOnly", { readMarks = 2, readNext = 2, dimRead = 1 } },
                  { "UI_ZeD_Options_ReadMarksDim", { readMarks = 2, readNext = 2, dimRead = 2 } } },
        read = function(v)
            if v.readMarks ~= 2 and v.readNext ~= 2 and v.dimRead ~= 2 then return 1 end
            return (v.dimRead == 2) and 3 or 2
        end },
    messages = { name = "UI_ZeD_Options_MsgNotes", tip = "UI_ZeD_Options_MsgNotesTip", ids = { "messagesCatch", "messagesToast" },
        items = { { "UI_ZeD_Options_MsgAsGame", { messagesCatch = 1, messagesToast = 1 } },
                  { "UI_ZeD_Options_MsgKeep", { messagesCatch = 2, messagesToast = 1 } },
                  { "UI_ZeD_Options_MsgKeepToast", { messagesCatch = 2, messagesToast = 2 } } },
        read = function(v)
            if v.messagesCatch ~= 2 then return 1 end
            return (v.messagesToast == 2) and 3 or 2
        end },
    hiddenFacts = { name = "UI_ZeD_Settings_HiddenFacts", tip = "UI_ZeD_Options_HiddenFactsTip", ids = { "hiddenFacts", "autoLearn" },
        items = { { "UI_ZeD_Settings_FindFirst", { hiddenFacts = 1, autoLearn = 1 } },
                  { "UI_ZeD_Hidden_Always", { hiddenFacts = 2, autoLearn = 2 } } },
        read = function(v) return (v.hiddenFacts == 2) and 2 or 1 end },
    -- (the game's controller button style picks the pictures; ZeD's own sets stay saved, a player on one sees Auto)
    glyphs = { name = "UI_ZeD_Settings_Glyphs", tip = "UI_ZeD_Options_GlyphsTip", ids = { "glyphDisplay" },
        items = { { "UI_ZeD_Settings_Auto", { glyphDisplay = 1 } },
                  { "UI_ZeD_Options_GlyphLetters", { glyphDisplay = 6 } } },
        read = function(v) return (v.glyphDisplay == 6 or v.glyphDisplay == 7) and 2 or 1 end },
    -- (Toggle mode overrode the other two, which is why they dimmed; Hold with a stick click, never offered here, reads
    -- as Hold and flick)
    wheels = { name = "UI_ZeD_Options_Wheels", tip = "UI_ZeD_Options_WheelsTip", ids = { "wheelOpen", "wheelCommit", "wheelToggle" },
        items = { { "UI_ZeD_Options_WheelHoldFlick", { wheelOpen = 2, wheelCommit = 1, wheelToggle = 1 } },
                  { "UI_ZeD_Options_WheelTapFlick", { wheelOpen = 1, wheelCommit = 1, wheelToggle = 1 } },
                  { "UI_ZeD_Options_WheelTapClick", { wheelOpen = 1, wheelCommit = 2, wheelToggle = 1 } },
                  { "UI_ZeD_Options_WheelToggle", { wheelToggle = 2 } } },
        read = function(v)
            if v.wheelToggle == 2 then return 4 end
            if v.wheelOpen == 2 then return 1 end
            return (v.wheelCommit == 2) and 3 or 2
        end },
    screens = { name = "UI_ZeD_Options_GiveBack", tip = "UI_ZeD_Options_GiveBackTip",
        ticks = { { "screenWindows", "UI_ZeD_Options_GiveWindows", "windows" }, { "screenBelt", "UI_ZeD_Options_GiveBelt", "belt" },
                  { "screenWatch", "UI_ZeD_Options_GiveWatch" }, { "screenDashboard", "UI_ZeD_Options_GiveDashboard", "dashboard" },
                  { "screenMoodles", "UI_ZeD_Options_GiveMoodles" }, { "screenWheels", "UI_ZeD_Options_GiveWheels", "wheels" },
                  { "screenCharInfo", "UI_ZeD_Options_GiveCharInfo", "charinfo" },
                  -- (the game's red error box back: Error box, the director, Nov 22 2026)
                  { "screenErrorBox", "UI_ZeD_Options_GiveErrorBox" } } },
}

-- a ZeD option's live pick (on the screen, Apply or not), else its stored value
local function liveOf(zo, id)
    local o = zo and zo.dict and zo.dict[id]
    if not o then return nil end
    local el = o.element
    local v = el and el.selected
    if v == nil then
        local ok, s = pcall(o.getValue, o)
        v = ok and s or nil
    end
    return v
end
-- an option's control set to item i as a click on it would (ZeD_MainMenuOptions' setCombo): counted for Apply, its
-- onChange run; with no control built yet, the option itself
local function setLiveOf(zo, id, i)
    local o = zo and zo.dict and zo.dict[id]
    if not o then return end
    local el = o.element
    if not el then pcall(o.setValue, o, i); return end
    if el.disabled or el.selected == i then return end
    el.selected = i
    if el.onChange then el.onChange(el.target, el, el.onChangeArgs and el.onChangeArgs[1], el.onChangeArgs and el.onChangeArgs[2]) end
end
G.liveOf = liveOf

--- A merged row's control, d a G.MERGED entry: a stand-in for a drop-down (or a row of tick boxes) that the options
--- window draws and steps as it does any other. Its pick is never kept on it: `selected` is read from the options each
--- time and a pick written to them (a metatable, so nothing stale is ever drawn).
local function mergedControl(key, d, zo)
    local c = { ID = "zedmerge:" .. key, options = {}, zedMerged = key }
    if d.ticks then
        for i, t in ipairs(d.ticks) do c.options[i] = ZeD.tr(t[2]) end
        c.selected = setmetatable({}, {
            __index = function(_, i)
                local t = d.ticks[tonumber(i) or 0]
                return (t ~= nil) and liveOf(zo, t[1]) == 2
            end,
            __newindex = function(_, i, on)
                local t = d.ticks[tonumber(i) or 0]
                if t then setLiveOf(zo, t[1], on and 2 or 1) end
            end })
        -- (Defaults: every one ZeD's again)
        c.zedOffDefault = function()
            for _, t in ipairs(d.ticks) do if liveOf(zo, t[1]) == 2 then return true end end
            return false
        end
        c.zedResetDefault = function() for _, t in ipairs(d.ticks) do setLiveOf(zo, t[1], 1) end end
        return c
    end
    for i, it in ipairs(d.items) do c.options[i] = it[1] end
    c.getOptionText = function(_, i)
        local it = d.items[tonumber(i) or 0]
        return it and ZeD.tr(it[1]) or ""
    end
    setmetatable(c, {
        __index = function(_, k)
            if k ~= "selected" then return nil end
            local v = {}
            for _, id in ipairs(d.ids) do v[id] = liveOf(zo, id) end
            return d.read(v)
        end,
        __newindex = function(t, k, i)
            if k ~= "selected" then rawset(t, k, i); return end
            local it = d.items[tonumber(i) or 0]
            if not it then return end
            for _, id in ipairs(d.ids) do
                local want = it[2][id]
                if want then setLiveOf(zo, id, want) end
            end
        end })
    return c
end

--- A ZeD group's rows with an add-on's spliced in (ZeD.Options.addRows: after the row its afterRow names, else at
--- the group's end). An add-on's row of another owner comes as a copy carrying _owner; ZeD_UI's as it is.
function G.groupRows(grp)
    local adds = ZeD.Options and ZeD.Options.rowAdds
    if not (adds and #adds > 0) then return grp[2] end
    local mine = {}
    for _, a in ipairs(adds) do if a.into == grp[1] then mine[#mine + 1] = a end end
    if #mine == 0 then return grp[2] end
    local function put(out, a)
        for _, r in ipairs(a.rows) do
            if a.owner == "ZeD_UI" then out[#out + 1] = r
            else
                local c = {}
                for k, v in pairs(r) do c[k] = v end
                c._owner = a.owner
                out[#out + 1] = c
            end
        end
    end
    local out, done = {}, {}
    for _, e in ipairs(grp[2]) do
        out[#out + 1] = e
        for i, a in ipairs(mine) do
            if not done[i] and a.afterRow == e[1] then put(out, a); done[i] = true end
        end
    end
    for i, a in ipairs(mine) do if not done[i] then put(out, a) end end
    return out
end

--- What the setup page's rows depend on besides the options' own values: Style (Lite leaves out groups and rows),
--- the live pick of every option a row's showIf names (ZeD's rows, an add-on's rows and groups: such a row shows
--- only while that one is on) and debug mode. ZeD_MainMenuOptions builds again when it changes.
function G.stateKey()
    local lite = ZeD.Settings and ZeD.Settings.lite and ZeD.Settings.lite()
    local MO = PZAPI and PZAPI.ModOptions
    local dbg = isDebugEnabled and isDebugEnabled()
    local parts = {}
    local function add(owner, e)
        if e.showIf then
            local zo = MO and MO:getOptions(e._owner or owner)
            parts[#parts + 1] = tostring(liveOf(zo, e.showIf))
        end
    end
    for _, grp in ipairs(G.ZED_GROUPS) do
        for _, e in ipairs(G.groupRows(grp)) do add("ZeD_UI", e) end
    end
    for _, a in ipairs(ZeD.Options and ZeD.Options.groups or {}) do
        for _, e in ipairs(a.rows) do add(a.owner, e) end
    end
    return tostring(lite) .. ":" .. table.concat(parts, ",") .. ":" .. tostring(dbg)
end

-- a shallow copy carrying a note under its name (ZeD setup's copies; the
-- original row stays as it is in its own group)
local function copyRow(r, under, why)
    local c = {}
    for k, v in pairs(r) do c[k] = v end
    c.under = under
    c.why = why
    c.only = nil
    c.setupCopy = true
    return c
end

-- a ZeD setup copy takes its drawing from its G.ZED_GROUPS entry e (or an add-on's row, which has
-- the same shape): the control, the line under it, the shorter words, what it needs
local function styleRow(c, e)
    c.zedStyle, c.under, c.zedShort = e[2], e.under, e.short
    c.zedNeeds, c.zedNeedsWhy, c.zedNeedsNot = e.needs, e.needsWhy, e.needsNot
    c.zedBack = e.back   -- (a ZeD screen a mod can take: ZeD_StepAside.lua names it under the switch)
end

-- ----------------------------------------------------------------------------
-- AN ADD-ON'S GROUP (Nov 15 2026, add-on hooks: ZeD.Options.addGroup, in
-- shared/ZeD/AddonOptions.lua, keeps the list; this turns one entry into rows)
-- ----------------------------------------------------------------------------

-- an option's tooltip as vanilla would show it: a translation key read in the player's
-- language, plain words as they are (getTextOrNull answers nil for words that are no key)
local function tipText(tt)
    if type(tt) ~= "string" or tt == "" then return nil end
    local t = getTextOrNull and getTextOrNull(tt)
    return t or tt
end

--- The ZeD setup rows for one add-on group a (ZeD.Options.groups' entry), from the Mods page's
--- rows (mods), built exactly as ZeD's own: the Mods page row is marked as ZeD's own (Find shows
--- it on ZeD setup only), and a copy takes the group's drawing. An owner or option ZeD cannot
--- find is logged once and left out.
local function addonRows(a, mods)
    local AO = ZeD.Options
    local list = {}
    -- (the colon call: getOptions is a method of PZAPI.ModOptions, as ZeD's own lookup above uses it)
    local zo = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions(a.owner)
    if not zo then
        AO.logOnce("owner:" .. a.owner, "no ModOptions with the id " .. a.owner .. ": its group on ZeD setup is left out")
        return list
    end
    local seen = {}   -- option id -> true once placed (a row named twice shows once)
    for _, e in ipairs(a.rows) do
        local id = e[1]
        local opt = zo.dict and zo.dict[id]
        if e.showIf and liveOf(zo, e.showIf) ~= 2 then
            -- (showIf: hidden while that switch of the add-on's is off; the page rebuilds when it flips, G.stateKey)
        elseif not opt then
            AO.logOnce("option:" .. a.owner .. ":" .. id, a.owner .. " has no option " .. id .. ": its row on ZeD setup is skipped")
        elseif opt.element and not seen[id] then
            -- (no element yet: vanilla has not built the Mods page; ZeD's own rows wait the same way)
            for _, r in ipairs(mods) do
                if r.control == opt.element then
                    -- the name: the add-on's key through ZeD.tr each frame, else the Mods page's words (r.label)
                    r.labelKey = e.nameKey
                    -- the help: the add-on's key through ZeD.tr, else the option's own tooltip (vanilla
                    -- never hands a mod's drop-down its tooltip, so the band would read nothing)
                    r.zedTipKey = e.tipKey
                    r.zedTip = (not e.tipKey) and tipText(opt.tooltip) or nil
                    r.zedOwn = true      -- (Find shows it on ZeD setup, not twice: G.findRows)
                    r.zedOwner = a.owner -- (whose options its needs = name: ZeD_MainMenuOptions' needsOff)
                    local c = copyRow(r, nil)
                    -- Reset to defaults: only a combo's item can be put back (ZeD_MMOptions:zedDefaults)
                    if opt.type == "combobox" then
                        local MO = ZeD.ModOptionsOwners
                        c.zedDefault = e.default or (MO and MO.default and MO.default(a.owner, id)) or nil
                        styleRow(c, e)
                    end
                    c.zedBack = nil   -- (screens a mod can take are ZeD's own; an add-on row names none)
                    list[#list + 1] = c
                    seen[id] = true
                end
            end
        end
    end
    return list
end

--- Build every group's rows. pages = vanilla's pages ({ title, raw, view, keys });
--- rowsOf(page) = that page's rows (ZeD_MainMenuOptions' discovery, cached).
--- Returns { [groupId] = rows }.
-- (QA, Nov 20 2026: G.build went over Kahlua's 200 locals once the setup cuts added theirs; the game threw
-- "Index 200 out of bounds" in LexState.new_localvar while KCheck passed. ZeD setup's rows are built here.)
local function buildSetup(realMods, byName)
    -- ZeD setup: ZeD's own options (their controls on the Mods page) in their groups,
    -- then the game settings ZeD's look depends on
    local setup = {}
    local zo = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("ZeD_UI")
    local mods = realMods
    local zrow, zorder = {}, {}   -- option id -> its row's copy; the ids in Settings.lua's order
    for _, opt in ipairs(zo and zo.data or {}) do
        if opt.element then
            for _, r in ipairs(mods) do
                if r.control == opt.element then
                    -- the name is drawn through ZeD.tr each frame (ZeD_MainMenuOptions), so the test language reaches it
                    r.labelKey = opt.zedNameKey
                    -- its help: vanilla's options screen never gives a mod's drop-down the option's
                    -- tooltip, so the band would read nothing; the key is beside the name's (UI_ZeD_Settings_<x>Tip)
                    r.zedTipKey = opt.zedNameKey and (opt.zedNameKey .. "Tip")
                    r.zedOwn = true   -- (one of ZeD's own options: Find shows it on ZeD setup, G.findRows)
                    local c = copyRow(r, nil)
                    c.zedDefault = opt.zedDefault   -- (Settings.lua: the item it starts on)
                    -- (the director, Nov 21 2026: Defaults keeps Style as it is, so a Lite player stays in Lite; the
                    -- help still says "Default: Full")
                    if opt.id == "lookStyle" then c.zedNoReset = true end
                    zrow[opt.id] = c
                    zorder[#zorder + 1] = opt.id
                end
            end
        end
    end
    local placed = {}
    -- (Nov 15 2026, add-on hooks) the add-ons' groups (ZeD.Options.addGroup) go in among ZeD's:
    -- after the group their `after` names, else just before Trouble. With none added, addons is
    -- empty and every line below that touches it does nothing.
    local addons = (ZeD.Options and ZeD.Options.groups) or {}
    local known = {}   -- ZeD's group title keys, so an `after` ZeD has no group for falls back
    for _, grp in ipairs(G.ZED_GROUPS) do known[grp[1]] = true end
    -- put the add-on groups whose place is slot (a ZeD group's title key; nil: the default place)
    local function emitAddons(slot)
        for _, a in ipairs(addons) do
            local want = a.after
            if want ~= nil and not known[want] then
                ZeD.Options.logOnce("after:" .. a.owner .. ":" .. tostring(want),
                    a.owner .. ": no ZeD group " .. tostring(want) .. " to follow; its group goes before Trouble")
                want = nil
            end
            if want == slot then
                local list = addonRows(a, mods)
                if #list > 0 then
                    -- (the title through ZeD.tr: an add-on's key, the test language too; plain words
                    -- come back as they are, since ZeD.tr hands back a key it cannot find)
                    setup[#setup + 1] = { kind = "header", text = ZeD.tr(a.title) }
                    for _, c in ipairs(list) do setup[#setup + 1] = c end
                end
            end
        end
    end
    local defaultDone = false   -- the default place came up (it is before Trouble)
    -- (beta 21: the eight Immersive-or-Simple switches are one Style switch now, Lite or Full; the old ones stay saved
    -- but never show, not even under Other)
    for _, id in ipairs(G.RETIRED) do placed[id] = true end
    local lite = ZeD.Settings and ZeD.Settings.lite and ZeD.Settings.lite()
    -- (QA's visual noise audit, Nov 20 2026) the options with no row of their own, and the rows hidden now (Restock
    -- while Loadouts is off, the Watch in Lite, the debug switches outside debug mode): none goes under Other, and
    -- G.hiddenOpts lists them for ZeD setup's Defaults
    local hidden = {}
    local function hide(id)
        if placed[id] then return end
        placed[id] = true
        local o = zo and zo.dict and zo.dict[id]
        if o then hidden[#hidden + 1] = o end
    end
    for _, id in ipairs(G.SETUP_HIDDEN) do hide(id) end
    local dbg = isDebugEnabled and isDebugEnabled() or false
    for _, grp in ipairs(G.ZED_GROUPS) do
      -- (QA B3-2) in Lite the Additions group still shows while the applied additions are off the Vanilla preset, so
      -- a player who came into Lite with extras on can see them and turn them off; Chords stays out
      local keepShown = grp[1] == "UI_ZeD_Options_ZedAdditions" and ZeD.Settings and ZeD.Settings.additionsOffVanilla
          and ZeD.Settings.additionsOffVanilla()
      if lite and G.LITE_HIDES[grp[1]] and not keepShown then
        -- (a group Lite leaves out: its options are hidden, so none of them turns up under Other instead, and
        -- through hide() they reach G.hiddenOpts, so ZeD setup's Defaults resets them too (QA B3-1))
        for _, e in ipairs(G.groupRows(grp)) do
            if not e._owner then hide(e[1]) end   -- (an add-on's own option is not ZeD's to hide)
            local d = e.merge and G.MERGED[e.merge]
            for _, id in ipairs((d and d.ids) or {}) do hide(id) end
        end
      else
        if grp[1] == "UI_ZeD_Options_ZedTrouble" and #addons > 0 then emitAddons(nil); defaultDone = true end
        local list = {}
        if grp.chords then
            -- the quick action chords: a row each (ZeD_MainMenuOptions draws a "chord" row)
            for _, c in ipairs(ZeD.QuickChords and ZeD.QuickChords.CHORDS or {}) do list[#list + 1] = { kind = "chord", chord = c, label = "" } end
        end
        for _, e in ipairs(G.groupRows(grp)) do
            -- (an add-on's row of another owner, ZeD.Options.addRows: its row built from its own options)
            local own = e._owner
            local c = zrow[e[1]]
            if own then
                local built = addonRows({ owner = own, rows = { e } }, mods)
                c = built[1]
            end
            local pkey = own and (own .. "." .. e[1]) or e[1]
            local ozo = own and PZAPI.ModOptions:getOptions(own) or zo
            local off = (e.fullOnly and lite) or (e.debugOnly and not dbg)
                or (e.showIf and liveOf(ozo, e.showIf) ~= 2)
            if c and off then
                if not own then hide(e[1]) end
            elseif c and not placed[pkey] then
                styleRow(c, e)
                local d = e.merge and G.MERGED[e.merge]
                if d then
                    -- one row for several options: a stand-in control (mergedControl), its own name and help; no
                    -- option of its own, so no opt (the changed dot compares it by its own key)
                    c.control = mergedControl(e.merge, d, zo)
                    c.opt = nil
                    c.labelKey = d.name
                    c.zedTipKey = d.tip
                    c.zedIds = d.ids
                    if d.ticks then
                        c.kind = "tick"
                        c.zedStyle = nil
                        c.zedDefault = nil
                        c.zedIds = {}
                        for i, t in ipairs(d.ticks) do c.zedIds[i] = t[1] end
                        c.zedBacks = d.ticks   -- (a screen a mod took: its name under the row, ZeD_StepAside.lua)
                    else
                        -- Defaults: the choice the options' own starting items make
                        local v = {}
                        for _, id in ipairs(d.ids) do
                            local o = zo and zo.dict and zo.dict[id]
                            v[id] = o and o.zedDefault
                        end
                        c.zedDefault = d.read(v)
                    end
                    for _, id in ipairs(c.zedIds) do placed[id] = true end
                end
                list[#list + 1] = c
                placed[pkey] = true
            end
        end
        if #list > 0 then
            setup[#setup + 1] = { kind = "header", text = G.text(grp[1]) }
            for _, c in ipairs(list) do setup[#setup + 1] = c end
        end
        if #addons > 0 then emitAddons(grp[1]) end
      end
    end
    -- (no Trouble group, should one ever be cut: the default place is the end of ZeD's groups)
    if #addons > 0 and not defaultDone then emitAddons(nil) end
    local rest = {}
    for _, id in ipairs(zorder) do if not placed[id] then rest[#rest + 1] = zrow[id] end end
    if #rest > 0 then
        setup[#setup + 1] = { kind = "header", text = getText("UI_ServerSettingGroup_Other") }
        for _, c in ipairs(rest) do setup[#setup + 1] = c end
    end
    local grows = {}
    for _, e in ipairs(G.SETUP_GAME) do
        local r = byName[e[1]]
        if r then grows[#grows + 1] = copyRow(r, ZeD.tr("UI_ZeD_Options_AlsoIn", G.text(e[2]), G.text(e[3])), e[4]) end
    end
    if #grows > 0 then
        setup[#setup + 1] = { kind = "header", text = ZeD.tr("UI_ZeD_Options_HeadGameSettings") }
        for _, r in ipairs(grows) do setup[#setup + 1] = r end
    end
    return setup, hidden
end

function G.build(pages, rowsOf)
    local byName, byPage, used = {}, {}, {}
    local extra = {}   -- pages a mod added with MainOptions:addPage (titles the game doesn't have)
    for _, p in ipairs(pages) do
        local pid = pageId(p.raw)
        local rows = rowsOf(p) or {}
        if pid then byPage[pid] = rows else extra[#extra + 1] = { title = p.raw, rows = rows } end
        for _, r in ipairs(rows) do
            if pid == "audio" and r.kind == "button" and not r.opt then byName.__audioButton = r end
            if r.opt and r.opt.name then
                byName[r.opt.name] = r
                -- (QA's visual noise audit 29, Nov 20 2026: "Does nothing with ZeD active" under each replaced setting,
                -- each with its own warning square. Such a row is hidden now: placed nowhere, not even under Other,
                -- and Find does not offer it. Its value stays the game's.)
                if G.MOOT[r.opt.name] then r.moot = G.MOOT[r.opt.name]; used[r] = true end
                if G.ONLY[r.opt.name] then r.only = G.ONLY[r.opt.name] end
            end
        end
    end
    -- the Mods group: the game's Mods page (where ZeD's own controls are), then each added page under its title
    local realMods = byPage.mods or {}
    if #extra > 0 then
        local all = {}
        for _, r in ipairs(realMods) do all[#all + 1] = r end
        for _, e in ipairs(extra) do
            all[#all + 1] = { kind = "header", text = tostring(e.title or "") }
            for _, r in ipairs(e.rows) do all[#all + 1] = r end
        end
        byPage.mods = all
    end
    local out = {}
    local other = {}   -- groupId -> rows nobody named
    for _, g in ipairs(G.GROUPS) do
        local rows = {}
        for _, sec in ipairs(g.sections or {}) do
            local title = sec[1]
            local list = {}
            if sec.from then
                local src = byPage[sec.from] or {}
                if sec.from == "keys" then
                    -- the key list, without the toggles (filed under Movement)
                    local skip = false
                    for _, r in ipairs(src) do
                        if r.kind == "header" and r.id == "toggles" then skip = true
                        elseif r.kind == "header" then skip = false end
                        if not skip and r.kind ~= "tick" then list[#list + 1] = r; used[r] = true end
                    end
                else
                    for _, r in ipairs(src) do list[#list + 1] = r; used[r] = true end
                end
            else
                for _, name in ipairs(sec[2] or {}) do
                    local r = byName[name]
                    if r and not used[r] then list[#list + 1] = r; used[r] = true end
                end
            end
            if #list > 0 then
                if title then rows[#rows + 1] = { kind = "header", text = G.text(title) } end
                for _, r in ipairs(list) do rows[#rows + 1] = r end
            end
        end
        out[g.id] = rows
    end
    -- the rest: controls nobody named, in their old page's group under Other
    for pid, rows in pairs(byPage) do
        local gid = FALLBACK[pid] or "gameplay"
        for _, r in ipairs(rows) do
            if not used[r] and r.kind ~= "header" and r.kind ~= "note" and r.kind ~= "desc" then
                -- a button with no label of its own (Audio's sound list) is named by its title
                if (r.label or "") == "" and r.control and r.control.title then r.label = tostring(r.control.title) end
                other[gid] = other[gid] or {}
                table.insert(other[gid], r)
                used[r] = true
            end
        end
    end
    for gid, rows in pairs(other) do
        local t = out[gid]
        if t then
            t[#t + 1] = { kind = "header", text = getText("UI_ServerSettingGroup_Other") }
            for _, r in ipairs(rows) do t[#t + 1] = r end
        end
    end
    out.zed, out.zedHidden = buildSetup(realMods, byName)
    return out
end

--- Find across the groups: the rows whose words (hayOf(r), lower case) hold q, each group's under its title.
--- ZeD's own options are found on ZeD setup, drawn with ZeD's own controls (radio rows, wells, the slider);
--- their plain drop-downs on the Mods page are left out, so Find never offers the same option twice.
--- ZeD setup's copies of the game's settings are left out the other way: each is found in its own group.
function G.findRows(pages, rowsFor, q, hayOf)
    local rows = {}
    for _, p in ipairs(pages) do
        local hits = {}
        for _, r in ipairs(rowsFor(p) or {}) do
            if r.kind ~= "header" and r.kind ~= "note" and r.kind ~= "desc" then
                local keep
                if p.setup then keep = r.zedOwn == true else keep = not r.zedOwn end
                if keep and string.find(hayOf(r), q, 1, true) then hits[#hits + 1] = r end
            end
        end
        if #hits > 0 then
            rows[#rows + 1] = { kind = "header", text = p.title }
            for _, r in ipairs(hits) do rows[#rows + 1] = r end
        end
    end
    return rows
end

-- ----------------------------------------------------------------------------
-- The first time the game starts with ZeD on, Options opens on ZeD setup by
-- itself, once (Zomboid/Lua/ZeD_setup_seen.txt remembers). Not on a QA
-- autoload launch, a -debug test run that continues the latest save by
-- itself (QABridge sets ZeD.QAAutoload).
-- ----------------------------------------------------------------------------
local SEEN_FILE = "ZeD_setup_seen.txt"
local firstTicks = 0
local function firstRun()
    firstTicks = firstTicks + 1
    if firstTicks < 120 then return end   -- let the desk settle
    if ZeD.QAAutoload then Events.OnFETick.Remove(firstRun); return end
    local m = MainScreen and MainScreen.instance
    local win = MM.root and MM.root.optsWin
    if not m or m.inGame or not win or MM.view ~= "main" or not MM.openOptions then
        Events.OnFETick.Remove(firstRun); return
    end
    -- the screen is still fading in (openOptions would refuse): try again next tick
    if (m.delay or 0) > 0 and firstTicks < 1200 then return end
    Events.OnFETick.Remove(firstRun)
    local r = getFileReader(SEEN_FILE, false)
    if r then r:close(); return end
    -- (beta 21, the director: the first launch offers a setup of its own, pick your own, load a setup or skip,
    -- ZeD_MainMenuWelcome.lua; it writes the seen file when it is answered, so a launch that never answers asks again)
    if MM.openWelcome then MM.openWelcome(); return end
    MM.openOptions()
    if MM.view ~= "options" then return end   -- it did not open: the marker stays unwritten, so the next launch tries again
    local w = getFileWriter(SEEN_FILE, true, false)
    if w then w:write("1"); w:close() end
    win.firstRun = true
    win.pageIdx = 1
    win.scroll = 0
    win._groupCache = nil
end
if Events and Events.OnMainMenuEnter then
    Events.OnMainMenuEnter.Add(function()
        firstTicks = 0
        Events.OnFETick.Remove(firstRun)
        Events.OnFETick.Add(firstRun)
    end)
end

return G
