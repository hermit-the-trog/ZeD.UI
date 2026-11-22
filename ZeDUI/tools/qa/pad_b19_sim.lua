-- ZeDUI/tools/qa/pad_b19_sim.lua
-- (beta 19, Nov 16 2026) The controller fixes of punch list 228e-p and 218, run outside the game: each fix's own
-- function is cut from the source by pattern and run with stubs.
--   228g  the on-screen keyboard put away with nothing to go back to: the pad no longer goes to the bare text box
--   228m  Hair | Beard: Left / Right stop at the switch's ends, Up / Down still leave
--   228n  Messages: Up from the cards' panel (let go) goes to the window box above it (228i), else the list
--   228i  Messages and the Reader: the window box is a stop, A opens its menu
--   228p  the window menu has Controller map (with a pad) and Hide interface, as the Select wheel does
--   218   A at a door: one toggle, never two, when the game's own A acts on the release as well
--   228e / 228f  source checks: the prompts take the pad, the four windows give it back through padBack
-- Run from the repo root: lua51 ZeDUI/tools/qa/pad_b19_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]pad_b19_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if ok then print("ok   " .. name) else failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readSrc(p)
    local fh = assert(io.open(ROOT .. "42/media/lua/client/ZeD/" .. p, "rb"))
    local s = fh:read("*a"):gsub("\r\n", "\n")
    fh:close()
    return s
end
local function has(s, needle) return s:find(needle, 1, true) ~= nil end

-- ---------------------------------------------------------------------------
-- 228g: ZeD_Keyboard:hide
-- ---------------------------------------------------------------------------
local kb = readSrc("ZeD_Keyboard.lua")
local hideBody = kb:match("\nfunction ZeD_Keyboard:hide%(%).-\nend\n")
check("finds ZeD_Keyboard:hide", hideBody ~= nil)
if hideBody then
    local KBT = {}
    assert(loadstring("local ZeD_Keyboard = ...\n" .. hideBody))(KBT)
    local menuClosedArgs = nil
    ZeD = { Input = { Focus = { menuClosed = function(m, pn) menuClosedArgs = { m, pn } end } } }
    updateJoypadFocus = function() end
    local function kbd(prev)
        local entry = { focused = false }
        function entry:focus() self.focused = true end
        local k = setmetatable({ playerNum = 0, textEntryBox = entry, prevFocus = prev }, { __index = KBT })
        function k:setVisible() end
        function k:removeFromUIManager() end
        local jd = { player = 0 }
        jd.focus = k
        k.joyfocus = jd
        return k, jd, entry
    end
    local k, jd, entry = kbd(nil)
    k:hide()
    check("228g: nothing to go back to: the pad is not left on the bare text box", jd.focus ~= entry, tostring(jd.focus))
    check("228g: it goes back the way a ZeD menu's does (Focus.menuClosed, the keyboard, its player)",
        menuClosedArgs ~= nil and menuClosedArgs[1] == k and menuClosedArgs[2] == 0)
    local back = {}
    menuClosedArgs = nil
    k, jd = kbd(back)
    k:hide()
    check("228g: with something named, the pad goes back to it", jd.focus == back and menuClosedArgs == nil)
    ZeD = { Input = {} }
    k, jd, entry = kbd(nil)
    k:hide()
    check("228g: no Focus at all: the pad goes to the game, not the text box", jd.focus == nil)
end

-- ---------------------------------------------------------------------------
-- 228m: the Hair | Beard switch's D-pad handler
-- ---------------------------------------------------------------------------
local hb = readSrc("ZeD_HairBeard.lua")
local partBlock = hb:match('id = "hb:part",(.-)onActivate')
local dirFn = partBlock and partBlock:match("onDpadDir = (function%(w, el, dir%).-\n%s*end),")
check("finds the Hair | Beard switch's onDpadDir", dirFn ~= nil)
check("228m: the switch still says dpadExits (Up / Down leave)", partBlock ~= nil and has(partBlock, "dpadExits = true"))
if dirFn then
    local st = { part = "hair" }
    local HBT = { setPart = function(w, p) st.part = p end }
    local partsOf = function() return { "hair", "beard" } end
    local fn = assert(loadstring("local partsOf, st, HB = ...\nreturn " .. dirFn))(partsOf, st, HBT)
    check("228m: Left at Hair (the left end) stops there", fn(nil, nil, "left") == true and st.part == "hair", st.part)
    check("228m: Right from Hair moves to Beard", fn(nil, nil, "right") == true and st.part == "beard", st.part)
    check("228m: Right at Beard (the right end) stops there", fn(nil, nil, "right") == true and st.part == "beard", st.part)
    check("228m: Up leaves the switch", fn(nil, nil, "up") == false)
    check("228m: Down leaves the switch", fn(nil, nil, "down") == false)
end

-- ---------------------------------------------------------------------------
-- 228n / 228i: the Messages window's D-pad and A
-- ---------------------------------------------------------------------------
local mw = readSrc("ZeD_MessagesWindow.lua")
local upBody = mw:match("\nfunction ZeD_MessagesWindow:onJoypadDirUp%(%).-\nend\n")
local downBody = mw:match("\nfunction ZeD_MessagesWindow:onJoypadDirDown%(%).-\nend\n")
local aBody = mw:match("\nfunction ZeD_MessagesWindow:onJoypadDown%(button, joypadData%).-\nend\n")
check("finds the Messages window's Up, Down and A", upBody ~= nil and downBody ~= nil and aBody ~= nil)
if upBody and downBody and aBody then
    local MWT = {}
    local sel = { "ModA", "ModB" }
    local scrolled = 0
    local sourcesInOrder = function() return sel end
    local padScroll = function(_, d) scrolled = scrolled + d end
    local sound = function() end
    local hdr = "local ZeD_MessagesWindow, sourcesInOrder, padScroll, sound = ...\n"
    assert(loadstring(hdr .. upBody))(MWT, sourcesInOrder, padScroll, sound)
    assert(loadstring(hdr .. downBody))(MWT, sourcesInOrder, padScroll, sound)
    assert(loadstring(hdr .. aBody))(MWT, sourcesInOrder, padScroll, sound)
    Joypad = { AButton = 1, BButton = 2 }
    local menuOpened = 0
    local WMS = {}
    ZeD = { WindowMenu = WMS }
    local function win(box)
        local w = setmetatable({ zone = "list", sel = "ModA", _g = { cards = { {} } } }, { __index = MWT })
        function w:windowBoxRect() return box and { x = 1, y = 1, w = 8, h = 8 } or nil end
        function w:choose(n) self.sel = n end
        function w:openWindowMenu() menuOpened = menuOpened + 1; WMS.current = { win = self } end
        return w
    end
    local w = win(true)
    w.zone, w.cardsGrab = "cards", nil
    w:onJoypadDirUp()
    check("228n: Up from the cards' panel (let go) goes to the window box above it", w.zone == "box", w.zone)
    w = win(false)
    w.zone, w.cardsGrab = "cards", nil
    w:onJoypadDirUp()
    check("228n: with no window box, Up from the panel goes to the list", w.zone == "list", w.zone)
    w = win(true)
    w.zone, w.cardsGrab = "cards", true
    w:onJoypadDirUp()
    check("228n: a grabbed panel still scrolls on Up", w.zone == "cards" and scrolled == -1, w.zone)
    w = win(true)
    w.zone, w.sel = "list", "ModB"
    w:onJoypadDirUp()
    check("228i: Up in the list moves up a row first", w.zone == "list" and w.sel == "ModA", w.sel)
    w:onJoypadDirUp()
    check("228i: Up from the list's top row reaches the window box", w.zone == "box", w.zone)
    w:onJoypadDown(Joypad.AButton, {})
    check("228i: A on the window box opens the window's menu, and B there comes back to this window",
        menuOpened == 1 and WMS.current and WMS.current.origin == w)
    w:onJoypadDirDown()
    check("228i: Down from the window box goes to the panel under it", w.zone == "cards" and not w.cardsGrab, w.zone)
    w = win(true)
    w._g.cards = {}
    w.zone = "box"
    w:onJoypadDirDown()
    check("228i: Down from the window box with no cards goes to the list", w.zone == "list", w.zone)
    check("228i: the Messages window draws the box's mark itself", has(mw, 'self.zone == "box" then') and has(mw, "ZeD.Focus.mark(self, wb.x, wb.y, wb.w, wb.h"))
end

-- the Reader: Up at the page's top reaches the box, A opens the menu, Down comes back
local rd = readSrc("ZeD_Reader.lua")
local atTopBody = rd:match("\nfunction ZeD_Reader:atTop%(%).-\nend\n")
local rUp = rd:match("\nfunction ZeD_Reader:onJoypadDirUp%(%).-\nend\n")
local rDown = rd:match("\nfunction ZeD_Reader:onJoypadDirDown%(%)[^\n]*\n")
local rA = rd:match("\nfunction ZeD_Reader:onJoypadDown%(button, joypadData%).-\nend\n")
check("finds the Reader's atTop, Up, Down and A", atTopBody ~= nil and rUp ~= nil and rDown ~= nil and rA ~= nil)
if atTopBody and rUp and rDown and rA then
    local RT = {}
    local hdr = "local ZeD_Reader, STEP, sound = ...\n"
    for _, b in ipairs({ atTopBody, rUp, rDown, rA }) do assert(loadstring(hdr .. b))(RT, 60, function() end) end
    Joypad = { AButton = 1, BButton = 2, LBumper = 3, RBumper = 4, XButton = 5, YButton = 6 }
    local opened = 0
    local WMS = {}
    ZeD = { T = { px = function(v) return v end }, WindowMenu = WMS }
    local r = setmetatable({ mode = "print", view = "words", wscroll = 120, places = {} }, { __index = RT })
    function r:windowBoxRect() return { x = 1, y = 1, w = 8, h = 8 } end
    function r:openWindowMenu() opened = opened + 1; WMS.current = { win = self } end
    r:onJoypadDirUp()
    check("228i: the Reader scrolls up while it is not at the top", r.wscroll == 60 and not r.padBox, r.wscroll)
    r.wscroll = 0
    r:onJoypadDirUp()
    check("228i: Up at the Reader's top reaches the window box", r.padBox == true)
    r:onJoypadDown(Joypad.AButton, {})
    check("228i: A on the Reader's window box opens its menu, with the Reader as its origin", opened == 1 and WMS.current.origin == r)
    r:onJoypadDirDown()
    check("228i: Down from the Reader's window box goes back to the page", not r.padBox and r.wscroll == 0, r.wscroll)
    r.view, r.page, r.panY, r._panMaxY = "paper", {}, 40, 40
    r:onJoypadDirUp()
    check("228i: a page panned to its top: Up reaches the window box", r.padBox == true)
end
check("228i: the Reader draws the box's mark and resets it on opening",
    has(rd, "if self.padBox and self.joyfocus and ZeD.Focus and ZeD.Focus.mark then") and has(rd, "win.padBox = nil"))

-- ---------------------------------------------------------------------------
-- 228p: the window menu's new rows (the block run as written, with stubs)
-- ---------------------------------------------------------------------------
local wm = readSrc("ZeD_WindowMenu.lua")
local block = wm:match("\n(    %-%- %(punch list 228p.-)\n    items%[#items %+ 1%] = { name = tr%(\"UI_ZeD_WinMenu_Setup\"%)")
check("finds the window menu's 228p rows, before ZeD setup", block ~= nil)
if block then
    local fn = assert(loadstring("local items, tr, pn = ...\n" .. block))
    local cmOpened, hidden = nil, 0
    local tr = function(k) return k end
    ZeD = { ControllerMap = { open = function(n) cmOpened = n end },
            DpadWheels = { H = { hideInterface = function() hidden = hidden + 1 end } } }
    JoypadState = { players = { {} } }
    local items = {}
    fn(items, tr, 0)
    local byName = {}
    for _, it in ipairs(items) do byName[it.name] = it end
    check("228p: Controller map is in the menu with a pad", byName["UI_ZeD_Wheel_ControllerMap"] ~= nil and byName["UI_ZeD_Wheel_ControllerMap"].category == "setup")
    check("228p: Hide interface is not in the mouse's menu (QA K1-6)", byName["UI_ZeD_Wheel_HideInterface"] == nil)
    if byName["UI_ZeD_Wheel_ControllerMap"] then byName["UI_ZeD_Wheel_ControllerMap"].onFire() end
    check("228p: Controller map opens the wheel's map for this player", cmOpened == 0)
    JoypadState = { players = {} }
    items = {}
    fn(items, tr, 0)
    local cm = false
    for _, it in ipairs(items) do if it.name == "UI_ZeD_Wheel_ControllerMap" then cm = true end end
    check("228p: no pad, no Controller map, nothing else in the block", not cm and #items == 0, #items)
end
local dw = readSrc("ZeD_DpadWheels.lua")
check("228p: the wheel's own hide is the one the menu calls (H.hideInterface)", has(dw, "function H.hideInterface()"))

-- ---------------------------------------------------------------------------
-- 218: A at a door, the whole file run with stubs
-- ---------------------------------------------------------------------------
do
    local onUpdate = {}
    local function ev() return { Add = function() end } end
    Events = { OnGameBoot = ev(), OnGameStart = ev(), OnCreatePlayer = ev(),
               OnPlayerUpdate = { Add = function(f) onUpdate[#onUpdate + 1] = f end } }
    ZeD = {}
    ISPlace3DItemCursor = nil
    local aDown = false
    JoypadButton = { A = { isDown = function() return aDown end } }
    CharacterJoypadButtonBinding = { Interact = { getJoypadButton = function() return JoypadButton.A end } }
    local drag = nil
    getCell = function() return { getDrag = function() return drag end } end
    local function door(open) return { kind = "IsoDoor", open = open, IsOpen = function(self) return self.open end } end
    instanceof = function(o, k) return o ~= nil and o.kind == k end
    local player = { ign = false }
    function player:isIgnoreContextKey() return self.ign end
    function player:setIgnoreContextKey(v) self.ign = v end
    function player:isLocalPlayer() return true end
    function player:getPlayerNum() return 0 end
    getSpecificPlayer = function() return player end
    local toggles = 0
    -- the game's own handler, as the right-click menu runs it (the timed action toggles at once here)
    ISWorldObjectContextMenu = { onOpenCloseDoor = function(_, d) toggles = toggles + 1; d.open = not d.open end,
                                 onOpenCloseWindow = function(_, w) toggles = toggles + 1; w.open = not w.open end }
    -- the game's prompt: the door's words, no function (Java does the press)
    ISButtonPrompt = {}
    function ISButtonPrompt.doInteractButtonDoorOrWindowOrWindowFrame(self, dir, obj)
        self.aPrompt = obj:IsOpen() and "Close door" or "Open door"
        self.aFunc, self.aParams = nil, {}
    end
    JoypadState = { players = { { id = 7, player = 0 } } }
    local src = readSrc("Overrides/PlaceItemPad.lua")
    local chunk = assert(loadstring(src))
    local _print = print
    print = function() end
    chunk()
    print = _print
    local function update() for _, f in ipairs(onUpdate) do f(player) end end
    -- Java's doContext on A's release: it toggles unless the player ignores the context key
    local function javaRelease(d) if not player:isIgnoreContextKey() then toggles = toggles + 1; d.open = not d.open end end

    local d = door(false)
    local bp = { player = 0 }
    ISButtonPrompt.doInteractButtonDoorOrWindowOrWindowFrame(bp, nil, d)
    check("218: the door's A prompt now has a function", type(bp.aFunc) == "function" and bp.aParams[1] == d)
    aDown = true
    bp.aFunc(bp, bp.aParams[1])   -- (onAPress: self:aFunc(param1))
    check("218: A opens the door through the game's Open / Close", toggles == 1 and d.open == true, toggles)
    check("218: the press holds the context key while A is down", player.ign == true)
    update(); update(); update(); update()
    check("218: held A keeps the context key held", player.ign == true)
    aDown = false
    javaRelease(d)
    check("218: Java's release does not toggle it a second time", toggles == 1 and d.open == true, toggles)
    update(); update()
    check("218: two updates after the release the key is still held", player.ign == true)
    update()
    check("218: three updates after the release the key is let go", player.ign == false)
    javaRelease(d)
    check("218: (a later press of Java's own acts again, the flag gone)", toggles == 2)

    -- another holder's flag (the Place Item guard, a mod) is left alone
    toggles = 0
    player.ign = true
    d = door(false)
    bp = { player = 0 }
    ISButtonPrompt.doInteractButtonDoorOrWindowOrWindowFrame(bp, nil, d)
    bp.aFunc(bp, bp.aParams[1])
    update(); update(); update(); update()
    check("218: a context key someone else set is never cleared here", player.ign == true and toggles == 1)
    player.ign = false

    -- a keyboard player's prompt (the hint strip's copy) keeps the game's nil
    JoypadState = { players = {} }
    bp = { player = 0 }
    ISButtonPrompt.doInteractButtonDoorOrWindowOrWindowFrame(bp, nil, door(false))
    check("218: a player with no pad keeps the game's prompt (no function)", bp.aFunc == nil and bp.aPrompt ~= nil)
    JoypadState = { players = { { id = 7, player = 0 } } }

    local origDo = ISButtonPrompt.doInteractButtonDoorOrWindowOrWindowFrame
    check("218: the wrap goes on once (the _zed flag)", ISButtonPrompt._zedPadDoor == true and ZeD.PadDoor and ZeD.PadDoor.wrap ~= nil)
    ZeD.PadDoor.wrap()
    check("218: a second wrap call does not wrap the wrapper", ISButtonPrompt.doInteractButtonDoorOrWindowOrWindowFrame == origDo)
end

-- ---------------------------------------------------------------------------
-- 228e / 228f: source checks
-- ---------------------------------------------------------------------------
local vif = readSrc("ModSupport/VIF_DualRender_B42.lua")
check("228e: the folder name prompt takes the pad and remembers what had it",
    has(vif, "box.prevFocus = getJoypadFocus(playerNum)") and has(vif, "setJoypadFocus(playerNum, box)"))
check("228e: the safe-mode question gives the pad back to the focused ZeD window",
    has(dw, "modal.prevFocus = Fo.getFocusedWindow(pn)"))
for _, f in ipairs({ "ZeD_MessagesWindow.lua", "ZeD_SirenController.lua", "ZeD_CarRadio.lua", "ZeD_Reader.lua" }) do
    local s = readSrc(f)
    check("228f: " .. f .. " notes what held the pad (padFrom) and gives it back (padBack)",
        has(s, "ZeD.Seats.padFrom(") and has(s, "padBack(self)"))
end
check("228f: Messages keeps its guest branch", has(mw, "elseif own and (not wasGuest or own.focus == self) then setJoypadFocus(self.playerNum, nil) end"))
local fm = readSrc("Input/FocusManager.lua")
check("217: the Y tap's hide is timed ([ZeD.LagClose])", has(fm, "Focus.lagClose(t0)") and has(fm, '"[ZeD.LagClose] hide "'))

print("pad_b19_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
