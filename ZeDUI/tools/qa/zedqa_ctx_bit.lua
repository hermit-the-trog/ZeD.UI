-- ZeDUI/tools/qa/zedqa_ctx_bit.lua  (Nov 7 2026, QA; compat round 6): with Better Item Transfer (3830103302) on, zedqa_ctxlist read
-- ZeD's right-click menu on an apple as empty. What a player sees: the apple's menu in both ZeD styles (1 the icon strip,
-- 2 the list), pictured, with the game's own option count and names (vanilla's ISContextMenu, which ZeD mirrors) and ZeD's
-- menu class, its tree size and whether it was marked failed. The style option is put back. grep "ZEDQA cbt".
local function say(s) print("ZEDQA cbt " .. tostring(s)) end
local p = getPlayer()
local opt = ZeD.Settings.contextStyleOption
local was = opt:getValue()
local apple
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function report(tag)
    local v = getPlayerContextMenu(0)
    local names = {}
    for _, o in ipairs(v and v.options or {}) do names[#names + 1] = tostring(o.name) end
    local z = v and v._zedMenu
    local tree = z and (z.tree or z._tree or z.actionTree)
    say(string.format("%s: the game's menu %d options (numOptions %s) visible %s: %s", tag, #names, tostring(v and v.numOptions),
        tostring(v and v:isVisible()), table.concat(names, ", ")))
    say(string.format("%s: ZeD's menu %s, tree %s, failed %s, levels %s", tag, tostring(z and z.Type), tostring(tree and #tree),
        tostring(v and v._zedFailed), tostring(z and z._levels and #z._levels)))
end
at(2, function()
    if not (ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    apple = p:getInventory():AddItem("Base.Apple")
    opt:setValue(1)
end)
at(20, function() ISInventoryPaneContextMenu.createMenu(0, true, { apple }, 700, 300) end)
at(45, function() report("style 1 (icon strip)") end)
at(50, function() pcall(function() getCore():TakeFullScreenshot("zqa_cbt_style1.png") end) end)
at(60, function() local v = getPlayerContextMenu(0); if v then v:hideAndChildren() end end)
at(70, function() opt:setValue(2) end)
at(90, function() ISInventoryPaneContextMenu.createMenu(0, true, { apple }, 700, 300) end)
at(115, function() report("style 2 (list)") end)
at(120, function() pcall(function() getCore():TakeFullScreenshot("zqa_cbt_style2.png") end) end)
at(130, function()
    local v = getPlayerContextMenu(0); if v then v:hideAndChildren() end
    opt:setValue(was)
    if apple then p:getInventory():Remove(apple) end
    say("style put back to " .. tostring(was))
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do
        if s.n == tick then
            local ok, e = pcall(s.fn)
            if not ok then say("ERR step " .. s.n .. ": " .. tostring(e)) end
        end
    end
    if tick > 135 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
