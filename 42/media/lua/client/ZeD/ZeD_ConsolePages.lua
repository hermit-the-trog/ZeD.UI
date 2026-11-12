-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ConsolePages.lua
-- ============================================================================
-- THE LUA CONSOLE'S OTHER PAGES: Help (and Commands), drawn into the console window from its page strip.
-- Client. Part of the ZeD_DebugConsoleWindow organism: this file adds the window's page methods (_drawPage,
-- _pageDir, _pageButton and the rest), which ZeD_DebugConsole.lua calls whenever the page is not the log.
--
-- Help is one scrolling page of fold headers: what runs where, the keys, the controller, the files. Its band has
-- one keycap, Back to the log. Controller: the hand walks the fold headers (A folds one), then the band; D-pad left
-- from the page goes to the strip.
--
-- The one thing to know: the page draws inside the window's own prerender, so everything it measures is kept per
-- width and text size and laid out again only when one of them, or a fold, changes.
-- ============================================================================

require "ZeD/ZeD_DebugConsole"

local DC = ZeD.DebugConsole
local W = ZeD_DebugConsoleWindow
local UI = DC.ui
local U = UI.U
local S = ZeD.ConsoleScratch

local function tr(k, ...) return ZeD.tr(k, ...) end
local function px(n) return ZeD.T.px(n) end
local function fh(font) return ZeD.TM:getFontHeight(font) end
local function inRect(r, x, y) return r ~= nil and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(name) pcall(function() getSoundManager():playUISound(name or "UISelectListItem") end) end
local function btn(s) return ZeD.btnCase and ZeD.btnCase(s) or s end

-- ---------------------------------------------------------------------------
-- HELP: its sections (the key names and file paths stay as written; the words are translated)
-- ---------------------------------------------------------------------------
-- the game's key for its console, by name (Toggle Lua Console in its key options; "`" when it can't be read)
local function toggleKey()
    local ok, name = pcall(function() return Keyboard.getKeyName(getCore():getKey("Toggle Lua Console")) end)
    if ok and name ~= nil and tostring(name) ~= "" then return tostring(name) end
    return "`"
end

local HELP = {
    { id = "where", key = "UI_ZeD_Console_HelpFoldWhere",
      paras = { "UI_ZeD_Console_HelpWhere1", "UI_ZeD_Console_HelpWhere2", "UI_ZeD_Console_HelpWhere3",
                "UI_ZeD_Console_HelpWhere4", "UI_ZeD_Console_HelpWhere5" } },
    { id = "keys", key = "UI_ZeD_Console_HelpFoldKeys",
      rows = { { k = toggleKey, d = "UI_ZeD_Console_HelpKeyToggle" }, { k = "Enter", d = "UI_ZeD_Console_HelpKeyEnter" },
               { k = "Shift+Enter", d = "UI_ZeD_Console_HelpKeyShiftEnter" }, { k = "Up / Down", d = "UI_ZeD_Console_HelpKeyUpDown" },
               { k = "Tab", d = "UI_ZeD_Console_HelpKeyTab" }, { k = "Esc", d = "UI_ZeD_Console_HelpKeyEsc" },
               { k = "F11", d = "UI_ZeD_Console_HelpKeyF11" } } },
    { id = "pad", key = "UI_ZeD_Console_HelpFoldPad",
      rows = { { k = "D-pad", d = "UI_ZeD_Console_HelpPadDpad" }, { k = "A", d = "UI_ZeD_Console_HelpPadA" },
               { k = "B", d = "UI_ZeD_Console_HelpPadB" }, { k = "X", d = "UI_ZeD_Console_HelpPadX" },
               { k = "Y", d = "UI_ZeD_Console_HelpPadY" }, { k = "LB / RB", d = "UI_ZeD_Console_HelpPadBumpers" } } },
    { id = "files", key = "UI_ZeD_Console_HelpFoldFiles",
      rows = { { k = "Zomboid/Lua/ZeD_console_*.log", d = "UI_ZeD_Console_HelpFileExport" },
               { k = "Zomboid/Lua/" .. S.SNIP_FILE, d = "UI_ZeD_Console_HelpFileSnippets" },
               { k = "Zomboid/Lua/" .. S.HIST_FILE, d = "UI_ZeD_Console_HelpFileHistory", arg = S.HIST_CAP } } },
}
DC.HELP = HELP

local function sectionCount(sec) return #(sec.paras or sec.rows or {}) end

-- the page laid out at a width: a flat list of { t = "fold" | "para" | "row", y, h, ... } and its whole height
function W:_helpLayout(w)
    local T = ZeD.T
    self.hFold = self.hFold or {}
    local f2, f3 = T.fontF2, T.fontF3
    local key = tostring(w) .. "|" .. tostring(f2) .. "|" .. tostring(T.scale) .. "|" .. tostring(fh(f2))
    for _, sec in ipairs(HELP) do key = key .. (self.hFold[sec.id] and "1" or "0") end
    if self._hKey == key and self._hItems then return self._hItems, self._hTotal end
    local A = ZeD.Atoms
    local items = {}
    local y = px(6)
    local foldH = px(U.FOLD)
    local step2, step3 = fh(f2) + px(2), fh(f3) + px(2)
    local indent = px(24)
    local textW = math.max(px(40), w - indent - px(14))
    local keyW = math.min(px(170), math.floor(textW * 0.4))
    for si, sec in ipairs(HELP) do
        if si > 1 then y = y + px(6) end
        items[#items + 1] = { t = "fold", sec = sec, si = si, y = y, h = foldH }
        y = y + foldH + px(4)
        if not self.hFold[sec.id] then
            if sec.paras then
                for _, pk in ipairs(sec.paras) do
                    local lines = A.wrapText(tr(pk), f2, textW)
                    items[#items + 1] = { t = "para", lines = lines, y = y, h = #lines * step2 }
                    y = y + #lines * step2 + px(6)
                end
            else
                for _, r in ipairs(sec.rows) do
                    local k = type(r.k) == "function" and r.k() or r.k
                    local kl = A.wrapText(k, f3, keyW - px(8))
                    local d = r.arg ~= nil and tr(r.d, r.arg) or tr(r.d)
                    local dl = A.wrapText(d, f2, textW - keyW - px(12))
                    local h = math.max(#kl * step3, #dl * step2)
                    items[#items + 1] = { t = "row", kl = kl, dl = dl, keyW = keyW, y = y, h = h }
                    y = y + h + px(2)
                end
            end
        end
    end
    self._hKey, self._hItems, self._hTotal = key, items, y + px(8)
    return items, self._hTotal
end

-- the fold headers' items, in order (the controller's stops)
local function helpFolds(items)
    local out = {}
    for _, it in ipairs(items) do if it.t == "fold" then out[#out + 1] = it end end
    return out
end

function W:_drawHelp(x, y, w, h, joy)
    local T = ZeD.T
    local M = ZeD.Molecules
    local sbW = T.sp.scrollbarW
    local items, total = self:_helpLayout(w - sbW)
    self.hScroll = self.hScroll or 0
    self.hFocus = self.hFocus or 1
    local folds = helpFolds(items)
    if self.hFocus > #folds then self.hFocus = #folds end
    -- the controller's header brought into view
    if self.hSeek then
        self.hSeek = nil
        local it = folds[self.hFocus]
        if it then
            if it.y < self.hScroll then self.hScroll = it.y
            elseif it.y + it.h > self.hScroll + h then self.hScroll = it.y + it.h - h end
        end
    end
    local maxS = math.max(0, total - h)
    self.hScroll = math.max(0, math.min(maxS, self.hScroll))
    self._hMax = maxS
    local iw = w - (total > h and sbW or 0)
    local mx, my = self:getMouseX(), self:getMouseY()
    if joy then mx, my = nil, nil end
    self._hHits = {}
    self:setStencilRect(x, y, iw, h)
    local f2, f3 = T.fontF2, T.fontF3
    local step2, step3 = fh(f2) + px(2), fh(f3) + px(2)
    local tc, kc = T.text, T.text
    local fi = 0
    for _, it in ipairs(items) do
        local yy = y + it.y - self.hScroll
        if it.t == "fold" then fi = fi + 1 end
        if yy + it.h > y and yy < y + h then
            if it.t == "fold" then
                local hover = mx ~= nil and mx >= x and mx < x + iw and my >= yy and my < yy + it.h and my >= y and my < y + h
                local foc = joy and self.zone == "page" and self.hFocus == fi
                M.drawSectionHeader(self, x + px(8), yy, iw - px(8), tr(it.sec.key), sectionCount(it.sec), not self.hFold[it.sec.id], hover, nil, true, px(8), it.h, nil,
                    foc and { focus = UI.focusOpts(self) } or nil)
                self._hHits[#self._hHits + 1] = { y = yy, h = it.h, id = it.sec.id, fi = fi }
            elseif it.t == "para" then
                for i, s in ipairs(it.lines) do
                    self:drawText(s, x + px(24), yy + (i - 1) * step2, tc.r, tc.g, tc.b, tc.a or 1, f2)
                end
            else
                for i, s in ipairs(it.kl) do
                    self:drawText(s, x + px(24), yy + (i - 1) * step3 + math.floor((step2 - step3) / 2), kc.r, kc.g, kc.b, kc.a or 1, f3)
                end
                for i, s in ipairs(it.dl) do
                    self:drawText(s, x + px(24) + it.keyW + px(12), yy + (i - 1) * step2, tc.r, tc.g, tc.b, tc.a or 1, f2)
                end
            end
        end
    end
    self:clearStencilRect()
    if total > h then
        local win = self
        M.scrollBar(self, nil, "help", x + w - sbW, y, sbW, h, self.hScroll, total, function(v) win.hScroll = v end, { step = step2 })
    end
    self._hRect = { x = x, y = y, w = iw, h = h }
end

-- a fold header folded or opened
function W:helpFold(id)
    self.hFold = self.hFold or {}
    if self.hFold[id] then self.hFold[id] = nil else self.hFold[id] = true end
    sound()
end

-- ---------------------------------------------------------------------------
-- THE PAGE HOOKS the window calls (page ~= "log")
-- ---------------------------------------------------------------------------
local _hBtns = { { id = "tolog", variant = "primary" } }
local _hSpec = { buttons = _hBtns }

function W:_drawPage(x, top, w, h, bandY, joy)
    if self.page == "help" then
        self:_drawHelp(x, top, w, h, joy)
        local b = _hBtns[1]
        b.label = btn(tr("UI_ZeD_Console_BackToLog"))
        b.focus = (joy and self.zone == "pband") and UI.focusOpts(self) or nil
        b.pressed = self._down == b.id
        if joy then b.hover = false else b.hover = nil end
        _hSpec.win = self
        local _, out = ZeD.Molecules.drawBand(self, 0, bandY, self.width, _hSpec)
        self._bandRects = out and out.buttons or {}
    elseif self._drawCmds then
        self:_drawCmds(x, top, w, h, bandY, joy)
    else
        ZeD.Molecules.drawEmptyLine(self, x + px(16), top + px(16), w - px(32), tr("UI_ZeD_Console_Coming"))
    end
end

function W:_pageStatus()
    if self.page == "help" then return tr("UI_ZeD_Console_HelpPage") end
    if self._cmdStatus then return self:_cmdStatus() end
    return ""
end

function W:_pageMouseDown(x, y)
    if self.page == "help" then
        if inRect(self._hRect, x, y) then
            for _, hit in ipairs(self._hHits or {}) do
                if y >= hit.y and y < hit.y + hit.h then self.hFocus = hit.fi; self:helpFold(hit.id); return true end
            end
            return true
        end
        return false
    end
    if self._cmdMouseDown then return self:_cmdMouseDown(x, y) end
    return false
end

function W:_pagePress(id)
    if id == "tolog" then sound("UIActivateButton"); self:setPage("log"); return true end
    if self._cmdPress then return self:_cmdPress(id) end
    return false
end

function W:_pageWheel(del, mx, my)
    if self.page == "help" then
        self.hScroll = math.max(0, math.min(self._hMax or 0, (self.hScroll or 0) + del * px(U.FROW) * 3))
    elseif self._cmdWheel then
        self:_cmdWheel(del, mx, my)
    end
end

-- the controller on a page: true when it moved; false on the left edge (the window goes to the strip)
function W:_pageDir(dir)
    if self.page == "help" then
        local folds = helpFolds((self:_helpLayout(self._hRect and self._hRect.w or px(400))))
        if self.zone == "pband" then
            if dir == "up" then self.zone = "page"; self.hSeek = true; return true end
            return dir ~= "left"
        end
        self.zone = "page"
        if dir == "up" then
            if (self.hFocus or 1) > 1 then self.hFocus = self.hFocus - 1; self.hSeek = true end
            return true
        elseif dir == "down" then
            if (self.hFocus or 1) < #folds then self.hFocus = (self.hFocus or 1) + 1; self.hSeek = true
            else self.zone = "pband" end
            return true
        end
        return dir ~= "left"
    end
    if self._cmdDir then return self:_cmdDir(dir) end
    return false
end

function W:_pageButton(button, jd)
    if self.page == "help" then
        if button == Joypad.AButton then
            if self.zone == "pband" then self:press("tolog")
            else
                local folds = helpFolds((self:_helpLayout(self._hRect and self._hRect.w or px(400))))
                local it = folds[self.hFocus or 1]
                if it then self:helpFold(it.sec.id) end
            end
            return true
        end
        return false
    end
    if self._cmdButton then return self:_cmdButton(button, jd) end
    return false
end

function W:_pagePrompts(out)
    if self.page == "help" then
        if self.zone == "pband" then
            out[#out + 1] = { glyph = "A", label = tr("UI_ZeD_Prompt_Press") }
        else
            local folds = helpFolds((self:_helpLayout(self._hRect and self._hRect.w or px(400))))
            local it = folds[self.hFocus or 1]
            if it then out[#out + 1] = { glyph = "A", label = (self.hFold and self.hFold[it.sec.id]) and tr("UI_ZeD_Prompt_Unfold") or tr("UI_ZeD_Prompt_Fold") } end
        end
        return
    end
    if self._cmdPrompts then self:_cmdPrompts(out) end
end

function W:_pageBLabel()
    if self._cmdBLabel then return self:_cmdBLabel() end
    return nil
end

function W:_pageLeave(old)
    if self._cmdLeave then self:_cmdLeave(old) end
end

function W:_pageClose()
    if self._cmdClose then return self:_cmdClose() end
    return {}
end

return W
