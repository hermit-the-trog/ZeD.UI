-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuTraits.lua
-- ============================================================================
-- OCCUPATION AND TRAITS ON THE MONITOR (HOOK_MAP row 26; director, Oct 14
-- 2026: menus delegated, no mockups)
--
-- A ZeD window in place of vanilla's CharacterCreationProfession. Vanilla's
-- screen stays built and hidden as the engine: its lists hold the occupations
-- and traits, its onSelectProf / addTrait / removeTrait keep every rule (free
-- traits from the occupation, traits that exclude each other, the points with
-- the sandbox's free points and negative-trait penalty), checkXPBoost gives
-- the starting skills, its builds file and randomizer are used as they are,
-- and its NEXT / BACK run as vanilla. Its setVisible(true) is redirected here.
--
--   column 1  occupations: picture, name, the points it gives
--   column 2  traits to take: POSITIVE, then NEGATIVE; one click takes one
--   column 3  CHOSEN traits (one click gives one back; the occupation's own
--             are marked Free), then STARTING SKILLS: a ten-cell bar, the
--             level, the XP boost
--   band      what the occupation or trait under the pointer does
--   title     the points left (a red dot when overspent: NEXT waits)
--   strip     BACK | BUILDS..., RANDOM, CLEAR TRAITS | NEXT
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "OptionScreens/CharacterCreationProfession"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui

-- design units
local HEAD_H, PROF_H, TRAIT_H, SKILL_H = 26, 44, 30, 26
local PROF_PIC_W, PROF_PIC_H, TRAIT_ICON = 42, 30, 18
local HELP_H = 54
local SHARE = { 0.34, 0.31, 0.35 }

local function ms() return MainScreen and MainScreen.instance end
local function prof() local m = ms(); return m and m.charCreationProfession end

local function signed(n)
    n = tonumber(n) or 0
    if n > 0 then return "+" .. n end
    return tostring(n)
end

-- a description's lines, plain (vanilla's tooltips use "\n" between facts)
local function helpLines(text, font, w)
    local out = {}
    for line in (tostring(text or "") .. "\n"):gmatch("([^\n]*)\n") do
        local p = UI.plain(line)
        if p ~= "" then
            for _, l in ipairs(ZeD.Atoms.wrapText(p, font, w)) do out[#out + 1] = l end
        end
    end
    return out
end

-- ============================================================================
ZeD_MMTraits = ZeD_MMWindow:derive("ZeD_MMTraits")

function ZeD_MMTraits:new()
    local o = ZeD_MMWindow.new(self, "traits")
    o.noResetControl = true
    o.scroll = { 0, 0, 0 }
    o.jcol, o.jidx = 1, 1
    o.confirm = false      -- false | "save" | "delete"
    return o
end

function ZeD_MMTraits:createChildren()
    ZeD_Window.createChildren(self)
    self.field = UI.newEntry(self)
    self.field:setVisible(false)
    self.field.onCommandEntered = function() self._enterAt = MM.now(); self:saveBuild() end
    self.field.onEscape = function() self:setConfirm(false) end
end

function ZeD_MMTraits:onShow()
    self.confirm = false
    self.field:setVisible(false)
    self.scroll = { 0, 0, 0 }
    self.jcol, self.jidx = 1, 1
    local p = prof()
    if p and p.listboxProf then self.jidx = math.max(1, p.listboxProf.selected or 1) end
    self.focusId = nil
end

-- ACTIONS (vanilla's own calls) ---------------------------------------------------

function ZeD_MMTraits:pickProf(i)
    local p = prof()
    if not p or not p.listboxProf.items[i] then return end
    if p.listboxProf.selected ~= i then MM.clickSound() end
    p.listboxProf.selected = i
    p:onSelectProf(p.listboxProf.items[i].item)
end

function ZeD_MMTraits:takeTrait(trait)
    local p = prof()
    if not p then return end
    MM.clickSound()
    p:addTrait(trait)
    p:checkXPBoost()
end

function ZeD_MMTraits:giveBack(i)
    local p = prof()
    local it = p and p.listboxTraitSelected.items[i]
    if not it or it.item:isFree() then return end
    MM.clickSound()
    p:removeTrait(i)
    p:checkXPBoost()
end

function ZeD_MMTraits:random()
    local p = prof()
    if not p then return end
    MM.clickSound()
    p:randomizeTraits()
    self.scroll = { 0, 0, 0 }
end

function ZeD_MMTraits:clearTraits()
    local p = prof()
    if not p then return end
    MM.clickSound()
    p:resetTraits()
end

function ZeD_MMTraits:next()
    local p = prof()
    if not p or p:PointToSpend() < 0 then return end
    MM.clickSound()
    MM.toVanilla()
    p:onOptionMouseDown({ internal = "NEXT" }, 0, 0)
end

function ZeD_MMTraits:back()
    local p = prof()
    MM.clickSound()
    if not p or not p.previousScreen then MM.showView("newgame"); return end
    MM.toVanilla()
    p:onOptionMouseDown({ internal = "BACK" }, 0, 0)
end

-- BUILDS (vanilla's saved_builds.txt) ------------------------------------------------

function ZeD_MMTraits:buildItems()
    local p = prof()
    local t = {}
    if not p then return t end
    local cur = p.savedBuilds.options[p.savedBuilds.selected]
    for i, name in ipairs(p.savedBuilds.options) do
        local text = tostring(name)
        if name == cur then text = text .. "  " .. string.char(171) end
        t[#t + 1] = { text = text, fn = function() self:loadBuild(i) end }
    end
    if #t > 0 then t[#t + 1] = "-" end
    t[#t + 1] = { text = ZeD.tr("UI_ZeD_Traits_SaveBuild"), fn = function() self:setConfirm("save") end }
    if cur then t[#t + 1] = { text = ZeD.tr("UI_ZeD_Traits_DeleteBuild", tostring(cur)), fn = function() self:setConfirm("delete") end } end
    return t
end

function ZeD_MMTraits:openBuilds()
    for _, b in ipairs(self._specs) do
        if b.id == "builds" then
            MM.openPopup("builds", self:buildItems(), { x = self:getAbsoluteX() + b.x, y = self:getAbsoluteY() + b.y, w = b.w, h = b.h }, true)
            return
        end
    end
end

function ZeD_MMTraits:loadBuild(i)
    local p = prof()
    if not p then return end
    MM.clickSound()
    p.savedBuilds.selected = i
    CharacterCreationProfession.loadBuild(p, p.savedBuilds)
    self.scroll = { 0, 0, 0 }
end

-- vanilla's saveBuildStep2 with the name from the strip's field (its name rules)
function ZeD_MMTraits:saveBuild()
    local p = prof()
    local name = self.field:getText() or ""
    if not p or not p:saveBuildValidate(name) then return end
    p:saveBuildStep2({ internal = "OK", parent = { entry = { getText = function() return name end } } }, nil)
    self:setConfirm(false)
    MM.clickSound()
end

-- the build goes from the file; the traits on screen stay (vanilla loaded another build)
function ZeD_MMTraits:deleteBuild()
    local p = prof()
    local cur = p and p.savedBuilds.options[p.savedBuilds.selected]
    if cur then
        local builds = BCRC.readSaveFile()
        builds[cur] = nil
        BCRC.writeSaveFile(builds)
        local names = {}
        for k, _ in pairs(builds) do names[#names + 1] = k end
        table.sort(names)
        p.savedBuilds.options = names
        p.savedBuilds.selected = 0
    end
    self:setConfirm(false)
end

function ZeD_MMTraits:setConfirm(mode)
    if self.confirm == mode then return end
    self.confirm = mode
    MM.ctx.open = nil
    if mode == "save" then
        local p = prof()
        local text = p and p.savedBuilds.options[p.savedBuilds.selected] or ""
        if text == "" and p then text = p:getSelectedProf():getUIName() end
        self.field:setText(tostring(text))
        self.field:setVisible(true)
        self.field:focus()
    else
        self.field:setVisible(false)
        if self.field:isFocused() then self.field:unfocus() end
    end
    self.focusId = mode and "confirm:yes" or nil
end

-- ============================================================================
-- DRAWING
-- ============================================================================

-- the three columns' rows: { head = text } or { h, draw(x, y, w, h), fn, help, focusable }
function ZeD_MMTraits:columns()
    local p = prof()
    local cols = { {}, {}, {} }
    if not p then return cols end
    local T = ZeD.T
    -- occupations
    for i, it in ipairs(p.listboxProf.items) do
        cols[1][#cols[1] + 1] = { h = T.px(PROF_H), kind = "prof", item = it, index = i, sel = (p.listboxProf.selected == i),
            fn = function() self:pickProf(i) end, help = it.tooltip, focusable = true }
    end
    -- traits to take
    local function traitRows(list, head)
        if #list == 0 then return end
        cols[2][#cols[2] + 1] = { head = head, count = #list }
        for _, it in ipairs(list) do
            local tr = it.item
            cols[2][#cols[2] + 1] = { h = T.px(TRAIT_H), kind = "trait", trait = tr, fn = function() self:takeTrait(tr) end, help = tr:getDescription(), focusable = true }
        end
    end
    traitRows(p.listboxTrait.items, ZeD.tr("UI_ZeD_Traits_HeadPositive"))
    traitRows(p.listboxBadTrait.items, ZeD.tr("UI_ZeD_Traits_HeadNegative"))
    -- chosen, then the starting skills
    local chosen = p.listboxTraitSelected.items
    cols[3][#cols[3] + 1] = { head = ZeD.tr("UI_ZeD_Traits_HeadChosen"), count = #chosen }
    for i, it in ipairs(chosen) do
        local tr = it.item
        local free = tr:isFree()
        cols[3][#cols[3] + 1] = { h = T.px(TRAIT_H), kind = "chosen", trait = tr, free = free,
            fn = (not free) and function() self:giveBack(i) end or nil,
            help = free and (tostring(tr:getDescription() or "") .. "\n" .. ZeD.tr("UI_ZeD_Traits_FromOccupation")) or tr:getDescription(), focusable = not free }
    end
    if #chosen == 0 then cols[3][#cols[3] + 1] = { h = T.px(TRAIT_H), kind = "empty" } end
    cols[3][#cols[3] + 1] = { head = ZeD.tr("UI_ZeD_Traits_HeadSkills") }
    for _, it in ipairs(p.listboxXpBoost.items) do
        cols[3][#cols[3] + 1] = { h = T.px(SKILL_H), kind = "skill", name = it.text, perk = it.item.perk, level = it.item.level }
    end
    return cols
end

function ZeD_MMTraits:prerender()
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    local w, h = UI.placeOnTube(self)
    local p = prof()
    local pts = p and p:PointToSpend() or 0
    self.title = ZeD.tr("UI_ZeD_Traits_Title")
    self.titleStats = { { text = ZeD.tr(math.abs(pts) == 1 and "UI_ZeD_Traits_PointsOne" or "UI_ZeD_Traits_PointsMany", pts), color = (pts >= 0) and T.positive or T.danger } }
    if p and getSandboxOptions():getOptionByName("NegativeTraitsPenalty"):getValue() ~= 1 then
        local off = p:negativeTraitOffset()
        if off > 0 then table.insert(self.titleStats, 1, { text = ZeD.tr("UI_ZeD_Traits_Penalty", off), color = { r = 0, g = 0, b = 0, a = 0 } }) end
    end
    ZeD_Window.prerender(self)

    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = T.px(U.STRIP_BTN_H) + T.px(U.STRIP_PAD_Y) * 2
    local stripY = h - self:footerHeight() - stripH
    local helpH = T.px(HELP_H)
    local bodyY = tb + pad
    local colH = stripY - pad - helpH - pad - bodyY
    local inner = w - pad * 4
    local cols = self:columns()
    self._cols = cols
    self._hover = nil
    local x = pad
    for c = 1, 3 do
        local cw = (c == 3) and (w - pad - x) or math.floor(inner * SHARE[c])
        self:drawColumn(c, x, bodyY, cw, colH, cols[c])
        x = x + cw + pad
    end
    -- a taken / given-back trait shortens its column: the controller's focus stays in range
    local f = self.focusId or ""
    if f:sub(1, 1) == "c" then
        local n = #(self._colFocus[self.jcol] or {})
        if n == 0 then self.focusId = "next"
        elseif self.jidx > n then self.jidx = n; self.focusId = "c" .. self.jcol .. ":" .. n end
    end
    self:drawHelp(pad, bodyY + colH + pad, w - pad * 2, helpH, pts)
    self:buildStrip(stripY, stripH, w, pts)
end

function ZeD_MMTraits:render()
    UI.drawStripAndButtons(self, self._stripY, self._stripH, self._ask)
    ZeD_Window.render(self)
end

-- one column: an inset box of rows that scrolls as one
function ZeD_MMTraits:drawColumn(c, x, y, w, h, rows)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    UI.insetBox(self, x, y, w, h)
    local vy, vh = y + T.px(1), h - T.px(2)
    local total = 0
    for _, r in ipairs(rows) do total = total + (r.head and T.px(HEAD_H) or r.h) end
    local sbW = T.sp.scrollbarW
    local over = total > vh
    local rw = w - T.px(2) - (over and sbW or 0)
    self.scroll[c] = math.max(0, math.min(self.scroll[c] or 0, math.max(0, total - vh)))
    self._colBox = self._colBox or {}
    self._colBox[c] = { x = x, y = vy, w = w, h = vh }
    local gp = MM.gamepad()
    local ac = T.accent
    local mx, my = getMouseX() - ax, getMouseY() - ay
    self:setStencilRect(x + T.px(1), vy, w - T.px(2), vh)
    local ry = vy - self.scroll[c]
    local fi = 0
    self._colFocus = self._colFocus or {}
    self._colFocus[c] = {}
    for _, r in ipairs(rows) do
        local rh = r.head and T.px(HEAD_H) or r.h
        local visible = ry + rh > vy and ry < vy + vh
        if r.head then
            if visible then
                ZeD.Molecules.drawSectionHeader(self, x + T.px(1) + T.px(8), ry, rw - T.px(8), r.text or r.head, r.count, true, false, T.fontF1, false, T.px(8), rh, true)
            end
        else
            local focusable = r.focusable
            local myIdx = nil
            if focusable then
                fi = fi + 1
                myIdx = fi
                self._colFocus[c][fi] = { row = r, ry = ry + self.scroll[c] - vy, rh = rh }
            end
            if visible then
                local isFocus = gp and focusable and self.focusId == ("c" .. c .. ":" .. myIdx)
                local hov = (not gp) and mx >= x and mx < x + rw and my >= math.max(ry, vy) and my < math.min(ry + rh, vy + vh)
                if isFocus then self:drawRect(x + T.px(1), ry, rw, rh, 0.55, ac.r, ac.g, ac.b)
                elseif r.sel then self:drawRect(x + T.px(1), ry, rw, rh, 0.22, ac.r, ac.g, ac.b)
                elseif hov and r.fn then self:drawRect(x + T.px(1), ry, rw, rh, 0.10, ac.r, ac.g, ac.b) end
                self:drawRect(x + T.px(1), ry + rh - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
                self:drawRow(r, x + T.px(1), ry, rw, rh)
                if isFocus or hov then self._hover = r end
                if r.fn then
                    local cy, ch = math.max(ry, vy), math.min(ry + rh, vy + vh) - math.max(ry, vy)
                    self._hits[#self._hits + 1] = { id = "traits:c" .. c .. ":" .. tostring(myIdx or ry), x = ax + x, y = ay + cy, w = rw, h = ch, fn = r.fn }
                end
            end
        end
        ry = ry + rh
    end
    self:clearStencilRect()
    if over then
        local sx = x + w - T.px(1) - sbW
        ZeD.Atoms.drawScrollTrack(self, sx, vy, sbW, vh)
        local th = math.max(T.px(24), math.floor(vh * vh / total))
        local tyy = vy + math.floor((vh - th) * self.scroll[c] / (total - vh))
        local hid = "traits:track" .. c
        ZeD.Atoms.drawScrollThumb(self, sx, tyy, sbW, th, MM.ctx.hot == hid and "hover" or "default")
        self._hits[#self._hits + 1] = { id = hid, x = ax + sx, y = ay + vy, w = sbW, h = vh, drag = function(_, myy)
            self.scroll[c] = math.floor(((myy - ay - vy) / vh) * total - vh / 2) end }
    end
end

-- a row's contents
function ZeD_MMTraits:drawRow(r, x, y, w, h)
    local T = ZeD.T
    local f2, f3 = T.fontF2, T.fontF3
    local tc, d = T.text, T.textDim
    local midY = y + math.floor(h / 2)
    if r.kind == "prof" then
        local pr = r.item.item
        local tex = pr:getTexture()
        local pw, ph = T.px(PROF_PIC_W), T.px(PROF_PIC_H)
        if tex then self:drawTextureScaledAspect(tex, x + T.px(8), midY - math.floor(ph / 2), pw, ph, 1, 1, 1, 1) end
        local cost = signed(pr:getCost())
        local cw = MM.textW(f2, cost)
        self:drawText(cost, x + w - T.px(10) - cw, midY - math.floor(MM.fontH(f2) / 2), d.r, d.g, d.b, d.a or 1, f2)
        local nx = x + T.px(8) + pw + T.px(10)
        local c = r.sel and T.textHead or tc
        self:drawText(ZeD.Atoms.truncateText(tostring(r.item.text), f2, x + w - T.px(20) - cw - nx), nx, midY - math.floor(MM.fontH(f2) / 2), c.r, c.g, c.b, c.a or 1, f2)
    elseif r.kind == "trait" or r.kind == "chosen" then
        local tr = r.trait
        local tex = tr:getTexture()
        local isz = T.px(TRAIT_ICON)
        if tex then self:drawTextureScaledAspect(tex, x + T.px(8), midY - math.floor(isz / 2), isz, isz, 1, 1, 1, 1) end
        -- the cost: points it takes (-) or gives (+); a status dot says which kind of trait
        local right = r.free and getText("IGUI_GameStats_Free") or tostring(tr:getRightLabel() or signed(-tr:getCost()))
        local rw = MM.textW(f2, right)
        local rx = x + w - T.px(10) - rw
        self:drawText(right, rx, midY - math.floor(MM.fontH(f2) / 2), d.r, d.g, d.b, d.a or 1, f2)
        local dsz = T.px(7)
        if tr:getCost() ~= 0 then
            ZeD.Atoms.drawStatusDot(self, rx - T.px(8) - dsz, midY - math.floor(dsz / 2), (tr:getCost() > 0) and T.positive or T.danger, dsz)
        end
        local nx = x + T.px(8) + isz + T.px(8)
        self:drawText(ZeD.Atoms.truncateText(tostring(tr:getLabel()), f2, rx - T.px(20) - dsz - nx), nx, midY - math.floor(MM.fontH(f2) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
    elseif r.kind == "empty" then
        self:drawText(ZeD.tr("UI_ZeD_Traits_NoneYet"), x + T.px(10), midY - math.floor(MM.fontH(f2) / 2), d.r, d.g, d.b, d.a or 1, f2)
    elseif r.kind == "skill" then
        local name = tostring(r.name)
        local lvl = math.max(0, math.min(10, r.level or 0))
        local pct = ""
        if r.perk ~= Perks.Fitness and r.perk ~= Perks.Strength then
            pct = (lvl >= 3) and "+125%" or ((lvl == 2) and "+100%" or "+75%")
        end
        local pctW = MM.textW(f3, "+125%")
        local barW = T.px(56)
        local px = x + w - T.px(10) - pctW
        if pct ~= "" then self:drawText(pct, px + pctW - MM.textW(f3, pct), midY - math.floor(MM.fontH(f3) / 2), d.r, d.g, d.b, d.a or 1, f3) end
        local lvX = px - T.px(10) - MM.textW(f2, "10")
        self:drawText(tostring(lvl), lvX, midY - math.floor(MM.fontH(f2) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
        local bx = lvX - T.px(8) - barW
        ZeD.Atoms.drawSegBar(self, bx, midY - T.px(4), barW, T.px(8), 10, lvl, T.accent, T.surf3, T.px(1))
        self:drawText(ZeD.Atoms.truncateText(name, f2, bx - T.px(14) - x), x + T.px(10), midY - math.floor(MM.fontH(f2) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
    end
end

-- the band: what the row under the pointer (or the controller) does
function ZeD_MMTraits:drawHelp(x, y, w, h, pts)
    local T = ZeD.T
    local s2, bs = T.surf2, T.borderS
    self:drawRect(x, y, w, h, 1, s2.r, s2.g, s2.b)
    self:drawRectBorder(x, y, w, h, bs.a, bs.r, bs.g, bs.b)
    local r = self._hover
    local text = r and r.help or nil
    if (not text or text == "") and pts < 0 then text = getText("UI_charactercreation_needpoints") end
    -- nothing under the pointer: what the chosen occupation does
    if not text or text == "" then
        local p = prof()
        local it = p and p.listboxProf.items[p.listboxProf.selected or 0]
        if it then text = tostring(it.text) .. ": " .. tostring(it.tooltip or "") end
    end
    if not text or text == "" then return end
    local f2, tc = T.fontF2, T.text
    local ly = y + T.px(7)
    for i, l in ipairs(helpLines(text, f2, w - T.px(24))) do
        if ly + MM.fontH(f2) > y + h - T.px(4) then break end
        self:drawText(l, x + T.px(12), ly, tc.r, tc.g, tc.b, tc.a or 1, f2)
        ly = ly + MM.fontH(f2) + T.px(2)
    end
end

function ZeD_MMTraits:buildStrip(stripY, stripH, w, pts)
    local T = ZeD.T
    local row = 1000
    local ask = nil
    if self.confirm == "save" then
        ask = ZeD.tr("UI_ZeD_Traits_AskName")
        local p = prof()
        local valid = p and p:saveBuildValidate(self.field:getText() or "") or false
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", getText("UI_btn_save"), function() self:saveBuild() end, "primary", not valid } })
        local f2 = T.fontF2
        local fx = T.px(U.STRIP_PAD_X) + T.px(4) + MM.textW(f2, ask) + T.px(10)
        local firstBtn = w
        for _, b in ipairs(self._specs) do if b.row == row then firstBtn = math.min(firstBtn, b.x) end end
        local fh = T.px(24)
        UI.styleEntry(self.field, fx, stripY + math.floor((stripH - fh) / 2), math.max(T.px(80), firstBtn - T.px(12) - fx), fh)
    elseif self.confirm == "delete" then
        local p = prof()
        ask = ZeD.tr("UI_ZeD_Traits_AskDelete", tostring(p and p.savedBuilds.options[p.savedBuilds.selected] or ""))
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", getText("UI_btn_delete"), function() self:deleteBuild() end, "danger" } })
    else
        UI.stripSpecs(self, stripY, w, row,
            { { "back", getText("UI_btn_back"), function() self:back() end } },
            { { "builds", ZeD.tr("UI_ZeD_Traits_Builds"), function() self:openBuilds() end },
              { "random", getText("UI_characreation_random"), function() self:random() end },
              { "clear", ZeD.tr("UI_ZeD_Traits_ClearTraits"), function() self:clearTraits() end },
              { "next", getText("UI_btn_next"), function() self:next() end, "primary", pts < 0 } })
    end
    self._stripY, self._stripH, self._ask = stripY, stripH, ask
end

-- ============================================================================
-- CONTROLLER + KEYS + WHEEL: up / down walk a column, left / right change column,
-- down past the end reaches the strip
-- ============================================================================
function ZeD_MMTraits:inStrip()
    local f = self.focusId or ""
    return f ~= "" and f:sub(1, 1) ~= "c"
end

function ZeD_MMTraits:setJoy(c, i)
    local list = self._colFocus and self._colFocus[c] or {}
    if #list == 0 then return false end
    i = math.max(1, math.min(i, #list))
    self.jcol, self.jidx = c, i
    self.focusId = "c" .. c .. ":" .. i
    local f = list[i]
    local box = self._colBox and self._colBox[c]
    if f and box then
        if f.ry < self.scroll[c] then self.scroll[c] = f.ry
        elseif f.ry + f.rh > self.scroll[c] + box.h then self.scroll[c] = f.ry + f.rh - box.h end
    end
    MM.hoverSound()
    return true
end

function ZeD_MMTraits:joyDir(dir)
    if self.confirm then return ZeD_MMWindow.joyDir(self, dir) end
    if self:inStrip() then
        if dir == "up" then self:setJoy(self.jcol, #(self._colFocus[self.jcol] or {})); return end
        return ZeD_MMWindow.joyDir(self, dir)
    end
    if not self.focusId then self:setJoy(self.jcol, self.jidx); return end
    if dir == "up" then self:setJoy(self.jcol, self.jidx - 1)
    elseif dir == "down" then
        if self.jidx >= #(self._colFocus[self.jcol] or {}) then self.focusId = "next"; MM.hoverSound()
        else self:setJoy(self.jcol, self.jidx + 1) end
    else
        local c = self.jcol + ((dir == "left") and -1 or 1)
        while c >= 1 and c <= 3 do
            if self:setJoy(c, self.jidx) then return end
            c = c + ((dir == "left") and -1 or 1)
        end
    end
end

function ZeD_MMTraits:joyA()
    if self.confirm or self:inStrip() then return ZeD_MMWindow.joyA(self) end
    local f = self._colFocus and self._colFocus[self.jcol] and self._colFocus[self.jcol][self.jidx]
    if f and f.row.fn then
        f.row.fn()   -- (the column may shorten: prerender keeps the focus in range)
    end
end

function ZeD_MMTraits:joyB()
    if self.confirm then self:setConfirm(false); return end
    self:back()
end
function ZeD_MMTraits:joyX() if not self.confirm then self:random() end end
function ZeD_MMTraits:joyY() if not self.confirm then self:openBuilds() end end

function ZeD_MMTraits:getFooterPrompts()
    if not MM.gamepad() then return nil end
    if self.confirm then return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = getText("UI_Cancel") } } end
    local t = {}
    if not self:inStrip() then
        local label = (self.jcol == 1) and ZeD.tr("UI_ZeD_Traits_PromptChoose") or ((self.jcol == 2) and getText("ContextMenu_Take") or ZeD.tr("UI_ZeD_Traits_PromptGiveBack"))
        t[#t + 1] = { glyph = "A", label = label }
    else
        t[#t + 1] = { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }
    end
    t[#t + 1] = { glyph = "X", label = getText("UI_mapspawn_random") }
    t[#t + 1] = { glyph = "Y", label = ZeD.tr("UI_ZeD_Traits_PromptBuilds") }
    t[#t + 1] = { glyph = "B", label = ZeD.btnCase(getText("UI_btn_back")) }
    return t
end

function ZeD_MMTraits:keyEscape()
    if self.confirm then self:setConfirm(false); return true end
    self:back()
    return true
end

function ZeD_MMTraits:keyOther(key)
    if key == Keyboard.KEY_RETURN and self._enterAt and MM.now() - self._enterAt < 400 then return true end
    if self.field:isFocused() or self.confirm then return false end
    if key == Keyboard.KEY_RETURN then self:next(); return true end
    -- the arrows walk the occupations
    if key == Keyboard.KEY_UP or key == Keyboard.KEY_DOWN then
        local p = prof()
        if p then
            local i = (p.listboxProf.selected or 1) + ((key == Keyboard.KEY_UP) and -1 or 1)
            if p.listboxProf.items[i] then self:pickProf(i); self:setJoy(1, i) end
        end
        return true
    end
    return false
end

function ZeD_MMTraits:close() self:back() end

function ZeD_MMTraits:wheel(del)
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    for c = 1, 3 do
        local b = self._colBox and self._colBox[c]
        if b and mx >= b.x and mx < b.x + b.w and my >= b.y and my < b.y + b.h then
            self.scroll[c] = (self.scroll[c] or 0) + del * ZeD.T.px(TRAIT_H) * 2
            return true
        end
    end
    return false
end
function ZeD_MMTraits:onMouseWheel(del) return MM.wheel(del) end

local _wheel = MM.wheel
function MM.wheel(del)
    if MM.view == "traits" and MM.root and MM.root.traitsWin then
        if MM.dropWheel and MM.dropWheel(del) then return true end
        return MM.root.traitsWin:wheel(del)
    end
    return _wheel(del)
end

-- on the desk as the "traits" view; vanilla's charCreationProfession:setVisible(true) lands here
MM.addView("traits", "traitsWin", function() return ZeD_MMTraits:new() end, "charCreationProfession")
