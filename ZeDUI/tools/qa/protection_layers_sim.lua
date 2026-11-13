-- ZeDUI/tools/qa/protection_layers_sim.lua  (Nov 12 2026, QA b12 round 2): the Equip tab's defense numbers
-- (ProtectionTab.gatherData) with no game running. The real ProtectionTab.lua on Lua 5.1 stubs of a character, its
-- worn items and its inventory. It checks the game's rule (IsoGameCharacter.getBodyPartClothingDefense on 42.22):
--   LAYERS  every worn layer over a part adds its defense (bite, scratch, bullet), the total floored and at most 100;
--           a layer with a hole over the part adds nothing there but still counts as a layer
--   AVERAGE the 18-part average, its grade, the best and worst parts follow the added layers
--   WORN    only worn garments count: one held in the hand (equipped, not worn) does not
-- QA's staged outfit: a leather jacket (ForeArm_L bite 20) over a denim shirt (7) is 27 there, as the game's panel.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/protection_layers_sim.lua
-- It prints FAIL lines and a last line "protection_layers_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]protection_layers_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- stubs
require = function() end
ZeD = { T = {}, partAbbrev = function(s) return s end }
local function list(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end
function instanceof(o, cls) return type(o) == "table" and o._cls == cls end

-- a garment: defs[part] = { bite, scratch, bullet }; holes[part] = true for a hole there
local function garment(name, defs, holes)
    local parts = {}
    for p in pairs(defs) do parts[#parts + 1] = p end
    table.sort(parts)
    local g = { _cls = "Clothing", name = name, defs = defs, holes = holes or {} }
    function g:getCoveredParts() return list(parts) end
    function g:getDefForPart(part, bite, bullet)
        local d = self.defs[part]
        if not d then return 0 end
        if bullet then return d[3] end
        if bite then return d[1] end
        return d[2]
    end
    function g:getVisual() local s = self; return { getHole = function(_, part) return s.holes[part] and 1 or 0 end } end
    function g:getName() return self.name end
    function g:getTex() return nil end
    function g:isEquipped() return true end
    return g
end
local function player(wornList, held)
    local all = {}
    for _, g in ipairs(wornList) do all[#all + 1] = g end
    for _, g in ipairs(held or {}) do all[#all + 1] = g end
    local wis = {}
    for _, g in ipairs(wornList) do wis[#wis + 1] = { getItem = function() return g end } end
    return {
        getWornItems = function() return list(wis) end,
        getInventory = function() return { getItems = function() return list(all) end } end,
        isFemale = function() return false end,
    }
end

local okL, errL = pcall(dofile, ROOT .. "42/media/lua/client/ZeD/ProtectionTab.lua")
check("ProtectionTab.lua loads", okL, errL)
local PT = ZeD.ProtectionTab

-- QA's staged outfit (whole numbers)
local hat    = garment("Hard Hat", { Head = { 40, 50, 10 } })
local shirt  = garment("Denim Shirt", { Torso_Upper = { 7, 15, 0 }, Torso_Lower = { 7, 15, 0 }, UpperArm_L = { 7, 15, 0 },
    UpperArm_R = { 7, 15, 0 }, ForeArm_L = { 7, 15, 0 }, ForeArm_R = { 7, 15, 0 } })
local jacket = garment("Leather Jacket", { Torso_Upper = { 20, 40, 5 }, Torso_Lower = { 20, 40, 5 }, UpperArm_L = { 20, 40, 5 },
    UpperArm_R = { 20, 40, 5 }, ForeArm_L = { 20, 40, 5 }, ForeArm_R = { 20, 40, 5 }, Back = { 20, 40, 5 } })
local jeans  = garment("Jeans", { Groin = { 10, 20, 0 }, UpperLeg_L = { 10, 20, 0 }, UpperLeg_R = { 10, 20, 0 },
    LowerLeg_L = { 10, 20, 0 }, LowerLeg_R = { 10, 20, 0 } })
local gloves = garment("Leather Gloves", { Hand_L = { 30, 50, 0 }, Hand_R = { 30, 50, 0 } })
local boots  = garment("Work Boots", { Foot_L = { 50, 60, 0 }, Foot_R = { 50, 60, 0 } })
local spare  = garment("Spare Shirt", { Torso_Upper = { 7, 15, 0 }, Torso_Lower = { 7, 15, 0 } })

local d = PT.gatherData(player({ hat, shirt, jacket, jeans, gloves, boots }, { spare }))
local ps = d.partStats
check("LAYERS: ForeArm_L jacket 20 + shirt 7 = 27 (the game's)", ps.ForeArm_L.bite == 27, ps.ForeArm_L.bite)
check("LAYERS: scratch added too", ps.ForeArm_L.scratch == 55, ps.ForeArm_L.scratch)
check("LAYERS: bullet added too", ps.ForeArm_L.bullet == 5, ps.ForeArm_L.bullet)
check("LAYERS: two layers over it", ps.ForeArm_L.layers == 2, ps.ForeArm_L.layers)
check("LAYERS: partDefense is the added bite", d.partDefense.Torso_Upper == 27, d.partDefense.Torso_Upper)
check("LAYERS: a single layer as it is", ps.Back.bite == 20 and ps.Back.layers == 1 and ps.Head.bite == 40)
check("LAYERS: an uncovered part -1, no layers", ps.Neck.bite == -1 and ps.Neck.layers == 0 and d.partDefense.Neck == -1)
-- 40 + 6*27 + 20 + 5*10 + 2*30 + 2*50 = 432; / 18 = 24
check("AVERAGE: the 18 parts with the layers added", d.avgBiteDef == 24, d.avgBiteDef)
check("AVERAGE: its grade", d.grade == "C", d.grade)
check("AVERAGE: the best part", d.bestPart.biteDef == 50, d.bestPart.biteDef)
check("WORN: a garment held in the hand is not counted", d.totalGarments == 6, d.totalGarments)
check("WORN: and adds nothing (Torso_Lower 27, not 34)", ps.Torso_Lower.bite == 27, ps.Torso_Lower.bite)
check("WORN: one uncovered part (the neck)", #d.uncoveredParts == 1, #d.uncoveredParts)

-- a hole over a part: that layer adds nothing there, still a layer
local holed = garment("Torn Jacket", { ForeArm_L = { 20, 40, 5 }, ForeArm_R = { 20, 40, 5 } }, { ForeArm_L = true })
d = PT.gatherData(player({ shirt, holed }))
check("LAYERS: a hole: the layer adds nothing there", d.partStats.ForeArm_L.bite == 7, d.partStats.ForeArm_L.bite)
check("LAYERS: a hole: still two layers", d.partStats.ForeArm_L.layers == 2)
check("LAYERS: the other arm whole", d.partStats.ForeArm_R.bite == 27, d.partStats.ForeArm_R.bite)
-- the total stops at 100; fractions added before the floor
local a = garment("A", { Head = { 60.6, 70, 50.5 } })
local b = garment("B", { Head = { 45.2, 50, 49.7 } })
local c = garment("C", { Neck = { 3.6, 2.5, 0 } })
local e = garment("E", { Neck = { 3.6, 2.5, 0 } })
d = PT.gatherData(player({ a, b, c, e }))
check("LAYERS: at most 100", d.partStats.Head.bite == 100 and d.partStats.Head.scratch == 100, d.partStats.Head.bite)
check("LAYERS: the unrounded layers added, then floored (3.6 + 3.6 = 7)", d.partStats.Neck.bite == 7, d.partStats.Neck.bite)
check("LAYERS: bullet 50.5 + 49.7 = 100", d.partStats.Head.bullet == 100, d.partStats.Head.bullet)
-- bare
d = PT.gatherData(player({}, { spare }))
check("bare: nothing worn, grade F, 18 uncovered", d.totalGarments == 0 and d.grade == "F" and #d.uncoveredParts == 18)

print("protection_layers_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
