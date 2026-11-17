-- ZeDUI/tools/qa/zedqa_b19_old_c.lua  (Nov 16 2026, QA): five older fixes that were built but never checked in game.
-- No controller is plugged into the QA PC, so a stand-in pad record is put in JoypadState.players for the length of
-- one call only (withPad) and taken out again before the next frame. Two places keep it longer, on purpose: one frame
-- for the Photo Studio's picture, and one game tick for the map's hold (taken out again inside that tick).
--   247   the action bubble: a short timed action (a stand-in of ZeD's QA, through the real queue) is drawn, ends with
--         "Done" drawn from that action, and fades out; a later end of an action that was never drawn (the "Done
--         smoking" minutes later) flashes nothing; a fence hop and a window climb get no bubble and their ends flash
--         nothing; a walk of a few tiles flashes no "Done"; a cancelled action says "Stopped" for itself and fades.
--   229   the Photo Studio: with a controller the button strip is drawn (A, Y, LB, RB, Up / Down, B, each with words),
--         none without one, none while the photo is taken; X does nothing (so it is not on the strip); Y, LB / RB,
--         Up / Down and B do what the strip says. (A is not pressed: it would save a real portrait.)
--   204   the map: LT / RT zoom on the controller's cursor (out, then back in); with the map's canvas holding the pad,
--         the game's per-tick map poll holds the character (no walking, aim and attack ignored, so LT cannot shove);
--         the pad gone, the hold is let go.
--   238   character creation's clothing row and palette, run on a stand-in of the creation window (its real code):
--         Left / Right walk item, tint, fabric and stop at the ends; A on the tint opens the palette on the color in
--         use; the D-pad walks the palette as a grid and stops at its edges; A takes the color.
--   239   the hair color swatches, same stand-in: Up / Down move a line, the short last line lands on its last swatch,
--         Up off the top and Down off the bottom leave the row, A takes the swatch under the cursor.
-- Not run: 204 with a real LT pull (the shove itself is the game's, read from a real trigger); 238 / 239 on the real
-- creation screen at the main menu (drawing, vanilla's tint callback); 247 with a real cigarette, a real fence hop
-- with B and a real window climb.
-- Pictures: Screenshots/zqa_b19c_*.png. Puts back: actions stopped, the character where it started, the studio
-- closed and its backdrop as it was, the map's tab and the window pair as found, the input mode unlocked, the pad
-- records out, movement and aim let go. grep "ZEDQA b19c".
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA b19c " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b19c_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local Focus = ZeD.Input and ZeD.Input.Focus
local CW, WWn = ZeD_CharacterWindow, ZeD_WorldWindow
local AB = ZeD.ActionBar
local S = {}

-- the stand-in pad: in JoypadState only for the call
local fake = { player = pn, focus = nil }
local function withPad(fn, ...)
    local real = JoypadState.players[pn + 1]
    if real then say("note: a real pad is bound; the stand-in is not used") return fn(...) end
    JoypadState.players[pn + 1] = fake
    local ok, r = pcall(fn, ...)
    JoypadState.players[pn + 1] = nil
    pcall(setPlayerButtonsActive, pn, true)
    pcall(setJoypadIgnoreAim, pn, false)
    if not ok then say("ERR " .. tostring(r)) end
    return r
end
local function ends() return AB._ends[pn] end
local function phaseOf(e) return e and e.st and e.st.phase or "none" end

-- a short timed action of QA's own, through the game's real queue (it does nothing and takes nothing)
S.Wait = ISBaseTimedAction:derive("ZeDQA_B19cWait")
function S.Wait:isValid() return true end
function S.Wait:waitToStart() return false end
function S.Wait:complete() return true end
function S.Wait:perform() ISBaseTimedAction.perform(self) end
function S.Wait:stop() ISBaseTimedAction.stop(self) end
function S.Wait:new(chr, t)
    local o = ISBaseTimedAction.new(self, chr)
    o.maxTime = t
    o.stopOnWalk, o.stopOnRun, o.stopOnAim = false, false, false
    return o
end

-- 204's one-tick hold watch: runs after the map's own tick poll (added later), takes the stand-in out again at once
S.onTick = function()
    if not S.armed then return end
    S.armed = false
    S.heldSeen = p:isBlockMovement()
    S.tickRan = true
    JoypadState.players[pn + 1] = nil
end
Events.OnTick.Add(S.onTick)

step(20, function()
    say("start: pad bound " .. tostring(JoypadState.players[pn + 1] ~= nil) .. ", at " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()))
    S.home = { x = p:getX(), y = p:getY(), z = p:getZ() }
    S.pairWas = CW.isOpen and CW.isOpen(pn) or false
    pcall(function() p:StopAllActionQueue() end)
    check(AB ~= nil and AB.onEnded ~= nil and AB.NO_BUBBLE ~= nil, "247: the action bubble's end check is loaded")
end)

-- ===================================================================== 247: the action bubble
step(30, function()
    S.a1 = S.Wait:new(p, 60)
    ISTimedActionQueue.add(S.a1)
end)
step(20, function()
    local last = AB._last[pn]
    check(last ~= nil and last.act == S.a1, "247: the bubble is drawn from the running action (" .. tostring(last and last.label) .. ")")
    shot("247_running")
end)
for _ = 1, 100 do
    step(4, function() if not S.end1 and ends() then S.end1 = ends(); shot("247_done") end end)
end
step(2, function()
    local e = S.end1
    check(e ~= nil and e.st.phase == "done" and e.st.act == S.a1, "247: it ends with Done, drawn from that action (" .. phaseOf(e) .. ")")
end)
step(90, function()
    check(ends() == nil and AB.state(p, pn) == nil, "247: the Done fades and the bubble is gone")
    -- the stale end: a later action of the same kind that was never drawn ends (the "Done smoking" minutes later)
    local x = S.Wait:new(p, 0)
    pcall(AB.onEnded, x, "done")
    check(ends() == nil, "247: a never-drawn action's end flashes nothing over the last bubble (" .. phaseOf(ends()) .. ")")
    local y = ISBaseTimedAction.new(ISBaseTimedAction, p)
    y.Type = "ISEatFoodAction"
    pcall(AB.onEnded, y, "done")
    check(ends() == nil, "247: nor does another kind's (" .. phaseOf(ends()) .. ")")
end)
-- the hop and the climb: built as the game builds them (create runs ZeD's hook), never queued
step(5, function()
    check(AB.NO_BUBBLE.ISClimbOverFence == true and AB.NO_BUBBLE.ISClimbThroughWindow == true, "247: fence hops and window climbs are on the no-bubble list")
    local stub = { isTallHoppable = function() return false end }
    local h = ISClimbOverFence:new(p, stub, IsoDirections.N)
    local okH, eH = pcall(ISBaseTimedAction.create, h)
    if not okH then say("note: the hop's create: " .. tostring(eH)) end
    check(h._zedBar == false, "247: a fence hop is made with no bubble")
    pcall(AB.onEnded, h, "done")
    check(ends() == nil, "247: a fence hop's end flashes nothing (" .. phaseOf(ends()) .. ")")
    local w = ISClimbThroughWindow:new(p, nil, 30)
    local okW, eW = pcall(ISBaseTimedAction.create, w)
    if not okW then say("note: the climb's create: " .. tostring(eW)) end
    check(w._zedBar == false, "247: a window climb is made with no bubble")
    pcall(AB.onEnded, w, "done")
    check(ends() == nil, "247: a window climb's end flashes nothing (" .. phaseOf(ends()) .. ")")
end)
-- a walk of a few tiles: no "Done" on the way or at the end
step(5, function()
    local cell = getCell()
    local x0, y0, z0 = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
    for d = 7, 3, -1 do
        for _, v in ipairs(dirs) do
            if not S.walkSq then
                local sq = cell:getGridSquare(x0 + v[1] * d, y0 + v[2] * d, z0)
                local ok, free = pcall(function() return sq and sq:isFree(false) end)
                if ok and free then S.walkSq = sq end
            end
        end
    end
    if not S.walkSq then say("not run: 247 walk (no free tile 3 to 7 tiles away)"); return end
    say("247 walk to " .. S.walkSq:getX() .. "," .. S.walkSq:getY())
    S.walkFrom = { x = p:getX(), y = p:getY() }
    S.walkFlash = nil
    ISTimedActionQueue.add(ISWalkToTimedAction:new(p, S.walkSq))
end)
for _ = 1, 150 do
    step(4, function()
        local ph = phaseOf(ends())
        if ph == "done" or ph == "stopped" then S.walkFlash = ph end
    end)
end
step(5, function()
    if not S.walkSq then return end
    local dx, dy = p:getX() - S.walkFrom.x, p:getY() - S.walkFrom.y
    local moved = math.sqrt(dx * dx + dy * dy)
    say("247 walked " .. string.format("%.1f", moved) .. " tiles")
    check(moved > 2, "247: the character walked")
    check(S.walkFlash == nil, "247: no Done or Stopped flashed during or after the walk (" .. tostring(S.walkFlash) .. ")")
    shot("247_after_walk")
end)
-- a cancelled action: Stopped, for itself, then gone
step(10, function()
    S.a2 = S.Wait:new(p, 2000)
    ISTimedActionQueue.add(S.a2)
end)
step(30, function()
    local last = AB._last[pn]
    check(last ~= nil and last.act == S.a2, "247: the second action's bubble is drawn from it")
    pcall(function() p:StopAllActionQueue() end)
end)
step(3, function()
    local e = ends()
    check(e ~= nil and e.st.phase == "stopped" and e.st.act == S.a2, "247: cancelled, it says Stopped for that action (" .. phaseOf(e) .. ")")
    shot("247_stopped")
end)
step(90, function()
    check(ends() == nil and AB.state(p, pn) == nil, "247: the Stopped fades and the bubble is gone")
    pcall(function() p:setX(S.home.x); p:setY(S.home.y); p:setLastX(S.home.x); p:setLastY(S.home.y) end)
end)
step(20, function()
    check(ends() == nil and AB.state(p, pn) == nil, "247: moved back, still no bubble")
    say("not run: 247 with a real cigarette, a real fence hop with B, a real window climb (the director's hands)")
end)

-- ===================================================================== 229: the Photo Studio's button strip
step(10, function()
    local ST = ZeD.Studio
    if not (ST and ST.open and ZeD_StudioRoom and ZeD.PadGlyphs) then say("not run: 229 (the studio is not loaded)"); return end
    S.bdWas = ST.backdrop
    local G = ZeD.PadGlyphs
    S.realStrip = G.drawStrip
    G.drawStrip = function(panel, x, y, w, prompts)
        S.strip = prompts
        if not S.dry then return S.realStrip(panel, x, y, w, prompts) end
    end
    check(ST.open(p) == true and ST.room ~= nil, "229: the Photo Studio opens")
end)
step(30, function()
    local r = ZeD.Studio and ZeD.Studio.room; if not r then return end
    S.dry = true
    S.strip = nil
    pcall(r.render, r)
    check(S.strip == nil, "229: with no controller in use, no strip")
    S.strip = nil
    withPad(function() r:render() end)
    S.got = S.strip
    S.strip = nil
    r.shoot = 1
    withPad(function() r:render() end)
    r.shoot = nil
    check(S.strip == nil, "229: no strip while the photo is taken")
    S.dry = false
    check(S.got ~= nil, "229: with a controller, the strip is drawn")
end)
step(2, function()
    local got = S.got; if not got then return end
    local tr = ZeD.tr
    local seen, words, bad = {}, {}, 0
    for _, e in ipairs(got) do
        local g, l = tostring(e.glyph), tostring(e.label)
        seen[g] = l
        if l == "" or l:sub(1, 3) == "UI_" then bad = bad + 1 end
        if g:byte(1) and g:byte(1) < 128 then words[#words + 1] = g .. " " .. l else words[#words + 1] = "(Up/Down) " .. l end
    end
    say("229 strip: " .. table.concat(words, " | "))
    check(seen.A ~= nil and seen.Y ~= nil and seen.LB ~= nil and seen.RB ~= nil and seen.B ~= nil, "229: A, Y, LB, RB and B are on the strip")
    local zoom = false
    for _, e in ipairs(got) do if tostring(e.label) == tr("UI_ZeD_Reader_PromptZoom") then zoom = true end end
    check(zoom, "229: Up / Down (zoom) is on the strip")
    check(bad == 0, "229: every button has its words (" .. bad .. " blank or untranslated)")
    check(seen.X == nil, "229: X is not on the strip (it does nothing)")
end)
step(5, function()
    if not (ZeD.Studio and ZeD.Studio.room) then return end
    JoypadState.players[pn + 1] = fake   -- (one frame, for the strip in the picture)
    S.markFrame = true
end)
step(2, function()
    if S.markFrame then JoypadState.players[pn + 1] = nil; S.markFrame = nil end
    shot("229_studio_strip")
    local r = ZeD.Studio and ZeD.Studio.room; if not r then return end
    local function dirOf() local ok, d = pcall(function() return tostring(r.fig:getDirection()) end); return ok and d or "?" end
    local bd, t, d = r.bd, r.t, dirOf()
    withPad(function() r:onJoypadDown(Joypad.XButton) end)
    check(r.bd == bd and r.t == t and dirOf() == d and ZeD.Studio.isOpen(), "229: X changes nothing")
    withPad(function() r:onJoypadDown(Joypad.YButton) end)
    check(r.bd ~= bd, "229: Y changes the backdrop (" .. tostring(bd) .. " -> " .. tostring(r.bd) .. ")")
    withPad(function() r:onJoypadDown(Joypad.LBumper) end)
    local d2 = dirOf()
    check(d2 ~= d, "229: LB turns the character (" .. d .. " -> " .. d2 .. ")")
    withPad(function() r:onJoypadDown(Joypad.RBumper) end)
    check(dirOf() == d, "229: RB turns it back (" .. dirOf() .. ")")
    withPad(function() r:onJoypadDirUp() end)
    check(r.t > t, "229: Up frames closer (" .. tostring(t) .. " -> " .. tostring(r.t) .. ")")
    withPad(function() r:onJoypadDirDown() end)
    check(math.abs(r.t - t) < 0.001, "229: Down frames back out")
end)
step(60, function()
    local r = ZeD.Studio and ZeD.Studio.room
    if r then
        withPad(function() r:onJoypadDown(Joypad.BButton) end)
        check(not ZeD.Studio.isOpen(), "229: B leaves the studio")
    end
    if S.realStrip then ZeD.PadGlyphs.drawStrip = S.realStrip; S.realStrip = nil end
    if ZeD.Studio then pcall(ZeD.Studio.close); ZeD.Studio.backdrop = S.bdWas end
    say("not run: 229 A (it would save a real portrait); the strip read by the director's eye on a real pad")
end)

-- ===================================================================== 204: LT in the map
step(20, function()
    if not (CW.isOpen and CW.isOpen(pn)) then pcall(CW.toggleBothPaired, pn) end
end)
step(20, function()
    local w = WWn.getWindow(pn)
    if not w then return end
    S.wTab, S.wOpen, S.wMode = w._activeTab, w._drawerOpen, w._drawerMode
    WWn.openTab(pn, "maps")
end)
step(40, function()
    local w = WWn.getWindow(pn)
    local mp = w and w._worldMapPanel
    if not (mp and mp:isReallyVisible()) then say("not run: 204 (the map did not open)"); return end
    S.map = true
    -- (getZoomF is the shown zoom, which glides to the new one over several frames, as vanilla's own LB zoom
    -- relies on: read it after the glide, not in the same frame)
    S.zf = function() local ok, z = pcall(function() return WWn.getWindow(pn)._worldMapPanel.mapAPI:getZoomF() end); return ok and z or nil end
    S.z0 = S.zf()
    ZeD.MapsTab.gpZoom(w, 1)
end)
step(45, function()
    if not S.map then return end
    S.z1 = S.zf()
    ZeD.MapsTab.gpZoom(WWn.getWindow(pn), -1)
end)
step(45, function()
    if not S.map then return end
    local w = WWn.getWindow(pn)
    local z0, z1, z2 = S.z0, S.z1, S.zf()
    say("204 zoom: " .. tostring(z0) .. " -> out " .. tostring(z1) .. " -> in " .. tostring(z2))
    check(z0 and z1 and z1 < z0, "204: LT's zoom goes out")
    check(z1 and z2 and z2 > z1, "204: RT's zoom comes back in")
    ZeD.Input.Detector.setLockedMode("gamepad")
    Focus.claimFocus(w)
    Focus.focusWhere(w, "worldTabContent", function(e) return e.isCanvasCursor end)
    local el = Focus.getFocusedElement(w)
    check(el ~= nil and el.isCanvasCursor == true, "204: the map's canvas holds the focus")
    local tr = false
    for _, pr in ipairs(el and el.extraPrompts or {}) do if pr.glyph == "RT LT" then tr = true end end
    check(tr, "204: the canvas's hints name RT LT zoom")
end)
step(10, function()
    if not S.map then return end
    shot("204_map_canvas")
    if JoypadState.players[pn + 1] then say("not run: 204 hold (a real pad is bound)"); return end
    local ok1, a = pcall(getControllerAxisValue, 0, 0)
    local ok2, b = pcall(getControllerAxisValue, 0, 4)
    if not (ok1 and ok2 and type(a) == "number" and type(b) == "number") then
        say("not run: 204 hold (the controller axes can't be read with no controller: " .. tostring(a) .. ", " .. tostring(b) .. ")")
        return
    end
    check(p:isBlockMovement() == false, "204: before, the character is free to move")
    S.fake2 = { player = pn, id = 0, focus = WWn.getWindow(pn) }
    S.tickRan, S.heldSeen = false, nil
    JoypadState.players[pn + 1] = S.fake2   -- (one game tick: the watch takes it out right after the map's poll)
    S.armed = true
end)
step(1, function()
    if S.armed then S.armed = false; JoypadState.players[pn + 1] = nil; say("note: 204 no game tick ran in that frame") end
    if S.fake2 then
        check(S.tickRan and S.heldSeen == true, "204: while the canvas has the pad, the character is held (no walking, no aim or attack: LT cannot shove)")
    end
end)
step(10, function()
    if not S.fake2 then return end
    check(p:isBlockMovement() == false, "204: the pad gone, the hold is let go")
    say("not run: 204 with a real LT pulled (the shove itself is read from a real trigger: the director's hands)")
end)
step(5, function()
    pcall(ZeD.Input.Detector.setLockedMode, nil)
    pcall(Focus.releaseFocus, pn)
    if S.wTab and S.wTab ~= "maps" and S.wOpen and S.wMode == "tab" then pcall(WWn.openTab, pn, S.wTab) end
end)

-- ===================================================================== 238 / 239: character creation, on a stand-in
step(10, function()
    if not (ZeD_MMLooks and ZeD_MMOptions and ZeD_MMLooks.swatchDir and ZeD_MMOptions.paletteDir) then
        say("not run: 238 / 239 (the creation window's code is not loaded in game)"); S.noLooks = true; return
    end
    S.picked = nil
    S.hair = { kind = "swatch", key = "qa_hair", label = "qa_hair", cur = 3, colors = {},
               pick = function(i) S.picked = i end }
    for i = 1, 12 do S.hair.colors[i] = { r = i / 12, g = 0.3, b = 0.2 } end
    S.L = setmetatable({ focusId = "qa_hair", confirm = false, scroll = 0, width = 800, height = 600 }, { __index = ZeD_MMLooks })
    S.L.getAbsoluteX = function() return 0 end
    S.L.getAbsoluteY = function() return 0 end
    S.L.focusedRow = function() return S.row end
    S.row = S.hair
    pcall(ZeD_MMLooks.rowHeight, S.L, S.hair, 10000)
    say("239 swatches to a line: " .. tostring(S.hair._per))
end)
step(2, function()
    if S.noLooks then return end
    local L, r = S.L, S.hair
    local per = r._per or 10
    L:joyDir("down")
    check(L:swatchAt(r) == math.min(12, 3 + per), "239: Down moves a line (3 -> " .. L:swatchAt(r) .. ")")
    check(L:swatchDir(r, "down") == false, "239: Down off the bottom line leaves the row")
    L:joyDir("up")
    check(L:swatchAt(r) == math.min(12, 3 + per) - per, "239: Up moves a line back (" .. L:swatchAt(r) .. ")")
    check(L:swatchDir(r, "up") == false, "239: Up off the top line leaves the row")
    L:joyDir("right")
    local at = L:swatchAt(r)
    check(at == math.min(12, 3 + per) - per + 1, "239: Right still moves a swatch (" .. at .. ")")
    L:activateRow(r)
    check(S.picked == at, "239: A takes the swatch under the cursor (" .. tostring(S.picked) .. ")")
end)
step(2, function()
    if S.noLooks then return end
    local L = S.L
    local vis = function() return true end
    -- the tint swatch wears palette color 311 (the 20th)
    S.cloth = { kind = "cloth", key = "qa_cloth", label = "qa_cloth", loc = "Shirt", control = {},
                tint = { isVisible = vis, backgroundColor = { r = 0.6, g = 0.2, b = 0.2 } },
                tex = { isVisible = vis, options = { 1, 2 } } }
    S.row = S.cloth
    L.focusId = "qa_cloth"
    check(L:clothCol(S.cloth) == "item", "238: the clothing row starts on the item")
    L:joyDir("right")
    check(L:clothCol(S.cloth) == "tint", "238: Right goes to the tint")
    L:joyDir("right")
    check(L:clothCol(S.cloth) == "tex", "238: Right goes to the fabric")
    L:joyDir("right")
    check(L:clothCol(S.cloth) == "tex", "238: Right at the fabric stays put")
    L:joyDir("left")
    check(L:clothCol(S.cloth) == "tint", "238: Left goes back to the tint")
    L:activateRow(S.cloth)
    local pal = L._palette
    check(pal ~= nil, "238: A on the tint opens the palette")
    if not pal then return end
    check(pal.at == 20, "238: the palette's cursor starts on the color in use (" .. tostring(pal.at) .. ", 20 wanted)")
    pal.row.onColor = function(c) S.color = c end   -- (in place of vanilla's tint callback, which needs the menu)
    local seq = { { "right", 21 }, { "down", 35 }, { "up", 21 }, { "left", 20 }, { "up", 6 }, { "up", 6 }, { "left", 5 } }
    local ok, got = true, {}
    for _, s in ipairs(seq) do
        L:joyDir(s[1])
        got[#got + 1] = s[1] .. " " .. tostring(pal.at)
        if pal.at ~= s[2] then ok = false end
    end
    check(ok, "238: the D-pad walks the palette as a grid and stops at its top (" .. table.concat(got, ", ") .. ")")
    L:joyA()
    local c = S.color
    -- PALETTE[5] is 503: r 1.0, g 0.0, b 0.6
    check(c ~= nil and math.abs(c.r - 1) < 0.01 and math.abs(c.g) < 0.01 and math.abs(c.b - 0.6) < 0.01 and L._palette == nil,
        "238: A takes the color under the cursor and closes the palette")
    say("not run: 238 / 239 on the real creation screen at the main menu (the frames drawn, vanilla's tint taking the color: the director's hands)")
end)

-- ===================================================================== put back
step(20, function()
    pcall(function() p:StopAllActionQueue() end)
    if S.home then pcall(function() p:setX(S.home.x); p:setY(S.home.y); p:setLastX(S.home.x); p:setLastY(S.home.y) end) end
    if S.realStrip then ZeD.PadGlyphs.drawStrip = S.realStrip end
    if ZeD.Studio and ZeD.Studio.isOpen and ZeD.Studio.isOpen() then pcall(ZeD.Studio.close) end
    if ZeD.Studio and S.bdWas ~= nil then ZeD.Studio.backdrop = S.bdWas end
    S.armed = false
    Events.OnTick.Remove(S.onTick)
    JoypadState.players[pn + 1] = nil
    pcall(ZeD.Input.Detector.setLockedMode, nil)
    pcall(function() p:setBlockMovement(false) end)
    pcall(setJoypadIgnoreAim, pn, false)
    pcall(setPlayerButtonsActive, pn, true)
    pcall(Focus.releaseFocus, pn)
    if CW.isOpen and CW.isOpen(pn) ~= S.pairWas then pcall(CW.toggleBothPaired, pn) end
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
