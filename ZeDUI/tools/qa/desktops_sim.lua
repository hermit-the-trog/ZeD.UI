-- ZeDUI/tools/qa/desktops_sim.lua  (Desktops, Nov 22 2026, Build): ZeD OS's desktops with no game.
-- The real ZeD_MainMenuDesktops.lua (ZeD.Desktops), the real MM.desktop / MM.setDesktop / MM.drawWallpaper /
-- MM.drawGameArt cut out of ZeD_MainMenu.lua, and the real ZeD_MainMenuDesktopPick.lua (the Desktop window) on
-- desk_stub.lua. It checks:
--   * the options: 25 in four groups (2, 10, 5, 8), every one in D.OPT, every texture on disk, every name and note
--     key in EN UI.json
--   * the choice (D.idOf): "original" is the painting, "new" the title video, an id is itself, anything else or no
--     file the painting; MM.setDesktop keeps the id in Zomboid/Lua/ZeD_wallpaper.txt
--   * the color (D.tone) against the handoff's table: orange #FA8F1C to #8D5A2E, green to #477544, blue to #4B679B,
--     white to #676767, PZ Teal's Dark accent to #187865; the color is toned again only when it changes
--   * MM.drawWallpaper's branch: Painting and Title video as before (dimmed 0.55, the video falling back to the
--     painting with video effects off); every other desktop through D.draw, undimmed, the ground the toned color
--     and the tiles at the icons' dot zoom (1 at UI scale 1, 2 at 1.75); the flags one picture over the tube
--   * the Desktop window: 660 wide, centered under the menu bar (x 150, y 44 of a 960 x 720 tube), 25 swatches and
--     Done; a press sets the desktop and moves the ring; the help line; one read of the color a frame; B and Done
--     close it; the Settings menu's row
-- What it can't show: the pictures on screen, the real D-pad walk (the stub's window has no spatial walk), the video.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/desktops_sim.lua
-- It prints FAIL lines and a last line "desktops_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]desktops_sim%.lua$", "")
local CDIR = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function readAll(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

-- ---------------------------------------------------------------------------
-- THE STUBS: the desk's (desk_stub.lua), and the game's color and textures
-- ---------------------------------------------------------------------------
local S = dofile(ROOT .. "ZeDUI/tools/qa/desk_stub.lua")
local W, DISK = S.W, S.DISK
local MM = ZeD.MainMenu

local G = { color = { 0.98, 0.56, 0.11 }, reads = 0, effects = true }
local core = getCore()
core.getObjectHighlitedColor = function()
    G.reads = G.reads + 1
    local c = G.color
    return { getR = function() return c[1] end, getG = function() return c[2] end, getB = function() return c[3] end }
end
core.getOptionDoVideoEffects = function() return G.effects end
getCore = function() return core end
getTexture = function(path) return { path = path, smooth = true } end
Texture = { getSharedTexture = function(path, flags) return { path = path, flags = flags } end }

-- every draw on a panel, in order
local log = {}
local function rec(kind) return function(_, ...) log[#log + 1] = { kind, ... } end end
local Pan = {}
for _, n in ipairs({ "drawRect", "drawTextureScaled", "setStencilRect", "clearStencilRect", "drawText" }) do Pan[n] = rec(n) end

-- ---------------------------------------------------------------------------
section("the options")
dofile(CDIR .. "ZeD_MainMenuDesktops.lua")
local D = ZeD.Desktops
check("ZeD.Desktops is the module", type(D) == "table" and type(D.draw) == "function")
local counts, all = {}, {}
for i, g in ipairs(D.GROUPS) do
    counts[i] = #g.ids
    for _, id in ipairs(g.ids) do all[#all + 1] = id end
end
check("four groups of 2, 10, 5 and 8", table.concat(counts, ",") == "2,10,5,8", table.concat(counts, ","))
local EN = readAll(ROOT .. "42/media/lua/shared/Translate/EN/UI.json") or ""
local function hasKey(k) return string.find(EN, '"' .. k .. '":', 1, true) ~= nil end
for _, g in ipairs(D.GROUPS) do check("group heading key " .. g.key, hasKey(g.key)) end
for _, id in ipairs(all) do
    local o = D.OPT[id]
    check(id .. " is an option", o ~= nil)
    check(id .. ": its name key is in EN", hasKey(D.nameKey(id)), D.nameKey(id))
    check(id .. ": its note key is in EN", hasKey(D.noteKey(id)), D.noteKey(id))
    for _, f in ipairs({ o and o.tex, o and o.chip }) do
        if f then check(id .. ": " .. f .. " is installed", readAll(ROOT .. "42/media/textures/ZeD/mainmenu/desktops/" .. f) ~= nil) end
    end
end
local nOpt = 0
for _ in pairs(D.OPT) do nOpt = nOpt + 1 end
check("25 options, none outside a group", #all == 25 and nOpt == 25, #all .. " / " .. nOpt)
for _, k in ipairs({ "UI_ZeD_MainMenu_Desktop", "UI_ZeD_Desktop_Title", "UI_ZeD_Desktop_Help", "UI_ZeD_Desktop_Foot", "UI_ZeD_Desktop_Done" }) do
    check(k .. " is in EN", hasKey(k))
end
check("the wallpaper rows' keys are gone from EN", not hasKey("UI_ZeD_MainMenu_WallpaperOriginal") and not hasKey("UI_ZeD_MainMenu_WallpaperNew"))
check("a name key: UI_ZeD_Desktop_Classic", D.nameKey("classic") == "UI_ZeD_Desktop_Classic")
check("a note key: UI_ZeD_Desktop_Usa_Note", D.noteKey("usa") == "UI_ZeD_Desktop_Usa_Note")

-- ---------------------------------------------------------------------------
section("the choice (D.idOf)")
check("original is the painting", D.idOf("original") == "painting")
check("new is the title video", D.idOf("new") == "video")
check("an id is itself", D.idOf("kentucky") == "kentucky" and D.idOf("classic") == "classic")
check("no file is the painting", D.idOf(nil) == "painting")
check("anything else is the painting", D.idOf("plaid") == "painting" and D.idOf("") == "painting")

-- ---------------------------------------------------------------------------
section("the color (D.tone)")
local function hex(r, g, b)
    local function byte(v) return math.floor(v * 255 + 0.5) end
    return string.format("#%02X%02X%02X", byte(r), byte(g), byte(b))
end
local function hexIn(s) return tonumber(s:sub(2, 3), 16) / 255, tonumber(s:sub(4, 5), 16) / 255, tonumber(s:sub(6, 7), 16) / 255 end
local function toneHex(r, g, b) return hex(D.tone(r, g, b)) end
local fr, fg, fb = hexIn("#FA8F1C")
check("the default orange #FA8F1C comes out #8D5A2E", toneHex(fr, fg, fb) == "#8D5A2E", toneHex(fr, fg, fb))
check("green 0.25 0.80 0.25 comes out #477544", toneHex(0.25, 0.80, 0.25) == "#477544", toneHex(0.25, 0.80, 0.25))
check("blue 0.25 0.50 1.00 comes out #4B679B", toneHex(0.25, 0.50, 1.00) == "#4B679B", toneHex(0.25, 0.50, 1.00))
check("white comes out #676767", toneHex(1, 1, 1) == "#676767", toneHex(1, 1, 1))
local tr_, tg, tb = hexIn("#47A18C")
check("PZ Teal's Dark accent #47A18C comes out #187865", toneHex(tr_, tg, tb) == "#187865", toneHex(tr_, tg, tb))
-- the ground: one read of the game's color a call; toned again only on a change
G.reads = 0
local r1, g1, b1 = D.ground()
check("D.ground reads the game's color once", G.reads == 1, G.reads)
local r0, g0, b0 = D.tone(0.98, 0.56, 0.11)
check("D.ground is the toned container color", r1 == r0 and g1 == g0 and b1 == b0)
local lr, lg, lb = D.lastGround()
check("D.lastGround gives the same, with no read", lr == r1 and lg == g1 and lb == b1 and G.reads == 1, G.reads)
local realTone, tones = D.tone, 0
D.tone = function(...) tones = tones + 1; return realTone(...) end
D.ground(); D.ground()
check("the same color is not toned again", tones == 0, tones)
G.color = { 0.25, 0.80, 0.25 }
local r2, g2, b2 = D.ground()
check("a new color in Options is toned at once", tones == 1 and hex(r2, g2, b2) == "#477544", tones .. " " .. hex(r2, g2, b2))
D.tone = realTone
G.color = { 0.98, 0.56, 0.11 }
D.ground()
-- the accent: the Dark value whatever the theme
ZeD.AccentColors = { teal = { dark = { accent = { r = tr_, g = tg, b = tb } }, light = { accent = { r = 0, g = 0, b = 0 } } },
                     orange = { dark = { accent = { r = 0.83, g = 0.57, b = 0.16 } } } }
ZeD.T.accentKey = "teal"
check("Accent takes the accent's Dark value, toned", hex(D.accentGround()) == "#187865", hex(D.accentGround()))
ZeD.T.accentKey = "nosuch"
check("an accent that names nothing falls back to Orange's", hex(D.accentGround()) == hex(D.tone(0.83, 0.57, 0.16)))
ZeD.T.accentKey = "teal"

-- ---------------------------------------------------------------------------
section("the dot zoom")
ZeD.T.scale = 1
check("1 at UI scale 1 (1080p)", D.zoom() == 1)
ZeD.T.scale = 1.75
check("2 at UI scale 1.75 (4K)", D.zoom() == 2)
ZeD.T.scale = 2.0
check("2 at 2.0", D.zoom() == 2)
ZeD.T.scale = 1

-- ---------------------------------------------------------------------------
section("MM.drawWallpaper's branch (the real code, cut from ZeD_MainMenu.lua)")
local SRC = readAll(CDIR .. "ZeD_MainMenu.lua") or ""
local function cut(name)
    local a = string.find(SRC, "\nfunction " .. name .. "%(")
    if not a then return nil end
    local b = string.find(SRC, "\nend\n", a + 1, true) or string.find(SRC, "\nend\r\n", a + 1, true)
    return b and string.sub(SRC, a + 1, b + 4) or nil
end
local parts = {}
for _, n in ipairs({ "MM.desktop", "MM.setDesktop", "MM.drawWallpaper", "MM.drawGameArt" }) do
    local f = cut(n)
    check(n .. " is in ZeD_MainMenu.lua", f ~= nil)
    parts[#parts + 1] = f or ""
end
check("MM.wallpaper and MM.setWallpaper are gone", not string.find(SRC, "function MM.wallpaper(", 1, true) and not string.find(SRC, "function MM.setWallpaper(", 1, true))
check("ZeD_MainMenu.lua requires the module", string.find(SRC, 'require "ZeD/ZeD_MainMenuDesktops"', 1, true) ~= nil)
local WALL_FILE = string.match(SRC, 'local WALL_FILE, WALL_VIDEO = "([^"]+)"')
local DIM = tonumber(string.match(SRC, "local WALL_DIM = ([%d%.]+)"))
check("the file is still ZeD_wallpaper.txt", WALL_FILE == "ZeD_wallpaper.txt", WALL_FILE)
SIM = { tiles = 0, zap = 0, frames = 0, video = { RenderFrame = function() SIM.frames = SIM.frames + 1 end }, hasVideo = true, clicks = 0 }
local pre = "local MM = ZeD.MainMenu\nlocal WALL_FILE = " .. string.format("%q", WALL_FILE or "") .. "\nlocal WALL_DIM = " .. tostring(DIM or 0.55) .. "\n"
    .. "local WALL_TILES, WALL_ZAP_TILES = { 'zap0' }, { 'zap1' }\n"
    .. "local function drawTiles(p, tiles, tx, ty, tw, th, a) if tiles == WALL_TILES then SIM.tiles = SIM.tiles + 1 else SIM.zap = SIM.zap + 1 end return true end\n"
    .. "local function zapLevel(t) return SIM.zapLevel or 0 end\n"
    .. "local function wallVideo() return SIM.hasVideo and SIM.video or nil end\n"
    .. "local function clickSound() SIM.clicks = SIM.clicks + 1 end\n"
local chunk, err = loadstring(pre .. table.concat(parts, "\n"))
check("the cut code loads", chunk ~= nil, err)
if chunk then chunk() end
local L = { tx = 480, ty = 180, tw = 960, th = 720 }
local function dims()
    local n = 0
    for _, e in ipairs(log) do if e[1] == "drawRect" and e[6] == (DIM or 0.55) and e[7] == 0 and e[8] == 0 and e[9] == 0 then n = n + 1 end end
    return n
end
local function draws(kind)
    local n = 0
    for _, e in ipairs(log) do if e[1] == kind then n = n + 1 end end
    return n
end
local function paint(id, fileLine)
    MM._wall = nil
    DISK[WALL_FILE] = fileLine and (fileLine .. "\n") or nil
    log = {}
    SIM.tiles, SIM.zap, SIM.frames = 0, 0, 0
    MM.drawWallpaper(Pan, L, 1000)
end
if chunk then
    paint(nil, nil)
    check("no file: the painting", MM.desktop() == "painting" and SIM.tiles == 1, MM.desktop())
    check("the painting is dimmed 0.55, as before", dims() == 1, dims())
    paint(nil, "original")
    check("an old file holding original: the painting", MM.desktop() == "painting" and SIM.tiles == 1)
    paint(nil, "new")
    check("an old file holding new: the title video", MM.desktop() == "video" and SIM.frames == 1 and SIM.tiles == 0, SIM.frames .. "/" .. SIM.tiles)
    check("the video is dimmed 0.55, as before", dims() == 1, dims())
    G.effects = false
    paint(nil, "video")
    check("video effects off: the painting stands in", SIM.tiles == 1 and SIM.frames == 0 and dims() == 1)
    G.effects = true
    SIM.hasVideo = false
    paint(nil, "video")
    check("no video to play: the painting stands in", SIM.tiles == 1)
    SIM.hasVideo = true
    SIM.zapLevel = 0.5
    paint(nil, "painting")
    check("the painting's lightning still comes", SIM.zap == 1)
    SIM.zapLevel = nil

    -- a pattern: the toned ground, the tiles from the tube's corner at zoom 1, no dimming, no game pictures
    G.reads = 0
    paint(nil, "classic")
    local first = log[1]
    local gr, gg, gb = D.tone(0.98, 0.56, 0.11)
    check("Classic: the ground first, over the tube, the toned container color",
        first and first[1] == "drawRect" and first[2] == L.tx and first[3] == L.ty and first[4] == L.tw and first[5] == L.th
        and first[6] == 1 and first[7] == gr and first[8] == gg and first[9] == gb)
    check("Classic: one read of the game's color", G.reads == 1, G.reads)
    check("Classic: no dimming, no painting, no video", dims() == 0 and SIM.tiles == 0 and SIM.frames == 0)
    local tiles = draws("drawTextureScaled")
    check("Classic at zoom 1: 960 x 720 takes 8 x 6 tiles of 128", tiles == 48, tiles)
    local t1 = nil
    for _, e in ipairs(log) do if e[1] == "drawTextureScaled" then t1 = e; break end end
    check("the first tile at the tube's corner, 128 px, nearest filtering",
        t1 and t1[3] == L.tx and t1[4] == L.ty and t1[5] == 128 and t1[6] == 128 and t1[2].flags == 3 and t1[2].path:find("ov_classic.png", 1, true))
    check("the tiles are clipped to the tube", draws("setStencilRect") == 1 and draws("clearStencilRect") == 1)
    ZeD.T.scale = 1.75
    local L4 = { tx = 960, ty = 360, tw = 1920, th = 1440 }
    log = {}
    MM.drawWallpaper(Pan, L4, 1000)
    tiles = draws("drawTextureScaled")
    check("Classic at 4K, UI scale 1.75: the same 48 tiles, 256 px each (a dot is 2 px)", tiles == 48, tiles)
    ZeD.T.scale = 1
    -- Slate, Accent, Solid, an art tile, the flags
    paint(nil, "slate")
    check("Slate: #5B6474, flat, no read of the game's color",
        log[1] and hex(log[1][7], log[1][8], log[1][9]) == "#5B6474" and #log == 1)
    paint(nil, "accent")
    check("Accent: the toned accent, flat", log[1] and hex(log[1][7], log[1][8], log[1][9]) == "#187865" and #log == 1)
    paint(nil, "solid")
    check("Solid: the toned container color, flat", log[1] and log[1][7] == gr and #log == 1)
    paint(nil, "topo")
    check("Topo: its own colors only (no ground), tiled", draws("drawRect") == 0 and draws("drawTextureScaled") > 0)
    paint(nil, "usa")
    check("USA: one picture over the whole tube, undimmed",
        #log == 1 and log[1][1] == "drawTextureScaled" and log[1][3] == L.tx and log[1][5] == L.tw and log[1][6] == L.th
        and log[1][2].path:find("pic_usa.png", 1, true))
    paint(nil, "kentucky")
    check("Kentucky: one picture over the whole tube", #log == 1 and log[1][2].path:find("pic_kentucky.png", 1, true))
    -- the choice kept
    MM._wall = nil
    DISK[WALL_FILE] = nil
    MM.setDesktop("camo")
    check("setDesktop keeps the id in ZeD_wallpaper.txt", DISK[WALL_FILE] == "camo\n", DISK[WALL_FILE])
    MM._wall = nil
    check("and it reads back after a restart", MM.desktop() == "camo")
    MM.setDesktop("nonsense")
    check("an id that names nothing keeps the painting", DISK[WALL_FILE] == "painting\n" and MM.desktop() == "painting", DISK[WALL_FILE])
    -- a swatch of the game's pictures: the video moves only when fresh
    log, SIM.frames = {}, 0
    MM.drawGameArt(Pan, "video", 0, 0, 64, 48, 1000, false)
    check("a Title video swatch beside the tube's video does not advance it", SIM.frames == 0 and dims() == 1)
end

-- ---------------------------------------------------------------------------
section("the Desktop window")
-- (what the window calls that the desk stub lacks)
ZeD.T.hair, ZeD.T.hover, ZeD.T.textSec, ZeD.T.accentText, ZeD.T.textOnFocus = 1, { r = 1, g = 1, b = 1, a = 0.2 }, { r = 0.5, g = 0.5, b = 0.5 }, { r = 0.9, g = 0.6, b = 0.2 }, { r = 0, g = 0, b = 0 }
ZeD.Focus = { mark = function() W.marks = (W.marks or 0) + 1; return true end }
ZeD.Atoms.frame = function(p, x, y, w, h, c, a, t) W.frames = W.frames or {}; W.frames[#W.frames + 1] = { x = x, y = y, w = w, h = h, c = c, t = t } end
ZeD.T.titleBarH = 24
-- (the stub's classes copy their parent's fields when derived: the window's draws are set on ZeD_MMWindow before the
-- window's file derives from it)
local texts = {}
ZeD_MMWindow.drawTextureScaled = function() end
ZeD_MMWindow.drawText = function(self, s, x, y, r, g, b, a, f) texts[#texts + 1] = { s = s, x = x, y = y, r = r, g = g, b = b, f = f } end
-- (the desktop's icon layer is not under test here: an empty panel stands in for it)
ZeD_MMIcons = ZeD_MMIcons or ISPanel:derive("ZeD_MMIcons")
local real = require
require = function() end
dofile(CDIR .. "ZeD_MainMenuDesktopPick.lua")
require = real
check("MM.openDesktopPick is there", type(MM.openDesktopPick) == "function")
local root = S.buildDesk()
local win = root.desktopPickWin
check("the desk builds the Desktop window", win ~= nil)
local function frame()
    texts, W.frames, W.marks = {}, {}, 0
    G.reads = 0
    S.frame()
end
MM._wall = nil
DISK[WALL_FILE or "ZeD_wallpaper.txt"] = "original\n"
MM.openDesktopPick()
frame()
check("it is the desktopPick view", MM.view == "desktopPick" and MM.activeWindow() == win, MM.view)
check("660 wide", win.width == 660, win.width)
check("at x 150, y 44 of the tube", win.x - S.L.tx == 150 and win.y - S.L.ty == 44, (win.x - S.L.tx) .. "," .. (win.y - S.L.ty))
check("it fits in the tube", win.y + win.height <= S.L.ty + S.L.th, win.height)
check("titled Desktop", win.title == "UI_ZeD_Desktop_Title", win.title)
check("one read of the game's color a frame", G.reads == 1, G.reads)
local sw, n = {}, 0
for _, s in ipairs(win._specs) do
    if s.id:sub(1, 3) == "sw:" then sw[s.id:sub(4)] = s; n = n + 1 end
end
check("25 swatches", n == 25, n)
local done = S.spec(win, "done")
check("Done in the band, the default keycap", done and done.band and done.variant == "primary")
check("the band's left line names the game's own color option", win._ask == "UI_ZeD_Desktop_Foot(UI_optionscreen_objHighlightColor)", win._ask)
check("8 columns: Painting and Video side by side, Classic under them", sw.video and sw.painting and sw.classic
    and sw.video.y == sw.painting.y and sw.video.x > sw.painting.x and sw.classic.y > sw.painting.y and sw.classic.x == sw.painting.x)
check("Patterns run to two rows: Camo starts the second", sw.camo and sw.camo.x == sw.classic.x and sw.camo.y > sw.classic.y)
check("each swatch's cell is at least 64 x 48", sw.classic and sw.classic.w >= 64 and sw.classic.h >= 48)
local rings = 0
for _, f in ipairs(W.frames) do if f.t == 2 then rings = rings + 1 end end
check("one accent ring, on the desktop in use", rings == 1, rings)
check("the help line shows the desktop in use", win:getStatusLine() == "UI_ZeD_Desktop_Help(UI_ZeD_Desktop_Painting,UI_ZeD_Desktop_Painting_Note)", win:getStatusLine())
local ringName = nil
for _, t in ipairs(texts) do if t.s == "UI_ZeD_Desktop_Painting" then ringName = t end end
check("its name is in accent-text", ringName and ringName.r == ZeD.T.accentText.r)
-- a press
sw.kentucky.fn()
frame()
check("a press sets the desktop at once", MM.desktop() == "kentucky" and DISK[WALL_FILE or "ZeD_wallpaper.txt"] == "kentucky\n")
check("the help line follows it", win:getStatusLine() == "UI_ZeD_Desktop_Help(UI_ZeD_Desktop_Kentucky,UI_ZeD_Desktop_Kentucky_Note)", win:getStatusLine())
-- the pointer over a swatch
MM.ctx.hot = "desktopPick:sw:camo"
frame()
check("the pointer's swatch fills the help line", win:getStatusLine() == "UI_ZeD_Desktop_Help(UI_ZeD_Desktop_Camo,UI_ZeD_Desktop_Camo_Note)", win:getStatusLine())
local hit = nil
for _, h in ipairs(win._hits) do if h.id == "desktopPick:sw:camo" then hit = h end end
check("each swatch has a hit for the pointer", hit ~= nil and hit.fn ~= nil)
MM.ctx.hot = nil
-- the controller
W.pad = true
win.focusId = "sw:stars"
frame()
check("the controller's focus fills the help line", win:getStatusLine() == "UI_ZeD_Desktop_Help(UI_ZeD_Desktop_Stars,UI_ZeD_Desktop_Stars_Note)", win:getStatusLine())
check("its mark is the Controller highlight", W.marks == 1, W.marks)
win:joyA()
check("A sets the focused swatch", MM.desktop() == "stars", MM.desktop())
local nav = ZeD.SpatialNav.pick({ x = sw.stars.x, y = sw.stars.y, w = sw.stars.w, h = sw.stars.h },
    (function() local c = {}; for _, s in ipairs(win._specs) do if s.id ~= "sw:stars" then c[#c + 1] = s end end; return c end)(), "down")
check("down from the Fun row is Done", nav and nav.id == "done", nav and nav.id)
check("no L3 or R3 handler", win.joyL3 == nil and win.joyR3 == nil and win.joyStick == nil)
local prompts = win:getFooterPrompts()
check("the footer: A choose, B done", prompts and prompts[1].glyph == "A" and prompts[2].glyph == "B")
check("and on a controller the focused swatch's Name: note rides last", prompts and prompts[3] == "UI_ZeD_Desktop_Help(UI_ZeD_Desktop_Stars,UI_ZeD_Desktop_Stars_Note)", prompts and tostring(prompts[3]))
win:onShow()
check("opening again starts on the desktop in use", win.focusId == "sw:stars", win.focusId)
win:close()
check("B / Done close it to the main window", MM.view == "main", MM.view)
W.pad = false
MM.openDesktopPick()
frame()
done = S.spec(win, "done")
done.fn()
check("Done closes it", MM.view == "main", MM.view)

-- ---------------------------------------------------------------------------
section("the Settings menu")
local menuSrc = string.match(SRC, 'elseif key == "settings" then(.-)elseif key == "debug"') or ""
check("one row, Desktop..., opening the window", string.find(menuSrc, 'UI_ZeD_MainMenu_Desktop"', 1, true) and string.find(menuSrc, "MM.openDesktopPick()", 1, true))
check("the wallpaper rows are gone", not string.find(menuSrc, "Wallpaper", 1, true))
local LS = readAll(CDIR .. "ZeD_LeftScreen.lua") or ""
check("the left screen still draws through MM.drawWallpaper", string.find(LS, "MM.drawWallpaper(self, L, t)", 1, true) ~= nil)

print("desktops_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
