-- ZeDUI/tools/qa/window_saved_pos_sim.lua  (Nov 11 2026, Build; saved window positions)
-- With no game running. Loads the REAL files on stubs: Organisms.lua (ZeD_Window, pairKey, the two resets),
-- ZeD_WindowPlaces.lua, ZeD_WindowMenu.lua (WM.build), and cut from the window files the Character and World
-- windows' own stateOf / applyState / fitToScreen. The file under Zomboid/Lua is a table here (getFileReader /
-- getFileWriter), so a write and a fresh read are a real round trip through the text.
--   MENU     every window with Reset this window gets Save position and Go to saved position in the reset group;
--            Go to saved position is greyed with its reason while nothing is saved; a window that shows no reset,
--            or has no lasting name, gets neither
--   EACH     Character, World and a plain window (the guide) each keep their own place; saving one leaves the others
--   PAIR     the Character window's drawer (open on Skills) and inventory width come back, the drawer shut first so
--            it slides open as on a fresh open; the World window's too; the controller's stops are synced; the accent
--            is not part of a place
--   FILE     the places survive the file: dropped from memory, read again, the same numbers
--   SCREEN   a smaller screen at a bigger scale: every window lands wholly on it
--   RESET    Reset this window and Reset both windows do what they did, and leave the saved places alone
--   STATE    the per-character layout (modData ZeD_WinState) is never read by Go to saved position
--   NOTICE   Save position says so once in a Messages bubble (a repeat is the same line)
--   SELF     the windows that center themselves every frame (the guide, Messages, the seat chooser, the join window)
--            keep a move and their saved place frame after frame, clamped onto a smaller screen; Reset this window
--            centers them again; a form card docked to its drawer has no saved place
-- Run from the repo root:  lua51 ZeDUI/tools/qa/window_saved_pos_sim.lua
-- It prints FAIL lines and a last line "window_saved_pos_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]window_saved_pos_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readAll(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return s end

-- ---------------------------------------------------------------- stubs
local stub
stub = setmetatable({}, { __index = function() return stub end, __call = function() return stub end })
function require() end
local SC, SW, SH = 0.75, 1280, 800
local function setScale(sc)
    SC = sc
    ZeD.T.scale = sc
    ZeD.T.px = function(v) return math.floor(v * SC + 0.5) end
end
ZeD = setmetatable({ T = {}, Settings = { syncWindowAccent = function() end } }, { __index = function() return stub end })
setScale(0.75)
getCore = function() return { getScreenWidth = function() return SW end, getScreenHeight = function() return SH end } end

local function newWin(fields)
    local w = { x = 0, y = 0, w = 300, h = 300, minimumWidth = 0, minimumHeight = 100, resizable = true }
    for k, v in pairs(fields or {}) do w[k] = v end
    return w
end
local function giveMethods(w)
    setmetatable(w, { __index = ZeD_Window })
    function w:setX(v) self.x = v end
    function w:setY(v) self.y = v end
    function w:setWidth(v) self.w = v end
    function w:setHeight(v) self.h = v end
    function w:getX() return self.x end
    function w:getY() return self.y end
    function w:getWidth() return self.w end
    function w:getHeight() return self.h end
    function w:setWindowShaded(on) self.windowShaded = on end
    return w
end

ISPanel = { derive = function(self, n) return setmetatable({ Type = n }, { __index = self }) end }
setmetatable(_G, { __index = function() return stub end })
local fn, err = loadfile(CLIENT .. "Organisms.lua")
local ok, e = pcall(fn or error, err)
setmetatable(_G, nil)
check("Organisms.lua loads on the stubs", fn and ok, err or e)
setmetatable(ZeD, nil)
ZeD.Scale, ZeD.Curtain = nil, nil
ZeD.T.minWinW = 270
ZeD.Halves = { foldedTab = function() return nil end, forgetFold = function() end }
ZeD.tr = function(k, a) return a and (k .. "(" .. tostring(a) .. ")") or k end
ZeD.playerNumOf = function() return 0 end
local notices = {}
ZeD.Messages = { notice = function(h, t, o) notices[#notices + 1] = { h = h, t = t, key = o and o.key } end }

-- the file under Zomboid/Lua
local disk = {}
function getFileReader(name)
    local s = disk[name]
    if not s then return nil end
    local pos = 1
    return { readLine = function()
                 if pos > #s then return nil end
                 local e2 = s:find("\n", pos, true) or (#s + 1)
                 local l = s:sub(pos, e2 - 1)
                 pos = e2 + 1
                 return l
             end, close = function() end }
end
function getFileWriter(name)
    local buf = {}
    return { write = function(_, s) buf[#buf + 1] = s end, close = function() disk[name] = table.concat(buf) end }
end

-- the Character and World windows' own functions, cut from their files (their upvalues set above them)
local function cut(src, name)
    local a = src:find("local function " .. name .. "(", 1, true)
    local b = nil
    if a then local _; _, b = src:find("\nend\r?\n", a) end
    check("found " .. name, a and b)
    return (a and b) and (string.gsub(src:sub(a, b), "\r", "")) or ""
end
local function loadSide(file, head, names)
    local src = readAll(CLIENT .. file)
    local body = head
    for _, n in ipairs(names) do body = body .. cut(src, n) end
    body = body .. "return " .. names[3] .. ", " .. names[2] .. ", " .. names[1]
    local f, e2 = loadstring(body)
    check(file .. " functions load", f, e2)
    return f()
end
local cState, cApply, cFit = loadSide("ZeD_CharacterWindow.lua", "local TAB_STRIP_W, CONTAINER_STRIP_W = 36, 36\n",
    { "fitCharToScreen", "applyCharState", "charStateOf" })
local wState, wApply, wFit = loadSide("ZeD_WorldWindow.lua", "local CONTAINER_STRIP_W, ACTION_TAB_STRIP_W = 36, 36\n",
    { "fitWorldToScreen", "applyWorldState", "worldStateOf" })
check("the Character window file exports stateOf and applyState",
    readAll(CLIENT .. "ZeD_CharacterWindow.lua"):find("ZeD_CharacterWindow.stateOf = charStateOf", 1, true)
    and readAll(CLIENT .. "ZeD_CharacterWindow.lua"):find("ZeD_CharacterWindow.applyState = applyCharState", 1, true))
check("the World window file exports stateOf and applyState",
    readAll(CLIENT .. "ZeD_WorldWindow.lua"):find("ZeD_WorldWindow.stateOf = worldStateOf", 1, true)
    and readAll(CLIENT .. "ZeD_WorldWindow.lua"):find("ZeD_WorldWindow.applyState = applyWorldState", 1, true))

local CW = giveMethods(newWin({ x = 100, y = 40, w = 333, h = 315, _baseInvW = 372, _activeTab = "loot", _accentKey = "red" }))
local WW = giveMethods(newWin({ x = 644, y = 0, w = 333, h = 315, _baseInvW = 372, _activeTab = "loot" }))
local GW = giveMethods(newWin({ Type = "ZeD_GuideWindow", x = 50, y = 50, w = 600, h = 400 }))
local rings = {}
ZeD_CharacterWindow = { getWindow = function() return CW end, stateOf = cState, applyState = cApply, fitToScreen = cFit,
                        syncRing = function(w) rings[#rings + 1] = w end }
ZeD_WorldWindow = { getWindow = function() return WW end, stateOf = wState, applyState = wApply, fitToScreen = wFit,
                    syncRing = function(w) rings[#rings + 1] = w end }

local okP, eP = pcall(dofile, CLIENT .. "ZeD_WindowPlaces.lua")
check("ZeD_WindowPlaces.lua loads", okP, eP)
ZeD_ContextList = { derive = function(self, n) return setmetatable({ Type = n }, { __index = self }) end }
local okM, eM = pcall(dofile, CLIENT .. "ZeD_WindowMenu.lua")
check("ZeD_WindowMenu.lua loads", okM, eM)
local P, WM = ZeD.WindowPlaces, ZeD.WindowMenu

local function rowOf(items, key)
    for _, it in ipairs(items) do if it.name == key then return it end end
    return nil
end
local function names(items)
    local t = {}
    for _, it in ipairs(items) do if it.category == "reset" then t[#t + 1] = it.name end end
    return table.concat(t, ",")
end

-- ---------------------------------------------------------------- MENU
local cm = WM.build(CW)
check("MENU: the pair's reset group in order", names(cm) ==
    "UI_ZeD_WinMenu_ResetThis,UI_ZeD_WinMenu_ResetBoth,UI_ZeD_WinMenu_SavePos,UI_ZeD_WinMenu_GoSaved", names(cm))
check("MENU: a plain window's reset group", names(WM.build(GW)) ==
    "UI_ZeD_WinMenu_ResetThis,UI_ZeD_WinMenu_SavePos,UI_ZeD_WinMenu_GoSaved", names(WM.build(GW)))
local go = rowOf(cm, "UI_ZeD_WinMenu_GoSaved")
check("MENU: Go to saved position greyed while nothing is saved", go and go.disabled(CW) == true)
check("MENU: with its reason", go and go.state(CW) == "UI_ZeD_WinMenu_NoSaved", go and go.state(CW))
check("MENU: no saved rows on a window without Reset", names(WM.build(giveMethods(newWin({ Type = "ZeD_Keyboard", noResetControl = true })))) == "")
check("MENU: no saved rows on a plain window with no lasting name",
    names(WM.build(giveMethods(newWin({ title = "" })))) == "UI_ZeD_WinMenu_ResetThis")
check("MENU: the pause window and a prompt kind have their own ids",
    P.keyOf(giveMethods(newWin({ Type = "ZeD_MMWindow", kind = "pause" }))) == "ZeD_MMWindow.pause")

-- ---------------------------------------------------------------- EACH + PAIR (Character)
CW._activeTab, CW._drawerMode, CW._drawerOpen, CW._drawerEffW = "skills", "tab", true, 360
CW._anchorRightEdge = CW.x + CW.w
rowOf(cm, "UI_ZeD_WinMenu_SavePos").onFire()
check("NOTICE: one Messages bubble on save", #notices == 1 and notices[1].h == "UI_ZeD_WinMenu_SavedHead", #notices)
check("NOTICE: its text names the row", notices[1] and notices[1].t == "UI_ZeD_WinMenu_SavedText(UI_ZeD_WinMenu_GoSaved)", notices[1] and notices[1].t)
check("MENU: Go to saved position live after a save", not go.disabled(CW) and go.state(CW) == "")
check("EACH: the World window still has nothing saved", rowOf(WM.build(WW), "UI_ZeD_WinMenu_GoSaved").disabled(WW) == true)
check("EACH: nor the guide", rowOf(WM.build(GW), "UI_ZeD_WinMenu_GoSaved").disabled(GW) == true)
local savedChar = P.places.char
check("PAIR: no accent kept in a place", savedChar and savedChar.accentKey == nil)
check("PAIR: the drawer kept open on Skills", savedChar and savedChar.drawerOpen == true and savedChar.drawerMode == "tab" and savedChar.activeTab == "skills")

-- move it, shut its drawer, another tab, another width and accent
CW.x, CW.y, CW.w, CW._activeTab, CW._drawerOpen, CW._drawerMode, CW._baseInvW, CW._accentKey = 500, 300, 280, "loot", false, nil, 208, "blue"
CW._anchorRightEdge = CW.x + CW.w
CW._drawerCapPush = 6
rings = {}
check("PAIR: Go to saved position runs", go.onFire() ~= false)
check("PAIR: the Character window back at x 100", CW.x == 100, CW.x)
check("PAIR: and y 40", CW.y == 40, CW.y)
check("PAIR: at its base width 333", CW.w == 333, CW.w)
check("PAIR: the inventory width back (372 units)", math.abs((CW._baseInvW or 0) - 372) < 0.01, CW._baseInvW)
check("PAIR: the drawer open on Skills again", CW._drawerOpen == true and CW._drawerMode == "tab" and CW._activeTab == "skills")
check("PAIR: shut first, so it slides open (effective width 0)", CW._drawerEffW == 0, CW._drawerEffW)
check("PAIR: the cap's push dropped", CW._drawerCapPush == 0)
check("PAIR: the anchor is the saved right edge", CW._anchorRightEdge == 433, CW._anchorRightEdge)
check("PAIR: the accent left as it was", CW._accentKey == "blue", CW._accentKey)
check("PAIR: the controller's stops synced", rings[1] == CW)

-- ---------------------------------------------------------------- World, separately
WW.x, WW.y, WW._activeTab, WW._drawerMode, WW._drawerOpen, WW._baseInvW = 700, 20, "build", "tab", true, 300
WW.w = math.floor((36 + 300 + 36) * SC + 0.5)
P.save(WW)
check("EACH: the World window's save leaves the Character's", P.places.char == savedChar and P.places.world ~= nil)
WW.x, WW.y, WW._drawerOpen, WW._drawerMode, WW._activeTab = 900, 200, false, nil, "loot"
P.goTo(WW)
check("PAIR: the World window back at 700, 20", WW.x == 700 and WW.y == 20, WW.x .. "," .. WW.y)
check("PAIR: its drawer open on its tab again", WW._drawerOpen == true and WW._activeTab == "build")
check("PAIR: its anchor its right edge", WW._anchorRightEdge == WW.x + WW.w)
check("EACH: the Character window did not move", CW.x == 100 and CW.y == 40)

-- ---------------------------------------------------------------- a plain window
P.save(GW)
GW.x, GW.y, GW.w, GW.h = 10, 10, 500, 300
P.goTo(GW)
check("EACH: the guide back at 50, 50, 600 x 400", GW.x == 50 and GW.y == 50 and GW.w == 600 and GW.h == 400,
    GW.x .. "," .. GW.y .. " " .. GW.w .. "x" .. GW.h)
check("NOTICE: a repeat is the same line (one key)", #notices == 3 and notices[3].key == notices[1].key)

-- ---------------------------------------------------------------- FILE
local text = disk[P.FILE] or ""
check("FILE: written under its own name", text ~= "" and P.FILE == "ZeD_window_places.txt")
check("FILE: a line per window", select(2, text:gsub("\n", "")) == 4, text)
P.places = nil
CW.x, CW.y = 600, 400
P.goTo(CW)
check("FILE: read again, the Character window back at 100, 40", CW.x == 100 and CW.y == 40, CW.x .. "," .. CW.y)
check("FILE: the drawer fields survive the text", P.places.char.drawerOpen == true and P.places.char.activeTab == "skills")
check("FILE: the guide's numbers survive the text", math.abs(P.places.ZeD_GuideWindow.w - 800) < 0.01, P.places.ZeD_GuideWindow.w)

-- ---------------------------------------------------------------- SCREEN
SW, SH = 800, 600
setScale(1.5)
P.goTo(GW)
check("SCREEN: the guide wholly on the smaller screen", GW.x >= 0 and GW.y >= 0 and GW.x + GW.w <= SW and GW.y + GW.h <= SH,
    GW.x .. "," .. GW.y .. " " .. GW.w .. "x" .. GW.h)
P.goTo(CW)
check("SCREEN: the Character window wholly on it", CW.x >= 0 and CW.y >= 0 and CW.x + CW.w <= SW and CW.y + CW.h <= SH,
    CW.x .. "," .. CW.y .. " " .. CW.w .. "x" .. CW.h)
-- (half of 800 is 400 px; the window's least, 272 units, is 408 px at 1.5, and the least wins)
check("SCREEN: no wider than half the screen or its least width", CW.w <= math.max(SW / 2, math.floor(272 * SC + 0.5)), CW.w)
P.goTo(WW)
check("SCREEN: the World window wholly on it", WW.x >= 0 and WW.y >= 0 and WW.x + WW.w <= SW and WW.y + WW.h <= SH,
    WW.x .. "," .. WW.y .. " " .. WW.w .. "x" .. WW.h)
SW, SH = 1280, 800
setScale(0.75)

-- ---------------------------------------------------------------- RESET (both items as before)
local before = disk[P.FILE]
rowOf(WM.build(CW), "UI_ZeD_WinMenu_ResetThis").onFire()
check("RESET: Reset this window puts the Character window at the spread's left page", CW.x == 640 - 333 - 4 and CW.y == 0 and CW.w == 333, CW.x)
check("RESET: its drawer shut on Loot", CW._activeTab == "loot" and CW._drawerOpen == false)
check("RESET: the World window left where it was", WW.x ~= 644 or WW.y ~= 0)
rowOf(WM.build(WW), "UI_ZeD_WinMenu_ResetBoth").onFire()
check("RESET: Reset both windows puts the World window at 644, 0", WW.x == 644 and WW.y == 0, WW.x)
GW._zedHome = { x = 5, y = 6, w = 700, h = 500 }
rowOf(WM.build(GW), "UI_ZeD_WinMenu_ResetThis").onFire()
check("RESET: a plain window to where it first opened", GW.x == 5 and GW.y == 6 and GW.w == 700)
check("RESET: the saved places untouched", disk[P.FILE] == before and P.has(CW) and P.has(WW) and P.has(GW))

-- ---------------------------------------------------------------- STATE
local md = { ZeD_WinState = { char = { x = 1, y = 1, w = 300, h = 300 } } }
CW._playerObj = { getModData = function() return md end }
P.goTo(CW)
check("STATE: Go to saved position uses the saved place, not the modData layout", CW.x == 100 and CW.y == 40, CW.x .. "," .. CW.y)

-- ---------------------------------------------------------------- SELF (windows that place themselves)
-- QA, Nov 11: Go to saved position put the survival guide at 1281,498 at 4K and 365,150 on the Deck against its
-- saved 200,150: the middle of the screen. The guide's layout centered it every frame and took it straight back.
-- The windows that center themselves every frame now place through ZeD_Window:placeSelf, which keeps a place
-- something else gave them (a drag, the saved place); each is run here frame by frame on the real placeSelf.
SW, SH = 1280, 800
local function selfWin(ty, w, h)
    local win = giveMethods(newWin({ Type = ty, x = 0, y = 0, w = w, h = h, resizable = false }))
    win.frame = function(self) self:placeSelf(math.floor((SW - self.w) / 2), math.floor((SH - self.h) / 2), 0, 0, SW, SH) end
    return win
end
for _, kind in ipairs({ { "ZeD_GuideWindow", 548, 500 }, { "ZeD_MessagesWindow", 520, 420 }, { "ZeD_SeatChooser", 300, 260 },
                        { "ZeD_JoinWindow", 640, 480 } }) do
    local n = kind[1]
    P.places = {}
    local sw0 = selfWin(n, kind[2], kind[3])
    sw0:frame()
    local cx, cy = math.floor((SW - sw0.w) / 2), math.floor((SH - sw0.h) / 2)
    check("SELF " .. n .. ": opens in the middle", sw0.x == cx and sw0.y == cy, sw0.x .. "," .. sw0.y)
    sw0:setX(200); sw0:setY(150)   -- (QA's move: what a drag does)
    sw0:frame()
    check("SELF " .. n .. ": a move stays (the next frame does not center it)", sw0.x == 200 and sw0.y == 150, sw0.x .. "," .. sw0.y)
    P.save(sw0)
    sw0:setX(0); sw0:setY(0)
    sw0:frame()
    P.goTo(sw0)
    for _ = 1, 3 do sw0:frame() end
    check("SELF " .. n .. ": Go to saved position lands exactly on the saved place, frames after", sw0.x == 200 and sw0.y == 150,
        sw0.x .. "," .. sw0.y)
    -- a smaller screen: the place clamped onto it, and kept there
    SW, SH = 640, 480
    sw0:setX(500); sw0:setY(400)
    for _ = 1, 2 do sw0:frame() end
    check("SELF " .. n .. ": off a smaller screen, clamped onto it", sw0.x >= 0 and sw0.y >= 0 and sw0.x + sw0.w <= math.max(SW, sw0.w)
        and sw0.y + sw0.h <= math.max(SH, sw0.h), sw0.x .. "," .. sw0.y)
    SW, SH = 1280, 800
    sw0._zedHome = { x = cx, y = cy, w = sw0.w, h = sw0.h }
    sw0:resetWindow()
    for _ = 1, 2 do sw0:frame() end
    check("SELF " .. n .. ": Reset this window gives it the middle again", sw0.x == cx and sw0.y == cy, sw0.x .. "," .. sw0.y)
end
-- the files: each of those windows places itself through placeSelf, and sets no place of its own beside it
local SELF_FILES = {
    { "ZeD_SurvivalGuide.lua", "function ZeD_GuideWindow:layout()" },
    { "ZeD_MessagesWindow.lua", "function ZeD_MessagesWindow:layout()" },
    { "ZeD_SeatChooser.lua", "function ZeD_SeatChooser:layout()" },
    { "ZeD_CommunityCards.lua", "function ZeD_JoinWindow:place()" },
}
for _, sf in ipairs(SELF_FILES) do
    local src = string.gsub(readAll(CLIENT .. sf[1]), "\r", "")
    local a = src:find(sf[2], 1, true)
    -- (the function's body: up to its own closing "end" at its indent)
    local ind = a and src:sub(1, a - 1):match("([ \t]*)$") or ""
    local _, e = src:find("\n" .. ind .. "end\n", a or 1, true)
    local body = (a and e) and src:sub(a, e) or ""
    check("SELF " .. sf[1] .. ": its placing goes through placeSelf", body:find("self:placeSelf(", 1, true) ~= nil)
    check("SELF " .. sf[1] .. ": no setX / setY of its own there", body ~= "" and not body:find("self:setX(", 1, true)
        and not body:find("self:setY(", 1, true), #body)
end
-- a form card docked to its drawer has no saved place (its box places it every frame); loose, it has one
check("SELF: a docked form card has no saved place", P.keyOf(giveMethods(newWin({ Type = "ZeD_FormCard", zedDocked = true }))) == nil)
check("SELF: a loose form card has one", P.keyOf(giveMethods(newWin({ Type = "ZeD_FormCard" }))) == "ZeD_FormCard")
check("SELF: ZeD_FormCard.lua marks a docked card", readAll(CLIENT .. "ZeD_FormCard.lua"):find("self.zedDocked = dp ~= nil", 1, true) ~= nil)

print("window_saved_pos_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
