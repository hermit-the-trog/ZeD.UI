-- ZeDUI/tools/qa/hfr_menu.lua  (Nov 20 2026, QA; tag mhfr): MAIN MENU ONLY, pushed through the QA bridge by
-- zedqa_menu_mods_run.ps1 (hotfix_report_run.ps1 -Part menu). The beta 21 hotfix report, CUTS B (git 7441148a3): the
-- main menu pictures, 4K at 1.75x, the pointer hidden, the debug console hidden. Pictures to Screenshots/hfr_B_*.png:
--   B_desk_full, B_desk_lite, B_file_menu_tutorial, B_mods_full, B_mods_lite, B_mods_about, B_mods_options,
--   B_mods_conflicts, B_mods_sandbox, B_load_order, B_welcome, B_upload_public, B_upload_hidden, B_upload_update
-- Nothing is saved or uploaded (the Upload button is never pressed; the form's fields are only read). What it puts back:
-- every ZeD option as found, the look on screen, ModOptions.ini line for line. grep "ZEDQA mhfr".
local MM = ZeD.MainMenu
local St = ZeD.Settings
local function say(s) print("ZEDQA mhfr " .. tostring(s)) end
local pass, fail, tick = 0, 0, 0
local steps = {}
local OFF = 80   -- (the desk's screen fades in at boot: every step after the first waits for it)
local T0 = 0
local function at(n, fn) T0 = T0 + n; steps[#steps + 1] = { n = (T0 > 2) and (T0 + OFF) or T0, fn = fn } end
local keep = {}
local K = {}

function K.opts() local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo end
function K.val(id)
    local zo = K.opts()
    local o = zo and zo.dict and zo.dict[id]
    local v = nil
    pcall(function() v = o:getValue() end)
    return v
end
function K.readIni()
    local t = nil
    pcall(function()
        local r = getFileReader("ModOptions.ini", false)
        if not r then return end
        t = {}
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        r:close()
    end)
    return t
end
function K.writeIni(lines)
    if not lines then return end
    pcall(function()
        local w = getFileWriter("ModOptions.ini", true, false)
        for _, l in ipairs(lines) do w:write(l .. "\r\n") end
        w:close()
    end)
end
function K.style(i)
    local o = St.lookStyleOption
    pcall(function() o:setValue(i) end)
    if o.onChange then pcall(o.onChange, o, i) end
end
function K.shot(name, keepMouse)
    pcall(function() if not keepMouse then Mouse.setXY(4, 4) end; Mouse.setCursorVisible(false) end)
    local ok, e = pcall(function() getCore():TakeFullScreenshot("hfr_" .. name .. ".png") end)
    if ok then pass = pass + 1; say("shot hfr_" .. name) else fail = fail + 1; say("ERR shot " .. name .. ": " .. tostring(e)) end
end
function K.W() return MM.root and MM.root.modsWin end
function K.rows() local w = K.W(); local r = {}; if w then pcall(function() r = w:rows() end) end; return r end
-- the first mod whose tab has something (not greyed) and, for options/sandbox/conflicts, a count; nil when none
function K.modFor(tab)
    local w = K.W()
    if not w then return nil end
    local best = nil
    for _, d in ipairs(K.rows()) do
        local list = {}
        pcall(function() list = w:detailTabs(d) end)
        for _, t in ipairs(list) do
            if t.id == tab and not t.none and (not best or (t.count or 0) > best.n) then best = { d = d, n = t.count or 0 } end
        end
    end
    return best and best.d or nil
end
function K.pickTab(tab, name)
    local w = K.W()
    local d = (tab == "about") and (function() for _, x in ipairs(K.rows()) do if x.modId == "ZeD_UI" then return x end end; return K.rows()[1] end)() or K.modFor(tab)
    if not (w and d) then fail = fail + 1; say("not taken: " .. name .. " (no mod with a " .. tab .. " tab)"); keep.skipTab = true; return end
    keep.skipTab = false
    w.sel = d.modId; w.fsel = nil; w.dtab = tab; w.dscroll = 0
    say(name .. ": " .. tostring(d.name) .. " (" .. tostring(d.modId) .. ")")
end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    keep.opt0 = {}
    local zo = K.opts()
    for _, o in ipairs((zo and zo.data) or {}) do
        if o.type == "combobox" and o.id then keep.opt0[o.id] = o.selected end
    end
    keep.ini0 = K.readIni()
    keep.base, keep.accent, keep.size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    say("as found: Style " .. tostring(K.val("lookStyle")) .. ", view " .. tostring(MM.view) .. ", look " .. tostring(keep.base))
    if MM.view ~= "main" then pcall(MM.showView, "main") end
    K.style(1)
end)
-- Full: the desk, the File menu
at(25, function() K.shot("B_desk_full") end)
at(5, function() MM.ctx.open = "file"; MM.ctx.dropFocus = 1 end)
at(10, function() say("File menu open " .. tostring(MM.ctx.open)); K.shot("B_file_menu_tutorial", true) end)
at(5, function() MM.ctx.open = nil end)
-- the Mods screen, Full
at(10, function() MM.openMods() end)
at(40, function()
    local w = K.W()
    say("Mods screen open " .. tostring(w ~= nil and w:isVisible()) .. ", rows " .. #K.rows())
    K.pickTab("about", "about")
end)
at(15, function() K.shot("B_mods_full") end)
at(5, function() K.pickTab("options", "options") end)
at(15, function() if not keep.skipTab then K.shot("B_mods_options") end end)
at(5, function() K.pickTab("sandbox", "sandbox") end)
at(15, function() if not keep.skipTab then K.shot("B_mods_sandbox") end end)
at(5, function() K.pickTab("conflicts", "conflicts") end)
at(15, function() if not keep.skipTab then K.shot("B_mods_conflicts") end end)
at(5, function() K.pickTab("about", "about"); local w = K.W(); if w then w.dtab = "about" end end)
at(15, function() K.shot("B_mods_about") end)
-- the load order page
at(5, function()
    local w = K.W()
    if w then pcall(function() w:enterOrder("order") end) end
end)
at(25, function() K.shot("B_load_order") end)
at(5, function() local w = K.W(); if w then pcall(function() w:leaveOrder(false) end) end end)
-- the same screen in Lite
at(15, function() K.style(2) end)
at(30, function()
    local w = K.W()
    say("Lite " .. tostring(St.lite()) .. ", Mods screen open " .. tostring(w ~= nil and w:isVisible()))
    if w then w.dtab = "about"; w.sel = "ZeD_UI" end
end)
at(15, function() K.shot("B_mods_lite") end)
at(5, function() local w = K.W(); if w then pcall(function() w:back() end) end end)
at(25, function() say("view " .. tostring(MM.view)); K.shot("B_desk_lite") end)
-- the first-launch window
at(5, function() K.style(1); MM.openWelcome() end)
at(50, function() say("welcome view " .. tostring(MM.view)); K.shot("B_welcome") end)
at(5, function() if MM.view ~= "main" then pcall(MM.showView, "main") end end)
-- the uploader: Public (a new item), Hidden (the Seen line), an update (the item with an id)
at(20, function()
    -- (QA, Nov 20: -nosteam gives the game no staged Workshop items, so the uploader read "No folders"; two stand-in items
    -- with the real fields stand where the game's list is, put back after: a new item without an id, and ZeD with one)
    local function fake(folder, title, id, vis)
        local f = { vis = vis or 0 }
        function f:getFolderName() return folder end
        function f:getTitle() return title end
        function f:getID() return id end
        function f:getVisibilityInteger() return self.vis end
        function f:setVisibilityInteger(v) self.vis = v end
        function f:getTags() return { size = function() return 0 end, get = function() return nil end } end
        function f:getDescription() return "A short description for the picture." end
        function f:getSubmitDescription() return "A short description for the picture." end
        function f:getChangeNote() return "" end
        function f:getPreviewImage() return "" end
        function f:getContentFolder() return "Workshop/" .. folder .. "/Contents" end
        function f:setTitle(v) end
        function f:setDescription(v) end
        function f:setChangeNote(v) end
        function f:setTags(v) end
        function f:setVisible(v) end
        function f:validateContents() return false end
        function f:getExtendedErrorInfo() return "" end
        return f
    end
    keep.realList = getSteamWorkshopStagedItems
    local stand = { fake("Mod Template", "Mod Template", nil, 0), fake("ZeD-GUI", "ZeD-GUI [BETA]", "3824968485", 0) }
    getSteamWorkshopStagedItems = function() return { size = function() return #stand end, get = function(_, i) return stand[i + 1] end } end
    MM.showView("workshop")
end)
at(30, function()
    local w = MM.root and MM.root.workshopWin
    if not w then fail = fail + 1; say("ERR no uploader window"); return end
    for i, it in ipairs(w.items or {}) do say("ws item " .. i .. " " .. tostring(it:getTitle())) end
    local function find(title) for i, it in ipairs(w.items or {}) do if tostring(it:getTitle()) == title then return i end end end
    keep.iNew = find("Mod Template")
    keep.iUpd = find("ZeD-GUI [BETA]")
    if keep.iNew then w:pick(keep.iNew); w.vis = 0; w.fscroll = 0 end
end)
at(25, function() K.shot("B_upload_public") end)
at(5, function() local w = MM.root.workshopWin; if w and keep.iNew then w.vis = 2; w.fscroll = 0 end end)
at(20, function() K.shot("B_upload_hidden") end)
at(5, function() local w = MM.root.workshopWin; if w and keep.iUpd then w:pick(keep.iUpd); w.fscroll = 0 else fail = fail + 1; say("not taken: B_upload_update (no item with an id)") end end)
at(25, function() if keep.iUpd then K.shot("B_upload_update") end end)
at(5, function()
    local w = MM.root.workshopWin
    if w then pcall(function() w.dirtyForm = false; w:back() end) end
    if w and w.confirm then pcall(function() w:setConfirm(false) end) end
end)
at(20, function() if MM.view ~= "main" then pcall(MM.showView, "main") end end)
at(2, function() if keep.realList then getSteamWorkshopStagedItems = keep.realList end end)
-- put back: every option as found, the look, ModOptions.ini, the desk
at(15, function()
    local zo = K.opts()
    for id, v in pairs(keep.opt0 or {}) do
        local o = zo and zo.dict and zo.dict[id]
        if o and o.selected ~= v then pcall(function() o:setValue(v) end) end
    end
    pcall(ZeD.Settings.reapplyFromOptions)
    if keep.base and ZeD.applyTheme then pcall(ZeD.applyTheme, keep.base, keep.accent, keep.size) end
    K.writeIni(keep.ini0)
end)
at(10, function()
    local bad = {}
    for id, v in pairs(keep.opt0 or {}) do if K.val(id) ~= v then bad[#bad + 1] = id end end
    say("put back: options " .. ((#bad == 0) and "all as found" or ("NOT " .. table.concat(bad, " "))) .. ", look " .. tostring(ZeD.currentBase) .. ", view " .. tostring(MM.view))
    if #bad > 0 then fail = fail + 1 end
    pcall(function() Mouse.setCursorVisible(true) end)
end)
at(5, function()
    say(string.format("end: %d shots, %d fail; view=%s", pass, fail, tostring(MM.view)))
    say("DONE")
end)

local last = T0
local function t()
    tick = tick + 1
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
