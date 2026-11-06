# The server part: what the game allows, and Phase 1 tickets (Nov 5 2026)

For the next build step. Follows `MP_ADMIN_SCOPE.md`, `MP_DECISIONS.md` and `mockups/zed_tickets_v2.html`.
Everything in Part A was read from Project Zomboid 42.22 itself: the vanilla Lua (paths below start at `media/lua/`,
with the line) and `projectzomboid.jar` through `javap` (class and member named). Nothing is from memory. What could not
be read off the code is in Part E, each with how QA settles it. Nothing here is built.

## The six facts that change the plan

1. **Any logged-in client can read any global mod data table by name.** `ModData.request` needs only the Login
   capability and the server answers with no other check (A2). Not transmitting is not enough: a table named
   `ZeD_Tickets` holding admin notes could be read by any player with a Lua console. ZeD's table gets a secret random
   name (B2).
2. **Server Lua cannot touch the game's tickets.** `addTicket`, `getTickets`, `removeTicket` and `viewedTicket` do
   nothing on a server: each is guarded by `GameClient.client`. All game-side ticket work is done by a client, the
   player's or a staff member's (A4, B8).
3. **Server Lua cannot kick, ban or unban.** No Lua path reaches `BanSystem` or `GameServer.kick`. A temp ban cannot lift
   itself from a server timer alone (A7). This one needs a design decision before Phase 2.
4. **`OnTick` and the game clock stop on a server with `PauseEmpty` (default true).** `OnTickEvenPaused` does not. Any
   server timer that must run with nobody on uses `OnTickEvenPaused` and `getTimestamp` (A1, A7).
5. **`SaveWorldEveryMinutes` defaults to 0.** On a default server global mod data is written only by `/save`, by `/quit`
   and on shutdown. A crash loses every ticket since the last save (A2, B10).
6. **A game ticket is public and unsigned.** Any logged-in client can read every game ticket, file one under any name and
   answer any of them, with no rate limit. ZeD's first message and first answer are as public as the game makes them.
   Nothing that comes back from the game's side is proof of anything, except `viewed`, which needs `AnswerTickets` (A4, B8).

---

# Part A: what the game does

## A1. How server Lua runs, and how client and server talk

**Which folders run where** (`zombie.Lua.LuaManager.LoadDirBase(String, boolean)`: the boolean true skips `RunLua` and
only adds the file to the checksum).

| Process | shared | client | server | Source |
|---|---|---|---|---|
| Dedicated server | runs | checksummed only, not run | runs | `zombie.network.GameServer`: `LoadDirBase("shared")`, `LoadDirBase("client", true)`, `LoadDirBase("server")` |
| Host's own server | runs | checksummed only, not run | runs | the same class: `CoopMaster.launchServer` starts a second Java process through `ProcessBuilder`, `zombie.network.GameServer -coop -servername ... -adminusername ...`. It shares no memory with the host's game (B12) |
| Multiplayer client, single player | runs | runs | **runs too** | `LuaManager.LoadDirBase()` runs shared and client; `zombie.gameStates.GameLoadingState` calls `LoadDirBase("server")` with no guard around it |

So every server file runs on clients as well and must begin with a guard. Vanilla does this in 33 files
(`server/ClientCommands.lua:1`: `if isClient() then return end`). ZeD uses the stricter form vanilla uses in
`server/Foraging/forageServer.lua:1`, `if not isServer() then return; end;`, because ZeD's server part has no use in
single player, where `isClient()` is false too.

ZeD's existing `42/media/lua/shared` already runs on a server, so a new `shared` file must call nothing client-only at
load.

**Telling the sides apart** (`zombie.Lua.LuaManager$GlobalObject`):

| | `isServer()` | `isClient()` | `isCoopHost()` |
|---|---|---|---|
| Dedicated server or the host's server process | true | false | false |
| The host's game client | false | true | true |
| A joined client | false | true | false |
| Single player | false | false | false |

`isServer()` returns `GameServer.server`, `isClient()` returns `GameClient.client`, and `isCoopHost()` reads
`GameClient.connection.isCoopHost` (false when there is no connection). Server Lua cannot tell a host's server from a
dedicated one. It does not need to.

**The messages** (signatures from `javap`):

```
public static void sendClientCommand(IsoPlayer, String, String, KahluaTable);
public static void sendClientCommand(String, String, KahluaTable);
public static void sendServerCommand(IsoPlayer, String, String, KahluaTable);
public static void sendServerCommand(String, String, KahluaTable);          // to every connection
```

- Client to server: `sendClientCommand(player, module, command, args)`. The packet carries the player's index, never a
  name. `GameServer.receiveClientCommand` finds the player from the connection, so **the `player` an `OnClientCommand`
  handler gets is trustworthy**. Its arguments are not.
- The handler: `Events.OnClientCommand.Add(function(module, command, player, args) ... end)`
  (`server/ClientCommands.lua:1346`). Every handler sees every command, so test the module first and return.
- Server to client: `sendServerCommand(player, module, command, args)`. The handler:
  `Events.OnServerCommand.Add(function(module, command, args) ... end)` (`client/ServerCommands.lua:207`). A player not
  in `PlayerToAddressMap` is skipped silently.
- `sendClientCommand` with no player sends index -1 and the server picks any player on the connection; with no player
  at all it logs `receiveClientCommand: player is null` and drops it. Send only after the local player exists.
- `sendClientCommand` throws `IllegalStateException` if called with three arguments on a server. Single player goes
  through `SinglePlayerClient`.

**Argument rules** (`zombie.network.TableNetworkUtils`):

- Keys: `String` or `Double`. Values: `String`, `Double`, `Boolean`, a table, `InventoryItem`, `IsoDirections`,
  `IsoDeadBody`. An entry of any other type is skipped, with a line in the debug log.
- An empty top table arrives as nil: "Can be nil if sending an empty table" (`client/ServerCommands.lua:210`). The
  writer sends `false` for "has args" when `isEmpty()`. Handlers must accept nil `args`.
- Strings: `GameWindow.WriteString` writes a two-byte length and `GameWindow$StringUTF.load` reads it with `getShort`,
  returning "" when the value is not positive. **A string over 32767 encoded bytes comes back empty.**
- Message size: `UdpConnection` allocates `ByteBuffer.allocate(1000000)` for `startPacket`, and `UdpEngine` a
  1000000-byte reader. That is the hard ceiling. ZeD keeps every message under 200 kB and pages lists.

**Rate limits:** `GameServer.receiveClientCommand` has none. `ClientCommandFilter` only decides what is written to the
`cmd` log: default `-vehicle.*;+vehicle.damageWindow;+vehicle.fixPart;+vehicle.installPart;+vehicle.uninstallPart`
(`zombie.network.ServerOptions`). ZeD's commands will show in `Logs/*_cmd.txt` by name, without arguments, as
`ISLogSystem.writeLog` does in QA's logs today. Vanilla keeps its own server limiter in Lua
(`server/Foraging/forageServer.lua`: `forageServer.lastReqMs`, `forageServer.minReqMs = 250`), and so does ZeD.

**Timers on a server.** `GameServer`'s main loop calls `IngameState.update` every pass. In
`IngameState.updateInternal`:

- `OnTickEvenPaused` fires first, before any pause test.
- `paused` is then set when `GameServer.Players` is empty and `ServerOptions.pauseEmpty` is on. `PauseEmpty` defaults
  to true.
- The block holding `UpdateStuff()` and `onTick()` runs only while not paused (`if (!paused || GameClient.client)`).
  `UpdateStuff` is what calls `GameTime.update`, which fires `EveryOneMinute`, `EveryTenMinutes` and `EveryHours`, so
  those stop too.

Use `getTimestamp()` (seconds, `System.currentTimeMillis() / 1000`) for real time. It fits a Lua double and stays
under 2^31 until 2038, so the Kahlua `%` trap does not bite; `getTimestampMs()` is past 2^31.

**Finding a player on the server.** `getOnlinePlayers()` returns `GameServer.getPlayers()` on a server. It is used
that way at `server/ClientCommands.lua:680` and `server/Foraging/forageServer.lua:463`. **`getPlayerFromUsername` is
not server-safe:** it calls `GameClient.instance.getPlayerFromUsername`. Loop `getOnlinePlayers()` instead.

## A2. Global mod data

```
// zombie.world.moddata.ModData (exposed to Lua)
public static ArrayList<String> getTableNames();
public static boolean exists(String);
public static KahluaTable getOrCreate(String);
public static KahluaTable get(String);
public static String create();                       // UUID.randomUUID() name, in GlobalModData.create()
public static KahluaTable create(String);
public static KahluaTable remove(String);
public static void add(String, KahluaTable);
public static void transmit(String);
public static void request(String);
```

- **`Events.OnInitGlobalModData(isNewGame)`**: `GlobalModData.init` runs `reset`, `load`, then fires it with
  `WorldDictionary.isIsNewGame()`. `IsoWorld` calls `init`. Vanilla listens at `client/Foraging/forageClient.lua:9`.
- **`Events.OnReceiveGlobalModData(tag, table)`**: fired from `GlobalModDataPacket.parse` on whichever side receives.
  `table` is `false` when the sender had none. Nothing stores the table for you; a handler must call `ModData.add`.
- **`ModData.transmit(tag)`**: from a client, sends to the server. From a server, sends to **every connection**.
- **`ModData.request(tag)`**: client only (logs "can only request from Client" otherwise). The server's
  `GlobalModData.receiveRequest` looks the name up and sends the table to that connection.
- **Access control:** `GlobalModDataRequestPacket` and `GlobalModDataPacket` both carry
  `requiredCapability=LoginOnServer`, and `receiveRequest` checks nothing more. **Any logged-in client can read any table
  whose name it knows.** There is no packet listing the server's table names: `ModData.getTableNames()` reads the local
  map, so a client sees only its own.
- A client's `ModData.transmit` cannot overwrite the server's table: `GlobalModDataPacket.parse` only fires the event.
  Vanilla Lua has no `OnReceiveGlobalModData` listener at all. A server mod that calls `ModData.add` in that event would
  let any client plant a table on the server.
- **Size:** `save` starts from a 1 MB buffer and on `BufferOverflowException` grows it by 512 kB and writes that table
  again. A large table saves, and nothing caps it. The cap is ZeD's (B2).
- **When it is saved:** `GlobalModData.save` writes `global_mod_data.tmp` in the save folder, then copies it over
  `global_mod_data.bin`. It stops at `Core.isNoSave()`. On a server it is called from `ServerMap.QueuedSaveAll` (offset
  143), reached by `/save` (`SaveCommand`), by `QueueQuit`, and by the timer in `ServerMap.preupdate` only when
  `saveWorldEveryMinutes > 0`. `SaveWorldEveryMinutes` is an integer option with default 0. A client and single player
  save it through `GameWindow.save`.
- **A server that drops ZeD keeps its world:** `load` reads every table by name and asks nothing about mods, so ZeD's
  table stays in the file, ignored.
- ZeD's only use today is `ZeD_SandboxInGame.lua:329-333`: `ModData.getOrCreate("ZeD_SandboxHistory")`, then fields set
  on the live table. That is the right pattern: tables are live and saved as they stand. It carries no version.

**A safe schema:** one table, one version number, migrations in order, a refusal to write when the data is newer than
the code. See B2.

## A3. Checking a player's powers on the server

```
public Role IsoPlayer.getRole();                       // the field; may be null
public boolean Role.hasCapability(Capability);
public static boolean Role.hasCapability(IsoMovingObject, Capability);
public boolean Role.hasAdminTool();
public boolean Role.hasAdminPower();
public String Role.getName();
public int Role.getPosition();
```

- Vanilla's own server handlers: `if not player:getRole():hasCapability(Capability.UseBrushToolManager) then`
  (`server/ClientCommands.lua:11`), and `Capability.AddItem` at `:354`.
- `getAccessLevel` still exists (`IsoPlayer.getAccessLevel()` returns the role's name or "none"), but a name proves
  nothing on a server with custom roles. ZeD does not use it. `Role` and `Capability` are exposed to Lua
  (`LuaManager$Exposer`).
- The null check matters: `IsoPlayer.getAccessLevel` itself tests the field for null.
- `IsoPlayer.getRole()` and `UdpConnection.getRole()` are two fields. `GameServer.changeRole` sets both. ZeD reads the
  player's, as vanilla's handlers do.
- A role change takes effect at once: `GameServer.changeRole` calls `IsoPlayer.setRole(Role)` and
  `UdpConnection.setRole(Role)`, so the next command is checked against the new role.
- Call the instance form, `role:hasCapability(Capability.X)`, as vanilla does. Overloads exist; do not guess another.

**Default roles** (`zombie.characters.Roles.addStatic`):

| Role | Has `AnswerTickets` | Lacks |
|---|---|---|
| banned | no | no `LoginOnServer` |
| user, priority | no | |
| observer, gm (also the default for overseer) | no | |
| moderator | **yes** | starts from every capability, then removes `UseMovablesCheat`, `SaveWorld`, `QuitWorld`, `ChangeAndReloadServerOptions`, `ReloadLuaFiles`, `BypassLuaChecksum`, `RolesWrite`, `ConnectWithDebug` |
| admin | yes | "Have all capabilities." |

`observer` and `gm` hold `CanSeeMessageForAdmin`, so they get the game's new-ticket message with the ticket's text in it,
and cannot answer.

**ZeD's rule:**

- **Staff** means `AnswerTickets`, the game's own test for a ticket window.
- **Admin** (Delete) means `RolesWrite`. The game has no capability that separates a moderator from an admin on
  tickets, and `RolesWrite` is the one moderators lack that fits "runs the server". A custom role with `RolesWrite`
  can delete.

## A4. The game's tickets

```
public static void getTickets(String);               // nil = all, name = that author's
public static void addTicket(String, String, int);   // author, message, -1 or the ticket answered
public static void removeTicket(int);
public static void viewedTicket(String, int);        // author, ticket
// zombie.network.DBTicket, exposed to Lua
String getAuthor(); String getMessage(); int getTicketID(); boolean isViewed();
DBTicket getAnswer(); boolean isAnswer();
```

All four globals are wrapped in `if (GameClient.client)`. **On a server they silently do nothing.**
`ServerWorldDatabase`, `GameServer` and `BanSystem` are not in `LuaManager$Exposer`. There is no server Lua path into the
tickets table.

The answer is one event: `Events.ViewTickets(ArrayList<DBTicket>)`, fired from `ViewTicketsPacket.parse` on the client
(listeners at `client/ISUI/UserPanel/ISTicketsUI.lua:186` and `client/ISUI/AdminPanel/ISAdminTicketsUI.lua:259`).

| Packet | Required capability | What the server does |
|---|---|---|
| `AddTicketPacket` | `LoginOnServer` | With ticket -1: sends `MessageForAdmin` ("user %s added a ticket `<LINE> <LINE>` %s") to connections with `CanSeeMessageForAdmin` or `AnswerTickets`, inserts the row, replies `sendTickets(author, connection)`. Otherwise inserts a row with `answeredID`, replies `sendTickets(null, connection)` |
| `ViewTicketsPacket` | `LoginOnServer` | `sendTickets(author, connection)`, "" meaning all |
| `ViewedTicketPacket` | `AnswerTickets` | `UPDATE tickets SET viewed = ? WHERE id = ?`, replies with all |
| `RemoveTicketPacket` | `AnswerTickets` | deletes the answer row, then the ticket, replies with all |

What this means for ZeD:

- **Any logged-in client can read every game ticket:** `getTickets(nil)` needs only `LoginOnServer`. Whatever goes into
  a game ticket's text is public to a player with a Lua console. Nearby names and notes must never go there.
- **`addTicket`'s author is whatever the client says**, and with an id, **any logged-in client can answer a ticket.**
  ZeD treats game-side authors and answers as claims.
- **One answer shows.** `ServerWorldDatabase.getAnswer` reads one row (`rs.next()` once), and `removeTicket` deletes one
  answer row. ZeD writes at most one game answer per ticket; several replies live in ZeD's record. The game's window
  offers Answer only while a ticket has none (`ISAdminTicketsUI.lua:121`).
- **`AddTicketPacket` has no rate limit.** A client can file or answer as fast as it can send. Each filing also sends
  every staff connection the message below.
- **`viewed` is the one field a plain client cannot set:** `ViewedTicketPacket` needs `AnswerTickets`. The game's window
  sets it when Answer is pressed (`ISAdminTicketsUI.lua:201-204`), so a real answer from that window is always on a viewed
  ticket.
- **Ids are never reused.** `CREATE TABLE [tickets] ([id] INTEGER PRIMARY KEY AUTOINCREMENT ...)`, in
  `Zomboid/db/<servername>.db`, beside the save and not in it. A world wipe keeps this file. An answer is a row of its own
  with `answeredID` set, and both list queries leave those rows out.
- **`ViewTickets` carries no tag and goes only to the connection that asked.** The reply to `addTicket(author, text, -1)`
  and to `getTickets(name)` holds that author's tickets only. The replies to `getTickets(nil)`, an answer, `viewedTicket`
  and `removeTicket` hold all. A handler that takes every reply as the whole list is wrong (B8).
- The vanilla windows: `ISTicketsUI.lua:52` `getTickets(username)`, `:161` `addTicket(username, text, -1)`;
  `ISAdminTicketsUI.lua:78` `getTickets(nil)`, `:203` `viewedTicket`, `:220` `removeTicket`, `:234`
  `addTicket(username, text, ticketID)`.
- `OnAdminMessage(message, x, y, z)` opens a game modal for staff (`client/ISUI/AdminPanel/ISAdminMessage.lua:142`,
  `:160`).

## A5. Logs, and can server Lua read Zomboid/Logs?

**The answer: no.** No Lua file reader reaches `Zomboid/Logs`.

`writeLog(String, String)` runs `LoggerManager.getLogger(FileName.sanitize(name)).write(text)`. `getLogger` creates the
logger on first use. `LoggerManager.getLogsDir` is `getCacheDirSub("Logs")`, so a line lands in
`Zomboid/Logs/<date>_<name>.txt` on whichever side called it; on a server, on the server. Old files move to
`logs_<date>` folders at start (`backupOldLogFiles`; QA's `zedqa_mp/Logs` shows both). So ZeD's own `writeLog` lines reach
outside tools, as the scope wants.

What each Lua reader reaches (`LuaManager$GlobalObject`):

| Function | Reaches | Guard |
|---|---|---|
| `getFileReader(String, boolean)`, `getFileInput(String)`, `getFileOutput(String)`, `getFileWriter(String, boolean, boolean)` | `Zomboid/Lua/<name>` only (`getLuaCacheDir()` + separator + name) | `hasRelativePath` refuses any `..` (`StringUtils.containsDoubleDot`). The prefix is always added, so an absolute path cannot leave |
| `getModFileReader(String, String, boolean)`, `getModFileWriter(String, String, boolean, boolean)` | the mod's version or common folder; a null mod id reads `Zomboid/mods/<path>` | refuses `..` and `File.isAbsolute()` |
| `listFilesInZomboidLuaDirectory(String)`, `listFilesInModDirectory(String, String)` | `Zomboid/Lua/...`, the mod's folders | the same |
| `getGameFilesInput(String)`, `getGameFilesTextInput(String)` | only names `ZomboidFileSystem.isKnownFile` accepts, the game's own media. The text form also needs `Core.getDebug()` | known-file list |
| `cacheFileExists(String)`, `serverFileExists(String)`, `fileExists(String)` | tell only whether a file exists | no reading |

`java.io.File` is not exposed. `BufferedReader` is, but only as what those functions return. `getSandboxFileReader` does
not exist in 42.22.

**What server Lua can do instead: catch lines as they are written.** Two official paths, no file access.

1. **The client log channel.** `ISLogSystem.sendLog` sends `sendClientCommand(character, 'ISLogSystem', 'writeLog',
   {loggerName=, logText=})` (`shared/Logs/ISLogSystem.lua:81`), and the server writes it (`:75-76`). A ZeD
   `OnClientCommand` listener sees the same command with both fields. This carries the game's own `ClientActionLog`
   lines. Their default list is `ISEnterVehicle;ISExitVehicle;ISTakeEngineParts;` (`ServerOptions.clientActionLogs`), each
   line `[steamid][type][username][x,y,z][extra]`.
2. **Wrapping the global `writeLog` on the server.** It catches any Lua caller that looks the global up at call time,
   vanilla's `:76` included. A mod that cached `local writeLog` passes by.

Both are forgeable or partial. `ISLogSystem.OnClientCommand` (`:85`) has no capability check, so any client can send a
line to any logger, `admin` included and `ZeD` too. In the Log view such lines are marked with their source, never shown
as ZeD's own evidence, and `ZeD_ServerCore.lua` closes the `ZeD` logger to that channel (B10).

**Whether Log Extender uses either path is unknown** (E1): it is not among the 300 Workshop items on this machine.
Phase 4 builds the tap, then tests it against the mod.

## A6. Vehicle griefing: what fires, and what has no event

Timed actions in `shared/` carry their result in `complete()`. `zombie.core.NetTimedAction.perform` calls `complete` on
the server, with `self.character` the server's player object. **Wrapping a `complete` on the server costs nothing unless
someone does the thing, and it knows who did it.** A live Build 42 mod replaces these same action classes in `shared`
(Another Vehicle Claim System, `AVCS2SharedOverrideVanilla.lua`, overriding `ISUninstallVehiclePart.new`,
`ISTakeEngineParts.new`, `ISSmashWindow`). That wrap is still proved by a probe first (E2).

**Window smashed**

| Route | Event or hook | Use it |
|---|---|---|
| The player's Smash Window action | `ISSmashVehicleWindow:complete` (`shared/Vehicles/TimedActions/ISSmashVehicleWindow.lua:55`, `self.window:hit(self.character)` at `:59`) | **yes**, wrap on the server; `VehicleWindow` has `getHealth`, `isDestroyed`, `getPart`, `isHittable` |
| A melee swing at the car | `PlayerHitVehiclePacket` calls `BaseVehicle.processHit(chr, weapon, damage)`, then `VehicleWindow.damage` | **no event** |
| Zombies, crashes | `AttackVehicleState`, `VehicleCollidePacket` | **no event**, and not griefing |
| `OnWeaponHitThumpable` | fired by `IsoBarricade`, `IsoCompost`, `IsoDoor`, `IsoThumpable`, `IsoWindow` | not vehicles |
| `OnVehicleDamageTexture` | `VehiclePart.setCondition`, only with a driver, passes only the driver | no: a parked car has none |
| `vehicle.damageWindow` client command | `server/Vehicles/VehicleCommands.lua:100`; nothing in `client` or `shared` sends it | dead |

**Part removed**

| Route | Hook | Use it |
|---|---|---|
| Uninstall a part | `ISUninstallVehiclePart:complete` (`shared/Vehicles/TimedActions/ISUninstallVehiclePart.lua:40`, `self.part:setInventoryItem(nil)` at `:64`) | **yes**; capture `self.part:getInventoryItem()` before, compare after, since the roll can fail |
| Take engine parts | `ISTakeEngineParts:complete` (`:31`) | **yes** |
| Siphon gas | `ISTakeGasolineFromVehicle:complete` (`:110`) | yes |
| Strip a burnt wreck | `ISRemoveBurntVehicle:complete` (`:60`) | yes |
| `OnMechanicActionDone` | `IsoGameCharacter.loadChange`, client side, gives only `(chr, success)` | no |
| `vehicle.uninstallPart` client command | named in the default `ClientCommandFilter`, but `VehicleCommands.lua` has no such command in 42.22 | **stale**: do not listen for it |

**Driven off by someone who is not its last driver**

The game keeps no owner or last driver. `BaseVehicle` has `getDriver()`, `isDriver(chr)`, `getSqlId()`,
`isEngineRunning()`, `isHotwired()`; nothing older. ZeD keeps its own `lastDriver[sqlId]`.

| Route | Event or hook | Use it |
|---|---|---|
| `OnEnterVehicle` | `BaseVehicle.enterRSync` fires only with `GameClient.client` and a local player; `client/Vehicles/TimedActions/ISEnterVehicle.lua:79` fires it in a client file. `IsoCell.putInVehicle` also fires it, after seating a character directly, and is not the way a player climbs in | **client only** for a player getting in |
| `OnUseVehicle` | `IsoPlayer.enterExitVehicle`, from the player's own update, declared at `server/Vehicles/Vehicles.lua:1537` | no: it is the use key, before anything has happened |
| `OnExitVehicle`, `OnSwitchVehicleSeat` | `client/Vehicles/TimedActions/ISExitVehicle.lua:62`, `ISSwitchVehicleSeat.lua:57`; declared at `client/Vehicles/ISUI/ISVehicleDashboard.lua:715-716` | **client only** |
| `VehicleEnterPacket` | no Lua event on the server | **no event** |
| Start the engine | `ISStartVehicleEngine:complete` (`:26`), which already tests `vehicle:isDriver(self.character)`; the `vehicle.startEngine` client command at `VehicleCommands.lua:10` is the older route, nothing in vanilla sends it | **yes**, the main hook |
| Hotwire | `ISHotwireVehicle:complete` (`:32`) | **yes** |
| Tow | `vehicle.attachTrailer` command (`VehicleCommands.lua:330`) through `OnClientCommand` | yes, one listener |
| `ClientActionLog` line | A5 path 1: `[ISEnterVehicle][user][x,y,z][script name]`. No vehicle id, no seat, sent by the client | a lead only |
| Engine already running when they climbed in | no hook | a poll, below |

**The rule for Phase 4:**

- On engine start or hotwire by player P: `last = lastDriver[sqlId]`. If `last` exists and is not P, write a
  "driven off" line. Then set `lastDriver[sqlId] = P`.
- A light poll covers the running engine: every 10 real seconds from `OnTickEvenPaused`, for each player in
  `getOnlinePlayers()`, `getVehicle()` then `isDriver`. The cost is one pass over the players, no scan of vehicles.
- The map is capped, oldest out.

`server/Vehicles/VehicleCommands.lua:11-13` shows both calls working on the server.

## A7. Temp bans and showing a reason

**The API is on the client:**

```
public static void banUnbanUserAction(String, String, String);   // action, target, reason
```

- `action` is a `BanUnbanUserActionPacket.Command`: `Kick`, `Ban`, `UnBan`, `BanIP`, `UnBanIP`, `UnBanIPOnly`,
  `BanSteamID`, `UnBanSteamID`. The packet needs `BanUnbanUser`. Vanilla: `client/ISUI/AdminPanel/ISUsersList.lua:376-378`.
- The slash commands: `/banuser "x" -r "reason"`, `/kickuser "x" -r "reason"`, `/unbanuser "x"`, sent with
  `SendCommandToServer`, which calls `GameClient.SendCommandToServer`.
- `banUnbanUserAction` sends through the client connection, with no server branch.
- `BanSystem` (`BanUser`, `KickUser`) and `GameServer.kick` are not in `LuaManager$Exposer`. Their callers are Java:
  the server commands, `BanUnbanUserActionPacket` and `AntiCheat` among them.
- The game has no ban length: `ServerWorldDatabase.banUser(String, boolean)` is on or off.

**So a server timer alone cannot lift a ban or remove a player.** What it can use:

| Tool | Runs with nobody on | What it can do |
|---|---|---|
| `OnTickEvenPaused` with `getTimestamp()` | yes | notice the time |
| `sendServerCommand(staffPlayer, ...)` | needs a staff member online | ask their client to run `banUnbanUserAction("UnBan", user, "")` |
| `sendServerCommand(bannedPlayer, ...)` | that player online | tell their client to show the reason and run `forceDisconnect()` (a global, client side, `connection.forceDisconnect("lua-force-disconnect")`) |

The two ways to build it are in E7. They need the director's decision before Phase 2.

**How a reason reaches the player:**

- **Kick.** `/kickuser "x" -r "reason"` runs `GameServer.kick(connection, "UI_Policy_KickReason", reason)`. `KickedPacket`
  carries description and reason; `getMessage` joins the translated text and the reason; `processClient` shows it in
  chat, fires `OnConnectFailed(message)` and disconnects. A client on the connect screen shows it
  (`client/OptionScreens/ConnectToServer.lua:309`). In game, `ServerDisconnectState` opens
  `ISServerDisconnectUI_OnServerDisconnectUI(reason)` (`client/ISUI/ISServerDisconnectUI.lua:69`). Keys in
  `shared/Translate/EN/UI.json`: `UI_Policy_Kick` (`:1111`), `UI_Policy_KickReason` (`:1112`).
- **Ban.** `BanSystem.BanUser` sets the account's ban, then `KickUser(username, "You were banned", "command-banid")`, a
  fixed text: **the reason is not shown at that moment.** The reason is stored only by `banSteamID(steamid, reason, ...)`
  in Steam mode, or by `banIp` in `bannedip`.
- **Trying to return.** `ServerWorldDatabase.authClient` reads `SELECT reason FROM bannedip WHERE ip = ?` and
  `SELECT * FROM bannedid WHERE steamid = ?` into `LogonResult.bannedReason`. `LoginPacket` sends it, shown as
  `UI_OnConnectFailed_BannedReason`: "You are banned from this server. Reason: %1" (`UI.json:1091`). A plain username ban
  with no Steam ID stores no reason. QA's `-nosteam` server is that case.
- **The appeal line** (Phase 5): a banned player cannot log in to ask for it, so the client keeps it from its last
  session on that server.

---

# Part B: Phase 1, tickets

## B1. The shape

ZeD's record lives on the server and is the truth. The game's ticket still exists beside it for admins on the game's
window, and is filed by clients because only clients can. Each player receives only what they may see, by
`sendServerCommand` to that player. The table is never transmitted.

```
Player client                       Server (ZeD)                         Staff client
  t_new {kind, here, text}   --->   stamps who, where, when, nearby
                             <---   t_ack {id, file}             --->    t_row to each staff member
  addTicket(me, file, -1)    --->   (the game inserts its ticket; ViewTickets back to the player)
  t_filed {id}               --->   gameFiled = true
                                                                         on opening the queue: getTickets(nil)
                                    links or adopts each new row <---    t_sync {rows, top, done}, in batches
                                    t_syncd {links}              --->    compares links with its list
                                    marks rows gone, keeps answers <---  t_gamediff {gone, ans}
```

## B2. The table

**Name.** A secret, made once:

- Name form: `ZeD_TK_` + `getRandomUUID()` (`zombie.modding.ModUtilsJava.getRandomUUID`, `UUID.randomUUID().toString()`).
- At `OnInitGlobalModData`, the server scans `ModData.getTableNames()` for that prefix. If found it is the table. If not,
  it makes one.
- The name is never sent, printed or logged. `ModData.getTableNames()` on a client lists only that client's tables.
- A second table with the prefix (restored backups, say): the one with the most tickets wins, and a line goes to the log.
  They are not merged; the other stays in the file. A planted table (A2, a third-party mod) could win this way at a
  restart. ZeD has no second store to check against, so the line in the log is the defense.
- This is a capability by name, and it holds only while nothing prints it. Backups and anyone given the save folder hold
  `global_mod_data.bin`, with the name and every note in it.

**Schema, version 1:**

```lua
{
    schema = 1,
    nextId = 15,                     -- never reused while the table lives
    gameMax = 212,                   -- the highest game ticket id dealt with (B8)
    skipped = 0,                     -- game tickets left in the game's window by the caps
    chars = 4210,                    -- characters of text held, kept on every add and eviction
    tickets = {                      -- keyed by id (a number); pairs only, since Delete leaves holes
        [14] = {
            id       = 14,
            source   = "zed",        -- "zed", or "game" for a ticket adopted from the game's window
            kind     = "GRIEF",      -- BUG GRIEF STUCK QUESTION APPEAL OTHER NONE
            author   = "Kade_R",     -- player:getUsername() on the server; for "game", the game's claim
            status   = "Open",       -- Open Seen Progress Answered Closed Spam
            day      = 12,           -- in-game day; nil for "game"
            filed    = 1793913240,   -- getTimestamp() seconds; nil for "game"
            updated  = 1793913240,   -- every change; sort and eviction
            place    = { x = 6280, y = 5350, z = 0, name = "Riverside farm" },   -- nil unless Include where I am
            near     = { n = 2, "Rosa", "Mags_77" },                             -- nil unless place
            assignee = nil,          -- username
            spamBy   = nil,          -- username
            gameId   = 212,          -- the game's ticket id; nil until a staff client links it
            gameFiled = true,        -- its game ticket exists or existed; nil tells the player's client to file it
            gameAns  = true,         -- ZeD's one game answer is filed
            gameGone = nil,          -- true once the game's row was removed on the game's window
            unread   = true,         -- an answer the author has not been told of
            thread   = { n = 2,
                { who = "Kade_R", t = 1793913240, text = "..." },
                { who = "Hermit", t = 1793914000, text = "...", staff = true },
                -- a line from the game's side carries game = true, staff stays nil
            },
            notes    = { n = 1, { who = "Hermit", t = 1793914100, text = "..." } },
        },
    },
}
```

Lists carry their own count `n`, which is cheap and safe against holes.

**Opening it:**

```lua
local SCHEMA = 1
local MIGRATE = {}                   -- MIGRATE[1] = function(md) ... end   moves 1 to 2

local function open()
    if T.md then return T.md end
    local name = findName() or (PREFIX .. getRandomUUID())
    local md = ModData.getOrCreate(name)
    md.schema = md.schema or SCHEMA
    md.nextId = md.nextId or 1
    md.gameMax = md.gameMax or 0
    md.skipped = md.skipped or 0
    md.chars = md.chars or 0
    md.tickets = md.tickets or {}
    if md.schema > SCHEMA then
        T.frozen = true              -- data from a newer ZeD: read it, never change it
    end
    while md.schema < SCHEMA do
        local step = MIGRATE[md.schema]
        if not step or not pcall(step, md) then
            T.frozen = true          -- a missing or failed step: stop here, write nothing
            break
        end
        md.schema = md.schema + 1
    end
    T.md = md
    return md
end
```

`OnInitGlobalModData` calls `open`, and so does every handler. `/reloadlua` (`ReloadLuaCommand`) runs one file again with
`LuaManager.RunLua`, which leaves `T` empty and does not fire the event. `T.frozen` answers every write with
`err = "frozen"`, and the hello reply says so (B9). Migrations only add or reshape, never drop a field they do not
understand.

**Caps.** The caps evict oldest first:

- Open means Open, Seen and Progress, the mockup's `isOpen`. Open tickets are never evicted.
- History (Answered, Closed and Spam): 500 records; at the cap the oldest `updated` goes. Answered is history, as the
  scope says, or nothing would bound it: an Answered ticket is neither open nor Closed.
- A player has at most 5 open tickets (B6). All players together have at most 300: `Open=true` is the game's default,
  accounts cost nothing, and the per-player limits do not stop ten accounts. Past it `t_new` answers `err = "full"` and
  a line goes to the log.
- Records adopted from the game (B8) hold at most 100 open, and 3 open per claimed author. Those fill from `addTicket`,
  which has no limit.
- A thread holds at most 40 messages, notes 20, each text at most 1000 characters.
- All the text in the table at most 4,000,000 characters (`md.chars`); past it history goes early, oldest first. At the
  record caps alone the worst case is 800 records of 60 kB, written out at every save.

Eviction touches only ZeD's record. The game's row stays in the game's window, and `gameMax` stops it coming back (B8).

At those caps the largest card is 60 messages of 1000 characters, 180 kB even if every character took 3 bytes, inside
the 200 kB rule with no paging. Each string stays far under the 32767-byte limit.

## B3. Where the facts are stamped

All on the server, in the `t_new` handler. The client sends only `kind`, `here` and `text`.

```lua
local function nearby(p, x, y, r)
    local out, me, list = { n = 0 }, p:getUsername(), getOnlinePlayers()
    for i = 0, list:size() - 1 do
        local o = list:get(i)
        local u = o:getUsername()
        if u ~= me then
            local dx, dy = o:getX() - x, o:getY() - y
            if dx * dx + dy * dy <= r * r and out.n < 20 then
                out.n = out.n + 1
                out[out.n] = u
            end
        end
    end
    return out
end

local function stamp(p, rec, wantPlace)
    rec.author = p:getUsername()
    rec.filed  = getTimestamp()
    rec.day    = math.floor(getGameTime():getWorldAgeHours() / 24) + 1
    if wantPlace then
        local x, y, z = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
        rec.place = { x = x, y = y, z = z, name = placeName(x, y, z) }
        rec.near  = nearby(p, x, y, ZeD.Tk.NEAR)
    end
end
```

`nearby` and `placeName` are declared above `stamp`: Kahlua binds a free name when the closure is made, so the other order
reads a nil global at the first ticket with a place.

`NEAR` is 30 (settled, in tiles, on any floor; griefing happens up and down stairs). Invisible staff are counted, so the
list stays honest for the staff who read it; the player never sees the list.

The Ask card's line ("Riverside, 6347 x 5372, and nobody else within 30 tiles") is the client's preview from what it can
see. It shows the place and a plain "and who is nearby", never a name or count from the server, so it cannot reveal an
invisible admin. The mockup's "nobody else" wording changes to that.

`placeName` is E3: until a town source is proved, `name` is nil and the UI shows "6347 x 5372".

## B4. Statuses

| Stored | Staff see | The player sees |
|---|---|---|
| Open | Open | Sent |
| Seen | Open | Seen |
| Progress | In progress | In progress |
| Answered | Answered | Answered |
| Closed | Closed | Closed |
| Spam | Spam | Closed |

The mapping is done **on the server**, in the player view. The word "Spam" never reaches a player's client.

| Action | Allowed from | Goes to | Also |
|---|---|---|---|
| File | | Open | `nextId` |
| Staff open the card | Open | Seen | others unchanged |
| Take it | Open, Seen, Progress | Progress | `assignee` = me |
| Answer | Open, Seen, Progress | Answered | thread, `assignee` kept or me, belt note, first answer filed to the game |
| Player adds to it | Open, Seen, Progress | unchanged | thread |
| Close | Open, Seen, Progress | Closed | |
| Reopen | Answered, Closed | Progress | |
| Spam | anything but Spam | Spam | `spamBy` = me |
| Not spam | Spam | Open | `spamBy` cleared |
| Delete | anything | gone | admins only; game ticket removed by the staff client |
| Add note | anything | unchanged | notes |

This is the mockup's rule: `isOpen` gates the player's reply and the staff's Answer and Close, and an Answered ticket
offers only Reopen. So a second staff reply is Reopen, then Answer, and a player cannot follow up on an answer until
staff reopen it. Whether that is what the director wants is E12. Spam also clears `unread`.

## B5. What each person receives

Two functions build every outgoing table from an allowlist of fields. Nothing else may send ticket data.

**`playerView(rec)`:** `id`, `kind`, `st` (mapped), `day`, `filed`, `place` (their own, as they included it), `thread`
(each `who`, `staff`, `game`, `t`, `text`), `can` (may they add to it). **Never** `notes`, `near`, `assignee`, `spamBy`,
`gameId`, `gameGone`, `gameAns`, `source`.

**`staffView(rec)`:** everything in the record.

Rows are the short forms:

- `playerRow(rec)`: `id`, `kind`, `st`, `day`, `last` (last message, 120 characters), `replies`, and `file` (the text for
  `addTicket`) while the ticket is open and `gameFiled` is nil.
- `staffRow(rec)`: `id`, `kind`, `author`, `st`, `day`, `filed`, `where` (the place name, else "6347 x 5372", else nil),
  `assignee`, `first` (first message, 120 characters), `replies`, `src`.

The server refuses to send `t_card` unless `can(p, CAP_STAFF)`, and refuses `t_one` unless
`rec.author == p:getUsername()`. A ticket of someone else's answers `gone`, the same as one that does not exist.

**What this does not protect.** The allowlists cover ZeD's record. The ticket's first message and author, and the first
staff answer, also sit in the game's table, where any logged-in client can read them with `getTickets(nil)` (A4). So a
plain player with a Lua console can read other players' first messages, with or without ZeD. Notes, the rest of the
thread, `near`, `place`, assignee and status never go there. See E13.

## B6. The messages

Module `ZeD` for the link, module `ZeDT` for tickets. On the server, one `OnClientCommand` listener tests the module,
applies the rate limit, then calls the handler inside `pcall` (a Lua logic error costs one command, never the server's
event chain). A failed handler answers `t_ack {ok = false, err = "fail"}` and writes a line. Every handler takes the
player from the event, **never a name from `args`**, and validates `args` by type first. `ZeD.Srv` is a global and the
listener is added only while `ZeD.Srv.listening` is nil, since `/reloadlua` of that file would add a second listener and
run every command twice.

`rid` is an optional request number the client picks and the server echoes in `t_ack`.

**Client to server**

| Command | Args | Who | Check | Limit | Reply |
|---|---|---|---|---|---|
| `ZeD.hello` | `v` | anyone | | 1 per 5 s | `ZeD.hello` |
| `t_new` | `kind`, `here`, `text`, `rid` | anyone | kind in the six; text 1 to 1000 after trim | 1 per 60 s; at most 5 open of `source = "zed"`; at most 300 open in all | `t_ack {id, file}`; `t_row` to staff |
| `t_filed` | `id` | anyone | author | general | none; sets `gameFiled` |
| `t_mine` | | anyone | | 1 per 5 s | `t_mine`, the newest 50 |
| `t_one` | `id` | anyone | author | general | `t_one` |
| `t_reply` | `id`, `text`, `rid` | anyone | author; status open | 1 per 10 s; thread cap | `t_one`; `t_row` to staff |
| `t_read` | `id` | anyone | author | general | clears `unread` |
| `t_queue` | `status`, `kind`, `who`, `mine`, `find`, `newest`, `page` | staff | `AnswerTickets` | 1 per 1 s | `t_queue` |
| `t_card` | `id` | staff | `AnswerTickets` | general | `t_card`; Open becomes Seen, `t_row` to author and staff |
| `t_take` | `id`, `rid` | staff | `AnswerTickets`; status | general | `t_card`; `t_row` to staff and author |
| `t_answer` | `id`, `text`, `rid` | staff | `AnswerTickets`; status; text | general | `t_ack {first, gameId}`; `t_card`; `t_note` and `t_one` to author |
| `t_addnote` | `id`, `text`, `rid` | staff | `AnswerTickets`; text; note cap | general | `t_card` to all staff with it open |
| `t_close` | `id`, `rid` | staff | `AnswerTickets`; status | general | `t_card`; `t_row` both ways |
| `t_reopen` | `id`, `rid` | staff | `AnswerTickets`; status | general | as Close |
| `t_spam` | `id`, `rid` | staff | `AnswerTickets`; not Spam | general | `t_ack`; `t_row` to staff; to the author it reads Closed |
| `t_unspam` | `id`, `rid` | staff | `AnswerTickets`; Spam | general | `t_card`; `t_row` both ways |
| `t_delete` | `id`, `rid` | **admin** | `RolesWrite` | general | `t_ack {gameId}`; `t_gone {id}` to staff and author |
| `t_sync` | `rows` (at most 20), `top`, `done`, `reset` | staff | `AnswerTickets` | 1 per 1 s | one `t_row` count to staff; `t_syncd` on `done` |
| `t_gamediff` | `gone`, `ans` (at most 50 each) | staff | `AnswerTickets` | 1 per 1 s | `t_row` to staff |

**General limit:** 10 commands in any 5 seconds, per username, counted before anything else runs. Past that, commands are
dropped with no reply and a counter ticks; a line goes to the `ZeD` log once per minute for a player over it. All limits
live in memory, in a table keyed by username, using `getTimestampMs()` for short gaps as `forageServer` does, and they are
in one `LIMITS` table in `ZeD_TicketProto.lua` so they can become server settings later. A restart clears them, and costs
a spammer one free ticket per account.

A command's own limit answers `t_ack {ok = false, err = "wait", left = seconds}`, so a card never waits on silence; only
the general limit is silent. `t_new` also answers `err = "many"` or `err = "full"`. The 60 seconds start at an accepted
ticket. The Ask card shows the answer in the help band and keeps the typed text; no reply in 10 seconds reads as `fail`,
and the text stays.

**Arguments.** `id`, `page` and `rid` are whole positive numbers (`rid` that is not is left out of the reply, so a client
cannot have a long string echoed). `kind` and `status` are in their sets. `who` and `find` are strings of at most 64
characters, and `find` is used as `string.find(s, find, 1, true)`, so a client's text is never a pattern. `text` is a
string, cleaned by `ZeD.Tk.clean` (trim, control characters out but for line breaks), measured with `#`, which counts Java
characters in Kahlua. In `t_sync` and `t_gamediff`, every string is cut to 1100 characters on the client and to 1000 when
stored, because a game ticket can be up to 32767 bytes.

**Server to client**

| Command | Args | To |
|---|---|---|
| `ZeD.hello` | `v`, `staff`, `admin`, `frozen`, `unread` (ids, at most 5); to staff only, `open`, `spam` | the asker |
| `t_ack` | `rid`, `ok`, `err`, and per command `id`, `file`, `first`, `gameId`, `left` | the asker |
| `t_mine` | `n`, rows of `playerRow` | the asker |
| `t_one` | `playerView` | the author |
| `t_row` | `id`, and `staffRow` or `playerRow`, with `open`, `spam` to staff | staff; the author |
| `t_queue` | `page`, `pages`, `n`, rows of `staffRow`, `open`, `spam`, `gameMax`, `skipped`, `authors` (page 1, at most 100) | the asker |
| `t_syncd` | `links`: game id to true if the record holds a game answer, else false | the asker |
| `t_card` | `staffView` | the asker; staff who have it open |
| `t_note` | `id`, `who` | the author, on an answer |
| `t_gone` | `id` | staff, the author |

**Staff pushes:** a helper loops `getOnlinePlayers()`, keeps those passing `can(p, CAP_STAFF)` and sends one row.
This runs only when a ticket changes. "Staff who have it open" is `T.cards[username] = id`, set by `t_card` and cleared by
`t_queue`. It is one entry per person and only staff can set one. A card is pushed through the same helper, so `can` is
tested again at every push and a demoted client gets no more notes. Nothing cleans an entry when a player leaves, since
no server event fires then (`OnDisconnect` is client side), and none is needed: the push reaches only who is online.

**Errors:** `perm`, `wait`, `many`, `full`, `gone`, `state`, `text`, `frozen`, `fail`. Each has a UI key. A client that
lacks a power never shows the button, but the server decides regardless. A plain player sending `t_queue`, `t_card` or
`t_delete` gets `t_ack {ok = false, err = "perm"}` and a line in the `ZeD` log, at most one a minute per player, or the
denial itself fills the disk. On `perm` the client sends `ZeD.hello` again, so a role changed mid-session updates its
buttons.

**Authorization, the whole of it:**

```lua
local CAP_STAFF = Capability and Capability.AnswerTickets
local CAP_ADMIN = Capability and Capability.RolesWrite

local function can(p, cap)
    local role = p and p:getRole()
    return role ~= nil and role:hasCapability(cap) == true
end
```

Both are in the 42.22 enum. If a game update renames one, the local is nil, and `hasCapability(nil)` would match no
overload inside a `pcall`, which corrupts the game's call pool. So at load, if either is nil, the server part logs it and
stays off: no hello reply, and clients use the fallback.

## B7. The Belt note

- Player online when an admin answers: `t_note {id, who}`.
- Client: `ZeD.Messages.add(sourceName, "mods", { k = "ticket", id = id, text = ..., read = false })`, then a toast.
  `toast` is local in `ZeD_Messages.lua`, so a small public `M.ticket(id, who)` goes there; it adds the item, toasts and
  bumps, and the belt's count follows on its own. An id already in the list makes no second item. `ZeD_MessagesWindow.lua` draws the `ticket` kind with an **Open**
  keycap that opens the ticket card in the Server tab and sends `t_read`.
- Player offline, or online and gone before pressing Open: `rec.unread` stays true until `t_read`. `ZeD.hello` lists up to
  5 such ids; the client makes one note each.
- Only an answer makes a note. Status changes appear in the list.

**For staff:** the game's own modal for a new ticket (A4, `OnAdminMessage`) would cover the screen on each ticket, which
breaks the house rule on interruptions. A client file requires `ISUI/AdminPanel/ISAdminMessage`, then
`Events.OnAdminMessage.Remove(ISAdminMessage.AddAdminMessage)` and adds a wrapper. With `ZeD.ServerPart.staff` true, a
message that starts `user ` and contains ` added a ticket` goes to Messages as a note ("A new ticket"), at most one in 10
seconds, because `addTicket` has no limit and a flood would otherwise fill the belt. Any other message passes to the
original, and so does this one on a client without `AnswerTickets`: `observer` and `gm` receive it (A3) and have no queue
to open. Vanilla removes event handlers the same way (`client/DebugUIs/ISFastTeleportMove.lua:24`).

## B8. The game's ticket, and keeping the two in step

**The tag** is the link, since server Lua cannot get a game ticket's id:

```
"[GRIEF #14] Someone pulled the engine out of my pickup ..."     with the server part
"[GRIEF] Someone pulled ... (6280 x 5350)"                       without it (B9)
```

The scope's `[GRIEF]` form gains the ZeD number. It stays at the front, so admins on the game's window read the kind
first. Parsing: `^%[(%u+) #(%d+)%] (.*)$`, then `^%[(%u+)%] (.*)$`. Both functions live in `ZeD_TicketProto.lua`.

**Filing.** `t_ack` carries `file`, the exact text the server built. The player's client calls `addTicket(me, file, -1)`,
so the game's copy matches the record whatever the server trimmed. The game replies with `ViewTickets`; when the tag
shows in that list the client sends `t_filed {id}`, which sets `gameFiled`. If the client left before filing, the next
`t_mine` row still carries `file`, and the client files it once. The record decides this, never the absence of a game row:
a ticket an admin removed on the game's window must not come back at its author's next login.

**Matching is the server's job.** Only the server holds every record. A staff client has a page of rows with 120-character
previews, which cannot test "same first message", and one client-side `t_adopt` per ticket would run into the general limit
on the first day of a server with 200 old tickets.

**Reading the game's list (staff client).** On opening the queue and on Refresh, the client calls `getTickets(nil)`. Only
the reply to that call is a full list (A4), so the client keeps one ticket request in flight and does not ask while its
own `addTicket(me, file, -1)` is unconfirmed. From a full list:

1. Rows above `gameMax`, oldest first, go in `t_sync` batches of 20, one batch a second, each row
   `{g, a, m, v, aw, at}`: game id, author, message, viewed, the answer's author and text. `top` is the highest id in the
   list. The last batch carries `done = true`; with nothing new, one empty batch carries it. If the queue closes the batches
   stop, and the next open starts from `gameMax`.
2. The server answers `t_syncd {links}`.
3. The client compares `links` with the list and sends what differs in `t_gamediff`.

**What the server does with a row.** A row at or below `gameMax` is ignored. Otherwise:

| The row | Result |
|---|---|
| Its id is on a record already (`T.byGame`, built in `open`) | nothing |
| A tag with an id, whose record is `source = "zed"`, has no `gameId`, has the same author, and whose message is exactly the tag plus the record's first message | link: `gameId`, `gameFiled` |
| Anything else, a forged tag included | adopt, under the caps in B2 |

Adopting makes a record with `source = "game"`, the kind from the tag or `NONE`, no day, time or place, and the author as
claimed. Status is Seen if viewed, Answered if viewed and answered, otherwise Open: `viewed` is the one field a plain client
cannot set (A4), so a griefer cannot answer a ticket out of the Open queue. An answer on a viewed ticket goes in the thread
with `game = true` and `staff` nil. An answer on an unviewed ticket goes in `notes`, for staff only. The card says the
author and any answer are as the game's ticket claims them; the mockup's #8 is this case: "Not recorded (filed from the
game's own window)". A row over a cap is left in the game's window and `skipped` ticks; the queue's help band says "N more
in the game's window".

After each row `gameMax` rises to its id. Ids are never reused (A4), so this one number stops an evicted, deleted or skipped
row from coming back, with no list of tombstones to keep. Two staff syncing at once do no harm.

A record adopted under a claimed author shows in that player's `t_mine`, so a forger can put a ticket in a victim's list.
It reads as filed through the game's window, and it reveals nothing: the forger wrote it, and the forger cannot read the
victim's own records. Adopted records do not count toward the 5 open, or forged tickets could stop a player filing.

**When the game's side changed.** The client looks only at ids at or below the list's highest, since a link made after its
list was fetched is not missing.

| Seen | Sent | The server |
|---|---|---|
| A linked id absent from two full lists at least 10 seconds apart | `gone` | clears `gameId`, sets `gameGone`, keeps `gameFiled` and the record, writes a line |
| A linked id with an answer, `links` says none | `ans {g, who, text, viewed}` | as for adopting: thread with `game = true` if viewed, else notes. Sets `gameAns`. No status change, no belt note |

Two lists, because a reply the client took for a full list by mistake must not cost a link. The second `getTickets(nil)`
runs only when something looks gone.

**A ticket removed on the game's window.** Only the game's row goes. The record stays with its status and its thread, the
staff card reads "Removed from the game's window", the player's view does not change, and nothing files it again. Later
answers stay in ZeD, since `first` needs a `gameId`. This is deliberate: a moderator holds `AnswerTickets` and not
`RolesWrite`, so if the game's Remove reached ZeD's record it would be Delete without the admin's power. An admin who wants
it gone uses Delete. Viewing a ticket on the game's window does not move it to Seen; nothing reports that.

**A replaced database.** If two full lists have a `top` below `gameMax`, the game's table is newer than ZeD's memory of it.
The next `t_sync` says so with `reset = true`: the server clears every `gameId` and sets `gameMax` to 0, and the rows are
matched afresh by tag. `gameFiled` stays, so nothing is filed twice.

**Before any game call** the staff client finds the row with that id in its latest full list and tests author and text
(`ZeD.Tk.sameTicket`). `rec.gameId` is right unless the database was replaced, and this stops a `removeTicket` from hitting
another ticket then. No row, or a row that differs: no call.

**Acting on the game's ticket (the staff client, after the server's ack):**

| ZeD action | Game call | Why |
|---|---|---|
| Open the card, ticket not viewed | `viewedTicket(me, gameId)` | the game's window shows it viewed |
| Answer, `first` true | `addTicket(me, text, gameId)` | one game answer only (A4). `first` is `gameId` set and `gameAns` nil; the server sets `gameAns` with it |
| Delete | `removeTicket(gameId)` | gone from both |
| Close, Spam, Not spam, Reopen, Take, Add note | none | the game has no such states |

**Polling.** `AdminTab.lua`'s 10-second `askTickets` stops when the server part is present. `getTickets(nil)` runs when
the queue opens and on the Refresh keycap; every later change arrives as `t_row`.

## B9. Without the server part

**Detection:**

- `ZeD_ServerLink.lua` sends `ZeD.hello {v = 1}` once the local player exists (`isClient()` only).
- No reply: again at 10 s and 30 s, then `ZeD.ServerPart.present = false`. A late reply still flips it true.
- While `present` is nil, Send waits with a line in the help band, so a ticket filed in the first seconds does not take
  the wrong path. The text stays.
- `hello` is sent at every `OnCreatePlayer`, a respawn included, and `send` reads `getPlayer()` at each call: the object from
  before a death is not the one to hand `sendClientCommand`.
- `frozen` in the reply means the server part is up and refuses writes. The client reads through it and sends with the
  fallback's `addTicket`, which a later version will adopt.
- The reply gives `v`. `ZeD.ServerPart.v` lets later phases test `v >= n`. The client ignores commands it does not know
  and so does the server, so a newer side and an older side degrade by feature.

**When this happens.** `DoLuaChecksum` defaults to true and the checksum covers `shared`, `client` and `server`, so on
most servers a client and server with different ZeD files cannot join at all. The fallback is for a server with the
checksum off running an older ZeD, or a server part that failed to load. It stays small.

**The fallback:**

| | With the server part | Without |
|---|---|---|
| Send | `t_new`, then `addTicket` | `addTicket(me, "[GRIEF] text (6347 x 5372)", -1)`, the place from the client, day and time left out |
| My tickets | `t_mine` | `getTickets(me)`; kind from the tag; `isViewed` gives Seen, `getAnswer` gives Answered, otherwise Sent |
| Reply | field | none: the game has no thread. A line says "This server keeps one question and one answer." |
| Queue | server pages | `getTickets(nil)`, filtered on the client; status, kind, player, find |
| Answer | many | one (`addTicket(me, text, id)`); then the field closes |
| Take, notes, Spam, Close | yes | hidden, with one line in the help band saying why |
| Delete | admins (`RolesWrite`) | `removeTicket(id)`, as the game allows (`AnswerTickets`) |
| Belt note | yes | none: nothing tells the client |

The place in the text is readable by any client (A4). It is what the player chose to send to the game's window, and the
scope asks for it. Nearby names are left out.

## B10. Failure and restart

- **Crash between saves.** The tickets since the last world save are lost, with the world's progress. The game's ticket
  table is SQLite and keeps them. `gameMax` rolls back with the table, so the next staff client's sync sees those rows as
  new and adopts them: text and kind survive; time and place do not. `nextId` can roll back, and the first-message test in
  B8 keeps a reused number from linking to the wrong ticket. Every other change since the save is undone in ZeD with no
  sign: a Close, a Spam, a note, and a Delete, whose record returns while its game row stays gone, and then reads as
  removed on the game's window.
- **`mp_server.ps1 -Stop` and any other kill** skip the shutdown hook. `GameServer$1` runs `ServerMap.QueuedQuit` on a normal
  JVM exit, so a console `quit`, Ctrl+C and `/quit` all save.
- **A plain restart.** `T.md` opens the same table by its prefix. Limits and `T.cards` are memory, so they start empty.
  Every client was dropped and sends `hello` when it returns. A reply lost in a drop is recovered from `t_mine` and the
  queue, and a card open at the drop is gone with the client's state.
- **A world wiped with the database kept** (owners do this): a new table, `gameMax` 0, and every old game ticket is adopted
  once under the caps, as `source = "game"` records from the last world. Staff close them; the caps hold.
- **Default save setting.** On `SaveWorldEveryMinutes=0` a server up for three weeks holds three weeks of tickets in memory.
  Server Lua cannot call `GlobalModData.save`. The Tickets queue's help band says so to staff when the option is 0
  (`getServerOptions()`, already used in `ISLogSystem.lua:44`).
- **QA note:** `mp_server.ps1 -Stop` is `Stop-Process -Force`. It never saves. A persistence test must send `/save` first
  (or `/quit`).
- A journal file in `Zomboid/Lua` would close the gap, at the cost of a second store. It is not in Phase 1.
- **`writeLog("ZeD", ...)`** on each ticket event: id, kind, who, what, place. Never the text or a note. This is the
  start of Phase 4's log, and it survives any crash. Any client can write to any logger (A5), so `ZeD_ServerCore.lua` wraps
  the function the channel calls. `ISLogSystem.OnClientCommand` looks it up at each call, so the wrap takes effect:

```lua
local base = ISLogSystem.writeLog
ISLogSystem.writeLog = function(who, packet)
    local name = packet and packet.loggerName
    if type(name) == "string" then
        local plain = string.gsub(string.lower(name), "[^%a]", "")
        if string.find(plain, "zed", 1, true) then return end
    end
    return base(who, packet)
end
```

## B11. The client, screens as drawn

`mockups/zed_tickets_v2.html` is the layout. The screens are a two-deep stack with a back-bar: the tab underneath, the
card pushed on top. The Server tab today is one scrolling list of items (`ServerTab.lua`), and `AdminTab.lua` the same,
so the card is a second render path behind one `st.card` state, not a change to the list.

| Surface | Where | Notes |
|---|---|---|
| Tickets block | `ServerTab.lua`, `build`: replaces the button at `:263-264` | "N open", the Ask the admins button, my tickets as rows |
| Ask the admins card | new | kind chips, Include where I am (ticked by Griefing and Stuck), the message field in the card, Cancel and Send in the foot. Pad keyboard under the field |
| My ticket card | new | facts, thread, Add to it while open |
| Tickets queue | `AdminTab.lua`: replaces the section at `:249-265`; the count goes on the tab's label | filters as drawn; each change is a `t_queue` |
| Ticket card | new | facts, thread, notes, Answer, Add note; foot: Delete (admin), Spam, Take it, Close or Reopen, Answer. Delete confirms in the foot |
| Go there | ticket card | `SendCommandToServer("/teleportto x,y,z")` (`TeleportToCommand`, form `(-?\d+.*\d*),(-?\d+.*\d*),(-?\d+.*\d*)`); needs `TeleportToCoordinates`, grayed with its reason otherwise |
| Player card | ticket card | until Phase 2: opens the game's stats window, as `DO.stats` does (`AdminTab.lua:95`) |

All player text is drawn as plain text, never through `ISRichTextPanel`: the game's rich text would act on a player's
`<LINE>`, `<RGB:...>` or `<IMAGE:...>`. Real dates are drawn from `filed` on the viewer's side. Time zone: E5. Simple mode draws the same cards: they are
already plain. All text is `UI_ZeD_Tk_*` keys in the EN `UI.json`, then the translation run. Kind and status always carry
their word, never color alone.

## B12. The host's own server

A host's server is not in the host's game. In 42.22 they never share a process, so there is no shared Lua state to guard.

- **Two processes.** `CoopMaster.launchServer` builds a `java` command line and starts `zombie.network.GameServer -coop` with
  `ProcessBuilder`. `T.md`, the limits and the table's name live in the child. The host's game talks to it with the same
  packets as anyone, and `isServer()` is false there, so the guard holds with no special case.
- **Two save folders.** `getServerSaveFolder` is the sanitized server name, `getPlayerSaveFolder` that name plus `_player`,
  and `GameClient` runs the host's game from the second. Each process writes its own `global_mod_data.bin`, so the game's
  client save cannot overwrite the tickets.
- **One cache folder.** The child gets `-cachedir=` with the host's own folder, so `Zomboid/Logs`, `Zomboid/Lua`,
  `Zomboid/db` and `Zomboid/Server` are one place. ZeD's client never calls `writeLog("ZeD", ...)`, or two processes would
  write one log. A future journal in `Zomboid/Lua` must carry the server's name. The host can read the notes from the save
  file. They own the server.
- **The host is staff.** `-adminusername` makes the host's account with `Roles.getDefaultForAdmin`, and `LoginPacket` gives
  the connection that account's role, so `can` passes both tests. The game also lets the host through every packet check
  (`PacketAuthorization.isAuthorized`, `isCoopHost`) and runs slash commands as admin. ZeD reads the role alone, because
  server Lua cannot see that flag: `isCoopHost()` reads `GameClient.connection`, which is nil in the child. A host who demoted
  their own account would be refused by ZeD and obeyed by the game. They can promote themselves back.
- **It ends with the host.** `GameServer` logs "Host user disconnected, stopping the server" and calls `ServerMap.QueueQuit`,
  and a lost master does the same ("Coop master is not responding, terminating"). Both save global mod data, so a host's
  crash saves the tickets. Only the child being killed loses them.
- **Timers with nobody on do not arise.** The server is gone when the host is. E7's choice reads differently here: a timed
  ban cannot end while the host is away, and the host is always online to run an unban.

---

# Part C: new files

| Path | Holds |
|---|---|
| `42/media/lua/shared/ZeD/ZeD_TicketProto.lua` | `ZeD.Tk`: module names, `PROTO = 1`, the six kinds and NONE, stored statuses and the player mapping, `LIMITS`, `NEAR = 30`, tag build and parse, `clean`, `sameTicket`. Pure Lua, ASCII, nothing client-only at load |
| `42/media/lua/server/ZeD/ZeD_ServerCore.lua` | Guard. `ZeD.Srv`: `can`, the rate limiter, `register(module, command, handler)`, the one `OnClientCommand` listener with its reload guard, `ZeD.hello`, `eachStaff`, `log`, the `ISLogSystem.writeLog` wrap. Later phases add their modules here |
| `42/media/lua/server/ZeD/ZeD_ServerTickets.lua` | Guard. The table: name, open, migrate, eviction. `stamp`, `nearby`, `placeName`. `playerView`, `staffView`, the rows. Every `t_*` handler |
| `42/media/lua/client/ZeD/ZeD_ServerLink.lua` | `ZeD.ServerPart` (`present`, `v`, `staff`, `admin`), hello and its retries, `send(module, command, args)`, the `OnServerCommand` listener that routes by module |
| `42/media/lua/client/ZeD/ZeD_Tickets.lua` | The client's model: my rows, the queue page, the open card; `ViewTickets` matching, filing, linking, adopting; the game calls in B8; the fallback in B9 |
| `42/media/lua/client/ZeD/ZeD_TicketCards.lua` | Drawing and input for the four cards: render, hit zones, pad stops, the text fields |
| `ZeDUI/tools/qa/tickets_sim.lua` | Lua 5.1 stubs of `getOnlinePlayers`, `ModData`, `sendServerCommand`, `Capability`, and the server files run against them: permissions, limits, views, caps. Needs no game |
| `ZeDUI/tools/qa/mp_tickets.lua`, `mp_tickets.txt` | The bridge script and manifest for the local server |
| `ZeDQAShim/42/media/lua/server/ZeDQAShim/QARole.lua` | Guard. QA only, in the shim, never in the mod: command `ZeDQA.role {name}` runs `player:setRole(role)` on the sender's server object, from `getRoles()`. It is what makes the server's own permission tests possible (Part D) |

**Changed:** `ServerTab.lua`, `AdminTab.lua`, `ZeD_Messages.lua` (`M.ticket`), `ZeD_MessagesWindow.lua` (the `ticket`
kind), `42/media/lua/shared/Translate/EN/UI.json`.

`AdminTab.lua`'s `A.onTickets` takes every `ViewTickets` as the whole list, and goes with this work (A4).

Leave `42/media/lua/server/Items/` alone. No Java, no change to `mod.info`.

---

# Part D: the steps, in order

Each step ends with the game running. QA uses `mp_server.ps1 -Start` (it copies ZeD in fresh, `PauseEmpty=true` already)
and `zedqa_run.ps1 -Mp`, then greps `Logs/*_DebugLog-server.txt` and the `ZeD` log in `C:\Users\danie\Zomboid\zedqa_mp`.
The test client joins as admin, since a `-debug` client must. `mp_nonadmin.lua` cannot stand in for a plain player here:
its own comment says the server refuses `/setaccesslevel` on the logged-in account, and it calls `p:setRole(low)` on the
client alone, so the server still sees an admin and every permission test would pass for the wrong reason. The test client
sends `ZeDQA.role` to the shim's server file (Part C), which changes the role `can` reads and leaves the connection's, so
the `-debug` client stays on. `mp_server.ps1` already copies the shim to the server.

| # | Build | QA checks on the local server |
|---|---|---|
| 1 | `ZeD_TicketProto`, `ZeD_ServerCore`, `ZeD_ServerLink`: hello only | Server log says the part is up. Client: `ZeD.ServerPart.present`, `v = 1`, `staff` and `admin` true. Single player: no server lines, no errors. `OnInitGlobalModData` fires after the listener is added |
| 2 | The table: name, open, migrate. `tickets_sim.lua` begins | Table made with a UUID name; `/save`, stop, start: same table, `nextId` kept. **From the client: `ModData.request` of `ZeD_Tickets` gives false, and the real name is in no log** |
| 3 | `t_new`, `stamp`, `t_mine`, `t_one`, `t_reply`, rate limits; a bare client call, no card yet | Place and day come from the server even with lying args. Text of 1000 and 1001 characters. Second `t_new` inside 60 s refused with seconds left; a sixth open ticket refused. Hostile args from the bridge: `id` a string, a table, -1, 14.5; `rid` a long string; no args; `find` of `%[`. One bad line each, nothing sent back that was not asked for |
| 4 | Filing and tag, B8 player side | The game's own window shows `[GRIEF #n] ...`; the game's modal shows for now. Quit before filing, rejoin: filed once. Rejoin again: not filed twice |
| 5 | Staff: `t_queue`, `t_card`, `t_take`, `t_answer`, `t_addnote`, `t_close`, `t_reopen`, `t_spam`, `t_unspam`, `t_delete` | Every transition in B4, and every refused one. Through `ZeDQA.role`: as user, each staff command answers `perm`, with one log line a minute under a flood. As moderator: Spam yes, Delete `perm`. **As a plain player, dump every table `ZeD.hello`, `t_one`, `t_mine` and `t_row` deliver: no `notes`, `near`, `assignee`, `spamBy`, no `open` or `spam` count, and a spammed ticket reads Closed.** `t_one` of a staff member's ticket answers `gone`. Demote while a card is open: no more pushes reach it |
| 6 | B8 staff side: sync, link, adopt, game calls | A ticket filed in the game's window appears as No kind. Answer shows in the game's window; a second answer does not add a game row; Delete removes it there. **Remove a linked ticket on the game's window:** the record stays and reads Removed, the author's next login does not file it again, a moderator's Remove does not delete. From the bridge, as a plain player: `addTicket("zedqa", "[GRIEF #1] ...", -1)` does not link to #1; an answer on an unviewed ticket lands in notes and the ticket stays Open; 300 tickets in a loop stop at the caps with `skipped` counting, and open and close the queue twice with no rise. Evict a record: not adopted again. Own filing as staff: nothing marked gone |
| 7 | Belt note, offline catch-up, the staff modal wrapper | Answer while online: note and toast. Answer offline, rejoin: one note. Opening clears it. The game's modal no longer opens for tickets; other admin messages still do |
| 8 | Player cards in the Server tab | Keyboard and pad; Deck and 720 at Auto with Normal and Large text; all themes and accents; scroll to the foot |
| 9 | Staff cards in the Admin tab | The same, plus filters, Find, paging at 26 tickets, the count on the tab label, Go there with and without the capability |
| 10 | Fallback, B9 | Force it with `ZeD.ServerPart.forceOff` from the bridge. Then once for real: `DoLuaChecksum=false` and the server's `server/ZeD` folder removed from the cache copy |
| 11 | Restart and crash | `/save`, stop, start: all kept. Stop with no save: tickets gone, game tickets adopted, kinds kept, no wrong link when a number is reused. `/reloadlua` of both server files: one reply per command, table still open. A `ZeD` log line sent through `ISLogSystem` from the client does not land. Delete `zedqa.db` with the save kept: ids restart, `reset` runs once, and no `removeTicket` hits the wrong row |

`-Mp` covers one client. Step 3's nearby list needs a second player (E4). `tickets_sim.lua` covers its logic until then.

---

# Part E: not established, and how to settle it

| # | Unknown | How QA settles it |
|---|---|---|
| E1 | Whether Log Extender writes through `ISLogSystem` or the global `writeLog`, and whether it is on Build 42 at all. It is not among this machine's Workshop items | Phase 4: subscribe it on the QA rig, grep its Lua for `writeLog`, run the tap on the local server |
| E2 | Whether a `complete` wrapped in a server file is the one `NetTimedAction.perform` calls. It reads `complete` with `rawget` on the action, a `PZNetKahluaTableImpl`, which I did not trace to the end | Phase 4, first thing: wrap `ISSmashVehicleWindow.complete` with a print, smash a window on the local server, grep the server log. If it misses, wrap `.new` as Another Vehicle Claim System does |
| E3 | A place name on the server. No vanilla function gives a town from coordinates. `getWorld():getMetaGrid():getZonesAt(x, y, z)` (`shared/Traps/TrapSystem.lua:12`) gives zones, and what they name was not read | A probe at five known spots printing each zone's type and name. Failing that: `square:getRoom():getRoomDef():getName()` for a room, and coordinates alone outdoors. Until then, coordinates only |
| E4 | Whether two game instances run side by side here under `-nosteam` | Try it after a build. If not, the director joins from a second machine for the one nearby check |
| E5 | The time zone of a real date. `OsLib` sets `tzone` to UTC, and `os.date(fmt, seconds)` multiplies by 1000. `ISUsersList.lua:134` is the only vanilla use, and it passes no seconds, so vanilla proves nothing about that form | Print `os.date("%H:%M", getTimestamp())` beside the clock. If it is UTC with no way to shift, ZeD shows the date with "UTC" |
| E6 | Whether anti-cheat packet checks (`PacketValidator`, `AntiCheatPacketType`) count client commands | Fire 200 `ZeD.hello` in a second from the bridge and watch for a kick. ZeD's own limit is unaffected |
| E7 | **Temp bans: a design decision, Phase 2.** Below | The director |
| E8 | That `OnTickEvenPaused` really fires on an empty dedicated server. The bytecode says so | Phase 2: a counter on the local server, nobody on, `PauseEmpty=true` |
| E9 | That `getAnswer` always returns the first answer row. It reads the first row of an unordered select | D step 6 |
| E10 | The host's own server. `-nosteam` QA cannot host. B12 is read from the code; that the host's `IsoPlayer` carries the admin role is inferred from the connection's | The director hosts once: `staff` and `admin` true on hello, a ticket filed and answered, quit from the menu, host again, the ticket is there. Then end the game's process from Task Manager and host again: the ticket is still there |
| E11 | Behavior of a message near 200 kB through RakNet | Send a full card (60 messages of 1000 characters) on the local server |
| E12 | **A design question for the director.** The mockup closes a ticket to replies at Answered. A player with a follow-up gets no field, and files a new ticket or waits for Reopen. Staff must Reopen to reply twice, which the scope's "several replies, not one" may not mean. Built as drawn until told otherwise | The director. If the field stays open at Answered, a player's reply should move the ticket back to Progress so it re-enters the queue |
| E13 | **A design question for the director.** The scope files the player's words in the game's ticket, so a griefing report's first message is readable by any player with a Lua console, as it is in the game today. The alternative is a stub in the game's ticket ("[GRIEF #14] see the Tickets queue"), which keeps it private and gives the game's window nothing to read | The director. Filed in full for now, as scoped. The Ask card's help band does not promise privacy |
| E14 | What the server does when `sendTickets` passes the 1 MB buffer, which a long-lived server or a flood reaches. If it throws, no staff client gets a list and the game's window is dead too. ZeD's queue still works, with no sync | Fill the local server's table from the bridge past 1 MB and call `getTickets(nil)` |

**E7, the choice.** A server timer cannot lift a real ban (A7).

- **The game's ban, lifted by staff.** Enforced by the server at login. At expiry, the next ZeD staff client online runs
  the unban. If no staff log on, the player stays out past the date, which is when it matters most.
- **ZeD's own ban.** The server keeps the list and lifts it to the second, with nobody on. When the player joins, the
  server tells their client to show the reason and leave. It is enforced by the client, so a modified client could stay.
  Staff get a note when a client does not leave, and can use the game's ban.

**Recommended:** ZeD's own ban for timed bans, since "lift themselves" is what was asked and only this does; the game's
ban for permanent ones.

---

# Critic's changes

Checked against 42.22's Lua and `javap`, and against `MP_ADMIN_SCOPE.md`, the mockup and the repo. Almost all of Part A held.
A1 to A4 were read again line by line in the Lua and the bytecode, and are right but for the items below. A5 to A7 are for
later phases: every quoted Lua line and class was found and the signatures match, but the kick and ban paths were checked by
name and not traced.

**Wrong in the document**

1. A host's client and server do not share a process (the brief assumed they might). The document was right; B12 now says
   what that means: two Lua states, two save folders, one cache folder, the host's role, what ends the server.
2. `stamp` called `nearby` declared below it, a nil global at the first ticket with a place. Reordered (B3).
3. Part D tested permissions with `mp_nonadmin.lua`, which changes only the client's role. The server would still have seen
   an admin, so every `perm` test would have proved nothing. Added a QA-only `ZeDQA.role` in the shim.
4. `open` and `spam` counts in `ZeD.hello` went to every player. Staff only now (B6).
5. "Every add, view, viewed and remove replies with `ViewTickets`, so a staff client gets a fresh list" was false: the reply
   goes to the asker, and `addTicket(..., -1)` returns that author's tickets only (A4).
6. Line numbers: `ServerCommands.lua:210` not 209, `ISAdminTicketsUI.lua:203` not 204, `ISLogSystem.lua:81` not 79. E5's
   `ISUsersList.lua:134` passes no seconds.
7. Staff could not have matched on the client: `staffRow` holds 120 characters and "same first message" needs all of it.
   Matching moved to the server (`t_sync`, B8). `t_link` and `t_adopt` are gone.
8. Filing compared the client's text with the server's trimmed text, so any padded ticket would have been adopted as its
   own duplicate. `t_ack` now carries `file`.
9. B2's history cap left out Answered, the one status with no bound. `staffRow.placeName` was nil until E3 is settled;
   it is `where` now, with coordinates.

**Attacks closed**

10. Forged adoption status: an answer on a game ticket marked it Answered, so any player could push a ticket out of the
    Open queue. Status now needs `viewed`, and an unviewed answer goes to notes (B8).
11. Forged author against the 5-open limit: three forged tickets could block a player from filing. Adopted records no
    longer count.
12. Unbounded table: forged `addTicket` floods adopted without limit, and open tickets are never evicted. Caps: 300 open,
    100 adopted open, 3 per claimed author, 4,000,000 characters in all. `Open=true` accounts defeat per-user limits (B2).
13. Forged ZeD log: `ISLogSystem` lets any client write to the `ZeD` logger. Wrapped on the server (B10).
14. Denial log flood: each `perm` wrote a line. One a minute per player now (B6).
15. Unsafe arguments: `rid` echoed any value, `find` could be a pattern, game rows could be 32 kB. Bounds in B6.
16. A demoted staff member with a card open could keep receiving notes: `T.cards` pushes retest `can` (B6).
17. `t_one` told "not yours" from "does not exist". Both answer `gone`.
18. Modal wrapper: anchored the match, rate limited the note, left `observer` and `gm` with the game's modal (B7).
19. Rich text in player messages drawn as plain text (B11).
20. Said plainly in B5: the allowlists do not protect the first message or first answer, which any client reads from the
    game. Put to the director as E13.

**Tickets lost or brought back**

21. Removed on the game's window: the old rule, "a record whose tag is not in the game's list, the client files it then",
    would have refiled a removed ticket at every login. `gameFiled` now decides. The record stays and reads Removed. A
    moderator's Remove does not act as Delete, or the admin-only rule would have a side door (B8).
22. Eviction and Delete: the game's row stays, so the old matching would have adopted every evicted or half-deleted ticket
    again, each time the queue opened. `gameMax` stops this, relying on `AUTOINCREMENT` (A4, B8).
23. A reply taken for the full list: a staff member's own filing returns only their tickets, which would have read as all
    others removed. One request in flight, and two lists 10 seconds apart before anything counts as gone.
24. A game-window answer on a linked ticket was not handled at all. Now read in `t_gamediff`, unproved and labeled.
25. A replaced `db`: stale `gameId` could delete the wrong row. Detected by `top`, and every game call rechecks its row.
26. `/reloadlua` left `T.md` nil and could double the listener. `open` is lazy, the listener guarded, a failed migration
    freezes instead of half running (B2, B6).
27. Restart, reconnect, world wipe, kills and the default no-save setting set out in B10, with a staff line when
    `SaveWorldEveryMinutes` is 0. `hello` runs at each `OnCreatePlayer`, and on `perm`.
28. `frozen` left players unable to file: the client falls back to `addTicket` (B9). `Send` waits while the link is unknown.
29. No reply in 10 seconds keeps the text; a command's own limit always answers `wait`; a failed handler answers `fail`.

**Added to Part E**

30. E12 (replies at Answered, as drawn in the mockup), E13 (the first message is public), E14 (`sendTickets` past 1 MB).
    E10 widened with a kill test for the host. The status table in B4 is unchanged: it matches the mockup.
