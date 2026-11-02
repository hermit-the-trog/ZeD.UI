"""The title spread, right after the cover (Nov 1 2026): the copyright page on the left, the title page on the right.

The publisher's names (the director's picks): the author Ann Sibyl; Doidbros & Buzzlord Division of Informatics
Publishing LLC. He has been at it as on the cover: Pears Software struck through with ZeD-GUI marked in under it, the
author struck through with "hermit" written in.
usage: python title_spread.py <out.png>"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import page_px as pp   # noqa: E402
import spread as S     # noqa: E402

TITLE = os.path.join(HERE, "..", "thumbnail", "fxc900.ttf")
MARKER = os.path.join(HERE, "fonts", "PermanentMarker-Regular.ttf")
RED, BLU = pp.C["red"], pp.C["blu"]


def centred(canvas, text, path, size, cx, base, col=S.PRN):
    w = S.F(path, size).getlength(text) * 2
    S.put_tok(canvas, text, path, size, cx - w / 2, base, col)
    return (cx - w / 2, cx + w / 2)


def marker_line(d, x0, x1, y, seed):
    """A stroke of the red marker through something printed: a little wavy, 6 px."""
    import random
    rng = random.Random(seed)
    pts, x = [], x0
    while x <= x1:
        pts.append((x, y + rng.uniform(-1.5, 1.5))); x += 18
    pts.append((x1, y))
    for dy in (0, 2, 4):
        pp.ink_line(d, [(px, py + dy) for px, py in pts], RED)


def main(out):
    canvas = pp.art_layer(0)[0].resize((S.OW, S.OH), Image.NEAREST).convert("RGB")
    d = ImageDraw.Draw(canvas)

    # ---- the title page (right)
    cx = (1030 + 1662) / 2
    centred(canvas, "Bitchin' znix", TITLE, 46, cx, 300)
    centred(canvas, "Programs", TITLE, 46, cx, 400)
    S.rule(d, cx - 110, cx + 110, 440, 4)
    centred(canvas, "A Guide to Learning", S.SERIF, 15, cx, 520)
    a, b = centred(canvas, "Pears Software", S.SERIF, 15, cx, 562)
    marker_line(d, a - 10, b + 10, 548, 3)
    zm = pp.mask2("ZeD-GUI", MARKER, 22)                              # marked in under it, as on the cover
    pp.put(canvas, zm, cx - zm.width / 2 + 20, 584, RED)
    pp.ink_line(d, [(cx - zm.width / 2 - 4, 618), (cx - zm.width / 2 + 8, 596), (cx - zm.width / 2 + 20, 618)], RED)
    a, b = centred(canvas, "Ann Sibyl", S.SERIF, 17, cx, 726)
    marker_line(d, a - 8, b + 8, 712, 7)
    hm = pp.mask2("hermit", pp.BALL, 19)
    pp.put(canvas, hm, b + 18, 700, BLU)
    # the publisher's device and imprint
    d.rectangle((cx - 34, 832, cx + 33, 899), outline=S.PRN, width=4)
    centred(canvas, "D&B", TITLE, 17, cx, 882)
    centred(canvas, "Doidbros & Buzzlord", S.SANS_B, 13, cx, 944)
    centred(canvas, "Division of Informatics Publishing LLC", S.SERIF, 10, cx, 974)
    centred(canvas, "Louisville, Kentucky", S.SERIF, 10, cx, 1000)

    # ---- the copyright page (left): the small print at the foot, as copyright pages set it
    c0, c1 = S.column("left")
    y = 548
    y = S.para(canvas, c0, y, c1 - c0, "Bitchin' znix Programs: A Guide to Learning Pears Software", size=10, lead=24, justify=False) + 2
    y = S.para(canvas, c0, y, c1 - c0, "by Ann Sibyl", size=10, lead=24, justify=False) + 18
    for txt in (
        "Copyright © 1993 by Doidbros & Buzzlord Division of Informatics Publishing LLC. All rights reserved. No part "
        "of this book may be reproduced, stored in a retrieval system or transmitted in any form or by any means, "
        "electronic, mechanical, photocopying, recording or otherwise, without the prior written permission of the "
        "publisher.",
        "ZNIX and Pears Software are trademarks of their respective holders. Other product names in this book are used "
        "for identification only.",
        "Limits of liability and disclaimer of warranty: the author and the publisher have used their best efforts in "
        "preparing this book and the programs in it. They make no warranty of any kind, expressed or implied, with "
        "regard to the programs or the documentation in this book.",
        "Technical review: the Doidbros & Buzzlord Docs Group.",
    ):
        y = S.para(canvas, c0, y, c1 - c0, txt, size=10, lead=24, justify=False) + 14
    y = S.para(canvas, c0, y + 8, c1 - c0, "Printed in the United States of America", size=10, lead=24, justify=False)
    S.para(canvas, c0, y, c1 - c0, "10 9 8 7 6 5 4 3 2 1", size=10, lead=24, justify=False)

    S.gutter(canvas)
    canvas.save(out)
    print("wrote", out)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "out_spread", "00_title.png"))
