-- ZeDUI/tools/qa/zedqa_thai_bytes.lua  (Nov 3 2026, QA; punch list 83): what Kahlua's string functions return on the game's
-- own Thai text (Foraging's topic), for the window's cluster breaks. grep "ZEDQA thb".
local function say(s) print("ZEDQA thb " .. tostring(s)) end
local s
for _, t in ipairs(select(3, ZeD.Guide.readTopicList(false)) or {}) do if t.titleKey == "SurvivalGuide_foraging_title" then s = t.text end end
s = tostring(s or "")
say("text length " .. #s)
local parts = {}
for i = 1, math.min(#s, 24) do parts[#parts + 1] = tostring(string.byte(s, i)) end
say("first bytes: " .. table.concat(parts, " "))
local hi = 0
for i = 1, #s do local b = string.byte(s, i); if b and b > hi then hi = b end end
say("highest string.byte in the text: " .. hi .. " (Thai code points are 3585-3675)")
say("DONE")
