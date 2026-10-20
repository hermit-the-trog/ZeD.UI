-- ZeD-UI/42/media/lua/client/ZeD/ContextMenuRegistry.lua
-- ============================================================================
-- CONTEXT MENU REGISTRY (S88)
-- Pure-data module. Transforms vanilla ISContextMenu.options[] into the
-- ActionDef tree that ZeD_ContextMenu renders. Also handles:
--   - Category keyword mapping (hybrid hardcode + log-unknown)
--   - Pinned action persistence via Player ModData
--   - Target meta formatting (food / weapon / clothing / fluid / literature)
--   - Icon texture resolution (migrated from old Overrides/ContextMenu.lua)
-- No rendering ? UI calls live in the organism + molecules.
-- ============================================================================

require "ZeD/ContextIcons"   -- provides ZeD.ContextIcons

ZeD = ZeD or {}
ZeD.ContextMenu = ZeD.ContextMenu or {}

local Registry = {}

-- ============================================================================
-- CATEGORY KEYWORD MAP
-- Substring match against option names. First-match-wins in iteration order;
-- to keep ordering deterministic we list (keyword, category) pairs instead of
-- a plain table. All comparisons are case-insensitive.
--
-- Category order (locked S87): USE ? ACTION ? CRAFT ? EQUIP ? TRANSFER ? INFO ? ADMIN
-- Unknown names fall back to ACTION. DEBUG_LOG_UNKNOWN_CATEGORIES toggles
-- first-sight logging so we can grow the map from real runs.
-- ============================================================================

Registry.CATEGORIES = { "USE", "ACTION", "CRAFT", "EQUIP", "TRANSFER", "INFO", "ADMIN" }

Registry.CATEGORY_KEYWORDS = {
    -- USE
    { "Eat",         "USE" },
    { "Drink",       "USE" },
    { "Refill",      "USE" },
    { "Empty",       "USE" },
    { "Sleep",       "USE" },
    { "Rest",        "USE" },
    { "Read",        "USE" },
    { "Light",       "USE" },
    { "Extinguish",  "USE" },

    -- ACTION
    { "Open",        "ACTION" },
    { "Close",       "ACTION" },
    { "Unlock",      "ACTION" },
    { "Lock",        "ACTION" },
    { "Climb",       "ACTION" },
    { "Walk to",     "ACTION" },
    { "Loot",        "ACTION" },
    { "Attach",      "ACTION" },
    { "Detach",      "ACTION" },
    { "Rotate",      "ACTION" },
    { "Sit",         "ACTION" },
    { "Stand",       "ACTION" },

    -- CRAFT
    { "Craft",       "CRAFT" },
    { "Cook",        "CRAFT" },
    { "Cut",         "CRAFT" },
    { "Mix",         "CRAFT" },
    { "Rip",         "CRAFT" },
    { "Sew",         "CRAFT" },
    { "Repair",      "CRAFT" },
    { "Sharpen",     "CRAFT" },
    { "Disassemble", "CRAFT" },
    { "Recipe",      "CRAFT" },

    -- EQUIP
    { "Equip",       "EQUIP" },
    { "Wear",        "EQUIP" },
    { "Unequip",     "EQUIP" },
    { "Hold",        "EQUIP" },

    -- TRANSFER
    { "Transfer",    "TRANSFER" },
    { "Grab",        "TRANSFER" },
    { "Take",        "TRANSFER" },
    { "Drop",        "TRANSFER" },
    { "Give",        "TRANSFER" },

    -- INFO
    { "Examine",     "INFO" },
    { "Inspect",     "INFO" },
    { "Info",        "INFO" },
    { "Mark",        "INFO" },
    { "Share",       "INFO" },

    -- ADMIN
    { "Admin",       "ADMIN" },
    { "Teleport",    "ADMIN" },
    { "Spawn",       "ADMIN" },
    { "Godmode",     "ADMIN" },
    { "Toggle",      "ADMIN" },
    { "Rename",      "ADMIN" },
    { "Destroy",     "ADMIN" },
}

-- Debug channel: when true, first-sight unknown names print to console so we
-- can grow CATEGORY_KEYWORDS empirically. Set true in a dev build or via
-- ZeD.ContextMenu.Registry.DEBUG_LOG_UNKNOWN_CATEGORIES = true at runtime.
Registry.DEBUG_LOG_UNKNOWN_CATEGORIES = false
Registry._loggedUnknowns = {}

function Registry.categorize(optionName)
    if not optionName or optionName == "" then return "ACTION" end
    local lower = string.lower(optionName)
    for _, pair in ipairs(Registry.CATEGORY_KEYWORDS) do
        if string.find(lower, string.lower(pair[1]), 1, true) then
            return pair[2]
        end
    end
    if Registry.DEBUG_LOG_UNKNOWN_CATEGORIES and not Registry._loggedUnknowns[optionName] then
        Registry._loggedUnknowns[optionName] = true
        print("[ZeD.ContextMenu] uncategorized option name: '" .. optionName .. "' -> ACTION")
    end
    return "ACTION"
end

-- ============================================================================
-- ICON TEXTURE RESOLUTION (migrated from old Overrides/ContextMenu.lua)
-- Vanilla options may already carry iconTexture or itemForTexture; otherwise
-- we look up option.name in ZeD.ContextIcons (which ships a large English-
-- keyed mapping to our SmashIcons PNG set). Translation keys are reverse-
-- resolved to display names so localized builds still match.
-- ============================================================================

local _iconCache = {}
local function getIconTexture(codepoint)
    if not codepoint then return nil end
    if _iconCache[codepoint] == nil then
        _iconCache[codepoint] = getTexture("media/textures/ZeD/icons/" .. codepoint .. ".png") or false
    end
    return _iconCache[codepoint] or nil
end

-- Exact-match cache: full option name (localized or raw) ? codepoint.
local _translatedNameCache = nil
-- First-word cache: leading word only ? codepoint. Used as fallback when the
-- option name has a dynamic suffix (e.g. "Read Doctor Magazine", "Repair
-- Baseball Bat", "Equip Shotgun") that the exact-match path would miss.
-- Vanilla composes many labels as `getText("ContextMenu_X") .. " " .. target`;
-- the leading word survives this composition and carries the action semantics.
local _firstWordCache = nil

local function _firstWord(s)
    if not s then return nil end
    -- Plain-text search for a literal space. Previously used "%s" with the
    -- plain=true flag, which made Lua look for the LITERAL two characters
    -- '%' and 's' rather than the whitespace class ? find never matched and
    -- _firstWord("Place Item") returned "Place Item" whole. (Confirmed from
    -- the debug log: "first word: 'Place Item'" should have been "Place".)
    local sp = s:find(" ", 1, true)
    if sp then return s:sub(1, sp - 1) end
    return s
end

local function buildTranslatedCache()
    _translatedNameCache = {}
    _firstWordCache = {}
    if not ZeD.ContextIcons then return end

    -- Pass 1: index direct entries (display name + optional translation key).
    for key, cp in pairs(ZeD.ContextIcons) do
        _translatedNameCache[key] = cp   -- direct display-name entries
        -- Also resolve translation keys to their localized display strings,
        -- which is what vanilla option.name will contain for translated mods.
        if key:sub(1, 12) == "ContextMenu_" or key:sub(1, 5) == "IGUI_" or key:sub(1, 6) == "Fluid_" then
            -- S123: a few keys (Fluid_HoldingOneType etc.) are Java format
            -- strings; calling getText without args makes Translator log a
            -- MissingFormatArgumentException WARN. Extra args are ignored by
            -- keys that have no specifiers, so pad with three blanks.
            local ok, translated = pcall(getText, key, "", "", "")
            if ok and translated then
                _translatedNameCache[translated] = cp
            end
        end
    end

    -- Pass 2: build first-word index from the materialized exact-match cache.
    -- Two-pass so translation-key resolutions (which only populate _translated-
    -- NameCache above) also contribute their localized first words here.
    -- Longer map keys win if multiple entries share a first word ? e.g.
    -- "Equip Primary" and "Equip" both start with "Equip"; we want
    -- "Equip Shotgun" ? first-word-fallback ? "Equip" (the generic verb), not
    -- "Equip Primary" (a specific slot). Generic single-word entries naturally
    -- win because a bare "Equip" key has first-word "Equip" with no competing
    -- shorter candidate. For conflicts where both entries are multi-word, we
    -- keep the first-seen (deterministic given Lua 5.1 table order is stable
    -- within a session ? unordered across reloads, but every option name that
    -- would fall back is a dynamic label anyway, so the icon picked is still
    -- semantically "close enough").
    for name, cp in pairs(_translatedNameCache) do
        local fw = _firstWord(name)
        if fw and fw ~= name then
            -- Multi-word map entry: don't pollute the first-word index with
            -- its leading word. The bare single-word entry (if any) wins; if
            -- there's no bare entry, no entry is the right answer (the user
            -- hasn't expressed intent for that action).
        elseif fw then
            -- Single-word map entry: it IS the first-word answer.
            if _firstWordCache[fw] == nil then
                _firstWordCache[fw] = cp
            end
        end
    end
end

-- Debug toggle: when true, prints each unmatched option name once so we can
-- grow the map from real-play labels. Default ON during S103 icon-work cycle;
-- flip to false once the map is stable by running in the in-game console:
--   ZeD.ContextMenu.Registry.DEBUG_LOG_UNKNOWN_ICONS = false
Registry.DEBUG_LOG_UNKNOWN_ICONS = false
Registry._loggedUnknownIcons = {}

local function resolveIconForName(optionName)
    if not optionName or not ZeD.ContextIcons then return nil end
    if not _translatedNameCache then buildTranslatedCache() end

    -- Exact match wins. Handles both direct display labels ("Walk to") and
    -- IGUI/ContextMenu_* localized forms ("Eat" from ContextMenu_Eat).
    local cp = _translatedNameCache[optionName]
    if cp then return getIconTexture(cp) end

    -- Prefix-word fallback for dynamic labels. "Read Doctor Magazine" ?
    -- first word "Read" ? use the Read icon. Preserves the action's
    -- semantic while tolerating vanilla's `verb + " " + target` composition.
    -- Only triggers when the leading word is a distinct token (i.e. the
    -- label has a space). Bare-word labels already took the exact path.
    local fw = _firstWord(optionName)
    if fw and fw ~= optionName then
        cp = _firstWordCache and _firstWordCache[fw]
        if cp then return getIconTexture(cp) end
    end

    if Registry.DEBUG_LOG_UNKNOWN_ICONS and not Registry._loggedUnknownIcons[optionName] then
        Registry._loggedUnknownIcons[optionName] = true
        print("[ZeD.ContextMenu] no icon mapping for option name: '"
              .. tostring(optionName) .. "' (first word: '"
              .. tostring(fw) .. "')")
    end
    return nil
end

Registry.resolveIconForName = resolveIconForName

-- ============================================================================
-- ACTIONDEF CONSTRUCTION
-- Walks ISContextMenu.options + .subMenus to build the tree format consumed
-- by ZeD_ContextMenu. See CONTEXT_MENU_SPEC ?6 for schema.
--
-- We PRESERVE a reference to the underlying vanilla option table so that:
--   - onSelect can dispatch through the original function
--   - onHighlight callbacks (used by some mods for server-side gating) can
--     still fire ? the organism calls vanillaRef.onHighlight on selection change
--   - notAvailable / isDisabled / badColor flags stay live if mods mutate them
-- ============================================================================

-- Derive a stable id from the option name. Collisions between sibling entries
-- resolve via "_<index>" suffix.
local function idFromName(name, index)
    local base = (name or "opt"):lower():gsub("[^%w]+", "_"):gsub("_+", "_"):gsub("^_", ""):gsub("_$", "")
    if base == "" then base = "opt_" .. tostring(index) end
    return base
end

-- Vanilla tooltip text carries rich-text tags (<LINE>, <INDENT:20>, <RGB:1,0,0>).
-- The strip's bubble and the list draw plain text, so line breaks become real
-- ones and every other tag is dropped.
local function plainTip(s)
    s = tostring(s or "")
    s = s:gsub("<[Ll][Ii][Nn][Ee]>", "\n"):gsub("<[Bb][Rr]>", "\n")
    s = s:gsub("<[^>]*>", " ")
    s = s:gsub("[ \t]+", " "):gsub(" *\n *", "\n")
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Translate a single vanilla option into an ActionDef
local function makeActionDef(option, index, vanillaMenu, target)
    local def = {}
    def.id = idFromName(option.name, index)
    def.name = option.name
    def.category = Registry.categorize(option.name)
    def.vanillaRef = option   -- for onHighlight / reactivity
    -- S111: ZeD icon mapping takes priority. This gives semantically correct
    -- action-icons (a needle for "Suture", a smoke icon for "Smoke", etc.)
    -- instead of the item-bound sprite that vanilla ships via itemForTexture
    -- (which was making every option on a cigarette pack show the cigarette-
    -- pack sprite). Fall back to vanilla only if our map has no entry.
    -- ZeD textures are pure-white-on-transparent alpha shapes, so the
    -- renderer multiply-tints them to the cell's foreground color
    -- (iconTintable=true). Vanilla iconTexture / itemForTexture textures are
    -- already colored and must NOT be tinted ? collapsing an item sprite to
    -- a single color would destroy it.
    def.iconTexture = resolveIconForName(option.name)
    if def.iconTexture then
        def.iconTintable = true
    else
        def.iconTexture = option.iconTexture or nil
        if not def.iconTexture and option.itemForTexture and option.itemForTexture.getTexture then
            local ok, tex = pcall(function() return option.itemForTexture:getTexture() end)
            if ok then def.iconTexture = tex end
        end
    end

    -- Live state functions ? captured-by-closure refs to option so flags can
    -- mutate after menu construction (vanilla mods sometimes do this in
    -- update-style callbacks)
    def.disabled = function(_target)
        return option.isDisabled or option.notAvailable or false
    end
    def.stateKind = function(_target)
        if option.notAvailable or option.badColor then return "bad" else return "ok" end
    end
    -- State row shows a REASON ? only populated when the action is gated.
    -- For a green-lit action the balloon body already explains the outcome;
    -- adding a redundant "? <tooltip>" here would just duplicate body text.
    -- When disabled/notAvailable, the tooltip typically contains the reason
    -- the option is gated (e.g. "Missing: Can Opener"), which is exactly
    -- what the state row is for.
    def.state = function(_target)
        local gated = option.isDisabled or option.notAvailable or option.badColor
        if gated and option.toolTip and option.toolTip.description then
            return plainTip(option.toolTip.description)
        end
        return ""
    end

    -- Body text: ONLY use the tooltip description. If vanilla doesn't provide
    -- one, leave body empty ? we deliberately do NOT fall back to the option
    -- name because that duplicates the floating label (which already shows
    -- the action name). The molecule collapses the body section when empty.
    if option.toolTip and option.toolTip.description then
        def.body = plainTip(option.toolTip.description)
    else
        def.body = nil
    end

    -- Fire: call original onSelect with target + preserved params.
    -- floor items stay in vanilla's shared floor container; vanilla's handlers transfer them themselves.
    def.onFire = function(_target)
        if not option.onSelect then return end
        local params = {}
        for i = 1, 10 do
            params[i] = option["param" .. i]
        end
        -- Vanilla onSelect signature: function(target_or_nil, param1, ..., param10)
        local selfArg = option.target
        if selfArg == nil then selfArg = _target end

        pcall(option.onSelect, selfArg,
            params[1], params[2], params[3], params[4], params[5],
            params[6], params[7], params[8], params[9], params[10])
    end

    -- Recurse into submenus (max 2 deep per spec ? but we don't enforce here;
    -- the organism flattens display via "path" state).
    --
    -- S99 FIX: vanilla stores submenus in `instanceMap`, reached via
    -- `:getSubMenu(num)` (see ISContextMenu.lua:1225). We were reading a
    -- non-existent `.subMenus` field, so every drill-in saw empty children
    -- and hit the leaf path ? the menu closed instead of drilling in.
    def.subOption   = option.subOption   -- preserve for lazy re-populate below
    def._vanillaMenu = vanillaMenu
    if option.subOption and vanillaMenu and vanillaMenu.getSubMenu then
        local ok, sub = pcall(function() return vanillaMenu:getSubMenu(option.subOption) end)
        if ok and sub and sub.options and #sub.options > 0 then
            def.children = {}
            for j, subOpt in ipairs(sub.options) do
                def.children[#def.children + 1] = makeActionDef(subOpt, j, sub, target)
            end
        end
    end

    return def
end

-- Export for lazy-drill-in path in ZeD_ContextMenu:confirm ? some mods
-- populate submenus only on hover via `option.onSubMenu`, so the build-time
-- snapshot may miss children that only materialize when the user drills in.
Registry._makeActionDef = makeActionDef

-- Names of submenus we flatten into the parent list. Vanilla uses "More" as
-- an overflow bucket for inventory actions (Rename, Show Build Recipes Used,
-- etc.) so the main menu doesn't get long. ZeD's strip handles overflow via
-- truncation + visual carousel ? the extra drill level is just friction.
-- Promote those children to the top-level at the parent's position.
local FLATTEN_NAMES = {}
local function rememberFlattenName(key)
    FLATTEN_NAMES[key] = true
    if getText then
        local ok, t = pcall(getText, key)
        if ok and t then FLATTEN_NAMES[t] = true end
    end
end
rememberFlattenName("ContextMenu_More")
FLATTEN_NAMES["More"] = true   -- belt-and-suspenders for unlocalized fallback

-- Returns true if name reads as a "More"-style overflow label, tolerating
-- trailing dots / ellipses / whitespace and localized forms (registered via
-- rememberFlattenName above).
local function looksLikeMore(name)
    if not name then return false end
    if FLATTEN_NAMES[name] then return true end
    -- Strip trailing dots / ellipses / whitespace, case-fold.
    local s = tostring(name):lower():gsub("[%s%.%?]+$", "")
    return s == "more"
end

-- Walks a tree once. When it sees an entry whose name looks like "More", one
-- of two things happens:
--   - has children ? splice children into the parent list at its position
--   - no children  ? just remove the orphan entry (vanilla sometimes leaves a
--                    "More" stub with nothing underneath; it's pure noise)
-- Operates in place. Recurses into every surviving entry with children.
local function flattenMoreSubmenus(list)
    if not list then return end
    local i = 1
    while i <= #list do
        local def = list[i]
        if def.children and #def.children > 0 then
            -- Recurse first so child "More" entries flatten before splice
            flattenMoreSubmenus(def.children)
        end
        if looksLikeMore(def.name) then
            if def.children and #def.children > 0 then
                local children = def.children
                table.remove(list, i)
                for j = 1, #children do
                    table.insert(list, i + j - 1, children[j])
                end
                -- DON'T increment i ? re-evaluate the freshly-inserted entries
            else
                -- Orphan "More" with no children ? just drop it.
                table.remove(list, i)
            end
        else
            i = i + 1
        end
    end
end

-- Build the full top-level ActionDef array from a vanilla ISContextMenu.
-- options:     vanillaMenu.options (array, 1-based)
-- target:      the world object(s) or inventory item(s) the menu is acting on
-- vanillaMenu: the ISContextMenu instance (needed for subMenus table)
function Registry.buildActionsFromVanilla(options, target, vanillaMenu)
    local tree = {}
    if not options then return tree end
    for i, opt in ipairs(options) do
        tree[#tree + 1] = makeActionDef(opt, i, vanillaMenu, target)
    end
    flattenMoreSubmenus(tree)
    return tree
end

-- ============================================================================
-- PINNED ACTION PERSISTENCE
-- Stored per-character in ModData under key "ZeD_PinnedContextIds".
-- Structure: { ["eat"] = true, ["disassemble"] = true, ... }
-- Match on ActionDef.id which derives from the English option name.
-- ============================================================================

local function getPinsModData()
    local player = getSpecificPlayer(0)
    if not player then return nil end
    local md = player:getModData()
    if not md.ZeD_PinnedContextIds then
        md.ZeD_PinnedContextIds = {}
    end
    return md.ZeD_PinnedContextIds
end

function Registry.getPinnedIds()
    return getPinsModData() or {}
end

function Registry.isPinned(actionId)
    local pins = getPinsModData()
    return pins and pins[actionId] == true
end

function Registry.togglePin(actionId)
    local pins = getPinsModData()
    if not pins or not actionId then return end
    if pins[actionId] then pins[actionId] = nil else pins[actionId] = true end
end

-- Apply pins to a tree: hoist pinned actions to the front of their category.
-- Mutates the tree in place. Also stamps def.pinned = true on each pinned
-- entry so the cell can render the pin indicator without re-querying.
-- Sort is stable per-category (Lua's table.sort isn't stable, so we use a
-- deliberate two-pass reordering: pinned first preserving input order, then
-- unpinned preserving input order).
function Registry.applyPins(tree, _target)
    local pins = getPinsModData() or {}
    -- Mark pinned flags first
    for _, def in ipairs(tree) do
        if pins[def.id] then def.pinned = true end
        if def.children then
            for _, child in ipairs(def.children) do
                if pins[child.id] then child.pinned = true end
            end
        end
    end
    -- Group by category preserving input order, then flatten in CATEGORIES
    -- order with pinned-first per category
    local buckets = {}
    for _, cat in ipairs(Registry.CATEGORIES) do buckets[cat] = { pinned = {}, rest = {} } end
    local unknown = { pinned = {}, rest = {} }
    for _, def in ipairs(tree) do
        local b = buckets[def.category] or unknown
        if def.pinned then b.pinned[#b.pinned + 1] = def
        else               b.rest[#b.rest + 1] = def end
    end
    local flat = {}
    for _, cat in ipairs(Registry.CATEGORIES) do
        local b = buckets[cat]
        for _, def in ipairs(b.pinned) do flat[#flat + 1] = def end
        for _, def in ipairs(b.rest)   do flat[#flat + 1] = def end
    end
    for _, def in ipairs(unknown.pinned) do flat[#flat + 1] = def end
    for _, def in ipairs(unknown.rest)   do flat[#flat + 1] = def end
    -- Replace input contents in place so the caller's reference stays valid
    for i = #tree, 1, -1 do tree[i] = nil end
    for i, def in ipairs(flat) do tree[i] = def end
    return tree
end

-- ============================================================================
-- META FORMATTERS ? fills the target card's meta slot.
-- Returns a short string for the item type, or "" if nothing meaningful.
-- Ordered by specificity: most specific check first.
-- ============================================================================

local function safeCall(obj, method, ...)
    local fn = obj[method]
    if not fn then return nil end
    local ok, result = pcall(fn, obj, ...)
    if ok then return result end
    return nil
end

local function formatFluidMeta(item)
    local fc = safeCall(item, "getFluidContainer")
    if not fc then return nil end
    local amount = safeCall(fc, "getAmount") or 0
    local capacity = safeCall(fc, "getCapacity") or 0
    local fluidPart = ""
    local primary = safeCall(fc, "getPrimaryFluid")
    if primary then
        fluidPart = safeCall(primary, "getTranslatedFluidName") or ""
    end
    if capacity > 0 then
        local txt = string.format("%.1f / %.1f L", amount, capacity)
        if fluidPart ~= "" then txt = txt .. " ? " .. fluidPart end
        return txt
    end
    return fluidPart ~= "" and fluidPart or nil
end

local function formatFoodMeta(item)
    if not item or not item.getFreshness and not item.getHungerChange then return nil end
    local parts = {}
    local count = safeCall(item, "getCount") or safeCall(item, "getCurrentUses")
    if count and count > 1 then parts[#parts + 1] = "x" .. tostring(count) end
    local hunger = safeCall(item, "getHungerChange")
    if hunger then
        parts[#parts + 1] = string.format("%+d hunger", math.floor(hunger * 100 + 0.5))
    end
    local age = safeCall(item, "getAge")
    local offAge = safeCall(item, "getOffAge")
    if age and offAge and offAge > 0 then
        local freshPct = math.floor((1 - age / offAge) * 100 + 0.5)
        if freshPct < 50 then parts[#parts + 1] = "stale"
        elseif freshPct < 85 then parts[#parts + 1] = "ripe"
        else parts[#parts + 1] = "fresh" end
    end
    if #parts == 0 then return nil end
    return table.concat(parts, " ? ")
end

local function formatWeaponMeta(item)
    local cond = safeCall(item, "getConditionPercent")
    local parts = {}
    if cond then parts[#parts + 1] = "cond " .. tostring(cond) .. "%" end
    local current = safeCall(item, "getCurrentAmmoCount")
    local max = safeCall(item, "getMaxAmmo")
    if current and max and max > 0 then
        parts[#parts + 1] = string.format("%d / %d", current, max)
    end
    if #parts == 0 then return nil end
    return table.concat(parts, " ? ")
end

local function formatClothingMeta(item)
    local parts = {}
    local wet = safeCall(item, "getWetness")
    if wet and wet > 0 then
        parts[#parts + 1] = string.format("wet %d%%", math.floor(wet))
    end
    local bite = safeCall(item, "getBiteDefense")
    if bite and bite > 0 then
        parts[#parts + 1] = string.format("bite %d", math.floor(bite))
    end
    if #parts == 0 then return nil end
    return table.concat(parts, " ? ")
end

local function formatLiteratureMeta(item)
    local pages = safeCall(item, "getNumberOfPages")
    local read = safeCall(item, "getAlreadyReadPages")
    if pages and pages > 0 then
        if read and read > 0 then
            return string.format("%d / %d pages", read, pages)
        end
        return string.format("%d pages", pages)
    end
    return nil
end

-- Detect a Java ArrayList (world-RMB target: ArrayList<IsoObject>). Java
-- userdata in Kahlua exposes .size() + .get(i) ? that's our signature.
local function isJavaList(v)
    return type(v) == "userdata" and v.size ~= nil and v.get ~= nil
end

-- Unwrap the user's inventory-selection table to the first InventoryItem.
-- Inventory RMB sends either { item1, item2, ... } or an ISInventoryPane-style
-- wrapper { items = { item1, ... }, ... } ? handle both.
local function firstInventoryItem(t)
    if type(t) ~= "table" then return nil end
    local first = t[1]
    if type(first) == "table" and first.items and first.items[1] then
        return first.items[1]
    end
    return first
end

-- Dispatch by duck-typing (instanceof is expensive; we probe method presence)
function Registry.getMetaFor(target)
    if not target then return "" end
    -- World RMB (Java ArrayList of IsoObjects) ? no item-style meta applies.
    -- The target card shows the object name instead; meta stays empty.
    if isJavaList(target) then return "" end
    -- Inventory RMB ? unwrap and probe the first selected item
    local item = target
    if type(target) == "table" then
        item = firstInventoryItem(target) or item
    end
    if type(item) ~= "userdata" and type(item) ~= "table" then return "" end
    -- Try in order of specificity
    local m = formatFluidMeta(item)
    if m then return m end
    m = formatLiteratureMeta(item)
    if m then return m end
    m = formatFoodMeta(item)
    if m then return m end
    m = formatWeaponMeta(item)
    if m then return m end
    m = formatClothingMeta(item)
    if m then return m end
    return ""
end

-- Given a Java ArrayList of IsoObjects from a world RMB, pick the most
-- meaningful object to display on the target card. Priority order:
--   1. IsoGameCharacter (player, zombie, animal, NPC) ? identified by the
--      getDescriptor method
--   2. Named world objects (doors, windows, vehicles, containers) ? anything
--      whose getName()/getObjectName() returns a non-empty, non-placeholder
--   3. Any IsoDeadBody
-- Falls back to {nil, nil} ? caller uses "Ground" default.
local function pickWorldObject(list)
    if not isJavaList(list) then return nil end
    local sz = 0
    pcall(function() sz = list:size() end)
    -- Pass 1: characters
    for i = 0, sz - 1 do
        local obj = list:get(i)
        if obj and safeCall(obj, "getDescriptor") then
            return obj, (safeCall(obj, "getFullName")
                         or safeCall(obj, "getDisplayName")
                         or safeCall(obj, "getName")
                         or "Survivor")
        end
    end
    -- Pass 2: named objects
    for i = 0, sz - 1 do
        local obj = list:get(i)
        if obj then
            local name = safeCall(obj, "getName") or safeCall(obj, "getObjectName")
            if name and name ~= "" and name ~= "null" and name ~= "IsoObject" then
                return obj, name
            end
        end
    end
    -- Pass 3: corpses (getCorpse / isCorpse flags vary; just check class name)
    for i = 0, sz - 1 do
        local obj = list:get(i)
        if obj then
            local cls = safeCall(obj, "getClass")
            local clsName = cls and safeCall(cls, "getName") or ""
            if clsName:find("IsoDeadBody") then
                return obj, "Corpse"
            end
        end
    end
    return nil
end

-- Name + icon for the target card.
--   - Inventory RMB ? first selected item's display name + its texture
--   - World RMB     ? first significant world object, else "Ground"
function Registry.getTargetDisplay(target)
    if not target then return "", nil end

    -- World RMB (Java ArrayList)
    if isJavaList(target) then
        local obj, name = pickWorldObject(target)
        if obj and name then
            local tex = safeCall(obj, "getTexture") or safeCall(obj, "getSprite")
            return name, tex
        end
        return "Ground", nil
    end

    -- Inventory RMB (Lua table)
    if type(target) == "table" then
        local item = firstInventoryItem(target)
        if item then
            local name = safeCall(item, "getDisplayName")
                         or safeCall(item, "getName") or "Item"
            local tex = safeCall(item, "getTexture")
            return name, tex
        end
        return "Selection", nil
    end

    -- Single userdata object (rare path ? direct IsoObject)
    if type(target) == "userdata" then
        local name = safeCall(target, "getDisplayName") or safeCall(target, "getName")
        if name and name ~= "" then
            local tex = safeCall(target, "getTexture")
            return name, tex
        end
    end

    return "", nil
end

-- Expose
ZeD.ContextMenu.Registry = Registry

return Registry
