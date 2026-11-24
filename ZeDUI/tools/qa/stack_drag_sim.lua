-- ZeDUI/tools/qa/stack_drag_sim.lua  (Nov 23 2026, QA L2-1): a CLOSED stack of 5 dragged from a bag held in the hand
-- (the Character window showing that bag alone: one column, colStates[1]) and released on another bag's button in
-- the container strip carries all 5; one row of the OPEN stack carries 1. Loads the REAL InventoryRenderer.lua
-- (handleDrop, dragItems, dragNoRoom), GridLayout.lua and ItemRules.lua on a stub world, no game running.
--   PRESS  ZeD_CharacterWindow.lua's row press names the column and its container before the drag begins
--   DROP   handleDrop: strip button (Character "cnt:N", World bare index), another column, the other window, the floor
--   ROOM   QA L2-1's real cause: the worn front bag was a Fanny Pack (Capacity 1) and Woodglue weighs 1.0, so the
--          game's transfer lands 1 and refuses 4; ZeD queues all 5 and its drag chip reads "No room" over that button
-- Run from the repo root:  lua51 ZeDUI/tools/qa/stack_drag_sim.lua
-- It prints FAIL lines and a last line "stack_drag_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]stack_drag_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function readAll(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

-- ===========================================================================
-- PRESS: the row press sets the drag's source column and container before beginPending (static read of the file)
-- ===========================================================================
do
    local src = readAll(CLIENT .. "ZeD_CharacterWindow.lua") or ""
    local a = src:find("local colIdx, colCs = getColumnAtX(self, x)", 1, true)
    local b = a and src:find("self._drag:beginPending(", a, true)
    local seg = (a and b) and src:sub(a, b) or ""
    check("PRESS: the Character window's row press finds its column", a ~= nil)
    check("PRESS: ... and names it the drag's source column", seg:find("self._dragSourceCol = colIdx", 1, true) ~= nil)
    check("PRESS: ... and its container the drag's source", seg:find("self._dragSourceInv = colCs.inventory", 1, true) ~= nil)
    local w = readAll(CLIENT .. "ZeD_WorldWindow.lua") or ""
    check("PRESS: the World window's row press does the same", w:find("self._dragSourceCol = colIdx", 1, true) ~= nil
        and w:find("self._dragSourceInv = colCs.inventory", 1, true) ~= nil)
end

-- ===========================================================================
-- the stub world
-- ===========================================================================
local stub
stub = setmetatable({}, { __index = function() return stub end, __call = function() return stub end })
function require() end
ZeD = setmetatable({}, { __index = function() return stub end })
ISPanel = { derive = function() return setmetatable({}, { __index = stub }) end }
local okL, errL = pcall(assert(loadfile(CLIENT .. "InventoryRenderer.lua")))
check("InventoryRenderer.lua loads on the stubs", okL, errL)
rawset(ZeD, "GridLayout", {}); rawset(ZeD, "ItemRules", {})
check("GridLayout.lua loads", (pcall(assert(loadfile(CLIENT .. "GridLayout.lua")))))
check("ItemRules.lua loads", (pcall(assert(loadfile(CLIENT .. "ItemRules.lua")))))
local IR = ZeD.InventoryRenderer
local handleDrop = okL and IR.handleDrop
if not handleDrop then
    print("stack_drag_sim: " .. checks .. " checks, " .. (failed + 1) .. " failed")
    os.exit(1)
end

ZeD.EquipDoll = { takeDrop = function() return false end }
ZeD.Belt = { takeDrop = function() return false end }
ZeD.HealthTab = { takeDrop = function() return false end }
ZeD.Curtain = { dropTarget = function() return nil end }
ZeD.ContainerGates = { refuses = function() return false end }
ZeD.playerNumOf = function() return 0 end
IR.dirtyModels = function() end
IR.isGridKey = function() return false end
getPlayerInventory, getPlayerLoot = function() return nil end, function() return nil end
local MX, MY = 500, 500
getMouseX, getMouseY = function() return MX end, function() return MY end
local NOW = 1000
getTimestampMs = function() NOW = NOW + 1000; return NOW end
UIManager = { getUI = function() return { size = function() return 0 end } end }
ISInventoryPaneContextMenu = { dropItem = function(item) item._dropped = true end }

-- containers that hold things and count their weight; capacity as the game's hasRoomFor reads it
local function container(kind, cap)
    local c = { kind = kind, cap = cap, held = {} }
    c.getType = function() return c.kind end
    c.isItemAllowed = function() return true end
    c.weight = function() local w = 0; for _, it in ipairs(c.held) do w = w + it.w end; return w end
    c.hasRoomFor = function(_, _, w) return c.cap == nil or c:weight() + w <= c.cap end
    return c
end
local function thing(name, w, inv)
    local t = { name = name, w = w, inv = inv }
    t.getContainer = function() return t.inv end
    t.isFavorite = function() return false end
    t.getFullType = function() return "Base." .. name end
    t.getUnequippedWeight = function() return t.w end
    inv.held[#inv.held + 1] = t
    return t
end
-- the game's transfer: queued, then run in order; each one checks room as ISInventoryTransferAction:isValid does
local queue = {}
ISTimedActionQueue = { add = function(a) queue[#queue + 1] = a end }
ISInventoryTransferUtil = { newInventoryTransferAction = function(_, item, src, dst) return { item = item, src = src, dst = dst } end }
local function runQueue()
    local landed = 0
    for _, a in ipairs(queue) do
        if a.item.inv == a.src and a.dst:hasRoomFor(nil, a.item.w) then
            for i, it in ipairs(a.src.held) do if it == a.item then table.remove(a.src.held, i); break end end
            a.dst.held[#a.dst.held + 1] = a.item
            a.item.inv = a.dst
            landed = landed + 1
        end
    end
    return landed
end

local main = container("none", nil)
local back = container("Bag_Schoolbag", nil)      -- the held back bag
local player = { getPlayerNum = function() return 0 end, getInventory = function() return main end, getVehicle = function() return nil end }

-- a ZeD list panel
local function panel(inv)
    local c = { _inventory = inv, _playerObj = player, _stacks = {}, _expandedStacks = {}, _hitZones = {} }
    c.over = false
    c.getMouseX = function() return 10 end
    c.getMouseY = function() return 10 end
    c.getHeight = function() return 600 end
    c.getAbsoluteX = function() return 0 end
    c.hitZoneAt = function() return nil end
    c.isMouseOver = function() return c.over end
    return c
end
-- a container strip: the pointer over one button (zid), or over none
local function strip()
    local s = { zid = nil, over = false }
    s.isMouseOver = function() return s.over end
    s.getMouseX = function() return 5 end
    s.getMouseY = function() return 5 end
    s.hitZoneAt = function() return s.zid and { id = s.zid } or nil end
    return s
end

-- the Character window shows the held back bag alone (one column, colStates[1], as renderMultiColumnContent binds it)
local cc = panel(back)
local cstrip = strip()
local cwin = { _contentPanel = cc, _containerStrip = cstrip, getIsVisible = function() return false end }
local wc = panel(container("crate", nil))
local wstrip = strip()
local wwin = { _contentPanel = wc, _containerStrip = wstrip, getIsVisible = function() return false end }
ZeD_CharacterWindow = { getWindow = function() return cwin end }
ZeD_WorldWindow = { getWindow = function() return wwin end }
ZeD_WorldWindow.transferFromFloor = function() end

-- five Woodglue (1.0 each) in the back bag, one closed stack; its row is the first
local glue
local function stage(front)
    queue = {}
    back.held = {}
    glue = {}
    for i = 1, 5 do glue[i] = thing("Woodglue", 1.0, back) end
    local stk = { rep = glue[1], items = glue, count = 5, key = "Base.Woodglue" }
    cc._stacks = { [glue[1]] = stk }
    cc._expandedStacks = {}
    cc._colStates = { { inventory = back, stacks = cc._stacks, expandedStacks = cc._expandedStacks, renderX = 0, renderW = 300,
        selectedItems = {} } }
    cwin._containers = { { inventory = main, isMain = true }, { inventory = back }, { inventory = front } }
end
-- the press (the column named as the window's row press names it), then the release
local function drag(rows)
    cc._dragSourceCol = 1
    cc._dragSourceInv = cc._colStates[1].inventory
    handleDrop(cc, rows, cc._dragSourceInv)
    cc._dragSourceCol, cc._dragSourceInv = nil, nil
end
local function overStrip(s, zid)
    cstrip.over, wstrip.over, cstrip.zid, wstrip.zid = false, false, nil, nil
    cc.over, wc.over = false, false
    -- (the strip sits beside the list: over a button, the pointer is left of the list's columns)
    cc.getMouseX = function() return s and -20 or 10 end
    if s then s.over, s.zid = true, zid end
end
local function count(inv) local n = 0; for _, it in ipairs(inv.held) do if it.name == "Woodglue" then n = n + 1 end end; return n end

-- ===========================================================================
-- DROP
-- ===========================================================================
-- 1. a roomy front bag (a Satchel, 12): the closed stack on its button, all 5 queued and all 5 land
local satchel = container("Bag_Satchel", 12)
stage(satchel)
overStrip(cstrip, "cnt:3")
drag({ glue[1] })
check("DROP 1: the held bag's closed stack on the front bag's strip button queues all 5", #queue == 5, #queue)
check("DROP 1: ... and all 5 land in the front bag", runQueue() == 5 and count(satchel) == 5, count(satchel))

-- 2. the stack opened in the held bag's column: one row carries exactly 1
satchel.held = {}
stage(satchel)
cc._colStates[1].expandedStacks["Base.Woodglue"] = true
overStrip(cstrip, "cnt:3")
drag({ glue[2] })
check("DROP 2: one row of the open stack queues exactly its one thing", #queue == 1 and queue[1].item == glue[2], #queue)

-- 3. the column's own open-stack table wins over the panel's (another column's opened stack does not leak in)
satchel.held = {}
stage(satchel)
cc._expandedStacks = { ["Base.Woodglue"] = true }
cc._colStates[1].expandedStacks = {}
overStrip(cstrip, "cnt:3")
drag({ glue[1] })
check("DROP 3: shut in the dragged column, all 5 go though the panel's own table has it open", #queue == 5, #queue)

-- 4. the main inventory's button (the strip's named top button)
stage(satchel)
overStrip(cstrip, "main_toggle")
drag({ glue[1] })
check("DROP 4: on the main inventory's button all 5 are queued", #queue == 5 and queue[1].dst == main, #queue)

-- 5. a World window strip button (bare index)
local crateB = container("crate", nil)
wwin._containers = { { inventory = crateB } }
stage(satchel)
overStrip(wstrip, 1)
drag({ glue[1] })
check("DROP 5: on a World window button all 5 are queued", #queue == 5 and queue[1].dst == crateB, #queue)

-- 6. the World window's list
stage(satchel)
overStrip(nil)
wc.over = true
drag({ glue[1] })
check("DROP 6: on the World window's list all 5 are queued", #queue == 5 and queue[1].dst == wc._inventory, #queue)
wc.over = false

-- 7. another column of the same window (two columns: the held bag, then the satchel)
stage(satchel)
overStrip(nil)
cc._colStates[1].renderW = 5
cc._colStates[2] = { inventory = satchel, stacks = {}, expandedStacks = {}, renderX = 5, renderW = 300, selectedItems = {} }
drag({ glue[1] })
check("DROP 7: on another column all 5 are queued", #queue == 5 and queue[1].dst == satchel, #queue)
cc._colStates[2] = nil

-- 8. the floor (released over the world, no window under the pointer)
stage(satchel)
overStrip(nil)
local okF = pcall(drag, { glue[1] })
local dropped = 0
for _, g in ipairs(glue) do if g._dropped then dropped = dropped + 1 end end
check("DROP 8: released over the world, all 5 are dropped", okF and dropped == 5, dropped)

-- ===========================================================================
-- ROOM: QA L2-1's front bag, a worn Fanny Pack (Capacity 1), and Woodglue at 1.0 each
-- ===========================================================================
local fanny = container("Bag_FannyPackFront", 1)
stage(fanny)
overStrip(cstrip, "cnt:3")
drag({ glue[1] })
check("ROOM 1: ZeD queues all 5 for the Fanny Pack", #queue == 5, #queue)
local landed = runQueue()
check("ROOM 1: ... the game's transfer lands 1 (1.0 fills Capacity 1) and refuses 4: L2-1's count, a room limit",
    landed == 1 and count(fanny) == 1 and count(back) == 4, landed)
-- the drag chip over that button reads "No room" (dragNoRoom); over the roomy Satchel it does not
stage(fanny)
overStrip(cstrip, "cnt:3")
cc._dragSourceCol, cc._dragSourceInv = 1, back
cc._drag = { isActive = function() return true end, items = { glue[1] } }
check("ROOM 2: the drag chip reads No room over the Fanny Pack's button", IR.dragNoRoom(0) == true)
satchel.held = {}
stage(satchel)
overStrip(cstrip, "cnt:3")
cc._dragSourceCol, cc._dragSourceInv = 1, back
cc._drag = { isActive = function() return true end, items = { glue[1] } }
check("ROOM 2: ... and not over the Satchel's", IR.dragNoRoom(0) == false)

print("stack_drag_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
