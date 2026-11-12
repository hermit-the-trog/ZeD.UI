-- ZeDUI/tools/qa/zedqa_window_saved_pos.lua  (Nov 11 2026, QA; tag wsp): the window menu's Save position and Go to saved
-- position, in game, on the Character and World windows and the survival guide. Runs through the rows WM.build makes (what
-- a click or the pad's A runs), a few ticks apart so the drawers slide, and prints PASS / FAIL lines:
--   1 nothing saved: Go to saved position greyed with its reason on all three windows
--   2 the Character window opened on Skills, its drawer open, moved: Save position; one Messages bubble says so
--   3 the Character window moved, its drawer shut on Loot: Go to saved position puts it back, the drawer sliding open on
--     Skills; the World window's Go to saved position still greyed (each window its own)
--   4 the World window and the guide saved and sent back the same way; the Character window's place unchanged
--   5 the file read again from Zomboid/Lua: the same places
--   6 Reset this window and Reset both windows still go to the default spread, and the saved places stay
-- Captures for the director: "ZEDQA wsp SHOT <name>" lines mark the moments (the menu open on the Character window with
-- the two new rows; just after Go to saved position). The player's own saved places are kept at the start and written back
-- at the end. Never at a resolution or scale the run did not start at; change those by hand and re-run step 3 for the clamp.
-- grep "ZEDQA wsp".
local TAG = "wsp"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local P, WM = ZeD.WindowPlaces, ZeD.WindowMenu
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local Q = { pass = 0, fail = 0 }
local function check(name, ok, detail)
    if ok then Q.pass = Q.pass + 1; say("PASS " .. name)
    else Q.fail = Q.fail + 1; say("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
if not (P and WM and CWm and WWm) then say("ERR ZeD's window modules are missing"); return end

-- the player's own places, put back at the end
local keep = {}
for k, v in pairs(P.load()) do keep[k] = v end
P.places = {}

local function row(win, key)
    for _, it in ipairs(WM.build(win)) do if it.name == ZeD.tr(key) then return it end end
    return nil
end
local function greyed(win)
    local r = row(win, "UI_ZeD_WinMenu_GoSaved")
    return r ~= nil and r.disabled(win) == true and r.state(win) == ZeD.tr("UI_ZeD_WinMenu_NoSaved")
end
local function at(win) return win:getX() .. "," .. win:getY() .. " " .. win:getWidth() .. "x" .. win:getHeight() end

local cw, ww, gw
local savedC, savedW, savedG
local steps = {
    function()
        if not CWm.getWindow() then CWm.toggle(0) end
        if not WWm.getWindow() then WWm.toggle(0) end
        -- (the guide's window, not the book: the book is not a ZeD window)
        if ZeD.Guide and ZeD.Guide.openWindow then pcall(ZeD.Guide.openWindow, 0) end
    end,
    function()
        cw, ww = CWm.getWindow(), WWm.getWindow()
        gw = ZeD.Guide and ZeD.Guide.get and ZeD.Guide.get(0) or nil
        check("1 the Character window open", cw ~= nil)
        check("1 the World window open", ww ~= nil)
        if not (cw and ww) then return "stop" end
        check("1 Character: Go to saved position greyed with its reason", greyed(cw))
        check("1 World: Go to saved position greyed with its reason", greyed(ww))
        if gw then check("1 guide: Go to saved position greyed with its reason", greyed(gw))
        else say("NOTRUN the guide (no window handle)") end
        CWm.openTab(0, "skills")
    end,
    function()
        cw:setX(120); cw._anchorRightEdge = 120 + cw:getWidth()
        cw:setY(60)
        WM.open(cw)
        say("SHOT menu_char_open")
    end,
    function()
        if WM.current then WM.current:close() end
        row(cw, "UI_ZeD_WinMenu_SavePos").onFire()
        say("SHOT saved_bubble")
        savedC = at(cw)
        check("2 Character saved", P.has(cw), savedC)
        local src = ZeD.Messages and ZeD.Messages.sources and ZeD.Messages.sources[ZeD.tr("UI_ZeD_WinMenu_SavedHead")]
        check("2 a Messages line for it", src ~= nil and #src.items == 1, src and #src.items)
        check("2 the drawer kept open on Skills", P.places.char and P.places.char.drawerOpen == true and P.places.char.activeTab == "skills")
        ZeD_Window.resetLayout("char")
    end,
    function()
        check("3 World still greyed after the Character's save", greyed(ww))
        row(cw, "UI_ZeD_WinMenu_GoSaved").onFire()
    end,
    function() end, function() end, function() end,   -- (the drawer slides open)
    function()
        say("SHOT after_go_saved_char")
        check("3 Character back on Skills, drawer open", cw._activeTab == "skills" and cw._drawerOpen == true, cw._activeTab)
        check("3 Character's left edge back (drawer grows left from the anchor)", cw._anchorRightEdge ~= nil, at(cw))
        say("INFO char now " .. at(cw) .. ", saved at " .. tostring(savedC))
        ww:setX(ww:getX() - 40); ww:setY(80)
        row(ww, "UI_ZeD_WinMenu_SavePos").onFire()
        savedW = at(ww)
        if gw then gw:setX(200); gw:setY(150); row(gw, "UI_ZeD_WinMenu_SavePos").onFire(); savedG = at(gw) end
        ZeD_Window.resetLayout()
        if gw then gw:setX(0); gw:setY(0) end
    end,
    function()
        row(ww, "UI_ZeD_WinMenu_GoSaved").onFire()
        if gw then row(gw, "UI_ZeD_WinMenu_GoSaved").onFire() end
    end,
    function() end, function() end,
    function()
        check("4 World back", ww:getX() .. "," .. ww:getY() == savedW:match("^(%S+)"), at(ww) .. " vs " .. savedW)
        if gw then check("4 guide back", at(gw) == savedG, at(gw) .. " vs " .. tostring(savedG)) end
        check("4 Character's place unchanged by the others", P.places.char and P.places.char.activeTab == "skills")
        local before = {}
        for k, v in pairs(P.places) do before[k] = v.x .. "," .. v.y end
        P.places = nil
        P.load()
        local same = true
        for k, v in pairs(before) do
            local r = P.places[k]
            if not (r and math.abs(r.x - tonumber(v:match("^([^,]+)"))) < 0.02) then same = false end
        end
        check("5 the file read again holds the same places", same)
        row(cw, "UI_ZeD_WinMenu_ResetThis").onFire()
        row(ww, "UI_ZeD_WinMenu_ResetBoth").onFire()
    end,
    function()
        local sw = getCore():getScreenWidth()
        check("6 Reset both: the World window from the middle", ww:getX() > math.floor(sw / 2) - 2 and ww:getY() == 0, at(ww))
        check("6 Reset both: the Character window left of the middle", cw:getX() + cw:getWidth() <= math.floor(sw / 2) and cw:getY() == 0, at(cw))
        check("6 the saved places stay", P.has(cw) and P.has(ww))
    end,
}

local i, wait = 0, 0
local function tick()
    wait = wait - 1
    if wait > 0 then return end
    i = i + 1
    local s = steps[i]
    local stop = false
    if s then
        local ok, r = pcall(s)
        if not ok then say("ERR step " .. i .. ": " .. tostring(r)); stop = true end
        if r == "stop" then stop = true end
    end
    if stop or i >= #steps then
        Events.OnTick.Remove(tick)
        P.places = keep
        P.flush()
        say("DONE pass " .. Q.pass .. " fail " .. Q.fail .. " (the player's saved places written back)")
        return
    end
    wait = 20
end
Events.OnTick.Add(tick)
