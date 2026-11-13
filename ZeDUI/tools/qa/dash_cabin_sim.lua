-- ZeDUI/tools/qa/dash_cabin_sim.lua  (Nov 12 2026, Build): the dashes' cabin colors with no game running (punch list
-- 179; ZeDUI/HANDOFF_design_dash_interior_colors_20261112.md). The real ZeD_DashProto.lua (shared: the odds, the paint's
-- buckets, the roll, the stamp) and DashPx.lua (the export's data) run on Lua 5.1 with a stub car.
--   HANDOFF  the odds as data equal the handoff's tables, row for row (paint words, colors, odds), every row 100; each
--            dash in its group as the handoff lists it; the colors' names to ramps as the handoff's; public service
--            always black
--   DATA     each civilian dash in DashPx carries its group's three colors, lead first; the fleet and the race car
--            none; every picture a color names is in the textures folder, every plain one too; a "cabin" shadow in the
--            parts has its color's own in every color
--   BUCKETS  the paint's buckets at every edge; vanilla's own paints land where they should; the special cars'
--            livery paint reads white; nothing to read is nil
--   ROWS     each bucket's row in each group, as the handoff's words put it (a maroon car on a "red" row, silver and
--            gray one bucket); every bucket finds a row everywhere
--   ROLL     the roll is 0..99, the same for the same key, spread evenly; the odds come out as the table's
--   CAR      the same car the same color every time: twice, a new dash (a reload), a second machine (multiplayer: the
--            same key and paint, no stamp yet), the server's stamp the same as the client's answer; the stamp written
--            once and a repaint after it changes nothing; existing cars (no stamp) get one on first sight
--   FLEET    police, taxi, ambulance, fire, ranger: black whatever the paint or roll, no stamp needed
--   FALLBACK a car whose paint can't be read (no getters, they throw, all zero) takes the neutral row, and is not
--            stamped
-- Run from the repo root:  lua51 ZeDUI/tools/qa/dash_cabin_sim.lua
-- It prints FAIL lines and a last line "dash_cabin_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]dash_cabin_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

ZeD = {}
dofile(ROOT .. "42/media/lua/shared/ZeD/ZeD_DashProto.lua")
dofile(ROOT .. "42/media/lua/client/ZeD/DashPx.lua")
local DP, PX = ZeD.DashProto, ZeD.DashPx
local TEXDIR = ROOT .. "42/media/textures/ZeD/dashpx/"

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
local function split(s, sep)
    local out = {}
    for piece in (s .. sep):gmatch("(.-)" .. sep) do out[#out + 1] = trim(piece) end
    return out
end
local function exists(path) local f = io.open(path, "rb"); if f then f:close(); return true end; return false end
local function join(t) local o = {}; for i, v in ipairs(t) do o[i] = tostring(v) end; return table.concat(o, ",") end

-- ---------------------------------------------------------------------------
section("HANDOFF")
-- ---------------------------------------------------------------------------
local f = assert(io.open(ROOT .. "ZeDUI/HANDOFF_design_dash_interior_colors_20261112.md", "r"))
local md = f:read("*a"); f:close()
md = md:gsub("\r", "")
-- the colors table: group | dashboards | name: `ramp` ...; then each odds table under its **group** heading
local HCOL, HODDS, order, cur = {}, {}, {}, nil
for line in (md .. "\n"):gmatch("(.-)\n") do
    local head = line:match("^%*%*(.-)%*%*$")
    if head then cur = head; HODDS[cur] = {} end
    if line:sub(1, 1) == "|" then
        local cells = split(line:sub(2, -2), "|")
        if #cells == 3 and cells[3]:find("`", 1, true) then
            local names, ramps = {}, {}
            for nm, ramp in cells[3]:gmatch("([%a ]+): `([%w_]+)`") do names[#names + 1] = trim(nm):gsub(" only$", ""); ramps[#ramps + 1] = ramp end
            HCOL[cells[1]] = { designs = split(cells[2], ","), names = names, ramps = ramps }
            order[#order + 1] = cells[1]
        elseif #cells == 2 and cur and HODDS[cur] and cells[1] ~= "Paint" and not cells[1]:find("^%-") then
            local paint = split(cells[1]:lower(), ",")
            local odds = {}
            for _, o in ipairs(split(cells[2], ",")) do
                local nm, n = o:match("^(.-) (%d+)$")
                odds[#odds + 1] = { nm, tonumber(n) }
            end
            HODDS[cur][#HODDS[cur] + 1] = { paint = paint, odds = odds }
        end
    end
end
check("HANDOFF the colors table read: six groups", #order == 6, #order)

local byTitle = {}
for g, G in pairs(DP.CAB_ODDS) do byTitle[G.heading] = g end
for _, title in ipairs(order) do
    local g = byTitle[title]
    check("HANDOFF a group for " .. title, g ~= nil)
    if g then
        local G, H = DP.CAB_ODDS[g], HCOL[title]
        -- the dashes in the group
        local mine = {}
        for did, gg in pairs(DP.CAB_GROUP) do if gg == g then mine[#mine + 1] = did end end
        table.sort(mine)
        local theirs = {}
        for i, d in ipairs(H.designs) do theirs[i] = d end
        table.sort(theirs)
        check("HANDOFF " .. title .. ": its dashes", join(mine) == join(theirs), join(mine) .. " vs " .. join(theirs))
        local nameToRamp = {}
        for i, nm in ipairs(H.names) do nameToRamp[nm] = H.ramps[i] end
        if G.always then
            check("HANDOFF " .. title .. ": always black", G.always == "v_black" and join(H.ramps) == "v_black", join(H.ramps))
            check("HANDOFF " .. title .. ": no odds table (always black)", HODDS[title] == nil)
            check("HANDOFF says public service is always black", md:find("Public service: always black.", 1, true) ~= nil)
        else
            local rows = HODDS[title]
            check("HANDOFF " .. title .. ": an odds table", rows ~= nil)
            rows = rows or {}
            check("HANDOFF " .. title .. ": the same rows", #rows == #G.rows, #rows .. " vs " .. #G.rows)
            for ri = 1, math.min(#rows, #G.rows) do
                local h, l = rows[ri], G.rows[ri]
                check("HANDOFF " .. title .. " row " .. ri .. ": paint words", join(h.paint) == join(l.paint), join(h.paint) .. " vs " .. join(l.paint))
                local hs, ls, sum = {}, {}, 0
                -- (the leather table names its colors short: "black" is black leather)
                for i, o in ipairs(h.odds) do hs[i] = tostring(nameToRamp[o[1]] or nameToRamp[o[1] .. " leather"]) .. " " .. o[2] end
                for i, o in ipairs(l.odds) do ls[i] = o[1] .. " " .. o[2]; sum = sum + o[2] end
                check("HANDOFF " .. title .. " row " .. ri .. ": odds", join(hs) == join(ls), join(hs) .. " vs " .. join(ls))
                check("HANDOFF " .. title .. " row " .. ri .. ": adds to 100", sum == 100, sum)
            end
            -- every color the group offers is in its odds somewhere, and nothing else is
            local seen = {}
            for _, r in ipairs(G.rows) do for _, o in ipairs(r.odds) do seen[o[1]] = true end end
            local n = 0
            for _ in pairs(seen) do n = n + 1 end
            local all = true
            for _, rmp in ipairs(H.ramps) do all = all and seen[rmp] == true end
            check("HANDOFF " .. title .. ": the odds use the group's three colors", n == #H.ramps and all, n)
        end
    end
end
-- every paint word the handoff uses answers to a bucket
local known = {}
for _, words in pairs(DP.PAINT_WORDS) do for _, w in ipairs(words) do known[w] = true end end
for title, rows in pairs(HODDS) do
    for _, r in ipairs(rows) do for _, w in ipairs(r.paint) do check("HANDOFF the paint word '" .. w .. "' (" .. title .. ") has a bucket", known[w]) end end
end

-- ---------------------------------------------------------------------------
section("DATA")
-- ---------------------------------------------------------------------------
for did, g in pairs(DP.CAB_GROUP) do
    local des = PX.designs[did]
    check("DATA " .. did .. " is in DashPx", des ~= nil)
    if des then
        local G = DP.CAB_ODDS[g]
        local want = HCOL[G.heading].ramps
        if G.always then
            check("DATA " .. did .. ": one color, no cabins", des.cabins == nil and des.cabinTex == nil)
        else
            local ids = {}
            for i, c in ipairs(des.cabins or {}) do ids[i] = c.id end
            check("DATA " .. did .. ": the group's colors, lead first", join(ids) == join(want), join(ids) .. " vs " .. join(want))
            local tex = {}
            for _, n in ipairs(des.cabinTex or {}) do tex[n] = true end
            check("DATA " .. did .. ": the plate and the night pictures by color", tex[des.plate] and tex[des.night.plate] and tex[des.night.dark])
            local missing = {}
            for _, c in ipairs(des.cabins or {}) do
                for _, n in ipairs(des.cabinTex or {}) do
                    if not exists(TEXDIR .. n .. PX.cabinSep .. c.id .. ".png") then missing[#missing + 1] = n .. PX.cabinSep .. c.id end
                end
            end
            for n in pairs(des.sprites or {}) do
                if not tex[n] and not exists(TEXDIR .. n .. ".png") then missing[#missing + 1] = n end
            end
            check("DATA " .. did .. ": every picture in the folder", #missing == 0, missing[1])
            -- a model line's shadow read off the vinyl: each color has its own
            local need = {}
            for _, p in ipairs(des.parts) do
                if p.shadow == "cabin" then need.shadow = true end
                if p.tagShadow == "cabin" then need.tagShadow = true end
            end
            for _, c in ipairs(des.cabins or {}) do
                for k in pairs(need) do check("DATA " .. did .. " " .. c.id .. ": its " .. k, type(c[k]) == "string" and c[k]:match("^#%x%x%x%x%x%x$") ~= nil, c[k]) end
            end
        end
    end
end
check("DATA the race car has one color", PX.designs.race and PX.designs.race.cabins == nil)
check("DATA no plain plate left for a three-color dash", not exists(TEXDIR .. "dash_nyala.png") and not exists(TEXDIR .. "dash_luxury_night.png"))

-- ---------------------------------------------------------------------------
section("BUCKETS")
-- ---------------------------------------------------------------------------
local B = DP.paintBucket
local cases = {
    -- h, s, v, bucket
    { 0.5, 0.19, 0.39, "BLACK" }, { 0.5, 0.19, 0.40, "SILVER" }, { 0.5, 0.19, 0.749, "SILVER" }, { 0.5, 0.19, 0.75, "WHITE" },
    { 0.5, 0.20, 0.6, "BLUE" }, { 0.0, 0.5, 0.45, "RED" }, { 0.0, 0.5, 0.449, "MAROON" }, { 0.029, 0.5, 0.6, "RED" },
    { 0.03, 0.5, 0.6, "BROWN" }, { 0.189, 0.5, 0.6, "BROWN" }, { 0.19, 0.5, 0.6, "GREEN" }, { 0.469, 0.5, 0.6, "GREEN" },
    { 0.47, 0.5, 0.6, "BLUE" }, { 0.799, 0.5, 0.6, "BLUE" }, { 0.8, 0.5, 0.55, "RED" }, { 0.8, 0.5, 0.549, "MAROON" },
    { 0.949, 0.5, 0.6, "RED" }, { 0.95, 0.5, 0.6, "RED" }, { 0.97, 0.5, 0.3, "MAROON" }, { 1.0, 0.6, 0.6, "RED" },
    -- the special cars: their livery's paint (doColor false) reads white
    { 0, 0.1, 0.9, "WHITE" },
}
for _, c in ipairs(cases) do
    check(string.format("BUCKETS h %.3f s %.2f v %.3f -> %s", c[1], c[2], c[3], c[4]), B(c[1], c[2], c[3]) == c[4], B(c[1], c[2], c[3]))
end
-- vanilla's own paints (BaseVehicle.doVehicleColor), corner to corner
local function corners(h0, h1, s0, s1, v0, v1, want)
    for _, h in ipairs({ h0, h1 }) do for _, s in ipairs({ s0, s1 }) do for _, v in ipairs({ v0, v1 }) do
        local got = B(h, s, v)
        local okk = false
        for _, w in ipairs(want) do okk = okk or got == w end
        check(string.format("BUCKETS vanilla %s at %.2f/%.2f/%.2f", want[1], h, s, v), okk, got)
    end end end
end
corners(0, 0.029, 0.85, 1, 0.55, 0.85, { "RED" })
corners(0.55, 0.61, 0.85, 1, 0.65, 0.75, { "BLUE" })
corners(0.15, 0.15, 0, 0.1, 0.7, 0.8, { "WHITE", "SILVER" })
corners(0, 1, 0, 0.1, 0.1, 0.25, { "BLACK" })
check("BUCKETS nothing to read: nil", B(nil, 0.5, 0.5) == nil and B("x", 1, 1) == nil and B(0, 0, 0) == nil and B(0 / 0, 0.5, 0.5) == nil)

-- ---------------------------------------------------------------------------
section("ROWS")
-- ---------------------------------------------------------------------------
-- the row each bucket reads, by the handoff's words (index into the group's rows)
local WANT = {
    wagon = { RED = 1, MAROON = 1, BROWN = 1, GREEN = 2, BLUE = 3, WHITE = 4, SILVER = 4, BLACK = 4 },
    s70 = { RED = 3, MAROON = 3, BROWN = 3, GREEN = 1, BLUE = 2, WHITE = 4, SILVER = 4, BLACK = 4 },
    s80 = { RED = 1, MAROON = 1, BROWN = 3, GREEN = 3, BLUE = 2, WHITE = 4, SILVER = 4, BLACK = 4 },
    s90 = { RED = 3, MAROON = 3, BROWN = 1, GREEN = 1, BLUE = 2, WHITE = 1, SILVER = 2, BLACK = 3 },
    lux = { RED = 1, MAROON = 1, BROWN = 3, GREEN = 3, BLUE = 3, WHITE = 2, SILVER = 2, BLACK = 2 },
}
for g, rows in pairs(WANT) do
    for bucket, want in pairs(rows) do
        local _, ri = DP.cabRow(g, bucket)
        check("ROWS " .. g .. " " .. bucket .. " -> row " .. want, ri == want, ri)
    end
    local n = 0
    for _ in pairs(DP.PAINT_WORDS) do n = n + 1 end
    local m = 0
    for _ in pairs(rows) do m = m + 1 end
    check("ROWS " .. g .. ": every bucket placed", m == n, m)
end
-- the roll walks the row: roll < 80 the first color of an 80/20 row, 80 and up the second
check("ROWS a roll walks the odds", DP.cabinFor("wagon", "BLUE", 0) == "v_navy70" and DP.cabinFor("wagon", "BLUE", 79) == "v_navy70"
    and DP.cabinFor("wagon", "BLUE", 80) == "v_walnut" and DP.cabinFor("wagon", "BLUE", 99) == "v_walnut")
check("ROWS a three-color row's edges", DP.cabinFor("s80", nil, 0) == nil and DP.cabinFor("horizon", "BLACK", 39) == "v_maroon"
    and DP.cabinFor("horizon", "BLACK", 40) == "v_navy" and DP.cabinFor("horizon", "BLACK", 74) == "v_navy" and DP.cabinFor("horizon", "BLACK", 75) == "v_beige_d")
check("ROWS a dash in no group: nil", DP.cabinFor("race", "RED", 5) == nil and DP.cabinFor("nosuch", "RED", 5) == nil)

-- ---------------------------------------------------------------------------
section("ROLL")
-- ---------------------------------------------------------------------------
local bins, okRange, same = {}, true, true
for i = 0, 9 do bins[i] = 0 end
local N = 20000
for k = 1, N do
    local key = (k * 7919) % 99999989
    local r = DP.cabRoll(key)
    okRange = okRange and r >= 0 and r <= 99 and r == math.floor(r)
    same = same and DP.cabRoll(key) == r
    bins[math.floor(r / 10)] = bins[math.floor(r / 10)] + 1
end
check("ROLL 0..99, whole", okRange)
check("ROLL the same key, the same roll", same)
local lo, hi = N, 0
for i = 0, 9 do lo = math.min(lo, bins[i]); hi = math.max(hi, bins[i]) end
check("ROLL spread evenly (each tenth 8 to 12%)", lo > N * 0.08 and hi < N * 0.12, lo .. ".." .. hi)
check("ROLL the key as the game hands it (a number, -1 for none)", DP.cabRoll(-1) == DP.cabRoll(-1) and DP.cabRoll(12345678) ~= nil)
-- the odds come out as the table's: the 70s neutral row over many keys
local count = {}
for k = 1, N do
    local c = DP.cabinFor("nyala", "SILVER", DP.cabRoll(k * 104729))
    count[c] = (count[c] or 0) + 1
end
local function pct(c) return 100 * (count[c] or 0) / N end
check("ROLL the 70s neutral row: light brown 40, slate blue 30, moss green 30 (within 2)",
    math.abs(pct("v_ltbrown") - 40) < 2 and math.abs(pct("v_navy70") - 30) < 2 and math.abs(pct("v_moss") - 30) < 2,
    string.format("%.1f/%.1f/%.1f", pct("v_ltbrown"), pct("v_navy70"), pct("v_moss")))

-- ---------------------------------------------------------------------------
section("CAR")
-- ---------------------------------------------------------------------------
local Car = {}
Car.__index = Car
function Car:getModData() return self.md end
function Car:getColorHue() return self.h end
function Car:getColorSaturation() return self.s end
function Car:getColorValue() return self.v end
function Car:getKeyId() return self.key end
function Car:getId() return 3 end
local function car(t) t.md = t.md or {}; return setmetatable(t, Car) end

local blue = car({ key = 4815162, h = 0.58, s = 0.9, v = 0.7 })
local b1, r1, st1 = DP.carCabin(blue)
check("CAR an unstamped car reads its paint", b1 == "BLUE" and st1 == false, b1)
local first = DP.cabinFor("wagon", b1, r1)
check("CAR the same car, the same color, twice", DP.cabinFor("wagon", DP.carCabin(blue)) == first)
check("CAR stamped on first sight", DP.stampCabin(blue) == true and blue.md[DP.CAB_KEY] == b1 .. ":" .. r1, blue.md[DP.CAB_KEY])
check("CAR stamped once", DP.stampCabin(blue) == false)
blue.h, blue.s, blue.v = 0.0, 0.9, 0.7                -- repainted red after the stamp
local b2, r2, st2 = DP.carCabin(blue)
check("CAR a repaint after the stamp changes nothing", st2 and b2 == b1 and r2 == r1 and DP.cabinFor("wagon", b2, r2) == first)
-- multiplayer: another machine, the same car as the server sent it (same key, same paint), no stamp on its copy
local other = car({ key = 4815162, h = 0.58, s = 0.9, v = 0.7 })
check("CAR another machine works out the same color", DP.cabinFor("wagon", DP.carCabin(other)) == first)
local server = car({ key = 4815162, h = 0.58, s = 0.9, v = 0.7 })
DP.stampCabin(server)
check("CAR the server's stamp is the client's answer", server.md[DP.CAB_KEY] == blue.md[DP.CAB_KEY], server.md[DP.CAB_KEY])
-- an existing car (saved before this version): no stamp, a paint and a key: rolled once, then kept
local old = car({ key = 777, h = 0.15, s = 0.05, v = 0.72, md = { ZeD_odo = 41000, ZeD_ash = true } })
local ob = DP.carCabin(old)
DP.stampCabin(old)
check("CAR an existing car gets its stamp, its other keys kept", old.md[DP.CAB_KEY] ~= nil and old.md.ZeD_odo == 41000 and old.md.ZeD_ash == true and ob == "SILVER")
-- different keys, different rolls (the colors vary across a lot)
local seen = {}
for k = 1, 200 do
    local b, r = DP.carCabin(car({ key = k * 31337, h = 0.15, s = 0.05, v = 0.72 }))
    seen[DP.cabinFor("nyala", b, r) or "nil"] = true
end
check("CAR a lot of silver Nyalas shows all three colors", seen.v_moss and seen.v_ltbrown and seen.v_navy70)
-- a stamp that isn't ours is ignored, and replaced by nothing (only an absent stamp is written)
local junk = car({ key = 5, h = 0.58, s = 0.9, v = 0.7, md = { [DP.CAB_KEY] = "PURPLE:12" } })
local jb, _, jst = DP.carCabin(junk)
check("CAR junk in the stamp is read past", jb == "BLUE" and jst == false)
check("CAR stamps parse", DP.cabParse("BLUE:37") == "BLUE" and DP.cabParse("BLUE:100") == nil and DP.cabParse("blue:3") == nil and DP.cabParse(5) == nil)

-- ---------------------------------------------------------------------------
section("FLEET")
-- ---------------------------------------------------------------------------
for _, did in ipairs({ "police", "taxi", "ambulance", "fire", "ranger" }) do
    local allBlack = true
    for bucket in pairs(DP.PAINT_WORDS) do
        for r = 0, 99, 7 do allBlack = allBlack and DP.cabinFor(did, bucket, r) == "v_black" end
    end
    allBlack = allBlack and DP.cabinFor(did, nil, 50) == "v_black"
    check("FLEET " .. did .. " always black", allBlack)
end

-- ---------------------------------------------------------------------------
section("FALLBACK")
-- ---------------------------------------------------------------------------
local bare = setmetatable({ md = {} }, { __index = { getModData = function(self) return self.md end, getKeyId = function() return 99 end } })
local fb, fr = DP.carCabin(bare)
check("FALLBACK no paint getters: unread", fb == nil)
local _, fri = DP.cabRow("wagon", fb)
local _, sri = DP.cabRow("s70", fb)
local _, eri = DP.cabRow("s80", fb)
check("FALLBACK the white/silver/gray/black row (wagon, 70s, 80s)", fri == 4 and sri == 4 and eri == 4, tostring(fri) .. tostring(sri) .. tostring(eri))
check("FALLBACK the 90s and the leather: the row with silver", select(2, DP.cabRow("s90", nil)) == 2 and select(2, DP.cabRow("lux", nil)) == 2)
check("FALLBACK every civilian dash still gets a color", DP.cabinFor("nyala", fb, fr) ~= nil and DP.cabinFor("luxury", fb, fr) ~= nil and DP.cabinFor("primani", fb, fr) ~= nil)
check("FALLBACK an unread car is not stamped", DP.stampCabin(bare) == false and bare.md[DP.CAB_KEY] == nil)
local throws = car({ key = 1 })
throws.getColorHue = function() error("no such method") end
check("FALLBACK a getter that throws: unread, no error", DP.carCabin(throws) == nil)
check("FALLBACK no car at all", DP.carCabin(nil) == nil)
local unpainted = car({ key = 2, h = 0, s = 0, v = 0 })
check("FALLBACK a car not painted yet (0/0/0): unread", DP.carCabin(unpainted) == nil and DP.stampCabin(unpainted) == false)

print("dash_cabin_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
