-- Load, Join and Host menu fixes (QA's Nov 27 2026 menus sweep, the LJ ids). Plain Lua 5.1, nothing from the game:
-- each function is cut out of its file as it ships and run over stubs, so the logic of each fix is checked here.
local ROOT = (debug.getinfo(1, "S").source:sub(2):gsub("\\", "/"):match("^(.*)/ZeDUI/tools/qa/") or ".") .. "/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function read(rel)
    local f = assert(io.open(ROOT .. rel, "rb")); local s = f:read("*a"); f:close()
    return (s:gsub("\r\n", "\n"))
end
local function cut(src, name, pat)
    local body = src:match(pat)
    check(name .. " found", body ~= nil)
    if body then assert(loadstring(body, "@" .. name))() end
end
local function fn(src, cls, m) cut(src, cls .. ":" .. m, "(function " .. cls .. ":" .. m .. "%(.-\nend\n)") end

local SV = read("42/media/lua/client/ZeD/ZeD_MainMenuSaves.lua")
local JN = read("42/media/lua/client/ZeD/ZeD_MainMenuJoin.lua")
local HO = read("42/media/lua/client/ZeD/ZeD_MainMenuHost.lua")
local JM = read("42/media/lua/client/ZeD/ZeD_MainMenuJoinMore.lua")

-- stubs ------------------------------------------------------------------------------------------------------
local now = 1000
local pad = false
ZeD = { tr = function(k) return k end, trBare = function(k) return k end, btnCase = function(t) return t end, textCase = function(t) return t end }
MM = { now = function() return now end, hoverSound = function() end, clickSound = function() end, gamepad = function() return pad end, ctx = {} }
getText = function(k) return k end
Keyboard = { KEY_RETURN = 28, KEY_UP = 200, KEY_DOWN = 208, KEY_DELETE = 211 }
ZeD_MMWindow = { joyDir = function(self, dir) if self._walk then self._walk(self, dir) end end }
ZeD_MMLoad, ZeD_MMJoin, ZeD_MMHost = {}, {}, {}

-- LJ9: player 1 dead, another alive: the name marked dead is player 1's ----------------------------------------
fn(SV, "ZeD_MMLoad", "readPlayers")
local s9 = { info = { playerAlive = false, players = { { sqlID = 1, name = "Dead Dan", isDead = true }, { sqlID = 2, name = "Alive Al", isDead = false } } } }
ZeD_MMLoad.readPlayers({}, s9)
check("LJ9: player 1 dead: dead, and named as player 1", s9.dead == true and s9.who == "Dead Dan", tostring(s9.who))
local s9b = { info = { playerAlive = true, players = { { sqlID = 2, name = "Bea", isDead = false }, { sqlID = 1, name = "Al", isDead = false } } } }
ZeD_MMLoad.readPlayers({}, s9b)
check("LJ9: player 1 alive: plays as player 1", s9b.dead == false and s9b.who == "Al", tostring(s9b.who))

-- LJ12: New player on a save that cannot be played: no call, and greyed in More --------------------------------
fn(SV, "ZeD_MMLoad", "newPlayer")
fn(SV, "ZeD_MMLoad", "moreItems")
local setCalls, played = 0, 0
setSavefilePlayer1 = function() setCalls = setCalls + 1 end
isDesktopOpenSupported = function() return false end
local w12 = setmetatable({ sav = { mode = "Survivor", saveName = "x", key = "Survivor/x" }, reason = "UI_worldscreen_MapNotFound" }, { __index = ZeD_MMLoad })
function w12:selected() return self.sav end
function w12:whyNot() return self.reason end
function w12:play() played = played + 1 end
w12:newPlayer()
check("LJ12: an unplayable save is never set to a new character", setCalls == 0 and played == 0, setCalls)
check("LJ12: New player greyed in More for it", w12:moreItems()[2].disabled == true)
w12.reason = nil
w12:newPlayer()
check("LJ12: a playable save: New player as before", setCalls == 1 and played == 1)
check("LJ12: New player live in More for it", w12:moreItems()[2].disabled == false)

-- LJ18: click, arrow off and back, click: no play --------------------------------------------------------------
fn(SV, "ZeD_MMLoad", "clickSave")
fn(SV, "ZeD_MMLoad", "joyDir")
local plays = 0
local order = { "save:A", "save:B" }
local w18 = setmetatable({ sel = nil, focusId = nil, scroll = 0, _list = { h = 1000 }, _specs = {
    { id = "save:A", listRow = true, key = "A", ry = 0, rh = 10 }, { id = "save:B", listRow = true, key = "B", ry = 10, rh = 10 } } }, { __index = ZeD_MMLoad })
function w18:play() plays = plays + 1 end
w18._walk = function(self, dir)
    for i, id in ipairs(order) do
        if id == self.focusId then self.focusId = order[i + (dir == "down" and 1 or -1)] or id; return end
    end
end
w18:clickSave({ key = "A" })
now = now + 100; w18:joyDir("down")
now = now + 100; w18:joyDir("up")
now = now + 100; w18:clickSave({ key = "A" })
check("LJ18: a click after the pick moved off and back is not a double click", plays == 0 and w18.sel == "A", plays)
now = now + 100; w18:clickSave({ key = "A" })
check("LJ18: two clicks with no move between still play", plays == 1, plays)

-- LJ30: the heads are pad rows (A folds, the pick stays); the arrow keys step over them --------------------------
local s30 = SV:match("local hfid = \"head:\" %.%. r%.mode\n%s*self%._specs%[#self%._specs %+ 1%] = { id = hfid, listRow = true[^\n]*fn = fold")
check("LJ30: each head adds a list row whose A folds it", s30 ~= nil)
local w30 = setmetatable({ sel = "A", focusId = "head:Survivor", scroll = 0, _list = { h = 1000 }, _specs = {
    { id = "head:Survivor", listRow = true, ry = 0, rh = 10 } } }, { __index = ZeD_MMLoad })
w30.confirm = false
w30:joyDir("up")
check("LJ30: the hand on a head leaves the pick alone", w30.sel == "A")
fn(SV, "ZeD_MMLoad", "keyOther")
local list30 = { "head:One", "save:A", "head:Two", "head:Three", "save:B" }
local w30k = setmetatable({ sel = "A", view = list30, find = { isFocused = function() return false end }, confirm = false,
    scroll = 0, _list = { h = 1000 }, _specs = {} }, { __index = ZeD_MMLoad })
for i, id in ipairs(list30) do
    w30k._specs[#w30k._specs + 1] = { id = id, listRow = true, key = (id:sub(1, 5) == "save:") and id:sub(6) or nil, ry = i * 10, rh = 10 }
end
w30k._walk = function(self, dir)
    for i, id in ipairs(list30) do
        if id == self.focusId then self.focusId = list30[i + (dir == "down" and 1 or -1)] or id; return end
    end
end
w30k:keyOther(Keyboard.KEY_DOWN)
check("LJ30: Down steps over two folded heads to the next save", w30k.sel == "B" and w30k.focusId == "save:B", w30k.focusId)
w30k:keyOther(Keyboard.KEY_DOWN)
w30k.sel, w30k.focusId = "A", "save:A"
w30k:keyOther(Keyboard.KEY_UP)
check("LJ30: Up from the first save stays on it, never on the head", w30k.sel == "A" and w30k.focusId == "save:A", w30k.focusId)

-- LJ24, LJ25, LJ10: Rename's field and Playing as are pad stops; Rename's field has a click box ------------------
check("LJ24: Rename's field is a controller stop", SV:find('fieldStop(self, self.renameEntry, "field:rename"', 1, true) ~= nil)
check("LJ24: with a controller Rename lands on its field", SV:find('self.focusId = MM.gamepad() and "field:rename" or "confirm:no"', 1, true) ~= nil)
check("LJ25: Rename's field takes a click", SV:find('id = "load:rename"', 1, true) ~= nil)
check("LJ10: Playing as is a controller stop", SV:find('{ id = "players", noDraw = true', 1, true) ~= nil)
check("LJ16: Version is the game's key", SV:find('trBare("UI_servers_version")', 1, true) ~= nil and SV:find('ZeD.tr("Version")', 1, true) == nil)

-- JOIN ------------------------------------------------------------------------------------------------------
s = function(v) if v == nil then return "" end; return tostring(v) end
keyOf = function(server) return server and (s(server:getIp()) .. ":" .. s(server:getPort())) or "" end
local function srv(ip, port, accs)
    local a = accs or {}
    return { getIp = function() return ip end, getPort = function() return port end,
             getAccounts = function() return { size = function() return #a end, get = function(_, i) return a[i + 1] end } end }
end
local function acc(name) return { getUserName = function() return name end } end

-- LJ44: two saved servers on one address each get their own rows
fn(JN, "ZeD_MMJoin", "savedRows")
local A1, A2 = srv("1.2.3.4", 16261), srv("1.2.3.4", 16261)
local items = { { item = { type = "server", server = A1 } }, { item = { type = "account", server = A1, account = acc("u") } },
    { item = { type = "new_account", server = A1 } }, { item = { type = "server", server = A2 } },
    { item = { type = "account", server = A2, account = acc("u") } }, { item = { type = "new_account", server = A2 } },
    { item = { type = "new_server" } } }
local M = { accountList = { items = items } }
mp = function() return M end
local rows = ZeD_MMJoin.savedRows({})
local keys, dup = {}, false
for _, r in ipairs(rows) do if keys[r.key] then dup = true end; keys[r.key] = true end
check("LJ44: every saved row has its own key", not dup and #rows == 7)
check("LJ44: the first server keeps its plain key", rows[1].key == "s:1.2.3.4:16261" and rows[4].key == "s:1.2.3.4:16261#2", rows[4].key)
check("LJ44: the second server's account is under its key", rows[5].key == "a:1.2.3.4:16261#2:u" and rows[5].server == A2, rows[5].key)

-- LJ33, LJ34: under a question the rows wait, and Remove keeps its target
cut(JN, "SAFE_ANSWER + setConfirm", "(local SAFE_ANSWER = .-\nfunction ZeD_MMJoin:setConfirm%(.-\nend\n)")
fn(JN, "ZeD_MMJoin", "pick")
fn(JN, "ZeD_MMJoin", "connectOrOpen")
fn(JN, "ZeD_MMJoin", "selectedRow")
local connects = 0
M.onSelectInternetServer = function() end
local field = { setText = function() end, setVisible = function() end, focus = function() end, isFocused = function() return false end, unfocus = function() end }
local rA = { kind = "server", key = "s:A", server = A1 }
local rB = { kind = "account", key = "a:B", server = A2, account = acc("b") }
local wj = setmetatable({ sel = "s:A", _rows = { rA, rB }, field = field, confirm = false, focusId = nil }, { __index = ZeD_MMJoin })
function wj:connect() connects = connects + 1 end
wj:setConfirm("delServer")
check("LJ33: Remove's target is the row it opened on", wj._cRow == rA)
wj:pick(rB)
check("LJ33: a click on another row under the question does not move the pick", wj.sel == "s:A" and wj._cRow == rA, wj.sel)
wj:setConfirm(false)
check("LJ33: the question closed lets the target go", wj._cRow == nil)
wj.sel = "a:B"
wj:setConfirm("pwd")
now = now + 1000; wj:pick(rA); now = now + 50; wj:pick(rA)
wj:connectOrOpen(rB)
check("LJ34: under the password question neither a double click nor A connects another row", connects == 0 and wj.sel == "a:B", connects)
wj:setConfirm(false)
now = now + 1000; wj:pick(rB); now = now + 50; wj:pick(rB)
check("LJ34: with no question a double click connects as before", connects == 1, connects)
check("LJ33: the band names the kept row", JN:find("local sv = self._cRow and self._cRow.server", 1, true) ~= nil and JN:find("local acc = self._cRow and self._cRow.account", 1, true) ~= nil)

-- LJ43: the port's problems as before, and 16261 as the fallback
fn(JN, "ZeD_MMJoin", "serverProblems")
detectBadWords = function() return false end
local function entryOf(t) return { getText = function() return t end } end
local function portProblem(p)
    local wf = setmetatable({ fName = entryOf("n"), fAddr = entryOf("1.2.3.4"), fPort = entryOf(p) }, { __index = ZeD_MMJoin })
    return wf:serverProblems().port
end
check("LJ43: 16261 is a good port", portProblem("16261") == nil)
check("LJ43: an empty port is a problem", portProblem("") == "UI_ZeD_Join_ErrNoPort")
check("LJ43: a word is not a port", portProblem("abc") == "UI_ZeD_Join_ErrPortNumber")
check("LJ43: the save falls back to 16261", JN:find("or 16261   %-%- %(LJ43") ~= nil and JN:find("or 16262", 1, true) == nil)

-- LJ40: Connect on a public server saved with several accounts lands on its first account; with none, the form
fn(JN, "ZeD_MMJoin", "connectPublic")
local formOpened, direct = nil, 0
local P0, P2 = srv("5.6.7.8", 1), srv("5.6.7.8", 2, { acc("x"), acc("y") })
local fav = nil
M.getServerFeatured = function() return fav end
local wp = setmetatable({ tab = "public", scroll = 5 }, { __index = ZeD_MMJoin })
function wp:openAccountForm(server, a, after) formOpened = { server = server, after = after } end
function wp:connectAccount() direct = direct + 1 end
function wp:savedRows() return { { key = "s:5.6.7.8:2" }, { key = "a:5.6.7.8:2:x" }, { key = "a:5.6.7.8:2:y" } } end
fav = { server = P2 }
wp:connectPublic(P2)
check("LJ40: two accounts: SAVED, the first account chosen, the hand on it", wp.tab == "saved" and wp.sel == "a:5.6.7.8:2:x" and wp.focusId == "row:2", tostring(wp.sel) .. " " .. tostring(wp.focusId))
fav = { server = P0 }
wp:connectPublic(P0)
check("LJ40: no account: the account form, connecting when saved", formOpened and formOpened.server == P0 and formOpened.after == true)

-- LJ36, LJ49, LJ25, LJ35: the pad stops and masks, as written
check("LJ36: every tick is a controller stop", JN:find('self:padStop("tick:" .. id', 1, true) ~= nil)
check("LJ36: the sort heads are controller stops", JN:find('self:padStop("sort:" .. c[1]', 1, true) ~= nil)
check("LJ49: the code field is a controller stop", JN:find('UI.fieldStop(self, self.code, "field:code"', 1, true) ~= nil)
check("LJ25: the band's password field takes a click", JN:find('id = "join:f:band"', 1, true) ~= nil)
check("LJ35: the server form masks the address and port in streamer mode", JN:find("self.fAddr:setMasked(streamer)", 1, true) ~= nil and JN:find("self.fPort:setMasked(streamer)", 1, true) ~= nil)
check("LJ35: the invite draws no host : port", JM:find('heading(self, s(b.host) .. " : " .. s(b.port)', 1, true) == nil)

-- HOST ------------------------------------------------------------------------------------------------------
-- LJ57: a folder path with a backslash and an n stays one path
local hb = HO:match("(local function unescape%(t%).-\nlocal function esc%(p%)[^\n]*\n)")
check("Host's unescape and esc found", hb ~= nil)
local unescape, esc = assert(loadstring((hb or "") .. "return unescape, esc", "@unescape"))()
local BS = string.char(92)
local folder = "C:" .. BS .. "Zomboid" .. BS .. "Saves" .. BS .. "Multiplayer" .. BS .. "nightly"
local template = "Delete %1?" .. BS .. "nIt cannot be undone."
local text = unescape((template:gsub("%%1", (esc(folder):gsub("%%", "%%%%")))))
check("LJ57: the folder path keeps its backslashes", text:find(folder, 1, true) ~= nil, text)
check("LJ57: the template's own line break still breaks", text:find("?\nIt cannot", 1, true) ~= nil)
check("LJ57: no stray line break inside the path", select(2, text:gsub("\n", "")) == 1)

-- LJ56: the idle form draws the status line; LJ2: leaving Host idle puts vanilla's screen away
check("LJ56: the idle form draws c.serverStatus", HO:find("local st = UI.plain(s(c.serverStatus))", 1, true) ~= nil)
fn(HO, "ZeD_MMHost", "onViewLeft")
local hidden, saved = 0, 0
local C = { uiStatus = "idle", vis = true }
function C:isVisible() return self.vis end
function C:setVisible(v) self.vis = v; if not v then hidden = hidden + 1 end end
function C:saveOptions() saved = saved + 1 end
coop = function() return C end
local wh = setmetatable({}, { __index = ZeD_MMHost })
function wh:idle() return C.uiStatus == "idle" end
wh:onViewLeft()
check("LJ2: leaving Host idle hides vanilla's screen, its options saved", hidden == 1 and saved == 1 and C.vis == false)
C.vis, C.uiStatus = true, "starting"
wh:onViewLeft()
check("LJ2: leaving while a server starts leaves it running", hidden == 1 and C.vis == true)
local MMsrc = read("42/media/lua/client/ZeD/ZeD_MainMenu.lua")
check("LJ2: MM.showView tells the window it left", MMsrc:find("if was and was ~= w and was.onViewLeft then pcall(was.onViewLeft, was) end", 1, true) ~= nil)

print(string.format("ljh_menu_fixes_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
