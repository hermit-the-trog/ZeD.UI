-- ZeDUI/tools/qa/studio_sim.lua  (Nov 10 2026, Build; punch list 145, the portrait studio's room)
-- With no game running, the real ZeD_Studio.lua runs on stubs (a panel class, the 3D figure, the game's speed, its
-- paused box, the screenshot). It checks:
--   OPEN     single player only (in multiplayer it doesn't open); opening pauses the game and hides the paused box;
--            the figure is the character's, idle, facing south, at full body
--   FRAME    the framings: full body (zoom 0, y 0), the bust (19, -0.875, the ID photo's), three-quarter between;
--            the wheel frames by steps, never past either end
--   TURN     the turn buttons step the figure's direction
--   PHOTO    Take photo: the controls go for the clean frames, the game's screenshot is taken after the second, one
--            more clean frame, then the flash, the file's name, and the controls back
--   LEAVE    leaving puts the speed back as it was (paused stays paused) and the paused box as it was; Escape leaves
--   CAMERA   the ID photo's camera button opens the studio; in multiplayer it says why it can't
--   WIRED    the Character window adds the camera button over the figure and places it in the photo's corner
-- Run from the repo root:  lua51 ZeDUI/tools/qa/studio_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]studio_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end

-- ---------------------------------------------------------------------------
-- STUBS
-- ---------------------------------------------------------------------------
local W = { client = false, speed = 1, pausedBox = true, shots = {}, now = 1000, ui = {}, help = nil }
isClient = function() return W.client end
getGameSpeed = function() return W.speed end
setGameSpeed = function(v) W.speed = v end
UIManager = { isShowPausedMessage = function() return W.pausedBox end, setShowPausedMessage = function(v) W.pausedBox = v end }
getCore = function() return { getScreenWidth = function() return 1920 end, getScreenHeight = function() return 1080 end,
                               TakeFullScreenshot = function(_, n) W.shots[#W.shots + 1] = n end } end
getTimestampMs = function() return W.now end
getSoundManager = function() return { playUISound = function() end } end
Keyboard = { KEY_ESCAPE = 1 }
GameKeyboard = { eatKeyPress = function() end }
Joypad = { AButton = 0, BButton = 1, LBumper = 4, RBumper = 5 }
JoypadState = { players = {} }
updateJoypadFocus = function() end
require = function() end
local postUI = {}
Events = { OnPostUIDraw = { Add = function(fn) postUI[#postUI + 1] = fn end } }
local function afterDraw() for _, fn in ipairs(postUI) do fn() end end
-- the figure's directions: 8 steps
local DIRS = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }
local function dir(i)
    local d = { i = i, name = DIRS[i] }
    function d:RotLeft() return dir((self.i + 6) % 8 + 1) end
    function d:RotRight() return dir(self.i % 8 + 1) end
    return d
end
IsoDirections = { S = dir(5) }
-- a panel class enough for ZeD_Panel's derive
local Panel = {}
Panel.__index = Panel
function Panel:derive(name) local c = setmetatable({}, { __index = self }); c.__index = c; c.Type = name; return c end
function Panel:new(x, y, w, h)
    local o = setmetatable({ x = x, y = y, width = w, height = h, visible = true, children = {}, _hitZones = {}, draws = 0 }, self)
    return o
end
function Panel:initialise() end
function Panel:instantiate() if self.createChildren then self:createChildren() end end
function Panel:addToUIManager() W.ui[self] = true end
function Panel:removeFromUIManager() W.ui[self] = nil end
function Panel:setAlwaysOnTop(v) self.onTop = v end
function Panel:bringToTop() end
function Panel:setVisible(v) self.visible = v end
function Panel:isVisible() return self.visible end
function Panel:addChild(c) self.children[#self.children + 1] = c end
function Panel:setWantKeyEvents(v) self.keys = v end
function Panel:setX(v) self.x = v end
function Panel:setY(v) self.y = v end
function Panel:setWidth(v) self.width = v end
function Panel:setHeight(v) self.height = v end
function Panel:getMouseX() return W.mx or 0 end
function Panel:getMouseY() return W.my or 0 end
function Panel:isMouseOver() return W.over == self end
function Panel:drawRect() self.draws = self.draws + 1 end
function Panel:drawRectBorder() self.draws = self.draws + 1 end
function Panel:drawText() self.draws = self.draws + 1 end
function Panel:clearHitZones() self._hitZones = {} end
function Panel:addHitZone(id, x, y, w, h) self._hitZones[#self._hitZones + 1] = { id = id, x = x, y = y, w = w, h = h } end
function Panel:hitZoneAt(mx, my)
    for _, z in ipairs(self._hitZones) do if mx >= z.x and mx < z.x + z.w and my >= z.y and my < z.y + z.h then return z end end
end
ZeD_Panel = Panel
ISUI3DModel = {}
ISUI3DModel.__index = ISUI3DModel
function ISUI3DModel:new(x, y, w, h) return setmetatable({ x = x, y = y, width = w, height = h }, ISUI3DModel) end
function ISUI3DModel:initialise() end
function ISUI3DModel:instantiate() end
function ISUI3DModel:setCharacter(c) self.chr = c end
function ISUI3DModel:setState(s) self.state = s end
function ISUI3DModel:setDirection(d) self.dir = d end
function ISUI3DModel:getDirection() return self.dir end
function ISUI3DModel:setIsometric(v) self.iso = v end
function ISUI3DModel:setDoRandomExtAnimations(v) self.ext = v end
function ISUI3DModel:setZoom(z) self.zoom = z end
function ISUI3DModel:setYOffset(y) self.yoff = y end
function ISUI3DModel:setX(v) self.x = v end
function ISUI3DModel:setY(v) self.y = v end
function ISUI3DModel:setWidth(v) self.width = v end
function ISUI3DModel:setHeight(v) self.height = v end
ZeD = { tr = function(k, a) return a and (k .. "(" .. a .. ")") or k end,
        T = { px = function(v) return v end, base = { r = 0, g = 0, b = 0 }, surf2 = { r = 0.1, g = 0.1, b = 0.1 },
              borderS = { r = 0.3, g = 0.3, b = 0.3 }, text = { r = 1, g = 1, b = 1 }, textDim = { r = 0.5, g = 0.5, b = 0.5 },
              textSec = { r = 0.6, g = 0.6, b = 0.6 }, hover = { r = 1, g = 1, b = 1, a = 0.2 }, fontF2 = "F2" },
        TM = { MeasureStringX = function(_, _, s) return #tostring(s) * 7 end, getFontHeight = function() return 15 end },
        Molecules = { drawButton = function(p) p.draws = p.draws + 1 end },
        Atoms = { truncateText = function(s) return s end },
        Help = { set = function(_, t) W.help = t end } }

local f, err = loadfile(ROOT .. "42/media/lua/client/ZeD/ZeD_Studio.lua")
if not f then print("studio_sim: " .. tostring(err)); os.exit(1) end
f()
local ST = ZeD.Studio
local CHR = { getPlayerNum = function() return 0 end }

-- ---------------------------------------------------------------------------
-- OPEN
-- ---------------------------------------------------------------------------
W.client = true
check("OPEN: not in multiplayer", ST.available() == false and ST.open(CHR) == false and not ST.isOpen())
W.client = false
W.speed = 2
check("OPEN: in single player it opens", ST.open(CHR) == true and ST.isOpen())
local room = ST.room
check("OPEN: the game paused", W.speed == 0, W.speed)
check("OPEN: the game's paused box hidden", W.pausedBox == false)
check("OPEN: on top of everything", W.ui[room] and room.onTop == true)
local fig = room.fig
check("OPEN: the character's figure, idle, facing south", fig and fig.chr == CHR and fig.state == "idle" and fig.dir.name == "S")
check("OPEN: at full body", fig.zoom == 0 and fig.yoff == 0)

-- ---------------------------------------------------------------------------
-- FRAME, TURN
-- ---------------------------------------------------------------------------
room:frameTo(1)
check("FRAME: the bust is the ID photo's", fig.zoom == 19 and math.abs(fig.yoff + 0.875) < 1e-9, fig.zoom)
room:frameTo(0.55)
check("FRAME: three-quarter between", math.abs(fig.zoom - 19 * 0.55) < 1e-9)
room:frameTo(0)
for _ = 1, 30 do room:onMouseWheel(-1) end
check("FRAME: the wheel stops at full body", room.t == 0, room.t)
for _ = 1, 30 do room:onMouseWheel(1) end
check("FRAME: and at the bust", room.t == 1, room.t)
room:frameTo(0)
room:turn(1)
check("TURN: a step right", fig.dir.name == "SW", fig.dir.name)
room:turn(-1); room:turn(-1)
check("TURN: two steps left", fig.dir.name == "SE", fig.dir.name)

-- ---------------------------------------------------------------------------
-- PHOTO
-- ---------------------------------------------------------------------------
room:prerender()
local zones0 = #room._hitZones
check("PHOTO: the controls are there before", zones0 >= 7, zones0)
-- the photo button's place: press it
local photoZ
for _, z in ipairs(room._hitZones) do if z.id == "photo" then photoZ = z end end
check("PHOTO: a Take photo button", photoZ ~= nil)
room:onMouseUp(photoZ.x + 2, photoZ.y + 2)
room:prerender()
check("PHOTO: the first frame after the press is clean", #room._hitZones == 0, #room._hitZones)
afterDraw()
check("PHOTO: no shot yet", #W.shots == 0)
room:prerender()
check("PHOTO: the second frame clean too", #room._hitZones == 0)
afterDraw()
check("PHOTO: the shot after it", #W.shots == 1 and W.shots[1]:match("^zed_portrait_%d+%.png$"), W.shots[1])
room:prerender()
check("PHOTO: one more clean frame", #room._hitZones == 0)
afterDraw()
check("PHOTO: then the flash and the file's name", room.flashAt ~= nil and room.saved == W.shots[1])
room:prerender()
check("PHOTO: the controls back", #room._hitZones == zones0, #room._hitZones)
afterDraw()
check("PHOTO: one shot a press", #W.shots == 1)

-- ---------------------------------------------------------------------------
-- LEAVE
-- ---------------------------------------------------------------------------
check("LEAVE: Escape is the studio's", room:isKeyConsumed(Keyboard.KEY_ESCAPE) == true)
room:onKeyPress(Keyboard.KEY_ESCAPE)
check("LEAVE: Escape leaves", not ST.isOpen() and not W.ui[room])
check("LEAVE: the speed as it was (2)", W.speed == 2, W.speed)
check("LEAVE: the paused box as it was", W.pausedBox == true)
W.speed = 0
ST.open(CHR)
ST.close()
check("LEAVE: a game paused before stays paused", W.speed == 0, W.speed)
W.speed = 1

-- ---------------------------------------------------------------------------
-- CAMERA
-- ---------------------------------------------------------------------------
local win = { _playerObj = CHR }
local cam = ST.newCamButton(win)
check("CAMERA: hidden until the ID photo shows", cam.visible == false)
W.over = cam
W.client = true
cam:prerender()
check("CAMERA: in multiplayer it says why it can't", W.help == "UI_ZeD_Studio_OnlySP", W.help)
cam:onMouseUp(1, 1)
check("CAMERA: and doesn't open", not ST.isOpen())
W.client = false
cam:prerender()
check("CAMERA: in single player it names the studio", W.help == "UI_ZeD_Studio_Title", W.help)
cam:onMouseUp(1, 1)
check("CAMERA: a press opens the studio", ST.isOpen())
ST.close()

-- ---------------------------------------------------------------------------
-- WIRED
-- ---------------------------------------------------------------------------
local fh = io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_CharacterWindow.lua", "rb"); local cw = fh:read("*a"); fh:close()
local addModel = cw:find("win:addChild(identityModel)", 1, true)
local addCam = cw:find("win:addChild(cam)", 1, true)
check("WIRED: the camera button added after the figure (over it)", addModel and addCam and addCam > addModel)
check("WIRED: placed in the photo's corner", cw:find("cam:setX(identityModel.x + identityModel.width - s - T.px(4))", 1, true) ~= nil)
check("WIRED: shown with the ID photo only", cw:find('local camOn = showAvatar and win._activeTab == "identity" or false', 1, true) ~= nil)

local fp = io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_PausedLook.lua", "rb"); local pl = fp:read("*a"); fp:close()
check("WIRED: paused, the glass leaves the camera button bright", pl:find("local cx, cy, cw, ch = camRect(self)", 1, true) ~= nil)
check("WIRED: paused, a press on the camera button reaches it", pl:find("if cam.onMouseUp then cam:onMouseUp(x - cx, y - cy) end", 1, true) ~= nil)

print("studio_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
