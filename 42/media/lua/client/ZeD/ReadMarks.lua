-- ZeD-UI/42/media/lua/client/ZeD/ReadMarks.lua
-- ============================================================================
-- READ MARKS in the item lists (mockup ZeDUI/mockups/zed_read_marks_v1.html, style B; approved Oct 26 2026).
--
-- The game remembers what the character has read: the pages read in each skill book, the maps, fliers and
-- brochures, the titled books, the tapes and discs, the recipes known. This reads those records (the same
-- calls as the game's own tick in ISInventoryPane:isLiteratureRead, and the ones Has Been Read makes) and
-- gives each readable item a status the lists draw:
--   * list view: a square mark and a word in the COND column (books have no condition, so it is empty for
--     them); where the column is hidden, the mark alone at the end of the name;
--   * grid view: the mark in the cell's free corner (bottom left);
--   * a "Next level" tag on a skill book that suits the character's next level (in the grid, a small arrow);
--   * a hover card (the library's detail card) in the game's own words.
-- Shape carries the meaning, colour backs it up: the 6u status square, hollow for unread, its left half filled
-- for part read (or some recipes known), full for read; the accent for unread and part read, the green "good"
-- colour for read. A skill book below the character's level counts as read (the game teaches nothing more
-- from it). "Dim read items" in ZeD setup (off by default) fades the read ones.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"

ZeD = ZeD or {}
ZeD.ReadMarks = ZeD.ReadMarks or {}
local R = ZeD.ReadMarks

ZeD.trDefaults({
    UI_ZeD_Read_Unread = "Unread", UI_ZeD_Read_Read = "Read", UI_ZeD_Read_Known = "Known",
    UI_ZeD_Read_Watched = "Watched", UI_ZeD_Read_NotWatched = "Not watched",
    UI_ZeD_Read_Heard = "Heard", UI_ZeD_Read_NotHeard = "Not heard",
    UI_ZeD_Read_Pages = "%1 of %2", UI_ZeD_Read_SomeKnown = "%1 of %2 known",
    UI_ZeD_Read_NextLevel = "Next level", UI_ZeD_Read_NextFor = "Good for your next level: %1",
    UI_ZeD_Read_PastLevels = "Your %1 is %2, past this book's levels (%3 to %4)",
    UI_ZeD_Read_ForLevels = "for %1 %2 to %3 (you have %4)",
    UI_ZeD_Read_KnownList = "Known: %1", UI_ZeD_Read_NotKnownList = "Not known: %1",
    UI_ZeD_Read_NotWatchedYet = "Not watched yet.", UI_ZeD_Read_NotHeardYet = "Not heard yet.",
    UI_ZeD_Read_AlreadyHeard = "Already heard.",
})

local CACHE_MS = 1000     -- a list asks for every visible row each frame: the records are read again once a second

local function call(o, m, ...)
    if o == nil then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end

-- ----------------------------------------------------------------------------
-- The status
-- ----------------------------------------------------------------------------
local function recipeName(name)
    if getRecipeDisplayName then
        local ok, s = pcall(getRecipeDisplayName, name)
        if ok and s and s ~= "" then return s end
    end
    return tostring(name)
end

local function perkName(perk)
    local pk = perk and PerkFactory and PerkFactory.getPerk(perk)
    return pk and tostring(pk:getName()) or ""
end

-- a skill book's status, or nil when it is not one
local function skillBook(p, item, s)
    local skill = call(item, "getSkillTrained")
    local sb = skill and SkillBook and SkillBook[skill]
    if not (sb and sb.perk) then return nil end
    local lvl = p:getPerkLevel(sb.perk)
    local lo, hi = call(item, "getLvlSkillTrained") or 0, call(item, "getMaxLevelTrained") or 0
    local pname = perkName(sb.perk)
    local pages = call(item, "getNumberOfPages") or 0
    local done = (pages > 0) and (p:getAlreadyReadPages(item:getFullType()) or 0) or 0
    local pagesLine = getText("IGUI_Pages") .. " " .. ZeD.tr("UI_ZeD_Read_Pages", done, pages)
    if hi < lvl + 1 then
        -- past the book's levels: read, as the game (and its tick) has it
        s.st, s.word = "r", ZeD.tr("UI_ZeD_Read_Read")
        s.lines = { getText("Tooltip_literature_HasBeenRead"), ZeD.tr("UI_ZeD_Read_PastLevels", pname, lvl, lo, hi) }
        return s
    end
    if pages > 0 and done >= pages then
        s.st, s.word = "r", ZeD.tr("UI_ZeD_Read_Read")
        s.lines = { getText("Tooltip_literature_HasBeenRead"), pagesLine }
    elseif done > 0 then
        s.st, s.word = "p", ZeD.tr("UI_ZeD_Read_Pages", done, pages)
        s.short = tostring(math.floor(done * 100 / pages)) .. "%"   -- (a narrow COND column)
        s.lines = { pagesLine }
    else
        s.st, s.word = "u", ZeD.tr("UI_ZeD_Read_Unread")
        s.lines = { getText("Tooltip_literature_NotBeenRead"), pagesLine }
    end
    if s.st ~= "r" and lo <= lvl + 1 and lvl + 1 <= hi then
        s.next = pname .. " " .. tostring(lvl + 1)
    elseif s.st ~= "r" then
        s.lines[#s.lines] = s.lines[#s.lines] .. " | " .. ZeD.tr("UI_ZeD_Read_ForLevels", pname, lo, hi, lvl)
    end
    return s
end

-- a recipe magazine's status (the recipes it teaches against the ones known), or nil
local function recipeBook(p, item, s)
    local list = call(item, "getLearnedRecipes")
    local n = list and list:size() or 0
    if n == 0 then return nil end
    local known = p:getKnownRecipes()
    local yes, no = {}, {}
    for i = 0, n - 1 do
        local r = list:get(i)
        if known:contains(r) then yes[#yes + 1] = recipeName(r) else no[#no + 1] = recipeName(r) end
    end
    if #no == 0 then
        s.st, s.word = "r", ZeD.tr("UI_ZeD_Read_Known")
        s.lines = { getText("Tooltip_literature_HasBeenRead"), ZeD.tr("UI_ZeD_Read_KnownList", table.concat(yes, ", ")) }
    elseif #yes > 0 then
        s.st, s.word = "p", ZeD.tr("UI_ZeD_Read_SomeKnown", #yes, n)
        s.short = tostring(#yes) .. "/" .. tostring(n)
        s.lines = { getText("Tooltip_literature_AlreadyKnown"),
            ZeD.tr("UI_ZeD_Read_KnownList", table.concat(yes, ", ")) .. " | " .. ZeD.tr("UI_ZeD_Read_NotKnownList", table.concat(no, ", ")) }
    else
        s.st, s.word = "u", ZeD.tr("UI_ZeD_Read_Unread")
        s.lines = { getText("Tooltip_literature_NotBeenRead"), getText("Tooltip_Literature_LearnedRecipes", table.concat(no, ", ")) }
    end
    return s
end

local function readOrNot(s, read)
    if read then s.st, s.word, s.lines = "r", ZeD.tr("UI_ZeD_Read_Read"), { getText("Tooltip_literature_HasBeenRead") }
    else s.st, s.word, s.lines = "u", ZeD.tr("UI_ZeD_Read_Unread"), { getText("Tooltip_literature_NotBeenRead") } end
    return s
end

-- The status of an item for a player, or nil when it is nothing the game keeps a read record for:
-- { st = "u" | "p" | "r", word = the COND column's word, lines = the hover text, next = "Mechanics 4" or nil }
function R.compute(p, item)
    if not (p and item) then return nil end
    local s = {}
    -- tapes and discs: all or nothing (the game says whether every line has been heard)
    if call(item, "isRecordedMedia") then
        local video = call(item, "getMediaType") == 1
        local done = call(item, "hasBeenSeen", p) or call(item, "hasBeenHeard", p)
        if video then
            s.st, s.word = done and "r" or "u", ZeD.tr(done and "UI_ZeD_Read_Watched" or "UI_ZeD_Read_NotWatched")
            s.lines = { done and getText("ContextMenu_Watched") or ZeD.tr("UI_ZeD_Read_NotWatchedYet") }
        else
            s.st, s.word = done and "r" or "u", ZeD.tr(done and "UI_ZeD_Read_Heard" or "UI_ZeD_Read_NotHeard")
            s.lines = { ZeD.tr(done and "UI_ZeD_Read_AlreadyHeard" or "UI_ZeD_Read_NotHeardYet") }
        end
        return s
    end
    if call(item, "IsMap") then return readOrNot(s, p:hasReadMap(item)) end
    if not call(item, "IsLiterature") then return nil end
    if call(item, "canBeWrite") then return nil end          -- a notebook or journal: written in, not read
    local md = item:hasModData() and item:getModData() or nil
    -- (the game titles every recipe magazine by its type, so the title read and the recipes known are both asked)
    local title = md and md.literatureTitle
    local titleRead = title and p:isLiteratureRead(title) or false
    if md then
        if md.printMedia ~= nil and md.printMedia.title then return readOrNot(s, p:isPrintMediaRead(md.printMedia.title)) end
        if md.learnedRecipe ~= nil then return readOrNot(s, titleRead or p:getKnownRecipes():contains(md.learnedRecipe)) end
    end
    local sk = skillBook(p, item, s)
    if sk then return sk end
    local rb = recipeBook(p, item, s)
    if rb then
        if titleRead and rb.st ~= "r" then rb.st, rb.word, rb.short = "r", ZeD.tr("UI_ZeD_Read_Read"), nil; table.insert(rb.lines, 1, getText("Tooltip_literature_HasBeenRead")) end
        return rb
    end
    if title then return readOrNot(s, titleRead) end
    -- pages kept with no skill (the game's own test)
    local pages = call(item, "getNumberOfPages") or 0
    if pages > 0 then
        local done = p:getAlreadyReadPages(item:getFullType()) or 0
        if done >= pages then return readOrNot(s, true) end
        if done > 0 then
            s.st, s.word = "p", ZeD.tr("UI_ZeD_Read_Pages", done, pages)
            s.lines = { getText("IGUI_Pages") .. " " .. ZeD.tr("UI_ZeD_Read_Pages", done, pages) }
            return s
        end
        return readOrNot(s, false)
    end
    return nil
end

-- the same, kept for a second (per player and item; the whole table starts over each second and at a language change)
local _cache, _cacheAt, _cacheGen, _cacheP = {}, 0, nil, nil
local NONE = {}
function R.state(p, item)
    if not (p and item) then return nil end
    if not R.on() then return nil end
    local now = getTimestampMs()
    if now - _cacheAt > CACHE_MS or _cacheGen ~= ZeD._trGen or _cacheP ~= p then
        _cache, _cacheAt, _cacheGen, _cacheP = {}, now, ZeD._trGen, p
    end
    local s = _cache[item]
    if s == nil then
        local ok, r = pcall(R.compute, p, item)
        s = (ok and r) or NONE
        _cache[item] = s
    end
    if s == NONE then return nil end
    return s
end
function R.clear() _cache, _cacheAt = {}, 0 end

-- ZeD setup's switches: "Read marks in item lists", "Next level on skill books" (both off for a new player since
-- Oct 30 2026, the Vanilla preset); off, the lists are as before
function R.on()
    local S = ZeD.Settings
    return S and S.readMarksOn and S.readMarksOn() or false
end
function R.nextOn()
    local S = ZeD.Settings
    return S and S.readNextOn and S.readNextOn() or false
end

-- "Dim read items" (ZeD setup, off by default)
function R.dimOn()
    local S = ZeD.Settings
    return S and S.dimReadOn and S.dimReadOn() or false
end

-- ----------------------------------------------------------------------------
-- The marks: the library's 6u status squares; the grid's next-level arrow in
-- pixel art (one unit = one art pixel at the whole zoom T.art)
-- ----------------------------------------------------------------------------
local UP = { "..o..", ".oao.", "oaaao", "ooooo" }
-- each picture as runs { x, y, w, ch } (ch: the character that colours it)
local function runs(rows)
    local out = {}
    for y, row in ipairs(rows) do
        local x = 1
        while x <= #row do
            local ch = row:sub(x, x)
            if ch ~= "." then
                local x2 = x
                while x2 < #row and row:sub(x2 + 1, x2 + 1) == ch do x2 = x2 + 1 end
                out[#out + 1] = { x - 1, y - 1, x2 - x + 1, ch }
                x = x2 + 1
            else
                x = x + 1
            end
        end
    end
    return out
end
local UP_RUNS = runs(UP)
R.UP_W, R.UP_H = 5, 4

local function k() local T = ZeD.T; return math.max(1, (T and T.art) or 1) end
R.k = k
-- the mark's side: the one status square (6u)
function R.markSize() return ZeD.T.px(6) end
R.DOT_W = 6   -- (design units; older readers measured the mark from it with k())
-- the COND column's room for the mark and the short statuses (Unread, Read, Known) in F3, with the
-- mark's own lead (InventoryRenderer sizes the column from it)
function R.wordRoom()
    local T, tm = ZeD.T, ZeD.TM
    local w = 0
    for _, key in ipairs({ "UI_ZeD_Read_Unread", "UI_ZeD_Read_Read", "UI_ZeD_Read_Known" }) do
        w = math.max(w, tm:MeasureStringX(T.fontF3, ZeD.tr(key)))
    end
    return T.px(6) + R.markSize() + T.px(5) + w
end
-- the mark's colour: the green "good" colour for read, the accent text colour for the rest
function R.color(st)
    local T = ZeD.T
    return (st == "r") and T.positive or (T.accentText or T.accent)
end
-- the status square with its top left at x, y: full (read), its left half filled (part read), hollow (unread)
function R.drawMark(el, x, y, st)
    local A = ZeD.Atoms
    local c = R.color(st)
    local sq = R.markSize()
    if st == "r" then A.drawStatusDot(el, x, y, c, sq)
    elseif st == "p" then A.drawStatusHalf(el, x, y, c, sq)
    else A.drawStatusHollow(el, x, y, c, sq) end
end
R.drawDot = R.drawMark   -- (the older name: it was a round dot)
-- the next level's arrow (5 x 4) in the grid: the accent, outlined in the window's strong line colour
function R.drawUp(el, x, y)
    local T = ZeD.T
    local ac = T.accentText or T.accent
    local ol = T.borderS
    local kk = k()
    for _, r in ipairs(UP_RUNS) do
        local c = (r[4] == "a") and ac or ol
        el:drawRect(x + r[1] * kk, y + r[2] * kk, r[3] * kk, kk, (r[4] == "a") and 1 or (ol.a or 1), c.r, c.g, c.b)
    end
end

return R
