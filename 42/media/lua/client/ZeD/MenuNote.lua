-- ZeD-UI/42/media/lua/client/ZeD/MenuNote.lua
-- ============================================================================
-- THE CHANGE NOTE ON THE MAIN MENU'S DESK. Client; a word list, nothing else.
-- One long note on yellow paper: what this build changed, in up to five short
-- lines. It reads as the room's own note, so it is English on purpose, like the
-- posters and the can — not in the translation files.
-- Each line shows in capitals, ten characters at most (ZeD_MainMenu.lua cuts
-- longer lines at ten; the 3 x 5 pixel face has no lower case). The lines are
-- rewritten by hand for every release from its change notes. The beta number at
-- the top is not here: ZeD_MainMenu.lua reads it off the mod's version
-- (MM.noteHeading).
-- ============================================================================

ZeD = ZeD or {}
ZeD.MenuNote = { "NOTE FIXES", "LIST SLIDE", "WIN SPOT", "DECK FIXES", "REPORTS" }

return ZeD.MenuNote
