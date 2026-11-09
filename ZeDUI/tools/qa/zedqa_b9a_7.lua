-- ZeDUI/tools/qa/zedqa_b9a_7.lua  (Nov 8 2026, hotfix 0.3.0-beta9a, fix 7): the item card scrolls until its last row
-- clears the care verbs' band at its foot. The director's sequence with the mouse: a card with a long "Used to make"
-- (nails: many recipes take them) opened from the Character list (the 220 card), scrolled to its end by dragging the
-- scrollbar's thumb to the bottom; the last "Used to make" row must sit wholly above the band. Then the Equip tab's
-- card on the full drawer (480 where the screen gives it room): a worn thing's card, scrolled to its end the same way,
-- its last line above the band. Run at 4K and at the Deck, Normal and Large text (the script reads the screen and the
-- text size; it sets neither). The REAL mouse (release_check_mouse.ps1: down, move, up), so run it with
-- batch_b9a.ps1. grep "ZEDQA b9a7". Pictures zqa_b9a7_<w>x<h>_<n>.png.
local TAG = "b9a7"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, s) if ok then pass = pass + 1 else fail = fail + 1 end; say((ok and "PASS " or "FAIL ") .. s); return ok end
if ZEDQA_HOME then ZEDQA_HOME(TAG) end
local p = getPlayer()
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
say("screen " .. sw .. "x" .. sh .. ", text size " .. tostring(ZeD.Settings and ZeD.Settings.textSize and ZeD.Settings.textSize()))
local CWm = ZeD_CharacterWindow
local function CW() return CWm.getWindow() end
local function req(s) local f = getFileWriter("zedqa_click.txt", true, false); f:write(s .. "\n"); f:close() end
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_" .. TAG .. "_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local keepPins, keepTab
local function rowOf(win, fullType)
    local c = win._mainContent
    for _, it in ipairs(c and c._flatItems or {}) do
        if it:getFullType() == fullType then
            local y = c._itemRenderYMap and c._itemRenderYMap[it]
            if not y then return nil end
            local x = (c._itemRenderXMap and c._itemRenderXMap[it]) or 0
            local cell = c._gridCell
            return it, math.floor(c:getAbsoluteX() + x + (cell and cell / 2 or 170)), math.floor(c:getAbsoluteY() + y + (cell and cell / 2 or ZeD.T.rowH / 2))
        end
    end
end
-- drag a card's scrollbar thumb from its top to past its bottom (the real mouse)
local function scrollToEnd(label, card)
    add(600, function()
        local c = card()
        local sb = c and c._sb
        if not check(sb and sb.visible, label .. ": the card has a scrollbar (" .. tostring(c and c:getWidth()) .. " wide)") then return end
        local x = math.floor(c:getAbsoluteX() + sb.x + sb.width / 2)
        req("down " .. x .. " " .. math.floor(c:getAbsoluteY() + sb.y + sb.arrowH + 6))
    end)
    add(600, function()
        local c = card(); local sb = c and c._sb
        if sb then req("move " .. math.floor(c:getAbsoluteX() + sb.x + sb.width / 2) .. " " .. math.floor(c:getAbsoluteY() + sb.y + sb.height + 200)) end
    end)
    add(600, function()
        local c = card(); local sb = c and c._sb
        if sb then req("up " .. math.floor(c:getAbsoluteX() + sb.x + sb.width / 2) .. " " .. math.floor(c:getAbsoluteY() + sb.y + sb.height + 200)) end
    end)
    add(800, function()
        local c = card()
        if not c then return end
        local viewH = c:getHeight() - (c._headH or 0) - (c._verbStripResvH or 0)
        local maxScroll = (c._contentH or 0) - viewH
        say(label .. ": width " .. c:getWidth() .. ", band " .. tostring(c._verbStripResvH) .. ", scroll " .. tostring(c._scrollPixels) .. " of " .. maxScroll)
        check(c._scrollPixels == maxScroll, label .. ": the scroll reaches the end of the body (" .. tostring(c._scrollPixels) .. " = " .. maxScroll .. ")")
        local bandTop = c:getAbsoluteY() + c:getHeight() - (c._verbStripResvH or 0)
        local last = c._makeRects and c._makeRects[#c._makeRects]
        if last then
            check(last.y + last.h <= bandTop, label .. ": the last \"Used to make\" row clears the band (" .. (last.y + last.h) .. " <= " .. bandTop .. ")")
        else
            say(label .. ": (no Used to make rows on this card)")
        end
        shot(label:gsub("[^%w]", "_"))
    end)
end

add(500, function()
    local t = p:getModData().ZeD_WinPinned
    if t then keepPins = {}; for k, v in pairs(t) do keepPins[k] = v end end
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
    keepTab = CW()._activeTab
    CW():setPinned(true)
    CWm.openTab(0, "loot")
    p:getInventory():AddItem("Base.Nails")
end)
add(1500, function()
    local it, x, y = rowOf(CW(), "Base.Nails")
    if check(it ~= nil, "the nails' row is on screen") then req("left " .. x .. " " .. y) end
end)
add(1500, function()
    local c = CW()._itemCard
    check(c and c.item ~= nil and c:isVisible(), "a click on the row opens its card")
    shot("1_card")
end)
scrollToEnd("the 220 card", function() return CW()._itemCard end)
-- the Equip tab's card (a worn thing): its drawer is the full card where the screen has room
add(800, function()
    CWm.openTab(0, "equip")
end)
add(1500, function()
    local c = CW()
    local z
    for _, zz in ipairs(c._equipSlotZones or {}) do if zz.item then z = zz; break end end
    local panel = c._equipPanel
    if check(z ~= nil and panel ~= nil, "a worn thing's slot on the Equip tab") then
        req("left " .. math.floor(panel:getAbsoluteX() + z.x + z.w / 2) .. " " .. math.floor(panel:getAbsoluteY() + z.y + z.h / 2))
    end
end)
add(1500, function()
    local panel = CW()._equipPanel
    local card = panel and panel._equipCard
    check(card and card:isVisible(), "the Equip tab's card opens (" .. tostring(card and card:getWidth()) .. " wide)")
    shot("2_equip_card")
end)
scrollToEnd("the Equip card", function() local panel = CW()._equipPanel; return panel and panel._equipCard end)
add(800, function()
    CW()._equipSelected = nil
    if keepPins then
        p:getModData().ZeD_WinPinned = keepPins
        local a, b = keepPins.charInv, keepPins.charTabs
        if a == nil and b == nil then a, b = keepPins.char == true, keepPins.char == true end
        ZeD.Halves.setPin(CW(), "inv", a == true); ZeD.Halves.setPin(CW(), "drawer", b == true)
    end
    if keepTab and keepTab ~= "equip" then CWm.openTab(0, keepTab) end
    say(string.format("RESULT %d pass, %d fail", pass, fail))
    say("DONE")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then fail = fail + 1; say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
say("start")
