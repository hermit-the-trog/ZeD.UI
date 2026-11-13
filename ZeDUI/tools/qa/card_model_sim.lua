-- ZeDUI/tools/qa/card_model_sim.lua  (Nov 7 2026, Build; the outside performance review, item 9): the item card keeps
-- its model (the marks, the header verbs, the top stats, the facts panel, the kind) for a moment instead of building
-- it every frame (ItemCardOrganism.lua, THE CARD'S MODEL), with no game running.
-- Two copies of the card run side by side on the same stub world, each in its own globals:
--   OLD  the card files as they were before the change (git show of BASE; with no git, the new files with the clock
--        taken away, which builds the model every frame as before)
--   NEW  the card files in the working tree
-- Every frame each card draws into its own log (every draw call and every molecule's arguments, tables written out
-- whole). The logs must match frame by frame, across: steady frames; condition; uses; fluid; rounds; a bite eaten;
-- the pages read; a bag's contents; worn, then dropped on the ground, then into a crate (the item moving container);
-- a mark set from the card; a loadout changed and the Loadouts switch; an action starting, ticking, turning
-- dangerous and ending (ItemActionManager); a mod registering a facts panel; the language; the test language; the
-- theme and the text size (a new ZeD.T); a fold toggled; another item set and back; the drawer narrowed.
-- Then it counts the calls into the game (each item, player or container getter) and the ZeD.tr calls per frame,
-- OLD against NEW, while a card just sits there.
-- A change the card has no reading for (poison put in food) shows within MODEL_MS: the sim measures it.
-- And (Nov 8 2026, code flags) a fold on a drawer card keeps the scroll: ItemCard:_toggleFold clamps with the height
-- renderBody drew, no longer the old layout's shorter _calcBodyH (the old card is shown jumping).
-- And (Nov 12 2026, the tab catalog's review) the Kind row is the game's word for the kind (the inventory's
-- catLabel), and a container's capacity is the one load format (Atoms.loadText), carried into the old files.
-- What it can't show is the game itself: the frame time with a card open, in the game.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/card_model_sim.lua
-- It prints FAIL lines and a last line "card_model_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]card_model_sim%.lua$", "")
local BASE = "7f17686e"   -- main before the change

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

local function readFile(rel)
    local f = io.open(ROOT .. rel, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end
local function gitShow(rel)
    local p = io.popen('git -C "' .. (ROOT ~= "" and (ROOT:gsub("[/\\]+$", "")) or ".") .. '" show ' .. BASE .. ":" .. rel .. " 2>nul")
    if not p then return nil end
    local s = p:read("*a")
    p:close()
    if not s or #s < 200 then return nil end
    return (string.gsub(s, "\r\n", "\n"))
end
-- the text from the first `from` to the end of the line where the first `to` after it ends (plain finds)
local function cut(src, from, to)
    local a = string.find(src, from, 1, true)
    if not a then return nil end
    local b = string.find(src, to, a, true)
    if not b then return nil end
    local e = string.find(src, "\n", b + #to, true) or #src
    return string.sub(src, a, e)
end

-- ---------------------------------------------------------------------------
-- THE WORLD (shared by both cards): game objects whose every getter call is counted
-- ---------------------------------------------------------------------------
local CALLS = 0
local function Obj(name, fields, is)
    local o = { _name = name, _f = fields, _is = is or {} }
    return setmetatable(o, { __index = function(_, k)
        local v = fields[k]
        if v == nil then return nil end
        return function(self, ...)
            CALLS = CALLS + 1
            if type(v) == "function" then return v(self, ...) end
            return v
        end
    end })
end
local function jlist(t)
    return Obj("list", { size = function() return #t end, get = function(_, i) return t[i + 1] end })
end

local LANG = "en"
local function getTextStub(k, ...)
    local s = LANG .. ":" .. tostring(k)
    local a = { ... }
    for i = 1, #a do s = s .. ":" .. tostring(a[i]) end
    return s
end

local PLAYER_INV = Obj("playerInv", { getType = "none" })
local FLOOR = Obj("floor", { getType = "floor" })
local CRATE = Obj("crate", { getType = "crate" })
local READ = { ["Base.Book"] = 10 }
local PMD = {}
local PLAYER = Obj("player", {
    getInventory = PLAYER_INV, getModData = PMD, getPlayerNum = 0,
    getAlreadyReadPages = function(_, ft) return READ[ft] or 0 end,
})

local function itemBase(name, ft, f)
    f.getFullType = ft
    f.getDisplayName = name
    f.getContainer = f.getContainer or PLAYER_INV
    f.getScriptItem = Obj("script:" .. ft, {})
    f.isEquipped = f.isEquipped or false
    f.isFavorite = false
    f.isNoRecipes = false
    f.isUnwanted = false
    f.getModData = {}
    f.getActualWeight = f.getActualWeight or 1
    f.setFavorite = function(self, v) self._f.isFavorite = v and true or false end
    f.setNoRecipes = function(self, _, v) self._f.isNoRecipes = v and true or false end
    f.setUnwanted = function(self, _, v) self._f.isUnwanted = v and true or false end
    return f
end
local FLUID = { amt = 0.8 }
local FC = Obj("fluidContainer", { getAmount = function() return FLUID.amt end, isEmpty = function() return FLUID.amt <= 0 end })
local BAG_ITEMS = { 1, 2, 3 }
local BAG_INV = Obj("bagInv", { getCapacity = 15, getContentsWeight = function() return #BAG_ITEMS * 1.5 end,
    getItems = function() return jlist(BAG_ITEMS) end })

local ITEMS = {
    shirt = Obj("shirt", itemBase("Shirt", "Base.Shirt", {
        getCategory = "Clothing", getCondition = 8, getConditionMax = 10, getFabricType = "Cotton",
        getCombatSpeedModifier = 1.0, getRunSpeedModifier = 0.95, IsClothing = true, getBiteDefense = 10,
        getScratchDefense = 20, getBulletDefense = 0, getInsulation = 0.35, getWindresistance = 0.2,
        getWaterResistance = 0.1, getCanHaveHoles = true, getDisplayCategory = "Clothing", getBodyLocation = "Shirt",
        getDirtiness = 0, getBloodLevel = 0,
    }), { Clothing = true }),
    apple = Obj("apple", itemBase("Apple", "Base.Apple", {
        getCategory = "Food", getCondition = 1, getHungerChange = -0.15, getThirstChange = -0.05, getCalories = 95,
        getProteins = 0.5, getLipids = 0.3, getCarbohydrates = 25, getPoisonPower = 0, getBoredomChange = 0,
        getUnhappyChange = 0, isCooked = false, isBurnt = false, isbDangerousUncooked = false, isRotten = false,
        isFresh = true, getDisplayCategory = "Food",
    }), { Food = true }),
    bat = Obj("bat", itemBase("Bat", "Base.BaseballBat", {
        getCategory = "Weapon", getCondition = 9, getConditionMax = 10, getMinDamage = 0.8, getMaxDamage = 1.2,
        getMinRange = 0.6, getMaxRange = 1.3, getSwingTime = 3, getPushBackMod = 0.5, getCriticalChance = 20,
        getDisplayCategory = "Weapon", getAmmoType = "",
    }), { HandWeapon = true }),
    pistol = Obj("pistol", itemBase("Pistol", "Base.Pistol", {
        getCategory = "Weapon", getCondition = 10, getConditionMax = 10, getMinDamage = 1, getMaxDamage = 2,
        getMinRange = 1, getMaxRange = 10, getSwingTime = 1, getPushBackMod = 0.3, getCriticalChance = 25,
        getDisplayCategory = "Firearm", getAmmoType = "Base.Bullets9mm", getCurrentAmmoCount = 15, getMaxAmmo = 15,
    }), { HandWeapon = true }),
    book = Obj("book", itemBase("Book", "Base.Book", {
        getCategory = "Literature", getCondition = 1, getNumberOfPages = 220, getSkillTrained = "Carpentry",
        getLvlSkillTrained = 1, getMaxLevelTrained = 2, getDisplayCategory = "Literature",
        getLearnedRecipes = jlist({}), getAlreadyReadPages = 0,
    }), { Literature = true }),
    bag = Obj("bag", itemBase("Bag", "Base.Bag", {
        getCategory = "Container", getCondition = 1, getItemCapacity = 15, getInventory = BAG_INV,
        getWeightReduction = 60, getDisplayCategory = "Bag", canBeEquipped = "Back",
    }), { InventoryContainer = true }),
    lighter = Obj("lighter", itemBase("Lighter", "Base.Lighter", {
        getCategory = "Item", getCondition = 1, getUsedDelta = 0.6, getDisplayCategory = "Tool",
    }), { DrainableComboItem = true }),
    bottle = Obj("bottle", itemBase("Bottle", "Base.WaterBottle", {
        getCategory = "Item", getCondition = 1, getFluidContainer = FC, isSealed = false, getDisplayCategory = "Water",
    }), {}),
}

-- the item card's own stubs that both cards share
local LISTS = { on = true, gen = 1, hits = {} }
local Lists = {
    KINDS = { "loadout" },
    on = function() return LISTS.on end,
    listsWith = function(_, item) return LISTS.hits[item] or {} end,
    namesFor = function(_, item) local h = LISTS.hits[item] or {}; return h[1] and h[1].list.name or "" end,
    placeText = function(p) return "place:" .. tostring(p) end,
    ruleText = function(ln) return "rule:" .. tostring(ln.rule) end,
}
Lists.gen = 1
local ListsUI = { inText = function(_, item) local h = LISTS.hits[item]; return h and #h > 0 and "in " .. h[1].list.name or nil end }
local RI_ROWS = { ["Base.Shirt"] = { { rec = { displayName = "Rag" }, known = true } },
                  ["Base.Apple"] = { { rec = { displayName = "Apple pie" }, known = false } } }
local RecipeIndex = {
    forCard = function(_, si, max) return RI_ROWS[si._name:sub(8)] or {}, 0 end,
    open = noop, openAll = noop,
}

-- ---------------------------------------------------------------------------
-- A WRITER: tables written out whole, keys in order, the card as <card>
-- ---------------------------------------------------------------------------
local function ser(v, depth, card)
    local t = type(v)
    if t == "number" then
        if v == math.floor(v) then return tostring(v) end
        return string.format("%.6g", v)
    end
    if t == "string" then return string.format("%q", v) end
    if t == "boolean" or t == "nil" then return tostring(v) end
    if t == "function" then return "fn" end
    if t == "table" then
        if v == card then return "<card>" end
        if rawget(v, "_f") then return "<" .. tostring(v._name) .. ">" end
        if depth > 6 then return "{...}" end
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        local parts = {}
        for _, k in ipairs(keys) do parts[#parts + 1] = tostring(k) .. "=" .. ser(v[k], depth + 1, card) end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "<" .. t .. ">"
end

-- ---------------------------------------------------------------------------
-- A THEME: ZeD.T as applyTheme builds it (a new table on a theme or text size change)
-- ---------------------------------------------------------------------------
local function makeT(tint, fontH)
    local colors = {}
    local T = {
        px = function(n) return n end, line = function(n) return n end, hair = 1, borderW = 1,
        fontF1 = "f1", fontF2 = "f2", fontF3 = "f3", fontF4 = "f4",
        fontF1H = fontH, fontF2H = fontH, fontF4H = fontH + 4, fillBarH = 6, rowH = 20, inputH = 18,
        iconSm = 16, cardIconSz = 32,
        sp = setmetatable({}, { __index = function() return 4 end }),
    }
    return setmetatable(T, { __index = function(_, k)
        local c = colors[k]
        if not c then
            local h = 0
            for i = 1, #k do h = (h * 31 + string.byte(k, i)) % 997 end
            c = { r = (h % 10) / 10 + tint, g = 0.5, b = 0.25, a = 1 }
            colors[k] = c
        end
        return c
    end })
end

-- ---------------------------------------------------------------------------
-- ONE CARD IN ITS OWN GLOBALS
-- ---------------------------------------------------------------------------
local W, H = 300, 900
local function newEnv(label, sources, clock)
    local env = setmetatable({}, { __index = _G })
    env.label = label
    env.LOG = {}
    env.TR = 0
    local function rec(name, ...)
        local log = env.LOG
        local args = { ... }
        local parts = {}
        local n = select("#", ...)
        -- (a facts row's flush flag, added Nov 11 2026 for the "Used to make" rows, punch list 153: a change of look
        -- the director asked for, not of the model; left out of the log so OLD and NEW still compare the model, and
        -- checked on its own below)
        -- (the log leaves out the card itself: x is args[1], isSub args[7], needsProbe args[8], flush args[9])
        if name == "M.drawFactsRow" and n > 7 then
            if args[9] == true then env.FLUSH = (env.FLUSH or 0) + 1 end
            n = 7
        end
        for i = 1, n do parts[i] = ser(args[i], 0, env.card) end
        log[#log + 1] = name .. "(" .. table.concat(parts, ",") .. ")"
    end
    env.require = noop
    env.getTimestampMs = clock
    env.getText = getTextStub
    env.getPlayer = function() return PLAYER end
    env.getSpecificPlayer = function() return PLAYER end
    env.instanceof = function(o, cls) return type(o) == "table" and o._is and o._is[cls] or false end
    env.ISPanel = { derive = function() return {} end }
    env.ISTimedActionQueue = { add = noop }
    env.Events = setmetatable({}, { __index = function() return { Add = noop, Remove = noop } end })
    local Z = {}
    env.ZeD = Z
    Z._trGen = 1
    Z.TEST = false
    Z.trTestOn = function() return Z.TEST end
    Z.tr = function(k, ...)
        env.TR = env.TR + 1
        local s = (Z.TEST and "~" or "") .. LANG .. ":" .. tostring(k)
        local a = { ... }
        for i = 1, #a do s = s .. ":" .. tostring(a[i]) end
        return s
    end
    Z.textCase = function(s) return "tc(" .. tostring(s) .. ")" end
    Z.btnCase = function(s) return "bc(" .. tostring(s) .. ")" end
    Z.upper = function(s) return string.upper(tostring(s)) end
    Z.T = makeT(0, 10)
    Z.TM = {
        MeasureStringX = function(_, f, s) return 7 * #tostring(s) end,
        MeasureStringY = function() return 10 end,
        getFontHeight = function() return 10 end,
    }
    local function recorderTable(prefix, explicit)
        return setmetatable(explicit, { __index = function(t, k)
            local f = function(...) rec(prefix .. k, select(2, ...)); return 0 end
            rawset(t, k, f)
            return f
        end })
    end
    Z.Atoms = recorderTable("A.", {
        safeGet = function(item, m, ...)
            if not item then return nil end
            local fn = item[m]; if not fn then return nil end
            local ok, r = pcall(fn, item, ...); if ok then return r end; return nil
        end,
        wrapText = function(s) return { s } end,
        mouseIn = function() return false end,
        truncateText = function(s) return s end,
        textCase = function(s) return "tc(" .. tostring(s) .. ")" end,
        ammoOf = function(item) return nil, item._f.getAmmoType end,
    })
    -- the one way a load over a capacity is written (the real Atoms.loadText, Nov 12 2026: the Kind block's Capacity
    -- row and Container Facts write it), not a drawing: run, not logged
    do
        local at = readFile("42/media/lua/client/ZeD/Atoms.lua") or ""
        local a1 = string.find(at, "function ZeD.Atoms.loadText(load, cap)", 1, true)
        local b1 = a1 and string.find(at, "\nend\n", a1, true)
        if a1 and b1 then assert(loadstring("local ZeD = ...\n" .. string.sub(at, a1, b1 + 4), "=loadText"))(Z) end
    end
    Z.Molecules = recorderTable("M.", {
        drawCardBackBar = function(panel, x, y, w, name, verbs, progressActive, compact, outRects, opts)
            rec("M.drawCardBackBar", x, y, w, name, verbs, progressActive, compact, opts)
            for i = 1, #verbs do outRects.verbs[i] = { x = w - 40 * i, y = y, w = 36, h = 20 } end
            return 24
        end,
        drawCardFlagStrip = function(panel, x, y, w, marks, compact, outRects, opts)
            rec("M.drawCardFlagStrip", x, y, w, marks, compact, opts and opts.focusParts)
            outRects.fav = { x = 0, y = y, w = 10, h = 10 }
            return 18
        end,
        drawCardProgressBand = function(panel, x, y, w, item, compact, outRect, opts)
            local IAM = env.ZeD.ItemActionManager
            local a = IAM and IAM.getActiveAction(item)
            rec("M.drawCardProgressBand", x, y, w, item, compact, a)
            if not a then return 0 end
            outRect.x, outRect.y, outRect.w, outRect.h = w - 20, y, 16, 16
            return 30
        end,
        drawTopStatsList = function(panel, x, y, w, rows) rec("M.drawTopStatsList", x, y, w, rows); return 12 * #rows end,
        drawTopStatsGrid = function(panel, x, y, w, tex, rows) rec("M.drawTopStatsGrid", x, y, w, tex, rows); return 12 * #rows end,
        drawFactsTitle = function(panel, x, y, w, title, compact) rec("M.drawFactsTitle", x, y, w, title, compact); return 14 end,
        drawFactsRuleThick = function(panel, x, y, w) rec("M.drawFactsRuleThick", x, y, w); return 2 end,
        drawFactsRuleThin = function(panel, x, y, w) rec("M.drawFactsRuleThin", x, y, w); return 1 end,
        drawFactsRow = function(panel, x, y, w, ...) rec("M.drawFactsRow", x, y, w, ...); return 12 end,
        bandH = function() return 26 end,
        drawBand = function(panel, x, y, w, spec)
            rec("M.drawBand", x, y, w, spec)
            local out = { buttons = {} }
            for i = 1, #spec.buttons do out.buttons[i] = { x = 10 * i, y = y, w = 8, h = 8 } end
            return 26, out
        end,
        drawTag = function(...) rec("M.drawTag", select(2, ...)); return 0 end,
    })
    Z.Help = { set = function(_, s) rec("Help.set", s) end }
    Z.Focus = { mark = function() return false end }
    Z.Lists = Lists
    Z.ListsUI = ListsUI
    Z.RecipeIndex = RecipeIndex
    Z.Settings = {}

    -- the mark state (Atoms.lua's own getState / setState, cut out of the working tree)
    local atoms = readFile("42/media/lua/client/ZeD/Atoms.lua")
    local asSrc = "ZeD.ActionStrip = {}\nlocal _safeGet = ZeD.Atoms.safeGet\n"
        .. "local function _markPlayer(playerNum) return getSpecificPlayer(playerNum or 0) end\n"
        .. assert(cut(atoms, "function ZeD.ActionStrip.getState(", "\nend\n"), "getState")
        .. assert(cut(atoms, "function ZeD.ActionStrip.setState(", "\nend\n"), "setState")
    local fn = assert(loadstring(asSrc, "=ActionStrip"))
    setfenv(fn, env)
    fn()

    for _, s in ipairs(sources) do
        local f, err = loadstring(s.src, "=" .. label .. ":" .. s.name)
        assert(f, err)
        setfenv(f, env)
        local ok, e = pcall(f)
        check(label .. ": " .. s.name .. " loads on the stubs", ok, e)
    end
    -- the zones (ItemCard.lua's getClothingZones needs the game's clothing visuals): the same stub in both
    Z.ItemDetail.buildConfigs = function(item)
        CALLS = CALLS + 3
        if item ~= ITEMS.shirt then return {} end
        return { { name = "Upper Torso", pct = 80, bar = true, dock = { flag = "TORN", color = Z.T.warning, state = "active" },
                   action = "repair" },
                 { name = "Left Upper Arm", pct = 100, bar = true } }
    end
    Z.ItemDetail.buildItemSoil = function() return { dirt = true, wet = 20 } end
    Z.ItemDetail.drawSoilRow = function(...) rec("ItemDetail.drawSoilRow", select(2, ...)); return 12 end

    local card = setmetatable({
        playerNum = 0, mode = "drawer", sourceContext = "inventory", _scrollPixels = 0,
        _foldStates = { clothing_zones = true, food_nutrition = true, food_ingredients = false },
        _foldHitRects = {}, _zoneDockRects = {}, _headH = 0, pad = 4,
    }, { __index = env.ZeD_ItemCard })
    card.getWidth = function() return W end
    card.getHeight = function() return H end
    card.getAbsoluteX = function() return 100 end
    card.getAbsoluteY = function() return 50 end
    card.drawRect = function(_, ...) rec("drawRect", ...) end
    card.drawRectBorder = function(_, ...) rec("drawRectBorder", ...) end
    card.drawText = function(_, ...) rec("drawText", ...) end
    card.drawTextRight = function(_, ...) rec("drawTextRight", ...) end
    card.drawTextureScaledAspect = function(_, ...) rec("drawTexture", ...) end
    card.setStencilRect = function(_, ...) rec("stencil", ...) end
    card.clearStencilRect = function() rec("clearStencil") end
    env.card = card
    return env
end

-- ---------------------------------------------------------------------------
-- THE TWO CARDS
-- ---------------------------------------------------------------------------
local FILES = {
    { name = "ItemCard.lua",          rel = "42/media/lua/client/ZeD/ItemCard.lua" },
    { name = "ItemCardOrganism.lua",  rel = "42/media/lua/client/ZeD/ItemCardOrganism.lua" },
    { name = "ItemFactsPanel.lua",    rel = "42/media/lua/client/ZeD/ItemFactsPanel.lua" },
    { name = "ItemActionManager.lua", rel = "42/media/lua/client/ZeD/ItemActionManager.lua" },
}
local CLOCK = 100000
local function clock() return CLOCK end
local newSrc, oldSrc, haveBase = {}, {}, true
for _, f in ipairs(FILES) do
    newSrc[#newSrc + 1] = { name = f.name, src = assert(readFile(f.rel), f.rel) }
    local o = gitShow(f.rel)
    if not o then haveBase = false end
    oldSrc[#oldSrc + 1] = { name = f.name, src = o }
end
-- (Nov 11 2026, tab review item 3) the Kind block's Capacity row now reads the bag's weight ("4.5 / 15 kg", as
-- Container Facts), no longer getItemCapacity (-1 on a real bag): a change made on purpose, so the old card is
-- given the new block and the comparison stays on the model
-- (Nov 12 2026, G7, D4 ruled) the top block keeps Kind and Weight only and every other fact shows once, below, in the
-- facts panel (which now carries the state rows and their mirror): a change made on purpose, so the old card is given
-- the new top block, the new facts panel whole (data only) and the new facts drawing (drawFactsGroups), and the
-- comparison stays on the model. (This replaces the Nov 11-12 carries of the Capacity row and the load format: the
-- new top block has no Capacity row, and the new facts panel has the load format.)
if haveBase then
    local o, n = oldSrc[2].src, newSrc[2].src
    local B7 = "-- ---------------------------------------------------------------------------\n-- B7: state mirror"
    local oa = string.find(o, "local function topStatsForItem(item)", 1, true)
    local ob = oa and string.find(o, B7, oa, true)
    local na = string.find(n, "local function topStatsForItem(item, playerNum)", 1, true)
    local nb = na and string.find(n, B7, na, true)
    local AM = string.find(n, "-- the mirror key of the item's running action", 1, true)
    local AMe = AM and string.find(n, "local function mirrorActiveStateOnRows", AM, true)
    local FG = string.find(n, "-- The facts panel's groups, a thin rule between them", 1, true)
    local FGe = FG and string.find(n, "\n-- ----", FG, true)
    check("D4: the new top block and facts drawing carried into the old card", oa and ob and na and nb and AM and AMe and FG and FGe)
    if oa and ob and na and nb and AM and AMe and FG and FGe then
        o = string.sub(o, 1, oa - 1) .. string.sub(n, na, nb - 1) .. string.sub(o, ob)
        local mo = string.find(o, "local function mirrorActiveStateOnRows", 1, true)
        o = string.sub(o, 1, mo - 1) .. string.sub(n, AM, AMe - 1) .. string.sub(n, FG, FGe) .. "\n" .. string.sub(o, mo)
        -- the old card's two facts loops become the new helper's calls
        local function loop(ind)
            local i2, i3, i4 = ind .. "    ", ind .. "        ", ind .. "            "
            return ind .. "for gi, group in ipairs(panel.groups or {}) do\n"
                .. i2 .. "if gi > 1 then\n"
                .. i3 .. "cy = cy + (M.drawFactsRuleThin and M.drawFactsRuleThin(card, x, cy, w) or 0) + T.px(2)\n"
                .. i2 .. "end\n"
                .. i2 .. "for _, row in ipairs(group.rows or {}) do\n"
                .. i3 .. "local lbl = row.label\n"
                .. i3 .. "if compact and lbl and row.short then\n"
                .. i4 .. "lbl = row.short\n"
                .. i3 .. "end\n"
                .. i3 .. "cy = cy + (M.drawFactsRow and\n"
                .. i4 .. "M.drawFactsRow(card, x, cy, w,\n"
                .. i4 .. "    lbl, row.value, row.valueClass, row.isSub, row.needsProbe) or 0)\n"
                .. i2 .. "end\n"
                .. ind .. "end\n"
        end
        local L12, L8 = loop("            "), loop("        ")
        local a12 = string.find(o, L12, 1, true)
        check("D4: the old clothing facts loop found", a12 ~= nil)
        if a12 then o = string.sub(o, 1, a12 - 1) .. "            cy = drawFactsGroups(card, item, x, cy, w, panel, compact, #zones > 0)\n" .. string.sub(o, a12 + #L12) end
        local a8 = string.find(o, L8, 1, true)
        check("D4: the old generic facts loop found", a8 ~= nil)
        if a8 then o = string.sub(o, 1, a8 - 1) .. "        cy = drawFactsGroups(card, item, x, cy, w, panel, compact, false)\n" .. string.sub(o, a8 + #L8) end
        oldSrc[2].src = o
    end
    oldSrc[3].src = newSrc[3].src
end
local OLD
if haveBase then
    section("OLD: the card files at " .. BASE .. " (before the change)")
    OLD = newEnv("OLD", oldSrc, clock)
else
    section("OLD: no git here; the new files with no clock (the model built every frame, as before)")
    OLD = newEnv("OLD", newSrc, nil)
end
section("NEW: the card files in the working tree")
local NEW = newEnv("NEW", newSrc, clock)
check("the old files are not the new ones (the comparison means something)",
    not haveBase or oldSrc[2].src ~= newSrc[2].src)
check("the new card keeps a model", type(NEW.ZeD_ItemCard._cardModel) == "function")
-- (Nov 11 2026, tab review item 3) a real bag's getItemCapacity is -1: the Capacity row reads its weight
do
    local f = ITEMS.bag._f
    local was = f.getItemCapacity
    f.getItemCapacity = -1
    -- (G7, D4: the Capacity row is the Container Facts' alone now, the top block keeps Kind and Weight)
    local ok, facts = pcall(NEW.ZeD.ItemFactsPanel.ContainerFacts, ITEMS.bag)
    f.getItemCapacity = was
    local got = nil
    for _, r in ipairs(ok and facts and facts.groups[1].rows or {}) do
        if r.label == "en:Tooltip_container_Capacity" then got = r.value end
    end
    -- (its words: the one load format, UI_ZeD_Char_WeightOfMax, "4.5 / 15 kg" in English)
    check("a bag reading getItemCapacity -1: Capacity 4.5 / 15 kg in its Container Facts",
        got == "en:UI_ZeD_Char_WeightOfMax:4.5:15", ok and tostring(got) or facts)
end
-- (Nov 12 2026, the tab catalog's review) the Kind row is the game's word for the kind, as the inventory's Category
-- column has it (InventoryRenderer.catLabel: IGUI_ItemCat_<key>), never the script's key ("GardeningWeapon")
do
    local asked = nil
    NEW.ZeD.InventoryRenderer = { catLabel = function(k) asked = k; return "IGUI_ItemCat_" .. tostring(k) .. " (word)" end }
    local ok, rows = pcall(NEW.ZeD.ItemCard.topStatsForItem, ITEMS.bag)
    NEW.ZeD.InventoryRenderer = nil
    local kind = nil
    for _, r in ipairs(ok and rows or {}) do
        if r.label == "en:UI_ZeD_Card_Kind" then kind = r.value end
    end
    check("the Kind row is the game's word for the item's display category", asked == "Bag" and kind == "IGUI_ItemCat_Bag (word)",
        ok and tostring(kind) or rows)
end
-- (Nov 12 2026, review) a bag's capacity is the card's character's: the game's getEffectiveCapacity (a Disorganized
-- character's 15 is 10; Organized holds more), what it checks a transfer against and shows in its own tooltip and
-- inventory. The bare getCapacity said 15 whatever the traits
do
    local f = BAG_INV._f
    f.getEffectiveCapacity = function(_, chr) return chr == PLAYER and 10 or 15 end
    local okF, facts = pcall(NEW.ZeD.ItemFactsPanel.ContainerFacts, ITEMS.bag, 0)
    f.getEffectiveCapacity = nil
    -- (G7, D4 ruled by the director, Nov 12 2026) the top block keeps Kind and Weight only; everything else shows
    -- once, below, in the facts panel: no label twice, and nothing the old top block said is lost
    local KW = { ["en:UI_ZeD_Card_Kind"] = true, ["en:UI_ZeD_Weight"] = true }
    local MOVED = {   -- what the old top block said, by item: each must be in the facts panel now
        shirt   = { "en:UI_ZeD_Card_Fabric", "en:IGUI_invpanel_Condition", "en:UI_ZeD_Card_Run" },
        apple   = { "en:Tooltip_food_Cooked", "en:Tooltip_food_Fresh", "en:UI_ZeD_Card_HungerReduction", "en:UI_ZeD_Card_ThirstReduction" },
        bat     = { "en:Tooltip_weapon_Condition", "en:Tooltip_weapon_Damage", "en:Tooltip_weapon_Range" },
        pistol  = { "en:Tooltip_weapon_Condition", "en:Tooltip_weapon_Ammo" },
        book    = { "en:UI_ZeD_Card_Progress", "en:IGUI_Skill", "en:UI_ZeD_Card_LevelRange" },
        bag     = { "en:Tooltip_container_Capacity", "en:UI_ZeD_Card_Items", "en:UI_ZeD_Card_WeightReduction" },
        lighter = { "en:IGUI_invpanel_Remaining" },
    }
    for name, want in pairs(MOVED) do
        local it = ITEMS[name]
        local okT, top = pcall(NEW.ZeD.ItemCard.topStatsForItem, it, 0)
        local okP, panel = pcall(NEW.ZeD.ItemFactsPanel.factsFor, it, 0)
        local labels, extra = {}, {}
        for _, r in ipairs(okT and top or {}) do if not KW[r.label] then extra[#extra + 1] = tostring(r.label) end end
        check("D4 " .. name .. ": the top block is Kind and Weight only", okT and #top == 2 and #extra == 0,
            okT and (#top .. " rows: " .. table.concat(extra, ",")) or top)
        local seen, twice = {}, {}
        for _, g in ipairs(okP and panel and panel.groups or {}) do
            for _, r in ipairs(g.rows or {}) do
                if seen[r.label] then twice[#twice + 1] = tostring(r.label) end
                seen[r.label] = r
            end
        end
        local missing = {}
        for _, l in ipairs(want) do if not seen[l] then missing[#missing + 1] = l end end
        check("D4 " .. name .. ": what the top block said is in the facts panel, once", okP and panel and #missing == 0 and #twice == 0,
            okP and ("missing " .. table.concat(missing, ",") .. " twice " .. table.concat(twice, ",")) or panel)
    end
    -- the state rows keep their mirror keys (the card colors them while cooking, reading, repairing)
    local function factRow(it, label)
        local ok2, panel = pcall(NEW.ZeD.ItemFactsPanel.factsFor, it, 0)
        for _, g in ipairs(ok2 and panel and panel.groups or {}) do
            for _, r in ipairs(g.rows or {}) do if r.label == label then return r end end
        end
    end
    local ck = factRow(ITEMS.apple, "en:Tooltip_food_Cooked")
    check("D4: the apple's Cooked row mirrors cooking", ck and ck.mirrorKey == "cooked", ck and ck.mirrorKey)
    local pr = factRow(ITEMS.book, "en:UI_ZeD_Card_Progress")
    check("D4: the book's Progress row mirrors reading", pr and pr.mirrorKey == "progress", pr and pr.mirrorKey)
    local cw = factRow(ITEMS.bat, "en:Tooltip_weapon_Condition")
    check("D4: the bat's Condition row mirrors a repair", cw and cw.mirrorKey == "condition", cw and cw.mirrorKey)
    local cs = factRow(ITEMS.shirt, "en:IGUI_invpanel_Condition")
    check("D4: the shirt's Condition row mirrors a repair and gives way to the zones heading", cs and cs.mirrorKey == "condition" and cs.zoneCond == true,
        cs and tostring(cs.mirrorKey) .. "/" .. tostring(cs.zoneCond))
    local am = factRow(ITEMS.pistol, "en:Tooltip_weapon_Ammo")
    check("D4: the pistol's Ammo row says the rounds loaded", am and tostring(am.value):find("15 / 15", 1, true) ~= nil, am and am.value)
    local lr = factRow(ITEMS.lighter, "en:IGUI_invpanel_Remaining")
    check("D4: the lighter's Remaining is 60%", lr and lr.value == "60%", lr and lr.value)
    local fv = okF and facts and facts.groups and facts.groups[1] and facts.groups[1].rows[1] and facts.groups[1].rows[1].value
    check("a Disorganized character's bag: its Container Facts' Capacity reads 4.5 / 10 kg (the one load format)",
        fv == "en:UI_ZeD_Char_WeightOfMax:4.5:10", okF and tostring(fv) or facts)
    local src = readFile("42/media/lua/client/ZeD/ItemCardOrganism.lua") or ""
    check("the card's model reads the stats and the facts for its own player",
        src:find("m.stats  = topStatsForItem(item, playerNum)", 1, true) ~= nil
        and src:find("ZeD.ItemFactsPanel.factsFor(item, playerNum)", 1, true) ~= nil)
end

local function frameOf(env)
    env.LOG = {}
    local c = env.card
    local c0, t0 = CALLS, env.TR
    local ok, err = pcall(function() c:renderBody({ sourceContext = c:_effectiveContext() }) end)
    return ok, err, table.concat(env.LOG, "\n"), CALLS - c0, env.TR - t0
end

local frames, diffs = 0, 0
local STATS = { OLD = { calls = 0, tr = 0, n = 0 }, NEW = { calls = 0, tr = 0, n = 0 } }
-- one frame on both cards (the clock moves dt ms first); true when they drew the same
local function frame(what, dt, quiet)
    CLOCK = CLOCK + (dt or 16)
    local okO, errO, logO, callsO, trO = frameOf(OLD)
    local okN, errN, logN, callsN, trN = frameOf(NEW)
    frames = frames + 1
    check(what .. ": the old card draws", okO, errO)
    check(what .. ": the new card draws", okN, errN)
    local same = okO and okN and logO == logN
    if not same then diffs = diffs + 1 end
    if not quiet then
        local detail
        if okO and okN and not same then
            local a, b = {}, {}
            for l in (logO .. "\n"):gmatch("(.-)\n") do a[#a + 1] = l end
            for l in (logN .. "\n"):gmatch("(.-)\n") do b[#b + 1] = l end
            for i = 1, math.max(#a, #b) do
                if a[i] ~= b[i] then detail = "line " .. i .. ": OLD " .. tostring(a[i]) .. " | NEW " .. tostring(b[i]); break end
            end
        end
        check(what .. ": the same drawing, old and new", same, detail)
    end
    return same, callsO, callsN, trO, trN, logN
end
local function frames3(what) for i = 1, 3 do frame(what .. " (frame " .. i .. ")") end end
local function both(fn) fn(OLD); fn(NEW) end
local function setItem(it) both(function(e) e.card:setItem(it) end) end

-- ---------------------------------------------------------------------------
-- THE TIMELINE
-- ---------------------------------------------------------------------------
section("Every kind of item, steady")
for _, k in ipairs({ "shirt", "apple", "bat", "pistol", "book", "bag", "lighter", "bottle" }) do
    setItem(ITEMS[k])
    local logN
    for i = 1, 20 do logN = select(6, frame(k .. " steady " .. i)) end
    check(k .. ": the card draws its top stats, facts and verbs (the logs say something)",
        logN and logN:find("M.drawTopStats", 1, true) and logN:find("M.drawCardBackBar", 1, true)
        and (k == "lighter" or k == "bottle" or logN:find("M.drawFactsRow", 1, true)) and true or false)
end

section("What the card shows changes: drawn the next frame")
setItem(ITEMS.bat)
frames3("bat")
ITEMS.bat._f.getCondition = 4;              frames3("bat: condition 4")
setItem(ITEMS.lighter)
frames3("lighter")
ITEMS.lighter._f.getUsedDelta = 0.2;         frames3("lighter: uses")
setItem(ITEMS.bottle)
frames3("bottle")
FLUID.amt = 0.3;                             frames3("bottle: fluid drunk")
FLUID.amt = 0;                               frames3("bottle: empty (no Drink)")
setItem(ITEMS.pistol)
frames3("pistol")
ITEMS.pistol._f.getCurrentAmmoCount = 9;     frames3("pistol: rounds fired")
setItem(ITEMS.apple)
frames3("apple")
ITEMS.apple._f.getHungerChange = -0.07; ITEMS.apple._f.getCalories = 45; frames3("apple: a bite eaten")
setItem(ITEMS.book)
frames3("book")
READ["Base.Book"] = 60;                       frames3("book: pages read")
setItem(ITEMS.bag)
frames3("bag")
BAG_ITEMS[#BAG_ITEMS + 1] = 4;               frames3("bag: an item put in")
table.remove(BAG_ITEMS);                     frames3("bag: an item taken out")

section("The item moving: worn, on the ground, in a crate")
setItem(ITEMS.shirt)
frames3("shirt in the inventory")
ITEMS.shirt._f.isEquipped = true;            frames3("shirt: worn")
ITEMS.shirt._f.isEquipped = false; ITEMS.shirt._f.getContainer = FLOOR; frames3("shirt: dropped")
ITEMS.shirt._f.getContainer = CRATE;         frames3("shirt: in a crate")
ITEMS.shirt._f.getContainer = PLAYER_INV;    frames3("shirt: back in the inventory")
ITEMS.shirt._f.getCondition = 5;             frames3("shirt: torn")

section("Marks and loadouts")
NEW.ZeD.ActionStrip.setState(ITEMS.shirt, "fav", true, 0);       frames3("shirt: favorite set from the card")
NEW.ZeD.ActionStrip.setState(ITEMS.shirt, "unwanted", true, 0);  frames3("shirt: unwanted")
NEW.ZeD.ActionStrip.setState(ITEMS.shirt, "protect", true, 0);   frames3("shirt: no craft")
LISTS.hits[ITEMS.shirt] = { { list = { name = "Raid" }, line = { place = "worn", rule = "any" } } }
Lists.gen = Lists.gen + 1;                    frames3("shirt: put on a loadout")
LISTS.on = false;                             frames3("Loadouts and outfits off")
LISTS.on = true;                              frames3("Loadouts and outfits on")

section("Actions (ItemActionManager)")
setItem(ITEMS.book)
frames3("book")
local act = { mode = "active", label = "Reading", kind = "read", percent = 0.1, timeStr = "1:00" }
both(function(e) e.ZeD.ItemActionManager.notify(ITEMS.book, "start", act) end); frames3("book: reading starts")
local act2 = { mode = "active", label = "Reading", kind = "read", percent = 0.4, timeStr = "0:40" }
both(function(e) e.ZeD.ItemActionManager.notify(ITEMS.book, "tick", act2) end)
READ["Base.Book"] = 90;                       frames3("book: a reading tick and a page")
both(function(e) e.ZeD.ItemActionManager.notify(ITEMS.book, "complete") end); frames3("book: reading ends")
setItem(ITEMS.apple)
local cook = { mode = "active", label = "Cooking", kind = "cook", percent = 0.5 }
both(function(e) e.ZeD.ItemActionManager.notify(ITEMS.apple, "start", cook) end); frames3("apple: cooking")
local burn = { mode = "danger", label = "BURNING", kind = "cook", percent = 0.9 }
both(function(e) e.ZeD.ItemActionManager.notify(ITEMS.apple, "danger", burn) end); frames3("apple: burning")
both(function(e) e.ZeD.ItemActionManager.notify(ITEMS.apple, "cancel") end); frames3("apple: off the heat")
setItem(ITEMS.bat)
local rep = { mode = "active", label = "Repairing", kind = "repair", percent = 0.2 }
both(function(e) e.ZeD.ItemActionManager.notify(ITEMS.bat, "start", rep) end); frames3("bat: repairing")
ITEMS.bat._f.getCondition = 7
both(function(e) e.ZeD.ItemActionManager.notify(ITEMS.bat, "complete") end); frames3("bat: repaired")

section("A mod's facts panel, the language, the theme, the text size")
local function modFacts(item)
    if item ~= ITEMS.bat then return nil end
    return { title = "Mod facts", groups = { { rows = { { label = "Heft", value = "heavy" } } } } }
end
both(function(e) e.ZeD.ItemFactsPanel.register("modfacts", modFacts, 1) end); frames3("bat: a mod's facts panel")
LANG = "fr"
both(function(e) e.ZeD._trGen = e.ZeD._trGen + 1 end); frames3("the language: French")
both(function(e) e.ZeD.TEST = true end);   frames3("the test language on")
both(function(e) e.ZeD.TEST = false end);  frames3("the test language off")
local T2 = makeT(0.05, 10)
both(function(e) e.ZeD.T = T2 end);        frames3("another theme")
local T3 = makeT(0.05, 14)
both(function(e) e.ZeD.T = T3 end);        frames3("Large text")

section("Folds, another item, the drawer's width")
setItem(ITEMS.shirt)
frames3("shirt")
local okF = true
both(function(e) local ok, err = pcall(e.card._toggleFold, e.card, "clothing_zones"); okF = okF and ok
    if not ok then print("  " .. e.label .. " _toggleFold: " .. tostring(err)) end end)
check("the fold toggles on both cards", okF)
check("a fold toggle drops the new card's model", NEW.card._model == nil)
frames3("shirt: zones folded")
both(function(e) pcall(e.card._toggleFold, e.card, "clothing_zones") end); frames3("shirt: zones open")
setItem(ITEMS.bag);   frames3("another item: the bag")
setItem(ITEMS.shirt); frames3("back to the shirt")
W = 200;              frames3("the narrow drawer (220)")
W = 300;              frames3("the wide drawer (480)")
for i = 1, 40 do frame("steady after it all " .. i) end

-- ---------------------------------------------------------------------------
-- WHAT THE CARD HAS NO READING FOR: shown within MODEL_MS
-- ---------------------------------------------------------------------------
section("A change with no reading (poison put in food) shows within MODEL_MS")
setItem(ITEMS.apple)
for i = 1, 3 do frame("apple fresh " .. i) end
ITEMS.apple._f.getPoisonPower = 12
local lag, caught = 0, false
for i = 1, 40 do
    local same = frame("apple poisoned", 16, true)
    if same then caught = true; break end
    lag = lag + 16
end
check("poison shows on the new card within 250 ms", caught and lag <= 250, lag .. " ms")
print(string.format("   poison on the new card: %d ms behind the old (MODEL_MS 250)", lag))
diffs = diffs - lag / 16   -- (those frames were the expected lag, not a fault)
setItem(ITEMS.apple)
for i = 1, 3 do frame("apple poisoned, steady " .. i) end
ITEMS.apple._f.isFresh = false; ITEMS.apple._f.isRotten = true; frames3("apple: gone rotten")
ITEMS.apple._f.isCooked = true;  frames3("apple: cooked")
ITEMS.apple._f.isBurnt = true;   frames3("apple: burnt")

-- ---------------------------------------------------------------------------
-- THE CALLS A FRAME, A CARD JUST SITTING THERE
-- ---------------------------------------------------------------------------
section("Calls into the game and ZeD.tr a frame, old and new (60 frames at 60 fps per item)")
local totO, totN, totTO, totTN = 0, 0, 0, 0
for _, k in ipairs({ "shirt", "apple", "bat", "pistol", "book", "bag", "lighter", "bottle" }) do
    setItem(ITEMS[k])
    local cO, cN, tO, tN = 0, 0, 0, 0
    for i = 1, 60 do
        local same, a, b, c, d = frame(k .. " counted " .. i, 16, true)
        check(k .. " counted " .. i .. ": the same drawing", same)
        cO, cN, tO, tN = cO + a, cN + b, tO + c, tN + d
    end
    print(string.format("   %-8s game calls %6.1f -> %5.1f a frame   ZeD.tr %5.1f -> %5.1f", k, cO / 60, cN / 60, tO / 60, tN / 60))
    check(k .. ": fewer calls into the game", cN < cO, cO .. " -> " .. cN)
    totO, totN, totTO, totTN = totO + cO, totN + cN, totTO + tO, totTN + tN
end
print(string.format("   all      game calls %6.1f -> %5.1f a frame   ZeD.tr %5.1f -> %5.1f   (%d%% fewer game calls)",
    totO / 480, totN / 480, totTO / 480, totTN / 480, math.floor(100 * (1 - totN / totO) + 0.5)))

-- ---------------------------------------------------------------------------
-- A FOLD KEEPS THE SCROLL (Nov 8 2026, code flags): a drawer card clamps with the height renderBody drew
-- ---------------------------------------------------------------------------
section("A fold on a drawer card keeps the scroll (its drawn height, not the old layout's)")
setItem(ITEMS.shirt)
frame("shirt before the fold")
local function foldAt(e, scroll)
    local c = e.card
    c._contentH, c._headH, c._verbStripResvH = 2000, 100, 26   -- as renderBody stamped them: 774 in view
    c._scrollPixels = scroll
    local ok, err = pcall(c._toggleFold, c, "facts_defense")
    check(e.label .. ": the fold toggles", ok, err)
    pcall(c._toggleFold, c, "facts_defense")
    return c._scrollPixels
end
local newKept = foldAt(NEW, 1000)
check("a fold deep in a long drawer card leaves the scroll where it was", newKept == 1000, newKept)
check("the scroll is still cut to the drawn height's end", foldAt(NEW, 1500) == 1226, NEW.card._scrollPixels)
local mode = NEW.card.mode
NEW.card.mode = "inspect"
local okI = pcall(NEW.card._toggleFold, NEW.card, "clothing_zones")
check("a card not in a drawer still clamps with the old layout's height", okI)
pcall(NEW.card._toggleFold, NEW.card, "clothing_zones")
NEW.card.mode = mode
if haveBase then
    local oldKept = foldAt(OLD, 1000)
    check("TEETH: the old clamp (the old layout's height) moved the scroll", oldKept ~= 1000, oldKept)
    print(string.format("   a fold at scroll 1000: old card %d, new card %d", oldKept, newKept))
end
both(function(e) e.card._scrollPixels = 0 end)
frame("shirt after the fold checks")

-- ---------------------------------------------------------------------------
-- B9A 7 (hotfix beta 9a): the card scrolls until its last row clears the care verbs' band at the foot (an
-- opened "Used to make" list's last rows stayed behind the band: the scroll's end left the band out)
-- ---------------------------------------------------------------------------
section("B9A 7: the scroll's end clears the band at the foot")
local function scrollEnd(e, band)
    local c = e.card
    if not c._sb then
        -- the card's own initialise builds its scrollbar and the scroll's onScroll (the real one)
        e.ISPanel.initialise = function() end
        e.ZeD_ScrollbarState = { new = function() return { setScrollPos = function() end } end }
        local keepLoad = c._loadFoldStates
        c._loadFoldStates = function() end
        e.ZeD_ItemCard.initialise(c)
        c._loadFoldStates = keepLoad
    end
    c._contentH, c._headH, c._verbStripResvH = 2000, 100, band
    c._sb.visible = true
    c._sb.onScroll(1)   -- (the thumb, the wheel or the arrows at the bottom)
    local byBar = c._scrollPixels
    c._scrollPixels = 0
    if c.scrollToContentY then c:scrollToContentY(1000000) end
    local byJump = c._scrollPixels
    c._scrollPixels, c._sb.visible = 0, false
    return byBar, byJump, c:getHeight()
end
for _, band in ipairs({ 26, 44 }) do   -- (the band at Normal and at Large text)
    local bar, jump, h = scrollEnd(NEW, band)
    local want = 2000 - (h - 100 - band)
    check("B9A 7: band " .. band .. ": the scroll's end puts the last row right above the band", bar == want, bar .. " want " .. want)
    check("B9A 7: band " .. band .. ": a jump to the end (the controller's) stops there too", jump == want, jump .. " want " .. want)
end
if haveBase then
    local bar, _, h = scrollEnd(OLD, 26)
    check("TEETH: the old card's scroll stopped the band's height short", bar == 2000 - (h - 100), bar)
end
frame("shirt after the scroll checks")

-- ---------------------------------------------------------------------------
-- TEETH: a model kept with no readings would show stale numbers
-- ---------------------------------------------------------------------------
section("TEETH: with the readings taken away, the sim sees the stale card")
-- (G7, D4) drawn: the shirt's overall condition once (its zones heading; the facts leave theirs out), and the
-- pistol's Condition facts row in the warning color while it is repaired (the state mirror on the facts)
section("D4: each fact once, drawn")
do
    setItem(ITEMS.shirt)
    local _, _, _, _, _, lg = frame("D4 shirt")
    -- (the language is French by here: the labels read "fr:...")
    local zonesDrawn = lg:find("UI_ZeD_Card_Zones", 1, true) ~= nil
    local condFacts = lg:find('M.drawFactsRow%([^\n]*:IGUI_invpanel_Condition"') ~= nil
    local fabric = lg:find('M.drawFactsRow%([^\n]*:UI_ZeD_Card_Fabric"') ~= nil
    check("D4 shirt: zones drawn, so the facts draw no second Condition row; Fabric is in the facts",
        zonesDrawn and not condFacts and fabric, tostring(zonesDrawn) .. "/" .. tostring(condFacts) .. "/" .. tostring(fabric))
    setItem(ITEMS.pistol)
    frame("D4 pistol")
    local rep2 = { mode = "active", label = "Repairing", kind = "repair", percent = 0.2 }
    both(function(e) e.ZeD.ItemActionManager.notify(ITEMS.pistol, "start", rep2) end)
    local _, _, _, _, _, lg2 = frame("D4 pistol: repairing")
    check("D4 pistol: its Condition facts row takes the warning color while repaired",
        lg2:find('M.drawFactsRow%([^\n]*:Tooltip_weapon_Condition"[^\n]*"warn"') ~= nil)
    both(function(e) e.ZeD.ItemActionManager.notify(ITEMS.pistol, "complete") end)
    frame("D4 pistol: repaired")
end

-- (G7, D4: the condition shows only in the facts panel now, and the bat's is a mod's panel by here: the pistol's
-- Combat Facts show its condition)
setItem(ITEMS.pistol)
frame("pistol before the teeth")
local savedProbe = NEW.ZeD_ItemCard._cardModel
NEW.ZeD_ItemCard._cardModel = function(self, item, ctx)
    local m = self._model
    if m and m.item == item then return m end
    return savedProbe(self, item, ctx)
end
ITEMS.pistol._f.getCondition = 2
local caughtTeeth = not frame("pistol: condition with no reading", 16, true)
check("a kept model that misses a change is caught", caughtTeeth)
NEW.ZeD_ItemCard._cardModel = savedProbe
frame("pistol: the readings back")

print(string.format("   %d frames compared, %d differed (the poison lag left out)", frames, diffs - (caughtTeeth and 1 or 0)))
-- (153, Nov 11 2026: the "Used to make" rows drawn flush, the director's "flush left with the rest of the card")
check("153 the card's recipe rows drawn flush left (no indent), as the old card's were not", (NEW.FLUSH or 0) > 0 and (OLD.FLUSH or 0) == 0,
      tostring(NEW.FLUSH) .. " / " .. tostring(OLD.FLUSH))
print(string.format("card_model_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
