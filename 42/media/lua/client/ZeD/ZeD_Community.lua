-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Community.lua
-- ============================================================================
-- COMMUNITY, THE CLIENT'S MODEL. Client file, no drawing: ZeD_CommunityCards.lua reads this and calls it.
--
-- The server holds the message of the day, the rules, the appeal line and the news, and sends each client what it may read
-- with the hello and again at every change (ZeD_ServerCommunity.lua). No view means the server has no such part: every
-- surface stays away and nothing here does anything.
--
-- The join screen is shown once in a connection, on the hello that says this player must answer. I agree closes it at once
-- and tells the server: no answer from the server can hold a player there, and one that is lost means they are asked again
-- next time. So a server that cannot be reached can never trap anyone.
--
-- The appeal line is kept in Lua/ZeD_appeal.txt for each server, because a banned player cannot log in to ask for it.
--
-- QA, read at call time (the ticket cards' style):
--   M.qaHold   true: no traffic, and the join screen waits for qaJoin. The screen shows only what the QA script put in the model
--   M.qaLink   true / false: the server part as the cards read it
-- ============================================================================

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_CommunityProto"
require "ZeD/ZeD_ServerLink"
require "ZeD/ZeD_Tickets"
require "ZeD/ZeD_Admin"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.Community = ZeD.Community or {}
local M = ZeD.Community
local S = ZeD.ServerPart
local Cm = ZeD.Cm
local K = ZeD.Tickets

local APPEAL_FILE = "ZeD_appeal.txt"
local APPEALS_MAX = 50                -- servers remembered, oldest out
local REMOVED_KEYS = { "UI_Policy_Kick", "UI_Policy_KickReason", "UI_OnConnectFailed_Banned", "UI_OnConnectFailed_BannedReason" }
local REASON = "ZEDREASON"            -- stands in for the reason: 42.22 logs an exception for words asked without their arguments

M.seq = M.seq or 0                    -- bumps on every change (the cards re-read)

local function now() return getTimestampMs() end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
function M.bump() M.seq = M.seq + 1 end

-- the server part as these surfaces read it
function M.live()
    if M.qaLink ~= nil then return M.qaLink end
    return S.available() and S.cm == true and M.view ~= nil
end

function M.frozen() return M.view ~= nil and M.view.frozen == true end

-- may this client write? The server decides every command regardless: these only draw the card
function M.canRules() return ZeD.Admin.can(Cm.CAP_RULES) end
function M.canNews() return ZeD.Admin.can(Cm.CAP_NEWS) end

-- ---------------------------------------------------------------------------
-- THE APPEAL LINE: from the server while on it, from this computer once off it
-- ---------------------------------------------------------------------------
local function readKept()
    local out = {}
    local r = getFileReader(APPEAL_FILE, false)
    if not r then return out end
    local l = r:readLine()
    while l do
        local at = string.find(l, "|", 1, true)
        if at then out[#out + 1] = { key = string.sub(l, 1, at - 1), appeal = string.sub(l, at + 1) } end
        l = r:readLine()
    end
    r:close()
    return out
end

local function writeKept(list)
    local f = getFileWriter(APPEAL_FILE, true, false)
    for _, e in ipairs(list) do f:write(e.key .. "|" .. e.appeal .. "\n") end
    f:close()
end

function M.keyOf(ip, port) return tostring(ip) .. ":" .. tostring(port) end

function M.serverKey()
    return safe(function() return M.keyOf(getServerIP(), getServerPort()) end, nil)
end

function M.kept(key)
    if not key then return nil end
    local found = nil
    local ok, list = pcall(readKept)
    if not ok then return nil end
    for _, e in ipairs(list) do
        if e.key == key then found = e.appeal end
    end
    return found
end

-- the last line goes last in the file, and an empty one takes the server off the list
function M.keep(appeal)
    local key = M.serverKey()
    if not key or M.keptNow == (appeal or "") then return end
    M.keptNow = appeal or ""
    local ok, err = pcall(function()
        local list = {}
        for _, e in ipairs(readKept()) do
            if e.key ~= key then list[#list + 1] = e end
        end
        if M.keptNow ~= "" then list[#list + 1] = { key = key, appeal = M.keptNow } end
        while #list > APPEALS_MAX do table.remove(list, 1) end
        writeKept(list)
    end)
    if not ok then ZeD.logOnce("community: the appeal line", err) end
end

function M.appeal()
    local v = M.view
    if v and v.appeal and v.appeal ~= "" then return v.appeal end
    if v then return nil end
    return M.kept(M.serverKey())
end

-- the game's words for someone kicked or banned, each up to the reason's place. Once: the connect screen asks every frame
local function removedHeads()
    if M.heads then return M.heads end
    local heads = {}
    for _, key in ipairs(REMOVED_KEYS) do
        local words = safe(function() return getText(key, REASON) end, nil)
        if words and words ~= key then
            local cut = string.find(words, REASON, 1, true)
            local head = string.gsub(cut and string.sub(words, 1, cut - 1) or words, "%s+$", "")
            if head ~= "" then heads[#heads + 1] = head end
        end
    end
    M.heads = heads
    return heads
end

-- is this what the game says to someone kicked or banned? The line goes only under these: a server going down has nobody to
-- appeal to
function M.isRemoved(s)
    if type(s) ~= "string" then return false end
    for _, head in ipairs(removedHeads()) do
        if string.find(s, head, 1, true) then return true end
    end
    return string.find(s, "You were banned", 1, true) ~= nil
end

-- ---------------------------------------------------------------------------
-- THE VIEW, and being asked
-- ---------------------------------------------------------------------------
function M.setView(v)
    M.view = v
    M.bump()
    if v then M.keep(v.appeal) end
end

function M.onHello(a)
    M.setView(a.cm)
    if M.joined then return end
    M.joined = true
    if a.cm and a.cm.ask then M.askAt = now() end
end

-- the rule numbers marked NEW for this player
function M.newRules() return Cm.newRules(M.view) end

-- rev: the rules' revision on the screen that was answered
function M.agree(rev)
    M.askAt = nil
    if M.qaHold then return end
    -- (taken: every part asks again for what the rules gate refused meanwhile)
    K.requestOn(Cm.MOD, "m_agree", { rev = rev or (M.view and M.view.rev) or nil }, function(a)
        if a.ok ~= false and S.agreed then S.agreed() end
    end)
end

function M.leave()
    M.askAt = nil
    if M.qaHold then return end
    pcall(forceDisconnect)
end

function M.get()
    if M.qaHold or not M.live() then return end
    S.send(Cm.MOD, "m_get", {})
end

-- ---------------------------------------------------------------------------
-- WRITING: every answer comes back to cb
-- ---------------------------------------------------------------------------
local function act(cmd, args, cb)
    K.requestOn(Cm.MOD, cmd, args, function(a)
        if cb then cb(a) end
        M.bump()
    end)
end

-- d: motd, appeal, ask, reask, base, rules = { n, [i] = { id or nil, text } }
function M.save(d, cb) act("m_save", d, cb) end
function M.post(text, pin, cb) act("m_post", { text = text, pin = pin == true }, cb) end
function M.pin(id, on, cb) act("m_pin", { id = id, on = on == true }, cb) end
function M.del(id, cb) act("m_del", { id = id }, cb) end

-- ---------------------------------------------------------------------------
-- WHAT THE SERVER SENDS
-- ---------------------------------------------------------------------------
S.on(Cm.MOD, function(command, args)
    if command == "m_view" then M.setView(args) end
end)

-- ---------------------------------------------------------------------------
-- THE CLOCK: the join screen goes up once the game can draw it
-- ---------------------------------------------------------------------------
local function tick()
    if M.askAt and not M.qaHold and M.joinScreen and getPlayer() then
        M.askAt = nil
        local ok, err = pcall(M.joinScreen)
        if not ok then ZeD.logOnce("community: the join screen", err) end
    end
end

if not M.hooked then
    M.hooked = true
    if Events.OnTick then Events.OnTick.Add(tick) end
    -- (a new connection: asked afresh)
    if Events.OnGameStart then Events.OnGameStart.Add(function() M.joined = nil end) end
end

return M
