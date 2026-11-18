-- ZeDUI/tools/qa/gallery_v1_a_end.lua  (Nov 17 2026, QA): last but one in gallery_v1_a_zed.txt / gallery_v1_a_van.txt,
-- after gallery_story_teardown.lua (which sets the skills back, so the floating XP text stays muted through it). Puts
-- back what gallery_v1_a_common.lua left for the end: the game's three halo-text calls (HaloTextHelper) and any error
-- box it hid; clears G1. grep "ZEDQA g1e".
local function say(s) print("ZEDQA g1e " .. tostring(s)) end
if G1 then
    local HT = HaloTextHelper
    if HT and G1.halo then
        HT.addTextWithArrow, HT.addGoodText, HT.addBadText = G1.halo.arrow, G1.halo.good, G1.halo.bad
        say("the floating XP text is back")
    end
    G1.halo = nil
    if G1.showErrors then G1.showErrors() end
    if G1.showWatermark then G1.showWatermark(); say("the game's build line shown again") end
    local ec = "?"
    pcall(function() ec = tostring(getLuaDebuggerErrorCount()) end)
    say("errors logged in this game: " .. ec)
    G1 = nil
else
    say("nothing to put back (no G1)")
end
local k = { n = 0 }
local function later()
    k.n = k.n + 1
    if k.n < 10 then return end
    Events.OnTick.Remove(later)
    say("DONE")
end
Events.OnTick.Add(later)
