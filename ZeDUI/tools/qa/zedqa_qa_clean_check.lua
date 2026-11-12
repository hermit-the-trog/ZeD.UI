-- ZeDUI/tools/qa/zedqa_qa_clean_check.lua  (Nov 11 2026, QA): is the QA save clean after the Animals runs? Counts the animals within 60 squares of the QA home, the livestock zones named "QA ...", and what the character carries (Bucket, SheepShears, Steak, Carrots). Read only. grep "ZEDQA qcc".
local function say(s) print("ZEDQA qcc " .. tostring(s)) end
local p = getPlayer()
local n = 0
local function later()
    n = n + 1
    if n < 60 then return end
    Events.OnTick.Remove(later)
    local okAll, err = pcall(function()
    local cell = getCell()
    local list = cell:getAnimals()
    local near, far = 0, 0
    for k = 0, list:size() - 1 do
        local o = list:get(k)
        do
            if math.abs(o:getX() - 925) <= 60 and math.abs(o:getY() - 13040) <= 60 then near = near + 1 else far = far + 1 end
        end
    end
    say("animals within 60 squares of the QA home: " .. near .. " (elsewhere loaded: " .. far .. ")")
    local zones = {}
    pcall(function()
        local all = DesignationZoneAnimal.getAllZones()
        for k = 0, all:size() - 1 do zones[#zones + 1] = tostring(all:get(k):getName()) end
    end)
    say("livestock zones: " .. #zones .. " " .. table.concat(zones, ", "))
    local inv = p:getInventory()
    for _, ft in ipairs({ "Base.Bucket", "Base.SheepShears", "Base.Steak", "Base.Carrots", "Base.Bag_Schoolbag" }) do
        local l = inv:getAllTypeRecurse(ft)
        say("carries " .. ft .. ": " .. l:size())
    end
    end)
    if not okAll then say("ERR " .. tostring(err)) end
    say("DONE")
end
Events.OnTick.Add(later)
say("start")
