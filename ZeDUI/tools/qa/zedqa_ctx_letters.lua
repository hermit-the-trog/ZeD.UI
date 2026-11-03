-- ZeDUI/tools/qa/zedqa_ctx_letters.lua  (Nov 3 2026, QA; Build's 5f2f68a8: an option with no icon of its own shows its
-- two letters in sentence case, "Op" not "OP")
-- Opens a context menu at the screen's centre the way another mod builds one (ISContextMenu.get + addOption) with
-- options ZeD has no icon for: two plain English names, one starting with a small letter, and two Turkish names
-- (letters past plain A-Z). Each option's two letters are worked out as drawContextCell does and logged, the menu is
-- photographed, then shut. Nothing is chosen. grep "ZEDQA ctl"; shot zqa_ctl_menu.png.
local function say(s) print("ZEDQA ctl " .. tostring(s)) end
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local CW = ZeD_CharacterWindow
local NAMES = { "Qa probe option", "open the crate", "Wxyz measure", "Çekiç kullan", "İçini boşalt" }
local ctx
local Q, qi, wait = {}, 1, nil
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function letters(name)   -- (drawContextCell's rule, Molecules.lua)
    local clean = tostring(name):gsub("[^%w]+", "")
    local l = ZeD.upper(clean:sub(1, 1)) .. string.lower(clean:sub(2, 2))
    return l == "" and "?" or l
end

step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if CW.isOpen() then CW.toggleBothPaired(0) end
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
end)
step(20, function()
    local x, y = math.floor(getCore():getScreenWidth() / 2), math.floor(getCore():getScreenHeight() / 2)
    pcall(function() Mouse.setXY(x, y) end)
    ctx = ISContextMenu.get(0, x, y)
    for _, n in ipairs(NAMES) do ctx:addOption(n, nil, function() say("chosen: " .. n) end) end
    ctx:setVisible(true)
    for _, n in ipairs(NAMES) do say("option \"" .. n .. "\" -> " .. letters(n)) end
end)
step(40, function()
    check(ctx and ctx._zedSpawned and not ctx._zedFailed, "ZeD drew the menu (not vanilla's)")
    check(letters(NAMES[1]) == "Qa", "a name with no icon shows a capital then a small letter (Qa)")
    check(letters(NAMES[2]) == "Op", "a name starting small still starts with a capital (Op)")
    check(letters(NAMES[3]) == "Wx", "wide letters (Wx)")
    pcall(function() getCore():TakeFullScreenshot("zqa_ctl_menu.png") end)
    say("shot zqa_ctl_menu at the screen's centre")
end)
step(10, function()
    pcall(function() ctx:closeAll() end)
    pcall(function() ctx:setVisible(false) end)
    if fails == 0 then say("summary: all " .. passes .. " PASS") else say("summary: " .. fails .. " of " .. (passes + fails) .. " checks FAIL") end
end)
step(20, function() say("DONE") end)

local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
