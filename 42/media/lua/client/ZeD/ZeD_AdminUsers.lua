-- ZeD-UI/42/media/lua/client/ZeD/ZeD_AdminUsers.lua
-- ============================================================================
-- THE USERS CARDS (ZeDUI/VANILLA_WINDOWS_20261107.md, C9; the director, Nov 7: every admin tool becomes a ZeD card). They
-- take over the game's Users List (ISUsersList) and the windows it opens. The Admin tab's Users row opens:
--   Users     Find with Online only, the count, every account a row (name, role, last seen or online, warning points), pages;
--             Add user below; a row for the game's banned IPs and Steam IDs, which the Bans card already holds
--   Account   one account: role, online and ping, last connection, whitelist and how they sign in, warning points,
--             suspicion points, kicks, Steam ID, the game's IP and Steam ID bans. Their Player card; Set password (a field
--             with the foot's answer), Reset password, Reset two-step code, Delete, and the game's per-account bans by IP
--             and by Steam ID, each behind the foot's confirm
-- Every act is the game's own call (networkUserAction, banUnbanUserAction), with the game's own checks before it: the
-- capability, the role's rank for account changes, CantBeBannedByUser, never on yourself, online for an IP or Steam ID ban.
-- A control that cannot be used stays on the card, gray, and says why. Everything else about a player (kick, ban with a
-- reason, warning points, role, logs) is on their Player card (ZeD_AdminCards.lua), one press away.
-- All player text is drawn with drawText, never through the game's rich text. Simple mode draws these same cards.
--
-- QA: U.qaRows (a list of rows, the shape of U.read's), U.qaHold (no traffic), AU.qaOpen(win, st, kind, user).
-- ZeDUI/tools/qa/admin_tools_sim.lua walks every state with these.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ZeD_Admin"
require "ZeD/ZeD_TicketCards"
require "ZeD/ZeD_AdminCards"

ZeD = ZeD or {}
ZeD.AdminUsers = ZeD.AdminUsers or {}
local AU = ZeD.AdminUsers
local M = ZeD.Admin
local AC = ZeD.AdminCards
local TC = ZeD.TicketCards
local Tk = ZeD.Tk
local D, B = TC._D, TC._B
local F = AC._F

local PAGE = 25                  -- accounts on one page
local READ_MS = 1000             -- getUsers has no event of its own: read this often while a card shows
local NAME_MAX = 64

local U = {}                     -- the model (a table: Kahlua counts every local in the chunk)
local P = {}                     -- the cards' parts
AU._U, AU._P = U, P
U.rows = U.rows or {}
U.seq = 0

local function tr(k, ...) return ZeD.tr(k, ...) end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
local function words(s) local S = ZeD.ServerTab; return (S and S.btnWords) and S.btnWords(s) or s end
function U.bump() U.seq = U.seq + 1 end

-- ---------------------------------------------------------------------------
-- THE MODEL: the game's user list, every field ISUsersList draws
-- ---------------------------------------------------------------------------
function U.readOne(u)
    local role = u:getRole()
    local ping = safe(function() return u:getPing() end, nil)
    return { user = u:getUsername(), on = u:isOnline() == true, role = role and role:getName() or nil,
        pos = role and safe(function() return role:getPosition() end, 0) or 0,
        last = safe(function() return u:getLastConnection() end, nil), warn = safe(function() return u:getWarningPoints() end, 0),
        susp = safe(function() return u:getSuspicionPoints() end, 0), kicks = safe(function() return u:getKicks() end, 0),
        sid = safe(function() return u:getSteamid() end, nil), ipBan = safe(function() return u:getIpBanned() end, ""),
        sidBan = safe(function() return u:getSteamIdBanned() end, ""), white = safe(function() return u:isInWhitelist() end, false) == true,
        auth = safe(function() return u:getAuthTypeName() end, nil), ping = ping and tonumber(ping) or nil,
        direct = safe(function() return u:isConnectedDirectly() end, false) == true }
end

function U.read()
    if U.qaHold then return end
    if U.qaRows then
        U.rows = U.qaRows
        return
    end
    if not M.can("SeeNetworkUsers") then
        U.rows = {}
        return
    end
    local out = {}
    pcall(function()
        local list = getUsers()
        for i = 0, list:size() - 1 do
            local ok, r = pcall(U.readOne, list:get(i))
            if ok and r and r.user then out[#out + 1] = r end
        end
    end)
    table.sort(out, function(a, b)
        if a.on ~= b.on then return a.on end
        return string.lower(a.user) < string.lower(b.user)
    end)
    local sig = {}
    for i, r in ipairs(out) do
        sig[i] = table.concat({ r.user, tostring(r.on), tostring(r.role), tostring(r.warn), tostring(r.susp), tostring(r.kicks), tostring(r.last),
            tostring(r.white), tostring(r.ipBan), tostring(r.sidBan), tostring(r.ping) }, ",")
    end
    sig = table.concat(sig, ";")
    U.rows = out
    if sig ~= U.sig then
        U.sig = sig
        U.bump()
    end
end

-- once a frame on a users card: the Admin tab's own asking (requestUsers, the banned lists), and this list read again
function U.watch()
    M.watch()
    if U.qaRows and U.rows ~= U.qaRows then
        U.rows = U.qaRows
        U.bump()
    end
    local t = getTimestampMs()
    if not U.readAt or t - U.readAt >= READ_MS then
        U.readAt = t
        U.read()
    end
end

function U.row(user)
    for _, r in ipairs(U.rows) do
        if r.user == user then return r end
    end
    return nil
end

function U.find(find, onlineOnly)
    local q = string.lower(Tk.clean(find) or "")
    local out = {}
    for _, r in ipairs(U.rows) do
        local keep = not onlineOnly or r.on
        -- (the game's own filter reads the name and the banned Steam ID and IP too)
        if keep and q ~= "" then
            keep = string.find(string.lower(r.user), q, 1, true) ~= nil
                or (r.role ~= nil and string.find(string.lower(r.role), q, 1, true) ~= nil)
                or (r.sidBan ~= nil and r.sidBan ~= "" and string.find(string.lower(r.sidBan), q, 1, true) ~= nil)
                or (r.ipBan ~= nil and r.ipBan ~= "" and string.find(string.lower(r.ipBan), q, 1, true) ~= nil)
        end
        if keep then out[#out + 1] = r end
    end
    return out
end

function U.myPos()
    if U.qaMyPos then return U.qaMyPos end
    return safe(function() return getPlayer():getRole():getPosition() end, 0)
end

-- the role's own capability, as the game reads it on the row's role
function U.roleHas(r, capName)
    local role = r.role and M.role(r.role)
    return role ~= nil and role.caps[capName] == true
end

-- ---------------------------------------------------------------------------
-- THE GAME'S CALLS, each as ISUsersList makes it
-- ---------------------------------------------------------------------------
U.ACTS = {
    del = function(r) networkUserAction("Delete", r.user, "") end,
    pass = function(r) networkUserAction("ResetPassword", r.user, "") end,
    totp = function(r) networkUserAction("ResetTOTPSecret", r.user, "") end,
    -- (the bans' game calls are made here only without ZeD's server part: with it they go through ZeD's Bans, U.ban)
    banip = function(r, reason) banUnbanUserAction("BanIP", r.user, reason or "") end,
    unbanip = function(r) banUnbanUserAction("UnBanIP", r.user, "") end,
    bansid = function(r, reason) banUnbanUserAction("BanSteamID", r.sid, reason or "") end,
    unbansid = function(r) banUnbanUserAction("UnBanSteamID", r.sid, "") end,
}

function U.act(kind, r, reason)
    local fn = U.ACTS[kind]
    if not fn then return false end
    local ok, err = pcall(fn, r, reason)
    if not ok then ZeD.logOnce("users: " .. kind, err) end
    pcall(requestUsers)
    U.readAt = nil
    if kind == "banip" or kind == "unbanip" or kind == "bansid" or kind == "unbansid" then
        pcall(getBannedIPs)
        if M.onSteam() then pcall(getBannedSteamIDs) end
    end
    return ok
end

-- THE BANS ON AN ACCOUNT (the director, Nov 7: one record for every ban). With ZeD's server part a ban by IP or by Steam ID is
-- ZeD's ban of that kind, as the Bans card and the Player card make it: a reason, a length, a row in ZeD's Bans list, and the
-- game's ban owed by the server (a_ban, a_owed). By IP: ZeD's ban on the name with its IP (M.ban, banIp). By Steam ID: the
-- account's own Steam ID from the game's user list, which counts as typed by staff (MP_SERVER_PART_DESIGN.md, the rules that
-- hold, item 4), so the game is given it (M.banTyped). Without the server part: the game's own calls, as before.
function U.ban(kind, r, reason, len, cb)
    if M.live() then
        if kind == "banip" then M.ban(r.user, reason, len, true, cb) else M.banTyped(r.sid, reason, len, cb) end
        return
    end
    local ok = U.act(kind, r, reason)
    if cb then cb({ ok = ok, fallback = true }) end
end

-- ZeD's row for this account's IP or Steam ID ban, if it has one
function U.banRow(kind, r)
    for _, b in ipairs(M.banRows()) do
        if kind == "unbanip" then
            if (b.user == r.user and b.banIp) or (b.ip and r.ipBan ~= "" and b.ip == r.ipBan) then return b end
        else
            local sid = (r.sidBan ~= nil and r.sidBan ~= "") and r.sidBan or r.sid
            if b.sid and sid and tostring(b.sid) == tostring(sid) then return b end
        end
    end
    return nil
end

-- the unban through ZeD's Bans: its row, or the game's own entry named for what it is
function U.unban(kind, r, cb)
    if M.live() then
        local row = U.banRow(kind, r)
        if not row then
            if kind == "unbanip" then row = { ip = r.ipBan, game = true } else row = { sid = (r.sidBan ~= "" and r.sidBan) or r.sid, game = true } end
        end
        M.unban(row, cb)
        return
    end
    local ok = U.act(kind, r)
    if cb then cb({ ok = ok, fallback = true }) end
end

function U.setPassword(user, text)
    if text == nil or text == "" then return false end
    local ok, err = pcall(networkUserAction, "SetPassword", user, text)
    if not ok then ZeD.logOnce("users: password", err) end
    return ok
end

function U.add(name)
    if name == nil or name == "" then return false end
    local ok, err = pcall(networkUserAction, "Add", name, "")
    if not ok then ZeD.logOnce("users: add", err) end
    pcall(requestUsers)
    U.readAt = nil
    return ok
end

-- ---------------------------------------------------------------------------
-- WHAT EACH CONTROL NEEDS: nil when it can be used, else the words
-- ---------------------------------------------------------------------------
-- account changes: ModifyNetworkUsers, and a role that ranks with theirs (the server checks the same)
function P.whyAccount(r)
    if not M.can("ModifyNetworkUsers") then return M.why("ModifyNetworkUsers") end
    if r.pos and U.myPos() < r.pos then return tr("UI_ZeD_Adm_Err_rank") end
    return nil
end

function P.whyBan(r, kind)
    if not M.can("BanUnbanUser") then return M.why("BanUnbanUser") end
    if kind == "unbanip" or kind == "unbansid" then return nil end
    if r.user == M.me() then return getText("IGUI_UserList_BanHimself") end
    if U.roleHas(r, "CantBeBannedByUser") then return getText("IGUI_UserList_CantBeBanned") end
    -- (a Steam ID ban through ZeD's Bans needs nobody online: the game's own call on its own does)
    if kind == "bansid" and M.live() then return nil end
    if not r.on or r.role == "banned" then
        return getText((kind == "bansid") and "IGUI_UserList_BanSteamIdNotOnline" or "IGUI_UserList_BanIPNotOnline")
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- THE USERS CARD
-- ---------------------------------------------------------------------------
function AU.open(win, st, from)
    local box = D.fieldOf(win, "ufind")
    if box then
        D.setField(win, "ufind", "")
        box._lastText = ""
    end
    D.setField(win, "uadd", "")
    U.readAt = nil
    F.push(win, st, { kind = "users", from = from or "adm:tk:sum:users", page = 1, find = "", only = false })
end

function P.lastText(r)
    if r.on then return tr("UI_ZeD_Adm_Online") end
    if r.last and r.last ~= "" and r.white then return r.last end
    return tr("UI_ZeD_Adm_NeverSeen")
end

function P.userRow(st, r, me)
    local warn = nil
    if r.warn and r.warn > 0 then warn = tr((r.warn == 1) and "UI_ZeD_Adm_OneWarn" or "UI_ZeD_Adm_Warns", r.warn) end
    local name = (r.user == me) and tr("UI_ZeD_Adm_NameYou", r.user) or r.user
    local user = r.user
    return { k = "arow", left = name, leftMin = 110, tag = r.role and { text = r.role, color = F.roleColor(r.role) } or nil,
        meta = P.lastText(r), dot = r.on, warn = warn, chev = true,
        c = { id = "u:" .. user, help = tr("UI_ZeD_Adm_HelpUserRow"), run = function(ww) AU.openUser(ww, st, user) end } }
end

function P.usersItems(win, st, t, card)
    local items = {}
    if not M.can("SeeNetworkUsers") then
        B.sub(items, M.why("SeeNetworkUsers"))
        return items
    end
    items[#items + 1] = { k = "afind", key = "ufind", hint = tr("UI_ZeD_Adm_UsersFindHint"), start = card.find,
        onText = function(_, text)
            card.find = text
            card.page = 1
            U.bump()
        end,
        c = { id = "f:ufind", help = tr("UI_ZeD_Adm_HelpUsersFind"), run = function(ww) D.useField(ww, "ufind") end },
        chip = { id = "uonly", style = "chip", text = tr("UI_ZeD_Adm_OnlineOnly"), on = card.only, help = tr("UI_ZeD_Adm_HelpOnlineOnly"),
            run = function()
                card.only = not card.only
                card.page = 1
                U.bump()
            end } }
    local on = 0
    for _, r in ipairs(U.rows) do
        if r.on then on = on + 1 end
    end
    local list = U.find(card.find, card.only)
    B.label(items, words(getText("IGUI_AdminPanel_SeeUsers")), tr("UI_ZeD_Adm_PlayerCount", on, #U.rows))
    if #U.rows == 0 then
        B.sub(items, tr("UI_ZeD_Srv_PlayersWait"))
    elseif #list == 0 then
        B.sub(items, tr("UI_ZeD_Adm_NobodyMatches"))
    end
    local pages = math.max(1, math.ceil(#list / PAGE))
    card.page = math.max(1, math.min(card.page, pages))
    local from = (card.page - 1) * PAGE
    local me = M.me()
    for i = 1, math.min(PAGE, #list - from) do
        local it = P.userRow(st, list[from + i], me)
        it.c.land = i == 1
        items[#items + 1] = it
    end
    if pages > 1 then
        local n = card.page
        F.flow(items, {
            F.gate({ id = "uprev", text = tr("UI_ZeD_Tk_Prev"), run = function() card.page = n - 1; U.bump() end }, nil, function()
                if n <= 1 then return tr("UI_ZeD_Tk_FirstPage") end
                return nil
            end),
            { style = "text", text = tr("UI_ZeD_Tk_PageOf", n, pages) },
            F.gate({ id = "unext", text = tr("UI_ZeD_Tk_Next"), run = function() card.page = n + 1; U.bump() end }, nil, function()
                if n >= pages then return tr("UI_ZeD_Tk_LastPage") end
                return nil
            end),
        })
    end
    -- ADD USER: the game's Add, a name for the whitelist with no password
    B.label(items, words(getText("IGUI_UserList_Add")))
    B.sub(items, tr("UI_ZeD_Adm_AddUserLine"))
    F.field(items, "uadd", 1, tr("UI_ZeD_Adm_AddUserHint"), #list == 0, NAME_MAX)
    F.flow(items, { F.gate({ id = "uaddb", text = words(getText("IGUI_UserList_Add")), help = tr("UI_ZeD_Adm_HelpAddUser"),
        run = function(ww)
            local name = F.text(ww, "uadd")
            if U.add(name) then
                D.setField(ww, "uadd", "")
                D.flash(TC.qaState(st), tr("UI_ZeD_Adm_UserAdded", name))
                U.bump()
            end
        end }, "ModifyNetworkUsers", function()
            local name = F.text(win, "uadd")
            if name == "" then return tr("UI_ZeD_Adm_WriteUserName") end
            if U.row(name) then return tr("UI_ZeD_Adm_UserExists", name) end
            return nil
        end) })
    -- the game's banned lists: the Bans card holds them, with ZeD's own
    B.label(items, words(getText(M.onSteam() and "IGUI_UserList_BannedSteamIDs" or "IGUI_UserList_BannedIPs")))
    items[#items + 1] = { k = "arow", left = tr("UI_ZeD_Adm_BansSum"), leftMin = 300, right = tostring(#M.banRows()), chev = true,
        c = F.gate({ id = "ubans", help = tr("UI_ZeD_Adm_HelpUsersBans"), run = function(ww) AC.openBans(ww, st) end }, "BanUnbanUser") }
    return items
end

TC.kinds.users = {
    data = function() return true end,
    tick = function() U.watch() end,
    key = function(t, card)
        return table.concat({ tostring(U.seq), tostring(M.seq), tostring(card.page), tostring(card.only), tostring(card.find) }, ":")
    end,
    title = function() return words(getText("IGUI_AdminPanel_SeeUsers")) end,
    help = function() return tr("UI_ZeD_Adm_HelpUsers") end,
    items = function(win, st, t, card) return P.usersItems(win, st, t, card) end,
    foot = function() return { main = {} } end,
}

-- ---------------------------------------------------------------------------
-- ONE ACCOUNT
-- ---------------------------------------------------------------------------
function AU.openUser(win, st, user)
    D.setField(win, "upass", "")
    F.push(win, st, { kind = "user", user = user, from = "tk:u:" .. user })
end

-- the game's own lines, as ISUsersList draws them under the name
function P.facts(items, r)
    if r.role then B.sub(items, getText("IGUI_UsersList_DetailsRole", r.role)) end
    local status = getText(r.on and "IGUI_UserList_Online" or "IGUI_UserList_Offline")
    if r.on and r.ping then status = status .. " | " .. getText("UI_Ping", r.ping) end
    B.sub(items, status)
    if r.white then
        B.sub(items, getText("IGUI_UsersList_DetailsAuthType", tostring(r.auth or "")))
        if r.last and r.last ~= "" then B.sub(items, getText("IGUI_UsersList_LastConnectionColumn") .. ": " .. r.last) end
    else
        B.sub(items, getText("IGUI_UsersList_DetailsNoWhitelist"))
    end
    B.sub(items, getText("IGUI_UsersList_WarningPoints", r.warn or 0))
    B.sub(items, getText("IGUI_UsersList_SuspicionPoints", r.susp or 0))
    B.sub(items, getText("IGUI_UsersList_Kicks", r.kicks or 0))
    -- (full-width lines, not facts: a Steam ID or a date is one long word, and a fact's column can't hold it in a narrow card)
    if r.sid and r.sid ~= "" and r.sid ~= "0" then B.sub(items, tr("UI_ZeD_Adm_SteamId") .. ": " .. r.sid) end
    if r.ipBan and r.ipBan ~= "" then B.sub(items, words(getText("IGUI_UserList_BannedIPs")) .. ": " .. r.ipBan) end
    if r.sidBan and r.sidBan ~= "" then B.sub(items, words(getText("IGUI_UserList_BannedSteamIDs")) .. ": " .. r.sidBan) end
end

-- the foot's question for each act, and what it says when done
P.ASK = {
    del = { ask = "UI_ZeD_Adm_UserDelAsk", btn = "IGUI_UserList_Delete", danger = true, help = "UI_ZeD_Adm_HelpUserDel" },
    pass = { ask = "UI_ZeD_Adm_UserPassAsk", btn = "IGUI_UserList_ResetPassword", help = "UI_ZeD_Adm_HelpUserPass" },
    totp = { ask = "UI_ZeD_Adm_UserTotpAsk", btn = "IGUI_UserList_ResetTOTPSecret", help = "UI_ZeD_Adm_HelpUserTotp" },
    banip = { btn = "IGUI_UserList_BanIP", danger = true, help = "UI_ZeD_Adm_HelpAcctBanIp" },
    unbanip = { ask = "UI_ZeD_Adm_UserUnbanIpAsk", btn = "IGUI_UserList_UnBanIP", help = "UI_ZeD_Adm_HelpUserUnbanIp" },
    bansid = { btn = "IGUI_UserList_BanBySteamID", danger = true, help = "UI_ZeD_Adm_HelpAcctBanSid" },
    unbansid = { ask = "UI_ZeD_Adm_UserUnbanSidAsk", btn = "IGUI_UserList_UnBanBySteamID", help = "UI_ZeD_Adm_HelpUserUnbanSid" },
}

function P.askBtn(st, card, kind, gate)
    local a = P.ASK[kind]
    return F.gate({ id = "ua:" .. kind, text = words(getText(a.btn)), danger = a.danger, help = tr(a.help),
        run = function(ww)
            local t = TC.qaState(st)
            t.confirm = { kind = kind, from = "tk:ua:" .. kind }
            D.focusId(ww, st, "tk:cno")
        end }, nil, gate)
end

-- Ban by IP or by Steam ID: a part on the card, the reason and the length, as the Player card's Ban
function P.banBtn(st, card, kind, gate)
    local a = P.ASK[kind]
    return F.gate({ id = "ua:" .. kind, text = words(getText(a.btn)), danger = true, help = tr(a.help),
        run = function(ww)
            D.setField(ww, "ureason", "")
            card.open, card.len = kind, "perm"
            U.bump()
            D.focusId(ww, st, "tk:f:ureason")
        end }, nil, gate)
end

function P.closeBan(win, st, card)
    local kind = card.open
    D.setField(win, "ureason", "")
    card.open = nil
    U.bump()
    D.focusId(win, st, "tk:ua:" .. tostring(kind))
end

function P.banWhy(win, card, kind)
    local now = U.row(card.user)
    if not now then return tr("UI_ZeD_Adm_UserGone", card.user) end
    local why = P.whyBan(now, kind)
    if why then return why end
    if ZeD.Adm.LENGTH[card.len].sec and not M.live() then return tr("UI_ZeD_Adm_NeedPart") end
    if kind == "banip" and ZeD.Adm.LENGTH[card.len].sec and not ZeD.Adm.TIMED_IP then return tr("UI_ZeD_Adm_IpPermOnly") end
    if F.text(win, "ureason") == "" then return tr("UI_ZeD_Adm_WriteReason") end
    return nil
end

function P.banPart(items, win, st, card, r)
    local kind = card.open
    local AP = AC._P
    F.inset(items, "danger", function()
        B.label(items, words(getText(P.ASK[kind].btn)))
        B.sub(items, tr(P.ASK[kind].help))
        B.label(items, tr("UI_ZeD_Adm_Reason"), tr("UI_ZeD_Adm_TheySee", r.user))
        F.field(items, "ureason", 2, tr("UI_ZeD_Adm_ReasonHint"), true, ZeD.Adm.L.REASON_MAX)
        B.label(items, tr("UI_ZeD_Adm_For"))
        F.flow(items, AP.lenChips(card, "ul:"))
        B.sub(items, AP.banLine(card.len))
        F.flow(items, {
            { id = "ubno", text = getText("UI_Cancel"), help = tr("UI_ZeD_Adm_HelpKeepUser"), run = function(ww) P.closeBan(ww, st, card) end },
            F.gate({ id = "ubyes", text = getText("IGUI_UserList_Ban"), danger = true, push = true, help = tr(P.ASK[kind].help),
                run = function(ww)
                    local why = P.banWhy(ww, card, kind)
                    if why then
                        D.flash(TC.qaState(st), why)
                        return
                    end
                    local reason = F.text(ww, "ureason")
                    local now = U.row(card.user)
                    F.act(ww, st, function(cb) U.ban(kind, now, reason, card.len, cb) end, tr("UI_ZeD_Adm_Banned", card.user), function()
                        P.closeBan(ww, st, card)
                        U.readAt = nil
                    end)
                end }, nil, function() return P.banWhy(win, card, kind) end),
        })
    end)
end

function P.userItems(win, st, t, card, r)
    local items = {}
    P.facts(items, r)
    -- PLAYER CARD: kick, ban with a reason, warning points, role, logs
    F.flow(items, { F.gate({ id = "upc", text = tr("UI_ZeD_Log_PlayerCard", r.user), help = tr("UI_ZeD_Adm_HelpPlayer"),
        run = function(ww) AC.openPlayer(ww, st, r.user, "tk:upc") end }, "CanSeePlayersStats") })
    -- THE ACCOUNT: password, two-step code, delete
    B.label(items, tr("UI_ZeD_Adm_Account"))
    local acct = function() return P.whyAccount(r) end
    if card.open == "pass" then
        B.sub(items, tr("UI_ZeD_Adm_PassLine", r.user))
        F.field(items, "upass", 1, tr("UI_ZeD_Adm_PassHint"), true, NAME_MAX)
        items[#items].mask = true      -- (starred, safe on a stream: the director, Nov 7)
        -- (Cancel here, not in the foot: Set password alone there fits the narrowest card)
        F.flow(items, { { id = "upcancel", text = getText("UI_Cancel"), help = tr("UI_ZeD_Adm_HelpKeepUser"), run = function(ww) P.closePass(ww, st, card) end } })
    else
        F.flow(items, {
            F.gate({ id = "upass", text = words(getText("IGUI_UserList_SetPassword")), help = tr("UI_ZeD_Adm_HelpUserSetPass"),
                run = function(ww)
                    D.setField(ww, "upass", "")
                    card.open = "pass"
                    U.bump()
                    D.focusId(ww, st, "tk:f:upass")
                end }, nil, acct),
            P.askBtn(st, card, "pass", acct),
            P.askBtn(st, card, "totp", acct),
            P.askBtn(st, card, "del", acct),
        })
    end
    -- BANS ON THIS ACCOUNT: by IP, by Steam ID (ZeD's Bans with the server part, the game's own calls without)
    if card.open == "banip" or card.open == "bansid" then
        B.label(items, tr("UI_ZeD_Adm_GameBans"))
        P.banPart(items, win, st, card, r)
        return items
    end
    local bans = {}
    local steam = M.onSteam()
    if steam then
        if r.sidBan and r.sidBan ~= "" then
            bans[#bans + 1] = P.askBtn(st, card, "unbansid", function() return P.whyBan(r, "unbansid") end)
        elseif r.sid and r.sid ~= "" then
            bans[#bans + 1] = P.banBtn(st, card, "bansid", function() return P.whyBan(r, "bansid") end)
        end
    end
    local hasIp = r.ipBan ~= nil and r.ipBan ~= ""
    if hasIp then
        bans[#bans + 1] = P.askBtn(st, card, "unbanip", function() return P.whyBan(r, "unbanip") end)
    elseif (not steam) or r.direct then
        bans[#bans + 1] = P.banBtn(st, card, "banip", function() return P.whyBan(r, "banip") end)
    end
    if #bans > 0 then
        B.label(items, tr("UI_ZeD_Adm_GameBans"))
        B.sub(items, tr(M.live() and "UI_ZeD_Adm_AcctBansLine" or "UI_ZeD_Adm_GameBansLine"))
        F.flow(items, bans)
    end
    return items
end

function P.passBtn(win, st, t, card)
    local b = D.btn("upset", words(getText("IGUI_UserList_SetPassword")), function(ww)
        local text = D.fieldText(ww, "upass") or ""
        text = string.gsub(text, "\n", "")
        if U.setPassword(card.user, text) then
            D.setField(ww, "upass", "")
            card.open = nil
            D.flash(t, tr("UI_ZeD_Adm_UserSent"))
            U.bump()
            D.focusId(ww, st, "tk:upass")
        end
    end, "primary", tr("UI_ZeD_Adm_HelpUserSetPass"))
    local r = U.row(card.user)
    local why = r and P.whyAccount(r) or nil
    if why then D.disable(b, why)
    elseif (D.fieldText(win, "upass") or "") == "" then D.disable(b, tr("UI_ZeD_Adm_WritePass")) end
    return b
end

function P.closePass(win, st, card)
    D.setField(win, "upass", "")
    card.open = nil
    U.bump()
    D.focusId(win, st, "tk:upass")
end

TC.kinds.user = {
    data = function(card) return U.row(card.user) end,
    tick = function(win)
        U.watch()
        -- the password box stars what is typed (the game's own UITextBox2.setMasked, javap). The box is made on its first
        -- draw, so this looks each frame until it is set
        local inner = D.fieldInner(D.fieldOf(win, "upass"))
        if inner and not inner._zedMasked then
            local ok = pcall(function() inner:setMasked(true) end)
            if ok then inner._zedMasked = true end
        end
    end,
    key = function(t, card) return table.concat({ tostring(U.seq), tostring(M.seq), tostring(card.open), tostring(card.len) }, ":") end,
    title = function(card) return card.user end,
    gone = function(card) return tr("UI_ZeD_Adm_UserGone", card.user) end,
    flag = function(panel, win, t, card, data, x, y, w, bar)
        local name = data and data.role
        if name then
            F.drawTag(panel, x + w - ZeD.T.px(10) - F.tagW(name), y - bar + math.floor((bar - ZeD.T.px(16)) / 2), name, F.roleColor(name), false)
        end
        return 0
    end,
    help = function(t, card)
        if t.confirm then return tr(P.ASK[t.confirm.kind].help) end
        if card.open == "pass" then return tr("UI_ZeD_Adm_HelpUserSetPass") end
        if card.open == "banip" or card.open == "bansid" then return tr(P.ASK[card.open].help) end
        return tr("UI_ZeD_Adm_HelpUserCard", card.user)
    end,
    items = function(win, st, t, card, data) return P.userItems(win, st, t, card, data) end,
    foot = function(win, st, t, card, data)
        local c = t.confirm
        if c then
            local a = P.ASK[c.kind]
            return { question = tr(a.ask, card.user), main = {
                D.btn("cno", tr("UI_ZeD_Tk_KeepIt"), function(ww)
                    t.confirm = nil
                    D.focusId(ww, st, c.from)
                end, nil, tr("UI_ZeD_Adm_HelpKeepUser")),
                D.btn("cyes", words(getText(a.btn)), function(ww)
                    t.confirm = nil
                    local r = U.row(card.user)
                    local why = nil
                    if r and (c.kind == "del" or c.kind == "pass" or c.kind == "totp") then why = P.whyAccount(r)
                    elseif r then why = P.whyBan(r, c.kind) end
                    if not r or why then
                        D.flash(t, why or tr("UI_ZeD_Adm_UserGone", card.user))
                        return
                    end
                    if c.kind == "unbanip" or c.kind == "unbansid" then
                        F.act(ww, st, function(cb) U.unban(c.kind, r, cb) end, tr("UI_ZeD_Adm_Unbanned", card.user), function() U.readAt = nil end)
                    elseif U.act(c.kind, r) then
                        D.flash(t, tr("UI_ZeD_Adm_UserSent"))
                    end
                    U.bump()
                    D.focusId(ww, st, c.from)
                end, a.danger and "danger" or "primary", tr(a.help)) } }
        end
        if card.open == "pass" then
            return { main = { P.passBtn(win, st, t, card) } }
        end
        return { main = {} }
    end,
    padX = function(win, st, t, card)
        if t.confirm or card.open ~= "pass" then return nil end
        local b = P.passBtn(win, st, t, card)
        return { label = b.label, run = b.run, disabled = b.disabled, why = b.why }
    end,
    cancel = function(win, st, t, card)
        if t.confirm then
            local from = t.confirm.from
            t.confirm = nil
            D.focusId(win, st, from)
            return true
        end
        if card.open == "pass" then
            P.closePass(win, st, card)
            return true
        end
        if card.open == "banip" or card.open == "bansid" then
            P.closeBan(win, st, card)
            return true
        end
        return false
    end,
    back = function(win, st, t, card) D.setField(win, "upass", "") end,
}

-- ---------------------------------------------------------------------------
-- THE ADMIN TAB'S ROW
-- ---------------------------------------------------------------------------
function AU.homeRow(L, st, win)
    L[#L + 1] = { k = "head", text = tr("UI_ZeD_Adm_Users") }
    local c = F.gate({ id = "sum:users", help = tr("UI_ZeD_Adm_UsersSum"), run = function(ww) AU.open(ww, st) end }, "SeeNetworkUsers")
    L[#L + 1] = { k = "tk", t = "arow", win = win, left = tr("UI_ZeD_Adm_UsersSum"), leftMin = 400, chev = true, c = c }
end

-- ---------------------------------------------------------------------------
-- QA
-- ---------------------------------------------------------------------------
function AU.qaOpen(win, st, kind, user)
    st.card = nil
    if kind == "users" then AU.open(win, st)
    elseif kind == "user" then
        AU.open(win, st)
        AU.openUser(win, st, user)
    end
end

return AU
