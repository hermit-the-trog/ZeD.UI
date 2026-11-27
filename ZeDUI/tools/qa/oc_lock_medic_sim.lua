-- ZeDUI/tools/qa/oc_lock_medic_sim.lua (QA LK1, LK4, OC7, MD2, MD4, Nov 26 2026): the lock and medic cards' fixes,
-- with no game running. The real ObjectCardLock.lua and ObjectCardMedic.lua run on stubs; the World window's
-- openObjectCard, the card host's pad stops and the Health tab's wound words are cut from their files.
--   LK1  the Lock question names the code ("3 1 9"); while it asks, the mouse wheel over a wheel, its chevrons, the
--        number keys and the pad's grab turn nothing; Yes locks with exactly the code the question named
--   LK4  the NEEDS words say the main inventory (every language); with two key padlocks, the first keyless, Use
--        padlock is offered and puts on the one with its keys
--   OC7  opening a card leaves his extra Loot columns open
--   MD2  outside cheat mode the medic card gives no percent (header tag, rows) and asks the Health tab for the game's
--        panel words; a scratch reads "Scratched", graded Severe from First Aid 3 as vanilla's panel
--   MD4  B with the game's treatment menu up shuts the menu and keeps the card; with no menu, the card's own B runs
-- Run from the repo root:  lua51 ZeDUI/tools/qa/oc_lock_medic_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]oc_lock_medic_sim%.lua$", "")
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"
local LANG = ROOT .. "42/media/lua/shared/Translate/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readFile(p)
    local f = io.open(p, "rb"); if not f then return nil end
    local s = f:read("*a"); f:close(); return (string.gsub(s, "\r\n", "\n"))
end
local function cut(src, head, stop)
    local a = src and src:find(head, 1, true)
    if not a then return nil end
    stop = stop or "\nend\n"
    local _, b = src:find(stop, a, true)
    return b and src:sub(a, b) or nil
end
local function done()
    print(string.format("oc_lock_medic_sim: %d checks, %d failed", checks, failed))
    if failed > 0 then os.exit(1) end
end
local function noop() end
local function has(s, sub) return type(s) == "string" and s:find(sub, 1, true) ~= nil end

-- ---------------------------------------------------------------------------
-- STUBS
-- ---------------------------------------------------------------------------
require = noop
local realPrint = print
print = function(s) if type(s) == "string" and s:sub(1, 5) == "[ZeD]" then return end realPrint(s) end
getText = function(k) return k end
getTextOrNull = function(k) return nil end
getTimestampMs = function() return 1000 end
getDebug = function() return false end
isClient = function() return false end
isMultiplayer = function() return false end
Events = setmetatable({}, { __index = function(t, k) local e = { Add = noop, Remove = noop }; rawset(t, k, e); return e end })
Keyboard = { KEY_BACK = 14 }
for n = 0, 9 do Keyboard["KEY_" .. n] = 100 + n; Keyboard["KEY_NUMPAD" .. n] = 200 + n end
instanceof = function(o, cls) return type(o) == "table" and o._cls == cls end
local QUEUED = {}
ISTimedActionQueue = { getTimedActionQueue = function() return { queue = {} } end,
                       add = function(a) QUEUED[#QUEUED + 1] = a end }
ISPadlockByCodeAction = { new = function(self, p, thump, pad, lock, code)
    return { Type = "ISPadlockByCodeAction", thump = thump, padlock = pad, lock = lock, code = code, perform = noop } end }
luautils = { walkAdj = function() return true end }
local PUT = {}
ISWorldObjectContextMenu = { onPutPadlock = function(_, pn, obj, pad) PUT[#PUT + 1] = pad end, onRemovePadlock = noop }
ISHealthPanel = { cheat = false, IsCharactersInSameCar = function() return false end }
UIManager = { getSpeedControls = function() return nil end }

local color = { r = 1, g = 1, b = 1, a = 1 }
ZeD = {
    tr = function(k, ...)
        local a = { ... }
        if #a == 0 then return k end
        local out = {}
        for i = 1, #a do out[i] = tostring(a[i]) end
        return k .. ":" .. table.concat(out, "|")
    end,
    textCase = function(s) return s end,
    Atoms = { frame = noop, drawStatusDot = noop, drawBody = noop, drawDividerH = noop, drawSecondary = noop,
              wrapText = function(s) return { s } end, textCase = function(s) return s end,
              pctText = function(f) return tostring(math.floor(f * 100)) .. "%" end, statusColor = function() return color end },
    CraftingCore = { truncText = function(s) return s end },
    TM = { getFontHeight = function() return 16 end, MeasureStringX = function(self, f, s) return #tostring(s) * 6 end },
    Focus = { mark = function() return false end },
    partLabel = function(n) return n end,
    Input = { Detector = { getMode = function() return "mouse" end } },
}
ZeD.T = setmetatable({ px = function(u) return u end, sp = setmetatable({}, { __index = function() return 2 end }),
                       fontF1 = 1, fontF2 = 2 }, { __index = function() return color end })
local DEFS = {}
local OC = {
    ui = { hex = function() return { r = 0, g = 0, b = 0 } end, disc = noop, fill = noop, section = function() return 10 end,
           warn = function() return 0 end },
    call = function(o, m, ...) if o and type(o[m]) == "function" then return o[m](o, ...) end return nil end,
    DOT = "-", REFRESH = 15, kinds = {},
    keyOf = function(sq, k) return k end, spriteIcon = noop, armKeys = noop, openNear = noop,
}
OC.register = function(d) DEFS[d.id] = d; OC.kinds[d.id] = d end
ZeD.ObjectCards = OC

-- a card as the host keeps it: the zones the body stamps, its question, its entry
local function newCard(t)
    local c = { zones = {}, playerNum = 0, entry = { t = t } }
    function c:zone(z) self.zones[#self.zones + 1] = z end
    function c:focusOf() return nil end
    function c:drawRect() end
    function c:drawRectBorder() end
    function c:drawText() end
    function c:pointerOver() return false end
    return c
end
local function zoneById(card, fid) for _, z in ipairs(card.zones) do if z.fid == fid then return z end end return nil end

-- ---------------------------------------------------------------------------
-- LK1 / LK4: the lock card
-- ---------------------------------------------------------------------------
local lockSrc = readFile(CLIENT .. "ObjectCardLock.lua")
local lfn, lerr = loadstring(lockSrc or "", "=ObjectCardLock.lua")
check("ObjectCardLock.lua compiles", lfn ~= nil, lerr)
local okL, runL = pcall(lfn or noop)
check("ObjectCardLock.lua runs and registers its card", okL and DEFS.lock ~= nil, runL)
local LKdef = DEFS.lock

local function list(items)
    return { size = function() return #items end, get = function(self, i) return items[i + 1] end }
end
local function inventory(items)
    local inv = {}
    function inv:FindAndReturn(ty) for _, it in ipairs(items) do if it.type == ty then return it end end return nil end
    function inv:getAllType(ty) local o = {}; for _, it in ipairs(items) do if it.type == ty then o[#o + 1] = it end end return list(o) end
    function inv:haveThisKeyId() return nil end
    function inv:getItems() return list(items) end
    return inv
end
local function padlock(keys) return { type = "Padlock", keys = keys, getNumberOfKey = function(self) return self.keys end } end
local COMBO = { type = "CombinationPadlock" }
local SQ = {}
local function crate()
    local o = { _cls = "IsoThumpable", code = 0 }
    function o:getSquare() return SQ end
    function o:getObjectIndex() return 1 end
    function o:getLockedByCode() return self.code end
    function o:isLockedByPadlock() return false end
    function o:canBeLockByPadlock() return true end
    function o:isLockedToCharacter() return false end
    function o:getName() return "Crate" end
    return o
end
local function player(items)
    local inv = inventory(items)
    return { getInventory = function() return inv end, getPlayerNum = function() return 0 end }
end

if LKdef then
    local P = player({ COMBO })
    local obj = crate()
    local t = LKdef.resolve(P, { obj = obj, set = true })
    t.digits = { 3, 1, 9 }
    LKdef.refresh(t, P)
    local v = t.verbs and t.verbs[1]
    check("LK1: the card is in set mode with Lock first", t.d and t.d.mode == "set" and v and v.id == "lock", t.d and t.d.mode)
    check("LK1: the Lock question names the code", v and has(v.confirm, "3 1 9"), v and v.confirm)
    -- the host's press: the question keeps the verb's words and run, then the body draws under it
    local card = newCard(t)
    LKdef.body(card, 0, 0, 200, t, P)
    card._confirm = { text = v.confirm, run = v.run }
    card.zones = {}
    LKdef.body(card, 0, 0, 200, t, P)
    local w3 = zoneById(card, "lk:wheel:3")
    local up1 = zoneById(card, "lk:up:1")
    local dn2 = zoneById(card, "lk:dn:2")
    check("LK1: the wheels and chevrons are drawn as zones", w3 and up1 and dn2)
    if w3 and w3.wheel then w3.wheel(-1); w3.wheel(-1) end
    if up1 and up1.run then up1.run(card) end
    if dn2 and dn2.run then dn2.run(card) end
    check("LK1: while the question asks, the mouse wheel and the chevrons turn nothing",
        t.digits[1] == 3 and t.digits[2] == 1 and t.digits[3] == 9, table.concat(t.digits, " "))
    local took = LKdef.onKey(t, Keyboard.KEY_7, card, false)
    LKdef.onKey(t, Keyboard.KEY_7, card, true)
    LKdef.onKey(t, Keyboard.KEY_BACK, card, true)
    check("LK1: ... the number keys are taken (not the hotbar's) but type nothing", took == true
        and t.digits[1] == 3 and t.digits[2] == 1 and t.digits[3] == 9, table.concat(t.digits, " "))
    check("LK1: ... the pad's grab cannot turn a wheel", w3 and w3.canTurn and w3.canTurn() == false)
    -- the dial moved anyway (another path): Yes still locks with the code the question named
    t.digits = { 3, 7, 0 }
    QUEUED = {}
    card._confirm.run(P, t)
    local act = QUEUED[1]
    check("LK1: Yes locks with exactly the code the question named", act and act.code == 319 and act.lock == true, act and act.code)
    -- no question: the dial turns again
    card._confirm = nil
    t.digits = { 3, 1, 9 }
    if w3 and w3.wheel then w3.wheel(-1) end
    check("LK1: with no question the mouse wheel turns the wheel", t.digits[3] == 0, table.concat(t.digits, " "))
    check("LK1: ... and the pad's grab may turn it", w3 and w3.canTurn and w3.canTurn() == true)
    LKdef.refresh(t, P)
    check("LK1: a turn makes the question again with the new code", has(t.verbs[1].confirm, "3 1 0"), t.verbs[1].confirm)

    -- LK4: two key padlocks, the first keyless
    local good = padlock(1)
    local P2 = player({ padlock(0), good })
    local t2 = LKdef.resolve(P2, crate())
    LKdef.refresh(t2, P2)
    local use = t2.verbs and t2.verbs[2]
    check("LK4: two key padlocks, the first keyless: Use padlock is offered", use and use.id == "usepad" and use.enabled == true,
        use and tostring(use.enabled))
    PUT = {}
    if use and use.enabled then use.run(P2, t2) end
    check("LK4: ... and puts on the one with its keys", PUT[1] == good)
    local P3 = player({ padlock(0) })
    local t3 = LKdef.resolve(P3, crate())
    LKdef.refresh(t3, P3)
    check("LK4: a keyless padlock alone offers none", t3.verbs[2].enabled == false)
end

-- the words in every language: the main inventory, and the question's code
do
    local en = readFile(LANG .. "EN/UI.json") or ""
    local function val(src, k) return src:match('"' .. k .. '":%s*"(.-)",?\n') end
    check("LK4: the English NEEDS words say the main inventory",
        has(val(en, "UI_ZeD_Lock_NeedsCombo"), "main inventory") and has(val(en, "UI_ZeD_Lock_NeedsKeyPad"), "main inventory"),
        val(en, "UI_ZeD_Lock_NeedsCombo"))
    local langs = { "AR", "CA", "CH", "CN", "CS", "DA", "DE", "EN", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT",
                    "JP", "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
    local missing = {}
    for _, l in ipairs(langs) do
        local s = readFile(LANG .. l .. "/UI.json") or ""
        local q = val(s, "UI_ZeD_Lock_QLock")
        if not has(q, "%1") then missing[#missing + 1] = l end
        if has(val(s, "UI_ZeD_Lock_NeedsCombo"), val(en, "UI_ZeD_Lock_NeedsCombo") or "?") and l ~= "EN" then missing[#missing + 1] = l .. "(en)" end
    end
    check("LK1: every language's Lock question names the code (%1)", #missing == 0, table.concat(missing, ","))
end

-- ---------------------------------------------------------------------------
-- OC7: the World window's openObjectCard keeps the Loot columns
-- ---------------------------------------------------------------------------
do
    local ww = readFile(CLIENT .. "ZeD_WorldWindow.lua")
    local body = cut(ww, "function ZeD_WorldWindow.openObjectCard(playerNum, entry)")
    check("OC7: openObjectCard is found", body ~= nil)
    if body then
        local exited = 0
        local win = { _mcSelected = { 2, 3 }, _mainContent = { _selectedItems = { a = true } }, _objectCard = { setEntry = noop } }
        local fn, e = loadstring("local _worldWins, exitWorldMC = ...\nZeD_WorldWindow = ZeD_WorldWindow or {}\n" .. body, "openObjectCard")
        check("OC7: openObjectCard compiles", fn ~= nil, e)
        if fn then
            ZeD.windowsFor = function() return true end
            fn({ [0] = win }, function(w, c) exited = exited + 1; w._mcSelected = {} end)
            local ok = ZeD_WorldWindow.openObjectCard(0, { def = {}, t = {} })
            check("OC7: the card opens", ok == true and win._drawerObject ~= nil)
            check("OC7: his two extra Loot columns stay", exited == 0 and #win._mcSelected == 2, #win._mcSelected)
            local left = 0
            for _ in pairs(win._mainContent._selectedItems) do left = left + 1 end
            check("OC7: ... the item selection still clears", left == 0, left)
        end
    end
end

-- ---------------------------------------------------------------------------
-- MD2 / MD4: the medic card
-- ---------------------------------------------------------------------------
local GATHER = {}
local FH = 16
local DRAWN = {}
ZeD.Atoms.drawTextRight = function(card, s) DRAWN[#DRAWN + 1] = s end
ZeD.HealthTab = {
    gatherData = function(p, opts)
        GATHER[#GATHER + 1] = opts
        local e = { name = "Left Hand", figure = "Left Hand", bodyPart = {}, health = 61, worstSev = "warning", conditions = {} }
        return { entries = { e }, overall = 80, partHealth = { ["Left Hand"] = 61 }, partByFigure = {},
                 hideNumbers = (opts and opts.hideNumbers) and true or nil }
    end,
    drawOverall = function(p, x, y) return y + FH end,
    drawSummary = function(p, d, x, y) return y + FH end,
    tagHang = function() return 0 end,
    condTags = function() return 0 end,
    sevColor = function() return color end,
    tintPart = noop,
    treat = noop,
    _renderDetailView = function(p, w, d, part, rx, ry) return ry end,
}
ZeD.Molecules = { figureFrame = function(x, y, w) return { two = true, frameX = x, frameY = y, frameW = 100, frameH = 200,
                  figX = x, figY = y, figW = 100, figH = 200, rightX = x + 110, rightY = y, rightW = w - 110 } end,
                  drawFigureFrame = noop }
ZeD_BodyFigure = { new = function()
    local f = {}
    for _, m in ipairs({ "initialise", "loadTextures", "setSex", "setSkinTone", "setPartWounds", "drawChart", "drawAt" }) do f[m] = noop end
    function f:getPartRects() return {} end
    return f
end }
Perks = { Doctor = "Doctor" }
local medicSrc = readFile(CLIENT .. "ObjectCardMedic.lua")
local mfn, merr = loadstring(medicSrc or "", "=ObjectCardMedic.lua")
check("ObjectCardMedic.lua compiles", mfn ~= nil, merr)
local okM, runM = pcall(mfn or noop)
check("ObjectCardMedic.lua runs and registers its card", okM and DEFS.medic ~= nil, runM)
local MDdef = DEFS.medic
if MDdef then
    local function body(isLocal)
        return { getBodyParts = noop }
    end
    local patient = { getBodyDamage = function() return body() end, isLocalPlayer = function() return true end,
                      getMoodles = function() return { getMoodleLevel = function() return 0 end } end }
    local doctor = { getPlayerNum = function() return 0 end }
    local t = { doctor = doctor, patient = patient, level = 0, fakeWin = {} }
    ISHealthPanel.cheat = false
    GATHER = {}
    MDdef.refresh(t, doctor)
    local o = GATHER[1] or {}
    check("MD2: the card asks for the game panel's words", o.panelWords == true)
    check("MD2: outside cheat mode it asks for no numbers", o.hideNumbers == true)
    check("MD2: outside cheat mode the header has no percent tag", MDdef.pill(t) == nil, tostring(MDdef.pill(t)))
    DRAWN = {}
    local card = newCard(t)
    MDdef.body(card, 0, 0, 460, t, doctor)
    local pct = 0
    for _, s in ipairs(DRAWN) do if has(s, "%") then pct = pct + 1 end end
    check("MD2: ... and no row draws its part's percent", pct == 0, pct)
    ISHealthPanel.cheat = true
    GATHER = {}
    MDdef.refresh(t, doctor)
    check("MD2: in cheat mode the numbers come back, as vanilla's", GATHER[1] and not GATHER[1].hideNumbers and MDdef.pill(t) ~= nil)
    ISHealthPanel.cheat = false

    -- MD4
    check("MD4: the card has its own B (def.onCancel)", type(MDdef.onCancel) == "function")
    if type(MDdef.onCancel) == "function" then
        local ctx = { vis = true }
        function ctx:getIsVisible() return self.vis end
        function ctx:setVisible(v) self.vis = v end
        function ctx:hideAndChildren() self.vis = false end
        t.menu = ctx
        check("MD4: B with the treatment menu up spends the B", MDdef.onCancel(t, card) == true)
        check("MD4: ... and shuts the menu", ctx.vis == false)
        check("MD4: a second B leaves it to the card (it closes)", MDdef.onCancel(t, card) == false)
    end
end

-- the host's pad stops: a kind's B first, else the card's own
do
    local src = readFile(CLIENT .. "ObjectCards.lua")
    local body = cut(src, "function ZeD_ObjectCard:buildFocusables(win)")
    check("MD4: the host's buildFocusables is found", body ~= nil)
    if body then
        local fn, e = loadstring("local ZeD_ObjectCard = ...\n" .. body, "buildFocusables")
        check("MD4: buildFocusables compiles", fn ~= nil, e)
        if fn then
            local C = {}
            fn(C)
            local closed = 0
            local kindB = true
            local card = { entry = { def = { onCancel = function() return kindB end }, t = {} }, _zones = { { fid = "mc:part:Left Hand" } },
                           _off = 0, close = function() closed = closed + 1 end, player = noop }
            local els = C.buildFocusables(card, {})
            local el = els[1]
            local r = el and el.onCancel({}, el)
            check("MD4: the host lets the kind spend B (the card stays)", r == true and closed == 0, closed)
            kindB = false
            if el then el.onCancel({}, el) end
            check("MD4: ... and closes the card when the kind does not", closed == 1, closed)
        end
    end
end

-- ---------------------------------------------------------------------------
-- MD2: the Health tab's wound words for a doctor (cut from HealthTab.lua)
-- ---------------------------------------------------------------------------
do
    local src = readFile(CLIENT .. "HealthTab.lua")
    local q = cut(src, "local function qualify(label, word)")
    local a = src and src:find("local SEEN = {}", 1, true)
    local cc = a and cut(src:sub(a), "local function classifyConditions(")
    check("MD2: the Health tab's classifier is found", q and cc)
    if q and cc then
        local fn, e = loadstring("local SEV_ORDER = {}\n" .. q .. "\nlocal SEEN = {}\n"
            .. ("-- panelWords\n" .. cc) .. "\nreturn classifyConditions\n", "classify")
        check("MD2: the classifier compiles", fn ~= nil, e)
        local classify = fn and fn()
        local function part(scratchT)
            local bp = {}
            local zero = function() return 0 end
            local no = function() return false end
            for _, m in ipairs({ "getFractureTime", "getSplintFactor", "getDeepWoundTime", "getWoundInfectionLevel", "getCutTime",
                                 "getBurnTime", "getStiffness", "getAdditionalPain", "getBandageLife", "getStitchTime",
                                 "getPlantainFactor", "getComfreyFactor", "getGarlicFactor" }) do bp[m] = zero end
            for _, m in ipairs({ "bandaged", "bitten", "bleeding", "deepWounded", "isInfectedWound", "haveBullet", "haveGlass",
                                 "isCut", "stitched", "isNeedBurnWash" }) do bp[m] = no end
            bp.scratched = function() return true end
            bp.getScratchTime = function() return scratchT end
            return bp
        end
        if classify then
            local okC, conds = pcall(classify, part(18), 3, true)
            local lab = okC and conds and conds[1] and conds[1].label
            check("MD2: a doctor's scratch reads in the game panel's word (Scratched)", has(lab, "IGUI_health_Scratched"), lab or conds)
            check("MD2: ... graded Severe at First Aid 3, as vanilla's panel", has(lab, "IGUI_health_Severe"), lab)
            local _, c0 = pcall(classify, part(18), 0, true)
            local l0 = c0 and c0[1] and c0[1].label
            check("MD2: ... and ungraded at First Aid 0", has(l0, "IGUI_health_Scratched") and not has(l0, "IGUI_health_Severe"), l0)
            local _, cOwn = pcall(classify, part(18), 3, nil)
            local lOwn = cOwn and cOwn[1] and cOwn[1].label
            check("MD2: the Health tab's own word stays (Scratch)", lOwn == "IGUI_health_Scratch" or has(lOwn, "IGUI_health_Scratch|"), lOwn)
        end
    end
end

done()
