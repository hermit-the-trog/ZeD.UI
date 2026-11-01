-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuModsFolders.lua
-- ============================================================================
-- THE MODS PAGE'S FOLDERS (MOD_FOLDERS_SPEC.md sections 1 to 6, 9, 12; stage 2 of the Mods screen
-- work, punch list 37; mockup zed_mod_folders_v1, scenes a and a2)
--
-- Folders sort the collection (every installed mod, on or off) and live in Zomboid/Lua/ModFolders.cfg,
-- the file of [B42]Mod Folders by FieClaussell (ZeD_ModFolders.lua reads and writes it in that mod's
-- own format), so a player's layout is the same with or without ZeD. A folder never changes what is
-- on or the load order; its box turns its mods on or off at once (the director's pick: act, Accept
-- commits).
--   * once any folder exists the collection is grouped: the folders in their saved order, then
--     Unfiled (every mod in no folder; not a folder, never written to the file). Folders open and
--     close (saved in the file, as the mod saves it; Unfiled's state is ZeD's own)
--   * a folder's heading: its name, its count, its box (ticked, empty, or a dash when mixed)
--   * New folder... (the band, a row's menu), Rename..., Delete folder (asks; its mods go to
--     Unfiled), Move up / Move down, Open all / Close all
--   * Move to folder: a mod row's menu (right-click, Shift+F10 or the menu key), for every picked row
--     (Ctrl-click, Shift-click), and Move to folder... in the mod's pane (the controller's way)
--   * a line over the list says which list this is (the collection; on the Load order page, the
--     load order)
--   * built for 1,500 mods: the grouped list is worked out once per change and kept; each frame
--     draws, and makes stops for, only the rows in sight (one either side, and the focused one)
-- ============================================================================

require "ZeD/ZeD_MainMenuMods"
require "ZeD/ZeD_MainMenuModsOrder"
require "ZeD/ZeD_ModFolders"

local MM = ZeD.MainMenu
local UI = MM.ui
local F  = ZeD.ModFolders

-- design units
local ROW_H, HEAD_H = 42, 30
local INDENT = 12
local DETAIL_PAD, KV_ROW_H = 12, 20
local DOUBLE_MS = 450
local UNFILED = "unfiled"

local EMPTY = {}

local function model() return ModSelector and ModSelector.instance and ModSelector.instance.model end

-- the first entry whose bottom is below y (entries are in y order)
local function firstFrom(ents, y)
    local a, b = 1, #ents
    if b == 0 then return 1 end
    while a < b do
        local mid = math.floor((a + b) / 2)
        if ents[mid].y + ents[mid].h <= y then a = mid + 1 else b = mid end
    end
    return a
end

local function activeSet(m)
    local s = {}
    for id, d in pairs(m.mods or EMPTY) do if d.isActive then s[id] = true end end
    return s
end

-- ----------------------------------------------------------------------------
-- SET-UP: the file read each time the Mods page opens (spec 9.1: outside edits show)
-- ----------------------------------------------------------------------------
local _onShow = ZeD_MMMods.onShow
function ZeD_MMMods:onShow()
    _onShow(self)
    F.load()
    self.fsel, self.msel, self._msAnchor = nil, nil, nil
    self._fView, self._fDet, self._fScrollTo = nil, nil, nil
end

-- folders show (the Workshop tab stays flat: it lists Steam's items, spec 2.2)
function ZeD_MMMods:foldersOn()
    return self.filter ~= "ws" and F.any()
end

-- ----------------------------------------------------------------------------
-- WHICH LIST THIS IS (spec 1.1, 1.2): a line over the list while folders exist
-- ----------------------------------------------------------------------------
function ZeD_MMMods:listLine(x, top, w, which)
    if not F.any() then return top end
    local T = ZeD.T
    local f1, f2 = T.fontF1, T.fontF2
    local c = self._llC
    if not (c and c.which == which and c.w == w and c.scale == T.scale) then
        local label = ZeD.tr(which == "order" and "UI_ZeD_Folders_LineOrder" or "UI_ZeD_Folders_LineCollection")
        local text = ZeD.tr(which == "order" and "UI_ZeD_Folders_LineOrderText" or "UI_ZeD_Folders_LineCollectionText")
        local tx = T.px(8) + MM.textW(f1, label) + T.px(10)
        local lines = ZeD.Atoms.wrapText(text, f2, w - tx - T.px(8))
        local lh = MM.fontH(f2) + T.px(2)
        c = { which = which, w = w, scale = T.scale, label = label, tx = tx, lines = lines, lh = lh, h = #lines * lh + T.px(10) }
        self._llC = c
    end
    ZeD.Surface.fill(self, x + T.px(1), top, w - 2 * T.px(1), c.h - T.px(1), "surf2")
    ZeD.Atoms.drawDividerH(self, x, top + c.h - T.px(1), w, true)
    local la, dc = T.accent, T.textDim
    self:drawText(c.label, x + T.px(8), top + T.px(5) + math.floor((MM.fontH(f2) - MM.fontH(f1)) / 2), la.r, la.g, la.b, la.a or 1, f1)
    local ly = top + T.px(5)
    for _, l in ipairs(c.lines) do
        self:drawText(l, x + c.tx, ly, dc.r, dc.g, dc.b, dc.a or 1, f2)
        ly = ly + c.lh
    end
    return top + c.h
end

-- ----------------------------------------------------------------------------
-- THE GROUPED LIST: worked out once per change (the rows, the file, the scale), never per frame
-- ----------------------------------------------------------------------------
-- the box's sentence for a folder of n installed mods, k on
local function boxText(n, k)
    if n == 0 then return ZeD.tr("UI_ZeD_Folders_BoxEmpty") end
    return ZeD.tr(k == n and "UI_ZeD_Folders_BoxOff" or "UI_ZeD_Folders_BoxOn", n)
end

function ZeD_MMMods:folderView()
    local T = ZeD.T
    local rows = self:rows()
    local q = string.lower(tostring(self.find:getInternalText() or ""))
    local c = self._fView
    if c and c.rows == rows and c.gen == F.gen and c.scale == T.scale and c.filter == self.filter and c.q == q then return c end
    local m = model()
    local M = F.get()
    local rh, hh = T.px(ROW_H), T.px(HEAD_H)
    -- every installed mod's folder: each folder's count and how many are on (its box, spec 6.1)
    local tot, on, bucket = {}, {}, {}
    for _, d in ipairs(m and m.sortedMods or EMPTY) do
        local fid = F.folderOf(d.modId) or UNFILED
        tot[fid] = (tot[fid] or 0) + 1
        if d.isActive then on[fid] = (on[fid] or 0) + 1 end
    end
    -- the rows the tab and Find keep, in their folders (A to Z inside, as the rows come)
    for _, d in ipairs(rows) do
        local fid = F.folderOf(d.modId) or UNFILED
        local b = bucket[fid]
        if not b then b = {}; bucket[fid] = b end
        b[#b + 1] = d
    end
    local narrowed = self.filter ~= "all" or q ~= ""
    local ents, at, y = {}, {}, 0
    local seen = {}
    local unfiledOpen = F.unfiledOpen()
    local function head(fid, f)
        local b = bucket[fid] or EMPTY
        -- (a tab or Find: a folder with nothing to show is not drawn, spec 2.1, 2.3)
        if narrowed and #b == 0 then return end
        local open
        if q ~= "" then open = true elseif f then open = f.open else open = unfiledOpen end
        local n, k = tot[fid] or 0, on[fid] or 0
        local cnt
        if narrowed then cnt = ZeD.tr("UI_ZeD_Folders_CountOf", #b, n)
        elseif n == 0 then cnt = ZeD.tr("UI_ZeD_Folders_CountNone")
        elseif k == n then cnt = ZeD.tr("UI_ZeD_Folders_CountAllOn", n)
        else cnt = ZeD.tr("UI_ZeD_Folders_CountOn", n, k) end
        local key = f and f.id or UNFILED
        local sid = "frow:" .. tostring(key)
        local name = f and f.name or ZeD.tr("UI_ZeD_Folders_Unfiled")
        local help = f and ZeD.tr("UI_ZeD_Folders_HelpRow", name, n, k, boxText(n, k)) or ZeD.tr("UI_ZeD_Folders_HelpUnfiled")
        local e = { k = "folder", f = f, fkey = key, sid = sid, y = y, h = hh, open = open, n = n, on = k, cnt = cnt, name = name, help = help,
                    hid = "mods:" .. sid, tid = "mods:ftri:" .. tostring(key), bid = "mods:fbox:" .. tostring(key) }
        ents[#ents + 1] = e
        at[sid] = #ents
        y = y + hh
        if open then
            for _, d in ipairs(b) do
                local me = { k = "mod", d = d, fkey = key, sid = "mrow:" .. d.modId, y = y, h = rh }
                ents[#ents + 1] = me
                at[me.sid] = #ents
                y = y + rh
            end
        end
    end
    for _, f in ipairs(M.folders) do
        -- (two folder lines with one number, only by editing the file: the first is the folder)
        if not seen[f.id] then seen[f.id] = true; head(f.id, f) end
    end
    head(UNFILED, nil)
    c = { rows = rows, gen = F.gen, scale = T.scale, filter = self.filter, q = q, ents = ents, at = at, total = y, tot = tot, on = on }
    self._fView = c
    return c
end

-- the mod ids in the list's order now (Shift-click's range)
function ZeD_MMMods:visibleModIds()
    local t = {}
    if self:foldersOn() then
        for _, e in ipairs(self:folderView().ents) do if e.k == "mod" then t[#t + 1] = e.d.modId end end
    else
        for _, d in ipairs(self:rows()) do t[#t + 1] = d.modId end
    end
    return t
end

-- ----------------------------------------------------------------------------
-- DRAWING THE GROUPED LIST
-- ----------------------------------------------------------------------------
-- a folder picture: a tab and a body, outlined (no fill: System 7's folder in a list)
local function drawFolderPic(p, x, y, s, c)
    local T = ZeD.T
    local u = T.px(1)
    local th = math.max(u * 2, math.floor(s * 0.2))
    local tw = math.floor(s * 0.45)
    local by = y + th
    local bh = s - th - u
    p:drawRectBorder(x, y, tw, th + u, c.a or 1, c.r, c.g, c.b)
    p:drawRectBorder(x, by, s, bh, c.a or 1, c.r, c.g, c.b)
end

-- a folder's box: ticked (all on), empty (none on), the dash (some on); greyed when empty (spec 6)
local function drawFolderBox(p, x, y, n, k, hot)
    local T = ZeD.T
    local sz = T.checkboxSz
    ZeD.Atoms.drawCheckbox(p, x, y, n > 0 and k == n, hot, n == 0)
    if n > 0 and k > 0 and k < n then
        local c = T.text
        local m = T.px(3)
        local dh = math.max(T.px(2), 2)
        p:drawRect(x + m, y + math.floor((sz - dh) / 2), sz - m * 2, dh, c.a or 1, c.r, c.g, c.b)
    end
end

function ZeD_MMMods:drawFolderHead(e, x, ry, rw, vy, vh, gp)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local f2, f3 = T.fontF2, T.fontF3
    local s2 = T.surf2
    self:drawRect(x + T.px(1), ry, rw, e.h, s2.a or 1, s2.r, s2.g, s2.b)
    local hot = (not gp) and (MM.ctx.hot == e.hid or MM.ctx.hot == e.tid)
    local onFocus = MM.rowLook(self, x + T.px(1), ry, rw, e.h, self.fsel == e.fkey, hot, gp and self.focusId == e.sid)
    if hot or (gp and self.focusId == e.sid) then ZeD.Help.set(self, e.help) end
    self:drawRect(x + T.px(1), ry + e.h - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
    local dim = onFocus and T.textOnFocus or T.textDim
    -- the disclosure triangle
    local tri = T.px(6)
    local tx, tyy = x + T.px(10), ry + math.floor((e.h - tri) / 2)
    if e.open then ZeD.Atoms.drawTriangleDown(self, tx, tyy, tri, dim) else ZeD.Atoms.drawTriangleRight(self, tx, tyy, tri, dim) end
    local nx = tx + tri + T.px(8)
    if e.f then
        local ps = T.px(14)
        drawFolderPic(self, nx, ry + math.floor((e.h - ps) / 2), ps, onFocus and T.textOnFocus or T.text)
        nx = nx + ps + T.px(8)
    end
    -- the box at the right (not on Unfiled, spec 5.1)
    local cb = T.checkboxSz
    local bx = x + rw - T.px(10) - cb
    local right = e.f and (bx - T.px(8)) or (x + rw - T.px(10))
    local nc = onFocus and T.textOnFocus or (e.f and T.textHead or T.textDim)
    local cw = MM.textW(f3, e.cnt)
    local nameW = math.max(T.px(20), right - nx - cw - T.px(8))
    local shown = ZeD.Atoms.truncateText(e.name, f2, nameW)
    self:drawText(shown, nx, ry + math.floor((e.h - MM.fontH(f2)) / 2), nc.r, nc.g, nc.b, nc.a or 1, f2)
    self:drawText(e.cnt, nx + MM.textW(f2, shown) + T.px(8), ry + math.floor((e.h - MM.fontH(f3)) / 2), dim.r, dim.g, dim.b, dim.a or 1, f3)
    if e.f then drawFolderBox(self, bx, ry + math.floor((e.h - cb) / 2), e.n, e.on, MM.ctx.hot == e.bid) end
    -- the hits, kept with the entry (made once per change)
    local cy0, ch = math.max(ry, vy), math.min(ry + e.h, vy + vh) - math.max(ry, vy)
    local h1 = e.hit
    if not h1 then h1 = { id = e.hid, fn = function() self:clickFolder(e) end }; e.hit = h1 end
    h1.x, h1.y, h1.w, h1.h = ax + x, ay + cy0, rw, ch
    self._hits[#self._hits + 1] = h1
    local h2 = e.triHit
    if not h2 then h2 = { id = e.tid, fn = function() self:folderOpenClose(e) end }; e.triHit = h2 end
    h2.x, h2.y, h2.w, h2.h = ax + x, ay + cy0, tx + tri + T.px(4) - x, ch
    self._hits[#self._hits + 1] = h2
    if e.f then
        local h3 = e.boxHit
        if not h3 then h3 = { id = e.bid, fn = function() self.fsel = e.fkey; self.sel = nil; self:folderBox(e.fkey) end }; e.boxHit = h3 end
        h3.x, h3.y, h3.w, h3.h = ax + bx - T.px(6), ay + cy0, cb + T.px(16), ch
        self._hits[#self._hits + 1] = h3
    end
end

-- an entry's controller stop (made once per change)
function ZeD_MMMods:folderStop(e, k)
    local sp = e.spec
    if not sp then
        if e.k == "folder" then
            sp = { id = e.sid, listRow = true, col = 1, fkey = e.fkey, fn = function() self:folderOpenClose(e) end }
        else
            local d = e.d
            sp = { id = e.sid, listRow = true, col = 1, key = d.modId, fn = function() self:toggle(d) end }
        end
        e.spec = sp
    end
    sp.row, sp.ry, sp.rh = k, e.y, e.h
    if e.k == "folder" then sp.chosen = self.fsel == e.fkey end
    self._specs[#self._specs + 1] = sp
end

function ZeD_MMMods:drawFolderRows(x, y, w, h, vy)
    local T = ZeD.T
    local v = self:folderView()
    local ents = v.ents
    local vh = h - (vy - y) - T.px(1)
    local total = v.total
    local sbW = T.sp.scrollbarW
    local over = total > vh
    local rw = w - T.px(2) - (over and sbW or 0)
    -- (a move or a key asked for the focused row to be in sight)
    if self._fScrollTo then
        local k = v.at[self._fScrollTo]
        local e = k and ents[k]
        if e then
            if e.y < self.scroll then self.scroll = e.y elseif e.y + e.h > self.scroll + vh then self.scroll = e.y + e.h - vh end
        end
        self._fScrollTo = nil
    end
    self.scroll = math.max(0, math.min(self.scroll, math.max(0, total - vh)))
    local L = self._fListT
    if not L then L = {}; self._fListT = L end
    L.x, L.y, L.w, L.h = x, vy, w, vh
    self._list = L
    -- nothing picked yet: the first entry
    if self.sel == nil and self.fsel == nil and ents[1] then
        if ents[1].k == "mod" then self.sel = ents[1].d.modId else self.fsel = ents[1].fkey end
    end
    if #ents == 0 then
        local msg = (self.filter == "favs") and ZeD.tr("UI_ZeD_Mods_EmptyFavs") or ((self.filter == "problems") and ZeD.tr("UI_ZeD_Mods_EmptyProblems") or ZeD.tr("UI_ZeD_Mods_EmptyNone"))
        ZeD.Molecules.drawEmptyLine(self, x + T.px(12), vy + T.px(8), w - T.px(24), msg)
    end
    local gp = MM.gamepad()
    local star = ZeD.PxIcon.has("star")
    self:setStencilRect(x + T.px(1), vy, w - T.px(2), vh)
    local k0 = firstFrom(ents, self.scroll)
    local k = k0
    while k <= #ents do
        local e = ents[k]
        local ry = vy + e.y - self.scroll
        if ry >= vy + vh then break end
        self:folderStop(e, k)
        if e.k == "folder" then self:drawFolderHead(e, x, ry, rw, vy, vh, gp)
        else self:drawModRow(e.d, x, ry, rw, e.h, vy, vh, gp, e.sid, T.px(INDENT), star) end
        k = k + 1
    end
    -- stops out of sight: the one before, the one after, the focused one
    if k0 > 1 then self:folderStop(ents[k0 - 1], k0 - 1) end
    if ents[k] then self:folderStop(ents[k], k) end
    local kf = self.focusId and v.at[self.focusId]
    if kf and (kf < k0 - 1 or kf > k) then self:folderStop(ents[kf], kf) end
    self:clearStencilRect()
    if over then self:orderScrollBar(x + w - T.px(1) - sbW, vy, sbW, vh, total) end
end

-- ----------------------------------------------------------------------------
-- PICKING, OPENING, CLOSING
-- ----------------------------------------------------------------------------
-- a click picks the folder (its pane); a second click soon after opens or closes it
function ZeD_MMMods:clickFolder(e)
    local t = MM.now()
    if self.fsel == e.fkey and self._lastFClick and t - self._lastFClick < DOUBLE_MS then
        self._lastFClick = nil
        self:folderOpenClose(e)
        return
    end
    self._lastFClick = t
    if self.fsel ~= e.fkey then self.dscroll = 0; MM.hoverSound() end
    self.fsel, self.sel, self.msel = e.fkey, nil, nil
    self.focusId = e.sid
end

-- the triangle, a double-click, A: open or close, saved (a folder: in the file, spec 3.6;
-- Unfiled: ZeD's own). While Find has text every folder with a match shows open for the moment.
function ZeD_MMMods:folderOpenClose(e)
    if (self.find:getInternalText() or "") ~= "" then
        MM.hoverSound()
        self:say(ZeD.tr("UI_ZeD_Folders_SayFindOpen"))
        return
    end
    if e.f then
        local ok = F.setOpen(e.fkey, not e.open)
        if not ok then self:say(ZeD.tr("UI_ZeD_Folders_SayNoWrite")); return end
    else
        F.setUnfiledOpen(not e.open)
    end
    MM.clickSound()
    -- (the focus on a mod row now hidden: it lands on its folder)
    self.focusId = self.focusId or e.sid
    if e.open and self.focusId ~= e.sid and self.focusId:sub(1, 5) == "mrow:" then
        local v = self:folderView()
        local k = v.at[self.focusId]
        if k and v.ents[k].fkey == e.fkey then self.focusId = e.sid; self.fsel = e.fkey; self.sel = nil end
    end
    self._fScrollTo = self.focusId
end

-- ----------------------------------------------------------------------------
-- A FOLDER'S BOX (spec 6): every installed mod in it on (empty or mixed) or off (all on), at once;
-- the game's own rules, as a single tick; nothing reaches the game until Accept
-- ----------------------------------------------------------------------------
function ZeD_MMMods:folderBox(fid)
    local m = model()
    local f = F.byId(fid)
    if not (m and f) then return end
    local ds, onN = {}, 0
    for _, d in ipairs(m.sortedMods or EMPTY) do
        if F.folderOf(d.modId) == fid then
            ds[#ds + 1] = d
            if d.isActive then onN = onN + 1 end
        end
    end
    if #ds == 0 then MM.hoverSound(); self:say(ZeD.tr("UI_ZeD_Folders_BoxEmpty")); return end
    local turnOn = onN < #ds
    local before = activeSet(m)
    local cannot, keptOn, inFolder = {}, {}, {}
    local SF = ZeD.ModSafety
    for _, d in ipairs(ds) do
        inFolder[d.modId] = true
        if turnOn then
            if not d.isActive then
                -- (a mod that cannot run stays off; the template mod asks on its own row)
                if d.modId == "ModTemplate" or self:problemNow(d) then cannot[#cannot + 1] = tostring(d.name)
                else m:forceActivateMods(d.modInfo, true) end
            end
        elseif d.isActive then
            -- a save's own list: a mod its world may hold stays on (its own row asks first)
            local grade = "safe"
            if m.loadGameFolder and SF and SF.forTurnOff then pcall(function() grade = SF.forTurnOff(m, d).grade end) end
            if grade ~= "safe" then keptOn[#keptOn + 1] = tostring(d.name)
            else m:forceActivateMods(d.modInfo, false) end
        end
    end
    if turnOn and self.relayoutList then self:relayoutList() end
    self:dirty()
    MM.clickSound()
    local after = activeSet(m)
    local mine, extra = 0, {}
    for id in pairs(after) do
        if not before[id] then
            if inFolder[id] then mine = mine + 1 else extra[#extra + 1] = m.mods[id] and tostring(m.mods[id].name) or id end
        end
    end
    for id in pairs(before) do
        if not after[id] then
            if inFolder[id] then mine = mine + 1 else extra[#extra + 1] = m.mods[id] and tostring(m.mods[id].name) or id end
        end
    end
    local parts = {}
    if mine == 0 then parts[1] = ZeD.tr("UI_ZeD_Folders_SayNone", f.name)
    elseif turnOn then parts[1] = ZeD.tr(mine == 1 and "UI_ZeD_Folders_SayOnOne" or "UI_ZeD_Folders_SayOnMany", f.name, mine)
    else parts[1] = ZeD.tr(mine == 1 and "UI_ZeD_Folders_SayOffOne" or "UI_ZeD_Folders_SayOffMany", f.name, mine) end
    if #extra > 0 then
        if turnOn then parts[#parts + 1] = ZeD.tr("UI_ZeD_Folders_SayCameAlong", #extra, table.concat(extra, ", "))
        else parts[#parts + 1] = ZeD.tr("UI_ZeD_Folders_SayAlsoOff", table.concat(extra, ", ")) end
    end
    if #cannot > 0 then parts[#parts + 1] = ZeD.tr("UI_ZeD_Folders_SayCannot", #cannot, table.concat(cannot, ", ")) end
    if #keptOn > 0 then parts[#parts + 1] = ZeD.tr("UI_ZeD_Folders_SayKeptOn", table.concat(keptOn, ", ")) end
    self:say(table.concat(parts, " "))
end

-- ----------------------------------------------------------------------------
-- MOVING MODS (spec 4)
-- ----------------------------------------------------------------------------
-- the mods a menu on row d acts on: every picked row when d is one of them, else d alone
function ZeD_MMMods:folderTargets(d)
    if self.msel and self.msel[d.modId] then
        local t = {}
        for _, id in ipairs(self:visibleModIds()) do if self.msel[id] then t[#t + 1] = id end end
        -- (picked rows a tab or Find now hides still go)
        local inT = {}
        for _, id in ipairs(t) do inT[id] = true end
        for id in pairs(self.msel) do if not inT[id] then t[#t + 1] = id end end
        return t
    end
    return { d.modId }
end

-- ids into folder fid (nil: Unfiled); the focus stays on the mod, in its new place (its folder's
-- row when that folder is closed, spec 4.3)
function ZeD_MMMods:folderMove(ids, fid)
    local m = model()
    local ok, res = F.assign(ids, fid)
    if res == "gone" then MM.hoverSound(); self:say(ZeD.tr("UI_ZeD_Folders_SayGone")); return end
    if not ok then
        if res == "nowrite" then self:say(ZeD.tr("UI_ZeD_Folders_SayNoWrite")) end
        return
    end
    MM.clickSound()
    local n = #ids
    local one = m and m.mods[ids[1]] and tostring(m.mods[ids[1]].name) or tostring(ids[1])
    local f = fid and F.byId(fid)
    if f then self:say(ZeD.tr(n == 1 and "UI_ZeD_Folders_SayMovedOne" or "UI_ZeD_Folders_SayMovedMany", n == 1 and one or n, f.name))
    else self:say(ZeD.tr(n == 1 and "UI_ZeD_Folders_SayOutOne" or "UI_ZeD_Folders_SayOutMany", n == 1 and one or n)) end
    self.msel = nil
    local onRow = (self.focusId or ""):sub(1, 5) == "mrow:"
    if onRow then
        local open = true
        if (self.find:getInternalText() or "") == "" then
            if f then open = f.open else open = F.unfiledOpen() end
        end
        if not open then
            self.focusId = "frow:" .. tostring(fid or UNFILED)
            self.fsel, self.sel = fid or UNFILED, nil
        end
    end
    self._fScrollTo = self.focusId
end

-- the Move to folder pop-up (mockup a2): the folders, New folder..., and Take out of the folder
function ZeD_MMMods:modFolderMenu(d, anchor)
    if not d then return end
    local ids = self:folderTargets(d)
    if #ids == 1 then self.sel = d.modId; self.fsel = nil end
    local items = { { text = (#ids == 1) and ZeD.tr("UI_ZeD_Folders_MenuMoveHead") or ZeD.tr("UI_ZeD_Folders_MenuMoveHeadMany", #ids), disabled = true }, "-" }
    local cur, anyIn = nil, false
    for _, id in ipairs(ids) do
        local fid = F.folderOf(id)
        if fid then anyIn = true end
        if #ids == 1 then cur = fid end
    end
    for _, f in ipairs(F.folders()) do
        local fid = f.id
        items[#items + 1] = { text = ZeD.Atoms.truncateText(f.name, ZeD.T.fontF2, ZeD.T.px(260)), disabled = (cur ~= nil and cur == fid), fn = function() self:folderMove(ids, fid) end }
    end
    if #F.folders() > 0 then items[#items + 1] = "-" end
    local full = #F.folders() >= F.MAX
    items[#items + 1] = { text = ZeD.tr("UI_ZeD_Folders_BtnNew"), disabled = full, fn = function() self:folderAskNew(ids) end }
    if anyIn then items[#items + 1] = { text = ZeD.tr("UI_ZeD_Folders_MenuTakeOut"), fn = function() self:folderMove(ids, nil) end } end
    MM.openPopup("modFolder", items, anchor or self:folderAnchor(), false)
end

-- Move to folder... in the mod's pane (the controller's way: A on it, the D-pad picks, A moves,
-- B leaves it where it was; the focus stays on the button)
function ZeD_MMMods:folderVerb(d)
    local anchor = nil
    for _, b in ipairs(self._specs or EMPTY) do
        if b.id == "fmove" and b.x then
            anchor = { x = self:getAbsoluteX() + b.x, y = self:getAbsoluteY() + b.y, w = b.w, h = b.h }
        end
    end
    self:modFolderMenu(d, anchor)
end

-- where a menu opened from the keyboard or the controller sits: at the focused row
function ZeD_MMMods:folderAnchor()
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local L = self._list
    if L and self:foldersOn() then
        local v = self:folderView()
        local k = self.focusId and v.at[self.focusId]
        local e = k and v.ents[k]
        if e then return { x = ax + L.x + T.px(60), y = ay + L.y + e.y - self.scroll, w = T.px(10), h = e.h } end
    end
    if L then return { x = ax + L.x + T.px(60), y = ay + L.y + T.px(20), w = T.px(10), h = T.px(10) } end
    return { x = ax + T.px(60), y = ay + T.px(60), w = T.px(10), h = T.px(10) }
end

-- a folder row's menu (spec 3: Rename..., Delete folder, Move up / Move down, Open all / Close all)
function ZeD_MMMods:folderMenu(e, anchor)
    local items = { { text = e.name, disabled = true }, "-" }
    local list = F.folders()
    if e.f then
        local fid = e.fkey
        local idx = 0
        for i, f in ipairs(list) do if f.id == fid then idx = i end end
        items[#items + 1] = { text = ZeD.tr("UI_ZeD_Folders_MenuRename"), fn = function() self:folderAskRename(fid) end }
        items[#items + 1] = { text = ZeD.tr("UI_ZeD_Folders_MenuDelete"), fn = function() self:folderAskDelete(fid) end }
        items[#items + 1] = "-"
        items[#items + 1] = { text = ZeD.tr("UI_ServerSettings_ButtonMoveUp"), disabled = idx <= 1, fn = function() self:folderShift(fid, -1) end }
        items[#items + 1] = { text = ZeD.tr("UI_ServerSettings_ButtonMoveDown"), disabled = idx >= #list, fn = function() self:folderShift(fid, 1) end }
        items[#items + 1] = "-"
    end
    items[#items + 1] = { text = ZeD.tr("UI_ZeD_Folders_MenuOpenAll"), fn = function() self:folderAllOpen(true) end }
    items[#items + 1] = { text = ZeD.tr("UI_ZeD_Folders_MenuCloseAll"), fn = function() self:folderAllOpen(false) end }
    items[#items + 1] = "-"
    items[#items + 1] = { text = ZeD.tr("UI_ZeD_Folders_BtnNew"), disabled = #list >= F.MAX, fn = function() self:folderAskNew(nil) end }
    MM.openPopup("folderRow", items, anchor or self:folderAnchor(), false)
end

function ZeD_MMMods:folderShift(fid, delta)
    local ok, res = F.moveFolder(fid, delta)
    if not ok then
        if res == "nowrite" then self:say(ZeD.tr("UI_ZeD_Folders_SayNoWrite")) end
        return
    end
    MM.clickSound()
    self._fScrollTo = self.focusId
end

function ZeD_MMMods:folderAllOpen(open)
    local ok, res = F.setAllOpen(open)
    if res == "nowrite" then self:say(ZeD.tr("UI_ZeD_Folders_SayNoWrite")); return end
    if F.unfiledOpen() ~= open then F.setUnfiledOpen(open) end
    MM.clickSound()
    -- (a focused mod row now hidden: its folder's row)
    local f = self.focusId or ""
    if not open and f:sub(1, 5) == "mrow:" then
        local fid = F.folderOf(f:sub(6)) or UNFILED
        self.focusId, self.fsel, self.sel = "frow:" .. tostring(fid), fid, nil
    end
    self._fScrollTo = self.focusId
end

-- ----------------------------------------------------------------------------
-- THE BAND: New folder..., Rename..., Delete folder (spec 3.1 to 3.5)
-- ----------------------------------------------------------------------------
-- the Mods page band's button (greyed at 99 folders, spec 3.3)
function ZeD_MMMods:folderNewSpec()
    local full = #F.folders() >= F.MAX
    return { "fnew", ZeD.tr("UI_ZeD_Folders_BtnNew"), function() self:folderAskNew(nil) end, "default", full,
             ZeD.tr(full and "UI_ZeD_Folders_HelpFull" or "UI_ZeD_Folders_HelpNew") }
end

-- ids: the mods that go into the new folder (made from a row's menu), or nil
function ZeD_MMMods:folderAskNew(ids)
    if #F.folders() >= F.MAX then MM.hoverSound(); self:say(ZeD.tr("UI_ZeD_Folders_HelpFull")); return end
    self._fNewMove = ids
    self._backFocus = self.focusId
    self:setConfirm("fnew")
end

function ZeD_MMMods:folderAskRename(fid)
    local f = F.byId(fid)
    if not f then return end
    self._fTarget, self._fieldPre = fid, f.name
    self._backFocus = self.focusId
    self:setConfirm("frename")
end

function ZeD_MMMods:folderAskDelete(fid)
    if not F.byId(fid) then return end
    self._fTarget = fid
    self._backFocus = self.focusId
    self:setConfirm("fdelete")
end

-- Return in the band's field, or its button
function ZeD_MMMods:folderFieldEnter(c)
    local text = F.trim(self.field:getText())
    if #text > F.NAME_MAX then text = string.sub(text, 1, F.NAME_MAX) end
    local except = (c == "frename") and self._fTarget or nil
    if F.nameProblem(text, except) then MM.hoverSound(); return end
    if c == "fnew" then
        local ok, res = F.create(text)
        local ids = self._fNewMove
        self._fNewMove = nil
        self:setConfirm(false)
        if not ok then self:say(ZeD.tr("UI_ZeD_Folders_SayNoWrite")); return end
        MM.clickSound()
        self:say(ZeD.tr("UI_ZeD_Folders_SayMade", text))
        -- (made from a row's menu: that row's mod, or every picked one, goes in, spec 3.1)
        if ids and #ids > 0 then self:folderMove(ids, res) end
    else
        local f = F.byId(self._fTarget)
        local old = f and f.name or ""
        local ok, res = F.rename(self._fTarget, text)
        self:setConfirm(false)
        if not ok and res == "nowrite" then self:say(ZeD.tr("UI_ZeD_Folders_SayNoWrite")); return end
        if ok then MM.clickSound(); self:say(ZeD.tr("UI_ZeD_Folders_SayRenamed", old, text)) end
    end
end

function ZeD_MMMods:folderDelete()
    local fid = self._fTarget
    local f = F.byId(fid)
    self:setConfirm(false)
    if not f then self:say(ZeD.tr("UI_ZeD_Folders_SayGone")); return end
    local name = f.name
    local ok = F.delete(fid)
    if not ok then self:say(ZeD.tr("UI_ZeD_Folders_SayNoWrite")); return end
    MM.clickSound()
    self:say(ZeD.tr("UI_ZeD_Folders_SayDeleted", name))
    if self.fsel == fid or self.focusId == "frow:" .. tostring(fid) then
        -- (the folder's row is gone: the focus goes to Unfiled, where its mods are now)
        if F.any() then self.fsel, self.focusId = UNFILED, "frow:" .. UNFILED
        else self.fsel, self.focusId = nil, nil end
        self._fScrollTo = self.focusId
    end
end

function ZeD_MMMods:folderStrip(stripY, stripH, w, row)
    local T = ZeD.T
    local c = self.confirm
    local cancel = { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end }
    if c == "fdelete" then
        local f = F.byId(self._fTarget)
        local name = f and f.name or ""
        local v = self:folderView()
        local n = v.tot[self._fTarget] or 0
        local ask
        if n == 0 then ask = ZeD.tr("UI_ZeD_Folders_AskDeleteEmpty", name)
        elseif n == 1 then ask = ZeD.tr("UI_ZeD_Folders_AskDeleteOne", name)
        else ask = ZeD.tr("UI_ZeD_Folders_AskDeleteMany", name, n) end
        UI.stripSpecs(self, stripY, w, row, {}, {
            cancel,
            { "confirm:yes", getText("UI_btn_delete"), function() self:folderDelete() end, "danger", false, ZeD.tr("UI_ZeD_Folders_HelpDelete") } },
            ask)
        return
    end
    local text = self.field:getText() or ""
    local except = (c == "frename") and self._fTarget or nil
    local probKey, probArg = F.nameProblem(text, except)
    local ask
    if probKey == "UI_ZeD_Folders_NameUsed" then ask = ZeD.tr(probKey, probArg)
    elseif c == "frename" then
        local f = F.byId(self._fTarget)
        ask = ZeD.tr("UI_ZeD_Folders_AskRename", f and f.name or "")
    else ask = ZeD.tr("UI_ZeD_Folders_AskNew") end
    local fx = UI.stripSpecs(self, stripY, w, row, {}, {
        cancel,
        { "confirm:yes", (c == "frename") and getText("UI_btn_rename") or ZeD.tr("UI_ZeD_Folders_BtnMake"), function() self:fieldEnter() end, "primary", probKey ~= nil } },
        ask, true)
    local firstBtn = w
    for _, b in ipairs(self._specs) do if b.row == row and b.x then firstBtn = math.min(firstBtn, b.x) end end
    local fh = T.px(24)
    UI.styleEntry(self.field, fx, stripY + math.floor((stripH - fh) / 2), math.max(T.px(80), firstBtn - T.px(12) - fx), fh)
    -- (typing stops at 48 letters, spec 12.3)
    if #text > F.NAME_MAX then self.field:setText(string.sub(text, 1, F.NAME_MAX)) end
end

-- ----------------------------------------------------------------------------
-- THE FOLDER'S PANE (mockup a): what is in it, what is not installed, what the box does
-- ----------------------------------------------------------------------------
function ZeD_MMMods:folderDetailModel(iw)
    local T = ZeD.T
    local v = self:folderView()
    local c = self._fDet
    if c and c.v == v and c.fsel == self.fsel and c.iw == iw and c.gen == F.gen then return c end
    local m = model()
    local fid = self.fsel
    local f = fid ~= UNFILED and F.byId(fid) or nil
    c = { v = v, fsel = fid, iw = iw, gen = F.gen, f = f, mods = {}, missing = {} }
    self._fDet = c
    for _, d in ipairs(m and m.sortedMods or EMPTY) do
        if (F.folderOf(d.modId) or UNFILED) == fid then c.mods[#c.mods + 1] = d end
    end
    if f then
        for _, id in ipairs(F.membersOf(fid)) do if not (m and m.mods[id]) then c.missing[#c.missing + 1] = id end end
    end
    local n, k = v.tot[fid] or 0, v.on[fid] or 0
    c.n, c.k = n, k
    c.title = f and f.name or ZeD.tr("UI_ZeD_Folders_Unfiled")
    c.sub = f and ZeD.tr("UI_ZeD_Folders_DetSub", n, k) or ZeD.tr("UI_ZeD_Folders_DetSubUnfiled", n, k)
    local f2 = T.fontF2
    local boxKey = (n == 0 and "UI_ZeD_Folders_DetBoxEmpty") or (k == n and "UI_ZeD_Folders_DetBoxAll") or (k == 0 and "UI_ZeD_Folders_DetBoxNone") or "UI_ZeD_Folders_DetBoxSome"
    c.boxLines = f and ZeD.Atoms.wrapText(ZeD.tr(boxKey, n), f2, iw) or EMPTY
    c.orderLines = ZeD.Atoms.wrapText(ZeD.tr(f and "UI_ZeD_Folders_DetNeverOrder" or "UI_ZeD_Folders_DetUnfiledNote"), f2, iw)
    c.keptLines = ZeD.Atoms.wrapText(ZeD.tr("UI_ZeD_Folders_DetKeptNote"), f2, iw)
    c.emptyLines = ZeD.Atoms.wrapText(ZeD.tr("UI_ZeD_Folders_DetEmpty"), f2, iw)
    c.inHead, c.missHead, c.boxHead = ZeD.tr("UI_ZeD_Folders_DetIn"), ZeD.tr("UI_ZeD_Folders_DetNotInstalled"), ZeD.tr("UI_ZeD_Folders_DetBox")
    c.inCount, c.missCount = tostring(#c.mods), tostring(#c.missing)
    -- the pane's buttons
    if f then
        local list = F.folders()
        local idx = 0
        for i, g in ipairs(list) do if g.id == fid then idx = i end end
        c.verbs = {
            { "fturn", ZeD.tr((n > 0 and k == n) and "UI_ZeD_Folders_VerbTurnAllOff" or "UI_ZeD_Folders_VerbTurnAllOn"), function() self:folderBox(fid) end, "default", n == 0 },
            { "frename", ZeD.tr("UI_ZeD_Folders_MenuRename"), function() self:folderAskRename(fid) end },
            { "fdelete", ZeD.tr("UI_ZeD_Folders_MenuDelete"), function() self:folderAskDelete(fid) end },
            { "fup", ZeD.tr("UI_ServerSettings_ButtonMoveUp"), function() self:folderShift(fid, -1) end, "default", idx <= 1 },
            { "fdown", ZeD.tr("UI_ServerSettings_ButtonMoveDown"), function() self:folderShift(fid, 1) end, "default", idx >= #list },
        }
    else
        c.verbs = { { "fnewp", ZeD.tr("UI_ZeD_Folders_BtnNew"), function() self:folderAskNew(nil) end, "default", #F.folders() >= F.MAX } }
    end
    c.outVerbs = {}
    local takeOut = ZeD.tr("UI_ZeD_Folders_VerbTakeOut")
    for i, id in ipairs(c.missing) do c.outVerbs[i] = { { "fout:" .. i, takeOut, function() self:folderDropMissing(id) end } } end
    return c
end

-- a heading in the folder's pane, its count beside it, a rule under it; returns the y under it
function ZeD_MMMods:paneHead(text, count, ix, iw, cy)
    local T = ZeD.T
    local f1, la, dc = T.fontF1, T.accent, T.textDim
    self:drawText(text, ix, cy, la.r, la.g, la.b, la.a or 1, f1)
    if count then self:drawText(count, ix + MM.textW(f1, text) + T.px(8), cy, dc.r, dc.g, dc.b, dc.a or 1, f1) end
    cy = cy + T.px(KV_ROW_H)
    self:drawRect(ix, cy - T.px(4), self._fDet and self._fDet.iw or 0, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
    return cy
end

-- lines already wrapped; returns the y under them
function ZeD_MMMods:paneLines(lines, ix, cy, color)
    local T = ZeD.T
    local f2 = T.fontF2
    for _, l in ipairs(lines) do
        self:drawText(l, ix, cy, color.r, color.g, color.b, color.a or 1, f2)
        cy = cy + MM.fontH(f2) + T.px(2)
    end
    return cy
end

function ZeD_MMMods:drawFolderDetail(x, vy, w, vh)
    local T = ZeD.T
    local pad = T.px(DETAIL_PAD)
    local ix, iw = x + pad, w - pad * 2
    local c = self:folderDetailModel(iw)
    local D = self._fDetT
    if not D then D = {}; self._fDetT = D end
    D.x, D.y, D.w, D.h = x, vy, w, vh
    self._detail = D
    self:setStencilRect(x + T.px(1), vy + T.px(1), w - T.px(2), vh - T.px(2))
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local cy = vy + pad - self.dscroll
    local hf = ZeD.Font.sdf.head
    local z = 20 * (T.scale or 1) / (hf.face or 64)
    local tc, dc, txt, la = T.textHead, T.textDim, T.text, T.accent
    local tx = ix
    if c.f then
        local ps = T.px(18)
        drawFolderPic(self, ix, cy + T.px(3), ps, txt)
        tx = ix + ps + T.px(10)
    end
    ZeD.Text.draw(self, hf, ZeD.Atoms.truncateText(c.title, T.fontF4, ix + iw - tx), tx, cy, z, tc.r, tc.g, tc.b, tc.a or 1, "l")
    cy = cy + math.floor(ZeD.Text.height(hf, z)) + T.px(2)
    self:drawText(ZeD.Atoms.truncateText(c.sub, f2, iw), ix, cy, dc.r, dc.g, dc.b, dc.a or 1, f2)
    cy = cy + MM.fontH(f2) + T.px(8)
    -- the verbs (made once per change, with the pane's model)
    cy = self:paneVerbs(c.verbs, ix, cy, iw, vy, vh, 500) + T.px(12)
    local lineH = MM.fontH(f2) + T.px(8)
    -- what is in it (only the lines in sight are drawn: a folder of 300 mods)
    cy = self:paneHead(c.inHead, c.inCount, ix, iw, cy)
    if #c.mods == 0 then cy = self:paneLines(c.emptyLines, ix, cy, dc) end
    local cb = T.checkboxSz
    local bottom = vy + vh
    for _, d in ipairs(c.mods) do
        if cy + lineH > vy and cy < bottom then
            ZeD.Atoms.drawCheckbox(self, ix, cy + math.floor((MM.fontH(f2) - cb) / 2), d.isActive, false, false)
            self:drawText(ZeD.Atoms.truncateText(tostring(d.name), f2, iw - cb - T.px(10)), ix + cb + T.px(10), cy, txt.r, txt.g, txt.b, txt.a or 1, f2)
        end
        cy = cy + lineH
    end
    -- what the file holds that is not installed (kept, not counted: spec 5.2, 5.3)
    if #c.missing > 0 then
        cy = cy + T.px(6)
        cy = self:paneHead(c.missHead, c.missCount, ix, iw, cy)
        local dsz = T.px(5)
        for i, id in ipairs(c.missing) do
            local bh = T.buttonH
            local rowH = math.max(lineH, bh + T.px(4))
            if cy + rowH > vy and cy < bottom then
                local bw = ZeD.Molecules.buttonW(ZeD.tr("UI_ZeD_Folders_VerbTakeOut"))
                ZeD.Atoms.drawStatusDot(self, ix + T.px(2), cy + math.floor((rowH - dsz) / 2), dc, dsz)
                self:drawText(ZeD.Atoms.truncateText(id, f3, iw - bw - T.px(24)), ix + T.px(14), cy + math.floor((rowH - MM.fontH(f3)) / 2), txt.r, txt.g, txt.b, txt.a or 1, f3)
                self:paneVerbs(c.outVerbs[i], ix + iw - bw, cy + math.floor((rowH - bh) / 2), bw, vy, vh, 700 + i)
            end
            cy = cy + rowH
        end
        cy = cy + T.px(4)
        cy = self:paneLines(c.keptLines, ix, cy, dc)
    end
    if c.f then
        cy = cy + T.px(10)
        cy = self:paneHead(c.boxHead, nil, ix, iw, cy)
        cy = self:paneLines(c.boxLines, ix, cy, txt)
    end
    cy = cy + T.px(8)
    cy = self:paneLines(c.orderLines, ix, cy, dc)
    self:clearStencilRect()
    local contentH = cy + self.dscroll - vy + pad
    D.contentH = contentH
    self.dscroll = math.max(0, math.min(self.dscroll, math.max(0, contentH - vh)))
end

function ZeD_MMMods:folderDropMissing(id)
    local ok, res = F.dropMember(id)
    if res == "nowrite" then self:say(ZeD.tr("UI_ZeD_Folders_SayNoWrite")); return end
    if ok then MM.clickSound(); self:say(ZeD.tr("UI_ZeD_Folders_SayDropped", id)) end
end

-- ----------------------------------------------------------------------------
-- PICKING SEVERAL ROWS (spec 4.1): Ctrl-click adds or drops a row, Shift-click a run of rows
-- ----------------------------------------------------------------------------
local _clickRow = ZeD_MMMods.clickRow
function ZeD_MMMods:clickRow(d)
    self.fsel = nil
    if self.page == "list" and (isCtrlKeyDown() or isShiftKeyDown()) and self.filter ~= "ws" then
        local s = self.msel or {}
        if isShiftKeyDown() and (self._msAnchor or self.sel) then
            local a = self._msAnchor or self.sel
            local list = self:visibleModIds()
            local ia, ib
            for i, id in ipairs(list) do
                if id == a then ia = i end
                if id == d.modId then ib = i end
            end
            if ia and ib then
                if not isCtrlKeyDown() then s = {} end
                for i = math.min(ia, ib), math.max(ia, ib) do s[list[i]] = true end
            else s[d.modId] = true end
        else
            if not self.msel and self.sel and self.sel ~= d.modId then s[self.sel] = true end
            if s[d.modId] then s[d.modId] = nil else s[d.modId] = true end
            self._msAnchor = d.modId
        end
        local n = 0
        for _ in pairs(s) do n = n + 1 end
        self.msel = n > 0 and s or nil
        self.sel = d.modId
        self.focusId = "mrow:" .. d.modId
        self._lastClick = nil
        MM.hoverSound()
        return
    end
    self.msel = nil
    self._msAnchor = d.modId
    _clickRow(self, d)
end

-- ----------------------------------------------------------------------------
-- MOUSE, CONTROLLER, KEYS
-- ----------------------------------------------------------------------------
-- a right-click on a row of the Mods list: a mod's Move to folder, a folder's own menu
local _rightClick = ZeD_MMMods.rightClick
function ZeD_MMMods:rightClick(mx, my)
    if self.page ~= "list" or self.confirm or self.filter == "ws" then return _rightClick(self, mx, my) end
    local L = self._list
    local lx, ly = mx - self:getAbsoluteX(), my - self:getAbsoluteY()
    if not (L and lx >= L.x and lx <= L.x + L.w and ly >= L.y and ly <= L.y + L.h) then return false end
    local yy = ly - L.y + self.scroll
    local anchor = { x = mx, y = my, w = 1, h = 1 }
    if self:foldersOn() then
        local v = self:folderView()
        local k = firstFrom(v.ents, yy)
        local e = v.ents[k]
        if not (e and yy >= e.y and yy < e.y + e.h) then return false end
        self.focusId = e.sid
        if e.k == "folder" then
            self.fsel, self.sel, self.msel = e.fkey, nil, nil
            self:folderMenu(e, anchor)
        else
            self.fsel = nil
            if not (self.msel and self.msel[e.d.modId]) then self.msel = nil end
            self:modFolderMenu(e.d, anchor)
        end
        return true
    end
    -- (no folder yet: a mod row's menu makes the first one)
    local rows = self:rows()
    local d = rows[math.floor(yy / ZeD.T.px(ROW_H)) + 1]
    if not d then return false end
    self.focusId = "mrow:" .. d.modId
    if not (self.msel and self.msel[d.modId]) then self.msel = nil end
    self:modFolderMenu(d, anchor)
    return true
end

-- the D-pad on a folder row picks the folder (its pane); on a mod row, the mod
local _joyDir = ZeD_MMMods.joyDir
function ZeD_MMMods:joyDir(dir)
    _joyDir(self, dir)
    if self.page ~= "list" then return end
    for _, b in ipairs(self._specs or EMPTY) do
        if b.id == self.focusId and b.listRow then
            if b.fkey ~= nil then
                if self.fsel ~= b.fkey then self.dscroll = 0 end
                self.fsel, self.sel = b.fkey, nil
            elseif b.key ~= nil then
                self.fsel = nil
            end
        end
    end
end

-- X on a folder row: its box (on a mod row X stays the star)
local _joyX = ZeD_MMMods.joyX
function ZeD_MMMods:joyX()
    local f = self.focusId or ""
    if self.page == "list" and not self.confirm and f:sub(1, 5) == "frow:" then
        if self.fsel and self.fsel ~= UNFILED then self:folderBox(self.fsel) else MM.hoverSound() end
        return
    end
    _joyX(self)
end

local _prompts = ZeD_MMMods.getFooterPrompts
function ZeD_MMMods:getFooterPrompts()
    if MM.gamepad() and self.page == "list" and not self.confirm and (self.focusId or ""):sub(1, 5) == "frow:" then
        local t = { { glyph = "A", label = ZeD.tr("UI_ZeD_Folders_PromptOpenClose") } }
        if self.fsel and self.fsel ~= UNFILED then t[#t + 1] = { glyph = "X", label = ZeD.tr("UI_ZeD_Folders_PromptBox") } end
        t[#t + 1] = { glyph = "Y", label = ZeD.tr("UI_ZeD_Mods_BtnProfiles") }
        t[#t + 1] = { glyph = "LB", label = "" }
        t[#t + 1] = { glyph = "RB", label = ZeD.tr("UI_ZeD_Mods_PromptFilter") }
        t[#t + 1] = { glyph = "B", label = ZeD.btnCase(getText("UI_btn_back")) }
        return t
    end
    return _prompts(self)
end

-- the help line with nothing under the pointer: picked rows, or lines of the file ZeD could not read
local _status = ZeD_MMMods.getStatusLine
function ZeD_MMMods:getStatusLine()
    if self.page == "list" then
        if self.msel then
            local n = 0
            for _ in pairs(self.msel) do n = n + 1 end
            if n > 1 then return ZeD.tr("UI_ZeD_Folders_StatusPicked", n) end
        end
        local M = F.cur
        if M and M.bad > 0 then return ZeD.tr("UI_ZeD_Folders_StatusBad", M.bad) end
    end
    return _status(self)
end

-- the folder row before (-1) or after (1) the focused entry (Page Up / Page Down, spec 12.8)
function ZeD_MMMods:folderJump(dir)
    local v = self:folderView()
    local k = (self.focusId and v.at[self.focusId]) or 0
    local j = k + dir
    while j >= 1 and j <= #v.ents do
        local e = v.ents[j]
        if e.k == "folder" then
            self.focusId, self.fsel, self.sel, self.msel = e.sid, e.fkey, nil, nil
            self.dscroll = 0
            self._fScrollTo = e.sid
            MM.hoverSound()
            return
        end
        j = j + dir
    end
end

-- keys on the Mods list (true = handled): Shift+F10 or the menu key, the row's menu; Page Up /
-- Page Down, folder to folder; on a folder row Space its box, F2 Rename..., Delete Delete folder;
-- Up / Down from a picked folder
local _keyOther = ZeD_MMMods.keyOther
function ZeD_MMMods:keyOther(key)
    local K = Keyboard
    if self.page ~= "list" or self.confirm or self.find:isFocused() or self.filter == "ws" then return _keyOther(self, key) end
    if key == K.KEY_RETURN and self._enterAt and MM.now() - self._enterAt < 400 then return _keyOther(self, key) end
    local f = self.focusId or ""
    local on = self:foldersOn()
    local onFolder = on and f:sub(1, 5) == "frow:" and self.fsel ~= nil
    if (K.KEY_APPS and key == K.KEY_APPS) or (isShiftKeyDown() and key == K.KEY_F10) then
        if onFolder then
            local v = self:folderView()
            local k = v.at[f]
            if k then self:folderMenu(v.ents[k], nil) end
        else
            local d = self:selected()
            if d then
                self.focusId = "mrow:" .. d.modId
                self:modFolderMenu(d, nil)
            end
        end
        return true
    end
    if on and (key == K.KEY_PRIOR or key == K.KEY_NEXT) then self:folderJump(key == K.KEY_PRIOR and -1 or 1); return true end
    if onFolder and self.fsel ~= UNFILED then
        if key == K.KEY_SPACE then self:folderBox(self.fsel); return true end
        if key == K.KEY_F2 then self:folderAskRename(self.fsel); return true end
        if key == K.KEY_DELETE then self:folderAskDelete(self.fsel); return true end
    end
    if on and (key == K.KEY_UP or key == K.KEY_DOWN) then
        local v = self:folderView()
        if self.fsel ~= nil then self.focusId = "frow:" .. tostring(self.fsel)
        elseif self.sel then
            -- (a picked mod inside a closed folder: from its folder's row)
            self.focusId = "mrow:" .. self.sel
            if not v.at[self.focusId] then self.focusId = "frow:" .. tostring(F.folderOf(self.sel) or UNFILED) end
        end
        self:joyDir(key == K.KEY_UP and "up" or "down")
        return true
    end
    return _keyOther(self, key)
end

-- Escape drops a multi-selection first
local _keyEscape = ZeD_MMMods.keyEscape
function ZeD_MMMods:keyEscape()
    if self.page == "list" and not self.confirm and not self._palette and self.msel then self.msel = nil; return true end
    return _keyEscape(self)
end
