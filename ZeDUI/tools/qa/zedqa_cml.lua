-- ZeDUI/tools/qa/zedqa_cml.lua  (Nov 8 2026, Build; tag cml): [B42] Custom Map Labels with ZeD (punch list 117), in the mod
-- list cml_mods.txt (mod id CustomMapLabels, ZeD last; add a map mod the mod has labels for, or turn on its Vanilla labels
-- option, or no label is written). Read-only. It reports (ZEDQA cml PASS / FAIL / info lines):
--   0. the mod is on, ZeD is on, ZeD's support for the mod loaded (ZeD.ModSupport.CustomMapLabels)
--   1. the game's map object exists (the mod asked for it at the start; ISWorldMap_instance), is shut, and the support's
--      start window is closed
--   2. the symbol store holds text symbols the mod wrote (isText, not user defined, key MapLabel_*): how many
--   3. ZeD's map opens on the Maps tab (ISWorldMap.ShowWorldMap, the M key's route) at a label's place if there is one, and
--      is ZeD's, not the game's; shot
-- By hand: console.txt has no "CustomMapLabels.lua:93" error at the start. Shots zqa_cml_*.png. grep "ZEDQA cml ".
local function say(s) print("ZEDQA cml " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_cml_" .. n .. ".png") end); say("shot " .. n) end
local active = {}
do local list = getActivatedMods(); for i = 0, list:size() - 1 do active[(tostring(list:get(i)):gsub("^\\", ""))] = true end end
local steps = {}
local function step(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local lx, ly = nil, nil

step(5, function()
    local S = ZeD and ZeD.ModSupport and ZeD.ModSupport.CustomMapLabels
    say("mods: CustomMapLabels=" .. tostring(active.CustomMapLabels == true) .. " ZeD_UI=" .. tostring(active.ZeD_UI == true)
        .. "; support loaded: " .. tostring(S ~= nil))
    check(active.CustomMapLabels and S, "the mod and ZeD's support are on")
    check(S and S.starting == false, "the start window is closed")
    check(ISWorldMap_instance ~= nil, "the game's map object exists (the mod asked at the start)")
    check(ISWorldMap_instance == nil or not ISWorldMap_instance:isVisible(), "and it is shut")
    if getGameSpeed() <= 0 then setGameSpeed(1) end
end)
step(10, function()
    local api = ZeD.MapNotes and ZeD.MapNotes.api and ZeD.MapNotes.api()
    check(api ~= nil, "the symbol store answers")
    if not api then return end
    local texts, labels = 0, 0
    for i = 0, api:getSymbolCount() - 1 do
        local s = api:getSymbolByIndex(i)
        if s and s:isText() and not s:isUserDefined() then
            texts = texts + 1
            local k = s:getUntranslatedText()
            if k and tostring(k):find("^MapLabel_") then
                labels = labels + 1
                if not lx then lx, ly = s:getWorldX(), s:getWorldY() end
            end
        end
    end
    say("text symbols not made by the player: " .. texts .. ", of them MapLabel_*: " .. labels)
    if labels == 0 then say("info: none: right only when no map mod the mod knows is on and its Vanilla labels option is off") end
end)
step(10, function()
    ISWorldMap.ShowWorldMap(0, lx, ly, 14)
end)
step(120, function()
    local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    check(win ~= nil and win._mapPopout ~= nil, "ZeD's map is open (the unfolded pop-out)")
    check(ISWorldMap_instance == nil or not ISWorldMap_instance:isVisible(), "the game's map stayed shut")
    shot("zed_map")
end)
step(10, function()
    pcall(ISWorldMap.HideWorldMap, 0)
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)
local qi, wait = 1, nil
local function tick()
    local s = steps[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    wait = wait or (now + s.n * 1000 / 60)
    if now < wait then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then fails = fails + 1; say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
