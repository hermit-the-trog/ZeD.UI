-- ZeDUI/tools/qa/mp_deck_end.lua  (Nov 5 2026, QA): the text size back after mp_surfaces_shots.lua at the Deck.
ZeD.applyTheme(nil, nil, "small")
local n = 0
local function t() n = n + 1; if n == 60 then Events.OnTick.Remove(t); print("ZEDQA mde DONE") end end
Events.OnTick.Add(t)
