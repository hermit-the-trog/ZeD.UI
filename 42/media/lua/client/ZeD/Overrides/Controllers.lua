-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Controllers.lua
-- ============================================================================
-- CONTROLLERS JOINING AND LEAVING (vanilla windows B12 and B13; the director,
-- Nov 7 2026: no ZeD prompts for these, they go into ZeD's notifications. "A
-- bubble pops up saying Controller plugged in or Controller unplugged, and the
-- notice is kept in Messages like the others"; the join choices "open from
-- that notice, or from Messages, on the new controller. They are no longer a
-- pop-up in the middle of play.")
--
--   * A press on a controller nobody plays with (the game's
--     JoypadControllerData:onPressButtonNoFocus) made ISJoypadListBox.Create
--     put its list in the middle of the screen. ISJoypadListBox.Create now
--     gives the game a stand-in that shows nothing: its fill files the notice
--     "Controller plugged in" in Messages (a bubble out of the note on the
--     belt) with the game's own choices as the note's buttons (Take over
--     player 1, Add new player, Add <saved player>: the game's fill, read on a
--     stand-in list, so the rules and words are the game's). The stand-in
--     holds that controller's focus, as the game's list did: A on it opens
--     Messages on the note with that controller (D-pad to a choice, A takes
--     it), B lets go. With the mouse, the bubble or Messages, then a button.
--     A choice runs the game's own command (ISJoypadListBox:invoke on a
--     stand-in of its list), so taking over, a new player (the game's
--     character creation) and a saved one are the game's.
--   * A player's controller unplugged (onJoypadDeactivate) made
--     ISJoypadDisconnectedUI in the middle of that player's screen. Its :new
--     now gives a stand-in: shown, it files "Controller unplugged" (player one
--     also gets the game's Use keyboard and mouse as the note's button);
--     taken away when the controller comes back (onJoypadReactivate), it files
--     "Controller plugged in". One note per controller or player: the newest
--     replaces the one before it.
--   * A controller plugged in while playing (OnGamepadConnect) that is no
--     player's yet: "Controller plugged in", press A on it to join.
-- Safe mode, and anything before a game is loaded, keep the game's windows.
-- ============================================================================

require "ZeD/SafeMode"
require "ZeD/ZeD_Messages"

ZeD = ZeD or {}
ZeD.PadJoin = ZeD.PadJoin or {}
local PJ = ZeD.PadJoin

local function noop() end
local function inGame()
    if ZeD.Safe.on() or not getPlayer() then return false end
    return not (MainScreen and MainScreen.instance and MainScreen.instance.inGame == false and MainScreen.instance:isReallyVisible())
end
PJ.inGame = inGame

-- ---------------------------------------------------------------------------
-- the game's choices for a controller (ISJoypadListBox:fill on a stand-in list); Cancel stays out (the note waits)
-- ---------------------------------------------------------------------------
function PJ.choices(joypadData)
    local out = {}
    if not (ISJoypadListBox and ISJoypadListBox.fill) then return out end
    local items = {}
    local list = { items = items, font = UIFont.Small, joypadData = joypadData, selected = 1 }
    function list:clear() for i = #items, 1, -1 do items[i] = nil end end
    function list:addItem(text, item) items[#items + 1] = { text = text, item = item } end
    function list:size() return #items end
    list.setScrollHeight, list.setWidth, list.setHeight = noop, noop, noop
    function list:getScrollHeight() return 0 end
    local ok, err = pcall(ISJoypadListBox.fill, list)
    if not ok then print("[ZeD] Controllers: the game's join list: " .. tostring(err)) end
    for _, e in ipairs(items) do
        if e.item and e.item.cmd ~= "cancel" then out[#out + 1] = { label = tostring(e.text), item = e.item } end
    end
    return out
end

-- the same choice in a fresh list: the same command and the same words (a saved player comes back as a new object
-- each time the game lists them, so its words, which carry its name, say which it is)
local function same(a, b)
    return a.item.cmd == b.item.cmd and a.item.playerNum == b.item.playerNum and a.label == b.label
end

-- run a choice: the game's own command (its invoke on a stand-in of its list), still on offer, from a fresh list
function PJ.run(joypadData, choice)
    if not (joypadData and choice and choice.item and ISJoypadListBox) then return false end
    local still = nil
    for _, c in ipairs(PJ.choices(joypadData)) do if same(c, choice) then still = c.item end end
    if not still then PJ.notice(joypadData); return false end   -- (the choice went away: the note offers what is left)
    local box = setmetatable({ joypadData = joypadData, items = { { item = still } }, selected = 1 }, { __index = ISJoypadListBox })
    box.setVisible, box.removeFromUIManager = noop, noop
    joypadData.activeWhilePaused = nil
    local ok, err = pcall(box.invoke, box)
    if not ok then print("[ZeD] Controllers: joining: " .. tostring(err)); return false end
    return true
end

-- "Controller plugged in" for a controller nobody plays with, with the game's choices as its buttons
function PJ.notice(joypadData)
    local id = "c" .. tostring(joypadData and joypadData.id)
    local buttons = {}
    for _, c in ipairs(PJ.choices(joypadData)) do
        local choice = c
        buttons[#buttons + 1] = { label = c.label, run = function() return PJ.run(joypadData, choice) end }
    end
    local text = ZeD.tr(#buttons > 0 and "UI_ZeD_Pad_ChooseText" or "UI_ZeD_Pad_NoRoomText")
    return ZeD.Messages.pad(id, ZeD.tr("UI_ZeD_Pad_PluggedIn"), text, buttons)
end

-- ---------------------------------------------------------------------------
-- the stand-in for the game's join list: the controller's focus, nothing on the screen
-- ---------------------------------------------------------------------------
local Stub = {}
Stub.__index = Stub
function PJ.stub(playerNum, joypadData)
    return setmetatable({ playerNum = playerNum, joypadData = joypadData, parent = nil, _zedPadStub = true }, Stub)
end
function Stub:fill() PJ.notice(self.joypadData) end
Stub.setVisible, Stub.addToUIManager, Stub.removeFromUIManager = noop, noop, noop
Stub.onGainJoypadFocus, Stub.onLoseJoypadFocus, Stub.onJoypadButtonReleased = noop, noop, noop
Stub.onJoypadDirUp, Stub.onJoypadDirDown, Stub.onJoypadDirLeft, Stub.onJoypadDirRight = noop, noop, noop, noop
function Stub:isVisible() return false end
function Stub:isReallyVisible() return false end
function Stub:getJoypadNavigateStartDelay() return 250 end
-- A: Messages on the note, with this controller; B: let go (the next A files the note again)
function Stub:onJoypadDown(button, joypadData)
    local jd = joypadData or self.joypadData
    if button == Joypad.AButton then
        local name = ZeD.tr("UI_ZeD_Pad_Source")
        local W = ZeD.MessagesWindow
        if W and W.openGuest then W.openGuest(jd, name) end
    elseif button == Joypad.BButton then
        if jd.focus == self then jd.focus, jd.lastfocus = nil, nil end
        jd.listBox, jd.activeWhilePaused = nil, nil
    end
end

-- ---------------------------------------------------------------------------
-- the stand-in for the game's "controller disconnected" banner
-- ---------------------------------------------------------------------------
-- the guest Messages window a controller drives lets it go (that controller unplugged)
function PJ.dropGuest(jd)
    local W = ZeD.MessagesWindow
    local win = W and W.get and W.get(0)
    if win and jd and win.guestJoy == jd then pcall(win.close, win) end
end

function PJ.unplugged(playerNum)
    local buttons = nil
    if playerNum == 0 and ISJoypadDisconnectedUI and ISJoypadDisconnectedUI.setKeyboardMouseActivated then
        buttons = { { label = getText("IGUI_Controller_Disconnected2"),
                      run = function()
                          ISJoypadDisconnectedUI.setKeyboardMouseActivated()
                          -- (player one is on the mouse now: a later plug-in is a new controller, not one back)
                          local jd = JoypadState and JoypadState.joypads and JoypadState.joypads[1]
                          if jd then jd.disconnectedUI = nil end
                          PJ._kbm = true
                          return true
                      end } }
    end
    return ZeD.Messages.pad("p" .. tostring(playerNum), ZeD.tr("UI_ZeD_Pad_Unplugged"),
        ZeD.tr("UI_ZeD_Pad_UnpluggedText", tostring((playerNum or 0) + 1)), buttons, playerNum)
end
function PJ.replugged(playerNum)
    if playerNum == 0 and PJ._kbm then PJ._kbm = nil; return nil end
    return ZeD.Messages.pad("p" .. tostring(playerNum), ZeD.tr("UI_ZeD_Pad_PluggedIn"),
        ZeD.tr("UI_ZeD_Pad_BackText", tostring((playerNum or 0) + 1)), nil, playerNum)
end
function PJ.disconnectedStub(playerNum)
    local s = { playerNum = playerNum, _zedPadStub = true }
    s.setAlwaysOnTop, s.setVisible, s.initialise, s.instantiate = noop, noop, noop, noop
    s.addToUIManager = function() PJ._kbm = nil; PJ.unplugged(playerNum) end
    s.removeFromUIManager = function() PJ.replugged(playerNum) end
    s.isReallyVisible = function() return false end
    s.useKeyboardMouse = function() ISJoypadDisconnectedUI.setKeyboardMouseActivated() end
    return s
end

-- a controller plugged in while playing that is nobody's yet: the note waits for its A
function PJ.onConnect(id)
    if not inGame() then return end
    local c = JoypadState and JoypadState.controllers and JoypadState.controllers[id]
    local jd = c and c.joypad
    if jd and jd.player ~= nil then return end   -- (a player's own controller back: the reactivation says so)
    ZeD.Messages.pad("c" .. tostring(id), ZeD.tr("UI_ZeD_Pad_PluggedIn"), ZeD.tr("UI_ZeD_Pad_PressAText"), nil)
end

-- ---------------------------------------------------------------------------
-- the hooks (asked at call time: safe mode keeps the game's windows)
-- ---------------------------------------------------------------------------
local function apply()
    if ISJoypadListBox and ISJoypadListBox.Create and not ISJoypadListBox._zedJoin then
        local vanilla = ISJoypadListBox.Create
        ISJoypadListBox._zedJoin = vanilla
        ISJoypadListBox.Create = function(playerNum, joypadData, ...)
            if not inGame() then return vanilla(playerNum, joypadData, ...) end
            return PJ.stub(playerNum, joypadData)
        end
    end
    if ISJoypadDisconnectedUI and ISJoypadDisconnectedUI.new and not ISJoypadDisconnectedUI._zedNote then
        local vanilla = ISJoypadDisconnectedUI.new
        ISJoypadDisconnectedUI._zedNote = vanilla
        ISJoypadDisconnectedUI.new = function(self, playerNum, ...)
            if not inGame() then return vanilla(self, playerNum, ...) end
            return PJ.disconnectedStub(playerNum)
        end
    end
    print("[ZeD] Overrides/Controllers: controllers joining and leaving go to Messages")
end

function PJ.onDisconnect(id)
    local c = JoypadState and JoypadState.controllers and JoypadState.controllers[id]
    if c and c.joypad then PJ.dropGuest(c.joypad) end
end

if Events then
    if Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
    if Events.OnJoypadDeactivate and not PJ._dropHooked then
        PJ._dropHooked = true
        Events.OnJoypadDeactivate.Add(function(id) pcall(PJ.onDisconnect, id) end)
    end
    if Events.OnGamepadConnect and not PJ._connectHooked then
        PJ._connectHooked = true
        Events.OnGamepadConnect.Add(function(id) pcall(PJ.onConnect, id) end)
    end
end
apply()
