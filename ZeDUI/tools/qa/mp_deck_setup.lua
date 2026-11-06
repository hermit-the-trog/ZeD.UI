-- ZeDUI/tools/qa/mp_deck_setup.lua  (Nov 5 2026, QA): Large text for the multiplayer surfaces at the Deck; put back by mp_deck_end.lua.
ZeD.applyTheme(nil, nil, "large")
print("ZEDQA mdk Large text on")
local n = 0
local function t() n = n + 1; if n == 60 then Events.OnTick.Remove(t); print("ZEDQA mdk DONE") end end
Events.OnTick.Add(t)
