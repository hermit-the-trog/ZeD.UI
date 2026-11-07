-- ZeDUI/tools/qa/zedqa_repair_check.lua  (Nov 6 2026, QA): the once-only Vanilla Access repair. Run by batch_repair.ps1 twice. First launch: ModOptions.ini holds Vanilla Access in every row but
-- Identity (Immersive) and the preset Custom, with no ZeD_presetRepair.txt: it must come up Vanilla Access, Identity Simple, then the player picks Immersive. Second launch: the pick must stay. grep "ZEDQA rpc".
local function say(s) print("ZEDQA rpc " .. tostring(s)) end
local opts = PZAPI.ModOptions:getOptions("ZeD_UI")
local preset, identity = opts:getOption("additionsPreset"), opts:getOption("identityStyle")
local leg = getCore():getScreenWidth() == 1280 and getCore():getScreenHeight() == 800 and "first" or "second"
say(leg .. " launch: preset " .. tostring(preset:getValue()) .. ", identity " .. tostring(identity:getValue()) .. ", restock " .. tostring(opts:getOption("restock"):getValue()))
local r = getFileReader("ZeD_presetRepair.txt", false)
say("repair file " .. tostring(r ~= nil)); if r then r:close() end
if leg == "first" then
    say((preset:getValue() == 3 and identity:getValue() == 2) and "PASS the player is back on Vanilla Access with Simple" or "FAIL not repaired")
    identity:setValue(1)
    ZeD.Settings.reconcileAdditions()
    PZAPI.ModOptions:save()
    say("picked Immersive: preset " .. tostring(preset:getValue()) .. ", identity " .. tostring(identity:getValue()))
else
    say((preset:getValue() == 4 and identity:getValue() == 1) and "PASS the later pick stays" or "FAIL the pick was undone")
end
say("DONE")
