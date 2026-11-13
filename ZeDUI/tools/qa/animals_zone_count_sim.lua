-- ZeDUI/tools/qa/animals_zone_count_sim.lua  (Nov 12 2026, Build, Q3): a hen just placed in a pen counts in that
-- pen's zone row, as Totals counts her. The game leaves a new animal's getDZone() empty for a while and a zone's
-- getAnimalsConnected() can miss her too; the poller then puts her in the streamed zone whose bounds hold her square.
-- Cuts the REAL discoverPlayerAnimals from AnimalsAlertPoller.lua and runs it on stubs.
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]animals_zone_count_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    print((ok and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    if not ok then failed = failed + 1 end
end
local function slurp(p) local f = assert(io.open(ROOT .. p, "rb")); local s = f:read("*a"); f:close(); return (s:gsub("\r\n", "\n")) end
local function cut(src, a, b)
    local i = assert(src:find(a, 1, true), "start not found: " .. a)
    local j = assert(src:find(b, i, true), "end not found: " .. b)
    return src:sub(i, j - 1)
end
local function jlist(t)
    local l = { t = t }
    function l.size() return #t end
    function l.get(_, i) return t[i + 1] end
    function l.iterator()
        local k = 0
        return { hasNext = function() return k < #t end, next = function() k = k + 1; return t[k] end }
    end
    return l
end

local src = slurp("42/media/lua/client/ZeD/AnimalsAlertPoller.lua")
local discover = assert(loadstring("local AD = ...\n" ..
    cut(src, "local function discoverPlayerAnimals(player)", "-- ============================================================================\n-- ALERT COMPUTATION") ..
    "\nreturn discoverPlayerAnimals"))({ isWild = function() return false end })

local function animal(x, y, z, dz)
    return { getX = function() return x end, getY = function() return y end, getZ = function() return z or 0 end,
        getDZone = function() return dz end }
end
local function zone(name, x, y, w, h, z, conn)
    return { name = name, isStillStreamed = function() return true end,
        getAnimalsConnected = function() return jlist(conn or {}) end,
        getX = function() return x end, getY = function() return y end, getW = function() return w end,
        getH = function() return h end, getZ = function() return z or 0 end }
end

local CELL = {}
getCell = function() return { getAnimals = function() return jlist(CELL) end } end
local player = { getCurrentSquare = function()
    return { getX = function() return 100 end, getY = function() return 100 end, getZ = function() return 0 end }
end }

-- the hen: inside the coop's bounds, no zone of her own yet, not in the coop's connected list
local hen = animal(105.5, 103.2, 0, nil)
local cow = animal(130.5, 130.5, 0, nil)
local coop = zone("Coop", 102, 100, 6, 6, 0, {})
local field = zone("Field", 120, 120, 20, 20, 0, { cow })
local loft = zone("Loft", 102, 100, 6, 6, 1, {})
local stray = animal(160.5, 160.5, 0, nil)
CELL = { hen, cow, stray }
local ZONES = { loft, coop, field }
DesignationZoneAnimal = { getAllZones = function() return jlist(ZONES) end }

local animals, zoneMap, zoneList = discover(player)
check("TOTALS three animals in reach", #animals == 3, #animals)
check("ZONES every streamed zone listed", #zoneList == 3, #zoneList)
check("HEN counted in the coop (bounds hold her square)", #(zoneMap[coop] or {}) == 1 and zoneMap[coop][1] == hen,
    #(zoneMap[coop] or {}))
check("HEN not counted in the loft above (another floor)", #(zoneMap[loft] or {}) == 0, #(zoneMap[loft] or {}))
check("COW stays in the field (connected list)", #(zoneMap[field] or {}) == 1, #(zoneMap[field] or {}))
local placed = 0
for _, z in ipairs(zoneList) do placed = placed + #(zoneMap[z] or {}) end
check("STRAY outside every zone counts in no zone row", placed == 2, placed)

-- an animal whose own zone is known keeps it, ahead of the bounds
local other = zone("Other", 0, 0, 1, 1, 0, {})
local hen2 = animal(104.5, 101.5, 0, other)
CELL = { hen2 }
ZONES = { coop }
animals, zoneMap, zoneList = discover(player)
check("OWN ZONE wins over bounds", #(zoneMap[other] or {}) == 1 and #(zoneMap[coop] or {}) == 0)

-- a zone whose bounds cannot be read: no error, the animal just stays unzoned
local broken = { isStillStreamed = function() return true end, getAnimalsConnected = function() return jlist({}) end,
    getX = function() error("no bounds") end }
CELL = { animal(104.5, 101.5, 0, nil) }
ZONES = { broken }
local ok = pcall(discover, player)
check("BROKEN zone bounds: no error", ok)

print(string.format("%d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
