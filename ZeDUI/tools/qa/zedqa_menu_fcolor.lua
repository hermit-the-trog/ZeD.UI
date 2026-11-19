-- ZeDUI/tools/qa/zedqa_menu_fcolor.lua  (Nov 19 2026, QA; tag mfc): MAIN MENU ONLY. Build's question after the report
-- picture folders_26 showed no Color... menu: does a folder's Color... pull-down really show on screen? One folder made
-- (the runner puts ModFolders.cfg and ZeD_folder_colors.txt back byte for byte), the Mods screen opened, then:
--   1. the folder row's menu (folderMenu, "folderRow")              the drop panel shown, on screen, above the Mods window
--   2. its Color... row picked as a click picks it (MM.pointer: ctx.open nil, then the row's fn)  "folderColor" shown
--   3. the folder pane's Color... button (the "fcolor" verb's fn)  "folderColor" shown
-- For each: ctx.open, the drop panel's visibility, box and place in the UI manager against the Mods window's, the
-- items' count, and a picture (Screenshots/mfc_row.png, mfc_color_row.png, mfc_color_pane.png). grep "ZEDQA mfc".
local MM = ZeD.MainMenu
local function say(s) print("ZEDQA mfc " .. tostring(s)) end
local pass, fail, tick = 0, 0, 0
local steps = {}
local function at(n, fn) steps[#steps + 1] = { n = n + 80, fn = fn } end   -- (the desk fades in at boot)
local function check(ok, what, detail)
    if ok then pass = pass + 1 else fail = fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (detail and (" | " .. tostring(detail)) or ""))
end
local S = {}
local function W() return MM.root and MM.root.modsWin end
local function uiIndex(panel)
    local idx = nil
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            local t = nil
            pcall(function() t = e:getTable() end)
            if e == panel.javaObject or t == panel then idx = i end
        end
    end)
    return idx
end
-- the drop panel's state, and where the Mods window sits (its own root, or the desk root that holds it)
local function state(label)
    local d = MM.root and MM.root.drop
    local vis, box = false, "none"
    pcall(function()
        vis = d:isVisible()
        box = string.format("%d,%d %dx%d", d:getAbsoluteX(), d:getAbsoluteY(), d:getWidth(), d:getHeight())
    end)
    local items = select(1, MM.openItems())
    local hits = d and d._hits and #d._hits or 0
    local di, wi, ri = d and uiIndex(d), W() and uiIndex(W()), MM.root and uiIndex(MM.root)
    say(string.format("%s: ctx.open %s, drop shown %s at %s, items %s, rows drawn %d, UI index drop %s / mods window %s / desk root %s",
        label, tostring(MM.ctx.open), tostring(vis), box, tostring(items and #items), hits, tostring(di), tostring(wi), tostring(ri)))
    return vis, hits
end
local function shot(n)
    pcall(function() Mouse.setCursorVisible(false) end)
    pcall(function() getCore():TakeFullScreenshot(n .. ".png") end)
    say("shot " .. n)
end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    pcall(function() Mouse.setXY(6, 6) end)
    MM.ctx.open = nil
    MM.openMods()
end)
at(20, function()
    local F, w = ZeD.ModFolders, W()
    if not (F and w) then check(false, "the Mods screen and ZeD.ModFolders are there"); return end
    local ids = {}
    pcall(function() ids = w:visibleModIds() end)
    local ok, fid = F.create("Survival")
    if ok then F.assign({ ids[1], ids[2] }, fid); ZeD_MMMods.setFolderColor(fid, "blue") end
    S.fid = ok and fid or nil
    check(S.fid ~= nil, "a folder made for the check", tostring(fid))
end)
-- 1. the folder row's menu
at(30, function()
    local w = W()
    if not (w and S.fid) then return end
    for _, e in ipairs(w:folderView().ents) do if e.f and e.fkey == S.fid then S.e = e end end
    if not S.e then check(false, "the folder's row is in the list"); return end
    w:folderMenu(S.e)
end)
at(36, function()
    local vis, hits = state("row menu")
    check(MM.ctx.open == "folderRow" and vis and hits > 0, "the folder row's menu shows (drop shown, rows drawn)")
    shot("mfc_row")
end)
-- 2. its Color... row picked as a click picks it
at(40, function()
    local items = select(1, MM.openItems()) or {}
    local color = nil
    for _, it in ipairs(items) do if type(it) == "table" and it.text == ZeD.tr("UI_ZeD_Folders_MenuColor") then color = it end end
    if not color then check(false, "the row menu has Color..."); return end
    MM.ctx.open = nil
    color.fn()
end)
at(46, function()
    local vis, hits = state("Color... from the row menu")
    check(MM.ctx.open == "folderColor" and vis and hits > 0, "Color... from the row menu shows its colors (drop shown, rows drawn)")
    shot("mfc_color_row")
end)
-- 3. the folder pane's Color... button
at(50, function()
    MM.ctx.open = nil
end)
at(54, function()
    local w = W()
    if not (w and S.fid) then return end
    pcall(function() w:folderColorMenu(S.fid) end)
end)
at(60, function()
    local vis, hits = state("Color... from the pane")
    check(MM.ctx.open == "folderColor" and vis and hits > 0, "Color... from the folder pane shows its colors (drop shown, rows drawn)")
    shot("mfc_color_pane")
end)
at(64, function()
    MM.ctx.open = nil
    local w = W()
    if w then pcall(function() w:back() end) end
    pcall(function() Mouse.setCursorVisible(true) end)
end)
at(70, function()
    say(string.format("end: %d pass, %d fail; view=%s", pass, fail, tostring(MM.view)))
    say(fail > 0 and ("VERDICT FAIL " .. fail) or ("VERDICT PASS " .. pass))
    say("DONE")
end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do
        if s.n == tick then
            local ok, e = pcall(s.fn)
            if not ok then fail = fail + 1; say("ERR " .. s.n .. " " .. tostring(e)) end
        end
    end
    if tick > 200 then Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
say("start")
