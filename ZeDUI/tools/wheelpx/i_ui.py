"""The windows' own small controls, drawn in the wheels' ink to replace the last licensed pictures outside the
right-click menu: the view toggles (list, grid), fold and unfold, pop out, move up and down, the pencil, the
prompt's stop mark. (The chevrons for folds, back and scrolling are drawn by the code itself at their own size,
AtomExtensions._drawArrow: they are smaller than 16 wherever they show.) Taken from the wheels as they are: stand (the
doll view), no (delete a row), car_exit (the seat chooser's doors), help (a question), info (a note), star (a
favourite mod, i_row).

  view_list    a list: List view (containers, the equipment tab, the maps side list, the appearance tab)
  view_grid    four tiles: Grid / Pictures view
  expand       four corners pointing out: unfold to a window (maps, radio)
  contract     four corners pointing in: fold back
  pop_out      an arrow out of a frame: pop the station out
  move_up      an arrow up: move a block up (the Workshop description editor)
  move_down    an arrow down: move a block down
  pencil       a pencil: draw on the map
  stop         an octagon with a bar: the prompt's stop (a costly step)
"""
from kit import icon
from i_row import _arrow


@icon("view_list", "ui", "three lines with their bullets: list view", ["list"])
def view_list(c, s):
    if s == 16:
        for y in (2, 7, 12): c.rect(1, y, 2, 2); c.rect(5, y, 10, 2)
    else:
        for y in (2, 10, 18): c.rect(1, y, 4, 4); c.rect(8, y, 15, 4)


@icon("view_grid", "ui", "four tiles: grid view, pictures", ["apps"])
def view_grid(c, s):
    if s == 16:
        for x in (1, 9):
            for y in (1, 9): c.rect(x, y, 6, 6)
    else:
        for x in (1, 13):
            for y in (1, 13): c.rect(x, y, 10, 10)


def _corners(c, s, out):
    """four L-shaped corners: at the icon's corners pointing out (out=True), or near the middle pointing in"""
    n = s; t = 2 if s == 16 else 3; L = 5 if s == 16 else 8
    if out:
        a, b = 1, n - 1
        c.rect(a, a, L, t); c.rect(a, a, t, L)
        c.rect(b - L, a, L, t); c.rect(b - t, a, t, L)
        c.rect(a, b - t, L, t); c.rect(a, b - L, t, L)
        c.rect(b - L, b - t, L, t); c.rect(b - t, b - L, t, L)
    else:
        p, q = (6, 10) if s == 16 else (9, 15)       # the inner corners' places: a clear square between them
        c.rect(p - L, p - t, L, t); c.rect(p - t, p - L, t, L)                 # top left, its corner inward
        c.rect(q, p - t, L, t); c.rect(q, p - L, t, L)                         # top right
        c.rect(p - L, q, L, t); c.rect(p - t, q, t, L)                         # bottom left
        c.rect(q, q, L, t); c.rect(q, q, t, L)                                 # bottom right


@icon("expand", "ui", "four corners pointing out: unfold to a window", ["expand"])
def expand(c, s):
    _corners(c, s, True)


@icon("contract", "ui", "four corners pointing in: fold back", ["contract"])
def contract(c, s):
    _corners(c, s, False)


@icon("pop_out", "ui", "an arrow out of a frame's corner: pop out", ["arrow-up-right-from-square"])
def pop_out(c, s):
    if s == 16:
        c.rect(1, 4, 11, 11); c.rect(3, 6, 7, 7, v=0)                         # the frame
        c.rect(7, 1, 8, 8, v=0)                                               # its corner cut away
        c.rect(9, 1, 6, 2); c.rect(13, 1, 2, 6)                               # the arrow's head
        c.line([(6.5, 9.5), (13, 3)], 1.9)
    else:
        c.rect(1, 6, 17, 17); c.rect(4, 9, 11, 11, v=0)
        c.rect(10, 1, 13, 13, v=0)
        c.rect(13, 1, 10, 3); c.rect(20, 1, 3, 10)
        c.line([(9.5, 14.5), (20, 4)], 2.8)


@icon("move_up", "ui", "an arrow up: move it up", ["arrow-up"])
def move_up(c, s):
    if s == 16: _arrow(c, s, 0, 1, True, 6, 8)
    else: _arrow(c, s, 0, 1, True, 9, 13)


@icon("move_down", "ui", "an arrow down: move it down", ["arrow-down"])
def move_down(c, s):
    if s == 16: _arrow(c, s, 0, 1, False, 6, 8)
    else: _arrow(c, s, 0, 1, False, 9, 13)


@icon("pencil", "ui", "a pencil, its point down left: draw, edit", ["edit"])
def pencil(c, s):
    if s == 16:
        c.grid(["...........##...",
                "..........####..",
                ".........#..###.",
                "........#....##.",
                ".......####.#...",
                "......######....",
                ".....######.....",
                "....######......",
                "...######.......",
                "..######........",
                "..#####.........",
                ".##.##..........",
                ".###............",
                ".##............."], oy=1)
    else:
        c.grid(["................###.....",
                "...............#####....",
                "..............#######...",
                ".............#...#####..",
                "............#.....####..",
                "...........###....###...",
                "..........#####..##.....",
                ".........########.......",
                "........########........",
                ".......########.........",
                "......########..........",
                ".....########...........",
                "....########............",
                "...########.............",
                "...#######..............",
                "..##..###...............",
                "..###...................",
                ".####...................",
                ".###....................",
                ".##....................."], oy=2)


@icon("stop", "ui", "an octagon with a bar cut out: stop, a costly step", ["octagon-minus"])
def stop(c, s):
    if s == 16:
        c.grid([".....######.....",
                "....########....",
                "...##########...",
                "..############..",
                ".##############.",
                ".##############.",
                ".##############.",
                ".##############.",
                ".##############.",
                ".##############.",
                "..############..",
                "...##########...",
                "....########....",
                ".....######....."], oy=1)
        c.rect(4, 7, 8, 2, v=0)
    else:
        c.poly([(8, 1), (16, 1), (23, 8), (23, 16), (16, 23), (8, 23), (1, 16), (1, 8)])
        c.rect(5, 10.5, 14, 3, v=0)
