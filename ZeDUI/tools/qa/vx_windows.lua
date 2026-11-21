-- ZeDUI/tools/qa/vx_windows.lua  (Nov 21 2026, QA): the in-game proof of Build's fixes for the code sweep's window
-- findings W6 W7 W8 W9 W10 (W45 is W7 found twice). Findings: ZeDUI/qa/audits/2026-11-21_beast_code_sweep.md.
-- Build's fix: commit 58c20c461. Built on rt_kit.lua (the global RT), run after zedqa_prelude.lua. grep "ZEDQA vx_win".
--
-- Each check says what the old code showed. Every one is made the way the player meets it:
--   W6   The World window made taller, rolled up (as the hover rolls it), then "Reset both windows" from the
--        Character window's box menu, then the window brought down as the next hover does. Its height must be the
--        default, and so must the height the kept layout writes next. Old code: the window stayed rolled through the
--        reset, came back at the old tall height, and that height was saved again.
--   W7   Two bottles of one kind with different fill. Bottle A pinned from its own right-click menu, A put on the
--        ground at the character's feet, some frames drawn. The pin must still be A's (nothing shown while A is
--        down), bottle B's menu must still say Pin, and A picked up again shows A's fill. Old code: the pin moved to
--        B for good. Also: a pin whose id is unknown (a save loaded with new ids) takes a bottle no other pin holds.
--        Old code: it took the first bottle, the one already pinned.
--   W10  Three pins (a skill, a bottle, a weapon) with the Character window drawing. Counted over 120 title bar
--        asks: how many of a pin's forms were built (ZeD.tr with the pins' own keys, which only ZeD_Pins.lua asks
--        for) and how many of the title bar's pin entries were built anew. The fix builds 3 forms for an entry
--        built anew and none otherwise, so none while nothing changes (old code: 9 for every ask, about 1080, and
--        new entries every ask); the bottle's fill changed: that pin's 3 forms; 1000 asks in a row: none (old code:
--        9000). The time of the 1000 asks is printed. (Counted against the entries built anew, so an XP tick on the
--        pinned skill in that time does not fail the check for the wrong reason.)
--   W8   A bag viewed alone (a click on its button in the Character strip, on a tab), then the inventory side stops
--        drawing: the Skills drawer over the whole window where the screen is that small, else the side rolled up
--        under its rod (the halves' own roll when the pointer leaves an unpinned side: the common way). The title
--        bar's load entries are counted: one. Old code: two, the first frozen.
--   W9   The real carry needs the character to die and a new one to be made: SKIP (a hand test, said in the line).
--        Checked instead: the carry's own code, the ZeD._winStateCarry block read from ZeD_CharacterWindow.lua as
--        the game loaded it and run in a closed environment (setfenv) on stand-in characters: its death and create
--        listeners are caught, never added to the game's events, and it cannot see the real character, the real
--        carry or any game function. Old code: the layout was carried, the pins were not.
-- Put back (also when a step throws or the time runs out): ZeD.tr and ZeD.Pins.stats as they were, the bottle off
-- the ground, the character's own pins, the bag view, the rolled side, the bag worn for the check, the windows'
-- layout, pins and accents, the pair open or shut as found, everything given taken back (RT.takeBack), then god
-- mode and invincible as found. Nothing here should hurt the character (no fight, fall, car or fire; the only risk
-- is the weight of two axes, two bottles and a bag), but nothing may: god mode and invincible are on for the run,
-- and he is healed (RestoreToFullHealth, no argument) only if his health dropped. No file is written.
local Q = RT.make("vx_win")
Q.maxMs = 300000    -- five minutes, then the put-back
local pn = RT.pn
local p = RT.p
local T = ZeD.T
local S = { st = {}, ground = {} }
local X = {}

-- ===================================================================== helpers
function X.geo(w)
    if not w then return nil end
    return { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() }
end
function X.gs(g) return g and string.format("%d,%d %dx%d", g.x, g.y, g.w, g.h) or "none" end
function X.sameGeo(a, b, slack)
    if not (a and b) then return false end
    return math.abs(a.x - b.x) <= slack and math.abs(a.y - b.y) <= slack and math.abs(a.w - b.w) <= slack and math.abs(a.h - b.h) <= slack
end
function X.copy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for a, b in pairs(t) do o[a] = X.copy(b) end
    return o
end
function X.worldOpen() local o = false; pcall(function() o = ZeD_WorldWindow.isOpen(pn) end); return o end
function X.bothOpen()
    local c, w = RT.cw(), RT.ww()
    return RT.isOpen() and X.worldOpen() and c ~= nil and w ~= nil and c:isVisible() and w:isVisible()
end
function X.bothShut() return (not RT.isOpen()) and (not X.worldOpen()) end
function X.has(text, part) return type(text) == "string" and type(part) == "string" and string.find(text, part, 1, true) ~= nil end
-- a press the way the engine delivers one: inside the element's update, followed by its onResize (rt_windows.lua)
function X.viaUpdate(el, fn)
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
-- true once the Character window shows tab id and its drawer has held one width for 15 frames
function X.settled(id)
    local w = RT.cw()
    if not w then return false end
    local e = math.floor(w._drawerEffW or 0)
    if e == S.st.lastE then S.st.same = (S.st.same or 0) + 1 else S.st.same, S.st.lastE = 0, e end
    return w._activeTab == id and S.st.same >= 15
end
function X.resetSettle() S.st.same, S.st.lastE = 0, nil end
function X.pinAll()
    for _, w in ipairs({ RT.cw(), RT.ww() }) do
        if w and w._halves and ZeD.Halves and ZeD.Halves.setPin then pcall(ZeD.Halves.setPin, w, nil, true) end
    end
end
-- a bottle's fill set to a share of its capacity; returns the amount as the pin writes it ("0.3")
function X.setFill(it, share)
    local out = nil
    pcall(function()
        local fc = it:getFluidContainer()
        fc:Empty()
        fc:addFluid(Fluid.Water, fc:getCapacity() * share)
        out = string.format("%.1f", fc:getAmount())
    end)
    return out
end
-- a carried thing put on the ground at the character's feet, as a drop does
function X.putDown(it)
    local sq = p:getCurrentSquare()
    if not sq then return false end
    local ok = pcall(function()
        p:getInventory():Remove(it)
        sq:AddWorldInventoryItem(it, 0.5, 0.5, 0)
    end)
    local wi = nil
    pcall(function() wi = it:getWorldItem() end)
    if ok and wi then S.ground[#S.ground + 1] = { sq = sq, it = it } end
    return ok and wi ~= nil
end
-- a thing taken off the ground (rt_hud.lua's way); true when it is off
function X.lift(it)
    for i, g in ipairs(S.ground) do
        if g.it == it then
            pcall(function()
                local wi = it:getWorldItem()
                if wi then
                    g.sq:transmitRemoveItemFromSquare(wi)
                    if it:getWorldItem() then wi:removeFromWorld(); wi:removeFromSquare(); wi:setSquare(nil) end
                end
            end)
            pcall(function() it:setWorldItem(nil) end)
            table.remove(S.ground, i)
            return true
        end
    end
    return false
end
function X.carried(it)
    local r = nil
    pcall(function() r = p:getInventory():getItemWithIDRecursiv(it:getID()) end)
    return r ~= nil
end
-- the right-click menu's row for a carried thing (ZeD.Pins.onFillInventory, the game's menu event's listener, with a
-- stand-in menu): its words (Pin to title bar, or Unpin) and the function the row runs when it is picked
function X.menu(it)
    local name, fire = nil, nil
    local ctx = { addOption = function(self, n, target, f)
        if name == nil then name, fire = tostring(n), f end
        return {}
    end }
    pcall(ZeD.Pins.onFillInventory, pn, ctx, { it })
    return name, fire
end
function X.menuWord(it) local n = X.menu(it); return n end
-- pinned from its own right-click menu, as the player pins it: true when the row said Pin and ran
function X.pinByMenu(it)
    local name, fire = X.menu(it)
    if not (fire and name == ZeD.tr("UI_ZeD_Pin_Pin")) then return false end
    return pcall(fire) and true or false
end
-- the pins' own phrase keys (only ZeD_Pins.lua asks for them): one ZeD.tr with one of them is one form built
X.PINKEYS = { UI_ZeD_Char_PinMax = true, UI_ZeD_Char_PinLevel = true, UI_ZeD_Pin_Of = true, UI_ZeD_Pin_Litres = true, UI_ZeD_Pin_Pct = true }
function X.wrap()
    if S.trOrig then return end
    local cnt = { tr = 0, stats = 0 }
    S.cnt = cnt
    local trOrig, stOrig, keys = ZeD.tr, ZeD.Pins.stats, X.PINKEYS
    S.trOrig, S.stOrig = trOrig, stOrig
    S.trWas, S.stWas = trOrig, stOrig
    -- (ZeD.tr fills %1..%4 from four arguments: the wrap passes all four on)
    ZeD.tr = function(key, a1, a2, a3, a4)
        if keys[key] then cnt.tr = cnt.tr + 1 end
        return trOrig(key, a1, a2, a3, a4)
    end
    ZeD.Pins.stats = function(pl)
        cnt.stats = cnt.stats + 1
        return stOrig(pl)
    end
end
function X.unwrap()
    if S.trOrig then ZeD.tr = S.trOrig; S.trOrig = nil end
    if S.stOrig then ZeD.Pins.stats = S.stOrig; S.stOrig = nil end
end
-- how many of the first n entries are other tables than before (built anew), and which (1 = the oldest pin)
function X.rebuilt(before, now, n)
    local k, which = 0, {}
    for i = 1, n do
        if (now and now[i]) ~= before[i] then k = k + 1; which[#which + 1] = tostring(i) end
    end
    return k, (#which > 0) and table.concat(which, ",") or "none"
end
-- the title bar's pin entries as the last ask handed them over (the pins come first in titleStats, oldest first)
function X.barPins(win)
    local t, out = win and win.titleStats or {}, {}
    for i = 1, 3 do out[i] = t[i] end
    return out
end
-- the title bar's entries with no status mark (the load is the only one): how many, and the last one's words
function X.loads(win)
    local n, last = 0, nil
    for _, st in ipairs(win.titleStats or {}) do
        if st.noMark then n = n + 1; last = st.text end
    end
    return n, last
end
function X.loadNow()
    local t = nil
    pcall(function() t = ZeD.Atoms.loadText(p:getInventory():getCapacityWeight(), p:getMaxWeight()) end)
    return t
end
-- a bag's button on the Character strip pressed and let go (the strip's own mouse handlers; they read the zone
-- from the x, y given, not from the pointer)
function X.clickBag(win, idx)
    local strip = win._containerStrip
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "cnt:" .. idx then
            pcall(strip.onMouseDown, strip, z.x + 2, z.y + 2)
            pcall(strip.onMouseUp, strip, z.x + 2, z.y + 2)
            return true
        end
    end
    return false
end
function X.bagIdx(win)
    for i, c in ipairs(win and win._containers or {}) do
        if not c.isMain then return i end
    end
    return nil
end
-- the Character window's list back on the main inventory, its side down
function X.viewMain()
    local w = RT.cw()
    if not w then return end
    pcall(function() if w._rolled then ZeD.Curtain.finishUnroll(w) end end)
    pcall(function()
        if w._viewedContainer ~= nil then
            w._viewedContainer = nil
            w._activeContainer = 1
            w._mainVisible = true
            local c = w._contentPanel
            if c and w._containers and w._containers[1] then
                c._inventory = w._containers[1].inventory
                c._selectedItems = {}
                c._lastClickedItem = nil
            end
        end
    end)
end
function X.pinsList() return p:getModData().ZeD_Pins or {} end
-- W9: the carry block of ZeD_CharacterWindow.lua as the game loaded it, read from the mod's own file
function X.carrySource()
    local r = nil
    pcall(function() r = getModFileReader("ZeD_UI", "media/lua/client/ZeD/ZeD_CharacterWindow.lua", false) end)
    if not r then return nil, "ZeD_CharacterWindow.lua could not be read in game" end
    local lines, on, done = {}, false, false
    pcall(function()
        local l = r:readLine()
        while l and not done do
            if not on and string.find(l, "^if not ZeD%._winStateCarry then") then on = true end
            if on then
                lines[#lines + 1] = l
                if string.find(l, "^end%s*$") then done = true end
            end
            if not done then l = r:readLine() end
        end
    end)
    pcall(function() r:close() end)
    if not done then return nil, on and "the carry block has no end in the file" or "the carry block is not in the file" end
    return table.concat(lines, "\n")
end
-- W9: the block run in an environment of its own (setfenv): stand-in events catch its listeners, getSpecificPlayer
-- hands out stand-in characters (plain tables), and nothing else of the game is in it. Were the environment not
-- taken, the block would meet the real ZeD._winStateCarry and do nothing, and no listener would be caught (a SKIP).
function X.carryRun(src)
    if type(loadstring) ~= "function" or type(setfenv) ~= "function" then return nil, "loadstring or setfenv is not in this game's Lua" end
    local fn, err = loadstring(src, "vx_win W9 carry")
    if not fn then return nil, "the carry block does not load: " .. tostring(err) end
    local R = { caught = {}, players = {} }
    local ev = {
        OnPlayerDeath = { Add = function(f) R.caught.death = f end },
        OnCreatePlayer = { Add = function(f) R.caught.create = f end },
        OnMainMenuEnter = { Add = function(f) R.caught.menu = f end },
    }
    R.env = { ZeD = {}, Events = ev, type = type, pairs = pairs, ipairs = ipairs, pcall = pcall, tostring = tostring,
        tonumber = tonumber, string = string, table = table, math = math, select = select, error = error, print = print,
        getSpecificPlayer = function(n) return R.players[n] end }
    if not pcall(setfenv, fn, R.env) then return nil, "setfenv refused the block" end
    local okRun, e2 = pcall(fn)
    if not okRun then return nil, "the carry block stopped: " .. tostring(e2) end
    if not (R.caught.death and R.caught.create and type(R.env.ZeD._winStateCarry) == "table") then
        return nil, "the block added no death or create listener in its own environment"
    end
    return R
end
-- a stand-in character for the carry: its player number and its modData
function X.standIn(num, md) return { getPlayerNum = function(self) return num end, getModData = function(self) return md end } end
function X.pinText(t)
    if type(t) ~= "table" then return "none" end
    return "charInv " .. tostring(t.charInv) .. " charTabs " .. tostring(t.charTabs) .. " worldInv " .. tostring(t.worldInv) .. " worldTabs " .. tostring(t.worldTabs)
end
function X.allPins(t) return type(t) == "table" and t.charInv == true and t.charTabs == true and t.worldInv == true and t.worldTabs == true end
function X.health() local h = nil; pcall(function() h = p:getBodyDamage():getOverallBodyHealth() end); return h end

-- ===================================================================== 0. the scene
Q.step(2, function()
    if p:isDead() then S.dead = true; Q.check(false, "the character is alive (nothing is run on a dead one)"); return end
    -- god mode and invincible for the whole run, as found at the end
    pcall(function() S.godWas = p:isGodMod() and true or false; S.invWas = p:isInvincible() and true or false end)
    pcall(function() p:setGodMod(true); p:setInvincible(true) end)
    S.hp0 = X.health()
    S.wasOpen = RT.isOpen()
    local md = p:getModData()
    S.winState0 = { had = md.ZeD_WinState ~= nil, v = X.copy(md.ZeD_WinState) }
    -- the character's own pins put aside whole (the same table goes back), the checks work on an empty list
    S.pins0 = ZeD.Pins.list(p)
    md.ZeD_Pins = {}
    S.pinsAside = true
    RT.pairOpen()
end)
Q.waitFor(5, 300, function() return S.dead or X.bothOpen() end, function(ok)
    if S.dead then return end
    if not X.bothOpen() then
        S.dead = true
        Q.check(false, "the scene: both windows open", "Character " .. tostring(RT.isOpen()) .. ", World " .. tostring(X.worldOpen()))
        return
    end
    S.snap = ZEDQA_LAYOUT_SNAP and ZEDQA_LAYOUT_SNAP() or nil
    S.geoC, S.geoW = X.geo(RT.cw()), X.geo(RT.ww())
    S.accC0, S.accW0, S.accRead = RT.cw()._accentKey, RT.ww()._accentKey, true
    X.pinAll()      -- (no half rolls by itself while the script works: the pointer is wherever QA left it)
    Q.say("scene: Character " .. X.gs(S.geoC) .. ", World " .. X.gs(S.geoW) .. ", screen " .. RT.core:getScreenWidth() .. "x" .. RT.core:getScreenHeight()
        .. ", the character's own pins put aside: " .. #S.pins0 .. ", god mode " .. tostring(p:isGodMod()) .. ", invincible " .. tostring(p:isInvincible()))
end)

-- ===================================================================== W6. Reset both windows and a rolled window
Q.step(10, function()
    if S.dead then return end
    local cw, ww = RT.cw(), RT.ww()
    local sw, sh = ZeD.screenOf(pn)
    S.defH = math.min(T.px(420), sh - T.px(80))
    local was = ww:getHeight()
    ww:setHeight(math.min(S.defH + T.px(60), sh - T.px(4)))
    S.tall = ww:getHeight()
    if S.tall < S.defH + T.px(10) then
        Q.check(false, "W6 staging: the World window can be made taller than the default height", "default " .. S.defH .. ", got " .. S.tall)
        return
    end
    -- rolled to its title bar, as the hover rolls it 2 s after the pointer leaves (the halves' own shade: the roll,
    -- the reset and the come-down are one step, so the halves' driver cannot step in between)
    ww:setWindowShaded(true)
    if not ww.windowShaded then
        Q.check(false, "W6 staging: the World window rolls up", "windowShaded " .. tostring(ww.windowShaded))
        return
    end
    local keptH = ww.preShadeHeight
    -- Reset both windows, the row of the Character window's box menu (the pointer is on that window)
    local row = nil
    pcall(function()
        local name = ZeD.tr("UI_ZeD_WinMenu_ResetBoth")
        for _, it in ipairs(ZeD.WindowMenu.build(cw)) do if it.name == name then row = it end end
    end)
    local how, okFire, err = "the menu row", false, nil
    if row and row.onFire then
        okFire, err = pcall(row.onFire)
    else
        how = "ZeD_Window.resetLayout (the menu row was not found)"
        okFire, err = pcall(ZeD_Window.resetLayout, nil, pn)
    end
    S.w6still = ww.windowShaded and true or false
    -- the pointer comes back over the window: it comes down (old code: at the height kept from before the reset)
    if ww.windowShaded then ww:setWindowShaded(false) end
    local h = ww:getHeight()
    S.w6ran = true
    Q.check(okFire and math.abs(h - S.defH) <= 1,
        "W6: Reset both windows gives a rolled World window the default height (old code: it came back at the old tall height)",
        "height before " .. was .. ", made " .. S.tall .. " (kept while rolled: " .. tostring(keptH) .. "), default " .. S.defH
        .. ", after the reset and the hover " .. h .. ", still rolled after the reset " .. tostring(S.w6still) .. ", by " .. how
        .. (err and (", error " .. tostring(err)) or ""))
end)
-- the reset clears the kept layout; the window writes it again within a second (its throttled save): wait for that
Q.waitFor(5, 900, function()
    if S.dead or not S.w6ran then return true end
    local ws = p:getModData().ZeD_WinState
    return ws ~= nil and ws.world ~= nil
end, function(ok)
    if S.dead or not S.w6ran then return end
    local ww = RT.ww()
    local h = ww:getHeight()
    local savedPx = nil
    pcall(function()
        local ws = p:getModData().ZeD_WinState
        local saved = ws and ws.world and ws.world.h or nil
        if saved then savedPx = math.floor(saved * (T.scale or 1) + 0.5) end   -- (kept in design units)
    end)
    Q.check(ok and savedPx ~= nil and math.abs(savedPx - S.defH) <= 2 and math.abs(h - S.defH) <= 1 and not ww.windowShaded,
        "W6: after the reset the World window keeps the default height and the kept layout writes it, not the old one (old code: the tall height saved again)",
        "height " .. h .. ", default " .. S.defH .. ", old tall " .. S.tall .. ", the kept layout's height "
        .. (savedPx and (savedPx .. " px") or "not written") .. ", rolled " .. tostring(ww.windowShaded))
    RT.bounds(Q, "after Reset both windows")
end)

-- ===================================================================== W7 (and W45). a pin stays on its own item
Q.step(5, function()
    if S.dead then return end
    local inv = p:getInventory()
    -- a kind of bottle the character carries none of, so "the first of its kind" is one of the two given here
    local kinds = { "Base.WaterBottle", "Base.PopBottle", "Base.Canteen" }
    local ft = nil
    for _, k in ipairs(kinds) do
        local n = -1
        pcall(function() n = inv:getAllTypeRecurse(k):size() end)
        if n == 0 and not ft then ft = k end
    end
    S.w7own = ft == nil
    ft = ft or kinds[1]
    S.A = RT.give(ft)
    S.B = RT.give(ft)
    if not (S.A and S.B) then Q.check(false, "W7 staging: two bottles of one kind given", ft); return end
    S.fillA, S.fillB = X.setFill(S.A, 0.3), X.setFill(S.B, 0.8)
    local kind = ZeD.Pins.kindOf(S.A)
    if not (S.fillA and S.fillB and S.fillA ~= S.fillB and kind == "fluid") then
        Q.check(false, "W7 staging: the two bottles hold different amounts and can be pinned",
            ft .. ": A " .. tostring(S.fillA) .. ", B " .. tostring(S.fillB) .. ", kind " .. tostring(kind))
        return
    end
    S.idA, S.idB, S.ft = S.A:getID(), S.B:getID(), ft
    -- A pinned from its own right-click menu ("Pin to title bar"), as the player pins it
    S.w7 = X.pinByMenu(S.A) and ZeD.Pins.isPinned(p, "fluid", S.idA)
    if not S.w7 then Q.check(false, "W7 staging: bottle A pins from its right-click menu", "the row \"" .. tostring(X.menuWord(S.A)) .. "\"") end
end)
Q.step(10, function()
    if not S.w7 then return end
    local st = ZeD.Pins.stats(p)
    local txt = st[1] and st[1].text or nil
    local wA, wB = X.menuWord(S.A), X.menuWord(S.B)
    if not (#st == 1 and X.has(txt, S.fillA) and wA == ZeD.tr("UI_ZeD_Pin_Unpin") and wB == ZeD.tr("UI_ZeD_Pin_Pin")) then
        S.w7 = false
        Q.check(false, "W7 staging: bottle A pinned shows A's fill in the title bar, A's menu says Unpin, B's says Pin",
            "pin \"" .. tostring(txt) .. "\" (A holds " .. S.fillA .. ", B " .. S.fillB .. "), A's menu \"" .. tostring(wA) .. "\", B's \"" .. tostring(wB) .. "\"")
        return
    end
    Q.say("W7 scene: " .. S.ft .. ", A " .. S.idA .. " holds " .. S.fillA .. ", B " .. S.idB .. " holds " .. S.fillB .. "; the pin \"" .. tostring(txt) .. "\""
        .. (S.w7own and " (the character carries bottles of this kind already)" or ""))
    -- A goes on the ground at his feet; B stays carried. The title bar asks for the pins every frame from here on.
    S.w7down = X.putDown(S.A) and not X.carried(S.A)
    if not S.w7down then Q.check(false, "W7 staging: bottle A is on the ground and not carried", "carried " .. tostring(X.carried(S.A))) end
end)
Q.step(15, function()
    if not (S.w7 and S.w7down) then return end
    local st = ZeD.Pins.stats(p)
    local e = X.pinsList()[1]
    local nowId = e and e.id or nil
    local txt = st[1] and st[1].text or "nothing"
    Q.check(tostring(nowId) == tostring(S.idA) and #st == 0,
        "W7: with the pinned bottle on the ground the pin is still its own and shows nothing (old code: the pin moved to the other bottle and showed its fill)",
        "the pin's id " .. tostring(nowId) .. " (A " .. S.idA .. ", B " .. S.idB .. "), the title bar shows " .. #st .. " pin(s): " .. tostring(txt))
    local wB = X.menuWord(S.B)
    Q.check(wB == ZeD.tr("UI_ZeD_Pin_Pin") and not ZeD.Pins.isPinned(p, "fluid", S.idB),
        "W7: the other bottle's menu still says Pin (old code: it said Unpin)",
        "B's menu \"" .. tostring(wB) .. "\", B pinned " .. tostring(ZeD.Pins.isPinned(p, "fluid", S.idB)))
    -- A is picked up again
    X.lift(S.A)
    pcall(function() p:getInventory():AddItem(S.A) end)
end)
Q.step(15, function()
    if not (S.w7 and S.w7down) then return end
    local st = ZeD.Pins.stats(p)
    local txt = st[1] and st[1].text or "nothing"
    local wA = X.menuWord(S.A)
    Q.check(X.carried(S.A) and #st == 1 and X.has(txt, S.fillA) and wA == ZeD.tr("UI_ZeD_Pin_Unpin"),
        "W7: picked up again, the pin shows bottle A's fill and A's menu says Unpin (old code: the pin stayed on B, A's menu said Pin)",
        "pin \"" .. tostring(txt) .. "\" (A holds " .. S.fillA .. ", B " .. S.fillB .. "), A's menu \"" .. tostring(wA) .. "\", A carried " .. tostring(X.carried(S.A)))
    -- a pin whose id is not known (a save loaded with new ids): written as the saved record would be, with an id
    -- no carried thing has. It takes a bottle of its kind, and never one another pin already holds. The first
    -- bottle of the kind he carries is the pinned one here, so old code (which took the first) doubled up.
    local inv = p:getInventory()
    local fake = 1999999937
    local taken = nil
    pcall(function() taken = inv:getItemWithIDRecursiv(fake) end)
    if taken then Q.skip("W7: a pin with an unknown id", "the made-up id " .. fake .. " belongs to a carried thing"); return end
    local first = nil
    pcall(function() first = inv:getFirstTypeRecurse(S.ft) end)
    local fid = first and first:getID() or nil
    p:getModData().ZeD_Pins = {}
    local L = X.pinsList()
    local ours = fid ~= nil and (fid == S.idA or fid == S.idB)
    if ours then ZeD.Pins.toggle(p, "fluid", fid, first:getDisplayName()) end
    L[#L + 1] = { k = "fluid", id = fake, name = "QA stale pin", ft = S.ft }
    local st2 = ZeD.Pins.stats(p)
    local stale = L[#L]
    local sid = stale and stale.id or nil
    if not ours then
        Q.skip("W7: a pin with an unknown id never takes a bottle already pinned",
            "the first bottle of this kind he carries is not one of the two given (id " .. tostring(fid) .. ")")
        Q.check(tostring(sid) ~= tostring(fake), "W7: a pin with an unknown id still finds a bottle of its kind (the load fallback is kept)", "it took id " .. tostring(sid))
    else
        local t1, t2 = st2[1] and st2[1].text or nil, st2[2] and st2[2].text or nil
        Q.check(tostring(sid) ~= tostring(fake) and tostring(sid) ~= tostring(fid) and #st2 == 2 and t1 ~= t2,
            "W7: a pin with an unknown id takes a bottle no pin holds (old code: it took the first bottle, already pinned, so two pins showed one bottle)",
            "the pinned bottle is the first of its kind (id " .. tostring(fid) .. "); the unknown pin took id " .. tostring(sid) .. " (A " .. S.idA .. ", B " .. S.idB
            .. "), the title bar shows " .. #st2 .. " pins: \"" .. tostring(t1) .. "\" and \"" .. tostring(t2) .. "\"")
    end
end)

-- ===================================================================== W10. the pins' words are built only on a change
Q.step(5, function()
    if S.dead then return end
    if not (S.A and S.idA and X.carried(S.A)) then
        Q.skip("W10: the pins' words are built only on a change", "it pins W7's bottle A, which is not carried here (W7's staging said why)")
        return
    end
    -- three pins: a skill (a real one: a child of a group, not Fitness or Strength), bottle A, a weapon
    p:getModData().ZeD_Pins = {}
    local skill = nil
    pcall(function()
        for i = 0, PerkFactory.PerkList:size() - 1 do
            local perk = PerkFactory.PerkList:get(i)
            if not skill and perk:getParent() ~= Perks.None and not perk:isPassiv() then
                local name = perk:getName()
                local pd = ZeD.SkillsTab.getPinData(p, name)
                if pd and pd.level < 10 then skill = name end
            end
        end
    end)
    S.axe = RT.give("Base.Axe")
    local kAxe = S.axe and ZeD.Pins.kindOf(S.axe) or nil
    if not (skill and S.axe and kAxe == "cond") then
        Q.check(false, "W10 staging: a skill, a carried bottle and a weapon to pin",
            "skill " .. tostring(skill) .. ", axe kind " .. tostring(kAxe) .. ", bottle carried " .. tostring(X.carried(S.A)))
        return
    end
    -- the skill as the Skills tab's row menu pins it; the bottle and the axe from their own right-click menus
    ZeD.Pins.toggle(p, "skill", skill, skill)
    local okA, okX = X.pinByMenu(S.A), X.pinByMenu(S.axe)
    local L = X.pinsList()
    if not (okA and okX and #L == 3 and L[2] and L[2].k == "fluid") then
        Q.check(false, "W10 staging: the three pins made (the bottle and the axe from their menus)",
            "bottle " .. tostring(okA) .. ", axe " .. tostring(okX) .. ", pins " .. #L)
        return
    end
    S.w10, S.w10skill = true, skill
    -- the Character window's list must be drawing: it is the title bar's side that asks for the pins
    X.viewMain()
    RT.charTab("loot")
end)
Q.step(30, function()
    if not S.w10 then return end
    local cw = RT.cw()
    local st = ZeD.Pins.stats(p)
    local shown = cw._contentPanel ~= nil and cw._contentPanel:isVisible()
    if not (#st == 3 and shown) then
        S.w10 = false
        Q.check(false, "W10 staging: three pins show and the Character window's list draws", #st .. " pins, list drawing " .. tostring(shown))
        return
    end
    S.w10e0 = { st[1], st[2], st[3] }   -- the entries as they stand (what the next ask hands over while nothing changes)
    X.wrap()        -- from here every pin form built and every title bar ask is counted
    Q.say("W10 scene: pins \"" .. tostring(st[1].text) .. "\", \"" .. tostring(st[2].text) .. "\", \"" .. tostring(st[3].text) .. "\"")
end)
Q.waitFor(1, 1200, function() return (not S.w10) or S.cnt.stats >= 120 end, function(ok)
    if not S.w10 then return end
    local asks, built = S.cnt.stats, S.cnt.tr
    local moved, which = X.rebuilt(S.w10e0, X.barPins(RT.cw()), 3)
    Q.check(ok and asks >= 120 and built == 3 * moved,
        "W10: over 120 title bar asks, a pin's words are built only for an entry built anew, so none while nothing changes (old code: 9 forms every ask, about " .. (asks * 9) .. ")",
        asks .. " asks by the title bar, " .. built .. " forms built, entries built anew: " .. moved .. " (" .. which .. ")"
        .. ((moved > 0) and ", a pin's numbers changed in that time" or ""))
    -- the same entry tables handed back
    local a, b = ZeD.Pins.stats(p), ZeD.Pins.stats(p)
    local same = #a == 3 and #b == 3 and a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
    Q.check(same, "W10: two asks in a row hand back the same three entries (old code: three new ones each ask)", #a .. " and " .. #b .. " entries, the same ones " .. tostring(same))
    -- a change: the bottle's fill. Only that pin is built again, and the title bar shows the new amount.
    S.w10e1 = { b[1], b[2], b[3] }
    S.fillA2 = X.setFill(S.A, 0.6)
    S.cnt.tr, S.cnt.stats = 0, 0
end)
Q.waitFor(1, 600, function() return (not S.w10) or S.cnt.stats >= 30 end, function(ok)
    if not S.w10 then return end
    local asks, built = S.cnt.stats, S.cnt.tr
    local cw = RT.cw()
    local now = X.barPins(cw)
    local moved, which = X.rebuilt(S.w10e1, now, 3)
    local bottleNew = now[2] ~= nil and now[2] ~= S.w10e1[2]
    local seen = (now[2] and X.has(now[2].text, S.fillA2)) and now[2].text or nil
    Q.check(ok and bottleNew and built == 3 * moved and seen ~= nil and S.fillA2 ~= S.fillA,
        "W10: the bottle's fill changed: its pin is built again (3 forms) and the title bar shows the new amount (old code: 9 forms every ask, about " .. (asks * 9) .. ")",
        asks .. " asks, " .. built .. " forms built, entries built anew: " .. moved .. " (" .. which .. "; the bottle is 2), fill " .. tostring(S.fillA)
        .. " -> " .. tostring(S.fillA2) .. ", the title bar's pin \"" .. tostring(now[2] and now[2].text) .. "\"")
    -- 1000 asks in a row, timed (the finding's own measure); one ask first takes in any change since the last frame
    ZeD.Pins.stats(p)
    S.cnt.tr, S.cnt.stats = 0, 0
    local t0 = getTimestampMs()
    for i = 1, 1000 do ZeD.Pins.stats(p) end
    local ms = getTimestampMs() - t0
    Q.check(S.cnt.tr == 0, "W10: 1000 asks in a row build no pin's words (old code: 9000 forms)",
        S.cnt.tr .. " forms built, " .. ms .. " ms for the 1000 asks with three pins (" .. ms .. " microseconds each)")
    X.unwrap()
    Q.check(ZeD.tr == S.trWas and ZeD.Pins.stats == S.stWas, "put back: the W10 counters are off (ZeD.tr and ZeD.Pins.stats are the mod's own again)")
end)

-- ===================================================================== W8. the load shows once in the title bar
Q.step(5, function()
    if S.dead then return end
    X.pinAll()
    local cw = RT.cw()
    S.bagI = X.bagIdx(cw)
    if S.bagI then S.bagHow = "a bag he already has on the strip"; return end
    -- no bag on the strip: one is given and worn where that place is free, else held in a free second hand
    local bag = RT.give("Base.Bag_Schoolbag")
    if not bag then S.bagHow = "a school bag could not be given"; return end
    S.bag = bag
    local loc = nil
    pcall(function() loc = bag:getBodyLocation() end)
    if loc == nil or tostring(loc) == "" then pcall(function() loc = bag:canBeEquipped() end) end
    local free = false
    pcall(function() free = loc ~= nil and tostring(loc) ~= "" and p:getWornItem(loc) == nil end)
    if free then
        pcall(function() p:setWornItem(loc, bag) end)
        S.bagHow = "a school bag given and worn"
    elseif p:getSecondaryHandItem() == nil then
        pcall(function() p:setSecondaryHandItem(bag) end)
        S.bagHow = "a school bag given and held in the second hand"
    else
        S.bagHow = "a school bag given, but his back and his second hand are taken"
    end
    pcall(function() cw._containerTimer = 30 end)     -- (the strip reads its bags afresh on the next frame)
end)
Q.waitFor(2, 240, function() return S.dead or X.bagIdx(RT.cw()) ~= nil end, function(ok)
    if S.dead then return end
    S.bagI = X.bagIdx(RT.cw())
    if not S.bagI then Q.skip("W8: the load shows once in the title bar", "no bag could be put on the Character strip (" .. tostring(S.bagHow) .. ")"); return end
    -- a tab other than Loot (on Loot a bag's button opens a column); the list still shows beside its drawer
    local ids = RT.tabs(RT.charStrip())
    local first = nil
    for _, id in ipairs(ids) do if id == "health" then first = id end end
    if not first then for _, id in ipairs(ids) do if id ~= "loot" and id ~= "skills" and not first then first = id end end end
    if not first then for _, id in ipairs(ids) do if id ~= "loot" and not first then first = id end end end
    S.w8tab = first
    if not first then Q.skip("W8: the load shows once in the title bar", "the Character strip has no tab but Loot"); S.bagI = nil; return end
    X.resetSettle()
    RT.charTab(first)
end)
Q.waitFor(5, 600, function() return S.dead or not S.bagI or X.settled(S.w8tab) end, function(ok)
    if S.dead or not S.bagI then return end
    local cw = RT.cw()
    S.bagI = X.bagIdx(cw)
    S.w8click = S.bagI ~= nil and X.clickBag(cw, S.bagI)
end)
Q.step(15, function()
    if S.dead or not S.bagI then return end
    local cw = RT.cw()
    local c = cw._contentPanel
    local n, txt = X.loads(cw)
    local view = cw._containers and cw._containers[cw._viewedContainer or cw._activeContainer]
    local alone = view ~= nil and not view.isMain and #(cw._mcSelected or {}) == 0
    S.w8ready = S.w8click and alone and c ~= nil and c:isVisible() and n == 1
    if not S.w8ready then
        Q.check(false, "W8 staging: a bag viewed alone on the " .. tostring(S.w8tab) .. " tab, the list drawing, the load in the title bar once",
            "bag button pressed " .. tostring(S.w8click) .. ", bag alone " .. tostring(alone) .. ", list drawing " .. tostring(c ~= nil and c:isVisible())
            .. ", load entries " .. n .. " (" .. tostring(S.bagHow) .. ")")
        return
    end
    Q.say("W8 scene: " .. tostring(S.bagHow) .. " viewed alone on " .. tostring(S.w8tab) .. ", the title bar's load \"" .. tostring(txt) .. "\"")
    -- the Skills drawer: on a small screen it takes the whole window and the list stops drawing
    S.w8full = nil
    for _, id in ipairs(RT.tabs(RT.charStrip())) do if id == "skills" then S.w8full = id end end
    if S.w8full and S.w8full ~= S.w8tab then X.resetSettle(); RT.charTab(S.w8full) else S.w8full = S.w8tab end
end)
Q.waitFor(5, 600, function() return S.dead or not S.w8ready or X.settled(S.w8full) end, function(ok)
    if S.dead or not S.w8ready then return end
    local cw = RT.cw()
    local c = cw._contentPanel
    if not c:isVisible() then S.w8how = "the " .. tostring(S.w8full) .. " drawer over the whole window"; return end
    -- a screen this big keeps the list beside the drawer: the side is rolled up under its rod instead (what the
    -- halves do 2 s after the pointer leaves an unpinned side; the same to the title bar: the list stops drawing
    -- with the bag's load entry last in the list)
    local can = false
    pcall(function() can = cw._curtain.canRoll() end)
    if not can then
        S.w8ready = false
        Q.skip("W8: the load shows once in the title bar", "the list still draws beside the " .. tostring(S.w8full) .. " drawer and its side cannot roll here")
        return
    end
    S.w8how = "the inventory side rolled up under its rod (the " .. tostring(S.w8full) .. " drawer leaves the list showing on this screen)"
    S.pressErr = nil
    X.viaUpdate(cw, function(self) ZeD.Curtain.roll(self) end)
end)
Q.waitFor(2, 400, function()
    if S.dead or not S.w8ready then return true end
    local cw = RT.cw()
    return cw._contentPanel ~= nil and not cw._contentPanel:isVisible()
end, function(ok)
    if S.dead or not S.w8ready then return end
    if not ok then
        S.w8ready = false
        Q.check(false, "W8 staging: the list stops drawing", tostring(S.w8how) .. (S.pressErr and (", error " .. S.pressErr) or ""))
    end
end)
Q.step(20, function()
    if S.dead or not S.w8ready then return end
    local cw = RT.cw()
    if cw._contentPanel:isVisible() then
        S.w8ready = false
        Q.check(false, "W8 staging: the list stays hidden for 20 frames", tostring(S.w8how))
        return
    end
    local n, txt = X.loads(cw)
    local now = X.loadNow()
    Q.check(n == 1 and txt == now,
        "W8: a bag viewed alone, then the list hidden: the title bar says the load once (old code: twice, the first copy frozen)",
        n .. " load entries, the last \"" .. tostring(txt) .. "\", the load now \"" .. tostring(now) .. "\", hidden by " .. tostring(S.w8how))
    S.w8txt = txt
    -- the load changes while the list is hidden: a second axe
    S.axe2 = RT.give("Base.Axe")
    -- (a note, not a check of W8: does a pin's number follow while the list is hidden?)
    if S.w10 and S.A and X.carried(S.A) then S.fillA3 = X.setFill(S.A, 0.9) end
end)
Q.step(20, function()
    if S.dead or not S.w8ready then return end
    local cw = RT.cw()
    local n, txt = X.loads(cw)
    local now = X.loadNow()
    Q.check(S.axe2 ~= nil and not cw._contentPanel:isVisible() and n == 1 and txt == now and txt ~= S.w8txt,
        "W8: an axe picked up while the list is hidden: the one load entry follows (old code: two entries, the first still the old weight)",
        n .. " load entries, \"" .. tostring(S.w8txt) .. "\" -> \"" .. tostring(txt) .. "\", the load now \"" .. tostring(now) .. "\"")
    if S.fillA3 then
        local seen, pinTxt = false, ""
        for _, st in ipairs(cw.titleStats or {}) do
            if not st.noMark then
                if X.has(st.text, S.fillA3) then seen = true end
                pinTxt = pinTxt .. (pinTxt ~= "" and "; " or "") .. tostring(st.text)
            end
        end
        Q.say("NOTE (not counted) pins while the list is hidden: the bottle's fill went " .. tostring(S.fillA2) .. " -> " .. S.fillA3
            .. ", the title bar's pins read \"" .. tostring(pinTxt) .. "\" (" .. (seen and "it follows" or "it does NOT follow: the pins freeze while the list is hidden, as the sweep's W8 fix hint said") .. ")")
    end
    RT.bounds(Q, "W8, the list hidden")
end)

-- ===================================================================== W9. window pins over a respawn
Q.step(5, function()
    if S.dead then return end
    Q.skip("W9: window pins carried over a real respawn",
        "it needs the character to die and a new one to be made; the QA character never dies, and the death and create events cannot be fired by hand without the game's own death screen and player data answering them. Hand test: a throwaway character, both windows pinned, die, respawn, open the windows")
    local src, why = X.carrySource()
    local R = nil
    if src then R, why = X.carryRun(src) end
    if not R then Q.skip("W9: the carry's own code gives a respawned character the window pins", why); return end
    local PINS = { charInv = true, charTabs = true, char = true, worldInv = true, worldTabs = true, world = true }
    -- 1. a character who kept a layout and pinned both windows dies; the new one gets both
    local dead1 = { ZeD_WinState = { char = { x = 10, h = 300 }, world = { x = 20, h = 300 } }, ZeD_WinPinned = X.copy(PINS) }
    local new1 = {}
    R.players[0] = X.standIn(0, new1)
    pcall(R.caught.death, X.standIn(0, dead1))
    pcall(R.caught.create, 0)
    local ok1 = X.allPins(new1.ZeD_WinPinned) and new1.ZeD_WinPinned ~= dead1.ZeD_WinPinned and type(new1.ZeD_WinState) == "table"
    -- 2. the pins with no layout kept (the windows never moved): still carried
    local dead2 = { ZeD_WinPinned = X.copy(PINS) }
    local new2 = {}
    R.players[0] = X.standIn(0, new2)
    pcall(R.caught.death, X.standIn(0, dead2))
    pcall(R.caught.create, 0)
    local ok2 = X.allPins(new2.ZeD_WinPinned)
    -- 3. a new character with pins of its own keeps them
    local dead3 = { ZeD_WinState = { char = { x = 10 } }, ZeD_WinPinned = X.copy(PINS) }
    local own = { charInv = false, charTabs = false, char = false }
    local new3 = { ZeD_WinPinned = own }
    R.players[0] = X.standIn(0, new3)
    pcall(R.caught.death, X.standIn(0, dead3))
    pcall(R.caught.create, 0)
    local ok3 = new3.ZeD_WinPinned == own and own.charInv == false
    local stash = R.env.ZeD._winStateCarry.stash
    local left = type(stash) == "table" and stash["pins0"] ~= nil
    Q.check(ok1 and ok2 and ok3 and not left,
        "W9: the carry's own code (read from ZeD_CharacterWindow.lua, run on stand-in characters) gives a respawned character the dead one's window pins (old code: the layout only, the windows came back unpinned)",
        "with a layout: pins " .. X.pinText(new1.ZeD_WinPinned) .. ", layout carried " .. tostring(type(new1.ZeD_WinState) == "table")
        .. "; with no layout: pins " .. X.pinText(new2.ZeD_WinPinned) .. "; a new character's own pins kept " .. tostring(ok3)
        .. "; pins left in the stash " .. tostring(left))
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    X.unwrap()
    -- anything still on the ground comes off it (RT.takeBack then takes the things themselves)
    while #S.ground > 0 do
        local it = S.ground[1].it
        if not X.lift(it) then table.remove(S.ground, 1) end
    end
    -- the character's own pins, the same table
    if S.pinsAside then
        pcall(function() p:getModData().ZeD_Pins = S.pins0 end)
        S.pinsAside = nil
    end
    -- the bag view and the rolled side, then the bag worn for the check
    X.viewMain()
    if S.bag then
        pcall(function() p:removeWornItem(S.bag) end)
        pcall(function() if p:getSecondaryHandItem() == S.bag then p:setSecondaryHandItem(nil) end end)
    end
    for _, w in ipairs({ RT.cw(), RT.ww() }) do
        if w and w._rolled and ZeD.Curtain then pcall(ZeD.Curtain.finishUnroll, w) end
        if w and w.windowShaded then pcall(function() w:setWindowShaded(false) end) end
    end
    if RT.isOpen() then RT.charTab("loot") end
end)
Q.step(20, function()
    if not X.bothOpen() then return end
    if ZEDQA_LAYOUT_BACK and S.snap then ZEDQA_LAYOUT_BACK(S.snap, "vx_win")
    else pcall(ZeD_Window.resetLayout, nil, pn) end
    -- each window's accent as found (only when it was read: an accent never read is left alone)
    if S.accRead then
        local c, w = RT.cw(), RT.ww()
        if c then c._accentKey = S.accC0; pcall(ZeD.Settings.syncWindowAccent, c) end
        if w then w._accentKey = S.accW0; pcall(ZeD.Settings.syncWindowAccent, w) end
    end
end)
Q.step(30, function()
    local md = p:getModData()
    local pinsBack = (not S.pins0) or md.ZeD_Pins == S.pins0
    if S.wasOpen == true and S.geoC then
        local c, w = X.geo(RT.cw()), X.geo(RT.ww())
        Q.check(X.sameGeo(c, S.geoC, 1) and X.sameGeo(w, S.geoW, 1) and pinsBack and #S.ground == 0,
            "put back: both windows are where and as big as they were, his own pins are back, nothing left on the ground",
            "Character " .. X.gs(S.geoC) .. " -> " .. X.gs(c) .. ", World " .. X.gs(S.geoW) .. " -> " .. X.gs(w) .. ", pins back " .. tostring(pinsBack))
    elseif S.wasOpen == false then
        RT.pairShut()      -- (shut as found; a run that never started, wasOpen nil, leaves the windows alone)
    end
end)
Q.waitFor(5, 300, function() return S.wasOpen ~= false or X.bothShut() end, function(ok)
    if S.wasOpen ~= false then return end
    -- shut as found: the layout the character keeps, as it was
    pcall(function()
        local md = p:getModData()
        if S.winState0 and S.winState0.had then md.ZeD_WinState = X.copy(S.winState0.v)
        elseif S.winState0 then md.ZeD_WinState = nil end
    end)
    Q.check(ok and p:getModData().ZeD_Pins == S.pins0 and #S.ground == 0,
        "put back: the pair is shut as found, his own pins are back, nothing left on the ground", "shut " .. tostring(ok))
end)
Q.step(5, function()
    -- the things given taken back now (Q.start's own takeBack then finds none), while god mode is still on
    RT.takeBack()
    -- healed only if his health dropped while the script ran (it should not have), god mode still on
    local hp = X.health()
    if S.hp0 and hp and hp < S.hp0 - 1 then pcall(function() p:getBodyDamage():RestoreToFullHealth() end) end
    if S.godWas ~= nil then
        pcall(function() p:setInvincible(S.invWas and true or false) end)
        pcall(function() p:setGodMod(S.godWas and true or false) end)
    end
    local alive = not p:isDead()
    local hp2 = X.health()
    local whole = hp2 ~= nil and (S.hp0 == nil or hp2 >= S.hp0 - 1)
    Q.check(alive and whole and (S.godWas == nil or (p:isGodMod() == S.godWas and p:isInvincible() == S.invWas)),
        "put back: the character is alive and whole, god mode and invincible as found",
        "alive " .. tostring(alive) .. ", health " .. tostring(S.hp0) .. " -> " .. tostring(hp2) .. ", god " .. tostring(p:isGodMod())
        .. " (was " .. tostring(S.godWas) .. "), invincible " .. tostring(p:isInvincible()) .. " (was " .. tostring(S.invWas) .. ")")
end)
Q.start()
