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
local CTRL, ALT = false, false
isCtrlKeyDown = function() return CTRL end
isShiftKeyDown = function() return false end
Keyboard = { KEY_LMENU = 56, KEY_RMENU = 184, KEY_A = 30 }
isKeyDown = function(k) return ALT and (k == 56 or k == 184) end
ISMouseDrag = {}
local WIN = { _playerObj = PLAYER }
local BALLOONS = {}
-- the card's layer: a top-level panel; what it draws is recorded
ISPanel = {}
ISPanel.__index = ISPanel
function ISPanel:new(x, y, w, h) return setmetatable({ x = x, y = y, w = w, h = h, visible = true }, ISPanel) end
function ISPanel:initialise() end
function ISPanel:instantiate() self.javaObject = { setConsumeMouseEvents = function() end } end
function ISPanel:addToUIManager() self.inUI = true end
function ISPanel:setAlwaysOnTop(v) self.onTop = v end
function ISPanel:isVisible() return self.visible end
function ISPanel:setVisible(v) self.visible = v end
function ISPanel:bringToTop() end
local NOW = 1000
getTimestampMs = function() return NOW end
getText = function(k) return k end
-- (the game's classes: a stub item says what it is)
instanceof = function(o, cls) return type(o) == "table" and o._is ~= nil and o._is[cls] == true end
local function status(f, text) local lit = (f <= 0) and 0 or math.max(1, math.ceil(math.min(1, f) * 5 - 1e-6)); return lit >= 4 and "G" or (lit >= 2 and (text and "y" or "Y") or "R") end
ZeD = { Balloon = { draw = function(p, content, a, side, opts)
            BALLOONS[#BALLOONS + 1] = { content = content, rect = { x = a.x, y = a.y, w = a.w, h = a.h }, side = side, key = opts and opts.key, layer = p }
        end },
        T = { px = function(v) return v end, accent = { r = 1, g = 0, b = 0 }, info = { r = 0, g = 0, b = 1, name = "info" }, scale = 1, fontF2 = "F2", fontF3 = "F3",
              text = { r = 1, g = 1, b = 1 }, textSec = { r = 0.6, g = 0.6, b = 0.6 } },
        tr = function(k, a) return a and (k .. "(" .. tostring(a) .. ")") or k end,
        TM = { MeasureStringX = function(_, _, s2) return #tostring(s2) * 6 end, getFontHeight = function() return 14 end },
        Molecules = { drawTag = function() return 30, 16 end },
        Atoms = { windowOf = function() return WIN end, statusColor = status, tagW = function(t) return #t * 6 + 10 end,
                  FILL_SEGS = 10, fillSegsLit = function(f, n) n = n or 10; if f <= 0 then return 0 end if f >= 1 then return n end return math.floor(f * n + 1e-6) end,
                  fillBarCompactH = function() return 8 end, STATUS_SEGS = 5, statusSegsLit = function() return 3 end,
                  drawSegFill = function() end, drawTextRight = function() end,
                  requestBalloon = function(owner, key, content, panel, rect, opts)
                      BALLOONS[#BALLOONS + 1] = { owner = owner, key = key, content = content, rect = { x = rect.x, y = rect.y, w = rect.w, h = rect.h }, opts = opts }
                  end } }

local function load(name)
    local f, err = loadfile(CDIR .. name)
    if not f then print("fast_loot_sim: " .. tostring(err)); os.exit(1) end
    f()
end
load("ItemMeter.lua")
load("ZeD_InvTip.lua")
load("ZeD_BoxSelect.lua")
load("ZeD_LootCard.lua")
local IT, BS = ZeD.InvTip, ZeD.BoxSelect

-- ---------------------------------------------------------------------------
-- TIP
-- ---------------------------------------------------------------------------
local list = { visible = true, isReallyVisible = function(s) return s.visible end, getMouseX = function() return 40 end,
               getAbsoluteX = function() return 100 end, getAbsoluteY = function() return 200 end }
-- the card's layer draws what was asked this frame
local function drawLayer() if IT._layer then IT._layer.render(IT._layer) end end
local axe, knife = { name = "Axe" }, { name = "Knife" }
-- (the game's tooltip is Alt's since the loot card: QA's checks below hold it down)
ALT = true
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

ALT = false

-- ---------------------------------------------------------------------------
-- CARD: without Alt, ZeD's loot card at once, by the pointer; the game's tooltip stays away
-- ---------------------------------------------------------------------------
local function item(t)
    local o = { _is = t.is or {} }
    for k, v in pairs(t) do
        if k ~= "is" then o[k] = function() return v end end
    end
    return o
end
local jacket = item({ is = { Clothing = true }, getName = "Leather Jacket", getActualWeight = 1.0, getEquippedWeight = 0.3,
                      getConditionMax = 10, getCondition = 4, getBodyLocation = "Jacket", getBiteDefense = 30, getScratchDefense = 60,
                      getWetness = 40 })
local worn = item({ is = { Clothing = true }, getBiteDefense = 40, getScratchDefense = 45 })
PLAYER.getWornItem = function(_, loc) return loc == "Jacket" and worn or nil end
BALLOONS = {}
frame()
IT.want(list, jacket, { x = 0, y = 20, w = 200, h = 16 })
drawLayer()
check("CARD: a row without Alt shows ZeD's card at once, on its own top layer", #BALLOONS == 1 and BALLOONS[1].side == "right"
      and IT._layer and IT._layer.onTop == true and IT._layer.inUI == true)
check("CARD: by the pointer, on the row (screen px)", BALLOONS[1] and BALLOONS[1].rect.x == 140 and BALLOONS[1].rect.y == 220 and BALLOONS[1].rect.h == 16, BALLOONS[1] and BALLOONS[1].rect.x)
-- the name drawn past the pointer: the tail goes after it (QA: the card covered the row's name)
BALLOONS = {}
IT.want(list, jacket, { x = 0, y = 20, w = 200, h = 16 })
IT.nameEnd(list, jacket, 90)
drawLayer()
check("CARD: past the row's name", BALLOONS[1] and BALLOONS[1].rect.x == 100 + 94, BALLOONS[1] and BALLOONS[1].rect.x)
BALLOONS = {}
IT.want(list, jacket, { x = 0, y = 20, w = 200, h = 16 })
IT.nameEnd(list, jacket, 10)
drawLayer()
check("CARD: a name ending before the pointer leaves it at the pointer", BALLOONS[1] and BALLOONS[1].rect.x == 140, BALLOONS[1] and BALLOONS[1].rect.x)
BALLOONS = {}
IT.want(list, jacket, { x = 300, y = 20, w = 52, h = 52 }, nil, true)
drawLayer()
check("CARD: a grid cell's card stands at the cell's right edge", BALLOONS[1] and BALLOONS[1].rect.x == 100 + 351, BALLOONS[1] and BALLOONS[1].rect.x)
-- the belt's boxes (punch list 135): the card above the box, its tail on the box's column, not by the pointer
BALLOONS = {}
IT.want(list, jacket, { x = 300, y = -40, w = 52, h = 92 }, nil, nil, "above")
drawLayer()
check("CARD: asked above a box (the belt's), it stands above, over the box's whole width", BALLOONS[1] and BALLOONS[1].side == "above"
      and BALLOONS[1].rect.x == 400 and BALLOONS[1].rect.w == 52 and BALLOONS[1].rect.y == 160 and BALLOONS[1].rect.h == 92,
      BALLOONS[1] and (BALLOONS[1].side .. " " .. BALLOONS[1].rect.x .. "," .. BALLOONS[1].rect.y))
BALLOONS = {}
IT.want(list, jacket, { x = 0, y = 20, w = 200, h = 16 })
drawLayer()
check("CARD: a row after it is by the pointer again", BALLOONS[1] and BALLOONS[1].side == "right" and BALLOONS[1].rect.w == 1)
BALLOONS = {}
frame(); frame()
drawLayer()
check("CARD: nothing asked for two frames: no card", #BALLOONS == 0)
IT.want(list, jacket, { x = 0, y = 20, w = 200, h = 16 })
drawLayer()
frame()
check("CARD: the game's tooltip stays away without Alt", not (IT._tip and IT._tip.inUI))
local c = BALLOONS[1] and BALLOONS[1].content
check("CARD: titled with the item's name", c and c.title == "Leather Jacket", c and c.title)
check("CARD: its body measured", c and c.body and c.body.w > 0 and c.body.h > 0 and type(c.body.draw) == "function")
local F = ZeD.LootCard.facts(jacket, PLAYER)
local function row(f, lab) for _, r in ipairs(f.rows) do if r[1] == lab then return r end end end
check("CARD: clothing's condition", F.cond and math.abs(F.cond - 0.4) < 1e-6, F.cond)
check("CARD: a wet tag", F.tags[1] and F.tags[1][1] == "UI_ZeD_Loot_Wet" and F.tags[1][2] == "warn")
local wr = row(F, "UI_ZeD_Weight")
check("CARD: the weight and what it weighs worn", wr and wr[2] == "1.0 kg" and wr[3] == "UI_ZeD_Loot_Worn(0.3)", wr and tostring(wr[3]))
local bite, scr = row(F, "IGUI_health_Bite"), row(F, "IGUI_health_Scratch")
check("CARD: bite against what is worn there: -10, red", bite and bite[2] == "30%" and bite[3] == "-10" and bite[4] == "bad", bite and tostring(bite[3]))
check("CARD: scratch against it: +15, green", scr and scr[2] == "60%" and scr[3] == "+15" and scr[4] == "good", scr and tostring(scr[3]))
local blade = item({ is = { HandWeapon = true }, getName = "Axe", getActualWeight = 3.0, getEquippedWeight = 0.9, getConditionMax = 13,
                     getCondition = 9, getMinDamage = 0.8, getMaxDamage = 2.0, hasSharpness = true, getSharpness = 0.8, getMaxRange = 1.2 })
local FB = ZeD.LootCard.facts(blade, PLAYER)
check("CARD: a weapon: what it weighs held", row(FB, "UI_ZeD_Weight")[3] == "UI_ZeD_Loot_Held(0.9)", tostring(row(FB, "UI_ZeD_Weight")[3]))
check("CARD: damage (a plain hyphen: the en dash isn't in the face), sharpness, reach", row(FB, "Tooltip_weapon_Damage") and row(FB, "Tooltip_weapon_Damage")[2] == "0.8 - 2.0"
      and row(FB, "UI_ZeD_Loot_Sharpness") and row(FB, "UI_ZeD_Loot_Sharpness")[2] == "80%" and row(FB, "UI_ZeD_Card_Reach"))
local broken = item({ is = { HandWeapon = true }, getName = "Kitchen Knife", isBroken = true, getActualWeight = 0.3, getConditionMax = 10, getCondition = 0 })
local FK = ZeD.LootCard.facts(broken, PLAYER)
check("CARD: broken says so first", FK.tags[1] and FK.tags[1][1] == "UI_ZeD_Loot_Broken" and FK.tags[1][2] == "bad" and FK.cond == 0)
-- LIQUID (punch lists 151 and 152; the director: "add the water amount in beta 11", then "At a quick glance that is
-- hovering over something, you're only going to be able to look at it and tell by the level ... It's not until you
-- inspect it ... where you see how much is in it"): a container's liquid on the card is a level bar under its name,
-- the fill bar's ten cells in the liquid blue, no number; Tainted a red tag; Unknown where the game hides the level;
-- lying on the floor, the liquid read from its world object (QA's Mac run on test 8: the floor's had none)
local FLUID_TAINT = false
ZeD.Fluid = {
    liquidsOf = function(fc) return fc._liquids and fc._liquids() or {} end,
    fluidLabel = function(l) if #l == 0 then return nil end if #l == 1 then return l[1].name end return "Fluid_Mixture" end,
    taintedShown = function() return FLUID_TAINT end,
}
local function bottle(fc, extra)
    local t = { is = {}, getName = "Water Bottle", getActualWeight = 1.0, getConditionMax = 10, getCondition = 10, getFluidContainer = fc }
    for k, v in pairs(extra or {}) do t[k] = v end
    return item(t)
end
local water = item({ getCapacity = 1.0, getAmount = 0.8, isEmpty = false, isHiddenAmount = false, _liquids = { { name = "Water", amt = 0.8 } } })
local FW = ZeD.LootCard.facts(bottle(water), PLAYER)
check("LIQUID: a bottle of water: a level bar under the liquid's name, 0.8 full, in the liquid blue",
      FW.amount and FW.amount.label == "Water" and math.abs(FW.amount.f - 0.8) < 1e-6 and FW.amount.color and FW.amount.color.name == "info",
      FW.amount and FW.amount.label)
check("LIQUID: no number for it on the card (the litres are the item card's)", row(FW, "Water") == nil)
check("LIQUID: and no condition bar for a bottle that never wears (the one bar is how full)", FW.cond == nil, FW.cond)
local mix = item({ getCapacity = 4.0, getAmount = 3.0, isEmpty = false, isHiddenAmount = false,
                   _liquids = { { name = "Water", amt = 2 }, { name = "Bleach", amt = 1 } } })
local FM = ZeD.LootCard.facts(bottle(mix), PLAYER)
check("LIQUID: several: the game's Mixture", FM.amount and FM.amount.label == "Fluid_Mixture" and math.abs(FM.amount.f - 0.75) < 1e-6)
FLUID_TAINT = true
local FT = ZeD.LootCard.facts(bottle(water), PLAYER)
local tainted = false
for _, t in ipairs(FT.tags) do if t[1] == "Tooltip_tainted" and t[2] == "bad" then tainted = true end end
check("LIQUID: tainted where the game's tooltip says so: a red tag", tainted)
FLUID_TAINT = false
local empty = item({ getCapacity = 1.5, getAmount = 0, isEmpty = true, isHiddenAmount = false })
local FE = ZeD.LootCard.facts(bottle(empty), PLAYER)
check("LIQUID: an empty one: Empty, the bar unlit", FE.amount and FE.amount.label == "Fluid_Empty" and FE.amount.f == 0)
local hid = item({ getCapacity = 0.5, getAmount = 0.3, isEmpty = false, isHiddenAmount = true, _liquids = { { name = "Pop", amt = 0.3 } } })
local FH = ZeD.LootCard.facts(bottle(hid), PLAYER)
check("LIQUID: the level hidden as the game hides it: Unknown, no bar", FH.amount == nil and row(FH, "Pop") and row(FH, "Pop")[2] == "Fluid_Unknown")
-- a saucepan of water is cookware (a weapon) that holds water: the one bar is how full; its damage stays
local pan = item({ is = { HandWeapon = true }, getName = "Saucepan", getActualWeight = 1.2, getConditionMax = 10, getCondition = 9,
                   getMinDamage = 0.4, getMaxDamage = 0.9, getFluidContainer = water })
local FP = ZeD.LootCard.facts(pan, PLAYER)
check("LIQUID: a saucepan of water: the water's bar (amount wins), its damage, no condition bar", FP.amount and FP.amount.label == "Water"
      and FP.cond == nil and row(FP, "Tooltip_weapon_Damage"))
-- on the floor: the item has no container of its own; its world object has the liquid
local floorItem = item({ is = {}, getName = "Water Bottle", getActualWeight = 1.0, getConditionMax = 10, getCondition = 10,
                         getWorldItem = item({ getFluidContainer = water }) })
local FF = ZeD.LootCard.facts(floorItem, PLAYER)
check("LIQUID: on the floor: the liquid from its world object (QA's test 8 fault)", FF.amount and FF.amount.label == "Water" and math.abs(FF.amount.f - 0.8) < 1e-6)
-- what runs down (a lighter, a battery): Remaining, a level bar in the accent
local lighter = item({ is = { DrainableComboItem = true }, getName = "Lighter", getActualWeight = 0.1, getConditionMax = 10, getCondition = 10,
                       getCurrentUsesFloat = 0.35 })
local FL2 = ZeD.LootCard.facts(lighter, PLAYER)
check("LIQUID: a lighter: Remaining as a level bar in a light neutral (the text's tone), no condition bar", FL2.amount and FL2.amount.label == "IGUI_invpanel_Remaining"
      and FL2.amount.color == ZeD.T.text and math.abs(FL2.amount.f - 0.35) < 1e-6 and FL2.cond == nil)
check("LIQUID: no fluid container, nothing running down: no level bar", ZeD.LootCard.facts(blade, PLAYER).amount == nil)
local content = ZeD.LootCard.content(bottle(water), PLAYER)
check("LIQUID: the card's body makes room for the level", content and content.body and content.body.h > 0)
do
    local fo = io.open(CDIR .. "ObjectCardFluid.lua", "rb"); local os2 = fo:read("*a"); fo:close()
    check("LIQUID: the water card shares its rules (ZeD.Fluid: L, liquidsOf, taintedShown, fluidLabel)",
          os2:find("ZeD.Fluid.L, ZeD.Fluid.liquidsOf, ZeD.Fluid.taintedShown, ZeD.Fluid.fluidLabel = L, liquidsOf, taintedShown, fluidLabel", 1, true) ~= nil)
end
local apple = item({ is = { Food = true }, getName = "Apple", getActualWeight = 0.2, isFresh = true, getHungerChange = -0.1, getThirstChange = -0.05, getConditionMax = 0 })
local FA = ZeD.LootCard.facts(apple, PLAYER)
check("CARD: food: fresh, no condition bar, hunger and thirst", FA.tags[1] and FA.tags[1][1] == "Tooltip_food_Fresh" and FA.cond == nil
      and row(FA, "Tooltip_food_Hunger")[2] == "+10" and row(FA, "Tooltip_food_Thirst")[2] == "+5")
local bagInv = { getCapacityWeight = function() return 5.4 end, getCapacity = function() return 18 end }
local bag = item({ is = { InventoryContainer = true }, getName = "Hiking Bag", getActualWeight = 6.2, getCapacity = 18, getInventory = bagInv, getWeightReduction = 70 })
local FG = ZeD.LootCard.facts(bag, PLAYER)
check("CARD: a bag: what it holds of what it can, its weight reduction", row(FG, "UI_ZeD_Loot_Holds") and row(FG, "UI_ZeD_Loot_Holds")[2] == "5.4 / 18"
      and row(FG, "UI_ZeD_Card_WeightReduce")[2] == "70%")
BALLOONS = {}
ALT = true
IT.want(list, jacket, { x = 0, y = 20, w = 200, h = 16 })
drawLayer()
check("CARD: with Alt, no card", #BALLOONS == 0)
frame()
check("CARD: with Alt, the game's tooltip", IT._tip and IT._tip.inUI and IT._tip.item == jacket)
ALT = false
frame(); frame()
BALLOONS = {}
WIN._drawerItem = jacket
IT.want(list, jacket, { x = 0, y = 20, w = 200, h = 16 })
drawLayer()
check("CARD: not while that item's card is open", #BALLOONS == 0)
WIN._drawerItem = nil

-- ---------------------------------------------------------------------------
-- QUEUE: the items waiting to move, from the player's timed action queue
-- ---------------------------------------------------------------------------
local moving, waiting, still = { n = 1 }, { n = 2 }, { n = 3 }
local QUEUE = { queue = {} }
ISTimedActionQueue = { getTimedActionQueue = function() return QUEUE end }
frame()
check("QUEUE: nothing waits: nil", IT.queued(list, moving) == nil)
QUEUE.queue = { { Type = "ISInventoryTransferAction", item = moving, action = { getJobDelta = function() return 0.4 end } },
                { Type = "ISInventoryTransferAction", item = waiting } }
frame()
check("QUEUE: the one moving now, how far", IT.queued(list, moving) == 0.4, IT.queued(list, moving))
check("QUEUE: one waiting its turn: 0", IT.queued(list, waiting) == 0)
check("QUEUE: one not in the queue: nil", IT.queued(list, still) == nil)
QUEUE.queue = {}
frame()
check("QUEUE: once moved, nil again", IT.queued(list, moving) == nil)

-- ---------------------------------------------------------------------------
-- SELECT ALL: a double-click on empty space (Ctrl+A walked the character: QA's Mac run)
-- ---------------------------------------------------------------------------
do
    local c = {}
    NOW = 5000
    check("SELECT ALL: one press on empty space is no double-click", BS.doubleEmpty(c, 10, 300) == false)
    NOW = 5250
    check("SELECT ALL: a second press there within 400 ms is", BS.doubleEmpty(c, 12, 301) == true)
    NOW = 5300
    check("SELECT ALL: a third press starts over", BS.doubleEmpty(c, 12, 301) == false)
    NOW = 5900
    check("SELECT ALL: too slow is two single presses", BS.doubleEmpty(c, 12, 301) == false)
    NOW = 6000
    check("SELECT ALL: too far apart is two single presses", BS.doubleEmpty(c, 40, 301) == false)
    check("SELECT ALL: no Ctrl+A key any more (the A walks)", BS.selectAllUnderPointer == nil)
end

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
local _, w1 = ir:gsub("ZeD%.InvTip%.want%(self, item, r%)", "")
local _, w2 = ir:gsub("ZeD%.InvTip%.want%(self, item, r, count, true%)", "")
check("WIRED: a row hands the card its name's end", ir:find("ZeD.InvTip.nameEnd(self, item, xOff + afterName)", 1, true) ~= nil)
check("WIRED: list rows and grid cells ask for the card, with their place", w1 == 1 and w2 == 1, w1 .. "/" .. w2)
local _, qm = ir:gsub("[^n]%squeueMark%(self, item,", "")   -- (the calls, not the function's own line)
check("WIRED: rows and cells show the queue", qm == 3, qm)
check("WIRED: the help line names Alt", ir:find("UI_ZeD_Inv_RowHelpLoot", 1, true) ~= nil)
check("WIRED: a drop on the Character window's main inventory button lands there", ir:find('elseif zid == "main_toggle" then', 1, true) ~= nil)
check("WIRED: the grid's name hint gives way to it", ir:find("ZeD.InvTip.wantedBy(self, hc.key)", 1, true) ~= nil)
for _, w in ipairs({ "ZeD_CharacterWindow.lua", "ZeD_WorldWindow.lua" }) do
    local s = read(w)
    check("WIRED: " .. w .. " starts the box on empty space", s:find("ZeD.BoxSelect.start(self, x, y, bSel", 1, true) ~= nil)
    local _, moves = s:gsub("ZeD%.BoxSelect%.move%(self, self:getMouseX%(%), self:getMouseY%(%)%)", "")
    check("WIRED: " .. w .. " moves it inside and outside", moves == 2, moves)
    local _, ends = s:gsub("ZeD%.BoxSelect%.finish%(self%)", "")
    check("WIRED: " .. w .. " finishes it on either release", ends == 2, ends)
    local _, picks = s:gsub("self%._padMarks = true   %-%- %(picking rows", "")
    check("WIRED: " .. w .. " Ctrl- and Shift-picks keep the card shut", picks == 2, picks)
    check("WIRED: " .. w .. " selects all on a double-click on empty space", s:find("content.zedSelectAll = function(self)", 1, true) ~= nil
          and s:find("ZeD.BoxSelect.doubleEmpty(self, x, y) and self.zedSelectAll", 1, true) ~= nil)
    check("WIRED: " .. w .. " draws it after the rows", s:find("content._onRender = function(self) if self._box and ZeD.BoxSelect then ZeD.BoxSelect.draw(self) end end", 1, true) ~= nil)
end

print("fast_loot_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
