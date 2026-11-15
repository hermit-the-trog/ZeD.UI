-- ZeDUI/tools/qa/zedqa_b15_diag.lua  (Nov 15 2026, QA): why three of zedqa_b15's checks missed, in the game.
-- 245 the open stack's header: its own onActivate called straight, then A through the pad, read after each.
-- 242 the paused balloon's reasons (paused, pause menu, what covers the middle) printed one by one.
-- 237 the aim: how often the right stick's read is asked while the stub holds it over, and the pad's holder.
-- grep "ZEDQA b15d".
local function say(s) print("ZEDQA b15d " .. tostring(s)) end
local p = getPlayer()
local Focus = ZeD.Input.Focus
local Det = ZeD.Input.Detector
local jd = JoypadState.players[1]
if not jd then
    for i = 0, 15 do
        local c = JoypadState.controllers[i]
        if c and c.connected then
            pcall(function() triggerEvent("OnJoypadActivate", i) end)
            jd = JoypadState.players[1] or JoypadState.joypads[1]
            if jd and not JoypadState.players[1] then pcall(function() p:setJoypadBind(i); jd.player = 0; JoypadState.players[1] = jd end) end
            break
        end
    end
end
jd = JoypadState.players[1]
local function desc(o) if o == nil then return "nil" end return tostring(o._zedLabel or o.Type or o) end
local RAG = "Base.RippedSheets"
local cw, rags = nil, {}
local function head()
    for _, s in ipairs(Focus.flatElements(cw)) do if s.el and s.el.isStackHead and s.el.stackKey == RAG then return s end end
end
local function nRows()
    local n = 0
    for _, s in ipairs(Focus.flatElements(cw)) do if s.zone == "charMainInv" and s.el and s.el.item and not s.el.isStackHead and s.el.item:getFullType() == RAG then n = n + 1 end end
    return n
end
local function expanded() local c = cw._mainContent; return c and c._expandedStacks and c._expandedStacks[RAG] end
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
at(300, function()
    ZeD_CharacterWindow.openTab(0, "equip"); cw = ZeD_CharacterWindow.getInstance(0)
    local inv = p:getInventory()
    local had = inv:getItemsFromFullType(RAG)
    for k = (had and had:size() or 0), 2 do rags[#rags + 1] = inv:AddItem(RAG) end
    cw._mainContent._expandedStacks = cw._mainContent._expandedStacks or {}
    cw._mainContent._expandedStacks[RAG] = true
end)
at(1200, function()
    Focus.claimFocus(cw)
    local h = head()
    say("245 open: rows " .. nRows() .. ", header " .. tostring(h and h.id) .. ", expanded " .. tostring(expanded()))
    if h then
        Focus.focusWhere(cw, h.zone, function(e) return e.isStackHead end)
        local el = Focus.getFocusedElement(cw)
        say("245 focused " .. tostring(el and el.id) .. " onActivate " .. tostring(el and el.onActivate))
        el.onActivate(cw, el)
        say("245 after its onActivate straight: expanded " .. tostring(expanded()))
    end
end)
at(2000, function()
    say("245 a frame later: rows " .. nRows() .. ", expanded " .. tostring(expanded()) .. ", focused " .. tostring(Focus.getFocusedElement(cw) and Focus.getFocusedElement(cw).id))
    cw._mainContent._expandedStacks[RAG] = true
end)
at(2800, function()
    local h = head()
    if h then Focus.focusWhere(cw, h.zone, function(e) return e.isStackHead end) end
    local el = Focus.getFocusedElement(cw)
    say("245 pad: focused " .. tostring(el and el.id) .. ", drawer " .. tostring(cw._drawerMode) .. ", pad on " .. desc(getJoypadFocus(0)))
    Det.setLockedMode(Det.MODE_GAMEPAD)
    Focus.qaButton("A", true); Focus.dispatchJoypadDown(cw, Joypad.AButton, jd)
end)
at(2950, function() Focus.qaButton("A", false) end)
at(3200, function() Focus.qaButton("A", nil); Det.setLockedMode(nil) end)
at(3600, function()
    say("245 after A by the pad: rows " .. nRows() .. ", expanded " .. tostring(expanded()) .. ", focused " ..
        tostring(Focus.getFocusedElement(cw) and Focus.getFocusedElement(cw).id) .. ", pad on " .. desc(getJoypadFocus(0)))
    pcall(function() getCore():TakeFullScreenshot("zqa_b15d_header.png") end)
    cw._mainContent._expandedStacks[RAG] = nil
end)

-- 242
local cover
at(4000, function()
    setGameSpeed(0)
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    cover = ISPanel:new(sw / 2 - 300, sh / 2 - 200, 600, 400)
    cover:initialise(); cover:addToUIManager(); cover:setVisible(true)
end)
at(4800, function()
    local PN = ZeD.PausedNotice
    say("242 isGamePaused " .. tostring(isGamePaused and isGamePaused()) .. ", pauseMenuUp " .. tostring(Focus.pauseMenuUp and Focus.pauseMenuUp()) ..
        ", wanted " .. tostring(PN and PN.wanted and PN.wanted(nil)))
    local cx, cy = math.floor(getCore():getScreenWidth() / 2), math.floor(getCore():getScreenHeight() / 2)
    local uis = UIManager.getUI()
    for j = 0, uis:size() - 1 do
        local ui = uis:get(j)
        local x, y = ui:getAbsoluteX(), ui:getAbsoluteY()
        local over = cx >= x and cy >= y and cx < x + ui:getWidth() and cy < y + ui:getHeight()
        local okC, takes = pcall(function() return ui:isConsumeMouseEvents() end)
        local t = ui:getTable()
        say(string.format("242 ui %d %s visible=%s over=%s consume=%s/%s x=%d y=%d w=%d h=%d", j, tostring(t and t.Type or ui),
            tostring(ui:isVisible()), tostring(over), tostring(okC), tostring(takes), x, y, ui:getWidth(), ui:getHeight()))
    end
    pcall(function() getCore():TakeFullScreenshot("zqa_b15d_paused.png") end)
    cover:removeFromUIManager()
    setGameSpeed(1)
end)

-- 237
local realAxis = getControllerAxisValue
local asks = 0
local MW = ZeD.MessagesWindow
at(5400, function()
    ZeD_CharacterWindow.openTab(0, "equip"); ZeD_WorldWindow.openTab(0, "loot")
    pcall(function() Focus.releaseFocus(0) end)
    setJoypadFocus(0, nil)
    pcall(function() MW.open(0) end)
end)
at(6600, function()
    say("237 pad on " .. desc(getJoypadFocus(0)) .. ", foreignHolder " .. desc(Focus.foreignHolder(0)) .. ", MW.get " .. desc(MW.get(0)) ..
        ", same " .. tostring(Focus.foreignHolder(0) == MW.get(0)) .. ", count " .. tostring(getControllerCount and getControllerCount()) ..
        ", jd.id " .. tostring(jd and jd.id))
    getControllerAxisValue = function(c, a) asks = asks + 1; if a == 2 then return 0.9 end return realAxis(c, a) end
end)
at(7400, function()
    getControllerAxisValue = realAxis
    local mw = MW.get(0)
    say("237 the stick read was asked " .. asks .. " times; Character up " .. tostring(cw:isVisible() and not cw.windowShaded) ..
        ", Messages up " .. tostring(mw and mw:isVisible()))
end)
at(8000, function()
    pcall(function() local mw = MW.get(0); if mw and mw:isVisible() then mw:close() end end)
    for _, r in ipairs(rags) do pcall(function() if r:getContainer() then r:getContainer():Remove(r) end end) end
    say("DONE")
end)
local function tick()
    local now = getTimestampMs()
    if not t0 then t0 = now end
    while steps[i + 1] and now - t0 >= steps[i + 1].ms do
        i = i + 1
        local ok, e = pcall(steps[i].fn)
        if not ok then say("ERR step " .. i .. " " .. tostring(e)) end
    end
    if i >= #steps then Events.OnRenderTick.Remove(tick) end
end
Events.OnRenderTick.Add(tick)
say("start")
