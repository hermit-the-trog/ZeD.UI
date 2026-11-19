-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Tutorial.lua
-- ============================================================================
-- THE TOUR (beta 21, the director, Nov 18 2026: "Tutorial but it is an option up front to skip. Balloons guide
-- through each window."; the words approved Nov 19). Client.
--
-- Asked for on the first-launch setup (ZeD_MainMenuWelcome.lua: Tutorial, Show me around, which writes
-- Zomboid/Lua/ZeD_tutorial.txt "1", or "pad" when Playing with is Controller). The first game after that, a few
-- seconds after it is playable, a run of balloons (Balloon.lua, the one Balloon Help) points at one thing each: the
-- belt, the watch, the Character window, an item's card, the World window, a window's menu, the guide. Each step
-- opens what it shows. Under each balloon, Next and Stop tour (the controller: A and B). The last step's Next reads
-- Done. Stop or Done writes "0", so the tour never comes back by itself. A step whose thing is not on screen (no
-- watch worn, the belt off) is passed over.
--
-- The balloon draws on a click-through layer over the whole screen; the two keys are a small panel of their own
-- under it, the only part that takes the pointer (and, while the tour runs, the controller).
-- ============================================================================
require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Balloon"

ZeD = ZeD or {}
ZeD.Tutorial = ZeD.Tutorial or {}
local TU = ZeD.Tutorial
TU.FILE = "ZeD_tutorial.txt"
TU.WAIT_MS = 6000          -- after the game is playable
TU.WAIT_SHOW_MS = 2000     -- how long a step waits for what it opens to come up

local function tr(k, ...) return ZeD.tr(k, ...) end

local function readFirst()
    local ok, r = pcall(function() return getFileReader(TU.FILE, false) end)
    if not (ok and r) then return nil end
    local l = nil
    pcall(function() l = r:readLine() end)
    pcall(function() r:close() end)
    return l
end
local function writeWord(word)
    local ok, w = pcall(function() return getFileWriter(TU.FILE, true, false) end)
    if not (ok and w) then return end
    pcall(function() w:write(word) end)
    pcall(function() w:close() end)
end

--- "mouse", "pad" or nil (not asked for, or done)
function TU.wanted()
    local l = readFirst()
    if l == "1" then return "mouse" end
    if l == "pad" then return "pad" end
    return nil
end

-- a UI element's screen rect, or nil when it is not on screen
local function rectOf(el)
    if not el then return nil end
    local ok, vis = pcall(function() return el:isReallyVisible() end)
    if not (ok and vis) then return nil end
    return { x = el:getAbsoluteX(), y = el:getAbsoluteY(), w = el:getWidth(), h = el:getHeight() }
end
local function charWin(pn) return ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow(pn) end
local function worldWin(pn) return ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow(pn) end
-- (QA, Nov 19 2026: a window made earlier and since shut keeps its place in the window's table, hidden, so opening a tab
-- on it showed nothing and the tour passed the step over. A hidden window is closed for good first, toggle, and made
-- fresh, toggle again, as the player's own key does.)
local function ensureChar(pn)
    if not ZeD_CharacterWindow then return end
    local w = charWin(pn)
    if w and w:isReallyVisible() then return end
    if w and ZeD_CharacterWindow.toggle then pcall(ZeD_CharacterWindow.toggle, pn) end
    if ZeD_CharacterWindow.openTab then pcall(ZeD_CharacterWindow.openTab, pn, "loot") end
end
-- (the director, Nov 19 2026, from QA's report pictures: the card step described a card that was not on screen. It
-- opens one: the first thing the character carries and does not wear or hold, picked as a click picks it, so the
-- window's own drawer shows its card.)
local function ensureCard(pn)
    ensureChar(pn)
    local w = charWin(pn)
    if not (w and w._contentPanel and w._updateDrawer) or w._drawerMode == "item" then return end
    local chr = getSpecificPlayer(pn)
    local inv = chr and chr:getInventory()
    if not inv then return end
    local pickIt = nil
    local ok = pcall(function()
        local items = inv:getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            local worn = it and it:isEquipped()   -- (InventoryItem.isEquipped: worn, held or on the belt)
            if it and not worn then pickIt = it; break end
        end
    end)
    if not (ok and pickIt) then return end
    w._contentPanel._selectedItems = { [pickIt] = true }
    pcall(w._updateDrawer, w._contentPanel)
end
TU._ensureCard = ensureCard   -- (the test sim's way in)
local function ensureWorld(pn)
    if not ZeD_WorldWindow then return end
    local w = worldWin(pn)
    if w and w:isReallyVisible() then return end
    if w and ZeD_WorldWindow.toggle then pcall(ZeD_WorldWindow.toggle, pn) end
    if ZeD_WorldWindow.open then pcall(ZeD_WorldWindow.open, pn) end
end

-- The steps: the words' keys (UI_ZeD_Tut_<key>_Title, _Text, and _Pad for a controller's words), what to open, what
-- to point at, the side the balloon prefers.
TU.STEPS = {
    { key = "Belt", target = function(pn) return rectOf(ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD(pn)) end, pref = "above" },
    { key = "Watch", target = function(pn) return rectOf(ZeD.Watch and ZeD.Watch._instance) end, pref = "below" },
    { key = "Char", prepare = ensureChar, target = function(pn) return rectOf(charWin(pn)) end, pref = "right" },
    { key = "Card", prepare = ensureCard, target = function(pn) return rectOf(charWin(pn)) end, pref = "right" },
    { key = "World", prepare = ensureWorld, target = function(pn) return rectOf(worldWin(pn)) end, pref = "left" },
    { key = "Menu", prepare = ensureWorld, target = function(pn)
        local w = worldWin(pn)
        if not (w and w:isReallyVisible() and w.windowBoxRect) then return nil end
        local ok, r = pcall(w.windowBoxRect, w)
        if not (ok and r and r.w) then return nil end
        return { x = w:getAbsoluteX() + r.x, y = w:getAbsoluteY() + r.y, w = r.w, h = r.h }
    end, pref = "below" },
    { key = "Guide", target = function(pn) return rectOf(ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD(pn)) end, pref = "above" },
}

-- ---------------------------------------------------------------------------
-- THE KEYS UNDER THE BALLOON
-- ---------------------------------------------------------------------------
ZeD_TutorialKeys = ISPanel:derive("ZeD_TutorialKeys")

function ZeD_TutorialKeys:new()
    local o = ISPanel.new(self, 0, 0, 10, 10)
    o.background = false
    o._down = nil
    return o
end
function ZeD_TutorialKeys:keyRects()
    local T = ZeD.T
    local nextW = ZeD.Molecules.buttonW(self.nextWord or "")
    local stopW = ZeD.Molecules.buttonW(tr("UI_ZeD_Tut_Stop"))
    return { x = stopW + T.px(6), y = 0, w = nextW, h = T.buttonH, id = "next" }, { x = 0, y = 0, w = stopW, h = T.buttonH, id = "stop" }
end
-- (QA: the keys read as see-through over the game; each sits on the balloon's own light paper, solid)
function ZeD_TutorialKeys:prerender()
    local n, s = self:keyRects()
    local pal = ZeD.Balloon and ZeD.Balloon.PALETTE
    local c = (pal and pal.surf2) or ZeD.T.surf2
    for _, r in ipairs({ n, s }) do
        ZeD.Atoms.fillRounded(self, r.x, r.y, r.w, r.h, c.r, c.g, c.b, 1)
    end
end
function ZeD_TutorialKeys:render()
    local T = ZeD.T
    local n, s = self:keyRects()
    local mx, my = self:getMouseX(), self:getMouseY()
    local function over(r) return mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h end
    ZeD.Molecules.drawButton(self, s.x, s.y, s.w, s.h, tr("UI_ZeD_Tut_Stop"), "default", self._down == "stop", nil, { hover = over(s) })
    ZeD.Molecules.drawButton(self, n.x, n.y, n.w, n.h, self.nextWord or "", "primary", self._down == "next", nil, { hover = over(n), default = true })
end
function ZeD_TutorialKeys:onMouseDown(x, y)
    local n, s = self:keyRects()
    if x >= n.x and x < n.x + n.w then self._down = "next" elseif x < s.x + s.w then self._down = "stop" end
    return true
end
function ZeD_TutorialKeys:onMouseUp(x, y)
    local down = self._down
    self._down = nil
    local n, s = self:keyRects()
    if down == "next" and x >= n.x and x < n.x + n.w then TU.next()
    elseif down == "stop" and x >= s.x and x < s.x + s.w then TU.stop() end
    return true
end
function ZeD_TutorialKeys:onMouseUpOutside() self._down = nil end
function ZeD_TutorialKeys:onJoypadDown(button)
    if button == Joypad.AButton then TU.next() elseif button == Joypad.BButton then TU.stop() end
end

-- ---------------------------------------------------------------------------
-- THE LAYER: the balloon, every frame, pointing at the step's thing
-- ---------------------------------------------------------------------------
local function newLayer()
    local layer = ISPanel:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight())
    layer:initialise()
    layer:instantiate()
    layer.background = false
    layer.javaObject:setConsumeMouseEvents(false)
    layer.prerender = function() end
    layer.onMouseDown = function() return false end
    layer.onMouseUp = function() return false end
    layer.onMouseWheel = function() return false end
    layer.onRightMouseDown = function() return false end
    layer.onRightMouseUp = function() return false end
    layer.render = function(self) TU.draw(self) end
    return layer
end

local R = { on = false, i = 0, pn = 0, mode = "mouse", layer = nil, keys = nil, content = nil, anchor = {} }
TU._state = R   -- (the test sim's way in)

local function stepWords(st)
    local base = "UI_ZeD_Tut_" .. st.key
    local text = tr(base .. "_Text")
    if R.mode == "pad" then
        local p = tr(base .. "_Pad")
        if p and p ~= "" and p ~= base .. "_Pad" then text = p end   -- (a step with no controller words keeps the mouse's)
    end
    return tr(base .. "_Title"), text
end

-- the next step with something on screen, from i (opening what it needs); nil past the last
local function findStep(i)
    while i <= #TU.STEPS do
        local st = TU.STEPS[i]
        if st.prepare then pcall(st.prepare, R.pn) end
        local ok, r = pcall(st.target, R.pn)
        -- (a step that opens what it shows waits for it: the window may come up a frame later; TU.draw passes the
        -- step over if it is still not there after WAIT_SHOW_MS)
        if (ok and r) or st.prepare then return i end
        i = i + 1
    end
    return nil
end

local function giveKeysThePad()
    local jd = JoypadState and JoypadState.players and JoypadState.players[R.pn + 1]
    if jd and R.keys then pcall(setJoypadFocus, R.pn, R.keys) end
end

local function show(i)
    local found = findStep(i)
    if not found then TU.finish(); return end
    R.i = found
    R.shownAt = getTimestampMs()
    local title, text = stepWords(TU.STEPS[found])
    R.content = { title = title, lines = { text, { text = tr("UI_ZeD_Tut_StepOf", found, #TU.STEPS), font = ZeD.T.fontF3 } } }
    R.keys.nextWord = (found == #TU.STEPS) and tr("UI_ZeD_Tut_Done") or tr("UI_ZeD_Tut_Next")
    giveKeysThePad()
end

function TU.draw(layer)
    if not R.on then return end
    local st = TU.STEPS[R.i]
    if not st then return end
    local ok, r = pcall(st.target, R.pn)
    if not (ok and r) then
        R.keys:setVisible(false)
        if R.shownAt and getTimestampMs() - R.shownAt > TU.WAIT_SHOW_MS then
            if R.i >= #TU.STEPS then TU.finish() else show(R.i + 1) end
        end
        return
    end
    local a = R.anchor
    a.x, a.y, a.w, a.h, a.below, a.noFlip = r.x, r.y, r.w, r.h, nil, nil
    local x, y, w, h = ZeD.Balloon.draw(layer, R.content, a, st.pref, { key = "tutorial:" .. R.i, prio = 3, noClaim = true, owner = layer })
    if not x then R.keys:setVisible(false); return end
    -- the keys under the balloon's box (above it when the box is at the screen's foot)
    local T = ZeD.T
    local n, s = R.keys:keyRects()
    local kw = n.x + n.w
    local kx = x + w - kw
    -- (QA, Nov 19 2026: under the box, the keys lay over the belt the balloon points at. They go on the box's far
    -- side from the thing: above a box that sits above it, below a box that sits below or beside it.)
    local ax, ay = layer:getAbsoluteX(), layer:getAbsoluteY()
    local boxTop, boxBot = ay + y, ay + y + h
    local ky
    if boxBot <= r.y + T.px(2) then ky = y - T.buttonH - T.px(6)
    else ky = y + h + T.px(6) end
    if ay + ky + T.buttonH > getCore():getScreenHeight() then ky = y - T.buttonH - T.px(6) end
    if ay + ky < 0 then ky = y + h + T.px(6) end
    kx, ky = ax + kx, ay + ky
    R.keys:setX(kx); R.keys:setY(ky); R.keys:setWidth(kw); R.keys:setHeight(T.buttonH)
    if not R.keys:getIsVisible() then R.keys:setVisible(true) end
end

--- Start the tour for player pn (mode "mouse" or "pad").
function TU.start(pn, mode)
    if R.on then return end
    R.on, R.pn, R.mode = true, pn or 0, mode or "mouse"
    if not R.layer then R.layer = newLayer() end
    if not R.keys then
        R.keys = ZeD_TutorialKeys:new()
        R.keys:initialise()
        R.keys:instantiate()
    end
    R.layer:setWidth(getCore():getScreenWidth()); R.layer:setHeight(getCore():getScreenHeight())
    R.layer:addToUIManager(); R.layer:setAlwaysOnTop(true)
    R.keys:addToUIManager(); R.keys:setAlwaysOnTop(true); R.keys:setVisible(false)
    show(1)
end

function TU.next()
    if not R.on then return end
    pcall(function() ZeD.uiSound("UIActivateButton") end)
    if R.i >= #TU.STEPS then TU.finish(); return end
    show(R.i + 1)
end

local function close()
    R.on = false
    if R.layer then R.layer:removeFromUIManager() end
    if R.keys then
        R.keys:setVisible(false)
        R.keys:removeFromUIManager()
        local jd = JoypadState and JoypadState.players and JoypadState.players[R.pn + 1]
        if jd and jd.focus == R.keys then pcall(setJoypadFocus, R.pn, nil) end
    end
    writeWord("0")
end
function TU.stop() pcall(function() ZeD.uiSound("UIActivateButton") end); close() end
function TU.finish() close() end
function TU.running() return R.on end
function TU.step() return R.i end

-- the first game after the setup asked for it: a few seconds after the game is playable, player one
local startAt = nil
local function tick()
    if not startAt then return end
    if getTimestampMs() < startAt then return end
    startAt = nil
    Events.OnTick.Remove(tick)
    local mode = TU.wanted()
    if not mode or (ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on()) then return end
    if not getSpecificPlayer(0) then return end
    TU.start(0, mode)
end
Events.OnGameStart.Add(function()
    if not TU.wanted() then return end
    startAt = getTimestampMs() + TU.WAIT_MS
    Events.OnTick.Remove(tick)
    Events.OnTick.Add(tick)
end)

return TU
