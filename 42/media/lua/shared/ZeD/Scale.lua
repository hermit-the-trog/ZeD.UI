-- ZeD-UI/42/media/lua/shared/ZeD/Scale.lua
-- ============================================================================
-- ZeD.Scale — the root scale of the whole UI, the layer under the tokens
-- ============================================================================
-- The rule: the UI adapts to the resolution by itself; the engine's font-size
-- option is only an extra multiplier on top.
--
-- Design base: a 1920x1080 screen is 1.0. Every layout number in ZeD is a
-- DESIGN UNIT (1 unit = 1 px at 1080p); multiply by ZeD.Scale.root() at draw
-- time (ZeD.Scale.px does that with rounding). A 4K screen lands at 2.0, 1440p
-- at 1.33, a 720p window at 0.75 (clamped).
--
-- Text: the engine draws any font at any zoom (ISUIElement:drawTextZoomed) and
-- distance-field atlases stay crisp. ZeD.Text wraps that so organisms never
-- touch UIFont sizes directly: zoom = root scale, width = MeasureStringX * zoom.
-- The one thing to know before touching it: this file also replaces the global
-- getTextManager with ZeD.TM (at the bottom), so every measure of a ZeD role
-- font, vanilla's included, comes back zoomed.
--
-- Shared: this file loads on the client and on a dedicated server alike, so
-- nothing client-only at file scope. A server process loads no fonts, and
-- X.noFonts (below) keeps the font work off there.
--
-- QA: ZeD.Scale.override = 1.0 / 1.333 / 2.0 forces the root scale; call
-- ZeD.Scale.refresh() afterwards (or wait a second).
-- ============================================================================

-- Reload-safe: loading this file twice reuses the tables instead of wiping them
ZeD = ZeD or {}
ZeD.Scale = ZeD.Scale or {}
local S = ZeD.Scale

S.BASE_H   = 1080
S.MIN      = 0.75
S.MAX      = 4.0
S.override = S.override or nil
-- Fixed UI scale chosen in the mod options (0.5 .. 2.0); nil = Auto (fit the screen).
-- Absolute: 1.0 is the 1080p design size, so a 4K player can pick 1.5 instead of 2.0.
S.userScale = S.userScale or nil

-- Engine font-size option. getOptionFontSize() is the options combo's own
-- 1-based index: 1 = 16px, 2 = 19px, 3 = 26px, 4 = 33px, 5 = 38px,
-- 6 = "Scale with window height" (the game's default). It does not touch ZeD
-- fonts, so it becomes the player's taste knob. 19px (the setting the look was
-- tuned at), 26px and the adaptive choice are neutral; 16px shrinks the UI a
-- step, 33px and 38px grow it. Keyed 1..6 to match the combo: keyed 0..5,
-- every fixed size would read the step above it and 38px would fall back to
-- neutral.
S.USER_MUL = { [1] = 0.85, [2] = 1.0, [3] = 1.0, [4] = 1.15, [5] = 1.3, [6] = 1.0 }

S._root = nil
S._tick = 0

--- the engine font-size option's multiplier (USER_MUL), 1.0 when it can't be read
function S.userMul()
    local ok, opt = pcall(function() return getCore():getOptionFontSize() end)
    if ok and opt ~= nil and S.USER_MUL[opt] then return S.USER_MUL[opt] end
    return 1.0
end

-- ---------------------------------------------------------------------------
-- THE UI SCALE CAP. Nobody plays at 2x on a 720p screen: the windows are too big
-- to fit more than a few words. So the UI scale is capped to what fits: on a small
-- screen ZeD setup's UI scale slider stops at the largest step whose windows still
-- fit; Auto stays the default.
--  1. A fixed step FITS when, at that step times the text size's multiplier
--     (Large: 1.15 on every T.px), one window at its narrowest useful width fits in
--     half the screen's width (both windows are capped there): the tab strip 36 +
--     the inventory's minimum beside a full card 180 (alone it keeps 200; beside a
--     full card it gives way to 180) + the full card 480 + the container strip 36 =
--     732 units. And the screen's height holds the windows' minimum useful height:
--     the title bar (26 units, Large 30, root scale only, as Tokens' SP() sizes it)
--     + a tab strip of 6 tabs (6 x 36) + the help line (22). The engine font-size
--     multiplier (USER_MUL) does not apply to a fixed step (S.compute hands
--     userScale back as is), so it is left out of the step test; it is in Auto's
--     scale, which sets the floor below.
--  2. The cap is the largest step that fits, never below the largest step at or
--     under what Auto picks on this screen (at 1280 wide with Large text Auto's 0.86
--     fits since the inventory gives way to 180 beside a full card)
--     and never below the smallest step. ZeD setup's slider, the Mods page's
--     drop-down and the controller's ZeD wheel offer the steps up to the cap; the
--     ones above it are dimmed and inert, the help line saying "Too big for this
--     screen". A saved step above the cap (picked on a bigger monitor) draws AT the
--     cap; the saved value is untouched, so the big monitor gets it back. Auto is
--     never capped. Nor is ZeD.Scale.override (QA): a stress probe still reaches
--     2.0 at 1280x720.
--  3. Live: worked out from the screen size and the text size each time it is
--     asked. S.compute runs every 30 ticks and after a resolution change, so a new
--     resolution or text size moves the cap within half a second.
-- ---------------------------------------------------------------------------
S.FIT_W_UNITS = 36 + 180 + 480 + 36   -- tab strip + inventory minimum beside a full card + full card + container strip
S.FIT_TABS    = 6
S.FIT_TAB_U   = 36
S.FIT_HELP_U  = 22
S.FIT_STEPS   = { 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0 }   -- (Settings.lua's fixed steps)

--- the screen's width and height in px; 1920 x 1080 when the game can't say
function S.screenSize()
    local w, h = 1920, S.BASE_H
    pcall(function() w = getCore():getScreenWidth(); h = getCore():getScreenHeight() end)
    if type(w) ~= "number" or w <= 0 then w = 1920 end
    if type(h) ~= "number" or h <= 0 then h = S.BASE_H end
    return w, h
end

--- What Auto picks for a screen this tall: the height over the base, clamped, times the font-size knob.
function S.autoScale(h)
    local r = (h or S.BASE_H) / S.BASE_H
    if r < S.MIN then r = S.MIN elseif r > S.MAX then r = S.MAX end
    return r * S.userMul()
end

-- The text size's multiplier on T.px and its title bar height (units), read live.
local function textSizeFit()
    local TS = ZeD.TextSizes
    local sz = TS and TS[ZeD.currentSize or "small"]
    return (sz and sz.scale) or 1, (sz and sz.titleBarH) or 26
end

--- Does fixed step v fit a w x h screen (rule 1)? w and h default to this screen
function S.stepFits(v, w, h)
    if not (w and h) then w, h = S.screenSize() end
    local k, titleU = textSizeFit()
    local sc = v * k
    if S.FIT_W_UNITS * sc > math.floor(w * 0.5) then return false end
    return titleU * v + (S.FIT_TABS * S.FIT_TAB_U + S.FIT_HELP_U) * sc <= h
end

--- The largest fixed step offered on this screen (rule 2).
function S.fitCap(w, h)
    if not (w and h) then w, h = S.screenSize() end
    local auto = S.autoScale(h)
    local cap = nil
    for _, v in ipairs(S.FIT_STEPS) do
        if cap == nil then cap = v end
        if v > cap and (v <= auto + 1e-6 or S.stepFits(v, w, h)) then cap = v end
    end
    return cap or S.MAX
end

--- true when fixed step v is above this screen's cap (dimmed and inert in the menus).
function S.stepTooBig(v)
    return type(v) == "number" and v > S.fitCap() + 1e-6
end

-- The smallest fixed step offered: 0.5x does not look right at scale, so it is not offered in the beta. The step
-- stays in the list, because combos save by position: a saved 0.5 draws at the floor and keeps its saved value.
-- TODO: offer 0.5 again after the beta, for players who want smaller windows.
S.STEP_FLOOR = 0.75
--- true for a step below the floor: kept in the list, not offered
function S.stepRetired(v)
    return type(v) == "number" and v < S.STEP_FLOOR - 1e-6
end

--- Raw computation: screen height over the base, clamped, times the user knob.
--- A fixed step above the cap draws at the cap (S.userScale itself is left as saved).
--- (S.computeGame is the game's scale; S.compute below adds the main menu's clamp.)
function S.computeGame()
    if S.override then return S.override end
    if S.userScale then
        local cap = S.fitCap()
        if S.userScale > cap then return cap end
        if S.userScale < S.STEP_FLOOR then return S.STEP_FLOOR end   -- a retired step (0.5) draws at the floor
        return S.userScale
    end
    local h = S.BASE_H
    pcall(function() h = getCore():getScreenHeight() end)
    if type(h) ~= "number" or h <= 0 then h = S.BASE_H end
    local r = h / S.BASE_H
    if r < S.MIN then r = S.MIN elseif r > S.MAX then r = S.MAX end
    return r * S.userMul()
end

-- ---------------------------------------------------------------------------
-- THE MAIN MENU'S SCALE. While the desk is up and no game is loaded the root
-- is at least 1.0, so the menu's type meets Valve's readable size on a Steam
-- Deck, and at most sMax / 4, where sMax is the largest whole
-- multiple of the desk picture whose monitor (240 x 180 px) fits the screen: 4 on a Deck
-- or at 720p, 6 at 1080p, 12 at 4K. The game's own scale (S.computeGame, with the fit
-- cap) is untouched: a Deck plays at 0.75 and reads its menu at 1.0. At 1080p and up
-- nothing changes (the root is already 1.0 or more and under the cap). The desk leans
-- in to hold the 1080p menu where the room's monitor cannot (ZeD_MainMenu.lua).
-- S.menuUp is set by ZeD_MainMenu.lua; S.override (QA) bypasses the clamp.
-- ---------------------------------------------------------------------------
S.menuUp = S.menuUp or nil
S.MENU_TUBE_W, S.MENU_TUBE_H = 240, 180
--- the main menu's largest root scale on a w x h screen (this screen by default): sMax / 4
function S.menuMax(w, h)
    if not (w and h) then w, h = S.screenSize() end
    local sMax = math.max(1, math.floor(math.min(w / S.MENU_TUBE_W, h / S.MENU_TUBE_H)))
    return sMax / 4
end
--- the root scale as it stands now: the game's, clamped while the main menu is up
function S.compute()
    local r = S.computeGame()
    if S.override then return r end
    if S.menuUp and S.menuUp() then
        local mx = S.menuMax()
        if r < 1 then r = 1 end
        if r > mx then r = mx end
    end
    return r
end

--- Cached root scale (recomputed every 30 ticks, on resolution change, and on refresh()).
function S.root()
    if S._root == nil then S._root = S.compute() end
    return S._root
end

--- work the root scale out again now, and return it
function S.refresh() S._root = S.compute(); return S._root end

--- Design units -> screen pixels (rounded).
function S.px(v) return math.floor(v * S.root() + 0.5) end

-- ---------------------------------------------------------------------------
-- EVEN AT EVERY STEP: the in-between scales stay, and the UI is crisp at any of
-- them. Text and layout keep the exact scale; three things snap to whole pixels:
--   * pixel art draws at a whole zoom, the nearest whole number to the scale
--     (1.75 -> 2, 1.25 -> 1, exactly .5 rounds up), and the layout around a
--     prop uses the size it is drawn at;
--   * hairlines: a 1-unit line is the same whole number of pixels everywhere
--     (S.hair), and an n-unit line is n of them (S.line), never px(n) (at 1.5,
--     px(2) = 3 would sit beside 2 px one-unit lines);
--   * rectangles: snap the edges, then take the size from them (S.snapRect),
--     so neighbours share edges and repeated rows never drift.
-- At exactly 1x and 2x every helper returns what T.px / S.px did.
-- ---------------------------------------------------------------------------
--- The whole zoom pixel art draws at for scale s (default: the root scale), never below 1.
function S.artZoom(s)
    local k = math.floor((s or S.root()) + 0.5 + 1e-6)
    if k < 1 then k = 1 end
    return k
end
--- One design unit of line, in whole screen px (>= 1).
function S.hair(s)
    local v = math.floor((s or S.root()) + 0.5)
    if v < 1 then v = 1 end
    return v
end
--- A line `units` design units thick (default 1): a whole multiple of the hairline, >= 1 px.
function S.line(units, s)
    local v = math.floor((units or 1) * S.hair(s) + 0.5)
    if v < 1 then v = 1 end
    return v
end
--- A rectangle in design units -> screen px with snapped edges: x0 = px(x), x1 = px(x + w),
--- size = x1 - x0 (and the same down). Returns x, y, w, h.
function S.snapRect(x, y, w, h, s)
    s = s or S.root()
    local x0, y0 = math.floor(x * s + 0.5), math.floor(y * s + 0.5)
    return x0, y0, math.floor((x + w) * s + 0.5) - x0, math.floor((y + h) * s + 0.5) - y0
end

-- the root scale is worked out again every 30 ticks (about half a second), and on the next ask after a resolution change
if Events then
    if Events.OnTick then
        Events.OnTick.Add(function()
            S._tick = S._tick + 1
            if S._tick >= 30 then S._tick = 0; S._root = S.compute() end
        end)
    end
    if Events.OnResolutionChange then
        Events.OnResolutionChange.Add(function() S._root = nil end)
    end
end

-- ============================================================================
-- ZeD.Text — zoomed text drawing in design units
-- ============================================================================
ZeD.Text = ZeD.Text or {}
local X = ZeD.Text

-- A role font entry is { font = UIFont.*, px = N } (ZeD.Font.*); plain UIFont values work too.
-- uifont (X.uifont): the UIFont inside either one
local function uifont(f)
    if type(f) == "table" then return f.font end
    return f
end
X.uifont = uifont

--- Nominal size (px) at which the engine draws a font entry at zoom 1. SDF faces are normalised
--- by the engine; calibrate from the reported font height against the atlas line height.
function X.nominal(f)
    if type(f) ~= "table" then return nil end
    if f.nominal then return f.nominal end
    if f.sdf and f.face then
        -- measured: the engine draws a distance-field atlas at its native face size at zoom 1
        -- (32 px face -> 10 x "H" = 223 px for the body role), so the nominal IS the face size
        f.nominal = f.face
    else
        f.nominal = f.px
    end
    return f.nominal
end
--- Zoom for an explicit design px on a 64 px distance-field face (free-size text: licence name, radio frequency).
--- When the game's fonts stand in for ZeD's (X.fallback, below) the default face is the stand-in's.
function X.zoomPx(px, face) return px * S.root() / (face or X.freeFace or 64) end
--- Zoom that draws entry f `px` pixels tall (its design px times the root scale, usually).
function X.zoomFor(f, px)
    local n = X.nominal(f)
    if not n or n <= 0 then return 1 end
    return px / n
end

-- The engine TextManager, captured once (the global getTextManager is replaced below by the proxy).
-- Kept on S, so a reload of this file never captures the proxy instead.
S._realGetTextManager = S._realGetTextManager or getTextManager
--- the engine's own TextManager: measures with no zoom
function X.realTM() return S._realGetTextManager() end

-- ---------------------------------------------------------------------------
-- Text entries. The engine's Java text box (UITextBox2, under ISTextEntryBox)
-- draws its font at the font's native pixel size: it has no zoom. So typed
-- text follows the scale by switching faces: the Fira body face baked at
-- 13 / 15 (Small / Large) and 18 / 26 px (Dialogue and Intro: two slots no
-- vanilla text uses; the Sdf slots stay the game's, since they hold the
-- printed newspapers' faces), as bitmap faces:
-- media/fonts/generate_entry_fonts.py + EN/fonts.txt). The pick is the face
-- closest to the scaled body size (body role px x root).
-- ---------------------------------------------------------------------------
-- slot, face px (the engine reports a line height about a third taller than the face)
local ENTRY_SLOTS = { { "Small", 13 }, { "Large", 15 }, { "Dialogue", 18 }, { "Intro", 26 } }
-- While the game's fonts stand in for ZeD's (X.fallback, below), entries and roles
-- use the game's three text fonts; the face size is read off each one's line height.
local GAME_SLOTS = { "Small", "Medium", "Large" }
local GAME_ENTRY_SLOTS = { { "Small", 0 }, { "Medium", 0 }, { "Large", 0 } }
local _entryFaces, _entryTarget, _entryFont = nil, nil, nil

local function entryFaces()
    if _entryFaces then return _entryFaces end
    local faces = {}
    local tm = X.realTM()
    local lastH = 0
    local slots = X.fallback and GAME_ENTRY_SLOTS or ENTRY_SLOTS
    for _, e in ipairs(slots) do
        local f = UIFont and UIFont[e[1]]
        if f then
            -- each baked face is taller than the one before; a slot that did not
            -- load (an older font manifest) breaks the run and is skipped
            local h = tm:getFontHeight(f)
            if h and h > lastH then
                -- the face's size read off its own line height when that is far from the one baked for the slot: the
                -- slot then holds another face than ZeD's. On QA's Mac (Nov 10 2026) a note's typed words came out
                -- about 2.5 times its hint's size at 1.75x: Intro was picked as a 26 px face and drew far larger
                local px = (e[2] > 0) and e[2] or h * 0.75
                if e[2] > 0 and math.abs(h * 0.75 - e[2]) > e[2] * 0.25 then px = h * 0.75 end
                faces[#faces + 1] = { font = f, px = px }
                lastH = h
            end
        end
    end
    -- (kept only once the fonts have loaded: a slot still loading reports no height, and a list made
    -- then would leave every text box on the fallback face for the session)
    if #faces > 0 and X._fontsSettled then _entryFaces = faces end
    return faces
end

--- The UIFont a text entry should use right now.
function X.entryFont()
    local T = ZeD.T
    local bodyPx = (T and T.fontPx and T.fontF2 and T.fontPx[T.fontF2]) or 13
    local target = bodyPx * S.root()
    if _entryTarget == target and _entryFont then return _entryFont end
    local best, bestD = UIFont and UIFont.Small, nil
    for _, f in ipairs(entryFaces()) do
        local d = math.abs(f.px - target)
        if not bestD or d < bestD then best, bestD = f.font, d end
    end
    if _entryFaces then _entryTarget, _entryFont = target, best end
    return best
end

--- The entry face closest to `px` design pixels at the current scale (a larger
--- hand than the body: the notebook's page). Returns the font and its line height
--- in screen px, which is the text box's own line pitch.
function X.entryFontAt(px)
    local target = px * S.root()
    local best, bestD = UIFont and UIFont.Small, nil
    for _, f in ipairs(entryFaces()) do
        local d = math.abs(f.px - target)
        if not bestD or d < bestD then best, bestD = f.font, d end
    end
    return best, X.realTM():getFontHeight(best)
end

--- Keep a ZeD text entry on the scaled face and the theme's text colours.
--- Cheap enough to call every frame: it only touches Java on a change.
function X.fitEntry(entry)
    if not (entry and entry.javaObject) then return end
    local f = X.entryFont()
    if f and entry._zedFont ~= f then
        entry._zedFont = f
        entry:setFont(f)
    end
    local T = ZeD.T
    local c, d = T and T.text, T and T.textDim
    if c then
        -- (zedDrawsText: the owner draws the typed text itself in ZeD's face; the box keeps only the input)
        local hide = entry.zedDrawsText == true
        local key = string.format("%.3f,%.3f,%.3f,%.3f", c.r, c.g, c.b, c.a or 1) .. (hide and "h" or "")
        if entry._zedTextKey ~= key then
            entry._zedTextKey = key
            entry.javaObject:setTextRGBA(c.r, c.g, c.b, hide and 0 or (c.a or 1))
            if d then entry.javaObject:setPlaceholderTextRGBA(d.r, d.g, d.b, hide and 0 or (d.a or 1)) end
        end
    end
end

-- ---------------------------------------------------------------------------
-- When the game's fonts stand in for ZeD's.
-- The five role fonts are 64 px distance-field atlases on the slots named in
-- ZeD.Font.sdf, put there by media/fonts/EN/fonts.txt. The game reads a
-- language's own fonts.txt over the English one, so PL and RU carry copies of
-- ZeD's list (Fira covers Latin, Greek and Cyrillic). Two cases still swap the
-- atlases out, and ZeD cannot follow:
--   * Chinese, Traditional Chinese, Japanese, Korean and Thai: the game's list
--     for the language reloads those slots with its own bitmap faces, and Fira
--     has none of those scripts anyway.
--   * The Dyslexic font option (English only): the game then reads
--     EN/fontsDyslexic.txt in place of ZeD's list.
-- Zooming a bitmap face as if it were the 64 px atlas draws every label a few
-- pixels tall. So each role slot is checked against ZeD's atlas (a
-- distance-field font with the atlas's line height). If any is not, every role
-- draws in the game's own Small / Medium / Large font nearest its height, at
-- native size, and free-size text (headings, radio digits) zooms the tallest of
-- the three. Readable rather than the ZeD look.
-- ---------------------------------------------------------------------------
X.fallback = X.fallback or false        -- true while the game's fonts stand in
X.freeFace = X.freeFace or nil          -- the default face for zoomPx while they do
X._fontsSettled = X._fontsSettled or false
X._fontsLogged = X._fontsLogged or false
-- A server process draws nothing and never loads a font: the TextManager is there, its slots are
-- empty and getFontHeight throws. isServer() is true in a dedicated server and in the separate
-- server process a hosted game starts; the host's own game is a client and reads false, as does
-- single player. So font work stops only where there are no fonts. Set before any Lua loads.
X.noFonts = (isServer and isServer()) and true or false
local ROLE_KEYS = { "sec", "body", "stat", "head", "title" }

-- true = the slot holds ZeD's atlas, false = something else, nil = not loaded yet.
-- The engine reports a font's height as its tallest glyph's reach (about 78-83 on ZeD's 64 px
-- atlases, depending on the glyph set), so the test is "a distance-field font at least about a
-- face tall". Every font the game puts in these slots is a bitmap of 50 px or less.
local function slotIsZedAtlas(tm, e)
    local h = tm:getFontHeight(e.slot)
    if type(h) ~= "number" or h <= 0 then return nil end
    local okSdf, isSdf = pcall(function() return tm:isSdf(e.slot) end)
    if okSdf and isSdf == false then return false end
    return h >= (e.zedFace or 64) * 0.9
end

-- The game font whose line height is nearest `lineH` screen px.
local function gameFontNear(tm, lineH)
    local best, bestD = UIFont.Small, nil
    for _, name in ipairs(GAME_SLOTS) do
        local f = UIFont[name]
        local h = f and tm:getFontHeight(f)
        if h and h > 0 then
            local d = math.abs(h - lineH)
            if not bestD or d < bestD then best, bestD = f, d end
        end
    end
    return best
end

-- The tallest game font and its line height.
local function gameFontTallest(tm)
    local best, bestH = UIFont.Large, 0
    for _, name in ipairs(GAME_SLOTS) do
        local f = UIFont[name]
        local h = f and tm:getFontHeight(f)
        if h and h > bestH then best, bestH = f, h end
    end
    return best, bestH
end

-- "RU" or "EN, Dyslexic font on", for the log line.
local function fontSetName()
    local lang, dys = "?", false
    pcall(function() lang = tostring(Translator.getLanguage():name()) end)
    pcall(function() dys = getCore():getOptionEnableDyslexicFont() and true or false end)
    return lang .. (dys and ", Dyslexic font on" or "")
end

--- Checks the role slots and points ZeD.Font.sdf either at ZeD's atlases or at the
--- game's stand-in. Returns X.fallback. ZeD.applyTheme calls it before it registers
--- the role fonts; the tick below repeats it until the fonts have loaded.
function X.checkRoleFonts()
    local F = ZeD.Font and ZeD.Font.sdf
    if X.noFonts or not (F and UIFont) then return X.fallback end
    local tm = X.realTM()
    local foreign, unknown = false, false
    for _, k in ipairs(ROLE_KEYS) do
        local e = F[k]
        if e then
            e.slot = e.slot or e.font           -- the slot ZeD's list puts this atlas on
            e.zedFace = e.zedFace or e.face
            local zed = slotIsZedAtlas(tm, e)
            if zed == nil then unknown = true elseif zed == false then foreign = true end
        end
    end
    X._fontsSettled = not unknown
    local standIn, standH = nil, 0
    if foreign then standIn, standH = gameFontTallest(tm) end
    local was = X.fallback
    X.fallback = foreign and standH > 0
    for _, k in ipairs(ROLE_KEYS) do
        local e = F[k]
        if e then
            if X.fallback then
                -- the face size a bitmap of that line height matches, so zoomFor / zoomPx keep their px
                e.font = standIn
                e.face = standH * (e.zedFace or 64) / (e.lineH or 77)
            else
                e.font = e.slot
                e.face = e.zedFace
            end
            e.nominal = nil
        end
    end
    X.freeFace = X.fallback and (standH * 64 / 77) or nil
    if X._scriptReset then X._scriptReset() end   -- (the script faces are looked up again)
    if was ~= X.fallback then _entryFaces, _entryTarget, _entryFont = nil, nil, nil end
    if X._fontsSettled and (was ~= X.fallback or not X._fontsLogged) then
        X._fontsLogged = true
        if X.fallback then
            print("[ZeD] Fonts: the game's own fonts hold the role slots (" .. fontSetName() .. "); ZeD text draws in the game's Small / Medium / Large at native size")
        else
            print("[ZeD] Fonts: ZeD's distance-field role fonts are in place (" .. fontSetName() .. ")")
        end
    end
    return X.fallback
end

--- The game font a role of `px` design px draws in while X.fallback is on (native size, no zoom).
--- Target: the line height the role has on ZeD's atlas (face 64, line 77) at the current scale.
function X.roleFallbackFont(px)
    return gameFontNear(X.realTM(), (px or 13) * S.root() * 77 / 64)
end

--- Width / height in SCREEN px of `str` drawn at `zoom` (explicit zoom: measured on the raw manager).
function X.width(f, str, zoom)
    str = tostring(str)
    if type(f) == "table" and f.sdf then
        local sf, zz = X.scriptSwap(str, zoom or 1, f.face)
        if sf then return X.realTM():MeasureStringX(sf, str) * zz end
    end
    return X.realTM():MeasureStringX(uifont(f), str) * (zoom or 1)
end
--- the font's line height in screen px at `zoom`
function X.height(f, zoom)
    return X.realTM():getFontHeight(uifont(f)) * (zoom or 1)
end

--- Draw `str` on element `el` at screen px (x, y) with `zoom`; align "l" | "c" | "r" around x.
--- Returns the drawn width in screen px.
function X.draw(el, f, str, x, y, zoom, r, g, b, a, align)
    str = tostring(str); zoom = zoom or 1
    local w = X.width(f, str, zoom)
    if align == "r" then x = x - w elseif align == "c" then x = x - w / 2 end
    if type(f) == "table" and f.sdf then
        local sf, zz, dy = X.scriptSwap(str, zoom, f.face)
        if sf then
            el:drawTextZoomed(str, math.floor(x), math.floor(y + dy), zz, r or 1, g or 1, b or 1, a or 1, sf)
            return w
        end
    end
    el:drawTextZoomed(str, math.floor(x), math.floor(y), zoom, r or 1, g or 1, b or 1, a or 1, uifont(f))
    return w
end

-- ---------------------------------------------------------------------------
-- Zoom for a font value: the five ZeD role fonts are registered by
-- ZeD.applyTheme in ZeD.T.fontPx / fontFace; everything else (vanilla fonts) is 1.
-- ---------------------------------------------------------------------------
-- (kept per font while the token table and the root scale stay: every text draw and measure asks)
local _zoom = { T = false, root = false, z = {} }
X._zoom = _zoom   -- (the lean text draw reads it inline: Overrides/TextScale.lua)
--- the zoom a font draws at now: a role font's px times the root over its face, 1 for anything else
function X.zoomOf(font)
    if font == nil then return 1 end
    local T = ZeD.T
    local root = S.root()
    if _zoom.T ~= T or _zoom.root ~= root then _zoom.T, _zoom.root, _zoom.z = T, root, {} end
    local z = _zoom.z[font]
    if z == nil then
        local px = T and T.fontPx and T.fontPx[font]
        if not px then z = 1
        else z = px * root / ((T.fontFace and T.fontFace[font]) or 64) end
        _zoom.z[font] = z
    end
    return z
end

-- ---------------------------------------------------------------------------
-- Text in scripts ZeD's fonts do not carry (a folder named in Chinese would draw "??").
-- Fira covers Latin, Greek and Cyrillic. ZeD's font lists (EN, PL, RU fonts.txt) put the game's
-- own Chinese and Japanese faces (zomboidMediumChinese / zomboidMediumJapanese, 23 px bitmaps
-- from the game's media/fonts) on two slots nothing else draws with: Cred1 (ZeD's spare Chicago,
-- unused) and DebugConsole (the -debug console). A string with a letter the role font lacks
-- (the engine measures a missing glyph 0 wide; one past the font's table draws "?") is drawn and
-- measured in whichever of those faces draws the most of its letters, zoomed to the role's size
-- and set on the role's baseline. Decided once per string (kept, two generations), glyphs probed
-- once per face. With the game's own fonts on the roles (Chinese, Japanese, Korean, Thai
-- language; X.fallback) nothing changes: those already draw their language.
-- Not covered: Korean and Thai letters (no free slot).
-- Simplified Chinese: the game's Chinese face is a traditional set (U+56FE, the second letter of
-- "map", draws blank in it), so ZeD's lists put Noto Sans SC on Cred1 instead: a 32 px
-- distance-field face (42/media/fonts/sdf/notoSC.fnt, ZeDUI/tools/fonts/bake_sdf_sc.py) with ASCII,
-- Latin-1, the 3,755 GB2312 level-1 letters and CJK punctuation. One face draws a whole string, so
-- a letter outside that set (a rare or traditional one) draws blank unless the Japanese face draws
-- more of the string's letters. The second Cred1 row keeps the game's face working if a list
-- still names it there (one row per slot is taken).
-- ---------------------------------------------------------------------------
local SCRIPT_SLOTS = {
    { name = "Cred1", em = 32, base = 38, probe = 0x56FE },          -- Noto Sans SC (ZeD's)
    { name = "Cred1", em = 23, base = 19, probe = 0x5730 },          -- the game's Chinese face
    { name = "DebugConsole", em = 23, base = 19, probe = 0x3042 },   -- the game's Japanese face
}
local ZED_BASE = 60 / 64      -- ZeD's distance-field atlases: baseline 60 px down a 64 px face
local SF_MAX = 4000
local SF = { ready = false, fonts = {}, zedFont = nil, has = {}, cur = {}, old = {}, n = 0 }
X._scriptFonts = SF

local function sfHas(font, c, str, i)
    local byF = SF.has[font]
    if not byF then byF = {}; SF.has[font] = byF end
    local v = byF[c]
    if v == nil then
        v = X.realTM():MeasureStringX(font, string.sub(str, i, i)) > 0
        byF[c] = v
    end
    return v
end

local function sfSetup()
    SF.ready = true
    SF.fonts, SF.has, SF.cur, SF.old, SF.n = {}, {}, {}, {}, 0
    SF.zedFont = nil
    if X.fallback or not UIFont then return end
    local body = ZeD.Font and ZeD.Font.sdf and ZeD.Font.sdf.body
    SF.zedFont = body and (body.slot or body.font) or nil
    local tm = X.realTM()
    local taken = {}
    for _, e in ipairs(SCRIPT_SLOTS) do
        local f = UIFont[e.name]
        -- (the slot must hold the face: a language's own list can put something else there)
        if f and not taken[e.name] and tm:MeasureStringX(f, string.char(e.probe)) > 0 then
            taken[e.name] = true
            SF.fonts[#SF.fonts + 1] = { font = f, em = e.em, base = e.base }
        end
    end
end
X._scriptReset = function() SF.ready = false end

local function sfScan(str)
    local n = #str
    local zf = SF.zedFont
    local wide, miss = 0, 0
    for i = 1, n do
        local c = string.byte(str, i)
        if c and c >= 128 then
            wide = wide + 1
            if not sfHas(zf, c, str, i) then miss = miss + 1 end
        end
    end
    if miss == 0 then return false end
    local best, bestN = false, wide - miss
    for k = 1, #SF.fonts do
        local e = SF.fonts[k]
        local got = 0
        for i = 1, n do
            local c = string.byte(str, i)
            if c and c >= 128 and sfHas(e.font, c, str, i) then got = got + 1 end
        end
        if got > bestN then best, bestN = e, got end
    end
    return best
end

--- The face entry ({ font, em, base }) that draws `str` in place of ZeD's role fonts, or false.
function X.scriptFont(str)
    if not SF.ready then
        if not X._fontsSettled then return false end
        sfSetup()
    end
    if SF.zedFont == nil or #SF.fonts == 0 or type(str) ~= "string" then return false end
    local v = SF.cur[str]
    if v ~= nil then return v end
    v = SF.old[str]
    if v == nil then v = sfScan(str) end
    if SF.n >= SF_MAX then SF.old, SF.cur, SF.n = SF.cur, {}, 0 end
    SF.cur[str] = v
    SF.n = SF.n + 1
    return v
end

--- For a role font drawn at zoom z: the face, its zoom and the y shift that draw `str`, or nil
--- when the role font draws it itself. face: the role atlas's face px (64).
function X.scriptSwap(str, z, face)
    local e = X.scriptFont(str)
    if not e then return nil end
    local f = face or 64
    local zz = z * f / e.em
    return e.font, zz, z * f * ZED_BASE - e.base * zz
end

--- Width in screen px of `str` in role font `font` at zoom z, in the face that draws it.
function X.roleWidth(font, str, z)
    if z ~= 1 then
        local T = ZeD.T
        local sf, zz = X.scriptSwap(str, z, (T and T.fontFace and T.fontFace[font]) or 64)
        if sf then return X.realTM():MeasureStringX(sf, str) * zz end
    end
    return X.realTM():MeasureStringX(font, str) * z
end

-- ---------------------------------------------------------------------------
-- ZeD.TM — the text manager seen by ZeD code (ZeD files measure with ZeD.TM; one
-- that still calls getTextManager() gets the same proxy, since the global is
-- replaced at the bottom). Measurements of the role fonts are
-- multiplied by their zoom so layout math matches the zoomed draws; anything
-- else passes through to the engine's TextManager.
-- ---------------------------------------------------------------------------
ZeD.TM = ZeD.TM or {}
local TM = ZeD.TM
-- Widths and heights are kept, because every panel measures the same strings every frame,
-- each measure three Java calls. A kept value is exactly what the engine
-- answered for that font and string; the store starts over whenever an answer could differ: a
-- new token table (theme, accent, text size, UI scale, the role fonts moving to the game's own),
-- another root scale, another language, the game's font-size option, a resolution change. Nothing
-- is kept until the fonts have loaded. Two generations of MC_MAX strings: past that the older
-- half drops (a string still in use is carried over on its next measure).
local MC = { T = false, root = false, gen = false, fs = false, x = {}, xOld = {}, h = {}, n = 0 }
local MC_MAX = 3000
X._measureCache = MC
MC.epoch = 0
local function mcReset() MC.x, MC.xOld, MC.h, MC.n = {}, {}, {}, 0; MC.epoch = MC.epoch + 1 end
-- the font-size option, read once a frame (OnPreUIDraw) rather than on every measure
MC.fsNow = false
local function mcFrame()
    local ok, v = pcall(function() return getCore():getOptionFontSize() end)
    MC.fsNow = ok and v or false
end
local function mcOn()
    if not X._fontsSettled then return false end
    local T = ZeD.T
    if MC.T ~= T or MC.root ~= S._root or MC.gen ~= ZeD._trGen or MC.fs ~= MC.fsNow then
        MC.T, MC.root, MC.gen, MC.fs = T, S._root, ZeD._trGen, MC.fsNow
        mcReset()
    end
    return true
end
--- For caches built on measures (ZeD.Atoms.truncateText): a number that changes whenever the kept
--- measures start over, or nil while measures are not kept (the fonts still loading)
function X.measureEpoch()
    -- (mcOn's test inline first, as in MeasureStringX: every truncate asks this)
    if X._fontsSettled and MC.T == ZeD.T and MC.root == S._root and MC.gen == ZeD._trGen and MC.fs == MC.fsNow then
        return MC.epoch
    end
    if not mcOn() then return nil end
    return MC.epoch
end
--- For caches of words and their widths: measureEpoch, also changed by the test language
--- (ZeD.tr's stretched words); nil while measures are not kept
function X.wordsEpoch()
    local e = X.measureEpoch()
    if e == nil then return nil end
    local st = ZeD._trState
    return e * 2 + ((st and st.on) and 1 or 0)
end
if Events then
    if Events.OnPreUIDraw then Events.OnPreUIDraw.Add(mcFrame) end
    if Events.OnResolutionChange then Events.OnResolutionChange.Add(function() mcReset(); MC.T = false end) end
end
--- a string's width in screen px, zoomed for a role font; kept, as above
function TM:MeasureStringX(font, str)
    if type(str) ~= "string" then str = tostring(str) end
    -- (mcOn's test inline: this runs a few hundred times a frame)
    if font == nil or not ((X._fontsSettled and MC.T == ZeD.T and MC.root == S._root and MC.gen == ZeD._trGen
                            and MC.fs == MC.fsNow) or mcOn()) then
        return X.roleWidth(font, str, X.zoomOf(font))
    end
    local byF = MC.x[font]
    if byF then
        local v = byF[str]
        if v then return v end
    else
        byF = {}
        MC.x[font] = byF
    end
    local old = MC.xOld[font]
    local v = old and old[str]
    if not v then v = X.roleWidth(font, str, X.zoomOf(font)) end
    if MC.n >= MC_MAX then
        MC.xOld, MC.x, MC.n = MC.x, {}, 0
        byF = {}
        MC.x[font] = byF
    end
    byF[str] = v
    MC.n = MC.n + 1
    return v
end
--- a string's height in screen px, zoomed for a role font (not kept)
function TM:MeasureStringY(font, str)
    return X.realTM():MeasureStringY(font, tostring(str)) * X.zoomOf(font)
end
--- a font's line height in screen px, zoomed for a role font; kept, as above
function TM:getFontHeight(font)
    -- (mcOn's test inline first, as in MeasureStringX)
    if font ~= nil and X._fontsSettled and MC.T == ZeD.T and MC.root == S._root and MC.gen == ZeD._trGen
       and MC.fs == MC.fsNow then
        local v = MC.h[font]
        if v then return v end
    end
    if font == nil or not mcOn() then
        return X.realTM():getFontHeight(font) * X.zoomOf(font)
    end
    local v = MC.h[font]
    if not v then
        v = X.realTM():getFontHeight(font) * X.zoomOf(font)
        MC.h[font] = v
    end
    return v
end
--- getFontFromEnum(font):getLineHeight() is how vanilla panels (ISRichTextPanel) size their lines:
--- for a zoomed font hand back a thin proxy whose getLineHeight is zoomed, everything else passes through.
function TM:getFontFromEnum(font)
    local real = X.realTM():getFontFromEnum(font)
    local z = X.zoomOf(font)
    if z == 1 or real == nil then return real end
    S._fontProxy = S._fontProxy or {}
    local c = S._fontProxy[font]
    if c and c.z == z and c.real == real then return c.proxy end
    local proxy = setmetatable({ getLineHeight = function() return real:getLineHeight() * z end },
        { __index = function(_, k) local v = real[k]; if type(v) == "function" then return function(_, ...) return v(real, ...) end end; return v end })
    S._fontProxy[font] = { z = z, real = real, proxy = proxy }
    return proxy
end
-- Any other method: wrapped once and cached on TM (the TextManager is a singleton; the wrapper
-- re-fetches it per call so a Lua reload never holds a stale object). Plain values pass through.
setmetatable(TM, { __index = function(t, k)
    local tm = X.realTM(); local v = tm[k]
    if type(v) ~= "function" then return v end
    local wrapper = function(_, ...) local real = X.realTM(); return real[k](real, ...) end
    rawset(t, k, wrapper)
    return wrapper
end })
-- The global: vanilla panels that ZeD hands a role font (tooltip description, rich text) measure
-- through the proxy too, so their wrapping matches the zoomed draws. Vanilla fonts measure unchanged.
getTextManager = function() return TM end
print("[ZeD] Scale: text manager proxy installed (role fonts measure zoomed)")

-- Re-apply the theme (token table, font heights) when the root scale changes.
S._appliedRoot = S._appliedRoot or nil
-- Open windows keep their screen-px geometry, so after a root change every window that is
-- open is closed and reopened (it restores from design units). Two ticks apart so the close
-- settles first. Each window is closed and reopened on its own, so a lone Character or World
-- window comes back alone (the pair toggle would open or close the missing partner), and
-- neither needs the game running: a scale picked from the pause menu applies at once.
S._reopenAt = nil
S._reopenChar, S._reopenWorld = false, false
local function reopenWindowsIfOpen()
    local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
    local charOpen  = (CW and CW.isOpen and CW.isOpen()) and true or false
    local worldOpen = (WW and WW.isOpen and WW.isOpen()) and true or false
    if not charOpen and not worldOpen then return end
    if charOpen and CW.toggle then pcall(CW.toggle, 0) end    -- close (saves the geometry at the old scale)
    if worldOpen and WW.close then pcall(WW.close) end
    S._reopenChar, S._reopenWorld = charOpen, worldOpen
    S._reopenAt = 3
end
local function reopenWindowsClosed()
    local p = getSpecificPlayer and getSpecificPlayer(0)
    if not p or p:isDead() then return end       -- a dead character's windows wait for the next one
    local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
    if S._reopenChar and CW and CW.toggle and CW.isOpen and not CW.isOpen() then pcall(CW.toggle, 0) end
    if S._reopenWorld and WW and WW.open then pcall(WW.open, 0) end
    S._reopenChar, S._reopenWorld = false, false
end
local function rootChanged()
    if S._appliedRoot ~= nil and S._root ~= nil and math.abs(S._appliedRoot - S._root) > 0.001 and ZeD.applyTheme and not S._reapplying then
        S._reapplying = true
        pcall(reopenWindowsIfOpen)   -- close FIRST: the close path persists geometry divided by the current (old) scale
        pcall(ZeD.applyTheme)
        S._reapplying = false
    end
end
-- The role-font check runs again until the fonts have loaded; if the answer changes, the theme
-- is re-applied so the roles move to (or off) the game's fonts.
local function fontsSettle()
    if X.noFonts or X._fontsSettled or not (ZeD.T and ZeD.applyTheme) or S._reapplying then return end
    local was = X.fallback
    X.checkRoleFonts()
    if X.fallback ~= was then
        S._reapplying = true
        pcall(ZeD.applyTheme)
        S._reapplying = false
    end
end
if Events and Events.OnTick then
    Events.OnTick.Add(function()
        if S._tick == 0 then rootChanged(); fontsSettle() end
        if S._reopenAt then
            S._reopenAt = S._reopenAt - 1
            if S._reopenAt <= 0 then S._reopenAt = nil; pcall(reopenWindowsClosed) end
        end
    end)
end

return S
