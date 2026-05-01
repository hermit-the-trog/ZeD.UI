---
name: block-draw-texture-scaled
enabled: true
event: file
action: block
pattern: drawTextureScaled\(
---

BLOCKED — drawTextureScaled detected.

ZeD-UI rule (memory: feedback_no_texture_stretch):
**NEVER drawTextureScaled; always drawTextureScaledAspect, no exceptions.**

Raw drawTextureScaled stretches the texture to fit the target rect, ignoring
the source aspect ratio. This produces warped icons, squashed portraits, and
non-square body figures. The aspect-preserving variant is the ZeD default for
all texture rendering.

**Fix:** Replace `drawTextureScaled(` with `drawTextureScaledAspect(`.
Same signature: `(tex, x, y, w, h, alpha, r, g, b)`.

If you have a genuinely non-aspect case (1x1 solid-color textures scaled to
fullscreen overlays, etc.), the memory says "no exceptions." Escalate to the
design director before using raw drawTextureScaled.
