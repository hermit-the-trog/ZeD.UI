-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuSpawn.lua
-- ============================================================================
-- MAP / SPAWN ON THE MONITOR (HOOK_MAP row 26; director, Oct 14 2026: menus
-- delegated, no mockups)
--
-- The town a new character starts in, as a ZeD window on the desk's screen in
-- place of vanilla's MapSpawnSelect. Vanilla's screen stays built and keeps
-- every rule: its fillList (towns by game mode, the map order, ignored maps,
-- Random), its map panel and data, the save-name checks, the seed, and its
-- clickNext / clickBack (sandbox options or character creation next; New Game,
-- Load Game or World Select back). Its setVisible(true) is redirected here.
--
--   left   the towns (a list box), then the new world's SAVE NAME and SEED
--          (only when a world is being made, as vanilla)
--   right  vanilla's own map panel, moved into this window: it glides to the
--          chosen town; the houses a new character can wake up in are marked;
--          the town's video plays in a small inset; drag pans, the wheel zooms
--          below: the town's name and vanilla's description
--   band   Back, Next (Next waits for a usable save name; the reason shows
--          under the field with a red status square)
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "OptionScreens/MapSpawnSelect"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui

-- design units
local LIST_SHARE = 0.36              -- the towns' share of the body
local ROW_H = 30
local DET_PAD, LABEL_H, FIELD_H, NOTE_H = 10, 18, 24, 22   -- the details box: a label over each field
local VIDEO_SHARE, VIDEO_MAX_W = 0.34, 260
local MARK = 6                       -- a house marker's side
local DESC_MAX_SHARE = 0.38          -- the description's most of the right side (longer text scrolls)

local function ms() return MainScreen and MainScreen.instance end
local function vanilla() return MapSpawnSelect and MapSpawnSelect.instance end

-- vanilla's town description as paragraphs: its centred name line is dropped (the
-- heading says it), each <LINE> run ends a paragraph, every other tag goes
local function townParagraphs(desc)
    local s = tostring(desc or "")
    local a, b = s:find("<LEFT>", 1, true)
    if a and s:sub(1, a):find("<CENTRE>", 1, true) then s = s:sub(b + 1) end
    s = s:gsub("<LINE>", "\n")
    s = s:gsub("<[^>]*>", " ")
    local paras = {}
    for line in s:gmatch("[^\n]+") do
        local t = line:gsub("%s+", " ")
        t = t:gsub("^%s+", "")
        t = t:gsub("%s+$", "")
        if t ~= "" then paras[#paras + 1] = t end
    end
    return paras
end

-- every house a new character can wake up in, across the professions (vanilla's
-- spawnpoints.lua lists them per profession; old map mods give a cell and an offset)
local function townPoints(item)
    if not item then return {} end
    if item._zedPts then return item._zedPts end
    local pts, seen = {}, {}
    local region = item.region
    if region and type(region.points) == "table" then
        for _, list in pairs(region.points) do
            if type(list) == "table" then
                for _, p in ipairs(list) do
                    local x, y = p.posX, p.posY
                    if x and y and p.worldX and p.worldY then x, y = p.worldX * 300 + x, p.worldY * 300 + y end
                    if x and y then
                        local k = math.floor(x) .. "," .. math.floor(y)
                        if not seen[k] then seen[k] = true; pts[#pts + 1] = { x = x, y = y } end
                    end
                end
            end
        end
    end
    item._zedPts = pts
    return pts
end

-- ============================================================================
-- THE MAP: vanilla's MapSpawnSelectImage, moved into the window. Same data, same
-- style; it follows this window's choice (zedGoal) instead of vanilla's list, and
-- the window's pointer drives it (the screen's glass takes the mouse).
-- ============================================================================
ZeD_MMSpawnMap = MapSpawnSelectImage:derive("ZeD_MMSpawnMap")

function ZeD_MMSpawnMap:prerender()
    ISUIElement.prerender(self)
    if self:getWidth() < 1 then return end
    local api = self.mapAPI
    if not self.hasResetView and api:getDataCount() > 0 and api:isDataLoaded() then
        self.hasResetView = true
        MapUtils.initDefaultStyleV1(self)
        self.javaObject:getAPIv1():getStyleAPI():removeLayerById("forest")
        MapUtils.overlayPaper(self)
        api:setBoundsFromData()
        api:resetView()
        self.zedHome = { x = api:getCenterWorldX(), y = api:getCenterWorldY(), z = api:getZoomF() }
        self.zedShownKey = nil
    elseif self.pyramidFileName and not self.hasResetView then
        self.hasResetView = true
        api:setBoundsInSquares(0, 0, api:getImagePyramidWidthInSquares(self.pyramidFileName), api:getImagePyramidHeightInSquares(self.pyramidFileName))
        api:resetView()
        self.zedHome = { x = api:getCenterWorldX(), y = api:getCenterWorldY(), z = api:getZoomF() }
        self.zedShownKey = nil
    end
    -- the chosen town: a jump the first time, a glide after
    local g = self.zedGoal
    if self.hasResetView and g and g.key ~= self.zedShownKey then
        local first = (self.zedShownKey == nil)
        self.zedShownKey = g.key
        local x, y, z = g.x, g.y, g.z
        local home = self.zedHome
        if (not x) and home then x, y, z = home.x, home.y, home.z end
        if x then
            z = z or api:getZoomF()
            if first then api:centerOn(x, y); api:setZoom(z) else api:transitionTo(x, y, z) end
        end
    end
end

function ZeD_MMSpawnMap:render() ISUIElement.render(self) end
function ZeD_MMSpawnMap:onMouseDown(x, y) return false end
function ZeD_MMSpawnMap:onMouseMove(dx, dy) return false end
function ZeD_MMSpawnMap:onMouseMoveOutside(dx, dy) return false end
function ZeD_MMSpawnMap:onMouseUp(x, y) return false end
function ZeD_MMSpawnMap:onMouseUpOutside(x, y) return false end
function ZeD_MMSpawnMap:onMouseDoubleClick(x, y) return false end
function ZeD_MMSpawnMap:onMouseWheel(del) return MM.wheel(del) end

-- ============================================================================
-- THE WINDOW
-- ============================================================================
ZeD_MMSpawn = ZeD_MMWindow:derive("ZeD_MMSpawn")

function ZeD_MMSpawn:new()
    local o = ZeD_MMWindow.new(self, "spawn")
    o.noResetControl = true
    o.sel = 1
    o.scroll = 0
    o.videos = {}
    return o
end

function ZeD_MMSpawn:createChildren()
    ZeD_Window.createChildren(self)
    -- the save's name and the world's seed (vanilla's limits)
    self.nameEntry = UI.newEntry(self)
    self.nameEntry.onCommandEntered = function() self._enterAt = MM.now(); self.nameEntry:unfocus() end
    self.seedEntry = UI.newEntry(self)
    self.seedEntry:setOnlyText(true)
    self.seedEntry:setMaxTextLength(16)
    self.seedEntry.onCommandEntered = function() self._enterAt = MM.now(); self.seedEntry:unfocus() end
end

-- vanilla's towns, as its fillList left them (Random last when there is a choice)
function ZeD_MMSpawn:items()
    local v = vanilla()
    local t = {}
    if v and v.listbox then
        for i, it in ipairs(v.listbox.items) do t[i] = it.item end
    end
    return t
end

function ZeD_MMSpawn:isRandom(it)
    return it ~= nil and it.region == nil and it.name == getText("UI_mapspawn_random")
end

-- the save name and seed show only while a world is being made (vanilla's hideOrShowSaveName)
function ZeD_MMSpawn:hasDetails()
    local m = ms()
    if not m or not m.createWorld then return false end
    if getCore():isChallenge() then return false end
    local v = vanilla()
    if not v or not v.textEntry then return false end
    return true
end

function ZeD_MMSpawn:onShow()
    local v = vanilla()
    self.sel = 1
    if v and v.listbox and v.listbox.selected and v.listbox.selected >= 1 then self.sel = v.listbox.selected end
    self.scroll = 0
    self.focusId = "town:" .. self.sel
    self._lastClick, self._drag, self._existsKey = nil, nil, nil
    if v then
        if v.textEntry then self.nameEntry:setText(v.textEntry:getText() or "") end
        if v.seedTextBox then self.seedEntry:setText(v.seedTextBox:getText() or "") end
        -- vanilla's map panel moves in here (its data is already loading from fillList)
        local mp = v.mapPanel
        if mp then
            if getmetatable(mp) ~= ZeD_MMSpawnMap then setmetatable(mp, ZeD_MMSpawnMap) end
            if mp.parent ~= self then self:addChild(mp) end
            mp.zedShownKey = nil
        end
    end
    self.nameEntry:unfocus()
    self.seedEntry:unfocus()
end

-- what keeps NEXT from going on: vanilla's checks on the save name, in words
function ZeD_MMSpawn:nameProblem()
    if not self:hasDetails() then return nil end
    local raw = self.nameEntry:getText() or ""
    local name = sanitizeWorldName(raw)
    if raw == "" or name == "" then return ZeD.tr("UI_ZeD_Spawn_ErrNoName") end
    if name ~= raw then
        local spaced = raw:gsub(" ", "_")
        if spaced == name then return ZeD.tr("UI_ZeD_Spawn_ErrSpaces") end
        return ZeD.tr("UI_ZeD_Spawn_ErrCharacters")
    end
    if luautils.stringStarts(name, ".") or luautils.stringEnds(name, ".") then return ZeD.tr("UI_ZeD_Spawn_ErrDot") end
    local key = getWorld():getGameMode() .. getFileSeparator() .. name
    if key ~= self._existsKey then
        self._existsKey = key
        self._exists = checkSaveFolderExists(key)
    end
    if self._exists then return ZeD.tr("UI_ZeD_Spawn_ErrExists") end
    return nil
end

function ZeD_MMSpawn:syncToVanilla()
    local v = vanilla()
    if not v then return end
    if v.textEntry then v.textEntry:setText(self.nameEntry:getText() or "") end
    if v.seedTextBox then v.seedTextBox:setText(self.seedEntry:getText() or "") end
end

function ZeD_MMSpawn:newSeed()
    MM.clickSound()
    self.seedEntry:setText(WorldGenUtils.INSTANCE:generateSeed())
end

-- NEXT: vanilla's clickNext with this town (sandbox options or character creation follow)
function ZeD_MMSpawn:next()
    local v = vanilla()
    local items = self:items()
    if not v or not items[self.sel] or self:nameProblem() then return end
    MM.clickSound()
    self:syncToVanilla()
    v.listbox.selected = self.sel
    MM.toVanilla()
    MapSpawnSelect.clickNext(v)
end

-- BACK: vanilla's clickBack (New Game and Load Game land back on the monitor)
function ZeD_MMSpawn:back()
    MM.clickSound()
    local v = vanilla()
    if not v or not v.previousScreen then MM.showView("newgame"); return end
    self:syncToVanilla()
    MM.toVanilla()
    MapSpawnSelect.clickBack(v)
end

function ZeD_MMSpawn:pick(i)
    if i ~= self.sel then MM.hoverSound() end
    self.sel = i
    self.focusId = "town:" .. i
end

-- a click picks the town; a second click on it soon after goes on (vanilla's double-click)
function ZeD_MMSpawn:clickTown(i)
    local t = MM.now()
    if self.sel == i and self._lastClick and t - self._lastClick < 450 then
        self._lastClick = nil
        self:next()
        return
    end
    self._lastClick = t
    self:pick(i)
end

-- the video inset's box in the window (the map's top-right corner), or nil
function ZeD_MMSpawn:insetRect(m, it)
    if not m or not self:townVideo(it) then return nil end
    local T = ZeD.T
    local fr = T.px(3)
    local vw = math.min(T.px(VIDEO_MAX_W), math.floor(m.w * VIDEO_SHARE))
    local vh = math.floor(vw * 9 / 16)
    local bw, bh = vw + fr * 2, vh + fr * 2
    if bh + T.px(20) > m.h then return nil end
    return { x = m.x + m.w - T.px(10) - bw, y = m.y + T.px(10), w = bw, h = bh, vw = vw, vh = vh, fr = fr }
end

-- where the map should be for a town: every house it can start you in, framed in the
-- map beside the video (never closer than vanilla's own zoom for the town); without
-- houses, vanilla's zoom from map.info; Random, the whole map
function ZeD_MMSpawn:mapGoal(it, mp, m)
    if not it or not mp or not mp.hasResetView or not m then return nil end
    if self:isRandom(it) then return { key = "all" } end
    local key = "town:" .. tostring(it.name) .. ":" .. m.w .. "x" .. m.h
    local pts = townPoints(it)
    if #pts > 0 then
        local T = ZeD.T
        local api = mp.mapAPI
        local x0, y0, x1, y1 = pts[1].x, pts[1].y, pts[1].x, pts[1].y
        for _, p in ipairs(pts) do
            x0, x1 = math.min(x0, p.x), math.max(x1, p.x)
            y0, y1 = math.min(y0, p.y), math.max(y1, p.y)
        end
        local bw, bh = math.max(x1 - x0, 300), math.max(y1 - y0, 300)
        -- the free part of the map: inside a margin, left of the video
        local pad = T.px(28)
        local right = m.w - pad
        local ins = self:insetRect(m, it)
        if ins then right = ins.x - m.x - pad end
        local fw, fh = math.max(T.px(60), right - pad), math.max(T.px(60), m.h - pad * 2)
        -- the map's scale doubles with each zoom step: scale = k * 2^zoom
        local k = api:getWorldScale() / (2 ^ api:getZoomF())
        local z = math.log(math.min(fw / bw, fh / bh) / k) / math.log(2)
        local zmax = 16
        if it.zoomS and it.zoomS > 0 then zmax = it.zoomS end
        if z > zmax then z = zmax end
        local s = k * (2 ^ z)
        -- centre the view so the houses' middle sits in the free part's middle
        local cx = (x0 + x1) / 2 + (m.w / 2 - (pad + fw / 2)) / s
        local cy = (y0 + y1) / 2 + (m.h / 2 - (pad + fh / 2)) / s
        return { key = key, x = cx, y = cy, z = z }
    end
    if it.zoomX and not (it.zoomX == 0 and it.zoomY == 0 and it.zoomS == 0) then
        return { key = key, x = it.zoomX, y = it.zoomY, z = it.zoomS }
    end
    return { key = "all" }
end

-- the town's video (vanilla's demoVideo), or its still when video effects are off
function ZeD_MMSpawn:townVideo(it)
    if not it or not it.demoVideo then return nil end
    local doVideo = getCore():getOptionDoVideoEffects()
    local key = tostring(it.demoVideo) .. (doVideo and ":v" or ":p")
    local c = self.videos[key]
    if c == nil then
        c = false
        if doVideo then
            local ok, vt = pcall(getVideo, it.demoVideo, 1920, 1080)
            if ok and vt then c = { tex = vt, video = true } end
        else
            local ok, t = pcall(getTexture, "media/videos/" .. tostring(it.demoVideo) .. ".png")
            if ok and t then c = { tex = t } end
        end
        self.videos[key] = c
    end
    if c then return c end
    return nil
end

-- the description box's height: the tallest town's, so the map keeps its size
function ZeD_MMSpawn:descHeight(items, w, maxH)
    local T = ZeD.T
    local f2 = T.fontF2
    local key = w .. ":" .. #items .. ":" .. tostring(f2) .. ":" .. tostring(items[1] and items[1].name)
    if self._descKey ~= key then
        self._descKey = key
        local hf = ZeD.Font.sdf.head
        local z = 20 * (T.scale or 1) / (hf.face or 64)
        local bigH = math.floor(ZeD.Text.height(hf, z))
        local lineH = MM.fontH(f2) + T.px(3)
        local tallest = 0
        for _, it in ipairs(items) do
            local n = 0
            local paras = townParagraphs(it.desc)
            for _, p in ipairs(paras) do n = n + #ZeD.Atoms.wrapText(p, f2, w - T.px(32)) end
            local hgt = T.px(14) * 2 + bigH + T.px(6) + n * lineH + math.max(0, #paras - 1) * T.px(6)
            tallest = math.max(tallest, hgt)
        end
        self._descH = tallest
    end
    return math.max(T.px(60), math.min(self._descH or 0, maxH))
end

function ZeD_MMSpawn:prerender()
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    local w, h = UI.placeOnTube(self)
    local items = self:items()
    if self.sel > #items then self.sel = math.max(1, #items) end
    local it = items[self.sel]
    self.title = ZeD.tr("UI_ZeD_Spawn_Title")
    self.titleStats = { { text = MM.modeName(getWorld():getGameMode()), noMark = true } }
    ZeD_Window.prerender(self)
    if not isMouseButtonDown(0) then self._drag = nil end

    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = MM.bandH()
    local stripY = h - self:footerHeight() - stripH
    local bodyY, bodyH = tb + pad, stripY - tb - pad * 2
    local lw = math.floor((w - pad * 3) * LIST_SHARE)
    local rx, rw = pad * 2 + lw, w - pad * 3 - lw

    -- left: the towns, then the new world's name and seed
    local details = self:hasDetails()
    local detH = 0
    if details then detH = T.px(DET_PAD) * 2 + (T.px(LABEL_H) + T.px(FIELD_H)) * 2 + T.px(NOTE_H) end
    local listH = bodyH - ((detH > 0) and (detH + pad) or 0)
    self:drawTowns(pad, bodyY, lw, listH, items)
    if details then
        self:drawDetails(pad, bodyY + listH + pad, lw, detH)
    else
        if self.nameEntry:isVisible() then self.nameEntry:setVisible(false) end
        if self.seedEntry:isVisible() then self.seedEntry:setVisible(false) end
    end

    -- right: the map, the town's words under it
    local descH = self:descHeight(items, rw, math.floor(bodyH * DESC_MAX_SHARE))
    local mapH = bodyH - descH - pad
    self:placeMap(rx, bodyY, rw, mapH, it)
    self:drawDesc(rx, bodyY + mapH + pad, rw, descH, it)

    -- the band at the foot
    UI.stripSpecs(self, stripY, w, 1000,
        { { "back", getText("UI_btn_back"), function() self:back() end } },
        { { "next", getText("UI_btn_next"), function() self:next() end, "primary", (it == nil) or (self:nameProblem() ~= nil) } })
    self._cur = it
end

function ZeD_MMSpawn:render()
    self:drawMapOverlay(self._cur)
    UI.drawStripAndButtons(self)
    ZeD_Window.render(self)
end

function ZeD_MMSpawn:drawTowns(x, y, w, h, items)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    UI.insetBox(self, x, y, w, h)
    local vy, vh = y + T.px(1), h - T.px(2)
    local rh = T.px(ROW_H)
    local rowsH = #items * rh
    local sbW = T.sp.scrollbarW
    local over = rowsH > vh
    local rw = w - T.px(2) - (over and sbW or 0)
    self.scroll = math.max(0, math.min(self.scroll, math.max(0, rowsH - vh)))
    self._list = { x = x, y = vy, w = w, h = vh, rowsH = rowsH }
    local gp = MM.gamepad()
    local f2 = T.fontF2
    self:setStencilRect(x + T.px(1), vy, w - T.px(2), vh)
    for i, it in ipairs(items) do
        local ry = vy - self.scroll + (i - 1) * rh
        local fid = "town:" .. i
        self._specs[#self._specs + 1] = { id = fid, listRow = true, row = i, col = 1, fn = function() self:next() end, index = i, ry = (i - 1) * rh, rh = rh }
        if ry + rh > vy and ry < vy + vh then
            local onFocus = MM.rowLook(self, x + T.px(1), ry, rw, rh, i == self.sel, (not gp) and MM.ctx.hot == "spawn:" .. fid, gp and self.focusId == fid)
            if (not gp) and MM.ctx.hot == "spawn:" .. fid then ZeD.Help.set(self, ZeD.tr("UI_ZeD_MMHelp_TownRow")) end
            self:drawRect(x + T.px(1), ry + rh - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
            local c = onFocus and T.textOnFocus or ((i == self.sel) and T.textHead or T.text)
            local name = ZeD.Atoms.truncateText(tostring(it.name or ""), f2, rw - T.px(20))
            self:drawText(name, x + T.px(10), ry + math.floor((rh - MM.fontH(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
            local cy, ch = math.max(ry, vy), math.min(ry + rh, vy + vh) - math.max(ry, vy)
            self._hits[#self._hits + 1] = { id = "spawn:" .. fid, x = ax + x, y = ay + cy, w = rw, h = ch, fn = function() self:clickTown(i) end }
        end
    end
    self:clearStencilRect()
    if over then
        local sx = x + w - T.px(1) - sbW
        ZeD.Atoms.drawScrollTrack(self, sx, vy, sbW, vh)
        local th = math.max(T.px(24), math.floor(vh * vh / rowsH))
        local tyy = vy + math.floor((vh - th) * self.scroll / (rowsH - vh))
        ZeD.Atoms.drawScrollThumb(self, sx, tyy, sbW, th, MM.ctx.hot == "spawn:track" and "hover" or "default")
        self._hits[#self._hits + 1] = { id = "spawn:track", x = ax + sx, y = ay + vy, w = sbW, h = vh, fn = function()
            local my = getMouseY() - ay - vy
            self.scroll = math.floor((my / vh) * rowsH - vh / 2)
        end }
    end
end

-- SAVE NAME and SEED: a mono accent label over each ZeD field, and the reason a name will not do
function ZeD_MMSpawn:drawDetails(x, y, w, h)
    local T = ZeD.T
    local bs = T.borderS
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    ZeD.Atoms.frame(self, x, y, w, h, bs)
    local gp = MM.gamepad()
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local ix, iw = x + T.px(DET_PAD), w - T.px(DET_PAD) * 2
    local lh, fh = T.px(LABEL_H), T.px(FIELD_H)
    local cy = y + T.px(DET_PAD)
    -- a field's label; the controller's mark takes the label and field together
    local function label(text, ry, fid)
        local focused = gp and self.focusId == fid
        local onFocus = focused and ZeD.Focus.mark(self, x + T.px(1), ry - T.px(3), w - 2 * T.px(1), lh + fh + 2 * T.px(3), MM.focusOpts())
        local la = onFocus and T.textOnFocus or T.accent
        self:drawText(text, ix, ry + math.floor((lh - MM.fontH(f1)) / 2) - T.px(1), la.r, la.g, la.b, la.a or 1, f1)
    end
    -- the save name
    label(ZeD.textCase(ZeD.trBare("UI_mapselecter_savename")), cy, "field:name")
    cy = cy + lh
    if not self.nameEntry:isVisible() then self.nameEntry:setVisible(true) end
    UI.styleEntry(self.nameEntry, ix, cy, iw, fh)
    self._specs[#self._specs + 1] = { id = "field:name", listRow = true, row = 500, col = 1, fn = function() self:edit(self.nameEntry) end, x = ix, y = cy, w = iw, h = fh }
    self._hits[#self._hits + 1] = { id = "spawn:name", x = ax + ix, y = ay + cy, w = iw, h = fh, fn = function() self.nameEntry:focus() end }
    cy = cy + fh
    -- why the name will not do
    local why = self:nameProblem()
    if why then
        local dsz = T.px(7)
        local ny = cy + math.floor((T.px(NOTE_H) - MM.fontH(f2)) / 2)
        ZeD.Atoms.drawStatusDot(self, ix, ny + math.floor((MM.fontH(f2) - dsz) / 2), T.danger, dsz)
        local c = T.text
        self:drawText(ZeD.Atoms.truncateText(why, f2, iw - dsz - T.px(6)), ix + dsz + T.px(6), ny, c.r, c.g, c.b, c.a or 1, f2)
    end
    cy = cy + T.px(NOTE_H)
    -- the seed, and a fresh one beside it
    label(ZeD.textCase(ZeD.tr("UI_advWorld_seed_label")), cy, "field:seed")
    cy = cy + lh
    if not self.seedEntry:isVisible() then self.seedEntry:setVisible(true) end
    local bText = ZeD.tr("UI_ZeD_Spawn_NewSeed")
    local bw = ZeD.Molecules.buttonW(bText)
    local bx = ix + iw - bw
    local fw = bx - T.px(8) - ix
    UI.styleEntry(self.seedEntry, ix, cy, fw, fh)
    self._specs[#self._specs + 1] = { id = "field:seed", listRow = true, row = 501, col = 1, fn = function() self:edit(self.seedEntry) end, x = ix, y = cy, w = fw, h = fh }
    self._hits[#self._hits + 1] = { id = "spawn:seed", x = ax + ix, y = ay + cy, w = fw, h = fh, fn = function() self.seedEntry:focus() end }
    self._specs[#self._specs + 1] = { id = "seed:new", text = bText, fn = function() self:newSeed() end, variant = "default", row = 501, col = 2,
                                      x = bx, y = cy + math.floor((fh - T.buttonH) / 2), w = bw, h = T.buttonH }
end

-- a field with the controller: vanilla's on-screen keyboard; with the mouse / keys: the caret
function ZeD_MMSpawn:edit(entry)
    local jd = MM.gamepad() and JoypadState and JoypadState.getMainMenuJoypad and JoypadState.getMainMenuJoypad()
    if jd and OnScreenKeyboard and OnScreenKeyboard.Show then
        local osk = OnScreenKeyboard.Show(jd.player or 0, entry, jd)
        if osk then
            osk.prevFocus = jd.focus
            jd.focus = osk
            updateJoypadFocus(jd)
            return
        end
    end
    entry:focus()
end

-- the map: vanilla's panel sized into the box; dragging pans it
function ZeD_MMSpawn:placeMap(x, y, w, h, it)
    local T = ZeD.T
    UI.insetBox(self, x, y, w, h)
    local ix, iy, iw, ih = x + T.px(1), y + T.px(1), w - T.px(2), h - T.px(2)
    self._map = { x = ix, y = iy, w = iw, h = ih }
    local v = vanilla()
    local mp = v and v.mapPanel
    if not mp or mp.parent ~= self then return end
    if mp.x ~= ix or mp.y ~= iy then mp:setX(ix); mp:setY(iy) end
    if mp.width ~= iw or mp.height ~= ih then mp:setWidth(iw); mp:setHeight(ih) end
    mp.zedGoal = self:mapGoal(it, mp, { x = ix, y = iy, w = iw, h = ih })
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    self._hits[#self._hits + 1] = { id = "spawn:map", x = ax + ix, y = ay + iy, w = iw, h = ih, drag = function(mx, my) self:panMap(mx, my) end }
end

-- a held press on the map moves it with the mouse (vanilla's MapSpawnSelectImage drag)
function ZeD_MMSpawn:panMap(mx, my)
    local v = vanilla()
    local mp = v and v.mapPanel
    if not mp or not mp.hasResetView then return end
    local api = mp.mapAPI
    local lx, ly = mx - mp:getAbsoluteX(), my - mp:getAbsoluteY()
    local d = self._drag
    if not d then
        self._drag = { cx = api:getCenterWorldX(), cy = api:getCenterWorldY(), z = api:getZoomF(),
                       wx = api:uiToWorldX(lx, ly), wy = api:uiToWorldY(lx, ly) }
        return
    end
    local wx = api:uiToWorldX(lx, ly, d.z, d.cx, d.cy)
    local wy = api:uiToWorldY(lx, ly, d.z, d.cx, d.cy)
    api:centerOn(d.cx + d.wx - wx, d.cy + d.wy - wy)
end

-- over the map: the house markers, the inset line, the town's video
function ZeD_MMSpawn:drawMapOverlay(it)
    local T = ZeD.T
    local m = self._map
    if not m then return end
    local v = vanilla()
    local mp = v and v.mapPanel
    if mp and mp.parent == self and mp.hasResetView then
        -- the houses this town can start you in (Random: every town's)
        local pts = {}
        if self:isRandom(it) then
            for _, o in ipairs(self:items()) do for _, p in ipairs(townPoints(o)) do pts[#pts + 1] = p end end
        else
            pts = townPoints(it)
        end
        local api = mp.mapAPI
        local s = T.px(MARK)
        local o1 = T.px(1)
        local ac = T.accent
        self:setStencilRect(m.x, m.y, m.w, m.h)
        for _, p in ipairs(pts) do
            local ux, uy = api:worldToUIX(p.x, p.y), api:worldToUIY(p.x, p.y)
            local px, py = m.x + math.floor(ux - s / 2), m.y + math.floor(uy - s / 2)
            if px > m.x - s and px < m.x + m.w and py > m.y - s and py < m.y + m.h then
                self:drawRect(px - o1, py - o1, s + o1 * 2, s + o1 * 2, 1, 0, 0, 0)
                self:drawRect(px, py, s, s, 1, ac.r, ac.g, ac.b)
            end
        end
        self:clearStencilRect()
    end
    -- the video: a small framed picture in the map's top-right corner
    local r = self:insetRect(m, it)
    if r then
        local vid = self:townVideo(it)
        local s1, bs = T.surf1, T.borderS
        self:drawRect(r.x, r.y, r.w, r.h, 1, s1.r, s1.g, s1.b)
        ZeD.Atoms.frame(self, r.x, r.y, r.w, r.h, bs)
        self:drawRect(r.x + r.fr, r.y + r.fr, r.vw, r.vh, 1, 0, 0, 0)
        if vid.video then vid.tex:RenderFrame() end
        self:drawTextureScaledAspect(vid.tex, r.x + r.fr, r.y + r.fr, r.vw, r.vh, 1, 1, 1, 1)
    end
end

-- the town's name and vanilla's words about it; longer words scroll inside the box
function ZeD_MMSpawn:drawDesc(x, y, w, h, it)
    local T = ZeD.T
    UI.insetBox(self, x, y, w, h)
    self._desc = nil
    if not it then return end
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local hf = ZeD.Font.sdf.head
    local z = 20 * (T.scale or 1) / (hf.face or 64)
    local bigH = math.floor(ZeD.Text.height(hf, z))
    local f2, c, tc = T.fontF2, T.text, T.textHead
    local lineH = MM.fontH(f2) + T.px(3)
    local sbW = T.sp.scrollbarW
    -- the lines, wrapped once per town and width
    local key = tostring(it.name) .. ":" .. w .. ":" .. tostring(f2)
    if self._descFor ~= key then
        self._descFor = key
        self.descScroll = 0
        local paras = townParagraphs(it.desc)
        if self:isRandom(it) then paras = { ZeD.tr("UI_ZeD_Spawn_RandomDesc") } end
        local lines, ch = {}, T.px(14) + bigH + T.px(6)
        for pi, p in ipairs(paras) do
            if pi > 1 then ch = ch + T.px(6) end
            for _, l in ipairs(ZeD.Atoms.wrapText(p, f2, w - T.px(32) - sbW)) do
                lines[#lines + 1] = { text = l, y = ch }
                ch = ch + lineH
            end
        end
        self._descLines, self._descContentH = lines, ch + T.px(10)
    end
    local vy, vh = y + T.px(1), h - T.px(2)
    local over = self._descContentH > vh
    local maxS = math.max(0, self._descContentH - vh)
    self.descScroll = math.max(0, math.min(self.descScroll or 0, maxS))
    local oy = y - self.descScroll
    self._desc = { x = x, y = vy, w = w, h = vh, over = over }
    self:setStencilRect(x + T.px(1), vy, w - T.px(2), vh)
    ZeD.Text.draw(self, hf, tostring(it.name or ""), x + T.px(16), oy + T.px(14), z, tc.r, tc.g, tc.b, tc.a or 1, "l")
    for _, l in ipairs(self._descLines) do
        local ly = oy + l.y
        if ly + lineH > vy and ly < vy + vh then self:drawText(l.text, x + T.px(16), ly, c.r, c.g, c.b, c.a or 1, f2) end
    end
    self:clearStencilRect()
    if over then
        local sx = x + w - T.px(1) - sbW
        ZeD.Atoms.drawScrollTrack(self, sx, vy, sbW, vh)
        local th = math.max(T.px(24), math.floor(vh * vh / self._descContentH))
        local tyy = vy + math.floor((vh - th) * self.descScroll / maxS)
        ZeD.Atoms.drawScrollThumb(self, sx, tyy, sbW, th, MM.ctx.hot == "spawn:desctrack" and "hover" or "default")
        local contentH = self._descContentH
        self._hits[#self._hits + 1] = { id = "spawn:desctrack", x = ax + sx, y = ay + vy, w = sbW, h = vh, fn = function()
            local my = getMouseY() - ay - vy
            self.descScroll = math.floor((my / vh) * contentH - vh / 2)
        end }
    end
end

-- CONTROLLER + KEYS + WHEEL ------------------------------------------------------

-- the list follows the controller: a focused town is the chosen one, scrolled into view
function ZeD_MMSpawn:joyDir(dir)
    ZeD_MMWindow.joyDir(self, dir)
    for _, b in ipairs(self._specs) do
        if b.id == self.focusId and b.index then
            self.sel = b.index
            local vh = self._list and self._list.h or 0
            if b.ry < self.scroll then self.scroll = b.ry
            elseif b.ry + b.rh > self.scroll + vh then self.scroll = b.ry + b.rh - vh end
        end
    end
end

function ZeD_MMSpawn:joyB() self:back() end
function ZeD_MMSpawn:joyY() if self:hasDetails() then self:newSeed() end end

function ZeD_MMSpawn:getFooterPrompts()
    if not MM.gamepad() then return nil end
    local f = self.focusId or ""
    if f:sub(1, 5) == "town:" then
        local t = { { glyph = "A", label = ZeD.btnCase(getText("UI_btn_next")) } }
        if self:hasDetails() then t[#t + 1] = { glyph = "Y", label = ZeD.tr("UI_ZeD_Spawn_PromptNewSeed") } end
        t[#t + 1] = { glyph = "B", label = ZeD.btnCase(getText("UI_btn_back")) }
        return t
    end
    if f:sub(1, 6) == "field:" then return { { glyph = "A", label = ZeD.tr("UI_ZeD_Sandbox_PromptEdit") }, { glyph = "B", label = ZeD.btnCase(getText("UI_btn_back")) } } end
    return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = ZeD.btnCase(getText("UI_btn_back")) } }
end

-- Escape: leave a field, then the screen
function ZeD_MMSpawn:keyEscape()
    if self.nameEntry:isFocused() then self.nameEntry:unfocus(); return true end
    if self.seedEntry:isFocused() then self.seedEntry:unfocus(); return true end
    self:back()
    return true
end

-- Return goes on; the arrow keys walk the towns
function ZeD_MMSpawn:keyOther(key)
    if key == Keyboard.KEY_RETURN and self._enterAt and MM.now() - self._enterAt < 400 then return true end
    if self.nameEntry:isFocused() or self.seedEntry:isFocused() then
        if key == Keyboard.KEY_RETURN then self.nameEntry:unfocus(); self.seedEntry:unfocus(); return true end
        return false
    end
    if key == Keyboard.KEY_RETURN then self:next(); return true end
    if key == Keyboard.KEY_UP or key == Keyboard.KEY_DOWN then
        self.focusId = "town:" .. self.sel
        self:joyDir(key == Keyboard.KEY_UP and "up" or "down")
        return true
    end
    return false
end

function ZeD_MMSpawn:close() self:back() end

-- the wheel zooms the map under the pointer, or scrolls the towns
function ZeD_MMSpawn:wheel(del)
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    local m = self._map
    local v = vanilla()
    local mp = v and v.mapPanel
    if m and mp and mp.parent == self and mx >= m.x and mx < m.x + m.w and my >= m.y and my < m.y + m.h then
        if mp.hasResetView then mp.mapAPI:zoomAt(mx - m.x, my - m.y, del) end
        return true
    end
    local l = self._list
    if l and mx >= l.x and mx <= l.x + l.w and my >= l.y and my <= l.y + l.h then
        self.scroll = self.scroll + del * ZeD.T.px(ROW_H)
        return true
    end
    local d = self._desc
    if d and d.over and mx >= d.x and mx <= d.x + d.w and my >= d.y and my <= d.y + d.h then
        self.descScroll = (self.descScroll or 0) + del * ZeD.T.px(ROW_H)
        return true
    end
    return false
end
function ZeD_MMSpawn:onMouseWheel(del) return MM.wheel(del) end

local _wheel = MM.wheel
function MM.wheel(del)
    if MM.view == "spawn" and MM.root and MM.root.spawnWin then return MM.root.spawnWin:wheel(del) end
    return _wheel(del)
end

-- on the desk as the "spawn" view; vanilla's MapSpawnSelect:setVisible(true) lands here
MM.addView("spawn", "spawnWin", function() return ZeD_MMSpawn:new() end, "mapSpawnSelect")
