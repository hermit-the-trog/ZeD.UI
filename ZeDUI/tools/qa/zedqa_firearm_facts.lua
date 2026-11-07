-- ZeDUI/tools/qa/zedqa_firearm_facts.lua  (Nov 7 2026, QA; punch list 101): ZeD.itemFacts on firearms, as the recipe preview card and the item card outside the
-- drawer call it. Beta 6a throws in formatFirearm (getAmmoType returns an AmmoType object). grep "ZEDQA ff".
local function say(s) print("ZEDQA ff " .. tostring(s)) end
local bad = 0
for _, ft in ipairs({ "Base.Pistol", "Base.Pistol2", "Base.Revolver", "Base.Shotgun", "Base.AssaultRifle", "Base.HuntingRifle", "Base.BaseballBat" }) do
    local it = instanceItem(ft)
    if it then
        local ok, stats = pcall(ZeD.itemFacts, it)
        local at
        if ok and type(stats) == "table" then for _, r in ipairs(stats) do if r.label == "Ammo type" then at = r.value end end end
        if not ok then bad = bad + 1 end
        say((ok and "PASS " or "FAIL ") .. ft .. (ok and (" ammo type " .. tostring(at)) or (": " .. tostring(stats))))
    else
        say("no item " .. ft)
    end
end
say(bad .. " failed")
say("DONE")
