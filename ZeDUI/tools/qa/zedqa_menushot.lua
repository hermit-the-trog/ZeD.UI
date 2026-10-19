-- ZeDUI/tools/qa/zedqa_menushot.lua: at the main menu, one screenshot (zqa_menu.png). grep "ZEDQA ms".
local n = 0
local function t() n = n + 1; if n == 30 then pcall(function() getCore():TakeFullScreenshot("zqa_menu.png") end); print("ZEDQA ms DONE"); Events.OnFETick.Remove(t) end end
Events.OnFETick.Add(t)
