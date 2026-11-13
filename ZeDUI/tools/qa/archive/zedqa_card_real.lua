-- ZeDUI/tools/qa/zedqa_card_real.lua  (Nov 6 2026, QA): a real item card over a World tab, with the real mouse: press a row, the card comes up; press the same row, or the card's X, and
-- it goes. Is the window whole after? The Nov 6 sweep's scripted close left a see-through hole where the card was on Crafting and Ranch. After zedqa_animals.lua. Run with
-- batch_card_real.ps1. Pictures zqa_crr_<tab>_<n>.png. grep "ZEDQA crr".
local function say(s) print("ZEDQA crr " .. tostring(s)) end
local WWm = ZeD_WorldWindow
local WW = WWm.getWindow
local function req(s) local f = getFileWriter("zedqa_click.txt", true, false); f:write(s .. "\n"); f:close() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_crr_" .. n .. ".png") end) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function state(tag)
    local w = WW()
    local d = w._drawerPanel
    say(tag .. ": tab=" .. tostring(w._activeTab) .. " mode=" .. tostring(w._drawerMode) .. " card=" .. tostring(w._drawerItem ~= nil) .. " tabUnder=" .. tostring(w._tabUnder)
        .. " clips=" .. tostring(d and d._zedStencilN) .. " coverL=" .. tostring(d and d._coverL))
end
local function rowXY()
    local w = WW()
    local cc = w._mainContent
    for _, z in ipairs(w._focusRing or {}) do
        if tostring(z.zone):find("MainInv", 1, true) then
            for _, e in ipairs(z.elements or {}) do
                if tostring(e.id):find("invrow", 1, true) and type(e.x) == "number" then
                    return math.floor(cc:getAbsoluteX() + e.x + 170), math.floor(cc:getAbsoluteY() + e.y + (e.h or 20) / 2)
                end
            end
        end
    end
    return math.floor(cc:getAbsoluteX() + 200), math.floor(cc:getAbsoluteY() + 110 * ZeD.T.scale)
end
add(500, function() if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end end)
for _, id in ipairs({ "craft", "animals" }) do
    add(2000, function() WWm.openTab(0, id) end)
    add(1500, function() state(id .. " open"); shot(id .. "_0_open"); local x, y = rowXY(); say("press " .. x .. "," .. y); req("left " .. x .. " " .. y) end)
    add(6000, function() state(id .. " after the press"); shot(id .. "_1_card") end)
    add(6000, function()
        state(id .. " after the second press")
        shot(id .. "_2_row_again")
        local w = WW()
        if w._drawerItem and w._itemCard then
            local x, y = math.floor(w._itemCard:getAbsoluteX() + 24), math.floor(w._itemCard:getAbsoluteY() + 24)
            say("the card's X at " .. x .. "," .. y); req("left " .. x .. " " .. y)
        end
    end)
    add(6000, function() state(id .. " after the X"); shot(id .. "_3_closed"); req("move 3000 1800") end)
    add(1500, function() state(id .. " mouse away"); shot(id .. "_4_away") end)
end
add(500, function() WWm.openTab(0, "loot"); say("DONE") end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); if i > #plan then say("DONE") end end
end
Events.OnTick.Add(drive)
