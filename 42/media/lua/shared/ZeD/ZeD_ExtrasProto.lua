-- ZeD-UI/42/media/lua/shared/ZeD/ZeD_ExtrasProto.lua
-- ============================================================================
-- THE SERVER EXTRAS PROTOCOL. What both sides agree on: the module, the settings and
-- what a good one looks like, every limit. Every extra is off until the owner turns it on, so solo play and vanilla-rules
-- servers are untouched. Pure Lua, ASCII, nothing client-only at load: this file also runs on a dedicated server.
-- ============================================================================

ZeD = ZeD or {}
ZeD.Ex = ZeD.Ex or {}
local Ex = ZeD.Ex

Ex.MOD = "ZeDX"

-- THE DIRECTOR'S QUESTIONS, answered the careful way, each kept to one switch (MP_SERVER_PART_DESIGN.md, the last section)
-- LOT_TILES: how far past the walls a claim's lot reaches when "Claims cover the lot" is ticked. The game keeps no lot
-- lines a server can read, so the lot is the safehouse's rectangle and this many tiles around it.
Ex.LOT_TILES = 5
-- CLAIM_NEEDS_KEY: does claiming a car take its key? false: standing by it is enough, as drawn. true: the key in the
-- player's inventory too.
Ex.CLAIM_NEEDS_KEY = false
-- CLAIM_SHARE_FACTION: does "others" leave out the owner's faction? false: others means everyone but the owner.
Ex.CLAIM_SHARE_FACTION = false

-- who may do what, by the game's own capabilities
Ex.CAP_EDIT = "ChangeAndReloadServerOptions"  -- change these settings: the game's own test for changing server options
Ex.CAP_CAR = "ManipulateVehicle"              -- staff who pass a claim, and may release anyone's
Ex.CAP_HOUSE = "UseBuildCheat"                -- staff who pass safehouse protection: the game's own pass for its sledgehammer rule
Ex.CAP_MAP = "TeleportToCoordinates"          -- the map's teleport: what the game's /teleportto asks for
Ex.SERVER_CAPS = { Ex.CAP_EDIT, Ex.CAP_CAR, Ex.CAP_HOUSE, Ex.CAP_MAP }

-- every limit in one place, so they can become server settings later
Ex.L = {
    PER_MIN = 1, PER_MAX = 5,           -- claims per player, as drawn
    LAPSE_MIN = 1, LAPSE_MAX = 30,      -- real days away, as drawn
    CLAIMS_MAX = 5000,                  -- claims on the server
    REACH_TILES = 6,                    -- how near a car a player stands to claim it: the tab's own limit
    TOOK_REACH = 150,                   -- how far from a container a player can be by the time the report lands: reports
                                        -- wait for the batch and each other, and a player can have run or driven off
    TOOK_FLOORS = 2,                    -- the same, in floors
    TOOK_ROWS = 12,                     -- kinds of item in one report
    TOOK_NAME = 40,                     -- characters of an item's name in a line
    TOOK_MAX = 9999,                    -- items of one kind in a report
    TOOK_BATCH_MS = 3000,               -- a client gathers its takes this long and sends them as one
    TOOK_SEND_MS = 1500,                -- a client leaves this long between reports
    TOOK_MS = 500,                      -- the server takes one in this long: well under that, or the network's jitter loses reports
    SAVE_MS = 1000,
    CLAIM_MS = 1000,
    VEH_MS = 300,
    MINE_MS = 1000,
    TP_MS = 1000,
    NOTE_MS = 5000,                     -- one refusal said and logged in this long, per player
    POLL_MS = 2000,                     -- how often the server looks at who is driving
    LEFT_POLLS = 5,                     -- and for how many polls it goes on looking at a claimed car once its driver has gone
    LAPSE_EVERY_S = 300,                -- how often claims are tested for lapsing
    WORLD_MAX = 60000,                  -- past any map's edge
    HIT_ROOM = 20,                      -- a swing's door damage times this, and no swing can land more
}

function Ex.defaults()
    return {
        vc = { on = false, parts = true, drive = true, tow = false, per = 2, lapse = 7 },
        sp = { on = false, dismantle = true, destroy = true, lot = true },
        tp = { on = false },
        cl = { on = false },
    }
end

local function bool(v, d)
    if type(v) == "boolean" then return v end
    return d
end
local function num(v, d, lo, hi)
    if type(v) ~= "number" or v ~= math.floor(v) then return d end
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- settings from anywhere, good ones: only the fields above, each its own type, numbers inside their limits. A missing or
-- wrong field takes its default, and every default is off
function Ex.clean(raw)
    local d = Ex.defaults()
    if type(raw) ~= "table" then return d end
    local L = Ex.L
    local v, s, t, c = raw.vc, raw.sp, raw.tp, raw.cl
    if type(v) == "table" then
        d.vc = { on = bool(v.on, false), parts = bool(v.parts, true), drive = bool(v.drive, true), tow = bool(v.tow, false),
            per = num(v.per, d.vc.per, L.PER_MIN, L.PER_MAX), lapse = num(v.lapse, d.vc.lapse, L.LAPSE_MIN, L.LAPSE_MAX) }
    end
    if type(s) == "table" then
        d.sp = { on = bool(s.on, false), dismantle = bool(s.dismantle, true), destroy = bool(s.destroy, true), lot = bool(s.lot, true) }
    end
    if type(t) == "table" then d.tp = { on = bool(t.on, false) } end
    if type(c) == "table" then d.cl = { on = bool(c.on, false) } end
    return d
end

function Ex.same(a, b)
    for group, fields in pairs(Ex.defaults()) do
        for k in pairs(fields) do
            if a[group][k] ~= b[group][k] then return false end
        end
    end
    return true
end

-- how many systems are on
function Ex.nOn(s) return (s.vc.on and 1 or 0) + (s.sp.on and 1 or 0) + (s.tp.on and 1 or 0) + (s.cl.on and 1 or 0) end

-- one short line of a set of settings, for the log
function Ex.summary(s)
    local function word(on) return on and "on" or "off" end
    return "claims " .. word(s.vc.on) .. " parts " .. word(s.vc.parts) .. " drive " .. word(s.vc.drive) .. " tow " .. word(s.vc.tow)
        .. " per " .. tostring(s.vc.per) .. " lapse " .. tostring(s.vc.lapse)
        .. ", safehouse " .. word(s.sp.on) .. " dismantle " .. word(s.sp.dismantle) .. " destroy " .. word(s.sp.destroy) .. " lot " .. word(s.sp.lot)
        .. ", map " .. word(s.tp.on) .. ", containers " .. word(s.cl.on)
end

-- a claim's key: the car's number in the game's vehicle database, which outlives a restart and goes where the car goes. The
-- game gives a removed car's number to the next new car, so the number alone doesn't prove the car: the server's F.claimOf
-- tests the car itself (F.sameCar). A string, so the table's keys are one type whatever the save does with numbers
function Ex.keyOf(sql) return "v" .. tostring(sql) end
function Ex.okKey(s) return type(s) == "string" and #s <= 16 and string.match(s, "^v%d+$") ~= nil end

-- a vehicle's short number as a client names it
function Ex.okVeh(n) return type(n) == "number" and n == math.floor(n) and n >= -32768 and n <= 65535 end
-- the vehicle the game's getVehicleById finds for a number: Kahlua's Double.intValue truncates, stops at the int's ends and
-- makes NaN 0, and getVehicleById narrows that to a short. nil for anything but a number (no % here: Kahlua's keeps the sign)
function Ex.vehId(n)
    if type(n) ~= "number" then return nil end
    if not (n > 0 or n <= 0) then return 0 end
    if n > 2147483647 then n = 2147483647 elseif n < -2147483648 then n = -2147483648 end
    local i = (n < 0) and math.ceil(n) or math.floor(n)
    local low = i - math.floor(i / 65536) * 65536
    if low >= 32768 then return low - 65536 end
    return low
end
function Ex.okCoord(n) return type(n) == "number" and n == math.floor(n) and n >= 0 and n <= Ex.L.WORLD_MAX end

return Ex
