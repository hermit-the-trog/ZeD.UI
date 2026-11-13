-- ZeDUI/tools/qa/zedqa_menu_textback.lua  (Nov 1 2026, QA; punch list 48)
-- At the main menu: puts ZeD setup's Text size back to the value zedqa_menu_textlarge.lua (tag mtl) kept in the
-- global ZEDQA_MTL, through the same option and Apply handler, then clears the global. Nothing saved to
-- ModOptions.ini. Run it before gallery_t14_end_menu.lua. grep "ZEDQA mtb"; DONE ~30 frames on (OnFETick).
local function say(s) print("ZEDQA mtb " .. tostring(s)) end
local K = ZEDQA_MTL
local opts = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("ZeD_UI")
local o = opts and opts:getOption("textSize")
if not K then say("nothing to put back (ZEDQA_MTL unset: mtl did not run) | size " .. tostring(ZeD and ZeD.currentSize)); say("DONE"); return end
if not o then say("FAIL no ZeD_UI textSize option"); say("DONE"); return end
say("text size before " .. tostring(ZeD and ZeD.currentSize) .. " (option index " .. tostring(o:getValue())
    .. ") | putting back index " .. tostring(K.was) .. " (" .. tostring(K.size) .. ")")
local ok, err = pcall(function()
    o:setValue(K.was)
    if o.onChangeApply then o:onChangeApply(K.was) else ZeD.Settings.reapplyFromOptions() end
end)
if not ok then say("FAIL putting the size back: " .. tostring(err)) end
local n = 0
local function tick()
    n = n + 1
    if n < 30 then return end
    Events.OnFETick.Remove(tick)
    local back = ZeD and ZeD.currentSize == K.size
    say("text size after " .. tostring(ZeD and ZeD.currentSize) .. " (option index " .. tostring(o:getValue()) .. ") | "
        .. (back and "PASS" or "FAIL") .. " the size is back to " .. tostring(K.size))
    ZEDQA_MTL = nil
    say("DONE")
end
Events.OnFETick.Add(tick)
