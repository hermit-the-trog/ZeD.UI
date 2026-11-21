-- ZeDUI/tools/qa/bx_options.lua  (Nov 21 2026, QA; tag bx_opt): the beast-mode stress run of ZeD's options.
-- Built on rt_kit.lua (the global RT); run after zedqa_prelude.lua and rt_kit.lua. grep "ZEDQA bx_opt". No pictures.
-- The scene: both windows open, the Character window on its inventory with an item card open (a pencil given for
-- the run), the HUD showing, the game playing.
-- What it does, as a player with fast hands would:
--   1. THE SWEEP. Every option of PZAPI.ModOptions "ZeD_UI" (every list, tick box and slider) is set to every value
--      it has, live, the way a pick does it (setValue, then the option's own onChange and onChangeApply). After each
--      value: the windows settle (a scale change shuts and reopens them), the value held, ZeD's hand-back state is
--      what the switches say (ZeD.Safe: every hook), the item card is not stale, RT.bounds, and a tab is turned on
--      both windows and checked. After each option: every option back as found, ZeD's state as at the start, no new
--      Lua error, no guarded fault (ZeD.Safe.fault watched, pass-through).
--   2. SAFE MODE. Every screen switch On at once and Off again; the Safe mode option flipped twenty times in one
--      frame and then every frame for forty frames; a trip (the note), a second trip, a screen switched while
--      tripped, the windows asked for while tripped, the option On and Off (which clears the trip); each time ZeD
--      comes back as at the start.
--   3. LITE AND FULL flipped sixteen times two frames apart with tabs turning; then Lite (ZeD.Settings.lite(), the
--      additions on the Vanilla preset) and Full.
--   4. THE KEYBOARD MAP opened and closed ten times in one frame; open: scrolled past both ends, a key cap clicked
--      twice, an action set to wait for its key and answered with Escape (no key changes), closed while waiting,
--      Escape from anywhere twice, the theme and text size changed under it. No binding is ever set.
--   5. OPTIONS MID-PLAY (ZeD's own window from the pause menu): Find typed with a word, capitals, a 1500 letter
--      text, 4000 letters, pattern symbols, spaces; cleared; a row found by its own name, changed (live preview),
--      Back (asks), Escape, Back, Discard; opened and closed five times in one frame. Nothing is applied.
--   6. THE CARD'S ITEM GONE: the pencil is removed while its card shows; the card must let go of it.
-- What it puts back: every ZeD option's value (each one compared with the value read at the start, a check each),
-- the theme, scale and look on screen, the character's copies (ZeD_Theme, ZeD_Gamepad, the windows' accents),
-- ModOptions.ini line for line when anything wrote it, safe mode off and its trip file emptied, the keyboard map
-- shut and the game's keys on, the pause menu shut, the windows where and as they were, the pencil taken back,
-- game speed 1. It never applies Options (the game's options.ini is not written) and never sets a key.
if not (RT and ZeD and ZeD.Settings and ZeD.Safe) then
    print("ZEDQA bx_opt FAIL the kit (rt_kit.lua) or ZeD's settings and safe mode are not loaded")
    print("ZEDQA bx_opt VERDICT FAIL 1")
    print("ZEDQA bx_opt DONE")
    return
end
local Q = RT.make("bx_opt")
Q.maxMs = 400000                     -- (the budget is 8 minutes: the put-back starts before that)
local S = { pn = RT.pn, p = RT.p, bad = {}, faultNew = {}, nFaults = 0, k = 0, nValues = 0, cardSeen = 0, tabTurns = 0, findN = {} }
local H = {}
local St, Sf, MM, Sc, KM = ZeD.Settings, ZeD.Safe, ZeD.MainMenu, ZeD.Scale, ZeD.KeyboardMap

-- ===================================================================== helpers: the game
function H.errs()
    local n = nil
    pcall(function() n = getLuaDebuggerErrorCount() end)
    return n
end
function H.menuUp()
    local up = false
    pcall(function() up = MainScreen.instance ~= nil and MainScreen.instance:isVisible() end)
    return up
end
function H.toggleMenu() pcall(function() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end) end
function H.onScreen(el)
    local ok = false
    pcall(function()
        local W, Hh = getCore():getScreenWidth(), getCore():getScreenHeight()
        local x, y = el:getAbsoluteX(), el:getAbsoluteY()
        ok = x >= -1 and y >= -1 and x + el:getWidth() <= W + 1 and y + el:getHeight() <= Hh + 1
    end)
    return ok
end
function H.readLines(name)
    local t = nil
    pcall(function()
        local r = getFileReader(name, false)
        if not r then return end
        t = {}
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        r:close()
    end)
    return t
end
function H.writeIni(lines)
    if not lines then return false end
    return pcall(function()
        local w = getFileWriter("ModOptions.ini", true, false)
        for _, l in ipairs(lines) do w:write(l .. "\r\n") end
        w:close()
    end) and true or false
end
function H.sameLines(a, b) return a ~= nil and b ~= nil and table.concat(a, "\n") == table.concat(b, "\n") end
function H.copy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = v end
    return o
end
function H.restoreTable(parent, key, snap)
    if snap == nil then parent[key] = nil; return end
    local t = parent[key]
    if type(t) ~= "table" then t = {}; parent[key] = t end
    local drop = {}
    for k in pairs(t) do if snap[k] == nil then drop[#drop + 1] = k end end
    for _, k in ipairs(drop) do t[k] = nil end
    for k, v in pairs(snap) do t[k] = v end
end
function H.odd(n) return n - math.floor(n / 2) * 2 == 1 end
function H.few(list, n)
    local out = {}
    for i = 1, math.min(#list, n or 6) do out[#out + 1] = tostring(list[i]) end
    if #list > #out then out[#out + 1] = "and " .. (#list - #out) .. " more" end
    return table.concat(out, "; ")
end
function H.note(s) if #S.bad < 40 then S.bad[#S.bad + 1] = s end end

-- ===================================================================== helpers: ZeD's options
function H.opts() local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo end
function H.opt(id) local zo = H.opts(); return zo and zo.dict and zo.dict[id] or nil end
function H.get(o)
    local v = nil
    pcall(function() v = o:getValue() end)
    return v
end
function H.val(id) local o = H.opt(id); return o and H.get(o) or nil end
-- the values an option can take: a list's items, a tick box's two, a slider's ends and two steps inside
function H.values(o)
    local out = {}
    if o.type == "combobox" then
        for i = 1, #(o.values or {}) do out[#out + 1] = i end
    elseif o.type == "tickbox" then
        out = { true, false }
    elseif o.type == "slider" and type(o.min) == "number" and type(o.max) == "number" then
        local st = (type(o.step) == "number" and o.step > 0) and o.step or 1
        local steps = math.floor((o.max - o.min) / st)
        out = { o.min, o.max }
        if steps > 1 then out[#out + 1] = o.min + st end
        if steps > 3 then out[#out + 1] = o.min + st * math.floor(steps / 2) end
    end
    return out
end
-- a pick, as the options screen makes one and Apply commits it: the value, the option's own onChange and
-- onChangeApply (the game calls both as option:fn(value)); safe mode's switches read at once
function H.pick(o, v)
    local ok, err = pcall(function()
        o:setValue(v)
        if o.onChange then o:onChange(v) end
        if o.onChangeApply then o:onChangeApply(v) end
    end)
    if not ok then H.note(tostring(o.id) .. "=" .. tostring(v) .. " threw: " .. tostring(err)) end
    pcall(Sf.reread)
    return ok
end
-- the ids whose value (or whose control) is not the one read at the start
function H.offList()
    local off = {}
    for _, o in ipairs(S.optAll or {}) do
        local v0 = S.opt0[o.id]
        local el = o.element
        if H.get(o) ~= v0 or (o.type == "combobox" and el and el.selected ~= nil and el.selected ~= v0) then off[#off + 1] = tostring(o.id) end
    end
    return off
end
-- every option's value back as found (in memory), and the copies Settings.lua keeps on the character
function H.putOptions()
    for _, o in ipairs(S.optAll or {}) do
        local v0 = S.opt0[o.id]
        local el = o.element
        if H.get(o) ~= v0 or (o.type == "combobox" and el and el.selected ~= v0) then pcall(function() o:setValue(v0) end) end
    end
    pcall(function()
        local md = S.p:getModData()
        H.restoreTable(md, "ZeD_Theme", S.mdTheme0)
        H.restoreTable(md, "ZeD_Gamepad", S.mdPad0)
        local ws = md.ZeD_WinState
        if ws and ws.char then ws.char.accentKey = S.wsC0 end
        if ws and ws.world then ws.world.accentKey = S.wsW0 end
    end)
    ZeD._pendingCharAccent, ZeD._pendingWorldAccent = S.pendC0, S.pendW0
end
-- the look on screen as found: the scale, the see-through pick, the status set, the theme, the input lock
function H.putLook()
    pcall(function() if S.root0 and Sc and math.abs(Sc.root() - S.root0) > 0.001 then St.applyScale(St.uiScaleOption:getValue()) end end)
    if S.look0 then
        ZeD.surfaceAlpha, ZeD._seePick, ZeD._seeForced = S.look0.a, S.look0.pick, S.look0.forced
        ZeD.currentStatus = S.look0.status
    end
    pcall(function() if ZeD_Window and ZeD_Window.clearPaletteCache then ZeD_Window.clearPaletteCache() end end)
    if S.base0 and (ZeD.currentBase ~= S.base0 or ZeD.currentAccent ~= S.accent0 or ZeD.currentSize ~= S.size0 or (ZeD.T and ZeD.T.baseKey ~= S.base0)) then
        pcall(ZeD.applyTheme, S.base0, S.accent0, S.size0)
    end
    pcall(function() if S.accC then RT.cw()._accentKey = S.accC.k end end)
    pcall(function() if S.accW then RT.ww()._accentKey = S.accW.k end end)
end

-- ===================================================================== helpers: the windows, the card, the tabs
function H.bothOpen()
    local c, w = false, false
    pcall(function() c = ZeD_CharacterWindow.isOpen(S.pn) end)
    pcall(function() w = ZeD_WorldWindow.isOpen(S.pn) end)
    return c and w
end
function H.bothShut()
    local c, w = true, true
    pcall(function() c = ZeD_CharacterWindow.isOpen(S.pn) end)
    pcall(function() w = ZeD_WorldWindow.isOpen(S.pn) end)
    return not c and not w
end
function H.aside() local a = false; pcall(function() a = Sf.on("windows") and true or false end); return a end
function H.scaleSettled()
    if not Sc then return true end
    local T = ZeD.T
    return Sc._reopenAt == nil and T ~= nil and math.abs((T.root or 0) - Sc.root()) < 0.001
end
-- the windows settled after a change: the scale applied, and the pair open again (asked for when a change shut
-- it), or ZeD stepped aside from the windows
function H.settled()
    if not H.scaleSettled() then return false end
    if H.aside() then return true end
    if H.bothOpen() then return true end
    if getGameSpeed() <= 0 then return true end   -- (paused: the pair does not open; said by the check after)
    if (S.stuck or 0) >= 3 then return true end   -- (the pair would not open three times: said each time, not waited for again)
    RT.pairOpen()
    return H.bothOpen()
end
function H.content() local w = RT.cw(); return w and w._mainContent end
function H.rowZone(item)
    local c = H.content()
    for _, z in ipairs((c and c._hitZones) or {}) do if z.id == item then return z end end
    return nil
end
function H.seekRow(item)
    local c = H.content()
    if not (c and item) then return false end
    if H.rowZone(item) then return true end
    local sc = c._scroll
    if sc and sc.setScrollPos then
        S.seekPos = (S.seekPos or -0.1) + 0.1
        if S.seekPos > 1.001 then S.seekPos = 0 end
        sc:setScrollPos(S.seekPos)
    end
    return false
end
-- a left click on the item's row, as the list's own mouse handlers take it (it opens the item's card)
function H.click(item)
    local c = H.content()
    local z = H.rowZone(item)
    if not (c and z) then return false end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    c._zedLastClick = nil   -- (never a double-click: that would be the quick use)
    return pcall(function() c:onMouseDown(x, y); c:onMouseUp(x, y) end) and true or false
end
function H.cardOn(item)
    local w = RT.cw()
    local c = w and w._itemCard
    return item ~= nil and w ~= nil and w._drawerItem == item and c ~= nil and c.item == item
end
function H.onLoot() local w = RT.cw(); return w ~= nil and w._activeTab == "loot" end
-- the card opened on the pencil when its row is drawn and no card shows (never a second click: that closes it)
function H.cardWanted()
    if S.noCard or not S.item or H.aside() or not H.onLoot() or H.cardOn(S.item) then return false end
    local w = RT.cw()
    if w and w._drawerItem ~= nil then return false end
    return H.click(S.item)
end
-- a card that shows must show the item the window says, and that item must still be somewhere
function H.cardStale()
    local w = RT.cw()
    local it = w and w._drawerItem
    if not it then return nil end
    local c = w._itemCard
    if not (c and c.item == it) then return "the drawer's item and the card's item differ" end
    local cont = nil
    pcall(function() cont = it:getContainer() end)
    if not cont then return "the card shows an item that is in no container" end
    return nil
end
function H.has(list, id) for _, x in ipairs(list or {}) do if x == id then return true end end; return false end
-- the next tab to turn to on each window (only tabs the first pass saw turn), pressed through the strip
function H.turnTabs()
    S.wantC, S.wantW = nil, nil
    if H.aside() or not H.bothOpen() then return end
    S.k = S.k + 1
    local gc, gw = S.goodC or {}, S.goodW or {}
    if #gc > 1 then
        local id = gc[S.k - math.floor(S.k / #gc) * #gc + 1]
        if id == "loot" then id = gc[(S.k + 1) - math.floor((S.k + 1) / #gc) * #gc + 1] end
        local okc, did = pcall(RT.charTab, id)
        if okc and did then S.wantC = id end
    end
    if #gw > 1 then
        local id = gw[S.k - math.floor(S.k / #gw) * #gw + 1]
        local okw, did = pcall(RT.worldTab, id)
        if okw and did then S.wantW = id end
    end
end
function H.tabsTurned()
    local cw, ww = RT.cw(), RT.ww()
    if S.wantC then
        if cw and cw._activeTab == S.wantC then S.tabTurns = S.tabTurns + 1
        elseif not H.aside() then H.note("Character tab " .. tostring(S.wantC) .. " did not open (on " .. tostring(cw and cw._activeTab) .. ")") end
    end
    if S.wantW then
        if ww and ww._activeTab == S.wantW then S.tabTurns = S.tabTurns + 1
        elseif not H.aside() then H.note("World tab " .. tostring(S.wantW) .. " did not open (on " .. tostring(ww and ww._activeTab) .. ")") end
    end
    S.wantC, S.wantW = nil, nil
    if H.has(S.goodC, "loot") and not H.aside() then pcall(RT.charTab, "loot") end
end
-- the first pass: each tab on both strips pressed once, four frames each; the ones that became the active tab
function H.probeStart()
    S.tp = { c = RT.tabs(RT.charStrip()), w = RT.tabs(RT.worldStrip()), i = 0, f = 0 }
    S.goodC, S.goodW = {}, {}
end
function H.probeTick()
    local t = S.tp
    if not t then return true end
    t.f = t.f + 1
    if t.f < 4 then return false end
    t.f = 0
    local cw, ww = RT.cw(), RT.ww()
    if t.i > 0 then
        local c, w = t.c[t.i], t.w[t.i]
        if c and cw and cw._activeTab == c then S.goodC[#S.goodC + 1] = c end
        if w and ww and ww._activeTab == w then S.goodW[#S.goodW + 1] = w end
    end
    t.i = t.i + 1
    if t.i > math.max(#t.c, #t.w) then return true end
    if t.c[t.i] then pcall(RT.charTab, t.c[t.i]) end
    if t.w[t.i] then pcall(RT.worldTab, t.w[t.i]) end
    return false
end
-- the ZeD things on screen, by kind
function H.zedRoots()
    local out, n = {}, 0
    for _, r in ipairs(RT.roots()) do
        local vis = false
        pcall(function() vis = r.e:isVisible() end)
        if vis and RT.isZeD(r.t) then
            local ty = tostring(r.t.Type or "?")
            out[ty] = (out[ty] or 0) + 1
            n = n + 1
        end
    end
    return out, n
end

-- ===================================================================== helpers: safe mode
function H.vanillaInv() local v = false; pcall(function() local vi = getPlayerInventory(S.pn); v = vi ~= nil and vi:isVisible() end); return v end
function H.hotbar()
    local orig = Sf._originals and Sf._originals.ISHotbar
    if not orig then return "no original kept" end
    return (ISHotbar.render == orig.render) and "vanilla" or "replaced"
end
function H.moodles() local s = "none"; pcall(function() local l = ZeD.Moodles.getLayer(S.pn); if l then s = tostring(l:isVisible()) end end); return s end
function H.state()
    return "safe " .. tostring(Sf.on()) .. " | pair shut " .. tostring(H.bothShut()) .. " | game's inventory " .. tostring(H.vanillaInv())
        .. " | hotbar " .. H.hotbar() .. " | moodle layer " .. H.moodles()
end
function H.safeNote()
    local n = Sf._note
    local vis = false
    pcall(function() vis = n ~= nil and n.javaObject ~= nil and n:isVisible() end)
    return vis and n or nil
end
function H.closeNote()
    local n = H.safeNote()
    if not n then return false end
    pcall(function() if n.ok then n:onClick(n.ok) else n:destroy() end end)
    return true
end
function H.tripped() local st = Sf._state; return st ~= nil and st.tripped == true end
function H.emptyTripFile() pcall(function() local f = getFileWriter("ZeD_safe_trip.txt", true, false); f:write(""); f:close() end) end
-- what ZeD's hand-back must be now, from the switches themselves: safe mode is the option or a trip; each screen
-- follows safe mode or its own switch; each hook was handed back or taken over to match (SafeMode.lua's sync)
function H.asideBad()
    local bad = {}
    local st = Sf._state or {}
    local by = st.by or {}
    local all = Sf.on() and true or false
    local want = (H.val("safeMode") == 2) or st.tripped == true
    if all ~= want then bad[#bad + 1] = "safe mode reads " .. tostring(all) .. ", option " .. tostring(H.val("safeMode")) .. ", tripped " .. tostring(st.tripped) end
    for sc, o in pairs(St.screenOptions or {}) do
        local off = Sf.pieceOff(sc) and true or false
        if off ~= (H.get(o) == 2) then bad[#bad + 1] = "screen " .. tostring(sc) .. " reads " .. tostring(off) .. ", switch " .. tostring(H.get(o)) end
    end
    for name, h in pairs(Sf._hooks or {}) do
        local w = all or (Sf.pieceOff(h.screen or name) and true or false)
        if (by[name] or false) ~= w then bad[#bad + 1] = "hook " .. tostring(name) .. " handed back " .. tostring(by[name] or false) .. ", want " .. tostring(w) end
    end
    if S.hot0 == "replaced" then
        local wantHot = Sf.on("belt") and "vanilla" or "replaced"
        if H.hotbar() ~= wantHot then bad[#bad + 1] = "hotbar " .. H.hotbar() .. ", want " .. wantHot end
    end
    if not Sf.on("windows") and H.vanillaInv() then bad[#bad + 1] = "the game's inventory page shows while ZeD has the windows" end
    if Sf.on("windows") and not H.bothShut() then bad[#bad + 1] = "ZeD's windows are open while the game has the windows" end
    return bad
end
-- a trip nobody asked for (a real fault ran two seconds): said, and taken back so the run goes on
function H.strayTrip(where)
    if S.tripMine or not H.tripped() then return false end
    H.note(where .. ": safe mode TRIPPED by itself")
    H.closeNote()
    pcall(Sf.reset)
    H.emptyTripFile()
    return true
end
function H.takeFaults()
    local f = S.faultNew
    S.faultNew = {}
    return f
end

-- ===================================================================== helpers: the Options window, the map
function H.listRows(w)
    local out = {}
    for _, sp in ipairs((w and w._specs) or {}) do if sp.listRow and sp.rowRef then out[#out + 1] = sp.rowRef end end
    return out
end
function H.setupRow(w, id)
    local o = H.opt(id)
    local el = o and o.element
    if not el then return nil end
    local rows = {}
    pcall(function() rows = w:zedSetupRows() end)
    for _, r in ipairs(rows) do if r.control == el then return r end end
    return nil
end
function H.optsUp() local w = MM and MM.pauseOpts; return w ~= nil and w:isVisible() and MM.pauseView == "options" end
function H.kmWin()
    local w = KM and KM.windows and KM.windows[S.pn]
    local on = false
    pcall(function() on = w ~= nil and w:isReallyVisible() end)
    return on and w or nil
end
-- a hit of the map by kind, drawn inside its body now; and a click on it through the window's own handlers
function H.kmHit(id)
    local w = H.kmWin()
    if not w then return nil end
    local tb = 0
    pcall(function() tb = w:titleBarHeight() end)
    for _, h in ipairs(w._hits or {}) do
        if h.id == id and h.y >= tb and h.y + h.h <= tb + (w._bodyH or 0) then return h end
    end
    return nil
end
function H.kmClick(h)
    local w = H.kmWin()
    if not (w and h) then return false end
    local x, y = h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2)
    return pcall(function() w:onMouseDown(x, y); w:onMouseUp(x, y) end) and true or false
end
function H.keysNow()
    local out, n = {}, 0
    pcall(function()
        for _, b in ipairs(keyBinding or {}) do
            local nm = b and b.value
            if type(nm) == "string" and nm:sub(1, 1) ~= "[" then out[nm] = getCore():getKey(nm); n = n + 1 end
        end
    end)
    return out, n
end

-- ===================================================================== 0. as found
Q.step(5, function()
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "bx_opt") end
    S.dead = false
    pcall(function() S.dead = S.p:isDead() end)
    S.err0 = H.errs()
    S.errAll0 = S.err0
    S.speed0 = getGameSpeed()
    S.winsWere = RT.isOpen()
    S.menuWas0 = H.menuUp()
    S.mapWas = H.kmWin() ~= nil
    S.ini0 = H.readLines("ModOptions.ini")
    S.keys0, S.nKeys = H.keysNow()
    -- every ZeD option's value as found (the sweep works the lists, tick boxes and sliders)
    S.opt0, S.optAll = {}, {}
    local zo = H.opts()
    for _, o in ipairs((zo and zo.data) or {}) do
        local v = (o.id and o.getValue and o.type ~= "multipletickbox") and H.get(o) or nil
        if v ~= nil and type(v) ~= "table" then S.opt0[o.id] = v; S.optAll[#S.optAll + 1] = o end
    end
    pcall(function()
        local md = S.p:getModData()
        S.mdTheme0, S.mdPad0 = H.copy(md.ZeD_Theme), H.copy(md.ZeD_Gamepad)
        local ws = md.ZeD_WinState
        S.wsC0 = ws and ws.char and ws.char.accentKey
        S.wsW0 = ws and ws.world and ws.world.accentKey
    end)
    S.pendC0, S.pendW0 = ZeD._pendingCharAccent, ZeD._pendingWorldAccent
    S.look0 = { a = ZeD.surfaceAlpha, pick = ZeD._seePick, forced = ZeD._seeForced, status = ZeD.currentStatus }
    S.base0, S.accent0, S.size0 = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    S.root0 = Sc and Sc.root()
    S.safe0 = Sf.on() and true or false
    Q.check(not S.dead and MM ~= nil and Sc ~= nil and #S.optAll > 0, "ZeD's options are there to work (PZAPI.ModOptions ZeD_UI), the character alive",
        #S.optAll .. " options with a value")
    Q.say("as found: safe mode " .. tostring(S.safe0) .. ", scale " .. tostring(S.root0) .. ", theme " .. tostring(S.base0) .. " / " .. tostring(S.accent0)
        .. " / " .. tostring(S.size0) .. ", " .. tostring(S.nKeys) .. " key bindings, ModOptions.ini " .. (S.ini0 and (#S.ini0 .. " lines") or "not read"))
    if getGameSpeed() <= 0 and not S.menuWas0 then pcall(setGameSpeed, 1) end
    RT.pairOpen()
end)
-- the scene: both windows, the inventory with the pencil's card, the HUD
Q.waitFor(10, 300, function() return H.aside() or H.bothOpen() end, function(ok)
    if ZEDQA_LAYOUT_SNAP then pcall(function() S.snap = ZEDQA_LAYOUT_SNAP() end) end
    pcall(function() S.accC = { k = RT.cw()._accentKey } end)
    pcall(function() S.accW = { k = RT.ww()._accentKey } end)
    if H.aside() then Q.skip("the scene: both windows open", "ZeD has handed the windows back to the game in this game (safe mode or its switch)"); return end
    Q.check(ok, "the scene: the Character and World windows are open")
    H.probeStart()
end)
Q.waitFor(1, 400, H.probeTick, function(ok)
    if not S.tp then return end
    Q.check(ok and #S.goodC > 0 and #S.goodW > 0, "the scene: the tabs on both windows turn (the first pass)",
        "Character: " .. table.concat(S.goodC or {}, " ") .. " | World: " .. table.concat(S.goodW or {}, " "))
    S.item = RT.give("Base.Pencil")
    if not S.item then Q.skip("the scene: an item card open", "the pencil could not be given"); S.noCard = true end
    if not H.has(S.goodC, "loot") then Q.skip("the scene: an item card open", "the Character window has no inventory tab to turn to"); S.noCard = true end
    pcall(RT.charTab, "loot")
    S.seekPos = nil
end)
Q.waitFor(6, 240, function() return S.noCard or H.aside() or H.seekRow(S.item) end, function(ok)
    if S.noCard or H.aside() then return end
    if not ok then Q.skip("the scene: an item card open", "the pencil's row was not found in the inventory list"); S.noCard = true; return end
    H.click(S.item)
end)
Q.step(20, function()
    if not (S.noCard or H.aside()) then
        Q.check(H.cardOn(S.item), "the scene: the pencil's item card is open in the Character window")
    end
    local kinds, n = H.zedRoots()
    S.roots0 = kinds
    local names = {}
    for ty, c in pairs(kinds) do names[#names + 1] = ty .. ((c > 1) and (" x" .. c) or "") end
    Q.check(n >= 2 or H.aside(), "the scene: ZeD's windows and HUD are on screen", n .. " ZeD things: " .. table.concat(names, ", "))
    S.hot0 = H.hotbar()
    S.state0 = H.state()
    Q.say("baseline: " .. S.state0)
    RT.bounds(Q, "the scene")
    -- every guarded fault from here on is kept (pass-through to safe mode's own count)
    S.faultWas = Sf.fault
    Sf.fault = function(k, e)
        S.nFaults = S.nFaults + 1
        if #S.faultNew < 12 then S.faultNew[#S.faultNew + 1] = tostring(k) .. ": " .. tostring(e) end
        return S.faultWas(k, e)
    end
end)

-- ===================================================================== 1. the sweep: every option, every value
function H.afterPick(o, v, ok)
    local tag = tostring(o.id) .. "=" .. tostring(v)
    S.nValues = S.nValues + 1
    if H.get(o) ~= v then H.note(tag .. " did not hold (reads " .. tostring(H.get(o)) .. ")") end
    if not ok then S.stuck = (S.stuck or 0) + 1 end
    if not ok then H.note(tag .. ": the windows did not settle (open " .. tostring(H.bothOpen()) .. ", scale settled " .. tostring(H.scaleSettled()) .. ")") end
    H.strayTrip(tag)
    for _, b in ipairs(H.asideBad()) do H.note(tag .. ": " .. b) end
    local stale = H.cardStale()
    if stale then H.note(tag .. ": " .. stale) end
    if H.cardOn(S.item) then S.cardSeen = S.cardSeen + 1 end
    RT.bounds(Q, tag)
    H.turnTabs()
end
function H.restoreOne(o)
    H.pick(o, S.opt0[o.id])
    H.putOptions()
    pcall(Sf.reread)
end
function H.backAsFound()
    if not H.settled() then return false end
    if (S.slow or 0) < 2 and H.state() ~= S.state0 then return false end   -- (a state that stays wrong is said, not waited for every time)
    if S.noCard or H.aside() or not H.onLoot() then return true end
    if H.cardOn(S.item) then return true end
    return H.seekRow(S.item)
end
function H.afterOption(o, n, ok)
    local id = tostring(o.id)
    if not ok then
        if H.state() ~= S.state0 then S.slow = (S.slow or 0) + 1 end
        if not (S.noCard or H.aside()) and H.onLoot() and not H.cardOn(S.item) and not H.rowZone(S.item) then
            S.seekMiss = (S.seekMiss or 0) + 1
            if S.seekMiss >= 2 then S.noCard = true; Q.say("the pencil's row is not found any more: the rest runs with no item card") end
        end
    end
    H.cardWanted()
    local off = H.offList()
    if #off > 0 then H.note("not back as found: " .. table.concat(off, " ")) end
    if H.state() ~= S.state0 then H.note("ZeD's state is " .. H.state()) end
    if not ok and not H.settled() then H.note("the windows did not come back") end
    Q.check(#S.bad == 0, "option " .. id .. ": " .. n .. " values, each held with ZeD's state right, the tabs turning, and back as found", H.few(S.bad, 6))
    S.bad = {}
    local e, f = H.errs(), H.takeFaults()
    Q.check((S.err0 == nil or e == S.err0) and #f == 0, "option " .. id .. ": no Lua error and no guarded fault",
        ((S.err0 and e) and ((e - S.err0) .. " new errors") or "errors not counted") .. ((#f > 0) and (" | faults: " .. H.few(f, 4)) or ""))
    S.err0 = e
end
function H.sweepOption(o)
    local vals = H.values(o)
    if #vals == 0 then return 0 end
    for _, v in ipairs(vals) do
        Q.step(2, function() H.cardWanted(); H.pick(o, v) end)
        Q.waitFor(3, 600, H.settled, function(ok) H.afterPick(o, v, ok) end)
        Q.step(3, H.tabsTurned)
    end
    Q.step(2, function() H.restoreOne(o) end)
    Q.waitFor(4, 300, H.backAsFound, function(ok) H.afterOption(o, #vals, ok) end)
    return #vals
end
function H.buildSweep()
    local zo = H.opts()
    local nOpt, nVal, left = 0, 0, {}
    for _, o in ipairs((zo and zo.data) or {}) do
        if o.id and (o.type == "combobox" or o.type == "tickbox" or o.type == "slider") then
            local n = H.sweepOption(o)
            if n > 0 then nOpt = nOpt + 1; nVal = nVal + n else left[#left + 1] = tostring(o.id) end
        elseif o.id and o.getValue then
            left[#left + 1] = tostring(o.id) .. " (" .. tostring(o.type) .. ")"
        end
    end
    S.sweepOpts, S.sweepVals, S.sweepLeft = nOpt, nVal, left
end
H.buildSweep()
Q.step(2, function()
    Q.check((S.sweepOpts or 0) > 0 and S.nValues == S.sweepVals, "the sweep set every value of every list, tick box and slider",
        tostring(S.nValues) .. " of " .. tostring(S.sweepVals) .. " values on " .. tostring(S.sweepOpts) .. " options")
    if #(S.sweepLeft or {}) > 0 then Q.skip("the sweep: " .. table.concat(S.sweepLeft, ", "), "not a list, tick box or slider, or it has no values") end
    Q.say("sweep: the item card was open through " .. S.cardSeen .. " of " .. S.nValues .. " changes, " .. S.tabTurns .. " tabs turned")
    if not (S.noCard or S.safe0) then Q.check(S.cardSeen > 0, "the sweep ran with the item card open", S.cardSeen .. " of " .. S.nValues .. " changes") end
    if #(S.goodC or {}) > 1 and not S.safe0 then Q.check(S.tabTurns > 0, "the sweep turned tabs after the changes", tostring(S.tabTurns)) end
end)

-- ===================================================================== 2. safe mode: each part, all parts, flips, a trip
-- (one closing check for a part of this section: ZeD's state as at the start, the switches' own story, no error)
function H.closeOut(what, ok)
    for _, b in ipairs(H.asideBad()) do H.note(b) end
    if H.state() ~= S.state0 then H.note("ZeD's state is " .. H.state()) end
    if not ok then H.note("the windows did not come back in time") end
    local off = H.offList()
    if #off > 0 then H.note("options not as found: " .. table.concat(off, " ")) end
    local e, f = H.errs(), H.takeFaults()
    if S.err0 and e and e ~= S.err0 then H.note((e - S.err0) .. " new Lua errors") end
    if #f > 0 then H.note("faults: " .. H.few(f, 4)) end
    S.err0 = e
    Q.check(#S.bad == 0, what, H.few(S.bad, 6))
    S.bad = {}
    if not H.aside() then RT.bounds(Q, what) end
end
function H.cameBack() return H.settled() and H.state() == S.state0 end   -- (waited for 600 frames at most, then said)
function H.screenList()
    local out = {}
    for sc in pairs(St.screenOptions or {}) do out[#out + 1] = sc end
    table.sort(out)
    return out
end
Q.step(5, function()
    if S.safe0 then Q.skip("safe mode: the parts, the flips and the trip", "safe mode is already on in this game: ZeD is not running to hand back"); return end
    S.safeOpt = St.safeModeOption
    -- every screen switch On in one frame (last name first), read at once
    local list = H.screenList()
    for i = #list, 1, -1 do pcall(function() St.screenOptions[list[i]]:setValue(2) end) end
    pcall(Sf.reread)
    S.nScreens = #list
end)
Q.step(20, function()
    if S.safe0 then return end
    local bad = H.asideBad()
    local st = Sf._state or {}
    local by, held, hooks = st.by or {}, 0, 0
    for name in pairs(Sf._hooks or {}) do hooks = hooks + 1; if by[name] then held = held + 1 end end
    Q.check(#bad == 0 and not Sf.on() and H.bothShut() and S.nScreens > 0, "every screen switch On at once: each screen is the game's, the windows shut, safe mode itself still off",
        (#bad > 0) and H.few(bad, 6) or (S.nScreens .. " switches, " .. held .. " of " .. hooks .. " hooks handed back"))
    RT.bounds(Q, "every screen handed back")
    pcall(RT.pairOpen)   -- (a player presses the inventory key: ZeD's windows must stay shut)
    S.shutStill = H.bothShut()
    local list = H.screenList()
    for i = 1, #list do pcall(function() St.screenOptions[list[i]]:setValue(S.opt0[St.screenOptions[list[i]].id]) end) end
    pcall(Sf.reread)
end)
Q.waitFor(4, 600, H.cameBack, function(ok)
    if S.safe0 then return end
    Q.check(S.shutStill, "every screen handed back: asking for ZeD's windows opens nothing")
    H.closeOut("every screen switch back: ZeD takes each screen again, as at the start", ok)
end)
-- the Safe mode option flipped twenty times in one frame (each read at once), ending Off
Q.step(5, function()
    if S.safe0 then return end
    local okAll = true
    for i = 1, 20 do
        local okp = pcall(function() S.safeOpt:setValue(H.odd(i) and 2 or 1); Sf.reread() end)
        okAll = okAll and okp
    end
    S.flipOk = okAll
end)
Q.waitFor(4, 600, H.cameBack, function(ok)
    if S.safe0 then return end
    if not S.flipOk then H.note("a flip threw") end
    H.closeOut("Safe mode On and Off twenty times in one frame: ZeD is back as at the start", ok)
end)
-- and once a frame for forty frames (the windows asked for on every Off), ending Off
Q.waitFor(3, 200, function()
    if S.safe0 then return true end
    S.ff = (S.ff or 0) + 1
    pcall(function() S.safeOpt:setValue(H.odd(S.ff) and 2 or 1); Sf.reread() end)
    if not H.odd(S.ff) then pcall(RT.pairOpen) end
    return S.ff >= 40
end, function() end)
Q.waitFor(4, 600, H.cameBack, function(ok)
    if S.safe0 then return end
    H.closeOut("Safe mode flipped every frame for forty frames: ZeD is back as at the start", ok)
end)
-- a trip: the note; a second trip changes nothing; a screen switched while tripped; the windows asked for
Q.step(5, function()
    if S.safe0 then return end
    S.tripMine = true
    pcall(Sf.trip, "bx_opt trip", "a test trip")
end)
Q.step(30, function()
    if S.safe0 then return end
    local n1 = H.safeNote()
    Q.check(Sf.on() and H.tripped() and H.bothShut() and n1 ~= nil, "a trip: ZeD steps aside, its windows shut, the note shows",
        H.state() .. " | note " .. tostring(n1 ~= nil))
    pcall(Sf.trip, "bx_opt trip two", "a second test trip")
    Q.check(H.safeNote() == n1, "a second trip while tripped shows no second note")
    Q.check(H.closeNote(), "the trip's note closes")
    local o = St.screenOptions and St.screenOptions.belt
    if o then
        pcall(function() o:setValue(2); Sf.reread(); o:setValue(S.opt0[o.id]); Sf.reread() end)
    end
    pcall(RT.pairOpen)
    local bad = H.asideBad()
    Q.check(Sf.on() and H.bothShut() and #bad == 0, "tripped: a screen switch On and Off and a press for the windows change nothing, every hook still handed back", H.few(bad, 6))
    RT.bounds(Q, "tripped")
    -- the option On, then Off: the trip goes with it (SafeMode.lua S.on)
    pcall(function() S.safeOpt:setValue(2); Sf.reread() end)
    S.onBoth = Sf.on() and H.tripped()
    pcall(function() S.safeOpt:setValue(S.opt0.safeMode or 1); Sf.reread() end)
end)
Q.waitFor(4, 600, H.cameBack, function(ok)
    if S.safe0 then return end
    Q.check(S.onBoth == true and not H.tripped() and not Sf.on(), "tripped, then the option On and Off: the trip is cleared with it and ZeD runs again",
        "tripped " .. tostring(H.tripped()) .. ", safe mode " .. tostring(Sf.on()))
    pcall(Sf.reset)        -- (the note may show again on a later real trip)
    H.emptyTripFile()
    S.tripMine = false
    H.closeOut("after the trip: ZeD is back as at the start", ok)
end)
-- a trip and a hand reset, twice over in one frame
Q.step(5, function()
    if S.safe0 then return end
    S.tripMine = true
    local okAll = true
    for i = 1, 2 do
        local okp = pcall(function() Sf.trip("bx_opt trip " .. i, "a test trip"); H.closeNote(); Sf.reset(); Sf.reset() end)
        okAll = okAll and okp
    end
    S.flipOk = okAll
    H.emptyTripFile()
    S.tripMine = false
end)
Q.waitFor(4, 600, H.cameBack, function(ok)
    if S.safe0 then return end
    if not S.flipOk then H.note("a trip or a reset threw") end
    if H.safeNote() then H.note("a note was left on screen"); H.closeNote() end
    H.closeOut("a trip and a reset twice in one frame: ZeD is back as at the start, no note left", ok)
end)

-- ===================================================================== 3. Lite and Full
Q.step(5, function()
    S.lookOpt = St.lookStyleOption
    S.ff, S.fn = 0, 0
    if not S.lookOpt then Q.check(false, "ZeD's settings have the Style option (Lite or Full)") end
end)
Q.waitFor(2, 400, function()
    if not S.lookOpt then return true end
    S.ff = S.ff + 1
    if H.odd(S.ff) then return false end
    S.fn = S.fn + 1
    H.pick(S.lookOpt, H.odd(S.fn) and 2 or 1)
    if H.odd(S.fn) then H.turnTabs() else S.wantC, S.wantW = nil, nil; pcall(RT.charTab, "loot") end
    return S.fn >= 16
end, function() end)
Q.waitFor(6, 600, H.settled, function(ok)
    if not S.lookOpt then return end
    if not ok then H.note("the windows did not settle") end
    if St.lite() then H.note("Style reads Lite after the last pick of Full") end
    local stale = H.cardStale()
    if stale then H.note(stale) end
    for _, b in ipairs(H.asideBad()) do H.note(b) end
    local e, f = H.errs(), H.takeFaults()
    if S.err0 and e and e ~= S.err0 then H.note((e - S.err0) .. " new Lua errors") end
    if #f > 0 then H.note("faults: " .. H.few(f, 4)) end
    S.err0 = e
    Q.check(#S.bad == 0, "Lite and Full flipped sixteen times two frames apart, tabs turning: ends in Full, nothing thrown", H.few(S.bad, 6))
    S.bad = {}
    RT.bounds(Q, "after the Lite and Full flips")
    pcall(RT.charTab, "loot")
    H.pick(S.lookOpt, 2)
end)
Q.waitFor(10, 600, H.settled, function(ok)
    if not S.lookOpt then return end
    local P1 = St.ADDITION_PRESETS and St.ADDITION_PRESETS[1]
    local off = {}
    for id, v in pairs(P1 or {}) do if H.opt(id) and H.val(id) ~= v then off[#off + 1] = id .. "=" .. tostring(H.val(id)) end end
    Q.check(ok and St.lite() == true and H.val("lookStyle") == 2, "Lite picked: ZeD.Settings.lite() is true, the windows open", tostring(H.val("lookStyle")))
    if P1 then Q.check(#off == 0, "Lite picked: every addition is on the Vanilla preset", table.concat(off, " "))
    else Q.skip("Lite picked: every addition is on the Vanilla preset", "ZeD.Settings.ADDITION_PRESETS is not there to read") end
    RT.bounds(Q, "Lite")
    H.cardWanted()
    H.turnTabs()
end)
Q.step(6, function()
    if not S.lookOpt then return end
    H.tabsTurned()
    H.pick(S.lookOpt, 1)
end)
Q.waitFor(10, 600, H.settled, function(ok)
    if not S.lookOpt then return end
    Q.check(ok and St.lite() == false and H.val("lookStyle") == 1, "Full picked: ZeD.Settings.lite() is false, the windows open", tostring(H.val("lookStyle")))
    RT.bounds(Q, "Full")
    H.restoreOne(S.lookOpt)
end)
Q.waitFor(4, 600, H.cameBack, function(ok)
    if not S.lookOpt then return end
    H.closeOut("after Lite and Full: the options and ZeD's state as at the start", ok)
end)

-- ===================================================================== 4. the keyboard map
Q.step(5, function()
    S.km = KM ~= nil and KM.open ~= nil and KM.close ~= nil
    if not S.km then Q.check(false, "ZeD's keyboard map is loaded (ZeD.KeyboardMap open, close)"); return end
    local okAll = true
    for _ = 1, 10 do
        local okp = pcall(function() KM.open(S.pn); KM.close(S.pn) end)
        okAll = okAll and okp
    end
    local w = KM.windows and KM.windows[S.pn]
    Q.check(okAll and H.kmWin() == nil and not (w and w._keysOff), "the keyboard map opened and closed ten times in one frame: shut, the game's keys on",
        "threw " .. tostring(not okAll) .. ", keys off " .. tostring(w and w._keysOff))
    pcall(KM.open, S.pn)
end)
Q.waitFor(10, 200, function() return not S.km or H.kmWin() ~= nil end, function(ok)
    if not S.km then return end
    S.kmOpen = ok
    if not Q.check(ok, "the keyboard map opens") then return end
    RT.bounds(Q, "the keyboard map")
    local w = H.kmWin()
    -- scrolled far past both ends, and by the wheel
    local okS = pcall(function() w:scrollBy(-999999) end)
    local top = w.scroll
    okS = pcall(function() w:scrollBy(999999) end) and okS
    local maxS = math.max(0, (w._contentH or 0) - (w._bodyH or 0))
    local bottom = w.scroll
    okS = pcall(function() w:onMouseWheel(-50); w:onMouseWheel(50); w:scrollBy(-999999) end) and okS
    Q.check(okS and top == 0 and math.abs(bottom - maxS) < 0.5 and w.scroll == 0, "the keyboard map scrolled past both ends stays between its top and its bottom",
        "top " .. tostring(top) .. ", bottom " .. tostring(bottom) .. " of " .. tostring(maxS))
end)
Q.step(8, function()
    if not S.kmOpen then return end
    local w = H.kmWin()
    local cap = H.kmHit("cap")
    if not (w and cap) then Q.skip("the keyboard map: a key cap clicked twice", "no key cap is drawn inside the window now"); return end
    H.kmClick(cap)
    local one = w.picked
    H.kmClick(cap)
    Q.check(one == cap.code and w.picked == nil, "the keyboard map: a click on a key cap picks it, a second click lets it go", tostring(one) .. " then " .. tostring(w.picked))
end)
-- an action set to wait for its key, answered with Escape: no key changes, and the game's keys come back
Q.step(4, function()
    if not S.kmOpen then return end
    local w = H.kmWin()
    local b = H.kmHit("bind")
    S.bind = b and b.name or nil
    if not (w and b) then Q.skip("the keyboard map: an action waits for its key", "no action box is drawn inside the window now"); return end
    S.bindKey = S.keys0[S.bind]
    H.kmClick(b)
    Q.check(w.listening == S.bind and w._keysOff == true, "the keyboard map: a click on an action waits for its key, the game's keys held off meanwhile",
        "waiting for " .. tostring(w.listening) .. ", keys off " .. tostring(w._keysOff))
    pcall(function() w:onKeyPress(Keyboard.KEY_ESCAPE) end)
end)
Q.step(24, function()
    if not (S.kmOpen and S.bind) then return end
    local w = H.kmWin()
    local now = nil
    pcall(function() now = getCore():getKey(S.bind) end)
    Q.check(w ~= nil and w.listening == nil and not w._keysOff and (S.bindKey == nil or now == S.bindKey),
        "the keyboard map: Escape while it waits sets no key, the map stays, the game's keys are back on",
        "open " .. tostring(w ~= nil) .. ", keys off " .. tostring(w and w._keysOff) .. ", key " .. tostring(now) .. " was " .. tostring(S.bindKey))
    -- waiting again, then the window closed under it
    local b = H.kmHit("bind")
    if w and b then
        H.kmClick(b)
        local waiting = w.listening ~= nil
        pcall(KM.close, S.pn)
        Q.check(waiting and H.kmWin() == nil and not w._keysOff and w.listening == nil, "the keyboard map closed while it waits: shut, nothing waiting, the game's keys on",
            "was waiting " .. tostring(waiting) .. ", keys off " .. tostring(w._keysOff))
    end
    pcall(KM.open, S.pn)
end)
Q.step(10, function()
    if not S.kmOpen then return end
    local w = H.kmWin()
    if not Q.check(w ~= nil and w.listening == nil and w.picked == nil, "the keyboard map opens again clean (nothing waiting, no key picked)") then return end
    -- Escape from anywhere: first it ends the wait, then it closes the map
    local b = H.kmHit("bind")
    if b then
        H.kmClick(b)
        local took = false
        pcall(function() took = KM.takeEscape() end)
        Q.check(took and H.kmWin() ~= nil and w.listening == nil and not w._keysOff, "the keyboard map: Escape from anywhere ends the wait and leaves the map open")
    end
    -- the theme and the text size changed under it
    local ob, os = H.opt("baseTheme"), H.opt("textSize")
    if ob then H.pick(ob, (S.opt0.baseTheme == 2) and 1 or 2) end
    if os then H.pick(os, (S.opt0.textSize == 2) and 1 or 2) end
end)
Q.step(12, function()
    if not S.kmOpen then return end
    Q.check(H.kmWin() ~= nil, "the keyboard map stays open through a theme and text size change")
    RT.bounds(Q, "the keyboard map in the other theme and text size")
    local ob, os = H.opt("baseTheme"), H.opt("textSize")
    if os then H.pick(os, S.opt0.textSize) end
    if ob then H.restoreOne(ob) end
    local took = false
    pcall(function() took = KM.takeEscape() end)
    Q.check(took and H.kmWin() == nil, "the keyboard map: Escape from anywhere closes it")
end)
Q.waitFor(6, 600, H.cameBack, function(ok)
    if not S.km then return end
    local now = H.keysNow()
    local off = {}
    for nm, c in pairs(S.keys0 or {}) do if now[nm] ~= c and #off < 6 then off[#off + 1] = nm .. "=" .. tostring(now[nm]) .. "/" .. tostring(c) end end
    Q.check(#off == 0, "the keyboard map left every key binding as it was", (#off > 0) and table.concat(off, " ") or (tostring(S.nKeys) .. " bindings"))
    H.closeOut("after the keyboard map: the options and ZeD's state as at the start", ok)
end)

-- ===================================================================== 5. Options mid-play, Find typed
function H.findStep(label, text)
    Q.step(3, function()
        if not S.o then return end
        S.fe = H.errs()
        S.setOk = pcall(function() MM.pauseOpts.find:setText(text) end)
    end)
    Q.step(4, function()
        if not S.o then return end
        local w = MM.pauseOpts
        local n = #H.listRows(w)
        S.findN[label] = n
        local kept = nil
        pcall(function() kept = #tostring(w.find:getInternalText() or "") end)
        local e, f = H.errs(), H.takeFaults()
        Q.check(S.setOk and w:isVisible() and H.onScreen(w) and (S.fe == nil or e == S.fe) and #f == 0 and n <= (S.allRows or n),
            "Options, Find " .. label .. ": the window stays up and on screen, nothing thrown",
            n .. " rows, " .. tostring(kept) .. " characters kept" .. ((S.fe and e and e ~= S.fe) and (", " .. (e - S.fe) .. " new Lua errors") or "")
            .. ((#f > 0) and (", faults: " .. H.few(f, 3)) or ""))
    end)
end
Q.step(5, function()
    S.o = false
    S.menuWas = H.menuUp()
    if not (MM and MM.openOptions) then Q.check(false, "ZeD's main menu module has Options (MM.openOptions)"); S.noOpts = true; return end
    if not S.menuWas then H.toggleMenu() end
end)
Q.waitFor(10, 400, function() return S.noOpts or (H.menuUp() and MM.pauseOpts ~= nil) end, function(ok)
    if S.noOpts then return end
    Q.check(ok, "mid-play, the pause menu opens with ZeD's Options window made")
    if ok then pcall(MM.openOptions) end
end)
Q.waitFor(5, 300, function() return S.noOpts or H.optsUp() end, function(ok)
    if S.noOpts then return end
    S.o = ok and true or false
    if not Q.check(ok, "Options opens from the pause menu, mid-play") then return end
    local w = MM.pauseOpts
    S.page0 = w.pageIdx
    for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end
    w.scroll = 0
    local all = 0
    for _, pg in ipairs(w:pages()) do
        for _, r in ipairs(w:rowsFor(pg) or {}) do
            if r.kind ~= "header" and r.kind ~= "note" and r.kind ~= "desc" then all = all + 1 end
        end
    end
    S.allRows = all
end)
Q.step(6, function()
    if not S.o then return end
    S.rows0 = #H.listRows(MM.pauseOpts)
    Q.check(S.rows0 > 0 and H.onScreen(MM.pauseOpts), "Options, ZeD setup: its rows are laid out, the window on screen", S.rows0 .. " rows of " .. tostring(S.allRows))
end)
H.findStep("a word (scale)", "scale")
H.findStep("in capitals (SCALE)", "SCALE")
H.findStep("a 1500 letter text", string.rep("zqxj ", 300))
H.findStep("4000 letters with no space", string.rep("Wq", 2000))
H.findStep("a percent sign", "%")
H.findStep("pattern words (%s %d %a+)", "%s %d %a+")
H.findStep("an open bracket", "[")
H.findStep("brackets and stars ([a-z]* (.-) .*)", "[a-z]* (.-) .*")
H.findStep("anchors and a backslash (^$ \\ |)", "^$ \\ |")
H.findStep("quotes and tags", "\"'`<b>&amp;</b>{0}")
H.findStep("spaces only", "     ")
H.findStep("a tab and a line break", "a\tb\nc")
H.findStep("a word between spaces", "  scale  ")
Q.step(3, function()
    if not S.o then return end
    local a, b = S.findN["a word (scale)"], S.findN["in capitals (SCALE)"]
    Q.check(a ~= nil and a > 0 and a == b and a < (S.allRows or 0), "Options, Find: capitals find the same rows as small letters, fewer than all",
        tostring(a) .. " and " .. tostring(b) .. " of " .. tostring(S.allRows))
    Q.check(S.findN["a 1500 letter text"] == 0 and S.findN["4000 letters with no space"] == 0, "Options, Find: a text no row holds lists no rows",
        tostring(S.findN["a 1500 letter text"]) .. " and " .. tostring(S.findN["4000 letters with no space"]))
    pcall(function() MM.pauseOpts.find:setText("") end)
end)
-- a row found by its own name, changed (the live preview), then Back, Escape, Back, Discard
Q.step(4, function()
    if not S.o then return end
    local w = MM.pauseOpts
    local n = #H.listRows(w)
    Q.check(n == S.rows0, "Options, Find cleared: ZeD setup's rows come back", n .. " rows, " .. tostring(S.rows0) .. " before")
    local r = H.setupRow(w, "baseTheme")
    S.themeName = r and tostring(r.label or (r.labelKey and ZeD.tr(r.labelKey)) or "") or ""
    if S.themeName == "" then Q.skip("Options: a row found by its own name and changed", "ZeD setup has no Theme row with a name to type"); S.noRow = true; return end
    pcall(function() w.find:setText(S.themeName) end)
end)
Q.step(5, function()
    if not S.o or S.noRow then return end
    local w = MM.pauseOpts
    local el = H.opt("baseTheme").element
    local row = nil
    for _, r in ipairs(H.listRows(w)) do if r.control == el then row = r end end
    if not Q.check(row ~= nil, "Options, Find the Theme row's own name: the row is listed", "\"" .. S.themeName .. "\", " .. #H.listRows(w) .. " rows") then S.noRow = true; return end
    local was = el.selected or 1
    pcall(function() w:nudge(row, (was < #(el.options or {})) and 1 or -1) end)
    if el.selected == was then pcall(function() w:nudge(row, -1) end) end
    S.nudged = el.selected ~= was
    S.themeLive = ZeD.currentBase
    pcall(function() w:back() end)
end)
Q.step(4, function()
    if not S.o or S.noRow then return end
    local w = MM.pauseOpts
    Q.check(S.nudged and S.themeLive ~= S.base0, "Options, a found row changed: the theme previews live", tostring(S.base0) .. " to " .. tostring(S.themeLive))
    Q.check(w.confirm == "back" and H.optsUp(), "Options, Back with the change pending and Find typed: it asks first, the window stays", "confirm " .. tostring(w.confirm))
    pcall(function() w:keyEscape() end)
    local stay = (not w.confirm) and H.optsUp()
    pcall(function() w:back() end)
    Q.check(stay and w.confirm == "back", "Options, Escape on the question: back in Options with the change kept; Back asks again", "stayed " .. tostring(stay) .. ", confirm " .. tostring(w.confirm))
    pcall(function() w:discard() end)
end)
Q.step(6, function()
    if not S.o or S.noRow then return end
    local el = H.opt("baseTheme").element
    Q.check(MM.pauseView == "pause" and ZeD.currentBase == S.base0 and el.selected == S.opt0.baseTheme and H.val("baseTheme") == S.opt0.baseTheme,
        "Options, Discard: the pause menu again, the theme on screen and its control back on the stored pick",
        "view " .. tostring(MM.pauseView) .. ", theme " .. tostring(ZeD.currentBase) .. ", control " .. tostring(el.selected))
    pcall(MM.openOptions)
end)
Q.step(6, function()
    if not S.o then return end
    local w = MM.pauseOpts
    if not H.optsUp() then pcall(MM.openOptions) end
    local txt = nil
    pcall(function() txt = w.find:getInternalText() end)
    Q.check(H.optsUp() and tostring(txt or "") == "" and not w.confirm, "Options opened again: Find is empty, nothing asked", "\"" .. tostring(txt) .. "\"")
    -- typed, then closed with the words still there; opened and closed five times in one frame
    pcall(function() w.find:setText("[%") end)
    local okAll = true
    for _ = 1, 5 do
        local okp = pcall(function() w:keyEscape(); MM.openOptions() end)
        okAll = okAll and okp
    end
    pcall(function() w:keyEscape() end)
    Q.check(okAll and MM.pauseView == "pause", "Options closed with Escape and opened five times in one frame, Find typed: ends on the pause menu", "view " .. tostring(MM.pauseView))
end)
Q.step(6, function()
    if S.noOpts then return end
    local w = MM.pauseOpts
    if w and MM.pauseView == "options" then
        if w.confirm or w:anyChanged() then pcall(function() w:discardStay() end) end
        if S.page0 then w.pageIdx = S.page0 end
        pcall(function() w:back() end)
    elseif w and S.page0 then
        w.pageIdx = S.page0
    end
    if not S.menuWas and H.menuUp() then H.toggleMenu() end
end)
Q.waitFor(5, 300, function() return S.noOpts or S.menuWas or not H.menuUp() end, function(ok)
    if S.noOpts then return end
    Q.check(ok, "the pause menu shuts after Options")
    if getGameSpeed() <= 0 and not S.menuWas then pcall(setGameSpeed, 1) end
end)
Q.waitFor(10, 600, H.cameBack, function(ok)
    if S.noOpts then return end
    H.closeOut("after Options mid-play: the game plays, the options and ZeD's state as at the start", ok)
end)

-- ===================================================================== 6. the card's item gone
Q.step(5, function()
    S.goneSkip = S.noCard or H.aside() or not S.item
    if S.goneSkip then Q.skip("the card's item removed while its card shows", "no item card could be staged in this game"); return end
    pcall(RT.charTab, "loot")
    S.seekPos = nil
end)
Q.waitFor(4, 240, function() return S.goneSkip or H.cardOn(S.item) or H.seekRow(S.item) end, function(ok)
    if S.goneSkip then return end
    if not H.cardOn(S.item) then H.cardWanted() end
end)
Q.step(15, function()
    if S.goneSkip then return end
    if not H.cardOn(S.item) then Q.skip("the card's item removed while its card shows", "the pencil's card did not open again"); S.goneSkip = true; return end
    local okR = pcall(function()
        local c = S.item:getContainer()
        c:Remove(S.item)
        c:setDrawDirty(true)
    end)
    if not okR then Q.skip("the card's item removed while its card shows", "the pencil could not be removed"); S.goneSkip = true end
end)
Q.waitFor(2, 240, function()
    if S.goneSkip then return true end
    local w = RT.cw()
    return w == nil or w._drawerItem ~= S.item
end, function(ok)
    if S.goneSkip then return end
    local e, f = H.errs(), H.takeFaults()
    Q.check(ok, "the pencil removed while its card shows: the card lets go of it within 240 frames", ok and "let go" or "the card still shows the removed pencil")
    Q.check((S.err0 == nil or e == S.err0) and #f == 0, "the pencil removed while its card shows: no Lua error and no guarded fault",
        ((S.err0 and e) and ((e - S.err0) .. " new errors") or "errors not counted") .. ((#f > 0) and (" | faults: " .. H.few(f, 4)) or ""))
    S.err0 = e
    RT.bounds(Q, "after the card's item went")
    -- (the stale card is shut by hand so nothing later works a gone item)
    if not ok then pcall(function() local w = RT.cw(); if w._itemCard and w._itemCard.onBackClick then w._itemCard.onBackClick() end end) end
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    if S.faultWas and Sf.fault ~= S.faultWas then Sf.fault = S.faultWas end
    S.faultWas = nil
    -- Options and the pause menu
    pcall(function()
        local w = MM and MM.pauseOpts
        if w and MM.pauseView == "options" then
            pcall(function() w.find:setText("") end)
            if w.confirm or w:anyChanged() then w:discardStay() end
            if S.page0 then w.pageIdx = S.page0 end
            w:back()
        end
    end)
    if not S.menuWas0 and H.menuUp() then H.toggleMenu() end
    -- the keyboard map and the game's keys
    if not S.mapWas then pcall(function() KM.close(S.pn) end) elseif not H.kmWin() then pcall(function() KM.open(S.pn) end) end
    pcall(function() local w = KM.windows[S.pn]; if w then w.listening, w._heldKey, w._keysOff = nil, nil, false end end)
    pcall(function() GameKeyboard.setDoLuaKeyPressed(true) end)
    -- safe mode: the option as found, a trip of this script's taken back, its note and file gone
    pcall(function()
        local o = St.safeModeOption
        if o:getValue() ~= S.opt0.safeMode then o:setValue(S.opt0.safeMode) end
    end)
    if not S.safe0 and H.tripped() then pcall(Sf.reset) end
    H.closeNote()
    if not S.safe0 then H.emptyTripFile() end
    S.tripMine = false
    -- every option as found: the ones with a live effect through their own pick, then every value, the look
    for _, id in ipairs({ "uiScale", "inputModeLock", "glyphDisplay", "charAccent", "worldAccent" }) do
        local o = H.opt(id)
        if o and S.opt0[id] ~= nil and H.get(o) ~= S.opt0[id] then pcall(function() H.pick(o, S.opt0[id]) end) end
    end
    pcall(H.putOptions)
    pcall(Sf.reread)
    pcall(H.putLook)
    S.bad = {}
end)
Q.waitFor(10, 900, function()
    if getGameSpeed() <= 0 and not H.menuUp() then pcall(setGameSpeed, 1) end
    return H.scaleSettled() and not (H.menuUp() and not S.menuWas0)
end, function(ok)
    pcall(H.putOptions)   -- (a window that reopened may have written its own accent back)
    pcall(H.putLook)
    local now = H.readLines("ModOptions.ini")
    if S.ini0 and not H.sameLines(now, S.ini0) then S.iniWrote = H.writeIni(S.ini0) end
    if getGameSpeed() ~= 1 and not H.menuUp() then pcall(setGameSpeed, 1) end
    pcall(function() getGameTime():setMultiplier(1) end)
    if S.winsWere == false then RT.pairShut() elseif S.winsWere and not H.aside() then RT.pairOpen() end
    Q.check(ok, "put back: the scale settled and the pause menu is as found")
end)
Q.step(20, function()
    if ZEDQA_LAYOUT_BACK and S.snap then pcall(ZEDQA_LAYOUT_BACK, S.snap, "bx_opt") end
    pcall(function() if RT.cw() and RT.cw()._activeTab ~= "loot" then RT.charTab("loot") end end)
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "bx_opt") end
end)
-- every option compared with the value read at the start, a check each
Q.step(10, function()
    for _, o in ipairs(S.optAll or {}) do
        local v0, v = S.opt0[o.id], H.get(o)
        local el = o.element
        local ctl = (o.type == "combobox" and el and el.selected ~= nil) and el.selected or v
        Q.check(v == v0 and ctl == v0, "put back: option " .. tostring(o.id) .. " is the value read at the start",
            "now " .. tostring(v) .. ((ctl ~= v) and (" (its control " .. tostring(ctl) .. ")") or "") .. ", at the start " .. tostring(v0))
    end
end)
Q.step(5, function()
    local T = ZeD.T
    Q.check(ZeD.currentBase == S.base0 and ZeD.currentAccent == S.accent0 and ZeD.currentSize == S.size0 and (T == nil or T.baseKey == S.base0)
        and ZeD.currentStatus == S.look0.status and ZeD.surfaceAlpha == S.look0.a and (not (Sc and S.root0) or math.abs(Sc.root() - S.root0) < 0.001),
        "put back: the theme, accent, text size, status colors, see-through and scale on screen as found",
        tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent) .. " / " .. tostring(ZeD.currentSize) .. " / " .. tostring(ZeD.currentStatus)
        .. " / " .. tostring(ZeD.surfaceAlpha) .. " / root " .. tostring(Sc and Sc.root()))
    local md = nil
    pcall(function() md = S.p:getModData() end)
    local mdBad = {}
    for _, key in ipairs({ "ZeD_Theme", "ZeD_Gamepad" }) do
        local was, cur = (key == "ZeD_Theme") and S.mdTheme0 or S.mdPad0, md and md[key]
        if type(was) == "table" and type(cur) == "table" then
            for k, v in pairs(was) do if cur[k] ~= v then mdBad[#mdBad + 1] = key .. "." .. tostring(k) end end
            for k in pairs(cur) do if was[k] == nil then mdBad[#mdBad + 1] = key .. "." .. tostring(k) .. " (new)" end end
        elseif (was == nil) ~= (cur == nil) then
            mdBad[#mdBad + 1] = key
        end
    end
    Q.check(#mdBad == 0, "put back: the character's copies of the theme and pad picks as found", table.concat(mdBad, " "))
    local now = H.readLines("ModOptions.ini")
    if S.ini0 then
        Q.check(H.sameLines(now, S.ini0), "put back: ModOptions.ini is as found, line for line",
            tostring(now and #now) .. " lines, " .. #S.ini0 .. " before" .. (S.iniWrote and " (something wrote it during the run; written back)" or ""))
    else
        Q.skip("put back: ModOptions.ini is as found, line for line", "the file could not be read at the start")
    end
    local keys = H.keysNow()
    local off = {}
    for nm, c in pairs(S.keys0 or {}) do if keys[nm] ~= c and #off < 6 then off[#off + 1] = nm end end
    Q.check(#off == 0, "put back: every key binding as found", table.concat(off, " "))
    Q.check(H.state() == S.state0 or S.winsWere == false, "put back: ZeD's hand-back state as at the start", H.state() .. " | at the start " .. tostring(S.state0))
    Q.check(Sf.fault ~= nil and S.faultWas == nil and H.safeNote() == nil and (S.mapWas or H.kmWin() == nil) and H.menuUp() == S.menuWas0,
        "put back: safe mode's own fault counter, no note left, the keyboard map and the pause menu as found")
    Q.check(RT.isOpen() == S.winsWere or H.aside(), "put back: the windows open or shut as found")
    Q.check(getGameSpeed() == 1 or H.menuUp(), "put back: game speed 1", tostring(getGameSpeed()))
    -- the ZeD things on screen at the start are all still there (transient notices left out)
    local kinds = H.zedRoots()
    local gone = {}
    for ty in pairs(S.roots0 or {}) do
        local l = string.lower(ty)
        local passing = l:find("toast", 1, true) or l:find("bubble", 1, true) or l:find("menu", 1, true) or l:find("tip", 1, true) or l:find("notice", 1, true) or l:find("halo", 1, true)
        if not kinds[ty] and not passing then gone[#gone + 1] = ty end
    end
    if S.winsWere then Q.check(#gone == 0, "put back: every ZeD window and HUD piece on screen at the start is on screen again", table.concat(gone, ", ")) end
    RT.bounds(Q, "the end")
    local e = H.errs()
    if S.errAll0 and e then Q.check(e == S.errAll0, "the whole run: no Lua error", (e - S.errAll0) .. " new") end
    Q.check(S.nFaults == 0, "the whole run: no guarded fault reached safe mode's watchdog", S.nFaults .. " faults")
end)
Q.start()
