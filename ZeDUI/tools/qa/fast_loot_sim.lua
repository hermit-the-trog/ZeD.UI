-- ZeDUI/tools/qa/fast_loot_sim.lua  (Nov 10 2026, Build; punch list 146, fast looting)
-- The director, Nov 10 2026, after a vanilla player on a stream: "for looting stats need to show quick, without a
-- click". Rulings: the game's own item tooltip, ZeD-styled, at once on hover; a box dragged from empty space selects
-- the rows it crosses. With no game running, the real ZeD_InvTip.lua and ZeD_BoxSelect.lua run on stubs. It checks:
--   TIP     a row asking for its tooltip while it draws gets it the next frame (the game's ISToolTipInv, following
--           the pointer); the next row's item swaps into the same tooltip; no ask and it goes; it stays away while
--           items are dragged (ZeD's drag or the game's), while a box is drawn, while a right-click menu is open,
--           while that same item's card is open, while the list is hidden; wantedBy says who asked this frame
--   BOX     a press on empty space and a drag past 4 units selects every item row the box crosses (and no category
--           or button zone); a press without a drag changes nothing; Ctrl at the press adds to the selection; in a
--           multi-container view the box keeps to its column; finish hands back the last row and the column
--   WIRED   the inventory's rows and grid cells ask for the tooltip, the grid's own name hint gives way to it, and
--           both windows start, move, finish and draw the box
-- What it can't show: the tooltip and the box on screen, a real drag. Run from the repo root:
--   lua51 ZeDUI/tools/qa/fast_loot_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]fast_loot_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local CDIR = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end

-- ---------------------------------------------------------------------------
-- STUBS
-- ---------------------------------------------------------------------------
local hooks = {}
Events = { OnPreUIDraw = { Add = function(fn) hooks[#hooks + 1] = fn end } }
local function frame() for _, fn in ipairs(hooks) do fn() end end
local made = 0
ISToolTipInv = {}
ISToolTipInv.__index = ISToolTipInv
function ISToolTipInv:new(item)
    made = made + 1
    -- (as the game's: a new one already reports itself visible, though it is in no UI list yet; QA's Mac run)
    return setmetatable({ item = item, visible = true, inUI = false, followMouse = false }, ISToolTipInv)
end
function ISToolTipInv:initialise() end
function ISToolTipInv:setItem(i) self.item = i end
function ISToolTipInv:setOwner(o) self.owner = o end
function ISToolTipInv:setCharacter(c) self.chr = c end
function ISToolTipInv:isVisible() return self.visible end
function ISToolTipInv:setVisible(v) self.visible = v end
function ISToolTipInv:addToUIManager() self.inUI = true end
function ISToolTipInv:removeFromUIManager() self.inUI = false end
function ISToolTipInv:bringToTop() end
local CTX = { open = false }
getPlayerContextMenu = function() return { isAnyVisible = function() return CTX.open end } end
local PLAYER = { getPlayerNum = function() return 0 end }
getSpecificPlayer = function() return PLAYER end
local CTRL = false
isCtrlKeyDown = function() return CTRL end
isShiftKeyDown = function() return false end
ISMouseDrag = {}
local WIN = { _playerObj = PLAYER }
ZeD = { T = { px = function(v) return v end, accent = { r = 1, g = 0, b = 0 } },
        Atoms = { windowOf = function() return WIN end } }

local function load(name)
    local f, err = loadfile(CDIR .. name)
    if not f then print("fast_loot_sim: " .. tostring(err)); os.exit(1) end
    f()
end
load("ZeD_InvTip.lua")
load("ZeD_BoxSelect.lua")
local IT, BS = ZeD.InvTip, ZeD.BoxSelect

-- ---------------------------------------------------------------------------
-- TIP
-- ---------------------------------------------------------------------------
local list = { visible = true, isReallyVisible = function(s) return s.visible end }
local axe, knife = { name = "Axe" }, { name = "Knife" }
frame()
IT.want(list, axe)
check("TIP: wantedBy the row that asked, this frame", IT.wantedBy(list, axe) and not IT.wantedBy(list, knife))
frame()
local tip = IT._tip
check("TIP: the next frame shows the game's tooltip, on screen the first time too", tip and tip.visible and tip.inUI and tip.item == axe)
check("TIP: following the pointer", tip and tip.followMouse == true and tip.anchorBottomLeft == nil)
check("TIP: for the window's character", tip and tip.chr == PLAYER and tip.owner == list)
IT.want(list, knife); frame()
check("TIP: the next row's item swaps into the same tooltip", IT._tip == tip and tip.item == knife and made == 1, made)
frame()
check("TIP: no ask, it goes", not tip.visible and not tip.inUI)
local function shownWith(setup, undo)
    setup(); IT.want(list, axe); frame(); local v = tip.visible; undo(); frame(); return v
end
check("TIP: not while ZeD drags items", not shownWith(function() list._drag = { isActive = function() return true end } end, function() list._drag = nil end))
check("TIP: not while the game drags items", not shownWith(function() ISMouseDrag.dragging = { axe } end, function() ISMouseDrag.dragging = nil end))
check("TIP: an empty drag list is no drag", shownWith(function() ISMouseDrag.dragging = {} end, function() ISMouseDrag.dragging = nil end))
check("TIP: not while a box is drawn", not shownWith(function() list._box = { live = true } end, function() list._box = nil end))
check("TIP: not while a right-click menu is open", not shownWith(function() CTX.open = true end, function() CTX.open = false end))
check("TIP: not while that item's card is open", not shownWith(function() WIN._drawerItem = axe end, function() WIN._drawerItem = nil end))
check("TIP: another item's card open, it shows", shownWith(function() WIN._drawerItem = knife end, function() WIN._drawerItem = nil end))
check("TIP: not while the list is hidden", not shownWith(function() list.visible = false end, function() list.visible = true end))

-- ---------------------------------------------------------------------------
-- BOX
-- ---------------------------------------------------------------------------
local items = {}
for i = 1, 6 do items[i] = { name = "item" .. i } end
local function content()
    local c = { _hitZones = {}, setCapture = function() end }
    c._hitZones[1] = { id = "cat:Food", x = 0, y = 0, w = 200, h = 16 }
    for i = 1, 6 do c._hitZones[#c._hitZones + 1] = { id = items[i], x = 0, y = 16 + (i - 1) * 16, w = 200, h = 16 } end
    c._hitZones[#c._hitZones + 1] = { id = "xfer:2", x = 150, y = 200, w = 40, h = 16 }
    return c
end
local function count(sel) local n = 0; for _ in pairs(sel) do n = n + 1 end; return n end
do
    local c, sel = content(), {}
    BS.start(c, 210, 40, sel)
    BS.move(c, 208, 42)
    check("BOX: under the threshold no box", not BS.active(c) and count(sel) == 0)
    local last0 = BS.finish(c)
    check("BOX: a press without a drag changes nothing", last0 == false and count(sel) == 0)
    sel[items[6]] = true
    BS.start(c, 210, 40, sel)
    BS.move(c, 100, 70)
    check("BOX: past 4 units the box is open", BS.active(c))
    check("BOX: the rows it crosses, selected (rows 2 to 4)", sel[items[2]] and sel[items[3]] and sel[items[4]] and count(sel) == 3, count(sel))
    check("BOX: a plain box replaces what was selected", not sel[items[6]])
    BS.move(c, 100, 2)
    check("BOX: drawn back up, the category zone is no row", sel[items[1]] and sel[items[2]] and not sel["cat:Food"] and count(sel) == 2, count(sel))
    local last, col = BS.finish(c)
    check("BOX: finish hands back the last row it took", last == items[2] and col == nil, tostring(last and last.name))
    check("BOX: and the box is gone", c._box == nil)
    -- Ctrl adds
    CTRL = true
    BS.start(c, 210, 100, sel)
    CTRL = false
    BS.move(c, 100, 120)
    check("BOX: Ctrl at the press adds to the selection", sel[items[1]] and sel[items[2]] and sel[items[6]] and count(sel) >= 3, count(sel))
    BS.finish(c)
    -- the XFER button is no row
    local s2 = {}
    BS.start(c, 210, 190, s2); BS.move(c, 140, 230); BS.finish(c)
    check("BOX: a button zone is not selected", count(s2) == 0, count(s2))
    -- columns: the box keeps to the one it starts in
    local c2 = content()
    for i = 1, 3 do c2._hitZones[#c2._hitZones + 1] = { id = { name = "right" .. i }, x = 300, y = 16 + (i - 1) * 16, w = 200, h = 16 } end
    local colAt = function(x) return x < 250 and 1 or 2 end
    local s3 = {}
    BS.start(c2, 10, 40, s3, colAt); BS.move(c2, 480, 60)
    local right = 0
    for k in pairs(s3) do if k.name and k.name:find("^right") then right = right + 1 end end
    check("BOX: in a multi-container view it keeps to its column", right == 0 and count(s3) > 0, right)
    local _, col2 = BS.finish(c2)
    check("BOX: finish says which column", col2 == 1, col2)
    -- the draw: a wash and an outline
    local c3 = content()
    local draws = 0
    c3.drawRect = function() draws = draws + 1 end
    c3.drawRectBorder = function() draws = draws + 1 end
    BS.draw(c3)
    check("BOX: nothing drawn with no box", draws == 0)
    BS.start(c3, 210, 40, {}); BS.move(c3, 100, 90); BS.draw(c3)
    check("BOX: the open box draws its wash and outline", draws == 2, draws)
end

-- ---------------------------------------------------------------------------
-- WIRED
-- ---------------------------------------------------------------------------
local function read(name) local f = io.open(CDIR .. name, "rb"); local s = f:read("*a"); f:close(); return s end
local ir = read("InventoryRenderer.lua")
local _, wants = ir:gsub("ZeD%.InvTip%.want%(self, item%)", "")
check("WIRED: list rows and grid cells ask for the tooltip", wants == 2, wants)
check("WIRED: the grid's name hint gives way to it", ir:find("ZeD.InvTip.wantedBy(self, hc.key)", 1, true) ~= nil)
for _, w in ipairs({ "ZeD_CharacterWindow.lua", "ZeD_WorldWindow.lua" }) do
    local s = read(w)
    check("WIRED: " .. w .. " starts the box on empty space", s:find("ZeD.BoxSelect.start(self, x, y, bSel", 1, true) ~= nil)
    local _, moves = s:gsub("ZeD%.BoxSelect%.move%(self, self:getMouseX%(%), self:getMouseY%(%)%)", "")
    check("WIRED: " .. w .. " moves it inside and outside", moves == 2, moves)
    local _, ends = s:gsub("ZeD%.BoxSelect%.finish%(self%)", "")
    check("WIRED: " .. w .. " finishes it on either release", ends == 2, ends)
    check("WIRED: " .. w .. " draws it after the rows", s:find("content._onRender = function(self) if self._box and ZeD.BoxSelect then ZeD.BoxSelect.draw(self) end end", 1, true) ~= nil)
end

print("fast_loot_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
