# Build to QA (Mac), Nov 12 2026

From the cloud Build session, answering "QA ZeD-GUI MAC". Build moves to a local session on the PC next; this file
carries what you asked.

**Install main from now on.** PR #5 (beta 11's last fixes) merged Nov 11 and beta 11 shipped. Main is 0.3.0-beta12.
`claude/keen-meitner-optdjj` now sits on main plus this note, so its tip installs beta 12 too.

**The gallery shoot (B11_RECAPTURE.md):** the PC finished a full beta 12 gallery on Nov 11-12, 80 pictures in
`ZeDUI/workshop/gallery/upload_b12` (plan v2, `PLAN_ALTERNATE_20261111.md`, director-approved). So the paused Mac shoot
looks superseded. **Ask the director before shooting more.** Build hasn't changed `gallery_v3_zed.lua`'s staging for that
reason.

**Chinese in the speech balloon (158, "状态" drops out):** not the font file. ZeD's Noto Sans SC (`sdf/notoSC.fnt`) has
状 (U+72B6) and 态 (U+6001), on atlas pages 2 and 3 with pixels where the .fnt says, the same as 搜, 刮, 剩 and 余.
To tell whether the line loses them before drawing or while drawing, please send, with the balloon up after
`p:Say("搜刮状态")`:
- `ZeD.Bubbles._sp[0].text` and each of `ZeD.Bubbles._sp[0].lines`, printed with `string.len` and
  `string.byte(s, 1, -1)` (the codes, not the glyphs);
- `getTextManager():MeasureStringX(UIFont.Cred1, "状")` and the same for "搜";
- `ZeD.Text.scriptFont("搜刮状态")` (nil, false or a table) and, if a table, its `.font`.
If `.text` already lacks 状态, the cut is before the balloon (the engine's say line or `B.clean`); if it has them and
the measures are > 0, the cut is in the draw.

**159, the notebook over the World window:** the reader (notebook, flyer) opens centred over everything, like the
game's own journal window. That's by design, not a jump. Making it keep clear of other windows is a design change for
the director.

**Open on GitHub:** PR #6, console Phases 3 and 4 (`console-phases-3-4`). The sims pass on main; it waits on the
director's merge.
