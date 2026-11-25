-- ZeDUI/tools/qa/cb_build_fixes_sim.lua  (QA cb sweep, Nov 25 2026: the Build tab's proven bugs, B1-B7, B10, B11)
-- Each fix the way the game's own build window does it (ISBuildPanel, ISWidgetBuildControl, MainScreen):
--   PADA     B1: A on the game's build cursor (ISBuildIsoEntity) sets its build flag on a valid tile, as the mouse's
--            release does; not on a blocked or red tile; LB, RB and B still reach the game's own handler
--   FACE     B6: the cursor starts on the facing the preview card showed (nSprite from the game's face index), and the
--            preview's ">" steps the way RB turns the cursor (the game's W N E S), "<" the way LB does
--   REARM    B2: once a placed build ends (the logic's onStopCraft) the cursor, still up, is re-armed; a cancelled one is
--            not brought back; while the build runs it stays blocked
--   HOLD     B3: Build pressed while a build is queued or running starts nothing
--   MOVE     B7: the containers are read again and set on the logic when the player moves a square, not otherwise
--   CLOSE    B5: the World window's close drops the Build tab's cursor, never another's
--   ESC      B4: Escape with a cursor up skips ZeD's Escape takers (the recipe card) and goes on to the game's, which
--            drops the cursor; with none up the card still takes it
--   PADB     B11: pad B on the build card's stops closes the card and puts the focus back on its row
--   SKILL    B10: the card names the skill short in the game's words; "Unknown" only when the recipe is not known
-- Run from the repo root:  lua51 ZeDUI/tools/qa/cb_build_fixes_sim.lua
-- It prints FAIL lines and a last line "cb_build_fixes_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]cb_build_fixes_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))
end
local function cut(src, from, to)
    local a = src and string.find(src, from, 1, true)
    if not a then return nil end
    local b = string.find(src, to, a, true)
    if not b then return nil end
    return string.sub(src, a, b + #to - 1) .. "\n"
end
local function has(src, s) return src ~= nil and string.find(src, s, 1, true) ~= nil end

local BT  = readFile(Z .. "BuildingTab.lua") or ""
local PIP = readFile(Z .. "Overrides/PlaceItemPad.lua") or ""
local PR  = readFile(Z .. "Overrides/Prompts.lua") or ""
local OCP = readFile(Z .. "ObjectCardPreview.lua") or ""
local CCS = readFile(Z .. "CraftingCore.lua") or ""
local WW  = readFile(Z .. "ZeD_WorldWindow.lua") or ""
check("SOURCE: the files read", #BT > 0 and #PIP > 0 and #PR > 0 and #OCP > 0 and #CCS > 0 and #WW > 0)

-- ---------------------------------------------------------------------------
print("-- PADA (B1): A on the game's build cursor")
Joypad = { AButton = "A", BButton = "B", RBumper = "RB", LBumper = "LB", YButton = "Y" }
local origCalls = {}
local Base = {}
function Base:onJoypadPressButton(ji, jd, button) origCalls[#origCalls + 1] = button end
ISBuildIsoEntity = setmetatable({}, { __index = Base })
do
    local src = cut(PIP, "local function applyBuild()", "\nend\n")
    check("PADA: applyBuild found in PlaceItemPad.lua", src ~= nil)
    if src then
        local fn, e = loadstring(src .. "return applyBuild", "applyBuild")
        check("PADA: applyBuild loads", fn ~= nil, e)
        if fn then
            local applyBuild = fn()
            applyBuild()
            applyBuild()   -- (twice: wrapped once)
            local cur = setmetatable({ canBeBuild = true }, { __index = ISBuildIsoEntity })
            cur:onJoypadPressButton(0, {}, Joypad.AButton)
            check("PADA: A on a valid tile sets the build flag", cur.build == true)
            check("PADA: A is not handed on as well", #origCalls == 0, #origCalls)
            local red = setmetatable({ canBeBuild = false }, { __index = ISBuildIsoEntity })
            red:onJoypadPressButton(0, {}, Joypad.AButton)
            check("PADA: A on a red tile does not build", red.build == nil)
            local blocked = setmetatable({ canBeBuild = true, blockBuild = true }, { __index = ISBuildIsoEntity })
            blocked:onJoypadPressButton(0, {}, Joypad.AButton)
            check("PADA: A on a blocked cursor does not build", blocked.build == nil)
            cur:onJoypadPressButton(0, {}, Joypad.RBumper)
            cur:onJoypadPressButton(0, {}, Joypad.BButton)
            check("PADA: RB and B still reach the game's handler, once each (wrapped once)",
                #origCalls == 2 and origCalls[1] == "RB" and origCalls[2] == "B", table.concat(origCalls, ","))
        end
    end
    check("PADA: applyBuild runs on boot, game start and a new player (server Lua loads late)",
        has(PIP, "Events.OnGameStart.Add(applyBuild)") and has(PIP, "Events.OnCreatePlayer.Add(applyBuild)"))
end

-- ---------------------------------------------------------------------------
-- the game's world, stubbed: one cell with a drag per player, a player on a square, a BuildLogic that fires its events
local drags = {}
local function cellStub()
    return { getDrag = function(_, pn) return drags[pn] end, setDrag = function(_, d, pn) drags[pn] = d end }
end
local theCell = cellStub()
getCell = function() return theCell end
local PX, PY = 10, 10
local player = {
    getPlayerNum = function() return 0 end,
    getCurrentSquare = function() return { getX = function() return PX end, getY = function() return PY end, getZ = function() return 0 end } end,
    isBuildCheat = function() return false end,
    getInventory = function() return {} end,
}
local logics = {}
local canPerform = true
BuildLogic = { new = function()
    local l = { listeners = {}, inProgress = false, containersSet = 0 }
    function l:getAllBuildableRecipes() return {} end
    function l:setRecipes() end
    function l:setRecipe(r) self.recipe = r end
    function l:setContainers(c)
        self.containersSet = self.containersSet + 1
        local changed = self.containers ~= c and (self.containers == nil or self.containers.at ~= c.at)
        self.containers = c
        if changed and self.listeners.onUpdateContainers then
            local L = self.listeners.onUpdateContainers
            L.fn(L.target)
        end
        return changed
    end
    function l:canPerformCurrentRecipe() return canPerform end
    function l:getSelectedBuildObject() return { name = "info" } end
    function l:getWallCoveringParams() return nil end
    function l:addEventListener(name, fn, target) self.listeners[name] = { fn = fn, target = target } end
    function l:isCraftActionInProgress() return self.inProgress end
    function l:startCraftAction() self.inProgress = true end
    function l:stopCraftAction()
        self.inProgress = false
        local L = self.listeners.onStopCraft
        if L then L.fn(L.target) end
    end
    logics[#logics + 1] = l
    return l
end }
ISBuildIsoEntity.new = function(self, character, info, nSprite, containers, logic)
    return setmetatable({ character = character, objectInfo = info, nSprite = nSprite, containers = containers,
        buildPanelLogic = logic }, { __index = ISBuildIsoEntity })
end
local playerUpdate = nil
Events = { OnPlayerUpdate = { Add = function(fn) playerUpdate = fn end, Remove = function() end } }
local counted = 0
local CCstub = {
    craftContainers = function(p) return { at = PX .. "," .. PY } end,
    incrementCraftCount = function() counted = counted + 1 end,
}
ZeD = { BuildingTab = {} }

local BTF = nil
do
    local up = cut(BT, "local _active = {}", "\nfunction ZeD.BuildingTab.buildInProgress(pn)")
    local up2 = cut(BT, "function ZeD.BuildingTab.buildInProgress(pn)", "\nend\n")
    local sb = cut(BT, "function ZeD.BuildingTab.startBuild(win, state)", "\nend\n")
    local cc = cut(BT, "local CARD_KINDS =", "\nend\n")
    local cc2 = cc and cut(BT, "function ZeD.BuildingTab.cardCancels(win, elements)", "\nend\n")
    check("SOURCE: the cursor's upkeep, startBuild and cardCancels found in BuildingTab.lua",
        up ~= nil and up2 ~= nil and sb ~= nil and cc ~= nil and cc2 ~= nil)
    if up and up2 and sb and cc and cc2 then
        -- (the upkeep block ends at buildInProgress's head: cut keeps the head line, drop it)
        up = string.gsub(up, "\nfunction ZeD%.BuildingTab%.buildInProgress%(pn%)\n$", "\n")
        local body = "local CC, _recipeByName, getTool = ...\n" .. up .. up2 .. sb .. cc .. cc2 .. "return _active\n"
        local fn, e = loadstring(body, "BuildingTab cut")
        check("SOURCE: the cut loads", fn ~= nil, e)
        if fn then
            local recipe = {
                getToolBoth = function() return nil end, getToolRight = function() return nil end, getToolLeft = function() return nil end,
            }
            BTF = { active = fn(CCstub, { Crate = { recipe = recipe }, Cross = { recipe = recipe } }, function() return nil end) }
        end
    end
end
check("SOURCE: the upkeep is on the player's update", type(playerUpdate) == "function")

if BTF then
    local win = { _playerObj = player }
    local function start(name, face)
        local state = { selected = name, _buildFace = face }
        ZeD.BuildingTab.startBuild(win, state)
        return drags[0]
    end

    print("-- FACE (B6): the cursor starts on the preview's facing")
    local c = start("Crate", nil)
    check("FACE: no preview seen: W (nSprite 1), as the game's panel starts it", c and c.nSprite == 1, c and c.nSprite)
    drags[0] = nil
    c = start("Crate", { name = "Crate", nSprite = 4 })
    check("FACE: the preview stepped to S: the cursor starts on S (nSprite 4)", c and c.nSprite == 4, c and c.nSprite)
    drags[0] = nil
    c = start("Crate", { name = "Cross", nSprite = 4 })
    check("FACE: another recipe's preview facing is not used", c and c.nSprite == 1, c and c.nSprite)

    print("-- REARM (B2): the cursor is usable again once the build ends")
    local L = logics[#logics]
    check("REARM: the logic has the game's two listeners", L.listeners.onStopCraft ~= nil and L.listeners.onUpdateContainers ~= nil)
    -- the game's tryBuild: startCraftAction, then blockAfterPlace blocks the cursor
    L:startCraftAction(); c.blockBuild = true
    local before = drags[0]
    print("-- HOLD (B3): Build while a build is queued starts nothing")
    local n0 = #logics
    ZeD.BuildingTab.startBuild(win, { selected = "Crate" })
    check("HOLD: Build during the build: no new cursor, no new logic", drags[0] == before and #logics == n0)
    check("HOLD: buildInProgress says so", ZeD.BuildingTab.buildInProgress(0) == true)
    L:stopCraftAction()
    check("REARM: the build ended: the cursor still up is re-armed (blockBuild false)", c.blockBuild == false, tostring(c.blockBuild))
    check("HOLD: after it, Build may start again", ZeD.BuildingTab.buildInProgress(0) == false)
    canPerform = false
    L:startCraftAction(); c.blockBuild = true
    L:stopCraftAction()
    check("REARM: the materials gone: it stays blocked, as the game's canPerformCurrentRecipe says", c.blockBuild == true)
    canPerform = true
    L:startCraftAction(); c.blockBuild = true
    drags[0] = nil   -- (cancelled while it ran)
    L:stopCraftAction()
    check("REARM: a cancelled cursor is not brought back", drags[0] == nil)

    print("-- MOVE (B7): the containers follow the player")
    drags[0] = nil
    c = start("Crate", nil)
    L = logics[#logics]
    local set0 = L.containersSet
    playerUpdate(player)
    check("MOVE: standing still: the containers are not read again", L.containersSet == set0, L.containersSet - set0)
    PX = 18
    playerUpdate(player)
    check("MOVE: a square on: the containers are read and set on the logic", L.containersSet == set0 + 1 and L.containers.at == "18,10",
        tostring(L.containers and L.containers.at))
    check("MOVE: the cursor carries the new list", c.containers == L.containers)
    L:startCraftAction()
    drags[0] = nil
    PX = 19
    playerUpdate(player)
    check("MOVE: the cursor cancelled but the build still under way: still read", L.containers.at == "19,10")
    L.inProgress = false
    PX = 20
    playerUpdate(player)
    check("MOVE: nothing up and nothing under way: the upkeep lets go", BTF.active[0] == nil and L.containers.at == "19,10")

    print("-- CLOSE (B5): the window's close drops the Build tab's cursor only")
    c = start("Crate", nil)
    check("CLOSE: the Build tab's cursor is dropped", ZeD.BuildingTab.dropCursor(0) == true and drags[0] == nil)
    c = start("Crate", nil)
    local other = { Type = "ISMoveableCursor" }
    drags[0] = other
    check("CLOSE: another cursor (Furniture) is left alone", ZeD.BuildingTab.dropCursor(0) == false and drags[0] == other)
    drags[0] = nil

    print("-- PADB (B11): B on the card closes it")
    local closed, landed = nil, nil
    CCstub.closeCraft = function(st) closed = st; st.selected = nil end
    ZeD.Input = { Focus = { focusByIdSoon = function(w, zone, id) landed = zone .. "|" .. id end } }
    local st = { selected = "Crate" }
    local keep = function() return "kept" end
    local els = { { craftKind = "cardSection", id = "build:card:req" }, { craftKind = "actBuild" }, { craftKind = "icon" },
        { craftKind = "slotAlt" }, { craftKind = "recipeRow" }, { craftKind = "cardSection", onCancel = keep } }
    ZeD.BuildingTab.cardCancels({ _buildState = st }, els)
    check("PADB: the card's stops get a B", els[1].onCancel ~= nil and els[2].onCancel ~= nil and els[3].onCancel ~= nil and els[4].onCancel ~= nil)
    check("PADB: a row keeps none, an existing B is kept", els[5].onCancel == nil and els[6].onCancel == keep)
    local took = els[1].onCancel({}, els[1])
    check("PADB: B on build:card:req closes the card", took == true and closed == st and st.selected == nil)
    check("PADB: the focus goes back to its row", landed == "worldTabContent|build:row:Crate", landed)
    check("PADB: no card open: B falls through (the game's B)", els[2].onCancel({}, els[2]) == false)
end

-- ---------------------------------------------------------------------------
print("-- FACE (B6): the preview card and the cursor turn the same way")
do
    local line = string.match(OCP, "local NSPRITE_OF = (%b{})")
    check("FACE: NSPRITE_OF found in ObjectCardPreview.lua", line ~= nil)
    local NS = line and loadstring("return " .. line)()
    -- the game's own conversion (ISBuildIsoEntity:getFace): nSprite 1 W, 2 N, 3 E, 4 S to face index 0 N, 1 W, 2 S, 3 E
    local function idxOf(ns) if ns == 2 then return 0 elseif ns == 4 then return 2 end return ns end
    if NS then
        local ok = true
        for i = 0, 3 do if idxOf(NS[i]) ~= i then ok = false end end
        check("FACE: each face index maps to the cursor's nSprite that shows it", ok)
    end
    local runR = string.match(OCP, 'fid = "oc:faceR".-run = function%(%) (.-) end }%)')
    local runL = string.match(OCP, 'fid = "oc:faceL".-run = function%(%) (.-) end }%)')
    check("FACE: the < and > presses found", runR ~= nil and runL ~= nil)
    if NS and runR and runL then
        local stepR = loadstring("local t, n = ...\n" .. runR)
        local stepL = loadstring("local t, n = ...\n" .. runL)
        local faces = { 0, 1, 2, 3 }   -- (the card lists getFace 0..3: N W S E)
        local okR, okL = true, true
        for k = 1, 4 do
            local t = { face = k }
            stepR(t, 4)
            local rb = NS[faces[k]] + 1; if rb > 4 then rb = 1 end   -- the game's RB (ISBuildingObject)
            if NS[faces[t.face]] ~= rb then okR = false end
            t = { face = k }
            stepL(t, 4)
            local lb = NS[faces[k]] - 1; if lb < 1 then lb = 4 end   -- the game's LB
            if NS[faces[t.face]] ~= lb then okL = false end
        end
        check("FACE: > steps the way RB turns the cursor", okR)
        check("FACE: < steps the way LB turns it", okL)
    end
    check("FACE: the face shown is left on the state for Build", has(OCP, "t.obj.state._buildFace = { name = t.entry.name, nSprite = NSPRITE_OF[face.idx] }"))
    check("FACE: each face keeps its game index", has(OCP, "tiles = {}, idx = i }"))
end

-- ---------------------------------------------------------------------------
print("-- ESC (B4): a cursor up wins over the recipe card")
do
    local src = cut(PR, "local function onKey(key)", "\nend\n")
    check("ESC: onKey found in Prompts.lua", src ~= nil)
    if src then
        local fn, e = loadstring("local previousToggle, isEscape = ...\n" .. src .. "return onKey", "onKey")
        check("ESC: onKey loads", fn ~= nil, e)
        if fn then
            local toggled, taken = 0, 0
            ZeD = { Safe = { on = function() return false end }, Prompt = nil,
                EscapeTakers = { recipeCard = function() taken = taken + 1; return true end } }
            MainScreen = nil
            Keyboard = { KEY_RETURN = 28, KEY_NUMPADENTER = 156 }
            local onKey = fn(function() toggled = toggled + 1 end, function(k) return k == 1 end)
            drags[0] = { Type = "ISBuildIsoEntity" }
            onKey(1)
            check("ESC: with the cursor up the card's taker is skipped and the game's Escape gets the key", taken == 0 and toggled == 1,
                "taken " .. taken .. ", toggled " .. toggled)
            drags[0] = nil
            onKey(1)
            check("ESC: with no cursor the card still takes Escape first", taken == 1 and toggled == 1, "taken " .. taken .. ", toggled " .. toggled)
        end
    end
end

-- ---------------------------------------------------------------------------
print("-- SKILL (B10): the card names the skill; Unknown only when not known")
do
    local src = cut(CCS, "function CC.shortSkillText(recipe, playerObj)", "\nend\n")
    check("SKILL: CC.shortSkillText found in CraftingCore.lua", src ~= nil)
    if src then
        local fn, e = loadstring("local CC = {}\n" .. src .. "return CC", "shortSkillText")
        check("SKILL: it loads", fn ~= nil, e)
        if fn then
            local C = fn()
            local words = { IGUI_CraftingWindow_Requires2 = "Requires", IGUI_CraftingWindow_Level = "Level" }
            getText = function(k) return words[k] or k end
            local function perk(nm) return { getName = function() return nm end } end
            local function req(p, lv) return { getPerk = function() return p end, getLevel = function() return lv end } end
            local carp, tail = perk("Carpentry"), perk("Tailoring")
            local recipe = { reqs = { req(tail, 1), req(carp, 3) } }
            function recipe:getRequiredSkillCount() return #self.reqs end
            function recipe:getRequiredSkill(i) return self.reqs[i + 1] end
            local lv = { Carpentry = 2, Tailoring = 4 }
            local pl = { getPerkLevel = function(_, p) return lv[p:getName()] or 0 end }
            CraftRecipeManager = nil
            check("SKILL: the second skill short is named in the game's words", C.shortSkillText(recipe, pl) == "Requires Carpentry Level 3",
                C.shortSkillText(recipe, pl))
            lv.Carpentry = 3
            check("SKILL: all met: none", C.shortSkillText(recipe, pl) == nil)
            CraftRecipeManager = { hasPlayerRequiredSkill = function(rs) return rs:getPerk() ~= tail end }
            check("SKILL: the game's own check (CraftRecipeManager) is asked first", C.shortSkillText(recipe, pl) == "Requires Tailoring Level 1")
            CraftRecipeManager = nil
        end
    end
    check("SKILL: Unknown is drawn only when the recipe is not known", has(CCS, "if rd.learned == false then\n        bw = A.drawBadge(panel, ZeD.tr(\"UI_ZeD_Craft_BadgeUnknown\")"))
    check("SKILL: the old rule (Unknown for short of skill) is gone", not has(CCS, "local isAccessible = rd.learned and (rd.hasSkill ~= false)"))
    check("SKILL: the skill chip, outside the Journal", has(CCS, "local needSkill = (rd.hasSkill == false and not config.readOnly) and CC.shortSkillText(entry.recipe, playerObj) or nil"))
    check("SKILL: on a chip row of its own, the card's width (the rerun: it was cut to Req...)", has(CCS, "if needSkill then chipH = chipH * 2 + T.px(4) end")
        and has(CCS, "A.drawBadge(panel, need, x + T.px(6), curY + T.px(26), \"danger\", nil, nil, true)"))
    check("HALF: on a tab too narrow for two panes the card takes the list's place, with Back", has(CCS, "local stacked = (splitFrac > 0) and w < T.px(CC.PANE_W_SPLIT) * 2")
        and has(CCS, "if stacked then listW, cardW = 0, w end") and has(CCS, 'type = "cardBack"') and has(CCS, 'elseif zone.type == "cardBack" then'))
    check("STAR: the split list never wider than the tab (half card, cr_tab case 10)", has(CCS, "if listW > w then listW = w end"))
    check("FACE: the preview's Build reads the facing at the press", has(readFile(Z .. "ObjectCardPreview.lua"), "o.state._buildFace = { name = tc.entry.name, nSprite = NSPRITE_OF[fc.idx] }"))
end

-- ---------------------------------------------------------------------------
print("-- WIRED")
check("WIRED (B5): the World window's close drops the Build tab's cursor",
    has(cut(WW, "local function _closeWorldWindow(w)", "\nend\n"), "ZeD.BuildingTab.dropCursor, w.playerNum or 0"))
check("WIRED (B11): the Build tab's stops get the card's B", has(WW, "ZeD.BuildingTab.cardCancels(win, els)"))
check("WIRED (B3): startBuild holds while a build is under way",
    has(cut(BT, "function ZeD.BuildingTab.startBuild(win, state)", "\nend\n"), "if ZeD.BuildingTab.buildInProgress(pn) then return end"))
check("WIRED (B2): the cursor's logic gets the game's listeners",
    has(BT, 'logic:addEventListener("onStopCraft", onStop, a)') and has(BT, 'logic:addEventListener("onUpdateContainers", onContainers, a)'))

print("cb_build_fixes_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
