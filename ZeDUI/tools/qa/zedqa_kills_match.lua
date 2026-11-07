-- ZeDUI/tools/qa/zedqa_kills_match.lua  (Nov 7 2026, QA; the director's answer 4: the Identity and Journal kill counts match)
-- Run after zedqa_kills_kind.lua (which kills with each weapon). The Identity tab's figure (ZeD.IdentityTab.gatherData's
-- zKills), the Journal's header and the death record all come from ZeD.KillTracker.total = the game's count + fire kills;
-- the Journal's rows (every weapon kind, explosion, fire, vehicle) must add up to it, and the table carries the fix's mark.
-- grep "ZEDQA kmt".
local function say(s) print("ZEDQA kmt " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, what, d)
    if ok then pass = pass + 1 else fail = fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (d ~= nil and (" (" .. tostring(d) .. ")") or ""))
end
local p = getPlayer()
local K = ZeD.KillTracker
local ok, e = pcall(function()
    local game = p:getZombieKills()
    local kd = K.data(p)
    local total = K.total(p)
    local rows, parts = 0, {}
    for k, v in pairs(kd.weapon or {}) do rows = rows + (tonumber(v) or 0); parts[#parts + 1] = k .. "=" .. tostring(v) end
    rows = rows + (tonumber(kd.explosion) or 0) + (tonumber(kd.fire) or 0) + (tonumber(kd.vehicle) or 0)
    say(string.format("the game's count %d; fire %s; vehicle %s; explosion %s; weapons %s; mark v=%s", game, tostring(kd.fire), tostring(kd.vehicle), tostring(kd.explosion), table.concat(parts, ", "), tostring(kd.v)))
    check(total == game + (tonumber(kd.fire) or 0), "the total is the game's count plus fire kills", total)
    local idOk, id = pcall(function() return ZeD.IdentityTab.gatherData(p) end)
    local idN = idOk and id and tonumber(id.zKills) or nil
    check(idN == total, "the Identity tab shows the total", tostring(idN) .. " against " .. total)
    check(rows == total, "the Journal's rows add up to its header", rows .. " against " .. total)
    check(kd.v ~= nil, "the table carries the fix's mark", kd.v)
end)
if not ok then say("ERR " .. tostring(e)) end
say(pass .. " passed, " .. fail .. " failed")
say("DONE")
