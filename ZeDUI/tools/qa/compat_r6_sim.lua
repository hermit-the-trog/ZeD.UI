-- ZeDUI/tools/qa/compat_r6_sim.lua  (Nov 7 2026, Build): the round 6 mod support for the menus, with no game running.
--   * Clear Skill Sheet (ModSupport/Clear_SkillSheet.lua) on the real SkillsTab.lua: the rate, its color, the row's tag in
--     place of the boost tag, the card lines added under (or as) the row's card, the mod's Enable option.
--   * Better Folders (ModSupport/VIF_DualRender_B42.lua) on the real ContainerGroups.lua: filed things grouped under their
--     folder in the character's own inventory only, the folder's words and order, the list rebuilt after each change, the
--     item menu's folder lines. The mod's own VIFState.lua is used when its SteamCMD copy is on this machine (the path in
--     ZeDUI/workshop/compat_round6_candidates.md); without it those checks are skipped, said in one line.
--   * Better Mod Experience (ModSupport/BetterModExperience.lua) on stubs of the main menu windows: Options > Mods read
--     whole and folded per mod, Load's reason and Play, New Game held back with the prompt, Host's problem line, the Mods
--     screen's pending line, and Back not sorting.
-- What it can't show is how it looks, the game's own menus and ZeD's real windows: the in-game list in
-- ZeDUI/qa/CHECK_mods-menus_20261107.md.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/compat_r6_sim.lua
-- It prints FAIL lines and a last line "compat_r6_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]compat_r6_sim%.lua$", "")
local VIF_STATE = "C:/steamcmd/steamapps/workshop/content/108600/3834889317/mods/VIF_DualRender_B42/42/media/lua/client/VIF/VIFState.lua"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function noop() end

-- ---------------------------------------------------------------------------
-- THE STUBS (shared)
-- ---------------------------------------------------------------------------
local function list(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end }
end
local ACTIVE = { "Clear_SkillSheet", "\\VIF_DualRender_B42", "BetterModExperience", "ZeD_UI" }
getActivatedMods = function() return list(ACTIVE) end
local TEXT = { UI_ClearSkillSheet_XpGain = "XP gain: %1", IGUI_skills_Multiplier = "Multiplier: %1" }
getText = function(k, a, b)
    local s = TEXT[k] or k
    s = s:gsub("%%1", tostring(a or "")):gsub("%%2", tostring(b or ""))
    return s
end
getTextOrNull = function(k) return TEXT[k] end
Events = setmetatable({}, { __index = function(t, k)
    local e = { fns = {} }
    e.Add = function(fn) e.fns[#e.fns + 1] = fn end
    e.Remove = noop
    rawset(t, k, e)
    return e
end })
require = function() return nil end

local COLOR = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
ZeD = {
    T = setmetatable({ px = function(n) return n end, sp = { xs = 3 } }, { __index = function() return COLOR end }),
    TM = { getFontHeight = function() return 16 end, MeasureStringX = function(_, _, s) return #tostring(s) * 7 end },
    tr = function(k, ...)
        local a = { ... }
        local s = k
        for i = 1, #a do s = s .. ":" .. tostring(a[i]) end
        return s
    end,
    textCase = function(s) return s end,
    Safe = { on = function() return false end },
}

-- ---------------------------------------------------------------------------
-- CLEAR SKILL SHEET
-- ---------------------------------------------------------------------------
section("Clear Skill Sheet")
Perks = { Fitness = "Fitness", Strength = "Strength", Sprinting = "Sprinting", Axe = "Axe", Cooking = "Cooking",
          Carving = "Carving", Crafting = "Crafting", None = "None" }
CharacterTrait = { FAST_LEARNER = "FL", SLOW_LEARNER = "SL", PACIFIST = "PA", CRAFTY = "CR" }
local function perk(t, parent)
    return { getType = function() return t end, getName = function() return t end, getParent = function() return parent or "Combat" end,
             getXpForLevel = function() return 100 end, getXp1 = function() return 75 end }
end
local P = { Fitness = perk("Fitness", "Passiv"), Strength = perk("Strength", "Passiv"), Sprinting = perk("Sprinting", "Agility"),
            Axe = perk("Axe"), Cooking = perk("Cooking", "Survivalist"), Carving = perk("Carving", "Crafting") }
PerkFactory = { PerkList = list({ P.Fitness, P.Strength, P.Sprinting, P.Axe, P.Cooking, P.Carving }) }
local function char(boosts, traits, books)
    return {
        getXp = function() return {
            getPerkBoost = function(_, t) return boosts[t] or 0 end,
            getMultiplier = function(_, t) return books and books[t] or 0 end,
            getXP = function() return 120 end,
        } end,
        hasTrait = function(_, tr) return traits and traits[tr] == true end,
        getPerkLevel = function() return 1 end,
    }
end

dofile(ROOT .. "42/media/lua/client/ZeD/SkillsTab.lua")
dofile(ROOT .. "42/media/lua/client/ZeD/ModSupport/Clear_SkillSheet.lua")
local CSS = ZeD.ModSupport.Clear_SkillSheet
check("the support loaded", CSS ~= nil and CSS.X ~= nil)
check("registered as a Skills tab extra", ZeD.SkillsTab.extras[1] and ZeD.SkillsTab.extras[1].id == "Clear_SkillSheet")

local plain = char({})
check("no boost: x0.25", CSS.gain(plain, P.Axe) == 0.25, CSS.gain(plain, P.Axe))
check("Fitness keeps x1 at no boost", CSS.gain(plain, P.Fitness) == 1)
check("Sprinting at boost 1: x1.25", CSS.gain(char({ Sprinting = 1 }), P.Sprinting) == 1.25)
check("boost 2: x1.33", CSS.gain(char({ Axe = 2 }), P.Axe) == 1.33)
check("boost 3 + Fast Learner: x2.16", CSS.gain(char({ Axe = 3 }, { FL = true }), P.Axe) == 2.16, CSS.gain(char({ Axe = 3 }, { FL = true }), P.Axe))
check("Strength never sped up", CSS.gain(char({ Strength = 3 }, { FL = true }), P.Strength) == 1)
check("Slow Learner: x0.7 at boost 1", CSS.gain(char({ Cooking = 1 }, { SL = true }), P.Cooking) == 0.7)
check("Pacifist on Axe at boost 2: x1 (0.9975 rounded)", CSS.gain(char({ Axe = 2 }, { PA = true }), P.Axe) == 1)
check("Crafty on a crafting skill", CSS.gain(char({ Carving = 1 }, { CR = true }), P.Carving) == 1.3)
check("colors: gray, green, blue, orange", CSS.color(0.25) == CSS.GRAY and CSS.color(1) == CSS.GREEN
    and CSS.color(1.33) == CSS.BLUE and CSS.color(1.66) == CSS.ORANGE)
check("numbers: trailing zeros dropped", CSS.num(1.5, 2) == "1.5" and CSS.num(3, 1) == "3" and CSS.num(1.33, 2) == "1.33")

local function skill(p, lv, boost) return { perk = p, name = p:getName(), level = lv or 1, boost = boost or 0, xpProgress = 0.2 } end
check("no tag below x1 with no boost and no book", ZeD.SkillsTab.extrasTag(plain, skill(P.Axe)) == nil)
local tg = ZeD.SkillsTab.extrasTag(char({ Axe = 2 }), skill(P.Axe, 1, 2))
check("boost 2: the tag", tg and tg.text == "UI_ZeD_CSS_Tag:1.33" and tg.color == CSS.BLUE, tg and tg.text)
tg = ZeD.SkillsTab.extrasTag(char({}, nil, { Cooking = 3 }), skill(P.Cooking))
check("a book alone: the tag with the book", tg and tg.text == "UI_ZeD_CSS_TagBook:0.25:3" and tg.color == CSS.GRAY, tg and tg.text)
tg = ZeD.SkillsTab.extrasTag(char({ Axe = 2 }, { PA = true }), skill(P.Axe, 1, 2))
check("Pacifist on a boosted skill: the tag stays", tg ~= nil)

local win = { _playerObj = char({ Axe = 2 }, nil, { Axe = 2 }) }
local card = ZeD.SkillsTab._skillCard(win, skill(P.Axe, 1, 2))
local texts = {}
for _, l in ipairs(card and card.lines or {}) do texts[#texts + 1] = l.text end
local joined = table.concat(texts, "|")
check("the card: the rate in the mod's words", joined:find("XP gain: x1.33", 1, true) ~= nil, joined)
check("the card: the book in the game's words", joined:find("Multiplier: 2", 1, true) ~= nil, joined)
win._playerObj = char({})
card = ZeD.SkillsTab._skillCard(win, skill(P.Axe, 10))
texts = {}
for _, l in ipairs(card and card.lines or {}) do texts[#texts + 1] = l.text end
check("a maxed skill: no rate line, no book: no card", card == nil, table.concat(texts, "|"))

-- another extra's card first, Clear Skill Sheet's lines under it
ZeD.SkillsTab.addExtras("Other", { card = function() return { label = "Other", lines = { { text = "Saved", value = "5" } } } end })
win._playerObj = char({ Axe = 2 })
card = ZeD.SkillsTab._skillCard(win, skill(P.Axe, 1, 2))
texts = {}
for _, l in ipairs(card and card.lines or {}) do texts[#texts + 1] = l.text end
joined = table.concat(texts, "|")
check("with another extra's card: both", joined:find("UI_ZeD_Skills_CardLine:Saved:5", 1, true) and joined:find("XP gain", 1, true), joined)
check("the other card's lines come first", (joined:find("Saved", 1, true) or 99) < (joined:find("XP gain", 1, true) or 0), joined)
table.remove(ZeD.SkillsTab.extras)

ClearSkillSheet = { isEnabled = function() return false end }
check("the mod's Enable off: no tag", ZeD.SkillsTab.extrasTag(char({ Axe = 2 }), skill(P.Axe, 1, 2)) == nil)
check("the mod's Enable off: no card", ZeD.SkillsTab._skillCard({ _playerObj = char({ Axe = 2 }) }, skill(P.Axe, 1, 2)) == nil)
ClearSkillSheet = { isEnabled = function() error("boom") end }
check("the option unreadable: on", ZeD.SkillsTab.extrasTag(char({ Axe = 2 }), skill(P.Axe, 1, 2)) ~= nil)
ClearSkillSheet = nil

-- ---------------------------------------------------------------------------
-- BETTER FOLDERS
-- ---------------------------------------------------------------------------
section("Better Folders")
dofile(ROOT .. "42/media/lua/client/ZeD/ContainerGroups.lua")
local CG = ZeD.ContainerGroups
check("no provider: nothing asked", CG.any() == false and CG.groupOf({}, nil, nil, true) == nil and CG.sig() == false)
local keys0 = { "Food", "Clothing", "Tool" }
CG.sortKeys(keys0, true)
check("no provider: categories sort as before", table.concat(keys0, ",") == "Clothing,Food,Tool")

local fh = io.open(VIF_STATE, "r")
if not fh then
    print("SKIP Better Folders' own VIFState.lua is not on this machine (" .. VIF_STATE .. "): its checks are skipped")
else
    fh:close()
    -- one character with a main inventory, a bag, items
    local function item(id, ft)
        return { getID = function() return id end, getFullType = function() return ft end }
    end
    local md = {}
    local mainInv, bag = { name = "main" }, { name = "bag" }
    local player = { getModData = function() return md end, getInventory = function() return mainInv end,
                     getPlayerNum = function() return 0 end }
    getSpecificPlayer = function(n) if n == 0 then return player end return nil end
    instanceof = function() return true end
    dofile(VIF_STATE)
    VIFFolderRows = { itemKey = function(it)
        local ok, v = pcall(it.getID, it)
        if not ok or v == nil then return nil end
        return "item:" .. tostring(v)
    end }
    -- the game's text box: answers OK with the name given here
    local nextName = nil
    ISTextBox = { new = function(_, x, y, w, h, title, start, target, onclick, pn)
        local box = { title = title, start = start, entry = { getText = function() return nextName end } }
        box.initialise = noop
        box.addToUIManager = function() onclick(target, { internal = "OK", parent = box }) end
        return box
    end }
    local function menuStub()
        local m = { opts = {}, subs = {} }
        function m:addOption(name, target, fn, a, b) local o = { name = name, target = target, fn = fn, a = a, b = b }; self.opts[#self.opts + 1] = o; return o end
        function m:addSubMenu(o, sub) o.sub = sub end
        return m
    end
    ISContextMenu = { getNew = function() return menuStub() end }
    getPlayerInventory = function() return nil end   -- (ZeD's windows up: the game's page has no pane for the mod)

    dofile(ROOT .. "42/media/lua/client/ZeD/ModSupport/VIF_DualRender_B42.lua")
    local BF = ZeD.ModSupport.VIF_DualRender_B42
    check("the support loaded", BF ~= nil and BF.G ~= nil and CG.any())
    check("the mod's mutate wrapped", VIFState._zedWrapped == true)

    local axe, apple, apple2, rope = item(1, "Base.Axe"), item(2, "Base.Apple"), item(3, "Base.Apple"), item(4, "Base.Rope")
    local sig0 = CG.sig(mainInv, player, true)
    check("nothing filed: no group", CG.groupOf(axe, mainInv, player, true) == nil)

    -- make two folders through the item menu (Create folder... and the prompt)
    local function fill(it, inv)
        it.getContainer = function() return inv end
        local ctx = menuStub()
        BF.onFill(0, ctx, { it })
        return ctx
    end
    local ctx = fill(axe, mainInv)
    local top = ctx.opts[1]
    check("the item menu: Virtual folders", top and top.name == "UI_VIF_VirtualFolders" and top.sub ~= nil)
    check("Create folder... first", top and top.sub.opts[1] and top.sub.opts[1].name == "UI_VIF_CreateFolder")
    nextName = "Tools"
    top.sub.opts[1].fn(top.sub.opts[1].target)
    nextName = "Food"
    top.sub.opts[1].fn(top.sub.opts[1].target)
    local st = BF.state(player)
    check("two folders made", st and #st.order == 2, st and #st.order)
    check("the list told to rebuild", CG.sig(mainInv, player, true) ~= sig0)
    check("saved in the character's modData", md.VirtualInventoryFolders_v1 ~= nil)
    check("a bag's item: no menu", #fill(rope, bag).opts == 0)

    -- file the axe by itself and apples by type (the filing lines ZeD adds when the mod's own are not there)
    local tools, food = st.order[1], st.order[2]
    BF.change(player, VIFState.assignVerified, axe, tools, VIFFolderRows.itemKey)
    ctx = fill(apple, mainInv)
    local sub = ctx.opts[1].sub
    local move = nil
    for _, o in ipairs(sub.opts) do if o.name == "UI_VIF_MoveTypeToFolder" then move = o end end
    check("the filing line is there (the mod's own page has no pane)", move ~= nil and move.sub and #move.sub.opts == 2)
    for _, o in ipairs(move and move.sub.opts or {}) do if o.name == "Food" then o.fn(o.target) end end
    local kAxe = CG.groupOf(axe, mainInv, player, true)
    local kApple = CG.groupOf(apple, mainInv, player, true)
    check("the axe under Tools", kAxe == "vif:0:" .. tools, kAxe)
    check("both apples under Food (by type)", kApple == "vif:0:" .. food and CG.groupOf(apple2, mainInv, player, true) == kApple)
    check("not in a bag's list", CG.groupOf(apple, bag, player, false) == nil)
    check("not on the loot side", CG.groupOf(apple, mainInv, player, false) == nil)
    check("the folder's words", CG.label(kAxe) == "Tools" and CG.label(kApple) == "Food")
    check("a category is not the mod's", CG.label("Food") == nil and CG.rank("Food") == nil)
    local keys = { "Tool", kApple, "Clothing", kAxe }
    CG.sortKeys(keys, true)
    check("folders first in the mod's order, then categories", table.concat(keys, ",") == kAxe .. "," .. kApple .. ",Clothing,Tool", table.concat(keys, ","))
    keys = { "Tool", kApple, "Clothing", kAxe }
    CG.sortKeys(keys, false)
    check("sorted the other way: folders still first", table.concat(keys, ",") == kAxe .. "," .. kApple .. ",Tool,Clothing", table.concat(keys, ","))

    -- rename and delete from a filed thing's menu
    ctx = fill(axe, mainInv)
    sub = ctx.opts[1].sub
    local ren, del = nil, nil
    for _, o in ipairs(sub.opts) do
        if o.name == "UI_VIF_Rename" then ren = o end
        if o.name == "UI_VIF_DeleteFolder" then del = o end
    end
    check("a filed thing: Rename and Delete", ren ~= nil and del ~= nil)
    nextName = "Kit"
    if ren then ren.fn(ren.target, ren.a) end
    check("renamed: the group's words follow", CG.label(kAxe) == "Kit", CG.label(kAxe))
    local sig1 = CG.sig(mainInv, player, true)
    if del then del.fn(del.target, del.a) end
    check("deleted: the axe back in its category", CG.groupOf(axe, mainInv, player, true) == nil)
    check("deleted: the list told", CG.sig(mainInv, player, true) ~= sig1)
    check("the apples stay filed", CG.groupOf(apple, mainInv, player, true) == kApple)
    ctx = fill(apple, mainInv)
    local rem = nil
    for _, o in ipairs(ctx.opts[1].sub.opts) do if o.name == "UI_VIF_RemoveFromFolder" then rem = o end end
    check("Remove from folder offered for a type rule", rem ~= nil)
    if rem then rem.fn(rem.target) end
    check("removed: back in its category", CG.groupOf(apple, mainInv, player, true) == nil)

    -- the mod's own menu answers: ZeD's adds only the folder lines
    getPlayerInventory = function() return { inventoryPane = { player = 0, inventory = mainInv } } end
    ctx = fill(apple, mainInv)
    local hasMove = false
    for _, o in ipairs(ctx.opts[1].sub.opts) do if o.name == "UI_VIF_MoveTypeToFolder" then hasMove = true end end
    check("with the mod's own menu there: no second filing line", not hasMove)

    -- a provider that throws counts as none
    CG.add("Broken", { group = function() error("bad") end })
    check("a throwing provider skipped", CG.groupOf(apple, mainInv, player, true) == nil and CG.errors.Broken ~= nil)
    CG.list[#CG.list] = nil
end

-- ---------------------------------------------------------------------------
-- BETTER MOD EXPERIENCE
-- ---------------------------------------------------------------------------
section("Better Mod Experience")
local now = 0
local sounds = 0
local MM = { now = function() return now end, clickSound = function() sounds = sounds + 1 end }
ZeD.MainMenu = MM

-- the options page: a fake mods panel with two sections folded the mod's way
local function ui(kind, y, text)
    local u = { kind = kind, y0 = y, text = text }
    u.getY = function(self) return self.y0 end
    u.setY = function(self, v) self.y0 = v end
    return u
end
local hA, a1, a2 = ui("header", 0, "Mod A"), ui("tick", 40, "a1"), ui("tick", 70, "a2")
local hB, b1 = ui("header", 100, "Mod B"), ui("combo", 140, "b1")
local loose = ui("tick", 200, "loose")
local gA = { open = false, heading = { { ui = hA, y = 0 } }, body = { { ui = a1, y = 40 }, { ui = a2, y = 70 } } }
local gB = { open = false, heading = { { ui = hB, y = 100 } }, body = { { ui = b1, y = 140 } } }
-- the mod's layout: section A shut, so B's heading and body moved up by A's body (60)
local function bmeLayout()
    local removed = 0
    for _, g in ipairs({ gA, gB }) do
        for _, e in ipairs(g.heading) do e.ui:setY(e.y - removed) end
        for _, e in ipairs(g.body) do e.ui:setY(e.y - removed) end
        if not g.open then removed = removed + 60 end
    end
end
hA.forceClick = function() gA.open = not gA.open; bmeLayout(); return true end
hB.forceClick = function() gB.open = not gB.open; bmeLayout(); return true end
bmeLayout()
local panel = { bmeGroups = { gA, gB } }
local view = { getChildren = function() return { panel } end }
-- ZeD's reading, as ZeD_MainMenuOptions: every label and control by where it sits now
MM.optionRows = function(page)
    local rows = {}
    for _, u in ipairs({ hA, a1, a2, hB, b1, loose }) do
        if u.kind == "header" then rows[#rows + 1] = { kind = "header", text = u.text, y = u:getY(), el = u }
        else rows[#rows + 1] = { kind = u.kind, label = u.text, y = u:getY(), control = u } end
    end
    table.sort(rows, function(a, b) if a.y ~= b.y then return a.y < b.y end return a.kind == "header" end)
    return rows
end
local drawn = nil
ZeD_MMOptions = { drawRows = function(self, x, y, w, h, rows) drawn = rows end }
-- the main menu windows
local loadWhy = nil
ZeD_MMLoad = { whyNot = function(self, s) return loadWhy end }
local played = 0
ZeD_MMNewGame = { items = function(self) return self._items end, isChallengesItem = function() return false end,
                  next = function(self) played = played + 1 end }
local hostProblem = nil
ZeD_MMHost = { problem = function() return hostProblem end }
local accepted, skipSeen = 0, nil
ZeD_MMMods = {
    pendingNow = function() return "Load order changed", false end,
    accept = function(self) accepted = accepted + 1; skipSeen = ModSelector.instance.model.bmeSkipAutoSort end,
    back = function(self) self:accept() end,
    discard = function(self) self:accept() end,
}
-- the mod's sorting: a list holding "bad" is held back
local function same(a, b)
    if #a ~= #b then return false end
    for i, v in ipairs(a) do if b[i] ~= v then return false end end
    return true
end
local previews = 0
BetterModExperience = { Sorting = {
    read = function(l) local t = {}; for i = 0, l:size() - 1 do t[#t + 1] = l:get(i) end; return t end,
    same = same,
    preview = function(owner, ids, force)
        if force or not owner.bmePlan or not same(owner.bmePlan.ids, ids) then
            previews = previews + 1
            local errs = {}
            for _, id in ipairs(ids) do if id == "bad" then errs[#errs + 1] = "<RGB:1,0,0>bad requires good" end end
            owner.bmePlan = { ids = ids, errors = errs }
        end
        return owner.bmePlan
    end,
} }
local function active(ids) return { getMods = function() return list(ids) end } end
local CURRENT = { "a", "b" }
ActiveMods = { getById = function(id) if id == "currentGame" then return active(CURRENT) end return active({ "a" }) end }
local prompts = {}
ISModalDialog = { new = function(_, x, y, w, h, text, yesno)
    local d = { text = text, yesno = yesno, initialise = noop }
    d.addToUIManager = function() prompts[#prompts + 1] = d end
    return d
end }
getModInfoByID = function() return { getName = function() return "Better Mod Experience" end } end

dofile(ROOT .. "42/media/lua/client/ZeD/ModSupport/BetterModExperience.lua")
local BME = ZeD.ModSupport.BetterModExperience
check("the support loaded", BME ~= nil)

-- Options > Mods
local rows = MM.optionRows({ view = view })
local order = {}
for _, r in ipairs(rows) do order[#order + 1] = r.text or r.label end
check("read in the game's own order (not jumbled by the folds)", table.concat(order, ",") == "Mod A,a1,a2,Mod B,b1,loose", table.concat(order, ","))
check("the mod's layout put back after the read", hB:getY() == 40 and b1:getY() == 80 and a1:getY() == 40)
local headA, headB = rows[1], rows[4]
check("each heading a fold, shut as the mod has it", headA.onFold and headA.shut == true and headB.onFold and headB.shut == true)
check("the count: the section's options", headA.count == 2 and headB.count == 1, tostring(headA.count) .. "/" .. tostring(headB.count))
check("a row outside the sections stays plain", rows[6].bmeGroup == nil)
ZeD_MMOptions:drawRows(0, 0, 100, 100, rows, { raw = "mods" }, false)
order = {}
for _, r in ipairs(drawn) do order[#order + 1] = r.text or r.label end
check("drawn: shut sections show their heading only", table.concat(order, ",") == "Mod A,Mod B,loose", table.concat(order, ","))
headA.onFold()
check("ZeD's fold opens the mod's section", gA.open == true)
ZeD_MMOptions:drawRows(0, 0, 100, 100, rows, { raw = "mods" }, false)
order = {}
for _, r in ipairs(drawn) do order[#order + 1] = r.text or r.label end
check("drawn open", table.concat(order, ",") == "Mod A,a1,a2,Mod B,loose" and headA.shut == false, table.concat(order, ","))
ZeD_MMOptions:drawRows(0, 0, 100, 100, rows, { raw = "mods" }, true)
check("Find draws every row", #drawn == 6)
ZeD_MMOptions:drawRows(0, 0, 100, 100, rows, { raw = "setup" }, false)
check("other pages untouched", #drawn == 6)
check("a page without the mod's panel: read as before", #MM.optionRows({ view = {} }) == 6)

-- Load
local s = { activeMods = active({ "a", "bad" }) }
local why = ZeD_MMLoad:whyNot(s)
check("Load: the mod's reason, tags out", why == "bad requires good", why)
local p0 = previews
ZeD_MMLoad:whyNot(s)
check("Load: the plan kept while the list is the same", previews == p0)
check("Load: a clean list plays", ZeD_MMLoad:whyNot({ activeMods = active({ "a" }) }) == nil)
loadWhy = "corrupt"
check("Load: the game's own reason first", ZeD_MMLoad:whyNot(s) == "corrupt")
loadWhy = nil
check("Load: no save, no reason", ZeD_MMLoad:whyNot(nil) == nil)

-- New Game
local ng = setmetatable({ _items = { { title = "Survivor" } }, sel = 1 }, { __index = ZeD_MMNewGame })
ZeD_MMNewGame.next(ng)
check("New Game: a clean list starts", played == 1 and #prompts == 0)
CURRENT = { "a", "bad" }
ZeD_MMNewGame.next(ng)
check("New Game: held back", played == 1)
check("New Game: ZeD's note with the reason", #prompts == 1 and prompts[1].yesno == false
    and prompts[1].text:find("UI_ZeD_BME_NotStarted:Better Mod Experience", 1, true) and prompts[1].text:find("bad requires good", 1, true), prompts[1] and prompts[1].text)
CURRENT = { "a" }

-- Host
CoopConnection = { servername = "srv" }
local serverMods = "a;bad"
ServerSettings = { new = function(name)
    return { loadFiles = function() return true end, getServerOptions = function() return {
        getOptionByName = function(_, n) return { getValue = function() return serverMods end } end } end }
end }
check("Host: the mod's reason as the problem", ZeD_MMHost:problem() == "bad requires good")
serverMods = "a"
check("Host: kept a moment", ZeD_MMHost:problem() == "bad requires good")
now = now + 5000
check("Host: read again, clean", ZeD_MMHost:problem() == nil)
hostProblem = "bad name"
check("Host: ZeD's own problem first", ZeD_MMHost:problem() == "bad name")

-- the Mods screen
local text = ZeD_MMMods:pendingNow()
check("Mods: the pending line says the mod sorts", text == "Load order changed UI_ZeD_BME_SortsOnAccept:Better Mod Experience", text)
local mdl = { bmeEntryOrder = { "a", "b" }, getActiveMods = function() return active({ "a", "b" }) end }
ModSelector = { instance = { model = mdl } }
local mods = setmetatable({}, { __index = ZeD_MMMods })
mods:back()
check("Mods: Back with the order unchanged does not sort", accepted == 1 and skipSeen == true and mdl.bmeSkipAutoSort == nil)
mods:discard()
check("Mods: Discard changes the same", accepted == 2 and skipSeen == true)
mods:accept()
check("Mods: Accept sorts", accepted == 3 and skipSeen == nil)
mdl.getActiveMods = function() return active({ "b", "a" }) end
mods:back()
check("Mods: Back after a reorder sorts (as the mod's own Back)", accepted == 4 and skipSeen == nil)

print("compat_r6_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
