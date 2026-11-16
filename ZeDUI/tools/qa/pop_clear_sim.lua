-- ZeDUI/tools/qa/pop_clear_sim.lua
-- (Nov 15 2026, QA's beta 16 pass) PopClear.lua: a pop-out placing itself keeps clear of the player's Character and
-- World windows. Runs the real file against stub windows on a 3840 x 2160 screen.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]pop_clear_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if ok then print("ok   " .. name) else failed = failed + 1; print("FAIL " .. name .. (detail and (" (" .. tostring(detail) .. ")") or "")) end
end

-- the game's globals the file touches
function getCore() return { getScreenHeight = function() return 2160 end } end
ZeD = { T = { px = function(n) return n end } }
local function mkWin(x, y, w, h, shown)
    return { getX = function() return x end, getY = function() return y end, getWidth = function() return w end,
             getHeight = function() return h end, isReallyVisible = function() return shown ~= false end }
end
local CHAR, WORLD = nil, nil
ZeD_CharacterWindow = { getWindow = function(pn) return CHAR end }
ZeD_WorldWindow = { getWindow = function(pn) return WORLD end }

dofile(ROOT .. "42/media/lua/client/ZeD/PopClear.lua")
local PC = ZeD.PopClear
check("loads ZeD.PopClear", PC and type(PC.spot) == "function")

-- nothing open: its own spot
local x, y = PC.spot(0, 900, 300, 400, 300)
check("no windows: its own spot", x == 900 and y == 300)

-- the World window above-left, its corner under the pop-out's top (QA's picture: 13 px over the corner)
WORLD = mkWin(500, 0, 600, 313)
x, y = PC.spot(0, 900, 300, 400, 300)
check("over the World window's corner: just below it", x == 900 and y == 313 + 8, tostring(x) .. "," .. tostring(y))

-- clear already: unchanged
x, y = PC.spot(0, 1200, 300, 400, 300)
check("beside the window, clear: unchanged", x == 1200 and y == 300)

-- a hidden window is not in the way
WORLD = mkWin(500, 0, 600, 313, false)
x, y = PC.spot(0, 900, 300, 400, 300)
check("a hidden window: its own spot", x == 900 and y == 300)

-- no room below (a tall window): just above it
WORLD = mkWin(500, 1000, 600, 1100)
x, y = PC.spot(0, 900, 1200, 400, 300)
check("no room below: just above the window", x == 900 and y == 1000 - 300 - 8, tostring(y))

-- below lands on the Character window and above is off the screen: its own spot after all
WORLD = mkWin(500, 100, 600, 900)
CHAR = mkWin(500, 1008, 600, 1100)
x, y = PC.spot(0, 900, 150, 400, 300)
check("boxed in: its own spot, never off the screen", x == 900 and y == 150, tostring(y))

-- the Character window counts too
WORLD, CHAR = nil, mkWin(0, 0, 1000, 400)
x, y = PC.spot(0, 900, 300, 400, 300)
check("over the Character window: just below it", y == 408, tostring(y))

-- the pop-outs ask it, and only for a spot they pick themselves (never a dragged or saved one)
local function read(p) local f = assert(io.open(ROOT .. p, "rb")); local s = f:read("*a"); f:close(); return s end
local TWF, SP = read("42/media/lua/client/ZeD/TwoWayFull.lua"), read("42/media/lua/client/ZeD/ZeD_SeatPopout.lua")
check("the face pop-out asks it for its spot beside the player", TWF:find("hx, hy = ZeD.PopClear.spot(pn, hx, hy, w, h)", 1, true) ~= nil)
check("the seat pop-out asks it for its anchored spot", SP:find("a.clearX, a.clearY = ZeD.PopClear.spot(self.playerNum, x, y, w, h)", 1, true) ~= nil)

print("pop_clear_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
