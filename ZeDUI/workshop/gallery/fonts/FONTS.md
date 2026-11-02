# Fonts used by the gallery pictures

| File | Family | Source | Licence |
|---|---|---|---|
| `PermanentMarker-Regular.ttf` | Permanent Marker (Font Diner) | Google Fonts | Apache License 2.0 |
| `Caveat.ttf` | Caveat (Impallari Type) | Google Fonts | SIL Open Font License 1.1 |
| `Charter-Regular.pfb`, `Charter-Bold.pfb` | Bitstream Charter (1987) | the X Window System's Type 1 fonts | Bitstream's donation to the X Consortium: free to use, copy and redistribute |
| `FiraSans-SemiBold.ttf` | Fira Sans SemiBold (Carrois and Edenspiekermann for Mozilla) | Mozilla's Fira, as on Google Fonts | SIL Open Font License 1.1 (named in the font's own metadata) |
| `FiraMono-Regular.ttf` | Fira Mono (Carrois and Edenspiekermann for Mozilla) | Mozilla's Fira, as on Google Fonts | SIL Open Font License 1.1 (named in the font's own metadata) |

All are drawn 1-bit, so nothing of the outlines ships in the pictures beyond pixels.

In the spreads (`spread.py`, `title_spread.py`): Charter sets the publisher's printed body, captions and table cells
(Charter Bold for the names on the screen); Fira Sans SemiBold sets the chapter heads, headings, figure and table labels
and page numbers; Fira Mono sets anything typed. Caveat is his ballpoint (the blue notes and the black sticky notes).
Permanent Marker is the red marker on the cover and the title page. The title face of the cover and the title page
(Fira Sans Extra Condensed Black, OFL) is `../../thumbnail/fxc900.ttf`.

The two Fira files were copied here on Nov 1 2026 from `zed_backups/fonts_for_desc`, which git ignores, so the spreads
build from a fresh checkout.
