-- ZeDUI/tools/qa/mp_hand_after.lua  (Nov 5 2026, QA; multiplayer): after a rejoin, what is in the hands of the character
-- whose hammer mp_actions.lua emptied ZeD's way (the server's state, sent back on join). grep "ZEDQA mph".
local p = getPlayer()
local h1, h2 = p:getPrimaryHandItem(), p:getSecondaryHandItem()
print("ZEDQA mph after the rejoin: main hand " .. tostring(h1 and h1:getFullType()) .. ", off hand " .. tostring(h2 and h2:getFullType()))
local n = 0
local function t() n = n + 1; if n == 20 then Events.OnTick.Remove(t); print("ZEDQA mph DONE") end end
Events.OnTick.Add(t)
