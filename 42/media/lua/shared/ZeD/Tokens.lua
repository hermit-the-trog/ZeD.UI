-- ZeD-UI/42/media/lua/shared/ZeD/Tokens.lua
-- ============================================================================
-- DESIGN TOKEN ENGINE: the tokens, the bottom layer every atom, molecule and organism reads.
-- Single source of truth for every visual value in the mod.
-- Three independent axes: Base Theme x Accent Color x Text Size
-- Produces ZeD.T — the active palette that all components reference.
-- The one thing to know: ZeD.applyTheme builds a NEW ZeD.T on every theme, accent, text-size
-- or UI-scale change, so code that keeps the old table keeps the old values. Read the palette
-- fresh every frame (prerender), so a theme change shows up instantly — nothing is cached.
-- Shared: this file loads on the client and on a dedicated server alike, so nothing
-- client-only at file scope. On a server the palette is built all the same; only the font
-- heights are skipped, since a server loads no fonts.
-- ============================================================================

-- Reload-safe: loading this file twice reuses the table instead of wiping it. Everything ZeD
-- makes lives under this one global.
ZeD = ZeD or {}

-- ---------------------------------------------------------------------------
-- HELPER: Build an RGBA table from 0-1 float values
-- PZ uses {r, g, b, a} tables for all color arguments
-- ---------------------------------------------------------------------------
local function rgba(r, g, b, a)
    return {r = r, g = g, b = b, a = a or 1.0}
end

-- Convenience: build rgba from hex string "#RRGGBB" + alpha float
local function hex(str, a)
    local r = tonumber(str:sub(2, 3), 16) / 255
    local g = tonumber(str:sub(4, 5), 16) / 255
    local b = tonumber(str:sub(6, 7), 16) / 255
    return rgba(r, g, b, a or 1.0)
end

-- ---------------------------------------------------------------------------
-- BASE THEMES
-- Control surfaces, borders, text contrast, border weight.
-- Each base theme is a table of token values. Accent-dependent tokens
-- (accent, hover, textOnAccent) are set separately by the accent system.
-- ---------------------------------------------------------------------------
ZeD.BaseThemes = {

    dark = {
        name     = "Dark",
        -- the list menu's marks on surface 1 (punch list 138, the director approved Nov 10 2026): the paper pair's
        -- hues made light enough for 4.5 : 1 here (blue 5.6, red 4.7), apart under all three kinds of color blindness
        markAdd    = hex("#4491E2"),
        markRemove = hex("#D9572A"),
        base     = hex("#0C0C0C", 0.92),   -- deepest background (neutral grey)
        onBand   = hex("#030303", 1.0),     -- the Mods list: the solid band under a mod that is on (darker than base)
        surf1    = hex("#141414", 0.92),    -- window background
        surf2    = hex("#1C1C1C", 0.92),    -- title bars, elevated panels
        surf3    = hex("#242424", 0.92),    -- interactive elements, buttons
        surf4    = hex("#2C2C2C", 0.92),    -- hover elevation
        border   = hex("#202020", 1.0),     -- soft dividers between rows
        borderS  = hex("#383838", 1.0),     -- strong structural borders
        -- (frameS / frameHi, the belt's slot frame: unset here, so the strong border and no outer line)
        text     = rgba(0.855, 0.855, 0.855, 1.0),   -- neutral off-white body text, opaque (punch list 160: at 0.9 it
                                                     -- drew #C4C6C5, no brighter than the secondary text)
        textSec  = rgba(0.63, 0.63, 0.63, 0.65),     -- neutral secondary (overwritten to accent at runtime)
        textDim  = rgba(0.63, 0.63, 0.63, 0.65),     -- structural chrome: scrollbar arrows, grip lines, ridges
        textHead = rgba(0.90, 0.90, 0.90, 0.92),     -- neutral bright chrome/headings
        stripe   = rgba(1.00, 1.00, 1.00, 0.04),     -- neutral white stripe
        -- Status colors (amber-shifted family)
        danger   = hex("#C45A2A"),
        warning  = hex("#C49A2A"),
        positive = hex("#7A9A34"),
        -- status colors safe as text, at least 4.5 : 1 on surface 2 (the balloons' checks and crosses,
        -- the crafting card's met and unmet). Danger itself reads 3.9 : 1 here, so its text is lighter.
        positiveText = hex("#7A9A34"),
        dangerText   = hex("#DE7045"),
        info     = hex("#5A8A9A"),
        violet   = hex("#9A6AC4"),                   -- a ticket's Appeal label
        -- Border weight (pixels) — High Contrast overrides this
        borderW  = 1,
        -- Disabled opacity
        disabledAlpha = 0.42,
        -- System 7 chrome: raised button highlight / shadow
        chromeHi = rgba(1.0, 1.0, 1.0, 1.0),   -- button top/left inset highlight
        chromeSh = rgba(0.0, 0.0, 0.0, 1.0),    -- button bottom/right inset shadow
        -- Groove divider: recessed channel effect (dark line + light line)
        grooveDark  = rgba(0.0, 0.0, 0.0, 0.50),
        grooveLight = rgba(1.0, 1.0, 1.0, 0.06),
        -- Overlay / modal scrim
        modalOverlayA = 0.50,
        -- Interactive state opacities
        selectionA    = 0.30,   -- selected row bg alpha: one accent wash, the same in all three themes
        dangerPulseMin = 0.08,  -- danger button sine pulse floor
        dangerPulseMax = 0.12,  -- danger button sine pulse ceiling (capped: red text must stay legible over the pulse)
        dangerHoverMul = 1.20,  -- danger text brightness on hover
        -- Scrollbar thumb opacities
        scrollThumbA      = 0.30,   -- default thumb
        scrollThumbHoverA = 0.20,   -- hover state
        scrollThumbDragA  = 0.30,   -- drag state
        -- Badge bg opacity
        badgeBgA = 0.10,
        -- Resize ridge opacities
        ridgeLightA = 0.40,
        ridgeDarkA  = 0.20,
        -- Drawer background overlay: dark = subtle black scrim, light = near-white lift
        drawerBg    = rgba(0.0, 0.0, 0.0, 0.15),
        -- Soiled condition flags (inventory row dock labels)
        soiledWet   = rgba(96/255, 176/255, 232/255, 0.9),   -- blue
        soiledBlood = rgba(255/255, 106/255, 106/255, 0.9),   -- red
        soiledDirt  = rgba(200/255, 152/255, 96/255, 0.9),    -- brown
        -- Patch material colors (condition bars + dock labels)
        matLeather  = hex("#B08A5E"),   -- warm brown
        matDenim    = hex("#5B8ABF"),   -- slate blue
        matFabric   = rgba(1, 1, 1, 0.55),  -- neutral white
        -- Thermal spectrum (5-stop: cold → cool → normal → warm → hot)
        tempCold = rgba(60/255, 120/255, 220/255, 1.0),
        tempCool = rgba(60/255, 180/255, 140/255, 1.0),
        tempNorm = rgba(120/255, 200/255, 80/255, 1.0),
        tempWarm = rgba(220/255, 180/255, 50/255, 1.0),
        tempHot  = rgba(220/255, 80/255, 40/255, 1.0),
        -- Thermal badge tints (bg + text pairs)
        tempColdBadge = { bg = rgba(60/255, 120/255, 220/255, 0.15), text = rgba(90/255, 150/255, 240/255, 1.0) },
        tempCoolBadge = { bg = rgba(60/255, 180/255, 140/255, 0.12), text = rgba(80/255, 195/255, 155/255, 1.0) },
        tempNormBadge = { bg = rgba(120/255, 200/255, 80/255, 0.12), text = rgba(130/255, 210/255, 90/255, 1.0) },
        tempWarmBadge = { bg = rgba(220/255, 180/255, 50/255, 0.15), text = rgba(230/255, 190/255, 60/255, 1.0) },
        tempHotBadge  = { bg = rgba(220/255, 80/255, 40/255, 0.15), text = rgba(235/255, 95/255, 55/255, 1.0) },
    },

    light = {
        name     = "Light",
        -- the list menu's marks: dark enough for 4.5 : 1 on the grey surface (blue 4.6, red 4.8; the red reads as rust)
        markAdd    = hex("#014E8E"),
        markRemove = hex("#872801"),
        base     = hex("#C6C6C6", 0.97),
        onBand   = hex("#A6A6A6", 1.0),
        surf1    = hex("#BEBEBE", 0.97),
        surf2    = hex("#B6B6B6", 0.97),
        surf3    = hex("#AEAEAE", 0.97),
        surf4    = hex("#A6A6A6", 0.97),
        border   = hex("#969696", 1.0),
        borderS  = hex("#767676", 1.0),
        -- the belt's slot and pouch frame: the strong border stands only 2.3:1 off the slots' fill, so
        -- frameS, the keyline, stands 3:1 off the fill, and frameHi, a light line outside it, 3:1 off the leather strap
        frameS   = hex("#424242", 1.0),
        frameHi  = hex("#D2D2D2", 1.0),
        text     = rgba(0.047, 0.047, 0.047, 0.95),  -- neutral near-black
        textSec  = rgba(0.047, 0.047, 0.047, 0.72),  -- neutral recessed (overwritten to accent at runtime)
        textDim  = rgba(0.047, 0.047, 0.047, 0.72),  -- structural chrome
        textHead = rgba(0.02, 0.02, 0.02, 1.00),     -- neutral near-black chrome
        stripe   = rgba(0.0, 0.0, 0.0, 0.05),        -- subtle dark texture on mid-gray
        danger   = hex("#7A2A11"),
        warning  = hex("#6B5510"),
        positive = hex("#2A5511"),
        -- (positive reads 4.3 : 1 on surface 2 here, so its text is darker)
        positiveText = hex("#204A0C"),
        dangerText   = hex("#7A2A11"),
        info     = hex("#1A5566"),
        violet   = hex("#552288"),
        borderW  = 1,
        -- (a grayed label at 0.42 read 2.2 : 1 on these surfaces, "nearly invisible"; 0.6 is 3.3 : 1 or more, as Dark reads at its 0.42)
        disabledAlpha = 0.6,
        chromeHi = rgba(1.0, 1.0, 1.0, 1.0),
        chromeSh = rgba(0.0, 0.0, 0.0, 0.40),
        grooveDark  = rgba(0.0, 0.0, 0.0, 0.30),
        grooveLight = rgba(1.0, 1.0, 1.0, 0.50),
        modalOverlayA = 0.35,
        selectionA    = 0.30,
        dangerPulseMin = 0.08,
        dangerPulseMax = 0.12,
        dangerHoverMul = 1.15,
        scrollThumbA      = 0.30,
        scrollThumbHoverA = 0.20,
        scrollThumbDragA  = 0.30,
        badgeBgA = 0.12,
        ridgeLightA = 0.50,
        ridgeDarkA  = 0.25,
        -- Drawer background: subtle white lift over surf1 (just a tad lighter than item card)
        drawerBg    = rgba(1.0, 1.0, 1.0, 0.12),
        -- Soiled condition flags (darker for contrast on light surfaces)
        soiledWet   = rgba(40/255, 110/255, 180/255, 0.9),    -- deep blue
        soiledBlood = rgba(160/255, 40/255, 40/255, 0.9),     -- dark red
        soiledDirt  = rgba(130/255, 90/255, 50/255, 0.9),     -- dark brown
        -- Patch material colors
        matLeather  = hex("#7A5A38"),   -- dark brown
        matDenim    = hex("#2A5588"),   -- deep blue
        matFabric   = rgba(0.2, 0.2, 0.2, 0.65),  -- dark neutral
        -- Thermal spectrum (darker for contrast on light surfaces)
        tempCold = rgba(30/255, 80/255, 180/255, 1.0),    -- deeper blue
        tempCool = rgba(20/255, 130/255, 100/255, 1.0),   -- deeper teal
        tempNorm = rgba(70/255, 150/255, 40/255, 1.0),    -- deeper green
        tempWarm = rgba(180/255, 130/255, 20/255, 1.0),   -- deeper amber
        tempHot  = rgba(190/255, 50/255, 20/255, 1.0),    -- deeper red
        -- Thermal badge tints (darker text for light bg)
        tempColdBadge = { bg = rgba(30/255, 80/255, 180/255, 0.15), text = rgba(25/255, 65/255, 150/255, 1.0) },
        tempCoolBadge = { bg = rgba(20/255, 130/255, 100/255, 0.12), text = rgba(15/255, 105/255, 80/255, 1.0) },
        tempNormBadge = { bg = rgba(70/255, 150/255, 40/255, 0.12), text = rgba(55/255, 125/255, 30/255, 1.0) },
        tempWarmBadge = { bg = rgba(180/255, 130/255, 20/255, 0.15), text = rgba(150/255, 105/255, 10/255, 1.0) },
        tempHotBadge  = { bg = rgba(190/255, 50/255, 20/255, 0.15), text = rgba(160/255, 40/255, 15/255, 1.0) },
    },

    hicon = {
        name     = "High contrast",
        markAdd    = hex("#4491E2"),   -- the list menu's marks: Dark's pair (blue 5.7 : 1, red 4.8 here)
        markRemove = hex("#D9572A"),
        base     = hex("#050505", 0.95),
        onBand   = hex("#000000", 1.0),
        surf1    = hex("#111111", 0.95),
        surf2    = hex("#191919", 0.95),
        surf3    = hex("#202020", 0.95),
        surf4    = hex("#292929", 0.95),
        border   = hex("#353535", 1.0),
        borderS  = hex("#555555", 1.0),
        -- (frameS / frameHi, the belt's slot frame: unset here, so the strong border and no outer line)
        text     = rgba(1.0, 1.0, 1.0, 0.95),
        textSec  = rgba(0.78, 0.78, 0.78, 0.75),
        textDim  = rgba(0.78, 0.78, 0.78, 0.75),
        textHead = rgba(1.0, 1.0, 1.0, 0.98),
        stripe   = rgba(1.0, 1.0, 1.0, 0.06),
        danger   = hex("#FF5533"),
        warning  = hex("#FFCC22"),
        positive = hex("#44DD44"),
        positiveText = hex("#44DD44"),
        dangerText   = hex("#FF5533"),
        info     = hex("#44CCFF"),
        violet   = hex("#CC99FF"),
        borderW  = 2,     -- thicker borders for accessibility
        -- (0.55: a grayed label 5.2 : 1 or more on these surfaces, as High Contrast should read; at 0.42 it read 3.7 : 1)
        disabledAlpha = 0.55,
        chromeHi = rgba(1.0, 1.0, 1.0, 1.0),
        chromeSh = rgba(0.0, 0.0, 0.0, 1.0),
        grooveDark  = rgba(0.0, 0.0, 0.0, 0.65),
        grooveLight = rgba(1.0, 1.0, 1.0, 0.10),
        modalOverlayA = 0.60,
        selectionA    = 0.30,
        dangerPulseMin = 0.10,
        dangerPulseMax = 0.12,
        dangerHoverMul = 1.15,
        scrollThumbA      = 0.40,
        scrollThumbHoverA = 0.30,
        scrollThumbDragA  = 0.40,
        badgeBgA = 0.15,
        ridgeLightA = 0.50,
        ridgeDarkA  = 0.30,
        -- Drawer background: same black scrim as dark theme
        drawerBg    = rgba(0.0, 0.0, 0.0, 0.15),
        -- Soiled condition flags (bright/saturated for max contrast)
        soiledWet   = rgba(80/255, 200/255, 255/255, 1.0),    -- bright cyan
        soiledBlood = rgba(255/255, 80/255, 80/255, 1.0),     -- bright red
        soiledDirt  = rgba(230/255, 170/255, 100/255, 1.0),   -- bright tan
        -- Patch material colors
        matLeather  = hex("#D4A870"),   -- bright brown
        matDenim    = hex("#70AAEE"),   -- bright blue
        matFabric   = rgba(1, 1, 1, 0.70),  -- bright white
        -- Thermal spectrum (bright/saturated for max contrast)
        tempCold = rgba(60/255, 120/255, 220/255, 1.0),
        tempCool = rgba(60/255, 180/255, 140/255, 1.0),
        tempNorm = rgba(120/255, 200/255, 80/255, 1.0),
        tempWarm = rgba(220/255, 180/255, 50/255, 1.0),
        tempHot  = rgba(220/255, 80/255, 40/255, 1.0),
        -- Thermal badge tints (bg + text pairs)
        tempColdBadge = { bg = rgba(60/255, 120/255, 220/255, 0.15), text = rgba(90/255, 150/255, 240/255, 1.0) },
        tempCoolBadge = { bg = rgba(60/255, 180/255, 140/255, 0.12), text = rgba(80/255, 195/255, 155/255, 1.0) },
        tempNormBadge = { bg = rgba(120/255, 200/255, 80/255, 0.12), text = rgba(130/255, 210/255, 90/255, 1.0) },
        tempWarmBadge = { bg = rgba(220/255, 180/255, 50/255, 0.15), text = rgba(230/255, 190/255, 60/255, 1.0) },
        tempHotBadge  = { bg = rgba(220/255, 80/255, 40/255, 0.15), text = rgba(235/255, 95/255, 55/255, 1.0) },
    },
}

-- ---------------------------------------------------------------------------
-- ACCENT COLORS
-- Each accent defines colors for dark and light base themes.
-- High Contrast uses dark values but the base theme's brighter status colors
-- provide the extra contrast.
-- ---------------------------------------------------------------------------
ZeD.AccentColors = {

    red = {
        name = "Red",
        dark  = { accent = hex("#CC4444"), bright = hex("#EE6666"), hover = hex("#CC4444", 0.22), textOnAccent = hex("#0C0C0C") },
        light = { accent = hex("#7A1A1A"), bright = hex("#AA3333"), hover = hex("#7A1A1A", 0.15), textOnAccent = hex("#F2F0EC") },
    },
    orange = {
        name = "Orange",
        dark  = { accent = hex("#D4922A"), bright = hex("#E8A830"), hover = hex("#D4922A", 0.22), textOnAccent = hex("#0C0C0C") },
        light = { accent = hex("#7A5010"), bright = hex("#B07818"), hover = hex("#7A5010", 0.15), textOnAccent = hex("#F2F0EC") },
    },
    yellow = {
        name = "Yellow",
        dark  = { accent = hex("#CCAA22"), bright = hex("#EEDD44"), hover = hex("#CCAA22", 0.22), textOnAccent = hex("#0C0C0C") },
        light = { accent = hex("#6B5F0A"), bright = hex("#998811"), hover = hex("#6B5F0A", 0.15), textOnAccent = hex("#F2F0EC") },
    },
    green = {
        name = "Green",
        dark  = { accent = hex("#44AA44"), bright = hex("#66CC66"), hover = hex("#44AA44", 0.20), textOnAccent = hex("#0C0C0C") },
        light = { accent = hex("#125518"), bright = hex("#338833"), hover = hex("#125518", 0.15), textOnAccent = hex("#F2F0EC") },
    },
    blue = {
        name = "Blue",
        dark  = { accent = hex("#4488CC"), bright = hex("#66AAEE"), hover = hex("#4488CC", 0.20), textOnAccent = hex("#0C0C0C") },
        light = { accent = hex("#1A4477"), bright = hex("#336699"), hover = hex("#1A4477", 0.15), textOnAccent = hex("#F2F0EC") },
    },
    teal = {
        name = "PZ Teal",
        dark  = { accent = hex("#47A18C"), bright = hex("#5CC4AA"), hover = hex("#47A18C", 0.22), textOnAccent = hex("#0C0C0C") },
        light = { accent = hex("#1A6655"), bright = hex("#3A8A77"), hover = hex("#1A6655", 0.15), textOnAccent = hex("#F2F0EC") },
    },
    purple = {
        name = "Purple",
        dark  = { accent = hex("#8855BB"), bright = hex("#AA77DD"), hover = hex("#8855BB", 0.20), textOnAccent = hex("#0C0C0C") },
        light = { accent = hex("#441888"), bright = hex("#6644AA"), hover = hex("#441888", 0.15), textOnAccent = hex("#F2F0EC") },
    },
    pink = {
        name = "Pink",
        dark  = { accent = hex("#DD5588"), bright = hex("#FF77AA"), hover = hex("#DD5588", 0.20), textOnAccent = hex("#0C0C0C") },
        light = { accent = hex("#882244"), bright = hex("#BB4470"), hover = hex("#882244", 0.15), textOnAccent = hex("#F2F0EC") },
    },
    mono = {
        name = "None",
        dark  = { accent = hex("#888888"), bright = hex("#AAAAAA"), hover = hex("#888888", 0.20), textOnAccent = hex("#0C0C0C") },
        light = { accent = hex("#3A3A3A"), bright = hex("#666666"), hover = hex("#3A3A3A", 0.15), textOnAccent = hex("#F2F0EC") },
    },
}

-- ---------------------------------------------------------------------------
-- FONT ATOMICS — ZeD.Font
-- Rich font entries: { font = UIFont.*, px = N }
-- .font = the UIFont enum value for drawText / MeasureStringX
-- .px   = base pixel size (1x scale) for deriving scale factors
-- The rest of the system references ZeD.Font.* — never UIFont.* directly.
--
-- The pairing: Fira Mono + Fira Sans Condensed (SIL OFL)
-- 5 typography roles (F-system):
--   F1 Chrome  — Fira Mono Bold              (title bars, tabs, button labels)
--   F2 Body    — Fira Sans Regular            (list rows, content text)
--   F3 Data    — Fira Mono Regular           (numbers, percentages, stat values)
--   F4 Heading — Fira Sans Cond. SemiBold   (section headers, item names)
--   F5 Micro   — Fira Sans Cond. Regular     (chips, badges, metadata labels)
-- ---------------------------------------------------------------------------
local F = {}
-- The bitmap role fonts (5 roles × 2 size presets = 10). ZeD.TextSizes takes each one's px for
-- its preset; the text itself draws with the distance-field faces in F.sdf below
F.sec        = { font = UIFont.NewMedium,  px = 11 }  -- F1 Chrome: Fira Mono Bold 11px (small)
F.secLg      = { font = UIFont.NewSmall,   px = 13 }  -- F1 Chrome: Fira Mono Bold 13px (large)
F.body       = { font = UIFont.Small,      px = 13 }  -- F2 Body: Fira Sans Regular 13px (small)
F.bodyLg     = { font = UIFont.Large,      px = 15 }  -- F2 Body: Fira Sans Regular 15px (large)
F.stat       = { font = UIFont.Medium,     px = 11 }  -- F3 Data: Fira Mono Regular 11px (small)
F.statLg     = { font = UIFont.CodeMedium, px = 13 }  -- F3 Data: Fira Mono Regular 13px (large)
F.head       = { font = UIFont.NewLarge,   px = 15 }  -- F4 Heading: Fira Sans Cond. SemiBold 15px (small)
F.headLg     = { font = UIFont.CodeLarge,  px = 17 }  -- F4 Heading: Fira Sans Cond. SemiBold 17px (large)
F.title      = { font = UIFont.Code,       px =  9 }  -- F5 Micro: Fira Sans Cond. Regular 9px (small)
F.titleLg    = { font = UIFont.CodeSmall,  px = 11 }  -- F5 Micro: Fira Sans Cond. Regular 11px (large)
-- Reserved slots (4 — speech, TV/radio, HOW YOU DIED, TBD). Nothing reads these entries, and each
-- slot now holds another face (EN/fonts.txt):
F.rsv1       = { font = UIFont.Cred1,     px = 20 }  -- (Cred1 holds Noto Sans SC, ZeD's simplified Chinese face, for ZeD.Text.scriptFont; Chicago is off the list)
F.rsv2       = { font = UIFont.Cred2,     px = 24 }  -- (Cred2 holds the F5 Micro distance-field face below; Chicago 24px is off the list)
F.rsv3       = { font = UIFont.MainMenu1, px = 16 }  -- (MainMenu1 holds the F2 Body distance-field face below; Lekton Bold 16px is off the list)
F.rsv4       = { font = UIFont.MainMenu2, px = 20 }  -- (MainMenu2 holds the F1 Chrome distance-field face below; Lekton Bold 20px is off the list)

-- Distance-field Fira (crisp at any zoom) on spare slots: the windows and the HUD props draw with
-- these, and the bitmap entries above give each text-size preset its px.
-- face / lineH = the atlas metrics (64 px face, lineH approximate). The engine draws an SDF atlas at its
-- native face at zoom 1 and its edge smoothing is a fixed band tuned for drawing a face at ~0.4x, so the
-- face is baked at 64 px: body 13 px x root 2 = 26 px lands at 0.4x (crisp), 1080p at 0.2x (hard-edged).
-- (rsv3 / rsv4 Lekton are unmapped while MainMenu1/2 carry these; nothing used them.)
-- When the game's fonts replace these atlases (Chinese, Japanese, Korean, Thai, Dyslexic font),
-- ZeD.Text.checkRoleFonts repoints .font / .face at the game's stand-in and keeps ZeD's own
-- values in .slot / .zedFace, so callers that read .font and .face follow without changes.
F.sdf = {
    sec   = { font = UIFont.MainMenu2, px = 11, face = 64, lineH = 77, sdf = true },  -- F1 Chrome: Fira Mono Bold
    body  = { font = UIFont.MainMenu1, px = 13, face = 64, lineH = 77, sdf = true },  -- F2 Body: Fira Sans Medium
    stat  = { font = UIFont.Title,     px = 11, face = 64, lineH = 77, sdf = true },  -- F3 Data: Fira Mono
    head  = { font = UIFont.Massive,   px = 15, face = 64, lineH = 77, sdf = true },  -- F4 Heading: Fira Sans Cond SemiBold
    title = { font = UIFont.Cred2,     px =  9, face = 64, lineH = 77, sdf = true },  -- F5 Micro: Fira Sans Cond (MediumNew ignores the manifest; Cred2 frees rsv2 Chicago, unused)
}
ZeD.Font = F

-- ---------------------------------------------------------------------------
-- TEXT SIZE PRESETS
-- Two presets with true font scaling. Each preset uses genuinely distinct
-- pixel sizes. 5 typography roles (F-system):
--   fontF1 (Fira Mono Bold), fontF2 (Fira Sans Regular),
--   fontF3 (Fira Mono Regular), fontF4 (Fira Sans Cond. SemiBold),
--   fontF5 (Fira Sans Cond. Regular)
-- ---------------------------------------------------------------------------
ZeD.TextSizes = {

    small = {
        name       = "Small",
        scale      = 1.00,
        fontF1     = F.sec,          -- F1 Chrome: Fira Mono Bold 11px
        fontF2     = F.body,         -- F2 Body: Fira Sans Regular 13px
        fontF3     = F.stat,         -- F3 Data: Fira Mono Regular 11px
        fontF4     = F.head,         -- F4 Heading: Fira Sans Cond. SemiBold 15px
        fontF5     = F.title,        -- F5 Micro: Fira Sans Cond. Regular 9px
        titleBarH  = 26,
        rowH       = 30,
        buttonH    = 26,
        tabH       = 24,
        inputH     = 26,
        iconSm     = 16,
        iconMd     = 24,
        iconLg     = 32,
        iconXl     = 48,
        fillBarH   = 13,
        checkboxSz = 13,
        closeBoxSz = 13,
        statIconSz = 12,
        contentPad = 10,
        colGap     = 12,
        cardIconSz = 40,
        contextRowH = 24,
        modalW     = 320,
        modalH     = 160,
        minWinW    = 360,
        minWinH    = 220,
    },

    large = {
        name       = "Large",
        scale      = 1.15,
        fontF1     = F.secLg,        -- F1 Chrome: Fira Mono Bold 13px
        fontF2     = F.bodyLg,       -- F2 Body: Fira Sans Regular 15px
        fontF3     = F.statLg,       -- F3 Data: Fira Mono Regular 13px
        fontF4     = F.headLg,       -- F4 Heading: Fira Sans Cond. SemiBold 17px
        fontF5     = F.titleLg,      -- F5 Micro: Fira Sans Cond. Regular 11px
        titleBarH  = 30,
        rowH       = 34,
        buttonH    = 30,
        tabH       = 28,
        inputH     = 30,
        iconSm     = 16,
        iconMd     = 24,
        iconLg     = 32,
        iconXl     = 48,
        fillBarH   = 15,
        checkboxSz = 15,
        closeBoxSz = 15,
        statIconSz = 14,
        contentPad = 12,
        colGap     = 14,
        cardIconSz = 44,
        contextRowH = 28,
        modalW     = 360,
        modalH     = 180,
        minWinW    = 400,
        minWinH    = 260,
    },
}

-- ---------------------------------------------------------------------------
-- SPACING SCALE
-- Fixed values that don't change with theme. In pixels.
-- ---------------------------------------------------------------------------
ZeD.Spacing = {
    xs  = 6,
    sm  = 10,
    md  = 14,
    lg  = 18,
    xl  = 24,
    xxl = 32,
    -- Component-specific spacing (fixed, not theme-dependent)
    iconGap       = 8,    -- gap between icon and label in a list row
    statGap       = 14,   -- gap between stat chips in title bar
    statIconGap   = 6,    -- gap between stat chip icon and text
    tabPadX       = 14,   -- horizontal padding inside tabs
    tabGap        = 3,    -- gap between tab buttons
    buttonPadX    = 14,   -- horizontal padding inside buttons
    inputPadX     = 10,   -- horizontal padding inside text inputs
    sectionIndent = 18,   -- indentation per collapsible section level
    scrollbarW    = 14,   -- scrollbar total width
    scrollGripOff = 3,    -- scrollbar grip line offset from center
    scrollGripMar = 6,    -- scrollbar grip line margin from edges
    badgePadX     = 9,    -- horizontal padding inside status badges
    badgePadY     = 3,    -- vertical padding inside status badges
    badgeGap      = 6,    -- gap between adjacent badges
    gridCellGap   = 3,    -- gap between grid cells
    gridCellPad   = 6,    -- padding inside grid cells
    titleBoxPad   = 3,    -- knockout box padding around title/stat text
    resizeHotZone = 4,    -- resize detection zone at window edges
    contextPadH   = 14,   -- deprecated: nothing reads it (the vanilla-list skin override did); T.ctx serves the strip menu
    contextPadV   = 5,    -- deprecated, as above
    contextSafeM  = 4,    -- deprecated, as above
    textLineGap   = 4,    -- micro-gap between stacked text lines (name → subtitle, name → badges)
    beforeHead    = 8,    -- padding above section headings
    headGap       = 8,    -- gap below section headings
    rowGap        = 6,    -- gap between data rows (stat lines, kill rows, etc.)
    afterLine     = 10,   -- padding below divider lines
    afterGroove   = 8,    -- padding below groove dividers
    -- Card layout rhythm: 4/8/4/6 rule
    cardBeforeHead = 4,   -- space before a card section heading
    cardAfterHead  = 8,   -- space after a card heading (before body content)
    cardAfterBody  = 4,   -- space after card body content
    cardAfterLabel = 6,   -- space after card labels / between bars
    colHdrH       = 20,   -- column header bar height (NAME / SLOT / BITE etc.); T.sp.colHdrH is T.sortBarH
    catHdrH       = 15,   -- category header row height in inventory lists
    tabHeaderH    = 37,   -- pinned drawer / tab header strip height; T.sp.tabHeaderH is T.stripH
                          -- (both follow the text size: applyTheme sets them from the shared rows)
    figurePadTop  = 12,   -- padding above body figure in Health/Protection/Thermal tabs
    figureW       = 220,  -- body figure width  (shared by Health/Protection/Thermal)
    figureH       = 260,  -- body figure height (shared by Health/Protection/Thermal)
    pillBtnPadV   = 10,   -- vertical padding added to secH for pill-style buttons
}

-- ---------------------------------------------------------------------------
-- CONTEXT MENU TOKENS (the unified horizontal strip)
-- All geometry, motion, and state dims for ZeD_ContextMenu and its molecules.
-- Fixed across themes. Exposed on T.ctx at render time.
-- ---------------------------------------------------------------------------
ZeD.Ctx = {
    -- CELL GEOMETRY — the atomic unit of the strip
    cellW       = 22,   -- one cell is 22x22 px
    cellH       = 22,
    iconPx      = 16,   -- 16x16 icon centered inside the cell (leaves 3px padding)
    gap         = 1,    -- 1px ink gridline between cells (painted by strip bg showing through)

    -- STRIP CAPACITY — truncation / visual loop kick in above this
    maxVisible  = 10,   -- at 11+ items we triple-render and scroll the window

    -- CHROME DIMENSIONS
    bumperMinW  = 28,   -- paper bumper at each end of the strip row
    chevW       = 12,   -- truncation chevron glyph block width (conditional)
    gutter      = 3,    -- gap between bumper / chev / strip / chev / bumper
    balloonW    = 230,  -- fixed balloon width — same whether strip is narrow or wide

    -- SMALL INDICATOR ATOMS
    pinDotSz      = 3,  -- 3x3 accent square top-right of a pinned cell
    submenuTriSz  = 3,  -- 3x3 corner triangle bottom-right when cell has children

    -- SHADOW + POINTER PRIMITIVES (System 7 pill / balloon chrome)
    shadowStep       = 2,  -- 2px stepped drop shadow (offset down-right)
    pointerTriOuter  = 6,  -- outer ink triangle of the label/balloon pointer
    pointerTriInner  = 5,  -- inner paper triangle, 1px inset — creates the outlined look

    -- VERTICAL RHYTHM OF THE ASSEMBLY STACK
    labelMarginV       = 28, -- from strip top up to label center (label floats above)
    targetCardMarginV  = 10, -- from strip bottom down to target card top
    balloonMarginV     = 10, -- from target card bottom down to balloon top
    targetIconPx       = 18, -- item icon tile inside the target card (larger than strip icon)

    -- MOTION TIMINGS
    animMs         = 180, -- all track / label / width transitions
    settleDelayMs  = 200, -- wait after animation end before silently teleporting the carousel

    -- STATE CHROME
    drilledBorderTop = 2, -- strip top border thickens 1px -> 2px when a submenu is open

    -- THE MARKS (punch list 138; design handoff Nov 9 2026): the plus or minus, in or out arrow, or strike that
    -- tells the two actions of a pair apart, colored at rest over the ink. Literals like the paper and ink they sit
    -- on (#F2F2F2, #141414), not theme colors: blue 5.5 : 1 and red 4.6 : 1 on the paper, and the two hold apart
    -- under all three kinds of color blindness. ZeD.PxIconMark (ContextPxIcons.lua) says which icon takes which.
    markAdd    = { r = 0x0B / 255, g = 0x63 / 255, b = 0xB0 / 255, a = 1 },   -- #0B63B0: add, take, load, in, on, up
    markRemove = { r = 0xC2 / 255, g = 0x41 / 255, b = 0x0C / 255, a = 1 },   -- #C2410C: remove, put, drop, out, off
}

-- ---------------------------------------------------------------------------
-- GAMEPAD TOKENS
-- All geometry, thresholds, and timings for the gamepad input stack.
-- Fixed across themes. Exposed on T.gp at render time.
--
-- InputModeDetector reads the detection thresholds, and FocusManager the hold,
-- repeat and aiming-escape values. The focus ring, the prompts, the Layout Mode
-- HUD and the strip menus have no reader yet: their values wait here so the
-- parts that will draw them find them ready.
-- ---------------------------------------------------------------------------
ZeD.Gp = {
    -- FOCUS RING (no reader yet) ---------------------------------------------
    focusRingW    = 2,        -- border width in pixels around the focused element
    focusRingPad  = 1,        -- inset from element edge so the ring sits inside the border
    focusFillA    = 0.10,     -- inner fill alpha when focused (accent-tinted wash)

    -- BUTTON PROMPTS (no reader yet) -----------------------------------------
    promptSize    = 16,       -- standard glyph size for footer prompt strips
    promptSizeSm  = 12,       -- small glyph size for inline / dense contexts
    promptGap     = 4,        -- gap between glyph and its label text

    -- LAYOUT MODE HUD (no reader yet) ----------------------------------------
    layoutHudH       = 22,    -- banner height when a window enters Layout Mode
    layoutHudY       = 4,     -- banner vertical offset from the title bar
    layoutMoveStep   = 8,     -- pixels per D-pad tap in Layout Mode
    layoutResizeStep = 8,     -- pixels per trigger/bumper tap in Layout Mode

    -- DETECTION THRESHOLDS (InputModeDetector reads these) -------------------
    -- Mirrored here from InputModeDetector so they can be tweaked at runtime
    -- via console (`ZeD.T.gp.stickThresh = 0.25`) during controller tuning.
    -- The detector reads these from T.gp on every poll, never hardcoded.
    stickThresh   = 0.20,     -- sqrt(lx² + ly²) radial deadzone — filters stick drift
    triggerThresh = 0.15,     -- abs(trigger) threshold — filters resting finger weight
    cooldownMs    = 200,      -- minimum ms between mode switches (last-event-wins)

    -- BUMPER CHORD -----------------------------------------------------------
    chordWindowMs = 250,      -- how long after first bumper press to wait for chord completion. No reader:
                              -- BumperChord keeps no arming timeout any more, so this can go

    -- HOLD-TO-REPEAT — D-PAD SPATIAL NAV (FocusManager) ----------------------
    holdInitMs    = 250,      -- initial delay before D-pad nav starts auto-repeating
    holdRepeatMs  = 120,      -- interval between auto-repeat ticks once started

    -- AIMING ESCAPE — RIGHT-STICK MAGNITUDE² THRESHOLD (FocusManager) --------
    -- FocusManager polls right-stick every tick while a ZeD window is focused.
    -- When the stick is pushed past this threshold, the window is shaded and
    -- focus is released so gameplay input resumes instantly. Threshold is in
    -- squared magnitude units (|v|² = x² + y²) to avoid a sqrt call per tick.
    -- 0.81 ≈ 90% of full deflection on a unit-circle stick.
    aimingThresholdSq = 0.81,

    -- HOLD DETECTION — B-HOLD and Y-HOLD (the tap/hold dismiss) --------------
    -- Shared threshold for `cancel` (B) and `window_control` (Y) hold actions.
    -- ActionMap declares `holdMs = 400` on those entries; FocusManager reads
    -- this token to drive the hold timer.
    holdMs        = 400,

    -- D-PAD STRIP MENUS (no reader yet) --------------------------------------
    stripAnchorY    = "bottomCenter",  -- symbolic anchor consumed by strip layout
    stripBottomGap  = 24,              -- pixels from screen bottom to strip baseline
    stripDismissMs  = 150,             -- fade-out duration on dismiss
}

-- ---------------------------------------------------------------------------
-- RADIO CHASSIS TOKENS (the first contextual drawer chassis)
-- Hardware colors — NOT theme-dependent. The chassis is its own visual
-- language; chrome (window, ring, accent) stays in T.surfX / T.accent.
--
-- Two tiers: Premium Technologies (silver Pioneer-style hi-fi, cyan VFD,
-- green-VFD CD module) vs ValuTech (cheap black plastic, backlit amber LCD,
-- no CD). The two are intentionally visually opposite so brand reads at-a-
-- glance: lit-on-dark VFD vs dark-on-lit LCD.
--
-- Sub-namespaces:
--   pt   = Premium chassis (silver)
--   vfd  = Premium main display (cyan phosphor on dark)
--   cd   = Premium CD module display (green phosphor on dark)
--   vt   = ValuTech chassis (black plastic)
--   lcd  = ValuTech main display (amber backlit, dark digits — INVERSE of VFD)
-- ---------------------------------------------------------------------------
-- Mutate-in-place pattern: ensure the table identity is preserved across
-- /lua reload so any code that captured `ZeD.Radio` or `T.radio` sees the
-- updated field values without needing applyTheme() to re-fire.
ZeD.Radio = ZeD.Radio or {}
ZeD.Radio.pt  = ZeD.Radio.pt  or {}
ZeD.Radio.vfd = ZeD.Radio.vfd or {}
ZeD.Radio.cd  = ZeD.Radio.cd  or {}
ZeD.Radio.vt  = ZeD.Radio.vt  or {}
ZeD.Radio.lcd = ZeD.Radio.lcd or {}

-- Premium chassis (silver hi-fi)
ZeD.Radio.pt.chassisBg     = hex("#B8B8B8")
ZeD.Radio.pt.recessedBg    = hex("#5A5A5A")
ZeD.Radio.pt.recessedHi    = hex("#3A3A3A")  -- top-left bevel (dark = inset)
ZeD.Radio.pt.recessedSh    = hex("#757575")  -- bottom-right bevel (light = inset)
ZeD.Radio.pt.btnBg         = hex("#C8C8C8")
ZeD.Radio.pt.btnBorder     = hex("#888888")
ZeD.Radio.pt.btnText       = hex("#1A1A1A")
ZeD.Radio.pt.brandBarBg    = hex("#D0D0D0")
ZeD.Radio.pt.silkScreen    = hex("#D8D8D8")

-- Premium main VFD (cyan)
ZeD.Radio.vfd.bg     = hex("#050A14")  -- dark blue display background
ZeD.Radio.vfd.bright = hex("#66DDFF")  -- cyan lit
ZeD.Radio.vfd.dim    = hex("#4499BB")  -- cyan dim (off-state still partly lit)
ZeD.Radio.vfd.off    = hex("#1A3A4A")  -- cyan very dim (segment unlit on dark bg)

-- Premium CD player VFD (green phosphor)
ZeD.Radio.cd.bg     = hex("#050A14")
ZeD.Radio.cd.bright = hex("#44EE44")
ZeD.Radio.cd.dim    = hex("#1A3A1A")

-- ValuTech chassis (cheap black plastic)
ZeD.Radio.vt.chassisBg  = hex("#1A1A1A")
ZeD.Radio.vt.recessedBg = hex("#0A0A0A")
ZeD.Radio.vt.recessedHi = hex("#050505")
ZeD.Radio.vt.recessedSh = hex("#3A3A3A")
ZeD.Radio.vt.btnBg      = hex("#2A2A2A")
ZeD.Radio.vt.btnBorder  = hex("#050505")
ZeD.Radio.vt.btnText    = hex("#E0E0E0")
ZeD.Radio.vt.silkScreen = hex("#888888")

-- ValuTech main LCD (backlit amber, dark digits — INVERSE of VFD)
ZeD.Radio.lcd.bg      = hex("#D4881F")
ZeD.Radio.lcd.fg      = hex("#1A0500")
ZeD.Radio.lcd.fgDim   = hex("#2A1505")
ZeD.Radio.lcd.segOn   = hex("#1A0500")
ZeD.Radio.lcd.segOff  = hex("#C47015")
ZeD.Radio.lcd.chipOff = hex("#5A3010")

-- ---------------------------------------------------------------------------
-- READABLE TEXT COLOURS
-- Text tokens are derived from the surfaces they sit on, not picked by hand:
-- a colour moves only as far toward the surface's contrasting end (white on
-- dark surfaces, black on light) as it needs to reach the target ratio.
-- 4.6 for text, 3.0 for headings and marks (WCAG). Fills, dots and bars keep
-- the plain colours; only text uses the derived ones.
-- Runs where the palette is rebuilt (applyTheme, and a window's own accent
-- palette), never per frame.
-- ---------------------------------------------------------------------------
local function lin(c)
    if c <= 0.03928 then return c / 12.92 end
    return ((c + 0.055) / 1.055) ^ 2.4
end

local function lum(c)
    return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b)
end

--- WCAG contrast ratio of two {r,g,b} colours (alpha ignored)
function ZeD.contrast(a, b)
    local l1, l2 = lum(a), lum(b)
    if l1 < l2 then l1, l2 = l2, l1 end
    return (l1 + 0.05) / (l2 + 0.05)
end

--- fg moved toward white (up = true) or black in 4% steps until it has minR against
--- every opaque colour in bgs; the first step that passes, so the hue stays as close as it can
function ZeD.legible(fg, minR, bgs, up)
    local goal = up and 1 or 0
    for i = 0, 25 do
        local t = i * 0.04
        local c = { r = fg.r + (goal - fg.r) * t, g = fg.g + (goal - fg.g) * t, b = fg.b + (goal - fg.b) * t, a = 1 }
        local ok = true
        for j = 1, #bgs do
            if ZeD.contrast(c, bgs[j]) < minR then ok = false; break end
        end
        if ok then return c end
    end
    return { r = goal, g = goal, b = goal, a = 1 }
end

local INK, PAPER = hex("#0C0C0C"), hex("#F2F0EC")
local BLACK, WHITE = { r = 0, g = 0, b = 0, a = 1 }, { r = 1, g = 1, b = 1, a = 1 }
--- Ink or paper, whichever reads better on this fill (pure black or white if neither reaches 4.5)
function ZeD.textOn(fill)
    local c = (ZeD.contrast(INK, fill) >= ZeD.contrast(PAPER, fill)) and INK or PAPER
    if ZeD.contrast(c, fill) < 4.5 then c = (c == INK) and BLACK or WHITE end
    return c
end

-- The label colours for mod folders and separators: ZeD's own accent colours, not System 7's label colours, since ZeD is
-- not System 7. None, then eight of ZeD's own accent colours (Mono left out: a grey label reads as none), named
-- with the accent setting's own words. Each theme takes the accent's own variant (light for Light, dark for Dark and
-- High contrast). P.labels[key] is the colour for marks (the swatches, a folder's picture, a separator's rules), moved
-- only as far as 3 : 1 needs on the theme's surfaces; P.labelsText[key] is the colour as text (a separator's name),
-- moved as far as 4.6 : 1. Both made in deriveReadable below.
ZeD.LABELS = {
    { k = "red",    name = "ContextMenu_Red" },
    { k = "orange", name = "ContextMenu_Orange" },
    { k = "yellow", name = "ContextMenu_Yellow" },
    { k = "green",  name = "ContextMenu_Green" },
    { k = "blue",   name = "ContextMenu_Blue" },
    { k = "teal",   name = "UI_ZeD_Accent_Teal" },
    { k = "purple", name = "ContextMenu_Purple" },
    { k = "pink",   name = "ContextMenu_Pink" },
}

-- Every field deriveReadable writes onto a palette (a window with its own accent swaps them all)
ZeD.READABLE_KEYS = {
    "accentText", "toneHi", "toneLo", "textSec", "accentDim", "textDim", "textOnAccent", "textOnFocus",
    "dangerText", "warningText", "positiveText", "infoText", "textOnWarning", "textOnDanger",
    "soiledWetText", "soiledBloodText", "soiledDirtText", "labels", "labelsText",
}

-- A surface stack (surface, then one optional wash) as one opaque colour over a world grey
local function flatOver(world, s, c, ca)
    local sa = s.a or 1
    local r, g, b = s.r * sa + world * (1 - sa), s.g * sa + world * (1 - sa), s.b * sa + world * (1 - sa)
    if c then
        r, g, b = c.r * ca + r * (1 - ca), c.g * ca + g * (1 - ca), c.b * ca + b * (1 - ca)
    end
    return { r = r, g = g, b = b }
end

--- P is a palette with accent, hover, text, surf1, surf2 (ZeD.T, or a window's own accent palette);
--- the base theme supplies the rest. Writes the READABLE_KEYS fields onto P.
function ZeD.deriveReadable(P, baseKey)
    local base  = ZeD.BaseThemes[baseKey] or ZeD.BaseThemes.dark
    local up    = (baseKey ~= "light")                 -- dark and high contrast text moves toward white
    local world = up and 1 or 0                        -- worst-case backdrop behind a translucent surface
    local ac    = P.accent
    local s1, s2 = P.surf1, P.surf2
    local hov   = P.hover
    local st    = base.stripe
    local bgs = {
        flatOver(world, s1), flatOver(world, s2),
        flatOver(world, s1, st, st.a), flatOver(world, s1, hov, hov.a), flatOver(world, s2, hov, hov.a),
        flatOver(world, s1, ac, base.selectionA), flatOver(world, s1, ac, 0.22),
    }
    local f1 = bgs[1]

    -- the accent as text (list weights, tab labels, titles): a solid colour that passes 4.7 : 1, rather than
    -- the accent at alpha 0.9
    local at = ZeD.legible(ac, 4.7, bgs, up)
    P.accentText, P.toneHi = at, at

    -- ghost tiers: start dim (45% toward the text colour from the surface, 30% toward the accent),
    -- then the faintest colour that passes 4.6; rather than the accent at alpha 0.5 / 0.55, which reads only 1.5-1.7 : 1
    local tx = P.text
    local g0 = {
        r = (f1.r + (tx.r - f1.r) * 0.45) * 0.70 + ac.r * 0.30,
        g = (f1.g + (tx.g - f1.g) * 0.45) * 0.70 + ac.g * 0.30,
        b = (f1.b + (tx.b - f1.b) * 0.45) * 0.70 + ac.b * 0.30,
    }
    local ghost = ZeD.legible(g0, 4.6, bgs, up)
    if baseKey == "dark" then
        -- (punch list 160, the director, Nov 11 2026: "A plus B". Dark's secondary tier read as bright as body text,
        -- because the 4.6 floor over a white world behind every wash pushed it up. It starts from the same mix over a
        -- dark world and stops at 7 : 1 on the window, then at least 4.5 : 1 on the window over a white world; on a
        -- selected row over a bright scene it can drop to about 3.1 to 4.4 : 1, the accepted cost.)
        local d1 = flatOver(0, s1)
        local gd = {
            r = (d1.r + (tx.r - d1.r) * 0.45) * 0.70 + ac.r * 0.30,
            g = (d1.g + (tx.g - d1.g) * 0.45) * 0.70 + ac.g * 0.30,
            b = (d1.b + (tx.b - d1.b) * 0.45) * 0.70 + ac.b * 0.30,
        }
        ghost = ZeD.legible(ZeD.legible(gd, 7.0, { d1 }, true), 4.5, { f1 }, true)
    end
    P.toneLo, P.textSec, P.accentDim = ghost, ghost, ghost
    P.textDim = ZeD.legible({
        r = f1.r + (tx.r - f1.r) * 0.40, g = f1.g + (tx.g - f1.g) * 0.40, b = f1.b + (tx.b - f1.b) * 0.40,
    }, 4.6, bgs, up)
    if baseKey == "dark" then
        -- (the director, Nov 11 2026: dim text the faintest of the three, under the secondary tier. A neutral grey a
        -- quarter of the way from the window to the text, then 5 : 1 on the window and at least 4.5 : 1 over a white
        -- world: about 5.9 : 1, against textSec's 7 and the body text's 12.8)
        local d1 = flatOver(0, s1)
        P.textDim = ZeD.legible(ZeD.legible({
            r = d1.r + (tx.r - d1.r) * 0.25, g = d1.g + (tx.g - d1.g) * 0.25, b = d1.b + (tx.b - d1.b) * 0.25,
        }, 5.0, { d1 }, true), 4.5, { f1 }, true)
    end

    -- label on a solid accent fill: ink or paper
    P.textOnAccent = ZeD.textOn(ac)

    -- label on the 0.55 accent focus wash: pure black or white, whichever is worse-case better
    -- over both a black and a white world
    local w0, w1 = flatOver(0, s1, ac, 0.55), flatOver(1, s1, ac, 0.55)
    local kb = math.min(ZeD.contrast(BLACK, w0), ZeD.contrast(BLACK, w1))
    local kw = math.min(ZeD.contrast(WHITE, w0), ZeD.contrast(WHITE, w1))
    P.textOnFocus = (kb >= kw) and BLACK or WHITE

    -- status and soiled colours as text: same hue, moved only as far as it needs to read on the
    -- surfaces and on its own badge wash (fills, dots and bars keep the plain colours)
    local n = #bgs
    local list = { bgs[1], bgs[2], bgs[3], bgs[4], bgs[5], bgs[6], bgs[7] }
    local bw = math.max(base.badgeBgA, 0.12)
    local function variant(c, washA)
        list[n + 1] = flatOver(world, s1, c, washA)
        return ZeD.legible(c, 4.6, list, up)
    end
    local st = ZeD.statusSet(baseKey)                  -- (the status colors: the theme's or the color blind set)
    P.textOnWarning, P.textOnDanger = ZeD.textOn(st.warning), ZeD.textOn(st.danger)   -- label on a solid status fill
    -- positiveText and dangerText start from the base theme's design values (lighter / darker than the plain
    -- colors where those miss 4.5 : 1) and are moved like the others, on every surface above and on surface 2
    -- drawn solid (the balloons): the accent's tint on the surfaces can take a design value under 4.5 : 1.
    local function statusText(seed, hue)
        list[n + 1] = flatOver(world, s1, hue, bw)
        list[n + 2] = { r = s2.r, g = s2.g, b = s2.b }
        local c = ZeD.legible(seed or hue, 4.6, list, up)
        list[n + 2] = nil
        return c
    end
    P.dangerText, P.warningText = statusText(st.dangerText, st.danger), variant(st.warning, bw)
    P.positiveText, P.infoText  = statusText(st.positiveText, st.positive), variant(base.info, bw)
    P.soiledWetText   = variant(base.soiledWet, 0.20)
    P.soiledBloodText = variant(base.soiledBlood, 0.20)
    P.soiledDirtText  = variant(base.soiledDirt, 0.20)
    -- the folder and separator labels as text and marks (on the list, its selection wash and the folder rows' surf2)
    local labs, labT = {}, {}
    for _, L in ipairs(ZeD.LABELS) do
        local set = ZeD.AccentColors[L.k]
        local c = set and set[(baseKey == "light") and "light" or "dark"].accent
        if c then
            labs[L.k] = ZeD.legible(c, 3.0, bgs, up)
            labT[L.k] = ZeD.legible(c, 4.6, bgs, up)
        end
    end
    P.labels, P.labelsText = labs, labT
end

-- ---------------------------------------------------------------------------
-- ACTIVE PALETTE: ZeD.T
-- This is what every component reads. It's rebuilt whenever the player
-- changes any setting. Components never reference BaseThemes or AccentColors
-- directly — they reference ZeD.T.
-- ---------------------------------------------------------------------------
ZeD.T = {}

-- ---------------------------------------------------------------------------
-- STATUS COLORS (punch list 144, the director, Nov 10 2026: "Add as an option", after the swatch page
-- ZeDUI/qa/status_colors_swatches.html). Standard: each base theme's own green, yellow and red. Color blind:
-- good and bad take the menu marks' blue and red-orange, and warning stands off red by brightness, so the three
-- stay apart under deuteranopia, protanopia and tritanopia (good to bad 5 to 6 under deuteranopia in Dark and
-- Light before, over 80 here; warning to bad 27 to 36). Light's red is a shade darker than its mark and High
-- contrast's blue brighter than its mark, for the same reason. Text shades are solved from these fills
-- (deriveReadable), so the set carries no text seeds.
-- ---------------------------------------------------------------------------
ZeD.StatusColors = {
    cb = {
        dark  = { positive = hex("#4491E2"), warning = hex("#F0D060"), danger = hex("#D9572A") },
        light = { positive = hex("#014E8E"), warning = hex("#8C6E00"), danger = hex("#6E1E00") },
        hicon = { positive = hex("#5AAEFF"), warning = hex("#FFDD33"), danger = hex("#E84A22") },
    },
}
ZeD.currentStatus = "standard"    -- "standard" or "cb" (Settings.lua's Status colors)
--- The status set a base theme draws with: the theme itself (its positive, warning, danger and the text seeds
--- positiveText / dangerText), or the color blind set for it
function ZeD.statusSet(baseKey)
    local base = ZeD.BaseThemes[baseKey] or ZeD.BaseThemes.dark
    return (ZeD.currentStatus == "cb" and ZeD.StatusColors.cb[baseKey]) or base
end

-- The accent a fresh install starts on, and the fallback for a saved key that names nothing.
-- PZ Teal from beta 11 (punch list 127); a saved Orange stays Orange.
ZeD.DEFAULT_ACCENT = "teal"

-- Current setting keys (persisted through ModOptions)
ZeD.currentBase   = "dark"
ZeD.currentAccent = ZeD.DEFAULT_ACCENT
ZeD.currentSize   = "small"

-- See-through (ZeD setup) works in the Dark theme only: Light and High Contrast always draw the window bodies
-- solid (the director, Nov 12 2026). baseKey: a base theme's key (default: the one in use).
function ZeD.seeThroughWorks(baseKey)
    return (baseKey or ZeD.currentBase) == "dark"
end

-- ---------------------------------------------------------------------------
-- APPLY THEME
-- Call this whenever a setting changes. Rebuilds ZeD.T from the three axes.
-- ---------------------------------------------------------------------------
function ZeD.applyTheme(baseKey, accentKey, sizeKey)
    -- Store current keys
    ZeD.currentBase   = baseKey   or ZeD.currentBase
    ZeD.currentAccent = accentKey or ZeD.currentAccent
    ZeD.currentSize   = sizeKey   or ZeD.currentSize

    -- A key that names nothing (an old or hand-edited save) falls back to the default
    -- rather than throwing below
    if not ZeD.BaseThemes[ZeD.currentBase]     then ZeD.currentBase   = "dark"   end
    if not ZeD.AccentColors[ZeD.currentAccent] then ZeD.currentAccent = ZeD.DEFAULT_ACCENT end
    -- a saved "medium" (a preset that is gone) falls back to small, as does any size that names nothing
    if ZeD.currentSize == "medium" or not ZeD.TextSizes[ZeD.currentSize] then ZeD.currentSize = "small" end
    local base   = ZeD.BaseThemes[ZeD.currentBase]
    local size   = ZeD.TextSizes[ZeD.currentSize]

    -- Determine which accent variant to use based on base theme
    -- High contrast uses dark accent values (same dark background family)
    local accentSet = ZeD.AccentColors[ZeD.currentAccent]
    local accentVariant
    if ZeD.currentBase == "light" then
        accentVariant = accentSet.light
    else
        accentVariant = accentSet.dark
    end

    -- Build the active palette by merging all three axes
    local T = {}

    -- Surface colors from base theme
    T.base     = base.base
    -- the marks on this theme's own surfaces (the list menu); the strip and the wheels sit on the locked paper and
    -- use ZeD.Ctx.markAdd / markRemove
    T.marks    = { add = base.markAdd, remove = base.markRemove }
    T.onBand   = base.onBand or base.base
    T.surf1    = base.surf1
    T.surf2    = base.surf2
    T.surf3    = base.surf3
    T.surf4    = base.surf4
    -- See-through (ZeD setup, a window's window box): one alpha for every window surface,
    -- 0.6 to 1, set by Settings.lua as ZeD.surfaceAlpha. It replaces the theme's own (0.92
    -- dark, 0.97 light, 0.95 high contrast) here, before the accent tint (which keeps alpha)
    -- and before deriveReadable, which solves the text colours against these surfaces as
    -- translucent over the world. New tables: BaseThemes stays as written.
    -- Light and High Contrast always draw the bodies solid (the director, punch list 175f(5)): See-through works in
    -- Dark only. The player's pick is kept aside while forced (ZeD._seePick) and comes back with Dark, so the readers of
    -- ZeD.surfaceAlpha (the windows' own accent palettes) see the solid value too.
    local sa = ZeD.surfaceAlpha
    if ZeD._seeForced and sa == 1 then sa = ZeD._seePick end
    if ZeD.seeThroughWorks(ZeD.currentBase) then
        ZeD._seeForced = nil
        ZeD.surfaceAlpha = sa
    else
        ZeD._seePick, ZeD._seeForced = sa, true
        sa = 1
        ZeD.surfaceAlpha = 1
    end
    if type(sa) == "number" then
        if sa < 0.6 then sa = 0.6 elseif sa > 1 then sa = 1 end
        T.base  = ZeD.colorAlpha(T.base, sa)
        T.surf1 = ZeD.colorAlpha(T.surf1, sa)
        T.surf2 = ZeD.colorAlpha(T.surf2, sa)
        T.surf3 = ZeD.colorAlpha(T.surf3, sa)
        T.surf4 = ZeD.colorAlpha(T.surf4, sa)
    end
    T.border   = base.border
    T.borderS  = base.borderS
    T.frameS   = base.frameS or base.borderS   -- the belt's slot frame: its keyline, and a light outer line where set
    T.frameHi  = base.frameHi
    T.stripe   = base.stripe

    -- Text colors from base theme
    T.text     = base.text
    T.textSec  = base.textSec  -- placeholder, overwritten to accent after accent is set
    T.textDim  = base.textDim  -- structural chrome (scrollbar arrows, grip lines, ridges)
    T.textHead = base.textHead

    -- Status colors: the base theme's, or the color blind set (ZeD.statusSet)
    local st = ZeD.statusSet(ZeD.currentBase)
    T.danger   = st.danger
    T.warning  = st.warning
    T.positive = st.positive
    T.info     = base.info
    T.violet   = base.violet

    -- Structural values from base theme
    T.borderW      = base.borderW
    T.disabledAlpha = base.disabledAlpha

    -- System 7 chrome colors
    T.chromeHi = base.chromeHi
    T.chromeSh = base.chromeSh

    -- Groove divider colors
    T.grooveDark  = base.grooveDark
    T.grooveLight = base.grooveLight

    -- Overlay / interactive state opacities
    T.modalOverlayA    = base.modalOverlayA
    T.selectionA       = base.selectionA
    T.dangerPulseMin   = base.dangerPulseMin
    T.dangerPulseMax   = base.dangerPulseMax
    T.dangerHoverMul   = base.dangerHoverMul
    T.scrollThumbA     = base.scrollThumbA
    T.scrollThumbHoverA = base.scrollThumbHoverA
    T.scrollThumbDragA = base.scrollThumbDragA
    T.badgeBgA         = base.badgeBgA
    T.ridgeLightA      = base.ridgeLightA
    T.ridgeDarkA       = base.ridgeDarkA
    T.drawerBg         = base.drawerBg

    -- Soiled condition colors
    T.soiledWet   = base.soiledWet
    T.soiledBlood = base.soiledBlood
    T.soiledDirt  = base.soiledDirt

    -- Patch material colors
    T.matLeather = base.matLeather
    T.matDenim   = base.matDenim
    T.matFabric  = base.matFabric

    -- Accent colors from accent selection
    T.accent       = accentVariant.accent
    T.accentBright = accentVariant.bright
    T.hover        = accentVariant.hover
    T.textOnAccent = accentVariant.textOnAccent

    -- Accent surface tinting: blend accent hue into neutral greys
    -- Mono = pure grey (no tint). All others get subtle color personality.
    -- Dark/HiCon: stronger tint (dark surfaces need more to register)
    -- Light: use bright accent variant (more even luminance across colors), lighter touch
    if ZeD.currentAccent ~= "mono" then
        local isLight = ZeD.currentBase == "light"
        local TINT = isLight and 0.10 or 0.03
        local ac = isLight and T.accentBright or T.accent
        local blend = ZeD.colorBlend
        T.base    = blend(T.base, ac, TINT)
        T.surf1   = blend(T.surf1, ac, TINT)
        T.surf2   = blend(T.surf2, ac, TINT)
        T.surf3   = blend(T.surf3, ac, TINT)
        T.surf4   = blend(T.surf4, ac, TINT)
        T.border  = blend(T.border, ac, TINT)
        T.borderS = blend(T.borderS, ac, TINT)
        T.frameS  = blend(T.frameS, ac, TINT)
        if T.frameHi then T.frameHi = blend(T.frameHi, ac, TINT) end
        T.text     = blend(T.text, ac, TINT * 0.5)
        T.textHead = blend(T.textHead, ac, TINT * 0.5)
    end

    -- 3-tone system: each F-role can use any of these three color tiers
    --   toneNorm = neutral white/black (no accent influence)
    --   toneHi   = the accent as text (accentText: the accent moved only as far as it needs to read)
    --   toneLo   = ghost / secondary accent text (the faintest colour that still passes 4.6 : 1)
    T.toneNorm = T.textHead
    -- Disclosure triangle color: toneNorm at 60% alpha (all expand/collapse chevrons)
    T.arrow    = { r = T.toneNorm.r, g = T.toneNorm.g, b = T.toneNorm.b, a = 0.60 }

    -- Derived readable text colours: accentText / toneHi, toneLo /
    -- textSec / accentDim (stat labels, section labels, category rows), textDim, textOnAccent,
    -- textOnFocus (labels on the 0.55 focus wash) and the *Text variants of the status and soiled
    -- colours. Rebuilt here, on theme or accent change, never per frame.
    ZeD.deriveReadable(T, ZeD.currentBase)
    -- Category headers: same fontF1, neutral color (not accent)
    T.textCat  = T.textHead

    -- The five role fonts live on the distance-field slots (ZeD.Font.sdf). The preset
    -- keeps its px per role; the root scale multiplies at draw time (Overrides/TextScale.lua routes
    -- ISUIElement text draws through the zoom path, ZeD.TM scales measurements) via ZeD.Text.zoomOf,
    -- which reads T.fontPx / T.fontFace keyed by the UIFont value. Heights are cached further down,
    -- after the palette is live.
    local SD = ZeD.Font.sdf
    local roleEntries = { SD.sec, SD.body, SD.stat, SD.head, SD.title }
    local rolePx      = { size.fontF1.px, size.fontF2.px, size.fontF3.px, size.fontF4.px, size.fontF5.px }
    T.fontPx, T.fontFace = {}, {}
    -- When the game's own fonts have replaced ZeD's atlases in those slots (a Chinese, Japanese,
    -- Korean or Thai font set, or the Dyslexic font option; ZeD.Text.checkRoleFonts in Scale.lua),
    -- each role draws in the nearest of the game's Small / Medium / Large at its native size and
    -- nothing is registered for zooming.
    T.fontFallback = (ZeD.Text and ZeD.Text.checkRoleFonts and ZeD.Text.checkRoleFonts()) and true or false
    for i = 1, 5 do
        local e = roleEntries[i]
        if T.fontFallback then
            T["fontF" .. i] = ZeD.Text.roleFallbackFont(rolePx[i])
        else
            T["fontF" .. i] = e.font
            T.fontPx[e.font]   = rolePx[i]
            T.fontFace[e.font] = e.face or 64
        end
    end
    -- T.scale = root scale (1080p = 1.0, from ZeD.Scale) x the text-size preset. Every px token
    -- below is pre-scaled; literals in layout code go through T.px(units).
    local root = (ZeD.Scale and ZeD.Scale.root and ZeD.Scale.root()) or 1
    local sc = root * (size.scale or 1)
    T.scale = sc
    T.root  = root
    -- (the answers are kept by units for this palette: the panels ask the same few hundred literals
    -- thousands of times a frame; past 512 kept the store starts over, so a drawer sliding open, which
    -- asks a new fraction each frame, never crowds them out; the sum below decides each one, as before)
    local pxKept, pxN, floor = {}, 0, math.floor
    T.px    = function(units)
        local v = pxKept[units]
        if v then return v end
        v = floor(units * sc + 0.5)
        if units == units then
            if pxN >= 512 then pxKept, pxN = {}, 0 end
            pxKept[units] = v
            pxN = pxN + 1
        end
        return v
    end
    -- Even at every step (ZeD.Scale.artZoom / hair / line / snapRect explain the rules):
    --   T.hair      a 1-unit line in whole px (= T.px(1), >= 1)
    --   T.line(n)   an n-unit line: n hairlines (T.px(n) would mix 3 px two-unit lines with 2 px one-unit ones at 1.5)
    --   T.rect(...) a design-unit rect with snapped edges, its size taken from the edges
    --   T.art       the whole zoom pixel art in the windows draws at (the nearest whole number to T.scale)
    local hair = math.floor(sc + 0.5)
    if hair < 1 then hair = 1 end
    T.hair  = hair
    T.line  = function(units)
        local v = math.floor((units or 1) * hair + 0.5)
        if v < 1 then v = 1 end
        return v
    end
    T.rect  = function(x, y, w, h)
        local x0, y0 = math.floor(x * sc + 0.5), math.floor(y * sc + 0.5)
        return x0, y0, math.floor((x + w) * sc + 0.5) - x0, math.floor((y + h) * sc + 0.5) - y0
    end
    T.art   = (ZeD.Scale and ZeD.Scale.artZoom) and ZeD.Scale.artZoom(sc) or math.max(1, math.floor(sc + 0.5 + 1e-6))
    -- A preset value Large sizes for itself (row 34 vs 30, button 30 vs 26 ...) takes the root scale
    -- only: multiplied by Large's 1.15 as well, rows would grow 30% for 15% more text (39 px rows) and
    -- push four rows in twenty off a full bag. Values both presets share (the icons) and every literal
    -- through T.px still grow with Large.
    local small = ZeD.TextSizes.small
    local function SP(key)
        local v = size[key]
        if small and small[key] ~= v then return math.floor(v * root + 0.5) end
        return T.px(v)
    end
    T.titleBarH  = SP("titleBarH")
    T.rowH       = SP("rowH")
    T.buttonH    = SP("buttonH")
    T.tabH       = SP("tabH")
    T.inputH     = SP("inputH")
    T.iconSm     = SP("iconSm")
    T.iconMd     = SP("iconMd")
    T.iconLg     = SP("iconLg")
    T.iconXl     = SP("iconXl")
    T.fillBarH   = SP("fillBarH")
    T.checkboxSz = SP("checkboxSz")
    T.closeBoxSz = SP("closeBoxSz")
    T.statIconSz = SP("statIconSz")
    T.contentPad = SP("contentPad")
    T.colGap     = SP("colGap")
    T.cardIconSz = SP("cardIconSz")
    T.contextRowH = SP("contextRowH")
    T.modalW     = SP("modalW")
    T.modalH     = SP("modalH")
    T.minWinW    = SP("minWinW")
    T.minWinH    = SP("minWinH")

    -- The two rows under the title bar, each one size across both windows (punch list 178): row 1, the
    -- strip, runs from the tab strip's top cell across the tab's header to the container strip's top
    -- cell; row 2, the sort bar, runs under it (the container strip's sort row and the inventory's
    -- column header). Each is the tallest thing it holds plus air, at the text size, times the root:
    --   T.stripH    the Find field, the selects and the header's buttons (inputH / buttonH, or one F4
    --               heading line if that is taller) + 11u. Small 37u, Large 43u
    --   T.sortBarH  one line of F1 (the sort font at Large; F5 at Small sits in it with air) + 7u. Small 20u, Large 24u
    -- (a line is the face's 77/64 of the preset px. Whoever draws in a row reads these fresh, never a
    -- copy made at load, so a new text size or UI scale moves both windows at once)
    local lineK = 77 / 64
    local rowSc = size.scale or 1
    local row1  = math.max(size.inputH, size.buttonH, size.fontF4.px * lineK)
    T.stripH    = math.floor((row1 + 11 * rowSc) * root + 0.5)
    T.sortBarH  = math.floor((size.fontF1.px * lineK + 7 * rowSc) * root + 0.5)

    -- Thermal spectrum (per-theme: dark vibrant, light darker for contrast)
    T.tempCold = base.tempCold
    T.tempCool = base.tempCool
    T.tempNorm = base.tempNorm
    T.tempWarm = base.tempWarm
    T.tempHot  = base.tempHot

    -- Thermal badge tints (per-theme)
    T.tempColdBadge = base.tempColdBadge
    T.tempCoolBadge = base.tempCoolBadge
    T.tempNormBadge = base.tempNormBadge
    T.tempWarmBadge = base.tempWarmBadge
    T.tempHotBadge  = base.tempHotBadge

    -- Neutral icon tint (theme-independent — used for texture rendering)
    T.iconWhite = {r = 1, g = 1, b = 1}
    -- Theme-aware icon tint: white on dark/hc, black on light
    T.iconTone  = (ZeD.currentBase == "light") and {r = 0, g = 0, b = 0} or {r = 1, g = 1, b = 1}

    -- Spacing is always available (doesn't change with theme)
    T.sp = {}   -- scaled copy; the static table stays the design-unit source
    for k, v in pairs(ZeD.Spacing) do T.sp[k] = (type(v) == "number") and T.px(v) or v end
    -- (the old names for the two rows read the shared sizes, so the tabs that ask for them line up)
    T.sp.tabHeaderH = T.stripH
    T.sp.colHdrH    = T.sortBarH
    -- the body figure is pixel art (ZeD_BodyFigure.lua): its box is the canvas at the whole zoom it draws at,
    -- so the Health, Thermal and Equip layouts make room for the size it really is
    T.sp.figureW = ZeD.Spacing.figureW * T.art
    T.sp.figureH = ZeD.Spacing.figureH * T.art
    -- the System 7 groove: a dark and a light hairline (ZeD.Atoms.drawGroove)
    T.grooveH = 2 * T.hair
    -- Context-menu tokens — static, not theme-dependent (see ZeD.Ctx definition above)
    T.ctx = {}  -- scaled copy; counts and milliseconds stay as they are
    local CTX_NOT_PX = { maxVisible = true, animMs = true, settleDelayMs = true }
    for k, v in pairs(ZeD.Ctx) do T.ctx[k] = (type(v) == "number" and not CTX_NOT_PX[k]) and T.px(v) or v end
    -- Gamepad tokens — static, not theme-dependent (see ZeD.Gp definition above)
    -- InputModeDetector reads T.gp's stick, trigger and cooldown values; FocusManager its hold, repeat and aiming ones
    T.gp  = ZeD.Gp

    -- Radio chassis tokens — static hardware colors, not theme-dependent.
    -- The first contextual drawer chassis, two tiers (Premium VFD / ValuTech LCD).
    T.radio = ZeD.Radio

    -- Set the active palette
    ZeD.T = T
    -- Cached font heights, zoomed (ZeD.Text.zoomOf reads ZeD.T, so this runs after the palette is live)
    -- (a server has no fonts, and nothing there reads these heights)
    if getTextManager and not (ZeD.Text and ZeD.Text.noFonts) then
        local tm = ZeD.TM
        T.fontF1H = tm:getFontHeight(T.fontF1)
        T.fontF2H = tm:getFontHeight(T.fontF2)
        T.fontF3H = tm:getFontHeight(T.fontF3)
        T.fontF4H = tm:getFontHeight(T.fontF4)
        T.fontF5H = tm:getFontHeight(T.fontF5)
        -- the game's own fonts (Chinese, Japanese, Korean, Thai, Dyslexic) can stand taller than ZeD's
        -- faces: the rows grow to hold them, still one size each
        if T.fontFallback then
            T.stripH   = math.max(T.stripH, T.fontF4H + T.px(11))
            T.sortBarH = math.max(T.sortBarH, T.fontF1H + T.px(7))
            T.sp.tabHeaderH, T.sp.colHdrH = T.stripH, T.sortBarH
        end
    end
    -- the sort bar's labels: at Small (the default) F5, today's look, so the narrow headings ("Cond / Amt",
    -- the Equip protection heads) still fit their columns in every language; at Large F1, which reads at the
    -- size (F5 stayed tiny there). T.sortWidthK is how much wider the sort font's words run than F5's at
    -- this size, for the columns that cap a heading's room (the inventory's COND)
    if ZeD.currentSize == "large" then
        T.sortFont   = T.fontF1
        T.sortWidthK = (size.fontF1.px * 0.6) / (size.fontF5.px * 0.48)
    else
        T.sortFont   = T.fontF5
        T.sortWidthK = 1
    end
    if ZeD.Scale then ZeD.Scale._appliedRoot = root end

    -- A custom event for windows that want to hear of a new palette. It fires only once some file
    -- registers OnZeDThemeChanged, and none does: components read ZeD.T fresh every frame instead
    if Events and Events.OnZeDThemeChanged then
        triggerEvent("OnZeDThemeChanged")
    end
end

-- ---------------------------------------------------------------------------
-- CONVENIENCE: Color with modified alpha
-- Used for disabled states, tinted backgrounds, etc.
-- Returns a NEW table — doesn't mutate the original.
-- ---------------------------------------------------------------------------
function ZeD.colorAlpha(color, alpha)
    return {r = color.r, g = color.g, b = color.b, a = alpha}
end

-- ---------------------------------------------------------------------------
-- CONVENIENCE: Blend a color toward the accent at a given strength
-- Used for hover tints on surfaces.
-- ---------------------------------------------------------------------------
function ZeD.colorBlend(base, overlay, strength)
    local inv = 1.0 - strength
    return {
        r = base.r * inv + overlay.r * strength,
        g = base.g * inv + overlay.g * strength,
        b = base.b * inv + overlay.b * strength,
        a = base.a,
    }
end

-- ---------------------------------------------------------------------------
-- PAPER TONE: no large near-white areas
-- Every big light sheet ZeD draws (the guide's book page, a paper map, the reader's
-- page, notebooks, the desk's sticky note) sits at 70% of its printed brightness:
-- a bright page in a dark game glares the way the game's snow does. Only the paper
-- and its light fills dim; ink and pictures keep their colors, and each surface's
-- text is checked for 4.5 : 1 on the dimmer paper (paper_tone_b10_sim.lua).
-- ---------------------------------------------------------------------------
ZeD.PAPER_TONE = 0.70

--- A paper color at the paper tone: the same hue, each channel times PAPER_TONE. A new table.
function ZeD.paperTone(c)
    local k = ZeD.PAPER_TONE
    return { r = c.r * k, g = c.g * k, b = c.b * k, a = c.a }
end

--- A sheet already drawn at full brightness (a texture the engine draws: a paper map, the game's
--- printed page) brought to the paper tone: black over it at 1 - PAPER_TONE, which multiplies
--- every pixel under it by PAPER_TONE. x, y, w, h in the panel's own coordinates.
function ZeD.paperToneOver(panel, x, y, w, h)
    if w <= 0 or h <= 0 then return end
    panel:drawRect(x, y, w, h, 1 - ZeD.PAPER_TONE, 0, 0, 0)
end

-- ---------------------------------------------------------------------------
-- BUTTON LABELS: sentence case
-- Every button reads in sentence case ("Load game", "Take all", "New..."),
-- never all caps: a row of all-caps buttons tires the eye.
-- Labels are still written in caps, or upper-cased from vanilla's words, in
-- many places, so the button molecules pass their label through here right
-- before they measure and draw it:
--   * a label with any lower-case letter is left as written (a keycap's "q",
--     a mod's own name, vanilla's Title Case words);
--   * an all-caps label keeps its first letter a capital and drops the rest
--     to lower case, except initials (OK, CD, TV, ...), words with a digit
--     ("2X", "4WD") and the letter after a degree sign (the oven's "°F");
--     ZED becomes ZeD.
-- Hardware printed on the props (the car radio, the dash, keycaps) is not a
-- button in this sense and keeps its caps: those draw their own text.
-- Labels draw every frame, so results are cached; the cache keeps the last
-- LABEL_CACHE_MAX labels and drops the oldest past that.
-- ---------------------------------------------------------------------------
local KEEP_CAPS = {
    OK = "OK", CD = "CD", CDS = "CDs", TV = "TV", VHS = "VHS", AM = "AM", FM = "FM", ID = "ID",
    HP = "HP", MP = "MP", PC = "PC", USB = "USB", NPC = "NPC", NPCS = "NPCs", XP = "XP", DLC = "DLC",
    UI = "UI", HUD = "HUD", PZ = "PZ", ZED = "ZeD", OS = "OS", IP = "IP", PVP = "PvP", PVE = "PvE",
    RGB = "RGB", FPS = "FPS", MHZ = "MHz", KHZ = "kHz", KM = "km", KG = "kg", LED = "LED", GPS = "GPS",
}
local DEGREE = string.char(176)
local LABEL_CACHE_MAX = 512
local labelCache, labelOrder, labelHead = {}, {}, 1

local function toSentenceCase(s)
    -- only an all-caps label with two or more capitals is turned
    if s:find("%l") or not s:find("%u.*%u") then return s end
    local parts, pos, first = {}, 1, true
    while true do
        local a, b = s:find("%w+", pos)
        if not a then parts[#parts + 1] = s:sub(pos); break end
        parts[#parts + 1] = s:sub(pos, a - 1)
        local w = s:sub(a, b)
        if KEEP_CAPS[w] then
            w = KEEP_CAPS[w]
        elseif w:find("%d") or (a > 1 and s:sub(a - 1, a - 1) == DEGREE) then
            -- "2X", "4WD", the F of "°F": as written
        else
            w = w:lower()
            if first then w = (ZeD.upper or string.upper)(w:sub(1, 1)) .. w:sub(2) end
        end
        first = false
        parts[#parts + 1] = w
        pos = b + 1
    end
    return table.concat(parts)
end

-- An error caught every frame (a draw, a tick) logs once per place and message, not
-- once a frame: one bad texture or nil field must not flood console.txt.
-- (capped, so a message with changing numbers cannot grow it forever)
local _logSeen, _logCount = {}, 0
--- prints "[ZeD] key: msg" once per key and message, 500 lines at most; every call still counts
--- toward safe mode's watchdog
function ZeD.logOnce(key, msg)
    -- every failing frame still counts towards safe mode's watchdog (client/ZeD/SafeMode.lua),
    -- before the dedup below; this file loads first, so it is looked up when called
    local safe = ZeD.Safe
    if safe and safe.fault then safe.fault(key, msg) end
    local k = tostring(key) .. "|" .. tostring(msg)
    if _logSeen[k] then return end
    if _logCount >= 500 then return end
    _logSeen[k] = true
    _logCount = _logCount + 1
    print("[ZeD] " .. tostring(key) .. ": " .. tostring(msg))
end

--- a button label in sentence case, by the BUTTON LABELS rules above; nil stays nil
function ZeD.btnCase(s)
    if s == nil then return s end
    s = tostring(s)
    local hit = labelCache[s]
    if hit then return hit end
    local out = toSentenceCase(s)
    -- FIFO: past the cap, the oldest cached label drops out
    if #labelOrder >= LABEL_CACHE_MAX then
        labelCache[labelOrder[labelHead]] = nil
        labelOrder[labelHead] = s
        labelHead = labelHead % LABEL_CACHE_MAX + 1
    else
        labelOrder[#labelOrder + 1] = s
    end
    labelCache[s] = out
    return out
end

--- Words that arrive in capitals at draw time (a heading, a column head, a status word
--- written in caps somewhere upstream) read in sentence case in the windows, by the same
--- rules as the buttons: initials, words with a digit and anything already in mixed case
--- pass through as written. Text printed on the hardware props keeps its caps and does
--- not come here.
function ZeD.textCase(s)
    return ZeD.btnCase(s)
end

-- ---------------------------------------------------------------------------
-- CONVENIENCE: Copy color fields into an existing table (zero allocation)
-- Used by organism prerender() to sync PZ color tables with the active theme
-- without creating new tables every frame.
-- ---------------------------------------------------------------------------
function ZeD.colorSync(target, source, alphaOverride)
    target.r = source.r
    target.g = source.g
    target.b = source.b
    target.a = alphaOverride or source.a
end

-- ---------------------------------------------------------------------------
-- INITIALIZE with defaults on load
-- This runs when the file is first required, giving ZeD.T valid values
-- before ModOptions loads saved preferences. ModOptions will call
-- ZeD.applyTheme() again with the player's saved choices.
-- ---------------------------------------------------------------------------
ZeD.applyTheme("dark", ZeD.DEFAULT_ACCENT, "small")
