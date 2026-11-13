-- ZeDUI/tools/qa/zedqa_cov_input.lua  (Nov 12 2026, QA; coverage audit ZeDUI/qa/AUDIT_DESIGN_AND_COVERAGE_20261111.md,
-- Table B, the "input" group; the review's fixes the same day)
-- The controller plumbing, the game's hidden top-left buttons and the text scale override, checked from ZeD's own
-- objects, in game on the ZeD-QA save only (it refuses any other save). Copy to Zomboid/Lua/zedqa.lua and bump
-- zedqa.go, or run cov_input.txt through zedqa_run.ps1; grep console.txt for "ZEDQA cov_input". Each check prints
-- "PASS <what>" or "FAIL <what> (<got> vs <want>)"; a check that could not run prints "FAIL <what> (not checked:
-- <why>)", so a skipped section never reads as a clean run; RESULT, then DONE.
-- Pictures (SHOT lines): Screenshots/zqa_cin_icons.png (the left-edge column with no window buttons),
-- zqa_cin_pad_world.png (RB moved the pad to the World window), zqa_cin_zoomed_in.png (two chord steps in).
--
-- WHAT IT CHECKS
--  Pad action map (Input/ActionMap.lua): every engine button object (JoypadButton.*, what the game hands a window's
--   onJoypadDown) maps to the pad spec's actions, each D-pad direction to its two; Joypad.AButton is the engine's
--   object, not a number (the 42.17 trap); the keys map to theirs, an unbound key and a key name to nothing;
--   getBinding per mode; getHoldConfig for Y (400 ms, tap and hold actions) and its 400 against the gp.holdMs token
--   FocusManager really times Y with; rebuild() picks up an action added to the table and one taken out; the lists
--   handed out are copies. Then the real pad path: the focused window's onJoypadDown(RB) moves the pad to the World
--   window, LB back to the Character window, a press on the window that does not hold the pad does nothing, and L3
--   steps the list's sort.
--  Input mode detector (Input/InputModeDetector.lua): a stand-in controller on slot 15 is fed to the detector's own
--   reads (getControllerCount, isControllerConnected, getControllerAxisValue, getControllerName; each axis read is
--   counted, so a "stays on mouse and keys" check fails when the detector never read the input): a stick inside the
--   dead zone stays on mouse and keys, past it switches to the pad and fires ZeD_InputModeChanged(gamepad, kbm); a key
--   (the engine's OnKeyPressed with an unbound key) inside the cooldown does not switch back (the time to the
--   detector's read is measured), after it does; a stick and a key on one tick: the key wins; a trigger under its
--   threshold (in auto mode, from mouse and keys, a cooldown after the last switch, so a misread would switch) and
--   over it; a pad unplugged with none left goes back to mouse and keys; the controller type from the pad's name; the
--   lock answers at once, switches the detector and tells the listeners, wins over a key, and a lock value that is
--   not a mode is ignored.
--  Pad bumpers, combat zoom (Input/BumperChord.lua): the bumpers are read through stand-ins for getJoypadData(0) and
--   JoypadButton.LeftBump / RightBump (nothing else of the game's is replaced): with a window holding the pad LB is
--   not the chord's; released, hold LB tap RB zooms in one level (the engine's target zoom, read back through
--   getNextZoom), each further RB tap one more, hold RB tap LB zooms out, a bumper alone does nothing, both on one
--   tick zoom in; the chord's states on the way (LB_HELD, RB_HELD, CONSUMED, IDLE); setEnabled(false) mid-chord
--   drops it; no pad on player 1's slot and a switch to mouse and keys mid-chord stop it.
--  Game's top-left buttons hidden (Overrides/ScreenIcons.lua): the window buttons of the left-edge column hidden; the
--   furniture button's hint and pop-up, each raised by the game's own prerender for a frame (the game's furniture
--   cursor up for the hint, a stand-in pointer on the button for the pop-up; a spy on each setVisible shows the
--   raise) and taken down again by ZeD's in that frame; no hover label left for the hidden buttons; the debug button
--   left alone; the hand slots the belt hid leave no hover zone; safe mode's hand-back shows the buttons the game had
--   showing and its whole hover list, and the next frames hide them again.
--  Text scale override (Overrides/TextScale.lua): the patches are in (presence); each role font zooms by its px x the
--   root over its face; ISUIElement text draws (left, right, centered) of a role font take the engine's zoom call, a
--   vanilla font the engine's own call untouched, a collapsed element draws nothing; borders are T.px(1) thick on
--   ZeD elements and one pixel on vanilla ones; the lean draw calls make exactly ISUIElement's Java calls; the listed
--   classes are flagged and every ZeD UI class has the lean calls (presence); ZeD.TM measures role fonts zoomed and
--   vanilla ones as they are; a ZeD text entry takes the face for the scale, the game's own placeholder (set first
--   through vanilla's setter) is emptied and ZeD draws its own; the tooltip text size option reaches the zoom. (The
--   draws are recorded on a stand-in Java object: the same functions the panels call, nothing drawn.)
-- PUTS BACK (also when a step fails): every stand-in global (on its own too, 90 s after it went in, and at the start
-- of a run that finds one left behind), the zoom level, the input mode and lock (the detector through the mode the
-- lock gives, or the mode the run found when ZeD setup says auto, then the lock as ZeD setup's own option has it),
-- each window as found (one the run opened is closed again, a rolled half or window rolled again), then the pad
-- focus, the sort and the scroll L3 changed, the test text entry, the probe action, the role px and the zoom kept for
-- it, the furniture cursor and the game's cursor globals it touched (mode, its cache, the cursor, the info box), the
-- way the character faces (the game's cursor turns an idle character toward the pointer), what ZeD's Furniture tab
-- read from the cursor (ZeD.FurnitureTab.cap[0], which its info box hook overwrites), the
-- stand-in pointer and the spies, ZeD's Furniture tab timer, the game's flags for controller slot 15 and its
-- controller test, the game speed (a paused game is unpaused for the run and paused again at the end).
-- ASSUMES: no real controller connected or joined. The synthetic unplug (OnGamepadDisconnect for slot 15) reaches
-- every listener, vanilla's main menu hand-back and options screen too; with none connected or joined they find
-- nothing to change, and with one the check is not made (FAIL, not checked). Kahlua-safe: ASCII only, no table
-- iterator calls outside pairs and ipairs.

local TAG = "ZEDQA cov_input "
local function say(s) print(TAG .. tostring(s)) end
local npass, nfail, nskip = 0, 0, 0
local function check(ok, what, got, want)
    if ok then
        npass = npass + 1
        say("PASS " .. what)
    else
        nfail = nfail + 1
        say("FAIL " .. what .. " (" .. tostring(got) .. " vs " .. tostring(want) .. ")")
    end
    return ok
end
-- a check that could not run counts as a FAIL, so a skipped section never reads as a clean run
local function skip(what, why)
    nfail, nskip = nfail + 1, nskip + 1
    say("FAIL " .. what .. " (not checked: " .. tostring(why) .. ")")
end
local function shot(n)
    local name = "zqa_cin_" .. n .. ".png"
    pcall(function() getCore():TakeFullScreenshot(name) end)
    say("SHOT " .. name)
end

local p = getPlayer()
local IN = (ZeD and ZeD.Input) or {}
local Det, Chord, Act, Focus = IN.Detector, IN.Chord, IN.Action, IN.Focus
local X, LEAN = ZeD and ZeD.Text, ZeD and ZeD.LeanDraw
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local FC = 15   -- the stand-in controller's slot (GLFW's last of 16; nothing real sits there on the QA rig)
local ICONS = { "invBtn", "healthBtn", "craftingBtn", "buildBtn", "movableBtn", "searchBtn", "zoneBtn", "mapBtn" }
local LEAN_NAMES = { "drawRect", "drawRectBorder", "drawText", "drawTextureScaled", "drawTextureScaledAspect" }
-- (Overrides/TextScale.lua's list of classes flagged zedScaled)
local ZED_CLASSES = { "ZeD_Panel", "ZeD_Window", "ZeD_Button", "ZeD_TextInput", "ZeD_TextEntry", "ZeD_SearchField",
    "ZeD_Tooltip", "ZeD_ScrollList", "ZeD_ScrollPanel", "ZeD_ZoneList", "ZeD_Dropdown", "ZeD_Modal", "ZeD_TabPanel",
    "ZeD_ItemGrid", "ZeD_ItemCard", "ZeD_BodyFigure", "ZeD_ContextMenu", "ZeD_ContextList", "ZeD_Dashboard", "ZeD_Watch",
    "ZeD_ObjectCard", "ZeD_FurnitureChip", "ZeD_MMBar", "ZeD_MMDrop", "ZeD_MMIcons" }
local SPEC_ACTIONS = { "confirm", "cancel", "nav_up", "nav_down", "nav_left", "nav_right", "window_prev", "window_next",
    "window_control", "layout_mode", "context_menu", "strip_hotbar", "strip_social", "strip_contextual", "strip_favorites",
    "list_sort", "list_view", "inspect" }
-- the engine's button objects (JoypadButton.<name>) and what the pad spec gives each
local PADMAP = {
    { "A", "confirm" }, { "B", "cancel" }, { "X", "context_menu" }, { "Y", "window_control" },
    { "LeftBump", "window_prev" }, { "RightBump", "window_next" }, { "Back", "layout_mode" }, { "Start", "(none)" },
    { "Guide", "(none)" }, { "LeftStick", "list_sort" }, { "RightStick", "list_view" },
    { "DPadUp", "nav_up strip_hotbar" }, { "DPadDown", "nav_down strip_social" },
    { "DPadLeft", "nav_left strip_contextual" }, { "DPadRight", "nav_right strip_favorites" },
}
local KEYMAP = { { "KEY_RETURN", "confirm" }, { "KEY_ESCAPE", "cancel" }, { "KEY_UP", "nav_up" }, { "KEY_DOWN", "nav_down" },
                 { "KEY_LEFT", "nav_left" }, { "KEY_RIGHT", "nav_right" }, { "KEY_I", "inspect" } }

-- the run's state: the stand-in bumpers (lb, rb) and pad data (jd), the stand-in controller (fc), the mode events seen
local S = { lb = false, rb = false, jd = { id = 0 }, deadline = 0, events = {}, nEv = 0, tSw = 0, finished = false }

-- THE GAME'S FUNCTIONS THE STAND-INS REPLACE ---------------------------------------------------------------------
local O = ZEDQA_CIN_ORIG
if O then
    -- a run before this one stopped without putting them back: back now, before they are kept again
    getJoypadData, JoypadButton = O.gjd, O.jb
    getControllerCount, isControllerConnected, getControllerAxisValue, getControllerName = O.gcc, O.icc, O.gcav, O.gcn
    say("a run before this one left its stand-ins in: the game's functions are back")
end
O = { gjd = getJoypadData, jb = JoypadButton, gcc = getControllerCount, icc = isControllerConnected,
      gcav = getControllerAxisValue, gcn = getControllerName }
ZEDQA_CIN_ORIG = O

local function unstub(why)
    getJoypadData, JoypadButton = O.gjd, O.jb
    getControllerCount, isControllerConnected, getControllerAxisValue, getControllerName = O.gcc, O.icc, O.gcav, O.gcn
    if (S.padStub or S.ctlStub) and why then say("stand-ins out: " .. why) end
    S.padStub, S.ctlStub = false, false
end
local function late()
    if getTimestampMs() > S.deadline then unstub("past their 90 s, the script stalled"); return true end
    return false
end

-- the bumpers: BumperChord reads getJoypadData(0).id, then JoypadButton.LeftBump / RightBump:isDown(id)
local FAKE_LB = { isDown = function(_, _) if late() then return false end; return S.lb == true end }
local FAKE_RB = { isDown = function(_, _) if late() then return false end; return S.rb == true end }
local JB = setmetatable({ LeftBump = FAKE_LB, RightBump = FAKE_RB }, { __index = O.jb })
local function fakeJoypadData(n)
    if late() then return O.gjd(n) end
    if n == 0 then return S.jd end
    return O.gjd(n)
end
local function padStub(on)
    S.lb, S.rb = false, false
    if on then
        S.deadline = getTimestampMs() + 90000
        S.jd = { id = 0 }
        getJoypadData, JoypadButton = fakeJoypadData, JB
        S.padStub = true
    else
        getJoypadData, JoypadButton = O.gjd, O.jb
        S.padStub = false
    end
end

-- the controller the detector polls: slot FC, axes 0-1 left stick, 2-3 right stick, 4-5 triggers (SDL order); every
-- read of an axis is counted (fc.reads), so a check that the detector stayed put can tell it read the input
local function ctlStub(on)
    if not on then
        getControllerCount, isControllerConnected, getControllerAxisValue, getControllerName = O.gcc, O.icc, O.gcav, O.gcn
        S.ctlStub = false
        return
    end
    S.deadline = getTimestampMs() + 90000
    S.fc = { connected = true, none = false, ax = { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 }, reads = {},
             name = "QA Pad" }
    getControllerCount = function()
        local n = O.gcc() or 0
        if late() then return n end
        return (n > FC) and n or (FC + 1)
    end
    isControllerConnected = function(i)
        if not S.ctlStub then return O.icc(i) end
        if S.fc.none then return false end
        if i == FC then return S.fc.connected end
        return O.icc(i)
    end
    getControllerAxisValue = function(i, a)
        if S.ctlStub and i == FC then
            S.fc.reads[a] = (S.fc.reads[a] or 0) + 1
            return S.fc.ax[a] or 0
        end
        return O.gcav(i, a)
    end
    getControllerName = function(i)
        if S.ctlStub and i == FC then return S.fc.name end
        return O.gcn(i)
    end
    S.ctlStub = true
end

-- HELPERS ----------------------------------------------------------------------------------------------------------
local function label(w) return w and tostring(w._zedLabel or "a window") or "none" end
local function norm(list)
    if type(list) ~= "table" or #list == 0 then return "(none)" end
    local c = {}
    for k = 1, #list do c[k] = tostring(list[k]) end
    table.sort(c)
    return table.concat(c, " ")
end
local function cooldown() return (ZeD.T and ZeD.T.gp and ZeD.T.gp.cooldownMs) or 200 end
local function stickTh() return (ZeD.T and ZeD.T.gp and ZeD.T.gp.stickThresh) or 0.2 end
local function trigTh() return (ZeD.T and ZeD.T.gp and ZeD.T.gp.triggerThresh) or 0.15 end
-- ZeD setup's input mode choice from the mod option itself, as Settings.lua's applyInputLock reads it (the
-- character's modData copy is only written when it changes with a character loaded): nil for auto
local function settingLock()
    local MO = PZAPI and PZAPI.ModOptions
    local opts = MO and MO.getOptions and MO:getOptions("ZeD_UI")
    local o = opts and opts.getOption and opts:getOption("inputModeLock")
    local keys = ZeD.Settings and ZeD.Settings.inputLockKeys
    local key = (o and keys) and keys[o:getValue() or 1] or nil
    if key == "kbm" or key == "gamepad" then return key end
    return nil
end
-- the real pads: how many are connected (the game's own functions), and whether one is joined to a player or the menu
local function realPads()
    local n, joined = 0, false
    local c = O.gcc() or 0
    for i = 0, c - 1 do if O.icc(i) then n = n + 1 end end
    if JoypadState then
        for i = 1, 4 do if JoypadState.players and JoypadState.players[i] then joined = true end end
        for _, jd in ipairs(JoypadState.joypads or {}) do if jd.id ~= nil and jd.id ~= -1 then joined = true end end
    end
    return n, joined
end
-- a window as found: open, rolled up, and (a window with halves, WindowHalves.lua) each half's roll
local function winState(M)
    local w = M and M.getWindow and M.getWindow()
    if not w then return { open = false } end
    local st = { open = true, shaded = w.windowShaded and true or false }
    local h = w._halves
    if h and h.inv and h.drawer then st.inv, st.drw = h.inv.rolled and true or false, h.drawer.rolled and true or false end
    return st
end
local function winText(st)
    if not st.open then return "closed" end
    return st.shaded and "rolled up" or "open"
end
local function putWindow(name, M, s0, close)
    if not s0 then return end
    local w = M.getWindow and M.getWindow()
    if not s0.open then
        if w then close(); say("INFO put back: the " .. name .. " window the run opened (the switch to the pad opens the pair) is closed again") end
        return
    end
    if not w then say("INFO the " .. name .. " window open at the start was closed during the run: left closed"); return end
    local h = w._halves
    if s0.inv ~= nil and h and h.inv and h.drawer then
        -- (the halves roll the window themselves, ZeD.Halves.drive, one step now and the rest on its own updates)
        if (h.inv.rolled and true or false) ~= s0.inv or (h.drawer.rolled and true or false) ~= s0.drw then
            h.inv.rolled, h.drawer.rolled = s0.inv, s0.drw
            h.inv.out, h.drawer.out = nil, nil
            if ZeD.Halves and ZeD.Halves.drive then ZeD.Halves.drive(w) end
            say("INFO put back: the " .. name .. " window's halves rolled as found (inventory " .. tostring(s0.inv)
                .. ", drawer " .. tostring(s0.drw) .. ")")
        end
    elseif (w.windowShaded and true or false) ~= s0.shaded and w.setWindowShaded then
        w:setWindowShaded(s0.shaded)
        say("INFO put back: the " .. name .. " window " .. (s0.shaded and "rolled up" or "rolled down") .. " as found")
    end
end
-- the engine's target zoom sits between these two (getNextZoom reads the target, which doZoomScroll sets at once)
local function zl()
    local c = getCore()
    return { up = c:getNextZoom(0, 1), dn = c:getNextZoom(0, -1) }
end
local function moved(a, b)
    if b.up < a.up or b.dn < a.dn then return "in" end
    if b.up > a.up or b.dn > a.dn then return "out" end
    return "none"
end
local function zoomCheck(want, what)
    if not S.zoomOk then skip(what, "the zoom level cannot move here"); return end
    local b = zl()
    local got = moved(S.z, b)
    check(got == want, what, string.format("%s, target now between %.2f and %.2f, was %.2f and %.2f", got, b.dn, b.up, S.z.dn, S.z.up), want)
    S.z = b
end
local function restoreZoom()
    local z0 = S.z0
    if not z0 or z0.up == z0.dn then return end   -- (between levels at the start: nothing could move it)
    local c = getCore()
    for _ = 1, 16 do
        local now = zl()
        if now.up == z0.up and now.dn == z0.dn then return end
        if now.up > z0.up or now.dn > z0.dn then c:doZoomScroll(0, -1) else c:doZoomScroll(0, 1) end
    end
    say("INFO the zoom level did not come back exactly")
end
-- a key no binding of the game's uses (F15 first), for the detector's OnKeyPressed
local function freeKey()
    local core = getCore()
    for _, name in ipairs({ "KEY_F15", "KEY_F16", "KEY_F17", "KEY_F18", "KEY_F14", "KEY_F13" }) do
        local k = Keyboard[name]
        if k then
            local used = false
            for _, b in ipairs(keyBinding or {}) do
                if b.key ~= nil and type(b.value) == "string" then
                    local ok1, v1 = pcall(function() return core:getKey(b.value) end)
                    local ok2, v2 = pcall(function() return core:getAltKey(b.value) end)
                    if (ok1 and v1 == k) or (ok2 and v2 == k) then used = true; break end
                end
            end
            if not used then return k end
        end
    end
    return nil
end
-- a stand-in Java object that writes down every draw call made on it
local function recorder()
    local r = { calls = {} }
    local function rec(name)
        return function(_, ...)
            r.calls[#r.calls + 1] = { name = name, n = select("#", ...), a = { ... } }
        end
    end
    r.jo = { DrawText = rec("DrawText"), DrawTextRight = rec("DrawTextRight"), DrawTextCentre = rec("DrawTextCentre"),
             DrawTextureScaledColor = rec("DTSC"), DrawTextureScaled = rec("DTS"), DrawTextureScaledAspect = rec("DTSA") }
    return r
end
local function sig(r)
    local out = {}
    for _, c in ipairs(r.calls) do
        local parts = { c.name }
        for k = 1, c.n do parts[#parts + 1] = tostring(c.a[k]) end
        out[#out + 1] = table.concat(parts, ",")
    end
    return (#out > 0) and table.concat(out, " | ") or "(no draw)"
end
local function isUI(c)
    local m = getmetatable(c)
    for _ = 1, 24 do
        if m == nil then return false end
        if m == ISUIElement then return true end
        m = getmetatable(m)
    end
    return false
end
-- a vanilla font that is not one of the five role fonts (zoom 1)
local function vanillaFont()
    local T = ZeD.T
    for _, name in ipairs({ "Small", "Medium", "Large", "NewSmall", "Code" }) do
        local f = UIFont[name]
        local role = false
        for i = 1, 5 do if T["fontF" .. i] == f then role = true end end
        if f ~= nil and not role and X.zoomOf(f) == 1 then return f end
    end
    return nil
end
-- the sort L3 stepped and the scroll it sent to the top (InventoryRenderer.padSort), back as found
local function restoreSort()
    local s = S.sortSave
    if not s then return end
    S.sortSave = nil
    s.cnt._sortCol, s.cnt._sortAsc = s.col, s.asc
    if s.cs then s.cs.sortCol, s.cs.sortAsc = s.cscol, s.csasc end
    if s.sb and s.pos ~= nil then
        if s.sb.setScrollPos then s.sb:setScrollPos(s.pos) else s.sb.scrollPos = s.pos end
    end
end
local function onMode(newMode, oldMode)
    S.events[#S.events + 1] = { new = tostring(newMode), old = tostring(oldMode) }
end
local function lastEv()
    local e = S.events[#S.events]
    return e and (e.new .. "," .. e.old) or "none"
end
-- the synthetic unplug's marks on the game, back as found: slot 15's flag, the controller test flag, the menu's pad focus
local function unplugBack()
    local u = S.unplug
    if not u then return end
    S.unplug = nil
    if S.fc then S.fc.none = false end
    local vc = JoypadState and JoypadState.controllers and JoypadState.controllers[FC]
    if vc then vc.connected = u.v end
    if JoypadState then JoypadState.controllerTest = u.test end
    if u.ms then u.ms.joyfocus = u.focus end
end

-- the furniture button's hint and pop-up: a spy on an element's setVisible (every value set, in order); the game's
-- cursor up for a frame; a stand-in pointer on the button for a frame. Each is taken down by its pair below.
local function spyVisible(el, log)
    local own = rawget(el, "setVisible")
    local base = el.setVisible
    el.setVisible = function(self, v, ...)
        log[#log + 1] = v and true or false
        return base(self, v, ...)
    end
    return { el = el, own = own }
end
local function unspy(s) if s then s.el.setVisible = s.own end end
local function sawRaise(log)
    for _, v in ipairs(log) do if v then return true end end
    return false
end
local function furCursorUp(eq)
    local MC, IW = ISMoveableCursor, ISMoveableInfoWindow
    local F = { tip = {}, pop = {}, deadline = getTimestampMs() + 10000 }
    S.fur = F
    F.spyTip = spyVisible(eq.movableTooltip, F.tip)
    -- (ZeD's Furniture tab opens itself for a cursor started any other way, FurnitureTab.lua's watch: held off)
    local FTs = ZeD.FurnitureTab and ZeD.FurnitureTab.state
    if FTs then F.ft, F.ftOpening = FTs, FTs.openingMs; FTs.openingMs = getTimestampMs() + 60000 end
    -- (the game's cursor globals this touches: the mode, its cache, the cursor, the info box)
    F.mode0, F.cache0, F.cur0 = MC.mode[0], MC.cacheMode[0], MC.cursors and MC.cursors[0]
    F.panel0 = IW and IW.infoPanels and IW.infoPanels[0]
    F.globals = true
    -- (the game's cursor turns an idle character toward the pointer; ZeD's info box hook records what the cursor read)
    F.ang0 = p:getDirectionAngle()
    F.capT = ZeD.FurnitureTab and ZeD.FurnitureTab.cap
    if F.capT then F.cap0 = F.capT[0] end
    -- (pickup, already cached: nothing turned and hidden as rotate does, no info box text, no sound)
    MC.mode[0], MC.cacheMode[0] = "pickup", "pickup"
    F.cursor = MC:new(p)
    getCell():setDrag(F.cursor, 0)
end
local function furCursorDown()
    local F = S.fur
    if not F then return end
    local MC, IW = ISMoveableCursor, ISMoveableInfoWindow
    local cur = F.cursor
    F.cursor = nil
    if cur then
        local cell = getCell()
        if cell and cell:getDrag(0) == cur then cur:exitCursor() end
    end
    if F.globals then
        F.globals = nil
        MC.mode[0], MC.cacheMode[0] = F.mode0, F.cache0
        if MC.cursors then MC.cursors[0] = F.cur0 end
        if IW and IW.infoPanels then
            local made = IW.infoPanels[0]
            if made and made ~= F.panel0 then made:removeFromUIManager() end
            IW.infoPanels[0] = F.panel0
        end
        if F.ang0 then p:setDirectionAngle(F.ang0); F.ang0 = nil end
        if F.capT then F.capT[0] = F.cap0; F.capT, F.cap0 = nil, nil end
    end
    unspy(F.spyTip); F.spyTip = nil
    if F.ft then F.ft.openingMs = F.ftOpening; F.ft = nil end
end
local function furHoverUp(eq)
    local F = S.fur
    S.popTried = true
    F.spyPop = spyVisible(eq.movablePopup, F.pop)
    F.overBtn, F.overOwn = eq.movableBtn, rawget(eq.movableBtn, "isMouseOver")
    eq.movableBtn.isMouseOver = function() return true end
end
local function furHoverDown()
    local F = S.fur
    if not F then return end
    if F.overBtn then F.overBtn.isMouseOver = F.overOwn; F.overBtn = nil end
    unspy(F.spyPop); F.spyPop = nil
end
local function watch()
    if S.finished then Events.OnRenderTick.Remove(watch); return end
    local now = getTimestampMs()
    if (S.padStub or S.ctlStub) and now > S.deadline then unstub("past their 90 s, the game stopped ticking") end
    if S.fur and now > S.fur.deadline then
        furCursorDown(); furHoverDown(); S.fur = nil
        say("INFO the furniture cursor and the stand-in pointer came down after 10 s: the game stopped ticking")
    end
end

-- THE QUEUE: step(n, fn) runs fn, then waits n ticks; untilDo(cond, ms, fn, n) waits for cond (at most ms), runs
-- fn(cond met), then waits n ticks. Everything runs on OnTick, after BumperChord's and the detector's own ticks.
local Q, qi, waitT = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function untilDo(cond, ms, fn, n) Q[#Q + 1] = { cond = cond, ms = ms, fn = fn, n = n } end
local cleanup, finish
local function sinceSwitch(ms) return function() return getTimestampMs() - S.tSw >= ms end end

-- ================================================================================================================
-- A. THE PAD ACTION MAP (pure lookups)
-- ================================================================================================================
step(1, function()
    local A = ZeD.Input.Actions
    local missing, n = {}, 0
    for _, id in ipairs(SPEC_ACTIONS) do if not A[id] then missing[#missing + 1] = id end end
    for _ in pairs(A) do n = n + 1 end
    check(#missing == 0, "action map: the pad spec's 18 actions are all in the table (" .. n .. " entries)", table.concat(missing, " "), "none missing")
    for _, e in ipairs(PADMAP) do
        local obj = O.jb[e[1]]
        if obj == nil then
            skip("action map: the engine's " .. e[1] .. " button", "no such JoypadButton in this build")
        else
            local got = norm(Act.fromGamepadButton(obj))
            check(got == e[2], "action map: the engine's " .. e[1] .. " button object maps to " .. e[2], got, e[2])
        end
    end
    local alias = Joypad and Joypad.AButton
    local got = type(alias) .. " " .. norm(alias and Act.fromGamepadButton(alias))
    check(alias ~= nil and type(alias) ~= "number" and alias == O.jb.A and got == "userdata confirm",
        "action map: Joypad.AButton, what the engine dispatches, is the engine's A object (not a number) and maps to confirm", got, "userdata confirm")
end)
step(1, function()
    for _, e in ipairs(KEYMAP) do
        local code = Keyboard[e[1]]
        local got = norm(code and Act.fromKey(code))
        check(got == e[2], "action map: key " .. e[1] .. " maps to " .. e[2], got, e[2])
    end
    S.freeKey = freeKey()
    if S.freeKey then
        local got = norm(Act.fromKey(S.freeKey))
        check(got == "(none)", "action map: an unbound key (" .. tostring(S.freeKey) .. ") maps to nothing", got, "(none)")
    else
        skip("action map: an unbound key", "F13 to F18 are all bound")
    end
    check(Act.fromKey("Return") == nil, "action map: a key name in place of a key code maps to nothing", norm(Act.fromKey("Return")), "(none)")
    local gy = norm(Act.fromGamepadButton("Y"))
    check(gy == "window_control", "action map: the spec name \"Y\" maps as the engine's Y does", gy, "window_control")
    local l1 = Act.fromGamepadButton(O.jb.DPadUp)
    if l1 then l1[1] = "qa_changed"; l1[#l1 + 1] = "qa_added" end
    local l2 = norm(Act.fromGamepadButton(O.jb.DPadUp))
    check(l2 == "nav_up strip_hotbar", "action map: a list handed out is a copy (changing it leaves the map as it was)", l2, "nav_up strip_hotbar")
    Act.rebuild()   -- (were it not a copy, the map is whole again from the table)
    local B = Act.getBinding
    local gb = tostring(B("confirm", "kbm")) .. " " .. tostring(B("confirm", "gamepad")) .. " " .. tostring(B("context_menu", "kbm")) .. " " .. tostring(B("window_prev", "kbm"))
    check(gb == "Return A MouseRight nil", "action map: getBinding per mode (confirm Return and A, context menu the right button, LB no key)", gb, "Return A MouseRight nil")
    local gn = tostring(B("no_such_action", "gamepad")) .. " " .. tostring(B("confirm", "joystick"))
    check(gn == "nil nil", "action map: getBinding of an unknown action or mode is nil", gn, "nil nil")
    local hc = Act.getHoldConfig("window_control")
    local hs = hc and (tostring(hc.holdMs) .. " " .. tostring(hc.tapAction) .. " " .. tostring(hc.holdAction)) or "nil"
    check(hc ~= nil and hc.holdMs == 400 and hc.tapAction == "toggle_pair_visibility" and hc.holdAction == "close_pair",
        "action map: Y's hold config is 400 ms, a tap toggles the pair, the hold closes it", hs, "400 toggle_pair_visibility close_pair")
    check(Act.getHoldConfig("confirm") == nil, "action map: an action with no hold has no hold config", tostring(Act.getHoldConfig("confirm")), "nil")
    local tok = ZeD.T and ZeD.T.gp and ZeD.T.gp.holdMs
    check(hc ~= nil and tok == hc.holdMs, "action map: Y's hold in the map matches the gp.holdMs token FocusManager times Y with",
        hc and hc.holdMs, "token " .. tostring(tok))
    -- rebuild(): an action added to the table, then taken out again
    ZeD.Input.Actions.__qa_probe = { gamepad = "Start" }
    S.probe = true
    Act.rebuild()
    local got1 = norm(Act.fromGamepadButton(O.jb.Start))
    ZeD.Input.Actions.__qa_probe = nil
    Act.rebuild()
    S.probe = nil
    local got2 = norm(Act.fromGamepadButton(O.jb.Start))
    check(got1 == "__qa_probe" and got2 == "(none)", "action map: rebuild() picks up an action added to the table and one taken out",
        got1 .. " then " .. got2, "__qa_probe then (none)")
end)

-- ================================================================================================================
-- B. THE GAME'S TOP-LEFT BUTTONS (the left-edge column, ISEquippedItem)
-- ================================================================================================================
step(1, function()
    check(ISEquippedItem ~= nil and ISEquippedItem._zedScreenIconsPatched == true, "top-left buttons: the override is on the game's column (presence: its patch flag)",
        tostring(ISEquippedItem and ISEquippedItem._zedScreenIconsPatched), "true")
    local pd = getPlayerData and getPlayerData(0)
    local eq = pd and pd.equipped
    if not eq then skip("top-left buttons", "no left-edge column for player 1"); return end
    if ZeD.Safe.on("belt") then skip("top-left buttons", "safe mode, or the belt given back to the game: the column is the game's"); return end
    S.eq = eq
    local hiddenSet = {}
    for _, k in ipairs(ICONS) do
        local b = eq[k]
        if b then
            hiddenSet[b] = true
            check(not b:getIsVisible(), "top-left buttons: " .. k .. " is hidden", "showing", "hidden")
        else
            say("INFO top-left buttons: the game built no " .. k .. " here")
        end
    end
    local left = 0
    for _, v in ipairs(eq.mouseOverList or {}) do if hiddenSet[v.object] then left = left + 1 end end
    check(left == 0, "top-left buttons: no hover label is left for a hidden button", left .. " left", "0")
    if eq.debugBtn then
        local listed = false
        for _, v in ipairs(eq.mouseOverList or {}) do if v.object == eq.debugBtn then listed = true end end
        check(eq.debugBtn:getIsVisible() and listed, "top-left buttons: the debug button is left alone (showing, with its hover label)",
            tostring(eq.debugBtn:getIsVisible()) .. "/" .. tostring(listed), "true/true")
    else
        skip("top-left buttons: the debug button", "not built (a game without -debug)")
    end
    -- the hand slots: the belt hides them (Overrides/Belt.lua); the game's hover list holds stand-in rects for them
    local mh, oh = eq.mainHand, eq.offHand
    if mh and not mh:getIsVisible() and eq:getIsVisible() then
        local zones = 0
        for _, v in ipairs(eq.mouseOverList or {}) do
            local o = v.object
            if o == mh or o == oh then
                zones = zones + 1
            elseif type(o) == "table" and o.getX and o.getY then
                local ox, oy = o:getX(), o:getY()
                if (ox == mh:getX() and oy == mh:getY()) or (oh and ox == oh:getX() and oy == oh:getY()) then zones = zones + 1 end
            end
        end
        check(zones == 0, "top-left buttons: the hand slots the belt hid leave no hover zone (else the held item's tooltip opens over the empty corner)",
            zones .. " hover zones on the hidden hand slots", "0")
    else
        skip("top-left buttons: the hidden hand slots' hover", "the hand slots show, or the column is hidden")
    end
    shot("icons")
end)
-- the furniture button's hint and pop-up: the game's prerender raises the hint every frame its furniture cursor is up
-- and the pop-up every frame the pointer is on the button (idle, it keeps both down itself, so only a raise tests
-- ZeD); ZeD's prerender must take each down again in the same frame
step(0, function()
    local eq = S.eq
    if not eq then return end   -- (the section's first step said why)
    local what, MC, cell = "top-left buttons: the furniture hint and pop-up", ISMoveableCursor, getCell()
    if not eq:getIsVisible() then skip(what, "the column is hidden: its prerender does not run"); return end
    if not (eq.movableBtn and eq.movableTooltip and eq.movablePopup) then skip(what, "the game built no furniture button here"); return end
    if not (MC and MC.new and MC.mode and MC.cacheMode and cell) then skip(what, "no furniture cursor (ISMoveableCursor) loaded"); return end
    if cell:getDrag(0) ~= nil then skip(what, "a cursor of the game's is up"); return end
    if ISEntityUI and ISEntityUI.IsWindowOpen and ISEntityUI.IsWindowOpen(0, "BuildWindow") then
        skip(what, "the game's build window is open (a cursor hides it)"); return
    end
    S.furTried = true
    furCursorUp(eq)
end)
untilDo(function() return S.fur == nil or sawRaise(S.fur.tip) end, 1500, function(ok)
    local F, eq = S.fur, S.eq
    if not F then
        if S.furTried then skip("top-left buttons: the furniture hint and pop-up", "the cursor came down before a frame drew") end
        return
    end
    local tip = eq.movableTooltip
    local last = F.tip[#F.tip]
    check(ok and last == false and not tip:getIsVisible(),
        "top-left buttons: the furniture hint the game raises for its cursor is taken down in the same frame",
        "raised by the game " .. tostring(ok) .. ", last set " .. tostring(last) .. ", showing " .. tostring(tip:getIsVisible()),
        "raised by the game true, last set false, showing false")
    furCursorDown()
    furHoverUp(eq)
end, 0)
untilDo(function() return S.fur == nil or sawRaise(S.fur.pop) end, 1500, function(ok)
    local F, eq = S.fur, S.eq
    if not F then
        if S.popTried then skip("top-left buttons: the furniture pop-up", "the stand-in pointer came down before a frame drew") end
        return
    end
    local pop = eq.movablePopup
    local last = F.pop[#F.pop]
    check(ok and last == false and not pop:getIsVisible(),
        "top-left buttons: the furniture pop-up the game raises for the pointer on its button is taken down in the same frame",
        "raised by the game " .. tostring(ok) .. ", last set " .. tostring(last) .. ", showing " .. tostring(pop:getIsVisible()),
        "raised by the game true, last set false, showing false")
    furHoverDown()
    S.fur = nil
end, 0)
step(1, function()
    -- safe mode's hand-back ("screen icons" in ZeD.Safe): the buttons the game had showing and its whole hover list
    local eq = S.eq
    if not eq then return end
    -- (a hidden column runs no prerender, so nothing would hide them again: single player without -debug)
    if not eq:getIsVisible() then skip("top-left buttons: safe mode's hand-back", "the column itself is hidden"); return end
    local h = ZeD.Safe._hooks and ZeD.Safe._hooks["screen icons"]
    if not (h and h.leave) then skip("top-left buttons: safe mode's hand-back", "no \"screen icons\" hook registered"); return end
    S.iconsShown = {}
    for _, b in ipairs(eq._zedHiddenBtns or {}) do S.iconsShown[#S.iconsShown + 1] = b end
    S.fullN = #(eq._zedOverAll or {})
    h.leave()
    local back = 0
    for _, b in ipairs(S.iconsShown) do if b:getIsVisible() then back = back + 1 end end
    check(#S.iconsShown > 0 and back == #S.iconsShown, "top-left buttons: safe mode's hand-back shows the buttons the game had showing",
        back .. " of " .. #S.iconsShown, "all")
    local n = #(eq.mouseOverList or {})
    check(S.fullN > 0 and n == S.fullN, "top-left buttons: the hand-back also puts the game's whole hover list back", n, S.fullN)
end)
step(4, function() end)   -- (ZeD's prerender takes over again on the next frame)
step(1, function()
    local eq = S.eq
    if not (eq and S.iconsShown) then return end
    local still, hiddenSet = 0, {}
    for _, b in ipairs(S.iconsShown) do
        hiddenSet[b] = true
        if b:getIsVisible() then still = still + 1 end
    end
    local left = 0
    for _, v in ipairs(eq.mouseOverList or {}) do if hiddenSet[v.object] then left = left + 1 end end
    check(still == 0 and eq._zedIconsHidden == true and left == 0, "top-left buttons: the next frames hide them and their hover labels again",
        still .. " showing, " .. left .. " labels", "0 showing, 0 labels")
end)

-- ================================================================================================================
-- C. THE TEXT SCALE OVERRIDE
-- ================================================================================================================
step(1, function()
    local got = tostring(ISUIElement._zedTextScalePatched) .. "/" .. tostring(ISUIElement._zedBorderPatched) .. "/"
        .. tostring(ISTextEntryBox and ISTextEntryBox._zedEntryPatched) .. "/" .. tostring(LEAN ~= nil)
    check(got == "true/true/true/true", "text scale: the text, border and entry patches are in and ZeD.LeanDraw is published (presence: the flags)", got, "true/true/true/true")
    local T = ZeD.T
    local root = ZeD.Scale.root()
    S.fallback = (X.fallback == true) or (T.fontFallback == true)
    say(string.format("INFO root scale %.3f, T.px(1) = %s, fallback fonts %s", root, tostring(T.px(1)), tostring(S.fallback)))
    for i = 1, 5 do
        local f = T["fontF" .. i]
        local z = X.zoomOf(f)
        if S.fallback then
            check(z == 1, "text scale: with the game's fonts on the roles, F" .. i .. " draws at zoom 1", z, 1)
        else
            local px, face = T.fontPx[f], (T.fontFace[f] or 64)
            local want = px and (px * root / face)
            check(f ~= nil and want ~= nil and math.abs(z - want) < 1e-6 and z ~= 1,
                "text scale: role font F" .. i .. " zooms by its px x the root over its face", z, want)
        end
    end
end)
step(1, function()
    local T = ZeD.T
    local F = T.fontF2
    local VF = vanillaFont()
    S.VF = VF
    if S.fallback then
        skip("text scale: the zoom path of a role font", "the game's own fonts hold the role slots, every role draws at native size")
    else
        local z = X.zoomOf(F)
        local w = X.roleWidth(F, "Hello", z)
        local r = recorder()
        ISUIElement.drawText({ javaObject = r.jo }, "Hello", 10, 20, 1, 1, 1, 1, F)
        local c = r.calls[1]
        check(#r.calls == 1 and c.name == "DrawText" and c.n == 9 and c.a[1] == F and c.a[3] == 10 and c.a[4] == 20 and c.a[5] == z,
            "text scale: drawText of the body role font takes the engine's zoom call at its zoom", sig(r), "DrawText,F2,Hello,10,20," .. tostring(z) .. ",1,1,1,1")
        r = recorder()
        ISUIElement.drawTextRight({ javaObject = r.jo }, "Hello", 100, 20, 1, 1, 1, 1, F)
        c = r.calls[1]
        check(#r.calls == 1 and c.name == "DrawText" and c.n == 9 and math.abs(c.a[3] - (100 - w)) < 1e-6 and c.a[5] == z,
            "text scale: drawTextRight ends the zoomed text at x (x less its zoomed width)", sig(r), "DrawText at x " .. tostring(100 - w))
        r = recorder()
        ISUIElement.drawTextCentre({ javaObject = r.jo }, "Hello", 100, 20, 1, 1, 1, 1, F)
        c = r.calls[1]
        check(#r.calls == 1 and c.name == "DrawText" and c.n == 9 and math.abs(c.a[3] - (100 - w / 2)) < 1e-6 and c.a[5] == z,
            "text scale: drawTextCentre centers the zoomed text on x", sig(r), "DrawText at x " .. tostring(100 - w / 2))
        r = recorder()
        ISUIElement.drawText({ javaObject = r.jo, isCollapsed = true }, "Hello", 10, 20, 1, 1, 1, 1, F)
        check(#r.calls == 0, "text scale: a collapsed element draws no zoomed text (as ISUIElement's own rule)", sig(r), "(no draw)")
    end
    if VF then
        local r = recorder()
        ISUIElement.drawText({ javaObject = r.jo }, "Hello", 10, 20, 1, 1, 1, 1, VF)
        local c = r.calls[1]
        check(#r.calls == 1 and c.name == "DrawText" and c.n == 8 and c.a[1] == VF and c.a[3] == 10 and c.a[5] == 1,
            "text scale: a vanilla font (" .. tostring(VF) .. ") keeps the engine's own call, no zoom", sig(r), "DrawText," .. tostring(VF) .. ",Hello,10,20,1,1,1,1")
        r = recorder()
        ISUIElement.drawTextRight({ javaObject = r.jo }, "Hello", 100, 20, 1, 1, 1, 1, VF)
        c = r.calls[1]
        check(#r.calls == 1 and c.name == "DrawTextRight" and c.n == 8 and c.a[3] == 100,
            "text scale: drawTextRight of a vanilla font is the engine's DrawTextRight, untouched", sig(r), "DrawTextRight," .. tostring(VF) .. ",Hello,100,...")
    else
        skip("text scale: a vanilla font's draw", "no vanilla font at zoom 1 found")
    end
end)
step(1, function()
    local t = ZeD.T.px(1)
    local r1 = recorder()
    ISUIElement.drawRectBorder({ javaObject = r1.jo }, 5, 6, 50, 40, 1, 0.5, 0.5, 0.5)
    local c1, c2 = r1.calls[1], r1.calls[2]
    check(#r1.calls == 4 and c1.a[4] == 1 and c2.a[5] == 1, "text scale: a vanilla element's border stays the engine's one-pixel lines", sig(r1), "4 lines, 1 px")
    local rects, r2 = {}, recorder()
    local el = { javaObject = r2.jo, zedScaled = true, drawRect = function(_, x, y, w, h) rects[#rects + 1] = { x, y, w, h } end }
    ISUIElement.drawRectBorder(el, 5, 6, 50, 40, 1, 0.5, 0.5, 0.5)
    local rs = {}
    for _, q in ipairs(rects) do rs[#rs + 1] = table.concat({ tostring(q[1]), tostring(q[2]), tostring(q[3]), tostring(q[4]) }, ",") end
    if t > 1 then
        local a, b, c, d = rects[1], rects[2], rects[3], rects[4]
        local ok = #rects == 4 and a[1] == 5 and a[2] == 6 and a[3] == 50 and a[4] == t and b[2] == 6 + 40 - t and b[4] == t
            and c[2] == 6 + t and c[3] == t and c[4] == 40 - 2 * t and d[1] == 5 + 50 - t and d[3] == t
        check(ok, "text scale: a ZeD element's border is four rects T.px(1) = " .. tostring(t) .. " px thick", table.concat(rs, " | "),
            "5,6,50," .. t .. " | 5," .. (46 - t) .. ",50," .. t .. " | ...")
    else
        check(#rects == 0 and #r2.calls == 4, "text scale: T.px(1) is 1 at this scale, so a ZeD element's border is the engine's lines too",
            table.concat(rs, " | ") .. " / " .. sig(r2), "4 one-pixel lines")
    end
end)
step(1, function()
    local T = ZeD.T
    local tex = getTexture("media/ui/ZoomIn.png")
    local rgb = { 5, 6, 50, 40, 0.8, 0.1, 0.2, 0.3 }
    local cases = {
        { "drawRect", rgb }, { "drawRectBorder", rgb },
        { "drawText", { "Hello", 10, 20, 0.9, 0.8, 0.7, 1, T.fontF2 } },
        { "drawText", { "Hello", 10, 20, 0.9, 0.8, 0.7, 1, S.VF or UIFont.Small } },
    }
    if tex then
        cases[#cases + 1] = { "drawTextureScaled", { tex, 1, 2, 30, 30, 0.5 } }
        cases[#cases + 1] = { "drawTextureScaled", { tex, 1, 2, 30, 30, 0.5, 0.1, 0.2, 0.3 } }
        cases[#cases + 1] = { "drawTextureScaledAspect", { tex, 1, 2, 30, 30, 0.5 } }
        cases[#cases + 1] = { "drawTextureScaledAspect", { tex, 1, 2, 30, 30, 0.5, 0.1, 0.2, 0.3 } }
    else
        skip("text scale: the lean texture draws", "no texture media/ui/ZoomIn.png")
    end
    for i, cs in ipairs(cases) do
        local rA, rB = recorder(), recorder()
        local elA = { javaObject = rA.jo, zedScaled = true, drawRect = LEAN.drawRect }
        local elB = { javaObject = rB.jo, zedScaled = true, drawRect = LEAN.drawRect }
        ISUIElement[cs[1]](elA, unpack(cs[2]))
        LEAN[cs[1]](elB, unpack(cs[2]))
        check(#rB.calls > 0 and sig(rA) == sig(rB), "text scale: the lean " .. cs[1] .. " (case " .. i .. ") makes exactly ISUIElement's Java calls",
            sig(rB), sig(rA))
    end
end)
step(1, function()
    local unflagged, present = {}, 0
    for _, n in ipairs(ZED_CLASSES) do
        local c = _G[n]
        if type(c) == "table" then
            present = present + 1
            if c.zedScaled ~= true then unflagged[#unflagged + 1] = n end
        end
    end
    check(present > 0 and #unflagged == 0, "text scale: the " .. present .. " listed ZeD classes are flagged for scaled borders (presence: the flag the border draw reads)",
        (#unflagged > 0) and table.concat(unflagged, " ") or (present .. " present"), "none unflagged")
    local nUI, miss = 0, {}
    for k, v in pairs(_G) do
        if type(k) == "string" and type(v) == "table" and string.sub(k, 1, 4) == "ZeD_" then
            local ok, ui = pcall(function() return rawget(v, "Type") == k and isUI(v) end)
            if ok and ui then
                nUI = nUI + 1
                for _, m in ipairs(LEAN_NAMES) do
                    local ok2, same = pcall(function() return v[m] == ISUIElement[m] end)
                    if ok2 and same then miss[#miss + 1] = k .. "." .. m end
                end
            end
        end
    end
    table.sort(miss)
    check(nUI > 0 and #miss == 0, "text scale: every ZeD UI class (" .. nUI .. ") has the lean draw calls or its own, none left on ISUIElement's (presence)",
        (#miss > 0) and table.concat(miss, " ") or "none", "none on ISUIElement's")
    local cw = CWm and CWm.getWindow and CWm.getWindow()
    if cw then
        local got = tostring(cw.zedScaled) .. "/" .. tostring(cw.drawText ~= ISUIElement.drawText) .. "/" .. tostring(cw.drawRectBorder ~= ISUIElement.drawRectBorder)
        check(got == "true/true/true", "text scale: the open Character window carries the scaled-border flag and the lean text and border calls (presence)", got, "true/true/true")
    else
        skip("text scale: the open Character window", "the Character window is not open")
    end
end)
step(1, function()
    local T = ZeD.T
    local F, VF = T.fontF2, S.VF or UIFont.Small
    local s = "Hello world"
    local real = X.realTM()
    local z = X.zoomOf(F)
    if z == 1 then
        skip("text scale: ZeD.TM's zoomed width and line height of a role font", "F2 draws at zoom 1 here (the game's fonts on the roles), so zoomed and plain read the same")
    else
        local zm, want = ZeD.TM:MeasureStringX(F, s), real:MeasureStringX(F, s) * z
        check(math.abs(zm - want) < 0.01, "text scale: ZeD.TM measures a role font zoomed, as it draws", zm, want)
        local fh, fw = ZeD.TM:getFontHeight(F), real:getFontHeight(F) * z
        check(math.abs(fh - fw) < 0.01, "text scale: ZeD.TM's line height of a role font is zoomed", fh, fw)
    end
    local vm, vw = ZeD.TM:MeasureStringX(VF, s), real:MeasureStringX(VF, s)
    check(vm == vw, "text scale: ZeD.TM measures a vanilla font as the engine does", vm, vw)
    check(getTextManager() == ZeD.TM, "text scale: the game's getTextManager() hands vanilla panels the zoomed proxy", tostring(getTextManager()), "ZeD.TM")
    -- Overrides/Tooltip.lua raises F2's px (T.fontPx) while a tooltip lays out and draws, for the game's tooltip
    -- text size option (Medium 1.15, Large 1.3): that only works if the zoom follows T.fontPx
    if S.fallback or not (T.fontPx and T.fontPx[F]) then
        skip("text scale: the tooltip text size option", "no role px registered (fallback fonts)")
    else
        local base, face = T.fontPx[F], (T.fontFace[F] or 64)
        local z0 = X.zoomOf(F)   -- (the kept value first, so this check can never leave a larger one kept)
        S.pxSave = { f = F, v = base }
        local ok, zBig = pcall(function() T.fontPx[F] = base * 1.3; return X.zoomOf(F) end)
        T.fontPx[F] = base
        S.pxSave = nil
        local wantBig = base * 1.3 * ZeD.Scale.root() / face
        check(ok and math.abs(zBig - wantBig) < 1e-6, "text scale: a raised role px (the tooltip's Large text, Overrides/Tooltip.lua) reaches the zoom",
            zBig, wantBig)
        local zAfter = X.zoomOf(F)
        check(zAfter == z0, "text scale: F2's zoom is as it was after the raise", zAfter, z0)
        -- (a zoom kept for the raised px would size every F2 text: the kept zooms start over)
        if zAfter ~= z0 and X._zoom then X._zoom.T = false end
    end
end)
step(4, function()
    -- a ZeD text entry (zedEntry), on screen for a few frames; the game's own placeholder goes in first through
    -- vanilla's setter, so ZeD has one to empty
    local e = ISTextEntryBox:new("", 40, 40, 260, 26)
    e:initialise()
    e:instantiate()
    S.entry = e
    e.zedEntry = true
    e:setPlaceholderText("QA game placeholder")
    S.phGame = tostring(e:getPlaceholderText())
    S.phDrawn = {}
    e.drawText = function(self, s, ...)
        S.phDrawn[#S.phDrawn + 1] = tostring(s)
        return ISUIElement.drawText(self, s, ...)
    end
    X.ownPlaceholder(e, "QA placeholder", nil, 1)
    e:addToUIManager()
end)
step(1, function()
    local e = S.entry
    local f = X.entryFont()
    check(e.font == f and e._zedFont == f, "text scale: a ZeD text entry takes the entry face for this scale", tostring(e.font), tostring(f))
    local ph = e.javaObject:getPlaceholderText()
    check(S.phGame == "QA game placeholder" and ph == "", "text scale: the game's own placeholder of a ZeD entry is emptied",
        tostring(S.phGame) .. " -> " .. tostring(ph), "QA game placeholder -> (empty)")
    local drawn = false
    for _, s in ipairs(S.phDrawn) do if s == "QA placeholder" then drawn = true end end
    check(drawn, "text scale: ZeD draws the entry's placeholder while it is empty and not focused", table.concat(S.phDrawn, "/"), "QA placeholder")
    e:setVisible(false)
    e:removeFromUIManager()
    S.entry = nil
end)

-- ================================================================================================================
-- D. THE INPUT MODE DETECTOR (the stand-in controller on slot 15)
-- ================================================================================================================
step(1, function() Det.setLockedMode("kbm"); S.tSw = getTimestampMs() end)
untilDo(sinceSwitch(450), 2000, function()
    Det.setLockedMode(nil)
    check(Det.getMode() == "kbm", "input mode: locked to mouse and keys, then let go, the detector stays on kbm", Det.getMode(), "kbm")
    ctlStub(true)
    local th = stickTh()
    S.fc.ax[0], S.fc.ax[1] = th * 0.6, th * 0.6   -- (|0.6, 0.6| x the threshold = 0.85 of it)
    S.fc.reads[0] = 0
end, 10)
step(0, function()
    local rd = S.fc.reads[0] or 0
    check(Det.getMode() == "kbm" and rd > 0, "input mode: a stick inside the dead zone (0.85 of it, both axes; read " .. rd
        .. " times in auto mode, past the cooldown) leaves mouse and keys", Det.getMode() .. ", read " .. rd, "kbm, read > 0")
    S.nEv = #S.events
    S.fc.ax[0], S.fc.ax[1] = math.min(0.9, stickTh() * 2.5), 0
end)
untilDo(function() return Det.getMode() == "gamepad" end, 1500, function(ok)
    check(ok, "input mode: a stick past the dead zone switches to the pad", Det.getMode(), "gamepad")
    check(#S.events > S.nEv and lastEv() == "gamepad,kbm", "input mode: ZeD_InputModeChanged fires (gamepad, kbm)", lastEv(), "gamepad,kbm")
    S.padOn = ok
    S.tSw = getTimestampMs()
    if ok and S.freeKey then triggerEvent("OnKeyPressed", S.freeKey) end   -- (inside the cooldown)
end, 0)
step(0, function()
    -- (the detector read the key on this tick, before this step: the time it saw since the switch is at most this)
    if not S.freeKey then
        skip("input mode: the four key checks (inside and after the cooldown, a stick and a key on one tick, a key on a locked mode)", "no unbound key to press")
    elseif not S.padOn then
        skip("input mode: the three key checks on the pad (inside and after the cooldown, a stick and a key on one tick)", "the stick never put the detector on the pad")
    else
        local took = getTimestampMs() - S.tSw
        if took >= cooldown() then
            skip("input mode: a key inside the cooldown", "the game took " .. took .. " ms to its next tick, past the " .. cooldown() .. " ms cooldown")
        else
            check(Det.getMode() == "gamepad", "input mode: a key " .. took .. " ms after the switch, inside the " .. cooldown()
                .. " ms cooldown, does not switch back", Det.getMode(), "gamepad")
        end
    end
    S.fc.ax[0], S.fc.ax[1] = 0, 0
end)
untilDo(sinceSwitch(cooldown() + 250), 3000, function()
    S.nEv = #S.events
    if not (S.freeKey and S.padOn) then return end   -- (said above)
    if Det.getMode() ~= "gamepad" then
        skip("input mode: a key after the cooldown switches back, and its event", "the detector was not on the pad before the key")
        return
    end
    S.keyBack = true
    triggerEvent("OnKeyPressed", S.freeKey)
end, 2)
step(0, function()
    if S.keyBack then
        check(#S.events > S.nEv and Det.getMode() == "kbm", "input mode: a key after the cooldown switches back to mouse and keys", Det.getMode(), "kbm")
        check(#S.events > S.nEv and lastEv() == "kbm,gamepad", "input mode: ZeD_InputModeChanged fires (kbm, gamepad)", lastEv(), "kbm,gamepad")
    end
    S.keyBack = nil
    S.tSw = getTimestampMs()
end)
untilDo(sinceSwitch(cooldown() + 250), 3000, function()
    if not (S.freeKey and S.padOn) then return end   -- (said above)
    if Det.getMode() ~= "kbm" then
        skip("input mode: a stick and a key on the same tick", "the detector was not on mouse and keys before it")
        return
    end
    S.stickKey = true
    S.fc.reads[0] = 0
    S.fc.ax[0] = 0.9
    triggerEvent("OnKeyPressed", S.freeKey)   -- (the stick and a key for the detector's next tick)
end, 0)
step(0, function()
    if S.stickKey then
        local rd = S.fc.reads[0] or 0
        check(Det.getMode() == "kbm" and rd > 0, "input mode: a stick and a key on the same tick (the stick read " .. rd
            .. " times), the key (the newer event) wins", Det.getMode() .. ", read " .. rd, "kbm, read > 0")
    end
    S.stickKey = nil
    S.fc.ax[0] = 0
end)
-- the trigger, from mouse and keys in auto mode: a run the stick left on the pad (no key) gets there through the lock,
-- let go once the detector has switched; the trigger then sits a cooldown after that switch, so a misread would switch
untilDo(sinceSwitch(cooldown() + 250), 3000, function()
    S.fc.ax[0], S.fc.ax[1] = 0, 0
    S.nEv = #S.events
    if Det.getMode() ~= "kbm" then Det.setLockedMode("kbm"); S.trigLock = true end
end, 0)
untilDo(function() return not S.trigLock or (#S.events > S.nEv and S.events[#S.events].new == "kbm") end, 1500, function(ok)
    if not S.trigLock then return end
    Det.setLockedMode(nil)
    S.trigLock = nil
    S.tSw = getTimestampMs()
    if not ok then say("INFO the lock to mouse and keys did not switch the detector in 1.5 s") end
end, 0)
untilDo(sinceSwitch(cooldown() + 250), 3000, function()
    S.fc.reads[4] = 0
    S.fc.ax[4] = trigTh() * 0.6
end, 10)
step(0, function()
    local rd = S.fc.reads[4] or 0
    check(Det.getMode() == "kbm" and rd > 0, "input mode: a trigger at 0.6 of its threshold (read " .. rd
        .. " times in auto mode, past the cooldown) leaves mouse and keys", Det.getMode() .. ", read " .. rd, "kbm, read > 0")
    S.fc.ax[4] = math.min(0.9, trigTh() * 3)
end)
untilDo(function() return Det.getMode() == "gamepad" end, 1500, function(ok)
    check(ok, "input mode: a trigger pulled past its threshold switches to the pad", Det.getMode(), "gamepad")
    S.tSw = getTimestampMs()
    S.fc.ax[4] = 0
end, 1)
untilDo(sinceSwitch(cooldown() + 250), 3000, function()
    local what = "input mode: a pad unplugged with none left goes back to mouse and keys"
    local vc = JoypadState and JoypadState.controllers and JoypadState.controllers[FC]
    if Det.getMode() ~= "gamepad" then skip(what, "not on the pad before it"); return end
    if not vc or vc.connected == true then skip(what, "the game's slot " .. FC .. " is missing or holds a real pad"); return end
    -- (OnGamepadDisconnect reaches every listener: vanilla's main menu hand-back and options screen as well as the
    -- detector; with no real pad connected or joined they have nothing to change, so only then)
    local pads, joined = realPads()
    local MSi = MainScreen and MainScreen.instance
    if pads > 0 or joined or (MSi and MSi.termsOfService) then
        local why = (pads > 0) and (pads .. " real pad(s) connected") or (joined and "a pad is joined" or "the main menu's terms are up")
        skip(what, why .. ": the unplug would reach the game's own pad handlers")
        return
    end
    S.unplug = { v = vc.connected, test = JoypadState.controllerTest, ms = MSi, focus = MSi and MSi.joyfocus }
    S.fc.none = true   -- (no controller left anywhere)
    local ok, e = pcall(triggerEvent, "OnGamepadDisconnect", FC)
    unplugBack()
    check(ok and Det.getMode() == "kbm", what, ok and Det.getMode() or tostring(e), "kbm")
    S.tSw = getTimestampMs()
end, 1)
step(1, function()
    local names = { { "Xbox Wireless Controller", "xbox" }, { "DualSense Wireless Controller", "playstation" },
                    { "Nintendo Switch Pro Controller", "nintendo" }, { "Generic USB Joystick", "unknown" } }
    for _, nm in ipairs(names) do
        S.fc.name = nm[1]
        local got = Det.getControllerType(FC)
        check(got == nm[2], "input mode: a pad named \"" .. nm[1] .. "\" reads as " .. nm[2], got, nm[2])
    end
    S.fc.connected = false
    local got = Det.getControllerType(FC)
    check(got == "unknown", "input mode: an empty slot reads as unknown", got, "unknown")
    ctlStub(false)
end)
-- the lock (ZeD setup's input mode choice), from mouse and keys so it has a switch to make
step(0, function()
    local e = S.events[#S.events]
    if e and e.new ~= "kbm" then Det.setLockedMode("kbm"); S.tSw = getTimestampMs() end
end)
untilDo(sinceSwitch(cooldown() + 250), 3000, function()
    S.nEv = #S.events
    Det.setLockedMode("gamepad")
    check(Det.getMode() == "gamepad", "input mode: a lock to the pad answers at once", Det.getMode(), "gamepad")
end, 0)
untilDo(function() return #S.events > S.nEv and S.events[#S.events].new == "gamepad" end, 1500, function(ok)
    check(ok, "input mode: the lock switches the detector and tells the listeners (gamepad)", lastEv(), "gamepad,kbm")
    Det.setLockedMode("joystick")   -- (not a mode: ignored with a warning)
    check(Det.getMode() == "gamepad", "input mode: a lock value that is not a mode is ignored", Det.getMode(), "gamepad")
    S.nEv = #S.events
    if S.freeKey then triggerEvent("OnKeyPressed", S.freeKey) end
end, 3)
step(0, function()
    if S.freeKey then
        check(Det.getMode() == "gamepad" and #S.events == S.nEv, "input mode: a key press does not move a locked mode",
            Det.getMode() .. ", " .. (#S.events - S.nEv) .. " events", "gamepad, 0 events")
    end
end)

-- ================================================================================================================
-- E. THE PAD PATH: a window's onJoypadDown, as the engine calls it, through the action map
-- ================================================================================================================
step(2, function()
    local cw, ww = CWm.getWindow(), WWm.getWindow()
    if not (cw and ww and cw:isVisible() and ww:isVisible()) then
        S.noWin = true
        skip("pad path", "the window pair is not open")
        return
    end
    Focus.claimFocus(cw)
end)
step(2, function()
    if S.noWin then return end
    local cw = CWm.getWindow()
    if Focus.getFocusedWindow() ~= cw then say("INFO the Character window did not take the pad: " .. label(Focus.getFocusedWindow())) end
    cw:onJoypadDown(Joypad.RBumper, nil)
end)
step(2, function()
    if S.noWin then return end
    local ww = WWm.getWindow()
    check(Focus.getFocusedWindow() == ww, "pad path: RB on the focused Character window moves the pad to the World window (window_next)",
        label(Focus.getFocusedWindow()), "World")
    shot("pad_world")
    ww:onJoypadDown(Joypad.LBumper, nil)
end)
step(2, function()
    if S.noWin then return end
    local cw, ww = CWm.getWindow(), WWm.getWindow()
    check(Focus.getFocusedWindow() == cw, "pad path: LB moves it back to the Character window (window_prev)", label(Focus.getFocusedWindow()), "Character")
    ww:onJoypadDown(Joypad.RBumper, nil)   -- (the World window does not hold the pad)
end)
step(1, function()
    if S.noWin then return end
    local cw = CWm.getWindow()
    check(Focus.getFocusedWindow() == cw, "pad path: a press on the window that does not hold the pad does nothing", label(Focus.getFocusedWindow()), "Character")
    local cnt = cw._mainContent
    if not cnt then skip("pad path: L3", "no list in the Character window"); return end
    local el = Focus.getFocusedElement(cw)
    local cs = (el and el.colIdx and cnt._colStates and cnt._colStates[el.colIdx]) or nil
    -- (padSort also sends that list's scroll to the top: kept to put back with the sort)
    local sb = (cs and cs.scroll) or cnt._scroll
    S.sortSave = { cnt = cnt, cs = cs, col = cnt._sortCol, asc = cnt._sortAsc, cscol = cs and cs.sortCol, csasc = cs and cs.sortAsc,
                   sb = sb, pos = sb and sb.scrollPos }
    local before = (cs and cs.sortCol) or cnt._sortCol or "name"
    cw:onJoypadDown(Joypad.LStickButton, nil)
    local after = (cs and cs.sortCol) or cnt._sortCol or "name"
    check(after ~= before, "pad path: L3 steps the list's sort (list_sort)", tostring(before) .. " -> " .. tostring(after), "the next column")
    restoreSort()
end)

-- ================================================================================================================
-- F. THE BUMPER ZOOM CHORD (the stand-in bumpers; the detector locked to the pad)
-- ================================================================================================================
step(4, function()
    padStub(true)
    if Focus.getFocusedWindow() == nil and CWm.getWindow() then Focus.claimFocus(CWm.getWindow()) end
    S.lb = true
end)
step(2, function()
    if Focus.getFocusedWindow() then
        check(Chord.getState() == "IDLE", "bumper zoom: with a window holding the pad, LB held is not the chord's (FocusManager turned it off)",
            Chord.getState(), "IDLE")
    else
        skip("bumper zoom: the focused-window gate", "no window took the pad")
    end
    S.lb = false
end)
step(2, function()
    Focus.releaseFocus()
    local c = getCore()
    S.zoomOk = c:isZoomEnabled() and not c:getAutoZoom(0) and c:getNextZoom(0, 1) ~= c:getNextZoom(0, -1)
    if S.zoomOk then
        -- room for two steps in: at least two levels under the target
        local n = 0
        while c:getNextZoom(0, -1) <= c:getMinZoom() and n < 3 do c:doZoomScroll(0, 1); n = n + 1 end
    else
        say("INFO the zoom level cannot move here (zoom off, auto zoom, or between levels): the zoom checks cannot be made")
    end
end)
step(3, function() S.z = zl(); S.lb = true end)
step(0, function()
    check(Focus.getFocusedWindow() == nil and Chord.getState() == "LB_HELD" and Chord.isActive(),
        "bumper zoom: with the pad released, LB held arms the chord (LB_HELD, active)", label(Focus.getFocusedWindow()) .. " " .. tostring(Chord.getState()), "none LB_HELD")
    S.rb = true
end)
step(2, function() end)
step(0, function()
    check(Chord.getState() == "CONSUMED", "bumper zoom: hold LB, tap RB fires the chord (CONSUMED)", Chord.getState(), "CONSUMED")
    zoomCheck("in", "bumper zoom: hold LB, tap RB zooms in one level")
    S.rb = false
end)
step(2, function() end)
step(2, function() S.rb = true end)   -- (LB still held: a second tap)
step(0, function()
    check(Chord.getState() == "CONSUMED", "bumper zoom: a second RB tap with LB held stays in the chord", Chord.getState(), "CONSUMED")
    zoomCheck("in", "bumper zoom: each further RB tap with LB held zooms in one more")
    S.lb, S.rb = false, false
end)
step(2, function() end)
step(45, function()
    check(Chord.getState() == "IDLE" and not Chord.isActive(), "bumper zoom: both let go, the chord is idle again", Chord.getState(), "IDLE")
end)
step(3, function() shot("zoomed_in"); S.z = zl(); S.rb = true end)
step(0, function()
    check(Chord.getState() == "RB_HELD", "bumper zoom: RB held arms the chord the other way (RB_HELD)", Chord.getState(), "RB_HELD")
    S.lb = true
end)
step(2, function() end)
step(0, function()
    check(Chord.getState() == "CONSUMED", "bumper zoom: hold RB, tap LB fires the chord", Chord.getState(), "CONSUMED")
    zoomCheck("out", "bumper zoom: hold RB, tap LB zooms out one level")
    S.lb, S.rb = false, false
end)
step(2, function() end)
step(3, function()
    check(Chord.getState() == "IDLE", "bumper zoom: let go, idle again", Chord.getState(), "IDLE")
    S.z = zl()
    S.lb = true
end)
step(0, function()
    check(Chord.getState() == "LB_HELD", "bumper zoom: LB alone arms the chord", Chord.getState(), "LB_HELD")
    S.lb = false
end)
step(2, function() end)
step(0, function()
    check(Chord.getState() == "IDLE", "bumper zoom: LB tapped alone and let go does nothing (back to IDLE)", Chord.getState(), "IDLE")
    zoomCheck("none", "bumper zoom: a bumper alone leaves the zoom")
    S.z = zl()
    S.lb, S.rb = true, true
end)
step(2, function() end)
step(0, function()
    check(Chord.getState() == "CONSUMED", "bumper zoom: both bumpers on one tick fire the chord (LB counts first)", Chord.getState(), "CONSUMED")
    zoomCheck("in", "bumper zoom: both bumpers on one tick zoom in")
    S.lb, S.rb = false, false
end)
step(2, function() end)
step(3, function()
    check(Chord.getState() == "IDLE", "bumper zoom: let go after both, idle again", Chord.getState(), "IDLE")
    S.lb = true
end)
step(0, function()
    local was = Chord.getState()
    Chord.setEnabled(false)
    local now = Chord.getState()
    check(was == "LB_HELD" and now == "IDLE", "bumper zoom: setEnabled(false) mid-chord drops it to IDLE", tostring(was) .. " -> " .. tostring(now), "LB_HELD -> IDLE")
    S.z = zl()
    S.rb = true
end)
step(3, function() end)
step(0, function()
    check(Chord.getState() == "IDLE", "bumper zoom: turned off, an RB tap with LB held does nothing", Chord.getState(), "IDLE")
    zoomCheck("none", "bumper zoom: turned off, the zoom stays")
    S.lb, S.rb = false, false
end)
step(2, function() end)
step(2, function() Chord.setEnabled(true) end)
step(0, function() S.jd = nil; S.lb = true end)   -- (no pad on player 1's slot)
step(3, function() end)
step(0, function()
    check(Chord.getState() == "IDLE", "bumper zoom: with no pad on player 1's slot the bumpers are not read", Chord.getState(), "IDLE")
    S.lb = false
    S.jd = { id = 0 }
end)
step(2, function() end)
step(3, function() S.lb = true end)
step(0, function()
    check(Chord.getState() == "LB_HELD", "bumper zoom: the pad back, LB held arms the chord again", Chord.getState(), "LB_HELD")
    S.nEv = #S.events
    Det.setLockedMode("kbm")
end)
untilDo(function() return #S.events > S.nEv and S.events[#S.events].new == "kbm" end, 1500, function(ok)
    check(ok and Chord.getState() == "IDLE", "bumper zoom: a switch to mouse and keys mid-chord drops it to IDLE", lastEv() .. " " .. tostring(Chord.getState()), "kbm,gamepad IDLE")
    S.rb = true
end, 3)
step(0, function()
    check(Chord.getState() == "IDLE", "bumper zoom: on mouse and keys the bumpers are not read", Chord.getState(), "IDLE")
    padStub(false)
end)
step(1, function() cleanup() end)

-- ================================================================================================================
-- PUT EVERYTHING BACK
-- ================================================================================================================
local function try(what, fn)
    local ok, e = pcall(fn)
    if not ok then say("ERR putting back " .. what .. ": " .. tostring(e)) end
end
-- the last of it, once the detector is on the mode it should be on (cleanup waits for that switch): the lock as
-- ZeD setup has it, then the windows (closing one hands its pad focus on), then the pad focus, the chord, the speed
finish = function()
    if S.finished then return end
    S.finished = true
    try("the input lock", function() Det.setLockedMode(S.lock0) end)
    try("the Character window", function() putWindow("Character", CWm, S.cw0, function() CWm.toggle(0) end) end)
    try("the World window", function() putWindow("World", WWm, S.ww0, function() WWm.close(0) end) end)
    try("the pad focus", function()
        local f0 = S.focus0
        if f0 and Focus.isRegistered and Focus.isRegistered(f0) then
            if Focus.getFocusedWindow() ~= f0 then Focus.claimFocus(f0) end
        elseif Focus.getFocusedWindow() then Focus.releaseFocus() end
    end)
    try("the chord", function() Chord.setEnabled(Focus.getFocusedWindow() == nil) end)
    try("the mode listener", function() Events.ZeD_InputModeChanged.Remove(onMode) end)
    try("the game speed", function()
        if S.speed0 ~= nil and S.speed0 <= 0 and getGameSpeed() > 0 then setGameSpeed(S.speed0); say("INFO put back: the game paused again, as found") end
    end)
    ZEDQA_CIN_ORIG = nil
    say(string.format("RESULT %d pass, %d fail (%d of them checks that could not run)", npass, nfail, nskip))
    say("DONE")
end
cleanup = function()
    if S.cleaning then finish(); return end
    S.cleaning = true
    try("the stand-ins", function() unstub("the clean-up") end)
    try("the furniture cursor and pointer", function() furCursorDown(); furHoverDown(); S.fur = nil end)
    try("the unplug's marks", unplugBack)
    try("the probe action", function()
        if S.probe then ZeD.Input.Actions.__qa_probe = nil; S.probe = nil end
        Act.rebuild()
    end)
    try("the test entry", function()
        if S.entry then S.entry:setVisible(false); S.entry:removeFromUIManager(); S.entry = nil end
    end)
    try("the sort", restoreSort)
    try("the role px", function()
        if S.pxSave then
            ZeD.T.fontPx[S.pxSave.f] = S.pxSave.v
            S.pxSave = nil
            if X._zoom then X._zoom.T = false end   -- (the kept zooms start over)
        end
    end)
    try("the zoom", restoreZoom)
    -- the mode: the detector through the mode the lock gives (or, with ZeD setup on auto, the mode the run found:
    -- kbm when it found none), so auto starts from it; the lock itself goes back once the detector has switched
    S.modeTarget = S.lock0 or ((S.mode0 == "gamepad") and "gamepad" or "kbm")
    try("the input mode", function() Det.setLockedMode(S.modeTarget) end)
    Q, qi, waitT = {}, 0, 0
    untilDo(function()
        local e = S.events[#S.events]
        return ((e and e.new) or S.mode0) == S.modeTarget
    end, 1500, function(ok)
        if not ok then say("INFO the detector did not come to " .. tostring(S.modeTarget) .. " in 1.5 s") end
        finish()
    end, 0)
end

local function drive()
    if S.finished then Events.OnTick.Remove(drive); return end
    if waitT > 0 then waitT = waitT - 1; return end
    local s = Q[qi + 1]
    if not s then return end
    local ok, v = true, true
    if s.cond then
        s.t0 = s.t0 or getTimestampMs()
        ok, v = pcall(s.cond)
        if ok and not v and getTimestampMs() - s.t0 < s.ms then return end
    end
    qi = qi + 1
    local ok2, e = false, v
    if ok then ok2, e = pcall(s.fn, v and true or false) end
    if not ok2 then
        nfail = nfail + 1
        say("ERR step " .. qi .. ": " .. tostring(e))
        cleanup()
        return
    end
    waitT = s.n or 0
end

-- START ------------------------------------------------------------------------------------------------------------
local okStart, whyNot = pcall(function()
    if not (ZeD and Det and Chord and Act and Focus and X and LEAN and CWm and WWm) then error("ZeD's input or text modules are not loaded") end
    local save = tostring(getWorld():getWorld())
    if save ~= "ZeD-QA" then error("not the ZeD-QA save (" .. save .. "): nothing was touched") end
    S.speed0 = getGameSpeed()
    if S.speed0 <= 0 then setGameSpeed(1) end   -- (ticks drive the run; paused again at the end)
    S.focus0 = Focus.getFocusedWindow()
    S.cw0, S.ww0 = winState(CWm), winState(WWm)
    S.z0 = zl()
    S.mode0, S.lock0 = Det.getMode(), settingLock()
    Events.ZeD_InputModeChanged.Add(onMode)
end)
if okStart then
    Events.OnRenderTick.Add(watch)
    Events.OnTick.Add(drive)
    say(string.format("start: mode %s, chord %s, pad on %s, Character window %s, World window %s, zoom target between %.2f and %.2f, lock in ZeD setup %s",
        tostring(S.mode0), tostring(Chord.getState()), label(S.focus0), winText(S.cw0), winText(S.ww0), S.z0.dn, S.z0.up, tostring(S.lock0 or "auto")))
else
    if S.speed0 ~= nil and S.speed0 <= 0 then pcall(setGameSpeed, S.speed0) end
    ZEDQA_CIN_ORIG = nil
    say("ERR " .. tostring(whyNot))
    say("DONE")
end
