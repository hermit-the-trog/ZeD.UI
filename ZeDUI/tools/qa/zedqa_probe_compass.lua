-- ZeDUI/tools/qa/zedqa_probe_compass.lua  (Nov 1 2026, QA; punch list 43)
-- The Foraging finds' compass letter: a find is staged at a known offset from the character through ZeD's own
-- discovery hook (ISSearchManager.spotIcon, wrapped by ForagingTab.lua), with a stand-in search manager so vanilla's
-- part of the hook does nothing, and the letter the list would draw is read from the find queue. Eight headings:
-- east E, north N, west W, south S and the four between. PZ's Y grows southward. The queue is put back after.
-- grep "ZEDQA cmp"; PASS/FAIL lines, then DONE a few ticks later.
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA cmp " .. tostring(s)) end
local FT = ZeD and ZeD.ForagingTab
if not (FT and FT._findQueues) then say("FAIL no ZeD.ForagingTab._findQueues"); say("DONE"); return end
local was = FT._findQueues[pn]
FT._findQueues[pn] = {}
local fakeMgr = { player = pn, character = p, seenIcons = {}, xpIcons = {}, resetForceFindSystem = function() end }
local px, py = p:getX(), p:getY()
-- dx, dy in tiles (dy positive = south), the heading wanted
local CASES = {
    { 5, 0, "E" }, { 0, -5, "N" }, { -5, 0, "W" }, { 0, 5, "S" },
    { 5, -5, "NE" }, { -5, -5, "NW" }, { -5, 5, "SW" }, { 5, 5, "SE" },
}
local fails = 0
for i, c in ipairs(CASES) do
    local icon = { iconID = "zedqa_cmp_" .. i, xCoord = px + c[1], yCoord = py + c[2], itemType = "Base.Stone" }
    local ok, err = pcall(function() ISSearchManager.spotIcon(fakeMgr, icon) end)
    local q = FT._findQueues[pn] or {}
    local e = q[1]
    local key = e and tostring(e.bearing) or "nil"
    local letter = key:match("Compass(%a+)$") or key
    local good = ok and e and letter == c[3]
    if not good then fails = fails + 1 end
    say(string.format("%s a find %d east, %d south of the character: %s (want %s) dist %s%s", good and "PASS" or "FAIL",
        c[1], c[2], letter, c[3], tostring(e and e.dist), ok and "" or (" | hook error " .. tostring(err))))
end
FT._findQueues[pn] = was
say(fails == 0 and "8 of 8 headings right" or (fails .. " FAILED"))
local n = 0
local function later() n = n + 1; if n < 8 then return end; Events.OnTick.Remove(later); say("DONE") end
Events.OnTick.Add(later)
