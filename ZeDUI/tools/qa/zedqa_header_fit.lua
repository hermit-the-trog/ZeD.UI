-- ZeDUI/tools/qa/zedqa_header_fit.lua  (Oct 16 2026)
-- At the main menu (fonts only, no world needed): would a container's own
-- buttons fit in the list's heading, between the name and the weight? Uses
-- the list column's usual width (372 design units) and the heading's layout
-- in InventoryRenderer (padX, the icon at the name's font height, iconGap, the
-- weight / count stack on the right), the button width of ObjectCards
-- UI.buttonW and a 5-unit gap, for both text sizes. grep "ZEDQA hf".
local function say(s) print("ZEDQA hf " .. tostring(s)) end
local T, tm = ZeD.T, ZeD.TM
local GAP = 5
local cases = {
    { "Campfire", "1.7/15kg", { "Light", "Add fuel", "Take apart" } },
    { "Campfire", "1.7/15kg", { "Add fuel", "Put out" } },
    { "Campfire", "1.7/15kg", { "Light", "Add fuel", "Take apart", "Add corpse" } },
    { "Stove", "0.8/15kg", { "Turn on", "Settings" } },
    { "Trunk", "11.4/80kg", { "Close trunk", "Lock trunk" } },
    { "Washing Machine", "3.1/20kg", { "Turn off" } },
    { "Clothes Dryer", "3.1/20kg", { "Turn on" } },
    { "Washer/Dryer", "0.0/20kg", { "Set mode: dryer", "Turn on" } },
    { "Mannequin", "2.6/10kg", { "Wear all", "Switch outfits" } },
    { "Mannequin", "0.0/10kg", { "Store worn outfit" } },
    { "Propane Barbecue", "0.0/5kg", { "Turn on", "Remove tank" } },
    { "Propane Barbecue", "0.0/5kg", { "Insert tank" } },
    { "Trash Can", "2.9/10kg", { "Delete all" } },
}
local function run(sizeName)
    local colW = T.px(372)
    local padX = T.sp.sm
    local f4H = tm:getFontHeight(T.fontF4)
    for _, c in ipairs(cases) do
        local name, wt, btns = c[1], c[2], c[3]
        local nameW = tm:MeasureStringX(T.fontF4, name)
        local stackW = math.max(tm:MeasureStringX(T.fontF1, wt), tm:MeasureStringX(T.fontF5, "20 items"))
        local room = colW - padX - (f4H + T.sp.iconGap) - nameW - T.px(8) - T.px(8) - stackW - padX
        local need = 0
        for i, b in ipairs(btns) do need = need + ZeD.ObjectCards.ui.buttonW(b) + (i > 1 and T.px(GAP) or 0) end
        say(string.format("%-6s %-17s room %3d need %3d %s  [%s]", sizeName, name, room, need,
            need <= room and "FITS" or ("short by " .. (need - room)), table.concat(btns, ", ")))
    end
end
local done = false
local function tick()
    if done then return end
    done = true
    Events.OnFETick.Remove(tick)
    -- both text sizes (ZeD.applyTheme(base, accent, size)), then back
    local base, accent, size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    for _, sz in ipairs({ "small", "large" }) do
        pcall(ZeD.applyTheme, base, accent, sz)
        local ok, e = pcall(run, sz)
        if not ok then say("ERR " .. tostring(e)) end
    end
    pcall(ZeD.applyTheme, base, accent, size)
    say("DONE")
end
Events.OnFETick.Add(tick)
