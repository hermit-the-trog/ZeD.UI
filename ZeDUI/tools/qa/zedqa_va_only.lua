-- ZeDUI/tools/qa/zedqa_va_only.lua  (Oct 20 2026)
-- One line before zedqa_visual_audit.lua in a manifest: sets the targeted-run globals the audit reads at
-- its top (see its header). Edit the two strings for the sections and base themes you want; take the line
-- out of the manifest (or set ZEDQA_VA_ONLY = nil) for the whole walk. Changes nothing in the game.
-- DONE is printed from a later tick, as the runner wants. grep "ZEDQA vao".
ZEDQA_VA_ONLY = "mc,list"
ZEDQA_VA_BASES = "dark,light"
local function onTick()
    Events.OnTick.Remove(onTick)
    print("ZEDQA vao DONE only=" .. tostring(ZEDQA_VA_ONLY) .. " bases=" .. tostring(ZEDQA_VA_BASES))
end
Events.OnTick.Add(onTick)
