-- ZeDUI/tools/qa/gallery_cinema_angel_close_mode.lua  (Nov 11 2026): gallery_cinema_angel.lua's closing break (CANG_MODE),
-- CANG_GUESTS other players to wait for. Run on the admin client just before it. grep "ZEDQA cangm".
CANG_MODE = "close"
CANG_GUESTS = CANG_GUESTS_SET or 3
print("ZEDQA cangm mode close, " .. tostring(CANG_GUESTS) .. " guests")
local n = 0
local function f() n = n + 1; if n < 5 then return end; Events.OnTick.Remove(f); print("ZEDQA cangm DONE") end
Events.OnTick.Add(f)