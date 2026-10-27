HEAD = """<header>
<div class="banner">ZeD-UI | belt | Oct 27 2026</div>
<h1>Belt hands together</h1>
<p class="lede">The two hand circles move next to each other on the belt, so an item held in both hands can join them into one shape with one condition track. Below: the belt as it is now, then two places for the pair. Every picture is cut from a 4K capture of the game at 1.75x. The joined shape is drawn with the belt's own pixel rules but isn't in the game yet.</p>
</header>"""

panel(("t", "Today"), "Hands at the two ends",
      "The off hand sits at the left end and the main hand at the right end, with the slots between them. When one item is held in both hands, the main hand shows it with its condition ring and the off hand shows a faded copy marked Both.",
      [("A kitchen knife at 50 per cent in the off hand, a claw hammer at 80 per cent in the main hand.", "today_two.png", "Today's belt with a knife and a hammer"),
       ("The hammer held in both hands.", "today_both.png", "Today's belt with the hammer in both hands")])

panel(("r", "Recommended"), "Together at the right end",
      "The main hand stays where it is, and the off hand moves in beside it, 6 units apart. The ammo pouch and a watch on the right wrist stay next to the main hand. A watch on the left wrist sits between the strap and the off hand.",
      [("Two items: two circles side by side.", "right_two.png", "Hands together at the right end, two items"),
       ("One item in both hands: the circles join into one shape with one framed condition track, filling clockwise from the top centre. It splits back into two circles when the item leaves a hand.", "right_both.png", "Hands together at the right end, the hammer in both hands")])

panel(("a", "Alternative"), "Together at the left end",
      "The off hand stays at the left end, and the main hand moves across the belt to sit beside it. The ammo pouch and a watch on the right wrist move with the main hand, between the pair and the strap.",
      [("Two items.", "left_two.png", "Hands together at the left end, two items"),
       ("One item in both hands.", "left_both.png", "Hands together at the left end, the hammer in both hands")])

FOOT = """<section class="notes">
<h2>Either way</h2>
<p><b>Seen from behind, as today.</b> The off hand is the left circle of the pair and the main hand the right one.</p>
<p><b>Dragging onto the joined shape.</b> The left half takes the item into the off hand and the right half into the main hand.</p>
<p><b>Controller.</b> The belt still starts on the first slot. At the right end, Right from the last slot reaches the off hand, then the main hand. At the left end, Left from the first slot reaches the main hand, then the off hand.</p>
<p><b>Why the right end.</b> Only the off hand moves. The main hand keeps its place on screen, where weapons and guns go, with the ammo pouch beside it.</p>
</section>"""
