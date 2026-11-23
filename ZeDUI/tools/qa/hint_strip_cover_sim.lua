-- ZeDUI/tools/qa/hint_strip_cover_sim.lua  (Nov 10 2026, Build; punch list 131, the belt's balloon over the hint strip)
-- With no game running, the real ZeD_HintStrip.lua on stubs: a balloon slot (Balloon.lua's B._slot and B.up) and a
-- strip that counts its draws. It checks the strip steps aside while a balloon that is up covers it, or touches it
-- (within 4 units), or is the belt's wherever it stands (the hands' balloons), and draws again once the balloon is down
-- or is someone else's elsewhere.
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
local strip = setmetatable({ _p = { 1 }, _t = false, width = 300, height = 24, playerNum = 0,
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
-- a balloon of the belt's: the strip steps aside wherever it stands (the hands' balloons sit beside it, not over it:
-- QA's Mac run, Nov 10 2026)
local BELT = {}
ZeD.Belt = { getHUD = function(pn) return pn == 0 and BELT or nil end }
SLOT.owner = BELT
check("a belt balloon off to the side: the strip steps aside", not drawn({ x = 100, y = 990, w = 60, h = 30 }, true))
check("a belt balloon down: the strip draws", drawn({ x = 100, y = 990, w = 60, h = 30 }, false))
SLOT.owner = {}
check("someone else's balloon off to the side: the strip draws", drawn({ x = 100, y = 990, w = 60, h = 30 }, true))
-- the belt's held-item card (135): drawn last on ZeD_InvTip's layer, so the balloon slot is the layer's while the belt's
-- own hint stands under it (QA's Mac run on test 6, Nov 11 2026: the strip stayed up beside the card)
local LAYER = {}
SLOT.owner = LAYER
ZeD.InvTip = { _frame = 10, _want = { owner = BELT, content = {}, frame = 10 } }
check("the belt's card up (the layer's balloon, off to the side): the strip steps aside", not drawn({ x = 100, y = 990, w = 60, h = 30 }, true))
ZeD.InvTip._want.owner = {}
check("a loot list's card off to the side: the strip draws", drawn({ x = 100, y = 990, w = 60, h = 30 }, true))
ZeD.InvTip._want.owner = BELT; ZeD.InvTip._frame = 14
check("the belt's card asked for frames ago: the strip draws", drawn({ x = 100, y = 990, w = 60, h = 30 }, true))
ZeD.InvTip = nil
SLOT.owner = nil
-- the strip and the moodles stay clear (QA rt_strain, Nov 22 2026: at 1280x800 the strip stood over the Endurance and Tired
-- moodles). H.clearOf on the moodles' rects as ZeD_Moodles._place makes them (row above the belt, columns at an edge), at 4K,
-- 1080p, the Deck and 720p, with 2 and 12 moodles, in each layout; the strip as prerender sets it (centred, over the belt).
local function meet(ax, ay, aw, ah, bx, by, bw, bh) return ax < bx + bw and bx < ax + aw and ay < by + bh and by < ay + ah end
local SCREENS = { { 3840, 2160, 2.0, 64 }, { 1920, 1080, 1.0, 48 }, { 1280, 800, 0.75, 32 }, { 1280, 720, 0.67, 32 } }
for _, sc in ipairs(SCREENS) do
    local sw, sh, k, size = sc[1], sc[2], sc[3], sc[4]
    local function px(v) return math.floor(v * k + 0.5) end
    for _, n in ipairs({ 2, 12 }) do
        for _, place in ipairs({ "bottom", "right", "left" }) do
            local gap = 10
            local beltY = sh - px(16) - px(40)                  -- the belt's top edge (a stand-in height)
            local h, w = px(17), px(148)
            local mr
            if place == "bottom" then
                local rw = n * size + (n - 1) * gap
                mr = { place = place, n = n, x = math.floor((sw - rw) / 2), y = beltY - px(12) - size, w = rw, h = size, size = size }
            else
                local cols = n > 5 and 3 or 1
                local cw = cols * size + (cols - 1) * gap
                local rows = n > 5 and 5 or n
                local rh = rows * size + (rows - 1) * gap
                mr = { place = place, n = n, x = place == "left" and 10 or sw - 10 - cw, y = math.floor((sh - rh) / 2), w = cw, h = rh, size = size }
            end
            local x0, y0 = math.floor((sw - w) / 2), beltY - h - px(6)
            local x, y = H.clearOf(x0, y0, w, h, mr, 0, 0, sw, sh, px(6))
            local lab = sw .. "x" .. sh .. " " .. place .. " n=" .. n
            check(lab .. ": the strip is clear of the moodles", not meet(x, y, w, h, mr.x, mr.y, mr.w, mr.h), x .. "," .. y)
            check(lab .. ": the strip stays on screen", x >= 0 and y >= 0 and x + w <= sw and y + h <= sh, x .. "," .. y)
            check(lab .. ": a strip with no moodles stays put", select(2, H.clearOf(x0, y0, w, h, nil, 0, 0, sw, sh, px(6))) == y0)
        end
    end
end
-- a strip made to reach a column is moved beside it (a wide strip on the Deck, columns on the right)
local cx, cy = H.clearOf(300, 400, 900, 17, { place = "right", n = 6, x = 1000, y = 300, w = 140, h = 300, size = 32 }, 0, 0, 1280, 800, 6)
check("a wide strip meeting a right column steps left of it", cx + 900 + 6 <= 1000 and cy == 400, cx .. "," .. cy)
print("hint_strip_cover_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
