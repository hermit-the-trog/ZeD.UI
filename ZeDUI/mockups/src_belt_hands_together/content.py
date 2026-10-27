HEAD = """<header>
<div class="banner">ZeD-UI | belt | Oct 27 2026</div>
<h1>Belt hands together</h1>
<p class="lede">The two hand circles move next to each other on the belt. As in the vanilla game, the main hand is bigger than the off hand: 56 units against 44, the size of a belt slot (vanilla draws the off hand at three quarters of the main; today both are 52). When one item is held in both hands, the main hand keeps its circle and its condition ring, and the off hand slides in behind it, peeking out 14 units. Below: the belt as it is now, then two places for the pair. The strap, slots and item pictures are cut from a 4K capture of the game at 1.75x, the knife scaled down for the smaller hand. The resized hands are drawn with the belt's own pixel rules but aren't in the game yet.</p>
</header>"""

panel(("t", "Today"), "Hands at the two ends",
      "The off hand sits at the left end and the main hand at the right end, with the slots between them. When one item is held in both hands, the main hand shows it with its condition ring and the off hand shows a faded copy marked Both.",
      [("A kitchen knife at 50 per cent in the off hand, a claw hammer at 80 per cent in the main hand.", "today_two.png", "Today's belt with a knife and a hammer"),
       ("The hammer held in both hands.", "today_both.png", "Today's belt with the hammer in both hands")])

panel(("r", "Recommended"), "Together at the left end",
      "The off hand stays at the left end, and the main hand moves across the belt to sit beside it, 6 units apart. The ammo pouch and a watch on the right wrist move with the main hand, between the pair and the strap.",
      [("Two items: the smaller off hand at the end, the bigger main hand next to the strap.", "left_two_v3.png", "Hands together at the left end, two items"),
       ("One item in both hands: the off hand slides in behind the main hand and peeks out at the end of the belt. The belt ends 36 units sooner on the left; nothing else moves.", "left_both_v3.png", "Hands together at the left end, the hammer in both hands, the off hand peeking from behind")])

panel(("a", "Alternative"), "Together at the right end",
      "The main hand stays where it is, and the off hand moves in beside it, 6 units apart. The ammo pouch and a watch on the right wrist stay next to the main hand. A watch on the left wrist sits between the strap and the off hand.",
      [("Two items.", "right_two_v3.png", "Hands together at the right end, two items"),
       ("One item in both hands: the off hand slides in behind the main hand and peeks out on the strap side, leaving 36 empty units between the strap and the hands.", "right_both_v3.png", "Hands together at the right end, the hammer in both hands, the off hand peeking from behind")])

FOOT = """<section class="notes">
<h2>Either way</h2>
<p><b>Seen from behind, as today.</b> The off hand is the left circle of the pair and the main hand the right one.</p>
<p><b>One item in both hands.</b> The off hand shows no picture and no ring of its own; the item and its condition are on the main hand. It slides back out when the item leaves a hand.</p>
<p><b>Dragging.</b> Onto the main hand's circle puts the item in the main hand; onto the peeking off hand, in the off hand.</p>
<p><b>Controller.</b> The belt still starts on the first slot. At the left end, Left from the first slot reaches the main hand, then the off hand. At the right end, Right from the last slot reaches the off hand, then the main hand. The peeking off hand is still a stop.</p>
<p><b>Sizes.</b> The belt grows 4 units taller, to the main hand's 56; the slots and the strap stay centred on it. The off hand's picture is 28 units, as a slot's is.</p>
<p><b>Why the left end now.</b> The belt is placed by its buckle, so at the left end the off hand can slide behind without moving anything else; the belt only ends sooner. At the right end, the main hand keeps its place but a gap opens beside the strap every time an item is held in both hands. Closing that gap would move the main hand, the ammo pouch and the watch instead.</p>
</section>"""
