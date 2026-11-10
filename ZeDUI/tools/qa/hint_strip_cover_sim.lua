-- ZeDUI/tools/qa/hint_strip_cover_sim.lua  (Nov 10 2026, Build; punch list 131, the belt's balloon over the hint strip)
-- With no game running, the real ZeD_HintStrip.lua on stubs: a balloon slot (Balloon.lua's B._slot and B.up) and a
-- strip that counts its draws. It checks the strip steps aside while a balloon that is up covers it, or touches it
-- (within 4 units), and draws again once the balloon is down or elsewhere.
-- What it can't show: the belt on screen (QA: hover Back and a slot on the belt with the hint strip on).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/hint_strip_cover_sim.lua
-- It prints FAIL lines and a last line "hint_strip_cover_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]hint_strip_cover_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local stub
stub = setmetatable({}, { __index = function() return stub end, __call = function() return stub end })
function require() end
local UP = true
local SLOT = { box = nil }
local DRAWS = 0
ZeD = { T = { px = function(v) return v end, borderS = {} },
        Balloon = { _slot = SLOT, up = function() return UP end },
        PadGlyphs = { drawStrip = function() DRAWS = DRAWS + 1 end },
        Atoms = { frame = function() end } }
ZeD_Panel = { derive = function(self, n) return setmetatable({}, { __index = self }) end }
setmetatable(_G, { __index = function() return stub end })
local fn, err = loadfile(ROOT .. "42/media/lua/client/ZeD/ZeD_HintStrip.lua")
local ok, e = pcall(fn or error, err)
setmetatable(_G, nil)
check("ZeD_HintStrip.lua loads on the stubs", fn and ok, err or e)
local H = ZeD.HintStrip
-- the strip at 800,1000, 300 x 24
local strip = setmetatable({ _p = { 1 }, width = 300, height = 24,
    getAbsoluteX = function() return 800 end, getAbsoluteY = function() return 1000 end }, { __index = ZeD_HintStripHUD })
local function drawn(box, up)
    SLOT.box, UP, DRAWS = box, up, 0
    strip:render()
    return DRAWS == 1
end
check("no balloon: the strip draws", drawn(nil, true))
check("the belt's balloon over the strip: it steps aside", not drawn({ x = 850, y = 990, w = 60, h = 30 }, true))
check("a balloon just above it, touching: it steps aside", not drawn({ x = 850, y = 950, w = 60, h = 48 }, true))
check("a balloon 3 px above: still part of its line", not drawn({ x = 850, y = 950, w = 60, h = 47 }, true))
check("a balloon 10 px above: the strip draws", drawn({ x = 850, y = 940, w = 60, h = 50 }, true))
check("a balloon off to the side: the strip draws", drawn({ x = 100, y = 990, w = 60, h = 30 }, true))
check("the balloon down: the strip draws again", drawn({ x = 850, y = 990, w = 60, h = 30 }, false))
check("covered() answers the same", H.covered(800, 1000, 300, 24) == false)
print("hint_strip_cover_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
