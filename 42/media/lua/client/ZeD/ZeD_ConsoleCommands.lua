-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ConsoleCommands.lua
-- ============================================================================
-- THE CONSOLE'S COMMAND LIST: every server slash command of 42.22, who may use it, what it does alone, and sending
-- one. No drawing. Client. Logic only (ZeD.ConsoleCommands); ZeD_ConsolePages.lua draws the Commands page.
--
-- The list is the game's own registry, read from its class files (zombie.commands.serverCommands, 42.22.2): each
-- command's names, the capability it needs and its help text key (UI_ServerOptionDesc_*, translated by the game).
-- Syntax and examples are written as the game's help writes them. Three classes the game marks disabled
-- (addalltowhitelist, addusertowhitelist, connections) are left out: the server refuses them. The chat channels
-- (/all, /say and the rest) and /roll and /card are typed in chat the same way, so they are listed too.
--
-- Who sees what: on a server, a command shows only when your role has its capability (the game's own test,
-- Role:hasCapability); the co-op host sees them all. The level shown beside each is the lowest role on this server
-- that has the capability, or the game's default roles when the roles can't be read. In single player there is no
-- server: every command shows, with the debug menu's own way of doing it, and a pick opens that window where one
-- exists.
--
-- The one thing to know: sending goes through SendCommandToServer, the call the game's chat makes for a "/" line.
-- It exists in 42.22 and returns nothing; that the server runs a line sent this way and answers is unproven in game
-- until QA's multiplayer run.
-- ============================================================================

ZeD = ZeD or {}
ZeD.ConsoleCommands = ZeD.ConsoleCommands or {}
local CC = ZeD.ConsoleCommands

-- the page's groups, in order
CC.GROUPS = {
    { id = "players", key = "UI_ZeD_Console_CmdGrpPlayers" },
    { id = "items", key = "UI_ZeD_Console_CmdGrpItems" },
    { id = "world", key = "UI_ZeD_Console_CmdGrpWorld" },
    { id = "moderation", key = "UI_ZeD_Console_CmdGrpModeration" },
    { id = "server", key = "UI_ZeD_Console_CmdGrpServer" },
    { id = "chat", key = "UI_ZeD_Console_CmdGrpChat" },
}

-- the game's classes it marks disabled (DisabledCommand): not listed
CC.DISABLED = { "addalltowhitelist", "addusertowhitelist", "connections" }

-- the default roles of 42.22 (zombie.characters.Roles.addStatic), lowest first, and the lowest that has each
-- capability the commands need (moderator has all but the admin ones; admin has all)
CC.DEFAULT_ROLES = { "user", "observer", "gm", "moderator", "admin" }
CC.DEFAULT_LEVEL = {
    LoginOnServer = "user",
    ToggleGodModHimself = "observer", ToggleInvisibleHimself = "observer", ToggleNoclipHimself = "observer",
    SeePlayersConnected = "observer", TeleportToPlayer = "observer", TeleportToCoordinates = "observer",
    SeePublicServerOptions = "observer", CanSeeMessageForAdmin = "observer",
    ToggleGodModEveryone = "gm", ToggleInvisibleEveryone = "gm", TeleportPlayerToAnotherPlayer = "gm",
    MakeEventsAlarmGunshot = "gm", StartStopRain = "gm", AddItem = "gm", AddXP = "gm",
    SaveWorld = "admin", QuitWorld = "admin", ChangeAndReloadServerOptions = "admin", ReloadLuaFiles = "admin",
    ConnectWithDebug = "admin",
}

-- the debug windows a single-player pick opens: the game's own debug menu buttons (ISDebugMenu:setupButtons)
CC.OPEN = {
    cheats = { label = "IGUI_DebugMenu_Main_Cheats", class = "ISAdminPowerUI" },
    items = { label = "IGUI_DebugMenu_Main_Items", class = "ISItemsListViewer" },
    player = { label = "IGUI_DebugMenu_Main_Player", class = "ISPlayerStatsUI" },
    climate = { label = "IGUI_DebugMenu_Main_Climate", class = "ClimateControlDebug" },
    general = { label = "IGUI_DebugMenu_Main_General", class = "ISGeneralDebug" },
    sandbox = { label = "IGUI_DebugMenu_Main_Sandbox", class = "ISDebugMenu", sandbox = true },
}

-- One row per command: group, name, other names, syntax, example, capabilities (any one), its help (the game's key,
-- or ZeD's when the game has none), single player (an OPEN window, or say = ZeD's words for where it is), and
-- undo = false for the ones that can't be undone (they ask first). chat = a chat channel, sent as chat sends it.
local L = {}
local function add(grp, name, also, syn, ex, caps, help, sp, extra)
    local c = { grp = grp, name = name, also = also or {}, syn = syn, ex = ex, caps = caps, help = help, sp = sp or {} }
    if extra then for k, v in pairs(extra) do c[k] = v end end
    L[#L + 1] = c
end
local NO_UNDO = { undo = false }
local G = "UI_ServerOptionDesc_"
-- players
add("players", "teleport", { "tp" }, '/teleport "playername"  |  /teleport "player1" "player2"', '/teleport "rj"', { "TeleportToPlayer", "TeleportPlayerToAnotherPlayer" }, G .. "Teleport", { say = "UI_ZeD_Console_SpTeleport" })
add("players", "teleportplayer", { "tpp" }, '/teleportplayer "player1" "player2"', '/teleportplayer "rj" "toUser"', { "TeleportPlayerToAnotherPlayer" }, G .. "TeleportPlayer")
add("players", "teleportto", { "tpto" }, "/teleportto x,y,z", "/teleportto 10000,11000,0", { "TeleportToCoordinates" }, G .. "TeleportTo", { say = "UI_ZeD_Console_SpTeleport" })
add("players", "godmode", { "godmod" }, "/godmode -value", "/godmode -true", { "ToggleGodModHimself" }, G .. "GodMod", { open = "cheats" })
add("players", "godmodeplayer", { "godmodplayer" }, '/godmodeplayer "username" -value', '/godmodeplayer "rj" -true', { "ToggleGodModEveryone" }, G .. "GodModPlayer")
add("players", "invisible", nil, "/invisible -value", "/invisible -true", { "ToggleInvisibleHimself" }, G .. "Invisible", { open = "cheats" })
add("players", "invisibleplayer", nil, '/invisibleplayer "username" -value', '/invisibleplayer "rj" -true', { "ToggleInvisibleEveryone" }, G .. "InvisiblePlayer")
add("players", "noclip", nil, '/noclip "username" -value', '/noclip "rj" -true', { "ToggleNoclipHimself" }, G .. "NoClip", { open = "cheats" })
add("players", "players", nil, "/players", "/players", { "SeePlayersConnected" }, G .. "Players")
add("players", "debugplayer", nil, '/debugplayer "username"', '/debugplayer "rj"', { "ConnectWithDebug" }, "UI_ZeD_Console_CmdDebugPlayer")
-- items and skills
add("items", "additem", nil, '/additem "username" "module.item" count', '/additem "rj" Base.Axe 5', { "AddItem" }, G .. "AddItem", { open = "items" })
add("items", "removeitem", nil, '/removeitem "module.item" count', "/removeitem Base.Axe 5", { "EditItem" }, G .. "RemoveItem")
add("items", "addkey", nil, '/addkey "username" "keyId" "name"', '/addkey "rj" 7295', { "AddItem" }, G .. "AddKey")
add("items", "addxp", nil, '/addxp "playername" perkname=xp -true', '/addxp "rj" Woodwork=2 -true', { "AddXP" }, G .. "AddXp", { open = "player" })
add("items", "addvehicle", nil, '/addvehicle "script" "user or x,y,z"', '/addvehicle "Base.VanAmbulance" "rj"', { "ManipulateVehicle" }, G .. "AddVehicle", { say = "UI_ZeD_Console_SpVehicle" })
-- world
add("world", "createhorde", nil, '/createhorde count "username"', '/createhorde 150 "rj"', { "CreateHorde" }, G .. "CreateHorde", { say = "UI_ZeD_Console_SpZombies" })
add("world", "createhorde2", nil, "/createhorde2 -x x -y y -z z -count n -radius r -crawler -isFallOnFront -isFakeDead -knockedDown -isInvulnerable -isSitting -onFire -outfit name", "/createhorde2 -count 10 -radius 5", { "CreateHorde" }, "UI_ZeD_Console_CmdCreateHorde2", { say = "UI_ZeD_Console_SpZombies" })
add("world", "removezombies", nil, "/removezombies -radius n -x x -y y -z z -reanimated -remove", "/removezombies -radius 20", { "ManipulateZombie" }, "UI_ZeD_Console_CmdRemoveZombies", { say = "UI_ZeD_Console_SpZombies" }, NO_UNDO)
add("world", "remove", nil, "/remove zombies|corpses|vehicles|animals", "/remove corpses", { "AnimalCheats" }, "UI_ZeD_Console_CmdRemove", nil, NO_UNDO)
add("world", "list", nil, "/list animals", "/list animals", { "LoginOnServer" }, "UI_ZeD_Console_CmdList")
add("world", "startrain", nil, '/startrain "intensity"', "/startrain 50", { "StartStopRain" }, G .. "StartRain", { open = "climate" })
add("world", "stoprain", nil, "/stoprain", "/stoprain", { "StartStopRain" }, G .. "StopRain", { open = "climate" })
add("world", "startstorm", nil, '/startstorm "duration"', "/startstorm 12", { "StartStopRain" }, G .. "StartStorm", { open = "climate" })
add("world", "stopweather", nil, "/stopweather", "/stopweather", { "StartStopRain" }, G .. "StopWeather", { open = "climate" })
add("world", "thunder", nil, '/thunder "username"', '/thunder "rj"', { "StartStopRain" }, G .. "Thunder", { open = "climate" })
add("world", "lightning", nil, '/lightning "username"', '/lightning "rj"', { "MakeEventsAlarmGunshot" }, G .. "Lightning", { open = "climate" })
add("world", "alarm", nil, "/alarm", "/alarm", { "MakeEventsAlarmGunshot" }, G .. "Alarm")
add("world", "chopper", nil, "/chopper", "/chopper", { "MakeEventsAlarmGunshot" }, G .. "Chopper", { open = "general" })
add("world", "gunshot", nil, "/gunshot", "/gunshot", { "MakeEventsAlarmGunshot" }, G .. "Gunshot")
add("world", "setTimeSpeed", { "sts" }, "/setTimeSpeed period", "/setTimeSpeed 10", { "ConnectWithDebug" }, G .. "SetTimeSpeed", { say = "UI_ZeD_Console_SpSpeed" })
-- moderation
add("moderation", "kickuser", { "kick" }, '/kickuser "username" -r "reason"', '/kickuser "rj" -r "spam"', { "KickUser" }, G .. "Kick")
add("moderation", "banuser", nil, '/banuser "username" -ip -r "reason"', '/banuser "rj" -ip -r "spawn kill"', { "BanUnbanUser" }, G .. "BanUser")
add("moderation", "unbanuser", nil, '/unbanuser "username"', '/unbanuser "rj"', { "BanUnbanUser" }, G .. "UnBanUser")
add("moderation", "banid", nil, "/banid SteamID", "/banid 76561198000000000", { "BanUnbanUser" }, G .. "BanSteamId")
add("moderation", "unbanid", nil, "/unbanid SteamID", "/unbanid 76561198000000000", { "BanUnbanUser" }, G .. "UnBanSteamId")
add("moderation", "banip", nil, "/banip IP", "/banip 192.168.0.10", { "BanUnbanUser" }, G .. "BanIp")
add("moderation", "unbanip", nil, "/unbanip IP", "/unbanip 192.168.0.10", { "BanUnbanUser" }, G .. "UnBanIp")
add("moderation", "voiceban", nil, '/voiceban "username" -value', '/voiceban "rj" -true', { "BanUnbanUser" }, G .. "VoiceBan")
add("moderation", "setaccesslevel", nil, '/setaccesslevel "username" "accesslevel"', '/setaccesslevel "rj" "moderator"', { "ChangeAccessLevel" }, G .. "SetAccessLevel")
add("moderation", "grantadmin", nil, '/grantadmin "username"', '/grantadmin "rj"', { "ChangeAccessLevel" }, "UI_ZeD_Console_CmdGrantAdmin", nil, NO_UNDO)
add("moderation", "removeadmin", nil, '/removeadmin "username"', '/removeadmin "rj"', { "ChangeAccessLevel" }, "UI_ZeD_Console_CmdRemoveAdmin", nil, NO_UNDO)
add("moderation", "adduser", nil, '/adduser "username" "password"', '/adduser "rj" "password"', { "ModifyNetworkUsers" }, G .. "AddUser")
add("moderation", "addsteamid", nil, '/addSteamID "steamid"', '/addSteamID "76561198000000000"', { "ModifyNetworkUsers" }, G .. "AddSteamID")
add("moderation", "removesteamid", nil, '/removeSteamID "steamid"', '/removeSteamID "76561198000000000"', { "ModifyNetworkUsers" }, G .. "RemoveSteamID")
add("moderation", "setpassword", nil, '/setpassword "username" "newpassword"', '/setpassword "rj" "newpassword"', { "ModifyNetworkUsers" }, G .. "SetPassword")
add("moderation", "removeuserfromwhitelist", nil, '/removeuserfromwhitelist "username"', '/removeuserfromwhitelist "rj"', { "ManipulateWhitelist" }, G .. "RemoveWhitelist")
add("moderation", "addtosafehouse", nil, '/addtosafehouse "title" "username"', '/addtosafehouse "Farm" "rj"', { "CanSetupSafehouses" }, G .. "AddToSafehouse")
add("moderation", "kickfromsafehouse", nil, '/kickfromsafehouse "title" "username"', '/kickfromsafehouse "Farm" "rj"', { "CanSetupSafehouses" }, G .. "KickFromSafehouse")
add("moderation", "releasesafehouse", nil, '/releasesafehouse "title"', '/releasesafehouse "Farm"', { "CanSetupSafehouses" }, G .. "ReleaseSafeHouse")
add("moderation", "removemapsymbolsforuser", nil, '/removemapsymbolsforuser "username"', '/removemapsymbolsforuser "rj"', { "EditMapSymbols" }, G .. "RemoveMapSymbolsForUser", nil, NO_UNDO)
-- server
add("server", "servermsg", nil, '/servermsg "My Message"', '/servermsg "Restart in 10 minutes"', { "DisplayServerMessage" }, G .. "ServerMsg")
add("server", "save", nil, "/save", "/save", { "SaveWorld" }, G .. "Save", { say = "UI_ZeD_Console_SpSave" })
add("server", "quit", nil, "/quit", "/quit", { "QuitWorld" }, G .. "Quit", nil, NO_UNDO)
add("server", "showoptions", nil, "/showoptions", "/showoptions", { "SeePublicServerOptions" }, G .. "ShowOptions", { open = "sandbox" })
add("server", "changeoption", nil, '/changeoption optionName "newValue"', '/changeoption PVP "false"', { "ChangeAndReloadServerOptions" }, G .. "ChangeOptions", { open = "sandbox" }, NO_UNDO)
add("server", "reloadoptions", nil, "/reloadoptions", "/reloadoptions", { "ChangeAndReloadServerOptions" }, G .. "ReloadOptions")
add("server", "reloadlua", nil, '/reloadlua "filename"', '/reloadlua "ISChat.lua"', { "ReloadLuaFiles" }, G .. "ReloadLua", { say = "UI_ZeD_Console_SpLua" })
add("server", "reloadalllua", { "reloadluaall" }, "/reloadalllua", "/reloadalllua", { "ReloadLuaFiles" }, "UI_ZeD_Console_CmdReloadAllLua", { say = "UI_ZeD_Console_SpLua" })
add("server", "log", nil, '/log "debug type" "severity"', "/log General Warning", { "DebugConsole" }, "UI_ZeD_Console_CmdLog", { say = "UI_ZeD_Console_SpLog" })
add("server", "stats", nil, "/stats none|file|console|all period", "/stats file 10", { "GetStatistic" }, G .. "Statistics")
add("server", "worldgen", nil, "/worldgen start|recheck|stop|status", "/worldgen status", { "SaveWorld" }, G .. "Worldgen")
add("server", "checkModsNeedUpdate", nil, "/checkModsNeedUpdate", "/checkModsNeedUpdate", { "ManipulateMods" }, G .. "CheckModsNeedUpdate")
add("server", "clear", nil, "/clear", "/clear", { "LoginOnServer" }, "UI_ZeD_Console_CmdClear")
add("server", "help", nil, "/help command", "/help additem", { "LoginOnServer" }, "UI_ZeD_Console_CmdHelpCmd", { say = "UI_ZeD_Console_SpHelp" })
-- chat channels, and the two chat lines everyone may type
local CHAT = { chat = true }
add("chat", "all", nil, "/all message", "/all anyone near the mall?", { "LoginOnServer" }, "UI_ZeD_Console_ChatAll", nil, CHAT)
add("chat", "say", { "s" }, "/say message", "/say over here", { "LoginOnServer" }, "UI_ZeD_Console_ChatSay", nil, CHAT)
add("chat", "yell", { "y" }, "/yell message", "/yell RUN", { "LoginOnServer" }, "UI_ZeD_Console_ChatYell", nil, CHAT)
add("chat", "whisper", { "w" }, '/whisper "username" message', '/whisper "rj" meet at the drag strip', { "LoginOnServer" }, "UI_ZeD_Console_ChatWhisper", nil, CHAT)
add("chat", "faction", { "f" }, "/faction message", "/faction regroup", { "LoginOnServer" }, "UI_ZeD_Console_ChatFaction", nil, CHAT)
add("chat", "safehouse", { "sh" }, "/safehouse message", "/safehouse door's open", { "LoginOnServer" }, "UI_ZeD_Console_ChatSafehouse", nil, CHAT)
add("chat", "admin", { "a" }, "/admin message", "/admin someone's duping", { "CanSeeMessageForAdmin" }, "UI_ZeD_Console_ChatAdmin", nil, CHAT)
add("chat", "roll", nil, "/roll sides", "/roll 6", { "LoginOnServer" }, G .. "Roll")
add("chat", "card", nil, "/card", "/card", { "LoginOnServer" }, G .. "Card")
CC.list = L

-- every name and other name, lower case -> the command
CC.byName = {}
for _, c in ipairs(L) do
    CC.byName[string.lower(c.name)] = c
    for _, a in ipairs(c.also) do CC.byName[string.lower(a)] = c end
end

--- The command a line starts with ("/kick ..." -> kickuser's row), nil when it names none.
function CC.find(text)
    local head = string.match(tostring(text or ""), "^%s*/?([%w_]+)")
    return head and CC.byName[string.lower(head)] or nil
end

-- ---------------------------------------------------------------------------
-- WHERE AND WHO
-- ---------------------------------------------------------------------------
local function safe(fn, dflt)
    local ok, v = pcall(fn)
    if ok and v ~= nil then return v end
    return dflt
end

--- On a server? (in single player there is nothing to send to)
function CC.server()
    if CC.qaServer ~= nil then return CC.qaServer end
    return safe(function() return isClient() end, false) == true
end

--- Does this player's role have the capability? (CC.qaCaps stands in for the role in the sims)
function CC.can(cap)
    if CC.qaCaps then return CC.qaCaps[cap] == true end
    local p = getPlayer and getPlayer()
    local c = Capability and Capability[cap]
    if not (p and c) then return false end
    return safe(function() return p:getRole():hasCapability(c) end, false) == true
end

--- Does this player see the command? Single player: all. A server: a role with one of its capabilities, or the host.
function CC.visible(c)
    if not CC.server() then return true end
    if CC.qaCaps == nil and safe(function() return isCoopHost() end, false) == true then return true end
    for _, cap in ipairs(c.caps) do
        if CC.can(cap) then return true end
    end
    return false
end

-- the server's roles, lowest first: { name, caps = { [cap] = true } } (ZeD.Admin's reading, kept there), or nil
local function serverRoles()
    if CC.qaRoles then return CC.qaRoles end
    if not CC.server() then return nil end
    local A = ZeD.Admin
    if not (A and A.roles) then return nil end
    local list = safe(A.roles, nil)
    if type(list) ~= "table" or #list == 0 then return nil end
    return list
end

-- a role's name as shown: "gm" GM, "moderator" Moderator
local function roleWord(name)
    name = tostring(name or "")
    if string.lower(name) == "gm" then return "GM" end
    return string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
end
CC.roleWord = roleWord

--- The lowest role that may use the command: its name as shown, and its rank among the default roles (1 user ..
--- 5 admin, for the status pixel's color). From the server's roles when they can be read, else the defaults.
function CC.level(c)
    local roles = serverRoles()
    if roles then
        for _, r in ipairs(roles) do
            for _, cap in ipairs(c.caps) do
                if r.caps and r.caps[cap] then
                    local rank = 4
                    for i, d in ipairs(CC.DEFAULT_ROLES) do if d == string.lower(tostring(r.name)) then rank = i end end
                    return roleWord(r.name), rank
                end
            end
        end
    end
    local best = nil
    for _, cap in ipairs(c.caps) do
        local lv = CC.DEFAULT_LEVEL[cap] or "moderator"
        for i, d in ipairs(CC.DEFAULT_ROLES) do
            if d == lv and (best == nil or i < best) then best = i end
        end
    end
    best = best or 4
    return roleWord(CC.DEFAULT_ROLES[best]), best
end

--- Your role's name as shown (nil in single player or when it can't be read).
function CC.myRole()
    if CC.qaRole then return CC.qaRole end
    if not CC.server() then return nil end
    local n = safe(function() return getPlayer():getRole():getName() end, nil)
    return n and roleWord(n) or nil
end

-- ---------------------------------------------------------------------------
-- THE WORDS: what a command does (the game's help, or ZeD's), and the search
-- ---------------------------------------------------------------------------
--- What the command does, in the player's language.
function CC.does(c)
    if string.sub(c.help, 1, 7) == "UI_ZeD_" then return ZeD.tr(c.help) end
    local ok, s = pcall(getText, c.help)
    if ok and s and s ~= c.help then return tostring(s) end
    return ""
end

--- Does the command match the search? (its names, its syntax, what it does and its capabilities; any case)
function CC.matches(c, q)
    if q == nil or q == "" then return true end
    q = string.lower(q)
    local hay = c._hay
    if not hay then
        hay = string.lower(c.name .. " " .. table.concat(c.also, " ") .. " " .. c.syn .. " " .. CC.does(c) .. " " .. table.concat(c.caps, " "))
        c._hay = hay
    end
    return string.find(hay, q, 1, true) ~= nil
end

--- The commands shown, in group order: { { group, cmds = { ... } }, ... } and how many in all.
function CC.shown(q)
    local out, n = {}, 0
    for _, g in ipairs(CC.GROUPS) do
        local cmds = {}
        for _, c in ipairs(L) do
            if c.grp == g.id and CC.visible(c) and CC.matches(c, q) then cmds[#cmds + 1] = c end
        end
        if #cmds > 0 then
            out[#out + 1] = { group = g, cmds = cmds }
            n = n + #cmds
        end
    end
    return out, n
end

--- The count the head shows against: every command this player may see.
function CC.total()
    local n = 0
    for _, c in ipairs(L) do if CC.visible(c) then n = n + 1 end end
    return n
end

-- ---------------------------------------------------------------------------
-- SINGLE PLAYER: the debug menu's way of doing it
-- ---------------------------------------------------------------------------
--- What it is alone: { open = id, label = the debug menu button's words } for a window that opens, { say = words }
--- for one that does not, nil for none.
function CC.alone(c)
    local sp = c.sp
    if sp.open then
        local o = CC.OPEN[sp.open]
        local ok, label = pcall(getText, o.label)
        return { open = sp.open, label = (ok and label) and tostring(label) or o.label }
    end
    if sp.say then return { say = ZeD.tr(sp.say) } end
    return nil
end

--- Open the command's debug window (single player). True when it opened.
function CC.openAlone(c)
    local o = c.sp.open and CC.OPEN[c.sp.open]
    if not o then return false end
    if CC.qaOpen then CC.qaOpen(c.sp.open); return true end
    local cls = _G[o.class]
    if type(cls) ~= "table" then return false end
    local ok
    if o.sandbox then
        ok = type(cls.onClickSandboxSettings) == "function" and pcall(cls.onClickSandboxSettings, cls)
    else
        ok = type(cls.OnOpenPanel) == "function" and pcall(cls.OnOpenPanel)
    end
    return ok == true
end

-- ---------------------------------------------------------------------------
-- SENDING
-- ---------------------------------------------------------------------------
--- Does the line need asking first? (it starts with a command that can't be undone)
function CC.asks(text)
    local c = CC.find(text)
    return c ~= nil and c.undo == false
end

--- Send a line as chat does. Returns "sent" (to the server), "chat" (a chat channel, through ZeD's chat), "filled"
--- (no way to send: it waits in the chat box), or false.
function CC.send(text)
    text = tostring(text or "")
    if (string.gsub(text, "%s", "")) == "" then return false end
    if CC.qaSend then return CC.qaSend(text) end
    local c = CC.find(text)
    if c and c.chat and ZeD.Chat and ZeD.Chat.send then
        local ok, sent = pcall(ZeD.Chat.send, text)
        return (ok and sent) and "chat" or false
    end
    -- (the server path, as ISChat:onCommandEntered sends a "/" line: unproven in game until QA's multiplayer run)
    if type(SendCommandToServer) == "function" then
        local ok = pcall(SendCommandToServer, text)
        if ok then return "sent" end
    end
    -- (no send call: the line goes into ZeD's chat box, to be sent from there)
    local C = ZeD.Chat
    if C and C.open then
        local ok = pcall(function()
            C.open(true)
            C.win.input:setText(text)
        end)
        if ok then return "filled" end
    end
    return false
end

return CC
