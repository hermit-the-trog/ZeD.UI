-- ZeDUI/tools/qa/smart_menu_sim.lua  (Nov 24 2026, Build; smart menu, the director, Nov 24 2026)
-- The item menu opens on its best guess (ZeD_MenuGuess.lua), loaded here with stubs:
--   NEED     hungry: Eat; thirsty: Drink; a wound: Apply Bandage; tired: Read (and only when the need is there)
--   MOVE     the row that moves it to the container last moved into; forgotten after 60 s or a walk away; never the floor
--   REPEAT   the last pick on the same full type; capped (FIFO); moves and danger rows are never remembered
--   USE      the item's main use: weapon Equip Primary, clothing not worn Wear, book Read, food Eat, a drink Drink
--   ORDER    a need beats a move beats a repeat beats the main use
--   SKIP     greyed rows and danger rows are never guessed; a submenu row lands on its parent; a parent with only
--            greyed rows inside is skipped
--   OFF      the setting off: no guess
--   PLACE    the placement math: the row's centre under the pointer, clamped to the screen (onRow false then)
--   WIRED    both looks and the override read it; CT.moveItems notes moves; the setting row and its words exist
-- Run from the repo root:  lua51 ZeDUI/tools/qa/smart_menu_sim.lua
-- It prints FAIL lines and a last line "smart_menu_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]smart_menu_sim%.lua$", "")
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
local function has(src, s) return src ~= nil and string.find(src, s, 1, true) ~= nil end

-- ---------------------------------------------------------------------------
-- stubs
-- ---------------------------------------------------------------------------
local TEXT = {
    ContextMenu_Eat = "Eat", ContextMenu_OpenAndEat = "Open and Eat", ContextMenu_Drink = "Drink",
    ContextMenu_OpenAndDrink = "Open and Drink", ContextMenu_Apply_Bandage = "Apply Bandage",
    ContextMenu_Read = "Read", ContextMenu_Wear = "Wear", ContextMenu_Equip_Primary = "Equip Primary",
    ContextMenu_Equip_Two_Hands = "Equip in Both Hands", ContextMenu_Drop = "Drop", ContextMenu_DropNamedItem = "Drop %1",
    ContextMenu_Disassemble = "Disassemble", ContextMenu_Move_To = "Move to", ContextMenu_Inspect = "Inspect",
}
getText = function(k) return TEXT[k] or k end
local clock = 1000000
getTimestampMs = function() return clock end
instanceof = function(o, cls) return type(o) == "table" and o._cls ~= nil and o._cls[cls] == true end
MoodleType = { HUNGRY = "HUNGRY", THIRST = "THIRST", TIRED = "TIRED", BLEEDING = "BLEEDING" }
local moods = {}
local P = { x = 10, y = 10, z = 0 }
function P:getMoodles() return { getMoodleLevel = function(_, t) return moods[t] or 0 end } end
function P:getPlayerNum() return 0 end
function P:getX() return self.x end
function P:getY() return self.y end
function P:getZ() return self.z end
getSpecificPlayer = function() return P end
local hurt = false
local setting = nil
ZeD = { QuickWheel = { hurt = function() return hurt end }, Settings = {} }
ISInventoryPaneContextMenu = { onPutItems = function() end, onMoveItemsTo = function() end }
local LOOT = nil
getPlayerLoot = function() return { inventory = LOOT } end

local function item(ft, cls, extra)
    local it = { ft = ft, _cls = {} }
    for _, c in ipairs(cls or {}) do it._cls[c] = true end
    for k, v in pairs(extra or {}) do it[k] = v end
    function it:getFullType() return self.ft end
    function it:isEquipped() return self.equipped == true end
    function it:getFluidContainer() return self.fluid end
    return it
end
local function inv(name, typ)
    local c = { name = name, _cls = { ItemContainer = true } }
    function c:getType() return typ or "crate" end
    return c
end
-- an ActionDef as the registry makes it (only the fields the guess reads)
local function row(name, opts)
    opts = opts or {}
    local o = { name = name, notAvailable = opts.grey or false, onSelect = opts.onSelect }
    for i = 1, 4 do o["param" .. i] = opts["p" .. i] end
    local d = { name = name, vanillaRef = o, children = opts.kids, subOption = opts.kids and 1 or nil }
    d.disabled = function() return o.notAvailable end
    return d
end

local src = readFile(Z .. "ZeD_MenuGuess.lua")
check("SOURCE: ZeD_MenuGuess.lua read", src ~= nil)
local fn, e = loadstring(src or "", "ZeD_MenuGuess")
check("SOURCE: loads", fn ~= nil, e)
if not fn then print("smart_menu_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end
fn()
local G = ZeD.MenuGuess
local function reset()
    moods, hurt, setting, LOOT = {}, false, nil, nil
    G._moves, G._picks, G.last = {}, {}, {}
    P.x, P.y, P.z = 10, 10, 0
    ZeD.Settings.menuGuessOption = nil
end

-- the rows an apple's menu might have: Inspect, Eat (submenu), Move to (submenu), Drop
local CRATE, BAG, FLOOR = inv("Crate"), inv("Bag"), inv("Floor", "floor")
local function foodMenu(eatGrey)
    return {
        row("Inspect"),
        row("Eat", { kids = { row("All", { grey = eatGrey }), row("1/2", { grey = eatGrey }) } }),
        row("Move to", { kids = { row("Crate", { p2 = CRATE }), row("Bag", { p2 = BAG }), row("Floor", { p2 = FLOOR }) } }),
        row("Drop"),
    }
end
local APPLE = item("Base.Apple", { "Food" })

-- ---------------------------------------------------------------------------
print("-- NEED")
reset()
check("NEED: not hungry, food -> main use Eat", select(2, G.pick(foodMenu(), 0, { APPLE })) == "use")
moods.HUNGRY = 1
local i, r = G.pick(foodMenu(), 0, { APPLE })
check("NEED: hungry -> Eat (the parent row)", i == 2 and r == "hungry", tostring(i) .. " " .. tostring(r))
check("NEED: G.last names it", G.last[0] and G.last[0].idx == 2 and G.last[0].rule == "hungry" and G.last[0].name == "Eat")
reset(); moods.THIRST = 2
local WATER = item("Base.WaterBottle", {}, { fluid = {} })
i, r = G.pick({ row("Inspect"), row("Drink"), row("Drop") }, 0, { WATER })
check("NEED: thirsty -> Drink", i == 2 and r == "thirsty", tostring(r))
reset(); hurt = true
local BANDAGE = item("Base.Bandage", {})
i, r = G.pick({ row("Inspect"), row("Apply Bandage", { kids = { row("Hand_L"), row("Hand_R") } }), row("Drop") }, 0, { BANDAGE })
check("NEED: wounded -> Apply Bandage", i == 2 and r == "wound", tostring(r))
reset(); moods.TIRED = 1
local BOOK = item("Base.Book", { "Literature" })
i, r = G.pick({ row("Inspect"), row("Re-read"), row("Drop") }, 0, { BOOK })
check("NEED: tired, a book already read (Re-read) is not guessed", i == nil, tostring(i))
i, r = G.pick({ row("Inspect"), row("Read"), row("Drop") }, 0, { BOOK })
check("NEED: tired -> Read", i == 2 and r == "tired", tostring(r))

-- ---------------------------------------------------------------------------
print("-- SKIP")
reset(); moods.HUNGRY = 1
i, r = G.pick(foodMenu(true), 0, { APPLE })
check("SKIP: Eat with every row inside greyed is not guessed", i ~= 2, tostring(i))
local greyEat = { row("Inspect"), row("Eat", { grey = true }), row("Drop") }
i = G.pick(greyEat, 0, { APPLE })
check("SKIP: a greyed row is never guessed", i == nil, tostring(i))
reset()
check("SKIP: danger by key", G.isDanger(row("Drop")) and G.isDanger(row("Drop Apple")) and G.isDanger(row("Disassemble")))
check("SKIP: not danger", not G.isDanger(row("Eat")) and not G.isDanger(row("Inspect")))
check("SKIP: the find never lands on a danger row", G.find({ row("Drop") }, nil, function() return true end) == nil)
local lazy = row("Wear"); lazy.subOption = 3   -- (a submenu not filled yet)
check("SKIP: an unfilled submenu row is not guessed", G.find({ lazy }, nil, function() return true end) == nil)

-- ---------------------------------------------------------------------------
print("-- MOVE")
reset()
G.noteMove(P, CRATE)
i, r = G.pick(foodMenu(), 0, { APPLE })
check("MOVE: lands on Move to (the crate row inside)", i == 3 and r == "move", tostring(i) .. " " .. tostring(r))
G.noteMove(P, FLOOR)
check("MOVE: the floor is never remembered", G._moves[0].dest == CRATE)
clock = clock + 59000
check("MOVE: still remembered at 59 s", G.lastMove(0, P) == CRATE)
clock = clock + 2000
check("MOVE: forgotten after 60 s", G.lastMove(0, P) == nil and G._moves[0] == nil)
G.noteMove(P, CRATE)
P.x = 14
check("MOVE: forgotten after a walk away", G.lastMove(0, P) == nil)
P.x = 10
G.noteMove(P, CRATE)
P.z = 1
check("MOVE: forgotten on another floor", G.lastMove(0, P) == nil)
P.z = 0
G.noteMove(P, inv("Elsewhere"))
check("MOVE: a container the menu has no row for: no move guess", select(2, G.pick(foodMenu(), 0, { APPLE })) ~= "move")
local PUT = { row("Inspect"), row("Put in Container (Crate)", { onSelect = ISInventoryPaneContextMenu.onPutItems }),
              row("Move to", { kids = { row("Crate", { p2 = CRATE }) } }) }
reset(); LOOT = CRATE; G.noteMove(P, CRATE)
i = G.pick(PUT, 0, { APPLE })
check("MOVE: the game's Put in Container on that page wins (a top row)", i == 2, tostring(i))
reset(); G.noteMove(P, CRATE)
local greyCrate = { row("Inspect"), row("Move to", { kids = { row("Crate", { p2 = CRATE, grey = true }) } }) }
check("MOVE: a greyed (full) container row is not guessed", G.pick(greyCrate, 0, { item("Base.Rock", {}) }) == nil)

-- ---------------------------------------------------------------------------
print("-- REPEAT")
reset()
local SHIRT = item("Base.Tshirt", { "Clothing" }, { equipped = true })
local shirtMenu = { row("Inspect"), row("Unequip"), row("Rename"), row("Drop") }
check("REPEAT: nothing remembered, worn shirt: no guess", G.pick(shirtMenu, 0, { SHIRT }) == nil)
G.notePick(0, "Base.Tshirt", { "Rename" }, shirtMenu[3], {})
i, r = G.pick(shirtMenu, 0, { SHIRT })
check("REPEAT: the last pick on the type", i == 3 and r == "repeat", tostring(i))
G.notePick(0, "Base.Tshirt", { "Drop" }, shirtMenu[4], {})
check("REPEAT: a danger pick is never remembered", G._picks[0].map["Base.Tshirt"][1] == "Rename")
local mv = row("Crate", { p2 = CRATE })
G.notePick(0, "Base.Tshirt", { "Move to", "Crate" }, mv, { row("Move to") })
check("REPEAT: a move pick is never remembered", G._picks[0].map["Base.Tshirt"][1] == "Rename")
G.notePick(0, "Base.Apple", { "Eat", "1/2" }, row("1/2"), { row("Eat") })
reset(); G.notePick(0, "Base.Apple", { "Eat", "1/2" }, row("1/2"), { row("Eat") })
i, r = G.pick(foodMenu(), 0, { APPLE })
check("REPEAT: a pick inside a submenu lands on its parent", i == 2 and r == "repeat", tostring(r))
check("REPEAT: mixed kinds have no type", G.typeOf({ APPLE, SHIRT }) == nil and G.typeOf({ APPLE, APPLE }) == "Base.Apple")
check("REPEAT: stacks read through", G.typeOf({ { items = { APPLE, APPLE, APPLE } } }) == "Base.Apple")
for n = 1, 70 do G.notePick(0, "Base.T" .. n, { "Inspect" }, row("Inspect"), {}) end
check("REPEAT: capped at 64, oldest gone", #G._picks[0].order == 64 and G._picks[0].map["Base.T1"] == nil
    and G._picks[0].map["Base.T70"] ~= nil and G._picks[0].map["Base.Apple"] == nil)
G.notePick(0, "Base.T10", { "Inspect" }, row("Inspect"), {})
check("REPEAT: a pick again moves to the newest", G._picks[0].order[64] == "Base.T10" and #G._picks[0].order == 64)
reset()
G.notePick(0, "Base.Tshirt", { "Rename" }, shirtMenu[3], {})
local greyRename = { row("Inspect"), row("Rename", { grey = true }) }
check("REPEAT: a remembered row greyed now is skipped", G.pick(greyRename, 0, { SHIRT }) == nil)

-- ---------------------------------------------------------------------------
print("-- USE")
reset()
local AXE = item("Base.Axe", { "HandWeapon" })
i, r = G.pick({ row("Inspect"), row("Equip Primary"), row("Equip Secondary"), row("Drop") }, 0, { AXE })
check("USE: weapon -> Equip Primary", i == 2 and r == "use")
local HAT = item("Base.Hat", { "Clothing" })
check("USE: clothing not worn -> Wear", G.pick({ row("Inspect"), row("Wear"), row("Drop") }, 0, { HAT }) == 2)
check("USE: book -> Read", G.pick({ row("Inspect"), row("Read") }, 0, { BOOK }) == 2)
check("USE: a drink -> Drink", G.pick({ row("Inspect"), row("Drink") }, 0, { WATER }) == 2)
check("USE: food -> Eat", G.pick(foodMenu(), 0, { APPLE }) == 2)
check("USE: a thing with no main use -> no guess", G.pick({ row("Inspect"), row("Drop") }, 0, { item("Base.Rock", {}) }) == nil)

-- ---------------------------------------------------------------------------
print("-- ORDER")
reset(); moods.HUNGRY = 1
G.noteMove(P, CRATE)
G.notePick(0, "Base.Apple", { "Inspect" }, row("Inspect"), {})
check("ORDER: a need beats a move and a repeat", select(2, G.pick(foodMenu(), 0, { APPLE })) == "hungry")
moods.HUNGRY = 0
check("ORDER: a move beats a repeat", select(2, G.pick(foodMenu(), 0, { APPLE })) == "move")
G._moves = {}
check("ORDER: a repeat beats the main use", select(2, G.pick(foodMenu(), 0, { APPLE })) == "repeat")

-- ---------------------------------------------------------------------------
print("-- OFF")
reset(); moods.HUNGRY = 1
ZeD.Settings.menuGuessOption = { getValue = function() return 1 end }
check("OFF: the setting off, no guess", G.pick(foodMenu(), 0, { APPLE }) == nil and G.last[0] == nil)
ZeD.Settings.menuGuessOption = { getValue = function() return 2 end }
check("OFF: the setting on, the guess", G.pick(foodMenu(), 0, { APPLE }) == 2)
ZeD.Settings.menuGuessOption = nil
check("OFF: no option yet reads on", G.on() == true)

-- ---------------------------------------------------------------------------
print("-- PLACE")
-- a 400 x 200 box whose row centre is at (100, 50) in it, the row 40 x 20; screen 1920 x 1080, pad 8
local x, y, on = G.place(600, 500, 100, 50, 20, 10, 400, 200, 1920, 1080, 8)
check("PLACE: the row's centre under the pointer", x == 500 and y == 450 and on == true, x .. "," .. y)
x, y, on = G.place(1900, 1070, 100, 50, 20, 10, 400, 200, 1920, 1080, 8)
check("PLACE: clamped right and bottom", x == 1920 - 400 - 8 and y == 1080 - 200 - 8 and on == false)
x, y, on = G.place(20, 20, 100, 50, 20, 10, 400, 200, 1920, 1080, 8)
check("PLACE: clamped left and top", x == 8 and y == 8 and on == false)
x, y, on = G.place(110, 60, 100, 50, 20, 10, 400, 200, 1920, 1080, 8)
check("PLACE: a small clamp keeps the pointer on the row", x == 10 and y == 10 and on == true, x .. "," .. y)

-- ---------------------------------------------------------------------------
print("-- WIRED")
local CM = readFile(Z .. "Overrides/ContextMenu.lua") or ""
local SM = readFile(Z .. "ZeD_ContextMenu.lua") or ""
local CL = readFile(Z .. "ZeD_ContextList.lua") or ""
local CC = readFile(Z .. "ContainerControls.lua") or ""
local ST = readFile(Z .. "Settings.lua") or ""
local OG = readFile(Z .. "ZeD_MainMenuOptionGroups.lua") or ""
local EN = readFile(ROOT .. "42/media/lua/shared/Translate/EN/UI.json") or ""
local CX = readFile(ROOT .. "ZeDUI/i18n/UI_ZeD.context.md") or ""
check("WIRED: the override guesses for item menus", has(CM, "ZeD.MenuGuess.pick, tree, self.player, self._zedGuessItems")
    and has(CM, "menu._zedGuessItems = items") and has(CM, "m._zedGuessUnder = gIdx ~= nil and not self._zedByPad"))
check("WIRED: get clears the guess", has(CM, "context._zedGuessItems, context._zedByPad"))
check("WIRED: the strip opens on it and places it", has(SM, "self._ctx.selected = g end") and has(SM, "ZeD.MenuGuess.place(")
    and has(SM, "ZeD.MenuGuess.notePick"))
check("WIRED: the list opens on it and places it", has(CL, "top.sel = gRow") and has(CL, "ZeD.MenuGuess.place(")
    and has(CL, "self._guessHold = false") and has(CL, "ZeD.MenuGuess.notePick"))
check("WIRED: CT.moveItems notes the move", has(CC, "ZeD.MenuGuess.noteMove(playerObj, dest)"))
check("WIRED: Put in Container notes the move", has(CM, "ZeD.MenuGuess.noteMove(getSpecificPlayer(player)"))
check("WIRED: the setting", has(ST, "addComboBox(\"menuGuess\"") and has(ST, "menuGuess = \"UI_ZeD_Settings_MenuGuess\"")
    and has(OG, "{ \"menuGuess\", \"onoff\" }"))
check("WIRED: its words", has(EN, "\"UI_ZeD_Settings_MenuGuess\"") and has(EN, "\"UI_ZeD_Settings_MenuGuessTip\"")
    and has(CX, "`UI_ZeD_Settings_MenuGuess`") and has(CX, "`UI_ZeD_Settings_MenuGuessTip`"))
check("WIRED: ASCII only", not string.find(src, "[\128-\255]"))

print("smart_menu_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
