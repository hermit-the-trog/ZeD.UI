-- ZeDUI/tools/qa/zedqa_pin_windows.lua  (Nov 4 2026, QA): pins the Character and World windows on the QA character
-- (0.3.0-beta3a rolls unpinned windows up when the pointer leaves; the suites expect them open). grep "ZEDQA pnw".
local md = getPlayer():getModData()
md.ZeD_WinPinned = { char = true, world = true }
for _, get in ipairs({ ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow, ZeD_WorldWindow and ZeD_WorldWindow.getWindow }) do
    local w = get and get()
    if w then w.pinned = true; if w.windowShaded then w:setWindowShaded(false) end end
end
print("ZEDQA pnw pinned both windows")
local n = 0
local function t() n = n + 1; if n == 20 then Events.OnTick.Remove(t); print("ZEDQA pnw DONE") end end
Events.OnTick.Add(t)
