-- sets the one car for zedqa_dash_keys_edge (Nov 8 QA)
ZeD_QA_DKE_ONLY = { dashelite = true }
local n = 0
local function t() n = n + 1; if n == 5 then Events.OnTick.Remove(t); print("ZEDQA dkeo DONE") end end
Events.OnTick.Add(t)
