-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuTerms.lua
-- ============================================================================
-- TERMS OF SERVICE: the game's terms window, replaced. Client-side; an
-- organism.
--
-- Vanilla's ISTermsOfServiceUI (the Spiffo judge with four stacked buttons)
-- as a ZeD window: the game's words in a scrolling box, the answers in the
-- band at the foot: Quit | View terms of service | View privacy policy |
-- Accept. Two ways in:
--   * the desk's ZeD menu > Terms of service (and Y on the main window): a
--     view on the monitor; Back, Escape and the close box leave it, as the
--     terms were accepted before the menu could show.
--   * the first run, or when the game's terms change (TermsOfServiceState,
--     before the main menu): the same window on its own over the black
--     screen, centered, Accept or Quit only.
-- Every answer is vanilla's own function: Accept runs
-- ISTermsOfServiceUI.onButtonAccept (it stores the game's terms version and
-- saves the options; the version is local to vanilla's file), the two View
-- buttons its onButton1 / onButton2 (Steam overlay or the browser), Quit its
-- onButtonQuit. Accepting is the player's own act: nothing here accepts.
-- Safe mode, or a window that cannot be built: vanilla's own.
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ISUI/ISTermsOfServiceUI"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui

-- design units
local DESK_H, BOOT_W, BOOT_H, LINE_GAP, PARA_GAP = 360, 640, 360, 3, 10

local function ms() return MainScreen and MainScreen.instance end

-- the game's words: its prompt, and the browser note when the Steam overlay is off; paragraphs at its <BR>
function MM.termsParagraphs()
    local text = getText("UI_TermsOfService_Prompt1")
    local overlay = false
    pcall(function() overlay = isSteamOverlayEnabled() end)
    if not overlay then text = text .. " <BR> " .. getText("UI_TermsOfService_Prompt2") end
    local out = {}
    text = text:gsub("<%s*[Bb][Rr]%s*>", "\n"):gsub("<LINE>", "\n")
    for para in (text .. "\n"):gmatch("([^\n]*)\n") do
        local p = UI.plain(para)
        if p ~= "" then out[#out + 1] = p end
    end
    return out
end

-- Accept as vanilla's own button does: its version stored, the options saved, then its hand-back
-- (to the game's start-up state, or to the main screen). A stand-in for vanilla's window carries it.
function MM.termsAccept(javaStateObj)
    local stand = setmetatable({ destroyOnClick = false, javaStateObj = javaStateObj,
                                 setVisible = function() end, removeFromUIManager = function() end }, { __index = ISTermsOfServiceUI })
    ISTermsOfServiceUI.onButtonAccept(stand, nil)
end

-- ============================================================================
ZeD_MMTerms = ZeD_MMWindow:derive("ZeD_MMTerms")

function ZeD_MMTerms:new(boot)
    local o = ZeD_MMWindow.new(self, boot and "termsboot" or "terms")
    o.noResetControl = true
    o.boot = boot and true or false
    o.scroll = 0
    o.ctx = { hot = nil, press = nil, wasDown = false }
    return o
end

-- on its own the window keeps its own pointer (no desk under it)
function ZeD_MMTerms:pctx() if self.boot then return self.ctx end; return MM.ctx end

function ZeD_MMTerms:onShow()
    self.scroll = 0
    -- the pad lands on View terms of service, as the game's window did: agreeing is never one press away
    self.focusId = "terms"
end

function ZeD_MMTerms:leave()
    if self.boot then return end
    MM.clickSound()
    MM.showView("main")
end

function ZeD_MMTerms:accept()
    MM.clickSound()
    if self.boot then
        local st = self.javaStateObj
        self:closeBoot()
        local ok, err = pcall(MM.termsAccept, st)
        if not ok then print("[ZeD] Terms: the game's Accept failed (" .. tostring(err) .. ")") end
        return
    end
    local ok, err = pcall(MM.termsAccept, nil)
    if not ok then print("[ZeD] Terms: the game's Accept failed (" .. tostring(err) .. ")") end
    MM.showView("main")
end

function ZeD_MMTerms:viewTerms() MM.clickSound(); pcall(ISTermsOfServiceUI.onButton1, nil, nil) end
function ZeD_MMTerms:viewPrivacy() MM.clickSound(); pcall(ISTermsOfServiceUI.onButton2, nil, nil) end
function ZeD_MMTerms:quit() MM.clickSound(); ISTermsOfServiceUI.onButtonQuit(nil, nil) end

-- the window's place: on the monitor, or centered on the screen at the start
function ZeD_MMTerms:place()
    local T = ZeD.T
    if not self.boot then return UI.placeOnTube(self, T.px(DESK_H)) end
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local w = math.min(T.px(BOOT_W), sw - T.px(32))
    local h = math.min(T.px(BOOT_H), sh - T.px(32))
    local x, y = math.floor((sw - w) / 2), math.floor((sh - h) / 2)
    if self.x ~= x or self.y ~= y then self:setX(x); self:setY(y) end
    if self.width ~= w or self.height ~= h then self:setWidth(w); self:setHeight(h) end
    return w, h
end

function ZeD_MMTerms:prerender()
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    local w, h = self:place()
    self.title = ZeD.textCase(getText("UI_TermsOfService_Title"))
    self.titleStats = {}
    ZeD_Window.prerender(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = MM.bandH()
    local stripY = h - self:footerHeight() - stripH
    local bx, by, bw, bh = pad, tb + pad, w - pad * 2, stripY - tb - pad * 2
    UI.insetBox(self, bx, by, bw, bh)
    -- the words, scrolled in the box
    local f2 = T.fontF2
    local ix, iw = bx + T.px(16), bw - T.px(32) - T.sp.scrollbarW
    local lines = {}
    for i, p in ipairs(MM.termsParagraphs()) do
        if i > 1 then lines[#lines + 1] = false end
        for _, l in ipairs(ZeD.Atoms.wrapText(p, f2, iw)) do lines[#lines + 1] = l end
    end
    local lh = MM.fontH(f2) + T.px(LINE_GAP)
    local total = T.px(14) * 2
    for _, l in ipairs(lines) do total = total + (l and lh or T.px(PARA_GAP)) end
    local vy, vh = by + T.px(1), bh - T.px(2)
    self.scroll = math.max(0, math.min(self.scroll, math.max(0, total - vh)))
    self._text = { x = bx, y = vy, w = bw, h = vh, max = math.max(0, total - vh) }
    self:setStencilRect(bx + T.px(1), vy, bw - T.px(2), vh)
    local cy = vy + T.px(14) - self.scroll
    local c = T.text
    for _, l in ipairs(lines) do
        if l then
            if cy + lh > vy and cy < vy + vh then self:drawText(l, ix, cy, c.r, c.g, c.b, c.a or 1, f2) end
            cy = cy + lh
        else
            cy = cy + T.px(PARA_GAP)
        end
    end
    self:clearStencilRect()
    if total > vh then
        local sbW = T.sp.scrollbarW
        MM.scrollBar(self, self.kind .. ":track", bx + bw - T.px(1) - sbW, vy, sbW, vh, self.scroll, total, function(v) self.scroll = v end, { step = lh })
    end
    -- the band: the answers, Accept last
    local lefts = {}
    if not self.boot then lefts[1] = { "back", getText("UI_btn_back"), function() self:leave() end } end
    UI.stripSpecs(self, stripY, w, 1000, lefts, {
        { "quit", ZeD.btnCase(getText("UI_TermsOfService_ButtonQuit")), function() self:quit() end, "default", false, ZeD.tr("UI_ZeD_MMHelp_TermsQuit") },
        { "terms", ZeD.btnCase(getText("UI_TermsOfService_Button1")), function() self:viewTerms() end, "default", false, ZeD.tr("UI_ZeD_MMHelp_TermsView") },
        { "privacy", ZeD.btnCase(getText("UI_TermsOfService_Button2")), function() self:viewPrivacy() end, "default", false, ZeD.tr("UI_ZeD_MMHelp_TermsView") },
        { "accept", ZeD.btnCase(getText("UI_TermsOfService_ButtonAccept")), function() self:accept() end, "primary", false, ZeD.tr("UI_ZeD_MMHelp_TermsAccept") } })
end

function ZeD_MMTerms:render()
    UI.drawStripAndButtons(self)
    ZeD_Window.render(self)
end

-- the band's buttons left and right; up and down scroll the words
function ZeD_MMTerms:joyDir(dir)
    if dir == "up" or dir == "down" then
        local step = MM.fontH(ZeD.T.fontF2) * 3
        self.scroll = math.max(0, math.min(self._text and self._text.max or 0, self.scroll + (dir == "up" and -step or step)))
        return
    end
    ZeD_MMWindow.joyDir(self, dir)
end
function ZeD_MMTerms:joyB() self:leave() end
function ZeD_MMTerms:joyY() end
function ZeD_MMTerms:keyEscape() if not self.boot then self:leave() end; return true end
function ZeD_MMTerms:keyOther(key)
    if key == Keyboard.KEY_RETURN then self:accept(); return true end
    return false
end
function ZeD_MMTerms:close() self:leave() end
function ZeD_MMTerms:getFooterPrompts()
    if not MM.gamepad() and not self.padSeen then return nil end
    local t = { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "D-PAD", label = ZeD.tr("UI_ZeD_Terms_PromptScroll") } }
    if not self.boot then t[#t + 1] = { glyph = "B", label = ZeD.btnCase(getText("UI_btn_back")) } end
    return t
end
function ZeD_MMTerms:wheel(del)
    local b = self._text
    if not b then return false end
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    if mx < b.x or mx > b.x + b.w or my < b.y or my > b.y + b.h then return false end
    self.scroll = math.max(0, math.min(b.max, self.scroll + del * (MM.fontH(ZeD.T.fontF2) + ZeD.T.px(LINE_GAP)) * 2))
    return true
end
function ZeD_MMTerms:onMouseWheel(del)
    if self.boot then return self:wheel(del) end
    return MM.wheel(del)
end

-- ON ITS OWN (the game's start-up state): its own pointer and the controller's buttons --------
-- (MM.pointer stands aside with no main screen, so the window answers the mouse itself:
-- press and release over the same box)
function ZeD_MMTerms:update()
    if not self.boot then return ZeD_MMWindow.update(self) end
    local ctx = self.ctx
    local down = ZeD.MouseTick and ZeD.MouseTick.down and ZeD.MouseTick.down() or isMouseButtonDown(0)
    local mx, my = getMouseX(), getMouseY()
    local h
    for i = #(self._hits or {}), 1, -1 do
        local hh = self._hits[i]
        if mx >= hh.x and mx < hh.x + hh.w and my >= hh.y and my < hh.y + hh.h then h = hh; break end
    end
    if h and h.disabled then h = nil end
    local id = h and h.id or nil
    if id ~= ctx.hot then ctx.hot = id; if h and h.sound then MM.hoverSound() end end
    if down and ctx.dragHit then ctx.dragHit.drag(mx, my) end
    if not down then ctx.dragHit = nil end
    if down and not ctx.wasDown then
        ctx.press = id
        if h and h.drag then ctx.dragHit = h; h.drag(mx, my) end
    elseif not down and ctx.wasDown then
        if h and h.fn and ctx.press == id then h.fn() end
        ctx.press = nil
    end
    ctx.wasDown = down
end
function ZeD_MMTerms:onMouseDown(x, y) return true end
function ZeD_MMTerms:onMouseUp(x, y) return true end
function ZeD_MMTerms:onGainJoypadFocus(joypadData) self.joyfocus = joypadData; self.padSeen = true; if not self.focusId then self.focusId = "terms" end end
function ZeD_MMTerms:onLoseJoypadFocus(joypadData) self.joyfocus = nil end
function ZeD_MMTerms:onJoypadDown(button, joypadData)
    self.padSeen = true
    if button == Joypad.AButton then self:joyA()
    elseif button == Joypad.BButton then self:joyB() end
end
function ZeD_MMTerms:onJoypadDirUp() self:joyDir("up") end
function ZeD_MMTerms:onJoypadDirDown() self:joyDir("down") end
function ZeD_MMTerms:onJoypadDirLeft() self:joyDir("left") end
function ZeD_MMTerms:onJoypadDirRight() self:joyDir("right") end

function ZeD_MMTerms:closeBoot()
    self:setVisible(false)
    self:removeFromUIManager()
    if ISTermsOfServiceUI.instance == self then ISTermsOfServiceUI.instance = nil end
    local jd = JoypadState and JoypadState.getMainMenuJoypad and JoypadState.getMainMenuJoypad()
    if jd and jd.focus == self then jd.focus = self.prevFocus; updateJoypadFocus(jd) end
end

-- The game's start-up state: ZeD's window in place of vanilla's (vanilla's handler stays for
-- safe mode and for any window that cannot be built). Only once, or when the terms change:
-- vanilla's own test of its version decides, so its handler runs and its window is swapped.
local function bootTerms(javaStateObj)
    -- (vanilla's handler runs once per state: had its Remove below not taken, its window is already up)
    local van = ISTermsOfServiceUI.instance
    local ran = van ~= nil and van.javaStateObj == javaStateObj
    local zedOn = ZeD.Safe and not ZeD.Safe.on() and ZeD.T and ZeD_Window
    if not zedOn then
        if not ran then MM._termsBootOrig(javaStateObj) end
        return
    end
    if not ran then MM._termsBootOrig(javaStateObj) end
    van = ISTermsOfServiceUI.instance
    if not (van and van.javaStateObj == javaStateObj and van:isVisible()) then return end   -- (the terms were already accepted)
    local ok, err = pcall(function()
        local win = ZeD_MMTerms:new(true)
        win.javaStateObj = javaStateObj
        win:initialise()
        win:addToUIManager()
        win:setAlwaysOnTop(true)
        win:onShow()
        win.prevFocus = van.prevFocus
        -- vanilla's window goes, quietly: nothing of its answers ran
        van:setVisible(false)
        van:removeFromUIManager()
        ISTermsOfServiceUI.instance = win
        local jd = JoypadState and JoypadState.getMainMenuJoypad and JoypadState.getMainMenuJoypad()
        if jd and jd.focus == van then jd.focus = win; updateJoypadFocus(jd) end
        local p1 = JoypadState and JoypadState.players and JoypadState.players[1]
        if p1 and p1.focus == van then p1.focus = win; updateJoypadFocus(p1) end
        MM.termsBootWin = win
    end)
    if not ok then
        print("[ZeD] Terms: ZeD's window could not open (" .. tostring(err) .. "); the game's own shows")
        if van and not van:isVisible() then van:setVisible(true); van:addToUIManager(); ISTermsOfServiceUI.instance = van end
    end
end

if not MM._termsBootOrig then
    MM._termsBootOrig = ISTermsOfServiceUI.OnGameStateEnter
    Events.OnGameStateEnter.Remove(ISTermsOfServiceUI.OnGameStateEnter)
    Events.OnGameStateEnter.Add(function(javaStateObj)
        if not instanceof(javaStateObj, "TermsOfServiceState") then return end
        bootTerms(javaStateObj)
    end)
end

local _wheel = MM.wheel
function MM.wheel(del)
    if MM.view == "terms" and MM.root and MM.root.termsWin then
        if MM.root.termsWin:wheel(del) then return true end
    end
    return _wheel(del)
end

-- on the desk: the ZeD menu's Terms of service (MM.act.tos) shows this view
MM.addView("terms", "termsWin", function() return ZeD_MMTerms:new(false) end)
