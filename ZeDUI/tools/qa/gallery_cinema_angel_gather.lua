-- ZeDUI/tools/qa/gallery_cinema_angel_gather.lua  (Nov 11 2026, QA; the gallery's closing break): on the ADMIN client, the
-- server's /teleport brings each other player (the names in zedqa_cang_guests.txt, one a line) to the admin, as
-- zedqa_b8_mp_stage.lua brings bob. grep "ZEDQA cangg".
local function say(s) print("ZEDQA cangg " .. tostring(s)) end
local me = getPlayer():getUsername()
local names = {}
local r = getFileReader("zedqa_cang_guests.txt", false)
if r then local l = r:readLine(); while l do if l ~= "" then names[#names + 1] = l end; l = r:readLine() end; r:close() end
for _, n in ipairs(names) do SendCommandToServer('/teleport "' .. n .. '" "' .. me .. '"') end
say("teleported " .. #names .. " to " .. tostring(me) .. ": " .. table.concat(names, ", "))
CANG_GUESTS_SET = #names
local k = 0
local function f() k = k + 1; if k < 120 then return end; Events.OnTick.Remove(f); say("DONE") end
Events.OnTick.Add(f)