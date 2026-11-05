-- ZeDUI/tools/qa/zedqa_pin_windows.lua  (Nov 4 2026, QA): pins the Character and World windows on the QA character
-- (0.3.0-beta3a rolls unpinned windows up when the pointer leaves; the suites expect them open). grep "ZEDQA pnw".
-- The tag is pnw the first time in a game session, then pnw2, pnw3 ... (a manifest's tags are unique).
ZEDQA_PNW_N = (ZEDQA_PNW_N or 0) + 1
local tag = (ZEDQA_PNW_N == 1) and "pnw" or ("pnw" .. ZEDQA_PNW_N)
local md = getPlayer():getModData()
md.ZeD_WinPinned = { char = true, world = true }
for _, get in ipairs({ ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow, ZeD_WorldWindow and ZeD_WorldWindow.getWindow }) do
    local w = get and get()
    if w then if w.setPinned then w:setPinned(true) else w.pinned = true end; if w.windowShaded then w:setWindowShaded(false) end end
end
print("ZEDQA " .. tag .. " pinned both windows")
local n = 0
local function t() n = n + 1; if n == 20 then Events.OnTick.Remove(t); print("ZEDQA " .. tag .. " DONE") end end
Events.OnTick.Add(t)
