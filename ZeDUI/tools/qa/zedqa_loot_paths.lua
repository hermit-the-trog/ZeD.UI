-- ZeDUI/tools/qa/zedqa_loot_paths.lua  (Nov 5 2026, QA; the container-click fix 7e1a49c2, the other ways in): the game's
-- loot page shown the way its right-click menu and others do (setNewContainer + setVisible), the controller's way
-- (ISButtonPrompt:cmdShowLoot) and a trunk's (setForceSelectedContainer): ZeD's World window must take each container,
-- the game's page must stay hidden. grep "ZEDQA lpa".
local function say(s) print("ZEDQA lpa " .. tostring(s)) end
if ZEDQA_HOME then ZEDQA_HOME("lpa") end
local p = getPlayer()
local function vl() return getPlayerLoot(0) end
local function selInv() local w = ZeD_WorldWindow.getWindow(); local c = w and w._containers and w._containers[w._activeContainer or 0]; return c and c.inventory end
local function closeAll() if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggle(0) end; if ZeD_WorldWindow.isOpen() then ZeD_WorldWindow.close() end end
-- a container next to a free square
local cand
do
    local cell = getCell(); local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    for r = 1, 40 do
        for dx = -r, r do for dy = -r, r do
            if not cand and (math.abs(dx) == r or math.abs(dy) == r) then
                local sq = cell:getGridSquare(px + dx, py + dy, pz)
                local objs = sq and sq:getObjects()
                for i = 0, (objs and objs:size() or 0) - 1 do
                    local o = objs:get(i)
                    if not cand and o:getContainer() and not instanceof(o, "IsoDeadBody") then local adj = AdjacentFreeTileFinder.Find(sq, p); if adj then cand = { o = o, adj = adj } end end
                end
            end
        end end
        if cand then break end
    end
end
if not cand then say("ERR no container"); say("DONE"); return end
local inv = cand.o:getContainer()
local function stand() p:setX(cand.adj:getX() + 0.5); p:setY(cand.adj:getY() + 0.5); p:setLastX(cand.adj:getX() + 0.5); p:setLastY(cand.adj:getY() + 0.5) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function check(tag) add(1500, function()
    local ok = ZeD_WorldWindow.isOpen() and not vl():getIsVisible() and selInv() == inv
    say((ok and "PASS " or "FAIL ") .. tag .. ": World open " .. tostring(ZeD_WorldWindow.isOpen()) .. ", game page " .. tostring(vl():getIsVisible()) .. ", the container shown " .. tostring(selInv() == inv))
end) end
-- the menu's way
add(300, function() closeAll(); stand() end)
add(1500, function() local l = vl(); l:setNewContainer(inv); l:setVisible(true); if l.isCollapsed then l.isCollapsed = false end end)
check("the game's menu way (setNewContainer, setVisible)")
-- the controller's way
add(300, function() closeAll() end)
add(1500, function()
    local l = vl(); l:setNewContainer(inv)
    local bp = ISButtonPrompt:new(0)
    local ok, e = pcall(function() bp:cmdShowLoot() end)
    say("cmdShowLoot ran " .. tostring(ok) .. " " .. tostring(e or ""))
end)
check("the controller's way (cmdShowLoot)")
-- the trunk's way: a forced container
add(300, function() closeAll() end)
add(1500, function() local l = vl(); l:setForceSelectedContainer(inv, 2000); l:setVisible(true) end)
check("a forced container (setForceSelectedContainer, as a trunk opens)")
add(300, function()
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
    if ZEDQA_HOME then ZEDQA_HOME("lpa") end
    say("DONE")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
