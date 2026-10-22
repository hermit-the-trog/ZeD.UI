# Workshop gallery: handoff (Oct 21 2026, from the claude.ai session)

## State
- Game: running, ZeD-Shots-Kohners loaded, at the police station lobby. zedqa.lock set to free.
- Shot saves: ZeD-Shots-Plizken / -McKline / -Rosa / -Kohners. Their mods.txt were EMPTY (createWorld from
  Lua writes none), so a reload started without ZeD; all four now hold ZeD_UI (copied from ZeD-QA).
  Backups: Zomboid/zed_backups/modslist_20261021/. zedqa_new_shot_save.lua still makes an empty one:
  copy ZeD-QA/mods.txt in after creating a save (or fix the script).
- Committed: 8e5222b7 (ZeD setup page: groups, switches, swatches, scale slider, Defaults, help band).

## Shot script (ZeDUI/tools/qa/make_staged.py -> zedqa_gallery_staged.lua, now v13, not committed)
New since v7:
- here = true: shoot where the character stands (director walks it there).
- zoomTo(): counts wheel steps (0.25 per level at 4K); windows + HUD shots at 0.25, car at 1.0, put back after.
- night shot: climate NIGHT_STRENGTH 1 / DAYLIGHT 0 / GLOBAL_LIGHT 0 / AMBIENT .12 (was barely darker).
- thumbs up shot at 1000 ms (peak of the emote; it is small from the iso camera, wave/salute no better).
- pair locked: placed once, Character right edge + World left edge + tops held (they were jumping).
- frontClear(): rejects spots with anything standing on the squares in front of / beside the character.
- shot 36: Options > Interface page with a "Does nothing with ZeD active" row in the help band.
- zedqa_dress.lua (+ run_*_dress_v1.lua in Zomboid/Lua/zed_stage/ws): full gear spec, strips the random outfit.

## Open (director's notes, in order)
1. BUG in the script, not ZeD: placePair sets the World window x while its loot side is rolled up (shot 21);
   WindowCurtain.finishUnroll then moves it left by the rolled width. Fix: w:setX(L.left + (w._rolled and w._rollW or 0)).
2. "Need to show multiple containers open": the Loot tab multi-column view, both windows. The toggles are
   file-local (mcToggleWorldContainer / mcToggleContainer). Draft public wrappers, NOT deployed:
   zed_backups/settings_v2_20261021/mc/ZeD_WorldWindow.lua + ZeD_CharacterWindow.lua
   (ZeD_WorldWindow.toggleColumn(inv) / ZeD_CharacterWindow.toggleColumn(inv), appended at the end).
   Script plan: drop a duffel bag with items on the crate's square (shows as its own container), then after
   every WWm.selectContainer(X.crateInv, 150) (shots 01, 24, 30-33; selectContainer exits MC) toggle the
   crate and the bag; Character window: toggle the worn backpack. Turn it off before the card shots (02+).
3. Kohners re-shoot after 1 and 2 (residential anchors; run 2 kept in Zomboid/Screenshots/ws_* as is,
   copy to kohners_run2/ was not made).
4. McKline: re-dress (run_mckline_dress_v1.lua) and re-shoot. Then the vanilla "before" shot, re-anchor
   shots.json, page mockup v3.
- Debug coordinates print bottom right in -debug shots: keep crops clear of it.
