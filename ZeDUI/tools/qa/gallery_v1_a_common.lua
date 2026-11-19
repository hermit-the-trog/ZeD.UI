-- ZeDUI/tools/qa/gallery_v1_a_common.lua  (Nov 17 2026, QA): shared helpers for the ZeD-GUI 1.0 gallery captures
-- (ZeDUI/HANDOFF_design_gallery_v1_20261117.md, "For QA: the shot list"). Runs in BOTH runs (ZeD on and ZeD off):
-- it never calls ZeD unless ZeD is loaded. Run after gallery_story_stage.lua and gallery_unload.lua, before
-- gallery_v1_a_zed.lua or gallery_v1_a_van.lua. Defines the global G1:
--   G1.make(tag)        a step queue on Events.OnPreUIDraw (step, waitFor, still, start; say tagged "ZEDQA <tag>")
--   Q.shot(name)        the gallery rule first (invisible off, god mode off, zombies-don't-attack on, debug console
--                       hidden, menus closed, pointer parked and hidden), then getCore():TakeFullScreenshot(name .. ".png"),
--                       then the load line (GAL_UNLOAD) and every visible window's box, with a "COVERS the character"
--                       note for any box over the character's screen rect
--   G1.charRect()       the character's rect on the screen (isoToScreenX / Y, else the screen centre)
--   G1.clear(win, side) moves a window that covers the character to the left or right edge (logged)
--   G1.shelf / G1.fillShelf / G1.shelfBack: picture 17's container, one Fossoil shelf by the stock spot, emptied
--                       (what was in it kept) and filled with the same ten things in both runs; put back after
--   G1.wound(on)        picture 26's bandaged scratch on the left forearm; off takes it away
-- The same staging in both runs: the story stage (Angel at the Fossoil, West Point), the same spots (STORY.P), the
-- same shelf (nearest the stock spot, ties to the smaller x then y), the same things. grep "ZEDQA g1c".
G1 = G1 or {}
G1.p = getPlayer()
G1.pn = G1.p:getPlayerNum()
G1.core = getCore()
G1.zed = (ZeD and ZeD_CharacterWindow and ZeD_WorldWindow) and true or false
G1.SHELF_ITEMS = { "Base.Pop", "Base.Pop", "Base.Pop2", "Base.Crisps", "Base.Chocolate", "Base.CandyPackage", "Base.Gum",
                   "Base.CigaretteCarton", "Base.WaterBottle", "Base.Peanuts" }
function G1.log(s) print("ZEDQA g1c " .. tostring(s)) end

-- ===================================================================== the queue
function G1.make(tag)
    local Q = { tag = tag, list = {}, qi = 1, wait = nil, t0 = getTimestampMs(), maxMs = 1500000, nOk = 0, nErr = 0 }
    function Q.say(s) print("ZEDQA " .. Q.tag .. " " .. tostring(s)) end
    function Q.step(n, fn) Q.list[#Q.list + 1] = { n = n, fn = fn } end
    -- after n frames, every frame until cond() (at most max frames), then fn(ok)
    function Q.waitFor(n, max, cond, fn) Q.list[#Q.list + 1] = { n = n, fn = fn, cond = cond, max = max } end
    -- the windows the same for 30 frames (at most 900), then fn
    function Q.still(n, fn)
        local st = { last = nil, same = 0 }
        Q.waitFor(n, 900, function()
            local s = G1.shape()
            if s == st.last then st.same = st.same + 1 else st.last, st.same = s, 0 end
            return st.same >= 30
        end, fn)
    end
    function Q.zoomTo(z)
        local st = { left = nil }
        Q.step(40, function() end)
        Q.waitFor(20, 1200, function()
            if st.left == nil then st.left = math.floor((G1.core:getZoom(0) - z) / 0.25 + 0.5) end
            if st.left == 0 then return true end
            G1.core:doZoomScroll(0, (st.left > 0) and -1 or 1)
            st.left = (st.left > 0) and (st.left - 1) or (st.left + 1)
            return st.left == 0
        end, function() end)
        Q.step(100, function() Q.say("zoom " .. tostring(G1.core:getZoom(0))) end)
    end
    function Q.shot(name, keepMenu)
        G1.clean(Q)
        if not keepMenu then G1.closeMenus() end
        G1.hidePointer()
        local ok, e = pcall(function() G1.core:TakeFullScreenshot(name .. ".png") end)
        if ok then Q.nOk = Q.nOk + 1; Q.say("shot " .. name) else Q.nErr = Q.nErr + 1; Q.say("ERR shot " .. name .. ": " .. tostring(e)) end
        Q.say("load " .. name .. ": " .. ((GAL_UNLOAD and GAL_UNLOAD.line) and GAL_UNLOAD.line() or "(gallery_unload.lua did not run)"))
        local ec = "?"
        pcall(function() ec = tostring(getLuaDebuggerErrorCount()) end)
        Q.say("eyes " .. name .. ": " .. G1.eyesLine() .. " | errors so far " .. ec)
        G1.boxes(Q, name)
    end
    function Q.notTaken(name, why) Q.nErr = Q.nErr + 1; Q.say("not taken: " .. name .. " (" .. tostring(why) .. ")") end
    function Q.tick()
        local s = Q.list[Q.qi]
        if not s then Events.OnPreUIDraw.Remove(Q.tick); return end
        if Q.qi < #Q.list and getTimestampMs() - Q.t0 > Q.maxMs then
            Q.say("ERR ran too long at step " .. Q.qi .. ": jumping to the put-back")
            Q.qi = Q.backAt or #Q.list
            Q.wait = nil
            return
        end
        if not s.started then
            Q.wait = (Q.wait or s.n) - 1
            if Q.wait > 0 then return end
            Q.wait = nil
            s.started = true
        end
        local res = true
        if s.cond then
            s.left = (s.left or s.max) - 1
            local okc, done = pcall(s.cond)
            res = (okc and done) and true or false
            if not res and s.left > 0 then return end
            if not res then Q.say("note: step " .. Q.qi .. " waited " .. s.max .. " frames, went on") end
        end
        Q.qi = Q.qi + 1
        local ok, err = pcall(s.fn, res)
        if not ok then Q.say("ERR step " .. (Q.qi - 1) .. ": " .. tostring(err)) end
    end
    -- mark(): the put-back starts here (a run that takes too long jumps to it)
    function Q.mark() Q.backAt = #Q.list + 1 end
    function Q.start()
        Q.step(2, function() Q.say(string.format("end: %d shots, %d not taken or failed", Q.nOk, Q.nErr)); Q.say("DONE") end)
        Events.OnPreUIDraw.Add(Q.tick)
        Q.say("start (" .. #Q.list .. " steps)")
    end
    return Q
end

-- ===================================================================== the gallery rule
function G1.clean(Q)
    pcall(function() G1.p:setInvisible(false) end)
    pcall(function() G1.p:setGodMod(false) end)
    pcall(function() G1.p:setZombiesDontAttack(true) end)
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false) end
        end
    end)
    G1.hideErrors(Q)
    G1.hideWatermark(Q)
    G1.glasses(Q)
    G1.noPain()
    -- the search overlay (it blurs everything outside a ring round the character): off, as the story stage does
    pcall(function() STORY.noSearch() end)
end
-- the game's build line ("42.22.2 <sha> pzBullet(...)", bottom right): vanilla's own WaterMarkUI panel
-- (ISVersionWaterMark.lua) hidden; G1.showWatermark (gallery_v1_a_end.lua) shows it again. No ZeD calls.
function G1.hideWatermark(Q)
    G1.wmHidden = G1.wmHidden or {}
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            local t = nil
            pcall(function() t = e:getTable() end)
            if t and t.Type == "WaterMarkUI" and e:isVisible() then
                e:setVisible(false)
                G1.wmHidden[#G1.wmHidden + 1] = e
                if Q then Q.say("hid the game's build line (WaterMarkUI)") end
            end
        end
    end)
end
function G1.showWatermark()
    for _, e in ipairs(G1.wmHidden or {}) do pcall(function() e:setVisible(true) end) end
    G1.wmHidden = {}
end
-- the debug build's red "Error / N errors" box (bottom right): any visible UI element whose Java class or Lua Type
-- has "rror" in it is hidden (kept in G1.errHidden, shown again by G1.showErrors). The first time, every visible
-- element in the bottom-right quarter is logged by name, so the box's class is on record if it is not caught.
function G1.hideErrors(Q)
    G1.errHidden = G1.errHidden or {}
    local W, H = G1.core:getScreenWidth(), G1.core:getScreenHeight()
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            local cls = tostring(e:getClass():getSimpleName())
            local typ = ""
            pcall(function() local t = e:getTable(); if t and t.Type then typ = tostring(t.Type) end end)
            if e:isVisible() then
                if not G1.errListed and Q and e:getX() >= W / 2 and e:getY() >= H / 2 then
                    Q.say(string.format("bottom-right element %s / %s at %d,%d %dx%d", cls, typ, e:getX(), e:getY(), e:getWidth(), e:getHeight()))
                end
                if cls:find("rror", 1, true) or typ:find("rror", 1, true) then
                    e:setVisible(false)
                    G1.errHidden[#G1.errHidden + 1] = e
                    if Q then Q.say("hid the error box: " .. cls .. " / " .. typ) end
                end
            end
        end
    end)
    G1.errListed = true
end
function G1.showErrors()
    for _, e in ipairs(G1.errHidden or {}) do pcall(function() e:setVisible(true) end) end
    G1.errHidden = {}
end
-- the QA character is short-sighted: prescription glasses must be worn for every shot (else the world blurs). The story
-- stage wears Glasses_Prescription_Aviators; if no prescription pair is on, one is put on (kept in G1.glassesAdded)
function G1.glassesOn()
    local on = nil
    pcall(function()
        local wi = G1.p:getWornItems()
        for i = 0, wi:size() - 1 do
            local it = wi:get(i):getItem()
            if it and tostring(it:getFullType()):find("Glasses_Prescription", 1, true) then on = it end
        end
    end)
    return on
end
function G1.shortSighted()
    local ss = false
    pcall(function() ss = G1.p:getCharacterTraits():get(CharacterTrait.SHORT_SIGHTED) == true end)
    return ss
end
function G1.glasses(Q)
    local on = G1.glassesOn()
    if not G1.shortSighted() then
        -- prescription glasses blur the world for a character who is not short-sighted: take any worn pair off
        if on then
            G1.glassesStripped = G1.glassesStripped or {}
            G1.glassesStripped[#G1.glassesStripped + 1] = on
            pcall(function() G1.p:removeWornItem(on, false) end)
            pcall(function() triggerEvent("OnClothingUpdated", G1.p) end)
            if Q then Q.say("short sighted false, prescription glasses off (took off " .. tostring(on:getFullType()) .. ")") end
        elseif Q then Q.say("short sighted false, prescription glasses off") end
        return true
    end
    if on then return true end
    local g = nil
    pcall(function() g = G1.p:getInventory():AddItem("Base.Glasses_Prescription_Aviators") end)
    if not g then pcall(function() g = G1.p:getInventory():AddItem("Base.Glasses_Prescription") end) end
    if not g then if Q then Q.say("ERR no prescription glasses to put on") end; return false end
    local ok = pcall(function() G1.p:setWornItem(g:getBodyLocation(), g) end)
    pcall(function() triggerEvent("OnClothingUpdated", G1.p) end)
    G1.glassesAdded = G1.glassesAdded or {}
    G1.glassesAdded[#G1.glassesAdded + 1] = g
    if Q then Q.say("glasses were off: put on " .. tostring(g:getFullType()) .. " " .. tostring(ok)) end
    return ok
end
function G1.glassesBack(Q)
    for _, g in ipairs(G1.glassesAdded or {}) do
        pcall(function() G1.p:removeWornItem(g, false) end)
        pcall(function() local c = g:getContainer(); if c then c:Remove(g) end end)
    end
    for _, g in ipairs(G1.glassesStripped or {}) do
        pcall(function() G1.p:setWornItem(g:getBodyLocation(), g) end)
    end
    pcall(function() triggerEvent("OnClothingUpdated", G1.p) end)
    if Q then Q.say("glasses put on by the script taken off again: " .. #(G1.glassesAdded or {}) .. ", worn ones put back: " .. #(G1.glassesStripped or {})) end
    G1.glassesAdded = {}
    G1.glassesStripped = {}
end
-- pain off (the scratch's pain and its moodle blur the picture; the wound stays drawn)
function G1.noPain()
    pcall(function() local bp = G1.part(); if bp then bp:setAdditionalPain(0) end end)
    pcall(function() G1.p:getStats():set(CharacterStat.PAIN, 0) end)
    -- (panic with the staged zombies near, and drink, also blur the view: both held at 0 for the shot)
    pcall(function() G1.p:getStats():set(CharacterStat.PANIC, 0) end)
    pcall(function() G1.p:getStats():set(CharacterStat.INTOXICATION, 0) end)
end
-- what can blur the world, logged at every shot: the glasses, the Short Sighted trait, the game's visual-aid read,
-- the search overlay, pain
function G1.eyesLine()
    local g, pain = G1.glassesOn(), "?"
    local E = { ss = "?", aid = "?", srch = "?", ov = "?" }
    pcall(function() pain = string.format("%.2f", G1.p:getStats():get(CharacterStat.PAIN)) end)
    pcall(function() E.ss = tostring(G1.p:getCharacterTraits():get(CharacterTrait.SHORT_SIGHTED)) end)
    pcall(function() E.aid = tostring(G1.p:isWearingVisualAid()) end)
    pcall(function() local sm = getSearchMode(); E.srch = tostring(sm:isEnabled(G1.pn)); E.ov = tostring(sm:isOverride(G1.pn)) end)
    return "glasses " .. tostring(g and g:getFullType()) .. ", short sighted " .. E.ss .. ", visual aid " .. E.aid
        .. ", search overlay " .. E.srch .. " (override " .. E.ov .. "), pain " .. pain .. G1.statLine()
end
function G1.statLine()
    local t = {}
    for _, k in ipairs({ "PANIC", "INTOXICATION", "FATIGUE", "STRESS" }) do
        pcall(function() t[#t + 1] = k:lower() .. " " .. string.format("%.2f", G1.p:getStats():get(CharacterStat[k])) end)
    end
    pcall(function() t[#t + 1] = "view cone " .. tostring(getPerformance():getViewConeOpacity()) end)
    return ", " .. table.concat(t, ", ")
end
-- (ZeD run) the floating XP text muted while the gallery scripts run: setting the skills fires the game's addXp, whose
-- HaloTextHelper.addTextWithArrow (ZeD_HaloText.lua's wrap) logged a Java exception per skill in the first run, and the
-- debug build's error box came up in the shots after. The game's three halo calls are no-ops until
-- gallery_v1_a_end.lua (after gallery_story_teardown.lua, which sets the skills back) puts them back.
function G1.muteHalo()
    local HT = HaloTextHelper
    if not HT or G1.halo then return end
    G1.halo = { arrow = HT.addTextWithArrow, good = HT.addGoodText, bad = HT.addBadText }
    HT.addTextWithArrow = function() end
    HT.addGoodText = function() end
    HT.addBadText = function() end
    G1.log("the floating XP text muted until gallery_v1_a_end.lua")
end
function G1.closeMenus()
    pcall(function() local m = getPlayerContextMenu(G1.pn); if m and m._zedMenu then m._zedMenu:close() end end)
    pcall(function() local m = getPlayerContextMenu(G1.pn); if m and m:isVisible() then m:closeAll() end end)
end
function G1.hidePointer()
    pcall(function() Mouse.setXY(4, G1.core:getScreenHeight() - 4) end)
    pcall(function() Mouse.setCursorVisible(false) end)
end
-- the character on the screen: a rect round the figure (zoom 1 at 4K: about 120 x 300 px)
function G1.charRect()
    local W, H = G1.core:getScreenWidth(), G1.core:getScreenHeight()
    local r = { x = W / 2, y = H / 2 }
    pcall(function()
        local sx = isoToScreenX(G1.pn, G1.p:getX(), G1.p:getY(), G1.p:getZ())
        local sy = isoToScreenY(G1.pn, G1.p:getX(), G1.p:getY(), G1.p:getZ())
        if sx and sy then r.x, r.y = sx, sy end
    end)
    local z = 1
    pcall(function() z = G1.core:getZoom(G1.pn) end)
    if not z or z <= 0 then z = 1 end
    r.x0, r.x1 = math.floor(r.x - 160 / z), math.floor(r.x + 160 / z)
    r.y0, r.y1 = math.floor(r.y - 360 / z), math.floor(r.y + 60 / z)
    return r
end
function G1.covers(win)
    if not (win and win:isVisible()) then return false end
    local r = G1.charRect()
    local x, y, w, h = win:getX(), win:getY(), win:getWidth(), win:getHeight()
    return x < r.x1 and x + w > r.x0 and y < r.y1 and y + h > r.y0
end
-- a window over the character goes to one side (side "left" or "right"); logged both ways
function G1.clear(Q, win, side, label)
    if not (win and win:isVisible()) then return end
    if not G1.covers(win) then return end
    local W = G1.core:getScreenWidth()
    local m = 24
    pcall(function() if ZeD and ZeD.T and ZeD.T.px then m = ZeD.T.px(12) end end)
    local x0 = win:getX()
    local x = (side == "right") and (W - win:getWidth() - m) or m
    win:setX(x)
    if win._anchorRightEdge ~= nil then win._anchorRightEdge = x + win:getWidth() end
    Q.say(string.format("moved %s from x %d to x %d (%s side): it covered the character", tostring(label), x0, x, tostring(side)))
end
-- every visible window this run draws, its box; "COVERS the character" when it does
function G1.wins()
    local out = {}
    if G1.zed then
        local c, w = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
        if c then out[#out + 1] = { "char", c } end
        if w then out[#out + 1] = { "world", w } end
        pcall(function() local L = ZeD.Moodles.getLayer(G1.pn); if L then out[#out + 1] = { "moodles", L } end end)
        pcall(function() local h = ZeD.Belt.getHUD(); if h then out[#out + 1] = { "belt", h } end end)
    end
    pcall(function() local pi = getPlayerInventory(G1.pn); if pi then out[#out + 1] = { "inventory", pi } end end)
    pcall(function() local pl = getPlayerLoot(G1.pn); if pl then out[#out + 1] = { "loot", pl } end end)
    pcall(function() local ip = getPlayerInfoPanel(G1.pn); if ip then out[#out + 1] = { "info", ip } end end)
    pcall(function() local mu = UIManager.getMoodleUI(G1.pn); if mu and not G1.zed then out[#out + 1] = { "moodlesV", mu } end end)
    return out
end
function G1.boxes(Q, name)
    local r = G1.charRect()
    Q.say(string.format("box %s character %d,%d-%d,%d", name, r.x0, r.y0, r.x1, r.y1))
    for _, e in ipairs(G1.wins()) do
        local w = e[2]
        local vis = false
        pcall(function() vis = w:isVisible() and w:getWidth() > 0 end)
        if vis then
            Q.say(string.format("box %s %s %d,%d-%d,%d%s", name, e[1], w:getX(), w:getY(), w:getX() + w:getWidth(), w:getY() + w:getHeight(),
                (e[1] ~= "moodles" and e[1] ~= "belt" and e[1] ~= "moodlesV" and G1.covers(w)) and " COVERS the character" or ""))
        end
    end
end
function G1.shape()
    local t = {}
    for _, e in ipairs(G1.wins()) do
        local w = e[2]
        pcall(function() if w:isVisible() then t[#t + 1] = string.format("%d,%d,%d,%d,%d", w:getX(), w:getY(), w:getWidth(), w:getHeight(), math.floor(w._drawerEffW or 0)) end end)
    end
    return table.concat(t, ";")
end
function G1.tp(q, dir)
    if not q then return end
    pcall(function() STORY.tpSq(q) end)
    pcall(function() G1.p:setDir(IsoDirections[dir or "SE"]) end)
end

-- ===================================================================== picture 17's shelf
-- the shelf nearest the stock spot that the spot reaches (ties: the smaller x, then y)
function G1.findShelf()
    local ST = STORY
    if not (ST and ST.F and ST.P) then return nil end
    local q = ST.P.stock
    local best = nil
    for _, e in ipairs(ST.F.shelves or {}) do
        local ok = false
        pcall(function() ok = (e.x == q[1] and e.y == q[2]) or ST.sqAt(q[1], q[2]):canReachTo(ST.sqAt(e.x, e.y)) end)
        local d = math.abs(e.x - q[1]) + math.abs(e.y - q[2])
        if ok and e.inv and d <= 2 then
            if not best or d < best.d or (d == best.d and (e.x < best.e.x or (e.x == best.e.x and e.y < best.e.y))) then best = { e = e, d = d } end
        end
    end
    return best and best.e or nil
end
function G1.fillShelf(Q)
    if G1.shelf then Q.say("the shelf is already filled"); return true end
    local e = G1.findShelf()
    if not e then Q.say("ERR no shelf in reach of the stock spot"); return false end
    local inv = e.inv
    G1.shelf = { e = e, inv = inv, was = {}, added = {} }
    pcall(function()
        local items = inv:getItems()
        for i = 0, items:size() - 1 do G1.shelf.was[#G1.shelf.was + 1] = items:get(i) end
    end)
    for _, it in ipairs(G1.shelf.was) do pcall(function() inv:Remove(it) end) end
    for _, ft in ipairs(G1.SHELF_ITEMS) do
        local it = nil
        pcall(function() it = inv:AddItem(ft) end)
        if it then G1.shelf.added[#G1.shelf.added + 1] = it end
    end
    Q.say(string.format("shelf %s at %d,%d: %d things it held set aside, %d of %d put in | capacity %s",
        tostring(e.t), e.x, e.y, #G1.shelf.was, #G1.shelf.added, #G1.SHELF_ITEMS, tostring(inv:getCapacity())))
    return true
end
function G1.shelfBack(Q)
    local s = G1.shelf
    if not s then return end
    for _, it in ipairs(s.added) do pcall(function() s.inv:Remove(it) end) end
    for _, it in ipairs(s.was) do pcall(function() s.inv:AddItem(it) end) end
    Q.say("shelf back: " .. #s.was .. " things it held, " .. #s.added .. " taken out")
    G1.shelf = nil
end
-- three apples (the one open stack, in both runs)
function G1.giveApples(Q)
    G1.apples = G1.apples or {}
    if #G1.apples > 0 then return end
    for _ = 1, 3 do
        local it = nil
        pcall(function() it = G1.p:getInventory():AddItem("Base.Apple") end)
        if it then G1.apples[#G1.apples + 1] = it end
    end
    Q.say("apples given: " .. #G1.apples)
end
function G1.applesBack(Q)
    for _, it in ipairs(G1.apples or {}) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    Q.say("apples taken back: " .. #(G1.apples or {}))
    G1.apples = {}
end

-- ===================================================================== picture 26's wound
function G1.part()
    local bp = nil
    pcall(function() bp = G1.p:getBodyDamage():getBodyPart(BodyPartType.ForeArm_L) end)
    return bp
end
function G1.wound(Q, on)
    local bp = G1.part()
    if not bp then Q.say("ERR no left forearm"); return false end
    if on then
        pcall(function() G1.p:setGodMod(false) end)
        pcall(function() bp:setScratched(true, true) end)
        pcall(function() bp:setInfectedWound(false) end)
        local ok = pcall(function() bp:setBandaged(true, 10.0, false, "Base.Bandage") end)
        if not ok then pcall(function() bp:setBandaged(true, 10.0) end) end
    else
        pcall(function() bp:setBandaged(false, 0.0) end)
        pcall(function() bp:setScratched(false, true) end)
        pcall(function() bp:setScratchTime(0) end)
    end
    local sc, bd = "?", "?"
    pcall(function() sc = tostring(bp:scratched()) end)
    pcall(function() bd = tostring(bp:bandaged()) end)
    Q.say("left forearm: scratched " .. sc .. ", bandaged " .. bd)
    return true
end

if G1.zed then G1.muteHalo() end
G1.glasses(nil)
G1.log("eyes at the start: " .. G1.eyesLine())
G1.log("helpers ready | ZeD loaded " .. tostring(G1.zed) .. " | story staged " .. tostring(STORY ~= nil and STORY.ready == true)
    .. " | load " .. ((GAL_UNLOAD and GAL_UNLOAD.line) and GAL_UNLOAD.line() or "(no unload)"))
local k = { n = 0 }
function G1.later()
    k.n = k.n + 1
    if k.n < 10 then return end
    Events.OnTick.Remove(G1.later)
    G1.log("DONE")
end
Events.OnTick.Add(G1.later)
