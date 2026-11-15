-- ZeD-UI/42/media/lua/client/ZeD/ZeD_SeatPopout.lua
-- ============================================================================
-- THE SEAT PICKER AS A POP-OUT (client; organism, an ISPanel subclass).
-- Nov 15 2026, seat pop-out (ZeDUI/HANDOFF_design_popouts_20261115.md, section 2).
--
-- In the Immersive style (ZeD setup's Dashboard row) the seat picker is the car's
-- cabin alone, with no window frame: the pixel-art floor, the car's own mini
-- dashboard, the seats in its interior color, the console, the people, the
-- things on the seats and the wheel (art baked by ZeDUI/tools/seats/
-- bake_seat_popout.py into media/textures/ZeD/seats/popout/; every number
-- below is from its layout.json, in art pixels). It is drawn at a whole number
-- of screen px per art px, nearest filtering: max(1, floor(T.px(2) + 0.5)).
-- Under it the strip: the seat's name, its status square and vanilla's reason,
-- then the controller's prompts or, with the mouse, the keys' help line.
-- Keycaps on the seats, the pointing hand outside the cabin at the focused
-- seat's side, the get-out cells beside the cabin at the doors (the rear door's
-- under it). The Simple style keeps the window (ZeD_SeatChooser.lua).
--
-- Every rule and action is vanilla's and is the window's own code, borrowed
-- here unchanged: readSeats (canSwitchSeat, moveItemsFromSeat, isExitBlocked),
-- reason, useSeat / exitSeat (onSwitchSeat, onEnter, onExit), the keys and the
-- controller's seat grid. Only the drawing and the place differ: it opens beside
-- the car on the player's side, never over the player, and stays there (vanilla
-- re-centers its window every frame); a drag moves it and the place is kept on
-- the character (modData ZeD_SeatPopout, design units; the face pop-outs keep
-- theirs apart). It closes with B, Escape, the seat key again, walking away
-- or taking a seat.
--
-- Rows: the seats grouped by vanilla's "inside" position offsets (z), the front
-- row first; left and right by x. The front row is two buckets with the console
-- between, except the pickups' front bench (the dashboards with the BED key,
-- bulldriver and d6); every row behind is a bench (a half bench and a dashed
-- outline when one place is not fitted); a row of one seat draws that side
-- only. A car this cannot draw (a row of three, more than five rows, a seat
-- with no inside position) gets the window instead.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/ZeD_SeatChooser"
require "ZeD/ZeD_PadGlyphs"
require "ZeD/ZeD_FocusPaint"
ZeD.trDefaults({
    UI_ZeD_Seat_KeysSit = "%1 Sit", UI_ZeD_Seat_KeysOut = "Shift+%1 Get out there", UI_ZeD_Seat_KeysClose = "Esc Close",
    UI_ZeD_Seat_FreeSit = "Free. Press %1 to sit here.", UI_ZeD_Seat_FreeSlide = "Free. Press %1 to slide over.",
})

ZeD = ZeD or {}
ZeD.Seats = ZeD.Seats or {}
local S = ZeD.Seats
S.popouts = S.popouts or {}

-- the cabin, in art pixels (layout.json)
local BW, LX, TOP, ROW, SEAT_W, SEAT_H, GAP = 112, 6, 27, 52, 46, 42, 8
local HALF_W = SEAT_W + GAP / 2                          -- a bench's place (50)
local BOX_H = { 85, 137, 189, 241, 293 }                 -- the floor for 1 .. 5 rows
local CELL = 13                                          -- a get-out cell
local HAND_W = 16                                        -- the pointing hand (ZeD_FocusPaint)
local ROW_TOL = 0.25                                     -- seats this close in z (m) share a row
-- design units
local KEY_W, KEY_H, KEY_R = 26, 24, 6                    -- the keycap atom, bigger than the window's
local STRIP_PAD, STRIP_GAP = 10, 3

local ART = "media/textures/ZeD/seats/popout/"
local INK   = { r = 0.08, g = 0.08, b = 0.08 }
local PAPER = { r = 0.95, g = 0.95, b = 0.95 }
local KEY_FILL, KEY_LINE, KEY_DIM = { r = 0.11, g = 0.11, b = 0.12 }, { r = 0.78, g = 0.78, b = 0.78 }, { r = 0.42, g = 0.42, b = 0.42 }
local OUTLINE = { r = 0.80, g = 0.80, b = 0.80 }        -- the dashed place of a seat not fitted

-- the mini dashboards baked (layout.json "dashes"): design__cabin
local DASHES = {}
for _, n in ipairs({ "wagon__v_walnut", "wagon__v_navy70", "wagon__v_army", "cossette__l_brown", "cossette__l_red",
        "cossette__l_black", "luxury__l_brown", "luxury__l_red", "luxury__l_black", "dashelite__v_beige_d", "dashelite__v_grey",
        "dashelite__v_black", "primani__v_beige_d", "primani__v_grey", "primani__v_black", "suv__v_beige_d", "suv__v_grey",
        "suv__v_black", "nyala__v_moss", "nyala__v_ltbrown", "nyala__v_navy70", "d6__v_moss", "d6__v_ltbrown", "d6__v_navy70",
        "bulldriver__v_moss", "bulldriver__v_ltbrown", "bulldriver__v_navy70", "rancher__v_moss", "rancher__v_ltbrown",
        "rancher__v_navy70", "horizon__v_maroon", "horizon__v_navy", "horizon__v_beige_d", "dart__v_maroon", "dart__v_navy",
        "dart__v_beige_d", "van__v_maroon", "van__v_navy", "van__v_beige_d", "police__v_black", "taxi__v_black",
        "ambulance__v_black", "fire__v_black", "ranger__v_black" }) do
    DASHES[n] = true
    local d, c = n:match("^(.-)__(.+)$")
    if d and not DASHES[d] then DASHES[d] = c end        -- (a design's first color: its own when the car names none)
end
local FRONT_BENCH = { bulldriver = true, d6 = true }     -- the pickups: the dashboards with the BED key

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------
local function fh(font) return ZeD.TM:getFontHeight(font) end
local function tw(font, s) return ZeD.TM:MeasureStringX(font, s) end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(name) pcall(function() ZeD.uiSound(name or "UIActivateButton") end) end

local _tex = {}
local function tex(name)
    local path = ART .. name .. ".png"
    local t = _tex[path]
    if t == nil then t = (Texture and Texture.getSharedTexture(path, 3)) or false; _tex[path] = t end   -- 3 = nearest
    return t or nil
end

--- The art pixel in screen px (the handoff: 4 at 4K at 1.75, 2 at 1080p at 1.0).
function S.popK() return math.max(1, math.floor(ZeD.T.px(2) + 0.5)) end

--- The pop-out style: true unless ZeD setup's Dashboard row is on Simple (the Simple style keeps the window).
function S.immersive()
    local St = ZeD.Settings
    return not (St and St.dashSimple and St.dashSimple())
end

-- the car's design and interior color: ZeD_Dashboard's own pick (its _designFor and _cabinOf, Nov 12 interior
-- colors); van__v_navy when the pick has no mini dashboard
function S.cabinPick(vehicle)
    local design, cabin
    pcall(function()
        local D = ZeD.Dashboard
        local des, id = D._designFor(vehicle:getScriptName())
        if des and id then
            design = id
            local cab = D._cabinOf(vehicle, des, id)
            cabin = cab and cab.id or nil
        end
    end)
    if design and not cabin and type(DASHES[design]) == "string" then cabin = DASHES[design] end
    if not (design and cabin and DASHES[design .. "__" .. cabin] == true) then design, cabin = "van", "v_navy" end
    return design, cabin
end

-- one rounded rect at radius rad (px), its corner stepped on the hairline grid
local function roundFill(p, x, y, w, h, rad, c)
    local u = ZeD.T.hair
    local n = math.max(1, math.floor(rad / u + 0.5))
    rad = n * u
    for i = 0, n - 1 do
        local dy = rad - (i + 0.5) * u
        local ins = math.floor(rad - math.sqrt(math.max(0, rad * rad - dy * dy)) + 0.5)
        p:drawRect(x + ins, y + i * u, w - 2 * ins, u, 1, c.r, c.g, c.b)
        p:drawRect(x + ins, y + h - (i + 1) * u, w - 2 * ins, u, 1, c.r, c.g, c.b)
    end
    if h - 2 * rad > 0 then p:drawRect(x, y + rad, w, h - 2 * rad, 1, c.r, c.g, c.b) end
end

-- a dashed outline (3 art px on, 2 off) around a rect
local function dashed(p, x, y, w, h, k, c)
    local t = ZeD.T.hair
    local on, step = 3 * k, 5 * k
    for d = 0, w - 1, step do
        local l = math.min(on, w - d)
        p:drawRect(x + d, y, l, t, 0.8, c.r, c.g, c.b)
        p:drawRect(x + d, y + h - t, l, t, 0.8, c.r, c.g, c.b)
    end
    for d = 0, h - 1, step do
        local l = math.min(on, h - d)
        p:drawRect(x, y + d, t, l, 0.8, c.r, c.g, c.b)
        p:drawRect(x + w - t, y + d, t, l, 0.8, c.r, c.g, c.b)
    end
end

-- ---------------------------------------------------------------------------
-- ZeD_SeatPopout
-- ---------------------------------------------------------------------------
ZeD_SeatPopout = ISPanel:derive("ZeD_SeatPopout")

function ZeD_SeatPopout:new(character)
    local o = ISPanel:new(0, 0, 10, 10)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.moveWithMouse = false
    o.character = character
    o.playerNum = character:getPlayerNum()
    o._zedLabel = "SeatPopout"   -- the name the focus manager and safe mode call this panel by
    o.vehicle = nil
    o.joypadSeat = 1
    o._hover = nil
    o:setWantKeyEvents(true)
    return o
end

-- vanilla's rules and actions: the window's own, unchanged (ZeD_SeatChooser.lua)
ZeD_SeatPopout.setVehicle  = ZeD_SeatChooser.setVehicle
ZeD_SeatPopout.readSeats   = ZeD_SeatChooser.readSeats
ZeD_SeatPopout.reason      = ZeD_SeatChooser.reason
ZeD_SeatPopout.useSeat     = ZeD_SeatChooser.useSeat
ZeD_SeatPopout.exitSeat    = ZeD_SeatChooser.exitSeat
ZeD_SeatPopout.isKeyConsumed = ZeD_SeatChooser.isKeyConsumed
ZeD_SeatPopout.onKeyPress    = ZeD_SeatChooser.onKeyPress
ZeD_SeatPopout.onKeyRelease  = ZeD_SeatChooser.onKeyRelease
ZeD_SeatPopout.onJoypadDown  = ZeD_SeatChooser.onJoypadDown
ZeD_SeatPopout.onJoypadDirUp    = ZeD_SeatChooser.onJoypadDirUp
ZeD_SeatPopout.onJoypadDirDown  = ZeD_SeatChooser.onJoypadDirDown
ZeD_SeatPopout.onJoypadDirLeft  = ZeD_SeatChooser.onJoypadDirLeft
ZeD_SeatPopout.onJoypadDirRight = ZeD_SeatChooser.onJoypadDirRight

function ZeD_SeatPopout:onGainJoypadFocus(joypadData) self.joyfocus = joypadData end
function ZeD_SeatPopout:onLoseJoypadFocus(joypadData) self.joyfocus = nil end

function ZeD_SeatPopout:close()
    self._drag = nil
    self:setVisible(false)
    self:removeFromUIManager()
    if JoypadState.players[self.playerNum + 1] then setJoypadFocus(self.playerNum, nil) end
end

-- ---------------------------------------------------------------------------
-- THE PLAN: rows and places from vanilla's inside offsets; nil when this car can't be drawn
-- ---------------------------------------------------------------------------
local function byFront(a, b)
    if a.oz ~= b.oz then return a.oz > b.oz end
    return a.n < b.n
end

function ZeD_SeatPopout:plan()
    local seats = self._seats
    if not seats or #seats == 0 then return nil end
    local list = {}
    for _, st in ipairs(seats) do
        if st.oz == nil then return nil end
        list[#list + 1] = st
    end
    table.sort(list, byFront)
    local rows = {}
    for _, st in ipairs(list) do
        local r = rows[#rows]
        if not r or math.abs(r.z - st.oz) > ROW_TOL then
            r = { z = st.oz, seats = {} }
            rows[#rows + 1] = r
        end
        r.seats[#r.seats + 1] = st
    end
    if #rows > #BOX_H then return nil end
    local places = {}
    for ri, r in ipairs(rows) do
        local s = r.seats
        if #s > 2 then return nil end
        -- (screen left is the car's +x, as vanilla draws it: the driver on the left)
        if #s == 2 then
            local a, b = s[1], s[2]
            if -a.ox > -b.ox then a, b = b, a end
            r.l, r.r = a, b
        elseif -s[1].ox > 0.05 then r.r = s[1]
        else r.l = s[1] end
        r.y = TOP + (ri - 1) * ROW
        r.bench = ri > 1 or (FRONT_BENCH[self._design] == true and r.l ~= nil and r.r ~= nil)
        if r.l then places[r.l.n] = { row = r, side = "l", x = LX, y = r.y } end
        if r.r then places[r.r.n] = { row = r, side = "r", x = LX + SEAT_W + GAP, y = r.y } end
    end
    -- each place's own rect (its keycap and its hit): the bucket, or its half of the bench
    for _, pl in pairs(places) do
        if pl.row.bench then
            pl.rx, pl.rw = (pl.side == "l") and LX or (LX + HALF_W), HALF_W
        else
            pl.rx, pl.rw = pl.x, SEAT_W
        end
    end
    -- the get-out cells: beside the row of each seat you could leave by, the rear door's under the cabin. Two seats
    -- leaving by one place share its cell: your own seat's, else the first.
    local cells, taken = {}, {}
    local own = self._playerSeat
    for n, d in pairs(self._doors or {}) do
        local pl = places[n]
        if pl and d.ox then
            local st = seats[n]
            local key, side
            if d.oz < st.oz - 0.6 and math.abs(d.ox) < math.abs(d.oz - st.oz) then
                side, key = "rear", "rear"   -- (one rear door: its cell centred under the cabin)
            else
                if d.ox > 0.05 then side = "l" elseif d.ox < -0.05 then side = "r" else side = pl.side end
                key = side .. pl.row.y
            end
            local prev = taken[key]
            if not prev or (n - 1 == own) or (prev.i ~= own and n < prev.n) then
                if prev then cells[prev.n] = nil end
                local c = { n = n, i = n - 1, side = side, place = pl }
                cells[n], taken[key] = c, c
            end
        end
    end
    return { rows = rows, places = places, cells = cells, nRows = #rows, rear = taken.rear ~= nil }
end

-- ---------------------------------------------------------------------------
-- PLACE: beside the car on the player's side, worked out once as it opens; a drag's place is kept on the character
-- ---------------------------------------------------------------------------
function ZeD_SeatPopout:autoAnchor(w)
    local T = ZeD.T
    local pn, v, chr = self.playerNum, self.vehicle, self.character
    local vx, vy, vz = v:getX(), v:getY(), v:getZ()
    local r = 2
    pcall(function() local e = v:getScript():getExtents(); r = math.max(e:x(), e:z()) / 2 end)
    local minX, maxX = nil, nil
    for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
        local sx = isoToScreenX(pn, vx + c[1] * r, vy + c[2] * r, vz)
        minX = minX and math.min(minX, sx) or sx
        maxX = maxX and math.max(maxX, sx) or sx
    end
    local cx, cy = isoToScreenX(pn, vx, vy, vz), isoToScreenY(pn, vx, vy, vz)
    local px = isoToScreenX(pn, chr:getX(), chr:getY(), chr:getZ())
    local body, gap = T.px(40), T.px(24)                 -- (the player's half width on screen, and the room left)
    local rightEdge = math.max(maxX, px + body) + gap
    local leftEdge = math.min(minX, px - body) - gap
    local sl, sw = getPlayerScreenLeft(pn), getPlayerScreenWidth(pn)
    local right
    if chr:getVehicle() == v then right = (sl + sw - rightEdge) >= (leftEdge - sl)   -- inside: the side with more room
    else right = px >= cx end
    if right and rightEdge + w > sl + sw and leftEdge - w >= sl then right = false
    elseif not right and leftEdge - w < sl and rightEdge + w <= sl + sw then right = true end
    return { right = right, edge = right and rightEdge or leftEdge, cy = cy }
end

function ZeD_SeatPopout:place(w, h)
    local T = ZeD.T
    local sc = (T and T.scale) or 1
    local x, y
    if self._drag then
        x, y = self._drag.nx, self._drag.ny
    else
        local saved = self.character:getModData().ZeD_SeatPopout
        if saved and saved.x then
            x, y = saved.x * sc, saved.y * sc
        else
            if not self._anchor then
                local ok, a = pcall(self.autoAnchor, self, w)
                self._anchor = ok and a or { right = true, edge = getPlayerScreenLeft(self.playerNum) + math.floor(getPlayerScreenWidth(self.playerNum) * 0.6),
                                            cy = getPlayerScreenTop(self.playerNum) + math.floor(getPlayerScreenHeight(self.playerNum) / 2) }
            end
            local a = self._anchor
            x = a.right and a.edge or (a.edge - w)
            y = a.cy - math.floor(h / 2)
        end
    end
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    x = math.max(0, math.min(x, sw - w)); y = math.max(0, math.min(y, sh - h))
    x, y = math.floor(x + 0.5), math.floor(y + 0.5)
    if self.width ~= w then self:setWidth(w) end
    if self.height ~= h then self:setHeight(h) end
    if self.x ~= x then self:setX(x) end
    if self.y ~= y then self:setY(y) end
end

-- ---------------------------------------------------------------------------
-- THE STRIP'S WORDS
-- ---------------------------------------------------------------------------
-- the seat the strip, the accent keycap and the hand are on: the controller's, the one under the pointer, else the
-- controller's start (your own seat, or seat 1) so the strip always names one
function ZeD_SeatPopout:pointedSeat()
    if self.joyfocus then return self.joypadSeat end
    local h = self._hover
    if h and h.seat then return h.seat end
    if h and h.door then return nil end
    return self.joypadSeat
end

function ZeD_SeatPopout:words()
    local name, why, dot
    local pd = (not self.joyfocus) and self._hover and self._hover.door
    local ps = self:pointedSeat()
    local script = self._script
    local function seatName(i)
        local id = "Seat"
        pcall(function() id = "Seat" .. script:getPassenger(i):getId() end)
        return getTextOrNull("IGUI_" .. id) and getText("IGUI_" .. id) or id
    end
    if pd then
        name = getText("IGUI_ExitVehicle")
        why, dot = ZeD.tr("UI_ZeD_Seat_ByDoor", seatName(pd - 1)), "accent"
    elseif ps and self._seats[ps] then
        local st = self._seats[ps]
        name = seatName(ps - 1)
        why, dot = self:reason(st)
        if not why and st.kind == "empty" and not st.off then
            -- (a free seat: the mockup's line, the key that takes it)
            local PG = ZeD.PadGlyphs
            local key = self.joyfocus and ((PG and PG.name and PG.name("A", PG.set and PG.set(self.playerNum))) or "A") or tostring(ps)
            why = ZeD.tr((self._playerSeat ~= -1) and "UI_ZeD_Seat_FreeSlide" or "UI_ZeD_Seat_FreeSit", key)
            dot = "ok"
        end
    end
    return name, why, dot
end

-- the controller's prompts (the window's getFooterPrompts, B labelled Close as the radio's strip is)
function ZeD_SeatPopout:padPrompts()
    local P = ZeD.Prompt
    local move = ZeD.tr("UI_ZeD_Seat_DpadMove")
    local t = { P and P.padNote and P.padNote(move) or move, { glyph = "A", label = ZeD.tr("UI_ZeD_Seat_Sit") } }
    if self._playerSeat ~= -1 then t[#t + 1] = { glyph = "X", label = ZeD.tr("UI_ZeD_Seat_GetOutHere") } end
    t[#t + 1] = { glyph = "B", label = ZeD.tr("UI_ZeD_Close") }
    return t
end

-- the mouse's help line: "1-n Sit   Shift+1-n Get out there   Esc Close" (Shift only while you are inside)
function ZeD_SeatPopout:helpLine()
    local n = self.vehicle:getMaxPassengers()
    local keys = (n > 1) and ("1-" .. n) or "1"
    local s = ZeD.tr("UI_ZeD_Seat_KeysSit", keys)
    if self._playerSeat ~= -1 then s = s .. "   " .. ZeD.tr("UI_ZeD_Seat_KeysOut", keys) end
    return s .. "   " .. ZeD.tr("UI_ZeD_Seat_KeysClose")
end

-- ---------------------------------------------------------------------------
-- LAYOUT (every frame; panel px in self._g)
-- ---------------------------------------------------------------------------
function ZeD_SeatPopout:layout(plan)
    local T = ZeD.T
    local k = S.popK()
    local g = { k = k, plan = plan }
    local cabW, cabH = BW * k, BOX_H[plan.nRows] * k
    local cell, gapIn, gapOut = CELL * k, 2 * k, 3 * k
    local sideW = gapIn + HAND_W * k + ((self._playerSeat ~= -1) and (gapOut + cell) or 0)
    -- the strip
    local f4, f2, f3 = T.fontF4, T.fontF2, T.fontF3
    local pad = T.px(STRIP_PAD)
    local name, why, dot = self:words()
    local prompts = self.joyfocus and self:padPrompts() or nil
    local help = (not prompts) and self:helpLine() or nil
    local need = math.max(name and (tw(f4, name) + pad * 2) or 0, why and (tw(f2, why) + T.px(13) + pad * 2) or 0,
        prompts and ZeD.PadGlyphs.stripW(prompts, self.playerNum) or (tw(f3, help) + pad * 2))
    local stripW = math.max(cabW, need)
    local rowH = ZeD.PadGlyphs.stripH()
    local stripH = T.px(6) + fh(f4) + T.px(2) + fh(f2) + T.px(6) + rowH
    local sh = T.hair
    local w = math.max(cabW + 2 * sideW, stripW) + sh
    local cabX = math.floor((w - sh - cabW) / 2)
    local cabY = 0
    local below = cabY + cabH + (plan.rear and (gapOut + cell) or 0)
    local stripY = below + T.px(STRIP_GAP)
    local h = stripY + stripH + sh
    g.cab = { x = cabX, y = cabY, w = cabW, h = cabH }
    g.strip = { x = math.floor((w - sh - stripW) / 2), y = stripY, w = stripW, h = stripH, rowH = rowH,
                name = name, why = why, dot = dot, prompts = prompts, help = help }
    -- the places' hits, the keycaps' centres and the cells (panel px)
    g.seats = {}
    for n, pl in pairs(plan.places) do
        local kx = cabX + math.floor((pl.x + SEAT_W / 2) * k)
        local ky = cabY + (pl.y + 12) * k
        g.seats[n] = { x = cabX + pl.rx * k, y = cabY + pl.y * k, w = pl.rw * k, h = SEAT_H * k, kx = kx, ky = ky, pl = pl }
    end
    g.cells = {}
    for n, c in pairs(plan.cells) do
        local s = g.seats[n]
        local cx, cy
        if c.side == "rear" then
            cx, cy = cabX + math.floor((cabW - cell) / 2), cabY + cabH + gapOut
        elseif c.side == "l" then
            cx, cy = cabX - sideW, s.ky - math.floor(cell / 2)
        else
            cx, cy = cabX + cabW + sideW - cell, s.ky - math.floor(cell / 2)
        end
        g.cells[n] = { x = cx, y = cy, w = cell, h = cell, c = c }
    end
    g.gapIn = gapIn
    self:place(w, h)
    self._g = g
end

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------
-- a part laid on in art px: its 1 px margin's corner at (ax - 1, ay - 1), as seat_cabin.lay does
local function lay(self, t, ax, ay)
    if not t then return end
    local g = self._g
    local k = g.k
    self:drawTextureScaled(t, g.cab.x + math.floor((ax - 1) * k), g.cab.y + math.floor((ay - 1) * k),
        t:getWidthOrig() * k, t:getHeightOrig() * k, 1, 1, 1, 1)
end

function ZeD_SeatPopout:drawCabin()
    local g, plan = self._g, self._g.plan
    local k, cab = g.k, self._cabin
    local seats = self._seats
    -- the floor (and its hard shadow, 1u right and down, on its own shape), then the dashboard
    local floor = tex("floor/" .. cab .. "_" .. plan.nRows)
    if floor then
        local sh = ZeD.T.hair
        self:drawTextureScaled(floor, g.cab.x + sh, g.cab.y + sh, g.cab.w, g.cab.h, 0.5, 0, 0, 0)
        self:drawTextureScaled(floor, g.cab.x, g.cab.y, g.cab.w, g.cab.h, 1, 1, 1, 1)
    end
    lay(self, tex("dash/" .. self._design .. "__" .. cab), 4, 4)
    -- the seats, row by row; the console between the front buckets
    local function fitted(st) return st and st.kind ~= "none" end
    for ri, r in ipairs(plan.rows) do
        local y = r.y
        if r.bench then
            if fitted(r.l) and fitted(r.r) then
                lay(self, tex("seat/" .. cab .. "_bench"), LX, y)
            else
                if fitted(r.l) then lay(self, tex("seat/" .. cab .. "_half"), LX, y) end
                if fitted(r.r) then lay(self, tex("seat/" .. cab .. "_half"), LX + SEAT_W + GAP - GAP / 2, y) end
            end
        else
            if fitted(r.l) then lay(self, tex("seat/" .. cab .. "_bucket"), LX, y) end
            if fitted(r.r) then lay(self, tex("seat/" .. cab .. "_bucket"), LX + SEAT_W + GAP, y) end
            if ri == 1 and r.l and r.r then lay(self, tex("console"), LX + SEAT_W + 1, y + 2) end
        end
    end
    -- the people, then the things (the bag, the box on it)
    for n, pl in pairs(plan.places) do
        local st = seats[n]
        if st.kind == "you" or st.kind == "person" then
            lay(self, tex(st.kind == "you" and "dummy_you" or "dummy_other"), pl.x + SEAT_W / 2 - 20, pl.y - 6)
        elseif st.kind == "items" then
            lay(self, tex("bag"), pl.x + 20, pl.y + 21)
            lay(self, tex("box"), pl.x + 6, pl.y + 18)
        end
    end
    -- a seat that can't be taken from here: the 50% stipple over it (bake_seat_stipple.py)
    for n, pl in pairs(plan.places) do
        local st = seats[n]
        if st.off and st.kind ~= "none" then
            local r = pl.row
            if not r.bench then lay(self, tex("stip_bucket"), pl.x, pl.y)
            elseif fitted(r.l) and fitted(r.r) then
                if pl.side == "l" then lay(self, tex("stip_bench_l"), LX, pl.y)
                else lay(self, tex("stip_bench_r"), LX + HALF_W + 1, pl.y) end
            else
                lay(self, tex("stip_half"), (pl.side == "l") and LX or (LX + SEAT_W + GAP - GAP / 2), pl.y)
            end
        end
    end
    -- the wheel, while the driver's seat is fitted, over the driver's knees
    local dpl = plan.places[1]
    if dpl and fitted(seats[1]) then lay(self, tex("wheel"), dpl.x + SEAT_W / 2 - 12.5, 3 + 12 - 2) end
    -- a seat not fitted: a dashed outline where it would be
    for n, s in pairs(g.seats) do
        if seats[n].kind == "none" then dashed(self, s.x, s.y, s.w, s.h, k, OUTLINE) end
    end
end

-- the keycap atom: 26 x 24u, radius 6u, its label in F4; the focused one in the accent; dim when the seat can't be
-- taken or is not fitted
function ZeD_SeatPopout:drawKeycap(cx, cy, label, on, dim)
    local T = ZeD.T
    local w, h, rad, hair = T.px(KEY_W), T.px(KEY_H), T.px(KEY_R), T.hair
    local x, y = cx - math.floor(w / 2), cy - math.floor(h / 2)
    local acc = T.accentBright or T.accent
    local line = (on and acc) or (dim and KEY_DIM) or KEY_LINE
    local fill = KEY_FILL
    if on then
        fill = { r = KEY_FILL.r * 0.7 + T.accent.r * 0.3, g = KEY_FILL.g * 0.7 + T.accent.g * 0.3, b = KEY_FILL.b * 0.7 + T.accent.b * 0.3 }
    end
    roundFill(self, x - hair, y - hair, w + 2 * hair, h + 2 * hair, rad + hair, INK)   -- the dark edge outside it
    roundFill(self, x, y, w, h, rad, line)
    roundFill(self, x + hair, y + hair, w - 2 * hair, h - 2 * hair, math.max(hair, rad - hair), fill)
    local f = T.fontF4
    local tc = (on and acc) or (dim and KEY_DIM) or PAPER
    self:drawText(label, cx - math.floor(tw(f, label) / 2), cy - math.floor(fh(f) / 2), tc.r, tc.g, tc.b, 1, f)
end

-- a get-out cell: the context strip's cell with the exit icon (Shift: the seat's number), its stepped shadow; the
-- focused one gets the accent double ring
function ZeD_SeatPopout:drawCell(r, on, shift)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    A.drawSteppedShadow(self, r.x, r.y, r.w, r.w, INK)
    local pic, px = ZeD.PxIcon.tex("car_exit", math.floor(r.w * 0.65))
    local def = { iconTexture = (not shift) and pic or nil, iconTintable = true, name = shift and tostring(r.c.n) or "" }
    local ctx = T.ctx
    local cw, ch, ip = ctx.cellW, ctx.cellH, ctx.iconPx
    ctx.cellW, ctx.cellH, ctx.iconPx = r.w, r.w, px
    pcall(M.drawContextCell, self, r.x, r.y, def, { isActive = false }, T)
    ctx.cellW, ctx.cellH, ctx.iconPx = cw, ch, ip
    A.frame(self, r.x, r.y, r.w, r.w, INK)
    if on then
        local hair, acc = T.hair, T.accentBright or T.accent
        A.frame(self, r.x - 2 * hair, r.y - 2 * hair, r.w + 4 * hair, r.w + 4 * hair, acc, 1, hair)
        A.frame(self, r.x - 4 * hair, r.y - 4 * hair, r.w + 8 * hair, r.w + 8 * hair, acc, 1, hair)
    end
end

function ZeD_SeatPopout:drawStrip()
    local T, A, PG = ZeD.T, ZeD.Atoms, ZeD.PadGlyphs
    local s = self._g.strip
    local hair = T.hair
    local s2 = T.surf2
    self:drawRect(s.x + hair, s.y + hair, s.w, s.h, 0.5, 0, 0, 0)                 -- System 7's hard shadow
    self:drawRect(s.x, s.y, s.w, s.h, 1, s2.r, s2.g, s2.b)
    local pad = T.px(STRIP_PAD)
    local f4, f2, f3 = T.fontF4, T.fontF2, T.fontF3
    local y = s.y + T.px(6)
    if s.name then
        local c = T.textHead or T.text
        self:drawText(A.truncateText(s.name, f4, s.w - pad * 2), s.x + pad, y, c.r, c.g, c.b, c.a or 1, f4)
    end
    y = y + fh(f4) + T.px(2)
    if s.why then
        local dsz = T.px(6)
        local dc = (s.dot == "danger" and T.danger) or (s.dot == "warning" and (T.warning or T.danger))
            or (s.dot == "ok" and (T.positive or T.accent)) or T.accent
        A.drawStatusDot(self, s.x + pad, y + math.floor((fh(f2) - dsz) / 2), dc, dsz)
        local tc = T.text
        self:drawText(A.truncateText(s.why, f2, s.w - pad * 2 - dsz - T.px(7)), s.x + pad + dsz + T.px(7), y, tc.r, tc.g, tc.b, tc.a or 1, f2)
    end
    local ry = s.y + s.h - s.rowH
    if s.prompts then
        PG.drawStrip(self, s.x, ry, s.w, s.prompts)
    else
        local bs, td = T.borderS, T.textDim
        self:drawRect(s.x, ry, s.w, hair, bs.a or 1, bs.r, bs.g, bs.b)
        self:drawText(s.help, s.x + pad, ry + math.floor((s.rowH - fh(f3)) / 2), td.r, td.g, td.b, td.a or 1, f3)
    end
end

function ZeD_SeatPopout:prerender()
    local T = ZeD.T
    if not (self.vehicle and T) then return end
    local okS, errS = pcall(self.readSeats, self)
    if not okS then ZeD.logOnce("seat pop-out", errS); self:close(); return end
    local plan = self:plan()
    if not plan then self:close(); return end
    self:layout(plan)
    local g = self._g
    self:drawCabin()
    local shift = (not self.joyfocus) and (isKeyDown(Keyboard.KEY_LSHIFT) or isKeyDown(Keyboard.KEY_RSHIFT))
    local ps = self:pointedSeat()
    -- the keycaps: free seats, seats with things, seats out of reach and seats not fitted (people have none)
    for n, s in pairs(g.seats) do
        local st = self._seats[n]
        if st.kind ~= "you" and st.kind ~= "person" then
            self:drawKeycap(s.kx, s.ky, tostring(n), n == ps, st.off or st.kind == "none")
        end
    end
    -- the pointing hand outside the cabin at the focused seat's side (mirrored on the right)
    local s = ps and g.seats[ps]
    if s and ZeD.Focus and ZeD.Focus.drawHandAt then
        local kh = ZeD.T.px(KEY_H)
        if s.pl.side == "l" then
            ZeD.Focus.drawHandAt(self, g.cab.x - g.gapIn, s.ky - math.floor(kh / 2), kh, g.k, false)
        else
            ZeD.Focus.drawHandAt(self, g.cab.x + g.cab.w + g.gapIn, s.ky - math.floor(kh / 2), kh, g.k, true)
        end
    end
    -- the get-out cells: the controller's on its seat's door, the mouse's under the pointer
    local hd = (not self.joyfocus) and self._hover and self._hover.door or nil
    for n, r in pairs(g.cells) do
        local on = (self.joyfocus and n == self.joypadSeat) or (hd == n)
        self:drawCell(r, on, shift)
    end
    self:drawStrip()
end

-- ---------------------------------------------------------------------------
-- MOUSE: a seat or a cell acts on the press (vanilla's); anything else drags the pop-out
-- ---------------------------------------------------------------------------
function ZeD_SeatPopout:hitAt(x, y)
    local g = self._g
    if not g then return nil end
    for n, r in pairs(g.cells) do if inRect(r, x, y) then return { door = n } end end
    for n, r in pairs(g.seats) do if inRect(r, x, y) then return { seat = n } end end
    return nil
end

function ZeD_SeatPopout:onMouseDown(x, y)
    if not self:getIsVisible() then return true end
    local h = self:hitAt(x, y)
    if h and h.seat then self:useSeat(h.seat - 1); return true end
    if h and h.door then self:exitSeat(h.door - 1); return true end
    self._drag = { mx = getMouseX(), my = getMouseY(), x = self:getX(), y = self:getY(), nx = self:getX(), ny = self:getY() }
    self:setCapture(true)
    return true
end

function ZeD_SeatPopout:onMouseMove(dx, dy)
    local d = self._drag
    if not d then return end
    d.nx = d.x + (getMouseX() - d.mx)
    d.ny = d.y + (getMouseY() - d.my)
end
function ZeD_SeatPopout:onMouseMoveOutside(dx, dy) self:onMouseMove(dx, dy) end

function ZeD_SeatPopout:onMouseUp(x, y)
    local d = self._drag
    if d then
        self._drag = nil
        self:setCapture(false)
        -- a real drag (2 px or more) keeps the new place on the character, in design units
        if math.abs(d.nx - d.x) + math.abs(d.ny - d.y) >= 2 then
            local sc = (ZeD.T and ZeD.T.scale) or 1
            self.character:getModData().ZeD_SeatPopout = { x = self:getX() / sc, y = self:getY() / sc }
        end
    end
    return true
end
function ZeD_SeatPopout:onMouseUpOutside(x, y)
    if self._drag then return self:onMouseUp(x, y) end
    return true
end

-- vanilla: a click elsewhere closes it (the first player's)
function ZeD_SeatPopout:onMouseDownOutside(x, y)
    if self._drag then return end
    if self.playerNum == 0 then self:close() end
end

function ZeD_SeatPopout:update()
    ISPanel.update(self)
    -- the car gone from the world or the character dead: it closes
    if not (self.vehicle and self.vehicle:getSquare()) or self.character:isDead() then self:close(); return end
    local jf = nil
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    if jd and jd.focus == self then jf = jd end
    if S.qaJoy then jf = S.qaJoy end   -- (for the test scripts: the controller look without a controller)
    self.joyfocus = jf
    local h = self:hitAt(self:getMouseX(), self:getMouseY())
    if S.qaPoint then h = S.qaPoint end
    self._hover = h
    -- vanilla: walking away closes it
    if self.character:DistTo(self.vehicle:getX(), self.vehicle:getY()) > 6 then self:close() end
end

-- ---------------------------------------------------------------------------
-- ENTRY (from S.toggle in ZeD_SeatChooser.lua while the Immersive style is on)
-- ---------------------------------------------------------------------------
--- Open the pop-out for a vehicle, or close it when it is up. False when this car can't be drawn as a cabin (the
--- caller opens the window instead).
function S.popToggle(playerObj, vehicle)
    local pn = playerObj:getPlayerNum()
    local p = S.popouts[pn]
    if p and p:isReallyVisible() then p:close(); return true end
    if not p or p.character ~= playerObj then
        p = ZeD_SeatPopout:new(playerObj)
        p:initialise()
        p:instantiate()
        S.popouts[pn] = p
    end
    p:setVehicle(vehicle)
    p._design, p._cabin = S.cabinPick(vehicle)
    p._anchor, p._drag, p._g = nil, nil, nil
    -- (a dry run: a car whose seats can't be laid out as rows, or the art not there, gets the window)
    local ok = pcall(p.readSeats, p)
    if not (ok and p:plan() and tex("floor/" .. p._cabin .. "_1")) then return false end
    p:setVisible(true)
    p:addToUIManager()
    p:setAlwaysOnTop(true)
    if JoypadState.players[pn + 1] then
        JoypadState.players[pn + 1].focus = p
        updateJoypadFocus(JoypadState.players[pn + 1])
    end
    return true
end

function S.getPopout(pn) return S.popouts[pn or 0] end
