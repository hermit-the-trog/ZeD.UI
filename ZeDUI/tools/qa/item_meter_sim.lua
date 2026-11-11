-- ZeDUI/tools/qa/item_meter_sim.lua  (Nov 11 2026, Build; punch list 152, the COND / AMT column)
-- The director, Nov 11 2026: "condition is not always condition. Sometimes it's how much is in something"; rulings:
-- one bar an item, amount wins; hovering shows the level, the item card the exact litres; liquids and use-ups; a
-- condition only for what wears. Then: the column's heading left aligned, only Weight (a number) at the right.
-- With no game running, the real ItemMeter.lua and ItemFactsPanel.lua on stubs:
--   METER   ItemMeter.of: a liquid container its fill (on the floor, from its world object: QA's test 8), a use-up
--           what is left, a weapon / clothing / anything below full its condition, the rest nothing; a hidden level
--           "hidden"; the sort key (no bar below an empty one)
--   FACTS   the item card's Liquid Facts: first in the registry; each liquid and its litres, the total in the
--           capacity, Tainted, Empty, Unknown; a saucepan's combat facts after its water; a floor bottle's too
--   COLUMN  InventoryRenderer: the row and the grid cell draw ItemMeter's bar; the heading has no right edge (left
--           aligned) while Weight keeps its; the column is as wide as its heading needs, up to 90 units
-- Run from the repo root:  lua51 ZeDUI/tools/qa/item_meter_sim.lua
-- It prints FAIL lines and a last line "item_meter_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]item_meter_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local CDIR = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end

function require() end
instanceof = function(o, cls) return type(o) == "table" and o._is ~= nil and o._is[cls] == true end
getTextOrNull = function(k) return k end
getText = function(k) return k end
ZeD = { T = { info = { name = "info" } }, tr = function(k) return k end }
local function item(t)
    local o = { _is = t.is or {} }
    for k, v in pairs(t) do if k ~= "is" then o[k] = function() return v end end end
    return o
end
assert(loadfile(CDIR .. "ItemMeter.lua"))()
assert(loadfile(CDIR .. "ItemFactsPanel.lua"))()
local IM, FP = ZeD.ItemMeter, ZeD.ItemFactsPanel

-- METER
local water = item({ getCapacity = 1.0, getAmount = 0.8, isEmpty = false, isHiddenAmount = false })
local function kf(it) local k, f = IM.of(it); return k, f end
local k, f = kf(item({ getConditionMax = 10, getCondition = 10, getFluidContainer = water }))
check("METER a water bottle: how full, not its condition", k == "fluid" and math.abs(f - 0.8) < 1e-6, k)
k, f = kf(item({ getConditionMax = 10, getCondition = 10, getWorldItem = item({ getFluidContainer = water }) }))
check("METER a water bottle on the floor: its world object's liquid (QA's test 8)", k == "fluid" and math.abs(f - 0.8) < 1e-6, k)
k, f = kf(item({ is = { HandWeapon = true }, getConditionMax = 10, getCondition = 3, getFluidContainer = water }))
check("METER a saucepan of water (a weapon too): how full wins", k == "fluid", k)
k = kf(item({ getFluidContainer = item({ getCapacity = 0.5, getAmount = 0.3, isHiddenAmount = true }) }))
check("METER a level the game hides: hidden (no bar)", k == "hidden", k)
k, f = kf(item({ is = { DrainableComboItem = true }, getConditionMax = 10, getCondition = 10, getCurrentUsesFloat = 0.4 }))
check("METER a lighter: what is left", k == "uses" and math.abs(f - 0.4) < 1e-6, k)
k, f = kf(item({ is = { HandWeapon = true }, getConditionMax = 13, getCondition = 13 }))
check("METER an axe at full: its condition (a weapon wears)", k == "cond" and f == 1, k)
k, f = kf(item({ is = { Clothing = true }, getConditionMax = 10, getCondition = 4 }))
check("METER a jacket: its condition", k == "cond" and math.abs(f - 0.4) < 1e-6, k)
k, f = kf(item({ getConditionMax = 100, getCondition = 60 }))
check("METER a part below full (a vehicle part, say): its condition", k == "cond" and math.abs(f - 0.6) < 1e-6, k)
k = kf(item({ getConditionMax = 10, getCondition = 10 }))
check("METER a can of beans at full: no bar (it never wears)", k == nil, k)
check("METER the sort key: no bar below an empty one", IM.sortKey(item({ getConditionMax = 10, getCondition = 10 })) == -1
      and IM.sortKey(item({ getFluidContainer = item({ getCapacity = 1, getAmount = 0, isEmpty = true }) })) == 0)
local fc1, gr1 = IM.style("cond"); local fc2, gr2 = IM.style("fluid"); local fc3, gr3 = IM.style("uses")
check("METER the bars: condition the status five, a liquid the fill ten in blue, a use-up the fill ten in the accent",
      fc1 == nil and gr1 == true and fc2 and fc2.name == "info" and gr2 == false and fc3 == nil and gr3 == false)

-- FACTS
check("FACTS Liquid Facts is first in the item card's list", FP._registry[1] and FP._registry[1].key == "liquid", FP._registry[1] and FP._registry[1].key)
local TAINT = false
ZeD.Fluid = {
    L = function(v) return string.format("%.2f L", v) end,
    liquidsOf = function(fc) return fc._liquids and fc._liquids() or {} end,
    taintedShown = function() return TAINT end,
}
local function rows(panel)
    local out = {}
    for _, g in ipairs(panel and panel.groups or {}) do for _, r in ipairs(g.rows or {}) do out[#out + 1] = r end end
    return out
end
local function find(panel, label) for _, r in ipairs(rows(panel)) do if r.label == label then return r end end end
local wb = item({ getFluidContainer = item({ getCapacity = 1.0, getAmount = 0.8, isEmpty = false, isHiddenAmount = false,
                                             _liquids = { { name = "Water", amt = 0.8 } } }) })
local P = FP.factsFor(wb)
check("FACTS a water bottle's card: Liquid Facts", P and P._key == "liquid" and P.title == "UI_ZeD_Card_FactsLiquid", P and P._key)
check("FACTS the water and its litres", find(P, "Water") and find(P, "Water").value == "0.80 L")
check("FACTS the total in the capacity", find(P, "UI_ZeD_Card_Amount") and find(P, "UI_ZeD_Card_Amount").value == "0.80 L / 1.00 L",
      find(P, "UI_ZeD_Card_Amount") and find(P, "UI_ZeD_Card_Amount").value)
local mixb = item({ getFluidContainer = item({ getCapacity = 4.0, getAmount = 3.0, isEmpty = false, isHiddenAmount = false,
                                               _liquids = { { name = "Water", amt = 2 }, { name = "Bleach", amt = 1, poison = true } } }) })
TAINT = true
local PM = FP.factsFor(mixb)
check("FACTS a mixture: each liquid, largest first, the poison red where the game says Tainted",
      rows(PM)[1].label == "Water" and rows(PM)[2].label == "Bleach" and rows(PM)[2].valueClass == "bad" and find(PM, "Tooltip_tainted"))
TAINT = false
local PE = FP.factsFor(item({ getFluidContainer = item({ getCapacity = 1.5, getAmount = 0, isEmpty = true, isHiddenAmount = false }) }))
check("FACTS an empty one: Empty, and 0 of its capacity", find(PE, "Fluid_Empty") and find(PE, "UI_ZeD_Card_Amount").value == "0.00 L / 1.50 L")
local PH = FP.factsFor(item({ getFluidContainer = item({ getCapacity = 0.5, getAmount = 0.3, isEmpty = false, isHiddenAmount = true,
                                                         _liquids = { { name = "Pop", amt = 0.3 } } }) }))
check("FACTS the level hidden: Unknown, no litres", find(PH, "UI_ZeD_Card_Amount").value == "Fluid_Unknown" and find(PH, "Pop").value == "?")
local pan = item({ is = { HandWeapon = true }, getMinDamage = 0.4, getMaxDamage = 0.9, getConditionMax = 10, getCondition = 9,
                   getFluidContainer = item({ getCapacity = 0.6, getAmount = 0.42, isEmpty = false, isHiddenAmount = false,
                                              _liquids = { { name = "Water", amt = 0.42 } } }) })
local PP = FP.factsFor(pan)
local combat = FP.CombatFacts(pan)
check("FACTS a saucepan of water: its water, then its combat facts", PP and PP._key == "liquid" and find(PP, "Water")
      and combat and #PP.groups == 2 + #combat.groups)
local PF = FP.factsFor(item({ getWorldItem = item({ getFluidContainer = item({ getCapacity = 1.0, getAmount = 0.5, isEmpty = false,
                                                     isHiddenAmount = false, _liquids = { { name = "Water", amt = 0.5 } } }) }) }))
check("FACTS a bottle on the floor: its liquid from the world object", PF and PF._key == "liquid" and find(PF, "Water"))
check("FACTS no liquid container: not Liquid Facts", FP.LiquidFacts(item({ is = { HandWeapon = true } })) == nil)

-- COLUMN
local fr = io.open(CDIR .. "InventoryRenderer.lua", "rb"); local src = fr:read("*a"); fr:close()
local condDef = src:match('colDefs%[#colDefs %+ 1%] = {ZeD%.tr%("UI_ZeD_Inv_ColCond"%)[^\n]*')
check("COLUMN the heading has no right edge: left aligned (the director)", condDef and not condDef:find("condX %+ condColW %- T%.px%(2%)"), condDef)
local wtDef = src:match('colDefs%[#colDefs %+ 1%] = {ZeD%.tr%("UI_ZeD_Inv_ColWt"%)[^\n]*')
check("COLUMN Weight, a number, keeps its right edge", wtDef and wtDef:find("wtX + wtColW - padX}", 1, true), wtDef)
check("COLUMN the column as wide as its heading needs, up to 90 units",
      src:find('MeasureStringX(T.fontF5, ZeD.tr("UI_ZeD_Inv_ColCond")) + padX * 2), math.floor(90 * scale))', 1, true) ~= nil)
local rowFn = src:match("local function rowCondition%(.-\nend")
local cellFn = src:match("local function drawCellCondition%(.-\nend")
check("COLUMN a row draws ItemMeter's bar", rowFn and rowFn:find("IM.of(item)", 1, true) and rowFn:find("IM.style(kind)", 1, true))
check("COLUMN a grid cell too", cellFn and cellFn:find("IM.of(item)", 1, true))
check("COLUMN the sort follows the bar", src:find("return ZeD.ItemMeter.sortKey(item)", 1, true) ~= nil)
-- every language has the heading, the panel's title and Amount
local LANGS = { "AR", "CA", "CH", "CN", "CS", "DA", "DE", "EN", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT", "JP",
                "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
local miss = ""
for _, L in ipairs(LANGS) do
    local fh = io.open(ROOT .. "42/media/lua/shared/Translate/" .. L .. "/UI.json", "rb"); local t = fh and fh:read("*a") or ""; if fh then fh:close() end
    for _, key in ipairs({ "UI_ZeD_Card_FactsLiquid", "UI_ZeD_Card_Amount" }) do if not t:find('"' .. key .. '"', 1, true) then miss = miss .. L .. ":" .. key .. " " end end
    local h = t:match('"UI_ZeD_Inv_ColCond": "([^"]*)"')
    if not (h and h:find("/", 1, true)) then miss = miss .. L .. ":heading " end
end
check("COLUMN the heading reads condition / amount, and the card's words, in all 28 languages", miss == "", miss)

print("item_meter_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
