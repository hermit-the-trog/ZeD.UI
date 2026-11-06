-- ZeDUI/tools/qa/zedqa_modlist.lua  (Nov 6 2026, QA): the mods the game has on, as the save loaded them. grep "ZEDQA mls".
local list = getActivatedMods and getActivatedMods()
local out = {}
if list then for i = 0, list:size() - 1 do out[#out + 1] = tostring(list:get(i)) end end
print("ZEDQA mls on: " .. table.concat(out, ", "))
local n = 0; local function t() n = n + 1; if n == 30 then Events.OnTick.Remove(t); print("ZEDQA mls DONE") end end; Events.OnTick.Add(t)
