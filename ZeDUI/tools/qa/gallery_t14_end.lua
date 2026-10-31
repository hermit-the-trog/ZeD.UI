-- ZeDUI/tools/qa/gallery_t14_end.lua  (Oct 30 2026)
-- Last in the gallery manifest: puts back what gallery_t14_look.lua changed. The desk's menu function, vanilla's
-- watermark render, the left-edge column, the theme options as they were (applied and saved), and clears GAL_LOOK,
-- GAL_STILL, GAL_SHAPE and GAL_T14. Safe to run twice. grep "ZEDQA g14e".
local function say(s) print("ZEDQA g14e " .. tostring(s)) end
local G = GAL_T14 or {}
local MM = ZeD and ZeD.MainMenu
if MM and G.menus then MM.menus = G.menus end
if WaterMarkUI and G.wm then WaterMarkUI.render = G.wm end
local col = ISEquippedItem and ISEquippedItem.instance
if col and G.colWas then col:setVisible(true) end
local opts = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("ZeD_UI")
if opts and G.optWas then
    for id, v in pairs(G.optWas) do
        local o = opts:getOption(id)
        if o then pcall(function() o:setValue(v) end) end
    end
    pcall(function() ZeD.Settings.reapplyFromOptions() end)
    pcall(function() PZAPI.ModOptions:save() end)
end
say("put back: menus " .. tostring(G.menus ~= nil) .. ", watermark " .. tostring(G.wm ~= nil) .. ", column " .. tostring(G.colWas)
    .. ", options " .. tostring(G.optWas ~= nil) .. " | look now " .. tostring(ZeD and ZeD.currentBase) .. " " .. tostring(ZeD and ZeD.currentAccent))
GAL_T14, GAL_LOOK, GAL_STILL, GAL_SHAPE = nil, nil, nil, nil
local n = 0
local function later()
    n = n + 1
    if n < 10 then return end
    Events.OnTick.Remove(later)
    Events.OnFETick.Remove(later)
    say("DONE")
end
Events.OnTick.Add(later)
Events.OnFETick.Add(later)
