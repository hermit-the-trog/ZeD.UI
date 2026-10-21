-- ============================================================================
-- ZeD.Scale — the root scale of the whole UI (S124, true scaling, phase 1)
-- ============================================================================
-- Director's rule (Oct 13 2026): the UI adapts to the resolution by itself;
-- the engine's font-size option is only an extra multiplier on top.
--
-- Design base: a 1920x1080 screen is 1.0. Every layout number in ZeD is a
-- DESIGN UNIT (1 unit = 1 px at 1080p); multiply by ZeD.Scale.root() at draw
-- time (ZeD.Scale.px does that with rounding). A 4K screen lands at 2.0, 1440p
-- at 1.33, a 720p window at 0.75 (clamped).
--
-- Text: the engine draws any font at any zoom (ISUIElement:drawTextZoomed,
-- Q138) and distance-field atlases stay crisp (Q139). ZeD.Text wraps that so
-- organisms never touch UIFont sizes directly: zoom = root scale, width =
-- MeasureStringX * zoom.
--
-- QA: ZeD.Scale.override = 1.0 / 1.333 / 2.0 forces the root scale; call
-- ZeD.Scale.refresh() afterwards (or wait a second).
-- ============================================================================

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
-- fonts (Q140), so it becomes the user's taste knob. 19px (the rig's setting,
-- where the approved look was tuned), 26px and the adaptive choice are
-- neutral; 16px shrinks the UI a step, 33px and 38px grow it. (Until Oct 20
-- 2026 this table was keyed 0..5, so every fixed size read the step above it
-- and 38px fell back to neutral.)
S.USER_MUL = { [1] = 0.85, [2] = 1.0, [3] = 1.0, [4] = 1.15, [5] = 1.3, [6] = 1.0 }

S._root = nil
S._tick = 0

function S.userMul()
    local ok, opt = pcall(function() return getCore():getOptionFontSize() end)
    if ok and opt ~= nil and S.USER_MUL[opt] then return S.USER_MUL[opt] end
    return 1.0
end

-- Raw computation: screen height over the base, clamped, times the user knob.
function S.compute()
    if S.override then return S.override end
    if S.userScale then return S.userScale end
    local h = S.BASE_H
    pcall(function() h = getCore():getScreenHeight() end)
    if type(h) ~= "number" or h <= 0 then h = S.BASE_H end
    local r = h / S.BASE_H
    if r < S.MIN then r = S.MIN elseif r > S.MAX then r = S.MAX end
    return r * S.userMul()
end

-- Cached root scale (recomputed every 30 ticks, on resolution change, and on refresh()).
function S.root()
    if S._root == nil then S._root = S.compute() end
    return S._root
end

function S.refresh() S._root = S.compute(); return S._root end

-- Design units -> screen pixels (rounded).
function S.px(v) return math.floor(v * S.root() + 0.5) end

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
local function uifont(f)
    if type(f) == "table" then return f.font end
    return f
end
X.uifont = uifont

-- Nominal size (px) at which the engine draws a font entry at zoom 1. SDF faces are normalised
-- by the engine; calibrate from the reported font height against the atlas line height.
function X.nominal(f)
    if type(f) ~= "table" then return nil end
    if f.nominal then return f.nominal end
    if f.sdf and f.face then
        -- measured Oct 13: the engine draws a distance-field atlas at its native face size at zoom 1
        -- (32 px face -> 10 x "H" = 223 px for the body role), so the nominal IS the face size
        f.nominal = f.face
    else
        f.nominal = f.px
    end
    return f.nominal
end
-- Zoom for an explicit design px on a 64 px distance-field face (free-size text: licence name, radio frequency).
-- When the game's fonts stand in for ZeD's (X.fallback, below) the default face is the stand-in's.
function X.zoomPx(px, face) return px * S.root() / (face or X.freeFace or 64) end
-- Zoom that draws entry f `px` pixels tall (its design px times the root scale, usually).
function X.zoomFor(f, px)
    local n = X.nominal(f)
    if not n or n <= 0 then return 1 end
    return px / n
end

-- The engine TextManager, captured once (the global getTextManager is replaced below by the proxy).
S._realGetTextManager = S._realGetTextManager or getTextManager
function X.realTM() return S._realGetTextManager() end

-- ---------------------------------------------------------------------------
-- Text entries. The engine's Java text box (UITextBox2, under ISTextEntryBox)
-- draws its font at the font's native pixel size: it has no zoom. So typed
-- text follows the scale by switching faces: the Fira body face baked at
-- 13 / 15 (Small / Large) and 18 / 26 px (Dialogue and Intro: two slots no
-- vanilla text uses. Oct 16 2026: they were four Sdf slots, which are the
-- printed newspapers' faces; those went back to the game), as bitmap faces:
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
                faces[#faces + 1] = { font = f, px = (e[2] > 0) and e[2] or h * 0.75 }
                lastH = h
            end
        end
    end
    _entryFaces = faces
    return faces
end

-- The UIFont a text entry should use right now.
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
    _entryTarget, _entryFont = target, best
    return best
end

-- The entry face closest to `px` design pixels at the current scale (a larger
-- hand than the body: the notebook's page). Returns the font and its line height
-- in screen px, which is the text box's own line pitch.
function X.entryFontAt(px)
    local target = px * S.root()
    local best, bestD = UIFont and UIFont.Small, nil
    for _, f in ipairs(entryFaces()) do
        local d = math.abs(f.px - target)
        if not bestD or d < bestD then best, bestD = f.font, d end
    end
    return best, X.realTM():getFontHeight(best)
end

-- Keep a ZeD text entry on the scaled face and the theme's text colours.
-- Cheap enough to call every frame: it only touches Java on a change.
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
        local key = string.format("%.3f,%.3f,%.3f,%.3f", c.r, c.g, c.b, c.a or 1)
        if entry._zedTextKey ~= key then
            entry._zedTextKey = key
            entry.javaObject:setTextRGBA(c.r, c.g, c.b, c.a or 1)
            if d then entry.javaObject:setPlaceholderTextRGBA(d.r, d.g, d.b, d.a or 1) end
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

-- Checks the role slots and points ZeD.Font.sdf either at ZeD's atlases or at the
-- game's stand-in. Returns X.fallback. ZeD.applyTheme calls it before it registers
-- the role fonts; the tick below repeats it until the fonts have loaded.
function X.checkRoleFonts()
    local F = ZeD.Font and ZeD.Font.sdf
    if not (F and UIFont) then return X.fallback end
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

-- The game font a role of `px` design px draws in while X.fallback is on (native size, no zoom).
-- Target: the line height the role has on ZeD's atlas (face 64, line 77) at the current scale.
function X.roleFallbackFont(px)
    return gameFontNear(X.realTM(), (px or 13) * S.root() * 77 / 64)
end

-- Width / height in SCREEN px of `str` drawn at `zoom` (explicit zoom: measured on the raw manager).
function X.width(f, str, zoom)
    return X.realTM():MeasureStringX(uifont(f), tostring(str)) * (zoom or 1)
end
function X.height(f, zoom)
    return X.realTM():getFontHeight(uifont(f)) * (zoom or 1)
end

-- Draw `str` on element `el` at screen px (x, y) with `zoom`; align "l" | "c" | "r" around x.
-- Returns the drawn width in screen px.
function X.draw(el, f, str, x, y, zoom, r, g, b, a, align)
    str = tostring(str); zoom = zoom or 1
    local w = X.width(f, str, zoom)
    if align == "r" then x = x - w elseif align == "c" then x = x - w / 2 end
    el:drawTextZoomed(str, math.floor(x), math.floor(y), zoom, r or 1, g or 1, b or 1, a or 1, uifont(f))
    return w
end

-- ---------------------------------------------------------------------------
-- Zoom for a font value (phase 2): the five ZeD role fonts are registered by
-- ZeD.applyTheme in ZeD.T.fontPx / fontFace; everything else (vanilla fonts) is 1.
-- ---------------------------------------------------------------------------
function X.zoomOf(font)
    if font == nil then return 1 end
    local T = ZeD.T
    local px = T and T.fontPx and T.fontPx[font]
    if not px then return 1 end
    return px * S.root() / ((T.fontFace and T.fontFace[font]) or 64)
end

-- ---------------------------------------------------------------------------
-- ZeD.TM — the text manager seen by ZeD code (every getTextManager() in the
-- mod's own files was rewritten to ZeD.TM). Measurements of the role fonts are
-- multiplied by their zoom so layout math matches the zoomed draws; anything
-- else passes through to the engine's TextManager.
-- ---------------------------------------------------------------------------
ZeD.TM = ZeD.TM or {}
local TM = ZeD.TM
function TM:MeasureStringX(font, str)
    return X.realTM():MeasureStringX(font, tostring(str)) * X.zoomOf(font)
end
function TM:MeasureStringY(font, str)
    return X.realTM():MeasureStringY(font, tostring(str)) * X.zoomOf(font)
end
function TM:getFontHeight(font)
    return X.realTM():getFontHeight(font) * X.zoomOf(font)
end
-- getFontFromEnum(font):getLineHeight() is how vanilla panels (ISRichTextPanel) size their lines:
-- for a zoomed font hand back a thin proxy whose getLineHeight is zoomed, everything else passes through.
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
    if X._fontsSettled or not (ZeD.T and ZeD.applyTheme) or S._reapplying then return end
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
