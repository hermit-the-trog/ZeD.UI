-- ZeD-UI/42/media/lua/client/ZeD/ZeD_QuickChords.lua
-- ============================================================================
-- QUICK ACTIONS ON BUMPER CHORDS: a bumper with A, B, X, Y, L3 or R3, twelve
-- quick actions a player assigns. Client; an override of vanilla's
-- JoypadControllerData (press and release) plus the chords' store, which ZeD's
-- Options window (a row per chord) and the D-pad wheels edit.
--
-- In the world (no window has the pad, no wheel is open, not paused), hold LB
-- or RB and press A, B, X, Y, L3 or R3: the action assigned to that chord
-- runs. The button pressed with a bumper does only the chord: it never reaches
-- the game's prompts (JoypadControllerData:onPressButtonNoFocus) or the
-- windows' Y (FocusManager). A bumper on its own still does nothing in the
-- world; LB + RB stays the zoom (BumperChord).
--
-- An action is any slice of the four D-pad wheels (ZeD_DpadWheels), found
-- again by its path: the wheel, then each level's place or key, e.g.
-- "character:3" (Eat), "character:3:Base.CannedCorn" (Eat > Canned Corn),
-- "character:8:1" (Use > Smoke). A slice that opens a list of things you
-- carry (marked best in ZeD_DpadWheels: Weapons, Eat, Drink, Medicine, Smoke,
-- Read) does its best pick at once: its own pick, else the first one the list
-- offers that can be done (the wheels' order: food spoiling soonest first,
-- water first ...). A slice that opens a wheel of places (Tabs, Map, View),
-- or one the game fills (Vehicle, Animal, a gesture group), opens that wheel.
-- One that can't run now does nothing, and the character says why over their
-- head (the game's HaloTextHelper), with the wheel's reason.
--
-- The twelve are kept in Zomboid/Lua/ZeD_chords.txt: "LB+A=<path>|<words>",
-- the words being the wheel's crumb at the time (tab separated), for the
-- setup page at the main menu where no wheel can be built. "LB+A=" is a
-- chord cleared on purpose. A chord the file does not name has its default.
-- ============================================================================

require "ISUI/Gamepad/JoyPadSetup"
require "ZeD/Tr"
require "ISUI/ISFirearmRadialMenu"   -- (its RB is wrapped below, QA K1-4)
require "ZeD/SafeMode"

ZeD = ZeD or {}
ZeD.QuickChords = ZeD.QuickChords or {}
local Q = ZeD.QuickChords

Q.BUMPERS = { "LB", "RB" }
Q.FACES = { "A", "B", "X", "Y", "L3", "R3" }
Q.CHORDS = {}
for _, b in ipairs(Q.BUMPERS) do for _, f in ipairs(Q.FACES) do Q.CHORDS[#Q.CHORDS + 1] = b .. "+" .. f end end

local WHEEL_OF = { character = "left", world = "right", social = "up", now = "down" }
local WHEEL_TITLE = { character = "UI_ZeD_Wheel_Character", world = "UI_ZeD_Wheel_World", social = "UI_ZeD_Wheel_Social", now = "UI_ZeD_Wheel_HereNow" }
Q.WHEELS = { "character", "world", "social", "now" }

local function word(key)
    if key:sub(1, 7) == "UI_ZeD_" then return ZeD.tr(key) end
    return getText(key)
end

-- the starting layout, with the words as translation keys
Q.DEFAULTS = {
    ["LB+A"]  = { "character:3",   { "UI_ZeD_Wheel_Character", "ContextMenu_Eat" } },
    ["LB+B"]  = { "character:4",   { "UI_ZeD_Wheel_Character", "ContextMenu_Drink" } },
    ["LB+X"]  = { "now:8",         { "UI_ZeD_Wheel_HereNow", "UI_ZeD_Wheel_Light" } },
    ["LB+Y"]  = { "character:8:1", { "UI_ZeD_Wheel_Character", "UI_ZeD_Wheel_Use", "ContextMenu_Smoke" } },
    ["LB+L3"] = { "now:1:1",       { "UI_ZeD_Wheel_HereNow", "UI_ZeD_Wheel_Sit", "ContextMenu_SitGround" } },
    ["LB+R3"] = { "social:5",      { "UI_ZeD_Wheel_Social", "IGUI_Emote_Shout" } },
    ["RB+A"]  = { "character:5",   { "UI_ZeD_Wheel_Character", "UI_ZeD_Wheel_Medicine" } },
    ["RB+B"]  = { "character:2",   { "UI_ZeD_Wheel_Character", "UI_ZeD_Wheel_Weapons" } },
    ["RB+X"]  = { "character:8:2", { "UI_ZeD_Wheel_Character", "UI_ZeD_Wheel_Use", "ContextMenu_Read" } },
    -- (the World wheel's Map slice opens the map itself now, no inner ring: KISS #36)
    ["RB+Y"]  = { "world:2",       { "UI_ZeD_Wheel_World", "UI_ZeD_Wheel_Map" } },
    ["RB+L3"] = { "now:3",         { "UI_ZeD_Wheel_HereNow", "UI_ZeD_Wheel_AutoWalk" } },
    ["RB+R3"] = { "now:2",         { "UI_ZeD_Wheel_HereNow", "UI_ZeD_Wheel_Crouch" } },
}

-- ---------------------------------------------------------------------------
-- the twelve, kept in Zomboid/Lua/ZeD_chords.txt
-- ---------------------------------------------------------------------------
local FILE = "ZeD_chords.txt"
local store = nil   -- chord -> { path = string|nil, words = { ... } }  (nil path = cleared)
local unread = false   -- the file did not read: a save must not write this short list over it

-- Lua has no rename and the game's writer cuts a file the moment it opens, so a save goes through a
-- spare file: the text and a last line saying it is whole go there and are read back, then the real
-- file is written and the spare emptied. A whole spare found on load is a save that did not finish; a
-- disk that cannot hold the text stops at the spare, with the real file as it was.
local SPARE = "ZeD_chords_spare.txt"
local WHOLE = "-- whole"

-- a file's lines (nil: no file, false: it did not read to its end)
local function readAll(file)
    local r = nil
    pcall(function() r = getFileReader(file, false) end)
    if not r then return nil end
    local t = {}
    local ok = pcall(function()
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
    end)
    pcall(function() r:close() end)
    if not ok then return false end
    return t
end

local function writeAll(file, text)
    local w = nil
    pcall(function() w = getFileWriter(file, true, false) end)
    if not w then return false end
    local ok = pcall(function() w:write(text) end)
    pcall(function() w:close() end)
    return ok
end

local function keepFile(text)
    local n = 0
    for _ in text:gmatch("\n") do n = n + 1 end
    if not writeAll(SPARE, text .. WHOLE .. "\n") then return false end
    local back = readAll(SPARE)
    if not back or #back ~= n + 1 or back[n + 1] ~= WHOLE then return false end
    if not writeAll(FILE, text) then return false end
    local done = readAll(FILE)
    if done and #done == n then writeAll(SPARE, "") end
    return true
end

local function load()
    store = {}
    local lines = readAll(SPARE)
    if lines and lines[#lines] == WHOLE then lines[#lines] = nil else lines = readAll(FILE) end
    unread = lines == false
    if not lines then return end
    for _, line in ipairs(lines) do
        local chord, rest = line:match("^([LR]B%+[ABXYLR3]+)=(.*)$")
        if chord then
            local path, words = rest:match("^([^|]*)|?(.*)$")
            local w = {}
            for s in (words or ""):gmatch("[^\t]+") do w[#w + 1] = s end
            store[chord] = { path = (path and path ~= "") and path or nil, words = w }
        end
    end
end

-- (QA OP24, director's pick Nov 27 2026: in Options a chord pick or X is a change like any row's: it waits for Apply,
-- and Discard brings the old chords back. Options holds the chords while it is open: picks change the list in memory
-- (the rows and the help show them) and the file is written only at Apply. A holder that went away without an answer
-- (its window no longer shown) drops what it held, as a Discard, before the next look.)
local hold = nil   -- { snap = chord -> copy of the store's entry (false = none), alive = fn }

local function copyEntry(s)
    if not s then return false end
    local w = {}
    for i, v in ipairs(s.words or {}) do w[i] = v end
    return { path = s.path, words = w }
end
local function sameEntry(a, b)
    if not a or not b then return (not a) == (not b) end
    if a.path ~= b.path then return false end
    local wa, wb = a.words or {}, b.words or {}
    if #wa ~= #wb then return false end
    for i = 1, #wa do if wa[i] ~= wb[i] then return false end end
    return true
end

local function save()
    if unread then return end
    if hold then return end   -- (OP24: held by Options; written at Apply, Q.commit)
    -- (the whole text first: a Lua error on the way leaves the file as it was)
    local buf = {}
    local w = { write = function(_, s) buf[#buf + 1] = s end }
    w:write("ZeD-UI quick action chords: chord=wheel path|the wheel's words (an empty path is a chord cleared on purpose)\n")
    for _, c in ipairs(Q.CHORDS) do
        local s = store[c]
        if s then w:write(c .. "=" .. (s.path or "") .. "|" .. table.concat(s.words or {}, "\t") .. "\n") end
    end
    keepFile(table.concat(buf))
end

-- the store read, and a hold whose window went away without Apply or Discard dropped (OP24, Nov 27 2026)
local function ready()
    if not store then load() end
    if hold and hold.alive then
        local ok, live = pcall(hold.alive)
        if not (ok and live) then
            for _, c in ipairs(Q.CHORDS) do store[c] = copyEntry(hold.snap[c]) or nil end
            hold = nil
        end
    end
end

--- (OP24) Options opened: chord picks wait for Apply. alive() says the holder is still shown.
--- A hold already there (a window that never answered) is dropped first.
function Q.hold(alive)
    if not store then load() end
    if hold then for _, c in ipairs(Q.CHORDS) do store[c] = copyEntry(hold.snap[c]) or nil end end
    local snap = {}
    for _, c in ipairs(Q.CHORDS) do snap[c] = copyEntry(store[c]) end
    hold = { snap = snap, alive = alive }
end
--- (OP24) How many chords differ from what they were when the hold began (or at the last Apply).
function Q.pendingCount()
    if not hold then return 0 end
    ready()
    if not hold then return 0 end
    local n = 0
    for _, c in ipairs(Q.CHORDS) do if not sameEntry(store[c], hold.snap[c]) then n = n + 1 end end
    return n
end
--- (OP24) Is this chord changed and not applied yet?
function Q.isPending(chord)
    if not hold then return false end
    ready()
    return hold ~= nil and not sameEntry(store[chord], hold.snap[chord])
end
--- (OP24) Apply: the chords as they are now go in the file; the hold goes on from here.
function Q.commit()
    if not store then load() end
    local h = hold
    hold = nil
    save()
    if h then Q.hold(h.alive) end
end
--- (OP24) Discard: the chords back as they were when the hold began (or at the last Apply); the hold goes on.
function Q.revert()
    if not hold then return end
    if not store then load() end
    for _, c in ipairs(Q.CHORDS) do store[c] = copyEntry(hold.snap[c]) or nil end
end
--- (OP24) Options closed: anything not applied is dropped and saves are at once again.
function Q.release()
    Q.revert()
    hold = nil
end
function Q.held() return hold ~= nil end

--- The chord's path (nil = nothing) and its words, for showing.
function Q.get(chord)
    ready()
    local s = store[chord]
    if s then return s.path, s.words end
    local d = Q.DEFAULTS[chord]
    if not d then return nil, {} end
    local w = {}
    for i, k in ipairs(d[2]) do w[i] = word(k) end
    return d[1], w
end

--- Give a chord a path and the words to show for it; saved at once (while Options holds them, at its Apply: OP24).
function Q.set(chord, path, words)
    ready()
    local w = {}
    for i, s in ipairs(words or {}) do w[i] = tostring(s):gsub("[\t\r\n|]", " ") end
    store[chord] = { path = path, words = w }
    save()
end
--- Clear a chord on purpose: it runs nothing (not the same as its default).
function Q.clear(chord) Q.set(chord, nil, {}) end
--- Is the chord as it starts (no line of its own in the file)?
function Q.isDefault(chord)
    ready()
    return store[chord] == nil
end
--- The name of the chord's default action (the last of its words), or "None".
function Q.defaultName(chord)
    local d = Q.DEFAULTS[chord]
    return d and word(d[2][#d[2]]) or ZeD.tr("UI_ZeD_Chord_None")
end
function Q.reload() if hold then return end; store = nil end   -- (the file is read again on the next look)  (not while Options holds picks: OP24)
--- Put a chord back to its default.
function Q.reset(chord)
    ready()
    store[chord] = nil
    save()
end

--- The first chord that runs this path (nil = none).
function Q.chordFor(path)
    if not path then return nil end
    for _, c in ipairs(Q.CHORDS) do if Q.get(c) == path then return c end end
    return nil
end

--- A slice's name without the wheel's count ("Canned Corn (3)"; the older "  x3" too).
function Q.cleanName(s) return (tostring(s or ""):gsub("%s+x%d+$", ""):gsub("%s+%(%d+%)$", "")) end

-- ---------------------------------------------------------------------------
-- finding the action again, and doing it
-- ---------------------------------------------------------------------------
local function safe(fn, ...) local ok, v = pcall(fn, ...); if ok then return v end; return nil end

local function find(list, seg)
    for _, e in ipairs(list or {}) do if e.key ~= nil and tostring(e.key) == seg then return e end end
    local i = tonumber(seg)
    return i and list and list[i] or nil
end

--- The entry a path names, with the chain of entries above it and its wheel; nil + why when it is gone.
function Q.resolve(p, pn, path)
    local D = ZeD.DpadWheels
    if not (D and D.B and path) then return nil end
    -- a chord saved on the old Map ring's World map slice is the Map slice now, which opens the map itself (KISS #36)
    if path == "world:2:1" then path = "world:2" end
    local segs = {}
    for s in path:gmatch("[^:]+") do segs[#segs + 1] = s end
    local wheel = segs[1]
    if not (wheel and D.B[wheel]) then return nil end
    local list = safe(D.B[wheel], p, pn) or {}
    local chain, e = {}, nil
    for i = 2, #segs do
        if e then
            if e.off then return nil, e.off, chain end   -- (a list that can't open: its reason)
            if not e.sub then return nil, nil, chain end
            list = safe(e.sub, p, pn) or {}
        end
        e = find(list, segs[i])
        if not e then return nil, nil, chain end
        chain[#chain + 1] = e
    end
    return e, nil, chain, wheel
end

-- a list's best pick: its own pick, else the first slice that can be done (into a list inside, twice at most)
local function bestOf(e, p, pn, depth)
    if e.pick then
        local b = safe(e.pick, p, pn)
        if b then return b end
    end
    for _, x in ipairs(e.sub and (safe(e.sub, p, pn) or {}) or {}) do
        if not x.off then
            if x.run then return x end
            if x.sub and depth < 2 then local b = bestOf(x, p, pn, depth + 1); if b then return b end end
        end
    end
    return nil
end

local function say(p, text) if text and text ~= "" and HaloTextHelper then pcall(HaloTextHelper.addBadText, p, text) end end

-- a slice the game fills itself: that wheel, open, as the D-pad would show it
local function openFilled(p, pn, wheel, chain)
    local D = ZeD.DpadWheels
    if not (D and D.open and WHEEL_OF[wheel]) then return end
    D.open(WHEEL_OF[wheel], { player = pn })
    for _, e in ipairs(chain) do
        if D.state[pn] then D.enter(pn, e) end
    end
end

--- Run the chord for player p; true when it did something.
function Q.run(p, chord)
    local pn = p:getPlayerNum()
    local path, words = Q.get(chord)
    if not path then return false end
    local e, why, chain, wheel = Q.resolve(p, pn, path)
    if not e then
        say(p, why or ZeD.tr("UI_ZeD_Chord_Gone", words[#words] or "?"))
        return false
    end
    if e.off then say(p, e.off); return false end
    -- a wheel the game fills, or a wheel of places (Map, Tabs, View): that wheel, open
    if e.fill or (e.sub and not e.run and not (e.best or e.pick)) then openFilled(p, pn, wheel, chain); return true end
    local act = e
    if not e.run and (e.sub or e.pick) then
        act = bestOf(e, p, pn, 0)
        if not act then say(p, ZeD.tr("UI_ZeD_Wheel_NotNow")); return false end
    end
    if act.off then say(p, act.off); return false end   -- (a pick that is there but can't run says why: Weapons with only the one in hand, QA K1-5)
    if not act.run then return false end
    local ok, err = pcall(act.run, p, pn)
    if not ok then print("[ZeD] QuickChords: " .. chord .. " (" .. path .. "): " .. tostring(err)) end
    return ok
end

-- ---------------------------------------------------------------------------
-- the actions a chord can take, for the setup page's list: per wheel, each
-- slice that does something, a list slice as its best pick then the slices
-- in it (one level in; a list inside a list as its best pick), a wheel the
-- game fills as "opens its wheel"
-- ---------------------------------------------------------------------------
--- The setup page's list: { { id, title, actions = { { path, words, text } } } }, one entry per wheel.
function Q.catalog(p, pn)
    local D = ZeD.DpadWheels
    local out = {}
    if not (D and D.B and p) then return out end
    local CH = " \226\128\186 "
    for _, wheel in ipairs(Q.WHEELS) do
        local title = ZeD.tr(WHEEL_TITLE[wheel])
        local acts = {}
        -- (QA's visual noise audit, Words, Nov 20 2026: "Zoom: opens its wheel", "Zoom > Zoom 75%" and "View > OPTIONS".
        -- A wheel the game fills reads "Zoom ...", a slice drops its parent's name from its front, and a name the
        -- game writes in capitals reads in sentence case.)
        local function add(path, words, how)
            local w = {}
            for i = 2, #words do
                local s = tostring(words[i] or "")
                local parent = (i > 2) and tostring(words[i - 1] or "") or nil
                if parent and #s > #parent + 1 and s:sub(1, #parent + 1) == parent .. " " then s = s:sub(#parent + 2) end
                if #s > 3 and s == s:upper() and s ~= s:lower() then s = s:sub(1, 1) .. s:sub(2):lower() end
                w[#w + 1] = s
            end
            local text = table.concat(w, CH)
            if how == ZeD.tr("UI_ZeD_Chord_OpensWheel") then text = text .. " ..."
            elseif how then text = text .. ": " .. how end
            acts[#acts + 1] = { path = path, words = words, text = text }
        end
        local function how(e) return (e.best or e.pick) and ZeD.tr("UI_ZeD_Chord_BestPick") or ZeD.tr("UI_ZeD_Chord_OpensWheel") end
        for i, e in ipairs(safe(D.B[wheel], p, pn) or {}) do
            local name = Q.cleanName(e.word or e.name)   -- (word: a slice's steady name, the light's)
            local path = wheel .. ":" .. i
            if e.fill then add(path, { title, name }, ZeD.tr("UI_ZeD_Chord_OpensWheel"))
            elseif e.run then add(path, { title, name })
            elseif e.sub then
                add(path, { title, name }, how(e))
                -- the slices inside: where some carry a key (the things you carry, tabs, Hands free), only those,
                -- since the rest come and go (a wound's treatments); a fixed wheel (Map, Sit, Use) all of them
                local list = safe(e.sub, p, pn) or {}
                local keyed = false
                for _, x in ipairs(list) do if x.key ~= nil then keyed = true; break end end
                for j, x in ipairs(list) do
                    if x.key ~= nil or not keyed then
                        local xn = Q.cleanName(x.name)
                        local xp = path .. ":" .. tostring(x.key or j)
                        if x.fill then add(xp, { title, name, xn }, ZeD.tr("UI_ZeD_Chord_OpensWheel"))
                        elseif x.run then add(xp, { title, name, xn })
                        elseif x.sub then add(xp, { title, name, xn }, how(x)) end
                    end
                end
            end
        end
        out[#out + 1] = { id = wheel, title = title, actions = acts }
    end
    return out
end

-- ---------------------------------------------------------------------------
-- the pad: a bumper held and one of the six pressed, in the world
-- ---------------------------------------------------------------------------
local FACE_OF = {}
-- pad id -> { button -> true }: a chord's button until that pad lets it go (its release is swallowed too).
-- Kept per pad, so one local player's chord never swallows another player's release of the same button.
local consumed = {}

local function bumperHeld(jid)
    if Q.qaBumper then return Q.qaBumper end   -- (a test hook: zedqa_quick_chords.lua holds a bumper without a pad)
    local lb = JoypadButton.LeftBump:isDown(jid)
    local rb = JoypadButton.RightBump:isDown(jid)
    if lb and rb then return nil end   -- (both: the zoom's)
    return lb and "LB" or (rb and "RB") or nil
end

local function paused()
    local sc = UIManager.getSpeedControls()
    return sc ~= nil and sc:getCurrentGameSpeed() == 0
end

-- the press, before the game's prompts see it; true = it was a chord
function Q.onPress(joypadData, button)
    if ZeD.Safe.on() then return false end
    local face = FACE_OF[button]
    if not (face and joypadData and joypadData.player and joypadData.id) then return false end
    local bump = bumperHeld(joypadData.id)
    if not bump then return false end
    local p = getSpecificPlayer(joypadData.player)
    if not p or p:isDead() or paused() then return false end
    local F = ZeD.Input and ZeD.Input.Focus
    if F and F.getFocusedWindow and F.getFocusedWindow(joypadData.player) then return false end   -- (that player's window has the pad)
    local mine = consumed[joypadData.id]
    if not mine then mine = {}; consumed[joypadData.id] = mine end
    mine[button] = true
    if bump == "RB" then Q.rbClaimed[joypadData.player] = { up = 0 } end   -- (this RB is the chord's, not the game's reload: QA K1-4)
    local chord = bump .. "+" .. face
    -- (a use of the hint strip's first hours' line, "LB or RB + button Quick actions": KISS #26)
    if ZeD.HintStrip and ZeD.HintStrip.taught then pcall(ZeD.HintStrip.taught, "chords") end
    local ok, err = pcall(Q.run, p, chord)
    if not ok then print("[ZeD] QuickChords: " .. chord .. ": " .. tostring(err)) end
    Q.lastChord = chord   -- (the last chord pressed, kept for testing)
    return true
end

-- ---------------------------------------------------------------------------
-- RB kept from the game's reload while it is half of a chord or of the zoom (QA K1-4)
-- ---------------------------------------------------------------------------
-- With a gun in hand the game reloads on an RB tapped (under half a second) and opens its firearm wheel on
-- an RB held (ISFirearmRadialMenu.onJoypadButtonReleased / onRepeatRBumper). ZeD takes only the face
-- button of a chord, so RB + A for a painkiller also swapped the magazine, and LB + RB (the zoom) too.
-- player number -> { up = ticks RB has been up } while ZeD owns that RB press
Q.rbClaimed = Q.rbClaimed or {}

-- the pad's id for a player, nil when that player has none
local function padOf(pn)
    local jd = JoypadState and JoypadState.players and JoypadState.players[pn + 1]
    return jd and jd.id or nil
end

-- is this player's RB press ZeD's? A chord claimed it (Q.onPress), or LB is down with it: the zoom
local function rbClaimedNow(pn)
    if Q.rbClaimed[pn] then return true end
    local jid = padOf(pn)
    if jid ~= nil and JoypadButton.LeftBump:isDown(jid) and JoypadButton.RightBump:isDown(jid) then
        Q.rbClaimed[pn] = { up = 0 }
        return true
    end
    return false
end

-- A claim whose release never reached the game's prompts (a window took the pad meanwhile) would block
-- the next lone RB's reload: it goes once RB has been up a few ticks (a few, so the release itself,
-- which may come a tick after RB reads up, still finds it)
local function rbClaimTick()
    local gone = nil
    for pn, c in pairs(Q.rbClaimed) do
        local jid = padOf(pn)
        if jid ~= nil and JoypadButton.RightBump:isDown(jid) then c.up = 0 else c.up = c.up + 1 end
        if c.up >= 3 then gone = gone or {}; gone[#gone + 1] = pn end
    end
    for _, pn in ipairs(gone or {}) do Q.rbClaimed[pn] = nil end   -- (dropped after the walk, not during it)
end

-- wraps the game's firearm wheel once (the _zedChords flag keeps a second call from wrapping the wrapper)
local function applyFirearm()
    if not ISFirearmRadialMenu or ISFirearmRadialMenu._zedChords then return end
    ISFirearmRadialMenu._zedChords = true
    local origRepeat = ISFirearmRadialMenu.onRepeatRBumper
    ISFirearmRadialMenu.onRepeatRBumper = function(buttonPrompt, ...)
        -- RB held as half of a chord or the zoom: no firearm wheel
        if buttonPrompt and buttonPrompt.player and rbClaimedNow(buttonPrompt.player) then return end
        return origRepeat(buttonPrompt, ...)
    end
    local origRelease = ISFirearmRadialMenu.onJoypadButtonReleased
    ISFirearmRadialMenu.onJoypadButtonReleased = function(buttonPrompt, button, joypadData, ...)
        local pn = buttonPrompt and buttonPrompt.player
        if button == Joypad.RBumper and pn and Q.rbClaimed[pn] then
            Q.rbClaimed[pn] = nil
            -- the game's own release still runs, so its press time is cleared for the next RB, with the
            -- reload stood down for this one call
            local R = ISReloadWeaponAction
            local begin = R and R.BeginAutomaticReload
            if begin then R.BeginAutomaticReload = function() end end
            local ok, err = pcall(origRelease, buttonPrompt, button, joypadData, ...)
            if begin then R.BeginAutomaticReload = begin end
            if not ok then print("[ZeD] QuickChords: firearm release: " .. tostring(err)) end
            return
        end
        return origRelease(buttonPrompt, button, joypadData, ...)   -- (RB alone: the game's reload, untouched)
    end
    Events.OnTick.Add(rbClaimTick)
end
Q._applyFirearm = applyFirearm

-- wraps vanilla's press and release once: it runs at load and again at game boot, and the _zedChords flag
-- keeps the second call from wrapping the wrapper
local function apply()
    if not JoypadControllerData or JoypadControllerData._zedChords then return end
    JoypadControllerData._zedChords = true
    FACE_OF = { [Joypad.AButton] = "A", [Joypad.BButton] = "B", [Joypad.XButton] = "X", [Joypad.YButton] = "Y",
                [Joypad.LStickButton] = "L3", [Joypad.RStickButton] = "R3" }
    local origPress = JoypadControllerData.onPressButtonNoFocus
    function JoypadControllerData:onPressButtonNoFocus(button)
        local ok, took = pcall(Q.onPress, self.joypad, button)
        if ok and took then return end
        return origPress(self, button)
    end
    local origRelease = JoypadControllerData.onReleaseButton
    function JoypadControllerData:onReleaseButton(button)
        -- (keyed on the controller's joypadData as the press is: a QA controller may carry no id of its own)
        local jd = self.joypad
        local mine = jd and jd.id ~= nil and consumed[jd.id]
        if mine and mine[button] then
            mine[button] = nil
            if not jd.focus then return end   -- (in the world: the release of a chord's button is the chord's too)
        end
        return origRelease(self, button)
    end
    print("[ZeD] QuickChords: a bumper held with A, B, X, Y, L3 or R3 runs a quick action")
end
Q._apply = apply

-- A pad unplugged with a chord's button down never sends that release: drop what it held, so the
-- pad plugged back in starts clean
if Events.OnGamepadDisconnect then
    Events.OnGamepadDisconnect.Add(function(id) if id ~= nil then consumed[id] = nil end end)
end

Events.OnGameBoot.Add(apply)
apply()
Events.OnGameBoot.Add(applyFirearm)   -- (QA K1-4)
applyFirearm()
