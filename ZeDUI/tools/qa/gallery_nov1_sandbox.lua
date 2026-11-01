-- ZeDUI/tools/qa/gallery_nov1_sandbox.lua  (Nov 1 2026, QA)
-- The Workshop gallery retake (workshop/gallery/REVIEW_20261101.md, "Retakes" 9): page 49's picture,
-- zqa_sbx_world_help (zedqa_sandbox_ig.lua's name, so shots.json keeps working). The t14 picture's help panel
-- described World Item Removal List, a row scrolled out of view. Here the World page opens at the top and a row that
-- is in view (the second setting under the world's day line that can change) is marked with the controller's focus,
-- and the help panel shows that same row. Nothing is changed: no value is touched, nothing is applied.
-- Runs anywhere in game (after the story's teardown in gallery_nov1_manifest.txt). Puts back: the Sandbox in game
-- switch, the controller look, the window shut, the pause screen shut.
-- Logs "rect zqa_sbx_world_help window x y w h list y h | row <name> at <y>" for the crop.
-- "ZEDQA n1x ..." ending "ZEDQA n1x DONE".
local p = getPlayer()
local MM = ZeD and ZeD.MainMenu
local X = { Q = {}, nOk = 0, nErr = 0 }
function X.say(s) print("ZEDQA n1x " .. tostring(s)) end
local say = X.say
local opt = ZeD and ZeD.Settings and ZeD.Settings.sandboxInGameOption
if not (p and opt and MM and ZeD_MMSandboxIG) then say("ERR the sandbox window is not loaded"); say("DONE"); return end
X.switchWas = opt:getValue()
X.padWas = MM.forceGamepad
function X.step(n, fn) X.Q[#X.Q + 1] = { n = n, fn = fn } end
function X.menuUp() return MainScreen and MainScreen.instance and MainScreen.instance:isVisible() end
function X.toggleMenu() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end
function X.page(title)
    local sw = X.sw
    for i, pg in ipairs(sw:pages()) do
        if pg.raw == title or pg.title == title then sw.pageIdx = i; sw.scroll = 0; sw.focusId = nil; return pg end
    end
    return nil
end

X.step(10, function()
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(p:getPlayerNum()) end
    opt:setValue(2)
    pcall(function() Mouse.setXY(5, 5) end)   -- (the pointer off the window: the help band shows the marked row)
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    if not X.menuUp() then X.toggleMenu() end
end)
X.step(40, function() MM.openSandboxIG() end)
X.step(40, function()
    X.sw = MM.pauseSandbox
    if not (X.sw and X.sw:isVisible()) then X.nErr = X.nErr + 1; say("ERR the Sandbox window did not open"); return end
    if not X.page("World") then X.nErr = X.nErr + 1; say("ERR no World page") end
end)
-- the page drawn once (the rows' heights known), then the row: the second live setting from the top
X.step(20, function()
    local sw = X.sw
    if not sw then return end
    local rows = sw:rowsFor(sw:pages()[sw.pageIdx])
    local idx, y, n = 0, 0, 0
    for _, r in ipairs(rows) do
        if r.kind ~= "header" and r.kind ~= "note" and r.kind ~= "desc" then
            idx = idx + 1
            if r.name and not sw:rowDisabled(r) then
                n = n + 1
                if n == 2 then X.row, X.idx, X.y = r, idx, y; break end
            end
        end
        y = y + (r._h or ZeD.T.px(30))
    end
    if not X.row then X.nErr = X.nErr + 1; say("ERR no live setting on the World page"); return end
    MM.forceGamepad = true
    sw.focusId = "orow:" .. X.idx
    sw.qaHelp = X.row
    local vh = sw._list and sw._list.h or 0
    say(string.format("world: the row %s (controller row %d) at %d of a %d-high list: %s", tostring(X.row.name), X.idx,
        math.floor(X.y), math.floor(vh), (X.y + (X.row._h or 0) <= vh) and "in view" or "NOT in view"))
end)
X.step(30, function()
    local sw = X.sw
    if not (sw and X.row) then return end
    local ok, e = pcall(function() getCore():TakeFullScreenshot("zqa_sbx_world_help.png") end)
    if ok then X.nOk = X.nOk + 1; say("shot zqa_sbx_world_help ok") else X.nErr = X.nErr + 1; say("ERR shot zqa_sbx_world_help: " .. tostring(e)) end
    local L = sw._list or {}
    say(string.format("rect zqa_sbx_world_help window %d %d %d %d list %d %d | row %s at %d (focus %s)",
        math.floor(sw:getAbsoluteX()), math.floor(sw:getAbsoluteY()), math.floor(sw:getWidth()), math.floor(sw:getHeight()),
        math.floor((L.y or 0) + sw:getAbsoluteY()), math.floor(L.h or 0), tostring(X.row.name), math.floor(X.y), tostring(sw.focusId)))
end)
X.step(5, function()
    MM.forceGamepad = X.padWas
    local sw = X.sw
    if sw then
        sw.qaHelp = nil
        sw.focusId = nil
        pcall(function() sw:finish() end)
    end
end)
X.step(10, function()
    opt:setValue(X.switchWas or 1)
    if X.menuUp() then X.toggleMenu() end
    say(string.format("put back: switch %s, controller look %s | end: %d shots ok, %d errors", tostring(opt:getValue()),
        tostring(MM.forceGamepad), X.nOk, X.nErr))
end)
X.step(10, function() say("DONE") end)

X.qi, X.wait = 1, nil
function X.tick()
    local s = X.Q[X.qi]
    if not s then Events.OnPreUIDraw.Remove(X.tick); return end
    X.wait = (X.wait or s.n) - 1
    if X.wait > 0 then return end
    X.wait = nil
    X.qi = X.qi + 1
    local ok, err = pcall(s.fn)
    if not ok then X.nErr = X.nErr + 1; say("ERR step " .. (X.qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(X.tick)
say("start (" .. #X.Q .. " steps)")
