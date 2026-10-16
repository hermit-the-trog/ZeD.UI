-- ZeDUI/tools/qa/zedqa_mod_workshop.lua  (Oct 16 2026)
-- At the main menu: the Workshop states this machine cannot produce (one real
-- subscription, up to date), fed to the Mods screen as stand-in data: an
-- update waiting, downloading, subscribed but not installed, a collection, and
-- a running mod (ZeDQA_TestB) that Steam updated mid-session, which turns the
-- strip into the restart case. Hot-reloads the two files first. Shoots each;
-- grep "ZEDQA ws". Nothing is sent to Steam.
local D = "C:/Users/danie/Zomboid/mods/ZeD-UI/42/media/lua/client/ZeD/"
reloadLuaFile(D .. "ZeD_ModScan.lua")
reloadLuaFile(D .. "ZeD_MainMenuMods.lua")
local MM = ZeD.MainMenu
local R = MM.root
local MS = ZeD.ModScan
setmetatable(R.modsWin, ZeD_MMMods)
MS.start()
local function say(s) print("ZEDQA ws " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ws_" .. n .. ".png") end) end
local now = getTimestamp()
local function item(id, title, state, agoS, size, children)
    return { id = id, title = title, state = state, updated = now - agoS, size = size, children = children or 0 }
end
local fake = {
    item("2859508566", "Extra Books (B41 + B42) [Loot tables update]", "ok", 86000, 315631),
    item("1111", "Tanks of Kentucky", "update", 7300, 193000000),
    item("2222", "Knox Radio Plus", "downloading", 3000, 12500000),
    item("3333", "Kitchen Core", "missing", 0, 0),
    item("4444", "Rural Kentucky (collection)", "ok", 900000, 0, 12),
    item("5555", "ZeD QA test B", "ok", 600, 48000),
}
local steps, t = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function w() return R.modsWin end
at(2, function()
    MS.ws.fake = true
    MS.ws.items, MS.ws.order = {}, {}
    for _, it in ipairs(fake) do MS.ws.items[it.id] = it; MS.ws.order[#MS.ws.order + 1] = it end
    table.sort(MS.ws.order, function(a, b) return a.title:lower() < b.title:lower() end)
    MS.ws.updatedNow = { ["5555"] = true }
    local orig = MS.wsFor
    MS.wsFor = function(mi) if mi:getId() == "ZeDQA_TestB" then return MS.ws.items["5555"] end return orig(mi) end
    MS.updatedLoaded = function() return { "ZeDQA_TestB" } end
    if MM.view ~= "mods" then MM.act.mods() end
end)
at(40, function() w().filter = "ws"; w().scroll = 0; w().wsSel = "1111"; w().sel = nil; w().dscroll = 0; w()._cnt = nil end)
at(50, function() shot("01_ws_update") end)
at(52, function() w().wsSel = "3333" end)
at(60, function() shot("02_ws_missing") end)
at(62, function() w().filter = "all"; w().sel = "ZeDQA_TestB"; w().dscroll = 0; w()._cnt = nil end)
at(72, function()
    shot("03_restart_strip")
    local s = {}
    for _, b in ipairs(w()._specs) do if b.row == 1000 then s[#s + 1] = b.id .. "=" .. b.text end end
    say("strip " .. table.concat(s, ", ") .. " | ask " .. tostring(w()._ask))
    say("DONE")
end)
local function tick()
    t = t + 1
    for _, s in ipairs(steps) do if s.n == t then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if t > 80 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
