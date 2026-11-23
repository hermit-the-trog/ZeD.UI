-- ZeDUI/tools/qa/vk4_belt.lua  (Nov 22 2026, QA; tag vk4_belt): the in-game proof of the director's belt row notes,
-- Build's commit 313d74d0e on branch k3 (on top of main ba8084973). The director: "The backpack icon down in the belt
-- row, it should go set it off about an icon's worth to the left. Same with notes, set that off about an icon's worth
-- to the right... Just move them [the time buttons] to the left of the backpack icon... the watches are on the left or
-- the right side of the hands. And then for the backpack, that should be a right mouse button click, and you can
-- change it to whatever bag you have on... It defaults to the pocket icon... that click takes you like directly to
-- your backpack... Or if you just want to open up your inventory from there, it just opens up the pocket."
-- Built on rt_kit.lua (the global RT), run after zedqa_prelude.lua. grep "ZEDQA vk4_belt". Manifest: vk4.txt.
--
-- How to read the log: the proofs are the lines that start "BELT"; each FAILS on ba8084973 and PASSES on 313d74d0e.
-- A part that cannot be staged FAILS with "(staging)" in its words. "NOTE" lines are readings. The "put back" checks
-- at the end pass on both: the run left him as it found him.
--
-- The belt's boxes are read as the belt laid them out (hud._boxes, left to right, in its own coordinates). "An icon's
-- gap" is the bag button's own size, ZeD.T.px(B.ICON_GAP), 38 design units (the old code has no B.ICON_GAP: 38, the
-- bag button's size LAMP, is the director's "an icon's worth"), within 2 px. The belt starts at the first box after
-- the bag button (the watch on the left wrist, else the off hand) and ends at the right edge of the strap or the last
-- box before the Messages note. The pointer is the one thing faked for a press: the global getMouseX / getMouseY
-- answer the bag button's middle for that call only, and the belt's own handlers run (onMouseDown / onMouseUp,
-- onRightMouseDown / onRightMouseUp, onJoypadDown with the belt's pad mark on the bag button). The bag button's icon
-- is read as the belt draws it: its _drawButton watched (the icon it is handed for the box of kind "bag").
--
-- The checks:
--   BELT 1  Full, no watch worn: no speed keys; the bag button first; an icon's gap from it to the belt (the off
--           hand), nothing between; an icon's gap from the belt to the Messages note. Old: 10 px gaps -> FAIL.
--   BELT 2  Full, a digital watch given and worn on the LEFT wrist: five speed keys, all left of the bag button; the
--           bag button, an icon's gap, then the watch beside the off hand; nothing between; the note an icon's gap
--           off the belt. Old: the keys sit between the bag button and the watch -> FAIL. Picture vk4_belt_full.
--   BELT 3  The same with the watch on the RIGHT wrist (the watch past the main hand). Old: the keys past the
--           watch, right of the bag button -> FAIL.
--   BELT 4  Lite (Style set by value): no speed keys on the belt (the watch is in the corner in Lite); the bag button
--           first, an icon's gap to the off hand, the note an icon's gap off the last slot. Old: 10 px -> FAIL.
--           Picture vk4_belt_lite.
--   BELT 5  Default, no pick (his modData ZeD_BeltBag cleared for the run): the button wears the pocket
--           (media/ui/Container_Pocket.png) and a click opens the pair with his main inventory on show. Old: the
--           button draws ZeD's "backpack" drawing -> FAIL.
--   BELT 6  A backpack (Base.Bag_Schoolbag) and a fanny pack (Base.Bag_FannyPackFront) given and worn. A right-click
--           on the bag button opens a menu whose rows as built (the game's menu's options) are Inventory first
--           (IGUI_InventoryTooltip) with the pocket's icon, then each bag he has on, each with its own icon
--           (item:getTex()), nothing else. Old: no menu -> FAIL. Picture vk4_belt_menu (the menu open).
--   BELT 7  The same menu as ZeD draws it (ZeD's list or strip: its rows' order and the icon each row draws):
--           Inventory first, each row its own icon. A row that draws an icon from ZeD's name-to-icon map instead
--           (Build's worry) is named with what it shows. Old: no menu -> FAIL.
--   BELT 8  Pad X on the bag button (the belt's pad mark on it): the same menu opens, the same rows. Old: X does
--           nothing there -> FAIL.
--   BELT 9  The backpack's row picked (the row's own fire, as a click on it): his modData ZeD_BeltBag holds the
--           backpack's { id, type } and the button wears the backpack's icon. Old: no menu -> FAIL. Picture
--           vk4_belt_picked.
--   BELT 10 A left click with the backpack picked: the pair opens, the Character window on Loot showing the backpack
--           alone (no columns). Old: no pick, the pair on his inventory -> FAIL.
--   BELT 11 A second click: the pair closes. Old: no pick to show alone (BELT 10 fails) -> FAIL.
--   BELT 12 Pad A on the bag button: the pair opens on the backpack alone. Old: his inventory -> FAIL.
--   BELT 13 The backpack taken off (still in his inventory): the button wears the pocket, a click opens the pair on
--           his main inventory, and the pick is kept in his modData. Old: no pick kept -> FAIL.
--   BELT 14 The backpack put on again: the button wears the backpack's icon again. Old: never -> FAIL.
--
-- Safety: nothing is eaten, read or dropped; the only things worn are the run's own (taken off and away at the end).
-- What it puts back (also when a step throws or the time runs out): menus closed; the belt's pad mark, its watched
-- drawing and the parked pointer gone, the cursor shown; both windows shut, then open or shut as found, placed and
-- on their tabs, the save's window state as found; every worn item as found (his own watch or bags back on); his
-- modData ZeD_BeltBag and ZeD_WatchPop as found; Style and Watch option values as found (values only, never saved);
-- the Messages note's staged line gone; the game speed; the input lock and the pad's focus. No file is written but
-- the four pictures (Zomboid/Screenshots/vk4_*.png).
-- Not run offline; parse-checked with the game's Kahlua compiler (KCheck).

if not (RT and RT.make) then
    print("ZEDQA vk4_belt ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vk4_belt VERDICT FAIL 1")
    print("ZEDQA vk4_belt DONE")
    return
end

local Q = RT.make("vk4_belt")
Q.maxMs = 540000   -- (nine minutes, then the put-back; a run takes about two)
local S = { p = RT.p, pn = RT.pn, was = {}, k = {}, given = {} }
local H = {}
S.Det = ZeD and ZeD.Input and ZeD.Input.Detector
S.Focus = ZeD and ZeD.Input and ZeD.Input.Focus
S.POCKET = "media/ui/Container_Pocket.png"
S.BAG, S.FANNY = "Base.Bag_Schoolbag", "Base.Bag_FannyPackFront"
S.WATCH_L, S.WATCH_R = "Base.WristWatch_Left_DigitalBlack", "Base.WristWatch_Right_DigitalBlack"
S.SRC = "QA vk4_belt"
S.CACHE_MS = 700   -- (the bag button's pick is looked up twice a second: wait past it)

-- ===================================================================== words, numbers, tables
function H.num(v)
    local x = tonumber(v)
    if x == nil then return "?" end
    local r = math.floor(x * 10 + 0.5) / 10
    if r == math.floor(r) then return tostring(math.floor(r)) end
    return tostring(r)
end
function H.copy(t, depth)
    if type(t) ~= "table" then return t end
    depth = depth or 0
    if depth > 4 then return nil end
    local o = {}
    for k, v in pairs(t) do o[k] = H.copy(v, depth + 1) end
    return o
end
function H.recText(r)
    if type(r) ~= "table" then return tostring(r) end
    return "{ id " .. tostring(r.id) .. ", type " .. tostring(r.type) .. " }"
end
function H.sameRec(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    return a.id == b.id and a.type == b.type
end
function H.md() return S.p:getModData() end
function H.now() return getTimestampMs() end

-- ===================================================================== waits (by the clock)
function H.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, math.floor(ms / 3) + 900, function()
        st.t = st.t or getTimestampMs()
        local okC, r = pcall(cond)
        if okC and r then st.ok = true; return true end
        return getTimestampMs() - st.t >= ms
    end, function() fn(st.ok == true) end)
end
function H.settle(minMs, maxMs, cond, fn)
    local st = {}
    Q.waitFor(1, math.floor(maxMs / 3) + 900, function()
        local now = getTimestampMs()
        st.t = st.t or now
        if now - st.t >= minMs then
            local okC, r = pcall(cond)
            if okC and r then st.ok = true; return true end
        end
        return now - st.t >= maxMs
    end, function() fn(st.ok == true) end)
end

-- ===================================================================== the belt
function H.B() return ZeD and ZeD.Belt or nil end
function H.hud() local h = nil; pcall(function() h = ZeD.Belt.getHUD(S.pn) end); return h end
function H.px(n) local v = n; pcall(function() v = ZeD.T.px(n) end); return v end
function H.iconGap() local B = H.B(); return H.px((B and B.ICON_GAP) or 38) end
function H.boxes() local hud = H.hud(); return (hud and hud._boxes) or {} end
function H.box(kind, which)
    for _, b in ipairs(H.boxes()) do
        if b.kind == kind and (which == nil or b.which == which) then return b end
    end
    return nil
end
function H.bagIdx()
    for i, b in ipairs(H.boxes()) do if b.kind == "bag" then return i end end
    return nil
end
function H.kinds()
    local out = {}
    for _, b in ipairs(H.boxes()) do
        if #out < 18 then
            out[#out + 1] = tostring(b.kind) .. (b.which and ("." .. tostring(b.which)) or "") .. (b.n and tostring(b.n) or "")
                .. "@" .. H.num(b.x) .. "+" .. H.num(b.w)
        end
    end
    return table.concat(out, " ")
end
function H.drawnOk() local hud = H.hud(); return hud ~= nil and hud._drawn == true end
function H.lite() local v = false; pcall(function() v = ZeD.Settings.lite() end); return v and true or false end
-- a texture's name, or ZeD's drawing's name when the icon is a ZeD pixel drawing (a string)
function H.texName(t)
    if t == nil then return "none" end
    if type(t) == "string" then return "ZeD drawing " .. t end
    local n = nil
    pcall(function() n = t:getName() end)
    return tostring(n or "a texture")
end
function H.pocketName()
    local t = nil
    pcall(function() t = getTexture(S.POCKET) end)
    if t then return H.texName(t) end
    return S.POCKET
end
function H.itemTex(it)
    local t = nil
    pcall(function() t = it:getTex() end)
    if t then return H.texName(t) end
    return "none"
end
function H.itemName(it) local n = nil; pcall(function() n = it:getName() end); return tostring(n) end
function H.itemShow(it) local n = nil; pcall(function() n = it:getDisplayName() end); return tostring(n) end
function H.itemId(it) local n = nil; pcall(function() n = it:getID() end); return n end
function H.itemType(it) local n = nil; pcall(function() n = it:getFullType() end); return n end

-- the bag button's icon as the belt draws it: its _drawButton watched (an instance field over the class's method)
function H.watchDraw(on)
    local hud = H.hud()
    if on then
        if S.dw or not hud then return end
        S.dw = { hud = hud, raw = rawget(hud, "_drawButton") }
        local base = hud._drawButton
        if type(base) ~= "function" then S.dw = nil; return end
        hud._drawButton = function(self, b, focus, hover, icon, lit)
            if b and b.kind == "bag" then S.drawn = { icon = icon, name = H.texName(icon), at = getTimestampMs() } end
            return base(self, b, focus, hover, icon, lit)
        end
        return
    end
    local d = S.dw
    if not d then return end
    S.dw = nil
    d.hud._drawButton = d.raw
end
-- the drawn icon's name when drawn after time t
function H.drawnSince(t)
    local d = S.drawn
    if d and d.at >= t then return d.name end
    return nil
end
-- the pointer parked off the belt for its plain pictures: the belt's own pointer reading answers far away, the
-- system pointer hidden in the corner
function H.park(on)
    local hud = H.hud()
    if on then
        if S.parked or not hud then return end
        S.parked = { hud = hud, mx = rawget(hud, "getMouseX"), my = rawget(hud, "getMouseY") }
        hud.getMouseX = function() return -100000 end
        hud.getMouseY = function() return -100000 end
        pcall(function() Mouse.setXY(4, getCore():getScreenHeight() - 4) end)
        pcall(function() Mouse.setCursorVisible(false) end)
        S.cursorHidden = true
        return
    end
    local pk = S.parked
    if pk then
        S.parked = nil
        pk.hud.getMouseX, pk.hud.getMouseY = pk.mx, pk.my
    end
    if S.cursorHidden then
        S.cursorHidden = nil
        pcall(function() Mouse.setCursorVisible(true) end)
    end
end
function H.shot(name)
    local ok, e = pcall(function() getCore():TakeFullScreenshot("vk4_" .. name .. ".png") end)
    if ok then Q.say("NOTE picture Zomboid/Screenshots/vk4_" .. name .. ".png") else Q.say("NOTE the picture " .. name .. " was not taken: " .. tostring(e)) end
end

-- ===================================================================== the pointer (the one thing faked)
function H.atPointer(gx, gy, fn)
    local ox, oy = getMouseX, getMouseY
    getMouseX = function() return gx end
    getMouseY = function() return gy end
    local ok, err = pcall(fn)
    getMouseX, getMouseY = ox, oy
    return ok, err
end
-- a press on the bag button through the belt's own handlers (right: the right button); ok, words
function H.pressBag(right)
    local hud = H.hud()
    local i = H.bagIdx()
    local b = i and H.boxes()[i] or nil
    if not (hud and b) then return false, "no bag button on the belt (" .. H.kinds() .. ")" end
    local lx, ly = b.x + math.floor(b.w / 2), b.y + math.floor(b.h / 2)
    local gx, gy = hud:getAbsoluteX() + lx, hud:getAbsoluteY() + ly
    local ok, err = H.atPointer(gx, gy, function()
        if right then
            hud:onRightMouseDown(lx, ly)
            hud:onRightMouseUp(lx, ly)
        else
            hud:onMouseDown(lx, ly)
            hud:onMouseUp(lx, ly)
        end
    end)
    if not ok then return false, "the press threw: " .. tostring(err) end
    S.pressAt = { x = gx, y = gy }
    return true, "pressed at " .. H.num(gx) .. "," .. H.num(gy)
end
-- a pad button on the bag button: the belt's pad mark put on it, its own onJoypadDown
function H.padBag(button)
    local hud = H.hud()
    local i = H.bagIdx()
    if not (hud and i) then return false, "no bag button on the belt" end
    hud._gp = { idx = i, inList = false, row = 1, list = {} }
    S.gpSet = true
    local jd = nil
    pcall(function() jd = JoypadState.players[S.pn + 1] end)
    local ok, err = pcall(function() hud:onJoypadDown(button, jd) end)
    if not ok then return false, "the press threw: " .. tostring(err) end
    return true, "pressed"
end
function H.gpOff()
    local hud = H.hud()
    if hud and S.gpSet then hud._gp = nil end
    S.gpSet = nil
end

-- ===================================================================== the belt's layout read
-- r: { ok, why = {...}, text } for Full or Lite; wantSpeed: five keys left of the bag button (else none);
-- wantWatch: "left" / "right" / nil (no watch box)
function H.layout(wantSpeed, wantWatch)
    local bx = H.boxes()
    local r = { why = {} }
    local ig = H.iconGap()
    local bi = H.bagIdx()
    if not bi then
        r.why[#r.why + 1] = "no bag button"
        r.text = H.kinds()
        return r
    end
    local bag = bx[bi]
    local bagR = bag.x + bag.w
    local nSp, spLeft = 0, true
    for i, b in ipairs(bx) do
        if b.kind == "speed" then
            nSp = nSp + 1
            if b.x + b.w > bag.x then spLeft = false end
        elseif i < bi then
            r.why[#r.why + 1] = tostring(b.kind) .. " left of the bag button"
        end
    end
    if wantSpeed then
        if nSp ~= 5 then r.why[#r.why + 1] = nSp .. " speed keys, not 5" end
        if not spLeft then r.why[#r.why + 1] = "a speed key right of the bag button's left edge" end
    elseif nSp > 0 then
        r.why[#r.why + 1] = nSp .. " speed keys on the belt (none wanted here)"
    end
    -- the belt's first box after the bag button, and the gap
    local nx = bx[bi + 1]
    local g1 = nx and (nx.x - bagR) or nil
    if not nx then r.why[#r.why + 1] = "nothing after the bag button"
    else
        if not (nx.kind == "watch" or nx.kind == "hand") then
            r.why[#r.why + 1] = "the first box after the bag button is " .. tostring(nx.kind) .. ", not the belt (a hand or its watch)"
        end
        if math.abs(g1 - ig) > 2 then r.why[#r.why + 1] = "bag button to belt " .. H.num(g1) .. " px, not " .. H.num(ig) end
        for j, b in ipairs(bx) do
            if j ~= bi and j ~= bi + 1 and b.x < nx.x and b.x + b.w > bagR then
                r.why[#r.why + 1] = tostring(b.kind) .. " between the bag button and the belt"
            end
        end
    end
    H.watchRead(r, bx, wantWatch)
    -- the belt's right end and the note
    local lamp = nil
    for _, b in ipairs(bx) do if b.kind == "lamp" and not lamp then lamp = b end end
    local g2 = nil
    if not lamp then r.why[#r.why + 1] = "no Messages note on the belt (staging)"
    else
        local right = 0
        local hud = H.hud()
        local st = hud and hud._strap
        if st then right = st.x + st.w end
        for _, b in ipairs(bx) do
            if b ~= lamp and b.x < lamp.x and b.x + b.w > right then right = b.x + b.w end
        end
        g2 = lamp.x - right
        if math.abs(g2 - ig) > 2 then r.why[#r.why + 1] = "belt to note " .. H.num(g2) .. " px, not " .. H.num(ig) end
    end
    r.ok = #r.why == 0
    r.text = "icon gap " .. H.num(ig) .. " px (the bag button " .. H.num(bag.w) .. " wide); speed keys " .. nSp .. ", all left of the bag button "
        .. tostring(nSp > 0 and spLeft) .. "; bag to belt " .. H.num(g1) .. " px (first: " .. tostring(nx and nx.kind) .. "), belt to note "
        .. H.num(g2) .. " px; " .. tostring(r.watch or "no watch box") .. "; boxes: " .. H.kinds()
        .. ((#r.why > 0) and ("; WRONG: " .. table.concat(r.why, "; ")) or "")
    return r
end
-- the watch beside its hand: left wrist just left of the off hand, right wrist just past the main hand (or its ammo)
function H.watchRead(r, bx, wantWatch)
    local w = nil
    for _, b in ipairs(bx) do if b.kind == "watch" and not w then w = b end end
    if not wantWatch then
        if w then r.why[#r.why + 1] = "a watch box on the belt (none wanted here)" end
        return
    end
    if not w then r.why[#r.why + 1] = "no watch on the belt"; return end
    local off, main, am = nil, nil, nil
    for _, b in ipairs(bx) do
        if b.kind == "hand" and b.which == "s" then off = b end
        if b.kind == "hand" and b.which == "p" then main = b end
        if b.kind == "ammo" then am = b end
    end
    local wr = H.px(8)
    local g = nil
    if w.wrist == "right" then
        local right = main and (main.x + main.w) or nil
        if right and am and am.x + am.w > right then right = am.x + am.w end
        g = right and (w.x - right) or nil
    else
        g = off and (off.x - (w.x + w.w)) or nil
    end
    local beside = g ~= nil and g >= -2 and g <= wr + 2
    r.watch = "the watch on the " .. tostring(w.wrist) .. " wrist, " .. H.num(g) .. " px from its hand"
    if tostring(w.wrist) ~= wantWatch then r.why[#r.why + 1] = "the watch reads the " .. tostring(w.wrist) .. " wrist, not " .. wantWatch end
    if not beside then r.why[#r.why + 1] = "the watch is not beside its hand (" .. H.num(g) .. " px)" end
end

-- ===================================================================== worn things
function H.wornList()
    local out = {}
    local wl = nil
    pcall(function() wl = S.p:getWornItems() end)
    if not wl then return out end
    pcall(function()
        for i = 0, wl:size() - 1 do
            local wi = wl:get(i)
            local it, loc = nil, nil
            if wi then
                it = wi:getItem()
                loc = wi:getLocation()
            end
            if it and loc ~= nil then out[#out + 1] = { loc = loc, item = it } end
        end
    end)
    return out
end
function H.isWorn(it)
    for _, e in ipairs(H.wornList()) do if e.item == it then return true end end
    return false
end
function H.locOf(it)
    local loc = nil
    pcall(function()
        if it:IsInventoryContainer() then loc = it:canBeEquipped() end
        if loc == nil or loc == "" then loc = it:getBodyLocation() end
    end)
    if loc == "" then loc = nil end
    return loc
end
function H.clothes() pcall(function() triggerEvent("OnClothingUpdated", S.p) end) end
function H.wear(it)
    local loc = it and H.locOf(it) or nil
    if not loc then return false end
    pcall(function() S.p:setWornItem(loc, it) end)
    H.clothes()
    return H.isWorn(it)
end
function H.unwear(it)
    if not (it and H.isWorn(it)) then return end
    pcall(function() S.p:removeWornItem(it) end)
    H.clothes()
end
function H.give(ft)
    local it = RT.give(ft)
    if it then S.given[#S.given + 1] = it end
    return it
end
function H.wornWatch() local w = nil; pcall(function() w = ZeD.Watch._wornWatch(S.p) end); return w end
-- the containers he has on now (worn or held), in his inventory's order
function H.bagsOn()
    local out = {}
    local items = nil
    pcall(function() items = S.p:getInventory():getItems() end)
    if not items then return out end
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        local cont, on = false, false
        pcall(function() cont = it:IsInventoryContainer() end)
        if cont then pcall(function() on = S.p:isEquipped(it) end) end
        if cont and on then out[#out + 1] = it end
    end
    return out
end

-- ===================================================================== the windows
function H.charOpen() local o = false; pcall(function() o = ZeD_CharacterWindow.isOpen(S.pn) end); return o and true or false end
function H.worldOpen() local o = false; pcall(function() o = ZeD_WorldWindow.isOpen(S.pn) end); return o and true or false end
function H.both() return H.charOpen() and H.worldOpen() and RT.cw() ~= nil and RT.ww() ~= nil end
function H.none() return not H.charOpen() and not H.worldOpen() end
function H.shutAll()
    if H.charOpen() and H.worldOpen() then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn); return end
    if H.charOpen() then pcall(ZeD_CharacterWindow.toggle, S.pn) end
    if H.worldOpen() then pcall(ZeD_WorldWindow.close, S.pn) end
end
function H.geo(w)
    if not w then return nil end
    return { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() }
end
function H.gs(g)
    if not g then return "none" end
    return H.num(g.x) .. "," .. H.num(g.y) .. " " .. H.num(g.w) .. "x" .. H.num(g.h)
end
function H.placeBack(w, g)
    if not (w and g) then return end
    pcall(function()
        if math.abs(w:getWidth() - g.w) > 1 then
            w.minimumWidth = math.min(w.minimumWidth or g.w, g.w)
            w:setWidth(g.w)
        end
        if math.abs(w:getHeight() - g.h) > 1 then
            w.minimumHeight = math.min(w.minimumHeight or g.h, g.h)
            w:setHeight(g.h)
        end
        if w:getX() ~= g.x then w:setX(g.x) end
        if w:getY() ~= g.y then w:setY(g.y) end
    end)
end
-- the lists the Character window shows side by side now: its columns, and the one on show
function H.shownSet()
    local w = RT.cw()
    local out, seen = {}, {}
    if not w then return out end
    for _, j in ipairs(w._mcSelected or {}) do
        local e = w._containers and w._containers[j]
        if e and not seen[e.inventory] then seen[e.inventory] = true; out[#out + 1] = e.inventory end
    end
    if w._mainVisible then
        local j = w._viewedContainer or w._activeContainer
        local e = w._containers and w._containers[j]
        if e and not seen[e.inventory] then seen[e.inventory] = true; out[#out + 1] = e.inventory end
    end
    return out
end
function H.main() return S.p:getInventory() end
function H.invName(inv)
    if inv == nil then return "none" end
    if inv == H.main() then return "his inventory" end
    if S.bagInv and inv == S.bagInv then return "the backpack" end
    if S.fannyInv and inv == S.fannyInv then return "the fanny pack" end
    local t = nil
    pcall(function() t = inv:getType() end)
    return tostring(t or "?")
end
function H.shownText()
    local out = {}
    for _, inv in ipairs(H.shownSet()) do out[#out + 1] = H.invName(inv) end
    local w = RT.cw()
    return "[" .. table.concat(out, ", ") .. "] on " .. tostring(w and (w._activeTab or "loot")) .. ", columns " .. tostring(w and #(w._mcSelected or {}))
end
-- the Character window on Loot showing inv alone (no columns)
function H.alone(inv)
    local w = RT.cw()
    if not (w and inv) then return false end
    local set = H.shownSet()
    return (w._activeTab or "loot") == "loot" and #set == 1 and set[1] == inv and #(w._mcSelected or {}) == 0
end
function H.mainShown()
    for _, inv in ipairs(H.shownSet()) do if inv == H.main() then return true end end
    return false
end
-- is the screen point inside an open ZeD window (a real click there would land on the window, not the belt)?
function H.underWindow(pt)
    if not pt then return "?" end
    for _, w in ipairs({ RT.cw() or false, RT.ww() or false }) do
        if w then
            local vis = false
            pcall(function() vis = w:isReallyVisible() end)
            if vis then
                local x, y = w:getAbsoluteX(), w:getAbsoluteY()
                if pt.x >= x and pt.x < x + w:getWidth() and pt.y >= y and pt.y < y + w:getHeight() then return tostring(w.Type or "a window") end
            end
        end
    end
    return "none"
end

-- ===================================================================== the menus
function H.ctx() local c = nil; pcall(function() c = getPlayerContextMenu(S.pn) end); return c end
function H.menu()
    local c = H.ctx()
    if c then return c._zedMenu end
    return nil
end
function H.menuUp()
    local m = H.menu()
    local vis = false
    if m then pcall(function() vis = m:isReallyVisible() end) end
    if vis then return true end
    local c = H.ctx()
    local cv = false
    if c then pcall(function() cv = c:isAnyVisible() and not c:isEmpty() end) end
    return cv and true or false
end
function H.closeMenu()
    local m = H.menu()
    if m then pcall(function() m:close() end) end
    pcall(function() local c = H.ctx(); if c and c:isAnyVisible() then c:hideAndChildren() end end)
end
-- the game's menu's options as built: { name, icon (its texture's name), opt }
function H.vanillaRows()
    local rows = {}
    local c = H.ctx()
    if not c then return rows end
    local opts = c.options or {}
    local n = (c.numOptions or (#opts + 1)) - 1
    for i = 1, n do
        local o = opts[i]
        if type(o) == "table" then rows[#rows + 1] = { name = tostring(o.name), icon = H.texName(o.iconTexture), opt = o } end
    end
    return rows
end
-- ZeD's menu's rows as it draws them (nil: ZeD's menu is not up): { name, shown, zed, def }
function H.zedRows()
    local m = H.menu()
    if not (m and m._ctx and m._ctx.open) then return nil end
    local out = {}
    for _, def in ipairs(m._ctx.actions or {}) do
        local shown = "none"
        if def.check ~= nil then shown = "a checkbox"
        elseif def.pxIcon then shown = "ZeD drawing " .. tostring(def.pxIcon)
        elseif def.iconTexture then shown = H.texName(def.iconTexture) end
        out[#out + 1] = { name = tostring(def.name), shown = shown, zed = def.pxIcon ~= nil or def.iconTintable == true, def = def }
    end
    return out
end
function H.rowsText(rows, key)
    local out = {}
    for _, r in ipairs(rows or {}) do out[#out + 1] = r.name .. " [" .. tostring(r[key]) .. "]" end
    return table.concat(out, "; ")
end
function H.nameIs(row, it) return row ~= nil and (row.name == H.itemName(it) or row.name == H.itemShow(it)) end

-- ===================================================================== settings (values only), the speed, the lock
function H.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function H.optSet(o, v) if o and v ~= nil then pcall(function() if o:getValue() ~= v then o:setValue(v) end end) end end
function H.styleOpt() return ZeD and ZeD.Settings and ZeD.Settings.lookStyleOption or nil end
function H.watchOpt() return ZeD and ZeD.Settings and ZeD.Settings.watchPlaceOption or nil end
function H.speed(n) if ZEDQA_SPEED then pcall(ZEDQA_SPEED, n) elseif setGameSpeed then pcall(setGameSpeed, n) end end
function H.opt(id)
    local api = PZAPI and PZAPI.ModOptions
    local zo = nil
    if api and api.getOptions then pcall(function() zo = api:getOptions("ZeD_UI") end) end
    return zo and zo.dict and zo.dict[id] or nil
end
function H.lockFound()
    local key = nil
    local o = H.opt("inputModeLock")
    local keys = ZeD and ZeD.Settings and ZeD.Settings.inputLockKeys
    if o and o.getValue and keys then key = keys[o:getValue() or 1] end
    if key == nil and S.p then
        local g = H.md().ZeD_Gamepad
        key = g and g.inputModeLock
    end
    return key or "auto"
end
function H.mode() return (S.Det and S.Det.getMode) and S.Det.getMode(S.pn) or nil end
function H.lock(mode)
    if not (S.Det and S.Det.setLockedMode) then return end
    if mode then
        if S.lockWas == nil then S.lockWas = H.lockFound() end
        S.Det.setLockedMode(mode)
        S.locked = true
        return
    end
    if not S.locked then return end
    S.locked = false
    S.Det.setLockedMode(nil)
    if S.lockWas == "kbm" or S.lockWas == "gamepad" then S.Det.setLockedMode(S.lockWas) end
end
function H.modeBack()
    local held = S.locked
    H.lock(false)
    if not (held and S.lockWas == "auto" and S.was.mode ~= nil and S.Det and S.Det.setLockedMode) then return end
    local want = (S.was.mode == "gamepad") and "gamepad" or "kbm"
    if H.mode() == want then return end
    S.Det.setLockedMode(want)
    S.modeHeld = want
end
function H.modeFree()
    if not S.modeHeld then return end
    S.modeHeld = nil
    S.Det.setLockedMode(nil)
end
function H.joyFocus()
    local f = nil
    pcall(function()
        local jd = JoypadState.players[S.pn + 1]
        if jd then f = jd.focus end
    end)
    return f
end
function H.hasPad()
    local yes = false
    pcall(function() yes = JoypadState.players[S.pn + 1] ~= nil end)
    return yes
end

-- ===================================================================== the Messages note (staged when empty)
function H.noteStage()
    local M = ZeD and ZeD.Messages
    if not (M and M.count and M.sources) then return end
    local n = 0
    pcall(function() n = M.count() end)
    if n > 0 then return end
    M.sources[S.SRC] = { name = S.SRC, kind = "err", at = (M.seq or 0) + 1,
        items = { { k = "err", count = 1, firsts = { "QA vk4_belt: a test line, not a real error" }, texts = { "QA vk4_belt" }, whens = {}, read = true, when = "" } } }
    if type(M.seq) == "number" then M.seq = M.seq + 1 end
    S.noteMade = true
end
function H.noteBack()
    local M = ZeD and ZeD.Messages
    if not (S.noteMade and M and M.sources) then return end
    M.sources[S.SRC] = nil
    if type(M.seq) == "number" then M.seq = M.seq + 1 end
    S.noteMade = nil
end

-- ===================================================================== start: what was found
Q.step(3, function()
    local dead = true
    pcall(function() dead = S.p:isDead() end)
    if dead then S.dead = true; Q.check(false, "the character is alive (staging)"); return end
    local ready = ZeD ~= nil and ZeD.Belt ~= nil and ZeD.Belt.getHUD ~= nil and ZeD_CharacterWindow ~= nil and ZeD_WorldWindow ~= nil
        and ZeD.Settings ~= nil and H.styleOpt() ~= nil and ZeD.Watch ~= nil and ZeD.Watch._wornWatch ~= nil and ZeD.T ~= nil
        and S.Det ~= nil and S.Det.setLockedMode ~= nil and S.Focus ~= nil
    if not Q.check(ready, "ZeD's belt, windows, Style, watch, theme sizes and the input lock are loaded (staging)") then S.dead = true; return end
    local md = H.md()
    S.was.bag = { had = md.ZeD_BeltBag ~= nil, v = H.copy(md.ZeD_BeltBag) }
    S.was.ws = { had = md.ZeD_WinState ~= nil, v = H.copy(md.ZeD_WinState) }
    S.was.pop = { had = md.ZeD_WatchPop ~= nil, v = H.copy(md.ZeD_WatchPop) }
    S.was.style = H.optVal(H.styleOpt())
    S.was.watch = H.optVal(H.watchOpt())
    S.was.char, S.was.world = H.charOpen(), H.worldOpen()
    local cw, ww = RT.cw(), RT.ww()
    S.was.geo = { c = S.was.char and H.geo(cw) or nil, w = S.was.world and H.geo(ww) or nil }
    S.was.tab = { c = (S.was.char and cw) and (cw._activeTab or "loot") or nil, w = (S.was.world and ww) and (ww._activeTab or "loot") or nil }
    S.was.speed = getGameSpeed()
    S.was.mode = H.mode()
    S.was.focus = S.Focus.getFocusedWindow and S.Focus.getFocusedWindow(S.pn) or nil
    S.was.joy = H.joyFocus()
    S.was.worn = H.wornList()
    S.lockWas = H.lockFound()
    S.server = (isClient and isClient()) and true or false
    H.closeMenu()
    H.lock("kbm")
    H.shutAll()
    if S.was.speed == 0 then H.speed(1) end
    -- the run's settings: Full, the watch on the belt, no pick, the full watch tucked
    H.optSet(H.styleOpt(), 1)
    H.optSet(H.watchOpt(), 1)
    md.ZeD_BeltBag = nil
    md.ZeD_WatchPop = nil
    -- his own watch off for the no-watch reading (back on at the end)
    S.ownWatch = H.wornWatch()
    if S.ownWatch then H.unwear(S.ownWatch) end
    H.noteStage()
    local wordsW = {}
    for _, e in ipairs(S.was.worn) do wordsW[#wordsW + 1] = H.itemShow(e.item) end
    Q.say("start: screen " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight() .. ", ZeD's scale " .. tostring(ZeD.T.scale)
        .. "; Style " .. tostring(S.was.style) .. " (1 Full, 2 Lite), Watch " .. tostring(S.was.watch) .. " (1 belt); ZeD_BeltBag "
        .. (S.was.bag.had and H.recText(S.was.bag.v) or "none") .. "; Character window open " .. tostring(S.was.char) .. " (" .. H.gs(S.was.geo.c)
        .. ", on " .. tostring(S.was.tab.c) .. "), World window open " .. tostring(S.was.world) .. " (" .. H.gs(S.was.geo.w) .. ", on "
        .. tostring(S.was.tab.w) .. "); game speed " .. tostring(S.was.speed) .. "; Input lock " .. tostring(S.lockWas) .. ", ZeD reads "
        .. tostring(S.was.mode) .. "; a pad connected " .. tostring(H.hasPad()) .. "; on a server " .. tostring(S.server) .. "; worn: "
        .. table.concat(wordsW, ", ") .. "; his own watch " .. tostring(S.ownWatch and H.itemShow(S.ownWatch)) .. " (taken off for the run)"
        .. "; the Messages note staged " .. tostring(S.noteMade == true))
end)
H.wait(6000, function() return S.dead or (H.none() and H.drawnOk() and not H.lite() and H.box("watch") == nil) end, function(ok)
    if S.dead then return end
    if not ok then
        S.dead = true
        Q.check(false, "both windows shut, the belt drawn in Full, no watch on it (staging)", "Character " .. tostring(H.charOpen())
            .. ", World " .. tostring(H.worldOpen()) .. ", belt drawn " .. tostring(H.drawnOk()) .. ", Lite " .. tostring(H.lite())
            .. ", a watch box " .. tostring(H.box("watch") ~= nil))
        return
    end
    H.watchDraw(true)
    S.ok = true
    S.t = H.now() + S.CACHE_MS
end)

-- ===================================================================== BELT 1 and 5: Full, no watch; the default pick
H.settle(S.CACHE_MS, 4000, function() return not S.ok or (H.drawnSince(S.t) ~= nil and H.box("lamp") ~= nil) end, function(ok)
    if not S.ok then return end
    local r = H.layout(false, nil)
    Q.check(ok and r.ok, "BELT 1: Full, no watch: no speed keys, the bag button first, an icon's gap to the belt and from the belt to the note, nothing between",
        r.text)
    local k = S.k
    k.defIcon = H.drawnSince(S.t)
    k.defRec = H.md().ZeD_BeltBag
    k.okP, k.whyP = H.pressBag(false)
end)
H.settle(600, 4000, function() return not S.ok or H.both() end, function(ok)
    if not S.ok then return end
    local k = S.k
    local pocket = H.pocketName()
    Q.check(ok and k.okP and k.defIcon == pocket and k.defRec == nil and H.mainShown(),
        "BELT 5: default (no pick): the bag button wears the pocket and a click opens the pair on his main inventory",
        "the button draws " .. tostring(k.defIcon) .. " (the pocket: " .. pocket .. "); ZeD_BeltBag " .. H.recText(k.defRec) .. "; "
        .. tostring(k.whyP) .. "; both open " .. tostring(H.both()) .. ", the Character window shows " .. H.shownText())
    H.shutAll()
end)
H.wait(5000, function() return not S.ok or H.none() end, function(ok)
    if S.ok and not ok then S.dead = true; S.ok = false; Q.check(false, "both windows shut again (staging)") end
end)

-- ===================================================================== BELT 2: Full, the watch on the left wrist
Q.step(2, function()
    if not S.ok then return end
    S.watchL = H.give(S.WATCH_L)
    S.k.wornL = S.watchL ~= nil and H.wear(S.watchL)
end)
H.settle(300, 4000, function()
    if not S.ok or not S.k.wornL then return true end
    local w = H.box("watch")
    return w ~= nil and w.wrist == "left" and H.box("lamp") ~= nil
end, function(ok)
    if not S.ok then return end
    local r = H.layout(not S.server, "left")
    Q.check(ok and S.k.wornL and r.ok, "BELT 2: Full, a watch on the left wrist: the speed keys left of the bag button, an icon's gap to the belt "
        .. "(the watch beside the off hand) and to the note, nothing between", "a " .. tostring(S.watchL and H.itemShow(S.watchL))
        .. " given and worn " .. tostring(S.k.wornL) .. "; " .. r.text .. (S.server and " (on a server: no speed keys wanted)" or ""))
    H.park(true)
end)
Q.step(4, function() if S.ok then H.shot("belt_full") end end)
Q.step(2, function() H.park(false) end)

-- ===================================================================== BELT 3: Full, the watch on the right wrist
Q.step(2, function()
    if not S.ok then return end
    H.unwear(S.watchL)
    S.watchR = H.give(S.WATCH_R)
    S.k.wornR = S.watchR ~= nil and H.wear(S.watchR)
end)
H.settle(300, 4000, function()
    if not S.ok or not S.k.wornR then return true end
    local w = H.box("watch")
    return w ~= nil and w.wrist == "right" and H.box("lamp") ~= nil
end, function(ok)
    if not S.ok then return end
    local r = H.layout(not S.server, "right")
    Q.check(ok and S.k.wornR and r.ok, "BELT 3: Full, a watch on the right wrist: the speed keys left of the bag button, an icon's gap to the "
        .. "belt and to the note, nothing between, the watch past the main hand", "a " .. tostring(S.watchR and H.itemShow(S.watchR))
        .. " given and worn " .. tostring(S.k.wornR) .. "; " .. r.text)
end)

-- ===================================================================== BELT 4: Lite
Q.step(2, function() if S.ok then H.optSet(H.styleOpt(), 2) end end)
H.settle(300, 4000, function()
    local hud = H.hud()
    return not S.ok or (H.lite() and hud ~= nil and hud._strap == nil and H.box("lamp") ~= nil and H.bagIdx() ~= nil)
end, function(ok)
    if not S.ok then return end
    local r = H.layout(false, nil)
    Q.check(ok and r.ok, "BELT 4: Lite: no speed keys on the belt, the bag button first, an icon's gap to the belt and from the last slot to "
        .. "the note, nothing between", "Lite " .. tostring(H.lite()) .. " (a watch worn: Lite keeps it in the corner); " .. r.text)
    H.park(true)
end)
Q.step(4, function() if S.ok then H.shot("belt_lite") end end)
Q.step(2, function()
    H.park(false)
    if S.ok then H.optSet(H.styleOpt(), 1) end
end)
H.wait(4000, function() local hud = H.hud(); return not S.ok or (not H.lite() and hud ~= nil and hud._strap ~= nil) end, function(ok)
    if S.ok and not ok then Q.check(false, "Full again after Lite (staging)", "Lite " .. tostring(H.lite())) end
end)

-- ===================================================================== the bags: a backpack and a fanny pack worn
Q.step(2, function()
    if not S.ok then return end
    S.bag = H.give(S.BAG)
    S.fanny = H.give(S.FANNY)
    if S.bag then pcall(function() S.bagInv = S.bag:getInventory() end) end
    if S.fanny then pcall(function() S.fannyInv = S.fanny:getInventory() end) end
    S.bagOn = S.bag ~= nil and H.wear(S.bag)
    S.fannyOn = S.fanny ~= nil and H.wear(S.fanny)
    if not (S.bagOn and S.fannyOn and S.bagInv) then
        S.noBags = true
        Q.check(false, "a backpack and a fanny pack given and worn (staging)", "backpack " .. tostring(S.bag ~= nil) .. " worn " .. tostring(S.bagOn)
            .. ", fanny pack " .. tostring(S.fanny ~= nil) .. " worn " .. tostring(S.fannyOn))
        return
    end
    Q.say("NOTE worn: the backpack " .. H.itemShow(S.bag) .. " (name " .. H.itemName(S.bag) .. ", icon " .. H.itemTex(S.bag) .. ", id "
        .. tostring(H.itemId(S.bag)) .. ") and the fanny pack " .. H.itemShow(S.fanny) .. " (name " .. H.itemName(S.fanny) .. ", icon "
        .. H.itemTex(S.fanny) .. "); bags he has on now: " .. #H.bagsOn())
end)
Q.waitMs(S.CACHE_MS)

-- ===================================================================== BELT 6 and 7: the right-click menu
Q.step(2, function()
    if not S.ok or S.noBags then return end
    H.closeMenu()
    S.k.okR, S.k.whyR = H.pressBag(true)
    S.k.menuT = H.now()
end)
H.settle(300, 3000, function() return not S.ok or S.noBags or (H.menuUp() and (H.zedRows() ~= nil or H.now() - S.k.menuT > 1500)) end, function(ok)
    if not S.ok or S.noBags then return end
    local k = S.k
    local up = H.menuUp()
    k.rows = up and H.vanillaRows() or {}
    k.zrows = up and H.zedRows() or nil
    H.listCheck(ok and up, k.rows, "BELT 6: a right-click on the bag button lists Inventory first with the pocket's icon, then each bag he has on, each with its own icon",
        tostring(k.whyR))
    H.drawCheck(up, k.rows, k.zrows)
    if up then H.shot("belt_menu") end
end)
Q.step(2, function() H.closeMenu() end)
H.wait(2000, function() return not H.menuUp() end, function() end)
-- the list as built (the game's menu): Inventory first, the pocket's icon, then each bag he has on with its own icon
function H.listCheck(up, rows, label, how)
    local why = {}
    local inv = getText("IGUI_InventoryTooltip")
    local pocket = H.pocketName()
    if not up then why[#why + 1] = "no menu opened" end
    local first = rows[1]
    if up and not (first and first.name == inv) then why[#why + 1] = "the first row is " .. tostring(first and first.name) .. ", not " .. inv end
    if up and first and first.icon ~= pocket then why[#why + 1] = "Inventory's icon is " .. tostring(first.icon) .. ", not the pocket " .. pocket end
    local on = H.bagsOn()
    for _, it in ipairs(on) do
        local found = nil
        for i = 2, #rows do if not found and H.nameIs(rows[i], it) then found = rows[i] end end
        if up and not found then why[#why + 1] = "no row for " .. H.itemShow(it)
        elseif found and found.icon ~= H.itemTex(it) then why[#why + 1] = found.name .. " shows " .. tostring(found.icon) .. ", not its own " .. H.itemTex(it) end
    end
    if up and #rows ~= 1 + #on then why[#why + 1] = #rows .. " rows for Inventory and " .. #on .. " bags" end
    return Q.check(#why == 0, label, tostring(how) .. "; rows: " .. H.rowsText(rows, "icon") .. ((#why > 0) and ("; WRONG: " .. table.concat(why, "; ")) or ""))
end
-- the menu as ZeD draws it: its order, and each row's icon against the row's own (a ZeD map icon named)
function H.drawCheck(up, rows, zrows)
    local label = "BELT 7: the bag menu as ZeD draws it: Inventory first, each row its own icon (none of ZeD's name-to-icon map in their place)"
    if not up then Q.check(false, label, "no menu opened"); return end
    if not zrows then
        Q.check(#rows > 0, label, "ZeD's menu is not up: the game's own menu shows the rows as built (" .. H.rowsText(rows, "icon") .. ")")
        return
    end
    local own = {}
    for _, r in ipairs(rows) do own[r.name] = r.icon end
    local why = {}
    local inv = getText("IGUI_InventoryTooltip")
    if not (zrows[1] and zrows[1].name == inv) then why[#why + 1] = "the first row drawn is " .. tostring(zrows[1] and zrows[1].name) .. ", not " .. inv end
    for _, z in ipairs(zrows) do
        local o = own[z.name]
        if o == nil then why[#why + 1] = "a row not in the list: " .. z.name
        elseif z.shown ~= o then
            why[#why + 1] = "'" .. z.name .. "' draws " .. z.shown .. (z.zed and " (ZeD's map icon)" or "") .. ", not its own " .. o
        end
    end
    if #zrows ~= #rows then why[#why + 1] = #zrows .. " rows drawn, " .. #rows .. " built" end
    local m = H.menu()
    Q.check(#why == 0, label, "ZeD's " .. tostring(m and m.Type) .. "; rows drawn: " .. H.rowsText(zrows, "shown")
        .. ((#why > 0) and ("; WRONG: " .. table.concat(why, "; ")) or ""))
end

-- ===================================================================== BELT 8: pad X
Q.step(2, function()
    if not S.ok or S.noBags then return end
    S.k.okX, S.k.whyX = H.padBag(Joypad.XButton)
    S.tookFocus = true
    S.k.menuT = H.now()
end)
H.settle(300, 3000, function() return not S.ok or S.noBags or (H.menuUp() and (H.zedRows() ~= nil or H.now() - S.k.menuT > 1500)) end, function(ok)
    if not S.ok or S.noBags then return end
    local k = S.k
    local up = H.menuUp()
    local rows = up and H.vanillaRows() or {}
    local same = up and #rows == #(k.rows or {}) and #rows > 0
    for i, r in ipairs(rows) do if not (k.rows[i] and k.rows[i].name == r.name and k.rows[i].icon == r.icon) then same = false end end
    local padOn = "(no pad connected)"
    if H.hasPad() then
        local f = H.joyFocus()
        padOn = tostring(f ~= nil and (f == H.ctx() or f == H.menu()))
    end
    Q.check(ok and up and same, "BELT 8: pad X on the bag button opens the same bag menu",
        "the press " .. tostring(k.whyX) .. "; a menu up " .. tostring(up) .. "; rows: " .. H.rowsText(rows, "icon") .. "; the same as the right-click's "
        .. tostring(same) .. "; the pad's focus on it " .. padOn)
end)
Q.step(2, function()
    H.closeMenu()
    H.gpOff()
end)
H.wait(2000, function() return not H.menuUp() end, function() end)

-- ===================================================================== BELT 9: the backpack picked
Q.step(2, function()
    if not S.ok or S.noBags then return end
    H.closeMenu()
    S.k.okR2, S.k.whyR2 = H.pressBag(true)
    S.k.menuT = H.now()
end)
H.settle(300, 3000, function() return not S.ok or S.noBags or (H.menuUp() and (H.zedRows() ~= nil or H.now() - S.k.menuT > 1500)) end, function(ok)
    if not S.ok or S.noBags then return end
    local k = S.k
    k.fired = false
    if not (ok and H.menuUp()) then k.fireWhy = "no menu to pick from"; return end
    k.fireWhy = H.fireBag()
end)
function H.fireBag()
    local row = nil
    for i, r in ipairs(H.vanillaRows()) do if i > 1 and not row and H.nameIs(r, S.bag) then row = r end end
    if not row then return "no row named for the backpack" end
    local zr = H.zedRows()
    if zr then
        local m = H.menu()
        for _, z in ipairs(zr) do
            if z.name == row.name and not S.k.fired and z.def.onFire then
                S.k.fired = pcall(z.def.onFire, m._ctx.target)
            end
        end
        pcall(function() m:close() end)
        return S.k.fired and ("the row '" .. row.name .. "' fired in ZeD's menu") or ("no ZeD row fired for '" .. row.name .. "'")
    end
    local o = row.opt
    if o and o.onSelect then
        S.k.fired = pcall(o.onSelect, o.target, o.param1, o.param2, o.param3, o.param4, o.param5)
    end
    H.closeMenu()
    return "the game's row '" .. row.name .. "' fired " .. tostring(S.k.fired)
end
Q.step(2, function() if S.ok and not S.noBags then S.t = H.now() + S.CACHE_MS end end)
H.settle(S.CACHE_MS, 3000, function() return not S.ok or S.noBags or H.drawnSince(S.t) == H.itemTex(S.bag) end, function(ok)
    if not S.ok or S.noBags then return end
    local k = S.k
    local rec = H.md().ZeD_BeltBag
    local want = { id = H.itemId(S.bag), type = H.itemType(S.bag) }
    Q.check(ok and k.fired and H.sameRec(rec, want), "BELT 9: the backpack picked: his modData ZeD_BeltBag holds it and the bag button wears its icon",
        tostring(k.fireWhy) .. "; ZeD_BeltBag " .. H.recText(rec) .. " (the backpack " .. H.recText(want) .. "); the button draws "
        .. tostring(H.drawnSince(S.t)) .. " (the backpack's " .. H.itemTex(S.bag) .. ")")
    H.park(true)
end)
Q.step(4, function() if S.ok and not S.noBags then H.shot("belt_picked") end end)
Q.step(2, function() H.park(false) end)

-- ===================================================================== BELT 10 and 11: a click, then a second click
Q.step(2, function()
    if not S.ok or S.noBags then return end
    S.k.okC, S.k.whyC = H.pressBag(false)
end)
H.settle(600, 4000, function() return not S.ok or S.noBags or (H.both() and H.alone(S.bagInv)) end, function(ok)
    if not S.ok or S.noBags then return end
    local k = S.k
    Q.check(ok and k.okC and H.both() and H.alone(S.bagInv), "BELT 10: with the backpack picked, a click opens the pair on the backpack alone",
        tostring(k.whyC) .. "; both open " .. tostring(H.both()) .. "; the Character window shows " .. H.shownText())
    k.under = H.underWindow(S.pressAt)
    k.wasAlone = H.both() and H.alone(S.bagInv)
    k.okC2, k.whyC2 = H.pressBag(false)
end)
H.wait(3000, function() return not S.ok or S.noBags or H.none() end, function(ok)
    if not S.ok or S.noBags then return end
    local k = S.k
    Q.check(ok and k.okC2 and k.wasAlone, "BELT 11: a second click on the bag button, the pair on the backpack alone, closes the pair",
        "the pair on the backpack alone before it " .. tostring(k.wasAlone) .. "; " .. tostring(k.whyC2) .. "; both shut " .. tostring(H.none())
        .. "; the bag button's middle under an open window: " .. tostring(k.under))
    H.shutAll()
end)
H.wait(4000, function() return H.none() end, function() end)

-- ===================================================================== BELT 12: pad A
Q.step(2, function()
    if not S.ok or S.noBags then return end
    S.k.okA, S.k.whyA = H.padBag(Joypad.AButton)
    S.tookFocus = true
end)
H.settle(600, 4000, function() return not S.ok or S.noBags or (H.both() and H.alone(S.bagInv)) end, function(ok)
    if not S.ok or S.noBags then return end
    local k = S.k
    Q.check(ok and k.okA and H.both() and H.alone(S.bagInv), "BELT 12: pad A on the bag button opens the pair on the backpack alone",
        tostring(k.whyA) .. "; both open " .. tostring(H.both()) .. "; the Character window shows " .. H.shownText())
    H.gpOff()
    H.shutAll()
    if S.was.focus == nil then pcall(S.Focus.releaseFocus, S.pn) end
end)
H.wait(4000, function() return H.none() end, function() end)

-- ===================================================================== BELT 13: the backpack taken off
Q.step(2, function()
    if not S.ok or S.noBags then return end
    H.unwear(S.bag)
    S.k.offOk = not H.isWorn(S.bag)
    S.t = H.now() + S.CACHE_MS
end)
H.settle(S.CACHE_MS, 3000, function() return not S.ok or S.noBags or H.drawnSince(S.t) == H.pocketName() end, function(ok)
    if not S.ok or S.noBags then return end
    local k = S.k
    k.offIcon = H.drawnSince(S.t)
    k.okO, k.whyO = H.pressBag(false)
end)
H.settle(600, 4000, function() return not S.ok or S.noBags or H.both() end, function(ok)
    if not S.ok or S.noBags then return end
    local k = S.k
    local rec = H.md().ZeD_BeltBag
    local kept = type(rec) == "table" and rec.id == H.itemId(S.bag)
    Q.check(ok and k.offOk and k.offIcon == H.pocketName() and k.okO and H.mainShown() and not H.alone(S.bagInv) and kept,
        "BELT 13: the backpack taken off: the bag button wears the pocket, a click opens his main inventory, the pick is kept",
        "taken off " .. tostring(k.offOk) .. " (still in his inventory); the button draws " .. tostring(k.offIcon) .. " (the pocket " .. H.pocketName()
        .. "); " .. tostring(k.whyO) .. "; both open " .. tostring(H.both()) .. ", the Character window shows " .. H.shownText() .. "; ZeD_BeltBag "
        .. H.recText(rec))
    H.shutAll()
end)
H.wait(4000, function() return H.none() end, function() end)

-- ===================================================================== BELT 14: the backpack on again
Q.step(2, function()
    if not S.ok or S.noBags then return end
    S.k.onOk = H.wear(S.bag)
    S.t = H.now() + S.CACHE_MS
end)
H.settle(S.CACHE_MS, 3000, function() return not S.ok or S.noBags or H.drawnSince(S.t) == H.itemTex(S.bag) end, function(ok)
    if not S.ok or S.noBags then return end
    local k = S.k
    Q.check(ok and k.onOk, "BELT 14: the backpack put on again: the bag button wears its icon again (the pick returns)",
        "worn again " .. tostring(k.onOk) .. "; the button draws " .. tostring(H.drawnSince(S.t)) .. " (the backpack's " .. H.itemTex(S.bag)
        .. "); ZeD_BeltBag " .. H.recText(H.md().ZeD_BeltBag))
end)

-- ===================================================================== put back
Q.mark()
Q.step(2, function()
    H.closeMenu()
    H.gpOff()
    H.park(false)
    H.watchDraw(false)
    H.shutAll()
end)
H.wait(5000, function() return H.none() end, function(ok)
    if not ok then H.shutAll() end
    -- the worn items as found: the run's taken off, his own back where they were
    for _, it in ipairs(S.given) do H.unwear(it) end
    for _, e in ipairs(S.was.worn or {}) do
        local now = nil
        pcall(function() now = S.p:getWornItem(e.loc) end)
        if now ~= e.item then pcall(function() S.p:setWornItem(e.loc, e.item) end) end
    end
    H.clothes()
    pcall(RT.takeBack)
    local md = H.md()
    if S.was.bag then
        if S.was.bag.had then md.ZeD_BeltBag = H.copy(S.was.bag.v) else md.ZeD_BeltBag = nil end
    end
    if S.was.pop then
        if S.was.pop.had then md.ZeD_WatchPop = H.copy(S.was.pop.v) else md.ZeD_WatchPop = nil end
    end
    if S.was.ws then
        if S.was.ws.had then md.ZeD_WinState = H.copy(S.was.ws.v) else md.ZeD_WinState = nil end
    end
    local cache = ZeD and ZeD.Belt and ZeD.Belt._bagCache
    if type(cache) == "table" then cache[S.pn] = nil end
    if S.was.style ~= nil then H.optSet(H.styleOpt(), S.was.style) end
    if S.was.watch ~= nil then H.optSet(H.watchOpt(), S.was.watch) end
    H.noteBack()
    if S.was.speed == 0 then H.speed(0) end   -- (the run only set x1 when it found the game paused)
    if S.tookFocus and S.was.focus == nil then pcall(S.Focus.releaseFocus, S.pn) end
    if H.hasPad() and H.joyFocus() ~= S.was.joy then pcall(setJoypadFocus, S.pn, S.was.joy) end
    H.modeBack()
    -- the windows open as found (the found window state loads on open)
    if S.was.char and S.was.world then pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn)
    elseif S.was.char then pcall(ZeD_CharacterWindow.toggle, S.pn)
    elseif S.was.world then pcall(ZeD_WorldWindow.open, S.pn) end
end)
H.settle(300, 5000, function() return H.charOpen() == (S.was.char == true) and H.worldOpen() == (S.was.world == true) end, function()
    if S.was.char then
        H.placeBack(RT.cw(), S.was.geo and S.was.geo.c)
        if S.was.tab and S.was.tab.c then pcall(RT.charTab, S.was.tab.c) end
    end
    if S.was.world then
        H.placeBack(RT.ww(), S.was.geo and S.was.geo.w)
        if S.was.tab and S.was.tab.w then pcall(RT.worldTab, S.was.tab.w) end
    end
end)
Q.step(4, function()
    H.modeFree()
    if not S.was.worn then Q.say("NOTE nothing was recorded or changed: no put-back to read"); return end
    -- the put-back read
    local wornNow = H.wornList()
    local bad = {}
    for _, e in ipairs(S.was.worn or {}) do
        local now = nil
        pcall(function() now = S.p:getWornItem(e.loc) end)
        if now ~= e.item then bad[#bad + 1] = H.itemShow(e.item) .. " not back on" end
    end
    for _, it in ipairs(S.given) do
        if H.isWorn(it) then bad[#bad + 1] = H.itemShow(it) .. " (the run's) still worn" end
        local held = false
        pcall(function() held = S.p:getInventory():contains(it) end)
        if held then bad[#bad + 1] = H.itemShow(it) .. " (the run's) still in his inventory" end
    end
    Q.check(#bad == 0 and #wornNow == #(S.was.worn or {}), "put back: every worn item as found, the run's things taken away",
        "worn now " .. #wornNow .. " (found " .. #(S.was.worn or {}) .. ")" .. ((#bad > 0) and ("; " .. table.concat(bad, "; ")) or ""))
    local md = H.md()
    local bagOk = (S.was.bag == nil) or (S.was.bag.had and H.sameRec(md.ZeD_BeltBag, S.was.bag.v)) or (not S.was.bag.had and md.ZeD_BeltBag == nil)
    local popOk = (S.was.pop == nil) or (S.was.pop.had == (md.ZeD_WatchPop ~= nil))
    Q.check(bagOk and popOk, "put back: his modData ZeD_BeltBag and ZeD_WatchPop as found",
        "ZeD_BeltBag " .. H.recText(md.ZeD_BeltBag) .. " (found " .. ((S.was.bag and S.was.bag.had) and H.recText(S.was.bag.v) or "none") .. ")")
    local style, watch = H.optVal(H.styleOpt()), H.optVal(H.watchOpt())
    Q.check(style == S.was.style and watch == S.was.watch, "put back: Style and Watch option values as found",
        "Style " .. tostring(style) .. " (found " .. tostring(S.was.style) .. "), Watch " .. tostring(watch) .. " (found " .. tostring(S.was.watch) .. ")")
    local hud = H.hud()
    local clean = S.dw == nil and S.parked == nil and S.cursorHidden == nil and S.gpSet == nil and not H.menuUp() and S.noteMade == nil
        and getMouseX ~= nil and (hud == nil or hud._gp == nil)
    Q.check(clean, "put back: menus closed, the belt's pad mark, watched drawing and parked pointer gone, the cursor shown, the staged note gone",
        "menu up " .. tostring(H.menuUp()) .. ", the belt's pad mark " .. tostring(hud and hud._gp ~= nil))
    local cw, ww = H.charOpen(), H.worldOpen()
    Q.check(cw == (S.was.char == true) and ww == (S.was.world == true) and not S.locked and S.modeHeld == nil,
        "put back: the windows open or shut as found, the input lock as found",
        "Character " .. tostring(cw) .. " (found " .. tostring(S.was.char) .. "), World " .. tostring(ww) .. " (found " .. tostring(S.was.world)
        .. "); lock " .. H.lockFound() .. " (found " .. tostring(S.lockWas) .. "), ZeD reads " .. tostring(H.mode()) .. " (found " .. tostring(S.was.mode)
        .. "); game speed " .. tostring(getGameSpeed()) .. " (found " .. tostring(S.was.speed) .. ")")
end)
Q.start()
