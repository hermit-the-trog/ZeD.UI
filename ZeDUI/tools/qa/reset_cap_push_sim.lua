-- ZeDUI/tools/qa/reset_cap_push_sim.lua  (Nov 10 2026, Build; punch list 125, a tab closed while rolled 4 px off)
-- QA's staged Deck run (Nov 9): after ZeD_Window.resetLayout the World window sat at 644 but its saved x was 864 design
-- units (648 px): the push the half-screen cap had made before the reset (4 px) stayed on the window, was saved on top
-- of the reset's x, and was given back when the next drawer closed, so a tab closed while rolled left it at 648.
-- With no game running, the real Organisms.lua on stubs: both windows carry a push and a lost width from before, the
-- reset runs, and the counters are clean, the windows at the reset's place (1280 x 800 at 0.75).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/reset_cap_push_sim.lua
-- It prints FAIL lines and a last line "reset_cap_push_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]reset_cap_push_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local stub
stub = setmetatable({}, { __index = function() return stub end, __call = function() return stub end })
function require() end
local SC = 0.75
ZeD = setmetatable({ T = { px = function(v) return math.floor(v * SC + 0.5) end, scale = SC },
                     Settings = { syncWindowAccent = function() end } }, { __index = function() return stub end })
getCore = function() return { getScreenWidth = function() return 1280 end, getScreenHeight = function() return 800 end } end
local function win()
    local w = { x = 0, y = 0, w = 100, h = 100, _drawerCapPush = 4, _drawerCapLost = 53 }
    function w:setX(v) self.x = v end
    function w:setY(v) self.y = v end
    function w:setWidth(v) self.w = v end
    function w:setHeight(v) self.h = v end
    function w:getX() return self.x end
    function w:getY() return self.y end
    function w:getWidth() return self.w end
    return w
end
local CW, WW = win(), win()
ZeD_CharacterWindow = { getWindow = function() return CW end }
ZeD_WorldWindow = { getWindow = function() return WW end }
setmetatable(_G, { __index = function() return stub end })
local fn, err = loadfile(ROOT .. "42/media/lua/client/ZeD/Organisms.lua")
local ok, e = pcall(fn or error, err)
setmetatable(_G, nil)
check("Organisms.lua loads on the stubs", fn and ok, err or e)
ZeD_CharacterWindow = { getWindow = function() return CW end }
ZeD_WorldWindow = { getWindow = function() return WW end }
local okR, eR = pcall(ZeD_Window.resetLayout)
check("resetLayout runs", okR, eR)
check("the World window at the reset's place (644)", WW.x == 644, WW.x)
check("its push from before is not owed", WW._drawerCapPush == 0, WW._drawerCapPush)
check("nor its lost width", WW._drawerCapLost == 0, WW._drawerCapLost)
check("the Character window's push from before is not owed", CW._drawerCapPush == 0, CW._drawerCapPush)
check("nor its lost width", CW._drawerCapLost == 0, CW._drawerCapLost)
-- what the World window saves from there: x + push, in design units (saveWorldState): 644 / 0.75, not 864
check("the save would read the reset's x", (WW.x + (WW._drawerCapPush or 0)) / SC ~= 864, (WW.x + (WW._drawerCapPush or 0)) / SC)
print("reset_cap_push_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
