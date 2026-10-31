-- ZeDUI/tools/qa/gallery_t14_radios.lua  (Oct 30 2026)
-- Workshop gallery, slide 57 "Radios and the CD player" (0.2.0-t14; faces from HANDOFF_radio_tv_laundry_20261030.md):
-- each portable in the main hand, the Character window's Radio tab on it (the half card), switched on, then a full 4K
-- screenshot in Zomboid/Screenshots once both windows have stopped moving:
--   g14_radio_black      the ValuTech radio (Base.RadioBlack), on, 98.0
--   g14_radio_red        the Premium radio (Base.RadioRed), on, 98.0
--   g14_radio_handbuilt  the hand-built radio (Base.RadioMakeShift), on, 98.0
--   g14_radio_cd         the CD player (Base.CDplayer), a disc in and playing
-- Each window's box and the radio face's rect are printed ("box ...") for the crops. Batteries at 60 per cent.
-- Puts back the hands, takes away every item it made, the tab back to Loot, the windows as they were.
-- Run after gallery_t14_look.lua. "ZEDQA g14r ..." ending "ZEDQA g14r DONE".
local p = getPlayer()
local pn = p:getPlayerNum()
local RT = ZeD.RadioTab
local function say(s) print("ZEDQA g14r " .. tostring(s)) end
if not (RT and ZeD.Rtv) then say("ERR the radio faces are not loaded"); say("DONE"); return end
local Z = { Q = {}, qi = 0, wait = 0, added = {}, cur = nil }
local function CW() return ZeD_CharacterWindow.getWindow() end
function Z.step(n, fn) Z.Q[#Z.Q + 1] = { n = n, fn = fn } end
function Z.waitFor(n, max, cond, fn) Z.Q[#Z.Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
-- the windows' place, size and drawer width the same for 30 frames (at most 900), then fn
local function shape()
    if GAL_SHAPE then return GAL_SHAPE() end
    local w = CW()
    return w and string.format("%d,%d,%d,%d,%d", w:getX(), w:getY(), w:getWidth(), w:getHeight(), math.floor(w._drawerEffW or 0)) or ""
end
function Z.whenStill(n, fn)
    local last, same = nil, 0
    Z.waitFor(n, 900, function()
        local s = shape()
        if s == last then same = same + 1 else last, same = s, 0 end
        return same >= 30
    end, fn)
end
function Z.shot(name)
    local ok, e = pcall(function() getCore():TakeFullScreenshot(name .. ".png") end)
    say((ok and "shot " or "ERR shot ") .. name .. (ok and "" or (": " .. tostring(e))))
    local w = CW()
    if w then say(string.format("box %s char %d,%d-%d,%d", name, w:getX(), w:getY(), w:getX() + w:getWidth(), w:getY() + w:getHeight())) end
    local t = w and w._radioTw
    if t and t.face then
        local ax, ay = w:getAbsoluteX(), w:getAbsoluteY()
        say(string.format("box %s face %s at %d,%d (window) k %s", name, tostring(t.pid), t.face.x or -1, t.face.y or -1, tostring(t.k)))
        say(string.format("box %s window origin %d,%d", name, ax, ay))
    end
end
local function goTab(id)
    local w = CW()
    for _, z in ipairs(w and w._tabStripPanel and w._tabStripPanel._hitZones or {}) do
        if z.id == "tab:" .. id then
            if w._activeTab ~= id or (id ~= "loot" and not w._drawerOpen) then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
local was = { prim = p:getPrimaryHandItem(), sec = p:getSecondaryHandItem(), open = ZeD_CharacterWindow.isOpen() }

local function give(ft)
    local it = p:getInventory():AddItem(ft)
    if it then Z.added[#Z.added + 1] = it end
    return it
end
local function radio(m)
    Z.step(5, function()
        local it = give(m.ft)
        Z.cur = it
        if not it then say("ERR could not make " .. m.ft); return end
        local dd = it:getDeviceData()
        if dd then
            if dd:getIsBatteryPowered() then dd:setHasBattery(true); dd:setPower(0.6) end
            dd:setDeviceVolume(0.4)
            pcall(function() dd:setChannel(98000) end)
            dd:setIsTurnedOn(true)
            if m.cd then
                pcall(function() dd:addMediaItem(instanceItem("Base.Disc_Retail")) end)
                pcall(function() dd:StartPlayMedia() end)
            end
        end
        p:setSecondaryHandItem(nil)
        p:setPrimaryHandItem(it)
    end)
    Z.waitFor(5, 300, function() local r = CW()._radios and CW()._radios[1]; return r ~= nil and r.radioInstance == Z.cur end,
        function() if not goTab("radio") then say("ERR " .. m.name .. ": no Radio tab") end end)
    Z.waitFor(5, 300, function() local t = CW()._radioTw; return t ~= nil and t.dev == Z.cur end, function()
        local t = CW()._radioTw
        say(m.name .. ": face " .. tostring(t and t.pid) .. ", card " .. math.floor(CW()._drawerEffW or 0) .. " px, on " .. tostring(Z.cur and Z.cur:getDeviceData():getIsTurnedOn()))
        pcall(function() Mouse.setXY(20, 20) end)
    end)
    Z.waitFor(60, 600, function() return not m.cd or (Z.cur and Z.cur:getDeviceData():isPlayingMedia()) end, function() end)
    Z.whenStill(10, function() Z.shot(m.name) end)
    Z.step(5, function()
        local dd = Z.cur and Z.cur:getDeviceData()
        if dd then pcall(function() dd:StopPlayMedia() end); dd:setIsTurnedOn(false) end
        p:setPrimaryHandItem(nil)
    end)
end

Z.step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    RT.useFaces = true
    say("look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. ", scale " .. tostring(ZeD.Scale and ZeD.Scale.root and ZeD.Scale.root()))
end)
radio({ ft = "Base.RadioBlack", name = "g14_radio_black" })
radio({ ft = "Base.RadioRed", name = "g14_radio_red" })
radio({ ft = "Base.RadioMakeShift", name = "g14_radio_handbuilt" })
radio({ ft = "Base.CDplayer", name = "g14_radio_cd", cd = true })
Z.step(10, function()
    p:setPrimaryHandItem(was.prim); p:setSecondaryHandItem(was.sec)
    for _, it in ipairs(Z.added) do local c = it:getContainer(); if c then pcall(function() c:Remove(it) end) end end
    goTab("loot")
    if was.open ~= ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    say("put back: hands, " .. #Z.added .. " items taken away")
end)
Z.step(10, function() say("DONE") end)

local function tick()
    local s = Z.Q[Z.qi + 1]
    if not s then Events.OnTick.Remove(tick); return end
    Z.wait = Z.wait + 1
    if Z.wait < s.n then return end
    if s.cond then
        s.left = (s.left or s.max) - 1
        local ok, done = pcall(s.cond)
        if not (ok and done) and s.left > 0 then return end
        if not (ok and done) then say("WARN step " .. (Z.qi + 1) .. ": waited " .. s.max .. " frames, went on") end
    end
    Z.wait = 0
    Z.qi = Z.qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. Z.qi .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
