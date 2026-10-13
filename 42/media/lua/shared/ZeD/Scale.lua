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
-- Zoom that draws entry f `px` pixels tall (its design px times the root scale, usually).
function X.zoomFor(f, px)
    local n = X.nominal(f)
    if not n or n <= 0 then return 1 end
    return px / n
end

-- Width / height in SCREEN px of `str` drawn at `zoom`.
function X.width(f, str, zoom)
    return getTextManager():MeasureStringX(uifont(f), tostring(str)) * (zoom or 1)
end
function X.height(f, zoom)
    return getTextManager():getFontHeight(uifont(f)) * (zoom or 1)
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

return S
