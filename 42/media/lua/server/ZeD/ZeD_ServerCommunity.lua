-- ZeD-UI/42/media/lua/server/ZeD/ZeD_ServerCommunity.lua
-- ============================================================================
-- COMMUNITY, THE SERVER'S SIDE (ZeDUI/MP_ADMIN_SCOPE.md, Phase 5). The message of the day, the rules, the appeal line, the
-- two ticks, the news, and who has agreed. Everything is decided here, from the player the event gives, never from a
-- client's word.
--
-- The table has a secret random name, as the tickets' does (A2), and is never transmitted. viewFor builds the one thing a
-- client receives, field by field: the words anyone on the server may read, whether this player is asked to agree, and for
-- those who may write, the two ticks. Who else has agreed never leaves the server.
--
-- Until a player asked at joining agrees, every ZeD command from them is refused (Srv.gates.rules): tickets, claims,
-- community, extras, log, dash, admin. Only the hello, a_hi, m_get and m_agree stay open. Who was asked is the server's own
-- record, made at the first word from them or at its own walk of the players online, so a client that never says hello is
-- caught all the same. Server Lua cannot remove a player (A7), so after Cm.L.ASKED_MS unanswered a Kick is owed, made by a
-- staff client or the host helper, with one line in the log staff read. The agreement itself is this server's record of what a
-- client said: a modified client can still send m_agree without showing the screen, and nothing on the server can tell.
--
-- Every edit goes through Srv.action, kind "community". An agreement is a line in the ZeD log alone: a busy server would
-- fill the ring with them. Only a real answer writes anything.
-- ============================================================================
if not isServer() then return end

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_AdminProto"
require "ZeD/ZeD_CommunityProto"
require "ZeD/ZeD_ServerCore"

local Srv = ZeD.Srv
local Tk = ZeD.Tk
local Adm = ZeD.Adm
local Cm = ZeD.Cm
if not Srv or Srv.off then return end

local CL = Cm.L
local PREFIX = "ZeD_CM_"
local SCHEMA = 1
local MIGRATE = {}                   -- MIGRATE[1] = function(md) ... end   moves 1 to 2; adds or reshapes, never drops

-- (a capability a later game renamed would be nil, and hasCapability(nil) matches no overload: this part stays off)
local CAP_RULES = Capability and Capability[Cm.CAP_RULES]
local CAP_NEWS = Capability and Capability[Cm.CAP_NEWS]
if not (CAP_RULES and CAP_NEWS) then
    Srv.fileLine("admin", Tk.SYS, "community off", nil, "this game has no " .. Cm.CAP_RULES .. " or " .. Cm.CAP_NEWS .. " capability")
    print("[ZeD] community off: a capability is missing")
    return
end

-- memory only: a /reloadlua of this file leaves it empty and open() fills it again
local T = { here = {} }               -- here: lower-case username -> { user, at, ask, noted }, one for each connection
Srv.M = T

-- ---------------------------------------------------------------------------
-- THE TABLE
-- ---------------------------------------------------------------------------
local function findName()
    local names = ModData.getTableNames()
    local best, found = nil, 0
    for i = 0, names:size() - 1 do
        local n = names:get(i)
        if string.sub(n, 1, #PREFIX) == PREFIX then
            found = found + 1
            if not best or n < best then best = n end
        end
    end
    if found > 1 then Srv.fileLine("admin", Tk.SYS, "community tables", nil, "found " .. found .. "; using the first by name") end
    return best
end

local function open()
    if T.md then return T.md end
    local name = findName() or (PREFIX .. getRandomUUID())
    local md = ModData.getOrCreate(name)
    md.schema = md.schema or SCHEMA
    md.motd = md.motd or ""
    md.appeal = md.appeal or ""
    md.rules = md.rules or { n = 0 }  -- each { id, text, rev }, in order
    md.nextRule = md.nextRule or 1
    md.rev = md.rev or 0              -- the rules' revision: a player who agreed at less is asked again
    md.saves = md.saves or 0          -- counts the saves: a Save from an older copy is stopped
    md.news = md.news or {}           -- id -> { id, text, by, t, pin }
    md.newsN = md.newsN or 0
    md.nextPost = md.nextPost or 1
    md.agreed = md.agreed or {}       -- lower-case username -> { rev, t }
    md.agreedN = md.agreedN or 0
    if md.ask == nil then md.ask = false end
    if md.reask == nil then md.reask = true end   -- (as the drawing has it, ticked)
    if md.schema > SCHEMA then
        T.frozen = true              -- data from a newer ZeD: read it, never change it
    end
    while md.schema < SCHEMA do
        local step = MIGRATE[md.schema]
        if not step or not pcall(step, md) then
            T.frozen = true          -- a missing or failed step: stop here, write nothing
            break
        end
        md.schema = md.schema + 1
    end
    if T.frozen then Srv.fileLine("admin", Tk.SYS, "community table frozen", nil, "schema " .. tostring(md.schema) .. ", this ZeD knows " .. SCHEMA) end
    T.md = md
    return md
end

local function frozen(p, rid)
    if T.frozen then Srv.ack(p, rid, false, "frozen"); return true end
    return false
end

-- the log's one way in; p is where it happened
local function logAt(p, what, detail)
    Srv.action("community", p:getUsername(), what, nil, detail, math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ()))
end

-- ---------------------------------------------------------------------------
-- WHAT EACH PERSON RECEIVES: built field by field from an allowlist
-- ---------------------------------------------------------------------------
-- must this player answer? A frozen table cannot keep an answer, so it asks nobody. No rules: nothing to agree to
local function asked(md, user)
    local a = md.agreed[string.lower(user)]
    if T.frozen or not md.ask or md.rules.n == 0 then return false, a and a.rev or nil end
    if not a then return true, nil end
    return md.reask and (a.rev or 0) < md.rev, a.rev
end

local function newsSorted(md)
    local rows, n = {}, 0
    for _, post in pairs(md.news) do
        n = n + 1
        rows[n] = post
    end
    table.sort(rows, function(a, b)
        if (a.pin == true) ~= (b.pin == true) then return a.pin == true end
        return a.id > b.id
    end)
    return rows, n
end

-- the words anyone on the server may read
local function baseView(md)
    local rules = { n = md.rules.n }
    for i = 1, md.rules.n do
        local r = md.rules[i]
        rules[i] = { id = r.id, text = r.text, rev = r.rev }
    end
    local rows, n = newsSorted(md)
    local news = { n = n }
    for i = 1, n do
        local post = rows[i]
        news[i] = { id = post.id, text = post.text, by = post.by, t = post.t, pin = post.pin == true }
    end
    return { motd = md.motd, rules = rules, changed = md.changed, appeal = md.appeal, news = news }
end

local function viewFor(md, p, base)
    local v = {}
    for k, x in pairs(base or baseView(md)) do v[k] = x end
    local need, since = asked(md, p:getUsername())
    v.rev = md.rev
    v.ask = need and true or nil
    v.since = since
    v.frozen = T.frozen and true or nil
    if Srv.can(p, CAP_RULES) or Srv.can(p, CAP_NEWS) then
        v.edit = { ask = md.ask, reask = md.reask, base = md.saves, by = md.by, at = md.at }
    end
    return v
end

-- everyone online; can is tested again at every push, so a demoted client gets no more ticks
local function pushNow(md)
    T.pushDue, T.pushedAt = nil, getTimestampMs()
    local base = baseView(md)
    Srv.eachOnline(function(o) Srv.to(o, Cm.MOD, "m_view", viewFor(md, o, base)) end)
end

-- a change. The whole board is the one large thing this part sends, so it goes out at most once in PUSH_MS: a change inside that
-- goes with the first tick that may, and p, who made it, gets it now
local function pushAll(md, p)
    if not T.pushedAt or getTimestampMs() - T.pushedAt >= CL.PUSH_MS then
        pushNow(md)
        return
    end
    T.pushDue = true
    Srv.to(p, Cm.MOD, "m_view", viewFor(md, p))
end

-- the appeal line for a player who has to leave (ZeD_ServerAdmin.lua: a banned player gets it with the reason)
function Srv.appealLine()
    local md = open()
    if md.appeal == "" then return nil end
    return md.appeal
end

-- ---------------------------------------------------------------------------
-- THE COMMANDS
-- ---------------------------------------------------------------------------
local function reg(command, opts, fn) Srv.register(Cm.MOD, command, opts, fn) end

reg("m_get", { limit = CL.GET_MS }, function(p, a, rid)
    local md = open()
    Srv.to(p, Cm.MOD, "m_view", viewFor(md, p))
end)

-- the oldest agreement goes, when the list is full: that player is asked once more
local function trimAgreed(md)
    if md.agreedN <= CL.AGREED_MAX then return end
    local oldest, at = nil, nil
    for k, e in pairs(md.agreed) do
        if not at or (e.t or 0) < at then oldest, at = k, e.t or 0 end
    end
    if oldest then
        md.agreed[oldest] = nil
        md.agreedN = md.agreedN - 1
    end
end

-- rev: the revision the client showed. Past what is here it means nothing, and anything but a good number counts as now
reg("m_agree", { limit = CL.AGREE_MS }, function(p, a, rid)
    local md = open()
    if frozen(p, rid) then return end
    -- (not being asked: nothing to keep, or a rule added later would find this name and never ask)
    if not asked(md, p:getUsername()) then
        Srv.ack(p, rid, true)
        return
    end
    local rev = (Tk.whole(a.rev) and a.rev <= md.rev) and a.rev or md.rev
    local low = string.lower(p:getUsername())
    if not md.agreed[low] then md.agreedN = md.agreedN + 1 end
    md.agreed[low] = { rev = rev, t = getTimestamp() }
    trimAgreed(md)
    if T.here[low] then T.here[low].ask = false end
    Srv.fileLine("community", p:getUsername(), "agreed to the rules", nil, "revision " .. tostring(rev))
    Srv.ack(p, rid, true)
    Srv.to(p, Cm.MOD, "m_view", viewFor(md, p))
end)

-- the rows a client sent, checked; nil, or nil and "text". Each is { id or nil, text }
local function readRows(p, list)
    if type(list) ~= "table" or not (list.n == 0 or Tk.whole(list.n)) or list.n > CL.RULES_MAX then
        Srv.bad(p, "m_save")
        return nil
    end
    local rows = {}
    for i = 1, list.n do
        local row = list[i]
        local text = type(row) == "table" and Cm.line(row.text, CL.RULE_MAX) or nil
        if not text or text == "" then return nil end
        rows[i] = { id = Tk.whole(row.id) and row.id or nil, text = text }
    end
    return rows
end

-- the new list, keeping each rule's revision unless its words changed. How many changed, whether any went, whether any moved
local function mergeRules(md, rows)
    local byId = {}
    for i = 1, md.rules.n do byId[md.rules[i].id] = md.rules[i] end
    local out, fresh, moved = { n = #rows }, 0, false
    local nextRev = md.rev + 1
    for i, row in ipairs(rows) do
        local old = row.id and byId[row.id] or nil
        if old then byId[row.id] = nil end        -- (an id sent twice is new the second time)
        if old and old.text == row.text then
            out[i] = { id = old.id, text = old.text, rev = old.rev }
            if md.rules[i] ~= old then moved = true end
        elseif old then
            fresh = fresh + 1
            out[i] = { id = old.id, text = row.text, rev = nextRev }
        else
            fresh = fresh + 1
            out[i] = { id = md.nextRule, text = row.text, rev = nextRev }
            md.nextRule = md.nextRule + 1
        end
    end
    local removed = false                         -- (Kahlua has no next())
    for _ in pairs(byId) do removed = true end
    return out, fresh, removed, moved
end

reg("m_save", { cap = CAP_RULES, limit = CL.SAVE_MS, mark = false }, function(p, a, rid)
    local md = open()
    if frozen(p, rid) then return end
    local motd = Cm.text(a.motd, CL.MOTD_MAX)
    local appeal = Cm.line(a.appeal, CL.APPEAL_MAX)
    local rows = readRows(p, a.rules)
    if not (motd and appeal and rows) then
        Srv.ack(p, rid, false, "text")
        return
    end
    -- someone saved since this card was opened: their words are not lost without a second press
    if a.base ~= md.saves then
        Srv.ack(p, rid, false, "stale", { base = md.saves, by = md.by })
        return
    end
    local rules, fresh, removed, moved = mergeRules(md, rows)
    if fresh > 0 or (removed and Cm.ASK_ON_REMOVE) then md.rev = md.rev + 1 end
    if fresh > 0 or removed or moved then md.changed = getTimestamp() end
    local words = motd ~= md.motd or appeal ~= md.appeal
    md.rules, md.motd, md.appeal = rules, motd, appeal
    md.ask = a.ask == true and rules.n > 0
    md.reask = a.reask == true
    md.saves = md.saves + 1
    md.by, md.at = p:getUsername(), getTimestamp()
    Srv.mark(p, "m_save")
    logAt(p, "rules saved", tostring(rules.n) .. " rules, " .. tostring(fresh) .. " new or changed"
        .. (words and ", message or appeal changed" or "") .. ", ask " .. (md.ask and "on" or "off") .. ", again " .. (md.reask and "on" or "off"))
    Srv.ack(p, rid, true, nil, { base = md.saves, reasked = fresh > 0 and md.ask and md.reask or nil })
    pushAll(md, p)
end)

-- room for one more, or nil: the oldest post that is not pinned goes, and the log keeps its words
local function newsRoom(md, p)
    if md.newsN < CL.NEWS_MAX then return true end
    local oldest = nil
    for _, post in pairs(md.news) do
        if not post.pin and (not oldest or post.id < oldest.id) then oldest = post end
    end
    if not oldest then return nil end
    md.news[oldest.id] = nil
    md.newsN = md.newsN - 1
    logAt(p, "news pushed off the board", "#" .. tostring(oldest.id) .. " by " .. tostring(oldest.by) .. ": " .. oldest.text)
    return true
end

-- a role's rank, as the admin tools read it. (Without them, its place.)
local function rankOf(p)
    local r = p:getRole()
    if Srv.rank then return Srv.rank(r) end
    return r and r:getPosition() or -1
end

reg("m_post", { cap = CAP_NEWS, limit = CL.POST_MS, mark = false }, function(p, a, rid)
    local md = open()
    if frozen(p, rid) then return end
    local text = Cm.text(a.text, CL.POST_MAX)
    if not text or text == "" then
        Srv.ack(p, rid, false, "text")
        return
    end
    if not newsRoom(md, p) then
        Srv.ack(p, rid, false, "pinned")
        return
    end
    local id = md.nextPost
    md.nextPost = id + 1
    md.news[id] = { id = id, text = text, by = p:getUsername(), t = getTimestamp(), pin = a.pin == true, rank = rankOf(p) }
    md.newsN = md.newsN + 1
    Srv.mark(p, "m_post")
    logAt(p, "news posted", "#" .. tostring(id) .. ": " .. text)
    Srv.ack(p, rid, true, nil, { id = id })
    pushAll(md, p)
end)

-- the post to pin or delete, or nil with the answer sent. As with acts on people, a role does not touch what one above it wrote
local function postOf(md, p, rid, id)
    local post = Tk.whole(id) and md.news[id] or nil
    if not post then
        Srv.ack(p, rid, false, "gone")
        return nil
    end
    if Adm.RANK_GUARD and post.rank and post.rank > rankOf(p) then
        Srv.ack(p, rid, false, "rank")
        return nil
    end
    return post
end

reg("m_pin", { cap = CAP_NEWS, limit = CL.PIN_MS }, function(p, a, rid)
    local md = open()
    if frozen(p, rid) then return end
    local post = postOf(md, p, rid, a.id)
    if not post then return end
    local on = a.on == true
    if (post.pin == true) == on then         -- (no change: nothing to log, nothing to send)
        Srv.ack(p, rid, true)
        return
    end
    post.pin = on
    logAt(p, post.pin and "news pinned" or "news unpinned", "#" .. tostring(post.id))
    Srv.ack(p, rid, true)
    pushAll(md, p)
end)

reg("m_del", { cap = CAP_NEWS, limit = CL.PIN_MS }, function(p, a, rid)
    local md = open()
    if frozen(p, rid) then return end
    local post = postOf(md, p, rid, a.id)
    if not post then return end
    md.news[post.id] = nil
    md.newsN = md.newsN - 1
    logAt(p, "news deleted", "#" .. tostring(post.id) .. ": " .. post.text)
    Srv.ack(p, rid, true)
    pushAll(md, p)
end)

-- ---------------------------------------------------------------------------
-- THE CLOCK: OnTickEvenPaused, as the admin tools' (A1)
-- ---------------------------------------------------------------------------
-- this connection's record: made at the first word from them (the hello or any command) or at the server's own walk. Asked
-- is fixed then: nobody is asked mid-play
local function hereOf(md, user, t)
    local low = string.lower(user)
    local e = T.here[low]
    if not e then
        e = { user = user, at = t, ask = (asked(md, user)) == true }
        T.here[low] = e
    end
    return e
end

-- still to answer the rules they were asked at joining (ZeD_ServerAdmin.lua: a Kick owed for them waits only while this holds)
function Srv.rulesUnanswered(user)
    local md = T.md
    if not md or type(user) ~= "string" then return false end
    local e = T.here[string.lower(user)]
    return e ~= nil and e.ask == true and (asked(md, e.user)) == true
end

-- the gate: asked and no answer, every ZeD command is refused but the few that let them answer
local OPEN = { [Cm.MOD .. ".m_agree"] = true, [Cm.MOD .. ".m_get"] = true, [Adm.MOD .. ".a_hi"] = true }
Srv.gates.rules = function(p, module, command)
    if module == Tk.MOD_LINK or OPEN[module .. "." .. tostring(command)] then return nil end
    local md = T.md
    if not md or T.frozen then return nil end
    local e = hereOf(md, p:getUsername(), getTimestampMs())
    if e.ask and (asked(md, e.user)) then return "has not agreed to the rules" end
    return nil
end

-- who was asked at joining and is still on with no answer: one line for a connection, and a Kick owed (reason "": the game's
-- own words). A role the game will not kick is only written down. Leave needs nothing, the player is gone. The walk itself
-- makes the record for anyone online without one, so a client that never says hello is asked all the same
local function lookAtAsked(md, t)
    Srv.eachOnline(function(o) hereOf(md, o:getUsername(), t) end)
    for low, e in pairs(T.here) do
        local o = Srv.player(e.user)
        if not o then
            T.here[low] = nil
        elseif e.ask and not asked(md, e.user) then
            e.ask = false
        elseif e.ask and not e.noted and t - e.at >= CL.ASKED_MS then
            e.noted = true
            local role = o:getRole()
            local cap = Capability and Capability.CantBeKickedByUser
            local kick = Srv.oweKick ~= nil and not (role and cap and role:hasCapability(cap))
            logAt(o, "rules not answered", "asked at joining, revision " .. tostring(md.rev) .. (kick and ", a kick is owed" or ""))
            if kick then Srv.oweKick(e.user, "", "rules") end
        end
    end
end

function Srv.communityTick()
    local md = T.md
    if not md then return end
    local t = getTimestampMs()
    if T.pushDue and t - T.pushedAt >= CL.PUSH_MS then pushNow(md) end
    if not T.lookedAt or t - T.lookedAt >= CL.ASKED_LOOK_MS then
        T.lookedAt = t
        lookAtAsked(md, t)
    end
end

-- ---------------------------------------------------------------------------
-- OPENING
-- ---------------------------------------------------------------------------
Srv.modules[Cm.MOD] = true
-- (a hello comes again at every respawn: the first of a connection is the one that shows the screen)
Srv.helloAdds.community = function(p, r)
    local v = viewFor(open(), p)
    r.cm = v
    hereOf(open(), p:getUsername(), getTimestampMs())
end

if Srv.communityHooked == nil then
    Srv.communityHooked = true
    Events.OnInitGlobalModData.Add(function() if ZeD.Srv.openCommunity then ZeD.Srv.openCommunity() end end)
    if Events.OnTickEvenPaused then
        Events.OnTickEvenPaused.Add(function()
            local ok, err = pcall(ZeD.Srv.communityTick)
            if not ok and not Srv.communityFailed then
                Srv.communityFailed = true
                print("[ZeD] server: the community clock failed: " .. tostring(err))
                Srv.action("admin", Tk.SYS, "community clock failed", nil, tostring(err))
            end
        end)
    end
end
Srv.openCommunity = open

return T
