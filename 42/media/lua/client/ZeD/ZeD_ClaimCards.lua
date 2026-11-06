-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ClaimCards.lua
-- ============================================================================
-- SAFEHOUSES, FACTIONS AND WARS IN CARDS (ZeDUI/MP_ADMIN_SCOPE.md, Phase 3; the drawing is
-- mockups/zed_safehouse_faction_v1.html). Drawing and input only: ZeD_Claims.lua is the model, and every act there is
-- the game's own call. The frame is the ticket cards' (ZeD_TicketCards.lua): the back bar, the foot, the text fields, the
-- pad keyboard and the focus. This file registers four cards and its own items with it:
--   safe      the title as the field itself, owner, members, invitations, respawn, the time left, the rules
--   faction   name, tag, color, members, invitations, the two ticks
--   newfac    create a faction: the name, in the card
--   wars      accept, refuse, end, the countdowns
-- and gives the Server tab its pieces: invitations as notes, the summary rows, Can I claim this?, this server's rules.
--
-- A name is a field in its card. What is typed is checked as it is typed, and saves with the foot's Save. A confirm is a
-- foot swap, in the game's own words. Simple mode draws these same cards: they are already plain.
--
-- QA, read at draw time (the ticket cards' style):
--   ZeD.Claims.qaHold  true: the model keeps what the script put in it, and no call reaches the game
--   CC.qaOpen(win, st, "safe" | "faction" | "newfac" | "wars"), CC.qaConfirm(st, { act, kind, who }), CC.qaRow(st, kind, name),
--   CC.qaDrawer(st, kind), CC.qaType(win, key, text)
-- ZeDUI/tools/qa/mp_claim_cards.lua walks every state of the drawing with these.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ZeD_ClaimProto"
require "ZeD/ZeD_ServerLink"
require "ZeD/ZeD_Claims"
require "ZeD/ZeD_TicketCards"

ZeD = ZeD or {}
ZeD.ClaimCards = ZeD.ClaimCards or {}
local CC = ZeD.ClaimCards
local TC = ZeD.TicketCards
local C = ZeD.Claims
local Cl = ZeD.Cl
local D = TC._D

local PAD, ROW_PAD, NOTE_PAD = 10, 6, 8   -- design units
local NAME_COL = 96                       -- a member's badge and status line up from here, past a short name
local DAYS_FROM_H = 48                    -- the time left reads in days from here up, in hours under it

local X = {}     -- the file's helpers (a table: Kahlua counts every local in the chunk)
CC._X = X

local function tr(k, ...) return ZeD.tr(k, ...) end
local function px(n) return ZeD.T.px(n) end
local function st_t(st) return TC.qaState(st) end
local function inside(mx, my, x, y, w, h) return mx ~= nil and mx >= x and mx < x + w and my >= y and my < y + h end

-- the game's word without its colon ("Owner:")
function X.plain(key) return (string.gsub(getText(key), "%s*:%s*$", "")) end
-- the game's word on a button: sentence case, as the Server tab's own
function X.word(s) return ZeD.ServerTab and ZeD.ServerTab.btnWords(s) or s end

function X.cl(t)
    if not t.cl then t.cl = {} end
    return t.cl
end

-- ---------------------------------------------------------------------------
-- WHO IS ON THE SERVER: the Server tab's scoreboard
-- ---------------------------------------------------------------------------
function X.players() return (ZeD.ServerTab and ZeD.ServerTab.players) or {} end

function X.online(user)
    for _, pl in ipairs(X.players()) do
        if pl.user == user then return true end
    end
    return false
end

function X.playersKey()
    local parts = {}
    for _, pl in ipairs(X.players()) do parts[#parts + 1] = pl.user end
    return table.concat(parts, ",")
end

-- ---------------------------------------------------------------------------
-- THE RULES, in plain words, from the server's own options
-- ---------------------------------------------------------------------------
function CC.ruleLines(r)
    local out = {}
    local function add(ok, key, a) out[#out + 1] = { ok = ok, text = (a ~= nil) and tr(key, a) or tr(key) } end
    if not r.player and not r.admin then add(false, "UI_ZeD_Cl_RuleNoClaims")
    elseif not r.player then out[#out + 1] = { ok = false, text = getText("UI_ServerOption_AdminSafehouse_tooltip") }
    elseif (r.claimDay or 0) > 0 then add(true, "UI_ZeD_Cl_RuleClaimDay", r.claimDay)
    else add(true, "UI_ZeD_Cl_RuleClaimAny") end
    if r.anyBuilding then add(true, "UI_ZeD_Cl_RuleAnyBuilding") else add(false, "UI_ZeD_Cl_RuleHomesOnly") end
    if r.trespass then add(false, "UI_ZeD_Cl_RuleTrespassYes") else add(true, "UI_ZeD_Cl_RuleTrespassNo") end
    if r.loot then add(false, "UI_ZeD_Cl_RuleLootYes") else add(true, "UI_ZeD_Cl_RuleLootNo") end
    if r.fire then add(false, "UI_ZeD_Cl_RuleFireYes") else add(true, "UI_ZeD_Cl_RuleFireNo") end
    if r.respawn then add(true, "UI_ZeD_Cl_RuleRespawnYes") else add(false, "UI_ZeD_Cl_RuleRespawnNo") end
    add(true, "UI_ZeD_Cl_RuleRemoval", r.removal or 0)
    if r.ownerOff then add(false, "UI_ZeD_Cl_RuleProtectOffline") else add(true, "UI_ZeD_Cl_RuleProtectAlways") end
    return out
end

function X.addRules(items, kindRule)
    items[#items + 1] = { k = "label", text = tr("UI_ZeD_Cl_Rules") }
    for _, l in ipairs(CC.ruleLines(C.rules or {})) do
        items[#items + 1] = { k = kindRule, ok = l.ok, text = l.text }
    end
end

-- what the server part knows of the time left, in words; nil without it
function CC.keepWords()
    local v = C.info and C.info.safe
    local r = C.rules
    if not (v and v.visitedH and r and (r.removal or 0) > 0) then return nil, nil end
    local gone = v.visitedH + (getTimestampMs() - C.info.at) / 3600000
    local left = r.removal - gone
    if left < 0 then left = 0 end
    local h = math.ceil(left)
    if left < 1 then return tr("UI_ZeD_Cl_KeepSoon"), left end
    if left >= DAYS_FROM_H then return tr("UI_ZeD_Cl_KeepDays", math.floor(left / 24)), left end
    return tr("UI_ZeD_Cl_KeepHours", h), left
end

-- ---------------------------------------------------------------------------
-- THE FIELDS. stored: what the game holds, clean: what a press would send, problem: why it cannot go, in the game's words
-- ---------------------------------------------------------------------------
X.FIELDS = {
    safeTitle = {
        max = Cl.TITLE_MAX + Cl.FIELD_OVER, limit = Cl.TITLE_MAX, clean = Cl.name,
        stored = function() return C.safe and C.safe.title or "" end,
        problem = function(s)
            local p = Cl.titleProblem(s)
            if p == "empty" then return tr("UI_ZeD_Cl_TitleEmpty") end
            if p == "long" then return tr("UI_ZeD_Cl_TitleLong", Cl.TITLE_MAX) end
            if not C.survivedToClaim() then
                return getText("IGUI_Safehouse_DaysSurvivedToClaim", (C.rules and C.rules.claimDay) or 0)
            end
            return nil
        end,
        save = function(s, done) C.rename(s, done) end, done = "UI_ZeD_Cl_Renamed",
    },
    facName = {
        max = Cl.NAME_MAX + Cl.FIELD_OVER, limit = Cl.NAME_MAX, clean = Cl.name,
        stored = function() return C.fac and C.fac.name or "" end,
        problem = function(s)
            local p = Cl.nameProblem(s, C.factionTaken(s))
            if p == "length" then return getText("IGUI_FactionUI_FactionNameTooLongShort") end
            if p == "exists" then return getText("IGUI_FactionUI_FactionAlreadyExist") end
            return nil
        end,
        save = function(s, done) C.renameFaction(s, done) end, done = "UI_ZeD_Cl_RenamedFaction",
    },
    facTag = {
        max = Cl.TAG_MAX + Cl.FIELD_OVER, limit = Cl.TAG_MAX, clean = Cl.tagText,
        stored = function() return C.fac and C.fac.tag or "" end,
        problem = function(s)
            local p = Cl.tagProblem(s, C.tagTaken(s))
            if p == "length" then return getText("IGUI_FactionUI_TagTooLongShort") end
            if p == "exists" then return getText("IGUI_FactionUI_TagAlreadyExist") end
            return nil
        end,
        save = function(s, done) C.setTag(s, done) end, done = "UI_ZeD_Cl_TagSet",
    },
}
X.FIELDS.newFac = {
    max = Cl.NAME_MAX + Cl.FIELD_OVER, limit = Cl.NAME_MAX, clean = Cl.name,
    stored = function() return "" end,
    problem = X.FIELDS.facName.problem,
}

function X.text(win, key)
    local f = X.FIELDS[key]
    return f.clean(D.fieldText(win, key))
end

-- the box holds words the game does not. (Nothing before its first frame, when the box has not been seeded.)
function X.dirty(win, key)
    local box = D.fieldOf(win, key)
    if not box or box._tkSeed == nil then return false end
    return X.text(win, key) ~= box._tkSeed
end

function X.resetField(win, key)
    local box = D.fieldOf(win, key)
    if box then box._tkSeed = nil end
end

function X.problemFor(win, key)
    if not X.dirty(win, key) then return nil end
    return X.FIELDS[key].problem(X.text(win, key))
end

function X.anyDirty(win, keys)
    for _, k in ipairs(keys or {}) do
        if X.dirty(win, k) then return true end
    end
    return false
end

-- the fields this card holds
function X.keysOf(card)
    local out = {}
    if card.kind == "safe" then
        if C.safe and C.safe.manage then out[1] = "safeTitle" end
    elseif card.kind == "faction" then
        if C.fac and C.fac.manage then out[1] = "facName" end
        if C.fac and C.fac.canTag then out[#out + 1] = "facTag" end
    end
    return out
end

function X.field(items, st, key, seed, hint, land)
    local f = X.FIELDS[key]
    items[#items + 1] = { k = "field", key = key, rows = 1, one = true, max = f.max, hint = hint, seed = seed,
        enter = function()
            local win = st.tkWin
            if win then X.pressSave(win, st) end
        end,
        esc = function()
            local win = st.tkWin
            if win then X.revert(win, st) end
        end,
        c = { id = "f:" .. key, land = land, help = hint, run = function(ww) D.useField(ww, key) end } }
    items[#items + 1] = { k = "sub", tone = "danger", text = "", liveText = function()
        local win = st.tkWin
        return win and X.problemFor(win, key) or ""
    end }
end

function X.count(st, key)
    local f = X.FIELDS[key]
    return function()
        local win = st.tkWin
        if not win then return "" end
        return tr("UI_ZeD_Cl_Count", #X.text(win, key), f.limit)
    end
end

-- Save: each changed field in turn. The game does not answer, so each waits to see its change arrive
function X.pressSave(win, st)
    local t = st_t(st)
    local card = st.card
    if not card or t.busy then return end
    local keys = {}
    for _, k in ipairs(X.keysOf(card)) do
        if X.dirty(win, k) then
            if X.problemFor(win, k) then return end
            keys[#keys + 1] = k
        end
    end
    if #keys == 0 then return end
    if C.qaHold then return end
    t.busy = true
    local i = 0
    local words = nil
    local function step(ok)
        if ok == false then
            t.busy = nil
            D.flash(t, tr("UI_ZeD_Cl_NoAnswer"))
            return
        end
        if i > 0 then words = tr(X.FIELDS[keys[i]].done) end
        i = i + 1
        local key = keys[i]
        if not key then
            t.busy = nil
            if words then D.flash(t, words) end
            D.focusId(win, st, "tk:f:" .. keys[#keys])
            return
        end
        X.FIELDS[key].save(X.text(win, key), step)
    end
    step(true)
end

function X.revert(win, st)
    local card = st.card
    if not card then return end
    local first = nil
    for _, k in ipairs(X.keysOf(card)) do
        if X.dirty(win, k) then
            local box = D.fieldOf(win, k)
            D.setField(win, k, box._tkSeed)
            first = first or k
        end
    end
    if first then D.focusId(win, st, "tk:f:" .. first) end
end

-- ---------------------------------------------------------------------------
-- ROWS AND PICKS
-- ---------------------------------------------------------------------------
function X.inline(c)
    local M, T = ZeD.Molecules, ZeD.T
    c.w, c.h = M.buttonW(c.text), T.buttonH - px(4)
end

function X.memberRows(items, st, t, kind, v)
    local me = C.me()
    local cl = X.cl(t)
    for _, n in ipairs(v.names) do
        local on = n == me or X.online(n)
        local row = { k = "member", kindOf = kind, name = n, owner = n == v.owner, you = n == me, on = on }
        local can = v.manage and n ~= me and n ~= v.owner
        local open = can and cl.row == kind .. ":" .. n
        row.c = { id = "m:" .. n, help = can and tr("UI_ZeD_Cl_HelpRow") or nil, open = open,
            run = can and function() X.toggleRow(st, t, kind, n) end or nil }
        if open then
            local own = { id = "own:" .. n, text = X.word(X.plain("IGUI_SafehouseUI_ChangeOwnership")), help = tr("UI_ZeD_Cl_HelpOwner"),
                run = function(ww) X.ask(ww, st, t, { act = "owner", kind = kind, who = n }) end }
            if not on then own.disabled, own.why = true, tr("UI_ZeD_Cl_MustBeOnline", n) end
            row.acts = { own,
                { id = "rem:" .. n, text = getText("ContextMenu_Remove"), help = tr("UI_ZeD_Cl_HelpRemove"), variant = "danger",
                  run = function(ww) X.ask(ww, st, t, { act = "remove", kind = kind, who = n }) end } }
        end
        items[#items + 1] = row
    end
    local names = {}
    for n in pairs(C.sent[kind] or {}) do names[#names + 1] = n end
    table.sort(names)
    for _, n in ipairs(names) do
        local row = { k = "member", kindOf = kind, name = n, pending = true }
        if v.manage then
            local c = { id = "un:" .. n, text = getText("UI_Cancel"), help = tr("UI_ZeD_Cl_HelpUninvite"),
                run = function(ww) X.uninvite(ww, st, t, kind, n) end }
            if not C.hasPart() then c.disabled, c.why = true, tr("UI_ZeD_Cl_NoTakeBack") end
            row.acts = { c }
        end
        items[#items + 1] = row
    end
end

function X.toggleRow(st, t, kind, n)
    local cl = X.cl(t)
    local key = kind .. ":" .. n
    if cl.row == key then cl.row = nil else cl.row = key end
    t.items = nil
end

function X.addDrawer(items, st, t, kind, v)
    local cl = X.cl(t)
    items[#items + 1] = { k = "btn", c = { id = "add", text = X.word(getText("IGUI_SafehouseUI_AddPlayer")), help = tr("UI_ZeD_Cl_HelpAdd"),
        run = function()
            if cl.drawer == kind then cl.drawer = nil else cl.drawer = kind end
            t.items = nil
        end } }
    if cl.drawer ~= kind then return end
    items[#items + 1] = { k = "dhead", text = tr("UI_ZeD_Cl_PlayersOnline"), right = tr("UI_ZeD_Cl_PickInvite") }
    local n = 0
    local isIn = {}
    for _, m in ipairs(v.names) do isIn[m] = true end
    for m in pairs(C.sent[kind] or {}) do isIn[m] = true end
    for _, pl in ipairs(X.players()) do
        if not isIn[pl.user] then
            n = n + 1
            local user = pl.user
            local word, why
            if kind == "safe" then
                local other = C.safeOf(user)
                word = other and tr("UI_ZeD_Cl_HasSafehouse") or tr("UI_ZeD_Cl_NoSafehouseYet")
                if other then why = getText("IGUI_SafehouseUI_AlreadyHaveSafehouse", (other ~= "") and ("(" .. other .. ")") or "") end
            else
                local other = C.factionOf(user)
                word = other and tr("UI_ZeD_Cl_InFaction", other) or tr("UI_ZeD_Cl_NoFactionYet")
                if other then why = getText("IGUI_FactionUI_AlreadyHaveFaction") end
            end
            items[#items + 1] = { k = "pick", name = pl.name, word = word,
                c = { id = "pick:" .. user, help = tr("UI_ZeD_Cl_HelpPick", pl.name), disabled = why ~= nil, why = why,
                      run = function(ww) X.invite(ww, st, t, kind, user) end } }
        end
    end
    if n == 0 then
        items[#items + 1] = { k = "pick", word = tr((#X.players() == 0) and "UI_ZeD_Srv_PlayersWait" or "UI_ZeD_Cl_EveryoneIn") }
    end
end

function X.invite(win, st, t, kind, user)
    X.cl(t).drawer = nil
    t.items = nil
    if not C.qaHold then C.invite(kind, user) end
    D.flash(t, tr("UI_ZeD_Cl_Sent", user))
    D.focusId(win, st, "tk:add")
end

function X.uninvite(win, st, t, kind, n)
    if C.qaHold then return end
    C.cancelInvite(kind, n, function(a)
        if a.ok == false then D.flash(t, tr("UI_ZeD_Cl_NoAnswer"))
        else D.flash(t, tr("UI_ZeD_Cl_Uninvited", n)) end
    end)
end

-- ---------------------------------------------------------------------------
-- THE FOOT'S CONFIRMS, in the game's own words
-- ---------------------------------------------------------------------------
function X.askWords(c)
    local keep = tr("UI_ZeD_Tk_KeepIt")
    if c.act == "release" then return getText("IGUI_SafehouseUI_ReleaseConfirm"), keep, tr("UI_ZeD_Cl_GoRelease") end
    if c.act == "quit" then return getText("IGUI_SafehouseUI_QuitSafeConfirm"), keep, tr("UI_ZeD_Cl_GoQuit") end
    if c.act == "disband" then return getText("IGUI_FactionUI_DisbandConfirm"), keep, tr("UI_ZeD_Cl_GoDisband") end
    if c.act == "leave" then return getText("IGUI_FactionUI_QuitSafeConfirm"), keep, tr("UI_ZeD_Cl_GoLeave") end
    if c.act == "remove" then
        local q = (c.kind == "safe") and "IGUI_SafehouseUI_RemoveConfirm" or "IGUI_FactionUI_RemoveConfirm"
        return getText(q, c.who), tr("UI_ZeD_Cl_Keep"), getText("ContextMenu_Remove")
    end
    if c.act == "owner" then return tr("UI_ZeD_Cl_OwnerAsk", c.who), tr("UI_ZeD_Cl_Keep"), X.word(X.plain("IGUI_SafehouseUI_ChangeOwnership")) end
    if c.act == "war" then
        if c.state == "Accepted" then return tr("UI_ZeD_Cl_WarAcceptAsk", tostring(c.row.attacker)), tr("UI_ZeD_Cl_Keep"), getText("IGUI_WarManager_AcceptWar") end
        return tr("UI_ZeD_Cl_WarEndAsk"), tr("UI_ZeD_Cl_Keep"), getText("IGUI_WarManager_EndWar")
    end
    return "", keep, ""
end

function X.ask(win, st, t, c)
    t.confirm = c
    D.focusId(win, st, "tk:no")
end

function X.closeAsk(win, st, t)
    local c = t.confirm
    t.confirm = nil
    if not c then return end
    if c.act == "remove" or c.act == "owner" then D.focusId(win, st, "tk:rem:" .. tostring(c.who))
    elseif c.act == "war" then D.focusId(win, st, c.from)
    else D.focusId(win, st, "tk:" .. c.act) end
end

function X.answered(t, ok, words)
    t.busy = nil
    D.flash(t, ok and words or tr("UI_ZeD_Cl_NoAnswer"))
end

function X.runAsk(win, st, t, c)
    t.confirm = nil
    local card = st.card
    X.cl(t).row = nil
    t.items = nil
    if C.qaHold then return end
    if c.act == "war" then
        C.war(c.row, c.state)
        return
    end
    t.busy = true
    local function left(words)
        card.goneText = words
        return function(ok)
            t.busy = nil
            if not ok then
                card.goneText = nil
                D.flash(t, tr("UI_ZeD_Cl_NoAnswer"))
            end
        end
    end
    if c.act == "release" then C.release(left(tr("UI_ZeD_Cl_Released")))
    elseif c.act == "quit" then C.quit(left(tr("UI_ZeD_Cl_Quit")))
    elseif c.act == "disband" then C.disband(left(tr("UI_ZeD_Cl_Disbanded")))
    elseif c.act == "leave" then C.leave(left(tr("UI_ZeD_Cl_Left")))
    elseif c.act == "remove" then C.remove(c.kind, c.who, function(ok) X.answered(t, ok, tr("UI_ZeD_Cl_Removed", c.who)) end)
    elseif c.act == "owner" then C.changeOwner(c.kind, c.who, function(ok) X.answered(t, ok, tr("UI_ZeD_Cl_NewOwner", c.who)) end)
    end
end

function X.footAsk(win, st, t, c)
    local q, keep, go = X.askWords(c)
    return { line = q, tone = "dangerText", main = {
        D.btn("no", keep, function(ww) X.closeAsk(ww, st, t) end, nil, tr("UI_ZeD_Cl_HelpKeep")),
        D.btn("yes", go, function(ww) X.runAsk(ww, st, t, c) end, "danger", tr("UI_ZeD_Cl_HelpGo", go)) } }
end

-- the foot while words wait to be saved: Save and Cancel, the reason if Save is gray
function X.footEdit(win, st, t, card)
    local keys = X.keysOf(card)
    local cl = X.cl(t)
    local dirty = X.anyDirty(win, keys)
    -- (under the controller: the keyboard hands back to Save, or to the field if the words went back)
    if D.padOn() then
        if dirty and not cl.wasDirty then D.focusId(win, st, "tk:save")
        elseif cl.wasDirty and not dirty and keys[1] then D.focusId(win, st, "tk:f:" .. keys[1]) end
    end
    cl.wasDirty = dirty
    if not dirty then return nil end
    local why = nil
    for _, k in ipairs(keys) do why = why or X.problemFor(win, k) end
    local save = D.btn("save", getText("IGUI_RolesList_Save"), function(ww) X.pressSave(ww, st) end, "primary", tr("UI_ZeD_Cl_HelpSave"))
    if why then D.disable(save, why) elseif t.busy then D.disable(save, tr("UI_ZeD_Tk_Busy")) end
    return { status = why, main = {
        D.btn("ecancel", getText("UI_Cancel"), function(ww) X.revert(ww, st) end, nil, tr("UI_ZeD_Cl_HelpRevert")), save } }
end

function X.footEnd(st, t, act, label, help)
    local b = D.btn(act, X.word(label), function(ww) X.ask(ww, st, t, { act = act }) end, "danger", help)
    if t.busy then D.disable(b, tr("UI_ZeD_Tk_Busy")) end
    return { main = { b } }
end

-- ---------------------------------------------------------------------------
-- THE CARDS
-- ---------------------------------------------------------------------------
function X.fact(items, key, value) items[#items + 1] = { k = "fact", label = X.plain(key), value = tostring(value or "") } end

function X.check(items, id, text, sub, on, run, land, why)
    items[#items + 1] = { k = "check", text = text, sub = sub, top = 8,
        c = { id = id, on = on, land = land, disabled = why ~= nil, why = why, run = run } }
end

function X.itemsSafe(win, st, t, card, h)
    local items = {}
    local r = C.rules or {}
    items[#items + 1] = { k = "label", text = X.plain("IGUI_SafehouseUI_Title"), right = h.manage and tr("UI_ZeD_Cl_PickRename") or nil }
    if h.manage then X.field(items, st, "safeTitle", h.title, tr("UI_ZeD_Cl_TitleHint"), true)
    else items[#items + 1] = { k = "value", text = h.title } end
    X.fact(items, "IGUI_SafehouseUI_Owner", h.owner)
    X.fact(items, "IGUI_SafehouseUI_Location", h.location or (tostring(h.x) .. " x " .. tostring(h.y)))
    if h.created then X.fact(items, "IGUI_SafehouseUI_DateCreated", h.created) end
    local keep = CC.keepWords()
    if keep then items[#items + 1] = { k = "sub", text = keep } end
    local sub, why
    if not r.respawn then why, sub = tr("UI_ZeD_Cl_RespawnOff"), tr("UI_ZeD_Cl_RespawnOff")
    elseif h.respawn then sub = tr("UI_ZeD_Cl_RespawnOn")
    else sub = tr("UI_ZeD_Cl_RespawnNeeds") end
    X.check(items, "respawn", getText("IGUI_SafehouseUI_Respawn"), sub, h.respawn and r.respawn,
        function() if C.qaHold then return end; C.setRespawn(not h.respawn) end, not h.manage, why)
    items[#items + 1] = { k = "label", text = X.plain("IGUI_SafehouseUI_Players"), right = tostring(#h.names) }
    X.memberRows(items, st, t, "safe", h)
    if h.manage then X.addDrawer(items, st, t, "safe", h) end
    X.addRules(items, "rule")
    return items
end

function X.itemsFaction(win, st, t, card, f)
    local items = {}
    local r = C.rules or {}
    items[#items + 1] = { k = "label", text = X.plain("IGUI_FactionUI_FactionName"), right = f.manage and tr("UI_ZeD_Cl_PickRename") or nil }
    if f.manage then X.field(items, st, "facName", f.name, tr("UI_ZeD_Cl_NameHint"), true)
    else items[#items + 1] = { k = "value", text = f.name } end
    items[#items + 1] = { k = "label", text = X.plain("IGUI_FactionUI_Tag"), rightFn = f.canTag and X.count(st, "facTag") or nil }
    if f.canTag then
        X.field(items, st, "facTag", f.tag or "", tr("UI_ZeD_Cl_TagHint"))
    elseif f.hasRoom or f.tag then
        items[#items + 1] = { k = "value", text = f.tag or tr("UI_ZeD_Cl_NoTag"), tagColor = f.color }
    else
        items[#items + 1] = { k = "sub", text = tr("UI_ZeD_Cl_TagNeeds", getText("IGUI_FactionUI_TagMembersIncorrect", r.tagNeeds or 1), #f.names) }
    end
    if f.canTag then
        items[#items + 1] = { k = "label", text = tr("UI_ZeD_Cl_TagColor") }
        local ctls = {}
        local noTag = (f.tag == nil or f.tag == "")
        for i, col in ipairs(Cl.COLORS) do
            ctls[i] = { id = "col:" .. col.id, color = col, on = Cl.sameColor(f.color, col), boxW = D.chipH(),
                help = tr("UI_ZeD_Cl_ColorHelp", tr("UI_ZeD_Cl_Color" .. col.id)), disabled = noTag, why = noTag and tr("UI_ZeD_Cl_TagFirst") or nil,
                run = function() if C.qaHold then return end; C.setColor(col) end }
        end
        items[#items + 1] = { k = "swatches", ctls = ctls }
    end
    X.check(items, "showtag", getText("IGUI_FactionUI_ShowTag"), tr("UI_ZeD_Cl_OwnTick"), f.showTag,
        function() if C.qaHold then return end; C.showTag(not f.showTag) end, not f.manage)
    if f.tag and f.tag ~= "" then items[#items + 1] = { k = "preview", tag = f.tag, color = f.color, show = f.showTag } end
    X.check(items, "pvp", getText("IGUI_FactionUI_FactionPvp"), getText("IGUI_FactionUI_FactionPvpTooltip"), f.pvp,
        function() if C.qaHold then return end; C.factionPvp(not f.pvp) end)
    items[#items + 1] = { k = "label", text = tr("UI_ZeD_Srv_Members"), right = tostring(#f.names) }
    X.memberRows(items, st, t, "fac", f)
    if f.manage then X.addDrawer(items, st, t, "fac", f) end
    return items
end

function X.itemsNew(win, st, t, card)
    local items = {}
    local r = C.rules or {}
    items[#items + 1] = { k = "label", text = X.plain("IGUI_FactionUI_FactionName"), rightFn = X.count(st, "newFac") }
    X.field(items, st, "newFac", "", tr("UI_ZeD_Cl_NewHint"), true)
    items[#items + 1] = { k = "label", text = tr("UI_ZeD_Cl_ComesNext") }
    local days = math.floor(C.hoursSurvived() / 24)
    if (r.factionDay or 0) > 0 then
        items[#items + 1] = { k = "rule", ok = days >= r.factionDay, text = tr("UI_ZeD_Cl_NextDays", days, r.factionDay) }
    end
    items[#items + 1] = { k = "rule", ok = true, text = tr("UI_ZeD_Cl_NextInvite") }
    items[#items + 1] = { k = "rule", ok = true, text = tr("UI_ZeD_Cl_NextTag", r.tagNeeds or 1) }
    return items
end

function X.warWord(state) return tr("UI_ZeD_Cl_War" .. tostring(state)) end

function X.warName(name)
    if name == C.me() then return getText("IGUI_WarManager_You") end
    return tostring(name)
end

function X.warPress(win, st, t, row, state, from)
    if Cl.WAR_CONFIRM and (state == "Accepted" or state == "Ended") then
        X.ask(win, st, t, { act = "war", row = row, state = state, from = from })
        return
    end
    if C.qaHold then return end
    C.war(row, state)
end

function X.itemsWars(win, st, t)
    local items = {}
    local r = C.rules or {}
    local me = C.me()
    local canEnd = C.cap("CanGoInsideSafehouses")
    local wars = C.wars or {}
    if #wars == 0 then items[#items + 1] = { k = "sub", text = tr("UI_ZeD_Cl_NoWars") } end
    for _, w in ipairs(wars) do
        items[#items + 1] = { k = "label", text = w.title or getText("IGUI_SafehouseUI_Safehouse") }
        items[#items + 1] = { k = "fact", label = getText("IGUI_WarManager_Attacker"), value = X.warName(w.attacker) }
        items[#items + 1] = { k = "fact", label = getText("IGUI_WarManager_Defender"), value = X.warName(w.defender) }
        local clock = Cl.warClock(w.state)
        items[#items + 1] = { k = "fact", label = X.warWord(w.state), value = clock and getText(clock, tostring(w.time)) or "" }
        local ctls = {}
        local words = { Accepted = "IGUI_WarManager_AcceptWar", Refused = "IGUI_WarManager_RefuseWar", Canceled = "IGUI_WarManager_CancelWar", Ended = "IGUI_WarManager_EndWar" }
        for _, state in ipairs(Cl.warActions(w.state, w.attacker, w.defender, me, canEnd)) do
            local id = "w:" .. tostring(w.id) .. ":" .. tostring(w.attacker) .. ":" .. state
            ctls[#ctls + 1] = { id = id, text = getText(words[state]), help = tr("UI_ZeD_Cl_HelpWar" .. state),
                run = function(ww) X.warPress(ww, st, t, w, state, "tk:" .. id) end }
        end
        if #ctls > 0 then items[#items + 1] = { k = "acts", ctls = ctls } end
    end
    items[#items + 1] = { k = "label", text = tr("UI_ZeD_Cl_WarRules") }
    items[#items + 1] = { k = "rule", ok = r.war == true, text = tr(r.war and "UI_ZeD_Cl_WarOn" or "UI_ZeD_Cl_WarOff") }
    if r.war then
        items[#items + 1] = { k = "rule", ok = true, text = tr("UI_ZeD_Cl_WarTimes", r.warDelay or 0, r.warLength or 0) }
        items[#items + 1] = { k = "rule", ok = true, text = tr("UI_ZeD_Cl_WarHow", getText("ContextMenu_WarClaim")) }
    end
    return items
end

function X.cardKey(t, card)
    local cl = X.cl(t)
    return table.concat({ tostring(C.seq), X.playersKey(), tostring(cl.row), tostring(cl.drawer), tostring(C.info and C.info.at) }, "|")
end

function X.cancelCard(win, st, t, card)
    if t.confirm then
        X.closeAsk(win, st, t)
    elseif X.anyDirty(win, X.keysOf(card)) then
        X.revert(win, st)
    else
        TC.back(win, st)
    end
end

function X.helpFor(t, card, base)
    local win = card.win
    if t.confirm then return tr("UI_ZeD_Cl_HelpConfirm") end
    if win and X.anyDirty(win, X.keysOf(card)) then return tr("UI_ZeD_Cl_HelpEdit") end
    return base
end

TC.kinds.safe = {
    data = function() return C.safe end,
    items = X.itemsSafe,
    title = function() return getText("IGUI_SafehouseUI_Safehouse") end,
    help = function(t, card, h)
        return X.helpFor(t, card, tr((h and h.manage) and "UI_ZeD_Cl_HelpSafeOwner" or "UI_ZeD_Cl_HelpSafeMember"))
    end,
    foot = function(win, st, t, card, h)
        if not h then return { main = {} } end
        if t.confirm then return X.footAsk(win, st, t, t.confirm) end
        local edit = X.footEdit(win, st, t, card)
        if edit then return edit end
        if h.isOwner then return X.footEnd(st, t, "release", getText("IGUI_SafehouseUI_Release"), tr("UI_ZeD_Cl_HelpRelease")) end
        return X.footEnd(st, t, "quit", getText("IGUI_SafehouseUI_QuitSafehouse"), tr("UI_ZeD_Cl_HelpQuit"))
    end,
    key = X.cardKey, cancel = X.cancelCard,
    gone = function(card) return card.goneText or tr("UI_ZeD_Cl_SafeGone") end,
}

TC.kinds.faction = {
    data = function() return C.fac end,
    items = X.itemsFaction,
    title = function() return getText("UI_userpanel_factionpanel") end,
    help = function(t, card, f)
        return X.helpFor(t, card, tr((f and f.manage) and "UI_ZeD_Cl_HelpFacOwner" or "UI_ZeD_Cl_HelpFacMember"))
    end,
    foot = function(win, st, t, card, f)
        if not f then return { main = {} } end
        if t.confirm then return X.footAsk(win, st, t, t.confirm) end
        local edit = X.footEdit(win, st, t, card)
        if edit then return edit end
        -- (the game's window: Disband for the owner and FactionCheat, Leave for a member of it who is not the owner)
        if f.isOwner then return X.footEnd(st, t, "disband", getText("IGUI_FactionUI_Remove"), tr("UI_ZeD_Cl_HelpDisband")) end
        return X.footEnd(st, t, "leave", getText("IGUI_SafehouseUI_QuitFaction"), tr("UI_ZeD_Cl_HelpLeave"))
    end,
    key = X.cardKey, cancel = X.cancelCard,
    gone = function(card) return card.goneText or tr("UI_ZeD_Cl_FacGone") end,
}

TC.kinds.newfac = {
    data = function() return true end,
    items = X.itemsNew,
    title = function() return getText("IGUI_FactionUI_CreateFaction") end,
    help = function() return tr("UI_ZeD_Cl_HelpNew") end,
    foot = function(win, st, t, card)
        local go = D.btn("create", X.word(getText("IGUI_FactionUI_CreateFaction")), function(ww) X.create(ww, st, t, card) end, "primary", tr("UI_ZeD_Cl_HelpCreate"))
        local text = X.text(win, "newFac")
        local why = (text == "") and tr("UI_ZeD_Cl_NameFirst") or X.FIELDS.newFac.problem(text)
        if why then D.disable(go, why) elseif t.busy then D.disable(go, tr("UI_ZeD_Tk_Busy")) end
        return { status = why, main = { D.btn("cancelnew", getText("UI_Cancel"), function(ww) TC.back(ww, st) end, nil, tr("UI_ZeD_Cl_HelpRevert")), go } }
    end,
    key = X.cardKey,
}

TC.kinds.wars = {
    data = function() return true end,
    items = X.itemsWars,
    title = function() return getText("IGUI_AdminPanel_SeeWars") end,
    help = function(t, card) return X.helpFor(t, card, tr("UI_ZeD_Cl_HelpWars")) end,
    foot = function(win, st, t, card)
        if t.confirm then return X.footAsk(win, st, t, t.confirm) end
        return { main = {} }
    end,
    key = X.cardKey,
    cancel = function(win, st, t, card)
        if t.confirm then X.closeAsk(win, st, t) else TC.back(win, st) end
    end,
}

function X.create(win, st, t, card)
    local name = X.text(win, "newFac")
    if X.FIELDS.newFac.problem(name) or C.qaHold then return end
    t.busy = true
    C.createFaction(name, function(ok)
        t.busy = nil
        if not ok or st.card ~= card then
            if not ok then D.flash(t, tr("UI_ZeD_Cl_NoAnswer")) end
            return
        end
        D.setField(win, "newFac", "")
        CC.openFaction(win, st, "srv:tk:sum:fac")
        D.flash(t, tr("UI_ZeD_Cl_Created", name))
        D.focusId(win, st, "tk:add")
    end)
end

-- ---------------------------------------------------------------------------
-- OPENING
-- ---------------------------------------------------------------------------
function X.push(win, st, kind, from)
    local t = st_t(st)
    local card = { kind = kind, from = from, win = win }
    t.cl = {}
    D.push(win, st, card)
    return card, t
end

function CC.openSafe(win, st, from)
    X.resetField(win, "safeTitle")
    return X.push(win, st, "safe", from or "srv:tk:sum:safe")
end

function CC.openFaction(win, st, from)
    if C.fac or (C.qaHold and C.fac) then
        X.resetField(win, "facName")
        X.resetField(win, "facTag")
        return X.push(win, st, "faction", from or "srv:tk:sum:fac")
    end
    D.setField(win, "newFac", "")
    X.resetField(win, "newFac")
    return X.push(win, st, "newfac", from or "srv:faction")
end

function CC.openWars(win, st) return X.push(win, st, "wars", "srv:tk:sum:wars") end

-- Claim Safehouse: the game's call, then its card with the title ready to type
function CC.claim(win, st)
    local t = st_t(st)
    local cl = X.cl(t)
    if cl.claiming or C.qaHold then return end
    cl.claiming = true
    C.bump()
    if not C.doClaim(function(ok)
        cl.claiming = nil
        C.bump()
        if not ok then
            D.flash(t, tr("UI_ZeD_Cl_NoAnswer"))
            return
        end
        CC.openSafe(win, st)
        local tt = st_t(st)
        D.flash(tt, tr("UI_ZeD_Cl_Claimed"))
        if not D.padOn() then tt.wantField = "safeTitle" end
    end) then
        cl.claiming = nil
        C.bump()
    end
end

-- once a frame on the Server tab, card or list
function CC.frame(win, st)
    if C.openNext then
        local kind = C.openNext
        C.openNext = nil
        st.card = nil
        if kind == "safe" and C.safe then CC.openSafe(win, st) end
    end
    if not st.card and not C.safe and not C.qaHold then C.claimCheck() end
end

-- ---------------------------------------------------------------------------
-- ITEMS IN THE SERVER TAB'S LIST (k = "cl")
-- ---------------------------------------------------------------------------
function X.tabKey()
    return table.concat({ tostring(C.seq), tostring((D.link())), tostring(C.info and C.info.at) }, "|")
end

function X.noteItem(st, t, inv, i)
    local it = { k = "cl", t = "note", text = C.inviteText(inv), sub = tr("UI_ZeD_Cl_NoteSub") }
    it.ctls = {
        { id = "inv:no:" .. tostring(i), text = tr("UI_ZeD_Cl_Decline"), help = tr("UI_ZeD_Cl_HelpDecline"),
          run = function(ww) X.answer(ww, st, t, inv, false) end },
        { id = "inv:yes:" .. tostring(i), text = getText("IGUI_WarManager_AcceptWar"), help = tr("UI_ZeD_Cl_HelpAccept"), primary = true,
          run = function(ww) X.answer(ww, st, t, inv, true) end },
    }
    return it
end

function X.answer(win, st, t, inv, yes)
    if C.qaHold then return end
    local who, name = tostring(inv.host), tostring(inv.name)
    C.answer(inv, yes, function(ok)
        if yes then D.flash(t, ok and tr("UI_ZeD_Cl_Joined", (inv.kind == "safe") and getText("IGUI_SafehouseUI_Safehouse") or name) or tr("UI_ZeD_Cl_InviteGone"))
        else D.flash(t, tr("UI_ZeD_Cl_Declined", who)) end
    end)
end

function X.sumItem(st, id, text, meta, tag, color, help, run)
    return { k = "cl", t = "sum", text = text, meta = meta, tag = tag, color = color,
        c = { id = "sum:" .. id, help = help, run = run } }
end

-- the notes, under the Server block
function CC.notes(L, win, st)
    local t = st_t(st)
    local cl = X.cl(t)
    if cl.noteKey ~= X.tabKey() or not cl.notes then
        cl.noteKey = X.tabKey()
        cl.notes = {}
        for i, inv in ipairs(C.invites) do cl.notes[i] = X.noteItem(st, t, inv, i) end
        t.listGen = t.listGen + 1
    end
    for _, it in ipairs(cl.notes) do L[#L + 1] = it end
end

function X.factionBlock(st, t, btnItem)
    local out = {}
    local f = C.fac
    local r = C.rules or {}
    out[#out + 1] = { k = "head", text = getText("UI_userpanel_factionpanel"), right = f and tr("UI_ZeD_Cl_NPlayers", #f.names) or nil }
    if f then
        out[#out + 1] = X.sumItem(st, "fac", f.name, tr("UI_ZeD_Cl_OwnerIs", tostring(f.owner)), (f.tag ~= "") and f.tag or nil, f.color,
            tr("UI_ZeD_Cl_HelpOpenFac"), function(ww) CC.openFaction(ww, st) end)
        return out
    end
    out[#out + 1] = { k = "line", text = tr("UI_ZeD_Srv_NoFaction") }
    local why = (not r.faction) and getText("IGUI_FactionUI_Disabled")
        or ((not C.canCreateFaction()) and getText("IGUI_FactionUI_FactionSurvivalDay", r.factionDay or 0)) or nil
    local b = btnItem("faction", getText("IGUI_FactionUI_CreateFaction"), why or tr("UI_ZeD_Srv_HelpCreateFaction"))
    b.disabled = why ~= nil
    out[#out + 1] = b
    out[#out + 1] = { k = "tk", t = "wrap", text = why or tr("UI_ZeD_Cl_CreateSub") }
    return out
end

function X.safeBlock(st, t, btnItem)
    local out = {}
    local h = C.safe
    local cl = X.cl(t)
    out[#out + 1] = { k = "head", text = getText("IGUI_SafehouseUI_Safehouse"), right = h and tr("UI_ZeD_Cl_NPlayers", #h.names) or nil }
    if h then
        out[#out + 1] = X.sumItem(st, "safe", h.title, tr("UI_ZeD_Cl_OwnerAt", tostring(h.x) .. " x " .. tostring(h.y), tostring(h.owner)), nil, nil,
            tr("UI_ZeD_Cl_HelpOpenSafe"), function(ww) CC.openSafe(ww, st) end)
        local keep, left = CC.keepWords()
        if keep and left and left < DAYS_FROM_H then out[#out + 1] = { k = "tk", t = "wrap", text = keep } end
        return out
    end
    out[#out + 1] = { k = "line", text = tr("UI_ZeD_Srv_NoSafehouse") }
    out[#out + 1] = { k = "cl", t = "label", text = tr("UI_ZeD_Cl_CanClaim") }
    local ans = C.claim or { lines = { tr("UI_ZeD_Cl_ClaimWait") } }
    for _, s in ipairs(ans.lines) do out[#out + 1] = { k = "cl", t = "rule", ok = ans.ok == true, text = s } end
    local why = (not ans.ok) and (ans.lines[1] or tr("UI_ZeD_Cl_ClaimWait")) or (cl.claiming and tr("UI_ZeD_Tk_Busy")) or nil
    local b = btnItem("claim", getText("ContextMenu_SafehouseClaim"), why or tr("UI_ZeD_Cl_HelpClaim"))
    b.disabled, b.variant = why ~= nil, "primary"
    out[#out + 1] = b
    out[#out + 1] = { k = "tk", t = "wrap", text = tr("UI_ZeD_Cl_ClaimSub") }
    out[#out + 1] = { k = "cl", t = "label", text = tr("UI_ZeD_Cl_Rules") }
    for _, l in ipairs(CC.ruleLines(C.rules or {})) do out[#out + 1] = { k = "cl", t = "rule", ok = l.ok, text = l.text } end
    return out
end

function X.warBlock(st, t)
    local out = {}
    local r = C.rules or {}
    local wars = C.wars or {}
    if not r.war and #wars == 0 then return out end
    out[#out + 1] = { k = "head", text = getText("IGUI_AdminPanel_SeeWars"), count = #wars }
    out[#out + 1] = X.sumItem(st, "wars", (#wars > 0) and tr("UI_ZeD_Cl_NWars", #wars) or tr("UI_ZeD_Cl_NoWars"), tr("UI_ZeD_Cl_WarsMeta"), nil, nil,
        tr("UI_ZeD_Cl_HelpOpenWars"), function(ww) CC.openWars(ww, st) end)
    return out
end

-- the Faction, Safehouse and Wars blocks; btnItem makes the tab's own button
function CC.blocks(L, win, st, btnItem)
    local t = st_t(st)
    local cl = X.cl(t)
    if cl.blockKey ~= X.tabKey() or not cl.block then
        cl.blockKey = X.tabKey()
        cl.block = {}
        for _, fn in ipairs({ X.factionBlock, X.safeBlock, X.warBlock }) do
            for _, it in ipairs(fn(st, t, btnItem)) do cl.block[#cl.block + 1] = it end
        end
        t.listGen = t.listGen + 1
    end
    for _, it in ipairs(cl.block) do L[#L + 1] = it end
end

function CC.listHelp() return tr("UI_ZeD_Cl_HelpList") end

function X.wrapOf(it, font, w)
    if it.wrapW ~= w then it.wrapW, it.lines = w, D.wrap(it.text, font, math.max(1, w)) end
    return it.lines
end

function CC.itemH(it, w)
    local T, tm = ZeD.T, ZeD.TM
    local f2h = tm:getFontHeight(T.fontF2)
    if it.t == "sum" then return D.rowH() end
    if it.t == "label" then return tm:getFontHeight(T.fontF1) + px(8) end
    if it.t == "rule" then
        return #X.wrapOf(it, T.fontF2, w - px(14)) * f2h + px(3)
    end
    if it.t == "note" then
        local pad = px(NOTE_PAD)
        local inner = w - 2 * pad
        X.wrapOf(it, T.fontF2, inner)
        if it.subW ~= inner then it.subW, it.subLines = inner, D.wrap(it.sub, T.fontF2, math.max(1, inner)) end
        local h = pad * 2 + (#it.lines + #it.subLines) * f2h + px(6) + T.buttonH - px(4)
        local right = inner
        for i = #it.ctls, 1, -1 do
            local c = it.ctls[i]
            X.inline(c)
            right = right - c.w
            c.dx, c.dy = pad + right, h - pad - c.h
            right = right - px(8)
        end
        return h + px(4)
    end
    return 0
end

function X.drawTagAt(panel, x, y, text, color)
    local T, A = ZeD.T, ZeD.Atoms
    local c = color and { r = color.r, g = color.g, b = color.b, a = 1 } or T.text
    local o = { keepCase = true, textColor = c, frameColor = c }
    return A.drawTag(panel, x, y, text, nil, o)
end

function X.drawRuleMark(panel, x, y, ok)
    local T, A = ZeD.T, ZeD.Atoms
    if ok then A.drawStatusDot(panel, x, y, T.positive, px(6))
    else A.drawStatusHollow(panel, x, y, T.danger, px(6)) end
end

function X.drawLines(panel, lines, x, y, font, c)
    local fh = ZeD.TM:getFontHeight(font)
    for i, s in ipairs(lines or {}) do
        panel:drawText(s, x, y + (i - 1) * fh, c.r, c.g, c.b, c.a or 1, font)
    end
end

function CC.drawItem(panel, win, st, it, x, dy, cw, mx, my)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local t = st_t(st)
    local pad = px(PAD)
    if it.t == "label" then
        local c = T.textHead
        panel:drawText(it.text, x + pad, dy + px(6), c.r, c.g, c.b, c.a or 1, T.fontF1)
    elseif it.t == "rule" then
        X.drawRuleMark(panel, x + pad, dy + px(4), it.ok)
        X.drawLines(panel, it.lines, x + pad + px(14), dy, T.fontF2, T.text)
    elseif it.t == "sum" then
        local hov = inside(mx, my, x, dy, cw, it.h)
        if hov then
            local hv = T.hover
            panel:drawRect(x, dy, cw, it.h, hv.a or 1, hv.r, hv.g, hv.b)
            if it.c.help then ZeD.Help.set(win, it.c.help) end
        end
        local onF = D.mark(panel, x + pad, dy, cw - pad, it.h, D.focusOf(win, t.prefix .. it.c.id))
        local tx = x + pad
        if it.tag and it.tag ~= "" then
            tx = tx + X.drawTagAt(panel, tx, dy + px(ROW_PAD), it.tag, onF and T.textOnFocus or it.color) + px(8)
        end
        local room = math.max(0, x + cw - pad - px(14) - tx)
        local tc = onF and T.textOnFocus or T.text
        panel:drawText(A.truncateText(it.text, T.fontF2, room), tx, dy + px(ROW_PAD), tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        local mc = onF and T.textOnFocus or T.textDim
        local fh = ZeD.TM:getFontHeight(T.fontF2)
        panel:drawText(A.truncateText(it.meta, T.fontF3, room), tx, dy + px(ROW_PAD) + fh + px(2), mc.r, mc.g, mc.b, mc.a or 1, T.fontF3)
        A.drawTextRight(panel, ">", x + cw - pad, dy + px(ROW_PAD), T.fontF3, onF and T.textOnFocus or T.textDim)
        A.drawDividerH(panel, x, dy + it.h - T.hair, cw, false)
        t.listHits[#t.listHits + 1] = { x = x, y = dy, w = cw, h = it.h, c = it.c }
    elseif it.t == "note" then
        local bx, bw = x + pad, cw - 2 * pad
        local np = px(NOTE_PAD)
        local ac = T.accent
        panel:drawRect(bx, dy, bw, it.h - px(4), 0.08, ac.r, ac.g, ac.b)
        A.frame(panel, bx, dy, bw, it.h - px(4), ac)
        X.drawLines(panel, it.lines, bx + np, dy + np, T.fontF2, T.text)
        local fh = ZeD.TM:getFontHeight(T.fontF2)
        X.drawLines(panel, it.subLines, bx + np, dy + np + #it.lines * fh, T.fontF2, T.textDim)
        for _, c in ipairs(it.ctls) do
            local cx, by = bx + c.dx, dy + c.dy
            local hov = inside(mx, my, cx, by, c.w, c.h)
            M.drawButton(panel, cx, by, c.w, c.h, c.text, c.primary and "primary" or "default", hov and isMouseButtonDown(0), nil,
                { hover = hov, disabled = c.disabled, help = c.why or c.help, win = win, focus = D.focusOf(win, t.prefix .. c.id) })
            t.listHits[#t.listHits + 1] = { x = cx, y = by, w = c.w, h = c.h, c = c }
        end
    end
end

-- the stops of one item, in reading order
function CC.itemStops(out, st, it, x0, dy, cw, flag)
    local t = st_t(st)
    local pad = px(PAD)
    local function add(c, x, y, w, h, cy)
        local e = D.stop(c, t.prefix .. c.id, x, y, w, h, cy)
        e[flag] = true
        e.tkWhy = function() return c.why end
        out[#out + 1] = e
    end
    if it.t == "sum" then
        add(it.c, x0, dy, cw - 2 * pad, it.h, it.y)
    elseif it.t == "note" then
        for _, c in ipairs(it.ctls) do add(c, x0 + c.dx, dy + c.dy, c.w, c.h, it.y + c.dy) end
    end
end

function CC.listKey(st)
    local t = st.tk
    return t and t.cl and tostring(t.cl.blockKey) or ""
end

-- ---------------------------------------------------------------------------
-- ITEMS ON A CARD
-- ---------------------------------------------------------------------------
TC.itemKinds.value = {
    gap = function() return px(2) end,
    layout = function(win, it, w)
        local T = ZeD.T
        return #X.wrapOf(it, T.fontF4, w) * ZeD.TM:getFontHeight(T.fontF4) + px(4)
    end,
    draw = function(panel, win, t, it, x, dy)
        local T = ZeD.T
        local col = it.tagColor
        local c = col and { r = col.r, g = col.g, b = col.b, a = 1 } or T.text
        X.drawLines(panel, it.lines, x, dy, T.fontF4, c)
    end,
}

TC.itemKinds.rule = {
    layout = function(win, it, w)
        local T = ZeD.T
        return #X.wrapOf(it, T.fontF2, w - px(14)) * ZeD.TM:getFontHeight(T.fontF2) + px(3)
    end,
    draw = function(panel, win, t, it, x, dy)
        local T = ZeD.T
        X.drawRuleMark(panel, x, dy + px(4), it.ok)
        X.drawLines(panel, it.lines, x + px(14), dy, T.fontF2, T.text)
    end,
}

-- a row of small buttons; each c gets dx, dy from the item's corner. Returns the height
function X.flowActs(ctls, w, x0)
    local gap = px(6)
    local dx, dy, h = x0, 0, 0
    for _, c in ipairs(ctls) do
        X.inline(c)
        c.w = math.min(c.w, w)
        if dx > x0 and dx + c.w > w then
            dx = x0
            dy = dy + c.h + gap
        end
        c.dx, c.dy = dx, dy
        dx = dx + c.w + gap
        h = dy + c.h
    end
    return h
end

function X.drawActs(panel, win, t, ctls, x, y, mx, my)
    for _, c in ipairs(ctls or {}) do
        D.drawInline(panel, win, t, c, x + c.dx, y + c.dy, mx, my)
    end
end

function X.actStops(add, ctls, x, y, cy)
    for _, c in ipairs(ctls or {}) do add(c, x + c.dx, y + c.dy, c.w, c.h, cy + c.dy) end
end

TC.itemKinds.acts = {
    gap = function() return px(6) end,
    layout = function(win, it, w) return X.flowActs(it.ctls, w, 0) end,
    draw = function(panel, win, t, it, x, dy, w, mx, my) X.drawActs(panel, win, t, it.ctls, x, dy, mx, my) end,
    stops = function(add, it, x0, dy) X.actStops(add, it.ctls, x0, dy, it.y) end,
}

function X.memberWords(it)
    if it.pending then return tr("UI_ZeD_Cl_InvitedWaiting") end
    return tr(it.on and "UI_ZeD_Cl_Online" or "UI_ZeD_Cl_Offline")
end

function X.memberName(it)
    if it.you then return tr("UI_ZeD_Cl_You", it.name) end
    return it.name
end

function X.ownerBadge() return ZeD.upper(X.plain("IGUI_SafehouseUI_Owner")) end

-- the name, the OWNER badge and the status on one line; the buttons beside them if they fit, else on a line of their own
TC.itemKinds.member = {
    layout = function(win, it, w)
        local T, tm = ZeD.T, ZeD.TM
        local line = tm:getFontHeight(T.fontF2) + 2 * px(ROW_PAD)
        it.lineH = line
        local nameW = math.max(tm:MeasureStringX(T.fontF2, X.memberName(it)) + px(8), px(NAME_COL))
        local badgeW = it.owner and (ZeD.Atoms.tagW(X.ownerBadge(), false, { keepCase = true }) + px(8)) or 0
        local stW = tm:MeasureStringX(T.fontF3, X.memberWords(it)) + px(16)
        it.nameRoom = w - px(4)
        if not it.acts then return line end
        local actsW = 0
        for _, c in ipairs(it.acts) do
            X.inline(c)
            actsW = actsW + c.w + px(6)
        end
        if nameW + badgeW + stW + actsW + px(8) <= w then
            local dx = w - actsW + px(6)
            for _, c in ipairs(it.acts) do
                c.dx, c.dy = dx, math.floor((line - c.h) / 2)
                dx = dx + c.w + px(6)
            end
            it.nameRoom = w - actsW - px(8)
            return line
        end
        local h = X.flowActs(it.acts, w, 0)
        for _, c in ipairs(it.acts) do c.dy = c.dy + line - px(ROW_PAD) end
        return line - px(ROW_PAD) + h + px(ROW_PAD)
    end,
    draw = function(panel, win, t, it, x, dy, w, mx, my)
        local T, A = ZeD.T, ZeD.Atoms
        local c = it.c
        local onF = false
        local hov = c and c.run and inside(mx, my, x, dy, w, it.h)
        if hov then
            local hv = T.hover
            panel:drawRect(x, dy, w, it.h, hv.a or 1, hv.r, hv.g, hv.b)
            if c.help then ZeD.Help.set(win, c.help) end
        end
        if c then onF = D.mark(panel, x, dy, w, it.lineH, D.focusOf(win, "tk:" .. c.id)) end
        local tc = onF and T.textOnFocus or T.text
        local name = A.truncateText(X.memberName(it), T.fontF2, it.nameRoom)
        local y = dy + px(ROW_PAD)
        panel:drawText(name, x, y, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        local tx = x + math.max(ZeD.TM:MeasureStringX(T.fontF2, name) + px(8), px(NAME_COL))
        local right = x + it.nameRoom
        if it.owner then
            local o = { keepCase = true, textColor = onF and T.textOnFocus or T.textDim, frameColor = onF and T.textOnFocus or T.textDim }
            if tx + A.tagW(X.ownerBadge(), false, o) <= right then
                tx = tx + A.drawTag(panel, tx, y, X.ownerBadge(), nil, o) + px(8)
            end
        end
        local word = X.memberWords(it)
        local room = right - tx - px(12)
        if room > px(20) then
            if not it.pending then
                local col = it.on and T.positive or T.textDim
                if it.on then A.drawStatusDot(panel, tx, y + px(4), col, px(6)) else A.drawStatusHollow(panel, tx, y + px(4), col, px(6)) end
            end
            local sc = onF and T.textOnFocus or T.textDim
            panel:drawText(A.truncateText(word, T.fontF3, room), tx + px(10), y + px(1), sc.r, sc.g, sc.b, sc.a or 1, T.fontF3)
        end
        A.drawDividerH(panel, x, dy + it.h - T.hair, w, false)
        X.drawActs(panel, win, t, it.acts, x, dy, mx, my)
        if c then t.hits[#t.hits + 1] = { x = x, y = dy, w = w, h = it.h, c = c } end
    end,
    stops = function(add, it, x0, dy, w)
        if it.c then
            local e = add(it.c, x0, dy, w, it.lineH or it.h, it.y)
            if not it.c.run then e.promptA = false end
        end
        X.actStops(add, it.acts, x0, dy, it.y)
    end,
}

TC.itemKinds.dhead = {
    gap = function() return px(6) end,
    layout = function() return ZeD.TM:getFontHeight(ZeD.T.fontF1) + px(10) end,
    draw = function(panel, win, t, it, x, dy, w)
        local T, A = ZeD.T, ZeD.Atoms
        A.surfaceFill(panel, x, dy, w, it.h, "surf2")
        A.frame(panel, x, dy, w, it.h, T.borderS)
        local c = T.textHead
        panel:drawText(it.text, x + px(8), dy + px(5), c.r, c.g, c.b, c.a or 1, T.fontF1)
        local room = w - px(16) - ZeD.TM:MeasureStringX(T.fontF1, it.text) - px(8)
        if room > px(20) then A.drawTextRight(panel, A.truncateText(it.right, T.fontF3, room), x + w - px(8), dy + px(5), T.fontF3, T.textDim) end
    end,
}

TC.itemKinds.pick = {
    layout = function() return ZeD.TM:getFontHeight(ZeD.T.fontF2) + 2 * px(ROW_PAD) end,
    draw = function(panel, win, t, it, x, dy, w, mx, my)
        local T, A = ZeD.T, ZeD.Atoms
        local c = it.c
        A.surfaceFill(panel, x, dy, w, it.h, "surf1")
        local hov = c and inside(mx, my, x, dy, w, it.h)
        if hov then
            local hv = T.hover
            panel:drawRect(x, dy, w, it.h, hv.a or 1, hv.r, hv.g, hv.b)
            ZeD.Help.set(win, c.why or c.help)
        end
        local onF = c and D.mark(panel, x, dy, w, it.h, D.focusOf(win, "tk:" .. c.id))
        local a = (c and c.disabled) and T.disabledAlpha or 1
        local y = dy + px(ROW_PAD)
        local tx = x + px(8)
        if it.name then
            local tc = onF and T.textOnFocus or T.text
            local name = A.truncateText(it.name, T.fontF2, math.floor(w * 0.45))
            panel:drawText(name, tx, y, tc.r, tc.g, tc.b, (tc.a or 1) * a, T.fontF2)
            tx = tx + ZeD.TM:MeasureStringX(T.fontF2, name) + px(10)
        end
        local sc = onF and T.textOnFocus or T.textDim
        panel:drawText(A.truncateText(it.word, T.fontF3, math.max(0, x + w - px(8) - tx)), tx, y + px(1), sc.r, sc.g, sc.b, (sc.a or 1) * a, T.fontF3)
        A.drawDividerH(panel, x, dy + it.h - T.hair, w, false)
        if c then t.hits[#t.hits + 1] = { x = x, y = dy, w = w, h = it.h, c = c } end
    end,
    stops = function(add, it, x0, dy, w)
        if it.c then add(it.c, x0, dy, w, it.h, it.y) end
    end,
}

TC.itemKinds.swatches = {
    layout = function(win, it, w) return D.flow(it.ctls, w, 0) + px(2) end,
    draw = function(panel, win, t, it, x, dy, w, mx, my)
        local T, A = ZeD.T, ZeD.Atoms
        for _, c in ipairs(it.ctls) do
            local cx, cy = x + c.dx, dy + c.dy
            local a = c.disabled and T.disabledAlpha or 1
            panel:drawRect(cx, cy, c.w, c.h, a, c.color.r, c.color.g, c.color.b)
            D.mark(panel, cx, cy, c.w, c.h, D.focusOf(win, "tk:" .. c.id))
            A.frame(panel, cx, cy, c.w, c.h, c.on and T.accent or T.borderS, a)
            if c.on then A.frame(panel, cx + px(2), cy + px(2), c.w - px(4), c.h - px(4), T.base) end
            if inside(mx, my, cx, cy, c.w, c.h) then ZeD.Help.set(win, c.why or c.help) end
            t.hits[#t.hits + 1] = { x = cx, y = cy, w = c.w, h = c.h, c = c }
        end
    end,
    stops = function(add, it, x0, dy)
        for _, c in ipairs(it.ctls) do add(c, x0 + c.dx, dy + c.dy, c.w, c.h, it.y + c.dy) end
    end,
}

-- "Over your head": the name as the game shows it, the tag in its color
TC.itemKinds.preview = {
    gap = function() return px(6) end,
    layout = function() return ZeD.TM:getFontHeight(ZeD.T.fontF3) + px(8) end,
    draw = function(panel, win, t, it, x, dy, w)
        local T = ZeD.T
        local label = tr("UI_ZeD_Cl_OverHead")
        local c = T.textDim
        panel:drawText(label, x, dy + px(4), c.r, c.g, c.b, c.a or 1, T.fontF3)
        local bx = x + ZeD.TM:MeasureStringX(T.fontF3, label) + px(8)
        local name = C.me()
        local nameW = ZeD.TM:MeasureStringX(T.fontF3, name)
        local tagS = it.show and ("[" .. tostring(it.tag) .. "]") or ""
        local tagW = (tagS ~= "") and (ZeD.TM:MeasureStringX(T.fontF3, tagS) + px(6)) or 0
        local bw = math.min(nameW + tagW + px(16), x + w - bx)
        local b = T.base
        panel:drawRect(bx, dy, bw, it.h, 1, b.r, b.g, b.b)
        local tc = T.text
        panel:drawText(name, bx + px(8), dy + px(4), tc.r, tc.g, tc.b, 1, T.fontF3)
        if tagS ~= "" then
            local col = it.color or tc
            panel:drawText(tagS, bx + px(8) + nameW + px(6), dy + px(4), col.r, col.g, col.b, 1, T.fontF3)
        end
    end,
}

-- ---------------------------------------------------------------------------
-- THE RIGHT-CLICK MENU'S "View safehouse" on your own opens the card (ISWorldObjectContextMenu.onViewSafeHouse)
-- ---------------------------------------------------------------------------
function CC.hookWorld()
    if CC.hooked or not ISWorldObjectContextMenu or not ISWorldObjectContextMenu.onViewSafeHouse then return end
    CC.hooked = true
    local base = ISWorldObjectContextMenu.onViewSafeHouse
    ISWorldObjectContextMenu.onViewSafeHouse = function(worldobjects, safehouse, player)
        local p = (type(player) == "number") and getSpecificPlayer(player) or player
        local mine = C.safe and C.safe.obj == safehouse
        local n = p and p.getPlayerNum and p:getPlayerNum() or 0
        if mine and ZeD_CharacterWindow and ZeD_CharacterWindow.openTab and ZeD_CharacterWindow.openTab(n, "server") then
            C.openNext = "safe"
            return
        end
        return base(worldobjects, safehouse, player)
    end
end
if Events and Events.OnGameStart then Events.OnGameStart.Add(CC.hookWorld) end

-- ---------------------------------------------------------------------------
-- QA
-- ---------------------------------------------------------------------------
function CC.qaOpen(win, st, kind)
    if kind == "safe" then CC.openSafe(win, st)
    elseif kind == "faction" then CC.openFaction(win, st)
    elseif kind == "newfac" then
        D.setField(win, "newFac", "")
        X.resetField(win, "newFac")
        X.push(win, st, "newfac", "srv:faction")
    else CC.openWars(win, st) end
end
function CC.qaConfirm(st, c) st_t(st).confirm = c end
function CC.qaRow(st, kind, name)
    local t = st_t(st)
    X.cl(t).row = kind .. ":" .. name
    t.items = nil
end
function CC.qaDrawer(st, kind)
    local t = st_t(st)
    X.cl(t).drawer = kind
    t.items = nil
end
function CC.qaType(win, key, text) D.setField(win, key, text) end

return CC
