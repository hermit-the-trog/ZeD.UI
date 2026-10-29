# Stack weight in brackets (Oct 29 2026)

4K fullscreen at 1.75x, daylight at the drag strip, cropped to the two windows (from `zedqa_wt_bracket.lua`,
run of `wt_bracket.txt`, report `../regression/2026-10-29_wt_bracket_4k_3.md`). Five oranges in the bag, five
apples and a saucepan on the ground.

A stack's row shows its total weight in brackets, "(1.0)"; open the stack and each row under it shows its own,
"0.2"; a single item shows its own, "0.7". The bracket takes its room from the name, so the list keeps Category
and Condition at the default window width. Sorting by weight puts a stack by its total.

1. `1_small_list.jpg` - the lists at Small: Orange x5 "(1.0)", Nails x6 "(0.3)", Plank x3 "(9.0)".
2. `2_open_stack.jpg` - both stacks opened: the row keeps "(1.0)", the four under it "0.2" each.
3. `3_narrow_wt.jpg` - the Character list's weight column dragged to its narrowest: totals drop the decimal, "(1)".
4. `4_small_grid.jpg` - the grid at Small: a stack's corner "(1.0)", a single's "0.7" (the grid opens no stacks).
5. `5_large_list.jpg` - the lists at Large text.
6. `6_large_grid.jpg` - the grid at Large text.
7. `7_two_columns.jpg` - the bag beside a worn pack (two columns side by side): "(1.0)".
8. `8_two_columns_large.jpg` - two columns at Large text, the tightest case: totals drop the decimal, "(1)", "(9)".
