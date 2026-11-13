-- ZeDUI/tools/qa/vehicle_tab_strip_sim.lua  (Nov 13 2026, Build; QA's beta 12 release pass blocker)
-- The Vehicle tab threw every frame once a car was in view: MT.vehicleTabItems (new with the per-vehicle tab strip)
-- handed vehicleName the list's entries ({ vehicle = v, id, dist }, from MT.buildVehicles) in place of the vehicles.
-- With no game running, vehicleName, mechType and MT.vehicleTabItems (cut out of the real MechanicsTab.lua) run on
-- entries shaped like MT.buildVehicles' with stub vehicles. It checks:
--   no error on real entries; each tab is the car's name; two of one name carry their place; the help line adds the type;
--   a shorter list drops the old tabs.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/vehicle_tab_strip_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]vehicle_tab_strip_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local f = io.open(ROOT .. "42/media/lua/client/ZeD/MechanicsTab.lua", "rb"); local src = f:read("*a"):gsub("\r\n", "\n"); f:close()
local ta = src:find("local function txt(key, fallback)", 1, true)
local tb = ta and src:find("\nend\n", ta, true)
local va = src:find("local function vehicleName(v)", 1, true)
local vb = va and src:find("local function mechType(v)", va, true)
local vc = vb and src:find("\nend\n", vb, true)
local ia = src:find("local _vehTabItems = {}", 1, true)
local ib = ia and src:find("\nend\n", src:find("function MT.vehicleTabItems", ia, true), true)
check("the pieces are found", ta and tb and va and vb and vc and ia and ib)
if not (ta and tb and va and vb and vc and ia and ib) then print("vehicle_tab_strip_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end
local NAMES = { Base_CarNormal = "Chevalier Nyala", Base_Van = "Franklin Van" }
getTextOrNull = function(k) return NAMES[(k:gsub("^IGUI_VehicleName", "Base_"))] or (k == "IGUI_VehicleType_1" and "Standard" or nil) end
getText = function(k, a) return "Burnt " .. tostring(a) end
local function car(model, mt)
    local sc = { getCarModelName = function() return nil end, getName = function() return model end,
                 getMechanicType = function() return mt end }
    return { getScript = function() return sc end }
end
local chunk = "local MT = ...\n" .. src:sub(ta, tb + 4) .. src:sub(va, vc + 4) .. src:sub(ia, ib + 4) .. "return MT\n"
local MT = assert(loadstring(chunk))({})
local list = { { vehicle = car("CarNormal", 1), id = 1, dist = 2 }, { vehicle = car("Van", 2), id = 2, dist = 3 },
               { vehicle = car("CarNormal", 1), id = 3, dist = 4 } }
local ok, items = pcall(MT.vehicleTabItems, list)
check("real entries draw without an error", ok, not ok and items or nil)
if ok then
    check("three tabs", #items == 3, #items)
    check("a car's tab is its name", items[2].label == "Franklin Van", items[2].label)
    check("two of one name carry their place", items[1].label == "Chevalier Nyala (1)" and items[3].label == "Chevalier Nyala (3)",
          tostring(items[1].label) .. " / " .. tostring(items[3].label))
    check("the help line adds the type", items[1].help == "Chevalier Nyala | Standard", items[1].help)
    local ok2, few = pcall(MT.vehicleTabItems, { list[2] })
    check("a shorter list drops the old tabs", ok2 and #few == 1 and few[1].label == "Franklin Van", ok2 and #few or few)
    local ok3, none = pcall(MT.vehicleTabItems, nil)
    check("no list, no tabs", ok3 and #none == 0)
end
print("vehicle_tab_strip_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
