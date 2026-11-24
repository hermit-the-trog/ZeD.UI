-- ZeDUI/tools/qa/chat_window_sim.lua: the chat window's place, width, roll down, pin and ghost (the director, Nov 23
-- 2026), with no game running. Lua 5.1 stubs of a panel and the game's calls; ZeD's REAL ZeD_Chat.lua, and the real
-- window shade, window box and surface swap cut from Organisms.lua.
--   PLACE   the first place: its foot on the screen's foot, its left edge an icon's gap right of the belt's chat key
--           (past the PvP marker after it), on the screen; no belt or no key: the old place low on the left; 360 wide
--   SAVED   an old line (no "v2") is no place, once; a v2 line is used; the save writes v2 with rolled and pinned
--   ROLL    roll down keeps the title bar at the old foot; roll up gives the height back in place; a line while rolled
--           counts on the chat key and the window stays down; the chat key (T) brings it up and empties the count;
--           a press on the rolled bar brings it up, a drag does not; the roll box both ways; the pad's X rolls it and
--           lets the pad go
--   PIN     the belt's key rolls a pinned window down and up, closes an unpinned one; Escape: pinned it stays,
--           unpinned it closes; the close unpins; the saved place keeps rolled and pinned, and a pinned window comes
--           back by itself, rolled as it was
--   GHOST   pinned, the pointer off: the surfaces and lines at 0.15, the words whole (alpha 1, edged); the pointer on
--           or typing: full; unpinned keeps the idle dim (0.35 in Dark)
-- Run from the repo root:  lua51 ZeDUI/tools/qa/chat_window_sim.lua
-- It prints FAIL lines and a last line "chat_window_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]chat_window_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end
-- a function's source from "function NAME" at a line's start to the first "end" at a line's start
local function cutFn(src, head)
    local a = src:find("\n" .. head, 1, true)
    if not a then return nil end
    local b = src:find("\nend", a + 1, true)
    return src:sub(a + 1, b + 4)
end

-- the game's calls --------------------------------------------------------------------------
local nowMs = 1000000
function getTimestampMs() return nowMs end
local SW, SH = 1920, 1080
function getCore() return { getScreenWidth = function() return SW end, getScreenHeight = function() return SH end } end
function isClient() return true end
function getText(k) return k end
local MX, MY = 0, 0
function getMouseX() return MX end
function getMouseY() return MY end
local FILES = {}
function getFileWriter(name)
    local buf = {}
    return { write = function(_, s) buf[#buf + 1] = s end, close = function() FILES[name] = table.concat(buf) end }
end
function getFileReader(name)
    local body = FILES[name]
    if not body then return nil end
    local done = false
    return { readLine = function() if done then return nil end; done = true; return (body:match("^[^\n]*")) end, close = function() end }
end
local padFocus = {}
function setJoypadFocus(pn, c) padFocus[pn] = c or false end
function getPlayer() return { getUsername = function() return "me" end } end
Keyboard = { KEY_ESCAPE = 1 }
local eaten = 0
GameKeyboard = { eatKeyPress = function() eaten = eaten + 1 end }
Joypad = { AButton = 1, BButton = 2, XButton = 3, YButton = 4 }
JoypadState = { players = {} }
ISChat = {}
local realRequire = require
require = function() end

-- ZeD's tables ------------------------------------------------------------------------------
local function col(r, g, b, a) return { r = r, g = g, b = b, a = a or 1 } end
ZeD = {}
ZeD.T = {
    scale = 1, px = function(n) return n end, line = function(n) return n end, hair = 1, borderW = 1,
    sp = { sm = 10, md = 14, titleBoxPad = 3, tabPadX = 14 },
    titleBarH = 26, closeBoxSz = 13, minWinH = 220, minWinW = 360, tabH = 24, inputH = 26, buttonH = 26,
    fontF2 = "F2", fontF3 = "F3",
    base = col(0.1, 0.1, 0.1), surf1 = col(0.15, 0.15, 0.15), surf2 = col(0.2, 0.2, 0.2), surf3 = col(0.25, 0.25, 0.25),
    surf4 = col(0.3, 0.3, 0.3), border = col(0.4, 0.4, 0.4), borderS = col(0.5, 0.5, 0.5, 0.9),
    text = col(0.9, 0.9, 0.9), textHead = col(1, 1, 1), textDim = col(0.6, 0.6, 0.6), textOnFocus = col(0, 0, 0),
    accent = col(1, 0.6, 0.2), hover = col(1, 1, 1, 0.1),
}
ZeD.TM = { MeasureStringX = function(_, f, s) return #tostring(s) * 7 end, getFontHeight = function() return 14 end }
ZeD.tr = function(k, ...) return k end
local SEE = true
ZeD.seeThroughWorks = function() return SEE end
ZeD.logOnce = function(k, e) print("LOG " .. tostring(k) .. " " .. tostring(e)) end
ZeD.uiSound = function() end
ZeD.Atoms = {
    wrapText = function(s) return { s } end,
    mouseIn = function() return false end,
    frame = function() end,
    drawTriangleUp = function() end, drawTriangleDown = function() end,
    drawStatusDot = function() end,
    textCase = function(s) return s end,
}
ZeD.Molecules = { drawEmptyLine = function() end }

-- the belt's row: its chat key at 500 in a panel at 600
local HUD = { _boxes = {}, visible = true, ax = 600 }
function HUD:getIsVisible() return self.visible end
function HUD:getAbsoluteX() return self.ax end
function HUD:getAbsoluteY() return (SH or 1080) - 50 end   -- (the row 50 high at the screen's foot)
local hudOn = true
ZeD.Belt = { ICON_GAP = 38, getHUD = function() return hudOn and HUD or nil end }

-- the panel and the window --------------------------------------------------------------------
local function newInput()
    local i = { vis = true, foc = false, text = "" }
    function i:isVisible() return self.vis end
    function i:setVisible(v) self.vis = v end
    function i:isFocused() return self.foc end
    function i:focus() self.foc = true end
    function i:unfocus() self.foc = false end
    function i:getText() return self.text end
    function i:setText(t) self.text = t end
    return i
end
ZeD_Window = {}
ZeD_Window.__index = ZeD_Window
function ZeD_Window:derive(name)
    local o = {}
    setmetatable(o, self)
    o.__index = o
    o.Type = name
    return o
end
function ZeD_Window.new(self, x, y, w, h, title)
    local o = { x = x, y = y, width = w, height = h, title = title, visible = true, children = {} }
    setmetatable(o, self)
    self.__index = self
    o.windowShaded = false
    o._closeBtnRect = {}
    return o
end
function ZeD_Window:getX() return self.x end
function ZeD_Window:getY() return self.y end
function ZeD_Window:setX(v) self.x = v end
function ZeD_Window:setY(v) self.y = v end
function ZeD_Window:getWidth() return self.width end
function ZeD_Window:getHeight() return self.height end
function ZeD_Window:setWidth(v) self.width = v end
function ZeD_Window:setHeight(v) self.height = v end
function ZeD_Window:getIsVisible() return self.visible end
function ZeD_Window:setVisible(v) self.visible = v end
function ZeD_Window:isMouseOver() return self.mouseOver == true end
function ZeD_Window:getChildren() return self.children end
function ZeD_Window:setMaxDrawHeight(h) self.maxDrawH = h end
function ZeD_Window:clearMaxDrawHeight() self.maxDrawH = nil end
function ZeD_Window:titleBarHeight() return ZeD.T.titleBarH end
function ZeD_Window:footerHeight() return 22 end
function ZeD_Window:closeRect() return nil end
function ZeD_Window:initialise() end
function ZeD_Window:instantiate() self.input = newInput(); self.children = { self.input } end
function ZeD_Window:addToUIManager() end
function ZeD_Window:removeFromUIManager() self.removed = true end
function ZeD_Window:setAlwaysOnTop() end
function ZeD_Window:setWantKeyEvents() end
function ZeD_Window:bringToTop() end
function ZeD_Window:_watchBoxes() end
function ZeD_Window:onMouseDown(x, y) self.moving = true; return true end
function ZeD_Window:onMouseUp() self.moving = false end
function ZeD_Window:onMouseUpOutside() self.moving = false end
function ZeD_Window:update() end
function ZeD_Window:prerender() end
function ZeD_Window:render() end
function ZeD_Window:setStencilRect() end
function ZeD_Window:clearStencilRect() end
function ZeD_Window:getMouseX() return -1 end
function ZeD_Window:getMouseY() return -1 end
local drawn = {}
function ZeD_Window:drawText(s, x, y, r, g, b, a, f) drawn[#drawn + 1] = { s = s, x = x, y = y, r = r, g = g, b = b, a = a } end
function ZeD_Window:drawRect() end
function ZeD_Window:drawRectBorder() end

-- the real ones from Organisms.lua
local org = readFile(CLIENT .. "Organisms.lua") or ""
local cut = { "function ZeD_Window:setWindowShaded(shaded)", "function ZeD_Window:shownHeight()", "function ZeD_Window:_swapSurfaces()",
    "function ZeD_Window:_restoreSurfaces()", "function ZeD_Window:windowBoxRect()", "function ZeD_Window:_surfaceAlpha(T)" }
local code = "local SURF_KEYS = { \"base\", \"surf1\", \"surf2\", \"surf3\", \"surf4\" }\nlocal SOLID_MS = 200\n"
local allCut = true
for _, h in ipairs(cut) do
    local s = cutFn(org, h)
    if not s then allCut = false; print("not found: " .. h) else code = code .. s .. "\n" end
end
check("Organisms.lua's shade, window box and surface swap are there to cut", allCut)
local chunk, err = loadstring(code, "organisms_cut")
check("and they load", chunk ~= nil, err)
if chunk then chunk() end

-- ZeD_Chat.lua itself
local ok, e = pcall(dofile, CLIENT .. "ZeD_Chat.lua")
check("ZeD_Chat.lua loads on the stubs", ok, e)
require = realRequire
local C = ZeD.Chat

local function fresh()
    if C.win then C.win = nil end
    C.unreadN = 0
    C._savedPlace = nil
    C._openRolled = nil
    C._pinChecked = nil
    C.tab = "general"
end

-- PLACE --------------------------------------------------------------------------------------
HUD._boxes = { { kind = "bag", x = 0, y = 0, w = 38, h = 38 }, { kind = "chat", x = 500, y = 0, w = 38, h = 38 } }
fresh(); FILES = {}
local w = C.open(false)
check("PLACE: opens", w ~= nil)
check("PLACE: 360 wide, 260 high", w.width == 360 and w.height == 260, tostring(w.width) .. "x" .. tostring(w.height))
check("PLACE: its foot on the screen's foot", w.y + w.height == SH, w.y)
check("PLACE: its left edge an icon's gap right of the chat key", w.x == 600 + 500 + 38 + 38, w.x)
w:close()
HUD.ax = 1700
fresh(); FILES = {}
w = C.open(false)
check("PLACE: on the screen when the key is far right", w.x == SW - 360, w.x)
-- (QA, Nov 23 2026) pushed back over the row, it stands on the row: its foot above the row's top
check("PLACE: pushed over the belt row, its foot above the row", w.y + w.height <= SH - 50, w.y)
w:close()
HUD.ax = 600
HUD._boxes[3] = { kind = "pvp", x = 560, y = 0, w = 90, h = 30 }
fresh(); FILES = {}
w = C.open(false)
check("PLACE: past the PvP marker right after the key", w.x == 600 + 560 + 90 + 38, w.x)
w:close()
HUD._boxes[3] = nil
hudOn = false
fresh(); FILES = {}
w = C.open(false)
check("PLACE: no belt: the old place, low on the left", w.x == 15 and w.y == SH - 260 - 140, tostring(w.x) .. "," .. tostring(w.y))
w:close()
hudOn = true
HUD._boxes = { { kind = "bag", x = 0, y = 0, w = 38, h = 38 } }
fresh(); FILES = {}
w = C.open(false)
check("PLACE: no chat key: the old place", w.x == 15, w.x)
w:close()
HUD._boxes = { { kind = "chat", x = 500, y = 0, w = 38, h = 38 } }

-- SAVED --------------------------------------------------------------------------------------
fresh(); FILES = { ["ZeD_chatwin.txt"] = "100 200 440 260 private" }
w = C.open(false)
check("SAVED: an old line is no place: the new first place", w.x == 1176 and w.y == SH - 260 and C.tab == "general", tostring(w.x) .. " " .. C.tab)
C.savePlace(w)
check("SAVED: the save writes v2 with rolled and pinned", FILES["ZeD_chatwin.txt"] == "v2 1176 820 360 260 general 0 0", FILES["ZeD_chatwin.txt"])
w:close()
fresh(); FILES = { ["ZeD_chatwin.txt"] = "v2 50 60 400 300 private 0 0" }
w = C.open(false)
check("SAVED: a v2 line is used", w.x == 50 and w.y == 60 and w.width == 400 and w.height == 300 and C.tab == "private",
    tostring(w.x) .. "," .. tostring(w.y) .. " " .. tostring(w.width) .. "x" .. tostring(w.height) .. " " .. C.tab)
w:close()

-- ROLL ---------------------------------------------------------------------------------------
fresh(); FILES = {}
w = C.open(false)
local x0, y0, h0 = w.x, w.y, w.height
w:setWindowShaded(true)
check("ROLL: down: the title bar alone", w.windowShaded and w.height == 26)
check("ROLL: its bar's foot where the window's foot was", w.y + w.height == y0 + h0, w.y)
check("ROLL: the line to type in hidden", w.input.vis == false)
check("ROLL: the save keeps the whole window and rolled", FILES["ZeD_chatwin.txt"] == "v2 1176 820 360 260 general 1 0", FILES["ZeD_chatwin.txt"])
C.serverLine("The server restarts at 4.")
check("ROLL: a line while down counts on the chat key", C.unread() == 1)
check("ROLL: and the window stays down", w.windowShaded)
w:setWindowShaded(false)
check("ROLL: up: the whole height back, in place", not w.windowShaded and w.height == h0 and w.y == y0 and w.x == x0, tostring(w.y) .. " " .. tostring(w.height))
check("ROLL: up: the count goes", C.unread() == 0)
check("ROLL: up: the line to type in back", w.input.vis == true)
w:setWindowShaded(true)
C.serverLine("again")
C.open(true)
check("ROLL: the chat key (T) brings it up and into the line", not w.windowShaded and w.input.foc and C.unread() == 0)
-- the roll box
w.input.foc = false
w:_drawRollBox(26)
local rr = w._rollRect
check("ROLL: the roll box sits after the title", rr and rr.x > 10 + 13 and rr.y >= 0 and rr.w == 13)
w:onMouseDown(rr.x + 2, rr.y + 2)
check("ROLL: the roll box rolls it down", w.windowShaded)
w:onMouseDown(rr.x + 2, rr.y + 2)
check("ROLL: and up", not w.windowShaded and w.y == y0)
-- a press on the rolled bar
w:setWindowShaded(true)
MX, MY = 1300, 1060
w:onMouseDown(150, 10)
w:onMouseUp(150, 10)
check("ROLL: a press on the rolled bar brings it up", not w.windowShaded and w.y == y0)
w:setWindowShaded(true)
w:onMouseDown(150, 10)
MX, MY = 1200, 1000
w:onMouseUp(150, 10)
check("ROLL: a drag of the rolled bar does not", w.windowShaded)
w:setWindowShaded(false)
-- the pad's X
JoypadState.players[1] = { focus = w }
w.joyfocus = JoypadState.players[1]
padFocus = {}
w:onJoypadDown(Joypad.XButton, w.joyfocus)
check("ROLL: the pad's X rolls it down", w.windowShaded)
check("ROLL: and the pad goes back to the game", padFocus[0] == false and w.joyfocus == nil)
JoypadState.players[1] = nil
w.joyfocus = { }
local P = w:getFooterPrompts() or {}
local hasX = false
for _, p in ipairs(P) do if p.glyph == "X" and p.label == "UI_ZeD_Chat_PadRollDown" then hasX = true end end
check("ROLL: the pad's prompts say X Roll down", hasX)
w.joyfocus = nil
w:close()

-- PIN ----------------------------------------------------------------------------------------
fresh(); FILES = {}
w = C.open(false)
w.pinned = true
C.toggle()
check("PIN: the belt's key rolls a pinned window down", C.win == w and w.windowShaded and w:getIsVisible())
C.toggle()
check("PIN: and brings it up", C.win == w and not w.windowShaded)
eaten = 0
check("PIN: Escape is the game's while not typing", w:isKeyConsumed(Keyboard.KEY_ESCAPE) == false)
w:onKeyPress(Keyboard.KEY_ESCAPE)
check("PIN: Escape leaves it open", C.win == w and w:getIsVisible() and eaten == 0)
w.input.foc = true
check("PIN: typing, Escape is the window's", w:isKeyConsumed(Keyboard.KEY_ESCAPE) == true)
w:onKeyPress(Keyboard.KEY_ESCAPE)
check("PIN: and only leaves the line", C.win == w and not w.input.foc and eaten == 1)
-- the saved place keeps rolled and pinned; a pinned window comes back by itself
w:setWindowShaded(true)
C.savePlace(w)
check("PIN: the save keeps rolled and pinned", FILES["ZeD_chatwin.txt"] == "v2 1176 820 360 260 general 1 1", FILES["ZeD_chatwin.txt"])
local _, _, _, _, _, rolled, pinned = C._readPlace()
check("PIN: read back rolled and pinned", rolled == true and pinned == true)
C.win = nil   -- (the player left with it pinned: no close)
C._pinChecked = nil
C.tick()
local back = C.win
check("PIN: a pinned window comes back by itself", back ~= nil and back.pinned == true)
check("PIN: rolled as it was, its bar at the foot", back and back.windowShaded and back.y + back.height == SH, back and back.y)
-- the close box unpins
back:close()
check("PIN: the close unpins and saves it", C.win == nil and FILES["ZeD_chatwin.txt"]:sub(-2) == " 0", FILES["ZeD_chatwin.txt"])
fresh()
w = C.open(false)
check("PIN: the key brings a rolled window up when opened", not w.windowShaded)
check("PIN: unpinned, Escape is the window's", w:isKeyConsumed(Keyboard.KEY_ESCAPE) == true)
C.toggle()
check("PIN: unpinned, the belt's key closes it", C.win == nil)

-- GHOST --------------------------------------------------------------------------------------
fresh(); FILES = {}
w = C.open(false)
w.pinned = true
w.mouseOver = false
check("GHOST: pinned, the pointer off: ghosted", w:_ghostNow() == true)
w.mouseOver = true
check("GHOST: the pointer on: not", w:_ghostNow() == false)
w.mouseOver = false
w.input.foc = true
check("GHOST: typing: not", w:_ghostNow() == false)
w.input.foc = false
w.joyfocus = {}
check("GHOST: the pad on it: not", w:_ghostNow() == false)
w.joyfocus = nil
local T = ZeD.T
local s1, bs = T.surf1, T.borderS
w._ghost = true
w:_swapSurfaces()
check("GHOST: the surfaces at 0.15", T.surf1.a == 0.15 and T.surf2.a == 0.15 and T.base.a == 0.15, T.surf1.a)
check("GHOST: the lines at 0.15 of their own", math.abs(T.borderS.a - 0.9 * 0.15) < 1e-9 and math.abs(T.border.a - 0.15) < 1e-9, T.borderS.a)
check("GHOST: the words' colors untouched", T.text.a == 1 and T.textHead.a == 1)
w:_restoreSurfaces()
check("GHOST: all back after the draw", T.surf1 == s1 and T.borderS == bs and T.surf1.a == 1)
-- the words, drawn ghosted: whole (alpha 1) with an edge
C.lines = { { text = "anyone seen my truck", author = "Kade_R", kind = "say" }, { text = "The server restarts at 4.", kind = "server" } }
drawn = {}
w:_drawLines(10, 40, 300, 150)
local whole, edged, faint = 0, 0, 0
for _, d in ipairs(drawn) do
    if d.a == 1 then whole = whole + 1 elseif d.a == 0.85 then edged = edged + 1 else faint = faint + 1 end
end
check("GHOST: every word drawn whole, each with its four-way edge", whole >= 3 and edged == whole * 4 and faint == 0,
    whole .. " whole, " .. edged .. " edge, " .. faint .. " faint")
local lightEdge = false
for _, d in ipairs(drawn) do if d.a == 0.85 and d.r == 0 then lightEdge = true end end
check("GHOST: light words get a dark edge", lightEdge)
drawn = {}
C.inkText(w, "hi", 0, 0, col(0.1, 0.1, 0.1), "F2")
check("GHOST: dark words (Light) get a light edge", drawn[1] and drawn[1].r == 1 and drawn[5].a == 1)
check("GHOST: the help line says nothing", w:getStatusLine() == nil)
-- the alpha: ghost 0.15, the pointer on: the theme's own; unpinned: the idle dim in Dark
check("GHOST: the surface alpha is 0.15", w:_surfaceAlpha(T) == 0.15)
w._ghost = false
check("GHOST: the pointer on: full (the palette's own)", w:_surfaceAlpha(T) == nil)
w.pinned = false
w._dim = true
SEE = true
check("GHOST: unpinned: the idle dim, 0.35 in Dark", w:_surfaceAlpha(T) == 0.35)
SEE = false
check("GHOST: unpinned: Light stays solid", w:_surfaceAlpha(T) == nil)
SEE = true
w._dim = false
w.mouseOver = false
check("GHOST: unpinned never ghosts", w:_ghostNow() == false)
drawn = {}
w:_drawLines(10, 40, 300, 150)
local plain = true
for _, d in ipairs(drawn) do if d.a ~= 1 then plain = false end end
check("GHOST: unpinned words drawn once, no edge", plain and #drawn >= 3, #drawn)
w:close()

-- (QA, Nov 23 2026) closed by the game (the server gone, safe mode): the pin kept; by the player: unpinned
fresh(); FILES = {}
w = C.open(false)
w.pinned = true
w:close(true)
check("KEEP: a close by the game keeps the pin", w.pinned == true)
w = C.open(false)
w.pinned = true
w:close()
check("KEEP: the player's close unpins", w.pinned == false)
-- ghosted, a press only brings the window back
fresh(); FILES = {}
w = C.open(false)
w._ghost = true
local shadedBefore = w.windowShaded
local took = w:onMouseDown(1, 1)
check("GHOST: a press on a ghosted window lifts the ghost and does nothing else",
    took == true and w._ghost == false and w.windowShaded == shadedBefore)
w:close()

print("chat_window_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
