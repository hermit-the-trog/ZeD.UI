-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuOptionGroups.lua
-- ============================================================================
-- OPTIONS, GROUPED LIKE A MODERN GAME (Oct 19 2026, mockup zed_settings_v1.html;
-- director: "Can we make PZ settings organized and feel like a modern game?")
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

-- The words in the tables below are translation keys, turned into the player's language where
-- they show (G.text): ZeD's own (UI_ZeD_...) through ZeD.tr, the game's own words (UI_optionscreen_audio,
-- UI_DisplayOptions_Camera...) through getText, all-caps ones in sentence case. Anything else, such as
-- words a window has already put into the player's language, passes through as it is.
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
-- row and the help band. From the code: ZeD replaces the surface and never
-- reads the option (a search for every getOption* call, Oct 19 2026).
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
-- (Oct 20 2026: the Dyslexic font replaces ZeD's text fonts with the game's own dyslexic ones, and
-- the Tooltip font sizes ZeD's tooltips as well as the item tooltip's facts)
G.ONLY = {
    enableDyslexicFont = { "UI_ZeD_Options_OnlyDyslexic", "UI_ZeD_Options_OnlyDyslexicHelp" },
    sidebarSize = { "UI_ZeD_Options_OnlySidebar", "UI_ZeD_Options_OnlySidebarHelp" },
    tooltipFont = { "UI_ZeD_Options_OnlyTooltip", "UI_ZeD_Options_OnlyTooltipHelp" },
}

-- ZeD setup: the game settings ZeD's look depends on: { name, its group, its section, why ZeD uses it }
-- (the group and section are translation keys, shown as "Also in <group> | <section>")
G.SETUP_GAME = {
    { "fontSize", "UI_ZeD_Options_GroupInterface", "UI_ZeD_Options_SecText", "UI_ZeD_Options_WhyFontSize" },
    { "tooltipFont", "UI_ZeD_Options_GroupInterface", "UI_ZeD_Options_SecText", "UI_ZeD_Options_WhyTooltipFont" },
    { "moodleSize", "UI_ZeD_Options_GroupInterface", "UI_ZeD_Options_SecHud", "UI_ZeD_Options_WhyMoodleSize" },
    { "clock24hour", "UI_ZeD_Options_GroupInterface", "UI_DisplayOptions_Clock", "UI_ZeD_Options_WhyWatch" },
    { "temperatureDisplay", "UI_ZeD_Options_GroupInterface", "UI_DisplayOptions_Clock", "UI_ZeD_Options_WhyWatch" },
    { "doVideoEffects", "UI_ZeD_Options_GroupGraphics", "UI_ZeD_Options_SecEffects", "UI_ZeD_Options_WhyVideoEffects" },
}

-- ZeD setup: ZeD's own options in five groups, each with the control it is drawn with
-- (Oct 21 2026, mockup ZeDUI/mockups/zed_settings_v2.html; director: "Apply and commit").
-- The value is still the combo's item (ModOptions saves that number), so a saved choice keeps
-- its meaning; only the drawing changes (ZeD_MainMenuOptions' drawControl):
--   "seg"    a switch of joined buttons, the pick filled with the accent (two or three choices)
--   "swatch" the nine accents as squares; the window accents add "Same as Accent"
--   "scale"  a stepped slider: Auto at the left, then the fixed sizes
--   "onoff"  an on/off switch (item 1 Off, item 2 On); danger: red when on
--   nil      the drop-down, as before (a long list of names)
-- A control too wide for the space (a long translation, the test language) is drawn as the drop-down.
-- { group title, { { option id, style, danger = , under = the line under its name,
--   short = shorter words for a switch's choices or the slider's steps, by item (the drop-down
--   on the Mods page keeps the full ones) } } }
-- An option of ZeD's this table doesn't name (a new one) lands under Other, as a drop-down.
G.ZED_GROUPS = {
    { "UI_ZeD_Options_ZedLook", { { "baseTheme", "seg" }, { "accentColor", "swatch" }, { "textSize", "seg" }, { "uiScale", "scale", short = { "UI_ZeD_Settings_Auto" } } } },
    { "UI_ZeD_Options_ZedWindows", { { "inventoryView", "seg" }, { "equipView", "seg" }, { "charAccent", "swatch" }, { "worldAccent", "swatch" } } },
    { "UI_ZeD_Options_ZedHud", { { "moodlePlace", "seg", short = { "UI_ZeD_Options_MoodlesRight", "UI_ZeD_Options_MoodlesLeft", "UI_ZeD_Options_MoodlesBottom" } }, { "watchPlace", "seg" }, { "actionBar", "seg" } } },
    { "UI_ZeD_Options_ZedControls", { { "contextStyle", "seg" }, { "glyphDisplay" }, { "inputModeLock" } } },
    -- (Oct 24 2026, mockup zed_quick_chords_v1: the twelve chords, ZeD_QuickChords; not ModOptions: rows of their own)
    { "UI_ZeD_Options_ZedChords", {}, chords = true },
    { "UI_ZeD_Options_ZedPutBack", { { "putBack", "onoff" } } },
    { "UI_ZeD_Options_ZedTrouble", { { "safeMode", "onoff", danger = true, under = "UI_ZeD_Options_UnderSafeMode" },
                                     { "testLanguage", "onoff" } } },
}

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

-- Build every group's rows. pages = vanilla's pages ({ title, raw, view, keys });
-- rowsOf(page) = that page's rows (ZeD_MainMenuOptions' discovery, cached).
-- Returns { [groupId] = rows }.
function G.build(pages, rowsOf)
    local byName, byPage, used = {}, {}, {}
    for _, p in ipairs(pages) do
        local pid = pageId(p.raw) or "mods"
        local rows = rowsOf(p) or {}
        byPage[pid] = rows
        for _, r in ipairs(rows) do
            if pid == "audio" and r.kind == "button" and not r.opt then byName.__audioButton = r end
            if r.opt and r.opt.name then
                byName[r.opt.name] = r
                if G.MOOT[r.opt.name] then r.moot = G.MOOT[r.opt.name] end
                if G.ONLY[r.opt.name] then r.only = G.ONLY[r.opt.name] end
            end
        end
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
    -- ZeD setup: ZeD's own options (their controls on the Mods page) in their groups,
    -- then the game settings ZeD's look depends on
    local setup = {}
    local zo = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("ZeD_UI")
    local mods = byPage.mods or {}
    local zrow, zorder = {}, {}   -- option id -> its row's copy; the ids in Settings.lua's order
    for _, opt in ipairs(zo and zo.data or {}) do
        if opt.element then
            for _, r in ipairs(mods) do
                if r.control == opt.element then
                    -- the name is drawn through ZeD.tr each frame (ZeD_MainMenuOptions), so the test language reaches it
                    r.labelKey = opt.zedNameKey
                    -- its help: vanilla's options screen never gives a mod's drop-down the option's
                    -- tooltip, so the band read nothing; the key is beside the name's (UI_ZeD_Settings_<x>Tip)
                    r.zedTipKey = opt.zedNameKey and (opt.zedNameKey .. "Tip")
                    local c = copyRow(r, nil)
                    c.zedDefault = opt.zedDefault   -- (Settings.lua: the item it starts on)
                    zrow[opt.id] = c
                    zorder[#zorder + 1] = opt.id
                end
            end
        end
    end
    local placed = {}
    for _, grp in ipairs(G.ZED_GROUPS) do
        local list = {}
        if grp.chords then
            -- the quick action chords: a row each (ZeD_MainMenuOptions draws a "chord" row)
            for _, c in ipairs(ZeD.QuickChords and ZeD.QuickChords.CHORDS or {}) do list[#list + 1] = { kind = "chord", chord = c, label = "" } end
        end
        for _, e in ipairs(grp[2]) do
            local c = zrow[e[1]]
            if c and not placed[e[1]] then
                c.zedStyle, c.zedDanger, c.under, c.zedShort = e[2], e.danger, e.under, e.short
                list[#list + 1] = c
                placed[e[1]] = true
            end
        end
        if #list > 0 then
            setup[#setup + 1] = { kind = "header", text = G.text(grp[1]) }
            for _, c in ipairs(list) do setup[#setup + 1] = c end
        end
    end
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
    out.zed = setup
    return out
end

-- ----------------------------------------------------------------------------
-- The first time the game starts with ZeD on, Options opens on ZeD setup by
-- itself, once (Zomboid/Lua/ZeD_setup_seen.txt remembers). Not on a QA
-- autoload launch (QABridge sets ZeD.QAAutoload).
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
