# QA to Design: tell people how containers open, before they download (Nov 18 2026)

**The director (Nov 18, evening):** "Are we telling people about the inventory tab, about the physical button, and
how when that tab is activated, you have access to multiple containers around you or on you? But when you are
interacting with other parts of the world or other parts of your character... it just goes back to vanilla style
inventory. One container at a time. I think that's a little confusing at first." Then: "And tell people how it
works, what buttons to push before they download the mod. Just say you click this button and it opens this
container, and if you hold down this, it opens the second container."

Where it goes: the Workshop description, gallery chapter 9 (Containers as Columns) and the F1 guide's "moving"
page. Today none of them says the columns are on the Inventory tab only. Chapter 9 compares vanilla's one container
at a time with ZeD's columns; the guide says "Each open container is a column, side by side"; the description
draft does not mention columns. QA writes no copy: these are the facts, read from the code
(ZeD_CharacterWindow.lua `mcToggleContainer`, the container strip's click and the pad's hold; ZeD_WorldWindow.lua
the same for the World window).

## How it works (both windows the same)

**Mouse**
- The container buttons are the column of icons at the window's edge: in the Character window your bags and what
  you wear; in the World window the floor, shelves, crates, cars around you.
- **On the Inventory tab:** click a container's button and it opens as a column of its own beside the others.
  Click another and that one opens too, side by side. Click a lit button again and its column closes. No key to hold.
- **On any other tab** (Health, Crafting, Cooking, Foraging and the rest): the tab takes the room, so the columns
  close. Clicking a container's button then shows that one container alone, as the game does: one at a time.
  Clicking it again hides it.
- Back on the Inventory tab, the columns are open again for clicking.

**Controller**
- **Tap A** on a container's button: shows that container alone.
- **Hold A** on it: opens it as another column, side by side (from any tab: it switches to the Inventory tab first).

So the "hold down" in the director's words is the controller's A. With a mouse there is nothing to hold: each click
adds a column, on the Inventory tab.
