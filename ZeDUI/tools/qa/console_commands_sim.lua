-- ZeDUI/tools/qa/console_commands_sim.lua  (Nov 12 2026): the Lua console's Commands page with no game running, on
-- console_sim_harness.lua's stage (the real console files on Lua 5.1 stubs). It checks:
--   * the list against the game's registry (the names read from zombie.commands.serverCommands on 42.22.2, below):
--     every enabled command and its other names there, the three disabled ones left out, syntax and example given,
--     every help key a ZeD key in UI.json or one of the game's UI_ServerOptionDesc keys
--   * the role filter: a server shows only what the role's capabilities allow, the host sees all, single player all;
--     the level beside each from the server's roles, or the defaults
--   * the search (names, other names, syntax, what it does, capability), its empty line
--   * a click fills the chat line with the example; Send sends it (a stub SendCommandToServer); a command that can't
--     be undone asks first in the band (Cancel keeps it, Send sends); the band says what happened; a line edited
--     under the question drops it, and the question's Send never sends the edited line unasked
--   * a steady frame asks no command its capabilities, level or words (kept with the rows, made again once a second)
--   * single player: each command's debug-menu way, a pick opens its window where there is one, the band's keycap
--   * the controller: strip, search, list, line, band; A fills or opens, X sends (on an empty line X fills it and
--     the hand goes to Send, nothing sent), B answers the question; the line edited on the pad keyboard under the
--     question asks again
--   * every frame drawn inside the window at 720 / Deck / 1080p / 4K, Normal and Large text, mouse and pad
-- What it cannot prove: that the server runs what SendCommandToServer hands it (QA's multiplayer run).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/console_commands_sim.lua

SIM_NAME = "console_commands_sim"
ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]console_commands_sim%.lua$", "")
local H = dofile(ROOT .. "ZeDUI/tools/qa/console_sim_harness.lua")
local check, frame, draw, textHas = H.check, H.frame, H.draw, H.textHas
local JC, KB, CORE = H.JC, H.KB, H.CORE
require "ZeD/ZeD_ConsolePages"
local DC = ZeD.DebugConsole
local CC = ZeD.ConsoleCommands
check("the files load", CC ~= nil and type(CC.send) == "function" and type(ZeD_DebugConsoleWindow._drawCmds) == "function")

-- the game's registry, 42.22.2: every class in zombie.commands.serverCommands with its @CommandName names
-- (javap of projectzomboid.jar); the three marked @DisabledCommand are last
local REGISTRY = {
    addalltowhitelist = "disabled", additem = "", addkey = "", addsteamid = "", adduser = "", addtosafehouse = "",
    addusertowhitelist = "disabled", addvehicle = "", addxp = "", alarm = "", banip = "", banid = "", banuser = "",
    changeoption = "", checkModsNeedUpdate = "", chopper = "", clear = "", connections = "disabled", createhorde2 = "",
    createhorde = "", debugplayer = "", godmode = "godmod", godmodeplayer = "godmodplayer", grantadmin = "", gunshot = "",
    help = "", invisible = "", invisibleplayer = "", kickuser = "kick", kickfromsafehouse = "", lightning = "", list = "",
    log = "", noclip = "", players = "", quit = "", releasesafehouse = "", reloadalllua = "reloadluaall", reloadlua = "",
    reloadoptions = "", removeadmin = "", remove = "", removeitem = "", removemapsymbolsforuser = "", removesteamid = "",
    removeuserfromwhitelist = "", removezombies = "", save = "", servermsg = "", setaccesslevel = "", setpassword = "",
    setTimeSpeed = "sts", showoptions = "", stats = "", startrain = "", startstorm = "", stoprain = "", stopweather = "",
    teleport = "tp", teleportplayer = "tpp", teleportto = "tpto", thunder = "", unbanip = "", unbanid = "", unbanuser = "",
    voiceban = "", worldgen = "",
}
-- the game's help keys the list uses (UI.json of 42.22.2 has every one)
local GAME_HELP = { AddItem = 1, AddKey = 1, AddSteamID = 1, AddUser = 1, AddToSafehouse = 1, AddVehicle = 1, AddXp = 1,
    Alarm = 1, BanIp = 1, BanSteamId = 1, BanUser = 1, ChangeOptions = 1, CheckModsNeedUpdate = 1, Chopper = 1,
    CreateHorde = 1, GodMod = 1, GodModPlayer = 1, Gunshot = 1, Invisible = 1, InvisiblePlayer = 1, Kick = 1,
    KickFromSafehouse = 1, Lightning = 1, NoClip = 1, Players = 1, Quit = 1, ReleaseSafeHouse = 1, ReloadLua = 1,
    ReloadOptions = 1, RemoveItem = 1, RemoveMapSymbolsForUser = 1, RemoveSteamID = 1, RemoveWhitelist = 1, Save = 1,
    ServerMsg = 1, SetAccessLevel = 1, SetPassword = 1, SetTimeSpeed = 1, ShowOptions = 1, Statistics = 1, StartRain = 1,
    StartStorm = 1, StopRain = 1, StopWeather = 1, Teleport = 1, TeleportPlayer = 1, TeleportTo = 1, Thunder = 1,
    UnBanIp = 1, UnBanSteamId = 1, UnBanUser = 1, VoiceBan = 1, Worldgen = 1, Roll = 1, Card = 1 }

-- ============================================================================
-- 1. the list against the registry
-- ============================================================================
local server = 0
for _, c in ipairs(CC.list) do if not c.chat and c.grp ~= "chat" then server = server + 1 end end
check("registry: 64 server commands listed", server == 64, server)
local missing, aliasMiss = {}, {}
for name, also in pairs(REGISTRY) do
    if also == "disabled" then
        check("registry: disabled " .. name .. " left out", CC.byName[string.lower(name)] == nil)
    else
        local c = CC.byName[string.lower(name)]
        if not c then missing[#missing + 1] = name end
        if also ~= "" and not (c and CC.byName[also] == c) then aliasMiss[#aliasMiss + 1] = also end
    end
end
check("registry: every enabled command listed", #missing == 0, table.concat(missing, ","))
check("registry: every other name finds its command", #aliasMiss == 0, table.concat(aliasMiss, ","))
local extra = {}
for _, c in ipairs(CC.list) do
    if c.grp ~= "chat" and REGISTRY[c.name] == nil then extra[#extra + 1] = c.name end
end
check("registry: nothing listed the game lacks", #extra == 0, table.concat(extra, ","))
local bad = {}
for _, c in ipairs(CC.list) do
    local ok = c.syn:sub(1, 1) == "/" and c.ex:sub(1, 1) == "/" and #c.caps >= 1
    if c.help:sub(1, 7) == "UI_ZeD_" then ok = ok and H.TEXT[c.help] ~= nil
    else ok = ok and GAME_HELP[c.help:gsub("^UI_ServerOptionDesc_", "")] ~= nil end
    if c.sp.open then ok = ok and CC.OPEN[c.sp.open] ~= nil end
    if c.sp.say then ok = ok and H.TEXT[c.sp.say] ~= nil end
    if not ok then bad[#bad + 1] = c.name end
end
check("every row: syntax, example, a capability, a known help key and its single-player words", #bad == 0, table.concat(bad, ","))
for _, g in ipairs(CC.GROUPS) do check("group " .. g.id .. ": its header's words", H.TEXT[g.key] ~= nil) end
check("find: a line's command", CC.find("/kick \"rj\"") == CC.byName.kickuser and CC.find("tp x") == CC.byName.teleport and CC.find("hello") == nil)
check("asks: the ones that can't be undone", CC.asks("/removezombies -radius 5") and CC.asks("/quit") and not CC.asks("/save") and not CC.asks("/kick x"))

-- ============================================================================
-- 2. the role filter and the levels
-- ============================================================================
CC.qaServer = true
CC.qaCaps = { LoginOnServer = true }
local function names()
    local groups = CC.shown("")
    local out = {}
    for _, g in ipairs(groups) do for _, c in ipairs(g.cmds) do out[#out + 1] = c.name end end
    return out
end
local userList = table.concat(names(), ",")
check("role: a plain user sees the everyone commands only", userList == "list,clear,help,all,say,yell,whisper,faction,safehouse,roll,card", userList)
check("role: hidden above it (no admin chat, no kick)", not userList:find("admin", 1, true) and not userList:find("kick", 1, true))
CC.qaCaps = { LoginOnServer = true, ToggleGodModHimself = true, TeleportToPlayer = true, TeleportToCoordinates = true, SeePlayersConnected = true,
    ToggleInvisibleHimself = true, ToggleNoclipHimself = true, SeePublicServerOptions = true, CanSeeMessageForAdmin = true }
local obs = names()
check("role: an observer sees godmode, teleport, the admin chat", table.concat(obs, ","):find("godmode", 1, true) and table.concat(obs, ","):find("admin", 1, true) and #obs == 19, #obs)
check("role: two capabilities, either one shows it (teleport)", CC.visible(CC.byName.teleport))
CC.qaCaps = nil
local caps = {}
Capability = setmetatable({}, { __index = function(_, k) return k end })
H.role.hasCapability = function(_, c) return caps[c] == true end
H.setClient(true, false, false)
CC.qaServer = nil
check("role: read from the player's role on a server", CC.server() and not CC.visible(CC.byName.additem))
caps.AddItem = true
check("role: a capability given, the command shows", CC.visible(CC.byName.additem))
H.setClient(true, false, true)
check("role: the co-op host sees all", CC.visible(CC.byName.quit))
H.setClient(false, false, false)
check("single player: all shown", not CC.server() and CC.visible(CC.byName.quit) and CC.total() == #CC.list)
local w, rank = CC.level(CC.byName.additem)
check("level: the defaults (additem: GM)", w == "GM" and rank == 3, w)
w = CC.level(CC.byName.quit)
check("level: quit is Admin", w == "Admin")
w = CC.level(CC.byName.kickuser)
check("level: kick is Moderator", w == "Moderator")
CC.qaServer = true
CC.qaRoles = { { name = "user", caps = { LoginOnServer = true } }, { name = "helper", caps = { LoginOnServer = true, KickUser = true } },
    { name = "admin", caps = { KickUser = true, QuitWorld = true } } }
w = CC.level(CC.byName.kickuser)
check("level: the server's own roles (a custom one)", w == "Helper", w)
CC.qaRoles = nil

-- ============================================================================
-- 3. the search
-- ============================================================================
CC.qaServer = false
local function hits(q) local _, n = CC.shown(q); return n end
check("search: a name", hits("kickfromsafehouse") == 1)
check("search: a capability finds all that need it", hits("BanUnbanUser") == 7, hits("BanUnbanUser"))
check("search: another name (tp)", (function() local g = CC.shown("tpto"); return g[1] and g[1].cmds[1].name == "teleportto" end)())
check("search: the syntax", hits("module.item") == 2, hits("module.item"))
check("search: what it does (ZeD's words)", hits("staff only") == 1)
check("search: the capability", hits("ManipulateZombie") == 1)
check("search: any case", hits("REMOVEZOMBIES") == 1)
check("search: nothing", hits("zzqqxx") == 0)

-- ============================================================================
-- 4. the page on a server: click, fill, Send, the question
-- ============================================================================
CC.qaServer = true
CC.qaCaps = setmetatable({}, { __index = function() return true end })
CC.qaRole = "Admin"
local SENT = {}
CC.qaSend = function(t) SENT[#SENT + 1] = t; return "sent" end
JC.visible = true
frame()
local win = DC.win
check("open", DC.isOpen() and win ~= nil)
win:setPage("cmds")
draw(win)
check("page: drawn inside", #H.DRAW.outside == 0, H.DRAW.outside[1])
check("page: the head", textHas("Your role: Admin") and textHas("of " .. #CC.list))
check("page: group headers and rows", (textHas("PLAYERS") or textHas("Players")) and textHas("/teleport"))
check("page: the level beside a row", textHas("GM") and textHas("Moderator"))
check("page: the chat line", win._chatRect ~= nil and textHas("Pick a command to fill the line"))
-- a frame of the page asks no command anything: the count, each row's level and words and your role are kept with
-- the rows (made again when the search or a fold changes, or once a second, for a role that changed)
do
    local calls, real = {}, {}
    for _, name in ipairs({ "visible", "can", "level", "does", "alone", "myRole", "total", "server" }) do
        local f = CC[name]
        real[name] = f
        CC[name] = function(...) calls[name] = (calls[name] or 0) + 1; return f(...) end
    end
    win.csel = "godmode"
    win._cKey = nil
    draw(win)
    for k in pairs(calls) do calls[k] = 0 end
    draw(win)
    local per = 0
    for _, name in ipairs({ "visible", "can", "level", "does", "alone", "myRole", "total" }) do per = per + (calls[name] or 0) end
    check("a steady frame: no command's capabilities, level or words asked again", per == 0,
        "visible " .. tostring(calls.visible) .. ", level " .. tostring(calls.level) .. ", does " .. tostring(calls.does) .. ", total " .. tostring(calls.total))
    check("a steady frame: on a server or not asked once, not per row", (calls.server or 0) <= 2, calls.server)
    check("a steady frame: the head's count and role still there", textHas("of " .. #CC.list) and textHas("Your role: Admin"))
    local clock = getTimestampMs
    local t0 = clock()
    getTimestampMs = function() return t0 + 1000 end
    for k in pairs(calls) do calls[k] = 0 end
    draw(win)
    check("a second on: the rows made again (a role that changed shows)", (calls.visible or 0) > 0 and (calls.myRole or 0) == 1, calls.visible)
    getTimestampMs = clock
    for name, f in pairs(real) do CC[name] = f end
    win.csel = nil
    win._cKey = nil
    draw(win)
end
local function rowHit(name)
    local items = win:_cmdItems()
    for _, hit in ipairs(win._cHits or {}) do
        local it = items[hit.i]
        if it.t == "cmd" and it.c.name == name then return hit end
    end
    return nil
end
local hit = rowHit("godmode")
check("page: godmode on screen", hit ~= nil)
win:onMouseDown(win._cListRect.x + 30, hit.y + 2)
check("click: picks it, the example fills the line", win.csel == "godmode" and win.chat:getText() == "/godmode -true")
draw(win)
check("detail: syntax and example", textHas("/godmode -value") and textHas("Syntax") and textHas("Example") and textHas("Also"))
check("detail: the capability", textHas("ToggleGodModHimself"))
local function band(id) for _, r in ipairs(win._bandRects or {}) do if r and r.id == id then return r end end return nil end
local s = band("csend")
win:onMouseDown(s.x + 2, s.y + 2); win:onMouseUp(s.x + 2, s.y + 2)
check("Send: sent as typed", SENT[1] == "/godmode -true")
check("Send: the band says so, the line empties", win._cStatus and win._cStatus.text:find("/godmode -true", 1, true) and win.chat:getText() == "")
-- a command that can't be undone
win.cq:setText("removezombies")
draw(win)
hit = rowHit("removezombies")
win:onMouseDown(win._cListRect.x + 30, hit.y + 2)
draw(win)
check("detail: the can't-be-undone tag", textHas("can't be undone"))
check("help line: Send asks first", win:getStatusLine():find("asks first", 1, true) ~= nil)
win.chat.onCommandEntered()
check("Enter on one that can't be undone: asks in the band, nothing sent", win.cConfirm == "/removezombies -radius 20" and #SENT == 1)
draw(win)
check("the question drawn", textHas("Send /removezombies -radius 20? It can't be undone.") and band("cno") and band("cyes"))
local no = band("cno")
win:onMouseDown(no.x + 2, no.y + 2); win:onMouseUp(no.x + 2, no.y + 2)
check("Cancel: nothing sent, the line kept", win.cConfirm == nil and #SENT == 1 and win.chat:getText() == "/removezombies -radius 20")
win:cmdSend()
draw(win)
local yes = band("cyes")
win:onMouseDown(yes.x + 2, yes.y + 2); win:onMouseUp(yes.x + 2, yes.y + 2)
check("Send in the question: sent", SENT[2] == "/removezombies -radius 20" and win.cConfirm == nil)
-- the line edited under the question: its Send never sends what it did not ask about, and the question goes
win.chat:setText('/removeadmin "bob"')
win:cmdSend()
draw(win)
yes = band("cyes")
check("question: asks about the line", win.cConfirm == '/removeadmin "bob"' and yes ~= nil)
local nSent = #SENT
win.chat:setText('/grantadmin "bobby"')
win:onMouseDown(yes.x + 2, yes.y + 2); win:onMouseUp(yes.x + 2, yes.y + 2)
check("the line edited, then the question's Send: nothing sent, asked again about the line", #SENT == nSent and win.cConfirm == '/grantadmin "bobby"', SENT[#SENT])
draw(win)
check("the question names the line as it stands", textHas('Send /grantadmin "bobby"? It can\'t be undone.') and not textHas('/removeadmin "bob"?'))
win.chat:setText("/save")
draw(win)
check("the line edited to another command: the question gone, the band's own Send back", win.cConfirm == nil and band("cyes") == nil and band("csend") ~= nil)
win.chat:setText("")
-- the search empty, Copy
win.cq:setText("zzqqxx")
draw(win)
check("search: the empty line", textHas("No command your role can use matches") and #H.DRAW.outside == 0)
win.cq:setText("")
win.chat:setText("/save")
draw(win)
local cp = band("ccopy")
win:onMouseDown(cp.x + 2, cp.y + 2); win:onMouseUp(cp.x + 2, cp.y + 2)
check("Copy: the line to the clipboard", H.clip() == "/save")
-- a role narrows the page
CC.qaCaps = { LoginOnServer = true }
CC.qaRole = "User"
win._cKey = nil
draw(win)
check("page: a user's page has no /kickuser", not textHas("/kickuser") and textHas("/help") and textHas("Your role: User"))
CC.qaCaps = setmetatable({}, { __index = function() return true end })
win._cKey = nil
-- the real send path: SendCommandToServer, ZeD's chat for a channel
CC.qaSend = nil
local GOT = {}
SendCommandToServer = function(t) GOT[#GOT + 1] = t end
check("send: a command through SendCommandToServer", CC.send("/players") == "sent" and GOT[1] == "/players")
ZeD.Chat = { send = function(t) GOT[#GOT + 1] = "chat:" .. t; return true end }
check("send: a chat channel through ZeD's chat", CC.send("/say hi") == "chat" and GOT[2] == "chat:/say hi")
SendCommandToServer = nil
local OPENED = nil
ZeD.Chat = { send = ZeD.Chat.send, open = function() ZeD.Chat.win = { input = { setText = function(_, t) OPENED = t end } } end }
check("send: no send call, the line waits in the chat box", CC.send("/players") == "filled" and OPENED == "/players")
ZeD.Chat = nil
check("send: nothing to send with", CC.send("/players") == false)
CC.qaSend = function(t) SENT[#SENT + 1] = t; return "sent" end

-- ============================================================================
-- 5. single player
-- ============================================================================
CC.qaServer, CC.qaCaps, CC.qaRole = false, nil, nil
local OPEN = {}
CC.qaOpen = function(id) OPEN[#OPEN + 1] = id end
win._cKey = nil
win.csel = nil
draw(win)
check("sp: drawn inside, no chat line", #H.DRAW.outside == 0 and win._chatRect == nil, H.DRAW.outside[1])
check("sp: the head says single player", textHas("Single player"))
check("sp: each row's debug-menu way", textHas("Debug menu >") and textHas("Nothing like it alone"))
check("sp: the band grayed with nothing picked", band("copen") and win._bandOff ~= nil)
hit = rowHit("godmode")
win:onMouseDown(win._cListRect.x + 30, hit.y + 2)
check("sp: a pick opens its debug window", OPEN[1] == "cheats" and win.csel == "godmode")
draw(win)
check("sp: the keycap names it", textHas("Open IGUI_DebugMenu_Main_Cheats"))
local op = band("copen")
win:onMouseDown(op.x + 2, op.y + 2); win:onMouseUp(op.x + 2, op.y + 2)
check("sp: the keycap opens it again", OPEN[2] == "cheats")
win:cmdPick(CC.byName.kickuser)
draw(win)
check("sp: one with nothing like it: no window, the detail says why", #OPEN == 2 and textHas("Nothing like it in single player"))
hit = rowHit("teleport")
win:onMouseDown(win._cListRect.x + 30, hit.y + 2)
draw(win)
check("sp: one that is only said", #OPEN == 2 and textHas("The world map in debug mode"))
check("sp: Send does nothing", (function() local n = #SENT; win.chat:setText("/save"); win:cmdSend(); return #SENT == n end)())
-- the real openers: the game's own panels, by name
CC.qaOpen = nil
local opened = {}
ISAdminPowerUI = { OnOpenPanel = function() opened[#opened + 1] = "cheats" end }
ISDebugMenu = { onClickSandboxSettings = function(self) opened[#opened + 1] = self == ISDebugMenu and "sandbox" or "?" end }
check("sp: Cheats opens through ISAdminPowerUI.OnOpenPanel", CC.openAlone(CC.byName.godmode) and opened[1] == "cheats")
check("sp: Sandbox through ISDebugMenu:onClickSandboxSettings", CC.openAlone(CC.byName.showoptions) and opened[2] == "sandbox")
check("sp: a window the game lacks: false, no error", CC.openAlone(CC.byName.startrain) == false)
CC.qaOpen = function(id) OPEN[#OPEN + 1] = id end

-- ============================================================================
-- 6. the controller
-- ============================================================================
DC.close()
local jd = { id = 0, player = 0 }
JoypadState.players[1] = jd
H.setMode("gamepad")
CC.qaServer = true
CC.qaCaps = setmetatable({}, { __index = function() return true end })
CC.qaRole = "Admin"
DC.open(0)
win = DC.win
win:update()
win:setPage("log")
win:setPage("cmds")
win.cq:setText("")
win.chat:setText("")
win._cKey = nil
win.cFocus = 1
check("pad: the page opens on the strip", win.zone == "strip")
local function glyphs()
    local g = {}
    for _, p in ipairs(win:getFooterPrompts()) do if type(p) == "table" then g[#g + 1] = p.glyph .. ":" .. p.label end end
    return table.concat(g, " ")
end
win:onJoypadDirRight()
check("pad: right from the strip, the list", win.zone == "page")
check("pad prompts on a header: A Fold, X Send, B Close", glyphs() == "A:Fold X:Send B:Close", glyphs())
win:onJoypadDirDown()
check("pad: down onto a command shows its detail", win.csel == "teleport")
check("pad prompts on a command: A Fill the line", glyphs():find("A:Fill the line", 1, true) ~= nil, glyphs())
H.resetMarks()
draw(win)
check("pad: marked, drawn inside", H.marks() >= 1 and #H.DRAW.outside == 0)
win:onJoypadDown(Joypad.AButton, jd)
check("pad: A fills the line", win.chat:getText() == '/teleport "rj"')
win:onJoypadDown(Joypad.XButton, jd)
check("pad: X sends", SENT[#SENT] == '/teleport "rj"')
-- X on a command with the line empty: its example fills the line and the hand goes to Send; a second X sends it
win.chat:setText("")
local smsg = nil
for i, it in ipairs(win:_cmdItems()) do if it.t == "cmd" and it.c.name == "servermsg" then smsg = i end end
win.zone, win.cFocus = "page", smsg
local nX = #SENT
win:onJoypadDown(Joypad.XButton, jd)
check("pad: X on a row with the line empty sends nothing", #SENT == nX, SENT[#SENT])
check("pad: ...the example in the line, the hand on Send", win.chat:getText() == '/servermsg "Restart in 10 minutes"' and win.zone == "pband" and win.cbFocus == 2, win.zone)
win:onJoypadDown(Joypad.XButton, jd)
check("pad: a second X sends it", #SENT == nX + 1 and SENT[#SENT] == '/servermsg "Restart in 10 minutes"')
-- the line edited on the pad keyboard under the question: A on Send asks about the new line, sends nothing
win.chat:setText("/removezombies -radius 20")
win.zone, win.cbFocus = "cline", 2
win:onJoypadDown(Joypad.XButton, jd)
check("pad: X on one that can't be undone asks, the hand on Cancel", win.cConfirm == "/removezombies -radius 20" and win.zone == "pband" and win.cbFocus == 1)
win:onJoypadDirUp()
win:onJoypadDown(Joypad.AButton, jd)
check("pad: up to the line under the question, A types", win.zone == "cline" and KB.visible and KB.entry == win.chat)
win.chat:setText("/removezombies -radius 2000")
KB.visible = false
jd.focus = win
win:update()
nX = #SENT
win:onJoypadDown(Joypad.AButton, jd)
check("pad: the edited line's A on Send sends nothing, asks about it", #SENT == nX and win.cConfirm == "/removezombies -radius 2000" and win.cbFocus == 1, SENT[#SENT])
if win.cConfirm then win:onJoypadDown(Joypad.BButton, jd) end
check("pad: B cancels it", win.cConfirm == nil and DC.isOpen())
win.cConfirm = nil
win.chat:setText("")
win.zone, win.cFocus = "page", 2
win:onJoypadDirUp(); win:onJoypadDirUp()
check("pad: up past the first row, the search", win.zone == "csearch")
win:onJoypadDown(Joypad.AButton, jd)
check("pad: A on the search opens the pad keyboard", KB.visible and KB.entry == win.cq)
KB.visible = false
jd.focus = win
win:update()
win:onJoypadDirDown()
check("pad: down from the search, the list", win.zone == "page")
local items = win:_cmdItems()
win.cFocus = #items
win:onJoypadDirDown()
check("pad: past the last row, the line", win.zone == "cline")
win:onJoypadDown(Joypad.AButton, jd)
check("pad: A on the line opens the pad keyboard", KB.visible and KB.entry == win.chat)
win.chat:setText("/quit")
KB.visible = false
jd.focus = win
win:update()
check("pad: after typing the line, on Send", win.zone == "pband" and win.cbFocus == 2)
win:onJoypadDown(Joypad.AButton, jd)
check("pad: A on Send for /quit asks", win.cConfirm == "/quit" and win.zone == "pband" and win.cbFocus == 1)
check("pad prompts in the question: B Cancel", glyphs():find("B:Cancel", 1, true) ~= nil, glyphs())
draw(win)
check("pad: the question drawn inside", #H.DRAW.outside == 0)
win:onJoypadDown(Joypad.BButton, jd)
check("pad: B cancels the question, the window stays", win.cConfirm == nil and DC.isOpen())
win:onJoypadDown(Joypad.AButton, jd)
win:onJoypadDirRight()
win:onJoypadDown(Joypad.AButton, jd)
check("pad: Send in the question sends", SENT[#SENT] == "/quit")
win:onJoypadDirLeft(); win:onJoypadDirLeft()
check("pad: left from the band's first keycap, the strip", win.zone == "strip")
-- single player on the pad: A opens
CC.qaServer = false
win._cKey = nil
win.zone, win.cFocus = "page", 2
local n0 = #OPEN
win:onJoypadDirUp(); win:onJoypadDirDown()
check("pad sp prompts: A Open, no X", glyphs():find("A:Open", 1, true) ~= nil and not glyphs():find("X:", 1, true), glyphs())
win:onJoypadDown(Joypad.AButton, jd)
check("pad sp: A on a command opens or says (teleport says)", #OPEN == n0 and win.csel == "teleport")
win.cFocus = 5   -- godmode
win:onJoypadDown(Joypad.AButton, jd)
check("pad sp: A on godmode opens Cheats", OPEN[#OPEN] == "cheats", win:_cmdItems()[5].c and win:_cmdItems()[5].c.name)
win.zone = "page"
win.cFocus = #win:_cmdItems()
win:onJoypadDirDown()
check("pad sp: past the last row, the band (no line)", win.zone == "pband")
DC.close()
JoypadState.players[1] = nil
H.setMode("kbm")

-- ============================================================================
-- 7. every size, both text sizes, mouse and pad, server and single player
-- ============================================================================
local PROFILES = {
    { name = "720p Normal", root = 1, size = "small", w = 1280, h = 720 },
    { name = "Deck Large", root = 1, size = "large", w = 1280, h = 800 },
    { name = "1080p Normal", root = 1, size = "small", w = 1920, h = 1080 },
    { name = "4K 1.75 Normal", root = 1.75, size = "small", w = 3840, h = 2160 },
    { name = "4K 2 Large", root = 2, size = "large", w = 3840, h = 2160 },
}
for _, prof in ipairs(PROFILES) do
    ZEDQA_ROOT = prof.root
    ZEDQA_LARGE = prof.size == "large"
    ZeD.applyTheme("dark", "orange", prof.size)
    H.SCREEN.w, H.SCREEN.h = prof.w, prof.h
    DC.close()
    DC.win, DC.place = nil, nil
    for _, padIn in ipairs({ false, true }) do
        H.setMode(padIn and "gamepad" or "kbm")
        JoypadState.players[1] = padIn and { id = 0, player = 0 } or nil
        JC.visible = true
        frame()
        if padIn then DC.close(); DC.open(0) end
        local w2 = DC.win
        if w2 then
            w2:update()
            w2:setPage("cmds")
            for _, sv in ipairs({ true, false }) do
                CC.qaServer = sv
                w2._cKey = nil
                w2.csel = "removezombies"
                for _, size in ipairs({ { w2.width, w2.height }, { ZeD.T.px(520), ZeD.T.px(260) } }) do
                    w2:setWidth(size[1]); w2:setHeight(size[2])
                    w2.zone = padIn and "page" or w2.zone
                    draw(w2)
                    local name = prof.name .. (padIn and " pad " or " mouse ") .. (sv and "server " or "sp ") .. size[1] .. "x" .. size[2]
                    check(name .. ": drawn inside", #H.DRAW.outside == 0, H.DRAW.outside[1])
                    check(name .. ": the list has room", w2._cListRect and w2._cListRect.h > 0)
                    if sv then
                        w2.cConfirm = "/removezombies -radius 20"
                        draw(w2)
                        check(name .. ": the question drawn inside", #H.DRAW.outside == 0, H.DRAW.outside[1])
                        w2.cConfirm = nil
                    end
                end
            end
            w2:setPage("log")
        end
        DC.close()
    end
end
JoypadState.players[1] = nil

H.sysPrint(SIM_NAME .. ": " .. H.checks .. " checks, " .. H.failed .. " failed")
if H.failed > 0 then os.exit(1) end
