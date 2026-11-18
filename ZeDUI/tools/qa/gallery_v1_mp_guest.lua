-- ZeDUI/tools/qa/gallery_v1_mp_guest.lua  (Nov 17 2026, QA; ZeD-GUI 1.0 gallery, picture 75 "Playing on a Server"): on
-- each OTHER player's client (mp_client2.ps1 -Slot n -Run), modelled on gallery_cinema_angel_guest.lua. Waits until the
-- admin (user angel, gallery_v1_mp_run.ps1) has brought it over (/teleport, gallery_cinema_angel_gather.lua), then stands on its own square in
-- the street to the right of and below the admin (where the Character window on the left and the chat top right leave
-- the picture open), keeps that square for two minutes and faces the admin. Then says one line on the General chat
-- (/all, through ZeD's chat), each player a few seconds after the one before, so the admin's chat shows the lines
-- under QA's own test names. Prints DONE once placed and the line sent. grep "ZEDQA g1mpg".
G1G = {}
local G = G1G
G.p = getPlayer()
G.me = G.p and tostring(G.p:getUsername()) or "?"
-- squares from the admin: +x is down-right on screen, +y down-left; these sit right of and below the character
G.ADMIN = "angel"   -- (the admin client's QA test name: gallery_v1_mp_run.ps1 makes the account and joins as it)
G.SPOT = { bob = { 3, -1 }, carl = { 2, 2 }, dave = { 5, 1 }, erin = { 4, 3 } }
G.LINE = {
    bob = { 0, "/all anyone got a can opener? got beans to trade" },
    carl = { 6000, "/all on my way, save me a spot by the motel" },
    dave = { 12000, "/all came in on the west road, its clear for now" },
    erin = { 18000, "/all who left the car door open lol" },
}
G.off = G.SPOT[G.me] or { 3, 3 }
G.line = G.LINE[G.me] or { 20000, "/all hey" }
G.placed, G.sent, G.n, G.t0, G.admin = false, false, 0, getTimestampMs(), nil
function G.say(s) print("ZEDQA g1mpg " .. tostring(s)) end
function G.find()
    local l = getOnlinePlayers()
    for i = 0, l:size() - 1 do
        local o = l:get(i)
        if o ~= G.p and tostring(o:getUsername()) == G.ADMIN then return o end
    end
    return nil
end
function G.place()
    local ax, ay = G.admin:getX(), G.admin:getY()
    if not G.placed then
        if math.abs(ax - G.p:getX()) > 4 or math.abs(ay - G.p:getY()) > 4 then
            if G.n % 300 == 0 then G.say(string.format("admin at %d,%d, me at %d,%d: waiting for the teleport", math.floor(ax), math.floor(ay), math.floor(G.p:getX()), math.floor(G.p:getY()))) end
            return
        end
        G.x, G.y = math.floor(ax) + G.off[1] + 0.5, math.floor(ay) + G.off[2] + 0.5
        G.p:setX(G.x); G.p:setY(G.y); G.p:setLastX(G.x); G.p:setLastY(G.y)
        G.placed, G.at = true, getTimestampMs()
        G.say(string.format("%s placed at %d,%d beside the admin at %d,%d", G.me, math.floor(G.x), math.floor(G.y), math.floor(ax), math.floor(ay)))
    end
    -- (the server's teleport can land after the placing: the square is held for two minutes)
    if getTimestampMs() - G.at < 120000 and (math.abs(G.p:getX() - G.x) > 0.6 or math.abs(G.p:getY() - G.y) > 0.6) then
        G.p:setX(G.x); G.p:setY(G.y); G.p:setLastX(G.x); G.p:setLastY(G.y)
        G.say(G.me .. " put back on its square")
    end
    G.p:faceLocation(ax, ay)
    if not G.sent and getTimestampMs() - G.at >= 4000 + G.line[1] then
        G.sent = true
        local ok, went, why = pcall(ZeD.Chat.send, G.line[2])
        G.say("chat line sent " .. tostring(ok and went) .. (why and (" (" .. tostring(why) .. ")") or "") .. ": " .. G.line[2])
        G.say("DONE")
    end
end
function G.tick()
    G.n = G.n + 1
    if G.n % 15 ~= 0 then return end
    local ok, e = pcall(function()
        G.admin = G.find() or G.admin
        if not G.admin then
            if G.n % 300 == 0 then G.say("waiting for the admin") end
            -- (Nov 18 2026) bob waited 15 minutes once: the admin never showed in its online list (another client only
            -- knows the players near it, and its teleport had not landed). After a minute it walks itself to the
            -- stage's usual square (gallery_v1_mp_stage.lua, the first spot), so the admin comes into range and the
            -- placing above takes over.
            if not G.fellBack and getTimestampMs() - G.t0 > 60000 then
                G.fellBack = true
                local fx, fy = 10600 + G.off[1] + 0.5, 9800 + G.off[2] + 0.5
                G.p:setX(fx); G.p:setY(fy); G.p:setLastX(fx); G.p:setLastY(fy)
                G.say(string.format("no admin after a minute: %s walked itself to the stage's usual square, at %d,%d", G.me, math.floor(fx), math.floor(fy)))
            end
            return
        end
        G.place()
    end)
    if not ok then G.say("ERR " .. tostring(e)) end
    if getTimestampMs() - G.t0 > 900000 then Events.OnTick.Remove(G.tick) end
end
Events.OnTick.Add(G.tick)
G.say("start as " .. G.me)
