-- ZeDUI/tools/qa/desk_stub.lua  (Nov 7 2026, punch list 104): a stub of the main menu's desk for the desk sims. The desk's
-- frame (ZeD_MainMenu.lua, the window organism, the game's panels and text boxes) is stood in for by the few calls the desktop,
-- the notepad and the mail app make, so the real ZeD_MainMenuDesktop.lua, ZeD_MainMenuNotes.lua and ZeD_MainMenuMail.lua run
-- with no game. Zomboid/Lua is a table (DISK), as in desk_notes_sim.lua. Nothing here draws: draws are counted.
-- Used by desk_sim.lua:  local D = dofile(ROOT .. "ZeDUI/tools/qa/desk_stub.lua"); D.boot(ROOT)

local D = {}
local W = { clock = 1000, mouse = { x = -1, y = -1 }, down = false, pad = false, sounds = 0, draws = 0, kbd = {} }
D.W = W

-- ---------------------------------------------------------------------------
-- Zomboid/Lua
-- ---------------------------------------------------------------------------
local DISK = {}
D.DISK = DISK
local function lines(text)
    local out, pos = {}, 1
    while pos <= #text do
        local nl = string.find(text, "\n", pos, true)
        if not nl then out[#out + 1] = string.sub(text, pos); break end
        out[#out + 1] = string.sub(text, pos, nl - 1)
        pos = nl + 1
    end
    return out
end
function getFileReader(name)
    if string.find(name, "..", 1, true) then error("hasRelativePath") end
    if DISK[name] == nil then return nil end
    local ls, i = lines(DISK[name]), 0
    return { readLine = function() i = i + 1; return ls[i] end, close = function() end }
end
function getFileWriter(name, create, append)
    if string.find(name, "..", 1, true) then error("hasRelativePath") end
    local buf = {}
    if append and DISK[name] then buf[1] = DISK[name] end
    DISK[name] = table.concat(buf)
    return { write = function(_, s) buf[#buf + 1] = s end, close = function() DISK[name] = table.concat(buf) end }
end
function getTimestamp() return math.floor(W.clock / 1000) + 1700000000 end
function getTimestampMs() return W.clock end
function getText(k, ...) return k end
function getMouseX() return W.mouse.x end
function getMouseY() return W.mouse.y end
function isMouseButtonDown() return W.down end
function getCore() return { getScreenWidth = function() return 1920 end, getScreenHeight = function() return 1080 end } end
function getSoundManager() return { playUISound = function() W.sounds = W.sounds + 1 end } end
function updateJoypadFocus() end
Keyboard = { KEY_RETURN = 28, KEY_ESCAPE = 1, KEY_UP = 200, KEY_DOWN = 208, KEY_LEFT = 203, KEY_RIGHT = 205 }
Texture = { getSharedTexture = function(path) return { path = path, isReady = function() return true end } end }
JoypadState = { getMainMenuJoypad = function() return W.pad and { player = 0, focus = "menu" } or nil end }
OnScreenKeyboard = { Show = function(p, entry, jd) W.kbd[#W.kbd + 1] = entry; return { entry = entry } end }

-- ---------------------------------------------------------------------------
-- PANELS, as the game's: a class derives, a child sits in its parent's coordinates, addChild builds the children
-- ---------------------------------------------------------------------------
local Base = {}
Base.__index = Base
function Base:derive(name)
    local c = {}
    for k, v in pairs(self) do if k ~= "__index" then c[k] = v end end
    c.__index = c
    c.Type = name
    c._super = self
    return c
end
function Base:new(x, y, w, h)
    local o = { x = x or 0, y = y or 0, width = w or 1, height = h or 1, children = {}, visible = true }
    setmetatable(o, self)
    return o
end
function Base:initialise() end
function Base:instantiate() end
function Base:createChildren() end
function Base:addChild(c)
    c.parent = self
    self.children[#self.children + 1] = c
    if not c._built then c._built = true; c:createChildren() end
end
function Base:setX(v) self.x = v end
function Base:setY(v) self.y = v end
function Base:setWidth(v) self.width = v end
function Base:setHeight(v) self.height = v end
function Base:getWidth() return self.width end
function Base:getHeight() return self.height end
function Base:getAbsoluteX() return self.x + (self.parent and self.parent:getAbsoluteX() or 0) end
function Base:getAbsoluteY() return self.y + (self.parent and self.parent:getAbsoluteY() or 0) end
function Base:isVisible() return self.visible end
function Base:setVisible(v) self.visible = v and true or false end
function Base:isReallyVisible()
    local p = self
    while p do if not p.visible then return false end; p = p.parent end
    return true
end
function Base:update() end
function Base:prerender() end
function Base:render() end
for _, n in ipairs({ "drawRect", "drawRectBorder", "drawText", "drawTextureScaledAspect", "drawRectStatic", "setStencilRect", "clearStencilRect" }) do
    Base[n] = function() W.draws = W.draws + 1 end
end
ISPanel = Base:derive("ISPanel")
ISUIElement = ISPanel

ISTextEntryBox = Base:derive("ISTextEntryBox")
function ISTextEntryBox:new(title, x, y, w, h)
    local o = Base.new(self, x, y, w, h)
    o.text = title or ""
    o.focused = false
    o.yScroll = 0
    o.javaObject = { setTextRGBA = function() end, setPlaceholderTextRGBA = function() end }
    o.getInternalText = true
    return o
end
function ISTextEntryBox:getText() return self.text end
function ISTextEntryBox:getInternalText() return self.text end
function ISTextEntryBox:setText(s) self.text = s or "" end
function ISTextEntryBox:setMultipleLine(b) self.multi = b end
function ISTextEntryBox:setMaxLines(n) self.maxLines = n end
function ISTextEntryBox:setMaxTextLength(n) self.maxLen = n end
function ISTextEntryBox:setFont(f) self.font = f end
function ISTextEntryBox:setPlaceholderText(s) self.placeholder = s end
function ISTextEntryBox:focus() self.focused = true end
function ISTextEntryBox:unfocus() self.focused = false end
function ISTextEntryBox:isFocused() return self.focused end
function ISTextEntryBox:setCursorPos(n) self.cursor = n end
function ISTextEntryBox:getCursorPos() return self.cursor or #self.text end
function ISTextEntryBox:setYScroll(v) self.yScroll = v end
function ISTextEntryBox:getYScroll() return self.yScroll end
function ISTextEntryBox:setEditable() end
-- what a player does to a text box: types (the box's own limit holds), the change call follows
function ISTextEntryBox:type(s)
    local t = self.text .. s
    if self.maxLen and #t > self.maxLen then t = string.sub(t, 1, self.maxLen) end
    self.text = t
    if self.onTextChange then self.onTextChange(self) end
end

-- ---------------------------------------------------------------------------
-- ZeD: tokens, words, the library pieces the desk calls
-- ---------------------------------------------------------------------------
local function col(r, g, b) return { r = r, g = g, b = b, a = 1 } end
ZeD = {
    paperTone = function(c) return { r = c.r * 0.7, g = c.g * 0.7, b = c.b * 0.7, a = c.a } end,   -- (Tokens.lua's paper tone)
    T = { scale = 1, px = function(n) return n end, fontF1 = 1, fontF2 = 2, fontF3 = 3, fontF4 = 4, titleBarH = 20, buttonH = 22, tabH = 20,
          accent = col(0.3, 0.5, 0.9), text = col(1, 1, 1), textDim = col(0.6, 0.6, 0.6), textOnAccent = col(1, 1, 1), surf1 = col(0.2, 0.2, 0.2),
          surf2 = col(0.25, 0.25, 0.25), borderS = col(0.5, 0.5, 0.5), border = col(0.4, 0.4, 0.4), base = col(0.1, 0.1, 0.1),
          positive = col(0, 1, 0), warning = col(1, 1, 0), danger = col(1, 0, 0), disabledAlpha = 0.4,
          sp = { scrollbarW = 12, sm = 4, buttonPadX = 8, tabGap = 2 } },
    tr = function(k, ...)
        local a = { ... }
        if #a == 0 then return k end
        for i = 1, #a do a[i] = tostring(a[i]) end
        return k .. "(" .. table.concat(a, ",") .. ")"
    end,
    btnCase = function(s) return s end,
    textCase = function(s) return s end,
    logOnce = function(what, err) print("logOnce " .. tostring(what) .. ": " .. tostring(err)) end,
    Atoms = { truncateText = function(s) return s end, frame = function() end, drawStatusDot = function() end, wrapText = function(s) return { s } end },
    Molecules = { drawGlyphPrompts = function() end, buttonW = function(s) return 8 * #tostring(s) + 16 end, drawEmptyLine = function() end,
                  drawTab = function(p, x, y, text) return 8 * #tostring(text) + 16 end, drawSectionHeader = function() end, bandH = function() return 34 end },
    Surface = { fill = function() end },
    Text = { entryFont = function() return "entryFont" end },
    MouseTick = { down = function() return W.down end },
    SpatialNav = { pick = function(cur, cands, dir, rectOf)
        rectOf = rectOf or function(e) return e end
        local best, bestD
        local c = rectOf(cur)
        local cx, cy = c.x + c.w / 2, c.y + c.h / 2
        for _, e in ipairs(cands) do
            local r = rectOf(e)
            local ex, ey = r.x + r.w / 2, r.y + r.h / 2
            local ok = (dir == "up" and ey < cy) or (dir == "down" and ey > cy) or (dir == "left" and ex < cx) or (dir == "right" and ex > cx)
            if ok then
                local d = (ex - cx) ^ 2 + (ey - cy) ^ 2
                if not bestD or d < bestD then best, bestD = e, d end
            end
        end
        return best
    end },
}

-- ---------------------------------------------------------------------------
-- THE WINDOW ORGANISM AND THE DESK'S OWN WINDOW, as far as the desk's apps use them
-- ---------------------------------------------------------------------------
ZeD_Window = ISPanel:derive("ZeD_Window")
function ZeD_Window.new(self, x, y, w, h, title)
    local o = Base.new(self, x, y, w, h)
    o.title = title
    o.titleStats = {}
    return o
end
function ZeD_Window:createChildren() end
function ZeD_Window:prerender() end
function ZeD_Window:render() end
function ZeD_Window:update() end
function ZeD_Window:footerHeight() return 20 end

ZeD_MMWindow = ZeD_Window:derive("ZeD_MMWindow")
function ZeD_MMWindow.new(self, kind)
    local o = ZeD_Window.new(self, 0, 0, 400, 300, "Project Zomboid")
    o.kind = kind
    o.confirm = false
    o._specs, o._hits = {}, {}
    return o
end
function ZeD_MMWindow:update() end
function ZeD_MMWindow:setConfirm(on) self.confirm = on end
function ZeD_MMWindow:focusPos()
    for _, s in ipairs(self._specs) do if s.id == self.focusId and not s.disabled then return s end end
    return nil
end
function ZeD_MMWindow:joyA() local s = self:focusPos(); if s and s.fn then s.fn() end end
function ZeD_MMWindow:joyDir() end

-- ---------------------------------------------------------------------------
-- THE DESK (ZeD.MainMenu), the parts the apps call
-- ---------------------------------------------------------------------------
local MM = {}
ZeD.MainMenu = MM
MM.U = { BAR_H = 24, STACK_PAD = 12, STACK_GAP = 8, WIDE_H = 34 }
MM.ctx = { open = nil, hot = nil, press = nil }
MM.view = "main"
MM.views = {}
MM.readyChecks = {}
MM.act = { newGame = function() end, load = function() end, join = function() end, options = function() end, mods = function() end, workshop = function() end }
D.L = { tx = 480, ty = 180, tw = 960, th = 720, sw = 1920, sh = 1080, s = 4 }
function MM.layout() return D.L end
function MM.fontH() return 16 end
function MM.textW(f, s) return 7 * #tostring(s or "") end
function MM.now() return W.clock end
function MM.clickSound() W.sounds = W.sounds + 1 end
function MM.hoverSound() W.sounds = W.sounds + 1 end
function MM.gamepad() return W.pad end
function MM.blocked() return false end
function MM.poweringOn() return false end
function MM.hasSaves() return true end
function MM.bandH() return 34 end
function MM.helpFor() return nil end
MM.DOT = " | "
MM.MONTHS = { "M1", "M2", "M3", "M4", "M5", "M6", "M7", "M8", "M9", "M10", "M11", "M12" }
function MM.drawDropBox() return false end
function MM.rowLook() return false end
function MM.focusOpts() return { focused = true } end
function MM.scrollBar() return {} end
ZeD.Atoms.drawDividerH = function() end
function MM.addView(view, field, make) MM.views[#MM.views + 1] = { view = view, field = field, make = make } end
function MM.openPopup(key, items, anchor, up) MM.popup = { key = key, items = items, anchor = anchor }; MM.ctx.open = key end
function MM.wheel() return false end
function MM.entryUnder() return nil end
function MM.menuItems(key)
    if key == "zed" then return { { about = true }, "-", { text = "credits" } } end
    return { { text = "x" } }
end
function MM.activeWindow()
    local r = MM.root
    if not r then return nil end
    if MM.view == "desktop" then return r.icons end
    for _, v in ipairs(MM.views) do if v.view == MM.view then return r[v.field] end end
    return r.win
end
function MM.showView(view)
    MM.view = view
    MM.ctx.open = nil
    local w = MM.activeWindow()
    if w and w.onShow then w:onShow() end
end

-- the band: buttons into the window's specs, right-aligned in the order given; returns where a field may start
local function stripSpecs(win, y, w, row, lefts, rights, ask, plain, statusColor)
    local x = w - 8
    local all = {}
    for _, g in ipairs({ lefts, rights }) do for _, r in ipairs(g) do all[#all + 1] = r end end
    for i = #all, 1, -1 do
        local r = all[i]
        local bw = 8 * #tostring(r[2]) + 16
        x = x - bw
        table.insert(win._specs, { id = r[1], text = r[2], fn = r[3], variant = r[4], disabled = r[5], help = r[6], row = row, col = i, x = x, y = y, w = bw, h = 22, band = true })
        x = x - 8
    end
    win._ask, win._askColor = ask, statusColor
    return 8 + MM.textW(2, ask or "") + 10
end
MM.ui = {
    insetBox = function() end,
    newEntry = function(win) local e = ISTextEntryBox:new("", 0, 0, 100, 24); win:addChild(e); return e end,
    styleEntry = function(e, x, y, w, h) e.x, e.y, e.width, e.height = x, y, w, h end,
    placeOnTube = function(win) win.x, win.y, win.width, win.height = D.L.tx + 20, D.L.ty + 36, D.L.tw - 40, D.L.th - 60; return win.width, win.height end,
    stripSpecs = stripSpecs,
    drawStripAndButtons = function() end,
    plain = function(s) return s end,
}

-- the desk: the icon layer, the sticky's field, the main window and every view's window, as ZeD_MMDesk:createChildren builds them
function D.buildDesk()
    local root = ISPanel:new(0, 0, 1920, 1080)
    MM.root = root
    root.icons = ZeD_MMIcons:new(); root:addChild(root.icons)
    if ZeD_MMSticky then root.sticky = ZeD_MMSticky:new(); root:addChild(root.sticky) end
    root.win = ZeD_MMWindow.new(ZeD_MMWindow, "main"); root:addChild(root.win)
    for _, v in ipairs(MM.views) do
        local w = v.make()
        root:addChild(w)
        root[v.field] = w
    end
    MM.view = "main"
    return root
end

-- one frame: the icon layer draws (and places the sticky), then the view's window; then the updates
function D.frame(ms)
    W.clock = W.clock + (ms or 16)
    local r = MM.root
    r.icons:prerender()
    if r.sticky then r.sticky:prerender() end
    local w = MM.activeWindow()
    if w and w ~= r.icons and w ~= r.win then w:prerender() end
    if r.sticky then r.sticky:update() end
    if w and w ~= r.icons and w ~= r.win and w.update then w:update() end
end

-- a spec of the view's window by id
function D.spec(win, id)
    for _, s in ipairs(win._specs or {}) do if s.id == id then return s end end
    return nil
end
function D.press(win, id)
    local s = D.spec(win, id)
    if not s then error("no button " .. tostring(id) .. " in " .. tostring(win.kind)) end
    if s.disabled then return false end
    s.fn()
    D.frame()          -- (the next frame draws what the press changed)
    return true
end

-- the icon layer's cells by item id
function D.cell(id)
    for _, c in ipairs(MM.root.icons._cells or {}) do if c.item.id == id then return c end end
    return nil
end

-- loads the desk's files: the real desktop, the notes (and the mail app when asked)
function D.boot(ROOT, withMail)
    local real = require
    require = function(name)
        if name == "ZeD/ZeD_DeskNotes" then return dofile(ROOT .. "42/media/lua/client/ZeD/ZeD_DeskNotes.lua") end
        if name == "ZeD/ZeD_MailProto" then return dofile(ROOT .. "42/media/lua/shared/ZeD/ZeD_MailProto.lua") end
        if name == "ZeD/ZeD_TicketProto" then return dofile(ROOT .. "42/media/lua/shared/ZeD/ZeD_TicketProto.lua") end
        if name == "ZeD/ZeD_MailStore" then return dofile(ROOT .. "42/media/lua/client/ZeD/ZeD_MailStore.lua") end
        if name == "ZeD/ZeD_MainMenuDesktop" or name == "ZeD/ZeD_MainMenuNotes" or name == "ZeD/ZeD_MainMenuDocs" then return nil end
        return nil
    end
    dofile(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenuDesktop.lua")
    dofile(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenuNotes.lua")
    dofile(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenuDocs.lua")
    if withMail then dofile(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenuMail.lua") end
    require = real
end

return D
