#!/usr/bin/env python3
"""Check the desk the way the game shows it at 1920 x 1080: the picture at 4x, the screen's contents taken from a capture.

    python preview.py desk.png capture_1920x1080.png out.png
"""
import sys
import numpy as np
from PIL import Image

desk, capture, out = sys.argv[1:4]
d = np.asarray(Image.open(desk).convert("RGB").resize((1920, 1080), Image.NEAREST)).copy()
c = np.asarray(Image.open(capture).convert("RGB"))
d[120:840, 480:1440] = c[120:840, 480:1440]          # the tube (120,30 240x180 at 4x): what the game draws there
Image.fromarray(d).save(out)
