-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MenuGuess.lua
-- ============================================================================
-- THE MENU'S BEST GUESS (smart menu, the director, Nov 24 2026). Client; a data module with no UI of its own.
--
-- The director: "if you're hungry and you click on a food item, the context menu should immediately show eat instead
-- of move or transfer or any of the other actions." An item's right-click menu opens with its selection on the row
-- the player most likely wants; the rows keep their order. Both looks read it (ZeD_ContextMenu, ZeD_ContextList):
-- the controller's focus starts there, and the mouse's menu opens with that row under the pointer.
--
-- The guesses, strongest first; the first that finds a row in THIS menu wins:
--   1 need       hungry: Eat; thirsty: Drink; a wound: Apply Bandage (or Bandage, Disinfect, Splint); tired: Read
--   2 move       the row that moves it to the container he last moved things into (for 60 s, while he stays near)
--   3 repeat     what he picked last time on the same kind of item (its full type), kept for the session
--   4 main use   a weapon: Equip Primary; clothing not worn: Wear; a book: Read; a drink: Drink; food: Eat
-- Rows are found by the game's own words (getText keys), never by English. Never guessed: a greyed row, a row that
-- destroys or drops (DANGER below), a submenu whose rows are all greyed. A guess inside a submenu lands on its
-- parent row; the submenu stays shut until the player opens it.
--
-- Read by QA: G.last[pn] = { idx, rule, name } for the last menu guessed; G._moves[pn], G._picks[pn]; the menus
-- carry _zedGuessIdx and _zedGuessRule.
-- ============================================================================

ZeD = ZeD or {}
ZeD.MenuGuess = ZeD.MenuGuess or {}
local G = ZeD.MenuGuess

G.MOVE_MS = 60000     -- a move is remembered this long (real time) ...
G.MOVE_TILES = 3      -- ... while the player stays within this many tiles of where he made it, on the same floor
G.PICK_CAP = 64       -- kinds of item whose last pick is remembered (the oldest goes first)

G._moves = G._moves or {}   -- [pn] = { dest, at, x, y, z }
G._picks = G._picks or {}   -- [pn] = { map = { [fullType] = { names } }, order = { fullType } }
G.last = G.last or {}       -- [pn] = { idx, rule, name }: the last guess, for QA

-- ---------------------------------------------------------------------------
-- small helpers
-- ---------------------------------------------------------------------------
local function safe(fn, default)
    local ok, v = pcall(fn)
    if ok and v ~= nil then return v end
    return default
end

--- True while the setting "Menu opens on its best guess" is on (On is the default; true before the option exists).
function G.on()
    -- (Lite: "If vanilla does it, so does Lite"; the game's menus open on their first row, so Lite's do too)
    if ZeD.Settings and ZeD.Settings.lite and ZeD.Settings.lite() then return false end
    local o = ZeD.Settings and ZeD.Settings.menuGuessOption
    if not o then return true end
    local ok, v = pcall(function() return o:getValue() end)
    return not (ok and v == 1)
end

local function now() return safe(function() return getTimestampMs() end, 0) end

-- The game's words for a key: { whole, prefix } (prefix: the text before a %1, for a key that names something)
local MARK = "ZeDGuessArg"   -- (stands in for %1 and %2 while reading a key's words; never shown)
local _words = {}
local function words(key)
    local w = _words[key]
    if w == nil then
        -- (QA lv_calls, Nov 24 2026: getText on a key whose text needs an argument, "Drop %1", logs a Java
        -- MissingFormatArgumentException. So every key is asked with two markers for %1 and %2; a key without them
        -- ignores the extras. The text before the first marker is the prefix.)
        local t = safe(function() return getText(key, MARK, MARK) end, nil)
        if type(t) ~= "string" or t == key then
            w = false
        else
            local cut = string.find(t, MARK, 1, true)
            w = cut and { whole = nil, prefix = string.sub(t, 1, cut - 1) } or { whole = t, prefix = nil }
        end
        _words[key] = w
    end
    return w or nil
end
--- Forget the cached words (a language change).
function G.resetWords() _words = {} end

-- true when an option's name is the game's text for one of keys
local function nameIs(name, keys)
    if type(name) ~= "string" then return false end
    for _, k in ipairs(keys) do
        local w = words(k)
        if w then
            if name == w.whole then return true end
            if w.prefix and w.prefix ~= "" and string.sub(name, 1, #w.prefix) == w.prefix then return true end
        end
    end
    return false
end
G.nameIs = nameIs

-- Rows that drop, destroy or throw away: never guessed, never remembered
G.DANGER = { "ContextMenu_Drop", "ContextMenu_DropNamedItem", "ContextMenu_Drop_Corpse", "ContextMenu_Destroy",
    "ContextMenu_DestroyFloor", "ContextMenu_DestroyForFuel", "ContextMenu_Disassemble", "ContextMenu_Dismantle",
    "ContextMenu_Delete", "ContextMenu_Delete_OneItem", "ContextMenu_Delete_Selection", "ContextMenu_Discard_Bait",
    "ContextMenu_Empty", "ContextMenu_Pour_on_Ground", "ContextMenu_RemoveAllPatches", "ContextMenu_Remove_GroundItem",
    "ContextMenu_Smash_window", "ContextMenu_Vehicle_Smashwindow", "ContextMenu_ThrowCorpseOverFence",
    "ContextMenu_ThrowCorpseThroughWindow" }
function G.isDanger(def) return def ~= nil and nameIs(def.name, G.DANGER) end

local function greyed(def, target)
    if not def then return true end
    if def.isBack or def.heading then return true end
    return def.disabled ~= nil and def.disabled(target) and true or false
end

local function kidsOf(def)
    local k = def and def.children
    return (k and #k > 0) and k or nil
end

-- A row the guess may land on: live, not danger; a submenu row only when a row inside it is live
local function landable(def, target)
    if greyed(def, target) or G.isDanger(def) then return false end
    local kids = kidsOf(def)
    if kids then
        for _, k in ipairs(kids) do
            if not greyed(k, target) and not G.isDanger(k) then return true end
        end
        return false
    end
    if def.subOption then return false end   -- (a submenu not filled yet: nothing known inside it)
    return true
end

-- The top-level index of the first row test(def) accepts: the top rows first, then the rows one submenu down (the
-- guess lands on their parent). Greyed and danger rows never count.
local function find(tree, target, test)
    for i, def in ipairs(tree) do
        if landable(def, target) and test(def) then return i end
    end
    for i, def in ipairs(tree) do
        local kids = kidsOf(def)
        if kids and not greyed(def, target) and not G.isDanger(def) then
            for _, k in ipairs(kids) do
                if not kidsOf(k) and landable(k, target) and test(k) then return i end
            end
        end
    end
    return nil
end
G.find = find

-- ---------------------------------------------------------------------------
-- the items the menu is for
-- ---------------------------------------------------------------------------
-- The real items: the menu's list holds items, or the inventory's stacks ({ items = { header copy, item, ... } })
local function actualItems(items)
    local out = {}
    if type(items) ~= "table" then return out end
    for _, v in ipairs(items) do
        if type(v) == "table" and type(v.items) == "table" then
            for j = 2, #v.items do out[#out + 1] = v.items[j] end
            if #v.items == 1 then out[#out + 1] = v.items[1] end
        elseif v ~= nil then
            out[#out + 1] = v
        end
    end
    return out
end
G.actualItems = actualItems

--- The full type the menu is for: every item's the same, else nil.
function G.typeOf(items)
    local list = actualItems(items)
    local t = nil
    for _, it in ipairs(list) do
        local ft = safe(function() return it:getFullType() end, nil)
        if not ft then return nil end
        if t and ft ~= t then return nil end
        t = ft
    end
    return t
end

local function isA(it, cls) return safe(function() return instanceof(it, cls) end, false) end

-- ---------------------------------------------------------------------------
-- 1 needs
-- ---------------------------------------------------------------------------
local function moodle(p, name)
    return safe(function() return p:getMoodles():getMoodleLevel(MoodleType[name]) end, 0)
end
local function wounded(p)
    local Q = ZeD.QuickWheel
    if Q and Q.hurt then return safe(function() return Q.hurt(p) end, false) end
    return moodle(p, "BLEEDING") >= 1
end
G.NEEDS = {
    { id = "hungry", test = function(p) return moodle(p, "HUNGRY") >= 1 end,
      keys = { "ContextMenu_Eat", "ContextMenu_OpenAndEat" } },
    { id = "thirsty", test = function(p) return moodle(p, "THIRST") >= 1 end,
      keys = { "ContextMenu_Drink", "ContextMenu_OpenAndDrink" } },
    { id = "wound", test = wounded,
      keys = { "ContextMenu_Apply_Bandage", "ContextMenu_Bandage", "ContextMenu_Disinfect", "ContextMenu_Splint" } },
    -- (only the plain Read: the game names a book already read "Re-read", so a finished one is not guessed)
    { id = "tired", test = function(p) return moodle(p, "TIRED") >= 1 end, keys = { "ContextMenu_Read" } },
}

local function byNeed(tree, target, p)
    if not p then return nil end
    for _, n in ipairs(G.NEEDS) do
        if n.test(p) then
            local keys = n.keys
            local i = find(tree, target, function(d) return nameIs(d.name, keys) end)
            if i then return i, n.id end
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- 2 the last move
-- ---------------------------------------------------------------------------
local function isFloorInv(inv) return safe(function() return inv:getType() == "floor" end, false) end

--- Every ZeD move (ContainerControls CT.moveItems: takes, drags, Move to) tells where things went. The floor is not
--- remembered (dropping is never guessed).
function G.noteMove(playerObj, dest)
    if not (playerObj and dest) or isFloorInv(dest) then return end
    local pn = safe(function() return playerObj:getPlayerNum() end, 0)
    G._moves[pn] = { dest = dest, at = now(),
        x = safe(function() return playerObj:getX() end, 0), y = safe(function() return playerObj:getY() end, 0),
        z = safe(function() return playerObj:getZ() end, 0) }
end

--- The container he last moved things into, while it is still fresh and near; else nil (and forgotten).
function G.lastMove(pn, p)
    local m = G._moves[pn]
    if not m then return nil end
    local stale = now() - (m.at or 0) > G.MOVE_MS
    if not stale and p then
        local x, y, z = safe(function() return p:getX() end, m.x), safe(function() return p:getY() end, m.y),
            safe(function() return p:getZ() end, m.z)
        local dx, dy = x - m.x, y - m.y
        stale = dx * dx + dy * dy > G.MOVE_TILES * G.MOVE_TILES or math.floor(z) ~= math.floor(m.z)
    end
    if stale then G._moves[pn] = nil; return nil end
    return m.dest
end

-- the option behind a row moves things into dest: one of its parameters is that container, or it is the game's Put in
-- Container while its loot page shows dest
local function movesTo(def, dest, pn)
    local o = def.vanillaRef
    if type(o) ~= "table" then return false end
    for i = 1, 4 do
        if o["param" .. i] == dest then return true end
    end
    local put = ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.onPutItems
    if put and o.onSelect == put then
        local inv = safe(function() return getPlayerLoot(pn).inventory end, nil)
        return inv ~= nil and inv == dest
    end
    return false
end
G.movesTo = movesTo

local function byMove(tree, target, pn, p)
    local dest = G.lastMove(pn, p)
    if not dest then return nil end
    local i = find(tree, target, function(d) return movesTo(d, dest, pn) end)
    if i then return i, "move" end
    return nil
end

-- ---------------------------------------------------------------------------
-- 3 the last pick on the same kind of item
-- ---------------------------------------------------------------------------
--- A row that moves things (a parameter is a container): rule 2's, never remembered here.
function G.isMoveRow(def)
    local o = def and def.vanillaRef
    if type(o) ~= "table" then return false end
    for i = 1, 4 do
        local v = o["param" .. i]
        if v ~= nil and isA(v, "ItemContainer") then return true end
    end
    local I = ISInventoryPaneContextMenu
    return I ~= nil and o.onSelect ~= nil and (o.onSelect == I.onPutItems or o.onSelect == I.onMoveItemsTo)
end

--- The menu ran a row: remember it for the next menu on that kind of item. names: the row's path, its submenu
--- parents' names first. Not for moves, danger rows, or a menu over mixed kinds (fullType nil).
function G.notePick(pn, fullType, names, def, parents)
    if not (fullType and type(names) == "table" and #names > 0) then return end
    if def and (G.isDanger(def) or G.isMoveRow(def)) then return end
    for _, pd in ipairs(parents or {}) do
        if G.isDanger(pd) then return end
    end
    pn = pn or 0
    local P = G._picks[pn]
    if not P then P = { map = {}, order = {} }; G._picks[pn] = P end
    if P.map[fullType] then
        for i, t in ipairs(P.order) do
            if t == fullType then table.remove(P.order, i); break end
        end
    end
    local copy = {}
    for i, n in ipairs(names) do copy[i] = n end
    P.map[fullType] = copy
    P.order[#P.order + 1] = fullType
    while #P.order > G.PICK_CAP do
        local old = table.remove(P.order, 1)
        P.map[old] = nil
    end
end

local function byRepeat(tree, target, pn, fullType)
    local P = fullType and G._picks[pn]
    local names = P and P.map[fullType]
    if not names then return nil end
    for i, def in ipairs(tree) do
        if def.name == names[1] and not greyed(def, target) and not G.isDanger(def) then
            if #names == 1 then
                if landable(def, target) and not kidsOf(def) then return i, "repeat" end
            else
                for _, k in ipairs(kidsOf(def) or {}) do
                    if k.name == names[2] and not kidsOf(k) and landable(k, target) then return i, "repeat" end
                end
            end
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- 4 the item's main use
-- ---------------------------------------------------------------------------
local EAT = { "ContextMenu_Eat", "ContextMenu_OpenAndEat" }
local DRINK = { "ContextMenu_Drink", "ContextMenu_OpenAndDrink" }
--- The keys of an item's main use, strongest first, or nil.
function G.mainUseKeys(it)
    if not it then return nil end
    if isA(it, "HandWeapon") then return { "ContextMenu_Equip_Primary", "ContextMenu_Equip_Two_Hands" } end
    if isA(it, "Clothing") then
        if safe(function() return it:isEquipped() end, false) then return nil end
        return { "ContextMenu_Wear" }
    end
    if isA(it, "Literature") then return { "ContextMenu_Read" } end
    if isA(it, "Food") then return { EAT[1], EAT[2], DRINK[1], DRINK[2] } end
    if safe(function() return it:getFluidContainer() ~= nil end, false) then return DRINK end
    return nil
end

local function byMainUse(tree, target, items)
    local it = actualItems(items)[1]
    local keys = G.mainUseKeys(it)
    if not keys then return nil end
    local i = find(tree, target, function(d) return nameIs(d.name, keys) end)
    if i then return i, "use" end
    return nil
end

-- ---------------------------------------------------------------------------
-- the guess
-- ---------------------------------------------------------------------------
--- The top-level index the menu should open on, and the rule that found it ("hungry", "thirsty", "wound", "tired",
--- "move", "repeat", "use"); nil when nothing fits or the setting is off. tree: the menu's ActionDef list (pins
--- applied); items: the inventory items it acts on.
function G.pick(tree, pn, items)
    pn = pn or 0
    G.last[pn] = nil
    if type(tree) ~= "table" or #tree == 0 or not G.on() then return nil end
    local p = safe(function() return getSpecificPlayer(pn) end, nil)
    local i, rule = byNeed(tree, items, p)
    if not i then i, rule = byMove(tree, items, pn, p) end
    if not i then i, rule = byRepeat(tree, items, pn, G.typeOf(items)) end
    if not i then i, rule = byMainUse(tree, items, items) end
    if i then G.last[pn] = { idx = i, rule = rule, name = tree[i] and tree[i].name } end
    return i, rule
end

-- ---------------------------------------------------------------------------
-- placement (the mouse: the guessed row under the pointer)
-- ---------------------------------------------------------------------------
--- Where a box goes so that its point (cx, cy) sits on the pointer (ax, ay), kept pad from the screen's edges as the
--- menus clamp. w, h: the box; sw, sh: the screen; hw, hh: half the row's size. Returns x, y and whether the pointer
--- is still on the row after the clamp (if not, the row stays lit as the selection anyway).
function G.place(ax, ay, cx, cy, hw, hh, w, h, sw, sh, pad)
    local x, y = ax - cx, ay - cy
    if x < pad then x = pad end
    if x + w > sw - pad then x = sw - w - pad end
    if y < pad then y = pad end
    if y + h > sh - pad then y = sh - h - pad end
    local onRow = math.abs(ax - (x + cx)) < hw and math.abs(ay - (y + cy)) < hh
    return x, y, onRow
end
