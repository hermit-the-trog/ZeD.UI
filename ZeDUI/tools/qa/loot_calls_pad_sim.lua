-- ZeDUI/tools/qa/loot_calls_pad_sim.lua  (Nov 24 2026; the director's loot KISS design calls, option 1 on all seven;
-- QA's loot KISS test, ZeDUI/qa/audits/2026-11-24_kiss_loot.md, "Design calls")
-- The pad's four:
--   CALL1  ZeD_WorldWindow.padTakeAllHint (cut): on a container's rows the help line shows "Left X Take all" (the
--          left arrow and X, the word of the X prompt on that container's button); hidden off the rows, with columns
--          open, a viewed container, nothing wanted or a locked one; InventoryRenderer.padPrompts adds it after L3, R3
--   CALL2  ZeD_WorldWindow.padNextContainer (cut): RB on the rows is A on the next container's button, in the strip's
--          order (the Floor, then the list), past locked ones, round to the top; anywhere else RB turns the tabs
--          (FocusManager's bumper tap asks it first; the hold still steps tabs back)
--   CALL3  ZeD_WorldWindow.padYLand (cut): by a container the pad lands on the one he faces; the remembered row comes
--          back only at that same container; away from containers the old memory rule stands
--   CALL5  InventoryRenderer.padItemButtons (cut): A on a closed stack in the World window (not his, nothing marked)
--          is the menu (Grab one, half, all); B opens it there (a running action first); his own bags, the
--          Character window, marks and single things keep what they did
-- Run from the repo root:  lua51 ZeDUI/tools/qa/loot_calls_pad_sim.lua
-- It prints FAIL lines and a last line "loot_calls_pad_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]loot_calls_pad_sim%.lua$", "")
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

local WW = readFile(Z .. "ZeD_WorldWindow.lua") or ""
local IR = readFile(Z .. "InventoryRenderer.lua") or ""
local FM = readFile(Z .. "Input/FocusManager.lua") or ""
local PG = readFile(Z .. "ZeD_PadGlyphs.lua") or ""
check("SOURCE: files read", #WW > 0 and #IR > 0 and #FM > 0 and #PG > 0)

-- the shared stubs: one World window, its focus, the game's words
local focusZone = "worldMainInv"
local focusedWin = nil
local ww = nil
ZeD = {
    Input = { Focus = {
        getFocusedZone = function(w) return { zone = focusZone } end,
        getFocusedWindow = function(pn) return focusedWin end,
    } },
    uiSound = function() end,
    tr = function(k) return k end,
    playerNumOf = function() return 0 end,
}
getText = function(k)
    if k == "IGUI_invpage_Loot_all" then return "Loot all" end
    return k
end
ZeD_WorldWindow = { getWindow = function(pn) return ww end }

-- ---------------------------------------------------------------------------
print("-- CALL1: Left X Take all on the rows")
local src1 = (cut(WW, "function ZeD_WorldWindow.padTakeAllPrompt(w, el)", "\nend\n") or "")
    .. (cut(WW, "function ZeD_WorldWindow.padOnRows(w)", "\nend\n") or "")
    .. (cut(WW, "function ZeD_WorldWindow.padTakeAllHint(w)", "\nend\n") or "")
check("CALL1: functions found", has(src1, "padTakeAllPrompt") and has(src1, "padOnRows") and has(src1, "padTakeAllHint"))
local f1, e1 = loadstring(src1, "call1")
check("CALL1: loads", f1 ~= nil, e1)
local wanted = true
local function inv(name) return { n = name, isEmptyOrUnwanted = function() return not wanted end } end
local FLOOR, A, B, C = inv("floor"), inv("A"), inv("B"), inv("C")
local function newWin()
    return { _playerObj = {}, _activeContainer = 2,
             _containers = { { inventory = A }, { inventory = B }, { inventory = C, locked = true }, { inventory = FLOOR, isFloor = true } } }
end
if f1 then
    f1()
    local W = ZeD_WorldWindow
    ww = newWin()
    local h = W.padTakeAllHint(ww)
    check("CALL1: on the rows, a prompt", h ~= nil)
    check("CALL1: the glyph is the left arrow and X", h and h.glyph == "\226\134\144 X", h and h.glyph)
    check("CALL1: the word is the X prompt's on the button", h and h.label == "Loot all", h and h.label)
    check("CALL1: the arrow is a pad picture (DL)", has(PG, '["\\226\\134\\144"] = "DL"'))
    focusZone = "worldContainerStrip"
    check("CALL1: off the rows, none", W.padTakeAllHint(ww) == nil)
    focusZone = "worldMainInv"
    ww._mcSelected = { 1 }
    check("CALL1: columns open, none", W.padTakeAllHint(ww) == nil)
    ww._mcSelected = {}
    ww._viewedContainer = 1
    check("CALL1: another container viewed over the selection, none", W.padTakeAllHint(ww) == nil)
    ww._viewedContainer = nil
    wanted = false
    check("CALL1: nothing wanted there, none", W.padTakeAllHint(ww) == nil)
    wanted = true
    ww._activeContainer = 3
    check("CALL1: a locked container, none", W.padTakeAllHint(ww) == nil)
    ww._activeContainer = 4
    check("CALL1: the Floor's rows have it too", W.padTakeAllHint(ww) ~= nil)
end
local pp = cut(IR, "function ZeD.InventoryRenderer.padPrompts(win)", "\nend\n") or ""
local l3, hi = string.find(pp, '"L3"', 1, true), string.find(pp, "padTakeAllHint(win)", 1, true)
check("CALL1: padPrompts adds the hint after L3 and R3", l3 ~= nil and hi ~= nil and l3 < hi)

-- ---------------------------------------------------------------------------
print("-- CALL2: RB on the rows, the next container")
local src2 = (cut(WW, "local function _worldStripListOrder(win, force)", "\nend\n") or "")
    .. (cut(WW, "function ZeD_WorldWindow.padNextContainer(pn)", "\nend\n") or "")
check("CALL2: functions found", has(src2, "_worldStripListOrder") and has(src2, "padNextContainer"))
local f2, e2 = loadstring(src2, "call2")
check("CALL2: loads", f2 ~= nil, e2)
if f2 then
    f2()
    local W = ZeD_WorldWindow
    local shown = {}
    local function stripWin()
        local w = newWin()
        local els = {}
        for i = 1, #w._containers do
            els[#els + 1] = { containerIdx = i, onActivate = function(win, el)
                win._activeContainer = el.containerIdx
                shown[#shown + 1] = el.containerIdx
            end }
        end
        w._focusRing = { { zone = "worldContainerStrip", elements = els }, { zone = "worldMainInv", elements = {} } }
        return w
    end
    ww = stripWin()
    focusedWin, focusZone = ww, "worldMainInv"
    -- the strip's order: the Floor (4), then A (1), B (2), C (3, locked)
    ww._activeContainer = 4
    check("CALL2: took the press", W.padNextContainer(0) == true)
    check("CALL2: Floor -> the first in the list", ww._activeContainer == 1, ww._activeContainer)
    W.padNextContainer(0)
    check("CALL2: A -> B", ww._activeContainer == 2, ww._activeContainer)
    W.padNextContainer(0)
    check("CALL2: B -> past the locked C, round to the Floor", ww._activeContainer == 4, ww._activeContainer)
    check("CALL2: each by A on its button", #shown == 3 and shown[1] == 1 and shown[2] == 2 and shown[3] == 4)
    ww._containerSortMode = "type"   -- (a sorted list: the strip's own order, as drawn)
    ww._containers[1].name, ww._containers[2].name, ww._containers[3].name = "Zed", "Box", "Crate"
    ww._activeContainer = 4
    W.padNextContainer(0)
    check("CALL2: follows the strip's sort (Box first)", ww._activeContainer == 2, ww._activeContainer)
    ww._containerSortMode = nil
    focusZone = "worldTabBar"
    check("CALL2: off the rows, RB is the tabs'", W.padNextContainer(0) == false)
    focusZone = "worldMainInv"
    ww._mcSelected = { 1 }
    check("CALL2: columns open, RB is the tabs'", W.padNextContainer(0) == false)
    ww._mcSelected = nil
    focusedWin = {}
    check("CALL2: the Character window focused, RB is the tabs'", W.padNextContainer(0) == false)
    focusedWin = ww
    -- one open container only: the press is taken, nothing moves (the game's RB does nothing there)
    ww._containers = { { inventory = A }, { inventory = FLOOR, isFloor = true, locked = true } }
    ww._activeContainer = 1
    ww._worldListOrder = nil
    local before = #shown
    check("CALL2: nothing else to go to: taken, no move", W.padNextContainer(0) == true and #shown == before and ww._activeContainer == 1)
end
local tap = cut(FM, "if s.win and not s.bCancel and s.bLast == 0 then", "\n            end\n") or ""
check("CALL2: the bumper tap asks padNextContainer before the tabs", has(tap, 'side == "world"') and has(tap, "WW.padNextContainer(pn)")
    and has(tap, "if not took then _stepTab(side, pn, 1) end"))
check("CALL2: the hold still steps tabs back", has(FM, "_stepTab(side, pn, -1)"))

-- ---------------------------------------------------------------------------
print("-- CALL3: Y lands on the container he faces")
local src3 = (cut(WW, "function ZeD_WorldWindow._padYFaced(ww)", "\nend\n") or "")
    .. (cut(WW, "function ZeD_WorldWindow.padYLand(pn, back)", "\nend\n") or "")
check("CALL3: functions found", has(src3, "_padYFaced") and has(src3, "padYLand"))
local f3, e3 = loadstring("local buildWorldContainers, _worldWins, _switchWorldTabForNav = ...\n" .. src3, "call3")
check("CALL3: loads", f3 ~= nil, e3)
if f3 then
    local inWorld = {}   -- what buildWorldContainers finds around him now
    local wins = {}
    local claimed, soon = nil, {}
    ZeD.Input.Focus.claimFocus = function(w) claimed = w end
    ZeD.Input.Focus.focusSoon = function(w, zone, pred) soon[#soon + 1] = { w = w, zone = zone, pred = pred } end
    local CW = {}
    ZeD_CharacterWindow = { getWindow = function() return CW end }
    f3(function() return inWorld end, wins, nil)
    local W = ZeD_WorldWindow
    local facedIdx = nil
    W._pickShown = function(win, po) return facedIdx end
    W.inReach = function() return true end
    W._padYLeft = {}
    local function item(c) return { getContainer = function() return c end } end
    local function reset()
        claimed, soon = nil, {}
        local w = newWin()
        w._mainContent = {}
        w._activeTab = "loot"
        wins[0] = w
        return w
    end
    -- crates A and B in reach; he faces B; the old row was in A
    inWorld = { { inventory = A }, { inventory = B }, { inventory = FLOOR, isFloor = true } }
    facedIdx = 2
    local w = reset()
    w._activeContainer = 1
    local rowA = item(A)
    W._padYLeft[0] = { kind = "world", zone = "worldMainInv", item = rowA }
    check("CALL3: took the pad", W.padYLand(0, true) == true)
    check("CALL3: a row of another crate: the faced crate shows", w._activeContainer == 2, w._activeContainer)
    check("CALL3: ... and the pad goes to its rows, not the old row", claimed == w and soon[#soon] and soon[#soon].zone == "worldMainInv"
        and soon[#soon].pred({ item = item(B) }) == true and soon[#soon].pred({ item = rowA }) == false)
    -- the old row in B, he faces B: back to it
    w = reset()
    local rowB = item(B)
    W._padYLeft[0] = { kind = "world", zone = "worldMainInv", item = rowB }
    W.padYLand(0, true)
    check("CALL3: a row of the faced crate comes back", #soon == 1 and soon[1].pred({ item = rowB }) == true
        and soon[1].pred({ item = item(B) }) == false)
    -- the Character window's row, by a crate: the crate wins
    w = reset()
    W._padYLeft[0] = { kind = "char", zone = "charMainInv", id = "invrow:3" }
    W.padYLand(0, true)
    check("CALL3: a Character window row by a crate: the crate", claimed == w and w._activeContainer == 2)
    -- the Character window's row, no crate near: back to it (as before)
    inWorld = { { inventory = FLOOR, isFloor = true } }
    facedIdx = 1
    w = reset()
    W._padYLeft[0] = { kind = "char", zone = "charMainInv", id = "invrow:3" }
    check("CALL3: no crate near: the Character window's row", W.padYLand(0, true) == true and claimed == CW
        and soon[1] and soon[1].zone == "charMainInv")
    -- no crate near, no memory: not the World window's
    w = reset()
    check("CALL3: no crate near, nothing kept: the caller's landing", W.padYLand(0, false) == false)
    -- a faced crate the window has not listed yet: the refresh's turn rule shows it
    inWorld = { { inventory = A }, { inventory = B }, { inventory = C }, { inventory = FLOOR, isFloor = true } }
    facedIdx = 3
    w = reset()
    w._containers = { { inventory = A }, { inventory = FLOOR, isFloor = true } }
    w._activeContainer, w._lookDir = 1, "N"
    W.padYLand(0, false)
    check("CALL3: a crate not listed yet: the turn rule runs", w._lookDir == nil and w._containerTimer == 30)
    -- columns open: his layout stands
    facedIdx = 2
    w = reset()
    w._mcSelected = { 1 }
    w._activeContainer = 1
    W.padYLand(0, false)
    check("CALL3: columns open: the shown container stays", w._activeContainer == 1)
end

-- ---------------------------------------------------------------------------
print("-- CALL5: A on a closed stack is the menu")
local src5 = (cut(IR, "local function padSel(w, el)", "\nend\n") or "")
    .. (cut(IR, "local function padStackItems(cnt, cs, item)", "\nend\n") or "")
    .. (cut(IR, "local function padIsStack(w, el)", "\nend\n") or "")
    .. (cut(IR, "function ZeD.InventoryRenderer.padStackMenu(w, el)", "\nend\n") or "")
    .. (cut(IR, "function ZeD.InventoryRenderer.padStackOpens(w, el)", "\nend\n") or "")
    .. (cut(IR, "function ZeD.InventoryRenderer.padItemButtons(el)", "\nend\n") or "")
check("CALL5: functions found", has(src5, "padStackMenu") and has(src5, "padStackOpens") and has(src5, "padItemButtons"))
local f5, e5 = loadstring("local containerKey = ...\n" .. src5, "call5")
check("CALL5: loads", f5 ~= nil, e5)
if f5 then
    local marks, own, grid, acting = 0, false, false, false
    local R = {
        padCardOpen = function() return false end,
        padMarkCount = function() return marks end,
        padOwnBags = function() return own end,
        isGridKey = function() return grid end,
        padMove = function() end, padPromptX = function() end, padPromptHold = function() end,
    }
    ZeD.InventoryRenderer = R
    ZeD.GridLayout = { padButtons = function() end }
    ZeD.Input.Focus.actionToCancel = function() return acting end
    getSpecificPlayer = function() return {} end
    f5(function(i) return "key" end)
    local CRATE = { n = "crate" }
    local rep, other, lone = { getContainer = function() return CRATE end }, {}, { getContainer = function() return CRATE end }
    local stack = { count = 2, items = { rep, other } }
    local world = { _mainContent = { _stacks = { [rep] = stack } } }
    ww = world
    local log = {}
    local function mkEl(it, withCancel)
        local el = { item = it,
            onActivate = function() log[#log + 1] = "tap" end,
            onContextMenu = function() log[#log + 1] = "menu" end,
            onHoldActivate = function() end }
        if withCancel then
            el.onCancel = function() log[#log + 1] = "cancel"; return marks > 0 end
            el.promptB = function() if marks > 0 then return "Clear" end return false end
        end
        return R.padItemButtons(el)
    end
    local el = mkEl(rep, true)
    log = {}
    el.onActivate(world, el)
    check("CALL5: A on a closed stack, the menu", log[1] == "menu", log[1])
    check("CALL5: A's word is Menu", el.promptA(world, el) == "UI_ZeD_Prompt_Menu")
    log = {}
    check("CALL5: B opens it", el.onCancel(world, el) == true and log[1] == "tap", log[1])
    check("CALL5: B's word is Open", el.promptB(world, el) == "IGUI_Open")
    acting = true
    log = {}
    check("CALL5: an action running: B is the game's cancel", el.onCancel(world, el) == false and log[1] == nil)
    check("CALL5: ... and its word is not Open", el.promptB(world, el) == false)
    acting = false
    grid = true
    log = {}
    el.onActivate(world, el)
    check("CALL5: in a grid A is the menu too", log[1] == "menu")
    check("CALL5: in a grid B has no Open", el.onCancel(world, el) == false and el.promptB(world, el) == false)
    grid = false
    own = true
    log = {}
    el.onActivate(world, el)
    check("CALL5: his own bags: A opens the stack, as before", log[1] == "tap")
    check("CALL5: his own bags: A's word as before", el.promptA(world, el) == nil)
    own = false
    marks = 1
    log = {}
    el.onActivate(world, el)
    check("CALL5: marks: A as before", log[1] == "tap")
    log = {}
    el.onCancel(world, el)
    check("CALL5: marks: B clears them", log[1] == "cancel" and el.promptB(world, el) == "Clear")
    marks = 0
    local charWin = { _mainContent = world._mainContent }
    log = {}
    el.onActivate(charWin, el)
    check("CALL5: the Character window: A as before", log[1] == "tap")
    local single = mkEl(lone, true)
    log = {}
    single.onActivate(world, single)
    check("CALL5: a single thing: A as before (the card)", log[1] == "tap")
    check("CALL5: a single thing: no B word without marks", single.promptB(world, single) == false)
    local bare = mkEl(rep, false)
    grid = true
    check("CALL5: a row that had no B still has none", bare.promptB(world, bare) == false and bare.onCancel(world, bare) == false)
    grid = false
end
check("CALL5: the game's Grab one / half / all come from the menu's grab wrap", has(readFile(Z .. "ContainerControls.lua"), 'context:addOption(getText("ContextMenu_Grab_half")'))

print("loot_calls_pad_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
