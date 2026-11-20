-- ZeDUI/tools/qa/hfr_disk.lua  (Nov 20 2026, QA; tag mdsk): MAIN MENU ONLY, pushed through the QA bridge by
-- zedqa_menu_mods_run.ps1 (hotfix_report_run.ps1 -Part disk -OutName disk_icons_report). The disk icons and the
-- "ZeD-GUI" names (Build, ZeDUI/tools/modicon): the Mods screen at 4K, the pointer hidden, the debug console hidden.
-- It logs every ZeD row's name and icon, checks the three names, and takes Screenshots/hfr_disk_*.png:
--   disk_dark_zed, disk_dark_picks, disk_light_zed (Multi-Slot is checked by name only: no installed copy)
-- Nothing is saved. What it puts back: the look on screen (Dark), the desk view. grep "ZEDQA mdsk".
local MM = ZeD.MainMenu
local function say(s) print("ZEDQA mdsk " .. tostring(s)) end
local pass, fail, tick = 0, 0, 0
local steps = {}
local OFF = 80   -- (the desk's screen fades in at boot: every step after the first waits for it)
local T0 = 0
local function at(n, fn) T0 = T0 + n; steps[#steps + 1] = { n = (T0 > 2) and (T0 + OFF) or T0, fn = fn } end
local keep = {}
local K = {}
local WANT = { ZeD_UI = "ZeD-GUI [BETA]", ZeDMultiSlot = "ZeD-GUI: Multi-Slot [BETA]", ZeD_Picks = "ZeD-GUI: Picks" }

function K.shot(name)
    pcall(function() Mouse.setXY(4, 4); Mouse.setCursorVisible(false) end)
    local ok, e = pcall(function() getCore():TakeFullScreenshot("hfr_" .. name .. ".png") end)
    if ok then pass = pass + 1; say("shot hfr_" .. name) else fail = fail + 1; say("ERR shot " .. name .. ": " .. tostring(e)) end
end
-- the desk painting's lightning (ZeD_MainMenu.lua life.zap) is held off while pictures are taken: a strike lights
-- the glass and the menu behind the Mods window shows through (director, Nov 20 2026). Let go at the end.
function K.holdZap()
    local z = MM._life and MM._life.zap
    if not z then return end
    if keep.zapAt == nil then keep.zapAt = z.nextAt or 0 end
    z.t0 = nil; z.nextAt = 1e15
end
function K.freeZap()
    local z = MM._life and MM._life.zap
    if z and keep.zapAt ~= nil then z.nextAt = keep.zapAt end
    keep.zapAt = nil
end
function K.W() return MM.root and MM.root.modsWin end
function K.rows() local w = K.W(); local r = {}; if w then pcall(function() r = w:rows() end) end; return r end
function K.pick(id)
    local w = K.W()
    if not w then fail = fail + 1; say("ERR no Mods screen"); return end
    w.sel = id; w.fsel = nil; w.dtab = "about"; w.dscroll = 0
end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    keep.base, keep.accent, keep.size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    say("as found: look " .. tostring(keep.base) .. ", view " .. tostring(MM.view))
    pcall(ZeD.applyTheme, "dark", keep.accent, keep.size)
    if MM.view ~= "main" then pcall(MM.showView, "main") end
end)
at(10, function() MM.openMods() end)
at(40, function()
    local seen = {}
    for _, d in ipairs(K.rows()) do
        local icon = nil
        pcall(function() local mi = getModInfoByID(d.modId); icon = mi and mi:getIcon() end)
        if WANT[d.modId] or tostring(d.name):find("ZeD") then say("row " .. tostring(d.modId) .. ": " .. tostring(d.name) .. " | icon " .. tostring(icon)) end
        if WANT[d.modId] then seen[d.modId] = d.name end
    end
    for id, want in pairs(WANT) do
        if seen[id] == want then pass = pass + 1; say("PASS name " .. id .. " = " .. want)
        else fail = fail + 1; say("FAIL name " .. id .. ": want " .. want .. ", got " .. tostring(seen[id])) end
    end
    K.pick("ZeD_UI")
end)
at(15, function() K.shot("disk_dark_zed") end)
at(5, function() K.pick("ZeD_Picks") end)
at(15, function() K.shot("disk_dark_picks") end)
at(5, function() pcall(ZeD.applyTheme, "light", keep.accent, keep.size); K.pick("ZeD_UI") end)
at(25, function() say("look " .. tostring(ZeD.currentBase)); K.shot("disk_light_zed") end)
-- put back: the look, the desk
at(5, function()
    if keep.base then pcall(ZeD.applyTheme, keep.base, keep.accent, keep.size) end
    K.freeZap(); keep.free = true
    local w = K.W(); if w then pcall(function() w:back() end) end
end)
at(20, function()
    if MM.view ~= "main" then pcall(MM.showView, "main") end
    say("put back: look " .. tostring(ZeD.currentBase) .. ", view " .. tostring(MM.view))
    if ZeD.currentBase ~= keep.base then fail = fail + 1 end
    pcall(function() Mouse.setCursorVisible(true) end)
end)
at(5, function()
    say(string.format("end: %d pass, %d fail; view=%s", pass, fail, tostring(MM.view)))
    say("DONE")
end)

local last = T0
local function t()
    tick = tick + 1
    if not keep.free then pcall(K.holdZap) end
    for _, s in ipairs(steps) do
        if s.n == tick then
            local ok, e = pcall(s.fn)
            if not ok then fail = fail + 1; say("ERR " .. s.n .. " " .. tostring(e)) end
        end
    end
    if tick > last + 20 + OFF then Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
say("start")
