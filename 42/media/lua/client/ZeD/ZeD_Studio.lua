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
-- height over a plain seamless backdrop. Drag the figure to turn it (the model's own drag), the wheel or the three
-- framings (full body, three-quarter, bust: the ID photo's two framings and one between) to frame it, two buttons to
-- turn it a step. Opening it pauses the game and hides the game's "Game Paused" box (as the Survival Guide book does);
-- leaving puts the speed back as it was. Take photo draws one frame with nothing but the backdrop and the figure, takes
-- the game's screenshot of it (Zomboid/Screenshots) after that frame, then flashes and names the file.
-- The controller: A takes the photo, B leaves, LB and RB turn, Up and Down frame.
-- Poses wait for the probe (ZeDUI/tools/qa/zedqa_studio_probe.lua).
-- ============================================================================

require "ISUI/ISUI3DModel"

ZeD = ZeD or {}
ZeD.Studio = ZeD.Studio or {}
local ST = ZeD.Studio

local function tr(k, ...) return ZeD.tr(k, ...) end
-- the two framings the ID photo uses (ZeD_CharacterWindow: full body zoom 0, y 0; the bust 19, -0.875)
local BUST_ZOOM, BUST_Y = 19, -0.875
local FRAMES = { { key = "UI_ZeD_Studio_Full", t = 0 }, { key = "UI_ZeD_Studio_ThreeQ", t = 0.55 }, { key = "UI_ZeD_Studio_Bust", t = 1 } }
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
        self.fig:setZoom(BUST_ZOOM * t)
        self.fig:setYOffset(BUST_Y * t)
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

local function drawPaper(p, L)
    -- a vertical sweep in strips: the paper darkening to its top, lighter where it curves into the floor
    local n = 48
    for i = 0, n - 1 do
        local f = i / (n - 1)
        local c = { r = PAPER_TOP.r + (PAPER_LOW.r - PAPER_TOP.r) * f, g = PAPER_TOP.g + (PAPER_LOW.g - PAPER_TOP.g) * f,
                    b = PAPER_TOP.b + (PAPER_LOW.b - PAPER_TOP.b) * f }
        local y0 = L.by + math.floor(L.bh * i / n)
        local y1 = L.by + math.floor(L.bh * (i + 1) / n)
        p:drawRect(L.bx, y0, L.bw, y1 - y0, 1, c.r, c.g, c.b)
    end
end

function ZeD_StudioRoom:prerender()
    local T = ZeD.T
    local L = self:layout()
    -- the room: dark, the paper lit
    local base = T.base
    self:drawRect(0, 0, self.width, self.height, 1, base.r * 0.6, base.g * 0.6, base.b * 0.6)
    drawPaper(self, L)
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
    for i, fr in ipairs(FRAMES) do button("frame:" .. i, tr(fr.key), math.abs(self.t - fr.t) < 0.01) end
    x = x + T.px(12)
    button("turn:-1", tr("UI_ZeD_Studio_TurnL"))
    button("turn:1", tr("UI_ZeD_Studio_TurnR"))
    x = x + T.px(12)
    button("photo", tr("UI_ZeD_Studio_Photo"))
    button("leave", tr("UI_ZeD_Studio_Leave"))
    -- the help line, or what the last photo was saved as
    local msg = self.saved and tr("UI_ZeD_Studio_Saved", self.saved) or tr("UI_ZeD_Studio_Help")
    local tc = T.textSec or T.textDim
    local room = self.width - x - T.px(GAP) * 2
    if room > T.px(40) then
        local s = ZeD.Atoms.truncateText(msg, f, room)
        self:drawText(s, x + T.px(GAP), y0 + math.floor((L.bar - ZeD.TM:getFontHeight(f)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f)
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
    local z = self:hitZoneAt(x, y)
    if not z then return true end
    local id = tostring(z.id)
    if id:sub(1, 6) == "frame:" then self:frameTo(FRAMES[tonumber(id:sub(7))].t)
    elseif id:sub(1, 5) == "turn:" then self:turn(tonumber(id:sub(6)))
    elseif id == "photo" then self:photo()
    elseif id == "leave" then ST.close() end
    pcall(function() getSoundManager():playUISound("UIActivateButton") end)
    return true
end
function ZeD_StudioRoom:onMouseWheel(del) self:frameBy(del * 0.08); return true end

--- Take a photo: the next frame draws clean, the shot is taken after it (ST's OnPostUIDraw), then the flash.
function ZeD_StudioRoom:photo()
    if self.shoot then return end
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
    elseif button == Joypad.RBumper then self:turn(1) end
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
