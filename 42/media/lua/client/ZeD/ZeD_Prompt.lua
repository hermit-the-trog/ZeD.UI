-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Prompt.lua
-- ============================================================================
-- O05 v2: THE PROMPT — vanilla's pop-ups as one small ZeD window
-- Mockup ZeDUI/mockups/zed_dialogs_v1.html (approved Oct 15 2026: vanilla's
-- placement, the ZeD keyboard). HOOK_MAP row 28; the hooks that open it are in
-- Overrides/Prompts.lua, the keyboard is ZeD_Keyboard.lua.
--
-- Every vanilla question, note, text box, long rich-text note, Set Alarm and
-- Set Timer opens this instead: the striped bar with the close box and no
-- title, vanilla's words in the body, the answers in the footer on the right
-- (the main answer last). The game gets vanilla's own answer back: the same
-- callback with the same arguments, a real ISButton as the button (internal
-- "YES" / "NO" / "OK" / "CANCEL", parent = this prompt), and the same fields
-- callers read and write (entry, param1..4, prevFocus, anything they add).
--
-- Kinds:  question (Yes / No)       note (OK)
--         text (a field, OK / Cancel)     rich (formatted text, OK or Yes / No)
--         alarm (hour, minute, Alarm tick, OK)   timer (seconds, OK / Cancel)
--
-- Placement is vanilla's (on the pointer, centred on the player's part of the
-- screen with a controller, or the caller's own box), always kept on screen.
-- No dim and no pause: the game keeps going behind it.
--
-- Mouse: clicks are hit-tested here (the prompt is a top-level panel; only the
-- text fields are children). Controller: a small focus grid (rows of ids),
-- A presses, B is No / Cancel, the D-pad moves or steps; the strip under the
-- footer names the buttons.
-- ============================================================================

require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Organisms"

ZeD = ZeD or {}
ZeD.Prompt = ZeD.Prompt or {}
local P = ZeD.Prompt

-- design units (1 px at 1080p; T.px scales them)
local U = {
    MARK = 32, MARK_GAP = 14,
    PAD_L = 16, PAD_R = 18, PAD_T = 16, PAD_B = 18,
    MSG_MIN = 220, MSG_MAX = 400,
    MIN_W = 300, TEXT_W = 340, ALARM_W = 300, RICH_W = 440, RICH_MAX_H = 420,
    FOOT_H = 40, FOOT_PAD = 12, BTN_H = 24, BTN_MIN = 78, BTN_PAD = 12, BTN_GAP = 12,
    LABEL_GAP = 6, WHY_GAP = 7, HEAD_GAP = 8,
    ROW_H = 34, STEP = 22, STEP_GAP = 6, VAL_W = 44, TICK_ROW = 30,
    SM_H = 22, SM_PAD = 7, SM_GAP = 4, TVAL_W = 64,
    SWATCH = 18, SWATCH_GAP = 6,
    PARA_GAP = 10, MARGIN = 8,
}

-- ---------------------------------------------------------------------------
-- small helpers
-- ---------------------------------------------------------------------------
local function TM() return ZeD.TM end
local function fh(font) return ZeD.TM:getFontHeight(font) end
local function tw(font, s) return ZeD.TM:MeasureStringX(font, s) end
local function clamp(v, lo, hi) if v < lo then return lo end if v > hi then return hi end return v end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(name) pcall(function() getSoundManager():playUISound(name or "UIActivateButton") end) end
local function upper(s) return string.upper(tostring(s or "")) end
local function gamepadMode()
    local D = ZeD.Input and ZeD.Input.Detector
    return D and D.getMode and D.getMode() == "gamepad" or false
end

-- the screen box a prompt stays inside: the player's part of the screen, or all of it
local function screenBox(player)
    if type(player) == "number" and player >= 0 and getPlayerScreenWidth then
        local ok, l, t, w, h = pcall(function()
            return getPlayerScreenLeft(player), getPlayerScreenTop(player), getPlayerScreenWidth(player), getPlayerScreenHeight(player)
        end)
        if ok and w and w > 0 and h and h > 0 then return l, t, w, h end
    end
    return 0, 0, getCore():getScreenWidth(), getCore():getScreenHeight()
end

-- Vanilla's placement, as a centre point: x == 0 / y == 0 put the pop-up on the
-- pointer, or in the middle of the player's screen when that player is on a
-- controller; any other x, y is the caller's own box (its centre is kept).
-- `alwaysCentre` = the alarm and the timer, which vanilla centres either way.
function P.anchor(x, y, w, h, player, alwaysCentre)
    local joy = false
    if type(player) == "number" then
        local p = getSpecificPlayer(player)
        joy = p ~= nil and p:getJoypadBind() ~= -1
    end
    local l, t, sw, sh = screenBox(player)
    local cx, cy
    if x == 0 or x == nil then
        cx = (joy or alwaysCentre) and (l + sw / 2) or getMouseX()
    else
        cx = x + (w or 0) / 2
    end
    if y == 0 or y == nil then
        cy = (joy or alwaysCentre) and (t + sh / 2) or getMouseY()
    else
        cy = y + (h or 0) / 2
    end
    return cx, cy
end

-- Questions that cost something get the stop sign and the red YES: a short list
-- of vanilla's own (killing, removing, deleting, quitting); any other question,
-- a mod's included, is a plain question.
local COSTLY = {
    { "AnimalContextMenu", "onKillAnimalConfirm" }, { "ISDesignationZonePanel", "onRemoveZone" },
    { "ISInventoryPane", "onConfirmDelete" }, { "ISPostDeathUI", "onConfirmQuitToDesktop" },
    { "ISFactionUI", "onDisbandFaction" }, { "ISFactionUI", "onRemovePlayerFromFaction" }, { "ISFactionUI", "onQuitFaction" },
    { "ISSafehouseUI", "onReleaseSafehouse" }, { "ISSafehouseUI", "onRemovePlayerFromSafehouse" }, { "ISSafehouseUI", "onQuitSafehouse" },
    { "ISPlayerStatsUserlogUI", "onRemoveLog" }, { "ISVehicleMechanics", "onCheatRemoveAux" },
    { "ISWorldMap", "onConfirmForget" }, { "ISWorldMapSymbols", "onConfirmRemoveAnnotation" },
}
function P.isCostly(fn)
    if type(fn) ~= "function" then return false end
    for _, c in ipairs(COSTLY) do
        local t = _G[c[1]]
        if type(t) == "table" and t[c[2]] == fn then return true end
    end
    return false
end

-- System 7's alert marks (white glyphs, tinted when drawn)
local MARKS = { question = "question", note = "info", stop = "octagon-minus" }
local _markTex = {}
local function markTex(kind)
    local name = MARKS[kind]
    if not name then return nil end
    if _markTex[name] == nil then _markTex[name] = getTexture("media/textures/ZeD/icons/" .. name .. ".png") or false end
    return _markTex[name] or nil
end

-- ---------------------------------------------------------------------------
-- RICH TEXT — vanilla's tags (<LINE>, <SIZE:medium>, <IMAGE:...>, colours...)
-- read as blocks set in ZeD type: a heading for each medium / large run, a
-- paragraph for each blank-line run (a single <LINE> stays a line break), an
-- image for each image tag. Colours, alignment and the rest are dropped.
-- ---------------------------------------------------------------------------
local function tidy(t)
    t = t:gsub("[ \t]+", " ")
    t = t:gsub(" ?\n ?", "\n")
    t = t:gsub("^%s+", "")
    t = t:gsub("%s+$", "")
    return t
end

local function splitParagraphs(t, out)
    -- a blank line may carry spaces ("<LINE> <LINE>"): close them up first
    t = t:gsub("[ \t]*\n[ \t]*", "\n")
    local pos = 1
    while pos <= #t do
        local a, b = t:find("\n\n+", pos)
        local piece = t:sub(pos, (a or (#t + 1)) - 1)
        piece = tidy(piece)
        if piece ~= "" then out[#out + 1] = { kind = "para", text = piece } end
        if not a then break end
        pos = b + 1
    end
end

function P.parseRich(src)
    local s = tostring(src or "")
    s = s:gsub("\\n", "\n")
    s = s:gsub("\r", "")
    local blocks, buf, mode = {}, {}, "para"
    local function flush()
        local t = table.concat(buf)
        buf = {}
        if mode == "head" then
            t = tidy(t:gsub("\n", " "))
            if t ~= "" then blocks[#blocks + 1] = { kind = "head", text = t } end
        else
            splitParagraphs(t, blocks)
        end
    end
    local function lineBreak()
        if mode == "head" then flush(); mode = "para" else buf[#buf + 1] = "\n" end
    end
    local function addText(chunk)
        local pos = 1
        while pos <= #chunk do
            local a = chunk:find("\n", pos, true)
            local piece = chunk:sub(pos, (a or (#chunk + 1)) - 1)
            if piece ~= "" then buf[#buf + 1] = piece end
            if not a then break end
            lineBreak()
            pos = a + 1
        end
    end
    local i = 1
    while i <= #s do
        local a, b = s:find("<[^<>]*>", i)
        addText(s:sub(i, (a or (#s + 1)) - 1))
        if not a then break end
        local tag = s:sub(a + 1, b - 1)
        local up = upper(tag)
        if up == "LINE" or up == "BR" then
            lineBreak()
        elseif up:sub(1, 5) == "SIZE:" then
            flush()
            local sz = up:sub(6)
            mode = (sz == "MEDIUM" or sz == "LARGE") and "head" or "para"
        elseif up == "H1" or up == "H2" then
            flush(); mode = "head"
        elseif up == "TEXT" then
            flush(); mode = "para"
        elseif up:sub(1, 5) == "IMAGE" then
            flush()
            local args = tag:match(":(.*)$") or ""
            local path, iw, ih = args:match("^%s*([^,]+)%s*,%s*(%d+)%s*,%s*(%d+)")
            path = path or args
            local tex = path ~= "" and getTexture(path) or nil
            if tex then blocks[#blocks + 1] = { kind = "image", tex = tex, w = tonumber(iw) or tex:getWidth(), h = tonumber(ih) or tex:getHeight() } end
        elseif up == "SPACE" then
            buf[#buf + 1] = " "
        end
        i = b + 1
    end
    flush()
    return blocks
end

-- lay the blocks out at width w: lines per block, heights; returns total height
local function layoutRich(blocks, w)
    local T = ZeD.T
    local total = 0
    for idx, bl in ipairs(blocks) do
        if idx > 1 then total = total + T.px(U.PARA_GAP) end
        if bl.kind == "image" then
            local iw, ih = T.px(bl.w), T.px(bl.h)
            if iw > w then ih = math.floor(ih * w / iw); iw = w end
            bl.dw, bl.dh, bl.y = iw, ih, total
            total = total + ih
        else
            local font = bl.kind == "head" and T.fontF4 or T.fontF2
            local lh = fh(font) + T.px(3)
            local lines = {}
            for _, l in ipairs(ZeD.Atoms.wrapText(bl.text, font, w)) do lines[#lines + 1] = l end
            bl.lines, bl.font, bl.lh, bl.y = lines, font, lh, total
            total = total + #lines * lh
        end
    end
    return total
end

-- ---------------------------------------------------------------------------
-- THE CLASS
-- ---------------------------------------------------------------------------
ZeD_Prompt = ZeD_Window:derive("ZeD_Prompt")

P.open = P.open or {}   -- prompts on screen, oldest first (the last visible one is "on top")

function ZeD_Prompt:new(kind, cx, cy, player)
    local o = ZeD_Window.new(self, 0, 0, 100, 100, "")
    o.kind = kind
    o.resizable = false
    o.themeFooter = false
    o.pin = true
    -- vanilla's fields callers read or write (colours are kept, never drawn)
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    -- anchored top-left only: the engine stretches an element anchored on all sides
    -- when it moves, and a prompt moves (placement, keeping its centre, dragging)
    o.anchorLeft, o.anchorRight, o.anchorTop, o.anchorBottom = true, false, true, false
    o.moveWithMouse = false
    o.player = player
    o._cx, o._cy = cx or getMouseX(), cy or getMouseY()
    o._placed = false
    o._focus = nil       -- controller focus: row index, column index
    o._hover = nil       -- mouse: id under the pointer
    o._down = nil        -- mouse: id pressed
    o._scroll = 0        -- rich: body scroll in px
    return o
end

-- a real ISButton as each answer (callbacks read button.internal / .parent / .player;
-- callers call setEnable, setTitle, forceClick); drawn and hit-tested here
local function makeButton(p, internal, title)
    local b = ISButton:new(0, 0, 10, 10, title or "", p, ZeD_Prompt.onClick)
    b.internal = internal
    b:initialise()
    b.parent = p
    return b
end

-- a ZeD-styled text field (theme colours and the scaled face follow ZeD.Text.fitEntry)
local function makeEntry(p, text)
    local e = ISTextEntryBox:new(text or "", 0, 0, 100, 24)
    e:initialise()
    e:instantiate()
    e.zedEntry = true
    e.font = (ZeD.Text and ZeD.Text.entryFont) and ZeD.Text.entryFont() or UIFont.Small
    p:addChild(e)
    return e
end

function ZeD_Prompt:createChildren()
    ZeD_Window.createChildren(self)
    self.minimumWidth, self.minimumHeight = 0, 0   -- see prerender
end

function ZeD_Prompt:initialise()
    ISPanel.initialise(self)
    local K = self.kind
    if K == "question" or K == "note" then
        if self.yesno then
            self.yes = makeButton(self, "YES", getText("UI_Yes"))
            self.no = makeButton(self, "NO", getText("UI_No"))
        else
            self.ok = makeButton(self, "OK", getText("UI_Ok"))
        end
    elseif K == "rich" then
        if self.yesno then
            self.yes = makeButton(self, "YES", getText(self.yesText or "UI_Yes"))
            self.yes.isYes = true
            self.no = makeButton(self, "NO", getText(self.noText or "UI_No"))
            self.no.isYes = false
        else
            self.ok = makeButton(self, "OK", getText("UI_Ok"))
            self.ok.isYes = true
        end
        -- vanilla's rich-text panel, as far as callers touch it (text, paginate)
        local prompt = self
        self.chatText = self.chatText or {
            text = self.text,
            paginate = function() prompt._richKey = nil end,
            getScrollHeight = function() return prompt._contentH or 0 end,
            setHeight = function() end, updateScrollbars = function() end,
            setYScroll = function(_, v) prompt._scroll = -(v or 0) end,
        }
    elseif K == "text" then
        self.entry = makeEntry(self, self.defaultEntryText)
        if self._onlyNumbers then self.entry:setOnlyNumbers(true) end
        self.entry:setMultipleLine(self.multipleLine == true)
        self.entry:setMaxLines(self.maxLines or 1)
        local prompt = self
        self.entry.onCommandEntered = function() prompt:pressPrimary() end
        self.entry.onOtherKey = function(_, key)
            if key == Keyboard.KEY_ESCAPE then prompt:answerCancel() end
        end
        self.currentColor = self.currentColor or ColorInfo.new(1, 1, 1, 1)
        self.yes = makeButton(self, "OK", getText("UI_Ok"))
        self.no = makeButton(self, "CANCEL", getText("UI_Cancel"))
    elseif K == "alarm" then
        local a = self.alarm
        self.hours = makeEntry(self, tostring(a and a:getHour() or 0))
        local m = a and a:getMinute() or 0
        self.mins = makeEntry(self, m == 0 and "00" or tostring(m))
        for _, e in ipairs({ self.hours, self.mins }) do e:setOnlyNumbers(true) end
        self._alarmOn = a and a:isAlarmSet() or false
        local prompt = self
        -- vanilla's tick box, as far as callers touch it
        self.setAlarm = {
            isSelected = function() return prompt._alarmOn end,
            setSelected = function(_, _, v) prompt._alarmOn = v and true or false end,
        }
        self.ok = makeButton(self, "OK", getText("UI_Ok"))
    elseif K == "timer" then
        self.textBox = makeEntry(self, tostring(self.time or 1))
        self.textBox:setOnlyNumbers(true)
        self.yes = makeButton(self, "OK", getText("UI_Ok"))
        self.no = makeButton(self, "CANCEL", getText("UI_Cancel"))
    end
    -- the Java side exists from here on (callers call ignoreHeightChange, setCapture...)
    if not self.javaObject then self:instantiate() end
    self:layout()
end

-- ---------------------------------------------------------------------------
-- vanilla's API, kind by kind (what callers call after :new)
-- ---------------------------------------------------------------------------
-- ISTextBox
function ZeD_Prompt:setOnlyNumbers(b)
    self._onlyNumbers = b
    if self.entry then self.entry:setOnlyNumbers(b) end
end
function ZeD_Prompt:setMultipleLine(b) self.multipleLine = b; if self.entry then self.entry:setMultipleLine(b) end end
function ZeD_Prompt:setNumberOfLines(n) self.numLines = n end
function ZeD_Prompt:setMaxLines(n) self.maxLines = n; if self.entry then self.entry:setMaxLines(n) end end
function ZeD_Prompt:getMaxLines() return self.maxLines end
function ZeD_Prompt:setValidateFunction(target, func, arg1, arg2)
    self.validateTarget, self.validateFunc, self.validateArgs = target, func, { arg1, arg2 }
end
function ZeD_Prompt:setValidateTooltipText(text) self.validateTooltipText = text end
function ZeD_Prompt:showErrorMessage(show, msg) self.showError, self.errorMsg = show, msg end
function ZeD_Prompt:enableColorPicker() self._colorPicker = true end
function ZeD_Prompt:onColorPicker() end
function ZeD_Prompt:onPickedColor(color)
    self.currentColor = ColorInfo.new(color.r, color.g, color.b, 1)
    if self.entry and self.entry.javaObject then self.entry.javaObject:setTextColor(self.currentColor) end
end
-- ISModalRichText
function ZeD_Prompt:setHeightToContents() self._richKey = nil; self:layout() end
-- ISBombTimerDialog
function ZeD_Prompt:getTime() return tonumber(self.textBox and self.textBox:getText() or "") or 0 end
function ZeD_Prompt:addTime(seconds)
    local v = self:getTime() + seconds
    if v < 1 then v = 1 end
    self.textBox:setText(tostring(v))
end
-- ISAlarmClockDialog's steps (hour wraps 0..23; minutes go in tens, 0..50)
function ZeD_Prompt:stepAlarm(which, dir)
    if which == "hour" then
        local v = (tonumber(self.hours:getText()) or 0) + dir
        if v > 23 then v = 0 elseif v < 0 then v = 23 end
        self.hours:setText(tostring(v))
    else
        local v = (tonumber(self.mins:getText()) or 0) + dir * 10
        if v > 50 then v = 0 elseif v < 0 then v = 50 end
        self.mins:setText(v == 0 and "00" or tostring(v))
    end
end

-- The text prompt's OK: on unless vanilla's checks say no; the reason goes under the field
function ZeD_Prompt:updateButtons()
    if self.kind ~= "text" or not self.entry then return end
    local on, why = true, nil
    local text = self.entry:getText()
    if self.validateFunc and not self.validateFunc(self.validateTarget, text, self.validateArgs and self.validateArgs[1], self.validateArgs and self.validateArgs[2]) then
        on, why = false, self.validateTooltipText
    end
    if self.maxChars and self.entry:getInternalText():len() > self.maxChars then
        on, why = false, getText("IGUI_TextBox_TooManyChar", self.maxChars)
    end
    if self.noEmpty and string.trim(self.entry:getInternalText()) == "" then
        on, why = false, getText("IGUI_TextBox_CantBeEmpty")
    end
    self.yes:setEnable(on)
    self.yes.tooltip = why
    self._why = (self.showError and self.errorMsg) or why
end

-- ---------------------------------------------------------------------------
-- answers
-- ---------------------------------------------------------------------------
local function restoreJoypad(self)
    if self.player ~= nil and type(self.player) == "number" then
        setJoypadFocus(self.player, self.prevFocus)
    elseif self.joyfocus and self.joyfocus.focus == self then
        self.joyfocus.focus = self.prevFocus
        updateJoypadFocus(self.joyfocus)
    end
end

local function hideKeyboard(self)
    local K = ZeD.Keyboard
    if K and K.isFor and K.isFor(self) then K.hide() end
end

-- a closed prompt lets go of its fields: a field keeps the keyboard after its panel is
-- gone, and its keys (Enter, Escape) would answer a prompt no longer on screen
local function releaseFields(self)
    for _, e in ipairs({ self.entry, self.hours, self.mins, self.textBox }) do
        if e and e.javaObject and e:isFocused() then e:unfocus() end
    end
end

local function untrack(self)
    for i = #P.open, 1, -1 do if P.open[i] == self then table.remove(P.open, i) end end
end

-- vanilla's destroy, per kind (the paused message, the game speed, the controller focus)
function ZeD_Prompt:destroy()
    hideKeyboard(self)
    releaseFields(self)
    self._dead = true
    local K = self.kind
    if K == "question" or K == "note" then
        local ms = MainScreen and MainScreen.instance
        local inGame = ms and ms.inGame and not ms:getIsVisible()
        UIManager.setShowPausedMessage(inGame and true or false)
        self:setVisible(false)
        self:removeFromUIManager()
        if UIManager.getSpeedControls() and inGame then UIManager.getSpeedControls():SetCurrentGameSpeed(1) end
        restoreJoypad(self)
    elseif K == "rich" then
        UIManager.setShowPausedMessage(true)
        self:setVisible(false)
        if self.destroyOnClick ~= false then self:removeFromUIManager() else untrack(self) end
        if UIManager.getSpeedControls() then UIManager.getSpeedControls():SetCurrentGameSpeed(1) end
        if type(self.player) == "number" and JoypadState.players[self.player + 1] then
            setJoypadFocus(self.player, self.prevFocus)
        elseif self.joyfocus and self.joyfocus.focus == self then
            self.joyfocus.focus = self.prevFocus
            updateJoypadFocus(self.joyfocus)
        end
    else
        UIManager.setShowPausedMessage(true)
        self:setVisible(false)
        self:removeFromUIManager()
        if (K == "alarm" or K == "timer") and UIManager.getSpeedControls() then UIManager.getSpeedControls():SetCurrentGameSpeed(1) end
    end
end

-- vanilla's close() (ISTextBox): hide, no answer
function ZeD_Prompt:close()
    hideKeyboard(self)
    releaseFields(self)
    self._dead = true
    self:setVisible(false)
    self:removeFromUIManager()
    if type(self.player) == "number" and JoypadState.players[self.player + 1] then setJoypadFocus(self.player, nil) end
end

-- the button callback, as each vanilla class runs it
function ZeD_Prompt:onClick(button)
    if self._dead then return end   -- answered already: one answer per prompt
    local K = self.kind
    if K == "question" or K == "note" then
        self:destroy()
        if self.onclick ~= nil then
            button.player = self.player
            self.onclick(self.target, button, self.param1, self.param2)
        end
    elseif K == "rich" then
        self:destroy()
        if self.onclick ~= nil then self.onclick(self.target, button, self.param1, self.param2) end
    elseif K == "text" then
        if type(self.player) == "number" and getJoypadData(self.player) then
            setJoypadFocus(self.player, self.prevFocus)
        elseif self.joyfocus and self.joyfocus.focus == self then
            self.joyfocus.focus = self.prevFocus
        end
        if self.onclick ~= nil then
            self.onclick(self.target, button, self.param1, self.param2, self.param3, self.param4)
        end
        if not self.showError then self:destroy() end
    elseif K == "alarm" then
        if button.internal == "OK" then
            local a = self.alarm
            local h = clamp(tonumber(self.hours:getText()) or 0, 0, 23)
            local m = clamp(tonumber(self.mins:getText()) or 0, 0, 59)
            if a then
                a:setAlarmSet(self._alarmOn)
                a:setHour(h)
                a:setMinute(m)
                a:syncAlarmClock()
            end
            self:destroy()
            if type(self.player) == "number" and JoypadState.players[self.player + 1] then setJoypadFocus(self.player, self.prevFocus) end
        end
    elseif K == "timer" then
        self:destroy()
        if self.playerNum and JoypadState.players[self.playerNum + 1] then setJoypadFocus(self.playerNum, self.prevFocus) end
        if self.targetFunc then self.targetFunc(self.target, button, self.param1, self.param2, self.param3, self.param4) end
    end
end

-- press an answer the way a click on vanilla's button would (enabled only, with
-- the button's sound, through the button's own onclick: ZeD_Prompt.onClick unless
-- a caller swapped it)
function ZeD_Prompt:press(b)
    if self._dead or not b or b.enable == false then return end
    sound("UIActivateButton")
    local a = b.onClickArgs or {}
    if b.onclick then b.onclick(b.target, b, a[1], a[2], a[3], a[4]) else self:onClick(b) end
end

-- the player's index (the timer keeps the IsoPlayer in .player, as vanilla's does)
function ZeD_Prompt:pnum()
    if type(self.player) == "number" then return self.player end
    return self.playerNum
end

function ZeD_Prompt:primaryButton()
    if self.kind == "question" or self.kind == "rich" then return self.yesno and self.yes or self.ok end
    if self.kind == "note" or self.kind == "alarm" then return self.ok end
    return self.yes
end

function ZeD_Prompt:pressPrimary()
    if self.kind == "text" then self:updateButtons() end
    self:press(self:primaryButton())
end

-- No / Cancel: the close box, Escape, B. A note's only answer is OK; the alarm
-- closes without a change (vanilla's has no Cancel).
function ZeD_Prompt:answerCancel()
    if self._dead then return end
    local K = self.kind
    if K == "note" then return self:press(self.ok) end
    if K == "rich" then return self:press(self.yesno and self.no or self.ok) end
    if K == "alarm" then
        self:destroy()
        if type(self.player) == "number" and JoypadState.players[self.player + 1] then setJoypadFocus(self.player, self.prevFocus) end
        return
    end
    if self.no then self:press(self.no) end
end

-- ---------------------------------------------------------------------------
-- the list of prompts on screen (Escape and Enter go to the one on top)
-- ---------------------------------------------------------------------------
function ZeD_Prompt:addToUIManager()
    ISUIElement.addToUIManager(self)
    self:setAlwaysOnTop(true)
    untrack(self)
    P.open[#P.open + 1] = self
    self.removed = false
    self._dead = false   -- a kept note (destroyOnClick false) can be shown again
    -- a text prompt opened from the mouse starts with the caret in its field
    if self.kind == "text" and self.entry and not self._focusedOnce then
        self._focusedOnce = true
        local n = self:pnum()
        local p = n and getSpecificPlayer(n)
        if not (p and p:getJoypadBind() ~= -1) then self.entry:focus() end
    end
end

function ZeD_Prompt:removeFromUIManager()
    untrack(self)
    ISUIElement.removeFromUIManager(self)
end

function P.top()
    for i = #P.open, 1, -1 do
        local p = P.open[i]
        if p and not p.removed and p:isReallyVisible() then return p end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- LAYOUT — every frame from the live tokens; geometry in self._g (local px)
-- ---------------------------------------------------------------------------
local function buttonWidth(b)
    local T = ZeD.T
    return math.max(T.px(U.BTN_MIN), tw(T.fontF3, upper(b.title)) + T.px(U.BTN_PAD) * 2)
end

-- answers in footer order: the secondary first, the main one last (on the right)
function ZeD_Prompt:answers()
    local K = self.kind
    if K == "note" or K == "alarm" or (K == "rich" and not self.yesno) then return { self.ok } end
    return { self.no, self.yes }
end

function ZeD_Prompt:stripPrompts()
    local K, f = self.kind, self:focusId()
    local noWord = function(b) local t = tostring(b and b.title or ""); return t:sub(1, 1):upper() .. t:sub(2):lower() end
    if K == "note" then return { { glyph = "A", label = "OK" }, { glyph = "B", label = "OK" } } end
    if K == "rich" then
        local list = {}
        if self._maxScroll and self._maxScroll > 0 then list[#list + 1] = "D-PAD Scroll" end
        if self.yesno then
            list[#list + 1] = "D-PAD Move"
            list[#list + 1] = { glyph = "A", label = "Press" }
            list[#list + 1] = { glyph = "B", label = noWord(self.no) }
        else
            list[#list + 1] = { glyph = "A", label = "OK" }
        end
        return list
    end
    if K == "text" then
        if f == "field" then return { "D-PAD Move", { glyph = "A", label = "Keyboard" }, { glyph = "B", label = "Cancel" } } end
        return { "D-PAD Move", { glyph = "A", label = "Press" }, { glyph = "B", label = "Cancel" } }
    end
    if K == "alarm" then return { "D-PAD Move / Step", { glyph = "A", label = "Press" }, { glyph = "B", label = "Close" } } end
    if K == "timer" then return { "D-PAD Move / Step", { glyph = "A", label = "Press" }, { glyph = "B", label = "Cancel" } } end
    return { "D-PAD Move", { glyph = "A", label = "Press" }, { glyph = "B", label = noWord(self.no) } }
end

-- A field: the prompt draws the inset box (System 7 field: base fill, border, dark
-- inner top-left line); the text field child sits inside it with a little air
-- (the engine draws its text from the child's top-left corner), on no fill of its own.
local function entryH(e, lines)
    local f = e and e.font or UIFont.Small
    return (lines or 1) * getTextManager():getFontHeight(f) + ZeD.T.px(2)
end

local function boxH(e, lines)
    return math.max(ZeD.T.px(26), entryH(e, lines) + ZeD.T.px(8))
end

-- place the child inside its box (only touches Java on a change)
local function placeEntry(e, box)
    if not e then return end
    local T = ZeD.T
    local eh = entryH(e, e._zedLines)
    local x, y = box.x + T.px(6), box.y + math.floor((box.h - eh) / 2)
    local w = box.w - T.px(12)
    if e.x ~= x or e.y ~= y then e:setX(x); e:setY(y) end
    if e.width ~= w or e.height ~= eh then e:setWidth(w); e:setHeight(eh) end
    e.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    e.borderColor = { r = 0, g = 0, b = 0, a = 0 }
end

function ZeD_Prompt:layout()
    local T = ZeD.T
    if not T then return end
    local A = ZeD.Atoms
    local K = self.kind
    local g = { hits = {}, rows = {} }
    local tbH = T.titleBarH
    local footH = T.px(U.FOOT_H)
    local stripH = self.joyfocus and T.sp.scrollbarW or 0
    local padL, padR, padT, padB = T.px(U.PAD_L), T.px(U.PAD_R), T.px(U.PAD_T), T.px(U.PAD_B)
    local l, t, sw, sh = screenBox(self:pnum())
    local maxW = sw - T.px(U.MARGIN) * 2

    -- footer answers
    local answers = self:answers()
    local ansW = 0
    for i, b in ipairs(answers) do ansW = ansW + buttonWidth(b) + (i > 1 and T.px(U.BTN_GAP) or 0) end
    local minW = math.max(T.px(U.MIN_W), ansW + T.px(U.FOOT_PAD) * 2)

    local w, bodyH
    if K == "question" or K == "note" or (K == "rich" and self.yesno) then
        -- a mark beside the words
        local markSz = T.px(U.MARK)
        local font = T.fontF2
        local text = tostring((K == "rich") and (self.chatText and self.chatText.text or self.text) or self.text or "")
        if K == "rich" then
            local parts = {}
            for _, bl in ipairs(P.parseRich(text)) do if bl.text then parts[#parts + 1] = bl.text end end
            text = table.concat(parts, "\n")
        end
        local natural = 0
        for line in (text .. "\n"):gmatch("([^\n]*)\n") do natural = math.max(natural, tw(font, line)) end
        local msgW = clamp(natural, T.px(U.MSG_MIN), T.px(U.MSG_MAX))
        w = math.max(minW, padL + markSz + T.px(U.MARK_GAP) + msgW + padR)
        w = math.min(w, maxW)
        msgW = w - padL - markSz - T.px(U.MARK_GAP) - padR
        local lh = fh(font) + T.px(3)
        local lines = A.wrapText(text, font, msgW)
        local msgH = #lines * lh
        local mark = (K == "note" or (K == "rich" and not self.yesno)) and "note"
                     or (P.isCostly(self.onclick) and "stop" or "question")
        g.mark = { kind = mark, x = padL, y = tbH + padT, sz = markSz }
        local my = tbH + padT + math.max(0, math.floor((markSz - msgH) / 2))
        g.msg = { x = padL + markSz + T.px(U.MARK_GAP), y = my, lines = lines, lh = lh, font = font }
        bodyH = padT + math.max(markSz, msgH) + padB
        g.costly = mark == "stop"
    elseif K == "rich" then
        -- a long note: heading and paragraphs, scrolling as one
        local text = self.chatText and self.chatText.text or self.text
        w = clamp(T.px(U.RICH_W), minW, maxW)
        local sbW = T.sp.scrollbarW
        local cw = w - padL - padR - sbW
        local key = tostring(text) .. "|" .. cw .. "|" .. T.scale
        if self._richKey ~= key then
            self._richKey = key
            self._blocks = P.parseRich(text)
            self._contentH = layoutRich(self._blocks, cw)
        end
        local maxBody = math.min(T.px(U.RICH_MAX_H), sh - tbH - footH - stripH - T.px(U.MARGIN) * 2 - padT)
        local viewH = math.max(T.px(40), math.min(self._contentH, maxBody))
        self._maxScroll = math.max(0, self._contentH - viewH)
        self._scroll = clamp(self._scroll or 0, 0, self._maxScroll)
        g.rich = { x = padL, y = tbH + padT, w = cw, h = viewH }
        if self._maxScroll > 0 then
            g.sb = { x = w - padR - sbW + T.px(4), y = tbH + padT, w = sbW - T.px(4), h = viewH }
            g.hits[#g.hits + 1] = { id = "track", x = g.sb.x, y = g.sb.y, w = g.sb.w, h = g.sb.h }
        end
        bodyH = padT + viewH + T.px(U.PARA_GAP)
    elseif K == "text" then
        local lblFont = T.fontF1
        local label = upper(self.text)
        local callerW = T.px(self._vanillaW or 0)
        w = clamp(math.max(minW, T.px(U.TEXT_W), callerW, tw(lblFont, label) + padL + padR), minW, maxW)
        local y = tbH + padT
        g.label = { x = padL, y = y, text = label, font = lblFont }
        y = y + fh(lblFont) + T.px(U.LABEL_GAP)
        local lines = math.max(1, self.numLines or 1)
        if self.entry then self.entry._zedLines = lines end
        local fieldH = boxH(self.entry, lines)
        g.field = { x = padL, y = y, w = w - padL - padR, h = fieldH }
        g.boxes = { g.field }
        g.rowFocus = { field = { x = padL - T.px(6), y = g.label.y - T.px(6), w = w - padL - padR + T.px(12), h = 0 } }
        placeEntry(self.entry, g.field)
        y = y + fieldH
        if self._colorPicker then
            y = y + T.px(U.LABEL_GAP)
            g.swatches = {}
            local sz = T.px(U.SWATCH)
            for i, c in ipairs(P.SWATCHES) do
                local r = { x = padL + (i - 1) * (sz + T.px(U.SWATCH_GAP)), y = y, w = sz, h = sz, c = c }
                g.swatches[i] = r
                g.hits[#g.hits + 1] = { id = "sw" .. i, x = r.x, y = r.y, w = r.w, h = r.h }
            end
            y = y + sz
        end
        self:updateButtons()
        if self._why and self._why ~= "" then
            y = y + T.px(U.WHY_GAP)
            g.why = { x = padL, y = y, text = self._why }
            y = y + fh(T.fontF2)
        end
        g.rowFocus.field.h = y - g.rowFocus.field.y + T.px(6)
        bodyH = y - tbH + padB
    elseif K == "alarm" then
        w = clamp(math.max(minW, T.px(U.ALARM_W)), minW, maxW)
        local y = tbH + padT
        g.head = { x = padL, y = y, text = getText("IGUI_SetAlarm") }
        y = y + fh(T.fontF2) + T.px(U.HEAD_GAP)
        g.steppers = {}
        g.rowFocus = {}
        g.boxes = {}
        for _, row in ipairs({ { id = "hour", label = "HOUR", entry = self.hours }, { id = "minute", label = "MINUTE", entry = self.mins } }) do
            local vh = boxH(row.entry)
            local rh = math.max(T.px(U.ROW_H), vh + T.px(8))
            local st, gap, vw = T.px(U.STEP), T.px(U.STEP_GAP), T.px(U.VAL_W)
            local right = w - padR
            local plus = { x = right - st, y = y + math.floor((rh - st) / 2), w = st, h = st }
            local val = { x = plus.x - gap - vw, y = y + math.floor((rh - vh) / 2), w = vw, h = vh }
            g.boxes[#g.boxes + 1] = val
            local minus = { x = val.x - gap - st, y = plus.y, w = st, h = st }
            g.steppers[#g.steppers + 1] = { id = row.id, label = row.label, ly = y + math.floor((rh - fh(T.fontF1)) / 2), minus = minus, plus = plus, val = val }
            g.hits[#g.hits + 1] = { id = row.id .. "-", x = minus.x, y = minus.y, w = minus.w, h = minus.h }
            g.hits[#g.hits + 1] = { id = row.id .. "+", x = plus.x, y = plus.y, w = plus.w, h = plus.h }
            g.rowFocus[row.id] = { x = padL - T.px(6), y = y, w = w - padL - padR + T.px(12), h = rh }
            placeEntry(row.entry, val)
            y = y + rh
        end
        local th = T.px(U.TICK_ROW)
        local cb = T.checkboxSz
        g.tick = { x = padL, y = y + math.floor((th - cb) / 2), sz = cb, label = getText("UI_Alarm"), ly = y + math.floor((th - fh(T.fontF2)) / 2) }
        g.hits[#g.hits + 1] = { id = "tick", x = padL, y = y, w = w - padL - padR, h = th }
        g.rowFocus.tick = { x = padL - T.px(6), y = y, w = w - padL - padR + T.px(12), h = th }
        y = y + th
        bodyH = y - tbH + padB
    elseif K == "timer" then
        local lblFont = T.fontF1
        local label = upper(self.prompt or "")
        local steps = { "-10", "-5", "-1", "+1", "+5", "+10" }
        local smW = {}
        local rowW = T.px(U.TVAL_W)
        for i, s in ipairs(steps) do smW[i] = tw(T.fontF3, s) + T.px(U.SM_PAD) * 2; rowW = rowW + smW[i] + T.px(U.SM_GAP) end
        w = clamp(math.max(minW, tw(lblFont, label) + padL + padR, rowW + padL + padR), minW, maxW)
        local y = tbH + padT
        g.label = { x = padL, y = y, text = label, font = lblFont }
        y = y + fh(lblFont) + T.px(U.HEAD_GAP)
        local tvh = boxH(self.textBox)
        local rh = math.max(tvh, T.px(U.SM_H)) + T.px(12)
        local x = math.floor((w - rowW) / 2)
        g.small = {}
        for i, s in ipairs(steps) do
            local r = { x = x, y = y + math.floor((rh - T.px(U.SM_H)) / 2), w = smW[i], h = T.px(U.SM_H), text = s, id = "t" .. s }
            g.small[#g.small + 1] = r
            g.hits[#g.hits + 1] = { id = r.id, x = r.x, y = r.y, w = r.w, h = r.h }
            x = x + smW[i] + T.px(U.SM_GAP)
            if i == 3 then
                g.tval = { x = x, y = y + math.floor((rh - tvh) / 2), w = T.px(U.TVAL_W), h = tvh }
                g.boxes = { g.tval }
                placeEntry(self.textBox, g.tval)
                x = x + T.px(U.TVAL_W) + T.px(U.SM_GAP)
            end
        end
        g.rowFocus = { value = { x = padL - T.px(6), y = y, w = w - padL - padR + T.px(12), h = rh } }
        y = y + rh
        bodyH = y - tbH + padB
    end

    -- footer, answers right-aligned (the main one last)
    local h = tbH + bodyH + footH + stripH
    g.foot = { y = tbH + bodyH, h = footH }
    local bh = T.px(U.BTN_H)
    local bx = w - T.px(U.FOOT_PAD) - ansW
    g.buttons = {}
    for i, b in ipairs(answers) do
        local bw = buttonWidth(b)
        local r = { x = bx, y = g.foot.y + math.floor((footH - bh) / 2), w = bw, h = bh, b = b, id = b.internal }
        g.buttons[#g.buttons + 1] = r
        g.hits[#g.hits + 1] = { id = "btn" .. i, x = r.x, y = r.y, w = r.w, h = r.h, b = b }
        bx = bx + bw + T.px(U.BTN_GAP)
    end
    if stripH > 0 then g.strip = { y = h - stripH, h = stripH } end

    -- size and place: the first time from the anchor, then keeping the centre
    local oldW, oldH = self.width, self.height
    if not self._placed then
        self._placed = true
        self:setWidth(w); self:setHeight(h)
        self:setX(math.floor(self._cx - w / 2)); self:setY(math.floor(self._cy - h / 2))
    elseif oldW ~= w or oldH ~= h then
        local cx, cy = self.x + oldW / 2, self.y + oldH / 2
        self:setWidth(w); self:setHeight(h)
        self:setX(math.floor(cx - w / 2)); self:setY(math.floor(cy - h / 2))
    end
    -- always wholly on screen (vanilla's hangs off the edge near one)
    local m = T.px(U.MARGIN)
    local nx = clamp(self.x, l + m, math.max(l + m, l + sw - w - m))
    local ny = clamp(self.y, t + m, math.max(t + m, t + sh - h - m))
    if nx ~= self.x then self:setX(nx) end
    if ny ~= self.y then self:setY(ny) end
    self._g = g
    self:buildFocusRows()
end

-- the controller's focus grid, row by row
function ZeD_Prompt:buildFocusRows()
    local K = self.kind
    local rows
    if K == "question" or (K == "rich" and self.yesno) then rows = { { "no", "yes" } }
    elseif K == "note" or K == "rich" then rows = { { "ok" } }
    elseif K == "text" then
        rows = { { "field" } }
        if self._colorPicker then
            local sw = {}
            for i = 1, #P.SWATCHES do sw[i] = "sw" .. i end
            rows[#rows + 1] = sw
        end
        rows[#rows + 1] = { "no", "yes" }
    elseif K == "alarm" then rows = { { "hour" }, { "minute" }, { "tick" }, { "ok" } }
    elseif K == "timer" then rows = { { "value" }, { "no", "yes" } }
    else rows = { {} } end
    self._rows = rows
    if not self._focus then
        -- vanilla's first focus: the main answer, or the field / first row
        if K == "question" or (K == "rich" and self.yesno) then self._focus = { 1, 2 }
        else self._focus = { 1, 1 } end
    end
    local r = clamp(self._focus[1], 1, #rows)
    self._focus = { r, clamp(self._focus[2], 1, math.max(1, #rows[r])) }
end

function ZeD_Prompt:focusId()
    if not (self._rows and self._focus) then return nil end
    local row = self._rows[self._focus[1]]
    return row and row[self._focus[2]]
end

-- the swatches a text prompt offers when its caller asks for a colour
P.SWATCHES = {
    { r = 1, g = 1, b = 1 }, { r = 0.13, g = 0.13, b = 0.13 }, { r = 0.65, g = 0.05, b = 0.05 }, { r = 0.85, g = 0.45, b = 0.1 },
    { r = 0.85, g = 0.75, b = 0.15 }, { r = 0.06, g = 0.45, b = 0.17 }, { r = 0.16, g = 0.25, b = 0.6 }, { r = 0.45, g = 0.2, b = 0.55 },
}

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------
-- a button as the menus draw theirs: hover 0.22 / focus 0.55 accent under it,
-- the label in the text colour over a focus fill; off = faded default
local function drawAnswer(p, r, label, variant, state, off)
    local T = ZeD.T
    if off then
        local sb, st = T.borderS, T.text
        T.borderS = ZeD.colorAlpha(sb, (sb.a or 1) * 0.38)
        T.text = ZeD.colorAlpha(st, (st.a or 1) * 0.38)
        ZeD.Molecules.drawButton(p, r.x, r.y, r.w, r.h, label, "default", false)
        T.borderS, T.text = sb, st
        return
    end
    local ac = T.accent
    local colors = nil
    if state == "focus" then
        colors = { fill = { r = ac.r, g = ac.g, b = ac.b, a = 0.55 }, text = T.text }
    elseif state == "hover" then
        colors = { fill = { r = ac.r, g = ac.g, b = ac.b, a = 0.22 } }
    end
    ZeD.Molecules.drawButton(p, r.x, r.y, r.w, r.h, label, variant or "default", state == "down", colors)
end

-- the menus' inset box (System 7 field look) around a field child
local function insetBox(p, r)
    local T = ZeD.T
    local b, bs = T.base, T.borderS
    p:drawRect(r.x, r.y, r.w, r.h, 1, b.r, b.g, b.b)
    p:drawRectBorder(r.x, r.y, r.w, r.h, bs.a or 1, bs.r, bs.g, bs.b)
    p:drawRect(r.x + T.px(1), r.y + T.px(1), r.w - T.px(2), T.px(1), 0.45, 0, 0, 0)
    p:drawRect(r.x + T.px(1), r.y + T.px(1), T.px(1), r.h - T.px(2), 0.45, 0, 0, 0)
end

function ZeD_Prompt:stateOf(id)
    if self.joyfocus then return self:focusId() == id and "focus" or nil end
    if self._down == id and self._hover == id then return "down" end
    if self._hover == id then return "hover" end
    return nil
end

function ZeD_Prompt:prerender()
    local T = ZeD.T
    -- the player's questions wear the Character window's accent when it has its own
    local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
    self._accentKey = cw and cw._accentKey or nil
    -- no minimum size: ZeD_Window.prerender sets the big windows' minimum every frame
    -- and the engine holds an element to it (ISUIElement:onResize)
    self.minimumWidth, self.minimumHeight = 0, 0
    self:layout()
    -- chrome: the window's own (accent, title bar with stripes, close box, body, border)
    ZeD_Window.prerender(self)
    self.minimumWidth, self.minimumHeight = 0, 0
    local g = self._g
    local A, M = ZeD.Atoms, ZeD.Molecules
    local tc, td, ac = T.text, T.textDim, T.accent
    local w = self.width
    local focusOn = self.joyfocus ~= nil
    local function rowFill(r) if r then self:drawRect(r.x, r.y, r.w, r.h, 0.55, ac.r, ac.g, ac.b) end end

    -- the controller's focus: the row under it, first (the boxes and words go over it)
    if focusOn and g.rowFocus then rowFill(g.rowFocus[self:focusId() or ""]) end
    -- the fields' boxes (the field children draw their text over them)
    for _, r in ipairs(g.boxes or {}) do insetBox(self, r) end
    -- mark + words
    if g.mark then
        local tex = markTex(g.mark.kind)
        local tint = g.mark.kind == "stop" and T.danger or tc
        if tex then A.drawIcon(self, tex, g.mark.x, g.mark.y, g.mark.sz, 1, tint) end
    end
    if g.msg then
        for i, line in ipairs(g.msg.lines) do
            self:drawText(line, g.msg.x, g.msg.y + (i - 1) * g.msg.lh, tc.r, tc.g, tc.b, tc.a or 1, g.msg.font)
        end
    end
    -- the text prompt
    if g.field then
        local lc = (focusOn and self:focusId() == "field") and tc or ac
        self:drawText(g.label.text, g.label.x, g.label.y, lc.r, lc.g, lc.b, lc.a or 1, g.label.font)
    end
    if g.swatches then
        for i, r in ipairs(g.swatches) do
            local c = r.c
            local st = self:stateOf("sw" .. i)
            if st == "focus" then self:drawRect(r.x - T.px(3), r.y - T.px(3), r.w + T.px(6), r.h + T.px(6), 0.55, ac.r, ac.g, ac.b) end
            self:drawRect(r.x, r.y, r.w, r.h, 1, c.r, c.g, c.b)
            local cur = self.currentColor
            local sel = cur and math.abs(cur:getR() - c.r) < 0.01 and math.abs(cur:getG() - c.g) < 0.01 and math.abs(cur:getB() - c.b) < 0.01
            local bc = sel and ac or T.borderS
            self:drawRectBorder(r.x, r.y, r.w, r.h, bc.a or 1, bc.r, bc.g, bc.b)
        end
    end
    if g.why then
        local dsz = T.px(7)
        local f2 = T.fontF2
        A.drawStatusDot(self, g.why.x, g.why.y + math.floor((fh(f2) - dsz) / 2), T.danger, dsz)
        self:drawText(A.truncateText(g.why.text, f2, w - g.why.x * 2 - dsz - T.px(7)), g.why.x + dsz + T.px(7), g.why.y, tc.r, tc.g, tc.b, tc.a or 1, f2)
    end
    -- the alarm
    if g.head then self:drawText(g.head.text, g.head.x, g.head.y, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2) end
    if g.steppers then
        for _, s in ipairs(g.steppers) do
            local f = focusOn and self:focusId() == s.id
            local lc = f and tc or ac
            self:drawText(s.label, T.px(U.PAD_L), s.ly, lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)
            drawAnswer(self, s.minus, "-", "default", (not focusOn) and self:stateOf(s.id .. "-") or nil)
            drawAnswer(self, s.plus, "+", "default", (not focusOn) and self:stateOf(s.id .. "+") or nil)
        end
    end
    if g.tick then
        local f = focusOn and self:focusId() == "tick"
        A.drawCheckbox(self, g.tick.x, g.tick.y, self._alarmOn, (not focusOn) and self._hover == "tick", false)
        self:drawText(g.tick.label, g.tick.x + g.tick.sz + T.px(8), g.tick.ly, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
    end
    -- the timer
    if g.small then
        local lc = (focusOn and self:focusId() == "value") and tc or ac
        self:drawText(g.label.text, g.label.x, g.label.y, lc.r, lc.g, lc.b, lc.a or 1, g.label.font)
        for _, r in ipairs(g.small) do
            drawAnswer(self, r, r.text, "default", (not focusOn) and self:stateOf(r.id) or nil)
        end
    end
    -- the long note (clipped to its view, scrolled as one)
    if g.rich then
        local r = g.rich
        self:setStencilRect(r.x, r.y, r.w, r.h)
        local oy = r.y - (self._scroll or 0)
        for _, bl in ipairs(self._blocks or {}) do
            if bl.kind == "image" then
                local ix = r.x + math.floor((r.w - bl.dw) / 2)
                if oy + bl.y + bl.dh > r.y and oy + bl.y < r.y + r.h then
                    self:drawTextureScaledAspect(bl.tex, ix, oy + bl.y, bl.dw, bl.dh, 1, 1, 1, 1)
                end
            else
                local c = bl.kind == "head" and (T.textHead or tc) or tc
                for i, line in ipairs(bl.lines) do
                    local ly = oy + bl.y + (i - 1) * bl.lh
                    if ly + bl.lh > r.y and ly < r.y + r.h then
                        self:drawText(line, r.x, ly, c.r, c.g, c.b, c.a or 1, bl.font)
                    end
                end
            end
        end
        self:clearStencilRect()
        if g.sb then
            local sb = g.sb
            A.drawScrollTrack(self, sb.x, sb.y, sb.w, sb.h)
            local frac = r.h / math.max(1, self._contentH)
            local thH = math.max(T.px(20), math.floor(sb.h * frac))
            local ty = sb.y + math.floor((sb.h - thH) * ((self._scroll or 0) / math.max(1, self._maxScroll)))
            A.drawScrollThumb(self, sb.x, ty, sb.w, thH, self._hover == "track" and "hover" or "default")
        end
    end

    -- footer: the action zone
    local f = g.foot
    local s2, bs = T.surf2, T.borderS
    self:drawRect(T.px(1), f.y, w - T.px(2), f.h, s2.a or 1, s2.r, s2.g, s2.b)
    A.drawDividerH(self, T.px(1), f.y, w - T.px(2), false)
    for i, r in ipairs(g.buttons) do
        local b = r.b
        local variant = "default"
        if i == #g.buttons then variant = g.costly and "danger" or "primary" end
        local id = (b == self.yes and "yes") or (b == self.no and "no") or "ok"
        local st = focusOn and (self:focusId() == id and "focus" or nil) or self:stateOf("btn" .. i)
        drawAnswer(self, r, upper(b.title), variant, st, b.enable == false)
    end
    -- the controller's strip: what the buttons do here
    if g.strip then
        self:drawRect(T.px(1), g.strip.y, w - T.px(2), g.strip.h, s2.a or 1, s2.r, s2.g, s2.b)
        A.drawDividerH(self, T.px(1), g.strip.y, w - T.px(2), false)
        M.drawGlyphPrompts(self, T.sp.sm, g.strip.y, g.strip.h, self:stripPrompts())
    end
end

function ZeD_Prompt:render()
    ZeD_Window.render(self)
end

-- ---------------------------------------------------------------------------
-- MOUSE (the prompt is top-level, so its own events arrive; fields are children)
-- ---------------------------------------------------------------------------
function ZeD_Prompt:hitAt(x, y)
    local g = self._g
    if not g then return nil end
    for _, h in ipairs(g.hits) do if inRect(h, x, y) then return h end end
    return nil
end

function ZeD_Prompt:activate(id, hit)
    if not id then return end
    if hit and hit.b then return self:press(hit.b) end
    if id == "hour-" or id == "hour+" then self:stepAlarm("hour", id == "hour+" and 1 or -1); sound("UISelectListItem")
    elseif id == "minute-" or id == "minute+" then self:stepAlarm("minute", id == "minute+" and 1 or -1); sound("UISelectListItem")
    elseif id == "tick" then self._alarmOn = not self._alarmOn; sound("UISelectListItem")
    elseif id:sub(1, 1) == "t" and tonumber(id:sub(2)) then self:addTime(tonumber(id:sub(2))); sound("UISelectListItem")
    elseif id:sub(1, 2) == "sw" then
        local c = P.SWATCHES[tonumber(id:sub(3))]
        if c then self:onPickedColor(c); sound("UISelectListItem") end
    end
end

function ZeD_Prompt:onMouseDown(x, y)
    if not self:getIsVisible() then return true end
    local T = ZeD.T
    local tbH = self:titleBarHeight()
    local cb = self:closeRect()
    if cb and inRect(cb, x, y) then self._down = "close"; return true end
    if y < tbH then
        -- drag by the title bar (no window shade on a prompt)
        self.moving = true
        self:bringToTop()
        return true
    end
    local h = self:hitAt(x, y)
    if h and h.id == "track" and self._g.sb then
        -- a click on the track pages the note
        local sb = self._g.sb
        local page = self._g.rich.h - T.px(20)
        self._scroll = clamp((self._scroll or 0) + ((y < sb.y + sb.h / 2) and -page or page), 0, self._maxScroll or 0)
        return true
    end
    self._down = h and h.id or nil
    self._downHit = h
    return true
end

function ZeD_Prompt:onMouseUp(x, y)
    self.moving = false
    local down = self._down
    self._down = nil
    if down == "close" then
        local cb = self:closeRect()
        if cb and inRect(cb, x, y) then sound("UIActivateButton"); self:answerCancel() end
        return true
    end
    if down then
        local h = self:hitAt(x, y)
        if h and h.id == down then self:activate(down, h) end
    end
    return true
end

function ZeD_Prompt:onMouseUpOutside(x, y)
    self.moving = false
    self._down = nil
end

function ZeD_Prompt:onMouseMove(dx, dy)
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
    end
end

function ZeD_Prompt:onMouseMoveOutside(dx, dy)
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
    end
end

-- the wheel steps a value under the pointer, or scrolls the note
function ZeD_Prompt:onMouseWheel(del)
    local g = self._g
    if not g then return true end
    local x, y = self:getMouseX(), self:getMouseY()
    local dir = del > 0 and 1 or -1   -- PZ: a positive delta is the wheel turned down (towards you)
    if g.rich and self._maxScroll and self._maxScroll > 0 then
        self._scroll = clamp((self._scroll or 0) + dir * ZeD.T.px(40), 0, self._maxScroll)
        return true
    end
    if g.steppers then
        for _, s in ipairs(g.steppers) do
            local row = g.rowFocus[s.id]
            if row and inRect(row, x, y) then self:stepAlarm(s.id, -dir); return true end
        end
    end
    if g.tval and g.rowFocus and g.rowFocus.value and inRect(g.rowFocus.value, x, y) then self:addTime(-dir); return true end
    return true
end

function ZeD_Prompt:update()
    ISPanel.update(self)
    -- the controller that holds this prompt (a caller may set .focus without telling it)
    local jf = nil
    if JoypadState and JoypadState.players then
        for i = 1, 4 do
            local jd = JoypadState.players[i]
            if jd and jd.focus == self then jf = jd; break end
        end
    end
    if P.qaJoy then jf = P.qaJoy end   -- QA: the controller look without a controller (zedqa_prompts.lua)
    if jf ~= self.joyfocus then
        self.joyfocus = jf
        if jf then self:buildFocusRows() end
    end
    -- hover (the mouse's 0.22 cue), and the close box's
    local x, y = self:getMouseX(), self:getMouseY()
    local h = self:hitAt(x, y)
    self._hover = h and h.id or nil
    local cb = self:closeRect()
    self._closeHover = cb and inRect(cb, x, y) or false
    -- vanilla's alarm closes when the character takes a step
    if self.kind == "alarm" and self.character and self.playerX then
        if math.abs(self.character:getX() - self.playerX) > 0.1 or math.abs(self.character:getY() - self.playerY) > 0.1 then
            self:destroy()
        end
    end
end

-- ---------------------------------------------------------------------------
-- CONTROLLER (setJoypadFocus(player, prompt) by the caller, as for vanilla's)
-- ---------------------------------------------------------------------------
function ZeD_Prompt:onGainJoypadFocus(joypadData)
    self.joyfocus = joypadData
    self:buildFocusRows()
end

function ZeD_Prompt:onLoseJoypadFocus(joypadData)
    self.joyfocus = nil
end

function ZeD_Prompt:onJoypadBeforeDeactivate(joypadData)
    if self.removeIfJoypadDeactivated then self:destroy() end
end

function ZeD_Prompt:onJoypadDown(button, joypadData)
    self.joyfocus = self.joyfocus or joypadData
    if button == Joypad.AButton then
        local id = self:focusId()
        if id == "yes" then return self:press(self.yes) end
        if id == "no" then return self:press(self.no) end
        if id == "ok" then return self:press(self.ok) end
        if id == "field" then return self:openKeyboard(joypadData) end
        if id == "tick" then self._alarmOn = not self._alarmOn; sound("UISelectListItem"); return end
        if id and id:sub(1, 2) == "sw" then return self:activate(id) end
        return
    end
    if button == Joypad.BButton then return self:answerCancel() end
end

function ZeD_Prompt:openKeyboard(joypadData)
    if not (self.entry and OnScreenKeyboard and OnScreenKeyboard.Show) then return end
    local jd = joypadData or self.joyfocus
    local osk = OnScreenKeyboard.Show(jd and jd.player or self.player or 0, self.entry, jd)
    if osk and jd then
        osk.prevFocus = self
        jd.focus = osk
        updateJoypadFocus(jd)
    end
end

local function moveFocus(self, dr, dc)
    if not self._rows then self:buildFocusRows() end
    local r, c = self._focus[1], self._focus[2]
    if dr ~= 0 then
        local nr = clamp(r + dr, 1, #self._rows)
        if nr ~= r then
            -- keep to the same side: the last answer stays the last answer
            local from = self._rows[r]
            local to = self._rows[nr]
            local nc = (#from > 1 and c == #from) and #to or clamp(c, 1, #to)
            self._focus = { nr, nc }
            sound("UISelectListItem")
        end
    elseif dc ~= 0 then
        local row = self._rows[r]
        local nc = clamp(c + dc, 1, #row)
        if nc ~= c then self._focus = { r, nc }; sound("UISelectListItem") end
    end
end

function ZeD_Prompt:onJoypadDirUp(joypadData)
    if self.kind == "rich" and self._maxScroll and self._maxScroll > 0 then
        self._scroll = clamp((self._scroll or 0) - ZeD.T.px(40), 0, self._maxScroll); return
    end
    moveFocus(self, -1, 0)
end

function ZeD_Prompt:onJoypadDirDown(joypadData)
    if self.kind == "rich" and self._maxScroll and self._maxScroll > 0 and (self._scroll or 0) < self._maxScroll then
        self._scroll = clamp((self._scroll or 0) + ZeD.T.px(40), 0, self._maxScroll); return
    end
    moveFocus(self, 1, 0)
end

local function sideStep(self, dir)
    local id = self:focusId()
    if id == "hour" or id == "minute" then self:stepAlarm(id, dir); sound("UISelectListItem"); return true end
    if id == "value" then self:addTime(dir); sound("UISelectListItem"); return true end
    return false
end

function ZeD_Prompt:onJoypadDirLeft(joypadData)
    if not sideStep(self, -1) then moveFocus(self, 0, -1) end
end

function ZeD_Prompt:onJoypadDirRight(joypadData)
    if not sideStep(self, 1) then moveFocus(self, 0, 1) end
end

-- ---------------------------------------------------------------------------
-- builders the hooks call (vanilla's :new arguments, unchanged)
-- ---------------------------------------------------------------------------
function P.question(x, y, width, height, text, yesno, target, onclick, player, param1, param2)
    text = tostring(text or ""):gsub("\\n", "\n")
    local cx, cy = P.anchor(x, y, width, height, player)
    local o = ZeD_Prompt:new(yesno and "question" or "note", cx, cy, player)
    o.text, o.yesno, o.target, o.onclick, o.param1, o.param2 = text, yesno, target, onclick, param1, param2
    return o
end

function P.rich(x, y, width, height, text, yesno, target, onclick, player, param1, param2)
    local cx, cy = P.anchor(x, y, width, height, player)
    local o = ZeD_Prompt:new("rich", cx, cy, player)
    o.text, o.yesno, o.target, o.onclick, o.param1, o.param2 = text, yesno, target, onclick, param1, param2
    o.destroyOnClick = true
    o.yesText, o.noText = "UI_Yes", "UI_No"
    return o
end

function P.textBox(x, y, width, height, text, defaultEntryText, target, onclick, player, param1, param2, param3, param4)
    local cx, cy = P.anchor(x, y, width, height, player)
    local o = ZeD_Prompt:new("text", cx, cy, player)
    o.text, o.defaultEntryText, o.target, o.onclick = text, defaultEntryText, target, onclick
    o.param1, o.param2, o.param3, o.param4 = param1, param2, param3, param4
    o.numLines, o.maxLines, o.multipleLine = 1, 1, false
    o._vanillaW = width
    o.titlebarbkg = getTexture("media/ui/Panel_TitleBar.png")
    return o
end

function P.alarm(x, y, width, height, player, alarm)
    local cx, cy = P.anchor(x, y, width, height, player, true)
    local o = ZeD_Prompt:new("alarm", cx, cy, player)
    local p = type(player) == "number" and getSpecificPlayer(player) or nil
    o.character, o.alarm = p, alarm
    o.playerX, o.playerY = p and p:getX(), p and p:getY()
    return o
end

function P.timer(x, y, width, height, prompt, time, player, target, targetFunc, param1, param2, param3, param4)
    local num = player and player.getPlayerNum and player:getPlayerNum() or 0
    local cx, cy = P.anchor(x, y, width, height, num, true)
    local o = ZeD_Prompt:new("timer", cx, cy, num)
    o.player = player          -- vanilla keeps the IsoPlayer here and the number in playerNum
    o.playerNum = num
    o.playerX, o.playerY = player and player:getX(), player and player:getY()
    o.prompt, o.time, o.target, o.targetFunc = prompt, time, target, targetFunc
    o.param1, o.param2, o.param3, o.param4 = param1, param2, param3, param4
    return o
end
