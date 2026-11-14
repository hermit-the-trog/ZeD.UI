-- Split view (beta 13, docs/plans/SPLITSCREEN_PLAN_20261111.md S2): the switch that lets players 2 to 4 have ZeD's
-- windows, and each window's screen being its player's part. Runs the real functions cut out of Atoms.lua and
-- Organisms.lua over a stubbed two-player vertical split (each player a half of a 1920 x 1080 screen).
local ROOT = (debug.getinfo(1, "S").source:sub(2):gsub("\\", "/"):match("^(.*)/ZeDUI/tools/qa/") or ".") .. "/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function cut(path, pattern)
    local f = assert(io.open(ROOT .. path, "rb")); local s = f:read("*a"); f:close()
    local body = s:match(pattern)
    check("found in " .. path .. ": " .. pattern:sub(1, 40), body ~= nil)
    if body then assert(loadstring(body, "@" .. path))() end
end

ZeD = {}
-- the game: two players side by side
local PARTS = { [0] = { 0, 0, 960, 1080 }, [1] = { 960, 0, 960, 1080 } }
getCore = function() return { getScreenWidth = function() return 1920 end, getScreenHeight = function() return 1080 end } end
getPlayerScreenLeft = function(pn) return PARTS[pn][1] end
getPlayerScreenTop = function(pn) return PARTS[pn][2] end
getPlayerScreenWidth = function(pn) return PARTS[pn][3] end
getPlayerScreenHeight = function(pn) return PARTS[pn][4] end

cut("42/media/lua/client/ZeD/Atoms.lua", "(function ZeD%.playerRect%(pn%).-\nend%s)")
cut("42/media/lua/client/ZeD/Atoms.lua", "(ZeD%.SPLIT_MIN_W, ZeD%.SPLIT_MIN_H = .-function ZeD%.partFits%(pn%).-\nend%s)")
cut("42/media/lua/client/ZeD/Atoms.lua", "(function ZeD%.windowsFor%(pn%).-\nend%s)")
cut("42/media/lua/client/ZeD/Organisms.lua", "(function ZeD%.screenOf%(w%).-\nend%s)")
cut("42/media/lua/client/ZeD/Organisms.lua", "(function ZeD%.screenLeftOf%(w%).-\nend%s)")

-- the switch off (as shipped until S5): player 1 only, the whole screen
check("off: player 1 has ZeD windows", ZeD.windowsFor(0) and ZeD.windowsFor(nil))
check("off: player 2 has the game's", not ZeD.windowsFor(1))
local w, h, x, y = ZeD.screenOf({ playerNum = 0 })
check("off: player 1's window has the whole screen", w == 1920 and h == 1080 and x == 0 and y == 0, w .. "x" .. h .. "+" .. x)
check("off: the left edge is 0", ZeD.screenLeftOf({ playerNum = 1 }) == 0)

-- the switch on
ZeD.splitWindows = true
check("on: players 2 to 4 have ZeD windows", ZeD.windowsFor(1) and ZeD.windowsFor(2) and ZeD.windowsFor(3))
check("on: no player 5", not ZeD.windowsFor(4))
w, h, x, y = ZeD.screenOf({ playerNum = 0 })
check("on: player 1's window has the left half", w == 960 and x == 0, w .. "+" .. x)
w, h, x, y = ZeD.screenOf({ playerNum = 1 })
check("on: player 2's window has the right half", w == 960 and x == 960, w .. "+" .. x)
check("on: player 2's left edge is the middle", ZeD.screenLeftOf({ playerNum = 1 }) == 960)
w, h, x = ZeD.screenOf(1)
check("on: a player number while a window is built", w == 960 and x == 960)
w = ZeD.screenOf({})
check("on: a window with no player (the main menu's) keeps the whole screen", w == 1920)
-- the director's choice A (Nov 13 2026): a part too small for the pair gives that player the game's windows
PARTS[1] = { 640, 0, 640, 800 }            -- a Steam Deck half
check("A: a Deck half is too small: player 2 gets the game's", not ZeD.windowsFor(1))
PARTS[1] = { 960, 540, 960, 540 }          -- a 1080p quarter
check("A: a 1080p quarter is too small", not ZeD.windowsFor(1))
PARTS[1] = { 1920, 0, 1920, 1080 }         -- a 4K quarter (at scale 1)
check("A: a 4K quarter fits", ZeD.windowsFor(1))
PARTS[1] = { 960, 0, 960, 1080 }
check("A: player 1 keeps ZeD's windows whatever their part", ZeD.windowsFor(0))
-- QA's stand-in: a part set for player 1 alone
ZeD._qaRect = { [0] = { 0, 540, 960, 540 } }
w, h, x, y = ZeD.screenOf({ playerNum = 0 })
check("QA's stand-in part is used", w == 960 and h == 540 and y == 540)
ZeD._qaRect = nil
ZeD.splitWindows = false

-- the left-edge pins use the player's left edge, never a bare 0
for _, p in ipairs({ "42/media/lua/client/ZeD/ZeD_CharacterWindow.lua", "42/media/lua/client/ZeD/WindowHalves.lua" }) do
    local f = assert(io.open(ROOT .. p, "rb")); local s = f:read("*a"); f:close()
    check(p .. ": no window pinned at a bare 0", s:find("if newX < 0 then pushed = %-newX; newX = 0 end") == nil and s:find("if x < 0 then pushed = %-x; x = 0 end") == nil)
end
print(string.format("split_view_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
