-- ZeDUI/tools/qa/bx_scale.lua  (Nov 21 2026, QA beast day; tag bx_scl): live look and size changes while both
-- windows, an item card, a right-click menu and the HUD are up. Built on rt_kit.lua (the global RT); run after
-- zedqa_prelude.lua and rt_kit.lua. grep "ZEDQA bx_scl". No pictures.
--
-- The scene: the pair open on Loot, a bat's card opened in the Character window's drawer (a click on its row), then
-- ZeD's right-click menu opened on a tool's row. The menu acts on the row under the pointer, which becomes the
-- selection first, so the card follows to the tool (ZeD_CharacterWindow.lua content.onRightMouseUp, _rmbMenuItems,
-- updateDrawer): the scene every change meets is the menu open on the tool with the tool's card beside it.
-- (Nov 21 2026, the first run: the script wanted the card "on the bat or gone" and failed 31 times on a card that
-- was rightly on the tool.) Then one change at a time, each set on ZeD's own option and handed to the
-- option's own handlers (onChange, then onChangeApply: the live preview and the Apply of ZeD setup):
--   UI scale      every step, Auto and the seven fixed ones, in an odd order (0.5x is retired: it draws at the floor;
--                 a step above what fits this screen draws at the cap)
--   Text size     Large, Small (the list has two sizes: "Normal" was retired with the medium preset)
--   Theme         Light, High contrast, Dark
--   Accent        all nine
--   Status colors color-blind set, standard
--   See-through   every step in Dark, and the lowest one in Light (Light draws solid whatever it says)
--   Style         Lite, Full (the value only, as zedqa_style_lite.lua: the option's handler would also move the
--                 additions to the Vanilla preset and write a file)
--   Window accent four pairs of Character / World accents, "Same as Accent color" among them
--   fringe        Large + High contrast + Lite + 2x in one frame; a resolution change with both windows twice the
--                 screen and half off it (the zedqa_break_reschange.lua way) in that look; every scale step, theme
--                 and text size fired in one frame; the window key pressed while the windows are mid-reopen from a
--                 scale change; a scale change with the pair shut, then the pair opened
-- After each change: the look ZeD reports matches the options (theme, accent, size, status set, scale, see-through,
-- Style); the root scale is the one ZeD.Scale works out, inside the cap; both windows are open; RT.bounds on every
-- ZeD root; after a UI scale step each window is as tall in design units as before it (the windows reopen from
-- design units); the card is still on the item it was on before the change (the tool) or cleanly gone, the menu still on
-- the tool or cleanly gone (never stale, never moved to another item); a tab switch works in
-- both windows (a different tab each time); the HUD pieces seen at the start are still up (Full only); no new Lua
-- error; back on Loot the windows do not lie over each other.
-- Also: "Reset both windows" (ZeD_Window.resetLayout) with a tab open in each window leaves both on Loot.
-- Put back: every ZeD option to the value read at the start (compared one by one), the look re-applied, the window
-- accents, the layout (ZEDQA_LAYOUT_BACK), a tab only where its drawer was open at the start, the pair open or shut
-- as found, the things given taken back.
-- The character: nothing here can hurt him, and god mode and invincible are on for the whole run all the same (put
-- back as found at the end); his body is read at the start and again in the put-back (health, every body part,
-- infection, fractures, alive): one line says whether he was whole when the run ended, one whether the put-back leaves
-- him whole, healing him first if anything is wrong. It runs even when the start failed.
-- The script never writes ModOptions.ini itself (ZeD's own layout reset saves the options as they stand in memory).

if not RT then
    print("ZEDQA bx_scl ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA bx_scl VERDICT FAIL 1")
    print("ZEDQA bx_scl DONE")
    return
end

local Q = RT.make("bx_scl")
Q.maxMs = 400000   -- (the budget is 8 minutes: past 6:40 the queue jumps to the put-back)
local S = { p = RT.p, pn = RT.pn, dead = false, ticks = 0, tick0 = 0, t0 = 0, needTicks = 6, k = 0, opt0 = {}, hud0 = nil }
local H = {}

local function step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
local function waitFor(n, max, cond, fn)
    Q.waitFor(n, max, function() if S.dead then return true end; return cond() end,
        function(ok) if S.dead then return end; fn(ok) end)
end

-- ===================================================================== helpers: options
function H.opts() local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo end
function H.opt(id) local zo = H.opts(); return zo and zo.dict and zo.dict[id] or nil end
function H.val(id) local o = H.opt(id); local v = nil; pcall(function() v = o:getValue() end); return v end
-- a pick as ZeD setup makes it: the value, the live preview (onChange), the Apply (onChangeApply). quiet: the value only
function H.set(id, i, quiet)
    local o = H.opt(id)
    if not o then error("no ZeD option " .. tostring(id)) end
    o:setValue(i)
    if quiet then return end
    if o.onChange then o.onChange(o, i) end
    if o.onChangeApply then o.onChangeApply(o, i) end
end
function H.errs() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function H.readIni()
    local t = nil
    pcall(function()
        local r = getFileReader("ModOptions.ini", false)
        if not r then return end
        t = {}
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        r:close()
    end)
    return t
end
function H.near(a, b) return type(a) == "number" and type(b) == "number" and math.abs(a - b) < 0.001 end

-- ===================================================================== helpers: the character's safety
-- (Java calls checked with javap, 42.22: IsoGameCharacter isGodMod(), setGodMod(boolean), isInvincible(),
-- setInvincible(boolean), isDead(), getBodyDamage(); BodyDamage getOverallBodyHealth(), IsInfected(), getBodyParts(),
-- RestoreToFullHealth(), setInfected(boolean); BodyPart HasInjury(), bleeding(), getFractureTime(),
-- setFractureTime(float), SetInfected(boolean), RestoreToFullHealth())
function H.safeOn()
    local p = S.p
    if not p then return end
    S.safe = {}
    pcall(function() S.safe.god = p:isGodMod() end)
    pcall(function() S.safe.inv = p:isInvincible() end)
    pcall(function() p:setGodMod(true) end)
    pcall(function() p:setInvincible(true) end)
end
-- what is wrong with him now: a list of words, empty when he is whole
function H.hurt()
    local p = S.p
    local bad = {}
    if not p then return { "no character" } end
    local dead = false
    pcall(function() dead = p:isDead() end)
    if dead then bad[#bad + 1] = "dead" end
    local ok, err = pcall(function()
        local bd = p:getBodyDamage()
        local hp = bd:getOverallBodyHealth()
        if hp < 99.9 then bad[#bad + 1] = "health " .. tostring(hp) end
        if bd:IsInfected() then bad[#bad + 1] = "infected" end
        local parts = bd:getBodyParts()
        local hurtN, fracN, bleedN = 0, 0, 0
        for i = 0, parts:size() - 1 do
            local b = parts:get(i)
            if b:HasInjury() then hurtN = hurtN + 1 end
            if b:getFractureTime() > 0 then fracN = fracN + 1 end
            if b:bleeding() then bleedN = bleedN + 1 end
        end
        if hurtN > 0 then bad[#bad + 1] = hurtN .. " wounded parts" end
        if fracN > 0 then bad[#bad + 1] = fracN .. " fractures" end
        if bleedN > 0 then bad[#bad + 1] = bleedN .. " bleeding parts" end
    end)
    if not ok then bad[#bad + 1] = "his body could not be read: " .. tostring(err) end
    return bad
end
function H.heal()
    local p = S.p
    if not p then return end
    pcall(function()
        local bd = p:getBodyDamage()
        local parts = bd:getBodyParts()
        for i = 0, parts:size() - 1 do
            local b = parts:get(i)
            pcall(function() b:setFractureTime(0) end)
            pcall(function() b:SetInfected(false) end)
            pcall(function() b:RestoreToFullHealth() end)
        end
        pcall(function() bd:setInfected(false) end)
        pcall(function() bd:RestoreToFullHealth() end)
    end)
end
-- the put-back's last word on him, two lines that each say one thing: was he whole when the run ended (nothing here
-- may hurt him, and god mode heals him on every update), and is he whole after the put-back (healed first, god mode
-- and invincible ON, if anything was wrong). Then god mode and invincible as found, or left ON if he is not whole.
function H.safeBack()
    if not S.p then Q.check(false, "put back: the character is alive and unhurt", "no character"); return end
    local was = H.hurt()
    local start = (S.hurt0 == nil) and "not read at the start"
        or ((#S.hurt0 == 0) and "whole at the start" or ("at the start: " .. table.concat(S.hurt0, ", ")))
    Q.check(#was == 0, "the character is whole at the end of the run (god mode and invincible on)",
        ((#was == 0) and "whole" or table.concat(was, ", ")) .. "; " .. start)
    if #was > 0 then
        pcall(function() S.p:setGodMod(true) end)
        pcall(function() S.p:setInvincible(true) end)
        H.heal()
    end
    local now = H.hurt()
    Q.check(#now == 0, "put back: the character is alive and unhurt (health 100, no wound, no fracture, not infected, not dead)",
        (#now == 0) and ((#was == 0) and "whole" or "whole after the heal") or ("after the heal: " .. table.concat(now, ", ")))
    local sf = S.safe
    if sf and #now == 0 then
        if sf.inv ~= nil then pcall(function() S.p:setInvincible(sf.inv and true or false) end) end
        if sf.god ~= nil then pcall(function() S.p:setGodMod(sf.god and true or false) end) end
        local g, iv = nil, nil
        pcall(function() g = S.p:isGodMod() end)
        pcall(function() iv = S.p:isInvincible() end)
        Q.check((sf.god == nil or g == sf.god) and (sf.inv == nil or iv == sf.inv), "put back: god mode and invincible as found",
            "god mode " .. tostring(g) .. " (was " .. tostring(sf.god) .. "), invincible " .. tostring(iv) .. " (was " .. tostring(sf.inv) .. ")")
    elseif #now > 0 then
        Q.say("note god mode and invincible are left ON: the character is not whole")
    end
end

-- ===================================================================== helpers: the list, the card, the menu
function H.cc() local w = RT.cw(); return w and w._mainContent end
function H.rowZone(item)
    local c = H.cc()
    for _, z in ipairs((c and c._hitZones) or {}) do if z.id == item then return z end end
    return nil
end
-- (a condition, every frame: the row drawn last frame, else the list one step further down; wraps at the end)
function H.seekRow(item)
    local c = H.cc()
    if not c then return false end
    if H.rowZone(item) then return true end
    local sc = c._scroll
    if sc and sc.setScrollPos then
        S.seekPos = (S.seekPos or -0.1) + 0.1
        if S.seekPos > 1.001 then S.seekPos = 0 end
        pcall(function() sc:setScrollPos(S.seekPos) end)
    end
    return false
end
function H.click(item)
    local c, z = H.cc(), H.rowZone(item)
    if not (c and z) then return false end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    local ok, err = pcall(function() c:onMouseDown(x, y); c:onMouseUp(x, y) end)
    if not ok then Q.check(false, "a click on a row ran without an error", err) end
    return ok
end
function H.rightClick(item)
    local c, z = H.cc(), H.rowZone(item)
    if not (c and z) then return false end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    local ok, err = pcall(function() c:onRightMouseDown(x, y); c:onRightMouseUp(x, y) end)
    if not ok then Q.check(false, "a right-click on a row ran without an error", err) end
    return ok
end
function H.cardOn(item)
    local w = RT.cw()
    local c = w and w._itemCard
    return item ~= nil and w ~= nil and w._drawerItem == item and c ~= nil and c.item == item
end
function H.menu()
    local m = nil
    pcall(function() local v = getPlayerContextMenu(S.pn); m = v and v._zedMenu end)
    if m and m._ctx and m._ctx.open ~= false then return m end
    return nil
end
function H.closeMenu()
    local m = H.menu()
    if m then pcall(function() m:close() end) end
end
function H.menuHas(m, item)
    local has = false
    pcall(function()
        local t = m._ctx.target
        if t == item then has = true end
        for _, x in ipairs(type(t) == "table" and t or {}) do if x == item then has = true end end
    end)
    return has
end
function H.itemName(it)
    if it == nil then return "nothing" end
    if it == S.tool then return "the tool" end
    if it == S.bat then return "the bat" end
    return tostring(it)
end
-- the card after a change: still on the item it was on before the change (want: the tool, as the right-click took it
-- there), that item still in a container and the card drawing the drawer's item; or cleanly gone. Anything else is
-- stale, a card that moved to another item too (QA review, Nov 21: "on the tool or the bat" let a card that jumped
-- from the tool to the bat pass)
function H.cardState(want)
    local w = RT.cw()
    if not w then return "no Character window", false end
    local di = w._drawerItem
    if di == nil then return "closed", true end
    local held = false
    pcall(function() held = di:getContainer() ~= nil end)
    local c = w._itemCard
    if want ~= nil and di == want and c ~= nil and c.item == di and held then return "on " .. H.itemName(di), true end
    return "stale (drawer item " .. H.itemName(di) .. ", card item " .. H.itemName(c and c.item) .. ", held " .. tostring(held) .. ")", false
end
function H.menuState()
    local m = H.menu()
    if not m then return "closed", true end
    if H.menuHas(m, S.tool) then return "open on the tool (" .. tostring(m.Type) .. ")", true end
    return "stale (" .. tostring(m.Type) .. " open on something else)", false
end
-- the list's levels inside the screen (the list is a full-screen layer, which RT.bounds leaves out)
function H.levelsOk(m)
    local W, H2 = getCore():getScreenWidth(), getCore():getScreenHeight()
    local bad = {}
    for i, lv in ipairs(m._levels or {}) do
        if lv.x < -1 or lv.y < -1 or lv.x + lv.w > W + 1 or lv.y + lv.h > H2 + 1 then
            bad[#bad + 1] = "level " .. i .. " at " .. math.floor(lv.x) .. "," .. math.floor(lv.y) .. " " .. math.floor(lv.w) .. "x" .. math.floor(lv.h)
        end
    end
    return #bad == 0, table.concat(bad, "; ")
end

-- ===================================================================== helpers: windows, tabs, the HUD
function H.geo(w) return math.floor(w:getX()) .. "," .. math.floor(w:getY()) .. " " .. math.floor(w:getWidth()) .. "x" .. math.floor(w:getHeight()) end
function H.pickTab(strip, k)
    local ids = {}
    for _, id in ipairs(RT.tabs(strip)) do if id ~= "loot" then ids[#ids + 1] = id end end
    if #ids == 0 then return nil end
    return ids[k - math.floor(k / #ids) * #ids + 1]
end
-- how many Character and World windows are on screen (one each, never two)
function H.winCount()
    local nc, nw = 0, 0
    for _, r in ipairs(RT.roots()) do
        local vis = false
        pcall(function() vis = r.e:isVisible() end)
        if vis and type(r.t) == "table" then
            if r.t._tabStripPanel ~= nil then nc = nc + 1 end
            if r.t._actionTabStrip ~= nil then nw = nw + 1 end
        end
    end
    return nc, nw
end
-- the HUD: every visible ZeD root that is not one of the two windows or the menu, counted by Type
function H.hud()
    local out, n = {}, 0
    local cw, ww, m = RT.cw(), RT.ww(), H.menu()
    for _, r in ipairs(RT.roots()) do
        local vis = false
        pcall(function() vis = r.e:isVisible() end)
        if vis and RT.isZeD(r.t) and r.t ~= cw and r.t ~= ww and r.t ~= m then
            local ty = tostring(r.t.Type)
            out[ty] = (out[ty] or 0) + 1
            n = n + 1
        end
    end
    return out, n
end
function H.hudCheck(label)
    if not S.hud0 then return end
    local now, n = H.hud()
    if ZeD.Settings.lite() then Q.say("note " .. label .. ": " .. n .. " ZeD HUD roots up in Lite (not compared: Lite has its own HUD)"); return end
    local gone = {}
    for ty, c in pairs(S.hud0) do
        if (now[ty] or 0) < c then gone[#gone + 1] = ty .. " " .. (now[ty] or 0) .. "/" .. c end
    end
    Q.check(#gone == 0, label .. ": the HUD pieces seen at the start are still up", (#gone == 0) and (n .. " roots") or ("fewer: " .. table.concat(gone, ", ")))
end
function H.overlap()
    local c, w = RT.cw(), RT.ww()
    if not (c and w) then return true end
    local apartX = c:getX() + c:getWidth() <= w:getX() + 1 or w:getX() + w:getWidth() <= c:getX() + 1
    local apartY = c:getY() + c:getHeight() <= w:getY() + 1 or w:getY() + w:getHeight() <= c:getY() + 1
    return not (apartX or apartY)
end

-- ===================================================================== helpers: the look
function H.rootSettled()
    local Sc = ZeD.Scale
    if Sc._reopenAt ~= nil then return false end
    local a = Sc._appliedRoot
    return a ~= nil and H.near(a, Sc.compute()) and H.near(Sc.root(), a)
end
function H.bothUp()
    local c, w = RT.cw(), RT.ww()
    return c ~= nil and w ~= nil and c:isVisible() and w:isVisible() and H.cc() ~= nil
end
function H.settled()
    if S.ticks - S.tick0 < S.needTicks then return false end
    if getTimestampMs() - S.t0 < 300 then return false end
    if not H.rootSettled() then return false end
    if S.wantOpen == false then return true end
    return H.bothUp()
end
function H.arm0(need)
    S.tick0, S.t0, S.needTicks, S.e0 = S.ticks, getTimestampMs(), need or 6, H.errs()
end
-- what the options say the look is
function H.expect()
    local St = ZeD.Settings
    local e = {}
    e.base = St.baseKeys[H.val("baseTheme") or 1]
    e.accent = St.accentKeys[H.val("accentColor") or 0]
    e.size = St.sizeKeys[H.val("textSize") or 1]
    e.status = St.statusKeys[H.val("statusColors") or 1]
    local sv = St.scaleKeys[H.val("uiScale") or 1]
    e.user = (type(sv) == "number") and sv or nil
    e.see = (St.seeThroughKeys[H.val("seeThrough") or 2] or 90) / 100
    e.lite = H.val("lookStyle") == 2
    return e
end
function H.lookTheme(label)
    local e = H.expect()
    Q.check(ZeD.currentBase == e.base and ZeD.currentAccent == e.accent and ZeD.currentSize == e.size and ZeD.currentStatus == e.status,
        label .. ": the theme, accent, text size and status set in use are the ones picked",
        tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentSize) .. " " .. tostring(ZeD.currentStatus)
        .. " / picked " .. tostring(e.base) .. " " .. tostring(e.accent) .. " " .. tostring(e.size) .. " " .. tostring(e.status))
    local wantA = ZeD.seeThroughWorks(e.base) and e.see or 1
    Q.check(H.near(ZeD.surfaceAlpha, wantA), label .. ": See-through is the picked step in Dark, solid in Light and High contrast",
        "alpha " .. tostring(ZeD.surfaceAlpha) .. ", wanted " .. tostring(wantA) .. " (" .. tostring(e.base) .. ")")
    Q.check(ZeD.Settings.lite() == e.lite, label .. ": Style reads as picked", "lite " .. tostring(ZeD.Settings.lite()))
end
function H.lookScale(label)
    local e = H.expect()
    local Sc = ZeD.Scale
    local root, T = Sc.root(), ZeD.T
    local sz = ZeD.TextSizes[e.size or "small"]
    Q.check(Sc.userScale == e.user, label .. ": the UI scale in use is the step picked (none for Auto)",
        tostring(Sc.userScale) .. " / picked " .. tostring(e.user))
    Q.check(H.near(root, Sc.compute()) and H.near(Sc._appliedRoot, root) and T ~= nil and H.near(T.root, root)
        and H.near(T.scale, root * ((sz and sz.scale) or 1)),
        label .. ": the tokens are built at the root scale ZeD.Scale works out, times the text size",
        "root " .. tostring(root) .. ", worked out " .. tostring(Sc.compute()) .. ", applied " .. tostring(Sc._appliedRoot)
        .. ", T.root " .. tostring(T and T.root) .. ", T.scale " .. tostring(T and T.scale))
    if e.user and not Sc.override then
        local cap = Sc.fitCap()
        Q.check(root <= cap + 0.001 and root >= Sc.STEP_FLOOR - 0.001, label .. ": a fixed step draws inside the floor and this screen's cap",
            "root " .. tostring(root) .. ", floor " .. tostring(Sc.STEP_FLOOR) .. ", cap " .. tostring(cap))
    end
end
-- everything after a change has settled
function H.after(label, ok)
    Q.check(ok, label .. ": the look settled with both windows open",
        "ticks " .. (S.ticks - S.tick0) .. ", reopening " .. tostring(ZeD.Scale._reopenAt) .. ", open " .. tostring(RT.isOpen()))
    local okL, errL = pcall(function() H.lookTheme(label); H.lookScale(label) end)
    if not okL then Q.check(false, label .. ": the look could be read", errL) end
    local nc, nw = H.winCount()
    Q.check(nc == 1 and nw == 1, label .. ": one Character window and one World window on screen", nc .. " and " .. nw)
    RT.bounds(Q, label)
    local c, w = RT.cw(), RT.ww()
    local W, H2 = getCore():getScreenWidth(), getCore():getScreenHeight()
    if c and w then
        Q.check(c:getWidth() <= W + 1 and c:getHeight() <= H2 + 1 and w:getWidth() <= W + 1 and w:getHeight() <= H2 + 1,
            label .. ": neither window is larger than the screen", "Character " .. H.geo(c) .. ", World " .. H.geo(w))
    end
    local cs, cok = H.cardState(S.pre and S.pre.item)
    Q.check(cok, label .. ": the item card is still on the item it was on or cleanly gone", cs .. " (before: " .. tostring(S.pre and S.pre.card) .. ")")
    local ms, mok = H.menuState()
    Q.check(mok, label .. ": the right-click menu is still on the tool or cleanly gone", ms .. " (before: " .. tostring(S.pre and S.pre.menu) .. ")")
    local m = H.menu()
    if m and m._levels then
        local okB, why = H.levelsOk(m)
        Q.check(okB, label .. ": the menu's list is inside the screen", why)
    end
end
-- a window's height unrolled (a rolled-up window keeps its height in preShadeHeight, as charStateOf reads it)
function H.fullH(win) return (win.windowShaded and win.preShadeHeight) or win:getHeight() end
-- after a UI scale step: each window as tall in design units as before it. The windows close and reopen from design
-- units (Scale.lua "it restores from design units"; charStateOf / worldStateOf save px / T.scale). The first run
-- (Nov 21 2026, before Build's W36 change) kept the old height in px on two of the eight steps, Auto (2x) to 1.75x and
-- 1.5x to 1x: 840 px and 720 px stayed, the World window's place too, though the log shows both windows closed and
-- reopened on those steps (Focus unregister / register). Likely cause (QA review, Nov 21): the game takes a removed
-- window off the screen only at the start of the next frame (UIManager.RemoveElement queues it), so the windows
-- Scale.lua has just closed draw once more in the new look, and their once-a-second layout save in render
-- (saveCharStateThrottled, saveWorldStateThrottled) can write over the save made at the close, now divided by the new
-- scale. A race: it fails some runs, not every run. A height the screen clamps is left out.
function H.keptHeight(label)
    local c, w, T = RT.cw(), RT.ww(), ZeD.T
    local b = S.preH
    if not (b and c and w and T and T.scale) then return end
    local maxU = (getCore():getScreenHeight() - T.px(20)) / T.scale
    if b.c > maxU - 2 or b.w > maxU - 2 then
        Q.say("note " .. label .. ": the heights are not compared (the screen clamps " .. math.floor(math.max(b.c, b.w)) .. " units at this scale)")
        return
    end
    local cu, wu = H.fullH(c) / T.scale, H.fullH(w) / T.scale
    Q.check(math.abs(cu - b.c) <= 2 and math.abs(wu - b.w) <= 2, label .. ": each window is as tall in design units as before the scale step",
        string.format("Character %.1f units (was %.1f), World %.1f units (was %.1f); now %s and %s",
            cu, b.c, wu, b.w, H.geo(c), H.geo(w)))
end
function H.errCheck(label)
    local n = H.errs()
    if S.e0 and n then Q.check(n == S.e0, label .. ": no Lua error since the change", (n - S.e0) .. " new") end
end

-- ===================================================================== the cycle, queued
-- the scene before a change: the pair on Loot, the bat's card open, the menu open on the tool
function H.arm(label)
    step(2, function()
        if getGameSpeed() == 0 then pcall(setGameSpeed, 1) end
        H.closeMenu()
        RT.pairOpen()
    end)
    waitFor(2, 300, H.bothUp, function(ok)
        if not ok then Q.check(false, label .. ": both windows are open before the change") end
        -- (no half rolls by itself while the script works: the pointer is elsewhere; a reopened window is a new one)
        for _, w in ipairs({ RT.cw(), RT.ww() }) do
            if w and w._halves and ZeD.Halves and ZeD.Halves.setPin then pcall(ZeD.Halves.setPin, w, nil, true) end
        end
        RT.charTab("loot"); RT.worldTab("loot")
        S.seekPos = nil
    end)
    waitFor(3, 240, function() return H.cardOn(S.bat) or H.seekRow(S.bat) end, function(ok)
        if H.cardOn(S.bat) then return end
        if ok then H.click(S.bat) end
    end)
    waitFor(2, 150, function() return H.cardOn(S.bat) end, function(ok)
        Q.check(ok, label .. ": before it, a click on the bat's row opens its card")
        S.seekPos = nil
    end)
    waitFor(2, 240, function() return H.seekRow(S.tool) end, function(ok)
        if ok then H.rightClick(S.tool) end
    end)
    waitFor(2, 150, function() return H.menu() ~= nil end, function(ok)
        local m = H.menu()
        Q.check(ok and m ~= nil and H.menuHas(m, S.tool), label .. ": before it, a right-click on the tool's row opens ZeD's menu on it",
            tostring(m and m.Type))
        -- (the row right-clicked becomes the selection, so the card is the tool's now: said once, the first time)
        if not S.saidFollow then
            S.saidFollow = true
            Q.check(H.cardOn(S.tool), "the card follows the row that was right-clicked (the menu acts on the row under the pointer)",
                (H.cardState(S.tool)))
        end
    end)
end
-- the tab switch after a change (a different tab each time), then back to Loot
function H.tabs(label, o)
    step(3, function()
        H.closeMenu()
        S.k = S.k + 1
        S.tc, S.tw = H.pickTab(RT.charStrip(), S.k), H.pickTab(RT.worldStrip(), S.k + 1)
        if S.tc then RT.charTab(S.tc) end
        if S.tw then RT.worldTab(S.tw) end
    end)
    waitFor(2, 180, function()
        local c, w = RT.cw(), RT.ww()
        return c ~= nil and w ~= nil and c._activeTab == S.tc and w._activeTab == S.tw
    end, function(ok)
        local c, w = RT.cw(), RT.ww()
        Q.check(ok and S.tc ~= nil and S.tw ~= nil, label .. ": a tab switch works in both windows",
            "Character " .. tostring(S.tc) .. " -> " .. tostring(c and c._activeTab) .. ", World " .. tostring(S.tw) .. " -> " .. tostring(w and w._activeTab))
    end)
    step(8, function()
        RT.bounds(Q, label .. ", on " .. tostring(S.tc) .. " and " .. tostring(S.tw))
        H.hudCheck(label)
        H.errCheck(label)
        RT.charTab("loot"); RT.worldTab("loot")
        S.still, S.lastW = 0, -1
    end)
    waitFor(2, 300, function()
        local c, w = RT.cw(), RT.ww()
        if not (c and w and c._activeTab == "loot" and w._activeTab == "loot") then return false end
        local sum = c:getWidth() + w:getWidth() + c:getX() + w:getX()
        if sum == S.lastW then S.still = S.still + 1 else S.still, S.lastW = 0, sum end
        return S.still >= 8
    end, function(ok)
        local c, w = RT.cw(), RT.ww()
        Q.check(ok, label .. ": both windows go back to Loot and come to rest", tostring(c and c._activeTab) .. " / " .. tostring(w and w._activeTab))
        if o and o.noOverlap then return end
        if c and w and c._drawerItem == nil then
            Q.check(not H.overlap(), label .. ": back on Loot the windows do not lie over each other", "Character " .. H.geo(c) .. ", World " .. H.geo(w))
        end
    end)
end
-- one change: the scene, the change, the settle, the checks, the tab switch. o.need: ticks to wait (36 where the
-- root scale may move: ZeD.Scale works it out every 30 ticks); o.extra: one more check; o.noOverlap
function H.cycle(label, fn, o)
    o = o or {}
    H.arm(label)
    step(2, function()
        local w0 = RT.cw()
        S.pre = { item = w0 and w0._drawerItem or nil, menu = H.menu() and "open" or "closed" }
        S.pre.card = (H.cardState(S.pre.item))
        S.preH = nil
        if o.keepH then
            local c, w, T = RT.cw(), RT.ww(), ZeD.T
            if c and w and T and T.scale then S.preH = { c = H.fullH(c) / T.scale, w = H.fullH(w) / T.scale } end
        end
        S.wantOpen = true
        H.arm0(o.need or 6)
        local ok, err = pcall(fn)
        Q.check(ok, label .. ": the change ran without an error", err)
    end)
    waitFor(2, 1500, H.settled, function(ok) S.okSettle = ok end)
    step(6, function()
        H.after(label, S.okSettle)
        if o.keepH then H.keptHeight(label) end
        if o.extra then
            local ok, err = pcall(o.extra, label)
            if not ok then Q.check(false, label .. ": its own check ran", err) end
        end
    end)
    H.tabs(label, o)
end

-- ===================================================================== the changes
function H.resChange()
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    for _, w in ipairs({ RT.cw(), RT.ww() }) do
        w:setWidth(sw * 2); w:setHeight(sh * 2); w:setX(sw - 50); w:setY(sh - 50)
    end
    triggerEvent("OnResolutionChange", sw, sh, sw, sh)
end
-- a scale step whose root differs from the one in use now (so the windows must reopen)
function H.otherScale()
    local Sc, St = ZeD.Scale, ZeD.Settings
    local cap, root = Sc.fitCap(), Sc.root()
    for _, i in ipairs({ 4, 3, 5, 6, 7, 8 }) do
        local v = St.scaleKeys[i]
        if v > cap then v = cap end
        if v < Sc.STEP_FLOOR then v = Sc.STEP_FLOOR end
        if math.abs(v - root) > 0.01 then return i end
    end
    return nil
end
function H.winAccent(i, j)
    H.set("charAccent", i)
    H.set("worldAccent", j)
end
function H.winAccentCheck(i, j, label)
    local St = ZeD.Settings
    local c, w = RT.cw(), RT.ww()
    local kc, kw = St.accentKeys[i], St.accentKeys[j]
    Q.check(c ~= nil and w ~= nil and c._accentKey == kc and w._accentKey == kw and ZeD._pendingCharAccent == kc and ZeD._pendingWorldAccent == kw,
        label .. ": each window wears its own accent (none: it follows Accent color)",
        "Character " .. tostring(c and c._accentKey) .. " / " .. tostring(kc) .. ", World " .. tostring(w and w._accentKey) .. " / " .. tostring(kw))
end
function H.rapid()
    for i = 1, 8 do H.set("uiScale", i) end
    for _, b in ipairs({ 2, 3, 1, 3 }) do H.set("baseTheme", b) end
    for _, t in ipairs({ 2, 1, 2 }) do H.set("textSize", t) end
    for i = 8, 1, -1 do H.set("uiScale", i) end
    for a = 1, 9 do H.set("accentColor", a) end
    for _, s in ipairs({ 5, 1, 3 }) do H.set("seeThrough", s) end
    H.set("statusColors", 2)
    H.set("lookStyle", 1, true)
    H.set("uiScale", 6)
end

-- ===================================================================== 0. as found
Q.step(3, function()
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "bx_scl") end
    S.errStart = H.errs()
    local zo = H.opts()
    local St, Sc = ZeD and ZeD.Settings, ZeD and ZeD.Scale
    if not Q.check(zo ~= nil and zo.dict ~= nil and St ~= nil and Sc ~= nil and St.applyScale ~= nil and St.applyThemeNow ~= nil and S.p ~= nil and not S.p:isDead(),
        "ZeD's options, ZeD.Settings and ZeD.Scale are there, the character alive") then S.dead = true; return end
    H.safeOn()
    S.hurt0 = H.hurt()
    Q.say("god mode and invincible are on for the run (found: god mode " .. tostring(S.safe and S.safe.god) .. ", invincible " .. tostring(S.safe and S.safe.inv) .. ")"
        .. ((#S.hurt0 == 0) and "; the character is whole" or ("; the character is NOT whole at the start: " .. table.concat(S.hurt0, ", ") .. " (god mode heals him; the put-back checks)")))
    local n = 0
    for _, o in ipairs(zo.data or {}) do
        if o.type == "combobox" and o.id then S.opt0[o.id] = o.selected; n = n + 1 end
    end
    S.nOpt = n
    for _, id in ipairs({ "uiScale", "textSize", "baseTheme", "accentColor", "statusColors", "seeThrough", "lookStyle", "charAccent", "worldAccent" }) do
        if S.opt0[id] == nil then Q.check(false, "ZeD's option " .. id .. " is there"); S.dead = true end
    end
    S.ini0 = H.readIni()
    S.look0 = { base = ZeD.currentBase, accent = ZeD.currentAccent, size = ZeD.currentSize, status = ZeD.currentStatus,
                user = Sc.userScale, root = Sc.root(), alpha = ZeD.surfaceAlpha, lite = St.lite(), override = Sc.override }
    S.pairWas = RT.isOpen()
    S.speed0 = getGameSpeed()
    Q.say("as found: " .. n .. " options; scale option " .. tostring(S.opt0.uiScale) .. " root " .. tostring(S.look0.root) .. " cap " .. tostring(Sc.fitCap())
        .. "; " .. tostring(S.look0.base) .. " " .. tostring(S.look0.accent) .. " " .. tostring(S.look0.size) .. " " .. tostring(S.look0.status)
        .. "; see-through " .. tostring(S.look0.alpha) .. "; lite " .. tostring(S.look0.lite) .. "; pair open " .. tostring(S.pairWas))
    S.tickFn = function() S.ticks = S.ticks + 1
        if S.onReopen and ZeD.Scale._reopenAt ~= nil then
            local f = S.onReopen
            S.onReopen, S.reopenHit = nil, true
            pcall(f)
        end
    end
    Events.OnTick.Add(S.tickFn)
    if getGameSpeed() == 0 then pcall(setGameSpeed, 1) end
    RT.pairOpen()
end)
waitFor(5, 400, H.bothUp, function(ok)
    if not Q.check(ok, "both windows are open at the start") then S.dead = true; return end
    local c, w = RT.cw(), RT.ww()
    S.snap = ZEDQA_LAYOUT_SNAP and ZEDQA_LAYOUT_SNAP() or nil
    S.tabC, S.tabW = c._activeTab, w._activeTab
    -- (a tab counts as open only with its drawer out: "Reset both windows" shuts the World window's drawer and leaves
    -- its tab's name in place, and the first run's put-back clicked that name and opened a drawer that was shut)
    S.drawC = c._drawerOpen == true and c._drawerMode == "tab" and S.tabC ~= "loot"
    S.drawW = w._drawerOpen == true and w._drawerMode == "tab" and S.tabW ~= "loot"
    Q.say("as found: Character tab " .. tostring(S.tabC) .. (S.drawC and " (drawer out)" or " (drawer shut)")
        .. ", World tab " .. tostring(S.tabW) .. (S.drawW and " (drawer out)" or " (drawer shut)"))
    S.acc0 = { c = c._accentKey, w = w._accentKey, pc = ZeD._pendingCharAccent, pw = ZeD._pendingWorldAccent }
    pcall(function()
        local ws = S.p:getModData().ZeD_WinState
        S.acc0.sc, S.acc0.sw = ws and ws.char and ws.char.accentKey, ws and ws.world and ws.world.accentKey
        S.acc0.hasC, S.acc0.hasW = (ws and ws.char) ~= nil, (ws and ws.world) ~= nil
    end)
    local cc = H.cc()
    S.scroll0 = cc and cc._scroll and cc._scroll.scrollPos or nil
    RT.charTab("loot"); RT.worldTab("loot")
    S.hudA = H.hud()
    Q.check(S.ticks > 0, "the game is running (ticks count)", S.ticks .. " ticks")
end)
step(40, function()
    -- the HUD's baseline: what was up in both looks at the start, a second apart (a notice that fades is left out)
    local b = H.hud()
    S.hud0 = {}
    local n = 0
    for ty, c in pairs(S.hudA or {}) do
        local m = math.min(c, b[ty] or 0)
        if m > 0 then S.hud0[ty] = m; n = n + m end
    end
    Q.say("the HUD at the start: " .. n .. " ZeD roots besides the two windows")
    if n == 0 then S.hud0 = nil; Q.skip("the HUD pieces stay up through the changes", "no ZeD HUD root was on screen at the start") end
    local have = {}
    local items = S.p:getInventory():getItems()
    for i = 0, items:size() - 1 do have[items:get(i):getFullType()] = true end
    for _, ft in ipairs({ "Base.BaseballBat", "Base.Golfclub", "Base.Plank", "Base.Saucepan" }) do
        if not S.bat and not have[ft] then S.bat = RT.give(ft) end
    end
    for _, ft in ipairs({ "Base.Hammer", "Base.Crowbar", "Base.Screwdriver", "Base.Wrench", "Base.ClubHammer" }) do
        if not S.tool and not have[ft] then S.tool = RT.give(ft) end
    end
    if not Q.check(S.bat ~= nil and S.tool ~= nil, "a bat (or its stand-in) and a tool of kinds the bag does not hold were given",
        tostring(S.bat and S.bat:getFullType()) .. ", " .. tostring(S.tool and S.tool:getFullType())) then S.dead = true end
end)

-- ===================================================================== 1. UI scale, every step, in an odd order
for _, i in ipairs({ 8, 2, 5, 1, 7, 3, 6, 4 }) do
    H.cycle("UI scale " .. ((i == 1) and "Auto" or tostring(ZeD.Settings.scaleLabels[i])),
        function() H.set("uiScale", i) end, { need = 36, keepH = true })
end
-- ===================================================================== 2. text size
for _, i in ipairs({ 2, 1 }) do
    H.cycle("Text " .. tostring(ZeD.Settings.sizeKeys[i]), function() H.set("textSize", i) end, { need = 36 })
end
-- ===================================================================== 3. theme
for _, i in ipairs({ 2, 3, 1 }) do
    H.cycle("Theme " .. tostring(ZeD.Settings.baseKeys[i]), function() H.set("baseTheme", i) end)
end
-- ===================================================================== 4. every accent
for i = 1, #ZeD.Settings.accentKeys do
    H.cycle("Accent " .. tostring(ZeD.Settings.accentKeys[i]), function() H.set("accentColor", i) end)
end
-- ===================================================================== 5. status colors
for _, i in ipairs({ 2, 1 }) do
    H.cycle("Status colors " .. tostring(ZeD.Settings.statusKeys[i]), function() H.set("statusColors", i) end)
end
-- ===================================================================== 6. see-through, every step (Dark), then in Light
for _, i in ipairs({ 5, 1, 3, 4, 2 }) do
    H.cycle("See-through " .. tostring(ZeD.Settings.seeThroughKeys[i]), function() H.set("seeThrough", i) end)
end
H.cycle("See-through 60 in Light", function() H.set("baseTheme", 2); H.set("seeThrough", 5) end)
H.cycle("Dark again, See-through 60 kept", function() H.set("baseTheme", 1) end)
-- ===================================================================== 7. Style
H.cycle("Style Lite", function() H.set("lookStyle", 2, true) end)
H.cycle("Style Full", function() H.set("lookStyle", 1, true) end)
-- ===================================================================== 8. the windows' own accents
for _, pr in ipairs({ { 1, 10 }, { 4, 7 }, { 9, 2 }, { 10, 10 } }) do
    H.cycle("Window accents " .. pr[1] .. " and " .. pr[2], function() H.winAccent(pr[1], pr[2]) end,
        { extra = function(label) H.winAccentCheck(pr[1], pr[2], label) end })
end
-- ===================================================================== 9. fringe
H.cycle("Large, High contrast, Lite and 2x in one frame", function()
    H.set("textSize", 2); H.set("baseTheme", 3); H.set("lookStyle", 2, true); H.set("uiScale", 8)
end, { need = 36 })
H.cycle("a resolution change with both windows twice the screen and half off it", H.resChange, { need = 36, noOverlap = true })
step(4, function()
    local ok, err = pcall(ZeD_Window.resetLayout)
    Q.check(ok, "the layout reset after the resolution change ran without an error", err)
end)
H.cycle("every scale step, theme and text size fired in one frame", H.rapid, { need = 36 })
H.cycle("a resolution change in Full after the burst", H.resChange, { need = 36, noOverlap = true })
step(4, function() pcall(ZeD_Window.resetLayout) end)

-- "Reset both windows" with a tab open in each window: both back on Loot, drawers shut. (The first run's put-back
-- showed the World window keeps its tab's name through a reset: resetChar sets _activeTab to "loot", resetWorld
-- does not, Organisms.lua. Its strip then lights the old tab over a shut drawer (the strip lights _activeTab), and
-- columns are a Loot-tab thing, so a click on a container button opens no column until Loot is clicked.)
step(6, function()
    H.closeMenu()
    RT.pairOpen()
    S.rc, S.rw = H.pickTab(RT.charStrip(), 1), H.pickTab(RT.worldStrip(), 1)
    if S.rc then RT.charTab(S.rc) end
    if S.rw then RT.worldTab(S.rw) end
end)
waitFor(2, 240, function()
    local c, w = RT.cw(), RT.ww()
    return c ~= nil and w ~= nil and S.rc ~= nil and S.rw ~= nil and c._activeTab == S.rc and w._activeTab == S.rw
        and c._drawerOpen == true and w._drawerOpen == true
end, function(ok)
    S.resetReady = ok
    if not ok then Q.skip("Reset both windows with a tab open in each", "the tabs did not open (" .. tostring(S.rc) .. ", " .. tostring(S.rw) .. ")"); return end
    local okR, err = pcall(ZeD_Window.resetLayout)
    Q.check(okR, "Reset both windows with " .. tostring(S.rc) .. " and " .. tostring(S.rw) .. " open ran without an error", err)
end)
step(6, function()
    if not S.resetReady then return end
    local c, w = RT.cw(), RT.ww()
    Q.check(c ~= nil and w ~= nil and c._activeTab == "loot" and w._activeTab == "loot" and not c._drawerOpen and not w._drawerOpen,
        "Reset both windows leaves both windows on Loot with their drawers shut",
        "Character " .. tostring(c and c._activeTab) .. " (drawer " .. tostring(c and c._drawerOpen) .. "), World "
        .. tostring(w and w._activeTab) .. " (drawer " .. tostring(w and w._drawerOpen) .. ")")
    RT.charTab("loot"); RT.worldTab("loot")
end)

-- the window key pressed while the windows are mid-reopen from a scale change
step(6, function()
    H.closeMenu()
    RT.pairOpen()
    S.wantOpen = false
    H.arm0(40)
    S.midI = H.otherScale()
    if not S.midI then Q.skip("the window key mid-reopen", "no scale step moves the root on this screen"); return end
    S.reopenHit = false
    S.onReopen = function() ZeD_CharacterWindow.toggleBothPaired(S.pn) end
    local ok, err = pcall(H.set, "uiScale", S.midI)
    Q.check(ok, "mid-reopen: the scale change ran without an error", err)
end)
waitFor(2, 1500, H.settled, function(ok)
    if not S.midI then return end
    S.onReopen = nil
    if not S.reopenHit then Q.skip("the window key mid-reopen", "the windows never showed as reopening") end
    Q.check(ok, "mid-reopen: the scale settles after the window key is pressed mid-reopen", "reopening " .. tostring(ZeD.Scale._reopenAt))
    Q.say("note mid-reopen: the pair is " .. (RT.isOpen() and "open" or "shut") .. " after the key (hit " .. tostring(S.reopenHit) .. ")")
    RT.pairOpen()
end)
waitFor(4, 400, H.bothUp, function(ok)
    if not S.midI then return end
    local nc, nw = H.winCount()
    Q.check(ok and nc == 1 and nw == 1, "mid-reopen: the pair opens after it, one window of each", nc .. " Character, " .. nw .. " World")
    RT.bounds(Q, "mid-reopen")
    local okL, errL = pcall(function() H.lookScale("mid-reopen") end)
    if not okL then Q.check(false, "mid-reopen: the scale could be read", errL) end
    H.errCheck("mid-reopen")
end)

-- a scale change with the pair shut, then the pair opened
step(6, function()
    H.closeMenu()
    RT.pairShut()
end)
waitFor(4, 300, function() return not RT.isOpen() end, function(ok)
    Q.check(ok, "pair shut: the pair closes")
    S.wantOpen = false
    H.arm0(40)
    S.shutI = H.otherScale()
    if not S.shutI then Q.skip("a scale change with the pair shut", "no scale step moves the root on this screen"); return end
    local okS, err = pcall(H.set, "uiScale", S.shutI)
    Q.check(okS, "pair shut: the scale change ran without an error", err)
end)
waitFor(2, 1500, H.settled, function(ok)
    if not S.shutI then return end
    Q.check(ok, "pair shut: the scale settles")
    local nc, nw = H.winCount()
    Q.check(not RT.isOpen() and nc == 0 and nw == 0, "pair shut: a scale change does not open windows the player shut", nc .. " Character, " .. nw .. " World on screen")
    RT.pairOpen()
end)
waitFor(4, 400, H.bothUp, function(ok)
    if not S.shutI then return end
    Q.check(ok, "pair shut: the pair opens at the new scale")
end)
step(10, function()
    if not S.shutI then return end
    RT.bounds(Q, "the pair opened after a scale change made while shut")
    local c, w = RT.cw(), RT.ww()
    local W, H2 = getCore():getScreenWidth(), getCore():getScreenHeight()
    if c and w then
        Q.check(c:getWidth() <= W + 1 and c:getHeight() <= H2 + 1 and w:getWidth() <= W + 1 and w:getHeight() <= H2 + 1,
            "pair shut: neither window opens larger than the screen", "Character " .. H.geo(c) .. ", World " .. H.geo(w))
    end
    local okL, errL = pcall(function() H.lookScale("pair shut") end)
    if not okL then Q.check(false, "pair shut: the scale could be read", errL) end
    H.errCheck("pair shut")
end)

-- ===================================================================== put back
Q.mark()
Q.step(4, function()
    S.onReopen = nil
    H.closeMenu()
    if S.nOpt == nil then return end
    local zo = H.opts()
    for id, v in pairs(S.opt0) do
        local o = zo and zo.dict and zo.dict[id]
        if o and o.selected ~= v then pcall(function() o:setValue(v) end) end
    end
    local ok1, e1 = pcall(ZeD.Settings.applyScale)
    local ok2, e2 = pcall(ZeD.Settings.applyThemeNow)
    Q.check(ok1 and ok2, "put back: the scale and the theme re-applied from the options as found", tostring(e1 or e2 or ""))
    S.wantOpen = false
    H.arm0(S.tickFn and 40 or 0)   -- (no tick counter when the start failed)
end)
-- (the pair is opened only once the scale has settled: since Build's W36 change a scale change shuts the windows at
-- once and ZeD reopens them three ticks later; an open asked for in between would open them itself and ZeD's own
-- reopen would then find them open, so the put-back would not go the way a player's scale change goes)
Q.waitFor(2, 1500, function() return S.nOpt == nil or H.settled() end, function(ok)
    if S.nOpt == nil then return end
    S.backSettled = ok
    RT.pairOpen()
end)
Q.waitFor(2, 400, function() return S.nOpt == nil or H.bothUp() end, function(ok)
    if S.nOpt == nil then return end
    Q.check(ok and S.backSettled, "put back: the look settled with both windows open",
        "scale settled " .. tostring(S.backSettled) .. ", reopening " .. tostring(ZeD.Scale._reopenAt) .. ", open " .. tostring(RT.isOpen()))
    if ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, S.snap, "bx_scl") else pcall(ZeD_Window.resetLayout) end
end)
Q.step(6, function()
    if S.nOpt == nil then return end
    -- (the layout reset sets both windows to "Same as Accent color" and its option with them: the options and the
    -- windows' own accents as found, after it; the values only, nothing saved by this script)
    for _, id in ipairs({ "charAccent", "worldAccent" }) do
        local o = H.opt(id)
        if o and S.opt0[id] ~= nil and o.selected ~= S.opt0[id] then pcall(function() o:setValue(S.opt0[id]) end) end
    end
    local a = S.acc0
    if a then
        local c, w = RT.cw(), RT.ww()
        if c then c._accentKey = a.c end
        if w then w._accentKey = a.w end
        ZeD._pendingCharAccent, ZeD._pendingWorldAccent = a.pc, a.pw
        pcall(function()
            local ws = S.p:getModData().ZeD_WinState
            if ws and ws.char and a.hasC then ws.char.accentKey = a.sc end
            if ws and ws.world and a.hasW then ws.world.accentKey = a.sw end
        end)
    end
    local cc = H.cc()
    if cc and cc._scroll and S.scroll0 ~= nil then pcall(function() cc._scroll:setScrollPos(S.scroll0) end) end
    -- (a tab only where its drawer was out at the start; a tab's name over a shut drawer, as a layout reset leaves the
    -- World window, is no tab the player had open, and clicking the name would open its drawer)
    if S.drawC and S.tabC then RT.charTab(S.tabC) end
    if S.drawW and S.tabW then RT.worldTab(S.tabW) end
end)
Q.step(10, function()
    if S.tickFn then Events.OnTick.Remove(S.tickFn) end
    local okS, errS = pcall(H.safeBack)   -- (first, and whatever the start did)
    if not okS then Q.check(false, "put back: the character's health could be read", errS) end
    if S.nOpt == nil then return end
    if S.pairWas then RT.pairOpen() else RT.pairShut() end
    if S.speed0 and S.speed0 > 0 and getGameSpeed() ~= S.speed0 then pcall(setGameSpeed, S.speed0) end
end)
Q.step(10, function()
    if S.nOpt == nil then return end
    local bad = {}
    for id, v in pairs(S.opt0) do if H.val(id) ~= v then bad[#bad + 1] = id .. " " .. tostring(H.val(id)) .. " (was " .. tostring(v) .. ")" end end
    Q.check(#bad == 0, "put back: every ZeD option holds the value read at the start (" .. tostring(S.nOpt) .. " options)", table.concat(bad, "; "))
    local L, Sc = S.look0, ZeD.Scale
    Q.check(ZeD.currentBase == L.base and ZeD.currentAccent == L.accent and ZeD.currentSize == L.size and ZeD.currentStatus == L.status
        and H.near(ZeD.surfaceAlpha, L.alpha) and ZeD.Settings.lite() == L.lite,
        "put back: the theme, accent, text size, status set, see-through and Style in use are as found",
        tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentSize) .. " " .. tostring(ZeD.currentStatus)
        .. " alpha " .. tostring(ZeD.surfaceAlpha) .. " lite " .. tostring(ZeD.Settings.lite()))
    Q.check(Sc.userScale == L.user and H.near(Sc.root(), L.root) and Sc.override == L.override, "put back: the UI scale and its root are as found",
        "step " .. tostring(Sc.userScale) .. " root " .. tostring(Sc.root()) .. " (was " .. tostring(L.user) .. ", " .. tostring(L.root) .. ")")
    Q.check(RT.isOpen() == S.pairWas, "put back: the pair open or shut as found")
    local c, w = RT.cw(), RT.ww()
    local a = S.acc0
    if a and c and w then
        Q.check(c._accentKey == a.c and w._accentKey == a.w, "put back: each window's own accent as found", tostring(c._accentKey) .. " / " .. tostring(w._accentKey))
    end
    local sn = S.snap
    if S.drawC or S.drawW then
        Q.skip("put back: both windows where and as large as found", "a tab's drawer was out at the start: the snapshot holds the window with its drawer, the reset shuts it first")
    elseif S.pairWas and sn and sn.char and sn.world and c and w then
        Q.check(c:getX() == sn.char.x and c:getY() == sn.char.y and c:getWidth() == sn.char.w and c:getHeight() == sn.char.h
            and w:getX() == sn.world.x and w:getY() == sn.world.y and w:getWidth() == sn.world.w and w:getHeight() == sn.world.h,
            "put back: both windows where and as large as found", "Character " .. H.geo(c) .. ", World " .. H.geo(w)
            .. " / found Character " .. math.floor(sn.char.x) .. "," .. math.floor(sn.char.y) .. " " .. math.floor(sn.char.w) .. "x" .. math.floor(sn.char.h)
            .. ", World " .. math.floor(sn.world.x) .. "," .. math.floor(sn.world.y) .. " " .. math.floor(sn.world.w) .. "x" .. math.floor(sn.world.h))
    else
        Q.skip("put back: both windows where and as large as found", "no layout snapshot (the prelude did not run, or the pair was shut)")
    end
    Q.check(H.menu() == nil, "put back: no right-click menu left open")
    local now = H.readIni()
    if S.ini0 and now then
        Q.say("note ModOptions.ini is " .. ((table.concat(now, "\n") == table.concat(S.ini0, "\n")) and "line for line as at the start"
            or "not as at the start (ZeD's own layout reset saves the options as they stand; this script writes nothing)"))
    end
    local n = H.errs()
    if S.errStart and n then Q.check(n == S.errStart, "the whole run drew with no Lua error", (n - S.errStart) .. " new") end
end)
Q.start()
