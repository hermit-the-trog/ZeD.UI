-- ZeDUI/tools/qa/zedqa_padfix_i.lua  (Nov 14 2026, QA): Build's 6088f4757. 234 Rename chosen twice for one bag opens
-- one box, and the box has the pad (with the box's isVisible / x / y / _dead, which Build asked for); 235 B on the
-- on-screen keyboard is Back: it closes and keeps what was typed, no question; 233 a craft station opened from the
-- world (ISEntityUI.OpenHandcraftWindow, as the A prompt does) puts the pad in the World window. grep "ZEDQA pfi".
local function say(s) print("ZEDQA pfi " .. tostring(s)) end
local nPass, nFail = 0, 0
local function check(ok, what) if ok then nPass = nPass + 1; say("PASS " .. what) else nFail = nFail + 1; say("FAIL " .. what) end end
local p = getPlayer()
local Focus = ZeD.Input.Focus
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
local function textBoxes()
    local out = {}
    local ui = UIManager.getUI()
    for j = 0, ui:size() - 1 do
        local t = ui:get(j):getTable()
        if t and (t.Type == "ISTextBox" or t.Type == "ZeD_Prompt") and t:isVisible() and not t._dead then out[#out + 1] = t end
    end
    return out
end
local bag, cw, S, kb
local steps, t0, i = {}, nil, 0
local function at(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
-- 234
at(300, function()
    ZeD_CharacterWindow.openTab(0, "equip"); cw = ZeD_CharacterWindow.getInstance(0)
    Focus.claimFocus(cw)
    bag = p:getInventory():AddItem("Base.Bag_Schoolbag")
    say("234 boxes before: " .. #textBoxes())
    ZeD.ItemMenu.rename(bag, 0, nil)
    ZeD.ItemMenu.rename(bag, 0, nil)   -- (the second run of one choice, as the director saw)
end)
at(1000, function()
    local bx = textBoxes()
    say("234 boxes after two Renames: " .. #bx)
    for k, b in ipairs(bx) do
        say(string.format("234 box %d visible=%s x=%d y=%d dead=%s reallyVisible=%s", k, tostring(b:isVisible()), b:getX(), b:getY(),
            tostring(b._dead), tostring(b:isReallyVisible())))
    end
    check(#bx == 1, "234 Rename chosen twice opens one box (" .. #bx .. ")")
    check(bx[1] ~= nil and getJoypadFocus(0) == bx[1], "234 the box has the pad (" .. desc(getJoypadFocus(0)) .. ")")
    pcall(function() getCore():TakeFullScreenshot("zqa_pfi_rename.png") end)
    ZeD.ItemMenu.closeRename()
end)
at(1600, function()
    check(#textBoxes() == 0, "234 the box goes when Rename is closed (" .. #textBoxes() .. " left)")
end)
-- 235: the Equip list's Find field, its keyboard, a typed letter, then B
at(2000, function()
    Focus.claimFocus(cw)
    local panel
    local function walk(o, depth)
        if panel or depth > 6 or type(o) ~= "table" then return end
        if o._zedFilter ~= nil then panel = o; return end
        local ok, kids = pcall(function() return o:getChildren() end)
        if ok and kids then for _, k in pairs(kids) do walk(k, depth + 1) end end
    end
    walk(cw, 0)
    say("235 list panel " .. tostring(panel))
    if not panel then return end
    S = ZeD.InvFilter.of(panel)
    if not S.open then ZeD.InvFilter.toggleOpen(S) end
end)
at(2500, function() if S then local ok, e = pcall(ZeD.InvFilter.editField, S, cw); say("235 editField ok " .. tostring(ok) .. " " .. tostring(e)) end end)
at(3000, function()
    kb = getJoypadFocus(0)
    say("235 pad on " .. desc(kb))
    if not (kb and kb.typeChar) then check(false, "235 the keyboard has the pad (" .. desc(kb) .. ")"); return end
    kb:typeChar("q"); kb:typeChar("a")
    say("235 typed, the field reads '" .. tostring(kb:getCurrentText()) .. "'")
    local footer = kb:getFooterPrompts()
    local bLabel
    for _, f in ipairs(footer or {}) do if f.glyph == "B" then bLabel = f.label end end
    check(bLabel == ZeD.tr("UI_ZeD_Prompt_Back"), "235 the help line reads B " .. tostring(bLabel))
    ZEDQA_PFI_ENTRY = kb.textEntryBox
    kb:onJoypadDown(Joypad.BButton, jd)
end)
at(3600, function()
    local f = getJoypadFocus(0)
    local up = kb and kb:isVisible()
    local txt = ZEDQA_PFI_ENTRY and ZEDQA_PFI_ENTRY:getInternalText() or "?"
    check(not up, "235 B closes the keyboard (visible " .. tostring(up) .. ", pad on " .. desc(f) .. ")")
    check(txt:lower():find("qa") ~= nil, "235 B keeps the typed text (the field reads '" .. tostring(txt) .. "')")
    check(f ~= nil and f.Type ~= "ISModalDialog" and f.Type ~= "ZeD_Prompt", "235 no question after B (" .. desc(f) .. ")")
    pcall(function() getCore():TakeFullScreenshot("zqa_pfi_keyboard.png") end)
    pcall(function() ZEDQA_PFI_ENTRY:setText(""); ZEDQA_PFI_ENTRY.javaObject:onTextChange() end)
    pcall(function() if S.open then ZeD.InvFilter.toggleOpen(S) end end)
end)
-- 233
at(4200, function()
    ZeD_WorldWindow.openTab(0, "loot")
    pcall(function() Focus.releaseFocus(0) end)
    setJoypadFocus(0, nil)
    say("233 pad before: " .. desc(getJoypadFocus(0)))
    local ok, e = pcall(function() ISEntityUI.OpenHandcraftWindow(p, nil, nil, nil, nil, nil) end)
    say("233 OpenHandcraftWindow ok " .. tostring(ok) .. " " .. tostring(e))
end)
at(5400, function()
    local ww = ZeD_WorldWindow.getWindow(0)
    local z = Focus.getFocusedZone(ww)
    check(ww and ww._activeTab == "craft", "233 the World window is on Craft (" .. tostring(ww and ww._activeTab) .. ")")
    check(getJoypadFocus(0) == ww, "233 the World window has the pad (" .. desc(getJoypadFocus(0)) .. ")")
    check(z and z.zone == "worldTabContent", "233 on the tab's first stop (zone " .. tostring(z and z.zone) .. ", id " ..
        tostring(Focus.getFocusedElement(ww) and Focus.getFocusedElement(ww).id) .. ")")
    pcall(function() getCore():TakeFullScreenshot("zqa_pfi_station.png") end)
    ZeD_WorldWindow.openTab(0, "loot")
    pcall(function() if bag:getContainer() then bag:getContainer():Remove(bag) end end)
    say("passed " .. nPass .. ", failed " .. nFail)
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
