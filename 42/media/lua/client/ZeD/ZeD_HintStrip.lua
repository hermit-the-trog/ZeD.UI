-- ZeD-UI/42/media/lua/client/ZeD/ZeD_HintStrip.lua
-- ============================================================================
-- THE HINT STRIP: one quiet strip for keyboard and controller alike, "E Open door | Right-click More". Client-side
-- HUD panel, plus a wrap on the game's ISButtonPrompt; ZeD setup picks Always (the default), First hours or Off. It
-- shows what you can do with what is in front of you, in the game's own words and by the game's own rules
-- (ISButtonPrompt: the controller prompt's getBest* functions), so it says only what the game would do.
--
--   On a controller   the game works out its prompts every tick (getButtonPrompts(pn)); the strip reads them and
--                     draws them with ZeD's button pictures, and the game's corner prompt is not drawn.
--   Keyboard, mouse   the game has no prompts. A second ISButtonPrompt of ZeD's own runs the same rules a few times
--                     a second; the interact key is shown for what it does (doors, windows, fences, cars: the game's
--                     Interact key does those), and right-click for the menu of what is there.
--   First hours       each hint stops after it has been used USES times (counted in Zomboid/Lua/ZeD_hints.txt).
--
-- Never shown while a window or menu has the controller, while the game is paused, asleep or dead, or in safe mode.
-- It sits just above the belt, centred, and takes no clicks.
-- ============================================================================

ZeD = ZeD or {}
ZeD.HintStrip = ZeD.HintStrip or {}
local H = ZeD.HintStrip

local USES = 3                -- First hours: a hint stops after this many uses
local EVAL_MS = 200           -- keyboard: the rules run this often
local FILE = "ZeD_hints.txt"

local function now() return getTimestampMs() end
local function mode()
    local S = ZeD.Settings
    return (S and S.hintStripMode and S.hintStripMode()) or "always"
end
local function onPad(pn) return JoypadState and JoypadState.players and JoypadState.players[pn + 1] ~= nil or false end

-- ---------------------------------------------------------------------------
-- First hours: the uses, kept
-- ---------------------------------------------------------------------------
H.uses = H.uses or nil
local function loadUses()
    H.uses = {}
    local r = nil
    pcall(function() r = getFileReader(FILE, false) end)
    if not r then return end
    pcall(function()
        local l = r:readLine()
        while l do
            local k, n = l:match("^(.-)=(%d+)$")
            if k then H.uses[k] = tonumber(n) end
            l = r:readLine()
        end
    end)
    pcall(function() r:close() end)
end
local function saveUses()
    pcall(function()
        local w = getFileWriter(FILE, true, false)
        if not w then return end
        local keys = {}
        for k in pairs(H.uses or {}) do keys[#keys + 1] = k end
        table.sort(keys)
        for _, k in ipairs(keys) do w:write(k .. "=" .. tostring(H.uses[k]) .. "\n") end
        w:close()
    end)
end
-- a hint's key: the game's function for it, else its words
local function useKey(fn, text)
    for name, f in pairs(ISButtonPrompt or {}) do if f == fn then return name end end
    return tostring(text or "")
end
function H.used(fn, text)
    if not H.uses then loadUses() end
    local k = useKey(fn, text)
    if k == "" then return end
    H.uses[k] = (H.uses[k] or 0) + 1
    saveUses()
end
local function spent(fn, text)
    if mode() ~= "first" then return false end
    if not H.uses then loadUses() end
    return (H.uses[useKey(fn, text)] or 0) >= USES
end

-- ---------------------------------------------------------------------------
-- the prompts
-- ---------------------------------------------------------------------------
-- (doors and windows: the game sets their prompt with no function — the Java does the press — so those
-- are known by their words)
local DOOR_WORDS = nil
local function doorWords(text)
    if not DOOR_WORDS then
        DOOR_WORDS = {}
        for _, k in ipairs({ "ContextMenu_Open_door", "ContextMenu_Close_door", "ContextMenu_Open_window", "ContextMenu_Close_window" }) do
            DOOR_WORDS[getText(k)] = true
        end
    end
    return text ~= nil and DOOR_WORDS[tostring(text)] == true
end
-- what the game's Interact key does on a keyboard (the controller's A does more: lights, stoves, devices; those are
-- in the right-click menu on a keyboard)
local function keyDoes(fn, text)
    local P = ISButtonPrompt
    if fn == nil then return doorWords(text) end
    return fn and P and (fn == P.openDoor or fn == P.closeDoor or fn == P.openWindow or fn == P.closeWindow
        or fn == P.climbInWindow or fn == P.climbFence or fn == P.climbOverWall or fn == P.cmdEnterVehicle
        or fn == P.cmdExitVehicle or fn == P.cmdOpenVehicleDoor or fn == P.cmdCloseVehicleDoor) or false
end

local function keyName(binding)
    local ok, code = pcall(function() return getCore():getKey(binding) end)
    if not ok or not code or code == 0 then return nil end
    local ok2, n = pcall(function() return getKeyName(code) end)
    return (ok2 and n and n ~= "") and tostring(n) or nil
end

-- the controller's prompts, as the game set them this tick
local PAD = { { "aPrompt", "aFunc", "A" }, { "xPrompt", "xFunc", "X" }, { "yPrompt", "yFunc", "Y" }, { "bPrompt", "bFunc", "B" },
              { "lbPrompt", "lbFunc", "LB" }, { "rbPrompt", "rbFunc", "RB" } }
local function padPrompts(pn, out)
    local bp = getButtonPrompts and getButtonPrompts(pn)
    if not bp then return end
    for _, p in ipairs(PAD) do
        local text, fn = bp[p[1]], bp[p[2]]
        if text and text ~= "" and not spent(fn, text) then out[#out + 1] = { glyph = p[3], label = tostring(text) } end
    end
end

-- the keyboard's: ZeD's own ISButtonPrompt, the same rules
H._eval = H._eval or {}
local function keyPrompts(pn, out)
    local st = H._eval[pn]
    if not st then
        if not ISButtonPrompt then return end
        st = { bp = ISButtonPrompt:new(pn), at = 0 }
        H._eval[pn] = st
    end
    local t = now()
    if t - st.at >= EVAL_MS then
        st.at = t
        local bp = st.bp
        local p = getSpecificPlayer(pn)
        pcall(function()
            bp:clearButtonBindings()
            local dir = p:getDir()
            bp:getBestInteractButtonAction(dir)
        end)
        st.a, st.aFn = bp.aPrompt, bp.aFunc
    end
    if st.a and st.a ~= "" then
        local key = keyDoes(st.aFn, st.a) and keyName("Interact")
        if key and not spent(st.aFn, st.a) then out[#out + 1] = { glyph = key, key = true, label = tostring(st.a) } end
        if not spent("rightclick", "rightclick") then out[#out + 1] = { glyph = getText("IGUI_mouse_btn_1"), key = true, label = ZeD.tr("UI_ZeD_Hint_More") } end
    end
end

-- what to show for a player now (nil: nothing)
function H.prompts(pn)
    if mode() == "off" then return nil end
    if ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on() then return nil end
    local p = getSpecificPlayer(pn)
    if not p or p:isDead() or p:isAsleep() then return nil end
    local sc = UIManager.getSpeedControls and UIManager.getSpeedControls()
    if sc and sc:getCurrentGameSpeed() == 0 then return nil end
    if getFocusForPlayer(pn) ~= nil then return nil end
    local out = {}
    if onPad(pn) then padPrompts(pn, out) else keyPrompts(pn, out) end
    return (#out > 0) and out or nil
end

-- ---------------------------------------------------------------------------
-- the strip: a HUD panel above the belt, no clicks
-- ---------------------------------------------------------------------------
ZeD_HintStripHUD = ZeD_HintStripHUD or ZeD_Panel:derive("ZeD_HintStripHUD")

function ZeD_HintStripHUD:new(pn)
    local o = ZeD_Panel:new(0, 0, 10, 10)
    setmetatable(o, self)
    self.__index = self
    o.playerNum = pn or 0
    o._zedLabel = "Hint strip"
    o.anchorBottom, o.anchorRight = false, false
    o.keepOnScreen = false
    o.wantMouseEvents = false
    return o
end
function ZeD_HintStripHUD:instantiate()
    ZeD_Panel.instantiate(self)
    pcall(function() self.javaObject:setConsumeMouseEvents(false) end)
end
function ZeD_HintStripHUD:onMouseDown() return false end
function ZeD_HintStripHUD:onMouseUp() return false end
function ZeD_HintStripHUD:onRightMouseDown() return false end
function ZeD_HintStripHUD:onRightMouseUp() return false end
function ZeD_HintStripHUD:onMouseMove() return false end
function ZeD_HintStripHUD:onMouseWheel() return false end

function ZeD_HintStripHUD:prerender()
    local T = ZeD.T
    self._p = nil
    if not T then return end
    local ok, p = pcall(H.prompts, self.playerNum)
    if not ok or not p then return end
    local G = ZeD.PadGlyphs
    local pn = self.playerNum
    local w = math.min(math.ceil(G.stripW(p, pn)) + 4, getPlayerScreenWidth(pn) - T.px(40))
    local h = G.stripH()
    local x = getPlayerScreenLeft(pn) + math.floor((getPlayerScreenWidth(pn) - w) / 2)
    local y = getPlayerScreenTop(pn) + getPlayerScreenHeight(pn) - h - T.px(16)
    local belt = ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD(pn)
    if belt and belt._drawn and belt:getIsVisible() then y = belt:getY() - h - T.px(6) end
    if self:getX() ~= x then self:setX(x) end
    if self:getY() ~= y then self:setY(y) end
    if self:getWidth() ~= w then self:setWidth(w) end
    if self:getHeight() ~= h then self:setHeight(h) end
    self._p = p
end

-- True while the strip should step aside (punch list 131): a balloon of the belt's is up (its balloons stand right above
-- the belt, where the strip sits, and the two read as one line, "Back | key 1 More"; the hands' too, beside it: QA's Mac
-- run, Nov 10), or any balloon that is up overlaps the strip (screen px). Until the balloon is down.
function H.covered(ax, ay, w, h, pn)
    local B = ZeD.Balloon
    local S = B and B._slot
    if not (S and B.up and B.up()) then return false end
    local belt = ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD(pn or 0)
    if belt and S.owner == belt then return true end
    -- (the belt's held-item card, 135: drawn last, on ZeD_InvTip's layer, so the balloon that is up is the layer's
    -- while the belt's own hint stands under it; the strip steps aside for it as for the hint. QA's Mac run on test 6,
    -- Nov 11 2026: the strip stayed up beside the card)
    local IT = ZeD.InvTip
    local want = IT and IT._want
    if belt and want and want.owner == belt and want.content and (want.frame or -9) >= (IT._frame or 0) - 1 then return true end
    if not S.box then return false end
    local b = S.box
    -- (a few units of room: a balloon that only touches the strip still reads as part of its line)
    local g = (ZeD.T and ZeD.T.px) and ZeD.T.px(4) or 4
    return b.x < ax + w + g and b.x + b.w > ax - g and b.y < ay + h + g and b.y + b.h > ay - g
end

function ZeD_HintStripHUD:render()
    if not self._p then return end
    if H.covered(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, self.playerNum) then return end
    local T = ZeD.T
    ZeD.PadGlyphs.drawStrip(self, 0, 0, self.width, self._p)
    ZeD.Atoms.frame(self, 0, 0, self.width, self.height, T.borderS)
end

-- ---------------------------------------------------------------------------
-- the game's corner prompt is not drawn while the strip is on for a player on a controller; uses are counted
-- ---------------------------------------------------------------------------
function H.replacing(pn) return mode() ~= "off" and not (ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on()) and onPad(pn) end

local function hookPrompt()
    local P = ISButtonPrompt
    if not P or H._hookedPrompt then return end
    H._hookedPrompt = true
    local _pre = P.prerender
    P.prerender = function(self, ...)
        if self.player ~= nil and H.replacing(self.player) then return end
        return _pre(self, ...)
    end
    -- (a press of A, X, Y or B in the world: that hint's use; the game's own handler runs as before)
    for _, pair in ipairs({ { "onAPress", "aFunc", "aPrompt" }, { "onXPress", "xFunc", "xPrompt" }, { "onYPress", "yFunc", "yPrompt" },
                            { "onBPress", "bFunc", "bPrompt" } }) do
        local orig = P[pair[1]]
        if orig then
            P[pair[1]] = function(self, ...)
                if mode() == "first" then pcall(H.used, self[pair[2]], self[pair[3]]) end
                return orig(self, ...)
            end
        end
    end
end

-- the keyboard's uses: the Interact key on a hint it does; a right-click in the world
local function onKey(key)
    if mode() ~= "first" then return end
    local st = H._eval[0]
    if st and st.a and keyDoes(st.aFn, st.a) then
        local ok, code = pcall(function() return getCore():getKey("Interact") end)
        if ok and code == key then H.used(st.aFn, st.a) end
    end
end
local function onRightClick()
    if mode() ~= "first" then return end
    local st = H._eval[0]
    if st and st.a then H.used("rightclick", "rightclick") end
end

H._huds = H._huds or {}
function H.install(pn)
    pn = pn or 0
    hookPrompt()
    if H._huds[pn] then return end
    local hud = ZeD_HintStripHUD:new(pn)
    hud:initialise()
    -- (split view: players 2 to 4 draw it in their own theme, PlayerTheme.lua; the first player's is left as it is)
    if ZeD.Theme and ZeD.Theme.adopt then ZeD.Theme.adopt(hud) end
    hud:addToUIManager()
    pcall(function() hud:backMost() end)
    H._huds[pn] = hud
end

if Events and not H._hooked then
    H._hooked = true
    if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(function(pn) pcall(H.install, pn) end) end
    if Events.OnGameStart then Events.OnGameStart.Add(function() pcall(H.install, 0) end) end
    if Events.OnKeyPressed then Events.OnKeyPressed.Add(onKey) end
    if Events.OnRightMouseDown then Events.OnRightMouseDown.Add(onRightClick) end
end

return H
