-- ZeDUI/tools/qa/vx_settings.lua  (Nov 21 2026, QA; tag vx_set): the in-game proof of Build's fixes for three
-- findings of the beast code sweep (ZeDUI/qa/audits/2026-11-21_beast_code_sweep.md): W35, W36, W37.
-- Built on rt_kit.lua (the global RT); run after zedqa_prelude.lua and rt_kit.lua. grep "ZEDQA vx_set". No pictures.
--
-- W35  Lite picked in ZeD setup must change the controls only, until Apply.
--      The scene: the additions stored on the Vanilla Plus set (ammo box, loadouts and the rest On), Style on Full,
--      ZeD setup open from the pause menu. The Style row is moved to Lite the way a click does it (the row's own
--      nudge, which runs the control's onChange). Then Back and Discard changes; and a second time Lite, Full again,
--      Discard in the footer.
--      Old code: the Lite pick wrote Off into every addition's stored value at once, so right after the pick, and
--      still after Discard, ZeD.Settings.ammoBoxOn() and loadoutsOn() read false and the preset read Vanilla.
--      Fixed code: the stored values never move; after Discard the controls are back On.
-- W36  A UI scale change made while paused must re-theme at once.
--      The scene: both windows open, the game paused by the pause menu, ZeD setup open. The UI scale row is moved
--      to another step. In the same frame the token table (ZeD.T.root, T.px) must be on the new root; 60 drawn
--      frames later, still paused (no game tick counted), it still is, and the windows wait shut for the resume.
--      Then Discard puts the old scale back at once; then the game's resolution event is fired with another scale
--      waiting (the Auto path of a resolution change) and the tokens must follow at once; then the game resumes and
--      the windows come back.
--      Old code: ZeD.Scale.root() moved but ZeD.T.root and T.px stayed on the old scale for as long as the game was
--      paused (text at the new zoom in rows sized for the old one), and the windows stayed open at the old size.
-- W37  On a server the game's User Panel button must come back when the belt is handed back.
--      On a server (zedqa_run -Mp): the Belt screen switch is set to the game's own; the button must show within
--      ten frames. Old code: it stayed hidden for the rest of the session.
--      In single player the real thing cannot be shown (the game makes no User Panel button and isClient() is
--      false), so that check is a SKIP; the part that can be checked is staged: for the one hand-back call a
--      stand-in button sits where the game's would and isClient answers true. Old code never showed it.
--
-- Put back: every ZeD option to the value read at the start (the stored additions were staged in memory only),
-- the scale and its re-theme, the Belt switch, the pause menu shut, the game playing, the windows open or shut as
-- found, the layout, god mode and invincible as found. The script never presses Apply. If ZeD itself saved
-- ModOptions.ini or its Custom set while the staged values were in memory, the file is written back line for line.
-- (QA review, Nov 21 2026: a file is written back only when it was read whole at the start; a read that broke
-- part way gives no lines, so a half-read file is never written over the player's. The sizes check compares 100
-- design units with what the new scale must make, so it cannot pass with the sizes left on the old scale; the
-- Discard, stored-scale and resume checks each need the tokens or the windows to have moved first, so none of
-- them passes on the old code. God mode and invincible go back in a step of their own.)

if not (RT and ZeD and ZeD.Settings and ZeD.Safe and ZeD.Scale) then
    print("ZEDQA vx_set FAIL the kit (rt_kit.lua) or ZeD's settings, safe mode or scale are not loaded")
    print("ZEDQA vx_set VERDICT FAIL 1")
    print("ZEDQA vx_set DONE")
    return
end

local Q = RT.make("vx_set")
Q.maxMs = 270000                     -- (the runner allows 7 minutes, timeout=420: past 4:30 the queue jumps to the put-back)
local S = { pn = RT.pn, p = RT.p, ticks = 0, opt0 = {}, staged = {}, nStaged = 0 }
local H = {}
local St, Sf, MM, Sc = ZeD.Settings, ZeD.Safe, ZeD.MainMenu, ZeD.Scale
local CUSTOM_FILE = "ZeD_custom_additions.txt"
-- (the style rows ZeD no longer shows: Settings.lua leaves them out when it matches the values to a preset)
local HIDDEN = { devicesStyle = true, watchStyle = true, dashStyle = true, guideStyle = true, modsStyle = true, identityStyle = true }

-- ===================================================================== helpers: the game
function H.errs() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function H.menuUp()
    local up = false
    pcall(function() up = MainScreen.instance ~= nil and MainScreen.instance:isVisible() end)
    return up
end
function H.toggleMenu() pcall(function() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end) end
function H.onTick() S.ticks = S.ticks + 1 end
-- a file's lines and how the read went: "ok", "none" (no such file) or "failed". A read that broke part way gives
-- no lines at all, so a half-read file is never written back over the whole one.
function H.readLines(name)
    local t, state = nil, "failed"
    local okAll = pcall(function()
        local r = getFileReader(name, false)
        if not r then state = "none"; return end
        local lines = {}
        local okRead = pcall(function()
            local l = r:readLine()
            while l do lines[#lines + 1] = l; l = r:readLine() end
        end)
        pcall(function() r:close() end)
        if okRead then t, state = lines, "ok" end
    end)
    if not okAll then t, state = nil, "failed" end
    return t, state
end
function H.writeLines(name, lines)
    return pcall(function()
        local w = getFileWriter(name, true, false)
        for _, l in ipairs(lines) do w:write(l .. "\r\n") end
        w:close()
    end) and true or false
end
function H.sameLines(a, b) return a ~= nil and b ~= nil and table.concat(a, "\n") == table.concat(b, "\n") end
function H.f(n) if type(n) ~= "number" then return tostring(n) end; return string.format("%.3f", n) end
function H.near(a, b) return type(a) == "number" and type(b) == "number" and math.abs(a - b) < 0.001 end
function H.list(t) if #t == 0 then return "none" end; return table.concat(t, " ") end

-- ===================================================================== helpers: ZeD's options
function H.opts() local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo end
function H.opt(id) local zo = H.opts(); return zo and zo.dict and zo.dict[id] or nil end
function H.get(o) local v = nil; pcall(function() v = o:getValue() end); return v end
function H.val(id) local o = H.opt(id); return o and H.get(o) or nil end
function H.el(id) local o = H.opt(id); return o and o.element or nil end
function H.sel(id) local e = H.el(id); return e and e.selected or nil end
function H.optsUp() local w = MM and MM.pauseOpts; return w ~= nil and w:isVisible() and MM.pauseView == "options" end
function H.setupRow(id)
    local w, el = MM and MM.pauseOpts, H.el(id)
    if not (w and el) then return nil end
    local rows = {}
    pcall(function() rows = w:zedSetupRows() end)
    for _, r in ipairs(rows) do if r.control == el then return r end end
    return nil
end
-- a control moved to item i as the player does it: the row's own left / right step in ZeD setup (which runs the
-- control's onChange, the game's handler and the option's); with no row to step, the control's onChange direct,
-- as a click on the game's own list does. Returns how it was done, or nil when the control did not take it.
function H.pickTo(id, i)
    local w, el = MM and MM.pauseOpts, H.el(id)
    if not el then return nil end
    if el.selected == i then return "already there" end
    local row = H.setupRow(id)
    if row and w then
        local n = #(el.options or {})
        for _ = 1, n do
            local was = el.selected
            if was == i then break end
            pcall(function() w:nudge(row, (i > was) and 1 or -1) end)
            if el.selected == was then break end
            if (i > was and el.selected > i) or (i < was and el.selected < i) then break end   -- (stepped over an off step)
        end
        if el.selected == i then return "the row" end
    end
    if el.disabled then return nil end
    local ok = pcall(function()
        el.selected = i
        if el.onChange then el.onChange(el.target, el, el.onChangeArgs and el.onChangeArgs[1], el.onChangeArgs and el.onChangeArgs[2]) end
    end)
    return (ok and el.selected == i) and "the control" or nil
end

-- ----- the additions (W35)
-- can the Vanilla Plus set be staged whole? (a part-staged set would read Custom, and ZeD would then save it)
function H.canStage()
    local P = St.ADDITION_PRESETS and St.ADDITION_PRESETS[2]
    if type(P) ~= "table" or not St.additionsPresetOption or not St.lookStyleOption then return false, "ZeD.Settings has no presets to read" end
    for id, v in pairs(P) do
        if not HIDDEN[id] then
            local o = H.opt(id)
            if not (o and o.values and o.values[v]) then return false, "the addition " .. tostring(id) .. " has no item " .. tostring(v) end
        end
    end
    return true
end
-- the stored values put on Vanilla Plus with Style Full, in memory only (no onChange, no save)
function H.stage()
    local P = St.ADDITION_PRESETS[2]
    local n = 0
    S.plus = P
    for id, v in pairs(P) do
        local o = H.opt(id)
        if o and o.values and o.values[v] then
            S.staged[id] = true
            if H.get(o) ~= v then o:setValue(v); n = n + 1 end
        end
    end
    local pr = St.additionsPresetOption
    if H.get(pr) ~= 2 then pr:setValue(2); n = n + 1 end
    local ls = St.lookStyleOption
    if H.get(ls) ~= 1 then ls:setValue(1); n = n + 1 end
    return n
end
-- the staged additions whose stored value is no longer the Vanilla Plus one
function H.storedOff()
    local off = {}
    for _, id in ipairs(St.ADDITION_IDS or {}) do
        if S.staged[id] and not HIDDEN[id] and H.val(id) ~= S.plus[id] then off[#off + 1] = id end
    end
    return off
end
-- the addition controls that do not show the given set (a control that is greyed out is left alone, as a pick leaves it)
function H.controlsOff(set)
    local off, n = {}, 0
    for _, id in ipairs(St.ADDITION_IDS or {}) do
        local el, v = H.el(id), set[id]
        if el and v and not HIDDEN[id] and not el.disabled then
            n = n + 1
            if el.selected ~= v then off[#off + 1] = id end
        end
    end
    return off, n
end
function H.addState()
    return "ammo box " .. tostring(St.ammoBoxOn()) .. ", loadouts " .. tostring(St.loadoutsOn()) .. ", preset stored " .. tostring(H.val("additionsPreset"))
        .. ", Style stored " .. tostring(H.val("lookStyle"))
end

-- ----- the scale (W36)
function H.cOpen() local o = false; pcall(function() o = ZeD_CharacterWindow.isOpen(S.pn) and true or false end); return o end
function H.wOpen() local o = false; pcall(function() o = ZeD_WorldWindow.isOpen(S.pn) and true or false end); return o end
function H.aside() local a = false; pcall(function() a = Sf.on("windows") and true or false end); return a end
function H.troot() return ZeD.T and ZeD.T.root or nil end
function H.px100() local v = nil; pcall(function() v = ZeD.T.px(100) end); return v end
-- what T.px(100) must be on a root (Tokens.lua applyTheme: the root times the text size's multiplier, then
-- units times that, rounded), worked out here from the root alone
function H.pxWant(root)
    if type(root) ~= "number" then return nil end
    local sz = ZeD.TextSizes and ZeD.TextSizes[ZeD.currentSize]
    local sc = root * ((sz and sz.scale) or 1)
    return math.floor(100 * sc + 0.5)
end
function H.scaleSettled() return Sc._reopenAt == nil and H.near(H.troot(), Sc.root()) end
function H.scaleSay() return "scale root " .. H.f(Sc.root()) .. ", tokens on " .. H.f(H.troot()) .. ", 100 units = " .. tostring(H.px100()) .. " px" end

-- ----- the belt (W37)
function H.eq() local e = nil; pcall(function() e = getPlayerData(S.pn).equipped end); return e end
function H.beltBy() local st = Sf._state; return st ~= nil and st.by ~= nil and st.by.belt == true end
function H.hotbar()
    local orig = Sf._originals and Sf._originals.ISHotbar
    if not (orig and ISHotbar) then return "no original kept" end
    return (ISHotbar.render == orig.render) and "the game's" or "ZeD's"
end
function H.btnVisible(b) local v = nil; pcall(function() v = b:getIsVisible() and true or false end); return v end

-- ===================================================================== 0. as found
Q.step(5, function()
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "vx_set") end
    pcall(function() S.god0, S.inv0 = S.p:isGodMod(), S.p:isInvincible() end)
    pcall(function() S.p:setGodMod(true) end)
    pcall(function() S.p:setInvincible(true) end)
    S.err0 = H.errs()
    S.speed0 = getGameSpeed()
    S.winsWere = RT.isOpen()
    S.menuWas0 = H.menuUp()
    S.ini0, S.iniState = H.readLines("ModOptions.ini")
    S.custom0, S.customState = H.readLines(CUSTOM_FILE)
    pcall(function() S.hp0 = S.p:getBodyDamage():getOverallBodyHealth() end)
    local zo = H.opts()
    S.optAll = {}
    for _, o in ipairs((zo and zo.data) or {}) do
        local v = (o.id and o.getValue and o.type ~= "multipletickbox") and H.get(o) or nil
        if v ~= nil and type(v) ~= "table" then S.opt0[o.id] = v; S.optAll[#S.optAll + 1] = o end
    end
    S.root0, S.user0 = Sc.root(), Sc.userScale
    S.safe0 = Sf.on() and true or false
    S.mp = isClient() and true or false
    Events.OnTick.Add(H.onTick)
    S.tickOn = true
    local alive = false
    pcall(function() alive = not S.p:isDead() end)
    S.go = Q.check(alive and MM ~= nil and #S.optAll > 0, "as found: ZeD's options are there (PZAPI.ModOptions ZeD_UI), the character alive",
        #S.optAll .. " options, " .. H.scaleSay() .. ", safe mode " .. tostring(S.safe0) .. ", on a server " .. tostring(S.mp)
        .. ", ModOptions.ini " .. (S.ini0 and (#S.ini0 .. " lines") or tostring(S.iniState)) .. ", health " .. tostring(S.hp0))
    if not S.go then return end
    if getGameSpeed() <= 0 and not S.menuWas0 then pcall(setGameSpeed, 1) end
    RT.pairOpen()
end)
Q.waitFor(10, 300, function() return not S.go or H.aside() or (H.cOpen() and H.wOpen()) end, function(ok)
    if not S.go then return end
    if ZEDQA_LAYOUT_SNAP then pcall(function() S.snap = ZEDQA_LAYOUT_SNAP() end) end
    if H.aside() then Q.say("the windows are with the game in this run (safe mode or the Windows switch): the window parts of W36 are skipped")
    else Q.check(ok, "the scene: the Character and World windows are open") end
    -- the additions staged (memory only), then ZeD setup from the pause menu
    local can, why = H.canStage()
    S.w35 = can and true or false
    if not can then Q.skip("W35: Lite picked in ZeD setup, then Discard", why)
    else
        S.nStaged = H.stage()
        Q.say("W35 scene: the stored additions put on Vanilla Plus with Style Full, in memory only (" .. S.nStaged .. " values moved): " .. H.addState())
    end
    if not H.menuUp() then H.toggleMenu() end
end)
Q.waitFor(10, 400, function() return not S.go or (H.menuUp() and MM.pauseOpts ~= nil) end, function(ok)
    if not S.go then return end
    S.go = Q.check(ok and MM.openOptions ~= nil, "the pause menu opens with ZeD's Options window made")
    if S.go then pcall(MM.openOptions) end
end)
Q.waitFor(5, 300, function() return not S.go or H.optsUp() end, function(ok)
    if not S.go then return end
    S.go = Q.check(ok, "ZeD's Options opens from the pause menu")
    if not S.go then return end
    local w = MM.pauseOpts
    S.page0 = w.pageIdx
    pcall(function() for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end end)
    w.scroll = 0
end)

-- ===================================================================== W35: Lite, Back, Discard changes
Q.step(6, function()
    if not (S.go and S.w35) then return end
    local w = MM.pauseOpts
    local pre = St.ammoBoxOn() and St.loadoutsOn() and H.val("lookStyle") == 1 and H.sel("lookStyle") == 1 and H.sel("ammoBox") == 2
        and H.val("additionsPreset") == 2 and #H.storedOff() == 0
    if not Q.check(pre, "W35 scene: in ZeD setup the additions are On (Vanilla Plus) and Style is Full, stored and on the controls",
        H.addState() .. ", ammo box control " .. tostring(H.sel("ammoBox")) .. ", Style control " .. tostring(H.sel("lookStyle"))) then
        S.w35 = false
        return
    end
    S.how = H.pickTo("lookStyle", 2)
    if not Q.check(S.how ~= nil and H.sel("lookStyle") == 2, "W35: the Style row moves to Lite", "moved by " .. tostring(S.how)) then S.w35 = false; return end
    -- what the pick shows: the addition controls on the Vanilla set, the change waiting for Apply
    local offC, nC = H.controlsOff(St.ADDITION_PRESETS[1])
    Q.check(#offC == 0 and nC > 0 and w:anyChanged(), "W35: Lite picked: the addition controls show the Vanilla set, waiting for Apply",
        nC .. " controls read, not on Vanilla: " .. H.list(offC) .. ", a change pending " .. tostring(w:anyChanged()))
    -- what the pick must not do: write the stored values (old code: every addition Off and the preset Vanilla, at once)
    local offS = H.storedOff()
    Q.check(St.ammoBoxOn() and St.loadoutsOn() and #offS == 0 and H.val("additionsPreset") == 2 and not St.lite(),
        "W35: Lite picked, not applied: the stored additions are still On (the ammo box and loadouts still work)",
        H.addState() .. ", stored values moved: " .. H.list(offS))
    pcall(function() w:back() end)
end)
Q.step(4, function()
    if not (S.go and S.w35) then return end
    local w = MM.pauseOpts
    Q.check(w.confirm == "back" and H.optsUp(), "W35: Back with Lite pending asks first", "confirm " .. tostring(w.confirm))
    pcall(function() w:discard() end)     -- (Discard changes)
end)
Q.step(6, function()
    if not (S.go and S.w35) then return end
    local offS = H.storedOff()
    local offC = H.controlsOff(S.plus)
    Q.check(MM.pauseView == "pause" and St.ammoBoxOn() and St.loadoutsOn() and #offS == 0 and H.val("additionsPreset") == 2,
        "W35: Lite, Back, Discard changes: the additions are back, ZeD.Settings.ammoBoxOn() and loadoutsOn() true",
        H.addState() .. ", stored values moved: " .. H.list(offS) .. ", view " .. tostring(MM.pauseView))
    Q.check(#offC == 0 and H.sel("lookStyle") == 1 and H.val("lookStyle") == 1 and not St.lite(),
        "W35: after Discard the controls read Full and Vanilla Plus again",
        "Style control " .. tostring(H.sel("lookStyle")) .. ", controls not on Vanilla Plus: " .. H.list(offC))
    -- the second way: Lite, Full again, Discard in the footer. Staged afresh so this stands on its own.
    H.stage()
    pcall(MM.openOptions)
end)
Q.waitFor(5, 300, function() return not (S.go and S.w35) or H.optsUp() end, function(ok)
    if not (S.go and S.w35) then return end
    if not Q.check(ok, "W35: Options opens again for the second way") then S.w35 = false; return end
    local w = MM.pauseOpts
    pcall(function() for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end end)
    local a = H.pickTo("lookStyle", 2)
    local b = H.pickTo("lookStyle", 1)
    local offS = H.storedOff()
    Q.check(a ~= nil and b ~= nil and St.ammoBoxOn() and St.loadoutsOn() and #offS == 0 and H.val("additionsPreset") == 2,
        "W35: Lite then Full again, nothing applied: the stored additions are still On",
        H.addState() .. ", stored values moved: " .. H.list(offS) .. ", moved by " .. tostring(a) .. " and " .. tostring(b))
    pcall(function() w:discardStay() end)   -- (Discard in the footer: the window stays)
end)
Q.step(5, function()
    if not (S.go and S.w35) then return end
    local offS, offC = H.storedOff(), H.controlsOff(S.plus)
    Q.check(H.optsUp() and St.ammoBoxOn() and St.loadoutsOn() and #offS == 0 and #offC == 0 and H.sel("lookStyle") == 1,
        "W35: Lite, Full, Discard in the footer: the additions On, stored and on the controls",
        H.addState() .. ", stored moved: " .. H.list(offS) .. ", controls off: " .. H.list(offC))
    local now = H.readLines("ModOptions.ini")
    Q.say("W35: ModOptions.ini " .. ((S.ini0 and H.sameLines(now, S.ini0)) and "is line for line as found" or "differs from the start or was not read (put back at the end)"))
end)

-- ===================================================================== W36: a scale change while paused
Q.step(4, function()
    if not S.go then return end
    local w = MM.pauseOpts
    if not H.optsUp() then pcall(MM.openOptions) end
    if w and (w.confirm or w:anyChanged()) then pcall(function() w:discardStay() end) end
    S.tk = S.ticks
end)
Q.step(30, function()
    if not S.go then return end
    S.paused = (S.ticks == S.tk)
    S.w36 = H.optsUp() and H.el("uiScale") ~= nil
    if not S.w36 then Q.check(false, "W36 scene: ZeD setup is open with its UI scale control"); return end
    Q.say("W36 scene: 30 drawn frames with the pause menu up, " .. (S.ticks - S.tk) .. " game ticks (paused " .. tostring(S.paused) .. "), game speed "
        .. tostring(getGameSpeed()) .. "; " .. H.scaleSay())
    local el = H.el("uiScale")
    S.rootA, S.pxA, S.selA = Sc.root(), H.px100(), el.selected
    S.cA, S.wA = H.cOpen(), H.wOpen()
    -- (the sizes check after the change compares with what the new scale must make: the sum is tried on the old
    -- scale first; where it does not match this build, the check falls back to the ratio and says so)
    S.pxExact = (type(S.pxA) == "number" and S.pxA == H.pxWant(S.rootA))
    if not Q.check(H.near(H.troot(), S.rootA), "W36 scene: before the change the tokens are on the scale root",
        H.scaleSay() .. " (the sum gives " .. tostring(H.pxWant(S.rootA)) .. " px)") then S.w36 = false; return end
    -- another step whose scale differs here: the nearest first
    local n = #(el.options or {})
    S.how36 = nil
    for d = 1, n do
        for _, i in ipairs({ S.selA + d, S.selA - d }) do
            if not S.how36 and i >= 1 and i <= n and not St.scaleStepOff(el, i) then
                local how = H.pickTo("uiScale", i)
                if how and math.abs(Sc.root() - S.rootA) > 0.01 then S.how36, S.selB = how, i end
            end
        end
    end
    if not S.how36 then
        Q.skip("W36: a UI scale change while paused", "no other UI scale step gives another scale on this screen")
        S.w36 = false
        pcall(function() local w = MM.pauseOpts; if w:anyChanged() then w:discardStay() end end)
        return
    end
    S.rootB, S.userB = Sc.root(), Sc.userScale
    local pxB = H.px100()
    -- in the same frame as the pick (old code: the tokens stayed on the old root until the game ran again)
    Q.check(H.near(H.troot(), S.rootB), "W36: UI scale moved in ZeD setup: the tokens are on the new scale in the same frame",
        "step " .. tostring(S.selA) .. " to " .. tostring(S.selB) .. " by " .. S.how36 .. ", root " .. H.f(S.rootA) .. " to " .. H.f(S.rootB) .. ", tokens on " .. H.f(H.troot()))
    -- (old code: 100 units stayed what the old scale made. The root moved by more than 0.01, so at 1x text or more
    -- the two sums are at least a pixel apart and the old sizes can never pass)
    local wantPx = H.pxWant(S.rootB)
    if S.pxExact then
        Q.check(pxB == wantPx, "W36: sizes follow at once: 100 design units are what the new scale makes",
            tostring(S.pxA) .. " px to " .. tostring(pxB) .. " px, the new scale makes " .. tostring(wantPx) .. " px")
    else
        local want = S.rootB / S.rootA
        local got = (type(pxB) == "number" and type(S.pxA) == "number" and S.pxA > 0) and (pxB / S.pxA) or 0
        Q.check(pxB ~= S.pxA and math.abs(got - want) < 0.03, "W36: sizes follow at once: 100 design units grew or shrank with the scale (by ratio)",
            tostring(S.pxA) .. " px to " .. tostring(pxB) .. " px, x" .. H.f(got) .. ", the scale x" .. H.f(want)
            .. " (the sum gave " .. tostring(H.pxWant(S.rootA)) .. " px on the old scale, not " .. tostring(S.pxA) .. ")")
    end
    if H.aside() or not (S.cA or S.wA) then
        Q.skip("W36: the open windows shut for the reopen", "no ZeD window was open under the pause menu")
    else
        -- (S.shutSeen: the resume check below asks that these same windows come back)
        S.shutSeen = Q.check(not H.cOpen() and not H.wOpen() and Sc._reopenAt ~= nil, "W36: the open windows are shut at once, to reopen at the new scale",
            "Character open " .. tostring(H.cOpen()) .. ", World open " .. tostring(H.wOpen()) .. ", reopen waiting " .. tostring(Sc._reopenAt ~= nil))
    end
    S.tk = S.ticks
end)
Q.step(60, function()
    if not (S.go and S.w36) then return end
    local dt = S.ticks - S.tk
    if dt ~= 0 then
        Q.skip("W36: 60 frames later, still paused", "the game ran " .. dt .. " ticks with the pause menu up (a server does not pause)")
    else
        Q.check(H.near(H.troot(), Sc.root()) and H.near(Sc.root(), S.rootB), "W36: 60 drawn frames later, still paused (no game tick): tokens and scale root agree",
            H.scaleSay())
        if not (H.aside() or not (S.cA or S.wA)) then
            Q.check(Sc._reopenAt ~= nil and not H.cOpen() and not H.wOpen(), "W36: while paused the windows wait shut (they reopen on resume)",
                "reopen waiting " .. tostring(Sc._reopenAt ~= nil) .. ", Character open " .. tostring(H.cOpen()) .. ", World open " .. tostring(H.wOpen()))
        end
    end
    -- Discard, still paused: the stored scale back, and its sizes with it. The tokens must go FROM the new scale
    -- (old code: they never left the old one, so this could not pass there)
    S.tokPre = H.troot()
    pcall(function() MM.pauseOpts:discardStay() end)
    Q.check(H.near(S.tokPre, S.rootB) and H.near(Sc.root(), S.rootA) and H.near(H.troot(), S.rootA) and H.px100() == S.pxA and H.sel("uiScale") == S.selA,
        "W36: Discard while paused: the tokens go from the new scale back to the old one at once, with their sizes",
        "tokens on " .. H.f(S.tokPre) .. " before the discard, " .. H.scaleSay() .. ", control " .. tostring(H.sel("uiScale")))
end)
-- the resolution event with another scale waiting (what a resolution change on Auto does), still paused
Q.step(6, function()
    if not (S.go and S.w36) then return end
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    S.userHeld = true
    Sc.userScale = S.userB
    local ok, err = pcall(triggerEvent, "OnResolutionChange", sw, sh, sw, sh)
    local r, t = Sc.root(), H.troot()
    Q.check(ok and H.near(r, S.rootB) and H.near(t, S.rootB), "W36: the game's resolution event with another scale waiting: the tokens follow at once",
        "root " .. H.f(r) .. ", tokens on " .. H.f(t) .. ", wanted " .. H.f(S.rootB) .. (ok and "" or (", threw " .. tostring(err))))
    S.tokPre2 = H.troot()
    Sc.userScale = S.user0
    S.userHeld = false
    pcall(St.applyScale)       -- (the stored step again, as Discard does it)
    Q.check(H.near(S.tokPre2, S.rootB) and H.near(Sc.root(), S.rootA) and H.near(H.troot(), S.rootA),
        "W36: the stored scale applied again while paused: the tokens go from the waiting scale back to the one as found",
        "tokens on " .. H.f(S.tokPre2) .. " before, " .. H.scaleSay())
end)
-- leave Options and the pause menu; the game resumes and the windows come back
Q.step(4, function()
    if not S.go then return end
    local w = MM.pauseOpts
    if w and MM.pauseView == "options" then
        if w.confirm or w:anyChanged() then pcall(function() w:discardStay() end) end
        if S.page0 then w.pageIdx = S.page0 end
        pcall(function() w:back() end)
    end
    if not S.menuWas0 and H.menuUp() then H.toggleMenu() end
end)
Q.waitFor(5, 300, function() return not S.go or S.menuWas0 or not H.menuUp() end, function(ok)
    if not S.go then return end
    Q.check(ok, "the pause menu shuts after Options")
    if getGameSpeed() <= 0 and not S.menuWas0 then pcall(setGameSpeed, 1) end
    S.tk = S.ticks
end)
Q.waitFor(2, 900, function()
    if not (S.go and S.w36) then return true end
    if S.ticks == S.tk then return false end
    if not H.scaleSettled() then return false end
    if H.aside() then return true end
    return (not S.cA or H.cOpen()) and (not S.wA or H.wOpen())
end, function(ok)
    if not (S.go and S.w36) then return end
    local dt = S.ticks - S.tk
    if H.aside() or not (S.cA or S.wA) then
        Q.check(ok, "W36: after the resume the scale is settled", dt .. " game ticks, " .. H.scaleSay())
    else
        -- (the fix's whole round: shut at once for the new scale while paused, back on the resume. Old code never shut
        -- them, it left them at the old size, so this needs the shut seen above as well)
        Q.check(ok and dt <= 45 and S.shutSeen == true and H.near(Sc.root(), S.rootA),
            "W36: the windows the paused change shut come back within 45 game ticks of the resume, at the scale as found",
            dt .. " ticks, shut while paused " .. tostring(S.shutSeen) .. ", Character open " .. tostring(H.cOpen()) .. ", World open "
            .. tostring(H.wOpen()) .. ", " .. H.scaleSay())
    end
    RT.bounds(Q, "after the paused scale change")
end)

-- ===================================================================== W37: the User Panel button
Q.step(10, function()
    if not S.go then return end
    local eq = H.eq()
    local o = St.screenOptions and St.screenOptions.belt
    S.w37 = eq ~= nil and o ~= nil
    if not S.w37 then Q.skip("W37: the User Panel button after the belt is handed back", "no left column or no Belt screen switch in this game"); return end
    if Sf.on("belt") then
        Q.skip("W37: the User Panel button after the belt is handed back", "the belt is already with the game in this run (safe mode or its switch)")
        S.w37 = false
        return
    end
    S.belt0 = H.get(o)
    S.hot0 = H.hotbar()
    -- (the column the hand-back shows: put back, it must show or hide as now; ZeD hides it again 30 frames after it
    -- takes the belt back, in single player without -debug)
    pcall(function() S.col0 = eq:getIsVisible() and true or false end)
    if S.mp and not eq.clientBtn then
        Q.skip("W37: the User Panel button after the belt is handed back", "on a server, but the game made no User Panel button")
        S.w37 = false
    end
end)
-- on a server: the real thing
Q.waitFor(2, 180, function()
    if not (S.go and S.w37 and S.mp) then return true end
    return H.btnVisible(H.eq().clientBtn) == false
end, function(ok)
    if not (S.go and S.w37 and S.mp) then return end
    if not Q.check(ok, "W37 scene (server): with ZeD's belt on, the game's User Panel button is hidden") then S.w37 = false; return end
    S.beltHeld = true
    pcall(function() St.screenOptions.belt:setValue(2) end)
    pcall(Sf.reread)
end)
Q.step(10, function()
    if not (S.go and S.w37 and S.mp) then return end
    -- (old code: still hidden, and the game's own prerender never shows it again)
    Q.check(H.beltBy() and H.btnVisible(H.eq().clientBtn) == true, "W37 (server): the belt handed back to the game: the User Panel button shows within 10 frames",
        "belt handed back " .. tostring(H.beltBy()) .. ", button visible " .. tostring(H.btnVisible(H.eq().clientBtn)))
    pcall(function() St.screenOptions.belt:setValue(S.belt0) end)
    pcall(Sf.reread)
    S.beltHeld = false
end)
Q.waitFor(2, 180, function()
    if not (S.go and S.w37 and S.mp) then return true end
    return H.btnVisible(H.eq().clientBtn) == false
end, function(ok)
    if not (S.go and S.w37 and S.mp) then return end
    Q.check(ok and not H.beltBy(), "W37 (server): ZeD's belt taken over again: the button is ZeD's to hide once more", "hotbar drawing " .. H.hotbar())
end)
-- single player: the real thing cannot be shown; the hand-back call is staged
Q.step(4, function()
    if not (S.go and S.w37) or S.mp then return end
    Q.skip("W37: on a server, the User Panel button shows again after the belt is handed back",
        "single player: the game makes no User Panel button and isClient() is false; run on the local test server (zedqa_run -Mp)")
    local eq = H.eq()
    local o = St.screenOptions.belt
    if eq.clientBtn ~= nil then Q.skip("W37 staged: the hand-back call with a stand-in button", "the column already has a User Panel button"); return end
    local function stand()
        local b = { vis = false, calls = 0 }
        function b.setVisible(self, v) self.vis = v and true or false; self.calls = self.calls + 1 end
        function b.getIsVisible(self) return self.vis end
        function b.isVisible(self) return self.vis end
        function b.setImage() end
        return b
    end
    -- 1) as single player really is: the hand-back must leave a button there alone (the fix is for a server only)
    local b1 = stand()
    S.beltHeld = true
    eq.clientBtn = b1
    pcall(function() o:setValue(2); Sf.reread() end)
    local by1 = H.beltBy()
    eq.clientBtn = nil
    pcall(function() o:setValue(S.belt0); Sf.reread() end)
    -- 2) as on a server: isClient answers true for the one hand-back call
    local b2 = stand()
    eq.clientBtn = b2
    S.isClient0 = isClient
    pcall(function()
        isClient = function() return true end
        o:setValue(2)
        Sf.reread()
    end)
    isClient = S.isClient0
    S.isClient0 = nil
    local by2 = H.beltBy()
    eq.clientBtn = nil
    pcall(function() o:setValue(S.belt0); Sf.reread() end)
    S.beltHeld = false
    if not (by1 and by2) then
        Q.skip("W37 staged: the hand-back call with a stand-in button", "the Belt switch did not hand the belt back in this game (" .. tostring(by1) .. ", " .. tostring(by2) .. ")")
        return
    end
    -- (old code: the hand-back showed the hands and the column and never the button: shown false, 0 calls)
    Q.check(b2.vis == true and b2.calls >= 1, "W37 staged (stand-in button, isClient true for the one call): the belt's hand-back shows the User Panel button",
        "shown " .. tostring(b2.vis) .. ", " .. b2.calls .. " calls")
    Q.check(b1.calls == 0, "W37 staged: in single player the hand-back leaves that button alone", b1.calls .. " calls")
end)
Q.step(10, function()
    if not (S.go and S.w37) or S.mp then return end
    Q.check(not H.beltBy() and H.hotbar() == S.hot0 and H.eq().clientBtn == nil and isClient() == false,
        "W37 staged: afterwards the belt is ZeD's again, the stand-in gone, isClient the game's own",
        "belt handed back " .. tostring(H.beltBy()) .. ", hotbar drawing " .. H.hotbar() .. " (" .. tostring(S.hot0) .. " before)")
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    -- the game's own isClient and the column, whatever threw
    if S.isClient0 then isClient = S.isClient0; S.isClient0 = nil end
    pcall(function() local eq = H.eq(); if eq and type(eq.clientBtn) == "table" and eq.clientBtn.calls ~= nil then eq.clientBtn = nil end end)
    if S.userHeld then Sc.userScale = S.user0; S.userHeld = false end
    -- Options and the pause menu
    pcall(function()
        local w = MM and MM.pauseOpts
        if w and MM.pauseView == "options" then
            if w.confirm or w:anyChanged() then w:discardStay() end
            if S.page0 then w.pageIdx = S.page0 end
            w:back()
        end
    end)
    if not S.menuWas0 and H.menuUp() then H.toggleMenu() end
    -- every option's stored value as found (the staged additions, the preset, Style, the Belt switch)
    for _, o in ipairs(S.optAll or {}) do
        local v0 = S.opt0[o.id]
        if v0 ~= nil and H.get(o) ~= v0 then pcall(function() o:setValue(v0) end) end
    end
    pcall(function() if St.forgetHeldCustom then St.forgetHeldCustom() end end)
    pcall(Sf.reread)
    pcall(St.applyScale)       -- (the stored UI scale, and its re-theme)
end)
Q.waitFor(10, 900, function()
    if H.menuUp() and not S.menuWas0 then
        -- (still up: once a second, Options left again and the menu shut again, so the game is never left paused)
        S.menuWait = (S.menuWait or 0) + 1
        if S.menuWait >= 60 then
            S.menuWait = 0
            pcall(function()
                local w = MM and MM.pauseOpts
                if w and MM.pauseView == "options" then
                    if w.confirm or w:anyChanged() then w:discardStay() end
                    w:back()
                end
            end)
            if H.menuUp() then H.toggleMenu() end
        end
        return false
    end
    if getGameSpeed() <= 0 and not H.menuUp() then pcall(setGameSpeed, 1) end
    return H.scaleSettled()
end, function(ok)
    Q.check(ok, "put back: the pause menu is as found and the scale settled", H.scaleSay() .. ", game speed " .. tostring(getGameSpeed()))
    for _, o in ipairs(S.optAll or {}) do
        local v0 = S.opt0[o.id]
        if v0 ~= nil and H.get(o) ~= v0 then pcall(function() o:setValue(v0) end) end
    end
    -- the two files, only when ZeD saved them while the staged values were in memory, and only from a whole read at
    -- the start and a whole read now (a read that failed writes nothing)
    local now, nowState = H.readLines("ModOptions.ini")
    if S.iniState == "ok" and nowState == "ok" and not H.sameLines(now, S.ini0) then
        local wrote = H.writeLines("ModOptions.ini", S.ini0)
        Q.say("put back: ModOptions.ini had changed during the run; written back line for line (" .. tostring(wrote) .. ")")
    end
    local cnow, cState = H.readLines(CUSTOM_FILE)
    if S.customState == "ok" and cState == "ok" and not H.sameLines(cnow, S.custom0) then
        Q.say("put back: " .. CUSTOM_FILE .. " had changed during the run; written back line for line (" .. tostring(H.writeLines(CUSTOM_FILE, S.custom0)) .. ")")
    elseif S.customState == "none" and cState == "ok" then
        Q.say("put back: " .. CUSTOM_FILE .. " was made during the run (there was none); emptied, which reads the same as none (" .. tostring(H.writeLines(CUSTOM_FILE, {})) .. ")")
    end
    if S.speed0 and S.speed0 > 0 and getGameSpeed() ~= S.speed0 and not H.menuUp() then pcall(setGameSpeed, S.speed0) end
    if S.winsWere == false then RT.pairShut() elseif S.winsWere and not H.aside() then RT.pairOpen() end
end)
Q.step(20, function()
    if ZEDQA_LAYOUT_BACK and S.snap then pcall(ZEDQA_LAYOUT_BACK, S.snap, "vx_set") end
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "vx_set") end
    if S.tickOn then Events.OnTick.Remove(H.onTick); S.tickOn = false end
end)
-- the character's two switches as found, in a step of their own (a throw in the checks below cannot skip them).
-- Nothing here can hurt him; no heal is called.
Q.step(2, function()
    pcall(function() if S.inv0 ~= nil then S.p:setInvincible(S.inv0 and true or false) end end)
    pcall(function() if S.god0 ~= nil then S.p:setGodMod(S.god0 and true or false) end end)
end)
Q.step(10, function()
    local off = {}
    for _, o in ipairs(S.optAll or {}) do
        local v0 = S.opt0[o.id]
        if v0 ~= nil then
            local el = o.element
            if H.get(o) ~= v0 then off[#off + 1] = o.id .. " stored " .. tostring(H.get(o)) .. " (was " .. tostring(v0) .. ")"
            elseif o.type == "combobox" and el and el.selected ~= v0 then off[#off + 1] = o.id .. " control " .. tostring(el.selected) .. " (stored " .. tostring(v0) .. ")" end
        end
    end
    Q.check(#off == 0, "put back: every ZeD option, stored and on its control, is as found", (#off == 0) and (#(S.optAll or {}) .. " options") or table.concat(off, "; "))
    Q.check(H.near(Sc.root(), S.root0) and H.near(H.troot(), S.root0) and Sc.userScale == S.user0, "put back: the UI scale and the tokens are as found",
        H.scaleSay() .. " (root " .. H.f(S.root0) .. " at the start)")
    local now, nowState = H.readLines("ModOptions.ini")
    if S.iniState == "ok" then
        Q.check(nowState == "ok" and H.sameLines(now, S.ini0), "put back: ModOptions.ini is line for line as found", (now and #now or 0) .. " lines, read " .. tostring(nowState))
    else
        Q.skip("put back: ModOptions.ini is line for line as found", "the file was not read whole at the start (" .. tostring(S.iniState) .. ")")
    end
    Q.check((Sf.on() and true or false) == S.safe0 and (S.belt0 == nil or H.val("screenBelt") == S.opt0.screenBelt) and isClient() == S.mp,
        "put back: safe mode and the Belt switch as found", "safe mode " .. tostring(Sf.on()) .. ", hotbar drawing " .. H.hotbar())
    if S.col0 ~= nil then
        local cv = nil
        pcall(function() cv = H.eq():getIsVisible() and true or false end)
        Q.check(cv == S.col0 and H.hotbar() == S.hot0, "put back: the game's left-edge column shows or hides as it did before the belt was handed back",
            "showing " .. tostring(cv) .. " (" .. tostring(S.col0) .. " before), hotbar drawing " .. H.hotbar())
    end
    local e = H.errs()
    Q.check(S.err0 == nil or e == S.err0, "no new Lua error during the run", (S.err0 and e) and ((e - S.err0) .. " new") or "errors not counted")
    -- the character: never hurt here (god mode and invincible were on throughout; the step above put them back)
    local alive, hp, god, inv = false, nil, nil, nil
    pcall(function() alive = not S.p:isDead(); hp = S.p:getBodyDamage():getOverallBodyHealth() end)
    pcall(function() god = S.p:isGodMod(); inv = S.p:isInvincible() end)
    local healthy = (S.hp0 == nil or (type(hp) == "number" and hp >= S.hp0 - 1))
    Q.check(alive and healthy and (S.god0 == nil or god == S.god0) and (S.inv0 == nil or inv == S.inv0),
        "put back: the character is alive, no less healthy than at the start, god mode and invincible as found",
        "health " .. tostring(hp) .. " (" .. tostring(S.hp0) .. " at the start), god mode " .. tostring(god) .. " (was " .. tostring(S.god0)
        .. "), invincible " .. tostring(inv) .. " (was " .. tostring(S.inv0) .. ")")
    Q.check(S.winsWere == nil or H.aside() or RT.isOpen() == S.winsWere, "put back: the windows are open or shut as found", "open " .. tostring(RT.isOpen()))
end)
Q.start()
