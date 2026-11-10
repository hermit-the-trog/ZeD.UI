# What Project Zomboid's console tooling already does in Build 42, and where ZeD-GUI can improve on it

The game already has a working Lua console window. It is a Java window called UIDebugConsole, opened with the grave (backtick) key when the game is launched with -debug. It is also one of the weakest tools the game ships: it takes one line of at most 256 characters, sends most output to console.txt rather than to the window, and offers no search, no autocomplete and no built-in help. A Lua-only mod can rebuild nearly everything around it except the Java-side log stream. The rest of the "dev console" landscape is split across five separate surfaces: the debug menu, the F11 Lua Debugger, slash commands typed into chat, the Admin Panel, and the dedicated server window or its remote console (RCON). None of them talks to the others, and each is learned mostly from third-party hosting guides rather than from the game.

## TL;DR

- **The vanilla Lua console is thin.** UIDebugConsole runs one line of Lua at a time, capped at 256 characters, with up/down history. In normal mode, print output and most runtime errors go to console.txt rather than the window. Vanilla only listens for its toggle key in -debug, but a 42.19 mod proves a Lua mod can open it without -debug. A ZeD-GUI console should replace this window rather than reskin it.
- **Lua can reach the raw material for a better console.** loadstring is back in 42.21 after 42.20.4 removed it. The F11 debugger's error list is exposed through getLuaDebuggerErrors and getLuaDebuggerErrorCount. Lua can write .txt and .log files in the cache folder. What Lua cannot do, as far as public sources show, is subscribe to the Java log stream, read console.txt, or register new server slash commands.
- **The biggest unmet needs are the gaps between surfaces.** Single player has no chat command line, and server commands are learned from hosting-company wikis. Errors are shown as a red counter that people install errorMagnifier to read. Cheat menus keep being rebuilt for every point release. The best opportunities are a unified command palette with built-in help, a filterable error and print log, multi-line input with persistent history, and a guarded mode for ordinary players. Most of that is feasible in Lua.

## Versions and what changed

As of November 8, 2026, the current stable build is **42.21**, released to Stable on September 28, 2026. Build 42 first reached the default Stable branch as 42.20 on July 29, 2026. There is no longer an "Unstable" branch. On October 27, 2026, The Indie Stone renamed it **Pre-Release** and put **42.22** on it, followed by hotfixes 42.22.1 (November 4) and 42.22.2 (November 6). The studio says builds will now sit on Pre-Release for at least a week before going Stable.

These point releases since 42.17 touched debug, console, admin or modding tooling:

- **42.17** (April 20, Unstable): work-in-progress controller changes, and the newer interface layouts were clamped to screen size. No console-specific changes were found.
- **42.20.1**: improved Lua checksum validation for anti-cheat, and added .json to the file types getFileWriter may create. According to PZwiki, getFileWriter is now limited to ini, cfg, txt, log and json.
- **42.20.4** (August 26): a security fix; The Indie Stone's notes warned mod makers that "the loadstring and loadstream methods have been removed." This broke one-line console experiments and some admin mods.
- **42.21**:
  - loadstring and loadstream were re-enabled; the studio's notes said "After investigating further into the security issue, we've decided to re-enable those commands."
  - Host-typed commands run with admin rights.
  - /grantadmin and /setaccesslevel were fixed for players who are not on the whitelist.
  - Two-player /teleport was fixed.
  - A Seam Editor was added on F9, according to pzfans.
  - Modders got a keybind registry (KeybindId) and new Lua events including LogLevelPerk.
  - The Umbrella typings shipped a matching 42.21.0 release the same day.
- **42.22.0** (Pre-Release): a "Useless" zombie toggle in the debug Horde Manager.
- **42.22.1**: added Java Runtime Environment integrity checks.
- **42.22.2**: fixed those checks wrongly reporting "attached" on Windows.

The 42.22.1 integrity checks matter for anyone relying on Java-patching frameworks. Inference: they are another reason for ZeD-GUI to stay Lua-only.

The official modding documentation at projectzomboid.com/modding is frozen at Build 41 and is treated here as a Build 41 baseline. Its Javadoc does list some classes that look like Build 42 code (entity components, a DebugLog backed by a Loki logging client), so its exact version is ambiguous. Every method named from it below should be checked on a 42.21 install.

## The surfaces at a glance

| Surface | What it does today | How you reach it | Who uses it | Main limits |
|---|---|---|---|---|
| Lua console (UIDebugConsole) | Runs one line of Lua in the global environment, with up/down history | -debug, then the grave key ("Toggle Lua Console", rebindable) | Modders, testers, curious players | 256-character single line; output mostly goes to console.txt; no search, autocomplete or help; Java window, so it cannot be reskinned from Lua |
| Debug menu and debug keys | Cheats, item spawning, stats, climate, sandbox editing, around 30 engine tools and editors | -debug, then the bug icon under the Map button; F-keys | Testers, modders, single-player tinkerers | Hidden behind a launch option; several tools take over the screen or wipe data; little documentation for Build 42 |
| Lua Debugger (F11) | Breakpoints, source view, file browser, reload a file, watch window, error list | -debug, then F11 | Modders | "Break on error" can hijack play; some options can crash the client on launch |
| Error counter | A red "Error N" box in the corner | Appears automatically | Everyone | Shows a count, not the error; people install errorMagnifier to read it |
| Chat slash commands | 78 server commands under 92 names, gated by named capabilities | T, then /command, in a hosted or dedicated game | Admins and moderators, hosts | Not available in single player; /help is incomplete; syntax is inconsistent |
| Admin Panel | Users, roles and capabilities, server options, safehouses, tickets, statistics, item list | Admin button on the left toolbar for staff roles | Admins and moderators | Button disappears when a role loses its last admin capability; role editing exists only here |
| Dedicated server window and RCON | The same commands without the slash, at full authority | Server process window, or any Source remote console client | Server administrators, bots | No Lua execution; no custom commands; output only in server-console.txt |

## The in-game Lua console

**What it is.** The in-game name is the **Lua Console**: the key binding is "Toggle Lua Console" under Options, Key Bindings, Debug, and PZwiki calls it the "Command console … also known as Lua Console". The Java class is confirmed as **zombie.ui.UIDebugConsole**. It extends the Java NewWindow class, not the Lua ISUI classes. The game keeps a single instance reachable from Lua through UIManager.getDebugConsole(). That inheritance matters for ZeD-GUI. Inference: because the window is drawn in Java, a Lua mod can show it, hide it and focus it, but cannot restyle it into a System 7 window. A themed console has to be a new Lua window that reimplements the command line.

**How it opens.** Launch with -debug and press the grave key, which is the key left of 1, not Shift plus tilde. pzfans notes that players on non-US keyboards often have to rebind it. If you also pass Java memory flags, -debug must come after a double-dash separator, or the bug icon never appears. Three debug options control the window: UIDebugConsoleStartVisible, UIDebugConsoleEchoCommand and UIDebugConsoleDebugLog. The first two do what their names say. The exact effect of the third is not documented; by its name it probably mirrors DebugLog output into the window (inference).

**What it does.** The mod author of CJS Non-Debug Lua Console documents the vanilla entry on Build 42.19: it is "limited to 256 characters and processes one line at a time." Outside debug mode it echoes the command, but print() output and most runtime errors stay in ~/Zomboid/console.txt. Debug mode adds a print callback that sends output to the window. Command history on the up and down arrows is shown by fields (Previous, PreviousIndex) in an old Build 39 Javadoc and by a community Rust port of the class. That port also describes:

- a "clear" command;
- a scroll bar on the output log;
- commands compiled through loadstring in the global environment;
- compile errors written to the log while runtime errors go to the thread.

Treat those details as strong hints, not official confirmation. The Java class also has a levenshteinDistance method, which suggests some fuzzy matching. Inference: possibly for suggestions or history; its actual use was not found. Copy and paste, colour coding, font choice, behaviour at different interface scales, and scrollback length were all **not found**. Because the console compiles through loadstring, one-liners failed on 42.20.4 and work again on 42.21.

**Who uses it and how they learn it.** Mostly modders and testers, plus players who copy one-liners from Steam threads. For example, a Steam support thread fixed missing debug context menus on a Build 42 server by typing getDebugOptions():setBoolean("UI.HideDebugContextMenuOptions", false) into the console. The game offers no help text for the console, and PZwiki's section on it is an empty stub.

**Limits and pain points.** You cannot paste a function longer than 256 characters or write a loop over several lines. Output is in a different file from the input. Nothing tells a newcomer what globals exist. Vanilla only listens for the toggle key in debug mode.

## The rest of debug mode

**Debug menu.** In 42.21, the bug icon under the Map button opens a Main tab with these entries:

- General debuggers (including game speed)
- Cheats, a window titled "Edit your Admin Powers" with, in pzfans's words, "God Mode, Invisible, No Clip and 21 more switches" (24 in all), among them Fast Move, Timed Action Instant, Brush Tool, LootZed and LootLog
- Climate debuggers
- Craft Recipes
- Player's Stats
- Items List
- Fluids
- Entities
- Script Manager
- XUI Debugger
- Recipe Monitor
- Sandbox Settings

A Dev tab holds engine tools: Audio, IsoRegions, Zombie Population, Stash, Anim monitor, Zomboid Radio, Animation Viewer, Attachment Editor, Chunk Debugger, Global Objects, Map Editor, Vehicle Editor, World Flares, Global Mod Data, New UI, Unit Tests, Character Debug, Forget Recipes and the Seam Editor. The main menu gains a Reset Lua button and a list of debug scenarios. Right-clicking in the world adds debug context menu entries such as copy or destroy tile, edit item, horde spawning and vehicle spawning. The Lua file behind the menu is presumed to be ISDebugMenu, but its Build 42 name and structure were **not verified**.

**Debug keys.** pzfans lists these defaults for 42.21:

- N toggles God Mode, Invisible, No Clip and Fast Move together.
- F3 hides character and zombie models.
- F6 shows animation text.
- F2 opens the Chunk Debugger; Ctrl+F2 opens Global Objects.
- F7, F8 and F9 open full-screen editors.
- F11 opens the Lua Debugger.

F3 and F2 have normal-play meanings too, so a reflexive keypress makes everyone vanish or throws the player into a full-screen tool.

**Lua Debugger (F11).** PZwiki's description dates from Build 41. It breaks into the debugger at the next Lua entry point. It has a file list, a file browser with a "reload file" button that the wiki calls "often an unreliable way to test", a watch window, a coroutine view and a long options list. PZwiki warns that some of those options can make the client freeze and crash on every launch until they are set back to false in Zomboid/debug-options.ini. A Steam user's fix for "lots of windows but no game" was to press F11 again and untick "break on error", because mod errors otherwise throw debug mode into that screen.

**Error counter.** Errors appear as a small red "Error N" box. The game exposes the same list the F11 debugger uses through the globals getLuaDebuggerErrorCount(), getLuaDebuggerErrors() and getLuaStackTrace(). These are named in the projectzomboid.com Javadoc and need checking on 42.21. The errorMagnifier author says the mod "just accesses the errors that would populate the F11 menu".

**Profiling.** No vanilla Lua profiler was found. The Workshop's Lua Profiler [B42.17] and ZBLuaPerfMon both depend on the ZombieBuddy Java-patching framework. That tells you profiling needs a Java hook.

**Foot-guns** in this surface:

- Forget Recipes wipes the character's learned recipes.
- Sandbox Settings changes persist after -debug is removed.
- An ElecShutModifier of -1 turns power off rather than on, and its maximum value overflows when food aging multiplies it by 24.
- Some Lua Debugger options crash on launch.
- The game marks nothing in a save as "debugged", so mistakes are silent.

## Log plumbing and what Lua can reach

**Files.** The client log is Zomboid/console.txt. Hosted co-op writes coop-console.txt, and a dedicated server writes server-console.txt. Earlier sessions are archived in Zomboid/Logs, and Tech Support asks for logs.zip. Lua print() output goes to console.txt. Log lines carry a category and a severity, for example "LOG : General", "ERROR: General … ExceptionLogger". In Java these come from DebugLog, DebugType and LogSeverity. The debuglog.cfg file or the -debugcfg= option sets levels per category, and on a server the /log command does the same. The host DoomHosting reports that the server prints a "Logs configuration" table at boot, and that "on a normal boot almost all of them sit at Warning."

**What a Lua mod can do (Build 42):**

- **Evaluate a string as Lua.** Yes on 42.21 via loadstring. It was absent on 42.20.4, so a console mod should detect that and degrade gracefully.
- **Read the F11 error list.** Yes, through getLuaDebuggerErrors and getLuaDebuggerErrorCount. This needs verifying on 42.21: a user on 42.21 wrote on the errorMagnifier Workshop page, "I'm consistently getting errors, but when I open the magnifier, it says there are zero errors."
- **Intercept Lua print.** Very likely, by wrapping the global print function. errorMagnifier's own changelog mentions a "print() fingerPrint override" fixed for Build 42.
- **Read and write files.** getFileReader and getFileWriter work in the Zomboid cache folder (the Lua subfolder) for ini, cfg, txt, log and json. getModFileReader and getModFileWriter work inside mod folders. That is enough for persistent history, saved snippets and exported logs.
- **Run a console without -debug.** Yes: CJS Non-Debug Lua Console grabs UIManager.getDebugConsole() and toggles it. In multiplayer the game still requires the co-op host or the UIManagerProcessCommands capability.

**What a Lua mod cannot do, or what is unknown:**

- **Subscribe to the Java DebugLog stream.** Not found; assume it needs a Java hook.
- **Read console.txt.** Unknown. No evidence that the file reader can leave the Lua sandbox, and PZwiki records a fixed escape that let mods write outside the intended folders.
- **Catch errors as they happen with an error event.** Not found. Polling the error count each tick is the known workaround (inference).
- **Register new slash commands on the server.** No. The author of the RCON Custom Commands mod states the game "does not expose its backend functionalities for creating custom server/admin commands through its Lua scripts". That mod works around it by filtering servermsg broadcasts on a client, which needs one player online.

## Chat commands and the Admin Panel

**What exists.** supercraft.host built its list from the 42.x server's own command registry (build 24909836, updated November 2, 2026). It counts 78 commands under 92 names, including seven chat channels. Each command is gated by a named capability (for example AddItem, BanUnbanUser, ReloadLuaFiles, DebugConsole, ConnectWithDebug), not by a role directly. Commands are typed after T with a leading slash. Notable Build 42 changes:

- Self and other-player versions of commands were split: /godmode versus /godmodeplayer, and /invisible versus /invisibleplayer.
- New commands include /removeitem, /teleportplayer, /debugplayer and /list (animals).
- /reloadlua and /reloadallluaall exist, but there is no command that runs arbitrary Lua.

**Single player versus multiplayer.** Single player has no chat box, so slash commands do nothing there. pzfans calls this the most common reason commands "fail", and it is a real gap for ordinary players. Hosting a game from the main menu gives a private server where commands work, and on 42.21 the host's typed commands run with admin rights. A dedicated server takes the same commands from its window without the slash.

**Access levels.** Sources conflict here:

- supercraft.host lists admin, moderator, overseer, gm, observer, user, priority and banned.
- pzfans says the defaults are banned, user, priority, observer, gm, moderator and admin, and that "overseer" survives only in /setaccesslevel's help text.

Either way, admins can change which capabilities each role holds. That editing happens only in the Admin Panel's Roles screen, with RolesRead to view and RolesWrite to edit.

**Admin Panel.** The Admin Panel holds a users list (with Set Role), a roles list, server options, the player database, safehouses, tickets, statistics and an item list. pzfans reports that the Admin button vanishes, and an open panel closes, when a role loses its last admin capability.

**Learning it.** /help lists the commands available to your access level. Help quality is uneven:

- Some commands, such as /connections and the whitelist commands, are not listed by /help.
- /log's help still reads "/log %1 %2".
- PZwiki shows "WIP: UI_ServerOptionDesc_AddToSafehouse" as a description.
- An older remote console guide shows missing-translation strings for /createhorde2 and /removezombies.

Most players learn commands from hosting-company pages, which disagree with each other and carry commands that never existed.

**Foot-guns.** /removezombies, /grantadmin and /removeadmin are flagged as destructive. /changeoption can change world rules mid-game. A client launched with -debug is disconnected from a dedicated server unless it is an admin ("Debug connection is not allowed for non-admin").

## Dedicated server console and remote console

The dedicated server window accepts every command without the slash. It is not access-limited, which is how the first admin gets created. It always needs a username where chat would assume "you", for example in /createhorde. Remote console uses the Source RCON protocol on a TCP port set by RCONPort and RCONPassword. It also runs with full admin authority, so, as the GameTeam blog puts it, treat the remote console password "like the keys to the server." The host WinterNode says that in Build 42 "Commands now behave the same across all three access methods, aside from the / prefix requirement for in-game chat."

What is missing:

- arbitrary Lua execution;
- custom commands;
- streaming of the server log over remote console;
- any connection to the in-game Lua console.

Community tools fill this from outside the game: a Python remote console library (zomboid_rcon, aligned to 42.20.2), and web panels such as zomboid-control-panel, which has its own capability-based roles and a "Lua bridge for in-game actions". Most Build 42 server tooling lives outside the game client.

## Community mods and developer tooling

**Consoles and error tools:**

- **CJS Non-Debug Lua Console** (GitHub, Build 42.19): exposes the vanilla console without -debug. It is tiny, with no stars yet. It shows people want the console without the rest of debug mode.
- **errorMagnifier** by Chuckleberry Finn (Workshop 2896041179, Build 41 and 42, 532 comments): turns the red counter into a readable, copyable error list. Other popular mods depend on it: Skill Recovery Journal (Workshop 2503622437) lists errorMagnifier as a required item. Recurring complaints: it misses errors that only reach the log, it loses the list when the save closes, and it struggles with error counts in the thousands. These complaints point at missing persistence and filtering.

**Cheat menus.** These are rebuilt for every point release:

- Cheat Menu: Rebirth (2732834772) has not been updated since 2022.
- Its unofficial [B42] port (3388809112, 502 ratings) is reported broken on 42.20.2.
- Cheat Menu Reborn (3751612935) is marked deprecated.
- Cheat Menu: Rebuild (3786332527) supports 42.20 and 42.21, including dedicated servers for admins.
- Rax's Reborn (3815818643) targets 42.21 with multiplayer in beta.
- A commenter mentions a single-player "Sandbox Control" menu with undo.

This churn shows how much vanilla's debug menu leaves players wanting, especially undo and a single right-click entry point.

**Debug helpers:**

- **[B42]DebugMenu** (3386556284) adds brush tools, item and media generators, basement and animal debugging, and time control. Its install step asks users to overwrite files inside the game's jar, so it is a Java patch and outside ZeD-GUI's rules.
- **Lua Profiler [B42.17]** and **ZBLuaPerfMon** need ZombieBuddy, also Java.

**Developer tooling:**

- **Umbrella** (PZ-Umbrella on GitHub) supplies LuaCATS type stubs for VS Code via EmmyLua or the Lua Language Server, and released 42.21.0 on September 28, 2026. Its pz-lua-stubdata source says it is current to 42.13 "with the exception of some known gaps".
- **LuaDocs** and PZwiki's per-build "Modding News" are the de facto change log for the Lua application programming interface.

The fact that modders depend on an external editor for autocomplete suggests an in-game autocomplete would be welcome (inference). A shared catalogue of globals could be built from the same stub data.

## Controllers, interface scale and fonts

No evidence was found that the Lua console, the debug menu, the Lua Debugger or the Admin Panel work with a game controller. The 42.17 to 42.20 controller work concerned gameplay and menu screens. No source documents how these surfaces behave with the interface scale or font size settings. errorMagnifier did have to anchor its button "to handle screen size changes". Treat both as unknown, and as an opening for ZeD-GUI.

## Gap list with feasibility for a Lua-only mod

Each gap is listed with its evidence and its feasibility.

1. **A console that does not need -debug, with a guarded mode for ordinary players.**
   - Evidence: the CJS mod; the Steam request for quicker debug toggling; pzfans's "why T-chat fails" troubleshooting.
   - Feasibility: **Doable.** Multiplayer stays gated by the game's UIManagerProcessCommands check. The guarded mode (read-only inspection, a curated list of safe actions, confirmation before destructive ones) is a design inference, not a documented request.
2. **Multi-line input and lines longer than 256 characters.**
   - Evidence: the 256-character single-line limit.
   - Feasibility: **Doable** in a new Lua window that compiles with loadstring on 42.21. Fragile if a future security hotfix removes loadstring again, as 42.20.4 did.
3. **Output in the window rather than in console.txt.**
   - Evidence: the CJS README.
   - Feasibility: **Doable for Lua print** by wrapping print. **Needs a Java hook that does not exist** for Java-side log lines.
4. **A searchable, filterable, persistent error log.**
   - Evidence: errorMagnifier's popularity and complaints.
   - Feasibility: **Doable.** Poll getLuaDebuggerErrors, then filter by mod or file and save to a .log file. Verify on 42.21, given the zero-errors report.
5. **Persistent command history and saved snippets.**
   - Evidence: inference; no source asks for it directly.
   - Feasibility: **Doable** with getFileWriter (.txt).
6. **Autocomplete and discoverability of Lua globals and Java methods.**
   - Evidence: modders rely on Umbrella in an external editor (inference).
   - Feasibility: walking the global table is **doable**. Listing methods on exposed Java objects is **unknown** until the reflection helpers are checked on a 42.21 install.
7. **A command palette for slash commands, with syntax, examples and required capability.**
   - Evidence: incomplete /help, untranslated help strings, and the self-versus-player split.
   - Feasibility: a bundled catalogue is **doable**. Sending a command from Lua the way chat does is likely but **unverified**. In single player the server commands still cannot run, so the palette must route to debug equivalents.
8. **Custom admin commands.**
   - Evidence: the RCON Custom Commands mod.
   - Feasibility: **needs a Java hook that does not exist.** A mod can only add its own client-to-server Lua commands.
9. **Undo for cheats and world edits.**
   - Evidence: the Sandbox Control comment.
   - Feasibility: **partly doable** for actions the mod performs itself. Not doable for vanilla debug tools.
10. **Lua profiling.**
    - Evidence: two ZombieBuddy-based profilers.
    - Feasibility: **needs a Java hook.**
11. **Controller and interface-scale support.**
    - Evidence: none either way.
    - Feasibility: **unknown.** Probably doable for a Lua window using the game's joypad focus system.
12. **Reading console.txt or the server log in-game.**
    - Evidence: admins currently read files by hand.
    - Feasibility: **unknown.** Likely blocked by the file sandbox.

## Recommendations

Build ZeD-GUI's console as a new System 7 window, not a skin over UIDebugConsole, which is Java-drawn. Organise it in four panes:

- **A Lua scratchpad.** Multi-line, with history saved to disk, and with loadstring detection so it fails clearly if a hotfix removes loadstring again.
- **A message log.** Wrapped print plus the F11 error list, filterable by mod, file and severity, and exportable.
- **A command palette.** Every server command with syntax, examples and required capability, and a single-player routing table to the debug-menu equivalent.
- **A guarded mode.** The default for non-debug players: inspect-only, with confirmations on anything flagged destructive.

Do not try to replace the Admin Panel's role editor, the debug editors or remote console. They are Java-backed or external, and rebuilding them gains little.

## Caveats

Many Build 42 details come from hosting-company and fan guides (pzfans, supercraft.host, gameteam) rather than The Indie Stone. Several of these sites have commercial motives and sometimes disagree, for example on whether "overseer" is still a role. The official Javadoc is a Build 41 baseline of uncertain version. Rust-port and Build 39 Javadoc evidence about history and scrollback is indirect. Mod popularity figures are partial because Workshop subscriber counts were mostly unavailable.

## Open questions only a Build 42 install can settle

1. Does the vanilla console support clipboard paste, or text selection and copy in its log? How long is its scrollback, and does it follow the interface scale setting?
2. What exactly does UIDebugConsoleDebugLog route into the window? Is any DebugLog listener or callback exposed to Lua?
3. Is getLuaDebuggerErrors still populated on 42.21 outside debug mode, and does it reset on save reload?
4. Can getFileReader open ../console.txt or anything outside Zomboid/Lua?
5. What is the Build 42 debug menu file (ISDebugMenu or a replacement)? Can mods add entries through a supported table rather than overriding it?
6. Is there a Lua function that sends a slash command to the server exactly as chat does, and what does it return?
7. Which reflection helpers can list methods and fields of exposed Java objects for autocomplete?
8. Does UIDebugConsole's levenshteinDistance drive any suggestion behaviour?
9. How do the console, debug menu and Admin Panel respond to joypad focus?
