-- gallery_nov1_only_furniture.lua (Nov 1 2026, QA): only the furniture section of gallery_nov1_lot.lua.
NOV1_ONLY = { furniture = true }
print("ZEDQA n1of sections: furniture")
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); print("ZEDQA n1of DONE") end
Events.OnTick.Add(later)
