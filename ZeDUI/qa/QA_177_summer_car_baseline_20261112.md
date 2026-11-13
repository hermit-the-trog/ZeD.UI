# QA 177: Maskarad's Summer Car baseline (Nov 12 2026)

Mod id MaskaradsSummerCar (Workshop 3790160840), copied into %USERPROFILE%\Zomboid\mods for the runs and removed after.
Game 42.22.2, 4K fullscreen, UI scale 1.75x, -nosteam, -debug. Reports: `qa/regression/2026-11-12_1700_mods_fullscreen4k.md`
(Run 1, ZeD on), `qa/regression/2026-11-12_1707_mods_fullscreen4k.md` (Run 2, ZeD out). Scripts: `tools/qa/zedqa_msc_run.ps1`,
`zedqa_msc_run1.lua`, `zedqa_msc_run2.lua`. Screenshots (not committed): `%USERPROFILE%\Zomboid\Screenshots\summer_car_20261112`.

Save: the runner (zedqa_mods_run.ps1) snapshots ZeD-QA and puts it back; a second copy was also made to a scratch folder
before the first launch. After the last run ZeD-QA matched that copy file for file, and its mods.txt lists ZeD_UI only.
A plain Base.CarNormal was spawned on the drag strip with its key. MSC initialized it on its own (initialized=true), with no ECU
installed. Staging used: Strength set to 5 and the ECU flag forced in the car's mod data for the ECU wheel check (the server sets it
in a real game); no engine lift or detached engine was staged.

## Run 1: ZeD on + Summer Car

| Check | Result |
|---|---|
| Summer Car engine window, auto-open from ZeD's Vehicle tab (hood open, player outside, game running) | **Never appears.** Seen on 0 of 323 ticks over a 14 s watch. The game's mechanics window object exists but is never visible (reallyVisible=false), so the wrapped ISVehicleMechanics:prerender never opens it. canAccessEngine is true once the hood is open. |
| "Inspect engine components" pressed from the Engine part menu | Runs without a Lua error but **no window appears** (0 windows 1.5 s and 5 s later). openFromMechanics is handed the hidden mechanics window; the window's own check (mechanics window not visible) closes it at once or never shows it. |
| Engine row right-click in ZeD's Vehicle tab (real mouse) | **Works.** ZeD's menu strip shows 3 cells: "DBG: ISVehicleMechanics.cheat=true" (debug only), "Remove engine at lift" (greyed: lift missing), "Inspect engine components" (available). Hover tooltip shows. Screenshot 3. |
| ECU diagnostics slice, inside the car, pad path (World > Vehicle slice through ZeD's wheel) | **Works.** Without an ECU there is no slice (12 slices); with the ECU forced there are 13 and slice 11 reads "Open ECU diagnostics". Screenshots 11 and 13. |
| ECU slice pressed | **Works.** The MSC window opens (x=1670 y=764, 500x631 px, tab Diagnostics) and stays (same 5 s later). It is not scaled with ZeD's 1.75x, so it looks small at 4K. Screenshots 14 and 15. |
| Push slice, outside the car, pad path | **Works.** With the character at the car's end (Push.validate true), the Vehicle wheel reads Vehicle Mechanics, Enter Vehicle, Push vehicle, Back. Screenshot 7. |
| Wheels with the mouse (V key path) | **Not tested.** ISVehicleMenu.showRadialMenu was called directly (the V handler's target) but the wheel never became visible from the bridge, and the slice lists it printed outside (with Push vehicle) and inside were stale. A real V key press was not tried. |
| Controller | Driven through ZeD's own pad path (ISDPadWheels.onDisplayRight, then the Vehicle slice) as the other pad scripts do; no real pad. |
| World right-click on the car (real mouse), ZeD's menu | **Works.** 6 cells: Gardening, Sit on ground, Walk to, Vehicle, "MSC: Dump vehicle diagnostics", "Push vehicle". Screenshot 8. Not pressed. |
| Push hotkey | **Works.** The binding is unbound by default; bound to K for the run, a real K press (keyboard helper) reached OnKeyPressed (1 event) and the car moved 0.45 squares with ZeD on. |
| Inventory options (hang engine on lift, inspect detached engine, component repair) | **Not tested.** Need a detached engine or damaged components. |
| Engine on a lift | **Skipped** (not cheap to stage). |
| Animal-tow overlay (MSC_AnimalTowClient, OnPostUIDraw) | **Not staged.** From the code: a full-screen transparent ISPanel at 0,0 with a line drawn in OnPostUIDraw, so it draws after all windows, over ZeD's. Not seen on screen. |
| Hood: ZeD's Vehicle tab opens the hood the normal way | Hood opened 3.3 to 3.8 s after the Mechanics action; no MSC prints. |

Where it breaks with ZeD: everything that goes through the game's mechanics window (auto-open, "Inspect engine components", the window's
close-with-mechanics rule, tiling beside the mechanics window). The wheels, the world menu, the push key and the ECU window work.

## Run 2: ZeD out of the mod list (QA shim only), game's mechanics window

| Item | Finding |
|---|---|
| Timeline after the Mechanics action | t+3085 ms hood open; t+6967 ms mechanics window visible (the engine window is not there); t+6999 ms (32 ms later) the Summer Car window appears. So it opens as soon as the mechanics window is visible and the hood is open; the hood must be open first (canAccessEngine = hood open). |
| Game mechanics window | x=1520 y=767 w=800 h=600 |
| Summer Car engine window | x=2330 y=767 w=500 h=785, title "MSC Engine Components", tab "engine". It sits right of the mechanics window (1520+800 = 2320, 10 px gap), same top. The mechanics window did not move (placement is tiled only if there is no room). |
| What it shows | Header (vehicle name, engine temperature), three tab buttons (Engine, Fluids & Temperatures, Diagnostics), two scroll lists of components grouped Electrical, Fuel and Air, Engine Core, Oil System, Cooling, Accessories, Drivetrain, each "(Standard)" with a condition percent; a selected-part header (Starter, Condition 81/100). Child classes: two ISScrollingListBox, ISButtons, ISResizeWidgets. |
| Engine part right-click | 3 options: "DBG: ISVehicleMechanics.cheat=true", "Inspect engine components", "Remove engine at lift" (greyed). Opened through ui:doPartContextMenu by the bridge, not a real right-click. Screenshot 2. |
| Closing the mechanics window | The Summer Car window closes with it (gone 1.5 s later). Reopening with the hood open: the engine window returns 16 ms after the mechanics window is visible. |
| Other Summer Car windows that depend on the mechanics window | None found. The window keeps `mechanicsUI` and `mechanicsPlacement`, closes itself when that window is hidden or shows another vehicle, and restores the mechanics window's x on close. The ECU and detached-engine paths open the same class without a mechanics window. |

## Console lines

Run 2's console.txt (Run 1's was replaced): MSC lines are the load banner (about 40 "[MSC][...] ... loaded" lines), 30 server
"Initialized Base.<car> vehicle id=..." lines (the spawned test car and the world's cars) and nothing else. No MSC-named Lua error or
exception in either run. The "Object tried to call nil in pcall" exceptions in the Run 2 report (12) and the first Run 1 report come
from the QA script's own pcall(e:getTable()) on non-Lua UI elements (spawnpoints.lua:108), not from the mod.
Other lines in the reports are the same engine errors every run shows (fonts, fluid names, map metadata).
