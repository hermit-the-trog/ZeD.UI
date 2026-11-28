-- ZeDUI/tools/qa/mu_order.lua  (Nov 27 2026, the menus gamut sweep; tag mu_order): MAIN MENU ONLY, pushed through the QA bridge.
-- The Mods screen's folders, separators, the load order page and the map order page, check by check against
-- ZeDUI/qa/audits/2026-11-27_map_menu_modorder.md (MO1-MO60). No pictures.
--   folders      ModFolders.cfg read and written on a test file (ZeD.ModFolders.FILE points at Lua/ZeDQA_ModFolders.cfg,
--                never the player's): byte for byte, version 1, non-ASCII names, lines ZeD can't read, outside edits,
--                names used and too long, 99 folders, not-installed members, Delete, colors and labels, the moved
--                count, open and close, picked rows; a folder's box and the order it lays out (installed mods turned
--                on, then Undo changes)
--   separators   on the load order page with made-up mods (the page's working copy only; Done and the on/off
--                matching are held off for it): New, duplicates, Delete, moves across, collapse, Find, Move it up,
--                Auto, Start separators from folders, Lite, not-installed members, labels
--   load order   pins, carried mods, ZeD picks, rules, the picker, Find, Undo's 30 steps, a red row's reason; then
--                with the mods in use (and a few installed ones turned on): stored pins, Back, Done, a separator's box,
--                a mod that needs one under it, a mod landing under an off separator, Turn on for a mod that can't run
--   map order    the button, no Undo, Done in memory only, the pane
--   words        every UI_ZeD key the three page files name has an English entry
-- After each part: nothing threw (every call under test is pcalled, and getLuaDebuggerErrorCount is compared).
-- NEVER pressed: Accept with a change, Reload, Quit and restart, anything that reaches Steam, Delete's Yes on a save, the Mods page's Back
-- while the order differs (it would reload Lua), Keep on "Keep the new order?" (it writes the order: Cancel and Discard
-- changes only, MO40; a page left after a move by the script goes through leaveOrder(false), the Discard way); Done
-- only on the mods in use, and the order is put back at once.
--
-- What it puts back itself: ZeD.ModFolders.FILE; the text of Lua/ZeDQA_ModFolders.cfg, Lua/ZeD_modfolders.txt,
-- Lua/ZeD_folder_colors.txt, Lua/ZeD_modfolders_spare.txt, Lua/ZeD_modprofiles.txt and Lua/ZeD_modprofiles_spare.txt
-- (each read at the start, written back when it changed; a file that was not there is left empty, as Lua cannot
-- delete one); the colors and labels it gave folder ids 1 and up (ZeD_MMMods.setFolderColor, F.setLabel); the list's
-- pins, rules and separators in memory (ZeD_ModOrder reloaded from the file); every mod's on and off (Undo changes)
-- and the load order and map order in memory as found; Style (Lite) as found; every ZeD option as found. It leaves
-- the Mods screen through Back with nothing waiting (vanilla's Accept of the same list), or by the menu bar's way
-- when that Back would reload Lua (a change still waiting is undone first: leaving with one now asks Back's question). Files the game may rewrite then: mods/default.txt, Lua/pz_modlist_settings.cfg.
--
-- Run (never while the game runs; the runner checks Lua/zedqa.lock itself; any mod list: the live checks turn on
-- installed mods that are off and can run, and skip what the machine lacks):
--   pwsh ZeDUI/tools/qa/zedqa_menu_mods_run.ps1 -ModList ZeDUI/tools/qa/compat_r4_mods.txt `
--        -Script ZeDUI/tools/qa/mu_order.lua -Tag mu_order -TimeoutSec 540
--   with $env:ZEDQA_NOSTEAM = "1" set first: a Steam launch loads the Workshop copy of ZeD, which has no QA bridge.
-- Lines: "ZEDQA mu_order PASS MOn: ..." / "FAIL ..." / "SKIP ..." / "NOTE ..." / "ERR ...", then "end: ...",
-- "VERDICT PASS n" or "VERDICT FAIL n", then DONE (from a later frame than the bridge's run line). grep "ZEDQA mu_order".
local TAG = "mu_order"
local MM = ZeD and ZeD.MainMenu
local St = ZeD and ZeD.Settings
local O = ZeD and ZeD.ModOrder
local F = ZeD and ZeD.ModFolders
local S = { pass = 0, fail = 0, skips = 0, stages = {}, si = 1, maxMs = 400000, start = getTimestampMs() }
local keep = { col = {} }
local K = {}
local X = {}
local TESTF = "ZeDQA_ModFolders.cfg"
local FILES = { TESTF, "ZeD_modfolders.txt", "ZeD_folder_colors.txt", "ZeD_modfolders_spare.txt", "ZeD_modprofiles.txt", "ZeD_modprofiles_spare.txt" }
-- every UI_ZeD key ZeD_MainMenuModsFolders.lua, ZeD_MainMenuModsSeps.lua and ZeD_MainMenuModsOrder.lua name (as read
-- Nov 27 2026), with the folder pane's built ones (DetSub, DetSubUnfiled, DetBoxAll, DetBoxNone, each with One)
local KEYS = table.concat({
    "UI_ZeD_Folders_AskDeleteEmpty UI_ZeD_Folders_AskDeleteMany UI_ZeD_Folders_AskDeleteOne UI_ZeD_Folders_AskNew UI_ZeD_Folders_AskRename UI_ZeD_Folders_BoxEmpty ",
    "UI_ZeD_Folders_BoxOff UI_ZeD_Folders_BoxOffOne UI_ZeD_Folders_BoxOn UI_ZeD_Folders_BoxOnOne UI_ZeD_Folders_BtnMake UI_ZeD_Folders_BtnNew ",
    "UI_ZeD_Folders_ColorNone UI_ZeD_Folders_CountAllOn UI_ZeD_Folders_CountNone UI_ZeD_Folders_CountOf UI_ZeD_Folders_CountOn UI_ZeD_Folders_DetBox ",
    "UI_ZeD_Folders_DetBoxAll UI_ZeD_Folders_DetBoxAllOne UI_ZeD_Folders_DetBoxEmpty UI_ZeD_Folders_DetBoxNone UI_ZeD_Folders_DetBoxNoneOne UI_ZeD_Folders_DetBoxSome ",
    "UI_ZeD_Folders_DetEmpty UI_ZeD_Folders_DetIn UI_ZeD_Folders_DetKeptNote UI_ZeD_Folders_DetNeverOrder UI_ZeD_Folders_DetNotInstalled UI_ZeD_Folders_DetSub ",
    "UI_ZeD_Folders_DetSubOne UI_ZeD_Folders_DetSubUnfiled UI_ZeD_Folders_DetSubUnfiledOne UI_ZeD_Folders_DetUnfiledNote UI_ZeD_Folders_HelpDelete UI_ZeD_Folders_HelpFull ",
    "UI_ZeD_Folders_HelpNew UI_ZeD_Folders_HelpRow UI_ZeD_Folders_HelpUnfiled UI_ZeD_Folders_LineCollectionText UI_ZeD_Folders_LineOrder UI_ZeD_Folders_LineOrderText ",
    "UI_ZeD_Folders_MenuCloseAll UI_ZeD_Folders_MenuColor UI_ZeD_Folders_MenuDelete UI_ZeD_Folders_MenuMoveHead UI_ZeD_Folders_MenuMoveHeadMany UI_ZeD_Folders_MenuOpenAll ",
    "UI_ZeD_Folders_MenuRename UI_ZeD_Folders_MenuTakeOut UI_ZeD_Folders_NameUsed UI_ZeD_Folders_PromptBox UI_ZeD_Folders_PromptOpenClose UI_ZeD_Folders_SayAlsoOff ",
    "UI_ZeD_Folders_SayCameAlong UI_ZeD_Folders_SayCannot UI_ZeD_Folders_SayDeleted UI_ZeD_Folders_SayDropped UI_ZeD_Folders_SayFindOpen UI_ZeD_Folders_SayGone ",
    "UI_ZeD_Folders_SayKeptOn UI_ZeD_Folders_SayMade UI_ZeD_Folders_SayMovedMany UI_ZeD_Folders_SayMovedOne UI_ZeD_Folders_SayNoWrite UI_ZeD_Folders_SayNone ",
    "UI_ZeD_Folders_SayOffMany UI_ZeD_Folders_SayOffOne UI_ZeD_Folders_SayOnMany UI_ZeD_Folders_SayOnOne UI_ZeD_Folders_SayOutMany UI_ZeD_Folders_SayOutOne ",
    "UI_ZeD_Folders_SayRenamed UI_ZeD_Folders_StatusBad UI_ZeD_Folders_StatusBadOne UI_ZeD_Folders_StatusPicked UI_ZeD_Folders_Unfiled UI_ZeD_Folders_VerbTakeOut ",
    "UI_ZeD_Folders_VerbTurnAllOff UI_ZeD_Folders_VerbTurnAllOn UI_ZeD_Mods_BtnAuto UI_ZeD_Mods_BtnProfiles UI_ZeD_Mods_EmptyFavs UI_ZeD_Mods_EmptyNone ",
    "UI_ZeD_Mods_EmptyProblems UI_ZeD_Mods_HelpLabel UI_ZeD_Mods_Label UI_ZeD_Mods_MapRule UI_ZeD_Mods_MapShares UI_ZeD_Mods_PromptFilter ",
    "UI_ZeD_Mods_RuleFix UI_ZeD_Mods_SayMapsSet UI_ZeD_Mods_SayOrderSet UI_ZeD_Options_Find UI_ZeD_Order_BtnLoadAfter UI_ZeD_Order_BtnLoadBefore ",
    "UI_ZeD_Order_BtnRemove UI_ZeD_Order_BtnShowFull UI_ZeD_Order_BtnUndo UI_ZeD_Order_Clear UI_ZeD_Order_DetCarriedFirst UI_ZeD_Order_DetCarriedLast ",
    "UI_ZeD_Order_DetCarriedLow UI_ZeD_Order_DetHelper UI_ZeD_Order_DetKept UI_ZeD_Order_DetKeptText UI_ZeD_Order_DetLoadsAt UI_ZeD_Order_DetNeedsCarried ",
    "UI_ZeD_Order_DetNeedsKept UI_ZeD_Order_DetNeedsLater UI_ZeD_Order_DetNeedsOff UI_ZeD_Order_DetOwnNone UI_ZeD_Order_DetOwnRules UI_ZeD_Order_DetPinNotKept ",
    "UI_ZeD_Order_DetPinnedFirst UI_ZeD_Order_DetPinnedFirstLow UI_ZeD_Order_DetPinnedFirstText UI_ZeD_Order_DetPinnedLast UI_ZeD_Order_DetPinnedLastLow UI_ZeD_Order_DetPinnedLastText ",
    "UI_ZeD_Order_DetRuleAfterKept UI_ZeD_Order_DetRuleAfterMissing UI_ZeD_Order_DetRuleAfterNot UI_ZeD_Order_DetRuleAfterOff UI_ZeD_Order_DetRuleBeforeKept UI_ZeD_Order_DetRuleBeforeMissing ",
    "UI_ZeD_Order_DetRuleBeforeNot UI_ZeD_Order_DetRuleBeforeOff UI_ZeD_Order_DetWishAfterKept UI_ZeD_Order_DetWishAfterNot UI_ZeD_Order_DetWishAfterPin UI_ZeD_Order_DetWishAfterRule ",
    "UI_ZeD_Order_DetWishBeforeKept UI_ZeD_Order_DetWishBeforeNot UI_ZeD_Order_DetWishBeforePin UI_ZeD_Order_DetWishBeforeRule UI_ZeD_Order_DetYourRules UI_ZeD_Order_FindCount ",
    "UI_ZeD_Order_GapMore UI_ZeD_Order_HeadCarried UI_ZeD_Order_HeadFirst UI_ZeD_Order_HeadLast UI_ZeD_Order_HeadOf UI_ZeD_Order_HeadPicks ",
    "UI_ZeD_Order_HeadPinned UI_ZeD_Order_HelpAuto UI_ZeD_Order_HelpCarried UI_ZeD_Order_HelpClear UI_ZeD_Order_HelpFind UI_ZeD_Order_HelpLoadAfter ",
    "UI_ZeD_Order_HelpLoadBefore UI_ZeD_Order_HelpLoadFirst UI_ZeD_Order_HelpLoadLast UI_ZeD_Order_HelpMapRow UI_ZeD_Order_HelpMatch UI_ZeD_Order_HelpRemove ",
    "UI_ZeD_Order_HelpRow UI_ZeD_Order_HelpShowFull UI_ZeD_Order_HelpUndo UI_ZeD_Order_HelpUnpin UI_ZeD_Order_HintNeedsAt UI_ZeD_Order_HintNeedsOff ",
    "UI_ZeD_Order_LoadAfter UI_ZeD_Order_LoadBefore UI_ZeD_Order_LoadFirst UI_ZeD_Order_LoadLast UI_ZeD_Order_MoveBottom UI_ZeD_Order_MoveDown ",
    "UI_ZeD_Order_MoveTop UI_ZeD_Order_MoveUp UI_ZeD_Order_NoMatch UI_ZeD_Order_PickBandAfter UI_ZeD_Order_PickBandBefore UI_ZeD_Order_PickExplainAfter ",
    "UI_ZeD_Order_PickExplainBefore UI_ZeD_Order_PickNoneAfter UI_ZeD_Order_PickNoneBefore UI_ZeD_Order_PickTitleAfter UI_ZeD_Order_PickTitleBefore UI_ZeD_Order_PromptMenu ",
    "UI_ZeD_Order_PromptPage UI_ZeD_Order_PromptPick UI_ZeD_Order_PromptShow UI_ZeD_Order_RedHidden UI_ZeD_Order_RedMany UI_ZeD_Order_RedOne ",
    "UI_ZeD_Order_RemoveRules UI_ZeD_Order_SayBlockEdge UI_ZeD_Order_SayCarriedStays UI_ZeD_Order_SayHelperFixed UI_ZeD_Order_SayPinnedFirst UI_ZeD_Order_SayPinnedLast ",
    "UI_ZeD_Order_SayRuleAfter UI_ZeD_Order_SayRuleBefore UI_ZeD_Order_SayRuleGoneAfter UI_ZeD_Order_SayRuleGoneBefore UI_ZeD_Order_SayRuleRemoved UI_ZeD_Order_SayRulesRemoved ",
    "UI_ZeD_Order_SayUndone UI_ZeD_Order_SayUnpinnedFirst UI_ZeD_Order_SayUnpinnedLast UI_ZeD_Order_ShortCircle UI_ZeD_Order_ShortLast UI_ZeD_Order_ShortNeeded ",
    "UI_ZeD_Order_ShortNeedsIt UI_ZeD_Order_ShortPinned UI_ZeD_Order_TagCarried UI_ZeD_Order_TagFirst UI_ZeD_Order_TagKeptByZeD UI_ZeD_Order_TagLast ",
    "UI_ZeD_Order_TagRule UI_ZeD_Order_Unpin UI_ZeD_Order_WhyBlockFirst UI_ZeD_Order_WhyBlockLast UI_ZeD_Order_WhyCircleAfter UI_ZeD_Order_WhyCircleBefore ",
    "UI_ZeD_Order_WhyItNeeds UI_ZeD_Order_WhyNeedsIt UI_ZeD_Seps_AskNameUsed UI_ZeD_Seps_AskNew UI_ZeD_Seps_AskRename UI_ZeD_Seps_AskReplaceMany ",
    "UI_ZeD_Seps_AskReplaceOne UI_ZeD_Seps_BtnFromFolders UI_ZeD_Seps_BtnMake UI_ZeD_Seps_BtnMoveItUp UI_ZeD_Seps_BtnNew UI_ZeD_Seps_BtnReplace ",
    "UI_ZeD_Seps_BtnReplaceGo UI_ZeD_Seps_BtnTurnOff UI_ZeD_Seps_BtnTurnOn UI_ZeD_Seps_CountHidden UI_ZeD_Seps_CountOff UI_ZeD_Seps_DetBox ",
    "UI_ZeD_Seps_DetBoxOff UI_ZeD_Seps_DetBoxOffOne UI_ZeD_Seps_DetBoxOn UI_ZeD_Seps_DetEmpty UI_ZeD_Seps_DetHeldSub UI_ZeD_Seps_DetHeldSubTop ",
    "UI_ZeD_Seps_DetHeldText UI_ZeD_Seps_DetKept UI_ZeD_Seps_DetMissing UI_ZeD_Seps_DetOffMod UI_ZeD_Seps_DetSubOff UI_ZeD_Seps_DetSubOffOne ",
    "UI_ZeD_Seps_DetSubOn UI_ZeD_Seps_DetSubOnOne UI_ZeD_Seps_DetUnder UI_ZeD_Seps_HelpBox UI_ZeD_Seps_HelpDelete UI_ZeD_Seps_HelpFromFolders ",
    "UI_ZeD_Seps_HelpHeld UI_ZeD_Seps_HelpMoveItUp UI_ZeD_Seps_HelpNew UI_ZeD_Seps_HelpReplace UI_ZeD_Seps_HelpRow UI_ZeD_Seps_HelpTri ",
    "UI_ZeD_Seps_ListThis UI_ZeD_Seps_MenuCollapse UI_ZeD_Seps_MenuDelete UI_ZeD_Seps_MenuExpand UI_ZeD_Seps_MenuMoveHead UI_ZeD_Seps_MenuMoveTo ",
    "UI_ZeD_Seps_MenuOffName UI_ZeD_Seps_MenuRename UI_ZeD_Seps_MenuTop UI_ZeD_Seps_ProfCountMany UI_ZeD_Seps_ProfCountOne UI_ZeD_Seps_PromptJump ",
    "UI_ZeD_Seps_RedLater UI_ZeD_Seps_SayDeleted UI_ZeD_Seps_SayFindOpen UI_ZeD_Seps_SayFromFolders UI_ZeD_Seps_SayFromFoldersNone UI_ZeD_Seps_SayFromFoldersRed ",
    "UI_ZeD_Seps_SayFromFoldersRedOne UI_ZeD_Seps_SayHeldFixed UI_ZeD_Seps_SayHeldOn UI_ZeD_Seps_SayLandedOff UI_ZeD_Seps_SayMade UI_ZeD_Seps_SayMadeDup ",
    "UI_ZeD_Seps_SayMovedTop UI_ZeD_Seps_SayMovedUnder UI_ZeD_Seps_SayMovedUp UI_ZeD_Seps_SayOffMany UI_ZeD_Seps_SayOffOne UI_ZeD_Seps_SayOnMany ",
    "UI_ZeD_Seps_SayOnOne UI_ZeD_Seps_SayRenamed UI_ZeD_Seps_WhyNeeds UI_ZeD_Seps_WhyOff UI_ZeD_Seps_WhySepOff UI_ZeD_Seps_WhyWasUnder ",
})

local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local function check(ok, what, detail)
    if ok then S.pass = S.pass + 1 else S.fail = S.fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. ((detail ~= nil and detail ~= "") and (" | " .. tostring(detail)) or ""))
    return ok and true or false
end
local function skip(what, why) S.skips = S.skips + 1; say("SKIP " .. what .. " | " .. tostring(why)) end
local function note(s) say("NOTE " .. tostring(s)) end

-- ---- the stages, on the clock (the menu's frame rate is anyone's guess; the UI's update runs every 100 ms):
-- after(ms, fn) runs fn ms after the stage before it (and three frames at least); waitFor(cond, maxMs, fn) runs
-- fn(true) as soon as cond is true, fn(false) after maxMs; mark() is where the put-back starts (out of time: the
-- queue jumps there)
local function after(ms, fn) S.stages[#S.stages + 1] = { ms = ms, fn = fn } end
local function waitFor(cond, maxMs, fn) S.stages[#S.stages + 1] = { ms = maxMs, cond = cond, fn = fn } end
local function mark() S.markAt = #S.stages + 1 end

-- ---- small things
function K.short(list)
    local out = {}
    for i, s in ipairs(list or {}) do if i <= 8 then out[#out + 1] = tostring(s) end end
    if #(list or {}) > 8 then out[#out + 1] = "(+" .. (#list - 8) .. " more)" end
    return table.concat(out, "; ")
end
function K.try(what, fn)
    local ok, a = pcall(fn)
    if not ok then check(false, what .. " ran without an error", a) end
    return ok, a
end
function K.errs() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function K.errCheck(label)
    local n = K.errs()
    if n == nil or keep.errs == nil then keep.errs = n; return end
    local d = n - keep.errs
    keep.errs = n
    check(d == 0, label .. ": no new Lua error", (d ~= 0) and (d .. " new, see console.txt") or nil)
end
function K.jlist(l)
    local t = {}
    if l then for i = 0, l:size() - 1 do t[#t + 1] = tostring(l:get(i)) end end
    return t
end
function K.count(t) local n = 0; for _ in pairs(t or {}) do n = n + 1 end; return n end
function K.idx(t, v) for i, x in ipairs(t or {}) do if x == v then return i end end; return nil end
function K.join(t) return table.concat(t or {}, ";") end
function K.copy(t) local o = {}; for i, v in ipairs(t or {}) do o[i] = v end; return o end
function K.b(v) return v and "yes" or "no" end

-- ---- options and files
function K.opts()
    if St and St.opts then return St.opts end
    local zo = nil
    pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end)
    return zo
end
function K.opt(id) local o = K.opts(); return o and o.dict and o.dict[id] end
function K.val(id)
    local o, v = K.opt(id), nil
    if o then pcall(function() v = o:getValue() end) end
    return v
end
function K.snapAll()
    local t = {}
    for _, o in ipairs((K.opts() and K.opts().data) or {}) do
        if o.id and o.getValue and o.type ~= "multipletickbox" and o.type ~= "button" then
            local ok, v = pcall(o.getValue, o)
            if ok and v ~= nil and type(v) ~= "table" then t[o.id] = v end
        end
    end
    return t
end
function K.diff(a, b)
    local bad, seen = {}, {}
    for id, v in pairs(a or {}) do seen[id] = true; if (b or {})[id] ~= v then bad[#bad + 1] = id .. "=" .. tostring((b or {})[id]) .. " (was " .. tostring(v) .. ")" end end
    for id, v in pairs(b or {}) do if not seen[id] then bad[#bad + 1] = id .. "=" .. tostring(v) .. " (was nil)" end end
    table.sort(bad)
    return bad
end
function K.setAll(t)
    for id, v in pairs(t or {}) do
        local o = K.opt(id)
        if o and o.setValue and K.val(id) ~= v then pcall(function() o:setValue(v) end) end
    end
end
function K.readLines(name)
    local t = nil
    pcall(function()
        local r = getFileReader(name, false)
        if not r then return end
        t = {}
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        r:close()
    end)
    return t
end
-- lines written each with "\n" after it, as ZeD writes these files (an empty list: an empty file)
function K.put(name, lines)
    pcall(function()
        local w = getFileWriter(name, true, false)
        for _, l in ipairs(lines or {}) do w:write(l); w:write("\n") end
        w:close()
    end)
end
function K.text(name)
    local t = K.readLines(name)
    if not t then return nil end
    return table.concat(t, "\n") .. "\n"
end
function K.same(a, b)
    if a == nil or b == nil then return a == b end
    return table.concat(a, "\n") == table.concat(b, "\n")
end
-- a file back as the run found it (one that was not there: emptied, when the run made it)
function K.restoreFile(name)
    local was = keep.files and keep.files[name]
    if was == nil then return end
    local now = K.readLines(name)
    if was == false then
        if now ~= nil and #now > 0 then K.put(name, {}) end
        return
    end
    if not K.same(now, was) then K.put(name, was) end
end
-- the file as the run found it (one that was not there: none, or empty)
function K.asFound(name)
    local was = keep.files and keep.files[name]
    local now = K.readLines(name)
    if was then return K.same(now, was) end
    return now == nil or #now == 0
end

-- ---- the lightning (hfr_disk.lua): held off; let go at the end
function K.holdZap()
    local z = MM._life and MM._life.zap
    if not z then return end
    if keep.zapAt == nil then keep.zapAt = z.nextAt or 0 end
    z.t0 = nil; z.nextAt = 1e15
end
function K.freeZap()
    local z = MM._life and MM._life.zap
    if z and keep.zapAt ~= nil then z.nextAt = keep.zapAt end
end

-- ---- windows and the Mods screen
function K.ms() return MainScreen and MainScreen.instance end
function K.W() return MM.root and MM.root.modsWin end
function K.up(view)
    local r = MM.root
    local w = r and ((view == "main" and r.win) or (view == "mods" and r.modsWin)) or nil
    return MM.view == view and w ~= nil and w:isVisible() and true or false
end
-- (DK19, MM2, Nov 27 2026: a view left by MM.showView with mods turned on or off now asks Back's question first
-- (ZeD_MMMods:askLeave) and stays; the script's way out is Undo changes (in memory only, never Discard's Accept),
-- the question closed, then the move again)
function K.unhold(w)
    w = w or K.W()
    if not w then return end
    pcall(function()
        if w.confirm then w:setConfirm(false) end
        -- (MO40, Nov 27 2026: an order page left after a move asks "Keep the new order?": it is left the Discard way,
        -- nothing kept)
        if w.page == "order" or w.page == "maps" then K.fakeOff(w); w:leaveOrder(false) end
        if K.model() and w:changed() then note("Mods: a change was waiting on the way out: Undo changes first (leaving now asks)"); w:revert() end
    end)
end
function K.rescue()
    MM.ctx.open = nil
    if MM.view == "mods" then K.unhold(K.W()) end
    pcall(MM.showView, "main")
    if MM.view ~= "main" and MM.view == "mods" then
        K.unhold(K.W())
        pcall(MM.showView, "main")
    end
end
function K.model() return ModSelector and ModSelector.instance and ModSelector.instance.model end
function K.rows() local w = K.W(); local r = {}; if w then pcall(function() r = w:rows() end) end; return r end
function K.activated() local t = {}; pcall(function() t = K.jlist(getActivatedMods()) end); return table.concat(t, ";") end
function K.activeIds()
    local t = {}
    pcall(function() t = K.jlist(K.model():getActiveMods():getMods()) end)
    return table.concat(t, ";")
end
function K.activeList()
    local t = {}
    pcall(function() t = K.jlist(K.model():getActiveMods():getMods()) end)
    return t
end
-- the mods that are on, as one sorted text
function K.onSet()
    local t = {}
    local m = K.model()
    for id, d in pairs((m and m.mods) or {}) do if d.isActive then t[#t + 1] = tostring(id) end end
    if O and O.sort then O.sort(t) else table.sort(t) end
    return table.concat(t, ";")
end
function K.mapOrder()
    local t = {}
    pcall(function() t = K.jlist(K.model():getActiveMods():getMapOrder()) end)
    return t
end
function K.mapsBack()
    pcall(function()
        local mo = K.model():getActiveMods():getMapOrder()
        mo:clear()
        for _, n in ipairs(keep.maps0 or {}) do mo:add(n) end
    end)
end
function K.wouldReset()
    local need = false
    pcall(function() need = ActiveMods.requiresResetLua(ActiveMods.getById("default")) end)
    if need then return "the mod list in memory is not the one running" end
    return nil
end
-- why Back (Accept with nothing changed) would reload Lua and end the script, or nil (bx_menu's)
function K.backReloads(w)
    local m = K.model()
    if not (w and m) then return "no mod list" end
    if w:changed() then return "a change is waiting" end
    local flip = false
    pcall(function() flip = m.ModsEnabled ~= getCore():getOptionModsEnabled() end)
    if flip then return "the game's mods switch moved since the list was read" end
    local need = false
    pcall(function() need = ActiveMods.requiresResetLua(m:getActiveMods()) end)
    if need then return "the load order differs from the one running" end
    if w._picksRefreshed then return "ZeD picks' copies were written again on this visit" end
    if w._resetPending then return "a mod's settings were reset on this visit" end
    local upd = 0
    pcall(function() upd = #ZeD.ModScan.updatedLoaded() end)
    if upd > 0 then return "Steam updated a loaded mod" end
    return nil
end
-- Back with nothing waiting (Accept); when that would reload Lua, the screen is left as the menu bar leaves it
function K.leaveMods(w)
    w = w or K.W()
    if w and (w.page == "order" or w.page == "maps") then K.unhold(w) end
    if w and K.model() and w:changed() then K.unhold(w) end
    local why = K.backReloads(w)
    if why then
        note("Mods: left without Back (" .. why .. ": Back would reload Lua and end this script)")
        MM.showView("main")
        if MM.view == "mods" then
            check(false, "Mods: left by the menu bar's way with nothing waiting, no question held it", "the band asks " .. tostring(w and w.confirm))
            K.rescue()
        end
        return
    end
    w:back()
    if w.confirm then
        check(false, "Mods: Back with nothing waiting asks nothing", tostring(w.confirm))
        w:setConfirm(false)
        MM.showView("main")
    end
end
function K.spec(w, id)
    for _, s in ipairs((w and w._specs) or {}) do if s.id == id then return s end end
    return nil
end
-- a control pressed as the player's click or A: its own fn; returns nil, or why it could not be pressed
function K.press(w, id)
    local s = K.spec(w, id)
    if not s then return "no control " .. id end
    if s.disabled then return id .. " is greyed" end
    if not s.fn then return id .. " does nothing" end
    local ok, e = pcall(s.fn)
    if not ok then return id .. ": " .. tostring(e) end
    return nil
end
function K.noteText(w) return (w and w.note and w.note.text) or "" end
function K.hasRight(rights, id)
    for _, r in ipairs(rights or {}) do if r[1] == id then return true end end
    return false
end
-- a mod's Find text on the Mods list (name, id, Workshop number)
function K.hay(d)
    local wid = ""
    pcall(function() wid = tostring(d.modInfo:getWorkshopID() or "") end)
    return string.lower(tostring(d.name) .. " " .. tostring(d.modId) .. " " .. wid)
end
-- what the machine has for the live checks: installed mods, up to four that are off, can run and need nothing, a
-- pair (a mod that is off and needs one other mod that is off; both can run), a mod that cannot run
function K.cands(w)
    local m = K.model()
    local helper = O.helperId()
    local c = { free = {}, inst = {}, pair = nil, bad = nil }
    for _, d in ipairs((m and m.sortedMods) or {}) do
        local id = d.modId
        c.inst[#c.inst + 1] = id
        local req = -1
        pcall(function() local r = d.modInfo:getRequire(); req = r and r:size() or 0 end)
        local plain = id ~= "ZeD_UI" and id ~= "ModTemplate" and id ~= helper and d.category ~= "map"
        local runs = false
        pcall(function() runs = d.isAvailable and not d.isIncompatible and not w:problemNow(d) and K.count(d.incompatibleWith) == 0 end)
        if plain and not d.isActive and not c.bad then
            local why = nil
            pcall(function() why = w:problemRun(d) end)
            if why then c.bad = id end
        end
        if plain and not d.isActive and runs then
            if req == 0 and #c.free < 4 then c.free[#c.free + 1] = id end
            if req == 1 and not c.pair then
                local r = nil
                pcall(function() r = tostring(d.modInfo:getRequire():get(0)) end)
                local pd = r and m.mods[r]
                local pok, preq = false, -1
                if pd then
                    pcall(function() pok = pd.isAvailable and not pd.isIncompatible and not w:problemNow(pd) and K.count(pd.incompatibleWith) == 0 end)
                    pcall(function() local rr = pd.modInfo:getRequire(); preq = rr and rr:size() or 0 end)
                end
                if pd and pok and preq == 0 and not pd.isActive and pd.category ~= "map" and r ~= helper and r ~= "ModTemplate" then
                    c.pair = { child = id, parent = r }
                end
            end
        end
    end
    -- (the pair's parent is never one of the free mods: their checks turn them on and off on their own)
    if c.pair then
        local t = {}
        for _, id in ipairs(c.free) do if id ~= c.pair.parent and id ~= c.pair.child then t[#t + 1] = id end end
        c.free = t
    end
    return c
end

-- ---- folders (the test file)
function K.file(lines) K.put(TESTF, lines); F.load() end
function K.folderLines(name, ids)
    local L = { "version=2", "next=2", "folder=1|1|" .. F.encode(name) }
    for _, id in ipairs(ids or {}) do L[#L + 1] = "member=" .. F.encode(id) .. "|1" end
    return L
end
function K.fent(w, key)
    local v = w:folderView()
    local k = v.at["frow:" .. tostring(key)]
    return k and v.ents[k] or nil
end
-- a folder id's color and label, kept once before the run gives it its own (put back with K.putColor)
function K.keepColor(fid)
    if keep.col[fid] == nil then keep.col[fid] = { c = ZeD_MMMods.folderColorKey(fid), l = F.labelOf(fid) } end
end
function K.putColor(fid)
    local o = keep.col[fid]
    if not o then return end
    if ZeD_MMMods.folderColorKey(fid) ~= o.c then ZeD_MMMods.setFolderColor(fid, o.c) end
    if F.labelOf(fid) ~= o.l then F.setLabel(fid, o.l) end
end
function K.without(list, pred)
    local t = {}
    for _, l in ipairs(list or {}) do if not pred(l) then t[#t + 1] = l end end
    return t
end

-- ---- the load order page with made-up mods (the page's working copy only)
function K.fakeOne(id, name)
    name = name or id
    return { name = name, req = {}, after = {}, before = {}, installed = true, hay = string.lower(name .. " " .. id) }
end
function K.fake(n)
    local I, ids = {}, {}
    for i = 1, n do
        local id = "zqa" .. i
        ids[i] = id
        I[id] = K.fakeOne(id, "QA Mod " .. i)
    end
    return I, ids
end
function K.lo() return O.copyLo(nil) end
function K.sep(name, ids) return { uid = O.newUid(), name = name, on = true, open = true, ids = ids or {} } end
function K.stage(w, ids, I, lo)
    if w.pick then w:closePicker(true) end
    if w.confirm then w:setConfirm(false) end
    MM.ctx.open = nil
    w.find:setText("")
    lo = lo or K.lo()
    lo.first, lo.last, lo.rules, lo.seps, lo.top = lo.first or {}, lo.last or {}, lo.rules or {}, lo.seps or {}, lo.top or {}
    w.oInfo = I
    w.oLo = lo
    w.order, w.oZone, w.oCarried, w.oSec = O.layout(ids, I, lo, false)
    w.oUndo, w.oOffHere, w.oSepSel, w.oHeldSel = {}, {}, nil, nil
    w.oSel, w.scroll, w.focusId, w.note, w.oDscroll = 1, 0, "orow:1", nil, 0
    w:orderChanged()
end
-- (made-up mods on the page: Done never keeps their order, and Undo and Back never match the game's on/off set
-- to them; both are instance fields over the class's methods, taken off before the page holds real mods again)
function K.fakeOn(w)
    w.sepMatchActive = false
    w.leaveOrder = function(self, keepIt)
        if keepIt then keep.blocked = (keep.blocked or 0) + 1; return end
        return ZeD_MMMods.leaveOrder(self, false)
    end
end
function K.fakeOff(w) w.sepMatchActive = nil; w.leaveOrder = nil end
function K.sepEnt(v, uid)
    for _, e in ipairs((v and v.ents) or {}) do if e.k == "sep" and e.uid == uid then return e end end
    return nil
end
function K.under(w, uid)
    local t = {}
    for _, id in ipairs(w.order) do if (w.oZone[id] or 2) == 2 and (w.oSec[id] or 0) == uid then t[#t + 1] = id end end
    return t
end
-- the page's working copy cleared of pins, rules and separators, laid out from the mods in use
function K.clean(w)
    local ids = K.activeList()
    w.oInfo = w:infoFor(K.model(), ids)
    w.oLo = K.lo()
    w.order, w.oZone, w.oCarried, w.oSec = O.layout(ids, w.oInfo, w.oLo, false)
    w.oUndo, w.oOffHere, w.oSepSel, w.oHeldSel = {}, {}, nil, nil
    w.oSel, w.scroll, w.focusId = 1, 0, "orow:1"
    w:orderChanged()
    -- (MO40, Nov 27 2026: the cleaned page counts as the page as opened, so a move after it is the one that asks)
    w._orderStart = table.concat(w.order or {}, ";")
    w._orderStartLo = ZeD_MMMods.orderLoSig and ZeD_MMMods.orderLoSig(w.oLo) or nil
end
-- the mods in use under separators: defs = { { name, ids, on } }, the rest at the top
function K.realSeps(w, defs)
    local ids = K.activeList()
    w.oInfo = w:infoFor(K.model(), ids)
    local lo = K.lo()
    local inSep = {}
    for _, d in ipairs(defs) do
        local sp = K.sep(d[1], K.copy(d[2]))
        if d[3] == false then sp.on = false end
        lo.seps[#lo.seps + 1] = sp
        for _, id in ipairs(d[2]) do inSep[id] = true end
    end
    for _, id in ipairs(ids) do if not inSep[id] then lo.top[#lo.top + 1] = id end end
    w.oLo = lo
    w.order, w.oZone, w.oCarried, w.oSec = O.layout(O.seqFrom(lo, ids), w.oInfo, lo, false)
    w.oUndo, w.oOffHere, w.oSepSel, w.oHeldSel = {}, {}, nil, nil
    w.oSel, w.scroll, w.focusId, w.note = 1, 0, "orow:1", nil
    w:orderChanged()
end

-- a stage's function that runs only while the Mods screen is up: fn(w, met)
local function M(fn)
    return function(met)
        if keep.noMods then return end
        local w = K.W()
        if not (w and MM.view == "mods") then
            if not keep.modsLost then keep.modsLost = true; check(false, "Mods: the screen stays up while it is walked", "view " .. tostring(MM.view)) end
            return
        end
        return fn(w, met)
    end
end
-- the same while the load order page holds made-up mods
local function P(fn)
    return M(function(w, met)
        if not keep.fakeOk then return end
        if w.page ~= "order" then
            if not keep.fakeLost then keep.fakeLost = true; check(false, "the load order page stays up for the made-up mods' checks", "page " .. tostring(w.page)) end
            return
        end
        return fn(w, met)
    end)
end

-- =========================================================================================================
-- 0: as found, the Mods screen opened on the test folders file
function X.start()
    after(100, function()
        keep.errs = K.errs()
        keep.errs0 = keep.errs
        keep.opt0 = K.snapAll()
        keep.files = {}
        for _, f in ipairs(FILES) do keep.files[f] = K.readLines(f) or false end
        keep.mods0 = K.activated()
        pcall(function() keep.liteVal = St.lookStyleOption:getValue() end)
        keep.ffile = F.FILE
        local there = {}
        for _, f in ipairs(FILES) do there[#there + 1] = f .. " " .. (keep.files[f] and (#keep.files[f] .. " lines") or "absent") end
        say("as found: " .. K.count(keep.opt0) .. " options, Style " .. tostring(keep.liteVal) .. ", view " .. tostring(MM.view) .. ", ModFolders file " .. tostring(F.FILE)
            .. "; " .. table.concat(there, ", "))
        check(MM.openMods and O and O.layout and F and F.parse and ZeD_MMMods and ZeD_MMMods.setFolderColor and ZeD_MMMods.sepNew and ZeD_MMMods.enterOrder and true or false,
            "the parts under test are loaded (ZeD_MainMenuMods, its folders, separators and order pages, ZeD_ModOrder, ZeD_ModFolders)")
        if K.wouldReset() then note("at the start the mod list in memory is not the one running: the Mods screen will be left by the menu bar's way") end
    end)
    waitFor(function()
        local m = K.ms()
        return m ~= nil and not MM.waking and not MM.poweringOn() and (m.delay or 0) <= 0 and MM.root:isVisible()
    end, 30000, function(met)
        check(met, "the desk is awake (powered on, the fade-in over)", "waking " .. tostring(MM.waking))
    end)
    after(1500, function()
        if MM.view ~= "main" then
            note("the desk had the " .. tostring(MM.view) .. " view up at the start (the first-launch setup): back to the main window, nothing answered")
            MM.showView("main")
        end
    end)
    after(400, function()
        check(MM.view == "main" and K.up("main"), "the main window is up", "view " .. tostring(MM.view))
        K.errCheck("the desk at rest")
    end)
    after(200, function()
        F.FILE = TESTF
        K.put(TESTF, {})
        MM.ctx.open = nil
        K.try("Mods: opening", MM.openMods)
    end)
    waitFor(function() return K.up("mods") and #K.rows() > 0 end, 10000, function(met)
        if not check(met, "Mods: the screen opens with its list", "view " .. tostring(MM.view) .. ", rows " .. #K.rows()) then keep.noMods = true; K.rescue(); return end
        local w = K.W()
        keep.filter0, keep.hide0 = w.filter, w.hideInc
        w.hideInc = false
        w.filter = "all"
        w.find:setText("")
        w:dirty()
        keep.ids0 = K.activeIds()
        keep.idsList0 = K.activeList()
        keep.on0 = K.onSet()
        keep.maps0 = K.mapOrder()
        keep.key = O.listKey(K.model())
        keep.lo0 = O.getLo(keep.key)
        keep.c = K.cands(w)
        local c = keep.c
        say("Mods: " .. #c.inst .. " installed, " .. #keep.idsList0 .. " on; the list " .. tostring(keep.key) .. " (" .. #keep.lo0.first .. " first, " .. #keep.lo0.last .. " last, "
            .. #keep.lo0.rules .. " rules, " .. #keep.lo0.seps .. " separators); for the live checks: off and free " .. K.join(c.free)
            .. "; a pair " .. (c.pair and (c.pair.child .. " needs " .. c.pair.parent) or "none") .. "; cannot run " .. tostring(c.bad))
        check(F.FILE == TESTF and not F.any(), "Mods: the folders read from the test file (" .. TESTF .. "), empty", tostring(F.FILE))
    end)
    after(400, M(function(w) K.errCheck("Mods open") end))
end

-- =========================================================================================================
-- 1: on the models alone (MO47, MO60, the file part of MO37)
function X.pure()
    after(150, M(function(w)
        local mainKey = O.listKey(nil)
        local sk = O.listKey({ loadGameFolder = "ZeDQA_mu_none" })
        local nk = O.listKey({ isNewGame = true })
        -- (a server's key reads the game's server settings screen's open settings, which the main menu has none of:
        -- a stand-in screen for this one call, so listKey's pcall'd getName does not raise; put back at once)
        local vk = nil
        if ServerSettingsScreen then
            local inst0 = ServerSettingsScreen.instance
            ServerSettingsScreen.instance = { pageEdit = { settings = { getName = function() return "ZeDQA_mu_server" end } } }
            pcall(function() vk = O.listKey({ isServerSettingsMods = true }) end)
            ServerSettingsScreen.instance = inst0
        else
            vk = O.listKey({ isServerSettingsMods = true })
        end
        vk = tostring(vk)
        local e = O.entry(mainKey, true)
        local was = K.copy(e.first)
        e.first = e.first or {}
        e.first[#e.first + 1] = "zqa_pin"
        local saveLo = O.getLo(sk)
        local mainLo = O.getLo(mainKey)
        e.first = was
        local ok = mainKey == "@list main menu" and sk == "@list save ZeDQA_mu_none" and nk == "@list new game" and string.sub(vk, 1, 13) == "@list server "
            and #saveLo.first == 0 and mainLo.first[#mainLo.first] == "zqa_pin"
        check(ok, "MO47: pins, rules and separators are kept per list (main menu, new game, each save, each server); a save's list never takes the main menu's",
            mainKey .. " | " .. sk .. " | " .. nk .. " | " .. vk .. " | the save's list holds " .. #saveLo.first .. " pins while the main menu's has one more")
        note("MO47: checked on ZeD_ModOrder's list keys and entries; no save's own Mods screen was opened")
    end))
    after(150, M(function(w)
        local miss, n = {}, 0
        for k in string.gmatch(KEYS, "%S+") do
            n = n + 1
            if ZeD.tr(k) == k then miss[#miss + 1] = k end
        end
        check(#miss == 0 and n > 250, "MO60: every ZeD word the three page files name has an entry (" .. n .. " keys, the folder pane's built ones too)", K.short(miss))
    end))
    -- (MO37's file form: a separator with a label written to ZeD_modprofiles.txt, then the file put back)
    after(150, M(function(w)
        local name = "@list ZeDQA mu_order"
        local e = O.entry(name, true)
        e.seps = { { uid = O.newUid(), name = "QA Label", on = true, open = false, ids = { "zqa1", "zqa2" }, label = "green" } }
        e.top = { "zqa0" }
        K.try("MO37: the profile file written", function() O.save() end)
        local raw = K.text("ZeD_modprofiles.txt") or ""
        keep.m37want = "sep=1|0|" .. O.encName("QA Label") .. "|zqa1;zqa2|green"
        keep.m37file = string.find(raw, keep.m37want, 1, true) ~= nil
        O.entries()[name] = nil
        K.restoreFile("ZeD_modprofiles.txt")
        K.restoreFile("ZeD_modprofiles_spare.txt")
        O.load()
        keep.m37back = O.entry(name) == nil and K.asFound("ZeD_modprofiles.txt")
        K.errCheck("the models alone")
    end))
end

-- =========================================================================================================
-- 2: ModFolders.cfg and its words (the test file)
function X.folderFile()
    after(200, M(function(w)
        local L = { "version=2", "next=4", "folder=1|1|51,41,20,41", "folder=2|0|51,41,20,6f", "folder=3|1|51,41,20,43",
                    "member=5A,65,44,5F,55,49|1", "member=7a,71,61,31|2" }
        K.file(L)
        local M0 = F.cur
        local read = #M0.folders == 3 and M0.folders[2].name == "QA o" and M0.folders[2].open == false and F.folderOf("zqa1") == 2
        local ok1 = F.change(function() return true end)
        local same = K.same(K.readLines(TESTF), L)
        local ok2 = F.rename(3, "QA C2")
        local now = K.readLines(TESTF) or {}
        local only = #now == #L
        for i = 1, #L do if i ~= 5 and now[i] ~= L[i] then only = false end end
        only = only and now[5] == "folder=3|1|" .. F.encode("QA C2")
        check(read and ok1 and same and ok2 and only, "MO1: an unchanged ModFolders.cfg round-trips line for line (lower-case hex kept), and one change rewrites only its own line",
            "read " .. K.b(read) .. ", unchanged write the same " .. K.b(same) .. ", the rename touched only line 5 " .. K.b(only) .. ": " .. K.short(now))
    end))
    after(200, M(function(w)
        K.file({ "version=1", "next=3", "folder=1|1|Caf%E9", "folder=2|0|%5730%56FE", "member=ZeD_UI|1", "member=zqa1|2" })
        local f1, f2 = F.byId(1), F.byId(2)
        local read = f1 ~= nil and f2 ~= nil and f1.name == "Caf" .. string.char(0xE9) and f2.name == string.char(0x5730, 0x56FE) and F.folderOf("zqa1") == 2
        local ok = F.setOpen(2, true)
        local want = { "version=2", "next=3", "folder=1|1|43,61,66,E9", "folder=2|1|5730,56FE", "member=5A,65,44,5F,55,49|1", "member=7A,71,61,31|2" }
        local now = K.readLines(TESTF)
        check(read and ok and K.same(now, want), "MO2: a version 1 file reads as the mod reads it (%XX and %XXXX), and the first change rewrites it as version 2",
            "read " .. K.b(read) .. "; now " .. K.short(now or {}))
    end))
    after(200, M(function(w)
        K.file({})
        local a = "Caf" .. string.char(0xE9)
        local b = string.char(0x5730, 0x56FE)
        local c = string.char(0xD83D, 0xDE00)
        local ok1, i1 = F.create(a)
        local ok2, i2 = F.create(b)
        local ok3, i3 = F.create(c)
        local raw = K.text(TESTF) or ""
        local enc = string.find(raw, "|43,61,66,E9\n", 1, true) ~= nil and string.find(raw, "|5730,56FE\n", 1, true) ~= nil and string.find(raw, "|D83D,DE00\n", 1, true) ~= nil
        F.load()
        local back = F.byId(i1) ~= nil and F.byId(i1).name == a and F.byId(i2) ~= nil and F.byId(i2).name == b and F.byId(i3) ~= nil and F.byId(i3).name == c
        check(ok1 and ok2 and ok3 and enc and back, "MO3: accented, CJK and emoji folder names save as one hex code per UTF-16 unit and read back the same",
            "ids " .. tostring(i1) .. ", " .. tostring(i2) .. ", " .. tostring(i3) .. "; encoded " .. K.b(enc) .. ", read back " .. K.b(back))
        skip("MO3: the [B42]Mod Folders mod reading the names ZeD wrote", "by hand: that mod on and a Lua reload (modfolders_crossread.lua)")
    end))
    after(200, M(function(w)
        local L = { "version=2", "next=2", "folder=1|1|51,41", "garbage line here", "member=bad", "folder=x|1|41", "", "member=5A,65,44,5F,55,49|1" }
        K.file(L)
        local bad = F.cur.bad
        w.msel = nil
        local status = nil
        K.try("MO20: the status line", function() status = w:getStatusLine() end)
        local want = ZeD.tr("UI_ZeD_Folders_StatusBad", 3)
        local ok, id = F.create("QA New")
        local mine = "folder=" .. tostring(id) .. "|1|" .. F.encode("QA New")
        local function drop(l) return l == mine or string.sub(l, 1, 5) == "next=" end
        local rest = K.without(K.readLines(TESTF), drop)
        check(bad == 3 and status == want and ok and K.same(rest, K.without(L, drop)), "MO20: lines ZeD can't read are counted on the status line and stay in their places through a change",
            "counted " .. tostring(bad) .. "; the status line: " .. tostring(status) .. "; kept in place " .. K.b(K.same(rest, K.without(L, drop))))
    end))
    after(200, M(function(w)
        K.file({ "version=2", "next=2", "folder=1|1|51,41" })
        K.put(TESTF, { "version=2", "next=2", "folder=1|1|51,41", "folder=7|1|51,42" })
        local v = w:folderView()
        local notYet = F.byId(7) == nil and v.at["frow:7"] == nil
        local ok, id = F.create("QA C")
        local raw = K.text(TESTF) or ""
        local kept = ok and string.find(raw, "folder=7|1|51,42\n", 1, true) ~= nil and F.byId(7) ~= nil and id == 8
        K.put(TESTF, K.without(K.readLines(TESTF), function(l) return l == "folder=7|1|51,42" end))
        w.note = nil
        K.try("MO19: a move into a folder deleted outside", function() w:folderMove({ "ZeD_UI" }, 7) end)
        local gone = K.noteText(w) == ZeD.tr("UI_ZeD_Folders_SayGone")
        check(notYet and kept and gone, "MO19: an outside edit shows when the page opens again and is kept by the next change; a move into a folder deleted outside says it is gone",
            "not shown before a reload " .. K.b(notYet) .. ", kept (new id " .. tostring(id) .. ") " .. K.b(kept) .. "; the band: " .. K.noteText(w))
        K.errCheck("ModFolders.cfg")
    end))
end

-- 3: the band's name field, the limit, the pane, Delete
function X.folderField()
    after(200, M(function(w)
        K.file({ "version=2", "next=3", "folder=1|1|" .. F.encode("Cars"), "folder=2|1|" .. F.encode("Boats") })
        local p1 = F.nameProblem("cars")
        local p2 = F.nameProblem("CARS", 1)
        local ok = F.rename(1, "CARS")
        keep.m10 = { p1 == "UI_ZeD_Folders_NameUsed", p2 == nil, ok and F.byId(1).name == "CARS" }
        K.try("MO10: New folder asked", function() w:folderAskNew(nil) end)
        w.field:setText("boats")
    end))
    after(350, M(function(w)
        local s = K.spec(w, "confirm:yes")
        local grey = s ~= nil and s.disabled == true
        local ask = tostring(w._bandAsk)
        check(keep.m10[1] and keep.m10[2] and keep.m10[3] and grey and ask == ZeD.tr("UI_ZeD_Folders_NameUsed", "Boats"),
            "MO10: a name another folder uses, in any case, greys Make and says so; a rename that changes only the case is allowed",
            "used " .. K.b(keep.m10[1]) .. ", case-only rename " .. K.b(keep.m10[2] and keep.m10[3]) .. ", Make greyed " .. K.b(grey) .. "; the band: " .. ask)
        w.field:setText(string.rep("M", 60))
    end))
    after(350, M(function(w)
        local typed = #(w.field:getText() or "")
        w:setConfirm(false)
        K.file({ "version=2", "next=2", "folder=1|1|" .. F.encode(string.rep("L", 60)) })
        local long = F.byId(1) and #F.byId(1).name or 0
        local ok, id = F.create(string.rep("N", 60))
        local made = ok and F.byId(id) and #F.byId(id).name or 0
        check(typed == 48 and long == 60 and made == 48, "MO11: typing stops at 48 letters; a longer name from the file stays",
            "typed " .. typed .. ", from the file " .. long .. ", made " .. tostring(made))
        note("MO11: the longer name is cut on the folder's head and pane only as drawn (truncateText); the file keeps all " .. long)
    end))
    after(200, M(function(w)
        local L = { "version=2", "next=99" }
        for i = 1, 98 do L[#L + 1] = "folder=" .. i .. "|1|" .. F.encode("F" .. i) end
        K.file(L)
        keep.m9a = w:folderNewSpec()[5] == false
        L[2] = "next=100"
        L[#L + 1] = "folder=99|1|" .. F.encode("F99")
        keep.m9L = L
        K.try("MO9: New folder asked at 98", function() w:folderAskNew(nil) end)
        w.field:setText("QA ninety nine")
    end))
    after(300, M(function(w)
        K.put(TESTF, keep.m9L)
        w.note = nil
        K.try("MO9: Make pressed after a 99th folder came in", function() w:folderFieldEnter("fnew") end)
        local said = K.noteText(w)
        if w.confirm then w:setConfirm(false) end
        F.load()
        local s99 = w:folderNewSpec()[5] == true
        local menuGrey = false
        local e = K.fent(w, 1)
        if e then
            K.try("MO9: the folder row's menu", function() w:folderMenu(e, nil) end)
            local items = (MM.popup and MM.popup.items) or {}
            local last = items[#items]
            menuGrey = type(last) == "table" and last.disabled == true
            MM.ctx.open = nil
        end
        check(keep.m9a and s99 and menuGrey, "MO9: New folder... greys at 99 folders (the band and the folder row's menu), not at 98",
            "98: open " .. K.b(keep.m9a) .. "; 99: band greyed " .. K.b(s99) .. ", menu greyed " .. K.b(menuGrey))
        check(said == ZeD.tr("UI_ZeD_Folders_HelpFull"), "MO9: a 99th folder made elsewhere while the name field is open: Make says the folders are full",
            "the band says: " .. said)
        K.file({ "version=2", "next=2", "folder=1|1|" .. F.encode("QA Taken") })
        K.try("MO9: New folder asked for a name taken meanwhile", function() w:folderAskNew(nil) end)
        w.field:setText("QA Late")
    end))
    after(300, M(function(w)
        -- (the name comes in from outside while the field is open; the file is written, not read in)
        K.put(TESTF, { "version=2", "next=3", "folder=1|1|" .. F.encode("QA Taken"), "folder=2|1|" .. F.encode("QA Late") })
        w.note = nil
        K.try("MO9: Make pressed after the name was taken", function() w:folderFieldEnter("fnew") end)
        local taken = K.noteText(w)
        if w.confirm then w:setConfirm(false) end
        F.load()
        w._fTarget = 2
        K.put(TESTF, { "version=2", "next=3", "folder=1|1|" .. F.encode("QA Taken") })   -- (folder 2 deleted outside)
        w.note = nil
        K.try("MO9: Delete on a folder deleted outside", function() w:folderDelete() end)
        local gone = K.noteText(w)
        F.load()
        local _, openWhy = F.setOpen(42, false)
        local noWrite = ZeD.tr("UI_ZeD_Folders_SayNoWrite")
        check(taken == ZeD.tr("UI_ZeD_Folders_NameUsed", "QA Late") and gone == ZeD.tr("UI_ZeD_Folders_SayGone") and openWhy == "gone",
            "MO9: every refusal says its own reason (a name taken meanwhile, a folder gone), not that ModFolders.cfg could not be written",
            "name taken: \"" .. taken .. "\"; deleted outside: \"" .. gone .. "\"; open on a folder gone: " .. tostring(openWhy)
            .. ((taken == noWrite or gone == noWrite) and " (the file was blamed)" or ""))
    end))
    after(200, M(function(w)
        local gA, gB = "ZeDQA_gone_a", "ZeDQA_gone_b"
        K.file({ "version=2", "next=2", "folder=1|1|" .. F.encode("QA Miss"), "member=" .. F.encode("ZeD_UI") .. "|1",
                 "member=" .. F.encode(gA) .. "|1", "member=" .. F.encode(gB) .. "|1" })
        w.fsel, w.sel, w._fDet = 1, nil, nil
        local c = w:folderDetailModel(400)
        local listed = #c.missing == 2 and c.missing[1] == gA and #c.outVerbs == 2 and #c.mods == 1
        K.try("MO17: Take out", function() w:folderDropMissing(gA) end)
        local raw = K.text(TESTF) or ""
        local dropped = string.find(raw, F.encode(gA) .. "|", 1, true) == nil and string.find(raw, F.encode(gB) .. "|", 1, true) ~= nil and F.folderOf("ZeD_UI") == 1
        check(listed and dropped, "MO17: a member line for a mod that is not installed lists under Not installed with Take out, which removes only that line",
            "listed " .. K.b(listed) .. " (" .. #c.missing .. " missing, " .. #c.mods .. " installed), only that line gone " .. K.b(dropped))
        K.try("MO12: Delete folder asked", function() w:folderAskDelete(1) end)
    end))
    after(300, M(function(w)
        local ask = tostring(w._bandAsk)
        local n = w:folderView().tot[1] or 0
        local miss = #F.membersOf(1) - n
        local open = w.confirm == "fdelete"
        K.try("MO12: Delete", function() w:folderDelete() end)
        local raw = K.text(TESTF) or ""
        local left = string.find(raw, "|1\n", 1, true) ~= nil
        local tail = (miss == 1 and ZeD.tr("UI_ZeD_Folders_AskDeleteMissingOne")) or (miss > 1 and ZeD.tr("UI_ZeD_Folders_AskDeleteMissingMany", miss)) or ""
        local said = miss > 0 and #ask >= #tail and string.sub(ask, #ask - #tail + 1) == tail
        check(open and miss > 0 and said and not left,
            "MO12: Delete folder's question says the member lines for mods not installed go too (and they go)",
            n .. " installed, " .. miss .. " not installed; asked " .. K.b(open) .. ": \"" .. ask .. "\"; a member line left " .. K.b(left))
        K.errCheck("the folder name field and pane")
    end))
end

-- 4: colors, labels, the moved count, open and close, picked rows
function X.folderLook()
    after(200, M(function(w)
        K.file({})
        local ok, id = F.create("QA Doomed")
        if not ok then check(false, "MO5: a test folder made", "F.create refused"); return end
        K.keepColor(id)
        ZeD_MMMods.setFolderColor(id, "red")
        F.setLabel(id, "blue")
        F.delete(id)
        local c1, l1 = ZeD_MMMods.folderColorKey(id), F.labelOf(id)
        K.file({})
        local ok2, id2 = F.create("QA Fresh")
        if ok2 then K.keepColor(id2) end
        local c2, l2 = ZeD_MMMods.folderColorKey(id2), F.labelOf(id2)
        check(c1 == nil and l1 == nil and c2 == nil and l2 == nil, "MO5: a deleted folder's color and label go with it (a new folder that takes its number starts plain)",
            "after Delete folder " .. tostring(id) .. ": color " .. tostring(c1) .. ", label " .. tostring(l1) .. "; a fresh file's new folder " .. tostring(id2) .. ": color " .. tostring(c2) .. ", label " .. tostring(l2))
        K.putColor(id)
        if ok2 then K.putColor(id2) end
    end))
    after(200, M(function(w)
        K.file({ "version=2", "next=2", "folder=1|1|" .. F.encode("QA Color") })
        K.keepColor(1)
        ZeD_MMMods.setFolderColor(1, "teal")
        K.try("MO7: the Color menu", function() w:folderColorMenu(1, nil) end)
        local items = (MM.ctx.open == "folderColor" and MM.popup and MM.popup.items) or {}
        local ticked, which = 0, nil
        for i, it in ipairs(items) do if type(it) == "table" and it.check then ticked = ticked + 1; which = i end end
        MM.ctx.open = nil
        local tealAt = 0
        for i, k in ipairs(St.accentKeys or {}) do if k == "teal" then tealAt = i end end
        local none = items[1] and items[1].text == ZeD.tr("UI_ZeD_Folders_ColorNone")
        check(#items == 9 and ticked == 1 and which == tealAt + 1 and none, "MO7: the Color menu lists None and eight colors with the game's color names, the folder's own ticked",
            #items .. " rows, " .. ticked .. " ticked (row " .. tostring(which) .. ", teal)")
        note("MO7: the comment over the Color menu (ZeD_MainMenuModsFolders.lua) says nine accents; the menu has None and eight (mono is left out)")
        K.putColor(1)
    end))
    after(200, M(function(w)
        local L = { "version=2", "next=2", "folder=1|1|" .. F.encode("QA Dest") }
        for i = 1, 3 do L[#L + 1] = "member=" .. F.encode("zqa" .. i) .. "|1" end
        K.file(L)
        w.note = nil
        K.try("MO8: five moved into the folder", function() w:folderMove({ "zqa1", "zqa2", "zqa3", "zqa4", "zqa5" }, 1) end)
        local said = K.noteText(w)
        local moved = #F.membersOf(1) - 3
        w.note = nil
        K.try("MO8: three taken out, two of them in the folder", function() w:folderMove({ "zqa1", "zqa2", "zqa9" }, nil) end)
        local out = K.noteText(w)
        local outN = 5 - #F.membersOf(1)
        check(moved == 2 and said == ZeD.tr("UI_ZeD_Folders_SayMovedMany", moved, "QA Dest") and outN == 2 and out == ZeD.tr("UI_ZeD_Folders_SayOutMany", outN),
            "MO8: Move to folder's count is the number of mods that moved (into a folder and out to Unfiled)",
            "5 picked, 3 already in it, " .. moved .. " moved; the band says: " .. said .. "; 3 taken out, " .. outN .. " were in it; the band says: " .. out)
    end))
    after(200, M(function(w)
        local a = nil
        for _, d in ipairs(K.rows()) do if not a and d.modId ~= "ZeD_UI" then a = d.modId end end
        a = a or "ZeD_UI"
        K.file(K.folderLines("QA Open", { a }))
        w.find:setText("")
        local e = K.fent(w, 1)
        w:folderOpenClose(e)
        local r1 = string.find(K.text(TESTF) or "", "folder=1|0|", 1, true) ~= nil and K.fent(w, 1).open == false
        w._lastFClick = nil
        w:clickFolder(K.fent(w, 1))
        w:clickFolder(K.fent(w, 1))
        local r2 = string.find(K.text(TESTF) or "", "folder=1|1|", 1, true) ~= nil
        w.find:setText("zz")
        w.note = nil
        local before = K.text(TESTF)
        w:folderOpenClose(e)
        local r3 = K.noteText(w) == ZeD.tr("UI_ZeD_Folders_SayFindOpen") and K.text(TESTF) == before
        w.find:setText("")
        local u = K.fent(w, "unfiled")
        local was = F.unfiledOpen()
        local cfg0 = K.text(TESTF)
        local r4 = false
        if u then
            w:folderOpenClose(u)
            local ui = K.readLines("ZeD_modfolders.txt") or {}
            r4 = F.unfiledOpen() == (not was) and ui[1] == ("unfiledOpen=" .. ((not was) and "1" or "0")) and K.text(TESTF) == cfg0
            w:folderOpenClose(K.fent(w, "unfiled"))
        end
        w.focusId, w.fsel, w.sel = "mrow:" .. a, nil, a
        w:folderOpenClose(K.fent(w, 1))
        local r5 = w.focusId == "frow:1" and w.fsel == 1 and w.sel == nil
        w:folderOpenClose(K.fent(w, 1))
        check(r1 and r2 and r3 and r4 and r5, "MO13: open and close by the triangle and a double-click, saved in the file; refused while Find has text; Unfiled's state in ZeD's own file; a hidden focused row hands the focus to its folder",
            "triangle " .. K.b(r1) .. ", double-click " .. K.b(r2) .. ", refused with Find " .. K.b(r3) .. ", Unfiled " .. K.b(r4) .. ", focus " .. K.b(r5))
    end))
    after(200, M(function(w)
        K.file({})
        local m = K.model()
        local a, b = nil, nil
        local inst = keep.c.inst
        local lim = math.min(#inst, 30)
        for i = 1, lim do
            local x = inst[i]
            for j = 1, lim do
                local y = inst[j]
                if not a and x ~= y and m.mods[x] and m.mods[y] and string.find(K.hay(m.mods[y]), string.lower(x), 1, true) == nil then a, b = x, y end
            end
            if a then break end
        end
        if not a then skip("MO16: picked rows Find hides", "fewer than two installed mods that Find tells apart"); return end
        w.msel = { [a] = true, [b] = true }
        w.find:setText(string.lower(a))
        local vis = w:visibleModIds()
        local bShown = K.idx(vis, b) ~= nil
        local targets = w:folderTargets(m.mods[a])
        local bGoes = K.idx(targets, b) ~= nil
        w.find:setText("")
        local esc = false
        if w.msel and not w.confirm and not w._palette and w.page == "list" then
            w:keyEscape()
            esc = w.msel == nil and w.page == "list" and MM.view == "mods"
        end
        note("MO16: picked rows a tab or Find hides still move with Move to folder (the hidden one goes: " .. K.b(bGoes) .. ", in sight: " .. K.b(bShown)
            .. "); Shift-click spans only rows in sight (visibleModIds); Escape drops the pick (" .. K.b(esc) .. ")")
        w.msel = nil
        K.errCheck("folder colors, counts, open and close")
    end))
end

-- 5: a folder's box and the order it lays out (installed mods turned on; Undo changes after)
function X.folderBox()
    after(250, M(function(w)
        local c = keep.c
        keep.ids14 = {}
        for _, id in ipairs(c.free) do if #keep.ids14 < 2 then keep.ids14[#keep.ids14 + 1] = id end end
        if #keep.ids14 < 2 then keep.no14 = true; skip("MO14: a folder's box turns its mods on and off", "fewer than two installed mods here that are off and can run"); return end
        if c.pair then keep.ids14[#keep.ids14 + 1] = c.pair.child end
        K.file(K.folderLines("QA Box", keep.ids14))
        local m = K.model()
        w.note = nil
        K.try("MO14: the folder's box (none on)", function() w:folderBox(1) end)
        keep.say14a = K.noteText(w)
        local allOn = true
        for _, id in ipairs(keep.ids14) do if not (m.mods[id] and m.mods[id].isActive) then allOn = false end end
        keep.on14 = allOn
        keep.came14 = true
        if c.pair then
            local p = m.mods[c.pair.parent]
            keep.came14 = p ~= nil and p.isActive and string.find(keep.say14a, tostring(p.name), 1, true) ~= nil
        end
        w.note = nil
        K.try("MO14: the folder's box (all on)", function() w:folderBox(1) end)
        local allOff = true
        for _, id in ipairs(keep.ids14) do if m.mods[id] and m.mods[id].isActive then allOff = false end end
        keep.off14 = allOff
        K.try("MO14: Undo changes", function() w:revert() end)
    end))
    after(300, M(function(w)
        if keep.no14 then return end
        local c = keep.c
        local named, said = true, ""
        if c.bad then
            K.file(K.folderLines("QA Box", { keep.ids14[1], c.bad }))
            w.note = nil
            K.try("MO14: the box with a mod that cannot run", function() w:folderBox(1) end)
            local bd = K.model().mods[c.bad]
            said = K.noteText(w)
            named = bd ~= nil and not bd.isActive and string.find(said, tostring(bd.name), 1, true) ~= nil
            K.try("MO14: Undo changes", function() w:revert() end)
        end
        check(keep.on14 and keep.came14 and keep.off14 and named and K.onSet() == keep.on0,
            "MO14: a folder's box turns all on in one batch (a requirement comes along, a mod that cannot run is named), all off from all on; Undo changes puts the set back",
            "on " .. K.b(keep.on14) .. ", came along " .. (c.pair and K.b(keep.came14) or "(no pair)") .. ", off " .. K.b(keep.off14) .. ", named " .. (c.bad and K.b(named) or "(none)")
            .. "; the band: " .. tostring(keep.say14a) .. (said ~= "" and (" / " .. said) or ""))
        skip("MO14: on a save's own list a mod its world may hold stays on", "the main menu's list here; that needs a save's own Mods screen")
    end))
    after(250, M(function(w)
        local fa = keep.c.free[1]
        if not fa then keep.no15 = true; skip("MO15: a folder turned on lays the order out again", "no installed mod here that is off and can run"); return end
        local m = K.model()
        local helper = O.helperId()
        local pin = nil
        for _, id in ipairs(K.activeList()) do if not pin and id ~= helper then pin = id end end
        if not pin then keep.no15 = true; skip("MO15: a folder turned on lays the order out again", "no mod on to pin"); return end
        keep.pin15 = pin
        local lo = K.lo()
        lo.last = { pin }
        O.putLo(keep.key, lo, false)
        K.file(K.folderLines("QA Lay", { fa }))
        K.try("MO15: the box while Load last is set", function() w:folderBox(1) end)
        local ord = K.activeList()
        local _, zone = O.layout(ord, w:infoFor(m, ord), lo, false)
        local iF = K.idx(ord, fa)
        local ok = iF ~= nil and zone[fa] == 2
        for k = (iF or #ord) + 1, #ord do if (zone[ord[k]] or 2) == 2 then ok = false end end
        keep.m15a = ok and K.idx(ord, pin) ~= nil and K.idx(ord, pin) > iF
        keep.m15ad = K.short(ord)
        K.try("MO15: Undo changes", function() w:revert() end)
        O.putLo(keep.key, K.lo(), false)
    end))
    after(300, M(function(w)
        if keep.no15 then return end
        local fa = keep.c.free[1]
        K.try("MO15: the box with no pins, rules or separators", function() w:folderBox(1) end)
        local ord = K.activeList()
        local iF = K.idx(ord, fa)
        local helper = O.helperId()
        keep.m15b = iF ~= nil and (iF == #ord or (iF == #ord - 1 and ord[#ord] == helper))
        local ordB = K.short(ord)
        K.try("MO15: Undo changes", function() w:revert() end)
        O.putLo(keep.key, keep.lo0, false)
        local I, ids = K.fake(3)
        local lo = K.lo()
        lo.seps = { K.sep("QA A", { "zqa1" }), K.sep("QA B", { "zqa2" }) }
        local _, _, _, sec = O.layout(ids, I, lo, false)
        local under = sec.zqa3 == lo.seps[2].uid
        check(keep.m15a and keep.m15b and under and K.onSet() == keep.on0,
            "MO15: a folder turned on lays the order out again only while the list has pins, rules or separators; the newly on mod lands at the end of the middle (above Load last, under the last separator)",
            "with " .. tostring(keep.pin15) .. " Load last: " .. tostring(keep.m15ad) .. "; with none, left at the end " .. K.b(keep.m15b) .. " (" .. ordB .. "); under the last separator " .. K.b(under))
        K.errCheck("a folder's box")
    end))
end

-- =========================================================================================================
-- 6: the load order page with made-up mods
function X.fakeEnter()
    after(250, M(function(w)
        K.file({})
        K.try("the load order page opened", function() w:enterOrder("order") end)
        keep.oSel0 = w.oSel
        keep.fakeOk = w.page == "order"
        if not check(keep.fakeOk, "the load order page opens", tostring(w.page)) then return end
        K.fakeOn(w)
    end))
end
function X.fakeSeps()
    after(250, P(function(w)
        local I, ids = K.fake(8)
        K.stage(w, ids, I, nil)
        w:orderSelectAt(3, false)
        w:sepNew("QA One")
        local one = w.oLo.seps[1]
        local under = one ~= nil
        for i = 3, 8 do if not one or w.oSec["zqa" .. i] ~= one.uid then under = false end end
        local top = (w.oSec.zqa1 or 0) == 0 and (w.oSec.zqa2 or 0) == 0
        w:sepNew("QA Zero")
        local above = w.oLo.seps[1].name == "QA Zero" and w.oLo.seps[2].name == "QA One"
        O.setPin(w.oLo, "zqa1", "first")
        w:orderLayout(false)
        w:orderSelect("zqa1", false)
        w:sepNew("QA End")
        local last = w.oLo.seps[#w.oLo.seps]
        local a = w:sepRange(last.uid)
        local atEnd = last.name == "QA End" and a == nil
        check(under and top and above and atEnd, "MO21: New separator goes above the picked mod (it and the mods under it, down to the next separator, go under it), above a picked separator, and at the end, empty, for a mod in a pinned block",
            "under " .. K.b(under) .. ", the top kept " .. K.b(top) .. ", above a separator " .. K.b(above) .. ", at the end " .. K.b(atEnd))
        note("MO21: the help says \"with nothing picked, at the end\" (UI_ZeD_Seps_HelpNew), but the page always has a row picked (row " .. tostring(keep.oSel0) .. " as it opened)")
    end))
    after(200, P(function(w)
        w.note = nil
        w:sepNew("qa one")
        keep.m22a = K.noteText(w) == ZeD.tr("UI_ZeD_Seps_SayMadeDup", "qa one")
        K.try("MO22: New separator asked", function() w:sepAskNew() end)
        w.field:setText("QA One")
    end))
    after(300, P(function(w)
        local s = K.spec(w, "confirm:yes")
        keep.m22b = s ~= nil and s.disabled == false
        keep.m22ask = tostring(w._bandAsk)
        w.field:setText("")
    end))
    after(300, P(function(w)
        local s = K.spec(w, "confirm:yes")
        local grey = s ~= nil and s.disabled == true
        w:setConfirm(false)
        check(keep.m22a and keep.m22b and grey, "MO22: a duplicate separator name is allowed with a warning; Make greys only for an empty name",
            "made with the warning " .. K.b(keep.m22a) .. ", Make open on a used name " .. K.b(keep.m22b) .. ", greyed when empty " .. K.b(grey))
        note("MO22: a second separator named \"qa one\" was made; with a used name the band reads: " .. keep.m22ask)
    end))
    after(200, P(function(w)
        local I, ids = K.fake(6)
        local A, B = K.sep("QA A", { "zqa2", "zqa3" }), K.sep("QA B", { "zqa4", "zqa5" })
        local lo = K.lo()
        lo.top, lo.seps = { "zqa1" }, { A, B, K.sep("QA C", { "zqa6" }) }
        K.stage(w, ids, I, lo)
        w:sepDelete(A.uid)
        local noAsk = not w.confirm and #w.oLo.seps == 2
        w:sepSelect(B.uid)
        w:orderKey(Keyboard.KEY_DELETE)
        local byKey = not w.confirm and #w.oLo.seps == 1
        w:orderUndo()
        w:orderUndo()
        local back = #w.oLo.seps == 3 and w.oLo.seps[1].uid == A.uid and w.oLo.seps[2].uid == B.uid
        check(back, "MO23: Undo brings deleted separators back", #w.oLo.seps .. " separators after two Undos")
        note("MO23: Delete separator asks nothing (from the pane or menu: " .. K.b(noAsk) .. ", the Delete key: " .. K.b(byKey) .. "), where Delete folder asks first")
    end))
    after(200, P(function(w)
        local I, ids = K.fake(6)
        local A, B, C = K.sep("QA Above", { "zqa3", "zqa4" }), K.sep("QA Off", { "zqa_offmod" }), K.sep("QA Gone", { "zqa5", "zqa6" })
        B.on = false
        local lo = K.lo()
        lo.top, lo.seps = { "zqa1", "zqa2" }, { A, B, C }
        K.stage(w, ids, I, lo)
        local ord0 = K.join(w.order)
        w:sepDelete(C.uid)
        local a1 = w.oSec.zqa5 == B.uid and w.oSec.zqa6 == B.uid
        w:sepDelete(B.uid)
        local a2 = w.oSec.zqa5 == A.uid and w.oSec.zqa6 == A.uid
        local sp = w:sepGet(A.uid)
        local inA = sp ~= nil and K.idx(sp.ids, "zqa_offmod") ~= nil
        local why = w.oOffHere.zqa_offmod
        check(K.join(w.order) == ord0 and a1 and a2 and inA and why == ZeD.tr("UI_ZeD_Seps_WhyWasUnder", "QA Off"),
            "MO24: deleting a separator keeps its mods in place under the one above; its off mods go along, reading \"Off: was under ...\" from an off separator",
            "order kept " .. K.b(K.join(w.order) == ord0) .. ", under the one above " .. K.b(a1 and a2) .. ", the off mod carried " .. K.b(inA) .. " (" .. tostring(why) .. ")")
    end))
    after(200, P(function(w)
        local I, ids = K.fake(6)
        local A, B = K.sep("QA A", { "zqa3", "zqa4" }), K.sep("QA B", { "zqa5", "zqa6" })
        local lo = K.lo()
        lo.top, lo.seps = { "zqa1", "zqa2" }, { A, B }
        K.stage(w, ids, I, lo)
        local p = w:orderIndexOf("zqa5")
        w:orderSelectAt(p, false)
        w:move(-1)
        local up = w.oSec.zqa5 == A.uid and w:orderIndexOf("zqa5") == p
        w:move(1)
        local down = w.oSec.zqa5 == B.uid and w:orderIndexOf("zqa5") == p
        w:sepMoveModTo("zqa1", B.uid)
        local toB = w.oSec.zqa1 == B.uid and w:orderIndexOf("zqa1") == #w.order
        w:orderMoveTo(w:orderIndexOf("zqa2"), w:orderIndexOf("zqa4"))
        local drop = w.oSec.zqa2 == A.uid
        check(up and down and toB and drop, "MO27: Move up or down at a section's edge crosses one separator, its place unchanged; Move to separator... puts it at that section's bottom; a drop takes the target row's section",
            "up " .. K.b(up) .. ", down " .. K.b(down) .. ", Move to separator " .. K.b(toB) .. ", a drop (orderMoveTo, as the release calls it) " .. K.b(drop))
        skip("MO27: a real mouse drag across separators", "by hand: needs ZeD.MouseTick and a real press")
    end))
    after(200, P(function(w)
        local I, ids = K.fake(5)
        local A = K.sep("QA Fold", { "zqa3", "zqa4", "zqa5" })
        local lo = K.lo()
        lo.top, lo.seps = { "zqa1", "zqa2" }, { A }
        K.stage(w, ids, I, lo)
        w:orderSelectAt(4, false)
        w:sepOpenClose(A.uid, false)
        local handed = w.oSepSel == A.uid and A.open == false
        local v = w:orderView()
        local e = K.sepEnt(v, A.uid)
        local cnt = e and e.cnt or "?"
        local cntOk = cnt == "(" .. ZeD.tr("UI_ZeD_Seps_CountHidden", 3, 3, 5) .. ")"
        local hidden = v.byPlace[3] == nil and v.byPlace[5] == nil and v.byPlace[1] ~= nil
        w.find:setText("zqa")
        w.note = nil
        w:sepOpenClose(A.uid)
        local refused = A.open == false and K.noteText(w) == ZeD.tr("UI_ZeD_Seps_SayFindOpen")
        w.find:setText("")
        w:sepSelect(A.uid)
        w:orderKey(Keyboard.KEY_RIGHT)
        local kr = A.open == true
        w:orderKey(Keyboard.KEY_LEFT)
        local kl = A.open == false
        w._sClick = nil
        local e2 = K.sepEnt(w:orderView(), A.uid)
        if e2 then w:clickSep(e2); w:clickSep(e2) end
        local dbl = A.open == true
        check(handed and cntOk and hidden and refused and kr and kl and dbl, "MO29: collapse by Left and Right and a double-click, its count \"(n | a to b hidden)\", refused while Find has text; a picked mod hidden hands the pick to the separator",
            "pick handed " .. K.b(handed) .. ", count " .. cnt .. ", rows hidden " .. K.b(hidden) .. ", refused with Find " .. K.b(refused) .. ", Right " .. K.b(kr) .. ", Left " .. K.b(kl) .. ", double-click " .. K.b(dbl))
    end))
    after(200, P(function(w)
        local I, ids = K.fake(6)
        local names = { "Apple", "Banana", "Radio Alpha", "Cherry", "Radio Beta", "Damson" }
        for i, id in ipairs(ids) do I[id].name = names[i]; I[id].hay = string.lower(names[i] .. " " .. id) end
        local A, B = K.sep("Fruit", { "zqa3", "zqa4" }), K.sep("Tuner", { "zqa5", "zqa6" })
        A.open = false
        local lo = K.lo()
        lo.top, lo.seps = { "zqa1", "zqa2" }, { A, B }
        K.stage(w, ids, I, lo)
        w.find:setText("radio")
        local v = w:orderView()
        local eA, eB = K.sepEnt(v, A.uid), K.sepEnt(v, B.uid)
        local r1 = eA ~= nil and eB ~= nil and eA.cnt == "(" .. ZeD.tr("UI_ZeD_Order_HeadOf", 1, 2) .. ")" and v.byPlace[3] ~= nil and v.byPlace[4] == nil and v.byPlace[1] == nil
        w.find:setText("tuner")
        v = w:orderView()
        local r2 = K.sepEnt(v, A.uid) == nil and K.sepEnt(v, B.uid) ~= nil and v.byPlace[5] ~= nil and v.byPlace[6] ~= nil
        w.find:setText("")
        check(r1 and r2, "MO30: Find with separators: a separator shows when it holds a match (\"(1 of 2)\", a collapsed one open for the moment) or its own name matches (then all its mods)",
            "matches " .. K.b(r1) .. " (" .. tostring(eA and eA.cnt) .. "), its name " .. K.b(r2))
    end))
    after(200, P(function(w)
        local I, ids = K.fake(5)
        I.zqa2.req = { "zqa4" }
        local lo = K.lo()
        lo.top, lo.seps = { "zqa1" }, { K.sep("QA Needs", { "zqa2", "zqa3" }), K.sep("QA Needed", { "zqa4", "zqa5" }) }
        K.stage(w, ids, I, lo)
        local res = w:orderCheck()
        local red = res.firstBad ~= nil
        local who, need = w:sepCrossNeed()
        local rights = {}
        w:sepStrip(rights, res, nil, nil)
        local offered = K.hasRight(rights, "smoveup")
        w:sepMoveItUp()
        local moved = (w.oSec.zqa4 or 0) == 0 and w:orderIndexOf("zqa4") < w:orderIndexOf("zqa2") and w:orderCheck().nBad == 0
        local I2, ids2 = K.fake(5)
        I2.zqa2.req = { "zqa4" }
        I2.zqa4.req = { "zqa5" }
        local lo2 = K.lo()
        lo2.top, lo2.seps = { "zqa1" }, { K.sep("QA A", { "zqa2", "zqa3" }), K.sep("QA B", { "zqa4" }), K.sep("QA C", { "zqa5" }) }
        K.stage(w, ids2, I2, lo2)
        local presses = 0
        while presses < 5 and w:sepCrossNeed() do w:sepMoveItUp(); presses = presses + 1 end
        local clear = w:orderCheck().nBad == 0
        check(red and who == "zqa2" and need == "zqa4" and offered and moved and presses == 2 and clear,
            "MO31: a red row across separators offers Move it up (the needed mod to the end of the section above); a chain needs one press per link; Done stays greyed while red",
            "red " .. K.b(red) .. ", " .. tostring(who) .. " needs " .. tostring(need) .. ", offered " .. K.b(offered) .. ", moved " .. K.b(moved) .. ", a chain of two took " .. presses .. " presses")
    end))
    after(200, P(function(w)
        local I, ids = K.fake(5)
        I.zqa2.req = { "zqa4" }
        local lo = K.lo()
        lo.top, lo.seps = { "zqa1" }, { K.sep("QA Needs", { "zqa2", "zqa3" }), K.sep("QA Needed", { "zqa4", "zqa5" }) }
        K.stage(w, ids, I, lo)
        local sec0 = tostring(w.oSec.zqa2) .. ":" .. tostring(w.oSec.zqa4)
        w:autoSort()
        local stillRed = w:orderCheck().nBad > 0 and (tostring(w.oSec.zqa2) .. ":" .. tostring(w.oSec.zqa4)) == sec0
        check(stillRed, "MO32: Auto never moves a mod across a separator: the red row stays red", "red rows after Auto " .. w:orderCheck().nBad)
        w.note = nil
        if w:orderCheck().firstBad then w:orderDone() end
        local said = K.noteText(w)
        -- (and where Auto can clear it, in one section, the refusal still offers Auto)
        local I2 = K.fake(2)
        I2.zqa2.req = { "zqa1" }
        K.stage(w, { "zqa2", "zqa1" }, I2, nil)
        w.order = { "zqa2", "zqa1" }
        w:orderChanged()
        w.note = nil
        local red2 = w:orderCheck().firstBad ~= nil
        if red2 then w:orderDone() end
        local said2 = K.noteText(w)
        check(w.page == "order" and said == ZeD.tr("UI_ZeD_Mods_RuleFixHand") and not string.find(string.lower(said), "auto", 1, true)
            and (not red2 or said2 == ZeD.tr("UI_ZeD_Mods_RuleFix")),
            "MO32: Done refused on a red row across separators does not send the player to Auto, which cannot fix it (one Auto can fix still names Auto)",
            "page " .. tostring(w.page) .. "; across separators the band says: " .. said .. "; in one section (red " .. K.b(red2) .. "): " .. said2)
    end))
    after(200, P(function(w)
        K.file({ "version=2", "next=3", "folder=1|1|" .. F.encode("Fold A"), "folder=2|1|" .. F.encode("Fold B"),
                 "member=" .. F.encode("zqa5") .. "|1", "member=" .. F.encode("zqa6") .. "|1", "member=" .. F.encode("zqa2") .. "|2" })
        K.keepColor(1)
        F.setLabel(1, "blue")
        ZeD_MMMods.setFolderColor(1, "red")
        local helper = O.helperId()
        local I, ids = K.fake(7)
        ids[#ids + 1] = helper
        I[helper] = K.fakeOne(helper, "ZeD picks")
        local lo = K.lo()
        lo.first = { "zqa1" }
        K.stage(w, ids, I, lo)
        w:sepFromFolders(false)
        local seps = w.oLo.seps
        local names = {}
        for _, sp in ipairs(seps) do names[#names + 1] = sp.name end
        local namesOk = K.join(names) == "Fold A;Fold B;" .. ZeD.tr("UI_ZeD_Folders_Unfiled")
        local want = "zqa1;zqa5;zqa6;zqa2;zqa3;zqa4;zqa7;" .. helper
        local got = K.join(w.order)
        keep.m34ord = got == want
        local pins = w.oZone.zqa1 == 1 and w.oZone[helper] == 4 and #w.oLo.top == 0
        local lab = seps[1] ~= nil and seps[1].label == "blue" and seps[1].color == nil
        w.oOffHere = { zqa_held = "kept" }
        w:sepFromFolders(false)
        local asked = w.confirm == "sreplace"
        w:sepFromFolders(true)
        local forgot = w.oOffHere.zqa_held == nil and not w.confirm
        w:orderUndo()
        local undone = w.oOffHere.zqa_held == "kept" and #w.oLo.seps == 3
        check(namesOk and keep.m34ord and pins and asked and forgot and undone,
            "MO34: Start separators from folders: one per folder with mods on, in the folders' order, Unfiled after the sections whose first mod loaded before the first unfiled one; pins and ZeD picks stay; with separators it asks; the old dimmed mods are forgotten until Undo",
            "separators " .. K.join(names) .. "; order " .. got .. "; pins kept " .. K.b(pins) .. ", asked " .. K.b(asked) .. ", forgot " .. K.b(forgot) .. ", Undo " .. K.b(undone))
        local help = ZeD.tr("UI_ZeD_Seps_HelpFromFolders")
        check(keep.m34ord and not string.find(string.lower(help), "sorted", 1, true), "MO33: Start separators from folders' help says what it does (each section keeps its own order)",
            "each section kept its order " .. K.b(keep.m34ord) .. "; the help says: " .. help)
        note("MO6: one folder holds Label blue (ZeD_modfolders.txt: the folder picture) and Color red (ZeD_folder_colors.txt: the rows) at once: label " .. tostring(F.labelOf(1))
            .. ", color " .. tostring(ZeD_MMMods.folderColorKey(1)) .. "; Start separators from folders carried the label only (" .. K.b(lab) .. "); the label's help: "
            .. ZeD.tr("UI_ZeD_Mods_HelpLabel", "Blue"))
        K.putColor(1)
    end))
    after(200, P(function(w)
        local before = keep.liteVal
        if before == nil then note("MO35: Style could not be read, so Lite was not set (nothing changed)"); return end
        pcall(function() St.lookStyleOption:setValue(2) end)
        local lite = St.lite()
        local fOn = w:foldersOn()
        local I, ids = K.fake(4)
        K.stage(w, ids, I, nil)
        local rights = {}
        w:sepStrip(rights, w:orderCheck(), nil, nil)
        local offer = K.hasRight(rights, "sfolders")
        pcall(function() St.lookStyleOption:setValue(before) end)
        note("MO35: in Lite (read " .. K.b(lite) .. ") the Mods list shows no folders (foldersOn " .. K.b(fOn) .. "), yet the load order page offers Start separators from folders ("
            .. K.b(offer) .. ") while ModFolders.cfg holds " .. #F.folders() .. " folders Lite never shows; Style put back: " .. K.b(St.lookStyleOption:getValue() == before))
        K.file({})
    end))
    after(200, P(function(w)
        local I, ids = K.fake(4)
        local A = K.sep("QA Keep", { "zqa2", "ZeDQA_gone_x", "zqa3" })
        local lo = K.lo()
        lo.top, lo.seps = { "zqa1" }, { A }
        K.stage(w, ids, I, lo)
        w:orderSelectAt(2, false)
        w:move(1)
        w:autoSort()
        w:orderLayout(false)
        local sp = w:sepGet(A.uid)
        local kept = sp ~= nil and K.idx(sp.ids, "ZeDQA_gone_x") ~= nil
        w:sepSelect(A.uid)
        local want = ZeD.tr("UI_ZeD_Seps_DetMissing", "ZeDQA_gone_x")
        local line = false
        for _, it in ipairs(w:orderDetailModel(600).items) do
            for _, l in ipairs(it.lines or {}) do if l == want then line = true end end
        end
        note("MO36: a separator keeps a mod that is not installed in its list through a move, Auto and a layout (" .. K.b(kept) .. "); its pane lists \"" .. want .. "\" ("
            .. K.b(line) .. "); nothing removes it")
    end))
    after(200, P(function(w)
        local I, ids = K.fake(3)
        local A = K.sep("QA Label", { "zqa2", "zqa3" })
        local lo = K.lo()
        lo.top, lo.seps = { "zqa1" }, { A }
        K.stage(w, ids, I, lo)
        w:sepSetLabel(A.uid, "green")
        local set = w:sepGet(A.uid).label == "green"
        local cols = w:labelColor("green") ~= nil and w:labelColor("green", true) ~= nil
        w:orderUndo()
        local undone = w:sepGet(A.uid) ~= nil and w:sepGet(A.uid).label == nil
        check(set and cols and undone and keep.m37file and keep.m37back, "MO37: a separator's label is set from its pane, drawn in the label's colors, saved as \"|<label>\" and undoable",
            "set " .. K.b(set) .. ", colors " .. K.b(cols) .. ", Undo " .. K.b(undone) .. ", the file line " .. tostring(keep.m37want) .. " " .. K.b(keep.m37file) .. ", the file put back " .. K.b(keep.m37back))
        K.errCheck("separators")
    end))
end
function X.fakeOrder()
    after(200, P(function(w)
        local I, ids = K.fake(4)
        I.zqa2.req = { "ZeDQA_absent" }
        K.stage(w, ids, I, nil)
    end))
    after(400, P(function(w)
        local res = w:orderCheck()
        local v = w:orderView()
        local k = v.byPlace[w:orderIndexOf("zqa2") or 0]
        local e = k and v.ents[k]
        local ds = K.spec(w, "done")
        check(res.firstBad ~= nil and ds ~= nil and ds.disabled == true, "MO43: a mod whose requirement is not installed is red for good and Done stays greyed",
            "red rows " .. res.nBad .. ", Done greyed " .. K.b(ds and ds.disabled))
        if e and e.hint then
            local nm = "ZeDQA_absent"
            pcall(function() nm = O.nameOf(K.model(), w.oInfo, "ZeDQA_absent") end)
            local want = ZeD.tr("UI_ZeD_Order_HintNeedsMissing", nm)
            check(e.hint == want and e.hint ~= ZeD.tr("UI_ZeD_Order_HintNeedsOff", nm), "MO43: the red reason tells a requirement that is not installed from one that is off",
                "it reads \"" .. tostring(e.hint) .. "\" (want \"" .. want .. "\")")
        else
            skip("MO43: the red reason's words", "the row was not drawn in time")
        end
    end))
    after(200, P(function(w)
        local helper = O.helperId()
        local I, ids = K.fake(6)
        ids[#ids + 1] = helper
        I[helper] = K.fakeOne(helper, "ZeD picks")
        I.zqa1.req = { "zqa2" }
        local bad = {}
        local lo = K.lo()
        lo.first = { "zqa1" }
        K.stage(w, ids, I, lo)
        w.note = nil
        w:orderSelect("zqa1", false)
        w:move(1)
        if not (O.pinOf(w.oLo, "zqa1") == nil and K.noteText(w) == ZeD.tr("UI_ZeD_Order_SayUnpinnedFirst", "QA Mod 1")) then bad[#bad + 1] = "a pinned row out of its block: " .. K.noteText(w) end
        lo = K.lo()
        lo.first = { "zqa1" }
        K.stage(w, ids, I, lo)
        local ord0 = K.join(w.order)
        w.note = nil
        w:orderMoveTo(w:orderIndexOf("zqa2"), w:orderIndexOf("zqa4"))
        if not (K.join(w.order) == ord0 and w.oCarried.zqa2 and K.noteText(w) == ZeD.tr("UI_ZeD_Order_SayCarriedStays", "QA Mod 2")) then bad[#bad + 1] = "a carried row: " .. K.noteText(w) end
        w.note = nil
        w:orderSelect("zqa6", false)
        w:move(1)
        if not (K.join(w.order) == ord0 and K.noteText(w) == ZeD.tr("UI_ZeD_Order_SayHelperFixed")) then bad[#bad + 1] = "ZeD picks: " .. K.noteText(w) end
        O.addRule(w.oLo, "zqa4", "after", "zqa3")
        w:orderLayout(false)
        w.note = nil
        w:orderSelect("zqa4", false)
        w:move(-1)
        if not (#w.oLo.rules == 0 and K.noteText(w) == ZeD.tr("UI_ZeD_Order_SayRuleGoneAfter", "QA Mod 3")) then bad[#bad + 1] = "a move past a rule: " .. #w.oLo.rules .. " rules, " .. K.noteText(w) end
        check(#bad == 0, "MO45: a pinned row moved out of its block unpins; a carried row can't leave; ZeD picks never moves; a move past a rule's other mod removes the rule with a note", K.short(bad))
    end))
    after(200, P(function(w)
        local bad = {}
        local I, ids = K.fake(6)
        I.zqa3.req = { "zqa2" }
        local lo = K.lo()
        lo.first, lo.last = { "zqa1" }, { "zqa6" }
        lo.rules = { { id = "zqa4", how = "after", other = "zqa5" }, { id = "zqa5", how = "after", other = "zqa2" } }
        K.stage(w, ids, I, lo)
        local function why(x, how, y, want, label)
            w:orderSelect(x, false)
            w:openPicker(how)
            local _, short = w:pickWhy(y)
            w:closePicker(true)
            if short ~= ZeD.tr(want) then bad[#bad + 1] = label .. ": " .. tostring(short) end
        end
        why("zqa2", "after", "zqa3", "UI_ZeD_Order_ShortNeedsIt", "a mod that needs it")
        why("zqa3", "before", "zqa2", "UI_ZeD_Order_ShortNeeded", "a mod it needs")
        why("zqa2", "after", "zqa4", "UI_ZeD_Order_ShortCircle", "a circle")
        why("zqa4", "after", "zqa6", "UI_ZeD_Order_ShortPinned", "a pinned block")
        w:orderSelect("zqa3", false)
        w:openPicker("after")
        w:pickChoose("zqa4", true)
        local r1 = false
        for _, r in ipairs(w.oLo.rules) do if r.id == "zqa3" and r.how == "after" and r.other == "zqa4" then r1 = true end end
        if not (w.pick == nil and r1 and w:orderIndexOf("zqa3") > w:orderIndexOf("zqa4")) then bad[#bad + 1] = "a choice confirmed at once (what a double-click calls)" end
        w:orderSelect("zqa5", false)
        w:openPicker("before")
        if w.pfind:isFocused() then w.pfind:unfocus() end
        w:pickChoose("zqa6", false)
        w.focusId = "orow:1"
        if w.pick and w.pick.sel == "zqa6" then w:orderKey(Keyboard.KEY_RETURN) end
        local r2 = false
        for _, r in ipairs(w.oLo.rules) do if r.id == "zqa5" and r.how == "before" and r.other == "zqa6" then r2 = true end end
        if not (w.pick == nil and r2) then bad[#bad + 1] = "Return" end
        if w:orderIndexOf("zqa5") ~= w:orderIndexOf("zqa6") - 1 then bad[#bad + 1] = "toward another block: not at its block's edge" end
        if w.pick then w:closePicker(true) end
        keep.bad46 = bad
    end))
    after(200, P(function(w)
        local bad = keep.bad46 or {}
        local I, ids = K.fake(5)
        local A, B = K.sep("QA A", { "zqa2", "zqa3" }), K.sep("QA B", { "zqa4", "zqa5" })
        local lo = K.lo()
        lo.top, lo.seps = { "zqa1" }, { A, B }
        K.stage(w, ids, I, lo)
        w:orderSelect("zqa5", false)
        w:openPicker("before")
        w:pickChoose("zqa2", true)
        if not (w.oSec.zqa5 == A.uid and w:orderIndexOf("zqa5") == w:orderIndexOf("zqa2") - 1) then bad[#bad + 1] = "with separators: not in the other's section" end
        if w.pick then w:closePicker(true) end
        check(#bad == 0, "MO46: the picker greys needs, circles and pinned blocks with their reasons; a choice confirms at once or on Return; a rule toward another block moves the mod to its block's edge; with separators the mod joins the other's section",
            K.short(bad))
    end))
    after(200, P(function(w)
        local I, ids = K.fake(4)
        I.zqa2.after = { "zqa3" }
        local lo = K.lo()
        lo.top, lo.seps = { "zqa1" }, { K.sep("QA Early", { "zqa2" }), K.sep("QA Late", { "zqa3", "zqa4" }) }
        K.stage(w, ids, I, lo)
        local s1 = w:orderCheck().st[w:orderIndexOf("zqa2")]
        w:autoSort()
        local s2 = w:orderCheck().st[w:orderIndexOf("zqa2")]
        note("MO48: a load-after wish on a mod under an earlier separator stays yellow (" .. tostring(s1) .. ", after Auto " .. tostring(s2)
            .. "): Auto sorts inside each section only, and a section is not an override")
    end))
    after(200, P(function(w)
        local I, ids = K.fake(6)
        K.stage(w, ids, I, nil)
        w:orderSelectAt(2, false)
        for n = 1, 36 do
            if n == math.floor(n / 2) * 2 then w:move(-1) else w:move(1) end
        end
        keep.n49 = #(w.oUndo or {})
    end))
    after(350, P(function(w)
        keep.u49a = K.spec(w, "undo") ~= nil
        w.oUndo = {}
    end))
    after(350, P(function(w)
        local gone = K.spec(w, "undo") == nil
        check(keep.n49 == 30 and keep.u49a and gone, "MO49: Undo keeps 30 steps; its button shows only while there is a step",
            "36 moves kept " .. tostring(keep.n49) .. " steps; the button with steps " .. K.b(keep.u49a) .. ", gone with none " .. K.b(gone))
        note("MO49: each step putting the on set back is checked live under MO25; Ctrl+Z (a held key) is by hand")
    end))
    after(200, P(function(w)
        local I, ids = K.fake(8)
        I.zqa4.name = "QA Find Four"
        I.zqa4.hay = "qa find four zqa4 987654321"
        K.stage(w, ids, I, nil)
        w.find:setText("987654321")
        local v = w:orderView()
        local rows, gaps, num = 0, 0, nil
        for _, e in ipairs(v.ents) do
            if e.k == "row" then rows = rows + 1; num = e.num
            elseif e.k == "gap" then gaps = gaps + (tonumber(string.match(e.text, "%d+")) or 0) end
        end
        keep.m50a = rows == 1 and num == "4" and gaps == 7 and v.countText == ZeD.tr("UI_ZeD_Order_FindCount", 1, 8)
        w.find:setText("qa find four")
        local n1 = w:orderView().nMatch
        w.find:setText("zqa4")
        local n2 = w:orderView().nMatch
        keep.m50b = n1 == 1 and n2 == 1
        keep.m50d = rows .. " row (number " .. tostring(num) .. "), " .. gaps .. " in the gaps, " .. tostring(v.countText) .. "; by name " .. tostring(n1) .. ", by id " .. tostring(n2)
        w.find:setText("987654321")
        w:orderView()
    end))
    after(350, P(function(w)
        local v = w:orderView()
        local k = v.byPlace[4]
        local e = k and v.ents[k]
        local dragOff = nil
        if e and e.hit and e.hit.drag then w._drag = nil; e.hit.drag(0, 0); dragOff = w._drag == nil; w._drag = nil end
        w.oSel, w.focusId = 4, "orow:4"
        w:orderView()
        w:orderJoyA()
        local aOk = (w.find:getInternalText() or "") == "" and w.oSel == 4
        w.find:setText("987654321")
        w:orderView()
        w._oClick, w.oSel = nil, 4
        w:clickOrderRow(4)
        w:clickOrderRow(4)
        local dbl = (w.find:getInternalText() or "") == ""
        w.find:setText("987654321")
        local rOk = false
        if w:orderView().q ~= "" then
            if w.find:isFocused() then w.find:unfocus() end
            w:orderKey(Keyboard.KEY_RETURN)
            rOk = (w.find:getInternalText() or "") == "" and w.page == "order"
        end
        w.find:setText("987654321")
        w:orderEscape()
        local esc = (w.find:getInternalText() or "") == "" and w.page == "order"
        check(keep.m50a and keep.m50b and dragOff == true and aOk and dbl and rOk and esc,
            "MO50: Find matches name, id or Workshop number with real numbers and \"n more\" gaps; A, a double-click and Return show the match in the full list; Escape clears; drag is off while Find has text",
            tostring(keep.m50d) .. "; drag off " .. tostring(dragOff) .. ", A " .. K.b(aOk) .. ", double-click " .. K.b(dbl) .. ", Return " .. K.b(rOk) .. ", Escape " .. K.b(esc))
    end))
    after(250, P(function(w)
        K.fakeOff(w)
        keep.fakeOk = false
        w.find:setText("")
        if w.pick then w:closePicker(true) end
        if w.confirm then w:setConfirm(false) end
        K.try("the load order page left (Back)", function() w:leaveOrder(false) end)
        check(w.page == "list" and K.activeIds() == keep.ids0 and K.onSet() == keep.on0 and (keep.blocked or 0) == 0,
            "the load order page with made-up mods left: the mods in use and their order untouched, nothing kept",
            "page " .. tostring(w.page) .. ", Done held off " .. tostring(keep.blocked or 0) .. " times")
        K.errCheck("the load order page with made-up mods")
    end))
end

-- =========================================================================================================
-- 7: the load order page with the mods in use (no mod turned on or off): Back, Done
function X.realBack()
    -- MO40 (the director's pick, Nov 27): with no move B leaves as before; after a move B and Escape ask "Keep the new
    -- order?" (Keep, Discard changes, Cancel), the pad on Cancel. Cancel stays; Discard changes leaves as Back did.
    -- Keep is never pressed (it writes the order).
    after(250, M(function(w)
        if w.page ~= "list" then K.fakeOff(w); w:leaveOrder(false) end
        keep.m40 = nil
        K.try("the load order page opened", function() w:enterOrder("order") end)
        if w.page ~= "order" then check(false, "MO40: the load order page opens", tostring(w.page)); return end
        K.clean(w)
        w:joyB()
        check(w.page == "list" and not w.confirm and K.activeIds() == keep.ids0, "MO40: with no move B leaves the load order page with no question",
            "page " .. tostring(w.page) .. ", question " .. tostring(w.confirm))
        if w.page ~= "list" then if w.confirm then w:setConfirm(false) end; w:leaveOrder(false) end
        K.try("the load order page opened again", function() w:enterOrder("order") end)
        if w.page ~= "order" then return end
        K.clean(w)
        if #w.order >= 2 then w:orderSelectAt(1, false); w:move(1) end
        if not w:orderMoved() then
            skip("MO40: Keep the new order? after a move", "fewer than two mods in use: no move to make")
            w:leaveOrder(false)
            return
        end
        w:joyB()
        keep.m40 = { page = w.page, c = w.confirm, f = w.focusId }
    end))
    after(250, M(function(w)
        local r = keep.m40
        if not r then return end
        check(r.page == "order" and r.c == "orderkeep", "MO40: after a move B asks Keep the new order? and stays on the page",
            "page " .. tostring(r.page) .. ", question " .. tostring(r.c))
        check(r.f == "confirm:no", "MO40: the question lands the pad on Cancel", "the pad on " .. tostring(r.f))
        local yes, dis, no = K.spec(w, "confirm:yes"), K.spec(w, "confirm:discard"), K.spec(w, "confirm:no")
        check(tostring(w._bandAsk) == ZeD.tr("UI_ZeD_Order_AskKeep") and yes ~= nil and yes.text == getText("ContextMenu_Keep") and dis ~= nil
            and no ~= nil and no.text == ZeD.btnCase(getText("UI_btn_cancel")) and no.text ~= string.upper(no.text), "MO40: the question's words and its answers (Keep, Discard changes, Cancel, in sentence case)",
            "the band says \"" .. tostring(w._bandAsk) .. "\"; " .. tostring(yes and yes.text) .. ", " .. tostring(dis and dis.text) .. ", " .. tostring(no and no.text))
        -- Cancel, once: the page and the move stay
        local why = "no question open"
        if w.confirm == "orderkeep" then why = K.press(w, "confirm:no") end
        check(why == nil and w.page == "order" and not w.confirm and w:orderMoved(), "MO40: Cancel stays on the page with the move",
            tostring(why) .. "; page " .. tostring(w.page) .. ", question " .. tostring(w.confirm))
        -- Escape asks the same (with Find empty and no picker up, Escape is the page's way out)
        local plain = (w.find:getInternalText() or "") == "" and not w.find:isFocused() and not w.pick
        if w.page == "order" and plain then w:keyEscape() end
        r.e = { page = w.page, c = w.confirm, f = w.focusId, plain = plain }
    end))
    after(250, M(function(w)
        local r = keep.m40
        if not (r and r.e) then return end
        check(r.e.plain and r.e.page == "order" and r.e.c == "orderkeep" and r.e.f == "confirm:no", "MO40: Escape after a move asks too, the pad on Cancel",
            "page " .. tostring(r.e.page) .. ", question " .. tostring(r.e.c) .. ", the pad on " .. tostring(r.e.f))
        -- Discard changes: the page left as Back did, the order in use untouched (never Keep: it writes the order)
        local why = "no question open"
        if w.confirm == "orderkeep" then why = K.press(w, "confirm:discard") end
        check(why == nil and w.page == "list" and not w.confirm and K.activeIds() == keep.ids0 and MM.view == "mods",
            "MO40: Discard changes leaves the load order page, the order in use as it was",
            tostring(why) .. "; page " .. tostring(w.page) .. ", question " .. tostring(w.confirm) .. ", view " .. tostring(MM.view))
        if w.page ~= "list" then if w.confirm then w:setConfirm(false) end; w:leaveOrder(false) end
        keep.m40 = nil
    end))
    after(250, M(function(w)
        K.try("the load order page opened", function() w:enterOrder("order") end)
        if w.page ~= "order" then check(false, "MO42: the load order page opens", tostring(w.page)); return end
        K.clean(w)
        local helper = O.helperId()
        local first, n = nil, 0
        for _, id in ipairs(w.order) do if id ~= helper then n = n + 1; first = first or id end end
        if n >= 2 then w:orderSelect(first, false); w:orderPin("last") end
        if w:orderCheck().firstBad then
            skip("MO42: Done, then the Mods page's Back", "the list in use has a red row: Done refuses")
            w:leaveOrder(false)
            return
        end
        local shown = K.join(w.order)
        K.try("MO42: Done", function() w:orderDone() end)
        local saved = w.page == "list" and K.activeIds() == shown
        local why = K.backReloads(w)
        note("MO42: after Done (the order " .. (shown ~= keep.ids0 and "changed" or "as it was") .. ", in the list in memory: " .. K.b(saved) .. ") nothing counts as a change (changed() "
            .. tostring(w:changed()) .. "), so the Mods page's Back runs Accept with no question and writes mods/default.txt" .. (why and ("; here it would also reload Lua (" .. why .. ")") or "")
            .. ". Back was not pressed")
        if w.page ~= "list" then w:leaveOrder(false) end
        w:saveOrder(keep.idsList0)
        K.restoreFile("ZeD_modprofiles.txt")
        K.restoreFile("ZeD_modprofiles_spare.txt")
        O.load()
        check(K.activeIds() == keep.ids0 and K.asFound("ZeD_modprofiles.txt"),
            "MO42: the order and the profile file put back after Done (nothing accepted)", K.activeIds())
        K.errCheck("the load order page: Back and Done")
    end))
end

-- 8: the load order page with installed mods turned on (Undo changes after)
function X.realLive()
    after(250, M(function(w)
        if w.page ~= "list" then w:leaveOrder(false) end
        local c = keep.c
        local ids = K.copy(c.free)
        if c.pair then ids[#ids + 1] = c.pair.child end
        if #ids == 0 then keep.noReal = true; return end
        K.try("installed mods turned on for the live checks", function() w:modsOnBatch(ids) end)
        w:dirty()
        local m = K.model()
        keep.free2 = {}
        for _, id in ipairs(c.free) do if m.mods[id] and m.mods[id].isActive then keep.free2[#keep.free2 + 1] = id end end
        keep.pairOn = c.pair ~= nil and m.mods[c.pair.child].isActive and m.mods[c.pair.parent].isActive
        say("live checks: on now " .. K.join(keep.free2) .. (keep.pairOn and (", " .. c.pair.child .. " with " .. c.pair.parent) or ""))
    end))
    after(250, M(function(w)
        local helper = O.helperId()
        local ids = K.activeList()
        local pick, n = nil, 0
        for _, id in ipairs(ids) do if id ~= helper then n = n + 1; pick = pick or id end end
        if n < 2 then skip("MO39: opening the page lays the order out with the stored pins", "fewer than two mods on"); return end
        local lo = K.lo()
        lo.last = { pick }
        O.putLo(keep.key, lo, false)
        local game0 = K.activeIds()
        K.try("the load order page opened", function() w:enterOrder("order") end)
        local shown = K.join(w.order)
        local pinned = w.oZone[pick] == 3
        w:leaveOrder(false)
        local backOk = w.page == "list" and K.activeIds() == game0
        O.putLo(keep.key, keep.lo0, false)
        check(pinned and shown ~= game0 and backOk, "MO39: opening the load order page lays the order out with the stored pins (it differs from the game's before any change); Back leaves the game's order",
            "pinned last " .. K.b(pinned) .. ", shown differs " .. K.b(shown ~= game0) .. ", Back left the game's " .. K.b(backOk))
    end))
    after(250, M(function(w)
        if not keep.pairOn then skip("MO44: the saved order is the shown order, with a pinned-last requirement carried", "no installed pair here (a mod and the one it needs, both off and able to run)"); return end
        local p, c = keep.c.pair.parent, keep.c.pair.child
        K.try("the load order page opened", function() w:enterOrder("order") end)
        K.clean(w)
        w:orderSelect(p, false)
        w:orderPin("last")
        local carried = w.oCarried[c] == true and w.oZone[c] == 3 and w:orderIndexOf(c) > w:orderIndexOf(p)
        if w:orderCheck().firstBad then
            skip("MO44: the saved order is the shown order", "the list in use has a red row: Done refuses")
            w:leaveOrder(false)
            return
        end
        local m = K.model()
        local shown = {}
        for _, id in ipairs(w.order) do if m.mods[id] then shown[#shown + 1] = id end end
        K.try("MO44: Done", function() w:orderDone() end)
        local same = w.page == "list" and K.activeIds() == K.join(shown)
        check(carried and same, "MO44: the saved order is the shown order (a pinned-last requirement carries the mod that needs it)",
            "carried " .. K.b(carried) .. ", saved as shown " .. K.b(same) .. ": " .. K.activeIds())
        if w.page ~= "list" then w:leaveOrder(false) end
        K.restoreFile("ZeD_modprofiles.txt")
        K.restoreFile("ZeD_modprofiles_spare.txt")
        O.load()
    end))
    after(250, M(function(w)
        if #(keep.free2 or {}) < 2 then skip("MO25: a separator's box turns its mods off and on in place", "fewer than two installed mods here that are off and can run"); return end
        local fa, fb = keep.free2[1], keep.free2[2]
        K.try("the load order page opened", function() w:enterOrder("order") end)
        K.realSeps(w, { { "QA Box", { fa, fb } } })
        local sp = w.oLo.seps[1]
        local n0 = #w.order
        local m = K.model()
        w.note = nil
        w:sepBox(sp.uid)
        local off = not m.mods[fa].isActive and not m.mods[fb].isActive and sp.on == false and #w.order == n0 - 2
        local held = 0
        for _, e in ipairs(w:orderView().ents) do if e.k == "held" and e.uid == sp.uid then held = held + 1 end end
        w:sepBox(sp.uid)
        local back = m.mods[fa].isActive and m.mods[fb].isActive and K.join(K.under(w, sp.uid)) == fa .. ";" .. fb
        w:sepBox(sp.uid)
        w:orderUndo()
        local undo = m.mods[fa].isActive and m.mods[fb].isActive
        check(off and held == 2 and back and undo, "MO25: a separator's box off turns its mods off, dimmed in place with the numbers closing up; on brings the same set back in place; Undo puts the on set back",
            "off " .. K.b(off) .. ", dimmed rows " .. held .. ", back in place " .. K.b(back) .. ", Undo " .. K.b(undo))
        w:leaveOrder(false)
    end))
    after(250, M(function(w)
        if not keep.pairOn then skip("MO26: a mod elsewhere that needs one under the separator goes off too", "no installed pair here"); return end
        local p, c = keep.c.pair.parent, keep.c.pair.child
        K.try("the load order page opened", function() w:enterOrder("order") end)
        K.realSeps(w, { { "QA Parent", { p } }, { "QA Child", { c } } })
        local sp = w.oLo.seps[1]
        local m = K.model()
        w.note = nil
        w:sepBox(sp.uid)
        local cOff = not m.mods[c].isActive
        local why = w.oOffHere[c]
        local whyOk = why == ZeD.tr("UI_ZeD_Seps_WhyNeeds", O.nameOf(m, w._infoAll, p))
        local named = string.find(K.noteText(w), tostring(m.mods[c].name), 1, true) ~= nil
        w:orderUndo()
        local back = m.mods[c].isActive and m.mods[p].isActive
        check(cOff and whyOk and named and back, "MO26: a mod elsewhere that needed one under the separator goes off too, reads \"Off: needs ...\" and is named in the band",
            "off " .. K.b(cOff) .. " (" .. tostring(why) .. "), named " .. K.b(named) .. ", Undo " .. K.b(back) .. "; the band: " .. K.noteText(w))
        w:leaveOrder(false)
    end))
    after(250, M(function(w)
        local fa = (keep.free2 or {})[1]
        if not fa then skip("MO27: a mod landing under a separator that is off turns off", "no installed mod here that is off and can run"); return end
        K.try("the load order page opened", function() w:enterOrder("order") end)
        K.realSeps(w, { { "QA On", { fa } }, { "QA Off", {}, false } })
        local off = w.oLo.seps[2]
        local m = K.model()
        w.note = nil
        w:sepMoveModTo(fa, off.uid)
        local landed = not m.mods[fa].isActive and K.noteText(w) == ZeD.tr("UI_ZeD_Seps_SayLandedOff", O.nameOf(m, w._infoAll, fa), "QA Off")
        w:orderUndo()
        local back = m.mods[fa].isActive
        check(landed and back, "MO27: a mod moved under a separator that is off turns off, with a note; Undo turns it back on", "off " .. K.b(landed) .. ", Undo " .. K.b(back) .. "; the band: " .. K.noteText(w))
        w:leaveOrder(false)
    end))
    after(250, M(function(w)
        local bad = keep.c.bad
        local fa = (keep.free2 or {})[1]
        if not (bad and fa) then skip("MO38: Turn on for a dimmed mod that cannot run", "no installed mod here that cannot run (or none to sit beside it)"); return end
        K.try("the load order page opened", function() w:enterOrder("order") end)
        K.realSeps(w, { { "QA Held", { fa, bad } } })
        w.oOffHere[bad] = ZeD.tr("UI_ZeD_Seps_WhyOff")
        w:orderChanged()
        local n0, v0 = #(w.oUndo or {}), w.oVer
        local ord0 = K.join(w.order)
        K.try("MO38: Turn on", function() w:heldTurnOn(bad) end)
        local n1, v1 = #(w.oUndo or {}), w.oVer
        check(not (v1 ~= v0 and n1 == n0), "MO38: Turn on for a dimmed mod that cannot run keeps an Undo step for the layout it made",
            "the order was laid out again (change " .. tostring(v0) .. " to " .. tostring(v1) .. ", the order " .. ((K.join(w.order) == ord0) and "the same" or "different")
            .. ") and its Undo step was dropped (" .. n0 .. " steps before, " .. n1 .. " after); the band: " .. K.noteText(w))
        w:leaveOrder(false)
    end))
    after(300, M(function(w)
        if w.page ~= "list" then w:leaveOrder(false) end
        if w:changed() then K.try("Undo changes", function() w:revert() end) end
        if K.activeIds() ~= keep.ids0 then w:saveOrder(keep.idsList0) end
        O.putLo(keep.key, keep.lo0, false)
        check(K.onSet() == keep.on0 and K.activeIds() == keep.ids0 and not w:changed(), "the live checks' mods off again (Undo changes): the mods in use and their order as found",
            "changed " .. tostring(w:changed()))
        K.errCheck("the load order page, live")
    end))
end

-- =========================================================================================================
-- 9: the map order page
function X.maps()
    after(300, M(function(w)
        if w.page ~= "list" then w:leaveOrder(false) end
        w:dirty()
    end))
    after(500, M(function(w)
        local clash = false
        pcall(function() clash = K.model():checkMapConflicts() and true or false end)
        local shown = K.spec(w, "maps") ~= nil
        check(shown == clash, "MO52: the Map order button follows the map clash test", "clash " .. K.b(clash) .. ", button " .. (shown and "shown" or "hidden"))
        note("MO52: the Map order button is " .. (shown and "shown" or "hidden") .. " now: ZeD hides it unless two map mods share cells (the test kept a second), where the game shows it greyed; two clashing map mods are not staged here")
        K.try("the map order page opened", function() w:enterOrder("maps") end)
        if w.page ~= "maps" then check(false, "MO55: the map order page opens", tostring(w.page)); keep.noMaps = true; return end
        local n = #w.order
        local function look()
            local t = { title = nil, up = nil, down = nil, extra = nil, rule = false, shares = false }
            for _, it in ipairs(w:orderDetailModel(400).items) do
                if it.t == "title" then t.title = it.text end
                if it.t == "btns" then
                    for _, b in ipairs(it.list) do
                        if b.id == "up" then t.up = b elseif b.id == "down" then t.down = b else t.extra = b.id end
                    end
                end
                if it.t == "text" and it.lines and it.lines[1] then
                    local l1 = it.lines[1]
                    if string.sub(ZeD.tr("UI_ZeD_Mods_MapRule"), 1, #l1) == l1 then t.rule = true end
                    if string.sub(ZeD.tr("UI_ZeD_Mods_MapShares", ""), 1, 8) == string.sub(l1, 1, 8) then t.shares = true end
                end
            end
            return t
        end
        if n == 0 then
            -- (the game's own map order reads the same model call, ModSelector.Model:getAllMapsInOrder, which builds
            -- its groups with includeVanilla false: with no map mod on, the game's list is empty too, so an empty
            -- page here is the staging, not ZeD's)
            local game = -1
            pcall(function() game = K.model():getAllMapsInOrder():size() end)
            if game == 0 then skip("MO55: the map order page lists the maps and its pane", "no map mod is on in this run: the game's own map order list is empty too (getAllMapsInOrder, vanilla maps left out)")
            else check(false, "MO55: the map order page lists the maps", "no map in the list, while the game's model lists " .. tostring(game)) end
            return
        end
        w.oSel = 1
        local a = look()
        local conf = {}
        pcall(function() conf = K.jlist(K.model():getMapConflicts(w.order[1])) end)
        w.oSel = n
        local z = look()
        w.oSel = 1
        check(a.title == w.order[1] and a.up ~= nil and a.up.disabled == true and z.down ~= nil and z.down.disabled == true and a.rule and a.shares == (#conf > 0) and a.extra == nil,
            "MO55: the map's pane: its folder name, Move up and Move down (greyed at the ends), the maps it shares cells with, the rule line; no Help as in the game's",
            n .. " maps; " .. tostring(a.title) .. ", shares " .. #conf .. ", rule " .. K.b(a.rule) .. ", other buttons " .. tostring(a.extra))
    end))
    after(250, M(function(w)
        if keep.noMaps or w.page ~= "maps" then return end
        local n = #w.order
        local before = K.join(w.order)
        if n >= 2 then w.oSel = 1; w:move(1) end
        keep.m53swap = n < 2 or K.join(w.order) ~= before
        keep.m53steps = #(w.oUndo or {})
        local swapped = K.join(w.order)
        w:orderUndo()
        keep.m53same = K.join(w.order) == swapped
        keep.m53n = n
    end))
    after(350, M(function(w)
        if keep.noMaps or w.page ~= "maps" then return end
        local noBtn = K.spec(w, "undo") == nil
        w:leaveOrder(false)
        local back = w.page == "list" and K.same(K.mapOrder(), keep.maps0)
        check(back and noBtn and keep.m53steps == 0, "MO53: Back on the map order page discards (the map order as found)", "steps " .. tostring(keep.m53steps) .. ", Undo button " .. (noBtn and "absent" or "shown"))
        note("MO53: no Undo on Map order: a move (" .. tostring(keep.m53n) .. " maps, moved " .. K.b(keep.m53swap) .. ") takes no step, the band shows no Undo, and Undo changes nothing ("
            .. K.b(keep.m53same) .. "); Back discards, as in the game")
    end))
    after(250, M(function(w)
        if keep.noMaps then return end
        K.try("the map order page opened", function() w:enterOrder("maps") end)
        if w.page ~= "maps" then return end
        if #w.order >= 2 then w.oSel = 1; w:move(1) end
        local shown = K.join(w.order)
        K.try("MO54: Done", function() w:orderDone() end)
        local now = K.join(K.mapOrder())
        local ok = w.page == "list" and now == shown
        if w.page ~= "list" then w:leaveOrder(false) end
        K.mapsBack()
        check(ok and K.same(K.mapOrder(), keep.maps0), "MO54: Done writes the shown map order to the list in memory only (mods/default.txt gets it at Accept); put back",
            "in memory as shown " .. K.b(ok) .. "; put back " .. K.b(K.same(K.mapOrder(), keep.maps0)))
        note("MO54: Accept's checkMissingMaps (the game's, MSM:243-247) was not run: nothing was accepted")
        K.errCheck("the map order page")
    end))
end

-- 10: what only a person can check
function X.byHand()
    after(100, function()
        skip("MO4: a failed write of ModFolders.cfg (the spare is never read back; the band says nothing changed)", "by hand: a full or read-only disk can't be staged from Lua")
        skip("MO18: keys on the grouped list (Shift+F10, the menu key, Page Up and Down, Space, F2, Delete, Up and Down)", "by hand: real key presses")
        skip("MO28: a drag can't reach an empty section or a section's top when dragging down", "by hand: a real drag (ZeD.MouseTick)")
        skip("MO41: Done gives no word when the profile file can't be written", "by hand: a profile file that can't be written")
        skip("MO51: Return is Done when Find is empty; a Return closing Find is swallowed within 400 ms", "by hand: real Return presses and their timing")
        skip("MO56: the pad on Map order (A only picks, Y and X move, LB and RB a page, B back)", "by hand: a real controller")
        skip("MO57: the pad on the load order page (A's menu, Y and X, LB and RB, the pane following, the picker's focus)", "by hand: a real controller")
        skip("MO58: 1280x720 and 4K with large text", "by hand: the screen and text size are set before launch")
        skip("MO59: safe mode does not hand back the mod manager", "by hand: safe mode and a Lua error on these pages")
    end)
end

-- =========================================================================================================
-- the put-back
function X.putBack()
    after(300, function()
        pcall(function()
            local w = K.W()
            if not w then return end
            K.fakeOff(w)
            if w.pick then w:closePicker(true) end
            if w.confirm then w:setConfirm(false) end
            w.msel = nil
            w.find:setText("")
            if w.page == "order" or w.page == "maps" then w:leaveOrder(false) end
            if w.page == "profiles" then w:leaveProfiles() end
        end)
        MM.ctx.open = nil
        pcall(function()
            local w = K.W()
            if w and K.model() and w:changed() then note("put back: a mod was left changed in the Mods list: Undo changes"); w:revert() end
        end)
        pcall(function()
            local w = K.W()
            if w and keep.idsList0 and K.activeIds() ~= keep.ids0 then note("put back: the load order in memory differed: put back"); w:saveOrder(keep.idsList0) end
        end)
        pcall(function() if keep.maps0 and not K.same(K.mapOrder(), keep.maps0) then note("put back: the map order in memory differed: put back"); K.mapsBack() end end)
        pcall(function() if keep.liteVal ~= nil and St.lookStyleOption:getValue() ~= keep.liteVal then St.lookStyleOption:setValue(keep.liteVal) end end)
        for fid in pairs(keep.col) do pcall(K.putColor, fid) end
        pcall(function() if keep.key and keep.lo0 then O.putLo(keep.key, keep.lo0, false) end end)
        if keep.ffile then F.FILE = keep.ffile end
        for _, f in ipairs(FILES) do pcall(K.restoreFile, f) end
        pcall(F.load)
        pcall(O.load)
        pcall(function()
            local w = K.W()
            if w and keep.filter0 ~= nil then w.filter, w.hideInc = keep.filter0, keep.hide0; w.find:setText(""); w:dirty() end
        end)
        if keep.opt0 then pcall(K.setAll, keep.opt0) end
    end)
    after(500, function()
        if keep.noMods then return end
        if MM.view == "mods" then K.try("Mods: Back", function() K.leaveMods(K.W()) end) end
    end)
    waitFor(function() return keep.noMods or MM.view == "main" end, 4000, function(met)
        if MM.view ~= "main" then K.rescue() end
    end)
    after(500, function()
        local d = K.diff(keep.opt0, K.snapAll())
        check(keep.opt0 ~= nil and #d == 0, "put back: every ZeD option as found (" .. K.count(keep.opt0) .. " options)", K.short(d))
        check(F.FILE == keep.ffile, "put back: ZeD.ModFolders.FILE as found", tostring(F.FILE))
        for _, f in ipairs(FILES) do
            local was = keep.files and keep.files[f]
            local now = K.readLines(f)
            if was then check(K.same(now, was), "put back: Lua/" .. f .. " line for line", (now and #now or "no") .. " lines (was " .. #was .. ")")
            elseif now == nil then check(true, "put back: Lua/" .. f .. " was not there and is not there")
            else note("put back: Lua/" .. f .. " was not there before and now exists with " .. #now .. " lines (Lua cannot delete a file; the chain's snapshot removes it)") end
        end
        check(K.activated() == keep.mods0, "put back: the mods in use are the ones found")
        check(K.wouldReset() == nil, "put back: the mod list in memory is the one running (no Lua reload waiting)", K.wouldReset())
        check(MM.view == "main" and K.up("main") and MM.ctx.open == nil, "put back: the main window is up, no menu open", "view " .. tostring(MM.view))
    end)
    after(300, function()
        keep.zapFree = true
        K.freeZap()
        local n = K.errs()
        if n ~= nil and keep.errs0 ~= nil then say("Lua errors counted during the run: " .. (n - keep.errs0)) end
    end)
end

-- =========================================================================================================
if not (MM and MM.root and St and MM.showView and O and F) then
    after(100, function() S.fail = S.fail + 1; say("ERR ZeD's main menu or the mod manager's models are not up: nothing was done") end)
else
    X.start()
    X.pure()
    X.folderFile()
    X.folderField()
    X.folderLook()
    X.folderBox()
    X.fakeEnter()
    X.fakeSeps()
    X.fakeOrder()
    X.realBack()
    X.realLive()
    X.maps()
    X.byHand()
    mark()
    X.putBack()
end
after(300, function()
    say("end: " .. S.pass .. " pass, " .. S.fail .. " fail, " .. S.skips .. " skipped; " .. math.floor((getTimestampMs() - S.start) / 1000) .. " s; view=" .. tostring(MM and MM.view))
    say(S.fail > 0 and ("VERDICT FAIL " .. S.fail) or ("VERDICT PASS " .. S.pass))
end)
after(100, function() say("DONE") end)

local function tickFn()
    if MM and not keep.zapFree then pcall(K.holdZap) end
    local s = S.stages[S.si]
    if not s then Events.OnFETick.Remove(tickFn); return end
    local now = getTimestampMs()
    if S.markAt and S.si < S.markAt and now - S.start > S.maxMs then
        S.fail = S.fail + 1
        say("ERR out of time at stage " .. S.si .. " of " .. #S.stages .. ": on to the put-back")
        S.si = S.markAt; S.t0 = nil
        return
    end
    if not S.t0 then S.t0 = now; S.n = 0 end
    S.n = S.n + 1
    local el = now - S.t0
    local go, met = false, false
    if s.cond then
        if S.n >= 2 then
            local ok, r = pcall(s.cond)
            met = ok and r and true or false
            if not ok and not s.said then s.said = true; say("ERR stage " .. S.si .. " (its wait): " .. tostring(r)); S.fail = S.fail + 1 end
        end
        go = met or el >= s.ms
    else
        go = el >= s.ms and S.n >= 3
    end
    if not go then return end
    S.si = S.si + 1
    S.t0 = nil
    local ok, e = pcall(s.fn, met)
    if not ok then S.fail = S.fail + 1; say("ERR stage " .. (S.si - 1) .. ": " .. tostring(e)) end
end
Events.OnFETick.Add(tickFn)
say("start (" .. #S.stages .. " stages)")
