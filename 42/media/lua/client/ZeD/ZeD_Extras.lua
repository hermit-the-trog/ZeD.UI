-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Extras.lua
-- ============================================================================
-- THE SERVER EXTRAS, THE CLIENT'S MODEL (ZeDUI/MP_ADMIN_SCOPE.md, Phase 6). No drawing: ZeD_ExtrasCards.lua reads this and
-- calls it. The server decides everything; this holds what it said, and sends what the cards ask.
--
-- Without the server part E.set stays nil and nothing here does anything: the extras are ZeD's, and the game has no version
-- of them to fall back on. With every extra off nothing is wrapped and nothing is asked.
--
-- One thing only a client can do: item transfers are Java on the server, with no Lua at all, so the container log is this
-- client reporting its own takes from containers inside a safehouse (x_took). A modified client can stay silent and a client
-- that drops off loses what it held, and the card and the log's line say so. The wrap goes on the first time the server says
-- the log is on, never before.
--
-- QA, read at call time (the ticket cards' style):
--   E.qaHold   true: no traffic. The screen shows only what the QA script put in the model
--   E.qaLink   true / false: the server part as the cards read it
-- ============================================================================

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_ExtrasProto"
require "ZeD/ZeD_ServerLink"
require "ZeD/ZeD_Tickets"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.Extras = ZeD.Extras or {}
local E = ZeD.Extras
local S = ZeD.ServerPart
local Ex = ZeD.Ex
local K = ZeD.Tickets
local L = Ex.L

local ASK_MS = 3000                   -- a car on the Vehicle tab is asked about this often

E.seq = E.seq or 0                    -- bumps on every change (the cards re-read)
E.cars = E.cars or {}                 -- vehicle id -> { at, view }
E.took = E.took or {}                 -- "x,y,z" -> what this client has taken there, on its way to the server

local function now() return getTimestampMs() end
local function tr(k, ...) return ZeD.tr(k, ...) end
function E.bump() E.seq = E.seq + 1 end

function E.live()
    if E.qaLink ~= nil then return E.qaLink end
    return S.available() and E.set ~= nil
end

function E.claimsOn() return E.live() and E.set ~= nil and E.set.vc.on end

-- the server's word for a refusal: its own errors first, then the tickets' shared ones
local ERR = { off = true, far = true, burnt = true, driven = true, soon = true, taken = true, many = true, key = true, gone = true,
    full = true, frozen = true, text = true, house = true, changed = true, fail = true }
function E.errText(a)
    local err = a.err or "fail"
    if err == "wait" then return tr("UI_ZeD_Ex_Err_wait", a.left or 1) end
    if ERR[err] then return tr("UI_ZeD_Ex_Err_" .. err) end
    return K.errText(err, a.left)
end

function E.request(cmd, args, cb)
    K.requestOn(Ex.MOD, cmd, args, function(a)
        if cb then cb(a) end
        E.bump()
    end)
end

-- was: the set the changes were made on (the server refuses a save that would undo another admin's)
function E.save(set, cb, was) E.request("x_save", { set = set, was = was or E.set }, cb) end

-- a line over the player's head, as the map's ink refusals have
function E.say(text, good)
    local p = getPlayer()
    if not (p and HaloTextHelper) then return end
    if good then HaloTextHelper.addGoodText(p, text) else HaloTextHelper.addBadText(p, text) end
end

-- ---------------------------------------------------------------------------
-- CLAIMS
-- ---------------------------------------------------------------------------
-- what the server said of this car, asking again every few seconds while the tab shows it. nil: not heard yet
function E.car(v)
    if not E.claimsOn() then return nil end
    local id = v:getId()
    local c = E.cars[id]
    local t = now()
    if not E.qaHold and (not c or t - c.at >= ASK_MS) then
        if not c then
            c = {}
            E.cars[id] = c
        end
        c.at = t
        S.send(Ex.MOD, "x_veh", { veh = id })
    end
    return c and c.view
end

-- the server refuses this anyway, at the end of the wait: gray it first. The owner's name, or nil
function E.partsBlock(v)
    if not (E.claimsOn() and E.set.vc.parts) then return nil end
    local view = E.car(v)
    if view and view.owner and not view.mine and not view.staff then return view.owner end
    return nil
end

function E.claim(v, cb)
    E.request("x_claim", { veh = v:getId() }, function(a)
        E.cars[v:getId()] = nil
        E.mineRows = nil
        if cb then cb(a) end
    end)
end

function E.release(key, cb)
    E.request("x_release", { key = key }, function(a)
        E.cars = {}
        E.mineRows = nil
        if cb then cb(a) end
    end)
end

-- my claims, asked when a card or the tab wants them and no answer is held
function E.mine()
    if E.claimsOn() and not E.mineRows and not E.qaHold then
        local t = now()
        if not E.mineAt or t - E.mineAt >= L.MINE_MS then
            E.mineAt = t
            S.send(Ex.MOD, "x_mine", {})
        end
    end
    return E.mineRows
end

-- ---------------------------------------------------------------------------
-- THE MAP'S TELEPORT
-- ---------------------------------------------------------------------------
-- the server says the setting is on and logs it; the game's /teleportto does the going and asks its own capability
function E.goTo(x, y, cb)
    E.request("x_tp", { x = x, y = y }, function(a)
        if a.ok then SendCommandToServer("/teleportto " .. tostring(x) .. "," .. tostring(y) .. ",0") end
        if cb then cb(a) end
    end)
end

-- ---------------------------------------------------------------------------
-- THE CONTAINER LOG: this client's report of its own takes
-- ---------------------------------------------------------------------------
local function newBatch(sq, src)
    return { x = sq:getX(), y = sq:getY(), z = sq:getZ(), from = src:getType(), at = now(), names = {}, rows = {} }
end

function E.noteTake(self)
    if not (E.set and E.set.cl.on and E.live()) then return end
    local src, dest, chr = self.srcContainer, self.destContainer, self.character
    if not (src and dest and chr) then return end
    if src:isInCharacterInventory(chr) or not dest:isInCharacterInventory(chr) then return end
    local sq = src:getSourceGrid()
    if not (sq and SafeHouse.getSafeHouse(sq)) then return end
    local q = self.queueList and self.queueList[1]
    local items = q and q.items or { self.item }
    local key = tostring(sq:getX()) .. "," .. tostring(sq:getY()) .. "," .. tostring(sq:getZ())
    local e = E.took[key]
    if not e then
        e = newBatch(sq, src)
        E.took[key] = e
        E.tookAny = true
    end
    for _, it in ipairs(items) do
        local name = it:getDisplayName()
        local r = e.names[name]
        if not r then
            if #e.rows >= L.TOOK_ROWS then
                -- a full report goes as it is, under a name of its own, and a new one opens
                E.tookSeq = (E.tookSeq or 0) + 1
                E.took[key .. ":" .. tostring(E.tookSeq)] = e
                e = newBatch(sq, src)
                E.took[key] = e
            end
            r = { name = name, n = 0 }
            e.names[name] = r
            e.rows[#e.rows + 1] = r
        end
        r.n = r.n + 1
    end
end

function E.tookTick()
    if not E.tookAny then return end
    local t = now()
    if E.tookSent and t - E.tookSent < L.TOOK_SEND_MS then return end
    E.tookAny = false
    for key, e in pairs(E.took) do
        E.tookAny = true
        if t - e.at >= L.TOOK_BATCH_MS then
            E.took[key] = nil
            E.tookSent = t
            S.send(Ex.MOD, "x_took", { x = e.x, y = e.y, z = e.z, from = e.from, rows = e.rows })
            return
        end
    end
end

-- the first time the log is on. The wrap stays after that, and tests the setting first
local function armLog()
    if E.logArmed or not ISInventoryTransferAction then return end
    E.logArmed = true
    local base = ISInventoryTransferAction.perform
    ISInventoryTransferAction.perform = function(self)
        local ok, err = pcall(E.noteTake, self)
        if not ok then ZeD.logOnce("extras: take", err) end
        return base(self)
    end
    Events.OnTick.Add(function()
        local ok, err = pcall(E.tookTick)
        if not ok then ZeD.logOnce("extras: took", err) end
    end)
end

-- ---------------------------------------------------------------------------
-- WHAT THE SERVER SAYS
-- ---------------------------------------------------------------------------
local function heardSet(set)
    E.set = Ex.clean(set)
    E.cars = {}
    E.mineRows = nil
    if E.set.cl.on then armLog() end
    E.bump()
end

local on = {}
function on.x_set(a) heardSet(a.set) end

function on.x_veh(a)
    local c = E.cars[a.veh]
    if not c then
        c = { at = now() }
        E.cars[a.veh] = c
    end
    c.view = { n = a.n, per = a.per, staff = a.staff == true, key = a.key, owner = a.owner, mine = a.mine == true }
    E.bump()
end

function on.x_mine(a)
    E.mineRows = a.rows or {}
    E.minePer = a.per
    E.bump()
end

function on.x_no(a) E.say(tr("UI_ZeD_Ex_No_" .. tostring(a.what), tostring(a.who))) end

S.on(Ex.MOD, function(command, args)
    local fn = on[command]
    if fn then fn(args) end
end)

function E.onHello(a)
    E.frozen = a.exFrozen == true
    if a.ex then
        heardSet(a.ex)
    elseif E.set then
        -- (a server without the extras: what the last server said goes with it)
        E.set, E.mineRows = nil, nil
        E.cars = {}
        E.bump()
    end
end

return E
