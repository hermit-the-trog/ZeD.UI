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
--   def.title(t) / def.icon(t) / def.pill(t) -> header (pill: the state tag's
--                                words, the status colour of its square mark or
--                                nil for a plain tag, and optionally a mark colour)
--   def.body(card, x, y, w, t, player) -> draws the body, returns its height
--   def.status(t)  (optional)  -> { text, c } a state line in the band at the foot
--   def.onKey(t, key, card) (optional) -> true when the card takes the key
--                                (asked only while the pointer is over the card)
-- Verbs: { id, label, enabled, primary, danger, run(player, t, card), jump = fid,
--          confirm = "question", help, sensible, needs, hint, needsLine }.
-- A verb with jump moves the view (and the controller focus) to a list in the
-- body; one with confirm asks in the band at the foot first (danger when it
-- cannot be undone). The card stays open within OC.LEASH tiles of the object.
-- Hidden actions (ZeD.Disclose): an action the character cannot do yet is not
-- drawn as a button; sensible = false drops one that makes no sense now, needs
-- says in plain words what it wants ("a lighter or matches in your bags") and
-- hint what it would let you do ("light it").
-- Zones may carry wheel(del) (the mouse wheel over them), nofocus = true
-- (clickable, but not a controller stop) and help (the window footer's line
-- while the pointer is over them).
-- ============================================================================

require "ZeD/Molecules"

ZeD = ZeD or {}
ZeD.ObjectCards = ZeD.ObjectCards or {}
local OC = ZeD.ObjectCards
local M, A = ZeD.Molecules, ZeD.Atoms

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

-- A word with its first letter a capital, the rest as it is (the game's lower-case
-- state words: "burning" reads "Burning" in a tag).
function OC.cap(s)
    s = tostring(s or "")
    local b = s:byte(1)
    if b and b >= 97 and b <= 122 then return ZeD.upper(s:sub(1, 1)) .. s:sub(2) end
    return s
end

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

-- Where an item sits, for list rows: Inventory or the bag's name (as the game writes them).
function OC.whereOf(item, player)
    local c = item and call(item, "getContainer")
    if not c or c == player:getInventory() then return ZeD.tr("ContextMenu_MoveToInventory") end
    local bag = call(c, "getContainingItem")
    local n = bag and call(bag, "getDisplayName")
    return n or ZeD.tr("UI_ZeD_ObjCard_WhereNearby")
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
-- The window parts are the library's: push buttons, tags, section heads, fill
-- bars, the band and the NEEDS line (ZeD.Molecules / ZeD.Atoms). Only the
-- hardware below (plates, lamps, gauges, the padlock) is drawn here by hand.
-- ============================================================================
OC.ui = OC.ui or {}
local UI = OC.ui

local function col(c) return c.r, c.g, c.b end

-- ---------------------------------------------------------------------------
-- Surfaces. A strip drawn over the card's body (a section head, the band) must
-- not add its opacity to the body's (see-through): the body is drawn as its rect
-- minus last frame's strips, the way the window draws its own. The card keeps
-- that body as a surface of its own (card._srf, made in drawBackground), so a
-- strip is claimed for it with the library's ZeD.Surface.claim (which also cuts
-- the claim to the clip in force: a head half scrolled out leaves no hole);
-- UI.fill draws a strip and claims it. On any panel but the card these are
-- plain fills.
-- ---------------------------------------------------------------------------
function UI.claim(card, x, y, w, h)
    local sp = card and card._srf
    if not sp then return end
    ZeD.Surface.claim(sp, x, y, w, h)
end

function UI.fill(card, x, y, w, h, token)
    A.surfaceFill(card, x, y, w, h, token or "surf2")
    UI.claim(card, x, y, w, h)
end

-- the pointer is over this zone (the card finds it once a frame from last frame's zones)
function UI.hovered(card, fid) return fid ~= nil and card._hoverFid == fid end

-- ---------------------------------------------------------------------------
-- Buttons and tags
-- ---------------------------------------------------------------------------

-- The library's push button; returns its width. opts: w, h (default T.buttonH), primary, danger,
-- disabled, selected (the current choice of a few: the selected wash under the outline), hover (else
-- the card's hover, or a pointer test off the card), focus (mark opts) or focused (the old flag), help;
-- with fid also stamps the zone (run, body, help) so one call does both.
local _bo = {}
local _selFill = { r = 0, g = 0, b = 0, a = 0 }
local _selColors = { fill = _selFill }
function UI.button(card, x, y, label, opts)
    opts = opts or {}
    local T = ZeD.T
    local w = opts.w or M.buttonW(label)
    local h = opts.h or T.buttonH
    local variant = "default"
    if opts.danger then variant = "danger" elseif opts.primary then variant = "primary" end
    local o = _bo
    if opts.hover ~= nil then o.hover = opts.hover
    elseif opts.fid then o.hover = card._hoverFid == opts.fid
    else o.hover = A.mouseIn(card, x, y, w, h) end
    o.disabled = opts.disabled
    o.focus = opts.focus
    if o.focus == nil and opts.focused then o.focus = card._fmark or true end
    o.help, o.win, o.compact = nil, nil, nil
    local colors = nil
    if opts.selected then
        local ac = T.accent
        _selFill.r, _selFill.g, _selFill.b, _selFill.a = ac.r, ac.g, ac.b, T.selectionA
        colors = _selColors
    end
    M.drawButton(card, x, y, w, h, label, variant, false, colors, o)
    if opts.fid then
        card:zone({ fid = opts.fid, x = x, y = y, w = w, h = h, body = opts.body,
            run = (not opts.disabled) and opts.run or nil, help = opts.help })
    end
    return w
end

function UI.buttonW(label) return M.buttonW(label) end

-- The width of a tag for these words (with its square mark when it has a status).
function UI.tagW(text, hasMark)
    local T = ZeD.T
    local s = A.textCase(text)
    return ZeD.TM:MeasureStringX(T.fontF1, s) + T.px(10) + (hasMark and (T.px(6) + T.px(4)) or 0)
end

-- The one tag look: 16u, a 1u outline, sentence case; a status adds its square mark before the
-- word (a plain tag has none). Returns the width.
function UI.tag(card, x, y, text, status)
    if status == ZeD.T.textDim then status = nil end
    local w = M.drawTag(card, x, y, text, status)
    return w
end

-- Section head: "Light with ......... right" (20u strip, sentence case). A number on the right is the
-- head's count "(4)"; other words sit at the right in the dim colour.
function UI.section(card, x, y, w, label, right)
    local T, tm = ZeD.T, ZeD.TM
    local inset = T.px(8)
    local count = nil
    local n = right and tonumber(right)
    if n then count = math.floor(n) end
    local h = M.drawSectionHeader(card, x + inset, y, w - inset, label, count, false, false, nil, true, inset, nil, true)
    if right and right ~= "" and not count then
        local f1 = T.fontF1
        A.drawTextRight(card, A.textCase(right), x + w - inset, y + math.floor((h - tm:getFontHeight(f1)) / 2), f1, T.textDim)
    end
    UI.claim(card, x, y, w, h)
    return h
end

-- Label + value line over a fill bar. zone = {lo, hi} percent band (the good range), drawn as an
-- outline on the strip. lockText = the skill level that reads the bar (a tag instead of a fill).
function UI.meter(card, x, y, w, label, value, dotC, pct, fillC, zone, lockText)
    local T, tm = ZeD.T, ZeD.TM
    local f1, f2 = T.fontF1, T.fontF2
    local lineH = math.max(tm:getFontHeight(f1), tm:getFontHeight(f2))
    local ac = T.accent
    card:drawText(A.textCase(label), x, y + math.floor((lineH - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
    local vw = tm:MeasureStringX(f2, value or "")
    local vx = x + w - vw
    card:drawText(value or "", vx, y + math.floor((lineH - tm:getFontHeight(f2)) / 2), T.text.r, T.text.g, T.text.b, T.text.a, f2)
    if dotC then A.drawStatusDot(card, vx - T.px(10), y + math.floor((lineH - T.px(6)) / 2), dotC, T.px(6)) end
    local by = y + lineH + T.px(4)
    local bh = T.fillBarH
    A.drawFillBar(card, x, by, w, lockText and 0 or math.max(0, math.min(100, pct or 0)) / 100, false, fillC, bh)
    if lockText then
        local tw = UI.tagW(lockText)
        UI.tag(card, x + w - tw - T.px(6), by + math.floor((bh - T.px(16)) / 2), lockText)
    elseif zone then
        local zx = x + math.floor(w * zone[1] / 100)
        local zw = math.floor(w * (zone[2] - zone[1]) / 100)
        A.frame(card, zx, by, zw, bh, T.textHead, 1, T.line(2))
    end
    return lineH + T.px(4) + bh
end

-- Two-column "Label value" row (pass nil to leave a side empty).
function UI.pair(card, x, y, w, l1, v1, l2, v2)
    local T, tm = ZeD.T, ZeD.TM
    local h = T.px(20)
    local half = math.floor((w - T.px(16)) / 2)
    local function one(px, l, v)
        if not l then return end
        local ac = T.accent
        card:drawText(A.textCase(l), px, y + math.floor((h - tm:getFontHeight(T.fontF1)) / 2), ac.r, ac.g, ac.b, 1, T.fontF1)
        if type(v) == "function" then
            v(px + half, y, h)
        elseif v then
            A.drawTextRight(card, v, px + half, y + math.floor((h - tm:getFontHeight(T.fontF2)) / 2), T.fontF2, T.text)
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
        A.drawTextRight(card, value, x + w - T.px(2), y + math.floor((h - tm:getFontHeight(vf)) / 2), vf, vc)
    end
    card:drawRect(x, y + h - T.px(1), w, T.px(1), T.border.a, col(T.border))
    return h
end

-- Pick row: icon, name, location, gain, tag, push button. Stamps a zone; returns height.
-- opts = { tex, name, where, gain, gainC (the square's colour; default positive), button, fid, run,
--          enabled, tag, tagC (the tag's status colour; textDim or nil = plain), help }
function UI.pick(card, x, y, w, opts)
    local T, tm = ZeD.T, ZeD.TM
    local h = math.max(T.px(26), T.buttonH)
    local isz = T.px(16)
    if opts.tex then card:drawTextureScaledAspect(opts.tex, x + T.px(2), y + math.floor((h - isz) / 2), isz, isz, 1, 1, 1, 1) end
    local label = opts.button or getText("UI_btn_add")
    local bw = M.buttonW(label)
    local bh = T.buttonH - T.px(4)
    local bx = x + w - bw - T.px(2)
    local by = y + math.floor((h - bh) / 2)
    local rx = bx - T.px(8)
    if opts.gain then
        local gf = T.fontF3
        local gw = tm:MeasureStringX(gf, opts.gain)
        card:drawText(opts.gain, rx - gw, y + math.floor((h - tm:getFontHeight(gf)) / 2), T.text.r, T.text.g, T.text.b, T.text.a or 1, gf)
        A.drawStatusDot(card, rx - gw - T.px(10), y + math.floor((h - T.px(6)) / 2), opts.gainC or T.positive, T.px(6))
        rx = rx - gw - T.px(10) - T.px(10)
    end
    if opts.tag then
        local tc = (opts.tagC ~= T.textDim) and opts.tagC or nil
        local tw = UI.tagW(opts.tag, tc ~= nil)
        UI.tag(card, rx - tw, y + math.floor((h - T.px(16)) / 2), opts.tag, tc)
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
    UI.button(card, bx, by, label, { w = bw, h = bh, disabled = opts.enabled == false, fid = opts.fid, body = true,
        run = opts.run, help = opts.help, focus = opts.fid and card.focusOf and card:focusOf(opts.fid) or nil })
    card:drawRect(x, y + h - T.px(1), w, T.px(1), T.border.a, col(T.border))
    return h
end

-- Wrapped paragraph; returns height.
function UI.para(card, x, y, w, text, c, font)
    local T, tm = ZeD.T, ZeD.TM
    font = font or T.fontF2
    c = c or T.text
    local lines = A.wrapText(text or "", font, w) or { text or "" }
    local lh = tm:getFontHeight(font) + T.px(2)
    for i, ln in ipairs(lines) do
        card:drawText(ln, x, y + (i - 1) * lh, c.r, c.g, c.b, c.a or 1, font)
    end
    return #lines * lh
end

-- A line of plain words with a status square before it ("Someone else is using the hook.").
-- markC nil: a hollow square. Returns height.
function UI.note(card, x, y, w, text, markC)
    local T, tm = ZeD.T, ZeD.TM
    local f2 = T.fontF2
    local sq = T.px(6)
    local fh = tm:getFontHeight(f2)
    local tx = x + sq + T.px(8)
    if markC then A.drawStatusDot(card, x, y + math.floor((fh - sq) / 2), markC, sq)
    else A.drawStatusHollow(card, x, y + math.floor((fh - sq) / 2), T.textDim, sq) end
    local lines = A.wrapText(text or "", f2, x + w - tx) or { text or "" }
    local lh = fh + T.px(2)
    for i, ln in ipairs(lines) do
        card:drawText(ln, tx, y + (i - 1) * lh, T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
    end
    return #lines * lh
end

-- A warning box (the generator's fumes, a trough outside any zone): surface 2, a 1u frame, a red
-- square mark and the words in F2.
function UI.warn(card, x, y, w, text)
    local T, tm = ZeD.T, ZeD.TM
    local pad = T.px(8)
    local f2 = T.fontF2
    local sq = T.px(6)
    local fh = tm:getFontHeight(f2)
    local tx = x + pad + sq + T.px(8)
    local lines = A.wrapText(text or "", f2, x + w - pad - tx) or { text or "" }
    local lh = fh + T.px(2)
    local h = #lines * lh + pad * 2 - T.px(2)
    UI.fill(card, x, y, w, h, "surf2")
    A.frame(card, x, y, w, h, T.borderS)
    A.drawStatusDot(card, x + pad, y + pad + math.floor((fh - sq) / 2), T.danger, sq)
    for i, ln in ipairs(lines) do
        card:drawText(ln, tx, y + pad + (i - 1) * lh, T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
    end
    return h
end

-- The NEEDS lines of the old paragraph: one library line per part (each already a sentence).
function UI.needs(card, x, y, w, parts)
    if not parts or #parts == 0 then return 0 end
    local T = ZeD.T
    local h = 0
    for _, p in ipairs(parts) do h = h + M.drawNeedsLine(card, x, y + h, w, p) + T.px(4) end
    return h
end

-- Cooking rows for a container (the item card's cooking reading), "on" = heat on.
function UI.cookRows(card, x, y, w, container, on)
    local T, tm = ZeD.T, ZeD.TM
    local items = container and call(container, "getItems")
    if not items or items:size() == 0 then return 0 end
    local h0 = y
    local rowH = math.max(T.px(28), T.buttonH)
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
                    tag, mode, p = ZeD.tr("IGUI_invpanel_Burnt"), "dng", 1
                elseif call(it, "isCooked") or (toCook > 0 and ct >= toCook) then
                    if on then
                        tag, mode = ZeD.tr("IGUI_invpanel_Burning"), "dng"
                        p = math.max(0, math.min(1, (ct - toCook) / math.max(1, toBurn - toCook)))
                        left = math.max(0, math.ceil(toBurn - ct))
                    else
                        tag, mode = ZeD.tr("Tooltip_food_Cooked"), "pos"
                    end
                else
                    p = toCook > 0 and math.max(0, math.min(1, ct / toCook)) or 0
                    tag, mode = on and ZeD.tr("IGUI_invpanel_Cooking") or ZeD.tr("UI_ZeD_ObjCard_TagRaw"), on and "acc" or "dim"
                    left = on and math.max(0, math.ceil(toCook - ct)) or nil
                end
            end
            local isz = T.px(16)
            if tex then card:drawTextureScaledAspect(tex, x + T.px(2), y + math.floor((rowH - isz) / 2), isz, isz, 1, 1, 1, 1) end
            local barW, pctW = T.px(110), T.px(40)
            local rx = x + w - T.px(2)
            local nx = x + T.px(2) + isz + T.px(8)
            -- the tag's mark carries the colour (burnt / burning red, cooked green, cooking accent); raw has none
            local mc = (mode == "dng") and T.danger or ((mode == "pos") and T.positive or ((mode == "acc") and T.accent or nil))
            local tagW = tag and (UI.tagW(tag, mc ~= nil) + T.px(6)) or 0
            local nstr = ZeD.CraftingCore.truncText(name, T.fontF2, math.max(T.px(30), rx - pctW - barW - T.px(16) - nx - tagW))
            card:drawText(nstr, nx, y + math.floor((rowH - tm:getFontHeight(T.fontF2)) / 2), T.text.r, T.text.g, T.text.b, T.text.a, T.fontF2)
            if tag then UI.tag(card, nx + tm:MeasureStringX(T.fontF2, nstr) + T.px(6), y + math.floor((rowH - T.px(16)) / 2), tag, mc) end
            if p then
                local bx = rx - pctW - barW
                local bh = A.fillBarCompactH()
                A.drawFillBar(card, bx, y + math.floor((rowH - bh) / 2), barW, p, false, mc or T.textDim, bh)
                local ptxt = left and ZeD.tr("UI_ZeD_ObjCard_MinLeft", left) or (mode == "pos" and ZeD.tr("UI_ZeD_ObjCard_Done") or (tostring(math.floor(p * 100 + 0.5)) .. "%"))
                A.drawTextRight(card, ptxt, rx, y + math.floor((rowH - tm:getFontHeight(T.fontF3)) / 2), T.fontF3, T.text)
            end
            card:drawRect(x, y + rowH - T.px(1), w, T.px(1), T.border.a, col(T.border))
            y = y + rowH
        end
    end
    return y - h0
end

-- ---------------------------------------------------------------------------
-- Hardware: 1993 control-panel parts (Visual Catalog A22-A26, M41)
-- Faceplates, lamps, gauges, knobs and the padlock keep their printed looks: they
-- are real parts, not window chrome.
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

-- A filled round part (a lamp, a knob, the padlock's arc), in scan lines on the hairline grid:
-- real hardware is round (the status marks are not, and do not come here). a overrides the alpha.
function UI.disc(card, cx, cy, r, c, a)
    local T = ZeD.T
    local u = T.hair
    r = math.max(u, r)
    local rowH = (r > T.px(40)) and 2 * u or u   -- the biggest discs step in rows two hairlines tall
    local alpha = a or 1
    local rr = r * r
    local top = math.floor(cy - r + 0.5)
    local rows = math.max(1, math.floor(r * 2 / rowH))
    for i = 0, rows - 1 do
        local dy = -r + (i + 0.5) * rowH
        local half = math.sqrt(math.max(0, rr - dy * dy))
        local x0 = math.floor(cx - half + 0.5)
        local x1 = math.floor(cx + half + 0.5)
        if x1 > x0 then card:drawRect(x0, top + i * rowH, x1 - x0, rowH, alpha, c.r, c.g, c.b) end
    end
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
    if serial then A.drawTextRight(card, serial, x + w - T.px(12), y + h - T.px(5) - ZeD.TM:getFontHeight(f5), f5, { r = tc.r, g = tc.g, b = tc.b, a = 0.5 }) end
end

-- Needle gauge: E..F arc, low red zone, label under. (cx, cy) = pivot.
function UI.needle(card, cx, cy, r, frac, label, lowZone)
    local T, HW = ZeD.T, UI.HW
    for d = -60, 60, 2 do UI.run(card, cx, cy, d, r - T.px(1), r, HW.face, T.px(1)) end
    if lowZone then for d = -56, -42, 2 do UI.run(card, cx, cy, d, r - T.px(4), r - T.px(1), HW.red, T.px(2)) end end
    for _, d in ipairs({ -60, -30, 0, 30, 60 }) do UI.run(card, cx, cy, d, r - T.px(7), r - T.px(3), HW.tick, T.px(1)) end
    local f5 = T.fontF5
    card:drawText(ZeD.tr("UI_ZeD_ObjCard_GaugeE"), cx - r - T.px(2), cy - ZeD.TM:getFontHeight(f5) + T.px(2), HW.tick.r, HW.tick.g, HW.tick.b, 1, f5)
    A.drawTextRight(card, ZeD.tr("UI_ZeD_ObjCard_GaugeF"), cx + r + T.px(2), cy - ZeD.TM:getFontHeight(f5) + T.px(2), f5, HW.tick)
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

-- I / O rocker switch (hardware: it keeps its own lit cue). Returns nothing; caller stamps the zone.
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

-- Round knob with a pointer (hardware: it keeps its own lit cue); frac 0..1 sweeps -135..+135 degrees.
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

local function worldWin()
    return ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow() or nil
end

-- Focused gamepad element id when focus sits in the card's ring zone, the World window
-- has the focus and the controller is the thing in use (a mouse press clears it).
local function focusedId()
    local win = worldWin()
    local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
    if not (win and Focus and Focus.isFocused and Focus.liveElement) then return nil end
    if not Focus.isFocused(win, "worldItemCard") then return nil end
    local fe = Focus.liveElement(win)
    return fe and fe.id or nil
end

-- The focus mark's options for this element, or nil when the controller is not on it
-- (ZeD.Focus.mark opts: the window and the zone the mark belongs to).
function ZeD_ObjectCard:focusOf(fid)
    if fid and self._fid == fid then return self._fmark end
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
        self._confirm = { text = v.confirm, yes = v.label, run = v.run, danger = v.danger and true or false, help = v.help }
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

local function inView(self, z)
    if not z.body then return true end
    return z.y + z.h > (self._viewY or 0) and z.y < (self._viewY or 0) + (self._viewH or 0)
end

-- The element under the pointer, from last frame's zones: its wash, and its words in the
-- window's help line. Off while the controller's mark shows, so a resting pointer never
-- paints a second highlight beside it.
function ZeD_ObjectCard:updateHover()
    self._hoverFid = nil
    local F = ZeD.Input and ZeD.Input.Focus
    if F and F.cuesVisible and F.cuesVisible() then return end
    if not self:pointerOver() then return end
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    local zones = self._lastZones
    for i = #zones, 1, -1 do
        local z = zones[i]
        if mx >= z.x and mx < z.x + z.w and my >= z.y and my < z.y + z.h and inView(self, z) then
            self._hoverFid = z.fid
            if z.help and ZeD.Help and ZeD.Help.set then ZeD.Help.set(self, z.help) end
            return
        end
    end
end

-- The card's body surface: its rect less the strips drawn over it last frame (UI.claim), so a
-- strip never stacks opacity on the body.
function ZeD_ObjectCard:drawBackground(w, h)
    local S = ZeD.Surface
    if not (S and S.beginFrame and S.drawBody) then
        local s1 = ZeD.T.surf1
        self:drawRect(0, 0, w, h, s1.a or 1, s1.r, s1.g, s1.b)
        return
    end
    local sp = self._srf
    if not sp then
        local card = self
        -- The card's body surface: it stands in for a window to ZeD.Surface (the body and
        -- the claims on it are in the card's own coordinates)
        sp = {
            isZeDWindow = true,
            getWidth = function() return card:getWidth() end,
            getHeight = function() return card:getHeight() end,
            getAbsoluteX = function() return card:getAbsoluteX() end,
            getAbsoluteY = function() return card:getAbsoluteY() end,
        }
        -- (the pieces go through the library's fill, so the window leaves those rects alone too)
        sp.drawRect = function(_, px, py, pw, ph) A.surfaceFill(card, px, py, pw, ph, "surf1") end
        self._srf = sp
    end
    S.beginFrame(sp)
    S.drawBody(sp, 0, 0, w, h, "surf1")
end

-- a kind's own header call: a throw drops that piece, logged once, rather than every frame
local function kindCall(e, f, ...)
    if not f then return nil end
    local ok, a, b, c = pcall(f, ...)
    if ok then return a, b, c end
    ZeD.logOnce("ObjectCards header " .. tostring(e.def and e.def.id), a)
    return nil
end

-- the arrows of the browse buttons: a left and a right triangle
local function triGlyph(left)
    return function(p, x, y, s, c)
        local t = math.max(ZeD.T.px(6), math.floor(s * 0.6))
        local f = left and A.drawTriangleLeft or A.drawTriangleRight
        f(p, x + math.floor((s - t) / 2), y + math.floor((s - t) / 2), t, c)
    end
end
local GLYPH_PREV, GLYPH_NEXT = triGlyph(true), triGlyph(false)

-- the mark of a state tag: the status colour (a plain tag has none), or the mark colour a kind gives
local function tagMark(c, markC)
    local s = markC or c
    if s == nil or s == ZeD.T.textDim then return nil end
    return s
end

-- The header (37u, a structure line under): the back key, the thing's icon, its name and state
-- tag, and on the right the browse buttons when more of the same kind are in reach.
function ZeD_ObjectCard:drawHeader(e, hh, win)
    local T, tm = ZeD.T, ZeD.TM
    local def, t = e.def, e.t
    local w = self:getWidth()
    local hv = self._hoverFid
    local bsz = T.buttonH
    local by = math.floor((hh - bsz) / 2)
    local bx = T.px(8)
    -- the close key's X, as the item card's (director, Oct 30 2026)
    M.drawCloseKey(self, bx, by, bsz, { hover = hv == "oc:back", focus = self:focusOf("oc:back"), win = win })
    self:zone({ fid = "oc:back", x = bx, y = by, w = bsz, h = bsz, run = function() self:close() end,
        help = ZeD.tr("UI_ZeD_Card_HelpClose") })
    local cx = bx + bsz + T.px(6)
    local isz = T.px(22)
    local iy = math.floor((hh - isz) / 2)
    A.frame(self, cx, iy, isz, isz, T.borderS)
    local icon = kindCall(e, def.icon, t)
    if icon then self:drawTextureScaledAspect(icon, cx + T.px(2), iy + T.px(2), isz - 2 * T.px(2), isz - 2 * T.px(2), 1, 1, 1, 1) end
    cx = cx + isz + T.px(8)
    -- browse (right)
    local rightX = w - T.px(8)
    if e.list and #e.list > 1 then
        local f3 = T.fontF3
        local txt = tostring(e.idx or 1) .. " / " .. tostring(#e.list)
        local nextX = rightX - bsz
        M.drawIconButton(self, nextX, by, bsz, GLYPH_NEXT, { hover = hv == "oc:next", focus = self:focusOf("oc:next"),
            hint = ZeD.tr("UI_ZeD_ObjCard_Next"), id = "oc:next", win = win })
        self:zone({ fid = "oc:next", x = nextX, y = by, w = bsz, h = bsz, help = ZeD.tr("UI_ZeD_ObjCard_HelpNext"),
            run = function() OC.browse(e, 1); self._confirm = nil; self.scroll:setScrollPos(0) end })
        local tw = tm:MeasureStringX(f3, txt)
        local tx = nextX - T.px(6) - tw
        self:drawText(txt, tx, by + math.floor((bsz - tm:getFontHeight(f3)) / 2), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f3)
        local prevX = tx - T.px(6) - bsz
        M.drawIconButton(self, prevX, by, bsz, GLYPH_PREV, { hover = hv == "oc:prev", focus = self:focusOf("oc:prev"),
            hint = ZeD.tr("UI_ZeD_ObjCard_Prev"), id = "oc:prev", win = win })
        self:zone({ fid = "oc:prev", x = prevX, y = by, w = bsz, h = bsz, help = ZeD.tr("UI_ZeD_ObjCard_HelpPrev"),
            run = function() OC.browse(e, -1); self._confirm = nil; self.scroll:setScrollPos(0) end })
        rightX = prevX - T.px(10)
    end
    local pillTxt, pillC, pillMark = kindCall(e, def.pill, t)
    local mark = pillTxt and tagMark(pillC, pillMark) or nil
    local pillW = pillTxt and (UI.tagW(pillTxt, mark ~= nil) + T.px(8)) or 0
    local nf = T.fontF4
    local name = kindCall(e, def.title, t) or "?"
    local nstr = ZeD.CraftingCore.truncText(name, nf, math.max(T.px(40), rightX - cx - pillW - T.px(10)))
    local th = T.textHead
    self:drawText(nstr, cx, math.floor((hh - tm:getFontHeight(nf)) / 2), th.r, th.g, th.b, th.a or 1, nf)
    if pillTxt then
        M.drawTag(self, cx + tm:MeasureStringX(nf, nstr) + T.px(8), math.floor((hh - T.px(16)) / 2), pillTxt, mark)
    end
    A.drawDividerH(self, 0, hh - T.hair, w, true)
end

-- the verbs in the order they read: the primary one first, the one that starts a question last
local function inOrder(list)
    local first, mid, last = {}, {}, {}
    for _, v in ipairs(list) do
        if v.primary and v.enabled ~= false then first[#first + 1] = v
        elseif v.danger then last[#last + 1] = v
        else mid[#mid + 1] = v end
    end
    for _, v in ipairs(mid) do first[#first + 1] = v end
    for _, v in ipairs(last) do first[#first + 1] = v end
    return first
end

-- The verbs for the thing, under its name: push buttons (hidden actions per the ZeD setup: a
-- greyed verb with its NEEDS line, or one folded row that opens to them). Returns the y under.
function ZeD_ObjectCard:drawVerbs(e, y, win)
    local T = ZeD.T
    local DS = ZeD.Disclose
    local def, t = e.def, e.t
    local w = self:getWidth()
    local verbs = t.verbs or {}
    for _, v in ipairs(verbs) do v.canDo = v.enabled ~= false end
    local setting = DS.setting()
    local shown, hidden = DS.split(verbs, setting)
    shown = inOrder(shown)
    self._shown = shown
    -- where a D-pad move into the card lands: the primary verb, else the first that can run
    local mainFid
    for i, v in ipairs(shown) do
        if v.primary and v.enabled ~= false then mainFid = "oc:verb:" .. tostring(v.id or i); break end
    end
    if not mainFid then
        for i, v in ipairs(shown) do
            if v.enabled ~= false then mainFid = "oc:verb:" .. tostring(v.id or i); break end
        end
    end
    self._mainFid = mainFid
    if #shown == 0 and #hidden == 0 then return y end

    local padX, gap = T.px(8), T.px(6)
    local bh = T.buttonH
    local hv = self._hoverFid
    local vx, vy = padX, y + T.px(6)
    local maxX = w - padX
    for i, v in ipairs(shown) do
        local fid = "oc:verb:" .. tostring(v.id or i)
        local bw = M.buttonW(v.label)
        if vx + bw > maxX and vx > padX then vx = padX; vy = vy + bh + gap end
        UI.button(self, vx, vy, v.label, { w = bw, h = bh, primary = v.primary and v.enabled ~= false, danger = v.danger,
            disabled = v.enabled == false, hover = hv == fid, focus = self:focusOf(fid) })
        local vv = v
        self:zone({ fid = fid, x = vx, y = vy, w = bw, h = bh, run = function() self:press(vv) end, verb = true,
            primary = (fid == mainFid) or nil, help = v.help })
        vx = vx + bw + gap
    end
    local cy = (#shown > 0) and (vy + bh + T.px(6)) or (y + T.px(2))
    -- Show all: one NEEDS line for each greyed verb
    if setting == "all" then
        for _, v in ipairs(shown) do
            if not v.canDo then cy = cy + M.drawNeedsLine(self, padX, cy, w - 2 * padX, DS.needsLine(v)) + T.px(4) end
        end
    end
    -- Folded: one quiet row after the verbs; open, the hidden verbs greyed with their NEEDS lines
    if #hidden > 0 then
        local key = "oc:" .. tostring(def.id)
        for i, v in ipairs(hidden) do
            local hf = "oc:hv:" .. tostring(v.id or i)
            v.hover, v.focus = hv == hf, self:focusOf(hf)
        end
        local mh, rowRect, vrects = M.drawMoreRow(self, padX, cy, w - 2 * padX, hidden, key,
            { hover = hv == "oc:more", focus = self:focusOf("oc:more"), inset = T.px(2), win = win })
        if rowRect then
            self:zone({ fid = "oc:more", x = rowRect.x, y = rowRect.y, w = rowRect.w, h = rowRect.h,
                run = function() DS.toggle(key) end, help = ZeD.tr("UI_ZeD_ObjCard_HelpMore") })
        end
        for i, r in pairs(vrects) do
            local v = hidden[i]
            self:zone({ fid = "oc:hv:" .. tostring(v.id or i), x = r.x, y = r.y, w = r.w, h = r.h, help = DS.needsLine(v) })
        end
        cy = cy + mh + T.px(2)
    end
    cy = cy + T.px(4)
    A.drawDividerH(self, 0, cy, w, false)
    return cy + T.hair
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
    local T, tm = ZeD.T, ZeD.TM
    local w, h = self:getWidth(), self:getHeight()
    self._lastZones = self._zones
    self._zones = {}
    self._fid = focusedId()
    local win = worldWin()
    local fm = self._fmark
    if not fm then fm = {}; self._fmark = fm end
    fm.win, fm.zone = win, "worldItemCard"
    self:updateHover()
    local def, t = e.def, e.t

    self:drawBackground(w, h)
    local hh = T.px(37)
    self:drawHeader(e, hh, win)
    local y = self:drawVerbs(e, hh, win)
    if self._wantGrab and t.verbs then
        -- the controller lands where the kind asks, else on the primary verb,
        -- else on the first live one
        local pick = def.openFocus and def.openFocus(t) or nil
        self._pendingFocus = pick or self._mainFid or "oc:back"
        self._wantGrab = nil
    end

    -- BODY (one scrolling unit); the band at the foot holds a question, or the kind's state line
    local footH, status = 0, nil
    local cf = self._confirm
    if cf then
        footH = M.bandH()
    elseif def.status then
        local sok, st = pcall(def.status, t)
        if sok and st and st.text then status = st; footH = M.bandH() end
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
    -- a machine plate's room: the body's width without the scrollbar, so the face picked and its zoom never flip
    -- with it (Oct 30 2026: the plates that fill the card; a face up to it overhangs the body by at most half the
    -- scrollbar's width each side, inside the margins)
    self._plateRoom = w - pad * 2
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

    -- the band at the foot: the question before the act that asks one, else the kind's state line
    local fy = h - footH
    if cf then
        UI.claim(self, 0, fy, w, footH)
        local _, cr, vr = M.drawQuestionBand(self, 0, fy, w, cf.text, cf.yes, { danger = cf.danger, win = win,
            cancelFocus = self:focusOf("oc:confirm:no"), verbFocus = self:focusOf("oc:confirm:yes"), verbHelp = cf.help,
            cancelHelp = ZeD.tr("UI_ZeD_ObjCard_HelpCancel") })
        self:zone({ fid = "oc:confirm:no", x = cr.x, y = cr.y, w = cr.w, h = cr.h, foot = true,
            run = function() self._confirm = nil end })
        self:zone({ fid = "oc:confirm:yes", x = vr.x, y = vr.y, w = vr.w, h = vr.h, foot = true,
            run = function()
                self._confirm = nil
                local p = self:player()
                if p and cf.run then
                    local ok2, err = pcall(cf.run, p, e.t, self)
                    if not ok2 then print("[ZeD] ObjectCards: confirm failed: " .. tostring(err)) end
                    e.t._refreshT = OC.REFRESH - 3
                end
            end })
    elseif status then
        UI.claim(self, 0, fy, w, footH)
        M.drawBand(self, 0, fy, w, { status = { text = status.text, color = status.c }, win = win })
    end
end

-- The drawer's edge toward the inventory, over everything: a structure line meeting the title bar
-- above and the help line below.
function ZeD_ObjectCard:render()
    self:_pointer()   -- (every frame drawn: update() runs only every 100 ms)
    if not self.entry then return end
    A.drawDividerV(self, 0, 0, self:getHeight(), true)
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
-- zone that was pressed (the item card's pattern). Polled on every frame drawn
-- (render): the engine runs update() only every 100 ms (42.22), and a click
-- between two updates was missed (Oct 30 2026).
function ZeD_ObjectCard:update()
    ISPanel.update(self)
end

function ZeD_ObjectCard:_pointer()
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
                isPrimary = z.primary,   -- (Oct 23 2026: where a move into the card lands)
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
