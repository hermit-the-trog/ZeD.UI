-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuModsFiles.lua
-- ============================================================================
-- THE MODS SCREEN'S FILES TAB: a mod's code files, each with a box to switch
-- it off (punch list 170, mockup zed_mods_file_switches_v1). Client-side; part of
-- the ZeD_MMMods organism (it extends the class ZeD_MainMenuMods.lua builds).
--
-- The answer to "a mod broke my game" when turning the whole mod off is too
-- much. The files are grouped by side (client, shared, server) with their size,
-- "used by N" (the mod's other files that name it) and the last game's errors on
-- the file they come from. Picking a file opens its card under it: its first
-- lines, what switching it off will touch, and the verbs. A file no other file
-- names switches off at once (the box, or A); one others use, or one with
-- errors, asks on its card first (Turn off anyway, or with the files that use
-- it). The mod's row in the list says "1 file off"; Turn all back on undoes it.
--
-- How it is done: ZeD_ModFiles.lua (the engine path) and ZeD_ModPicks.lua (the
-- helper's copies). The change is kept at once; a reload puts it in place.
-- Never a file the game has too, never a server's list.
-- ============================================================================
require "ZeD/ZeD_MainMenuModsPanes"
require "ZeD/ZeD_ModFiles"
local MM = ZeD.MainMenu
local MS = ZeD.ModScan
local P  = ZeD.ModPicks
local F  = ZeD.ModFiles

-- design units
local CARD_PAD = 10
local CODE_LINES = 4
local MANY_USERS = 3   -- an error's file used by this many others: turning the mod off is the cleaner fix

local function model() return ModSelector and ModSelector.instance and ModSelector.instance.model end

-- a tag at a file row's right, as the list's rows draw theirs: an outline, its status a square
local function tagW(text, mark)
    local T = ZeD.T
    return MM.textW(T.fontF1, ZeD.textCase(text)) + T.px(10) + (mark and T.px(10) or 0)
end
local function rowTag(p, text, x, y, mark)
    local T = ZeD.T
    local b = T.base
    p:drawRect(x, y, tagW(text, mark), T.px(16), 1, b.r, b.g, b.b)
    ZeD.Molecules.drawTag(p, x, y, text, mark, { font = T.fontF1 })
end

-- ----------------------------------------------------------------------------
-- WHAT CAN BE SWITCHED
-- ----------------------------------------------------------------------------
--- Files of this mod can be switched here: ZeD picks is installed, the mod is on and was
--- loaded (its files are known), and the list is not a server's (a server checks every
--- player's code matches its own).
function ZeD_MMMods:canSwitchFiles(d)
    local m = model()
    if not (m and d and d.isActive and MS.isLoaded(d.modId)) then return false end
    if m.isServerSettingsMods then return false end
    return P.helper() ~= nil
end

--- The file's state: "game" (the game ships the path too), "gone" (off, and an update took it
--- out of the mod), "off", "on".
function ZeD_MMMods:fileState(d, f)
    if F.isGameFile(f.path) then return "game" end
    if P.offOf(f.path) == d.modId then return f.gone and "gone" or "off" end
    return "on"
end

-- the paths of this mod switched off now
local function offCount(modId) return #P.offFor(modId) end

-- ----------------------------------------------------------------------------
-- SWITCHING
-- ----------------------------------------------------------------------------
--- Switch these paths off (or back on), keep it, rebuild the helper's copies and say so.
function ZeD_MMMods:switchFiles(d, paths, off)
    if #paths == 0 then return end
    self._filesSeen = self._filesSeen or {}
    for _, path in ipairs(paths) do
        if self._filesSeen[path] == nil then self._filesSeen[path] = (P.offOf(path) == d.modId) end
    end
    P.setOff(d.modId, paths, off)
    self:afterPicks()
    self._filesChanged = d.name
    MM.clickSound()
    local n = #paths
    if off then self:say(ZeD.tr(n == 1 and "UI_ZeD_Mods_SayFileOff" or "UI_ZeD_Mods_SayFilesOff", n, d.name))
    else self:say(ZeD.tr(n == 1 and "UI_ZeD_Mods_SayFileOn" or "UI_ZeD_Mods_SayFilesOn", n, d.name)) end
end

--- The box on a row, or A on it: on a file that is off, back on; on a file that is safe to
--- switch off on its own (read, no other file names it, no errors), off; otherwise its card opens
--- so the warning is read first.
function ZeD_MMMods:fileA(d, f)
    local st = self:fileState(d, f)
    if st == "off" or st == "gone" then self:switchFiles(d, { f.path }, false); self.fileSel = f.path; return end
    if st == "on" and self:canSwitchFiles(d) then
        local used = F.usedBy(d.modId, f.path)
        if used and #used == 0 and #F.placesOn(d.name, f.path) == 0 then
            self:switchFiles(d, { f.path }, true)
            self.fileSel = f.path
            return
        end
    end
    if self.fileSel ~= f.path then MM.clickSound() end
    self.fileSel = f.path
end

--- An error card's Open in Mods (ZeD_ModFiles.takeJump, read as the screen opened): once the
--- list holds the mod named, it is picked, on its Files tab, and the tab picks the file. Given
--- up after a few seconds (the mod is gone, or renamed by an update).
function ZeD_MMMods:resolveJump()
    local j = self._pendingJump
    local m = model()
    if not (j and m) then return end
    j.tries = (j.tries or 0) + 1
    for id, d in pairs(m.mods or {}) do
        if tostring(d.name) == j.name or tostring(id) == j.name then
            self._pendingJump = nil
            self.sel, self.fsel, self.dtab, self.dscroll = id, nil, "files", 0
            self._fileJump = j.file
            self.filter = "all"
            self.focusId = "dtab:files"
            self:dirty()
            return
        end
    end
    if j.tries > 300 then self._pendingJump = nil end
end

-- ----------------------------------------------------------------------------
-- THE TAB
-- ----------------------------------------------------------------------------
--- How many code files the tab lists (0 while the mod was not loaded).
function ZeD_MMMods:filesCount(d)
    if not MS.isLoaded(d.modId) then return 0 end
    return #F.files(d.modId)
end

--- The Files tab: a line of counts, the files by side, the picked file's card under it.
function ZeD_MMMods:drawFilesTab(d, ix, iw, cy, vy, vh)
    local T = ZeD.T
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local dim = T.textDim
    if not MS.isLoaded(d.modId) then
        return self:paneNote(ZeD.tr(d.isActive and "UI_ZeD_Mods_FilesTabLater" or "UI_ZeD_Mods_FilesTabTurnOn"), ix, iw, cy)
    end
    local files = F.files(d.modId)
    if #files == 0 then return self:paneNote(ZeD.tr("UI_ZeD_Mods_FilesTabNone"), ix, iw, cy) end
    F.scan(d.modId)
    local nOff = offCount(d.modId)
    local can = self:canSwitchFiles(d)
    -- the counts, and Turn all back on
    local sum = ZeD.tr("UI_ZeD_Mods_FilesCount", #files) .. " | " .. ((nOff > 0) and ZeD.tr("UI_ZeD_Mods_FilesOffN", nOff) or ZeD.tr("UI_ZeD_Mods_FilesAllOn"))
    cy = self:paneText(sum, ix, cy, iw, f2, nOff > 0 and T.warningText or T.text) + T.px(4)
    if nOff > 0 then
        cy = self:paneVerbs({ { "mf:allon", ZeD.tr("UI_ZeD_Mods_FilesVerbAllOn"), function() self:switchFiles(d, P.offFor(d.modId), false); self.focusId = "dtab:files" end } }, ix, cy, iw, vy, vh, 690) + T.px(8)
    end
    -- why the boxes may be off, and how it works
    local m = model()
    if m and m.isServerSettingsMods then cy = self:paneNote(ZeD.tr("UI_ZeD_Mods_FilesServer"), ix, iw, cy, T.warningText)
    elseif not P.helper() then cy = self:paneNote(ZeD.tr("UI_ZeD_Mods_FilesNoHelper"), ix, iw, cy, T.warningText) end
    cy = self:paneText(ZeD.tr("UI_ZeD_Mods_FilesHowWorks"), ix, cy, iw, f3, dim) + T.px(8)
    -- Open in Mods from an error card: the file it named, picked and scrolled to
    local jump = self._fileJump
    if jump then
        self._fileJump = nil
        local want = string.lower(tostring(jump))
        for i, f in ipairs(files) do
            if string.lower(f.path:match("([^/]+)$") or f.path) == want then
                self.fileSel = f.path
                self.focusId = "mfile:" .. i
                self._fileScrollTo = f.path
                break
            end
        end
    end
    local side = nil
    for i, f in ipairs(files) do
        if f.side ~= side then
            side = f.side
            local n = 0
            for _, g in ipairs(files) do if g.side == side then n = n + 1 end end
            cy = cy + T.px(4)
            local la = T.accent
            local head = ZeD.textCase(side ~= "" and side or "?")
            self:drawText(head, ix, cy, la.r, la.g, la.b, la.a or 1, f1)
            local cnt = ZeD.tr("UI_ZeD_Mods_FilesCount", n)
            self:drawText(cnt, ix + iw - MM.textW(f3, cnt), cy, dim.r, dim.g, dim.b, dim.a or 1, f3)
            cy = cy + MM.fontH(f1) + T.px(3)
            self:drawRect(ix, cy, iw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
            cy = cy + T.px(2)
        end
        local top = cy
        cy = self:drawFileRow(d, f, i, ix, iw, cy, vy, vh, can)
        if self.fileSel == f.path then cy = self:drawFileCard(d, f, i, ix, iw, cy + T.px(4), vy, vh, can) + T.px(6) end
        if self._fileScrollTo == f.path then
            self._fileScrollTo = nil
            if top < vy or top > vy + vh - T.px(40) then self.dscroll = math.max(0, self.dscroll + (top - vy) - T.px(40)) end
        end
    end
    return cy + T.px(8)
end

-- one file: the changed dot, its box, its name (struck through when off), the tags, its size
function ZeD_MMMods:drawFileRow(d, f, i, ix, iw, cy, vy, vh, can)
    local T = ZeD.T
    local f2, f3 = T.fontF2, T.fontF3
    local rh = MM.fontH(f2) + T.px(10)
    local gp = MM.gamepad()
    local sid = "mfile:" .. i
    local st = self:fileState(d, f)
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    if cy + rh > vy and cy < vy + vh then
        local hid = "mods:mfile:" .. i
        local onFocus = MM.rowLook(self, ix - T.px(4), cy, iw + T.px(8), rh, self.fileSel == f.path, (not gp) and (MM.ctx.hot == hid or MM.ctx.hot == hid .. ":cb"), gp and self.focusId == sid)
        local midY = cy + math.floor(rh / 2)
        -- (a dot: switched since the screen opened)
        local seen = self._filesSeen and self._filesSeen[f.path]
        if seen ~= nil and seen ~= (st == "off" or st == "gone") then
            local dsz = T.px(6)
            ZeD.Atoms.drawStatusDot(self, ix, midY - math.floor(dsz / 2), T.accent, dsz)
        end
        local cb = T.checkboxSz
        local cbx = ix + T.px(10)
        local switchable = can and st ~= "game"
        ZeD.Atoms.drawCheckbox(self, cbx, midY - math.floor(cb / 2), st ~= "off" and st ~= "gone", (not gp) and MM.ctx.hot == hid .. ":cb", not switchable and st ~= "off")
        -- the tags and the size, from the right
        local right = ix + iw
        local size = F.sizeText(d.modId, f.path) or ""
        if size ~= "" then
            local sw = MM.textW(f3, size)
            local dc = onFocus and T.textOnFocus or T.textDim
            self:drawText(size, right - sw, midY - math.floor(MM.fontH(f3) / 2), dc.r, dc.g, dc.b, dc.a or 1, f3)
            right = right - sw - T.px(10)
        end
        local tags = {}
        local nErr = 0
        for _, p in ipairs(F.placesOn(d.name, f.path)) do nErr = nErr + p.count end
        if nErr > 0 then tags[#tags + 1] = { ZeD.tr(nErr == 1 and "UI_ZeD_Mods_FileTagErrorOne" or "UI_ZeD_Mods_FileTagErrors", nErr), T.danger } end
        if st == "game" then tags[#tags + 1] = { ZeD.tr("UI_ZeD_Mods_FileTagGame"), T.warning }
        elseif st == "gone" then tags[#tags + 1] = { ZeD.tr("UI_ZeD_Mods_FileTagGone"), T.warning }
        else
            local used = F.usedBy(d.modId, f.path)
            if used and #used > 0 then tags[#tags + 1] = { ZeD.tr("UI_ZeD_Mods_FileTagUsedBy", #used), nil } end
        end
        for _, t in ipairs(tags) do
            local w = tagW(t[1], t[2])
            if right - w < cbx + cb + T.px(80) then break end
            right = right - w
            rowTag(self, t[1], right, midY - T.px(8), t[2])
            right = right - T.px(6)
        end
        -- the name: its path under the side folder; off: dim and struck through
        local nx = cbx + cb + T.px(8)
        local isOff = st == "off" or st == "gone"
        local nc = onFocus and T.textOnFocus or (isOff and T.textDim or T.text)
        local name = ZeD.Atoms.truncateText(f.sub, f2, right - T.px(6) - nx)
        local ny = midY - math.floor(MM.fontH(f2) / 2)
        self:drawText(name, nx, ny, nc.r, nc.g, nc.b, nc.a or 1, f2)
        if isOff then self:drawRect(nx, midY, MM.textW(f2, name), T.px(1), nc.a or 1, nc.r, nc.g, nc.b) end
        self:drawRect(ix, cy + rh - T.px(1), iw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
        -- the pointer: the row picks the file, the box switches it
        local top, bot = math.max(cy, vy), math.min(cy + rh, vy + vh)
        if bot > top then
            self._hits[#self._hits + 1] = { id = hid, x = ax + ix, y = ay + top, w = iw, h = bot - top, fn = function()
                if self.fileSel ~= f.path then self.fileSel = f.path; MM.clickSound() else self.fileSel = nil end
                self.focusId = sid
            end }
            if switchable or isOff then
                self._hits[#self._hits + 1] = { id = hid .. ":cb", x = ax + ix, y = ay + top, w = cbx - ix + cb + T.px(6), h = bot - top, fn = function()
                    self.focusId = sid
                    self:fileA(d, f)
                end }
            end
        end
    end
    -- the controller: A switches (or opens the card first, as the box does); the pane follows it
    self._specs[#self._specs + 1] = { id = sid, listRow = true, paneStop = true, row = 700 + i, col = 1, x = ix, y = cy, w = iw, h = rh,
                                      clipTop = vy, clipBot = vy + vh, fn = function()
                                          if (can and st ~= "game") or st == "off" or st == "gone" then self:fileA(d, f)
                                          else self.fileSel = (self.fileSel ~= f.path) and f.path or nil end
                                      end }
    return cy + rh
end

-- a line with a status square in front, wrapped; returns the y under it
function ZeD_MMMods:fileNote(text, color, ix, iw, cy)
    local T = ZeD.T
    local f2 = T.fontF2
    local dsz = T.px(7)
    ZeD.Atoms.drawStatusDot(self, ix, cy + math.floor((MM.fontH(f2) - dsz) / 2), color, dsz)
    return self:paneText(text, ix + dsz + T.px(7), cy, iw - dsz - T.px(7), f2, T.text) + T.px(4)
end

-- the names of these paths, joined (at most five, then "and N more")
local function namesOf(paths)
    local t = {}
    for k, p in ipairs(paths) do
        if k > 5 then break end
        t[#t + 1] = p:match("^[Mm][Ee][Dd][Ii][Aa]/[Ll][Uu][Aa]/[^/]+/(.+)$") or p
    end
    local s = table.concat(t, ", ")
    if #paths > 5 then s = ZeD.tr("UI_ZeD_Mods_AndMore", s, #paths - 5) end
    return s
end

--- The picked file's card, under its row: what it is, its first lines, what switching it off
--- touches, its errors, the verbs. Returns the y under it.
function ZeD_MMMods:drawFileCard(d, f, i, ix, iw, cy, vy, vh, can)
    local T = ZeD.T
    local f2, f3 = T.fontF2, T.fontF3
    local dim = T.textDim
    local pad = T.px(CARD_PAD)
    local x0, y0 = ix, cy
    local cx, cw = ix + pad, iw - pad * 2
    cy = cy + pad
    local st = self:fileState(d, f)
    local res = F.scan(d.modId)
    local used = F.usedBy(d.modId, f.path)
    local e = res and res.byPath[f.path]
    -- the head: its name, where it is, its size, who uses it
    local file = f.path:match("([^/]+)$") or f.path
    local meta = { f.side }
    local size = F.sizeText(d.modId, f.path)
    if size then meta[#meta + 1] = size end
    if used then meta[#meta + 1] = (#used == 0) and ZeD.tr("UI_ZeD_Mods_FileUsedNone") or ZeD.tr("UI_ZeD_Mods_FileTagUsedBy", #used) end
    local th = T.textHead
    self:drawText(ZeD.Atoms.truncateText(file, f2, cw), cx, cy, th.r, th.g, th.b, th.a or 1, f2)
    cy = cy + MM.fontH(f2) + T.px(2)
    cy = self:paneText(table.concat(meta, " | "), cx, cy, cw, f3, dim) + T.px(6)
    -- its first lines (ZeD cannot tell what a file does; its own first lines say most)
    if e and #e.first > 0 then
        local ch = MM.fontH(T.fontF1) + T.px(14) + (#e.first + 1) * (MM.fontH(f3) + T.px(2))
        if cy + ch > vy and cy < vy + vh then self:drawCode(cx, cy, cw, ch, ZeD.tr("UI_ZeD_Mods_FileFirstLines"), e.first) end
        cy = cy + ch + T.px(8)
    end
    -- its errors (the last game's, from Messages), each place once
    local places = F.placesOn(d.name, f.path)
    for _, p in ipairs(places) do
        local key = (p.count == 1) and "UI_ZeD_Mods_FileErrOne" or "UI_ZeD_Mods_FileErrMany"
        cy = self:fileNote(ZeD.tr(key, p.count, p.line or "?", (p.fn and p.fn ~= "") and p.fn or "?", p.msg or ""), T.danger, cx, cw, cy)
    end
    if #places > 0 and used and #used >= MANY_USERS then
        cy = self:paneText(ZeD.tr("UI_ZeD_Mods_FileErrCleaner", #used), cx, cy, cw, f2, T.text) + T.px(6)
    end
    -- what switching it off does
    local verbs = {}
    if st == "game" then
        cy = self:fileNote(ZeD.tr("UI_ZeD_Mods_FileGame"), T.warningText, cx, cw, cy)
    elseif st == "gone" then
        cy = self:fileNote(ZeD.tr("UI_ZeD_Mods_FileGone"), T.warningText, cx, cw, cy)
        verbs[#verbs + 1] = { "mf:on", ZeD.tr("UI_ZeD_Mods_FileVerbForget"), function() self:switchFiles(d, { f.path }, false) end, "primary" }
    elseif st == "off" then
        cy = self:paneText(ZeD.tr("UI_ZeD_Mods_FileOffNow", d.name), cx, cy, cw, f2, T.text) + T.px(6)
        verbs[#verbs + 1] = { "mf:on", ZeD.tr("UI_ZeD_Mods_FileVerbOn"), function() self:switchFiles(d, { f.path }, false) end, "primary" }
    elseif not used then
        cy = self:paneText(ZeD.tr("UI_ZeD_Mods_FileReading"), cx, cy, cw, f2, dim) + T.px(6)
    elseif #used == 0 then
        cy = self:paneText(ZeD.tr("UI_ZeD_Mods_FileUsedNoneWhy"), cx, cy, cw, f2, T.text) + T.px(6)
        if can then verbs[#verbs + 1] = { "mf:off", ZeD.tr("UI_ZeD_Mods_FileVerbOff"), function() self:switchFiles(d, { f.path }, true) end, "primary" } end
    else
        cy = self:fileNote(ZeD.tr(#used == 1 and "UI_ZeD_Mods_FileUsedOne" or "UI_ZeD_Mods_FileUsedMany", #used, namesOf(used)), T.warningText, cx, cw, cy)
        if can then
            verbs[#verbs + 1] = { "mf:off", ZeD.tr("UI_ZeD_Mods_FileVerbOffAnyway"), function() self:switchFiles(d, { f.path }, true) end }
            local with = { f.path }
            for _, p in ipairs(used) do if not F.isGameFile(p) then with[#with + 1] = p end end
            verbs[#verbs + 1] = { "mf:offwith", ZeD.tr("UI_ZeD_Mods_FileVerbOffWith", #with - 1), function() self:switchFiles(d, with, true) end }
        end
    end
    -- (a verb leaves the controller on the file's row: the verb itself goes when the card changes)
    for _, v in ipairs(verbs) do
        local run = v[3]
        v[3] = function() run(); self.focusId = "mfile:" .. i end
    end
    if #verbs > 0 then cy = self:paneVerbs(verbs, cx, cy, cw, vy, vh, 700 + i + 0.5) + T.px(4) end
    cy = cy + pad
    ZeD.Atoms.frame(self, x0, y0, iw, cy - y0, T.borderS)
    return cy
end
