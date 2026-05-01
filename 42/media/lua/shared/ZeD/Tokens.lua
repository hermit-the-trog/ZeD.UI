-- ZeD-UI/42/media/lua/shared/ZeD/Tokens.lua
-- ============================================================================
-- DESIGN TOKEN ENGINE
-- Single source of truth for every visual value in the mod.
-- Three independent axes: Base Theme x Accent Color x Text Size
-- Produces ZeD.T — the active palette that all components reference.
-- ============================================================================

-- Global namespace — everything lives under ZeD
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
        base     = hex("#0C0C0C", 0.92),   -- deepest background (neutral grey)
        surf1    = hex("#141414", 0.92),    -- window background
        surf2    = hex("#1C1C1C", 0.92),    -- title bars, elevated panels
        surf3    = hex("#242424", 0.92),    -- interactive elements, buttons
        surf4    = hex("#2C2C2C", 0.92),    -- hover elevation
        border   = hex("#202020", 1.0),     -- soft dividers between rows
        borderS  = hex("#383838", 1.0),     -- strong structural borders
        text     = rgba(0.855, 0.855, 0.855, 0.90),  -- neutral off-white body text
        textSec  = rgba(0.63, 0.63, 0.63, 0.65),     -- neutral secondary (overwritten to accent at runtime)
        textDim  = rgba(0.63, 0.63, 0.63, 0.65),     -- structural chrome: scrollbar arrows, grip lines, ridges
        textHead = rgba(0.90, 0.90, 0.90, 0.92),     -- neutral bright chrome/headings
        stripe   = rgba(1.00, 1.00, 1.00, 0.04),     -- neutral white stripe
        -- Status colors (amber-shifted family)
        danger   = hex("#C45A2A"),
        warning  = hex("#C49A2A"),
        positive = hex("#7A9A34"),
        info     = hex("#5A8A9A"),
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
        selectionA    = 0.18,   -- selected row bg alpha
        dangerPulseMin = 0.08,  -- danger button sine pulse floor
        dangerPulseMax = 0.25,  -- danger button sine pulse ceiling
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
        base     = hex("#C6C6C6", 0.92),
        surf1    = hex("#BEBEBE", 0.92),
        surf2    = hex("#B6B6B6", 0.92),
        surf3    = hex("#AEAEAE", 0.92),
        surf4    = hex("#A6A6A6", 0.92),
        border   = hex("#969696", 1.0),
        borderS  = hex("#767676", 1.0),
        text     = rgba(0.047, 0.047, 0.047, 0.95),  -- neutral near-black
        textSec  = rgba(0.047, 0.047, 0.047, 0.72),  -- neutral recessed (overwritten to accent at runtime)
        textDim  = rgba(0.047, 0.047, 0.047, 0.72),  -- structural chrome
        textHead = rgba(0.02, 0.02, 0.02, 1.00),     -- neutral near-black chrome
        stripe   = rgba(0.0, 0.0, 0.0, 0.05),        -- subtle dark texture on mid-gray
        danger   = hex("#7A2A11"),
        warning  = hex("#6B5510"),
        positive = hex("#2A5511"),
        info     = hex("#1A5566"),
        borderW  = 1,
        disabledAlpha = 0.42,
        chromeHi = rgba(1.0, 1.0, 1.0, 1.0),
        chromeSh = rgba(0.0, 0.0, 0.0, 0.40),
        grooveDark  = rgba(0.0, 0.0, 0.0, 0.30),
        grooveLight = rgba(1.0, 1.0, 1.0, 0.50),
        modalOverlayA = 0.35,
        selectionA    = 0.18,
        dangerPulseMin = 0.08,
        dangerPulseMax = 0.25,
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
        base     = hex("#050505", 0.95),
        surf1    = hex("#111111", 0.95),
        surf2    = hex("#191919", 0.95),
        surf3    = hex("#202020", 0.95),
        surf4    = hex("#292929", 0.95),
        border   = hex("#353535", 1.0),
        borderS  = hex("#555555", 1.0),
        text     = rgba(1.0, 1.0, 1.0, 0.95),
        textSec  = rgba(0.78, 0.78, 0.78, 0.75),
        textDim  = rgba(0.78, 0.78, 0.78, 0.75),
        textHead = rgba(1.0, 1.0, 1.0, 0.98),
        stripe   = rgba(1.0, 1.0, 1.0, 0.06),
        danger   = hex("#FF5533"),
        warning  = hex("#FFCC22"),
        positive = hex("#44DD44"),
        info     = hex("#44CCFF"),
        borderW  = 2,     -- thicker borders for accessibility
        disabledAlpha = 0.42,
        chromeHi = rgba(1.0, 1.0, 1.0, 1.0),
        chromeSh = rgba(0.0, 0.0, 0.0, 1.0),
        grooveDark  = rgba(0.0, 0.0, 0.0, 0.65),
        grooveLight = rgba(1.0, 1.0, 1.0, 0.10),
        modalOverlayA = 0.60,
        selectionA    = 0.25,
        dangerPulseMin = 0.10,
        dangerPulseMax = 0.30,
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
-- Pairing D: Fira Mono + Fira Sans Condensed (SIL OFL)
-- 5 typography roles (F-system):
--   F1 Chrome  — Fira Mono Bold              (title bars, tabs, button labels)
--   F2 Body    — Fira Sans Regular            (list rows, content text)
--   F3 Data    — Fira Mono Regular           (numbers, percentages, stat values)
--   F4 Heading — Fira Sans Cond. SemiBold   (section headers, item names)
--   F5 Micro   — Fira Sans Cond. Regular     (chips, badges, metadata labels)
-- ---------------------------------------------------------------------------
local F = {}
-- Active role fonts (5 roles × 2 size presets = 10)
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
-- Reserved slots (4 — speech, TV/radio, HOW YOU DIED, TBD)
F.rsv1       = { font = UIFont.Cred1,     px = 20 }  -- Chicago 20px
F.rsv2       = { font = UIFont.Cred2,     px = 24 }  -- Chicago 24px
F.rsv3       = { font = UIFont.MainMenu1, px = 16 }  -- Lekton Bold 16px
F.rsv4       = { font = UIFont.MainMenu2, px = 20 }  -- Lekton Bold 20px
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
        fontF2     = F.body,         -- F2 Body: Fira Sans Regular 12px
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
        fontF2     = F.bodyLg,       -- F2 Body: Fira Sans Regular 14px
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
    contextPadH   = 14,   -- DEPRECATED S88 — was used by the vanilla-list skin override; replaced by T.ctx for the new strip menu
    contextPadV   = 5,    -- DEPRECATED S88 — see above
    contextSafeM  = 4,    -- DEPRECATED S88 — see above
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
    colHdrH       = 20,   -- column header bar height (NAME / SLOT / BITE etc.)
    catHdrH       = 15,   -- category header row height in inventory lists
    tabHeaderH    = 37,   -- pinned drawer / tab header strip height
                          -- (Health / Equipment-Defense / Thermal / Identity /
                          --  Skills / Maps toolbar / Radio drawer header)
    figurePadTop  = 12,   -- padding above body figure in Health/Protection/Thermal tabs
    figureW       = 220,  -- body figure width  (shared by Health/Protection/Thermal)
    figureH       = 260,  -- body figure height (shared by Health/Protection/Thermal)
    pillBtnPadV   = 10,   -- vertical padding added to secH for pill-style buttons
}

-- ---------------------------------------------------------------------------
-- CONTEXT MENU TOKENS (S88 — unified horizontal strip)
-- All geometry, motion, and state dims for ZeD_ContextMenu and its molecules.
-- Fixed across themes. Exposed on T.ctx at render time. See CONTEXT_MENU_SPEC §9.
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
}

-- ---------------------------------------------------------------------------
-- GAMEPAD TOKENS (S91 — Gamepad Phase 1 Infrastructure)
-- All geometry, thresholds, and timings for the gamepad input stack.
-- Fixed across themes. Exposed on T.gp at render time. See GAMEPAD_SPEC §11.
--
-- Ship the ENTIRE block now even though Phase 1 (InputModeDetector + ActionMap)
-- only reads stickThresh, triggerThresh, cooldownMs. Phases 2-6 read the rest
-- and we don't want to revisit this file every phase.
-- ---------------------------------------------------------------------------
ZeD.Gp = {
    -- FOCUS RING (Layer 3 FocusManager — Phase 3) ----------------------------
    focusRingW    = 2,        -- border width in pixels around the focused element
    focusRingPad  = 1,        -- inset from element edge so the ring sits inside the border
    focusFillA    = 0.10,     -- inner fill alpha when focused (accent-tinted wash)

    -- BUTTON PROMPTS (Layer 4 GlyphManager — Phase 4) ------------------------
    promptSize    = 16,       -- standard glyph size for footer prompt strips
    promptSizeSm  = 12,       -- small glyph size for inline / dense contexts
    promptGap     = 4,        -- gap between glyph and its label text

    -- LAYOUT MODE HUD (Layer 3 FocusManager / Layout Mode — Phase 3) ---------
    layoutHudH       = 22,    -- banner height when a window enters Layout Mode
    layoutHudY       = 4,     -- banner vertical offset from the title bar
    layoutMoveStep   = 8,     -- pixels per D-pad tap in Layout Mode
    layoutResizeStep = 8,     -- pixels per trigger/bumper tap in Layout Mode

    -- DETECTION THRESHOLDS (Layer 1 InputModeDetector — Phase 1, PHASE 1 USES)
    -- Mirrored here from InputModeDetector so they can be tweaked at runtime
    -- via console (`ZeD.T.gp.stickThresh = 0.25`) during controller tuning.
    -- The detector reads these from T.gp on every poll, never hardcoded.
    stickThresh   = 0.20,     -- sqrt(lx² + ly²) radial deadzone — filters stick drift
    triggerThresh = 0.15,     -- abs(trigger) threshold — filters resting finger weight
    cooldownMs    = 200,      -- minimum ms between mode switches (last-event-wins)

    -- BUMPER CHORD (Layer 2 BumperChord — Phase 2) ---------------------------
    chordWindowMs = 250,      -- how long after first bumper press to wait for chord completion

    -- HOLD-TO-REPEAT — D-PAD SPATIAL NAV (Layer 3 FocusManager — Phase 3) ----
    holdInitMs    = 250,      -- initial delay before D-pad nav starts auto-repeating
    holdRepeatMs  = 120,      -- interval between auto-repeat ticks once started

    -- AIMING ESCAPE — RIGHT-STICK MAGNITUDE² THRESHOLD (S97 ring model) ------
    -- FocusManager polls right-stick every tick while a ZeD window is focused.
    -- When the stick is pushed past this threshold, the window is shaded and
    -- focus is released so gameplay input resumes instantly. Threshold is in
    -- squared magnitude units (|v|² = x² + y²) to avoid a sqrt call per tick.
    -- 0.81 ≈ 90% of full deflection on a unit-circle stick.
    aimingThresholdSq = 0.81,

    -- HOLD DETECTION — B-HOLD and Y-HOLD (S90 tap/hold dismiss model) --------
    -- Shared threshold for `cancel` (B) and `window_control` (Y) hold actions.
    -- ActionMap declares `holdMs = 400` on those entries; FocusManager reads
    -- this token to drive the hold timer. Schema-only in Phase 1.
    holdMs        = 400,

    -- D-PAD STRIP MENUS (new §12, S90 — Phase 3 dispatcher) ------------------
    stripAnchorY    = "bottomCenter",  -- symbolic anchor consumed by strip layout
    stripBottomGap  = 24,              -- pixels from screen bottom to strip baseline
    stripDismissMs  = 150,             -- fade-out duration on dismiss
}

-- ---------------------------------------------------------------------------
-- RADIO CHASSIS TOKENS (S115 — first contextual drawer chassis)
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
-- ACTIVE PALETTE: ZeD.T
-- This is what every component reads. It's rebuilt whenever the player
-- changes any setting. Components never reference BaseThemes or AccentColors
-- directly — they reference ZeD.T.
-- ---------------------------------------------------------------------------
ZeD.T = {}

-- Current setting keys (persisted through ModOptions)
ZeD.currentBase   = "dark"
ZeD.currentAccent = "orange"
ZeD.currentSize   = "small"

-- ---------------------------------------------------------------------------
-- APPLY THEME
-- Call this whenever a setting changes. Rebuilds ZeD.T from the three axes.
-- ---------------------------------------------------------------------------
function ZeD.applyTheme(baseKey, accentKey, sizeKey)
    -- Store current keys
    ZeD.currentBase   = baseKey   or ZeD.currentBase
    ZeD.currentAccent = accentKey or ZeD.currentAccent
    ZeD.currentSize   = sizeKey   or ZeD.currentSize

    local base   = ZeD.BaseThemes[ZeD.currentBase]
    -- Medium removed — fall back to small if persisted
    if ZeD.currentSize == "medium" then ZeD.currentSize = "small" end
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
    T.surf1    = base.surf1
    T.surf2    = base.surf2
    T.surf3    = base.surf3
    T.surf4    = base.surf4
    T.border   = base.border
    T.borderS  = base.borderS
    T.stripe   = base.stripe

    -- Text colors from base theme
    T.text     = base.text
    T.textSec  = base.textSec  -- placeholder, overwritten to accent after accent is set
    T.textDim  = base.textDim  -- structural chrome (scrollbar arrows, grip lines, ridges)
    T.textHead = base.textHead

    -- Status colors from base theme
    T.danger   = base.danger
    T.warning  = base.warning
    T.positive = base.positive
    T.info     = base.info

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
        T.text     = blend(T.text, ac, TINT * 0.5)
        T.textHead = blend(T.textHead, ac, TINT * 0.5)
    end

    -- 3-tone system: each F-role can use any of these three color tiers
    --   toneNorm = neutral white/black (no accent influence)
    --   toneHi   = accent at 90% alpha (primary accent text)
    --   toneLo   = accent at 50% alpha (ghost / secondary accent text)
    T.toneNorm = T.textHead
    T.toneHi   = { r = T.accent.r, g = T.accent.g, b = T.accent.b, a = 0.90 }
    T.toneLo   = { r = T.accent.r, g = T.accent.g, b = T.accent.b, a = 0.50 }
    -- Disclosure triangle color: toneNorm at 60% alpha (all expand/collapse chevrons)
    T.arrow    = { r = T.toneNorm.r, g = T.toneNorm.g, b = T.toneNorm.b, a = 0.60 }

    -- Secondary label color = toneLo (F1 at 50% accent — stat labels, section labels, category rows)
    T.textSec  = T.toneLo
    -- Dimmed accent: same hue at ~55% alpha for tertiary/supporting accent text
    T.accentDim = { r = T.accent.r, g = T.accent.g, b = T.accent.b, a = 0.55 }
    -- Category headers: same fontF1, neutral color (not accent)
    T.textCat  = T.textHead

    -- Font values: extract .font from rich atomics for drawText compatibility
    T.fontF1  = size.fontF1.font    -- F1 Chrome (Fira Mono Bold)
    T.fontF2  = size.fontF2.font    -- F2 Body (Fira Sans Regular)
    T.fontF3  = size.fontF3.font    -- F3 Data (Fira Mono Regular)
    T.fontF4  = size.fontF4.font    -- F4 Heading (Fira Sans Cond. SemiBold)
    T.fontF5  = size.fontF5.font    -- F5 Micro (Fira Sans Cond. Regular)
    -- Cached font heights (avoids per-frame getTextManager() bridge calls)
    if getTextManager then
        local tm = getTextManager()
        T.fontF1H = tm:getFontHeight(T.fontF1)
        T.fontF2H = tm:getFontHeight(T.fontF2)
        T.fontF3H = tm:getFontHeight(T.fontF3)
        T.fontF4H = tm:getFontHeight(T.fontF4)
        T.fontF5H = tm:getFontHeight(T.fontF5)
    end
    T.scale      = size.scale
    T.titleBarH  = size.titleBarH
    T.rowH       = size.rowH
    T.buttonH    = size.buttonH
    T.tabH       = size.tabH
    T.inputH     = size.inputH
    T.iconSm     = size.iconSm
    T.iconMd     = size.iconMd
    T.iconLg     = size.iconLg
    T.iconXl     = size.iconXl
    T.fillBarH   = size.fillBarH
    T.checkboxSz = size.checkboxSz
    T.closeBoxSz = size.closeBoxSz
    T.statIconSz = size.statIconSz
    T.contentPad = size.contentPad
    T.colGap     = size.colGap
    T.cardIconSz = size.cardIconSz
    T.contextRowH = size.contextRowH
    T.modalW     = size.modalW
    T.modalH     = size.modalH
    T.minWinW    = size.minWinW
    T.minWinH    = size.minWinH

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
    T.sp = ZeD.Spacing
    -- Context-menu tokens — static, not theme-dependent (see ZeD.Ctx definition above)
    T.ctx = ZeD.Ctx
    -- Gamepad tokens — static, not theme-dependent (see ZeD.Gp definition above)
    -- S91: InputModeDetector + ActionMap read T.gp.stickThresh/triggerThresh/cooldownMs
    T.gp  = ZeD.Gp

    -- Radio chassis tokens — static hardware colors, not theme-dependent.
    -- S115: first contextual drawer chassis, two tiers (Premium VFD / ValuTech LCD).
    T.radio = ZeD.Radio

    -- Set the active palette
    ZeD.T = T

    -- Fire a custom event so all open windows can refresh
    -- (components listen for this to re-read ZeD.T)
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
ZeD.applyTheme("dark", "orange", "small")
