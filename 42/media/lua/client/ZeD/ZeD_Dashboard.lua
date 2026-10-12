-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Dashboard.lua
-- ============================================================================
-- VEHICLE DASHBOARD (S123) — bottom-centre HUD strip, built from scratch.
--
-- Replaces ISVehicleDashboard (parked, never removed: Java still calls its
-- setVehicle through the vanilla event handlers, so we just keep it
-- invisible). One organism, one layout; the vehicle's paint (HSV) tints the
-- trim band and the family (normal / sport / utility / emergency / luxury)
-- changes emphasis only. Mockup: ZeDUI/mockups/zed_dashboard_v1.html.
-- HOOK_MAP.md #2.
--
-- Left: speed + gear, RPM / FUEL / BATT bars. Right: toggles with a status
-- dot, name and key hint. Actions reuse the vanilla ISVehicleMenu verbs so
-- behaviour (and MP commands) stay identical to vanilla.
--
-- Gamepad: the strip registers as a FocusManager window when the driver is
-- seated and no ZeD window owns focus. D-pad moves across the toggles, A
-- toggles, B releases focus back to driving (the strip stays visible).
-- ============================================================================

require "ZeD/ZeD_Panel"

ZeD = ZeD or {}
ZeD.Dashboard = ZeD.Dashboard or {}
local D = ZeD.Dashboard

local BASE_W, BASE_H = 560, 92
local CLUSTER_W      = 300
local TOGGLE_W, TOGGLE_H, TOGGLE_GAP = 58, 36, 4

-- ---------------------------------------------------------------------------
-- Colour helpers
-- ---------------------------------------------------------------------------
local function hsv2rgb(h, s, v)
    h = (h or 0) % 1; s = s or 0; v = v or 0
    local i = math.floor(h * 6); local f = h * 6 - i
    local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then return v, t, p elseif i == 1 then return q, v, p elseif i == 2 then return p, v, t
    elseif i == 3 then return p, q, v elseif i == 4 then return t, p, v else return v, p, q end
end

-- Family from the script name. Only trim + brand text differ.
local function _family(vehicle)
    local name = ""
    pcall(function() name = tostring(vehicle:getScriptName() or "") end)
    local n = name:lower()
    if n:find("police") or n:find("ambulance") or n:find("fire") or n:find("ranger") or n:find("lights") then return "emergency", name end
    if n:find("sport") or n:find("race") then return "sport", name end
    if n:find("luxury") or n:find("limo") then return "luxury", name end
    if n:find("pickup") or n:find("van") or n:find("truck") or n:find("suv") or n:find("trailer") then return "utility", name end
    return "normal", name
end

local function _prettyName(scriptName)
    local s = tostring(scriptName or ""):gsub("^Base%.", "")
    s = s:gsub("(%l)(%u)", "%1 %2"):gsub("_", " ")
    return s:upper()
end

-- Paint-derived trim colour. Low saturation paints (grey/white/black) get the
-- family's own colour so the trim never disappears into the chassis.
local function _trimColor(vehicle, family)
    local T = ZeD.T
    local h, s, v = 0, 0, 0
    pcall(function() h = vehicle:getColorHue(); s = vehicle:getColorSaturation(); v = vehicle:getColorValue() end)
    if s and s > 0.18 and v and v > 0.18 then
        local r, g, b = hsv2rgb(h, math.min(1, s * 1.3), math.max(0.45, v))
        return { r = r, g = g, b = b }
    end
    if family == "sport" then return T.danger end
    if family == "luxury" then return T.warning end
    if family == "utility" or family == "emergency" then return T.info end
    return T.accent
end

-- ---------------------------------------------------------------------------
-- State readout (per frame)
-- ---------------------------------------------------------------------------
local function _safe(fn, default)
    local ok, v = pcall(fn)
    if ok then return v end
    return default
end

local function _state(vehicle, chr)
    local st = {}
    st.running  = _safe(function() return vehicle:isEngineRunning() end, false)
    st.started  = _safe(function() return vehicle:isEngineStarted() end, false)
    st.keysIn   = _safe(function() return vehicle:isKeysInIgnition() end, false)
    st.hotwired = _safe(function() return vehicle:isHotwired() end, false)
    st.hasKey   = _safe(function() return chr:getInventory():haveThisKeyId(vehicle:getKeyId()) end, false)
    st.speed    = math.floor(math.abs(_safe(function() return vehicle:getCurrentSpeedKmHour() end, 0)) + 0.5)
    st.rpm      = st.running and _safe(function() return vehicle:getEngineSpeed() end, 0) or 0
    st.gear     = st.running and _safe(function() return tostring(vehicle:getTransmissionNumberLetter()) end, "D") or "P"
    local live  = st.running or st.keysIn
    st.fuel = nil
    local tank = _safe(function() return vehicle:getPartById("GasTank") end, nil)
    if live and tank and _safe(function() return tank:isContainer() end, false) then
        st.fuel = _safe(function() return tank:getContainerContentAmount() / math.max(1, tank:getContainerCapacity()) end, nil)
    end
    st.battery  = live and _safe(function() return vehicle:getBatteryCharge() end, nil) or nil
    st.engineCond = _safe(function() return vehicle:getPartById("Engine"):getCondition() end, 100)
    st.lightsOn = _safe(function() return vehicle:getHeadlightsOn() end, false)
    st.lightsOk = _safe(function() return vehicle:getHeadlightCanEmmitLight() end, true)
    st.allLocked = _safe(function() return vehicle:areAllDoorsLocked() end, false)
    st.anyLocked = _safe(function() return vehicle:isAnyDoorLocked() end, false)
    st.hasTrunk  = _safe(function() return vehicle:getPartById("TruckBed") ~= nil end, false)
    st.trunkLocked = _safe(function() return vehicle:isTrunkLocked() end, false)
    local heater = _safe(function() return vehicle:getPartById("Heater") end, nil)
    st.hasHeater = heater ~= nil
    st.heaterOn  = heater and _safe(function() return heater:getModData().active == true end, false) or false
    local radio  = _safe(function() return vehicle:getPartById("Radio") end, nil)
    st.hasRadio  = radio ~= nil and _safe(function() return radio:getInventoryItem() ~= nil end, false)
    st.radioOn   = st.hasRadio and _safe(function() return radio:getDeviceData():getIsTurnedOn() end, false) or false
    st.cruise    = _safe(function() return vehicle:isRegulator() end, false)
    st.cruiseSpeed = _safe(function() return vehicle:getRegulatorSpeed() end, 0)
    return st
end

-- ---------------------------------------------------------------------------
-- Toggle definitions: id, label, dot(st) -> "on"|"off"|"warn"|"bad", action
-- ---------------------------------------------------------------------------
local function _toggles(st)
    local T = {}
    T[#T + 1] = { id = "engine", label = "ENGINE",
        dot = function(s) if s.running then return (s.engineCond < 40) and "warn" or "on" elseif s.started then return "warn" else return "off" end end,
        promptA = function(s) return s.running and "Shut off" or "Start" end,
        act = function(chr, v) if v:isEngineRunning() then ISVehicleMenu.onShutOff(chr) else ISVehicleMenu.onStartEngine(chr) end end }
    T[#T + 1] = { id = "key", label = (st.hotwired and "HOTWIRE") or ((not st.keysIn and not st.hasKey) and "NO KEY" or "KEY"),
        dot = function(s) if s.hotwired then return "warn" elseif s.keysIn then return "on" elseif not s.hasKey then return "bad" else return "off" end end,
        promptA = function(s) return s.keysIn and "Remove key" or "Insert key" end,
        act = function(chr, v) if v:isEngineRunning() then ISVehicleMenu.onShutOff(chr) elseif not v:isEngineStarted() then v:setKeysInIgnition(not v:isKeysInIgnition()) end end,
        enabled = function(s) return s.hasKey or s.keysIn end }
    T[#T + 1] = { id = "lights", label = "LIGHTS",
        dot = function(s) if s.lightsOn and not s.lightsOk then return "bad" elseif s.lightsOn then return "on" else return "off" end end,
        promptA = function(s) return s.lightsOn and "Lights off" or "Lights on" end,
        act = function(chr, v) ISVehicleMenu.onToggleHeadlights(chr) end }
    T[#T + 1] = { id = "doors", label = "DOORS",
        dot = function(s) if s.allLocked then return "on" elseif s.anyLocked then return "warn" else return "off" end end,
        promptA = function(s) return s.anyLocked and "Unlock" or "Lock" end,
        act = function(chr, v) ISVehiclePartMenu.onLockDoors(chr, v, not v:isAnyDoorLocked()) end }
    if st.hasTrunk then
        T[#T + 1] = { id = "trunk", label = "TRUNK",
            dot = function(s) return s.trunkLocked and "on" or "off" end,
            promptA = function(s) return s.trunkLocked and "Unlock trunk" or "Lock trunk" end,
            act = function(chr, v) ISVehicleMenu.onToggleTrunkLocked(chr) end }
    end
    if st.hasHeater then
        T[#T + 1] = { id = "heater", label = "HEATER",
            dot = function(s) return s.heaterOn and "on" or "off" end,
            promptA = function(s) return s.heaterOn and "Heater off" or "Heater on" end,
            act = function(chr, v) ISVehicleMenu.onToggleHeater(chr) end }
    end
    T[#T + 1] = { id = "radio", label = "RADIO",
        dot = function(s) if not s.hasRadio then return (s.keysIn or s.running) and "bad" or "off" elseif s.radioOn then return "on" else return "off" end end,
        promptA = function(s) return s.radioOn and "Radio off" or "Radio on" end,
        enabled = function(s) return s.hasRadio end,
        act = function(chr, v)
            local radio = v:getPartById("Radio")
            if not radio or not radio:getInventoryItem() or not radio:getDeviceData() then return end
            pcall(function() getSoundManager():playUISound("VehicleRadioButton") end)
            radio:getDeviceData():setIsTurnedOn(not radio:getDeviceData():getIsTurnedOn())
        end }
    T[#T + 1] = { id = "cruise", label = "CRUISE",
        dot = function(s) return s.cruise and "on" or "off" end,
        -- display only (vanilla binds cruise to a key, not the dashboard)
    }
    return T
end

-- ---------------------------------------------------------------------------
-- The organism
-- ---------------------------------------------------------------------------
ZeD_Dashboard = ZeD_Panel:derive("ZeD_Dashboard")

function ZeD_Dashboard:new(playerNum)
    local o = ZeD_Panel:new(0, 0, BASE_W, BASE_H)
    setmetatable(o, self)
    self.__index = self
    o.playerNum = playerNum or 0
    o._zedLabel = "Dashboard"
    o.vehicle   = nil
    o._hit      = {}      -- toggle hit rects (panel-local)
    o._focusRing = { { zone = "dashToggles", focusable = false, elements = {}, focusedElementIdx = 1 } }
    o._focusIdx  = 1
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor     = { r = 0, g = 0, b = 0, a = 0 }
    return o
end

function ZeD_Dashboard:_scale()
    local T = ZeD.T
    return (T and T.scale) or 1
end

function ZeD_Dashboard:_layout()
    local s = self:_scale()
    local w, h = math.floor(BASE_W * s), math.floor(BASE_H * s)
    local pn = self.playerNum
    local x = getPlayerScreenLeft(pn) + math.floor((getPlayerScreenWidth(pn) - w) / 2)
    local y = getPlayerScreenTop(pn) + getPlayerScreenHeight(pn) - h - math.floor(8 * s)
    if self:getWidth() ~= w then self:setWidth(w) end
    if self:getHeight() ~= h then self:setHeight(h) end
    if self:getX() ~= x then self:setX(x) end
    if self:getY() ~= y then self:setY(y) end
    return w, h, s
end

local function _dotColor(kind)
    local T = ZeD.T
    if kind == "on" then return T.positive elseif kind == "warn" then return T.warning elseif kind == "bad" then return T.danger end
    return { r = 0.33, g = 0.33, b = 0.33, a = 1 }
end

function ZeD_Dashboard:prerender()
    local T = ZeD.T
    local A = ZeD.Atoms
    local chr = getSpecificPlayer(self.playerNum)
    local vehicle = chr and chr:getVehicle()
    if not chr or not vehicle or (ISUIHandler and ISUIHandler.allUIVisible == false) then
        self:setVisible(false)
        return
    end
    self.vehicle = vehicle

    -- Park the vanilla dashboard every frame (vanilla's event handlers keep
    -- re-showing it on enter/seat change).
    local vd = getPlayerVehicleDashboard and getPlayerVehicleDashboard(self.playerNum)
    if vd and vd.isVisible and vd:isVisible() then pcall(vd.setVisible, vd, false) end

    local w, h, s = self:_layout()
    local tm = getTextManager()
    local st = _state(vehicle, chr)
    local family, scriptName = _family(vehicle)
    local trim = _trimColor(vehicle, family)
    local isLux = family == "luxury"

    -- Chassis + trim band
    local s1 = isLux and { r = 0.086, g = 0.078, b = 0.063, a = 1 } or T.surf1
    local bd = T.border
    self:drawRect(0, 0, w, h, s1.a or 1, s1.r, s1.g, s1.b)
    self:drawRectBorder(0, 0, w, h, bd.a, bd.r, bd.g, bd.b)
    if family == "emergency" then
        local seg = math.floor(12 * s)
        local alt = T.danger
        for sx = 1, w - 2, seg * 2 do
            self:drawRect(sx, 1, math.min(seg, w - 1 - sx), 3, 1, trim.r, trim.g, trim.b)
            if sx + seg < w - 1 then self:drawRect(sx + seg, 1, math.min(seg, w - 1 - sx - seg), 3, 1, alt.r, alt.g, alt.b) end
        end
    else
        self:drawRect(1, 1, w - 2, 3, 1, trim.r, trim.g, trim.b)
    end

    -- Cluster -----------------------------------------------------------
    local cw = math.floor(CLUSTER_W * s)
    A.drawDividerV(self, cw, 6, h - 12, false)
    local pad = math.floor(12 * s)
    local digitsFont = T.fontF4
    local digits = tostring(st.speed)
    local dc = (family == "sport") and { r = 0.91, g = 0.66, b = 0.19 } or T.text
    self:drawText(digits, pad, math.floor(10 * s), dc.r, dc.g, dc.b, 1, digitsFont)
    local dw = tm:MeasureStringX(digitsFont, digits)
    -- gear chip
    local gearFont = T.fontF1
    local gw = tm:MeasureStringX(gearFont, st.gear) + 8
    local gh = tm:getFontHeight(gearFont) + 2
    local gx = pad + dw + 8
    local gy = math.floor(12 * s)
    self:drawRect(gx, gy, gw, gh, 1, T.text.r, T.text.g, T.text.b)
    self:drawText(st.gear, gx + 4, gy + 1, 0.05, 0.05, 0.05, 1, gearFont)
    -- unit line
    local unit
    if st.running then unit = string.format("KM/H - %d RPM", math.floor(st.rpm))
    elseif st.hotwired then unit = "KM/H - HOTWIRED"
    elseif st.keysIn then unit = "KM/H - KEY IN"
    elseif not st.hasKey then unit = "KM/H - NO KEY"
    else unit = "KM/H" end
    self:drawText(unit, pad, math.floor(10 * s) + tm:getFontHeight(digitsFont) + 2, T.textDim.r, T.textDim.g, T.textDim.b, 1, T.fontF5)

    -- Bars
    local bx = pad + math.floor(118 * s)
    local bw = cw - bx - math.floor(10 * s)
    local rowY = math.floor(12 * s)
    local rowStep = math.floor(22 * s)
    local function bar(label, pct, color, valStr)
        local lw = math.floor(34 * s)
        self:drawText(label, bx, rowY - 1, T.textDim.r, T.textDim.g, T.textDim.b, 1, T.fontF5)
        local tx, tw, th = bx + lw, bw - lw - math.floor(36 * s), math.floor(8 * s)
        local s2 = T.surf2
        self:drawRect(tx, rowY, tw, th, s2.a, s2.r, s2.g, s2.b)
        self:drawRectBorder(tx, rowY, tw, th, bd.a, bd.r, bd.g, bd.b)
        if pct then
            local fw = math.floor((tw - 2) * math.max(0, math.min(1, pct)))
            if fw > 0 then self:drawRect(tx + 1, rowY + 1, fw, th - 2, 1, color.r, color.g, color.b) end
        end
        local vw = tm:MeasureStringX(T.fontF5, valStr)
        local vc = (color == T.danger) and T.danger or T.text
        self:drawText(valStr, bx + bw - vw, rowY - 1, vc.r, vc.g, vc.b, 1, T.fontF5)
        rowY = rowY + rowStep
    end
    local rpmPct = st.running and math.max(0, math.min(1, (st.rpm - 1000) / 6000)) or 0
    bar("RPM", rpmPct, T.text, st.running and string.format("%.1fk", st.rpm / 1000) or "0")
    if st.fuel then
        local fc = (st.fuel < 0.15) and T.danger or ((st.fuel < 0.35) and T.warning or T.positive)
        bar("FUEL", st.fuel, fc, string.format("%d%%", math.floor(st.fuel * 100 + 0.5)))
    else
        bar("FUEL", nil, T.text, "--")
    end
    if st.battery then
        local bc = (st.battery < 0.2) and T.danger or ((st.battery < 0.5) and T.warning or T.positive)
        bar("BATT", st.battery, bc, string.format("%d%%", math.floor(st.battery * 100 + 0.5)))
    else
        bar("BATT", nil, T.text, "--")
    end

    -- Toggles -----------------------------------------------------------
    local Focus = ZeD.Input and ZeD.Input.Focus
    local focEl = (Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() == self) and Focus.getFocusedElement(self) or nil
    local toggles = _toggles(st)
    self._hit = {}
    local elements = {}
    local tw, th, gap = math.floor(TOGGLE_W * s), math.floor(TOGGLE_H * s), math.floor(TOGGLE_GAP * s)
    local tx0 = cw + math.floor(8 * s)
    local ty0 = math.floor(8 * s)
    local perRow = math.max(1, math.floor((w - tx0 - math.floor(8 * s) + gap) / (tw + gap)))
    for i, tg in ipairs(toggles) do
        local col = (i - 1) % perRow
        local row = math.floor((i - 1) / perRow)
        local x = tx0 + col * (tw + gap)
        local y = ty0 + row * (th + gap)
        local kind = tg.dot(st)
        local enabled = (tg.enabled == nil) or tg.enabled(st)
        local s2 = isLux and { r = 0.118, g = 0.106, b = 0.078, a = 1 } or T.surf2
        if kind == "bad" then
            local dg = T.danger
            self:drawRect(x, y, tw, th, 0.16, dg.r, dg.g, dg.b)
            self:drawRectBorder(x, y, tw, th, 1, dg.r, dg.g, dg.b)
        else
            self:drawRect(x, y, tw, th, s2.a or 1, s2.r, s2.g, s2.b)
            self:drawRectBorder(x, y, tw, th, bd.a, bd.r, bd.g, bd.b)
        end
        if focEl and focEl.id == "dash:" .. tg.id then
            local ac = T.accent
            self:drawRect(x, y, tw, th, 0.55, ac.r, ac.g, ac.b)
        end
        local dcol = _dotColor(kind)
        A.drawStatusDot(self, x + 5, y + 5, dcol, 6)
        local lc = enabled and T.text or T.textDim
        self:drawText(tg.label, x + 5, y + th - tm:getFontHeight(T.fontF5) - 3, lc.r, lc.g, lc.b, 1, T.fontF5)
        if tg.id == "cruise" and st.cruise then
            local sp = tostring(math.floor(st.cruiseSpeed))
            self:drawText(sp, x + tw - 4 - tm:MeasureStringX(T.fontF5, sp), y + 3, T.textDim.r, T.textDim.g, T.textDim.b, 1, T.fontF5)
        end
        self._hit[#self._hit + 1] = { x = x, y = y, w = tw, h = th, tg = tg, enabled = enabled }
        if tg.act and enabled then
            elements[#elements + 1] = {
                x = x, y = y, w = tw, h = th,
                id = "dash:" .. tg.id,
                promptA = tg.promptA and tg.promptA(st) or "Toggle",
                promptB = "Drive",
                onActivate = function(win, el) win:_fire(tg) end,
                onCancel   = function(win, el) win:_release() end,
            }
        end
    end

    -- Footer line: prompts (gamepad) or brand
    local brand = _prettyName(scriptName) .. " - ZeD"
    local bwid = tm:MeasureStringX(T.fontF5, brand)
    self:drawText(brand, w - 8 - bwid, h - tm:getFontHeight(T.fontF5) - 2, 0.33, 0.33, 0.33, 1, T.fontF5)
    local Det = ZeD.Input and ZeD.Input.Detector
    if Det and Det.getMode and Det.getMode() == "gamepad" then
        local hint = focEl and ("A " .. (focEl.promptA or "Toggle") .. " - B Drive") or "Dashboard: re-enter the seat to focus"
        self:drawText(hint, 8, h - tm:getFontHeight(T.fontF5) - 2, T.textDim.r, T.textDim.g, T.textDim.b, 1, T.fontF5)
    end

    -- Gamepad ring sync (identity-preserved by id)
    if Focus and Focus.setRingZoneElements then
        local zone = self._focusRing[1]
        local oldEl = zone.elements[zone.focusedElementIdx or 1]
        local keep = nil
        if oldEl then for i, e in ipairs(elements) do if e.id == oldEl.id then keep = i; break end end end
        Focus.setRingZoneElements(self, "dashToggles", elements, keep)
        Focus.setZoneFocusable(self, "dashToggles", #elements > 0)
    end
end

function ZeD_Dashboard:render() end

function ZeD_Dashboard:_fire(tg)
    local chr = getSpecificPlayer(self.playerNum)
    local v = self.vehicle
    if not chr or not v or not tg or not tg.act then return end
    if getGameSpeed() == 0 then return end
    if getGameSpeed() > 1 then setGameSpeed(1) end
    local ok, err = pcall(tg.act, chr, v)
    if not ok then print("[ZeD] Dashboard: action " .. tostring(tg.id) .. " failed: " .. tostring(err)) end
end

function ZeD_Dashboard:onMouseDown(x, y)
    for _, hr in ipairs(self._hit or {}) do
        if hr.enabled and x >= hr.x and x < hr.x + hr.w and y >= hr.y and y < hr.y + hr.h then
            self:_fire(hr.tg)
            return true
        end
    end
    return false
end

-- Gamepad focus: claim when seated and nothing else owns focus; release on B.
function ZeD_Dashboard:_claim()
    local Focus = ZeD.Input and ZeD.Input.Focus
    if not Focus then return end
    Focus.registerWindow(self)
    if not Focus.getFocusedWindow() then Focus.claimFocus(self) end
end

function ZeD_Dashboard:_release()
    local Focus = ZeD.Input and ZeD.Input.Focus
    if not Focus then return end
    if Focus.getFocusedWindow() == self then Focus.releaseFocus() end
end

function ZeD_Dashboard:_unregister()
    local Focus = ZeD.Input and ZeD.Input.Focus
    if Focus then pcall(Focus.unregisterWindow, self) end
end

-- ---------------------------------------------------------------------------
-- Lifecycle + hooks
-- ---------------------------------------------------------------------------
function D.install()
    if D._instance then return D._instance end
    local inst = ZeD_Dashboard:new(0)
    inst:initialise()
    inst:addToUIManager()
    inst:setVisible(false)
    D._instance = inst
    print("[ZeD] Dashboard: ZeD vehicle dashboard installed (vanilla parked)")
    return inst
end

function D.getInstance() return D._instance end

function D.show(character)
    if not (character and instanceof(character, "IsoPlayer") and character:isLocalPlayer()) then return end
    local inst = D._instance or D.install()
    local pn = character and character.getPlayerNum and character:getPlayerNum() or 0
    if pn ~= inst.playerNum then return end
    local vehicle = character:getVehicle()
    if vehicle and vehicle:isDriver(character) then
        inst.vehicle = vehicle
        inst:setVisible(true)
        inst:_claim()
    else
        inst:setVisible(false)
        inst:_release(); inst:_unregister()
    end
end

function D.hide(character)
    local inst = D._instance
    if not inst then return end
    if not (character and instanceof(character, "IsoPlayer") and character:isLocalPlayer()) then return end
    local pn = character and character.getPlayerNum and character:getPlayerNum() or 0
    if pn ~= inst.playerNum then return end
    inst.vehicle = nil
    inst:setVisible(false)
    inst:_release(); inst:_unregister()
end

Events.OnGameStart.Add(function()
    D._instance = nil
    D.install()
end)
Events.OnEnterVehicle.Add(function(character) pcall(D.show, character) end)
Events.OnSwitchVehicleSeat.Add(function(character) pcall(D.show, character) end)
Events.OnExitVehicle.Add(function(character) pcall(D.hide, character) end)
