# Check: trading and the medical check of another player (Nov 7 2026, Build for QA)

The director's B10 and B11 (VANILLA_WINDOWS_20261107.md): both are now World window cards. Trading opens ZeD's trade
card instead of the game's trading window; a medical check of another player opens ZeD's Health tab on them in the
card drawer instead of the game's health panel. Nothing here was run in game. The sim
(`lua51 ZeDUI/tools/qa/trade_medic_sim.lua`, 149 checks) runs the game's own ISTradingUI, ISHealthPanel and
ISMedicalCheckAction files against ZeD's code; it cannot show what the engine does with real packets, fonts and focus.
That is this check.

Files: `client/ZeD/ZeD_Trade.lua`, `ObjectCardTrade.lua`, `ObjectCardMedic.lua`, `Overrides/TradeMedic.lua`, with small
additions to `ObjectCards.lua` (a band of a card's own buttons, a pixel icon in the header, a card that stays open in
a car) and `HealthTab.lua` (read another player's body at the doctor's First Aid level; the treatment menu for another
patient).

## Setup

Two real players on the local server kit, as `batch_two_b7.ps1` does it:

- `mp_server.ps1 -Start` (ZeD_UI), the main client with `zedqa_run.ps1 -Mp` (the admin), the second client with
  `mp_client2.ps1` (bob, profile `zedqa_p2`). `ZEDQA_NOSTEAM=1`. Zombies off. Check `Lua/zedqa.lock` first.
- Stand the two characters next to each other at the drag strip (ZEDQA_HOME). Give the admin: an apple, a stack of
  nails (5 or more), a jacket worn, a knife in hand, a watch marked favorite, a bandage in a backpack, a bandage and
  ripped sheets in the main inventory, First Aid 0 at first. Give bob a deep wound on the left hand (admin's Cheat
  menu from the game's own health panel in safe mode, or debug) and a few items to offer.
- Sizes: 4K fullscreen at 1.75x first, then Deck (1280x800, Auto UI scale, Normal and Large text).
- Mouse first, then the whole run again on a controller (the admin's client on the pad).

## Trade

1. **Ask.** Admin right-clicks bob: "Trade with bob". Expect the World window to open (if shut) with the trade card in
   its drawer: swap icon, "Trade with bob", a yellow **Waiting** tag, a red warning box "Waiting for bob's answer.",
   Seal offer grayed, Cancel reading **Close**, Accept deal grayed. Hover Add on any row: the help line repeats the
   waiting line. Right-click the world: the game's "Can't use inventory context menu while trading." only.
2. **Bob's prompt.** On bob's screen: the ZeD prompt "admin wants to trade. Accept?" with No and Yes. Press Yes.
   Expect bob's World window to open on the same card (no waiting box), and the admin's box to go.
3. **The lists.** Admin's card: "Your offer 0 / 20" at the left, "bob's offer 0 / 20" at the right, each "Nothing
   offered yet."; under them **Main inventory** with the apple, "Nails (5)" with Add all and Add, the bandage and the
   sheets. Not listed: the jacket, the knife, the watch, the backpack's bandage.
4. **Add.** Add the apple, then Add all on the nails. Expect them under Your offer with Remove buttons, and on bob's
   card under "admin's offer" (read only), with "admin added Nails to their offer." in bob's line and his Trade Log.
   The count reads 6 / 20.
5. **Rules.** In the debug console or by moving items: put an offered nail into the backpack: it comes off the offer
   on both screens. Add up to 20 items: the 21st Add is grayed and says "Can't add more than 20 items to an offer."
6. **Seal.** Admin ticks Seal offer: "You have sealed your offer." under Your offer, Remove and Add gray out (their
   help says why); bob sees "admin sealed their offer". Accept deal stays grayed, its help "Both offers must be sealed
   before the trade can be accepted."
7. **A change unseals.** Bob adds an item. Admin's Seal offer unticks by itself, the line "bob added X to their offer."
   shows, and the log at the foot of the card lists it (newest first).
8. **Accept.** Both seal; the admin's tag turns green **Ready** and Accept deal lights. Press it. Expect both cards to
   close and the items to swap in both inventories (the server moves them). Check both inventories after a rejoin too.
9. **Distance.** Start a new trade, then walk bob 3 tiles away: the red box "Too far away from bob!" on the admin's
   card, every control but Close grayed. Walk back: it clears.
10. **Cancel and close.** Start one, press Cancel: bob's card shows "admin closed their trading window." with Close.
    Start one, press the card's close key (X): the same on bob's side. Start one and close the whole World window:
    within a few frames bob's card shows the same (the trade ended). Start one and click an item in the admin's
    inventory so its item card replaces the trade card: the trade ends the same way (see the design question).
11. **No.** Bob answers No: the admin's box reads "bob refused to trade with you." and Close.
12. **Bob gives up first.** Admin asks, then closes the card before bob answers: bob's prompt goes away by itself.
13. **Safe mode.** Turn Safe mode on and trade: the game's own trading window, on both sides as usual.

Controller (admin on the pad): the card takes the focus when it opens, on the first Add (on Close while blocked). The
D-pad walks Add / Add all / Remove and the band (Seal offer, Cancel, Accept deal); A presses; B is Cancel (it closes
the card and ends the trade). Check nothing is a dead stop, and that the focus comes back to the inventory after.

## Medical check

1. **Ask.** Admin right-clicks bob: Medical Check. Bob's screen: the ZeD prompt "admin wants to perform a medical check
   on you. Accept?". Yes. The admin's character does the check animation (the game's own timed action).
2. **The card.** At its end the admin's World window shows the medical check card: stethoscope icon, "bob's Health",
   a tag with bob's overall health in its color. The body figure colored by health, the summary at its right (Overall,
   the bar, "1 of 17 parts injured", no pain line at First Aid 0), the injury list under it with the left hand first,
   "Deep wound" without a severity word. No game health panel opens.
3. **Doctor level.** Give the admin First Aid 5, do the check again: "Deep wound (Severe)" or "(Moderate)", and bob's
   pain ("Pain", "Severe Pain") in the summary.
4. **Hover and focus.** Hover a figure part or an injury row: the right column shows that part (health, its tags).
5. **Treat.** Click the left hand's row (or the hand on the figure): the game's treatment menu at the pointer, with
   Bandage (from the admin's main inventory), Disinfect, Stitch if he has the tools. Bandage: the admin bandages bob's
   hand with the game's own action; the row turns to "Bandaged" within a second or two on the admin's card, and bob's
   own Health tab shows the bandage. Try Remove bandage too.
6. **Paused.** Pause (single player only, below): clicking a part does nothing.
7. **Closing.** Either character takes a step: the card closes (vanilla's rule). As an admin with the right to check
   from afar (the role's CanMedicalCheat), walk 3 tiles: the card stays with the red "Too far away from bob!" in the
   band and no list; walk back and it fills again. Two players in one car: the check works and stays open while the car
   moves.
8. **Split screen and single player.** A split-screen game with two local players: the second player asks the first
   for a medical check (the first answers Yes on the prompt). The card opens on the World window if it is the doctor's;
   if the World window belongs to the other player, the game's own health panel opens (expected).
9. **Safe mode.** The game's own health panel.

Controller: the card opens on the worst injury's row; the D-pad walks the figure's parts and the rows; A opens the
treatment menu (the game's, focused); B closes the card.

## What to look at in the pictures

- 4K: the two offer columns side by side, nothing cut; long item names end in "..." before the Remove button; the band
  holds the check and both buttons with room between.
- Deck, Normal and Large text: the same, and the card scrolls as one with the band fixed at the foot. Note any
  overlap between the Seal offer words and Cancel at Large text.
- Medical card at Deck: the figure and the summary side by side; with Large text the summary wraps under it cleanly.

## Untested by the sim (only the game can show it)

The real packets (that the server moves the items on Accept deal, and the order the add and seal events arrive in),
the Java context menu hiding "Trade with" while a ZeD trade is open, the game's transfer action waiting while the trade
is open, the remote body updates arriving after startReceivingBodyDamageUpdates, the treatment menu's position and
controller focus, and font widths.
