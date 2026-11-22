-- ZeDUI/tools/qa/vx_french_units.lua  (Nov 21 2026, QA): the in-game proof of B7-7 (QA batch 7, fixed in b7809b732):
-- in French the game's fleet cars put the service after the model ("Dash Bulldriver de Pompiers", "Chevalier Nyala de
-- garde forestier"), and the dash's unit line read the maker ("DASH - UNITE nn", "CHEVALIER - UNITE nn") where English
-- shows the service. Run with the game in French (lang_run.ps1 -Lang FR -Manifest vx_french_units.txt), after
-- rt_kit.lua. grep "ZEDQA vx_fr".
--
-- No car is spawned: the dash's own two steps (ZeD.Dashboard._designFor and _badges, exposed for QA probes) are asked
-- with a stand-in car that answers getScript and getId only, so the name comes from the game's own French text
-- (IGUI_VehicleName<model>) exactly as for a real car. For each of the game's fleet cars named in French, the unit line
-- must lead with the service and never with a maker. (The director, Nov 21 2026, fd4981a9f: the service is painted in
-- French too, the word the car's own name uses: POMPIERS, FORESTIER, POLICE, SHERIFF, AMBULANCE, TAXI; the English
-- service still picks the unit word, CAMION for a fire engine.) The English names of the same cars are not in play
-- here; vx_vehicles.lua covers English. Nothing is changed and nothing is written.

if not RT then
    print("ZEDQA vx_fr ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vx_fr VERDICT FAIL 1")
    print("ZEDQA vx_fr DONE")
    return
end

local Q = RT.make("vx_fr")
Q.maxMs = 60000
local S = {}

-- the game's fleet cars, by model, and the service word (as the car's French name says it) their unit line must lead with
S.CARS = {
    { "CarLightsPolice", "POLICE" }, { "CarLightsRanger", "FORESTIER" }, { "PickUpTruckLightsFire", "POMPIERS" },
    { "PickUpTruckLightsRanger", "FORESTIER" }, { "PickUpVanLightsFire", "POMPIERS" }, { "PickUpVanLightsPolice", "POLICE" },
    { "PickUpVanLightsRanger", "FORESTIER" }, { "CarLightsBulletinSheriff", "SHERIFF" }, { "CarLightsMuldraughPolice", "POLICE" },
    { "ModernCarLightsCityLouisvillePD", "POLICE" }, { "ModernCarLightsWestPoint", "POLICE" }, { "VanAmbulance", "AMBULANCE" },
    { "CarTaxi", "TAXI" },
}
S.MAKERS = { "CHEVALIER", "DASH", "FRANKLIN", "MASTERSON", "MERCIA" }

-- a stand-in car: the dash reads its script's model name and its id, nothing else
function S.fake(model)
    local sc = {}
    function sc.getCarModelName() return model end
    function sc.getName() return model end
    local v = {}
    function v.getScript() return sc end
    function v.getId() return 7 end
    return v
end

Q.step(2, function()
    local D = ZeD and ZeD.Dashboard
    Q.check(D ~= nil and D._designFor ~= nil and D._badges ~= nil, "the dash's design and badge steps are there for the probe", "missing")
    if not (D and D._designFor and D._badges) then return end
    local lang = "?"
    pcall(function() lang = tostring(Translator.getLanguage()) end)
    local police = tostring(getTextOrNull("IGUI_VehicleNameCarLightsPolice"))
    Q.say("the game's language: " .. lang .. "; the police car is \"" .. police .. "\"; ZeD's unit word: " .. tostring(ZeD.tr("UI_ZeD_Dash_UnitUnit", "X", "00")))
    Q.check(police == "Chevalier Nyala de Police", "the game runs in French for this proof (the police car's French name)", police)
    for _, c in ipairs(S.CARS) do
        local model, want = c[1], c[2]
        local name = getTextOrNull("IGUI_VehicleName" .. model)
        if not name then
            Q.skip(model, "the game has no French name for this car")
        else
            local ok, b = pcall(function()
                local des, _, own = D._designFor("Base." .. model)
                return D._badges(des, S.fake(model), "Base." .. model, own)
            end)
            local unit = (ok and type(b) == "table") and tostring(b.unit) or ("ERROR " .. tostring(b))
            local lead = unit:match("^(%S+)") or ""
            local maker = false
            for _, m in ipairs(S.MAKERS) do if lead == m then maker = true end end
            Q.check(ok and lead == want and not maker, model .. " (\"" .. tostring(name) .. "\"): the unit line leads with " .. want,
                "\"" .. unit .. "\"")
        end
    end
end)
Q.start()
