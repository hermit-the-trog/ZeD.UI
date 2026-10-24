# QUICK_CHORDS_SPEC: quick actions on bumper chords, and putting things back

**Status:** APPROVED (director, Oct 24 2026: "The mockup is approved. Build the button pictures first, then the quick action chords and putting things back."). Mockup `ZeDUI/mockups/zed_quick_chords_v1.html` (built by `zed_quick_chords_v1/build.ps1` from its template). The button pictures are built (GAMEPAD_SPEC.md, Button pictures); the chords and putting things back follow.
**Asked for (director, Oct 24 2026):** "settings for gamepad chords for quick actions. Bumpers + A, B, X, Y, L3, R3 -- 12 quick action assignments possible. I used to have this set up as steam controller setup and it worked great in combination with a quick actions mod ... quickly pulling out a flashlight and turning it on LB+X and it was on ... eating the best option, drinking the best drink, pulling a cig out and the lighter, lighting and putting the lighter back." And: "an option to automatically putting things back in the container they were in after using for a game action, like changing a tire will take the pump and jack out of a trunk and put it back after" (Tidy Up Meister, Workshop 2769706949; its page now says it was removed from the Workshop).
**Relation to other specs:** the actions are the D-pad wheels' own (DPAD_WHEELS_SPEC.md); the bumpers are BumperChord's (GAMEPAD_SPEC.md, Chords). LB + RB stays the camera zoom.

## 1. Chords (settled)

1. **Where:** in the world, when no window has the pad and no wheel is open (the wheels' rule). Not while the game is paused.
2. **How:** hold LB or RB, press A, B, X, Y, L3 or R3: the action assigned to that chord runs. Twelve chords: `LB + A` ... `LB + R3`, `RB + A` ... `RB + R3`.
3. **The button pressed with a bumper does only the chord:** A does not interact, Y does not open the windows, the stick clicks do not do their own thing. A bumper on its own still does nothing in the world; LB + RB is still zoom.
4. **More than one while held:** keep LB held and press X, then A: both run, in that order (the game queues them).
5. **An action that can't run now** does nothing and the character says why, in the game's own over-the-head text, with the wheel's reason ("Nothing to drink on you.", "In a vehicle.").
6. **Stick clicks (Hard Rule #11):** the rule keeps stray stick clicks harmless. A chord needs a bumper held as well, so L3 / R3 alone still do nothing in the world. The director asked for the L3 / R3 chords by name: #11 is amended to allow them (GLOSSARY.md).

## 2. What can go on a chord (settled: any wheel action)

- Any slice on the four D-pad wheels that does something, at any level: Eat, Drink, Smoke, Take pills, Treat wounds, Flashlight, Weapons, Sleep, Sit, Crouch, Auto-walk, Shout, a gesture, Map, Mini-map, a window tab, game speed, zoom and the rest.
- A slice that opens a list (Eat, Drink, Smoke, Take pills, Weapons) does **its best pick at once** on a chord: the first item the wheel lists, in the wheels' order (food spoiling soonest first and rotten last, water before drinks with a downside, weapons by condition, the brightest light). Same verbs as the wheel, so the game's rules hold: items come out of bags first, masks come off, a lighter is found.
- A slice inside a list (Eat › Canned Corn) can be assigned too: the chord then eats that kind when you carry one.
- The ZeD wheel's settings (Select) are not offered: they stay on Select.
- Nothing is faster than the game: every chord runs the same timed actions the wheel or the context menu would (keep vanilla's stakes).

## 3. Assigning (settled: both ways)

- **ZeD setup, Quick actions:** a page with the twelve chords as rows (the two button glyphs, then the action and where it lives on the wheels). A changes a row: a list of the wheels' actions, grouped by wheel, in the wheels' order. X clears a row.
- **From a wheel:** point at a slice, hold a bumper and press a button: the chord is assigned. If it held another action, the new one replaces it and the bubble says so for a moment. An assigned slice's bubble shows its chord (`LB + X`).
- **Defaults:** a starting layout is proposed in the mockup for the director to change (the director's old Steam layout wins if they share it).
- **Button pictures:** chords show as two pictures, `[LB] + [X]`, from ZeD's own pixel button set in the pad's colours (GAMEPAD_SPEC.md, Button pictures; director, Oct 24 2026).

## 4. Putting things back (settled)

- **The option:** ZeD setup, "Put things back after an action". **Off** for a new player.
- **When on:** whatever an action took out of a bag you carry, a container in reach (a car trunk, a shelf, a crate) or off the floor goes back where it came from once the action finishes: the same bag, the same container, the same floor square. Leftovers go back too (a half-eaten can, an empty bottle). What was in your hands goes back in your hands (your weapon after changing a tire).
- **Time:** the game's own move action, so it takes the same game time as doing it by hand.
- **Not after an interruption** or a cancel: you never stand there tidying while a zombie closes in.
- **Out of reach or full:** the thing stays on you.
- **Where the game already puts things back** (crafting and a few context-menu actions since Build 42.8), the game does it; ZeD does not move them twice. ZeD covers the rest: vehicle work (tires, parts, refuelling), first aid, smoking's lighter, eating and drinking from a bag, reading.

## 5. Build notes (for Code; not settled with the director)

- Chords: BumperChord already tracks LB / RB held (`LB_HELD` / `RB_HELD`). Add edges for A, B, X, Y, L3, R3 while a bumper is held (state to `CONSUMED`, so releasing the bumper is not a tap), and keep the pressed button from reaching vanilla (`JoypadControllerData:onPressButtonNoFocus` / `onReleaseButton`: ISButtonPrompt's A / B / X / Y, `ISJoystickButtonRadialMenu` for the stick clicks, `ISVehicleRegulator.onJoypadReleaseX`). Check what the engine reads from those buttons on its own (Java) before relying on the swallow.
- The actions: the wheel builders' entries (`ZeD.DpadWheels.B.*`, `run` / `sub`), found by a stored path (wheel id, slice key, item full type). Store the twelve in ZeD's settings file.
- Put back: wrap `ISTimedActionQueue.add`; note transfers into the main inventory (`ISInventoryTransferAction`: item, source container, floor square) and the hands at the start of a run of queued actions; on the main action's `perform`, queue transfers back (vanilla's `ISInventoryTransferUtil.newInventoryTransferAction`, the floor through vanilla's floor transfer, FLOOR_CONTAINER_TRAP) and re-equip (`ISEquipWeaponAction`); on `stop`, forget the run. Skip items the game itself returns.
- Strings: `UI_ZeD_Chord_*` keys in UI.json, the wheels' own words where they exist.
- QA: a bridge script that sets the chord state and presses the buttons as `onPressButtonNoFocus` is called; put-back with a tire change from a trunk (the deep run's car), smoking from a bag, eating from a crate, and a cancel halfway.
