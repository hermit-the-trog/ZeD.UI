-- LuaConsole93/42/media/lua/client/LuaConsole93/Tokens.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the parts of ZeD-GUI's Tokens.lua the console uses (64 of its
-- 105 statements).
-- Made from ZeD-GUI's 42/media/lua/shared/ZeD/Tokens.lua by ZeDUI/tools/products/build_luaconsole93.py. Do
-- not edit it here: change ZeD-GUI's file and build again.
-- ============================================================================================================

-- With ZeD-GUI on (mod ZeD_UI; the game can put a backslash before a mod's id), ZeD-GUI's console is the one:
-- this file stops here and defines nothing.
do
    local guiOn = false
    pcall(function()
        local mods = getActivatedMods()
        for i = 0, mods:size() - 1 do
            if string.gsub(tostring(mods:get(i)), "^\\", "") == "ZeD_UI" then guiOn = true end
        end
    end)
    if guiOn then return end
end

require "LuaConsole93/LC93_Text"
require "LuaConsole93/Scale"

LC93 = LC93 or {}

local function rgba(r, g, b, a)
    return {r = r, g = g, b = b, a = a or 1.0}
end

local function hex(str, a)
    local r = tonumber(str:sub(2, 3), 16) / 255
    local g = tonumber(str:sub(4, 5), 16) / 255
    local b = tonumber(str:sub(6, 7), 16) / 255
    return rgba(r, g, b, a or 1.0)
end

LC93.BaseThemes = {

    dark = {
        name     = "Dark",
        markAdd    = hex("#4491E2"),
        markRemove = hex("#D9572A"),
        base     = hex("#0C0C0C", 0.92),
        onBand   = hex("#030303", 1.0),
        surf1    = hex("#141414", 0.92),
        surf2    = hex("#1C1C1C", 0.92),
        surf3    = hex("#242424", 0.92),
        surf4    = hex("#2C2C2C", 0.92),
        border   = hex("#202020", 1.0),
        borderS  = hex("#383838", 1.0),
        text     = rgba(0.855, 0.855, 0.855, 1.0),
        textSec  = rgba(0.63, 0.63, 0.63, 0.65),
        textDim  = rgba(0.63, 0.63, 0.63, 0.65),
        textHead = rgba(0.90, 0.90, 0.90, 0.92),
        stripe   = rgba(1.00, 1.00, 1.00, 0.04),
        danger   = hex("#C45A2A"),
        warning  = hex("#C49A2A"),
        positive = hex("#7A9A34"),
        positiveText = hex("#7A9A34"),
        dangerText   = hex("#DE7045"),
        info     = hex("#5A8A9A"),
        violet   = hex("#9A6AC4"),
        borderW  = 1,
        disabledAlpha = 0.42,
        chromeHi = rgba(1.0, 1.0, 1.0, 1.0),
        chromeSh = rgba(0.0, 0.0, 0.0, 1.0),
        grooveDark  = rgba(0.0, 0.0, 0.0, 0.50),
        grooveLight = rgba(1.0, 1.0, 1.0, 0.06),
        modalOverlayA = 0.50,
        selectionA    = 0.30,
        dangerPulseMin = 0.08,
        dangerPulseMax = 0.12,
        dangerHoverMul = 1.20,
        scrollThumbA      = 0.30,
        scrollThumbHoverA = 0.20,
        scrollThumbDragA  = 0.30,
        badgeBgA = 0.10,
        ridgeLightA = 0.40,
        ridgeDarkA  = 0.20,
        drawerBg    = rgba(0.0, 0.0, 0.0, 0.15),
        soiledWet   = rgba(96/255, 176/255, 232/255, 0.9),
        soiledBlood = rgba(255/255, 106/255, 106/255, 0.9),
        soiledDirt  = rgba(200/255, 152/255, 96/255, 0.9),
        matLeather  = hex("#B08A5E"),
        matDenim    = hex("#5B8ABF"),
        matFabric   = rgba(1, 1, 1, 0.55),
        tempCold = rgba(60/255, 120/255, 220/255, 1.0),
        tempCool = rgba(60/255, 180/255, 140/255, 1.0),
        tempNorm = rgba(120/255, 200/255, 80/255, 1.0),
        tempWarm = rgba(220/255, 180/255, 50/255, 1.0),
        tempHot  = rgba(220/255, 80/255, 40/255, 1.0),
        tempColdBadge = { bg = rgba(60/255, 120/255, 220/255, 0.15), text = rgba(90/255, 150/255, 240/255, 1.0) },
        tempCoolBadge = { bg = rgba(60/255, 180/255, 140/255, 0.12), text = rgba(80/255, 195/255, 155/255, 1.0) },
        tempNormBadge = { bg = rgba(120/255, 200/255, 80/255, 0.12), text = rgba(130/255, 210/255, 90/255, 1.0) },
        tempWarmBadge = { bg = rgba(220/255, 180/255, 50/255, 0.15), text = rgba(230/255, 190/255, 60/255, 1.0) },
        tempHotBadge  = { bg = rgba(220/255, 80/255, 40/255, 0.15), text = rgba(235/255, 95/255, 55/255, 1.0) },
    },

    light = {
        name     = "Light",
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
        frameS   = hex("#424242", 1.0),
        frameHi  = hex("#D2D2D2", 1.0),
        text     = rgba(0.047, 0.047, 0.047, 0.95),
        textSec  = rgba(0.047, 0.047, 0.047, 0.72),
        textDim  = rgba(0.047, 0.047, 0.047, 0.72),
        textHead = rgba(0.02, 0.02, 0.02, 1.00),
        stripe   = rgba(0.0, 0.0, 0.0, 0.05),
        danger   = hex("#7A2A11"),
        warning  = hex("#6B5510"),
        positive = hex("#2A5511"),
        positiveText = hex("#204A0C"),
        dangerText   = hex("#7A2A11"),
        info     = hex("#1A5566"),
        violet   = hex("#552288"),
        borderW  = 1,
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
        drawerBg    = rgba(1.0, 1.0, 1.0, 0.12),
        soiledWet   = rgba(40/255, 110/255, 180/255, 0.9),
        soiledBlood = rgba(160/255, 40/255, 40/255, 0.9),
        soiledDirt  = rgba(130/255, 90/255, 50/255, 0.9),
        matLeather  = hex("#7A5A38"),
        matDenim    = hex("#2A5588"),
        matFabric   = rgba(0.2, 0.2, 0.2, 0.65),
        tempCold = rgba(30/255, 80/255, 180/255, 1.0),
        tempCool = rgba(20/255, 130/255, 100/255, 1.0),
        tempNorm = rgba(70/255, 150/255, 40/255, 1.0),
        tempWarm = rgba(180/255, 130/255, 20/255, 1.0),
        tempHot  = rgba(190/255, 50/255, 20/255, 1.0),
        tempColdBadge = { bg = rgba(30/255, 80/255, 180/255, 0.15), text = rgba(25/255, 65/255, 150/255, 1.0) },
        tempCoolBadge = { bg = rgba(20/255, 130/255, 100/255, 0.12), text = rgba(15/255, 105/255, 80/255, 1.0) },
        tempNormBadge = { bg = rgba(70/255, 150/255, 40/255, 0.12), text = rgba(55/255, 125/255, 30/255, 1.0) },
        tempWarmBadge = { bg = rgba(180/255, 130/255, 20/255, 0.15), text = rgba(150/255, 105/255, 10/255, 1.0) },
        tempHotBadge  = { bg = rgba(190/255, 50/255, 20/255, 0.15), text = rgba(160/255, 40/255, 15/255, 1.0) },
    },

    hicon = {
        name     = "High contrast",
        markAdd    = hex("#4491E2"),
        markRemove = hex("#D9572A"),
        base     = hex("#050505", 0.95),
        onBand   = hex("#000000", 1.0),
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
        positiveText = hex("#44DD44"),
        dangerText   = hex("#FF5533"),
        info     = hex("#44CCFF"),
        violet   = hex("#CC99FF"),
        borderW  = 2,
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
        drawerBg    = rgba(0.0, 0.0, 0.0, 0.15),
        soiledWet   = rgba(80/255, 200/255, 255/255, 1.0),
        soiledBlood = rgba(255/255, 80/255, 80/255, 1.0),
        soiledDirt  = rgba(230/255, 170/255, 100/255, 1.0),
        matLeather  = hex("#D4A870"),
        matDenim    = hex("#70AAEE"),
        matFabric   = rgba(1, 1, 1, 0.70),
        tempCold = rgba(60/255, 120/255, 220/255, 1.0),
        tempCool = rgba(60/255, 180/255, 140/255, 1.0),
        tempNorm = rgba(120/255, 200/255, 80/255, 1.0),
        tempWarm = rgba(220/255, 180/255, 50/255, 1.0),
        tempHot  = rgba(220/255, 80/255, 40/255, 1.0),
        tempColdBadge = { bg = rgba(60/255, 120/255, 220/255, 0.15), text = rgba(90/255, 150/255, 240/255, 1.0) },
        tempCoolBadge = { bg = rgba(60/255, 180/255, 140/255, 0.12), text = rgba(80/255, 195/255, 155/255, 1.0) },
        tempNormBadge = { bg = rgba(120/255, 200/255, 80/255, 0.12), text = rgba(130/255, 210/255, 90/255, 1.0) },
        tempWarmBadge = { bg = rgba(220/255, 180/255, 50/255, 0.15), text = rgba(230/255, 190/255, 60/255, 1.0) },
        tempHotBadge  = { bg = rgba(220/255, 80/255, 40/255, 0.15), text = rgba(235/255, 95/255, 55/255, 1.0) },
    },
}

LC93.AccentColors = {

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

local F = {}
F.sec        = { font = UIFont.NewMedium,  px = 11 }
F.secLg      = { font = UIFont.NewSmall,   px = 13 }
F.body       = { font = UIFont.Small,      px = 13 }
F.bodyLg     = { font = UIFont.Large,      px = 15 }
F.stat       = { font = UIFont.Medium,     px = 11 }
F.statLg     = { font = UIFont.CodeMedium, px = 13 }
F.head       = { font = UIFont.NewLarge,   px = 15 }
F.headLg     = { font = UIFont.CodeLarge,  px = 17 }
F.title      = { font = UIFont.Code,       px =  9 }
F.titleLg    = { font = UIFont.CodeSmall,  px = 11 }
F.rsv1       = { font = UIFont.Cred1,     px = 20 }
F.rsv2       = { font = UIFont.Cred2,     px = 24 }
F.rsv3       = { font = UIFont.MainMenu1, px = 16 }
F.rsv4       = { font = UIFont.MainMenu2, px = 20 }

F.sdf = {
    sec   = { font = UIFont.MainMenu2, px = 11, face = 64, lineH = 77, sdf = true },
    body  = { font = UIFont.MainMenu1, px = 13, face = 64, lineH = 77, sdf = true },
    stat  = { font = UIFont.Title,     px = 11, face = 64, lineH = 77, sdf = true },
    head  = { font = UIFont.Massive,   px = 15, face = 64, lineH = 77, sdf = true },
    title = { font = UIFont.Cred2,     px =  9, face = 64, lineH = 77, sdf = true },
}
LC93.Font = F

LC93.TextSizes = {

    small = {
        name       = "Small",
        scale      = 1.00,
        fontF1     = F.sec,
        fontF2     = F.body,
        fontF3     = F.stat,
        fontF4     = F.head,
        fontF5     = F.title,
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
        fontF1     = F.secLg,
        fontF2     = F.bodyLg,
        fontF3     = F.statLg,
        fontF4     = F.headLg,
        fontF5     = F.titleLg,
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

LC93.Spacing = {
    xs  = 6,
    sm  = 10,
    md  = 14,
    lg  = 18,
    xl  = 24,
    xxl = 32,
    iconGap       = 8,
    statGap       = 14,
    statIconGap   = 6,
    tabPadX       = 14,
    tabGap        = 3,
    buttonPadX    = 14,
    inputPadX     = 10,
    sectionIndent = 18,
    scrollbarW    = 14,
    scrollGripOff = 3,
    scrollGripMar = 6,
    badgePadX     = 9,
    badgePadY     = 3,
    badgeGap      = 6,
    gridCellGap   = 3,
    gridCellPad   = 6,
    titleBoxPad   = 3,
    resizeHotZone = 4,
    contextPadH   = 14,
    contextPadV   = 5,
    contextSafeM  = 4,
    textLineGap   = 4,
    beforeHead    = 8,
    headGap       = 8,
    rowGap        = 6,
    afterLine     = 10,
    afterGroove   = 8,
    cardBeforeHead = 4,
    cardAfterHead  = 8,
    cardAfterBody  = 4,
    cardAfterLabel = 6,
    colHdrH       = 20,
    catHdrH       = 15,
    tabHeaderH    = 37,
    figurePadTop  = 12,
    figureW       = 220,
    figureH       = 260,
    pillBtnPadV   = 10,
}

LC93.Ctx = {
    cellW       = 22,
    cellH       = 22,
    iconPx      = 16,
    gap         = 1,

    maxVisible  = 10,

    bumperMinW  = 28,
    chevW       = 12,
    gutter      = 3,
    balloonW    = 230,

    pinDotSz      = 3,
    submenuTriSz  = 3,

    shadowStep       = 2,
    pointerTriOuter  = 6,
    pointerTriInner  = 5,

    labelMarginV       = 28,
    targetCardMarginV  = 10,
    balloonMarginV     = 10,
    targetIconPx       = 18,

    animMs         = 180,
    settleDelayMs  = 200,

    drilledBorderTop = 2,

    markAdd    = { r = 0x0B / 255, g = 0x63 / 255, b = 0xB0 / 255, a = 1 },
    markRemove = { r = 0xC2 / 255, g = 0x41 / 255, b = 0x0C / 255, a = 1 },
}

LC93.Gp = {
    focusRingW    = 2,
    focusRingPad  = 1,
    focusFillA    = 0.10,

    promptSize    = 16,
    promptSizeSm  = 12,
    promptGap     = 4,

    layoutHudH       = 22,
    layoutHudY       = 4,
    layoutMoveStep   = 8,
    layoutResizeStep = 8,

    stickThresh   = 0.20,
    triggerThresh = 0.15,
    cooldownMs    = 200,

    chordWindowMs = 250,

    holdInitMs    = 250,
    holdRepeatMs  = 120,

    aimingThresholdSq = 0.81,

    holdMs        = 400,

    stripAnchorY    = "bottomCenter",
    stripBottomGap  = 24,
    stripDismissMs  = 150,
}

LC93.Radio = LC93.Radio or {}

local function lin(c)
    if c <= 0.03928 then return c / 12.92 end
    return ((c + 0.055) / 1.055) ^ 2.4
end

local function lum(c)
    return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b)
end

function LC93.contrast(a, b)
    local l1, l2 = lum(a), lum(b)
    if l1 < l2 then l1, l2 = l2, l1 end
    return (l1 + 0.05) / (l2 + 0.05)
end

function LC93.legible(fg, minR, bgs, up)
    local goal = up and 1 or 0
    for i = 0, 25 do
        local t = i * 0.04
        local c = { r = fg.r + (goal - fg.r) * t, g = fg.g + (goal - fg.g) * t, b = fg.b + (goal - fg.b) * t, a = 1 }
        local ok = true
        for j = 1, #bgs do
            if LC93.contrast(c, bgs[j]) < minR then ok = false; break end
        end
        if ok then return c end
    end
    return { r = goal, g = goal, b = goal, a = 1 }
end

local INK, PAPER = hex("#0C0C0C"), hex("#F2F0EC")
local BLACK, WHITE = { r = 0, g = 0, b = 0, a = 1 }, { r = 1, g = 1, b = 1, a = 1 }
function LC93.textOn(fill)
    local c = (LC93.contrast(INK, fill) >= LC93.contrast(PAPER, fill)) and INK or PAPER
    if LC93.contrast(c, fill) < 4.5 then c = (c == INK) and BLACK or WHITE end
    return c
end

LC93.LABELS = {
    { k = "red",    name = "ContextMenu_Red" },
    { k = "orange", name = "ContextMenu_Orange" },
    { k = "yellow", name = "ContextMenu_Yellow" },
    { k = "green",  name = "ContextMenu_Green" },
    { k = "blue",   name = "ContextMenu_Blue" },
    { k = "teal",   name = "UI_LC93_Accent_Teal" },
    { k = "purple", name = "ContextMenu_Purple" },
    { k = "pink",   name = "ContextMenu_Pink" },
}

LC93.READABLE_KEYS = {
    "accentText", "toneHi", "toneLo", "textSec", "accentDim", "textDim", "textOnAccent", "textOnFocus",
    "dangerText", "warningText", "positiveText", "infoText", "textOnWarning", "textOnDanger",
    "soiledWetText", "soiledBloodText", "soiledDirtText", "labels", "labelsText",
}

local function flatOver(world, s, c, ca)
    local sa = s.a or 1
    local r, g, b = s.r * sa + world * (1 - sa), s.g * sa + world * (1 - sa), s.b * sa + world * (1 - sa)
    if c then
        r, g, b = c.r * ca + r * (1 - ca), c.g * ca + g * (1 - ca), c.b * ca + b * (1 - ca)
    end
    return { r = r, g = g, b = b }
end

function LC93.deriveReadable(P, baseKey, statusKey)
    local base  = LC93.BaseThemes[baseKey] or LC93.BaseThemes.dark
    local up    = (baseKey ~= "light")
    local world = up and 1 or 0
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

    local at = LC93.legible(ac, 4.7, bgs, up)
    P.accentText, P.toneHi = at, at

    local tx = P.text
    local g0 = {
        r = (f1.r + (tx.r - f1.r) * 0.45) * 0.70 + ac.r * 0.30,
        g = (f1.g + (tx.g - f1.g) * 0.45) * 0.70 + ac.g * 0.30,
        b = (f1.b + (tx.b - f1.b) * 0.45) * 0.70 + ac.b * 0.30,
    }
    local ghost = LC93.legible(g0, 4.6, bgs, up)
    if baseKey == "dark" then
        local d1 = flatOver(0, s1)
        local gd = {
            r = (d1.r + (tx.r - d1.r) * 0.45) * 0.70 + ac.r * 0.30,
            g = (d1.g + (tx.g - d1.g) * 0.45) * 0.70 + ac.g * 0.30,
            b = (d1.b + (tx.b - d1.b) * 0.45) * 0.70 + ac.b * 0.30,
        }
        ghost = LC93.legible(LC93.legible(gd, 7.0, { d1 }, true), 4.5, { f1 }, true)
    end
    P.toneLo, P.textSec, P.accentDim = ghost, ghost, ghost
    P.textDim = LC93.legible({
        r = f1.r + (tx.r - f1.r) * 0.40, g = f1.g + (tx.g - f1.g) * 0.40, b = f1.b + (tx.b - f1.b) * 0.40,
    }, 4.6, bgs, up)
    if baseKey == "dark" then
        local d1 = flatOver(0, s1)
        P.textDim = LC93.legible(LC93.legible({
            r = d1.r + (tx.r - d1.r) * 0.25, g = d1.g + (tx.g - d1.g) * 0.25, b = d1.b + (tx.b - d1.b) * 0.25,
        }, 5.0, { d1 }, true), 4.5, { f1 }, true)
    end

    P.textOnAccent = LC93.textOn(ac)

    local w0, w1 = flatOver(0, s1, ac, 0.55), flatOver(1, s1, ac, 0.55)
    local kb = math.min(LC93.contrast(BLACK, w0), LC93.contrast(BLACK, w1))
    local kw = math.min(LC93.contrast(WHITE, w0), LC93.contrast(WHITE, w1))
    P.textOnFocus = (kb >= kw) and BLACK or WHITE

    local n = #bgs
    local list = { bgs[1], bgs[2], bgs[3], bgs[4], bgs[5], bgs[6], bgs[7] }
    local bw = math.max(base.badgeBgA, 0.12)
    local function variant(c, washA)
        list[n + 1] = flatOver(world, s1, c, washA)
        return LC93.legible(c, 4.6, list, up)
    end
    local st = LC93.statusSet(baseKey, statusKey or P.statusKey)
    P.textOnWarning, P.textOnDanger = LC93.textOn(st.warning), LC93.textOn(st.danger)
    local function statusText(seed, hue)
        list[n + 1] = flatOver(world, s1, hue, bw)
        list[n + 2] = { r = s2.r, g = s2.g, b = s2.b }
        local c = LC93.legible(seed or hue, 4.6, list, up)
        list[n + 2] = nil
        return c
    end
    P.dangerText, P.warningText = statusText(st.dangerText, st.danger), variant(st.warning, bw)
    P.positiveText, P.infoText  = statusText(st.positiveText, st.positive), variant(base.info, bw)
    P.soiledWetText   = variant(base.soiledWet, 0.20)
    P.soiledBloodText = variant(base.soiledBlood, 0.20)
    P.soiledDirtText  = variant(base.soiledDirt, 0.20)
    local labs, labT = {}, {}
    for _, L in ipairs(LC93.LABELS) do
        local set = LC93.AccentColors[L.k]
        local c = set and set[(baseKey == "light") and "light" or "dark"].accent
        if c then
            labs[L.k] = LC93.legible(c, 3.0, bgs, up)
            labT[L.k] = LC93.legible(c, 4.6, bgs, up)
        end
    end
    P.labels, P.labelsText = labs, labT
end

LC93.T = {}

LC93.StatusColors = {
    cb = {
        dark  = { positive = hex("#4491E2"), warning = hex("#F0D060"), danger = hex("#D9572A") },
        light = { positive = hex("#014E8E"), warning = hex("#8C6E00"), danger = hex("#6E1E00") },
        hicon = { positive = hex("#5AAEFF"), warning = hex("#FFDD33"), danger = hex("#E84A22") },
    },
}
LC93.currentStatus = "standard"
function LC93.statusSet(baseKey, statusKey)
    local base = LC93.BaseThemes[baseKey] or LC93.BaseThemes.dark
    return (((statusKey or LC93.currentStatus) == "cb") and LC93.StatusColors.cb[baseKey]) or base
end

LC93.DEFAULT_ACCENT = "teal"

LC93.currentBase   = "dark"
LC93.currentAccent = LC93.DEFAULT_ACCENT
LC93.currentSize   = "small"
LC93.surfaceAlpha = 0.9

function LC93.seeThroughWorks(baseKey)
    return (baseKey or LC93.currentBase) == "dark"
end

function LC93.buildColors(P, baseKey, accentKey, statusKey, seePick)
    local T = P
    if not LC93.BaseThemes[baseKey] then baseKey = "dark" end
    if not LC93.AccentColors[accentKey] then accentKey = LC93.DEFAULT_ACCENT end
    if statusKey ~= "cb" then statusKey = "standard" end
    T.baseKey, T.accentKey, T.statusKey = baseKey, accentKey, statusKey
    local base   = LC93.BaseThemes[baseKey]

    local accentSet = LC93.AccentColors[accentKey]
    local accentVariant
    if baseKey == "light" then
        accentVariant = accentSet.light
    else
        accentVariant = accentSet.dark
    end

    T.base     = base.base
    T.marks    = { add = base.markAdd, remove = base.markRemove }
    T.onBand   = base.onBand or base.base
    T.surf1    = base.surf1
    T.surf2    = base.surf2
    T.surf3    = base.surf3
    T.surf4    = base.surf4
    local sa = seePick
    if not LC93.seeThroughWorks(baseKey) then sa = 1 end
    if type(sa) == "number" then
        if sa < 0.6 then sa = 0.6 elseif sa > 1 then sa = 1 end
        T.base  = LC93.colorAlpha(T.base, sa)
        T.surf1 = LC93.colorAlpha(T.surf1, sa)
        T.surf2 = LC93.colorAlpha(T.surf2, sa)
        T.surf3 = LC93.colorAlpha(T.surf3, sa)
        T.surf4 = LC93.colorAlpha(T.surf4, sa)
    end
    T.surfaceAlpha = sa
    T.border   = base.border
    T.borderS  = base.borderS
    T.frameS   = base.frameS or base.borderS
    T.frameHi  = base.frameHi
    T.stripe   = base.stripe

    T.text     = base.text
    T.textSec  = base.textSec
    T.textDim  = base.textDim
    T.textHead = base.textHead

    local st = LC93.statusSet(baseKey, statusKey)
    T.danger   = st.danger
    T.warning  = st.warning
    T.positive = st.positive
    T.info     = base.info
    T.violet   = base.violet

    T.borderW      = base.borderW
    T.disabledAlpha = base.disabledAlpha

    T.chromeHi = base.chromeHi
    T.chromeSh = base.chromeSh

    T.grooveDark  = base.grooveDark
    T.grooveLight = base.grooveLight

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

    T.soiledWet   = base.soiledWet
    T.soiledBlood = base.soiledBlood
    T.soiledDirt  = base.soiledDirt

    T.matLeather = base.matLeather
    T.matDenim   = base.matDenim
    T.matFabric  = base.matFabric

    T.accent       = accentVariant.accent
    T.accentBright = accentVariant.bright
    T.hover        = accentVariant.hover
    T.textOnAccent = accentVariant.textOnAccent

    if accentKey ~= "mono" then
        local isLight = baseKey == "light"
        local TINT = isLight and 0.10 or 0.03
        local ac = isLight and T.accentBright or T.accent
        local blend = LC93.colorBlend
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

    T.toneNorm = T.textHead
    T.arrow    = { r = T.toneNorm.r, g = T.toneNorm.g, b = T.toneNorm.b, a = 0.60 }

    LC93.deriveReadable(T, baseKey, statusKey)
    T.textCat  = T.textHead

    T.tempCold = base.tempCold
    T.tempCool = base.tempCool
    T.tempNorm = base.tempNorm
    T.tempWarm = base.tempWarm
    T.tempHot  = base.tempHot

    T.tempColdBadge = base.tempColdBadge
    T.tempCoolBadge = base.tempCoolBadge
    T.tempNormBadge = base.tempNormBadge
    T.tempWarmBadge = base.tempWarmBadge
    T.tempHotBadge  = base.tempHotBadge

    T.iconWhite = {r = 1, g = 1, b = 1}
    T.iconTone  = (baseKey == "light") and {r = 0, g = 0, b = 0} or {r = 1, g = 1, b = 1}

    return T
end

function LC93.applyTheme(baseKey, accentKey, sizeKey)
    LC93.currentBase   = baseKey   or LC93.currentBase
    LC93.currentAccent = accentKey or LC93.currentAccent
    LC93.currentSize   = sizeKey   or LC93.currentSize

    if not LC93.BaseThemes[LC93.currentBase]     then LC93.currentBase   = "dark"   end
    if not LC93.AccentColors[LC93.currentAccent] then LC93.currentAccent = LC93.DEFAULT_ACCENT end
    if LC93.currentSize == "medium" or not LC93.TextSizes[LC93.currentSize] then LC93.currentSize = "small" end
    local size   = LC93.TextSizes[LC93.currentSize]

    local sa = LC93.surfaceAlpha
    if LC93._seeForced and sa == 1 then sa = LC93._seePick end
    LC93.surfacePick = sa
    if LC93.seeThroughWorks(LC93.currentBase) then
        LC93._seeForced = nil
        LC93.surfaceAlpha = sa
    else
        LC93._seePick, LC93._seeForced = sa, true
        LC93.surfaceAlpha = 1
    end

    local T = {}
    LC93.buildColors(T, LC93.currentBase, LC93.currentAccent, LC93.currentStatus, sa)

    local SD = LC93.Font.sdf
    local roleEntries = { SD.sec, SD.body, SD.stat, SD.head, SD.title }
    local rolePx      = { size.fontF1.px, size.fontF2.px, size.fontF3.px, size.fontF4.px, size.fontF5.px }
    T.fontPx, T.fontFace = {}, {}
    T.fontFallback = (LC93.Text and LC93.Text.checkRoleFonts and LC93.Text.checkRoleFonts()) and true or false
    for i = 1, 5 do
        local e = roleEntries[i]
        if T.fontFallback then
            T["fontF" .. i] = LC93.Text.roleFallbackFont(rolePx[i], i)
        else
            T["fontF" .. i] = e.font
            T.fontPx[e.font]   = rolePx[i]
            T.fontFace[e.font] = e.face or 64
        end
    end
    local root = (LC93.Scale and LC93.Scale.root and LC93.Scale.root()) or 1
    local sc = root * (size.scale or 1)
    T.scale = sc
    T.root  = root
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
    T.art   = (LC93.Scale and LC93.Scale.artZoom) and LC93.Scale.artZoom(sc) or math.max(1, math.floor(sc + 0.5 + 1e-6))
    local small = LC93.TextSizes.small
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

    local lineK = 77 / 64
    local rowSc = size.scale or 1
    local row1  = math.max(size.inputH, size.buttonH, size.fontF4.px * lineK)
    T.stripH    = math.floor((row1 + 11 * rowSc) * root + 0.5)
    T.sortBarH  = math.floor((size.fontF1.px * lineK + 7 * rowSc) * root + 0.5)

    T.sp = {}
    for k, v in pairs(LC93.Spacing) do T.sp[k] = (type(v) == "number") and T.px(v) or v end
    T.sp.tabHeaderH = T.stripH
    T.sp.colHdrH    = T.sortBarH
    T.sp.figureW = LC93.Spacing.figureW * T.art
    T.sp.figureH = LC93.Spacing.figureH * T.art
    T.grooveH = 2 * T.hair
    T.ctx = {}
    local CTX_NOT_PX = { maxVisible = true, animMs = true, settleDelayMs = true }
    for k, v in pairs(LC93.Ctx) do T.ctx[k] = (type(v) == "number" and not CTX_NOT_PX[k]) and T.px(v) or v end
    T.gp  = LC93.Gp

    T.radio = LC93.Radio

    LC93._sharedT = T
    LC93._themeGen = (LC93._themeGen or 0) + 1
    T.themeGen = LC93._themeGen
    LC93._playerT = {}
    LC93.T = T
    if getTextManager and not (LC93.Text and LC93.Text.noFonts) then
        local tm = LC93.TM
        T.fontF1H = tm:getFontHeight(T.fontF1)
        T.fontF2H = tm:getFontHeight(T.fontF2)
        T.fontF3H = tm:getFontHeight(T.fontF3)
        T.fontF4H = tm:getFontHeight(T.fontF4)
        T.fontF5H = tm:getFontHeight(T.fontF5)
        if T.fontFallback then
            T.stripH   = math.max(T.stripH, T.fontF4H + T.px(11))
            T.sortBarH = math.max(T.sortBarH, T.fontF1H + T.px(7))
            T.sp.tabHeaderH, T.sp.colHdrH = T.stripH, T.sortBarH
        end
    end
    if LC93.currentSize == "large" then
        T.sortFont   = T.fontF1
        T.sortWidthK = (size.fontF1.px * 0.6) / (size.fontF5.px * 0.48)
    else
        T.sortFont   = T.fontF5
        T.sortWidthK = 1
    end
    if LC93.Scale then LC93.Scale._appliedRoot = root end

    if Events and Events.OnLC93ThemeChanged then
        triggerEvent("OnLC93ThemeChanged")
    end
end

LC93.Theme = LC93.Theme or {}
LC93._playerT = LC93._playerT or {}

function LC93.colorAlpha(color, alpha)
    return {r = color.r, g = color.g, b = color.b, a = alpha}
end

function LC93.colorBlend(base, overlay, strength)
    local inv = 1.0 - strength
    return {
        r = base.r * inv + overlay.r * strength,
        g = base.g * inv + overlay.g * strength,
        b = base.b * inv + overlay.b * strength,
        a = base.a,
    }
end

local KEEP_CAPS = {
    OK = "OK", CD = "CD", CDS = "CDs", TV = "TV", VHS = "VHS", AM = "AM", FM = "FM", ID = "ID",
    HP = "HP", MP = "MP", PC = "PC", USB = "USB", NPC = "NPC", NPCS = "NPCs", XP = "XP", DLC = "DLC",
    UI = "UI", HUD = "HUD", PZ = "PZ", OS = "OS", IP = "IP", PVP = "PvP", PVE = "PvE",
    RGB = "RGB", FPS = "FPS", MHZ = "MHz", KHZ = "kHz", KM = "km", KG = "kg", LED = "LED", GPS = "GPS",
}
local DEGREE = string.char(176)
local LABEL_CACHE_MAX = 512
local labelCache, labelOrder, labelHead = {}, {}, 1

local function toSentenceCase(s)
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
        else
            w = w:lower()
            if first then w = (LC93.upper or string.upper)(w:sub(1, 1)) .. w:sub(2) end
        end
        first = false
        parts[#parts + 1] = w
        pos = b + 1
    end
    return table.concat(parts)
end

local _logSeen, _logCount = {}, 0
function LC93.logOnce(key, msg)
    local safe = LC93.Safe
    if safe and safe.fault then safe.fault(key, msg) end
    local k = tostring(key) .. "|" .. tostring(msg)
    if _logSeen[k] then return end
    if _logCount >= 500 then return end
    _logSeen[k] = true
    _logCount = _logCount + 1
    print("[Lua Console 93] " .. tostring(key) .. ": " .. tostring(msg))
end

function LC93.btnCase(s)
    if s == nil then return s end
    s = tostring(s)
    local hit = labelCache[s]
    if hit then return hit end
    local out = toSentenceCase(s)
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

function LC93.textCase(s)
    return LC93.btnCase(s)
end

LC93.applyTheme("dark", LC93.DEFAULT_ACCENT, "small")
