-- ZeD-UI/42/media/lua/client/ZeD/ZeD_WheelGesture.lua
-- ============================================================================
-- HOW THE WHEELS ARE WORKED (punch list 91; ZeDUI/RADIAL_WHEELS_SPEC.md, which
-- changes how the wheels of DPAD_WHEELS_SPEC.md are worked, not what is on them)
--
-- Tap a D-pad direction (or Select) and the wheel stays up on its own. The left
-- stick keeps walking. The right stick's angle highlights a slice past the
-- engage radius; when it drops under the release radius the slice highlighted
-- on the last frame above it fires. The same direction or B cancels, another
-- direction swaps, a wheel nobody points at closes by itself. Three other ways
-- of working it come from ZeD setup: Hold (today's: up while the direction is
-- held), Stick click (R3 fires) and Toggle mode (the stick or the D-pad moves
-- the highlight, A takes, no timer).
--
-- One table per player in D.state; the slices stay ZeD_DpadWheels'. Polled on
-- OnRenderTick, the event the game's own pad code runs on: OnTick stops while
-- paused, and Here and now and ZeD open while paused; a UI element's update()
-- runs only every 100 ms, too slow to catch a flick.
--
-- WHAT THE GAME DOES WITH A WHEEL UP (read from the 42.22 code, Nov 5 2026):
--   * The pad focus (joypadData.focus) is Lua's. Java hears of it through one
--     place, updateJoypadFocus (JoyPadSetup): setPlayerButtonsActive false while
--     anything has the focus, setJoypadIgnoreAim from the focus's ignoreAim
--     (ISRadialMenu sets it).
--   * Walking does not read either. IsoPlayer.updateMovementFromInput stops only
--     on TutorialManager.stealControl, setBlockMovement (the world map and the
--     on-screen keyboard), a body being carried, a fall. The rest is
--     CharacterInputComponent.getInputMoveVector, which asks for the Movement
--     axis and is gated by nothing but setIgnoreInputsForDirection (the
--     Tutorial's) and the stick's own dead zone; the car reads
--     JoypadManager directly. Running (Run: the left stick past 0.975) has the
--     same one gate. So a wheel holding the pad leaves the left stick walking
--     and running, and the triggers driving. Sprint (R3) does go quiet: it is
--     one of the buttons setPlayerButtonsActive mutes.
--   * So the wheel keeps the pad focus, as the game's wheels do: that is what
--     gives "A, X and Y do nothing and don't reach the game" at both ends. Lua
--     sends every press to the focus's onJoypadDown (onPressButton), and Java's
--     polled buttons (Interact on A, Crouch, Reload, Rack, Cancel) are muted.
--     With no focus the same press goes to onPressButtonNoFocus: the prompts,
--     the Select wheel, the stick-click wheel.
--   * A paused game drops a press that has a focus unless
--     joypadData.activeWhilePaused is set (onPressButton); a release is never
--     dropped. Paused wheels set it, and every close puts it back.
--   * The D-pad and Select are buttons too: onJoypadDown gets their press once.
--     The D-pad's onPressLeft and the rest also fire, first, and repeat while
--     held (every 300 ms, then faster): a held direction must not open a wheel
--     again once this one has closed (freshPress).
--   * The triggers are not buttons: Java polls them. Melee (LT) is gated by
--     nothing. PrecisionAim and Attack (RT) need isJoypadIgnoreAim and
--     isJoypadIgnoreAimUntilCentered both off, so a wheel up holds them back and
--     closing it lets the same held press through on the next frame. The Aim
--     binding is the right stick itself, so it can't count as aiming with a
--     wheel up. The triggers are read through the game's bindings, so a preset
--     that moves them moves them here too.
--   * addToUIManager only queues the wheel. It joins the UI list on the game's
--     next update, and until then isReallyVisible is false; the press and this
--     file's tick are one OnRenderTick, so a wheel just opened reads as not on
--     the screen. removeFromUIManager is queued the same way: gone, it still
--     reads as visible for the rest of the frame.
--
-- Commit reads the latch, never the stick: on the release frame the stick is
-- springing through the center and its angle is noise. The latch is also what
-- ZeD.Wheel draws (menu._zedPoint), so what the player sees is what fires.
-- ============================================================================

require "ZeD/ZeD_Wheel"

ZeD = ZeD or {}
ZeD.DpadWheels = ZeD.DpadWheels or {}
ZeD.WheelGesture = ZeD.WheelGesture or {}
local D, G, W = ZeD.DpadWheels, ZeD.WheelGesture, ZeD.Wheel

-- the feel, in one table, live: ZeD.DpadWheels.tune.SECTOR_HYST_DEG = 10 and the next frame has it.
-- ENGAGE_RADIUS and RELEASE_RADIUS start false: they come from the setting (Wheel stick dead zone,
-- 0.35 unless changed; release is 60% of it). A number here wins over the setting.
D.tune = D.tune or {
    ENGAGE_RADIUS = false,      -- stick magnitude above which a slice highlights
    RELEASE_RADIUS = false,     -- magnitude below which the highlighted slice fires
    SECTOR_HYST_DEG = 7,        -- degrees past a boundary before the highlight moves; never over a quarter of a slice
    DISMISS_TIMEOUT_S = 3.0,    -- nothing pointed at for this long: the wheel closes
    OPEN_DEBOUNCE_MS = 150,     -- a second tap this soon after opening is ignored
    FAR_HOLD_MS = 60,           -- the highlight crosses to the far side of the wheel only if the stick stays there this long
    REST_MS = 150,              -- a stick sitting under engage this long counts as centered (a drifting pad)
}
local RELEASE_SHARE = 0.60

G.live = G.live or {}       -- pn -> the state table the tick last saw (a state dropped any other way is still finished)
G.qa = G.qa or {}           -- pn -> { x, y }: a stick with no pad (D.qaStick)
G.qaTrig = G.qaTrig or {}   -- pn -> true / false: the triggers with no pad (D.qaTrigger)

-- ---------------------------------------------------------------------------
-- the settings (ZeD setup, Controls)
-- ---------------------------------------------------------------------------
-- how a wheel opened now is worked: "tap" / "hold" / "toggle", then "flick" / "click" / "button"
function G.modeOf()
    local q, S = D.qaSettings, ZeD.Settings
    local toggle
    if q and q.toggle ~= nil then toggle = q.toggle else toggle = S and S.wheelToggle and S.wheelToggle() end
    if toggle then return "toggle", "button" end
    local open = (q and q.open) or (S and S.wheelOpen and S.wheelOpen()) or "tap"
    local commit = (q and q.commit) or (S and S.wheelCommit and S.wheelCommit()) or "flick"
    return open, commit
end

-- engage and release, read every frame so the dead zone is live
function G.radii()
    local t, q, S = D.tune, D.qaSettings, ZeD.Settings
    local zone = (q and q.deadZone) or (S and S.wheelDeadZone and S.wheelDeadZone()) or 0.35
    local engage = t.ENGAGE_RADIUS or zone
    local release = t.RELEASE_RADIUS or (engage * RELEASE_SHARE)
    return engage, math.min(release, engage)
end

-- ---------------------------------------------------------------------------
-- starting, levels and ending
-- ---------------------------------------------------------------------------
-- a wheel opened (D.open): how it is worked, once per open
function G.begin(pn, st, menu)
    if G.live[pn] then G.finish(pn, G.live[pn]) end
    G.live[pn] = st
    local mode, commit = G.modeOf()
    -- a mod's own wheel class draws itself and has none of this: the game's way, up while held
    local cls = getmetatable(menu)
    if cls ~= ISRadialMenu and cls ~= ISBackButtonWheel then mode = "hold" end
    st.mode, st.commit = mode, commit
    st.held = (mode == "hold")
    st.openedAt = getTimestampMs()
    st.lastActive = st.openedAt
    -- a stick already over (aiming when the D-pad was tapped) has to come back first. Hold with Flick-release
    -- too: a slice lit on the first frame would fire as that stick went home, with nobody choosing it. Hold with
    -- Stick click is today's: the stick can be out before the wheel is up.
    st.needCenter = (not st.held) or commit == "flick"
    st.restSince = 0       -- (no flick to spring back from yet: a stick under engage at the open is already home)
    local jd = JoypadState.players[pn + 1]
    if jd then
        st.pad = true
        st.pausedWas = jd.activeWhilePaused
        jd.activeWhilePaused = true
    end
    st.trigHeld = G.trigger(pn, jd)   -- (a trigger already down, aiming or driving, is no new press)
end

-- a new ring on the wheel (in or out one level): nothing pointed, the stick back to the center first
function G.level(st)
    st.latch, st.engaged = nil, false
    st.needCenter = true
    st.farSince, st.restSince = nil, nil
    st.seen = nil          -- (the ring may be going back through the UI queue)
    st.lastActive = getTimestampMs()
end

-- the state is over, however it went: the shipped map back. Safe to call twice.
function G.finish(pn, st)
    if not st or st.done then return end
    st.done = true
    if D.state[pn] == st then D.state[pn] = nil end
    if G.live[pn] == st then G.live[pn] = nil end
    local menu = st.menu
    local jd = JoypadState.players[pn + 1]
    if jd and st.pad then jd.activeWhilePaused = st.pausedWas end
    -- (undisplay clears the focus through menu.joyfocus, which the game sets a frame late)
    if jd and menu and jd.focus == menu and not menu:isReallyVisible() then setJoypadFocus(pn, nil) end
    -- (a wheel that gets the pad back later, from a window's setPrevFocusForPlayer or the like, is a plain
    -- wheel, the game's own B and X close it; a dead state on it would take its buttons and do nothing)
    if menu and menu._zedDpad == st then menu._zedDpad = nil end
    if jd and menu and jd.prevfocus == menu then jd.prevfocus = nil end
    -- (setJoypadIgnoreAimUntilCentered stays as the wheel set it: the game clears it itself once the
    -- stick is centered, which is what keeps a flick from turning into a swing. G.attack clears it at once.)
end

-- the stick and the triggers: the wheel's own reading of the pad
function G.stick(pn, jd)
    local q = G.qa[pn]
    if q then return q.x, q.y end
    local id = jd and jd.id
    if not id or id < 0 then return nil end
    return getJoypadAimingAxisX(id), getJoypadAimingAxisY(id)
end

local function bindingDown(id)
    local B = CharacterJoypadButtonBinding
    -- (the game's Original preset puts PrecisionAim on the right stick: that is the pointer, not an aim)
    local aim = B.PrecisionAim:getJoypadAxis2d() == nil and B.PrecisionAim:isDown(id)
    return aim or B.Attack:isDown(id) or B.Melee:isDown(id)
end

function G.trigger(pn, jd)
    local q = G.qaTrig[pn]
    if q ~= nil then return q end
    local id = jd and jd.id
    if not id or id < 0 then return false end
    local ok, down = pcall(bindingDown, id)
    if ok then return down end
    return isJoypadRTPressed(id) or isJoypadLTPressed(id)
end

-- ---------------------------------------------------------------------------
-- which slice: slice 1 centered at 12 o'clock, clockwise, 360 / slices each
-- (ZeD.Wheel's geometry). The last slice keeps the highlight until the stick is
-- past its boundary by the hysteresis. -1: nothing there.
-- ---------------------------------------------------------------------------
local function clock(ax, ay)
    -- clockwise from 12 o'clock, 0 to 360 (the 360 first: Kahlua's % keeps the sign)
    return (math.deg(math.atan2(ay, ax)) + 90 + 360) % 360
end

-- degrees from the angle a to the middle of slice i
local function awayFrom(i, a, width)
    local off = math.abs(a - (i - 1) * width)
    if off > 180 then off = 360 - off end
    return off
end

function G.sector(menu, st, ax, ay)
    local slices = menu.slices or {}
    local n = #slices
    if n == 0 then return -1 end
    local width = 360 / math.max(n, 2)
    local hyst = math.min(D.tune.SECTOR_HYST_DEG or 0, width / 4)
    local a = clock(ax, ay)
    local last = st.latch
    if last and last >= 1 and last <= n then
        if awayFrom(last, a, width) <= width / 2 + hyst then return last end
    end
    local i = math.floor(((a + width / 2) % 360) / width) + 1
    if i > n or W.isPlace(slices[i]) then return -1 end
    return i
end

-- Toggle mode: the D-pad walks the ring toward the side pressed, one slice a press (a tie goes clockwise,
-- so every slice can be reached). Nothing highlighted yet: the slice furthest that way.
local PRESS = { left = { -1, 0 }, right = { 1, 0 }, up = { 0, -1 }, down = { 0, 1 } }
function G.move(st, menu, dir)
    local slices = menu.slices or {}
    local n = #slices
    local v = PRESS[dir]
    if n == 0 or not v then return end
    local step = 360 / math.max(n, 2)
    local function reach(i)
        local a = math.rad(-90 + (i - 1) * step)
        return math.cos(a) * v[1] + math.sin(a) * v[2]
    end
    local pick
    if st.latch then
        local cw, ccw = st.latch, st.latch
        for _ = 1, n do
            cw = (cw % n) + 1
            if not W.isPlace(slices[cw]) then break end
        end
        for _ = 1, n do
            ccw = ((ccw - 2 + n) % n) + 1
            if not W.isPlace(slices[ccw]) then break end
        end
        pick = (reach(ccw) > reach(cw) + 0.001) and ccw or cw
    else
        for i = 1, n do
            if not W.isPlace(slices[i]) and (not pick or reach(i) > reach(pick) + 0.001) then pick = i end
        end
    end
    if pick and not W.isPlace(slices[pick]) then
        st.latch = pick
        menu._zedPoint = pick
    end
end

-- ---------------------------------------------------------------------------
-- the ends a wheel can come to
-- ---------------------------------------------------------------------------
-- the slice fires. viaButton: A or R3 (an off slice stays, as A on it always has); else the stick let go.
function G.commit(pn, st, i, viaButton)
    local menu = st.menu
    if not (i and i > 0) then return end
    local slice = menu.slices and menu.slices[i]
    local cmd = menu:getSliceCommand(i)
    if not (cmd and cmd[1]) then
        -- an off slice does what taking one does today: letting go on the top level closes the wheel,
        -- in an inner wheel it stays open
        if viaButton then return end
        if #st.path <= 1 then return D.close(pn) end
        st.latch, st.engaged = nil, false
        st.lastActive = getTimestampMs()
        menu._zedPoint = -1
        return
    end
    if cmd[1] ~= D.enter and cmd[1] ~= D.back then
        menu:undisplay()
        G.finish(pn, st)
    end
    W.noteChoice(menu, slice)
    cmd[1](cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7])
end

-- aim or attack (the director): the wheel closes, nothing is taken, and the press goes through. The trigger is
-- still down, so the two flags have to be off now, or the game holds the swing until the stick is centered.
function G.attack(pn)
    D.close(pn)
    setJoypadIgnoreAim(pn, false)
    setJoypadIgnoreAimUntilCentered(pn, false)
end

function G.swap(pn, dir, jd)
    if dir ~= "down" and dir ~= "select" and D.paused() then return end   -- (paused: only Here and now and ZeD)
    D.close(pn)
    if dir == "select" then
        D.open("select", jd or { player = pn }, getPlayerBackButtonWheel(pn))
    else
        D.open(dir, jd or { player = pn })
    end
end

-- the windows behind a bumper: LB the Character window, RB the World window, as in a window
-- (the window pair is player 1's: another player's bumper only closes that player's wheel)
local function openWindows(pn, name)
    if pn ~= 0 then return end
    local F = ZeD.Input and ZeD.Input.Focus
    if F and F.openSide then F.openSide((name == "LB") and "char" or "world") end
end

-- ---------------------------------------------------------------------------
-- the buttons: the wheel's onJoypadDown and onJoypadButtonReleased
-- ---------------------------------------------------------------------------
local function dirOf(button)
    if button == Joypad.DPadLeft then return "left" end
    if button == Joypad.DPadRight then return "right" end
    if button == Joypad.DPadUp then return "up" end
    if button == Joypad.DPadDown then return "down" end
    if button == Joypad.Back then return "select" end
    return nil
end

local function bumperName(button)
    if button == Joypad.LBumper then return "LB" end
    if button == Joypad.RBumper then return "RB" end
    return nil
end

-- the bumper held right now, for a chord assigned from the wheel: nil with both down (the zoom's)
function G.heldBumper(st, jid)
    local b = st.bump
    if b then
        if b.both or (b.LB and b.RB) then return nil end
        return b.LB and "LB" or "RB"
    end
    if not jid then return nil end
    local lb, rb = JoypadButton.LeftBump:isDown(jid), JoypadButton.RightBump:isDown(jid)
    if lb ~= rb then return lb and "LB" or "RB" end
    return nil
end

-- a chord went on: this bumper's release does nothing
function G.noteAssign(st)
    if st.bump then st.bump.used = true end
end

-- the slice the wheel has: the latch once the wheel runs on a stick, else the game's reading
function G.pointed(st, menu, id)
    if st.driven then return st.latch or -1 end
    return W.sliceFromJoypad(menu, id)
end

-- X held at the wheel of a car: D-pad Up and Down stay the cruise control. True when it took the press.
-- (The regulator polls X by the pad's id, so no id, no call.)
local function cruise(dir, jd)
    local R = ISVehicleRegulator
    if not (R and jd and jd.id) then return false end
    if dir == "up" then return R.onJoypadPressUp(jd) end
    if dir == "down" then return R.onJoypadPressDown(jd) end
    return false
end

-- Hold is today's: A takes, B backs out, X closes, the D-pad does nothing. Stick click adds R3.
local function holdButton(pn, st, menu, button, jd)
    if button == Joypad.BButton then return D.back(pn) end
    if button == Joypad.XButton then return D.close(pn) end
    local click = st.commit == "click" and button == Joypad.RStickButton
    if button == Joypad.AButton or click then
        local id = menu.joyfocus and menu.joyfocus.id or (jd and jd.id)
        return G.commit(pn, st, G.pointed(st, menu, id), true)
    end
end

function G.onButton(pn, st, menu, button, jd)
    local name = bumperName(button)
    if name then
        -- nothing happens yet: a face button may follow (the chord), so the close waits for the release
        local b = st.bump
        if not b then b = {}; st.bump = b end
        b[name] = true
        if b.LB and b.RB then b.both = true end
        return
    end
    if st.mode == "hold" then return holdButton(pn, st, menu, button, jd) end
    if button == Joypad.Start then
        -- the game stays live, so the pause does: the wheel closes and the press goes where it goes with no
        -- wheel up. (Opening the pause menu hides the UI, this wheel too, in the frame before it leaves.)
        D.close(pn)
        if jd and jd.controller then jd.controller:onPauseButtonPressed() end
        if menu.setVisible then menu:setVisible(true) end
        return
    end
    local dir = dirOf(button)
    if dir then
        if cruise(dir, jd) then return end
        if getTimestampMs() - st.openedAt < (D.tune.OPEN_DEBOUNCE_MS or 0) then return end   -- (the press that opened it lands here too)
        if st.mode == "toggle" and dir ~= "select" then
            G.move(st, menu, dir)
            return
        end
        if dir == st.dir then return D.close(pn) end
        return G.swap(pn, dir, jd)
    end
    if button == Joypad.BButton then return D.back(pn) end
    if st.mode == "toggle" and button == Joypad.AButton then
        return G.commit(pn, st, st.latch, true)
    end
    if st.commit == "click" and button == Joypad.RStickButton then
        return G.commit(pn, st, st.latch, true)   -- (the latch: the click doesn't move the highlight)
    end
    -- A, X and Y do nothing, and go no further
end

-- true: the release was the gesture's
function G.onRelease(menu, button)
    local st = menu._zedDpad
    local name = bumperName(button)
    local b = st and st.bump
    if not (name and b) then return false end
    b[name] = nil
    if b.LB or b.RB then return true end
    st.bump = nil
    if st.mode == "hold" or b.both or b.used then return true end
    -- a bumper tapped: the wheel closes and the windows open
    -- (paused: the windows stay shut, as Y keeps them. A window with the pad on a paused game drops every press.)
    local pn = menu.playerNum or 0
    D.close(pn)
    if not D.paused() then openWindows(pn, name) end
    return true
end

-- the game repeats a held direction (JoypadControllerData:update): only the press itself opens a wheel,
-- or B would close a wheel and the same held thumb would open it again
local HELD_FOR = { left = "dtleft", right = "dtright", up = "dtup", down = "dtdown" }
function G.freshPress(dir, jd)
    local c = jd and jd.controller
    local dt = c and c[HELD_FOR[dir]]
    return not (dt and dt > 100)
end

-- ---------------------------------------------------------------------------
-- one frame of one player's wheel
-- ---------------------------------------------------------------------------
-- a stick let go can swing past the center and read above engage on the far side of the wheel, with no frame
-- under release in between. True while this frame may be that: the highlight stays. A slice within a quarter turn
-- of the highlight is the stick moving round the rim, and moves at once.
local function springingBack(menu, st, i, ax, ay, now)
    if not st.latch or i == st.latch then st.farSince = nil; return false end
    local width = 360 / math.max(#(menu.slices or {}), 2)
    if awayFrom(st.latch, clock(ax, ay), width) <= 90 then st.farSince = nil; return false end
    st.farSince = st.farSince or now
    return now - st.farSince < (D.tune.FAR_HOLD_MS or 0)
end

local function pick(pn, st, menu, ax, ay)
    local engage, release = G.radii()
    local mag = math.sqrt(ax * ax + ay * ay)
    local now = getTimestampMs()
    if mag <= engage then st.farSince = nil end
    if st.needCenter then
        -- (a pad resting between the radii never gets under release: sitting there is its center. Only sitting:
        -- passing through on the way to an overshoot must not count.)
        if mag < release then
            st.needCenter = false
        elseif mag < engage then
            st.restSince = st.restSince or now
            if now - st.restSince >= (D.tune.REST_MS or 0) then st.needCenter = false end
        else
            st.restSince = nil
        end
    elseif mag > engage then
        local i = G.sector(menu, st, ax, ay)
        if not springingBack(menu, st, i, ax, ay, now) then
            st.latch = (i > 0) and i or nil
            st.engaged = i > 0
        end
        st.lastActive = now
    elseif mag < release and st.engaged then
        st.engaged = false
        st.lastActive = now
        -- (a bumper held keeps the highlight: the thumb has left the stick to press the chord's button)
        local jd = JoypadState.players[pn + 1]
        local bump = st.bump or (jd and jd.id and jd.id >= 0 and (JoypadButton.LeftBump:isDown(jd.id) or JoypadButton.RightBump:isDown(jd.id)))
        if st.commit == "flick" and not bump then
            return G.commit(pn, st, st.latch, false)
        end
    end
    menu._zedPoint = st.latch or -1
    -- the timer: nothing pointed at, or a stick left sitting under engage with a slice lit (a pad that rests above
    -- release never lets go, and nothing is taken for it). Stick click's lit slice waits for the click.
    if st.mode == "tap" and (not st.engaged or mag <= engage) and not st.bump
       and not (st.commit == "click" and st.latch)
       and now - st.lastActive > (D.tune.DISMISS_TIMEOUT_S or 3) * 1000 then
        D.close(pn)
    end
end

-- off the screen with no close of ours: Hold's letting go, a click, a slice's own close, or the whole UI hidden
-- (the pause menu, Esc, the Toggle UI key). Removed, never undisplayed: that clears whatever focus the pad has now,
-- and it can be the pause menu's.
local function gone(pn, st, menu)
    menu:removeFromUIManager()
    G.finish(pn, st)
    -- the game would bring a hidden wheel back with the pad on it: this one is over, so it leaves the saved focus,
    -- and it can't stay hidden, the game's own fillers show the shared wheel without setting that
    local saved = JoypadState.saveFocus
    if saved then
        for i, f in pairs(saved) do
            if f == menu then saved[i] = nil; break end
        end
    end
    if menu.setVisible then menu:setVisible(true) end
end

local function step(pn, st)
    local menu = st.menu
    local p = getSpecificPlayer(pn)
    if not menu or not p or p:isDead() then return D.close(pn) end
    -- (a wheel just opened is still in the UI queue: only one seen on the screen can have left it)
    if menu:isReallyVisible() then
        st.seen = menu
    elseif st.seen == menu then
        return gone(pn, st, menu)
    end
    local jd = JoypadState.players[pn + 1]
    if st.pad and (not jd or jd.focus ~= menu) then
        -- a window or a prompt took the pad (or it is gone): the wheel goes and the focus stays where it went
        menu:removeFromUIManager()
        return G.finish(pn, st)
    end
    if W.qaPoint or not menu._zed then return end   -- (QA's pointed slice; a wheel the engine draws)
    local ax, ay = G.stick(pn, jd)
    if not ax then st.driven = false; return end
    st.driven = true
    -- a trigger pressed with a wheel up. In a vehicle the triggers are the pedals; Hold is today's.
    if st.mode ~= "hold" then
        local tr = false
        if not p:getVehicle() then tr = G.trigger(pn, jd) end
        if tr and not st.trigHeld then return G.attack(pn) end
        st.trigHeld = tr
    end
    pick(pn, st, menu, ax, ay)
end

local function frame()
    for pn = 0, 3 do
        local st, was = D.state[pn], G.live[pn]
        if was and was ~= st then G.finish(pn, was) end
        if st then
            G.live[pn] = st
            local ok, err = pcall(step, pn, st)
            if not ok then
                ZeD.logOnce("WheelGesture", err)
                pcall(D.close, pn)
            end
        end
    end
end

if Events and Events.OnRenderTick then Events.OnRenderTick.Add(frame) end

-- ---------------------------------------------------------------------------
-- QA: every gesture with no pad (zedqa_dpad_wheels.lua, zedqa_quick_chords.lua)
-- ---------------------------------------------------------------------------
-- a simulated stick; nil gives the stick back
function D.qaStick(pn, x, y)
    if x == nil then G.qa[pn] = nil else G.qa[pn] = { x = x, y = y or 0 } end
end
-- the triggers down or up; nil gives them back
function D.qaTrigger(pn, down) G.qaTrig[pn] = down end
-- one frame now, so a script can play a flick frame by frame
function D.qaStep(pn)
    local st = D.state[pn]
    if st then step(pn, st) end
end
-- a look at the state: nil with no wheel up
function D.gesture(pn)
    local st = D.state[pn]
    if not st then return nil end
    local jd = JoypadState.players[pn + 1]
    return { dir = st.dir, mode = st.mode, commit = st.commit, held = st.held, level = #st.path, latch = st.latch,
             engaged = st.engaged == true, needCenter = st.needCenter == true, driven = st.driven == true,
             point = st.menu and st.menu._zedPoint, bump = st.bump ~= nil,
             focus = jd and jd.focus == st.menu or false, pausedWas = st.pausedWas }
end
