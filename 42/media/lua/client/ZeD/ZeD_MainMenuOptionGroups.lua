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
--   * only: still works, but only somewhere ("Only outside ZeD's windows")
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

-- the groups, in order; each section lists vanilla option names, or takes a
-- whole page's rows (from = "keys" | "controller" | "mods")
G.GROUPS = {
    { id = "zed", title = "ZeD setup", setup = true },
    { id = "display", title = "Display", sections = {
        { "Screen", { "displayMode", "fullscreen", "borderless", "resolution", "framerate", "vsync", "focusloss", "lockCursorToWindow" } },
    } },
    { id = "graphics", title = "Graphics", sections = {
        { "Textures", { "texcompress", "maxTextureSize", "maxVehicleTextureSize", "simpleClothingTex", "simpleWeaponTex",
                        "highResPlacedItems", "perf_3Ditems" } },
        { "World", { "lightingFPS", "fogQuality", "waterQuality", "perf_puddles", "puddlesQuality", "precipOption",
                     "precipitationSpeedMultiplier", "perf_reflections", "perf_skybox", "bloodDecals", "corpseShadows" } },
        { "Effects", { "screenFilter", "doVideoEffects", "doWindSpriteEffects", "doDoorSpriteEffects", "viewConeOpacity",
                       "searchModeOverlayEffect", "usePhysicsHitReaction", "maxActiveRagdolls", "zombieUpdateOpt" } },
    } },
    { id = "audio", title = "Audio", sections = {
        { "Volume", { "soundVolume", "musicVolume", "jumpscareVolume", "vehicleEngineVolume" } },
        { "Music", { "musicLibrary", "__audioButton", "musicActionStyle" } },   -- (__audioButton: the library's Reload)
        { "Voice chat", { "voiceEnable", "voiceRecordDevice", "voiceMode", "voiceVADMode", "voiceAGCMode", "voiceVolumeMic",
                          "voiceVolumePlayers" } },
        { "Streaming", { "streamerMode" } },
    } },
    { id = "controls", title = "Controls", sections = {
        { "Movement", { "toggleToRun", "dblTapRunToSprint", "toggleToSprint", "toggleToAim", "autoProneAtk" } },
        { "Menus", { "radialMenuKeyToggle", "reloadRadialInstant", "enableLeftJoystickRadialMenu", "singleContextMenu",
                     "cycleContainerKey", "shoulderButtonContainerSwitch" } },
        { "Mouse", { "ignoreMouseWheelAcceleration", "mapHorizontalMouseWheelToVertical" } },
        { "Controller", from = "controller" },
        { "Key bindings", from = "keys" },
    } },
    { id = "gameplay", title = "Gameplay", sections = {
        { "Camera", { "zoom", "zoomLevels", "autoZoom", "panCameraWhileAiming", "panCameraWhileDriving" } },
        { "Aiming", { "reticleMode", "showAimTexture", "aimTexture", "showReticleTexture", "reticleTexture",
                      "showValidTargetReticleTexture", "validTargetReticleTexture", "targetColor", "noTargetColor",
                      "crosshairTexture", "maxCrosshairOffset", "reticleCameraZoom" } },
        { "Cursor", { "iso_cursor", "showCursorWhileAiming", "meleeOutline" } },
        { "On its own", { "autoDrink", "keyInIgnition", "autoWalkContainer", "timedActionGameSpeedReset", "mapViewPause",
                          "dropItemsOnSquareCenter", "autoRevealPrintMediaMapLocations" } },
        { "Multiplayer", { "showUsername", "mpTextColor", "populateServerListOnStart" } },
    } },
    { id = "interface", title = "Interface", sections = {
        { "Text", { "fontSize", "contextMenuFont", "inventoryFont", "tooltipFont" } },
        { "HUD", { "moodleSize", "sidebarSize", "inventoryContainerSize", "actionProgressBarSize" } },
        { "Clock", { "clockFormat", "clockSize", "clock24hour", "temperatureDisplay" } },
        { "Highlights", { "doContainerOutline", "objHighColor", "worldItemHighlightColor" } },
        { "Help", { "showCraftingXP", "showItemModInfo", "showSurvivalGuide" } },
        { "Rendering", { "UIFBO", "UIRenderFPS" } },
        { "Language", { "language", "comlang" } },
    } },
    { id = "access", title = "Accessibility", sections = {
        { "Colours", { "goodHighColor", "badHighColor", "colorblindPatterns" } },
        { "Reading", { "enableDyslexicFont" } },
        { "Weather", { "disableLightningDuringStorms" } },
    } },
    { id = "mods", title = "Mods", sections = { { nil, from = "mods" } } },
}

-- where an option the table doesn't name goes: its old page's group
local FALLBACK = { display = "graphics", ui = "interface", audio = "audio", keys = "controls", access = "gameplay",
                   mp = "gameplay", controller = "controls", mods = "mods" }

-- Settings that do nothing with ZeD active: greyed, inert, the reason in the
-- row and the help band. From the code: ZeD replaces the surface and never
-- reads the option (a search for every getOption* call, Oct 19 2026).
G.MOOT = {
    inventoryFont = "ZeD's lists draw in ZeD's text: use Text size in ZeD setup.",
    contextMenuFont = "ZeD draws every context menu in ZeD's text: use Text size in ZeD setup.",
    inventoryContainerSize = "ZeD's windows have their own container column.",
    clockSize = "The watch shows the time; the game's clock is put away.",
    clockFormat = "The watch shows the day of the month only.",
    showCraftingXP = "ZeD's Craft tab replaces the game's crafting window.",
    shoulderButtonContainerSwitch = "LB and RB open ZeD's Character and World windows.",
    cycleContainerKey = "ZeD's container column doesn't cycle containers by key and wheel.",
}
-- Still working, but only somewhere: { the line under its name, the help band's words }
G.ONLY = {
    enableDyslexicFont = { "Outside ZeD's windows only", "ZeD's windows keep their own text; the game's remaining screens switch." },
    sidebarSize = { "Multiplayer only", "ZeD hides these buttons in single player; in multiplayer they stay." },
    tooltipFont = { "Item tooltip only", "The item tooltip's facts follow it; ZeD's tooltip frame uses ZeD's text." },
}

-- ZeD setup: the game settings ZeD's look depends on: { name, where it lives, why ZeD uses it }
G.SETUP_GAME = {
    { "fontSize", "Interface | Text", "ZeD's windows grow with the game's font size." },
    { "tooltipFont", "Interface | Text", "The item tooltip's facts are drawn in it." },
    { "moodleSize", "Interface | HUD", "ZeD places the moodles and sizes its moodle row from it." },
    { "clock24hour", "Interface | Clock", "The watch reads it." },
    { "temperatureDisplay", "Interface | Clock", "The watch reads it." },
    { "doVideoEffects", "Graphics | Effects", "The New wallpaper plays only with it on." },
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
                        if r.kind == "header" and r.text == "Toggles" then skip = true
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
                if title then rows[#rows + 1] = { kind = "header", text = title } end
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
            t[#t + 1] = { kind = "header", text = "Other" }
            for _, r in ipairs(rows) do t[#t + 1] = r end
        end
    end
    -- ZeD setup: ZeD's own options (their controls on the Mods page), then the
    -- game settings ZeD's look depends on
    local setup = {}
    local zo = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("ZeD_UI")
    local mods = byPage.mods or {}
    local zrows = {}
    for _, opt in ipairs(zo and zo.data or {}) do
        if opt.element then
            for _, r in ipairs(mods) do if r.control == opt.element then zrows[#zrows + 1] = copyRow(r, nil) end end
        end
    end
    if #zrows > 0 then
        setup[#setup + 1] = { kind = "header", text = "ZeD's look" }
        for _, r in ipairs(zrows) do setup[#setup + 1] = r end
    end
    local grows = {}
    for _, e in ipairs(G.SETUP_GAME) do
        local r = byName[e[1]]
        if r then grows[#grows + 1] = copyRow(r, "Also in " .. e[2], e[3]) end
    end
    if #grows > 0 then
        setup[#setup + 1] = { kind = "header", text = "Game settings ZeD uses" }
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
    Events.OnFETick.Remove(firstRun)
    if ZeD.QAAutoload then return end
    local r = getFileReader(SEEN_FILE, false)
    if r then r:close(); return end
    local m = MainScreen and MainScreen.instance
    local win = MM.root and MM.root.optsWin
    if not m or m.inGame or not win or MM.view ~= "main" or not MM.openOptions then return end
    local w = getFileWriter(SEEN_FILE, true, false)
    if w then w:write("1"); w:close() end
    MM.openOptions()
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
