"""The container row's icons (the one-line row of buttons under each window's item list, ContainerControls.lua),
drawn in the wheels' ink. The row keeps the metaphors its first icons had (an in-tray, two sheets, arrows from a
dotted line, a bin, the power sign, a match, an extinguisher) and takes three straight from the wheels: the cog
(stove settings), the campfire (add fuel) and the shut padlock (lock the trunk).

  tray_in      Take all (World window): an arrow down into an open tray
  tray_out     Transfer all (Character window): an arrow up out of the tray
  same_type    Same type: two sheets, one over the other
  same_nearby  Same type, all nearby: arrows out both ways from a dotted line
  to_floor     To floor: an arrow down onto a dotted line
  trash        Delete all (a trash can): a bin, its lid and handle
  power        a stove's, washer's, dryer's or barbecue's switch: the power sign
  match        Light (a campfire): a struck match
  extinguisher Put out (a campfire): a fire extinguisher
"""
from kit import icon


# ------------------------------------------------------------------ the tray and its arrows
def _tray(c, s):
    """an open tray: two sides, the shoulders, the floor (the arrow's pocket between the shoulders)"""
    if s == 16:
        c.grid([".##..........##.",
                ".##..........##.",
                ".##..........##.",
                ".#####....#####.",
                ".##############.",
                ".##############."], oy=9)
    else:
        c.grid([".###................###.",
                ".###................###.",
                ".###................###.",
                ".###................###.",
                ".########......########.",
                ".########......########.",
                ".######################.",
                ".######################.",
                ".######################."], oy=14)


@icon("tray_in", "row", "an arrow down into an open tray: take all", ["IGUI_invpage_Loot_all"])
def tray_in(c, s):
    _tray(c, s)
    if s == 16: _arrow(c, s, 0, 1, False, 4, 6)
    else: _arrow(c, s, 0, 1, False, 6, 9)


@icon("tray_out", "row", "an arrow up out of the open tray: transfer all", ["IGUI_invpage_Transfer_all"])
def tray_out(c, s):
    _tray(c, s)
    if s == 16: _arrow(c, s, 0, 1, True, 4, 6)
    else: _arrow(c, s, 0, 1, True, 6, 9)


# ------------------------------------------------------------------ same type
def _sheets(c, s, ox=0, oy=0):
    """two sheets: the back one an outline, the front one solid, a clear pixel between them"""
    if s == 16:
        c.rect(ox + 1, oy + 1, 9, 9); c.rect(ox + 2, oy + 2, 7, 7, v=0)
        c.rect(ox + 4, oy + 4, 11, 11, v=0)
        c.rect(ox + 5, oy + 5, 9, 9)
    else:
        c.rect(ox + 1, oy + 1, 14, 14); c.rect(ox + 3, oy + 3, 10, 10, v=0)
        c.rect(ox + 7, oy + 7, 16, 16, v=0)
        c.rect(ox + 9, oy + 9, 14, 14)


@icon("same_type", "row", "two sheets, one over the other: the same type", ["UI_ZeD_Controls_SameType"])
def same_type(c, s):
    _sheets(c, s)


# ------------------------------------------------------------------ the dotted line: nearby, the floor
def _dots(c, s, y):
    """a dotted line across the icon at row y: 2 x 2 dots, centred, edge to edge of the live area"""
    xs = (1, 4, 7, 10, 13) if s == 16 else (2, 5, 8, 11, 14, 17, 20)
    for x in xs: c.rect(x, y, 2, 2)


def _arrow(c, s, x, y, up, head, shaft):
    """an arrow on the icon's centre line: its head `head` rows (2 px wider each row), its shaft `shaft` rows;
    (x, y) is the top left of the box it fills; s picks the shaft's width (2 at 16, 4 at 24)"""
    sw = 2 if s == 16 else 4
    cx = s // 2
    rows = []
    for i in range(head): rows.append(2 + 2 * i if s == 16 else max(2, 2 + 2 * i))
    if up:
        for i, w in enumerate(rows): c.rect(cx - w // 2, y + i, w, 1)
        c.rect(cx - sw // 2, y + head, sw, shaft)
    else:
        c.rect(cx - sw // 2, y, sw, shaft)
        for i, w in enumerate(reversed(rows)): c.rect(cx - w // 2, y + shaft + i, w, 1)


@icon("same_nearby", "row", "arrows out both ways from a dotted line: the same type, to every container nearby",
      ["UI_ZeD_Controls_SameTypeNearby"])
def same_nearby(c, s):
    if s == 16:
        _arrow(c, s, 0, 1, True, 3, 2); _dots(c, s, 7); _arrow(c, s, 0, 10, False, 3, 2)
    else:
        _arrow(c, s, 0, 1, True, 5, 3); _dots(c, s, 11); _arrow(c, s, 0, 15, False, 5, 3)


@icon("to_floor", "row", "an arrow down onto a dotted line: put it all on the floor", ["UI_ZeD_Controls_ToFloor"])
def to_floor(c, s):
    if s == 16:
        _arrow(c, s, 0, 1, False, 5, 5); _dots(c, s, 13)
    else:
        _arrow(c, s, 0, 1, False, 7, 9); _dots(c, s, 21)


# ------------------------------------------------------------------ the bin
@icon("trash", "row", "a bin, its lid and handle: delete all (a trash can)", ["IGUI_invpage_RemoveAll"])
def trash(c, s):
    if s == 16:
        c.rect(6, 1, 4, 1)                                                      # the handle
        c.rect(1, 2, 14, 2)                                                     # the lid
        c.rect(3, 5, 10, 9); c.rect(4, 14, 8, 1)                                # the can, its bottom rounded
        c.rect(6, 7, 1, 5, v=0); c.rect(9, 7, 1, 5, v=0)                        # the slots
    else:
        c.rect(8, 1, 8, 3); c.rect(10, 2, 4, 2, v=0)                        # the handle, an arch
        c.rect(1, 4, 22, 3)                                                     # the lid
        c.rect(3, 8, 18, 14); c.rect(4, 22, 16, 1)                              # the can
        for x in (6, 11, 16): c.rect(x, 11, 2, 8, v=0)                          # the slots


# ------------------------------------------------------------------ the switch
@icon("power", "row", "the power sign: switch a stove, washer, dryer or barbecue on or off",
      ["ContextMenu_Turn_On", "ContextMenu_Turn_Off"])
def power(c, s):
    if s == 16:
        c.oring(8, 8.5, 6.6, 2)
        c.rect(6, 0, 4, 7, v=0)
        c.rect(7, 1, 2, 7)
    else:
        c.oring(12, 12.5, 10.6, 3)
        c.rect(9, 0, 6, 10, v=0)
        c.rect(10.5, 1, 3, 11)


# ------------------------------------------------------------------ fire: the match, the extinguisher
@icon("match", "row", "a struck match, its flame: light a fire", ["ContextMenu_Light"])
def match(c, s):
    if s == 16:
        c.grid(["..........#.....",
                ".........##.....",
                "........####....",
                "........#.##....",
                ".......##..##...",
                ".......##.###...",
                "........####....",
                "................",
                ".......###......",
                "......####......",
                ".....###........",
                "....##..........",
                "...##...........",
                "..##............",
                ".##............."], oy=0)
    else:
        c.grid(["...............#........",
                "..............##........",
                ".............####.......",
                "............#####.......",
                "............######......",
                "...........###.####.....",
                "...........##..####.....",
                "..........###...###.....",
                "..........##....####....",
                "..........###..####.....",
                "...........#######......",
                "............#####.......",
                "........................",
                "..........#####.........",
                ".........######.........",
                "........######..........",
                ".......#####............",
                "......###...............",
                ".....###................",
                "....###.................",
                "...###..................",
                "..###...................",
                ".###....................",
                ".##....................."], oy=0)


@icon("extinguisher", "row", "a fire extinguisher, its hose and horn: put a fire out", ["UI_ZeD_Controls_PutOut"])
def extinguisher(c, s):
    if s == 16:
        c.grid(["..######........",
                "....##.......##.",
                "...####....####.",
                "...############.",
                "...####....####.",
                "..######.....##.",
                "..######........",
                "..######........",
                "..######........",
                "..######........",
                "..######........",
                "..######........",
                "..######........",
                "...####........."], oy=1)
    else:
        c.grid(["...#########............",
                "...#########............",
                ".......##...............",
                "......####..........###.",
                ".....######.......#####.",
                ".....#################..",
                ".....#################..",
                ".....######.......#####.",
                "....########........###.",
                "...##########...........",
                "...##########...........",
                "...##########...........",
                "...##########...........",
                "...##########...........",
                "...##########...........",
                "...##########...........",
                "...##########...........",
                "...##########...........",
                "...##########...........",
                "...##########...........",
                "...##########...........",
                "....########............"], oy=1)


# ------------------------------------------------------------------ the item card's marks (Fav, No-craft, Dispose)
# Dispose takes the bin above; Fav a star (vanilla marks a favourite with a star); No-craft the craft tab's tools,
# struck through (the kit's "turning a thing off strikes it through")
@icon("star", "row", "a five-point star: a favourite", ["UI_ZeD_Card_ChipFav", "IGUI_CraftUI_Favorite"])
def star(c, s):
    if s == 16:
        c.grid([".......##.......",
                ".......##.......",
                "......####......",
                "......####......",
                ".##############.",
                "..############..",
                "...##########...",
                "....########....",
                "....########....",
                "...##########...",
                "...####..####...",
                "..####....####..",
                "..##........##.."], oy=2)
    else:
        c.grid(["...........##...........",
                "..........####..........",
                "..........####..........",
                ".........######.........",
                ".........######.........",
                "........########........",
                ".######################.",
                "..####################..",
                "...##################...",
                "....################....",
                ".....##############.....",
                "......############......",
                "......############......",
                ".....##############.....",
                ".....######..######.....",
                "....######....######....",
                "....#####......#####....",
                "...#####........#####...",
                "...####..........####...",
                "..####............####..",
                "..##................##.."], oy=2)


@icon("craft_off", "row", "the hammer and wrench, struck through: not to be used in crafting",
      ["UI_ZeD_Card_ChipNoCraft", "ContextMenu_SetNoRecipes"])
def craft_off(c, s):
    import i_tabs
    i_tabs.craft(c, s)
    c.slash()
