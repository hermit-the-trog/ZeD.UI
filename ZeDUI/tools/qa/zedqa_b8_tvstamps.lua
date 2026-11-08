-- ZeDUI/tools/qa/zedqa_b8_tvstamps.lua (Nov 8 2026, Build, QA round 2): what the TV scripts hold on this save, so the
-- schedule's day base can be read off. grep "ZEDQA tvst". Prints per TV channel: whether it has an active script, its
-- "main" script's getStartDayStamp / getStartDay, how many broadcasts, the first and last stamp (minutes from the script's
-- start), and the teaching ones; then the radio's clock and what F.schedule read (F.stat).
local function say(s) print("ZEDQA tvst " .. tostring(s)) end
local function try(label, f)
    local ok, r = pcall(f)
    say(label .. ": " .. (ok and ("ok " .. tostring(r)) or ("ERR " .. tostring(r))))
    return ok, r
end
local R = getZomboidRadio()
local sm = R:getScriptManager()
try("clock", function()
    return "now " .. tostring(sm:getCurrentTimeStamp()) .. " (day " .. tostring(math.floor(sm:getCurrentTimeStamp() / 1440)) .. ")"
        .. " daysSinceStart " .. tostring(R:getDaysSinceStart()) .. " nights " .. tostring(GameTime.getInstance():getNightsSurvived())
        .. " startOffset " .. tostring(ZeD.Finds and ZeD.Finds.startOffset and ZeD.Finds.startOffset())
end)
local list = sm:getChannelsList()
for i = 0, list:size() - 1 do
    local ch = list:get(i)
    if ch:IsTv() then
        try("ch " .. tostring(ch:GetName()), function()
            local cur = ch:getCurrentScript()
            local main = ch:getRadioScript("main")
            local out = "active=" .. tostring(cur and cur:GetName() or nil)
            if main then
                local bl = main:getBroadcastList()
                local first, last, teach = nil, nil, 0
                for j = 0, bl:size() - 1 do
                    local b = bl:get(j)
                    first = first and math.min(first, b:getStartStamp()) or b:getStartStamp()
                    last = last and math.max(last, b:getEndStamp()) or b:getEndStamp()
                    local lines = b:getLines()
                    for k = 0, lines:size() - 1 do
                        local c = tostring(lines:get(k):getEffectsString() or "")
                        if c:find("%u%u%u%+") or c:find("RCP=", 1, true) then teach = teach + 1; break end
                    end
                end
                out = out .. " main: startDayStamp " .. tostring(main:getStartDayStamp()) .. " startDay " .. tostring(main:getStartDay())
                    .. " broadcasts " .. tostring(bl:size()) .. " stamps " .. tostring(first) .. ".." .. tostring(last)
                    .. " (days " .. tostring(first and first / 1440) .. ".." .. tostring(last and last / 1440) .. ") teaching " .. teach
                    .. " loops " .. tostring(main:getLoopMin()) .. "-" .. tostring(main:getLoopMax())
            else
                out = out .. " main: none"
            end
            return out
        end)
    end
end
try("F.schedule", function()
    local s = ZeD.Finds and ZeD.Finds.schedule and ZeD.Finds.schedule()
    local st = ZeD.Finds and ZeD.Finds.stat
    return tostring(s and #s) .. " shows; stat " .. (st and ("channels " .. st.channels .. " dormant " .. st.dormant .. " broadcasts " .. st.broadcasts
        .. " inWindow " .. st.inWindow .. " first " .. tostring(st.first) .. " last " .. tostring(st.last)) or "nil")
end)
local n = 0
local function t() n = n + 1; if n == 10 then Events.OnTick.Remove(t); say("DONE") end end
Events.OnTick.Add(t)
