-- ZeDUI/tools/qa/gallery_v1_c3_common.lua  (Nov 17 2026, QA): shared helpers for the ZeD-GUI 1.0 gallery's "lived-in"
-- retakes, third batch (chapters 60, 62, 64, 66, 67, 69, 71, 72, 73, 74; the director, Nov 17: retake somewhere
-- lived-in, Angel at the West Point Fossoil). Run after gallery_story_stage.lua and gallery_unload.lua, before
-- gallery_v1_c3_a.lua, gallery_v1_c3_b.lua and gallery_v1_c3_c.lua (gallery_v1_c3.txt). Defines the global C3:
--   C3.make(tag)        a step queue on Events.OnPreUIDraw (drawn frames: runs behind the pause menu and the book too):
--                       Q.step(n, fn), Q.waitFor(n, max, cond, fn), Q.still(n, fn), Q.mark() (the put-back starts
--                       here; a run past its time jumps to it), Q.hold (a function run every frame: keeps windows
--                       placed while drawers grow), Q.shot(name, extras), Q.notTaken(name, why), Q.start() (DONE last)
--   Q.shot(name, ex)    the gallery rule first (invisible off, god mode off, zombies-don't-attack on, debug console
--                       hidden, pointer hidden), refused over 19 kg; then getCore():TakeFullScreenshot(name .. ".png");
--                       then the load line and every window's box, "COVERS the character" on a box over the character
--   C3.side(list, side) THE NEW RULE: the windows to one side. list = { { win, label }, ... }: the first at the left
--                       (or right) edge, the next beside it; one that would cover the character goes to the other edge
--   C3.sideX(w)         the x for one window w px wide: the left edge, else the right edge, whichever leaves the
--                       character uncovered
--   C3.go(Q, spot, dir) the character to STORY.P[spot] (stock, clerk, pump, smoke), facing dir; logged
--   C3.listView(on)     every container in the list view (nothing can fall into a grid's Overflow strip); off puts the
--                       choices back
--   C3.theme(b, a, s)   ZeD.applyTheme, the windows following the accent
-- grep "ZEDQA c3m".
C3 = C3 or {}
local C = C3
C.p = getPlayer()
C.pn = C.p:getPlayerNum()
C.core = getCore()
C.CWm, C.WWm = ZeD_CharacterWindow, ZeD_WorldWindow
function C.log(s) print("ZEDQA c3m " .. tostring(s)) end
function C.CW() local w = nil; pcall(function() w = C.CWm.getWindow() end); return w end
function C.WW() local w = nil; pcall(function() w = C.WWm.getWindow() end); return w end
function C.vis(w) local v = false; pcall(function() v = w:isVisible() and w:getWidth() > 0 end); return v end

-- ===================================================================== the queue
function C.make(tag, maxMs)
    local Q = { tag = tag, list = {}, qi = 1, wait = nil, t0 = getTimestampMs(), maxMs = maxMs or 1500000, took = {}, missed = {} }
    function Q.say(s) print("ZEDQA " .. Q.tag .. " " .. tostring(s)) end
    function Q.step(n, fn) Q.list[#Q.list + 1] = { n = n, fn = fn } end
    -- after n frames, every frame until cond() (at most max frames), then fn(ok)
    function Q.waitFor(n, max, cond, fn) Q.list[#Q.list + 1] = { n = n, fn = fn or function() end, cond = cond, max = max } end
    -- the windows the same for 30 frames running (at most 900), then fn
    function Q.still(n, fn)
        local st = { last = nil, same = 0 }
        Q.waitFor(n, 900, function()
            local s = C.shape()
            if s == st.last then st.same = st.same + 1 else st.last, st.same = s, 0 end
            return st.same >= 30
        end, fn)
    end
    function Q.mark() Q.backAt = #Q.list + 1 end
    function Q.notTaken(name, why) Q.missed[#Q.missed + 1] = name; Q.say("not taken: " .. name .. " (" .. tostring(why) .. ")") end
    -- extras: { { label, window }, ... } logged with the ZeD windows
    function Q.shot(name, extras)
        C.clean()
        C.hidePointer()
        local load = C.loadLine()
        if C.weight() > 19 then Q.notTaken(name, "over the load limit: " .. load); return false end
        local ok, e = pcall(function() C.core:TakeFullScreenshot(name .. ".png") end)
        if ok then Q.took[#Q.took + 1] = name; Q.say("shot " .. name) else Q.missed[#Q.missed + 1] = name; Q.say("ERR shot " .. name .. ": " .. tostring(e)) end
        Q.say("load " .. name .. ": " .. load)
        C.boxes(Q, name, extras)
        return ok
    end
    function Q.tick()
        if Q.hold then local okH, eH = pcall(Q.hold); if not okH then Q.say("ERR hold: " .. tostring(eH)); Q.hold = nil end end
        local s = Q.list[Q.qi]
        if not s then Events.OnPreUIDraw.Remove(Q.tick); return end
        if Q.backAt and Q.qi < Q.backAt and getTimestampMs() - Q.t0 > Q.maxMs then
            Q.say("ERR ran too long at step " .. Q.qi .. ": jumping to the put-back")
            Q.qi, Q.wait, Q.hold = Q.backAt, nil, nil
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
    function Q.start()
        Q.step(2, function()
            Q.hold = nil
            Q.say("taken " .. #Q.took .. ": " .. table.concat(Q.took, " "))
            Q.say("not taken " .. #Q.missed .. ": " .. table.concat(Q.missed, " "))
            Q.say("DONE")
        end)
        Events.OnPreUIDraw.Add(Q.tick)
        Q.say("start (" .. #Q.list .. " steps) | " .. C.where())
    end
    return Q
end

-- ===================================================================== the gallery rule
function C.clean()
    pcall(function() C.p:setInvisible(false) end)
    pcall(function() C.p:setGodMod(false) end)
    pcall(function() C.p:setZombiesDontAttack(true) end)
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false) end
        end
    end)
end
-- (gallery_unload.lua keeps the pointer hidden every drawn frame; this hides it again for scripts run without it)
function C.hidePointer() pcall(function() Mouse.setCursorVisible(false) end) end
function C.park(x, y)
    local W, H = C.core:getScreenWidth(), C.core:getScreenHeight()
    pcall(function() Mouse.setXY(x or (W - 3), y or (H - 3)) end)
    C.hidePointer()
end
function C.weight()
    if GAL_UNLOAD and GAL_UNLOAD.weight then return GAL_UNLOAD.weight() end
    local w = 0
    pcall(function() w = C.p:getInventory():getCapacityWeight() end)
    return w
end
function C.loadLine()
    if GAL_UNLOAD and GAL_UNLOAD.line then return GAL_UNLOAD.line() end
    return string.format("%.1f kg (gallery_unload.lua did not run)", C.weight())
end
function C.where()
    local z = 1
    pcall(function() z = C.core:getZoom(C.pn) end)
    return string.format("at %d,%d,%d zoom %s | look %s %s %s", math.floor(C.p:getX()), math.floor(C.p:getY()), math.floor(C.p:getZ()),
        tostring(z), tostring(ZeD and ZeD.currentBase), tostring(ZeD and ZeD.currentAccent), tostring(ZeD and ZeD.currentSize))
end

-- ===================================================================== the character on the screen, the boxes
-- a rect round the figure (zoom 1 at 4K: about 320 x 420 px with room to spare)
function C.charRect()
    local W, H = C.core:getScreenWidth(), C.core:getScreenHeight()
    local r = { x = W / 2, y = H / 2 }
    pcall(function()
        local sx = isoToScreenX(C.pn, C.p:getX(), C.p:getY(), C.p:getZ())
        local sy = isoToScreenY(C.pn, C.p:getX(), C.p:getY(), C.p:getZ())
        if sx and sy then r.x, r.y = sx, sy end
    end)
    local z = 1
    pcall(function() z = C.core:getZoom(C.pn) end)
    if not z or z <= 0 then z = 1 end
    r.x0, r.x1 = math.floor(r.x - 160 / z), math.floor(r.x + 160 / z)
    r.y0, r.y1 = math.floor(r.y - 360 / z), math.floor(r.y + 60 / z)
    return r
end
function C.hits(x, y, w, h)
    local r = C.charRect()
    return x < r.x1 and x + w > r.x0 and y < r.y1 and y + h > r.y0
end
function C.covers(win)
    if not C.vis(win) then return false end
    return C.hits(win:getAbsoluteX(), win:getAbsoluteY(), win:getWidth(), win:getHeight())
end
function C.boxes(Q, name, extras)
    local r = C.charRect()
    Q.say(string.format("box %s character %d,%d-%d,%d", name, r.x0, r.y0, r.x1, r.y1))
    local list = { { "char", C.CW() }, { "world", C.WW() } }
    pcall(function() local L = ZeD.Moodles.getLayer(C.pn); if L then list[#list + 1] = { "moodles", L, true } end end)
    pcall(function() local h = ZeD.Belt.getHUD(); if h then list[#list + 1] = { "belt", h, true } end end)
    for _, e in ipairs(extras or {}) do list[#list + 1] = e end
    local n = 0
    for _, e in ipairs(list) do
        local w = e[2]
        if w and C.vis(w) then
            local x, y = math.floor(w:getAbsoluteX()), math.floor(w:getAbsoluteY())
            local cov = (not e[3]) and C.covers(w)
            if cov then n = n + 1 end
            Q.say(string.format("box %s %s %d,%d-%d,%d%s", name, e[1], x, y, x + w:getWidth(), y + w:getHeight(), cov and " COVERS the character" or ""))
        end
    end
    if n == 0 then Q.say("box " .. name .. ": the character is clear of every window") end
end
function C.shape()
    local t = {}
    for _, w in ipairs({ C.CW() or false, C.WW() or false }) do
        if w and C.vis(w) then
            t[#t + 1] = string.format("%d,%d,%d,%d,%d,%d", math.floor(w:getX()), math.floor(w:getY()), math.floor(w:getWidth()),
                math.floor(w:getHeight()), math.floor(w._drawerEffW or 0), math.floor((w._seeA or 0) * 100))
        end
    end
    return table.concat(t, ";")
end

-- ===================================================================== the new rule: windows to one side
function C.m() local m = 24; pcall(function() m = ZeD.T.px(12) end); return m end
function C.sideX(w, prefer)
    local W, m = C.core:getScreenWidth(), C.m()
    local left, right = m, W - w - m
    local first, second = left, right
    if prefer == "right" then first, second = right, left end
    local r = C.charRect()
    if not (first < r.x1 and first + w > r.x0) then return first end
    if not (second < r.x1 and second + w > r.x0) then return second end
    return first
end
function C.setX(win, x)
    if math.floor(win:getX()) ~= math.floor(x) then win:setX(x) end
    if win._anchorRightEdge ~= nil then win._anchorRightEdge = x + win:getWidth() end
end
-- list = { { win, label, y }, ... }; side "left" (default) or "right"; y (optional) the window's top
function C.side(list, side)
    local W, m = C.core:getScreenWidth(), C.m()
    local r = C.charRect()
    local x = m
    local other = W - m
    for _, e in ipairs(list) do
        local win = e[1]
        if win and C.vis(win) then
            local w = win:getWidth()
            local nx = (side == "right") and (W - x - w) or x
            if nx < r.x1 and nx + w > r.x0 then
                -- this one would cover the character: the other edge
                if side == "right" then nx = m else nx = other - w; other = nx - m end
            else
                x = x + w + m
            end
            C.setX(win, nx)
            if e[3] and math.floor(win:getY()) ~= math.floor(e[3]) then win:setY(e[3]) end
        end
    end
end
-- both ZeD windows to the left (the World window to the right edge when it would cover the character)
function C.pairSide() C.side({ { C.CW(), "char" }, { C.WW(), "world" } }, "left") end

-- ===================================================================== windows, tabs, the look
function C.pairOpen()
    if not C.CWm.isOpen() then pcall(C.CWm.toggleBothPaired, C.pn) end
    if not C.WWm.isOpen() then pcall(C.WWm.open, C.pn) end
end
function C.pairShut() if C.CWm.isOpen() then pcall(C.CWm.toggleBothPaired, C.pn) end end
function C.goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab or (tab ~= "loot" and not win._drawerOpen) then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
function C.charTab(id) local w = C.CW(); return (w and C.goTab(w, w._tabStripPanel, id)) and true or false end
function C.worldTab(id) local w = C.WW(); return (w and C.goTab(w, w._actionTabStrip, id)) and true or false end
function C.theme(base, accent, size)
    pcall(function() ZeD.applyTheme(base, accent, size or ZeD.currentSize) end)
    local c, w = C.CW(), C.WW()
    if c then c._accentKey = nil end
    if w then w._accentKey = nil end
end
-- the place, size and tab of both windows, to put back
function C.snapWins()
    local s = {}
    for k, w in pairs({ c = C.CW() or false, w = C.WW() or false }) do
        if w then s[k] = { x = w:getX(), y = w:getY(), h = w:getHeight(), tab = w._activeTab, anchor = w._anchorRightEdge } end
    end
    s.open = C.CWm.isOpen()
    return s
end
function C.backWins(s)
    if not s then return end
    for k, w in pairs({ c = C.CW() or false, w = C.WW() or false }) do
        local v = s[k]
        if w and v then
            pcall(function() w:setHeight(v.h); w:onResize() end)
            pcall(function() w:setX(v.x); w:setY(v.y); w._anchorRightEdge = v.anchor end)
        end
    end
    pcall(function() if s.c and s.c.tab then C.charTab(s.c.tab) end end)
    pcall(function() if s.w and s.w.tab then C.worldTab(s.w.tab) end end)
    if s.open then C.pairOpen() else C.pairShut() end
end

-- ===================================================================== the place
function C.go(Q, spot, dir)
    local ST = STORY
    local q = ST and ST.P and ST.P[spot]
    -- (the pump is a record of the pump's own square: the first free outdoor square beside it, by the story's car)
    if q and q.x and not q[1] then
        local near = nil
        pcall(function() near = ST.outNear(q.x, q.y, 4) end)
        q = near or { q.x + 1, q.y + 1 }
    end
    if not q then Q.say("ERR no story spot " .. tostring(spot) .. " (gallery_story_stage.lua did not run): staying here"); return false end
    pcall(function() C.p:StopAllActionQueue() end)
    pcall(function() ST.tpSq(q) end)
    pcall(function() C.p:setDir(IsoDirections[dir or "SE"]) end)
    Q.say(string.format("at %s: %d,%d facing %s | %s", spot, q[1], q[2], tostring(dir or "SE"), STORY.site and STORY.site.name or "?"))
    return true
end

-- ===================================================================== list view everywhere (no Overflow strip)
function C.listView(on)
    local md = C.p:getModData()
    local St = ZeD.Settings
    if on then
        if C.gridWas then return end
        C.gridWas = { had = md.ZeD_GridViews ~= nil, keys = {}, opt = St and St.inventoryViewOption and St.inventoryViewOption:getValue() }
        for k, v in pairs(md.ZeD_GridViews or {}) do C.gridWas.keys[#C.gridWas.keys + 1] = { k, v } end
        pcall(function() St.inventoryViewOption:setValue(1) end)
        for k, _ in pairs(md.ZeD_GridViews or {}) do md.ZeD_GridViews[k] = false end
        C.log("list view on every container (was option " .. tostring(C.gridWas.opt) .. ", " .. #C.gridWas.keys .. " own choices)")
    else
        local w = C.gridWas
        if not w then return end
        if w.had then
            md.ZeD_GridViews = {}
            for _, kv in ipairs(w.keys) do md.ZeD_GridViews[kv[1]] = kv[2] end
        else
            md.ZeD_GridViews = nil
        end
        if w.opt then pcall(function() St.inventoryViewOption:setValue(w.opt) end) end
        C.gridWas = nil
        C.log("list view choices put back")
    end
end

-- ===================================================================== the stand-in pad (one call only)
C.fake = { player = C.pn, focus = nil }
function C.withPad(Q, fn, ...)
    if JoypadState.players[C.pn + 1] then return fn(...) end
    JoypadState.players[C.pn + 1] = C.fake
    local ok, r = pcall(fn, ...)
    JoypadState.players[C.pn + 1] = nil
    pcall(setPlayerButtonsActive, C.pn, true)
    pcall(setJoypadIgnoreAim, C.pn, false)
    if not ok then Q.say("ERR withPad: " .. tostring(r)) end
    return r
end

C.log("helpers ready | story staged " .. tostring(STORY ~= nil and STORY.ready == true) .. " | " .. C.where() .. " | load " .. C.loadLine())
C.k = 0
function C.later()
    C.k = C.k + 1
    if C.k < 10 then return end
    Events.OnTick.Remove(C.later)
    C.log("DONE")
end
Events.OnTick.Add(C.later)
