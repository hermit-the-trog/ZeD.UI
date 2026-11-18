# Showcase captures for the 1.0 Workshop description (Nov 18 2026, Build for QA)

The 1.0 description (ZeDUI/workshop/description_1.0_draft_tables.bbcode) has four showcase graphics: a picture,
then two groups of bullets side by side, four times over. They are new graphics, not book pages. The director:
"a collage of just screenshots, or a split of two screenshots, to show what the bullet points below are talking
about. Outline stuff, highlight stuff, but not enough that you can't tell what's going on or that you don't
understand where that fits on the screen. These have to be awesome."

The director on the first prototype (Nov 18): the whole-screen shot must not be a reset UI or "just the two
inventory windows side by side". Show the UI the way it's played: windows at a real working size, tabs open, a
drawer or item card out, the belt and HUD present.

## Rules for every shot

- 4K at 1.75x, fullscreen, the gallery capture rules (no debug text or overlays, pointer hidden unless the shot is
  about the pointer, under weight, no prescription glasses, daylight unless the shot is night on purpose).
- A good-looking spot: a lived-in place with something going on, not an empty field.
- Each graphic gets ONE whole-screen "context" shot and two or three "close-up" shots of the same moment or the same
  setup, so the close-ups can be pulled from the same place on screen. Name them `sc<slot>_<what>.png`, into
  Zomboid/Screenshots/showcase/.
- Build cuts, outlines and labels them (ZeDUI/workshop/showcase/make_showcase.py); the shots only need to show it.

## 1. Two windows instead of dozens / Your stuff

Bullets: one window for the character, one for the world, tabs, an item's card in a drawer beside them; crafting,
building, cooking, fishing, foraging, farming, animals, appliances, furniture and trading rebuilt inside them;
list or grid, sort, find, stack weights, drag to select, Move To, Loot all; read marks, loadouts and outfits, a
belt with visual slots; item cards two ways (a glance, the whole card).

- `sc1_context.png`: both windows open at a real working size. Character window on a tab other than Loot with its
  drawer out (Equipment with the doll, or Health). World window looting a full container (a fridge or shelf) with
  an item's full card out in its drawer. The belt with items in its slots at the bottom.
- `sc1_grid.png`: the inventory in grid view, tinted, with stacks showing their (n) and weights, a few items
  selected by drag.
- `sc1_crafting.png`: a crafting or cooking tab open in the World window with a recipe's card.
- `sc1_glance.png`: the pointer resting on an item, its glance card showing (the pointer is the point here).

## 2. Gadgets you can hold / Know where you stand

Bullets: watches, radios, TVs, CD player, walkie-talkies as 1993 hardware; car dashboards, car radio, police
siren, seat picker; plain cards instead. Health, temperature, skills; an action bar; notes over the head; moodles
placed; foraging finds with a magnifier; the paper road map, notes, journal, guide.

- `sc2_dash.png`: driving at dusk or night, the dashboard at the foot with lights on, the car radio playing.
- `sc2_watch_radio.png`: the full watch open and a radio or TV open in the World window.
- `sc2_survival.png`: during a timed action (reading or eating): the action bar running, a note over the head,
  moodles placed at the side, the Health or Thermal tab open.
- `sc2_forage.png`: search mode with two or three magnifier pins and the pointer hand.
- (After the map branch merges: `sc2_map.png`, the Survey map on the paper look, zoomed to a town.)

## 3. Built for the controller / Made to be read

Bullets: every screen on a controller, D-pad wheels, quick chords, quick wheel; button prompts for Xbox,
PlayStation, Steam Deck, Nintendo; a button map with a live test. Dark, Light, High contrast, nine accents, two
text sizes, UI scale, colour-blind status colours, four controller highlight styles, 27 languages.

- `sc3_pad.png`: on the controller, focus on an inventory row (the pointing hand), the hint strip with button
  prompts at the foot, a D-pad wheel open.
- `sc3_buttonmap.png`: Options, Button map and test, with the drawn pad.
- `sc3_themes_dark.png`, `sc3_themes_light.png`, `sc3_themes_hicon.png`: the SAME screen and moment in each theme
  (the existing theme_* shots are the idea; one spot, three themes, for a three-way split).
- `sc3_language.png`: the same windows in another language with its own script (Japanese or Russian).

## 4. Before you play / On a server

Bullets: a 1993 desk for a main menu; a robust mod manager with conflict management, warnings, profiles, load
order, folders and more; saves, servers, sandbox. On a server: chat, admin tools, tickets, safehouse claims, mail,
community boards.

- `sc4_desk.png`: the main menu desk.
- `sc4_mods.png`: the mod manager with folders, a conflict warning showing and a profile picked.
- `sc4_server.png`: on the local server kit: chat with a few lines, and the admin or community tab open.
