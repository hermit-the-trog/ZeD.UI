-- ZeDUI/tools/qa/belt_row_drag_msgs_sim.lua  (Belt row, the director, Nov 23 2026), no game running.
-- The real ZeD_Belt.lua and ZeD_ErrorBox.lua on Lua 5.1 stubs of the game and ZeD's library:
--   BAG     the bag button under a drag: "fit" while the bag it has picked (the Pocket by default, or a worn bag) can
--           take one of the dragged items, else "no": already in that bag, the bag itself, the bag's own rule
--           (isItemAllowed), an add-on's rule (ZeD.ItemRules), its room (hasRoomFor), a mod's gate (ContainerGates)
--   DRAW    the drag states drawn on the white block: the accent's wash and edge for fit (doubled with the pointer on
--           it), the ink wash (NO_A) for no; the five speed keys grey under a drag; nothing without a drag
--   DROP    a drop on the bag moves what fits through ContainerControls.moveItems into that bag (a list's closed
--           stack with it); nothing fitting moves nothing; a drop on a speed key or the notice is swallowed
--   ROW     the Messages notice's place: after the speed keys, an icon's gap, and before the chat key, an icon's gap;
--           single player's row ends with it; on a server it follows the belt; none on player two's row
--   PLACE   the notice element stands on the row's place while the belt draws, shown all the time; the balloons'
--           anchor is its top middle there; the pad's mark (E.padOn) while the belt's pad walk is on it
--   CORNER  the belt away (dead, driving, hidden): the notice back in the screen's corner with the corner's rules
--   MARK    the error marker rises from the screen's bottom under the notice's row place, ends where the notice's
--           bottom stood and lifts the notice by its height, as in the corner
--   WIDTH   the row's widths with a watch and 8 slots: 1280 x 800 at 1x and 3840 x 2160 at 1.75 (printed)
-- Run from the repo root:  lua51 ZeDUI/tools/qa/belt_row_drag_msgs_sim.lua
-- It prints FAIL lines and a last line "belt_row_drag_msgs_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]belt_row_drag_msgs_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local rawPrint = print
print = function(s) if not tostring(s):find("^%[ZeD%]") then rawPrint(s) end end

-- ---------------------------------------------------------------------------
-- THE GAME, as far as the belt and the notice ask
-- ---------------------------------------------------------------------------
local env
local LOG = {}
local function logv(x)
    if type(x) == "number" then return string.format("%.3f", x) end
    if type(x) == "table" then return x.name or "{tbl}" end
    return tostring(x)
end

local function event()
    local e = { list = {} }
    function e.Add(f) e.list[#e.list + 1] = f end
    function e.Remove(f) for i = #e.list, 1, -1 do if e.list[i] == f then table.remove(e.list, i) end end end
    return e
end
local function fire(name, ...)
    local l = {}
    for i, f in ipairs(Events[name].list) do l[i] = f end
    for _, f in ipairs(l) do f(...) end
end
local function list(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end,
             getItemByIndex = function(_, i) return t[i + 1] end }
end

-- a container: rules by item (allowed), room by weight left
local function container(name, room)
    local c = { name = name, room = room or 100, refuse = {} }
    function c:isItemAllowed(it) return not self.refuse[it] end
    function c:hasRoomFor(p, w) return (w or 0) <= self.room end
    function c:getType() return "none" end
    return c
end
local Item = {}
Item.__index = Item
local function item(t)
    t.name = t.name or "item"
    t.w = t.w or 1
    return setmetatable(t, Item)
end
function Item:getTex() return { name = "tex:" .. self.name } end
function Item:getDisplayName() return self.name end
function Item:getName() return self.name end
function Item:getContainer() return self.at end
function Item:getUnequippedWeight() return self.w end
function Item:getID() return self.id or 0 end
function Item:getFullType() return "Base." .. self.name end
function Item:getCategory() return self.inv and "Container" or "Item" end
function Item:getInventory() return self.inv end

local function newPlayer()
    local p = { dead = false, md = {}, carried = {}, worn = {} }
    p.main = container("Pocket", 100)
    function p:getPrimaryHandItem() return nil end
    function p:getSecondaryHandItem() return nil end
    function p:isDead() return self.dead end
    function p:getVehicle() return self.vehicle end
    function p:getWornItems() return list({}) end
    function p:isEquipped(it) return self.worn[it] == true end
    function p:isHandItem() return false end
    function p:getModData() return self.md end
    function p:getPlayerNum() return 0 end
    function p:getInventory()
        local me = self
        self.main.getItems = function() return list(me.carried) end
        return self.main
    end
    function p:setJoypadIgnoreAimUntilCentered() end
    return p
end

local SW, SH = 1920, 1080
local function installGlobals()
    Events = setmetatable({}, { __index = function(t, k) local e = event(); rawset(t, k, e); return e end })
    getTimestampMs = function() return env.clock end
    isMouseButtonDown = function() return false end
    getText = function(k) return k end
    getTextOrNull = function() return nil end
    getCore = function()
        return { getKey = function() return 0 end, getGameMode = function() return "Sandbox" end,
                 getScreenWidth = function() return SW end, getScreenHeight = function() return SH end,
                 getOptionLockCursorToWindow = function() return false end, getOptionUIFBO = function() return true end }
    end
    isIngameState = function() return true end
    getPlayerScreenLeft, getPlayerScreenTop = function() return 0 end, function() return 0 end
    getPlayerScreenWidth, getPlayerScreenHeight = function() return SW end, function() return SH end
    getTexture = function() return nil end
    Texture = { getSharedTexture = function() return nil end }
    instanceof = function() return false end
    getActivatedMods = function() return list({}) end
    getPlayerHotbar = function(pn) return env.hotbars[pn or 0] end
    getSpecificPlayer = function(pn) return env.players[pn or 0] end
    getPlayer = function() return env.players[0] end
    getPlayerContextMenu = function() return nil end
    isClient = function() return env.server == true end
    getMouseX, getMouseY = function() return env.mouseX end, function() return env.mouseY end
    setJoypadFocus = function(n, what) env.joyFocus = what end
    Joypad = { AButton = 1, BButton = 2, XButton = 3, YButton = 4 }
    JoypadState = nil
    UIManager = { getSpeedControls = function() return { getCurrentGameSpeed = function() return 1 end } end }
    ISUIHandler = nil
    ISMouseDrag = nil
    ISInventoryPane = { getActualItems = function(d) return d.items end }
    ISFPS = nil
    ZeD_CharacterWindow, ZeD_WorldWindow = nil, nil
    ZeD_Panel = setmetatable({}, { __index = function(_, k)
        if type(k) == "string" and k:sub(1, 4) == "draw" then
            return function(_, ...)
                local a = { k }
                for i = 1, select("#", ...) do a[#a + 1] = logv((select(i, ...))) end
                LOG[#LOG + 1] = table.concat(a, " ")
            end
        end
        return nil
    end })
    ZeD_Panel.__index = ZeD_Panel
    function ZeD_Panel:derive() local c = {}; c.__index = c; return setmetatable(c, { __index = ZeD_Panel }) end
    function ZeD_Panel:new(x, y, w, h) return { x = x, y = y, width = w, height = h, _vis = true } end
    function ZeD_Panel:getX() return self.x end
    function ZeD_Panel:getY() return self.y end
    function ZeD_Panel:getAbsoluteX() return self.x end
    function ZeD_Panel:getAbsoluteY() return self.y end
    function ZeD_Panel:getWidth() return self.width end
    function ZeD_Panel:getHeight() return self.height end
    function ZeD_Panel:setX(v) self.x = v end
    function ZeD_Panel:setY(v) self.y = v end
    function ZeD_Panel:setWidth(v) self.width = v end
    function ZeD_Panel:setHeight(v) self.height = v end
    function ZeD_Panel:getMouseX() return env.mouseX - self.x end
    function ZeD_Panel:getMouseY() return env.mouseY - self.y end
    function ZeD_Panel:setCapture() end
    function ZeD_Panel:getIsVisible() return self._vis end
    function ZeD_Panel:isVisible() return self._vis end
    function ZeD_Panel:setVisible(v) self._vis = v end
    function ZeD_Panel:isMouseOver() return false end
    function ZeD_Panel:initialise() end
    function ZeD_Panel:addToUIManager() end
    function ZeD_Panel:setAlwaysOnTop() end
    function ZeD_Panel:backMost() end
    require = function() end
end

local function installZeD(scale)
    scale = scale or 1
    ZeD = { _trGen = 0 }
    ZeD.trDefaults = function() end
    ZeD.tr = function(k) return k end
    ZeD.textCase = function(s) return s end
    ZeD.logOnce = function(key, msg) env.errors[#env.errors + 1] = tostring(key) .. ": " .. tostring(msg) end
    ZeD.uiSound = function() end
    ZeD.windowsFor = function() return false end
    ZeD.Safe = { on = function() return env.safe end, guard = function(self, fn) return fn(self) end, register = function() end }
    ZeD.Settings = { lite = function() return false end, beltStyleOption = { getValue = function() return 1 end }, ammoBoxOn = function() return false end }
    ZeD.Watch = { beltWatch = function() return env.watch, nil, env.watch and "left" or nil end,
                  miniState = function() return { speed = 1 } end }
    local T = { scale = scale, art = math.max(1, math.floor(scale + 0.5 + 1e-6)), hair = math.max(1, math.floor(scale + 0.5)),
                fontF1 = "F1", fontF2 = "F2", fontF5 = "F5", fillBarH = 8,
                px = function(n) return math.floor(n * scale + 0.5) end, line = function(n) return n end }
    ZeD.WatchMini = { size = function() return 44 * T.art, 46 * T.art end, draw = function() end }
    local id = 0
    ZeD.T = setmetatable(T, { __index = function(t, k)
        id = id + 1
        local c = { r = id / 1000, g = 0.5, b = 0.25, a = 1, name = k }
        rawset(t, k, c)
        return c
    end })
    ZeD.TM = { getFontHeight = function() return 14 end, MeasureStringX = function(_, _, s) return #tostring(s) * 7 end }
    ZeD.Atoms = setmetatable({ fillBarCompactH = function() return 8 end, requestHint = function() end }, { __index = function(t, k)
        local f = function() end
        rawset(t, k, f)
        return f
    end })
    ZeD.Molecules = setmetatable({}, { __index = function() return function() end end })
    ZeD.Focus = { mark = function() return false end, isShowing = function() return false end, style = function() return "wash" end,
                  drawOverlay = function() end }
    ZeD.Messages = { sources = {}, toasts = {}, open = function() env.opened = env.opened + 1 end, count = function() return 0 end }
    function ZeD.Messages.unread()
        local n = 0
        for _, s in pairs(ZeD.Messages.sources) do for _, it in ipairs(s.items) do if not it.read then n = n + 1 end end end
        return n
    end
    ZeD.ItemRules = { check = function(it) if env.ruleNo[it] then return false, "no" end return true end }
    ZeD.ContainerGates = { refuses = function(inv) return env.gated[inv] == true end }
    ZeD.ContainerControls = { moveItems = function(p, items, dest) env.moves[#env.moves + 1] = { p = p, items = items, dest = dest } end }
    ZeD.InventoryRenderer = { dragItems = function(content, items) return content.stack or items end }
end

local function newEnv()
    env = { clock = 1000000, safe = false, server = false, mouseX = -100, mouseY = -100, errors = {}, opened = 0,
            ruleNo = {}, gated = {}, moves = {}, players = {}, hotbars = {}, watch = nil }
    local p = newPlayer()
    env.players[0] = p
    env.hotbars[0] = { chr = p, attachedItems = {}, availableSlot = {
        { slotType = "SmallBeltLeft", name = "Belt L", def = { attachments = {} } },
        { slotType = "SmallBeltRight", name = "Belt R", def = { attachments = {} } } } }
end

local function boot(scale)
    newEnv()
    ZeD_BeltHUD, ZeD_ErrorNotice, ZeD_ErrorMarker = nil, nil, nil
    installGlobals()
    installZeD(scale)
    assert(loadfile(Z .. "ZeD_Belt.lua"))()
    assert(loadfile(Z .. "ZeD_ErrorBox.lua"))()
    fire("OnGameStart")
    return ZeD.Belt, ZeD.ErrorBox
end

local function frame()
    LOG = {}
    local hud = ZeD.Belt.getHUD(0)
    hud:prerender()
    return table.concat(LOG, "\n"), hud
end
local function find(hud, kind, n)
    for i, b in ipairs(hud._boxes) do if b.kind == kind and (n == nil or b.n == n) then return b, i end end
    return nil
end
local function kinds(hud)
    local t = {}
    for _, b in ipairs(hud._boxes) do t[#t + 1] = b.kind .. (b.n ~= nil and tostring(b.n) or "") end
    return table.concat(t, ",")
end

-- ---------------------------------------------------------------------------
-- BAG
-- ---------------------------------------------------------------------------
do
    local B = boot()
    local p = env.players[0]
    local crate = container("Crate", 100)
    local apple = item({ name = "Apple", at = crate })
    local nail = item({ name = "Nail", at = p.main })
    check("BAG the Pocket: an apple from a crate fits", select(2, B.bagTakes(0, { apple }))[1] == apple)
    check("BAG the Pocket: what is already in it does not", #select(2, B.bagTakes(0, { nail })) == 0)
    local dest = B.bagTakes(0, { apple })
    check("BAG the Pocket's container is his main inventory", dest == p.main)
    -- a worn backpack picked
    local pack = item({ name = "Pack", id = 7, at = p.main, inv = container("PackInv", 5) })
    p.carried = { pack }
    p.worn[pack] = true
    B.bagPick(nil, 0, 7, "Base.Pack")
    dest = B.bagTakes(0, { apple })
    check("BAG a worn backpack picked: its own container", dest == pack.inv)
    check("BAG ... the bag itself dragged: no", #select(2, B.bagTakes(0, { pack })) == 0)
    local inPack = item({ name = "Bandage", at = pack.inv })
    check("BAG ... already in the backpack: no", #select(2, B.bagTakes(0, { inPack })) == 0)
    check("BAG ... from the Pocket into the backpack: fits", #select(2, B.bagTakes(0, { nail })) == 1)
    pack.inv.refuse[apple] = true
    check("BAG ... the bag's own rule (isItemAllowed) refuses: no", #select(2, B.bagTakes(0, { apple })) == 0)
    pack.inv.refuse[apple] = nil
    env.ruleNo[apple] = true
    check("BAG ... an add-on's rule (ItemRules) refuses: no", #select(2, B.bagTakes(0, { apple })) == 0)
    env.ruleNo[apple] = nil
    local anvil = item({ name = "Anvil", at = crate, w = 20 })
    check("BAG ... no room for its weight: no", #select(2, B.bagTakes(0, { anvil })) == 0)
    local mixed = select(2, B.bagTakes(0, { anvil, pack, apple, inPack }))
    check("BAG ... a mixed drag: only what fits (the apple)", #mixed == 1 and mixed[1] == apple, #mixed)
    env.gated[pack.inv] = true
    check("BAG ... a mod's gate refuses the bag: nothing", #select(2, B.bagTakes(0, { apple })) == 0)
    env.gated[pack.inv] = nil
    p.worn[pack] = nil
    B._bagCache[0] = nil
    check("BAG the backpack taken off: back to the Pocket", (B.bagTakes(0, { apple })) == p.main)
    env.players[0] = nil
    check("BAG no character: no bag, nothing", (B.bagTakes(0, { apple })) == nil)
end

-- ---------------------------------------------------------------------------
-- DRAW
-- ---------------------------------------------------------------------------
do
    local B = boot()
    local p = env.players[0]
    local crate = container("Crate", 100)
    local apple = item({ name = "Apple", at = crate })
    local hud
    local log
    log, hud = frame()
    local bag = find(hud, "bag")
    local sp = find(hud, "speed", 2)
    local NO = string.format("%.3f", 0.45)
    local function rectAt(L, b, a)
        return L:find("drawRect " .. logv(b.x) .. " " .. logv(b.y) .. " " .. logv(b.w) .. " " .. logv(b.h) .. " " .. a, 1, true) ~= nil
    end
    check("DRAW no drag: no wash on the bag button", not rectAt(log, bag, "0.140") and not rectAt(log, bag, NO))
    check("DRAW no drag: no wash on a speed key", not rectAt(log, sp, NO))
    ISMouseDrag = { dragging = { items = { apple } } }
    log = frame()
    check("DRAW a drag that fits the Pocket: the bag button's accent wash (fit)", rectAt(log, bag, "0.140"))
    check("DRAW ... and its accent edge", log:find("drawRectBorder " .. logv(bag.x) .. " " .. logv(bag.y) .. " " .. logv(bag.w) .. " " .. logv(bag.h) .. " 1.000 " .. logv(ZeD.T.accent.r), 1, true) ~= nil)
    check("DRAW ... the speed keys grey (the ink wash)", rectAt(log, sp, NO) and rectAt(log, find(hud, "speed", 0), NO))
    env.mouseX, env.mouseY = hud.x + bag.x + 2, hud.y + bag.y + 2
    log = frame()
    check("DRAW the pointer on the bag button: the stronger wash (fitHover)", rectAt(log, bag, "0.220"))
    check("DRAW ... the edge doubled", select(2, log:gsub("drawRectBorder [^\n]* " .. logv(ZeD.T.accent.r):gsub("%.", "%%."), "")) >= 2)
    env.mouseX, env.mouseY = -100, -100
    local nail = item({ name = "Nail", at = p.main })
    ISMouseDrag = { dragging = { items = { nail } } }
    env.clock = env.clock + 1000   -- (past the 250 ms the answer is kept for one drag)
    log = frame()
    check("DRAW a drag already in the Pocket: the bag button greys (no)", rectAt(log, bag, NO) and not rectAt(log, bag, "0.140"))
    ISMouseDrag = nil
    log = frame()
    check("DRAW the drag over: plain again", not rectAt(log, bag, NO) and not rectAt(log, sp, NO))
end

-- ---------------------------------------------------------------------------
-- DROP
-- ---------------------------------------------------------------------------
do
    local B = boot()
    local p = env.players[0]
    local crate = container("Crate", 100)
    local apple = item({ name = "Apple", at = crate })
    local apple2 = item({ name = "Apple", at = crate })
    local nail = item({ name = "Nail", at = p.main })
    local _, hud = frame()
    local bag = find(hud, "bag")
    env.mouseX, env.mouseY = hud.x + bag.x + 3, hud.y + bag.y + 3
    check("DROP on the bag button: taken", B.takeDrop(0, { apple, nail }) == true)
    local mv = env.moves[1]
    check("DROP ... moved through ContainerControls.moveItems into the Pocket, only what fits",
        mv and mv.dest == p.main and #mv.items == 1 and mv.items[1] == apple and mv.p == p)
    env.moves = {}
    local content = { _dragSourceInv = crate, stack = { apple, apple2 } }
    B.takeDrop(0, { apple }, content, crate)
    check("DROP a list's row brings its closed stack (the list's dragItems)", env.moves[1] and #env.moves[1].items == 2)
    env.moves = {}
    check("DROP nothing that fits: taken (no fall to the floor), nothing moved", B.takeDrop(0, { nail }) == true and #env.moves == 0)
    local sp = find(hud, "speed", 1)
    env.mouseX, env.mouseY = hud.x + sp.x + 2, hud.y + sp.y + 2
    check("DROP on a speed key: taken, nothing moved", B.takeDrop(0, { apple }) == true and #env.moves == 0)
    local nb = find(hud, "notice")
    env.mouseX, env.mouseY = hud.x + nb.x + 2, hud.y + nb.y + 2
    check("DROP on the notice's place: taken, nothing moved", B.takeDrop(0, { apple }) == true and #env.moves == 0)
end

-- ---------------------------------------------------------------------------
-- ROW
-- ---------------------------------------------------------------------------
do
    local B, E = boot()
    local _, hud = frame()
    local nb, ni = find(hud, "notice")
    local s4 = find(hud, "speed", 4)
    check("ROW single player: the row ends with the notice", nb ~= nil and ni == #hud._boxes, kinds(hud))
    check("ROW ... an icon's gap after the last speed key", nb and nb.x - (s4.x + s4.w) == B.ICON_GAP, nb and (nb.x - (s4.x + s4.w)))
    check("ROW ... the notice's size (the bag button's, E.NOTE_U)", nb and nb.w == E.NOTE_U and nb.h == E.NOTE_U)
    -- on a server: no speed keys, the chat key after the notice
    ZeD.Chat = { onBelt = function() return true end, unread = function() return 0 end }
    env.server = true
    env.clock = env.clock + 2000
    frame()
    nb = find(hud, "notice")
    local chat, ci = find(hud, "chat")
    local strapEnd = hud._strap.x + hud._strap.w
    check("ROW on a server: belt, notice, chat in that order", kinds(hud):find("slot,notice,chat$") ~= nil, kinds(hud))
    check("ROW ... the notice an icon's gap off the belt", nb.x - strapEnd == B.ICON_GAP, nb.x - strapEnd)
    check("ROW ... the chat key an icon's gap after the notice", chat.x - (nb.x + nb.w) == B.ICON_GAP, chat.x - (nb.x + nb.w))
    env.server = false
    ZeD.Chat = nil
    -- safe mode: the notice may not show, no place
    env.safe = true
    check("ROW safe mode: no place for the notice", B.noticeOnRow(0) == false)
    env.safe = false
    check("ROW player two's row: no place (one notice for the screen)", B.noticeOnRow(1) == false and B.noticeOnRow(0) == true)
end

-- ---------------------------------------------------------------------------
-- PLACE, CORNER, MARK
-- ---------------------------------------------------------------------------
do
    local B, E = boot()
    local _, hud = frame()
    local el = E._note
    E.frame()
    local nb = find(hud, "notice")
    local rx, ry = hud.x + nb.x, hud.y + nb.y
    check("PLACE on the row: the notice at its place on the belt", el.x == rx and el.y == ry and el.width == nb.w,
        tostring(el.x) .. "," .. tostring(el.y) .. " vs " .. rx .. "," .. ry)
    check("PLACE ... shown with nothing new (the row's notice shows all the time)", el._vis == true)
    local ax, ay = E.anchor(0)
    check("PLACE the balloons come out of its top middle on the row", ax == rx + math.floor(nb.w / 2) and ay == ry)
    local x4, y4, s4, row = E.rect()
    check("PLACE E.rect says the row", row == true and x4 == rx and y4 == ry and s4 == nb.w)
    -- the pad on it: the belt's walk in row order
    local _, ni = find(hud, "notice")
    hud._gp = { idx = ni - 1, inList = false, row = 1, list = {} }
    check("PLACE the pad on the last speed key: no mark on the notice", E.padOn() == false)
    hud:onJoypadDirRight()
    check("PLACE Right: the pad's mark on the notice (E.padOn)", E.padOn() == true)
    hud:onJoypadDown(Joypad.AButton)
    check("PLACE A: Messages opens, the pad leaves", env.opened == 1 and hud._gp == nil and E.padOn() == false)
    -- a click that reaches the belt on the notice's place opens Messages too
    env.mouseX, env.mouseY = rx + 2, ry + 2
    hud:onMouseDown(nb.x + 2, nb.y + 2)
    check("PLACE a click on the notice's place through the belt: Messages", env.opened == 2)
    env.mouseX, env.mouseY = -100, -100

    -- CORNER: the belt away
    env.players[0].dead = true
    frame()
    E.frame()
    local cx, cy = SW - E.NOTE_U - E.EDGE_U, SH - E.NOTE_U - E.EDGE_U
    local _, _, _, row2 = E.rect()
    check("CORNER dead (the belt away): E.rect the corner", row2 == false)
    env.players[0].dead = false
    env.players[0].vehicle = { isDriver = function() return true end }
    frame()
    E.frame()
    check("CORNER driving: the corner, hidden with nothing new (the corner's rules)", el._vis == false and select(4, E.rect()) == false)
    ZeD.Messages.sources.ModA = { kind = "mods", items = { { read = false } } }
    E.frame()
    check("CORNER ... something unread: shown in the corner", el._vis == true and el.x == cx and el.y == cy, tostring(el.x) .. "," .. tostring(el.y))
    ZeD.Messages.sources.ModA = nil
    env.players[0].vehicle = nil
    frame()
    E.frame()
    check("CORNER out of the car: back on the row", el.x == rx and el.y == ry and el._vis == true)
    ISUIHandler = { allUIVisible = false }
    frame()
    E.frame()
    check("CORNER the UI hidden: the corner", select(4, E.rect()) == false)
    ISUIHandler = nil
    frame()
    E.frame()

    -- MARK: rises from the screen's bottom under the row's place
    local mk = E._marker
    local _, MH = E.markSize()
    local under = SH - (ry + nb.h)
    local T0 = env.clock
    ZeD.Messages.sources["ZeD-GUI"] = { kind = "err", items = { { read = false, count = 1 } } }
    E.frame()
    check("MARK a new error: the marker starts at the screen's bottom, at the notice's x and width",
        mk._vis == true and mk.y == SH and mk.x == rx and mk.width == nb.w, tostring(mk.y) .. "," .. tostring(mk.x))
    env.clock = T0 + 250
    E.frame()
    check("MARK half way: (its height + the gap under the notice) / 2 up", mk.y == SH - math.floor((MH + under) * 0.5 + 0.5), mk.y)
    env.clock = T0 + 500
    E.frame()
    check("MARK at the top: its bottom where the notice's bottom stood", mk.y == ry + nb.h - MH, mk.y)
    check("MARK ... the notice lifted by the marker's height", el.y == ry - MH and el.x == rx, el.y)
    env.clock = T0 + 4000
    E.frame()
    check("MARK down again: the notice back on its row place", mk._vis == false and el.y == ry)
end

-- ---------------------------------------------------------------------------
-- WIDTH: the whole row with a watch and 8 slots (Full), its buckle on the screen's middle
-- ---------------------------------------------------------------------------
local function rowWidth(scale, w, server)
    SW, SH = w, math.floor(w * 9 / 16)
    local B = boot(scale)
    env.watch = item({ name = "Watch" })
    env.server = server
    if server then ZeD.Chat = { onBelt = function() return true end, unread = function() return 0 end } end
    local slots = {}
    local types = { "SmallBeltLeft", "SmallBeltRight", "HolsterLeft", "HolsterRight", "WebbingLeft", "WebbingRight", "Back", "Shovel" }
    for i = 1, 8 do slots[i] = { slotType = types[i], name = types[i], def = { attachments = {} } } end
    env.hotbars[0].availableSlot = slots
    local _, hud = frame()
    local left, right = hud.x, hud.x + hud.width
    ZeD.Chat = nil
    return left, right, hud
end
do
    for _, c in ipairs({ { 1, 1280, "1280 at 1x" }, { 1.75, 3840, "4K at 1.75" } }) do
        local l, r, hud = rowWidth(c[1], c[2], false)
        print(string.format("WIDTH %s, single player: the row %d px wide, from x %d to %d on a %d screen (%s)", c[3], r - l, l, r, c[2], kinds(hud)))
        check("WIDTH " .. c[3] .. ": the row fits the screen", l >= 0 and r <= c[2], l .. ".." .. r)
        local l2, r2 = rowWidth(c[1], c[2], true)
        print(string.format("WIDTH %s, on a server (no speed keys, the chat key): %d px, from x %d to %d", c[3], r2 - l2, l2, r2))
        check("WIDTH " .. c[3] .. " on a server: fits", l2 >= 0 and r2 <= c[2], l2 .. ".." .. r2)
    end
    SW, SH = 1920, 1080
end

print = rawPrint
print(string.format("belt_row_drag_msgs_sim: %d checks, %d failed", checks, failed))
os.exit(failed == 0 and 0 or 1)
