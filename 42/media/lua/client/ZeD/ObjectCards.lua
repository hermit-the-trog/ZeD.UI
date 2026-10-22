-- ZeD-UI/42/media/lua/client/ZeD/ObjectCards.lua
-- ============================================================================
-- OBJECT CARDS — HOOK_MAP rows 11 and 12 (mockup zed_info_cards_v1.html)
-- One card in the World window's card drawer for world objects that vanilla
-- answers with a small read-only "Info" window: generators, fires (campfire,
-- charcoal barbecue, fireplace, propane barbecue) and farm plots.
--
-- The card is an organism (ZeD_ObjectCard) that lives beside the item card in
-- the drawer overlay. Each kind of object registers a definition here
-- (ObjectCardPower / ObjectCardFire / ObjectCardFarm):
--   def.resolve(player, obj)  -> target table { obj, sq, key, ... } or nil
--   def.valid(t)              -> still in the world?
--   def.nearby(player)        -> targets of the same kind in reach (browse)
--   def.refresh(t, player)    -> fills t.d (data) and t.verbs every few frames
--   def.title(t) / def.icon(t) / def.pill(t) -> header
--   def.body(card, x, y, w, t, player) -> draws the body, returns its height
--   def.status(t)  (optional)  -> { text, c, alarm } a state line in the footer
--   def.onKey(t, key, card) (optional) -> true when the card takes the key
--                                (asked only while the pointer is over the card)
-- Verbs: { id, label, enabled, primary, run(player, t, card), jump = fid,
--          confirm = "question" }. A verb with jump moves the view (and the
-- controller focus) to a list in the body; one with confirm asks in the
-- footer first. The card stays open within OC.LEASH tiles of the object.
-- Zones may carry wheel(del) (the mouse wheel over them) and nofocus = true
-- (clickable, but not a controller stop).
-- ============================================================================

require "ZeD/Molecules"

ZeD = ZeD or {}
ZeD.ObjectCards = ZeD.ObjectCards or {}
local OC = ZeD.ObjectCards

OC.LEASH   = 6       -- tiles: the card closes past this (vanilla's plant window rule)
OC.CARD_W  = 480     -- design units
OC.REFRESH = 15      -- frames between data refreshes
OC.BROWSE_EVERY = 60 -- frames between nearby-object scans
OC.DOT = "|"   -- the separator: ZeD OS's pipe (director, Oct 16 2026: no middle dots)
OC.kinds = OC.kinds or {}

-- Safe Java / Lua method call: nil when the method is missing or throws.
local function call(o, m, ...)
    if o == nil then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end
OC.call = call

function OC.register(def) OC.kinds[def.id] = def end

-- The game's own display name for an item type ("Base.Lighter" or "Lighter"), else fb.
function OC.itemName(fullType, fb)
    local ft = tostring(fullType)
    if not ft:find(".", 1, true) then ft = "Base." .. ft end
    local si = getScriptManager():FindItem(ft)
    local n = si and call(si, "getDisplayName")
    if n and n ~= "" then return n end
    return fb or tostring(fullType)
end

function OC.keyOf(sq, tag)
    if not sq then return tostring(tag) end
    return tostring(sq:getX()) .. "," .. tostring(sq:getY()) .. "," .. tostring(sq:getZ()) .. ":" .. tostring(tag)
end

function OC.squareDist(player, sq)
    if not (player and sq) then return 999 end
    local dx, dy = sq:getX() + 0.5 - player:getX(), sq:getY() + 0.5 - player:getY()
    return math.sqrt(dx * dx + dy * dy)
end

-- Every loaded square within r tiles on the player's floor.
function OC.eachSquare(player, r, fn)
    local sq0 = player and player:getCurrentSquare()
    if not sq0 then return end
    local cell = getCell()
    for y = sq0:getY() - r, sq0:getY() + r do
        for x = sq0:getX() - r, sq0:getX() + r do
            local sq = cell:getGridSquare(x, y, sq0:getZ())
            if sq then fn(sq) end
        end
    end
end

-- Targets in reading order (rows, then columns): stable for the browse arrows.
function OC.sortTargets(list)
    table.sort(list, function(a, b)
        if a.sq:getY() ~= b.sq:getY() then return a.sq:getY() < b.sq:getY() end
        return a.sq:getX() < b.sq:getX()
    end)
    return list
end

-- "2 h 20 m" / "45 m" / "0 m"
function OC.hm(minutes)
    minutes = math.max(0, math.floor((minutes or 0) + 0.5))
    local h, m = math.floor(minutes / 60), minutes % 60
    if h > 0 and m > 0 then return ZeD.tr("UI_ZeD_ObjCard_HoursMinutes", h, m) end
    if h > 0 then return ZeD.tr("UI_ZeD_ObjCard_Hours", h) end
    return ZeD.tr("UI_ZeD_ObjCard_Minutes", m)
end

-- Where an item sits, for list rows: INVENTORY or the bag's name.
function OC.whereOf(item, player)
    local c = item and call(item, "getContainer")
    if not c or c == player:getInventory() then return ZeD.upper(ZeD.tr("ContextMenu_MoveToInventory")) end
    local bag = call(c, "getContainingItem")
    local n = bag and call(bag, "getDisplayName")
    return n and ZeD.upper(n) or ZeD.tr("UI_ZeD_ObjCard_WhereNearby")
end

-- Open the card on an object (World window opens if needed).
function OC.open(player, kindId, obj)
    local def = OC.kinds[kindId]
    if not (def and player and obj) then return false end
    if not (ZeD_WorldWindow and ZeD_WorldWindow.openObjectCard) then return false end
    local t = def.resolve(player, obj)
    if not t then return false end
    return ZeD_WorldWindow.openObjectCard(player:getPlayerNum(), { def = def, t = t }) and true or false
end

-- Open the card on an object that may be out of reach (the Animals tab lists
-- hutches, troughs and hooks across a zone): past the kind's leash, walk next
-- to sq first, then open (a one-tick action at the end of the walk).
ZeDOpenCardAction = ZeDOpenCardAction or ISBaseTimedAction:derive("ZeDOpenCardAction")
function ZeDOpenCardAction:isValid() return true end
function ZeDOpenCardAction:update() end
function ZeDOpenCardAction:start() end
function ZeDOpenCardAction:stop() ISBaseTimedAction.stop(self) end
function ZeDOpenCardAction:getDuration() return 1 end
function ZeDOpenCardAction:perform()
    local ok, err = pcall(OC.open, self.character, self.kind, self.obj)
    if not ok then print("[ZeD] ObjectCards: open after walk failed: " .. tostring(err)) end
    ISBaseTimedAction.perform(self)
end
function ZeDOpenCardAction:new(character, kind, obj)
    local o = ISBaseTimedAction.new(self, character)
    o.kind, o.obj = kind, obj
    o.maxTime = 1
    o.stopOnWalk, o.stopOnRun = false, false
    return o
end

function OC.openNear(player, kindId, obj, sq)
    local def = OC.kinds[kindId]
    if not (def and player and obj) then return false end
    local leash = def.leash or OC.LEASH
    if sq and (math.floor(player:getZ()) ~= sq:getZ() or OC.squareDist(player, sq) > leash - 0.5) then
        if luautils.walkAdj(player, sq) then
            ISTimedActionQueue.add(ZeDOpenCardAction:new(player, kindId, obj))
        end
        return true
    end
    return OC.open(player, kindId, obj)
end

-- Sprite icon for a world object (a hutch, a trough): the tile's own icon.
function OC.spriteIcon(obj)
    local spr = obj and call(obj, "getSprite")
    local name = spr and call(spr, "getName")
    local tex = name and getTexture(name)
    if not tex then return nil end
    return call(tex, "splitIcon") or tex
end

-- Per-frame upkeep for the open entry: validity, leash, data and browse list.
-- Returns false when the card should close.
function OC.tick(e, player)
    local def, t = e.def, e.t
    if not (t and def.valid(t)) then
        -- a kind that keeps going (farm plots) steps to the next one in reach
        if not def.keepOnLoss then return false end
        local ok, list = pcall(def.nearby, player)
        if not (ok and list) then return false end
        local live = {}
        for _, o in ipairs(list) do
            local vok, v = pcall(def.valid, o)
            if vok and v then live[#live + 1] = o end
        end
        if #live == 0 then return false end
        e.list = live
        e.idx = math.min(e.idx or 1, #live)
        e.t = live[e.idx]
        e.t._refreshT = OC.REFRESH
        e._browseT = 0
        t = e.t
    end
    if player:getVehicle() or player:isDead() then return false end
    -- the leash applies to a card about a tile (a fluid card about your own
    -- bottles has none)
    local sq = t.sq
    local leash = def.leash or OC.LEASH
    if sq and (math.floor(player:getZ()) ~= sq:getZ() or OC.squareDist(player, sq) > leash + 0.5) then
        return false
    end
    t._refreshT = (t._refreshT or OC.REFRESH) + 1
    if t._refreshT >= OC.REFRESH or not t.d then
        t._refreshT = 0
        local ok, err = pcall(def.refresh, t, player)
        if not ok then ZeD.logOnce("ObjectCards refresh " .. tostring(def.id), err) end
    end
    e._browseT = (e._browseT or OC.BROWSE_EVERY) + 1
    if e._browseT >= OC.BROWSE_EVERY or not e.list then
        e._browseT = 0
        local ok, list = pcall(def.nearby or function() return { t } end, player)
        e.list = ok and list or { t }
        e.idx = 1
        for i, o in ipairs(e.list) do if o.key == t.key then e.idx = i end end
    end
    return true
end

-- Step to the previous / next object of the same kind in reach.
function OC.browse(e, dir)
    if not (e.list and #e.list > 1) then return end
    local n = #e.list
    local i = ((e.idx or 1) - 1 + dir) % n + 1
    e.idx = i
    e.t = e.list[i]
    e.t._refreshT = OC.REFRESH
end

-- ============================================================================
-- DRAWING PIECES — shared by the kinds (all sizes in design units via T.px)
-- ============================================================================
OC.ui = OC.ui or {}
local UI = OC.ui

local function col(c) return c.r, c.g, c.b end

-- System 7 verb button (same chrome as Molecules.drawCardBackBar). Returns width.
function UI.button(card, x, y, label, opts)
    local T = ZeD.T
    opts = opts or {}
    label = ZeD.btnCase(label)   -- sentence case, never all caps
    local font = T.fontF1
    local h = opts.h or T.px(22)
    local padX = T.px(8)
    local w = opts.w or (ZeD.TM:MeasureStringX(font, label) + padX * 2)
    local a = opts.disabled and 0.35 or 1
    local bg = opts.primary and T.accent or T.surf3
    card:drawRect(x, y, w, h, (bg.a or 1) * a, col(bg))
    if opts.danger and not opts.disabled then
        local pulse = math.sin((getTimestampMs() or 0) / 400) * 0.5 + 0.5
        local fa = T.dangerPulseMin + pulse * (T.dangerPulseMax - T.dangerPulseMin)
        card:drawRect(x, y, w, h, fa, col(T.danger))
    end
    local hi = opts.primary and T.accentBright or T.surf4
    local sh = opts.primary and ZeD.colorBlend(T.accent, T.base, 0.55) or T.borderS
    card:drawRect(x, y, w, T.px(1), (hi.a or 1) * a, col(hi))
    card:drawRect(x, y, T.px(1), h, (hi.a or 1) * a, col(hi))
    card:drawRect(x, y + h - T.px(1), w, T.px(1), (sh.a or 1) * a, col(sh))
    card:drawRect(x + w - T.px(1), y, T.px(1), h, (sh.a or 1) * a, col(sh))
    local tc = opts.primary and T.textOnAccent or (opts.danger and T.danger or T.text)
    local lh = T.fontF1H or ZeD.TM:getFontHeight(font)
    card:drawText(label, x + math.floor((w - ZeD.TM:MeasureStringX(font, label)) / 2), y + math.floor((h - lh) / 2),
        tc.r, tc.g, tc.b, (tc.a or 1) * a, font)
    if opts.focused then
        local ac = T.accent
        card:drawRect(x, y, w, h, 0.55, col(ac))
    end
    return w
end

function UI.buttonW(label)
    local T = ZeD.T
    return ZeD.TM:MeasureStringX(T.fontF1, ZeD.btnCase(label)) + T.px(16)
end

-- Bordered tag ("BURNING", "FARMING 4"). Returns width.
function UI.tag(card, x, y, text, c, withDot, dotC)
    local T, tm = ZeD.T, ZeD.TM
    local f = T.fontF1
    c = c or T.textDim
    local h = T.px(16)
    local dotW = withDot and T.px(11) or 0
    local w = tm:MeasureStringX(f, text) + T.px(12) + dotW
    card:drawRectBorder(x, y, w, h, c.a or 1, col(c))
    if withDot then ZeD.Atoms.drawStatusDot(card, x + T.px(6), y + math.floor((h - T.px(6)) / 2), dotC or c, T.px(6)) end
    card:drawText(text, x + T.px(6) + dotW, y + math.floor((h - tm:getFontHeight(f)) / 2), c.r, c.g, c.b, c.a or 1, f)
    return w
end

-- Section header: "LABEL ............. right"
function UI.section(card, x, y, w, label, right)
    local T, tm = ZeD.T, ZeD.TM
    local h = T.px(20)
    local f = T.fontF1
    local ty = y + math.floor((h - tm:getFontHeight(f)) / 2)
    local c = T.textDim
    card:drawText(label, x + T.px(2), ty, c.r, c.g, c.b, c.a or 1, f)
    if right and right ~= "" then ZeD.Atoms.drawTextRight(card, right, x + w - T.px(2), ty, f, c) end
    card:drawRect(x, y + h - T.px(1), w, T.px(1), T.borderS.a, col(T.borderS))
    return h
end

-- Label + value line over a fill bar. zone = {lo, hi} percent band (good range).
-- lock = skill level that reads the bar (draws a FARMING n tag instead of a fill).
function UI.meter(card, x, y, w, label, value, dotC, pct, fillC, zone, lockText)
    local T, tm = ZeD.T, ZeD.TM
    local f1, f2 = T.fontF1, T.fontF2
    local lineH = math.max(tm:getFontHeight(f1), tm:getFontHeight(f2))
    local ac = T.accent
    card:drawText(label, x, y + math.floor((lineH - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
    local vw = tm:MeasureStringX(f2, value or "")
    local vx = x + w - vw
    card:drawText(value or "", vx, y + math.floor((lineH - tm:getFontHeight(f2)) / 2), T.text.r, T.text.g, T.text.b, T.text.a, f2)
    if dotC then ZeD.Atoms.drawStatusDot(card, vx - T.px(11), y + math.floor((lineH - T.px(6)) / 2), dotC, T.px(6)) end
    local by = y + lineH + T.px(4)
    local bh = T.px(12)
    local s1 = T.surf1
    card:drawRect(x, by, w, bh, s1.a, col(s1))
    if lockText then
        local tw = UI.tagW(lockText)
        UI.tag(card, x + w - tw - T.px(2), by - T.px(2), lockText, T.textDim)
    else
        if zone then
            local zx = x + math.floor(w * zone[1] / 100)
            local zw = math.floor(w * (zone[2] - zone[1]) / 100)
            local inf = T.info or T.accent
            card:drawRect(zx, by, zw, bh, 0.18, col(inf))
            card:drawRect(zx, by, T.px(1), bh, 0.6, col(inf))
            card:drawRect(zx + zw - T.px(1), by, T.px(1), bh, 0.6, col(inf))
        end
        local fw = math.floor(w * math.max(0, math.min(100, pct or 0)) / 100)
        if fw > 0 then card:drawRect(x, by, fw, bh, 1, col(fillC or T.accent)) end
    end
    card:drawRectBorder(x, by, w, bh, T.borderS.a, col(T.borderS))
    return lineH + T.px(4) + bh
end

function UI.tagW(text)
    local T = ZeD.T
    return ZeD.TM:MeasureStringX(T.fontF1, text) + T.px(12)
end

-- Two-column "LABEL value" row (pass nil to leave a side empty).
function UI.pair(card, x, y, w, l1, v1, l2, v2)
    local T, tm = ZeD.T, ZeD.TM
    local h = T.px(20)
    local half = math.floor((w - T.px(16)) / 2)
    local function one(px, l, v)
        if not l then return end
        local ac = T.accent
        card:drawText(l, px, y + math.floor((h - tm:getFontHeight(T.fontF1)) / 2), ac.r, ac.g, ac.b, 1, T.fontF1)
        if type(v) == "function" then
            v(px + half, y, h)
        elseif v then
            ZeD.Atoms.drawTextRight(card, v, px + half, y + math.floor((h - tm:getFontHeight(T.fontF2)) / 2), T.fontF2, T.text)
        end
    end
    one(x, l1, v1)
    one(x + half + T.px(16), l2, v2)
    return h
end

-- List row: icon, name, right value (dim mono)
function UI.row(card, x, y, w, tex, name, value, valueC)
    local T, tm = ZeD.T, ZeD.TM
    local h = T.px(24)
    local isz = T.px(16)
    local iy = y + math.floor((h - isz) / 2)
    if tex then
        card:drawTextureScaledAspect(tex, x + T.px(2), iy, isz, isz, 1, 1, 1, 1)
    end
    local nx = tex and (x + T.px(2) + isz + T.px(8)) or (x + T.px(2))
    local vf = T.fontF3
    local vw = value and tm:MeasureStringX(vf, value) or 0
    local nstr = ZeD.CraftingCore and ZeD.CraftingCore.truncText(name or "", T.fontF2, x + w - vw - T.px(10) - nx) or (name or "")
    card:drawText(nstr, nx, y + math.floor((h - tm:getFontHeight(T.fontF2)) / 2), T.text.r, T.text.g, T.text.b, T.text.a, T.fontF2)
    if value then
        local vc = valueC or T.textDim
        ZeD.Atoms.drawTextRight(card, value, x + w - T.px(2), y + math.floor((h - tm:getFontHeight(vf)) / 2), vf, vc)
    end
    card:drawRect(x, y + h - T.px(1), w, T.px(1), T.border.a, col(T.border))
    return h
end

-- Pick row: icon, name, location, gain, button. Stamps a zone; returns height.
-- opts = { tex, name, where, gain, gainC, button, fid, run, enabled, tag, tagC }
function UI.pick(card, x, y, w, opts)
    local T, tm = ZeD.T, ZeD.TM
    local h = T.px(26)
    local isz = T.px(16)
    if opts.tex then card:drawTextureScaledAspect(opts.tex, x + T.px(2), y + math.floor((h - isz) / 2), isz, isz, 1, 1, 1, 1) end
    local bw = UI.buttonW(opts.button or getText("UI_btn_add"))
    local bx = x + w - bw - T.px(2)
    local by = y + math.floor((h - T.px(20)) / 2)
    local rx = bx - T.px(8)
    if opts.gain then
        local gf = T.fontF3
        local gc = opts.gainC or T.positive
        local gw = tm:MeasureStringX(gf, opts.gain)
        card:drawText(opts.gain, rx - gw, y + math.floor((h - tm:getFontHeight(gf)) / 2), gc.r, gc.g, gc.b, gc.a or 1, gf)
        rx = rx - gw - T.px(10)
    end
    if opts.tag then
        local tw = UI.tagW(opts.tag)
        UI.tag(card, rx - tw, y + math.floor((h - T.px(16)) / 2), opts.tag, opts.tagC)
        rx = rx - tw - T.px(10)
    end
    if opts.where then
        local lf = T.fontF1
        local lw = tm:MeasureStringX(lf, opts.where)
        card:drawText(opts.where, rx - lw, y + math.floor((h - tm:getFontHeight(lf)) / 2), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, lf)
        rx = rx - lw - T.px(10)
    end
    local nx = x + T.px(2) + isz + T.px(8)
    local nstr = ZeD.CraftingCore and ZeD.CraftingCore.truncText(opts.name or "", T.fontF2, rx - nx) or (opts.name or "")
    local nc = (opts.enabled == false) and T.textDim or T.text
    card:drawText(nstr, nx, y + math.floor((h - tm:getFontHeight(T.fontF2)) / 2), nc.r, nc.g, nc.b, nc.a or 1, T.fontF2)
    local focused = card._fid == opts.fid
    UI.button(card, bx, by, opts.button or getText("UI_btn_add"), { h = T.px(20), disabled = opts.enabled == false, focused = focused })
    card:drawRect(x, y + h - T.px(1), w, T.px(1), T.border.a, col(T.border))
    if opts.fid then
        card:zone({ fid = opts.fid, x = bx, y = by, w = bw, h = T.px(20), body = true,
            run = (opts.enabled ~= false) and opts.run or nil })
    end
    return h
end

-- Wrapped paragraph; returns height.
function UI.para(card, x, y, w, text, c, font)
    local T, tm = ZeD.T, ZeD.TM
    font = font or T.fontF2
    c = c or T.text
    local lines = ZeD.Atoms.wrapText(text or "", font, w) or { text or "" }
    local lh = tm:getFontHeight(font) + T.px(2)
    for i, ln in ipairs(lines) do
        card:drawText(ln, x, y + (i - 1) * lh, c.r, c.g, c.b, c.a or 1, font)
    end
    return #lines * lh
end

-- Danger band (the generator's fumes warning)
function UI.warn(card, x, y, w, text)
    local T = ZeD.T
    local pad = T.px(8)
    local dg = T.danger
    -- (measured, not drawn: the paragraph draws once, over the tint; it drew twice before,
    -- the first time under the tint; code audit Oct 17 2026)
    local lines = ZeD.Atoms.wrapText(text or "", T.fontF2, w - pad * 2 - T.px(14)) or { text or "" }
    local th = #lines * (ZeD.TM:getFontHeight(T.fontF2) + T.px(2))
    local h = th + pad * 2 - T.px(2)
    card:drawRect(x, y, w, h, 0.12, col(dg))
    card:drawRectBorder(x, y, w, h, dg.a or 1, col(dg))
    ZeD.Atoms.drawStatusDot(card, x + pad, y + pad + T.px(4), dg, T.px(7))
    UI.para(card, x + pad + T.px(14), y + pad, w - pad * 2 - T.px(14), text, T.text)
    return h
end

-- "NEEDS" line under the verbs: hollow dot + dim mono text (wraps).
function UI.needs(card, x, y, w, parts)
    if not parts or #parts == 0 then return 0 end
    local T = ZeD.T
    local text = table.concat(parts, "  " .. OC.DOT .. "  ")
    ZeD.Atoms.drawStatusRing(card, x, y + T.px(4), T.textDim, T.px(7))
    return UI.para(card, x + T.px(14), y, w - T.px(14), text, T.textDim, T.fontF1) + T.px(2)
end

-- Cooking rows for a container (the item card's cooking reading), "on" = heat on.
function UI.cookRows(card, x, y, w, container, on)
    local T, tm = ZeD.T, ZeD.TM
    local items = container and call(container, "getItems")
    if not items or items:size() == 0 then return 0 end
    local h0 = y
    local rowH = T.px(28)
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it then
            local name = call(it, "getDisplayName") or "?"
            local tex = call(it, "getTex")
            local tag, mode, p, left = nil, nil, nil, nil
            if instanceof(it, "Food") and call(it, "isCookable") then
                local ct = call(it, "getCookingTime") or 0
                local toCook = call(it, "getMinutesToCook") or 0
                local toBurn = call(it, "getMinutesToBurn") or 0
                if call(it, "isBurnt") then
                    tag, mode, p = ZeD.upper(ZeD.tr("IGUI_invpanel_Burnt")), "dng", 1
                elseif call(it, "isCooked") or (toCook > 0 and ct >= toCook) then
                    if on then
                        tag, mode = ZeD.upper(ZeD.tr("IGUI_invpanel_Burning")), "dng"
                        p = math.max(0, math.min(1, (ct - toCook) / math.max(1, toBurn - toCook)))
                        left = math.max(0, math.ceil(toBurn - ct))
                    else
                        tag, mode = ZeD.upper(ZeD.tr("Tooltip_food_Cooked")), "pos"
                    end
                else
                    p = toCook > 0 and math.max(0, math.min(1, ct / toCook)) or 0
                    tag, mode = on and ZeD.upper(ZeD.tr("IGUI_invpanel_Cooking")) or ZeD.tr("UI_ZeD_ObjCard_TagRaw"), on and "acc" or "dim"
                    left = on and math.max(0, math.ceil(toCook - ct)) or nil
                end
            end
            local isz = T.px(16)
            if tex then card:drawTextureScaledAspect(tex, x + T.px(2), y + math.floor((rowH - isz) / 2), isz, isz, 1, 1, 1, 1) end
            local barW, pctW = T.px(110), T.px(40)
            local rx = x + w - T.px(2)
            local nx = x + T.px(2) + isz + T.px(8)
            local tagW = tag and (UI.tagW(tag) + T.px(6)) or 0
            local nstr = ZeD.CraftingCore.truncText(name, T.fontF2, math.max(T.px(30), rx - pctW - barW - T.px(16) - nx - tagW))
            card:drawText(nstr, nx, y + math.floor((rowH - tm:getFontHeight(T.fontF2)) / 2), T.text.r, T.text.g, T.text.b, T.text.a, T.fontF2)
            local mc = (mode == "dng") and T.danger or ((mode == "pos") and T.positive or ((mode == "acc") and T.accent or T.textDim))
            if tag then UI.tag(card, nx + tm:MeasureStringX(T.fontF2, nstr) + T.px(6), y + math.floor((rowH - T.px(16)) / 2), tag, mc) end
            if p then
                local bx = rx - pctW - barW
                local bh = T.px(6)
                local by = y + math.floor((rowH - bh) / 2)
                card:drawRect(bx, by, barW, bh, T.surf2.a, col(T.surf2))
                card:drawRectBorder(bx, by, barW, bh, T.borderS.a, col(T.borderS))
                card:drawRect(bx + T.px(1), by + T.px(1), math.floor((barW - 2 * T.px(1)) * p), bh - 2 * T.px(1), 1, col(mc))
                local ptxt = left and ZeD.tr("UI_ZeD_ObjCard_MinLeft", left) or (mode == "pos" and ZeD.tr("UI_ZeD_ObjCard_Done") or (tostring(math.floor(p * 100 + 0.5)) .. "%"))
                ZeD.Atoms.drawTextRight(card, ptxt, rx, y + math.floor((rowH - tm:getFontHeight(T.fontF3)) / 2), T.fontF3, mode == "dng" and T.danger or T.text)
            end
            card:drawRect(x, y + rowH - T.px(1), w, T.px(1), T.border.a, col(T.border))
            y = y + rowH
        end
    end
    return y - h0
end

-- ---------------------------------------------------------------------------
-- Hardware: 1993 control-panel parts (Visual Catalog A22-A26, M41)
-- ---------------------------------------------------------------------------
local function hex(h)
    local n = tonumber(string.sub(h, 2), 16) or 0
    return { r = math.floor(n / 65536) / 255, g = (math.floor(n / 256) % 256) / 255, b = (n % 256) / 255, a = 1 }
end
UI.hex = hex
UI.HW = {
    plateTop = hex("#34363A"), plateBot = hex("#26282B"), edge = hex("#000000"), text = hex("#E6E2D6"),
    hazard = hex("#E3B52A"), hazardDark = hex("#1B1B1B"),
    lcdBg = hex("#0F1A10"), lcdEdge = hex("#4A4A40"), lcdOn = hex("#66EE66"), lcdDim = hex("#3A8A3A"),
    ledOff = hex("#222222"), ledRim = hex("#444444"), green = hex("#3EE26A"), amber = hex("#FFB02A"), red = hex("#FF4A2A"),
    needle = hex("#FF7A2A"), face = hex("#555555"), tick = hex("#999999"),
    rockerDark = hex("#151515"), rockerLit = hex("#3A3A3A"),
    knob = hex("#343434"), knobHi = hex("#6A6A6A"),
}

-- A radial run of small squares (needles, pointers), deg 0 = up.
function UI.run(card, cx, cy, deg, r0, r1, c, thick)
    local a = (deg - 90) * math.pi / 180
    local ca, sa = math.cos(a), math.sin(a)
    local t = math.max(1, thick)
    local r = r0
    while r <= r1 do
        card:drawRect(math.floor(cx + ca * r - t / 2), math.floor(cy + sa * r - t / 2), t, t, c.a or 1, c.r, c.g, c.b)
        r = r + 1
    end
end

function UI.disc(card, cx, cy, r, c, a)
    ZeD.Atoms.drawStatusDot(card, math.floor(cx - r), math.floor(cy - r), { r = c.r, g = c.g, b = c.b, a = a or 1 }, math.floor(r * 2))
end

-- Vertical-gradient plate with a hazard stripe and a brand line. Returns inner top.
function UI.plate(card, x, y, w, h, brand, serial, palette)
    local T, HW = ZeD.T, UI.HW
    local top, bot = (palette and palette.top) or HW.plateTop, (palette and palette.bot) or HW.plateBot
    local bands = 10
    for i = 0, bands - 1 do
        local f = i / (bands - 1)
        local y0 = y + math.floor(h * i / bands)
        local y1 = y + math.floor(h * (i + 1) / bands)
        card:drawRect(x, y0, w, y1 - y0, 1, top.r + (bot.r - top.r) * f, top.g + (bot.g - top.g) * f, top.b + (bot.b - top.b) * f)
    end
    if not (palette and palette.noStripe) then
        local sh = T.px(4)
        local seg = T.px(8)
        local i = 0
        local sx = x
        while sx < x + w do
            local c = (i % 2 == 0) and HW.hazard or HW.hazardDark
            card:drawRect(sx, y, math.min(seg, x + w - sx), sh, 1, c.r, c.g, c.b)
            sx = sx + seg
            i = i + 1
        end
    end
    card:drawRectBorder(x, y, w, h, 1, HW.edge.r, HW.edge.g, HW.edge.b)
    local f5 = T.fontF5
    local tc = HW.text
    if brand then card:drawText(brand, x + T.px(12), y + h - T.px(5) - ZeD.TM:getFontHeight(f5), tc.r, tc.g, tc.b, 0.75, f5) end
    if serial then ZeD.Atoms.drawTextRight(card, serial, x + w - T.px(12), y + h - T.px(5) - ZeD.TM:getFontHeight(f5), f5, { r = tc.r, g = tc.g, b = tc.b, a = 0.5 }) end
end

-- Needle gauge: E..F arc, low red zone, label under. (cx, cy) = pivot.
function UI.needle(card, cx, cy, r, frac, label, lowZone)
    local T, HW = ZeD.T, UI.HW
    for d = -60, 60, 2 do UI.run(card, cx, cy, d, r - T.px(1), r, HW.face, T.px(1)) end
    if lowZone then for d = -56, -42, 2 do UI.run(card, cx, cy, d, r - T.px(4), r - T.px(1), HW.red, T.px(2)) end end
    for _, d in ipairs({ -60, -30, 0, 30, 60 }) do UI.run(card, cx, cy, d, r - T.px(7), r - T.px(3), HW.tick, T.px(1)) end
    local f5 = T.fontF5
    card:drawText(ZeD.tr("UI_ZeD_ObjCard_GaugeE"), cx - r - T.px(2), cy - ZeD.TM:getFontHeight(f5) + T.px(2), HW.tick.r, HW.tick.g, HW.tick.b, 1, f5)
    ZeD.Atoms.drawTextRight(card, ZeD.tr("UI_ZeD_ObjCard_GaugeF"), cx + r + T.px(2), cy - ZeD.TM:getFontHeight(f5) + T.px(2), f5, HW.tick)
    UI.run(card, cx, cy, -60 + 120 * math.max(0, math.min(1, frac or 0)), 0, r - T.px(4), HW.needle, T.px(2))
    UI.disc(card, cx, cy, T.px(4), HW.ledRim)
    if label then
        local f1 = T.fontF1
        local lw = ZeD.TM:MeasureStringX(f1, label)
        card:drawText(label, cx - math.floor(lw / 2), cy + T.px(6), HW.text.r, HW.text.g, HW.text.b, 1, f1)
    end
end

-- Green LCD window: big digits + small unit. Returns width.
function UI.lcd(card, x, y, big, small, minW)
    local T, tm, HW = ZeD.T, ZeD.TM, UI.HW
    local bf, sf = T.fontF4, T.fontF1
    local bw, sw = tm:MeasureStringX(bf, big), small and tm:MeasureStringX(sf, small) or 0
    local w = math.max(minW or 0, bw + (small and (sw + T.px(8)) or 0) + T.px(16))
    local h = T.px(30)
    card:drawRect(x, y, w, h, 1, HW.lcdBg.r, HW.lcdBg.g, HW.lcdBg.b)
    card:drawRectBorder(x, y, w, h, 1, HW.lcdEdge.r, HW.lcdEdge.g, HW.lcdEdge.b)
    do local i = T.px(1); card:drawRectBorder(x + i, y + i, w - 2 * i, h - 2 * i, 1, HW.lcdEdge.r, HW.lcdEdge.g, HW.lcdEdge.b) end  -- (the LCD's second bezel line, inset by the scaled border)
    local tx = x + math.floor((w - bw - (small and (sw + T.px(8)) or 0)) / 2)
    card:drawText(big, tx, y + math.floor((h - tm:getFontHeight(bf)) / 2), HW.lcdOn.r, HW.lcdOn.g, HW.lcdOn.b, 1, bf)
    if small then
        card:drawText(small, tx + bw + T.px(8), y + math.floor((h - tm:getFontHeight(sf)) / 2) + T.px(1), HW.lcdDim.r, HW.lcdDim.g, HW.lcdDim.b, 1, sf)
    end
    return w
end

-- Indicator lamp with a label to its right.
function UI.led(card, x, y, c, on, label)
    local T, HW = ZeD.T, UI.HW
    local r = T.px(4)
    UI.disc(card, x + r, y + r, r + T.px(1), HW.ledRim)
    UI.disc(card, x + r, y + r, r, on and c or HW.ledOff)
    if label then
        local f1 = T.fontF1
        card:drawText(label, x + r * 2 + T.px(6), y + r - math.floor(ZeD.TM:getFontHeight(f1) / 2), HW.text.r, HW.text.g, HW.text.b, 1, f1)
    end
end

-- I / O rocker switch. Returns nothing; caller stamps the zone.
function UI.rocker(card, x, y, w, h, on, focused, label)
    local T, HW, tm = ZeD.T, UI.HW, ZeD.TM
    card:drawRect(x - T.px(2), y - T.px(2), w + 2 * T.px(2), h + 2 * T.px(2), 1, 0.07, 0.07, 0.07)
    local half = math.floor(h / 2)
    local topC = on and HW.rockerLit or HW.rockerDark
    local botC = on and HW.rockerDark or HW.rockerLit
    card:drawRect(x, y, w, half, 1, topC.r, topC.g, topC.b)
    card:drawRect(x, y + half, w, h - half, 1, botC.r, botC.g, botC.b)
    local f1 = T.fontF1
    local function glyph(s, gy, lit)
        local gw = tm:MeasureStringX(f1, s)
        local c = lit and HW.text or { r = 0.53, g = 0.53, b = 0.53 }
        card:drawText(s, x + math.floor((w - gw) / 2), gy + math.floor((half - tm:getFontHeight(f1)) / 2), c.r, c.g, c.b, 1, f1)
    end
    glyph("I", y, on)
    glyph("O", y + half, not on)
    if focused then
        local ac = T.accent
        card:drawRect(x - T.px(2), y - T.px(2), w + 2 * T.px(2), h + 2 * T.px(2), 0.55, ac.r, ac.g, ac.b)
    end
    if label then
        local lw = tm:MeasureStringX(f1, label)
        card:drawText(label, x + math.floor((w - lw) / 2), y + h + T.px(5), HW.text.r, HW.text.g, HW.text.b, 1, f1)
    end
end

-- Round knob with a pointer; frac 0..1 sweeps -135..+135 degrees.
function UI.knob(card, cx, cy, r, frac, focused, label)
    local T, HW, tm = ZeD.T, UI.HW, ZeD.TM
    if focused then UI.disc(card, cx, cy, r + T.px(4), T.accent, 0.55) end
    UI.disc(card, cx, cy, r + T.px(2), HW.edge)
    UI.disc(card, cx, cy, r, HW.knob)
    UI.disc(card, cx - r * 0.15, cy - r * 0.2, r * 0.6, HW.knobHi, 0.5)
    UI.run(card, cx, cy, -135 + 270 * math.max(0, math.min(1, frac or 0)), r * 0.15, r * 0.8, { r = 0.88, g = 0.88, b = 0.88 }, T.px(3))
    if label then
        local f1 = T.fontF1
        local lw = tm:MeasureStringX(f1, label)
        card:drawText(label, cx - math.floor(lw / 2), cy + r + T.px(6), HW.text.r, HW.text.g, HW.text.b, 1, f1)
    end
end

-- Free-size number (big readouts): distance-field heading face at px design units.
function UI.big(card, text, x, y, px, c)
    c = c or ZeD.T.text
    if ZeD.Text and ZeD.Text.draw and ZeD.Font and ZeD.Font.sdf then
        return ZeD.Text.draw(card, ZeD.Font.sdf.head, text, x, y, ZeD.Text.zoomPx(px), c.r, c.g, c.b, c.a or 1, "l")
    end
    card:drawText(text, x, y, c.r, c.g, c.b, c.a or 1, ZeD.T.fontF4)
    return ZeD.TM:MeasureStringX(ZeD.T.fontF4, text)
end

-- ============================================================================
-- ZeD_ObjectCard — the organism
-- ============================================================================
-- "or": a hot reload redefines the methods on the live class table
ZeD_ObjectCard = ZeD_ObjectCard or ISPanel:derive("ZeD_ObjectCard")

function ZeD_ObjectCard:new(x, y, w, h, playerNum)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.playerNum = playerNum or 0
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.entry = nil
    o._zones, o._lastZones = {}, {}
    o.scroll = ZeD_ScrollbarState:new()
    o._bodyH = 0
    return o
end

function ZeD_ObjectCard:setEntry(entry)
    -- the outgoing kind may tidy up (the placement card puts its gizmo away)
    local old = self.entry
    if old and old ~= entry and old.def and old.def.onClose then
        local ok, err = pcall(old.def.onClose, old.t, self)
        if not ok then print("[ZeD] ObjectCards: onClose failed: " .. tostring(err)) end
    end
    self.entry = entry
    self._confirm = nil
    self._pendingFocus = nil
    self._followId = nil
    self._wantGrab = entry ~= nil   -- pick the opening focus once the verbs exist
    -- until then hold focus on the back button, so the last card's focused
    -- row never scrolls the new card on its first frame
    self._pendingFocus = entry and "oc:back" or nil
    self.scroll:setScrollPos(0)
    if entry and entry.t then entry.t._refreshT = OC.REFRESH end
end

function ZeD_ObjectCard:zone(z) self._zones[#self._zones + 1] = z end

function ZeD_ObjectCard:player() return getSpecificPlayer(self.playerNum) end

-- Focused gamepad element id when focus sits in the card's ring zone.
local function focusedId()
    local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    if not (win and Focus and Focus.getFocusedZone and Focus.getFocusedElement) then return nil end
    local D = ZeD.Input and ZeD.Input.Detector
    if not (D and D.getMode and D.getMode() == "gamepad") then return nil end
    if Focus.getFocusedWindow and Focus.getFocusedWindow() ~= win then return nil end
    local fz = Focus.getFocusedZone(win)
    if fz and fz.zone == "worldItemCard" then
        local fe = Focus.getFocusedElement(win)
        return fe and fe.id or nil
    end
    return nil
end

function ZeD_ObjectCard:close()
    if ZeD_WorldWindow and ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end
end

-- Run a verb: confirm first, or jump to a list, or act.
function ZeD_ObjectCard:press(v)
    if not v or v.enabled == false then return end
    local player = self:player()
    local e = self.entry
    if not (player and e) then return end
    if v.confirm then
        self._confirm = { text = v.confirm, yes = v.label, run = v.run }
        self._pendingFocus = "oc:confirm:yes"
        return
    end
    if v.jump then
        self._jumpTo = v.jump
        self._pendingFocus = v.jump
        self._followId = nil
        return
    end
    if v.run then
        local ok, err = pcall(v.run, player, e.t, self)
        if not ok then print("[ZeD] ObjectCards: verb " .. tostring(v.id) .. " failed: " .. tostring(err)) end
        e.t._refreshT = OC.REFRESH - 3
    end
end

function ZeD_ObjectCard:prerender()
    local e = self.entry
    if not e then return end
    local player = self:player()
    if not player then return end
    -- (a card kind's own calls run every frame: a throw closes the card or drops that piece,
    -- logged once, rather than repeating each frame; code audit Oct 17 2026)
    local okT, alive = pcall(OC.tick, e, player)
    if not okT then ZeD.logOnce("ObjectCards tick " .. tostring(e.def and e.def.id), alive) end
    if not (okT and alive) then
        self:close()
        return
    end
    local function try(f, ...)
        if not f then return nil end
        local ok, a, b, c = pcall(f, ...)
        if ok then return a, b, c end
        ZeD.logOnce("ObjectCards header " .. tostring(e.def and e.def.id), a)
        return nil
    end
    local T, tm = ZeD.T, ZeD.TM
    local w, h = self:getWidth(), self:getHeight()
    self._lastZones = self._zones
    self._zones = {}
    self._fid = focusedId()
    local def, t = e.def, e.t

    -- Background
    local s1 = T.surf1
    self:drawRect(0, 0, w, h, 0.98, s1.r, s1.g, s1.b)

    -- HEADER: back, icon, name, state pill, browse arrows
    local hh = T.px(37)
    local s2 = T.surf2
    self:drawRect(0, 0, w, hh, s2.a, s2.r, s2.g, s2.b)
    self:drawRect(0, hh - T.px(1), w, T.px(1), T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
    local bx, by = T.px(8), math.floor((hh - T.px(22)) / 2)
    UI.button(self, bx, by, "<", { w = T.px(22), focused = self._fid == "oc:back" })
    self:zone({ fid = "oc:back", x = bx, y = by, w = T.px(22), h = T.px(22), run = function() self:close() end })
    local cx = bx + T.px(22) + T.px(6)
    local isz = T.px(22)
    self:drawRect(cx, by, isz, isz, s1.a, s1.r, s1.g, s1.b)
    self:drawRectBorder(cx, by, isz, isz, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
    local icon = try(def.icon, t)
    if icon then self:drawTextureScaledAspect(icon, cx + T.px(2), by + T.px(2), isz - 2 * T.px(2), isz - 2 * T.px(2), 1, 1, 1, 1) end
    cx = cx + isz + T.px(8)
    -- browse (right)
    local rightX = w - T.px(8)
    if e.list and #e.list > 1 then
        local f1 = T.fontF1
        local txt = tostring(e.idx or 1) .. " / " .. tostring(#e.list)
        local aw = T.px(18)
        local nextX = rightX - aw
        UI.button(self, nextX, by, ">", { w = aw, focused = self._fid == "oc:next" })
        self:zone({ fid = "oc:next", x = nextX, y = by, w = aw, h = T.px(22), run = function() OC.browse(e, 1); self._confirm = nil; self.scroll:setScrollPos(0) end })
        local tw = tm:MeasureStringX(f1, txt)
        local tx = nextX - T.px(6) - tw
        self:drawText(txt, tx, by + math.floor((T.px(22) - tm:getFontHeight(f1)) / 2), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f1)
        local prevX = tx - T.px(6) - aw
        UI.button(self, prevX, by, "<", { w = aw, focused = self._fid == "oc:prev" })
        self:zone({ fid = "oc:prev", x = prevX, y = by, w = aw, h = T.px(22), run = function() OC.browse(e, -1); self._confirm = nil; self.scroll:setScrollPos(0) end })
        rightX = prevX - T.px(10)
    end
    local pillTxt, pillC, pillDot = nil, nil, nil
    pillTxt, pillC, pillDot = try(def.pill, t)
    local pillW = pillTxt and (UI.tagW(pillTxt) + T.px(11)) or 0
    local nf = T.fontF4
    local name = try(def.title, t) or "?"
    local nstr = ZeD.CraftingCore.truncText(name, nf, math.max(T.px(40), rightX - cx - pillW - T.px(10)))
    self:drawText(nstr, cx, math.floor((hh - tm:getFontHeight(nf)) / 2), T.text.r, T.text.g, T.text.b, T.text.a, nf)
    if pillTxt then UI.tag(self, cx + tm:MeasureStringX(nf, nstr) + T.px(8), math.floor((hh - T.px(16)) / 2), pillTxt, pillC, true, pillDot) end

    -- VERB BAR
    local y = hh
    local verbs = t.verbs or {}
    if #verbs > 0 then
        local vh = T.px(32)
        self:drawRect(0, y + vh - T.px(1), w, T.px(1), T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
        local vx = T.px(8)
        for i, v in ipairs(verbs) do
            local fid = "oc:verb:" .. tostring(v.id or i)
            local vw = UI.button(self, vx, y + math.floor((vh - T.px(22)) / 2), v.label,
                { primary = v.primary and v.enabled ~= false, disabled = v.enabled == false, danger = v.danger, focused = self._fid == fid })
            local vv = v
            self:zone({ fid = fid, x = vx, y = y + math.floor((vh - T.px(22)) / 2), w = vw, h = T.px(22),
                run = function() self:press(vv) end, verb = true })
            vx = vx + vw + T.px(4)
        end
        y = y + vh
    end
    if self._wantGrab and t.verbs then
        -- the controller lands where the kind asks, else on the primary verb,
        -- else on the first live one
        local pick = def.openFocus and def.openFocus(t) or nil
        if not pick then
            for i, v in ipairs(verbs) do
                if v.primary and v.enabled ~= false then pick = "oc:verb:" .. tostring(v.id or i); break end
            end
        end
        if not pick then
            for i, v in ipairs(verbs) do
                if v.enabled ~= false then pick = "oc:verb:" .. tostring(v.id or i); break end
            end
        end
        self._pendingFocus = pick or "oc:back"
        self._wantGrab = nil
    end

    -- BODY (one scrolling unit)
    -- the confirm footer grows to fit its question (two lines at most)
    local footH, footLines = 0, nil
    if self._confirm then
        local textW = w - UI.buttonW(self._confirm.yes) - UI.buttonW(getText("UI_Cancel")) - T.px(8 + 6 + 10 + 22)
        footLines = ZeD.Atoms.wrapText(self._confirm.text, T.fontF2, textW) or { self._confirm.text }
        if #footLines > 2 then
            footLines = { footLines[1], ZeD.CraftingCore.truncText(table.concat(footLines, " ", 2), T.fontF2, textW) }
        end
        footH = math.max(T.px(32), #footLines * (tm:getFontHeight(T.fontF2) + T.px(2)) + T.px(12))
    end
    -- otherwise the kind may keep a state line there (the lock card's answer)
    local status = nil
    if not self._confirm and def.status then
        local sok, st = pcall(def.status, t)
        if sok and st and st.text then status = st; footH = T.px(32) end
    end
    local viewY, viewH = y, h - y - footH
    self._viewY, self._viewH = viewY, viewH
    local scroll = self.scroll
    local totalH = self._bodyH or 0
    local needs = totalH > viewH
    scroll.visible = needs
    local sbw = T.sp.scrollbarW
    scroll.width, scroll.arrowH = sbw, sbw
    local bw = needs and (w - sbw) or w
    local off = 0
    if needs then
        scroll.x, scroll.y, scroll.height = w - sbw, viewY, viewH
        scroll:setBarSize(viewH / totalH)
        off = math.floor(scroll.scrollPos * (totalH - viewH))
    end
    self._off = off
    if not needs then
        scroll:setScrollPos(0)
    end
    self:setStencilRect(0, viewY, bw, viewH)
    local pad = T.px(10)
    local ok, bodyH = pcall(def.body, self, pad, viewY + T.px(8) - off, bw - pad * 2, t, player)
    if not ok then
        ZeD.logOnce("ObjectCards body " .. tostring(def.id), bodyH)
        bodyH = 0
    end
    self._bodyH = (bodyH or 0) + T.px(18)
    self:clearStencilRect()
    if needs then scroll:draw(self) end

    -- jump / follow focus inside the body
    local target = self._jumpTo or self._fid
    if target and needs and target ~= self._followId then
        for _, z in ipairs(self._zones) do
            if z.fid == target and z.body then
                local span = math.max(1, totalH - viewH)
                local cy = z.y - viewY + off
                local newOff = off
                if cy < off + T.px(8) then newOff = cy - T.px(8)
                elseif cy + z.h > off + viewH - T.px(8) then newOff = cy + z.h - viewH + T.px(8) end
                newOff = math.max(0, math.min(span, newOff))
                if newOff ~= off then scroll:setScrollPos(newOff / span) end
                self._followId = target
                break
            end
        end
    end
    self._jumpTo = nil

    -- FOOTER: confirmations only
    if self._confirm then
        local fy = h - footH
        local dg = T.danger
        self:drawRect(0, fy, w, footH, 1, s2.r, s2.g, s2.b)
        self:drawRect(0, fy, w, footH, 0.12, dg.r, dg.g, dg.b)
        self:drawRect(0, fy, w, T.px(1), T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
        local yesW = UI.buttonW(self._confirm.yes)
        local noW = UI.buttonW(getText("UI_Cancel"))
        local btnY = fy + math.floor((footH - T.px(22)) / 2)
        local yesX = w - T.px(8) - yesW
        local noX = yesX - T.px(6) - noW
        UI.button(self, noX, btnY, getText("UI_Cancel"), { focused = self._fid == "oc:confirm:no" })
        UI.button(self, yesX, btnY, self._confirm.yes, { primary = true, focused = self._fid == "oc:confirm:yes" })
        local cf = self._confirm
        self:zone({ fid = "oc:confirm:no", x = noX, y = btnY, w = noW, h = T.px(22), run = function() self._confirm = nil end, foot = true })
        self:zone({ fid = "oc:confirm:yes", x = yesX, y = btnY, w = yesW, h = T.px(22), foot = true,
            run = function()
                self._confirm = nil
                local p = self:player()
                if p and cf.run then
                    local ok2, err = pcall(cf.run, p, e.t, self)
                    if not ok2 then print("[ZeD] ObjectCards: confirm failed: " .. tostring(err)) end
                    e.t._refreshT = OC.REFRESH - 3
                end
            end })
        local lh = tm:getFontHeight(T.fontF2) + T.px(2)
        local ty = fy + math.floor((footH - #footLines * lh) / 2)
        ZeD.Atoms.drawStatusDot(self, T.px(10), ty + math.floor((lh - T.px(7)) / 2), dg, T.px(7))
        for i, ln in ipairs(footLines) do
            self:drawText(ln, T.px(22), ty + (i - 1) * lh, T.text.r, T.text.g, T.text.b, T.text.a, T.fontF2)
        end
    elseif status then
        local fy = h - footH
        self:drawRect(0, fy, w, footH, 1, s2.r, s2.g, s2.b)
        if status.alarm then self:drawRect(0, fy, w, footH, 0.12, T.danger.r, T.danger.g, T.danger.b) end
        self:drawRect(0, fy, w, T.px(1), T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
        local f2 = T.fontF2
        local ty = fy + math.floor((footH - tm:getFontHeight(f2)) / 2)
        ZeD.Atoms.drawStatusDot(self, T.px(10), fy + math.floor((footH - T.px(7)) / 2), status.c or T.accent, T.px(7))
        local s = ZeD.CraftingCore.truncText(status.text, f2, w - T.px(32))
        self:drawText(s, T.px(22), ty, T.text.r, T.text.g, T.text.b, T.text.a, f2)
    end
end

-- Left divider over everything (the drawer's edge toward the inventory).
function ZeD_ObjectCard:render()
    if not self.entry then return end
    local bd = ZeD.T.border
    self:drawRect(0, 0, ZeD.T.px(1), self:getHeight(), bd.a, bd.r, bd.g, bd.b)
end

local function inView(self, z)
    if not z.body then return true end
    return z.y + z.h > (self._viewY or 0) and z.y < (self._viewY or 0) + (self._viewH or 0)
end

-- Zone under a panel-local point (topmost first), or nil.
function ZeD_ObjectCard:zoneAt(x, y)
    local zones = self._zones
    for i = #zones, 1, -1 do
        local z = zones[i]
        if x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h and inView(self, z) then return z end
    end
    return nil
end

-- Mouse: nested drawer children don't get reliable mouse events, so clicks
-- are hit-tested here from the raw mouse state and fire on release over the
-- zone that was pressed (the item card's pattern).
function ZeD_ObjectCard:update()
    ISPanel.update(self)
    local down = isMouseButtonDown(0)
    if not (self.entry and self:getIsVisible()) then
        self._wasDown, self._pressFid, self._sbDrag = down, nil, false
        return
    end
    local mx = getMouseX() - self:getAbsoluteX()
    local my = getMouseY() - self:getAbsoluteY()
    local inside = mx >= 0 and my >= 0 and mx < self:getWidth() and my < self:getHeight()
    if down and not self._wasDown and inside then
        if self.scroll.visible and mx >= self.scroll.x then
            self.scroll:handleMouseDown(my - self.scroll.y)
            self._sbDrag = true
        else
            local z = self:zoneAt(mx, my)
            self._pressFid = z and z.fid or nil
        end
    end
    if self._sbDrag then
        if down then
            if self.scroll.dragging then self.scroll:handleMouseMove(my - self.scroll.y) end
        else
            self.scroll:handleMouseUp()
            self._sbDrag = false
        end
    end
    if down and self._pressFid then
        -- a zone with drag (a slider) follows the mouse while it is held
        for _, z in ipairs(self._zones) do
            if z.fid == self._pressFid then
                if z.drag then z.drag(self, mx, my) end
                break
            end
        end
    end
    if self._wasDown and not down and self._pressFid then
        local z = inside and self:zoneAt(mx, my)
        if z and z.fid == self._pressFid and z.run then z.run(self, self:player()) end
        self._pressFid = nil
    end
    self._wasDown = down
end

-- Consume clicks so they never reach the tab or the world underneath.
function ZeD_ObjectCard:onMouseDown(x, y) return self.entry ~= nil end
function ZeD_ObjectCard:onMouseUp(x, y) return self.entry ~= nil end

function ZeD_ObjectCard:onMouseWheel(del)
    -- a zone with wheel (a dial) takes the wheel while the pointer is on it
    local z = self:zoneAt(getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY())
    if z and z.wheel then z.wheel(del); return true end
    if self.scroll.visible then self.scroll:handleMouseWheel(del) end
    return true
end

-- Pointer over the card (raw mouse state; nested children miss hover events)
function ZeD_ObjectCard:pointerOver()
    if not (self.entry and self:getIsVisible()) then return false end
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    return mx >= 0 and my >= 0 and mx < self:getWidth() and my < self:getHeight()
end

-- Keys for the open card: the World window passes key presses here while a
-- card that reads keys is up and the pointer is over it.
function OC.cardTakesKey(key)
    local card = ZeD_WorldWindow and ZeD_WorldWindow.getObjectCard and ZeD_WorldWindow.getObjectCard()
    local e = card and card.entry
    if not (e and e.def.onKey and card:pointerOver()) then return false end
    local ok, took = pcall(e.def.onKey, e.t, key, card, false)
    return ok and took == true
end
function OC.cardKey(key)
    local card = ZeD_WorldWindow and ZeD_WorldWindow.getObjectCard and ZeD_WorldWindow.getObjectCard()
    local e = card and card.entry
    if not (e and e.def.onKey and card:pointerOver()) then return end
    local ok, err = pcall(e.def.onKey, e.t, key, card, true)
    if not ok then print("[ZeD] ObjectCards: key failed: " .. tostring(err)) end
end

-- The World window asks for key events once a card that reads keys opens
-- (UIManager offers keys only to top-level elements). Chains any handlers
-- the window already has.
function OC.armKeys()
    local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    if not win or win._ocKeysArmed then return end
    win._ocKeysArmed = true
    local prevPress, prevConsumed = win.onKeyPress, win.isKeyConsumed
    win.onKeyPress = function(self, key)
        OC.cardKey(key)
        if prevPress then return prevPress(self, key) end
    end
    win.isKeyConsumed = function(self, key)
        if OC.cardTakesKey(key) then return true end
        if prevConsumed then return prevConsumed(self, key) end
        return false
    end
    win:setWantKeyEvents(true)
end

-- Gamepad elements (panel-local; the card sits at 0,0 in the drawer overlay).
-- A runs the zone; B cancels a confirmation or closes the card; up / down in
-- a long card scroll-follows through the body.
function ZeD_ObjectCard:buildFocusables(win)
    local out = {}
    if not self.entry then return out end
    local card = self
    local confirming = self._confirm ~= nil
    local off = self._off or 0
    for _, z in ipairs(self._zones) do
        if z.fid and not z.nofocus and (not confirming or z.foot) then
            local zz = z
            -- body elements sit at their unscrolled place, so up / down walks
            -- the card top to bottom; scroll-follow brings the focused one in
            out[#out + 1] = {
                x = z.x, y = z.body and (z.y + off) or z.y, w = z.w, h = z.h, id = z.fid, zone = z,
                onFocus = function(w, el) end,
                onActivate = function(w, el) if zz.run then zz.run(card, card:player()) end end,
                onCancel = function(w, el)
                    if card._confirm then card._confirm = nil else card:close() end
                end,
                onDpadDir = zz.dpad and function(w, el, dir)
                    if zz.dpad(dir) then return nil end
                    return false
                end or nil,
                promptB = confirming and getText("UI_Cancel") or ZeD.tr("UI_ZeD_ObjCard_CloseCard"),
            }
        end
    end
    return out
end

function ZeD_ObjectCard:focusKey()
    local e = self.entry
    if not e then return "none" end
    return tostring(e.t and e.t.key) .. "/" .. tostring(#self._zones) .. "/" .. tostring(self._confirm ~= nil)
        .. "/" .. tostring(self.scroll.scrollPos)
end

print("[ZeD] ObjectCards: object card loaded")
return OC
