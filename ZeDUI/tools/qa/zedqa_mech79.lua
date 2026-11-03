-- ZeDUI/tools/qa/zedqa_mech79.lua  (Nov 3 2026, QA; punch list 79, VEHICLE_TAB_SPEC.md section 8)
-- The Vehicle tab in two columns. From the drag strip (ZEDQA_HOME): a sedan beside the character with its key, its
-- front left tire taken off (a missing part), the jack, lug wrench and wrench in the bag, Mechanics set to 3; the
-- game's own "Vehicle Mechanics" walks over and inspects it. Then: By section's order (a brake and a suspension under
-- their tire, a window under its door), the missing part's row; the Sort list with By condition greyed at level 3 and
-- usable at 4; hover on a row lights the part and never opens the card; a click on a row opens its card, the same row
-- closes it, another row swaps it; no back arrow; the wheel over the card keeps it; a click on the diagram picks a
-- part; the step-before line on a brake and its button; the footer's verbs (lit or greyed); a real uninstall and
-- install of the rear right tire with the card staying on it; A and B through the controller's elements. Last, a
-- livestock trailer with animals: its tab and the animal rows inside the list column. Everything made is taken away
-- and the Mechanics level put back. Shots zqa_m79_<w>x<h>_*.png; grep "ZEDQA m79".
local function say(s) print("ZEDQA m79 " .. tostring(s)) end
if ZEDQA_HOME then ZEDQA_HOME("m79") end
local p = getPlayer()
local MT = ZeD and ZeD.MechanicsTab
if not (p and MT) then say("ERR the Vehicle tab is not loaded"); say("DONE"); return end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_m79_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local function W() return ZeD_WorldWindow.getWindow() end
local function S() local w = W(); return w and MT.getState(w) end
local function zone(id) local s = S(); return s and s.byId and s.byId[id] end
local function zonesLike(pre) local out = {}; for _, z in ipairs((S() or {}).zones or {}) do if z.id:sub(1, #pre) == pre then out[#out + 1] = z end end; return out end
-- a click at the zone's middle, as the World window passes it; a row scrolled out of view is pressed directly (logged)
local function press(z)
    local w = W(); if not (z and w) then return end
    local cx, cy = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    local c = z.clip
    if c and not (cx >= c.x and cx < c.x + c.w and cy >= c.y and cy < c.y + c.h) then say("(" .. z.id .. " is out of view: pressed directly)"); z.fn(); return end
    MT.onClick(w, cx, cy)
end
local function rowOrder() local o = {}; for i, z in ipairs((S() or {}).lastRows or {}) do o[#o + 1] = z.part end; return o end
local function idx(list, id) for i, v in ipairs(list) do if v == id then return i end end; return nil end
if getGameSpeed() <= 0 then setGameSpeed(1) end

local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function waitFor(n, max, cond, fn) Q[#Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
local v, trailer, key, hovered
local made, animals = {}, {}
local mechWas = p:getPerkLevel(Perks.Mechanics)
local knewRecipe = true

local function freeSq(offsets)
    for _, o in ipairs(offsets) do
        local sq = getCell():getGridSquare(math.floor(p:getX()) + o[1], math.floor(p:getY()) + o[2], math.floor(p:getZ()))
        local free = false
        if sq then pcall(function() free = sq:isFree(false) and not sq:HasTree() and not sq:getVehicleContainer() end) end
        if free then return sq end
    end
    return nil
end

-- ---- the car
step(120, function()
    local sq = freeSq({ { 3, 0 }, { -3, 0 }, { 0, 3 }, { 0, -3 }, { 4, 2 }, { -4, 2 } })
    v = sq and addVehicleDebug("Base.CarNormal", IsoDirections.N, nil, sq) or nil
    if not v then say("ERR no free square for the car"); return end
    pcall(function() key = p:getInventory():AddItem(v:createVehicleKey()); made[#made + 1] = key end)
    for _, t in ipairs({ "Base.Jack", "Base.LugWrench", "Base.Wrench", "Base.Screwdriver" }) do
        local it = p:getInventory():AddItem(t); if it then made[#made + 1] = it end
    end
    p:setPerkLevelDebug(Perks.Mechanics, 3)
    -- brakes and suspension need the recipe; known, their cards show Uninstall (and its step before)
    pcall(function() knewRecipe = p:isRecipeKnown("Basic Mechanics") end)
    if not knewRecipe then pcall(function() p:learnRecipe("Basic Mechanics") end) end
    say("car at " .. math.floor(v:getX()) .. "," .. math.floor(v:getY()) .. "; Mechanics " .. mechWas .. " -> 3")
end)
step(180, function()
    if not v then return end
    local tire = v:getPartById("TireFrontLeft")
    if tire then pcall(function() tire:setInventoryItem(nil); v:transmitPartItem(tire) end) end
    say("front left tire off: " .. tostring(tire and tire:getInventoryItem() == nil))
    if not ZeD_WorldWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
step(60, function() if v then ISVehicleMenu.onMechanic(p, v) end end)
waitFor(30, 3600, function() local w = W(); return v and MT.isInspected(v) and w and w._activeTab == "vehicle" end, function()
    check(v and MT.isInspected(v), "the game's Vehicle Mechanics inspects the car and the World window shows the Vehicle tab")
    pcall(function() Mouse.setXY(sw - 4, sh - 4) end)
end)

-- ---- By section
step(90, function()
    local s = S(); if not s then return end
    local o = rowOrder()
    say("rows (By section, " .. #o .. "): " .. table.concat(o, ", "))
    check(s.sort == "area", "the list opens By section")
    local function under(child, parentId, nextPrefix)
        local a, b = idx(o, parentId), idx(o, child)
        if not (a and b and b > a) then return false end
        for i = a + 1, b - 1 do if o[i]:find(nextPrefix, 1, true) == 1 then return false end end
        return true
    end
    check(under("BrakeRearLeft", "TireRearLeft", "Tire"), "a brake sits under its tire (BrakeRearLeft after TireRearLeft, no tire between)")
    check(under("SuspensionRearLeft", "TireRearLeft", "Tire"), "a suspension sits under its tire")
    check(under("WindowFrontLeft", "DoorFrontLeft", "Door"), "a window sits under its door")
    check(idx(o, "TireFrontLeft") ~= nil, "the missing front left tire keeps its row")
    check(zone("mech:back") == nil, "no back arrow")
    local w = W()
    local over = {}
    for _, z in ipairs(s.lastRows or {}) do if s.splitX and z.x + z.w > s.splitX + 1 then over[#over + 1] = z.part end end
    check(#over == 0, "every row sits inside the list column" .. (#over > 0 and (" (over: " .. table.concat(over, ", ") .. ")") or ""))
    shot("1_by_section")
end)
-- ---- hover lights the part and never opens the card
step(10, function()
    local s, w = S(), W()
    local z
    for _, r in ipairs(s.lastRows or {}) do
        local c, cy = r.clip, r.y + math.floor(r.h / 2)
        if not z and (not c or (cy >= c.y and cy < c.y + c.h)) then z = r end
    end
    if not (z and w) then say("ERR no row in view"); return end
    hovered = z.part
    local panel = s.panel
    -- the real cursor (release_check_mouse.ps1 "move"): a script-set Mouse does not make hover in 42.22
    pcall(function() local fw = getFileWriter("zedqa_click_done.txt", true, false); fw:write(""); fw:close() end)
    pcall(function()
        local f = getFileWriter("zedqa_click.txt", true, false)
        f:write("move " .. math.floor(panel:getAbsoluteX() + z.x + 20) .. " " .. math.floor(panel:getAbsoluteY() + z.y + z.h / 2)); f:close()
    end)
end)
waitFor(10, 600, function()
    local r = getFileReader("zedqa_click_done.txt", false); local l = r and r:readLine(); if r then r:close() end
    return l ~= nil and l:find("done", 1, true) ~= nil
end, function() end)
step(30, function()
    local s = S()
    check(s and s.hl ~= nil and s.hl == hovered, "hover on a row lights its part on the diagram (" .. tostring(hovered) .. ", lit " .. tostring(s and s.hl) .. ")")
    check(s and s.card == nil, "hover never opens the card")
    shot("2_hover_row")
end)
-- ---- the Sort list: By condition greyed at level 3
step(10, function() pcall(function() Mouse.setXY(sw - 4, sh - 4) end); press(zone("mech:sortMenu")) end)
step(20, function()
    local s = S()
    local c = zone("mech:sortRow:cond")
    check(s and s.sortOpen, "the Sort box opens its list")
    local sz
    for _, z in ipairs(s and s.sortZones or {}) do if z.id == "cond" then sz = z end end
    check(sz and sz.disabled, "By condition is greyed at Mechanics 3")
    shot("3_sort_gated")
    press(c)
end)
step(20, function()
    local s = S()
    check(s and s.sort == "area", "pressing the greyed By condition changes nothing (" .. tostring(s and s.sort) .. ")")
    if s then s.sortOpen = nil end
    p:setPerkLevelDebug(Perks.Mechanics, 4)
end)
step(20, function() press(zone("mech:sortMenu")) end)
step(20, function()
    local sz
    for _, z in ipairs((S() or {}).sortZones or {}) do if z.id == "cond" then sz = z end end
    check(sz and not sz.disabled, "By condition is usable at Mechanics 4")
    press(zone("mech:sortRow:cond"))
end)
step(30, function()
    local s = S()
    check(s and s.sort == "cond", "By condition sorts the list (" .. tostring(s and s.sort) .. ")")
    say("rows (By condition): " .. table.concat(rowOrder(), ", "))
    shot("4_by_condition")
    press(zone("mech:sortMenu"))
end)
step(20, function() press(zone("mech:sortRow:area")) end)
-- ---- a click opens the card, the same row closes it, another swaps it; the wheel keeps it
step(20, function() press(zone("mech:row:TireRearRight")) end)
step(30, function()
    local s = S()
    check(s and s.card == "TireRearRight", "a click on a row opens its card (" .. tostring(s and s.card) .. ")")
    check(zone("mech:back") == nil, "the card has no back arrow")
    local verbs = {}
    for _, z in ipairs(zonesLike("mech:verb:")) do verbs[#verbs + 1] = z.id:sub(11) .. (z.disabled and " (greyed)" or "") end
    say("tire card footer verbs: " .. table.concat(verbs, ", "))
    check(zone("mech:verb:uninstall") and not zone("mech:verb:uninstall").disabled, "the tire's main verb, Uninstall, is in the footer and lit")
    check(zone("mech:sortMenu") ~= nil, "the Sort box stays in the footer with the card open")
    shot("5_card_tire")
    local w = W()
    if s and s.panel and s.splitX then pcall(function() Mouse.setXY(s.panel:getAbsoluteX() + s.splitX + 40, s.panel:getAbsoluteY() + 200) end) end
    MT.onMouseWheel(w, 1); MT.onMouseWheel(w, -1)
end)
step(10, function()
    check(S() and S().card == "TireRearRight", "the mouse wheel over the card does not close it")
    pcall(function() Mouse.setXY(sw - 4, sh - 4) end)
    press(zone("mech:row:TireRearRight"))
end)
step(20, function()
    check(S() and S().card == nil, "the same row again closes the card")
    press(zone("mech:row:TireRearRight"))
end)
step(20, function() press(zone("mech:row:DoorFrontLeft")) end)
step(20, function()
    check(S() and S().card == "DoorFrontLeft", "another row swaps the card (" .. tostring(S() and S().card) .. ")")
    press(zone("mech:row:DoorFrontLeft"))
end)
-- ---- a click on the diagram picks a part
step(20, function()
    local s = S()
    local c = s and s.figClip
    if not c then say("ERR no diagram"); return end
    local hitId
    for dy = 0, c.h - 1, 6 do
        for dx = 0, c.w - 1, 6 do
            if not hitId then
                MT.onClick(W(), c.x + dx, c.y + dy)
                if s.card then hitId = s.card end
            end
        end
    end
    check(hitId ~= nil, "a click on the diagram picks a part (" .. tostring(hitId) .. ")")
    if s.card then press(zone("mech:row:" .. s.card)) end
end)
-- ---- the step before (a brake under a fitted tire)
step(20, function() press(zone("mech:row:BrakeRearLeft")) end)
step(30, function()
    local z = zone("mech:step")
    local vb = {}
    for _, q in ipairs(zonesLike("mech:verb:")) do vb[#vb + 1] = q.id:sub(11) .. (q.disabled and " (greyed)" or "") end
    local known = false; pcall(function() known = p:isRecipeKnown("Basic Mechanics") end)
    local bp = v and v:getPartById("BrakeRearLeft")
    local ut = bp and bp:getTable("uninstall")
    say("brake card: verbs " .. table.concat(vb, ", ") .. " | Basic Mechanics known " .. tostring(known) .. " | uninstall table: recipes " .. tostring(ut and ut.recipes) .. ", skills " .. tostring(ut and ut.skills) .. ", requireUninstalled " .. tostring(ut and ut.requireUninstalled))
    check(z ~= nil, "a brake's card shows the step before (take the tire off first) with its button")
    shot("6_card_brake_step")
    press(z)
end)
step(20, function()
    check(S() and S().card == "TireRearLeft", "the step before's button opens that part's card (" .. tostring(S() and S().card) .. ")")
end)
-- ---- a real uninstall and install, the card staying on the part
step(10, function() press(zone("mech:row:TireRearRight")) end)
step(20, function()
    press(zone("mech:verb:uninstall"))
end)
step(15, function() local y = zone("mech:confirm:yes"); if y then press(y) end end)
waitFor(30, 3600, function() local t = v and v:getPartById("TireRearRight"); return t and t:getInventoryItem() == nil and not ISTimedActionQueue.isPlayerDoingAction(p) end, function()
    local t = v and v:getPartById("TireRearRight")
    check(t and t:getInventoryItem() == nil, "Uninstall from the footer takes the rear right tire off for real")
    check(S() and S().card == "TireRearRight", "the card stays on the part after the uninstall")
    shot("7_after_uninstall")
end)
step(30, function()
    local z = zone("mech:verb:install")
    check(z and not z.disabled, "Install is lit on the missing tire's card")
    press(z)
end)
step(15, function() local y = zone("mech:confirm:yes"); if y then press(y) end end)
waitFor(30, 3600, function() local t = v and v:getPartById("TireRearRight"); return t and t:getInventoryItem() ~= nil and not ISTimedActionQueue.isPlayerDoingAction(p) end, function()
    local t = v and v:getPartById("TireRearRight")
    check(t and t:getInventoryItem() ~= nil, "Install from the footer puts it back for real")
    check(S() and S().card == "TireRearRight", "the card stays on the part after the install")
end)
-- ---- A and B through the controller's elements
step(20, function()
    local s, w = S(), W()
    if s and s.card then press(zone("mech:row:" .. s.card)) end
end)
step(20, function()
    local w = W()
    local row
    for _, e in ipairs(MT.buildFocusables(w)) do if e.id == "mech:row:EngineDoor" or (not row and e.id:sub(1, 9) == "mech:row:") then row = e end end
    if row then row.onActivate() end
    say("A on " .. tostring(row and row.id))
end)
step(20, function()
    local s, w = S(), W()
    check(s and s.card ~= nil, "A on a row opens its card (" .. tostring(s and s.card) .. ")")
    local b
    for _, e in ipairs(MT.buildFocusables(w)) do if e.onCancel then b = e end end
    if b then b.onCancel() end
end)
step(20, function() check(S() and S().card == nil, "B closes the card") end)

-- ---- the trailer
step(10, function()
    local sq
    for r = 5, 12 do
        if not sq then
            for _, o in ipairs({ { r, 0 }, { -r, 0 }, { 0, r }, { 0, -r } }) do
                local c = getCell():getGridSquare(math.floor(p:getX()) + o[1], math.floor(p:getY()) + o[2], 0)
                if not sq and c and c:isFree(false) and not c:getVehicleContainer() and c:isOutside() then sq = c end
            end
        end
    end
    trailer = sq and addVehicleDebug("Base.Trailer_Livestock", IsoDirections.N, nil, sq) or nil
    say("trailer " .. tostring(trailer ~= nil))
end)
step(60, function()
    if not trailer then return end
    local sq = trailer:getSquare()
    for _, kind in ipairs({ "ewe", "ram", "lamb", "hen" }) do
        local def = AnimalDefinitions.getDef(kind)
        local a = def and addAnimal(getCell(), sq:getX(), sq:getY(), 0, kind, def:getBreeds():get(0))
        if a then trailer:addAnimalInTrailer(a); animals[#animals + 1] = a end
    end
    say("animals in the trailer: " .. trailer:getAnimals():size())
    pcall(function() MT.openTrailer(p, trailer) end)
end)
waitFor(30, 1800, function() local s = S(); local e = s and s.vehicles and s.vehicles[s.idx]; return e and e.vehicle == trailer end, function()
    local s = S()
    local o = rowOrder()
    say("trailer rows: " .. table.concat(o, ", "))
    local over = {}
    for _, z in ipairs(s.zones or {}) do
        if not z.footer and z.pane ~= "right" and s.splitX and z.x < s.splitX and z.x + z.w > s.splitX + 1 then over[#over + 1] = z.id end
    end
    check(#over == 0, "the trailer's rows, animals included, fit the list column" .. (#over > 0 and (" (over: " .. table.concat(over, ", ") .. ")") or ""))
    shot("8_trailer")
end)

-- ---- put back
step(20, function()
    pcall(function() if ZeD_WorldWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end end)
    if trailer then
        pcall(function() local l = trailer:getAnimals(); while l:size() > 0 do trailer:removeAnimalFromTrailer(l:get(0)) end end)
        for _, a in ipairs(animals) do pcall(function() a:removeFromWorld(); a:removeFromSquare() end) end
        pcall(function() trailer:permanentlyRemove() end)
    end
    if v then pcall(function() v:permanentlyRemove() end) end
    for _, it in ipairs(made) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    p:setPerkLevelDebug(Perks.Mechanics, mechWas)
    if not knewRecipe then pcall(function() p:getKnownRecipes():remove("Basic Mechanics") end) end
    say("put back: car, trailer, " .. #animals .. " animals, " .. #made .. " items taken away; Mechanics " .. p:getPerkLevel(Perks.Mechanics))
    if fails == 0 then say("summary: all " .. passes .. " PASS") else say("summary: " .. fails .. " of " .. (passes + fails) .. " checks FAIL") end
end)
step(20, function() say("DONE") end)

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
