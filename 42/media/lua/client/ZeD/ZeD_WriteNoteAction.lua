-- ZeD-UI/42/media/lua/client/ZeD/ZeD_WriteNoteAction.lua
-- ============================================================================
-- A LINE IN A NOTEBOOK - client; a timed action (ZeD_WriteNoteAction) and the
-- notebook helpers (ZeD.Notes) behind the Journal tab's quick note and the log
-- box's "Into", both in ZeD_JournalReaders.lua.
--
-- The character writes one line onto a page of a notebook, journal or diary
-- they carry: a short timed action with vanilla's own rules for writing
-- (ISInventoryPaneContextMenu's Write note + ISWriteSomething): light to see by,
-- a pencil or pen anywhere in the bags, a notebook nobody else locked (and one
-- you locked stays finished until you unlock it on the full page), 15 lines of
-- 80 letters a page. The book is taken out of a bag first, as vanilla does.
-- ============================================================================

require "TimedActions/ISBaseTimedAction"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.Notes = ZeD.Notes or {}
local N = ZeD.Notes

N.LINES, N.LETTERS = 15, 80

-- vanilla's write tools (ISInventoryPaneContextMenu: canBeWrite)
local WRITE_TAGS = { "WRITE", "BLUE_PEN", "PEN", "PENCIL", "RED_PEN", "GREEN_PEN" }

--- A pencil or pen anywhere in the character's bags.
function N.hasWritingTool(playerObj)
    local inv = playerObj:getInventory()
    for _, t in ipairs(WRITE_TAGS) do
        local tag = ItemTag and ItemTag[t]
        if tag and inv:containsTagRecurse(tag) then return true end
    end
    return false
end

--- Locked by someone else (an admin can still write).
function N.otherLock(playerObj, item)
    local by = item:getLockedBy()
    return by ~= nil and by ~= playerObj:getUsername() and not isAdmin()
end

function N.lockedByMe(playerObj, item)
    return item:getLockedBy() ~= nil and not N.otherLock(playerObj, item)
end

--- Why the character cannot write in it now, as the line to show (nil: they can).
function N.why(playerObj, item)
    if N.otherLock(playerObj, item) then return ZeD.tr("UI_ZeD_Notebook_WhyLockedOther") end
    if N.lockedByMe(playerObj, item) then return ZeD.tr("UI_ZeD_Notebook_WhyLockedMine") end
    if not N.hasWritingTool(playerObj) then return ZeD.tr("UI_ZeD_Notebook_WhyNoTool") end
    if playerObj:tooDarkToRead() then return ZeD.tr("UI_ZeD_Notebook_WhyTooDark") end
    return nil
end

--- The page's lines as the game's box counts them: each line of text, 80 letters to a ruled line.
function N.linesOf(text)
    if not text or text == "" then return 0 end
    local n = 0
    for l in (text .. "\n"):gmatch("(.-)\n") do n = n + math.max(1, math.ceil(#l / N.LETTERS)) end
    return n
end

--- Page i's text ("" for a blank page).
function N.page(item, i) return item:seePage(i) or "" end

--- The page's text with one more line under it.
function N.append(cur, line)
    if not cur or cur == "" then return line end
    return cur .. "\n" .. line
end

--- The text fits on one page: N.LINES ruled lines and N.LINES x N.LETTERS letters at most.
function N.fits(text)
    return N.linesOf(text) <= N.LINES and #text <= N.LINES * N.LETTERS
end

--- The last page with writing on it (0: a blank book).
function N.lastWritten(item)
    local last = 0
    for i = 1, item:getPageToWrite() do
        if N.page(item, i) ~= "" then last = i end
    end
    return last
end

--- Where a new line goes: the last written page if it has room, else the next blank one (nil: the book is full).
function N.pageFor(item, line)
    local last = N.lastWritten(item)
    if last >= 1 and N.fits(N.append(N.page(item, last), line)) then return last end
    for i = math.max(1, last + 1), item:getPageToWrite() do
        if N.page(item, i) == "" and N.fits(line) then return i end
    end
    return nil
end

--- The kind of book, its script's own name ("Notebook" when that can't be read): the list shows it under
--- the book's name, so a renamed book still says what it is.
function N.kind(item)
    local ok, s = pcall(function() return item:getScriptItem():getDisplayName() end)
    return ok and s or ZeD.tr("UI_ZeD_Notebook_Kind")
end

--- How many pages have writing on them.
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
        -- (QA B3, Nov 27 2026: a blank ID card written here stayed open. The game's write window
        -- locks a LOCK_ON_WRITE item on OK with a random owner nobody holds, so it is written once;
        -- the same here, before the sync carries it.)
        local lockTag = ItemTag and ItemTag.LOCK_ON_WRITE
        if lockTag and item:hasTag(lockTag) then item:setLockedBy(tostring(ZombRand(1000000))) end
        pcall(syncItemFields, self.character, item)
        if self.onDone then pcall(self.onDone, page) end
    end
    self.character:playSound(isBook(item) and "CloseBook" or "CloseMagazine")
    ISBaseTimedAction.perform(self)
end

function ZeD_WriteNoteAction:complete() return true end   -- (perform writes the page and syncs it: nothing left here)

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

--- Queue the writing as vanilla does (the book out of the bag first); returns the write action and
--- every action the call queued (the move out of the bag, then the write), for a busy check.
--- onDone(page) runs once the line is on the page.
-- (QA J29, Nov 27 2026: the book was taken out of the bag, written in, then went back into it. ZeD's
-- Put things back (ZeD_PutBack.lua) took the move as the write's own and undid it after. The game's
-- transferIfNeeded queues the same move; it is queued here with _zedApart, Put back's mark for a
-- move the player asked for, so the book stays in the main inventory as the game leaves it.)
function N.write(playerObj, item, page, text, onDone)
    local queued = {}
    if luautils.haveToBeTransfered(playerObj, item) then
        local t = ISInventoryTransferUtil.newInventoryTransferAction(playerObj, item, item:getContainer(), playerObj:getInventory())
        t._zedApart = true
        ISTimedActionQueue.add(t)
        queued[#queued + 1] = t
    end
    local a = ZeD_WriteNoteAction:new(playerObj, item, page, text, onDone)
    ISTimedActionQueue.add(a)
    queued[#queued + 1] = a
    return a, queued
end

--- True while any of `queued` (N.write's list) is still in the character's action queue.
function N.busy(playerObj, queued)
    if not (playerObj and queued) then return false end
    local ok, q = pcall(ISTimedActionQueue.getTimedActionQueue, playerObj)
    if not (ok and q and q.queue) then return false end
    for i = 1, #queued do
        for j = 1, #q.queue do
            if q.queue[j] == queued[i] then return true end
        end
    end
    return false
end
