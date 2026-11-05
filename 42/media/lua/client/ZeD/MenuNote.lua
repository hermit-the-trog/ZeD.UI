-- ZeD-UI/42/media/lua/client/ZeD/MenuNote.lua
-- ============================================================================
-- THE CHANGE NOTE ON THE MAIN MENU'S CORKBOARD (the director, Nov 5 2026: "one long note, yellow paper, and it's the
-- change notes", ZeDUI/HANDOFF_main_menu_note_20261105.md). What this build changed, in five short lines: Hermit's own
-- note in the room, English on purpose, like the posters and the can (not in the translation files).
-- Up to five lines, capitals, ten characters each (longer is cut at ten; the 3 x 5 face has no lower case). Every
-- release: Build drafts them from the change note, the director approves them with the page text, and they go in here
-- before staging (RELEASE_CHECKLIST step 4b). The beta number at the top comes from the mod's version:
-- ZeD_MainMenu.lua, MM.noteHeading.
-- ============================================================================

ZeD = ZeD or {}
ZeD.MenuNote = { "SERVER TAB", "PVP MARKER", "CHAT", "ADMIN TAB", "BOX FIX" }

return ZeD.MenuNote
