-- ZeD-UI/42/media/lua/shared/ZeD/ZeD_AdminProto.lua
-- ============================================================================
-- THE ADMIN PROTOCOL (ZeDUI/MP_ADMIN_SCOPE.md, Phase 2). What both sides agree on: the module, the ban lengths, the
-- repeats, the powers the game switches on with a role, every limit, and the capabilities in their five groups. Pure
-- Lua, ASCII, nothing client-only at load: this file also runs on a dedicated server.
-- ============================================================================

ZeD = ZeD or {}
ZeD.Adm = ZeD.Adm or {}
local Adm = ZeD.Adm

Adm.MOD = "ZeDA"

-- THE DIRECTOR'S QUESTIONS, answered the careful way, each kept to one switch (MP_SERVER_PART_DESIGN.md, the last section)
-- TIMED_IP: may a timed ban carry Ban IP too? Server Lua cannot see an IP, so only the game's IP ban exists, and that one
-- lifts only when a staff client runs it. false: Ban IP too goes with Permanent alone, grayed with its reason.
Adm.TIMED_IP = false
-- RANK_GUARD: may staff kick, ban, warn, mute, bring or level a player whose role sits above theirs? The game only asks
-- that for a role change. true: nobody acts on a role above their own.
Adm.RANK_GUARD = true
-- MUTE_STAFF_SEES: a muted player's lines are hidden on every ZeD client. true: staff still read them, marked.
Adm.MUTE_STAFF_SEES = true
-- SPAWN_TELLS: does a player hear that an admin spawned items to them? false: no note, as the game's /additem.
Adm.SPAWN_TELLS = false

-- the ban lengths, as drawn; Permanent is the game's ban, the rest ZeD's own (E7, settled)
Adm.LENGTHS = {
    { id = "h1", sec = 3600, key = "UI_ZeD_Adm_Len1h" },
    { id = "d1", sec = 86400, key = "UI_ZeD_Adm_Len1d" },
    { id = "d3", sec = 259200, key = "UI_ZeD_Adm_Len3d" },
    { id = "w1", sec = 604800, key = "UI_ZeD_Adm_Len1w" },
    { id = "perm", key = "UI_ZeD_Adm_LenPerm" },
}
Adm.LENGTH = {}
for _, l in ipairs(Adm.LENGTHS) do Adm.LENGTH[l.id] = l end
Adm.DEFAULT_LEN = "d3"

Adm.EVERY = { 15, 30, 60, 120 }     -- Repeat every, in minutes
Adm.EVERY_OK = {}
for _, m in ipairs(Adm.EVERY) do Adm.EVERY_OK[m] = true end

-- the powers GameServer.changeRole switches on with a role, when the old role lacked them: id is the game's own option
-- in ISAdminPowerUI (IGUI_CheatPanel_<id>)
Adm.POWERS = {
    { id = "Invisible", cap = "ToggleInvisibleHimself" },
    { id = "NoClip", cap = "ToggleNoclipHimself" },
    { id = "GodMod", cap = "ToggleGodModHimself" },
}

-- every power on the Admin tab (ISAdminPowerUI.OptionList) and the capability the game asks for it: what the server takes
-- for a line in the log
Adm.POWER_CAP = {
    Invisible = "ToggleInvisibleHimself", GodMod = "ToggleGodModHimself", NoClip = "ToggleNoclipHimself",
    FastMove = "UseFastMoveCheat", TimedActionInstant = "UseTimedActionInstantCheat", UnlimitedCarry = "ToggleUnlimitedCarry",
    UnlimitedEndurance = "ToggleUnlimitedEndurance", UnlimitedAmmo = "ToggleUnlimitedAmmo", KnowAllRecipes = "ToggleKnowAllRecipes",
    BuildCheat = "UseBuildCheat", FarmingCheat = "UseFarmingCheat", FishingCheat = "UseFishingCheat", HealthCheat = "UseHealthCheat",
    MechanicsCheat = "UseMechanicsCheat", MoveableCheat = "UseMovablesCheat", CanSeeAll = "CanSeeAll", CanHearAll = "CanHearAll",
    ZombiesDontAttack = "ManipulateZombie", BrushTool = "UseBrushToolManager", LootZed = "UseLootZed", LootLog = "UseLootLog",
    AnimalCheat = "AnimalCheats", AnimalExtraValues = "AnimalCheats", AlwaysDay = "ClimateManager",
}

-- every limit in one place, so they can become server settings later
Adm.L = {
    REASON_MAX = 200,
    MSG_MAX = 200,
    WARN_MAX = 10,
    SPAWN_MAX = 100,
    REPEATS_MAX = 10,
    BANS_MAX = 1000,                    -- rows; past it the oldest permanent row the game holds goes, a timed one never
    MUTES_MAX = 500,
    PLAYERS_MAX = 2000,                 -- players remembered for the offline list, oldest out
    PLAYERS_ROWS = 500,                 -- rows in one a_players
    LOG_MAX = 2000,                     -- admin actions kept for Phase 4's Log view, oldest out
    LOG_ACTOR_MAX = 400,                -- past this share one account's new lines replace its own oldest
    LOG_TOLD_MAX = 100,                 -- the same for lines a client reports of itself (the container log)
    OWED_MAX = 200,                     -- game calls waiting for a staff client
    TICKETS_ROWS = 10,                  -- tickets on a player card
    TARGET_MAX = 64,                    -- a name, a Steam ID or an IP
    PLAYERS_MS = 2000,
    CARD_MS = 500,
    LIST_MS = 1000,
    SPAWN_MS = 500,
    POWER_MS = 1000,
    BAN_MS = 1500,                      -- between one account's bans, and its unbans
    POLL_S = 5,                         -- how often the server walks the players
    SNAP_S = 60,                        -- how often a player's card is copied for when they leave
    LEAVE_S = 12,                       -- how long a player reads the reason before they go
    IP_GAP_S = 3,                       -- after the IP call, the plain ban: a player still on means the game refused the IP
    STAY_S = 20,                        -- past this, a banned client that has not left is reported to staff
    STAY_EVERY_S = 300,                 -- and again this often
    OWED_RETRY_S = 15,                  -- a game call with no word back goes again
    ROLE_WATCH_S = 30,                  -- a role change waits this long for the game to apply it
    ROLE_WATCH_KEEP_S = 86400,          -- and this long for a player who is not on
    SID_ROUND = 64,                     -- a Steam ID in a Lua number is this near the real one (a double, past 2^53)
}

-- the five groups, as drawn; every capability the game has (getCapabilities) sits in one. One this list has not met yet
-- goes in the last group under its own name.
Adm.GROUPS = {
    { id = "players", key = "UI_ZeD_Adm_GrpPlayers", caps = {
        "SeePlayersConnected", "SeeNetworkUsers", "GetSteamScoreboard", "CanSeePlayersStats",
        "CanModifyPlayerStatsInThePlayerStatsUI", "CanModifyBodyStats", "InspectPlayerInventory", "KickUser",
        "BanUnbanUser", "AddUserlog", "ReadUserLog", "WorkWithUserlog", "TeleportToPlayer",
        "TeleportPlayerToAnotherPlayer", "TeleportToCoordinates", "ChangeAccessLevel", "ModifyNetworkUsers",
        "ManipulateWhitelist", "AddXP" } },
    { id = "tickets", key = "UI_ZeD_Adm_GrpTickets", caps = {
        "AnswerTickets", "CanSeeMessageForAdmin", "DisplayServerMessage", "AdminChat", "IgnoreChatSlowMode",
        "EmptyLinesInChat", "ToggleWriteRoleNameAbove" } },
    { id = "powers", key = "UI_ZeD_Adm_GrpPowers", caps = {
        "ToggleGodModHimself", "ToggleInvisibleHimself", "ToggleInvincibleHimself", "ToggleNoclipHimself",
        "ToggleGodModEveryone", "ToggleInvisibleEveryone", "ToggleNoclipEveryone", "ToggleUnlimitedEndurance",
        "ToggleKnowAllRecipes", "ToggleUnlimitedAmmo", "ToggleUnlimitedCarry", "UseMovablesCheat", "UseFastMoveCheat",
        "UseBuildCheat", "UseFarmingCheat", "UseFishingCheat", "UseHealthCheat", "UseMechanicsCheat",
        "UseTimedActionInstantCheat", "UseZombieDontAttackCheat", "CanMedicalCheat", "AnimalCheats", "GeneralCheats",
        "CanSeeAll", "CanHearAll", "SeesInvisiblePlayers", "CanOpenLockedDoors", "CanGoInsideSafehouses",
        "UseDebugContextMenu", "UseBrushToolManager", "UseLootZed", "UseLootLog" } },
    { id = "world", key = "UI_ZeD_Adm_GrpWorld", caps = {
        "AddItem", "EditItem", "CanSetupSafehouses", "CanSetupNonPVPZone", "FactionCheat", "ClimateManager",
        "StartStopRain", "MakeEventsAlarmGunshot", "CreateHorde", "CreateStory", "ManipulateZombie", "ManipulateVehicle",
        "PopmanManage", "EditMapSymbols", "SeeWorldMap" } },
    { id = "server", key = "UI_ZeD_Adm_GrpServer", caps = {
        "SeePublicServerOptions", "ChangeAndReloadServerOptions", "SandboxOptions", "PVPLogTool", "GetStatistic",
        "RolesRead", "RolesWrite", "SaveWorld", "QuitWorld", "ReloadLuaFiles", "BypassLuaChecksum", "ConnectWithDebug",
        "DebugConsole", "ManipulateMods", "UIManagerProcessCommands", "LoginOnServer", "PriorityLogin",
        "CanAlwaysJoinServer", "CantBeKickedIfTooLaggy", "CantBeKickedByUser", "CantBeBannedByUser",
        "CantBeKickedByAnticheat", "CantBeBannedByAnticheat", "HideFromSteamUserList" } },
}
Adm.CAP_GROUP = {}
for _, g in ipairs(Adm.GROUPS) do
    for _, c in ipairs(g.caps) do Adm.CAP_GROUP[c] = g.id end
end

-- the capabilities the server part reads (A3: a name missing from a later game leaves the part off, or the call would
-- match no overload)
Adm.SERVER_CAPS = {
    "SeePlayersConnected", "CanSeePlayersStats", "KickUser", "BanUnbanUser", "AddUserlog", "TeleportToPlayer",
    "TeleportPlayerToAnotherPlayer", "ChangeAccessLevel", "ModifyNetworkUsers", "AddXP", "DisplayServerMessage",
    "AddItem", "RolesWrite", "CantBeKickedByUser", "CantBeBannedByUser", "ToggleInvisibleHimself",
    "ToggleNoclipHimself", "ToggleGodModHimself",
}

-- what a typed target looks like: "ip", "sid" or "user". An IP is four numbers, a Steam ID seventeen digits from 7656. Only
-- for the Bans card's typed field: a username can look like a Steam ID, so a name from a row is never read by its shape
function Adm.targetKind(s)
    if type(s) ~= "string" then return nil end
    if string.match(s, "^%d+%.%d+%.%d+%.%d+$") then return "ip" end
    if #s == 17 and string.match(s, "^7656%d+$") then return "sid" end
    return "user"
end

-- a reason or a server message: one line, trimmed, within its limit; nil when it is not usable
function Adm.line(s, max)
    local c = ZeD.Tk.clean(s)
    if not c then return nil end
    c = string.gsub(c, "\n", " ")
    if #c < 1 or #c > max then return nil end
    return c
end

-- a word for a slash command: the game's parser ends a quoted argument at the next quote
function Adm.quoted(s) return "\"" .. string.gsub(tostring(s), "\"", "") .. "\"" end

return Adm
