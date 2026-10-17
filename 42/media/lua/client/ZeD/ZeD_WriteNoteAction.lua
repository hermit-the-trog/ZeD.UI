-- ZeD-UI/42/media/lua/client/ZeD/ZeD_WriteNoteAction.lua
-- ============================================================================
-- A LINE IN A NOTEBOOK (the Journal tab's quick note and the log box's "Into";
-- mockup zed_reader_v2, director Oct 16 2026: "Writes into a notebook")
--
-- The character writes one line onto a page of a notebook, journal or diary
-- they carry: a short timed action with vanilla's own rules for writing
-- (ISInventoryPaneContextMenu's Write note + ISWriteSomething): light to see by,
-- a pencil or pen anywhere in the bags, a notebook nobody else locked (and one
-- you locked stays finished until you unlock it on the full page), 15 lines of
-- 80 letters a page. The book is taken out of a bag first, as vanilla does.
-- ============================================================================

require "TimedActions/ISBaseTimedAction"

ZeD = ZeD or {}
ZeD.Notes = ZeD.Notes or {}
local N = ZeD.Notes

N.LINES, N.LETTERS = 15, 80

-- vanilla's write tools (ISInventoryPaneContextMenu: canBeWrite)
local WRITE_TAGS = { "WRITE", "BLUE_PEN", "PEN", "PENCIL", "RED_PEN", "GREEN_PEN" }

function N.hasWritingTool(playerObj)
    local inv = playerObj:getInventory()
    for _, t in ipairs(WRITE_TAGS) do
        local tag = ItemTag and ItemTag[t]
        if tag and inv:containsTagRecurse(tag) then return true end
    end
    return false
end

-- locked by someone else (an admin can still write)
function N.otherLock(playerObj, item)
    local by = item:getLockedBy()
    return by ~= nil and by ~= playerObj:getUsername() and not isAdmin()
end

function N.lockedByMe(playerObj, item)
    return item:getLockedBy() ~= nil and not N.otherLock(playerObj, item)
end

-- why the character cannot write in it now (nil: they can)
function N.why(playerObj, item)
    if N.otherLock(playerObj, item) then return "Locked by its writer" end
    if N.lockedByMe(playerObj, item) then return "Locked: unlock it on the full page to write" end
    if not N.hasWritingTool(playerObj) then return "No pencil or pen" end
    if playerObj:tooDarkToRead() then return "Too dark to write" end
    return nil
end

-- the page's lines as the game's box counts them: each line of text, 80 letters to a ruled line
function N.linesOf(text)
    if not text or text == "" then return 0 end
    local n = 0
    for l in (text .. "\n"):gmatch("(.-)\n") do n = n + math.max(1, math.ceil(#l / N.LETTERS)) end
    return n
end

function N.page(item, i) return item:seePage(i) or "" end

function N.append(cur, line)
    if not cur or cur == "" then return line end
    return cur .. "\n" .. line
end

function N.fits(text)
    return N.linesOf(text) <= N.LINES and #text <= N.LINES * N.LETTERS
end

-- the last page with writing on it (0: a blank book)
function N.lastWritten(item)
    local last = 0
    for i = 1, item:getPageToWrite() do
        if N.page(item, i) ~= "" then last = i end
    end
    return last
end

-- where a new line goes: the last written page if it has room, else the next blank one
function N.pageFor(item, line)
    local last = N.lastWritten(item)
    if last >= 1 and N.fits(N.append(N.page(item, last), line)) then return last end
    for i = math.max(1, last + 1), item:getPageToWrite() do
        if N.page(item, i) == "" and N.fits(line) then return i end
    end
    return nil
end

-- the name it carries in a list: a renamed one by its name, with the kind of book under it
function N.kind(item)
    local ok, s = pcall(function() return item:getScriptItem():getDisplayName() end)
    return ok and s or "Notebook"
end

function N.pagesWritten(item)
    local n = 0
    for i = 1, item:getPageToWrite() do if N.page(item, i) ~= "" then n = n + 1 end end
    return n
end

-- ============================================================================
ZeD_WriteNoteAction = ISBaseTimedAction:derive("ZeD_WriteNoteAction")

local function isBook(item) return item:getType():match("Book") ~= nil end

function ZeD_WriteNoteAction:isValid()
    if self.character:tooDarkToRead() then
        HaloTextHelper.addBadText(self.character, getText("ContextMenu_TooDark"))
        return false
    end
    local inv = self.character:getInventory()
    local ok, has = pcall(function() return inv:containsRecursive(self.item) end)
    if not ok then has = inv:contains(self.item) end
    return has and N.why(self.character, self.item) == nil
end

function ZeD_WriteNoteAction:update() end

function ZeD_WriteNoteAction:start()
    self:setAnimVariable("ReadType", "book")
    self:setActionAnim(CharacterActionAnims.Read)
    self:setOverrideHandModels(nil, self.item)
    self.character:playSound(isBook(self.item) and "OpenBook" or "OpenMagazine")
end

function ZeD_WriteNoteAction:stop()
    self.character:playSound(isBook(self.item) and "CloseBook" or "CloseMagazine")
    ISBaseTimedAction.stop(self)
end

function ZeD_WriteNoteAction:perform()
    local item, page = self.item, self.page
    local text = N.append(N.page(item, page), self.text)
    if N.fits(text) then
        -- (the pages are kept in order: a blank page before this one is written as blank)
        for i = 1, page - 1 do if item:seePage(i) == nil then item:addPage(i, "") end end
        item:addPage(page, text)
        pcall(syncItemFields, self.character, item)
        if self.onDone then pcall(self.onDone, page) end
    end
    self.character:playSound(isBook(item) and "CloseBook" or "CloseMagazine")
    ISBaseTimedAction.perform(self)
end

function ZeD_WriteNoteAction:complete() return true end

function ZeD_WriteNoteAction:getDuration()
    -- a few seconds a line: longer for more letters (about 3 s for 40 letters at normal speed)
    return math.min(200, 40 + #self.text)
end

function ZeD_WriteNoteAction:new(character, item, page, text, onDone)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.page = page
    o.text = text
    o.onDone = onDone
    o.ignoreHandsWounds = true
    o.maxTime = o:getDuration()
    return o
end

-- queue it as vanilla does (out of the bag first); returns the action
function N.write(playerObj, item, page, text, onDone)
    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item)
    local a = ZeD_WriteNoteAction:new(playerObj, item, page, text, onDone)
    ISTimedActionQueue.add(a)
    return a
end
