-- ZeDUI/tools/qa/zedqa_mods_hand.lua  (Nov 1 2026)
-- Main menu QA for the Mods screen by hand: the screen driven through its own mouse, key and pad
-- handlers (no real mouse or pad), on the Mods page with two test folders and on the Load order
-- page with two separators (MOD_FOLDERS_SPEC.md 3, 4, 7, 8, 12; MODS_LOAD_ORDER_SPEC 8):
--   1. right-click a folder row, a mod row in a folder, an order row, a separator row and a dimmed
--      (off) row: each opens its menu (MM.ctx.open / MM.popup) with its entries; Escape and B close
--   2. Page Up / Page Down on the Mods page jump folder to folder; on Load order they page the rows,
--      and LB / RB jump separator to separator (on the Mods page LB / RB walk the filter tabs)
--   3. Ctrl+Up / Down (move) moves the picked order row one place; Undo puts it back; a drop
--      (orderMoveTo) the same
--   4. A on a folder row opens / closes it, X is its box, Space too, B asks before leaving; A on a
--      separator opens its menu (A on the menu's first entry collapses / opens it), X / Y move it
--   5. several rows picked (msel): the menu acts on all of them (Move to folder...), the box on the
--      folder they went into; Escape, a plain click and a right-click elsewhere drop the pick
--   6. the arrows (D-pad, Up / Down) move one row at a time and skip none, down and back up
-- Ctrl and Shift are read live (isCtrlKeyDown / isShiftKeyDown) and cannot be faked: Ctrl+Up / Down
-- and Ctrl+Z are called as the handlers they run (w:move, w:orderUndo), and a Ctrl / Shift pick is
-- set as w.msel and w._msAnchor. A drag needs the real mouse: only its drop (orderMoveTo) is run.
-- Works on its own folders file: ZeD.ModFolders.FILE is pointed at Lua/ZeDQA_ModFolders.cfg for
-- the run, never the player's ModFolders.cfg. Puts back: every mod's on / off and the load order
-- (Undo changes and the order as it was), the folders file emptied and its name, the Unfiled state
-- file's text, the profile file's text (the separators go with it); leaves through Discard changes
-- (vanilla's NO), so nothing new is accepted. Needs eight installed mods that are off and four on:
-- run with compat_r4_mods.txt.
--
-- Run (never while the game runs; checks Lua/zedqa.lock itself):
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/compat_r4_mods.txt `
--        -Script ZeDUI/tools/qa/zedqa_mods_hand.lua -Tag mhd -TimeoutSec 300
-- Lines: "ZEDQA mhd PASS ..." / "ZEDQA mhd FAIL ..." / "ZEDQA mhd SKIP ...", then a total and DONE.
local MM = ZeD.MainMenu
local F = ZeD.ModFolders
local O = ZeD.ModOrder
local function say(s) print("ZEDQA mhd " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_mhd_" .. n .. ".png") end) end
local pass, fail = 0, 0
local function check(ok, what)
    if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end
end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function W() return MM.root and MM.root.modsWin end
local function model() return ModSelector.instance.model end
-- (MM.keyRelease / MM.joyDown / MM.joyDir take vanilla's MainScreen, as its overrides pass it:
-- MM.isUp reads its bottomPanel; MM.root has none)
local function ms() return MainScreen.instance end
local function jlist(l) local t = {}; if l then for i = 0, l:size() - 1 do t[#t + 1] = l:get(i) end end; return t end
local function idx(order, id) for i, x in ipairs(order) do if x == id then return i end end; return nil end
local function join(t) return table.concat(t or {}, ";") end
local function slice(t, a, b) local o = {}; for i = a, b do if t[i] ~= nil then o[#o + 1] = t[i] end end; return o end
local K = Keyboard
local JP = Joypad

local TEST = "ZeDQA_ModFolders.cfg"
local UISTATE = "ZeD_modfolders.txt"
local PROFILES = "ZeD_modprofiles.txt"
local keep = {}

local function readRaw(name)
    local r = getFileReader(name, false)
    if not r then return nil end
    local t = {}
    local line = r:readLine()
    while line do t[#t + 1] = line; line = r:readLine() end
    r:close()
    return table.concat(t, "\n") .. "\n"
end
local function writeRaw(name, s)
    local w = getFileWriter(name, true, false)
    if w then w:write(s); w:close() end
end

-- what is on, and the load order, as one text (everything must come back to it)
local function onAndOrder()
    local m = model()
    local on = {}
    for _, d in ipairs(m.sortedMods or {}) do if d.isActive then on[#on + 1] = d.modId end end
    return join(on) .. " / " .. join(jlist(m:getActiveMods():getMods()))
end
local function onSet()
    local on = {}
    for _, d in ipairs(model().sortedMods or {}) do if d.isActive then on[#on + 1] = d.modId end end
    return join(on)
end
local function allOn(ids, want)
    local m = model()
    for _, id in ipairs(ids) do if (m.mods[id] and m.mods[id].isActive or false) ~= want then return false end end
    return true
end

-- the page's mods (in order) under separator uid
local function under(w, uid)
    local t = {}
    for _, id in ipairs(w.order) do if (w.oZone[id] or 2) == 2 and (w.oSec[id] or 0) == uid then t[#t + 1] = id end end
    return t
end

-- the open pop-up menu (MM.openPopup: MM.ctx.open is its key, MM.popup its items)
local function menuItem(text)
    local P = MM.popup
    if not (P and MM.ctx.open and P.key == MM.ctx.open) then return nil end
    for _, it in ipairs(P.items or {}) do if type(it) == "table" and it.text == text then return it end end
    return nil
end
local function menuHead()
    local P = MM.popup
    local it = P and P.items and P.items[1]
    if type(it) ~= "table" then return nil, nil end
    return it.text, it.disabled
end
-- every key's text in the open menu; dis: the keys that must be greyed (true) or live (false)
local function menuHas(keys, dis)
    local bad = {}
    for _, k in ipairs(keys) do
        local it = menuItem(ZeD.tr(k))
        if not it then bad[#bad + 1] = k .. " missing"
        elseif dis and dis[k] ~= nil and (it.disabled == true) ~= dis[k] then bad[#bad + 1] = k .. (dis[k] and " live" or " greyed") end
    end
    if #bad > 0 then say("menu " .. tostring(MM.ctx.open) .. ": " .. join(bad)) end
    return #bad == 0
end
local function menuClosed() return MM.ctx.open == nil end

-- a list entry's point on the screen (scrolled into sight first): the Mods list or the Load order
local function listXY(w, v, sid)
    local k = v.at and v.at[sid]
    local e = k and v.ents[k]
    local L = w._list
    if not (e and L) then return nil end
    if e.y < w.scroll or e.y + e.h > w.scroll + L.h then w.scroll = e.y end
    return w:getAbsoluteX() + L.x + math.floor(L.w / 3), w:getAbsoluteY() + L.y + (e.y - w.scroll) + math.floor(e.h / 2), e
end
local function rightClickAt(w, v, sid)
    local x, y = listXY(w, v, sid)
    if not x then say("no entry " .. tostring(sid)); return false end
    return w:rightClick(x, y) == true
end
local function hasStop(w, id)
    for _, s in ipairs(w._specs or {}) do if s.id == id then return true end end
    return false
end
local function focusFolder(w, fid)
    w.fsel, w.sel, w.msel = fid, nil, nil
    w.focusId = "frow:" .. tostring(fid)
    w._fScrollTo = w.focusId
end

-- the arrows' walk: the stops from one entry down, the focus seen after each press, down and up
local walk = {}
local function walkStart(v, from, n)
    local seq, on = {}, false
    for _, e in ipairs(v.ents) do
        if e.sid == from then on = true end
        if on and e.sid then seq[#seq + 1] = e.sid end
    end
    walk = { seq = seq, n = math.min(n, #seq - 1), down = {}, up = {} }
end
local function walkStep(which, s, press)
    local w = W()
    if not (walk.seq and s <= walk.n) then return end
    press(w)
    local t = walk[which]
    t[#t + 1] = w.focusId or "nil"
end
local function walkCheck(tag, page)
    local okD, okU = walk.n >= 3, walk.n >= 3
    local wantU = {}
    for s = 1, walk.n do
        if walk.down[s] ~= walk.seq[s + 1] then okD = false end
        wantU[s] = walk.seq[walk.n + 1 - s]
        if walk.up[s] ~= wantU[s] then okU = false end
    end
    if not okD then say("down: want " .. join(slice(walk.seq, 2, walk.n + 1)) .. " got " .. join(walk.down)) end
    if not okU then say("up: want " .. join(wantU) .. " got " .. join(walk.up)) end
    check(okD, tag .. "a " .. page .. ": down " .. walk.n .. " times, one row each, none skipped")
    check(okU, tag .. "b " .. page .. ": back up the same rows to where it began")
end
local function walkSteps(t0, n, down, up)
    for s = 1, n do at(t0 + 2 * s, function() walkStep("down", s, down) end) end
    for s = 1, n do at(t0 + 2 * n + 2 * s, function() walkStep("up", s, up) end) end
end

-- ============================================================================
-- SET-UP: the test folders file, the Mods page, two folders
-- ============================================================================
at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    keep.file = F.FILE
    keep.ui = readRaw(UISTATE)
    keep.prof = readRaw(PROFILES)
    F.FILE = TEST
    writeRaw(TEST, "")
    MM.ctx.open = nil
    MM.openMods()
end)

at(15, function()
    local w = W()
    local m = model()
    if w.find:isFocused() then w.find:unfocus() end
    keep.state0 = onAndOrder()
    keep.order0 = jlist(m:getActiveMods():getMods())
    local picks = {}
    for _, d in ipairs(m.sortedMods or {}) do
        if #picks < 8 and d.isAvailable and not d.isActive and not w:problemNow(d) and d.modId ~= "ModTemplate" and d.modId ~= "ZeD_UI" then picks[#picks + 1] = d.modId end
    end
    if #picks < 8 then say("SKIP Mods page parts (fewer than eight installed mods that are off and can run)"); return end
    keep.picks = picks
    local okA, a = F.create("QA Hand A")
    local okB, b = F.create("QA Hand B")
    F.assign({ picks[1], picks[2], picks[3] }, a)
    F.assign({ picks[4], picks[5] }, b)
    F.setUnfiledOpen(true)
    keep.fa, keep.fb = a, b
    w.filter = "all"
    w.find:setText("")
    w.scroll = 0
    focusFolder(w, a)
    w:dirty()
    check(okA and okB and F.folderOf(picks[1]) == a and F.folderOf(picks[4]) == b, "0 two test folders made in the test file, mods moved in")
end)
at(20, function() shot("00_folders") end)

-- ============================================================================
-- MODS PAGE 1: clicks and right-clicks
-- ============================================================================
-- a click picks a folder; a second one at once opens or closes it
at(24, function()
    local w = W()
    if not keep.fa then return end
    local a = keep.fa
    local v = w:folderView()
    local e = v.ents[v.at["frow:" .. a]]
    w._lastFClick, w.fsel = nil, nil
    w:clickFolder(e)
    check(w.fsel == a and w.focusId == "frow:" .. a and w.sel == nil, "1a a click on a folder row picks it (its pane, the focus)")
    w:clickFolder(e)
    check(F.byId(a).open == false, "1b a second click at once closes it")
    v = w:folderView()
    e = v.ents[v.at["frow:" .. a]]
    w:clickFolder(e)
    w:clickFolder(e)
    check(F.byId(a).open == true, "1c and opens it again")
end)

-- right-click a folder row: its menu
at(28, function()
    local w = W()
    if not keep.fa then return end
    local a = keep.fa
    local ok = rightClickAt(w, w:folderView(), "frow:" .. a)
    local head, hdis = menuHead()
    check(ok and MM.ctx.open == "folderRow" and w.fsel == a and w.focusId == "frow:" .. a, "1d right-click a folder row: its menu opens, the folder picked")
    check(head == F.byId(a).name and hdis == true, "1e the menu's heading is the folder's name (greyed)")
    check(menuHas({ "UI_ZeD_Folders_MenuRename", "UI_ZeD_Folders_MenuDelete", "UI_ServerSettings_ButtonMoveUp", "UI_ServerSettings_ButtonMoveDown",
                    "UI_ZeD_Folders_MenuOpenAll", "UI_ZeD_Folders_MenuCloseAll", "UI_ZeD_Folders_BtnNew" },
                  { UI_ServerSettings_ButtonMoveUp = true, UI_ServerSettings_ButtonMoveDown = false }),
          "1f Rename..., Delete folder, Move up (greyed: the first), Move down, Open all, Close all, New folder...")
end)
at(31, function() shot("01_folder_menu") end)
at(33, function()
    local w = W()
    if not keep.fa then return end
    local r = MM.keyRelease(ms(), K.KEY_ESCAPE)
    check(r == true and menuClosed() and MM.view == "mods" and w.page == "list", "1g Escape closes the menu (the screen stays)")
end)

-- right-click a mod row in a folder: Move to folder
at(35, function()
    local w = W()
    if not keep.fa then return end
    local p = keep.picks
    local ok = rightClickAt(w, w:folderView(), "mrow:" .. p[2])
    check(ok and MM.ctx.open == "modFolder" and w.sel == p[2] and w.fsel == nil, "1h right-click a mod row in a folder: Move to folder opens, the mod picked")
    local head = menuHead()
    local fa, fb = menuItem(F.byId(keep.fa).name), menuItem(F.byId(keep.fb).name)
    check(head == ZeD.tr("UI_ZeD_Folders_MenuMoveHead") and fa and fa.disabled == true and fb and not fb.disabled,
          "1i its folders listed: its own greyed, the other live")
    check(menuHas({ "UI_ZeD_Folders_BtnNew", "UI_ZeD_Folders_MenuTakeOut" }), "1j New folder... and Take out of the folder")
    MM.joyDown(ms(), JP.BButton)
    check(menuClosed() and not w.confirm and MM.view == "mods", "1k B closes the menu (and nothing else)")
    -- Unfiled's own menu: no Rename / Delete
    local v = w:folderView()
    w:folderMenu(v.ents[v.at["frow:unfiled"]], nil)
    check(MM.ctx.open == "folderRow" and not menuItem(ZeD.tr("UI_ZeD_Folders_MenuRename")) and menuHas({ "UI_ZeD_Folders_MenuOpenAll", "UI_ZeD_Folders_BtnNew" }),
          "1l Unfiled's menu: Open all, Close all, New folder... (no Rename, no Delete)")
    MM.keyRelease(ms(), K.KEY_ESCAPE)
end)

-- ============================================================================
-- MODS PAGE 2: Page Up / Page Down folder to folder; LB / RB walk the tabs
-- ============================================================================
at(42, function()
    local w = W()
    if not keep.fa then return end
    local a, b, p = keep.fa, keep.fb, keep.picks
    focusFolder(w, a)
    MM.keyRelease(ms(), K.KEY_NEXT)
    check(w.focusId == "frow:" .. b and w.fsel == b, "2a Page Down: from folder A's row to folder B's (A's mods passed)")
    MM.keyRelease(ms(), K.KEY_NEXT)
    check(w.focusId == "frow:unfiled" and w.fsel == "unfiled", "2b Page Down: to Unfiled")
    MM.keyRelease(ms(), K.KEY_NEXT)
    check(w.focusId == "frow:unfiled", "2c Page Down at the last heading stays")
    MM.keyRelease(ms(), K.KEY_PRIOR)
    check(w.focusId == "frow:" .. b and w.fsel == b, "2d Page Up: back to folder B")
    w.fsel, w.sel, w.focusId = nil, p[2], "mrow:" .. p[2]
    MM.keyRelease(ms(), K.KEY_PRIOR)
    check(w.focusId == "frow:" .. a and w.fsel == a and w.sel == nil, "2e Page Up from a mod in A: A's own heading")
    w.fsel, w.sel, w.focusId = nil, p[2], "mrow:" .. p[2]
    w:folderJump(1)
    check(w.focusId == "frow:" .. b, "2f folderJump(1) from a mod in A: B's heading")
end)
-- (on the Mods page LB / RB walk the filter tabs, ZeD_MMMods:joyBumper; folder to folder is Page Up / Down)
at(44, function()
    local w = W()
    if not keep.fa then return end
    w.filter = "all"
    local order = w._tabOrder or {}
    MM.joyDown(ms(), JP.RBumper)
    check(w.filter == order[2] and w.filter ~= "all", "2g RB: the next filter tab (" .. tostring(w.filter) .. ")")
    MM.joyDown(ms(), JP.LBumper)
    check(w.filter == "all", "2h LB: back to All")
    w.filter, w.scroll = "all", 0
    w:dirty()
    focusFolder(w, keep.fa)
end)

-- ============================================================================
-- MODS PAGE 4: A, X, B, Space on a folder row
-- ============================================================================
local function pressOnFolder(button, what)
    local w = W()
    if not keep.fa then return false end
    if not hasStop(w, w.focusId) then check(false, what .. " (no stop for " .. tostring(w.focusId) .. ")"); return false end
    MM.joyDown(ms(), button)
    return true
end
at(52, function()
    local w = W()
    if not pressOnFolder(JP.AButton, "4a A on folder A") then return end
    local a = keep.fa
    local v = w:folderView()
    check(F.byId(a).open == false and (readRaw(TEST) or ""):find("folder=" .. a .. "|0|", 1, true) ~= nil and v.at["mrow:" .. keep.picks[1]] == nil,
          "4a A on a folder row closes it (saved |0|, its rows gone)")
end)
at(56, function()
    if not pressOnFolder(JP.AButton, "4b A again") then return end
    check(F.byId(keep.fa).open == true, "4b A again opens it")
end)
at(60, function()
    local w = W()
    if not pressOnFolder(JP.XButton, "4c X on folder A") then return end
    local p = keep.picks
    say("band: " .. tostring(w.note and w.note.text))
    check(allOn({ p[1], p[2], p[3] }, true) and w.focusId == "frow:" .. keep.fa, "4c X on a folder row is its box: its mods on, the focus stays")
end)
at(63, function()
    local w = W()
    if not keep.fa then return end
    MM.joyDown(ms(), JP.BButton)
    check(w.confirm == "back" and MM.view == "mods", "4d B with changes waiting asks first (the screen stays)")
end)
at(66, function()
    local w = W()
    if not keep.fa then return end
    MM.joyDown(ms(), JP.BButton)
    check(not w.confirm and MM.view == "mods" and w.page == "list", "4e B again answers the question: no, the screen stays")
    say("NOTE after the question the focus is " .. tostring(w.focusId) .. " (back() keeps no _backFocus)")
end)
at(69, function()
    local w = W()
    if not keep.fa then return end
    local p = keep.picks
    focusFolder(w, keep.fa)
    MM.keyRelease(ms(), K.KEY_SPACE)
    check(allOn({ p[1], p[2], p[3] }, false), "4f Space on a folder row, all on: the box turns them all off")
    w:revert()
    check(onAndOrder() == keep.state0, "4g Undo changes: on / off and the order as they were")
end)

-- ============================================================================
-- MODS PAGE 6: the arrows, one row at a time (the D-pad down, the Up key back)
-- ============================================================================
at(74, function()
    local w = W()
    if not keep.fa then return end
    w.scroll = 0
    focusFolder(w, keep.fa)
end)
at(78, function()
    local w = W()
    if not keep.fa then return end
    walkStart(w:folderView(), "frow:" .. keep.fa, 10)
    say("Mods walk from " .. tostring(walk.seq[1]) .. ", " .. walk.n .. " steps")
end)
walkSteps(78, 10, function(w) w:joyDir("down") end, function(w) MM.keyRelease(ms(), K.KEY_UP) end)
at(123, function() if keep.fa then walkCheck("6", "Mods page") end end)

-- ============================================================================
-- MODS PAGE 5: several rows picked (Ctrl / Shift-click's result)
-- ============================================================================
at(126, function()
    local w = W()
    if not keep.fa then return end
    local p = keep.picks
    w.msel = { [p[6]] = true, [p[7]] = true, [p[8]] = true }
    w._msAnchor, w.sel, w.fsel, w.focusId = p[6], p[6], nil, "mrow:" .. p[6]
    check(w:getStatusLine() == ZeD.tr("UI_ZeD_Folders_StatusPicked", 3), "5a three picked: the help line says so")
    local ok = rightClickAt(w, w:folderView(), "mrow:" .. p[7])
    local head = menuHead()
    local n = 0
    for _ in pairs(w.msel or {}) do n = n + 1 end
    check(ok and MM.ctx.open == "modFolder" and n == 3 and head == ZeD.tr("UI_ZeD_Folders_MenuMoveHeadMany", 3),
          "5b right-click one of them: the menu is for all three, the pick kept")
end)
at(129, function() shot("02_move_many") end)
at(131, function()
    local w = W()
    if not keep.fa then return end
    local p, b = keep.picks, keep.fb
    local live, k = MM.dropLive(), nil
    for i, it in ipairs(live) do if it.text == F.byId(b).name then k = i end end
    if k then MM.ctx.dropFocus = k; MM.joyDown(ms(), JP.AButton) end
    check(k ~= nil and menuClosed() and F.folderOf(p[6]) == b and F.folderOf(p[7]) == b and F.folderOf(p[8]) == b and w.msel == nil,
          "5c A on folder B in the menu: all three move into B, the pick drops")
    w:folderBox(b)
    check(allOn({ p[4], p[5], p[6], p[7], p[8] }, true), "5d B's box: every mod in it on, the three moved in with them")
end)
at(134, function()
    local w = W()
    if not keep.fa then return end
    local p = keep.picks
    local m = model()
    w.msel, w.focusId = { [p[6]] = true, [p[7]] = true }, "mrow:" .. p[6]
    local r = MM.keyRelease(ms(), K.KEY_ESCAPE)
    check(r == true and w.msel == nil and MM.view == "mods" and w.page == "list", "5e Escape drops the pick first (the screen stays)")
    w.msel = { [p[6]] = true, [p[7]] = true }
    rightClickAt(w, w:folderView(), "mrow:" .. p[4])
    check(MM.ctx.open == "modFolder" and w.msel == nil and menuHead() == ZeD.tr("UI_ZeD_Folders_MenuMoveHead"), "5f right-click a row not picked: the pick drops, the menu is that row's")
    MM.keyRelease(ms(), K.KEY_ESCAPE)
    w.msel, w.sel, w._lastClick = { [p[6]] = true, [p[7]] = true }, p[6], nil
    local was = m.mods[p[8]].isActive
    w:clickRow(m.mods[p[8]])
    check(w.msel == nil and w.sel == p[8] and w.focusId == "mrow:" .. p[8] and m.mods[p[8]].isActive == was, "5g a plain click picks one row and drops the pick (no on / off)")
    w:revert()
    check(onAndOrder() == keep.state0, "5h Undo changes: on / off and the order as they were")
end)

-- ============================================================================
-- LOAD ORDER: two separators (as zedqa_mods_separators.lua makes them)
-- ============================================================================
at(140, function()
    local w = W()
    MM.ctx.open = nil
    w.msel = nil
    walk = {}
    w:enterOrder("order")
    keep.on0p = onSet()
    local mids = {}
    for i, id in ipairs(w.order) do if w.oZone[id] == 2 and id ~= "ZeD_UI" and id ~= O.helperId() then mids[#mids + 1] = i end end
    if #mids < 4 then say("SKIP Load order parts (fewer than 4 movable mods on: run with compat_r4_mods.txt)"); return end
    -- (any separators the list had go for the run; they come back with the profile file at the end)
    w.oLo.seps, w.oLo.top = {}, {}
    w:orderChanged()
    w.oSel = mids[2]
    w:sepNew("QA Alpha")
    keep.alpha = w.oSepSel
    w.oSepSel = nil
    w.oSel = mids[math.floor(#mids / 2) + 2] or mids[#mids]
    w:sepNew("QA Beta")
    keep.beta = w.oSepSel
    w.oUndo = {}
    keep.ord0p = join(w.order)
    -- a mod with the next place in its own section, neither of them the fixed helper, for the moves
    local a, b = under(w, keep.alpha), under(w, keep.beta)
    say("Alpha: " .. join(a) .. " | Beta: " .. join(b))
    local H = O.helperId()
    for i = 1, #w.order - 1 do
        local x, y = w.order[i], w.order[i + 1]
        if not keep.mx and x ~= H and y ~= H and x ~= "ZeD_UI" and (w.oZone[x] or 2) == 2 and (w.oZone[y] or 2) == 2
            and (w.oSec[x] or 0) ~= 0 and w.oSec[x] == w.oSec[y] then
            keep.mx = x
            local s = under(w, w.oSec[x])
            keep.mlast = s[#s]
        end
    end
    if not keep.mx then say("SKIP Load order parts (no two movable mods side by side under one separator)"); keep.beta = nil end
    w:orderSelectAt(1, false)
end)

-- 1: right-click an order row, a separator, a dimmed row
at(145, function()
    local w = W()
    if not keep.beta then return end
    local x = keep.mx
    local i = idx(w.order, x)
    local ok = rightClickAt(w, w:orderView(), "orow:" .. i)
    check(ok and MM.ctx.open == "orderRow" and w.oSel == i and w.oSepSel == nil, "1m right-click an order row: its menu opens, the row picked")
    check(menuHead() == O.nameOf(model(), w.oInfo, x), "1n the menu's heading is the mod's name")
    check(menuHas({ "UI_ZeD_Order_LoadAfter", "UI_ZeD_Order_LoadBefore", "UI_ZeD_Order_MoveTop", "UI_ZeD_Order_MoveBottom", "UI_ZeD_Seps_MenuMoveTo", "UI_ZeD_Seps_BtnNew" }),
          "1o Load after..., Load before..., Move to top / bottom, Move to separator..., New separator...")
end)
at(148, function() shot("03_order_menu") end)
at(150, function()
    local w = W()
    if not keep.beta then return end
    MM.keyRelease(ms(), K.KEY_ESCAPE)
    check(menuClosed() and w.page == "order", "1p Escape closes it (the page stays)")
    local ok = rightClickAt(w, w:orderView(), "osep:" .. keep.beta)
    check(ok and MM.ctx.open == "sepRow" and w.oSepSel == keep.beta and w.focusId == "osep:" .. keep.beta, "1q right-click a separator: its menu opens, the separator picked")
    local keys = { "UI_ZeD_Seps_MenuCollapse", "UI_ZeD_Seps_BtnTurnOff", "UI_ZeD_Seps_MenuRename", "UI_ZeD_Seps_MenuDelete",
                   "UI_ServerSettings_ButtonMoveUp", "UI_ServerSettings_ButtonMoveDown", "UI_ZeD_Seps_BtnNew" }
    if F.any() then keys[#keys + 1] = "UI_ZeD_Seps_BtnReplace" end
    check(menuHead() == "QA Beta" and menuHas(keys, { UI_ServerSettings_ButtonMoveUp = false, UI_ServerSettings_ButtonMoveDown = true }),
          "1r Collapse, Turn off, Rename..., Delete, Move up, Move down (greyed: the last), New separator..., from folders")
end)
at(153, function() shot("04_sep_menu") end)
at(155, function()
    local w = W()
    if not keep.beta then return end
    MM.joyDown(ms(), JP.BButton)
    check(menuClosed() and w.page == "order", "1s B closes the menu (the page stays)")
    w:sepMenu(keep.alpha, nil)
    check(MM.ctx.open == "sepRow" and menuHas({ "UI_ServerSettings_ButtonMoveUp", "UI_ServerSettings_ButtonMoveDown" }, { UI_ServerSettings_ButtonMoveUp = true, UI_ServerSettings_ButtonMoveDown = false }),
          "1t the first separator's menu: Move up greyed, Move down live")
    MM.keyRelease(ms(), K.KEY_ESCAPE)
    local v = w:orderView()
    local e = v.ents[v.at["osep:" .. keep.alpha]]
    w._sClick = nil
    w:clickSep(e)
    check(w.oSepSel == keep.alpha and w.focusId == e.sid, "1u a click on a separator picks it")
    local i = idx(w.order, under(w, keep.alpha)[1])
    w._oClick = nil
    w:clickOrderRow(i)
    check(w.oSel == i and w.oSepSel == nil and w.focusId == "orow:" .. i, "1v a click on an order row picks it (the separator dropped)")
end)
-- a dimmed row: Beta off
at(158, function()
    local w = W()
    if not keep.beta then return end
    w:sepBox(keep.beta)
end)
at(162, function()
    local w = W()
    if not keep.beta then return end
    local v = w:orderView()
    local e = nil
    for _, x in ipairs(v.ents) do if not e and x.k == "held" and x.uid == keep.beta then e = x end end
    if not e then say("SKIP 1w to 1y (Beta off shows no dimmed row)"); return end
    keep.heldId = e.id
    w:clickHeld(e)
    check(w.oHeldSel == e.id and w.oSepSel == nil and w.focusId == e.sid, "1w a click on a dimmed row picks it")
    local ok = rightClickAt(w, v, e.sid)
    check(ok and MM.ctx.open == "sepHeld" and w.oHeldSel == e.id, "1x right-click a dimmed row: its menu opens")
    check(menuHead() == O.nameOf(model(), w._infoAll, e.id) and menuHas({ "UI_ZeD_Seps_BtnTurnOn" }), "1y its heading is the mod's name; Turn on")
end)
at(165, function() shot("05_held_menu") end)
at(167, function()
    local w = W()
    if not keep.beta then return end
    MM.keyRelease(ms(), K.KEY_ESCAPE)
    if keep.heldId then
        w:heldMenu(keep.heldId, nil)
        check(MM.ctx.open == "sepHeld", "1z heldMenu opens from the keyboard / pad too")
        MM.keyRelease(ms(), K.KEY_ESCAPE)
    end
    say("1zz before Undo: undo depth " .. tostring(w.oUndo and #w.oUndo) .. ", Beta on " .. tostring(w:sepGet(keep.beta).on))
    w:orderUndo()
    if not (w:sepGet(keep.beta).on == true and onSet() == keep.on0p and join(w.order) == keep.ord0p) then
        say("1zz detail: Beta on " .. tostring(w:sepGet(keep.beta).on) .. "; on same " .. tostring(onSet() == keep.on0p)
            .. "; order now [" .. join(w.order) .. "] before [" .. tostring(keep.ord0p) .. "]; on now [" .. tostring(onSet()) .. "] before [" .. tostring(keep.on0p) .. "]")
    end
    check(w:sepGet(keep.beta).on == true and onSet() == keep.on0p and join(w.order) == keep.ord0p, "1zz Undo: Beta on again, its mods on, in their places")
end)

-- 2: Page Up / Down a page of rows; LB / RB separator to separator
at(172, function()
    local w = W()
    if not keep.beta then return end
    w:orderSelectAt(1, false)
    MM.keyRelease(ms(), K.KEY_NEXT)
    local s1 = w.oSel
    check(s1 > 1 and w.focusId == "orow:" .. s1, "2i Page Down on Load order: a page of rows down (" .. tostring(s1) .. ")")
    MM.keyRelease(ms(), K.KEY_PRIOR)
    check(w.oSel == 1 and w.focusId == "orow:1", "2j Page Up: back to the first row")
    -- the separators in the list's order after row 1
    local v = w:orderView()
    local seps = {}
    for k = (v.at["orow:1"] or 0) + 1, #v.ents do if v.ents[k].k == "sep" then seps[#seps + 1] = v.ents[k].uid end end
    if #seps < 2 then say("SKIP 2k to 2o (fewer than two separators below row 1)"); return end
    MM.joyDown(ms(), JP.RBumper)
    check(w.focusId == "osep:" .. seps[1] and w.oSepSel == seps[1], "2k RB: the next separator's heading")
    MM.joyDown(ms(), JP.RBumper)
    check(w.focusId == "osep:" .. seps[2] and w.oSepSel == seps[2], "2l RB again: the one after")
    MM.joyDown(ms(), JP.RBumper)
    check(w.focusId == "osep:" .. seps[2], "2m RB at the last separator stays")
    MM.joyDown(ms(), JP.LBumper)
    check(w.focusId == "osep:" .. seps[1] and w.oSepSel == seps[1], "2n LB: the one before")
    w:sepJump(1)
    check(w.focusId == "osep:" .. seps[2], "2o sepJump(1) (Ctrl+Page Down's handler): the next")
end)

-- 4: A and X / Y on a separator; A and B on an order row
at(176, function()
    local w = W()
    if not keep.beta then return end
    w:sepSelect(keep.alpha)
    MM.joyDown(ms(), JP.AButton)
    local first = MM.dropLive()[1]
    check(MM.ctx.open == "sepRow" and first and first.text == ZeD.tr("UI_ZeD_Seps_MenuCollapse"), "4h A on a separator: its menu, Collapse first")
    MM.joyDown(ms(), JP.AButton)
    check(menuClosed() and w:sepGet(keep.alpha).open == false, "4i A on Collapse: the separator collapses")
end)
at(179, function()
    local w = W()
    if not keep.beta then return end
    MM.joyDown(ms(), JP.AButton)
    local first = MM.dropLive()[1]
    check(MM.ctx.open == "sepRow" and first and first.text == ZeD.tr("UI_ZeD_Seps_MenuExpand"), "4j A again: the menu offers Expand first")
    MM.joyDown(ms(), JP.AButton)
    check(menuClosed() and w:sepGet(keep.alpha).open == true, "4k A on Expand: open again")
end)
at(182, function()
    local w = W()
    if not keep.beta then return end
    local before = join(w.order)
    w:sepSelect(keep.alpha)
    MM.joyDown(ms(), JP.XButton)
    check(w.oLo.seps[2] and w.oLo.seps[2].uid == keep.alpha, "4l X on a separator: Move down (past Beta, its mods with it)")
    MM.joyDown(ms(), JP.YButton)
    check(w.oLo.seps[1].uid == keep.alpha and join(w.order) == before, "4m Y: Move up, the order as it was")
end)
at(185, function()
    local w = W()
    if not keep.beta then return end
    local i = idx(w.order, keep.mx)
    w:orderSelectAt(i, false)
    MM.joyDown(ms(), JP.AButton)
    check(MM.ctx.open == "orderRow" and w.oSel == i, "4n A on an order row: its menu")
    MM.joyDown(ms(), JP.BButton)
    check(menuClosed() and w.page == "order", "4o B closes it (the page stays)")
end)

-- 3: Ctrl+Up / Down (move), X on a row, a drop (orderMoveTo); Undo after each
at(188, function()
    local w = W()
    if not keep.beta then return end
    local x = keep.mx
    local i = idx(w.order, x)
    local sx = w.oSec[x]
    local before = join(w.order)
    w:orderSelectAt(i, false)
    w:move(1)
    check(w.order[i + 1] == x and w.oSel == i + 1 and w.focusId == "orow:" .. (i + 1) and w.oSec[x] == sx, "3a Ctrl+Down (move 1): one place down, the focus with it, same separator")
    w:move(-1)
    check(w.order[i] == x and w.oSel == i, "3b Ctrl+Up (move -1): back up")
    w:move(1)
    w:orderUndo()
    check(join(w.order) == before and w.oSel == i, "3c Undo (Ctrl+Z's handler) puts it back, the pick too")
    w:orderSelectAt(i, false)
    MM.joyDown(ms(), JP.XButton)
    local okX = w.order[i + 1] == x
    w:orderUndo()
    check(okX and join(w.order) == before, "3d X on an order row moves it down; Undo puts it back")
    local j = idx(w.order, keep.mlast)
    w:orderMoveTo(i, j)
    local okD = w.order[j] == x
    w:orderUndo()
    check(okD and join(w.order) == before, "3e a drop (orderMoveTo) moves it to the row it lands on; Undo puts it back")
    w:orderSelectAt(i, false)
    MM.keyRelease(ms(), K.KEY_DOWN)
    check(join(w.order) == before and w.focusId ~= "orow:" .. i, "3f Down without Ctrl moves the focus, never the mod")
end)

-- 6: the arrows on Load order (the D-pad down through the separators, the Up key back)
at(192, function()
    local w = W()
    if not keep.beta then return end
    w.scroll = 0
    w:orderSelectAt(1, false)
end)
at(196, function()
    local w = W()
    if not keep.beta then return end
    walkStart(w:orderView(), "orow:1", 8)
    say("Load order walk from " .. tostring(walk.seq[1]) .. ", " .. walk.n .. " steps: " .. join(slice(walk.seq, 1, walk.n + 1)))
end)
walkSteps(196, 8, function(w) MM.joyDir(ms(), "down") end, function(w) MM.keyRelease(ms(), K.KEY_UP) end)
at(233, function() if keep.beta then walkCheck("6", "Load order") end end)

-- B on Load order: back to the Mods page, nothing kept
at(236, function()
    local w = W()
    if w.page ~= "order" then return end
    MM.ctx.open = nil
    w:orderSelectAt(1, false)
    MM.joyDown(ms(), JP.BButton)
    check(w.page == "list" and MM.view == "mods" and onSet() == keep.on0p, "4p B on Load order: back to the Mods page, on / off as they were")
end)

-- ============================================================================
-- PUT EVERYTHING BACK
-- ============================================================================
at(240, function()
    local w = W()
    local m = model()
    MM.ctx.open = nil
    w.msel = nil
    if w.page == "order" or w.page == "maps" then w:leaveOrder(false) end
    w:revert()
    if keep.order0 then m:correctAndSaveModOrder(keep.order0) end
    if keep.state0 then check(onAndOrder() == keep.state0, "Z every mod's on / off and the load order exactly as before") end
    writeRaw(PROFILES, keep.prof or "")
    O.load()
    F.FILE = keep.file or "ModFolders.cfg"
    writeRaw(TEST, "")
    if keep.ui then writeRaw(UISTATE, keep.ui) else writeRaw(UISTATE, "unfiledOpen=1\n") end
    F.load()
    w:discard()
end)
at(270, function()
    say(string.format("view=%s; %d passed, %d failed", tostring(MM.view), pass, fail))
    say("DONE")
end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then fail = fail + 1; say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 290 then Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
say("start")
