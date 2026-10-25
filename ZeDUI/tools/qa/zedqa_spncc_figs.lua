-- ZeDUI/tools/qa/zedqa_spncc_figs.lua  (Oct 25 2026)
-- The Appearance tab's 3D figures over time: the tab opened and left alone, pictures at
-- 1, 3, 6 and 10 seconds, with each figure's place and whether it is shown. (Run 3 had
-- the big figure and the seventh face blank with seven faces up.) grep "ZEDQA spf".
local function say(s) print("ZEDQA spf " .. tostring(s)) end
local S = ZeD.ModSupport and ZeD.ModSupport.SPNCC
if not S then say("ERR no SPNCC support"); return end
local CW = ZeD_CharacterWindow
local t0 = getTimestampMs()
local function dump(tag)
    local w = CW.getWindow()
    local st = w and w._spncc
    if not st then say(tag .. " no state"); return end
    local function one(name, m)
        if not m then say(tag .. " " .. name .. " none"); return end
        say(string.format("%s %s x=%d y=%d w=%d h=%d lua=%s java=%s", tag, name, m:getX(), m:getY(), m:getWidth(), m:getHeight(),
            tostring(m:isVisible()), tostring(m.javaObject:isVisible())))
    end
    one("preview", st.preview)
    for i, m in ipairs(st.pool) do one("tile" .. i .. ":" .. tostring(m._tile and m._tile.opt.name), m) end
end
local shots = { { 60, "1s" }, { 180, "3s" }, { 360, "6s" }, { 600, "10s" } }
local i = 1
local opened = false
local function tick()
    local el = (getTimestampMs() - t0) * 60 / 1000
    if not opened then S.openTab(0); opened = true end
    local s = shots[i]
    if not s then Events.OnRenderTick.Remove(tick); say("DONE"); return end
    if el >= s[1] then
        dump(s[2])
        pcall(function() getCore():TakeFullScreenshot("zqa_spf_" .. s[2] .. ".png") end)
        i = i + 1
    end
end
Events.OnRenderTick.Add(tick)
say("start")
