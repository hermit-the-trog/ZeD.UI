-- ZeDUI/tools/qa/zedqa_b8_seven_menus.lua  (Nov 7 2026, QA; tag b8menu): the seven supported mods loaded TOGETHER, the menus half
-- (CHECK_mods-menus_20261107.md and CHECK_mods_hud_20261107.md part 4). zedqa_b8_seven_hud.lua is the belt half.
--   1. Better Item Transfer: ZeD's "Context menu" option set to the LIST and a right-click on an item AT ONCE is the list
--      (the first right-click after the switch, saved or not); set back to the strip, the next right-click is the strip.
--      The mod's primed flag is set; the menu holds the mod's entries (counted and listed). Pictures of both styles.
--   2. Clear Skill Sheet: the mod's rate for Fitness (x1 with no boost: tag "XP x1"), a boosted skill's tag, the card lines
--      ("XP gain: x..."), the extra is registered on ZeD's Skills tab; the Skills tab pictured.
--   3. Better Folders: a folder made through the mod's own call, listed even while empty (ZeD's group keys), an axe filed into
--      it by type (group key and label), the item menu holds "Virtual folders", a rename, "remove from folder", delete. All
--      folders it made are deleted at the end. The Character window's inventory pictured with the folder.
--   4. Better Mod Experience: ZeD's support answered, the mod's sorting table is there and its preview of the CURRENT mod list
--      (the seven) holds nothing back. (Options > Mods folds, the Load/Continue/New Game notes and the Mods screen are main-menu
--      screens: by hand.)
--   5. Step aside stayed out again after all of it: no "ZeD screens" notice, no switch ticked.
--   PUT BACK: the context menu style, the folders, the items, the windows.
-- grep "ZEDQA b8menu"; shots zqa_b8menu_*.png.
local function say(s) print("ZEDQA b8menu " .. tostring(s)) end
local p = getPlayer()
local fails = 0
local function check(ok, what)
    if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8menu_" .. n .. ".png") end) end
local CW = ZeD_CharacterWindow
if not (p and CW and ZeD.Settings and ZeD.Settings.contextStyleOption) then say("ERR ZeD's windows or settings are not loaded"); say("DONE"); return end

local Q, qi, waitT, tries = {}, 1, nil, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end

local inv = p:getInventory()
local added = {}
local function give(ft)
    local ok, it = pcall(function() return inv:AddItem(ft) end)
    if ok and it then added[#added + 1] = it; return it end
    say("note: " .. ft .. " could not be added")
    return nil
end
local function modTable(id) return ZeD.ModSupport and ZeD.ModSupport[id] end
local function keepDown(w)
    if not w then return end
    w._autoShaded = false
    if w.windowShaded and w.setWindowShaded then w:setWindowShaded(false) end
    w._outSince = getTimestampMs() + 600000
end
local function menuNames()
    local v = getPlayerContextMenu(0)
    local t = {}
    for _, o in ipairs(v and v.options or {}) do t[#t + 1] = tostring(o.name) end
    return t, v
end
local function hideMenu()
    local v = getPlayerContextMenu(0)
    if v then pcall(function() v:hideAndChildren() end) end
end
local function styleOf()
    local v = getPlayerContextMenu(0)
    local z = v and v._zedMenu
    local t = z and tostring(z.Type) or ""
    return z, (t == "ZeD_ContextList" or (t ~= "ZeD_ContextMenu" and z and z._levels ~= nil)) and "list" or "strip"
end

local opt = ZeD.Settings.contextStyleOption
local styleWas = opt:getValue()
local windowsWere = CW.isOpen()
local apple, axe

-- 1. Better Item Transfer: the style switch counts from the very next right-click
step(5, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not CW.isOpen() then CW.toggleBothPaired(0) end
    apple = give("Base.Apple")
    local S = modTable("BetterItemTransfer")
    check(S ~= nil and S.primed == true, "Better Item Transfer's options were read at the game's start (primed " .. tostring(S and S.primed) .. ")")
    local O = BetterItemTransferOptions
    if type(O) == "table" and type(O.get) == "function" then
        local ok, v = pcall(O.get, "showIcons")
        say("the mod's showIcons option reads " .. tostring(v) .. " (ok " .. tostring(ok) .. ")")
    end
    opt:setValue(1)
end)
step(30, function() ISInventoryPaneContextMenu.createMenu(0, true, { apple }, 700, 300) end)
step(40, function()
    local names, v = menuNames()
    local z, kind = styleOf()
    say("style strip: " .. kind .. ", " .. #names .. " entries: " .. table.concat(names, ", "))
    check(z ~= nil and kind == "strip", "the strip style: the right-click opens the icon strip (" .. kind .. ")")
    check(#names >= 3, "with the mod's entries in it (" .. #names .. ")")
    shot("bit_strip")
    hideMenu()
end)
-- the switch, NOT saved: the very next right-click is the list
step(20, function() opt:setValue(2) end)
step(10, function() ISInventoryPaneContextMenu.createMenu(0, true, { apple }, 700, 300) end)
step(40, function()
    local names = menuNames()
    local z, kind = styleOf()
    say("style list: " .. kind .. ", " .. #names .. " entries: " .. table.concat(names, ", "))
    check(z ~= nil and kind == "list", "the list style on the FIRST right-click after the switch (" .. kind .. ")")
    check(#names >= 3, "and the mod's entries are all in it (" .. #names .. ")")
    shot("bit_list")
    hideMenu()
end)
step(20, function() opt:setValue(1) end)
step(10, function() ISInventoryPaneContextMenu.createMenu(0, true, { apple }, 700, 300) end)
step(40, function()
    local z, kind = styleOf()
    check(z ~= nil and kind == "strip", "switched back: the next right-click is the strip (" .. kind .. ")")
    hideMenu()
    opt:setValue(styleWas)
end)

-- 2. Clear Skill Sheet
step(10, function()
    local S = modTable("Clear_SkillSheet")
    check(S ~= nil and S.X ~= nil, "Clear Skill Sheet's support answered")
    if not S then return end
    local fit = PerkFactory.getPerk(Perks.Fitness)
    local axeP = PerkFactory.getPerk(Perks.Axe)
    local g = S.gain(p, fit)
    check(g == 1, "Fitness learns at x1 with no boost (" .. tostring(g) .. ")")
    local t = S.X.tag(p, fit, { boost = 0, level = 5 })
    check(t ~= nil and tostring(t.text):find("x1", 1, true) ~= nil, "Fitness's tag reads 'XP x1' (" .. tostring(t and t.text) .. ")")
    local ga = S.gain(p, axeP)
    say("Axe learns at x" .. tostring(ga) .. " (the character's own traits)")
    local ta = S.X.tag(p, axeP, { boost = 2, level = 3 })
    check(ta ~= nil and ta.text ~= nil, "a boosted skill has a tag ('" .. tostring(ta and ta.text) .. "')")
    local lines = S.X.cardLines(p, axeP, { level = 3 })
    check(lines ~= nil and #lines >= 1 and tostring(lines[1].text):find("x", 1, true) ~= nil, "the card holds the 'XP gain' line (" .. tostring(lines and lines[1] and lines[1].text) .. ")")
    local maxed = S.X.cardLines(p, axeP, { level = 10 })
    check(maxed ~= nil and #maxed == 0, "a maxed skill has no XP gain line (" .. tostring(maxed and #maxed) .. ")")
    local registered = false
    for _, e in ipairs(ZeD.SkillsTab and ZeD.SkillsTab.extras or {}) do
        if e.id == "Clear_SkillSheet" then registered = true end
    end
    check(registered, "the extra is registered on ZeD's Skills tab")
    -- every skill the character has boosted, as the tab would tag it
    local rows = {}
    local list = PerkFactory.PerkList
    for i = 0, (list and list:size() or 0) - 1 do
        local pk = list:get(i)
        local okb, boost = pcall(function() return p:getXp():getPerkBoost(pk:getType()) end)
        if okb and boost and boost > 0 then
            local tg = S.X.tag(p, pk, { boost = boost, level = p:getPerkLevel(pk:getType()) })
            rows[#rows + 1] = tostring(pk:getName()) .. " boost " .. boost .. " -> " .. tostring(tg and tg.text)
        end
    end
    say("boosted skills: " .. (#rows > 0 and table.concat(rows, "; ") or "none"))
    keepDown(CW.getWindow())
    CW.openTab(0, "skills")
end)
step(60, function() keepDown(CW.getWindow()); shot("skills_tab") end)

-- 3. Better Folders
local VIF, folderId, folderKey
step(10, function()
    VIF = modTable("VIF_DualRender_B42")
    check(VIF ~= nil and VIF.state(p) ~= nil, "Better Folders: the mod's state for the character is there")
    if not (VIF and VIFState) then return end
    axe = give("Base.Axe")
    folderId = VIF.change(p, VIFState.createFolder, "b8 Tools")
    check(folderId ~= nil, "a folder made through the mod's call (" .. tostring(folderId) .. ")")
    local keys = VIF.G.keys(inv, p, true) or {}
    for _, k in ipairs(keys) do
        if VIF.G.label(k) == "b8 Tools" then folderKey = k end
    end
    check(folderKey ~= nil, "the empty folder is listed in ZeD's groups (" .. #keys .. " folders)")
    check(folderKey ~= nil and VIF.G.rank(folderKey) ~= nil, "and has a place in the order (rank " .. tostring(folderKey and VIF.G.rank(folderKey)) .. ")")
end)
step(20, function()
    if not (VIF and folderId and axe) then return end
    VIF.change(p, VIFState.setTypeRule, "Base.Axe", folderId)
    check(VIF.folderOf(p, axe) == folderId, "the axe is filed in the folder by type")
    check(VIF.G.group(axe, inv, p, true) == folderKey, "ZeD's group key for the axe is the folder's (" .. tostring(VIF.G.group(axe, inv, p, true)) .. ")")
    ISInventoryPaneContextMenu.createMenu(0, true, { axe }, 700, 300)
end)
step(40, function()
    local names = menuNames()
    say("the axe's menu: " .. table.concat(names, " | "))
    local vf = getText("UI_VIF_VirtualFolders")
    local found = false
    for _, n in ipairs(names) do if n == vf then found = true end end
    check(found, "the item menu has '" .. tostring(vf) .. "'")
    shot("folders_menu")
    hideMenu()
    keepDown(CW.getWindow())
    CW.openTab(0, "loot")
end)
step(60, function() keepDown(CW.getWindow()); shot("folders_inventory") end)
step(10, function()
    if not (VIF and folderId) then return end
    VIF.change(p, VIFState.renameFolder, folderId, "b8 Kit")
    check(folderKey ~= nil and VIF.G.label(folderKey) == "b8 Kit", "the rename shows at once (" .. tostring(folderKey and VIF.G.label(folderKey)) .. ")")
    VIF.change(p, VIFState.setTypeRule, "Base.Axe", nil)
    check(VIF.folderOf(p, axe) == nil, "'remove from folder' puts the axe back under its category")
    local keys = VIF.G.keys(inv, p, true) or {}
    local still = false
    for _, k in ipairs(keys) do if k == folderKey then still = true end end
    check(still, "and the empty folder stays as an empty group row")
    VIF.delete(p, folderId)
    keys = VIF.G.keys(inv, p, true) or {}
    still = false
    for _, k in ipairs(keys) do if k == folderKey then still = true end end
    check(not still, "delete takes the folder away; nothing left the inventory (axe still carried: " .. tostring(inv:contains(axe)) .. ")")
end)

-- 4. Better Mod Experience
step(10, function()
    local S = modTable("BetterModExperience")
    check(S ~= nil, "Better Mod Experience's support answered")
    if not S then return end
    local B = S.sorting()
    check(B ~= nil, "the mod's sorting table (BetterModExperience.Sorting.preview) is there")
    say("the mod's name as the game lists it: " .. tostring(S.modName()))
    if B then
        local ids = {}
        local list = getActivatedMods()
        for i = 0, list:size() - 1 do ids[#ids + 1] = (tostring(list:get(i)):gsub("^\\", "")) end
        local errs = S.errors("b8menu", ids, true)
        check(errs == nil, "the mod's preview of the current list (" .. #ids .. " mods) holds nothing back" .. (errs and (": " .. tostring(errs[1])) or ""))
    end
    say("(manual: Options > Mods folds, Load / Continue / New Game / Host notes and the Mods screen are main-menu screens)")
end)

-- 5. step aside stayed out, and the put back
step(10, function()
    local MS = ZeD.Messages
    local src = MS and MS.sources[ZeD.tr("UI_ZeD_StepAside_Head")]
    check(src == nil or #src.items == 0, "still no 'ZeD screens' notice after all of it")
    local ticked = {}
    for name, o in pairs(ZeD.Settings.screenOptions or {}) do
        if o:getValue() == 2 then ticked[#ticked + 1] = name end
    end
    check(#ticked == 0, "and no ZeD screen switch ticked (" .. table.concat(ticked, ",") .. ")")
    hideMenu()
    opt:setValue(styleWas)
    for _, it in ipairs(added) do pcall(function() inv:Remove(it) end) end
    if not windowsWere and CW.isOpen() then CW.toggleBothPaired(0) end
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

-- a step's n is in 60ths of a second (wall clock; OnRenderTick runs while paused)
local function tick()
    local s = Q[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    waitT = waitT or (now + s.n * 1000 / 60)
    if now < waitT then return end
    waitT = nil
    local ok, res = pcall(s.fn)
    if not ok then fails = fails + 1; say("ERR step " .. qi .. ": " .. tostring(res)) end
    qi = qi + 1
end
Events.OnRenderTick.Add(tick)
say("start")
