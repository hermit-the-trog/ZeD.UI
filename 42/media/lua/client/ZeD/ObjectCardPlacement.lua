-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardPlacement.lua
-- ============================================================================
-- OBJECT CARD: 3D PLACEMENT (HOOK_MAP row 15; mockup zed_furniture_v1.html)
-- Vanilla's "Extended 3D Placement" window (ISExtendedPlacementUI) becomes a
-- placement card in the World window's card drawer. Right-click an item lying
-- in the world that has a 3D model; vanilla walks next to it and the card
-- opens. MOVEMENT X / Y / Z (0..1 of the tile) and ROTATION X / Y / Z
-- (0..360 degrees), each a slider with a readout and nudge buttons; REVERT and
-- DONE. Vanilla's world gizmo stays: the move arrows while you work in
-- MOVEMENT, the turn rings in ROTATION, and dragging it updates the card.
-- Closes past vanilla's 3 tiles; closing saves the placement as vanilla does
-- (syncExtendedPlacement).
-- ============================================================================

require "ZeD/ObjectCards"

local OC = ZeD.ObjectCards
local UI = OC.ui
local DEG = string.char(176)

local MOVE_NUDGE, TURN_NUDGE = 0.01, 15
local MOVE_STEP, TURN_STEP = 0.05, 15   -- controller left / right on a slider

local function col(c) return c.r, c.g, c.b end
local function round(v, dp) local m = 10 ^ (dp or 3) return math.floor(v * m + 0.5) / m end

local def = { id = "place3d", leash = 3 }

function def.resolve(player, wi)
    if not (wi and instanceof(wi, "IsoWorldInventoryObject")) then return nil end
    local item = wi:getItem()
    local sq = wi:getSquare()
    if not (item and sq) then return nil end
    local t = { obj = wi, item = item, sq = sq, key = "p3:" .. tostring(item:getID()), group = "translate",
        pn = player:getPlayerNum() }
    t.orig = {
        mx = round(wi:getOffX()), my = round(wi:getOffY()), mz = round(wi:getOffZ()),
        rx = round(item:getWorldXRotation()), ry = round(item:getWorldYRotation()), rz = round(item:getWorldZRotation()),
    }
    -- the world gizmo calls back into this table when it is dragged (vanilla's names)
    t.gz = {
        onRotateGizmo = function(self, v)
            if not def.valid(t) then return end
            local function wrap(a) return a + (a < 0 and 360 or 0) end
            t.item:setWorldXRotation(wrap(v:x())); t.item:setWorldYRotation(wrap(v:y())); t.item:setWorldZRotation(wrap(v:z()))
            t.obj:setExtendedPlacement(true)
        end,
        onTranslateGizmo = function(self, v)
            if not def.valid(t) then return end
            local function c01(a) return math.max(0, math.min(1, a)) end
            t.obj:setOffX(c01(v:x() - t.obj:getX())); t.obj:setOffY(c01(v:y() - t.obj:getY())); t.obj:setOffZ(c01(v:z() - t.obj:getZ()))
            t.obj:setExtendedPlacement(true)
        end,
    }
    return t
end

function def.valid(t)
    return t.obj ~= nil and t.obj:getItem() ~= nil and t.obj:isExistInTheWorld()
end

-- the six values: getter, setter, range
local AXES = {
    move = {
        { id = "x", get = function(t) return t.obj:getOffX() end, set = function(t, v) t.obj:setOffX(v) end },
        { id = "y", get = function(t) return t.obj:getOffY() end, set = function(t, v) t.obj:setOffY(v) end },
        { id = "z", get = function(t) return t.obj:getOffZ() end, set = function(t, v) t.obj:setOffZ(v) end },
    },
    turn = {
        { id = "x", get = function(t) return t.item:getWorldXRotation() end, set = function(t, v) t.item:setWorldXRotation(v) end },
        { id = "y", get = function(t) return t.item:getWorldYRotation() end, set = function(t, v) t.item:setWorldYRotation(v) end },
        { id = "z", get = function(t) return t.item:getWorldZRotation() end, set = function(t, v) t.item:setWorldZRotation(v) end },
    },
}

local function setAxis(t, section, ax, v)
    if section == "move" then
        v = math.max(0, math.min(1, v))
        t.group = "translate"
    else
        v = v % 360
        t.group = "rotate"
    end
    ax.set(t, v)
    t.obj:setExtendedPlacement(true)
end

local function revert(t)
    local o = t.orig
    t.item:setWorldXRotation(o.rx); t.item:setWorldYRotation(o.ry); t.item:setWorldZRotation(o.rz)
    t.obj:setOffX(o.mx); t.obj:setOffY(o.my); t.obj:setOffZ(o.mz)
end

function def.refresh(t, player)
    t.d = { name = t.item:getDisplayName(), tex = t.item:getTex() }
    t.verbs = {
        { id = "done", label = getText("UI_mods_Done"), primary = true, run = function(p, tt, card) card:close() end },
        { id = "revert", label = ZeD.upper(getText("IGUI_ExtendedPlacement_Revert")), run = function(p, tt) revert(tt) end },
    }
    t.needs = {}
end

-- a controller lands on the first slider, ready to move
function def.openFocus(t) return "p3:move:x" end

function def.title(t) return t.d and t.d.name or ZeD.tr("UI_ZeD_Place_Item") end
function def.icon(t) return t.d and t.d.tex or nil end

-- the card leaves: save the placement and put the gizmo away (vanilla close())
function def.onClose(t)
    if t.obj and t.obj:getItem() then
        t.obj:getItem():setDoingExtendedPlacement(false)
        pcall(function() t.obj:syncExtendedPlacement() end)
    end
    pcall(function() Gizmos.getInstance():setGizmo(t.pn or 0, nil) end)
end

-- the world gizmo, every frame the card shows
local function driveGizmo(t)
    local wi, item = t.obj, t.item
    item:setDoingExtendedPlacement(true)
    local G = Gizmos.getInstance()
    local gizmo = (t.group == "rotate") and G:getRotateGizmo(t.pn) or G:getTranslateGizmo(t.pn)
    gizmo:setWorldPosition(wi:getWorldPosX(), wi:getWorldPosY(), wi:getWorldPosZ())
    gizmo:setRotation(item:getWorldXRotation(), item:getWorldYRotation(), item:getWorldZRotation())
    gizmo:setVisible(true)
    gizmo:setTable(t.gz)
    G:setGizmo(t.pn, gizmo)
end

local function axisRow(card, x, y, w, t, section, ax)
    local T, tm = ZeD.T, ZeD.TM
    local h = T.px(28)
    local f1, f3 = T.fontF1, T.fontF3
    local ac = T.accent
    local isMove = section == "move"
    local v = ax.get(t)
    local frac = isMove and v or (v / 360)
    card:drawText(string.upper(ax.id), x, y + math.floor((h - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
    -- nudges (right)
    local nud = isMove and MOVE_NUDGE or TURN_NUDGE
    local nl = isMove and "0.01" or "15"
    -- one button width for both groups, so the six sliders line up
    local bw = math.max(T.px(38), UI.buttonW("+" .. MOVE_NUDGE), UI.buttonW("-" .. MOVE_NUDGE))
    local plusX = x + w - bw
    local minusX = plusX - T.px(3) - bw
    local by = y + math.floor((h - T.px(20)) / 2)
    local idm, idp = "p3:" .. section .. ":" .. ax.id .. ":-", "p3:" .. section .. ":" .. ax.id .. ":+"
    UI.button(card, minusX, by, "-" .. nl, { h = T.px(20), w = bw, focused = card._fid == idm })
    UI.button(card, plusX, by, "+" .. nl, { h = T.px(20), w = bw, focused = card._fid == idp })
    card:zone({ fid = idm, x = minusX, y = by, w = bw, h = T.px(20), body = true, run = function() setAxis(t, section, ax, ax.get(t) - nud) end })
    card:zone({ fid = idp, x = plusX, y = by, w = bw, h = T.px(20), body = true, run = function() setAxis(t, section, ax, ax.get(t) + nud) end })
    -- readout
    local val = isMove and string.format("%.2f", v) or (tostring(math.floor(v + 0.5) % 360) .. DEG)
    local vx = minusX - T.px(10)
    ZeD.Atoms.drawTextRight(card, val, vx, y + math.floor((h - tm:getFontHeight(f3)) / 2), f3, T.text)
    -- slider
    local sx0 = x + T.px(26)
    local sw = vx - T.px(58) - sx0
    local trY = y + math.floor(h / 2) - T.px(3)
    card:drawRect(sx0, trY, sw, T.px(6), 1, col(T.surf1))
    card:drawRect(sx0, trY, math.floor(sw * math.max(0, math.min(1, frac))), T.px(6), 1, col(ac))
    card:drawRectBorder(sx0, trY, sw, T.px(6), T.borderS.a or 1, col(T.borderS))
    for _, f in ipairs({ 0.25, 0.5, 0.75 }) do
        card:drawRect(sx0 + math.floor(sw * f), trY + T.px(8), T.px(1), T.px(4), T.borderS.a or 1, col(T.borderS))
    end
    local sid = "p3:" .. section .. ":" .. ax.id
    local focused = card._fid == sid
    local thW, thH = T.px(12), T.px(18)
    local thX = sx0 + math.floor(sw * math.max(0, math.min(1, frac))) - math.floor(thW / 2)
    local thY = y + math.floor((h - thH) / 2)
    if focused then card:drawRect(thX - T.px(3), thY - T.px(3), thW + 2 * T.px(3), thH + 2 * T.px(3), 0.55, col(ac)) end
    local tb = focused and T.accentBright or T.surf3
    card:drawRect(thX, thY, thW, thH, tb.a or 1, col(tb))
    card:drawRect(thX, thY, thW, T.px(1), T.surf4.a or 1, col(T.surf4))
    card:drawRect(thX, thY, T.px(1), thH, T.surf4.a or 1, col(T.surf4))
    card:drawRect(thX, thY + thH - T.px(1), thW, T.px(1), 1, 0, 0, 0)
    card:drawRect(thX + thW - T.px(1), thY, T.px(1), thH, 1, 0, 0, 0)
    card:zone({ fid = sid, x = sx0 - T.px(6), y = y, w = sw + T.px(12), h = h, body = true,
        drag = function(c, mx, my)
            local f = math.max(0, math.min(1, (mx - sx0) / math.max(1, sw)))
            setAxis(t, section, ax, isMove and f or math.floor(f * 360 + 0.5))
        end,
        dpad = function(dir)
            local step = isMove and MOVE_STEP or TURN_STEP
            if dir == "left" then setAxis(t, section, ax, ax.get(t) - step)
            elseif dir == "right" then setAxis(t, section, ax, ax.get(t) + step)
            else return false end
            return true
        end })
    return h
end

function def.body(card, x, y, w, t, player)
    local T = ZeD.T
    if not def.valid(t) then return 0 end
    local y0 = y
    -- the gizmo follows the group you work in: the controller's focus, else the mouse
    -- (card._fid is set only while a controller drives the card)
    local fid = card._fid
    if fid and fid:sub(1, 8) == "p3:move:" then t.group = "translate"
    elseif fid and fid:sub(1, 8) == "p3:turn:" then t.group = "rotate" end
    local my = card:getMouseY()
    local mx = card:getMouseX()
    local inCard = mx >= 0 and mx < card:getWidth()
    local sec = T.px(20)
    local rowH = T.px(28)
    local moveTop, moveBot = y, y + sec + rowH * 3
    local turnTop = moveBot + T.px(8)
    local turnBot = turnTop + sec + rowH * 3
    if not fid and inCard and not isMouseButtonDown(0) then
        if my >= moveTop and my < moveBot then t.group = "translate"
        elseif my >= turnTop and my < turnBot then t.group = "rotate" end
    end
    pcall(driveGizmo, t)

    y = y + UI.section(card, x, y, w, ZeD.upper(getText("IGUI_ExtendedPlacement_ModeMovement")), ZeD.tr("UI_ZeD_Place_WithinTile"))
    for _, ax in ipairs(AXES.move) do y = y + axisRow(card, x, y, w, t, "move", ax) end
    y = y + T.px(8)
    y = y + UI.section(card, x, y, w, ZeD.upper(getText("IGUI_ExtendedPlacement_ModeRotation")), ZeD.tr("UI_ZeD_Place_Degrees"))
    for _, ax in ipairs(AXES.turn) do y = y + axisRow(card, x, y, w, t, "turn", ax) end
    return y - y0
end

OC.register(def)
