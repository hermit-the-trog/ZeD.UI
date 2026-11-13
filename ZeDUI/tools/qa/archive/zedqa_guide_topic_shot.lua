-- ZeDUI/tools/qa/zedqa_guide_topic_shot.lua  (Nov 3 2026, QA): the window look on one topic (GUIDE_TOPIC, a title key), a picture, the
-- end x of each text line against the measure logged. grep "ZEDQA gts". Shot zqa_gts_<lang>_<key>.png.
local function say(s) print("ZEDQA gts " .. tostring(s)) end
local G = ZeD.Guide
local key = GUIDE_TOPIC or "SurvivalGuide_foraging_title"
local lang = "?"; pcall(function() lang = tostring(Translator.getLanguage():name()) end)
local opt = ZeD.Settings.guideStyleOption
local was = opt:getValue()
local n = 0
local function tick()
    n = n + 1
    if n == 20 then opt:setValue(2); if G.openWindow then G.openWindow(0, key) else G.open(0, key) end end
    if n == 80 then
        local w = G.get(0); local g = w._g; local T = ZeD.T
        local right = g.text.x + g.text.w - T.px(10) * 2 - (T.sp.scrollbarW or 0)
        for _, it in ipairs(g.items or {}) do
            if it.kind == "line" then
                local endX, s = it.x, ""
                for _, r in ipairs(it.runs or {}) do if r.text then s = s .. r.text; endX = math.max(endX, it.x + r.x + ZeD.TM:MeasureStringX(T.fontF2, r.text)) end end
                if endX > right + 1 then say(string.format("over by %d px: %s", math.floor(endX - right), s)) end
            end
        end
        pcall(function() getCore():TakeFullScreenshot("zqa_gts_" .. lang .. "_" .. key .. ".png") end)
    end
    if n == 100 then G.get(0):close(); opt:setValue(was); if getGameSpeed() <= 0 then setGameSpeed(1) end; Events.OnRenderTick.Remove(tick); say("DONE") end
end
Events.OnRenderTick.Add(tick)
say("start " .. key)
