-- ZeDUI/tools/qa/zedqa_kills_kind.lua  (Nov 7 2026, QA; punch list 101): which row a kill lands in. A zombie made beside the character for each weapon, made
-- harmless (setUseless), hit with the game's own IsoZombie:Hit until it dies (that fires OnHitZombie as a swing does). Then ZeD_Kills against what it held
-- before, and the Journal's header against the game's own count. Beta 6a files every weapon under Explosion and the header counts those twice.
-- Everything is put back (the kill count and ZeD_Kills; the save comes back after the batch). grep "ZEDQA kk".
local function say(s) print("ZEDQA kk " .. tostring(s)) end
local p = getPlayer()
local md = p:getModData()
local function copy(t) if type(t) ~= "table" then return t end local o = {} for k, v in pairs(t) do o[k] = copy(v) end return o end
local keepKills, keepKd = p:getZombieKills(), copy(md.ZeD_Kills)
local WEAPONS = { "Base.BaseballBat", "Base.Axe", "Base.HuntingKnife", "Base.Pistol", "Base.Hammer", "BARE", "Base.PipeBomb", "Base.Aerosolbomb", "Base.Molotov" }
-- (merge 1, Nov 7 2026: each weapon its own row; only a real explosive under Explosion; a Molotov is no explosion)
local WANT = { ["Base.BaseballBat"] = "Blunt", ["Base.Axe"] = "Axe", ["Base.HuntingKnife"] = "SmallBlade", ["Base.Pistol"] = "Firearm",
               ["Base.Hammer"] = "SmallBlunt", BARE = "Unarmed" }
local BOMB = { ["Base.PipeBomb"] = true, ["Base.Aerosolbomb"] = true }
local function weapon(ft)
    if ft == "BARE" then return instanceItem("Base.BareHands") end
    return instanceItem(ft)
end
local function snap()
    local kd = md.ZeD_Kills or {}
    local w = {}
    for k, v in pairs(kd.weapon or {}) do w[k] = v end
    return { explosion = kd.explosion or 0, fire = kd.fire or 0, vehicle = kd.vehicle or 0, weapon = w, engine = p:getZombieKills(), v = kd.v }
end
local before, wi, z, hits, nPass, nFail = nil, 0, nil, 0, 0, 0
local log = {}
local function check(ok, what) if ok then nPass = nPass + 1; say("PASS " .. what) else nFail = nFail + 1; say("FAIL " .. what) end end
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
step(30, function()
    before = snap()
    local d0 = ZeD.JournalTab.gatherData(p)
    before.header = d0 and d0.totalKills
    say("before: engine " .. before.engine .. ", explosion " .. before.explosion .. ", fire " .. before.fire .. ", vehicle " .. before.vehicle .. ", Other " .. tostring(before.weapon.Other) .. ", version " .. tostring(before.v) .. ", Journal header " .. tostring(before.header))
end)
for n, ft in ipairs(WEAPONS) do
    step(10, function()
        wi = n
        local x, y = math.floor(p:getX()) + 2, math.floor(p:getY())
        local list = addZombiesInOutfit(x, y, 0, 1, nil, 0)
        z = list and list:size() > 0 and list:get(0) or nil
        if z then z:setUseless(true) end
        hits = 0
        say(ft .. ": zombie " .. tostring(z ~= nil))
    end)
    step(20, function()
        local w = weapon(ft)
        if not (z and w) then say("ERR " .. ft .. ": no zombie or weapon"); return end
        local s0 = snap()
        for _ = 1, 30 do
            if z:isDead() or z:getHealth() <= 0 then break end
            pcall(function() z:Hit(w, p, 3.0, false, 1.0) end)
            hits = hits + 1
        end
        log[n] = { ft = ft, s0 = s0, dead = z:isDead() or z:getHealth() <= 0, instant = w.isInstantExplosion and w:isInstantExplosion(), power = w.getExplosionPower and w:getExplosionPower() }
    end)
    step(90, function()
        local l = log[n]
        if not l then return end
        local s1 = snap()
        local moved = {}
        for k, v in pairs(s1.weapon) do if v ~= (l.s0.weapon[k] or 0) then moved[#moved + 1] = k .. "+" .. (v - (l.s0.weapon[k] or 0)) end end
        if s1.explosion ~= l.s0.explosion then moved[#moved + 1] = "explosion+" .. (s1.explosion - l.s0.explosion) end
        if s1.fire ~= l.s0.fire then moved[#moved + 1] = "fire+" .. (s1.fire - l.s0.fire) end
        say(l.ft .. ": dead " .. tostring(l.dead) .. " after " .. hits .. " hits, instant " .. tostring(l.instant) .. ", power " .. tostring(l.power) .. ", engine +" .. (s1.engine - l.s0.engine) .. ", ZeD " .. (#moved > 0 and table.concat(moved, " ") or "nothing"))
        if n == 1 then
            -- the one-time save fix, on the first death this build sees (the QA save was saved on beta 6a)
            local old = before.v ~= 2 and before.explosion or 0
            local otherWas = (before.weapon.Other or 0)
            check(s1.v == 2, "the save fix stamps version 2 (was " .. tostring(before.v) .. ")")
            check(before.v == 2 or ((s1.weapon.Other or 0) - otherWas == old and l.s0.explosion == before.explosion), "the save fix moves the old Explosion count (" .. before.explosion .. ") into Other once (Other " .. otherWas .. " -> " .. tostring(s1.weapon.Other) .. ")")
            local d1 = ZeD.JournalTab.gatherData(p)
            check(d1 and before.header and d1.totalKills - before.header == s1.engine - before.engine, "the save fix leaves the header alone (header " .. tostring(before.header) .. " -> " .. tostring(d1 and d1.totalKills) .. ", this kill +" .. (s1.engine - before.engine) .. ")")
            -- (this kill's own row, measured past the fix)
            l.s0.explosion = 0
            if before.v ~= 2 then l.s0.weapon.Other = (l.s0.weapon.Other or 0) + old end
        end
        if l.dead then
            local expl = s1.explosion - l.s0.explosion
            local fire = s1.fire - l.s0.fire
            if BOMB[l.ft] then check(expl == 1, l.ft .. " counts as an explosion (+" .. expl .. ")")
            else check(expl == 0, l.ft .. " is not filed as an explosion (+" .. expl .. ")") end
            check(fire == 0, l.ft .. " makes no fire row (+" .. fire .. ")")
            if WANT[l.ft] then
                local got = (s1.weapon[WANT[l.ft]] or 0) - (l.s0.weapon[WANT[l.ft]] or 0)
                check(got == 1, l.ft .. " goes under " .. WANT[l.ft] .. " (+" .. got .. ")")
            end
        end
    end)
end
step(10, function()
    local s = snap()
    local data = ZeD.JournalTab.gatherData(p)
    local extra = (s.fire - before.fire) + (s.vehicle - before.vehicle) + (s.explosion - before.explosion)
    say("after: engine " .. s.engine .. ", ZeD explosion " .. s.explosion .. ", Journal header " .. tostring(data and data.totalKills))
    -- (Build's rule after merge 1, Nov 7 2026: the header is the game's own count plus fire kills, the only kills the
    -- game leaves out, since a burning zombie's death clears its attacker)
    check(data ~= nil and data.totalKills == s.engine + s.fire, "the Journal header is the game's own count plus fire kills (header " .. tostring(data and data.totalKills) .. ", game " .. s.engine .. ", fire " .. s.fire .. ", vehicle " .. s.vehicle .. ", explosion " .. s.explosion .. ")")
    check((s.fire - before.fire) == 0, "no fire rows from this run's weapon kills (fire +" .. (s.fire - before.fire) .. ")")
    say("this run's own kills: engine +" .. (s.engine - before.engine) .. ", ZeD extra rows +" .. extra)
end)
step(5, function()
    p:setZombieKills(keepKills)
    md.ZeD_Kills = keepKd
    say(nPass .. " passed, " .. nFail .. " failed")
    say("DONE")
end)
local function tick()
    if wait > 0 then wait = wait - 1; return end
    qi = qi + 1
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. " " .. tostring(e)) end
    wait = s.n
end
say("start")
Events.OnTick.Add(tick)
