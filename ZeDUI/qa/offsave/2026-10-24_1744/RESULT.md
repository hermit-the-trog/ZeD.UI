# A save made with ZeD, loaded with ZeD off, then on again (Oct 24 2026)

Asked before a public test: a tester who turns ZeD off must not lose their save.
Run by `ZeDUI/tools/qa/zedqa_offsave_run.ps1` (three launches in a 1920x1080
window, `zedqa_offsave.lua` in each) on a copy of the ZeD-QA save.

| Launch | ZeD | What was written down (`zedqa_off_<phase>.txt`) |
|---|---|---|
| before | on | 46 items carried, 9 worn, with ZeD's steel Timez watch worn on the left wrist, one more carried and one in a schoolbag |
| off | off (`ZeDQA_Probe` in its place) | 43 items, 8 worn: the three Timez watches gone, **everything else the same**; ZeD's save data (10 `ZeD_` keys) still there |
| on | on again | the same as off (the watches stay gone); ZeD's windows open; the journal, kill counts, map notes, theme and window places all read back |

- The game drops an item whose mod is off by itself and keeps loading:
  `InventoryItemFactory.CreateItem() cannot create item ... Base.WristWatch_Left_DigitalTimez,modID = "ZeD_UI" ... removed = true`,
  then `InventoryItem.loadItem() item == null, skipped bytes`. No error, no
  Lua error, the rest of the inventory and the worn clothes load.
- With ZeD off the game's own interface draws (its inventory, hotbar, left
  buttons); nothing of ZeD's is left on screen (`zqa_off_off.jpg`).
- The off launch saved the game without ZeD; the on launch loaded that save
  with ZeD and its data (`zqa_off_on_settled.jpg`; that picture was taken at
  the director's own UI scale, 1.75x, in a 1080p window, where the window pair
  does not fit side by side; the script now uses Auto, as the test runner does).
- The before launch's report reads TIMEOUT only because its manifest line had
  an `end=` the runner did not match; the script itself reached DONE (fixed).

**For testers:** turning ZeD off keeps the save. The one thing lost is any
steel Timez watch (the one item ZeD adds): it is gone for good, also after
turning ZeD back on.
