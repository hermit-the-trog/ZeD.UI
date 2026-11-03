-- ZeDUI/tools/qa/zedqa_radio_review.lua  (Nov 3 2026, QA; the director's review of the radio faces)
-- At 4K, at each of ZeD's UI scale steps (0.5x to 2x, ZeD.Scale.override, a layout reset each time): every radio with
-- a face, in its Radio tab (the half card, or the full card where the face needs it), switched on; and for each
-- two-way set its full view as well (TwoWayFull.lua, the plate on its own). In the hand (Character window): the
-- ValuTech, Premium and hand-built radios, the CD player, the five walkies, the hand-built walkie and the ManPack. Set
-- down beside the character (World window): the civilian, army and hand-built ham sets. Logs every window's and full
-- view's rect for the crops ("rect <shot> x y w h"). Puts the hands, the scale and the tabs back; takes away all it
-- made. Shots zqa_rrv_<scale>_<plate>_half.png and _full.png; grep "ZEDQA rrv".
local p = getPlayer()
local pn = p:getPlayerNum()
local Sc = ZeD.Scale
local F = ZeD.TwoWayFull
local function say(s) print("ZEDQA rrv " .. tostring(s)) end
if not (Sc and F and ZeD.RadioTab) then say("ERR the radio modules are not loaded"); say("DONE"); return end
local function CW() return ZeD_CharacterWindow.getWindow() end
local function WW() return ZeD_WorldWindow.getWindow() end
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function waitFor(n, max, cond, fn) Q[#Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
local SC = "x"
local made, placed = {}, {}
local handWas = { p:getPrimaryHandItem(), p:getSecondaryHandItem() }

local function rect(name, ui)
    if ui then say(string.format("rect %s %d %d %d %d", name, ui:getAbsoluteX(), ui:getAbsoluteY(), ui:getWidth(), ui:getHeight())) end
end
local function shot(name, ui)
    pcall(function() getCore():TakeFullScreenshot(name .. ".png") end)
    rect(name, ui)
end
local function power(dev)
    local dd = dev and dev:getDeviceData()
    if not dd then return end
    pcall(function() if dd:getIsBatteryPowered() then dd:setHasBattery(true); dd:setPower(0.8) end end)
    pcall(function() dd:setDeviceVolume(0.4) end)
    pcall(function() dd:setChannel(98000) end)
    pcall(function() dd:setIsTurnedOn(true) end)
end
-- the Radio tab open on dev, its drawer at a card width and still for a few polls
local still = { v = -1, n = 0 }
local poke = 0
local function ready(w, strip, dev)
    if not w then return false end
    poke = poke + 1
    if (w._activeTab ~= "radio" or not w._drawerOpen) and poke % 15 == 1 then
        for _, z in ipairs(strip and strip._hitZones or {}) do
            if z.id == "tab:radio" then strip:onMouseDown(z.x + 2, z.y + 2) end
        end
    end
    for i, r in ipairs(w._radios or {}) do if r.radioInstance == dev then w._radioIdx = i end end
    if w._activeTab ~= "radio" or not w._drawerOpen then return false end
    local t = w._radioTw
    if not (t and t.dev == dev) then return false end
    local e = math.floor(w._drawerEffW or 0)
    if e == still.v then still.n = still.n + 1 else still.v, still.n = e, 0 end
    return e > 0 and still.n >= 20
end
local function pid(w) local t = w and w._radioTw; return t and t.pid or "?" end

-- one radio: in the hand (ft) or set down (sprite)
local cur
local function radio(ft, twoWay, sprite)
    step(5, function()
        poke, still.v, still.n = 0, -1, 0
        if sprite then
            local here = p:getCurrentSquare()
            local x0, y0, z0 = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
            cur = nil
            for _, d in ipairs({ { -1, 1 }, { 1, 1 }, { -1, -1 }, { 1, -1 }, { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 } }) do
                local sq = getCell():getGridSquare(x0 + d[1], y0 + d[2], z0)
                if not cur and sq and sq:isFree(false) and here and here:canReachTo(sq) then
                    local it = instanceItem(ft)
                    local dv = it and it:getDeviceData()
                    if dv then
                        cur = IsoRadio.new(getCell(), sq, getSprite(sprite))
                        cur:setDeviceData(dv)
                        sq:AddTileObject(cur)
                        placed[#placed + 1] = cur
                    end
                end
            end
        else
            cur = p:getInventory():AddItem(ft)
            if cur then made[#made + 1] = cur end
            p:setSecondaryHandItem(nil)
            p:setPrimaryHandItem(cur)
        end
        if not cur then say("ERR " .. SC .. " " .. ft .. ": not made"); return end
        power(cur)
        if sprite then
            if not ZeD_WorldWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
        elseif not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    end)
    local function win() return sprite and WW() or CW() end
    local function strip() local w = win(); return w and (sprite and w._actionTabStrip or w._tabStripPanel) end
    waitFor(10, 900, function() return cur ~= nil and ready(win(), strip(), cur) end, function()
        local w = win()
        if not (cur and w and w._radioTw and w._radioTw.dev == cur) then say("ERR " .. SC .. " " .. ft .. ": the Radio tab did not open on it"); return end
        pcall(function() Mouse.setXY(20, 20) end)
        local name = "zqa_rrv_" .. SC .. "_" .. pid(w) .. "_half"
        shot(name, w)
        say(string.format("%s %s: face %s, card %d px", SC, ft, pid(w), math.floor(w._drawerEffW or 0)))
        if twoWay then F.open(p, cur, w) end
    end)
    if twoWay then
        step(60, function()
            local v = F.views and F.views[pn]
            local w = win()
            if v and v:isReallyVisible() then shot("zqa_rrv_" .. SC .. "_" .. pid(w) .. "_full", v)
            else say("ERR " .. SC .. " " .. ft .. ": no full view") end
            pcall(function() F.close(pn) end)
        end)
    end
    step(10, function()
        if not cur then return end
        pcall(function() cur:getDeviceData():setIsTurnedOn(false) end)
        if sprite then
            pcall(function() cur:getSquare():transmitRemoveItemFromSquare(cur) end)
            pcall(function() if cur:getSquare() then cur:getSquare():RemoveTileObject(cur) end end)
        else
            p:setPrimaryHandItem(nil)
            pcall(function() p:getInventory():Remove(cur) end)
        end
        cur = nil
    end)
end

local HAND = {
    { "Base.RadioBlack" }, { "Base.RadioRed" }, { "Base.RadioMakeShift" }, { "Base.CDplayer" },
    { "Base.WalkieTalkie1", true }, { "Base.WalkieTalkie2", true }, { "Base.WalkieTalkie3", true }, { "Base.WalkieTalkie4", true },
    { "Base.WalkieTalkie5", true }, { "Base.WalkieTalkieMakeShift", true }, { "Base.ManPackRadio", true },
}
local SET = { { "Base.HamRadio1", "appliances_com_01_0" }, { "Base.HamRadio2", "appliances_com_01_8" }, { "Base.HamRadioMakeShift", "appliances_com_01_56" } }

step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    end)
    ZeD.RadioTab.useFaces = true
end)
for _, s in ipairs({ 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0 }) do
    step(10, function()
        Sc.override = s; Sc.refresh(); ZeD.applyTheme()
        SC = string.format("%.2f", s):gsub("%.", "_")
        say(string.format("scale %.2f: root %.2f", s, (Sc.root and Sc.root()) or -1))
    end)
    step(60, function() pcall(ZeD_Window.resetLayout) end)
    step(60, function() end)
    for _, r in ipairs(HAND) do radio(r[1], r[2]) end
    for _, r in ipairs(SET) do radio(r[1], true, r[2]) end
end
step(20, function()
    Sc.override = nil; Sc.refresh(); ZeD.applyTheme()
    p:setPrimaryHandItem(handWas[1]); p:setSecondaryHandItem(handWas[2])
    for _, it in ipairs(made) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    for _, o in ipairs(placed) do pcall(function() if o:getSquare() then o:getSquare():RemoveTileObject(o) end end) end
    say("put back: the scale, the hands; " .. #made .. " items and " .. #placed .. " sets taken away")
end)
step(60, function() pcall(ZeD_Window.resetLayout) end)
step(30, function() say("DONE") end)

local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnTick.Remove(tick); return end
    wait = wait + 1
    if wait < q.n then return end
    if q.cond then
        q.left = (q.left or q.max) - 1
        local ok, done = pcall(q.cond)
        if not (ok and done) and q.left > 0 then return end
        if not (ok and done) then say("WARN step " .. (qi + 1) .. ": waited " .. q.max .. " frames, went on") end
    end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
