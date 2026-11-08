# Handoff: dash indicators and odometer (Nov 6 2026)

For the design session, from the director, written by QA. Not part of today's release: this is for the next beta.

## What we want

Draw the missing indicators on ZeD's 19 dashboards, so they can show what the mod Roadworthy adds, and give the dashes a real odometer and trip odometer. No new dashboards. The director: "I think we just need to add some indicators, like the seatbelt."

## Why

A player, Neonvolt, asked for Roadworthy support, worried its extra gauges won't show on ZeD's dashes. Roadworthy is a realistic driving and car maintenance overhaul by Mexes, with 3,683 subscribers. Its code is MIT licensed and its art is CC BY 4.0. Workshop ID 3828608843, Mod ID RealisticDrivingOverhaul. It needs Vehicle Kit Library.

Pictures: `ZeDUI/qa/roadworthy_look/`. `roadworthy_dashboard_2x.png` is its dashboard; `roadworthy_workshop_pictures.jpg` is all 11 Workshop pictures.

## What Roadworthy puts on the dashboard

- Odometer and trip meter: six digits in miles and a four-digit trip counter.
- Temperature gauge: a C to H dial in its own small pod.
- Four lamps: high beam, coolant, seat belt, oil.
- Gear letter: on hover it shows the car's gearbox.
- It also lights the game's battery and engine icons when those fail.

In Roadworthy a seat belt lamp and chime come on in cars from 1972 onward if you're not buckled.

## What each dash has now

From `DashPx.lua`. "Draw" means the art is missing. Gear letters: 9 dashes have a live letter part; the others may show the gear another way, which I didn't check.

| Dash | Seat belt | Hot (coolant) | Oil lamp | High beam | Temp gauge | Oil gauge | Gear letter |
|---|---|---|---|---|---|---|---|
| ambulance | yes | Draw | yes | yes | yes | yes | yes |
| bulldriver | yes | Draw | Draw | yes | yes | yes | check |
| cossette | Draw | Draw | yes | yes | yes | yes | check |
| d6 | yes | yes | Draw | yes | yes | yes | check |
| dart | Draw | yes | yes | yes | Draw | no | check |
| dashelite | Draw | Draw | yes | yes | yes | no | yes |
| fire | yes | yes | Draw | yes | yes | yes | check |
| horizon | yes | yes | yes | yes | yes | no | check |
| luxury | Draw | Draw | yes | yes | yes | no | yes |
| nyala | yes | yes | yes | yes | yes | no | yes |
| police | yes | Draw | yes | yes | yes | yes | yes |
| primani | Draw | Draw | yes | yes | yes | no | yes |
| race | Draw | Draw | Draw | Draw | yes | yes | check |
| rancher | yes | Draw | yes | yes | yes | yes | check |
| ranger | yes | yes | yes | yes | yes | no | yes |
| suv | Draw | Draw | yes | yes | yes | yes | check |
| taxi | yes | yes | yes | yes | yes | no | yes |
| van | yes | Draw | yes | yes | yes | yes | yes |
| wagon | yes | yes | yes | yes | yes | no | check |

Totals to draw: seat belt 7, hot 11, oil 4, high beam 1, temp gauge 1.

An existing lamp isn't necessarily a working one. Today the seat belt, oil and brake lamps only light during the key-on bulb check, and the temperature needle sits at the middle unless the engine has a warning. Wiring them to real states is Build's job once QA has tested Roadworthy.

## Odometer and trip odometer

The director wants both.

- **Today:** only dashelite draws an odometer, four small digits. The Simple dash has one as a text cell. The number is made up: a base from the car's ID plus miles driven this session.
- **Trip meter:** ZeD measures it per car for the taxi's fare, but no dash shows it, and it resets each session.
- **For design:** a place for an odometer and a trip counter on the other 18 dashes, in each dash's own style (mechanical drums on the older cars, LCD on the newer ones?), and how a trip reset is pressed, if it has one.

The idea for behavior: ZeD saves the distance on the car, so both survive between sessions, for every player, with or without Roadworthy. Not settled: the game doesn't seem to keep past mileage, so a found car needs a starting number, and this needs testing on a server.

## Rules for the art

- Dashes are made in `ZeDUI/tools/dashpx/`: edit the design, run `build.py`, then `export_lua.py`. `DashPx.lua` is generated, so never edit it by hand. The README there has the depth and lighting rules.
- Nothing that moves may travel over print.
- Each dash has day, night and dark plates, so new lamps need their night art too.
- A plate is 800 x 178 and one plate pixel is one screen pixel at 1080p.
- Every graphic surface has a Simple version. The Simple dash already has a Belt word and the other lamps, so it needs an odometer and trip cell check only.
- 1993 flashback, no modern tropes. American spelling.
- Check the Visual Catalog first.

## Questions for the director and design

1. Does a seat belt lamp belong on every dash, or only on cars from 1972 onward as Roadworthy has it? ZeD's cars are all 1993 or older, so check the oldest ones.
2. Do lamps with nothing to show stay dark when Roadworthy is off, or stay out of the art until it's on? Art is baked into plates, so dark lamps are the simple way.
3. Does the race dash get high beam and belt lamps at all?
4. Does dart get a temperature gauge, or is its hot lamp enough?
5. Odometer in miles only, or following the player's units?

## Not known yet

- QA hasn't run Roadworthy with ZeD. Whether its gauges show on ZeD's dashes, and whether ZeD can read its miles, temperature, belt and lamp states, are both untested. QA tests this once the release checks are done.
- A car from another mod falls back to the Nyala's dash, so what the Nyala gets, they get.
