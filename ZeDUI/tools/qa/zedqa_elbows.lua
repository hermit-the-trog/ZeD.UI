-- ZeDUI/tools/qa/zedqa_elbows.lua  (Nov 5 2026, QA; punch list 88 and 90, 5876172f): the repaired arms. A board of the male and female figures
-- at 3x, bare and with the arm parts tinted; a walk of each arm's hit map (the upper arm, the forearm and the hand by name, down each arm);
-- then the Health, Thermal and Equip tabs as male and as female; the five American lines as the game reads them. The save comes back
-- (zedqa_mods_run.ps1). Pictures zqa_elb_board.png, zqa_elb_<sex>_<tab>.png. grep "ZEDQA elb".
local function say(s) print("ZEDQA elb " .. tostring(s)) end
require "ZeD/ZeD_BodyFigure"
local p = getPlayer()
local CWm = ZeD_CharacterWindow
local function cw() return CWm.getWindow() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_elb_" .. n .. ".png") end) end
local function tab(id)
    local w = cw(); local strip = w and w._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
end
local B = ISPanel:derive("ZeDQAElbows")
function B:prerender()
    self:drawRect(0, 0, self.width, self.height, 1, 0.10, 0.11, 0.13)
    local x = 40
    for _, f in ipairs(self.figs) do
        f.fig:drawAt(self, x, 40, 660, 780)
        x = x + 690
    end
end
local board = B:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight())
board.figs = {}
local TINTS = { { "Right Upper Arm", 0.9, 0.27, 0.2 }, { "Left Upper Arm", 0.95, 0.66, 0.24 }, { "Right Forearm", 0.2, 0.7, 0.9 }, { "Left Forearm", 0.3, 0.9, 0.4 }, { "Right Hand", 0.8, 0.4, 0.9 }, { "Left Hand", 0.9, 0.9, 0.3 } }
for _, spec in ipairs({ { false, false }, { true, false }, { false, true }, { true, true } }) do
    local fig = ZeD_BodyFigure:new(0, 0, 100, 100, 0)
    fig:setSex(spec[1])
    if spec[2] then for _, t in ipairs(TINTS) do fig:setPartColor(t[1], t[2], t[3], t[4], 0.9) end end
    board.figs[#board.figs + 1] = { fig = fig, sex = spec[1], tinted = spec[2] }
end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
add(300, function()
    for _, k in ipairs({ "UI_ZeD_Order_PickNoneAfter", "UI_ZeD_Order_PickNoneBefore", "UI_ZeD_Mods_HelpLabel", "UI_ZeD_GCh_zed_look_Text", "UI_ZeD_GCh_whatsnew_beta3_Text" }) do
        local s = getTextOrNull(k) or ""
        local bad = s:find("[Gg]rey") or s:find("[Cc]olour")
        say(((s ~= "" and not bad) and "PASS " or "FAIL ") .. k .. ": " .. string.sub(s, 1, 60))
    end
    board:initialise(); board:addToUIManager(); board:bringToTop()
end)
add(1500, function()
    shot("board")
    -- down each arm, canvas coordinates: the map's answer at each step
    for fi = 1, 2 do
        local f = board.figs[fi].fig
        local sex = board.figs[fi].sex and "female" or "male"
        for _, arm in ipairs({ { "viewer's left", 56, 76 }, { "viewer's right", 126, 150 } }) do
            local seen = {}
            for y = 56, 170, 4 do
                local line = {}
                for x = arm[2], arm[3], 2 do
                    local n = f:hitTestAt(f._drawAtX + x * f._drawAtS, f._drawAtY + y * f._drawAtS)
                    if n and not line[n] and n ~= "Upper Torso" and n ~= "Lower Torso" then line[n] = true; seen[#seen + 1] = y .. ":" .. n end
                end
            end
            local out, last = {}, nil
            for _, e in ipairs(seen) do local y, n = e:match("^(%d+):(.+)$"); if n ~= last then out[#out + 1] = y .. " " .. n; last = n end end
            say(sex .. ", " .. arm[1] .. ": " .. table.concat(out, ", "))
        end
    end
    board:removeFromUIManager()
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
end)
for _, sex in ipairs({ "male", "female" }) do
    add(1500, function() pcall(function() p:setFemale(sex == "female") end); pcall(function() p:getDescriptor():setFemale(sex == "female") end); say("the character is " .. sex .. ": " .. tostring(p:isFemale())) end)
    for _, id in ipairs({ "health", "thermal", "equip" }) do
        add(1200, function() tab(id) end)
        add(1800, function() shot(sex .. "_" .. id) end)
    end
end
add(500, function() tab("loot"); CWm.toggleBothPaired(0); say("DONE") end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); if i > #plan then say("DONE") end end
end
Events.OnTick.Add(drive)
