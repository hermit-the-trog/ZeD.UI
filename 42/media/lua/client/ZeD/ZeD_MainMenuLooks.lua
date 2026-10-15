-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuLooks.lua
-- ============================================================================
-- THE CHARACTER'S LOOKS ON THE MONITOR (HOOK_MAP row 26; director, Oct 14
-- 2026: menus delegated, no mockups)
--
-- The last step of a new character, as a ZeD window in place of vanilla's
-- CharacterCreationMain, built on the Options window's rows. Vanilla's screen
-- stays built and hidden as the engine: its controls and handlers keep every
-- rule (names re-rolled with the sex, beards for men only, clothing choices
-- from the occupation and traits, tints and fabric types only where the item
-- has them), its saved outfits file is used as it is, and its PLAY starts the
-- game. Its setVisible(true) is redirected here.
--
--   left   vanilla's own 3D figure, moved into the window: turn it with the
--          arrows (or drag it, or LB / RB), Idle / Walk / Run under it
--   right  NAME (forename, surname, sex), BODY (skin as swatches, chest hair),
--          HAIR (style, colour as swatches, stubble), BEARD, VOICE (type, pitch,
--          a preview), CLOTHING (each slot: its item, its tint, its fabric type)
--   strip  BACK | OUTFITS..., RANDOM | PLAY
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_MainMenuOptions"
require "OptionScreens/CharacterCreationMain"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui

-- design units
local FIGURE_SHARE = 0.34
local SW, SW_GAP = 22, 6          -- a colour swatch and the gap between swatches
local TEX_W, TINT_W = 96, 28      -- a clothing row's fabric list box and tint swatch
local ROW_H = 32

local function ms() return MainScreen and MainScreen.instance end
local function looks() local m = ms(); return m and m.charCreationMain end
local function desc() local m = ms(); return m and m.desc end
local MARK = string.char(171)

local function comboText(c, i) local ok, t = pcall(function() return c:getOptionText(i) end); return ok and tostring(t or "") or "" end
local function label(key) return (tostring(getText(key) or ""):gsub(":%s*$", "")) end

-- the clothing slots top to bottom; any other slot follows by name
local SLOT_ORDER = { "Hat", "FullHat", "Mask", "MaskEyes", "Eyes", "LeftEye", "RightEye", "Ears", "Neck", "Necklace", "Scarf",
                     "Jacket", "JacketHat", "FullSuit", "FullSuitHead", "Dress", "Sweater", "SweaterHat", "Shirt", "ShortSleeveShirt",
                     "TankTop", "Tshirt", "Hands", "Belt", "BeltExtra", "Pants", "ShortPants", "Skirt", "Legs1", "Socks", "Shoes" }
local SLOT_RANK = {}
for i, s in ipairs(SLOT_ORDER) do SLOT_RANK[s] = i end

-- vanilla's hair colours (the same desaturated list its picker shows)
local function hairColors()
    local d = desc()
    local out = {}
    if not d then return out end
    local list = d:getCommonHairColor()
    local info = ColorInfo.new()
    for i = 1, list:size() do
        local c = list:get(i - 1)
        info:set(c:getRedFloat(), c:getGreenFloat(), c:getBlueFloat(), 1)
        out[#out + 1] = { r = info:getR(), g = info:getG(), b = info:getB() }
    end
    return out
end

local function nearest(colors, r, g, b)
    local best, bestD = nil, 1e9
    for i, c in ipairs(colors) do
        local dd = (c.r - r) ^ 2 + (c.g - g) ^ 2 + (c.b - b) ^ 2
        if dd < bestD then best, bestD = i, dd end
    end
    if bestD < 0.004 then return best end
    return nil
end

-- ============================================================================
ZeD_MMLooks = ZeD_MMOptions:derive("ZeD_MMLooks")

function ZeD_MMLooks:new()
    local o = ZeD_MMWindow.new(self, "looks")
    o.inGame = false
    o.noResetControl = true
    o.noHelpBand = true
    o.pageIdx = 1
    o.scroll = 0
    o.confirm = false     -- false | "save" | "delete"
    o.snap = {}
    o.ctx = { hot = nil, press = nil, wasDown = false }
    return o
end

function ZeD_MMLooks:createChildren()
    ZeD_MMOptions.createChildren(self)          -- Find (unused here) and the strip's field
    self.find:setVisible(false)
    self.field.onCommandEntered = function() self._enterAt = MM.now(); self:saveOutfit() end
    -- the two names, kept in step with vanilla's own fields
    self.fore = UI.newEntry(self)
    self.sur = UI.newEntry(self)
    for _, e in ipairs({ self.fore, self.sur }) do
        e:setVisible(false)
        e.onCommandEntered = function() self._enterAt = MM.now(); e:unfocus() end
    end
end

function ZeD_MMLooks:onShow()
    local v = looks()
    self.confirm = false
    self.field:setVisible(false)
    self.scroll = 0
    self.focusId = nil
    if not v then return end
    -- what vanilla's setVisible(true) does: dress for the occupation and traits, clothing lists
    if desc() then
        pcall(function() v:randomGenericOutfit() end)
        pcall(function() v:checkAllClothingOptions() end)
    end
    -- vanilla's 3D figure moves in here
    local model = v.avatarPanel and v.avatarPanel.avatarPanel
    if model and model.parent ~= self then self:addChild(model) end
    self._model = model
end

-- the names: our fields follow vanilla's (a new sex or RANDOM re-rolls them) unless typed in
function ZeD_MMLooks:syncNames()
    local v = looks()
    if not v then return end
    for _, pair in ipairs({ { self.fore, v.forenameEntry }, { self.sur, v.surnameEntry } }) do
        local ours, theirs = pair[1], pair[2]
        if ours:isFocused() then
            if ours:getText() ~= theirs:getText() then theirs:setText(ours:getText()) end
        elseif ours:getText() ~= theirs:getText() then
            ours:setText(theirs:getText())
        end
    end
end

-- ROWS -----------------------------------------------------------------------------
function ZeD_MMLooks:rowsNow()
    local v = looks()
    local d = desc()
    local rows = {}
    if not v or not d then return rows end
    local male = not d:isFemale()
    local function head(t) rows[#rows + 1] = { kind = "header", text = t } end
    head("Name")
    rows[#rows + 1] = { kind = "name", label = label("UI_characreation_forename"), entry = self.fore, key = "fore" }
    rows[#rows + 1] = { kind = "name", label = label("UI_characreation_surname"), entry = self.sur, key = "sur" }
    rows[#rows + 1] = { kind = "combo", label = "Sex", control = v.genderCombo }
    head(label("UI_characreation_body"))
    rows[#rows + 1] = { kind = "swatch", label = label("UI_SkinColor"), colors = v.skinColors or {}, cur = v.skinColor, key = "skin",
        pick = function(i) v.colorPickerSkin.index = i; v:onSkinColorPicked(v.skinColors[i], true) end }
    if male then rows[#rows + 1] = { kind = "tick", label = label("UI_ChestHair"), control = v.chestHairTickBox } end
    head(label("UI_characreation_hair"))
    rows[#rows + 1] = { kind = "combo", label = label("UI_characreation_hairtype"), control = v.hairTypeCombo }
    local hc = hairColors()
    local cur = d:getHumanVisual():getHairColor()
    rows[#rows + 1] = { kind = "swatch", label = label("UI_characreation_color"), colors = hc, key = "hair",
        cur = cur and nearest(hc, cur:getRedFloat(), cur:getGreenFloat(), cur:getBlueFloat()) or nil,
        pick = function(i) v:onHairColorPicked(hc[i], true) end }
    rows[#rows + 1] = { kind = "tick", label = label("UI_Stubble"), control = v.hairStubbleTickBox }
    if male then
        head(label("UI_characreation_beard"))
        rows[#rows + 1] = { kind = "combo", label = label("UI_characreation_beardtype"), control = v.beardTypeCombo }
        rows[#rows + 1] = { kind = "tick", label = label("UI_Stubble"), control = v.beardStubbleTickBox }
    end
    head(label("UI_characreation_voice"))
    rows[#rows + 1] = { kind = "combo", label = label("UI_characreation_voicetype"), control = v.voiceTypeCombo }
    rows[#rows + 1] = { kind = "slider", label = label("UI_characreation_voicepitch"), control = v.voicePitchSlider }
    rows[#rows + 1] = { kind = "button", label = "", control = v.voiceDemoButton }
    head(label("UI_characreation_clothing"))
    if v.outfitCombo then rows[#rows + 1] = { kind = "combo", label = "Outfit", control = v.outfitCombo } end
    local slots = {}
    for loc, combo in pairs(v.clothingCombo or {}) do
        local lbl = v.clothingComboLabel and v.clothingComboLabel[loc]
        slots[#slots + 1] = { loc = loc, combo = combo, text = lbl and lbl:getName() or tostring(loc) }
    end
    table.sort(slots, function(a, b)
        local ra, rb = SLOT_RANK[a.loc] or 999, SLOT_RANK[b.loc] or 999
        if ra ~= rb then return ra < rb end
        return a.text < b.text
    end)
    for _, s in ipairs(slots) do
        rows[#rows + 1] = { kind = "cloth", label = s.text, loc = s.loc, control = s.combo,
            tint = v.clothingColorBtn and v.clothingColorBtn[s.loc], tex = v.clothingTextureCombo and v.clothingTextureCombo[s.loc] }
    end
    return rows
end

function ZeD_MMLooks:isChanged(r) return false end
function ZeD_MMLooks:anyChanged() return false end
function ZeD_MMLooks:snapshot() end

-- a swatch row is as tall as its lines of swatches
function ZeD_MMLooks:rowHeight(r, cw)
    local T = ZeD.T
    if r.kind == "swatch" then
        local per = math.max(1, math.floor((cw + T.px(SW_GAP)) / (T.px(SW) + T.px(SW_GAP))))
        per = math.min(per, 10)
        local lines = math.max(1, math.ceil(#r.colors / per))
        return math.max(T.px(ROW_H), lines * (T.px(SW) + T.px(SW_GAP)) + T.px(10))
    end
    return ZeD_MMOptions.rowHeight(self, r, cw)
end

-- a list box drawn in a given width (the clothing rows split theirs)
function ZeD_MMLooks:drawBox(c, x, y, w, h, id, clip, pickRow)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local hot = MM.ctx.hot == self.kind .. ":" .. id
    local s = hot and T.surf3 or T.surf2
    local bs, tc, f2 = T.borderS, T.text, T.fontF2
    self:drawRect(x, y, w, h, 1, s.r, s.g, s.b)
    self:drawRectBorder(x, y, w, h, bs.a, bs.r, bs.g, bs.b)
    self:drawText(ZeD.Atoms.truncateText(comboText(c, c.selected), f2, w - T.px(28)), x + T.px(8), y + math.floor((h - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
    ZeD.Atoms.drawTriangleDown(self, x + w - T.px(16), y + math.floor((h - T.px(5)) / 2), T.px(8), T.textDim)
    local top, bot = math.max(y, clip.y), math.min(y + h, clip.y + clip.h)
    if bot > top then
        self._hits[#self._hits + 1] = { id = self.kind .. ":" .. id, x = ax + x, y = ay + top, w = w, h = bot - top, sound = true,
            fn = function() self:openCombo({ control = c }, { x = ax + x, y = ay + y, w = w, h = h }) end }
    end
end

function ZeD_MMLooks:drawControl(r, cx, ry, cw, rh, rowId, clip)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local midY = ry + math.floor(rh / 2)
    local inView = ry >= clip.y and ry + rh <= clip.y + clip.h
    if r.kind == "name" then
        local fh = T.px(24)
        local e = r.entry
        if inView then
            UI.styleEntry(e, cx, midY - math.floor(fh / 2), math.min(cw, T.px(280)), fh)
            if not e:isVisible() then e:setVisible(true) end
            self._shown[e] = true
            self._hits[#self._hits + 1] = { id = self.kind .. ":" .. rowId .. ":name", x = ax + e.x, y = ay + e.y, w = e.width, h = e.height, fn = function() e:focus() end }
        end
        return
    elseif r.kind == "swatch" then
        local s, g = T.px(SW), T.px(SW_GAP)
        local per = math.min(10, math.max(1, math.floor((cw + g) / (s + g))))
        local bs = T.borderS
        local y0 = ry + T.px(6)
        for i, c in ipairs(r.colors) do
            local col, line = (i - 1) % per, math.floor((i - 1) / per)
            local x = cx + col * (s + g)
            local y = y0 + line * (s + g)
            local id = rowId .. ":sw" .. i
            self:drawRect(x, y, s, s, 1, c.r, c.g, c.b)
            self:drawRectBorder(x, y, s, s, bs.a, bs.r, bs.g, bs.b)
            if i == r.cur or MM.ctx.hot == self.kind .. ":" .. id then
                local tc = T.text
                self:drawRectBorder(x - T.px(2), y - T.px(2), s + T.px(4), s + T.px(4), 1, tc.r, tc.g, tc.b)
                if i == r.cur then self:drawRectBorder(x - T.px(3), y - T.px(3), s + T.px(6), s + T.px(6), 1, tc.r, tc.g, tc.b) end
            end
            local top, bot = math.max(y, clip.y), math.min(y + s, clip.y + clip.h)
            if bot > top then
                self._hits[#self._hits + 1] = { id = self.kind .. ":" .. id, x = ax + x, y = ay + top, w = s, h = bot - top, sound = true,
                    fn = function() r.pick(i); MM.clickSound() end }
            end
        end
        return
    elseif r.kind == "cloth" then
        local bh = T.px(24)
        local by = midY - math.floor(bh / 2)
        local tint = r.tint and r.tint:isVisible()
        local tex = r.tex and r.tex:isVisible() and #(r.tex.options or {}) > 1
        local right = 0
        if tint then right = right + T.px(TINT_W) + T.px(8) end
        if tex then right = right + T.px(TEX_W) + T.px(8) end
        local iw = math.max(T.px(80), math.min(T.px(280), cw) - right)
        self:drawBox(r.control, cx, by, iw, bh, rowId .. ":item", clip)
        local x = cx + iw + T.px(8)
        if tint then
            local b = r.tint.backgroundColor or { r = 1, g = 1, b = 1 }
            local bs = T.borderS
            local sw = T.px(TINT_W)
            self:drawRect(x, by, sw, bh, 1, b.r or 1, b.g or 1, b.b or 1)
            self:drawRectBorder(x, by, sw, bh, bs.a, bs.r, bs.g, bs.b)
            local id = rowId .. ":tint"
            if MM.ctx.hot == self.kind .. ":" .. id then
                local ac = T.accent
                self:drawRectBorder(x - T.px(2), by - T.px(2), sw + T.px(4), bh + T.px(4), 1, ac.r, ac.g, ac.b)
            end
            local top, bot = math.max(by, clip.y), math.min(by + bh, clip.y + clip.h)
            local loc, btn = r.loc, r.tint
            if bot > top then
                self._hits[#self._hits + 1] = { id = self.kind .. ":" .. id, x = ax + x, y = ay + top, w = sw, h = bot - top, sound = true,
                    fn = function() self:openPalette({ control = btn, onColor = function(col) looks():onClothingColorPicked(col, true, loc) end },
                                                     { x = ax + x, y = ay + by, w = sw, h = bh }) end }
            end
            x = x + sw + T.px(8)
        end
        if tex then self:drawBox(r.tex, x, by, T.px(TEX_W), bh, rowId .. ":tex", clip) end
        return
    end
    ZeD_MMOptions.drawControl(self, r, cx, ry, cw, rh, rowId, clip)
end

-- the palette's pick: a clothing tint
function ZeD_MMLooks:pickColor(col)
    local p = self._palette
    self._palette = nil
    if p and p.row and p.row.onColor then p.row.onColor(col) end
    MM.clickSound()
end

-- THE FIGURE ---------------------------------------------------------------------------
local ANIMS = { { "IGUI_anim_Idle", "EventIdle" }, { "IGUI_anim_Walk", "EventWalk" }, { "IGUI_anim_Run", "EventRun" } }

function ZeD_MMLooks:turn(dir)
    local m = self._model
    if not m then return end
    local d = m:getDirection()
    if dir < 0 then m:setDirection(d:RotRight()) else m:setDirection(d:RotLeft()) end
end

function ZeD_MMLooks:pose(i)
    local m = self._model
    local a = ANIMS[i]
    if not m or not a then return end
    self.anim = i
    m:setState(nil)
    m:reportEvent(a[2])
end

function ZeD_MMLooks:drawFigure(x, y, w, h)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local bh = T.px(U.STRIP_BTN_H)
    local boxH = h - bh - T.px(10)
    UI.insetBox(self, x, y, w, boxH)
    local m = self._model
    if m and m.parent == self then
        -- the figure keeps vanilla's 1 : 2 frame, centred in the box
        local mh = boxH - T.px(12)
        local mw = math.min(w - T.px(12), math.floor(mh / 2))
        local mx, my = x + math.floor((w - mw) / 2), y + T.px(6)
        if m.x ~= mx or m.y ~= my then m:setX(mx); m:setY(my) end
        if m.width ~= mw or m.height ~= mh then m:setWidth(mw); m:setHeight(mh) end
        -- dragging across the figure turns it, a step per stretch of the drag
        self._hits[#self._hits + 1] = { id = "looks:figure", x = ax + x, y = ay + y, w = w, h = boxH, drag = function(mxx)
            local last = self._dragX
            if not last then self._dragX = mxx; return end
            local step = T.px(40)
            if mxx - last >= step then self:turn(1); self._dragX = mxx
            elseif last - mxx >= step then self:turn(-1); self._dragX = mxx end
        end }
    end
    -- under it: turn left, the pose, turn right
    local by = y + boxH + T.px(10)
    local f3 = T.fontF3
    local bw = T.px(36)
    local function btn(id, text, bx, bwid, fn)
        local b = { id = id, text = text, x = bx, y = by, w = bwid, h = bh, fn = fn, variant = "default", row = 900, col = (id == "turnL") and 1 or ((id == "pose") and 2 or 3) }
        self._specs[#self._specs + 1] = b
    end
    btn("turnL", "<", x, bw, function() self:turn(-1) end)
    btn("turnR", ">", x + w - bw, bw, function() self:turn(1) end)
    local pw = w - bw * 2 - T.px(16)
    local cur = ANIMS[self.anim or 1]
    btn("pose", string.upper(getText(cur[1])), x + bw + T.px(8), pw, function()
        local items = {}
        for i, a in ipairs(ANIMS) do
            local t = getText(a[1])
            if i == (self.anim or 1) then t = t .. "  " .. MARK end
            items[#items + 1] = { text = t, fn = function() self:pose(i) end }
        end
        MM.openPopup("pose", items, { x = ax + x + bw + T.px(8), y = ay + by, w = pw, h = bh }, true)
    end)
end

-- DRAWING ----------------------------------------------------------------------------
function ZeD_MMLooks:prerender()
    local T = ZeD.T
    self:syncNames()
    if not isMouseButtonDown(0) then self._dragX = nil end
    self._specs, self._hits = {}, {}
    local w, h = UI.placeOnTube(self)
    local v = looks()
    self.title = "Project Zomboid  +  Character"
    local name = (self.fore:getText() or "") .. " " .. (self.sur:getText() or "")
    self.titleStats = { { text = name, color = { r = 0, g = 0, b = 0, a = 0 } } }
    ZeD_Window.prerender(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = T.px(U.STRIP_BTN_H) + T.px(U.STRIP_PAD_Y) * 2
    local stripY = h - self:footerHeight() - stripH
    local bodyY, bodyH = tb + pad, stripY - tb - pad * 2
    local fw = math.floor((w - pad * 3) * FIGURE_SHARE)
    self:drawFigure(pad, bodyY, fw, bodyH)
    self._shown = {}
    self:drawRows(pad * 2 + fw, bodyY, w - pad * 3 - fw, bodyH, self:rowsNow(), nil, false)
    -- a name field whose row is out of view hides
    for _, e in ipairs({ self.fore, self.sur }) do
        if not self._shown[e] and e:isVisible() then
            if e:isFocused() then e:unfocus() end
            e:setVisible(false)
        end
    end
    self:buildStrip(stripY, stripH, w)
end

-- SAVED OUTFITS (vanilla's file) --------------------------------------------------------
function ZeD_MMLooks:outfitItems()
    local v = looks()
    local t = {}
    if not v then return t end
    local cur = v.savedBuilds.options[v.savedBuilds.selected]
    for i, n in ipairs(v.savedBuilds.options) do
        local text = tostring(n)
        if n == cur then text = text .. "  " .. MARK end
        t[#t + 1] = { text = text, fn = function() self:loadOutfit(i) end }
    end
    if #t > 0 then t[#t + 1] = "-" end
    t[#t + 1] = { text = "Save Outfit...", fn = function() self:setConfirm("save") end }
    if cur then t[#t + 1] = { text = "Delete " .. tostring(cur) .. "...", fn = function() self:setConfirm("delete") end } end
    return t
end

function ZeD_MMLooks:openOutfits()
    for _, b in ipairs(self._specs) do
        if b.id == "outfits" then
            MM.openPopup("outfits", self:outfitItems(), { x = self:getAbsoluteX() + b.x, y = self:getAbsoluteY() + b.y, w = b.w, h = b.h }, true)
            return
        end
    end
end

function ZeD_MMLooks:loadOutfit(i)
    local v = looks()
    if not v then return end
    MM.clickSound()
    v.savedBuilds.selected = i
    v:loadOutfit(v.savedBuilds)
end

function ZeD_MMLooks:saveOutfit()
    local v = looks()
    local name = self.field:getText() or ""
    if not v or not v:saveBuildValidate(name) then return end
    v:saveBuildStep2({ internal = "OK", parent = { entry = { getText = function() return name end } } }, nil)
    self:setConfirm(false)
    MM.clickSound()
end

-- the outfit goes from the file; the character on screen stays (vanilla loaded another)
function ZeD_MMLooks:deleteOutfit()
    local v = looks()
    local cur = v and v.savedBuilds.options[v.savedBuilds.selected]
    if cur then
        local builds = CharacterCreationMain.readSavedOutfitFile()
        builds[cur] = nil
        CharacterCreationMain.writeSaveFile(builds)
        local names = {}
        for k, _ in pairs(builds) do names[#names + 1] = k end
        table.sort(names)
        v.savedBuilds.options = names
        v.savedBuilds.selected = 0
    end
    self:setConfirm(false)
end

function ZeD_MMLooks:commitText() if self.confirm == "save" then self:saveOutfit() end end

function ZeD_MMLooks:setConfirm(mode)
    if self.confirm == mode then return end
    self.confirm = mode
    MM.ctx.open = nil
    if mode == "save" then
        local v = looks()
        local text = v and v.savedBuilds.options[v.savedBuilds.selected] or nil
        if not text then text = ((self.fore:getText() or "") .. " " .. (self.sur:getText() or "")):gsub("^%s+", ""):gsub("%s+$", "") end
        if text == "" then text = "Preset" end
        self.field:setText(tostring(text))
        self.field:setVisible(true)
        self.field:focus()
    else
        self.field:setVisible(false)
        if self.field:isFocused() then self.field:unfocus() end
    end
    self.focusId = mode and "confirm:yes" or self.focusId
end

-- THE STRIP + LEAVING ----------------------------------------------------------------------
function ZeD_MMLooks:random()
    local v = looks()
    if not v then return end
    MM.clickSound()
    v:onOptionMouseDown({ internal = "RANDOM" }, 0, 0)
end

function ZeD_MMLooks:play()
    local v = looks()
    if not v then return end
    self:syncNames()
    MM.clickSound()
    MM.toVanilla()
    v:onOptionMouseDown({ internal = "NEXT" }, 0, 0)
end

function ZeD_MMLooks:back()
    local v = looks()
    MM.clickSound()
    if not v then MM.showView("newgame"); return end
    self:syncNames()
    MM.toVanilla()
    v:onOptionMouseDown({ internal = "BACK" }, 0, 0)
end

function ZeD_MMLooks:buildStrip(stripY, stripH, w)
    local T = ZeD.T
    local row = 1000
    local ask = nil
    if self.confirm == "save" then
        ask = "Outfit name:"
        local v = looks()
        local valid = v and v:saveBuildValidate(self.field:getText() or "") or false
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", "CANCEL", function() self:setConfirm(false) end },
            { "confirm:yes", "SAVE", function() self:saveOutfit() end, "primary", not valid } })
        local f2 = T.fontF2
        local fx = T.px(U.STRIP_PAD_X) + T.px(4) + MM.textW(f2, ask) + T.px(10)
        local firstBtn = w
        for _, b in ipairs(self._specs) do if b.row == row then firstBtn = math.min(firstBtn, b.x) end end
        local fh = T.px(24)
        UI.styleEntry(self.field, fx, stripY + math.floor((stripH - fh) / 2), math.max(T.px(80), firstBtn - T.px(12) - fx), fh)
    elseif self.confirm == "delete" then
        local v = looks()
        ask = "Delete the outfit " .. tostring(v and v.savedBuilds.options[v.savedBuilds.selected] or "") .. "?"
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", "CANCEL", function() self:setConfirm(false) end },
            { "confirm:yes", "DELETE", function() self:deleteOutfit() end, "danger" } })
    else
        UI.stripSpecs(self, stripY, w, row,
            { { "back", "BACK", function() self:back() end } },
            { { "outfits", "OUTFITS...", function() self:openOutfits() end },
              { "random", "RANDOM", function() self:random() end },
              { "play", string.upper(getText("UI_btn_play")), function() self:play() end, "primary" } })
    end
    self._stripY, self._stripH, self._ask = stripY, stripH, ask
end

-- ROWS ON A CONTROLLER ---------------------------------------------------------------------
function ZeD_MMLooks:activateRow(r)
    local T = ZeD.T
    local anchor = { x = self:getAbsoluteX() + self.width / 2, y = self:getAbsoluteY() + self.height / 3, w = T.px(280), h = T.px(24) }
    if r.kind == "name" then
        local jd = MM.gamepad() and JoypadState and JoypadState.getMainMenuJoypad and JoypadState.getMainMenuJoypad()
        if jd and OnScreenKeyboard and OnScreenKeyboard.Show then
            local osk = OnScreenKeyboard.Show(jd.player or 0, r.entry, jd)
            if osk then osk.prevFocus = jd.focus; jd.focus = osk; updateJoypadFocus(jd); return end
        end
        r.entry:focus()
    elseif r.kind == "swatch" then
        local i = r.cur or 1
        if r.colors[i] then r.pick(i) end
    elseif r.kind == "cloth" then
        self:openCombo({ control = r.control }, anchor)
    else
        ZeD_MMOptions.activateRow(self, r)
    end
end

function ZeD_MMLooks:nudge(r, dir)
    if r.kind == "swatch" then
        local i = math.max(1, math.min(#r.colors, (r.cur or 1) + dir))
        if r.colors[i] and i ~= r.cur then r.pick(i); MM.hoverSound() end
        return true
    elseif r.kind == "cloth" then
        local c = r.control
        local n = #(c.options or {})
        local i = math.max(1, math.min(n, (c.selected or 1) + dir))
        if i ~= c.selected then c.selected = i; c.onChange(c.target, c, c.onChangeArgs and c.onChangeArgs[1], c.onChangeArgs and c.onChangeArgs[2]); MM.hoverSound() end
        return true
    elseif r.kind == "name" then
        return false
    end
    return ZeD_MMOptions.nudge(self, r, dir)
end

function ZeD_MMLooks:joyBumper(dir) self:turn(dir) end
function ZeD_MMLooks:joyB()
    if self._palette then self._palette = nil; return end
    if self.confirm then self:setConfirm(false); return end
    self:back()
end
function ZeD_MMLooks:joyX() if not self.confirm then self:random() end end
function ZeD_MMLooks:joyY() if not self.confirm then self:openOutfits() end end

function ZeD_MMLooks:getFooterPrompts()
    if not MM.gamepad() then return nil end
    if self.confirm then return { { glyph = "A", label = "Select" }, { glyph = "B", label = "Cancel" } } end
    local t = {}
    local r = self:focusedRow()
    if r and (r.kind == "combo" or r.kind == "cloth" or r.kind == "swatch" or r.kind == "slider") then t[#t + 1] = { glyph = "<>", label = "Change" } end
    t[#t + 1] = { glyph = "A", label = "Select" }
    t[#t + 1] = { glyph = "LB", label = "" }
    t[#t + 1] = { glyph = "RB", label = "Turn" }
    t[#t + 1] = { glyph = "X", label = "Random" }
    t[#t + 1] = { glyph = "Y", label = "Outfits" }
    t[#t + 1] = { glyph = "B", label = "Back" }
    return t
end

function ZeD_MMLooks:keyEscape()
    if self._palette then self._palette = nil; return true end
    if self.confirm then self:setConfirm(false); return true end
    if self.fore:isFocused() then self.fore:unfocus(); return true end
    if self.sur:isFocused() then self.sur:unfocus(); return true end
    self:back()
    return true
end

function ZeD_MMLooks:keyOther(key)
    if key == Keyboard.KEY_RETURN and self._enterAt and MM.now() - self._enterAt < 400 then return true end
    if self.field:isFocused() or self.fore:isFocused() or self.sur:isFocused() or self.confirm then return false end
    if key == Keyboard.KEY_RETURN then self:play(); return true end
    if key == Keyboard.KEY_LEFT then self:turn(-1); return true end
    if key == Keyboard.KEY_RIGHT then self:turn(1); return true end
    return false
end

function ZeD_MMLooks:close() self:back() end

local _wheel = MM.wheel
function MM.wheel(del)
    if MM.view == "looks" and MM.root and MM.root.looksWin then
        if MM.dropWheel and MM.dropWheel(del) then return true end
        return MM.root.looksWin:wheel(del)
    end
    return _wheel(del)
end

-- on the desk as the "looks" view; vanilla's charCreationMain:setVisible(true) lands here
MM.addView("looks", "looksWin", function() return ZeD_MMLooks:new() end, "charCreationMain")
