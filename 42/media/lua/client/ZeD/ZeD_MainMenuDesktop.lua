-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuDesktop.lua
-- ============================================================================
-- THE ZeD OS DESKTOP (HOOK_MAP row 26; menus delegated, no mockups). Director,
-- Oct 15 2026: "Add ability to close a window on the ZeD OS desktop computer in
-- the main menu. Add icons to the desktop to open the menus, in case they close
-- it and dont figure out the toolbar menu can do it. Normal application type
-- icons that would be on a desktop. Make a trashcan icon with system32.dll in
-- the trash can (little joke)."
--
-- The main window's close box now just closes it (Quit stays in File and on the
-- case's power button) and leaves the bare desktop. Down the screen's right
-- edge, the way a 1993 desktop kept them: Project Zomboid, New Game, Load Game,
-- Join a Server, Options, Mods, Mod Uploader (the Workshop, where Steam offers it); the
-- Trash in the bottom corner. 32 x 32 pixel
-- icons (ZeDUI/tools/mainmenu/bake_desktop_icons.py) drawn at whole multiples.
-- A click selects an icon (its name turns accent, the picture darkens), a
-- second click opens it; Return or A opens the selected one, the arrows or the
-- D-pad move between them. They sit under the windows, as icons do.
--
-- The Trash opens a small window holding one file: the Computer itself (Oct 21
-- 2026, was system32.dll; the old desktop joke of dragging the computer to the
-- trash). Empty trash throws the computer away: the window asks the game's own
-- "Quit Project Zomboid?" (director, Oct 16 2026: "What if deleting system32.dll
-- queues the are quit game dialog?"). Cancel keeps everything.
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/Input/SpatialNav"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui

local ICON_DIR = "media/textures/ZeD/mainmenu/icons/"
local NEAREST = 3                 -- Texture flag: nearest filtering (the pixels stay square)
local ICON_PX = 32                -- the art's own size
local CELL_W = 104                -- design units: an icon's cell (its name wraps no wider)
local EDGE = 14                   -- from the screen's edges
local GAP = 14                    -- between cells
local DOUBLE_MS = 450             -- a second click this soon opens

local _tex = {}
local function icon(name)
    local t = _tex[name]
    if t == nil then t = Texture.getSharedTexture(ICON_DIR .. name .. ".png", NEAREST) or false; _tex[name] = t end
    return t or nil
end

-- the icons, top first; each opens what its File / Multiplayer / Settings item opens
local function items()
    local A = MM.act
    return {
        { id = "pz", label = "Project Zomboid", open = function() MM.showView("main") end },
        { id = "newgame", label = ZeD.btnCase(getText("UI_NewGameScreen_title")), open = function() A.newGame() end },
        { id = "load", label = ZeD.tr("UI_ZeD_MainMenu_LoadGame"), open = function() A.load() end, off = function() return not MM.hasSaves() end },
        { id = "join", label = ZeD.tr("UI_ZeD_MainMenu_JoinServer"), open = function() A.join() end },
        { id = "options", label = ZeD.btnCase(getText("UI_mainscreen_option")), open = function() A.options() end },
        { id = "mods", label = getText("UI_NewGame_Mods"), open = function() A.mods() end },
        -- the Workshop window, where Steam offers it (director, Oct 25 2026: "an icon on the desktop...
        -- Look like a FTP program... named, Mod Uploader"; the icon is the pick of three)
        { id = "uploader", label = ZeD.tr("UI_ZeD_Desktop_ModUploader"), open = function() A.workshop() end,
          hide = function() local m = MainScreen and MainScreen.instance; return not (m and m.workshopOption) end },
    }
end
local TRASH = { id = "trash", label = "UI_ZeD_Desktop_Trash", open = function() MM.showView("trash") end }   -- (label: a translation key, drawn through ZeD.tr)

-- (director, Oct 16 2026: "desktop icons are loading slower than their text label") the
-- icon pictures are loose textures the engine streams in after boot: they are asked for
-- now, the menu's wake-up waits for them with the desk's own pictures, and a cell draws
-- its name only once its picture is in, so the two always arrive together
local ICON_IDS = { "pz", "newgame", "load", "join", "options", "mods", "uploader", "trash", "computer" }
pcall(function() for _, n in ipairs(ICON_IDS) do Texture.getSharedTexture(ICON_DIR .. n .. ".png", NEAREST) end end)
local function iconReady(t)
    if not t then return true end
    local ok, r = pcall(function() return t:isReady() end)
    return (not ok) or r
end
MM.readyChecks = MM.readyChecks or {}
MM.readyChecks.desktopIcons = function()
    for _, n in ipairs(ICON_IDS) do if not iconReady(icon(n)) then return false end end
    return true
end

-- the icons' places on the screen: { item, x, y, w, h (the cell), ix, iy, isz (the picture), ly (its name) }
local function cells(L)
    local T = ZeD.T
    local k = math.max(1, math.floor((T.scale or 1) + 0.5))
    local isz = ICON_PX * k
    local labelH = MM.fontH(T.fontF2) + T.px(4)
    local cw = math.max(T.px(CELL_W), isz + T.px(16))
    local ch = isz + T.px(6) + labelH
    local x = L.tx + L.tw - T.px(EDGE) - cw
    local y = L.ty + T.px(U.BAR_H) + T.px(EDGE)
    local out = {}
    local function place(it, cy)
        out[#out + 1] = { item = it, x = x, y = cy, w = cw, h = ch, ix = x + math.floor((cw - isz) / 2), iy = cy, isz = isz, ly = cy + isz + T.px(6), lh = labelH }
    end
    -- top down; a cell that would reach the Trash starts a column to the left (a short screen at a big scale)
    local top, trashY = y, L.ty + L.th - T.px(EDGE) - ch
    for _, it in ipairs(items()) do
        if not (it.hide and it.hide()) then
            if y > top and y + ch > trashY - T.px(GAP) then x = x - cw - T.px(GAP); y = top end
            place(it, y); y = y + ch + T.px(GAP)
        end
    end
    x = L.tx + L.tw - T.px(EDGE) - cw
    place(TRASH, trashY)
    return out
end

-- ============================================================================
-- THE ICON LAYER (a child of the desk under the windows; the "desktop" view's
-- controller and keys come here too)
-- ============================================================================
ZeD_MMIcons = ISPanel:derive("ZeD_MMIcons")

function ZeD_MMIcons:new()
    local o = ISPanel:new(0, 0, 1, 1)   -- draws over the desk; the desk's pointer tests its hits
    setmetatable(o, self)
    self.__index = self
    o.background = false
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o._hits = {}
    o.focusId = nil      -- the selected icon (the controller's focus is the selection)
    o._lastClick = nil   -- { id, at } for the second click
    return o
end

function ZeD_MMIcons:onShow()
    if not self.focusId then self.focusId = "pz" end
end

function ZeD_MMIcons:find(id)
    for _, c in ipairs(self._cells or {}) do if c.item.id == id then return c end end
    return nil
end

function ZeD_MMIcons:open(id)
    local c = self:find(id)
    if not c then return end
    if c.item.off and c.item.off() then return end
    self._lastClick = nil
    MM.clickSound()
    c.item.open()
end

function ZeD_MMIcons:click(id)
    local t = MM.now()
    local lc = self._lastClick
    if lc and lc.id == id and t - lc.at < DOUBLE_MS then self:open(id); return end
    self.focusId = id
    self._lastClick = { id = id, at = t }
    MM.hoverSound()
end

function ZeD_MMIcons:prerender()
    local T = ZeD.T
    local L = MM.layout()
    self._hits = {}
    local list = cells(L)
    self._cells = list
    local f2 = T.fontF2
    local ac, tc, onAc = T.accent, T.text, T.textOnAccent
    for _, c in ipairs(list) do
        local it = c.item
        local off = it.off and it.off()
        local sel = self.focusId == it.id
        local tex = icon(it.id)
        local ready = iconReady(tex)
        local k = sel and 0.55 or 1                       -- a selected icon darkens, as they did
        if ready then                                     -- (picture and name come together)
        if tex then self:drawTextureScaledAspect(tex, c.ix, c.iy, c.isz, c.isz, off and T.disabledAlpha or 1, k, k, k) end
        -- its name, on a theme backing (surf1) so it reads over the painting on every theme; selected: the accent
        local name = ZeD.Atoms.truncateText((it.id == "trash") and ZeD.tr(it.label) or it.label, f2, c.w - T.px(4))
        local nw = MM.textW(f2, name)
        local nx = c.x + math.floor((c.w - nw) / 2)
        local bx, bw = nx - T.px(4), nw + T.px(8)
        if sel then
            self:drawRect(bx, c.ly, bw, c.lh, 1, ac.r, ac.g, ac.b)
            self:drawText(name, nx, c.ly + T.px(2), onAc.r, onAc.g, onAc.b, off and T.disabledAlpha or 1, f2)
        else
            local s1 = T.surf1
            self:drawRect(bx, c.ly, bw, c.lh, 0.92, s1.r, s1.g, s1.b)
            self:drawText(name, nx, c.ly + T.px(2), tc.r, tc.g, tc.b, off and T.disabledAlpha or 1, f2)
        end
        if not off then
            self._hits[#self._hits + 1] = { id = "desk:" .. it.id, x = c.x, y = c.y, w = c.w, h = c.h, fn = function() self:click(it.id) end }
        end
        end
    end
    -- the controller's prompts along the screen's foot (the bare desktop only)
    if MM.view == "desktop" and MM.gamepad() then
        local h = T.sp.scrollbarW
        local y = L.ty + L.th - h - T.px(EDGE)
        local s2, bs = T.surf2, T.borderS
        local w = T.px(260)
        self:drawRect(L.tx + T.px(EDGE), y, w, h, 1, s2.r, s2.g, s2.b)
        self:drawRectBorder(L.tx + T.px(EDGE), y, w, h, bs.a or 1, bs.r, bs.g, bs.b)
        ZeD.Molecules.drawGlyphPrompts(self, L.tx + T.px(EDGE) + T.sp.sm, y, h, { ZeD.tr("UI_ZeD_Desktop_PromptDpad"), { glyph = "A", label = getText("IGUI_Open") } })
    end
end

-- CONTROLLER + KEYS (the "desktop" view) ------------------------------------------
function ZeD_MMIcons:joyDir(dir)
    local cur = self:find(self.focusId or "pz")
    if not cur then self.focusId = "pz"; return end
    local cands = {}
    for _, c in ipairs(self._cells or {}) do if c ~= cur and not (c.item.off and c.item.off()) then cands[#cands + 1] = c end end
    local best = ZeD.SpatialNav.pick(cur, cands, dir)
    if best then self.focusId = best.item.id; MM.hoverSound() end
end
function ZeD_MMIcons:joyA() self:open(self.focusId or "pz") end
function ZeD_MMIcons:joyB() end
function ZeD_MMIcons:getFooterPrompts() return nil end
function ZeD_MMIcons:keyEscape() return false end
function ZeD_MMIcons:keyOther(key)
    if key == Keyboard.KEY_RETURN then self:joyA(); return true end
    if key == Keyboard.KEY_UP then self:joyDir("up"); return true end
    if key == Keyboard.KEY_DOWN then self:joyDir("down"); return true end
    if key == Keyboard.KEY_LEFT then self:joyDir("left"); return true end
    if key == Keyboard.KEY_RIGHT then self:joyDir("right"); return true end
    return false
end

-- ============================================================================
-- THE TRASH (a small window on the desktop)
-- ============================================================================
ZeD_MMTrash = ZeD_MMWindow:derive("ZeD_MMTrash")

local TRASH_W = 440
local FILE = { name = "UI_ZeD_Desktop_FileName", size = "40 MB", kind = "UI_ZeD_Desktop_FileKind" }   -- (name, kind: translation keys)

function ZeD_MMTrash:new()
    local o = ZeD_MMWindow.new(self, "trash")
    o.noResetControl = true
    return o
end

function ZeD_MMTrash:onShow()
    self.confirm = false
    self.focusId = "close"
end

-- the question in the band (the main window's own, a band swap); off, the
-- controller goes back to Empty trash
function ZeD_MMTrash:setConfirm(on)
    ZeD_MMWindow.setConfirm(self, on)
    if not on then self.focusId = "empty" end
end

function ZeD_MMTrash:close()
    MM.clickSound()
    MM.showView("desktop")
end
function ZeD_MMTrash:back() self:close() end

-- emptying it throws the computer away
function ZeD_MMTrash:empty() self:setConfirm(true) end

function ZeD_MMTrash:prerender()
    local T = ZeD.T
    local L = MM.layout()
    self._specs, self._hits = {}, {}
    local f2, f3 = T.fontF2, T.fontF3
    local pad = T.px(U.STACK_PAD)
    local k = math.max(1, math.floor((T.scale or 1) + 0.5))
    local isz = ICON_PX * k
    local rowH = isz + T.px(12)
    local stripH = MM.bandH()
    local tb = T.titleBarH
    local w = math.min(T.px(TRASH_W), L.tw - T.px(40))
    local h = tb + pad + rowH + T.px(2) + pad + stripH + self:footerHeight()
    local x = L.tx + math.floor((L.tw - w) / 2)
    local y = L.ty + T.px(U.BAR_H) + math.floor((L.th - T.px(U.BAR_H) - h) / 2)
    if self.x ~= x or self.y ~= y then self:setX(x); self:setY(y) end
    if self.width ~= w or self.height ~= h then self:setWidth(w); self:setHeight(h) end
    self.title = ZeD.tr("UI_ZeD_Desktop_Trash")
    self.titleStats = { { text = ZeD.tr("UI_ZeD_Desktop_OneItem"), noMark = true } }   -- (no status mark: a plain count)
    ZeD_Window.prerender(self)

    -- the one file in it
    local bx, by, bw = pad, tb + pad, w - pad * 2
    UI.insetBox(self, bx, by, bw, rowH + T.px(2))
    local ry = by + T.px(1)
    local tex = icon("computer")
    if tex then self:drawTextureScaledAspect(tex, bx + T.px(10), ry + math.floor((rowH - isz) / 2), isz, isz, 1, 1, 1, 1) end
    local tc, td = T.text, T.textDim
    local nx = bx + T.px(20) + isz
    self:drawText(ZeD.tr(FILE.name), nx,ry + math.floor(rowH / 2) - MM.fontH(f2), tc.r, tc.g, tc.b, tc.a or 1, f2)
    self:drawText(ZeD.tr(FILE.kind), nx, ry + math.floor(rowH / 2), td.r, td.g, td.b, td.a or 1, f2)
    self:drawText(FILE.size, bx + bw - T.px(12) - MM.textW(f3, FILE.size), ry + math.floor((rowH - MM.fontH(f3)) / 2), td.r, td.g, td.b, td.a or 1, f3)

    local stripY = h - self:footerHeight() - stripH
    if self.confirm then
        UI.stripSpecs(self, stripY, w, 1000, {},
            { { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end, "default" },
              { "confirm:yes", getText("UI_mainscreen_exit"), MM.act.quit, "danger", false, ZeD.tr("UI_ZeD_MMHelp_QuitGame") } },
            ZeD.tr("UI_ZeD_MainMenu_AskQuitGame"))
    else
        UI.stripSpecs(self, stripY, w, 1000,
            { { "close", getText("UI_btn_close"), function() self:close() end } },
            { { "empty", ZeD.tr("UI_ZeD_Desktop_EmptyTrash"), function() self:empty() end } })
    end
end

function ZeD_MMTrash:render()
    UI.drawStripAndButtons(self)
    ZeD_Window.render(self)
end

function ZeD_MMTrash:joyB() if self.confirm then self:setConfirm(false) else self:close() end end
function ZeD_MMTrash:getFooterPrompts()
    if not MM.gamepad() then return nil end
    if self.confirm then return { { glyph = "A", label = getText("IGUI_Exit") }, { glyph = "B", label = getText("UI_Cancel") } } end
    return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = getText("UI_Close") } }
end
function ZeD_MMTrash:keyEscape() self:joyB(); return true end

MM.addView("trash", "trashWin", function() return ZeD_MMTrash:new() end)
