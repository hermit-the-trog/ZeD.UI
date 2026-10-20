-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardFire.lua
-- ============================================================================
-- OBJECT CARD: FIRES (HOOK_MAP row 12; mockup zed_info_cards_v1.html)
-- One fire card for campfires, charcoal barbecues and fireplaces: fuel as time
-- left on a strip that ends at the sandbox maximum, ADD FUEL (what you carry
-- that burns and the time each piece adds), LIGHT WITH (the methods vanilla
-- offers), what is on the fire with the item card's cooking reading, and
-- SMOULDERING as a third state. The propane barbecue gets its own plate: the
-- game's Jorge Foreguy cart grill in pixel art (director, Oct 16 2026; the
-- shared plate template ZeD_Plate.lua draws it from PhysPx.lua): the burner
-- knobs' pointers, the flames' glow under the hood, the lid thermometer, the
-- tank gauge and the tank in the cart. The centre knob and the red igniter
-- light it or shut it off, the cart takes a tank in or gives it back. Under the
-- plate the hours of gas, then the grill's contents.
-- Every action goes through vanilla's camping / barbecue handlers.
-- ============================================================================

require "ZeD/ObjectCards"
require "ZeD/ZeD_PixelParts"
require "ZeD/ZeD_Plate"
require "ZeD/PhysPx"

local OC = ZeD.ObjectCards
local P = ZeD.Px
local PL = ZeD.Plate
local UI = OC.ui
local call = OC.call
local DOT = OC.DOT

local PROPANE_FULL_MIN = 1200   -- a full propane tank: 20 hours of gas
local GRILL_SETTLE_MS = 4000    -- the lid thermometer's needle creeps up after lighting, down after

local function campfireSystem() return CCampfireSystem and CCampfireSystem.instance or nil end

local function fuelMax()
    if getCampingFuelMax then
        local ok, v = pcall(getCampingFuelMax)
        if ok and v and v > 0 then return v end
    end
    local h = SandboxVars and SandboxVars.MaximumFireFuelHours or 8
    return h * 60
end

local function fireObjectOn(sq)
    if not sq then return nil end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o and call(o, "isFireInteractionObject") then return o end
    end
    return nil
end

local function spriteIcon(iso)
    local tile = iso and call(iso, "getSpriteName")
    local tex = tile and getTexture(tile)
    if not tex then return nil end
    return call(tex, "splitIcon") or tex
end

local def = { id = "fire" }

-- Accepts a campfire (its Lua object or the IsoObject) or a barbecue /
-- fireplace IsoObject.
function def.resolve(player, obj)
    if not obj then return nil end
    local sq = call(obj, "getSquare")
    if not sq then return nil end
    local sys = campfireSystem()
    local lua = sys and sys:getLuaObjectOnSquare(sq)
    if lua then
        return { kind = "campfire", obj = lua, sq = sq, key = OC.keyOf(sq, "campfire") }
    end
    local fo = (call(obj, "isFireInteractionObject") and obj) or fireObjectOn(sq)
    if not fo then return nil end
    local kind = call(fo, "isPropaneBBQ") and "propane" or (instanceof(fo, "IsoFireplace") and "fireplace" or "charcoal")
    return { kind = kind, obj = fo, sq = sq, key = OC.keyOf(sq, "fire") }
end

function def.valid(t)
    if t.kind == "campfire" then
        local sys = campfireSystem()
        local lua = sys and sys:getLuaObjectOnSquare(t.sq)
        if not lua then return false end
        t.obj = lua
        return lua:getIsoObject() ~= nil
    end
    return t.obj ~= nil and t.obj:getObjectIndex() ~= -1
end

function def.nearby(player)
    local list = {}
    local sys = campfireSystem()
    OC.eachSquare(player, OC.LEASH, function(sq)
        local lua = sys and sys:getLuaObjectOnSquare(sq)
        if lua then
            list[#list + 1] = { kind = "campfire", obj = lua, sq = sq, key = OC.keyOf(sq, "campfire") }
        else
            local fo = fireObjectOn(sq)
            if fo then list[#list + 1] = def.resolve(player, fo) end
        end
    end)
    return OC.sortTargets(list)
end

-- ---------------------------------------------------------------------------
-- REFRESH
-- ---------------------------------------------------------------------------
local function iso(t) return t.kind == "campfire" and t.obj:getIsoObject() or t.obj end

local function fuelRows(info, current, max, player)
    local rows = {}
    local list = {}
    for _, it in ipairs(info.fuelList or {}) do list[#list + 1] = it end
    table.sort(list, function(a, b)
        return ISCampingMenu.getFuelDurationForItem(a) > ISCampingMenu.getFuelDurationForItem(b)
    end)
    local totalN, totalDur = 0, 0
    for _, it in ipairs(list) do
        local count = info.itemCount[it:getName()] or 1
        local dur = ISCampingMenu.getFuelDurationForItem(it) or 0
        -- vanilla's cap loop: as many of this type as the fire still holds
        local fitN = count
        while current + dur * fitN > max and fitN > 1 do fitN = fitN - 1 end
        totalN = totalN + count
        totalDur = totalDur + dur * count
        rows[#rows + 1] = {
            item = it, fullType = it:getFullType(), name = it:getName() .. (count > 1 and (" x" .. tostring(count)) or ""),
            baseName = it:getName(),
            tex = it:getTex(), where = OC.whereOf(it, player), dur = dur, count = count,
            fits = current + dur <= max,
            fitN = fitN, allFits = (fitN == count),
        }
    end
    -- the all-types total (vanilla's "All (N)" across the list)
    rows.totalN, rows.totalDur = totalN, totalDur
    return rows
end

-- The lighting methods vanilla offers (one row per tinder, first starter).
local function lightRows(info, hasFuel, player)
    local rows = {}
    local starters = info.starters or {}
    local starter = starters[1]
    if starter and hasFuel and info.petrol then
        rows[#rows + 1] = { method = "petrol", name = info.petrol:getName(), with = starter:getName(),
            tex = info.petrol:getTex(), where = OC.whereOf(info.petrol, player), starter = starter, petrol = info.petrol }
    end
    if starter then
        for _, v in ipairs(info.tinder or {}) do
            local count = info.itemCount[v:getName()] or 1
            rows[#rows + 1] = { method = "tinder", name = v:getName() .. (count > 1 and (" x" .. tostring(count)) or ""), with = starter:getName(),
                tex = v:getTex(), where = OC.whereOf(v, player), starter = starter, tinderType = v:getFullType(),
                dur = ISCampingMenu.getFuelDurationForItem(v) }
        end
    end
    if info.percedWood then
        local stick = info.stick or info.branch
        local endurance = player:getStats():get(CharacterStat.ENDURANCE)
        local ok = stick ~= nil and hasFuel and endurance > 0
        local need = nil
        if not stick then need = "NEEDS A STICK"
        elseif not hasFuel then need = "NEEDS FUEL"
        elseif endurance <= 0 then need = "TOO TIRED" end
        rows[#rows + 1] = { method = "kindle", name = info.percedWood:getName(), with = stick and stick:getName() or nil,
            tex = info.percedWood:getTex(), where = OC.whereOf(info.percedWood, player), percedWood = info.percedWood, stick = stick,
            enabled = ok, need = need }
    end
    return rows
end

local function refreshPropane(t, player)
    local o = t.obj
    local d = { propane = true }
    d.lit = o:isLit()
    d.tank = o:hasPropaneTank()
    d.hasFuel = o:hasFuel()
    d.fuel = o:getFuelAmount() or 0
    d.name = call(o, "getTileName") or "Propane Barbecue"
    d.tex = spriteIcon(o)
    d.container = call(o, "getContainer")
    d.spare = ISBBQMenu.FindPropaneTank(player, o)
    t.d = d
    local verbs, needs = {}, {}
    local toggle = function(p, tt) ISBBQMenu.onToggle(nil, p:getPlayerNum(), tt.obj) end
    t.toggle = d.hasFuel and toggle or nil
    verbs[#verbs + 1] = { id = "power", label = d.lit and "TURN OFF" or "TURN ON", primary = d.hasFuel, enabled = d.hasFuel, run = toggle }
    verbs[#verbs + 1] = { id = "insert", label = "INSERT TANK", enabled = d.spare ~= nil, primary = (not d.hasFuel) and d.spare ~= nil,
        run = function(p, tt)
            local tank = ISBBQMenu.FindPropaneTank(p, tt.obj)
            if tank then ISBBQMenu.onInsertPropaneTank(nil, p:getPlayerNum(), tt.obj, tank) end
        end }
    verbs[#verbs + 1] = { id = "remove", label = "REMOVE TANK", enabled = d.tank,
        run = function(p, tt) ISBBQMenu.onRemovePropaneTank(nil, p:getPlayerNum(), tt.obj) end }
    if not d.hasFuel then needs[#needs + 1] = "Turn on: needs a propane tank with gas" end
    if not d.spare and not d.tank then needs[#needs + 1] = "Insert tank: needs a propane tank" end
    t.verbs, t.needs = verbs, needs
end

function def.refresh(t, player)
    if t.kind == "propane" then return refreshPropane(t, player) end
    local d = {}
    local io = iso(t)
    if t.kind == "campfire" then
        pcall(function() t.obj:updateFromIsoObject() end)
        d.fuel = t.obj.fuelAmt or 0
        d.lit = t.obj.isLit == true
        d.smoulder = false
    else
        d.fuel = t.obj:getFuelAmount() or 0
        d.lit = t.obj:isLit()
        d.smoulder = (not d.lit) and (call(t.obj, "isSmouldering") == true)
    end
    d.max = fuelMax()
    d.name = (io and call(io, "getTileName")) or (t.kind == "campfire" and "Campfire" or "Fire")
    d.tex = spriteIcon(io)
    d.container = io and call(io, "getContainer")
    local info = ISCampingMenu.getNearbyFuelInfo(player)
    d.fuelRows = fuelRows(info, d.fuel, d.max, player)
    d.lightRows = (not d.lit) and lightRows(info, d.fuel > 0, player) or {}
    t.d = d

    local addAction = (t.kind == "campfire") and ISAddFuelAction or ISBBQAddFuel
    t.addFuel = function(p, row)
        ISCampingMenu.onAddFuel(p, t.obj, row.fullType, addAction, d.fuel)
    end
    -- vanilla's bulk adds: every one of a type that fits (or all that fit),
    -- and everything on the list. The capped count is passed explicitly
    -- because vanilla only checks the cap per item, not across the batch.
    t.addFuelMany = function(p, row)
        ISCampingMenu.onAddMultipleFuel(p, t.obj, row.fullType, addAction, d.fuel, (not row.allFits) and row.fitN or nil)
    end
    t.addFuelAll = function(p)
        ISCampingMenu.onAddAllFuel(p, t.obj, addAction, d.fuel)
    end
    local petrolA = (t.kind == "campfire") and ISLightFromPetrol or ISBBQLightFromPetrol
    local tinderA = (t.kind == "campfire") and ISLightFromLiterature or ISBBQLightFromLiterature
    local kindleA = (t.kind == "campfire") and ISLightFromKindle or ISBBQLightFromKindle
    t.light = function(p, row)
        if row.method == "petrol" then
            ISCampingMenu.onLightFromPetrol(p, row.starter, row.petrol, t.obj, petrolA)
        elseif row.method == "tinder" then
            ISCampingMenu.onLightFromLiterature(p, row.tinderType, row.starter, t.obj, tinderA)
        elseif row.method == "kindle" then
            ISCampingMenu.onLightFromKindle(p, row.percedWood, row.stick, t.obj, kindleA)
        end
    end

    local verbs, needs = {}, {}
    local full = d.fuel >= d.max
    local anyFits = false
    for _, r in ipairs(d.fuelRows) do if r.fits then anyFits = true end end
    local canLight = false
    for _, r in ipairs(d.lightRows) do if r.enabled ~= false then canLight = true end end
    local fuelOK = (not full) and anyFits
    verbs[#verbs + 1] = { id = "fuel", label = "ADD FUEL", enabled = fuelOK, primary = fuelOK and (d.lit or not canLight), jump = "fire:fuel:1" }
    verbs[#verbs + 1] = { id = "out", label = "PUT OUT", enabled = d.lit,
        run = function(p, tt)
            if tt.kind == "campfire" then ISCampingMenu.onPutOutCampfire(nil, p, tt.obj)
            else ISBBQMenu.onExtinguish(nil, p:getPlayerNum(), tt.obj) end
        end }
    verbs[#verbs + 1] = { id = "light", label = "LIGHT", enabled = (not d.lit) and canLight, primary = (not d.lit) and canLight, jump = "fire:light:1" }
    if t.kind == "campfire" then
        verbs[#verbs + 1] = { id = "take", label = "TAKE APART", danger = true,
            confirm = "Take the campfire apart? You get 3 stones; what is on it drops.",
            run = function(p, tt) ISCampingMenu.onRemoveCampfire(nil, p, tt.obj) end }
    end
    if full then needs[#needs + 1] = "The fire holds no more fuel"
    elseif #d.fuelRows == 0 then needs[#needs + 1] = "Add fuel: needs something that burns" end
    if not d.lit and not canLight then
        if d.fuel <= 0 then needs[#needs + 1] = "Light: needs fuel in the fire first"
        else needs[#needs + 1] = "Light: needs a lighter or matches with tinder, or a notched plank and a stick" end
    end
    t.verbs, t.needs = verbs, needs
end

function def.title(t) return t.d and t.d.name or "Fire" end
function def.icon(t) return t.d and t.d.tex or nil end
function def.pill(t)
    local T = ZeD.T
    local d = t.d
    if not d then return nil end
    if d.propane then
        if d.lit then return "BURNING", T.positive end
        if not d.tank then return "NO TANK", T.textDim end
        return "OFF", T.textDim
    end
    if d.lit then return "BURNING", T.positive end
    if d.smoulder then return "SMOULDERING", T.warning end
    return "OUT", T.textDim
end

-- ---------------------------------------------------------------------------
-- BODY
-- ---------------------------------------------------------------------------
local function drawFuelStrip(card, x, y, w, d)
    local T, tm = ZeD.T, ZeD.TM
    local y0 = y
    local maxH = d.max / 60
    -- big readout: time left + "OF FUEL | HOLDS 8 H"
    local bigPx = 26
    local bw = UI.big(card, OC.hm(d.fuel), x, y, bigPx, T.text) or 0
    local bigH = math.floor(T.px(bigPx) * 1.0)
    local small = "OF FUEL " .. DOT .. " HOLDS " .. tostring(math.floor(maxH + 0.5)) .. " H"
    local f1 = T.fontF1
    card:drawText(small, x + bw + T.px(8), y + bigH - tm:getFontHeight(f1), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f1)
    y = y + bigH + T.px(8)
    -- hour cells to the sandbox maximum
    local cells = math.max(4, math.min(12, math.ceil(maxH)))
    local gap = T.px(3)
    local cw = math.floor((w - gap * (cells - 1)) / cells)
    local ch = T.px(12)
    local perCell = d.max / cells
    -- burning: amber; smouldering: half amber; out: fuel waiting, muted amber
    local fillC = d.lit and T.warning or ZeD.colorBlend(T.warning, T.surf2, d.smoulder and 0.35 or 0.6)
    for i = 0, cells - 1 do
        local cx = x + i * (cw + gap)
        local s1 = T.surf1
        card:drawRect(cx, y, cw, ch, s1.a, s1.r, s1.g, s1.b)
        local f = math.max(0, math.min(1, (d.fuel - i * perCell) / perCell))
        if f > 0 then card:drawRect(cx, y, math.floor(cw * f), ch, 1, fillC.r, fillC.g, fillC.b) end
        card:drawRectBorder(cx, y, cw, ch, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
    end
    y = y + ch + T.px(4)
    -- scale: NOW ... FULL with even hour marks between
    local f5 = T.fontF5
    local dc = T.textDim
    card:drawText("NOW", x, y, dc.r, dc.g, dc.b, dc.a or 1, f5)
    ZeD.Atoms.drawTextRight(card, "FULL", x + w, y, f5, dc)
    local marks = 3
    for k = 1, marks do
        local hrs = maxH * k / (marks + 1)
        local lbl = "+" .. tostring(math.floor(hrs + 0.5)) .. " H"
        local lw = tm:MeasureStringX(f5, lbl)
        card:drawText(lbl, x + math.floor(w * k / (marks + 1) - lw / 2), y, dc.r, dc.g, dc.b, dc.a or 1, f5)
    end
    y = y + tm:getFontHeight(f5)
    return y - y0
end

local function fireBody(card, x, y, w, t, player)
    local T = ZeD.T
    local d = t.d
    local y0 = y
    local gap = T.px(8)
    y = y + drawFuelStrip(card, x, y, w, d) + gap
    if t.needs and #t.needs > 0 then y = y + UI.needs(card, x, y, w, t.needs) + gap end

    if not d.lit and #d.lightRows > 0 then
        y = y + UI.section(card, x, y, w, "LIGHT WITH", "")
        for i, r in ipairs(d.lightRows) do
            local rr = r
            y = y + UI.pick(card, x, y, w, {
                tex = r.tex, name = r.name,
                gain = r.dur and ("+" .. OC.hm(r.dur)) or nil,
                tag = r.need or (r.with and string.upper(r.with)) or nil, tagC = T.textDim,
                button = "LIGHT", fid = "fire:light:" .. i, enabled = r.enabled ~= false,
                run = function(c, p) t.light(p, rr) end,
            })
        end
        y = y + gap
    end

    if #d.fuelRows > 0 then
        y = y + UI.section(card, x, y, w, "ADD FUEL FROM YOUR BAGS", "ADDS")
        local rows = d.fuelRows
        -- one button for everything on the list, when more than one piece
        -- is carried and the whole lot fits (vanilla's "All")
        if #rows > 1 and (rows.totalN or 0) > 1 then
            local lotFits = d.fuel + rows.totalDur <= d.max
            y = y + UI.pick(card, x, y, w, {
                tex = rows[1].tex, name = "All fuel (" .. tostring(rows.totalN) .. ")",
                gain = "+" .. OC.hm(rows.totalDur),
                tag = (not lotFits) and "FULL" or nil, tagC = T.textDim,
                button = "ADD ALL", fid = "fire:fuelall", enabled = lotFits,
                run = function(c, p) t.addFuelAll(p) end,
            })
        end
        for i, r in ipairs(rows) do
            local rr = r
            local gain = "+" .. OC.hm(r.dur) .. (r.count > 1 and " each" or "")
            y = y + UI.pick(card, x, y, w, {
                tex = r.tex, name = r.name, where = r.where, gain = gain,
                tag = (not r.fits) and "FULL" or nil, tagC = T.textDim,
                button = "ADD", fid = "fire:fuel:" .. i, enabled = r.fits,
                run = function(c, p) t.addFuel(p, rr) end,
            })
            -- several of this type: add all of them, or all that fit
            if r.fitN > 1 then
                y = y + UI.pick(card, x, y, w, {
                    tex = r.tex,
                    name = r.baseName .. ": " .. (r.allFits and "all" or "all that fit") .. " (" .. tostring(r.fitN) .. ")",
                    gain = "+" .. OC.hm(r.dur * r.fitN),
                    button = "ADD ALL", fid = "fire:fuelmany:" .. i, enabled = r.fits,
                    run = function(c, p) t.addFuelMany(p, rr) end,
                })
            end
        end
        y = y + gap
    end

    local items = d.container and call(d.container, "getItems")
    local n = items and items:size() or 0
    if n > 0 then
        y = y + UI.section(card, x, y, w, "ON THE FIRE", tostring(n))
        y = y + UI.cookRows(card, x, y, w, d.container, d.lit)
    end
    return y - y0
end

-- the grill's plate: what its live parts read (the thermometer settles, it has weight)
local function grillState(t, d)
    local st = { lit = d.lit, tank = d.tank, tankF = d.tank and math.max(0, math.min(1, d.fuel / PROPANE_FULL_MIN)) or 0 }
    local target = d.lit and 0.74 or 0.04
    local now = getTimestampMs()
    local cur = t._grillT
    if cur == nil then cur = target end
    local dt = t._grillMs and math.max(0, math.min(250, now - t._grillMs)) or 0
    cur = cur + (target - cur) * (dt / (GRILL_SETTLE_MS + dt))
    t._grillT, t._grillMs = cur, now
    st.grillTemp = cur
    return st
end
local function plateTex(name) return P.tex(ZeD.PhysPx.texdir .. name .. ".png") end

local function propaneBody(card, x, y, w, t, player)
    local T = ZeD.T
    local d = t.d
    local y0 = y
    local gap = T.px(8)
    local X = ZeD.PhysPx
    local des = X and X.plates[X.fallback.propane]
    if des then
        local Sc = ZeD.Scale
        local k = P.k((Sc and Sc.root and Sc.root()) or 1)
        local px0 = x + PL.centre(w, des.w, k)
        local cv = P.canvas(card, px0, y, k)
        local st = grillState(t, d)
        PL.draw(cv, des, st, { tex = plateTex, now = getTimestampMs() })
        -- the centre knob turns it on or off; the igniter lights it; the cart takes a tank or gives it back
        local function tankFn(p, tt)
            if tt.obj:hasPropaneTank() then ISBBQMenu.onRemovePropaneTank(nil, p:getPlayerNum(), tt.obj)
            else
                local tank = ISBBQMenu.FindPropaneTank(p, tt.obj)
                if tank then ISBBQMenu.onInsertPropaneTank(nil, p:getPlayerNum(), tt.obj, tank) end
            end
        end
        local function ignite(p, tt) if not tt.obj:isLit() and t.toggle then t.toggle(p, tt) end end
        for _, c in ipairs(PL.controls(des, st)) do
            local fid = "bbq:" .. c.id
            local fn = nil
            if c.id == "burner" then fn = t.toggle
            elseif c.id == "ignite" then fn = (not d.lit and t.toggle) and ignite or nil
            elseif c.id == "tank" then fn = (d.tank or d.spare) and tankFn or nil end
            if card._fid == fid then PL.cue(cv, c, T.accent, 0.55) end
            card:zone({ fid = fid, x = px0 + c.x * k, y = y + c.y * k, w = c.w * k, h = c.h * k, body = true,
                run = fn and function(cc, p) fn(p, t) end or nil })
        end
        y = y + des.h * k + T.px(6)
    end
    local gm = math.floor(d.fuel % 60)
    local hrs = d.tank and (tostring(math.floor(d.fuel / 60)) .. ":" .. (gm < 10 and "0" or "") .. tostring(gm)) or "0:00"
    y = y + UI.pair(card, x, y, w, "GAS LEFT", hrs .. " HRS", "TANK", d.tank and "IN" or "NONE") + gap
    if t.needs and #t.needs > 0 then y = y + UI.needs(card, x, y, w, t.needs) + gap end
    local items = d.container and call(d.container, "getItems")
    local n = items and items:size() or 0
    if n > 0 then
        y = y + UI.section(card, x, y, w, "ON THE GRILL", tostring(n))
        y = y + UI.cookRows(card, x, y, w, d.container, d.lit)
    end
    return y - y0
end

function def.body(card, x, y, w, t, player)
    if not t.d then return 0 end
    if t.d.propane then return propaneBody(card, x, y, w, t, player) end
    return fireBody(card, x, y, w, t, player)
end

OC.register(def)
