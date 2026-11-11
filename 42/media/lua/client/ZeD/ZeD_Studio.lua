-- ============================================================================
-- ZeD_Studio.lua: the portrait studio, step 1: the room (punch list 145)
-- ============================================================================
-- The director, Nov 10 2026: "Add a popout XL avatar option to the ID ... OR! Enter the studio and there are pull down
-- backdrops you can choose like the old glamour shots did." Then "Studio has to auto pause the game". Rulings: the
-- studio, in two steps (the room, then the backdrops and poses); single player only (a client can't stop a server's
-- clock); a camera button in the ID photo's corner opens it; Take photo is a clean shot with a flash; pieces, not
-- sets; props held off. The name stays ZeD's own.
--
-- The room: the whole screen, the player's own 3D figure (ISUI3DModel, as the ID photo uses) near the screen's full
-- height over a plain seamless backdrop that runs edge to edge (so the photo is all studio). Drag the figure to turn it (the model's own drag), the wheel or the three
-- framings (full body, three-quarter, bust: the ID photo's two framings and one between) to frame it, two buttons to
-- turn it a step. Opening it pauses the game and hides the game's "Game Paused" box (as the Survival Guide book does);
-- leaving puts the speed back as it was. Take photo draws one frame with nothing but the backdrop and the figure, takes
-- the game's screenshot of it (Zomboid/Screenshots) after that frame, then flashes and names the file.
-- The controller: A takes the photo, B leaves, LB and RB turn, Up and Down frame, Y the next backdrop.
-- Poses: standing only for now (the director, Nov 10 2026). The probe (ZeDUI/tools/qa/zedqa_studio_probe.lua) found no
-- state, emote or variable that poses this figure; the game's own walk and run events do, as moving loops, and the
-- figure freezes while the game is paused.
-- ============================================================================

require "ISUI/ISUI3DModel"

ZeD = ZeD or {}
ZeD.Studio = ZeD.Studio or {}
local ST = ZeD.Studio

local function tr(k, ...) return ZeD.tr(k, ...) end
-- the two framings the ID photo uses (ZeD_CharacterWindow: full body zoom 0, y 0; the bust 19, -0.875)
local BUST_ZOOM, BUST_Y = 19, -0.875
-- The y offset that keeps the head whole with a little paper above it, by zoom, measured on QA's Mac (Nov 10 2026,
-- zedqa_studio_frame_probe.lua and finer steps after it): zoom 6 at -0.6, 11 at -0.70, 15 at -0.79; the bust is the
-- ID photo's (19, -0.875). A y of exactly 0 is the figure's own centring, which sits where about -0.5 would (from 0 to
-- +0.05 the figure jumped 484 px where the slope gives 44), so full body keeps its 0 and the curve starts at -0.5.
-- (Three-quarter as halfway between the two framings' zoom and y, 10.45 at -0.48, framed collar to shins.)
local YAT = { { 0, -0.5 }, { 6, -0.6 }, { 11, -0.70 }, { 15, -0.79 }, { 19, -0.875 } }
local function yAt(z)
    if z <= 0 then return 0 end
    for i = 2, #YAT do
        local a, b = YAT[i - 1], YAT[i]
        if z <= b[1] then return a[2] + (b[2] - a[2]) * (z - a[1]) / (b[1] - a[1]) end
    end
    return YAT[#YAT][2]
end
ST.yAt = yAt
local FRAMES = { { key = "UI_ZeD_Studio_Full", t = 0 }, { key = "UI_ZeD_Studio_ThreeQ", t = 11 / 19 }, { key = "UI_ZeD_Studio_Bust", t = 1 } }
ST.FRAMES = FRAMES
-- the seamless paper: a studio grey, the same in every theme (it is the set, not the UI), lighter at the sweep
local PAPER_TOP, PAPER_LOW = { r = 0.47, g = 0.49, b = 0.52 }, { r = 0.62, g = 0.64, b = 0.66 }
local BAR_H, GAP, BTN_H = 44, 8, 26

--- May the studio open here? Single player only: it pauses the game.
function ST.available() return not (isClient and isClient()) end

ZeD_StudioRoom = ZeD_Panel:derive("ZeD_StudioRoom")

function ZeD_StudioRoom:new(chr)
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local o = ZeD_Panel.new(self, 0, 0, sw, sh)
    o.chr = chr
    o.t = 0                 -- the framing, 0 full body to 1 bust
    o.bd = ST.backdrop or 1 -- the backdrop hanging
    o.anchorRight, o.anchorBottom = false, false
    o._hitZones = {}
    o:setWantKeyEvents(true)
    return o
end

function ZeD_StudioRoom:createChildren()
    local m = ISUI3DModel:new(0, 0, 10, 10)
    m:initialise()
    m:instantiate()
    m:setCharacter(self.chr)
    m:setState("idle")
    m:setDirection(IsoDirections.S)
    m:setIsometric(false)
    m:setDoRandomExtAnimations(true)
    local room = self
    m.onMouseWheel = function(_, del) room:frameBy(del * 0.08); return true end
    self:addChild(m)
    self.fig = m
    self:frameTo(self.t)
end

--- The framing, 0 (full body) to 1 (bust)
function ZeD_StudioRoom:frameTo(t)
    t = math.max(0, math.min(1, t or 0))
    self.t = t
    if self.fig then
        local z = BUST_ZOOM * t
        self.fig:setZoom(z)
        self.fig:setYOffset(yAt(z))
    end
end
function ZeD_StudioRoom:frameBy(d) self:frameTo(self.t + d) end

--- Turn the figure a step (dir < 0 to its left)
function ZeD_StudioRoom:turn(dir)
    local m = self.fig
    if not m then return end
    pcall(function()
        local d = m:getDirection()
        m:setDirection(dir < 0 and d:RotLeft() or d:RotRight())
    end)
end

-- the backdrop's place and the figure's in it
function ZeD_StudioRoom:layout()
    local T = ZeD.T
    local sw, sh = self.width, self.height
    local bar, m = T.px(BAR_H), T.px(GAP) * 2
    local bh = sh - bar - m * 2
    local bw = math.min(sw - m * 2, math.floor(bh * 0.95))
    local bx, by = math.floor((sw - bw) / 2), m
    local fh = math.floor(bh * 0.97)
    local fw = math.floor(fh * 0.6)
    return { bx = bx, by = by, bw = bw, bh = bh, fx = math.floor((sw - fw) / 2), fy = by + bh - fh, fw = fw, fh = fh, bar = bar }
end

local function drawPaper(p, L, vis)
    -- a vertical sweep in strips: the paper darkening to its top, lighter where it curves into the floor; vis: how
    -- much of it hangs down from the top (a roll), all of it when nil
    local n = 48
    local limit = L.by + (vis or L.bh)
    for i = 0, n - 1 do
        local f = i / (n - 1)
        local c = { r = PAPER_TOP.r + (PAPER_LOW.r - PAPER_TOP.r) * f, g = PAPER_TOP.g + (PAPER_LOW.g - PAPER_TOP.g) * f,
                    b = PAPER_TOP.b + (PAPER_LOW.b - PAPER_TOP.b) * f }
        local y0 = L.by + math.floor(L.bh * i / n)
        local y1 = math.min(limit, L.by + math.floor(L.bh * (i + 1) / n))
        if y1 > y0 then p:drawRect(L.bx, y0, L.bw, y1 - y0, 1, c.r, c.g, c.b) end
    end
end

-- ---------------------------------------------------------------------------
-- THE BACKDROPS (step 2; the director, Nov 10 2026: "go ahead with those backdrops"). Painted drafts for the director
-- to refine (ZeDUI/tools/studio/make_backdrops.py; the guide and the 1920 x 1080 copies in ZeDUI/art/studio_backdrops):
-- each hangs from a roller along the top of the screen and fills it ("cover": scaled to fill, the edges cropped on
-- screens of another shape). Picking one rolls the paper that hangs up into the roller, then the new one down.
-- ---------------------------------------------------------------------------
local TEX = "media/textures/ZeD/studio/backdrop_"
ST.BACKDROPS = {
    { id = "grey", key = "UI_ZeD_Studio_BdGrey" },                                 -- (drawn here: drawPaper)
    { id = "mottled", key = "UI_ZeD_Studio_BdMottled", tex = TEX .. "mottled.png" },
    { id = "sky", key = "UI_ZeD_Studio_BdSky", tex = TEX .. "sky.png" },
    { id = "autumn", key = "UI_ZeD_Studio_BdAutumn", tex = TEX .. "autumn.png" },
    { id = "knox", key = "UI_ZeD_Studio_BdKnox", tex = TEX .. "knox.png" },
    { id = "lasers", key = "UI_ZeD_Studio_BdLasers", tex = TEX .. "lasers.png" },
    { id = "flag", key = "UI_ZeD_Studio_BdFlag", tex = TEX .. "flag.png" },   -- (the director, Nov 10 2026)
}
ST.backdrop = ST.backdrop or 1          -- (the last one picked, for the session)
ST.ROLL_MS = 380                        -- each half of a change: the old paper up, the new one down
local ROLLER = 12                       -- the roller's height, design units

local function texOf(b)
    if not b.tex then return nil end
    if b._t == nil then b._t = (getTexture and getTexture(b.tex)) or false end
    return b._t or nil
end
ST.texOf = texOf

-- backdrop b over (x, y, w, h), its paper down frac of the way from the roller (1: all of it)
local function drawBackdrop(p, b, x, y, w, h, frac)
    local vis = math.floor(h * math.max(0, math.min(1, frac)))
    if vis <= 0 then return end
    local tex = texOf(b)
    if not tex then
        drawPaper(p, { bx = x, by = y, bw = w, bh = h }, vis)
        return
    end
    local tw, th = tex:getWidth(), tex:getHeight()
    local sc = math.max(w / tw, h / th)
    local sw, sh = w / sc, h / sc
    local sx, sy = (tw - sw) / 2, (th - sh) / 2
    p.javaObject:DrawSubTextureRGBA(tex, sx, sy, sw, sh * vis / h, x, y, w, vis, 1, 1, 1, 1)
end
ST._drawBackdrop = drawBackdrop

--- Pick backdrop i: the paper that hangs rolls up, then i's rolls down.
--- (The tray stays open after a pick, to try the next one behind the character: QA's Mac run, Nov 11 2026, found it
--- shut after each. It shuts on the Backdrop button, a press on the paper, or Take photo.)
function ZeD_StudioRoom:pickBackdrop(i)
    if not ST.BACKDROPS[i] or i == self.bd or self.roll then return end
    self.roll = { from = self.bd, to = i, t0 = getTimestampMs() }
    self.bd = i
    ST.backdrop = i
end

-- the stage: the wall, the paper (rolling, when it is), the roller; returns how far down the paper hangs
function ZeD_StudioRoom:drawStage()
    local T = ZeD.T
    local W, H = self.width, self.height
    local base = T.base
    self:drawRect(0, 0, W, H, 1, base.r * 0.5, base.g * 0.5, base.b * 0.5)   -- (the wall behind the paper)
    local b, frac = ST.BACKDROPS[self.bd] or ST.BACKDROPS[1], 1
    local r = self.roll
    if r then
        local e = getTimestampMs() - r.t0
        if e < ST.ROLL_MS then b, frac = ST.BACKDROPS[r.from] or b, 1 - e / ST.ROLL_MS
        elseif e < ST.ROLL_MS * 2 then frac = (e - ST.ROLL_MS) / ST.ROLL_MS
        else self.roll = nil end
    end
    drawBackdrop(self, b, 0, 0, W, H, frac)
    if self.shoot then return frac end   -- (the photo: the paper alone, no roller)
    -- the paper's weighted foot while it moves, and the roller along the top
    local rh = T.px(ROLLER)
    if frac < 1 then
        local fy = math.floor(H * frac)
        self:drawRect(0, fy - T.px(3), W, T.px(4), 1, 0.16, 0.15, 0.14)
    end
    self:drawRect(0, 0, W, rh, 1, 0.20, 0.20, 0.22)
    self:drawRect(0, math.floor(rh * 0.25), W, math.max(1, math.floor(rh * 0.2)), 1, 0.42, 0.42, 0.45)
    self:drawRect(0, rh - T.px(1), W, T.px(1), 1, 0.08, 0.08, 0.09)
    return frac
end

function ZeD_StudioRoom:prerender()
    local L = self:layout()
    -- the paper from edge to edge, so the photo (the game's screenshot is the whole screen) is all studio (the
    -- director, Nov 10 2026, after QA's first portrait showed the dark room either side: "Paper fills the screen")
    self:drawStage()
    local m = self.fig
    if m and (m.x ~= L.fx or m.y ~= L.fy or m.width ~= L.fw or m.height ~= L.fh) then
        m:setX(L.fx); m:setY(L.fy); m:setWidth(L.fw); m:setHeight(L.fh)
    end
    self:clearHitZones()
    if self.shoot then return end   -- (the clean frames: the paper and the figure only)
    self:drawBar(L)
end

-- the controls' bar along the foot of the screen
function ZeD_StudioRoom:drawBar(L)
    local T = ZeD.T
    local s2 = T.surf2
    local y0 = self.height - L.bar
    self:drawRect(0, y0, self.width, L.bar, 1, s2.r, s2.g, s2.b)
    self:drawRect(0, y0, self.width, T.px(1), 1, T.borderS.r, T.borderS.g, T.borderS.b)
    local bh = T.px(BTN_H)
    local by = y0 + math.floor((L.bar - bh) / 2)
    local x = T.px(GAP) * 2
    local mx, my = self:getMouseX(), self:getMouseY()
    local f = T.fontF2
    local function button(id, text, pressed)
        local w = ZeD.TM:MeasureStringX(f, text) + T.px(20)
        local over = mx >= x and mx < x + w and my >= by and my < by + bh
        ZeD.Molecules.drawButton(self, x, by, w, bh, text, "default", pressed or false, nil, { hover = over })
        self:addHitZone(id, x, by, w, bh)
        x = x + w + T.px(6)
    end
    button("tray", tr("UI_ZeD_Studio_Backdrop"), self.tray)
    x = x + T.px(12)
    for i, fr in ipairs(FRAMES) do button("frame:" .. i, tr(fr.key), math.abs(self.t - fr.t) < 0.01) end
    x = x + T.px(12)
    button("turn:-1", tr("UI_ZeD_Studio_TurnL"))
    button("turn:1", tr("UI_ZeD_Studio_TurnR"))
    x = x + T.px(12)
    button("photo", tr("UI_ZeD_Studio_Photo"))
    button("leave", tr("UI_ZeD_Studio_Leave"))
    if self.tray then self:drawTray(y0) end
    -- the help line, or what the last photo was saved as
    local msg = self.saved and tr("UI_ZeD_Studio_Saved", self.saved) or tr("UI_ZeD_Studio_Help")
    local tc = T.textSec or T.textDim
    local room = self.width - x - T.px(GAP) * 2
    if room > T.px(40) then
        local s = ZeD.Atoms.truncateText(msg, f, room)
        self:drawText(s, x + T.px(GAP), y0 + math.floor((L.bar - ZeD.TM:getFontHeight(f)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f)
    end
end

-- the backdrops' tray: a column of swatches down the left side, above the bar, named, the one hanging outlined in the
-- accent; a second column when one doesn't fit the height. On the left, clear of the figure: across the bar's top the
-- figure's panel (above the studio's own drawing, and taking the pointer) lay over the last swatches, so Lasers and
-- the flag couldn't be picked and the shoes drew over them (QA's Mac run, Nov 10 2026); and from there the backdrop
-- changing behind the character shows while picking.
function ZeD_StudioRoom:drawTray(barY)
    local T = ZeD.T
    local n = #ST.BACKDROPS
    local tw, th, gap, pad = T.px(128), T.px(72), T.px(8), T.px(8)
    local f = T.fontF2
    local lh = ZeD.TM:getFontHeight(f)
    local cellH = th + lh + T.px(6)
    local top = T.px(ROLLER) + T.px(GAP)
    local room = barY - T.px(6) - top - pad * 2
    local rows = math.max(1, math.min(n, math.floor((room + gap) / (cellH + gap))))
    local cols = math.ceil(n / rows)
    local w = cols * tw + (cols - 1) * gap + pad * 2
    local h = rows * cellH + (rows - 1) * gap + pad * 2
    local x0, y0 = T.px(GAP) * 2, barY - h - T.px(6)
    local s2, bs = T.surf2, T.borderS
    self:drawRect(x0, y0, w, h, 1, s2.r, s2.g, s2.b)
    self:drawRectBorder(x0, y0, w, h, 1, bs.r, bs.g, bs.b)
    self:addHitZone("trayBox", x0, y0, w, h)
    local mx, my = self:getMouseX(), self:getMouseY()
    for i, b in ipairs(ST.BACKDROPS) do
        local col, row = math.floor((i - 1) / rows), (i - 1) % rows
        local x, y = x0 + pad + col * (tw + gap), y0 + pad + row * (cellH + gap)
        drawBackdrop(self, b, x, y, tw, th, 1)
        local over = mx >= x and mx < x + tw and my >= y and my < y + th + lh + T.px(6)
        local oc = (i == self.bd) and T.accent or (over and T.text or bs)
        self:drawRectBorder(x, y, tw, th, 1, oc.r, oc.g, oc.b)
        if i == self.bd then self:drawRectBorder(x + 1, y + 1, tw - 2, th - 2, 1, oc.r, oc.g, oc.b) end
        local name = ZeD.Atoms.truncateText(tr(b.key), f, tw)
        local tc = T.text
        self:drawText(name, x, y + th + T.px(4), tc.r, tc.g, tc.b, tc.a or 1, f)
        self:addHitZone("bd:" .. i, x, y, tw, th + lh + T.px(6))
    end
end

function ZeD_StudioRoom:render()
    -- the flash after a photo: white, fading over a third of a second
    if self.flashAt then
        local a = 1 - (getTimestampMs() - self.flashAt) / 350
        if a <= 0 then self.flashAt = nil
        else self:drawRect(0, 0, self.width, self.height, a * 0.85, 1, 1, 1) end
    end
end

function ZeD_StudioRoom:onMouseUp(x, y)
    -- (the last zone under the pointer: a swatch over the tray's box)
    local z = nil
    for _, zz in ipairs(self._hitZones or {}) do
        if x >= zz.x and y >= zz.y and x < zz.x + zz.w and y < zz.y + zz.h then z = zz end
    end
    if not z then self.tray = false end
    if not z then return true end
    local id = tostring(z.id)
    if id == "tray" then self.tray = not self.tray
    elseif id:sub(1, 3) == "bd:" then self:pickBackdrop(tonumber(id:sub(4)))
    elseif id == "trayBox" then return true
    elseif id:sub(1, 6) == "frame:" then self:frameTo(FRAMES[tonumber(id:sub(7))].t)
    elseif id:sub(1, 5) == "turn:" then self:turn(tonumber(id:sub(6)))
    elseif id == "photo" then self:photo()
    elseif id == "leave" then ST.close() end
    pcall(function() getSoundManager():playUISound("UIActivateButton") end)
    return true
end
function ZeD_StudioRoom:onMouseWheel(del) self:frameBy(del * 0.08); return true end

--- Take a photo: the next frame draws clean, the shot is taken after it (ST's OnPostUIDraw), then the flash.
function ZeD_StudioRoom:photo()
    if self.shoot or self.roll then return end   -- (not while a paper moves)
    self.tray = false
    self.shoot = 1
end

function ZeD_StudioRoom:isKeyConsumed(key) return key == Keyboard.KEY_ESCAPE end
function ZeD_StudioRoom:onKeyPress(key)
    if key == Keyboard.KEY_ESCAPE then ST.close(); pcall(GameKeyboard.eatKeyPress, key) end
end

-- the controller: A the photo, B leaves, LB / RB turn, Up / Down frame
function ZeD_StudioRoom:onJoypadDown(button)
    if button == Joypad.AButton then self:photo()
    elseif button == Joypad.BButton then ST.close()
    elseif button == Joypad.LBumper then self:turn(-1)
    elseif button == Joypad.RBumper then self:turn(1)
    elseif button == Joypad.YButton then self:pickBackdrop(self.bd % #ST.BACKDROPS + 1) end
end
function ZeD_StudioRoom:onJoypadDirUp() self:frameBy(0.25) end
function ZeD_StudioRoom:onJoypadDirDown() self:frameBy(-0.25) end

-- after the clean frame is on screen: the shot, then the flash and the file's name
local function afterDraw()
    local p = ST.room
    if not (p and p.shoot) then return end
    -- 1: the first clean frame is up; 2: the shot, after a second clean one; 3: one more clean frame (in case the
    -- game reads the frame after the call), then the flash and the file's name
    if p.shoot == 1 then p.shoot = 2; return end
    if p.shoot == 2 then
        p.shotName = "zed_portrait_" .. tostring(getTimestampMs()) .. ".png"
        pcall(function() getCore():TakeFullScreenshot(p.shotName) end)
        p.shoot = 3
        return
    end
    if p.shoot == 3 then
        p.saved, p.flashAt, p.shoot = p.shotName, getTimestampMs(), nil
        pcall(function() getSoundManager():playUISound("UIActivateButton") end)
    end
end
if Events and Events.OnPostUIDraw and not ST._hooked then
    ST._hooked = true
    Events.OnPostUIDraw.Add(function() afterDraw() end)
end
ST._afterDraw = afterDraw

--- Open the studio for chr (the player's character). False when it can't (multiplayer, no character).
function ST.open(chr)
    if not (chr and ST.available()) then return false end
    if ST.room then ST.close() end
    local p = ZeD_StudioRoom:new(chr)
    p:initialise()
    p:instantiate()
    p:addToUIManager()
    p:setAlwaysOnTop(true)
    p:bringToTop()
    ST.room = p
    -- the pause, and the game's paused box out of the way (as the Survival Guide book has it)
    ST._speed = (getGameSpeed and getGameSpeed()) or 1
    pcall(setGameSpeed, 0)
    pcall(function() ST._pausedMsg = UIManager.isShowPausedMessage(); UIManager.setShowPausedMessage(false) end)
    -- the controller's focus
    local pn = chr.getPlayerNum and chr:getPlayerNum() or 0
    local jd = JoypadState and JoypadState.players and JoypadState.players[pn + 1]
    if jd then ST._prevFocus = jd.focus; jd.focus = p; jd.activeWhilePaused = true; pcall(updateJoypadFocus, jd) end
    ST._pn = pn
    return true
end

--- Leave the studio: the game's speed as it was, its paused box as it was, the controller back.
function ST.close()
    local p = ST.room
    if not p then return end
    ST.room = nil
    p:setVisible(false)
    p:removeFromUIManager()
    if ST._pausedMsg ~= nil then pcall(function() UIManager.setShowPausedMessage(ST._pausedMsg) end); ST._pausedMsg = nil end
    pcall(setGameSpeed, ST._speed or 1)
    local jd = JoypadState and JoypadState.players and JoypadState.players[(ST._pn or 0) + 1]
    if jd and jd.focus == p then jd.focus = ST._prevFocus; pcall(updateJoypadFocus, jd) end
    ST._prevFocus = nil
end

--- True while the studio is open.
function ST.isOpen() return ST.room ~= nil end

-- ---------------------------------------------------------------------------
-- THE CAMERA BUTTON in the ID photo's corner (ZeD_CharacterWindow places it over the figure)
-- ---------------------------------------------------------------------------
-- a small camera in whole units: the body, the viewfinder's bump, the lens
local CAM = { "....###.....", "############", "#..........#", "#...####...#", "#..#....#..#", "#..#....#..#",
              "#...####...#", "#..........#", "############" }
ST.CAM = CAM

--- The camera button for win (a ZeD_Panel; win._playerObj is whose figure it shows).
function ST.newCamButton(win)
    local T = ZeD.T
    local s = T.px(18)
    local b = ZeD_Panel:new(0, 0, s, s)
    b.anchorRight, b.anchorBottom = false, false
    b:initialise()
    b:setVisible(false)
    b.prerender = function(self)
        local T2 = ZeD.T
        local on = ST.available()
        local over = self:isMouseOver()
        local bg = T2.surf2
        self:drawRect(0, 0, self.width, self.height, 0.85, bg.r, bg.g, bg.b)
        if over and on then local h = T2.hover; self:drawRect(0, 0, self.width, self.height, h.a or 0.2, h.r, h.g, h.b) end
        local bs = T2.borderS
        self:drawRectBorder(0, 0, self.width, self.height, 1, bs.r, bs.g, bs.b)
        local u = math.max(1, math.floor(self.width / 18))
        local gw, gh = #CAM[1] * u, #CAM * u
        local ox, oy = math.floor((self.width - gw) / 2), math.floor((self.height - gh) / 2)
        local c = on and T2.text or T2.textDim
        local a = on and 1 or (T2.disabledAlpha or 0.4)
        for r, row in ipairs(CAM) do
            for i = 1, #row do
                if row:sub(i, i) == "#" then self:drawRect(ox + (i - 1) * u, oy + (r - 1) * u, u, u, a, c.r, c.g, c.b) end
            end
        end
        if over and ZeD.Help then ZeD.Help.set(self, on and tr("UI_ZeD_Studio_Title") or tr("UI_ZeD_Studio_OnlySP")) end
    end
    b.onMouseDown = function() return true end
    b.onMouseUp = function(self)
        if ST.available() and win._playerObj then
            pcall(function() getSoundManager():playUISound("UIActivateButton") end)
            ST.open(win._playerObj)
        end
        return true
    end
    return b
end
