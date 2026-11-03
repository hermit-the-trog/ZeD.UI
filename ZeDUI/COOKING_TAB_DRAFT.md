# Cooking tab: design (punch list 80, Nov 3 2026)

The director's answer to the four questions below (Nov 3 2026): "Go with your recs and we will tune it." Built
with Build's picks: the ingredients on the left with the dish in the header, saved dishes at the top of the Dish
list, a missing ingredient named with a same-kind swap offered as a press, the drinks included. No mockup first: the
director tunes it in game. Code: 42/media/lua/client/ZeD/CookingTab.lua. Source: ZeD's own Crafting tab only.

## What the game does today

The pot-and-pan dishes are the game's "evolved recipes": 62 of them, about 30 kinds (stew, soup, stir-fry, salad,
fruit salad, sandwich, burger, hot dog, taco, burrito, pizza, pie, cake, pasta, rice, omelette, oatmeal, pancakes,
waffles, toast, bagels, muffins, roasting pan, ice cream cone, and 11 drinks in cups and mugs).

- Each starts from a **base**: a pot of water, a pan, a bowl, bread slices, a bun, a tortilla, pie or cake dough, a
  cup. The first ingredient turns the base into the dish (a pot of water becomes a pot of stew).
- Each takes **3 to 6 ingredients** (a stew 6, a stir-fry 4, a pie 4). Spices go in on top and do not count.
- How much of an ingredient goes in depends on the **Cooking level**; the game says so in the menu ("(1/4)").
- Many dishes then need **cooking** (on a stove or fire). The tab builds the dish; cooking it stays where it is.
- Today it is right-click only: right-click an ingredient or the base, Create from..., one ingredient per press, each
  a short timed action. The game also offers "Add random vegetable" and the like.

## The tab (proposal)

A Character window tab, **Cooking**, shown when a base is in the inventory and an ingredient that fits it is in reach
(bags and nearby, as Crafting counts them). The same two columns, header, band and pad paths as Crafting.

- **Header:** a **Dish** select (Stew, Salad, Sandwich... only the ones a base in reach can make) and a **Base** select
  (which pot, bowl or bread, when there are several).
- **Left column: the ingredients** in reach that fit the chosen dish, each with what it gives (hunger, and the
  amount at your Cooking level, the game's own "(1/4)") and where it is. Sort (the band's pop-up, as Crafting):
  **By ingredient** (A to Z) and **By kind** (the game's own food types: vegetables, meat, fish, fruit, spices,
  condiments...). A press adds it to the dish.
- **Right column: the dish** being built: its slots ("4 of 6"), the ingredients added in order (a press takes one
  back out before Build), the spices, and what it will be (hunger, calories, unhappiness, as the game reckons them).
  A full dish greys the ingredients that no longer fit, as the game refuses them.
- **The band:** Sort and Show at the left (as Crafting); at the right **Build**, and beside it the **- n +** count
  when what is in reach makes more than one (bases and ingredients both), never more than that. Build runs the
  game's own add-ingredient actions, one after another, for each dish in turn.
- **Saved dishes:** a dish built here can be saved under a name and chosen again (see question 2).
- **The game's rules stay:** the same limits per base, the same amounts by Cooking level, the same results as by
  hand. No random add (the tab always shows what is in reach, so "Add random vegetable" has nothing to save).

## Questions for the director

1. **The left column:** the ingredients (your words: "it lists the ingredients"), with the dish picked in the header,
   as above? Or the dishes first, like Crafting's recipe list, and the ingredients in the card? *Build's pick: the
   ingredients, dish in the header.*
2. **Where saved dishes live:** at the top of the Dish select ("Your dishes": choosing one fills the slots), or as a
   pinned section at the top of the left column, like Crafting's Pinned? *Build's pick: the Dish select.*
3. **A saved dish with an ingredient not in reach:** Build greys and names what is missing, or the tab offers one of
   the same kind that is in reach ("no carrot: use a potato?") for you to accept? *Build's pick: name what is missing,
   and offer the same kind as a press you choose; it never swaps on its own.*
4. **Drinks:** the 11 drinks (coffee, tea, cocoa in cups and mugs) in the same tab, or left to right-click? *Build's
   pick: in the tab; they are the same system.*

Answered: Build's picks, all four.
