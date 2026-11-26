-- ZeDUI/tools/qa/cb_calls_build_sim.lua  (the director's calls 5, 6 and 7 on the Build tab, Nov 25 2026, "1 on all")
-- The real functions cut out of BuildingTab.lua and CraftingCore.lua, the game stubbed:
--   DOUBLE  call 5: a double-click on a Build recipe row starts placing it (Build pressed on its card); one click, two
--           slow clicks, two on different rows, a click on a hidden row or with a list open do not. Pad: A on a row
--           opens the card with the focus on Build (one press more)
--   ALL     call 6: the Build list opens on Show: All; a row short of skill carries that skill ("Carpentry 3") as a tag
--           in the danger color; the Craft tab's default is untouched
--   PICK    call 7: the materials chosen on the build card go on the build's logic in manual select, only the chosen
--           type in its slot, the others the game's own; Build runs the tab's start with them (not the craft's
--           handcraft start); the B7 move carries the chosen items; a build that ends offers the same type again;
--           chosen items that no longer cover the build start nothing and say so; pad B in the list leaves it first
-- Run from the repo root:  lua51 ZeDUI/tools/qa/cb_calls_build_sim.lua
-- It prints FAIL lines and a last line "cb_calls_build_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]cb_calls_build_sim%.lua$", "")
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
local CCS = readFile(Z .. "CraftingCore.lua") or ""
local MOL = readFile(Z .. "Molecules.lua") or ""
local WW  = readFile(Z .. "ZeD_WorldWindow.lua") or ""
local CT  = readFile(Z .. "CraftingTab.lua") or ""
check("SOURCE: the files read", #BT > 0 and #CCS > 0 and #MOL > 0 and #WW > 0 and #CT > 0)

-- Java-like lists
local function jlist(t)
    t = t or {}
    return { _t = t,
        size = function() return #t end,
        get = function(_, i) return t[i + 1] end,
        add = function(_, x) t[#t + 1] = x end,
        contains = function(_, x) for _, v in ipairs(t) do if v == x then return true end end return false end }
end

-- ---------------------------------------------------------------------------
print("-- DOUBLE (call 5): a double-click on a row starts placing")
do
    local src = cut(BT, "ZeD.BuildingTab.DOUBLE_MS = 300", "\n    return took\nend\n")
    check("DOUBLE: rowAt and onClick found in BuildingTab.lua", src ~= nil)
    if src then
        local now = 1000
        getTimestampMs = function() return now end
        ZeD = { BuildingTab = {} }
        local started = 0
        local startFn = function() end
        local CCd = {
            onClick = function(state, cfg, win, x, y)
                for _, z in ipairs(state.zones) do
                    if z.type == "recipeRow" and y >= z.y and y < z.y + z.h then
                        if state.selected ~= z.id then state.selected = z.id end
                        return true
                    end
                end
                return false
            end,
            runStart = function(win, state, sa) if sa == startFn then started = started + 1 end end,
        }
        local cfg = { startAction = startFn }
        local state = { zones = {
            { type = "recipeRow", id = "Crate", x = 0, y = 0, w = 200, h = 24 },
            { type = "recipeRow", id = "Cross", x = 0, y = 24, w = 200, h = 24 },
            { type = "recipeRow", id = "Hidden", x = 0, y = 400, w = 200, h = 24 },
        }, _listGeo = { viewY = 0, viewH = 300 } }
        local fn, e = loadstring("local CC, buildConfig, getState = ...\n" .. src, "onClick cut")
        check("DOUBLE: the cut loads", fn ~= nil, e)
        if fn then
            fn(CCd, cfg, function() return state end)
            local win = {}
            local click = ZeD.BuildingTab.onClick
            click(win, 10, 5)
            check("DOUBLE: one click opens the card, starts nothing", state.selected == "Crate" and started == 0)
            now = now + 200
            click(win, 10, 5)
            check("DOUBLE: a second click on the row within 300 ms starts placing (Build on its card)", started == 1, started)
            now = now + 100
            click(win, 10, 5)
            check("DOUBLE: a third click begins a new pair, starts nothing more", started == 1, started)
            now = now + 1000
            click(win, 10, 5); now = now + 400; click(win, 10, 5)
            check("DOUBLE: two clicks 400 ms apart do not start", started == 1, started)
            now = now + 1000
            click(win, 10, 5); now = now + 100; click(win, 10, 30)
            check("DOUBLE: a click on one row then another does not start", started == 1 and state.selected == "Cross", started)
            now = now + 1000
            click(win, 10, 405); now = now + 100; click(win, 10, 405)
            check("DOUBLE: a row outside the list's view never starts", started == 1, started)
            now = now + 1000
            state.showMenuOpen = true
            click(win, 10, 30); now = now + 100; click(win, 10, 30)
            check("DOUBLE: with a list open the clicks only shut it, nothing starts", started == 1, started)
            state.showMenuOpen = nil
            now = now + 1000
            click(win, 10, 30); now = now + 100; click(win, 10, 30)
            check("DOUBLE: the open row's double-click starts too", started == 2, started)
        end
    end
    check("DOUBLE (pad): A on a row jumps the focus to the card's Build, one press more",
        has(WW, 'elseif win._activeTab == "build" then pendingState = win._buildState end') and has(WW, 'if e.craftKind == "actBuild" then'))
end

-- ---------------------------------------------------------------------------
print("-- ALL (call 6): the list opens on All, short rows marked")
do
    check("ALL: the Build tab's state opens on Show: All", has(BT, 'win._buildState.show = "all"') and not has(BT, 'win._buildState.show = "known"'))
    local cs = cut(CCS, "function CC.createState()", "\nend\n")
    check("ALL: CC.createState found", cs ~= nil)
    if cs then
        ZeD_ScrollbarState = { new = function() return { setScrollPos = function() end } end }
        local CC0 = {}
        local f = loadstring("local CC = ...\n" .. cs)
        f(CC0)
        local st = CC0.createState()
        check("ALL: the shared state sets no Show (the Craft tab keeps its own default)", st.show == nil and st.activeCat == "all")
    end
    check("ALL: the Craft tab's state is not opened on All here", not has(CT, '.show = "all"'))

    local src = cut(BT, "local function skillTagOf(entry, playerObj)", "\nend\n")
    check("ALL: skillTagOf found", src ~= nil)
    if src then
        local f = loadstring(src .. "return skillTagOf")()
        local levels = { Woodwork = 1, Metal = 0 }
        local function perk(n, shown) return { name = n, getName = function() return shown end } end
        local function rs(p, lv) return { getPerk = function() return p end, getLevel = function() return lv end } end
        local wood, metal = perk("Woodwork", "Carpentry"), perk("Metal", "Metalworking")
        local player = { getPerkLevel = function(_, p) return levels[p.name] or 0 end }
        local function recipe(list)
            return { getRequiredSkillCount = function() return #list end, getRequiredSkill = function(_, i) return list[i + 1] end }
        end
        local e1 = { recipe = recipe({ rs(wood, 3) }) }
        check("ALL: a recipe short of Carpentry 3 is tagged \"Carpentry 3\"", f(e1, player) == "Carpentry 3", f(e1, player))
        local t1 = f(e1, player)
        check("ALL: the tag's words are kept (no new string each refresh)", f(e1, player) == t1 and e1._skillTags ~= nil)
        local e2 = { recipe = recipe({ rs(wood, 1), rs(metal, 2) }) }
        check("ALL: the first skill short is the one named (the second here)", f(e2, player) == "Metalworking 2", f(e2, player))
        levels.Metal = 2
        check("ALL: no skill short: no tag", f(e2, player) == nil)
        check("ALL: no recipe: no tag", f({}, player) == nil)
    end
    check("ALL: the row's tag is set from the short skill on each refresh",
        has(BT, "rd.skillTag = (not hasSkill) and skillTagOf(entry, playerObj) or nil"))
    check("ALL: the list draws the skill as the row's tag, marked danger",
        has(CCS, "rowData.tag = rd.stationTag or rd.skillTag") and has(CCS, "rowData.tagDanger = (rd.stationTag == nil and rd.skillTag ~= nil) or nil"))
    check("ALL: the row draws a danger tag in the danger color with its mark, measured with the mark",
        has(MOL, "tg.textColor = onFocus and T.textOnFocus or (data.tagDanger and (T.dangerText or T.danger) or nil)")
        and has(MOL, "data.tagDanger and T.danger or nil, tg)") and has(MOL, "tagW = A.tagW(data.tag, data.tagDanger and true or false)"))
    check("ALL: Show: All keeps a short row listed (the filter's rule)", has(CCS, 'if not searchOut and not searching and show ~= "all" and entry.name ~= state.selected'))
end

-- ---------------------------------------------------------------------------
print("-- PICK (call 7): the chosen materials on the build's logic")
ResourceType = { Item = "Item" }
local function item(ft, cont) return { ft = ft, cont = cont, getFullType = function(s) return s.ft end, getContainer = function(s) return s.cont end } end
local function script(name, need, valid) return { name = name, need = need, valid = valid, getResourceType = function() return "Item" end } end
local PLANK = script("planks", 2, { ["Base.Plank"] = true, ["Base.PlankOak"] = true })
local NAILS = script("nails", 3, { ["Base.Nails"] = true })
local SAW   = script("saw", 1, { ["Base.Saw"] = true })   -- (a tool: kept, put back)
local canPerform = true
local logics = {}
local function newLogic()
    local l = { listeners = {}, inProgress = false, manual = false, filter = nil, auto = 0, containersSet = 0, slots = {} }
    for _, s in ipairs({ PLANK, NAILS, SAW }) do
        local sl = { script = s, items = {} }
        function sl:isInputItemsSatisfied() return #self.items >= self.script.need end
        l.slots[s] = sl
    end
    function l:getAllBuildableRecipes() return {} end
    function l:setRecipes() end
    function l:setRecipe(r) self.recipe = r end
    function l:setContainers(c)
        self.containersSet = self.containersSet + 1
        local changed = self.containers == nil or self.containers.at ~= c.at
        self.containers = c
        return changed
    end
    function l:setManualSelectInputs(on) self.manual = on end
    function l:setManualSelectInputScriptFilter(s) self.filter = s end
    function l:autoPopulateInputs()
        self.auto = self.auto + 1
        for s, sl in pairs(self.slots) do
            sl.items = {}
            for ci = 0, self.containers:size() - 1 do
                local its = self.containers:get(ci):getItems()
                for j = 0, its:size() - 1 do
                    local it = its:get(j)
                    if #sl.items < s.need and s.valid[it.ft] then sl.items[#sl.items + 1] = it end
                end
            end
        end
    end
    function l:clearManualInputsFor(sl) sl.items = {} end
    function l:offerInputItem(it)
        local sl = self.filter and self.slots[self.filter]
        if sl and not sl:isInputItemsSatisfied() and self.filter.valid[it.ft] then sl.items[#sl.items + 1] = it end
    end
    function l:getRecipeData()
        local me = self
        return {
            getDataForInputScript = function(_, s) return me.slots[s] end,
            getAllInputItems = function()
                local t = {}
                for _, s in ipairs({ PLANK, NAILS, SAW }) do for _, it in ipairs(me.slots[s].items) do t[#t + 1] = it end end
                return jlist(t)
            end,
            getAllPutBackInputItems = function() return jlist(me.slots[SAW].items) end,
        }
    end
    function l:canPerformCurrentRecipe()
        if not canPerform then return false end
        -- (out of manual select the game fills the slots itself for its check; counted apart from the picks' fill)
        if not self.manual then local n = self.auto; self:autoPopulateInputs(); self.auto = n end
        for _, sl in pairs(self.slots) do if not sl:isInputItemsSatisfied() then return false end end
        return true
    end
    function l:getSelectedBuildObject() return { name = "info" } end
    function l:getWallCoveringParams() return nil end
    function l:addEventListener(name, fn, target) self.listeners[name] = { fn = fn, target = target } end
    function l:isCraftActionInProgress() return self.inProgress end
    function l:stopCraftAction()
        self.inProgress = false
        local L = self.listeners.onStopCraft
        if L then L.fn(L.target) end
    end
    logics[#logics + 1] = l
    return l
end

-- the containers: the inventory and a crate, the crate holding both plank kinds, nails and the saw
local INV = { name = "inv" }
local CRATE = { name = "crate" }
local invItems, crateItems = {}, {}
INV.getItems = function() return jlist(invItems) end
CRATE.getItems = function() return jlist(crateItems) end
local function put(cont, list, ft, n) for _ = 1, n do list[#list + 1] = item(ft, cont) end end
put(CRATE, crateItems, "Base.Plank", 3)
put(CRATE, crateItems, "Base.PlankOak", 2)
put(CRATE, crateItems, "Base.Nails", 5)
put(INV, invItems, "Base.Saw", 1)
local PX = 10
local function contList() local c = jlist({ INV, CRATE }); c.at = tostring(PX); return c end

do
    local src = cut(BT, "local function applyPicks(logic, entry, picks, containers)", "\nend\n")
    check("PICK: applyPicks found in BuildingTab.lua", src ~= nil)
    if src then
        local applyPicks = loadstring(src .. "return applyPicks")()
        local entry = { inputDefs = { { inputRef = PLANK }, { inputRef = NAILS }, { inputRef = SAW } } }
        local L = newLogic(); L:setContainers(contList())
        check("PICK: no picks: the logic is left as it is (the game's own choice)", applyPicks(L, entry, nil, contList()) == false and L.manual == false and L.auto == 0)
        check("PICK: an empty picks table: left as it is", applyPicks(L, entry, {}, contList()) == false and L.manual == false)
        local ok = applyPicks(L, entry, { [1] = "Base.PlankOak" }, contList())
        local pl = L.slots[PLANK].items
        check("PICK: picks put on: manual select on, the game's fill first", ok == true and L.manual == true and L.auto == 1)
        check("PICK: the chosen slot holds only the chosen type, as many as it needs",
            #pl == 2 and pl[1].ft == "Base.PlankOak" and pl[2].ft == "Base.PlankOak", #pl .. " " .. tostring(pl[1] and pl[1].ft))
        check("PICK: the other slots keep the game's fill", #L.slots[NAILS].items == 3 and #L.slots[SAW].items == 1)
        check("PICK: the slot filter is cleared after", L.filter == nil)
        check("PICK: the logic can build with them", L:canPerformCurrentRecipe() == true)
        local L2 = newLogic(); L2:setContainers(contList())
        applyPicks(L2, entry, { [1] = "Base.Plank", [2] = "Base.Nails" }, contList())
        check("PICK: two slots chosen, each its own type", L2.slots[PLANK].items[1].ft == "Base.Plank" and #L2.slots[NAILS].items == 3)
    end
end

-- startBuild and the cursor's upkeep, with the picks
do
    local drags = {}
    getCell = function() return { getDrag = function(_, pn) return drags[pn] end, setDrag = function(_, d, pn) drags[pn] = d end } end
    local player = {
        getPlayerNum = function() return 0 end,
        getCurrentSquare = function() return { getX = function() return PX end, getY = function() return 10 end, getZ = function() return 0 end } end,
        isBuildCheat = function() return false end,
        getInventory = function() return INV end,
    }
    local playerUpdate = nil
    Events = { OnPlayerUpdate = { Add = function(fn) playerUpdate = fn end, Remove = function() end } }
    BuildLogic = { new = function() return newLogic() end }
    local baseTry = {}
    ISBuildIsoEntity = { tryBuild = function(self) baseTry[#baseTry + 1] = self end }
    ISBuildIsoEntity.new = function(self, character, info, nSprite, containers, logic)
        return setmetatable({ character = character, objectInfo = info, nSprite = nSprite, containers = containers,
            buildPanelLogic = logic }, { __index = ISBuildIsoEntity })
    end
    local moved = {}
    ISInventoryPaneContextMenu = { transferIfNeeded = function(p, it) moved[#moved + 1] = it end }
    local queue = { queue = {} }
    ISTimedActionQueue = { getTimedActionQueue = function() return queue end }
    local said = {}
    HaloTextHelper = { addBadText = function(p, t) said[#said + 1] = t end }
    getText = function(k) return k end
    local returned = nil
    local CCstub = {
        craftContainers = function() return contList() end,
        incrementCraftCount = function() end,
        returnCraftInputs = function(p, list) returned = list end,
        closeCraft = function(st) st.selected = nil end,
        exitAltMode = function(st) st.altSlotName = nil end,
    }
    ZeD = { BuildingTab = {} }
    local up = cut(BT, "local _active = {}", "\nfunction ZeD.BuildingTab.buildInProgress(pn)")
    local up2 = cut(BT, "function ZeD.BuildingTab.buildInProgress(pn)", "\nend\n")
    local sb = cut(BT, "function ZeD.BuildingTab.startBuild(win, state)", "\nend\n")
    local cc = cut(BT, "local CARD_KINDS =", "\nend\n")
    check("PICK: the upkeep, startBuild and cardCancels found", up ~= nil and up2 ~= nil and sb ~= nil and cc ~= nil)
    if up and up2 and sb and cc then
        up = string.gsub(up, "\nfunction ZeD%.BuildingTab%.buildInProgress%(pn%)\n$", "\n")
        local fn, e = loadstring("local CC, _recipeByName, getTool = ...\n" .. up .. up2 .. sb .. cc .. "return _active\n", "BuildingTab cut")
        check("PICK: the cut loads", fn ~= nil, e)
        if fn then
            local recipe = { getToolBoth = function() end, getToolRight = function() end, getToolLeft = function() end }
            local entry = { name = "Crate", recipe = recipe, inputDefs = { { inputRef = PLANK }, { inputRef = NAILS }, { inputRef = SAW } } }
            local active = fn(CCstub, { Crate = entry }, function() return nil end)
            local win = { _playerObj = player }
            local state = { selected = "Crate", picks = { Crate = { [1] = "Base.PlankOak" } } }
            ZeD.BuildingTab.startBuild(win, state)
            local c = drags[0]
            local L = logics[#logics]
            check("PICK: Build with a pick starts the cursor on a logic in manual select", c ~= nil and c.buildPanelLogic == L and L.manual == true)
            check("PICK: the cursor's logic holds the chosen planks", L.slots[PLANK].items[1].ft == "Base.PlankOak" and L.slots[PLANK].items[2].ft == "Base.PlankOak")
            state.picks.Crate[1] = "Base.Plank"
            check("PICK: a pick changed on the card later does not change the cursor's", active[0].picks[1] == "Base.PlankOak")
            state.picks.Crate[1] = "Base.PlankOak"

            -- the B7 move carries the chosen items
            moved = {}
            c:tryBuild(1, 2, 0)
            local oak = 0
            for _, it in ipairs(moved) do if it.ft == "Base.PlankOak" then oak = oak + 1 end end
            local plain = 0
            for _, it in ipairs(moved) do if it.ft == "Base.Plank" then plain = plain + 1 end end
            check("PICK (B7): the move before the walk carries the chosen planks, not others", oak == 2 and plain == 0, oak .. " oak, " .. plain .. " plain")
            check("PICK (B7): the saw already carried is not moved", (function() for _, it in ipairs(moved) do if it.ft == "Base.Saw" then return false end end return true end)())
            check("PICK (B7): the game's tryBuild ran", #baseTry == 1)

            -- a build ended: the same type offered again
            local auto0 = L.auto
            L.inProgress = true
            L:stopCraftAction()
            check("PICK: a build ended: the chosen type is offered again for the next", L.auto == auto0 + 1 and L.slots[PLANK].items[1].ft == "Base.PlankOak")

            -- the player moves before placing: offered again from what is in reach; not while a build is under way
            local a0 = L.auto
            PX = 11
            playerUpdate(player)
            check("PICK: moved a square, nothing under way: the picks offered again", L.auto == a0 + 1)
            L.inProgress = true
            PX = 12
            playerUpdate(player)
            check("PICK: moved while a build is under way: the picks are left alone", L.auto == a0 + 1)
            L.inProgress = false

            -- no picks: the game's own fill, as before
            drags[0] = nil
            ZeD.BuildingTab.startBuild(win, { selected = "Crate" })
            local L3 = logics[#logics]
            check("PICK: no picks: the logic is not put in manual select", drags[0] ~= nil and L3.manual == false and active[0].picks == nil)

            -- the chosen type is gone: nothing starts, the game's words said
            drags[0] = nil
            local n0 = #said
            ZeD.BuildingTab.startBuild(win, { selected = "Crate", picks = { Crate = { [2] = "Base.NailsGone" } } })
            check("PICK: a chosen type not in reach: no cursor, the game's words said",
                drags[0] == nil and #said == n0 + 1 and said[#said] == "IGUI_CraftingWindow_Error_Inputs", tostring(said[#said]))
            drags[0] = nil
            canPerform = false
            local n1 = #said
            ZeD.BuildingTab.startBuild(win, { selected = "Crate" })
            check("PICK: no picks and the game says no: nothing said, as before", drags[0] == nil and #said == n1)
            canPerform = true

            -- pad B in the alternatives list leaves the list first, then shuts the card
            ZeD.Input = { Focus = { focusByIdSoon = function() end } }
            local st = { selected = "Crate", altSlotName = "planks" }
            local els = { { craftKind = "altPick" }, { craftKind = "altBack" }, { craftKind = "altOwned" } }
            ZeD.BuildingTab.cardCancels({ _buildState = st }, els)
            check("PICK (pad): the list's stops get a B", els[1].onCancel ~= nil and els[2].onCancel ~= nil and els[3].onCancel ~= nil)
            check("PICK (pad): B in the list leaves it, the card stays", els[1].onCancel({}, els[1]) == true and st.altSlotName == nil and st.selected == "Crate")
            check("PICK (pad): B again shuts the card", els[2].onCancel({}, els[2]) == true and st.selected == nil)
        end
    end
end

-- the Build key runs the tab's own start with the picks, never the craft's handcraft start
do
    local src = cut(CCS, "function CC.runStart(win, state, startAction)", "\nend\n")
    check("PICK: CC.runStart found", src ~= nil)
    if src then
        local CC0 = {}
        loadstring("local CC = ...\n" .. src)(CC0)
        local picked, own = 0, 0
        CC0.startPickedCraft = function() picked = picked + 1; return true end
        local sa = function() own = own + 1 end
        CC0.runStart({}, { _pickOn = true, config = { ownPicks = true } }, sa)
        check("PICK: Build (ownPicks): the tab's start runs, the craft's picked start does not", own == 1 and picked == 0)
        CC0.runStart({}, { _pickOn = true, config = { prefix = "craft" } }, sa)
        check("PICK: Craft keeps its picked start", own == 1 and picked == 1)
    end
    check("PICK: the Build config turns the pick list on and keeps its own start",
        has(BT, "pickIngredients = true,") and has(BT, "ownPicks        = true,"))
    check("PICK: the pick list follows the config (mouse: altPick zone; pad: altPick stops)",
        has(CCS, "local pickOn = config.pickIngredients") and has(CCS, 'elseif zone.type == "altPick" then')
        and has(CCS, 'id = prefix .. ":altPick:" .. tostring(z.id),'))
    check("PICK: the double-click and the Build key share the start (runStart)", has(BT, "CC.runStart(win, state, buildConfig.startAction)"))
end

print("cb_calls_build_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
