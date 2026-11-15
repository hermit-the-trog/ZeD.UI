# Controller report, Nov 14 2026

For the director, after the controller playtests. Plain words; the detail for Build is in punch list 228.

## Where we stand

- **Fixed and confirmed today, on the controller:**
  - Place item with A
  - Bumpers step through each window's tabs
  - Start pauses with the inventory open; Y in the pause menu no longer drops the pad
  - Death screen and respawn take the pad
  - A opens doors and windows
  - Filter keyboard types, and B closes it
  - TV tab says Television
  - Title-bar menu reachable, with its selection ring
  - Right from the bag strip lands on Ground
  - X menu closes when you walk away
  - Sort and Show pull-ups readable
  - Reading papers
  - Cooking bar on the row
  - Queued actions
- **Built tonight, not yet tried by you:**
  - X moves an item to the other window
  - A on food opens the card; hold A to eat
  - Keyboards ask before closing, and B saves
  - The item tooltip shows on the pad's selected row
  - Desk navigation
- **The test of every tab:** I pressed every direction from every stop on all 14 tabs of both windows. No dead ends, no unreachable stops. The basic grid is sound; the trouble is in the edges: pop-ups, menus, keyboards and dials.

## The six patterns behind today's bugs, and where they still hide

1. **The pad left on something you can't see.** A keyboard, prompt or menu opens or closes without handing the pad over and back. This was the desk note, Safe mode and the bumpers out of step. **Still there:**
   - Y opens the windows over other pop-ups (the X menu, the oven pop-out, the reader, the car radio, Messages and more), leaving those pop-ups unselectable.
   - Aiming can strand a keyboard or prompt. The keyboard also freezes your character in place.
   - ZeD's X menus don't hand the pad back to what opened them. The belt and the car radio lose it.
   - The list style of the X menu (an option in setup) misses today's "close when you walk away" fix.
2. **Things on screen you can't reach.** Like the title-bar menu and the desk. **Still there:**
   - The Character window's Radio tab has the World window's old bug: pick up a radio while the windows are open, and you can't reach the tab.
   - Every other ZeD window (Messages, chat, reader, guide, controller map, Lua console, oven pop-out, map) has a title-bar menu the pad can't reach.
   - Chat's name color can't be changed on a controller at all.
3. **Directions that surprise you.** Like the oven pop-out. **Still there:**
   - Radio knobs turn with Up/Down on some faces and Left/Right on others, and Up/Down knobs block moving past them.
   - The lock's combination dials trap Up/Down.
   - The car radio's knob direction changes with its look.
4. **Game code that only works with a mouse.** Like Place item. **Still there:** furniture moves started from a menu (Pick up, Place, Rotate, Scrap) can lose A the same way Place item did. No other game code is hooked too early.
5. **Only one way in** (your two-ways rule). **Still there:**
   - Copy bug report and the controller map are only on the wheel.
   - The window placement choices (reset, save position) are only in the title-bar menu.
6. **One tap doing something you can't undo.** Like eating raw food. **Still there:**
   - A, A on a bottle drinks it: bleach, gasoline or dirty water in two quick taps. Drink should be a hold, like Eat.
   - "Use" on drainables is a tap too.

## A proposed button grammar (yours to change)

The idea is one meaning per button, everywhere, the way well-loved controller games do it (Baldur's Gate 3, Diablo IV, Stardew Valley, Destiny 2, The Witcher 3).

| Button | Tap | Hold |
|---|---|---|
| A | Select or open. Never consumes or destroys. | The main use of the thing (eat, drink, equip, use) |
| B | Back out one level, keeping your work | Close everything back to the game |
| X | Move it across (grab, drop, put in) | Quick use, or the whole stack |
| Y | Open or close the windows (today) | Close the windows (today) |
| LB / RB | Previous or next tab in this window | Step back through tabs |
| LT / RT | Sub-pages, or page through a long list | — |
| D-pad | Move the selection; never acts | Repeat the move |

Rules that go with it:

- The selection never disappears, and the hint strip always shows what each button does right now.
- Resting on a row shows its tooltip, as the mouse hover does.
- Every pop-up takes the pad when it opens and gives it back to what opened it when it closes.
- Every window has the same edges: Up from the top reaches its title bar, and Left/Right off the side reaches the next window.
- Knobs and dials all turn the same way (Left/Right), so Up/Down always moves.

**A choice for you on Y:** today Y opens and closes the windows. Some games use Y for "more about this thing" (details, or the full menu). We can keep Y as it is, which I recommend since it's learned already, and put "more" on hold A or on the card's More button (227). Or we can move things around. Your call.

## Is a controller as quick as a mouse?

Not for shuffling dozens of items, and probably never quite. For everyday play it can get very close if:

- every common action is one press, with the bigger version on a hold
- moving between the two windows is one press (X)
- the pad never makes you go back and find where you were

Today's fixes moved a long way in that direction. The patterns above are the remaining rough edges.
