-- ZeDUI/tools/qa/xfer_floor_sim.lua  (Nov 24 2026, Build; the director: "transfer all would transfer to the floor,
-- wouldn't it? How does the vanilla game do it?")
-- The game's Transfer all (ISInventoryPane:transferAll) sends your things to the loot pane's container, which is the
-- floor when nothing else is open. ZeD's Character window had no "other side" with the World window shut, so its
-- Transfer all did nothing. Now:
--   DEST     ContainerControls transferDest (cut from the real file): the World window's container when it has one;
--            from your side with the World window shut (or no container across), the game's own floor container
--            (ISInventoryPage.GetFloorContainer, the one ZeD's World window shares); from the World window's side it
--            stays otherInventory (never the floor fallback)
--   WIRED    buildChar's Transfer all and its marked form (the controller's marks) read transferDest, so the button is
--            on and drops with the World window shut, worded Drop for the marks; the single-row moves (the controller's
--            X: moveToOther, the X prompt, a drag) still read otherInventory, so nothing drops by accident
-- Run from the repo root:  lua51 ZeDUI/tools/qa/xfer_floor_sim.lua
-- It prints FAIL lines and a last line "xfer_floor_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]xfer_floor_sim%.lua$", "")
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

local CC = readFile(Z .. "ContainerControls.lua") or ""
check("SOURCE: ContainerControls.lua read", #CC > 0)

-- ---------------------------------------------------------------------------
print("-- DEST: where Transfer all sends things")
local function container(kind) return { kind = kind, getType = function() return kind end } end
local FLOOR = container("floor")
local CRATE = container("crate")
local OTHER = {}
local floorAsked
ZeD = { playerNumOf = function(c) return c._pn or 0 end }
ISInventoryPage = { GetFloorContainer = function(pn) floorAsked = pn; return FLOOR end }
local src = cut(CC, "local function transferDest(content)", "\nend\n")
check("DEST: transferDest found in ContainerControls.lua", src ~= nil)
local transferDest
if src then
    local fn, e = loadstring("local otherInventory, zedFloor = ...\n" .. src .. "return transferDest", "transferDest")
    check("DEST: transferDest loads", fn ~= nil, e)
    if fn then
        transferDest = fn(function(c) return OTHER[c._ccSide] end, function() return nil end)
    end
end
if transferDest then
    local char, world = { _ccSide = "char", _pn = 0 }, { _ccSide = "world", _pn = 0 }
    OTHER.char = CRATE
    check("DEST: World window open on a crate: your Transfer all goes to the crate", transferDest(char) == CRATE)
    OTHER.char = nil
    floorAsked = nil
    check("DEST: World window shut: your Transfer all goes to the floor", transferDest(char) == FLOOR)
    check("DEST: the floor is the game's own floor container for your player", floorAsked == 0, floorAsked)
    local p2 = { _ccSide = "char", _pn = 2 }
    floorAsked = nil
    transferDest(p2)
    check("DEST: split screen: player 3's floor", floorAsked == 2, floorAsked)
    OTHER.world = nil
    floorAsked = nil
    check("DEST: from the World window's side there is no floor fallback", transferDest(world) == nil and floorAsked == nil)
    OTHER.world = CRATE
    check("DEST: from the World window's side it is the other side as before", transferDest(world) == CRATE)
    -- no game floor getter: ZeD's own (nil while the World window is shut) and no crash
    ISInventoryPage = nil
    check("DEST: without the game's getter, ZeD's own floor (none here) and no error", transferDest(char) == nil)
end

-- ---------------------------------------------------------------------------
print("-- WIRED: which moves fall back")
local build = cut(CC, "local function buildChar(content)", "\nend\n") or ""
check("WIRED: buildChar found", #build > 0)
local n = 0
for _ in string.gmatch(build, "transferDest%(") do n = n + 1 end
check("WIRED: buildChar's Transfer all and its marked form read transferDest (2 builds, 2 runs)", n == 4, n)
check("WIRED: the marked form's Drop wording follows transferDest's floor",
    build:find("local toFloor = xdest ~= nil and isFloor(xdest)", 1, true) ~= nil)
local move = cut(CC, "function CT.moveToOther(content, items)", "\nend\n") or ""
check("WIRED: the controller's X on a row (moveToOther) still reads otherInventory, not the floor",
    move:find("otherInventory(content)", 1, true) ~= nil and move:find("transferDest", 1, true) == nil)
local IR = readFile(Z .. "InventoryRenderer.lua") or ""
check("WIRED: the X prompt and drops read otherInventory only (no floor fallback outside Transfer all)",
    IR:find("transferDest", 1, true) == nil)

print("xfer_floor_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
