-- ZeDUI/tools/qa/vx_hud.lua  (Nov 21 2026, QA): the in-game proof of Build's fixes from the beast code sweep
-- (qa/audits/2026-11-21_beast_code_sweep.md), HUD row: W40 W41 W42 W43 (W44 is the same fault) W54 W55.
-- Build's fix: 58c20c461 (belt, messages, hint strip) and a4fc05567 (map). Built on rt_kit.lua (the global RT),
-- run after zedqa_prelude.lua. grep "ZEDQA vx_hud". No pictures. Under 6 minutes (the put-back starts by 300 s).
-- (Nov 21 2026, the skeptic pass over the first draft: the Lite belt's layout record is read late in the count, where
-- the old code had no clock left and could not pass by luck; the map's made-up pad goes only to a call made from
-- MapsTab.lua, found on the Lua call stack, in place of three swapped functions that could hand it to other code;
-- the controller's first ask on the unfolded map must build the waiting stops on the spot; the character starts on
-- the drag strip; the window layout and the map's view are put back.)
--
-- Each check says what the OLD code showed, so a FAIL reads as "the fault is back":
--   W55  a walkie-talkie in the main hand, in the open at the drag strip, strip on Always: the hint strip offers
--        nothing.                              OLD: one hint, "Right-click More", all the time.
--   W40  a belt item pressed and dragged, the release never arriving (no mouse button is down in this run, which
--        is exactly a lost release):
--          a) the belt still showing: the drag is dropped on the next drawn frame.     OLD: stays armed for good.
--          b) the interface hidden mid-drag (ISUIHandler.toggleUI, what V does) and shown again: the drag is gone
--             while hidden and after, and a mouse-up on the main hand equips nothing.  OLD: still armed, the icon
--             on the pointer, and that mouse-up calls ZeD.Belt.equipHand with the belt item.
--          c) a mouse-up reaching a belt that did not draw this frame lets go.         OLD: returns early, armed.
--   W41  Lite belt: ZeD_BeltHUD:_layout calls counted over 3 seconds of the same scene: about one a second; then its
--        layout record read on three drawn frames in a row: kept.  OLD: one layout every drawn frame (about 180 in
--        3 s), a new record every frame.
--   W43  the game paused, then another mod's note is kept in Messages: still paused 12 frames later.
--                                                                 OLD: running again after 3 frames.
--        and the fix's other side (a guard, the same on old and new): a mod that pauses FOR its note is still undone.
--   W42  the unfolded map with the mouse and keyboard in use: rebuilds of its controller stops counted over 60 of
--        its drawn frames: 2 at most, and the stop list the same table.   OLD: 60, one per frame, a new list each.
--        The controller's first ask (Focus.focusWhere) builds the waiting stops on the spot and lands on the map's
--        cursor.                                                   OLD: no waiting, so nothing built for the ask.
--        The finding's second half (a new map made on every unfold, the old ones piling up) is NOT in Build's fix
--        ("W42, partly"): its check is here and is expected to FAIL until that half is done.
--   W54  the controller on the Maps tab's cursor, the game paused: the left stick moves the cursor and a trigger
--        zooms.                                                    OLD: both dead while paused.
--        No controller is plugged in on the QA machine: getJoypadData answers with a made-up pad (id 7, which the
--        engine reads as no controller) only for a call made straight from MapsTab.lua (the map's own tick, found on
--        the Lua call stack), and getControllerAxisValue answers pad 7's stick and triggers, for a second or two. A
--        real pad reaching the game while paused cannot be shown from a script; that part is said as a SKIP.
-- Puts back: the pointer and pad functions, the detector's lock, the pad's focus, the pause, the interface shown,
-- the look style, the hint strip and Messages options, Messages' test notes, the belt's hammer, the hands, the map's
-- view, the window pair and its layout (when it was open), the god mode flags. Things given are taken back
-- (RT.takeBack). Nothing here can hurt Angel; no heal is called; no file is written.
local Q = RT.make("vx_hud")
Q.maxMs = 300000                     -- (the runner gives this script 420 s: the put-back runs well before that)
local S = { p = RT.p, pn = RT.pn, back = {}, cnt = {} }
local Z = ZeD
S.sw, S.sh = RT.core:getScreenWidth(), RT.core:getScreenHeight()
S.realMX, S.realMY = getMouseX, getMouseY
S.realJD, S.realAX = getJoypadData, getControllerAxisValue
S.SRC = "ZeD QA vx_hud mod"

function S.opt(o) local v = nil; pcall(function() v = o:getValue() end); return v end
function S.setOpt(o, v) if o and v then pcall(function() o:setValue(v) end) end end
function S.hud() return Z.Belt and Z.Belt.getHUD and Z.Belt.getHUD(S.pn) or nil end
function S.focus() return Z.Input and Z.Input.Focus or nil end
function S.det() return Z.Input and Z.Input.Detector or nil end
function S.boxes(kind)
    local out = {}
    local hud = S.hud()
    for _, b in ipairs(hud and hud._boxes or {}) do if b.kind == kind then out[#out + 1] = b end end
    return out
end
function S.handBox(which)
    for _, b in ipairs(S.boxes("hand")) do if b.which == which then return b end end
    return nil
end
-- a belt slot holding something that is not in a hand (the only kind a press can drag out)
function S.slotBox()
    for _, b in ipairs(S.boxes("slot")) do
        if b.s and b.s.item and not b.s.inHand then return b end
    end
    return nil
end
function S.speed() local v = -1; pcall(function() v = getGameSpeed() end); return v end
function S.pause(on)
    S.paused = on and true or nil
    if on then
        pcall(function() UIManager.getSpeedControls():SetCurrentGameSpeed(0) end)
        if ZEDQA_SPEED then ZEDQA_SPEED(0) else pcall(setGameSpeed, 0) end
    else
        pcall(function() UIManager.getSpeedControls():SetCurrentGameSpeed(1) end)
        if ZEDQA_SPEED then ZEDQA_SPEED(1) else pcall(setGameSpeed, 1) end
    end
end
function S.uiShown() return not (ISUIHandler and ISUIHandler.allUIVisible == false) end
function S.showUI() if not S.uiShown() then pcall(ISUIHandler.toggleUI) end end

-- the name the QA bridge loads this script under (its loadstring chunk name), read once from the Lua call stack:
-- the W54 pad answer steps over this script's own frames to find who called it
S.SELF = nil
pcall(function()
    local co = getCurrentCoroutine()
    local top = getCallframeTop(co)
    for i = top - 1, 0, -1 do
        local cf = getCoroutineCallframeStack(co, i)
        local f = cf and getFilenameOfCallframe(cf)
        if f then S.SELF = f; return end
    end
end)

-- ===================================================================== start
Q.step(10, function()
    -- the drag strip, in the open, out of any car (W55 needs nothing in front of him: no door, no car)
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "vx_hud") end
    S.pairWas = RT.isOpen()
    if S.pairWas and ZEDQA_LAYOUT_SNAP then pcall(function() S.snap = ZEDQA_LAYOUT_SNAP() end) end
    RT.pairShut()
    pcall(function() S.p:StopAllActionQueue() end)
    if S.speed() ~= 1 then S.pause(false) end
    -- nothing here can hurt him, but the game gets paused and the interface hidden for a few seconds: he is safe
    pcall(function() S.godWas = S.p:isGodMod(); S.invWas = S.p:isInvincible() end)
    pcall(function() S.p:setGodMod(true); S.p:setInvincible(true) end)
    S.back.god = true
    S.hand1, S.hand2 = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    S.back.hands = true
    local md = nil
    pcall(function() md = S.p:getModData().ZeD_Gamepad end)
    S.lockWas = md and md.inputModeLock
    S.back.lock = true
    if S.det() then S.det().setLockedMode("kbm") end   -- (the mouse and keyboard, until the map's pad part)
    S.freshWas = ZEDQA_FRESH_STOPS
    S.showUI()
    Q.check(not (Z.Safe and Z.Safe.on and Z.Safe.on()), "safe mode is off, so ZeD draws the HUD")
    Q.check(Z.Belt ~= nil and Z.HintStrip ~= nil and Z.Messages ~= nil and Z.MapsTab ~= nil and Z.Settings ~= nil
        and S.focus() ~= nil and S.det() ~= nil, "the belt, hint strip, Messages, map and focus modules are loaded")
end)
-- (after a move to the strip its squares load first; the belt draws again)
Q.waitFor(2, 300, function()
    local hud = S.hud()
    return S.p:getCurrentSquare() ~= nil and hud ~= nil and hud._drawn == true
end, function(ok)
    if not ok then Q.say("start: his square or the belt was not ready in 300 frames (the checks below say what they meet)") end
end)

-- ===================================================================== W55: no "Right-click More" for a held radio
function S.hintWords(list)
    local words = {}
    for _, pr in ipairs(list or {}) do words[#words + 1] = tostring(pr.glyph) .. " " .. tostring(pr.label) end
    return (#words > 0) and table.concat(words, " ; ") or "nothing"
end
function S.putHint()
    if not S.back.hint then return end
    S.back.hint = nil
    S.setOpt(Z.Settings.hintStripOption, S.hintOpt or 1)
end
function S.putHands()
    if not S.back.hands then return end
    S.back.hands = nil
    pcall(function() if S.p:getPrimaryHandItem() ~= S.hand1 then S.p:setPrimaryHandItem(S.hand1) end end)
    pcall(function() if S.p:getSecondaryHandItem() ~= S.hand2 then S.p:setSecondaryHandItem(S.hand2) end end)
end
Q.step(5, function()
    S.hintOpt = S.opt(Z.Settings.hintStripOption)
    S.back.hint = true
    S.setOpt(Z.Settings.hintStripOption, 1)          -- Always
    -- empty hands first: what the strip says in this spot with no radio
    pcall(function() S.p:setPrimaryHandItem(nil); S.p:setSecondaryHandItem(nil) end)
end)
Q.waitMs(450)
Q.step(1, function() pcall(Z.HintStrip.prompts, S.pn) end)
Q.waitMs(300)
Q.step(1, function()
    local okp, base = pcall(Z.HintStrip.prompts, S.pn)
    S.hintBase = okp and base or nil
    Q.say("W55: empty hands at the drag strip, the strip offers " .. S.hintWords(S.hintBase))
    S.radio = RT.give("Base.WalkieTalkie2")
    if S.radio then pcall(function() S.p:setPrimaryHandItem(S.radio) end) end
end)
Q.waitMs(450)
Q.step(1, function() pcall(Z.HintStrip.prompts, S.pn) end)   -- (the rules run at most every 200 ms: asked twice)
Q.waitMs(300)
Q.step(1, function()
    local okp, out = pcall(Z.HintStrip.prompts, S.pn)
    if not okp then out = nil end
    local st = Z.HintStrip._eval and Z.HintStrip._eval[S.pn]
    local device = st ~= nil and ISButtonPrompt ~= nil and st.aFn ~= nil and st.aFn == ISButtonPrompt.openDeviceOptions
    if not Q.check(S.radio ~= nil and S.p:getPrimaryHandItem() == S.radio and device,
        "W55 staging: a walkie-talkie in the main hand and the game's own prompt for it is Device Options",
        "radio " .. tostring(S.radio ~= nil) .. ", the game's prompt '" .. tostring(st and st.a) .. "'") then
        S.putHands(); S.putHint(); return
    end
    local more, moreWord = false, tostring(Z.tr("UI_ZeD_Hint_More"))
    for _, pr in ipairs(out or {}) do if tostring(pr.label) == moreWord then more = true end end
    Q.check(not more, "W55: a held walkie-talkie in the open shows no 'Right-click " .. moreWord .. "' hint (old: that hint, all the time)",
        "the strip offers " .. S.hintWords(out))
    S.putHands(); S.putHint()
end)

-- ===================================================================== W40: a belt drag that loses its release
-- the press on a filled slot and a 200 px drag, as the mouse does them; no real button is down, so the release is lost
function S.armDrag(hud, b)
    local lx, ly = b.x + math.floor(b.w / 2), b.y + math.floor(b.h / 2)
    pcall(hud.onMouseDown, hud, lx, ly)
    local pr = hud._press
    if not (pr and hud._out) then return false end
    local fx, fy = pr.x + 200, pr.y
    getMouseX, getMouseY = function() return fx end, function() return fy end
    pcall(hud.onMouseMove, hud, 200, 0)
    getMouseX, getMouseY = S.realMX, S.realMY
    return hud._out ~= nil and hud._out.active == true
end
function S.dropDrag()
    local hud = S.hud()
    if not hud then return end
    hud._out, hud._press = nil, nil
    pcall(hud.setCapture, hud, false)
end
function S.dragState(hud)
    return "drag " .. ((hud._out and (hud._out.active and "armed and active" or "armed")) or "none") .. ", press " .. (hud._press and "kept" or "none")
end
function S.putBelt()
    getMouseX, getMouseY = S.realMX, S.realMY
    if S.beltStub then
        Z.Belt.equipHand, Z.Belt.detach = S.beltStub.eq, S.beltStub.de
        S.beltStub = nil
    end
    S.showUI()
    pcall(S.dropDrag)
    local a = S.att
    if a then
        S.att = nil
        pcall(function() if a.hb:isItemAttached(a.it) then a.hb:removeItem(a.it, false) end end)
    end
end
Q.step(10, function()
    local hud = S.hud()
    if not Q.check(hud ~= nil and hud._drawn == true and hud:getIsVisible(), "W40 staging: the belt is drawn") then S.w40Skip = true; return end
    if S.slotBox() then return end
    -- nothing on the belt to drag: a hammer goes on the first free slot that takes it (the game's own attach)
    local hb = Z.Belt.hotbar and Z.Belt.hotbar(S.pn)
    local it = RT.give("Base.Hammer")
    if hb and hb.availableSlot and it then
        for i, sl in ipairs(hb.availableSlot) do
            if not S.att and not (hb.attachedItems and hb.attachedItems[i]) and Z.Belt.fits(hb, i, it) then
                local model = sl.def and sl.def.attachments and sl.def.attachments[it:getAttachmentType()]
                S.att = { hb = hb, it = it }
                pcall(hb.attachItem, hb, it, model, i, sl.def, false)
            end
        end
    end
end)
Q.waitFor(2, 120, function() return S.w40Skip or S.slotBox() ~= nil end, function(ok)
    if S.w40Skip then return end
    if not (ok and S.slotBox()) then
        S.w40Skip = true
        Q.skip("W40: a belt drag that loses its release", "nothing on this character's belt and no free slot takes a hammer")
    end
end)
-- a) the belt still showing (the pause menu case): the drawn frame drops the drag
Q.step(3, function()
    if S.w40Skip then return end
    local hud = S.hud()
    local armed = S.armDrag(hud, S.slotBox())
    if not Q.check(armed, "W40 staging: a press and a drag on a belt item arm the drag-out", S.dragState(hud)) then S.w40Skip = true; S.dropDrag() end
end)
Q.step(6, function()
    if S.w40Skip then return end
    local hud = S.hud()
    Q.check(hud._out == nil and hud._press == nil,
        "W40 a: no button down, the belt showing: the drag is dropped on the next drawn frames (old: armed for good, the icon on the pointer)",
        S.dragState(hud))
    S.dropDrag()
end)
-- b) the interface hidden mid-drag (V), then shown again
Q.step(3, function()
    if S.w40Skip then return end
    local hud = S.hud()
    local b = S.slotBox()
    S.dragItem = b and b.s.item
    S.dragSlot = b and b.i
    local armed = b ~= nil and S.armDrag(hud, b)
    if not armed then Q.check(false, "W40 staging: the drag arms a second time", S.dragState(hud)); S.w40Skip = true; S.dropDrag(); return end
    pcall(ISUIHandler.toggleUI)                 -- the same step: no drawn frame between the drag and the hide
    S.hidAt = getTimestampMs()
end)
Q.waitFor(1, 240, function() local hud = S.hud(); return S.w40Skip or (hud ~= nil and hud._drawn == false and not hud:getIsVisible()) end, function(ok)
    if S.w40Skip then return end
    if not Q.check(ok and not S.uiShown(), "W40 staging: the interface is hidden and the belt with it") then S.w40Skip = true; S.showUI(); S.dropDrag() end
end)
Q.step(4, function()
    if S.w40Skip then return end
    local hud = S.hud()
    Q.check(hud._out == nil and hud._press == nil,
        "W40 b: hidden mid-drag, the belt lets the drag go while hidden (old: kept armed, no mouse-up can reach it)", S.dragState(hud))
    S.showUI()
end)
Q.waitFor(1, 240, function() local hud = S.hud(); return S.w40Skip or (hud ~= nil and hud._drawn == true) end, function(ok)
    if S.w40Skip then return end
    if not Q.check(ok, "W40 staging: the interface is back and the belt drawn") then S.w40Skip = true; S.dropDrag() end
end)
Q.step(4, function()
    if S.w40Skip then return end
    local hud = S.hud()
    Q.check(hud._out == nil, "W40 b: shown again, no item is on the pointer (old: the belt item's icon follows the pointer)", S.dragState(hud))
    -- the next mouse-up, on the main hand's circle. The belt's two verbs are counted, not run, so his hands stay as they are
    local calls, who = 0, "nothing"
    S.beltStub = { eq = Z.Belt.equipHand, de = Z.Belt.detach }
    Z.Belt.equipHand = function(pn, item, which) calls = calls + 1; who = "equipHand(" .. tostring(which) .. ")" end
    Z.Belt.detach = function(pn, item) calls = calls + 1; who = "detach" end
    local hb = S.handBox("p")
    if hb then pcall(hud.onMouseUp, hud, hb.x + math.floor(hb.w / 2), hb.y + math.floor(hb.h / 2)) end
    Z.Belt.equipHand, Z.Belt.detach = S.beltStub.eq, S.beltStub.de
    S.beltStub = nil
    local still = false
    for _, s in ipairs(Z.Belt.slots(S.pn)) do if s.i == S.dragSlot and s.item == S.dragItem then still = true end end
    Q.check(hb ~= nil and calls == 0 and still,
        "W40 b: the next mouse-up on the main hand does nothing with the belt item (old: it equips it, or detaches it over a list)",
        "the belt called " .. who .. "; the item " .. (still and "is still in its slot" or "left its slot"))
    S.dropDrag()
end)
-- c) a mouse-up that reaches a belt which did not draw this frame
Q.step(4, function()
    if S.w40Skip then return end
    local hud = S.hud()
    local b = S.slotBox()
    if not (b and S.armDrag(hud, b)) then Q.check(false, "W40 staging: the drag arms a third time", S.dragState(hud)); S.dropDrag(); return end
    hud._drawn = false                          -- (what a frame the belt sat out leaves behind; the next drawn frame sets it again)
    pcall(hud.onMouseUp, hud, -5, -5)
    Q.check(hud._out == nil and hud._press == nil,
        "W40 c: a mouse-up on a belt that is not showing lets the drag go (old: it returned early and stayed armed)", S.dragState(hud))
    S.dropDrag()
end)
Q.step(4, function() S.putBelt() end)

-- ===================================================================== W41: the Lite belt's layout is kept
-- (the counters sit on the belt itself; what it had of its own under those names is kept and put back)
function S.countBelt(on)
    local hud = S.hud()
    if on and hud and not S.beltCnt then
        local lay0, lc0 = hud._layout, hud._layoutCached
        S.beltCnt = { hud = hud, ownLay = rawget(hud, "_layout"), ownLc = rawget(hud, "_layoutCached") }
        S.cnt.lay, S.cnt.frames, S.cnt.t0 = 0, 0, getTimestampMs()
        hud._layout = function(self, slots, wItem, wPlate, wWrist, lamp, ammo, two)
            S.cnt.lay = S.cnt.lay + 1
            return lay0(self, slots, wItem, wPlate, wWrist, lamp, ammo, two)
        end
        hud._layoutCached = function(self, slots)
            S.cnt.frames = S.cnt.frames + 1
            return lc0(self, slots)
        end
    elseif not on and S.beltCnt then
        local c = S.beltCnt
        S.beltCnt = nil
        c.hud._layout, c.hud._layoutCached = c.ownLay, c.ownLc
        S.cnt.ms = getTimestampMs() - (S.cnt.t0 or 0)
    end
end
function S.putStyle()
    S.countBelt(false)
    if not S.back.style then return end
    S.back.style = nil
    S.setOpt(Z.Settings.lookStyleOption, S.styleWas or 1)
end
function S.layoutVerdict(label, old)
    local lay, frames, ms = S.cnt.lay or -1, S.cnt.frames or 0, S.cnt.ms or 0
    local limit = math.floor(ms / 1000) + 3      -- (once a second, and room for a real change: a lamp, a hand)
    return Q.check(frames >= 20 and lay >= 0 and lay <= limit, label,
        lay .. " layouts in " .. frames .. " drawn frames over " .. ms .. " ms, at most " .. limit .. " wanted" .. (old and (" (old: " .. old .. ")") or ""))
end
Q.step(5, function()
    S.styleWas = S.opt(Z.Settings.lookStyleOption)
    S.back.style = true
    S.setOpt(Z.Settings.lookStyleOption, 1)      -- Full first: the belt that always kept its layout
end)
Q.step(20, function()
    local hud = S.hud()
    if not Q.check(hud ~= nil and hud._drawn == true and not Z.Belt.simple(), "W41 staging: the Full belt is drawn") then S.w41Skip = true; return end
    S.countBelt(true)
end)
Q.waitMs(2000)
Q.step(1, function()
    if S.w41Skip then return end
    S.countBelt(false)
    S.layoutVerdict("W41 staging: the Full belt lays out about once a second (it always did: the yardstick for this scene)", nil)
    S.setOpt(Z.Settings.lookStyleOption, 2)      -- Lite
end)
Q.step(30, function()
    if S.w41Skip then return end
    local hud = S.hud()
    if not Q.check(hud ~= nil and hud._drawn == true and Z.Belt.simple(), "W41 staging: Style Lite gives the Lite belt, drawn") then S.w41Skip = true; return end
    S.countBelt(true)
end)
Q.waitMs(3000)
-- the layout record on three drawn frames in a row, read now: more than a second into Lite, where the old code had no
-- once-a-second clock left (its last one came from the Full belt) and made a new record every frame
Q.step(1, function() if not S.w41Skip then S.lk = { S.hud()._lk } end end)
Q.step(1, function() if not S.w41Skip then S.lk[2] = S.hud()._lk end end)
Q.step(1, function()
    if S.w41Skip then S.putStyle(); return end
    S.lk[3] = S.hud()._lk
    S.countBelt(false)
    S.layoutVerdict("W41: the Lite belt lays out about once a second, the same scene for 3 s", "one layout every drawn frame")
    local kept = S.lk[1] ~= nil and (S.lk[1] == S.lk[2] or S.lk[2] == S.lk[3])
    Q.check(kept, "W41: the Lite belt's layout record is the same table on drawn frames in a row, 3 s into Lite (old: a new table every frame)",
        "frames 1-2 " .. ((S.lk[1] == S.lk[2]) and "same" or "new") .. ", frames 2-3 " .. ((S.lk[2] == S.lk[3]) and "same" or "new"))
    S.putStyle()
end)
Q.step(20, function() end)

-- ===================================================================== W43 (and W44): a kept note leaves a pause alone
function S.note(words)
    local MS = Z.Messages
    local n = nil
    MS.qaSource = S.SRC
    local ok, err = pcall(function()
        n = ISModalDialog:new(0, 0, 300, 150, words, false, S, function() end, S.pn)
        n:initialise()
        n:addToUIManager()
    end)
    MS.qaSource = nil
    if not ok then Q.say("W43: the note could not be made: " .. tostring(err)) end
    return n
end
function S.putMsg()
    if not S.back.msg then return end
    S.back.msg = nil
    local MS, St = Z.Messages, Z.Settings
    MS.qaSource = nil
    pcall(function() if MS.sources[S.SRC] then MS.clear(S.SRC) end end)
    for _, n in ipairs(S.notes or {}) do pcall(function() if n.javaObject and n:isVisible() then n:removeFromUIManager() end end) end
    S.notes = nil
    pcall(function() if S.popWas then MS.setPopups(S.SRC, true) end end)
    S.setOpt(St.messagesCatchOption, S.catchWas or 1)
    S.setOpt(St.messagesToastOption, S.toastWas or 1)
    if S.toasts0 then MS.toasts = S.toasts0; S.toasts0 = nil end
    if S.paused then S.pause(false) end
end
Q.step(5, function()
    local MS, St = Z.Messages, Z.Settings
    S.catchWas, S.toastWas = S.opt(St.messagesCatchOption), S.opt(St.messagesToastOption)
    S.toasts0 = {}
    for _, t in ipairs(MS.toasts or {}) do S.toasts0[#S.toasts0 + 1] = t end
    S.back.msg = true
    S.notes = {}
    S.setOpt(St.messagesCatchOption, 2)          -- other mods' notes are kept in Messages
    S.setOpt(St.messagesToastOption, 1)
    pcall(function() S.popWas = MS.popupsFor(S.SRC); if S.popWas then MS.setPopups(S.SRC, false) end end)
    if S.speed() ~= 1 then S.pause(false) end
end)
Q.step(10, function() S.pause(true) end)       -- running for ten frames (Messages notes the speed 1), then the player's pause
Q.step(8, function()
    if not Q.check(S.speed() == 0, "W43 staging: the game is paused before the note comes", "speed " .. S.speed()) then S.w43Skip = true; return end
    local n = S.note("QA vx_hud: a note from another mod, the game already paused.")
    S.notes[#S.notes + 1] = n
    local s = Z.Messages.sources[S.SRC]
    if not Q.check(n ~= nil and n._zedCaught == true and s ~= nil and #s.items >= 1,
        "W43 staging: the other mod's note is kept in Messages, not shown", "caught " .. tostring(n and n._zedCaught)) then S.w43Skip = true end
end)
Q.step(12, function()
    if S.w43Skip then S.pause(false); return end
    Q.check(S.speed() == 0, "W43: a game the player had paused is still paused 12 drawn frames after the note is kept (old: running again after 3)",
        "speed " .. S.speed())
    S.pause(false)
end)
-- the fix's other side (a guard: the old code passed it too): the pause a mod makes for its own note is still undone
Q.step(15, function()
    if S.w43Skip then return end
    if S.speed() ~= 1 then S.pause(false) end
end)
Q.step(10, function()
    if S.w43Skip then return end
    local n = S.note("QA vx_hud: a note from a mod that pauses the game for it.")
    S.notes[#S.notes + 1] = n
    S.caught2 = n ~= nil and n._zedCaught == true
    pcall(setGameSpeed, 0)                       -- as that mod does, right after showing its note
    S.pausedByMod = S.speed() == 0
end)
Q.step(12, function()
    if S.w43Skip then return end
    Q.check(S.caught2 and S.pausedByMod and S.speed() > 0,
        "W43 guard: a mod that pauses the game for its own kept note is still undone (the game runs on, as before the fix)",
        "kept " .. tostring(S.caught2) .. ", paused by the mod " .. tostring(S.pausedByMod) .. ", speed now " .. S.speed())
    S.pause(false)
    S.putMsg()
end)

-- ===================================================================== W42: the unfolded map's controller stops wait
function S.mp() local w = RT.ww(); return w and w._worldMapPanel end
function S.pop() local w = RT.ww(); return w and w._mapPopout end
function S.countMap(on)
    local MT = Z.MapsTab
    if on and not S.mapCnt then
        S.mapCnt = { bf = MT.buildFocusables, rp = MT._renderPopout }
        S.cnt.builds, S.cnt.pframes = 0, 0
        MT.buildFocusables = function(win, a, b)
            if win and win._mapBuildingForPopout then S.cnt.builds = S.cnt.builds + 1 end
            return S.mapCnt.bf(win, a, b)
        end
        MT._renderPopout = function(content, win, pop)
            S.cnt.pframes = S.cnt.pframes + 1
            return S.mapCnt.rp(content, win, pop)
        end
    elseif not on and S.mapCnt then
        MT.buildFocusables, MT._renderPopout = S.mapCnt.bf, S.mapCnt.rp
        S.mapCnt = nil
    end
end
function S.putMap()
    getMouseX, getMouseY = S.realMX, S.realMY
    S.fakeMove = nil
    S.countMap(false)
    ZEDQA_FRESH_STOPS = S.freshWas
    local w = RT.ww()
    if w and w._mapPopout then pcall(Z.MapsTab.closePopout, w, true) end
end
Q.step(5, function()
    RT.pairOpen()
end)
Q.waitFor(2, 180, function() local w = RT.ww(); return w ~= nil and w:isReallyVisible() end, function(ok)
    local w = RT.ww()
    if not Q.check(ok and w ~= nil, "map staging: the World window is open") then S.mapSkip = true; return end
    S.tabWas = w._activeTab
    S.back.tab = true
    if not Q.check(RT.worldTab("maps"), "map staging: the World window has its Maps tab", table.concat(RT.tabs(RT.worldStrip()), " ")) then S.mapSkip = true end
end)
Q.waitFor(2, 240, function() local m = S.mp(); return S.mapSkip or (m ~= nil and m:isReallyVisible()) end, function(ok)
    if S.mapSkip then return end
    if not Q.check(ok, "map staging: the Maps tab draws its map") then S.mapSkip = true; return end
    S.back.map = true
    S.countMap(true)
    pcall(Z.MapsTab.openPopout, RT.ww())          -- what the unfold button's press calls
end)
Q.waitFor(2, 240, function()
    local w = RT.ww()
    return S.mapSkip or (w ~= nil and w._mapPopout ~= nil and w._worldMapPanel ~= nil and w._worldMapPanel ~= w._worldMapPanelInline and S.cnt.pframes > 5)
end, function(ok)
    if S.mapSkip then return end
    if not Q.check(ok, "map staging: the map unfolds into its own window and draws") then S.mapSkip = true; S.putMap(); return end
    RT.bounds(Q, "the unfolded map")
    S.bigMap1 = RT.ww()._worldMapPanel
    -- a player on the mouse and keyboard: the QA prelude's "keep every stop fresh" switch off for the count, and
    -- the controller's focus mark off (a pointer move takes it off, as it does for a player)
    ZEDQA_FRESH_STOPS = nil
    local F = S.focus()
    if F.cuesVisible and F.cuesVisible(S.pn) then
        local fx = S.realMX() + 300
        getMouseX = function() return fx end
        S.fakeMove = true
    end
end)
Q.step(6, function()
    if S.fakeMove then getMouseX = S.realMX; S.fakeMove = nil end
end)
Q.step(30, function()
    if S.mapSkip then return end
    local F, pop = S.focus(), S.pop()
    local may = false
    pcall(function() may = F.stopsMayWait(pop) == true end)
    if not Q.check(pop ~= nil and may, "W42 staging: the mouse and keyboard are in use on the unfolded map (its stops may wait)",
        "mode " .. tostring(S.det().getMode(S.pn)) .. ", focus mark " .. tostring(F.cuesVisible and F.cuesVisible(S.pn))
        .. ", a landing waiting " .. tostring(F.soonPending and pop and F.soonPending(pop))) then S.w42Skip = true; return end
    S.cnt.builds, S.cnt.pframes = 0, 0
    S.els0 = pop._focusRing and pop._focusRing[1] and pop._focusRing[1].elements
end)
Q.waitFor(1, 900, function() return S.mapSkip or S.w42Skip or S.cnt.pframes >= 60 end, function(ok)
    if S.mapSkip or S.w42Skip then return end
    local pop = S.pop()
    local els = pop and pop._focusRing and pop._focusRing[1] and pop._focusRing[1].elements
    Q.check(ok and S.cnt.builds <= 2,
        "W42: the unfolded map on the mouse rebuilds its controller stops 2 times at most in 60 drawn frames (old: 60, one a frame)",
        S.cnt.builds .. " rebuilds in " .. S.cnt.pframes .. " drawn frames")
    Q.check(els ~= nil and els == S.els0, "W42: the stop list is the same table 60 frames on (old: a new table and new functions every frame)",
        (els == S.els0) and "same" or "new")
    -- the controller asks (a landing, as its first press does): the waiting stops are built there and then, and the
    -- pad lands on the map's cursor. The old code had no waiting, so nothing was built for the ask.
    local b0 = S.cnt.builds
    local F = S.focus()
    local okf, e = pcall(F.focusWhere, pop, "popMapContent", function(el) return el.isCanvasCursor == true end)
    local made = S.cnt.builds - b0
    local n = pop and pop._focusRing and pop._focusRing[1] and pop._focusRing[1].elements and #pop._focusRing[1].elements or 0
    Q.check(okf and e ~= nil and e.isCanvasCursor == true and made >= 1,
        "W42: the controller's first ask builds the waiting stops on the spot and lands on the map's cursor (old: no waiting, nothing built for the ask)",
        made .. " build(s) for the ask, " .. n .. " stops, landed on " .. tostring(okf and e and e.id))
end)
-- the finding's second half: one unfolded map kept and used again, not a new one on every unfold
Q.step(3, function()
    ZEDQA_FRESH_STOPS = S.freshWas
    if S.mapSkip then return end
    pcall(Z.MapsTab.closePopout, RT.ww(), true)
end)
Q.waitFor(3, 240, function() local m = S.mp(); return S.mapSkip or (S.pop() == nil and m ~= nil and m:isReallyVisible()) end, function(ok)
    if S.mapSkip then return end
    if not Q.check(ok, "map staging: folded back, the drawer's map draws again") then S.mapSkip = true; S.putMap(); return end
    S.cnt.pframes = 0
    pcall(Z.MapsTab.openPopout, RT.ww())
end)
Q.waitFor(2, 240, function()
    local w = RT.ww()
    return S.mapSkip or (w ~= nil and w._mapPopout ~= nil and w._worldMapPanel ~= nil and w._worldMapPanel ~= w._worldMapPanelInline and S.cnt.pframes > 5)
end, function(ok)
    if S.mapSkip then return end
    local big2 = RT.ww()._worldMapPanel
    Q.check(ok and S.bigMap1 ~= nil and big2 == S.bigMap1,
        "W42 second half (not in Build's fix, 'W42, partly'): a second unfold uses the first unfold's map again (now: a new map every unfold, the old ones left behind)",
        (big2 == S.bigMap1) and "the same map" or "a new map")
    pcall(Z.MapsTab.closePopout, RT.ww(), true)
    S.countMap(false)
end)

-- ===================================================================== W54: the map's stick and triggers while paused
-- No pad on the QA machine. The map's own tick (_mapPadTick -> _mapPadPlayer, MapsTab.lua) asks getJoypadData for the
-- player's pad once the pad's focus is on the map's cursor. Here only a call made straight from MapsTab.lua gets a pad
-- (id 7, nobody's: the engine finds no controller there and reads its buttons as up), found on the Lua call stack, and
-- getControllerAxisValue answers pad 7's stick and triggers from S.stick. Every other caller gets the real answers.
S.FAKE = 7
S.stick = { x = 0, lt = 0, rt = 0 }
S.jdHits = 0
-- true when the code that called getJoypadData is in MapsTab.lua: the Lua call stack read from the top, past this
-- script's own frames (S.SELF) and the game's Java frames (no file name). False whenever it cannot tell.
function S.fromMap()
    if not S.SELF then return false end
    local hit = false
    pcall(function()
        local co = getCurrentCoroutine()
        local top = getCallframeTop(co)
        for i = top - 1, math.max(0, top - 12), -1 do
            local cf = getCoroutineCallframeStack(co, i)
            local f = cf and getFilenameOfCallframe(cf)
            if f and f ~= S.SELF then
                hit = string.find(string.lower(tostring(f)), "mapstab.lua", 1, true) ~= nil
                return
            end
        end
    end)
    return hit
end
function S.padStubs(on)
    if on and not S.stub then
        local st = { jd = getJoypadData, ax = getControllerAxisValue }
        S.stub = st
        local fake = { id = S.FAKE }
        getJoypadData = function(pn)
            if pn == S.pn and S.fromMap() then S.jdHits = S.jdHits + 1; return fake end
            return st.jd(pn)
        end
        getControllerAxisValue = function(cid, axis)
            if cid == S.FAKE then
                if axis == 0 then return S.stick.x end
                if axis == 4 then return S.stick.lt end
                if axis == 5 then return S.stick.rt end
                return 0
            end
            return st.ax(cid, axis)
        end
    elseif not on and S.stub then
        local st = S.stub
        S.stub = nil
        getJoypadData, getControllerAxisValue = st.jd, st.ax
    end
end
function S.putPad()
    S.stick.x, S.stick.lt, S.stick.rt = 0, 0, 0
    pcall(S.padStubs, false)
    if S.paused then S.pause(false) end
    if not S.back.pad then return end
    S.back.pad = nil
    local F, D = S.focus(), S.det()
    pcall(function() D.setLockedMode("kbm") end)
    pcall(function() F.releaseFocus(S.pn) end)
    pcall(function() if S.focusWas and S.focusWas.javaObject and S.focusWas:isReallyVisible() then F.claimFocus(S.focusWas) end end)
    -- (the map's tick lets go of these itself once the pad leaves the map; said again here in case it did not run)
    pcall(function() S.p:setBlockMovement(false) end)
    if setJoypadIgnoreAim then pcall(setJoypadIgnoreAim, S.pn, false) end
    -- the map's view as found: its centre, its zoom and the controller's cursor
    local v = S.view
    S.view = nil
    if v and v.m then
        pcall(function() v.m.mapAPI:centerOn(v.cx, v.cy) end)
        pcall(function() v.m:_zoomTo(v.z) end)
        v.m._gpCursorX, v.m._gpCursorY = v.gx, v.gy
    end
end
function S.cursorMid()
    local m = S.mp()
    m._gpCursorX, m._gpCursorY = math.floor(m:getWidth() / 2), math.floor(m:getHeight() / 2)
    return m._gpCursorX
end
Q.waitFor(3, 240, function()
    local m, w, F = S.mp(), RT.ww(), S.focus()
    -- (the fold above lands the pad on the unfold button a tick or two later: that landing is left to finish)
    return S.mapSkip or (S.pop() == nil and m ~= nil and m:isReallyVisible() and not (F.soonPending and w and F.soonPending(w)))
end, function(ok)
    if S.mapSkip then Q.skip("W54: the map's stick and triggers while paused", "the map could not be staged (see the map staging line above)"); return end
    if not Q.check(ok, "W54 staging: the Maps tab's own map is drawn and no landing waits") then S.w54Skip = true; return end
    if not S.SELF then Q.say("W54: this game gives no Lua call stack to read, so the map's tick cannot be handed a pad (the staging line below fails)") end
    local F, D, w, m = S.focus(), S.det(), RT.ww(), S.mp()
    S.focusWas = F.getFocusedWindow(S.pn)
    S.back.pad = true
    pcall(function()
        S.view = { m = m, cx = m.mapAPI:getCenterWorldX(), cy = m.mapAPI:getCenterWorldY(), z = m.mapAPI:getZoomF(),
                   gx = m._gpCursorX, gy = m._gpCursorY }
    end)
    D.setLockedMode("gamepad")
    F.claimFocus(w)
    local e = nil
    pcall(function() e = F.focusWhere(w, "worldTabContent", function(el) return el.isCanvasCursor == true end) end)
    local fe = F.getFocusedElement(w)
    if not Q.check(e ~= nil and F.getFocusedWindow(S.pn) == w and fe ~= nil and fe.isCanvasCursor == true,
        "W54 staging: the controller is on the map's cursor in the World window", "landed on " .. tostring(e and e.id)) then
        S.w54Skip = true; S.putPad(); return
    end
    S.padStubs(true)
    S.x0 = S.cursorMid()
    S.stick.x = 1                                -- the left stick pushed right, the game running
end)
Q.waitMs(350)
Q.step(1, function()
    if S.mapSkip or S.w54Skip then return end
    S.stick.x = 0
    local m = S.mp()
    if not Q.check(S.jdHits > 0 and m._gpCursorX ~= S.x0,
        "W54 staging: with the game running the left stick moves the map's cursor (the yardstick, old and new)",
        "cursor x " .. tostring(S.x0) .. " -> " .. tostring(m._gpCursorX) .. ", the map's tick read the pad " .. S.jdHits .. " times") then
        S.w54Skip = true; S.putPad(); return
    end
    S.pause(true)
end)
Q.step(8, function()
    if S.mapSkip or S.w54Skip then return end
    local F, w, m = S.focus(), RT.ww(), S.mp()
    if not Q.check(S.speed() == 0 and m ~= nil and m:isReallyVisible(), "W54 staging: the game is paused and the map still shows", "speed " .. S.speed()) then
        S.w54Skip = true; S.putPad(); return
    end
    -- (should the pause have taken the pad off the map, it is put back on it, as a player would)
    local fe = F.getFocusedElement(w)
    if not (F.getFocusedWindow(S.pn) == w and fe and fe.isCanvasCursor) then
        Q.say("W54: the pause took the pad off the map's cursor; put back on it")
        pcall(F.claimFocus, w)
        pcall(function() F.focusWhere(w, "worldTabContent", function(el) return el.isCanvasCursor == true end) end)
    end
    S.x0 = S.cursorMid()
    S.z0 = m.mapAPI:getZoomF()
    S.jdHits = 0
    S.stick.x, S.stick.rt = 1, 1                 -- stick right and the right trigger pulled (zoom in)
end)
Q.waitMs(450)
Q.step(1, function()
    if S.mapSkip or S.w54Skip then return end
    local m = S.mp()
    S.x1, S.z1, S.hits1 = m._gpCursorX, m.mapAPI:getZoomF(), S.jdHits
    S.stick.x, S.stick.rt, S.stick.lt = 0, 0, 1   -- then the left trigger (zoom out), in case the map was zoomed all the way in
end)
Q.waitMs(350)
Q.step(1, function()
    if S.mapSkip or S.w54Skip then return end
    local m = S.mp()
    local z2 = m.mapAPI:getZoomF()
    S.stick.lt = 0
    Q.check(S.speed() == 0 and S.hits1 > 0 and S.x1 ~= S.x0,
        "W54: paused, the left stick moves the map's cursor (old: dead while paused, the map's tick only ran with the game)",
        "cursor x " .. tostring(S.x0) .. " -> " .. tostring(S.x1) .. ", the map's tick read the pad " .. tostring(S.hits1) .. " times while paused")
    Q.check(S.speed() == 0 and (S.z1 ~= S.z0 or z2 ~= S.z1),
        "W54: paused, the triggers zoom the map (old: dead while paused)",
        string.format("zoom %.3f, after RT %.3f, after LT %.3f", S.z0, S.z1, z2))
    Q.skip("W54: a real controller's stick reaching the game while paused", "no controller on the QA machine: the stick and triggers were fed to the map's own tick; one pass on a real pad is the director's")
    S.putPad()
end)
Q.step(10, function() end)

-- ===================================================================== put back
Q.mark()
Q.step(3, function()
    -- (each on its own, so one that throws never stops the rest)
    pcall(S.putPad)
    pcall(S.putMap)
    pcall(S.putMsg)
    pcall(S.putStyle)
    pcall(S.putBelt)
    pcall(S.putHands)
    pcall(S.putHint)
    getMouseX, getMouseY = S.realMX, S.realMY
    if getJoypadData ~= S.realJD then getJoypadData = S.realJD end
    if getControllerAxisValue ~= S.realAX then getControllerAxisValue = S.realAX end
    ZEDQA_FRESH_STOPS = S.freshWas
    if S.speed() ~= 1 then S.pause(false) end
    S.showUI()
    if S.back.lock then
        S.back.lock = nil
        pcall(function()
            local D = S.det()
            D.setLockedMode("kbm")
            D.setLockedMode(nil)
            if S.lockWas == "kbm" or S.lockWas == "gamepad" then D.setLockedMode(S.lockWas) end
        end)
    end
end)
function S.putTab()
    if not S.back.tab then return end
    S.back.tab = nil
    pcall(function() if S.tabWas and RT.ww() and RT.ww()._activeTab ~= S.tabWas then RT.worldTab(S.tabWas) end end)
end
Q.step(5, function()
    if S.pairWas then RT.pairOpen()
    else
        S.putTab()                               -- (the World window goes back shut on the tab it opened with)
        RT.pairShut()
    end
    if S.back.god then
        S.back.god = nil
        pcall(function() S.p:setInvincible(S.invWas == true) end)
        pcall(function() S.p:setGodMod(S.godWas == true) end)
    end
end)
Q.step(5, function()
    -- the pair's places and pins as found (the prelude's layout put-back, which also puts the windows on Loot with the
    -- drawers shut), then the World window's tab as found (only when the pair was open at the start)
    if S.pairWas and S.snap and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, S.snap, "vx_hud") end
    S.putTab()
end)
Q.step(10, function()
    local hud = S.hud()
    local alive = false
    pcall(function() alive = not S.p:isDead() end)
    Q.check(alive, "put back: Angel is alive and was never in harm's way")
    Q.check(getMouseX == S.realMX and getMouseY == S.realMY and getJoypadData == S.realJD and getControllerAxisValue == S.realAX
        and S.stub == nil and S.mapCnt == nil and S.beltCnt == nil and S.beltStub == nil,
        "put back: the pointer, the pad and the counted functions are the real ones again")
    Q.check(S.speed() == 1 and S.uiShown(), "put back: the game runs at speed 1 and the interface shows", "speed " .. S.speed())
    Q.check(hud ~= nil and hud._out == nil and hud._press == nil, "put back: the belt holds no drag")
    Q.check(S.opt(Z.Settings.lookStyleOption) == (S.styleWas or S.opt(Z.Settings.lookStyleOption))
        and S.opt(Z.Settings.hintStripOption) == (S.hintOpt or S.opt(Z.Settings.hintStripOption))
        and S.opt(Z.Settings.messagesCatchOption) == (S.catchWas or S.opt(Z.Settings.messagesCatchOption))
        and S.opt(Z.Settings.messagesToastOption) == (S.toastWas or S.opt(Z.Settings.messagesToastOption)),
        "put back: the look style, the hint strip and the Messages options as found")
    Q.check(S.p:getPrimaryHandItem() == S.hand1 and S.p:getSecondaryHandItem() == S.hand2, "put back: his hands hold what they held")
    Q.check(S.pop() == nil and Z.Messages.sources[S.SRC] == nil, "put back: the map is folded and the test notes are gone from Messages")
end)
Q.start()
