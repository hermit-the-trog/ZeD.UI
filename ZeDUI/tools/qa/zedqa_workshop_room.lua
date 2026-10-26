-- ZeDUI/tools/qa/zedqa_workshop_room.lua  (Oct 25 2026)
-- The Workshop window's room for a description (Steam answered 8 to the 0.2.0-t5 upload: the
-- game adds its own lines to the description, and 7,976 + 58 went past Steam's 8,000). At the
-- main menu, with the ZeD-UI item in Zomboid/Workshop: the room is 8,000 less what the game adds
-- (getSubmitDescription minus getDescription), our description fits it, and a description one
-- character too long is held back with the reason. Run with zedqa_menu_mods_run.ps1.
-- Screenshot zqa_wsr_1.png; grep "ZEDQA wsr".
local MM = ZeD.MainMenu
local R = MM.root
local function say(s) print("ZEDQA wsr " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function vwin(view) for _, rv in ipairs(MM.views or {}) do if rv.view == view then return R[rv.field] end end end
local steps, t = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end

at(2, function() MM.act.workshop() end)
at(40, function()
    local w = vwin("workshop")
    if not check(w ~= nil and w.descRoom ~= nil, "the Workshop window is up") then return end
    local it = w:item()
    say("item " .. tostring(it and it:getFolderName()) .. " id " .. tostring(it and it:getID()))
    local own, sub = tostring(it:getDescription()), tostring(it:getSubmitDescription())
    local room = w:descRoom()
    say(string.format("ours %d, sent %d, the game adds %d, room %d", #own, #sub, #sub - #own, room))
    check(room == 8000 - (#sub - #own), "the room is Steam's 8,000 less what the game adds")
    check(#sub <= 8000, "what the game sends is within Steam's 8,000 (" .. #sub .. ")")
    check(#w.desc <= room and w:blocker() ~= ZeD.tr("UI_ZeD_Workshop_DescriptionTooLong", room), "our description fits, nothing holds it back for its length")
    local keep = w.desc
    w.desc = keep .. string.rep("x", room - #keep + 1)
    local b = w:blocker()
    check(b == ZeD.tr("UI_ZeD_Workshop_DescriptionTooLong", room), "one character over is held back: " .. tostring(b))
    w.desc = keep
    getCore():TakeFullScreenshot("zqa_wsr_1.png")
end)
at(60, function() MM.showView("main") end)
at(75, function() say(fails == 0 and "all checks passed" or (fails .. " failed")); say("DONE") end)

local function tick()
    t = t + 1
    for _, s in ipairs(steps) do if s.n == t then local ok, e = pcall(s.fn); if not ok then fails = fails + 1; say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if t > 80 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
