-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenu.lua
-- ============================================================================
-- MAIN MENU + PAUSE MENU (HOOK_MAP row 26; mockup zed_main_menu_v9, approved
-- Oct 14 2026: "build it, motion is fine")
--
-- The main menu is the director's desk: one 480 x 270 pixel-art picture drawn
-- at a whole multiple (4x at 1080p, 6x at 1440p, 8x at 4K) so its pixels stay
-- square. The CRT's screen (240 x 180 of those pixels) holds the menu: a menu
-- bar and the Project Zomboid window, a ZeD window like the Character and
-- World windows. Vanilla's old painting is the monitor's wallpaper. Small life
-- on the desk: the hard disk light, the floppy light, the boombox needle, the
-- lamp, lightning in the painting. None of it does anything.
--
-- In game, Escape opens the pause window: a ZeD window over the dimmed world.
--
-- Every item runs vanilla's own handler (MainScreen.onMenuItemMouseDownMainMenu
-- with vanilla's item). Vanilla's labels stay alive, parked off-screen; the
-- hooks are in Overrides/MainMenu.lua. The screens behind the items (Load,
-- New Game, Options, Mods, ...) stay vanilla's until each has its own design.
--
-- Clicks: every panel here registers hit boxes while it draws and the update
-- pass tests the mouse against them (child panels do not get mouse events
-- reliably). Buttons act on release over the button that took the press.
-- ============================================================================

require "ISUI/ISPanel"
require "ZeD/Organisms"

ZeD = ZeD or {}
ZeD.MainMenu = ZeD.MainMenu or {}
local MM = ZeD.MainMenu

-- ---------------------------------------------------------------------------
-- THE DESK PICTURE (native pixels of desk.png)
-- ---------------------------------------------------------------------------
local TEX = "media/textures/ZeD/mainmenu/"
local DESK_W, DESK_H = 480, 270
local TUBE_X, TUBE_Y, TUBE_W, TUBE_H = 120, 30, 240, 180   -- the CRT's screen
local EDGE_ROW = 184             -- the desktop's front edge row at the picture's sides
local WALL  = { r = 0x17 / 255, g = 0x13 / 255, b = 0x10 / 255 }
local DESKC = { r = 0x7c / 255, g = 0x58 / 255, b = 0x31 / 255 }
-- lights and moving parts: { x, y, w, h } in native pixels
local HDD      = { 142, 248, 3, 2 }    -- orange hard disk light (drawn lit in the picture)
local FLOPPY   = { 300, 261, 3, 2 }    -- green floppy light (drawn lit in the picture)
local HDD_OFF    = { r = 0.29, g = 0.19, b = 0.07 }
local FLOPPY_OFF = { r = 0.17, g = 0.24, b = 0.16 }
local DIAL     = { 416, 120, 7, 10 }   -- the boombox dial without its needle (dial_clean.png)
local NEEDLE   = { 419, 121, 1, 8 }    -- the red tuning needle
local NEEDLE_C = { r = 0xb8 / 255, g = 0x33 / 255, b = 0x1f / 255 }
local LAMP     = { 60, 92, 42, 36 }    -- the lamp's glow, dimmed (lamp_dim.png)
local POWER    = { 122, 246, 10, 10 }  -- the case's power button: Quit

-- The wallpaper: vanilla's old title painting and its lightning frame, cropped to the
-- screen's 4:3 around the figures (1440 x 1080 from x 470 of the 1920 x 1080 picture).
-- Own copies: the mod blanks vanilla's media/ui/Title*.png so the engine draws no
-- painting behind vanilla's screens.
local WALLPAPER, WALLPAPER_ZAP = TEX .. "wallpaper.png", TEX .. "wallpaper_lightning.png"
local WALL_DIM = 0.55        -- the wallpaper sits back behind the windows

-- ---------------------------------------------------------------------------
-- DESIGN UNITS (1 unit = 1 px at 1080p; T.px scales them)
-- ---------------------------------------------------------------------------
local BAR_H, BAR_PAD, BAR_ITEM_PAD = 24, 6, 11
local DROP_MIN_W, DROP_ROW_H, DROP_PAD_X, DROP_PAD_Y, DROP_SEP_H = 236, 26, 16, 3, 9
local MAIN_W, PAUSE_W = 660, 360
local STACK_PAD, STACK_GAP = 12, 8
local CARD_PAD, THUMB, CARD_GAP = 10, 128, 14
local WIDE_H, BIG_PAD_X = 34, 22
local STRIP_PAD_X, STRIP_PAD_Y, STRIP_BTN_H, STRIP_BTN_PAD, STRIP_GAP = 10, 8, 30, 16, 8
local HEAD_H = 37
local WIN_TOP, WIN_TOP_FIRST = 20, 86   -- below the menu bar: with Continue / without

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
local DOT = " " .. string.char(183) .. " "

-- ---------------------------------------------------------------------------
-- STATE
-- ---------------------------------------------------------------------------
MM.ctx = MM.ctx or { open = nil, hot = nil, press = nil, wasDown = false }   -- main menu pointer
MM.root  = MM.root  or nil   -- the desk (main menu only)
MM.pause = MM.pause or nil   -- the pause window (in game only)
MM.forceGamepad = MM.forceGamepad or false   -- QA: draw focus + prompts without a controller

-- ---------------------------------------------------------------------------
-- SMALL HELPERS
-- ---------------------------------------------------------------------------
local _tex = {}
-- The desk's pixel art loads with nearest filtering so every pixel stays square at 4x / 6x / 8x;
-- the painting (smooth) loads as getTexture does, linear. Filtering is a per-texture flag fixed
-- at its first load (TextureFlags.FILTER_MIN_NEAREST 1 + FILTER_MAG_NEAREST 2; KB Q205).
local NEAREST = 3
local function tex(path, smooth)
    local t = _tex[path]
    if t == nil then
        if smooth then t = getTexture(path) else t = Texture.getSharedTexture(path, NEAREST) end
        t = t or false
        _tex[path] = t
    end
    return t or nil
end

local function rnd(a, b) return a + (b - a) * ZombRand(10000) / 10000 end

local function now() return getTimestampMs() end

local function ms() return MainScreen and MainScreen.instance end

-- A controller is driving the menu (vanilla's main-menu joypad has focus on MainScreen).
function MM.gamepad()
    if MM.forceGamepad then return true end
    local jd = JoypadState and JoypadState.getMainMenuJoypad and JoypadState.getMainMenuJoypad()
    return jd ~= nil and jd.focus == ms()
end

local _hoverSound = nil
local function hoverSound()
    local sm = getSoundManager()
    if _hoverSound then sm:stopUISound(_hoverSound) end
    _hoverSound = sm:playUISound("UIHighlightMainMenuItem")
end
local function clickSound() getSoundManager():playUISound("UIActivateMainMenuItem") end

local function textW(font, s) return ZeD.TM:MeasureStringX(font, s) end
local function fontH(font) return ZeD.TM:getFontHeight(font) end

-- A mouse click falls through to the desk only when nothing else is on top of it.
local function blocked()
    if UIManager.isModalVisible and UIManager.isModalVisible() then return true end
    local m = ms()
    if not m then return true end
    if m.termsOfServiceDialog then return true end
    if m.quitToDesktopDialog then return true end
    if m.checkSavefileModal then return true end
    if m.animPopup and m.animPopup:isReallyVisible() then return true end
    if m.infoModList and m.infoModList:isVisible() and m.infoModList:isMouseOver() then return true end
    -- vanilla screens we hand over to (Advanced sounds, the controller page) own the mouse while up
    if m.mainOptions and m.mainOptions.gameSounds and m.mainOptions.gameSounds:isVisible() then return true end
    if MM._vanillaOptions then return true end
    local ds = DebugScenarios and DebugScenarios.instance
    if ds and ds:isVisible() and ds:isMouseOver() then return true end
    return false
end

-- ---------------------------------------------------------------------------
-- LAYOUT: the desk at the largest whole multiple that covers the screen while
-- the CRT's screen stays on it; margins (ultrawide) get the wall and desktop.
-- ---------------------------------------------------------------------------
function MM.layout()
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local c = MM._layout
    if c and c.sw == sw and c.sh == sh then return c end
    local s = math.max(1, math.ceil(math.max(sw / DESK_W, sh / DESK_H) - 0.001))
    local ox, oy
    while true do
        ox = math.floor((sw - DESK_W * s) / 2)
        oy = math.floor((sh - DESK_H * s) / 2)
        local tx, ty = ox + TUBE_X * s, oy + TUBE_Y * s
        if s <= 1 or (tx >= 0 and ty >= 0 and tx + TUBE_W * s <= sw and ty + TUBE_H * s <= sh) then break end
        s = s - 1
    end
    c = { sw = sw, sh = sh, s = s, ox = ox, oy = oy,
          tx = ox + TUBE_X * s, ty = oy + TUBE_Y * s, tw = TUBE_W * s, th = TUBE_H * s }
    MM._layout = c
    return c
end

-- native rect -> screen rect
local function nat(L, r) return L.ox + r[1] * L.s, L.oy + r[2] * L.s, r[3] * L.s, r[4] * L.s end

-- ---------------------------------------------------------------------------
-- SMALL LIFE ON THE DESK
-- ---------------------------------------------------------------------------
local life = {}
MM._life = life   -- QA: the bridge can start a lightning strike (life.zap.nextAt = 0)

local function lifeTick(t)
    -- hard disk: a burst of flicker every few seconds
    local h = life.hdd
    if not h then h = { nextAt = t + rnd(1500, 4000), on = false }; life.hdd = h end
    -- a game starting: the disk works the whole time the monitor switches off
    if MM.powerOff and (not h.stopAt or h.stopAt - t < 200) then
        h.stopAt = t + 600
        if not h.flipAt then h.on = true; h.flipAt = t + rnd(30, 140) end
    end
    if h.stopAt then
        if t >= h.stopAt then h.stopAt = nil; h.on = false; h.nextAt = t + rnd(2500, 9000)
        elseif t >= h.flipAt then h.on = not h.on; h.flipAt = t + rnd(30, 140) end
    elseif t >= h.nextAt then
        h.stopAt = t + rnd(250, 1400); h.on = true; h.flipAt = t + rnd(30, 140)
    end
    -- floppy: a read now and then
    local f = life.floppy
    if not f then f = { nextAt = t + rnd(15000, 40000) }; life.floppy = f end
    if f.stopAt then
        if t >= f.stopAt then f.stopAt = nil; f.nextAt = t + rnd(25000, 60000) end
    elseif t >= f.nextAt then
        f.stopAt = t + rnd(700, 1600)
    end
    -- boombox: the needle drifts a pixel either way, slowly
    local n = life.needle
    if not n then n = { dx = 0, nextAt = t + rnd(3000, 7000) }; life.needle = n end
    if t >= n.nextAt then
        local step = (ZombRand(2) == 0) and -1 or 1
        if n.dx + step < -1 or n.dx + step > 1 then step = -step end
        n.dx = n.dx + step
        n.nextAt = t + rnd(2500, 8000)
    end
    -- lamp: a few dim / lit beats every so often (odd beats are dim)
    local l = life.lamp
    if not l then l = { nextAt = t + rnd(6000, 15000) }; life.lamp = l end
    if l.beats then
        if t >= l.beatEnd then
            l.i = l.i + 1
            if l.i > #l.beats then l.beats = nil; l.nextAt = t + rnd(9000, 26000)
            else l.beatEnd = t + l.beats[l.i] end
        end
    elseif t >= l.nextAt then
        l.beats = {}
        for i = 1, 2 + ZombRand(3) * 2 do l.beats[i] = rnd(40, 110) end
        l.i = 1; l.beatEnd = t + l.beats[1]
    end
    -- lightning in the painting: a strike, sometimes doubled
    local z = life.zap
    if not z then z = { nextAt = t + rnd(5000, 12000) }; life.zap = z end
    if z.t0 and t - z.t0 > 1200 then z.t0 = nil; z.nextAt = t + rnd(9000, 20000) end
    if not z.t0 and t >= z.nextAt then z.t0 = t; z.double = ZombRand(3) == 0 end
end

local function flash(t, peak)
    if t < 0 then return 0 end
    if t < 50 then return peak * t / 50 end
    return math.max(0, peak * (1 - (t - 50) / 600))
end
local function zapLevel(t)
    local z = life.zap
    if not (z and z.t0) then return 0 end
    local dt = t - z.t0
    local v = flash(dt, 1)
    if z.double then v = math.max(v, flash(dt - 220, 0.75)) end
    return math.min(1, v)
end

-- ---------------------------------------------------------------------------
-- DRAWING THE DESK, THE WALLPAPER, THE GLASS
-- ---------------------------------------------------------------------------
function MM.drawDesk(p, L, t)
    local s = L.s
    -- margins (a screen wider or taller than the picture): wall above the desk's edge, desktop below
    local edge = L.oy + EDGE_ROW * s
    if edge > 0 then p:drawRect(0, 0, L.sw, edge, 1, WALL.r, WALL.g, WALL.b) end
    if edge < L.sh then p:drawRect(0, edge, L.sw, L.sh - edge, 1, DESKC.r, DESKC.g, DESKC.b) end
    local desk = tex(TEX .. "desk.png")
    if desk then p:drawTextureScaledAspect(desk, L.ox, L.oy, DESK_W * s, DESK_H * s, 1, 1, 1, 1) end

    lifeTick(t)
    if not life.hdd.on then
        local x, y, w, h = nat(L, HDD)
        p:drawRect(x, y, w, h, 1, HDD_OFF.r, HDD_OFF.g, HDD_OFF.b)
    end
    if not life.floppy.stopAt then
        local x, y, w, h = nat(L, FLOPPY)
        p:drawRect(x, y, w, h, 1, FLOPPY_OFF.r, FLOPPY_OFF.g, FLOPPY_OFF.b)
    end
    if life.needle.dx ~= 0 then
        local dial = tex(TEX .. "dial_clean.png")
        if dial then
            local x, y, w, h = nat(L, DIAL)
            p:drawTextureScaledAspect(dial, x, y, w, h, 1, 1, 1, 1)
            local nx, ny, nw, nh = nat(L, NEEDLE)
            p:drawRect(nx + life.needle.dx * s, ny, nw, nh, 1, NEEDLE_C.r, NEEDLE_C.g, NEEDLE_C.b)
        end
    end
    local l = life.lamp
    if l.beats and l.i % 2 == 1 then
        local lamp = tex(TEX .. "lamp_dim.png")
        if lamp then
            local x, y, w, h = nat(L, LAMP)
            p:drawTextureScaledAspect(lamp, x, y, w, h, 1, 1, 1, 1)
        end
    end
end

-- The painting fills the tube (both are 4:3), lightning over it, then dimmed.
function MM.drawWallpaper(p, L, t)
    local tx, ty, tw, th = L.tx, L.ty, L.tw, L.th
    local a = tex(WALLPAPER, true)
    if a then p:drawTextureScaledAspect(a, tx, ty, tw, th, 1, 1, 1, 1) end
    local zap = zapLevel(t)
    if zap > 0 then
        local b = tex(WALLPAPER_ZAP, true)
        if b then p:drawTextureScaledAspect(b, tx, ty, tw, th, zap, 1, 1, 1) end
    end
    p:drawRect(tx, ty, tw, th, WALL_DIM, 0, 0, 0)
end

-- Scanlines and the tube's edges falling off into the dark, over everything on the screen.
function MM.drawGlass(p, L)
    local T = ZeD.T
    local tx, ty, tw, th = L.tx, L.ty, L.tw, L.th
    MM.drawPowerOff(p, L)   -- (a game starting: the picture collapses under the glass)
    local step, line = math.max(2, T.px(3)), math.max(1, T.px(1))
    for y = ty, ty + th - 1, step do p:drawRect(tx, y, tw, line, 0.11, 0, 0, 0) end
    local band = math.max(1, math.floor(math.min(tw, th) * 0.008))
    for i = 1, 8 do   -- soft: the menu bar along the top edge keeps its contrast
        local d = i * band
        p:drawRect(tx, ty, tw, d, 0.025, 0, 0, 0)
        p:drawRect(tx, ty + th - d, tw, d, 0.025, 0, 0, 0)
        p:drawRect(tx, ty + d, d, th - 2 * d, 0.025, 0, 0, 0)
        p:drawRect(tx + tw - d, ty + d, d, th - 2 * d, 0.025, 0, 0, 0)
    end
end

-- ---------------------------------------------------------------------------
-- STARTING A GAME: THE MONITOR SWITCHES OFF (director, Oct 15 2026)
-- The engine draws the loading screen itself, black, and no Lua draws over it (KB Q229).
-- Every vanilla start ends in forceChangeState(LoadingQueueState.new()); from the desk
-- the monitor switches off first, as a 1993 CRT does (the picture squeezes into a
-- bright line, the line into a dot, the dot fades) while the hard disk works, and then
-- the engine takes over. About half a second; nothing on the desk answers meanwhile.
-- ---------------------------------------------------------------------------
local OFF_SQUEEZE, OFF_LINE, OFF_DOT, OFF_HOLD = 170, 150, 180, 100
local OFF_TOTAL = OFF_SQUEEZE + OFF_LINE + OFF_DOT + OFF_HOLD
local PHOSPHOR = { r = 0.86, g = 0.94, b = 1.0 }

MM._origForceChangeState = MM._origForceChangeState or forceChangeState   -- (a Lua reload must not wrap the wrapper)
function forceChangeState(state, ...)
    local loading = state ~= nil and instanceof(state, "LoadingQueueState")
    local o = MM.powerOff
    if loading and o and o.state then return end   -- (a second start, Return or A again, while the first switches off)
    local m = ms()
    local root = MM.root
    if loading and not o and root and root:isVisible() and m and not m.inGame then
        MM.powerOff = { t0 = now(), state = state }
        MM.ctx.open, MM.ctx.hot, MM.ctx.press = nil, nil, nil
        return
    end
    return MM._origForceChangeState(state, ...)
end

-- (the desk's update) the switch-off done: vanilla's start goes on to the loading screen
function MM.powerOffTick()
    local o = MM.powerOff
    if not o then return end
    local t = now()
    if o.state and t - o.t0 >= OFF_TOTAL then
        local st = o.state
        o.state, o.firedAt = nil, t
        MM._origForceChangeState(st)
    elseif not o.state and o.firedAt and t - o.firedAt > 2000 then
        MM.powerOff = nil   -- still on the menu (the start did not go through): the monitor comes back
    end
end

function MM.drawPowerOff(p, L)
    local o = MM.powerOff
    if not o then return end
    local dt = now() - o.t0
    local tx, ty, tw, th = L.tx, L.ty, L.tw, L.th
    local px = math.max(1, L.s)   -- one pixel of the desk picture
    local cx, cy = tx + tw / 2, ty + th / 2
    local c = PHOSPHOR
    if dt < OFF_SQUEEZE then
        -- the picture squeezes toward the middle, brightening as it goes
        local k = dt / OFF_SQUEEZE
        local bh = math.max(px, math.floor(th * (1 - k * k)))
        local by = math.floor(cy - bh / 2)
        p:drawRect(tx, ty, tw, by - ty, 1, 0, 0, 0)
        p:drawRect(tx, by + bh, tw, ty + th - by - bh, 1, 0, 0, 0)
        p:drawRect(tx, by, tw, bh, 0.15 + 0.75 * k, c.r, c.g, c.b)
        return
    end
    p:drawRect(tx, ty, tw, th, 1, 0, 0, 0)
    local d = dt - OFF_SQUEEZE
    if d < OFF_LINE then
        -- the line draws in from both ends
        local k = d / OFF_LINE
        local lw = math.max(px * 2, math.floor(tw * (1 - k * k)))
        local lx = math.floor(cx - lw / 2)
        p:drawRect(lx, math.floor(cy - px * 1.5), lw, px * 3, 0.3, c.r, c.g, c.b)
        p:drawRect(lx, math.floor(cy - px / 2), lw, px, 1, c.r, c.g, c.b)
        return
    end
    d = d - OFF_LINE
    if d < OFF_DOT then
        -- the dot fades
        local a = 1 - d / OFF_DOT
        local ds = px * 2
        p:drawRect(math.floor(cx - ds * 1.5), math.floor(cy - ds * 1.5), ds * 3, ds * 3, a * 0.3, c.r, c.g, c.b)
        p:drawRect(math.floor(cx - ds / 2), math.floor(cy - ds / 2), ds, ds, a, c.r, c.g, c.b)
    end
end

-- ---------------------------------------------------------------------------
-- WHAT THE MENU SHOWS (read from vanilla)
-- ---------------------------------------------------------------------------
function MM.modeName(mode)
    mode = tostring(mode or "")
    return getTextOrNull("IGUI_Gametime_" .. mode) or mode
end

-- A save folder named by date (vanilla's default) reads "<Mode>, <Mon> <D>".
-- The game's own copies keep their tag: "..._crash" -> "Sandbox, Oct 12 (crash)".
function MM.saveTitle(name, mode)
    name = tostring(name or "")
    local _, mo, d, rest = name:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)_%d%d%-%d%d%-%d%d(.*)$")
    if mo and MONTHS[tonumber(mo)] then
        local t = MM.modeName(mode) .. ", " .. MONTHS[tonumber(mo)] .. " " .. tonumber(d)
        local tag = rest and rest:match("^_(.+)$")
        if tag then t = t .. " (" .. tag:gsub("_", " ") .. ")" elseif rest and rest ~= "" then t = t .. rest end
        return t
    end
    return name
end

-- A save's map list ("Brandenburg, KY;...;Muldraugh, KY"): the whole county reads as
-- Knox Country (vanilla's own name for it); a single map reads as itself.
function MM.mapText(mapName)
    local list = tostring(mapName or "Muldraugh, KY")
    if list:find(";") and list:find("Muldraugh, KY", 1, true) then return "Knox Country" end
    return list:match("^[^;]+") or list
end

local function clock12(h, m)
    local h12 = h % 12
    if h12 == 0 then h12 = 12 end
    return string.format("%d:%02d %s", h12, m, h >= 12 and "PM" or "AM")
end

-- getLastPlayedDate's text -> "Oct 14 2026, 7:52 PM" (unknown shapes pass through)
function MM.playedText(raw)
    raw = tostring(raw or "")
    local y, mo, d, h, mi = raw:match("(%d%d%d%d)[%-/%.](%d%d?)[%-/%.](%d%d?)[ T_](%d%d?)[:%-](%d%d)")
    if not y then
        d, mo, y, h, mi = raw:match("(%d%d?)[%-/%.](%d%d?)[%-/%.](%d%d%d%d)[ T_](%d%d?)[:%-](%d%d)")
    end
    if y and MONTHS[tonumber(mo)] then
        return MONTHS[tonumber(mo)] .. " " .. tonumber(d) .. " " .. y .. ", " .. clock12(tonumber(h), tonumber(mi))
    end
    return raw
end

-- The latest save (vanilla's Continue), read once each time the menu shows.
function MM.refresh()
    MM._cont = false
    local m = ms()
    if not (m and not m.inGame and m.latestSaveOption and m.latestSaveOption:isVisible()) then return end
    local mode, world = MainScreen.latestSaveGameMode, MainScreen.latestSaveWorld
    if not (mode and world) then return end
    local key = mode .. getFileSeparator() .. world
    local ok, info = pcall(getSaveInfo, key)
    if not ok or type(info) ~= "table" then info = {} end
    local c = { key = key }
    c.title = MM.saveTitle(info.saveName or world, info.gameMode or mode)
    local who = nil
    if info.players and info.players[1] then who = info.players[1].name end
    c.who = who
    c.dead = info.playerAlive == false
    c.where = MM.modeName(info.gameMode or mode) .. DOT .. MM.mapText(info.mapName)
    local okP, played = pcall(getLastPlayedDate, key)
    c.played = okP and played and ("Last played " .. MM.playedText(played)) or nil
    local okT, thumb = pcall(getTextureFromSaveDir, "thumb.png", key)
    c.thumb = okT and thumb or nil
    MM._cont = c
end
function MM.continueInfo() return MM._cont or nil end

function MM.hasSaves() local m = ms(); if m and m.hasSaveFiles then return true end; return false end

function MM.modCount()
    local ok, n = pcall(function() return getActivatedMods():size() end)
    return ok and n or 0
end

function MM.version()
    if not MM._version then
        local ok, v = pcall(function() return getCore():getVersion() end)
        MM._version = ok and (tostring(v or ""):match("^(%S+)") or "") or ""   -- "42.21.0 4a0e9546ec" -> "42.21.0"
    end
    return MM._version
end

local _clock = { at = -1, s = "", fmt = nil }
function MM.clock()
    local t = now()
    if t - _clock.at < 1000 then return _clock.s end
    _clock.at = t
    local ok24, v24 = pcall(function() return getCore():getOptionClock24Hour() end)
    local fmt = (ok24 and v24 == false) and "h:mm a" or "HH:mm"
    local ok, s = pcall(function()
        if _clock.fmt ~= fmt then _clock.fmt = fmt; _clock.sdf = SimpleDateFormat.new(fmt, Locale.ENGLISH) end
        return _clock.sdf:format(Calendar.getInstance():getTime())
    end)
    _clock.s = ok and tostring(s) or ""
    return _clock.s
end

-- in game: the character, the save, the day and time
function MM.pauseInfo()
    local p = getSpecificPlayer(0)
    local name = "Paused"
    if p then
        local ok, n = pcall(function() local d = p:getDescriptor(); return d:getForename() .. " " .. d:getSurname() end)
        if ok and n then name = n end
    end
    local save = ""
    if isClient() then
        local ok, s = pcall(getServerName)
        save = ok and tostring(s or "") or ""
    else
        local ok, s = pcall(function() return MM.saveTitle(getWorld():getWorld(), getWorld():getGameMode()) end)
        save = ok and s or ""
    end
    local gt = getGameTime()
    local day = math.floor((gt:getWorldAgeHours() or 0) / 24) + 1
    local hour, min = gt:getHour(), gt:getMinutes()
    local ok24, v24 = pcall(function() return getCore():getOptionClock24Hour() end)
    local tstr = (ok24 and v24 == false) and clock12(hour, min) or string.format("%02d:%02d", hour, min)
    return { name = name, save = save, when = "Day " .. day .. DOT .. tstr }
end

-- ---------------------------------------------------------------------------
-- ACTIONS (each runs vanilla's handler with vanilla's item)
-- ---------------------------------------------------------------------------
local function fire(field)
    local m = ms()
    local item = m and m[field]
    if not item then return end
    MM.ctx.open = nil
    MainScreen.onMenuItemMouseDownMainMenu(item, 0, 0)
end

MM.act = {
    continue  = function() fire("latestSaveOption") end,
    -- New Game and Load Game open on the monitor (ZeD_MainMenuSaves.lua); vanilla's
    -- SOLO item also copies the default mods into the new game's list
    newGame   = function()
        MM.ctx.open = nil
        local m = ms()
        if not m or m.delay > 0 then return end
        clickSound()
        pcall(function() ActiveMods.getById("currentGame"):copyFrom(ActiveMods.getById("default")) end)
        MM.showView("newgame")
    end,
    load      = function()
        MM.ctx.open = nil
        local m = ms()
        if not m or m.delay > 0 or not MM.hasSaves() then return end
        clickSound()
        MM.showView("load")
    end,
    join      = function() MM.ctx.open = nil; clickSound(); MM.showView("join") end,   -- ZeD_MainMenuJoin.lua (vanilla's item hides the menu after its screen shows)
    host      = function()   -- ZeD_MainMenuHost.lua: vanilla's COOP item without its trailing menu hide
        MM.ctx.open = nil; clickSound()
        local c = ms() and ms().onlineCoopScreen
        if c then c:aboutToShow(); c:setVisible(true, JoypadState.getMainMenuJoypad()) end
    end,
    tutorial  = function() fire("tutorialOption") end,
    options   = function() MM.openOptions() end,   -- ZeD_MainMenuOptions.lua (main menu and in game)
    mods      = function() MM.openMods() end,   -- the mod manager on the monitor (ZeD_MainMenuMods.lua)
    workshop  = function() fire("workshopOption") end,
    credits   = function() MM.ctx.open = nil; MM.clickSound(); MM.showView("credits") end,   -- ZeD_MainMenuCredits.lua (vanilla's item hides the menu after opening its screen)
    tos       = function() MM.ctx.open = nil; local m = ms(); if m then m:onClickTermsOfService() end end,
    reportBug = function() MM.ctx.open = nil; local m = ms(); if m then m:onClickReportBug() end end,
    resetLua  = function() getCore():ResetLua("default", "Force") end,
    scenarios = function()
        MM.ctx.open = nil
        local ds, m = DebugScenarios and DebugScenarios.instance, ms()
        if not (ds and m) then return end
        if ds:isVisible() then ds:setVisible(false)
        else m:removeChild(ds); m:addChild(ds); ds:setVisible(true) end   -- re-added last: above the desk
    end,
    -- quitting asks in the window's action strip
    askQuit   = function() MM.ctx.open = nil; local w = MM.root and MM.root.win; if w then w:setConfirm(true) end end,
    quit      = function()
        if isQuitCooldown() then return end
        local m = ms(); if m then m:quitToDesktop() end
    end,
    -- in game
    resume    = function() fire("returnOption") end,
    players   = function() fire("scoreOption") end,
    invite    = function() fire("inviteOption") end,
    modList   = function() local m = ms(); if m then m:onClickModList() end end,
    saveQuit  = function() fire("exitOption") end,
}

-- ---------------------------------------------------------------------------
-- THE MENU BAR'S MENUS
-- ---------------------------------------------------------------------------
function MM.menus()
    local t = {
        { key = "zed", logo = true },
        { key = "file", title = "File" },
        { key = "mp", title = "Multiplayer" },
        { key = "settings", title = "Settings" },
    }
    if getDebug() then t[#t + 1] = { key = "debug", title = "Debug" } end
    return t
end

function MM.menuItems(key)
    local A, m = MM.act, ms()
    if key == "zed" then
        return { { about = true }, "-",
                 { text = "Credits", fn = A.credits },
                 { text = "Terms of Service", fn = A.tos },
                 { text = "Report a Bug", fn = A.reportBug } }
    elseif key == "file" then
        return { { text = "Continue", fn = A.continue, disabled = not MM.continueInfo() },
                 { text = "New Game", fn = A.newGame },
                 { text = "Load Game", fn = A.load, disabled = not MM.hasSaves() },
                 { text = "Tutorial", fn = A.tutorial },
                 "-",
                 { text = "Quit", fn = A.askQuit } }
    elseif key == "mp" then
        return { { text = "Join a Server", fn = A.join }, { text = "Host a Game", fn = A.host } }
    elseif key == "settings" then
        local t = { { text = "Options", fn = A.options }, { text = "Mods (" .. MM.modCount() .. " on)", fn = A.mods } }
        if m and m.workshopOption then t[#t + 1] = { text = "Workshop", fn = A.workshop } end
        return t
    elseif key == "debug" then
        local t = { { text = "Reset Lua", fn = A.resetLua } }
        if DebugScenarios and DebugScenarios.instance then t[#t + 1] = { text = "Scenarios", fn = A.scenarios } end
        return t
    end
    return {}
end

-- ---------------------------------------------------------------------------
-- POINTER: hover, press, release over the hit boxes the panels registered
-- (panels top-first). A hit: { id, x, y, w, h (screen px), fn, disabled,
-- menu = key (a menu title), inDrop (a dropdown row), sound (hover sound) }.
-- ---------------------------------------------------------------------------
local function hitAt(panels, mx, my)
    for _, p in ipairs(panels) do
        if p and p:isVisible() and p._hits then
            for i = #p._hits, 1, -1 do
                local h = p._hits[i]
                if mx >= h.x and mx < h.x + h.w and my >= h.y and my < h.y + h.h then return h end
            end
        end
    end
    return nil
end

function MM.pointer(ctx, panels)
    local down = isMouseButtonDown(0)
    if blocked() then ctx.hot = nil; ctx.press = nil; ctx.dragHit = nil; ctx.wasDown = down; return end
    local h = hitAt(panels, getMouseX(), getMouseY())
    if h and h.disabled then h = nil end
    local id = h and h.id or nil
    if id ~= ctx.hot then
        ctx.hot = id
        if h and h.sound then hoverSound() end
    end
    -- a menu is open: pointing at another title switches to it
    if ctx.open and h and h.menu and h.menu ~= ctx.open then ctx.open = h.menu end
    -- a held press on a draggable box (a slider, a scroll thumb) follows the mouse until release
    if down and ctx.dragHit then ctx.dragHit.drag(getMouseX(), getMouseY()) end
    if not down and ctx.dragHit then ctx.dragHit = nil end
    if down and not ctx.wasDown then
        ctx.press, ctx.pressMenu = id, h and h.menu or nil
        if h and h.drag then ctx.dragHit = h; h.drag(getMouseX(), getMouseY()) end
        if h and h.menu then
            if ctx.open == h.menu then ctx.open = nil else ctx.open = h.menu end   -- the open menu's title closes it
        elseif ctx.open and not (h and h.inDrop) then
            ctx.open = nil          -- a click outside the open menu only closes it
            ctx.press = nil
        end
    elseif not down and ctx.wasDown then
        -- act on release over the press's own box; a menu row also takes a press-drag from its title
        if h and h.fn and (ctx.press == id or (h.inDrop and ctx.pressMenu)) then
            if MM.debugFire then print("[ZeD.MM] fire " .. tostring(id) .. " press=" .. tostring(ctx.press) .. " t=" .. now()) end
            if h.inDrop then ctx.open = nil end   -- a picked row closes its menu (pop-ups too)
            h.fn()
        end
        ctx.press, ctx.pressMenu = nil, nil
    end
    ctx.wasDown = down
end

-- ---------------------------------------------------------------------------
-- BUTTON DRAWING (Molecules.drawButton; hover 0.22 / controller focus 0.55
-- accent fill under it; a disabled button is drawn faded)
-- ---------------------------------------------------------------------------
local function drawBtn(p, b, hot, focus, pressed)
    local T = ZeD.T
    if b.disabled then
        local sb, st = T.borderS, T.text
        T.borderS = ZeD.colorAlpha(sb, (sb.a or 1) * 0.38)
        T.text    = ZeD.colorAlpha(st, (st.a or 1) * 0.38)
        ZeD.Molecules.drawButton(p, b.x, b.y, b.w, b.h, b.text, "default", false)
        T.borderS, T.text = sb, st
        return
    end
    local ac = T.accent
    if focus then ZeD.Atoms.fillRounded(p, b.x, b.y, b.w, b.h, ac.r, ac.g, ac.b, 0.55)
    elseif hot then ZeD.Atoms.fillRounded(p, b.x, b.y, b.w, b.h, ac.r, ac.g, ac.b, 0.22) end
    ZeD.Molecules.drawButton(p, b.x, b.y, b.w, b.h, b.text, b.variant, pressed)
end

-- The ZeD mark: a square cut into a Z (top bar, bottom bar, the diagonal between).
local function drawMark(p, x, y, size, c)
    local bar = math.max(1, math.floor(size * 0.22 + 0.5))
    p:drawRect(x, y, size, bar, c.a or 1, c.r, c.g, c.b)
    p:drawRect(x, y + size - bar, size, bar, c.a or 1, c.r, c.g, c.b)
    local sw = math.max(1, math.floor(size * 0.32 + 0.5))
    for row = bar, size - bar - 1 do
        local f = (row + 0.5 - 0.22 * size) / (0.56 * size)
        local xl = math.floor((0.68 - 0.68 * f) * size + 0.5)
        p:drawRect(x + xl, y + row, sw, 1, c.a or 1, c.r, c.g, c.b)
    end
end

-- ============================================================================
-- THE DESK (full screen, a child of MainScreen; main menu only)
-- ============================================================================
ZeD_MMDesk = ISPanel:derive("ZeD_MMDesk")

function ZeD_MMDesk:new()
    local o = ISPanel:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight())
    setmetatable(o, self)
    self.__index = self
    o.background = false
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o._hits = {}
    return o
end

function ZeD_MMDesk:createChildren()
    self.bar = ZeD_MMBar:new()
    self.bar:initialise()
    self:addChild(self.bar)
    self.win = ZeD_MMWindow:new("main")
    self.win:initialise()
    self:addChild(self.win)
    -- Load Game and New Game on the monitor (ZeD_MainMenuSaves.lua); one window shows at a time
    self.loadWin = ZeD_MMLoad:new()
    self.loadWin:initialise()
    self:addChild(self.loadWin)
    self.newWin = ZeD_MMNewGame:new()
    self.newWin:initialise()
    self:addChild(self.newWin)
    self.modsWin = ZeD_MMMods:new()
    self.modsWin:initialise()
    self:addChild(self.modsWin)
    self.optsWin = ZeD_MMOptions:new(false)
    self.optsWin:initialise()
    self:addChild(self.optsWin)
    -- the later screens register themselves (MM.addView): map / spawn, ...
    for _, v in ipairs(MM.views) do
        local w = v.make()
        w:initialise()
        self:addChild(w)
        self[v.field] = w
    end
    self.drop = ZeD_MMDrop:new()
    self.drop:initialise()
    self:addChild(self.drop)
    self.drop:setVisible(false)
    self.glass = ZeD_MMGlass:new()   -- added last: drawn over everything on the screen
    self.glass:initialise()
    self:addChild(self.glass)
end

function ZeD_MMDesk:prerender()
    local L = MM.layout()
    if self.width ~= L.sw or self.height ~= L.sh then self:setWidth(L.sw); self:setHeight(L.sh) end
    -- the root scale follows the screen at the menu too (no OnTick here)
    local S = ZeD.Scale
    if S and S.refresh then
        self._scaleTick = (self._scaleTick or 0) + 1
        if self._scaleTick >= 30 then
            self._scaleTick = 0
            local r = S.refresh()
            if S._appliedRoot and math.abs(S._appliedRoot - r) > 0.001 then ZeD.applyTheme() end
        end
    end
    local t = now()
    MM.drawDesk(self, L, t)
    MM.drawWallpaper(self, L, t)
    -- the power button: Quit
    self._hits = {}
    local px, py, pw, ph = nat(L, POWER)
    self._hits[1] = { id = "power", x = px, y = py, w = pw, h = ph, fn = MM.act.askQuit }
end

function ZeD_MMDesk:update()
    ISPanel.update(self)
    -- the view's window shows (hidden panels get no update of their own, so this lives here)
    local v = MM.view or "main"
    if self.win:isVisible() ~= (v == "main") then self.win:setVisible(v == "main") end
    if self.loadWin:isVisible() ~= (v == "load") then self.loadWin:setVisible(v == "load") end
    if self.newWin:isVisible() ~= (v == "newgame") then self.newWin:setVisible(v == "newgame") end
    if self.modsWin:isVisible() ~= (v == "mods") then self.modsWin:setVisible(v == "mods") end
    if self.optsWin:isVisible() ~= (v == "options") then self.optsWin:setVisible(v == "options") end
    for _, rv in ipairs(MM.views) do
        local w = self[rv.field]
        if w and w:isVisible() ~= (v == rv.view) then w:setVisible(v == rv.view) end
    end
    if MM.powerOff then
        MM.powerOffTick()   -- a game starting: nothing answers until the engine takes over
    else
        MM.pointer(MM.ctx, { self.drop, MM.activeWindow(), self.bar, self })
    end
    -- the pull-down shows while a menu is open
    local open = MM.ctx.open ~= nil
    if self.drop and self.drop:isVisible() ~= open then self.drop:setVisible(open) end
end

-- ============================================================================
-- THE MENU BAR (top of the screen)
-- ============================================================================
ZeD_MMBar = ISPanel:derive("ZeD_MMBar")

function ZeD_MMBar:new()
    local o = ISPanel:new(0, 0, 100, 24)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o._hits = {}
    o.pos = {}
    return o
end

function ZeD_MMBar:prerender()
    local T, L = ZeD.T, MM.layout()
    local h = T.px(BAR_H)
    if self.x ~= L.tx or self.y ~= L.ty then self:setX(L.tx); self:setY(L.ty) end
    if self.width ~= L.tw or self.height ~= h then self:setWidth(L.tw); self:setHeight(h) end
    local w = self.width
    local s2, bs = T.surf2, T.borderS
    self:drawRect(0, 0, w, h, 1, s2.r, s2.g, s2.b)
    self:drawRect(0, h - T.px(1), w, T.px(1), bs.a, bs.r, bs.g, bs.b)

    self._hits = {}
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local x = T.px(BAR_PAD)
    local font, logoFont = T.fontF2, T.fontF1
    local markSz = T.px(12)
    for _, m in ipairs(MM.menus()) do
        local tw = m.logo and (markSz + T.px(6) + textW(logoFont, "ZeD")) or textW(font, m.title)
        local iw = tw + T.px(BAR_ITEM_PAD) * 2
        local open = MM.ctx.open == m.key
        if open then self:drawRect(x, 0, iw, h - T.px(1), 1, T.accent.r, T.accent.g, T.accent.b) end
        local tx = x + T.px(BAR_ITEM_PAD)
        if m.logo then
            local c = open and T.textOnAccent or T.accent
            drawMark(self, tx, math.floor((h - markSz) / 2), markSz, c)
            self:drawText("ZeD", tx + markSz + T.px(6), math.floor((h - fontH(logoFont)) / 2), c.r, c.g, c.b, c.a or 1, logoFont)
        else
            local c = open and T.textOnAccent or T.text
            self:drawText(m.title, tx, math.floor((h - fontH(font)) / 2), c.r, c.g, c.b, c.a or 1, font)
        end
        self.pos[m.key] = { x = x, w = iw }
        self._hits[#self._hits + 1] = { id = "menu:" .. m.key, x = ax + x, y = ay, w = iw, h = h, menu = m.key }
        x = x + iw
    end
    -- right: the build and the clock
    local right = "Build " .. MM.version() .. DOT .. MM.clock()
    local f3 = T.fontF3
    local d = T.textDim
    self:drawText(right, w - T.px(12) - textW(f3, right), math.floor((h - fontH(f3)) / 2), d.r, d.g, d.b, d.a or 1, f3)
end

-- ============================================================================
-- THE OPEN MENU (a pull-down under its title)
-- ============================================================================
ZeD_MMDrop = ISPanel:derive("ZeD_MMDrop")

function ZeD_MMDrop:new()
    local o = ISPanel:new(0, 0, 10, 10)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o._hits = {}
    return o
end

local function aboutLines()
    return { { "ZeD-UI", "head" }, { "A total UI overhaul for Project Zomboid", "dim" }, { "Build " .. MM.version(), "dim" } }
end

-- The items of the open menu: a menu-bar title's, or a pop-up a window opened at a button
-- (MM.openPopup: MORE, PLAYING AS). Returns items plus the bar position or the pop-up.
function MM.openItems()
    local key = MM.ctx.open
    if not key then return nil end
    local bar = MM.root and MM.root.bar
    local pos = bar and bar.pos[key]
    if pos then return MM.menuItems(key), pos, nil end
    local pop = MM.popup
    if pop and pop.key == key then return pop.items, nil, pop end
    return nil
end

-- Opens a pop-up menu at a button: anchor = { x, y, w, h } in screen px; up = above it, right-aligned.
function MM.openPopup(key, items, anchor, up)
    MM.popup = { key = key, items = items, anchor = anchor, up = up }
    MM.ctx.open = key
    MM.ctx.dropFocus = 1
    MM.ctx.dropScroll = 0
end

-- The live rows of the open menu (the controller walks these).
function MM.dropLive()
    local items = MM.openItems()
    local live = {}
    for _, it in ipairs(items or {}) do
        if type(it) == "table" and it.text and not it.disabled then live[#live + 1] = it end
    end
    return live
end

function ZeD_MMDrop:prerender()
    self._hits = {}
    local key = MM.ctx.open
    local items, pos, pop = MM.openItems()
    if not items then return end
    local bar = MM.root and MM.root.bar
    local T = ZeD.T
    local font, f1, f3 = T.fontF2, T.fontF1, T.fontF3
    local rowH, padX, padY, sepH = T.px(DROP_ROW_H), T.px(DROP_PAD_X), T.px(DROP_PAD_Y), T.px(DROP_SEP_H)
    local lineH = T.px(17)
    -- size
    local w, h = T.px(DROP_MIN_W), padY * 2
    for _, it in ipairs(items) do
        if it == "-" then h = h + sepH
        elseif it.about then
            for _, l in ipairs(aboutLines()) do w = math.max(w, textW(l[2] == "head" and f1 or f3, l[1]) + padX * 2) end
            h = h + T.px(8) * 2 + lineH * 3
        else
            w = math.max(w, textW(font, it.text) + padX * 2)
            h = h + rowH
        end
    end
    local step = T.px(3)
    local x, y
    if pos then
        x, y = bar.x + pos.x, bar.y + bar.height
    else
        local an = pop.anchor
        w = math.max(w, an.w)
        if pop.up then x, y = an.x + an.w - w, an.y - h - T.px(2)   -- above the button, right edges lined up
        else x, y = an.x, an.y + an.h + T.px(2) end                  -- below it
    end
    -- room: the monitor's screen at the menu, the game screen in game. A list that does not
    -- fit below its box opens above it when there is more room there, else it is cut and scrolls.
    local full = h
    if not pos then
        local L = MM.layout()
        local m = ms()
        local inGame = m and m.inGame
        local limTop = inGame and T.px(8) or (L.ty + T.px(4))
        local limBot = inGame and (getCore():getScreenHeight() - T.px(8)) or (L.ty + L.th - T.px(4))
        local an = pop.anchor
        if not pop.up and y + h > limBot then
            local below, above = limBot - y, an.y - T.px(2) - limTop
            if above >= h then y = an.y - h - T.px(2)
            elseif above > below then h = above; y = limTop
            else h = math.max(rowH * 3, below) end
        elseif pop.up and y < limTop then
            h = math.max(rowH * 3, an.y - T.px(2) - limTop); y = limTop
        end
    end
    local scrollMax = math.max(0, full - h)
    MM.ctx.dropScrollMax = scrollMax
    MM.ctx.dropScroll = math.max(0, math.min(MM.ctx.dropScroll or 0, scrollMax))
    local off = MM.ctx.dropScroll
    if self.x ~= x or self.y ~= y then self:setX(x); self:setY(y) end
    if self.width ~= w + step or self.height ~= h + step then self:setWidth(w + step); self:setHeight(h + step) end

    local s1, bs = T.surf1, T.borderS
    ZeD.Atoms.drawSteppedShadow(self, 0, 0, w, h, { r = 0, g = 0, b = 0, a = 0.55 })
    self:drawRect(0, 0, w, h, 1, s1.r, s1.g, s1.b)
    self:drawRectBorder(0, 0, w, h, bs.a, bs.r, bs.g, bs.b)

    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local gp = MM.gamepad()
    local cy = padY - off
    local live = 0
    if scrollMax > 0 then self:setStencilRect(T.px(1), T.px(1), w - T.px(2), h - T.px(2)) end
    for i, it in ipairs(items) do
        if it == "-" then
            self:drawRect(0, cy + math.floor((sepH - T.px(1)) / 2), w, T.px(1), bs.a, bs.r, bs.g, bs.b)
            cy = cy + sepH
        elseif it.about then
            local ly = cy + T.px(8)
            for _, l in ipairs(aboutLines()) do
                local f = l[2] == "head" and f1 or f3
                local c = l[2] == "head" and T.accent or T.textDim
                self:drawText(l[1], padX, ly + math.floor((lineH - fontH(f)) / 2), c.r, c.g, c.b, c.a or 1, f)
                ly = ly + lineH
            end
            cy = cy + T.px(8) * 2 + lineH * 3
        else
            local id = "drop:" .. key .. ":" .. i
            if not it.disabled then live = live + 1 end
            local lit = false   -- the pointer's row, or the controller's (MM.ctx.dropFocus counts live rows)
            if not it.disabled then
                if gp then lit = (live == (MM.ctx.dropFocus or 1)) else lit = (MM.ctx.hot == id) end
            end
            if lit then self:drawRect(T.px(1), cy, w - T.px(2), rowH, 0.55, T.accent.r, T.accent.g, T.accent.b) end
            -- the controller's row stays in view
            if lit and gp and scrollMax > 0 then
                if cy < padY then MM.ctx.dropScroll = off - (padY - cy)
                elseif cy + rowH > h - padY then MM.ctx.dropScroll = off + (cy + rowH - (h - padY)) end
            end
            local c = T.text
            local a = (c.a or 1) * (it.disabled and 0.38 or 1)
            self:drawText(it.text, padX, cy + math.floor((rowH - fontH(font)) / 2), c.r, c.g, c.b, a, font)
            local top, bot = math.max(cy, 0), math.min(cy + rowH, h)
            if bot > top then
                self._hits[#self._hits + 1] = { id = id, x = ax, y = ay + top, w = w, h = bot - top, fn = it.fn, disabled = it.disabled, inDrop = true }
            end
            cy = cy + rowH
        end
    end
    if scrollMax > 0 then
        self:clearStencilRect()
        -- a small scroll bar on the right edge: there is more
        local sbW = T.px(4)
        local th = math.max(T.px(16), math.floor(h * h / full))
        local ty = math.floor((h - th) * off / scrollMax)
        self:drawRect(w - sbW - T.px(2), ty, sbW, th, 0.6, T.textDim.r, T.textDim.g, T.textDim.b)
    end
end

-- the wheel over an open pull-down scrolls it
function MM.dropWheel(del)
    if not MM.ctx.open or (MM.ctx.dropScrollMax or 0) <= 0 then return false end
    MM.ctx.dropScroll = (MM.ctx.dropScroll or 0) + del * ZeD.T.px(DROP_ROW_H) * 2
    return true
end

-- ============================================================================
-- THE GLASS (scanlines and the tube's edge) and the power button's label
-- ============================================================================
ZeD_MMGlass = ISPanel:derive("ZeD_MMGlass")

function ZeD_MMGlass:new()
    local o = ISPanel:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight())
    setmetatable(o, self)
    self.__index = self
    o.background = false
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    return o
end

function ZeD_MMGlass:prerender()
    local L = MM.layout()
    if self.width ~= L.sw or self.height ~= L.sh then self:setWidth(L.sw); self:setHeight(L.sh) end
    MM.drawGlass(self, L)
    if MM.ctx.hot == "power" then
        local T = ZeD.T
        local px, py, pw = nat(L, POWER)
        local f = T.fontF3
        local label = "Quit"
        local bw, bh = textW(f, label) + T.px(16), fontH(f) + T.px(8)
        local bx, by = math.floor(px + pw / 2 - bw / 2), py - T.px(6) - bh
        local s1, bs, c = T.surf1, T.borderS, T.text
        ZeD.Atoms.drawSteppedShadow(self, bx, by, bw, bh, { r = 0, g = 0, b = 0, a = 0.55 })
        self:drawRect(bx, by, bw, bh, 1, s1.r, s1.g, s1.b)
        self:drawRectBorder(bx, by, bw, bh, bs.a, bs.r, bs.g, bs.b)
        self:drawText(label, bx + T.px(8), by + T.px(4), c.r, c.g, c.b, c.a or 1, f)
    end
end

-- ============================================================================
-- THE WINDOWS: "main" (the Project Zomboid window on the monitor) and "pause"
-- (in game). A ZeD window frame (title bar, close box, the theme footer) that
-- does not move or resize; the body, the action strip and the confirmations
-- are drawn here.
-- ============================================================================
ZeD_MMWindow = ZeD_Window:derive("ZeD_MMWindow")

function ZeD_MMWindow:new(kind)
    local o = ZeD_Window.new(self, 0, 0, 400, 300, "Project Zomboid")
    o.kind = kind
    o.resizable = false
    o.themeFooter = true
    o.noResetControl = (kind == "main")   -- R resets the Character / World windows: in game only
    o.globalAccentControl = true
    o.confirm = false
    o.focusId = nil
    o._specs = {}
    o._hits = {}
    o.ctx = { hot = nil, press = nil, wasDown = false }   -- the pause window's own pointer
    return o
end

-- the pointer context this window reads hover from
function ZeD_MMWindow:pctx() if self.kind == "pause" then return self.ctx end; return MM.ctx end   -- the desk's windows share the menu bar's pointer

function ZeD_MMWindow:setConfirm(on)
    if self.confirm == on then return end
    self.confirm = on
    clickSound()
    -- the controller lands on the question's answer, and back on the button that asked
    if on then self.focusId = "confirm:yes" else self.focusId = (self.kind == "main") and "quit" or "quitDesktop" end
end

-- Builds this frame's buttons and the window's size. Each spec:
-- { id, text, variant, x, y, w, h (window px), fn, row, col, disabled }
function ZeD_MMWindow:build()
    local T = ZeD.T
    local specs = {}
    local function add(s) specs[#specs + 1] = s; return s end
    local f3 = T.fontF3
    local pad, gap = T.px(STACK_PAD), T.px(STACK_GAP)
    local tb = T.titleBarH
    local w
    local L = (self.kind == "main") and MM.layout() or nil
    if self.kind == "main" then
        w = math.min(T.px(MAIN_W), L.tw - T.px(24))
    else
        w = T.px(PAUSE_W)
    end
    local y = tb
    local row = 0
    local A = MM.act
    local m = ms()
    self._card, self._head = nil, nil

    if self.kind == "main" then
        local cont = MM.continueInfo()
        y = y + pad
        if cont then
            local cardH = T.px(THUMB) + T.px(CARD_PAD) * 2
            self._card = { x = pad, y = y, w = w - pad * 2, h = cardH, info = cont }
            local bw = textW(f3, "CONTINUE") + T.px(BIG_PAD_X) * 2
            row = row + 1
            add({ id = "continue", text = "CONTINUE", variant = "primary", fn = A.continue, row = row, col = 1,
                  x = pad + T.px(CARD_PAD) + T.px(THUMB) + T.px(CARD_GAP), y = y + T.px(CARD_PAD) + T.px(THUMB) - T.px(WIDE_H),
                  w = bw, h = T.px(WIDE_H) })
            y = y + cardH + gap
        end
        local list = {
            { "newgame",  "NEW GAME",      A.newGame },
            { "load",     "LOAD GAME",     A.load, not MM.hasSaves() },
            { "join",     "JOIN A SERVER", A.join },
            { "host",     "HOST A GAME",   A.host },
            { "tutorial", "TUTORIAL",      A.tutorial },
        }
        for i, r in ipairs(list) do
            row = row + 1
            add({ id = r[1], text = r[2], variant = (not cont and i == 1) and "primary" or "default", fn = r[3], disabled = r[4],
                  row = row, col = 1, x = pad, y = y, w = w - pad * 2, h = T.px(WIDE_H) })
            y = y + T.px(WIDE_H) + gap
        end
        y = y - gap + pad
    else
        local info = MM.pauseInfo()
        self.title = info.name .. "  +  Paused"
        self.titleStats = { { text = info.save, color = T.positive } }
        self._head = { y = y, h = T.px(HEAD_H), when = info.when }
        y = y + T.px(HEAD_H) + pad
        local list = { { "resume", "RESUME", A.resume, "primary" }, { "options", "OPTIONS", A.options },
                       { "mods", "MODS (" .. MM.modCount() .. ")", A.modList } }
        if m and m.scoreOption then list[#list + 1] = { "players", "PLAYERS", A.players } end
        if m and m.inviteOption then list[#list + 1] = { "invite", "INVITE FRIENDS", A.invite } end
        for _, r in ipairs(list) do
            row = row + 1
            add({ id = r[1], text = r[2], variant = r[4] or "default", fn = r[3], row = row, col = 1,
                  x = pad, y = y, w = w - pad * 2, h = T.px(WIDE_H) })
            y = y + T.px(WIDE_H) + gap
        end
        y = y - gap + pad
    end

    -- the action strip
    local stripH = T.px(STRIP_BTN_H) + T.px(STRIP_PAD_Y) * 2
    self._strip = { y = y, h = stripH }
    row = row + 1
    local by = y + T.px(STRIP_PAD_Y)
    local bh = T.px(STRIP_BTN_H)
    local function bw(text) return textW(f3, text) + T.px(STRIP_BTN_PAD) * 2 end
    local col = 0
    local function left(id, text, fn, variant, disabled)
        col = col + 1
        local b = add({ id = id, text = text, fn = fn, variant = variant or "default", disabled = disabled, row = row, col = col,
                        x = self._sx, y = by, w = bw(text), h = bh })
        self._sx = self._sx + b.w + T.px(STRIP_GAP)
        return b
    end
    self._sx = T.px(STRIP_PAD_X)
    local rights = {}
    if self.confirm then
        self._ask = (self.kind == "main") and "Quit Project Zomboid?" or "Quit to desktop?"
        rights = { { "confirm:no", "CANCEL", function() self:setConfirm(false) end, "default" },
                   { "confirm:yes", "QUIT", A.quit, "danger" } }
    else
        self._ask = nil
        local cooling = isQuitCooldown and isQuitCooldown()
        if self.kind == "main" then
            left("options", "OPTIONS", A.options)
            left("mods", "MODS (" .. MM.modCount() .. ")", A.mods)
            if m and m.workshopOption then left("workshop", "WORKSHOP", A.workshop) end
            left("credits", "CREDITS", A.credits)
            rights = { { "quit", "QUIT", A.askQuit, "default", cooling } }
        else
            left("quitDesktop", "QUIT TO DESKTOP", function() self:setConfirm(true) end, "default", cooling)
            rights = { { "saveQuit", "SAVE AND QUIT", A.saveQuit, "default", cooling } }
        end
    end
    -- right-aligned buttons, in order
    local total = 0
    for i, r in ipairs(rights) do total = total + bw(r[2]) + (i > 1 and T.px(STRIP_GAP) or 0) end
    local rx = w - T.px(STRIP_PAD_X) - total
    for _, r in ipairs(rights) do
        col = col + 1
        local b = add({ id = r[1], text = r[2], fn = r[3], variant = r[4], disabled = r[5], row = row, col = col,
                        x = rx, y = by, w = bw(r[2]), h = bh })
        rx = rx + b.w + T.px(STRIP_GAP)
    end
    y = y + stripH

    local h = y + self:footerHeight()
    -- place
    local x, wy
    if self.kind == "main" then
        local barH = T.px(BAR_H)
        x = L.tx + math.floor((L.tw - w) / 2)
        wy = L.ty + barH + T.px(MM.continueInfo() and WIN_TOP or WIN_TOP_FIRST)
        if wy + h > L.ty + L.th then wy = math.max(L.ty + barH, L.ty + L.th - h) end
        self.title = "Project Zomboid  +  Main menu"
        self.titleStats = { { text = "Build " .. MM.version(), color = T.positive } }
    else
        x = math.floor((getCore():getScreenWidth() - w) / 2)
        wy = math.floor((getCore():getScreenHeight() - h) / 2)
    end
    if self.x ~= x or self.y ~= wy then self:setX(x); self:setY(wy) end
    if self.width ~= w or self.height ~= h then self:setWidth(w); self:setHeight(h) end
    self._specs = specs
    return specs
end

-- the controller's focus: rows of live buttons
function ZeD_MMWindow:rows()
    local rows, byRow = {}, {}
    for _, s in ipairs(self._specs) do
        if not s.disabled then
            local r = byRow[s.row]
            if not r then r = {}; byRow[s.row] = r; rows[#rows + 1] = r; r.n = s.row end
            r[#r + 1] = s
        end
    end
    table.sort(rows, function(a, b) return a.n < b.n end)
    for _, r in ipairs(rows) do table.sort(r, function(a, b) return a.col < b.col end) end
    return rows
end

function ZeD_MMWindow:focusPos()
    local rows = self:rows()
    for ri, r in ipairs(rows) do
        for ci, s in ipairs(r) do
            if s.id == self.focusId then return rows, ri, ci end
        end
    end
    if rows[1] then self.focusId = rows[1][1].id; return rows, 1, 1 end
    return rows, nil, nil
end

function ZeD_MMWindow:joyDir(dir)
    local rows, ri, ci = self:focusPos()
    if not ri then return end
    if dir == "up" or dir == "down" then
        local nr = ri + (dir == "up" and -1 or 1)
        if nr < 1 or nr > #rows then return end
        -- landing in the strip from above starts at its first button; leaving it goes to the row's only button
        local nc = math.min(ci, #rows[nr])
        self.focusId = rows[nr][nc].id
    else
        local nc = ci + (dir == "left" and -1 or 1)
        if nc < 1 or nc > #rows[ri] then return end
        self.focusId = rows[ri][nc].id
    end
    hoverSound()
end

function ZeD_MMWindow:joyA()
    local rows, ri, ci = self:focusPos()
    if ri then
        local s = rows[ri][ci]
        if s.fn then s.fn() end
    end
end

-- B: answer No to a question; in game, otherwise resume
function ZeD_MMWindow:joyB()
    if self.confirm then self:setConfirm(false); return end
    if self.kind == "pause" then MM.act.resume() end
end

function ZeD_MMWindow:getFooterPrompts()
    if not MM.gamepad() then return nil end
    if self.confirm then return { { glyph = "A", label = "Quit" }, { glyph = "B", label = "Cancel" } } end
    if self.kind == "pause" then return { { glyph = "A", label = "Select" }, { glyph = "B", label = "Resume" } } end
    return { { glyph = "A", label = "Select" }, { glyph = "Y", label = "Legal" } }
end

function ZeD_MMWindow:prerender()
    self:build()
    ZeD_Window.prerender(self)
    local T = ZeD.T
    local w = self.width
    local s2, bs = T.surf2, T.borderS
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()

    -- in game: the Paused header with the day and time
    if self._head then
        local hd = self._head
        self:drawRect(T.px(1), hd.y, w - T.px(2), hd.h, 1, s2.r, s2.g, s2.b)
        ZeD.Molecules.drawTabHeader(self, 0, hd.y, w, "Paused", true, false)
        local f3, d = T.fontF3, T.textDim
        self:drawText(hd.when, w - T.px(10) - textW(f3, hd.when), hd.y + math.floor((hd.h - fontH(f3)) / 2), d.r, d.g, d.b, d.a or 1, f3)
    end

    -- the Continue card: the last save's picture, name, character, mode and map, when it was played
    local cd = self._card
    if cd then
        local c = cd.info
        self:drawRect(cd.x, cd.y, cd.w, cd.h, 1, s2.r, s2.g, s2.b)
        self:drawRectBorder(cd.x, cd.y, cd.w, cd.h, bs.a, bs.r, bs.g, bs.b)
        local th = T.px(THUMB)
        local tx, ty = cd.x + T.px(CARD_PAD), cd.y + T.px(CARD_PAD)
        if c.thumb then
            self:drawTextureScaledAspect(c.thumb, tx, ty, th, th, 1, 1, 1, 1)
        else
            local s3 = T.surf3
            self:drawRect(tx, ty, th, th, 1, s3.r, s3.g, s3.b)
        end
        self:drawRectBorder(tx, ty, th, th, bs.a, bs.r, bs.g, bs.b)
        -- director, Oct 14 2026: the character leads, large; the save's name is a medium
        -- heading under it; then mode and map, and when it was played
        local ix = tx + th + T.px(CARD_GAP)
        local maxW = cd.x + cd.w - T.px(CARD_PAD) - ix
        local tc = T.textHead
        local y = ty + T.px(2)
        -- large: the character (a red status dot before a dead one), or the save when it has none
        local hf = ZeD.Font.sdf.head
        local z = 20 * (T.scale or 1) / (hf.face or 64)
        local bigH = math.floor(ZeD.Text.height(hf, z))
        local lx = ix
        if c.who and c.dead then
            local dsz = T.px(9)
            ZeD.Atoms.drawStatusDot(self, lx, y + math.floor((bigH - dsz) / 2), T.danger, dsz)
            lx = lx + dsz + T.px(6)
        end
        local big = c.who or c.title
        local room = maxW - (lx - ix)
        if ZeD.Text.width(hf, big, z) > room then
            while #big > 1 and ZeD.Text.width(hf, big .. "...", z) > room do big = big:sub(1, #big - 1) end
            big = big .. "..."
        end
        ZeD.Text.draw(self, hf, big, lx, y, z, tc.r, tc.g, tc.b, tc.a or 1, "l")
        y = y + bigH + T.px(2)
        -- medium: the save
        if c.who then
            local f4 = T.fontF4
            self:drawText(ZeD.Atoms.truncateText(c.title, f4, maxW), ix, y, tc.r, tc.g, tc.b, tc.a or 1, f4)
            y = y + math.floor(fontH(f4)) + T.px(6)
        else
            y = y + T.px(4)
        end
        -- small: mode and map, last played
        local f3, d = T.fontF3, T.textDim
        local lineH = T.px(17)
        local lines = { c.where }
        if c.played then lines[#lines + 1] = c.played end
        for _, l in ipairs(lines) do
            self:drawText(ZeD.Atoms.truncateText(l, f3, maxW), ix, y + math.floor((lineH - fontH(f3)) / 2), d.r, d.g, d.b, d.a or 1, f3)
            y = y + lineH
        end
    end

    -- the action strip
    local st = self._strip
    self:drawRect(T.px(1), st.y, w - T.px(2), st.h, 1, s2.r, s2.g, s2.b)
    self:drawRect(T.px(1), st.y, w - T.px(2), T.px(1), bs.a, bs.r, bs.g, bs.b)
    if self._ask then
        local f2, c = T.fontF2, T.text
        self:drawText(self._ask, T.px(STRIP_PAD_X) + T.px(4), st.y + math.floor((st.h - fontH(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
    end

    -- the buttons
    local ctx = self:pctx()
    local gp = MM.gamepad()
    if gp then self:focusPos() end
    self._hits = {}
    for _, b in ipairs(self._specs) do
        local hid = self.kind .. ":" .. b.id
        local hot = not gp and ctx.hot == hid
        local focus = gp and self.focusId == b.id
        drawBtn(self, b, hot, focus, hot and ctx.press == hid)
        self._hits[#self._hits + 1] = { id = hid, x = ax + b.x, y = ay + b.y, w = b.w, h = b.h, fn = b.fn, disabled = b.disabled, sound = true }
    end
end

-- no dragging, no WindowShade: the window sits where the menu puts it
function ZeD_MMWindow:onMouseDown(x, y) return true end

-- Escape opened the pause menu (vanilla's ToggleEscapeMenu calls onEnterFromGame on
-- MainScreen's children): no question pending, the controller on Resume.
function ZeD_MMWindow:onEnterFromGame()
    self.confirm = false
    self.focusId = "resume"
    self.ctx.hot, self.ctx.press = nil, nil
end

-- the close box: Quit on the monitor, Resume in game
function ZeD_MMWindow:close()
    if self.kind == "main" then MM.act.askQuit() else MM.act.resume() end
end

function ZeD_MMWindow:update()
    -- the frame's own controls (close box, theme squares) wait while a menu is open over them
    local before = tostring(ZeD.currentBase) .. tostring(ZeD.currentAccent) .. tostring(ZeD.currentSize)
    if not (self.kind ~= "pause" and MM.ctx.open) and not blocked() then ZeD_Window.update(self) end
    local after = tostring(ZeD.currentBase) .. tostring(ZeD.currentAccent) .. tostring(ZeD.currentSize)
    if before ~= after and PZAPI and PZAPI.ModOptions then pcall(PZAPI.ModOptions.save, PZAPI.ModOptions) end
    if self.kind == "pause" then MM.pointer(self.ctx, { self }) end
end

-- ============================================================================
-- ATTACHING TO VANILLA'S MainScreen (called from Overrides/MainMenu.lua)
-- ============================================================================
function MM.attach(m)
    if m.inGame then
        local w = ZeD_MMWindow:new("pause")
        w:initialise()
        m:addChild(w)
        MM.pause = w
        -- Options in game: its own window over the world, and a pull-down for its list boxes (added last: on top)
        MM.pauseView = "pause"
        local ow = ZeD_MMOptions:new(true)
        ow:initialise()
        m:addChild(ow)
        ow:setVisible(false)
        MM.pauseOpts = ow
        local dr = ZeD_MMDrop:new()
        dr:initialise()
        m:addChild(dr)
        dr:setVisible(false)
        MM.igDrop = dr
        MM.hookOptions(m)
    else
        MM.ctx.open, MM.ctx.hot, MM.ctx.press = nil, nil, nil
        MM.view = "main"
        local root = ZeD_MMDesk:new()
        root:initialise()
        m:addChild(root)
        MM.root = root
        MM.refresh()
        -- vanilla's debug scenario list sat over the logo; it is in the Debug menu now
        local ds = DebugScenarios and DebugScenarios.instance
        if ds then ds:setVisible(false) end
        -- Every vanilla way back to New Game or Load (map / spawn's BACK, character creation's
        -- BACK, the mod list's return, a challenge's BACK) shows vanilla's screen with
        -- setVisible(true): those land on the monitor instead.
        MM.redirect(m.soloScreen, "newgame")
        MM.redirect(m.loadScreen, "load")
        MM.redirect(m.modSelect, "mods")
        for _, v in ipairs(MM.views) do
            if v.screen then if v.mirror then MM.mirror(m[v.screen], v.view) else MM.redirect(m[v.screen], v.view) end end
        end
        MM.hookOptions(m)
    end
end

function MM.redirect(screen, view)
    if not screen or screen._zedRedirect then return end
    screen._zedRedirect = true
    local orig = screen.setVisible
    screen.setVisible = function(self, visible, joypadData)
        if visible and MM.root then
            orig(self, false, joypadData)
            MM.showView(view, joypadData)
            return
        end
        return orig(self, visible, joypadData)
    end
end

-- Puts a view on the monitor: "main", "load" or "newgame". The menu comes back up
-- (vanilla's bottom panel) and the controller focus returns to MainScreen.
function MM.showView(view, joypadData)
    local m = ms()
    if not m then return end
    MM.view = view
    MM.ctx.open, MM.ctx.hot, MM.ctx.press = nil, nil, nil
    local w = MM.activeWindow()
    if w and w.onShow then w:onShow() end
    if not m.bottomPanel:isVisible() then m.bottomPanel:setVisible(true) end
    local jd = joypadData or (JoypadState and JoypadState.getMainMenuJoypad and JoypadState.getMainMenuJoypad())
    if jd then jd.focus = m; updateJoypadFocus(jd) end
end

-- A vanilla screen takes over (map / spawn, mods, ...): the desk steps aside.
function MM.toVanilla()
    MM.ctx.open = nil
    local m = ms()
    if m and m.bottomPanel:isVisible() then m.bottomPanel:setVisible(false) end
end

-- The window the current view shows.
function MM.activeWindow()
    local r = MM.root
    if not r then return nil end
    if MM.view == "load" then return r.loadWin end
    if MM.view == "newgame" then return r.newWin end
    if MM.view == "mods" then return r.modsWin end
    if MM.view == "options" then return r.optsWin end
    for _, rv in ipairs(MM.views) do
        if MM.view == rv.view and r[rv.field] then return r[rv.field] end
    end
    return r.win
end

-- A later screen's window on the monitor: its view name, the desk's field for it, a
-- maker (called when the desk builds, after every module has loaded), and the MainScreen
-- field of the vanilla screen it stands in for (its setVisible(true) lands on the view).
MM.views = MM.views or {}
function MM.addView(view, field, make, screen, mirror)
    for _, v in ipairs(MM.views) do
        if v.view == view then v.field, v.make, v.screen, v.mirror = field, make, screen, mirror; return end   -- a Lua reload replaces it
    end
    MM.views[#MM.views + 1] = { view = view, field = field, make = make, screen = screen, mirror = mirror }
end

-- A vanilla screen that must stay "visible" to keep working (it only follows events while
-- shown): it shows as vanilla wants but off the screen, and the view mirrors it; hiding
-- it brings it back and leaves the view (whatever vanilla shows next takes over).
function MM.mirror(screen, view)
    if not screen or screen._zedRedirect then return end
    screen._zedRedirect = true
    local orig = screen.setVisible
    screen.setVisible = function(self, visible, joypadData)
        orig(self, visible, joypadData)
        if not MM.root then return end
        if visible then
            if self:getX() > -10000 then self._zedX = self:getX() end
            self:setX(-20000)
            MM.showView(view, joypadData)
        else
            if self:getX() <= -10000 then self:setX(self._zedX or 0) end
            if MM.view == view then MM.showView("main") end
        end
    end
end

-- Is our menu showing (vanilla's bottom panel visible = no other screen is up)?
function MM.isUp(m)
    -- explicit ifs: Kahlua can return the table from "A and B and (C or D) and true or false" (KB Q206)
    if not (m and m.bottomPanel and m.bottomPanel:isVisible()) then return false end
    if m.inGame then return MM.pause ~= nil end
    return MM.root ~= nil
end

-- Vanilla's own extras on the main screen move into the menu; hide them while it shows.
local EXTRAS = { "versionBtn", "reportBug", "termsOfService", "resetLua", "modListDetail", "seedLabel" }
function MM.hideExtras(m)
    for _, k in ipairs(EXTRAS) do
        local e = m[k]
        if e and e.isVisible and e:isVisible() then e:setVisible(false) end
    end
end

-- Runs after MainScreen's prerender every frame.
function MM.afterPrerender(m)
    local up = MM.isUp(m)
    if m.inGame then
        local pv = MM.pauseView or "pause"
        local w = MM.pause
        if w and w:isVisible() ~= (up and pv == "pause") then w:setVisible(up and pv == "pause") end
        local ow = MM.pauseOpts
        if ow and ow:isVisible() ~= (up and pv == "options") then ow:setVisible(up and pv == "options") end
        if MM.igDrop and not (up and pv == "options") and MM.igDrop:isVisible() then MM.igDrop:setVisible(false); MM.ctx.open = nil end
    else
        local root = MM.root
        local show = up or MM.powerOff ~= nil   -- (a game starting: the desk stays while the monitor switches off)
        if root and root:isVisible() ~= show then
            root:setVisible(show)
            if up then
                MM.refresh()
                MM.ctx.open, MM.ctx.press = nil, nil
                if root.win then root.win.confirm = false end
            end
        end
    end
    if up then
        m.bottomPanel:setX(-20000)   -- vanilla's labels stay alive (their items drive every action) but out of sight
        MM.hideExtras(m)
    end
end

-- ---------------------------------------------------------------------------
-- CONTROLLER + KEYS (MainScreen hands them in while our menu shows). An open
-- pull-down takes the D-pad, A and B first; otherwise the view's window does
-- (joyA / joyB / joyX / joyY / joyDir).
-- ---------------------------------------------------------------------------
function MM.window(m)
    if m.inGame then
        if MM.pauseView == "options" and MM.pauseOpts then return MM.pauseOpts end
        return MM.pause
    end
    return MM.activeWindow()
end

function MM.joyDown(m, button)
    if MM.ctx.open then
        local live = MM.dropLive()
        if button == Joypad.AButton then
            local it = live[MM.ctx.dropFocus or 1]
            MM.ctx.open = nil
            if it and it.fn then it.fn() end
        elseif button == Joypad.BButton then
            MM.ctx.open = nil
        end
        return
    end
    local w = MM.window(m)
    if not w then return end
    if button == Joypad.AButton then w:joyA()
    elseif button == Joypad.BButton then w:joyB()
    elseif button == Joypad.XButton then if w.joyX then w:joyX() end
    elseif button == Joypad.LBumper then if w.joyBumper then w:joyBumper(-1) end
    elseif button == Joypad.RBumper then if w.joyBumper then w:joyBumper(1) end
    elseif button == Joypad.YButton then
        if w.joyY then w:joyY()
        elseif not m.inGame and not w.confirm then MM.act.tos() end
    end
end

function MM.joyDir(m, dir)
    if MM.ctx.open then
        local n = #MM.dropLive()
        if n > 0 and (dir == "up" or dir == "down") then
            local f = (MM.ctx.dropFocus or 1) + (dir == "up" and -1 or 1)
            if f < 1 then f = n elseif f > n then f = 1 end
            MM.ctx.dropFocus = f
            hoverSound()
        end
        return
    end
    local w = MM.window(m)
    if w then w:joyDir(dir) end
end

-- the controller starts on the window's first button
function MM.joyFocus(m)
    local w = MM.window(m)
    if w then w.focusId = nil end
end

-- Keys at the main menu. Escape closes an open menu, then a question, then leaves Load
-- Game / New Game; Return plays / goes on. True = handled.
function MM.keyRelease(m, key)
    if m.inGame or not MM.isUp(m) then return false end
    local w = MM.window(m)
    if key == Keyboard.KEY_ESCAPE then
        if MM.ctx.open then MM.ctx.open = nil; return true end
        if w and w.keyEscape and w:keyEscape() then return true end
        if w and w.confirm then w:setConfirm(false); return true end
        return false
    end
    if w and w.keyOther then return w:keyOther(key) end
    return false
end

-- shared with ZeD_MainMenuSaves.lua
MM.drawBtn, MM.drawMark = drawBtn, drawMark
MM.hoverSound, MM.clickSound = hoverSound, clickSound
MM.textW, MM.fontH, MM.blocked, MM.now, MM.tex = textW, fontH, blocked, now, tex
MM.DOT, MM.MONTHS = DOT, MONTHS
MM.U = { BAR_H = BAR_H, STACK_PAD = STACK_PAD, STACK_GAP = STACK_GAP, WIDE_H = WIDE_H,
         STRIP_PAD_X = STRIP_PAD_X, STRIP_PAD_Y = STRIP_PAD_Y, STRIP_BTN_H = STRIP_BTN_H,
         STRIP_BTN_PAD = STRIP_BTN_PAD, STRIP_GAP = STRIP_GAP }

-- the wheel over an open pull-down scrolls it (the drop is its own panel)
function ZeD_MMDrop:onMouseWheel(del) return MM.dropWheel(del) end
