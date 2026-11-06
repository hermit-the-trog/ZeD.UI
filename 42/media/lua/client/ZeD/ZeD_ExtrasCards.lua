-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ExtrasCards.lua
-- ============================================================================
-- THE SERVER EXTRAS IN CARDS (ZeDUI/MP_ADMIN_SCOPE.md, Phase 6; the drawing is mockups/zed_community_v1.html). Drawing and
-- input only: ZeD_Extras.lua is the model. The frame is the ticket cards' (ZeD_TicketCards.lua), and the items the admin
-- cards' (ZeD_AdminCards.lua). This file holds:
--   the Admin tab    its row, and the Server extras card: each system a tick in its box, Save in the foot
--   the Server tab   This server's extras in plain words, and your claims
--   xclaims          your claims: each car, Release behind the foot's confirm
--   the Vehicle tab  who holds the car, Claim or Release in the footer (MechanicsTab.lua calls in here; every call does
--                    nothing while claims are off)
--   the map          Teleport Here on the Maps tab's band, while the setting is on and your role can
-- The card's words say what the server refuses and what it can't, because the owner decides from them. Economy stays gray
-- with its reason. Simple mode draws these same cards: they are already plain.
--
-- QA, read at draw time: ZeD.Extras.qaHold, qaLink (ZeD_Extras.lua), ZeD.Admin.qaCaps, qaRoles, and EC.qaOpen(win, st, kind).
-- ZeDUI/tools/qa/mp_extras_cards.lua walks every state of the drawing with these.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ZeD_ExtrasProto"
require "ZeD/ZeD_Extras"
require "ZeD/ZeD_Admin"
require "ZeD/ZeD_TicketCards"
require "ZeD/ZeD_AdminCards"
require "ZeD/ZeD_ClaimCards"
require "ZeD/MapsTabExt"

ZeD = ZeD or {}
ZeD.ExtrasCards = ZeD.ExtrasCards or {}
local EC = ZeD.ExtrasCards
local E = ZeD.Extras
local Ex = ZeD.Ex
local M = ZeD.Admin
local TC = ZeD.TicketCards
local AC = ZeD.AdminCards
local CC = ZeD.ClaimCards
local D, B = TC._D, TC._B
local F = AC._F
local L = Ex.L

local INNER = 24                          -- design units: what sits under a system's tick, as drawn

local P = {}     -- the cards' parts (a table: Kahlua counts every local in the chunk)

local function tr(k, ...) return ZeD.tr(k, ...) end

-- ---------------------------------------------------------------------------
-- THE SERVER EXTRAS CARD
-- ---------------------------------------------------------------------------
function P.changed(card) card.rev = (card.rev or 0) + 1 end
function P.dirty(card) return E.set ~= nil and not Ex.same(card.d, E.set) end

-- why this client can't change the settings, or nil
function P.editWhy()
    if not M.can(Ex.CAP_EDIT) then return M.why(Ex.CAP_EDIT) end
    if E.frozen then return tr("UI_ZeD_Ex_Err_frozen") end
    if not E.live() then return tr("UI_ZeD_Adm_NeedPart") end
    return nil
end

function P.tick(items, card, group, field, id, text, sub, help)
    local d = card.d[group]
    items[#items + 1] = { k = "atick", text = text, sub = sub,
        c = F.gate({ id = id, on = d[field] == true, help = help or sub or text,
            run = function()
                d[field] = not d[field]
                P.changed(card)
            end }, nil, P.editWhy) }
end

-- a number between two buttons. A button at the end of the range is gray, and says so
function P.stepper(items, card, field, id, lo, hi, unit, help)
    local d = card.d.vc
    local function gray(atEnd, key, limit)
        return function()
            local why = P.editWhy()
            if why then return why end
            if atEnd() then return tr(key, limit) end
            return nil
        end
    end
    F.flow(items, {
        F.gate({ id = id .. ":less", text = "-", help = help,
            run = function()
                d[field] = d[field] - 1
                P.changed(card)
            end }, nil, gray(function() return d[field] <= lo end, "UI_ZeD_Ex_Least", lo)),
        { style = "text", text = tostring(d[field]), tone = "text" },
        F.gate({ id = id .. ":more", text = "+", help = help,
            run = function()
                d[field] = d[field] + 1
                P.changed(card)
            end }, nil, gray(function() return d[field] >= hi end, "UI_ZeD_Ex_Most", hi)),
        { style = "text", text = unit },
    })
end

-- one system: its tick in a box, what it holds under that while it's on. The box takes the accent while it's on, as drawn
function P.system(items, card, id, titleKey, whatKey, inner)
    local on = card.d[id].on
    items[#items + 1] = { k = "insetTop", tone = on and "accent" or nil }
    local from = #items + 1
    P.tick(items, card, id, "on", "x" .. id, tr(titleKey), tr(whatKey))
    local mid = #items + 1
    if on and inner then inner() end
    for i = from, #items do items[i].ind = (i < mid) and 8 or INNER end
    items[#items + 1] = { k = "insetEnd" }
end

-- the roles that have it, least to most: the game's own list
function P.teleportWho()
    local names = {}
    for _, r in ipairs(M.roles()) do
        if r.caps[Ex.CAP_MAP] and r.name ~= "banned" then names[#names + 1] = r.name end
    end
    local word = M.capWord(Ex.CAP_MAP)
    if #names == 0 then return tr("UI_ZeD_Ex_TpNobody", word) end
    return tr("UI_ZeD_Ex_TpWho", table.concat(names, ", "), word)
end

function P.extrasItems(win, st, t, card)
    local items = {}
    B.sub(items, tr("UI_ZeD_Ex_Intro"))
    P.system(items, card, "vc", "UI_ZeD_Ex_VcTitle", "UI_ZeD_Ex_VcWhat", function()
        B.label(items, tr("UI_ZeD_Ex_VcCant"))
        P.tick(items, card, "vc", "parts", "vparts", tr("UI_ZeD_Ex_VcParts"), tr("UI_ZeD_Ex_VcPartsSub"))
        P.tick(items, card, "vc", "drive", "vdrive", tr("UI_ZeD_Ex_VcDrive"), tr("UI_ZeD_Ex_VcDriveSub"))
        P.tick(items, card, "vc", "tow", "vtow", tr("UI_ZeD_Ex_VcTow"), nil, tr("UI_ZeD_Ex_HelpTow"))
        B.label(items, tr("UI_ZeD_Ex_VcPer"))
        P.stepper(items, card, "per", "vper", L.PER_MIN, L.PER_MAX, tr((card.d.vc.per == 1) and "UI_ZeD_Ex_VcCar" or "UI_ZeD_Ex_VcCars"), tr("UI_ZeD_Ex_HelpPer"))
        B.label(items, tr("UI_ZeD_Ex_VcLapse"))
        P.stepper(items, card, "lapse", "vlapse", L.LAPSE_MIN, L.LAPSE_MAX, tr("UI_ZeD_Ex_VcDays"), tr("UI_ZeD_Ex_HelpLapse"))
        B.sub(items, tr("UI_ZeD_Ex_VcLimit"))
    end)
    P.system(items, card, "sp", "UI_ZeD_Ex_SpTitle", "UI_ZeD_Ex_SpWhat", function()
        P.tick(items, card, "sp", "dismantle", "sdis", tr("UI_ZeD_Ex_SpDismantle"), nil, tr("UI_ZeD_Ex_HelpDismantle"))
        P.tick(items, card, "sp", "destroy", "sdes", tr("UI_ZeD_Ex_SpDestroy"), nil, tr("UI_ZeD_Ex_HelpDestroy"))
        P.tick(items, card, "sp", "lot", "slot", tr("UI_ZeD_Ex_SpLot"), tr("UI_ZeD_Ex_SpLotSub", Ex.LOT_TILES))
        B.sub(items, tr("UI_ZeD_Ex_SpLimit"))
    end)
    P.system(items, card, "tp", "UI_ZeD_Ex_TpTitle", "UI_ZeD_Ex_TpWhat", function()
        B.sub(items, P.teleportWho())
    end)
    P.system(items, card, "cl", "UI_ZeD_Ex_ClTitle", "UI_ZeD_Ex_ClWhat", function()
        items[#items + 1] = { k = "sub", text = tr("UI_ZeD_Ex_ClTold"), tone = "warning" }
        B.sub(items, tr("UI_ZeD_Ex_ClLimit"))
    end)
    -- Economy: on the card, gray, with its reason
    items[#items + 1] = { k = "insetTop" }
    items[#items + 1] = { k = "atick", ind = 8, text = tr("UI_ZeD_Ex_EcoTitle"), sub = tr("UI_ZeD_Ex_EcoWhat"),
        c = F.gate({ id = "xeco", run = function() end }, nil, function() return tr("UI_ZeD_Ex_EcoWhy") end) }
    items[#items + 1] = { k = "insetEnd" }
    return items
end

function P.saveBtn(win, st, t, card)
    local b = D.btn("xsave", getText("IGUI_RolesList_Save"), function(ww)
        F.act(ww, st, function(cb) E.save(card.d, cb) end, tr("UI_ZeD_Ex_SavedFlash"))
    end, "primary", tr("UI_ZeD_Ex_HelpSave"))
    local why = P.editWhy()
    if why then D.disable(b, why)
    elseif not P.dirty(card) then D.disable(b, tr("UI_ZeD_Adm_NothingToSave"))
    elseif t.busy then D.disable(b, tr("UI_ZeD_Tk_Busy")) end
    return b
end

-- another admin saved while this card was open: a card with nothing changed follows, and one with changes keeps them
function P.follow(card)
    if card.base == E.set then return end
    if card.base and E.set and Ex.same(card.d, card.base) then
        card.d = Ex.clean(E.set)
        P.changed(card)
    end
    card.base = E.set
end

TC.kinds.extras = {
    data = function(card) return card.d end,
    tick = function(win, st, t, card) P.follow(card) end,
    key = function(t, card) return tostring(E.seq) .. ":" .. tostring(card.rev) end,
    title = function() return tr("UI_ZeD_Ex_Title") end,
    help = function() return tr("UI_ZeD_Ex_Help") end,
    items = function(win, st, t, card) return P.extrasItems(win, st, t, card) end,
    foot = function(win, st, t, card)
        return { status = tr(P.dirty(card) and "UI_ZeD_Adm_NotSaved" or "UI_ZeD_Ex_Saved"), main = { P.saveBtn(win, st, t, card) } }
    end,
    padX = function(win, st, t, card)
        local b = P.saveBtn(win, st, t, card)
        return { label = b.label, run = b.run, disabled = b.disabled, why = b.why }
    end,
}

function EC.open(win, st)
    F.push(win, st, { kind = "extras", from = "adm:tk:sum:extras", d = Ex.clean(E.set), base = E.set })
end

-- the Admin tab's row, after Spawn items (AC.homeItems)
function AC.extrasKey() return tostring(E.seq) .. ":" .. tostring(E.live()) end

function AC.extrasHome(L2, win, st)
    local n = (E.live() and E.set) and Ex.nOn(E.set) or nil
    L2[#L2 + 1] = { k = "head", text = tr("UI_ZeD_Ex_Title"), right = n and ((n > 0) and tr("UI_ZeD_Ex_NOn", n) or tr("UI_ZeD_Ex_NoneOn")) or nil }
    local c = F.gate({ id = "sum:extras", help = tr("UI_ZeD_Ex_HelpRow"), run = function(ww) EC.open(ww, st) end }, nil, function()
        if not E.live() then return tr("UI_ZeD_Adm_NeedPart") end
        return nil
    end)
    L2[#L2 + 1] = { k = "tk", t = "arow", left = tr("UI_ZeD_Ex_RowWords"), leftMin = 400, chev = true, c = c }
end

-- ---------------------------------------------------------------------------
-- THE SERVER TAB: this server's extras, in plain words
-- ---------------------------------------------------------------------------
-- a list of ticked words, as a sentence: "take parts, drive it"
function P.words(list)
    return table.concat(list, ", ")
end

function EC.playerLines(set)
    local out = {}
    local vc, sp = set.vc, set.sp
    if vc.on then
        local can = {}
        if vc.parts then can[#can + 1] = tr("UI_ZeD_Ex_WordParts") end
        if vc.drive then can[#can + 1] = tr("UI_ZeD_Ex_WordDrive") end
        if vc.tow then can[#can + 1] = tr("UI_ZeD_Ex_WordTow") end
        if #can > 0 then out[#out + 1] = { ok = true, text = tr("UI_ZeD_Ex_LineClaims", P.words(can)) }
        else out[#out + 1] = { ok = true, text = tr("UI_ZeD_Ex_LineClaimsOnly") } end
    else
        out[#out + 1] = { dim = true, text = tr("UI_ZeD_Ex_NoClaims") }
    end
    if sp.on and (sp.dismantle or sp.destroy) then
        local what = (sp.dismantle and sp.destroy) and "UI_ZeD_Ex_WordBoth" or (sp.dismantle and "UI_ZeD_Ex_WordDismantle" or "UI_ZeD_Ex_WordDestroy")
        out[#out + 1] = { ok = true, text = tr(sp.lot and "UI_ZeD_Ex_LineSafeLot" or "UI_ZeD_Ex_LineSafe", tr(what)) }
    end
    if set.cl.on then out[#out + 1] = { dim = true, text = tr("UI_ZeD_Ex_LineLog") } end
    return out
end

function P.tabItems(win, st)
    local out = {}
    out[#out + 1] = { k = "head", text = tr("UI_ZeD_Ex_Head"), right = tr("UI_ZeD_Ex_SetBy") }
    for i, l in ipairs(EC.playerLines(E.set)) do
        if l.dim then
            out[#out + 1] = { k = "tk", t = "wrap", text = l.text }
        else
            out[#out + 1] = { k = "cl", t = "rule", ok = l.ok, text = l.text, c = { id = "exline:" .. tostring(i) } }
        end
    end
    if E.set.vc.on then
        local rows = E.mine()
        local n = rows and #rows or 0
        out[#out + 1] = CC._X.sumItem(st, "xclaims", tr("UI_ZeD_Ex_YourClaims"), tr("UI_ZeD_Ex_NOfM", n, E.set.vc.per), nil, nil,
            tr("UI_ZeD_Ex_HelpClaims"), function(ww) EC.openClaims(ww, st) end)
    end
    return out
end

-- under the Server block, over Tickets, as drawn. Nothing without the server part
function EC.blocks(L2, win, st)
    if not (E.live() and E.set) then return end
    local t = TC.qaState(st)
    local key = tostring(E.seq)
    if t.exKey ~= key or not t.exItems then
        t.exKey = key
        t.exItems = P.tabItems(win, st)
        t.listGen = t.listGen + 1
    end
    for _, it in ipairs(t.exItems) do L2[#L2 + 1] = it end
end

-- ---------------------------------------------------------------------------
-- YOUR CLAIMS: every car, wherever it is
-- ---------------------------------------------------------------------------
function EC.carWord(name)
    if type(name) ~= "string" then return tr("UI_ZeD_Ex_ACar") end
    return getTextOrNull("IGUI_VehicleName" .. name) or name
end

function P.claimItems(win, st, t, card)
    local items = {}
    local rows = E.mineRows
    if not rows then
        B.sub(items, tr("UI_ZeD_Ex_ClaimsWait"))
        return items
    end
    B.sub(items, tr((#rows == 0) and "UI_ZeD_Ex_ClaimsNone" or "UI_ZeD_Ex_ClaimsTop"))
    for i, r in ipairs(rows) do
        local row = r
        local where = (r.x and r.y) and (tostring(r.x) .. " x " .. tostring(r.y)) or nil
        items[#items + 1] = { k = "arow", left = EC.carWord(r.name), leftMin = 120, meta = where, ctl = F.gate({ id = "xrel:" .. tostring(i), text = tr("UI_ZeD_Ex_Release"), help = tr("UI_ZeD_Ex_HelpRelease"),
            run = function(ww)
                card.ask = row
                card.askFrom = "tk:xrel:" .. tostring(i)
                t.confirm = true
                D.focusId(ww, st, "tk:xkeep")
            end }, nil, function()
                if not E.live() then return tr("UI_ZeD_Adm_NeedPart") end
                return nil
            end) }
    end
    return items
end

function P.keepClaim(win, st, t, card)
    t.confirm, card.ask = nil, nil
    if card.askFrom then D.focusId(win, st, card.askFrom) end
end

TC.kinds.xclaims = {
    data = function() return true end,
    tick = function() E.mine() end,
    key = function(t, card) return tostring(E.seq) end,
    title = function() return tr("UI_ZeD_Ex_YourClaims") end,
    help = function(t, card)
        if card.ask then return tr("UI_ZeD_Ex_HelpRelease") end
        return tr("UI_ZeD_Ex_HelpClaimsCard")
    end,
    items = function(win, st, t, card) return P.claimItems(win, st, t, card) end,
    foot = function(win, st, t, card)
        if not card.ask then return {} end
        return { question = tr("UI_ZeD_Ex_ReleaseAsk", EC.carWord(card.ask.name)), main = {
            D.btn("xkeep", tr("UI_ZeD_Cl_Keep"), function(ww) P.keepClaim(ww, st, t, card) end, nil, tr("UI_ZeD_Ex_HelpKeep")),
            D.btn("xrelyes", tr("UI_ZeD_Ex_Release"), function(ww)
                local key = card.ask.key
                t.confirm, card.ask = nil, nil
                F.act(ww, st, function(cb) E.release(key, cb) end, tr("UI_ZeD_Ex_Released"))
            end, "danger", tr("UI_ZeD_Ex_HelpRelease")) } }
    end,
    cancel = function(win, st, t, card)
        if not card.ask then return false end
        P.keepClaim(win, st, t, card)
        return true
    end,
}

function EC.openClaims(win, st)
    F.push(win, st, { kind = "xclaims", from = TC.qaState(st).prefix .. "sum:xclaims" })
end

-- ---------------------------------------------------------------------------
-- THE VEHICLE TAB (MechanicsTab.lua calls these; each does nothing while claims are off)
-- ---------------------------------------------------------------------------
function EC.statRow(panel, x, y, w, v)
    if not E.claimsOn() then return 0 end
    local view = E.car(v)
    if not view then return 0 end
    local Mo, T = ZeD.Molecules, ZeD.T
    if view.owner then
        return Mo.drawStatRowDot(panel, x, y, w, tr("UI_ZeD_Ex_ClaimRow"), view.mine and tr("UI_ZeD_Ex_ClaimYours") or view.owner,
            view.mine and T.positive or T.warning)
    end
    return Mo.drawStatRow(panel, x, y, w, tr("UI_ZeD_Ex_ClaimRow"), tr("UI_ZeD_Ex_ClaimFree"))
end

-- why Claim is gray, or nil
function EC.claimWhy(view)
    if not view then return tr("UI_ZeD_Ex_Asking") end
    if view.n >= view.per then return tr("UI_ZeD_Ex_ClaimsFull", view.per) end
    return nil
end

-- the footer's own button, with no part chosen
function EC.vehicleBar(list, s, win, v)
    if not E.claimsOn() then return end
    local view = E.car(v)
    if view and view.owner then
        if not (view.mine or view.staff) then return end
        list[#list + 1] = { id = "xrelease", label = tr("UI_ZeD_Ex_Release"), variant = "danger", help = tr("UI_ZeD_Ex_HelpRelease"),
            fn = function()
                s.confirm = "xrelease"
                win._mechFocusTarget = "mech:confirm:no"
            end }
        return
    end
    local why = EC.claimWhy(view)
    list[#list + 1] = { id = "xclaim", label = tr("UI_ZeD_Ex_Claim"), disabled = why ~= nil, help = why or tr("UI_ZeD_Ex_HelpClaim"),
        fn = function()
            if why then return end
            E.claim(v, function(a)
                if a.ok then E.say(tr("UI_ZeD_Ex_ClaimedNow"), true) else E.say(E.errText(a)) end
            end)
        end }
end

-- the footer swapped for Release's confirm
function EC.releaseBand(panel, win, s, x, y, w, v, h)
    local Mo = ZeD.Molecules
    local view = E.car(v)
    local key = view and view.key
    local _, cancelR, verbR = Mo.drawQuestionBand(panel, x, y, w, tr("UI_ZeD_Ex_ReleaseAskCar"), tr("UI_ZeD_Ex_Release"), { win = win, danger = true,
        cancelFocus = h.focusFor(s, "mech:confirm:no"), verbFocus = h.focusFor(s, "mech:confirm:yes"),
        cancelHelp = tr("UI_ZeD_Ex_HelpKeep"), verbHelp = tr("UI_ZeD_Ex_HelpRelease") })
    h.stamp(s, "mech:confirm:no", cancelR.x, cancelR.y, cancelR.w, cancelR.h, function() s.confirm = nil end, { footer = true })
    h.stamp(s, "mech:confirm:yes", verbR.x, verbR.y, verbR.w, verbR.h, function()
        s.confirm = nil
        if key then
            E.release(key, function(a)
                if a.ok then E.say(tr("UI_ZeD_Ex_Released"), true) else E.say(E.errText(a)) end
            end)
        end
    end, { footer = true })
end

-- ---------------------------------------------------------------------------
-- THE MAP: Teleport Here on the band, a click or A on the map to go
-- ---------------------------------------------------------------------------
function EC.mapOn()
    return E.live() and E.set ~= nil and E.set.tp.on and M.can(Ex.CAP_MAP)
end

function EC.mapGo(mp, win, x, y)
    local wx, wy = math.floor(mp.mapAPI:uiToWorldX(x, y)), math.floor(mp.mapAPI:uiToWorldY(x, y))
    if not getWorld():getMetaGrid():isValidChunk(math.floor(wx / 10), math.floor(wy / 10)) then
        E.say(tr("UI_ZeD_Ex_MapOff"))
        return
    end
    win._exTp = nil
    E.goTo(wx, wy, function(a)
        if a.ok == false then E.say(E.errText(a)) end
    end)
end

ZeD.MapsTab.addExtension("extras_tp", {
    order = 40,
    button = function(win)
        if not EC.mapOn() then
            win._exTp = nil
            return nil
        end
        return { id = "extras:tp", text = getText("IGUI_ZombiePopulation_TeleportHere"), help = tr("UI_ZeD_Ex_MapHelp"), on = win._exTp == true,
            activate = function(w)
                w._exTp = (not w._exTp) or nil
                if w._exTp then ZeD.MapsTab.putDownTool(w) end
            end }
    end,
    banner = function(win)
        if win._exTp then return tr("UI_ZeD_Ex_MapBanner") end
        return nil
    end,
    armed = function(win) return win._exTp == true end,
    putDown = function(win) win._exTp = nil end,
    mouseDown = function(mp, win, x, y)
        EC.mapGo(mp, win, x, y)
        return true
    end,
    padA = function(mp, win, x, y, phase)
        if phase == "down" then EC.mapGo(mp, win, x, y) end
    end,
})

-- ---------------------------------------------------------------------------
-- QA
-- ---------------------------------------------------------------------------
function EC.qaOpen(win, st, kind)
    if kind == "extras" then EC.open(win, st)
    elseif kind == "xclaims" then EC.openClaims(win, st) end
end

function EC.qaAsk(st, row)
    local card = st.card
    card.ask, card.askFrom = row, "tk:xrel:1"
    TC.qaState(st).confirm = true
end

EC._P = P

return EC
