-- ZeDUI/tools/qa/smart_attach_sim.lua  (smart attach, the director, Nov 24 2026)
-- ZeD_SmartAttach.lua with stand-ins for the game:
--   OFF      the setting off: nothing is queued
--   ATTACH   a hammer taken goes on the empty belt slot, by ISAttachItemHotbar queued after the take
--   FULL     a slot that holds something is left alone (no swap)
--   BACK     a bat goes to the back slot
--   ONE      two hammers taken, one belt slot: one attaches
--   SKIP     favorite, broken, in the hands, a bag: left alone; a worn one still attaches; no take queued: nothing
--   BAG      a take into a worn bag: to the main inventory first, then the attach
--   SPARE    a broken weapon: the most worn spare of its kind comes to hand (attached first on a tie), melee for melee,
--            never a firearm for melee; not in a car, not with a new thing in hand
--   WIRED    the take sites call it (Loot all, the item menu's Loot all, pad X on a row, Grab, the double-click), the
--            drag / Move to / Transfer all / Same type paths do not
--   SETTING  the switch, the presets (Access on, Vanilla and Plus off), the EN keys
-- Run from the repo root:  lua51 ZeDUI/tools/qa/smart_attach_sim.lua
-- It prints FAIL lines and a last line "smart_attach_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]smart_attach_sim%.lua$", "")
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
local function cut(src, from, to)
    local a = src and string.find(src, from, 1, true)
    if not a then return nil end
    local b = string.find(src, to, a, true)
    if not b then return nil end
    return string.sub(src, a, b + #to - 1)
end

-- ---------------------------------------------------------------------------
-- the game, stood in
local on = true
local inCar, aiming, mp = false, false, false
local queue = {}
local MAIN, BAG, CRATE = { n = "main" }, { n = "bag" }, { n = "crate" }
local CALL = "SmartAttach.after"

ZeD = { Settings = { smartAttachOn = function() return on end }, Safe = { on = function() return false end } }
Events = { OnPlayerAttackFinished = { Add = function() end }, OnTick = { Add = function() end } }
isClient = function() return mp end
getTimestampMs = function() return 0 end
isForceDropHeavyItem = function(it) return it.heavy == true end
WeaponCategory = { AXE = "AXE", BLUNT = "BLUNT", SPEAR = "SPEAR", LONG_BLADE = "LONG_BLADE", SMALL_BLADE = "SMALL_BLADE",
                   SMALL_BLUNT = "SMALL_BLUNT" }
instanceof = function(o, cls)
    if cls == "InventoryContainer" then return o.bag == true end
    if cls == "HandWeapon" then return o.weapon == true end
    return false
end
ISTimedActionQueue = {
    getTimedActionQueue = function() return { queue = queue } end,
    add = function(a) queue[#queue + 1] = a end,
}
ISInventoryTransferUtil = { newInventoryTransferAction = function(_, item, src, dest)
    return { Type = "ISInventoryTransferAction", item = item, srcContainer = src, destContainer = dest } end }
ISAttachItemHotbar = {}
ISAttachItemHotbar.start = function() end
ISAttachItemHotbar.isValid = function() return true end
function ISAttachItemHotbar:new(chr, item, slot, slotIndex, slotDef)
    local o = setmetatable({ Type = "ISAttachItemHotbar", character = chr, item = item, slot = slot, slotIndex = slotIndex,
        slotDef = slotDef, hotbar = getPlayerHotbar(0) }, { __index = ISAttachItemHotbar })   -- (the game's new sets hotbar)
    return o
end
local equipped = {}
ISInventoryPaneContextMenu = { equipWeapon = function(w, primary, twoHands, pn)
    equipped[#equipped + 1] = { w = w, primary = primary, two = twoHands }
    queue[#queue + 1] = { Type = "ISEquipWeaponAction", item = w }
end }

local function item(t)
    t.getAttachmentType = function(s) return s.atype end
    t.isFavorite = function(s) return s.fav == true end
    t.isBroken = function(s) return s.broken == true end
    t.isEquipped = function(s) return s.equipped == true end
    t.isRanged = function(s) return s.gun == true end
    t.getCondition = function(s) return s.cond or 10 end
    t.getConditionMax = function(s) return s.max or 10 end
    t.isTwoHandWeapon = function(s) return s.two == true end
    t.getType = function(s) return s.type or "Thing" end
    t.getScriptItem = function(s) return { containsWeaponCategory = function(_, c) return s.cat == c end } end
    return t
end
local BELT = { type = "SmallBeltLeft", name = "Belt Left", animset = "belt left", attachments = { Hammer = "Belt Left" } }
local BACKDEF = { type = "Back", name = "Back", animset = "back", attachments = { BigWeapon = "Bat On Back" } }
local hotbar
local hands = nil
local mainItems = {}
local player = {
    getPlayerNum = function() return 0 end,
    getVehicle = function() return inCar and {} or nil end,
    getInventory = function() return MAIN end,
    isEquipped = function(_, it) return it.equipped == true end,
    isAiming = function() return aiming end,
    getPrimaryHandItem = function() return hands end,
    isLocalPlayer = function() return true end,
}
MAIN.getItems = function() return { size = function() return #mainItems end, get = function(_, i) return mainItems[i + 1] end } end
getPlayerHotbar = function() return hotbar end
local function freshHotbar()
    hotbar = { availableSlot = { [1] = { def = BACKDEF }, [2] = { def = BELT } }, attachedItems = {}, replacements = {} }
    hotbar.isInHotbar = function(self, it) for _, v in pairs(self.attachedItems) do if v == it then return true end end return false end
end
-- a take queued for each item, as the band's move queues it
local function take(items, dest)
    for _, it in ipairs(items) do queue[#queue + 1] = { Type = "ISInventoryTransferAction", item = it, srcContainer = CRATE, destContainer = dest or MAIN } end
end
local function attaches()
    local out = {}
    for i, a in ipairs(queue) do if a.Type == "ISAttachItemHotbar" then out[#out + 1] = { a = a, at = i } end end
    return out
end
local function reset() queue = {}; equipped = {}; freshHotbar(); on, inCar, aiming, mp, hands = true, false, false, false, nil; mainItems = {} end

local SRC = readFile(Z .. "ZeD_SmartAttach.lua") or ""
check("SOURCE: ZeD_SmartAttach.lua read", #SRC > 0)
local fn, e = loadstring(SRC, "ZeD_SmartAttach")
check("SOURCE: loads", fn ~= nil, e)
if fn then fn() end
local SA = ZeD.SmartAttach or {}

-- ---------------------------------------------------------------------------
print("-- OFF")
reset(); on = false
local hammer = item({ atype = "Hammer" })
take({ hammer })
check("OFF: nothing queued", SA.after(player, { hammer }) == 0 and #attaches() == 0)

print("-- ATTACH")
reset()
hammer = item({ atype = "Hammer" })
take({ hammer })
local n = SA.after(player, { hammer })
local at = attaches()
check("ATTACH: one attach", n == 1 and #at == 1, n)
check("ATTACH: onto the belt slot", at[1] and at[1].a.slotIndex == 2 and at[1].a.slot == "Belt Left" and at[1].a.slotDef == BELT)
check("ATTACH: queued after the take", at[1] and at[1].at == 2 and queue[1].item == hammer)
check("ATTACH: marked for QA and Put back", at[1] and at[1].a._zedSmartAttach == true and at[1].a._zedApart == true)
check("ATTACH: QA field", SA.lastAttached == 1)
-- a slot filled by hand before it starts: dropped, nothing displaced
if at[1] then
    hotbar.attachedItems[2] = item({ atype = "Hammer" })
    check("ATTACH: a slot filled since is not displaced", at[1].a:isValid() == false)
end

print("-- FULL")
reset()
hotbar.attachedItems[2] = item({ atype = "Hammer" })
hammer = item({ atype = "Hammer" })
take({ hammer })
check("FULL: the full belt slot is left alone", SA.after(player, { hammer }) == 0 and #attaches() == 0)

print("-- BACK")
reset()
local bat = item({ atype = "BigWeapon" })
take({ bat })
SA.after(player, { bat })
at = attaches()
check("BACK: the bat goes to the back", #at == 1 and at[1].a.slotIndex == 1 and at[1].a.slot == "Bat On Back")
reset()
hotbar.replacements = { BigWeapon = "null" }
bat = item({ atype = "BigWeapon" })
take({ bat })
check("BACK: a bag that blocks the back: nothing", SA.after(player, { bat }) == 0)

print("-- ONE")
reset()
local h1, h2 = item({ atype = "Hammer" }), item({ atype = "Hammer" })
take({ h1, h2 })
SA.after(player, { h1, h2 })
at = attaches()
check("ONE: two hammers, one attaches", #at == 1 and at[1].a.item == h1)

print("-- SKIP")
for _, c in ipairs({ { "favorite", { fav = true } }, { "broken", { broken = true } }, { "in the hands", { equipped = true } },
                     { "a bag", { bag = true } }, { "heavy", { heavy = true } } }) do
    reset()
    local t = c[2]; t.atype = "Hammer"
    local it = item(t)
    take({ it })
    check("SKIP: " .. c[1], SA.after(player, { it }) == 0)
end
reset()
local worn = item({ atype = "Hammer", cond = 2 })
take({ worn })
check("SKIP: a worn one still attaches", SA.after(player, { worn }) == 1)
reset()
hammer = item({ atype = "Hammer" })
check("SKIP: no take queued (refused, or in the hands): nothing", SA.after(player, { hammer }) == 0)
reset()
local plain = item({})
take({ plain })
check("SKIP: a thing that does not hang", SA.after(player, { plain }) == 0)

print("-- BAG")
reset()
hammer = item({ atype = "Hammer" })
take({ hammer }, BAG)
SA.after(player, { hammer })
check("BAG: take, then to the main inventory, then attach", #queue == 3 and queue[2].Type == "ISInventoryTransferAction"
    and queue[2].srcContainer == BAG and queue[2].destContainer == MAIN and queue[3].Type == "ISAttachItemHotbar")

-- ---------------------------------------------------------------------------
print("-- SPARE")
local function weapon(t) t.weapon = true; t.cat = t.cat or (not t.gun and "BLUNT" or nil); return item(t) end
reset()
local broke = weapon({ broken = true, cond = 0, type = "BaseballBat" })
hands = nil   -- (the game took it out of the hands)
local good = weapon({ cond = 9 })
local worn2 = weapon({ cond = 3 })
local attachedWorn = weapon({ cond = 3 })
hotbar.attachedItems[1] = attachedWorn
mainItems = { broke, good, worn2, attachedWorn }
check("SPARE: replaced", SA.replaceBroken(player, broke) == true)
check("SPARE: the most worn, the attached one on a tie", equipped[1] and equipped[1].w == attachedWorn, equipped[1] and equipped[1].w.cond)
check("SPARE: QA field", SA.lastSpare == attachedWorn)
check("SPARE: an equip waiting: not twice", SA.replaceBroken(player, broke) == false and #equipped == 1)

reset()
broke = weapon({ broken = true, cond = 0 })
local sameKind = weapon({ cond = 8 })
local otherKind = weapon({ cond = 1, cat = "AXE" })
mainItems = { broke, otherKind, sameKind }
SA.replaceBroken(player, broke)
check("SPARE: the same kind before a more worn other kind", equipped[1] and equipped[1].w == sameKind)

reset()
broke = weapon({ broken = true, cond = 0 })
local axe = weapon({ cond = 5, cat = "AXE", two = true })
local gun = weapon({ gun = true, cond = 1 })
mainItems = { broke, gun, axe }
SA.replaceBroken(player, broke)
check("SPARE: any melee when no same kind, two hands for a two-handed", equipped[1] and equipped[1].w == axe and equipped[1].two == true)

reset()
broke = weapon({ broken = true, cond = 0 })
mainItems = { broke, weapon({ gun = true }) , weapon({ broken = true, cond = 0 }), item({ weapon = true }) }
check("SPARE: never a firearm for melee, a broken one or a thing with no kind", SA.replaceBroken(player, broke) == false and #equipped == 0)

reset()
broke = weapon({ broken = true, cond = 0, gun = true })
mainItems = { broke, weapon({ cond = 5 }) }
check("SPARE: never melee for a firearm", SA.replaceBroken(player, broke) == false)

reset()
broke = weapon({ broken = true, cond = 0 })
mainItems = { broke, weapon({ cond = 5 }) }
inCar = true
check("SPARE: not in a car", SA.replaceBroken(player, broke) == false)
inCar = false
hands = weapon({ cond = 5 })
check("SPARE: not with a new thing in hand", SA.replaceBroken(player, broke) == false)
hands = broke
check("SPARE: with the broken one still in hand", SA.replaceBroken(player, broke) == true)
reset(); on = false
broke = weapon({ broken = true, cond = 0 })
mainItems = { broke, weapon({ cond = 5 }) }
check("SPARE: setting off: nothing", SA.replaceBroken(player, broke) == false)
reset()
local fine = weapon({ cond = 4 })
mainItems = { fine, weapon({ cond = 5 }) }
SA.onAttackFinished(player, fine)
check("SPARE: a swing that did not break it: nothing", #equipped == 0)
mp = true
SA.onAttackFinished(player, fine)
check("SPARE: multiplayer watches the swing", SA._watch[player] ~= nil)
fine.broken = true
SA.tick()
check("SPARE: broken a moment later (multiplayer): replaced", #equipped == 1 and SA._watch[player] == nil)

-- ---------------------------------------------------------------------------
print("-- WIRED")
local CC = readFile(Z .. "ContainerControls.lua") or ""
local IR = readFile(Z .. "InventoryRenderer.lua") or ""
local IC = readFile(Z .. "ItemCard.lua") or ""
check("WIRED: Loot all (band, heading, pad X on a container's button)", has(cut(CC, "function CT.lootAll(", "\nend\n"), CALL))
check("WIRED: the item menu's Loot all (CT.takeAll)", has(cut(CC, "function CT.takeAll(", "\nend\n"), CALL))
check("WIRED: pad X on a World window row (moveToOther)", has(cut(CC, "function CT.moveToOther(", "\nend\n"), CALL))
check("WIRED: the card's Grab", has(cut(IC, 'elseif label == "TAKE" then', 'elseif label == "EAT"'), CALL))
local qu = cut(IR, "function ZeD.InventoryRenderer.quickUse(", "\nend\n")
check("WIRED: the double-click, not the Shift wear", has(qu, "if not wear and ZeD.SmartAttach then ZeD.SmartAttach.after("))
check("WIRED: Transfer all does not", not has(cut(CC, "function CT.transferAll(", "\nend\n"), CALL))
check("WIRED: moveItems (Move to, Put in, Same type, drags) does not", not has(cut(CC, "function CT.moveItems(", "\nend\n"), CALL))
check("WIRED: grabItems (the pad's drag) does not", not has(cut(CC, "function CT.grabItems(", "\nend\n"), CALL))
check("WIRED: the band's buildChar / buildWorld do not", not has(cut(CC, "local function buildChar(", "\nend\n"), CALL)
    and not has(cut(CC, "local function buildWorld(", "\nend\n"), CALL))
local GL = readFile(Z .. "GridLayout.lua") or ""
check("WIRED: the grid's drag does not", not has(GL, CALL))

print("-- SETTING")
local ST = readFile(Z .. "Settings.lua") or ""
local GR = readFile(Z .. "ZeD_MainMenuOptionGroups.lua") or ""
local EN = readFile(ROOT .. "42/media/lua/shared/Translate/EN/UI.json") or ""
check("SETTING: the switch", has(ST, 'onSwitch("smartAttach", "UI_ZeD_Settings_SmartAttach", "UI_ZeD_Settings_SmartAttachTip")'))
check("SETTING: an addition", has(ST, '"smartAttach" }'))
local pre = cut(ST, "local PRESETS = {", "\n    }\n") or ""
local _, offs = string.gsub(pre, "smartAttach = OFF", "")
local _, ons = string.gsub(pre, "smartAttach = ON", "")
check("SETTING: Vanilla and Plus off, Access on", offs == 2 and ons == 1 and has(pre, "appliances = OFF, smartAttach = ON"), offs .. "/" .. ons)
check("SETTING: ZeD setup row", has(GR, '{ "smartAttach", "onoff" }'))
check("SETTING: EN keys", has(EN, '"UI_ZeD_Settings_SmartAttach":') and has(EN, '"UI_ZeD_Settings_SmartAttachTip":'))

print("smart_attach_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
