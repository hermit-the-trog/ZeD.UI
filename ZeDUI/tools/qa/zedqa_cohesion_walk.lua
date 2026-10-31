-- ZeDUI/tools/qa/zedqa_cohesion_walk.lua  (Oct 27 2026)
-- The cohesion pass walked for the camera: one pass over what the restyle changed, full 4K
-- screenshots named zqa_cw_<nn>_<words>.png, a "ZEDQA cw" line before each one that says what
-- it shows and the live settings. In game on the ZeD-QA save with both windows open (run
-- zedqa_prelude.lua first), through the QA bridge. About three to five minutes; a run that
-- goes past 5 min 40 s jumps to the put-back.
--   01-07  themes x text sizes (dark, light, high contrast x small, large): both windows, the
--          Character window on its inventory, the World window on Loot, an apple's card open;
--          the dark / small pass adds the window box's menu pulled down with Theme open
--   08-13  see-through 100, 90, 80, 70, 60 at dark / small, then 60 with Solid while in use
--          and the pointer on the Character window
--   14-21  controller highlight: hand, corners, wash, ants, each on an inventory row and on a
--          button of the item card
--   22-23  the card's drawer caught twice while it slides open (the frame must stay on top)
--   24-25  the resize handle on the bottom edge and on the right edge
--   26-28  new controller paths: Craft's sort pop-up, Messages' Delete question on Cancel,
--          the item card's Back key
--   29-30  Hair and beard with no scissors or razor: Hidden actions folded, then Show all
--   31-32  the Health tab's bars, the belt with a hand item at 45 per cent
--   33-34  the Maps tab with the Survey / Color / Paper pop-up open, then the map unfolded
-- Nothing is left behind: every setting it changes is put back (the options file too), the
-- things it adds are taken away, what it opens is shut. If the run goes over its time it jumps
-- to the put-back and ends there. Ends with "ZEDQA cw DONE".
--
-- How the pointer and the pad are driven:
--  * Cues. The controller's marks show only after a pad press reaches a ZeD window and go
--    off as soon as the pointer travels more than a few units (Input/FocusManager.lua,
--    _showCues). So the pointer is parked first, given a few frames to settle, and only then
--    does a pad press go in (Focus.dispatchJoypadDir / dispatchJoypadDown). A button name that
--    is bound to nothing ("QA") shows the cues without doing anything.
--  * A is the element's own onActivate (the hold timer of a real A press needs a real button).
--  * The resize handle and the window box read the raw pointer (Organisms.lua update(): the
--    engine's mouse position and isMouseOver), so those shots move the real pointer with
--    Mouse.setXY, as the gallery scripts do.
--  * Optional: set ZEDQA_CW_SPOT = { x, y, z } before the run to stand the character on open
--    ground for the see-through shots (Irvington Speedway's drag strip is 925, 13040, 0). The
--    character goes back afterwards. Unset, the character stays where it is.
--
-- A step that cannot find its piece says "ERR ..." and the walk goes on.
local TAG = "cw"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); say("DONE"); return end
if not (ZeD and ZeD.applyTheme and ZeD.Settings and ZeD.Settings.setSeeThrough and ZeD.Settings.setSolidInUse
        and ZeD.Settings.setFocusStyle and ZeD.Input and ZeD.Input.Focus and ZeD.Input.Detector
        and ZeD_CharacterWindow and ZeD_WorldWindow) then
    say("ERR ZeD is not loaded, or it is older than the cohesion pass"); say("DONE"); return
end
local pn = p:getPlayerNum()
local core = getCore()
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local F, D = ZeD.Input.Focus, ZeD.Input.Detector
-- B holds the helpers and S the step queue; both are declared first so every closure below sees them
local B = { n = 0, items = {}, was = {}, stash = {} }
local S = { queue = {}, qi = 1, tick = 0, lastDone = 0, nOk = 0, nErr = 0, section = "start" }

-- ===========================================================================
-- THE STEP QUEUE (driven from OnRenderTick: the pause menu stops OnTick)
-- S.step(after, fn): fn runs once, `after` frames after the step before it.
-- S.poll(after, max, fn, onTimeout): fn runs every frame until it returns true (or max frames).
-- ===========================================================================
function S.step(after, fn) S.queue[#S.queue + 1] = { after = after, fn = fn, sec = S.section } end
function S.poll(after, max, fn, onTimeout)
    S.queue[#S.queue + 1] = { after = after, fn = fn, max = max, timeout = onTimeout, sec = S.section }
end
function S.frames(n) S.step(n, function() end) end
function S.waitMs(ms)
    local t0 = nil
    S.poll(0, math.floor(ms / 3) + 900, function()
        t0 = t0 or getTimestampMs()
        return getTimestampMs() - t0 >= ms
    end)
end
-- Wait until both windows have stopped moving: place, size and drawer width the same for n frames
-- in a row (the windows widen and slide over many frames after a theme, a tab or a card)
function S.still(n, max)
    local last, same = nil, 0
    S.poll(1, max or 600, function()
        local s = B.shape()
        if s == last then same = same + 1 else same, last = 0, s end
        return same >= (n or 30)
    end, function() say("note: the windows were still moving after " .. tostring(max or 600) .. " frames; going on") end)
end
function S.err(what) S.nErr = S.nErr + 1; say("ERR " .. tostring(what)) end
function S.shot(name)
    local ok, e = pcall(function() core:TakeFullScreenshot(name .. ".png") end)
    if ok then S.nOk = S.nOk + 1; say("shot " .. name .. " ok")
    else S.nErr = S.nErr + 1; say("ERR shot " .. name .. ": " .. tostring(e)) end
end
function S.start(maxMs)
    local startMs = getTimestampMs()
    local limit = maxMs or 340000
    S.step(2, function()
        B.finish()
        say(string.format("end: %d shots ok, %d errors, %d seconds", S.nOk, S.nErr, math.floor((getTimestampMs() - startMs) / 1000)))
        say("DONE")
    end)
    local fin = #S.queue
    local function onFrame()
        S.tick = S.tick + 1
        local s = S.queue[S.qi]
        if not s then Events.OnRenderTick.Remove(onFrame); return end
        if S.qi < fin and getTimestampMs() - startMs > limit then
            say("ERR ran too long at step " .. S.qi .. " [" .. tostring(s.sec) .. "]: jumping to the put-back")
            S.nErr = S.nErr + 1
            S.qi = fin; S.lastDone = S.tick
            return
        end
        if not s.startTick then
            if S.tick - S.lastDone < s.after then return end
            s.startTick = S.tick
        end
        local done = true
        local ok, r = pcall(s.fn)
        if not ok then
            S.nErr = S.nErr + 1
            say("ERR step " .. S.qi .. " [" .. tostring(s.sec) .. "] " .. tostring(r))
        elseif s.max then
            done = r == true
            if not done and S.tick - s.startTick >= s.max then
                if s.timeout then pcall(s.timeout) end
                say("note: step " .. S.qi .. " [" .. tostring(s.sec) .. "] timed out")
                done = true
            end
        end
        if done then S.lastDone = S.tick; S.qi = S.qi + 1 end
    end
    Events.OnRenderTick.Add(onFrame)
    say("start (" .. #S.queue .. " steps)")
end

-- ===========================================================================
-- WINDOWS AND TABS (as the gallery scripts)
-- ===========================================================================
function B.CW() return CWm.getWindow() end
function B.WW() return WWm.getWindow() end
function B.try(label, fn)
    local ok, e = pcall(fn)
    if not ok then say("ERR put-back " .. label .. ": " .. tostring(e)) end
end
-- the pair side by side, centred, both at the top of the screen
function B.place()
    local c, w = B.CW(), B.WW()
    if not (c and w and CWm.isOpen() and WWm.isOpen()) or w._rolled then return false end
    if not B.lock then
        local gap = ZeD.T.px(8)
        local x0 = math.floor((core:getScreenWidth() - (c:getWidth() + gap + w:getWidth())) / 2)
        B.lock = { right = x0 + c:getWidth(), left = x0 + c:getWidth() + gap }
    end
    c._anchorRightEdge = B.lock.right
    c:setX(B.lock.right - c:getWidth()); w:setX(B.lock.left)
    c:setY(0); w:setY(0)
    return true
end
function B.openPair()
    if not (CWm.isOpen() and WWm.isOpen()) then
        if WWm.isOpen() then WWm.close() end
        if CWm.isOpen() then CWm.toggle(pn) end
        CWm.toggleBothPaired(pn)
    end
    B.place()
end
function B.closePair()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(pn)
    else
        if CWm.isOpen() then CWm.toggle(pn) end
        if WWm.isOpen() then WWm.close() end
    end
end
function B.goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
function B.charTab(id) local w = B.CW(); return (w and B.goTab(w, w._tabStripPanel, id)) and true or false end
function B.worldTab(id) local w = B.WW(); return (w and B.goTab(w, w._actionTabStrip, id)) and true or false end
-- what "still" compares: each window's place, size, drawer width and see-through fade
function B.shape()
    local t = {}
    local c, w = B.CW(), B.WW()
    for i = 1, 2 do
        local win = (i == 1) and c or w
        if win and win:isVisible() then
            local dp = win._drawerPanel
            t[#t + 1] = string.format("%d,%d,%d,%d,%d,%d,%d", win:getX(), win:getY(), win:getWidth(), win:getHeight(),
                math.floor(win._drawerEffW or 0), dp and dp:getWidth() or 0, math.floor((win._seeA or 0) * 100))
        end
    end
    return table.concat(t, ";")
end

-- ===========================================================================
-- THE POINTER
-- ===========================================================================
function B.pointAt(x, y)
    if Mouse and Mouse.setXY then pcall(function() Mouse.setXY(math.floor(x), math.floor(y)) end) end
end
-- two parking places on the empty left edge, 4 per cent of the screen apart: moving from one to the
-- other is travel enough to put the controller's marks out
function B.parkPos(k)
    local sw, sh = core:getScreenWidth(), core:getScreenHeight()
    return math.floor(sw * 0.03) + ((k == 2) and math.floor(sw * 0.04) or 0), math.floor(sh * 0.5)
end
function B.park() B.parkK = 1; B.pointAt(B.parkPos(1)) end
function B.nudge() B.parkK = (B.parkK == 1) and 2 or 1; B.pointAt(B.parkPos(B.parkK)) end

-- ===========================================================================
-- THE WINDOW BOX'S MENU (ZeD.WindowMenu), driven as the gallery scripts do
-- ===========================================================================
-- the window box's corners on the screen (left, top, right, bottom), nil when the window has none
function B.boxRect(win)
    local b = win and win.windowBoxRect and win:windowBoxRect()
    if not b then return nil end
    local ax, ay = win:getAbsoluteX(), win:getAbsoluteY()
    return math.floor(ax + b.x), math.floor(ay + b.y), math.floor(ax + b.x + b.w), math.floor(ay + b.y + b.h)
end
function B.hoverBox(win)
    local x0, y0, x1, y1 = B.boxRect(win)
    if x0 then B.pointAt((x0 + x1) / 2, (y0 + y1) / 2) end
end
function B.leafName(kind, key)
    local Sx = ZeD.Settings
    local keys, labels = Sx.baseKeys, Sx.baseLabels
    if kind == "accent" then keys, labels = Sx.accentKeys, Sx.accentLabels end
    for i, k in ipairs(keys or {}) do
        if k == key then return ZeD.tr(labels[i]) end
    end
    return tostring(key)
end
function B.menu()
    local m = ZeD.WindowMenu and ZeD.WindowMenu.current
    return (m and m._ctx and m._ctx.open) and m or nil
end
-- the hit zone of the row on level li whose words are `name` (the menu's panel covers the screen,
-- so the zones are in screen coordinates and exist once the menu has drawn a frame)
function B.menuRow(li, name)
    local m = B.menu()
    local lv = m and m._levels and m._levels[li]
    if not lv then return nil end
    for ri, r in ipairs(lv.rows) do
        if r.def and r.def.name == name then
            for _, zn in ipairs(m._hitZones or {}) do
                if zn.id == "row:" .. li .. ":" .. ri then return zn end
            end
        end
    end
    return nil
end
function B.menuHover(li, name)
    local zn = B.menuRow(li, name)
    if zn then B.pointAt(zn.x + zn.w / 2, zn.y + zn.h / 2) end
    return zn ~= nil
end
-- a click on a row: the context list's own mouse-up (a row with a submenu opens it)
function B.menuClick(li, name)
    local m, zn = B.menu(), B.menuRow(li, name)
    if not (m and zn) then return false end
    m:onMouseUp(math.floor(zn.x + zn.w / 2), math.floor(zn.y + zn.h / 2))
    return true
end

-- ===========================================================================
-- WORDS FOR THE SAY LINES, AND THE SHOT
-- ===========================================================================
-- the live settings, for the line before every shot
function B.live()
    local St = ZeD.Settings
    local function try(fn, dflt)
        local ok, v = pcall(fn)
        if ok and v ~= nil then return tostring(v) end
        return dflt
    end
    return string.format("theme %s, accent %s, size %s | see-through %s | solid while in use %s | highlight %s | hidden actions %s | input mode %s",
        tostring(ZeD.currentBase), tostring(ZeD.currentAccent), tostring(ZeD.currentSize),
        try(St.seeThrough, "?"), try(function() return St.solidInUse() and "on" or "off" end, "?"),
        try(St.focusStyle, "?"), try(St.hiddenActions, "?"), try(D.getMode, "?"))
end
function B.nextName(words)
    B.n = B.n + 1
    return string.format("zqa_cw_%02d_%s", B.n, words)
end
-- say the line, then take the shot, in this very frame
function B.shotNow(name, what)
    local ok, txt = pcall(function() if type(what) == "function" then return what() end return what end)
    if not ok then txt = "(no description: " .. tostring(txt) .. ")" end
    say("shot " .. name .. " | " .. tostring(txt) .. " | " .. B.live())
    S.shot(name)
end
-- queue one shot as a step of its own, with a pause after it (a 4K shot stalls the game about 1.5 s)
function B.snap(words, what)
    local name = B.nextName(words)
    S.step(2, function() B.shotNow(name, what) end)
    S.frames(20)
    return name
end

-- ===========================================================================
-- INVENTORY, CARD AND PAD HELPERS
-- ===========================================================================
function B.addItem(fullType)
    local it = p:getInventory():AddItem(fullType)
    if it then B.items[#B.items + 1] = it end
    return it
end
function B.removeItems()
    for i = #B.items, 1, -1 do
        local it = B.items[i]
        pcall(function()
            local c = it:getContainer()
            if c then c:Remove(it) end
        end)
    end
    B.items = {}
    B.apple, B.hammer = nil, nil
    pcall(function() ISInventoryPage.dirtyUI() end)
end
-- the pane's own selection, then the window's drawer update: what a click on the row does
-- (nil shuts the card)
function B.selectItem(item)
    local w = B.CW()
    local c = w and w._mainContent
    if not (c and w._updateDrawer) then return false end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    c._selectedItems, c._lastClickedItem = sel, item
    w._updateDrawer(c)
    return true
end
function B.padTouch(w) F.dispatchJoypadDown(w, "QA") end
function B.zoneOf(w, name)
    for i, z in ipairs(w and w._focusRing or {}) do
        if z.zone == name then return i, z end
    end
    return nil, nil
end
-- the first element of any focusable zone for which pred(el) is true, and that zone's name
function B.findEl(w, pred)
    for _, z in ipairs(w and w._focusRing or {}) do
        if z.focusable then
            for _, e in ipairs(z.elements or {}) do
                if pred(e) then return e, z.zone end
            end
        end
    end
    return nil, nil
end
-- the pad's focus onto the first element that matches, then a pad press so the cues show
function B.focusOn(w, pred)
    if not w then return nil end
    F.claimFocus(w)
    local e, zone = B.findEl(w, pred)
    if not e then return nil end
    local got = F.focusWhere(w, zone, function(x) return x == e end)
    if got then B.padTouch(w) end
    return got
end
function B.focusDesc(w)
    local z, e = F.getFocusedZone(w), F.getFocusedElement(w)
    return string.format("pad on zone %s, element %s, cues %s", tostring(z and z.zone), tostring(e and e.id),
        tostring(F.cuesVisible and F.cuesVisible()))
end
-- an inventory row that is on screen now (the hammer's when it is), else the first row
function B.pickRow(w, prefer)
    local _, z = B.zoneOf(w, "charMainInv")
    if not (z and z.focusable) then return nil end
    local ch = (w._mainContent and w._mainContent:getHeight()) or 0
    local pref, firstVis, firstAny
    for _, e in ipairs(z.elements or {}) do
        if e.item then
            firstAny = firstAny or e
            if ch > 0 and e.y >= 0 and e.y + e.h <= ch then
                firstVis = firstVis or e
                if prefer and e.item == prefer and not pref then pref = e end
            end
        end
    end
    return pref or firstVis or firstAny
end
-- a button in the open item card: the care verbs' band (verb_*) when it has one, else the main
-- header verb (hverb_*, the primary one), else the first header verb
function B.pickCardButton(w)
    local _, z = B.zoneOf(w, "charItemCard")
    if not (z and z.focusable) then return nil, nil end
    local care, prim, anyH
    for _, e in ipairs(z.elements or {}) do
        local id = tostring(e.id)
        if id:sub(1, 5) == "verb_" then care = care or e end
        if id:sub(1, 6) == "hverb_" then
            if e.isPrimary then prim = prim or e end
            anyH = anyH or e
        end
    end
    if care then return care, "care verbs' band" end
    if prim then return prim, "main verb under the name" end
    return anyH, "first verb under the name"
end
-- the input mode: the mouse's looks for every shot that is not a pad shot, the pad's for the rest.
-- Leaving the pad takes the lock through KBM for a moment so the detector's own mode follows.
function B.qPadOff()
    S.step(2, function() D.setLockedMode("kbm"); B.nudge() end)
    S.waitMs(350)
    S.step(2, function() B.nudge() end)
    S.frames(6)
end

-- ===========================================================================
-- WHAT THE WALK ADDS: three apples (a stack) and a hammer
-- ===========================================================================
function B.addStuff()
    for _ = 1, 3 do
        local a = B.addItem("Base.Apple")
        B.apple = B.apple or a
    end
    B.hammer = B.addItem("Base.Hammer")
    pcall(function() ISInventoryPage.dirtyUI() end)
    say(string.format("added: apples %s, hammer %s", tostring(B.apple ~= nil), tostring(B.hammer ~= nil)))
end

-- ===========================================================================
-- THE SNAPSHOT OF WHAT IS PUT BACK
-- ===========================================================================
function B.snapshot()
    local W = B.was
    local St = ZeD.Settings
    W.base, W.accent, W.size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    W.see = St.seeThroughIndex and St.seeThroughIndex() or nil
    W.solid = St.solidInUse and St.solidInUse() or false
    W.focus = St.focusStyle and St.focusStyle() or "hand"
    W.hidden = St.hiddenActionsOption and St.hiddenActionsOption:getValue() or nil
    W.speed = getGameSpeed()
    W.cOpen, W.wOpen = CWm.isOpen(), WWm.isOpen()
    local c, w = B.CW(), B.WW()
    W.cTab, W.wTab = c and c._activeTab, w and w._activeTab
    W.cx, W.cy = c and c:getX(), c and c:getY()
    W.wx, W.wy = w and w:getX(), w and w:getY()
    W.focusWin = F.getFocusedWindow()
    W.p1, W.p2 = p:getPrimaryHandItem(), p:getSecondaryHandItem()
    say(string.format("start: theme %s/%s/%s, see-through index %s, solid %s, highlight %s, hidden %s, speed %s, windows %s/%s, tabs %s/%s",
        tostring(W.base), tostring(W.accent), tostring(W.size), tostring(W.see), tostring(W.solid), tostring(W.focus),
        tostring(W.hidden), tostring(W.speed), tostring(W.cOpen), tostring(W.wOpen), tostring(W.cTab), tostring(W.wTab)))
end

-- ===========================================================================
-- OPTIONAL OPEN GROUND FOR THE SEE-THROUGH SHOTS
-- ===========================================================================
function B.spotGo()
    local sp = ZEDQA_CW_SPOT
    if type(sp) ~= "table" then return end
    local x, y, z = sp[1] or sp.x, sp[2] or sp.y, sp[3] or sp.z or 0
    if not (x and y) then return end
    B.home = B.home or { p:getX(), p:getY(), p:getZ() }
    pcall(function()
        p:teleportTo(x, y, z)
        p:setX(x); p:setY(y); p:setZ(z); p:setLastX(x); p:setLastY(y); p:setLastZ(z)
    end)
    say(string.format("see-through: standing the character on %d, %d, %d", math.floor(x), math.floor(y), math.floor(z)))
end
function B.spotBack()
    local h = B.home
    if not h then return end
    B.home = nil
    pcall(function()
        p:teleportTo(h[1], h[2], h[3])
        p:setX(h[1]); p:setY(h[2]); p:setZ(h[3]); p:setLastX(h[1]); p:setLastY(h[2]); p:setLastZ(h[3])
    end)
    say("the character is back where the walk found it")
end

-- ===========================================================================
-- THE PUT-BACK (also what a run that goes over time jumps to)
-- ===========================================================================
function B.stashTools()
    local inv = p:getInventory()
    local preds = {
        function(it) return not it:isBroken() and (it:hasTag(ItemTag.SCISSORS) or it:getType() == "Scissors") end,
        function(it) return not it:isBroken() and (it:hasTag(ItemTag.RAZOR) or it:getType() == "Razor") end,
    }
    for _, pred in ipairs(preds) do
        for _ = 1, 8 do
            local ok, it = pcall(function() return inv:getFirstEvalRecurse(pred) end)
            if not (ok and it) then break end
            local c = it:getContainer()
            if not c then break end
            c:Remove(it)
            B.stash[#B.stash + 1] = { item = it, container = c }
        end
    end
    say("hair: " .. #B.stash .. " scissors / razor set aside for the two shots (put back after)")
end
function B.unstashTools()
    for i = #B.stash, 1, -1 do
        local s = B.stash[i]
        pcall(function() s.container:AddItem(s.item) end)
    end
    if #B.stash > 0 then say("hair: " .. #B.stash .. " scissors / razor put back") end
    B.stash = {}
    pcall(function() ISInventoryPage.dirtyUI() end)
end
function B.finish()
    local W = B.was
    local St = ZeD.Settings
    local try = B.try
    try("input mode", function() D.setLockedMode(nil) end)
    try("map pop-out", function()
        local w = B.WW()
        if w and w._mapPopout and ZeD.MapsTab and ZeD.MapsTab.closePopout then ZeD.MapsTab.closePopout(w) end
        if w then w._mapStyleMenuOpen = nil; w._mapStyleMenuZones = nil end
    end)
    try("sort pop-up", function()
        local w = B.WW()
        local st = w and w._craftState
        if st and st.sortMenuOpen and ZeD.CraftingCore then ZeD.CraftingCore.closeSortMenu(st) end
    end)
    try("window menu", function() local m = B.menu(); if m then m:close() end end)
    try("messages", function()
        local MS, MW = ZeD.Messages, ZeD.MessagesWindow
        if MS and B.MSG and MS.sources and MS.sources[B.MSG] then MS.clear(B.MSG) end
        if MW then
            MW.qaJoy = nil
            local mw = B.msgOpened and MW.get and MW.get(pn)
            if mw and mw:isReallyVisible() then mw:close() end
        end
    end)
    try("equip card", function()
        local c = B.CW()
        if c then c._equipSelected = nil; c._gpFocusedEquipSlot = nil end
    end)
    try("hair tools", function() B.unstashTools() end)
    try("hair fold", function()
        local DS = ZeD.Disclose
        for k, was in pairs(B.hairOpenWas or {}) do if DS then DS.setOpen(k, was) end end
        B.hairOpenWas = nil
    end)
    try("hands", function()
        if not B.handsTouched then return end
        p:setPrimaryHandItem(W.p1)
        p:setSecondaryHandItem(W.p2)
        B.handsTouched = nil
        local hb = getPlayerHotbar and getPlayerHotbar(pn)
        if hb and hb.refresh then hb:refresh() end
    end)
    try("card", function() B.selectItem(nil) end)
    try("added items", function() B.removeItems() end)
    -- settings: the choices first, then the theme (the options follow it), then see-through (it applies the
    -- theme again from the options), then the hidden-actions pick, then the options file
    try("solid while in use", function() St.setSolidInUse(W.solid) end)
    try("highlight", function() St.setFocusStyle(W.focus) end)
    try("theme", function()
        ZeD.applyTheme(W.base, W.accent, W.size)
        if St.syncToModOptions then St.syncToModOptions() end
    end)
    try("see-through", function() if W.see then St.setSeeThrough(W.see) end end)
    try("hidden actions", function()
        if St.hiddenActionsOption and W.hidden then St.hiddenActionsOption:setValue(W.hidden) end
    end)
    try("options file", function() if St.save then St.save() end end)
    -- windows: the tabs, then where they stood, then open or shut as they were
    try("tabs", function()
        if B.CW() and W.cTab then B.charTab(W.cTab) end
        if B.WW() and W.wTab then B.worldTab(W.wTab) end
    end)
    try("window places", function()
        local c, w = B.CW(), B.WW()
        if c and W.cx and CWm.isOpen() then c:setX(W.cx); c:setY(W.cy) end
        if w and W.wx and WWm.isOpen() then w:setX(W.wx); w:setY(W.wy) end
    end)
    try("pair open or shut", function()
        if not (W.cOpen or W.wOpen) and (CWm.isOpen() or WWm.isOpen()) then B.closePair() end
    end)
    try("character spot", function() B.spotBack() end)
    try("pad focus", function()
        if W.focusWin and W.focusWin.isVisible and W.focusWin:isVisible() then F.claimFocus(W.focusWin)
        elseif F.getFocusedWindow() then F.releaseFocus() end
    end)
    try("pointer", function() B.nudge() end)
    try("game speed", function() if W.speed and W.speed <= 0 then setGameSpeed(W.speed) end end)
    say("put back: the settings, the options file, the windows, the added items")
end

-- ===========================================================================
-- THE WALK
-- ===========================================================================

-- start: snapshot, run the game, add the apples and the hammer, windows open on Loot
function B.buildStart()
    S.section = "start"
    S.step(2, function()
        B.snapshot()
        if getGameSpeed() <= 0 then pcall(setGameSpeed, 1); say("the game was paused: running it for the walk (put back at the end)") end
        D.setLockedMode("kbm")
        B.openPair()
        B.addStuff()
        B.park()
    end)
    S.still(40)
    S.step(2, function()
        B.charTab("loot"); B.worldTab("loot")
        B.nudge()   -- travel far enough to put out any marks an earlier run left lit
    end)
    S.still(20)
end

-- 1. themes x text sizes
function B.buildThemes()
    S.section = "1 themes and sizes"
    local COMBOS = { { "dark", "small" }, { "dark", "large" }, { "light", "small" }, { "light", "large" },
                     { "hicon", "small" }, { "hicon", "large" } }
    for _, c in ipairs(COMBOS) do
        local base, size = c[1], c[2]
        S.step(2, function()
            B.park()
            B.selectItem(nil)
            B.charTab("loot"); B.worldTab("loot")
            ZeD.applyTheme(base, ZeD.currentAccent, size)
        end)
        S.still(30)
        S.step(2, function() B.lock = nil; B.place() end)   -- centred again at this size, the card shut
        S.still(20)
        S.step(2, function()
            if not B.selectItem(B.apple) then S.err("themes " .. base .. "/" .. size .. ": the inventory pane is not there to pick the apple") end
        end)
        S.still(30)
        S.step(2, function() B.place() end)
        S.frames(10)
        B.snap(base .. "_" .. size .. "_card", function()
            local w = B.CW()
            return string.format("both windows: Character on its inventory with the apple's card open (card item %s), World on Loot",
                tostring(w and w._drawerItem and w._drawerItem:getDisplayName()))
        end)
        if base == "dark" and size == "small" then
            local themeRow = ZeD.tr("UI_ZeD_WinMenu_Theme")
            B.menuShow(function() return B.CW() end, themeRow, function() return B.leafName("base", ZeD.currentBase) end,
                "dark_small_window_menu_theme",
                "the Character window's window box menu pulled down, its Theme submenu open, the pointer on the theme in use")
        end
    end
end

-- the window box's menu: pulled down, the parent row clicked, the pointer on a choice, one shot, the menu shut
-- without a pick (nothing is changed)
function B.menuShow(getWin, parent, getChoice, words, what)
    S.step(2, function()
        local w = getWin()
        if not w then S.err(words .. ": no window to pull the menu from"); return end
        B.hoverBox(w)
        w:openWindowMenu()
    end)
    S.poll(2, 180, function() return B.menuRow(1, parent) ~= nil end,
        function() S.err(words .. ": the menu did not draw its " .. tostring(parent) .. " row") end)
    S.step(2, function() B.menuClick(1, parent) end)
    S.poll(2, 180, function() return B.menuRow(2, getChoice()) ~= nil end,
        function() S.err(words .. ": the submenu did not draw " .. tostring(getChoice())) end)
    S.step(2, function() B.menuHover(2, getChoice()) end)
    S.frames(12)
    B.snap(words, what)
    S.step(2, function()
        local m = B.menu()
        if m then pcall(function() m:close() end) end
        B.park()
    end)
    S.frames(10)
end

-- 2. see-through at dark / small
function B.buildSeeThrough()
    S.section = "2 see-through"
    S.step(2, function()
        B.park()
        -- dark / small in the options too: setSeeThrough applies the theme again from the options
        ZeD.applyTheme("dark", ZeD.currentAccent, "small")
        pcall(ZeD.Settings.syncToModOptions)
        B.charTab("loot"); B.worldTab("loot")
        B.spotGo()
        local sq = p:getSquare()
        say("see-through: the character is " .. ((sq and sq:isOutside()) and "outside" or "indoors or unknown")
            .. " | square at " .. math.floor(p:getX()) .. ", " .. math.floor(p:getY()))
    end)
    S.poll(5, 600, function()
        if not B.home then return true end
        local ok, sq = pcall(function() return getCell():getGridSquare(math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())) end)
        return ok and sq ~= nil
    end)
    S.waitMs(600)
    S.step(2, function() B.lock = nil; B.place() end)
    S.still(30)
    S.step(2, function() B.selectItem(B.apple) end)   -- the card too: its surface must follow the value
    S.still(30)
    S.step(2, function() B.place() end)
    local keys = ZeD.Settings.seeThroughKeys or { 100, 90, 80, 70, 60 }
    for i, v in ipairs(keys) do
        S.step(2, function() ZeD.Settings.setSeeThrough(i); B.park() end)
        S.still(30)
        B.snap("seethrough_" .. tostring(v), function()
            return "both windows with the apple's card open at see-through " .. tostring(v) .. ", the world behind them"
        end)
    end
    S.step(2, function()
        ZeD.Settings.setSeeThrough(#keys)
        ZeD.Settings.setSolidInUse(true)
        local c = B.CW()
        if c then
            -- the title bar: nothing there answers a hover
            B.pointAt(c:getAbsoluteX() + math.floor(c:getWidth() * 0.4), c:getAbsoluteY() + math.floor(c:titleBarHeight() / 2))
        end
    end)
    S.waitMs(700)   -- the fade to solid takes 200 ms
    B.snap("seethrough_" .. tostring(keys[#keys]) .. "_solid_pointer_on_character", function()
        local c, w = B.CW(), B.WW()
        return string.format("see-through %s with Solid while in use on, the pointer on the Character window (its surface alpha %s, the World window's %s)",
            tostring(keys[#keys]), tostring(c and c._seeA), tostring(w and w._seeA))
    end)
    S.step(2, function()
        ZeD.Settings.setSolidInUse(B.was.solid)
        ZeD.Settings.setSeeThrough(B.was.see or 2)
        B.park()
        B.spotBack()
    end)
    S.waitMs(500)
    S.still(30)
end

-- 3. controller highlight styles
function B.buildFocusStyles()
    S.section = "3 highlight styles"
    S.step(2, function()
        B.park()
        if not B.selectItem(B.hammer) then S.err("highlight: could not open the hammer's card") end
    end)
    S.still(40)
    S.step(2, function() D.setLockedMode("gamepad") end)
    S.frames(8)
    for _, style in ipairs({ "hand", "corners", "wash", "ants" }) do
        S.step(2, function() ZeD.Settings.setFocusStyle(style); B.park() end)
        S.frames(10)
        S.step(2, function()
            local w = B.CW()
            F.claimFocus(w)
            local row = B.pickRow(w, B.hammer)
            local got = row and B.focusOn(w, function(x) return x == row end)
            if not got then S.err("highlight " .. style .. ": no inventory row to put the pad on") end
        end)
        S.frames(12)
        B.snap("focus_" .. style .. "_inventory_row", function()
            return "pad focus on an inventory row of the Character window | " .. B.focusDesc(B.CW())
        end)
        S.step(2, function()
            local w = B.CW()
            local btn, kind = B.pickCardButton(w)
            B.cardKind = kind
            local got = btn and B.focusOn(w, function(x) return x == btn end)
            if not got then S.err("highlight " .. style .. ": no button in the item card to put the pad on") end
        end)
        S.frames(12)
        B.snap("focus_" .. style .. "_card_button", function()
            return "pad focus on a button of the item card (" .. tostring(B.cardKind) .. ") | " .. B.focusDesc(B.CW())
        end)
    end
    S.step(2, function() ZeD.Settings.setFocusStyle(B.was.focus) end)
    B.qPadOff()
end

-- 4. the drawer sliding open: two shots on two separate opens (a shot stalls the game, and the
-- slide is over by the time a second shot could follow the first)
function B.buildSlide()
    S.section = "4 drawer slide"
    for k, frac in ipairs({ 0.25, 0.60 }) do
        S.step(2, function() B.park(); B.selectItem(nil) end)
        S.poll(2, 240, function()
            local c = B.CW()
            return (not c) or (c._drawerEffW or 0) < 1
        end)
        S.still(20)
        local name = B.nextName(k == 1 and "drawer_slide_early" or "drawer_slide_late")
        S.step(2, function()
            if not B.selectItem(B.hammer) then S.err("drawer slide: could not open the hammer's card") end
        end)
        -- the shot is taken in the frame the drawer first reaches that part of its way
        S.poll(0, 120, function()
            local c = B.CW()
            local target = ZeD.T.px(220)   -- an item card's width (ZeD_CharacterWindow.lua ITEM_CARD_W)
            local eff = c and (c._drawerEffW or 0) or 0
            if eff >= frac * target then
                B.shotNow(name, string.format("the item card's drawer %d per cent open and still sliding: the window frame must stay on top",
                    math.floor(eff / target * 100 + 0.5)))
                return true
            end
            return false
        end, function() S.err("drawer slide " .. k .. ": the drawer never reached " .. tostring(frac)) end)
        S.frames(20)
        S.still(30)
    end
end

-- 5. the resize handle: the pointer held still on an edge
function B.buildResize()
    S.section = "5 resize handle"
    S.step(2, function() B.park(); B.selectItem(nil) end)
    S.still(40)
    -- Organisms.lua reads the engine's pointer (getMouseX / getMouseY and isMouseOver) every frame and
    -- lights the handle after the pointer has rested 350 ms in a zone: the real pointer is moved here
    S.step(2, function()
        local c = B.CW()
        if not c then S.err("resize: no Character window"); return end
        local T = ZeD.T
        local x = c:getAbsoluteX() + math.floor(c:getWidth() / 2)
        local y = math.min(c:getAbsoluteY() + c:getHeight() - T.px(3), core:getScreenHeight() - 2)
        B.pointAt(x, y)
    end)
    S.waitMs(650)
    B.snap("resize_handle_bottom_edge", function()
        local c = B.CW()
        return "the pointer held on the Character window's bottom edge for 650 ms; handle lit: " .. tostring(c and c._rzLit)
    end)
    S.step(2, function()
        local c = B.CW()
        if not c then return end
        local T = ZeD.T
        local tb = c:titleBarHeight()
        local x = c:getAbsoluteX() + c:getWidth() - T.px(2)
        local y = c:getAbsoluteY() + tb + math.floor((c:getHeight() - tb - c:footerHeight()) / 2)
        B.pointAt(x, y)
    end)
    S.waitMs(650)
    B.snap("resize_handle_right_edge", function()
        local c = B.CW()
        return "the pointer held on the Character window's right edge for 650 ms; handle lit: " .. tostring(c and c._rzLit)
    end)
    S.step(2, function() B.park() end)
    S.frames(10)
end

-- 6a. Craft's sort pop-up, with the pad in it
function B.buildCraftSort()
    S.section = "6a craft sort pop-up"
    local function menuZone()
        local ww = B.WW()
        local st = ww and ww._craftState
        for _, z in ipairs(st and st.zones or {}) do
            if z.type == "sortMenu" then return z end
        end
        return nil
    end
    S.step(2, function()
        B.park()
        if not B.worldTab("craft") then S.err("craft sort: the World window has no Craft tab") end
    end)
    S.still(30)
    -- the Sort pop-up box sits in the card's band (Oct 30 2026, punch list 21: the sort strip's
    -- radio buttons went); the Large-text retry below stays as a fallback
    S.poll(2, 120, function() return menuZone() ~= nil end, function() end)
    S.step(2, function()
        if menuZone() == nil then
            say("note: Craft's sort strip shows its radio buttons at this size; trying Large text")
            B.sortLarge = true
            ZeD.applyTheme(nil, nil, "large")
        end
    end)
    S.still(30)
    S.poll(2, 120, function() return menuZone() ~= nil end,
        function() B.sortMissing = true; S.err("craft sort: no pop-up box on the sort strip, even at Large text") end)
    S.step(2, function() D.setLockedMode("gamepad"); B.park() end)
    S.frames(10)
    S.step(2, function()
        local ww = B.WW()
        if B.sortMissing or not ww then return end
        local e = B.focusOn(ww, function(x) return x.craftKind == "sortMenu" end)
        if not e then S.err("craft sort: the pad could not land on the sort box"); return end
        pcall(e.onActivate, ww, e)   -- A on the box opens the list
    end)
    S.frames(20)
    S.step(2, function()
        local ww = B.WW()
        local st = ww and ww._craftState
        if B.sortMissing or not st then return end
        local cur = F.getFocusedElement(ww)
        if not (cur and cur.craftKind == "sortRow") then
            local e = B.focusOn(ww, function(x) return x.craftKind == "sortRow" and x.sortId == st.sort end)
            if not e then S.err("craft sort: the pad is not in the open list") end
        end
        B.padTouch(ww)
    end)
    S.frames(10)
    B.snap("craft_sort_popup_pad", function()
        local ww = B.WW()
        local st = ww and ww._craftState
        return string.format("World window, Craft tab: the sort pop-up open (list open %s, sort %s) | %s",
            tostring(st and st.sortMenuOpen), tostring(st and st.sort), B.focusDesc(ww))
    end)
    S.step(2, function()
        local ww = B.WW()
        local st = ww and ww._craftState
        if st and st.sortMenuOpen then ZeD.CraftingCore.closeSortMenu(st) end
        B.worldTab("loot")
        if B.sortLarge then ZeD.applyTheme(nil, nil, "small"); B.sortLarge = nil end
    end)
    S.still(30)
end

-- 6b. Messages: the Delete question with the pad on Cancel
function B.buildMessages()
    S.section = "6b messages"
    local SRC = "ZeD QA walk"
    B.MSG = SRC
    S.step(2, function()
        local MS, MW = ZeD.Messages, ZeD.MessagesWindow
        if not (MS and MW and MS.add and MW.open) then S.err("messages: the store or the window is missing"); return end
        -- a note of its own, so the window has something to delete whether or not other mods filed any
        MS.add(SRC, "mods", { k = "note", text = "QA: a note kept for the cohesion walk. Delete asks before it throws a source away.",
                              buttons = { { title = "OK" } } })
        B.msgWin = MW.open(pn, SRC)
        B.msgOpened = true
        MW.qaJoy = true   -- the window's QA hook: it draws as if a controller held it
        B.nudge()         -- the marks the Craft shot left on the other windows go out (the Messages window marks itself)
    end)
    S.frames(20)
    S.step(2, function()
        local win = B.msgWin
        if not win then return end
        win:pressFoot({ id = "clear" })   -- A on Delete: the question comes up with the pad on Cancel
    end)
    S.frames(20)
    B.snap("messages_delete_question_cancel", function()
        local win = B.msgWin
        return string.format("Messages window: the Delete question in the band, pad on Cancel (asking %s, zone %s, button %s)",
            tostring(win and win.asking), tostring(win and win.zone), tostring(win and win.footFocus))
    end)
    S.step(2, function()
        local win = B.msgWin
        if win and win.asking then win:cancelAsk() end
        if ZeD.Messages.sources[SRC] then ZeD.Messages.clear(SRC) end
        if win then win:close() end
        if ZeD.MessagesWindow then ZeD.MessagesWindow.qaJoy = nil end
        B.msgOpened = nil
        B.msgWin = nil
    end)
    S.frames(15)
end

-- 6c. the item card's Back key with the pad on it
function B.buildBackKey()
    S.section = "6c card back key"
    S.step(2, function() B.park(); B.selectItem(B.hammer) end)
    S.still(30)
    S.step(2, function()
        local c = B.CW()
        B.backPath = "equip"
        local _, z = B.zoneOf(c, "charItemCard")
        for _, e in ipairs(z and z.elements or {}) do
            local id = tostring(e.id)
            if id == "back" or id:match("[:_]back$") then B.backPath = "inventory" end
        end
        if B.backPath == "equip" then
            -- the inventory card has no Back stop; the Equip tab's card does (equipcard:back)
            say("back key: the inventory card has no pad stop on its Back key; using the Equip tab's card")
            B.selectItem(nil)
            B.charTab("equip")
        end
    end)
    S.still(40)
    S.step(2, function()
        local c = B.CW()
        if B.backPath ~= "equip" or not c then return end
        local pick
        for _, g in ipairs(c._equipCache and c._equipCache.groups or {}) do
            if g.id ~= "held" then
                for _, s in ipairs(g.slots or {}) do
                    if not pick and s.item then pick = s end
                end
            end
        end
        if not pick then S.err("back key: nothing is worn, so the Equip tab has no card to open"); B.backPath = nil; return end
        c._equipSelected = pick.type   -- what a click on the slot does (EquipmentTab selectSlot)
        c._equipCache = nil
        c._gpFocusedEquipSlot = nil
    end)
    S.still(40)
    S.step(2, function() D.setLockedMode("gamepad"); B.park() end)
    S.frames(10)
    S.step(2, function()
        local c = B.CW()
        if not (c and B.backPath) then return end
        local e = B.focusOn(c, function(x)
            local id = tostring(x.id)
            return id == "back" or id == "equipcard:back"
        end)
        if not e then S.err("back key: the pad could not land on the card's Back key (" .. tostring(B.backPath) .. ")") end
    end)
    S.frames(12)
    B.snap("card_back_key_pad", function()
        return "the item card (" .. tostring(B.backPath) .. " path) with the pad on its Back key | " .. B.focusDesc(B.CW())
    end)
    S.step(2, function()
        local c = B.CW()
        if c then c._equipSelected = nil; c._gpFocusedEquipSlot = nil end
        B.selectItem(nil)
        B.charTab("loot")
    end)
    B.qPadOff()
    S.still(30)
end

-- 7. Hair and beard with no scissors: Hidden actions folded, then Show all
function B.buildHair()
    S.section = "7 hidden actions"
    S.step(2, function()
        B.park()
        B.stashTools()
        local DS = ZeD.Disclose
        B.hairOpenWas = {}
        for _, k in ipairs({ "hb:more:hair", "hb:more:beard" }) do
            B.hairOpenWas[k] = (DS and DS.isOpen(k)) and true or false
            if DS then DS.setOpen(k, false) end
        end
        if ZeD.Settings.hiddenActionsOption then ZeD.Settings.hiddenActionsOption:setValue(1) end
        B.charTab("identity")
    end)
    S.still(40)
    -- scroll so the Hair and beard section starts under the tab header: its distance from the top is read at
    -- scroll 0, the longest scroll at scroll 1
    S.step(2, function()
        local c = B.CW()
        if ZeD.HairBeard and c then pcall(ZeD.HairBeard.setPart, c, "hair") end
        if c and c._identityScroll then c._identityScroll:setScrollPos(0) end
    end)
    S.frames(45)   -- the section reads the character's tools about twice a second
    S.step(2, function()
        local c = B.CW()
        local st = c and ZeD.HairBeard and ZeD.HairBeard.state(c)
        local v = c and c._idView
        B.hairOff = (st and st.top and v) and (st.top - v.y) or nil
        if c and c._identityScroll then c._identityScroll:setScrollPos(1) end
    end)
    S.frames(12)
    S.step(2, function()
        local c = B.CW()
        local maxOff = c and c._identityScrollOff or 0
        if c and c._identityScroll and B.hairOff and maxOff > 0 then
            local f = math.max(0, math.min(1, (B.hairOff - ZeD.T.px(4)) / maxOff))
            c._identityScroll:setScrollPos(f)
        end
    end)
    S.still(30)
    B.snap("hair_beard_folded", function() return "Identity tab, Hair and beard, Hidden actions folded | " .. B.hairLine() end)
    S.step(2, function()
        if ZeD.Settings.hiddenActionsOption then ZeD.Settings.hiddenActionsOption:setValue(2) end
    end)
    S.frames(15)
    S.still(30)
    B.snap("hair_beard_show_all", function() return "Identity tab, Hair and beard, Hidden actions Show all | " .. B.hairLine() end)
    S.step(2, function()
        if ZeD.Settings.hiddenActionsOption and B.was.hidden then ZeD.Settings.hiddenActionsOption:setValue(B.was.hidden) end
        B.unstashTools()
        local DS = ZeD.Disclose
        for k, was in pairs(B.hairOpenWas or {}) do if DS then DS.setOpen(k, was) end end
        B.hairOpenWas = nil
        B.charTab("loot")
    end)
    S.still(30)
end
-- what the Hair and beard section shows, for the say line
function B.hairLine()
    local c = B.CW()
    local HB = ZeD.HairBeard
    local st = c and HB and HB.state(c)
    local more
    for _, it in ipairs(st and st.L and st.L.items or {}) do
        if it.kind == "more" then more = it end
    end
    local tl = (st and st.tools) or {}
    local rowText = "none"
    if more and ZeD.Disclose then
        local ok, t = pcall(ZeD.Disclose.rowText, more.groups)
        rowText = ok and ('"' .. tostring(t) .. '"') or "?"
    end
    return string.format("folded row: %s | tools in reach: razor %s, scissors %s, gel %s, spray %s | set aside %d",
        rowText, tostring(tl.razor ~= nil), tostring(tl.scissors ~= nil), tostring(tl.gel ~= nil), tostring(tl.spray ~= nil), #B.stash)
end

-- 8. status bars: the Health tab, the belt with a hand item at 45 per cent
function B.buildBars()
    S.section = "8 status bars"
    S.step(2, function() B.park(); B.charTab("health") end)
    S.still(40)
    B.snap("health_tab_bars", "the Character window's Health tab: the condition and body-part bars")
    S.step(2, function()
        B.charTab("loot")
        B.closePair()   -- the belt in plain sight, as the ring test does it
        local h = B.hammer
        if not h then S.err("belt: no hammer to hold"); return end
        pcall(function()
            h:setCondition(math.max(1, math.floor(h:getConditionMax() * 0.45 + 0.5)))
            p:setPrimaryHandItem(h)
            B.handsTouched = true
        end)
    end)
    S.still(40)
    B.snap("belt_hand_45", function()
        local h = B.hammer
        local cond = h and ZeD.Belt and ZeD.Belt.cond and ZeD.Belt.cond(h) or nil
        local hud = ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD()
        return string.format("the belt with the hammer in the main hand at condition %s (windows shut; belt drawn %s)",
            tostring(cond and (math.floor(cond * 100 + 0.5) .. " per cent")), tostring(hud and hud:isVisible()))
    end)
    S.step(2, function()
        pcall(function()
            p:setPrimaryHandItem(B.was.p1)
            p:setSecondaryHandItem(B.was.p2)
            B.handsTouched = nil
            local hb = getPlayerHotbar and getPlayerHotbar(pn)
            if hb and hb.refresh then hb:refresh() end
        end)
        B.openPair()
        B.charTab("loot"); B.worldTab("loot")
    end)
    S.still(40)
end

-- 9. the Maps tab: the Survey / Color / Paper pop-up, then the map unfolded
function B.buildMaps()
    S.section = "9 maps"
    S.step(2, function()
        B.park()
        if not B.worldTab("maps") then S.err("maps: the World window has no Maps tab") end
    end)
    S.poll(5, 400, function()
        local w = B.WW()
        return w ~= nil and w._worldMapPanel ~= nil and w._mapStyleZones ~= nil
    end, function() S.err("maps: the map panel did not come up") end)
    S.still(40)
    -- the pop-up box replaces the radio buttons only when they do not all fit the band
    -- (Oct 30 2026: Survey / Color / Paper are on the card's band, at its left; the
    -- pop-up's list opens upward over the map)
    S.step(2, function()
        local w = B.WW()
        if w and not w._mapStyleMenuZone then
            say("note: the Maps band shows its radio buttons at this size; trying Large text")
            B.mapLarge = true
            ZeD.applyTheme(nil, nil, "large")
        end
    end)
    S.still(40)
    S.step(2, function() D.setLockedMode("gamepad"); B.park() end)
    S.frames(10)
    S.step(2, function()
        local w = B.WW()
        B.mapMenu = false
        if not w then return end
        if not w._mapStyleMenuZone then
            -- (the band has more room than the old toolbar row: the radio buttons may fit even at Large text)
            if w._mapStyleZones and #w._mapStyleZones > 0 then
                say("note: the Maps band shows its radio buttons even at Large text; no pop-up to open")
                B.focusOn(w, function(x) return x.id == "map:style:survey" end)
            else
                S.err("maps: no Survey / Color / Paper on the band (the base map has no paper style?)")
            end
            return
        end
        local e = B.focusOn(w, function(x) return x.id == "map:style:menu" end)
        if not e then S.err("maps: the pad could not land on the style box"); return end
        pcall(e.onActivate, w, e)   -- A on the box: the list opens and the pad goes into it
        B.mapMenu = true
    end)
    S.frames(25)
    S.step(2, function()
        local w = B.WW()
        if w and B.mapMenu then B.padTouch(w) end
    end)
    S.frames(10)
    B.snap("maps_style_popup_pad", function()
        local w = B.WW()
        return string.format("World window, Maps tab: the band with Survey / Color / Paper (pop-up list open %s) | %s",
            tostring(w and w._mapStyleMenuOpen), B.focusDesc(w))
    end)
    S.step(2, function()
        local w = B.WW()
        if w then w._mapStyleMenuOpen = nil; w._mapStyleMenuZones = nil end
        if B.mapLarge then ZeD.applyTheme(nil, nil, "small"); B.mapLarge = nil end
    end)
    B.qPadOff()
    S.still(40)
    S.step(2, function()
        local w = B.WW()
        if not (w and ZeD.MapsTab and ZeD.MapsTab.openPopout) then S.err("maps: no pop-out to open"); return end
        ZeD.MapsTab.openPopout(w)
    end)
    S.poll(5, 400, function()
        local w = B.WW()
        return w ~= nil and w._mapPopout ~= nil and w._worldMapPanel ~= nil
    end, function() S.err("maps: the pop-out did not come up") end)
    S.waitMs(1500)   -- the map's tiles load in
    B.snap("maps_popout", function() return "the map unfolded into its own window, toolbar visible" end)
    S.step(2, function()
        local w = B.WW()
        if w and w._mapPopout then ZeD.MapsTab.closePopout(w) end
    end)
    S.still(40)
    S.step(2, function() B.worldTab("loot") end)
    S.still(30)
end

-- the end: cards and windows back to how the walk found them, before the put-back
function B.buildEnd()
    S.section = "end"
    S.step(2, function()
        B.park()
        B.selectItem(nil)
        B.charTab(B.was.cTab or "loot")
        B.worldTab(B.was.wTab or "loot")
    end)
    S.still(40)
    S.step(2, function()
        local c, w = B.CW(), B.WW()
        if c and B.was.cx then c:setX(B.was.cx); c:setY(B.was.cy) end
        if w and B.was.wx then w:setX(B.was.wx); w:setY(B.was.wy) end
    end)
    S.frames(10)
end

B.buildStart()
B.buildThemes()
B.buildSeeThrough()
B.buildFocusStyles()
B.buildSlide()
B.buildResize()
B.buildCraftSort()
B.buildMessages()
B.buildBackKey()
B.buildHair()
B.buildBars()
B.buildMaps()
B.buildEnd()
S.start(340000)
