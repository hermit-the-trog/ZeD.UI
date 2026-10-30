-- ZeDUI/tools/qa/zedqa_appliances.lua  (Oct 25 2026)
-- The oven and microwave faces in the World window's Craft tab, and in their own window
-- (director: "Check that various appliance faces for cooking and crafting are the correct
-- scale in the window, and have option to pop out on their own centered panel").
-- The character is moved into the nearest room (the game powers only indoor squares), and a
-- modern gas range and a white microwave are placed beside them (tiles
-- appliances_cooking_01_12 and _24) and opened through ZeD's station route. For each:
--   the tab is wide enough that the plate draws at the screen's whole zoom (at 1.75x the
--   standard tab fitted only 1x, half size); the pop-out window opens centred with the
--   plate at least as large, the tab says where it went, a knob turned in the window moves
--   the appliance's own setting, and Bring it back returns it to the tab.
-- The appliances are taken away, the station released, the character put back where they
-- stood, both windows back on Loot.
-- Screenshots/zqa_ap_*.png; grep "ZEDQA ap".
local p = getPlayer()
local pn = p:getPlayerNum()
local ST, SA, SP = ZeD.Stations, ZeD.StationAppliance, ZeD.StationPopout
local function say(s) print("ZEDQA ap " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ap_" .. n .. ".png") end) end
local function WW() return ZeD_WorldWindow.getWindow() end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
-- after n frames, every frame until cond() is true (at most max frames), then fn
local function waitFor(n, max, cond, fn) Q[#Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
if not (ST and SA and SP) then say("ERR the station modules are not loaded"); say("DONE"); return end

-- indoors: the game gives grid power only to a square in a room or beside one (ItemContainer.isSquarePowered),
-- and the QA character's home has no room in reach. A free square at x, with powered free floor at x-2
-- and x+2: near the character, or else in the Fossoil at West Point (the story pictures' gas station).
local function sqAt(x, y, z) return getCell():getGridSquare(x, y, z) end
local function freeSq(x, y, z)
    local sq = sqAt(x, y, z)
    local ok = false
    if sq then pcall(function() ok = sq:isFree(false) and not sq:getVehicleContainer() end) end
    return ok and sq or nil
end
local function powerable(x, y, z)
    local sq = freeSq(x, y, z)
    if not sq then return nil end
    if sq:getRoom() then return sq end
    for _, d in ipairs({ { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }) do
        local n = sqAt(x + d[1], y + d[2], z)
        if n and n:getRoom() then return sq end
    end
    return nil
end
local function findSpot(cx, cy, cz, R)
    for r = 0, R do
        for dy = -r, r do
            for dx = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local x, y = cx + dx, cy + dy
                    if freeSq(x, y, cz) and powerable(x - 2, y, cz) and powerable(x + 2, y, cz) then return { x = x + 0.5, y = y + 0.5, z = cz } end
                end
            end
        end
    end
    return nil
end
local STORE = { x0 = 12052, y0 = 7117, x1 = 12069, y1 = 7126 }   -- gallery_story_stage.lua's ST.SITES.westpoint
local home = { x = p:getX(), y = p:getY(), z = p:getZ() }
local spot = findSpot(math.floor(home.x), math.floor(home.y), math.floor(home.z), 45)
local travelled, t0 = false, 0
local function moveTo(x, y, z)
    p:teleportTo(x, y, z)
    pcall(function() p:setX(x); p:setY(y); p:setZ(z); p:setLastX(x); p:setLastY(y); p:setLastZ(z) end)
end

local placed = {}
local function place(sprite, dx, dy)
    local sq = getCell():getGridSquare(math.floor(p:getX()) + dx, math.floor(p:getY()) + dy, math.floor(p:getZ()))
    if not sq then return nil end
    local obj = IsoStove.new(getCell(), sq, getSprite(sprite))
    pcall(function() obj:createContainersFromSpriteProperties() end)
    sq:AddSpecialObject(obj)
    -- (the game counts an object as powered only once it is in the square's object list)
    if obj:getObjectIndex() < 0 then pcall(function() sq:AddTileObject(obj) end) end
    placed[#placed + 1] = obj
    return obj
end

local function root() return (ZeD.Scale and ZeD.Scale.root and ZeD.Scale.root()) or 1 end
local function tabChecks(tag, obj)
    local w = WW()
    local st = ST.current(p)
    check(st and st.obj == obj, tag .. ": the station is the one opened")
    check(w and w._activeTab == "craft", tag .. ": the World window is on its Craft tab")
    local des = st and SA.plateFor(st)
    local k0 = ZeD.Px.k(root())
    local effW = w and math.floor(w._drawerEffW or 0) or 0
    local kTab = des and ZeD.Px.kFit(root(), des.w, effW - ZeD.T.sp.scrollbarW) or 0
    say(string.format("%s: plate %s %dx%d, tab %d px, zoom in the tab %d (the screen's %d)", tag, tostring(des and des.plate),
        des and des.w or 0, des and des.h or 0, effW, kTab, k0))
    -- the tab is the full card and no wider (Oct 29 2026); the plate draws at the largest whole zoom that fits it
    -- (the screen's own once Design's 336 px plates are in: ZeDUI/PLATE_SIZES_SPEC.md)
    check(effW == ZeD.T.px(480), tag .. ": the tab is the full card")
    check(kTab >= 1 and kTab <= k0, tag .. ": the plate draws at a whole zoom that fits the card")
    local hasBtn = false
    for _, z in ipairs((w and w._craftState and w._craftState.zones) or {}) do if z.type == "popout" then hasBtn = true end end
    check(hasBtn, tag .. ": the tab has the pop-out button")
end

local stove, micro, heatWas
-- the grid power on for the run (the QA world is past the shut-off; an unpowered panel offers no controls)
local so = getSandboxOptions()
local elec = so and so:getOptionByName("ElecShutModifier")
local elecWas = elec and elec:getValue()
local hydroWas = getWorld():isHydroPowerOn()
local winsWere = ZeD_CharacterWindow.isOpen()
step(10, function()
    if elec then elec:setValue(99999); pcall(function() so:toLua() end) end
    getWorld():setHydroPowerOn(true)
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    if not spot then
        travelled, t0 = true, getTimestampMs()
        say(string.format("no room in reach of %d,%d: to the Fossoil at West Point", math.floor(home.x), math.floor(home.y)))
        moveTo(math.floor((STORE.x0 + STORE.x1) / 2) + 0.5, math.floor((STORE.y0 + STORE.y1) / 2) + 0.5, 0)
    end
end)
-- (after a trip: the store's squares loaded, then 9 s more, as the story test waits)
waitFor(5, 3000, function()
    return not travelled or (sqAt(STORE.x0, STORE.y0, 0) ~= nil and sqAt(STORE.x1, STORE.y1, 0) ~= nil and getTimestampMs() - t0 > 9000)
end, function()
    if travelled then spot = findSpot(math.floor((STORE.x0 + STORE.x1) / 2), math.floor((STORE.y0 + STORE.y1) / 2), 0, 12) end
    say(spot and string.format("indoors at %d,%d", math.floor(spot.x), math.floor(spot.y)) or "ERR no powered floor at the store either")
    if spot then moveTo(spot.x, spot.y, spot.z) end
end)
step(30, function()
    stove = place("appliances_cooking_01_12", 2, 0)
    micro = place("appliances_cooking_01_24", -2, 0)
    say("placed: stove " .. tostring(stove ~= nil) .. ", microwave " .. tostring(micro ~= nil))
    pcall(function() Mouse.setXY(20, 20) end)
end)
step(10, function() check(stove and ST.open(p, stove), "the stove opens in the Craft tab") end)
step(70, function()
    local pw = false
    pcall(function() pw = stove:getContainer():isPowered() end)
    say("stove powered " .. tostring(pw) .. " (grid power on the square " .. tostring(stove:getSquare():hasGridPower())
        .. ", object index " .. tostring(stove:getObjectIndex()) .. ", world power " .. tostring(getWorld():isHydroPowerOn()) .. ")")
    tabChecks("stove", stove); shot("1_tab_stove")
end)

-- its own window
step(5, function()
    heatWas = stove:getMaxTemperature()
    SP.open(p, ST.current(p))
end)
step(40, function()
    local win = SP.get(pn)
    local des = SA.plateFor(ST.current(p))
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    check(win and win:isReallyVisible(), "the pop-out window is up")
    if win then
        local k = win:zoomFor(des)
        say(string.format("pop-out %d,%d %dx%d, zoom %d (the screen's %d)", win:getX(), win:getY(), win:getWidth(), win:getHeight(), k, ZeD.Px.k(root())))
        check(math.abs(win:getX() + win:getWidth() / 2 - sw / 2) <= 2 and math.abs(win:getY() + win:getHeight() / 2 - sh / 2) <= 2, "the pop-out is centred on the screen")
        check(k >= ZeD.Px.k(root()), "the pop-out's plate is at least the tab's size")
        check(win:getY() >= 0 and win:getY() + win:getHeight() <= sh and win:getX() >= 0 and win:getX() + win:getWidth() <= sw, "the pop-out is on screen")
        check(#win:controls() > 0, "the pop-out has the plate's controls (" .. #win:controls() .. ")")
    end
    local tabPop = false
    for _, z in ipairs((WW()._craftState and WW()._craftState.zones) or {}) do if z.type == "popin" then tabPop = true end end
    check(tabPop, "the tab says it is in its own window and offers it back")
end)
step(10, function() shot("2_popout_stove") end)
step(5, function()
    local win = SP.get(pn)
    local knob, broil
    for _, z in ipairs(win and win:controls() or {}) do
        if z.kind == "turn" and not knob then knob = z end
        if z.id == "broil" then broil = z end
    end
    if knob then
        win:onMouseDown(knob.x + knob.w - 2, knob.y + math.floor(knob.h / 2))   -- the right half turns it up a stop
        say("turned " .. tostring(knob.id))
    elseif broil then
        -- the 1992 range has keys, no knobs: BROIL is the hottest stop at once
        win:onMouseDown(broil.x + math.floor(broil.w / 2), broil.y + math.floor(broil.h / 2))
        say("pressed broil")
    else say("no knob or BROIL key on this plate") end
end)
step(30, function()
    local now = stove:getMaxTemperature()
    say("stove heat " .. tostring(heatWas) .. " -> " .. tostring(now))
    check(now ~= heatWas, "a control pressed in the pop-out moves the stove's own setting")
    shot("2b_popout_stove_on")
    local win = SP.get(pn)
    for _, z in ipairs(win and win:controls() or {}) do
        if z.id == "cancel" then win:onMouseDown(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)) end   -- off again
    end
end)
step(5, function() SP.close(p) end)
step(40, function()
    check(not (SP.get(pn) and SP.get(pn):isReallyVisible()), "Bring it back closes the window")
    local hasBtn = false
    for _, z in ipairs((WW()._craftState and WW()._craftState.zones) or {}) do if z.type == "popout" then hasBtn = true end end
    check(hasBtn, "the plate is back in the tab")
    pcall(function() stove:setMaxTemperature(heatWas or 0) end)
end)

-- the microwave
step(10, function() check(micro and ST.open(p, micro), "the microwave opens in the Craft tab") end)
step(70, function() tabChecks("microwave", micro); shot("3_tab_microwave") end)
step(5, function() SP.open(p, ST.current(p)) end)
step(40, function() shot("4_popout_microwave"); local win = SP.get(pn); check(win and win:isReallyVisible(), "the microwave pops out too") end)
step(5, function() SP.close(p) end)

step(20, function()
    pcall(function() ST.unbind(p) end)
    if elec and elecWas ~= nil then elec:setValue(elecWas); pcall(function() so:toLua() end) end
    getWorld():setHydroPowerOn(hydroWas)
    if winsWere and not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    for _, obj in ipairs(placed) do
        local sq = obj:getSquare()
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(obj) end) end
    end
    local w = WW()
    if w then
        for _, z in ipairs(w._actionTabStrip and w._actionTabStrip._hitZones or {}) do
            if z.id == "tab:loot" and w._activeTab ~= "loot" then w._actionTabStrip:onMouseDown(z.x + 2, z.y + 2) end
        end
    end
    say("cleanup: " .. #placed .. " appliances removed, station " .. tostring(ST.current(p) and ST.current(p).name or "released"))
    if spot or travelled then moveTo(home.x, home.y, home.z); t0 = getTimestampMs() end
end)
-- back where they stood, the squares there loaded (3 s more after a trip)
waitFor(5, 3000, function()
    return not travelled or (sqAt(math.floor(home.x), math.floor(home.y), math.floor(home.z)) ~= nil and getTimestampMs() - t0 > 3000)
end, function()
    say(string.format("back at %d,%d", math.floor(p:getX()), math.floor(p:getY())))
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    if s.cond then
        s.left = (s.left or s.max) - 1
        local ok, done = pcall(s.cond)
        if not (ok and done) and s.left > 0 then wait = 1; return end
        if not (ok and done) then say("ERR step " .. qi .. ": waited " .. s.max .. " frames") end
    end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
