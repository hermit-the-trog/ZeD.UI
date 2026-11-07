-- ZeDUI/tools/qa/zedqa_floor_rclick.lua  (Nov 6 2026, QA): zedqa_ctx_icons.lua handed the game's world menu the dropped items on the square and the game threw (spriteName null). Does a real
-- right click on dropped items do the same? The real mouse on a tile holding nails, then bare ground as the control. Run with batch_floor_rclick.ps1. Pictures zqa_frc_*.png. grep "ZEDQA frc".
local function say(s) print("ZEDQA frc " .. tostring(s)) end
local function req(s) local f = getFileWriter("zedqa_click.txt", true, false); f:write(s .. "\n"); f:close() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_frc_" .. n .. ".png") end) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function target(x, y)
    return math.floor(isoToScreenX(0, x + 0.5, y + 0.5, 0)), math.floor(isoToScreenY(0, x + 0.5, y + 0.5, 0))
end
local function menu(tag)
    local c = getPlayerContextMenu and getPlayerContextMenu(0)
    say(tag .. ": menu " .. tostring(c and c.Type) .. " visible " .. tostring(c and c:getIsVisible()) .. " options " .. tostring(c and c.numOptions))
    for k = 1, (c and c.numOptions or 1) - 1 do local o = c.options and c.options[k]; if o then say("  " .. tostring(o.name)) end end
end
local function close() local c = getPlayerContextMenu(0); if c and c.closeAll then c:closeAll() end end
local function square(x, y)
    local sq = getCell():getGridSquare(x, y, 0)
    local n = sq and sq:getWorldObjects() and sq:getWorldObjects():size() or 0
    say("tile " .. x .. "," .. y .. " dropped items " .. n)
    return n
end
local bx, by
add(500, function()
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
    square(926, 13041)
    local px, py = math.floor(getPlayer():getX()), math.floor(getPlayer():getY())
    for dy = 4, 8 do for dx = -6, 6 do
        local x, y = px + dx, py + dy
        local sq = getCell():getGridSquare(x, y, 0)
        if not bx and sq and sq:getWorldObjects():size() == 0 and sq:getObjects():size() == 1 then bx, by = x, y end
    end end
    say("bare tile " .. tostring(bx) .. "," .. tostring(by))
end)
add(1500, function() local x, y = target(926, 13041); say("right at " .. x .. "," .. y); req("right " .. x .. " " .. y) end)
add(6500, function() menu("on nails"); shot("01_nails") end)
add(500, close)
add(1500, function() local x, y = target(bx, by); say("right at " .. x .. "," .. y); req("right " .. x .. " " .. y) end)
add(6500, function() menu("bare ground"); shot("02_bare") end)
add(500, close)
add(500, function() say("DONE") end)
local function tick()
    local s = plan[i]
    if not s then Events.OnTick.Remove(tick); return end
    if getTimestampMs() - t0 < s.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, er = pcall(s.fn)
    if not ok then say("ERR " .. tostring(er)) end
end
say("start")
Events.OnTick.Add(tick)
