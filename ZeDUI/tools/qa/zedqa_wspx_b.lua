-- ZeDUI/tools/qa/zedqa_wspx_b.lua  (Nov 11 2026, QA; tag wspb): second half: in a Deck-size launch the places saved at 4K by zedqa_wspx_a.lua. Go to saved position is live (not greyed); the Character
-- window goes back by the MOUSE's route and the World window by the PAD's, each fully on screen (not off the edge). grep "ZEDQA wspb".
local function say(s) print("ZEDQA wspb " .. tostring(s)) end
if not (ZeD.WindowPlaces and ZeD.WindowMenu) then say("ERR no window places"); return end
local P, WM = ZeD.WindowPlaces, ZeD.WindowMenu
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local Q = { pass = 0, fail = 0 }
local function check(name, ok, detail)
    if ok then Q.pass = Q.pass + 1; say("PASS " .. name)
    else Q.fail = Q.fail + 1; say("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function rowIndex(m, key)
    local lv = m._levels and m._levels[1]
    for ri, r in ipairs(lv and lv.rows or {}) do if r.def and r.def.name == ZeD.tr(key) then return ri end end
end
-- the mouse's route: the menu's own click on the row (onMouseUp at the row's hit zone)
local function clickRow(m, key)
    local ri = rowIndex(m, key)
    if not ri then return false, "no row" end
    for _, z in ipairs(m._hitZones or {}) do
        if z.id == "row:1:" .. ri then m._openPress = false; m:onMouseUp(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)); return true end
    end
    return false, "no hit zone"
end
-- the pad's route: D-pad down to the row, then A
local function padRow(m, key)
    local ri = rowIndex(m, key)
    if not ri then return false, "no row" end
    local lv = m._levels[1]
    lv.sel = 0
    for _ = 1, #lv.rows + 1 do
        m:onJoypadDirDown()
        if lv.sel == ri then break end
    end
    if lv.sel ~= ri then return false, "pad could not reach the row (on " .. tostring(lv.sel) .. ")" end
    m:onJoypadDown(Joypad.AButton)
    return true
end
local function onScreen(win)
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    return win:getX() >= 0 and win:getY() >= 0 and win:getX() + win:getWidth() <= sw and win:getY() + win:getHeight() <= sh, win:getX() .. "," .. win:getY() .. " " .. win:getWidth() .. "x" .. win:getHeight() .. " on " .. sw .. "x" .. sh
end
local function msgCount()
    local src = ZeD.Messages and ZeD.Messages.sources and ZeD.Messages.sources[ZeD.tr("UI_ZeD_WinMenu_SavedHead")]
    return src and #src.items or 0
end
local function greyedRow(win)
    for _, it in ipairs(WM.build(win)) do
        if it.name == ZeD.tr("UI_ZeD_WinMenu_GoSaved") then return it.disabled(win) == true, it.state and it.state(win) end
    end
end
local function runSteps(steps, tail)
    local i, wait = 0, 0
    local function tick()
        wait = wait - 1
        if wait > 0 then return end
        i = i + 1
        local s = steps[i]
        if s then local ok, r = pcall(s); if not ok then say("ERR step " .. i .. ": " .. tostring(r)); i = #steps end end
        if i >= #steps then Events.OnTick.Remove(tick); if tail then pcall(tail) end; say("DONE pass " .. Q.pass .. " fail " .. Q.fail); return end
        wait = 25
    end
    Events.OnTick.Add(tick)
end
local cw, ww
local steps = {
    function()
        P.places = nil
        P.load()
        if not CWm.getWindow() then CWm.toggle(0) end
        if not WWm.getWindow() then WWm.toggle(0) end
    end,
    function()
        cw, ww = CWm.getWindow(), WWm.getWindow()
        check("the saved places were read from the file", P.has(cw) and P.has(ww))
        check("Go to saved position is live now (Character)", greyedRow(cw) == false, tostring(greyedRow(cw)))
        say("Deck screen " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight() .. "; saved Character at " .. tostring(P.places.char and (P.places.char.x .. "," .. P.places.char.y)))
        WM.open(cw)
    end,
    function()
        local ok, why = clickRow(WM.current, "UI_ZeD_WinMenu_GoSaved")
        check("Go to saved position by the mouse (Character)", ok, why)
    end,
    function() end, function() end, function() end,
    function()
        local ok, d = onScreen(cw)
        check("the Character window is fully on screen after Go to saved position", ok, d)
        say("SHOT after_go_saved_deck_char")
        WM.open(ww)
    end,
    function()
        local ok, why = padRow(WM.current, "UI_ZeD_WinMenu_GoSaved")
        check("Go to saved position by the pad (World)", ok, why)
    end,
    function() end, function() end, function() end,
    function()
        local ok, d = onScreen(ww)
        check("the World window is fully on screen after Go to saved position", ok, d)
        say("SHOT after_go_saved_deck_world")
    end,
}
runSteps(steps, nil)
say("start")