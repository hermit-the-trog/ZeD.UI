# Radial wheels: the build spec (punch list 91, Nov 5 2026)

The doc "ZeD-GUI Radial Wheels: Build & QA Handoff" (https://claude.ai/artifact/4HtFjQfJExmaMQaQcJ8Yj3), corrected against
the shipped game and the director's answers. Where the two differ, this file wins. It changes how the wheels of
DPAD_WHEELS_SPEC.md are worked. It does not change what is on them.

## What stays
- All four wheels and the Select (ZeD) wheel, every slice in its place, inner wheels, Tabs as the first slice, "places
  never move" (off slices keep their reason), mods adding slices through the game's radial object, keyboard wheels.
- Quick action chords, including assigning one from an open wheel (a bumper held, then a face button).
- The look: ZeD_Wheel.lua, no new drawing beyond the prompts. Wheels open only when no window has the pad. Driving with X
  held keeps D-pad Up and Down for cruise control. Paused: only Here and now and ZeD open.
- The shipped button map (GAMEPAD_SPEC.md): A left click, X right click, B back, Y windows, LB and RB the windows.

## The gesture (defaults)
1. **Open:** tap a D-pad direction. The wheel stays up on its own, at the center of that player's screen. The left thumb
   goes back to the stick; the left stick keeps walking and the game stays live.
2. **Pick:** the right stick's angle highlights a slice once its magnitude passes the engage radius. Only the right stick.
3. **Commit:** flick-release. When the magnitude drops below the release radius, the slice highlighted on the last frame
   above that radius fires and the wheel closes. Never read the angle on the release frame: the stick springs through
   center and reports garbage.
4. **Inner wheels:** a flick onto a slice that opens a wheel opens that ring in place. The stick has to come back to
   center (it just did), then pick and flick again. B backs out one level. Same D-pad direction closes all of it.
5. **Cancel:** the same D-pad direction again, or B (at the top level), nothing fires. A different direction swaps wheels,
   nothing fires. With no engage after opening (or after entering an inner wheel), the wheel closes by itself.
6. **Face buttons:** A, X and Y do nothing with a wheel up, and don't reach the game. On close the shipped map is back,
   whichever way it closed (commit, cancel, timeout, swap, attack).
7. **Aim or attack with a wheel up (the director):** the wheel closes, takes nothing, and the attack happens. The press
   must not be swallowed.
8. **Bumpers (the director):** close the wheel and open the windows. The chord assign still works: a bumper held and a
   face button pressed with a wheel up assigns, so the close and the windows act on the bumper's release, and only when
   no face button was pressed while it was held.
9. **An off slice:** highlights, and committing it does what taking an off slice does today.
10. No auto-repeat, no acceleration, magnitude never clamped. No rumble: the game has none.

## Constants (starting values, in one table, `ZeD.DpadWheels.tune`, so a tester can change them live)
| Name | Default | Does |
|---|---|---|
| ENGAGE_RADIUS | 0.35 | stick magnitude above which a slice highlights |
| RELEASE_RADIUS | 0.60 x engage (0.21) | magnitude below which the highlighted slice commits |
| SECTOR_HYST_DEG | 7 | degrees past a boundary before the highlight moves; the wheel keeps lastSector |
| DISMISS_TIMEOUT_S | 3.0 | no engage: closes |
| OPEN_DEBOUNCE_MS | 150 | a second tap this soon after open is ignored |

Inner wheels can have up to 12 slices: sector width is 360 / slice count, and the hysteresis never exceeds a quarter of it.

## Settings (ZeD setup, Controls, beside the other controller choices)
| Setting | Options | Default |
|---|---|---|
| Wheel open | Tap, Hold | Tap |
| Wheel commit | Flick-release, Stick click | Flick-release |
| Wheel toggle mode | Off, On | Off |
| Wheel stick dead zone | 0.20 to 0.60 | 0.35 (sets engage; release is 60% of it) |

- **Hold** is today's behavior: up while the direction is held, letting go takes. With Flick-release, releasing either the
  D-pad or the stick commits, whichever comes first.
- **Stick click:** flick-release no longer commits, R3 does, and the click doesn't move the highlight. An exception to
  the rule that nothing in the world binds to a stick click: it counts only with a wheel open and this setting chosen
  (the director).
- **Toggle mode:** tap to open, right stick or D-pad moves the highlight, A confirms, B closes. Overrides commit, forces
  open to Tap. For players who can't use the stick fluidly or can't hold inputs. Goes on the Workshop page's Access list.
- The Select wheel follows these same settings.

## Words to update with it
The wheels' prompts (top level and inner), every place the game's text says to hold the D-pad (the survival guide, the
controller map, GAMEPAD_SPEC.md's "D-pad wheels" section, DPAD_WHEELS_SPEC.md section 2, QUICK_CHORDS_SPEC.md if it
says so). The gallery and the Workshop page are QA's and the director's, after it lands.

## QA (the doc's list, corrected)
On a real pad, and once on one with drift. Each direction opens by tap with the game running; the left stick walks with
a wheel up; same direction cancels; a different direction swaps; timeout closes; B cancels; A, X, Y do nothing; every
close gives the shipped map back. Below engage nothing highlights; each slice highlights at its angle; resting on a
boundary doesn't flicker; a fast flick and a slow ease both commit the same slice, never the opposite one. Inner wheels
by flick, B out one level. Attack and aim close the wheel and the swing lands. Bumper tap closes and opens the windows;
bumper held plus a face button assigns a chord and opens nothing. Hold, Stick click, Toggle mode, the dead zone live.
No wheel with a window holding the pad. Left stick never moves the highlight. Split screen.
