-- ZeDUI/tools/qa/rt_windows.lua  (Nov 18 2026, QA): the release test's windows (RELEASE_TEST.md, row rt_windows.lua).
-- Built on rt_kit.lua (the global RT). grep "ZEDQA rt_win".
--   1. Mouse: the inventory key's action (ZeD_CharacterWindow.toggleBothPaired) opens both windows and closes both.
--   2. Every tab on both strips (RT.tabs of each strip, pressed through the strip's own mouse handler): it becomes the
--      active tab (win._activeTab), its drawer settles at the half card (220 design units; 260 is gone, Build Nov 18) or the full card
--      (480), nothing between (ZeD.T.px of each, 1 px slack; the World and Character Loot tabs have no drawer), the
--      other window does not move, no new Lua error, and RT.bounds passes.
--   3. The curtain (WindowCurtain.lua) on each window: on a tab with a drawer the side rolls up under its rod (run in
--      the window's update, as a press is), the rod's tab pressed rolls it down, and the window is back in the same
--      box to the pixel, the other window untouched.
--   4. The pad's Y through FocusManager (Focus.qaButton, the input mode locked to the pad for the run): a tap opens
--      the pair, a tap closes it (Nov 22 2026, KISS #25: it used to roll it to two bars), a tap opens it again, a
--      hold closes it.
-- (Nov 18 2026, the FEATURE_MAP ledger's "Windows and tabs" gaps; each block names its rows)
--   In the tab walk: the title names the open tab; the full-card tabs agree on one card, the others take the half card;
--      every tab has its lit icon; each tab's zone is what the strip's hitZoneAt finds.
--   5. Inside the Character tabs, through the drawer's own mouse handler: Equip's List / Doll, a group's fold, a
--      column's width drag; Health's figure fold, exercise list, session time; Thermal's figure fold, View list,
--      units; Skills' grid fold, the title's health pixel, Show all after the pad's aim; Identity's trait stops.
--   6. Inside the World tabs: Craft's Sort, Show and Category, a recipe pinned and unpinned by right-click;
--      Foraging's focus drop-down and More detail; the extension tabs registered.
--   7. The window box's menu (its rows, Accent, on screen), Save / Go to saved position, Reset this / both. (Nov 22
--      2026, QA K1-6: no Hide interface row in it any more; the pad's View wheel keeps that one.)
--   8. Resize by the right edge (the pointer read as the drag reads it): narrower, past the cap, back.
--   9. Layout kept per character over a close; the game's own pages hidden; World force close; paused, the
--      Character window alone.
--  10. (after the pad's Y) the D-pad wheel's presses: the same direction or B closes it, another swaps; LB + A on a
--      pointed slice puts it on that chord (put back); the Controller map closes on B. Also: each half's pin
--      (after Show all) and the Character window's extension tabs (after the World's).
-- Put back: the halves' pins, the active tabs, the window places (ZEDQA_LAYOUT_BACK when the prelude ran), the input
-- mode lock, the game speed, and the pair open or shut as found; each window's accent, the kept layout (pair shut),
-- the Equip view option, the craft pins, the saved window places file, and each tab's state the checks touched.
local Q = RT.make("rt_win")
local pn = RT.pn
local T = ZeD.T
local S = { tabs = { c = {}, w = {} }, hasErr = false, st = {} }
local MAXT = 24     -- tab slots per strip (a strip with fewer leaves the rest empty)

-- ===================================================================== helpers
local function errCount()
    local n = nil
    pcall(function() n = getLuaDebuggerErrorCount() end)
    return n
end
local function geo(w)
    if not w then return nil end
    return { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() }
end
local function gs(g) return g and string.format("%d,%d %dx%d", g.x, g.y, g.w, g.h) or "none" end
local function sameGeo(a, b, slack)
    if not (a and b) then return false end
    slack = slack or 0
    return math.abs(a.x - b.x) <= slack and math.abs(a.y - b.y) <= slack and math.abs(a.w - b.w) <= slack and math.abs(a.h - b.h) <= slack
end
local function wOf(k) if k == "c" then return RT.cw() end; return RT.ww() end
local function otherOf(k) if k == "c" then return RT.ww() end; return RT.cw() end
local function nameOf(k) if k == "c" then return "Character" end; return "World" end
local function press(k, id) if k == "c" then return RT.charTab(id) end; return RT.worldTab(id) end
local function worldOpen() local o = false; pcall(function() o = ZeD_WorldWindow.isOpen(pn) end); return o end
local function bothOpen()
    local c, w = RT.cw(), RT.ww()
    return RT.isOpen() and worldOpen() and c ~= nil and w ~= nil and c:isVisible() and w:isVisible()
end
local function bothShut() return (not RT.isOpen()) and (not worldOpen()) end
local function toggle() return pcall(ZeD_CharacterWindow.toggleBothPaired, pn) end
-- the drawer's card: "closed", "half", "full" or "NEITHER" (screen px; 1 px slack)
local function cardName(eff)
    if eff <= 0 then return "closed" end
    if math.abs(eff - T.px(220)) <= 1 then return "half" end
    if math.abs(eff - T.px(480)) <= 1 then return "full" end
    return "NEITHER"
end
-- true once the window shows tab id and its drawer has held one width for 15 frames
local function settled(k, id)
    local w = wOf(k)
    if not w then return false end
    local e = math.floor(w._drawerEffW or 0)
    if e == S.st.lastE then S.st.same = (S.st.same or 0) + 1 else S.st.same, S.st.lastE = 0, e end
    return w._activeTab == id and S.st.same >= 15
end
local function resetSettle() S.st.same, S.st.lastE = 0, nil end
-- a press the way the engine delivers one: inside the element's update, followed by its onResize
-- (as zedqa_curtain.lua's viaUpdate; el._qaPressDone is false until the update ran it)
local function viaUpdate(el, fn)
    local own = rawget(el, "update")
    el._qaPressDone = false
    el.update = function(self)
        self.update = own
        self:update()
        local ok, e = pcall(fn, self)
        if not ok then S.pressErr = tostring(e) end
        pcall(function() self:onResize() end)
        self._qaPressDone = true
    end
end
-- the halves' pins of both windows, from the character's saved table (WindowHalves.lua keeps them there)
local PIN_KEYS = { "charInv", "charTabs", "char", "worldInv", "worldTabs", "world" }
local function pinAll()
    for _, w in ipairs({ RT.cw(), RT.ww() }) do
        if w and w._halves and ZeD.Halves and ZeD.Halves.setPin then pcall(ZeD.Halves.setPin, w, nil, true) end
    end
end
-- the pad's Y: down (with the press handed to the window holding the pad, as the engine's onJoypadDown would),
-- up, and let go of the hook
local function yDown()
    RT.pad("Y", true)
    local F = RT.focus()
    local fw = nil
    pcall(function() fw = F.getFocusedWindow(pn) end)
    if fw and fw:isVisible() and not fw.windowShaded then pcall(F.dispatchJoypadDown, fw, Joypad.YButton) end
end
local function yTap()
    Q.step(2, function() yDown() end)
    Q.step(4, function() RT.pad("Y", false) end)
    Q.step(4, function() RT.pad("Y", nil) end)
end
local function rolledBoth()
    local F = RT.focus()
    local c, w = RT.cw(), RT.ww()
    return F and c and w and F.isRolled(c) and F.isRolled(w) or false
end

-- ===================================================================== helpers for sections 5 to 9 (FEATURE_MAP rows)
-- (kept in one table: the chunk stays far under Kahlua's 200 locals)
local X = {}
function X.copy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for a, b in pairs(t) do o[a] = b end
    return o
end
function X.has(list, v)
    for _, x in ipairs(list or {}) do if x == v then return true end end
    return false
end
-- a press and its release on a panel at x, y (panel-local), through the panel's own mouse handlers
function X.clickAt(panel, x, y)
    if not panel then return false end
    local ok = pcall(panel.onMouseDown, panel, x, y)
    if panel.onMouseUp then pcall(panel.onMouseUp, panel, x, y) end
    return ok
end
-- a zone's middle, or its left part (a heading's disclosure: clear of a Find field or a count on its right)
function X.mid(z) return z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2) end
function X.left(z) return z.x + math.min(T.px(12), math.floor(z.w / 2)), z.y + math.floor(z.h / 2) end
function X.clickZone(panel, z, atLeft)
    if not (panel and z) then return false end
    local x, y
    if atLeft then x, y = X.left(z) else x, y = X.mid(z) end
    return X.clickAt(panel, x, y)
end
-- the first zone in a list whose field f is v
function X.zoneBy(list, f, v)
    for _, z in ipairs(list or {}) do if z[f] == v then return z end end
    return nil
end
-- the pointer where a drag would have it: the game's getMouseX / getMouseY answer mx, my for the length of fn
-- (a resize and a column drag read the pointer, not the event); always put back
function X.withMouse(mx, my, fn)
    local ox, oy = getMouseX, getMouseY
    if mx then getMouseX = function() return mx end end
    if my then getMouseY = function() return my end end
    local ok, e = pcall(fn)
    getMouseX, getMouseY = ox, oy
    return ok, e
end
-- a tab's def on its window's list
function X.tabDef(k, id)
    local list = nil
    pcall(function() list = (k == "c") and ZeD_CharacterWindow.TABS or ZeD_WorldWindow.TABS end)
    for _, t in ipairs(list or {}) do if t.id == id then return t end end
    return nil
end
-- (FEATURE_MAP "Title: name + tab" and "Title: container + tab") the title is the name (or the container) and the open tab
function X.titleCheck(k, w, id, label)
    local def = X.tabDef(k, id)
    if not def then Q.check(false, label .. ": the tab is on its window's list (TABS)"); return end
    local want = nil
    pcall(function()
        if k == "c" then
            want = tostring(w._ttName) .. "  +  " .. ZeD_CharacterWindow.tabLabel(def)
        else
            want = (w._titleBase or ZeD.tr("UI_ZeD_World_Title")) .. "  +  " .. ZeD_WorldWindow.tabLabel(def, w)
        end
    end)
    Q.check(want ~= nil and w.title == want, label .. ": the title names the open tab", "title '" .. tostring(w.title) .. "', want '" .. tostring(want) .. "'")
end
-- (FEATURE_MAP "Drawer widths per tab" and "Drawer widths") the full-card tabs all get the full card, or all the half
-- card where the window holds the drawer in; the others the half card. A two-way radio picks its own (exempt).
X.FULL = { c = { equip = true, health = true, skills = true, thermal = true, identity = true, journal = true },
           w = { craft = true, build = true, maps = true, forage = true, animals = true, vehicle = true, furniture = true } }
S.heldCard = {}
function X.cardCheck(k, w, id, card, label)
    if id == "radio" then return end
    local want = "half"
    local ext = nil
    pcall(function() ext = (k == "c") and ZeD_CharacterWindow._extTabs[id] or ZeD_WorldWindow._extTabs[id] end)
    if X.FULL[k][id] then want = "full"
    elseif ext then want = (ext.drawerW == nil or ext.drawerW > 220) and "full" or "half" end
    if want == "full" then
        S.heldCard[k] = S.heldCard[k] or card
        Q.check(card == S.heldCard[k], label .. ": a full-card tab, the same card as the window's other full-card tabs",
            card .. " (the window's: " .. tostring(S.heldCard[k]) .. ")")
    else
        Q.check(card == "half", label .. ": a half-card tab gets the half card", card)
    end
end
-- (FEATURE_MAP "Lit pixel tab icons" and "Base panel hit zones") every tab on the strip has its lit icon, and every tab's
-- zone is what the strip's own hit test finds at its middle
function X.stripChecks(k, strip)
    local name = nameOf(k)
    local noIcon = {}
    for _, id in ipairs(S.tabs[k] or {}) do
        local has = false
        pcall(function() has = ZeD.TabPx.has(id) end)
        if not has then noIcon[#noIcon + 1] = id end
    end
    Q.check(#S.tabs[k] > 0 and #noIcon == 0, name .. " strip: every tab has its lit pixel icon (ZeD.TabPx.has)",
        (#noIcon == 0) and (#S.tabs[k] .. " tabs") or ("none for " .. table.concat(noIcon, ", ")))
    if not strip then return end
    local bad, seen = {}, 0
    local sh = strip:getHeight()
    for _, z in ipairs(strip._hitZones or {}) do
        if type(z.id) == "string" and z.id:sub(1, 4) == "tab:" then
            local mx, my = X.mid(z)
            if my >= 0 and my < sh then
                seen = seen + 1
                local hz = nil
                pcall(function() hz = strip:hitZoneAt(mx, my) end)
                if not (hz and hz.id == z.id) then bad[#bad + 1] = z.id .. " -> " .. tostring(hz and hz.id) end
            end
        end
    end
    Q.check(seen > 0 and #bad == 0, name .. " strip: each tab's zone is what hitZoneAt finds at its middle",
        (#bad == 0) and (seen .. " zones") or table.concat(bad, "; "))
end
-- open a tab for the checks after it (S.tabIn false when it did not open: the steps after it say so and stand down)
function X.tabStep(k, id)
    Q.step(3, function() resetSettle(); S.tabIn = press(k, id); S.tabId = id end)
    Q.waitFor(5, 600, function() return settled(k, id) end, function(ok)
        S.tabIn = (ok and S.tabIn) and true or false
        if not S.tabIn then
            local w = wOf(k)
            Q.check(false, nameOf(k) .. " tab " .. id .. ": opens for its own checks", "active " .. tostring(w and w._activeTab))
        end
    end)
end
function X.loot(k)
    Q.step(2, function() resetSettle(); press(k, "loot") end)
    Q.waitFor(5, 600, function() return settled(k, "loot") end, function() end)
end
function X.drawerC() local w = RT.cw(); return w and w._drawerPanel end
function X.drawerW() local w = RT.ww(); return w and w._drawerPanel end

-- ===================================================================== setup
Q.step(10, function()
    S.hasErr = errCount() ~= nil
    if not S.hasErr then Q.say("note: no Lua error counter (getLuaDebuggerErrorCount) in this game: the no-error checks are off") end
    S.wasOpen = RT.isOpen()
    S.speed = getGameSpeed()
    if S.speed == 0 then pcall(setGameSpeed, 1) end
    S.snap = (S.wasOpen and ZEDQA_LAYOUT_SNAP) and ZEDQA_LAYOUT_SNAP() or nil
    S.geoC, S.geoW = geo(RT.cw()), geo(RT.ww())
    S.tabC0 = RT.cw() and RT.cw()._activeTab or nil
    S.tabW0 = RT.ww() and RT.ww()._activeTab or nil
    S.pins = {}
    pcall(function()
        local t = RT.p:getModData().ZeD_WinPinned
        if t then for _, k in ipairs(PIN_KEYS) do S.pins[k] = t[k] end end
    end)
    -- (put back at the end: the layout the character keeps, when the pair was shut; the Equip view option; the craft
    -- pins; the saved window places file)
    pcall(function()
        local ws = RT.p:getModData().ZeD_WinState
        S.winState = { had = ws ~= nil, char = ws and X.copy(ws.char), world = ws and X.copy(ws.world) }
    end)
    pcall(function() S.eqView0 = ZeD.EquipDoll.view() end)
    pcall(function() S.craftPins0 = X.copy(RT.p:getModData().ZeD_CraftPins) end)
    pcall(function()
        local pl = ZeD.WindowPlaces.load()
        S.places0 = { char = X.copy(pl.char), world = X.copy(pl.world) }
    end)
    Q.say(string.format("screen %dx%d, half card %d / %d px, full card %d px, pair open %s",
        RT.core:getScreenWidth(), RT.core:getScreenHeight(), T.px(220), T.px(260), T.px(480), tostring(S.wasOpen)))
end)

-- ===================================================================== 1. mouse: the inventory key's action
Q.step(2, function() RT.pairShut() end)
Q.waitFor(5, 240, bothShut, function(ok)
    if S.wasOpen then Q.check(ok, "mouse: the inventory key's action closes both windows", "Character " .. tostring(RT.isOpen()) .. ", World " .. tostring(worldOpen())) end
end)
Q.step(5, function() S.tOk = toggle() end)
Q.waitFor(5, 300, bothOpen, function(ok)
    Q.check(ok and S.tOk, "mouse: the inventory key's action opens both windows", "Character " .. tostring(RT.isOpen()) .. ", World " .. tostring(worldOpen()))
end)
Q.step(30, function() RT.bounds(Q, "both windows open") end)
Q.step(2, function() S.tOk = toggle() end)
Q.waitFor(5, 300, bothShut, function(ok)
    Q.check(ok and S.tOk, "mouse: the inventory key's action closes both windows again", "Character " .. tostring(RT.isOpen()) .. ", World " .. tostring(worldOpen()))
end)
Q.step(5, function() toggle() end)
Q.waitFor(5, 300, bothOpen, function(ok)
    if not ok then Q.check(false, "mouse: the pair opens for the tab walk") end
    pinAll()   -- (no half rolls by itself while the script works: the pointer is elsewhere)
    -- each window's own accent (the reset below and ZEDQA_LAYOUT_BACK clear it; put back at the end)
    S.accC0 = RT.cw() and RT.cw()._accentKey or nil
    S.accW0 = RT.ww() and RT.ww()._accentKey or nil
end)

-- ===================================================================== 2. every tab on both strips
local function tabWalk(k)
    Q.step(10, function()
        local w = wOf(k)
        local strip = w and ((k == "c") and RT.charStrip() or RT.worldStrip())
        S.tabs[k] = RT.tabs(strip)
        Q.check(#S.tabs[k] >= 2, nameOf(k) .. " window: its strip offers its tabs", table.concat(S.tabs[k], ", "))
        if #S.tabs[k] > MAXT then Q.check(false, nameOf(k) .. " window: at most " .. MAXT .. " tabs walked", #S.tabs[k] .. " on the strip") end
        X.stripChecks(k, strip)
    end)
    for i = 1, MAXT do
        Q.step(2, function()
            local id = S.tabs[k][i]
            S.cur = id
            if not id then return end
            resetSettle()
            S.err = errCount()
            S.oth = geo(otherOf(k))
            S.pressed = press(k, id)
        end)
        Q.waitFor(5, 600, function()
            if not S.cur then return true end
            return settled(k, S.cur)
        end, function(ok)
            local id = S.cur
            if not id then return end
            local w = wOf(k)
            local label = nameOf(k) .. " tab " .. id
            local act = w and w._activeTab
            Q.check(S.pressed and act == id, label .. ": pressed on the strip, it is the active tab", "active " .. tostring(act))
            local eff = w and math.floor(w._drawerEffW or 0) or -1
            local card = cardName(eff)
            if id == "loot" then
                Q.check(card ~= "NEITHER", label .. ": no drawer, or the half or the full card", eff .. " px = " .. card)
            else
                Q.check(ok and (card == "half" or card == "full"), label .. ": its drawer is the half card or the full card, nothing between",
                    eff .. " px = " .. card .. (ok and "" or " (still moving)"))
            end
            if id ~= "loot" and w then
                X.titleCheck(k, w, id, label)
                X.cardCheck(k, w, id, card, label)
            end
            local og = geo(otherOf(k))
            Q.check(sameGeo(og, S.oth, 1), label .. ": the other window did not move or change size", gs(S.oth) .. " -> " .. gs(og))
            if S.hasErr then
                local e = errCount()
                Q.check(e == S.err, label .. ": it opened and drew with no Lua error", "errors " .. tostring(S.err) .. " -> " .. tostring(e))
            end
            RT.bounds(Q, label)
        end)
    end
    Q.step(2, function() resetSettle(); press(k, "loot") end)
    Q.waitFor(5, 600, function() return settled(k, "loot") end, function() end)
end
tabWalk("c")
tabWalk("w")

-- ===================================================================== 3. the curtain rolls and unrolls back to the same box
local CURTAIN_TABS = { c = { "skills", "health", "journal" }, w = { "maps", "forage", "craft" } }
local function curtain(k)
    local label = nameOf(k) .. " curtain"
    Q.step(5, function()
        S.ctab = nil
        for _, want in ipairs(CURTAIN_TABS[k]) do
            for _, id in ipairs(S.tabs[k]) do if id == want and not S.ctab then S.ctab = id end end
        end
        if not S.ctab then for _, id in ipairs(S.tabs[k]) do if id ~= "loot" and not S.ctab then S.ctab = id end end end
        S.cskip = nil
        if not S.ctab then S.cskip = "no tab with a drawer on the strip"; return end
        resetSettle()
        press(k, S.ctab)
    end)
    Q.waitFor(5, 600, function() return S.cskip ~= nil or settled(k, S.ctab) end, function()
        if S.cskip then return end
        local w = wOf(k)
        local can = false
        pcall(function() can = w._curtain.canRoll() end)
        if not can then S.cskip = "the side cannot roll on " .. tostring(S.ctab) .. " here (the drawer hides the list)"; return end
        S.box, S.obox = geo(w), geo(otherOf(k))
        S.err = errCount()
        S.pressErr = nil
        viaUpdate(w, function(self) ZeD.Curtain.roll(self) end)
    end)
    Q.waitFor(2, 400, function()
        if S.cskip then return true end
        local w = wOf(k)
        local rod = w and w._rod
        return w._qaPressDone == true and w._rolled == true and rod ~= nil and rod._chip ~= nil and (rod._h or 999) <= T.titleBarH
    end, function(ok)
        if S.cskip then Q.skip(label, S.cskip); return end
        local w = wOf(k)
        local rod = w._rod
        Q.check(ok and w._rolled == true and rod ~= nil and rod:isVisible(), label .. ": the side rolls up under its rod (on " .. S.ctab .. ")",
            "rolled " .. tostring(w._rolled) .. ", rod " .. tostring(rod ~= nil and rod:isVisible()) .. (S.pressErr and (", error " .. S.pressErr) or ""))
        local g = geo(w)
        local rw = w._rollW or 0
        Q.check(g.w == S.box.w - rw and g.y == S.box.y and g.h == S.box.h, label .. ": rolled, the window is its box less the side",
            gs(S.box) .. " less " .. rw .. " -> " .. gs(g))
        RT.bounds(Q, label .. " rolled")
        -- the rod's tab pressed (in the rod's update): it rolls down, then the side comes back
        if rod and rod._chip then
            local c = rod._chip
            viaUpdate(rod, function(self) self:onMouseDown(c.x + 2, c.y + 2); self:onMouseUp(c.x + 2, c.y + 2) end)
        else
            ZeD.Curtain.unroll(w)
        end
    end)
    Q.waitFor(2, 600, function()
        if S.cskip then return true end
        local w = wOf(k)
        return w and not w._rolled
    end, function(ok)
        if S.cskip then return end
        local w = wOf(k)
        local g = geo(w)
        Q.check(ok, label .. ": the rod's tab rolls the side back down", "rolled " .. tostring(w._rolled))
        Q.check(sameGeo(g, S.box, 0), label .. ": unrolled, the window is back in the same box to the pixel", gs(S.box) .. " -> " .. gs(g))
        Q.check(not (w._rod and w._rod:isVisible()), label .. ": the rod is gone from the screen")
        Q.check(sameGeo(geo(otherOf(k)), S.obox, 0), label .. ": the other window never moved", gs(S.obox) .. " -> " .. gs(geo(otherOf(k))))
        if S.hasErr then Q.check(errCount() == S.err, label .. ": no Lua error through the roll", tostring(S.err) .. " -> " .. tostring(errCount())) end
    end)
    Q.step(2, function() resetSettle(); press(k, "loot") end)
    Q.waitFor(5, 600, function() return settled(k, "loot") end, function() end)
end
curtain("c")
curtain("w")

-- ===================================================================== 5. inside the Character tabs
-- Each press goes through the drawer's own mouse handler (drawer.onMouseDown at a stamped zone), as a click does.
-- Equip: List / Doll, a group's fold, a column's width drag (FEATURE_MAP: "List / Doll toggle", "Equip list: group
-- fold", "Equip list: column width drag")
X.tabStep("c", "equip")
Q.step(6, function()
    S.eq = nil
    if not S.tabIn then return end
    local w, D = RT.cw(), ZeD.EquipDoll
    S.eq = { view = D.view(), listExp = w._equipListExpanded, exp = X.copy(w._equipExpanded), colW = X.copy(w._equipColWidths) }
    local other = (S.eq.view == "doll") and "list" or "doll"
    local z = X.zoneBy(w._equipViewZones, "view", other)
    if not z then Q.check(false, "Equip: the List and Doll buttons are drawn in the heading"); return end
    X.clickZone(X.drawerC(), z)
    local v = nil
    pcall(function() v = ZeD.Settings.equipViewOption:getValue() end)
    Q.check(D.view() == other and v == ((other == "doll") and 2 or 1), "Equip: the " .. other .. " button shows the " .. other .. " view, the option follows",
        "view " .. tostring(D.view()) .. ", option " .. tostring(v))
end)
Q.step(6, function()
    if not S.eq then return end
    local w, D = RT.cw(), ZeD.EquipDoll
    if D.view() ~= "list" then
        X.clickZone(X.drawerC(), X.zoneBy(w._equipViewZones, "view", "list"))
        Q.check(D.view() == "list", "Equip: the list button brings the list back", "view " .. tostring(D.view()))
    end
    w._equipListExpanded = true   -- (the list shows its groups for the next checks; put back after)
end)
Q.step(6, function()
    S.gid = nil
    if not S.eq then return end
    local w = RT.cw()
    local gz = (w._equipGroupZones or {})[1]
    if not gz then Q.check(false, "Equip: the list draws its group headings"); return end
    S.gid, S.gwas = gz.id, (w._equipExpanded[gz.id] and true or false)
    X.clickZone(X.drawerC(), gz, true)
    local now = w._equipExpanded[gz.id] and true or false
    Q.check(now ~= S.gwas, "Equip: a group heading pressed folds or opens its group (" .. tostring(gz.id) .. ")", tostring(S.gwas) .. " -> " .. tostring(now))
end)
Q.step(4, function()
    if not S.gid then return end
    local w = RT.cw()
    X.clickZone(X.drawerC(), X.zoneBy(w._equipGroupZones, "id", S.gid), true)
    local now = w._equipExpanded[S.gid] and true or false
    Q.check(now == S.gwas, "Equip: pressed again, the group is back as it was", tostring(now))
end)
Q.step(4, function()
    if not S.eq then return end
    local w, dp = RT.cw(), X.drawerC()
    local dz = (w._equipDivZones or {})[1]
    if not dz then Q.check(false, "Equip: the column dividers are stamped on the list's heading"); return end
    local mx, my = X.mid(dz)
    pcall(dp.onMouseDown, dp, mx, my)
    local cd = w._equipColDrag
    if not Q.check(cd ~= nil, "Equip: a press on a column divider starts its drag (" .. tostring(dz.col) .. ")") then return end
    local col, startW = cd.col, cd.startW
    -- the pointer 10 units right of the press: the column (its left edge on the divider) is 10 units narrower
    local want = math.max(T.px(30), math.min(math.floor(dp:getWidth() / 2), startW - T.px(10)))
    X.withMouse(cd.startX + T.px(10), nil, function() dp:onMouseMove(T.px(10), 0) end)
    local nw = w._equipColWidths and w._equipColWidths[col]
    Q.check(nw == want, "Equip: the drag sets the column's width from the pointer", tostring(startW) .. " -> " .. tostring(nw) .. ", want " .. tostring(want))
    pcall(dp.onMouseUp, dp, mx, my)
    Q.check(w._equipColDrag == nil, "Equip: the release ends the column drag")
end)
Q.step(3, function()
    if not S.eq then return end
    local w = RT.cw()
    if S.eq.view == "doll" then pcall(ZeD.EquipDoll.setView, "doll") end
    w._equipListExpanded = S.eq.listExp
    if S.eq.exp then w._equipExpanded = S.eq.exp end
    w._equipColWidths = S.eq.colW
end)

-- Health: the figure's fold, the exercise picker, the session time (FEATURE_MAP: "Figure disclosure" (Health),
-- "Exercise picker", "Session time - / +")
X.tabStep("c", "health")
Q.step(6, function()
    S.fig = nil
    if not S.tabIn then return end
    local w = RT.cw()
    if not w._healthFigureZone then Q.check(false, "Health: the figure's heading is stamped"); return end
    S.fig = w._healthFigureExpanded and true or false
    X.clickZone(X.drawerC(), w._healthFigureZone, true)
    local now = w._healthFigureExpanded and true or false
    Q.check(now ~= S.fig, "Health: the figure's heading pressed folds or opens the figure", tostring(S.fig) .. " -> " .. tostring(now))
end)
Q.step(4, function()
    if S.fig == nil then return end
    local w = RT.cw()
    X.clickZone(X.drawerC(), w._healthFigureZone, true)
    Q.check((w._healthFigureExpanded and true or false) == S.fig, "Health: pressed again, the figure is back as it was")
    w._healthFigureExpanded = S.fig
end)
Q.step(4, function()
    S.ex = nil
    if not S.tabIn then return end
    local w = RT.cw()
    local bz = w._healthBand
    if not (bz and bz.box and bz.box.w and bz.inc and bz.inc.w) then Q.check(false, "Health: the exercise band is drawn"); return end
    S.ex = { sel = w._healthExerciseSel, min = w._healthExerciseMinutes }
    X.clickZone(X.drawerC(), bz.box)
    Q.check(w._healthMenuOpen == true, "Health: the exercise box opens its list")
end)
Q.step(4, function()
    if not S.ex then return end
    local w, HT = RT.cw(), ZeD.HealthTab
    local cur = HT.selectedExercise(w)
    local pick = nil
    for _, z in ipairs(w._healthMenuZones or {}) do if z.id ~= cur and not pick then pick = z end end
    if not pick then
        Q.check(false, "Health: the exercise list shows its rows", tostring(#(w._healthMenuZones or {})) .. " rows")
        pcall(HT.closeMenu, w)
        return
    end
    X.clickZone(X.drawerC(), pick)
    Q.check(HT.selectedExercise(w) == pick.id and not w._healthMenuOpen, "Health: a row picked is the exercise, the list shut",
        tostring(HT.selectedExercise(w)) .. ", open " .. tostring(w._healthMenuOpen))
    w._healthExerciseSel = S.ex.sel
end)
Q.step(3, function()
    if not S.ex then return end
    local w, HT = RT.cw(), ZeD.HealthTab
    local bz = w._healthBand
    local m0 = HT.getExerciseMinutes(w)
    local up = m0 < 60
    X.clickZone(X.drawerC(), up and bz.inc or bz.dec)
    local m1 = HT.getExerciseMinutes(w)
    Q.check(m1 == m0 + (up and 10 or -10), "Health: the session time's " .. (up and "+" or "-") .. " steps it 10 minutes", m0 .. " -> " .. m1)
    X.clickZone(X.drawerC(), up and bz.dec or bz.inc)
    Q.check(HT.getExerciseMinutes(w) == m0, "Health: the other button steps it back", tostring(HT.getExerciseMinutes(w)))
    -- kept inside 10 to 60: + at 60 holds
    w._healthExerciseMinutes = 60
    X.clickZone(X.drawerC(), bz.inc)
    Q.check(HT.getExerciseMinutes(w) == 60, "Health: + at 60 minutes holds at 60", tostring(HT.getExerciseMinutes(w)))
    w._healthExerciseMinutes = S.ex.min
end)

-- Thermal: the view picker, the figure's fold, the units (FEATURE_MAP: "View picker (7 views)", "Figure disclosure"
-- (Thermal), "Units follow the game option")
X.tabStep("c", "thermal")
Q.step(6, function()
    S.fig = nil
    if not S.tabIn then return end
    local w = RT.cw()
    if not w._thermalFigureZone then Q.check(false, "Thermal: the figure's heading is stamped"); return end
    S.fig = w._thermalFigureExpanded and true or false
    X.clickZone(X.drawerC(), w._thermalFigureZone, true)
    local now = w._thermalFigureExpanded and true or false
    Q.check(now ~= S.fig, "Thermal: the figure's heading pressed folds or opens the figure", tostring(S.fig) .. " -> " .. tostring(now))
end)
Q.step(4, function()
    if S.fig == nil then return end
    local w = RT.cw()
    X.clickZone(X.drawerC(), w._thermalFigureZone, true)
    Q.check((w._thermalFigureExpanded and true or false) == S.fig, "Thermal: pressed again, the figure is back as it was")
    w._thermalFigureExpanded = S.fig
end)
Q.step(4, function()
    S.tv = nil
    if not S.tabIn then return end
    local w = RT.cw()
    local bz = w._thermalBand
    if not (bz and bz.box and bz.box.w) then Q.check(false, "Thermal: the View band is drawn"); return end
    S.tv = { v = w._thermalView }
    X.clickZone(X.drawerC(), bz.box)
    Q.check(w._thermalMenuOpen == true, "Thermal: the View box opens its list")
end)
Q.step(4, function()
    if not S.tv then return end
    local w = RT.cw()
    local cur = w._thermalView or 1
    local zs = w._thermalMenuZones or {}
    local pick = nil
    for _, z in ipairs(zs) do if z.id ~= cur and not pick then pick = z end end
    Q.check(#zs == 7, "Thermal: the View list offers 7 views", #zs .. " rows")
    if not pick then pcall(ZeD.ThermalTab.closeMenu, w); return end
    X.clickZone(X.drawerC(), pick)
    Q.check(w._thermalView == pick.id and not w._thermalMenuOpen, "Thermal: a view picked is the view, the list shut",
        tostring(w._thermalView) .. ", open " .. tostring(w._thermalMenuOpen))
    w._thermalView = S.tv.v
end)
Q.step(2, function()
    local TT = ZeD.ThermalTab
    local opt = nil
    pcall(function() opt = getCore():getOptionDisplayAsCelsius() end)
    local s, c, f = "", "", ""
    pcall(function() s, c, f = TT.tempText(37), TT.tempText(37, true), TT.tempText(37, false) end)
    Q.check(opt ~= nil and TT.useCelsius() == (opt and true or false) and s == (opt and c or f)
        and c:find("37.0", 1, true) ~= nil and f:find("98.6", 1, true) ~= nil,
        "Thermal: temperatures follow the game's Celsius option", "option " .. tostring(opt) .. ": '" .. s .. "' (C '" .. c .. "', F '" .. f .. "')")
end)

-- Skills: the grid's fold; the title's health pixel; Show all (FEATURE_MAP: "Skill grid disclosure", "Title: name + tab,
-- health pixel", "Show all (bumper, Y)")
X.tabStep("c", "skills")
Q.step(6, function()
    S.fig = nil
    if not S.tabIn then return end
    local w = RT.cw()
    local hp, want = nil, nil
    pcall(function() hp = math.floor(RT.p:getBodyDamage():getOverallBodyHealth()) end)
    pcall(function() want = ZeD.tr("UI_ZeD_Char_HealthHelp", getText("IGUI_XP_Health"), ZeD.Atoms.pctText(hp / 100)) end)
    Q.check(w._titleMark ~= nil and want ~= nil and w._titleHelp == want, "Character title: the health pixel is drawn, its help line gives the health",
        tostring(w._titleHelp) .. " (want " .. tostring(want) .. ")")
    if not w._skillsGridZone then Q.check(false, "Skills: the grid's heading is stamped"); return end
    S.fig = w._skillsGridExpanded and true or false
    X.clickZone(X.drawerC(), w._skillsGridZone, true)
    local now = w._skillsGridExpanded and true or false
    Q.check(now ~= S.fig, "Skills: the grid's heading pressed folds or opens the grid", tostring(S.fig) .. " -> " .. tostring(now))
end)
Q.step(4, function()
    if S.fig == nil then return end
    local w = RT.cw()
    X.clickZone(X.drawerC(), w._skillsGridZone, true)
    Q.check((w._skillsGridExpanded and true or false) == S.fig, "Skills: pressed again, the grid is back as it was")
    w._skillsGridExpanded = S.fig
end)
-- Show all: the halves unpinned and rolled (the pad's aim), then brought back as a bumper or Y does (Focus.showWin)
Q.step(3, function()
    S.sa = S.tabIn and ZeD.Halves ~= nil and RT.focus() ~= nil
    if not S.sa then return end
    local w = RT.cw()
    pcall(ZeD.Halves.setPin, w, nil, false)
    pcall(ZeD.Halves.aim, w)
end)
Q.waitFor(2, 120, function() return (not S.sa) or RT.focus().isRolled(RT.cw()) end, function(ok)
    if not S.sa then return end
    Q.check(ok, "Show all: first the unpinned halves roll (the pad's aim)")
    pcall(RT.focus().showWin, RT.cw())
end)
Q.waitFor(2, 120, function()
    local w = RT.cw()
    return (not S.sa) or (w and not ZeD.Halves.anyRolled(w) and not w.windowShaded)
end, function(ok)
    if not S.sa then return end
    local w = RT.cw()
    Q.check(ok, "Show all: brought back (a bumper or Y), no half rolled and the window not shaded",
        "anyRolled " .. tostring(ZeD.Halves.anyRolled(w)) .. ", shaded " .. tostring(w.windowShaded))
    pinAll()
end)
-- Half pins (FEATURE_MAP "Half pins (inventory / tabs)", Nov 18 2026 ledger): each half's pin (what the title bar's
-- pin box and the pad's "halfpin:" stop run, ZeD.Halves.togglePin) flips it and saves it with the character; again
-- puts it back
Q.step(3, function()
    local w, H = RT.cw(), ZeD.Halves
    if not (w and w._halves and H and H.togglePin) then Q.check(false, "Half pins: the Character window has its halves"); return end
    for _, half in ipairs({ "inv", "drawer" }) do
        local key = (half == "inv") and "charInv" or "charTabs"
        local was = w._halves[half].pinned and true or false
        pcall(H.togglePin, w, half)
        local now = w._halves[half].pinned and true or false
        local md = nil
        pcall(function() md = RT.p:getModData().ZeD_WinPinned end)
        local saved = md and md[key]
        Q.check(now ~= was and saved ~= nil and (saved and true or false) == now, "Half pins: a half's pin pressed flips it, saved with the character",
            half .. ": " .. tostring(was) .. " -> " .. tostring(now) .. ", " .. key .. " " .. tostring(saved))
        pcall(H.togglePin, w, half)
        Q.check((w._halves[half].pinned and true or false) == was, "Half pins: pressed again, the pin is back as it was", half)
    end
    pinAll()
end)

-- Identity: one controller stop per trait row (FEATURE_MAP: "Traits list")
X.tabStep("c", "identity")
Q.step(8, function()
    if not S.tabIn then return end
    local w = RT.cw()
    local zs = w._idTraitZones or {}
    local n = zs.n or #zs
    if n == 0 then Q.skip("Identity: one controller stop per trait row", "this character shows no traits"); return end
    local stops = 0
    local okF, els = pcall(ZeD.IdentityTab.focusables, w)
    for _, e in ipairs(okF and els or {}) do
        if type(e.id) == "string" and e.id:sub(1, 15) == "identity:trait:" then stops = stops + 1 end
    end
    Q.check(stops == n, "Identity: one controller stop per trait row", stops .. " stops, " .. n .. " rows")
end)
X.loot("c")

-- ===================================================================== 6. inside the World tabs
-- Craft: Sort, Show, Category, then a pin by right-click (FEATURE_MAP: "Craft: Sort / Show / category", "Craft: pins")
X.tabStep("w", "craft")
Q.step(8, function()
    S.cr = nil
    if not S.tabIn then return end
    local st = RT.ww()._craftState
    if not st then Q.check(false, "Craft: the tab's state is up"); return end
    S.cr = { sort = st.sort, show = st.show, showAll = st.showAll, cat = st.activeCat }
    local z = X.zoneBy(st.zones, "type", "sortMenu")
    if not z then Q.check(false, "Craft: the band's Sort box is drawn"); return end
    X.clickZone(X.drawerW(), z)
    Q.check(st.sortMenuOpen == true, "Craft: the Sort box opens its list")
end)
Q.step(4, function()
    if not S.cr then return end
    local st = RT.ww()._craftState
    if not st.sortMenuOpen then return end
    local pick = nil
    for _, z in ipairs(st._sortMenuZones or {}) do if z.id ~= st.sort and not pick then pick = z end end
    if not pick then Q.check(false, "Craft: the Sort list shows its choices"); st.sortMenuOpen = false; return end
    X.clickZone(X.drawerW(), pick)
    Q.check(st.sort == pick.id and not st.sortMenuOpen, "Craft: a Sort choice picked is the order, the list shut", tostring(st.sort))
end)
Q.step(4, function()
    if not S.cr then return end
    local st = RT.ww()._craftState
    local z = X.zoneBy(st.zones, "type", "showMenu")
    if not z then Q.check(false, "Craft: the band's Show box is drawn"); return end
    X.clickZone(X.drawerW(), z)
    Q.check(st.showMenuOpen == true, "Craft: the Show box opens its list")
end)
Q.step(4, function()
    if not S.cr then return end
    local st = RT.ww()._craftState
    if not st.showMenuOpen then return end
    local cur = st.show or (st.showAll and "all") or "ready"
    local pick = X.zoneBy(st._showMenuZones, "id", "all")
    if cur == "all" or not pick then
        pick = nil
        for _, z in ipairs(st._showMenuZones or {}) do if z.id ~= cur and not pick then pick = z end end
    end
    if not pick then Q.check(false, "Craft: the Show list shows its choices"); st.showMenuOpen = false; return end
    X.clickZone(X.drawerW(), pick)
    Q.check(st.show == pick.id and not st.showMenuOpen, "Craft: a Show choice picked is what the list shows, the list shut", tostring(st.show))
end)
Q.step(4, function()
    if not S.cr then return end
    local st = RT.ww()._craftState
    local z = X.zoneBy(st.zones, "type", "catDropdown")
    if not z then Q.check(false, "Craft: the band's Category select is drawn"); return end
    X.clickZone(X.drawerW(), z)
    Q.check(st.catDropdownOpen == true, "Craft: the Category select opens its list")
end)
Q.step(4, function()
    if not S.cr then return end
    local st = RT.ww()._craftState
    if not st.catDropdownOpen then return end
    local geo, cats = st._ddGeo, st.categoryList or {}
    local idx = (st.catDropdownScroll or 0) + 2
    if not (geo and cats[idx]) then
        Q.check(false, "Craft: the Category list has a second row", #cats .. " categories")
        st.catDropdownOpen = false
        return
    end
    X.clickAt(X.drawerW(), geo.x + T.px(10), geo.y + T.px(20) + T.px(10))
    Q.check(st.activeCat == cats[idx].id and not st.catDropdownOpen, "Craft: a category picked filters the list, the select shut",
        tostring(st.activeCat) .. " (want " .. tostring(cats[idx].id) .. ")")
    -- back to the category it had and the order it had; Show stays on "all" for the pin below (put back after)
    st.activeCat, st.sort, st.filterDirty = S.cr.cat, S.cr.sort, true
end)
Q.step(15, function()
    S.pin = nil
    if not S.cr then return end
    local w = RT.ww()
    local st = w._craftState
    local lg = st._listGeo
    for _, z in ipairs(st.zones or {}) do
        if not S.pin and z.type == "recipeRow" and not X.has(w._craftPins, z.id) then
            local cy = z.y + math.floor(z.h / 2)
            if not lg or (cy >= lg.viewY and cy < lg.viewY + lg.viewH) then S.pin, S.pinZ = z.id, z end
        end
    end
    if not S.pin then Q.check(false, "Craft: the list shows a recipe row to pin (Show: all)"); return end
    S.pins0 = X.copy(w._craftPins)
    local dp = X.drawerW()
    local mx, my = X.mid(S.pinZ)
    pcall(dp.onRightMouseDown, dp, mx, my)
    local md = nil
    pcall(function() md = RT.p:getModData().ZeD_CraftPins end)
    Q.check(X.has(w._craftPins, S.pin) and X.has(md, S.pin), "Craft: a right-click on a recipe row pins it, saved with the character", tostring(S.pin))
end)
Q.step(15, function()
    if not S.pin then return end
    local w = RT.ww()
    local st = w._craftState
    local lg = st._listGeo
    local zz = nil
    for _, z in ipairs(st.zones or {}) do
        if not zz and z.type == "recipeRow" and z.id == S.pin then
            local cy = z.y + math.floor(z.h / 2)
            if not lg or (cy >= lg.viewY and cy < lg.viewY + lg.viewH) then zz = z end
        end
    end
    if not zz then Q.check(false, "Craft: the pinned recipe's row is on view to unpin", tostring(S.pin)); return end
    local dp = X.drawerW()
    local mx, my = X.mid(zz)
    pcall(dp.onRightMouseDown, dp, mx, my)
    local md = nil
    pcall(function() md = RT.p:getModData().ZeD_CraftPins end)
    Q.check(not X.has(w._craftPins, S.pin) and not X.has(md, S.pin), "Craft: a right-click on it again unpins it", tostring(S.pin))
end)
Q.step(2, function()
    if not S.cr then return end
    local w = RT.ww()
    local st = w._craftState
    st.sort, st.show, st.showAll, st.activeCat = S.cr.sort, S.cr.show, S.cr.showAll, S.cr.cat
    st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen = false, false, false
    if S.pins0 ~= nil or S.pin then
        w._craftPins = X.copy(S.pins0) or {}
        st.pins = w._craftPins
        pcall(function() RT.p:getModData().ZeD_CraftPins = X.copy(S.craftPins0) end)
    end
    st.filterDirty = true
end)

-- Foraging: the focus drop-down, More detail (FEATURE_MAP: "Foraging: focus dropdown, More detail")
X.tabStep("w", "forage")
Q.step(8, function()
    S.fg = nil
    if not S.tabIn then return end
    local dd = RT.ww()._forageDropdown
    if not dd then Q.check(false, "Foraging: the focus drop-down is drawn"); return end
    S.fg = { sel = dd.selectedId }
    pcall(dd.onMouseDown, dd, T.px(4), math.floor(T.inputH / 2))
    Q.check(dd.isOpen == true, "Foraging: the focus drop-down opens")
end)
Q.step(4, function()
    if not S.fg then return end
    local dd = RT.ww()._forageDropdown
    local idx = nil
    for i, o in ipairs(dd.options or {}) do if not idx and o.id ~= S.fg.sel then idx = i end end
    if not idx then
        pcall(dd.onMouseDown, dd, T.px(4), T.inputH + math.floor(T.rowH / 2))
        Q.check(not dd.isOpen, "Foraging: a row pressed shuts the drop-down")
        Q.skip("Foraging: another focus picked", "only one focus is offered at this character's foraging level")
        return
    end
    pcall(dd.onMouseDown, dd, T.px(4), T.inputH + (idx - 1 - (dd.scrollOffset or 0)) * T.rowH + math.floor(T.rowH / 2))
    local id = dd.options[idx].id
    local cat = nil
    pcall(function() cat = ISSearchWindow.players[RT.p].searchFocusCategory end)
    local want = (id == "none") and "None" or id
    Q.check(dd.selectedId == id and not dd.isOpen and cat == want, "Foraging: a focus picked is the game's search focus, the drop-down shut",
        tostring(dd.selectedId) .. ", the game's " .. tostring(cat))
    dd.selectedId = S.fg.sel
    if dd.onChange then pcall(dd.onChange, dd, S.fg.sel) end
end)
Q.step(3, function()
    S.fig = nil
    if not S.tabIn then return end
    local w = RT.ww()
    local z = w._forageDisclosureZone
    if not z then Q.check(false, "Foraging: the More detail heading is stamped"); return end
    S.fig = w._moreDetailOpen and true or false
    X.clickZone(X.drawerW(), z, true)
    local now = w._moreDetailOpen and true or false
    Q.check(now ~= S.fig, "Foraging: More detail pressed opens or folds it", tostring(S.fig) .. " -> " .. tostring(now))
end)
Q.step(4, function()
    if S.fig == nil then return end
    local w = RT.ww()
    X.clickZone(X.drawerW(), w._forageDisclosureZone, true)
    Q.check((w._moreDetailOpen and true or false) == S.fig, "Foraging: pressed again, More detail is back as it was")
    w._moreDetailOpen = S.fig
end)
X.loot("w")
Q.step(2, function()
    -- (FEATURE_MAP "Extension tabs" (World)) every tab another file added is registered and on the tab list
    local ext = ZeD_WorldWindow._extTabs or {}
    local ids, missing = {}, {}
    for id in pairs(ext) do
        ids[#ids + 1] = tostring(id)
        if not X.tabDef("w", id) then missing[#missing + 1] = tostring(id) end
    end
    Q.check(ext.fishing ~= nil and #missing == 0, "World extension tabs: each one added (addTab) is registered and on the tab list",
        table.concat(ids, ", ") .. ((#missing > 0) and (", not on the list: " .. table.concat(missing, ", ")) or ""))
end)
Q.step(2, function()
    -- (FEATURE_MAP "Extension tabs" (Character), Nov 18 2026 ledger) every tab another file added (Cooking always) is
    -- registered and on the Character window's tab list
    local ext = ZeD_CharacterWindow._extTabs or {}
    local ids, missing = {}, {}
    for id in pairs(ext) do
        ids[#ids + 1] = tostring(id)
        if not X.tabDef("c", id) then missing[#missing + 1] = tostring(id) end
    end
    Q.check(ext.cooking ~= nil and #missing == 0, "Character extension tabs: each one added (addTab) is registered and on the tab list",
        table.concat(ids, ", ") .. ((#missing > 0) and (", not on the list: " .. table.concat(missing, ", ")) or ""))
end)

-- ===================================================================== 7. the window box's menu (Character window)
-- (FEATURE_MAP: "Window box menu", "Per-window accent", "Save / go to saved position", "Reset this window / both")
Q.step(5, function()
    local w = RT.cw()
    pcall(function() w:openWindowMenu() end)
    local m = ZeD.WindowMenu and ZeD.WindowMenu.current
    S.wm = m
    Q.check(m ~= nil and m._ctx ~= nil and m._ctx.open == true and w._wboxOpen == true, "Window menu: the window box pulls its menu down",
        "menu " .. tostring(m ~= nil) .. ", box open " .. tostring(w._wboxOpen))
end)
Q.step(5, function()
    local m = S.wm
    if not m then return end
    RT.bounds(Q, "the window menu")
    local SS = ZeD.Settings
    local names = {}
    for _, it in ipairs(m._ctx.actions or {}) do names[#names + 1] = it.name end
    local need = { "UI_ZeD_WinMenu_Theme", "UI_ZeD_WinMenu_Accent", "UI_ZeD_Settings_TextSize", "UI_ZeD_WinMenu_ResetThis",
                   "UI_ZeD_WinMenu_ResetBoth", "UI_ZeD_WinMenu_SavePos", "UI_ZeD_WinMenu_GoSaved", "UI_ZeD_WinMenu_Setup" }
    if SS.seeThroughKeys then need[#need + 1] = "UI_ZeD_Settings_SeeThrough" end
    if SS.focusStyleKeys then need[#need + 1] = "UI_ZeD_Settings_FocusStyle" end
    if ZeD.Messages and ZeD.Messages.copyBugReport then need[#need + 1] = "UI_ZeD_Msg_BugReport" end
    -- (Nov 22 2026, QA K1-6: Hide the interface left the mouse's menu, since a mouse has no way back from it; the pad's
    -- View wheel keeps Hide and Show interface. Until beta 21c this list needed the Hide interface row.)
    local missing = {}
    for _, k in ipairs(need) do if not X.has(names, ZeD.tr(k)) then missing[#missing + 1] = k end end
    Q.check(#missing == 0, "Window menu: it has its rows (Theme to ZeD setup)", (#missing == 0) and (#names .. " rows") or ("missing " .. table.concat(missing, ", ")))
    -- (QA K1-6) the row is gone from the menu the mouse opens, and the pad's View wheel (D-pad Down > View) still offers
    -- it, under its own name (Show interface while the interface is hidden). On 2488ceead (beta 21c) the menu has the
    -- row, so this FAILS there; on 0ebd56570 it PASSES.
    local hideRow = X.has(names, ZeD.tr("UI_ZeD_Wheel_HideInterface")) or X.has(names, ZeD.tr("UI_ZeD_Wheel_ShowInterface"))
    local onWheel = false
    local DW = ZeD.DpadWheels
    if DW and DW.N and DW.N.view then
        local okV, view = pcall(DW.N.view, RT.p, pn)
        for _, e in ipairs((okV and type(view) == "table") and view or {}) do
            if e.run and (e.name == ZeD.tr("UI_ZeD_Wheel_HideInterface") or e.name == ZeD.tr("UI_ZeD_Wheel_ShowInterface")) then onWheel = true end
        end
    end
    Q.check(not hideRow and onWheel, "Window menu: no Hide interface row (a mouse has no way back from it); the pad's View wheel keeps it (QA K1-6)",
        "row in the menu " .. tostring(hideRow) .. ", on the View wheel " .. tostring(onWheel))
    -- Accent: a pick gives this window its own accent; "Same as Accent color" clears it (the rows' own onFire)
    local w = RT.cw()
    S.acc = w._accentKey
    local acc = nil
    for _, it in ipairs(m._ctx.actions or {}) do if it.name == ZeD.tr("UI_ZeD_WinMenu_Accent") then acc = it end end
    local pick, same = nil, nil
    for _, c in ipairs(acc and acc.children or {}) do
        if c.category == "follow" then same = c
        elseif not pick then
            local ok, on = pcall(c.checked)
            if ok and not on then pick = c end
        end
    end
    if pick then
        pcall(pick.onFire)
        local ok, on = pcall(pick.checked)
        Q.check(w._accentKey ~= nil and ok and on, "Window menu: Accent > " .. tostring(pick.name) .. " is this window's own accent", tostring(w._accentKey))
    else
        Q.check(false, "Window menu: the Accent submenu offers the accents")
    end
    if same then
        pcall(same.onFire)
        Q.check(w._accentKey == nil, "Window menu: Accent > Same as Accent color clears it", tostring(w._accentKey))
    else
        Q.check(false, "Window menu: the Accent submenu offers Same as Accent color")
    end
    w._accentKey = S.acc
    pcall(ZeD.Settings.syncWindowAccent, w)
    pcall(function() m:close() end)
    Q.check(w._wboxOpen == nil and ZeD.WindowMenu.current == nil, "Window menu: it closes", "box open " .. tostring(w._wboxOpen))
end)
-- Save position, then the window moved down, then Go to saved position (the file is put back after)
Q.step(5, function()
    local w, WP = RT.cw(), ZeD.WindowPlaces
    S.wpRec = nil
    if not WP then Q.check(false, "Save position: ZeD.WindowPlaces is loaded"); return end
    S.wpTouched = true
    local M = ZeD.Messages
    local said = false
    local oldNotice = M and M.notice
    if M then M.notice = function() said = true end end   -- (its Messages note counted, not posted)
    local ok = false
    pcall(function() ok = WP.save(w) end)
    if M then M.notice = oldNotice end
    local k, rec = nil, nil
    pcall(function() k, rec = WP.capture(w) end)
    local fr = WP.load()[k or "char"]
    Q.check(ok and k == "char" and rec ~= nil and fr ~= nil and math.abs(fr.x - rec.x) < 0.02 and math.abs(fr.y - rec.y) < 0.02
        and math.abs(fr.w - rec.w) < 0.02, "Save position: the window's place is in the file under char, read back",
        tostring(k) .. (fr and string.format(" x %.2f y %.2f w %.2f", fr.x, fr.y, fr.w) or " (none)"))
    Q.check(said, "Save position: a note says it was saved")
    S.wpRec = fr
    -- (the place as the window stood when saved: a width this screen's fit narrowed is saved as the width it came
    -- from, so the box on screen, not the record's numbers, is what Go to saved position must give back)
    S.wpGeo = geo(w)
    w:setY(w:getY() + T.px(30))
end)
Q.step(10, function()
    if not S.wpRec then return end
    local w = RT.cw()
    S.wpGo = false
    pcall(function() S.wpGo = ZeD.WindowPlaces.goTo(w) end)
end)
Q.step(10, function()
    if not S.wpRec then return end
    local w = RT.cw()
    local g = geo(w)
    Q.check(S.wpGo and sameGeo(g, S.wpGeo, 2), "Go to saved position: the window is back at its saved place", gs(S.wpGeo) .. " -> " .. gs(g))
    RT.bounds(Q, "after Go to saved position")
end)
-- Reset this window, then Reset both, through the rows' own onFire (from a tab, the window moved)
X.tabStep("c", "skills")
Q.step(5, function()
    local w = RT.cw()
    w:setY(w:getY() + T.px(20))
    S.rs = nil
    local items = {}
    pcall(function() items = ZeD.WindowMenu.build(w) end)
    for _, it in ipairs(items) do
        if it.name == ZeD.tr("UI_ZeD_WinMenu_ResetThis") then S.rs = S.rs or {}; S.rs.this = it end
        if it.name == ZeD.tr("UI_ZeD_WinMenu_ResetBoth") then S.rs = S.rs or {}; S.rs.both = it end
    end
    if not (S.rs and S.rs.this and S.rs.both) then Q.check(false, "Reset: the menu has Reset this window and Reset both windows"); S.rs = nil; return end
    pcall(S.rs.this.onFire)
end)
Q.step(10, function()
    if not S.rs then return end
    local w = RT.cw()
    local sw, sh, sl, st = ZeD.screenOf(w)
    local right = w:getX() + w:getWidth()
    local want = sl + math.floor(sw / 2) - T.px(5)
    Q.check(math.abs(right - want) <= 1 and math.abs(w:getY() - st) <= 1 and w._activeTab == "loot" and not w._rolled and ZeD.Halves.foldedTab(w) == nil,
        "Reset this window: the Character window is back in the spread (right edge mid-screen less 5 px), on Loot",
        "right " .. right .. " (want " .. want .. "), y " .. w:getY() .. ", tab " .. tostring(w._activeTab))
    pcall(S.rs.both.onFire)
end)
Q.step(10, function()
    if not S.rs then return end
    local w = RT.ww()
    local sw, sh, sl, st = ZeD.screenOf(w)
    local want = sl + math.floor(sw / 2) + T.px(5)
    Q.check(math.abs(w:getX() - want) <= 1 and w._activeTab == "loot", "Reset both windows: the World window is back in the spread (left edge mid-screen plus 5 px), on Loot",
        "x " .. w:getX() .. " (want " .. want .. "), tab " .. tostring(w._activeTab))
    RT.bounds(Q, "after Reset both windows")
    resetSettle()
end)
Q.waitFor(2, 300, function() return settled("c", "loot") end, function() end)

-- ===================================================================== 8. resize (FEATURE_MAP "Resize (inventory width kept)")
-- The right edge dragged as the window's own resize does it (_startResize, _resizeStep from the pointer, _stopResize),
-- the pointer where the drag would leave it: narrower, then past the half-screen cap, then back.
function X.drag(w, newW)
    local ok, e = X.withMouse(w:getAbsoluteX() + newW, w:getAbsoluteY() + w:getHeight(), function()
        w:_startResize("e")
        w:_resizeStep()
    end)
    pcall(function() w:_stopResize() end)
    if not ok then S.dragErr = tostring(e) end
    return ok
end
Q.step(5, function()
    local w = RT.cw()
    S.dragErr = nil
    S.rz = { w0 = w:getWidth(), base0 = w._baseInvW, maxW = w._maxWinW }
    X.drag(w, S.rz.w0 - T.px(40))
end)
Q.step(15, function()
    local w = RT.cw()
    local inv = w:getWidth() - T.px(36) - T.px(36)
    Q.check(S.dragErr == nil and math.abs(w:getWidth() - (S.rz.w0 - T.px(40))) <= 1 and type(w._baseInvW) == "number"
        and math.abs(w._baseInvW * (T.scale or 1) - inv) <= 1,
        "Resize: the edge dragged 40 units in, the window follows and keeps the inventory's new width",
        S.rz.w0 .. " -> " .. w:getWidth() .. ", inventory " .. tostring(S.rz.base0) .. " -> " .. tostring(w._baseInvW) .. (S.dragErr and (", error " .. S.dragErr) or ""))
    X.drag(w, (S.rz.maxW or w:getWidth()) + T.px(200))
end)
Q.step(15, function()
    local w = RT.cw()
    local cap = w._maxWinW or S.rz.maxW or 0
    Q.check(w:getWidth() <= cap + 1, "Resize: dragged past it, the window stops at the half-screen cap", w:getWidth() .. " (cap " .. cap .. ")")
    X.drag(w, S.rz.w0)
end)
Q.step(15, function()
    local w = RT.cw()
    Q.check(math.abs(w:getWidth() - S.rz.w0) <= 1, "Resize: dragged back, the window is its old width", w:getWidth() .. " (was " .. S.rz.w0 .. ")")
    if S.rz.base0 then w._baseInvW = S.rz.base0 end
    RT.bounds(Q, "after the resize")
end)

-- ===================================================================== 9. the pair: the layout kept, the game's pages, force close, paused
-- (FEATURE_MAP: "Layout kept per character", "Vanilla pages hidden from first frame", "Force close (safe mode)",
-- "Open alone while paused")
function X.vanillaCheck(label)
    local vi, vl = nil, nil
    pcall(function() vi = getPlayerInventory(pn):getIsVisible() end)
    pcall(function() vl = getPlayerLoot(pn):getIsVisible() end)
    Q.check(vi == false and vl == false, "The game's inventory and loot pages stay hidden (" .. label .. ")", "inventory " .. tostring(vi) .. ", loot " .. tostring(vl))
end
X.tabStep("c", "skills")
Q.step(5, function() S.lk = S.tabIn; if S.lk then toggle() end end)
Q.waitFor(5, 300, function() return (not S.lk) or bothShut() end, function(ok)
    if not S.lk then return end
    local cs = nil
    pcall(function() cs = RT.p:getModData().ZeD_WinState.char end)
    local miss = {}
    for _, f in ipairs({ "x", "y", "w", "h", "anchorRightEdge" }) do if type(cs and cs[f]) ~= "number" then miss[#miss + 1] = f end end
    Q.check(ok and cs ~= nil and #miss == 0 and cs.activeTab == "skills" and cs.drawerMode == "tab" and cs.drawerOpen == true,
        "Layout kept: closed on Skills, the character keeps the window's place and tab",
        cs and ("tab " .. tostring(cs.activeTab) .. ", drawer " .. tostring(cs.drawerMode) .. " " .. tostring(cs.drawerOpen) .. ((#miss > 0) and (", missing " .. table.concat(miss, ", ")) or "")) or "no ZeD_WinState.char")
    X.vanillaCheck("the pair closed")
    toggle()
end)
Q.waitFor(5, 300, bothOpen, function(ok)
    if not S.lk then return end
    local w = RT.cw()
    Q.check(ok and w ~= nil and w._activeTab == "skills", "Layout kept: opened again, the Character window is back on Skills", "tab " .. tostring(w and w._activeTab))
    X.vanillaCheck("the pair open")
    pinAll()
end)
X.loot("c")
Q.step(5, function()
    local okf = pcall(ZeD_WorldWindow.forceClose, pn)
    Q.check(okf and RT.ww() == nil and not worldOpen(), "Force close (safe mode's hand-back): the World window is gone", "window " .. tostring(RT.ww() ~= nil))
    toggle()   -- (the Character window open alone: the inventory key's action opens the World window again)
end)
Q.waitFor(5, 300, bothOpen, function(ok)
    Q.check(ok, "Force close: the inventory key's action opens the World window again")
    pinAll()
end)
Q.step(5, function() RT.pairShut() end)
Q.waitFor(5, 300, bothShut, function(ok)
    S.pz = ok
    if not ok then Q.check(false, "Paused: the pair shuts first"); return end
    pcall(setGameSpeed, 0)
end)
Q.step(5, function()
    if not S.pz then return end
    if getGameSpeed() > 0 then S.pz = false; Q.skip("Paused: the Character window alone", "setGameSpeed(0) did not pause the game"); return end
    S.tOk = toggle()
end)
Q.waitFor(3, 300, function() return (not S.pz) or RT.isOpen() end, function(ok)
    if not S.pz then return end
    Q.check(ok and S.tOk and not worldOpen(), "Paused: the inventory key's action opens the Character window alone",
        "Character " .. tostring(RT.isOpen()) .. ", World " .. tostring(worldOpen()))
    RT.bounds(Q, "paused, the Character window alone")
    toggle()
end)
Q.waitFor(3, 300, function() return (not S.pz) or bothShut() end, function(ok)
    if S.pz then Q.check(ok, "Paused: the key again closes it") end
    pcall(setGameSpeed, (S.speed and S.speed > 0) and S.speed or 1)
end)
Q.step(10, function() toggle() end)
Q.waitFor(5, 300, bothOpen, function(ok)
    if not ok then Q.check(false, "the pair opens again after the paused checks") end
    pinAll()
end)

-- ===================================================================== 4. the pad's Y (FocusManager's own Y tap and hold)
Q.step(5, function()
    S.padOk = RT.focus() ~= nil and RT.focus().qaButton ~= nil and ZeD.Input.Detector ~= nil
    if not S.padOk then return end
    pcall(function() S.lockWas = RT.p:getModData().ZeD_Gamepad and RT.p:getModData().ZeD_Gamepad.inputModeLock end)
    pcall(ZeD.Input.Detector.setLockedMode, "gamepad")
    pcall(RT.focus().releaseFocus, pn)
end)
Q.step(20, function() if S.padOk then RT.pairShut() end end)
Q.waitFor(5, 300, function() return (not S.padOk) or bothShut() end, function(ok)
    if not S.padOk then Q.skip("the pad's Y", "FocusManager has no QA button hook (Focus.qaButton)"); return end
    Q.check(ok, "pad: before Y, both windows are closed")
end)
yTap()
Q.waitFor(2, 300, function() return (not S.padOk) or bothOpen() end, function(ok)
    if S.padOk then Q.check(ok, "pad: a tap of Y opens both windows", "Character " .. tostring(RT.isOpen()) .. ", World " .. tostring(worldOpen())) end
end)
Q.step(20, function() if S.padOk then RT.bounds(Q, "opened by the pad") end end)
yTap()
-- (Nov 22 2026, KISS #25, the director's pick: a tap of Y closes both, as the game's Y puts its inventory away. Until
-- K3 (0b366177e) the second tap rolled both up to two bars that only a hold cleared, and this check read rolledBoth.)
Q.waitFor(2, 300, function() return (not S.padOk) or bothShut() end, function(ok)
    if S.padOk then
        Q.check(ok and not rolledBoth(), "pad: a second tap of Y closes both windows (KISS #25)",
            "Character " .. tostring(RT.isOpen()) .. ", World " .. tostring(worldOpen()) .. ", rolled " .. tostring(rolledBoth()))
    end
end)
yTap()
Q.waitFor(2, 300, function() return (not S.padOk) or (bothOpen() and not RT.focus().isRolled(RT.cw()) and not RT.focus().isRolled(RT.ww())) end, function(ok)
    if S.padOk then Q.check(ok, "pad: a third tap of Y opens both windows again, neither rolled") end
end)
-- a hold past the hold time (gp.holdMs, 400 ms) closes the pair
Q.step(10, function() if S.padOk then yDown() end end)
Q.waitFor(2, 900, function() return (not S.padOk) or bothShut() end, function(ok)
    RT.pad("Y", false)
    if S.padOk then Q.check(ok, "pad: holding Y closes both windows", "Character " .. tostring(RT.isOpen()) .. ", World " .. tostring(worldOpen())) end
end)
Q.step(4, function() RT.pad("Y", nil) end)

-- ===================================================================== 10. the pad's wheels and the Controller map
-- (Nov 18 2026, the FEATURE_MAP ledger: "Same direction or B closes; another direction swaps", "Assign a chord from an
-- open wheel", "Controller map closes"). The input mode is still locked to the pad (section 4). The Left wheel is
-- opened the way the game opens it (ISDPadWheels.onDisplayLeft), the gesture set to Tap (D.qaSettings, as rt_pad
-- sets it), and the presses go to the open wheel's own onJoypadDown (ZeD's wrap of ISRadialMenu's).
function X.wheelsShut()
    local D = ZeD.DpadWheels
    if not D then return end
    pcall(D.close, pn)
    D.state[pn] = nil
    for _, m in ipairs({ getPlayerRadialMenu(pn), getPlayerBackButtonWheel(pn) }) do
        if m and m:isReallyVisible() then pcall(m.undisplay, m) end
    end
    if ZeD.Wheel then ZeD.Wheel.qaPoint = nil end
end
function X.wheelOpen(dir)
    local fn = ({ left = "onDisplayLeft", right = "onDisplayRight" })[dir]
    pcall(ISDPadWheels[fn], { player = pn })
    local st = ZeD.DpadWheels.state[pn]
    return st ~= nil and st.dir == dir and st.menu ~= nil
end
function X.wheelPress(button)
    local st = ZeD.DpadWheels.state[pn]
    local m = st and st.menu
    if m then pcall(m.onJoypadDown, m, button, { player = pn }) end
end
function X.wheelStep(fn)
    Q.step(5, function()
        if not S.wh then return end
        X.wheelsShut()
        S.whOpen = X.wheelOpen("left")
        if not S.whOpen then Q.check(false, "wheels: D-pad Left opens the Character wheel for the next press") end
    end)
    Q.waitMs(400)   -- (past the wheel's open debounce, D.tune.OPEN_DEBOUNCE_MS: the press that opened it is ignored)
    Q.step(2, function() if S.wh and S.whOpen then fn() end end)
end
Q.step(5, function()
    local D = ZeD.DpadWheels
    S.wh = S.padOk and D ~= nil and D.state ~= nil and ISDPadWheels ~= nil and ISDPadWheels.onDisplayLeft ~= nil and ZeD.QuickChords ~= nil
    if not S.wh then Q.skip("the pad's wheels", "no D-pad wheels or no pad hook here"); return end
    S.whBack = true
    S.whSettings = D.qaSettings
    D.qaSettings = { open = "tap", commit = "flick", toggle = false, deadZone = 0.35 }
    if D.qaStick then pcall(D.qaStick, pn, 0, 0) end
    pcall(RT.focus().releaseFocus, pn)
end)
X.wheelStep(function()
    X.wheelPress(Joypad.DPadLeft)
    Q.check(ZeD.DpadWheels.state[pn] == nil, "wheels: the same direction again (D-pad Left) closes the wheel")
end)
X.wheelStep(function()
    X.wheelPress(Joypad.BButton)
    Q.check(ZeD.DpadWheels.state[pn] == nil, "wheels: B on the wheel's top level closes it")
end)
X.wheelStep(function()
    X.wheelPress(Joypad.DPadRight)
    local st = ZeD.DpadWheels.state[pn]
    Q.check(st ~= nil and st.dir == "right" and st.menu ~= nil and st.menu:isReallyVisible(), "wheels: another direction (D-pad Right) swaps to that wheel",
        "dir " .. tostring(st and st.dir))
    RT.bounds(Q, "the World wheel, swapped to")
end)
-- the chord: LB held, then A, on the pointed slice puts it on LB + A; the wheel stays open. LB + A put back after.
X.wheelStep(function()
    local D, Qc = ZeD.DpadWheels, ZeD.QuickChords
    local st = D.state[pn]
    local i, e = nil, nil
    for k, x in ipairs(st.path[1].entries or {}) do
        if not i and not x.off and D.pathOf(st, k, x) then i, e = k, x end
    end
    if not i then Q.check(false, "chord: the Left wheel has a slice to put on a chord"); return end
    S.chord = { def = Qc.isDefault("LB+A") }
    S.chord.path, S.chord.words = Qc.get("LB+A")
    local m = st.menu
    ZeD.Wheel.qaPoint = i
    m._zedPoint = i
    X.wheelPress(Joypad.LBumper)
    X.wheelPress(Joypad.AButton)
    local got = Qc.get("LB+A")
    local want = D.pathOf(st, i, e)
    Q.check(got ~= nil and got == want and D.state[pn] ~= nil and m:isReallyVisible(),
        "chord: LB held and A on the pointed slice puts it on LB + A, the wheel stays open", tostring(got) .. " (want " .. tostring(want) .. ")")
    X.chordBack()
end)
function X.chordBack()
    local c, Qc = S.chord, ZeD.QuickChords
    if not c then return end
    S.chord = nil
    if c.def then pcall(Qc.reset, "LB+A") else pcall(Qc.set, "LB+A", c.path, c.words) end
end
Q.step(3, function()
    if not S.wh then return end
    X.wheelsShut()
    local D = ZeD.DpadWheels
    D.qaSettings = S.whSettings
    if D.qaStick then pcall(D.qaStick, pn, nil) end
    S.whBack = nil
end)
-- the Controller map: B closes it (only B: A does nothing), and it lets go of the pad
Q.step(5, function()
    S.cm = nil
    if not S.padOk then return end
    local CM = ZeD.ControllerMap
    if not (CM and CM.open) then Q.check(false, "Controller map: ZeD.ControllerMap is loaded"); return end
    pcall(function() S.cm = CM.open(pn) end)
end)
Q.step(10, function()
    local cm = S.cm
    if not cm then return end
    if not Q.check(cm:isReallyVisible(), "Controller map: it opens") then return end
    RT.bounds(Q, "the Controller map")
    pcall(cm.onJoypadDown, cm, Joypad.AButton)
    local afterA = cm:isReallyVisible()
    pcall(cm.onJoypadDown, cm, Joypad.BButton)
    local jd = JoypadState and JoypadState.players and JoypadState.players[pn + 1]
    local held = jd ~= nil and jd.focus == cm
    Q.check(afterA and not cm:isReallyVisible() and not held, "Controller map: B closes it (A does not) and it lets go of the pad",
        "after A " .. tostring(afterA) .. ", after B " .. tostring(cm:isReallyVisible()) .. ", holds the pad " .. tostring(held))
    pcall(ZeD.ControllerMap.close, pn)
    S.cm = nil
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    RT.pad("Y", nil)
    -- (section 10, if the run jumped here: the chord, the wheel's gesture settings, the wheels, the Controller map)
    X.chordBack()
    if S.whBack then
        X.wheelsShut()
        ZeD.DpadWheels.qaSettings = S.whSettings
        if ZeD.DpadWheels.qaStick then pcall(ZeD.DpadWheels.qaStick, pn, nil) end
        S.whBack = nil
    end
    if S.cm then pcall(ZeD.ControllerMap.close, pn); S.cm = nil end
    if S.padOk then
        pcall(ZeD.Input.Detector.setLockedMode, nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then pcall(ZeD.Input.Detector.setLockedMode, S.lockWas) end
    end
    pcall(function() RT.focus().releaseFocus(pn) end)
    -- the halves' pins as they were (the saved table; the open windows below read it again)
    pcall(function()
        local md = RT.p:getModData()
        md.ZeD_WinPinned = md.ZeD_WinPinned or {}
        for _, k in ipairs(PIN_KEYS) do md.ZeD_WinPinned[k] = S.pins[k] end
    end)
    for _, w in ipairs({ RT.cw(), RT.ww() }) do
        if w and w._rolled and ZeD.Curtain then pcall(ZeD.Curtain.finishUnroll, w) end
    end
    -- the menus shut, the game's speed (the paused checks), the Equip view, the craft pins, the saved places file
    pcall(function() if ZeD.WindowMenu.current then ZeD.WindowMenu.current:close() end end)
    if S.speed and S.speed > 0 and getGameSpeed() == 0 then pcall(setGameSpeed, S.speed) end
    pcall(function() if S.eqView0 and ZeD.EquipDoll.view() ~= S.eqView0 then ZeD.EquipDoll.setView(S.eqView0) end end)
    if S.pin then pcall(function() RT.p:getModData().ZeD_CraftPins = X.copy(S.craftPins0) end) end
    if S.wpTouched and S.places0 then
        pcall(function()
            local WP = ZeD.WindowPlaces
            local pl = WP.load()
            pl.char, pl.world = X.copy(S.places0.char), X.copy(S.places0.world)
            WP.flush()
        end)
    end
    if S.wasOpen and not RT.isOpen() then toggle() end
    if (not S.wasOpen) and RT.isOpen() then RT.pairShut() end
end)
Q.waitFor(10, 300, function() return S.wasOpen == bothOpen() or ((not S.wasOpen) and bothShut()) end, function()
    if not S.wasOpen then
        -- shut as found: the layout the character keeps, as it was (the checks' closes and resets wrote it)
        pcall(function()
            local md = RT.p:getModData()
            if S.winState and S.winState.had then
                md.ZeD_WinState = md.ZeD_WinState or {}
                md.ZeD_WinState.char, md.ZeD_WinState.world = X.copy(S.winState.char), X.copy(S.winState.world)
            elseif S.winState then
                md.ZeD_WinState = nil
            end
        end)
        return
    end
    local c, w = RT.cw(), RT.ww()
    -- the pins back on the live windows
    if c and c._halves and ZeD.Halves then
        pcall(ZeD.Halves.setPin, c, "inv", S.pins.charInv == true); pcall(ZeD.Halves.setPin, c, "drawer", S.pins.charTabs == true)
    end
    if w and w._halves and ZeD.Halves then
        pcall(ZeD.Halves.setPin, w, "inv", S.pins.worldInv == true); pcall(ZeD.Halves.setPin, w, "drawer", S.pins.worldTabs == true)
    end
    if ZEDQA_LAYOUT_BACK and S.snap then ZEDQA_LAYOUT_BACK(S.snap, "rt_win") end
    -- each window's own accent (the reset clears it)
    c, w = RT.cw(), RT.ww()
    if c then c._accentKey = S.accC0; pcall(ZeD.Settings.syncWindowAccent, c) end
    if w then w._accentKey = S.accW0; pcall(ZeD.Settings.syncWindowAccent, w) end
end)
Q.step(30, function()
    if not S.wasOpen then return end
    if S.tabC0 and S.tabC0 ~= "loot" then RT.charTab(S.tabC0) end
    if S.tabW0 and S.tabW0 ~= "loot" then RT.worldTab(S.tabW0) end
end)
Q.step(60, function()
    if S.speed == 0 then pcall(setGameSpeed, 0) end
    if S.wasOpen then
        local c, w = geo(RT.cw()), geo(RT.ww())
        Q.check(sameGeo(c, S.geoC, 1) and sameGeo(w, S.geoW, 1), "put back: both windows are where and as big as they were",
            "Character " .. gs(S.geoC) .. " -> " .. gs(c) .. ", World " .. gs(S.geoW) .. " -> " .. gs(w))
    else
        Q.check(bothShut(), "put back: the pair is shut, as found")
    end
end)
Q.start()
