-- ZeDUI/tools/qa/zedqa_px_icons.lua  (Oct 27 2026)
-- In game on the ZeD-QA save, after the prelude (both windows open): ZeD's pixel icons outside the wheels, the
-- ones that replaced the licensed pictures (the container row, the item card's marks, the windows' small
-- controls), at the UI scale in use.
--   1. checks: every id has its drawings; the box rule picks 16 / 24 / 32 / 48 as the wheels do; the chevrons
--      draw with no picture;
--   2. a test panel: every icon in an icon button at rest, pointed at, lit, off and in the warning colour; the
--      item card's mark strip wide and narrow, off and on; the chevrons at 5 to 16 units in four directions;
--   3. the real windows: the item card on the first thing in the bag with Fav and Dispose on (put back after),
--      and both container rows at the bottom of the lists.
-- Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep "ZEDQA px"; captures Screenshots/zqa_px_*.png.
local function say(s) print("ZEDQA px " .. tostring(s)) end
local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
local fails = 0
local function check(ok, what) if ok then say("ok " .. what) else fails = fails + 1; say("ERR " .. what) end end

local ROW = { "tray_out", "same_type", "same_nearby", "tray_in", "to_floor", "trash", "power", "gears", "match",
    "campfire", "extinguisher", "padlock" }
local CARD = { "star", "craft_off", "trash" }
local SCREENS = { "view_list", "view_grid", "stand", "expand", "contract", "pop_out", "no", "move_up", "move_down",
    "pencil", "car_exit", "help", "info", "stop" }
local ALL = {}
for _, l in ipairs({ ROW, CARD, SCREENS }) do for _, id in ipairs(l) do ALL[#ALL + 1] = id end end

-- 1. the drawings and the box rule
local box = T.px(16)
local want = (box >= 48 and 48) or (box >= 32 and 32) or (box >= 24 and 24) or (box >= 16 and 16) or box
say("scale " .. tostring(T.scale) .. ": the 16-unit icon box is " .. box .. " px, the drawing for it " .. want)
local missing = {}
for _, id in ipairs(ALL) do
    for _, s in ipairs({ 16, 24, 32, 48 }) do
        local t = ZeD.PxIcon.tex(id, s)
        if not t then missing[#missing + 1] = id .. "@" .. s end
    end
    local _, got = ZeD.PxIcon.tex(id, box)
    if got ~= want then missing[#missing + 1] = id .. " drew " .. tostring(got) end
end
check(#missing == 0, #ALL .. " icons, four drawings each, the box picks " .. want .. (#missing > 0 and (": " .. table.concat(missing, ", ")) or ""))
check(ZeD.PxIcon.has("tray_in") and not ZeD.PxIcon.has("inbox-in"), "a licensed name is no pixel icon (the row falls back to words, not a picture)")
check(ZeD.Wheel and ZeD.Wheel.iconTex("bed", 24) == (ZeD.PxIcon.tex("bed", 24)), "the wheels use the same lookup")

-- 2. the test panel
local P = ISPanel:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight())
P:initialise(); P.backgroundColor = { r = 0.08, g = 0.08, b = 0.08, a = 1 }
local STATES = {
    { "rest", {} }, { "pointed", { hover = true } }, { "lit", { active = true } },
    { "off", { disabled = true } }, { "warning", { tint = T.danger } },
}
local drawErr
function P:render()
    local ok, e = pcall(function()
        local bh = T.buttonH
        local x0, y = T.px(150), T.px(20)
        local f = T.fontF3
        for si, st in ipairs(STATES) do
            self:drawText(st[1], T.px(20), y + math.floor((bh - ZeD.TM:getFontHeight(f)) / 2), 0.8, 0.8, 0.8, 1, f)
            for i, id in ipairs(ALL) do
                local o = {}
                for k, v in pairs(st[2]) do o[k] = v end
                o.iconSize = T.px(16)
                M.drawIconButton(self, x0 + (i - 1) * (bh + T.px(4)), y, bh, id, o)
            end
            y = y + bh + T.px(8)
        end
        -- the item card's marks: wide and narrow, all off, all on, one each
        y = y + T.px(10)
        local combos = { {}, { fav = true, nocraft = true, dispose = true }, { fav = true, dispose = true } }
        for _, compact in ipairs({ false, true }) do
            local x = T.px(20)
            for _, mk in ipairs(combos) do
                local w = compact and T.px(220) or T.px(480)
                M.drawCardFlagStrip(self, x, y, w, mk, compact, {}, { hover = { fav = false, nocraft = false, dispose = false } })
                x = x + w + T.px(20)
            end
            y = y + T.px(36)
        end
        -- the chevrons, drawn with no picture
        y = y + T.px(10)
        local x = T.px(20)
        for _, u in ipairs({ 5, 6, 8, 10, 12, 16 }) do
            local s = T.px(u)
            A.drawTriangleRight(self, x, y, s, T.text); A.drawTriangleDown(self, x + s + T.px(6), y, s, T.text)
            A.drawTriangleLeft(self, x + 2 * (s + T.px(6)), y, s, T.text); A.drawTriangleUp(self, x + 3 * (s + T.px(6)), y, s, T.text)
            x = x + 4 * (s + T.px(6)) + T.px(20)
        end
    end)
    if not ok and not drawErr then drawErr = tostring(e); say("ERR the test panel: " .. drawErr) end
end

local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local function shot(name) pcall(function() getCore():TakeFullScreenshot("zqa_px_" .. name .. ".png") end); say("shot zqa_px_" .. name) end

-- 3. the real windows
local item, before
local function CW() return ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow() end
local function selectItem(it)
    local w = CW()
    local c = w and w._mainContent
    if not c then return false end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    if it then sel[it] = true end
    c._selectedItems, c._lastClickedItem = sel, it
    w._updateDrawer(c)
    return true
end
local function shape()
    local s = ""
    for _, w in ipairs({ CW(), ZeD_WorldWindow and ZeD_WorldWindow.getWindow() }) do
        if w then s = s .. w:getX() .. "," .. w:getY() .. "," .. w:getWidth() .. "," .. w:getHeight() .. "," .. tostring(w._drawerEffW) .. ";" end
    end
    return s
end

at(5, function() P:addToUIManager() end)
at(40, function() shot("panel"); check(drawErr == nil, "the test panel drew") end)
at(45, function() P:removeFromUIManager() end)
at(50, function()
    local inv = getPlayer():getInventory():getItems()
    for i = 0, inv:size() - 1 do
        local it = inv:get(i)
        if it and not it:isEquipped() then item = it; break end
    end
    if not item then say("ERR nothing loose in the bag for the card"); return end
    before = { fav = item:isFavorite(), dis = ZeD.ActionStrip.getState(item, "unwanted", 0) }
    item:setFavorite(true)
    ZeD.ActionStrip.setState(item, "unwanted", true, 0)
    check(selectItem(item), "the card opened on " .. tostring(item:getDisplayName()))
end)
-- wait for the windows to stop moving, then shoot the card
local still, last, waited = 0, nil, 0
local function poll(k)
    local s = shape()
    if s == last then still = still + 1 else still, last = 0, s end
    waited = waited + 1
    return still >= 30 or waited >= 900
end
local phase = "card"
at(60, function() phase = "wait_card" end)

local k, i = 0, 1
local function tick()
    k = k + 1
    if phase == "wait_card" then
        if poll() then
            if still < 30 then say("WARN the windows were still moving: captured anyway") end
            shot("card")
            local w = CW()
            local r = w and w._drawerPanel and w._drawerPanel._itemCard and w._drawerPanel._itemCard.toggleRects
            say("card toggle rects " .. tostring(r and #r))
            if item and before then
                item:setFavorite(before.fav)
                ZeD.ActionStrip.setState(item, "unwanted", before.dis, 0)
            end
            selectItem(nil)
            still, last, waited = 0, nil, 0
            phase = "wait_rows"
        end
        return
    elseif phase == "wait_rows" then
        if poll() then
            shot("rows")
            check(item == nil or (item:isFavorite() == before.fav), "Fav put back")
            say("DONE " .. fails .. " failed")
            phase = "done"
            Events.OnRenderTick.Remove(tick)
        end
        return
    end
    while steps[i] and steps[i].n <= k do local ok, e = pcall(steps[i].f); if not ok then say("step error " .. tostring(e)) end; i = i + 1 end
end
Events.OnRenderTick.Add(tick)
