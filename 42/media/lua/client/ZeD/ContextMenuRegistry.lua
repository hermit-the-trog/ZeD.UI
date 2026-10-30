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
require "ZeD/ContextPxIcons" -- provides ZeD.ContextPxIcons (the pixel icon for each picture)
require "ZeD/Tr"              -- ZeD.tr

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

-- ----------------------------------------------------------------------------
-- TRANSLATED KEYS
-- The keyword list above and the icon table are written in English. For other
-- languages the same words come from vanilla's own translation keys
-- (ZeD.ContextIconKeys and ZeD.ContextCategoryKeys, generated into
-- ContextIcons.lua by tools/i18n/rekey_icons.py). Each key is read through
-- getText once, the first time a menu needs it; the English words stay as the
-- fallback for options that mods add without keys.
-- ----------------------------------------------------------------------------

-- Stand-ins passed as getText arguments, so a key with %1..%4 in it comes back
-- with these marks where the values go. That is how a label with a changing
-- part ("Empty %1") becomes a pattern instead of one fixed word.
local SENTINELS = { string.char(1), string.char(2), string.char(3), string.char(4) }

-- A key is a translation key ("ContextMenu_Walk_to") or an item type
-- ("Base.Sausage"); anything with spaces is an English display name.
local function looksLikeKey(name)
    if type(name) ~= "string" then return false end
    return name:find("^%a[%w]*_[%w_]+$") ~= nil or name:find("^%a+%.[%w_]+$") ~= nil
end

local function isItemType(key)
    return key:find("^%a+%.[%w_]+$") ~= nil
end

-- Returns the key's text in the player's language and whether it holds
-- placeholders, or nil when the game has no text for it.
local function translateKey(key)
    local ok, text
    if isItemType(key) then
        if not getItemNameFromFullType then return nil end
        ok, text = pcall(getItemNameFromFullType, key)
        if ok and type(text) == "string" and text ~= "" and text ~= key then return text, false end
        return nil
    end
    ok, text = pcall(getText, key, SENTINELS[1], SENTINELS[2], SENTINELS[3], SENTINELS[4])
    if not ok or type(text) ~= "string" or text == "" or text == key then return nil end
    for i = 1, #SENTINELS do
        if text:find(SENTINELS[i], 1, true) then return text, true end
    end
    return text, false
end

local _localizedCategories = nil   -- { {lowercase word, category}, ... } in the player's language

local function firstWordOf(s)
    local sp = s:find(" ", 1, true)
    if sp then return s:sub(1, sp - 1) end
    return s
end

-- True when the text holds a Chinese, Japanese or Korean character (code 0x2E80
-- and up), where one character is already a whole word.
local function hasWideChar(s)
    for i = 1, #s do
        if string.byte(s, i) >= 0x2E80 then return true end
    end
    return false
end

-- A group word has to be long enough not to turn up inside unrelated labels:
-- three letters, or a single character in Chinese, Japanese or Korean.
local function wordLongEnough(low)
    return #low >= 3 or (#low >= 1 and hasWideChar(low))
end

local function buildLocalizedCategories()
    _localizedCategories = {}
    local rows = ZeD.ContextCategoryKeys
    if not rows then return end
    local byKeyword = {}
    for _, row in ipairs(rows) do
        local list = byKeyword[row[1]]
        if not list then list = {}; byKeyword[row[1]] = list end
        list[#list + 1] = row
    end
    local seen = {}
    -- Words taken whole from a key go first. Words that are only the first word
    -- of a longer key ("first" rows) come second, so a common opening word such
    -- as "Take" never claims a label a whole-word key already owns. Within each
    -- round the English list order is kept, which is the category order.
    for round = 1, 2 do
        local wantFirstWord = (round == 2)
        for _, pair in ipairs(Registry.CATEGORY_KEYWORDS) do
            local english = string.lower(pair[1])
            for _, row in ipairs(byKeyword[pair[1]] or {}) do
                local firstOnly = row[#row] == "first"
                if firstOnly == wantFirstWord then
                    local last = #row
                    if firstOnly then last = last - 1 end
                    for i = 2, last do
                        local text, hasPlaceholder = translateKey(row[i])
                        if text and not hasPlaceholder then
                            if firstOnly then text = firstWordOf(text) end
                            local low = string.lower(text)
                            if wordLongEnough(low) and low ~= english and not seen[low] then
                                seen[low] = true
                                _localizedCategories[#_localizedCategories + 1] = { low, pair[2] }
                            end
                        end
                    end
                end
            end
        end
    end
end

-- The group the English keyword list gives a name, or nil when no keyword is in it.
function Registry.englishCategory(name)
    local lower = string.lower(tostring(name or ""))
    for _, pair in ipairs(Registry.CATEGORY_KEYWORDS) do
        if string.find(lower, string.lower(pair[1]), 1, true) then return pair[2] end
    end
    return nil
end

-- Whole labels in the player's language with a known group: { lowercase label = group }.
-- A label that is exactly a known option ("Equip Primary" in Russian opens with the word for
-- "take") keeps that option's group, ahead of any group word found inside it.
function Registry.exactCategories()
    if Registry._exactCategories then return Registry._exactCategories end
    local exact = {}
    Registry._exactCategories = exact
    local function add(key, cat)
        if not (key and cat) then return end
        local text, hasPlaceholder = translateKey(key)
        if text and not hasPlaceholder then
            local low = string.lower(text)
            -- a label the English keyword list already places elsewhere keeps that group
            -- (English "Open and Drink" stays with Drink, not Open)
            local eng = Registry.englishCategory(text)
            if exact[low] == nil and (eng == nil or eng == cat) then exact[low] = cat end
        end
    end
    local groupOf = {}
    for _, pair in ipairs(Registry.CATEGORY_KEYWORDS) do groupOf[pair[1]] = pair[2] end
    -- the group rows: the whole-text rows first, then the first-word rows' whole text
    for round = 1, 2 do
        for _, row in ipairs(ZeD.ContextCategoryKeys or {}) do
            local last = #row
            local firstOnly = row[last] == "first"
            if firstOnly then last = last - 1 end
            if firstOnly == (round == 2) then
                for i = 2, last do add(row[i], groupOf[row[1]]) end
            end
        end
    end
    -- the icon rows: each key's text takes the group its English name has
    for _, rows in ipairs({ ZeD.ContextIconKeys or {}, ZeD.ContextIconVerbKeys or {} }) do
        for _, row in ipairs(rows) do
            local cat = Registry.englishCategory(row[1])
            if cat then
                for i = 2, #row do add(row[i], cat) end
            end
        end
    end
    return exact
end

function Registry.categorize(optionName)
    if not optionName or optionName == "" then return "ACTION" end
    local lower = string.lower(optionName)
    -- a label that is exactly a known option keeps that option's group
    local whole = Registry.exactCategories()[lower]
    if whole then return whole end
    -- the player's language first, then the English words
    if not _localizedCategories then buildLocalizedCategories() end
    for _, pair in ipairs(_localizedCategories) do
        if string.find(lower, pair[1], 1, true) then
            return pair[2]
        end
    end
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

-- A picture name drawn by ZeD's pixel icon (ZeD.ContextPxIcons, Oct 28 2026) gives its
-- 16 drawing and its id: the cell draws the id's drawing that fits its icon box, at its
-- own size (ZeD.Atoms.drawPxIcon). A name a mod adds keeps its picture from icons/.
local _iconCache = {}
local function getIconTexture(codepoint)
    if not codepoint then return nil end
    local id = ZeD.ContextPxIcons and ZeD.ContextPxIcons[codepoint]
    if id and ZeD.PxIcon and ZeD.PxIcon.has(id) then return ZeD.PxIcon.tex(id, 16), id end
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

-- Labels with a changing part ("Empty %1"): { Lua pattern, codepoint } pairs.
local _patternList = nil

-- A Lua pattern for a label that holds placeholders: the fixed words must match,
-- each placeholder matches any text. Returns nil when too little is fixed (a
-- label that is nearly all placeholder would match everything). Spaces and
-- punctuation do not count as fixed: "%2 (%1)" says nothing about the label.
local function patternForPlaceholderText(text)
    local fixed = text
    for i = 1, #SENTINELS do fixed = fixed:gsub(SENTINELS[i], "") end
    fixed = fixed:gsub("[%s%p]", "")
    if #fixed < 3 and not (#fixed >= 2 and hasWideChar(fixed)) then return nil end
    local p = text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
    for i = 1, #SENTINELS do p = p:gsub(SENTINELS[i], ".-") end
    return "^" .. p .. "$"
end

-- English names whose keys are put in the cache before everything else, so they keep
-- their icon when another option's translation reads exactly the same.
Registry.PRIORITY_NAMES = { ["Walk to"] = true }

local function buildTranslatedCache()
    _translatedNameCache = {}
    _firstWordCache = {}
    _patternList = {}
    local icons = ZeD.ContextIcons
    if not icons then return end

    -- A name already in the cache keeps its first icon, so the order below is
    -- the order of authority: keyed entries, then keys found for the English
    -- names, then the English names themselves.
    local function put(name, cp)
        if name and cp and _translatedNameCache[name] == nil then
            _translatedNameCache[name] = cp
        end
    end
    local function putKey(key, cp)
        local text, hasPlaceholder = translateKey(key)
        if not text then return end
        if hasPlaceholder then
            local pat = patternForPlaceholderText(text)
            if pat then _patternList[#_patternList + 1] = { pat, cp } end
        else
            put(text, cp)
        end
    end

    -- Pass 1a and 1b run twice. The first round takes the vanilla context-menu
    -- keys ("ContextMenu_...") only, the second everything else (interface and
    -- fluid wording, item names), so when two words read alike the option the
    -- player actually right-clicks wins over a label from another screen.
    -- Within a round, keyed entries come before the keys found for the English
    -- names, and the keyed entries are sorted so the result never changes
    -- between runs.
    local keyed = {}
    for name in pairs(icons) do
        if looksLikeKey(name) then keyed[#keyed + 1] = name end
    end
    table.sort(keyed)
    -- Rows are { English name, key, key, ... }; the icon is the English name's.
    -- ZeD.ContextIconKeys holds the keys that read exactly as the name;
    -- ZeD.ContextIconVerbKeys holds the keys that only start with a one-word
    -- name ("Open Door" under "Open"), so they come after.
    local rowSets = { ZeD.ContextIconKeys or {}, ZeD.ContextIconVerbKeys or {} }
    for round = 1, 2 do
        local contextOnly = (round == 1)
        -- Pass 0: the names that win when a language gives two options the same words
        -- (Chinese reads "Walk to" and "Move To" alike; Walk to keeps its icon).
        for _, rows in ipairs(rowSets) do
            for _, row in ipairs(rows) do
                local cp = icons[row[1]]
                if cp and Registry.PRIORITY_NAMES[row[1]] then
                    for i = 2, #row do
                        if (row[i]:sub(1, 12) == "ContextMenu_") == contextOnly then putKey(row[i], cp) end
                    end
                end
            end
        end
        -- Pass 1a: entries keyed by a translation key.
        for _, key in ipairs(keyed) do
            if (key:sub(1, 12) == "ContextMenu_") == contextOnly then putKey(key, icons[key]) end
        end
        -- Pass 1b: the keys found for the English names.
        for _, rows in ipairs(rowSets) do
            for _, row in ipairs(rows) do
                local cp = icons[row[1]]
                if cp then
                    for i = 2, #row do
                        if (row[i]:sub(1, 12) == "ContextMenu_") == contextOnly then putKey(row[i], cp) end
                    end
                end
            end
        end
    end

    -- Pass 1c: the display names as written (English, and any a mod adds
    -- without a key).
    for name, cp in pairs(icons) do put(name, cp) end

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

    -- Labels with a changing part ("Empty %1" in the player's language).
    for _, entry in ipairs(_patternList) do
        if string.find(optionName, entry[1]) then return getIconTexture(entry[2]) end
    end

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

-- Forget what was read from the translations, so the next menu reads it again.
-- Call after a mod adds entries to ZeD.ContextIcons once menus are already open.
function Registry.resetTranslatedCaches()
    _translatedNameCache = nil
    _firstWordCache = nil
    _patternList = nil
    _localizedCategories = nil
    Registry._exactCategories = nil
end

-- For checking another language in the game console: how much of the map the
-- current language filled in, and what a given label resolves to.
--   ZeD.ContextMenu.Registry.debugTranslated("Marcher vers")
function Registry.debugTranslated(label)
    if not _translatedNameCache then buildTranslatedCache() end
    if not _localizedCategories then buildLocalizedCategories() end
    local names, patterns, words = 0, #_patternList, #_localizedCategories
    for _ in pairs(_translatedNameCache) do names = names + 1 end
    print("[ZeD.ContextMenu] language map: " .. names .. " names, " .. patterns
          .. " patterns, " .. words .. " group words")
    if label then
        local cp = _translatedNameCache[label]
        local how = cp and "exact" or nil
        if not cp then
            for _, entry in ipairs(_patternList) do
                if string.find(label, entry[1]) then cp = entry[2]; how = "pattern"; break end
            end
        end
        if not cp then
            local fw = _firstWord(label)
            cp = fw ~= label and _firstWordCache[fw] or nil
            if cp then how = "first word" end
        end
        print("[ZeD.ContextMenu] '" .. tostring(label) .. "' icon: " .. tostring(cp)
              .. " (" .. tostring(how) .. "), group: " .. Registry.categorize(label))
    end
end

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
    def.iconTexture, def.pxIcon = resolveIconForName(option.name)
    if def.iconTexture then
        def.iconTintable = true
    else
        def.iconTexture = option.iconTexture or nil
        if not def.iconTexture and option.itemForTexture and option.itemForTexture.getTexture then
            local ok, tex = pcall(function() return option.itemForTexture:getTexture() end)
            if ok then def.iconTexture = tex end
        end
    end

    -- An option ZeD adds may say more than vanilla's fields (Oct 29 2026, the
    -- loadouts' Save to outfit / Save to loadout): zedPx = its pixel icon's id,
    -- zedCategory = its group (a rule between groups in the list look), zedCheck =
    -- a checkbox (true / false) in the icon's place in both looks.
    if option.zedPx and ZeD.PxIcon and ZeD.PxIcon.has(option.zedPx) then
        def.iconTexture, def.pxIcon, def.iconTintable = ZeD.PxIcon.tex(option.zedPx, 16), option.zedPx, true
    end
    if option.zedCategory then def.category = option.zedCategory end
    if option.zedCheck ~= nil then def.check = option.zedCheck and true or false end

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
        local txt = ZeD.tr("UI_ZeD_Meta_FluidAmount", string.format("%.1f", amount), string.format("%.1f", capacity))
        if fluidPart ~= "" then txt = txt .. " | " .. fluidPart end
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
        parts[#parts + 1] = ZeD.tr("UI_ZeD_Meta_Hunger", string.format("%+d", math.floor(hunger * 100 + 0.5)))
    end
    local age = safeCall(item, "getAge")
    local offAge = safeCall(item, "getOffAge")
    if age and offAge and offAge > 0 then
        local freshPct = math.floor((1 - age / offAge) * 100 + 0.5)
        if freshPct < 50 then parts[#parts + 1] = ZeD.tr("Tooltip_food_Stale")
        elseif freshPct < 85 then parts[#parts + 1] = ZeD.tr("UI_ZeD_Meta_Ripe")
        else parts[#parts + 1] = ZeD.tr("Tooltip_food_Fresh") end
    end
    if #parts == 0 then return nil end
    return table.concat(parts, " | ")
end

local function formatWeaponMeta(item)
    local cond = safeCall(item, "getConditionPercent")
    local parts = {}
    if cond then parts[#parts + 1] = ZeD.tr("UI_ZeD_Meta_Condition", tostring(cond)) end
    local current = safeCall(item, "getCurrentAmmoCount")
    local max = safeCall(item, "getMaxAmmo")
    if current and max and max > 0 then
        parts[#parts + 1] = string.format("%d / %d", current, max)
    end
    if #parts == 0 then return nil end
    return table.concat(parts, " | ")
end

local function formatClothingMeta(item)
    local parts = {}
    local wet = safeCall(item, "getWetness")
    if wet and wet > 0 then
        parts[#parts + 1] = ZeD.tr("UI_ZeD_Meta_Wet", math.floor(wet))
    end
    local bite = safeCall(item, "getBiteDefense")
    if bite and bite > 0 then
        parts[#parts + 1] = ZeD.tr("UI_ZeD_Meta_Bite", math.floor(bite))
    end
    if #parts == 0 then return nil end
    return table.concat(parts, " | ")
end

local function formatLiteratureMeta(item)
    local pages = safeCall(item, "getNumberOfPages")
    local read = safeCall(item, "getAlreadyReadPages")
    if pages and pages > 0 then
        if read and read > 0 then
            return ZeD.tr("UI_ZeD_Meta_PagesRead", read, pages)
        end
        return ZeD.tr("UI_ZeD_Meta_Pages", pages)
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
                         or ZeD.tr("UI_ZeD_Target_Survivor"))
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
                return obj, ZeD.tr("IGUI_ItemCat_Corpse")
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
        return ZeD.tr("IGUI_ContainerTitle_floor"), nil
    end

    -- Inventory RMB (Lua table)
    if type(target) == "table" then
        local item = firstInventoryItem(target)
        if item then
            local name = safeCall(item, "getDisplayName")
                         or safeCall(item, "getName") or ZeD.tr("IGUI_Item")
            local tex = safeCall(item, "getTexture")
            return name, tex
        end
        return ZeD.tr("UI_ZeD_Target_Selection"), nil
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
