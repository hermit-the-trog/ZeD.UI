-- ZeDUI/tools/qa/zedqa_summercar.lua  (Nov 12 2026, Build, punch list 177): Maskarad's Summer Car's engine window beside
-- ZeD's Vehicle tab (ModSupport/MaskaradsSummerCar.lua), in the game with the mod on. Modeled on QA's zedqa_msc_run1.lua.
-- A plain car with its key on the drag strip; the World window's halves unpinned for the run and put back after.
--   A setup | B auto-open beside | C stays (the reported bug) | D hold and fold | E the player's close lasts
--   F part menu | G footer | H hood | I another car | J rolled | K closed | L tile band | M wheels | N lift | O pad | P put back
-- Needs release_check_mouse.ps1 running (batch_summercar.ps1 starts it). grep "ZEDQA sc"; shots zqa_sc_*.png.
-- Unattended-safe: it removes what it adds. Never while the director uses the machine.
local function say(s) print("ZEDQA sc " .. tostring(s)) end
local p = getPlayer()
local pn = p:getPlayerNum()
local MT = ZeD and ZeD.MechanicsTab
local S = ZeD and ZeD.ModSupport and ZeD.ModSupport.MaskaradsSummerCar
if ZEDQA_HOME then ZEDQA_HOME("sc") end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_sc_" .. n .. ".png") end); say("shot " .. n) end
local function Wn() return ZeD_WorldWindow.getWindow() end
local function St() local w = Wn(); return w and MT and MT.getState(w) end
local function now() return getTimestampMs() end
if getGameSpeed() <= 0 then setGameSpeed(1) end
local v, v2, key, key2
local saved = {}

-- ---- sequencer: a step is fn() -> true when finished (polled each tick), with a time cap
local Q, qi, qstart = {}, 0, 0
local function add(name, fn, cap) Q[#Q + 1] = { n = name, fn = fn, cap = cap or 0 } end
local function wait(ms) local t0; add("wait " .. ms, function() t0 = t0 or now(); if now() - t0 >= ms then t0 = nil; return true end return false end) end

-- ---- the real mouse / keyboard helper (zedqa_click.txt, as zedqa_msc_run1.lua)
local function req(line)
    pcall(function() local fw = getFileWriter("zedqa_click_done.txt", true, false); fw:write(""); fw:close() end)
    pcall(function() local f = getFileWriter("zedqa_click.txt", true, false); f:write(line); f:close() end)
end
local function reqDone()
    local r = getFileReader("zedqa_click_done.txt", false); local l = r and r:readLine(); if r then r:close() end
    return l ~= nil and l:find("done", 1, true) ~= nil
end
local function realClick(kind, x, y, nm)
    local sent = false
    add(nm or "click", function()
        if not sent then sent = true; req(kind .. " " .. math.floor(x()) .. " " .. math.floor(y())); return false end
        if reqDone() then sent = false; return true end
        return false
    end, 15000)
end
local function realMove(x, y, nm) realClick("move", x, y, nm) end

-- ---- the engine window
local function eng() local W = MSC and MSC.EngineComponentsWindow; return W and W.instances[pn] end
local function engLine(tag)
    local e = eng()
    if not e then say(tag .. ": no engine window"); return nil end
    local w = Wn()
    say(string.format("%s: engine window %d,%d %dx%d anchored=%s vehicle=%s | World window %s", tag,
        math.floor(e:getX()), math.floor(e:getY()), math.floor(e:getWidth()), math.floor(e:getHeight()),
        tostring(S and e.mechanicsUI == S.standIn(pn)), tostring(e.vehicle == v and "v" or (e.vehicle == v2 and "v2" or tostring(e.vehicle))),
        w and (math.floor(w:getX()) .. "," .. math.floor(w:getY()) .. " " .. math.floor(w:getWidth()) .. "x" .. math.floor(w:getHeight())) or "closed"))
    return e
end
local function expect(tag, ok, detail) say((ok and "PASS " or "ERR ") .. tag .. (detail and (" (" .. tostring(detail) .. ")") or "")) end
local function placedOk(tag)
    local e, w = eng(), Wn()
    if not (e and w) then expect(tag .. ": placed beside", false, "no window"); return end
    local fx, fy, fw = S.footprint(w)
    local ex, ew = e:getX(), e:getWidth()
    local clear = ex + ew <= fx - 9 or ex >= fx + fw + 9
    expect(tag .. ": no horizontal overlap with the World window, the mod's gap", clear, ex .. "+" .. ew .. " vs " .. fx .. "+" .. fw)
    expect(tag .. ": top level with the World window", math.abs(e:getY() - math.max(10, fy)) < 1, e:getY())
    expect(tag .. ": on screen", ex >= 0 and ex + ew <= sw and e:getY() + e:getHeight() <= sh)
end
local function closeCtx()
    pcall(function() local zm = getPlayerContextMenu(pn); if zm and zm._zedMenu and zm._zedMenu.close then zm._zedMenu:close() end end)
    pcall(function() getPlayerContextMenu(pn):setVisible(false) end)
end
local function ctxNames()
    local zm = getPlayerContextMenu(pn)
    local m = zm and zm._zedMenu
    local out = {}
    local ok, items = pcall(function() return m:_currentItems() end)
    for _, it in ipairs(ok and items or {}) do out[#out + 1] = tostring(it.name) end
    return out
end

if not (MT and ZeD_WorldWindow) then say("ERR ZeD's Vehicle tab is not loaded"); say("DONE"); return end

-- ================= A. setup
add("A checks", function()
    if not S then say("ERR ZeD.ModSupport.MaskaradsSummerCar is nil (the support file did not load)") end
    local n = 0
    for k in pairs(S and S.noted or {}) do n = n + 1; say("ERR noted at start: " .. tostring(k)) end
    if not (ZeD.StepAside and ZeD.StepAside.SUPPORTED and ZeD.StepAside.SUPPORTED.MaskaradsSummerCar) then
        say("ERR StepAside's SUPPORTED lacks MaskaradsSummerCar")
    end
    if S then say("startup line ok=" .. tostring(S.check())) end
    return true
end)
add("A spawn", function()
    local sqs = { { 4, 0 }, { -4, 0 }, { 0, 4 }, { 0, -4 }, { 5, 3 } }
    for _, o in ipairs(sqs) do
        local sq = getCell():getGridSquare(math.floor(p:getX()) + o[1], math.floor(p:getY()) + o[2], 0)
        local free = false
        if sq then pcall(function() free = sq:isFree(false) and not sq:HasTree() and not sq:getVehicleContainer() end) end
        if free and not v then v = addVehicleDebug("Base.CarNormal", IsoDirections.N, nil, sq)
        elseif free and v and not v2 then v2 = addVehicleDebug("Base.CarNormal", IsoDirections.N, nil, sq) end
    end
    if not v then say("ERR no free square for the car"); return true end
    pcall(function() key = p:getInventory():AddItem(v:createVehicleKey()) end)
    pcall(function() if v2 then key2 = p:getInventory():AddItem(v2:createVehicleKey()) end end)
    say("cars " .. tostring(v ~= nil) .. " " .. tostring(v2 ~= nil))
    return true
end)
wait(5000)
add("A windows", function()
    if not ZeD_WorldWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
    return true
end)
wait(1500)
add("A save and unpin", function()
    local w = Wn()
    if not w then say("ERR no World window"); return true end
    local md = p:getModData()
    local ws = md.ZeD_WinState and md.ZeD_WinState.world
    if ws then saved.state = {}; for k, val in pairs(ws) do saved.state[k] = val end end
    saved.x, saved.y = w:getX(), w:getY()
    local hs = w._halves
    saved.inv, saved.drawer, saved.both = hs and hs.inv.pinned, hs and hs.drawer.pinned, w.pinned
    -- (Nov 12 2026: the drawer half stays pinned: unpinned it rolls up after 2 s and hides the engine window by design,
    -- which read as "no engine window" in steps B, C and E)
    if hs then hs.inv.pinned, hs.drawer.pinned = false, true end
    w.pinned = false
    pcall(ZeD_WorldWindow.openTab, 0, "vehicle")
    return true
end)
wait(1500)

-- ================= B. auto-open beside
add("B onMechanic", function() if v then ISVehicleMenu.onMechanic(p, v) end; return true end)
local inspAt
add("B wait inspected", function()
    if MT.isInspected(v) then inspAt = inspAt or now() end
    return inspAt ~= nil and eng() ~= nil
end, 70000)
add("B report", function()
    say("engine window " .. tostring(eng() ~= nil) .. " " .. tostring(inspAt and (now() - inspAt)) .. " ms after the inspection")
    local e = engLine("B opened")
    if e then
        expect("B: anchored to the tab, for this car", e.mechanicsUI == S.standIn(pn) and e.vehicle == v)
        saved.winX = Wn():getX()
        placedOk("B")
    end
    shot("B_opened")
    return true
end)
wait(1500)
add("B ZeD's window still", function()
    local w = Wn()
    expect("B: the World window not moved", w and w:getX() == saved.winX, w and w:getX())
    local ws = p:getModData().ZeD_WinState and p:getModData().ZeD_WinState.world
    say("B saved x now " .. tostring(ws and ws.x))
    return true
end)

-- ================= C. stays (the reported bug)
wait(5000)
add("C stays", function() expect("C: still open 5 s later", eng() ~= nil); engLine("C"); shot("C_stays"); return true end)

-- ================= D. hold and fold (the real cursor)
realMove(function() local e = eng(); return e and e:getX() + 40 or 100 end, function() local e = eng(); return e and e:getY() + 120 or 100 end, "D pointer on the engine window")
wait(4000)
add("D held", function()
    expect("D: the pointer on the engine window holds the tab", ZeD_WorldWindow.isTabShowing("vehicle", pn) and eng() ~= nil)
    return true
end)
realMove(function() return math.floor(sw / 2) end, function() return math.floor(sh * 0.75) end, "D pointer on the world")
wait(3500)
add("D folded", function()
    say("D after 3.5 s in the world: tab showing " .. tostring(ZeD_WorldWindow.isTabShowing("vehicle", pn)) .. " engine window " .. tostring(eng() ~= nil))
    expect("D: the engine window went with the tab", ZeD_WorldWindow.isTabShowing("vehicle", pn) or eng() == nil)
    shot("D_folded")
    return true
end)
add("D tab back", function() pcall(ZeD_WorldWindow.openTab, 0, "vehicle"); return true end)
wait(1200)
add("D back", function() expect("D: a fold's close is not the player's: it comes back with the tab", eng() ~= nil); return true end)

-- ================= E. the player's close lasts
realMove(function() local e = eng(); return e and e:getX() + 40 or 100 end, function() local e = eng(); return e and e:getY() + 120 or 100 end, "E pointer on")
add("E close", function()
    local e = eng()
    if e then pcall(function() e:close() end) end      -- (the title-bar X runs close() with no argument)
    return true
end)
wait(2000)
add("E stays shut", function() expect("E: closed by the player and still shut 2 s later", eng() == nil); return true end)
add("E loot", function() pcall(ZeD_WorldWindow.openTab, 0, "loot"); return true end)
wait(1000)
add("E vehicle", function() pcall(ZeD_WorldWindow.openTab, 0, "vehicle"); return true end)
wait(1500)
add("E still shut", function() expect("E: Loot and back: still shut (the player's close lasts)", eng() == nil); shot("E_shut"); return true end)

-- ================= F. part menu (the real right-click)
local engRow
add("F find row", function()
    local s = St()
    for _, r in ipairs(s and s.lastRows or {}) do if r.part == "Engine" then engRow = r end end
    say("F engine row " .. tostring(engRow ~= nil))
    return true
end)
realClick("right", function() local s = St(); return (engRow and s and s.panel) and (s.panel:getAbsoluteX() + engRow.x + math.min(engRow.w / 2, 200)) or 100 end,
    function() local s = St(); return (engRow and s and s.panel) and (s.panel:getAbsoluteY() + engRow.y + engRow.h / 2) or 100 end, "F right-click Engine")
wait(900)
local inspOpt
add("F menu", function()
    local names = table.concat(ctxNames(), " | ")
    say("F ZeD's cells: " .. names)
    expect("F: Inspect engine components", names:find(getText("UI_MSC_InspectEngineComponents"), 1, true) ~= nil)
    expect("F: no Take engine parts / Repair engine", not names:find(getText("IGUI_TakeEngineParts"), 1, true) and not names:find(getText("IGUI_RepairEngine"), 1, true))
    local ui = getPlayerMechanicsUI(pn)
    for _, o in ipairs(ui and ui.context and ui.context.options or {}) do
        if o.name == getText("UI_MSC_InspectEngineComponents") then inspOpt = o end
    end
    expect("F: the option points at the anchor, no pad grab", inspOpt and inspOpt.param2 == S.standIn(pn) and inspOpt.param3 == true)
    shot("F_menu")
    return true
end)
add("F pick", function()
    if inspOpt then pcall(function() inspOpt.onSelect(inspOpt.target, inspOpt.param1, inspOpt.param2, inspOpt.param3) end) end
    closeCtx()
    return true
end)
wait(1000)
add("F opened", function() expect("F: picking it opens beside, anchored", eng() ~= nil and eng().mechanicsUI == S.standIn(pn)); placedOk("F"); return true end)
wait(5000)
add("F stays", function() expect("F: and stays 5 s", eng() ~= nil); return true end)

-- ================= G. footer
add("G footer", function()
    local s = St()
    local w = Wn()
    pcall(function() s.card = "Engine" end)
    return true
end)
wait(800)
add("G zones", function()
    local s = St()
    local ids = {}
    for _, z in ipairs(s and s.zones or {}) do ids[z.id] = true end
    expect("G: the footer holds Inspect engine components", ids["mech:verb:mscInspect"] == true)
    expect("G: and not Repair engine / Take engine parts", not ids["mech:verb:repairEngine"] and not ids["mech:verb:takeParts"])
    local e = eng(); if e then pcall(function() e:close() end) end
    shot("G_footer")
    return true
end)
wait(800)
local verbZ
add("G find verb", function() local s = St(); verbZ = s and s.byId and s.byId["mech:verb:mscInspect"]; return true end)
realClick("left", function() local s = St(); return (verbZ and s.panel) and (s.panel:getAbsoluteX() + verbZ.x + verbZ.w / 2) or 100 end,
    function() local s = St(); return (verbZ and s.panel) and (s.panel:getAbsoluteY() + verbZ.y + verbZ.h / 2) or 100 end, "G press the verb")
wait(1000)
add("G opened", function() expect("G: the footer verb opens it beside", eng() ~= nil); placedOk("G"); return true end)

-- ================= H. hood
add("H close hood", function()
    local hood = v:getPartById("EngineDoor")
    pcall(function() ISTimedActionQueue.add(ISCloseVehicleDoor:new(p, v, hood)) end)
    return true
end)
add("H wait shut", function() local d = v:getPartById("EngineDoor"):getDoor(); return d and not d:isOpen() end, 20000)
wait(500)
add("H closed", function()
    expect("H: the hood shut closes the engine window", eng() == nil)
    local s = St()
    local ok, n = pcall(MT._test.needsFor, s, v:getPartById("Engine"), "mscInspect", p, v)
    expect("H: the verb's line is the mod's sentence", ok and n and n.line == getText("UI_MSC_HoodMustBeOpen"), ok and n and n.line)
    shot("H_hood_closed")
    return true
end)
add("H open hood", function()
    pcall(function() ISTimedActionQueue.add(ISOpenVehicleDoor:new(p, v, v:getPartById("EngineDoor"))) end)
    return true
end)
add("H wait open", function() local d = v:getPartById("EngineDoor"):getDoor(); return d and d:isOpen() end, 20000)
wait(1500)
add("H back", function() expect("H: the hood open again: it opens again by itself", eng() ~= nil); return true end)

-- ================= I. another car
add("I second car", function()
    if not v2 then say("I skipped: no second car"); return true end
    ISVehicleMenu.onMechanic(p, v2)
    return true
end)
add("I wait", function() return not v2 or (MT.isInspected(v2) and eng() and eng().vehicle == v2) end, 70000)
add("I check", function() if v2 then expect("I: one window, for the second car", eng() and eng().vehicle == v2); engLine("I") end; return true end)

-- ================= J. rolled to the title bar
add("J shade", function() local w = Wn(); if w then w:setWindowShaded(true) end; return true end)
wait(200)
add("J shut", function() expect("J: rolled: the engine window closes", eng() == nil); return true end)
add("J unshade", function() local w = Wn(); if w then w:setWindowShaded(false) end; return true end)
wait(1500)
add("J back", function() expect("J: unrolled: back by itself", eng() ~= nil); return true end)

-- ================= K. the World window closed
add("K close", function() ZeD_WorldWindow.close(0); return true end)
wait(300)
add("K shut", function() expect("K: the World window closed: the engine window closes", eng() == nil); return true end)
add("K reopen", function() pcall(ZeD_WorldWindow.openTab, 0, "vehicle"); return true end)
wait(2000)
add("K back", function() expect("K: reopened on the Vehicle tab: back", eng() ~= nil); return true end)

-- ================= L. the tile band (this screen's)
add("L move", function()
    local w = Wn()
    local e = eng(); if e then pcall(function() e:close(false) end) end
    if not w then return true end
    local tx = (sw >= 3000) and math.floor((sw - w:getWidth()) / 2) or ((sw >= 1900) and 498 or 320)
    say("L the World window to x=" .. tx)
    w:setX(tx)
    saved.tileX = w:getX()
    return true
end)
wait(1500)
add("L check", function()
    local w = Wn()
    engLine("L")
    expect("L: ZeD's window stays where it was put", w and w:getX() == saved.tileX, w and w:getX())
    local e = eng()
    if e then
        local fx, _, fw = S.footprint(w)
        local clear = e:getX() + e:getWidth() <= fx or e:getX() >= fx + fw
        expect("L: beside, or 420 wide at x 10 over the inventory side", clear or (e:getX() == 10 and e:getWidth() == 420))
    end
    shot("L_tile")
    if saved.x then w:setX(saved.x); w:setY(saved.y) end
    return true
end)
wait(800)

-- ================= M. wheels (outside; seated with the ECU forced)
add("M outside", function()
    pcall(function() ISVehicleMenu.showRadialMenu(p) end)
    return true
end)
wait(700)
add("M list", function()
    local m = getPlayerRadialMenu(pn)
    local t = {}
    for i, s in ipairs(m.slices or {}) do t[#t + 1] = i .. ":" .. tostring(s.text) end
    say("M outside wheel: " .. table.concat(t, "  "))
    pcall(function() m:undisplay() end)
    return true
end)

-- ================= N. lift (staging: the mod's lift columns beside the engine end)
local liftObjs = {}
add("N stage", function()
    local ok, err = pcall(function()
        local sq1 = getCell():getGridSquare(math.floor(v:getX()) + 2, math.floor(v:getY()) - 2, 0)
        local sq2 = getCell():getGridSquare(math.floor(v:getX()) - 2, math.floor(v:getY()) - 2, 0)
        for i, sq in ipairs({ sq1, sq2 }) do
            local o = IsoObject.new(getCell(), sq, i == 1 and "location_business_machinery_01_0" or "location_business_machinery_01_2")
            sq:AddTileObject(o)
            liftObjs[#liftObjs + 1] = { sq = sq, o = o }
        end
    end)
    say("N lift staged ok=" .. tostring(ok) .. (ok and "" or (" " .. tostring(err))))
    return true
end)
realClick("right", function() local s = St(); return (engRow and s and s.panel) and (s.panel:getAbsoluteX() + engRow.x + math.min(engRow.w / 2, 200)) or 100 end,
    function() local s = St(); return (engRow and s and s.panel) and (s.panel:getAbsoluteY() + engRow.y + engRow.h / 2) or 100 end, "N right-click Engine")
wait(900)
add("N menu", function() say("N ZeD's cells: " .. table.concat(ctxNames(), " | ")); shot("N_lift_menu"); closeCtx(); return true end)

-- ================= O. controller (only with a pad attached)
add("O pad", function()
    if not JoypadState.players[pn + 1] then say("O skipped: no pad (the sim proves the hand-back)"); return true end
    local e = eng(); if e then pcall(function() e:close() end) end
    return true
end)
wait(200)
add("O focus", function()
    if JoypadState.players[pn + 1] then expect("O: the pad is not left with the anchor", getJoypadFocus(pn) ~= S.standIn(pn)) end
    return true
end)

-- ================= P. put back
add("P put back", function()
    local e = eng(); if e then pcall(function() e:close(false) end) end
    closeCtx()
    for _, l in ipairs(liftObjs) do pcall(function() l.sq:RemoveTileObject(l.o) end) end
    pcall(function() ISTimedActionQueue.clear(p) end)
    pcall(function() if v then v:permanentlyRemove() end end)
    pcall(function() if v2 then v2:permanentlyRemove() end end)
    pcall(function() if key then p:getInventory():Remove(key) end end)
    pcall(function() if key2 then p:getInventory():Remove(key2) end end)
    local w = Wn()
    if w then
        if saved.x then w:setX(saved.x); w:setY(saved.y) end
        local hs = w._halves
        if hs then hs.inv.pinned, hs.drawer.pinned = saved.inv, saved.drawer end
        w.pinned = saved.both
    end
    if saved.state then
        local md = p:getModData()
        md.ZeD_WinState = md.ZeD_WinState or {}
        md.ZeD_WinState.world = saved.state
    end
    local n = 0
    for k in pairs(S and S.noted or {}) do n = n + 1; say("ERR noted: " .. tostring(k)) end
    say("put back; Summer Car notes " .. n)
    return true
end)
wait(500)
add("done", function() say("DONE"); return true end)

-- ================= run
local function tick()
    if qi == 0 then qi = 1; qstart = now() end
    local st = Q[qi]
    if not st then Events.OnTick.Remove(tick); return end
    local ok, r = pcall(st.fn)
    if not ok then say("ERR step '" .. st.n .. "': " .. tostring(r)); r = true end
    if not r and st.cap > 0 and now() - qstart > st.cap then say("ERR step '" .. st.n .. "' timed out"); r = true end
    if r then qi = qi + 1; qstart = now() end
end
Events.OnTick.Add(tick)
say("start (" .. #Q .. " steps)")
