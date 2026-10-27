local function say(s) print("ZEDQA pw " .. tostring(s)) end
local p = getPlayer()
local book = p:getInventory():AddItem("Base.Notebook")
p:getInventory():AddItem("Base.Pencil")
local n = 0
local function t()
  n = n + 1
  if n == 30 then local ok, e = pcall(ISInventoryPaneContextMenu.onWriteSomething, book, true, p:getPlayerNum()); say("write " .. tostring(ok) .. " " .. tostring(e)) end
  if n == 200 then pcall(function() getCore():TakeFullScreenshot("zqa_pw.png") end); say("frame 200") end
  if n == 260 then Events.OnRenderTick.Remove(t); say("DONE") end
end
Events.OnRenderTick.Add(t)
say("start")
