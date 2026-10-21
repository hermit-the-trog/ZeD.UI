-- ZeD-UI/42/media/lua/client/ZeD/MapNotes.lua
-- ============================================================================
-- MAP NOTES (Oct 20 2026; director: "as its own careful task") -- the marks
-- and notes the player puts on ZeD's map live in vanilla's own store: the
-- world map's MapItem (MapItem.getSingleton()), through the same symbols API
-- vanilla's map uses (ISWorldMapSymbols: addTexture, addTranslatedText,
-- removeSymbolByIndex, and in multiplayer sendRemoveSymbol / sendModifySymbol). So a
-- mark made on ZeD's map shows on vanilla's map and mini-map, is saved with
-- the world the vanilla way, and shares in multiplayer the vanilla way. The
-- engine draws them (every map bound to the item draws its symbols); ZeD
-- draws none of its own.
--
-- Paper map items (reading a map you picked up) keep their own symbols, as
-- vanilla's ISMap does with setMapItem(the item): nothing here touches them.
--
-- Until Oct 20 2026 ZeD kept its marks in the character's modData
-- (ZeD_MapAnnotations). migrate() copies them into the store once per
-- character (ZeD_MapNotesMoved marks it done) and leaves the old list as it
-- was, as a backup.
-- ============================================================================

ZeD = ZeD or {}
ZeD.MapNotes = ZeD.MapNotes or {}
local M = ZeD.MapNotes

M.OLD_KEY      = "ZeD_MapAnnotations"   -- the old store (character modData), kept as a backup
M.MIGRATED_KEY = "ZeD_MapNotesMoved"    -- set once the old store has been copied over

-- ZeD's toolbar icons and vanilla's symbol ids for the same pictures
-- (shared/Definitions/MapSymbolDefinitions.lua)
M.SYMBOL_BY_ICON = {
    house = "House", target = "Target", skull = "Skull", star = "Star", cross = "Cross",
    heart = "Heart", exclamation = "Exclamation", question = "Question", fire = "Fire",
    gun = "Gun", burger = "Burger", axe = "Axe", gears = "Gears", x = "X", checkmark = "Checkmark",
}

-- Vanilla's inks (ISWorldMapSymbols colorButtonInfo), in ZeD's toolbar order:
-- the colour a mark gets is the colour vanilla gives the same pen.
M.INKS = {
    { item = "Pencil",   r = 0.2,   g = 0.2,   b = 0.2   },
    { item = "Pen",      r = 0.129, g = 0.129, b = 0.129 },
    { item = "BluePen",  r = 0.156, g = 0.188, b = 0.49  },
    { item = "RedPen",   r = 0.65,  g = 0.054, b = 0.054 },
    { item = "GreenPen", r = 0.06,  g = 0.39,  b = 0.17  },
}

-- vanilla's note limit (ISWorldMapSymbolTool_AddNote: modal.maxChars)
M.NOTE_MAX_CHARS = 45

local function _scale() return (ISMap and ISMap.SCALE) or 0.666 end

local function _trim(s)
    if type(s) ~= "string" then return "" end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function _ink(idx)
    return M.INKS[tonumber(idx) or 1] or M.INKS[1]
end

-- ============================================================================
-- THE STORE -- one hidden map bound to the world map's item, made once per
-- world (the item is new after a load). Every visible map makes its own
-- symbols wrapper, and the engine keeps each one listening for good, so marks
-- are added and counted through this one instead.
-- ============================================================================

function M.api()
    if not (MapItem and MapItem.getSingleton and UIWorldMap) then return nil end
    local item = MapItem.getSingleton()
    if not item then return nil end
    local s = M._store
    if s and s.item == item then return s.api end
    local ui = {}
    ui.javaObject = UIWorldMap.new(ui)
    ui.mapAPI = ui.javaObject:getAPIv3()
    ui.mapAPI:setMapItem(item)              -- (before the first getSymbolsAPIv2: the engine keeps the first)
    M._store = { item = item, ui = ui, api = ui.mapAPI:getSymbolsAPIv2() }
    return M._store.api
end

-- A visible map draws the store as vanilla's map does (ISWorldMap:instantiate).
-- Must come before anything asks that map for its symbols API.
function M.bind(mp)
    if not (mp and mp.mapAPI and MapItem and MapItem.getSingleton) then return false end
    local item = MapItem.getSingleton()
    if not item then return false end
    mp.mapAPI:setMapItem(item)
    mp._zedNotesBound = true
    return true
end

-- the map's own symbols API (hit tests need its layout), made on first need
function M.panelAPI(mp)
    if not (mp and mp._zedNotesBound) then return nil end
    if not mp._zedSymbolsAPI then mp._zedSymbolsAPI = mp.mapAPI:getSymbolsAPIv2() end
    return mp._zedSymbolsAPI
end

-- The map's own labels (rivers, towns, places) from each map folder's
-- worldmap-annotations.lua, loaded once into the store as vanilla's map and
-- mini-map do every frame (ISWorldMap:prerender). Vanilla shows them; so does ZeD.
function M.initDefaults()
    local api = M.api()
    if api then api:initDefaultAnnotations() end
end

-- ============================================================================
-- READING THE STORE
-- ============================================================================

-- a mark the player made (not one of the map's own labels)
function M.isMark(sym)
    return sym ~= nil and sym:isUserDefined() == true
end

-- vanilla's filter for tools that change a mark: in multiplayer, only what
-- this client may change (ISWorldMapSymbols filterAny / filterEdit)
function M.canModify(sym)
    if not M.isMark(sym) then return false end
    if isClient() and not sym:canClientModify() then return false end
    return true
end

function M.count()
    local api = M.api()
    if not api then return 0 end
    local n = 0
    for i = 0, api:getSymbolCount() - 1 do
        if M.isMark(api:getSymbolByIndex(i)) then n = n + 1 end
    end
    return n
end

-- whether sym is still in api's list (a menu opened a moment ago may be stale)
function M.contains(api, sym)
    if not (api and sym) then return false end
    for i = 0, api:getSymbolCount() - 1 do
        if api:getSymbolByIndex(i) == sym then return true end
    end
    return false
end

function M.textOf(sym)
    if not (sym and sym:isText()) then return nil end
    return sym:getTranslatedText()
end

-- the first note with exactly this text (QA), and its wrapper's api
function M.findByText(text)
    local api = M.api()
    if not api then return nil end
    for i = 0, api:getSymbolCount() - 1 do
        local s = api:getSymbolByIndex(i)
        if M.isMark(s) and s:isText() and s:getTranslatedText() == text then return s, api end
    end
    return nil
end

-- the ink (M.INKS index) closest to a mark's colour
function M.inkOf(sym)
    if not sym then return nil end
    local r, g, b = sym:getRed(), sym:getGreen(), sym:getBlue()
    local best, bestD = nil, 0.01
    for i, k in ipairs(M.INKS) do
        local d = (k.r - r) * (k.r - r) + (k.g - g) * (k.g - g) + (k.b - b) * (k.b - b)
        if d < bestD then best, bestD = i, d end
    end
    return best
end

-- The mark under (x, y) on a visible map that this player may change, and the
-- api it came from: the engine's own hit test first (vanilla's tools use it),
-- then, within radius pixels, the nearest mark's anchor (the old ZeD reach,
-- kept for the controller's cursor and small marks far out).
function M.hitAt(mp, x, y, radius)
    local api = M.panelAPI(mp)
    if not api then return nil end
    local idx = api:hitTest(x, y)
    if idx and idx >= 0 then
        local s = api:getSymbolByIndex(idx)
        if M.canModify(s) then return s, api end
    end
    if not radius then return nil end
    local map = mp.mapAPI
    local best, bestD = nil, radius * radius
    for i = 0, api:getSymbolCount() - 1 do
        local s = api:getSymbolByIndex(i)
        if M.canModify(s) and s:isVisible() then
            local wx, wy = s:getWorldX(), s:getWorldY()
            local dx = map:worldToUIX(wx, wy) - x
            local dy = map:worldToUIY(wx, wy) - y
            local d = dx * dx + dy * dy
            if d <= bestD then best, bestD = s, d end
        end
    end
    if best then return best, api end
    return nil
end

-- ============================================================================
-- WRITING THE STORE -- vanilla's calls, in vanilla's order
-- ============================================================================

-- ISWorldMapSymbolTool_AddSymbol:addSymbol
function M.addSymbol(symbolId, wx, wy, inkIdx)
    local api = M.api()
    if not (api and symbolId) then return nil end
    local defs = MapSymbolDefinitions and MapSymbolDefinitions.getInstance()
    if defs and not defs:getSymbolById(symbolId) then return nil end
    local k = _ink(inkIdx)
    local sym = api:addTexture(symbolId, wx, wy)
    if not sym then return nil end
    sym:setRGBA(k.r, k.g, k.b, 1.0)
    sym:setAnchor(0.5, 0.5)
    sym:setScale(_scale())
    return sym
end

-- ISWorldMapSymbolTool_AddNote:onNoteAdded (the in-game path: plain text, no
-- translation key). Empty text adds nothing, as in vanilla.
function M.addNote(text, wx, wy, inkIdx)
    local api = M.api()
    if not api then return nil end
    text = _trim(text)
    if text == "" then return nil end
    local k = _ink(inkIdx)
    local sym = api:addTranslatedText(text, api:getDefaultTextLayerID(), wx, wy)
    if not sym then return nil end
    sym:setRGBA(k.r, k.g, k.b, 1.0)
    sym:setAnchor(0.5, 0.5)
    sym:setScale(_scale())
    sym:setRotation(0.0)
    sym:setMatchPerspective(false)
    sym:setMinZoom(0.0)
    sym:setMaxZoom(24.0)
    return sym
end

-- ISWorldMapSymbolTool_RemoveAnnotation:removeAnnotation, branch for branch.
-- A NOTE is always taken off locally (removeSymbolByIndex), shared or not, as
-- vanilla does. A SYMBOL that is shared on a server is taken off by asking the
-- server (sendRemoveSymbol); any other symbol is taken off locally.
function M.remove(sym, api)
    api = api or M.api()
    if not (api and sym) then return false end
    local idx = nil
    for i = 0, api:getSymbolCount() - 1 do
        if api:getSymbolByIndex(i) == sym then idx = i; break end
    end
    if idx == nil then return false end
    if sym:isText() then
        return pcall(function() api:removeSymbolByIndex(idx) end) == true
    end
    if isClient() and sym:isShared() then
        api:sendRemoveSymbol(sym)
        return true
    end
    return pcall(function() api:removeSymbolByIndex(idx) end) == true
end

-- ISWorldMapSymbolTool_EditAnnotation:onSymbolEdited / onNoteEdited (colour)
function M.setInk(sym, inkIdx, api)
    api = api or M.api()
    if not (api and sym) then return false end
    local k = _ink(inkIdx)
    sym:setRGBA(k.r, k.g, k.b, 1.0)
    if isClient() then api:sendModifySymbol(sym) end
    return true
end

-- ISWorldMapSymbolTool_EditAnnotation:onNoteEdited (text). Empty text changes
-- nothing, as in vanilla.
function M.setText(sym, text, api)
    api = api or M.api()
    if not (api and sym and sym:isText()) then return false end
    text = _trim(text)
    if text == "" then return false end
    sym:setTranslatedText(text)
    if isClient() then api:sendModifySymbol(sym) end
    return true
end

-- ============================================================================
-- MIGRATION -- the old modData marks into the store, once per character
-- ============================================================================

-- a mark like this one already in the store (a second copy is never made,
-- even if the done-flag was lost)
local function _alreadyThere(api, isText, idOrText, wx, wy)
    for i = 0, api:getSymbolCount() - 1 do
        local s = api:getSymbolByIndex(i)
        if M.isMark(s) and math.abs(s:getWorldX() - wx) < 0.5 and math.abs(s:getWorldY() - wy) < 0.5 then
            if isText then
                if s:isText() and s:getTranslatedText() == idOrText then return true end
            elseif s:isTexture() and s:getSymbolID() == idOrText then
                return true
            end
        end
    end
    return false
end

-- Copies playerObj's old marks into the store. Returns how many were added
-- (0 when done before, nothing to move, or the store is not up yet: then
-- nothing is marked and the next call tries again).
function M.migrate(playerObj)
    if not playerObj then return 0 end
    local md = playerObj:getModData()
    if md[M.MIGRATED_KEY] then return 0 end
    local api = M.api()
    if not api then return 0 end
    local old = md[M.OLD_KEY]
    local added = 0
    if type(old) == "table" then
        for _, a in ipairs(old) do
            local wx = type(a) == "table" and tonumber(a.worldX) or nil
            local wy = type(a) == "table" and tonumber(a.worldY) or nil
            if wx and wy then
                local text = _trim(a.text)
                if a.iconId == "text" then
                    if text ~= "" and not _alreadyThere(api, true, text, wx, wy) then
                        if M.addNote(text, wx, wy, a.colorIdx) then added = added + 1 end
                    end
                else
                    local id = M.SYMBOL_BY_ICON[a.iconId]
                    if id and not _alreadyThere(api, false, id, wx, wy) then
                        if M.addSymbol(id, wx, wy, a.colorIdx) then added = added + 1 end
                    end
                    -- an icon that carried words: vanilla's symbols cannot, so
                    -- the words become a note just above it
                    if text ~= "" and not _alreadyThere(api, true, text, wx, wy - 3) then
                        if M.addNote(text, wx, wy - 3, a.colorIdx) then added = added + 1 end
                    end
                end
            end
        end
    end
    md[M.MIGRATED_KEY] = true
    return added
end

local function _migrateLocalPlayers()
    for i = 0, getNumActivePlayers() - 1 do
        local p = getSpecificPlayer(i)
        if p then pcall(M.migrate, p) end
    end
end

local function _migrateCreated(_playerNum, playerObj)
    if playerObj then pcall(M.migrate, playerObj) end
end

if Events then
    if Events.OnGameStart then Events.OnGameStart.Add(_migrateLocalPlayers) end
    if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(_migrateCreated) end
end
