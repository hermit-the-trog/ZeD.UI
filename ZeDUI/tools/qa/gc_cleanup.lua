-- ZeDUI/tools/qa/gc_cleanup.lua  (Nov 22 2026, QA; tag gc_cln): Design's graphic cleanup in game (handoff
-- ZeDUI/HANDOFF_design_graphic_cleanup_20261121.md, commit 01a436b52, merged in ba8084973), its "## QA" list: the body
-- figure (canvas 106 x 272, no grid, the height ruler; Health, Thermal, Equipment's defense view, the medical check
-- card), the Vehicle tab (the parts out of their boxes, no grid box, the car centered at 2x at 4K) and the laundry
-- card's room (the tile floor round the top-loading washer, the painted wall and baseboard behind the dryer and the
-- washer-dryer). Pictures on the 1.0 gallery's staging (kiss_loot.lua: HFR.init, S.DIR, S.shot, the pointer the game
-- reads parked, placed objects, the put-back) and rt_kit-style checks (PASS / FAIL lines, "VERDICT" at the end, as
-- vk3_win.lua). Manifest gc_cleanup.txt (no story stage: the car needs the drag strip, ZEDQA_HOME). 4K full screen.
-- Pictures to Zomboid/Screenshots/gc_cln_<name>.png:
--   health_dark, health_light, health_hc   the Health tab, a scratch on one arm and a laceration on one leg (infection
--                                          off, bleeding stopped, healed after), Dark, Light, High Contrast
--   thermal_dark, equip_defense_dark       the Thermal tab; the Equipment tab with its list folded so the Defense view
--                                          (the figure) stands under the header
--   medcard_336, medcard_220               the medical check card (ObjectCardMedic.lua) held so its BODY is 336 units
--                                          wide (two columns, the text column 336 - figure - 10), and held to the half
--                                          card, 220 (stacked). In single player there is no other player to check:
--                                          the patient is a stand-in table that answers every call with the
--                                          character's own (his body, his name), opened through the kind's own
--                                          resolve and ZeD_WorldWindow.openObjectCard, as OC.open does. The card's
--                                          width is held by its own prerender (the drawer stays 480 wide)
--   vehicle_tab, vehicle_part_missing      a Base.CarNormal (the prelude's ZEDQA_CAR_WAIT), repaired, the Vehicle tab
--                                          opened as the mechanics key does (MechanicsTab.openFromAction); then its
--                                          battery taken out, its windshield smashed and a tire worn down
--   laundry_washer_full / _narrow, laundry_dryer_full / _narrow, laundry_combo_full, laundry_popout
--                                          a washer, a dryer and a washer-dryer placed one square from him (the
--                                          game's tiles, as rt_cards.lua finds them); each card on the full card and
--                                          held to a 336-unit body (the main face); the washer's face popped out
--                                          (FacePop.open). The faces' ids are logged (t._face)
-- Checks (Q.check, "ZEDQA gc_cln PASS|FAIL ..."):
--   canvas      ZeD.Spacing.figureW / figureH are 106 / 272, T.sp's are those at T.art, and the figure's background
--               (fig-bg-*) is drawn 106 x 272 at the figure's whole zoom from a 106 x 272 picture: each tab, each
--               theme on Health, the medical card
--   no grid     no texture named *grid* drawn by the panel in that frame (its draws recorded for one frame)
--   parts       every part getPartRects gives (17) hovers and selects by mouse at a point inside its focus box that
--               the figure's hit map gives to it (the drawer's own onMouseMove; Health: the drawer's onMouseDown / Up,
--               the pending press opening the part's treatment, the call recorded and not run) and by the pad (the
--               part's stop found by FocusManager.focusWhere, its rect the focus box, the tab's own field set by
--               onFocus; A through Focus.qaButton and dispatchJoypadDown; Health: A opens the part's treatment,
--               recorded and not run)
--   medical     the card's own layout: at body 336 the figure at the body's left and the text column beside it; on
--               the half card the figure centered and the text under it (ZeD_BodyFigure.drawAt and
--               HealthTab.drawOverall / _renderDetailView recorded for one frame on the card)
--   laundry     at 480, a 336-unit body and the half card, for each machine: nothing the card draws lies outside its
--               rect, and the room fills the body from edge to edge on the face's rows (the card's draws recorded)
--   vehicle     no grid box drawn; the car's base picture is MechFigs' size (no callout boxes baked in); the car is
--               centered in the diagram's room at a whole zoom (2 at 4K); the missing battery and the smashed
--               windshield draw their rims
-- The pointer the game reads is parked off every window (getMouseX / getMouseY swapped, as kiss_loot.lua) except for
-- the hover tests; the real pointer hidden; ZeD's input mode locked to the mouse; the window in the picture held "in
-- use". Every picture waits for the windows to stop moving and for 3.6 s with no new Lua error.
-- What it puts back: the theme (base, accent, size) as found, the wounds healed (only parts it hurt; the body made
-- whole if it lost health), the treatment call, the figure and draw wrappers, the pad's focus and its A, the card's
-- width hold, the card and the pop-out closed, the machines removed, the car's look ended and the car removed, the
-- tabs' figure folds, the equipment list fold, the hover and pad fields, the input lock, the pointer swap, the windows'
-- "in use" test, both windows' places, sizes, pins and tabs (ZEDQA_LAYOUT_BACK), the pair as found, him where he stood.
-- Not undone: unread Messages marked read before each picture (kiss_loot.lua's practice). grep "ZEDQA gc_cln".
local S = HFR and HFR.init and HFR.init("gc_cln", true)
if not S then return end
local Q = S.Q
S.DIR = "gc_cln_"
Q.maxMs = 900000
S.pic, S.held, S.rec, S.clicked, S.placed, S.hurt, S.flags = {}, {}, {}, {}, {}, {}, {}
S.F = ZeD and ZeD.Input and ZeD.Input.Focus
S.Det = ZeD and ZeD.Input and ZeD.Input.Detector
S.NAMES = { "Head", "Neck", "Upper Torso", "Lower Torso", "Groin", "Left Upper Arm", "Right Upper Arm", "Left Forearm",
    "Right Forearm", "Left Hand", "Right Hand", "Left Upper Leg", "Right Upper Leg", "Left Lower Leg", "Right Lower Leg",
    "Left Foot", "Right Foot" }
S.TABS = {
    health  = { label = "Health", fig = "_healthBodyFigure", hover = "_healthHoveredPart", view = "_healthView",
                padField = "_gpFocusedBodyPart", click = true },
    thermal = { label = "Thermal", fig = "_thermalBodyFigure", hover = "_thermalHoveredPart", view = "_thermalBodyRect",
                padField = "_gpFocusedThermalPart" },
    equip   = { label = "Equipment's defense view", fig = "_equipDefBodyFigure", hover = "_equipDefHoveredPart",
                padField = "_equipDefHoveredPart" },
}
S.WOUNDS = { { kind = "scratch", parts = { "ForeArm_L", "Hand_L", "UpperArm_L" } },
             { kind = "cut", parts = { "UpperLeg_R", "LowerLeg_R", "ForeArm_R" } } }
S.CARS = { "Base.CarNormal", "Base.PickUpTruck" }
S.MACHINES = { { key = "washer", cls = "IsoClothingWasher" }, { key = "dryer", cls = "IsoClothingDryer" },
               { key = "combo", cls = "IsoCombinationWasherDryer" } }
S.REC_FNS = { "drawRect", "drawRectBorder", "drawTexture", "drawTextureScaled", "drawTextureScaledAspect",
              "drawTextureScaledUniform", "drawTextZoomed" }

-- ===================================================================== the checks (rt_kit.lua's way)
Q.pass, Q.fail, Q.skips = 0, 0, 0
function Q.check(ok, what, detail)
    if ok then Q.pass = Q.pass + 1 else Q.fail = Q.fail + 1 end
    Q.say((ok and "PASS " or "FAIL ") .. tostring(what) .. (detail ~= nil and (" | " .. tostring(detail)) or ""))
    return ok and true or false
end
function Q.skip(what, why) Q.skips = Q.skips + 1; Q.say("SKIP " .. tostring(what) .. " (" .. tostring(why) .. ")") end
-- a step that throws is a FAIL (G1's queue only logs it)
S.step0, S.wait0 = Q.step, Q.waitFor
function S.guard(fn)
    return function(res)
        local ok, e = pcall(fn, res)
        if not ok then Q.check(false, "a step ran without an error", tostring(e)) end
    end
end
function Q.step(n, fn) S.step0(n, S.guard(fn)) end
function Q.waitFor(n, max, cond, fn) S.wait0(n, max, cond, S.guard(fn)) end
function S.verdict()
    Q.step(2, function()
        Q.say(string.format("checks: %d pass, %d fail, %d skipped", Q.pass, Q.fail, Q.skips))
        Q.say(Q.fail > 0 and ("VERDICT FAIL " .. Q.fail) or ("VERDICT PASS " .. Q.pass))
    end)
end

if not (ZeD and ZeD.T and ZeD.T.px and ZeD.T.sp and ZeD.Spacing and ZeD_BodyFigure and ZeD.HealthTab and ZeD.ObjectCards
        and ZeD.ObjectCards.kinds and ZeD.ObjectCards.kinds.medic and ZeD.ObjectCardLaundry and ZeD.MechanicsTab
        and ZeD.MechanicsTab.getState and ZeD.MechFigs and S.F and S.F.focusWhere and S.F.qaButton and S.F.dispatchJoypadDown
        and S.F.claimFocus and ZeD_WorldWindow and ZeD_WorldWindow.openObjectCard and ZeD_ObjectCard and ZeD.applyTheme
        and S.CWm and S.WWm and S.CWm.toggleBothPaired) then
    Q.check(false, "ZeD's body figure, tabs, cards, focus and theme are loaded")
    S.verdict()
    Q.start()
    return
end

-- ===================================================================== the error watch, the still, the picture
S.errN, S.errAt = nil, -100000
function S.errWatch()
    local n = nil
    if getLuaDebuggerErrorCount then n = getLuaDebuggerErrorCount() end
    if n ~= nil and n ~= S.errN then
        if S.errN ~= nil then S.errAt = getTimestampMs() end
        S.errN = n
    end
end
function S.quiet() S.errWatch(); return getTimestampMs() - S.errAt > 3600 end
Events.OnPreUIDraw.Add(S.errWatch)
function Q.still(n, fn)
    local st = { last = nil, same = 0 }
    Q.waitFor(n, 900, function()
        local s = G1.shape()
        if s == st.last then st.same = st.same + 1 else st.last, st.same = s, 0 end
        return st.same >= 30 and S.quiet()
    end, fn)
end
function S.notesRead()
    local M = ZeD.Messages
    if not (M and M.unread and M.markAllRead) then return end
    if M.readErrors then pcall(M.readErrors) end
    local un = 0
    pcall(function() un = M.unread() end)
    if (un or 0) > 0 then pcall(M.markAllRead) end
    if M.toasts and M.dropToast then
        for i = #M.toasts, 1, -1 do
            local t = M.toasts[i]
            if t and t.kind == "crit" then pcall(M.dropToast, t) end
        end
    end
    if (un or 0) > 0 then Q.say("note: before the picture " .. tostring(un) .. " unread message(s) marked read") end
end
function S.shotOk(name, what)
    S.notesRead()
    if not S.quiet() then
        Q.say("NOTE " .. name .. ": a Lua error came " .. tostring(getTimestampMs() - S.errAt) .. " ms before the picture")
    end
    S.shot(name)
    S.pic[#S.pic + 1] = name
    Q.say("SHOT " .. name .. " | " .. tostring(what))
end
function S.skipShot(name, why) Q.notTaken(name, why); Q.say("SKIP " .. name .. " | " .. tostring(why)) end
-- time, not frames: cond asked every 100 ms, at most ms; fn(true) when it came true (kiss_loot.lua)
function S.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 400000, function()
        local now = getTimestampMs()
        st.t = st.t or now
        if st.last and now - st.last < 100 then return false end
        st.last = now
        local ok, r = pcall(cond)
        if ok and r then st.ok = true; return true end
        return now - st.t >= ms
    end, function() fn(st.ok == true) end)
end
function S.n(v)
    local x = tonumber(v)
    if x == nil then return "?" end
    return tostring(math.floor(x * 10 + 0.5) / 10)
end

-- ===================================================================== the pointer the game reads, the input lock, "in use"
function S.mouseOn(x, y)
    S.fx, S.fy = x, y
    if S.mouseSwapped then return end
    S.realMX, S.realMY = getMouseX, getMouseY
    S.mouseSwapped = true
    pcall(function()
        getMouseX = function() return S.fx end
        getMouseY = function() return S.fy end
    end)
end
function S.mouseOff()
    if not S.mouseSwapped then return end
    pcall(function() getMouseX, getMouseY = S.realMX, S.realMY end)
    S.mouseSwapped = false
end
function S.park() S.mouseOn(-9000, -9000) end
function S.lockFound()
    local key = nil
    pcall(function()
        local o = S.opt("inputModeLock")
        local keys = ZeD.Settings.inputLockKeys
        if o and keys then key = keys[o:getValue() or 1] end
    end)
    return key or "auto"
end
function S.lock(mode)
    if not (S.Det and S.Det.setLockedMode) then return end
    pcall(function()
        if S.lockWas == nil then S.lockWas = S.lockFound() end
        if mode then
            S.Det.setLockedMode(mode)
            S.locked = true
            return
        end
        if not S.locked then return end
        S.locked = false
        S.Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then S.Det.setLockedMode(S.lockWas) end
    end)
end
function S.holdWin(w, val)
    if not w then return end
    w.pointerOn = function() return val end
    S.held[#S.held + 1] = w
end
function S.unhold()
    for _, w in ipairs(S.held) do w.pointerOn = nil end
    S.held = {}
end
-- the Character window in use for its tabs' pictures, the World window for its cards and tabs
function S.holdFor(which)
    S.unhold()
    S.holdWin(S.CW(), which == "char")
    S.holdWin(S.WW(), which == "world")
end

-- ===================================================================== the draw recorder (one frame of a panel's draws)
function S.texInfo(tex)
    local nm, tw, th = nil, nil, nil
    if type(tex) == "string" then return tex, nil, nil end
    if tex == nil then return nil, nil, nil end
    pcall(function() nm = tex:getName() end)
    pcall(function() tw = tex:getWidthOrig(); th = tex:getHeightOrig() end)
    if tw == nil then pcall(function() tw = tex:getWidth(); th = tex:getHeight() end) end
    return nm, tw, th
end
function S.recAdd(R, fn, a1, a2, a3, a4, a5)
    local d = { fn = fn }
    if fn == "drawRect" or fn == "drawRectBorder" then
        d.x, d.y, d.w, d.h = a1, a2, a3, a4
    elseif fn == "drawTextZoomed" then
        d.x, d.y, d.w, d.h, d.text = a2, a3, 0, 0, true
    else
        d.name, d.tw, d.th = S.texInfo(a1)
        d.x, d.y = a2, a3
        if fn == "drawTexture" then d.w, d.h = d.tw or 0, d.th or 0
        elseif fn == "drawTextureScaledUniform" then d.w, d.h = (d.tw or 0) * (a4 or 1), (d.th or 0) * (a4 or 1)
        else d.w, d.h = a4, a5 end
    end
    d.x, d.y, d.w, d.h = tonumber(d.x) or 0, tonumber(d.y) or 0, tonumber(d.w) or 0, tonumber(d.h) or 0
    R.list[#R.list + 1] = d
end
function S.recFn(R, fn, orig)
    return function(self, a1, a2, a3, a4, a5, ...)
        pcall(S.recAdd, R, fn, a1, a2, a3, a4, a5)
        return orig(self, a1, a2, a3, a4, a5, ...)
    end
end
function S.recOn(key, panel)
    S.recOff(key)
    if not panel then return false end
    local R = { panel = panel, own = {}, list = {} }
    for _, fn in ipairs(S.REC_FNS) do
        R.own[fn] = rawget(panel, fn) or false
        local orig = panel[fn]
        if orig then panel[fn] = S.recFn(R, fn, orig) end
    end
    S.rec[key] = R
    return true
end
function S.recOff(key)
    local R = S.rec[key]
    if not R then return nil end
    for _, fn in ipairs(S.REC_FNS) do
        local o = R.own[fn]
        if o then R.panel[fn] = o else R.panel[fn] = nil end
    end
    S.rec[key] = nil
    return R
end
function S.recAllOff()
    local keys = {}
    for k in pairs(S.rec) do keys[#keys + 1] = k end
    for _, k in ipairs(keys) do S.recOff(k) end
end
function S.recCount()
    local n = 0
    for _ in pairs(S.rec) do n = n + 1 end
    return n
end

-- ===================================================================== the theme, the wounds
function S.theme(base)
    if ZeD.currentBase == base then return end
    pcall(ZeD.applyTheme, base, ZeD.currentAccent, ZeD.currentSize)
    Q.say("theme " .. tostring(ZeD.currentBase) .. " (" .. tostring(ZeD.currentAccent) .. ", " .. tostring(ZeD.currentSize) .. ")")
end
function S.bd() local bd = nil; pcall(function() bd = S.p:getBodyDamage() end); return bd end
function S.bp(typeName)
    local bd, t, bp = S.bd(), BodyPartType and BodyPartType[typeName], nil
    if not (bd and t) then return nil end
    pcall(function() bp = bd:getBodyPart(t) end)
    return bp
end
function S.partClean(bp)
    local hurt = true
    pcall(function() hurt = bp:scratched() or bp:isCut() or bp:bleeding() or bp:deepWounded() end)
    return not hurt
end
function S.stage(bp, kind)
    if kind == "scratch" then pcall(function() bp:setScratched(true, true) end)
    else
        pcall(function() bp:setCut(true) end)
        pcall(function() bp:setCutTime(20) end)
    end
    pcall(function() bp:setInfectedWound(false) end)
    pcall(function() bp:setBleeding(false) end)
    pcall(function() bp:setBleedingTime(0) end)
end
function S.heal(bp)
    pcall(function() bp:setScratched(false, true) end)
    pcall(function() bp:setScratchTime(0) end)
    pcall(function() bp:setCut(false) end)
    pcall(function() bp:setCutTime(0) end)
    pcall(function() bp:setBleeding(false) end)
    pcall(function() bp:setBleedingTime(0) end)
    pcall(function() bp:setInfectedWound(false) end)
    pcall(function() bp:RestoreToFullHealth() end)
end
function S.wounds(on)
    if on then
        local said = {}
        for _, W in ipairs(S.WOUNDS) do
            for _, nm in ipairs(W.parts) do
                local bp = S.bp(nm)
                if bp and S.partClean(bp) then
                    S.stage(bp, W.kind)
                    S.hurt[#S.hurt + 1] = bp
                    said[#said + 1] = W.kind .. " on " .. nm
                    break
                end
            end
        end
        Q.say("wounds staged: " .. ((#said > 0) and table.concat(said, ", ") or "none (every candidate part was already hurt)"))
        return
    end
    for _, bp in ipairs(S.hurt) do S.heal(bp) end
    local n = #S.hurt
    S.hurt = {}
    local bd = S.bd()
    if bd then
        local hp = nil
        pcall(function() hp = bd:getOverallBodyHealth() end)
        if hp and S.was.hp and hp < S.was.hp - 0.01 then pcall(function() bd:RestoreToFullHealth() end) end
        if S.was.infected == false then
            pcall(function() if bd:isInfected() then bd:setInfected(false); bd:setInfectionLevel(0) end end)
        end
    end
    if n > 0 then Q.say("wounds healed: " .. n .. " part(s)") end
end

-- ===================================================================== windows, tabs, the figure's folds
function S.homeLayout()
    if ZEDQA_LAYOUT_DEFAULT then pcall(ZEDQA_LAYOUT_DEFAULT, "gc_cln") else pcall(function() ZeD_Window.resetLayout() end) end
end
function S.flagsFound()
    local cw = S.CW()
    if not cw or S.flags.taken then return end
    S.flags.taken = true
    for _, k in ipairs({ "_healthFigureExpanded", "_thermalFigureExpanded", "_equipListExpanded", "_gpFocusedBodyPart",
                         "_gpFocusedThermalPart", "_gpFocusedEquipSlot", "_equipSelected" }) do
        S.flags[k] = { v = cw[k] }
    end
end
function S.flagsBack()
    local cw = S.CW()
    if not (cw and S.flags.taken) then return end
    for k, e in pairs(S.flags) do
        if type(e) == "table" then cw[k] = e.v end
    end
    S.clearHover()
end
function S.clearHover()
    local cw = S.CW()
    if not cw then return end
    cw._healthHoveredPart, cw._thermalHoveredPart, cw._equipDefHoveredPart = nil, nil, nil
end
function S.expand(id)
    local cw = S.CW()
    if not cw then return end
    S.flagsFound()
    if id == "health" then cw._healthFigureExpanded = true
    elseif id == "thermal" then cw._thermalFigureExpanded = true
    elseif id == "equip" then cw._equipListExpanded = false; cw._equipSelected = nil end
end
function S.fig(id)
    local cw = S.CW()
    return cw and cw[S.TABS[id].fig] or nil
end
function S.rects(fig)
    local r = {}
    if fig and fig.getPartRects then pcall(function() r = fig:getPartRects() end) end
    return r or {}
end
function S.rectOf(fig, name)
    for _, r in ipairs(S.rects(fig)) do if r.name == name then return r end end
    return nil
end
function S.tabReady(id)
    local cw = S.CW()
    if not (cw and cw._activeTab == id and cw._drawerMode == "tab" and cw._drawerPanel) then return false end
    if id == "equip" and cw._equipDefHidden then return false end
    return #S.rects(S.fig(id)) == #S.NAMES
end
function S.tabSay(id)
    local cw = S.CW()
    if not cw then return "no Character window" end
    return "tab " .. tostring(cw._activeTab) .. ", drawer " .. tostring(cw._drawerMode) .. ", focus boxes " .. #S.rects(S.fig(id))
        .. ", Find hides the Defense view " .. tostring(cw._equipDefHidden == true)
end
function S.tabStage(id)
    local C = S.TABS[id]
    Q.step(10, function()
        S.openPair()
        S.charTab(id)
        S.expand(id)
        S.clearHover()
    end)
    Q.waitFor(5, 600, function() S.expand(id); return S.tabReady(id) end, function(ok)
        C.off = not ok
        if not ok then Q.check(false, C.label .. ": the tab shows its body figure (staging)", S.tabSay(id)) end
    end)
    Q.step(2, function() if not C.off then S.holdFor("char"); S.clearChar() end end)
    Q.still(5, function() end)
end

-- ===================================================================== the figure's canvas and no grid
function S.figCheck(label, R, fig)
    local T, Sp = ZeD.T, ZeD.Spacing
    local s = fig and fig._drawAtS
    local bg, grids, n = nil, {}, 0
    for _, d in ipairs((R and R.list) or {}) do
        local nm = d.name and string.lower(tostring(d.name)) or ""
        if nm:find("fig-bg-", 1, true) then bg = d end
        if nm:find("grid", 1, true) then grids[#grids + 1] = nm end
        n = n + 1
    end
    local art = T.art or 1
    local tok = Sp.figureW == 106 and Sp.figureH == 272 and T.sp.figureW == 106 * art and T.sp.figureH == 272 * art
    local drawn = bg ~= nil and s ~= nil and math.abs(bg.w - 106 * s) < 0.6 and math.abs(bg.h - 272 * s) < 0.6
    local pic = bg ~= nil and bg.tw == 106 and bg.th == 272
    Q.check(tok and drawn and pic, label .. ": the figure's canvas is 106 x 272 (T.sp.figureW / figureH), drawn whole at its zoom",
        "tokens " .. tostring(Sp.figureW) .. " x " .. tostring(Sp.figureH) .. ", T.sp " .. tostring(T.sp.figureW) .. " x "
        .. tostring(T.sp.figureH) .. " at T.art " .. tostring(art) .. "; the background " .. (bg and (tostring(bg.name) .. " drawn "
        .. S.n(bg.w) .. " x " .. S.n(bg.h) .. " from a " .. tostring(bg.tw) .. " x " .. tostring(bg.th) .. " picture") or "not drawn")
        .. " at zoom " .. tostring(s))
    Q.check(R ~= nil and n > 0 and #grids == 0, label .. ": no grid is drawn behind the figure",
        n .. " draws recorded in the frame; grid textures: " .. ((#grids > 0) and table.concat(grids, ", ") or "none"))
end
function S.figCheckQ(id, label)
    local C = S.TABS[id]
    Q.step(2, function()
        local cw = S.CW()
        if not C.off and cw then S.recOn("fig", cw._drawerPanel) end
    end)
    Q.step(1, function()
        local R = S.recOff("fig")
        if C.off then return end
        S.figCheck(label or C.label, R, S.fig(id))
    end)
end

-- ===================================================================== every part by mouse and by pad
-- the treatment the Health tab opens for a part (the press's pending open, the pad's A): recorded, never run
function S.clickWrap(on)
    local HT = ZeD.HealthTab
    if on then
        if S.click0 then return end
        S.click0 = HT._onPartClicked
        HT._onPartClicked = function(win, name, ...) S.clicked[#S.clicked + 1] = name end
        return
    end
    if S.click0 then HT._onPartClicked = S.click0; S.click0 = nil end
end
-- a point inside the part's focus box that the figure's hit map gives to it, inside the body's view
function S.pointIn(fig, r, name, view)
    local function good(x, y)
        if view and not (x >= view.x and x < view.x + view.w and y >= view.y and y < view.y + view.h) then return false end
        local hit = nil
        pcall(function() hit = fig:hitTestAt(x, y) end)
        return hit == name
    end
    local cx, cy = r.x + math.floor(r.w / 2), r.y + math.floor(r.h / 2)
    if good(cx, cy) then return cx, cy end
    local g = math.max(2, math.floor((fig._drawAtS or 1) * 2))
    for y = r.y + 1, r.y + r.h - 2, g do
        for x = r.x + 1, r.x + r.w - 2, g do
            if good(x, y) then return x, y end
        end
    end
    return nil, nil
end
function S.loopStart(id, mode)
    local C = S.TABS[id]
    S.L = { id = id, C = C, mode = mode, i = 1, phase = 0, wait = 0, ok = 0, bad = {}, selN = 0 }
    if C.off then S.L.i = #S.NAMES + 1; return end
    S.clicked = {}
    if mode == "pad" then
        local cw = S.CW()
        pcall(S.F.claimFocus, cw)
        if S.F.getFocusedWindow(S.pn) ~= cw then S.L.noPad = true end
        S.L.wait = 6   -- (the tab's stops rebuilt and seeded once with the pad on the window before the first part)
    end
end
function S.partBad(L, name, why)
    L.bad[#L.bad + 1] = name .. ": " .. tostring(why)
    L.i, L.phase, L.wait, L.t = L.i + 1, 0, 0, nil
end
function S.loopTick()
    local L = S.L
    if not L or L.i > #S.NAMES then return true end
    if L.wait > 0 then L.wait = L.wait - 1; return false end
    if L.t and getTimestampMs() - L.t < (L.ms or 0) then return false end
    if L.noPad then
        for _, nm in ipairs(S.NAMES) do L.bad[#L.bad + 1] = nm .. ": the pad could not be given to the Character window" end
        L.i = #S.NAMES + 1
        return true
    end
    local ok, e = pcall(L.mode == "pad" and S.padStep or S.mouseStep, L)
    if not ok then S.partBad(L, tostring(S.NAMES[L.i]), "the step threw: " .. tostring(e)) end
    return L.i > #S.NAMES
end
function S.mouseStep(L)
    local name = S.NAMES[L.i]
    local cw = S.CW()
    local fig = cw and cw[L.C.fig]
    local d = cw and cw._drawerPanel
    if not (fig and d) then return S.partBad(L, name, "no figure or drawer") end
    if L.phase == 0 then
        local r = S.rectOf(fig, name)
        if not r then return S.partBad(L, name, "no focus box from getPartRects") end
        local px, py = S.pointIn(fig, r, name, L.C.view and cw[L.C.view] or nil)
        if not px then return S.partBad(L, name, "no point inside its focus box maps to it (hitTestAt)") end
        L.px, L.py = px, py
        S.mouseOn(d:getAbsoluteX() + px, d:getAbsoluteY() + py)
        d:onMouseMove(0, 0)
        L.hov = cw[L.C.hover]
        L.nClick = #S.clicked
        L.press = nil
        if L.C.click then
            d:onMouseDown(px, py)
            d:onMouseUp(px, py)
            L.press = cw._healthPress and cw._healthPress.part or nil
        end
        S.park()
        L.phase, L.wait = 1, 2
        return
    end
    local sel = fig.selectedPart
    local opened = L.C.click and S.clicked[L.nClick + 1] or nil
    local good = L.hov == name and sel == name and (not L.C.click or (L.press == name and opened == name))
    if good then L.ok = L.ok + 1
    else
        L.bad[#L.bad + 1] = name .. ": at " .. L.px .. "," .. L.py .. " hovered " .. tostring(L.hov) .. ", lit " .. tostring(sel)
            .. (L.C.click and (", pressed " .. tostring(L.press) .. ", its treatment opened for " .. tostring(opened)) or "")
    end
    L.i, L.phase, L.wait = L.i + 1, 0, 0
end
function S.padStep(L)
    local name = S.NAMES[L.i]
    local cw = S.CW()
    local fig = cw and cw[L.C.fig]
    local F = S.F
    if not fig then return S.partBad(L, name, "no figure") end
    if L.phase == 0 then
        local e = F.focusWhere(cw, "charTabContent", function(x) return x.partName == name end)
        if not e then return S.partBad(L, name, "the pad has no stop for it") end
        local r = S.rectOf(fig, name)
        L.box = r ~= nil and e.x == r.x and e.w == r.w and e.y >= r.y and e.y + e.h <= r.y + r.h
        L.boxSay = r and (e.x .. "," .. e.y .. " " .. e.w .. "x" .. e.h .. " in the box " .. r.x .. "," .. r.y .. " " .. r.w .. "x" .. r.h) or "no box"
        L.field = cw[L.C.padField] == name
        L.nClick = #S.clicked
        F.qaButton("A", true, S.pn)
        pcall(F.dispatchJoypadDown, cw, Joypad.AButton)
        L.phase, L.wait, L.t, L.ms = 1, 2, getTimestampMs(), 120
        return
    end
    if L.phase == 1 then
        F.qaButton("A", false, S.pn)
        L.phase, L.wait, L.t, L.ms = 2, 3, getTimestampMs(), 100
        return
    end
    F.qaButton("A", nil, S.pn)
    local el = F.getFocusedElement(cw)
    local still = el ~= nil and el.partName == name
    local opened = L.C.click and S.clicked[L.nClick + 1] or nil
    if fig.selectedPart == name then L.selN = L.selN + 1 end
    local good = L.box and L.field and still and (not L.C.click or opened == name)
    if good then L.ok = L.ok + 1
    else
        L.bad[#L.bad + 1] = name .. ": the stop " .. tostring(L.boxSay) .. ", the tab's field " .. tostring(L.field)
            .. ", still focused after A " .. tostring(still) .. (L.C.click and (", A opened the treatment for " .. tostring(opened)) or "")
    end
    L.i, L.phase, L.wait, L.t = L.i + 1, 0, 0, nil
end
function S.loopEnd(ok)
    local L = S.L
    if not L then return end
    if L.mode == "pad" then
        pcall(S.F.qaButton, "A", nil, S.pn)
        pcall(S.F.releaseFocus, S.pn)
    end
    S.park()
    S.clearHover()
    if L.C.off then S.L = nil; return end
    local what
    if L.mode == "mouse" then
        what = L.C.label .. ": every body part hovers and is lit by the mouse at a point inside its focus box (getPartRects)"
            .. (L.C.click and ", and a press opens its treatment" or "")
    else
        what = L.C.label .. ": every body part is a pad stop on its focus box (getPartRects) and the tab follows it"
            .. (L.C.click and "; A opens its treatment" or "; A does nothing there (readout only)")
    end
    local detail = L.ok .. " of " .. #S.NAMES .. " parts" .. (ok and "" or " (the loop ran out of time)")
    if L.mode == "pad" then detail = detail .. "; lit on the figure by the pad " .. L.selN .. " of " .. #S.NAMES .. " (NOTE only)" end
    if #L.bad > 0 then detail = detail .. "; " .. table.concat(L.bad, "; ") end
    Q.check(ok and L.ok == #S.NAMES, what, detail)
    S.L = nil
end
function S.partsQ(id, mode)
    Q.step(2, function() S.loopStart(id, mode) end)
    Q.waitFor(1, #S.NAMES * 40 + 200, S.loopTick, function(ok) S.loopEnd(ok) end)
end

-- ===================================================================== a tab's picture in a theme
function S.tabShot(id, base, name)
    local C = S.TABS[id]
    Q.step(5, function()
        if C.off then return end
        S.theme(base)
        S.openPair()
        S.charTab(id)
        S.expand(id)
        S.clearHover()
        S.park()
        S.holdFor("char")
        S.clearChar()
    end)
    Q.still(10, function() end)
    Q.waitFor(1, 300, function() return C.off or S.tabReady(id) end, function() end)
    S.figCheckQ(id, C.label .. " (" .. base .. ")")
    Q.step(2, function()
        if C.off then S.skipShot(name, C.label .. " did not show its figure"); return end
        S.shotOk(name, C.label .. " in " .. tostring(ZeD.currentBase) .. ", the Character window held in use, the pointer parked")
    end)
end

-- ===================================================================== the medical check card
-- a stand-in patient: every method call answered with the character's own (single player has no other player)
function S.proxyOf(pl)
    local px = { _gcQaPatient = true }
    setmetatable(px, { __index = function(t, k)
        if type(k) ~= "string" then return nil end
        local m = nil
        pcall(function() m = pl[k] end)
        if m == nil then return nil end
        local f = function(self, ...) return m(pl, ...) end
        rawset(t, k, f)
        return f
    end })
    return px
end
function S.card()
    local c = nil
    pcall(function() c = ZeD_WorldWindow.getObjectCard(S.pn) end)
    return c
end
function S.entryT()
    local c = S.card()
    local e = c and c.entry
    return e and e.t or nil
end
function S.closeCard()
    if S.card() then pcall(ZeD_WorldWindow.closeObjectCard, S.pn) end
end
-- the card's width held by its own prerender: mode { body = units } (the body that wide) or { card = units }
function S.cardHook()
    local ww = S.WW()
    local card = ww and ww._objectCard
    if not card or S.hooked == card then return end
    S.hooked = card
    S.hookOwn = rawget(card, "prerender") or false
    local base = S.hookOwn or ZeD_ObjectCard.prerender
    card.prerender = function(self)
        local m = S.cardMode
        if m then
            local T = ZeD.T
            local w
            if m.card then w = T.px(m.card)
            else
                local sb = (self.scroll and self.scroll.visible) and T.sp.scrollbarW or 0
                w = T.px(m.body) + 2 * T.px(10) + sb
            end
            if math.abs(self:getWidth() - w) > 0.5 then self:setWidth(w) end
        end
        return base(self)
    end
end
function S.cardUnhook()
    local card = S.hooked
    S.cardMode = nil
    if not card then return end
    if S.hookOwn then card.prerender = S.hookOwn else card.prerender = nil end
    S.hooked, S.hookOwn = nil, nil
end
function S.medOpen()
    local def = ZeD.ObjectCards.kinds.medic
    S.patient = S.proxyOf(S.p)
    local t = nil
    pcall(function() t = def.resolve(S.p, S.patient) end)
    if not t then return false, "the kind's resolve gave nothing" end
    t._ended = true   -- (its close then never asks the game to stop sending the stand-in's body: there is no such player)
    S.medT = t
    local ok, r = pcall(ZeD_WorldWindow.openObjectCard, S.pn, { def = def, t = t })
    return ok and r == true, tostring(r)
end
function S.medWrap(on)
    local HT = ZeD.HealthTab
    if on then
        if S.med0 then return end
        S.medRec = {}
        S.med0 = { drawAt = ZeD_BodyFigure.drawAt, overall = HT.drawOverall, detail = HT._renderDetailView }
        local card = S.card()
        ZeD_BodyFigure.drawAt = function(self, panel, px, py, pw, ph)
            if panel == card then S.medRec.fig = { x = px, y = py, w = pw, h = ph, obj = self } end
            return S.med0.drawAt(self, panel, px, py, pw, ph)
        end
        HT.drawOverall = function(panel, x, y, w, data)
            if panel == card then S.medRec.text = { x = x, y = y, w = w, how = "summary" } end
            return S.med0.overall(panel, x, y, w, data)
        end
        HT._renderDetailView = function(panel, win, data, nm, rx, ry, rw)
            if panel == card then S.medRec.text = { x = rx, y = ry, w = rw, how = "part" } end
            return S.med0.detail(panel, win, data, nm, rx, ry, rw)
        end
        return
    end
    if not S.med0 then return end
    ZeD_BodyFigure.drawAt, HT.drawOverall, HT._renderDetailView = S.med0.drawAt, S.med0.overall, S.med0.detail
    S.med0 = nil
end
function S.bodyOf(card)
    local T = ZeD.T
    local sb = (card.scroll and card.scroll.visible) and T.sp.scrollbarW or 0
    local pad = T.px(10)
    return pad, card:getWidth() - sb - 2 * pad
end
function S.medCheck(M)
    local T = ZeD.T
    local card = S.card()
    local f, tx = S.medRec and S.medRec.fig, S.medRec and S.medRec.text
    if not (card and f and tx) then
        Q.check(false, "medical card (" .. M.say .. "): the figure and the text column are drawn", "figure " .. tostring(f ~= nil) .. ", text " .. tostring(tx ~= nil))
        return
    end
    local bx, bw = S.bodyOf(card)
    local figW, figH = T.sp.figureW, T.sp.figureH
    local ok, want
    if M.two then
        want = "the figure at the body's left, the text column beside it"
        local cx, cw = bx + figW + T.px(10), bw - figW - T.px(10)
        ok = math.abs(f.x - bx) <= 1 and math.abs(tx.x - cx) <= 1 and math.abs(tx.w - cw) <= 1 and math.abs(tx.y - f.y) <= 1
    else
        want = "the figure centered, the text under it at the body's full width"
        local fx = bx + math.floor((bw - figW) / 2)
        ok = math.abs(f.x - fx) <= 1 and math.abs(tx.x - bx) <= 1 and math.abs(tx.w - bw) <= 1 and math.abs(tx.y - (f.y + figH + T.px(8))) <= 1
    end
    local sc = T.scale or 1
    Q.check(ok, "medical card (" .. M.say .. "): " .. want,
        "card " .. S.n(card:getWidth() / sc) .. " units, body " .. S.n(bw / sc) .. " units (two columns from "
        .. S.n((figW + T.px(170)) / sc) .. "); figure at " .. S.n(f.x) .. "," .. S.n(f.y) .. " " .. S.n(f.w) .. " x " .. S.n(f.h)
        .. "; text (" .. tostring(tx.how) .. ") at " .. S.n(tx.x) .. "," .. S.n(tx.y) .. ", " .. S.n(tx.w) .. " px = " .. S.n(tx.w / sc) .. " units")
end
function S.medStep(M)
    Q.step(5, function()
        if S.medOff then return end
        S.cardHook()
        S.cardMode = M.mode
        S.park()
        S.holdFor("world")
        S.clearChar()
    end)
    Q.still(10, function() end)
    Q.step(1, function()
        if S.medOff then return end
        S.medWrap(true)
        S.recOn("card", S.card())
    end)
    Q.step(1, function()
        local R = S.recOff("card")
        S.medWrap(false)
        if S.medOff then return end
        S.medCheck(M)
        S.figCheck("medical card (" .. M.say .. ")", R, S.medRec and S.medRec.fig and S.medRec.fig.obj)
    end)
    Q.step(2, function()
        if S.medOff then S.skipShot(M.shot, "the medical card did not open"); return end
        S.shotOk(M.shot, "the medical check card (a stand-in patient: his own body), " .. M.say .. ", the World window held in use")
    end)
end

-- ===================================================================== the laundry machines
function S.laundryTile(cls)
    for i = 0, 47 do
        local name = "appliances_laundry_01_" .. i
        local spr = getSprite(name)
        local props = spr and spr:getProperties()
        if props and props:has("IsoType") and props:get("IsoType") == cls then return name end
    end
    return nil
end
S.RING = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
function S.freeSqs(n)
    local out, cell = {}, getCell()
    local x0, y0, z = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    for _, o in ipairs(S.RING) do
        local sq = cell:getGridSquare(x0 + o[1], y0 + o[2], z)
        local free = false
        if sq then pcall(function() free = sq:isFree(false) and sq:getVehicleContainer() == nil end) end
        if free and #out < n then out[#out + 1] = sq end
    end
    return out
end
function S.putMachine(m, sq)
    local tile = S.laundryTile(m.cls)
    if not (tile and sq) then return nil, "no " .. m.cls .. " tile" end
    local obj = nil
    pcall(function()
        if m.cls == "IsoClothingWasher" then obj = IsoClothingWasher.new(getCell(), sq, getSprite(tile))
        elseif m.cls == "IsoClothingDryer" then obj = IsoClothingDryer.new(getCell(), sq, getSprite(tile))
        else obj = IsoCombinationWasherDryer.new(getCell(), sq, getSprite(tile)) end
    end)
    if not obj then return nil, m.cls .. " not made" end
    pcall(function() obj:createContainersFromSpriteProperties() end)
    pcall(function() obj:createFluidContainersFromSpriteProperties() end)
    pcall(function() sq:AddSpecialObject(obj) end)
    pcall(function() if obj:getObjectIndex() < 0 then sq:AddTileObject(obj) end end)
    S.placed[#S.placed + 1] = obj
    if m.cls == "IsoCombinationWasherDryer" then pcall(function() obj:setModeWasher() end) end
    return obj, tile .. " at " .. sq:getX() .. "," .. sq:getY()
end
function S.placeMachines()
    local sqs = S.freeSqs(#S.MACHINES)
    local said = {}
    for i, m in ipairs(S.MACHINES) do
        local obj, how = S.putMachine(m, sqs[i])
        m.obj = obj
        said[#said + 1] = m.key .. ": " .. tostring(how)
    end
    Q.check(S.MACHINES[1].obj ~= nil and S.MACHINES[2].obj ~= nil and S.MACHINES[3].obj ~= nil,
        "a washer, a dryer and a washer-dryer placed one square from him (staging)", table.concat(said, "; "))
end
function S.removeMachines()
    local n = 0
    for _, obj in ipairs(S.placed) do
        local sq = nil
        pcall(function() sq = obj:getSquare() end)
        if sq then
            pcall(function() sq:transmitRemoveItemFromSquare(obj) end)
            pcall(function() if obj:getObjectIndex() >= 0 then sq:RemoveTileObject(obj) end end)
        end
        n = n + 1
    end
    S.placed = {}
    for _, m in ipairs(S.MACHINES) do
        if m.obj then m.gone = m.obj end
        m.obj = nil
    end
    return n
end
function S.standing()
    local n = 0
    for _, m in ipairs(S.MACHINES) do
        local i = -1
        if m.gone then pcall(function() i = m.gone:getObjectIndex() end) end
        if i >= 0 then n = n + 1 end
    end
    return n
end
-- the room behind the face fills the body edge to edge, and nothing the card draws lies outside it
function S.roomCheck(label, R, card, t)
    local T = ZeD.T
    local W, H = card:getWidth(), card:getHeight()
    local out, outSay = 0, nil
    for _, d in ipairs(R.list) do
        local bad = d.x < -0.5 or d.x + d.w > W + 0.5 or (not d.text and (d.y < -0.5 or d.y + d.h > H + 0.5))
        if bad then
            out = out + 1
            outSay = outSay or (d.fn .. " " .. tostring(d.name or "") .. " at " .. S.n(d.x) .. "," .. S.n(d.y) .. " " .. S.n(d.w) .. " x " .. S.n(d.h))
        end
    end
    if t and t._face == "plain" then
        Q.skip(label, "the Simple card shows (ZeD setup's Devices row): no face, no room")
        return
    end
    local X = ZeD.PhysPx
    local des = X and X.plates and t and t._face and X.plates[t._face]
    local k = t and t._k
    if not (des and k) then
        Q.check(false, label .. ": the face is drawn", "face " .. tostring(t and t._face) .. ", zoom " .. tostring(k))
        return
    end
    local bx, bw = S.bodyOf(card)
    local fy = (card._viewY or 0) + T.px(8) - (card._off or 0)
    local fh = des.h * k
    local minX, maxR, nb = nil, nil, 0
    for _, d in ipairs(R.list) do
        if d.fn == "drawRect" and d.h > 0 and d.w > 0 and d.y >= fy - 0.5 and d.y + d.h <= fy + fh + 0.5 then
            nb = nb + 1
            if not minX or d.x < minX then minX = d.x end
            if not maxR or d.x + d.w > maxR then maxR = d.x + d.w end
        end
    end
    local edges = minX ~= nil and math.abs(minX - bx) <= 0.5 and math.abs(maxR - (bx + bw)) <= 0.5
    Q.check(out == 0 and edges, label .. ": the room fills the body edge to edge and nothing is drawn outside the card",
        "face " .. tostring(t._face) .. " at zoom " .. tostring(k) .. "; card " .. S.n(W) .. " x " .. S.n(H) .. " px, body "
        .. S.n(bx) .. " .. " .. S.n(bx + bw) .. "; on the face's rows " .. nb .. " rects from " .. S.n(minX) .. " to " .. S.n(maxR)
        .. "; " .. #R.list .. " draws, " .. out .. " outside the card" .. (outSay and (" (first: " .. outSay .. ")") or ""))
end
S.WIDTHS = { full = { say = "the full card", mode = nil }, narrow = { say = "a 336-unit body", mode = { body = 336 } },
             half = { say = "the half card (220)", mode = { card = 220 } } }
function S.laundryRun(m, wkey, shot)
    local Wd = S.WIDTHS[wkey]
    local label = "laundry " .. m.key .. " on " .. Wd.say
    Q.step(5, function()
        if not m.obj then return end
        local t = S.entryT()
        if not (t and t.obj == m.obj) then pcall(ZeD.ObjectCardLaundry.open, S.p, m.obj) end
        S.cardHook()
        S.cardMode = Wd.mode
        S.park()
        S.holdFor("world")
        S.clearChar()
    end)
    Q.waitFor(5, 600, function()
        local t = S.entryT()
        return m.obj == nil or (t ~= nil and t.obj == m.obj and t._face ~= nil and t.d ~= nil)
    end, function(ok)
        if not m.obj then return end
        local t = S.entryT()
        if not ok then Q.check(false, label .. ": the card opens on the machine (staging)", "card on " .. tostring(t and t.obj)) end
    end)
    Q.still(10, function() end)
    Q.step(1, function() if m.obj then S.recOn("card", S.card()) end end)
    Q.step(1, function()
        local R = S.recOff("card")
        if not m.obj then Q.skip(label, "the machine was not placed"); return end
        local card, t = S.card(), S.entryT()
        if not (R and card and t and t.obj == m.obj) then Q.check(false, label .. ": the card's draws recorded (staging)"); return end
        S.roomCheck(label, R, card, t)
    end)
    if shot then
        Q.step(2, function()
            if not m.obj then S.skipShot(shot, "the " .. m.key .. " was not placed"); return end
            local t = S.entryT()
            S.shotOk(shot, "the " .. m.key .. "'s card on " .. Wd.say .. ", face " .. tostring(t and t._face) .. " at zoom " .. tostring(t and t._k)
                .. (Wd.mode and " (the card held to that width inside the 480 drawer)" or ""))
        end)
    end
end

-- ===================================================================== the car (zedqa_prelude.lua, vk3_screen.lua)
function S.carStart()
    if not ZEDQA_CAR_WAIT then S.carWhy = "the prelude's car helpers are not loaded"; return end
    S.carWaiting = true
    ZEDQA_CAR_WAIT(S.CARS[1], "gc_cln", function(v)
        S.carWaiting = false
        if S.carGaveUp then if ZEDQA_CAR_AWAY then ZEDQA_CAR_AWAY(v) end; return end
        S.car = { v = v, script = S.CARS[1] }
    end, function(why)
        S.carWaiting = false
        S.carWhy = why
    end, 4000)
end
function S.dist(v)
    local d = 999
    pcall(function()
        local dx, dy = v:getX() - S.p:getX(), v:getY() - S.p:getY()
        d = math.sqrt(dx * dx + dy * dy)
    end)
    return d
end
function S.tpTo(x, y, z)
    pcall(function()
        S.p:setX(x); S.p:setY(y); S.p:setZ(z)
        S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z)
    end)
end
S.BESIDE = { { -3, 0 }, { 3, 0 }, { -3, 1 }, { 3, -1 }, { 0, -5 }, { 0, 5 } }
-- him within the tab's reach of the car (4.5 tiles), on a free square beside it
function S.carNear(v)
    local d = S.dist(v)
    if d <= 4.0 then return d end
    local vx, vy, z = math.floor(v:getX()), math.floor(v:getY()), math.floor(S.p:getZ())
    for _, o in ipairs(S.BESIDE) do
        local sq = getCell():getGridSquare(vx + o[1], vy + o[2], z)
        local free = false
        if sq then pcall(function() free = sq:isFree(false) and sq:getVehicleContainer() == nil end) end
        if free then
            S.tpTo(vx + o[1] + 0.5, vy + o[2] + 0.5, z)
            Q.say("moved him beside the car (it stood " .. S.n(d) .. " tiles away): " .. (vx + o[1]) .. "," .. (vy + o[2]))
            return S.dist(v)
        end
    end
    return d
end
function S.carTabReady()
    local ww = S.WW()
    local v = S.car and S.car.v
    if not (ww and v and ww._activeTab == "vehicle") then return false end
    local s = ZeD.MechanicsTab.getState(ww)
    local cur = s and s.vehicles and s.vehicles[s.idx or 1]
    return cur ~= nil and cur.vehicle == v and s.view == "overview" and s.figZones ~= nil and #s.figZones > 0 and s.rightClip ~= nil
end
function S.carCheck(R)
    local T = ZeD.T
    local F = ZeD.MechFigs
    local grid, base, pre = {}, nil, nil
    for _, d in ipairs(R.list) do
        local nm = d.name and string.lower(tostring(d.name)) or ""
        if nm:find("grid", 1, true) then grid[#grid + 1] = nm end
        local p = nm:match("zm_([%w]+)_base")
        if p then base, pre = d, p .. "_" end
    end
    Q.check(#R.list > 0 and #grid == 0, "Vehicle tab: no grid box is drawn behind the car",
        #R.list .. " draws recorded; grid textures: " .. ((#grid > 0) and table.concat(grid, ", ") or "none"))
    local L = pre and F.layers and F.layers[pre .. "base"]
    local U = pre and F.unions and F.unions[pre]
    if not (base and L and U) then
        Q.check(false, "Vehicle tab: the car's base picture is drawn", "base " .. tostring(base and base.name) .. ", body shape " .. tostring(pre))
        return nil
    end
    Q.check(base.tw == L.w and base.th == L.h, "Vehicle tab: the car's base picture is the body alone, MechFigs' size (no callout boxes)",
        tostring(base.name) .. " is " .. tostring(base.tw) .. " x " .. tostring(base.th) .. ", MechFigs " .. L.w .. " x " .. L.h
        .. " (union " .. U.w .. " x " .. U.h .. ")")
    local ww = S.WW()
    local s = ww and ZeD.MechanicsTab.getState(ww)
    local clip = s and s.rightClip
    local sc = base.w / L.w
    local whole = math.abs(sc - math.floor(sc + 0.5)) < 0.01
    local want = (S.core:getScreenWidth() >= 3800) and 2 or nil
    local pad = T.px(10)
    local areaC = clip and (clip.x + pad + (clip.w - T.sp.scrollbarW - 2 * pad) / 2) or 0
    local ox = base.x - (L.x - U.x) * sc
    local uC = ox + U.w * sc / 2
    Q.check(clip ~= nil and whole and (want == nil or math.abs(sc - want) < 0.01) and math.abs(uC - areaC) <= 1,
        "Vehicle tab: the car is centered in the diagram's room at a whole zoom" .. (want and " (2x at 4K)" or ""),
        "zoom " .. S.n(sc) .. ", the car's middle at x " .. S.n(uC) .. ", the room's at " .. S.n(areaC) .. " (screen "
        .. S.core:getScreenWidth() .. " wide)")
    return pre
end
function S.carBreak(v)
    local said = {}
    local b = v:getPartById("Battery")
    if b then pcall(function() b:setInventoryItem(nil) end); said[#said + 1] = "battery taken out" end
    local ws = v:getPartById("Windshield")
    local wn = nil
    if ws then pcall(function() wn = ws:getWindow() end) end
    if wn then pcall(function() wn:damage(1000) end) end
    local smashed = false
    if wn then pcall(function() smashed = wn:isDestroyed() end) end
    said[#said + 1] = "windshield smashed " .. tostring(smashed)
    S.smashed = smashed
    local tire = v:getPartById("TireFrontLeft")
    if tire then pcall(function() tire:setCondition(15) end); said[#said + 1] = "front left tire at 15" end
    Q.say("the car broken for the picture: " .. table.concat(said, ", "))
end
function S.rimCheck(R, pre)
    local rimB, fullB, rimW = false, false, false
    for _, d in ipairs(R.list) do
        local nm = d.name and string.lower(tostring(d.name)) or ""
        if nm:find("battery_rim", 1, true) then rimB = true
        elseif nm:find("battery", 1, true) then fullB = true end
        if nm:find("windshield_rim", 1, true) then rimW = true end
    end
    Q.check(rimB and not fullB and (rimW or not S.smashed), "Vehicle tab: the missing battery" .. (S.smashed and " and the smashed windshield draw" or " draws")
        .. " only their rims", "battery rim " .. tostring(rimB) .. ", battery picture " .. tostring(fullB) .. ", windshield rim " .. tostring(rimW)
        .. " (smashed " .. tostring(S.smashed) .. "), body shape " .. tostring(pre))
end
function S.carAway()
    local c = S.car
    S.carGaveUp = true
    pcall(function() ZeD.MechanicsTab.endLooks(S.p) end)
    if not c or c.going then return end
    c.going = true
    if ZEDQA_CAR_AWAY then pcall(ZEDQA_CAR_AWAY, c.v, nil) end
end
function S.carLive(v)
    if not v then return false end
    local live = false
    local vs = nil
    pcall(function() vs = getCell():getVehicles() end)
    if not vs then return false end
    pcall(function()
        for i = 0, vs:size() - 1 do if vs:get(i) == v then live = true end end
    end)
    return live
end

-- ===================================================================== start
Q.step(5, function()
    pcall(function() S.was.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() } end)
    S.start0()
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "gc_cln") end
    if getGameSpeed() ~= 1 then pcall(setGameSpeed, 1) end
    S.was.base, S.was.accent, S.was.size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    local bd = S.bd()
    if bd then
        pcall(function() S.was.hp = bd:getOverallBodyHealth() end)
        pcall(function() S.was.infected = bd:isInfected() == true end)
    end
    S.lock("kbm")
    S.park()
    S.openPair()
    Q.say("found: theme " .. tostring(S.was.base) .. " / " .. tostring(S.was.accent) .. " / " .. tostring(S.was.size) .. ", health "
        .. S.n(S.was.hp) .. ", input lock " .. tostring(S.lockWas) .. ", screen " .. S.core:getScreenWidth() .. " x "
        .. S.core:getScreenHeight() .. ", UI scale " .. tostring(ZeD.T.scale) .. ", art zoom " .. tostring(ZeD.T.art))
end)
Q.waitFor(10, 600, function() return S.CW() ~= nil and S.WW() ~= nil and S.CWm.isOpen() and S.WWm.isOpen() end, function(ok)
    if not ok then Q.check(false, "both windows open (staging)") end
    pcall(function() S.was.snap = ZEDQA_LAYOUT_SNAP and ZEDQA_LAYOUT_SNAP() or nil end)
    S.homeLayout()
    S.flagsFound()
end)
Q.step(10, function()
    S.theme("dark")
    S.wounds(true)
end)

-- ===================================================================== the body figure: Health, Thermal, Equipment
S.tabStage("health")
S.figCheckQ("health")
Q.step(1, function() S.clickWrap(true) end)
S.partsQ("health", "mouse")
S.partsQ("health", "pad")
Q.step(1, function() S.clickWrap(false) end)
S.tabShot("health", "dark", "health_dark")
S.tabShot("health", "light", "health_light")
S.tabShot("health", "hicon", "health_hc")
Q.step(5, function() S.theme("dark") end)

S.tabStage("thermal")
S.figCheckQ("thermal")
S.partsQ("thermal", "mouse")
S.partsQ("thermal", "pad")
S.tabShot("thermal", "dark", "thermal_dark")

S.tabStage("equip")
S.figCheckQ("equip")
S.partsQ("equip", "mouse")
S.partsQ("equip", "pad")
S.tabShot("equip", "dark", "equip_defense_dark")

-- ===================================================================== the medical check card
Q.step(10, function()
    S.unhold()
    S.clearHover()
    S.charTab("loot")
    local ok, why = S.medOpen()
    S.medOff = not ok
    if not ok then Q.check(false, "the medical check card opens on the World window (staging)", why) end
end)
Q.waitFor(5, 600, function()
    local t = S.entryT()
    return S.medOff or (t ~= nil and t == S.medT and t.d ~= nil)
end, function(ok)
    if S.medOff then return end
    if not ok then S.medOff = true; Q.check(false, "the medical check card reads the body (staging)") end
end)
S.medStep({ mode = { body = 336 }, two = true, say = "a 336-unit body", shot = "medcard_336" })
S.medStep({ mode = { card = 220 }, two = false, say = "the half card, 220", shot = "medcard_220" })
Q.step(5, function()
    S.cardMode = nil
    S.closeCard()
    S.wounds(false)
end)

-- ===================================================================== the laundry card's room
Q.step(10, function() S.placeMachines() end)
S.laundryRun(S.MACHINES[1], "full", "laundry_washer_full")
S.laundryRun(S.MACHINES[1], "narrow", "laundry_washer_narrow")
S.laundryRun(S.MACHINES[1], "half", nil)
S.laundryRun(S.MACHINES[2], "full", "laundry_dryer_full")
S.laundryRun(S.MACHINES[2], "narrow", "laundry_dryer_narrow")
S.laundryRun(S.MACHINES[2], "half", nil)
S.laundryRun(S.MACHINES[3], "full", "laundry_combo_full")
S.laundryRun(S.MACHINES[3], "narrow", nil)
S.laundryRun(S.MACHINES[3], "half", nil)
Q.step(5, function()
    S.cardMode = nil
    S.closeCard()
    local w = S.MACHINES[1].obj
    S.popped = false
    if w and ZeD.FacePop and ZeD.FacePop.open then
        local ok, r = pcall(ZeD.FacePop.open, S.p, w)
        S.popped = ok and r == true
    end
    S.park()
    S.unhold()
end)
Q.still(10, function() end)
Q.step(10, function()
    if not S.popped then S.skipShot("laundry_popout", "the washer's face did not pop out (faces off, or no washer)"); return end
    S.shotOk("laundry_popout", "the washer's face popped out (FacePop.open): the face alone, no room (picture only, no check)")
end)
Q.step(5, function()
    pcall(function() ZeD.TwoWayFull.close(S.pn) end)
    Q.say("machines removed: " .. S.removeMachines())
end)

-- ===================================================================== the Vehicle tab
Q.step(10, function()
    S.cardUnhook()
    S.worldTab("loot")
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "gc_cln") end
    S.carStart()
end)
S.wait(45000, function() return S.car ~= nil or S.carWhy ~= nil end, function(ok)
    if not S.car then
        S.carGaveUp = true
        S.carOff = true
        Q.check(false, "a car spawned and ready beside him (staging)", tostring(S.carWhy or "no ready car in 45 s"))
    end
end)
Q.step(5, function()
    if S.carOff then return end
    local v = S.car.v
    pcall(function() v:repair() end)
    local d = S.carNear(v)
    local ok, r = pcall(ZeD.MechanicsTab.openFromAction, S.p, v)
    Q.say("the car " .. tostring(S.car.script) .. " " .. S.n(d) .. " tiles away; the Vehicle tab opened " .. tostring(ok and r))
end)
S.wait(8000, function() return S.carOff or S.carTabReady() end, function(ok)
    if S.carOff then return end
    local ww = S.WW()
    if not ok then S.carOff = true; Q.check(false, "the Vehicle tab shows the car's diagram (staging)", "tab " .. tostring(ww and ww._activeTab)) end
end)
Q.step(5, function() if not S.carOff then S.park(); S.holdFor("world"); S.clearChar() end end)
Q.still(10, function() end)
Q.step(1, function() local ww = S.WW(); if not S.carOff and ww then S.recOn("car", ww._drawerPanel) end end)
Q.step(1, function()
    local R = S.recOff("car")
    if S.carOff or not R then return end
    S.carPre = S.carCheck(R)
end)
Q.step(2, function()
    if S.carOff then S.skipShot("vehicle_tab", "no car or no Vehicle tab"); return end
    S.shotOk("vehicle_tab", "the Vehicle tab on a repaired " .. tostring(S.car.script) .. ", looked at (the mechanics key's way), the World window held in use")
end)
Q.step(5, function() if not S.carOff then S.carBreak(S.car.v) end end)
S.wait(1500, function() return false end, function() end)
Q.still(5, function() end)
Q.step(1, function() local ww = S.WW(); if not S.carOff and ww then S.recOn("car", ww._drawerPanel) end end)
Q.step(1, function()
    local R = S.recOff("car")
    if S.carOff or not R then return end
    S.rimCheck(R, S.carPre)
end)
Q.step(2, function()
    if S.carOff then S.skipShot("vehicle_part_missing", "no car or no Vehicle tab"); return end
    S.shotOk("vehicle_part_missing", "the same car with its battery out, its windshield smashed (" .. tostring(S.smashed) .. ") and a tire worn down")
end)
Q.step(5, function()
    S.unhold()
    S.worldTab("loot")
    S.carAway()
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    S.recAllOff()
    S.medWrap(false)
    S.clickWrap(false)
    pcall(S.F.qaButton, "A", nil, S.pn)
    if S.F.getFocusedWindow and S.F.getFocusedWindow(S.pn) then pcall(S.F.releaseFocus, S.pn) end
    S.L = nil
    S.cardUnhook()
    S.closeCard()
    pcall(function() ZeD.TwoWayFull.close(S.pn) end)
    if #S.placed > 0 then S.removeMachines() end
    S.carAway()
    S.wounds(false)
    S.unhold()
    S.flagsBack()
    if ZeD.currentBase ~= S.was.base or ZeD.currentAccent ~= S.was.accent or ZeD.currentSize ~= S.was.size then
        pcall(ZeD.applyTheme, S.was.base, S.was.accent, S.was.size)
    end
    S.lock(false)
end)
S.wait(5000, function() return not (S.car and S.carLive(S.car.v)) end, function(ok)
    if S.car and not ok then Q.say("NOTE the car is still in the world 5 s after it was sent away") end
end)
Q.step(20, function()
    S.openPair()
    S.charTab("loot"); S.worldTab("loot")
    if ZEDQA_LAYOUT_BACK and S.was.snap then pcall(ZEDQA_LAYOUT_BACK, S.was.snap, "gc_cln") end
    local pos = S.was.pos
    if pos and (math.abs(S.p:getX() - pos.x) > 1 or math.abs(S.p:getY() - pos.y) > 1 or math.floor(S.p:getZ()) ~= math.floor(pos.z)) then
        S.tpTo(pos.x, pos.y, pos.z)
        Q.say("back where he stood: " .. math.floor(pos.x) .. "," .. math.floor(pos.y) .. "," .. math.floor(pos.z))
    end
    S.mouseOff()
    S.back0()
end)
Q.step(30, function()
    if not S.was.pairOpen then S.closePair() end
    pcall(function() Mouse.setCursorVisible(true) end)
    Events.OnPreUIDraw.Remove(S.errWatch)
    local mode, hp = "?", nil
    if S.Det and S.Det.getMode then pcall(function() mode = tostring(S.Det.getMode(S.pn)) end) end
    local bd = S.bd()
    if bd then pcall(function() hp = bd:getOverallBodyHealth() end) end
    local hooked = (ZeD_BodyFigure.drawAt ~= nil and S.med0 == nil and S.click0 == nil and S.hooked == nil) and "none" or "SOME LEFT"
    Q.say("put back: theme " .. tostring(ZeD.currentBase) .. " / " .. tostring(ZeD.currentAccent) .. " / " .. tostring(ZeD.currentSize)
        .. " (found " .. tostring(S.was.base) .. " / " .. tostring(S.was.accent) .. " / " .. tostring(S.was.size) .. "), health "
        .. S.n(hp) .. " (found " .. S.n(S.was.hp) .. "), machines still standing " .. S.standing() .. ", car in the world "
        .. tostring(S.car ~= nil and S.carLive(S.car.v)) .. ", wrappers left " .. hooked .. ", recorders left " .. S.recCount()
        .. ", pad focus " .. tostring(S.F.getFocusedWindow and S.F.getFocusedWindow(S.pn) ~= nil) .. ", input lock as found ("
        .. tostring(S.lockWas) .. "; ZeD reads " .. mode .. "), mouse swap " .. tostring(S.mouseSwapped == true) .. ", windows held "
        .. #S.held .. ", alive " .. tostring(not S.p:isDead()) .. ", in a car " .. tostring(S.p:getVehicle() ~= nil)
        .. "; pictures taken: " .. ((#S.pic > 0) and table.concat(S.pic, ", ") or "none"))
end)
S.verdict()
Q.start()
