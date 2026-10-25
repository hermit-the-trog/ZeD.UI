-- ZeD-UI/42/media/lua/client/ZeD/ZeD_DpadWheels.lua
-- ============================================================================
-- THE CONTROLLER'S D-PAD WHEELS (DPAD_WHEELS_SPEC.md, HOOK_MAP row 29;
-- mockup ZeDUI/mockups/zed_dpad_wheels_v2.html, approved Oct 23 2026)
--
-- Four wheels in place of the game's four D-pad wheels, one per direction:
--   Left  Character     the Character window's things, one flick from the world
--   Right World         the World window's things and what is in reach
--   Up    Social        gestures, shout; on a server chat, safety, players
--   Down  Here and now  stance and movement, time and view, help, the light
-- They open only when no window has the pad (in the world). Hold the D-pad,
-- point with the right stick (ZeD.Wheel.sliceFromJoypad), let go to take.
-- A slice with the corner triangle swaps the ring in place to its wheel and
-- keeps it open: the stick points, A takes, B backs out one level (Back is
-- the inner wheel's last slice). Every top-level slice keeps its place: one
-- that can't be done now is added off, and the bubble gives the reason.
--
-- The shared getPlayerRadialMenu wheel is filled (ZeD_Wheel.lua draws it),
-- so mods see vanilla's object API. Where the game fills a wheel itself
-- (vehicle, animal, emote groups) its filler runs and ZeD adds Back.
-- Replaces: ISDPadWheels.onDisplayLeft / Right / Up / Down (and with them
-- the belt's D-pad Left and ZeD_QuickWheel's additions to D-pad Right; the
-- quick wheel's item pickers are used here). Safe mode: the game's wheels.
-- ============================================================================

require "ISUI/ISDPadWheels"
require "ISUI/ISRadialMenu"
require "ZeD/ZeD_Wheel"
require "ZeD/ZeD_QuickWheel"
require "ZeD/Tr"
require "ZeD/SafeMode"

ZeD = ZeD or {}
ZeD.DpadWheels = ZeD.DpadWheels or {}
local D = ZeD.DpadWheels
local W = ZeD.Wheel

local MAX_INNER = 11                      -- an inner wheel's items (Back is the 12th; paging is out of scope for v1)
local BACK_TEX = "media/ui/emotes/back.png"
local CHEVRON = "  \226\128\186  "        -- (U+203A, as the mockup's breadcrumb)

-- the four directions: the wheel's name, its button, the arrow the prompts show
D.DIRS = {
    left  = { title = "UI_ZeD_Wheel_Character", button = "DPadLeft",  arrow = "\226\134\144", build = "character" },
    right = { title = "UI_ZeD_Wheel_World",     button = "DPadRight", arrow = "\226\134\146", build = "world" },
    up    = { title = "UI_ZeD_Wheel_Social",    button = "DPadUp",    arrow = "\226\134\145", build = "social" },
    down  = { title = "UI_ZeD_Wheel_HereNow",   button = "DPadDown",  arrow = "\226\134\147", build = "now" },
    -- the Select (Back / View) button: ZeD's own wheel (director, Oct 23 2026), on the game's Select wheel object
    select = { title = "UI_ZeD_Wheel_ZeD", button = "Back", glyph = "UI_ZeD_Wheel_GlyphSelect", build = "zed" },
}
D.B = D.B or {}                           -- the wheels' builders (filled below): player, pn -> entries

-- per player: { dir = "left", path = { level, ... } }; a level = { title, entries, fill }
D.state = D.state or {}

local function safe(fn, ...) local ok, v = pcall(fn, ...); if ok then return v end; return nil end
function D.safe(fn, ...) return safe(fn, ...) end

-- ---------------------------------------------------------------------------
-- pictures: ZeD icons by name, the tab icons, or a texture as given
-- ---------------------------------------------------------------------------
local _tex = {}
local function texOf(path)
    if _tex[path] == nil then _tex[path] = getTexture(path) or false end
    return _tex[path] or nil
end
function D.icon(name) return texOf("media/textures/ZeD/icons/" .. name .. ".png") end
function D.tabIcon(name) return texOf("media/textures/ZeD/TabIcons/" .. name .. ".png") end

-- an entry's picture: { texture, tintable }
local function pictureOf(e)
    if e.icon then local t = D.icon(e.icon); if t then return t, true end end
    if e.tab then local t = D.tabIcon(e.tab); if t then return t, true end end
    if e.tex then return e.tex, e.tint == true end
    if e.vanilla then return texOf(e.vanilla), false end
    return nil, false
end

-- ---------------------------------------------------------------------------
-- showing a level on the shared wheel
-- ---------------------------------------------------------------------------
local function centre(menu, pn)
    menu:setX(getPlayerScreenLeft(pn) + getPlayerScreenWidth(pn) / 2 - menu:getWidth() / 2)
    menu:setY(getPlayerScreenTop(pn) + getPlayerScreenHeight(pn) / 2 - menu:getHeight() / 2)
end

local function crumb(st)
    local parts = {}
    for _, lv in ipairs(st.path) do parts[#parts + 1] = lv.title or "" end   -- (the wheel draws it in upper case)
    return table.concat(parts, CHEVRON)
end

local function prompts(st)
    local d = D.DIRS[st.dir]
    local g = d.arrow or ZeD.tr(d.glyph)
    local gp = (not d.arrow) and { "SEL" } or nil   -- (the Select button's picture; its name is translated)
    if #st.path <= 1 and st.held then
        return { { glyph = g, pad = gp, label = ZeD.tr("UI_ZeD_Wheel_PromptHold") }, { glyph = "RS", label = ZeD.tr("UI_ZeD_Wheel_PromptPoint") },
                 { glyph = g, pad = gp, label = ZeD.tr("UI_ZeD_Wheel_PromptLetGo") }, { glyph = "B", label = ZeD.tr("UI_ZeD_Wheel_PromptClose") } }
    end
    return { { glyph = "RS", label = ZeD.tr("UI_ZeD_Wheel_PromptPoint") }, { glyph = "A", label = ZeD.tr("UI_ZeD_Wheel_PromptTake") },
             { glyph = "B", label = ZeD.tr(#st.path > 1 and "UI_ZeD_Prompt_Back" or "UI_ZeD_Wheel_PromptClose") } }
end

-- the wheel on the player's screen and the pad on it; held = the D-pad is down
-- (letting go takes), else A takes
local function present(menu, pn, st)
    menu._zedCrumb = crumb(st)
    menu._zedPrompts = prompts(st)
    menu._zedDpad = st
    centre(menu, pn)
    menu:setHideWhenButtonReleased(st.held and Joypad[D.DIRS[st.dir].button] or nil)
    -- (the Select wheel's first show is the game's: JoyPadSetup adds it and gives it the pad)
    if st.engineShows then st.engineShows = nil; return end
    menu:addToUIManager()
    if menu.setVisible then menu:setVisible(true) end
    if JoypadState.players[pn + 1] then setJoypadFocus(pn, menu) end
    local p = getSpecificPlayer(pn)
    if p then p:setJoypadIgnoreAimUntilCentered(true) end
end

-- ---------------------------------------------------------------------------
-- quick action chords (ZeD_QuickChords.lua; QUICK_CHORDS_SPEC.md): a slice's
-- path, its words, and assigning a chord from the open wheel
-- ---------------------------------------------------------------------------
-- "character:8:1" for the slice i of the level on show (nil: the ZeD wheel, or a wheel the game fills)
function D.pathOf(st, i, e)
    local d = st and D.DIRS[st.dir]
    if not d or st.dir == "select" then return nil end
    local parts = { d.build }
    for k = 2, #st.path do
        local lv = st.path[k]
        local id = lv.key or lv.at
        if lv.fill or id == nil then return nil end
        parts[#parts + 1] = tostring(id)
    end
    parts[#parts + 1] = tostring((e and e.key) or i)
    return table.concat(parts, ":")
end

-- the wheel's words for it: the wheel, each level, the slice
function D.wordsOf(st, e)
    local Qc = ZeD.QuickChords
    local w = { ZeD.tr(D.DIRS[st.dir].title) }
    for k = 2, #st.path do w[#w + 1] = Qc.cleanName(st.path[k].title) end
    w[#w + 1] = Qc.cleanName(e and e.name)
    return w
end

local function chordPads(chord)
    if not chord then return nil end
    local b, f = chord:match("^(%a+)%+(%w+)$")
    return b and { b, f } or nil
end
local function chordWords(chord)
    local PG = ZeD.PadGlyphs
    local b, f = chord:match("^(%a+)%+(%w+)$")
    if PG and PG.set() then return PG.name(b) .. " + " .. PG.name(f) end
    return b .. " + " .. f
end

-- a bumper held and a button pressed on the open wheel: the pointed slice goes on that chord
function D.assign(pn, menu, chord)
    local Qc = ZeD.QuickChords
    local st = D.state[pn]
    if not (Qc and st and menu) then return end
    local i = menu._zedPoint or W.sliceFromJoypad(menu, menu.joyfocus and menu.joyfocus.id)
    local s = i and i > 0 and menu.slices and menu.slices[i]
    if not s or W.isPlace(s) or W.isBack(s) then return end
    local lv = st.path[#st.path]
    local e = (not lv.fill) and lv.entries and lv.entries[i] or nil
    local path = e and D.pathOf(st, i, e)
    if not path then
        s._zedNote = ZeD.tr(st.dir == "select" and "UI_ZeD_Chord_NotOnZeD" or "UI_ZeD_Chord_NotHere")
        return
    end
    local was, wasWords = Qc.get(chord)
    Qc.set(chord, path, D.wordsOf(st, e))
    local note = ZeD.tr("UI_ZeD_Chord_NowOn", chordWords(chord))
    if was and was ~= path and wasWords and #wasWords > 0 then note = note .. " " .. ZeD.tr("UI_ZeD_Chord_Replaces", wasWords[#wasWords]) end
    -- (the slice that had this chord before shows none now; this one shows it, and says so)
    for _, x in ipairs(menu.slices or {}) do
        if x._zedChord and x._zedChord[1] .. "+" .. x._zedChord[2] == chord then x._zedChord = nil end
    end
    s._zedChord = chordPads(chord)
    s._zedNote = note   -- (the bubble's second line while this wheel is open: ZeD_Wheel)
    pcall(function() getSoundManager():playUISound("UIActivateButton") end)
end

local function addEntry(menu, pn, e, st, n)
    local tex, tint = pictureOf(e)
    local text = e.name or "?"
    if e.off then
        menu:addSlice(text .. "\n" .. tostring(e.off), tex, nil)
    else
        if e.detail and e.detail ~= "" then text = text .. "\n" .. e.detail end
        if e.sub or e.fill then
            menu:addSlice(text, tex, D.enter, pn, e)
        else
            menu:addSlice(text, tex, D.take, pn, e)
        end
    end
    local s = menu.slices and menu.slices[#menu.slices]
    if s then
        if tex then s._zedTex, s._zedTint = tex, tint end   -- (the wheel's own picture lookup is skipped)
        if e.swatch then s._zedSwatch = e.swatch; if not tex then s._zedTex = false end end
        if (e.sub or e.fill) and not e.off then s._zedSub = true end
        local Qc = ZeD.QuickChords
        if Qc and st and n then s._zedChord = chordPads(Qc.chordFor(D.pathOf(st, n, e))) end   -- (its chord, in the bubble)
    end
end

-- a level of ZeD's own entries (with Back last when it is an inner wheel)
local function showLevel(pn, st)
    local lv = st.path[#st.path]
    local menu = st.menu
    menu:clear()
    local n = 0
    for _, e in ipairs(lv.entries or {}) do
        n = n + 1
        if #st.path > 1 and n > MAX_INNER then break end
        addEntry(menu, pn, e, st, n)
    end
    if #st.path > 1 then
        menu:addSlice(getText("IGUI_Emote_Back"), texOf(BACK_TEX), D.back, pn)
    end
    present(menu, pn, st)
end

-- a wheel the game fills itself (vehicle, animal, emote group): its filler,
-- then ZeD's Back in place of (or after) the game's
local function showFilled(pn, st)
    local lv = st.path[#st.path]
    local menu = getPlayerRadialMenu(pn)   -- (the game's fillers fill the shared wheel)
    if st.menu ~= menu and st.menu and st.menu.removeFromUIManager then st.menu:removeFromUIManager() end
    -- (the vehicle and animal fillers close the shared wheel instead of filling
    -- it when it is on screen: off the screen first)
    if menu:isReallyVisible() then menu:removeFromUIManager() end
    st.menu = menu
    local p = getSpecificPlayer(pn)
    local ok, err = pcall(lv.fill, p, pn)
    if not ok then print("[ZeD] DpadWheels: " .. tostring(err)) end
    if menu.removeFromUIManager then menu:removeFromUIManager() end
    local slices = menu.slices or {}
    local last = slices[#slices]
    if last and W.isBack(last) then
        last.command = { D.back, pn }
    else
        menu:addSlice(getText("IGUI_Emote_Back"), texOf(BACK_TEX), D.back, pn)
    end
    present(menu, pn, st)
end

local function show(pn)
    local st = D.state[pn]
    if not st then return end
    local lv = st.path[#st.path]
    if lv.fill then showFilled(pn, st) else showLevel(pn, st) end
end

-- ---------------------------------------------------------------------------
-- the commands the slices run
-- ---------------------------------------------------------------------------
function D.close(pn)
    local st = D.state[pn]
    D.state[pn] = nil
    local menu = st and st.menu
    if menu and menu._zedDpad then menu:undisplay() end
end

-- a slice that opens a wheel: it swaps in place and stays open (A takes)
function D.enter(pn, e)
    local st = D.state[pn]
    if not st then return end
    local p = getSpecificPlayer(pn)
    -- (where it sits in the level above, for a quick action chord assigned from the wheel: ZeD_QuickChords)
    local above = st.path[#st.path]
    local at = nil
    for i, x in ipairs(above and above.entries or {}) do if x == e then at = i; break end end
    local lv = { title = e.crumb or e.name, fill = e.fill, at = at, key = e.key }
    if e.sub then
        local entries = safe(e.sub, p, pn) or {}
        lv.entries = entries
    end
    st.path[#st.path + 1] = lv
    st.held = false
    show(pn)
end

-- one level up; from the top the wheel closes
function D.back(pn)
    local st = D.state[pn]
    if not st or #st.path <= 1 then return D.close(pn) end
    local was = st.menu
    st.path[#st.path] = nil
    st.held = false
    -- the top level is built again: what is live may have changed
    if #st.path == 1 then
        local p = getSpecificPlayer(pn)
        st.path[1].entries = safe(D.B[D.DIRS[st.dir].build], p, pn) or {}
    end
    -- (back on ZeD's own entries: the wheel this direction opened on; a
    -- game-filled wheel on the shared wheel leaves the screen first)
    if not st.path[#st.path].fill then st.menu = st.home end
    if was and was ~= st.menu and was.removeFromUIManager then was:removeFromUIManager() end
    show(pn)
end

-- a slice that does something: the wheel is gone first, then the game's own action
function D.take(pn, e)
    D.state[pn] = nil
    local p = getSpecificPlayer(pn)
    if not (p and e and e.run) then return end
    local ok, err = pcall(e.run, p, pn)
    if not ok then print("[ZeD] DpadWheels: " .. tostring(e.name) .. ": " .. tostring(err)) end
end

-- ---------------------------------------------------------------------------
-- opening (the four onDisplay* functions)
-- ---------------------------------------------------------------------------
local function paused()
    local sc = UIManager.getSpeedControls()
    return sc ~= nil and sc:getCurrentGameSpeed() == 0
end

-- a ZeD window holding the pad (a menu or prompt let the focus go): the press
-- is that window's, never a wheel (Oct 23 2026, from the belt's D-pad Left)
local function windowTakes(dir, joypadData)
    local F = ZeD.Input and ZeD.Input.Focus
    local fw = F and F.getFocusedWindow and F.getFocusedWindow()
    if fw and fw:isVisible() and not fw.windowShaded then
        F.reclaimEngineFocus()
        pcall(F.dispatchJoypadDir, fw, dir, joypadData)
        return true
    end
    return false
end

-- menu: the wheel object (the shared D-pad wheel, or the Select wheel);
-- engineShows: the game adds it to the screen and gives it the pad itself
function D.open(dir, joypadData, menu, engineShows)
    local pn = joypadData and joypadData.player or 0
    local p = getSpecificPlayer(pn)
    if not p or p:isDead() then return end
    local d = D.DIRS[dir]
    menu = menu or getPlayerRadialMenu(pn)
    local st = { dir = dir, held = true, path = {}, menu = menu, home = menu, engineShows = engineShows }
    st.path[1] = { title = ZeD.tr(d.title), entries = safe(D.B[d.build], p, pn) or {} }
    D.state[pn] = st
    show(pn)
end

-- the game's functions, kept for safe mode
D.orig = D.orig or {}

-- the game's own wheels: safe mode, ZeD not drawn yet, or the Tutorial (it
-- teaches the game's controls and steps the game's Select wheel)
function D.gameWheels()
    if ZeD.Safe.on() or not (ZeD.T and ZeD.T.px) then return true end
    return getCore():getGameMode() == "Tutorial"
end
local HOOKS = { left = "onDisplayLeft", right = "onDisplayRight", up = "onDisplayUp", down = "onDisplayDown" }

local function apply()
    if not ISDPadWheels or ISDPadWheels._zedDpad then return end
    ISDPadWheels._zedDpad = true
    for dir, fn in pairs(HOOKS) do
        local orig = ISDPadWheels[fn]
        D.orig[dir] = orig
        ISDPadWheels[fn] = function(joypadData)
            if D.gameWheels() then return orig(joypadData) end
            if windowTakes(dir, joypadData) then return end
            -- paused: only Here and now opens (Game speed, Play stays in reach)
            if dir ~= "down" and paused() then return end
            local ok, err = pcall(D.open, dir, joypadData)
            if not ok then print("[ZeD] DpadWheels: open " .. dir .. ": " .. tostring(err)) end
        end
    end
    -- the Select button: the game fills its wheel and shows it (JoyPadSetup);
    -- ZeD's wheel goes on that same object
    if ISBackButtonWheel and not ISBackButtonWheel._zedDpad then
        ISBackButtonWheel._zedDpad = true
        local origAdd = ISBackButtonWheel.addCommands
        D.orig.select = origAdd
        function ISBackButtonWheel:addCommands()
            if D.gameWheels() then return origAdd(self) end
            local ok, err = pcall(D.open, "select", { player = self.playerNum }, self, true)
            if not ok then
                print("[ZeD] DpadWheels: open select: " .. tostring(err))
                return origAdd(self)
            end
        end
    end
    -- an open inner wheel (or the top level after Back): A takes, B backs out
    local R = ISRadialMenu
    if R and not R._zedDpadKeys then
        R._zedDpadKeys = true
        local origDown = R.onJoypadDown
        function R:onJoypadDown(button, joypadData)
            local st = self._zedDpad
            if st and self._zed then
                local pn = self.playerNum or (joypadData and joypadData.player) or 0
                -- a bumper held: the button puts the pointed slice on that quick action chord (ZeD_QuickChords)
                local face = ({ [Joypad.AButton] = "A", [Joypad.BButton] = "B", [Joypad.XButton] = "X", [Joypad.YButton] = "Y",
                                [Joypad.LStickButton] = "L3", [Joypad.RStickButton] = "R3" })[button]
                local jid = joypadData and joypadData.id
                if face and jid then
                    local lb, rb = JoypadButton.LeftBump:isDown(jid), JoypadButton.RightBump:isDown(jid)
                    if lb ~= rb then D.assign(pn, self, (lb and "LB" or "RB") .. "+" .. face); return end
                end
                if button == Joypad.AButton then
                    local id = self.joyfocus and self.joyfocus.id or (joypadData and joypadData.id)
                    local i = W.sliceFromJoypad(self, id)
                    local cmd = i > 0 and self:getSliceCommand(i)
                    if cmd and cmd[1] then
                        if cmd[1] ~= D.enter and cmd[1] ~= D.back then D.state[pn] = nil; self:undisplay() end
                        W.noteChoice(self, self.slices[i])
                        cmd[1](cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7])
                    end
                    return
                elseif button == Joypad.BButton then
                    D.back(pn)
                    return
                elseif button == Joypad.XButton then
                    D.close(pn)
                    return
                end
                return
            end
            return origDown(self, button, joypadData)
        end
    end
    if not _G._zedDpadAnnounced then
        _G._zedDpadAnnounced = true
        print("[ZeD] DpadWheels: the D-pad's four wheels are ZeD's (Character, World, Social, Here and now)")
    end
end

D._apply = apply

-- (the wheels' contents follow; apply runs at the end of the file)

local function tr(k, ...) return ZeD.tr(k, ...) end
D.tr = tr

-- ============================================================================
-- SELECT: ZeD (theme, accent, text size, UI scale, moodles, action bar, reset
-- windows, ZeD setup, safe mode). The inner wheels mark the choice in use.
-- ============================================================================
local Z = {}
D.Z = Z

local function inUse(on) return on and tr("UI_ZeD_Wheel_InUse") or nil end

-- the theme, accent and text size go through ZeD.applyTheme and back into the
-- mod options, as the windows' footer controls do
function Z.theme(base, accent, size)
    ZeD.applyTheme(base or ZeD.currentBase, accent or ZeD.currentAccent, size or ZeD.currentSize)
    if ZeD.Settings and ZeD.Settings.syncToModOptions then ZeD.Settings.syncToModOptions() end
end

-- a combo option set as the options screen sets it, and saved
function Z.option(opt, i, apply)
    if not opt then return end
    pcall(function() opt:setValue(i) end)
    if apply then pcall(apply, i) end
    if ZeD.Settings and ZeD.Settings.save then ZeD.Settings.save() end
end

local function labelAt(list, i) return list and list[i] and tr(list[i]) or "?" end

function Z.themeWheel()
    local S, out = ZeD.Settings, {}
    for i, k in ipairs(S.baseKeys) do
        out[#out + 1] = { name = labelAt(S.baseLabels, i), icon = "settings", detail = inUse(ZeD.currentBase == k),
            run = function() Z.theme(k, nil, nil) end }
    end
    return out
end

function Z.accentWheel()
    local S, out = ZeD.Settings, {}
    local tone = (ZeD.currentBase == "light") and "light" or "dark"
    for i, k in ipairs(S.accentKeys) do
        local c = ZeD.AccentColors and ZeD.AccentColors[k] and ZeD.AccentColors[k][tone]
        out[#out + 1] = { name = labelAt(S.accentLabels, i), swatch = c and c.accent or nil, detail = inUse(ZeD.currentAccent == k),
            run = function() Z.theme(nil, k, nil) end }
    end
    return out
end

function Z.sizeWheel()
    local S, out = ZeD.Settings, {}
    for i, k in ipairs(S.sizeKeys) do
        out[#out + 1] = { name = labelAt(S.sizeLabels, i), icon = "text-box-dots", detail = inUse(ZeD.currentSize == k),
            run = function() Z.theme(nil, nil, k) end }
    end
    return out
end

function Z.scaleWheel()
    local S, out = ZeD.Settings, {}
    local cur = S.uiScaleOption and S.uiScaleOption:getValue() or 1
    for i = 1, #S.scaleKeys do
        local name = (i == 1) and tr(S.scaleLabels[1]) or S.scaleLabels[i]   -- (the steps are numbers, as the options show them)
        out[#out + 1] = { name = name, icon = "magnifying-glass-eye", detail = inUse(cur == i),
            run = function() Z.option(S.uiScaleOption, i, S.applyScale) end }
    end
    return out
end

local function comboWheel(opt, labels, icon)
    local out = {}
    local cur = opt and opt:getValue() or 1
    for i, key in ipairs(labels) do
        out[#out + 1] = { name = tr(key), icon = icon, detail = inUse(cur == i), run = function() Z.option(opt, i) end }
    end
    return out
end

function Z.moodleWheel()
    local S = ZeD.Settings
    return comboWheel(S.moodlePlaceOption, S.moodleLabels or { "UI_ZeD_Settings_MoodlesRight", "UI_ZeD_Settings_MoodlesLeft", "UI_ZeD_Settings_MoodlesBottom" }, "smile")
end

function Z.actionBarWheel()
    return comboWheel(ZeD.Settings.actionBarOption, { "UI_ZeD_Settings_ActionBarVerbose", "UI_ZeD_Settings_ActionBarSimple" }, "clock")
end

-- the label of a combo's choice, for the top level's second line
local function current(opt, labels)
    local i = opt and opt:getValue()
    return i and labels[i] and tr(labels[i]) or nil
end

function Z.resetWindows()
    if ZeD_Window and ZeD_Window.resetLayout then ZeD_Window.resetLayout() end
end

-- safe mode, after the player says yes in a prompt that says how to come back
function Z.safeMode(p, pn)
    local function onAnswer(_, button)
        if not (button and button.internal == "YES") then return end
        local S = ZeD.Settings
        Z.option(S.safeModeOption, 2)
        if ZeD.Safe and ZeD.Safe.reread then ZeD.Safe.reread() end
    end
    local modal = ISModalDialog:new(0, 0, 350, 150, tr("UI_ZeD_Wheel_SafeModeAsk"), true, nil, onAnswer, pn)
    modal:initialise()
    modal:addToUIManager()
    if JoypadState.players[pn + 1] then setJoypadFocus(pn, modal) end
end

D.B.zed = function(p, pn)
    local S = ZeD.Settings
    if not S then return {} end
    local tone = (ZeD.currentBase == "light") and "light" or "dark"
    local ac = ZeD.AccentColors and ZeD.AccentColors[ZeD.currentAccent]
    local function at(keys, labels, k) for i, x in ipairs(keys) do if x == k then return tr(labels[i]) end end return nil end
    return {
        { name = tr("UI_ZeD_Settings_BaseTheme"), icon = "settings", detail = at(S.baseKeys, S.baseLabels, ZeD.currentBase), sub = Z.themeWheel },
        { name = tr("UI_ZeD_Settings_AccentColor"), swatch = ac and ac[tone] and ac[tone].accent or nil,
          detail = at(S.accentKeys, S.accentLabels, ZeD.currentAccent), sub = Z.accentWheel },
        { name = tr("UI_ZeD_Settings_TextSize"), icon = "text-box-dots", detail = at(S.sizeKeys, S.sizeLabels, ZeD.currentSize), sub = Z.sizeWheel },
        { name = tr("UI_ZeD_Settings_UiScale"), icon = "magnifying-glass-eye", sub = Z.scaleWheel },
        { name = tr("UI_ZeD_Settings_Moodles"), icon = "smile", detail = current(S.moodlePlaceOption, S.moodleLabels or {}), sub = Z.moodleWheel },
        { name = tr("UI_ZeD_Settings_ActionBar"), icon = "clock",
          detail = current(S.actionBarOption, { "UI_ZeD_Settings_ActionBarVerbose", "UI_ZeD_Settings_ActionBarSimple" }), sub = Z.actionBarWheel },
        -- Messages (MESSAGES_SPEC.md): other mods' notes and errors; off while nothing is kept
        (function()
            local MS = ZeD.Messages
            local n, un = MS and MS.count() or 0, MS and MS.unread() or 0
            return { name = tr("UI_ZeD_Msg_Title"), icon = "inbox-in",
                     detail = (n > 0) and tr(un > 0 and "UI_ZeD_Msg_New" or "UI_ZeD_Msg_CountStat", un > 0 and un or n) or nil,
                     run = (n > 0) and function(pl, pn2) MS.open() end or nil, off = (n == 0) and tr("UI_ZeD_Msg_None") or nil }
        end)(),
        { name = tr("UI_ZeD_Wheel_ResetWindows"), icon = "rotate-left", detail = tr("UI_ZeD_Wheel_ResetWindowsDetail"), run = Z.resetWindows },
        { name = tr("UI_ZeD_Options_GroupZed"), icon = "gears", detail = tr("UI_ZeD_Wheel_ZeDSetupDetail"), run = function(pl, n) D.H.openSetup(pl, n) end },
        { name = tr("UI_ZeD_Settings_SafeMode"), icon = "bolt-slash", detail = tr("UI_ZeD_Wheel_SafeModeDetail"), run = Z.safeMode },
    }
end

-- ============================================================================
-- helpers the wheels share (filled in below)
-- ============================================================================
D.H = D.H or {}
local H = D.H

-- the pair open on a Character tab, the pad in the Character window
function H.charTab(p, pn, id)
    if not (ZeD_CharacterWindow and ZeD_CharacterWindow.ensureBothOpenForGamepad) then return end
    pcall(ZeD_CharacterWindow.ensureBothOpenForGamepad, pn)
    local tries = 0
    local function tick()
        tries = tries + 1
        local win = ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
        local strip = win and win._tabStripPanel
        local done = false
        if win and win._activeTab == id and win._drawerOpen ~= false then done = true
        elseif strip and strip._hitZones then
            for _, z in ipairs(strip._hitZones) do
                if z.id == "tab:" .. id then strip:onMouseDown(z.x + 2, z.y + 2); done = true; break end
            end
        end
        if done or tries >= 30 then
            Events.OnTick.Remove(tick)
            local F = ZeD.Input and ZeD.Input.Focus
            if win and F and F.claimFocus and JoypadState.players[pn + 1] then pcall(F.claimFocus, win) end
        end
    end
    Events.OnTick.Add(tick)
end

-- the pair open on a World tab, the pad in the World window
function H.worldTab(p, pn, id)
    if ZeD_CharacterWindow and ZeD_CharacterWindow.ensureBothOpenForGamepad then pcall(ZeD_CharacterWindow.ensureBothOpenForGamepad, pn) end
    if ZeD_WorldWindow and ZeD_WorldWindow.openTab then pcall(ZeD_WorldWindow.openTab, pn, id) end
    local tries = 0
    local function tick()
        tries = tries + 1
        if tries < 3 then return end
        Events.OnTick.Remove(tick)
        local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
        local F = ZeD.Input and ZeD.Input.Focus
        if win and F and F.claimFocus and JoypadState.players[pn + 1] then pcall(F.claimFocus, win) end
    end
    Events.OnTick.Add(tick)
end

-- what the character carries (the main inventory and the bags in it / worn)
function H.carried(p)
    local out = {}
    local function scan(c, depth)
        local items = c and safe(function() return c:getItems() end)
        if not items then return end
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            out[#out + 1] = it
            if depth < 2 and instanceof(it, "InventoryContainer") then scan(safe(function() return it:getInventory() end), depth + 1) end
        end
    end
    scan(p:getInventory(), 0)
    return out
end

-- one of the quick wheel's lists (ZeD_QuickWheel.lua) as entries: one per kind, the best first
function H.quick(p, gid)
    local Q = ZeD.QuickWheel
    local g = Q and Q.group and Q.group(gid)
    if not g then return {} end
    local out = {}
    for _, k in ipairs(Q.collect(p, g)) do
        local name = safe(function() return k.item:getDisplayName() end) or "?"
        if k.n > 1 then name = name .. "  x" .. k.n end
        local item = k.item
        out[#out + 1] = { name = name, tex = safe(function() return item:getTex() end), detail = H.itemDetail(p, item, gid),
            key = safe(function() return item:getFullType() end), run = function(pl) g.act(pl, item) end }
    end
    return out
end

-- the bubble's second line for a thing you carry: where it is, how fresh, how much
function H.itemDetail(p, item, gid)
    if gid == "eat" then
        if safe(function() return item:isRotten() end) then return getText("Tooltip_food_Rotten") end
        if safe(function() return item:isFresh() end) then return getText("Tooltip_food_Fresh") end
        if safe(function() return item:getOffAge() and item:getOffAge() < 1e6 end) then return getText("Tooltip_food_Stale") end
        return nil
    elseif gid == "drink" then
        local fc = safe(function() return item:getFluidContainer() end)
        local amt = fc and safe(function() return fc:getAmount() end)
        if amt and amt > 0 then return string.format("%.1f L", amt) end
        return nil
    end
    local c = safe(function() return item:getContainer() end)
    if c and c ~= p:getInventory() then
        local owner = safe(function() return c:getContainingItem() end)
        if owner then return safe(function() return owner:getDisplayName() end) end
    end
    return nil
end

-- the weapons you carry (vanilla's D-pad Left list: the main inventory), one per kind, best condition first
function H.weapons(p)
    local kinds, order = {}, {}
    local hb = ZeD.Belt and ZeD.Belt.hotbar and safe(ZeD.Belt.hotbar, p:getPlayerNum())
    local items = p:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if instanceof(it, "HandWeapon") and it:getCondition() > 0 then
            local ft = it:getFullType()
            local k = kinds[ft]
            if not k then k = { item = it, n = 0 }; kinds[ft] = k; order[#order + 1] = k end
            k.n = k.n + 1
            if p:isEquipped(it) or it:getCondition() > k.item:getCondition() then k.item = it end
        end
    end
    local out = {}
    for _, k in ipairs(order) do
        local it = k.item
        local name = it:getDisplayName() .. ((k.n > 1) and ("  x" .. k.n) or "")
        local where
        if p:getPrimaryHandItem() == it or p:getSecondaryHandItem() == it then where = tr("UI_ZeD_Wheel_InYourHands")
        elseif hb and safe(function() return hb:isItemAttached(it) end) then
            local slot = safe(function() return it:getAttachedSlot() end)
            where = slot and slot >= 0 and tr("UI_ZeD_Wheel_BeltSlot", slot + 1) or tr("UI_ZeD_Wheel_OnTheBelt")
        end
        out[#out + 1] = { name = name, tex = it:getTex(), detail = where, key = it:getFullType(), run = function(pl) ISDPadWheels.onEquipPrimary(pl, it) end }
    end
    return out
end

-- both hands empty (vanilla's unequip, the hand items into the bag)
function H.handsFree(p)
    local a, b = p:getPrimaryHandItem(), p:getSecondaryHandItem()
    if a then ISTimedActionQueue.add(ISUnequipAction:new(p, a, 50)) end
    if b and b ~= a then ISTimedActionQueue.add(ISUnequipAction:new(p, b, 50)) end
end

-- the brightest light you carry (vanilla's onDisplayLeft rule: an equipped or attached one first),
-- the bags you carry included (Oct 24 2026: a torch in the backpack is the one LB + X pulls out)
function H.bestLight(p)
    local best, bestEq
    local function look(items, inBag)
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if safe(function() return it:canEmitLight() end) then
                if not best or best:getLightStrength() < it:getLightStrength() then best = it end
                if not inBag and (p:isEquipped(it) or safe(function() return p:isAttachedItem(it) end)) then
                    if not bestEq or bestEq:getLightStrength() < it:getLightStrength() then bestEq = it end
                end
            elseif not inBag and instanceof(it, "InventoryContainer") then
                look(it:getInventory():getItems(), true)
            end
        end
    end
    look(p:getInventory():getItems(), false)
    return bestEq or best
end

-- the light in a hand and on in one go (director, Oct 24 2026: "pulling out a flashlight and
-- turning it on LB+X and it was on"). In a hand or on the belt: vanilla's toggle. Else vanilla's
-- equip (its time; out of a bag first, vanilla's move), and the light switched on once it is in
-- the hand; vanilla's toggle only equips, a second press switched it on.
function H.lightOn(p, l)
    -- (vanilla's own rule; its isEquippedOrAttached is local to ISDPadWheels.lua)
    if p:isEquipped(l) or p:isAttachedItem(l) then ISDPadWheels.onToggleLight(p, l); return end
    if l:getContainer() ~= p:getInventory() then ISInventoryPaneContextMenu.transferIfNeeded(p, l) end
    local a = ISEquipWeaponAction:new(p, l, 50, false)
    local perform = a.perform
    a.perform = function(self, ...)
        local r = perform(self, ...)
        local n = 0
        local function on()
            n = n + 1
            local held = p:isEquipped(l)
            if not held and n <= 30 then return end   -- (the hand is set when the action completes)
            Events.OnTick.Remove(on)
            if held and not l:isActivated() then
                l:setActivated(true)
                syncItemActivated(p, l)
                l:playActivateDeactivateSound()
            end
        end
        Events.OnTick.Add(on)
        return r
    end
    ISTimedActionQueue.add(a)
end

-- the game's speed controls, as the game's Select wheel works them
function H.speed(button) local sc = UIManager.getSpeedControls(); if sc then sc:ButtonClicked(button) end end

-- a helper that may not be there yet (filled below, or missing on this build): its result, else nil
local function ask(name, ...)
    local f = H[name]
    if not f then return nil end
    return safe(f, ...)
end

-- ============================================================================
-- LEFT: CHARACTER
-- ============================================================================
local C = {}
D.C = C

function C.tabs(p, pn)
    local out = {}
    local win = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
    for _, tab in ipairs(ZeD_CharacterWindow and ZeD_CharacterWindow.TABS or {}) do
        local name = ZeD_CharacterWindow.tabLabel(tab)
        local e = { name = name, tab = tab.iconName, key = tab.id, run = function(pl, n) H.charTab(pl, n, tab.id) end }
        if tab.id == "radio" then
            -- (the window's own list is stale while it is shut: the Radio tab's rule asked directly)
            if not H.hasRadio(p) then e.off = tr("UI_ZeD_Wheel_NoRadioOnYou") end
        elseif tab.visible and not (win and ZeD_CharacterWindow.isTabVisible(tab, win)) then
            e.off = tr("UI_ZeD_Wheel_NotNow")
        end
        out[#out + 1] = e
    end
    return out
end

function C.weapons(p, pn)
    local out = H.weapons(p)
    while #out > 10 do out[#out] = nil end   -- (Hands free and Back after them)
    out[#out + 1] = { name = tr("UI_ZeD_Wheel_HandsFree"), icon = "backpack", detail = tr("UI_ZeD_Wheel_HandsFreeDetail"), key = "handsfree", run = H.handsFree,
        off = (not p:getPrimaryHandItem() and not p:getSecondaryHandItem()) and tr("UI_ZeD_Wheel_HandsAlreadyFree") or nil }
    return out
end

function C.medicine(p, pn)
    local out = H.quick(p, "pills")
    for _, e in ipairs(ask("treatments", p, pn) or {}) do out[#out + 1] = e end
    while #out > 10 do out[#out] = nil end   -- (the Health tab and Back after them)
    out[#out + 1] = { name = ZeD_CharacterWindow.tabLabel(ZeD_CharacterWindow.TABS[3]), tab = "health-tab-white", detail = tr("UI_ZeD_Wheel_EveryWound"), key = "health",
        run = function(pl, n) H.charTab(pl, n, "health") end }
    return out
end

-- a quick action chord's pick (ZeD_QuickChords): the worst wound's treatment first, as the list puts
-- them in the wound's order, then the first medicine
function C.medicinePick(p, pn)
    for _, e in ipairs(ask("treatments", p, pn) or {}) do if e.run and not e.off then return e end end
    for _, e in ipairs(H.quick(p, "pills")) do if e.run and not e.off then return e end end
    return nil
end

function C.clothing(p, pn)
    local out = ask("clothing", p, pn) or {}
    while #out > 10 do out[#out] = nil end
    out[#out + 1] = { name = ZeD_CharacterWindow.tabLabel(ZeD_CharacterWindow.TABS[2]), tab = "equipment-tab-white", detail = tr("UI_ZeD_Wheel_EverythingYouWear"), key = "equip",
        run = function(pl, n) H.charTab(pl, n, "equip") end }
    return out
end

function C.use(p, pn)
    local smoke, read = H.quick(p, "smoke"), H.quick(p, "read")
    local watch, radio = ask("watch", p, pn), ask("radio", p, pn)
    local readOff = nil
    if #read == 0 then
        readOff = safe(function() return p:tooDarkToRead() end) and getText("ContextMenu_TooDark") or tr("UI_ZeD_Wheel_NothingToRead")
    end
    return {
        { name = getText("ContextMenu_Smoke"), icon = "smoking", best = true, sub = function() return H.quick(p, "smoke") end,
          off = (#smoke == 0) and tr("UI_ZeD_Wheel_NothingToSmoke") or nil },
        { name = getText("ContextMenu_Read"), icon = "book-open-reader", best = true, sub = function() return H.quick(p, "read") end, off = readOff },
        { name = tr("UI_ZeD_Wheel_Watch"), icon = "clock", sub = function() return ask("watch", p, pn) or {} end,
          off = not (watch and #watch > 0) and tr("UI_ZeD_Wheel_NoWatch") or nil },
        { name = getText("IGUI_ItemType_Radio"), icon = "survival-077-radio", sub = function() return ask("radio", p, pn) or {} end,
          off = not (radio and #radio > 0) and tr("UI_ZeD_Wheel_NoRadioOnYou") or nil },
    }
end

D.B.character = function(p, pn)
    local weapons, eat, drink = H.weapons(p), H.quick(p, "eat"), H.quick(p, "drink")
    local pills = H.quick(p, "pills")
    local treat = ask("treatments", p, pn) or {}
    local sleep = ask("sleep", p, pn) or { off = tr("UI_ZeD_Wheel_NotNow") }
    local clothing = ask("clothing", p, pn) or {}
    local hurt = ZeD.QuickWheel and ZeD.QuickWheel.hurt and ZeD.QuickWheel.hurt(p)
    return {
        { name = tr("UI_ZeD_Wheel_Tabs"), tab = "loot-tab-white", detail = tr("UI_ZeD_Wheel_CharacterWindow"), sub = C.tabs },
        { name = tr("UI_ZeD_Wheel_Weapons"), icon = "knife", best = true, sub = C.weapons, off = (#weapons == 0) and tr("UI_ZeD_Wheel_NoWeapon") or nil },
        { name = getText("ContextMenu_Eat"), icon = "apple-whole", best = true, sub = function() return H.quick(p, "eat") end,
          off = (#eat == 0) and ((ZeD.QuickWheel.tooFull and ZeD.QuickWheel.tooFull(p)) and getText("Tooltip_CantEatMore")
              or tr("UI_ZeD_Wheel_NothingToEat")) or nil },
        { name = getText("ContextMenu_Drink"), icon = "water-045-drink", best = true, sub = function() return H.quick(p, "drink") end,
          off = (#drink == 0) and tr("UI_ZeD_Wheel_NothingToDrink") or nil },
        { name = tr("UI_ZeD_Wheel_Medicine"), icon = "bandage-wound", sub = C.medicine, pick = C.medicinePick,
          off = (#pills == 0 and #treat == 0 and not hurt) and tr("UI_ZeD_Wheel_NothingToTreat") or nil },
        { name = getText("ContextMenu_Sleep"), icon = "bed", detail = sleep.detail, off = sleep.off, run = sleep.run },
        { name = tr("UI_ZeD_Wheel_Clothing"), icon = "fi-br-shirt-long-sleeve", sub = C.clothing,
          off = (#clothing == 0) and tr("UI_ZeD_Wheel_NothingToChange") or nil },
        { name = tr("UI_ZeD_Wheel_Use"), icon = "backpack", detail = tr("UI_ZeD_Wheel_UseDetail"), sub = C.use },
    }
end

-- ============================================================================
-- RIGHT: WORLD
-- ============================================================================
local Wd = {}
D.Wd = Wd

function Wd.tabs(p, pn)
    local out = {}
    local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    for _, tab in ipairs(ZeD_WorldWindow and ZeD_WorldWindow.TABS or {}) do
        local e = { name = ZeD_WorldWindow.tabLabel(tab), tab = tab.iconName, key = tab.id, run = function(pl, n) H.worldTab(pl, n, tab.id) end }
        -- (the contextual tabs asked by their own rules: the window's lists are stale while it is shut)
        if tab.id == "radio" then
            local list = ZeD.RadioTab and ZeD.RadioTab.buildWorldRadios and safe(ZeD.RadioTab.buildWorldRadios, p)
            if not (list and #list > 0) then e.off = tr("UI_ZeD_Wheel_NoRadioInReach") end
        elseif tab.id == "vehicle" then
            local list = ZeD.MechanicsTab and ZeD.MechanicsTab.buildVehicles and safe(ZeD.MechanicsTab.buildVehicles, p)
            if not (list and #list > 0) then e.off = tr("UI_ZeD_Wheel_NoVehicle") end
        elseif tab.visible and win and not ZeD_WorldWindow.isTabVisible(tab, win) then
            e.off = tr("UI_ZeD_Wheel_NotNow")
        end
        out[#out + 1] = e
    end
    return out
end

function Wd.map(p, pn)
    local mini = getPlayerMiniMap and getPlayerMiniMap(pn)
    local noMini = (not mini) and tr("UI_ZeD_Wheel_NoMiniMap") or nil
    local noMap = not (ISWorldMap and ISWorldMap.IsAllowed and ISWorldMap.IsAllowed())
    return {
        { name = getText("IGUI_WorldMap_Toggle"), icon = "crafting-game-037-map", run = function(pl, n) ISWorldMap.ToggleWorldMap(n) end,
          off = noMap and tr("UI_ZeD_Wheel_NoWorldMap") or nil },
        { name = getText("IGUI_MiniMap_Toggle"), icon = "fi-br-map-point", run = function(pl, n) ISMiniMap.ToggleMiniMap(n) end, off = noMini },
        { name = getText("IGUI_MiniMap_Focus"), icon = "map-marker", run = function(pl, n) ISMiniMap.FocusMiniMap(n) end, off = noMini },
    }
end

function Wd.craft(p, pn)
    -- Crafting at the nearest station in reach, named ("Workbench, 2 tiles"); else by hand
    local st = ask("nearestStation", p, pn)
    local S = ZeD.Stations
    local detail = st and (tostring(st.name) .. ", " .. tostring(S.tilesText and S.tilesText(st.dist) or "")) or nil
    local craftRun = function(pl, n) H.worldTab(pl, n, "craft") end
    if st and S and S.open then
        craftRun = function(pl, n)
            if ZeD_CharacterWindow and ZeD_CharacterWindow.ensureBothOpenForGamepad then pcall(ZeD_CharacterWindow.ensureBothOpenForGamepad, n) end
            S.open(pl, st.obj)
        end
    end
    return {
        { name = getText("IGUI_CraftingWindow_Title"), tab = "craft-tab-white", detail = detail, run = craftRun },
        { name = tr("UI_ZeD_World_TabBuilding"), tab = "build-tab-white", run = function(pl, n) H.worldTab(pl, n, "build") end },
        { name = getText("IGUI_BackButton_Movable"), tab = "move-tab-white", run = function(pl, n) H.worldTab(pl, n, "furniture") end },
    }
end

-- the game's Select wheel's search commands (search mode, a found item), and the Foraging tab
function Wd.search(p, pn)
    local m = ISSearchManager and safe(ISSearchManager.getManager, p)
    local on = m and m.isSearchMode
    local found = nil
    if m and m.closeIcons then for _, icon in pairs(m.closeIcons) do found = icon; break end end
    local foundName = found and found.itemObj and safe(function() return found.itemObj:getDisplayName() end) or nil
    return {
        { name = getText(on and "UI_disable_search_mode" or "UI_enable_search_mode"), icon = "eye",
          run = function(pl) local mm = ISSearchManager.getManager(pl); if mm then mm:toggleSearchMode() end end,
          off = (not m) and tr("UI_ZeD_Wheel_NotNow") or nil },
        { name = getText("UI_investigate_area_window_show"), tab = "forage-tab-white", run = function(pl, n) H.worldTab(pl, n, "forage") end },
        { name = getText("IGUI_Pickup"), icon = "fi-br-picking-box", detail = foundName,
          run = function(pl)
              local mm = ISSearchManager.getManager(pl)
              if mm then for _, icon in pairs(mm.closeIcons) do icon:doForage(); break end end
          end,
          off = (not found) and tr("UI_ZeD_Wheel_NothingFound") or nil },
    }
end

D.B.world = function(p, pn)
    local vehicle = ask("vehicleInReach", p, pn)
    local animal = ask("animalInReach", p, pn)
    local lights = ask("lights", p, pn) or {}
    local anyLight = false
    for _, e in ipairs(lights) do if not e.off then anyLight = true end end
    return {
        { name = tr("UI_ZeD_Wheel_Tabs"), tab = "craft-tab-white", detail = tr("UI_ZeD_Wheel_WorldWindow"), sub = Wd.tabs },
        { name = tr("UI_ZeD_Wheel_Map"), icon = "crafting-game-037-map", sub = Wd.map },
        { name = tr("UI_ZeD_Wheel_Vehicle"), icon = "car-mechanic", fill = function(pl, n) ISVehicleMenu.showRadialMenu(pl); H.dashSlice(pl, n) end,
          off = (not vehicle) and tr("UI_ZeD_Wheel_NoVehicle") or nil },
        { name = tr("UI_ZeD_Wheel_Animal"), icon = "cow", fill = function(pl) AnimalContextMenu.showRadialMenu(pl) end,
          off = (not animal) and tr("UI_ZeD_Wheel_NoAnimal") or nil },
        { name = tr("UI_ZeD_Wheel_CraftBuild"), icon = "carpentry-015-toolbox", sub = Wd.craft },
        { name = tr("UI_ZeD_Wheel_Search"), icon = "fi-br-magnifying-glass-wave", sub = Wd.search },
        { name = tr("UI_ZeD_Wheel_LightsPower"), icon = "lightbulb-on", sub = function() return ask("lights", p, pn) or {} end,
          off = (not anyLight) and tr("UI_ZeD_Wheel_NoLights") or nil },
        -- (the spec's Zones and rooms: the rooms editor has no way in on 42.21, so the place is Designated zones itself)
        { name = getText("IGUI_Zone_Name"), icon = "map-marker", detail = tr("UI_ZeD_World_TabAnimals"),
          run = function(pl, n) ISDPadWheels.showAnimalZoneUI(n) end },
    }
end

-- ============================================================================
-- UP: SOCIAL
-- ============================================================================
local EMOTE_GROUPS = {
    { id = "friendly", key = "IGUI_Emote_Friendly", tex = "media/ui/emotes/thumbsup.png" },
    { id = "hostile",  key = "IGUI_Emote_Hostile",  tex = "media/ui/emotes/thumbsdown.png" },
    { id = "group",    key = "IGUI_Emote_Group",    tex = "media/ui/emotes/followme.png" },
    { id = "signal",   key = "IGUI_Emote_Signal",   tex = "media/ui/emotes/moveout.png" },
}

-- a server-only slice: off in single player, else the helper's run / reason
local function serverSlice(name, icon, h)
    local e = { name = name, icon = icon, detail = h and h.detail, run = h and h.run }
    if not isClient() then e.off = tr("UI_ZeD_Wheel_ServerOnly")
    elseif not e.run then e.off = (h and h.off) or tr("UI_ZeD_Wheel_NotNow") end
    return e
end

D.B.social = function(p, pn)
    local out = {}
    for _, g in ipairs(EMOTE_GROUPS) do
        out[#out + 1] = { name = getText(g.key), vanilla = g.tex, fill = function(pl)
            if not ISEmoteRadialMenu.menu then ISEmoteRadialMenu:init() end
            local erm = ISEmoteRadialMenu:new(pl)
            erm:fillMenu(g.id)
        end }
    end
    out[#out + 1] = { name = getText("IGUI_Emote_Shout"), icon = "bullhorn", run = function(pl) ISDPadWheels.onShout(pl) end }
    out[#out + 1] = serverSlice(tr("UI_ZeD_Wheel_Chat"), "text-box-dots", ask("chat", p, pn))
    out[#out + 1] = serverSlice(tr("UI_ZeD_Wheel_Safety"), "fi-br-lock", ask("safety", p, pn))
    out[#out + 1] = serverSlice(tr("UI_ZeD_Wheel_Players"), "handshake", ask("players", p, pn))
    return out
end

-- ============================================================================
-- DOWN: HERE AND NOW
-- ============================================================================
local N = {}
D.N = N

function N.speed(p, pn)
    local sc = UIManager.getSpeedControls()
    local cur = sc and sc:getCurrentGameSpeed() or 1
    local mult = safe(function() return getGameTime():getTrueMultiplier() end) or 1
    local playing = cur ~= 0 and mult <= 1
    return {
        { name = getText(cur == 0 and "IGUI_BackButton_Play" or "UI_optionscreen_binding_Pause"),
          vanilla = (cur == 0) and "media/ui/speedControls/Play_Off.png" or "media/ui/speedControls/Pause_Off.png",
          detail = inUse(playing),
          run = function()
              local s = UIManager.getSpeedControls()
              if not s then return end
              if s:getCurrentGameSpeed() == 0 or getGameTime():getTrueMultiplier() > 1 then H.speed("Play") else H.speed("Pause") end
          end },
        { name = getText("IGUI_BackButton_FF1"), vanilla = "media/ui/speedControls/FFwd1_Off.png", detail = inUse(cur ~= 0 and mult == 5),
          run = function() H.speed("Fast Forward x 1") end },
        { name = getText("IGUI_BackButton_FF2"), vanilla = "media/ui/speedControls/FFwd2_Off.png", detail = inUse(cur ~= 0 and mult == 20),
          run = function() H.speed("Fast Forward x 2") end },
        { name = getText("IGUI_BackButton_FF3"), vanilla = "media/ui/speedControls/Wait_Off.png", detail = inUse(cur ~= 0 and mult == 40),
          run = function() H.speed("Wait") end },
    }
end

function N.zoom(p, pn)
    local core = getCore()
    local off = core:getAutoZoom(pn) and tr("UI_ZeD_Wheel_AutoZoom") or nil
    return {
        { name = getText("IGUI_BackButton_Zoom", math.floor(core:getNextZoom(pn, -1) * 100)), vanilla = "media/ui/ZoomIn.png",
          run = function(pl, n) getCore():doZoomScroll(n, -1) end, off = off },
        { name = getText("IGUI_BackButton_Zoom", math.floor(core:getNextZoom(pn, 1) * 100)), vanilla = "media/ui/ZoomOut.png",
          run = function(pl, n) getCore():doZoomScroll(n, 1) end, off = off },
    }
end

function N.view(p, pn)
    return {
        { name = tr((ISUIHandler and ISUIHandler.allUIVisible == false) and "UI_ZeD_Wheel_ShowInterface" or "UI_ZeD_Wheel_HideInterface"),
          icon = "eye", detail = tr("UI_ZeD_Wheel_HideInterfaceDetail"),
          run = function(pl, n) ask("hideInterface", pl, n) end },
        { name = tr("UI_ZeD_Wheel_ResetWindows"), icon = "rotate-left", detail = tr("UI_ZeD_Wheel_ResetWindowsDetail"), run = Z.resetWindows },
        { name = tr("UI_ZeD_Settings_TextSize"), icon = "text-box-dots", sub = Z.sizeWheel },
        { name = getText("UI_mainscreen_option"), icon = "gears", detail = tr("UI_ZeD_Wheel_ZeDSetupDetail"),
          run = function(pl, n) ask("openSetup", pl, n) end },
    }
end

function N.help(p, pn)
    return {
        { name = getText("UI_optionscreen_binding_Toggle Survival Guide"), icon = "info-guide", run = function(pl, n) ISDPadWheels.showSurvGuide(n) end },
        -- (v1: no screen for the controller map yet, DPAD_WHEELS_SPEC section 6)
        { name = tr("UI_ZeD_Wheel_ControllerMap"), icon = "question", off = tr("UI_ZeD_Wheel_ComingLater") },
    }
end

function N.sit(p, pn)
    return ask("sitWheel", p, pn) or {}
end

-- a slice from a helper that returns { run, detail, tex, off }, off in a vehicle
local function stanceSlice(name, h, carOff)
    h = h or {}
    local e = { name = name, detail = h.detail, run = h.run }
    if h.tex then e.tex = h.tex else e.icon = "fi-br-person-walking-arrow-right" end
    if carOff then e.off = carOff elseif not e.run then e.off = h.off or tr("UI_ZeD_Wheel_NotNow") end
    return e
end

D.B.now = function(p, pn)
    local carOff = (p:getVehicle() ~= nil) and tr("UI_ZeD_Wheel_InVehicle") or nil
    local light = H.bestLight(p)
    local lightDetail = nil
    if light then lightDetail = getText(light:isActivated() and "ContextMenu_Turn_Off" or "ContextMenu_Turn_On") end
    local speedOff = (isClient() or not UIManager.getSpeedControls()) and tr("UI_ZeD_Wheel_ServerTime") or nil
    local out = {
        { name = tr("UI_ZeD_Wheel_Sit"), icon = "sitting-ground", sub = N.sit, off = carOff },
        stanceSlice(tr("UI_ZeD_Wheel_Crouch"), ask("crouch", p, pn), carOff),
        stanceSlice(tr("UI_ZeD_Wheel_AutoWalk"), ask("autoWalk", p, pn), carOff),
        { name = tr("UI_ZeD_Wheel_GameSpeed"), vanilla = "media/ui/speedControls/Pause_Off.png", sub = N.speed, off = speedOff },
        { name = tr("UI_ZeD_Wheel_Zoom"), vanilla = "media/ui/ZoomIn.png", sub = N.zoom,
          off = (not getCore():isZoomEnabled()) and tr("UI_ZeD_Wheel_NotNow") or nil },
        { name = tr("UI_ZeD_Wheel_View"), icon = "eye", detail = tr("UI_ZeD_Wheel_ViewDetail"), sub = N.view },
        { name = tr("UI_ZeD_Wheel_Help"), icon = "info-guide", sub = N.help },
        { name = light and light:getDisplayName() or tr("UI_ZeD_Wheel_Light"), icon = "lightbulb-on", detail = lightDetail,
          run = function(pl) local l = H.bestLight(pl); if l then H.lightOn(pl, l) end end,
          off = (not light) and tr("UI_ZeD_Wheel_NoLight") or nil },
    }
    -- the Last Stand mode's own button (the game's Select wheel had it)
    if Core.isLastStand and Core.isLastStand() then
        out[#out + 1] = { name = getText("IGUI_BackButton_LastStand"), tex = Joypad.Texture and Joypad.Texture.AButton,
            run = function(pl, n) JoypadState.players[n + 1].focus = nil; doLastStandBackButtonWheel(n, "s") end }
    end
    return out
end

-- ============================================================================
-- THE HELPERS THE SLICES ASK FOR (the game's own rules and verbs; API census
-- Oct 23 2026, ZeDUI/qa notes in DPAD_WHEELS_SPEC)
-- ============================================================================
local function vtext(key) return (tostring(getText(key)):gsub("<br>", " ")) end   -- (some of vanilla's reasons carry a line break)

-- a stand-in context menu that records what vanilla's builders add
local function recorder()
    local r = { options = {} }
    function r:addOption(name, target, onSelect, ...)
        local o = { name = name, target = target, onSelect = onSelect, n = select("#", ...), args = { ... } }
        self.options[#self.options + 1] = o
        return o
    end
    function r:addActionsOption(name, ...) return self:addOption(name, ...) end
    function r:getNew() return recorder() end
    function r:addSubMenu(option, child) option.sub = child end
    function r:isEmpty() return #self.options == 0 end
    function r:setVisible() end
    function r:getIsVisible() return false end
    return r
end

-- Medicine and first aid: for every part that wants care, what vanilla's
-- health panel offers (ISHealthPanel:doBodyPartContextMenu with ISContextMenu.get
-- answering the recorder), one slice per treatment, the part on the second line
function H.treatments(p, pn)
    if not (ISHealthPanel and ISHealthPanel.doBodyPartContextMenu and ISContextMenu) then return {} end
    local adapter = { character = p, otherPlayer = nil, blockingMessage = nil, actions = {} }
    function adapter:getDoctor() return self.character end
    function adapter:getAbsoluteX() return 0 end
    function adapter:getAbsoluteY() return 0 end
    adapter.checkItems = ISHealthPanel.checkItems
    adapter.checkContainerItems = ISHealthPanel.checkContainerItems
    local out = {}
    local origGet = ISContextMenu.get
    local parts = p:getBodyDamage():getBodyParts()
    for i = 0, parts:size() - 1 do
        local bp = parts:get(i)
        local wants = safe(function() return bp:HasInjury() or bp:bandaged() or bp:stitched() or bp:getSplintFactor() > 0 end)
        if wants then
            local rec = recorder()
            ISContextMenu.get = function() return rec end
            pcall(ISHealthPanel.doBodyPartContextMenu, adapter, bp, 0, 0)
            ISContextMenu.get = origGet
            local part = safe(function() return BodyPartType.getDisplayName(bp:getType()) end)
            local function leaves(opts, parent)
                for _, o in ipairs(opts) do
                    if o.sub then leaves(o.sub.options, o.name)
                    elseif o.onSelect and not o.notAvailable then
                        out[#out + 1] = { name = parent and (parent .. ": " .. tostring(o.name)) or tostring(o.name), detail = part, icon = "bandage-wound",
                            run = function() o.onSelect(o.target, unpack(o.args, 1, o.n)) end }
                    end
                end
            end
            leaves(rec.options)
        end
    end
    ISContextMenu.get = origGet
    return out
end

-- Sleep: the game's rules in its order (the vehicle wheel's, ISVehicleMenu
-- 190-227), its words for the reason; from where you stand, sit or lie
function H.sleep(p, pn)
    local function no(key) return { off = vtext(key) } end
    if isClient() and not getServerOptions():getBoolean("SleepAllowed") then return { off = tr("UI_ZeD_Wheel_NoSleepHere") } end
    local needed = (not isClient()) or getServerOptions():getBoolean("SleepNeeded")
    local stats = p:getStats()
    local fatigue = stats:get(CharacterStat.FATIGUE)
    local v = p:getVehicle()
    if needed and fatigue <= 0.3 then return no("IGUI_Sleep_NotTiredEnough") end
    if v and not v:isStopped() then return no("IGUI_PlayerText_CanNotSleepInMovingCar") end
    if needed and (stats:getNumVisibleZombies() > 0 or stats:getNumChasingZombies() > 0 or stats:getNumVeryCloseZombies() > 0) then return no("IGUI_Sleep_NotSafe") end
    if needed and (p:getHoursSurvived() - p:getLastHourSleeped()) <= 1 then return no("ContextMenu_NoSleepTooEarly") end
    if p:getSleepingTabletEffect() < 2000 then
        local m = p:getMoodles()
        if m:getMoodleLevel(MoodleType.PAIN) >= 2 and fatigue <= 0.85 then return no("ContextMenu_PainNoSleep") end
        if m:getMoodleLevel(MoodleType.PANIC) >= 1 then return no("ContextMenu_PanicNoSleep") end
    end
    if v then
        if safe(function() return v:isEngineRunning() end) then return no("ContextMenu_NoSleepEngineRunning") end
        return { detail = tr("UI_ZeD_Wheel_SleepInCar"), run = function(pl) ISVehicleMenu.onSleep(pl, pl:getVehicle()) end }
    end
    local seat = safe(function() return p:isSittingOnFurniture() and p:getSitOnFurnitureObject() end) or nil
    return { detail = seat and safe(getMoveableDisplayName, seat) or getText("ContextMenu_SleepOnGround"),
             run = function(pl, n) ISWorldObjectContextMenu.onSleep(seat, n) end }
end

-- Clothing: every worn thing's own options (hood up, open, tie...: vanilla's
-- doClothingItemExtraMenu lists them) and taking off headwear, a mask, glasses
local TAKE_OFF = { "HAT", "FULL_HAT", "MASK", "MASK_FULL", "MASK_EYES", "EYES" }
function H.clothing(p, pn)
    local out, seen = {}, {}
    local worn = p:getWornItems()
    for i = 0, worn:size() - 1 do
        local item = worn:get(i):getItem()
        local opts = item and safe(function() return item:getClothingItemExtraOption() end)
        local extras = item and safe(function() return item:getClothingItemExtra() end)
        if opts and extras and not item:isBroken() then
            for k = 0, opts:size() - 1 do
                local full = moduleDotType(item:getModule(), extras:get(k))
                out[#out + 1] = { name = getText("ContextMenu_" .. tostring(opts:get(k))), detail = item:getDisplayName(), tex = item:getTex(),
                    run = function(pl) ISInventoryPaneContextMenu.onClothingItemExtra(item, full, pl) end }
            end
        end
    end
    for _, loc in ipairs(TAKE_OFF) do
        local bl = ItemBodyLocation and ItemBodyLocation[loc]
        local item = bl and safe(function() return p:getWornItem(bl) end)
        if item and not seen[item] then
            seen[item] = true
            out[#out + 1] = { name = getText("ContextMenu_Unequip"), detail = item:getDisplayName(), tex = item:getTex(),
                run = function(pl, n) ISInventoryPaneContextMenu.unequipItem(item, n) end }
        end
    end
    return out
end

-- Watch (ZeD's watch, player one): the full watch, its light, its alarm
function H.watch(p, pn)
    local Wt = ZeD.Watch
    local inst = Wt and Wt.getInstance and Wt.getInstance()
    if pn ~= 0 or not (inst and inst._item) then return {} end
    local item = inst._item
    local belt = Wt.beltMode and Wt.beltMode()
    local alarm = safe(function() return string.format("%d:00 | %s", item:getHour(), getText(item:isAlarmSet() and "UI_On" or "UI_Off")) end)
    return {
        { name = tr("UI_ZeD_Wheel_OpenWatch"), icon = "clock", detail = item:getDisplayName(), run = function() Wt.togglePop(true) end,
          off = (not belt) and tr("UI_ZeD_Wheel_WatchAlwaysOpen") or nil },
        { name = tr("UI_ZeD_Wheel_WatchLight"), icon = "lightbulb-on", run = function() Wt.act("light") end,
          off = not (Wt.hasLight and Wt.hasLight(inst._def)) and tr("UI_ZeD_Wheel_WatchNoLight") or nil },
        { name = tr("UI_ZeD_Wheel_WatchAlarm"), icon = "essential-collection-213-alarm", detail = alarm, run = function() Wt.act("alarm") end },
    }
end

-- Radio: the radio you hold or carry on your back (the Radio tab's rule):
-- on / off, the next station, the Radio tab
function H.radio(p, pn)
    local R = ZeD.RadioTab
    local list = R and R.buildEquippedRadios and safe(R.buildEquippedRadios, p) or {}
    local r = list[1]
    if not r then return {} end
    local item, dd = r.radioInstance, r.deviceData
    local on = dd and safe(function() return dd:getIsTurnedOn() end)
    local mhz = dd and safe(function() return string.format("%.1f MHz", dd:getChannel() / 1000) end)
    return {
        { name = getText(on and "ContextMenu_Turn_Off" or "ContextMenu_Turn_On"), detail = item:getDisplayName(), tex = item:getTex(),
          run = function(pl) ZeD.RadioOps.power(pl, item) end },
        { name = tr("UI_ZeD_Wheel_NextStation"), icon = "fm-radio", detail = mhz, run = function(pl) ZeD.RadioOps.seek(pl, item, 1) end,
          off = (not on) and tr("UI_ZeD_Wheel_RadioIsOff") or nil },
        { name = ZeD_CharacterWindow.tabLabel(ZeD_CharacterWindow.TABS[8]), tab = "radio-tab-white", detail = tr("UI_ZeD_Wheel_EveryRadio"),
          run = function(pl, n) H.charTab(pl, n, "radio") end },
    }
end
function H.hasRadio(p)
    local R = ZeD.RadioTab
    local list = R and R.buildEquippedRadios and safe(R.buildEquippedRadios, p)
    return list ~= nil and #list > 0
end

-- the vehicle and the animal wheels' own tests (vanilla's key handler uses them)
function H.vehicleInReach(p)
    return ISVehicleMenu and ISVehicleMenu.getVehicleToInteractWith and ISVehicleMenu.getVehicleToInteractWith(p) ~= nil
end
function H.animalInReach(p)
    local a = AnimalContextMenu and AnimalContextMenu.getAnimalToInteractWith and AnimalContextMenu.getAnimalToInteractWith(p)
    return a ~= nil and not a:isWild()
end

-- the nearest crafting station in reach (ZeD.Stations: name, distance)
function H.nearestStation(p)
    local S = ZeD.Stations
    local list = S and S.nearby and safe(S.nearby, p)
    return list and list[1] or nil
end

-- a room's light switch in reach: you stand in a room with power, the switch on
-- your square or a side one (the controller prompt's rule, ISButtonPrompt 519)
function H.switchInReach(p)
    local sq = p:getCurrentSquare()
    if not (sq and sq:getRoom()) then return nil end
    local power = safe(function() return sq:haveElectricity() end)
        or safe(function() return SandboxVars.ElecShutModifier > -1 and getGameTime():getWorldAgeHours() / 24 + (getSandboxOptions():getTimeSinceApo() - 1) * 30 < SandboxVars.ElecShutModifier end)
    if not power then return nil end
    local function find(s)
        local objs = s and s:getObjects()
        for i = 0, (objs and objs:size() or 0) - 1 do
            local o = objs:get(i)
            if instanceof(o, "IsoLightSwitch") then return o end
        end
    end
    local o = find(sq)
    if o then return o end
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local s2 = getCell():getGridSquare(sq:getX() + d[1], sq:getY() + d[2], sq:getZ())
        if s2 and (s2:getRoom() == sq:getRoom() or safe(function() return s2:Is(IsoFlagType.solidtrans) end)) then
            o = find(s2)
            if o then return o end
        end
    end
    return nil
end

local function fireLit(f)
    if f.kind == "campfire" then
        pcall(function() f.obj:updateFromIsoObject() end)
        return f.obj.isLit == true
    end
    return safe(function() return f.obj:isLit() end) == true
end

-- Lights and power: the room's lights, a generator, a fire; each on / off
-- with vanilla's action, off with the reason when there is none in reach
function H.lights(p, pn)
    local out = {}
    local sw = H.switchInReach(p)
    out[#out + 1] = { name = tr("UI_ZeD_Wheel_RoomLights"), icon = "lightbulb-on",
        detail = sw and getText(sw:isActivated() and "ContextMenu_Turn_Off" or "ContextMenu_Turn_On") or nil,
        run = sw and function(pl) ISTimedActionQueue.add(ISToggleLightAction:new(pl, sw)) end or nil,
        off = (not sw) and tr("UI_ZeD_Wheel_NoSwitch") or nil }
    local OC = ZeD.ObjectCards
    local gk = OC and OC.kinds and OC.kinds.generator
    local gl = gk and gk.nearby and safe(gk.nearby, p) or {}
    local g = gl[1] and gl[1].obj
    local gOn = g and safe(function() return g:isActivated() end)
    local gCan = g and (gOn or safe(function() return g:isConnected() and g:getFuel() > 0 and g:getCondition() > 0 end))
    local gOff = nil
    if not g then gOff = tr("UI_ZeD_Wheel_NoGenerator")
    elseif not gCan then gOff = tr(safe(function() return g:getFuel() <= 0 end) and "UI_ZeD_Power_NeedFuel" or "UI_ZeD_Power_NeedConnected") end
    out[#out + 1] = { name = getText("ContextMenu_Generator"), icon = "doomsday-007-generator",
        detail = g and getText(gOn and "ContextMenu_Turn_Off" or "ContextMenu_Turn_On") or nil,
        run = gCan and function(pl, n) ISWorldObjectContextMenu.onActivateGenerator(nil, not gOn, g, n) end or nil, off = gOff }
    local fk = OC and OC.kinds and OC.kinds.fire
    local fl = fk and fk.nearby and safe(fk.nearby, p) or {}
    local f = fl[1]
    local lit = f and fireLit(f)
    local fireRun = nil
    if f and lit then
        fireRun = function(pl, n)
            if f.kind == "campfire" then ISCampingMenu.onPutOutCampfire(nil, pl, f.obj) else ISBBQMenu.onExtinguish(nil, n, f.obj) end
        end
    elseif f then
        -- (lighting needs a method: the fire's card lists them, with what each needs)
        fireRun = function(pl, n)
            if ZeD_CharacterWindow and ZeD_CharacterWindow.ensureBothOpenForGamepad then pcall(ZeD_CharacterWindow.ensureBothOpenForGamepad, n) end
            if ZeD_WorldWindow and ZeD_WorldWindow.openObjectCard then pcall(ZeD_WorldWindow.openObjectCard, n, { def = fk, t = f }) end
        end
    end
    out[#out + 1] = { name = getText(lit and "ContextMenu_Put_out_fire" or "ContextMenu_Light_fire"), icon = "campfire",
        detail = f and (lit and tr("UI_ZeD_Wheel_FireLit") or tr("UI_ZeD_Wheel_FireCard")) or nil, run = fireRun,
        off = (not f) and tr("UI_ZeD_Wheel_NoFire") or nil }
    return out
end

-- Sit: on the ground (or up again), on the nearest seat in reach (vanilla's Rest)
function H.nearestSeat(p)
    local OC = ZeD.ObjectCards
    if not (OC and OC.eachSquare and SeatingManager) then return nil end
    local best, bd
    OC.eachSquare(p, 3, function(sq)
        local objs = sq:getObjects()
        for i = 0, objs:size() - 1 do
            local o = objs:get(i)
            if safe(function() return SeatingManager.getInstance():getTilePositionCount(o) > 0 and not o:isFurnitureOccupied(p) end) then
                local d = math.max(math.abs(sq:getX() + 0.5 - p:getX()), math.abs(sq:getY() + 0.5 - p:getY()))
                if not bd or d < bd then best, bd = o, d end
            end
        end
    end)
    return best, bd and math.max(1, math.floor(bd + 0.5)) or nil
end
function H.sitWheel(p, pn)
    local sitting = safe(function() return p:isSitOnGround() or p:isSittingOnFurniture() end)
    local seat, d = H.nearestSeat(p)
    local seatName = seat and safe(getMoveableDisplayName, seat)
    return {
        { name = sitting and tr("UI_ZeD_Wheel_GetUp") or getText("ContextMenu_SitGround"),
          vanilla = sitting and "media/ui/emotes/sit_off.png" or "media/ui/emotes/sit_on.png",
          run = function(pl)
              if pl:isSitOnGround() or pl:isSittingOnFurniture() then pl:StopAllActionQueue(); pl:setVariable("forceGetUp", true)
              else pl:setAutoWalk(false); pl:reportEvent("EventSitOnGround") end
          end },
        { name = seatName and tr("UI_ZeD_Wheel_SitOn", seatName) or tr("UI_ZeD_Wheel_SitOnSeat"), icon = "chair",
          detail = d and ZeD.Stations and ZeD.Stations.tilesText and ZeD.Stations.tilesText(d) or nil,
          run = seat and function(pl, n) ISWorldObjectContextMenu.onRest(seat, n) end or nil,
          off = (not seat) and tr("UI_ZeD_Wheel_NoSeat") or nil },
    }
end

-- Crouch and auto-walk (the stick-click wheel's two toggles, its pictures)
function H.crouch(p)
    local on = p:isSneaking()
    return { tex = getTexture(on and "media/ui/emotes/crouch_off.png" or "media/ui/emotes/crouch_on.png"), detail = getText(on and "UI_On" or "UI_Off"),
             run = function(pl) pl:setSneaking(not pl:isSneaking()) end }
end
function H.autoWalk(p)
    local on = safe(function() return p:isAutoWalk() end)
    return { tex = getTexture(on and "media/ui/emotes/autowalk_off.png" or "media/ui/emotes/autowalk_on.png"), detail = getText(on and "UI_On" or "UI_Off"),
             run = function(pl) pl:setAutoWalk(not pl:isAutoWalk()) end }
end

-- the interface off until the same slice again (vanilla's Toggle UI)
function H.hideInterface() if ISUIHandler and ISUIHandler.toggleUI then ISUIHandler.toggleUI() end end

-- a step once the next frame has drawn (the pause screen's windows need one; OnTick stops while paused)
local function nextFrame(fn, frames)
    local n = 0
    local function f()
        n = n + 1
        if n < (frames or 2) then return end
        Events.OnPreUIDraw.Remove(f)
        pcall(fn)
    end
    Events.OnPreUIDraw.Add(f)
end

-- In the driver's seat, after the game's vehicle slices: Dashboard, the pad on the dash's
-- controls until B (director, Oct 24 2026: the dash no longer takes the D-pad when you sit
-- down). Its claim waits a frame, so the wheel's own close does not take the pad back.
function H.dashSlice(p, pn)
    local Dash = ZeD.Dashboard
    if not (Dash and Dash.canTakePad and Dash.canTakePad(p)) then return end
    addEntry(getPlayerRadialMenu(pn), pn, {
        name = getText("IGUI_VehiclePartCatdashboard"), icon = "fuel-gauge", detail = tr("UI_ZeD_Wheel_DashboardDetail"),
        run = function(pl) nextFrame(function() Dash.takePad(pl) end) end })
end

-- Options, on ZeD setup: the pause screen first (Options live in it), then ZeD's Options on its first page
function H.openSetup(p, pn)
    local MM = ZeD.MainMenu
    if not (MM and MM.openOptions) then return end
    if not (MainScreen and MainScreen.instance and MainScreen.instance:isVisible()) then ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end
    nextFrame(function()
        MM.openOptions()
        if MM.pauseOpts then MM.pauseOpts.pageIdx = 1; MM.pauseOpts.scroll = 0 end
    end, 3)
end

-- the server-only three (no server here to try them on: kept to the game's own calls)
function H.chat(p, pn)
    if not (ISChat and ISChat.instance) then return nil end
    return { detail = tr("UI_ZeD_Wheel_ChatDetail"), run = function() ISChat.instance:focus() end }
end
function H.safety(p, pn)
    if not (isClient() and safe(function() return getServerOptions():getBoolean("SafetySystem") end)) then return { off = tr("UI_ZeD_Wheel_NoSafetyHere") } end
    local s = p:getSafety()
    local allowed = safe(function() return s:isToggleAllowed() end)
    return { detail = getText(safe(function() return s:isEnabled() end) and "UI_On" or "UI_Off"),
             run = allowed and function(pl) local ss = pl:getSafety(); if ss:isToggleAllowed() then ss:toggleSafety() end end or nil,
             off = (not allowed) and tr("UI_ZeD_Wheel_SafetyWait") or nil }
end
function H.players(p, pn)
    local MM = ZeD.MainMenu
    if not (MM and MM.act and MM.act.players) then return nil end
    return { detail = tr("UI_ZeD_Wheel_PlayersDetail"), run = function()
        if not (MainScreen and MainScreen.instance and MainScreen.instance:isVisible()) then ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end
        nextFrame(function() MM.act.players() end, 3)
    end }
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
