-- ZeD-UI/42/media/lua/client/ZeD/ZeD_StatsCards.lua
-- ============================================================================
-- A PLAYER'S STATS AND INVENTORY IN CARDS - client. The game's two windows become two card kinds on the ticket cards'
-- engine (ZeD_TicketCards.lua), in the Admin tab:
--   pstats  the game's Player Stats window (ISPlayerStatsUI) and its pop-ups: names, profession, weight, role, traits,
--           skills and XP, warning points, the user logs, and Manage Inventory. Another player's or your own.
--   pinv    the game's Manage Inventory (ISPlayerStatsManageInvUI): their things as the server sends them, Remove and
--           Take in the foot, Refresh, Add item through the Spawn items card.
-- Reached from the Player card's Check stats and its Inventory row, More tools > Check your stats, a ticket's or a chat
-- line's Player card without the server part, and the game's own Check Stats (ISWorldObjectContextMenu.onCheckStats).
--
-- Every edit is the game's own call, made as its window makes it, and is gated as its window gates it: the role holds
-- CanModifyPlayerStatsInThePlayerStatsUI and the player is in the world with a role no higher than yours
-- (ISPlayerStatsUI:updateButtons, canModifyThis). On top, the capability the game's packet asks for, so a press the server
-- would drop is grayed with its reason: names, profession and role CanSeePlayersStats; warning points and a new log
-- AddUserlog, a log taken off WorkWithUserlog, reading the logs ReadUserLog; XP and skill levels AddXP (the /addxp
-- command); the inventory InspectPlayerInventory. The role's own window asks ManipulateWhitelist in place of
-- CanModifyPlayerStatsInThePlayerStatsUI; weight and traits carry only the window's gate.
--
-- The game's IsoPlayer is read into a plain table once a second (SC.read); the card draws that table. A player this client
-- has not loaded has no stats to show, as the game's window cannot open on them: the card says so and keeps the logs.
--
-- For the test scripts: SC.qaChar (username -> a stub player), SC.qaView (username -> a read, as SC.read makes it),
-- SC.qaLists (prof, role, good, bad: the pick lists), SC.qaInv (username -> the server's item table, standing in for its
-- answer), SC.qaOpen(win, st, kind, user), SC.qaPart(win, st, part, which). ZeDUI/tools/qa/admin_cards_sim.lua walks
-- both cards.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ZeD_Admin"
require "ZeD/ZeD_TicketCards"
require "ZeD/ZeD_AdminCards"

ZeD = ZeD or {}
ZeD.StatsCards = ZeD.StatsCards or {}
local SC = ZeD.StatsCards
local M = ZeD.Admin
local TC = ZeD.TicketCards
local AC = ZeD.AdminCards
local D, B = TC._D, TC._B
local F = AC._F

local READ_MS = 1000                  -- the player's object read this often while the card shows
local WEIGHT_MIN, WEIGHT_MAX = 30, 130   -- ISPlayerStatsUI.onChangeWeight
local PICK_PAGE = 12                  -- rows in one page of a pick list
local LOG_MAX = 200                   -- a log's words
local NAME_MAX = 40
local WARN_MAX = 99
local EDIT_CAP = "CanModifyPlayerStatsInThePlayerStatsUI"

local Y = {}     -- the file's helpers (a table rather than locals: Kahlua caps how many locals one chunk may hold)
SC._Y = Y

local function tr(k, ...) return ZeD.tr(k, ...) end
local function px(n) return ZeD.T.px(n) end
local function now() return getTimestampMs() end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
-- the game's words without the colon it ends a label with ("Username:")
function Y.plain(key) return (string.gsub(getText(key), "%s*:%s*$", "")) end

-- ---------------------------------------------------------------------------
-- THE PLAYER, as the game's window holds them
-- ---------------------------------------------------------------------------
-- yourself, or the player this client has loaded (getPlayerFromUsername: the game's window needs the same object)
function SC.char(user)
    if SC.qaChar then return SC.qaChar[user] end
    local p = getPlayer()
    if p and p:getUsername() == user then return p end
    return safe(function() return getPlayerFromUsername(user) end, nil)
end

-- ISPlayerStatsUI:canModifyThis: in the world (or not placed at all), and a role no higher than yours
function Y.rankWhy(char)
    if not isClient() then return nil end
    local sq = char:getCurrentSquare()
    if sq and not char:isExistInTheWorld() then return tr("UI_ZeD_St_NotInWorld") end
    local me = getPlayer()
    local theirs, mine = char:getRole(), me and me:getRole()
    if theirs and mine and theirs:getPosition() > mine:getPosition() then return tr("UI_ZeD_St_RankAbove", theirs:getName()) end
    return nil
end

-- why an edit can't go: the window's own test, then the capability its packet asks for. nil: it can
function Y.why(v, packetCap, windowCap)
    if not v.char then return tr("UI_ZeD_Adm_NotSeen") end
    windowCap = windowCap or EDIT_CAP
    if not M.can(windowCap) then return M.why(windowCap) end
    if v.rankWhy then return v.rankWhy end
    if packetCap and not M.can(packetCap) then return M.why(packetCap) end
    return nil
end

-- the skills as ISPlayerStatsUI.loadPerks lists them: every perk with a parent, its level, XP in the level, boost, multiplier
function Y.skills(char)
    local out = {}
    local xp = char:getXp()
    for i = 0, Perks.getMaxIndex() - 1 do
        local id = Perks.fromIndex(i)
        local perk = PerkFactory.getPerk(id)
        if perk and perk:getParent() ~= Perks.None then
            local lv = char:getPerkLevel(id)
            local prev = safe(function() return ISSkillProgressBar.getPreviousXpLvl(perk, lv) end, nil) or perk:getTotalXpForLevel(lv)
            local inLv = math.floor((xp:getXP(id) - prev) * 100 + 0.5) / 100
            local boost = xp:getPerkBoost(id)
            out[#out + 1] = { perk = id, def = perk, id = tostring(id), lv = lv, xp = inLv, xpTo = perk:getXpForLevel(lv + 1),
                name = perk:getName() .. " (" .. PerkFactory.getPerkName(perk:getParent()) .. ")",
                boost = (boost == 1 and "75%") or (boost == 2 and "100%") or (boost == 3 and "125%") or "50%",
                mult = xp:getMultiplier(id) }
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

-- the traits as ISPlayerStatsUI.loadTraits shows them: those with a picture
function Y.traits(char)
    local out = {}
    local known = char:getCharacterTraits():getKnownTraits()
    for i = 0, known:size() - 1 do
        local def = CharacterTraitDefinition.getCharacterTraitDefinition(known:get(i))
        if def and def:getTexture() then
            out[#out + 1] = { type = def:getType(), id = tostring(def:getType()), label = def:getLabel(), desc = def:getDescription(), cost = def:getCost() }
        end
    end
    return out
end

-- one read of everything the card shows. Each part on its own guard: a call another build lacks leaves that part out
function SC.read(user)
    local char = SC.char(user)
    local v = { user = user, char = char }
    if not char then return v end
    v.display = safe(function() return char:getDisplayName() end, "")
    local desc = safe(function() return char:getDescriptor() end, nil)
    if desc then
        v.fore = safe(function() return desc:getForename() end, "")
        v.sur = safe(function() return desc:getSurname() end, "")
        v.prof = safe(function() return desc:getCharacterProfession() end, nil)
        local def = v.prof and safe(function() return CharacterProfessionDefinition.getCharacterProfessionDefinition(v.prof) end, nil)
        v.profName = def and safe(function() return def:getUIName() end, nil) or ""
    end
    v.survived = safe(function() return char:getTimeSurvived() end, "")
    v.kills = safe(function() return char:getZombieKills() end, 0)
    v.weight = safe(function() return math.floor(char:getNutrition():getWeight()) end, nil)
    v.role = safe(function() return char:getRole():getName() end, nil)
    v.rankWhy = safe(function() return Y.rankWhy(char) end, nil)
    v.traits = safe(function() return Y.traits(char) end, {})
    v.skills = safe(function() return Y.skills(char) end, {})
    return v
end

-- the card's read, again once a second or straight after an edit
function Y.view(card)
    if SC.qaView and SC.qaView[card.user] then
        card.view = SC.qaView[card.user]
        return card.view
    end
    local t = now()
    if card.view and not card.stale and card.readAt and t - card.readAt < READ_MS then return card.view end
    card.readAt, card.stale = t, nil
    local v = SC.read(card.user)
    local sig = Y.sig(v)
    if sig ~= card.sig then
        card.sig = sig
        M.bump()
    end
    card.view = v
    return v
end

function Y.sig(v)
    local parts = { tostring(v.char ~= nil), tostring(v.display), tostring(v.fore), tostring(v.sur), tostring(v.profName), tostring(v.weight),
        tostring(v.role), tostring(v.rankWhy), tostring(v.kills) }
    for _, x in ipairs(v.traits or {}) do parts[#parts + 1] = x.id end
    for _, s in ipairs(v.skills or {}) do parts[#parts + 1] = s.id .. "=" .. tostring(s.lv) .. "/" .. tostring(s.xp) end
    return table.concat(parts, "|")
end

-- the warning points, as the game's window sums them from the logs; else the game's user list's count
function Y.warnings(user)
    local logs = M.logs[user]
    if logs then
        local n = 0
        for _, l in ipairs(logs) do
            if l.type == "WarningPoint" then n = n + (tonumber(l.amount) or 0) end
        end
        return n
    end
    local r = M.row(user)
    return r and r.warn or nil
end

function Y.adminLogType()
    return safe(function() return UserlogType.AdminLog:toString() end, "AdminLog")
end

-- ---------------------------------------------------------------------------
-- THE EDITS: each the game's own call, as its window makes it
-- ---------------------------------------------------------------------------
local DO = {}
Y.DO = DO

function DO.name(char, which, text)
    if which == "Forename" then char:getDescriptor():setForename(text)
    elseif which == "Surname" then char:getDescriptor():setSurname(text)
    else char:setDisplayName(text) end
    sendPlayerStatsChange(char)
end

function DO.prof(char, prof)
    char:getDescriptor():setCharacterProfession(prof)
    sendPlayerStatsChange(char)
end

function DO.role(char, name)
    char:setRole(name)
    sendPlayerStatsChange(char)
end

-- (the server's own command, with no capability of its own: the window's rule is the only gate)
function DO.weight(char, w)
    if isClient() then
        sendClientCommand(getPlayer(), "player", "setWeight", { weight = w, id = char:getOnlineID() })
    else
        char:getNutrition():setWeight(w)
    end
end

function DO.addTrait(char, ty)
    char:getCharacterTraits():add(ty)
    char:modifyTraitXPBoost(ty, false)
    SyncXp(char)
end

function DO.removeTrait(char, ty)
    char:getCharacterTraits():remove(ty)
    char:modifyTraitXPBoost(ty, true)
    SyncXp(char)
end

-- ISPlayerStatsUI.onAddXP: the server's /addxp, and the same XP on this client's copy
function DO.xp(char, perk, amount, mult)
    if isClient() then
        SendCommandToServer("/addxp \"" .. char:getUsername() .. "\" " .. tostring(perk) .. "=" .. tostring(amount) .. (mult and " -true" or " -false"))
    end
    char:getXp():AddXP(perk, amount, false, mult == true, false, false)
end

-- LEVELPERK and LOWERPERK: the XP to the next level's start, or back to this level's
function DO.level(char, s, dir)
    local lv = math.max(0, math.min(10, char:getPerkLevel(s.perk) + dir))
    local amount = s.perk:getTotalXpForLevel(lv) - char:getXp():getXP(s.perk)
    DO.xp(char, s.perk, amount, false)
end

function DO.warn(user, reason, n)
    addWarningPoint(user, reason, n)
    requestUserlog(user)
end

function DO.addLog(user, text)
    addUserlog(user, Y.adminLogType(), text)
    requestUserlog(user)
end

function DO.removeLog(user, l)
    removeUserlog(user, l.type, l.text)
    requestUserlog(user)
end

-- a press: the gate asked again (the player can leave, a role can change, while the foot was up), then the call
function Y.run(win, st, card, why, fn, done)
    local t = TC.qaState(st)
    if why then
        D.flash(t, why)
        return false
    end
    local ok, err = pcall(fn)
    if not ok then
        ZeD.logOnce("stats card: edit", err)
        D.flash(t, tr("UI_ZeD_Cl_NoAnswer"))
        return false
    end
    card.stale = true
    M.bump()
    if done then D.flash(t, done) end
    return true
end

-- ---------------------------------------------------------------------------
-- OPENING
-- ---------------------------------------------------------------------------
--- open the stats card on a user in the Admin tab's window (from: the focus to land on when the card closes)
function SC.openStats(win, st, user, from)
    for _, k in ipairs({ "sname", "sweight", "sxp", "sreason", "slog", "spfind" }) do D.setField(win, k, "") end
    F.push(win, st, { kind = "pstats", user = user, from = from or "adm:tk:p:" .. tostring(user), good = true, page = 1, xpMult = true, warnN = 1 })
    M.loadLog(user)
end

function Y.closePart(win, st, card, focus)
    card.open, card.pick, card.which = nil, nil, nil
    card.page, card.find = 1, ""
    D.setField(win, "spfind", "")
    local t = TC.qaState(st)
    t.confirm = nil
    D.focusId(win, st, focus or "tk:back")
    M.bump()
end

-- part: "name" (which: Display, Forename, Surname), "weight", "prof", "role", "trait", "xp", "warn", "log"
function Y.openPart(win, st, card, part, which, focus)
    local v = card.view or {}
    card.open, card.which, card.pick = part, which, nil
    card.page, card.find, card.warnN = 1, "", 1
    D.setField(win, "spfind", "")
    local box = D.fieldOf(win, "spfind")
    if box then box._lastText = "" end
    if part == "name" then
        local seed = (which == "Forename" and v.fore) or (which == "Surname" and v.sur) or v.display or ""
        card.seed = seed
        D.setField(win, "sname", seed)
    elseif part == "weight" then
        card.seed = v.weight and tostring(v.weight) or ""
        D.setField(win, "sweight", card.seed)
    elseif part == "xp" then
        D.setField(win, "sxp", "1")
    elseif part == "warn" then
        D.setField(win, "sreason", "")
    elseif part == "log" then
        D.setField(win, "slog", "")
    end
    TC.qaState(st).confirm = nil
    D.focusId(win, st, focus)
    M.bump()
end

-- ---------------------------------------------------------------------------
-- THE STATS CARD
-- ---------------------------------------------------------------------------
-- a fact with Change at its end (the window's buttons beside each value)
function Y.fact(items, label, value, c) B.fact(items, label, value ~= nil and tostring(value) or "", c) end

function Y.change(win, st, card, id, part, which, why, help)
    return F.gate({ id = id, text = getText("IGUI_PlayerStats_Change"), help = help or tr("UI_ZeD_St_HelpChange"),
        run = function(ww) Y.openPart(ww, st, card, part, which, (part == "prof" or part == "role") and "tk:pk:1" or ("tk:f:" .. ((part == "weight") and "sweight" or "sname"))) end },
        nil, function() return why() end)
end

function Y.whyName(v) return Y.why(v, "CanSeePlayersStats") end

function Y.facts(items, win, st, card, v)
    Y.fact(items, Y.plain("IGUI_PlayerStats_Username"), card.user)
    if not v.char then
        B.sub(items, tr("UI_ZeD_Adm_NotSeen"))
        return
    end
    local function nameWhy() return Y.whyName(card.view or v) end
    Y.fact(items, Y.plain("IGUI_PlayerStats_DisplayName"), v.display, Y.change(win, st, card, "c:disp", "name", "Display", nameWhy))
    Y.fact(items, getText("UI_characreation_forename"), v.fore, Y.change(win, st, card, "c:fore", "name", "Forename", nameWhy))
    Y.fact(items, getText("UI_characreation_surname"), v.sur, Y.change(win, st, card, "c:sur", "name", "Surname", nameWhy))
    if card.open == "name" then Y.namePart(items, win, st, card) end
    Y.fact(items, Y.plain("IGUI_PlayerStats_Profession"), v.profName, Y.change(win, st, card, "c:prof", "prof", nil, nameWhy))
    if card.open == "prof" then Y.profPart(items, win, st, card, v) end
    Y.fact(items, getText("IGUI_char_Survived_For"), v.survived)
    Y.fact(items, getText("IGUI_char_Zombies_Killed"), v.kills)
    Y.fact(items, getText("IGUI_char_Weight"), v.weight, Y.change(win, st, card, "c:wt", "weight", nil, function() return Y.why(card.view or v) end))
    if card.open == "weight" then Y.weightPart(items, win, st, card) end
    if isClient() then
        Y.fact(items, tr("UI_ZeD_Adm_Role"), v.role, Y.change(win, st, card, "c:role", "role", nil,
            function() return Y.why(card.view or v, "CanSeePlayersStats", "ManipulateWhitelist") end))
        if card.open == "role" then Y.rolePart(items, win, st, card, v) end
    end
end

function Y.nameWord(which)
    if which == "Forename" then return getText("UI_characreation_forename") end
    if which == "Surname" then return getText("UI_characreation_surname") end
    return Y.plain("IGUI_PlayerStats_DisplayName")
end

function Y.namePart(items, win, st, card)
    F.inset(items, nil, function()
        B.label(items, Y.nameWord(card.which))
        F.field(items, "sname", 1, Y.nameWord(card.which), true, NAME_MAX)
        items[#items].seed = card.seed     -- (the box is made on its first frame: it starts with the name)
    end)
end

function Y.weightPart(items, win, st, card)
    F.inset(items, nil, function()
        B.label(items, getText("IGUI_char_Weight"), tr("UI_ZeD_St_WeightRange", WEIGHT_MIN, WEIGHT_MAX))
        F.field(items, "sweight", 1, tr("UI_ZeD_St_WeightRange", WEIGHT_MIN, WEIGHT_MAX), true, 3)
        items[#items].seed = card.seed
    end)
end

-- a list to pick from, in the card: rows, a page at a time. list: { id, label, sub, on }
function Y.pickRows(items, win, st, card, list, find)
    if find then
        items[#items + 1] = { k = "afind", key = "spfind", hint = find, start = card.find or "",
            onText = function(_, text)
                card.find = text
                card.page = 1
                M.bump()
            end,
            c = { id = "f:spfind", help = find, run = function(ww) D.useField(ww, "spfind") end } }
        local q = string.lower(ZeD.Tk.clean(card.find) or "")
        if q ~= "" then
            local keep = {}
            for _, r in ipairs(list) do
                if string.find(string.lower(r.label), q, 1, true) then keep[#keep + 1] = r end
            end
            list = keep
        end
    end
    local pages = math.max(1, math.ceil(#list / PICK_PAGE))
    card.page = math.max(1, math.min(card.page or 1, pages))
    local from = (card.page - 1) * PICK_PAGE
    for i = 1, math.min(PICK_PAGE, #list - from) do
        local r = list[from + i]
        local pick = r
        items[#items + 1] = { k = "arow", left = r.label, leftMin = 120, right = r.right, sub = r.sub, on = card.pick ~= nil and card.pick.id == r.id,
            c = { id = "pk:" .. tostring(i), land = i == 1, help = r.help or tr("UI_ZeD_St_HelpPick"),
                run = function(ww)
                    card.pick = pick
                    D.focusId(ww, st, "tk:sgo")
                    M.bump()
                end } }
    end
    if #list == 0 then B.sub(items, tr("UI_ZeD_St_NoMatch")) end
    if pages > 1 then
        local n = card.page
        F.flow(items, {
            F.gate({ id = "pprev", text = tr("UI_ZeD_Tk_Prev"), run = function() card.page = n - 1; M.bump() end }, nil, function()
                if n <= 1 then return tr("UI_ZeD_Tk_FirstPage") end
                return nil
            end),
            { style = "text", text = tr("UI_ZeD_Tk_PageOf", n, pages) },
            F.gate({ id = "pnext", text = tr("UI_ZeD_Tk_Next"), run = function() card.page = n + 1; M.bump() end }, nil, function()
                if n >= pages then return tr("UI_ZeD_Tk_LastPage") end
                return nil
            end),
        })
    end
end

-- ISPlayerStatsChooseProfessionUI: every profession, unemployed first, then by name
function Y.profList(v)
    if SC.qaLists then return SC.qaLists.prof end
    local out = {}
    pcall(function()
        local list = CharacterProfessionDefinition.getProfessions()
        for i = 0, list:size() - 1 do
            local d = list:get(i)
            out[#out + 1] = { id = tostring(d:getType()), type = d:getType(), label = d:getUIName(), help = F.plainTip(d:getDescription()),
                first = d:getType() == CharacterProfession.UNEMPLOYED, right = (d:getType() == v.prof) and tr("UI_ZeD_St_Now") or nil }
        end
    end)
    table.sort(out, function(a, b)
        if a.first ~= b.first then return a.first end
        return a.label < b.label
    end)
    return out
end

function Y.profPart(items, win, st, card, v)
    F.inset(items, nil, function()
        B.label(items, getText("IGUI_PlayerStats_ChangeProfTitle"))
        Y.pickRows(items, win, st, card, Y.profList(v))
    end)
end

-- ISPlayerStatsChooseAccessLevelUI: the roles up to your own
function Y.roleList(v)
    if SC.qaLists then return SC.qaLists.role end
    local out = {}
    local me = getPlayer()
    local mine = safe(function() return me:getRole():getPosition() end, -1)
    pcall(function()
        local roles = getRoles()
        for i = 0, roles:size() - 1 do
            local r = roles:get(i)
            if r:getPosition() <= mine then
                out[#out + 1] = { id = r:getName(), label = r:getName(), help = r:getDescription(), right = (r:getName() == v.role) and tr("UI_ZeD_St_Now") or nil }
            end
        end
    end)
    return out
end

function Y.rolePart(items, win, st, card, v)
    F.inset(items, nil, function()
        B.label(items, tr("UI_ZeD_Adm_Role"))
        B.sub(items, tr("UI_ZeD_St_RoleLine"))
        Y.pickRows(items, win, st, card, Y.roleList(v))
    end)
end

-- ISPlayerStatsChooseTraitUI: the traits they don't have, good (cost 0 and up) or bad
function Y.traitList(v, good)
    if SC.qaLists then return good and SC.qaLists.good or SC.qaLists.bad end
    local out = {}
    local char = v.char
    pcall(function()
        local list = CharacterTraitDefinition.getTraits()
        for i = 0, list:size() - 1 do
            local d = list:get(i)
            if not char:hasTrait(d:getType()) and ((d:getCost() >= 0) == good) then
                out[#out + 1] = { id = tostring(d:getType()), type = d:getType(), label = d:getLabel(), help = F.plainTip(d:getDescription()) }
            end
        end
    end)
    table.sort(out, function(a, b) return a.label < b.label end)
    return out
end

function Y.traits_(items, win, st, card, v)
    local list = v.traits or {}
    B.label(items, getText("IGUI_char_Traits"), tostring(#list))
    if #list == 0 then B.sub(items, tr("UI_ZeD_St_NoTraits")) end
    local t = TC.qaState(st)
    for i, x in ipairs(list) do
        local trait = x
        items[#items + 1] = { k = "arow", left = x.label, leftMin = 120, sub = F.plainTip(x.desc),
            ctl = F.gate({ id = "tr:" .. tostring(i), text = getText("ContextMenu_Remove"), help = tr("UI_ZeD_St_HelpRemove"),
                run = function(ww)
                    t.confirm = { act = "rmtrait", trait = trait, from = "tk:tr:" .. tostring(i) }
                    D.focusId(ww, st, "tk:sno")
                    M.bump()
                end }, nil, function() return Y.why(card.view or v) end) }
    end
    F.flow(items, { F.gate({ id = "addtrait", text = getText("IGUI_PlayerStats_AddTrait"), help = getText("IGUI_PlayerStats_AddTraitTooltip"),
        run = function(ww) Y.openPart(ww, st, card, "trait", nil, "tk:tg:good") end }, nil, function() return Y.why(card.view or v) end) })
    if card.open == "trait" then
        F.inset(items, nil, function()
            B.label(items, getText("IGUI_PlayerStats_AddTraitTitle"))
            B.sub(items, getText("IGUI_PlayerStats_AddTraitTooltip"))
            F.flow(items, {
                { id = "tg:good", style = "chip", text = tr("UI_ZeD_St_GoodTraits"), on = card.good,
                  run = function() card.good, card.pick, card.page = true, nil, 1; M.bump() end },
                { id = "tg:bad", style = "chip", text = tr("UI_ZeD_St_BadTraits"), on = not card.good,
                  run = function() card.good, card.pick, card.page = false, nil, 1; M.bump() end },
            })
            Y.pickRows(items, win, st, card, Y.traitList(v, card.good), tr("UI_ZeD_St_FindTrait"))
        end)
    end
end

-- a skill: its name, a line of the window's columns, Level Down and Level Up
TC.items.sskill = {
    layout = function(win, it, w)
        local T, tm = ZeD.T, ZeD.TM
        for _, c in ipairs(it.ctls) do c.w, c.h = ZeD.Molecules.buttonW(c.text), T.buttonH - px(4) end
        local top = math.max(it.ctls[1].h, tm:getFontHeight(T.fontF2))
        if it.wrapW ~= w then
            it.wrapW = w
            it.lines = D.wrap(it.meta, T.fontF3, math.max(1, w))
        end
        it.topH = top
        return top + #it.lines * tm:getFontHeight(T.fontF3) + px(6)
    end,
    draw = function(panel, win, t, it, x, dy, w, mx, my, ctx)
        local T, A = ZeD.T, ZeD.Atoms
        local rx = x + w
        for i = #it.ctls, 1, -1 do
            local c = it.ctls[i]
            rx = rx - c.w
            F.drawCtl(panel, win, t, c, rx, dy, mx, my, ctx)
            c.sx = rx
            rx = rx - px(4)
        end
        local pipW = math.min(px(70), math.floor(w * 0.25))
        rx = rx - px(4) - pipW
        A.drawSegBar(panel, rx, dy + math.floor((it.topH - px(8)) / 2), pipW, px(8), 10, it.lv, T.accent, T.surf3 or T.borderS, 1)
        local tc = T.text
        local name = A.truncateText(it.name, T.fontF2, math.max(px(20), rx - x - px(6)))
        panel:drawText(name, x, dy + math.floor((it.topH - ZeD.TM:getFontHeight(T.fontF2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        local dc = T.textDim
        local f3h = ZeD.TM:getFontHeight(T.fontF3)
        for i, s in ipairs(it.lines or {}) do
            panel:drawText(s, x, dy + it.topH + px(2) + (i - 1) * f3h, dc.r, dc.g, dc.b, dc.a or 1, T.fontF3)
        end
        A.drawDividerH(panel, x, dy + it.h - T.hair, w, false)
    end,
    stops = function(it, x0, dy, w, add)
        for _, c in ipairs(it.ctls) do add(c, c.sx or (x0 + w - px(60)), dy, c.w, c.h, it.y) end
    end,
}

function Y.skillMeta(s)
    local xp = (s.xpTo == -1) and tr("UI_ZeD_St_XpMax") or (tostring(s.xp) .. "/" .. tostring(s.xpTo))
    return table.concat({ getText("IGUI_PlayerStats_Level") .. " " .. tostring(s.lv), getText("IGUI_PlayerStats_XP") .. " " .. xp,
        getText("IGUI_PlayerStats_Boost") .. " " .. s.boost, getText("IGUI_PlayerStats_Multiplier") .. " " .. tostring(s.mult) }, " | ")
end

function Y.skills_(items, win, st, card, v)
    local list = v.skills or {}
    local shown = 0
    for _, s in ipairs(list) do
        if s.lv > 0 or s.xp > 0 or card.allSkills then shown = shown + 1 end
    end
    B.label(items, tr("UI_ZeD_Adm_Skills"), getText("IGUI_PlayerStats_LevelUp") .. ", " .. getText("IGUI_PlayerStats_LevelDown"))
    local t = TC.qaState(st)
    local function xpWhy() return Y.why(card.view or v, "AddXP") end
    for _, s in ipairs(list) do
        if s.lv > 0 or s.xp > 0 or card.allSkills then
            local sk = s
            items[#items + 1] = { k = "sskill", name = s.name, lv = s.lv, meta = Y.skillMeta(s), ctls = {
                F.gate({ id = "sd:" .. s.id, text = "-", help = getText("IGUI_PlayerStats_LevelDown"),
                    run = function(ww)
                        local cv = Y.view(card)
                        Y.run(ww, st, card, Y.why(cv, "AddXP"), function() DO.level(cv.char, sk, -1) end, tr("UI_ZeD_Adm_SkillDone", sk.name))
                    end }, nil, function()
                        if sk.lv <= 0 then return tr("UI_ZeD_Adm_SkillLeast") end
                        return xpWhy()
                    end),
                F.gate({ id = "su:" .. s.id, text = "+", help = getText("IGUI_PlayerStats_LevelUp"),
                    run = function(ww)
                        local cv = Y.view(card)
                        Y.run(ww, st, card, Y.why(cv, "AddXP"), function() DO.level(cv.char, sk, 1) end, tr("UI_ZeD_Adm_SkillDone", sk.name))
                    end }, nil, function()
                        if sk.lv >= 10 then return tr("UI_ZeD_Adm_SkillMost") end
                        return xpWhy()
                    end),
            } }
        end
    end
    if shown == 0 then B.sub(items, tr("UI_ZeD_Adm_NoSkills")) end
    F.flow(items, {
        { id = "allskills", style = "chip", text = tr("UI_ZeD_Adm_AllSkills"), on = card.allSkills, help = tr("UI_ZeD_Adm_HelpAllSkills"),
          run = function() card.allSkills = not card.allSkills; M.bump() end },
        F.gate({ id = "addxp", text = getText("IGUI_PlayerStats_AddXP"), help = tr("UI_ZeD_St_HelpAddXp"),
            run = function(ww) Y.openPart(ww, st, card, "xp", nil, "tk:f:spfind") end }, nil, xpWhy),
    })
    if card.open == "xp" then
        F.inset(items, nil, function()
            B.label(items, getText("IGUI_PlayerStats_AddXPTitle"))
            local rows = {}
            for _, s in ipairs(list) do rows[#rows + 1] = { id = s.id, label = s.name, perk = s.perk } end
            Y.pickRows(items, win, st, card, rows, tr("UI_ZeD_St_FindSkill"))
            B.label(items, getText("IGUI_PlayerStats_Amount"))
            F.field(items, "sxp", 1, tr("UI_ZeD_St_XpAmount"), nil, 7)
            items[#items].seed = "1"
            items[#items + 1] = { k = "atick", text = getText("IGUI_PlayerStats_AddXPMultipliers"),
                c = { id = "xpmult", on = card.xpMult, help = getText("IGUI_PlayerStats_AddXPMultipliers"),
                      run = function() card.xpMult = not card.xpMult; M.bump() end } }
        end)
    end
end

function Y.warn_(items, win, st, card, v)
    local n = Y.warnings(card.user)
    Y.fact(items, Y.plain("IGUI_PlayerStats_WarningPts"), (n ~= nil) and tostring(n) or M.why("ReadUserLog"),
        F.gate({ id = "addwarn", text = getText("IGUI_PlayerStats_Add"), help = tr("UI_ZeD_Adm_HelpWarn"),
            run = function(ww) Y.openPart(ww, st, card, "warn", nil, "tk:f:sreason") end }, nil, function() return Y.why(card.view or v, "AddUserlog") end))
    if card.open ~= "warn" then return end
    F.inset(items, "warning", function()
        B.label(items, getText("IGUI_PlayerStats_WarningPointTitle"))
        F.flow(items, {
            F.gate({ id = "wm", text = "-", run = function() card.warnN = card.warnN - 1; M.bump() end }, nil, function()
                if card.warnN <= 1 then return tr("UI_ZeD_Adm_WarnLeast") end
                return nil
            end),
            { style = "text", text = tostring(card.warnN), tone = "text" },
            F.gate({ id = "wp", text = "+", run = function() card.warnN = card.warnN + 1; M.bump() end }, nil, function()
                if card.warnN >= WARN_MAX then return tr("UI_ZeD_Adm_WarnMost", WARN_MAX) end
                return nil
            end),
        })
        B.label(items, tr("UI_ZeD_Adm_Reason"), tr("UI_ZeD_Adm_TheySee", card.user))
        F.field(items, "sreason", 2, tr("UI_ZeD_Adm_ReasonHint"), true, LOG_MAX)
    end)
end

function Y.logs_(items, win, st, card, v)
    local list = M.logs[card.user] or {}
    B.label(items, getText("IGUI_PlayerStats_UserLogs"), tostring(#list))
    if not M.can("ReadUserLog") then
        B.sub(items, M.why("ReadUserLog"))
    elseif #list == 0 then
        B.sub(items, tr("UI_ZeD_Adm_NothingLogged"))
    end
    local t = TC.qaState(st)
    for i, l in ipairs(list) do
        local log = l
        local head = tostring(l.type) .. " | " .. tostring(l.by) .. ((tonumber(l.amount) or 0) ~= 0 and (" | " .. tostring(l.amount)) or "")
        items[#items + 1] = { k = "arow", left = head, leftMin = 120, sub = tostring(l.text or ""),
            ctl = F.gate({ id = "lg:" .. tostring(i), text = getText("ContextMenu_Remove"), help = getText("IGUI_PlayerStats_RemoveLogConfirm"),
                run = function(ww)
                    t.confirm = { act = "rmlog", log = log, from = "tk:lg:" .. tostring(i) }
                    D.focusId(ww, st, "tk:sno")
                    M.bump()
                end }, nil, function() return Y.why(card.view or v, "WorkWithUserlog") end) }
    end
    F.flow(items, { F.gate({ id = "addlog", text = getText("IGUI_PlayerStats_AddLog"), help = getText("IGUI_PlayerStats_AddLogOn", card.user),
        run = function(ww) Y.openPart(ww, st, card, "log", nil, "tk:f:slog") end }, nil, function() return Y.why(card.view or v, "AddUserlog") end) })
    if card.open == "log" then
        F.inset(items, nil, function()
            B.label(items, getText("IGUI_PlayerStats_AddLogOn", card.user))
            F.field(items, "slog", 2, tr("UI_ZeD_St_LogHint"), true, LOG_MAX)
        end)
    end
end

function Y.statsItems(win, st, t, card, v)
    local items = {}
    Y.facts(items, win, st, card, v)
    if v.char then
        Y.traits_(items, win, st, card, v)
        Y.skills_(items, win, st, card, v)
    end
    Y.warn_(items, win, st, card, v)
    Y.logs_(items, win, st, card, v)
    B.label(items, tr("UI_ZeD_Adm_Inventory"))
    items[#items + 1] = { k = "arow", left = getText("IGUI_PlayerStats_ManageInventory", card.user), leftMin = 300, chev = true,
        c = F.gate({ id = "inv", help = tr("UI_ZeD_Adm_HelpInvCard"),
            run = function(ww) SC.openInv(ww, st, card.user, nil, "tk:inv") end }, "InspectPlayerInventory") }
    return items
end

-- what the foot says and does while a part or a confirm is open
function Y.textOf(win, key) return ZeD.Tk.clean(D.fieldText(win, key)) or "" end

-- what an open part or confirm would do: { q, go, variant, why, run, done, back }, or nil with none open. Built again on
-- the press from a fresh read, so what goes is what holds then
function Y.plan(win, st, t, card, v)
    local c = t.confirm
    local P = { back = "tk:back", variant = "primary" }
    if c and c.act == "rmtrait" then
        P.q, P.go, P.variant, P.back = tr("UI_ZeD_St_TraitRemoveAsk", c.trait.label), getText("ContextMenu_Remove"), "danger", c.from
        P.why = Y.why(v)
        P.done = tr("UI_ZeD_St_TraitRemoved", c.trait.label)
        P.run = function() DO.removeTrait(v.char, c.trait.type) end
    elseif c and c.act == "rmlog" then
        P.q, P.go, P.variant, P.back = getText("IGUI_PlayerStats_RemoveLogConfirm"), getText("ContextMenu_Remove"), "danger", c.from
        P.why = Y.why(v, "WorkWithUserlog")
        P.done = tr("UI_ZeD_St_LogRemoved")
        P.run = function() DO.removeLog(card.user, c.log) end
    elseif card.open == "name" then
        local text = Y.textOf(win, "sname")
        local was = (card.which == "Forename" and v.fore) or (card.which == "Surname" and v.sur) or v.display
        local word = Y.nameWord(card.which)
        P.go, P.back = getText("IGUI_RolesList_Save"), "tk:c:" .. ((card.which == "Forename" and "fore") or (card.which == "Surname" and "sur") or "disp")
        P.why = Y.whyName(v) or ((text == "") and tr("UI_ZeD_St_NameEmpty")) or ((text == was) and getText("IGUI_PlayerStats_SameName", word)) or nil
        P.done = tr("UI_ZeD_St_NameDone", word)
        P.run = function() DO.name(v.char, card.which, text) end
    elseif card.open == "weight" then
        local w = tonumber(Y.textOf(win, "sweight"))
        P.go, P.back = getText("IGUI_RolesList_Save"), "tk:c:wt"
        P.why = Y.why(v) or ((not w or w < WEIGHT_MIN or w > WEIGHT_MAX) and tr("UI_ZeD_St_WeightRange", WEIGHT_MIN, WEIGHT_MAX)) or nil
        P.done = w and tr("UI_ZeD_St_WeightDone", tostring(w)) or nil
        P.run = function() DO.weight(v.char, w) end
    elseif card.open == "prof" then
        local p = card.pick
        P.back, P.go = "tk:c:prof", getText("IGUI_PlayerStats_Change")
        P.q = p and tr("UI_ZeD_St_ProfAsk", p.label) or nil
        P.why = Y.whyName(v) or ((not p) and tr("UI_ZeD_St_PickFirst")) or ((p.type == v.prof) and tr("UI_ZeD_St_IsNow")) or nil
        P.done = p and tr("UI_ZeD_St_ProfDone", p.label) or nil
        P.run = function() DO.prof(v.char, p.type) end
    elseif card.open == "role" then
        local p = card.pick
        P.back, P.go = "tk:c:role", getText("IGUI_PlayerStats_Change")
        P.q = p and tr("UI_ZeD_St_RoleAsk", p.label) or nil
        P.why = Y.why(v, "CanSeePlayersStats", "ManipulateWhitelist") or ((not p) and tr("UI_ZeD_St_PickFirst")) or ((p.id == v.role) and tr("UI_ZeD_St_IsNow")) or nil
        P.done = p and tr("UI_ZeD_St_RoleDone", p.label) or nil
        P.run = function() DO.role(v.char, p.id) end
    elseif card.open == "trait" then
        local p = card.pick
        P.back, P.go = "tk:addtrait", getText("IGUI_PlayerStats_Add")
        P.q = p and tr("UI_ZeD_St_TraitAsk", p.label) or nil
        P.why = Y.why(v) or ((not p) and tr("UI_ZeD_St_PickFirst")) or nil
        P.done = p and tr("UI_ZeD_St_TraitAdded", p.label) or nil
        P.run = function() DO.addTrait(v.char, p.type) end
    elseif card.open == "xp" then
        local p = card.pick
        local n = tonumber(Y.textOf(win, "sxp"))
        P.back, P.go = "tk:addxp", getText("IGUI_PlayerStats_AddXP")
        P.q = (p and n and n > 0) and tr("UI_ZeD_St_XpAsk", tostring(n), p.label) or nil
        P.why = Y.why(v, "AddXP") or ((not p) and tr("UI_ZeD_St_PickFirst")) or ((not n or n <= 0) and tr("UI_ZeD_St_XpAmount")) or nil
        P.done = (p and n) and tr("UI_ZeD_St_XpDone", tostring(n), p.label) or nil
        P.run = function() DO.xp(v.char, p.perk, n, card.xpMult == true) end
    elseif card.open == "warn" then
        local reason, n = Y.textOf(win, "sreason"), card.warnN
        P.back, P.go = "tk:addwarn", tr("UI_ZeD_Adm_Add")
        P.why = Y.why(v, "AddUserlog") or ((reason == "") and tr("UI_ZeD_Adm_WriteReason")) or nil
        P.done = (n == 1) and tr("UI_ZeD_Adm_WarnDone1", card.user) or tr("UI_ZeD_Adm_WarnDone", n, card.user)
        P.run = function() DO.warn(card.user, reason, n) end
    elseif card.open == "log" then
        local text = Y.textOf(win, "slog")
        P.back, P.go = "tk:addlog", getText("IGUI_PlayerStats_AddLog")
        P.why = Y.why(v, "AddUserlog") or ((text == "") and tr("UI_ZeD_St_WriteLog")) or nil
        P.done = tr("UI_ZeD_St_LogAdded")
        P.run = function() DO.addLog(card.user, text) end
    else
        return nil
    end
    if t.busy and not P.why then P.why = tr("UI_ZeD_Tk_Busy") end
    return P
end

-- the press: planned again from a fresh read of the player
function Y.press(win, st, card)
    local t = TC.qaState(st)
    card.stale = true
    local P = Y.plan(win, st, t, card, Y.view(card))
    if not P then return end
    if P.why then
        D.flash(t, P.why)
        return
    end
    if Y.run(win, st, card, nil, P.run, P.done) then Y.closePart(win, st, card, P.back) end
end

function Y.footFor(win, st, t, card, v)
    local P = Y.plan(win, st, t, card, v)
    if not P then return nil end
    local keep = D.btn("sno", t.confirm and tr("UI_ZeD_Tk_KeepIt") or getText("UI_Cancel"), function(ww) Y.closePart(ww, st, card, P.back) end, nil, tr("UI_ZeD_St_HelpCancel"))
    local go = D.btn("sgo", P.go, function(ww) Y.press(ww, st, card) end, P.variant, P.done)
    if P.why then D.disable(go, P.why) end
    return { question = P.q, main = { keep, go } }
end
TC.kinds.pstats = {
    data = function(card) return Y.view(card) end,
    tick = function(win, st, t, card)
        M.watch()
        card.win = win
    end,
    key = function(t, card)
        return table.concat({ tostring(M.seq), tostring(card.sig), tostring(card.open), tostring(card.which), tostring(card.pick and card.pick.id),
            tostring(card.page), tostring(card.good), tostring(card.allSkills), tostring(card.xpMult), tostring(card.warnN), tostring(t.confirm) }, ":")
    end,
    title = function(card) return card.user end,
    help = function(t, card, v)
        if t.confirm then return tr("UI_ZeD_St_HelpConfirm") end
        if card.open == "prof" or card.open == "role" or card.open == "trait" then return tr("UI_ZeD_St_HelpPick") end
        if card.open then return tr("UI_ZeD_St_HelpEdit") end
        if card.user == M.me() then return tr("UI_ZeD_St_HelpOwn") end
        return tr("UI_ZeD_St_HelpCard", card.user)
    end,
    items = function(win, st, t, card, v) return Y.statsItems(win, st, t, card, v) end,
    flag = function(panel, win, t, card, v, x, y, w, bar)
        local name = v and v.role
        if name then
            F.drawTag(panel, x + w - px(10) - F.tagW(name), y - bar + math.floor((bar - px(16)) / 2), name, F.roleColor(name), false)
        end
        return 0
    end,
    foot = function(win, st, t, card, v)
        if not v then return { main = {} } end
        return Y.footFor(win, st, t, card, v) or { main = {} }
    end,
    cancel = function(win, st, t, card)
        if t.confirm then
            local from = t.confirm.from
            t.confirm = nil
            D.focusId(win, st, from or "tk:back")
            M.bump()
            return true
        end
        if card.open then
            Y.closePart(win, st, card, nil)
            return true
        end
        return false
    end,
}

-- ---------------------------------------------------------------------------
-- THE INVENTORY CARD (ISPlayerStatsManageInvUI)
-- ---------------------------------------------------------------------------
SC.inv = SC.inv or {}          -- username -> { rows, cap, max, at } as the server last sent it
SC.invAsked = SC.invAsked or nil

-- the online ID the game's window takes: from the loaded player, else the server part's card; -1 for none (the window
-- then hides its buttons)
function SC.onlineId(user, oid)
    if oid ~= nil then return oid end
    local char = SC.char(user)
    local id = char and safe(function() return char:getOnlineID() end, nil)
    if id ~= nil then return id end
    local v = M.cards[user]
    if v and v.oid then return v.oid end
    return -1
end

function SC.askInv(card)
    SC.invAsked = card.user
    card.askedAt = now()
    if SC.qaInv then
        SC.onItems(SC.qaInv[card.user])
        return
    end
    if M.qaHold then return end
    pcall(sendRequestInventory, card.id, card.user)
end

-- the server's table, as ISPlayerStatsManageInvUI.ReceiveItems reads it: weapons on their own first, then the rest. The
-- event names nobody: it is the answer to the last ask
function SC.onItems(itemtable)
    local user = SC.invAsked
    if not user or type(itemtable) ~= "table" then return end
    local keys = {}
    for k, v in pairs(itemtable) do
        if type(v) == "table" and v.fullType ~= nil then keys[#keys + 1] = k end
    end
    table.sort(keys, function(a, b)
        if type(a) == type(b) and (type(a) == "number" or type(a) == "string") then return a < b end
        return tostring(a) < tostring(b)
    end)
    local weapons, rest = {}, {}
    local weaponWord = getText("IGUI_ItemCat_Weapon")
    for _, k in ipairs(keys) do
        local v = itemtable[k]
        local full = tostring(v.fullType)
        local name = safe(function() return getItemName(full) end, nil)
        if name then
            local cat = tostring(v.cat or "")
            local catWord = (getTextOrNull and getTextOrNull("IGUI_ItemCat_" .. cat)) or cat
            local row = { id = tostring(v.itemId), itemId = v.itemId, full = full, name = name, count = tonumber(v.count) or 1, cat = catWord,
                inInv = v.inInv == true, parent = v.parrentId, hasParent = v.hasParrent == true, container = v.container,
                equip = v.isEquip == true, var = tonumber(v.var), maxCond = safe(function() return getItemConditionMax(full) end, nil) }
            row.weapon = catWord == weaponWord
            if row.weapon and not row.inInv and tonumber(row.parent) == -1 then weapons[#weapons + 1] = row else rest[#rest + 1] = row end
        end
    end
    for _, r in ipairs(rest) do weapons[#weapons + 1] = r end
    SC.inv[user] = { rows = weapons, cap = math.floor((tonumber(itemtable.capacityWeight) or 0) * 10) / 10, max = itemtable.maxWeight, at = now() }
    M.bump()
end

--- open the inventory card on a user and ask the server for their things (oid: their online ID, when known)
function SC.openInv(win, st, user, oid, from)
    local card = { kind = "pinv", user = user, from = from or "tk:inv" }
    card.id = SC.onlineId(user, oid)
    F.push(win, st, card)
    SC.inv[user] = nil
    SC.askInv(card)
end

function Y.invLines(r)
    local parts = {}
    if r.hasParent and r.container then parts[#parts + 1] = tr("UI_ZeD_St_InContainer", tostring(r.container)) end
    if r.weapon and r.var and r.maxCond and r.maxCond > 0 then
        parts[#parts + 1] = getText("IGUI_invpanel_Condition") .. " " .. tostring(math.floor(r.var / r.maxCond * 1000) / 10) .. "%"
    end
    if r.equip then parts[#parts + 1] = tr("UI_ZeD_St_Equipped") end
    if #parts == 0 then return nil end
    return table.concat(parts, " | ")
end

-- a thing: its picture, name, how many, its kind, and the window's notes under it
TC.items.sinv = {
    layout = function(win, it, w)
        local T, tm = ZeD.T, ZeD.TM
        local top = math.max(tm:getFontHeight(T.fontF2), px(20)) + 2 * px(4)
        it.topH = top
        if it.sub then
            if it.wrapW ~= w then
                it.wrapW = w
                it.lines = D.wrap(it.sub, T.fontF3, math.max(1, w - px(28)))
            end
            return top + #it.lines * tm:getFontHeight(T.fontF3) + px(4)
        end
        it.lines = nil
        return top
    end,
    draw = function(panel, win, t, it, x, dy, w, mx, my, ctx)
        local T, A = ZeD.T, ZeD.Atoms
        local c = it.c
        local hov = mx ~= nil and mx >= x and mx < x + w and my >= dy and my < dy + it.h
        if it.on then
            local a = T.accent
            panel:drawRect(x, dy, w, it.h, 0.25, a.r, a.g, a.b)
        elseif it.kin then
            local a = T.accent
            panel:drawRect(x, dy, w, it.h, 0.1, a.r, a.g, a.b)
        elseif hov then
            local hv = T.hover
            panel:drawRect(x, dy, w, it.h, hv.a or 1, hv.r, hv.g, hv.b)
        end
        if hov and c.help then ZeD.Help.set(win, c.help) end
        local onF = D.mark(panel, x, dy, w, it.h, D.focusOf(win, ctx.prefix .. c.id))
        local ic = px(20)
        local tex = it.tex
        if tex == nil then
            tex = safe(function() return getItemTex(it.full) end, false)
            it.tex = tex
        end
        if tex then panel:drawTextureScaledAspect(tex, x + px(2), dy + math.floor((it.topH - ic) / 2), ic, ic, 1, 1, 1, 1) end
        local tx = x + ic + px(8)
        local tc = onF and T.textOnFocus or T.text
        local dc = onF and T.textOnFocus or T.textDim
        local right = (it.count > 1) and ("x" .. tostring(it.count)) or ""
        local rw = ZeD.TM:MeasureStringX(T.fontF3, right)
        local catW = math.min(ZeD.TM:MeasureStringX(T.fontF3, it.cat), math.floor(w * 0.3))
        local ty = dy + math.floor((it.topH - ZeD.TM:getFontHeight(T.fontF2)) / 2)
        local f3y = dy + math.floor((it.topH - ZeD.TM:getFontHeight(T.fontF3)) / 2)
        if right ~= "" then panel:drawText(right, x + w - px(4) - rw, f3y, dc.r, dc.g, dc.b, dc.a or 1, T.fontF3) end
        local catX = x + w - px(4) - rw - px(10) - catW
        panel:drawText(A.truncateText(it.cat, T.fontF3, catW), catX, f3y, dc.r, dc.g, dc.b, dc.a or 1, T.fontF3)
        panel:drawText(A.truncateText(it.name, T.fontF2, math.max(px(20), catX - tx - px(8))), tx, ty, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        for i, s in ipairs(it.lines or {}) do
            panel:drawText(s, tx, dy + it.topH + (i - 1) * ZeD.TM:getFontHeight(T.fontF3), dc.r, dc.g, dc.b, dc.a or 1, T.fontF3)
        end
        A.drawDividerH(panel, x, dy + it.h - T.hair, w, false)
        ctx.hits[#ctx.hits + 1] = { x = x, y = dy, w = w, h = it.h, c = c }
    end,
    stops = function(it, x0, dy, w, add) add(it.c, x0, dy, w, it.h, it.y) end,
}

function Y.invRow(card, user)
    local data = SC.inv[user]
    if not (data and card.sel) then return nil end
    for _, r in ipairs(data.rows) do
        if r.id == card.sel then return r end
    end
    return nil
end

function Y.invItems(win, st, t, card, data)
    local items = {}
    local user = card.user
    if not M.can("InspectPlayerInventory") then
        B.sub(items, M.why("InspectPlayerInventory"))
        return items
    end
    if card.id == -1 then B.sub(items, tr("UI_ZeD_St_InvNoId")) end
    if not data.rows then
        B.sub(items, tr("UI_ZeD_Tk_Loading"))
        return items
    end
    B.label(items, getText("IGUI_char_Weight"), tostring(data.cap) .. " / " .. tostring(data.max))
    if #data.rows == 0 then B.sub(items, tr("UI_ZeD_St_InvEmpty")) end
    local sel = Y.invRow(card, user)
    for i, r in ipairs(data.rows) do
        local row = r
        -- (the window marks a container's things, and the container of the thing picked)
        local kin = sel ~= nil and sel ~= r and (tostring(sel.itemId) == tostring(r.parent) or tostring(sel.parent) == tostring(r.itemId))
        items[#items + 1] = { k = "sinv", name = r.name, full = r.full, count = r.count, cat = r.cat, sub = Y.invLines(r), on = card.sel == r.id, kin = kin,
            c = { id = "it:" .. tostring(i), land = i == 1, help = tr("UI_ZeD_St_HelpPick"),
                run = function(ww)
                    card.sel = (card.sel == row.id) and nil or row.id
                    t.confirm = nil
                    M.bump()
                end } }
    end
    return items
end

function Y.invFoot(win, st, t, card, data)
    local user = card.user
    local sel = Y.invRow(card, user)
    local own = user == M.me()
    local function base()
        if not M.can("InspectPlayerInventory") then return M.why("InspectPlayerInventory") end
        if card.id == -1 then return tr("UI_ZeD_St_InvNoId") end
        if t.busy then return tr("UI_ZeD_Tk_Busy") end
        return nil
    end
    if t.confirm and t.confirm.act == "rminv" and t.confirm.row then
        local r = t.confirm.row
        local go = D.btn("ryes", getText("ContextMenu_Remove"), function(ww)
            local why = base()
            t.confirm = nil
            if why then
                D.flash(t, why)
                return
            end
            InvMngRemoveItem(r.itemId, card.id, user)
            D.flash(t, tr("UI_ZeD_St_InvRemoved", r.name, user))
            card.sel = nil
            SC.askInv(card)
            D.focusId(ww, st, "tk:irefresh")
            M.bump()
        end, "danger", tr("UI_ZeD_St_HelpRemove"))
        local why = base()
        if why then D.disable(go, why) end
        return { question = tr("UI_ZeD_St_InvRemoveAsk", r.name, user), main = {
            D.btn("rno", tr("UI_ZeD_Tk_KeepIt"), function(ww)
                t.confirm = nil
                D.focusId(ww, st, "tk:iremove")
                M.bump()
            end, nil, tr("UI_ZeD_St_HelpCancel")), go } }
    end
    local refresh = D.btn("irefresh", ZeD.btnCase and ZeD.btnCase(getText("UI_servers_refresh")) or getText("UI_servers_refresh"), function(ww)
        SC.askInv(card)
        D.flash(t, tr("UI_ZeD_Tk_Loading"))
    end)
    local add = D.btn("iadd", tr("UI_ZeD_St_InvAdd"), function(ww)
        AC.openSpawn(ww, st)
        st.card.to = user
        st.card.from = "tk:iadd"
    end, nil, tr("UI_ZeD_St_HelpInvAdd"))
    local take = D.btn("itake", tr("UI_ZeD_St_InvTake"), function(ww)
        local r = Y.invRow(card, user)
        if not r then return end
        if r.count > 1 then InvMngGetItem(0, r.full, card.id, user) else InvMngGetItem(r.itemId, nil, card.id, user) end
        D.flash(t, tr("UI_ZeD_St_InvTaken", r.name))
        card.sel = nil
        SC.askInv(card)
        M.bump()
    end, nil, tr("UI_ZeD_St_HelpTake"))
    local remove = D.btn("iremove", getText("ContextMenu_Remove"), function(ww)
        local r = Y.invRow(card, user)
        if not r then return end
        t.confirm = { act = "rminv", row = r }
        D.focusId(ww, st, "tk:rno")
        M.bump()
    end, "danger", tr("UI_ZeD_St_HelpRemove"))
    local why = base()
    if why then
        D.disable(refresh, why)
        D.disable(remove, why)
    end
    -- (the game's window leaves Take and Add out for your own inventory)
    local takeWhy = why or (own and tr("UI_ZeD_St_InvOwn")) or nil
    local addWhy = (own and tr("UI_ZeD_St_InvOwn")) or (card.id == -1 and tr("UI_ZeD_St_InvNoId")) or ((not M.can("AddItem")) and M.why("AddItem")) or nil
    if not sel then
        if not why then D.disable(remove, tr("UI_ZeD_St_PickFirst")) end
        takeWhy = takeWhy or tr("UI_ZeD_St_PickFirst")
    end
    if takeWhy then D.disable(take, takeWhy) end
    if addWhy then D.disable(add, addWhy) end
    return { lead = { refresh, add }, main = { take, remove } }
end

TC.kinds.pinv = {
    data = function(card)
        local d = SC.inv[card.user]
        if d and SC.invAsked == card.user then return d end
        return {}
    end,
    tick = function(win, st, t, card) M.watch() end,
    key = function(t, card)
        local d = SC.inv[card.user]
        return table.concat({ tostring(M.seq), tostring(d and d.at), tostring(card.sel), tostring(t.confirm and t.confirm.row and t.confirm.row.id) }, ":")
    end,
    title = function(card) return getText("IGUI_PlayerStats_ManageInventory", card.user) end,
    help = function(t, card)
        if t.confirm then return tr("UI_ZeD_St_HelpConfirm") end
        return tr("UI_ZeD_St_HelpInv")
    end,
    items = function(win, st, t, card, data) return Y.invItems(win, st, t, card, data) end,
    foot = function(win, st, t, card, data) return Y.invFoot(win, st, t, card, data) end,
    cancel = function(win, st, t, card)
        if not t.confirm then return false end
        t.confirm = nil
        D.focusId(win, st, "tk:iremove")
        M.bump()
        return true
    end,
}

-- ---------------------------------------------------------------------------
-- THE GAME'S OWN WAYS IN: Check Stats on another player (ISWorldObjectContextMenu.onCheckStats). The card in the Admin
-- tab when it can show; the game's window otherwise
-- ---------------------------------------------------------------------------
function SC.hookWorld()
    if SC.hooked or not ISWorldObjectContextMenu or not ISWorldObjectContextMenu.onCheckStats then return end
    SC.hooked = true
    local base = ISWorldObjectContextMenu.onCheckStats
    ISWorldObjectContextMenu.onCheckStats = function(worldobjects, player, otherPlayer)
        local user = otherPlayer and safe(function() return otherPlayer:getUsername() end, nil)
        local n = player and safe(function() return player:getPlayerNum() end, 0) or 0
        if user and ZeD.AdminTab and ZeD.AdminTab.openNext and ZeD.AdminTab.openNext({ kind = "pstats", user = user }, n) then return end
        return base(worldobjects, player, otherPlayer)
    end
end

-- wired once (a reload keeps SC, and the handlers call through it, so they pick up the new code)
if not SC.wired then
    SC.wired = true
    if Events and Events.MngInvReceiveItems then Events.MngInvReceiveItems.Add(function(t) SC.onItems(t) end) end
    if Events and Events.OnGameStart then Events.OnGameStart.Add(SC.hookWorld) end
end

-- ---------------------------------------------------------------------------
-- TEST HOOKS (for the test scripts: open a card or a part straight away)
-- ---------------------------------------------------------------------------
function SC.qaOpen(win, st, kind, user)
    if kind == "pinv" then SC.openInv(win, st, user, nil, "tk:inv") else SC.openStats(win, st, user, "adm:tk:p:" .. tostring(user)) end
end
function SC.qaPart(win, st, part, which) Y.openPart(win, st, st.card, part, which, "tk:back") end

return SC
