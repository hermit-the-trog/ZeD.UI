-- ZeDUI/tools/qa/rt_lite.lua  (Nov 18 2026, QA; tag rt_lite): the release test's Lite checks (beta 21, the seven
-- FEATURE_MAP rows "Style: Lite or Full" to "Lite desk and Mods"; the desk and Mods row is the main menu's,
-- zedqa_menu_lite.lua). Built on rt_kit.lua (the global RT); run after it. grep "ZEDQA rt_lite". No pictures.
-- The director, Nov 18 2026: "If vanilla does it, so does Lite." Lite is one Style switch in ZeD setup, Look.
-- What it checks, in Lite and then in Full:
--   1. Style (Settings.lua, ZeD_MainMenuOptionGroups.lua): Lite picked as a player picks it (pause menu, Options,
--      ZeD setup, the Style row stepped as the pad steps it, Apply); ZeD.Settings.lite() reads it; the forms' helpers
--      answer Lite (devices, watch, guide, mods, identity, the belt); the additions are on the Vanilla preset; ZeD
--      setup has no Additions or Chords group and none of the eight retired switches
--   2. buttons (Molecules.lua): ZeD.Molecules.lite(); liteKind gives Cancel and No and a danger button "bad", a
--      primary "good", a plain one nothing; liteColor is the game's own good and bad colors (Accessibility); and a
--      button really drawn in Lite (the watch's speed row, the speed in use is primary) is filled with the good color
--      under a line two hairlines thick
--   3. dashboard (ZeD_Dashboard.lua): D._designFor gives every car, a pickup and a police car, the Dash Elite;
--      D._cabinOf gives it the black cabin
--   4. watch (ZeD_Watch.lua): W.lite(), W.beltMode() false (the corner); its keys are the speed row speed0 to speed3
--      (SKIP on a server, where the speed is not the player's)
--   5. device faces (PlainFace.lua): every radio plate's plain controls, ZeD.PlainFace.controlsFor, have no preset
--      keys, no memory key and no dial lamp; every plate with a power row in Full keeps it
--   6. windows (InventoryRenderer.lua, ContainerControls.lua, ItemCardOrganism.lua): the inventory's List or Grid
--      key and its Filter key drawn as words (their boxes as wide as ZeD.Molecules.buttonW of the word); no Same
--      type or Same type nearby button; an item card opened from its row (the list's own mouse handler) has no
--      marks strip (no Favorite box stamped)
--   RT.bounds after the windows and the card open in Lite, and with the watch in its corner.
-- Then Full is picked the same way and the Full forms come back (the helpers, the additions group, the icon keys,
-- Same type, the marks strip, the pickup's own dash, a preset key on some radio).
-- What it puts back: every ZeD option's stored value as found (Style among them, Full or Lite as it was), and
-- ModOptions.ini line for line (Apply writes it); the windows open or shut as found; the pencil it gave is taken
-- back; the pause menu shut as found. Apply also rewrites the game's options.ini with the values it already had.
if not RT then
    print("ZEDQA rt_lite FAIL the kit (rt_kit.lua) is not loaded")
    print("ZEDQA rt_lite VERDICT FAIL 1")
    print("ZEDQA rt_lite DONE")
    return
end
local Q = RT.make("rt_lite")
Q.maxMs = 1500000                    -- (the runner gives this script 1800 s: the put-back runs before that)
local S = { pn = RT.pn, p = RT.p }
local H = {}
local St, M, MM = ZeD.Settings, ZeD.Molecules, ZeD.MainMenu

-- ===================================================================== helpers
function H.opts() local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo end
function H.opt(id) local zo = H.opts(); return zo and zo.dict and zo.dict[id] or nil end
function H.val(id) local o = H.opt(id); local v = nil; pcall(function() v = o:getValue() end); return v end
function H.menuUp()
    local up = false
    pcall(function() up = MainScreen.instance ~= nil and MainScreen.instance:isVisible() end)
    return up
end
function H.toggleMenu() pcall(function() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end) end
-- ModOptions.ini as lines, and written back as it was (the game's own line ends)
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
function H.writeIni(lines)
    if not lines then return false end
    return pcall(function()
        local w = getFileWriter("ModOptions.ini", true, false)
        for _, l in ipairs(lines) do w:write(l .. "\r\n") end
        w:close()
    end) and true or false
end
-- ZeD setup's row for one of ZeD's options (its control is the option's own element)
function H.setupRow(w, id)
    local o = H.opt(id)
    local el = o and o.element
    if not el then return nil end
    local rows = {}
    pcall(function() rows = w:zedSetupRows() end)
    for _, r in ipairs(rows) do if r.control == el then return r end end
    return nil
end
-- the row stepped to item want as the pad's Left and Right step it (ZeD_MMOptions:nudge); else as a click sets it
function H.stepTo(w, r, want)
    local c = r and r.control
    if not c then return false end
    for _ = 1, 8 do
        local cur = c.selected or 1
        if cur == want then return true end
        pcall(function() w:nudge(r, (want > cur) and 1 or -1) end)
        if c.selected == cur then break end
    end
    if c.selected ~= want then
        c.selected = want
        if c.onChange then pcall(c.onChange, c.target, c) end
    end
    return c.selected == want
end
function H.same(r1, g1, b1, r2, g2, b2)
    return r1 ~= nil and r2 ~= nil and math.abs(r1 - r2) < 0.002 and math.abs(g1 - g2) < 0.002 and math.abs(b1 - b2) < 0.002
end
function H.coreRGB(fn)
    local r, g, b = nil, nil, nil
    pcall(function() local c = getCore()[fn](getCore()); r, g, b = c:getR(), c:getG(), c:getB() end)
    return r, g, b
end
function H.rgb(r, g, b)
    if r == nil then return "nil" end
    return string.format("rgb %d %d %d", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end
-- the forms' helpers (Settings.lua): what each answers now
function H.forms()
    local out = {}
    local list = { "devicesSimple", "watchSimple", "guideSimple", "modsSimple", "identitySimple" }
    for _, n in ipairs(list) do
        local v = nil
        pcall(function() v = St[n]() end)
        out[#out + 1] = { n, v }
    end
    local b = nil
    pcall(function() b = ZeD.Belt.simple() end)
    out[#out + 1] = { "Belt.simple", b }
    return out
end
function H.formsAre(want)
    local bad = {}
    for _, f in ipairs(H.forms()) do if (f[2] == true) ~= want then bad[#bad + 1] = f[1] .. "=" .. tostring(f[2]) end end
    return #bad == 0, (#bad == 0) and "6 helpers" or table.concat(bad, " ")
end
-- the Character window's inventory list (the loot tab) and its parts
function H.content() local w = RT.cw(); return w and w._mainContent end
function H.toggle(view)
    local c = H.content()
    for _, t in ipairs((c and c._viewToggleRects) or {}) do if t.view == view then return t end end
    return nil
end
function H.moveIds()
    local out = {}
    local c = H.content()
    for _, h in ipairs((c and c._cc and c._cc.hits) or {}) do
        if h.spec and h.spec.id then out[#out + 1] = tostring(h.spec.id) end
    end
    return out
end
function H.has(list, id) for _, x in ipairs(list) do if x == id then return true end end; return false end
function H.rowZone(item)
    local c = H.content()
    for _, z in ipairs((c and c._hitZones) or {}) do if z.id == item then return z end end
    return nil
end
-- (a condition, every frame: the row drawn, else the list one step further down; wraps at the end)
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
-- a left click on the row, as the list's own mouse handlers take it (it opens the item's card; again, closes it)
function H.click(item)
    local c = H.content()
    local z = H.rowZone(item)
    if not (c and z) then return false end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    c._zedLastClick = nil   -- (never a double-click: that would be the quick use)
    c:onMouseDown(x, y)
    c:onMouseUp(x, y)
    return true
end
function H.cardOn(item)
    local w = RT.cw()
    local c = w and w._itemCard
    return item ~= nil and w ~= nil and w._drawerItem == item and c ~= nil and c.item == item
end
-- every radio plate's plain controls (ZeD.PlainFace.controlsFor), each plate read with its own base (the radios and
-- TVs of ZeD.Rtv.INFO, the two-ways of ZeD.TwoWay.INFO; never another's, since controlsFor keeps what it reads by
-- the plate's id): how many have a preset key, the memory key or the dial lamp, and the plates with a power row
function H.faces()
    local PF, X = ZeD.PlainFace, ZeD.PhysPx
    local res = { n = 0, extras = 0, power = {}, names = {} }
    if not (PF and PF.controlsFor and X and X.plates) then return res end
    local bases = { { "rtv", ZeD.Rtv }, { "tw", ZeD.TwoWay } }
    for _, b in ipairs(bases) do
        for pid in pairs((b[2] and b[2].INFO) or {}) do
            if X.plates[pid] then
                local ok, C = pcall(PF.controlsFor, b[2], pid)
                if ok and C and C.byId and #(C.list or {}) > 0 then
                    res.n = res.n + 1
                    local by = C.byId
                    if by.presets or by.mem or by.lamp then
                        res.extras = res.extras + 1
                        if #res.names < 6 then res.names[#res.names + 1] = tostring(pid) end
                    end
                    if by.power then res.power[b[1] .. ":" .. tostring(pid)] = true end
                end
            end
        end
    end
    return res
end
-- the buttons drawn for a few frames (ZeD.Molecules.drawButton wrapped, pass-through): each button's words, its
-- variant, the fills and lines under it (ZeD.Atoms.fillRounded, borderRounded, borderDoubleRounded)
function H.recStart()
    if S.recOn then return end
    S.rec = {}
    S.recOn = true
    S.drawWas = M.drawButton
    local A = ZeD.Atoms
    M.drawButton = function(panel, x, y, w, h, text, variant, pressed, colors, opts)
        local r = { text = text, variant = variant, fills = {}, lines = 0, doubles = 0, lineRGB = nil }
        local f0, b0, d0 = A.fillRounded, A.borderRounded, A.borderDoubleRounded
        A.fillRounded = function(p, fx, fy, fw, fh, cr, cg, cb, ca, ...)
            r.fills[#r.fills + 1] = { cr, cg, cb }
            return f0(p, fx, fy, fw, fh, cr, cg, cb, ca, ...)
        end
        A.borderRounded = function(p, bx, by, bw, bh, cr, cg, cb, ca, ...)
            r.lines = r.lines + 1
            r.lineRGB = { cr, cg, cb }
            return b0(p, bx, by, bw, bh, cr, cg, cb, ca, ...)
        end
        A.borderDoubleRounded = function(...)
            r.doubles = r.doubles + 1
            return d0(...)
        end
        local ok, err = pcall(S.drawWas, panel, x, y, w, h, text, variant, pressed, colors, opts)
        A.fillRounded, A.borderRounded, A.borderDoubleRounded = f0, b0, d0
        if #S.rec < 400 then S.rec[#S.rec + 1] = r end
        if not ok then error(err) end
    end
end
function H.recStop()
    if not S.recOn then return end
    S.recOn = false
    M.drawButton = S.drawWas
end

-- ===================================================================== picking Style (Lite 2, Full 1) as a player
-- picks it: the pause menu, Options, ZeD setup, the Style row stepped to it, Apply; then onRows(w, rows) reads ZeD
-- setup as it is laid out after; Back; the pause menu shut as found. (No Options: the option set as the row sets it,
-- said as a FAIL.)
function H.pickStyle(want, label, onRows)
    Q.step(5, function()
        S.mu = H.menuUp()
        S.optOk = false
        if not S.mu then H.toggleMenu() end
    end)
    Q.waitFor(10, 400, function() return H.menuUp() and MM.pauseOpts ~= nil end, function(ok)
        if ok then pcall(MM.openOptions) end
    end)
    Q.waitFor(5, 300, function() return MM.pauseOpts ~= nil and MM.pauseOpts:isVisible() end, function(ok)
        Q.check(ok, "Style " .. label .. ": Options opens from the pause menu")
        S.optOk = ok
        local o = St.lookStyleOption
        if not ok then
            pcall(function() o:setValue(want); o:onChange(want) end)
            return
        end
        local w = MM.pauseOpts
        for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end
        w.scroll = 0
        local r = H.setupRow(w, "lookStyle")
        Q.check(r ~= nil, "Style " .. label .. ": ZeD setup has the Style row")
        if r then H.stepTo(w, r, want) end
        pcall(function() w:apply(false) end)
    end)
    Q.step(10, function()
        local w = MM.pauseOpts
        if not (S.optOk and w) then return end
        if w.confirm and w.confirm ~= "back" then pcall(function() w:setConfirm(false) end) end
        w._groupCache = nil
        local rows = {}
        pcall(function() rows = w:zedSetupRows() end)
        onRows(w, rows)
        RT.bounds(Q, "ZeD setup in " .. label)
        pcall(function() w:back() end)
        if w.confirm == "back" then pcall(function() w:discard() end) end
    end)
    Q.step(10, function() if not S.mu and H.menuUp() then H.toggleMenu() end end)
    Q.waitFor(5, 300, function() return S.mu or not H.menuUp() end, function(ok)
        Q.check(ok, "Style " .. label .. ": the pause menu shuts")
    end)
end
-- ZeD setup's group headers as words, the chord rows, and the retired switches still laid out
function H.setupFacts(rows)
    local G = MM.optionGroups
    local f = { heads = {}, chords = 0, retired = {} }
    for _, r in ipairs(rows) do
        if r.kind == "header" then f.heads[tostring(r.text)] = true end
        if r.kind == "chord" then f.chords = f.chords + 1 end
    end
    for _, id in ipairs((G and G.RETIRED) or {}) do
        local o = H.opt(id)
        local el = o and o.element
        if el then
            for _, r in ipairs(rows) do if r.control == el then f.retired[#f.retired + 1] = id end end
        end
    end
    f.add = f.heads[ZeD.tr("UI_ZeD_Options_ZedAdditions")] == true
    f.chordHead = f.heads[ZeD.tr("UI_ZeD_Options_ZedChords")] == true
    return f
end

-- ===================================================================== 0. as found
Q.step(5, function()
    S.err0 = nil
    pcall(function() S.err0 = getLuaDebuggerErrorCount() end)
    S.opt0 = {}
    local zo = H.opts()
    for _, o in ipairs((zo and zo.data) or {}) do
        if o.type == "combobox" and o.id then S.opt0[o.id] = o.selected end
    end
    S.ini0 = H.readIni()
    S.style0 = H.val("lookStyle")
    S.pairWas = RT.isOpen()
    RT.pairOpen()
    S.server = isClient() and true or false
    Q.check(St ~= nil and St.lite ~= nil and St.lookStyleOption ~= nil and M ~= nil and M.liteKind ~= nil and MM ~= nil,
        "Lite: ZeD's settings, molecules and options are loaded")
    Q.say("as found: Style " .. tostring(S.style0) .. " (1 Full, 2 Lite), additions preset " .. tostring(H.val("additionsPreset")))
end)

-- ===================================================================== 1. Lite picked
H.pickStyle(2, "Lite", function(w, rows)
    local f = H.setupFacts(rows)
    Q.check(not f.add and not f.chordHead and f.chords == 0,
        "Style Lite: ZeD setup leaves out the Additions and Chords groups",
        "additions " .. tostring(f.add) .. ", chords " .. tostring(f.chordHead) .. "/" .. f.chords)
    Q.check(#f.retired == 0, "Style Lite: none of the eight retired switches is in ZeD setup", table.concat(f.retired, " "))
    Q.check(H.setupRow(w, "lookStyle") ~= nil, "Style Lite: the Style row stays in ZeD setup")
end)
Q.step(10, function()
    Q.check(St.lite() == true and H.val("lookStyle") == 2, "Style Lite: ZeD.Settings.lite() is true once applied", tostring(H.val("lookStyle")))
    local ok, d = H.formsAre(true)
    Q.check(ok, "Style Lite: the forms' helpers all answer Lite (devices, watch, guide, mods, identity, belt)", d)
    local set = St.ADDITION_PRESETS and St.ADDITION_PRESETS[1] or {}
    local bad, n = {}, 0
    for id, v in pairs(set) do
        n = n + 1
        if H.val(id) ~= v then bad[#bad + 1] = id .. "=" .. tostring(H.val(id)) end
    end
    Q.check(n > 0 and #bad == 0 and H.val("additionsPreset") == 1, "Style Lite: the additions are on the Vanilla preset",
        "preset " .. tostring(H.val("additionsPreset")) .. (#bad > 0 and (", off it: " .. table.concat(bad, " ")) or (", " .. n .. " additions")))
end)

-- ===================================================================== 2. buttons
Q.step(3, function()
    Q.check(M.lite() == true, "Lite buttons: ZeD.Molecules.lite() is true")
    local cancel = ZeD.btnCase(getText("UI_Cancel"))
    local no = ZeD.btnCase(getText("UI_No"))
    local kc, kn = M.liteKind(cancel, "default"), M.liteKind(no, "default")
    local kd, kp, k0 = M.liteKind("Delete", "danger"), M.liteKind("OK", "primary"), M.liteKind("Sort", "default")
    Q.check(kc == "bad" and kn == "bad" and kd == "bad", "Lite buttons: Cancel, No and a danger button are the bad kind",
        tostring(cancel) .. " " .. tostring(kc) .. ", " .. tostring(no) .. " " .. tostring(kn) .. ", danger " .. tostring(kd))
    Q.check(kp == "good" and k0 == nil and M.liteKind("OK", "default", { default = true }) == "good",
        "Lite buttons: a primary or default answer is the good kind, a plain button neither", tostring(kp) .. " / " .. tostring(k0))
    Q.check(M.liteKind(cancel, "default", { disabled = true }) == nil, "Lite buttons: a grayed button has no kind")
    local gr, gg, gb = M.liteColor("good")
    local br, bg, bb = M.liteColor("bad")
    local cr, cg, cb = H.coreRGB("getGoodHighlitedColor")
    local dr, dg, db = H.coreRGB("getBadHighlitedColor")
    Q.check(H.same(gr, gg, gb, cr, cg, cb), "Lite buttons: the good color is the game's getGoodHighlitedColor", H.rgb(gr, gg, gb) .. " / " .. H.rgb(cr, cg, cb))
    Q.check(H.same(br, bg, bb, dr, dg, db), "Lite buttons: the bad color is the game's getBadHighlitedColor", H.rgb(br, bg, bb) .. " / " .. H.rgb(dr, dg, db))
    S.good = { gr, gg, gb }
    H.recStart()
end)

-- ===================================================================== 4. the watch (and the buttons it draws)
Q.step(30, function()
    H.recStop()
    local W = ZeD.Watch
    Q.check(W.lite() == true and W.beltMode() == false, "Lite watch: off the belt, in the corner (W.beltMode() false)",
        "lite " .. tostring(W.lite()) .. ", belt " .. tostring(W.beltMode()))
    local inst = W.getInstance and W.getInstance() or nil
    if S.server then
        Q.skip("Lite watch: its keys are the speed row speed0 to speed3", "on a server the speed is not the player's")
    else
        local ids = {}
        for _, h in ipairs((inst and inst._hit) or {}) do ids[#ids + 1] = tostring(h.id) end
        local want = "speed0 speed1 speed2 speed3"
        Q.check(inst ~= nil and table.concat(ids, " ") == want, "Lite watch: its keys are the speed row speed0 to speed3", table.concat(ids, " "))
    end
    if inst and inst:isVisible() and inst:getWidth() > 0 then RT.bounds(Q, "Lite: the watch in its corner") end
    -- a button really drawn in Lite: the watch's speed row, the speed in use primary, filled with the good color
    -- under a line two hairlines thick of the same color
    local hit, seen = nil, 0
    for _, r in ipairs(S.rec or {}) do
        seen = seen + 1
        if r.variant == "primary" and not hit then
            for _, f in ipairs(r.fills) do
                if H.same(f[1], f[2], f[3], S.good[1], S.good[2], S.good[3]) then hit = r end
            end
        end
    end
    if S.server then
        Q.skip("Lite buttons: a primary button is drawn filled with the good color under a two-hairline line", "no speed row on a server")
    else
        local lc = hit and hit.lineRGB
        Q.check(hit ~= nil and hit.lines == 2 and hit.doubles == 0 and lc ~= nil and H.same(lc[1], lc[2], lc[3], S.good[1], S.good[2], S.good[3]),
            "Lite buttons: a primary button is drawn filled with the good color under a two-hairline line",
            hit and (tostring(hit.text) .. ": " .. hit.lines .. " lines, " .. hit.doubles .. " double") or (seen .. " buttons drawn, none primary and good"))
    end
end)

-- ===================================================================== 3. the dashboard
Q.step(3, function()
    local D = ZeD.Dashboard
    local des, id = nil, nil
    pcall(function() des, id = D._designFor("Base.PickUpTruck") end)
    local _, idP = nil, nil
    pcall(function() _, idP = D._designFor("Base.CarLightsPolice") end)
    Q.check(des ~= nil and id == D.LITE_DESIGN and id == "dashelite" and idP == "dashelite",
        "Lite dashboard: every car gets the Dash Elite (a pickup, a police car)", tostring(id) .. ", " .. tostring(idP))
    local cab = nil
    pcall(function() cab = D._cabinOf(nil, des, id) end)
    Q.check(cab ~= nil and cab.id == D.LITE_CABIN and cab.id == "v_black", "Lite dashboard: in the black cabin", cab and tostring(cab.id) or "no cabin")
end)

-- ===================================================================== 5. device faces
Q.step(3, function()
    local f = H.faces()
    S.facesLite = f
    Q.check(f.n > 0 and f.extras == 0, "Lite device faces: no preset keys, memory key or dial lamp on any radio's plain controls",
        f.n .. " readings, " .. f.extras .. " with them: " .. table.concat(f.names, " "))
    local drops = ZeD.PlainFace.LITE_DROPS or {}
    Q.check(drops.mem == true and drops.lamp == true, "Lite device faces: the memory key and the lamp are on the Lite drop list")
end)

-- ===================================================================== 6. windows: the inventory's keys, the card
Q.step(3, function()
    RT.pairOpen()
    RT.charTab("loot")
    S.pencil = RT.give("Base.Pencil")
end)
Q.step(30, function()
    local c = H.content()
    local fl = H.toggle("flip")
    if not Q.check(fl ~= nil, "Lite windows: the inventory has its List or Grid key") then return end
    local grid = c._gv and c._gv.on
    local word = grid and ZeD.tr("UI_ZeD_Inv_GridView") or getText("IGUI_CraftingWindow_ListView")
    Q.check(fl.w == M.buttonW(word), "Lite windows: List or Grid is drawn as its word",
        tostring(word) .. ": " .. tostring(fl.w) .. " wide, the word's button " .. tostring(M.buttonW(word)))
    local ft = H.toggle("filter")
    if ft then
        local fw = ZeD.tr("UI_ZeD_Inv_Filter")
        Q.check(ft.w == M.buttonW(fw), "Lite windows: Filter is drawn as its word", tostring(ft.w) .. " wide, the word's button " .. tostring(M.buttonW(fw)))
    else
        Q.skip("Lite windows: Filter is drawn as its word", "this list has no Filter key")
    end
    local ids = H.moveIds()
    Q.check(#ids > 0 and not H.has(ids, "same") and not H.has(ids, "near"), "Lite windows: no Same type or Same type nearby button",
        table.concat(ids, " "))
    local cut = ZeD.ContainerControls._liteTrim({ { id = "xfer" }, { id = "same" }, { id = "near" } })
    Q.check(#cut == 1 and cut[1].id == "xfer", "Lite windows: the container buttons' trim keeps Transfer all only", #cut .. " left")
    S.seekPos = nil
end)
Q.waitFor(1, 240, function() return H.seekRow(S.pencil) end, function(ok)
    Q.check(ok, "Lite windows: the pencil's row is in the Character window's list")
    if ok then H.click(S.pencil) end
end)
Q.step(20, function()
    local on = H.cardOn(S.pencil)
    Q.check(on, "Lite windows: a click on the row opens its item card")
    local card = RT.cw() and RT.cw()._itemCard
    local fr = card and card._flagRects
    Q.check(on and fr ~= nil and fr.fav ~= nil and fr.fav.x == nil, "Lite windows: the item card has no marks strip",
        fr and fr.fav and tostring(fr.fav.x) or "no rects")
    RT.bounds(Q, "Lite: both windows and the item card")
    if on then H.click(S.pencil) end
end)
Q.step(10, function()
    Q.check(not H.cardOn(S.pencil), "Lite windows: a second click closes the card")
end)

-- ===================================================================== 7. Full picked: the Full forms come back
H.pickStyle(1, "Full", function(w, rows)
    local f = H.setupFacts(rows)
    Q.check(f.add and f.chordHead, "Style Full: ZeD setup has the Additions and Chords groups again",
        "additions " .. tostring(f.add) .. ", chords " .. tostring(f.chordHead))
    Q.check(#f.retired == 0, "Style Full: the retired switches stay out of ZeD setup", table.concat(f.retired, " "))
end)
Q.step(10, function()
    Q.check(St.lite() == false and H.val("lookStyle") == 1, "Style Full: ZeD.Settings.lite() is false once applied", tostring(H.val("lookStyle")))
    local ok, d = H.formsAre(false)
    Q.check(ok, "Style Full: the forms' helpers all answer Full", d)
    Q.check(M.lite() == false, "Full buttons: ZeD.Molecules.lite() is false")
    local W = ZeD.Watch
    local place = H.val("watchPlace")
    Q.check(W.lite() == false and W.beltMode() == (place == nil or place == 1), "Full watch: its place is the Watch option's again",
        "belt " .. tostring(W.beltMode()) .. ", option " .. tostring(place))
    local D = ZeD.Dashboard
    local id, idP = nil, nil
    pcall(function() local _; _, id = D._designFor("Base.PickUpTruck") end)
    pcall(function() local _; _, idP = D._designFor("Base.CarLightsPolice") end)
    Q.check(id ~= nil and id ~= "dashelite" and idP ~= "dashelite", "Full dashboard: a pickup and a police car have their own dash again",
        tostring(id) .. ", " .. tostring(idP))
    local f = H.faces()
    local lost = {}
    for k in pairs(f.power) do
        if not (S.facesLite and S.facesLite.power[k]) and #lost < 6 then lost[#lost + 1] = k end
    end
    Q.check(f.extras > 0, "Full device faces: the radios' preset keys, memory key and lamp come back", f.extras .. " readings with them")
    Q.check(#lost == 0, "Lite device faces: every plate's power row stays in Lite", table.concat(lost, " "))
end)
Q.step(30, function()
    RT.pairOpen()
    RT.charTab("loot")
end)
Q.step(30, function()
    local fl = H.toggle("flip")
    Q.check(fl ~= nil and fl.w == fl.h, "Full windows: List or Grid is the square picture key again", fl and (fl.w .. "x" .. fl.h) or "no key")
    local ids = H.moveIds()
    Q.check(H.has(ids, "same") and H.has(ids, "near"), "Full windows: Same type and Same type nearby come back", table.concat(ids, " "))
    S.seekPos = nil
end)
Q.waitFor(1, 240, function() return H.seekRow(S.pencil) end, function(ok)
    if ok then H.click(S.pencil) end
end)
Q.step(20, function()
    local card = RT.cw() and RT.cw()._itemCard
    local fr = card and card._flagRects
    Q.check(H.cardOn(S.pencil) and fr ~= nil and fr.fav ~= nil and fr.fav.x ~= nil, "Full windows: the item card has its marks strip again",
        fr and fr.fav and tostring(fr.fav.x) or "no rects")
    if H.cardOn(S.pencil) then H.click(S.pencil) end
end)

-- ===================================================================== map always light
-- (Nov 19 2026, QA: the FEATURE_MAP row "Map always light"; Settings.lua mapLight, MapsSurvey.lua M.key. Dark with
-- Always light reads light; Follows the theme reads dark; High contrast keeps its own either way. The theme and the
-- option put back after.)
Q.step(5, function()
    local MS = ZeD.MapsSurvey
    local o = St.mapLightOption
    if not (MS and MS.key and o and St.mapLight) then Q.check(false, "Map always light: the mapLight option and MapsSurvey.key are loaded"); return end
    local was = { ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize, o:getValue() }
    local r = {}
    pcall(function()
        ZeD.applyTheme("dark", was[2], was[3])
        o:setValue(2); r.dOn = MS.key()
        o:setValue(1); r.dOff = MS.key()
        ZeD.applyTheme("hicon", was[2], was[3])
        o:setValue(2); r.hOn = MS.key()
    end)
    pcall(function() o:setValue(was[4]); ZeD.applyTheme(was[1], was[2], was[3]) end)
    Q.check(r.dOn == "light", "Map always light: in Dark, Always light reads the Light map", tostring(r.dOn))
    Q.check(r.dOff == "dark", "Map always light: in Dark, Follows the theme reads the Dark map", tostring(r.dOff))
    Q.check(r.hOn == "hicon", "Map always light: High contrast keeps its own map", tostring(r.hOn))
    Q.check(ZeD.currentBase == was[1] and o:getValue() == was[4], "Map always light: the theme and the option put back", tostring(ZeD.currentBase))
end)

-- ===================================================================== put back
Q.mark()
Q.step(10, function()
    H.recStop()
    if H.menuUp() and not S.mu then H.toggleMenu() end
    local zo = H.opts()
    for id, v in pairs(S.opt0 or {}) do
        local o = zo and zo.dict and zo.dict[id]
        if o and o.selected ~= v then pcall(function() o:setValue(v) end) end
    end
    S.iniBack = H.writeIni(S.ini0)
    if S.pairWas then RT.pairOpen() else RT.pairShut() end
end)
Q.step(10, function()
    local bad = {}
    for id, v in pairs(S.opt0 or {}) do if H.val(id) ~= v then bad[#bad + 1] = id end end
    Q.check(#bad == 0 and H.val("lookStyle") == S.style0, "put back: every ZeD option as found, Style among them",
        "Style " .. tostring(H.val("lookStyle")) .. (#bad > 0 and (", off: " .. table.concat(bad, " ")) or ""))
    local now = H.readIni()
    Q.check(S.ini0 ~= nil and now ~= nil and table.concat(now, "\n") == table.concat(S.ini0, "\n"), "put back: ModOptions.ini line for line",
        tostring(now and #now) .. " lines, " .. tostring(S.ini0 and #S.ini0) .. " before")
    Q.check(RT.isOpen() == S.pairWas, "put back: the windows open or shut as found")
    local e1 = nil
    pcall(function() e1 = getLuaDebuggerErrorCount() end)
    if S.err0 and e1 then Q.check(e1 == S.err0, "Lite and Full drew with no Lua error", (e1 - S.err0) .. " new") end
end)
Q.start()
