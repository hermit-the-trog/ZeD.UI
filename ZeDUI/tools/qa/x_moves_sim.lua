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
--   DRINK   (punch list 228q) the same for a drink: A tapped on a water bottle's row or on the card's Drink never
--           drinks; A held does (the game's drink); the card's Use (the game's double-click: pills) is a hold too
--   USE     (punch list 228q follow-up, "Yes, hold uses it") hold A on a row whose card's main verb is Use (pills,
--           smokes: a drainable) uses it, the game's double-click; a tap never does; marking it is a painted run
--   FLOOR   (punch list 227, "Show it") a thing on the floor shows Grab, its main action, More, as in a crate; the
--           action runs the game's own handler on the floor item (it brings the item over itself); food still holds
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
             isSealed = function() return opts.sealed == true end,
             getCustomMenuOption = function() return opts.own end }
end
isForceDropHeavyItem = function(it) return it.heavy == true end
luautils = { walkToContainer = function(c) log[#log + 1] = { kind = "walk", c = c }; return true end }
ISInventoryPaneContextMenu = {
    createMenu = function(pn, mine, items) log[#log + 1] = { kind = "menu", items = items } end,
    -- (the game's eat queues ISEatFoodAction)
    eatItem = function(it) log[#log + 1] = { kind = "ISEatFoodAction", item = it } end,
    -- (the game's drink queues ISDrinkFluidAction)
    onDrinkFluid = function(it) log[#log + 1] = { kind = "ISDrinkFluidAction", item = it } end,
    equipHeavyItem = function(p, it) log[#log + 1] = { kind = "heavy", item = it } end,
}

ZeD = { Input = {}, ActionStrip = { TOGGLE_DEFS = {} } }
ZeD.tr = function(k, a) return a ~= nil and (k .. ":" .. tostring(a)) or k end
ZeD.playerNumOf = function() return 0 end
ZeD.uiSound = noop
ZeD.InventoryRenderer = {}
ZeD.Input.Detector = { getMode = function() return "gamepad" end }
-- (QA K1-2) the card's one Drink / Eat rule (ZeD.ItemCard.canDrink, tooFull, eatOff), cut from ItemCardOrganism.lua,
-- which the card and the held A both ask
FluidCategory = { Beverage = "Beverage" }
MoodleType = { FOOD_EATEN = "FOOD_EATEN" }
ZeD.ItemCard = {}
do
    local O = readFile(Z .. "ItemCardOrganism.lua") or ""
    local parts = {
        cut(O, "local function safeGet(item, m, ...)", "\nend"),
        cut(O, "function ZeD.ItemCard.canDrink(item, playerObj)", "\nend"),
        cut(O, "function ZeD.ItemCard.tooFull(playerObj)", "\nend"),
        cut(O, "function ZeD.ItemCard.eatOff(item, playerObj)", "\nend"),
        cut(O, "function ZeD.ItemCard.drainableUse(item)", "\nend"),   -- (QA K2 review)
    }
    local src = ""
    for i = 1, 5 do
        check("WIRED: the card's drink and eat rule piece " .. i .. " is found", parts[i] ~= nil)
        src = src .. (parts[i] or "")
    end
    local fn, e = loadstring(src, "drink rule")
    check("the card's drink and eat rule compiles", fn ~= nil, e)
    if fn then fn() end
end
-- a fluid for the stubs: its categories, the game's tainted test, the container's size
local function fluidOf(cats, opts)
    opts = opts or {}
    local fl = { isCategory = function(_, c) return cats[c] == true end }
    return { isEmpty = function() return opts.empty == true end, getPrimaryFluid = function() return fl end,
             isTaintedStatusKnown = function() return opts.tainted == true end,
             getCapacity = function() return opts.cap or 1 end,
             getProperties = function() return { getHungerChange = function() return opts.hunger or 0 end } end }
end
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
local moveSrc = cut(CC, "function CT.moveToOther(content, items)", "\nend", "function CT.grabItems(")
check("WIRED: CT.moveToOther and CT.grabItems are found", moveSrc ~= nil)
if moveSrc then
    local fn, e = loadstring("local CT, isFloor = ...\nlocal otherInventory = CT.otherInventory\n" .. moveSrc, "moveToOther")
    check("CT.moveToOther compiles", fn ~= nil, e)
    if fn then fn(CT, function(inv) return inv ~= nil and inv:getType() == "floor" end) end
end
-- (loot KISS call 6, Nov 24 2026: moveToOther asks CT.noRoom first; here every bag has room. The No room case is
-- loot_calls_noroom_sim.lua's.)
CT.noRoom = function() return false end

local IRS = readFile(Z .. "InventoryRenderer.lua") or ""
-- (Nov 15 2026, add-on hooks: padItemButtons hands each stop to GridLayout.padButtons; the real file, no add-on)
check("GridLayout.lua loads", (pcall(dofile, Z .. "GridLayout.lua")))
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

-- DRINK (punch list 228q)
local WATER = fluidOf({ Beverage = true })
local bottle = item("water bottle", MAIN, { fluid = WATER })
check("DRINK: a bottle with water in it is a drink", IR.padIsDrink(bottle) == true)
check("DRINK: ... an empty one is not", not IR.padIsDrink(item("empty", MAIN, { fluid = fluidOf({ Beverage = true }, { empty = true }) })))
-- (QA K1-2: only where the game offers Drink)
check("DRINK: ... nor bleach (no beverage: its Drink stays in the right-click menu)", not IR.padIsDrink(item("bleach", MAIN, { fluid = fluidOf({ Poison = true }, { tainted = true }) })))
check("DRINK: ... nor gasoline or rubbing alcohol (no beverage)", not IR.padIsDrink(item("gas can", MAIN, { fluid = fluidOf({ Fuel = true }, { cap = 10 }) })))
check("DRINK: ... nor water known to be tainted", not IR.padIsDrink(item("tainted", MAIN, { fluid = fluidOf({ Beverage = true }, { tainted = true }) })))
check("DRINK: ... nor a beverage in a container over 3 L", not IR.padIsDrink(item("big pot", MAIN, { fluid = fluidOf({ Beverage = true }, { cap = 5 }) })))
check("DRINK: ... nor a sealed one (the card has no Drink for it)", not IR.padIsDrink(item("sealed", MAIN, { fluid = WATER, sealed = true })))
focus(charW, itemStop(bottle))
tap(charW, Joypad.AButton)
check("DRINK: A tapped on a water bottle's row never drinks", #logged("ISDrinkFluidAction") == 0)
check("DRINK: ... it opens the card", #logged("card") == 1)
hold(charW, Joypad.AButton)
check("DRINK: A held on a water bottle's row drinks (the game's drink)", #logged("ISDrinkFluidAction") == 1)
check("DRINK: ... and marks nothing", #logged("mark") == 0)
el = charW._focusRing[1].elements[1]
check("DRINK: the hold's word is the card's Drink", el.promptHold(charW, el) == "ContextMenu_Drink", el.promptHold(charW, el))

-- FOOD on the card, and the card's header verbs (punch list 227)
-- the card's model: VERB_KEYS, safeGet, categoryOf, headerVerbsForContext and compactVerbs, cut from ItemCardOrganism.lua
instanceof = function(o, cls) return false end
ZeD.T = { px = function(n) return n end, buttonH = 24, fontF3 = "F3" }
-- (7 units a letter; a game key measures as its English word, the part after the last "_")
ZeD.TM = { MeasureStringX = function(self, f, s) return #(s:match("_([^_]+)$") or s) * 7 end }
ZeD.btnCase = function(s) return s end
local ORG = readFile(Z .. "ItemCardOrganism.lua") or ""
local orgParts = {
    cut(ORG, "ZeD.ItemCard.VERB_KEYS = {", "\nend", "function ZeD.ItemCard.verbText"),
    cut(ORG, "local function safeGet(item, m, ...)", "\nend"),
    cut(ORG, "local function categoryOf(item)", "\nend"),
    cut(ORG, "local function headerVerbsForContext(ctx, item, playerObj)", "\nend"),
    cut(ORG, "local function compactVerbs(verbs, w)", "\nend"),
}
local orgSrc = ""
for i = 1, 5 do
    check("WIRED: the card's verb model piece " .. i .. " is found", orgParts[i] ~= nil)
    orgSrc = orgSrc .. (orgParts[i] or "")
end
ZeD.ItemCard = ZeD.ItemCard or {}   -- (keeps the drink and eat rule loaded above)
local VERBS
do
    local fn, e = loadstring(orgSrc .. "\nreturn headerVerbsForContext, compactVerbs, categoryOf\n", "card verbs")
    check("the card's verb model compiles", fn ~= nil, e)
    if fn then
        local hv, cv, cat = fn()
        ZeD.ItemCard.categoryOf = cat
        VERBS = function(ctx, it, w)
            local v = hv(ctx, it)
            if w and #v > 1 then v = cv(v, w) end
            local ids = {}
            for i, x in ipairs(v) do ids[i] = x.id end
            return table.concat(ids, ","), v
        end
    end
end
if VERBS then
    local ids, v = VERBS("container", crayfish)
    check("CARD: food in the world's container: Grab, Eat, More", ids == "TAKE,EAT,MORE", ids)
    check("CARD: ... Grab reads the game's word", v[1].label == "ContextMenu_Grab", v[1].label)
    check("CARD: ... and the pad lands on Eat, not Grab", v[2].primary == true and not v[1].primary)
    ids = VERBS("container", crayfish, 220)
    check("CARD: the narrow card keeps Grab, Eat, More where they fit", ids == "TAKE,EAT,MORE", ids)
    ids = VERBS("container", crayfish, 120)
    -- (loot KISS call 4, the director, Nov 24 2026: Grab stays; the main verb goes into More instead)
    check("CARD: ... and keeps Grab, More where they don't (Eat goes into More)", ids == "TAKE,MORE", ids)
    ids = VERBS("inventory", crayfish)
    check("CARD: food in your inventory: Eat, Drop, More (two verbs kept)", ids == "EAT,DROP,MORE", ids)
    ids = VERBS("inventory", crayfish, 220)
    check("CARD: ... the narrow card: Eat, More", ids == "EAT,MORE", ids)
    ids = VERBS("container", item("nail", CRATE))
    check("CARD: a thing with no verb of its own in a crate: Grab, More", ids == "TAKE,MORE", ids)
    -- FLOOR (punch list 227, the design lead's "Show it")
    ids, v = VERBS("ground", crayfish)
    check("FLOOR: food on the floor: Grab, Eat, More", ids == "TAKE,EAT,MORE", ids)
    check("FLOOR: ... the pad lands on Eat, not Grab", v[2].primary == true and not v[1].primary)
    ids = VERBS("ground", item("nail", FLOOR))
    check("FLOOR: a thing with no verb of its own on the floor: Grab, More", ids == "TAKE,MORE", ids)
    ids, v = VERBS("ground", item("book", FLOOR, { cat = "Literature" }))
    check("FLOOR: a book on the floor: Grab, Read, More", ids == "TAKE,READ,MORE", ids)
    ids = VERBS("container", bottle)
    check("DRINK: a bottle in a crate: Grab, Drink, More", ids == "TAKE,DRINK,MORE", ids)
    -- (QA K1-2) the card's one bright button never drinks bleach or a gas can
    ids = VERBS("inventory", item("bleach", MAIN, { fluid = fluidOf({ Poison = true }, { tainted = true }) }))
    check("DRINK: bleach's card has no Drink (the right-click menu keeps it)", not ids:find("DRINK", 1, true), ids)
    ids = VERBS("inventory", item("gas can", MAIN, { fluid = fluidOf({ Fuel = true }, { cap = 10 }) }))
    check("DRINK: a gas can's card has no Drink", not ids:find("DRINK", 1, true), ids)
end

-- USE (punch list 228q follow-up)
do
    ISInventoryPane = { doContextualDblClick = function(stub, it) log[#log + 1] = { kind = "dblclick", item = it, pn = stub.player } end }
    local oldInst = instanceof
    instanceof = function(o, cls) return cls == "DrainableComboItem" and type(o) == "table" and o.drainable == true end
    local pills = item("pills", MAIN)
    pills.drainable = true
    -- (QA K2-7) the card's Use is only for the game's consumables (pills, smokes); wipes and thread get none
    local oldTag = ItemTag
    ItemTag = { CONSUMABLE = "consumable", SHOW_POISON = "showpoison" }
    pills.hasTag = function(_, t) return t == "consumable" end
    local wipes = item("wipes", MAIN)
    wipes.drainable = true
    wipes.hasTag = function() return false end
    check("USE: pills (a drainable: the card's main verb is Use) are a use", IR.padIsUse(pills) == true)
    check("USE: ... a shirt is not", not IR.padIsUse(shirt))
    if VERBS then check("USE: ... and the card's own main verb for them is Use", VERBS("inventory", pills) == "USE,DROP,MORE", VERBS("inventory", pills)) end
    if VERBS then check("USE: ... wipes and thread have no Use on the card (K2-7)", VERBS("inventory", wipes) == "DROP,MORE", VERBS("inventory", wipes)) end
    focus(charW, itemStop(pills))
    tap(charW, Joypad.AButton)
    check("USE: A tapped on a pills row never takes one", #logged("dblclick") == 0)
    check("USE: ... it opens the card", #logged("card") == 1)
    hold(charW, Joypad.AButton)
    local dc = logged("dblclick")
    check("USE: A held on it uses it (the game's double-click, the player's own)", #dc == 1 and dc[1].item == pills and dc[1].pn == 0)
    check("USE: ... and marks nothing", #logged("mark") == 0)
    el = charW._focusRing[1].elements[1]
    -- (KISS #29: pills read the game's Take Pills; the stub getText returns the key)
    check("USE: the hold's word is the card's Take Pills", el.promptHold(charW, el) == "ContextMenu_Take_pills", el.promptHold(charW, el))
    -- marking it: a painted run started on another row
    charW._mainContent._selectedItems = {}
    IR.padMark(charW, { item = shirt })
    IR.padPaint(charW, { item = pills }, charW._gpPaint)
    check("USE: a painted run started on another row still marks it", charW._mainContent._selectedItems[pills] == true)
    charW._mainContent._selectedItems = {}
    charW._gpPaint = nil
    instanceof = oldInst
    ItemTag = oldTag
end

local ICS = readFile(Z .. "ItemCard.lua") or ""
local cardSrc = cut(ICS, "function ZeD_ItemCard:getActionStripElements()", "\nend")
local dispSrc = cut(ICS, "function ZeD_ItemCard:_dispatchHeaderVerb(label)", "\nend")
local markSrc = cut(ICS, "function ZeD_ItemCard:_markedWith(item)", "\nend")
local ctxSrc = cut(ICS, "function ZeD_ItemCard:_effectiveContext()", "\nend")
check("WIRED: the card's stops, dispatch, marks and context are found", cardSrc and dispSrc and markSrc and ctxSrc)
if cardSrc and dispSrc and markSrc and ctxSrc then
    ZeD_ItemCard = {}
    local holdLine = ICS:match("(local HOLD_VERBS = [^\n]*\n)")
    check("WIRED: the card's hold verbs are found", holdLine ~= nil)
    local fn, e = loadstring("local VERB_DISPATCH = {}\n" .. (holdLine or "") .. cardSrc .. dispSrc .. markSrc .. ctxSrc, "card stops")
    check("the card's stops compile", fn ~= nil, e)
    if fn then fn() end
    getMouseX = function() return 0 end
    getMouseY = function() return 0 end
    MAIN.containsRecursive = function(self, it) return it.carried or it:getContainer() == self end
    ZeD_CharacterWindow = { getWindow = function() return charW end }
    ZeD_WorldWindow = { getWindow = function() return worldW end }
    local function makeCard(it, verbs)
        local c = setmetatable({ item = it, playerNum = 0,
            _backBarRects = { verbs = {} }, _lastHeaderVerbs = verbs }, { __index = ZeD_ItemCard })
        for i = 1, #verbs do c._backBarRects.verbs[i] = { x = 50 * i, y = 0, w = 40, h = 20 } end
        function c:getAbsoluteX() return 0 end
        function c:getAbsoluteY() return 0 end
        return c
    end
    local card = makeCard(crayfish, { { id = "EAT", label = "Eat", primary = true }, { id = "MORE", label = "More", isMore = true } })
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
        local menus = logged("menu")
        check("CARD: More (a tap) opens the item's menu", #menus == 1 and menus[1].items[1] == crayfish and #menus[1].items == 1)
        charW._mainContent._selectedItems = { [crayfish] = true, [shirt] = true }
        tap(charW, Joypad.AButton)
        menus = logged("menu")
        check("CARD: with rows marked and the card up for one, More's menu takes every marked row",
            #menus == 1 and #menus[1].items == 2, menus[1] and #menus[1].items)
        charW._mainContent._selectedItems = {}
    end
    local box = item("crayfish2", CRATE, { cat = "Food" })
    card = makeCard(box, { { id = "TAKE", label = "ContextMenu_Grab" }, { id = "EAT", label = "Eat", primary = true },
        { id = "MORE", label = "More", isMore = true } })
    ok, els = pcall(card.getActionStripElements, card)
    if ok then
        focus(worldW, els[1])
        tap(worldW, Joypad.AButton)
        local mv = logged("move")
        check("CARD: Grab (a tap) is X's move: into your inventory", mv[1] and mv[1].dest == MAIN and mv[1].items[1] == box)
        check("CARD: ... walking to the crate first", #logged("walk") == 1)
        check("CARD: ... and the Eat beside it still wants A held", els[2].onActivate == nil and els[2].onHoldActivate ~= nil)
    end
    card = makeCard(box, {})
    check("CARD: a thing in the world's crate is the container context (Grab shows)", card:_effectiveContext() == "container")
    -- DRINK on the card
    local wcard = makeCard(bottle, { { id = "DRINK", label = "ContextMenu_Drink", primary = true },
        { id = "USE", label = "Use" }, { id = "MORE", label = "More", isMore = true } })
    local okD, dels = pcall(wcard.getActionStripElements, wcard)
    check("DRINK: the card's stops build", okD, dels)
    if okD then
        check("DRINK: the card's Drink is still where the pad lands", dels[1].isPrimary == true)
        focus(charW, dels[1])
        tap(charW, Joypad.AButton)
        check("DRINK: A tapped on the card's Drink never drinks (A, A on a bottle)", #logged("ISDrinkFluidAction") == 0)
        hold(charW, Joypad.AButton)
        check("DRINK: A held on the card's Drink drinks", #logged("ISDrinkFluidAction") == 1)
        check("DRINK: the card's Drink says its word for the hold prompt", dels[1].promptHold == "ContextMenu_Drink")
        check("DRINK: the card's Use (the game's double-click: pills, smokes) is a hold too",
            dels[2].onActivate == nil and dels[2].onHoldActivate ~= nil)
    end
    -- FLOOR on the card: the floor container's thing, Grab then Eat (a hold) then More
    local onFloor = item("crayfish3", FLOOR, { cat = "Food" })
    card = makeCard(onFloor, {})
    check("FLOOR: a thing in the floor container is the ground context", card:_effectiveContext() == "ground")
    card = makeCard(onFloor, { { id = "TAKE", label = "ContextMenu_Grab" }, { id = "EAT", label = "Eat", primary = true },
        { id = "MORE", label = "More", isMore = true } })
    local okG, gels = pcall(card.getActionStripElements, card)
    check("FLOOR: the card's stops build", okG, gels)
    if okG then
        focus(worldW, gels[2])
        tap(worldW, Joypad.AButton)
        check("FLOOR: A tapped on the floor card's Eat never eats", #logged("ISEatFoodAction") == 0)
        hold(worldW, Joypad.AButton)
        local eats = logged("ISEatFoodAction")
        check("FLOOR: A held on it runs the game's eat on the floor item itself (it brings it over first)",
            #eats == 1 and eats[1].item == onFloor)
        check("FLOOR: ... with no move of ZeD's queued before it", #logged("move") == 0)
        focus(worldW, gels[1])
        tap(worldW, Joypad.AButton)
        local mv = logged("move")
        check("FLOOR: Grab (a tap) takes it into your inventory", mv[1] and mv[1].dest == MAIN and mv[1].items[1] == onFloor)
    end
    local inBag = item("apple", BAG, { cat = "Food" })
    inBag.carried = true
    card = makeCard(inBag, {})
    check("CARD: a thing in a bag you carry is your inventory (no Grab)", card:_effectiveContext() == "inventory")
end

-- WIRED
for _, f in ipairs({ "ZeD_CharacterWindow.lua", "ZeD_WorldWindow.lua" }) do
    local src = readFile(Z .. f) or ""
    local _, n = src:gsub("ZeD%.InventoryRenderer%.padItemButtons%(elements%[#elements%]%)", "")
    check("WIRED: " .. f .. " hands its list's and its columns' item stops to padItemButtons", n == 2, n)
end

print("x_moves_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
