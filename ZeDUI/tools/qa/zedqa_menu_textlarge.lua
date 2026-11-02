-- ZeDUI/tools/qa/zedqa_menu_textlarge.lua  (Nov 1 2026, QA; punch list 48)
-- At the main menu: Large text the way the mod's option does it (ZeD setup's Text size combo set to Large and
-- its Apply handler run, as vanilla's MainOptions apply does: option:onChangeApply(index)). The option's value
-- before is kept in the global ZEDQA_MTL for zedqa_menu_textback.lua (tag mtb) to put back; the first value is
-- kept when it runs twice. Nothing saved to ModOptions.ini (the runner keeps and restores that file anyway).
-- Runs after gallery_t14_look_menu.lua (which sets the option to small). grep "ZEDQA mtl"; DONE ~30 frames on
-- (OnFETick: the main menu has no OnTick).
local function say(s) print("ZEDQA mtl " .. tostring(s)) end
local opts = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("ZeD_UI")
local o = opts and opts:getOption("textSize")
if not o then say("FAIL no ZeD_UI textSize option (options " .. tostring(opts) .. ")"); say("DONE"); return end
local LARGE = 2   -- Settings.lua: sizeKeys = { "small", "large" }
if not ZEDQA_MTL then ZEDQA_MTL = { was = o:getValue(), size = ZeD and ZeD.currentSize } end
say("text size before " .. tostring(ZeD and ZeD.currentSize) .. " (option index " .. tostring(o:getValue())
    .. ") | kept for mtb: index " .. tostring(ZEDQA_MTL.was) .. ", size " .. tostring(ZEDQA_MTL.size))
local ok, err = pcall(function()
    o:setValue(LARGE)
    if o.onChangeApply then o:onChangeApply(LARGE) else ZeD.Settings.reapplyFromOptions() end
end)
if not ok then say("FAIL setting Large: " .. tostring(err)) end
local n = 0
local function tick()
    n = n + 1
    if n < 30 then return end
    Events.OnFETick.Remove(tick)
    local MM = ZeD and ZeD.MainMenu
    local S = ZeD and ZeD.Scale
    say("text size after " .. tostring(ZeD and ZeD.currentSize) .. " (option index " .. tostring(o:getValue()) .. ") | "
        .. ((ZeD and ZeD.currentSize == "large") and "PASS Large text on" or "FAIL Large text not on")
        .. " | root " .. tostring(S and S.root and S.root()) .. " | framing " .. tostring(MM and MM._framing)
        .. " (wants " .. tostring(MM and MM.wantFraming and MM.wantFraming()) .. ")")
    say("DONE")
end
Events.OnFETick.Add(tick)
