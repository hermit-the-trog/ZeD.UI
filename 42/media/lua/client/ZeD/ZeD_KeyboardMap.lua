-- ZeD-UI/42/media/lua/client/ZeD/ZeD_KeyboardMap.lua
-- ============================================================================
-- THE KEYBOARD MAP (beta 21, the director, Nov 18 2026: "Keyboard display and binding assistance") — every key the
-- game uses, on one page, and a way to change one. Client organism (a ZeD_Window), the Controller map's sibling.
--
-- A drawn 1993 keyboard: every key the game's bindings use lit in the accent; a key that does two jobs the game's own
-- keys never share drawn in the player's bad color (the game's Accessibility option); a key picked (clicked) washed,
-- and its jobs washed in the list. Under it the game's actions in the game's own groups ([Player Control] and the
-- rest, the keyBinding table), each with its key in a box. Click a box, press a key: the action takes it (Escape
-- leaves it as it was). The change goes into keysB42.ini the way the game's Options writes it (the same lines: the
-- key, an alternate, shift, ctrl, alt) and into the game at once (Core.addKeyBinding), so it holds after a restart
-- and the game's own Options shows it. "Reset to the game's keys" asks once (the button says so), then puts back
-- every key the game ships with.
--
-- Opened from each window's menu (Keyboard map) and the survival guide's keys page. Escape, B or the close box close
-- it. The body scrolls as one piece (the wheel, the D-pad); the keys themselves are a keyboard's to change.
-- ============================================================================
require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Organisms"
ZeD = ZeD or {}
ZeD.KeyboardMap = ZeD.KeyboardMap or {}
local KM = ZeD.KeyboardMap
KM.windows = KM.windows or {}
KM.FILE = "keysB42.ini"   -- (the game's own key file, MainOptions.saveKeys)

local W_U = 480          -- the full card's width (design units)
local STEP_U = 40        -- one D-pad press of scroll
local RESET_ASK_MS = 4000

-- (the words: UI_ZeD_KMap_* in Translate/<LANG>/UI.json)

-- ---------------------------------------------------------------------------
-- THE KEYBOARD: rows of { label, width in key units, key code name on Keyboard } (nil: a gap)
-- ---------------------------------------------------------------------------
local function K(label, w, code) return { label, w, code } end
KM.ROWS = {
    { K("Esc", 1, "KEY_ESCAPE"), K(nil, 0.5), K("F1", 1, "KEY_F1"), K("F2", 1, "KEY_F2"), K("F3", 1, "KEY_F3"), K("F4", 1, "KEY_F4"),
      K(nil, 0.5), K("F5", 1, "KEY_F5"), K("F6", 1, "KEY_F6"), K("F7", 1, "KEY_F7"), K("F8", 1, "KEY_F8"), K(nil, 0.5),
      K("F9", 1, "KEY_F9"), K("F10", 1, "KEY_F10"), K("F11", 1, "KEY_F11"), K("F12", 1, "KEY_F12") },
    { K("`", 1, "KEY_GRAVE"), K("1", 1, "KEY_1"), K("2", 1, "KEY_2"), K("3", 1, "KEY_3"), K("4", 1, "KEY_4"), K("5", 1, "KEY_5"),
      K("6", 1, "KEY_6"), K("7", 1, "KEY_7"), K("8", 1, "KEY_8"), K("9", 1, "KEY_9"), K("0", 1, "KEY_0"), K("-", 1, "KEY_MINUS"),
      K("=", 1, "KEY_EQUALS"), K("Back", 2, "KEY_BACK") },
    { K("Tab", 1.5, "KEY_TAB"), K("Q", 1, "KEY_Q"), K("W", 1, "KEY_W"), K("E", 1, "KEY_E"), K("R", 1, "KEY_R"), K("T", 1, "KEY_T"),
      K("Y", 1, "KEY_Y"), K("U", 1, "KEY_U"), K("I", 1, "KEY_I"), K("O", 1, "KEY_O"), K("P", 1, "KEY_P"), K("[", 1, "KEY_LBRACKET"),
      K("]", 1, "KEY_RBRACKET"), K("\\", 1.5, "KEY_BACKSLASH") },
    { K("Caps", 1.75, "KEY_CAPITAL"), K("A", 1, "KEY_A"), K("S", 1, "KEY_S"), K("D", 1, "KEY_D"), K("F", 1, "KEY_F"),
      K("G", 1, "KEY_G"), K("H", 1, "KEY_H"), K("J", 1, "KEY_J"), K("K", 1, "KEY_K"), K("L", 1, "KEY_L"),
      K(";", 1, "KEY_SEMICOLON"), K("'", 1, "KEY_APOSTROPHE"), K("Enter", 2.25, "KEY_RETURN") },
    { K("Shift", 2.25, "KEY_LSHIFT"), K("Z", 1, "KEY_Z"), K("X", 1, "KEY_X"), K("C", 1, "KEY_C"), K("V", 1, "KEY_V"),
      K("B", 1, "KEY_B"), K("N", 1, "KEY_N"), K("M", 1, "KEY_M"), K(",", 1, "KEY_COMMA"), K(".", 1, "KEY_PERIOD"),
      K("/", 1, "KEY_SLASH"), K("Shift", 2.75, "KEY_RSHIFT") },
    { K("Ctrl", 1.5, "KEY_LCONTROL"), K(nil, 1), K("Alt", 1.5, "KEY_LMENU"), K("Space", 7, "KEY_SPACE"),
      K("Alt", 1.5, "KEY_RMENU"), K(nil, 1), K("Ctrl", 1.5, "KEY_RCONTROL") },
}
local ROW_UNITS = 15     -- the widest row, in key units

local function code(name)
    local ok, v = pcall(function() return Keyboard[name] end)
    return ok and v or nil
end

-- ---------------------------------------------------------------------------
-- THE BINDINGS: the game's own list (keyBinding, shared/keyBinding.lua), as set now
-- ---------------------------------------------------------------------------
local function tr(k, ...) return ZeD.tr(k, ...) end
local function bindName(v)
    return getTextOrNull("UI_optionscreen_binding_" .. v) or v
end
local function keyLabel(c)
    if not c or c == 0 then return tr("UI_ZeD_KMap_None") end
    local ok, n = pcall(function() return getKeyName(c) end)   -- (the game's own, as its Options names keys)
    return (ok and n and n ~= "") and n or tostring(c)
end

-- (QA's bug hunt KM-3, Nov 20 2026: a binding saved with Shift, Ctrl or Alt held keeps it, and the map showed only the
-- key. The file's own line says which; the key box reads "Shift+H" and so on.)
local _modsAt, _mods = -1, {}
local function modsOf(name)
    local now = getTimestampMs()
    if now - _modsAt > 1000 then
        _modsAt, _mods = now, {}
        local ok, r = pcall(function() return getFileReader(KM.FILE, false) end)
        if ok and r then
            pcall(function()
                local l = r:readLine()
                while l do
                    local n, rest = l:match("^([^=]+)=(.*)$")
                    if n then
                        local p = ""
                        if rest:find("ctrl:true", 1, true) then p = p .. "Ctrl+" end
                        if rest:find("shift:true", 1, true) then p = p .. "Shift+" end
                        if rest:find("alt:true", 1, true) then p = p .. "Alt+" end
                        if p ~= "" then _mods[n] = p end
                    end
                    l = r:readLine()
                end
            end)
            pcall(function() r:close() end)
        end
    end
    return _mods[name] or ""
end
KM.modsOf = modsOf

-- (QA's bug hunt KM-2, Nov 20 2026: on a French AZERTY keyboard the game's own keys are not keyBinding's: it moves four
-- of them as it loads (MainOptions, "a=q, etc."). Reset wrote the QWERTY keys, and the map drew the game's own pairs
-- in the bad color. The game's own swap is used for both.)
local AZERTY = { Left = 16, Forward = 44, Shout = 30, VehicleHorn = 30 }
local function defaultKey(b)
    local ok, az = pcall(function() return getCore():isAzerty() end)
    if ok and az and AZERTY[tostring(b.value)] then return AZERTY[tostring(b.value)] end
    return b.key or 0
end

--- { groups = { { title, rows = { { name, label, code } } } }, used = { [code] = count }, clash = { [code] = true } }
function KM.read()
    local out = { groups = {}, used = {}, clash = {} }
    local defaultsOf, nowOf = {}, {}
    local g = nil
    for _, b in ipairs(keyBinding or {}) do
        local v = b.value and tostring(b.value) or ""
        if v:find("^%[") then
            g = { title = getTextOrNull("UI_optionscreen_binding_" .. v:gsub("%[", ""):gsub("%]", "")) or v, rows = {} }
            out.groups[#out.groups + 1] = g
        elseif v ~= "" and g then
            local ok, c = pcall(function() return getCore():getKey(v) end)
            c = ok and c or 0
            g.rows[#g.rows + 1] = { name = v, label = bindName(v), code = c }
            if c ~= 0 then
                nowOf[c] = nowOf[c] or {}
                table.insert(nowOf[c], v)
                out.used[c] = (out.used[c] or 0) + 1
            end
            local dk = defaultKey(b)
            if dk ~= 0 then
                defaultsOf[dk] = defaultsOf[dk] or {}
                defaultsOf[dk][v] = true
            end
        end
    end
    -- a clash: two jobs on one key that the game's own keys never put together (the game shares some on purpose,
    -- the horn and shout among them; those are not the player's to fix)
    for c, names in pairs(nowOf) do
        if #names > 1 then
            for i = 1, #names do
                for j = i + 1, #names do
                    local same = false
                    for _, set in pairs(defaultsOf) do
                        if set[names[i]] and set[names[j]] then same = true; break end
                    end
                    if not same then out.clash[c] = true end
                end
            end
        end
    end
    return out
end

-- ---------------------------------------------------------------------------
-- SAVING: keysB42.ini as the game's Options writes it, and the game told at once
-- ---------------------------------------------------------------------------
local function readLines()
    local ok, r = pcall(function() return getFileReader(KM.FILE, false) end)
    if not (ok and r) then return nil end
    local lines = {}
    pcall(function()
        local l = r:readLine()
        while l do lines[#lines + 1] = l; l = r:readLine() end
    end)
    pcall(function() r:close() end)
    return (#lines > 0) and lines or nil
end
local function writeLines(lines)
    local ok, w = pcall(function() return getFileWriter(KM.FILE, true, false) end)
    if not (ok and w) then return false end
    local wrote = pcall(function() for _, l in ipairs(lines) do w:write(l .. "\r\n") end end)
    pcall(function() w:close() end)
    return wrote
end
local function lineOf(name, c, alt, shift, ctrl, altK)
    local s = name .. "=key:" .. tostring(c or 0)
    if alt and alt > 0 then s = s .. ";altCode:" .. tostring(alt) end
    if shift then s = s .. ";shift:true" end
    if ctrl then s = s .. ";ctrl:true" end
    if altK then s = s .. ";alt:true" end
    return s
end
local function parse(l)
    local name, rest = l:match("^([^=]+)=(.*)$")
    if not name then return nil end
    return name, tonumber(rest:match("key:(%d+)")) or 0, tonumber(rest:match("altCode:(%d+)")) or 0,
        rest:find("shift:true", 1, true) ~= nil, rest:find("ctrl:true", 1, true) ~= nil, rest:find("alt:true", 1, true) ~= nil
end
local function keysVersion() return (MainOptions and MainOptions.KEYS_VERSION) or 2 end
-- the file as the game would write it now (no file yet: the bindings as they stand)
local function currentLines()
    local lines = { "VERSION=" .. tostring(keysVersion()) }
    for _, b in ipairs(keyBinding or {}) do
        local v = b.value and tostring(b.value) or ""
        if v:find("^%[") then lines[#lines + 1] = v
        elseif v ~= "" then
            local ok, c = pcall(function() return getCore():getKey(v) end)
            lines[#lines + 1] = lineOf(v, ok and c or 0, b.alt, b.shift, b.ctrl, b.altKey)
        end
    end
    return lines
end

-- (QA's bug hunt KM-1, Nov 20 2026: the game's Options screen keeps its own list of keys, MainOptions.keyText, and its
-- Apply writes keysB42.ini from that list, so a key changed here came undone at the next Apply. Each change is put into
-- that list too, the button's words with it.)
local function syncOptions(name, c, alt, shift, ctrl, altK)
    local list = MainOptions and MainOptions.keyText
    if not list then return end
    for _, v in ipairs(list) do
        local ok, n = pcall(function() return v.txt and v.txt:getName() end)
        if ok and n == name then
            v.keyCode = c
            if alt ~= nil then v.altCode = alt end
            if shift ~= nil then v.shift, v.ctrl, v.alt = shift, ctrl, altK end
            pcall(function()
                if v.btn and MainOptions.getKeyPrefix then v.btn:setTitle(MainOptions.getKeyPrefix(v) .. getKeyName(c)) end
            end)
        end
    end
end

--- One action onto a key: the file and the game. True when it took.
function KM.setKey(name, c)
    local lines = readLines() or currentLines()
    local found = false
    local alt, shift, ctrl, altK = 0, false, false, false
    for i, l in ipairs(lines) do
        local n, _, a, s, ct, ak = parse(l)
        if n == name then
            -- (a key pressed here is the key alone: Shift, Ctrl and Alt are cleared, so the map, the file and the game
            -- agree; the alternate stays)
            alt, shift, ctrl, altK = a, false, false, false
            lines[i] = lineOf(name, c, a, false, false, false)
            _modsAt = -1
            found = true
            break
        end
    end
    if not found then lines[#lines + 1] = lineOf(name, c, 0, false, false, false) end
    local ok = pcall(function() getCore():addKeyBinding(name, c, alt, shift, ctrl, altK) end)
    writeLines(lines)
    syncOptions(name, c, alt, shift, ctrl, altK)
    return ok
end

--- Every key back to the game's own (keyBinding's), the file and the game.
function KM.resetAll()
    local lines = { "VERSION=" .. tostring(keysVersion()) }
    for _, b in ipairs(keyBinding or {}) do
        local v = b.value and tostring(b.value) or ""
        if v:find("^%[") then lines[#lines + 1] = v
        elseif v ~= "" then
            local c = defaultKey(b)
            pcall(function() getCore():addKeyBinding(v, c, b.alt or 0, b.shift or false, b.ctrl or false, b.altKey or false) end)
            syncOptions(v, c, b.alt or 0, b.shift or false, b.ctrl or false, b.altKey or false)
            lines[#lines + 1] = lineOf(v, c, b.alt, b.shift, b.ctrl, b.altKey)
        end
    end
    writeLines(lines)
end

-- ---------------------------------------------------------------------------
-- THE WINDOW
-- ---------------------------------------------------------------------------
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end

ZeD_KeyboardMap = ZeD_Window:derive("ZeD_KeyboardMap")

function ZeD_KeyboardMap:new(playerNum)
    local o = ZeD_Window.new(self, 0, 0, 100, 100, "")
    o.resizable = false
    o.pin = true
    o.anchorLeft, o.anchorRight, o.anchorTop, o.anchorBottom = true, false, true, false
    o.moveWithMouse = false
    o.playerNum = playerNum or 0
    o.scroll = 0
    o._contentH = 0
    o._hits = {}
    o._down = nil
    o.listening = nil      -- the action waiting for its key
    o.picked = nil         -- the key clicked on the drawing
    o._resetAt = nil       -- when Reset was pressed once
    o:setWantKeyEvents(true)
    return o
end

function ZeD_KeyboardMap:createChildren()
    ZeD_Window.createChildren(self)
    self.minimumWidth, self.minimumHeight = 0, 0
end

-- (QA's bug hunt P6, Nov 20 2026: the key that answers the map also did its job in the game, a shout for Q, a window
-- for Tab. While an action waits for its key, and until the key that answered is let go, the game's Lua key events
-- are off, as the game's own Options does it; they come back on at every way out. Read each update, and at once
-- wherever the wait starts or ends.)
local function syncKeys(self)
    local held = self._heldKey and isKeyDown(self._heldKey)
    if not held then self._heldKey = nil end
    local off = self:getIsVisible() and (self.listening ~= nil or held) and true or false
    if off ~= (self._keysOff or false) then
        self._keysOff = off
        pcall(function() GameKeyboard.setDoLuaKeyPressed(not off) end)
    end
end

function ZeD_KeyboardMap:close()
    self.listening = nil
    self._heldKey = nil
    if self._keysOff then self._keysOff = false; pcall(function() GameKeyboard.setDoLuaKeyPressed(true) end) end
    self:setVisible(false)
    self:removeFromUIManager()
    local jd = JoypadState.players[self.playerNum + 1]
    if jd and jd.focus == self then setJoypadFocus(self.playerNum, nil) end
end

local function badRGB()
    local M = ZeD.Molecules
    if M and M.liteColor then return M.liteColor("bad") end
    return 0.9, 0.25, 0.25
end

-- one key cap: rounded, its label at the top left
local function drawCap(panel, x, y, w, h, label, lit, clash, picked)
    local T, A = ZeD.T, ZeD.Atoms
    local fill = picked and T.accent or (lit and T.surf3 or T.surf2)
    A.fillRounded(panel, x, y, w, h, fill.r, fill.g, fill.b, picked and T.selectionA or (fill.a or 1))
    local br, bg, bb = T.borderS.r, T.borderS.g, T.borderS.b
    if clash then br, bg, bb = badRGB()
    elseif lit then br, bg, bb = T.accent.r, T.accent.g, T.accent.b end
    A.borderRounded(panel, x, y, w, h, br, bg, bb, 1)
    if lit or clash then A.borderRounded(panel, x + T.hair, y + T.hair, w - 2 * T.hair, h - 2 * T.hair, br, bg, bb, 1) end
    local tc = (lit or clash) and T.text or T.textDim
    panel:drawText(label, x + T.px(3), y + T.px(2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF1)
end

function ZeD_KeyboardMap:prerender()
    local T = ZeD.T
    if not T then return end
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local w = math.min(T.px(W_U), sw - T.px(20))
    local margin = T.px(14)
    local tbH = self:titleBarHeight()
    local fH = self:footerHeight()
    local inner = w - 2 * margin
    local tm = ZeD.TM
    local f1, f2 = T.fontF1, T.fontF2
    local fh1, fh2 = tm:getFontHeight(f1), tm:getFontHeight(f2)
    local data = KM.read()
    self._data = data
    -- the keyboard's size: a key unit from the inner width
    local ku = math.floor(inner / ROW_UNITS)
    local gap = T.px(2)
    local kbH = #KM.ROWS * ku + T.px(6)
    local legend = ZeD.Atoms.wrapText(tr("UI_ZeD_KMap_Legend"), f2, inner)
    local rowH = math.max(T.buttonH, fh2) + T.px(4)
    local total = margin + kbH + T.px(6) + #legend * fh2 + T.px(8) + T.buttonH + T.px(10)
    for _, g in ipairs(data.groups) do total = total + fh1 + T.px(8) + #g.rows * rowH + T.px(6) end
    total = total + margin
    self._contentH = total
    local bodyH = math.min(total, sh - tbH - fH - T.px(40))
    local h = tbH + bodyH + fH
    if self.width ~= w or self.height ~= h then
        self:setWidth(w); self:setHeight(h)
        self:setX(math.floor((sw - w) / 2))
        self:setY(math.floor((sh - h) / 2))
    end
    self.title = tr("UI_ZeD_KMap_Title")
    self._bodyH = bodyH
    self.scroll = math.max(0, math.min(self.scroll or 0, total - bodyH))
    self.minimumWidth, self.minimumHeight = 0, 0
    ZeD_Window.prerender(self)
    self.minimumWidth, self.minimumHeight = 0, 0
    local listenRow = nil
    if self.listening then
        for _, g in ipairs(data.groups) do for _, r in ipairs(g.rows) do if r.name == self.listening then listenRow = r end end end
    end
    ZeD.Help.set(self, listenRow and tr("UI_ZeD_KMap_Listening", listenRow.label) or tr("UI_ZeD_KMap_Help"))

    local hits = self._hits
    for i = #hits, 1, -1 do hits[i] = nil end
    local mx, my = self:getMouseX(), self:getMouseY()
    self:setStencilRect(0, tbH, w, bodyH)
    local y = tbH + margin - self.scroll
    -- the keyboard
    for r, row in ipairs(KM.ROWS) do
        local x = margin
        for _, k in ipairs(row) do
            local kw = math.floor(k[2] * ku)
            if k[1] then
                local c = code(k[3])
                local lit = c and (data.used[c] or 0) > 0
                drawCap(self, x, y, kw - gap, ku - gap, k[1], lit, c and data.clash[c], c ~= nil and c == self.picked)
                if c then hits[#hits + 1] = { id = "cap", code = c, x = x, y = y, w = kw - gap, h = ku - gap } end
            end
            x = x + kw
        end
        y = y + ku + ((r == 1) and T.px(6) or 0)
    end
    y = y + T.px(6)
    local td = T.textDim
    for _, l in ipairs(legend) do
        self:drawText(l, margin, y, td.r, td.g, td.b, td.a or 1, f2)
        y = y + fh2
    end
    y = y + T.px(8)
    -- Reset, at the right
    local sure = self._resetAt and (getTimestampMs() - self._resetAt) < RESET_ASK_MS
    local rWord = tr(sure and "UI_ZeD_KMap_ResetSure" or "UI_ZeD_KMap_Reset")
    local rw = ZeD.Molecules.buttonW(rWord)
    local rx = margin + inner - rw
    ZeD.Molecules.drawButton(self, rx, y, rw, T.buttonH, rWord, sure and "danger" or "default", self._down == "reset",
        nil, { hover = inRect({ x = rx, y = y, w = rw, h = T.buttonH }, mx, my) })
    hits[#hits + 1] = { id = "reset", x = rx, y = y, w = rw, h = T.buttonH }
    y = y + T.buttonH + T.px(10)
    -- the actions, in the game's groups
    local boxW = T.px(110)
    local tc = T.text
    for _, g in ipairs(data.groups) do
        local ac = T.accent
        self:drawText(g.title, margin, y, ac.r, ac.g, ac.b, ac.a or 1, f1)
        y = y + fh1 + T.px(8)
        for _, r in ipairs(g.rows) do
            local on = self.picked ~= nil and r.code == self.picked
            if on then
                local s = T.accent
                self:drawRect(margin, y - T.px(2), inner, rowH, T.selectionA, s.r, s.g, s.b)
            end
            self:drawText(r.label, margin, y + math.floor((rowH - T.px(4) - fh2) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
            local bx = margin + inner - boxW
            local listening = self.listening == r.name
            local word = listening and tr("UI_ZeD_KMap_Press") or (((r.code ~= 0) and modsOf(r.name) or "") .. keyLabel(r.code))
            local colors = nil
            if listening then colors = { fill = { r = T.accent.r, g = T.accent.g, b = T.accent.b, a = T.selectionA } }
            elseif r.code ~= 0 and data.clash[r.code] then
                local br, bg, bb = badRGB()
                colors = { border = { r = br, g = bg, b = bb, a = 1 } }
            end
            local box = { x = bx, y = y, w = boxW, h = T.buttonH }
            ZeD.Molecules.drawButton(self, bx, y, boxW, T.buttonH, word, "default", false, colors,
                { hover = inRect(box, mx, my), compact = true })
            hits[#hits + 1] = { id = "bind", name = r.name, x = bx, y = y, w = boxW, h = T.buttonH }
            y = y + rowH
        end
        y = y + T.px(6)
    end
    self:clearStencilRect()
    if total > bodyH then
        local ac = T.accent
        local th = math.max(T.px(20), math.floor(bodyH * bodyH / total))
        local ty = tbH + math.floor((bodyH - th) * self.scroll / (total - bodyH))
        self:drawRect(w - T.px(4), ty, T.px(2), th, 0.8, ac.r, ac.g, ac.b)
    end
end

function ZeD_KeyboardMap:render() ZeD_Window.render(self) end

-- always solid: a page to read
function ZeD_KeyboardMap:_surfaceAlpha(T)
    local base = (T.surf1 and T.surf1.a) or 1
    if base >= 0.999 then return nil end
    return 1
end

function ZeD_KeyboardMap:getFooterPrompts()
    if not self.joyfocus then return nil end
    local out = {}
    if (self._contentH or 0) > (self._bodyH or 0) then out[#out + 1] = { glyph = "D-PAD", label = tr("UI_ZeD_CMap_Scroll") } end
    out[#out + 1] = { glyph = "B", label = tr("UI_ZeD_Close") }
    return out
end

function ZeD_KeyboardMap:update()
    ZeD_Window.update(self)
    syncKeys(self)
    if not self:getIsVisible() then return end
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    self.joyfocus = (jd and jd.focus == self) and jd or nil
end

function ZeD_KeyboardMap:scrollBy(d)
    local maxS = math.max(0, (self._contentH or 0) - (self._bodyH or 0))
    self.scroll = math.max(0, math.min(maxS, (self.scroll or 0) + d))
end

local function hitAt(self, x, y)
    local tb = self:titleBarHeight()
    if y < tb or y > tb + (self._bodyH or 0) then return nil end
    for i = #self._hits, 1, -1 do
        local h = self._hits[i]
        if inRect(h, x, y) then return h end
    end
    return nil
end

function ZeD_KeyboardMap:onMouseDown(x, y)
    local cb = self:closeRect()
    if cb and inRect(cb, x, y) then self._down = "close"; return true end
    local h = hitAt(self, x, y)
    self._down = h and h.id or nil
    return true
end
function ZeD_KeyboardMap:onMouseUp(x, y)
    local down = self._down
    self._down = nil
    if down == "close" then
        local cb = self:closeRect()
        if cb and inRect(cb, x, y) then pcall(function() ZeD.uiSound("UIActivateButton") end); self:close() end
        return true
    end
    local h = hitAt(self, x, y)
    if not (h and h.id == down) then return true end
    pcall(function() ZeD.uiSound("UIActivateButton") end)
    if h.id == "cap" then
        self.picked = (self.picked == h.code) and nil or h.code
    elseif h.id == "bind" then
        self.listening = (self.listening == h.name) and nil or h.name
        syncKeys(self)
    elseif h.id == "reset" then
        local since = self._resetAt and (getTimestampMs() - self._resetAt) or nil
        if since and since >= 300 and since < RESET_ASK_MS then   -- (QA's bug hunt P1: a double-click is not "again")
            self._resetAt = nil
            self.listening = nil
            syncKeys(self)
            KM.resetAll()
        else
            self._resetAt = getTimestampMs()
        end
    end
    return true
end
function ZeD_KeyboardMap:onMouseUpOutside() self._down = nil end
function ZeD_KeyboardMap:onMouseWheel(del) self:scrollBy(del * ZeD.T.px(STEP_U)); return true end

-- while an action waits for its key, every key is this window's (the next one pressed is the answer)
function ZeD_KeyboardMap:isKeyConsumed(key) return self.listening ~= nil or key == Keyboard.KEY_ESCAPE end
function ZeD_KeyboardMap:onKeyPress(key)
    if self.listening then
        local name = self.listening
        self.listening = nil
        self._heldKey = key     -- (the game's keys stay off till this one is let go: P6)
        if key ~= Keyboard.KEY_ESCAPE then KM.setKey(name, key) end
        pcall(function() GameKeyboard.eatKeyPress(key) end)
        return
    end
    if key == Keyboard.KEY_ESCAPE then self:close(); pcall(function() GameKeyboard.eatKeyPress(key) end) end
end

function ZeD_KeyboardMap:onGainJoypadFocus(jd) self.joyfocus = jd end
function ZeD_KeyboardMap:onLoseJoypadFocus() self.joyfocus = nil end
function ZeD_KeyboardMap:onJoypadDown(button, jd)
    if ZeD.padStart and ZeD.padStart(button, jd, self.playerNum) then return end   -- (Start pauses: QA's bug hunt 7)
    if button == Joypad.BButton then self:close() end
end
function ZeD_KeyboardMap:onJoypadDirUp() self:scrollBy(-ZeD.T.px(STEP_U)) end
function ZeD_KeyboardMap:onJoypadDirDown() self:scrollBy(ZeD.T.px(STEP_U)) end

-- ---------------------------------------------------------------------------
-- ENTRY
-- ---------------------------------------------------------------------------
function KM.open(pn)
    pn = pn or 0
    local win = KM.windows[pn]
    if not win then
        win = ZeD_KeyboardMap:new(pn)
        win:initialise()
        win:instantiate()
        KM.windows[pn] = win
    end
    win.scroll, win.listening, win.picked, win._resetAt = 0, nil, nil, nil
    if not win:isReallyVisible() then
        win:setVisible(true)
        win:addToUIManager()
        win:setAlwaysOnTop(true)
    end
    local jd = JoypadState.players[pn + 1]
    if jd then jd.focus = win; updateJoypadFocus(jd) end
    return win
end

function KM.close(pn)
    local win = KM.windows[pn or 0]
    if win and win:isReallyVisible() then win:close() end
end

-- Escape from anywhere: the map on screen closes (but a key being set takes Escape as its answer first)
function KM.takeEscape()
    for _, win in pairs(KM.windows) do
        if win and win:isReallyVisible() then
            if win.listening then win.listening = nil; syncKeys(win) else win:close() end
            return true
        end
    end
    return false
end
ZeD.EscapeTakers = ZeD.EscapeTakers or {}
ZeD.EscapeTakers.keyboardMap = KM.takeEscape

-- (P6's safety: a map taken off screen some other way, mid-wait, gives the game its keys back; a window that no
-- longer draws never runs its own update)
if Events and Events.OnTick then
    Events.OnTick.Add(function()
        for _, win in pairs(KM.windows) do
            if win and win._keysOff and not win:isReallyVisible() then
                win._keysOff, win.listening, win._heldKey = false, nil, nil
                pcall(function() GameKeyboard.setDoLuaKeyPressed(true) end)
            end
        end
    end)
end

return KM
