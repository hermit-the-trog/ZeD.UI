-- ZeDUI/tools/qa/x_moves_sim.lua  (Nov 14 2026, punch lists 223 and 225): the controller's inventory buttons, as the
-- game's own controller inventory has them ("Match the game"), and food eaten only on a held A ("Eat on a hold").
-- With no game running, the real FocusManager.lua runs on Lua 5.1 stubs and drives an item row built by
-- InventoryRenderer.padItemButtons (cut from InventoryRenderer.lua with the controller's marks around it), the
-- move by ContainerControls.moveToOther (cut from ContainerControls.lua) and the card's header verbs
-- (ZeD_ItemCard:getActionStripElements, cut from ItemCard.lua). Buttons go down and up through Focus.qaButton.
--   XTAP    X tapped on a row moves it to the other window's container by the band's move (CT.moveItems); a stack
--           header moves its whole stack; marked rows all move and the marks go; from the World window a heavy
--           thing alone is picked up in the hands; with no container across nothing moves and X has no prompt
--   XHOLD   X held on a row is still the quick use (onHoldContext), no move
--   ATAP    A on a row whose card is open opens the game's menu (the builder's old X); A on any other row opens
--           the card as before; A on a stack header still folds or opens it
--   OTHER   X tapped on a stop that is not an item row still runs its own onContextMenu
--   FOOD    A tapped on a food row or on the card's Eat never eats; A held does (the game's eat); hold A on other
--           rows still marks; the prompts say Eat (hold)
--   WIRED   both windows' list and column builders hand their item stops to padItemButtons
-- What it can't show: the game's timed actions really running. Run from the repo root:
--   lua51 ZeDUI/tools/qa/x_moves_sim.lua
-- It prints FAIL lines and a last line "x_moves_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]x_moves_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function noop() end
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))
end
-- the text from `from` to the end of the first line-start `to` after `after` (or after `from`)
local function cut(src, from, to, after)
    local a = src and string.find(src, from, 1, true)
    if not a then return nil end
    local p = after and string.find(src, after, a, true) or a
    if not p then return nil end
    local b = string.find(src, to, p, true)
    if not b then return nil end
    return string.sub(src, a, b + #to - 1) .. "\n"
end

-- ---------------------------------------------------------------------------
-- STUBS
-- ---------------------------------------------------------------------------
local now = 100000
Events = setmetatable({}, { __index = function(t, k)
    local e = { Add = noop, Remove = noop }
    rawset(t, k, e)
    return e
end })
LuaEventManager = { AddEvent = noop }
triggerEvent = noop
require = noop
getTimestampMs = function() return now end
getSoundManager = function() return { playUISound = noop } end
isDebugEnabled = function() return false end
getJoypadData = function() return nil end
getMaxActivePlayers = function() return 4 end
getText = function(k) return k end
JoypadState = { players = {}, joypads = {}, controllers = {} }
Joypad = { AButton = 0, BButton = 1, XButton = 2, YButton = 3, LBumper = 4, RBumper = 5 }
local realPrint = print
print = function(s) if type(s) == "string" and s:sub(1, 5) == "[ZeD." then return end realPrint(s) end

local log = {}
local function logged(kind)
    local out = {}
    for _, e in ipairs(log) do if e.kind == kind then out[#out + 1] = e end end
    return out
end
local function container(kind) return { kind = kind, getType = function() return kind end } end
local MAIN, CRATE, FLOOR, BAG = container("none"), container("crate"), container("floor"), container("bag")
local PLAYER = { getPlayerNum = function() return 0 end, isAsleep = function() return false end,
                 getInventory = function() return MAIN end }
getSpecificPlayer = function() return PLAYER end
local function item(name, where, opts)
    opts = opts or {}
    return { name = name, heavy = opts.heavy, getContainer = function() return where end,
             getCategory = function() return opts.cat or "Item" end,
             getFluidContainer = function() return opts.fluid end,
             getCustomMenuOption = function() return opts.own end }
end
isForceDropHeavyItem = function(it) return it.heavy == true end
luautils = { walkToContainer = function(c) log[#log + 1] = { kind = "walk", c = c }; return true end }
ISInventoryPaneContextMenu = {
    createMenu = function(pn, mine, items) log[#log + 1] = { kind = "menu", items = items } end,
    -- (the game's eat queues ISEatFoodAction)
    eatItem = function(it) log[#log + 1] = { kind = "ISEatFoodAction", item = it } end,
    equipHeavyItem = function(p, it) log[#log + 1] = { kind = "heavy", item = it } end,
}

ZeD = { Input = {}, ActionStrip = { TOGGLE_DEFS = {} } }
ZeD.tr = function(k, a) return a ~= nil and (k .. ":" .. tostring(a)) or k end
ZeD.playerNumOf = function() return 0 end
ZeD.uiSound = noop
ZeD.InventoryRenderer = {}
ZeD.Input.Detector = { getMode = function() return "gamepad" end }
ZeD.Input.Action = { fromGamepadButton = function(b)
    if b == Joypad.AButton then return { "confirm" } end
    if b == Joypad.XButton then return { "context_menu" } end
    return nil
end }

-- the other window's container, by side (the real otherInventory reads the windows; this sim sets it)
local OTHER = { char = CRATE, world = MAIN }
local CT = {
    moveItems = function(p, items, dest) log[#log + 1] = { kind = "move", items = items, dest = dest } end,
    otherInventory = function(c) return OTHER[c._ccSide] end,
}
ZeD.ContainerControls = CT

-- ---------------------------------------------------------------------------
-- THE REAL CODE
-- ---------------------------------------------------------------------------
local CC = readFile(Z .. "ContainerControls.lua") or ""
check("WIRED: ContainerControls.lua hands out otherInventory", CC:find("CT.otherInventory = otherInventory", 1, true) ~= nil)
local moveSrc = cut(CC, "function CT.moveToOther(content, items)", "\nend")
check("WIRED: CT.moveToOther is found", moveSrc ~= nil)
if moveSrc then
    local fn, e = loadstring("local CT, isFloor = ...\nlocal otherInventory = CT.otherInventory\n" .. moveSrc, "moveToOther")
    check("CT.moveToOther compiles", fn ~= nil, e)
    if fn then fn(CT, function(inv) return inv ~= nil and inv:getType() == "floor" end) end
end

local IRS = readFile(Z .. "InventoryRenderer.lua") or ""
local irSrc = cut(IRS, "local function padSel(w, el)", "\nend", "function ZeD.InventoryRenderer.padItemButtons(el)")
check("WIRED: the pad's marks and padItemButtons are found", irSrc ~= nil)
if irSrc then
    local fn, e = loadstring(irSrc, "pad buttons")
    check("the pad's buttons compile", fn ~= nil, e)
    if fn then local ok, e2 = pcall(fn); check("the pad's buttons run", ok, e2) end
end
local IR = ZeD.InventoryRenderer

local okF, errF = pcall(dofile, Z .. "Input/FocusManager.lua")
check("FocusManager.lua loads", okF, errF)
local Focus = ZeD.Input.Focus

-- ---------------------------------------------------------------------------
-- A WINDOW WITH ONE STOP
-- ---------------------------------------------------------------------------
local function makeWin(side)
    local w = { _zedLabel = side, playerNum = 0, windowShaded = false, _playerObj = PLAYER }
    function w:isVisible() return true end
    w._mainContent = { _ccSide = side, _playerObj = PLAYER, _selectedItems = {}, _stacks = {} }
    w._focusRing = { { zone = side .. "MainInv", focusable = true, elements = {}, focusedElementIdx = 1 } }
    w._focusIdx = 1
    return w
end
-- an item stop as a builder makes it (its tap opens the card, its X opened the menu, its hold marks)
local function itemStop(it)
    local el = { id = "invrow:1", item = it, x = 0, y = 0, w = 100, h = 20 }
    el.onActivate = function(w, e) log[#log + 1] = { kind = "card", item = e.item } end
    el.onContextMenu = function(w, e) ISInventoryPaneContextMenu.createMenu(0, true, { e.item }) end
    el.onHoldActivate = function(w, e) log[#log + 1] = { kind = "mark", item = e.item } end
    el.onHoldContext = function(w, e) log[#log + 1] = { kind = "quickuse", item = e.item } end
    return IR.padItemButtons and IR.padItemButtons(el) or el
end
local function focus(w, el)
    w._focusRing[1].elements = { el }
    w._focusRing[1].focusedElementIdx = 1
    Focus.claimFocus(w)
end
local function tick(ms) now = now + (ms or 16); Focus.tick() end
local BTN = { [Joypad.AButton] = "A", [Joypad.XButton] = "X" }
local function down(w, b) Focus.qaButton(BTN[b], true); Focus.dispatchJoypadDown(w, b, { player = 0 }); tick() end
local function up(b) Focus.qaButton(BTN[b], false); tick(); Focus.qaButton(BTN[b], nil) end
local function tap(w, b) log = {}; down(w, b); up(b) end
local function hold(w, b) log = {}; down(w, b); tick(400); up(b) end

local charW, worldW = makeWin("char"), makeWin("world")

-- XTAP
local shirt = item("shirt", MAIN)
focus(charW, itemStop(shirt))
tap(charW, Joypad.XButton)
local mv = logged("move")
check("XTAP: X on a row moves it once", #mv == 1, #mv)
check("XTAP: ... to the World window's container", mv[1] and mv[1].dest == CRATE)
check("XTAP: ... that row only", mv[1] and #mv[1].items == 1 and mv[1].items[1] == shirt)
check("XTAP: ... and opens no menu", #logged("menu") == 0)
check("XTAP: the prompt says Move", IR.padPromptX(charW, charW._focusRing[1].elements[1]) == "UI_ZeD_Inv_PromptMove")

local s1, s2, s3 = item("nail1", MAIN), item("nail2", MAIN), item("nail3", MAIN)
charW._mainContent._stacks[s1] = { count = 3, items = { s1, s2, s3 }, key = "nails" }
focus(charW, itemStop(s1))
tap(charW, Joypad.XButton)
mv = logged("move")
check("XTAP: a stack header moves its whole stack (the game's grab)", mv[1] and #mv[1].items == 3, mv[1] and #mv[1].items)

local m1, m2 = item("m1", MAIN), item("m2", MAIN)
charW._mainContent._selectedItems = { [m1] = true, [m2] = true }
check("XTAP: with marks the prompt is the band's Move marked",
    IR.padPromptX(charW, {}) == "UI_ZeD_Controls_MoveMarked", IR.padPromptX(charW, {}))
focus(charW, itemStop(shirt))
tap(charW, Joypad.XButton)
mv = logged("move")
check("XTAP: with rows marked every marked row moves", mv[1] and #mv[1].items == 2, mv[1] and #mv[1].items)
check("XTAP: ... and the marks go", IR.padMarkCount(charW) == 0, IR.padMarkCount(charW))

OTHER.char = FLOOR
check("XTAP: onto the floor the prompt says Drop", IR.padPromptX(charW, {}) == "ContextMenu_Drop")
OTHER.char = nil
tap(charW, Joypad.XButton)
check("XTAP: no container across: nothing moves", #logged("move") == 0 and #logged("menu") == 0)
check("XTAP: ... and X has no prompt", IR.padPromptX(charW, {}) == false)
OTHER.char = CRATE

local crowbar = item("crowbar", CRATE)
focus(worldW, itemStop(crowbar))
tap(worldW, Joypad.XButton)
mv = logged("move")
check("XTAP: from the World window into your inventory", mv[1] and mv[1].dest == MAIN)
check("XTAP: ... walking to the crate first, as Take does", #logged("walk") == 1)
check("XTAP: the World window's prompt says Grab", IR.padPromptX(worldW, {}) == "ContextMenu_Grab")
local fridge = item("generator", CRATE, { heavy = true })
focus(worldW, itemStop(fridge))
tap(worldW, Joypad.XButton)
check("XTAP: a heavy thing alone is picked up in the hands (the game's grab)",
    #logged("heavy") == 1 and #logged("move") == 0)

-- XHOLD
focus(charW, itemStop(shirt))
hold(charW, Joypad.XButton)
check("XHOLD: X held is the quick use", #logged("quickuse") == 1)
check("XHOLD: ... and moves nothing", #logged("move") == 0 and #logged("menu") == 0)

-- ATAP
charW._drawerItem = nil
tap(charW, Joypad.AButton)
check("ATAP: A on a row whose card is shut opens the card", #logged("card") == 1 and #logged("menu") == 0)
local el = charW._focusRing[1].elements[1]
check("ATAP: ... its prompt is the default (Card)", el.promptA(charW, el) == nil)
charW._drawerItem = shirt
tap(charW, Joypad.AButton)
check("ATAP: A on the row whose card is open opens the game's menu", #logged("menu") == 1 and #logged("card") == 0)
check("ATAP: ... its prompt says Menu", el.promptA(charW, el) == "UI_ZeD_Prompt_Menu")
charW._drawerItem = s1
focus(charW, itemStop(s1))
tap(charW, Joypad.AButton)
check("ATAP: A on a stack header with its card open still folds / opens it", #logged("card") == 1 and #logged("menu") == 0)
charW._drawerItem = nil

-- OTHER
local plain = { id = "view:flip:x", x = 0, y = 0, w = 10, h = 10, onActivate = noop,
                onContextMenu = function() log[#log + 1] = { kind = "own" } end }
focus(charW, plain)
tap(charW, Joypad.XButton)
check("OTHER: X on a stop that is no item row runs its own onContextMenu", #logged("own") == 1 and #logged("move") == 0)

-- FOOD
local crayfish = item("crayfish", MAIN, { cat = "Food" })
focus(charW, itemStop(crayfish))
tap(charW, Joypad.AButton)
check("FOOD: A tapped on a food row never eats", #logged("ISEatFoodAction") == 0)
check("FOOD: ... it opens the card", #logged("card") == 1)
hold(charW, Joypad.AButton)
check("FOOD: A held on a food row eats (the game's eat)", #logged("ISEatFoodAction") == 1)
check("FOOD: ... and marks nothing", #logged("mark") == 0)
el = charW._focusRing[1].elements[1]
check("FOOD: the hold's word is the card's Eat", el.promptHold(charW, el) == "ContextMenu_Eat", el.promptHold(charW, el))
local cig = item("cigarette", MAIN, { cat = "Food", own = "Smoke" })
check("FOOD: ... or the food's own verb", IR.padPromptHold(charW, { item = cig }) == "Smoke")
local pop = item("pop", MAIN, { cat = "Food", fluid = {} })
check("FOOD: a thing with fluid in it is a drink, not food (the card's rule)", not IR.padIsFood(pop))
focus(charW, itemStop(shirt))
hold(charW, Joypad.AButton)
check("FOOD: A held on a row that is not food still marks", #logged("mark") == 1 and #logged("ISEatFoodAction") == 0)

-- FOOD on the card
local ICS = readFile(Z .. "ItemCard.lua") or ""
local cardSrc = cut(ICS, "function ZeD_ItemCard:getActionStripElements()", "\nend")
check("WIRED: the card's stops are found", cardSrc ~= nil)
if cardSrc then
    ZeD_ItemCard = {}
    local fn, e = loadstring("local VERB_DISPATCH = {}\n" .. cardSrc, "card stops")
    check("the card's stops compile", fn ~= nil, e)
    if fn then fn() end
    local card = setmetatable({ item = crayfish, playerNum = 0,
        _backBarRects = { verbs = { { x = 0, y = 0, w = 40, h = 20 }, { x = 50, y = 0, w = 40, h = 20 } } },
        _lastHeaderVerbs = { { id = "EAT", label = "Eat", primary = true }, { id = "MORE", label = "More", isMore = true } },
    }, { __index = ZeD_ItemCard })
    function card:getAbsoluteX() return 0 end
    function card:getAbsoluteY() return 0 end
    function card:_dispatchHeaderVerb(label)
        -- (the real dispatch: EAT is the game's eatItem)
        if label == "EAT" then ISInventoryPaneContextMenu.eatItem(self.item) else log[#log + 1] = { kind = "verb", label = label } end
    end
    local ok, els = pcall(card.getActionStripElements, card)
    check("the card's stops build", ok, els)
    if ok then
        local eat, more = els[1], els[2]
        check("FOOD: the card's Eat is still where the pad lands", eat and eat.isPrimary == true)
        focus(charW, eat)
        tap(charW, Joypad.AButton)
        check("FOOD: A tapped on the card's Eat never eats", #logged("ISEatFoodAction") == 0)
        hold(charW, Joypad.AButton)
        check("FOOD: A held on the card's Eat eats", #logged("ISEatFoodAction") == 1)
        check("FOOD: the card's Eat says its word for the hold prompt (Eat (hold))", eat.promptHold == "Eat")
        focus(charW, more)
        tap(charW, Joypad.AButton)
        check("FOOD: the card's other buttons still answer a tap", #logged("verb") == 1)
    end
end

-- WIRED
for _, f in ipairs({ "ZeD_CharacterWindow.lua", "ZeD_WorldWindow.lua" }) do
    local src = readFile(Z .. f) or ""
    local _, n = src:gsub("ZeD%.InventoryRenderer%.padItemButtons%(elements%[#elements%]%)", "")
    check("WIRED: " .. f .. " hands its list's and its columns' item stops to padItemButtons", n == 2, n)
end

print("x_moves_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
