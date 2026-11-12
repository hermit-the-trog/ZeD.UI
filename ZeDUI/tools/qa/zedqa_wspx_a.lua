-- ZeDUI/tools/qa/zedqa_wspx_a.lua  (Nov 11 2026, QA; tag wspa): the window menu's Save position, first half of the 4K-to-Deck check. Run after zedqa_window_saved_pos.lua (which puts the
-- player's places back) in a 4K launch: nothing saved -> Go to saved position greyed; the Character window moved to the lower right and saved by the PAD's route (D-pad, A), the World window
-- by the MOUSE's route (a click on the row); a Messages notice each. The places stay in Zomboid/Lua/ZeD_window_places.txt for zedqa_wspx_b.lua in a Deck launch (the wrapper puts the player's file back). grep "ZEDQA wspa".
local function say(s) print("ZEDQA wspa " .. tostring(s)) end
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
        P.places = {}
        if not CWm.getWindow() then CWm.toggle(0) end
        if not WWm.getWindow() then WWm.toggle(0) end
    end,
    function()
        cw, ww = CWm.getWindow(), WWm.getWindow()
        local g1 = greyedRow(cw)
        check("nothing saved: Go to saved position greyed (Character)", g1 == true)
        check("nothing saved: Go to saved position greyed (World)", greyedRow(ww) == true)
        local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
        say("screen " .. sw .. "x" .. sh .. "; Character " .. cw:getWidth() .. "x" .. cw:getHeight() .. ", World " .. ww:getWidth() .. "x" .. ww:getHeight())
        cw:setX(sw - cw:getWidth() - 20); cw:setY(sh - cw:getHeight() - 60); cw._anchorRightEdge = cw:getX() + cw:getWidth()
        ww:setX(sw - ww:getWidth() - 40); ww:setY(sh - ww:getHeight() - 100)
        P.places = {}
        say("Character moved to " .. cw:getX() .. "," .. cw:getY())
        WM.open(cw)
    end,
    function()
        local n0 = msgCount()
        local ok, why = padRow(WM.current, "UI_ZeD_WinMenu_SavePos")
        check("Save position by the pad (D-pad down, A) on the Character window", ok and P.has(cw), why)
        check("saving shows a Messages notice", msgCount() == n0 + 1, n0 .. " -> " .. msgCount())
        say("SHOT saved_bubble_4k")
    end,
    function() if WM.current then WM.current:close() end; WM.open(ww) end,
    function()
        local n0 = msgCount()
        local ok, why = clickRow(WM.current, "UI_ZeD_WinMenu_SavePos")
        check("Save position by the mouse (a click on the row) on the World window", ok and P.has(ww), why)
        check("saving shows a Messages notice (World)", msgCount() == n0 + 1, n0 .. " -> " .. msgCount())
    end,
    function()
        local pc = P.places.char
        say("saved Character: " .. tostring(pc and (pc.x .. "," .. pc.y)) .. "; World: " .. tostring(P.places.world and (P.places.world.x .. "," .. P.places.world.y)))
        P.flush()
        ZeD_Window.resetLayout()
    end,
}
runSteps(steps, nil)
say("start")