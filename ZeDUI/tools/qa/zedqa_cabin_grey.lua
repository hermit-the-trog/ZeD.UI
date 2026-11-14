-- ZeDUI/tools/qa/zedqa_cabin_grey.lua (Nov 13 2026, QA): forces the grey cabin (ZeD.Dashboard.qaCabin = "v_grey") for the next
-- dash pass, so the grey Primani's printed words can be seen; zedqa_cabin_off.lua puts it back. grep "ZEDQA cab".
ZeD.Dashboard.qaCabin = "v_grey"
print("ZEDQA cab qaCabin " .. tostring(ZeD.Dashboard.qaCabin))
print("ZEDQA cab DONE")
