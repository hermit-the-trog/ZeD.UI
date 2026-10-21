-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardLock.lua
-- ============================================================================
-- OBJECT CARD: PADLOCKS (HOOK_MAP row 25; mockup zed_padlock_codes_v1.html)
-- Vanilla sets and opens a combination padlock in ISDigitalCode, a small
-- pop-up mid-screen (three text boxes with ^ and v). This card replaces it in
-- the World window's card drawer for any object that takes a padlock (the
-- crates, lockers, counters and bars you build):
--   * the padlock drawn as the dial: three number wheels with ▲ / ▼, the mouse
--     wheel over a wheel, the number keys while the pointer is on the card,
--     the D-pad (up / down turn the focused wheel);
--   * LOCK (vanilla's rules: a Combination Padlock in your inventory, a code
--     other than 000) and REMOVE PADLOCK, both vanilla's ISPadlockByCodeAction;
--   * a wrong code says so in the footer (vanilla's pop-up just closes); every
--     try is vanilla's own 20-tick action, right or wrong;
--   * key padlocks on the same card (vanilla's Use / Remove Padlock).
-- The code is never stored for the player (director, Oct 14 2026: vanilla
-- keeps no record, and neither do we).
-- ============================================================================

require "ZeD/ObjectCards"

local OC = ZeD.ObjectCards
local UI = OC.ui
local call = OC.call
local DOT = OC.DOT

ZeD.ObjectCardLock = ZeD.ObjectCardLock or {}
local LK = ZeD.ObjectCardLock

local function txt(k, fb) local s = getTextOrNull and getTextOrNull(k) return s or fb or k end
local function col(c) return c.r, c.g, c.b end
local function now() return getTimestampMs and getTimestampMs() or 0 end
local function isGamepad()
    local D = ZeD.Input and ZeD.Input.Detector
    return (D and D.getMode and D.getMode() == "gamepad") or false
end
-- 319 -> "3 1 9"
local function spaced(code)
    code = math.floor(code or 0)
    return tostring(math.floor(code / 100) % 10) .. " " .. tostring(math.floor(code / 10) % 10) .. " " .. tostring(code % 10)
end

local WHEEL_W, WHEEL_H = 34, 60      -- design units
local WHEEL_GAP = 7
local CHEV_H = 15
local LOCK_W, LOCK_H = 236, 214
local FLASH_MS = 6000

local def = { id = "lock", leash = 4 }

-- ----------------------------------------------------------------------------
-- The object and its locks
-- ----------------------------------------------------------------------------
-- a built crate's own name ("Small Metal Locker (Shoddy)"); getName holds the
-- entity id ("Metal_LockerSmall_Lvl1"), so it only serves as a last resort
local function objName(o)
    local raw = call(o, "getName")
    local n = call(o, "getEntityDisplayName")
    if n and n ~= "" and n ~= raw and n ~= "Entity" then return n end
    local c = call(o, "getContainer")
    local ty = c and call(c, "getType")
    local title = ty and getTextOrNull and getTextOrNull("IGUI_ContainerTitle_" .. tostring(ty))
    if title then return title end
    if raw and raw ~= "" then return raw end
    return txt("ContextMenu_Padlock", "Padlock")
end

-- vanilla looks in the main inventory (ItemContainer.FindAndReturn), and the
-- action removes the padlock from there
local function comboPadlock(player) return call(player:getInventory(), "FindAndReturn", "CombinationPadlock") end
local function keyPadlock(player)
    local p = call(player:getInventory(), "FindAndReturn", "Padlock")
    if p and (call(p, "getNumberOfKey") or 0) > 0 then return p end
    return nil
end

local function codeOf(t) return t.digits[1] * 100 + t.digits[2] * 10 + t.digits[3] end
local function codeText(t) return tostring(t.digits[1]) .. " " .. tostring(t.digits[2]) .. " " .. tostring(t.digits[3]) end

-- arg = the object, or { obj = object, set = true } from Use Combination Padlock
function def.resolve(player, arg)
    local o, set = arg, false
    if type(arg) == "table" and arg.obj then o, set = arg.obj, arg.set end
    if not (o and instanceof(o, "IsoThumpable")) then return nil end
    local sq = o:getSquare()
    if not sq then return nil end
    return { obj = o, sq = sq, key = OC.keyOf(sq, "lock:" .. tostring(call(o, "getObjectIndex"))),
             setting = set and true or false, digits = { 0, 0, 0 }, cursor = 1 }
end

function def.valid(t)
    local o = t.obj
    return o ~= nil and o:getSquare() ~= nil and (call(o, "getObjectIndex") or -1) >= 0
end

-- What the band says of a running padlock action: its label token (see lockAction)
-- through the translations.
function LK.busyText(label, act)
    if label == "locking" then return ZeD.tr("UI_ZeD_Lock_BusyLocking") end
    if label == "trying" then return ZeD.tr("UI_ZeD_Lock_BusyTrying", spaced(act and act.code)) end
    if label == "putting" then return ZeD.tr("UI_ZeD_Lock_BusyPutting") end
    if label == "removing" then return ZeD.tr("UI_ZeD_Lock_BusyRemoving") end
    if label == "walking" then return ZeD.tr("UI_ZeD_Lock_BusyWalking") end
    return ""
end

-- The padlock action running (or queued) on this object, and its label token
-- (locking, trying, putting, removing, walking: the player reads LK.busyText of it).
local function lockAction(player, t)
    local q = ISTimedActionQueue.getTimedActionQueue(player)
    local list = q and q.queue
    if not list then return nil end
    for i, a in ipairs(list) do
        if (a.Type == "ISPadlockByCodeAction" or a.Type == "ISPadlockAction") and a.thump == t.obj then
            local label
            if a.Type == "ISPadlockByCodeAction" then
                label = a.lock and "locking" or "trying"
            else
                label = a.lock and "putting" or "removing"
            end
            if i > 1 then label = "walking" end
            return list[1], label, a
        end
    end
    return nil
end

function def.refresh(t, player)
    local o = t.obj
    local d = {}
    d.code = call(o, "getLockedByCode") or 0
    d.codeLocked = d.code > 0
    d.keyLocked = call(o, "isLockedByPadlock") == true
    d.canPad = call(o, "canBeLockByPadlock") == true
    d.lockedToMe = call(o, "isLockedToCharacter", player) == true
    d.combo = comboPadlock(player)
    d.keyPad = keyPadlock(player)
    d.haveKey = d.keyLocked and call(player:getInventory(), "haveThisKeyId", call(o, "getKeyId")) ~= nil
    d.name = objName(o)
    local c = call(o, "getContainer")
    d.items = c and call(c, "getItems") and c:getItems():size() or nil
    d.weight = c and call(c, "getCapacityWeight") or 0
    d.cap = c and (call(c, "getEffectiveCapacity", player) or call(c, "getCapacity")) or 0
    d.inv = c

    -- a try finished: still locked means the code was wrong (vanilla's action
    -- does nothing then); a cancelled try says nothing
    local tr = t.try
    if tr then
        if tr.action._zedDone then
            if now() - tr.action._zedDone > 150 then
                if d.codeLocked then t.wrong = tr.code end
                t.try = nil
            end
        else
            local _, _, a = lockAction(player, t)
            if a ~= tr.action then t.try = nil end
        end
    end
    -- the padlock just came off with our try: show the container in the Loot pane
    if t.d and t.d.codeLocked and not d.codeLocked then
        t.flash = { text = ZeD.tr("UI_ZeD_Lock_FlashOff"), untilMs = now() + FLASH_MS }
        t.wrong, t.setting = nil, false
        if c and ZeD_WorldWindow and ZeD_WorldWindow.selectContainer then ZeD_WorldWindow.selectContainer(c, 120) end
    end
    -- just locked: the wheels start again from 0 0 0 for the next opening (vanilla's do)
    if d.codeLocked and t.d and not t.d.codeLocked then t.digits, t.cursor = { 0, 0, 0 }, 1 end
    if d.codeLocked then t.setting = false end
    -- vanilla's rule for putting a padlock on: takes one, has none
    d.free = d.canPad and not d.codeLocked and not d.keyLocked
    if d.codeLocked then d.mode = "enter"
    elseif d.keyLocked then d.mode = "key"
    elseif t.setting and d.free then d.mode = "set"
    else d.mode = "open" end
    local head, label, lact = lockAction(player, t)
    d.busy, d.busyLabel = head, label
    d.busyText = label and LK.busyText(label, lact) or nil
    t.d = d

    -- verbs
    local verbs = {}
    local busy = head ~= nil
    if d.mode == "set" then
        verbs[1] = { id = "lock", label = ZeD.tr("UI_ZeD_Lock_Lock"), primary = true, enabled = (not busy) and d.combo ~= nil and codeOf(t) ~= 0,
            run = function(p, tt) LK.lock(p, tt) end }
    elseif d.mode == "enter" then
        verbs[1] = { id = "remove", label = getText("ContextMenu_RemovePadlock"), primary = true, enabled = not busy,
            run = function(p, tt) LK.try(p, tt) end }
    elseif d.mode == "key" then
        verbs[1] = { id = "remove", label = getText("ContextMenu_RemovePadlock"), primary = true, enabled = (not busy) and d.haveKey,
            run = function(p, tt) ISWorldObjectContextMenu.onRemovePadlock(nil, p:getPlayerNum(), tt.obj) end }
    else
        verbs[1] = { id = "usecombo", label = getText("ContextMenu_PutCombinationPadlock"), enabled = (not busy) and d.free and d.combo ~= nil,
            run = function(p, tt) tt.setting = true; tt.digits = { 0, 0, 0 }; tt.cursor = 1; tt.wrong = nil; tt._refreshT = OC.REFRESH end }
        verbs[2] = { id = "usepad", label = getText("ContextMenu_PutPadlock"), enabled = (not busy) and d.free and d.keyPad ~= nil,
            run = function(p, tt)
                local pad = keyPadlock(p)
                if pad then ISWorldObjectContextMenu.onPutPadlock(nil, p:getPlayerNum(), tt.obj, pad) end
            end }
    end
    t.verbs = verbs
end

-- LOCK: vanilla's onSetDigitalCode (walk next to it, then the action)
function LK.lock(player, t)
    local code = codeOf(t)
    local pad = comboPadlock(player)
    if code == 0 or not pad then return end
    if luautils.walkAdj(player, t.obj:getSquare()) then
        ISTimedActionQueue.add(ISPadlockByCodeAction:new(player, t.obj, pad, true, code))
    end
end

-- REMOVE PADLOCK on a code lock: every try runs vanilla's action, which takes
-- the padlock off only when the code is right; the card reads the outcome
function LK.try(player, t)
    local code = codeOf(t)
    if not luautils.walkAdj(player, t.obj:getSquare()) then return end
    local a = ISPadlockByCodeAction:new(player, t.obj, nil, false, code)
    local basePerform = a.perform
    a.perform = function(self)
        self._zedDone = now()
        return basePerform(self)
    end
    ISTimedActionQueue.add(a)
    t.try = { action = a, code = code }
    t.wrong = nil
end

local function turn(t, i, step)
    if t.d and t.d.busy then return end
    -- (Kahlua's % keeps the sign: -1 % 10 is -1, so wrap by hand)
    t.digits[i] = ((t.digits[i] + step) % 10 + 10) % 10
    t.cursor = i
    t.wrong = nil
end

-- number keys type left to right (Backspace steps back); only while the
-- pointer is over the card (the hotbar keeps the number keys otherwise)
local DIGIT = {}
local function mapKeys()
    local K = Keyboard
    for n = 0, 9 do
        local k1 = K["KEY_" .. tostring(n)]
        local k2 = K["KEY_NUMPAD" .. tostring(n)]
        if k1 then DIGIT[k1] = n end
        if k2 then DIGIT[k2] = n end
    end
    DIGIT._mapped = true
end
function def.onKey(t, key, card, act)
    if not DIGIT._mapped then mapKeys() end
    local mode = t.d and t.d.mode
    if mode ~= "set" and mode ~= "enter" then return false end
    local n = DIGIT[key]
    if n == nil and key ~= Keyboard.KEY_BACK then return false end
    if not act then return true end
    if t.d.busy then return true end
    if n ~= nil then
        t.digits[t.cursor] = n
        t.cursor = (t.cursor % 3) + 1
    else
        t.cursor = (t.cursor + 1) % 3 + 1   -- one step left, wrapping
        t.digits[t.cursor] = 0
    end
    t.wrong = nil
    t._refreshT = OC.REFRESH
    return true
end

-- ----------------------------------------------------------------------------
-- Header, footer
-- ----------------------------------------------------------------------------
function def.title(t) return t.d and t.d.name or objName(t.obj) end
function def.icon(t) return OC.spriteIcon(t.obj) end
function def.pill(t)
    local T = ZeD.T
    local d = t.d
    if not d then return nil end
    if d.mode == "set" then return ZeD.tr("UI_ZeD_Lock_PillSetting"), T.textDim end
    if d.mode == "enter" then return ZeD.tr("UI_ZeD_Lock_PillCode"), T.danger end
    if d.mode == "key" then return ZeD.tr("UI_ZeD_Lock_PillKey"), d.haveKey and T.warning or T.danger end
    return ZeD.tr("UI_ZeD_Lock_PillUnlocked"), T.positive
end
function def.openFocus(t)
    local d = t.d
    if d and (d.mode == "set" or d.mode == "enter") then return "lk:wheel:1" end
    return nil
end

function def.status(t)
    local T = ZeD.T
    local d = t.d
    if not d then return nil end
    if d.busy then return { text = d.busyLabel == "walking" and ZeD.tr("UI_ZeD_Lock_StatusWalking") or ZeD.tr("UI_ZeD_Lock_StatusWorking"), c = T.accent } end
    if d.mode == "set" then
        if not d.combo then return { text = ZeD.tr("UI_ZeD_Lock_StatusNoCombo"), c = T.danger } end
        if codeOf(t) == 0 then return { text = ZeD.tr("UI_ZeD_Lock_StatusZeroCode"), c = T.danger } end
        return { text = ZeD.tr("UI_ZeD_Lock_StatusReadyLock", codeText(t)), c = T.positive }
    end
    if d.mode == "enter" then
        if t.wrong then
            return { text = ZeD.tr("UI_ZeD_Lock_StatusWrong", spaced(t.wrong)), c = T.danger, alarm = true }
        end
        return { text = ZeD.tr("UI_ZeD_Lock_StatusReadyTry", codeText(t)), c = T.positive }
    end
    if d.mode == "key" then
        if d.haveKey then return { text = ZeD.tr("UI_ZeD_Lock_StatusReadyKey"), c = T.positive } end
        return { text = ZeD.tr("UI_ZeD_Lock_StatusNoKey"), c = T.danger }
    end
    if t.flash and now() < t.flash.untilMs then return { text = t.flash.text, c = T.positive } end
    return nil
end

-- ----------------------------------------------------------------------------
-- The padlock (hardware, not chrome)
-- ----------------------------------------------------------------------------
local STEEL = { UI.hex("#5a6168"), UI.hex("#8d949b"), UI.hex("#c3c9cf"), UI.hex("#8d949b"), UI.hex("#5a6168") }
local BODY_COMBO = { top = UI.hex("#3d434a"), bot = UI.hex("#22262b"), rim = UI.hex("#5a6068") }
local BODY_KEY = { top = UI.hex("#c9a24c"), bot = UI.hex("#8a6a24"), rim = UI.hex("#e2c070") }
local WHEEL = { UI.hex("#6e685a"), UI.hex("#b9b29f"), UI.hex("#e2dccb"), UI.hex("#f2ecda"), UI.hex("#e2dccb"), UI.hex("#b9b29f"), UI.hex("#6e685a") }
local INK = UI.hex("#151515")
local INK_DIM = UI.hex("#5a5444")
local CHEV_TOP, CHEV_BOT = UI.hex("#4a5058"), UI.hex("#33383e")

-- vertical bands (a cylinder's shading)
local function bands(card, x, y, w, h, list)
    local n = #list
    for i = 1, n do
        local x0 = x + math.floor(w * (i - 1) / n)
        local x1 = x + math.floor(w * i / n)
        local c = list[i]
        card:drawRect(x0, y, x1 - x0, h, 1, col(c))
    end
end
local function vgrad(card, x, y, w, h, top, bot, steps)
    steps = steps or 8
    for i = 0, steps - 1 do
        local f = i / math.max(1, steps - 1)
        local y0 = y + math.floor(h * i / steps)
        local y1 = y + math.floor(h * (i + 1) / steps)
        card:drawRect(x, y0, w, y1 - y0, 1, top.r + (bot.r - top.r) * f, top.g + (bot.g - top.g) * f, top.b + (bot.b - top.b) * f)
    end
end
-- rounded body: the rect without its corners, then a disc in each
local function mix(a, b, f) return { r = a.r + (b.r - a.r) * f, g = a.g + (b.g - a.g) * f, b = a.b + (b.b - a.b) * f } end
local function roundBody(card, x, y, w, h, r, pal)
    -- the corner discs first, in the gradient's colour at their height, so
    -- the bands drawn over them leave only the rounded edge showing
    local fTop, fBot = r / math.max(1, h), (h - r) / math.max(1, h)
    UI.disc(card, x + r, y + r, r, mix(pal.top, pal.bot, fTop))
    UI.disc(card, x + w - r, y + r, r, mix(pal.top, pal.bot, fTop))
    UI.disc(card, x + r, y + h - r, r, mix(pal.top, pal.bot, fBot))
    UI.disc(card, x + w - r, y + h - r, r, mix(pal.top, pal.bot, fBot))
    vgrad(card, x + r, y, w - r * 2, h, pal.top, pal.bot, 10)
    local f0, f1 = r / math.max(1, h), (h - r) / math.max(1, h)
    vgrad(card, x, y + r, r, h - r * 2, mix(pal.top, pal.bot, f0), mix(pal.top, pal.bot, f1), 8)
    vgrad(card, x + w - r, y + r, r, h - r * 2, mix(pal.top, pal.bot, f0), mix(pal.top, pal.bot, f1), 8)
end

local function chevron(card, x, y, w, h, up, focused, dim)
    local T = ZeD.T
    card:drawRect(x, y, w, math.floor(h / 2), 1, col(CHEV_TOP))
    card:drawRect(x, y + math.floor(h / 2), w, h - math.floor(h / 2), 1, col(CHEV_BOT))
    card:drawRect(x, y, w, T.px(1), 1, 0.42, 0.45, 0.48)
    card:drawRect(x, y, T.px(1), h, 1, 0.42, 0.45, 0.48)
    card:drawRect(x, y + h - T.px(1), w, T.px(1), 1, 0.07, 0.07, 0.07)
    card:drawRect(x + w - T.px(1), y, T.px(1), h, 1, 0.07, 0.07, 0.07)
    -- the arrow: a small stack of rects
    local cx = x + math.floor(w / 2)
    local ah = T.px(4)
    local a = dim and 0.45 or 1
    for i = 0, ah - 1 do
        local hw = up and (i + 1) or (ah - i)
        card:drawRect(cx - hw, y + math.floor((h - ah) / 2) + i, hw * 2, 1 * math.max(1, T.px(1)), a, 0.9, 0.89, 0.84)
    end
    if focused then
        local ac = T.accent
        card:drawRect(x, y, w, h, 0.55, col(ac))
    end
end

-- digit drawn centred at (cx, cy) on the distance-field mono face
local function digit(card, s, cx, cy, px, c, a)
    local T = ZeD.T
    local X, F = ZeD.Text, ZeD.Font
    if X and X.draw and F and F.sdf then
        local z = X.zoomPx(px)
        local h = X.height(F.sdf.sec, z)
        X.draw(card, F.sdf.sec, s, cx, cy - h / 2, z, c.r, c.g, c.b, a or 1, "c")
    else
        local f = T.fontF4
        local w = ZeD.TM:MeasureStringX(f, s)
        card:drawText(s, cx - math.floor(w / 2), cy - math.floor(ZeD.TM:getFontHeight(f) / 2), c.r, c.g, c.b, a or 1, f)
    end
end

local function drawPadlock(card, x, y, t, key)
    local T = ZeD.T
    local d = t.d
    local p = T.px
    local open = d.mode == "set"
    local lw = p(LOCK_W)
    local ox = x + math.floor((card._lkW - lw) / 2)
    local bodyX, bodyY, bodyW, bodyH = ox + p(26), y + p(80), p(184), p(126)
    -- shackle: legs at bodyX+48 and bodyX+136 (design), arc above; up 16 when open
    local sy = open and p(16) or 0
    local thick = p(14)
    local legL = ox + p(74) - math.floor(thick / 2)
    local legR = ox + p(162) - math.floor(thick / 2)
    local arcCX = ox + p(118)
    local arcCY = y + p(58) - sy
    local rOut = p(44) + math.floor(thick / 2)
    local rIn = p(44) - math.floor(thick / 2)
    local bg = T.surf1
    UI.disc(card, arcCX, arcCY, rOut + p(2), UI.hex("#1a1a1a"))
    UI.disc(card, arcCX, arcCY, rOut, STEEL[3])
    UI.disc(card, arcCX, arcCY, rIn, bg)
    card:drawRect(arcCX - rOut - p(3), arcCY, (rOut + p(3)) * 2, rOut + p(3), 1, col(bg))
    bands(card, legL, arcCY, thick, bodyY - arcCY + p(6), STEEL)
    bands(card, legR, arcCY, thick, bodyY - arcCY + p(6), STEEL)
    if open then card:drawRect(legR - p(2), bodyY - p(2), thick + p(4), p(5), 1, 0.05, 0.05, 0.05) end
    -- body
    local pal = key and BODY_KEY or BODY_COMBO
    roundBody(card, bodyX - p(1), bodyY - p(1), bodyW + p(2), bodyH + p(2), p(13), { top = UI.hex("#0c0c0c"), bot = UI.hex("#0c0c0c") })
    roundBody(card, bodyX, bodyY, bodyW, bodyH, p(12), pal)
    card:drawRectBorder(bodyX + p(8), bodyY + p(8), bodyW - p(16), bodyH - p(16), 0.7, col(pal.rim))
    if key then
        -- a keyway
        local kx, ky = ox + p(118), bodyY + p(58)
        UI.disc(card, kx, ky, p(13), UI.hex("#3a2a10"))
        card:drawRect(kx - p(4), ky, p(8), p(22), 1, col(UI.hex("#3a2a10")))
        UI.disc(card, kx, ky, p(5), UI.hex("#120c04"))
        card:drawRect(kx - p(2), ky, p(4), p(20), 1, col(UI.hex("#120c04")))
        return p(LOCK_H)
    end
    -- the wheel window and its three wheels
    local winX, winY, winW, winH = ox + p(50), y + p(108), p(136), p(68)
    card:drawRect(winX, winY, winW, winH, 1, 0.05, 0.05, 0.05)
    local busy = d.busy ~= nil
    local wheelW, wheelH, gap = p(WHEEL_W), p(WHEEL_H), p(WHEEL_GAP)
    local total = wheelW * 3 + gap * 2
    local wx0 = winX + math.floor((winW - total) / 2)
    local wy = winY + math.floor((winH - wheelH) / 2)
    local cursorOn = card:pointerOver() and not isGamepad()
    for i = 1, 3 do
        local wx = wx0 + (i - 1) * (wheelW + gap)
        local fid = "lk:wheel:" .. tostring(i)
        local focused = card._fid == fid
        bands(card, wx, wy, wheelW, wheelH, { WHEEL[4], WHEEL[4], WHEEL[4] })
        -- cylinder shading top and bottom
        for k = 1, 3 do
            local c = WHEEL[k]
            local hh = math.floor(wheelH * 0.1)
            card:drawRect(wx, wy + (k - 1) * hh, wheelW, hh, 1, col(c))
            card:drawRect(wx, wy + wheelH - k * hh, wheelW, hh, 1, col(c))
        end
        card:drawRect(wx, wy, p(1), wheelH, 1, 0.1, 0.1, 0.1)
        card:drawRect(wx + wheelW - p(1), wy, p(1), wheelH, 1, 0.1, 0.1, 0.1)
        local v = t.digits[i]
        local cx = wx + math.floor(wheelW / 2)
        digit(card, tostring((v + 9) % 10), cx, wy + p(10), 11, INK_DIM, 0.6)
        digit(card, tostring(v), cx, wy + math.floor(wheelH / 2), 26, INK, 1)
        digit(card, tostring((v + 1) % 10), cx, wy + wheelH - p(10), 11, INK_DIM, 0.6)
        if focused then card:drawRect(wx, wy, wheelW, wheelH, 0.55, col(T.accent)) end
        -- the typing cursor (keyboard): a bar under the wheel the next digit lands on
        if cursorOn and t.cursor == i and not busy then
            card:drawRect(wx, winY + winH - p(3), wheelW, p(2), 1, col(T.accent))
        end
        local ii = i
        card:zone({ fid = fid, x = wx, y = wy, w = wheelW, h = wheelH, body = true,
            run = function(c)
                -- A on a wheel presses the card's verb (LOCK / REMOVE PADLOCK)
                local v1 = t.verbs and t.verbs[1]
                if isGamepad() then
                    if v1 then c:press(v1) end
                else
                    t.cursor = ii
                end
            end,
            dpad = function(dir)
                -- while an action runs the D-pad moves on (to STOP)
                if t.d and t.d.busy then return false end
                if dir == "up" then turn(t, ii, 1); return true end
                if dir == "down" then turn(t, ii, -1); return true end
                return false
            end,
            wheel = function(del) turn(t, ii, del < 0 and 1 or -1) end })
        local ch = p(CHEV_H)
        chevron(card, wx, bodyY + p(12), wheelW, ch, true, focused, busy)
        chevron(card, wx, winY + winH + p(1), wheelW, ch, false, focused, busy)
        card:zone({ fid = "lk:up:" .. tostring(i), x = wx, y = bodyY + p(12), w = wheelW, h = ch, body = true, nofocus = true,
            run = function() turn(t, ii, 1) end })
        card:zone({ fid = "lk:dn:" .. tostring(i), x = wx, y = winY + winH + p(1), w = wheelW, h = ch, body = true, nofocus = true,
            run = function() turn(t, ii, -1) end })
    end
    return p(LOCK_H)
end

-- ----------------------------------------------------------------------------
-- Body
-- ----------------------------------------------------------------------------
local function band(card, x, y, w, t, player)
    local T, tm = ZeD.T, ZeD.TM
    local d = t.d
    local ac = T.accent
    local h = T.px(32)
    card:drawRect(x, y, w, h, 0.10, col(ac))
    card:drawRectBorder(x, y, w, h, 1, col(ac))
    local f1 = T.fontF1
    card:drawText(d.busyText or "", x + T.px(8), y + math.floor((h - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
    local bw = UI.buttonW(getText("IGUI_media_stop"))
    local bx = x + w - T.px(6) - bw
    local by = y + math.floor((h - T.px(22)) / 2)
    UI.button(card, bx, by, getText("IGUI_media_stop"), { focused = card._fid == "lk:stop" })
    card:zone({ fid = "lk:stop", x = bx, y = by, w = bw, h = T.px(22), body = true,
        run = function() pcall(function() ISTimedActionQueue.clear(player) end) end })
    local pct = 0
    if d.busyLabel ~= "walking" then pcall(function() pct = d.busy:getJobDelta() end) end
    local s = tostring(math.floor(pct * 100 + 0.5)) .. "%"
    local f3 = T.fontF3
    local sw = tm:MeasureStringX(f3, s)
    card:drawText(s, bx - T.px(10) - sw, y + math.floor((h - tm:getFontHeight(f3)) / 2), T.text.r, T.text.g, T.text.b, 1, f3)
    local barX = x + T.px(8) + tm:MeasureStringX(f1, d.busyText or "") + T.px(12)
    local barW = bx - T.px(10) - sw - T.px(10) - barX
    if barW > T.px(20) then
        local bh = T.px(8)
        local yy = y + math.floor((h - bh) / 2)
        card:drawRect(barX, yy, barW, bh, 1, col(T.surf2))
        card:drawRect(barX, yy, math.floor(barW * math.max(0, math.min(1, pct))), bh, 1, col(ac))
        card:drawRectBorder(barX, yy, barW, bh, T.borderS.a or 1, col(T.borderS))
    end
    return h
end

local function fact(card, x, y, w, label, value, dotC)
    local T, tm = ZeD.T, ZeD.TM
    local h = T.px(20)
    local ac = T.accent
    local f1, f3 = T.fontF1, T.fontF3
    card:drawText(label, x, y + math.floor((h - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
    local vx = x + T.px(96)
    if dotC then
        ZeD.Atoms.drawStatusDot(card, vx, y + math.floor((h - T.px(7)) / 2), dotC, T.px(7))
        vx = vx + T.px(13)
    end
    local s = ZeD.CraftingCore.truncText(value, f3, x + w - vx)
    card:drawText(s, vx, y + math.floor((h - tm:getFontHeight(f3)) / 2), T.text.r, T.text.g, T.text.b, T.text.a or 1, f3)
    return h
end

local function needRow(card, x, y, w, ok, text)
    local T, tm = ZeD.T, ZeD.TM
    local h = T.px(20)
    ZeD.Atoms.drawStatusDot(card, x + T.px(2), y + math.floor((h - T.px(7)) / 2), ok and T.positive or T.danger, T.px(7))
    local f = T.fontF3
    card:drawText(ZeD.CraftingCore.truncText(text, f, w - T.px(16)), x + T.px(15), y + math.floor((h - tm:getFontHeight(f)) / 2), T.text.r, T.text.g, T.text.b, T.text.a or 1, f)
    return h
end

function def.body(card, x, y, w, t, player)
    local T, tm = ZeD.T, ZeD.TM
    local d = t.d
    if not d then return 0 end
    OC.armKeys()
    card._lkW = w
    local y0 = y
    if d.busy then y = y + band(card, x, y, w, t, player) + T.px(8) end

    -- the padlock, or an empty plate when there is none
    if d.mode == "open" then
        local ph = T.px(64)
        local s2, s1 = T.surf2, T.surf1
        card:drawRect(x, y, w, ph, 1, col(s1))
        local stripe = T.px(6)
        local i = 0
        local sx = x - ph
        while sx < x + w do
            card:drawRect(math.max(x, sx), y, math.min(stripe, x + w - math.max(x, sx)), ph, (i % 2 == 0) and 0.6 or 0, col(s2))
            sx = sx + stripe
            i = i + 1
        end
        card:drawRectBorder(x, y, w, ph, T.borderS.a or 1, col(T.borderS))
        local lbl = ZeD.tr("UI_ZeD_Lock_NoPadlock")
        local f1 = T.fontF1
        local lw2 = tm:MeasureStringX(f1, lbl)
        local dc = T.textDim
        card:drawText(lbl, x + math.floor((w - lw2) / 2), y + math.floor((ph - tm:getFontHeight(f1)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f1)
        y = y + ph + T.px(10)
    else
        y = y + drawPadlock(card, x, y, t, d.mode == "key") + T.px(4)
    end
    if d.mode == "set" then
        -- what vanilla never says: the lock shuts the crate to you too
        local note = ZeD.tr("UI_ZeD_Lock_NoteSet")
        local f1 = T.fontF1
        local dc = T.textDim
        local lh = tm:getFontHeight(f1) + T.px(2)
        for _, ln in ipairs(ZeD.Atoms.wrapText(note, f1, w) or { note }) do
            local lw2 = tm:MeasureStringX(f1, ln)
            card:drawText(ln, x + math.max(0, math.floor((w - lw2) / 2)), y, dc.r, dc.g, dc.b, dc.a or 1, f1)
            y = y + lh
        end
        y = y + T.px(6)
    end

    -- what it locks
    y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Lock_WhatItLocks")) + T.px(4)
    local contents
    if d.lockedToMe then contents = ZeD.tr("UI_ZeD_Lock_Hidden")
    elseif d.items then contents = ZeD.tr(d.items == 1 and "UI_ZeD_Lock_ItemsOne" or "UI_ZeD_Lock_ItemsMany", d.items,
        string.format("%.1f", d.weight or 0), math.floor((d.cap or 0) + 0.5))
    else contents = "" end
    y = y + fact(card, x, y, w, ZeD.tr("UI_ZeD_Lock_FactContainer"), d.name .. (contents ~= "" and (" " .. DOT .. " " .. contents) or ""))
    if d.mode == "enter" then
        y = y + fact(card, x, y, w, ZeD.tr("UI_ZeD_Lock_FactPadlock"), ZeD.tr("UI_ZeD_Lock_PadComboLocked"), T.danger)
    elseif d.mode == "key" then
        y = y + fact(card, x, y, w, ZeD.tr("UI_ZeD_Lock_FactPadlock"), ZeD.tr("UI_ZeD_Lock_PadKeyOpens"), d.haveKey and T.positive or T.danger)
        y = y + fact(card, x, y, w, ZeD.tr("UI_ZeD_Lock_FactKey"), ZeD.tr(d.haveKey and "UI_ZeD_Lock_KeyIn" or "UI_ZeD_Lock_KeyNotIn"))
    elseif d.mode == "set" then
        y = y + fact(card, x, y, w, ZeD.tr("UI_ZeD_Lock_FactPadlock"), d.combo and ZeD.tr("UI_ZeD_Lock_ComboIn") or ZeD.tr("UI_ZeD_Lock_ComboNone"),
            d.combo and T.positive or T.danger)
    else
        y = y + fact(card, x, y, w, ZeD.tr("UI_ZeD_Lock_FactPadlock"), getText("IGUI_None"), T.positive)
    end
    y = y + T.px(8)

    -- needs
    if d.mode == "set" then
        y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Lock_NeedsLock")) + T.px(4)
        y = y + needRow(card, x, y, w, d.combo ~= nil, ZeD.tr("UI_ZeD_Lock_NeedCombo"))
        y = y + needRow(card, x, y, w, codeOf(t) ~= 0, ZeD.tr("UI_ZeD_Lock_NeedCode"))
    elseif d.mode == "key" then
        y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Lock_NeedsRemove")) + T.px(4)
        y = y + needRow(card, x, y, w, d.haveKey, ZeD.tr("UI_ZeD_Lock_NeedKey"))
    elseif d.mode == "open" and d.free then
        y = y + UI.section(card, x, y, w, ZeD.upper(ZeD.tr("Tooltip_craft_Needs"))) + T.px(4)
        y = y + needRow(card, x, y, w, d.combo ~= nil, ZeD.tr("UI_ZeD_Lock_NeedUseCombo"))
        y = y + needRow(card, x, y, w, d.keyPad ~= nil, ZeD.tr("UI_ZeD_Lock_NeedUsePad"))
    end
    return y - y0
end

-- ----------------------------------------------------------------------------
-- Entry points
-- ----------------------------------------------------------------------------
-- Open the card on an object (walks there first when out of reach).
function LK.openFor(player, obj, set)
    if not (player and obj) then return false end
    return OC.openNear(player, "lock", { obj = obj, set = set }, obj:getSquare())
end

OC.register(def)
print("[ZeD] ObjectCardLock: padlock card loaded")
return LK
