-- ZeDUI/tools/qa/mp_p2_newchar.lua  (Nov 5 2026, QA): the second client through ZeD's new-character screens on the server: Next on Spawn and Occupation,
-- Play on Looks, each as its button does. Runs at the front end. grep "ZEDQA pnc".
local function say(s) print("ZEDQA pnc " .. tostring(s)) end
local MM = ZeD.MainMenu
local function vwin(view) local R = MM.root; for _, rv in ipairs(MM.views) do if rv.view == view then return R[rv.field] end end end
local n, last = 0, nil
local function tick()
    n = n + 1
    if n % 90 ~= 0 then return end
    local v = MM.view
    if v ~= last then say("view " .. tostring(v)); last = v end
    local ok, e = pcall(function()
        if v == "spawn" then vwin("spawn"):next()
        elseif v == "traits" then vwin("traits"):next()
        elseif v == "looks" then local l = vwin("looks"); if l.play then l:play() else l:next() end; Events.OnFETick.Remove(tick); say("Play pressed"); say("DONE") end
    end)
    if not ok then say("ERR " .. tostring(e)) end
    if n > 90 * 60 then Events.OnFETick.Remove(tick); say("gave up on view " .. tostring(v)); say("DONE") end
end
Events.OnFETick.Add(tick)
say("start")
