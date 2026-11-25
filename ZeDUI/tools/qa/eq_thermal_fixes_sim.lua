-- ZeDUI/tools/qa/eq_thermal_fixes_sim.lua  (Nov 24 2026, Build; QA's Equipment and Thermal sweep, et.txt)
--   STILLON  ZeD.EquipmentTab.stillOn (cut from the real file): worn, in a hand or on the belt is on;
--            unequipped into the bag or dropped is off
--   PIN      the card mode's pin: a layered slot's card closes once its thing is off, not turning into the
--            layer under it; a layer change on the strip keeps it open (S1, eq_tab 3b/3c/3e)
--   WEAR     a drop on the doll wears by the game's onWearItems, which lowers a hood first (S2, eq_tab 5d)
--   DROP     the card's Drop is grayed with the game's DropFromVehicle reason in a shut car (eq_tab 14)
--   COLS     the Thermal grid goes to one column where two would leave a cell no room for its name (T7)
--   HOVER    a folded figure has no hovered part (T8); the hover is clipped to the body's view (T9)
-- Run from the repo root:  lua51 ZeDUI/tools/qa/eq_thermal_fixes_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]eq_thermal_fixes_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return "" end
    local s = f:read("*a"); f:close()
    return (s:gsub("\r\n", "\n"))
end
local function cut(src, from, to)
    local a = string.find(src, from, 1, true)
    if not a then return nil end
    local b = string.find(src, to, a, true)
    return b and string.sub(src, a, b + #to - 1) .. "\n" or nil
end
local function has(s, x) return string.find(s, x, 1, true) ~= nil end

local ET = readFile(Z .. "EquipmentTab.lua")
local ED = readFile(Z .. "EquipDoll.lua")
local ICO = readFile(Z .. "ItemCardOrganism.lua")
local TT = readFile(Z .. "ThermalTab.lua")
local CW = readFile(Z .. "ZeD_CharacterWindow.lua")

print("-- STILLON")
ZeD = { EquipmentTab = {} }
local src = cut(ET, "function ZeD.EquipmentTab.stillOn(playerObj, item)", "\nend\n")
check("STILLON: found", src ~= nil)
if src then
    local fn, e = loadstring(src, "stillOn")
    check("STILLON: loads", fn ~= nil, e)
    if fn then
        fn()
        local inv, floor = {}, {}
        local function item(slot) local it = { c = inv, slot = slot or -1 }
            it.getContainer = function(self) return self.c end
            it.getAttachedSlot = function(self) return self.slot end
            return it end
        local jacket, sweater, hammer, belted, loose = item(), item(), item(), item(2), item()
        local worn = { jacket = true, sweater = true }
        local p = {
            getInventory = function() return inv end,
            getPrimaryHandItem = function() return hammer end,
            getSecondaryHandItem = function() return nil end,
            getWornItems = function() return { contains = function(_, it) return (it == jacket and worn.jacket) or (it == sweater and worn.sweater) end } end,
        }
        local on = ZeD.EquipmentTab.stillOn
        check("STILLON: worn", on(p, jacket) == true)
        check("STILLON: in hand", on(p, hammer) == true)
        check("STILLON: on the belt", on(p, belted) == true)
        check("STILLON: loose in the bag: off", on(p, loose) == false)
        worn.jacket = false
        check("STILLON: unequipped: off", on(p, jacket) == false)
        sweater.c = floor
        check("STILLON: dropped: off", on(p, sweater) == false)
        check("STILLON: nil: off", on(p, nil) == false)
    end
end

print("-- PIN")
check("PIN: the pin is read before the revert", (string.find(ET, "win._equipPinItem ~= selSlot.item", 1, true) or 1e9) < (string.find(ET, "-- If selected item was unequipped externally", 1, true) or 0))
check("PIN: closes only when the old thing is off", has(ET, "and not ZeD.EquipmentTab.stillOn(win._playerObj, win._equipPinItem) then"))
check("PIN: same slot only", has(ET, "win._equipPinKey == win._equipSelected"))
check("PIN: follows the shown thing", has(ET, "win._equipPinItem = selSlot and selSlot.item or nil"))
check("PIN: cleared on close", has(ET, "win._equipPinKey, win._equipPinItem = nil, nil"))
-- the rule itself, as a table: jacket over sweater
local function closes(pinKey, sel, pinItem, shown, pinOn)
    return (shown ~= nil and pinKey == sel and pinItem ~= nil and pinItem ~= shown and not pinOn)
end
check("PIN: jacket taken off, sweater shown: closes", closes("doll:torso", "doll:torso", "jacket", "sweater", false))
check("PIN: layer strip to the sweater, jacket still on: stays", not closes("doll:torso", "doll:torso", "jacket", "sweater", true))
check("PIN: a new slot: stays", not closes("doll:torso", "doll:hands", "jacket", "ring", false))

-- the pin is fresh on each opening: the selection-change block clears it (QA eq_tab 8)
do
    local blk = cut(ET, "if win._equipSelected ~= win._equipSelPrev then", "\n    end\n")
    check("PIN: a new opening (or the list between) clears the pin", blk ~= nil and has(blk, "win._equipPinKey, win._equipPinItem = nil, nil"))
end

print("-- WEAR")
check("WEAR: the doll's drop uses onWearItems", has(ED, "ISInventoryPaneContextMenu.onWearItems({ item }, pn)"))
check("WEAR: no direct wearItem left on the drop", not has(ED, "ISInventoryPaneContextMenu.wearItem(item, pn)"))

print("-- DROP")
local dsrc = cut(ICO, "local function dropVerb(playerObj)", "\nend\n")
check("DROP: found", dsrc ~= nil)
if dsrc then
    local shut = false
    ZeD = { ItemCard = { verbText = function(id) return id end },
            InventoryRenderer = { carWindowShut = function() return shut end } }
    getText = function(k) return "T:" .. k end
    local fn = loadstring(dsrc .. "\nreturn dropVerb", "dropVerb")
    local dropVerb = fn and fn()
    check("DROP: loads", dropVerb ~= nil)
    if dropVerb then
        local v = dropVerb({})
        check("DROP: open air: live", not v.disabled and v.id == "DROP")
        shut = true
        v = dropVerb({})
        check("DROP: shut car: grayed", v.disabled == true)
        check("DROP: the game's reason", v.offHelp == "T:ContextMenu_DropFromVehicle")
    end
end
check("DROP: the equipped card uses it", has(ICO, "            dropVerb(playerObj),"))
check("DROP: the bag card uses it", has(ICO, "verbs[#verbs + 1] = dropVerb(playerObj)"))

print("-- COLS")
local csrc = cut(TT, "function ZeD.ThermalTab.gridCols(listW, celsius)", "\nend\n")
check("COLS: found", csrc ~= nil)
if csrc then
    local scale = 1
    ZeD = { ThermalTab = { useCelsius = function() return true end, tempText = function() return "36.6 C" end },
            T = { sp = { sm = 6 }, fontF3 = "f3", fontF2 = "f2", px = function(n) return n * scale end },
            Atoms = { fillBarMinW = function() return 40 * scale end, rowBarW = function() return 80 * scale end },
            TM = { MeasureStringX = function(_, f, s) return #s * 7 * scale end } }
    local fn, e = loadstring(csrc, "gridCols")
    check("COLS: loads", fn ~= nil, e)
    if fn then
        fn()
        check("COLS: the 480 card: two", ZeD.ThermalTab.gridCols(456) == 2)
        check("COLS: the 220 card: one", ZeD.ThermalTab.gridCols(200) == 1)
        scale = 1.5
        check("COLS: the 220 card, Large text: one", ZeD.ThermalTab.gridCols(300) == 1)
    end
end
check("COLS: the draw uses it", has(TT, "local nCols = ZeD.ThermalTab.gridCols(listW, celsius)"))
check("COLS: the measure uses it", has(TT, "math.ceil(#PART_ORDER / ZeD.ThermalTab.gridCols(listW))"))
check("COLS: one column stacks every cell", has(TT, "if nCols == 1 then leftY = cy + rowH + rowGap"))

print("-- HOVER")
check("HOVER: folded clears the hover", has(TT, "if not win._thermalFigureExpanded then win._thermalHoveredPart = nil end"))
check("HOVER: clipped to the body's view", has(CW, "win._thermalHoveredPart = inView and win._thermalBodyFigure:hitTestAt(mx, my) or nil"))

print("-- COLDRAG")
check("COLDRAG: a dragged width no longer turns the fitting off", not has(ET, "if not (win and win._equipColWidths) and nameW < need then"))
check("COLDRAG: with dragged widths the steps run once the name would fall under its least", has(ET, "if win and win._equipColWidths then need = T.px(40) end"))

print("eq_thermal_fixes_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
