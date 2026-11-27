-- ZeDUI/tools/qa/belt_watch_pad_sim.lua
-- (Nov 16 2026, QA's audit, punch list 250, 251, 263) The controller's ways onto the belt and the full watch, and
-- Start from anything holding the pad.
--   250: the Character wheel's Belt slice gives the belt the pad (B.focus had no caller); the belt keeps its place
--        while the full watch it opened has the pad, and takes it back on B there.
--   251: the full watch on the pad: lands on Start, the D-pad walks its keys, A presses, SET / the crown / SPEED are
--        grabbed with A and the D-pad turns them, A or B lets go, B gives the pad back where it came from.
--   263: ZeD.padStart, the one helper every pad holder calls: Start goes to the game's pause.
-- Runs the real ZeD_Watch.lua and ZeD.padStart against stubs; the wiring in the other files is read from the source.
-- Run from the repo root: lua51 ZeDUI/tools/qa/belt_watch_pad_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]belt_watch_pad_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if ok then print("ok   " .. name) else failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function read(p)
    local f = assert(io.open(ROOT .. p, "rb")); local s = f:read("*a"); f:close()
    return (s:gsub("\r\n", "\n"))
end
local DIR = "42/media/lua/client/ZeD/"

-- ---------------------------------------------------------------------------
-- the game's globals
-- ---------------------------------------------------------------------------
Joypad = { AButton = 0, BButton = 1, XButton = 2, YButton = 3, Start = 7 }
local paused = 0
local controller = { onPauseButtonPressed = function() paused = paused + 1 end }
JoypadState = { players = { { controller = controller, focus = nil } } }
local focusLog = {}
function setJoypadFocus(pn, el) JoypadState.players[pn + 1].focus = el; focusLog[#focusLog + 1] = el or "game" end
local clock = 1000
function getTimestampMs() return clock end
function isClient() return false end
function require() end
function instanceof() return false end
function getSpecificPlayer(pn) return nil end
local speedNow = 1
local clicked = {}
UIManager = { getSpeedControls = function()
    return { getCurrentGameSpeed = function() return speedNow end,
             ButtonClicked = function(_, b) clicked[#clicked + 1] = b
                 if b == "Fast Forward x 1" then speedNow = 2 elseif b == "Fast Forward x 2" then speedNow = 3
                 elseif b == "Wait" then speedNow = 4 elseif b == "Play" then speedNow = 1 elseif b == "Pause" then speedNow = 0 end end,
             SetCurrentGameSpeed = function(_, n) speedNow = n end }
end }
function getGameTime() return { setMultiplier = function() end } end
local noop = { Add = function() end, Remove = function() end }
Events = { OnPreUIDraw = noop, OnPostUIDraw = noop, OnGameStart = noop, OnTick = noop }
ISPanel = { derive = function(self, name) local t = {}; t.__index = t; return setmetatable(t, { __index = self }) end }

ZeD = {
    tr = function(k, a) return k .. (a and ("(" .. tostring(a) .. ")") or "") end,
    trDefaults = function() end,
    uiSound = function() end,
    Safe = { register = function() end, on = function() return false end },
    Settings = {},
}

-- ---------------------------------------------------------------------------
-- 263: ZeD.padStart
-- ---------------------------------------------------------------------------
dofile(ROOT .. DIR .. "ZeD_Panel.lua")
check("263: ZeD.padStart is there", type(ZeD.padStart) == "function")
check("263: Start pauses", ZeD.padStart(Joypad.Start, JoypadState.players[1], 0) == true and paused == 1)
check("263: another button is not taken", ZeD.padStart(Joypad.AButton, JoypadState.players[1], 0) == false and paused == 1)
check("263: no joypadData: the player's own pad", ZeD.padStart(Joypad.Start, nil, 0) == true and paused == 2)
check("263: no pad at all: not taken", ZeD.padStart(Joypad.Start, nil, 3) == false and paused == 2)
-- every holder the audit named asks it first in its onJoypadDown (ZeD_Window and the ZeD_Panel default: the dash)
local HOLDERS = {
    { "TwoWayFull.lua", "ZeD_TwoWayFull" }, { "StationPopout.lua", "ZeD_StationPopout" },
    { "ZeD_CarRadio.lua", "ZeD_CarRadio" }, { "ZeD_SirenController.lua", "ZeD_SirenController" },
    { "ZeD_SurvivalGuideBook.lua", "ZeD_GuideBook" }, { "ZeD_SurvivalGuide.lua", "ZeD_GuideWindow" },
    { "ZeD_Reader.lua", "ZeD_Reader" }, { "ZeD_SeatChooser.lua", "ZeD_SeatChooser" },
    { "ZeD_Chat.lua", "ZeD_ChatWindow" }, { "ZeD_MessagesWindow.lua", "ZeD_MessagesWindow" },
    { "Organisms.lua", "ZeD_Window" }, { "ZeD_Panel.lua", "ZeD_Panel" },
    { "ZeD_Belt.lua", "ZeD_BeltHUD" }, { "ZeD_Watch.lua", "ZeD_Watch" },
}
for _, h in ipairs(HOLDERS) do
    local src = read(DIR .. h[1])
    -- (the first line of code in it, past its comments)
    local body = src:match("\nfunction " .. h[2] .. ":onJoypadDown%([^\n]*\n(.-)\nend\n") or ""
    local head = nil
    for line in body:gmatch("[^\n]+") do
        if not line:match("^%s*%-%-") then head = line; break end
    end
    check("263: " .. h[2] .. " asks ZeD.padStart first", head ~= nil and head:find("ZeD.padStart(button", 1, true) ~= nil, head)
end
check("263: the seat pop-out shares the seat chooser's handler",
    read(DIR .. "ZeD_SeatPopout.lua"):find("ZeD_SeatPopout.onJoypadDown  = ZeD_SeatChooser.onJoypadDown", 1, true) ~= nil)
check("263: the dash has no handler of its own (ZeD_Panel's)", read(DIR .. "ZeD_Dashboard.lua"):find(":onJoypadDown(", 1, true) == nil)

-- ---------------------------------------------------------------------------
-- 251: the full watch on the pad (the real file)
-- ---------------------------------------------------------------------------
-- TW.nearest, the faces' own walk, taken from TwoWayFace.lua
local twSrc = read(DIR .. "TwoWayFace.lua")
local nearestBody = twSrc:match("\nfunction TW%.nearest%(.-\nend\n")
check("251: finds TW.nearest", nearestBody ~= nil)
ZeD.TwoWay = {}
assert(loadstring("local TW = ...\n" .. nearestBody))(ZeD.TwoWay)

dofile(ROOT .. DIR .. "ZeD_Watch.lua")
local W = ZeD.Watch
check("251: W.padOpen is there", type(W.padOpen) == "function")

-- an instance by hand (no game: its draw is not run), on a CaZio digital's controls
local inst = setmetatable({ playerNum = 0, _hit = {}, _setOpen = false, _popped = false, _belt = false }, { __index = ZeD_Watch })
function inst:isVisible() return true end
W._instance = inst
local function hit(id, x, y, w, h) return { id = id, x = x, y = y, w = w, h = h } end
local function plate(setOpen)
    inst._hit = { hit("light", 0, 38, 14, 16), hit("alarm", 22, 103, 36, 9), hit("set", 66, 103, 36, 9),
                  hit("speed", 16, 121, 44, 20), hit("start", 64, 121, 44, 20) }
    if setOpen then
        table.insert(inst._hit, 2, hit("setdn", 20, 49, 42, 38))
        table.insert(inst._hit, 3, hit("setup", 62, 49, 42, 38))
    end
end
plate(false)
local alarm = { on = true, hour = 6 }
inst._item = { isAlarmSet = function() return alarm.on end, getHour = function() return alarm.hour end,
               setHour = function(_, h) alarm.hour = h end, setMinute = function() end,
               setAlarmSet = function(_, v) alarm.on = v end }

check("251: the pad goes onto the watch", W.padOpen(0, nil) == true and JoypadState.players[1].focus == inst)
inst:_padSettle()
check("251: lands on Start (the likely action)", inst._padId == "start", inst._padId)
-- A on Start pauses (the watch's own key)
inst:onJoypadDown(Joypad.AButton, JoypadState.players[1])
check("251: A on Start pauses the game", speedNow == 0)
inst:onJoypadDown(Joypad.AButton, JoypadState.players[1])
check("251: A on Start again runs it", speedNow == 1)
-- the D-pad walks: Left from Start is Speed, Up from Speed is Alarm
inst:onJoypadDirLeft()
check("251: Left from Start: Speed", inst._padId == "speed", inst._padId)
-- SPEED grabbed: the D-pad turns it
inst:onJoypadDown(Joypad.AButton, JoypadState.players[1])
check("251: A grabs Speed", inst:padGrabbed())
inst:onJoypadDirUp()
check("251: Up on the grabbed Speed: faster (x5)", speedNow == 2, speedNow)
inst:onJoypadDirRight()
check("251: Right: faster again (x20)", speedNow == 3, speedNow)
inst:onJoypadDirDown(); inst:onJoypadDirDown(); inst:onJoypadDirDown()
check("251: Down never goes past x1 (Start pauses, not Speed)", speedNow == 1, speedNow)
check("251: grabbed, the D-pad never moves the focus", inst._padId == "speed")
local items = inst:padItems(speedNow)
check("251: the strip while grabbed: D-pad and Let go", #items == 2 and items[2].label == "UI_ZeD_Prompt_KnobLetGo")
inst:onJoypadDown(Joypad.BButton, JoypadState.players[1])
check("251: B lets go and keeps the pad", not inst:padGrabbed() and JoypadState.players[1].focus == inst)
-- to SET: Up from Speed is Alarm, Right is Set
inst:onJoypadDirUp()
check("251: Up from Speed: Alarm", inst._padId == "alarm", inst._padId)
inst:onJoypadDown(Joypad.AButton, JoypadState.players[1])
check("251: A on Alarm turns it off", alarm.on == false)
inst:onJoypadDown(Joypad.AButton, JoypadState.players[1])
check("251: A again turns it on", alarm.on == true)
inst:onJoypadDirRight()
check("251: Right from Alarm: Set", inst._padId == "set", inst._padId)
items = inst:padItems(speedNow)
check("251: the strip on Set: A Grab, B Close", items[1].label == "UI_ZeD_Prompt_KnobGrab" and items[#items].label == "UI_ZeD_Close")
inst:onJoypadDown(Joypad.AButton, JoypadState.players[1])
check("251: A grabs Set and opens the setting", inst:padGrabbed() and inst._setOpen == true)
plate(true)   -- (the set mode's keys show; the focus stays on Set)
inst:onJoypadDirUp(); inst:onJoypadDirUp()
check("251: Up twice: the alarm two hours on", alarm.hour == 8, alarm.hour)
inst:onJoypadDirLeft()
check("251: Left: one back", alarm.hour == 7, alarm.hour)
alarm.hour = 23
inst:onJoypadDirUp()
check("251: past 23 the alarm is OFF", alarm.on == false)
inst:onJoypadDirUp()
check("251: on from OFF: 0:00", alarm.on == true and alarm.hour == 0, alarm.hour)
inst:onJoypadDown(Joypad.AButton, JoypadState.players[1])
check("251: A lets go and the setting closes", not inst:padGrabbed() and inst._setOpen == false)
plate(false)
-- the setting opened by the mouse: A on Set closes it, as a click does (no grab)
inst._setOpen = true
inst:onJoypadDown(Joypad.AButton, JoypadState.players[1])
check("251: the setting open by the mouse: A on Set closes it", inst._setOpen == false and not inst:padGrabbed())
-- Start pauses from the watch, and the pad stays on it
paused = 0
inst:onJoypadDown(Joypad.Start, JoypadState.players[1])
check("251/263: Start on the watch: the game's pause", paused == 1 and JoypadState.players[1].focus == inst)
-- B: back to the game (opened from the wheel)
inst:onJoypadDown(Joypad.BButton, JoypadState.players[1])
check("251: B gives the pad back to the game", JoypadState.players[1].focus == nil)

-- opened from the belt's watch: B gives it back to the belt (which kept its place), and the popped watch tucks away
local belt = { _gp = { idx = 3 }, padReturn = function(self) setJoypadFocus(0, self); return true end }
inst._belt = true
W.togglePop = function(on) inst._popped = on and true or false end
check("251: from the belt", W.padOpen(0, belt) == true and JoypadState.players[1].focus == inst)
check("250: the belt is told to keep its place", belt._padHandoff == true)
inst._popped = true
inst:onJoypadDown(Joypad.BButton, JoypadState.players[1])
check("250/251: B: the pad back on the belt", JoypadState.players[1].focus == belt)
check("251: the popped watch tucks back", inst._popped == false)
-- the belt gone meanwhile (a car seat): B gives the pad to the game
local gone = { padReturn = function() return false end }
W.padOpen(0, gone)
inst:onJoypadDown(Joypad.BButton, JoypadState.players[1])
check("250/251: the belt gone: B gives the pad to the game", JoypadState.players[1].focus == nil)
-- another player's pad never takes the first player's watch
JoypadState.players[2] = { controller = controller }
check("251: the second player's pad: no", W.padOpen(1, nil) == false)
-- the controls' words: every control the plates carry has one
-- (Time buttons, the director, Nov 22 2026: the tape deck's speed0 .. speed3 are gone from the watch; the speed keys
-- are the belt row's, their words the game's own: hud_perf_sim checks W.padLabel for them)
local named = true
for _, id in ipairs({ "start", "speed", "alarm", "set", "crown", "light", "setdn", "setup", "alarmtoggle" }) do
    if not W.padLabel(id, 1) then named = false; print("     no words for " .. id) end
end
check("251: every control has its words on the strip", named)

-- ---------------------------------------------------------------------------
-- 250: the wiring (read from the source: the belt and the wheels need the whole game)
-- ---------------------------------------------------------------------------
local WH = read(DIR .. "ZeD_DpadWheels.lua")
check("250: the wheel has a Belt helper that hands the pad to B.focus", WH:find("function H.belt(p, pn)", 1, true) ~= nil
    and WH:find("run = function(pl, n) nextFrame(function() Bt.focus(n) end) end", 1, true) ~= nil)
check("250: the Belt slice is keyed (its quick action chord survives Loadouts on or off)", WH:find('icon = "holster", key = "belt"', 1, true) ~= nil)
local charB = WH:match("\nD%.B%.character = function%(p, pn%)(.-)\nend\n")
check("250: the Character wheel adds it last", charB ~= nil and charB:find('local belt = ask("belt", p, pn)', 1, true) ~= nil
    and charB:find("if belt then ring[#ring + 1] = belt end\n    return ring", 1, true) ~= nil)
check("251: the wheel's Open the watch gives the watch the pad", WH:find("Wt.padOpen and Wt.padOpen(n)", 1, true) ~= nil)
local BS = read(DIR .. "ZeD_Belt.lua")
check("250: A on the belt's watch opens the full watch on the pad", BS:find("ZeD.Watch.padOpen(self.playerNum, self)", 1, true) ~= nil)
check("250: the belt keeps its place for the way back", BS:find("and not self._padHandoff then self._gp = nil end", 1, true) ~= nil)
check("250: the belt takes the pad back (padReturn)", BS:find("function ZeD_BeltHUD:padReturn()", 1, true) ~= nil)
check("250: leaving the belt never takes the pad from the watch", BS:find("if jd and wi and jd.focus == wi then return end", 1, true) ~= nil)
check("250: the belt's mark only while it holds the pad", BS:find("local gpTarget = padHere and", 1, true) ~= nil)

-- (QA I10 third pass, Nov 27 2026) W.dateVisible: the game's rule from the watch he wears, not the parked clock's
-- flags (the watch parks the clock every frame, so its visible flag stays false)
do
    local function list(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end
    local oldInst = instanceof
    instanceof = function(o, cls) return type(o) == "table" and o._cls == cls end
    local digital = { _cls = "AlarmClockClothing", isDigital = function() return true end }
    local analog = { _cls = "AlarmClockClothing", isDigital = function() return false end }
    local function wearer(item)
        local worn = item and { { getItem = function() return item end, getLocation = function() return "LeftWrist" end } } or {}
        return { getWornItems = function() return list(worn) end,
                 getInventory = function() return { getItems = function() return list({}) end } end }
    end
    local oldUI = UIManager
    UIManager = { getClock = function() return { isVisible = function() return false end, isDigital = function() return false end,
                                                  isDateVisible = function() return false end } end,
                  getSpeedControls = oldUI and oldUI.getSpeedControls }
    check("I10: a digital watch worn: the date shows (the parked clock says not visible)", W.dateVisible(wearer(digital)) == true)
    check("I10: an analog watch: no date", W.dateVisible(wearer(analog)) == false)
    check("I10: no watch: no date", W.dateVisible(wearer(nil)) == false)
    UIManager = oldUI
    instanceof = oldInst
end

print("belt_watch_pad_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
