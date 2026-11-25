-- ZeDUI/tools/qa/loot_calls_noroom_sim.lua  (Nov 24 2026; loot KISS call 6, ZeDUI/qa/audits/2026-11-24_kiss_loot.md)
-- Pad X into a bag that can't take it says "No room", the mouse drag chip's word (UI_ZeD_Drag_NoRoom). The chip is
-- drawn only under a mouse drag, so the pad's word is ZeD's notice over the head (ZeD.Bubbles.note, "bad"), as the
-- add-on rules' refusals show.
--   ROOM     ContainerControls CT.noRoom (cut): a refused thing, or a weight that does not fit; the floor and things
--            already in the bag are not asked
--   MOVE     CT.moveToOther (cut): no room = the note once, nothing moves, false (pad marks stay); room = the old
--            moves; a heavy thing alone out of the world still goes into the hands; asleep = nothing, no note
--   WIRED    pad X on a row and on an open stack's header both go through CT.moveToOther; the drag chip keeps the key
-- Run from the repo root:  lua51 ZeDUI/tools/qa/loot_calls_noroom_sim.lua
-- It prints FAIL lines and a last line "loot_calls_noroom_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]loot_calls_noroom_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

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
    return (s:gsub("\r\n", "\n"))
end
local function cut(src, from, to)
    local a = src and string.find(src, from, 1, true)
    if not a then return nil end
    local b = string.find(src, to, a, true)
    if not b then return nil end
    return string.sub(src, a, b + #to - 1) .. "\n"
end
local function has(src, s) return src ~= nil and string.find(src, s, 1, true) ~= nil end

local CC = readFile(Z .. "ContainerControls.lua") or ""
local IR = readFile(Z .. "InventoryRenderer.lua") or ""
local MO = readFile(Z .. "Molecules.lua") or ""
local EN = readFile(ROOT .. "42/media/lua/shared/Translate/EN/UI.json") or ""
check("SOURCE: files read", #CC > 0 and #IR > 0 and #MO > 0 and #EN > 0)

-- stand-ins: a container with a type, a capacity and a refused set; a thing with a weight and its container
local function bag(cap, kind)
    local b = { cap = cap, used = 0, kind = kind or "bag", refuse = {} }
    function b:getType() return self.kind end
    function b:isItemAllowed(item) return not self.refuse[item] end
    function b:hasRoomFor(_, w) return self.used + w <= self.cap end
    return b
end
local function thing(w, inside)
    local t = { w = w, c = inside }
    function t:getContainer() return self.c end
    function t:getUnequippedWeight() return self.w end
    return t
end
local asleep = false
local player = { getPlayerNum = function() return 0 end, isAsleep = function() return asleep end }

-- ---------------------------------------------------------------------------
print("-- ROOM: the drag chip's test")
local src = (cut(CC, "function CT.noRoom(playerObj, items, dest)", "\nend\n") or "")
    .. (cut(CC, "function CT.moveToOther(content, items)", "\nend\n") or "")
check("ROOM: both functions found", has(src, "CT.noRoom") and has(src, "CT.moveToOther"))
CT = {}
local notes, grabbed, moved, other = {}, nil, nil, nil
ZeD = { tr = function(k) return k end,
        Bubbles = { note = function(pn, text, tone) notes[#notes + 1] = { pn = pn, text = text, tone = tone } end } }
getTimestampMs = function() return 1234 end
local heavy = {}
isForceDropHeavyItem = function(item) return heavy[item] == true end
local fn, e = loadstring("local isFloor, otherInventory = ...\n" .. src, "noroom")
check("ROOM: loads", fn ~= nil, e)
if fn then
    fn(function(inv) return inv ~= nil and inv:getType() == "floor" end, function() return other end)
    CT.grabItems = function(po, items, dest) grabbed = { items = items, dest = dest }; return true end
    CT.moveItems = function(po, items, dest) moved = { items = items, dest = dest } end

    local crate = bag(100, "crate")
    local pack = bag(5)
    local a, b = thing(3, crate), thing(3, crate)
    check("ROOM: one that fits", CT.noRoom(player, { a }, pack) == false)
    check("ROOM: two that don't fit together", CT.noRoom(player, { a, b }, pack) == true)
    pack.refuse[a] = true
    check("ROOM: a refused thing", CT.noRoom(player, { a }, pack) == true)
    pack.refuse[a] = nil
    local inPack = thing(4, pack)
    check("ROOM: a thing already there is not counted", CT.noRoom(player, { inPack, a }, pack) == false)
    check("ROOM: the floor has no limit here", CT.noRoom(player, { a, b }, bag(0, "floor")) == false)
    check("ROOM: nothing weighed", CT.noRoom(player, { thing(0, crate) }, bag(0)) == false)

    -- -----------------------------------------------------------------------
    print("-- MOVE: pad X")
    local charSide = { _playerObj = player, _ccSide = "char" }
    local worldSide = { _playerObj = player, _ccSide = "world" }
    other = pack
    notes, grabbed, moved = {}, nil, nil
    local r = CT.moveToOther(worldSide, { a, b })
    check("MOVE: no room from the World window says so", #notes == 1 and notes[1].text == "UI_ZeD_Drag_NoRoom"
        and notes[1].tone == "bad" and notes[1].pn == 0, #notes)
    check("MOVE: and moves nothing, false", r == false and grabbed == nil and moved == nil)
    check("MOVE: QA's field set", CT.lastNoRoom == 1234)
    notes = {}
    r = CT.moveToOther(charSide, { a, b })
    check("MOVE: no room from his side says so too", r == false and #notes == 1 and moved == nil)
    notes = {}
    r = CT.moveToOther(worldSide, { a })
    check("MOVE: room = the grab as before", r == true and #notes == 0 and grabbed and grabbed.dest == pack)
    r = CT.moveToOther(charSide, { a })
    check("MOVE: room = his side's move as before", r == true and #notes == 0 and moved and moved.dest == pack)
    local log = thing(50, crate)
    heavy[log] = true
    grabbed = nil
    r = CT.moveToOther(worldSide, { log })
    check("MOVE: a heavy thing alone still goes to the hands", r == true and #notes == 0 and grabbed and grabbed.items[1] == log)
    moved = nil
    r = CT.moveToOther(charSide, { log })
    check("MOVE: a heavy thing from his side into a small bag is no room", r == false and #notes == 1 and moved == nil)
    notes = {}
    asleep = true
    r = CT.moveToOther(worldSide, { a, b })
    check("MOVE: asleep, nothing and no note", r == false and #notes == 0)
    asleep = false
    other = nil
    r = CT.moveToOther(worldSide, { a })
    check("MOVE: nowhere to go stays false, no note", r == false and #notes == 0)
end

-- ---------------------------------------------------------------------------
print("-- WIRED")
local padMove = cut(IR, "function ZeD.InventoryRenderer.padMove(w, el)", "\nend\n")
local headMove = cut(IR, "local function headMove(w, el)", "\nend\n")
check("WIRED: pad X on a row goes through moveToOther", has(padMove, "CT.moveToOther(cnt, items)"))
check("WIRED: pad X on a stack header too", has(headMove, "CT.moveToOther(cnt,"))
check("WIRED: the drag chip reads the same key", has(MO, 'ZeD.tr("UI_ZeD_Drag_NoRoom")'))
check("WIRED: the key is in EN", has(EN, '"UI_ZeD_Drag_NoRoom": "No room"'))

print("loot_calls_noroom_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
