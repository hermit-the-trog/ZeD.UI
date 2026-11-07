# Testing Project Viewpoint and ZombieBuddy in isolation (research, Nov 7 2026)

The director, Nov 7 2026: "look into a virtual machine setup for testing just viewport and zombiebuddy, not the other add on mods. want to add to the list of beta 9 or 10."

Research only: nothing was installed or signed in. The two Workshop pages (ZombieBuddy 3619862853, Project Viewpoint 3809306528) refused automated reads (HTTP 429). Read both by hand before setting anything up.

## What the two are

**ZombieBuddy** is an open-source (MIT) Java agent by zed-0xff (https://github.com/zed-0xff/ZombieBuddy). It loads Java mods into the game.
- **Subscribing alone does nothing.** Two files (`ZombieBuddy.jar`, `zbNative.dll`) go into the game's install folder, and a launch flag (`-agentlib:zbNative --` on Windows) goes into the launcher: `ProjectZomboid64.json`, `ProjectZomboid64.bat` or Steam's launch options. Its installer does this to the real Steam install (doc/Installation.md).
- **It writes outside the game too:** `%USERPROFILE%\.zombie_buddy\` holds its approvals and caches. The `config_dir=` argument can move that folder (doc/CommandLine.md).
- **A Java mod runs with your full user rights.** Its approval dialog stops unknown jars, but an approved jar is not sandboxed (README, doc/ModSigning.md).
- **Removal:** the installer's Uninstall, or by hand (doc/Uninstall.md):
  1. remove the flag;
  2. delete the two files and `.jar.new`;
  3. delete `.zombie_buddy`;
  4. let Steam's Verify restore the launcher files.

**Project Viewpoint** (by ellu, per a third-party listing) is a new renderer for the game, built on ZombieBuddy:
- first-person, third-person and free cameras;
- shadows, volumetric light and bloom;
- shader packs;
- its own settings on Delete.

It says nothing about the game's HUD or UI mods. The likely contact points with ZeD are:
- mouse picking and the cursor lock;
- scaling;
- anything drawn in the world;
- hover cards and the radial wheels;
- key clashes: O, Shift+O, Insert+O, Delete and the middle mouse button.

## Ways to fence it off from the director's PC

| Option | Wall | Graphics | Effort | Disk | Note |
|---|---|---|---|---|---|
| **Windows Sandbox with vGPU** (in Windows 11 Pro) | Real: everything but mapped folders is wiped on close; networking can be off | Shares the real GPU; whether its OpenGL is enough for the game and Viewpoint is **unknown** | Low: one `.wsb` text file | about 10 GB (a copy of the game) | The recommended first try |
| VMware Workstation Pro (free for personal use) | Real: separate Windows | OpenGL up to 4.3 in the guest; the game is not known to run there | Medium | 40-70 GB | The fallback if the Sandbox's graphics fall short |
| Hyper-V with GPU partitioning | Real | "OpenGL games may or may not work"; breaks on every NVIDIA driver update | High | 40-70 GB | Not recommended |
| VirtualBox | Real | Too weak | - | - | No |
| A copy of the game folder, `-nosteam`, `-cachedir` | **None**: a Java mod runs as you and can reach any file | Full speed | Lowest | about 10 GB | Isolation by habit only |

Sources:
- Microsoft's .wsb docs (vGPU, mapped folders, networking): https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-configure-using-wsb-file
- VMware's guest OpenGL: Broadcom techdocs for Workstation 17.
- GPU-P: https://github.com/l3rd/easy-gpu-pv

## Result, Nov 7 2026: Windows Sandbox can't run the game

The director turned Windows Sandbox on and QA built the setup:
- the copy is at `E:\ZeDSandbox`: `game` (the copy, with Zombie Buddy's two files and its flag in `ProjectZomboid64.json`), `user` (-cachedir, with ZombieBuddy and Viewpoint in `mods`), `zbconfig`, `logs`, `scripts\start.cmd` and `ZeD_Viewpoint.wsb`;
- vGPU on, networking off;
- the mods were downloaded with SteamCMD as anonymous, with no subscription;
- the real install's `ProjectZomboid64.json` was checked untouched.

Four runs:
1. Fullscreen, 16 GB, with Zombie Buddy.
2. The same again.
3. Windowed 1280x720, 8 GB, with Zombie Buddy.
4. Windowed 1280x720, 8 GB, Zombie Buddy off.

Every run reached the same point. The game sees the RTX 4090 through the sandbox (OpenGL 4.6.0 NVIDIA 617.42), opens its window and starts the sound system. With Zombie Buddy on, the agent loads (`agents=1`) and patches `GameWindow`. Then the whole sandbox dies with "The Windows Sandbox environment unexpectedly terminated. The virtual machine or container exited unexpectedly. (0x80370106)". The last log line is always `FMOD_System_Set3DSettings`. On the real install, the next step is loading the font textures, the first big upload to the GPU. Run 4 fails the same way, so the sandbox's GPU sharing is the fault, not Zombie Buddy.

**Also:** Viewpoint 0.1.6.1's `mod.info` says `versionMin=42.21` and `versionMax=42.21`. The director's game is 42.22.2, so the game may refuse Viewpoint even on a machine that runs it.

What's left: VMware Workstation Pro (free for personal use). It's an install, so it needs the director's go, and the game isn't known to run there either. Viewpoint also needs a 42.22 build from its author, or a 42.21 copy of the game.

## Recommendation, for the beta 9 or 10 list

Try **Windows Sandbox** first: a copy of the game, run with `-nosteam`, networking off, and ZombieBuddy's config folder pointed inside the mapped area. If the game or Viewpoint won't draw there, the next step is VMware Workstation Pro.

Steps, for when the director gives the go:
1. Turn on Windows Sandbox (Windows features). This needs a restart.
2. Copy the game install to a test folder. Make empty user and ZombieBuddy-config folders.
3. Download ZombieBuddy and Viewpoint with SteamCMD (no subscription) into the test user folder's `mods`.
4. Copy ZombieBuddy's two files into the game copy only. Never run its installer: it targets the real Steam install.
5. Write the `.wsb`:
   - vGPU on, networking off, 8 GB of memory or more;
   - the game copy mapped, plus writable user and config folders;
   - a start script.
6. Start the copy with `-nosteam -debug -cachedir=<user> -agentlib:zbNative=policy=prompt,config_dir=<config> --`. Look for the "ZombieBuddy loaded" label, and OpenGL errors in console.txt.

What QA tests once it runs:
- **The game's own baseline:** Viewpoint with ZeD off.
- **Then with ZeD:**
  - the main menu and ZeD setup;
  - the belt, watch and moodles;
  - both windows, cards and the wheels;
  - clicks landing under the cursor in each camera;
  - the controller;
  - key clashes;
  - 1080p and 4K;
  - ten minutes of play.

Pass means no new ZeD errors, every ZeD surface in place in all three cameras, clicks true, no key clash and no crash.
