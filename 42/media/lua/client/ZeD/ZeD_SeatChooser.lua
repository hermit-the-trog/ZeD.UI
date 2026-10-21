-- ZeD-UI/42/media/lua/client/ZeD/ZeD_SeatChooser.lua
-- ============================================================================
-- THE SEAT CHOOSER — vanilla's ISVehicleSeatUI as a small ZeD window
-- Mockup ZeDUI/mockups/zed_seats_lightbar_v1.html (director, Oct 15 2026:
-- "love it, build both"). HOOK_MAP row 4; the hook is Overrides/Seats.lua
-- (ISVehicleMenu.onShowSeatUI: the wheel's Switch Seat and Enter Vehicle, the
-- seat key).
--
-- Where vanilla's sat (the middle of the player's screen, re-centred every
-- frame), the same size. The car is vanilla's own seat-chooser outline,
-- tinted; the seats sit at vanilla's own places (the passenger positions, the
-- same scale and per-car offsets), so every vehicle, a mod's too, lines up as
-- it does in vanilla.
--
-- Each seat is a seat seen from above (art baked by ZeDUI/tools/seats/
-- bake_seat_art.py): an empty one shows its number (the key that takes it);
-- someone sitting is a crash test dummy (the accent for you, grey for anyone
-- else); items are a pile of junk; a seat not fitted is its dashed place; a
-- seat that can't be taken from here is stippled. The pointed seat grows and
-- turns the accent. The band under the title names it and gives vanilla's
-- reason with a status dot. Doors are the context strip's cells beside the car,
-- one per door you could leave by (Shift numbers them).
--
-- Every rule and every action is vanilla's: canSwitchSeat, moveItemsFromSeat,
-- isExitBlocked, onSwitchSeat / onEnter / onExit, the keys (1..n sit, Shift +
-- n get out, the seat key and Escape close), the controller's seat grid.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Organisms"
ZeD.trDefaults({
    UI_ZeD_Seat_ByDoor = "By the %1 door.", UI_ZeD_Seat_DpadMove = "D-PAD Move", UI_ZeD_Seat_Sit = "Sit",
    UI_ZeD_Seat_GetOutHere = "Get out here", UI_ZeD_Seat_NumberGetOut = "+ number: Get out",
})

ZeD = ZeD or {}
ZeD.Seats = ZeD.Seats or {}
local S = ZeD.Seats
S.windows = S.windows or {}

-- design units (1 px at 1080p; T.px scales them)
local U = {
    W = 330, BAND_H = 46, BAND_PAD = 12, FIG_H = 392, FOOT_H = 40, FOOT_PAD = 12,
    BTN_H = 24, BTN_MIN = 78, BTN_PAD = 12,
    SEAT_W = 34, SEAT_H = 48, SEAT_ON_W = 42, SEAT_ON_H = 58,
    DOOR = 24, DOOR_ON = 33, DOOR_ICON = 15, DOOR_ICON_ON = 22, DOOR_GAP = 22,
}
local VAN_H, VAN_SCALE = 500, 0.7   -- vanilla's panel height and the car's share of it (its seat scale)
local BOX_W, BOX_H = 42, 58         -- the baked art's unit box
local ART = "media/textures/ZeD/seats/"
-- the context strip's locked paper and ink (cells read the same on every theme)
local INK   = { r = 0.08, g = 0.08, b = 0.08 }
local PAPER = { r = 0.95, g = 0.95, b = 0.95 }
local OTHER = { r = 0.415, g = 0.415, b = 0.415 }   -- someone else's dummy
local JUNK  = { r = 0.68, g = 0.68, b = 0.68 }

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------
local function fh(font) return ZeD.TM:getFontHeight(font) end
local function tw(font, s) return ZeD.TM:MeasureStringX(font, s) end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(name) pcall(function() getSoundManager():playUISound(name or "UIActivateButton") end) end

local _tex = {}
local function tex(path)
    local t = _tex[path]
    if t == nil then t = getTexture(path) or false; _tex[path] = t end
    return t or nil
end
-- the baked layer fine enough for a cell `pxW` screen px wide (1, 2 or 3 px per unit)
local function art(name, pxW)
    local need = pxW / BOX_W
    local ppu = (need <= 1.05 and 1) or (need <= 2.05 and 2) or 3
    return tex(ART .. name .. "_" .. ppu .. "x.png")
end

local function seatName(script, i)
    local id = "Seat"
    pcall(function() id = "Seat" .. script:getPassenger(i):getId() end)
    return getTextOrNull("IGUI_" .. id) and getText("IGUI_" .. id) or id
end

local function vehicleName(v)
    local name = ""
    pcall(function()
        local sc = v:getScript()
        local car = sc:getCarModelName() or sc:getName()
        name = getTextOrNull("IGUI_VehicleName" .. tostring(car)) or tostring(car)
    end)
    return name
end

-- ---------------------------------------------------------------------------
-- ZeD_SeatChooser
-- ---------------------------------------------------------------------------
ZeD_SeatChooser = ZeD_Window:derive("ZeD_SeatChooser")

function ZeD_SeatChooser:new(character)
    local o = ZeD_Window.new(self, 0, 0, 100, 100, "")
    o.resizable = false
    o.themeFooter = false
    o.pin = true
    o.anchorLeft, o.anchorRight, o.anchorTop, o.anchorBottom = true, false, true, false
    o.moveWithMouse = false
    o.character = character
    o.playerNum = character:getPlayerNum()
    o.vehicle = nil
    o.joypadSeat = 1
    o._hover = nil
    o:setWantKeyEvents(true)
    return o
end

function ZeD_SeatChooser:createChildren()
    ZeD_Window.createChildren(self)
    self.minimumWidth, self.minimumHeight = 0, 0
end

-- vanilla's setVehicle: the controller starts on your own seat
function ZeD_SeatChooser:setVehicle(vehicle)
    self.vehicle = vehicle
    self.characterSeat = nil
    self.joypadSeat = 1
    self._hover = nil
    if self.character:getVehicle() == vehicle then
        self.characterSeat = vehicle:getSeat(self.character)
        self.joypadSeat = self.characterSeat + 1
    end
end

function ZeD_SeatChooser:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if JoypadState.players[self.playerNum + 1] then setJoypadFocus(self.playerNum, nil) end
end

-- ---------------------------------------------------------------------------
-- STATE (vanilla's rules, read once a frame)
-- ---------------------------------------------------------------------------
function ZeD_SeatChooser:readSeats()
    local v, chr = self.vehicle, self.character
    local script = v:getScript()
    local scriptName = v:getScriptName()
    local ext = script:getExtents()
    local scale = (VAN_H * VAN_SCALE) / ext:z()
    local ox = (SeatOffsetX and SeatOffsetX[scriptName]) or 0
    local oy = (SeatOffsetY and SeatOffsetY[scriptName]) or 0
    local playerSeat = v:getSeat(chr)
    local seats, doors = {}, {}
    for n = 1, v:getMaxPassengers() do
        local i = n - 1
        local pngr = script:getPassenger(i)
        local inside = pngr and pngr:getPositionById("inside")
        local st = { i = i, n = n }
        if inside then
            local off = inside:getOffset()
            st.dx, st.dy = -off:get(0) * scale + ox, -off:get(2) * scale + oy
        end
        local occupied = v:isSeatOccupied(i)
        local who = v:getCharacter(i)
        if occupied then
            if who then
                st.kind = (who == chr) and "you" or "person"
            else
                st.kind = "items"
                st.movable = ISVehicleMenu.moveItemsFromSeat(chr, v, i, false, false) and true or false
                st.off = not st.movable
            end
        else
            local part = v:getPartForSeatContainer(i)
            if part and not part:getInventoryItem() then st.kind = "none" else st.kind = "empty" end
        end
        if playerSeat ~= -1 and playerSeat ~= i and not v:canSwitchSeat(playerSeat, i) then
            st.far = true
            if st.kind ~= "you" and st.kind ~= "person" and st.kind ~= "none" then st.off = true end
        end
        seats[n] = st
        -- a door you could leave by (inside only): vanilla's exit test
        if playerSeat ~= -1 then
            local can = v:canSwitchSeat(playerSeat, i)
            if occupied then
                can = false
                if not who then can = st.movable end
            end
            if playerSeat == i then can = true end
            v:updateHasExtendOffsetForExit(chr)
            if v:isExitBlocked(chr, i) then can = false end
            v:updateHasExtendOffsetForExitEnd(chr)
            local outside = pngr and pngr:getPositionById("outside")
            if can and outside then
                local off = outside:getOffset()
                doors[n] = { n = n, i = i, dx = -off:get(0) * scale, dy = -off:get(2) * scale + oy }
            end
        end
    end
    self._seats, self._doors, self._playerSeat, self._script = seats, doors, playerSeat, script
end

-- vanilla's reason for a seat (prerender of ISVehicleSeatUI), with its dot
function ZeD_SeatChooser:reason(st)
    local v, i = self.vehicle, st.i
    if not v:isSeatInstalled(i) then return getText("IGUI_VehicleSeat_Uninstalled"), "danger" end
    if v:isSeatOccupied(i) then
        local str, dot
        if st.movable then str, dot = getText("IGUI_VehicleSeat_MoveItems"), "warning"
        else str, dot = getText("IGUI_VehicleSeat_Items"), "danger" end
        if self.characterSeat == i then str, dot = getText("IGUI_VehicleSeat_Self"), "accent"
        elseif v:getCharacter(i) then str, dot = getText("IGUI_VehicleSeat_Person"), "danger" end
        return str, dot
    end
    if self._playerSeat ~= -1 and not v:canSwitchSeat(self._playerSeat, i) then
        return getText("IGUI_VehicleSeat_ExitToSwitch"), "danger"
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- ACTIONS (vanilla's useSeat / exitSeat, unchanged)
-- ---------------------------------------------------------------------------
function ZeD_SeatChooser:useSeat(seat)
    local v = self.vehicle
    if not (v and v:isSeatInstalled(seat)) then return end
    if v:getCharacter(seat) then return end
    self:close()
    local chr = self.character
    if chr:getVehicle() then
        if v:canSwitchSeat(v:getSeat(chr), seat) then
            local part = v:getPartForSeatContainer(seat)
            local cont = part and part:getItemContainer()
            if cont then
                local minWeight = cont:getCapacity() / 4
                local weight = cont:getCapacityWeight()
                if (weight > minWeight) and not ISVehicleMenu.moveItemsFromSeat(chr, v, seat, true, false) then return end
            end
            ISVehicleMenu.onSwitchSeat(chr, seat)
        else
            -- the ambulance's front seats aren't reachable from the back
            ISVehicleMenu.onExit(chr)
            ISVehicleMenu.onEnter(chr, v, seat)
        end
    else
        ISVehicleMenu.onEnter(chr, v, seat)
    end
end

function ZeD_SeatChooser:exitSeat(seat)
    local v = self.vehicle
    if not (v and v:isSeatInstalled(seat)) then return end
    local chr = self.character
    local playerSeat = v:getSeat(chr)
    if playerSeat == -1 then return end
    self:close()
    if seat == playerSeat then ISVehicleMenu.onExit(chr); return end
    if v:isSeatOccupied(seat) then return end
    if chr:getVehicle() and v:canSwitchSeat(playerSeat, seat) then
        ISVehicleMenu.onSwitchSeat(chr, seat)
        ISVehicleMenu.onExit(chr, seat)
    end
end

-- ---------------------------------------------------------------------------
-- LAYOUT (every frame from the live tokens; geometry in self._g, local px)
-- ---------------------------------------------------------------------------
function ZeD_SeatChooser:layout()
    local T = ZeD.T
    local g = { seats = {}, doors = {} }
    local tbH = self:titleBarHeight()
    local w = T.px(U.W)
    local bandY, bandH = tbH, T.px(U.BAND_H)
    local figY, figH = bandY + bandH, T.px(U.FIG_H)
    local footY, footH = figY + figH, T.px(U.FOOT_H)
    local stripH = T.sp.scrollbarW
    local h = footY + footH + stripH
    g.band = { y = bandY, h = bandH }
    g.fig = { y = figY, h = figH, cx = math.floor(w / 2), cy = figY + math.floor(figH / 2) }
    g.foot = { y = footY, h = footH }
    g.strip = { y = footY + footH, h = stripH }
    -- the car: vanilla's outline at its own size (times its per-shape scale)
    local u = T.px(1000) / 1000
    local script = self._script
    local overlay = script and (script:getCarMechanicsOverlay() or self.vehicle:getScriptName())
    local props = overlay and ISCarMechanicsOverlay and ISCarMechanicsOverlay.CarList and ISCarMechanicsOverlay.CarList[overlay]
    -- vanilla's drawing is white lines over a black fill; ZeD's copy is the lines alone
    -- (ZeDUI/tools/seats/bake_car_outlines.py), on vanilla's 263 x 600 canvas
    local shape = props and props.imgPrefix
    local vtex = shape and getTexture("media/ui/vehicles/seatui/" .. shape .. "base_small.png")
    local lineTex = shape and tex(ART .. "zs_car_" .. (shape:gsub("_$", "")) .. ".png")
    if vtex or lineTex then
        local k = (ImageScale and ImageScale[shape]) or 1.0
        local bw, bh = vtex and vtex:getWidthOrig() or 263, vtex and vtex:getHeightOrig() or 600
        local cw, ch = bw * k * u, bh * k * u
        g.car = { tex = lineTex or vtex, lines = lineTex ~= nil, x = g.fig.cx - cw / 2, y = g.fig.cy - ch / 2, w = cw, h = ch }
    elseif script then
        local ext = script:getExtents()
        local ch = VAN_H * VAN_SCALE * u
        local cw = ch * ext:x() / ext:z()
        g.car = { x = g.fig.cx - cw / 2, y = g.fig.cy - ch / 2, w = cw, h = ch }
    end
    -- the seats (pointed: grown) and the doors, at vanilla's places
    local pointed = self:pointedSeat()
    for n, st in ipairs(self._seats or {}) do
        if st.dx then
            local on = pointed == n
            local sw, sh = T.px(on and U.SEAT_ON_W or U.SEAT_W), T.px(on and U.SEAT_ON_H or U.SEAT_H)
            local cx, cy = g.fig.cx + st.dx * u, g.fig.cy + st.dy * u
            g.seats[n] = { x = math.floor(cx - sw / 2), y = math.floor(cy - sh / 2), w = sw, h = sh, st = st, on = on,
                           hit = { x = math.floor(cx - T.px(U.SEAT_W) / 2), y = math.floor(cy - T.px(U.SEAT_H) / 2), w = T.px(U.SEAT_W), h = T.px(U.SEAT_H) } }
        end
    end
    local pdoor = self._hover and self._hover.door or nil
    for n, d in pairs(self._doors or {}) do
        local show = not self.joyfocus or n == self.joypadSeat
        if show then
            local on = pdoor == n and not self.joyfocus
            local sz = T.px(on and U.DOOR_ON or U.DOOR)
            local cx, cy = g.fig.cx + d.dx * u, g.fig.cy + d.dy * u
            g.doors[n] = { x = math.floor(cx - sz / 2), y = math.floor(cy - sz / 2), w = sz, h = sz, d = d, on = on,
                           hit = { x = math.floor(cx - T.px(U.DOOR) / 2), y = math.floor(cy - T.px(U.DOOR) / 2), w = T.px(U.DOOR), h = T.px(U.DOOR) } }
        end
    end
    -- the footer's one answer
    local label = ZeD.upper(getText("UI_Cancel"))
    local bw = math.max(T.px(U.BTN_MIN), tw(T.fontF3, label) + T.px(U.BTN_PAD) * 2)
    local bh = T.px(U.BTN_H)
    g.cancel = { x = w - T.px(U.FOOT_PAD) - bw, y = footY + math.floor((footH - bh) / 2), w = bw, h = bh, label = label }
    -- size and place: vanilla re-centres on the player's screen every frame
    if self.width ~= w then self:setWidth(w) end
    if self.height ~= h then self:setHeight(h) end
    local pn = self.playerNum
    local x = getPlayerScreenLeft(pn) + math.floor((getPlayerScreenWidth(pn) - w) / 2)
    local y = getPlayerScreenTop(pn) + math.floor((getPlayerScreenHeight(pn) - h) / 2)
    if self.x ~= x then self:setX(x) end
    if self.y ~= y then self:setY(y) end
    self._g = g
end

-- the seat the band and the art treat as pointed: the controller's, or the one under the pointer
function ZeD_SeatChooser:pointedSeat()
    if self.joyfocus then return self.joypadSeat end
    return self._hover and self._hover.seat or nil
end

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------
local function tinted(p, t, x, y, w, h, c, a)
    if t then p:drawTextureScaledAspect(t, x, y, w, h, a or 1, c.r, c.g, c.b) end
end

-- one seat from above (layers: step shadow, fill, outline; then the dummy or the junk;
-- the number; the stipple), into the cell rect r
function ZeD_SeatChooser:drawSeat(r, st, shift)
    local T = ZeD.T
    local on = r.on
    local x, y, w, h = r.x, r.y, r.w, r.h
    local function L(name) return art(name, w) end
    if st.kind == "none" then
        tinted(self, L("zs_seat_dash"), x, y, w, h, INK, 0.6)
    else
        local sh = math.max(1, math.floor(w * 2 / BOX_W))
        tinted(self, L("zs_seat_fill"), x + sh, y + sh, w, h, INK, 1)
        tinted(self, L("zs_seat_fill"), x, y, w, h, on and T.accent or PAPER, 1)
        tinted(self, L("zs_seat_line"), x, y, w, h, on and (T.accentBright or T.accent) or INK, 1)
    end
    if st.kind == "you" or st.kind == "person" then
        tinted(self, L("zs_dummy_fill"), x, y, w, h, st.kind == "you" and T.accent or OTHER, 1)
        tinted(self, L("zs_dummy_light"), x, y, w, h, PAPER, 1)
        tinted(self, L("zs_dummy_ink"), x, y, w, h, INK, 1)
    elseif st.kind == "items" then
        tinted(self, L("zs_junk_fill"), x, y, w, h, on and (T.accentBright or T.accent) or JUNK, 1)
        tinted(self, L("zs_junk_ink"), x, y, w, h, on and (T.textOnAccent or PAPER) or INK, 1)
    elseif not shift then
        -- the number: the key that takes it, on the cushion
        local f = T.fontF1
        local s = tostring(st.n)
        local c = (st.kind == "none" and T.textDim) or (on and (T.textOnAccent or PAPER)) or INK
        local cy = y + math.floor(h * 20 / BOX_H)
        self:drawText(s, math.floor(x + (w - tw(f, s)) / 2), math.floor(cy - fh(f) / 2), c.r, c.g, c.b, c.a or 1, f)
    end
    if st.off then tinted(self, L("zs_seat_stip"), x, y, w, h, on and PAPER or INK, on and 0.5 or 0.38) end
end

-- a door: the context strip's cell with the exit icon (Shift: its number), the stepped shadow
function ZeD_SeatChooser:drawDoor(r, shift, glyph)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local on = r.on
    A.drawSteppedShadow(self, r.x, r.y, r.w, r.w, INK)
    local def = { iconTexture = (not shift) and tex("media/textures/ZeD/icons/exit.png") or nil, iconTintable = true, name = shift and tostring(r.d.n) or "" }
    local ctx = T.ctx
    local cw, ch, ip = ctx.cellW, ctx.cellH, ctx.iconPx
    ctx.cellW, ctx.cellH, ctx.iconPx = r.w, r.w, T.px(on and U.DOOR_ICON_ON or U.DOOR_ICON)
    pcall(M.drawContextCell, self, r.x, r.y, def, { isActive = on }, T)
    ctx.cellW, ctx.cellH, ctx.iconPx = cw, ch, ip
    if not on then self:drawRectBorder(r.x, r.y, r.w, r.w, 1, INK.r, INK.g, INK.b) end
    -- a door you have not pointed sits back a little (vanilla's are faint until pointed)
    if not on and not shift and not glyph then
        local b = T.surf1
        self:drawRect(r.x, r.y, r.w, r.w, 0.25, b.r, b.g, b.b)
    end
    if glyph then
        -- the controller's X sits on the focused seat's door
        local gs = T.px(12)
        local gx, gy = r.x + r.w - math.floor(gs / 2), r.y + r.w - math.floor(gs / 2)
        self:drawRect(gx, gy, gs, gs, 1, 0.24, 0.48, 0.85)
        local f = T.fontF5
        self:drawText("X", gx + math.floor((gs - tw(f, "X")) / 2), gy + math.floor((gs - fh(f)) / 2), 0.05, 0.05, 0.05, 1, f)
    end
end

function ZeD_SeatChooser:prerender()
    local T = ZeD.T
    if not (self.vehicle and T) then return end
    self.minimumWidth, self.minimumHeight = 0, 0
    local okS, errS = pcall(self.readSeats, self)
    if not okS then ZeD.logOnce("seat chooser", errS); self:close(); return end
    self.title = (self._playerSeat ~= -1) and getText("IGUI_SwitchSeat") or getText("IGUI_EnterVehicle")
    self.titleStats = { { text = vehicleName(self.vehicle) } }
    self:layout()
    ZeD_Window.prerender(self)
    self.minimumWidth, self.minimumHeight = 0, 0
    local g = self._g
    local A, M = ZeD.Atoms, ZeD.Molecules
    local w = self.width
    local tc = T.text
    local shift = (not self.joyfocus) and (isKeyDown(Keyboard.KEY_LSHIFT) or isKeyDown(Keyboard.KEY_RSHIFT))

    -- the band: the pointed seat (or door) and why not; with nothing pointed, your own seat
    local s2 = T.surf2
    self:drawRect(T.px(1), g.band.y, w - T.px(2), g.band.h, 1, T.surf1.r, T.surf1.g, T.surf1.b)
    A.drawDividerH(self, T.px(1), g.band.y + g.band.h - T.px(1), w - T.px(2), false)
    local name, why, dot
    local pd = (not self.joyfocus) and self._hover and self._hover.door
    local ps = self:pointedSeat()
    if pd then
        name = getText("IGUI_ExitVehicle")
        why, dot = ZeD.tr("UI_ZeD_Seat_ByDoor", seatName(self._script, pd - 1)), "accent"
    elseif ps and self._seats[ps] then
        name = seatName(self._script, ps - 1)
        why, dot = self:reason(self._seats[ps])
    elseif self._playerSeat ~= -1 then
        name = seatName(self._script, self._playerSeat)
        why, dot = getText("IGUI_VehicleSeat_Self"), "accent"
    end
    local bx = T.px(U.BAND_PAD)
    local f4, f2 = T.fontF4, T.fontF2
    local ny = g.band.y + T.px(6)
    if name then
        self:drawText(A.truncateText(name, f4, w - bx * 2), bx, ny, T.textHead.r, T.textHead.g, T.textHead.b, T.textHead.a or 1, f4)
    end
    if why then
        local dsz = T.px(7)
        local ry = g.band.y + g.band.h - T.px(7) - fh(f2)
        local dc = (dot == "danger" and T.danger) or (dot == "warning" and (T.warning or T.danger)) or T.accent
        A.drawStatusDot(self, bx, ry + math.floor((fh(f2) - dsz) / 2), dc, dsz)
        self:drawText(A.truncateText(why, f2, w - bx * 2 - dsz - T.px(7)), bx + dsz + T.px(7), ry, tc.r, tc.g, tc.b, tc.a or 1, f2)
    end

    -- the car, then the doors, then the seats (the pointed seat last, over its neighbours)
    if g.car then
        if g.car.tex then
            self:drawTextureScaledAspect(g.car.tex, g.car.x, g.car.y, g.car.w, g.car.h, g.car.lines and 0.6 or 0.55, tc.r, tc.g, tc.b)
        else
            self:drawRectBorder(g.car.x, g.car.y, g.car.w, g.car.h, 0.55, tc.r, tc.g, tc.b)
        end
    end
    for n, r in pairs(g.doors) do self:drawDoor(r, shift, self.joyfocus and n == self.joypadSeat) end
    local last
    for n, r in pairs(g.seats) do
        if r.on then last = r else self:drawSeat(r, r.st, shift) end
    end
    if last then self:drawSeat(last, last.st, shift) end

    -- footer: the action zone
    local f = g.foot
    self:drawRect(T.px(1), f.y, w - T.px(2), f.h, s2.a or 1, s2.r, s2.g, s2.b)
    A.drawDividerH(self, T.px(1), f.y, w - T.px(2), false)
    local c = g.cancel
    local ac = T.accent
    local colors = (self._hover and self._hover.cancel) and { fill = { r = ac.r, g = ac.g, b = ac.b, a = 0.22 } } or nil
    M.drawButton(self, c.x, c.y, c.w, c.h, c.label, "default", self._down == "cancel", colors)
    -- the strip: the keys or the buttons that work here
    local st = g.strip
    self:drawRect(T.px(1), st.y, w - T.px(2), st.h, s2.a or 1, s2.r, s2.g, s2.b)
    A.drawDividerH(self, T.px(1), st.y, w - T.px(2), false)
    M.drawGlyphPrompts(self, T.sp.sm, st.y, st.h, self:stripPrompts())
end

function ZeD_SeatChooser:stripPrompts()
    local inside = self._playerSeat ~= -1
    if self.joyfocus then
        local t = { ZeD.tr("UI_ZeD_Seat_DpadMove"), { glyph = "A", label = ZeD.tr("UI_ZeD_Seat_Sit") } }
        if inside then t[#t + 1] = { glyph = "X", label = ZeD.tr("UI_ZeD_Seat_GetOutHere") } end
        t[#t + 1] = { glyph = "B", label = getText("UI_Cancel") }
        return t
    end
    local n = #(self._seats or {})
    local t = { { glyph = (n > 1) and ("1-" .. n) or "1", label = ZeD.tr("UI_ZeD_Seat_Sit") } }
    if inside then t[#t + 1] = { glyph = "SHIFT", label = ZeD.tr("UI_ZeD_Seat_NumberGetOut") } end
    t[#t + 1] = { glyph = "ESC", label = getText("UI_Cancel") }
    return t
end

function ZeD_SeatChooser:render()
    ZeD_Window.render(self)
end

-- ---------------------------------------------------------------------------
-- MOUSE (top-level: hit-tested here)
-- ---------------------------------------------------------------------------
function ZeD_SeatChooser:hitAt(x, y)
    local g = self._g
    if not g then return nil end
    if inRect(g.cancel, x, y) then return { cancel = true } end
    for n, r in pairs(g.doors) do if inRect(r.hit, x, y) then return { door = n } end end
    for n, r in pairs(g.seats) do if inRect(r.hit, x, y) then return { seat = n } end end
    return nil
end

function ZeD_SeatChooser:onMouseDown(x, y)
    if not self:getIsVisible() then return true end
    local cb = self:closeRect()
    if cb and inRect(cb, x, y) then self._down = "close"; return true end
    local h = self:hitAt(x, y)
    if h and h.cancel then self._down = "cancel"; return true end
    -- vanilla acts on the press
    if h and h.seat then self:useSeat(h.seat - 1); return true end
    if h and h.door then self:exitSeat(h.door - 1); return true end
    return true
end

function ZeD_SeatChooser:onMouseUp(x, y)
    local down = self._down
    self._down = nil
    if down == "close" then
        local cb = self:closeRect()
        if cb and inRect(cb, x, y) then sound("UIActivateButton"); self:close() end
    elseif down == "cancel" then
        local h = self:hitAt(x, y)
        if h and h.cancel then sound("UIActivateButton"); self:close() end
    end
    return true
end

function ZeD_SeatChooser:onMouseUpOutside(x, y) self._down = nil end

-- vanilla: a click elsewhere closes it (the first player's)
function ZeD_SeatChooser:onMouseDownOutside(x, y)
    if self.playerNum == 0 then self:close() end
end

function ZeD_SeatChooser:update()
    ISPanel.update(self)
    -- the car gone from the world or the character dead: it closes, rather than reading a
    -- vanished vehicle every frame (code audit Oct 17 2026)
    if not (self.vehicle and self.vehicle:getSquare()) or self.character:isDead() then self:close(); return end
    -- the controller that holds it
    local jf = nil
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    if jd and jd.focus == self then jf = jd end
    if S.qaJoy then jf = S.qaJoy end   -- QA: the controller look without a controller
    self.joyfocus = jf
    local h = self:hitAt(self:getMouseX(), self:getMouseY())
    if S.qaPoint then h = S.qaPoint end
    self._hover = h
    local cb = self:closeRect()
    self._closeHover = cb and inRect(cb, self:getMouseX(), self:getMouseY()) or false
    -- vanilla: walking away closes it
    if self.vehicle and self.character:DistTo(self.vehicle:getX(), self.vehicle:getY()) > 6 then self:close() end
end

-- ---------------------------------------------------------------------------
-- KEYS (vanilla's: the seat key and Escape close; 1..n sit, Shift + n get out)
-- ---------------------------------------------------------------------------
function ZeD_SeatChooser:isKeyConsumed(key)
    if getCore():isKey(KeybindId.VEHICLE_HORN, key) then return false end   -- the horn must hear its release
    return true
end

function ZeD_SeatChooser:onKeyPress(key)
    if getCore():isKey(KeybindId.VEHICLE_SWITCH_SEAT, key) then self:close(); return end
    if key == Keyboard.KEY_ESCAPE then
        self:close()
        GameKeyboard.eatKeyPress(key)
    end
end

function ZeD_SeatChooser:onKeyRelease(key)
    local v = self.vehicle
    if not (v and v:getScript()) then return end
    local num = v:getMaxPassengers()
    if key >= Keyboard.KEY_1 and key < Keyboard.KEY_1 + num then
        if isKeyDown(Keyboard.KEY_LSHIFT) or isKeyDown(Keyboard.KEY_RSHIFT) then self:exitSeat(key - Keyboard.KEY_1)
        else self:useSeat(key - Keyboard.KEY_1) end
    end
end

-- ---------------------------------------------------------------------------
-- CONTROLLER (vanilla's seat grid: two columns, up / down by a row)
-- ---------------------------------------------------------------------------
function ZeD_SeatChooser:onGainJoypadFocus(joypadData) self.joyfocus = joypadData end
function ZeD_SeatChooser:onLoseJoypadFocus(joypadData) self.joyfocus = nil end

-- the D-pad arrives as onJoypadDir* (and as onJoypadDown too): only the Dir path moves
function ZeD_SeatChooser:onJoypadDown(button, joypadData)
    if button == Joypad.AButton then self:useSeat(self.joypadSeat - 1)
    elseif button == Joypad.XButton then self:exitSeat(self.joypadSeat - 1)
    elseif button == Joypad.BButton then self:close() end
end

local function count(self) local sc = self.vehicle and self.vehicle:getScript(); return sc and sc:getPassengerCount() or 0 end
function ZeD_SeatChooser:onJoypadDirUp() if self.joypadSeat > 2 then self.joypadSeat = self.joypadSeat - 2; sound("UISelectListItem") end end
function ZeD_SeatChooser:onJoypadDirDown() if self.joypadSeat <= count(self) - 2 then self.joypadSeat = self.joypadSeat + 2; sound("UISelectListItem") end end
function ZeD_SeatChooser:onJoypadDirLeft() if self.joypadSeat % 2 == 0 then self.joypadSeat = self.joypadSeat - 1; sound("UISelectListItem") end end
function ZeD_SeatChooser:onJoypadDirRight()
    if self.joypadSeat % 2 == 1 and self.joypadSeat < count(self) then self.joypadSeat = self.joypadSeat + 1; sound("UISelectListItem") end
end

-- ---------------------------------------------------------------------------
-- ENTRY (vanilla's ISVehicleMenu.onShowSeatUI, as a toggle per player)
-- ---------------------------------------------------------------------------
function S.toggle(playerObj, vehicle)
    local speed = UIManager.getSpeedControls()
    if speed and speed:getCurrentGameSpeed() == 0 then return end   -- vanilla: not while paused
    local pn = playerObj:getPlayerNum()
    local win = S.windows[pn]
    if not win or win.character ~= playerObj then
        win = ZeD_SeatChooser:new(playerObj)
        win:initialise()
        win:instantiate()
        S.windows[pn] = win
    end
    if win:isReallyVisible() then
        win:close()
        return
    end
    win:setVehicle(vehicle)
    win:setVisible(true)
    win:addToUIManager()
    win:setAlwaysOnTop(true)
    if JoypadState.players[pn + 1] then
        JoypadState.players[pn + 1].focus = win
        updateJoypadFocus(JoypadState.players[pn + 1])
    end
end

-- Escape from anywhere (the prompts' key hook asks): the chooser on screen closes
function S.takeEscape()
    for _, win in pairs(S.windows) do
        if win and win:isReallyVisible() then win:close(); return true end
    end
    return false
end

function S.get(pn) return S.windows[pn or 0] end
