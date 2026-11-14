-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/ImmersiveSearching.lua
-- ============================================================================
-- SUPPORT FOR IMMERSIVE SEARCHING [B42MP] (mod id ImmersiveSearching, Workshop
-- 3760450908, by kitsuneyuki (yuckyfox); its add-on OpenAllContainersISCompat
-- needs nothing here). Client.
--
-- The mod hides a container's things until the character searches it, a timed
-- action of its own (ImmersiveSearching_ISSearch: its sound, its animation,
-- its time from the contents, the light, Dextrous / All Thumbs and Foraging),
-- that reveals them one by one, heaviest first, from a fifth of the way in.
-- A search is kept per container and per player in mod data. In the game's
-- pages it wraps ISInventoryPane:refreshContainer (only the revealed things
-- list), ISInventoryPage:selectContainer (picking a container starts the
-- search), the loot window handlers' shouldBeVisible (Take all, Same type, To
-- floor, Transfer all... hide until searched) and, on the Java side,
-- ItemContainer.hasRoomFor (nothing goes into a container never searched) and
-- getCapacityWeight (0 until searched). ZeD's windows list containers
-- themselves, so none of that reached them.
--
-- What this file does, all through ZeD's general hooks and the mod's own
-- functions and data (the mod's page asks that it not be altered; nothing of
-- it is changed or copied):
--   * the strips (StripDecorators.lua): a small "?" chip in the top right of
--     a container's button while it is not searched (a search under way too);
--   * the lists (ContainerGates.lua): an unsearched container lists only what
--     the mod has revealed, read from ImmersiveSearching.Items[container]
--     (.Searched by item id; a thing put in after the search began shows, as
--     in the mod's own list), so things turn up as the mod reveals them;
--     before a search the empty line reads "Not searched.", and the weight line
--     the gate's words ("Not searched", "Searching...") in place of the
--     mod's 0 kg;
--   * the band (ContainerControls.lua): the moves (Take all, Same type, To
--     floor; on your side Transfer all and both Same types) are left out for
--     an unsearched container, as the mod hides the game's; a status line, the
--     moving bar while the search runs (the mod's own action, its job delta),
--     Search (the main button) and Search all;
--   * moves and drops into a container never searched are refused, as the
--     mod's hasRoomFor refuses them (a search under way lets things in, as
--     its hasRoomFor does); the band's moves into it are off;
--   * a container a ZeD list starts showing (a pick in a strip, a column
--     added, the pad) starts the mod's search the way the game's page does:
--     ZeD presses the game's own page for that container
--     (ISInventoryPage:selectContainer with its button), which the mod wraps
--     to queue its search. Search does the same. The search, its time, its
--     checks (too dark, driving) and its XP stay the mod's.
--   * Search all: the mod's own rule, from its sandbox (SearchAll: off by
--     default; "every container" or "corpses only"); with it off the button
--     does not show. Each container is started as above, one search after
--     another in the action queue. Too dark for the mod to search at all:
--     only one is started (the mod's action then says why).
-- ZeD stores nothing. ModSupport/<mod id>.lua returns at once unless that
-- mod is on.
-- ============================================================================

local MOD_ID = "ImmersiveSearching"

-- Is the mod switched on? getActivatedMods() is a Java list of mod ids; a
-- workshop id can carry a leading backslash, which is cut off before comparing.
local function modOn()
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    for i = 0, list:size() - 1 do
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
if not modOn() then return end

require "ZeD/Tokens"
require "ZeD/Tr"
require "ZeD/Atoms"
require "ZeD/ContainerGates"
require "ZeD/StripDecorators"
require "ZeD/ContainerControls"
require "ZeD/ZeD_CharacterWindow"   -- (it loads the World window too)

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.ImmersiveSearching = S

local ACTION_TYPE = "ImmersiveSearching_ISSearch"
local PENDING_MS  = 1500   -- a search asked for, not yet in the queue (the mod waits for the character to get up first)

-- The QA scripts read these: the last search ZeD started (reused table) and the decorator's stamps
S.lastStart = { inv = nil, side = nil, how = nil, at = 0, ok = false }
S.badged = setmetatable({}, { __mode = "k" })   -- container -> time its "?" was last drawn

-- ---------------------------------------------------------------------------
-- THE MOD'S OWN ANSWERS (its global table, looked up at the moment of use:
-- its files can load after ours, and its cache is made when the player is)
-- ---------------------------------------------------------------------------
local function api()
    local IS = ImmersiveSearching
    if type(IS) ~= "table" or type(IS.isSearched) ~= "function" or IS.Searched == nil then return nil end
    return IS
end

-- searched (or the mod not ready, or a container it never hides): true
local function isSearched(po, inv)
    local IS = api()
    if not (IS and po and inv) then return true end
    local ok, yes = pcall(IS.isSearched, po, inv)
    if not ok then return true end
    return yes and true or false
end
S.isSearched = isSearched

-- The mod's search of this container in the player's action queue: the
-- action and its place (1 = running now), or nil.
local function searchAction(po, inv)
    local q = ISTimedActionQueue and ISTimedActionQueue.queues and ISTimedActionQueue.queues[po]
    local list = q and q.queue
    if not list then return nil end
    for i, a in ipairs(list) do
        if a and a.Type == ACTION_TYPE and a.container == inv then return a, i end
    end
    return nil
end
S.searchAction = searchAction

local function progressOf(a)
    if not (a and a.action) then return 0 end
    local ok, d = pcall(a.getJobDelta, a)
    if ok and type(d) == "number" then return math.max(0, math.min(1, d)) end
    return 0
end

-- the mod's sandbox for Search all: 1 off, 2 every container, 3 corpses only
local function searchAllMode()
    local sv = SandboxVars and SandboxVars.ImmersiveSearching
    return sv and tonumber(sv.SearchAll) or 1
end

-- ---------------------------------------------------------------------------
-- STARTING A SEARCH: the game's own page, pressed for that container
-- ---------------------------------------------------------------------------
local pending = setmetatable({}, { __mode = "k" })   -- container -> when ZeD asked

local function findButton(page, inv)
    for _, b in ipairs(page and page.backpacks or {}) do
        if b and b.inventory == inv then return b end
    end
    return nil
end

-- The page's button for the container (your inventory's page for a bag you
-- carry, the loot page for the rest; the other page, then the page's own
-- list rebuilt, when it is not there yet).
local function buttonFor(po, inv, side)
    local pn = po:getPlayerNum()
    local inPage, lootPage = getPlayerInventory(pn), getPlayerLoot(pn)
    local first, second = lootPage, inPage
    if side == "char" then first, second = inPage, lootPage end
    local b = findButton(first, inv) or findButton(second, inv)
    if b then return (findButton(first, inv) and first or second), b end
    if first and first.refreshBackpacks then
        pcall(first.refreshBackpacks, first)
        b = findButton(first, inv)
        if b then return first, b end
    end
    return first, nil
end

-- Starts the mod's search of one container (nothing when it is searched, or
-- its search is queued or asked for). how: "pick", "search", "all" (kept in S.lastStart).
function S.start(po, inv, side, how)
    if not (po and inv) or isSearched(po, inv) then return false end
    if searchAction(po, inv) then return false end
    local at = pending[inv]
    local now = getTimestampMs()
    if at and now - at < PENDING_MS then return false end
    local page, button = buttonFor(po, inv, side)
    if not (page and page.selectContainer) then return false end
    -- no button of the game's for it (a container another mod adds to ZeD's
    -- strip): the page is handed the container as its click would hand it
    button = button or { inventory = inv, name = "", capacity = inv:getCapacity() }
    -- the mod's wrapper of selectContainer queues its search, then the game's own runs
    local ok, err = pcall(page.selectContainer, page, button)
    if not ok then print("[ZeD] ImmersiveSearching: starting a search failed: " .. tostring(err)) end
    pending[inv] = now
    local L = S.lastStart
    L.inv, L.side, L.how, L.at, L.ok = inv, side, how, now, ok
    return ok
end

-- Every container in reach that is not searched (and not queued): the World
-- window's, then the bags in the Character window, the mod's sandbox rule
-- applied (corpses only). Returns them in a reused list.
local _all = {}
local function unsearchedInReach(po, skip)
    for i = #_all, 1, -1 do _all[i] = nil end
    if searchAllMode() == 1 then return _all end
    local corpsesOnly = searchAllMode() == 3
    local function add(list)
        for _, e in ipairs(list or {}) do
            local inv = e and e.inventory
            if inv and inv ~= skip and not e.locked and not e.isFloor and not isSearched(po, inv)
               and not searchAction(po, inv) then
                local parent = inv:getParent()
                if not corpsesOnly or (parent and instanceof(parent, "IsoDeadBody")) then
                    _all[#_all + 1] = inv
                end
            end
        end
    end
    -- (po's own windows: in split view each player has a pair)
    local pn = po and po:getPlayerNum() or 0
    local ww = ZeD_WorldWindow and ZeD_WorldWindow.isOpen(pn) and ZeD_WorldWindow.getWindow(pn)
    if ww then add(ww._containers) end
    local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.isOpen and ZeD_CharacterWindow.isOpen(pn) and ZeD_CharacterWindow.getWindow(pn)
    if cw then add(cw._containers) end
    return _all
end
S.unsearchedInReach = unsearchedInReach

-- too dark for the mod to search at all (its own test, its sandbox)
local function cannotSearchForDark(po)
    local IS = api()
    local sv = SandboxVars and SandboxVars.ImmersiveSearching
    if not (IS and sv and IS.tooDark) or tonumber(sv.DarknessPenalty) ~= 100 then return false end
    local ok, dark = pcall(IS.tooDark, po, po:getPlayerNum(), sv.DarknessPenaltyMinLight)
    return ok and dark and true or false
end

function S.searchAll(po)
    if not po then return 0 end
    local wwSet = {}
    local ww = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow(po:getPlayerNum())
    for _, e in ipairs(ww and ww._containers or {}) do if e.inventory then wwSet[e.inventory] = true end end
    local list = unsearchedInReach(po, nil)
    local only = cannotSearchForDark(po)
    local n = 0
    for _, inv in ipairs(list) do
        if S.start(po, inv, wwSet[inv] and "world" or "char", "all") then n = n + 1 end
        if only and n > 0 then break end
    end
    return n
end

-- ---------------------------------------------------------------------------
-- THE GATE (ContainerGates.lua): one table per container, updated in place
-- ---------------------------------------------------------------------------
local gates = setmetatable({}, { __mode = "k" })

local function newGate(inv)
    local g = { inv = inv, noMoves = true, band = {} }
    -- what the mod has revealed so far: its record's Searched ids, and a thing
    -- put in after the search began (not in its Initial list), as its list shows
    g.keep = function(item)
        local r = g.rev
        if not (r and item) then return false end
        local id = item:getID()
        return (r.Searched and r.Searched[id]) or not (r.Initial and r.Initial[id])
    end
    g.specs = function(side, content, inv2)
        return S.specs(side, content, inv2, g)
    end
    return g
end

local function revealedCount(rev)
    local n = 0
    if rev and rev.Searched then for _ in pairs(rev.Searched) do n = n + 1 end end
    return n
end

local function gateFor(inv, po)
    if isSearched(po, inv) then return nil end
    local IS = api()
    if not IS then return nil end
    local g = gates[inv]
    if not g then g = newGate(inv); gates[inv] = g end
    local rev = IS.Items and IS.Items[inv] or nil
    g.rev = rev
    local a, place = searchAction(po, inv)
    local T = ZeD.T
    local band = g.band
    if a and place == 1 then
        g.mode = "searching"
        band.text, band.progress, band.color = ZeD.tr("UI_ZeD_Search_Searching"), progressOf(a), T.info
        g.empty = ZeD.tr("UI_ZeD_Search_EmptyRunning")
    elseif a or (pending[inv] and getTimestampMs() - pending[inv] < PENDING_MS) then
        g.mode = "waiting"
        band.text, band.progress, band.color = ZeD.tr("UI_ZeD_Search_Waiting"), nil, T.info
        g.empty = ZeD.tr("UI_ZeD_Search_EmptyNot")
    else
        g.mode = "unsearched"
        band.text, band.progress, band.color = ZeD.tr("UI_ZeD_Search_NotSearched"), nil, T.warning
        g.empty = ZeD.tr(rev and "UI_ZeD_Search_EmptyRunning" or "UI_ZeD_Search_EmptyNot")
    end
    g.status = band.text
    -- the mod's hasRoomFor: nothing goes in until a search has begun
    g.refuse = (rev == nil)
    -- the list is built again as the mod reveals more
    g.sig = rev and (1 + revealedCount(rev)) or 0
    return g
end

-- The band's button for an unsearched container: Search, the main one, last
-- at the right (until the search is queued).
function S.specs(side, content, inv, g)
    if g.mode ~= "unsearched" then return nil end
    return { { id = "is:search", label = ZeD.tr("UI_ZeD_Search_Search"), enabled = true, primary = true,
        help = ZeD.tr("UI_ZeD_Search_SearchHelp"),
        run = function(ct) S.start(ct._playerObj, ct._inventory, ct._ccSide, "search") end } }
end

ZeD.ContainerGates.add(MOD_ID, gateFor)

-- Search all, in the World window's band whatever container is on show, while
-- the mod's sandbox allows it and some container in reach is unsearched
-- (ContainerControls.addProvider: the row asks again every few frames).
ZeD.ContainerControls.addProvider(MOD_ID, function(side, content, inv, other)
    local po = content and content._playerObj
    if side ~= "world" or not po or #unsearchedInReach(po, nil) == 0 then return nil end
    return { { id = "is:all", label = ZeD.tr("UI_ZeD_Search_SearchAll"), enabled = true,
        help = ZeD.tr("UI_ZeD_Search_SearchAllHelp"),
        run = function(ct) S.searchAll(ct._playerObj) end } }
end)

-- a container a ZeD list starts showing: the mod's search, as its page pick does
ZeD.ContainerGates.addChosen(MOD_ID, function(inv, po, side)
    if not isSearched(po, inv) then S.start(po, inv, side, "pick") end
end)

-- ---------------------------------------------------------------------------
-- THE "?" ON THE STRIP BUTTON: a small chip in the top right corner, the
-- frame and well of ZeD's marks, a pixel question mark (5 x 7 units)
-- ---------------------------------------------------------------------------
local GLYPH = { { 1, 0, 3, 1 }, { 0, 1, 1, 1 }, { 4, 1, 1, 1 }, { 4, 2, 1, 1 }, { 3, 3, 1, 1 }, { 2, 4, 1, 1 }, { 2, 6, 1, 1 } }
local CHIP_W, CHIP_H = 9, 11   -- design units: a 1u frame, 1u room, the glyph

function S.decorate(panel, entry, x, y, w, h, win)
    local inv = entry and entry.inventory
    if not inv or entry.isFloor or entry.locked then return end
    local po = (win and win._playerObj) or getSpecificPlayer(0)
    if isSearched(po, inv) then return end
    local T, A = ZeD.T, ZeD.Atoms
    local u = T.px(1)
    local cw, ch = T.px(CHIP_W), T.px(CHIP_H)
    local cx = x + w - cw - T.px(2)
    local cy = y + T.px(2)
    local well = T.surf2
    panel:drawRect(cx, cy, cw, ch, 1, well.r, well.g, well.b)
    A.frame(panel, cx, cy, cw, ch, T.borderS)
    local tc = T.text
    local gx, gy = cx + T.px(2), cy + T.px(2)
    for _, r in ipairs(GLYPH) do
        panel:drawRect(gx + r[1] * u, gy + r[2] * u, r[3] * u, r[4] * u, tc.a or 1, tc.r, tc.g, tc.b)
    end
    S.badged[inv] = getTimestampMs()
end

ZeD_CharacterWindow.addStripDecorator(MOD_ID, S.decorate)
ZeD_WorldWindow.addStripDecorator(MOD_ID, S.decorate)
