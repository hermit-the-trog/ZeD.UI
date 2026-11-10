-- ZeDUI/tools/qa/belt_mods_sim.lua  (Nov 7 2026, Build): the belt's two new general hooks (ZeD.Belt.addMeter,
-- ZeD.Belt.addBox) and the four ModSupport files that use them or sit beside them, with no game running. The real
-- ZeD_Belt.lua and the real ModSupport files run on Lua 5.1 stubs of the game, ZeD's library and the four mods. The
-- mods are stubs of their published shape, written here from their Lua (Workshop 3835479468, 3832759095, 3834708364,
-- 3830103302): only the functions ZeD calls, never their drawing.
--   SAME     with none of the mods on, the belt draws exactly as before this work (git show BASE:ZeD_Belt.lua): every
--            draw call equal, Full and Simple, slots with and without items, one item in both hands, a pad focus;
--            and none of the four files registers anything or leaves a global behind
--   ICR      Item Condition Restored's number on the strips and rings: liquid in T.info, its one-color styles in
--            T.positive, multicolor graduated, None and items it has nothing for back to ZeD's own condition; a
--            meter that throws is skipped
--   MASK     Mask Filter Indicator's box: after the strap and before the Messages note, the mask's picture, its filter
--            on the strip, the spares badge, the lamp (tank on, filter draining), Alert only when low, the hint, the
--            mod's menu from a click, a right-click, A and X (the pad's anchored on the box, focus in it), no drop on it,
--            the mod's strip parked while the belt is in charge and its own again in safe mode
--   AHB      Auto-Hide Hotbar: the belt attached through the mod's own call (again after a respawn's new belt, detached
--            in safe mode), keepShown for ZeD's windows (its keepInventory option) and for a belt in use; the slide the
--            mod sets for a frame is not undone by the belt, and the belt is home again between frames; the split
--            (Nov 7 2026, the director: the slots only): the strap, buckle and slots through the mod's stand-in where it
--            slid them, the hands and the Messages note on the real element at home, and without the split all of it
--   MSB      Minimal Sidebar: the belt's fade (ZeD.Belt.addAlpha) with the mod's rates and options: the strap, buckle and slots
--            fade out until the pointer is within the margin, a hand that holds something stays and an empty one fades,
--            Animation Speed scales both, Enable Mod off draws the belt as it is, the controller, a drag and a menu keep it
--            shown; the stand-in for the Java element scales every draw's alpha and is never left on
--   BIT      Better Item Transfer: the mod's lazy first options read, which put ZeD's menu style back to the file's
--            value on the first right-click, happens at game start after the options are written, so a style set in
--            game holds on the next menu (the bug reproduced first without the file)
-- What it can't show is how it looks: ZeDUI/qa/CHECK_mods_hud_20261107.md, in the game with each mod on.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/belt_mods_sim.lua
-- It prints FAIL lines and a last line "belt_mods_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]belt_mods_sim%.lua$", "")
local BASE = "2bb40b79"     -- the commit this work started from (its ZeD_Belt.lua is "today's belt")
local CLIENT = ROOT .. "42/media/lua/client/"
local BELT = "42/media/lua/client/ZeD/ZeD_Belt.lua"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

local function readFile(p)
    local f = assert(io.open(p, "rb"))
    local s = f:read("*a")
    f:close()
    return s
end
local function gitShow(rev, path)
    local cmd = 'git -C "' .. (ROOT == "" and "." or ROOT) .. '" show ' .. rev .. ":" .. path
    local h = io.popen(cmd)
    local s = h and h:read("*a") or ""
    if h then h:close() end
    return s
end

-- ---------------------------------------------------------------------------
-- THE GAME, as far as the belt and the four files ask
-- ---------------------------------------------------------------------------
local LOG = {}
local env
local rawPrint = print
print = function(s) if not tostring(s):find("^%[ZeD%]") then rawPrint(s) end end

local function logv(x)
    local t = type(x)
    if t == "number" then return string.format("%.4f", x) end
    if t == "table" then return x.path or x.name or "{tbl}" end
    return tostring(x)
end
local function logger(name)
    return function(_, ...)
        local a = { name }
        for i = 1, select("#", ...) do a[#a + 1] = logv((select(i, ...))) end
        LOG[#LOG + 1] = table.concat(a, " ")
    end
end
-- a library table: named functions given, every other name a function that writes its call down
local function recorder(fixed)
    return setmetatable(fixed or {}, { __index = function(t, k)
        local f = function(...)
            local a = { k }
            for i = 1, select("#", ...) do
                local x = select(i, ...)
                if type(x) ~= "table" or x.name or x.path then a[#a + 1] = logv(x) end
            end
            LOG[#LOG + 1] = table.concat(a, " ")
        end
        rawset(t, k, f)
        return f
    end })
end

-- Events that keep their handlers, so the sim can fire them
local function newEvents()
    return setmetatable({}, { __index = function(t, k)
        local e = { list = {} }
        e.Add = function(f) e.list[#e.list + 1] = f end
        e.Remove = function(f) for i = #e.list, 1, -1 do if e.list[i] == f then table.remove(e.list, i) end end end
        rawset(t, k, e)
        return e
    end })
end
local function fire(name, ...)
    local e = rawget(Events, name)
    if not e then return end
    for _, f in ipairs(e.list) do f(...) end
end

-- items and the character
local Item = {}
Item.__index = Item
local function item(t)
    t.name = t.name or "item"
    return setmetatable(t, Item)
end
function Item:getTex() return { name = "tex:" .. self.name } end
function Item:getConditionMax() return self.condMax or 0 end
function Item:getCondition() return self.cond or 0 end
function Item:canBeActivated() return self.activatable == true end
function Item:isActivated() return self.on == true end
function Item:getDisplayName() return self.display or self.name end
function Item:getFluidContainer() return self.fluid end
function Item:getID() return self.id or 1 end
function Item:getUsedDelta() return self.delta or 0 end
function Item:getFullType() return "Base." .. self.name end
function Item:getAttachmentType() return nil end

local function list(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end,
             getItemByIndex = function(_, i) return t[i + 1] end }
end

local function newPlayer()
    local p = { pri = nil, sec = nil, worn = {}, dead = false }
    function p:getPrimaryHandItem() return self.pri end
    function p:getSecondaryHandItem() return self.sec end
    function p:isDead() return self.dead end
    function p:getVehicle() return nil end
    function p:getWornItems() return list(self.worn) end
    function p:isEquipped(it) return it == self.pri or it == self.sec end
    function p:isHandItem(it) return it == self.pri or it == self.sec end
    function p:getDescriptor() error("no descriptor in the sim") end
    function p:getInventory() return { getItems = function() return list({}) end } end
    function p:setJoypadIgnoreAimUntilCentered() end
    return p
end

local function installGlobals()
    Events = newEvents()
    getTimestampMs = function() return env.clock end
    getText = function(k, ...) return k end
    getTextOrNull = function() return nil end
    getCore = function()
        return { getKey = function(_, name) local n = tonumber(string.match(name, "(%d+)$")); return n and (n + 1) or 0 end,
                 getGameMode = function() return "Sandbox" end }
    end
    Keyboard = { getKeyName = function(code) return tostring(code - 1) end }
    getPlayerScreenLeft, getPlayerScreenTop = function() return 0 end, function() return 0 end
    getPlayerScreenWidth, getPlayerScreenHeight = function() return 1920 end, function() return 1080 end
    Texture = { getSharedTexture = function() return nil end }
    getTexture = function() return nil end
    instanceof = function(o, cls) return type(o) == "table" and o.class == cls end
    getActivatedMods = function()
        local ids = {}
        for id in pairs(env.mods) do ids[#ids + 1] = id end
        table.sort(ids)
        return list(ids)
    end
    getPlayerHotbar = function() return env.hotbar end
    getSpecificPlayer = function() return env.player end
    getPlayerContextMenu = function() return env.ctx end
    isClient = function() return false end
    getMouseX, getMouseY = function() return env.mouseX end, function() return env.mouseY end
    getSoundManager = function() return { playUISound = function() end } end
    setJoypadFocus = function(n, what) env.joyFocus = what end
    Joypad = { AButton = 1, BButton = 2, XButton = 3, YButton = 4 }
    ISUIHandler = nil
    ISMouseDrag = nil
    ISToolTipInv = { new = function(_, it)
        local t = { item = it }
        for _, m in ipairs({ 'initialise', 'addToUIManager', 'setOwner', 'setCharacter', 'setItem', 'bringToTop', 'setVisible' }) do t[m] = function() end end
        return t
    end }
    ZeD_CharacterWindow, ZeD_WorldWindow = nil, nil
    ISContextMenu = {
        get = function(pn, x, y)
            local ctx = env.ctx
            ctx.options, ctx.x, ctx.y = {}, x, y
            ctx._zedAnchorMode, ctx._zedAnchorX, ctx._zedAnchorY = "cursor", x, y
            ctx.visible = true
            return ctx
        end,
    }
    PZAPI = nil
    ZeD_Panel = {}
    ZeD_Panel.__index = ZeD_Panel
    setmetatable(ZeD_Panel, { __index = function(_, k)
        if type(k) == "string" and (k:sub(1, 4) == "draw" or k == "setStencilRect" or k == "clearStencilRect") then return logger(k) end
        return nil
    end })
    function ZeD_Panel:derive() local c = {}; c.__index = c; return setmetatable(c, { __index = ZeD_Panel }) end
    function ZeD_Panel:new(x, y, w, h) return { _x = x, _y = y, _w = w, _h = h, _vis = true } end
    function ZeD_Panel:getX() return self._x end
    function ZeD_Panel:getY() return self._y end
    function ZeD_Panel:getAbsoluteX() return self._x end
    function ZeD_Panel:getAbsoluteY() return self._y end
    function ZeD_Panel:getWidth() return self._w end
    function ZeD_Panel:getHeight() return self._h end
    function ZeD_Panel:setX(v) self._x = v; env.setXs = env.setXs + 1 end
    function ZeD_Panel:setY(v) self._y = v; env.setYs = env.setYs + 1 end
    function ZeD_Panel:setWidth(v) self._w = v end
    function ZeD_Panel:setHeight(v) self._h = v end
    function ZeD_Panel:getMouseX() return env.mouseX - self._x end
    function ZeD_Panel:getMouseY() return env.mouseY - self._y end
    function ZeD_Panel:setCapture() end
    function ZeD_Panel:getIsVisible() return self._vis end
    function ZeD_Panel:isVisible() return self._vis end
    function ZeD_Panel:setVisible(v) self._vis = v end
    function ZeD_Panel:initialise() end
    function ZeD_Panel:addToUIManager() end
    require = function() end
end

local function installZeD()
    ZeD = { _trGen = 0 }
    local defaults = {}
    ZeD.trDefaults = function(t) for k, v in pairs(t) do defaults[k] = v end end
    local EN = { UI_ZeD_Belt_MaskLeft = "%1%% left", UI_ZeD_Belt_MaskSpares = "spares: %1" }
    ZeD.tr = function(key, ...)
        local s = EN[key] or defaults[key] or key
        for i = 1, select("#", ...) do s = string.gsub(s, "%%" .. i, (string.gsub(tostring((select(i, ...))), "%%", "%%%%"))) end
        s = string.gsub(s, "%%%%", "%%")
        return s
    end
    ZeD.textCase = function(s) return s end
    ZeD.logOnce = function(key, msg) env.errors[#env.errors + 1] = tostring(key) .. ": " .. tostring(msg) end
    ZeD.Safe = { on = function() return env.safe end, guard = function(self, fn) return fn(self) end, register = function() end }
    ZeD.Settings = { beltStyleOption = { getValue = function() return env.simple and 2 or 1 end }, ammoBoxOn = function() return false end }
    ZeD.Watch = { beltWatch = function() return nil end }
    ZeD.WatchMini = { size = function() return 44, 46 end }
    ZeD.Messages = { count = function() return env.messages end, unread = function() return 0 end, open = function() end }
    local id = 0
    local T = { scale = 1, art = 1, borderW = 1, hair = 1, fontF1 = "F1", fontF2 = "F2", fontF5 = "F5", fillBarH = 8,
                px = function(n) return n end, line = function(n) return n end }
    -- every color a distinct number, so a color shows in the drawing log
    ZeD.T = setmetatable(T, { __index = function(t, k)
        id = id + 1
        local c = { r = id / 1000, g = 0.5, b = 0.25, a = 1, name = k }
        rawset(t, k, c)
        return c
    end })
    ZeD.TM = { getFontHeight = function() return 10 end, MeasureStringX = function(_, _, s) return #tostring(s) * 6 end }
    ZeD.Atoms = recorder({
        fillBarCompactH = function() return 8 end,
        statusColor = function(f, text)   -- (Atoms.lua's status rule, punch list 143)
            local T = ZeD.T
            local lit = (f or 0) <= 0 and 0 or math.max(1, math.ceil(math.min(1, f) * 5 - 1e-6))
            if lit >= 4 then return T.positive end
            if lit >= 2 then return (text and T.warningText) or T.warning end
            return T.danger
        end,
        requestHint = function(_, key, words) env.hints[#env.hints + 1] = { key = key, words = words } end,
        drawFillBar = function(_, x, y, w, f, graduated, fc, h)
            LOG[#LOG + 1] = table.concat({ "drawFillBar", logv(x), logv(y), logv(w), logv(f), tostring(graduated), fc and fc.name or "nil", logv(h) }, " ")
            env.bars[#env.bars + 1] = { f = f, graduated = graduated, color = fc and fc.name or nil }
        end,
    })
    ZeD.Molecules = recorder()
    ZeD.Focus = { mark = function() return false end, isShowing = function() return false end, style = function() return "wash" end,
                  drawOverlay = function() end }
end

local function newCtx()
    local ctx = { options = {}, visible = false }
    function ctx:addOption(name, target, fn, ...) local o = { name = name, target = target, onSelect = fn }; self.options[#self.options + 1] = o; return o end
    function ctx:isAnyVisible() return self.visible end
    return ctx
end

local function newEnv()
    env = { clock = 1000000, mods = {}, safe = false, simple = false, messages = 0, mouseX = -100, mouseY = -100,
            errors = {}, hints = {}, bars = {}, setXs = 0, setYs = 0, joyFocus = nil }
    env.player = newPlayer()
    env.ctx = newCtx()
    env.hotbar = { chr = env.player, attachedItems = {},
        availableSlot = { { slotType = "SmallBeltLeft", name = "Belt L", def = { attachments = {} } },
                          { slotType = "SmallBeltRight", name = "Belt R", def = { attachments = {} } },
                          { slotType = "Back", name = "Back", def = { attachments = {} } } } }
    return env
end

-- the mods' published shapes
local function stubICR(mode, handMode)
    ItemCondition = { Config = { Hotbar = { ProgressBarMode = mode }, EquippedItem = { ProgressBarMode = handMode or mode },
                                 TypeDefault = { name = "default" }, TypeWater = { name = "water" } }, UI = {} }
    function ItemCondition.UI:Measure(it)
        if it.icrThrow then return nil end   -- (the mod's own pcall: nil)
        if it.fluidRatio then return it.fluidRatio, ItemCondition.Config.TypeWater end
        if it.uses then return it.uses, ItemCondition.Config.TypeDefault end
        if it.class == "HandWeapon" then return it.cond / it.condMax, ItemCondition.Config.TypeDefault end
        return nil
    end
end

local function stubMFI()
    local M = { disabled = false, swaps = 0 }
    function M.findWornMask(p)
        for _, it in ipairs(p.worn) do if it.maskCfg then return it, it.maskCfg end end
        return nil
    end
    function M.hasDrainable(mask, cfg) return mask.fitted == true end
    function M.listSpareFilters() local t = {}; for i = 1, env.spares or 0 do t[i] = 1 end; return t end
    function M.performSwap() M.swaps = M.swaps + 1 end
    MaskFilterIndicator = M
    MaskFilterIndicatorOptions = { mode = 1, blink = true }
    function MaskFilterIndicatorOptions.getHudMode() return MaskFilterIndicatorOptions.mode end
    function MaskFilterIndicatorOptions.isShowDrainBlink() return MaskFilterIndicatorOptions.blink end
    local H = { renders = 0 }
    H.__index = H
    function H.getFilterDrainStrength() return env.drain or 0 end
    function H:onRightMouseUp(x, y)
        local ctx = ISContextMenu.get(0, getMouseX(), getMouseY())
        ctx:addOption("ContextMenu_MFI_TakeOffMask", env.player, nil)
        if self.mask and self.cfg then ctx:addOption("ContextMenu_MFI_ReplaceFilter", env.player, MaskFilterIndicator.performSwap) end
        return true
    end
    function H:render() H.renders = H.renders + 1; self:setX(500); self:setY(600) end
    MaskFilterIndicatorHUD = H
end

local function stubAHB()
    local A = { attached = {}, forced = {}, opts = { keepInventory = false }, vis = 1 }
    function A.attach(el, n, owner) A.attached[el] = { n = n, owner = owner } end
    function A.detach(el) A.attached[el] = nil end
    function A.keepShown(n, id, on) A.forced[id] = on and true or nil end
    function A.opt(id) return A.opts[id] end
    function A.getVisibility() return A.vis end
    AutoHideHotbar = A
end

-- a fresh game: the belt from this source, then the ModSupport files (each returns at once unless its mod is on)
local SUPPORT = { "AutoHideHotbar", "ItemConditionRestored", "MaskFilterIndicator", "BetterItemTransfer", "MinimalSidebar" }
local function boot(source, mods)
    newEnv()
    for _, m in ipairs(mods or {}) do env.mods[m] = true end
    ZeD_BeltHUD = nil
    AutoHideHotbar, ItemCondition, MaskFilterIndicator, MaskFilterIndicatorOptions, MaskFilterIndicatorHUD = nil, nil, nil, nil, nil
    BetterItemTransferOptions = nil
    installGlobals()
    installZeD()
    if env.mods.ItemConditionRestored then stubICR(3) end
    if env.mods.MaskFilterIndicator then stubMFI() end
    if env.mods.AutoHideHotbar then stubAHB() end
    local f, err = loadstring(source, "=ZeD_Belt")
    assert(f, err)
    f()
    for _, name in ipairs(SUPPORT) do
        local g, e2 = loadfile(CLIENT .. "ZeD/ModSupport/" .. name .. ".lua")
        assert(g, e2)
        g()
    end
    fire("OnGameStart")
    return ZeD.Belt
end

local function frame()
    LOG = {}
    env.hints, env.bars = {}, {}
    local hud = ZeD.Belt.getHUD()
    hud:prerender()
    return table.concat(LOG, "\n"), hud
end

local NEW = readFile(ROOT .. BELT)
local OLD = gitShow(BASE, BELT)
if OLD == "" then print("(git show " .. BASE .. " gave nothing: the SAME section is skipped)") end

-- ---------------------------------------------------------------------------
section("SAME: no mod on, the belt as before")
-- ---------------------------------------------------------------------------
local function scenario(n)
    local knife = item({ name = "Knife", class = "HandWeapon", cond = 6, condMax = 10 })
    local lighter = item({ name = "Lighter", class = "DrainableComboItem", uses = 0.4 })
    local pot = item({ name = "Pot", condMax = 10, cond = 9, fluidRatio = 0.3 })
    local axe = item({ name = "Axe", class = "HandWeapon", cond = 2, condMax = 10 })
    local p, hb = env.player, env.hotbar
    if n == 1 then hb.attachedItems = { [1] = knife, [2] = lighter }; p.pri, p.sec = axe, pot
    elseif n == 2 then hb.attachedItems = {}; p.pri, p.sec = nil, nil
    elseif n == 3 then hb.attachedItems = { [3] = pot }; p.pri, p.sec = axe, axe
    elseif n == 4 then hb.attachedItems = { [1] = knife }; p.pri, p.sec = knife, nil; env.mouseX, env.mouseY = 9999, 9999
    end
end
if OLD ~= "" then
    for _, simple in ipairs({ false, true }) do
        for n = 1, 4 do
            boot(OLD); env.simple = simple; scenario(n)
            local a = frame(); local a2 = frame()
            boot(NEW); env.simple = simple; scenario(n)
            local b = frame(); local b2 = frame()
            local nLines = select(2, string.gsub(b, "\n", "")) + 1
            check("SAME the frame draws (" .. (simple and "Simple" or "Full") .. " " .. n .. ")", nLines > 40, nLines)
            check("SAME draws, " .. (simple and "Simple" or "Full") .. " scenario " .. n, a == b and a2 == b2,
                (a ~= b) and ("first difference near: " .. (function()
                    local i = 1
                    while i <= #a and a:sub(i, i) == b:sub(i, i) do i = i + 1 end
                    return a:sub(math.max(1, i - 60), i + 60) .. " || " .. b:sub(math.max(1, i - 60), i + 60)
                end)()) or nil)
        end
    end
end
boot(NEW)
check("SAME no meter or box registered with no mod on", #ZeD.Belt._meters == 0 and #ZeD.Belt._extras == 0)
check("SAME no ModSupport table with no mod on", ZeD.ModSupport == nil or next(ZeD.ModSupport) == nil)
check("SAME no Events handler from the files with no mod on", rawget(Events, "OnTick") ~= nil and #rawget(Events, "OnTick").list == 1)

-- ---------------------------------------------------------------------------
section("ICR: Item Condition Restored's numbers")
-- ---------------------------------------------------------------------------
boot(NEW, { "ItemConditionRestored" })
local B = ZeD.Belt
local pot = item({ name = "Pot", condMax = 10, cond = 9, fluidRatio = 0.3 })
local lighter = item({ name = "Lighter", class = "DrainableComboItem", uses = 0.4 })
local sword = item({ name = "Sword", class = "HandWeapon", cond = 7, condMax = 10 })
local shirt = item({ name = "Shirt", cond = 5, condMax = 10 })
local f, k = B.meter(pot, "slot")
check("ICR liquid: its fill, fluid", f == 0.3 and k == "fluid", tostring(f) .. " " .. tostring(k))
f, k = B.meter(lighter, "slot")
check("ICR drainable: uses left, graduated (multicolor)", f == 0.4 and k == nil, tostring(f) .. " " .. tostring(k))
f, k = B.meter(shirt, "slot")
check("ICR nothing from the mod: ZeD's own condition", f == 0.5 and k == nil, tostring(f) .. " " .. tostring(k))
stubICR(2, 1)
f, k = B.meter(sword, "slot")
check("ICR one-color style: flat", f == 0.7 and k == "flat", tostring(f) .. " " .. tostring(k))
f, k = B.meter(lighter, "hand")
check("ICR hands set to None: ZeD's own (no condition: nil)", f == nil, tostring(f))
f, k = B.meter(sword, "hand")
check("ICR hands set to None: a weapon keeps ZeD's own condition", f == 0.7 and k == nil, tostring(f) .. " " .. tostring(k))
stubICR(3)
env.hotbar.attachedItems = { [1] = pot, [2] = lighter }
env.player.pri = item({ name = "Kettle", condMax = 10, cond = 9, fluidRatio = 0.8 })
local log = frame()
check("ICR the slot strips: liquid in info, uses graduated",
    env.bars[1] and env.bars[1].color == "info" and env.bars[1].graduated == false and env.bars[1].f == 0.3
    and env.bars[2] and env.bars[2].color == nil and env.bars[2].graduated == true and env.bars[2].f == 0.4)
check("ICR the hand ring in the info color", log:find(string.format("%.4f", ZeD.T.info.r), 1, true) ~= nil)
ItemCondition.UI.Measure = function() error("boom") end
f = B.meter(shirt, "slot")
check("ICR a meter that throws: ZeD's own condition", f == 0.5, tostring(f))
ItemCondition = nil
f = B.meter(lighter, "slot")
check("ICR the mod's table gone: ZeD's own", f == nil)

-- ---------------------------------------------------------------------------
section("MASK: Mask Filter Indicator's box")
-- ---------------------------------------------------------------------------
boot(NEW, { "MaskFilterIndicator" })
B = ZeD.Belt
env.messages = 1
local log0 = frame()
local hud = B.getHUD()
local function boxOf(kind)
    for i, b in ipairs(hud._boxes) do if b.kind == kind then return b, i end end
    return nil
end
check("MASK no mask worn: no box", boxOf("extra") == nil)
local gas = item({ name = "GasMask", display = "Gas Mask", maskCfg = { isTank = false }, fitted = true, delta = 0.64 })
env.player.worn = { gas }
env.spares = 2
env.clock = env.clock + 1000
frame()
local xb, xi = boxOf("extra")
local lb, li = boxOf("lamp")
check("MASK the box is there", xb ~= nil)
check("MASK after the strap, before the Messages note", xb and lb and xi < li and xb.x > hud._strap.x + hud._strap.w - 1 and xb.x < lb.x)
check("MASK a slot's size", xb and xb.w == 44 and xb.h == 44)
check("MASK the filter on the strip, graduated", #env.bars >= 1 and env.bars[#env.bars].f == 0.64 and env.bars[#env.bars].graduated == true)
local log2 = table.concat(LOG, "\n")
check("MASK the picture", log2:find("tex:GasMask", 1, true) ~= nil)
check("MASK the spares badge", log2:find("drawText +2", 1, true) ~= nil)
check("MASK no lamp: not draining", log2:find("drawLamp", 1, true) == nil)
env.drain = 0.3; env.clock = env.clock + 1000
frame(); log2 = table.concat(LOG, "\n")
check("MASK a lamp while the filter is being used up", log2:find("drawLamp", 1, true) ~= nil)
MaskFilterIndicatorOptions.blink = false; env.clock = env.clock + 1000
frame(); log2 = table.concat(LOG, "\n")
check("MASK no lamp with the mod's blink option off", log2:find("drawLamp", 1, true) == nil)
-- hint
env.mouseX, env.mouseY = hud._x + xb.x + 5, hud._y + xb.y + 5
frame()
local hint = env.hints[#env.hints]
check("MASK the hint", hint and hint.words == "Gas Mask | 64% left | spares: 2", hint and hint.words)
-- the mod's menu: click, right-click
env.ctx.visible = false
hud:onMouseDown(xb.x + 5, xb.y + 5)
check("MASK the press alone opens nothing (the menu could take the release)", env.ctx.visible == false)
hud:onMouseUp(xb.x + 5, xb.y + 5)
check("MASK a click opens the mod's menu on the release", env.ctx.visible and #env.ctx.options == 2 and env.ctx.options[2].name == "ContextMenu_MFI_ReplaceFilter")
env.ctx.visible = false
hud:onRightMouseUp(xb.x + 5, xb.y + 5)
check("MASK a right-click opens it", env.ctx.visible and #env.ctx.options == 2)
check("MASK a mouse menu at the pointer", env.ctx._zedAnchorX == env.mouseX)
-- pad
env.ctx.visible = false
hud._gp = { idx = xi, inList = false, row = 1, list = {} }
hud:onJoypadDown(Joypad.AButton)
check("MASK A opens the menu, focus in it", env.ctx.visible and env.joyFocus == env.ctx and env.ctx.origin == hud)
check("MASK the pad's menu anchored on the box", env.ctx._zedAnchorX == hud._x + xb.x + 22 and env.ctx._zedAnchorY == hud._y + xb.y)
env.ctx.visible = false; env.joyFocus = nil
hud:onJoypadDown(Joypad.XButton)
check("MASK X opens it too", env.ctx.visible and env.joyFocus == env.ctx)
hud._gp = nil
check("MASK nothing drops on the box", hud:_dropState(xb, { lighter }) == "no")
env.ctx.visible = false
-- no filter, tank, alert
gas.fitted = false; env.spares = 0; env.clock = env.clock + 1000
frame()
check("MASK no filter: the empty well", env.bars[#env.bars] and env.bars[#env.bars].f == 0)
hint = env.hints[#env.hints]
check("MASK no filter: the game's and the mod's words", hint and hint.words == "Gas Mask | Tooltip_NoFilter | UI_MFI_NoSpareFilter", hint and hint.words)
local scba = item({ name = "SCBA", maskCfg = { isTank = true }, fitted = true, delta = 0.5, on = true })
env.player.worn = { scba }; env.clock = env.clock + 1000
frame(); log2 = table.concat(LOG, "\n")
check("MASK an SCBA turned on: the lamp", log2:find("drawLamp", 1, true) ~= nil)
MaskFilterIndicatorOptions.mode = 2; env.player.worn = { gas }; gas.fitted = true; gas.delta = 0.6; env.clock = env.clock + 1000
frame()
check("MASK Alert, not low: no box", boxOf("extra") == nil)
gas.delta = 0.2; env.clock = env.clock + 1000
frame()
check("MASK Alert, low: the box", boxOf("extra") ~= nil)
MaskFilterIndicator.disabled = true; env.clock = env.clock + 1000
frame()
check("MASK the mod disabled itself: no box", boxOf("extra") == nil)
MaskFilterIndicator.disabled = false
-- the mod's strip: parked, then its own in safe mode
local strip = setmetatable({ _x = 500, _y = 600, keepOnScreen = true, _posRestored = true }, MaskFilterIndicatorHUD)
function strip:getX() return self._x end
function strip:getY() return self._y end
function strip:setX(v) self._x = v end
function strip:setY(v) self._y = v end
local before = MaskFilterIndicatorHUD.renders
strip:render()
check("MASK the mod's strip parked while the belt is in charge", strip._x == -100000 and strip._y == -100000
    and strip.keepOnScreen == false and strip._posRestored == false and MaskFilterIndicatorHUD.renders == before)
env.safe = true
strip:render()
check("MASK safe mode: the mod's strip its own again", MaskFilterIndicatorHUD.renders == before + 1 and strip.keepOnScreen == true and strip._x == 500)
env.safe = false
-- a box that throws: skipped, the belt goes on
ZeD.Belt.addBox("Broken", { state = function() error("boom") end })
env.clock = env.clock + 1000
local okF = pcall(frame)
check("MASK another box that throws: skipped", okF and boxOf("extra") ~= nil)

-- ---------------------------------------------------------------------------
section("AHB: Auto-Hide Hotbar")
-- ---------------------------------------------------------------------------
boot(NEW, { "AutoHideHotbar" })
B = ZeD.Belt
hud = B.getHUD()
local S = ZeD.ModSupport.AutoHideHotbar
S.upkeep()
check("AHB the belt attached through the mod's call", AutoHideHotbar.attached[hud] and AutoHideHotbar.attached[hud].owner == "zed")
fire("OnGameStart")    -- a respawn: a new belt
local hud2 = B.getHUD()
S.upkeep()
check("AHB a new belt attached, the old one detached", hud2 ~= hud and AutoHideHotbar.attached[hud2] ~= nil and AutoHideHotbar.attached[hud] == nil)
hud = hud2
env.safe = true; S.upkeep()
check("AHB safe mode: detached", AutoHideHotbar.attached[hud] == nil)
env.safe = false; S.upkeep()
check("AHB back from safe mode: attached", AutoHideHotbar.attached[hud] ~= nil)
local cwVis = true
ZeD_CharacterWindow = { getWindow = function() return { isVisible = function() return cwVis end } end }
S.upkeep()
check("AHB keepInventory off: ZeD's windows do not keep it", AutoHideHotbar.forced.zed_windows == nil)
AutoHideHotbar.opts.keepInventory = true; S.upkeep()
check("AHB keepInventory on: ZeD's Character window keeps it shown", AutoHideHotbar.forced.zed_windows == true)
cwVis = false; S.upkeep()
check("AHB the window closed: let go", AutoHideHotbar.forced.zed_windows == nil)
hud._gp = { idx = 1, inList = false, row = 1, list = {} }; S.upkeep()
check("AHB the controller on the belt keeps it shown", AutoHideHotbar.forced.zed_belt == true)
hud._gp = nil; env.ctx.visible = true; AutoHideHotbar.vis = 1; S.upkeep()
check("AHB a menu open while it shows keeps it", AutoHideHotbar.forced.zed_belt == true)
AutoHideHotbar.vis = 0; S.upkeep()
check("AHB a menu open while it is hidden does not show it", AutoHideHotbar.forced.zed_belt == nil)
env.ctx.visible = false
-- the slide: the mod moves the belt for its drawing; the belt does not put it back mid-frame; home between frames
frame()
local homeY = hud._y
hud._y = homeY + 40          -- (something else moved it, no mod drawing: the belt puts itself home, as before)
frame()
check("AHB no hold: the belt puts itself home in its drawing, as before", hud._y == homeY)
hud._y = homeY + 40; hud._ahbBusy = true   -- (the mod's slide for this frame, while it draws)
frame()
hud._ahbBusy = nil
check("AHB the slide holds through the belt's drawing", hud._y == homeY + 40)
fire("OnTick")
check("AHB home again between frames", hud._y == homeY)
-- the slots only (the director, Nov 7 2026): while the mod draws, the strap, buckle and slots go through its stand-in
-- where it slid them; the hands, the Messages note and the rest on the real element at home
do
    local seen = {}
    local function spy(name)
        local orig = ZeD_BeltHUD[name]
        ZeD_BeltHUD[name] = function(self, b, ...)
            local j = rawget(self, "javaObject")
            local r = j and (rawget(j, "_ahbReal") or j)
            seen[#seen + 1] = { what = (name == "_drawBox" and b and b.kind) or name, via = j and j.tag, y = r and r._y }
            return orig(self, b, ...)
        end
        return orig
    end
    local spied = {}
    for _, n in ipairs({ "_drawBox", "_drawStrap", "_drawBuckle", "_drawLamp" }) do spied[n] = spy(n) end
    local real = { tag = "real" }
    function real:getX() return self._x end
    function real:getY() return self._y end
    function real:setX(v) self._x = v end
    function real:setY(v) self._y = v end
    local px = { tag = "px", _ahbReal = real }
    env.messages = 1
    env.player.pri = item({ name = "Axe", class = "HandWeapon", cond = 2, condMax = 10 })
    env.hotbar.attachedItems = { [1] = item({ name = "Knife", class = "HandWeapon", cond = 6, condMax = 10 }) }
    hud.javaObject = real
    frame()
    local hx, hy = hud._homeX, hud._homeY
    local function kinds(via, y)
        local t = {}
        for _, s in ipairs(seen) do if s.via == via and (y == nil or s.y == y) then t[s.what] = (t[s.what] or 0) + 1 end end
        return t
    end
    -- the mod's frame: slid 40 down and faded (its stand-in on the belt)
    real._x, real._y = hx, hy + 40
    hud.javaObject, hud._ahbBusy = px, true
    seen = {}
    frame()
    local slid = kinds("px", hy + 40)
    local home = kinds("real", hy)
    check("AHB split: the slots through the mod's fade, where it slid them", (slid.slot or 0) == 3 and home.slot == nil, (slid.slot or 0) .. "/" .. tostring(home.slot))
    check("AHB split: the strap and buckle with them", slid._drawStrap == 1 and slid._drawBuckle == 1 and home._drawStrap == nil)
    check("AHB split: the hands stay, at home and unfaded", home.hand == 2 and slid.hand == nil, tostring(home.hand) .. "/" .. tostring(slid.hand))
    check("AHB split: the Messages note stays", home._drawLamp == 1 and slid._drawLamp == nil)
    check("AHB split: nothing drawn anywhere else", #seen == (slid.slot or 0) + 2 + 2 + 1, #seen)
    check("AHB split: the real element at home after the drawing (the mod restores its own after)", real._x == hx and real._y == hy)
    hud._ahbBusy, hud.javaObject = nil, real
    -- slid with no fade this frame: the javaObject is the real one, only moved
    real._x, real._y = hx, hy + 25
    hud._ahbBusy = true
    seen = {}
    frame()
    slid, home = kinds("real", hy + 25), kinds("real", hy)
    check("AHB split, slide only: the slots slid", (slid.slot or 0) == 3, slid.slot)
    check("AHB split, slide only: the hands at home", home.hand == 2, home.hand)
    hud._ahbBusy = nil
    -- no mod drawing: one element, nothing switched
    seen = {}
    frame()
    local all = kinds("real", hy)
    check("AHB no split between the mod's frames", (all.slot or 0) == 3 and all.hand == 2 and #seen == 8, #seen)
    -- the proof can fail: without the split hook the hands slide and fade with the slots (the whole belt hid)
    ZeD.Belt._splits = {}
    real._x, real._y = hx, hy + 40
    hud.javaObject, hud._ahbBusy = px, true
    seen = {}
    frame()
    local whole = kinds("px", hy + 40)
    check("AHB without the split the hands went with the slots (the check can fail)", whole.hand == 2, whole.hand)
    hud._ahbBusy, hud.javaObject = nil, nil
    for n, f in pairs(spied) do ZeD_BeltHUD[n] = f end
    env.messages = 0
end
AutoHideHotbar = nil
local okT = pcall(S.upkeep)
check("AHB the mod's table gone: nothing breaks", okT)
check("AHB no errors logged", #env.errors == 0, env.errors[1])

-- ---------------------------------------------------------------------------
section("MSB: Minimal Sidebar's fade on the belt")
-- ---------------------------------------------------------------------------
-- the mod's options as PZAPI.ModOptions keeps them (its own ids; a combo's value is the item's index)
local msbOpts
local function stubMSBOptions()
    msbOpts = { EnableMinimalSidebar = true, ShowHeartOnPulse = false, AnimationSpeed = 2 }
    PZAPI = { ModOptions = {} }
    function PZAPI.ModOptions:getOptions(id)
        if id ~= "MinimalSideBar" then return nil end
        return { getOption = function(_, oid)
            if msbOpts[oid] == nil then return nil end
            return { getValue = function() return msbOpts[oid] end }
        end }
    end
end
-- the Java element the belt draws on: any Draw call is written down with its arguments
local function fakeReal()
    local r = { _x = 0, _y = 0, calls = {} }
    function r:getX() return self._x end
    function r:getY() return self._y end
    function r:setX(v) self._x = v end
    function r:setY(v) self._y = v end
    return setmetatable(r, { __index = function(t, k)
        if type(k) ~= "string" then return nil end
        if k:sub(1, 4) ~= "Draw" then return function() end end
        return function(self, ...) self.calls[#self.calls + 1] = { k, ... } end
    end })
end
local msbSeen
local function msbSpy()
    local spied = {}
    for _, name in ipairs({ "_drawBox", "_drawStrap", "_drawBuckle", "_drawLamp" }) do
        local orig = ZeD_BeltHUD[name]
        spied[name] = orig
        ZeD_BeltHUD[name] = function(self, b, ...)
            local j = rawget(self, "javaObject")
            local a = j and rawget(j, "_a") or 1
            msbSeen[#msbSeen + 1] = { what = (name == "_drawBox" and b and b.kind) or name, which = b and b.which, a = a }
            return orig(self, b, ...)
        end
    end
    return spied
end
local function msbUnspy(spied) for n, f in pairs(spied) do ZeD_BeltHUD[n] = f end end
local function msbAlpha(what, which)
    for _, s in ipairs(msbSeen) do
        if s.what == what and (which == nil or s.which == which) then return s.a end
    end
    return nil
end
local function msbRun(n) for _ = 1, n do msbSeen = {}; frame() end end
local function msbStage()
    boot(NEW, { "MinimalSidebar" })
    stubMSBOptions()
    env.messages = 1
    env.player.pri = item({ name = "Axe", class = "HandWeapon", cond = 2, condMax = 10 })
    env.player.sec = nil
    env.hotbar.attachedItems = { [1] = item({ name = "Knife", class = "HandWeapon", cond = 6, condMax = 10 }) }
    local h = ZeD.Belt.getHUD()
    h.javaObject = fakeReal()
    return h
end

hud = msbStage()
local MS = ZeD.ModSupport and ZeD.ModSupport.MinimalSidebar
check("MSB the file answers with the mod on", type(MS) == "table")
check("MSB the belt has one alpha provider", #ZeD.Belt._alphas == 1)
local real0 = hud.javaObject
local spied = msbSpy()
-- the pointer far away: the strap, buckle and slots fade out; the held hand stays; the empty hand fades; the note stays
env.mouseX, env.mouseY = -500, -500
msbRun(1)
check("MSB the first frame starts shown and begins to fade (1.0x: a tenth of the gap)", math.abs(msbAlpha("slot") - 0.9) < 0.001, msbAlpha("slot"))
msbRun(120)
check("MSB far pointer: the slots fade out", msbAlpha("slot") == 0, msbAlpha("slot"))
check("MSB the strap and the buckle fade with them", msbAlpha("_drawStrap") == 0 and msbAlpha("_drawBuckle") == 0)
check("MSB the hand that holds something stays", msbAlpha("hand", "p") == 1, msbAlpha("hand", "p"))
check("MSB the empty hand fades", msbAlpha("hand", "s") == 0, msbAlpha("hand", "s"))
check("MSB the Messages note stays", msbAlpha("_drawLamp") == 1, msbAlpha("_drawLamp"))
check("MSB the belt's element is the real one after the drawing", hud.javaObject == real0)
-- a faded part draws nothing through the stand-in; a half-faded one draws at half
do
    ZeD.Belt.fadeTo(hud, 0)
    real0.calls = {}
    hud.javaObject:DrawText("F", "x", 1, 2, 1, 1, 1, 1, 1)
    check("MSB a part at 0 is not drawn", #real0.calls == 0)
    ZeD.Belt.fadeTo(hud, 0.5)
    hud.javaObject:DrawText("F", "x", 1, 2, 1, 1, 1, 1, 0.8)
    hud.javaObject:DrawTextureScaledColor("t", 1, 2, 3, 4, 1, 1, 1, 1)
    hud.javaObject:setStencilRect(1, 2, 3, 4)
    local c1, c2 = real0.calls[1], real0.calls[2]
    check("MSB half faded: the alpha last is halved", c1 and math.abs(c1[#c1] - 0.4) < 1e-9 and c2 and math.abs(c2[#c2] - 0.5) < 1e-9)
    check("MSB the other calls pass through", #real0.calls == 2 or real0.calls[3] == nil)
    ZeD.Belt.fadeTo(hud, nil)
    check("MSB fadeTo(nil) puts the real element back", hud.javaObject == real0)
end
-- the pointer on the belt (and within the margin): everything comes back
env.mouseX, env.mouseY = hud._x + hud._w / 2, hud._y + hud._h / 2
msbRun(120)
check("MSB pointer on the belt: the slots are back", msbAlpha("slot") == 1, msbAlpha("slot"))
check("MSB the empty hand is back too (it follows the fade)", msbAlpha("hand", "s") == 1)
env.mouseX, env.mouseY = hud._x + hud._w + 30, hud._y + hud._h / 2
msbRun(120)
check("MSB pointer inside the margin (30 of 50): still shown", msbAlpha("slot") == 1, msbAlpha("slot"))
env.mouseX = hud._x + hud._w + 80
msbRun(120)
check("MSB pointer past the margin: faded", msbAlpha("slot") == 0, msbAlpha("slot"))
env.mouseX, env.mouseY = hud._x + hud._w / 2, hud._y - 30
msbRun(120)
check("MSB 30 above the belt: shown", msbAlpha("slot") == 1)
-- in use: the controller, a drag off the belt, a menu open while it shows
env.mouseX, env.mouseY = -500, -500
hud._gp = { idx = 1, inList = false, row = 1, list = {} }
msbRun(120)
check("MSB the controller on the belt keeps it shown", msbAlpha("slot") == 1, msbAlpha("slot"))
hud._gp = nil
msbRun(120)
check("MSB the controller off: it fades again", msbAlpha("slot") == 0)
hud._out = { active = true }
msbRun(120)
check("MSB a slot dragged off the belt keeps it shown", msbAlpha("slot") == 1)
hud._out = nil
msbRun(120)
env.ctx.visible = true
msbRun(30)
check("MSB a menu open while it is hidden does not show it", msbAlpha("slot") == 0)
env.mouseX, env.mouseY = hud._x + hud._w / 2, hud._y + hud._h / 2
msbRun(120)
env.mouseX, env.mouseY = -500, -500
msbRun(30)
check("MSB a menu open while it shows keeps it", msbAlpha("slot") == 1)
env.ctx.visible = false
msbRun(120)
check("MSB the menu shut: it fades", msbAlpha("slot") == 0)
-- the hand: a hand that is filled comes back by itself, an emptied one fades
env.player.sec = item({ name = "Pot", condMax = 10, cond = 9, fluidRatio = 0.3 })
msbRun(120)
check("MSB a hand that now holds something comes back with the pointer far", msbAlpha("hand", "s") == 1, msbAlpha("hand", "s"))
env.player.pri, env.player.sec = nil, nil
msbRun(120)
check("MSB both hands emptied: both fade", msbAlpha("hand", "p") == 0 and msbAlpha("hand", "s") == 0)
env.player.pri = item({ name = "Axe", class = "HandWeapon", cond = 2, condMax = 10 })
-- Animation Speed: the combo's index into 0.5x..5x; the hand fades at 0.15 times it
env.mouseX, env.mouseY = hud._x + hud._w / 2, hud._y + hud._h / 2
msbRun(120)
for _, c in ipairs({ { 1, 0.95 }, { 2, 0.9 }, { 4, 0.8 }, { 10, 0.5 } }) do
    msbOpts.AnimationSpeed = c[1]
    env.mouseX, env.mouseY = hud._x + hud._w / 2, hud._y + hud._h / 2
    msbRun(120)
    env.mouseX, env.mouseY = -500, -500
    msbRun(1)
    check("MSB Animation Speed item " .. c[1] .. ": one frame of fading leaves " .. c[2], math.abs(msbAlpha("slot") - c[2]) < 0.001, msbAlpha("slot"))
end
msbOpts.AnimationSpeed = 2
env.mouseX, env.mouseY = hud._x + hud._w / 2, hud._y + hud._h / 2
msbRun(120)
check("MSB speed as a string ('2.5x') reads the number", (function() msbOpts.AnimationSpeed = "2.5x"; return MS.speed() end)() == 2.5)
msbOpts.AnimationSpeed = 2
env.player.sec = item({ name = "Pot", condMax = 10, cond = 9, fluidRatio = 0.3 })
msbRun(120)
env.player.sec = nil
env.mouseX, env.mouseY = -500, -500
msbRun(1)
check("MSB an emptied hand's own fade runs at 0.15 of the gap (1.0x), the slots' at 0.1", math.abs(MS.state[0].off - 0.85) < 0.001 and math.abs(MS.state[0].fade - 0.9) < 0.001, MS.state[0].off)
-- Enable Mod off: nothing is faded, the element is never swapped
msbOpts.EnableMinimalSidebar = false
msbRun(5)
check("MSB Enable Mod off: every part as it is", msbAlpha("slot") == 1 and msbAlpha("_drawStrap") == 1 and msbAlpha("hand", "s") == 1)
check("MSB Enable Mod off: the real element throughout", hud.javaObject == real0)
msbOpts.EnableMinimalSidebar = true
msbRun(120)
check("MSB Enable Mod on again: it fades", msbAlpha("slot") == 0)
-- no options table at all (the mod's options not made yet): the mod's defaults, on at 1.0x
PZAPI = nil
check("MSB no options: on, 1.0x", MS.enabled() == true and MS.speed() == 1)
stubMSBOptions()
-- a mod's split holds the drawing: no fade that frame
do
    local sreal = hud.javaObject
    ZeD.Belt.addSplit("msbtest", function() return sreal end)
    sreal._x, sreal._y = hud._homeX or 0, hud._homeY or 0
    msbRun(1)
    check("MSB while another mod splits the drawing the fade stands aside", msbAlpha("slot") == 1 and msbAlpha("_drawStrap") == 1)
    ZeD.Belt._splits = {}
end
-- a frame that threw leaves the stand-in on; the next frame starts with the real element
ZeD.Belt.fadeTo(hud, 0.3)
check("MSB (setup) the stand-in is on", hud.javaObject ~= real0)
msbRun(1)
check("MSB the next frame puts the real element back", hud.javaObject == real0)
-- safe mode: the belt is not drawn (wanted), nothing of the fade is left on it
-- the provider that throws is skipped; the belt's drawing goes on
ZeD.Belt.addAlpha("boom", { alpha = function() error("boom") end, frame = function() error("boom") end })
msbRun(1)
check("MSB a provider that throws is skipped", #msbSeen > 5 and #env.errors == 0)
ZeD.Belt._alphas = {}
-- the proof can fail: with no provider the belt's parts are never faded
msbRun(1)
check("MSB no provider: no fade", msbAlpha("slot") == 1)
check("MSB no errors logged", #env.errors == 0, env.errors[1])
-- the real mod's file as the game has it: its options as the mod reads them, the numbers the mod's source holds
do
    local fh = io.open("C:/steamcmd/steamapps/workshop/content/108600/3642084851/mods/MinimalSidebar/common/media/lua/client/MinimalSideBar.lua", "rb")
    local src = fh and fh:read("*a") or nil
    if fh then fh:close() end
    if src then check("MSB the mod's source has our rates (0.1, 0.15, margin 50, ids)", src:find("a,b,c,d,e,f,g,h,i,j=0.1,0.15,0,1,50", 1, true) ~= nil
        and src:find("'EnableMinimalSidebar'", 1, true) ~= nil and src:find("'AnimationSpeed'", 1, true) ~= nil
        and src:find("PZAPI.ModOptions:create('MinimalSideBar'", 1, true) ~= nil) end
end
msbUnspy(spied)
env.messages = 0

-- QA's in-game sequence (zedqa_minsidebar.lua), the pointer told to the belt as the script does it (an instance
-- getMouseX / getMouseY relative to the belt; the desktop cursor stays far away, as it does in game): away, back on the
-- belt, inside and outside the margin, and the frames Animation Speed takes
do
    hud = msbStage()
    MS = ZeD.ModSupport.MinimalSidebar     -- (a fresh game: the file's table is a new one)
    local sp = msbSpy()
    local function point(rx, ry) hud.getMouseX = function() return rx end; hud.getMouseY = function() return ry end end
    local function frames(pred, max) for n = 1, max do msbSeen = {}; frame(); if pred() then return n end end return nil end
    local function fadeNow() return MS.state[0].fade end
    env.mouseX, env.mouseY = -5000, -5000       -- (the real cursor: away for the whole sequence)
    point(hud._w / 2, hud._h / 2)
    msbRun(3)
    check("MSB2 the belt starts shown with the pointer told to be on it", fadeNow() == 1)
    point(-5000, -5000)
    check("MSB2 away: the fade runs out", frames(function() return fadeNow() < 0.02 end, 90) ~= nil)
    point(hud._w / 2, hud._h / 2)
    local back = frames(function() return fadeNow() > 0.98 end, 90)
    check("MSB2 on the belt: it comes back (" .. tostring(back) .. " frames)", back ~= nil)
    msbRun(60)
    check("MSB2 the slots and both hands are drawn at 1 again",msbAlpha("slot") == 1 and msbAlpha("hand", "s") == 1)
    point(hud._w / 2, -30)
    msbRun(60)
    check("MSB2 30 units above the belt (inside the margin): still shown", fadeNow() > 0.98, fadeNow())
    point(hud._w / 2, -80)
    check("MSB2 80 units above (outside): faded again", frames(function() return fadeNow() < 0.02 end, 90) ~= nil)
    -- Animation Speed, frames from the pointer leaving to the fade passing a half (QA: 0.5x counted 1, 5.0x counted 1)
    for _, c in ipairs({ { 1, 12, 16 }, { 10, 1, 2 } }) do
        msbOpts.AnimationSpeed = c[1]
        point(hud._w / 2, hud._h / 2)
        local up = frames(function() return fadeNow() > 0.98 end, 120)
        check("MSB2 speed item " .. c[1] .. ": shown again (" .. tostring(up) .. " frames)", up ~= nil)
        point(-5000, -5000)
        local n = frames(function() return fadeNow() < 0.5 end, 60)
        check("MSB2 speed item " .. c[1] .. ": half faded after " .. tostring(n) .. " frames (" .. c[2] .. " to " .. c[3] .. ")", n ~= nil and n >= c[2] and n <= c[3])
    end
    msbOpts.AnimationSpeed = 2
    -- the script lets go: the belt reads the cursor again
    hud.getMouseX, hud.getMouseY = nil, nil
    env.mouseX, env.mouseY = hud._x + hud._w / 2, hud._y + hud._h / 2
    check("MSB2 the told pointer let go: the cursor is read again", frames(function() return fadeNow() > 0.98 end, 90) ~= nil)
    msbUnspy(sp)
    env.messages = 0
end

-- ---------------------------------------------------------------------------
section("BIT: Better Item Transfer's first options read")
-- ---------------------------------------------------------------------------
-- ModOptions as the game has it: values in memory, ModOptions.ini on disk; save writes the one, load reads the other
local function stubModOptions()
    local file = { contextStyle = 1 }
    local zedStyle = { value = 1 }
    PZAPI = { ModOptions = { saves = 0, loads = 0 } }
    function PZAPI.ModOptions:save() self.saves = self.saves + 1; file.contextStyle = zedStyle.value end
    function PZAPI.ModOptions:load() self.loads = self.loads + 1; zedStyle.value = file.contextStyle end
    -- the mod's options file as it is: the first get reads the whole file, once
    local loaded = false
    BetterItemTransferOptions = { get = function(id)
        if not loaded then PZAPI.ModOptions:load(); loaded = true end
        return true
    end }
    return zedStyle, file
end
-- without ZeD's file: the bug, as QA saw it
newEnv(); installGlobals(); installZeD()
local style = stubModOptions()
fire("OnGameStart")
style.value = 2                                   -- the list, set in game (as QA's script does)
BetterItemTransferOptions.get("showIcons")        -- the first right-click on an item
check("BIT without ZeD's file the first menu's style goes back to the file (the bug, reproduced)", style.value == 1)
-- with it
newEnv(); env.mods.BetterItemTransfer = true; installGlobals(); installZeD()
style = stubModOptions()
assert(loadfile(CLIENT .. "ZeD/ModSupport/BetterItemTransfer.lua"))()
fire("OnGameStart")
check("BIT primed at game start", ZeD.ModSupport.BetterItemTransfer.primed == true and PZAPI.ModOptions.loads == 1 and PZAPI.ModOptions.saves == 1)
style.value = 2
BetterItemTransferOptions.get("showIcons")
check("BIT the style set in game holds on the first menu", style.value == 2)
-- a value changed before the read is written first, so the read gives it back
newEnv(); env.mods.BetterItemTransfer = true; installGlobals(); installZeD()
style = stubModOptions()
assert(loadfile(CLIENT .. "ZeD/ModSupport/BetterItemTransfer.lua"))()
style.value = 2
fire("OnGameStart")
check("BIT a value not yet written survives the read", style.value == 2)
-- a save that fails: no read now (it would put the file back), the mod's own first use reads later
newEnv(); env.mods.BetterItemTransfer = true; installGlobals(); installZeD()
style = stubModOptions()
PZAPI.ModOptions.save = function() error("disk") end
assert(loadfile(CLIENT .. "ZeD/ModSupport/BetterItemTransfer.lua"))()
fire("OnGameStart")
check("BIT a failed save: no read made", PZAPI.ModOptions.loads == 0 and ZeD.ModSupport.BetterItemTransfer.primed == false)
-- the mod's file missing: nothing
newEnv(); env.mods.BetterItemTransfer = true; installGlobals(); installZeD()
stubModOptions(); BetterItemTransferOptions = nil
assert(loadfile(CLIENT .. "ZeD/ModSupport/BetterItemTransfer.lua"))()
local okB = pcall(fire, "OnGameStart")
check("BIT the mod's options table missing: nothing breaks", okB and ZeD.ModSupport.BetterItemTransfer.primed == false)

print(string.format("belt_mods_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
