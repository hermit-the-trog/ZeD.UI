"""The animal's wheel (vanilla ISAnimalContextMenu's radial): kill (the knife), pick up (a figure, in i_fig), milk,
pet, lead on a rope, shear, the animal's info (in i_sym)"""
import math

from kit import icon


@icon("milk", "animal", "a milk bottle: milk the animal", ["ContextMenu_Milk", "AnimalActions_Milk"])
def milk(c, s):
    if s == 16:
        c.grid(["....######....",
                "....######....",
                ".....####.....",
                "....######....",
                "...########...",
                "..##########..",
                "..##########..",
                "..#........#..",
                "..#........#..",
                "..##########..",
                "..##########..",
                "..##########..",
                "...########..."], ox=1, oy=1)
    else:
        c.rect(7, 1, 10, 3); c.rect(8.5, 4, 7, 2.5)                            # the cap, the neck
        c.poly([(8.5, 6.5), (15.5, 6.5), (19.5, 10.5), (4.5, 10.5)])           # the shoulder
        c.rrect(4.5, 10, 15, 13, 2)
        c.rect(6.5, 13, 11, 4, v=0)                                            # the label


@icon("pet", "animal", "an open hand and a heart: pet the animal", ["ContextMenu_PetAnimal", "AnimalActions_Pet"])
def pet(c, s):
    if s == 16:
        c.grid([".#.#.",
                "#####",
                "#####",
                ".###.",
                "..#.."], ox=10, oy=1)
        c.grid(["....#.....",
                "..#.#.#...",
                "..#.#.#.#.",
                "..#.#.#.#.",
                "..#.#.#.#.",
                "..#######.",
                "#.#######.",
                "##########",
                ".#########",
                "..#######.",
                "...#####.."], ox=1, oy=4)
    else:
        c.circle(17.2, 3.6, 2.6); c.circle(21.2, 3.6, 2.6); c.poly([(14.7, 4.4), (23.7, 4.4), (19.2, 9.2)])
        for x, top in ((4.5, 8.5), (8, 6.5), (11.5, 7.5), (15, 10)):
            c.line([(x, top), (x, 15)], 2.6)
        c.rrect(3.2, 13.5, 13.2, 9, 3)
        c.line([(4.2, 20), (2, 16.5), (1.4, 13.5)], 2.6)


@icon("rope", "animal", "a lasso, its loop and knot: lead the animal on a rope, or let it go", ["ContextMenu_AttachAnimal", "ContextMenu_DetachAnimal", "AnimalActions_Rope"])
def rope(c, s):
    if s == 16:
        c.grid(["......#######...",
                "....##.......##.",
                "...#...........#",
                "...#...........#",
                "....##.......##.",
                "......###.###...",
                "........###.....",
                "........###.....",
                ".......#........",
                "......#.........",
                ".....#..........",
                "......#.........",
                ".......#........",
                "......#.........",
                ".....#.........."], oy=1)
    else:
        c.ellipse(14, 6.5, 9, 5.2); c.ellipse(14, 6.5, 7, 3.4, v=0)
        c.rrect(11.5, 10.5, 4.5, 4, 1)                                          # the knot
        c.line([(12.5, 14.5), (10, 17), (12, 19.5), (9, 22.5)], 2)


@icon("scissors", "animal", "shears: shear the animal", ["ContextMenu_Shear", "AnimalActions_Shear"])
def scissors(c, s):
    if s == 16:
        c.line([(8, 9), (3.5, 1.5)], 1.6); c.line([(8, 9), (12.5, 1.5)], 1.6)
        c.oring(4.5, 12, 2.6, 1); c.oring(11.5, 12, 2.6, 1)
        c.line([(8, 8.5), (6.2, 10.6)], 1.2); c.line([(8, 8.5), (9.8, 10.6)], 1.2)
    else:
        c.poly([(15.2, 16), (4.2, 1), (6.2, 1), (16.8, 14.5)])                   # a blade, through the pivot
        c.poly([(8.8, 16), (19.8, 1), (17.8, 1), (7.2, 14.5)])
        c.ring(6.5, 19, 4, 2); c.ring(17.5, 19, 4, 2)
        c.dot(12, 11.5, 1.2, v=0)
