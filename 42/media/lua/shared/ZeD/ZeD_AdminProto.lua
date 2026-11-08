-- ZeD-UI/42/media/lua/shared/ZeD/ZeD_AdminProto.lua
-- ============================================================================
-- THE ADMIN PROTOCOL: what both sides agree on. The module name, the ban lengths, the choices for a repeating message,
-- the powers the game switches on with a role, every limit, and the capabilities in their five groups. Shared: this
-- file loads on the client and on a dedicated server alike, so nothing client-only at file scope. Pure Lua, pure ASCII.
-- ============================================================================

-- Reload-safe: loading this file twice reuses the tables instead of wiping them
ZeD = ZeD or {}
ZeD.Adm = ZeD.Adm or {}
local Adm = ZeD.Adm

Adm.MOD = "ZeDA"            -- the module on every admin command

-- DESIGN CHOICES that could go either way, answered the careful way, each kept to one switch
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

-- the ban lengths the Bans card offers. Every one is the game's own ban too, which the server enforces at login; ZeD
-- lifts a timed one at its end. Timed lengths need the server part: without it, Permanent is the only one
Adm.LENGTHS = {
    { id = "h1", sec = 3600, key = "UI_ZeD_Adm_Len1h" },
    { id = "d1", sec = 86400, key = "UI_ZeD_Adm_Len1d" },
    { id = "d3", sec = 259200, key = "UI_ZeD_Adm_Len3d" },
    { id = "w1", sec = 604800, key = "UI_ZeD_Adm_Len1w" },
    { id = "perm", key = "UI_ZeD_Adm_LenPerm" },
}
Adm.LENGTH = {}
for _, l in ipairs(Adm.LENGTHS) do Adm.LENGTH[l.id] = l end
Adm.DEFAULT_LEN = "d3"              -- where a player card's ban length starts; Permanent without the server part

Adm.EVERY = { 15, 30, 60, 120 }     -- the choices for a repeating message's Repeat every, in minutes
Adm.EVERY_OK = {}
for _, m in ipairs(Adm.EVERY) do Adm.EVERY_OK[m] = true end

-- the powers GameServer.changeRole switches on with a role, when the old role lacked them: id is the game's own option
-- in ISAdminPowerUI (IGUI_CheatPanel_<id>)
Adm.POWERS = {
    { id = "Invisible", cap = "ToggleInvisibleHimself" },
    { id = "NoClip", cap = "ToggleNoclipHimself" },
    { id = "GodMod", cap = "ToggleGodModHimself" },
}

-- every power on the Admin tab (ISAdminPowerUI.OptionList) and the capability the game asks for it. A client's word that
-- it turned a power on or off makes a log line only for a power on this list, from a player who holds its capability
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
    REASON_MAX = 200,                   -- a kick, warning or ban reason
    MSG_MAX = 200,                      -- a server message, once or repeating
    WARN_MAX = 10,                      -- warning points in one warning
    SPAWN_MAX = 100,                    -- items in one spawn
    REPEATS_MAX = 10,                   -- repeating messages at once
    BANS_MAX = 1000,                    -- rows; past it the oldest permanent row the game holds goes, a timed one never
    MUTES_MAX = 500,                    -- players muted at once
    PLAYERS_MAX = 2000,                 -- players remembered for the offline list, oldest out
    PLAYERS_ROWS = 500,                 -- rows in one a_players
    LOG_MAX = 2000,                     -- lines kept for the Log view (every kind, not only admin actions), oldest out
    LOG_ACTOR_MAX = 400,                -- past this share one account's new lines replace its own oldest
    LOG_TOLD_MAX = 100,                 -- the same for lines a client reports of itself (the container log)
    OWED_MAX = 200,                     -- game calls waiting for a staff client
    TICKETS_ROWS = 10,                  -- tickets on a player card
    TARGET_MAX = 64,                    -- a name, a Steam ID or an IP
    PLAYERS_MS = 2000,                  -- between two asks for the players list, from one player
    CARD_MS = 500,                      -- between two player cards
    LIST_MS = 1000,                     -- between two asks for the bans, and for the repeats
    SPAWN_MS = 500,                     -- between two spawns
    POWER_MS = 1000,                    -- between two power lines for the log
    BAN_MS = 1500,                      -- between one account's bans, and its unbans
    POLL_S = 5,                         -- how often the server walks the players
    SNAP_S = 60,                        -- how often a player's card is copied for when they leave
    LEAVE_S = 12,                       -- how long a player reads the reason before they go
    IP_GAP_S = 3,                       -- after the IP call, the plain ban: a player still on means the game refused the IP
    STAY_S = 20,                        -- past this, a banned client that has not left is reported to staff
    STAY_EVERY_S = 300,                 -- and again this often
    OWED_RETRY_S = 15,                  -- a game call with no word back goes again
    VERIFY_S = 10,                      -- a client's "done" is not proof: past this, a banned player still on means the ban did not take
    REOWE_MAX = 3,                      -- a game ban that did not take is asked for again this many times, then a log line
    LIFT_LOOK_N = 10,                   -- rows whose Steam ID or IP the game held, read back each walk for one it lifted (a query each)
    OFF_GAP_S = 5,                      -- a Steam ID or IP read off the game's list counts only when a second read this much later agrees
    LOOK_N = 20,                        -- names in one look at the game's user list, asked of a staff client
    LOOK_EVERY_S = 60,                  -- each name ban row is looked at this often
    LOOK_SETTLE_S = 3,                  -- a name ban just made is looked at this soon after its "done"
    LOOK_GAP_S = 2,                     -- between one look and the next
    LOOK_WAIT_S = 10,                   -- a look not answered in this long counts for nothing
    LOOK_HOLD_S = 25,                   -- a held name ban's player found on: re-ban and leave screen wait this long for a look
    LIFT_FRESH_S = 10,                  -- a look proves a lift only when asked this long after the look that saw the ban
    BANNED_ROLE = "banned",             -- the game's own role for a name ban (Roles.addStatic; its default for banned)
    HELPER_POLL_S = 2,                 -- how often the server reads the host helper's answers and writes its queue
    HELPER_ALIVE_S = 30,                -- the helper counts as running while its last answers file is this fresh
    HELPER_WAIT_S = 30,                 -- a call the helper has not answered in this long goes to a staff client as well
    HELPER_TRIES = 3,                   -- a call the helper failed this many times is left to staff clients
    HELPER_LOG_S = 60,                  -- the helper's failures make one log line this often at most, with a count
    ROLE_WATCH_S = 30,                  -- a role change waits this long for the game to apply it
    ROLE_WATCH_KEEP_S = 86400,          -- and this long for a player who is not on
}

-- the five groups the Roles card sorts capabilities into; every capability the game has (getCapabilities) sits in one.
-- One this list has not met yet (a later game added it) goes in the last group under its own name.
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
Adm.CAP_GROUP = {}                  -- capability -> its group's id
for _, g in ipairs(Adm.GROUPS) do
    for _, c in ipairs(g.caps) do Adm.CAP_GROUP[c] = g.id end
end

-- the capabilities the server part reads. One missing from a later game leaves the admin tools off: looked up anyway,
-- it would be nil, and a call with nil matches no overload
Adm.SERVER_CAPS = {
    "SeePlayersConnected", "CanSeePlayersStats", "KickUser", "BanUnbanUser", "AddUserlog", "TeleportToPlayer",
    "TeleportPlayerToAnotherPlayer", "ChangeAccessLevel", "ModifyNetworkUsers", "AddXP", "DisplayServerMessage",
    "AddItem", "RolesWrite", "CantBeKickedByUser", "CantBeBannedByUser", "ToggleInvisibleHimself",
    "ToggleNoclipHimself", "ToggleGodModHimself",
}

--- what a target looks like: "ip", "sid" or "user" (nil unless given a string). An IP is four numbers, a Steam ID
--- seventeen digits from 7656. A username can look like a Steam ID, so the shape is only a reading: where a name is
--- known (a player the server has met, a row on the list), the callers take the name first
function Adm.targetKind(s)
    if type(s) ~= "string" then return nil end
    if string.match(s, "^%d+%.%d+%.%d+%.%d+$") then return "ip" end
    if #s == 17 and string.match(s, "^7656%d+$") then return "sid" end
    return "user"
end

--- a reason or a server message: one line (line breaks become spaces), trimmed, 1 to max characters; nil otherwise
function Adm.line(s, max)
    local c = ZeD.Tk.clean(s)
    if not c then return nil end
    c = string.gsub(c, "\n", " ")
    if #c < 1 or #c > max then return nil end
    return c
end

--- a word for a slash command, in quotes, with any quote inside it dropped: the game's parser ends a quoted argument
--- at the next quote
function Adm.quoted(s) return "\"" .. string.gsub(tostring(s), "\"", "") .. "\"" end

return Adm
