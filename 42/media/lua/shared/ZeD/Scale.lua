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

-- Engine font-size option (UI_optionscreen_FontSize0..5 = 16px, 19px, 26px,
-- 33px, 38px, "Scale with window height"). It does not touch ZeD fonts (Q140),
-- so it becomes the user's taste knob: 26px (the rig's setting) and the
-- adaptive choice are neutral, the others nudge the whole UI.
S.USER_MUL = { [0] = 0.85, [1] = 0.92, [2] = 1.0, [3] = 1.15, [4] = 1.3, [5] = 1.0 }

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
function X.zoomPx(px, face) return px * S.root() / (face or 64) end
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
local _entryFaces, _entryTarget, _entryFont = nil, nil, nil

local function entryFaces()
    if _entryFaces then return _entryFaces end
    local faces = {}
    local tm = X.realTM()
    local lastH = 0
    for _, e in ipairs(ENTRY_SLOTS) do
        local f = UIFont and UIFont[e[1]]
        if f then
            -- each baked face is taller than the one before; a slot that did not
            -- load (an older font manifest) breaks the run and is skipped
            local h = tm:getFontHeight(f)
            if h and h > lastH then
                faces[#faces + 1] = { font = f, px = e[2] }
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
-- Open windows keep their screen-px geometry, so after a root change the pair is closed and
-- reopened (it restores from design units). Two ticks apart so the close settles first.
S._reopenAt = nil
local function reopenPairIfOpen()
    local CW = ZeD_CharacterWindow
    if CW and CW.isOpen and CW.toggleBothPaired and CW.isOpen() and getGameSpeed and getGameSpeed() > 0 then
        pcall(CW.toggleBothPaired, 0)        -- close both
        S._reopenAt = 3
    end
end
local function rootChanged()
    if S._appliedRoot ~= nil and S._root ~= nil and math.abs(S._appliedRoot - S._root) > 0.001 and ZeD.applyTheme and not S._reapplying then
        S._reapplying = true
        pcall(reopenPairIfOpen)   -- close FIRST: the close path persists geometry divided by the current (old) scale
        pcall(ZeD.applyTheme)
        S._reapplying = false
    end
end
if Events and Events.OnTick then
    Events.OnTick.Add(function()
        if S._tick == 0 then rootChanged() end
        if S._reopenAt then
            S._reopenAt = S._reopenAt - 1
            if S._reopenAt <= 0 then S._reopenAt = nil; local CW = ZeD_CharacterWindow; if CW and CW.toggleBothPaired then pcall(CW.toggleBothPaired, 0) end end
        end
    end)
end

return S
