-- ZeD-UI/42/media/lua/client/ZeD/ZeD_AdminZones.lua
-- ============================================================================
-- THE ZONES CARD AND ITS MAP PICK (ZeDUI/VANILLA_WINDOWS_20261107.md, C14; the director, Nov 7: every admin tool becomes a
-- ZeD card). One card takes over the game's Zone editor, Non PVP Zone and Add Safezone windows (ISMultiplayerZoneEditor,
-- ISPvpZonePanel with ISAddNonPvpZoneUI, ISAddSafeZoneUI):
--   Non-PvP zones   every zone a row (name, corners, size); pick one for Go there and Remove (behind the foot's confirm);
--                   See zones on the ground (the game's own highlight); Add a non-PvP zone
--   Safe zones      a count of the claims, and Add a safe zone (a safehouse claimed for a player)
--   Adding          the name (and the owner, for a safe zone), the area, and Add zone in the foot. The area is picked by
--                   dragging over ZeD's map (the Maps tab: this file's map extension), or with Corner here and Other corner
--                   here where the character stands, as the game's windows do. The area shows on the ground while the card
--                   shows (the game's own highlight), blue when it can be added and red when it overlaps.
-- Every act is the game's own call (NonPvpZone.addNonPvpZone and removeNonPvpZone, sendSafezoneClaim, /teleportto), with the
-- game's own checks first: the capability, a name not taken, a size past one, no overlap (the player's own check for a
-- non-PvP zone; for a safe zone, the claims' rectangles), an owner who is online. A control that cannot be used stays on the
-- card, gray, and says why. All text is drawn with drawText. Simple mode draws this same card.
--
-- On the map (Maps tab), while any zones card is open, the non-PvP zones and the claims show as tinted rectangles, and while a
-- pick is armed the band says so; a drag (or the controller's A held from corner to corner) sets the area and the Admin tab
-- comes back with it.
--
-- QA: AZ._Z.qaZones / qaSafes / qaPlayer, AZ.qaOpen(win, st, which), AZ.qaArea(st, x1, y1, x2, y2).
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ZeD_Admin"
require "ZeD/ZeD_TicketCards"
require "ZeD/ZeD_AdminCards"
require "ZeD/MapsTabExt"

ZeD = ZeD or {}
ZeD.AdminZones = ZeD.AdminZones or {}
local AZ = ZeD.AdminZones
local M = ZeD.Admin
local AC = ZeD.AdminCards
local TC = ZeD.TicketCards
local D, B = TC._D, TC._B
local F = AC._F

local NAME_MAX = 64
local READ_MS = 1000

local Z = {}                     -- the model and the pick (a table: Kahlua counts every local in the chunk)
local P = {}                     -- the card's parts
AZ._Z, AZ._P = Z, P
Z.seq = 0

local function tr(k, ...) return ZeD.tr(k, ...) end
local function px(n) return ZeD.T.px(n) end
local function words(s) local S = ZeD.ServerTab; return (S and S.btnWords) and S.btnWords(s) or s end
function Z.bump() Z.seq = Z.seq + 1 end

local CAP_PVP, CAP_SAFE = "CanSetupNonPVPZone", "CanSetupSafehouses"

-- ---------------------------------------------------------------------------
-- THE MODEL: the game's lists
-- ---------------------------------------------------------------------------
function Z.zones()
    if Z.qaZones then return Z.qaZones end
    local out = {}
    pcall(function()
        local list = NonPvpZone.getAllZones()
        for i = 0, list:size() - 1 do
            local z = list:get(i)
            out[#out + 1] = { title = z:getTitle(), x = z:getX(), y = z:getY(), x2 = z:getX2(), y2 = z:getY2(), size = z:getSize() }
        end
    end)
    return out
end

function Z.safes()
    if Z.qaSafes then return Z.qaSafes end
    local out = {}
    pcall(function()
        local list = SafeHouse.getSafehouseList()
        for i = 0, list:size() - 1 do
            local h = list:get(i)
            out[#out + 1] = { title = h:getTitle(), owner = h:getOwner(), x = h:getX(), y = h:getY(), w = h:getW(), h = h:getH() }
        end
    end)
    return out
end

function Z.player()
    if Z.qaPlayer then return Z.qaPlayer end
    return getPlayer()
end

-- a list's signature: the card's words are built again when it changes
function Z.sig()
    local parts = {}
    for _, z in ipairs(Z.zones()) do parts[#parts + 1] = table.concat({ tostring(z.title), z.x, z.y, z.x2, z.y2 }, ",") end
    parts[#parts + 1] = "|" .. tostring(#Z.safes())
    return table.concat(parts, ";")
end

-- the area as the game's windows take it: the corners in order, the size the game's own sum gives
function Z.norm(a)
    if not (a and a.x1 and a.x2) then return nil end
    local x1, x2 = math.floor(math.min(a.x1, a.x2)), math.floor(math.max(a.x1, a.x2))
    local y1, y2 = math.floor(math.min(a.y1, a.y2)), math.floor(math.max(a.y1, a.y2))
    -- (ISAddNonPvpZoneUI: twice the width and twice the height, at least one)
    local size = math.max(math.floor(math.abs(x2 - x1) * 2 + math.abs(y2 - y1) * 2 + 0.5), 1)
    return { x1 = x1, y1 = y1, x2 = x2, y2 = y2, w = x2 - x1 + 1, h = y2 - y1 + 1, size = size }
end

function Z.overlapsSafe(n)
    for _, h in ipairs(Z.safes()) do
        if n.x1 < h.x + h.w and n.x2 >= h.x and n.y1 < h.y + h.h and n.y2 >= h.y then return true end
    end
    return false
end

function Z.overlapsPvp(n)
    local p = Z.player()
    if not p then return false end
    local ok, v = pcall(function() return p:checkZonesInterception(n.x1, n.x2, n.y1, n.y2) end)
    return ok and v == true
end

function Z.titleTaken(kind, title)
    if kind == "nonpvp" then
        for _, z in ipairs(Z.zones()) do
            if z.title == title then return true end
        end
        return false
    end
    for _, h in ipairs(Z.safes()) do
        if h.title == title then return true end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- THE CARD
-- ---------------------------------------------------------------------------
-- which: "zones" (the Zone editor row), "nonpvp" or "safe" (start on adding one)
function AZ.open(win, st, which)
    local card = { kind = "zones", from = "adm:b:more:zones", open = nil }
    D.setField(win, "zname", "")
    D.setField(win, "zowner", "")
    F.push(win, st, card)
    Z.card, Z.cardWin, Z.cardSt = card, win, st
    if which == "nonpvp" or which == "safe" then P.startAdd(win, st, card, which) end
end

function P.coords(x1, y1, x2, y2) return tr("UI_ZeD_Adm_ZoneCorners", x1, y1, x2, y2) end

function P.startAdd(win, st, card, kind)
    card.add, card.area = kind, nil
    local n = (kind == "nonpvp") and (#Z.zones() + 1) or (#Z.safes() + 1)
    -- (the field may not be made yet: the seed fills it the first time it draws, as the role card's description does)
    card.nameSeed = tr((kind == "nonpvp") and "UI_ZeD_Adm_ZoneDefault" or "UI_ZeD_Adm_SafeDefault", n)
    D.setField(win, "zname", card.nameSeed)
    D.setField(win, "zowner", "")
    Z.bump()
    D.focusId(win, st, "tk:f:zname")
end

function P.stopAdd(win, st, card)
    local kind = card.add
    card.add, card.area = nil, nil
    if Z.pick and Z.pick.card == card then Z.pick = nil end
    Z.bump()
    D.focusId(win, st, (kind == "safe") and "tk:zaddsafe" or "tk:zaddpvp")
end

-- the corners where the character stands: the game's windows' Redefine Starting Point, and the other corner
function P.corner(card, which)
    local p = Z.player()
    if not p then return end
    local x, y = math.floor(p:getX()), math.floor(p:getY())
    local a = card.area or {}
    if which == 1 or not a.x1 then
        a.x1, a.y1 = x, y
        if not a.x2 then a.x2, a.y2 = x, y end
    else
        a.x2, a.y2 = x, y
    end
    card.area = a
    Z.bump()
end

-- the map: the Maps tab with this card's pick armed
function P.pickOnMap(win, st, card)
    Z.pick = { card = card, win = win, st = st }
    local ok = ZeD_WorldWindow and ZeD_WorldWindow.openTab and ZeD_WorldWindow.openTab(0, "maps")
    -- (ZeD's mark tool and the extras' Teleport here go down: the press on the map is this pick's)
    if ZeD.MapsTab and ZeD.MapsTab.putDownTool then pcall(ZeD.MapsTab.putDownTool, win) end
    win._exTp = nil
    if not ok then
        Z.pick = nil
        D.flash(TC.qaState(st), tr("UI_ZeD_Adm_ZoneNoMap"))
    end
    Z.bump()
end

function P.mapWhy()
    if Z.qaMap ~= nil then
        if Z.qaMap then return nil end
        return tr("UI_ZeD_Adm_ZoneNoMap")
    end
    local MT = ZeD.MapsTab
    if not (MT and MT.isAllowed and MT.isAllowed()) then return tr("UI_ZeD_Adm_ZoneNoMap") end
    return nil
end

-- why the zone being added can't go in yet, or nil
function P.addWhy(win, card)
    local kind = card.add
    if not M.can(kind == "safe" and CAP_SAFE or CAP_PVP) then return M.why(kind == "safe" and CAP_SAFE or CAP_PVP) end
    local title = F.text(win, "zname")
    if title == "" then return tr("UI_ZeD_Adm_ZoneWriteName") end
    if Z.titleTaken(kind, title) then return getText("IGUI_PvpZone_ZoneAlreadyExistTitle") end
    local n = Z.norm(card.area)
    if not n then return tr("UI_ZeD_Adm_ZoneNoArea") end
    if n.size <= 1 then return tr("UI_ZeD_Adm_ZoneTooSmall") end
    if kind == "nonpvp" then
        if Z.overlapsPvp(n) then return getText("IGUI_PvpZone_ZoneInterception") end
    else
        local owner = F.text(win, "zowner")
        if owner == "" then return tr("UI_ZeD_Adm_ZoneWriteOwner") end
        if not Z.qaPlayer and not getPlayerFromUsername(owner) then return tr("UI_ZeD_Adm_ZoneOwnerOff", owner) end
        if Z.overlapsSafe(n) then return tr("UI_ZeD_Adm_ZoneOverlapSafe") end
    end
    return nil
end

function P.addItems(items, win, st, t, card)
    local kind = card.add
    F.inset(items, nil, function()
        B.label(items, tr(kind == "safe" and "UI_ZeD_Adm_AddSafe" or "UI_ZeD_Adm_AddPvp"))
        B.sub(items, tr(kind == "safe" and "UI_ZeD_Adm_AddSafeLine" or "UI_ZeD_Adm_AddPvpLine"))
        B.label(items, tr("UI_ZeD_Adm_Name"))
        F.field(items, "zname", 1, tr("UI_ZeD_Adm_ZoneNameHint"), true, NAME_MAX)
        items[#items].seed = card.nameSeed
        if kind == "safe" then
            B.label(items, tr("UI_ZeD_Adm_ZoneOwner"))
            F.field(items, "zowner", 1, tr("UI_ZeD_Adm_ZoneOwnerHint"), nil, NAME_MAX)
        end
        B.label(items, tr("UI_ZeD_Adm_ZoneArea"))
        local n = Z.norm(card.area)
        if n then
            B.sub(items, P.coords(n.x1, n.y1, n.x2, n.y2) .. " | " .. tr("UI_ZeD_Adm_ZoneSize", n.w, n.h))
        else
            B.sub(items, tr("UI_ZeD_Adm_ZoneNoArea"))
        end
        if Z.pick and Z.pick.card == card then B.sub(items, tr("UI_ZeD_Adm_ZonePicking")) end
        local cap = (kind == "safe") and CAP_SAFE or CAP_PVP
        F.flow(items, {
            F.gate({ id = "zmap", text = tr("UI_ZeD_Adm_ZonePickMap"), help = tr("UI_ZeD_Adm_HelpZonePickMap"),
                run = function(ww) P.pickOnMap(ww, st, card) end }, cap, P.mapWhy),
            F.gate({ id = "zc1", text = tr("UI_ZeD_Adm_ZoneCorner1"), help = tr("UI_ZeD_Adm_HelpZoneCorner"),
                run = function() P.corner(card, 1) end }, cap),
            F.gate({ id = "zc2", text = tr("UI_ZeD_Adm_ZoneCorner2"), help = tr("UI_ZeD_Adm_HelpZoneCorner"),
                run = function() P.corner(card, 2) end }, cap, function()
                    if not (card.area and card.area.x1) then return tr("UI_ZeD_Adm_ZoneCornerFirst") end
                    return nil
                end),
        })
    end)
end

function P.zoneRow(items, st, card, z, i)
    local open = card.sel == z.title
    items[#items + 1] = { k = "arow", left = z.title, leftMin = 110, meta = P.coords(z.x, z.y, z.x2, z.y2), right = tr("UI_ZeD_Adm_ZoneSizeN", z.size), on = open,
        c = { id = "z:" .. i, help = tr("UI_ZeD_Adm_HelpZoneRow"), land = i == 1,
            run = function()
                card.sel = (card.sel == z.title) and nil or z.title
                Z.bump()
            end } }
    if not open then return end
    local place = { x = math.floor((z.x + z.x2) / 2), y = math.floor((z.y + z.y2) / 2), z = 0 }
    F.flow(items, {
        { id = "zgo:" .. i, text = tr("UI_ZeD_Tk_GoThere"), help = tr("UI_ZeD_Adm_HelpZoneGo"), live = function(c) D.liveGo(c) end,
            run = function() D.goThere(st, place) end },
        F.gate({ id = "zdel:" .. i, text = tr("UI_ZeD_Adm_ZoneRemove"), danger = true, help = tr("UI_ZeD_Adm_HelpZoneRemove"),
            run = function(ww)
                local t = TC.qaState(st)
                t.confirm = { title = z.title, from = "tk:zdel:" .. i }
                D.focusId(ww, st, "tk:cno")
            end }, CAP_PVP),
    })
    items[#items].ctls[1].live(items[#items].ctls[1])
end

function P.items(win, st, t, card)
    local items = {}
    -- NON-PVP ZONES
    local zones = Z.zones()
    B.label(items, words(getText("IGUI_AdminPanel_NonPvpZone")), tostring(#zones))
    if not M.can(CAP_PVP) then B.sub(items, M.why(CAP_PVP)) end
    local p = Z.player()
    local okSee, seeing = false, false
    if p then okSee, seeing = pcall(function() return p:isSeeNonPvpZone() end) end
    seeing = okSee and seeing == true
    F.flow(items, { F.gate({ id = "zsee", style = "tick", text = words(getText("IGUI_PvpZone_SeeZone")), on = seeing, help = tr("UI_ZeD_Adm_HelpZoneSee"),
        run = function()
            local pl = Z.player()
            if pl then pcall(function() pl:setSeeNonPvpZone(not pl:isSeeNonPvpZone()) end) end
            card.saw = true
            Z.bump()
        end }, CAP_PVP) })
    if #zones == 0 then B.sub(items, tr("UI_ZeD_Adm_ZonesNone")) end
    for i, z in ipairs(zones) do P.zoneRow(items, st, card, z, i) end
    if card.add == "nonpvp" then
        P.addItems(items, win, st, t, card)
    else
        F.flow(items, { F.gate({ id = "zaddpvp", text = tr("UI_ZeD_Adm_AddPvp"), help = tr("UI_ZeD_Adm_AddPvpLine"),
            run = function(ww) P.startAdd(ww, st, card, "nonpvp") end }, CAP_PVP, function()
                if card.add then return tr("UI_ZeD_Adm_ZoneOneAtATime") end
                return nil
            end) })
    end
    -- SAFE ZONES
    B.label(items, tr("UI_ZeD_Adm_SafeZones"), tostring(#Z.safes()))
    if not M.can(CAP_SAFE) then B.sub(items, M.why(CAP_SAFE)) end
    B.sub(items, tr("UI_ZeD_Adm_SafeZonesLine"))
    if card.add == "safe" then
        P.addItems(items, win, st, t, card)
    else
        F.flow(items, { F.gate({ id = "zaddsafe", text = tr("UI_ZeD_Adm_AddSafe"), help = tr("UI_ZeD_Adm_AddSafeLine"),
            run = function(ww) P.startAdd(ww, st, card, "safe") end }, CAP_SAFE, function()
                if card.add then return tr("UI_ZeD_Adm_ZoneOneAtATime") end
                return nil
            end) })
    end
    return items
end

function P.addBtn(win, st, t, card)
    local b = D.btn("zadd", words(getText("IGUI_PvpZone_AddZone")), function(ww)
        local why = P.addWhy(ww, card)
        if why then
            D.flash(t, why)
            return
        end
        local n = Z.norm(card.area)
        local title = F.text(ww, "zname")
        local ok, err
        if card.add == "nonpvp" then
            ok, err = pcall(function() NonPvpZone.addNonPvpZone(title, n.x1, n.y1, n.x2, n.y2) end)
        else
            local owner = F.text(ww, "zowner")
            ok, err = pcall(function() sendSafezoneClaim(owner, n.x1, n.y1, n.w, n.h, title) end)
        end
        if not ok then
            ZeD.logOnce("zones: add", err)
            return
        end
        D.flash(t, tr("UI_ZeD_Adm_ZoneAdded", title))
        P.stopAdd(ww, st, card)
    end, "primary", tr("UI_ZeD_Adm_HelpZoneAdd"))
    local why = P.addWhy(win, card)
    if why then D.disable(b, why) end
    return b
end

TC.kinds.zones = {
    data = function() return true end,
    tick = function(win, st, t, card)
        Z.card, Z.cardWin, Z.cardSt = card, win, st
        Z.seenAt = getTimestampMs()
        if not card.readAt or Z.seenAt - card.readAt >= READ_MS then
            card.readAt = Z.seenAt
            local s = Z.sig()
            if s ~= card.sig then
                card.sig = s
                Z.bump()
            end
        end
        -- the area on the ground, every frame as the game's windows draw it: blue when it can go in, red when it overlaps
        local n = card.add and Z.norm(card.area)
        if n and not Z.qaZones then
            local bad = (card.add == "nonpvp" and Z.overlapsPvp(n)) or (card.add == "safe" and Z.overlapsSafe(n))
            pcall(addAreaHighlight, n.x1, n.y1, n.x2, n.y2, 0, bad and 1 or 0, 0, bad and 0 or 1, 0.25)
        end
    end,
    key = function(t, card)
        local a = card.area or {}
        return table.concat({ tostring(Z.seq), tostring(M.seq), tostring(card.sel), tostring(card.add), tostring(a.x1), tostring(a.y1),
            tostring(a.x2), tostring(a.y2), tostring(Z.pick ~= nil) }, ":")
    end,
    title = function() return words(getText("IGUI_AdminPanel_ZoneEditor")) end,
    help = function(t, card)
        if t.confirm then return tr("UI_ZeD_Adm_HelpZoneRemove") end
        if card.add then return tr("UI_ZeD_Adm_HelpZoneAdding") end
        return tr("UI_ZeD_Adm_HelpZones")
    end,
    items = function(win, st, t, card) return P.items(win, st, t, card) end,
    foot = function(win, st, t, card)
        local c = t.confirm
        if c then
            return { question = getText("IGUI_PvpZone_RemoveConfirm", c.title), main = {
                D.btn("cno", tr("UI_ZeD_Tk_KeepIt"), function(ww)
                    t.confirm = nil
                    D.focusId(ww, st, c.from)
                end, nil, tr("UI_ZeD_Adm_HelpZoneKeep")),
                D.btn("cyes", tr("UI_ZeD_Adm_ZoneRemove"), function(ww)
                    t.confirm = nil
                    local ok, err = pcall(function() NonPvpZone.removeNonPvpZone(c.title) end)
                    if not ok then ZeD.logOnce("zones: remove", err) end
                    card.sel = nil
                    D.flash(t, tr("UI_ZeD_Adm_ZoneRemoved", c.title))
                    Z.bump()
                    D.focusId(ww, st, "tk:zaddpvp")
                end, "danger", tr("UI_ZeD_Adm_HelpZoneRemove")) } }
        end
        if card.add then
            return { main = {
                D.btn("zcancel", getText("UI_Cancel"), function(ww) P.stopAdd(ww, st, card) end, nil, tr("UI_ZeD_Adm_HelpZoneCancel")),
                P.addBtn(win, st, t, card) } }
        end
        return { main = {} }
    end,
    padX = function(win, st, t, card)
        if t.confirm or not card.add then return nil end
        local b = P.addBtn(win, st, t, card)
        return { label = b.label, run = b.run, disabled = b.disabled, why = b.why }
    end,
    cancel = function(win, st, t, card)
        if t.confirm then
            local from = t.confirm.from
            t.confirm = nil
            D.focusId(win, st, from)
            return true
        end
        if card.add then
            P.stopAdd(win, st, card)
            return true
        end
        return false
    end,
    back = function(win, st, t, card)
        if Z.pick and Z.pick.card == card then Z.pick = nil end
        if Z.card == card then Z.card = nil end
        -- (the game's window takes its highlight off as it closes)
        if card.saw then
            local p = Z.player()
            if p then pcall(function() p:setSeeNonPvpZone(false) end) end
        end
    end,
}

-- ---------------------------------------------------------------------------
-- THE MAP: the zones drawn on it, and the pick
-- ---------------------------------------------------------------------------
-- the zones card shows lately: the map draws the zones while it does
function Z.cardLive()
    return Z.card ~= nil and Z.seenAt ~= nil and getTimestampMs() - Z.seenAt < 60000
end

function Z.toWorld(mp, x, y)
    return math.floor(mp.mapAPI:uiToWorldX(x, y)), math.floor(mp.mapAPI:uiToWorldY(x, y))
end

function Z.rect(mp, x1, y1, x2, y2, c, a)
    local api = mp.mapAPI
    local ax, ay = api:worldToUIX(x1, y1), api:worldToUIY(x1, y1)
    local bx, by = api:worldToUIX(x2 + 1, y2 + 1), api:worldToUIY(x2 + 1, y2 + 1)
    local l, t = math.min(ax, bx), math.min(ay, by)
    local w, h = math.max(1, math.abs(bx - ax)), math.max(1, math.abs(by - ay))
    mp:drawRect(l, t, w, h, a, c.r, c.g, c.b)
    mp:drawRectBorder(l, t, w, h, 1, c.r, c.g, c.b)
end

-- the pick done: the area on the card, the Admin tab back
function Z.finish(mp, win, x, y)
    local pk = Z.pick
    if not (pk and pk.from) then return end
    local wx, wy = Z.toWorld(mp, x, y)
    pk.card.area = { x1 = pk.from.x, y1 = pk.from.y, x2 = wx, y2 = wy }
    Z.pick = nil
    Z.bump()
    if ZeD_WorldWindow and ZeD_WorldWindow.openTab then pcall(ZeD_WorldWindow.openTab, 0, "admin") end
    if pk.st and pk.win then D.focusId(pk.win, pk.st, "tk:zadd") end
end

function Z.start(mp, x, y)
    local wx, wy = Z.toWorld(mp, x, y)
    Z.pick.from = { x = wx, y = wy }
    Z.pick.to = { x = wx, y = wy }
end

function Z.drag(mp, x, y)
    if not (Z.pick and Z.pick.from) then return end
    local wx, wy = Z.toWorld(mp, x, y)
    Z.pick.to = { x = wx, y = wy }
end

ZeD.MapsTab.addExtension("admin_zones", {
    order = 45,
    button = function(win)
        if not Z.pick then return nil end
        return { id = "adm:zones:cancel", text = tr("UI_ZeD_Adm_ZonePickCancel"), help = tr("UI_ZeD_Adm_HelpZonePickCancel"), on = true,
            activate = function()
                Z.pick = nil
                Z.bump()
                if ZeD_WorldWindow and ZeD_WorldWindow.openTab then pcall(ZeD_WorldWindow.openTab, 0, "admin") end
            end }
    end,
    banner = function(win)
        if Z.pick then return tr("UI_ZeD_Adm_ZoneBanner") end
        return nil
    end,
    armed = function(win) return Z.pick ~= nil end,
    putDown = function(win) Z.pick = nil end,
    mouseDown = function(mp, win, x, y)
        if not Z.pick then return false end
        Z.start(mp, x, y)
        return true
    end,
    mouseMove = function(mp, win, x, y) Z.drag(mp, x, y) end,
    mouseUp = function(mp, win, x, y) Z.finish(mp, win, x, y) end,
    padA = function(mp, win, x, y, phase)
        if not Z.pick then return end
        if phase == "down" then Z.start(mp, x, y)
        elseif phase == "hold" then Z.drag(mp, x, y)
        else Z.finish(mp, win, x, y) end
    end,
    drawMap = function(mp, win)
        if not (Z.pick or Z.cardLive()) then return end
        local T = ZeD.T
        for _, z in ipairs(Z.zones()) do Z.rect(mp, z.x, z.y, z.x2, z.y2, T.info or T.accent, 0.15) end
        for _, h in ipairs(Z.safes()) do Z.rect(mp, h.x, h.y, h.x + h.w - 1, h.y + h.h - 1, T.positive or T.accent, 0.15) end
        local pk = Z.pick
        if pk and pk.from and pk.to then Z.rect(mp, pk.from.x, pk.from.y, pk.to.x, pk.to.y, T.accent, 0.3) end
    end,
})

-- ---------------------------------------------------------------------------
-- QA
-- ---------------------------------------------------------------------------
function AZ.qaOpen(win, st, which)
    st.card = nil
    AZ.open(win, st, which)
end

function AZ.qaArea(st, x1, y1, x2, y2)
    st.card.area = { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
    Z.bump()
end

return AZ
