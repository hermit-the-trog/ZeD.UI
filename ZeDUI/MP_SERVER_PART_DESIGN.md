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
   itself from a server timer alone (A7). This one needs a design decision before Phase 2. (Settled Nov 7 2026: every ban
   is the game's, made by a staff client or the optional host helper; see "Rules that hold" at the end.)
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

The two ways to build it are in E7. They need the director's decision before Phase 2. (Nov 7 2026: a third tool, the game's
own remote console driven by the optional host helper on the server machine, makes these calls with nobody on. See "Rules
that hold" at the end.)

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
| `42/media/lua/server/ZeD/ZeD_ServerHelper.lua` | (Nov 7 2026) Guard. `Srv.H`: the host helper's queue and answers files under `Zomboid/Lua/ZeD_helper/`, its allow-list and target patterns, `on`, `alive`, `read`, `write` |
| `ZeDUI/server_helper/zed_rcon_helper.py`, `README.md`, `test_zed_rcon_helper.py` | (Nov 7 2026) The optional host helper, Python 3 standard library only, run by a server's owner on the server machine; not in the Workshop item |
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

**Superseded Nov 7 2026 (the director):** a timed ban is the game's ban too, owed at once, and its unban is owed at its end.
It may run past its time while nobody can make that call, never short. See "Rules that hold" at the end.

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

# Build's changes (Nov 5 2026, Part D steps 1 to 7)

Where the build differs from Part B, and why. Everything else is as written.

1. **A replaced database (B8) needed a second test.** A list's `top` also falls below `gameMax` when the newest ticket is
   removed, by Delete or on the game's window. With `top` alone that reset every link, and each adopted record was adopted a
   second time. Now the `t_sync` with `reset = true` carries up to 20 rows that sit under a linked id. The server resets only
   if none of them still matches its record, and `t_syncd` says `reset` or `same`, with `gameMax`.
2. **The text cap holds when history is gone.** 300 open tickets can reach 18,000,000 characters, past the 4,000,000 in B2.
   With no history left to evict, a write answers `full`.
3. **A filing from a `t_mine` row reads `getTickets(me)` first,** so a filing whose reply was lost is confirmed and not filed
   twice. The record still decides: nothing is filed once `gameFiled` is set.
4. **Small additions to B6:** a command with a `rid` always gets a `t_ack`, success included, so a card never waits on
   silence. `t_queue` also carries `noSave` (the server's own value of `SaveWorldEveryMinutes`, for B10's line). A player's
   `t_row` carries `pv = true`, because staff who filed a ticket receive both kinds. A bad `kind` answers `text`, a bad `id`
   answers `gone`. Bad-argument lines are held to 6 a minute per player.
5. **QA:** `QARole.lua` is kept in the repo at `ZeDUI/tools/qa/shim/...`, since the shim is outside it. `mp_server.ps1 -Start`
   copies it into the shim on both sides, or the Lua checksum refuses the join, and takes `-Mods "ZeD_UI;ZeDQAShim"`, because
   the server did not load the shim before. It also answers `ZeDQA.nolimits`, so a run need not wait out five 60-second limits.

# Build's changes (Nov 5 2026, Part D steps 8 to 10)

The cards are `ZeD_TicketCards.lua`. Where they differ from Part B or the mockup, and why.

1. **The Tickets block sits after the Server block,** as drawn, and the queue at the top of the Admin tab, as drawn here and in
   `zed_admin_tools_v1.html`. B11 says "replaces the section"; the drawings say where. The queue stays inline in the tab's one
   list (B11's two-deep stack), so 25 rows push Players down. `zed_admin_tools_v1.html` draws a summary row that opens the queue;
   that is Phase 2's to decide.
2. **Every thread message is a stop** with nothing to press, or a controller could not read a long
   thread: the card scrolls only to a stop.
3. **The back and foot stops are said to lie above and below the list,** whatever their place on screen, or Down from the last
   line in view lands on the foot and skips what is under the fold.
4. **With a controller the help line holds the prompts,** so an answer to a press, a grayed control's reason and the fallback's
   line cannot be read there. On a card they go in the foot's own line; on a tab's list they are a line in the list.
5. **Status marks are ZeD's squares,** hollow, half and solid, not the mockup's round glyphs: the fonts have none, and a status is
   a square by the cohesion spec. **The back key has no word beside it** (the mockup's "Server"): the card back bar is ZeD's
   molecule, the same on every card; its help line names where it goes.
6. **`Y Filters` is not built.** Y is the window pair on every ZeD surface. Up reaches the filters.
7. **The date reads UTC** (`DATE_SAYS_UTC` in `ZeD_TicketCards.lua`) until E5 is settled.
8. **A field grows with its words,** so nothing scrolls inside the card's scroll. **Past what fits, the player pop-up ends in a
   line pointing to Find.** Same reason.
9. **`ZeD_CharacterWindow.openTab` did not exist,** so a note's Open went nowhere. Added, as the World window's.
10. **The keyboard's `_multi` is turned off for these fields,** so RT ends the typing. With it on, RT makes a line break and the
    plain way out is B, which puts the field back as it was.
11. **The band gained `lead`,** push buttons at its left, and **the tag `frameColor`.** Tokens gained `violet` for Appeal.

# Build's changes (Nov 5 2026, after the review)

Where B2, B4, B6, B8 and B9 now differ, and why.

1. **An answer from the game's side is never proof, viewed or not.** `viewed` shows that staff opened a ticket, and any client
   can add an answer row after that (A4). So B8's two tables change: every game-side answer goes in `notes` with `game = true`,
   for staff only, and never in the thread. Adoption gives Seen if viewed, else Open, never Answered, so every adopted record
   sits under the open caps. A foreign answer sets `gameClaim`, not `gameAns`: `first` stays true, and ZeD's real first answer
   still goes to the game. The cost: a real answer given on the game's window reaches staff as a labeled note, and a ZeD player
   reads it only in the game's window. On a server with old answered tickets, those adopt as open, up to the cap, for staff to
   close.
2. **B8's "no list of tombstones" has one small exception.** A tagged row whose id is below `nextId` and has no record was deleted
   or evicted, so it is dealt with and not adopted. A crash that rolled `nextId` back still adopts, as B10 says. A Delete with no
   game link keeps `md.tombs[id] = author`, at most 50, until the row is seen. The batch's ack then says `remove`, and the staff
   client removes the row after testing its tag.
3. **What staff did before a link is owed at the link.** The batch's ack says `owe {g, view, text}`: viewed, and the first staff
   line as the one game answer. `getTickets(nil)` now also runs 2 seconds after a `t_row` with `unlinked` (the author's `t_filed`),
   after an answer or a Delete with no link. B8 said only on opening and Refresh.
4. **A replaced database needs a row that proves it.** After every sync up to 20 rows under linked ids go to the server, the
   newest first. One that is not its record resets, whatever `top` says, and each `ans` carries its row, tested before anything
   is written. An empty proof answers `same`: `top` below the lowest link is not evidence, since it is also what removing the only
   ticket looks like. If two lists agree `top` is below `gameMax`, `lower` brings `gameMax` down to `top`, which heals a forged
   `g`. A linked id missing from two lists is gone even above `top`, since `compare` runs only after `same`.
5. **One `t_sync` batch out at a time.** The next goes after the ack, and a refused or unanswered batch goes again, the same rows:
   `gameMax` is a watermark, so a batch the general limit drops must not be passed.
6. **The text budget.** Players, adoption and game-side answers stop at `PLAYER_CHARS`, 3,500,000; the last 500,000 is for staff.
   Past the line a player's write can evict only Spam. History goes early only for a staff write. Adopted records go before ZeD's,
   then oldest first. The record being written to is never evicted. "tickets full" is one line a minute for the server.
7. **`t_card` and `t_one` ack.** `t_queue` no longer clears `T.cards`: new `t_cardoff` does, sent when a card closes, because the
   queue's own traffic runs under an open card.
8. **E13 off files the staff's answer as the stub too** (`Tk.answerText`), or the first answer stays public.
9. **The fallback (B9):** Answered needs viewed and an answer. An answer on an unviewed row keeps the ticket open and is labeled as
   the game's. A ZeD card opened there calls `viewedTicket`.
10. **The cards.** A field never outgrows the view, and one being typed in stays in view with its box. A push that takes a field
    away keeps the words on the card and says why in the foot. With a controller the foot's words have a line of their own above
    the bands, and a gray Previous or Next gets a line in the list. Player text wraps with a hard break and keeps blank lines. The
    card's place reads name and coordinates (`Tk.whereFull`). The adopted card's caveat is a line on the card. The wheel over a
    field scrolls the card, the hint is drawn by the card, wrapped, and the keyboard's key reads Accept (`setSingleLine`). It still
    sits at the screen's foot, not under the field.

# Build's changes (Nov 5 2026, Phase 2, admin tools)

The files: `shared/ZeD/ZeD_AdminProto.lua` (`ZeD.Adm`), `server/ZeD/ZeD_ServerAdmin.lua`, `client/ZeD/ZeD_Admin.lua` (the model),
`client/ZeD/ZeD_AdminCards.lua` (the cards, on the ticket cards' engine, which gained `TC.kinds`, `TC.items` and pick lists over a
card). Module `ZeDA`; every answer comes back as `t_ack`. The table is `ZeD_AD_` plus a UUID, as B2. The sims are `admin_sim.lua` and
`admin_cards_sim.lua`; the bridge is `mp_admin.lua` and `mp_admin_cards.lua`. Where it differs from Part A, E7 or the drawing, and why.

1. **A7 said a staff client makes the game's call. Two kinds now do.** Kick, warn, teleport, mute, role and Level Up go from the
   client that pressed, on the ack. Ban calls go through `md.owed`: the server holds each one (`act`, `target`, `reason`, `at`) and
   sends it to the actor or any staff member online until one answers `a_done`. That is what lets a player read the reason first
   (the game's ban waits `LEAVE_S`, 12 seconds), an unban survive the actor leaving, and a timed ban's `Kick` back up the client's
   own leaving. A modified client that ignores `a_leave` is kicked by the server's game call when it is banned online.
2. **E7 as settled, with one edge.** (Superseded Nov 7 2026: every ban is the game's too, and a Steam ID matches on the
   server's own number; see "Rules that hold".) Timed bans are ZeD's, permanent ones the game's. Server Lua sees no IP (`UdpConnection.getIP` is
   not reachable) and `IsoPlayer.getSteamID` is a long past what a Lua number holds, so a client names its own Steam ID in `a_hi`. A
   timed ban on a Steam ID is client-claimed, like the rest of a timed ban, but the claim is checked: `IsoPlayer.getSteamID` read as
   a Lua number must equal the claim read the same way, which narrows a client to the few IDs sharing that double, and a server without Steam takes none.
   A timed ban on an IP is refused (`TIMED_IP`, below). A ban row can gain the game's ban (`a_gameban`) when a client stayed, and that
   comes off when the timed ban ends.
3. **Mute.** The game's mute is voice only (`/voiceban`, `BanUnbanUser`). `IsoPlayer.setAllChatMuted` is set by the words filter and
   read by nothing in the chat path of 42.22. So Mute is the server's list (`md.mutes`, `a_mutes` to everyone): each ZeD client hides
   those lines and the muted client will not send. It is client enforced. A client without ZeD's chat is not stopped.
4. **Repeating messages do not go through `/servermsg`.** Server Lua cannot reach `ChatServer`, and `ChatManager` is not exposed. A
   repeat is `a_srvmsg` to every connection, and `ZeD.Chat.serverLine` adds it with the server alerts. The first send is the game's.
   It reaches only clients with ZeD's chat, and it has no alert over the screen. The clock skips an empty server instead of bursting.
5. **The powers.** `GameServer.changeRole` switches on three, not the drawing's five: Invisible, No Clip, God Mode, each only when the
   old role lacked it. The server watches for the role to land (`ROLE_WATCH_S`), turns off what was not ticked on its own object and
   tells the player's client, which uses the game's setter and `sendPlayerExtraInfo` (client only).
6. **Capabilities.** The drawing's 23 are the game's 97: all sit in the five groups, with short words (`UI_ZeD_Cap_*`) and the game's
   tooltip in the help band. Each group folds, or a controller would walk a hundred stops. X is Save on this card and Spawn on the
   spawn card (the drawing's START), since START is the game's.
7. **A role's name cannot change.** The game's `setupRole` has no name, so the field shows only for a new role. Up and Down are added
   to a role's card, or moving roles would have left with the Roles List window.
8. **The Bans card gains a reason field and the lengths** for a ban on someone offline: the drawing has none, and each ban shows a
   reason. A row can come from the game's own lists (`getBannedSteamIDs`, `getBannedIPs`, a `banned` role) with no ZeD record: it says so,
   and Unban goes through the server for the log.
9. **Manage Inventory opens the game's window,** not the ground pane as drawn: that pane is ZeD's world window and reading another
   player's items into it is a job of its own.
10. **Offline players come from `md.players`,** kept by the server's walk (`POLL_S`, a copy every `SNAP_S`), capped at 2000 oldest out,
    merged with the game's `getUsers` on the client, which alone has warning points, kicks and Steam names. Without `SeeNetworkUsers` those
    read 0. Kick counts are the game's.
11. **The Tickets queue moved behind the summary,** on a screen of its own (`st.screen`). `TC.queueWatch` keeps it read while the tab
    shows, so the sync with the game's list runs as before. `tally` gained `kinds` for the summary, staff only.
12. **User Logs are the game's** (`requestUserlog`), each as a message stop. `getLastUpdate` is the date; the drawing's "Day 9" is not stored.
13. **`Srv.adminLog`** writes every action to the ZeD log and to `md.log`, a ring of 2000 lines (who, what, target, text, place, real
    time, day) for Phase 4. Reasons are in those lines; a ticket's words are not.
14. **Safehouses and Factions stay in the tab,** under Spawn items. The drawing leaves them out. Phase 3's cards hold only your own, so
    these lists stay as the way staff see everyone else's (see the merge's notes below).
15. **The ban screen** is `ZeD_LeaveScreen`, over the game for 12 seconds with Leave. Phase 5 sets `ZeD.Admin.leaveScreen(info)`, and
    `info.appeal` already has its line.
16. **The director's questions, each answered the careful way behind one switch in `ZeD_AdminProto.lua`:** `TIMED_IP = false` (Ban IP too
    goes with Permanent alone, since only a staff client could lift it); `RANK_GUARD = true` (nobody kicks, bans, warns, mutes, brings or
    levels a role above theirs; the game asks that only of a role change); `MUTE_STAFF_SEES = true` (staff still read a muted player, marked);
    `SPAWN_TELLS = false` (a player is not told, as `/additem`).

**Part E gains:** E15, whether `getRoles` holds every role on a client without `RolesRead` (a gray then names no role); E16, whether `getUsers`
fills on `requestUsers` alone (the game's own list reads it in `populateList`, with no event: ZeD reads it every second while the tab shows);
E17, whether a `/banuser` from `a_owed` shows staff the game's answer; E18, whether a player reads the 12-second screen before the game's
ban lands on a slow client. Each needs a second client on the local server (`mp_admin.lua` prints them as TODO lines).

# Build's changes (Nov 6 2026, Phase 2, after the review)

1. **A row's name is never read by its shape.** A username may be 17 digits from 7656 (`isValidUserName` allows it). The cards send
   `user` from a row and `target` only from the Bans card's typed field. A typed target the server knows as a name, in any case, is a
   name. `a_unban` takes `id`, `user`, `sid` or `ip`, each for what it is. `a_ban` no longer takes a `sid` at all: a ban's Steam ID is the
   one the server checked in `a_hi`.
2. **The guard holds on a Steam ID and on an unknown name.** A Steam ID runs the guard of every record that holds it, and a ban is tested
   again whenever it is about to act (`bindsRole`), so a row made while little was known never removes a protected or higher role. A
   name the server has never met answers `unknown` for a timed ban, warning points, a mute and a role, since there is no role to test;
   a permanent ban still goes to the game, which tests it itself. **An IP has no such test:** server Lua sees no IP, so nothing ties one
   to an account, and `/banip` asks only for `BanUnbanUser`, as it does in the game's own window.
3. **Rank.** `Roles.addRole` starts a role under every other, so a role's rank is never counted under `user`. Its holders act on plain
   players as soon as it is saved, and on nobody above `user` until it is moved. On the Role card Up and Down follow ZeD's list, least to
   most, so Down is more rank; the game's list runs the other way.
4. **Owed calls carry their ban.** Unbanned or lifted, the calls go with it, and an unban is owed only if the game's ban was made or may
   have been. A call whose author lost `BanUnbanUser` (their last known role) or whose target rose above the ban is dropped with a log
   line. A Kick goes a moment past the client's own clock and is dropped if they have left, so there is no age limit: an owed Kick is
   either on someone still under the ban or it is gone. A call goes to one named client, which alone can answer `a_done`, and never to
   its own target. A standing ban shuts its holder out of every command but the hello.
5. **Ban IP too.** The game's IP ban needs the player on, refuses a Steam connection, and in either case bans nobody. So the IP call goes
   first, at `LEAVE_S`, with the client held on the reason screen (`hold`: no Leave, the client's own clock doubled as a last resort),
   and the plain ban always follows, `IP_GAP_S` later. A player gone before the call, or still on after it, means the game holds no IP:
   the row says so and staff get a note. Offline, Ban IP too is refused up front.
6. **A permanent ban keeps them out until the game holds it.** Until `a_done`, the row works as a timed one does on joining. With a Steam
   ID on record a `BanSteamID` follows the plain ban, the only one of the two that stores a reason for the game's login line. Otherwise a
   permanent ban shows the reason only while they are online, and the Bans card says so.
7. **One row per player.** A second ban answers `already`, and the Player card shows the ban with Unban in Ban's place, behind the foot's
   confirm. `BANS_MAX` drops the oldest permanent row the game already holds; timed rows are never dropped. `a_ban` and `a_unban` are paced
   (`BAN_MS`), and past `OWED_MAX` a Kick goes, never a ban or an unban: those commands answer `full`.
8. **Case.** The game's login matches `LOWER(username)`, so bans and mutes do too (`md.mutes` and the clients' list are lower case). Read
   from the SQL only: a second client should confirm what spelling reaches `getUsername`.
9. **The audit ring.** Past `LOG_ACTOR_MAX` a new line takes the place of that account's own oldest, so no one account evicts another's.
   `s` is the order; Phase 4 sorts by it. `a_power` takes only an id on `POWER_CAP`, with its capability.
10. **A role change across a restart.** The watch is in `md.watch`, and one back from a restart waits for that player's `a_hi`.
11. **Reads on the card.** A player's tickets go to `AnswerTickets` alone, and the place of a role above the viewer's stays out of the view.
12. **The game's windows.** Users and Check your stats are under More tools, and Check stats is on every Player card: accounts, passwords,
    the whitelist, add XP, professions, traits and the game's banned lists have no card yet, and those windows are the way there.
13. **Spectate is not built.** The scope lists it for the player card; the drawing dropped it, and the game's Lua has no spectate call to reach
    (none on the admin panels, none on `LuaManager$GlobalObject`). For the director.
14. **Without the server part** a Mute is the game's voice ban, kept on this client so Unmute works, and the card says voice only. A role
    change says the game leaves the powers on. Timed bans and a spawn to the ground are refused, never turned into something else.

**Part E gains:** E19, whether `IsoPlayer.getSteamID` reaches Lua as a number on a dedicated Steam server, as `KahluaNumberConverter` reads;
if it does not, `sidOf` refuses every claim and name bans simply carry no Steam ID. E20, whether the game keeps the typed spelling of a
username (item 8). Each needs a second client on a Steam server.

# Build's changes (Nov 5 2026, Phase 3: safehouses and factions)

Files: `ZeD_ClaimProto.lua` (shared), `ZeD_ServerClaims.lua` (server), `ZeD_Claims.lua` (the model), `ZeD_ClaimCards.lua` (the cards).
`claims_sim.lua`, `claim_cards_sim.lua`, `mp_claims.lua`, `mp_claim_cards.lua`. Nothing is stored: no table, so no secret name.
Where the build differs from `mockups/zed_safehouse_faction_v1.html` and `MP_ADMIN_SCOPE.md`, and why.

1. **Expiry is the safehouse's, not a member's.** The game's tooltip says players are removed; its code does not. `SafeHouse.update`
   releases the whole safehouse once `lastVisited + SafeHouseRemovalTime` hours has passed, and any allowed player standing in it
   resets `lastVisited` (`IsoPlayer.updateInternal2`). So the drawing's "away 61 h: removed in 11 h" on a member's row is gone, and
   the card says "Keep it by visiting within 3 days", as the scope has it. A member's row says online or offline.
2. **The time left needs the server part.** `SafehouseSyncPacket` carries no `lastVisited`, so a client's copy is only the moment it
   first heard of the safehouse. `c_info` sends hours ago, so no client clock enters the sum. Without the server part the rule shows
   and the countdown does not.
3. **Faction PvP and Show Tag are each player's own,** in the game (`IsoPlayer.setFactionPvp`, `setShowTag`, `FactionStatsPacket`),
   not the owner's as drawn. Both ticks show for every member, and a line says so.
4. **An invitation has no take-back call,** and only the server holds the list. Cancel on a pending row goes through `c_cancel`
   (`Invite.removeInvite`, reached through `SafeHouse` and `Faction`). Without the server part it is gray and says why, and "invited,
   waiting" is this client's memory for this session.
5. **Invitations the client has no note of** (it joined after one was sent) are raised from `c_info`, which reads `hasInvite` on the
   game's lists. The game sends an invitation once, to a player online, so with no server part one sent before a relog is gone, as
   in the game.
6. **The log compares the game's lists every 5 seconds** on `OnTickEvenPaused`, so a change from any window or the game's own expiry
   is logged and none rests on a client's word. It writes through `Srv.action`, the one log (see the merge's notes below). It names who a change touched, not always
   who made it: the game keeps no doer. At most 40 lines a pass.
7. **Fields sit in the cards through two small additions to the ticket frame:** `TC.kinds` and `TC.items` (`TC.itemKinds` until the merge with Phase 2). A field's `one` makes it
   a line that Enter saves and Escape puts back. `seed` keeps the box with what the game holds unless someone typed over it. A long
   confirm is `foot.line`, on the line over the bands with mouse or pad, because the game's confirm words outrun a band at Deck width.
8. **Save has no answer to wait for.** The game's calls send nothing back, so `C.expect` watches for the change for 8 seconds, then says
   "Nothing changed. The server may have refused it." and keeps the words.
9. **Member rows pick to a second line** when the buttons will not fit beside the name, as at Deck and 720. Drawn beside it.
10. **Marks for a rule are ZeD's squares,** solid and hollow, not the drawing's check and cross: the fonts have neither, and each rule's
    words say it anyway. The drawing's pointing hand is ZeD's focus mark. **The pad keyboard sits at the screen's foot,** not under
    the field, as for tickets. After typing, focus goes to Save.
11. **The place reads coordinates and the game's `getLocation`,** not a town: E3 is still open. The checker says "at 6402 x 5410".
12. **Wars have no drawing.** Built as a card of the same parts. Refuse and Cancel go at once, as in the game's window. Accept and End ask
    in the foot (`Cl.WAR_CONFIRM`), which the game does not do.
13. **The rules show in the Server tab too** when you have no safehouse, under Can I claim this?, because that is when they matter. The
    drawing has them only in the card.
14. **The Tickets block stays directly under the Server block,** as its drawing has it, then Faction, Safehouse, Wars. The order in this
    drawing has no Tickets block.
15. **A claim's title is the username,** as the game's context menu sends it, not "Riverside house", until E3 gives a place name. The
    title field takes the caret when the card opens; under the controller the card lands on it.
16. **The game's 15 and its words' 14:** its code takes a 15-character faction name, its text says 3-14. ZeD holds to 14 (`Cl.NAME_MAX`).
17. **A rename has no claim-day test.** `SafehouseChangeTitlePacket` extends `SafehouseID` and tests only that the title is not empty; the
    survival test is in `SafeHouseTitle`, the claim packet's parent. So an owner on a new character can rename, as the game's window lets them.
18. **The HUD's war icon opens the wars card** (`ISEquippedItem:onOptionMouseDown`, wrapped as `ZeD_ClaimCards.lua` loads, because the button
    keeps the function it was built with). `ISWarManagerUI` runs only if the tab cannot open. The right-click menu's Claim war stays the game's:
    the card says how.
19. **A tag's Save waits for the server.** `sendFactionChangeTag` reads the tag and color off the client's object, so ZeD sets them, sends, and
    puts them straight back; a tag the server takes reaches every client in a `FactionSync`, the sender too. The tag field is for an owner or
    FactionCheat with enough members: `FactionChangeTagPacket` has no exception for any role. One the game does not fix: with a tag that exists,
    the packet refuses anyone but the owner, so FactionCheat staff who are not the owner cannot change a color alone, and the card says nothing changed.
20. **The log compares the game's lists every 5 seconds,** which is the limit of what Phase 4 can read from it. A change undone between two passes
    leaves no line (an owner hands the house over and takes it back; someone joins and quits). A pass writes at most `LOG_PER_SCAN` lines and then one
    `claims | N changes not logged` line. Player text in a line has its `|` turned to `/`, so a split on ` | ` gives seven fields. Factions are compared
    by the object: two can share a name, because the game's rename does not test for one.

Not settled, for QA on the local server (`mp_claims.lua` prints these as PROBE lines):

| # | Unknown | How it settles |
|---|---|---|
| F1 | Whether Lua sees `hasInvite` and `removeInvite`: they live on `Invite`, which is not in `LuaManager$Exposer`. Absent, `c_cancel` answers `fail` and waiting invitations are not raised | PROBE line. Two clients for the real run |
| F2 | Whether `IsoPlayer.updateInternal2` reaches `setLastVisited` on the server's copy of a player, as the bytecode reads | PROBE line: hours ago near 0 while standing in it |
| F3 | **Settled by the jar: one refused safehouse packet kicks by default.** `SafehouseRelease`, `ChangeOwner`, `ChangeTitle` and `Invite` carry `AntiCheat.SafeHouseOwner`, `ChangeMember` carries `SafeHouseMember`. Both are built with `maxSuspiciousCounter` 1, `AntiCheatSafeHouse` defaults to 2 (kick; 1 bans), and `SuspiciousActivity.report` returns 1 on the first hit. Roles with `CantBeKickedByAnticheat` and debug servers are spared. So each confirm remembers the house it was opened on and is checked in the foot and on the press (`X.stillTrue`), and Save and Invite read the game's lists first | Two clients: a confirm open while the other removes or transfers. Expect the foot to close with no kick |
| F4 | `onCommandEntered` on `ZeD_TextEntry` with `setMultipleLine(false)`, and the one-line box's height at each text size | Type a title on the local server; `mp_claim_cards.lua` at each size |
| F5 | E8 again: that `OnTickEvenPaused` fires on the server. The log rests on it | The `safehouse | claim` line appears within 5 seconds |

# Build's changes (Nov 6 2026, Phases 2 and 3 merged)

Both phases grew the ticket frame at once. What the merge settled:

1. **One hook for each job.** `TC.kinds` takes one contract: `key(t, card)`, and `cancel` answers true when it dealt with B, or the frame's
   own answer runs. `TC.items` replaces `TC.itemKinds`: `gap` in design units, `draw(..., ctx)`, `stops(it, x0, dy, w, add)`, and `stops` may
   be left out. `D.makeField` takes the whole item. A field's `seed` replaces its `start`; `afind` keeps `start`, for its own box. Labels both
   wrap and take `right` or `rightFn`, cut to the room left.
2. **One log.** `Srv.action(kind, who, what, target, detail, x, y, z)` in `ZeD_ServerCore.lua` writes every admin, safehouse and faction line:
   `kind | what | who | target | where | detail | day N`, seven fields, `-` for an empty one. `Srv.adminLog` is that call with kind `admin`.
   `md.log` holds every kind, with `kind` on each row, under the same per-account share. A faction's name is the line's target. With the
   admin tools off the lines still reach the ZeD log, but no ring holds them. Ticket lines are still free text: Phase 4 moves them.
3. **The Admin tab keeps Safehouses and Factions.** The Server tab's cards read only your own (`C.safe`, `C.fac`), so these lists are the only
   way staff see anyone else's. Your own row opens its card; anyone else's opens the game's window, until a staff card holds them.
4. **Two answers to a command stay.** Admin commands answer on the tickets' `t_ack`, and claims on their own `c_ack` through `ackModule`, since
   those cards work without the tickets' model. `Srv.ack` carries both.

# Build's changes (Nov 6 2026, Phase 6: server extras)

Files: `ZeD_ExtrasProto.lua` (shared), `ZeD_ServerExtras.lua` (server), `ZeD_Extras.lua` (the model), `ZeD_ExtrasCards.lua` (the cards, the Vehicle tab's
pieces, the map's button). `extras_sim.lua`, `extras_cards_sim.lua`, `mp_extras.lua`, `mp_extras_two.lua`, `mp_extras_cards.lua`. The table is `ZeD_EX_<uuid>`, never transmitted.

**Off means off.** Until a system is on, the file wraps nothing, adds no listener and no clock: the game's own functions are in place. `Srv.exOn` holds what the wraps test.
Once on, a wrap stays (a later mod may have wrapped over it) and starts with one test of a boolean. `extras_sim.lua` proves both: a stub vehicle and safehouse count every
touch, and the count stays 0 through every action, swing and tow with claims stored. A failed test lets the game's function run.

**What the server can refuse, and what it can't.** From the bytecode; each row is 42.22.

| Act | Path | Refused how | Enforced by |
|---|---|---|---|
| Uninstall, engine parts | timed actions; `NetTimedAction.perform` calls Lua `complete` on the server | `complete` answers false | **server** |
| Siphon | the same, but the gas moves before `complete`: `serverStart` emulates an `update` anim event each second, and `animEvent` runs `update` on the server | `animEvent` is wrapped, so no event moves gas for a player a claim stops, and `complete` answers false | **server** |
| Dismantle, scrap furniture, pry a barricade, sledgehammer | timed actions | the same. The game's `SledgehammerOnlyInSafehouse` refuses this way | **server** |
| Start the engine, hotwire | timed actions | the same | **server** |
| `vehicle.startEngine` | a client command with no action around it: the game's handler calls `tryStartEngine`, with no test. The game's client sends it when a running car loads | can't be refused. This file's listener runs after the handler and shuts the engine off at once | **server**, after the fact |
| Sit in the driver's seat | `VehicleEnterPacket`, no Lua hook | can't be refused. A 2-second clock shuts off a running engine under anyone a claim stops: at most 2 seconds of driving | **server**, after the fact |
| Tow | client command run by the game's local handler, which nothing can stop | this file's listener runs after it and calls `breakConstraint`, as `detachTrailer` does | **server**, after the fact |
| Axe at a door, built wall, barricade | `PlayerHitObjectPacket`, Java; no refusal. `OnWeaponHitThumpable` fires on the server before the damage | the object gets room for the swing, and its old health back next tick | **server**, unproved until QA (G6.4) |
| Take from a container | `ItemTransactionPacket`, `TransactionManager`: Java, no Lua on the server at all | not refused: logged only, and only from **the player's own client**. The server tests that the report could be true. The card says a modified game can leave lines out and any game that drops off loses its last ones, and the line says "reported by their game". A player's reports hold 100 lines of the Log's ring and replace only each other (`LOG_TOLD_MAX`), and the container's word stays in the line's text | **client** |
| The Vehicle tab graying Uninstall and Take Parts | a courtesy: the refusal otherwise comes at the end of the wait | the server refuses anyway | client, never relied on |

Not stopped at all, and said on the card: looting a trunk, deflating a tire, breaking a car window, ramming; windows on a house, fire, cars, zombies.

**What a refused action is judged by.** The server runs no Lua `isValid` (Java `NetTimedAction.isValid` answers false and `perform` calls only `complete`), so anything a client names is its word. A scrap is
judged by the object it scraps, whatever square it names. A tow by the car the game finds: `getVehicleById` truncates the number and narrows it to a short, so `Ex.vehId` does the same, and 65553 is car 17.

**A claim proves its car.** `getSqlId` outlives a restart, but the game gives a removed car's number to the next new car (`VehiclesDB2`: `allocateID` hands out the lowest free id). So a claim leaves a stamp in the
car's own mod data (`IsoMovingObject.save` writes it with the car). A burnt car's claim goes when anything reads the car, and when the wreck is cleared (`ISRemoveBurntVehicle`). An owner who is on hears of any claim that goes.

**The stamp alone wasn't enough** (Nov 6 2026, after the phase). ZeD never sends the stamp to a client that already has the car, and `ObjectModDataPacket.parse` replaces the server's copy of a car's mod data with whatever a client sends, asking only
`LoginOnServer`: `KahluaTableImpl.load` wipes first, and an empty send takes the `wipe` branch. `RetroDashboardDigital` calls `vehicle:transmitModData()` on the client, so one player with that mod dropped the claim as "that car is gone", and a
modified client could drop anyone's on purpose. So `F.sameCar` asks two things that each stand in for the other: the stamp, and the car's key number, kept in the claim as `kid`. `keyId` is `Rand.Next(100000000)` in the `BaseVehicle` constructor,
saved and loaded with the car, and no network class in the jar names `setKeyId`, so a client can't touch it (`VehicleFullUpdatePacket` carries it, with the stamp, but its `handlingType` is 2, client only). A lost stamp on a car with the right number is put back on the server's copy; a new number on a car with its stamp (Locksmith's
`vehicle:setKeyId`, on the server) goes into the claim; with neither, it's another car and the claim goes. The reused number stays handled: a new car has neither.

The stamp isn't a secret. `VehicleFullUpdatePacket.write` calls `BaseVehicle.save`, so a client that loads the car after the claim holds the stamp (a car the client already has is read into `tempVehicle`, so its own copy stays without). `RetroDashboardDigital` sends on every exit (`setVehicle(nil)`),
and nothing looks at a parked car, so `F.poll` keeps a claimed car on a list for `LEFT_POLLS` polls after its driver goes, and puts the stamp back. What's left:

- A client's send on a parked car after those polls, by a mod that sends from outside the car, then a new lock before anything looks at it: both are lost, and the claim goes as "that car is gone".
- A new car has 1 chance in 100 million of the old key number by luck, but Locksmith's `repinVehicle` sets a car's `keyId` to the number of any vehicle key the player carries, so two cars can share one on purpose. A new car on a reused number, not yet looked at, re-pinned to a copy of the old car's key takes the old claim without `x_claim`'s tests. Keeping the car's script in the claim wouldn't stop a same-model reuse, so it isn't done.
- A modified client can copy the stamp from a full update and send it onto a new car on a reused number before anything looks at that car, which takes the old claim the same way.

`getMechanicalID` looks the better number and isn't: `createPhysics` rolls it again every time a car loads, outside its `created` test. The server still never transmits the table:
that would overwrite whatever a client's mod had just sent.

**A save can't undo another's.** `x_save` replaces the whole set, so it carries the set the card's changes were made on, and the server answers `changed` if that isn't the set it holds. A card that hears
another admin's save takes it, with its own changes on top, and says so.

**The anti-cheat.** `complete` answering false reaches `ActionManager.update`, which marks the action Reject and sends it; the client's `LuaTimedActionNew.update` sees `isRejected` and
stops. `NetTimedActionPacket` carries no `AntiCheat` interface and no `SuspiciousActivity` is touched, unlike the safehouse packets of F3. Nothing here sends the game a packet it would
refuse: tow and swings are repaired after the game's own handling, and a claim is ZeD's own command.

**Why a class wrap works.** `NetTimedAction.perform` does `action.rawget("complete")`, and `KahluaTableImpl.rawget` walks the metatable, so an action reads its class's function at that
moment. The class table is the place to wrap (E2's question, answered in the bytecode).

Where the build differs from `mockups/zed_community_v1.html`, and why.

1. **The teleport is `TeleportToCoordinates`,** not the drawing's "Teleport to a player": that is what the game's `/teleportto` asks for, and what Go there already reads. The Who line is
   built from the game's roles and shows the capability's own word.
2. **Your claims is new.** Not drawn. A claim lapses only while its owner is away, so a player who lost a car would hold the slot for ever without it: a row in the Server tab, under the
   extras, opens a card with each car and Release behind a foot confirm.
3. **The steppers' number is plain text** between two buttons, not the drawing's boxed value; `aflow` has no boxed item and a new one for one number earns nothing. Each end is gray and says why.
4. **Save is X under the controller,** as on the Role card, not the drawing's START: the frame has one slot for it (`padX`).
5. **Each system says what it can't stop,** under its ticks. The drawing has no such lines; the job asks for them.
6. **Drive it has a line of its own:** "They can still sit in the seat." The drawing says only "Drive it".
7. **The Server tab shows the extras block with the server part alone.** Without it there is nothing to say, and the block is gone.
8. **Your claims' rows show where the car was last driven by you,** which is all the server can know of a car nobody has touched.
9. **The extras block sits over Tickets,** as this drawing has it. Phase 5's Rules and News go above it when that merges.
10. **Vehicle tab:** Claim and Release are in the footer with no part chosen; a part's card keeps its own verbs. Claimed by is a row of the summary, under the key.
11. **The map:** Teleport Here on the Maps tab's band (`ZeD.MapsTab.addExtension`), the game's own word; the band's button arms it, as a mark tool arms, then a click or A goes. Vanilla has
    it on a right-click menu that ZeD's map doesn't draw.
12. **A burnt car's claim goes** the next time anything looks at the car or clears the wreck, and frees the slot. A wreck is nobody's.
13. **Taking parts covers siphoning gas.** Tires deflated, trunks and windows are not covered.
14. **A table from a newer ZeD turns every extra off,** where tickets go on reading: enforcing means writing (a lapse, a position), and frozen means no writes.
15. **A car at someone else's safehouse can't be claimed,** inside the walls or on the lot, whether or not protection is on. Not drawn. Without it a stranger by the fence could lock a member out of their own car. The
    careful answer, for the director: the drawing has standing by the car as enough, and `Ex.CLAIM_NEEDS_KEY` is still the stricter choice.
16. **The Server tab's protection line says "what's built there",** not the drawing's "anything": windows, fire, cars and zombies aren't stopped, and the card says so. Words for the director to look at.

The director's questions, answered the careful way, each behind one switch in `ZeD_ExtrasProto.lua`:

| Switch | Answer | What the other answer does |
|---|---|---|
| `Ex.LOT_TILES` = 5 | The game has no lot lines a server can read, so the lot is 5 tiles past the walls. Small, so it rarely reaches a neighbor or the road | Larger takes in more yard, and more of the street |
| `Ex.CLAIM_NEEDS_KEY` = false | As drawn: standing by the car is enough | true: the key in the inventory, which keeps a hotwired car out of a claim |
| `Ex.CLAIM_SHARE_FACTION` = false | "Others" is everyone but the owner | true: the owner's faction passes |

Not settled, for QA on the local server (`mp_extras.lua`, `mp_extras_two.lua`, PROBE and TODO lines):

| # | Unknown | How it settles |
|---|---|---|
| G6.1 | That a rejected action really only stops on the client: no kick, no suspicion, the bar goes away, the queue clears | bob's uninstall past the gray; he stays on, the part stays |
| G6.2 | That `getSqlId` outlives a restart, and is set by the time a player can reach a car (`sql < 0` answers "soon") | `/save`, restart, claim again: "taken" |
| G6.3 | That `breakConstraint` straight after `addPointConstraint` leaves both cars clean on every client | hitch a claimed car with two clients watching |
| G6.4 | That `OnWeaponHitThumpable` fires on the server, and that `setHealth` on all three objects takes (a door has no sync of its own). Only the bytecode says so | an axe at a door in another's safehouse; the door's health over 20 swings |
| G6.5 | That `shutOff` from the clock stops a car with a driver cleanly, sound included | get in a running claimed car |
| G6.6 | `/teleportto` with z 0 from a click on a roof or a basement, as the game's own map does | a spot under a building's second floor |
| G6.7 | That `isInCharacterInventory` is true of the player's main inventory (the container log's test) | take from a crate in a safehouse; the line appears |
| G6.8 | That the `Transactions.scrapMoveable` route is dead: `TransactionProcessor` is local, and nothing in vanilla's Lua sends it, so the wrap is on `ISMoveablesAction` alone | the disassembly menu on furniture in another's safehouse |
| G6.9 | That a car's stamp and key number outlive a restart on a real server (the bytecode says `save` writes both), and that a server that crashes between the two saves costs at most that claim | Before any restart or relog, so the client has no stamp to send back: a client with `RetroDashboardDigital` that had the car in view before the claim reads `getModData().ZeDClaim` as nil, drives the claimed car, gets out, and waits ten seconds. The owner still holds it, no "claim gone" line. A relog then reads `retroDashOdometer` and `ZeDClaim` both on the car: the server took the client's table, wiped its own, and put the stamp back. With Locksmith, a re-pin from outside: still held. Then claim a car, `/save`, restart: "taken", and the owner still holds it |
| G6.10 | That siphoning with the `animEvent` wrap leaves the tank and the can as they were, and the bar ends cleanly | bob siphons a claimed car past the gray; the tank's level before and after |
| G6.11 | That `shutOff` during `Starting` (right after `vehicle.startEngine`) leaves the engine off on every client | send the command from a blocked driver's client |
| G6.12 | The Vehicle tab under the controller, which no sim loads: Claim going from gray to lit, Claim to Release, a gray Claim's reason in the help band and on A, Keep and B landing on Release | walk the footer with the pad |

# Build's changes (Nov 6 2026, Phase 4: logs and accountability)

Files: `ZeD_LogProto.lua` (shared, `ZeD.Lg`), `ZeD_ServerLog.lua` (server), `ZeD_Log.lua` (the model, `ZeD.Logs`), `ZeD_LogCards.lua` (the card). Module `ZeDL`; answers
come back on the tickets' `t_ack`. `log_sim.lua`, `log_cards_sim.lua`, `mp_log.lua`, `mp_log_cards.lua`. Where the build differs from A5, A6, the scope and
`mockups/zed_logs_v1.html`, and why.

1. **Everything is on `Srv.action` now.** Tickets are kind `ticket` (`ticket | filed | Kade_R | #14 | 6280,5350,0 | GRIEF | day 12`: the record's kind in `detail`, never its words).
   The core's lines (refused, bad arguments, rate limit, handler failed, up and off) and the admin clock's are kind `admin`, who `Tk.SYS` (`@server`: the game refuses `@` in a username, `ServerWorldDatabase.isValidUserName`, so no account can pass for it) or the player. The ring holds them, so
   a refused command reads in the Log view. Only a table's own opening, the hook's QA lines and work on a car with no owner write through `Srv.fileLine`.
   `Srv.log` is the writer behind both and nothing else calls it. Existing outside parsers of the old free-text ticket line have to change.
2. **Three rings beside `md.log`.** The game's PvP hits go in `md.pvp` (`PVP_MAX`, 400), other mods' lines in `md.tap` (`TAP_MAX`, 300) and work on a car nobody has on record in `md.world` (`VEH_MAX`, 1000), all in the same secret table. A fight fills a
   10-hit buffer every few seconds and any client can write a tapped line, so neither may push out ZeD's evidence. All three share the order `s`. Scavenging world cars would otherwise fill the 2000-line ring in hours; `md.world` lines still read under Vehicle and in Around, and reach the file. Hits and tapped lines are not
   written to the ZeD log: they are already in the game's `pvp` file and the mod's own. Kills are ZeD's own lines (kind `pvp`) and are in the ZeD log.
3. **E2 reads settled in the bytecode; the probe stays.** `NetTimedAction.parse` runs `<Type>.new` by name with the class first. `perform` takes `complete` with
   `KahluaTable.rawget`, and `KahluaTableImpl.rawget` does not stop at the table: a key it lacks goes to the metatable's `rawget`, and so up the classes. So the class wrap is what
   runs, and it is what ships. `.new` is wrapped too, to count. `serverStop` goes the same road, and every class gets one (the game calls it if it finds one), so a cancelled action proves the road as well. A class that makes `HOOK_MISS` (3) actions with neither reached, `HOOK_WAIT_S` (2 minutes) after the first, turns the fallback on
   by itself, with one line in the ZeD log: each new action of exactly that class carries the wrap as its own `complete`, while the class's own is still ZeD's, so a mod that wrapped or replaced `complete` later, or a subclass with its own, stays in the chain.
   `.new` must be wrapped on the server only: `NetTimedAction.set` on the client reads the closure's parameter names.
4. **The game's PvP log has no weapon and no usable time.** `PVPEvent` keeps wielder, target and place; `getText` gives `[dd-MM-yy HH:mm:ss.SSS] "a" hit "b"`, and its fields aren't reachable
   as methods. It holds the last ten hits. So `PVPLogTool.getEvents` is read every `POLL_S`, a line takes the time it was read (at most 10 seconds late), and more than ten hits between
   two reads are lost. The drawing's "with a Baseball Bat" comes from `OnWeaponHitCharacter`, read beside it and lost if it does not fire on the server; the line then just says "hit Mags_77".
   Reading needs `PVPLogTool`, the game's own test. The drawing's "a Baseball Bat" reads "with Baseball Bat": the article can't be chosen for every item name.
5. **Kills come from `OnCharacterDeath`,** which `IsoGameCharacter.DoDeath` fires just before it reads `getAttackedBy` for the game's own kill line. Animals are left out. The kill line in the
   game's `pvp` file is not read: `logKill` keeps nothing in `events`.
6. **Other mods' lines.** The global `writeLog` is wrapped; A5's first path needs nothing more, since `ISLogSystem.writeLog` looks the global up. `Srv.tapBy` carries who sent a line through
   `ISLogSystem`, so a line claiming to be someone else's reads "from the log X, sent by griefer, not proved". The ZeD log's name stays closed, in any case and punctuation. The game's own `ClientActionLog` and `PerkLog` are left out of the view: they are its chatter, two lines a car trip, and they open with the Steam ID. A line is cut to `2 * TAP_TEXT` and read with plain finds in one pass, since any client can send one and it runs on the main loop. What is kept is what follows the place, with no leading digits, so a place lives in `x`, `y`, `z` alone, a Steam ID goes nowhere, and a place past the map is no place. Go there is gray on these lines with why: one press must not take staff to a spot a griefer chose. The Who list takes a tapped line's proved sender, never the name it claims. `TAP_PER_MIN` per
   sender limits what is kept; the game's file gets every line regardless. A logger named `pvp` shows under the PvP chip with its own source, never as the game's. A logger that fits no chip
   shows as Other under All: the drawing has no such chip.
7. **One reading of the codes, three readers.** A row holds `what`, `target`, `text` and the vehicle's `car`, `part` and `locked`; `Lg.lineWords` (`ZeD_LogProto.lua`) reads them, through the viewer's language on the card and through `Lg.EN`, the EN file's words held to it by `log_sim.lua`, on the server. So Find looks through what the card
   shows as well as the codes, and a note says what the line says. A code with no words reads as the server wrote it, which is how a later ZeD's lines and the server's own reports show, after "Server:". A client in another language sends the codes its words came to with the Find (`Lg.findCodes`); a car's name in another language stays out of reach. Nothing in the file changes for outside tools.
8. **A place name is coordinates.** E3 is still open, so no line says "Riverside farm". The car's name is the game's `IGUI_VehicleName`, the part's `IGUI_VehiclePart`.
9. **The owner is the last driver,** as A6 says, and a claimed car's is the claimer (the section after this one). The name moves only on a running engine and settles slowly. `ISStartVehicleEngine.complete` answers true for a key that did nothing, so a start or a hotwire moves it only if `isEngineRunning`; otherwise the 10 second look does. A new driver holds the car for `SETTLE_S` (a day) before it counts as theirs (`prev` and `at` on the record): until then a thief's strip job writes lines naming
   the owner, and the owner taking it back writes no line. A first driver has no one before them: the name is theirs, but their own work on it still writes, as a car with no owner. `Lg.OWN_CAR_LINES` is false, so a settled car of your own writes no lines. "Drove off" is never dropped by the pace; a car with no record first taken writes one. The drawing's "parked and locked his Chevalier D6" is not built: getting out and locking
   have no server event. Two friends sharing a car write a "drove off" line when the wheel changes hands, and none coming back. A line waits for `sqlId` to be 0 or more; a car with none has no owner. Frozen, the record is a copy in memory, and the file still gets its lines. A siphon stopped early has moved fuel with no `complete`, so `serverStop` compares the tank. Past `VEH_PER_MIN` a player's other lines are dropped, with one "not kept" line for the minute. Kills are the last of an account's lines to go at its share.
10. **Who reads it.** `Lg.VIEW_CAP` is `AnswerTickets`. The Log's row is under Tickets at the top of the tab, since the drawing doesn't place it. A role above yours keeps its place out of your view, as on the Player card: the
    line stays, its place goes, Around and Find can't reach it, and a note added from it has none either. A fight's place counts for both people in it. An IP address or Steam ID on a ban line needs `BanUnbanUser`, as the Bans card does: without it the line reads "a hidden address", and Find, Who and a note can't reach the value. The ring and the file keep it. Go there says which: a place held back, or none on record.
11. **Today is the UTC date,** as every date on these cards is until E5 is settled, and the card's last line says "Times are UTC".
12. **Around ticket.** The server finds the ticket's place and time itself, from the number. Who the nearby list missed is a line in the band, not the help band as drawn: with a controller the help band holds the prompts. It names up to three: anyone with an admin, vehicle or PvP line there up to the filing (a ticket's line has the ticket's place and a safehouse's the house's, so they say nothing of who stood there), not a tapped line, not the author, not on the list. "missed him" reads "missed them". Add to ticket is on every line, not only vehicle lines as drawn: a PvP hit at the scene answers a griefing ticket too. Its note is written by the
    server, in the card's English words, with the line's time and place and, on a tapped line, who sent it; the same line can't go on twice. A game row taken in is the server's line, with the author in its detail and "not proved" in its words: that name came through a staff client.
13. **Parts of the card.** `lfilt` and `lfind` are the list's filter items without their fill, so the label sits at the left as drawn. The count sits on the back bar through `flag`. The name is struck twice, since the fonts have no bold.
    A name on a card button is cut to 16 characters. Clear sits under the band's words, not beside them: there is no room at Deck. `Y Filters` is not built, as on the Tickets card. Pages are new: the drawing has 16 lines. The first page reads itself again every 10 seconds; a later page stays put.
14. **Without the server part** the row reads "The game's PvP log" and opens that window; gray with the capability's reason if the role lacks it.
15. **The ticket queue's line.** `gameCall` marks `getTickets(nil)` as `full`. No answer in `REPLY_MS` raises `C.gameSilent`, and a line in the queue; an answer clears it. Nothing asks again on its account.

**Container.** `ISInventoryTransferAction` is a client file and the transfer is Java (`ItemTransactionPacket`), so server Lua has no hook and no event for a take. The only route is the taker's own client reporting it, which a modified client can skip. Phase 6 built that route and owns the setting and the player's notice. The chip and the lines are joined in the next section.

**A tow** is noted only with both cars within `TOW_REACH` of the sender, at `TOW_PER_MIN`, since the game limits nothing and only warns about distance. It sends the command as the action starts and takes it back on a cancel, so the line waits for the next look to see `getVehicleTowedBy`, up to 20 seconds late. It reads both cars, the menu can put either first, and names the one that isn't the sender's; one line a pair in `TOW_REPEAT_S`. Faction lines take the place of the person named while they are on.

**Director's questions, each answered the careful way behind one switch in `ZeD_LogProto.lua`:** `VIEW_CAP` (who reads the log), `OWN_CAR_LINES` (your own car), `SETTLE_S` (how long before a new driver's car is theirs). `LOG_MAX` stays 2000 lines; a busy server may want more, and it is `Adm.L.LOG_MAX`.

Not settled, for QA on the local server (`mp_log.lua` prints these as PROBE and TODO lines):

| # | Unknown | How it settles |
|---|---|---|
| E2 | The class wrap reaching `complete` on a real server, though the bytecode says so | PROBE E2: `done` 1 with no fallback. Otherwise three smashes turn the fallback on, and the next line lands |
| E1 | Whether Log Extender writes through either path. Still not on this machine | Subscribe it on the QA rig; its lines show as Other or under their logger's chip |
| G4.1 | That `OnCharacterDeath` fires on the server for a player, with `getAttackedBy` set. The bytecode reads so; `IsoPlayer.OnDeath`'s other event, `OnPlayerDeath`, is for local players only | Two clients, PvP on: a `pvp \| kill` line |
| G4.2 | That `isEngineRunning` reads true on the server for a car being driven, and that `getVehicleTowedBy` does after a hitch. The bytecode reads so (`VehicleEngine.isRunning`; `addPointConstraint` calls `setVehicleTowedBy` on the server) | Two clients: a "drove off" line, and a tow's line from the game's menu |
| G4.3 | That `serverStop` reaches a siphon stopped early, as `complete` reaches a finished one | Cancel a siphon part way: a "siphoned" line, and `stopped` on the probe |
| G4.4 | The car's name in a note and in Find: `getTextOrNull` on a dedicated server | Add to ticket on a vehicle line: the game's name, or the script name if the server has no words |
| G4.5 | That `OnWeaponHitCharacter` fires on the server, from `Hit.process`. Without it lines have no weapon, nothing else changes | PROBE weapons rises with a hit |
| G4.6 | That `PVPLogTool.getEvents` holds the hits on a dedicated server and that `getX` reads through the exposer: the class and `PVPEvent` are both exposed, vanilla calls it only on a client | Two clients, PvP on: a hit reads in the view |
| G4.7 | That replacing the global `writeLog` holds under `ISLogSystem` on a real server | PASS "the tap took a client's line" |
| G4.8 | What `getSqlId` holds on a car spawned this session. Below 0 means no owner is kept | PROBE car |
| G4.9 | Whether a tow reaches `vehicle.attachTrailer` as read, from the game's menu | TODO: a "hooked up" line |

# Build's changes (Nov 6 2026, Phases 4 and 6 joined)

The two phases were built side by side on one base, each without the other. What the join settled. `log_sim.lua`'s last sections run `ZeD_ServerExtras.lua` beside `ZeD_ServerLog.lua`, on the same classes, in the game's load order, which nothing had done.

1. **The wraps' order.** The Log wraps its seven classes as its file loads. The extras wrap when a system is first on, which is `OnInitGlobalModData` at the earliest, after every file has loaded. So on a class both wrap, the extras' wrap is the outer one, always. Refused, it answers false and the Log's wrap never runs: the action's one line is `refused: parts`, `refused: drive` and so on, never "removed" or "hotwired". Not refused, it calls the Log's wrap, and the action's one line is the Log's. The other order would work too, since the Log writes nothing when `complete` answers false.
2. **A refusal proves the road.** A refused action reaches no wrap of the Log's, so three refusals in a row looked like E2 failing and would have turned the fallback on. `Srv.L.refused` counts them (`ref`, on `l_probe` and PROBE E2), and the fallback waits for that too.
3. **The fallback carries the whole chain.** `Lo.made` used to shadow the class with the Log's wrap only, and only while the class held exactly that, so with the extras' wrap on top it shadowed nothing. Now `Srv.exTop` holds each extras wrap as it stands, an action carries whichever of the two is on top, and a siphon's `animEvent` goes on with it. **What this doesn't cover, plainly:** in the world the fallback exists for, where a class wrap isn't reached at all, a refusal on those classes starts only once the fallback is on (the third action, two minutes after the first; that action is refused). An action already made when a system is turned on keeps what it carried and finishes. And `ISDismantleAction`, `ISMoveablesAction`, `ISUnbarricadeAction` and `ISDestroyStuffAction` have no `.new` wrap and no fallback: in that world Safehouse protection's timed actions refuse nothing. Both phases read the bytecode the same way (E2), so this is the case QA's E2 and G6.1 rule out, not one expected.
4. **Off still means off.** `Srv.exOwner`, `Srv.exDriveStops` and `Srv.exTowStops` test one boolean before they look at a car. With every extra off nothing is wrapped, and `log_sim.lua` calls them with a stub that errors on any touch. `extras_sim.lua`'s proof runs unchanged.
5. **Whose car.** A claimed car's owner is the claimer: `carFacts` asks `Srv.exOwner` first, a claim counts as settled, and the last-driver record answers for every other car. So the claimer's own work writes no lines, taking the wheel writes no "drove off", and a window smashed on a claimed car names the claimer whoever drove it last. A claim that goes (released, lapsed, burnt, or claims off) hands the car back to the record. A wreck's claim goes when anything reads the car, so a line for stripping one names the last driver.
6. **A driver a claim stops is no driver.** The Log's 10 second look can land in the 2 seconds before the clock shuts a stopped driver's engine off. It now skips them, so no "drove off" and no move of the record, and the refusal is the line. With Drive it unticked nothing is stopped, and the line names the claimer.
7. **One tow, one line.** Both listeners stay, the game's handler running first. A tow a claim stops is taken straight off by the extras' listener, which writes `refused: tow`. The Log's listener asks `Srv.exTowStops` and doesn't note it, so no "hooked up" can follow whatever `getVehicleTowedBy` then reads (`breakConstraint` clears it on both cars). A tow a claim lets by, or with Towing unticked, is the Log's one line, naming the claimer. Refusals are paced per sort, not per player, or a tow refused just after a part would have left no line at all.
8. **The Container chip and its lines are one.** `Lg.CONTAINER_LOG`, `Lg.containerOn` and `Lg.containerWriter` are gone. `l_query` sends `opt` from `Srv.exContainerLog`, which reads the server's Container log setting, so the chip shows with it on. With it off, lines already kept stay under All, and a chip in use stays until it is left, so a setting turned off can't strand the filter. `WHAT.container` reads `took`: the file's detail ends "(reported by their game)", and the words on the card, in a note and in Find say the same in the viewer's language (`UI_ZeD_Log_Took`). A container line counts for nobody on Around's list, since it is a client's word. Go there stays lit on these lines, unlike a tapped line's: the server has tested that the place is inside a safehouse and near the player, so a griefer can't choose it freely.
9. **Words for Phase 6's lines.** A code with no words reads as the server wrote it, which is how `refused: tow` would have read. `Lg.CLAIM` and `Lg.HOUSE_NO` hold them, and Phase 6's lines carry the car through `ex`, so "Rosa was refused towing Kade_R's Chevalier D6" reads like any other line. `claim` and `release` are words for a safehouse and for a car: the kind picks which, and a Find in another language reaches both. Lines that carry a car's place with its owner anywhere (a release, a lapse, a claim gone) are `Lg.NOT_THERE`, so they put nobody on Around's list. A line's car is the game's `getCarModelName`, then `getName`, on both sides, as vanilla's own windows read it.
10. **One writer.** Phase 4 made `Srv.action` the one log, with `Srv.fileLine` for what the ring can't hold, and Phase 6 was still calling `Srv.log` with free text. Its lines now have the seven fields too. Those at load and at a table's opening go through `Srv.fileLine`, since nothing may open the admin table before the game has loaded it.
11. **`Srv.action`'s arguments agree everywhere:** `kind, who, what, target, detail, x, y, z, ex`, checked at every call in the server files. Phase 6 only changed `ZeD_ServerAdmin.lua`'s ring; `ZeD_ServerCore.lua` is Phase 4's alone, plus comments here. The ring keeps both phases' rules: a kill goes last, and a player's reports hold their own smaller share and replace only each other.
12. **Numbering.** Phase 4's and Phase 6's tables each ran from G1, and Phase 4's used G3, G4 and G5 twice. Each row now says its phase: G4.1 to G4.9, G5.1 to G5.9, G6.1 to G6.12, numbered down each table. No QA script prints them; `mp_log.lua` prints E1 and E2.

Not settled, for QA on the local server:

| # | Unknown | How it settles |
|---|---|---|
| H1 | That on a real server the extras' wrap is outside the Log's and one refused action writes one line. The load order and the bytecode say so; only `log_sim.lua` has run it | bob's uninstall past the gray with Parts on: "was refused taking parts" in the Log view, no "removed the", PROBE E2's `refused` up by one |
| H2 | That a tow refused on two clients leaves no "hooked up" line (G6.3 for the cars themselves) | hitch a claimed car with Towing on: one "was refused towing" line after 20 seconds |
| H3 | A container line from a real take, under the chip, with the words | Container log on, take from a crate in a safehouse: the chip, the line, and the same line after Add to ticket |

# Build's changes (Nov 6 2026, Phase 5: community)

Files: `ZeD_CommunityProto.lua` (shared, `ZeD.Cm`), `ZeD_ServerCommunity.lua` (server), `ZeD_Community.lua` (the model), `ZeD_CommunityCards.lua` (the cards, the
join window, the leaving screens). `community_sim.lua`, `community_cards_sim.lua`, `mp_community.lua`, `mp_community_cards.lua`. Module `ZeDM`; every answer comes back as
`t_ack`. The table is `ZeD_CM_` plus a UUID, as B2. The view goes out with the hello (`r.cm`) and again as `m_view` at every change. Where it differs from the drawing or the
scope, and why.

1. **The screen asks once in a connection, on the hello.** Nobody is asked mid-play: a rule changed while you are on waits for your next join, a respawn is not a join. The
   drawing's Saved line says the same.
2. **A rule changed or added asks again; a rule moved or taken away does not** (`Cm.ASK_ON_REMOVE`). Each rule keeps the revision it last changed at, `md.rev` is the highest,
   and a player who agreed at less is asked, with the rules past their revision marked NEW. The message of the day and the appeal line never ask again. "Changed Nov 5" moves
   for any change to the list. With no rules the tick does not hold: there is nothing to agree to.
3. **I agree closes the screen at once and tells the server after.** Nothing waits on an answer, so no server can hold anyone there. A lost answer means being asked again next
   join. Agreeing is to the words on screen: the window keeps the view it opened with, and a push while reading changes nothing. A frozen table asks nobody, because it could
   not keep the answer.
4. **Enforced by the client, as the timed ban is.** (Superseded Nov 7 2026: until a player agrees every ZeD command is refused,
   and five minutes unanswered owes a Kick; see "Rules that hold".) Server Lua cannot remove a player (A7). A modified client can skip the screen; the agreement is a record of what a client
   said. It is a line in the ZeD log, not in `md.log`: agreements would crowd out the ring on a busy server, and only a player who is being asked writes one. As the ban has its stay
   note, a player asked at joining and still on with no answer after `Cm.L.ASKED_MS` gets one `Srv.action` line, "rules not answered", so a skipped screen is seen though it cannot be
   stopped. Leave is not recorded: the player is simply gone. Every edit is `Srv.action("community", ...)`, so Phase 4's Log needs a word for that kind when the two meet. A post
   pushed off the board is logged with its words, and acts on a report from chat go through `Srv.action("ticket", ...)` for the same reason.
5. **The join screen holds the keys, not the character.** `doKeyPress(false)` stops the game's key events; only a focused text box stops `GameKeyboard.isKeyDown`, so WASD still
   walks behind the cover. The pad's focus is the window's, so a pad does not walk. The world runs on: a player reading on a hot spawn can be bitten, and Lua has nothing to
   stop that. The cover is 0.94 opaque.
6. **The join window is not a Focus Manager window, and the manager knows it is up.** The manager polls Y past engine focus and opens the pair on the first pad press, so while the
   window stands `Focus.held()` stops Y, `claimFocus` and `ensureBothOpenForGamepad`. The window also takes the pad back in its own `update` from anything else (a death's panel, a pad
   that arrives after it opened), and hands it back at the end. Up and Down scroll, Left and Right pick, A presses, B answers nothing, and focus never leaves the two buttons, so
   reading never loses the button. It lands on I agree. No close box: closing would have to mean something. It is the same card as the rest, on the ticket frame, through two small
   hooks: `K.noBack`, and `win._padId` for a window with its own pad, in `D.focusOf`.
7. **Nothing can trap a player.** It goes up only on a view that says so. The window is built before the cover, so a build that fails leaves nothing up. A failed draw closes it
   (`ZeD.Safe.guard`), as does safe mode (piece `community`), a ban, and the connection ending. `ISServerDisconnectUI_OnServerDisconnectUI` is wrapped for that last one, or the cover would stand over the game's Exit and Quit. The same wrap clears `Admin.leave`, which
   closes the ban screen for the same reason.
8. **The appeal line reaches a removed player three ways.** On the ban screen with the reason, from the server (`leaveView`, since their client may never have heard it). Under the
   game's own words on a kick: the game draws the reason in Java on its disconnect screen, so ZeD adds one line under it, for a removal only (`M.isRemoved`, the game's own keys). On
   ZeD's connect screen when a banned login is refused, from `Lua/ZeD_appeal.txt`, kept per server (A7: they cannot log in to ask). Always `drawText`, never a link.
9. **Two capabilities, not one** (`Cm.CAP_RULES`, `Cm.CAP_NEWS`). The game has none for this. Rules, message, appeal and the ticks need `ChangeAndReloadServerOptions`, the one that
   changes the server's welcome message; moderators lack it. News needs `DisplayServerMessage`, as the drawing's post by Rosa has it. Each half of the card grays with its reason.
   `Adm.RANK_GUARD` covers news as it covers acts on people: a post keeps its writer's rank, and a lower role can't pin or delete it.
10. **Save is stopped on an older copy.** `base` counts the saves; a Save from before someone else's answers `stale`, the foot names who, and a second press replaces it. A card nobody
    has typed in takes their words at once. The whole board is pushed at most once in `Cm.L.PUSH_MS`, and whoever pressed gets it at once.
11. **A report's chat is the reporter's word.** Server Lua cannot reach `ChatServer`, so the server hears none of it. `rec.report` is kept on the ticket (name, up to 11 lines, each cut to
    300), counted in `md.chars`, shown to staff and the reporter with that said on the card, and never put in the game's ticket, which is public. The kind starts at Griefing with
    Include where I am ticked, the card's own rule for that kind; the player can change both. The words are still the player's to write. A staff member a report names can't answer,
    close, or mark it spam (`named`); an admin can. A forged name stops one person handling one ticket, no more.
12. **Without the server part** chat still picks: Mute and an admin's two need nothing from it, and Report opens the game's fallback card with "About mike_d: " typed, and no chat. The
    same goes for a frozen ticket table and a server part from before this phase. Rules, news and the join screen do not exist there. Mute covers ZeD's window on this computer; the words over a head are the game's.
13. **The fields.** A rule's box wraps and grows, where the drawing has one line: a one-line box cannot show a rule of 200 characters at Deck width. Enter makes a line break and Save
    flattens it. Up, Down and Remove are icon buttons with ZeD's own triangles and cross (the fonts have neither), and move under the field when they will not fit beside it. They take
    effect on Save, as drawn. A field not yet scrolled to has no box, so the card reads its seed until it does.
14. **Small changes from the drawing.** The foot's "Not saved yet." alone, since the band cut the rest; the sentence is in Save's help. Delete asks in the foot (`Cm.DELETE_ASKS`): it sits
    beside Pin and a post is public. PINNED sits in its own column, not inline. Pin it to the top starts unticked (the drawing's sample has it ticked, and everything would pin). The Server
    block keeps Online and Your role after the message and The rules row. News and The rules row go when there is nothing in them. A long list of new rules goes on the line over the
    band and reads "3 rules are new". Your own lines and server lines cannot be picked: nothing to do about them. On the pad a picked line's buttons are walked with Left and Right.
15. **The director's questions, each answered the careful way behind one switch in `ZeD_CommunityProto.lua`:** `CAP_RULES`, `CAP_NEWS`, `ASK_ON_REMOVE = false`, `DELETE_ASKS = true`, and
    `Tk.REPORT_AROUND = 5` in `ZeD_TicketProto.lua`, where the server's limit is worked out from it. Staff are asked like everyone: "everyone" is the tick's word.

Not settled, for QA on the local server (`mp_community.lua` prints these as PROBE and TODO lines):

| # | Unknown | How it settles |
|---|---|---|
| G5.1 | That `doKeyPress(false)` stops I, T and Esc while the screen is up, read from `GameKeyboard.update` only | Press them with the screen up |
| G5.2 | When the hello lands against the game's "click to start" and a new character's screens. The screen waits for `getPlayer()`; `UIManager` must be drawing | Join with a new account, and with a saved one |
| G5.3 | That `getServerIP` in game is the string `server:getIp` gives the connect screen. `GameClient.ip` is set from the connect call, as far as the bytecode goes. If they differ a banned player sees no line | PROBE prints the key; compare it with the file after a ban |
| G5.4 | That a panel added from the wrapped `ISServerDisconnectUI_OnServerDisconnectUI` draws in `ServerDisconnectState`, whose `ResetCallbacks` has just run. `UIManager.render` is called there | A kick on a second client |
| G5.5 | That `LuaManager.call` finds the wrapped global. The name is looked up in the Lua environment at the call | The same kick |
| G5.6 | `getAuthor` on a chat line: the username or a display name. Mute, Report, Player card and Teleport all take it as the username | A second client, with a name set apart from the username if the server allows it |
| G5.7 | What `getDatetimeStr` holds. A report's time is cut to 16 characters | Read a report's lines on the local server |
| G5.8 | That `OnGameStart` runs before the hello's answer on a fresh join, or the first answer would be read as a repeat. Harmless the other way | The join screen shows on the first join of a connection |
| G5.9 | E5 again: the dates read in the viewer's zone or UTC. A post's short date carries no UTC word | Compare a post's date near midnight |

# Build's changes (Nov 6 2026, Phases 4, 5 and 6 joined)

Phase 5 was built on the same base as the other two, and met them here. What the join settled. The last sections of `log_sim.lua` and `log_cards_sim.lua` run community's lines through the Log's server side and its card, and the last of `community_cards_sim.lua` holds both tabs' order, the home key, and a report with Around.

1. **The Log's word for community.** `Lg.KINDS` holds `community`, so a chip reads it and `l_query` accepts it; the chip always shows, ahead of Container, which is the one that comes and goes. The tag says COMMUNITY in plain text color (`Lm.kindColor`): the status colors are all spoken for, and the word carries the kind, never the color. `Lg.COMMUNITY` holds the codes and `WHAT.community` their words, in the viewer's language on the card and in `Lg.EN` for Find and notes. A post's words go on one line in quotes. A code with no words reads as the server wrote it.
2. **A report's lines have words too.** `logReport` writes `report answered`, `closed`, `marked spam` and `deleted` under the Ticket kind. `Lg.REPORT` reads them, the reported player is the line's target, so Who finds them, and a picked line offers that player's card.
3. **Around.** A community line's place is where the writer stood, or the one asked to agree, so it is in `PROVES_PLACE` and can put them on Around's list. A report is a ticket like any other: Ask the admins starts with Include where I am ticked, and the staff card holds the Reported row, then the Log row. Unticked, the Log row is gray with its reason, as on any ticket with no place. The Reported row's Player card and the Log row are stops of their own, and Add to ticket stays open to staff a report names: a note handles nothing.
4. **The Admin tab's order.** Tickets, Log, Players, Admin powers, Server message, Roles, Bans, Spawn items, Rules and news, Server extras, Safehouses, Factions, More tools. The admin tools drawing has Tickets through Spawn items and More tools. `zed_community_v1.html` lists Rules and news before Server extras. No drawing places the Log's row: it stays under Tickets, which it answers. The home key holds all three parts' state: `ZeD.Logs.live()`, `AC.homeKey`, `AC.extrasKey`.
5. **The Server tab's order.** Server (with the message and The rules), invitations, News, This server's extras with Your claims, Tickets, Faction, Safehouse, Wars, PvP, Players. Each is flat items in the tab's one list: no block holds a scroll of its own. The cards that open from them scroll as one card.
6. **The hello.** `S.lg` and `S.cm` both land, and each module reads its own part of the same reply. `Srv.helloAdds` are separate, so a part that stayed off at load simply leaves its key out, and each client surface stands on its own test. One slip fixed: `E.onHello` kept the last server's extras when a hello came with none. It now drops them, as `M.onHello` does.
7. **One writer, again.** Phase 5 was built before Phase 4's seven fields, and called `Srv.log` with free text. Those lines now go through `Srv.fileLine`, and the agreement, which stays out of the ring on purpose, reads `community | agreed to the rules | Aretha | - | - | revision 3 | day 12`.
8. **`rec.report` is counted.** `reportSize` goes on `md.chars` at `t_new`, `playerRoom` asks for it first, and `textOf` takes it off with the ticket, so the room check, the eviction and the delete all agree. Phase 4 changed none of that.

Not settled, for QA on the local server:

| # | Unknown | How it settles |
|---|---|---|
| H4 | A real report through to Around | Report a line in chat with Include where I am ticked; on the staff card, the Reported row, the Log row, and a line of the card's with Add to ticket |
| H5 | Community's lines on the Log card with a real server's words: nine chips wrapping at Deck width and at Large text | Save the rules, post, pin, delete; the Community chip; each line's words |

# Build's changes (Nov 7 2026, rules that hold)

The director's decisions of Nov 7 2026 (multiple choice), built. Files: `ZeD_ServerCore.lua` (the gates), `ZeD_ServerAdmin.lua`,
`ZeD_ServerCommunity.lua`, the new `ZeD_ServerHelper.lua`, `ZeD_AdminProto.lua` and `ZeD_CommunityProto.lua` (limits), `ZeD_Admin.lua`
(an empty reason), `ZeD_CommunityCards.lua` (the plain question in safe mode), `sandbox-options.txt` (`ZeD.HostHelper`), and
`ZeDUI/server_helper/`. Sims: `admin_sim.lua`, `community_sim.lua`, `community_cards_sim.lua`; the helper's own test is
`ZeDUI/server_helper/test_zed_rcon_helper.py`.

**Settled facts this rests on** (bytecode, 42.22.2): server Lua cannot kick, ban, unban or set one player's role. `GameServer`,
`ServerWorldDatabase` and `UdpConnection` are not exposed, and the `GlobalObject` admin calls only act on a client. The game's own
ban is enforced by the server at login (`ServerWorldDatabase.authClient`). `deletePlayerFromDatabase` and
`checkPlayerExistsInDatabase` are never called (they delete an account and its character), and `IsoPlayer:setRole` is never used
from server Lua (it changes the player object's field, not the connection's role the game checks).

1. **Every ban is the game's ban too.** A timed ban owes the game's ban at once: the name, plus `BanSteamID` when the server has a
   checked Steam ID, plus the IP while the player is on (as a permanent ban does, under `TIMED_IP`). Online, it waits `LEAVE_S`
   so the reason shows first; the game's ban kicks them, so no Kick goes with it. At the end the row goes and the unban is owed
   (`UnBan`, and `UnBanSteamID` when the row has a Steam ID: lifting one without the other would leave every account on that Steam
   ID out). It goes to the next staff client or the host helper, so **a timed ban may run past its time while nobody can lift it,
   never short.** ZeD's row stays the record (reason, end, who), still shows the leave screen with the time left and has
   `gameBan` set, so Use the game's ban no longer shows on the Bans card. An unban of a permanent ban with a Steam ID now lifts
   both halves too (it lifted only the name before).
2. **A standing ban shuts its holder out of everything.** `Srv.gates` (`ZeD_ServerCore.lua`) run before any command's own power,
   for every module: tickets, claims, community, extras, log, dash, admin. The ban gate refuses all of them but the hello and
   `a_hi`, so the client still hears why. A refusal answers `perm` and writes one line a minute ("refused", "under a ban: ...").
   A row stands whatever the game holds: a permanent ban the game made should have kept the player from logging in, so one found
   on the server did not take. The admin part asks the gates before it hands anyone a game call (`mayCall`).
3. **A stay owes a Kick, on every stay.** When a banned client is still on `STAY_S` after being told, the server reports it as
   before and owes a Kick (once while one waits), on every connection and again each `STAY_EVERY_S`.
4. **Steam IDs match on the server's own number.** `standingFor` compares the row's Steam ID with `p:getSteamID()` as numbers
   (`tonumber(b.sid) == real`), whatever the client claims or leaves out. A Lua number holds a Steam ID to about 16, so a ban on one
   ID also matches the few IDs that share its double; staff see that as a ban on the player it finds. The exact string is still
   the one `a_hi` checked, and it is only what the game's `BanSteamID` call is given.
5. **A client's "done" is not proof.** `a_done` (and the helper's "ok") only says the call went without an error. After it:
   - a `BanSteamID` is read back from the game's own table: `NetworkUser.new():isSteamIdBanned(sid)` (an exposed class; the method
     is a read-only `SELECT steamid FROM bannedid` on `ServerWorldDatabase.instance`, one overload taking a String, the ID back or
     null). Not on the list: asked for again.
   - a name ban has no read-only lookup in reach (`getFirstBannedIPForUser` is the IP's), so the proof is that the player is gone:
     found on past `VERIFY_S` with the row made, the ban is asked for again.
   - a Kick: still on past `VERIFY_S` while its reason holds (the row binds or the rules are still unanswered), asked for again.
   Each is asked again `REOWE_MAX` (3) times with a log line ("game ban did not take", "kick did not take"), then one line says
   so. The row still keeps them out (the leave screen, a Kick on a stay). **A ban lifted in the game's own window but left on
   ZeD's Bans card is put back** by this: the Bans card is the record, and Unban there lifts both.
6. **The join rules hold.** Until a player asked at joining agrees, every ZeD command from them is refused (the rules gate); only
   the hello, `a_hi`, `m_get` and `m_agree` stay open. The record of who was asked is made at the first word from them (the hello or
   any command) or at the server's own walk of the players online (`lookAtAsked`, every `ASKED_LOOK_MS`), so a client that never
   says hello is caught all the same. After `ASKED_MS` (5 minutes) unanswered: one line, and a Kick owed with no reason (the
   game's own words; an empty quoted reason makes the game refuse the whole command line, so `ZeD_Admin.lua` leaves `-r` off). A
   Kick still waiting when they agree is dropped ("the rules were answered"). A role the game will not kick
   (`CantBeKickedByUser`) is only written down. Nobody is asked mid-play, as before. A split-screen guest (a second to fourth
  player on one connection, `getPlayerNum() > 0`; the server sets it from the connect packet in `GameServer.receivePlayerConnect`)
  gets no record: ZeD's client speaks only for its first player, so a guest could never answer, and the game's kick by name
  (`KickUserCommand`) drops the whole connection with `forceDisconnect`, the first player with it. The first player's answer
  stands for the screen. A modified client can still send `m_agree`
   without showing the screen: the agreement is the server's record of what a client said, and nothing on the server can tell.
7. **Safe mode asks too.** Safe mode used to skip the join screen, which with the gate would leave an unmodified client refused and
   kicked. It now asks the same question in the game's own yes/no box (`ISModalDialog`): the rules as plain lines of at most 70
   characters, then `UI_ZeD_Cm_SafeAsk`. Yes agrees to those words, No leaves. Turning safe mode on with the screen up asks it there.
8. **Mutes stay client-kept.** The server cannot reach the game's chat (`ChatServer` is not exposed, and `IsoPlayer.setAllChatMuted`
   is read by nothing in the chat path). ZeD's mute is the server's list, kept by each player's ZeD chat; a modified client, or the
   game's own chat box under safe mode, is not stopped, and the words over a player's head are the game's. The voice mute is the
   game's own (`/voiceban`).

**The host helper** (optional, off by default; the sandbox option `ZeD.HostHelper`, "Host Helper (RCON)" on the ZeD-GUI page).
A small program the server's owner runs on the server machine (`ZeDUI/server_helper/zed_rcon_helper.py`, Python 3 standard library
only). It talks to the game's own remote console and makes the owed calls itself, so the rules hold with no staff online.

- **The game's console, from the bytecode.** `GameServer.startServer` starts `RCONServer` when the server's settings have `RCONPort`
  and `RCONPassword`; with the Java property `rconlo` set (`-Drconlo=true`) it binds 127.0.0.1, otherwise every address (or
  `-ip`). Source RCON over TCP, little-endian: login is type 3, answered by an empty type 0 and then type 2 with the id, or -1 for
  a wrong password (the connection then closes); a command is type 2, its answer type 0 with the same id, cut at 4086 bytes a
  packet. A packet under 10 or over 4096 bytes closes the connection. The body is decoded with the platform's default charset, so
  the helper sends ASCII only. A command runs as `GameServer.rcon` then `handleServerCommand(line, null)`: user "admin" with the
  default admin role and no connection, so `BanSystem` acts as "System".
- **The commands** (`zombie.commands.serverCommands`, their `@CommandName` and `@CommandArgs`): `kickuser` (alias `kick`)
  `"(.+)"` or `"(.+)" -r "(.+)"`; `banuser` `"(.+)"` with `-ip` and/or `-r "(.+)"`; `unbanuser "(.+)"`; `banid (.+)` (Steam mode
  only, a valid Steam ID; the reason is not stored by this path); `unbanid (.+)`. Each needs `BanUnbanUser` (kick `KickUser`). The
  line is read by `([^"]\S*|".*?")\s*` with every `"` removed, so a quoted argument can hold spaces but never a quote. Answers:
  "User X kicked.", "User X doesn't exist.", "This user can't be kicked.", "System banned user X", "System unbanned user X",
  "This user can't be banned.", "System banned SteamID X(...", "SteamID X is now unbanned", "Server is not in Steam mode",
  "Expected SteamID but got ...". The kick compares names with `String.equals`, exactly.
- **The files.** Server Lua writes `Zomboid/Lua/ZeD_helper/queue.txt` with `getFileWriter(path, true, false)` (one overload; the
  path is under `LuaManager.getLuaCacheDir()`, the server's own Zomboid folder or its `-cachedir`; txt is an allowed extension) and
  reads `answers.txt` with `getFileReader(path, false)` and `readLine`, every `HELPER_POLL_S`. Queue: `ZEDQ 1 <epoch>`, then
  `id, try, act, target, reason`, tab-separated, every owed call the helper holds, then `ZEDQ end`; rewritten only when it
  changes. The game's writer is not atomic (it truncates the file, then writes it in pieces of about 8 KB), so the helper takes a
  queue only when its last line is `ZEDQ end` with its line break, and only call lines of exactly five fields: a file read
  mid-write is left for the next pass, and a line cut inside a name is never made as a shorter name. Answers:
  `ZEDA 1 <epoch> <unix seconds>`, then `id, try, result, text`, the newest try of each call only; the helper rewrites it every
  pass through a temporary file and `os.replace`. The epoch is a random word made at each server start and never saved
  (`H.epoch`), so a helper never takes another world's numbers, nor the old answers of ids a crash rolled back.
- **Who makes a call.** With the helper on, a call its allow-list takes goes in the queue first. A staff client gets it as well
  in four cases: the helper has not answered in `HELPER_WAIT_S`; it answered "failed" (it gets a new try `HELPER_WAIT_S` later,
  `HELPER_TRIES` (3) tries in all, then the call is staff clients' only); it answered "refused" (off the queue for good); its
  answers file is older than `HELPER_ALIVE_S` (not running). Failures write one line every `HELPER_LOG_S` (a minute) at most, with
  a count of the ones held back, so a console the helper cannot reach never floods the log ring. Either
  answer counts; the call is judged the same way afterwards (item 5). IP calls (`BanIP`, `BanIPOnly`, `UnBanIP`, `UnBanIPOnly`)
  are never the helper's: the game's IP ban needs the player's own connection. Nor a name outside the helper's patterns.
- **Security.** The helper sends nothing but those five commands, built from targets it checks itself: a name of 2 to 32 ASCII
  letters, digits, `_`, `-` or inner spaces, quoted; a Steam ID of 17 digits from 7656119. The server checks the same patterns
  before it queues a call (`H.okTarget`). A reason is the only typed text: the server takes out its tabs and line breaks, the
  helper keeps printable ASCII, turns `"` into `'` and caps it at 200, so it can never close its quotes. Anything else is refused,
  answered "refused" and given to a staff client. The password comes from the server's settings or `ZED_RCON_PASSWORD` and is
  never printed or written. It is the owner's program on the owner's machine. The epoch is not a secret: anything that can
  write `Lua/ZeD_helper/queue.txt` gets those five commands, and that includes any other server-side Lua mod and, on a machine
  where the owner also plays from the same Zomboid folder, client Lua from another server's mods. The README asks for a separate
  `-cachedir` for the server when the helper runs, and one server per Zomboid folder (two servers there share one queue).
- **Where it lives.** In the repository only (`ZeDUI/` is never staged: `stage_workshop.ps1` ships the version folders and
  `common/`, and leaves out `.py` anywhere). Owners download it from the public repository; the README says how, for Windows and
  Linux hosts.

**Enforcement, bans and rules.** From the bytecode; each row is 42.22.2.

| Rule | Path | Held how | Enforced by |
|---|---|---|---|
| A ban (timed or permanent) keeps a player out | the game's ban, made by a staff client or the helper | `ServerWorldDatabase.authClient` refuses the login; `BanSteamID` covers every account on that Steam ID | **server**, once the call lands |
| A timed ban ends | `liftDue` on `OnTickEvenPaused`, then the owed unban | the row goes to the second; the game's ban comes off when a staff client or the helper makes the call | **server** (ZeD); late, never early, with nobody to make the call |
| A banned player still on | the server's walk (`POLL_S`) | told to leave; the game's ban asked for again past `VERIFY_S`; a Kick owed on each stay | **server**, through a staff client or the helper |
| A banned player's ZeD commands | `Srv.gates.ban` in the one listener | refused, every module | **server** |
| A Steam ID ban | `p:getSteamID()` against the row, as numbers | the server's own ID, whatever the client claims (to about 16 IDs) | **server** |
| The game's call took | `isSteamIdBanned` read back; presence past `VERIFY_S` for a name or a Kick | asked again, `REOWE_MAX` times | **server** |
| The join rules: commands before agreeing | `Srv.gates.rules` | refused, every module but hello, `a_hi`, `m_get`, `m_agree` | **server** |
| The join rules: no answer | the server's walk and `ASKED_MS` | a Kick owed | **server**, through a staff client or the helper |
| The join rules: the agreement itself | `m_agree` | the server's record of what a client said | **client** (a modified client can agree without reading) |
| The reason screen, the 12 seconds to read it | `a_leave` | the client shows it and leaves | client, never relied on: the game's ban follows |
| The IP part of a ban | `BanIP` from a staff client while the player is on | the game refuses an offline player or a Steam relay | **server** when made; dodged by leaving first, as before |
| A mute | `md.mutes`, each ZeD chat | the muted client will not send; other ZeD chats hide the lines | **client** |
| Staff using the game's own window or `/banuser` | the game's packet | the game checks `BanUnbanUser` and `CantBeBannedByUser` only | server (the game's), outside ZeD's rank guard and log |

**What still gets through.** A modified client can agree to the rules without reading them, and can ignore a mute. Until the
game's call lands (no staff online and no helper) a banned modified client can stay; it is refused every ZeD command meanwhile and
a Kick waits for the first staff client. The Steam ID a client names in `a_hi` is the exact string the game's `BanSteamID` gets: a
client can name a neighbor within the same double, and that ID is the one the game bans (the server's own match is unaffected). A
staff client could check it against the game's `getUsers()` before the call; not built. With the default `SaveWorldEveryMinutes =
0` a crash still loses rows and owed calls since the last save. New server lines ("game ban did not take", "kick did not take",
"host helper ...", "refused ... under a ban") read on the Log card as the server wrote them, like the other server-only lines.

**Part E gains**, each for the local server:

| # | Unknown | How it settles |
|---|---|---|
| E21 | That `NetworkUser.new():isSteamIdBanned(sid)` runs from server Lua (the bytecode says the constructor and the method are exposed, and the method reads `ServerWorldDatabase.instance`). If it throws, `gameHoldsSid` answers nil and only presence judges a Steam ID ban | `BanSteamID` on a Steam server, then a print of the call |
| E22 | That `getFileWriter("ZeD_helper/queue.txt", true, false)` lands in the dedicated server's own `Zomboid/Lua/` (or its `-cachedir`), with the folder made | Turn the option on, ban an offline name, look for the file |
| E23 | The helper against the real console: login, `banuser "x" -r "y"`, `kickuser "x"` with no reason, `banid`, the answers as read from the bytecode | Run it beside the local server with `RCONPort`, `RCONPassword` and `-Drconlo=true` |
| E24 | That `-Drconlo=true` reaches `System.getProperty` from `StartServer64.bat` and from `ProjectZomboid64.json` | `netstat` on the RCON port after a start |
| E25 | The safe mode question in game: the game's box sizes itself to 70-character lines at Deck width and Large text | Safe mode on, join a server that asks |

