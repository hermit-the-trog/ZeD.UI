-- ZeDUI/tools/qa/everyday_leftovers_sim.lua  (Nov 7 2026, Build): the everyday vanilla windows of
-- docs/reference/VANILLA_WINDOWS_20261107.md section B, with no game running. The real ZeD files run on Lua 5.1 with a
-- forgiving stand-in for everything else (a global or field nobody set is a stand-in that takes any call), and
-- small fakes of the game's objects each section needs.
--   B6  HEATER   ZeD_Dashboard.heater turns the heater on (the key in) or off, keeps the temperature, says the game's
--                "needs the key" when it cannot, lights the dash's climate controls, hands a driver's pad to the dash;
--                declines when ZeD's dash is the game's (its switch), so Overrides/Heater.lua opens the game's window
--   B7  MINIMAP  the World wheel's Map wheel has no mini-map slices (World map alone, Back after it), and ZeD's
--                wheels leave the game's mini-map commands out (ZeD.Wheel.isMiniMapCommand)
--   B8  LABEL    a CD's label in the reader: its words as paragraphs, who made it, the recording's name; the carried
--                CD found again by its label; Overrides/MediaLabel.lua sends ISMediaInfo.openPanel there (the
--                game's window in safe mode)
--   B9  MAKEUP   the make-up rows (ZeD_MakeUp.rows): the spots the carried make-up can do by the game's categories,
--                the worn under Remove, the game's mirror rule; Apply queues the game's ISApplyMakeUp, Remove takes it
--                off; the hair section's parts (Hair, Beard, Make Up), the figures' make-up; Overrides/MakeUp.lua
--   B12 B13 PADS a controller's join list and its "disconnected" banner become notes in Messages with the game's
--                choices as buttons (Overrides/Controllers.lua); one note per controller; safe mode keeps the game's
--   NOTICES      ZeD's notices as balloons out of the Messages note (ZeD_Bubbles.layoutNoticeBalloons): inside the
--                screen at Deck and 720p widths, the newest lowest over the note, the tail's base under its balloon
--   B14 PAUSED   ZeD_PausedLook: the Character window's actions held while paused, the tab strip and bags free; the
--                glass over the tab and the list while paused, gone when the game plays
--   B15 STATION  ST.classify: any craft machine is a machine; the open route makes anything else a general station;
--                StationGeneral reads its logic, resources and what the bags hold, and its Start / Take / Add run
--                the game's own actions
-- Every section checks what the old code could not do, so it fails on the code before this work.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/everyday_leftovers_sim.lua
-- It prints FAIL lines and a last line "everyday_leftovers_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]everyday_leftovers_sim%.lua$", "")
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

-- ---------------------------------------------------------------------------
-- THE FORGIVING WORLD: any global or field nobody set is a stand-in that takes any call and any index
-- ---------------------------------------------------------------------------
local autoMT = {}
local function auto() return setmetatable({}, autoMT) end
autoMT.__index = function(t, k) return auto() end
autoMT.__call = function() return auto() end
autoMT.__concat = function(a, b) return "" end
autoMT.__unm = function() return 0 end
for _, m in ipairs({ "__add", "__sub", "__mul", "__div", "__mod", "__pow" }) do autoMT[m] = function() return 0 end end
local function isAuto(v) return type(v) == "table" and getmetatable(v) == autoMT end
setmetatable(_G, { __index = function(t, k)
    if k == "arg" then return nil end
    local s = auto(); rawset(t, k, s); return s
end })

local clock = 1000000
function getTimestampMs() return clock end
function getText(k, a, b) if a then return k .. "(" .. tostring(a) .. (b and ("," .. tostring(b)) or "") .. ")" end return k end
function getTextOrNull(k) return nil end
function instanceof(o, cls) return type(o) == "table" and o._class == cls end
function require() return true end
function isClient() return false end
function getDebug() return false end
local SPEED = 1
function getGameSpeed() return SPEED end
local SENT = {}
function sendClientCommand(chr, mod, cmd, args) SENT[#SENT + 1] = { mod = mod, cmd = cmd, args = args } end
local QUEUE = {}
ISTimedActionQueue = { add = function(a) QUEUE[#QUEUE + 1] = a end, hasActionType = function() return false end,
                       hasAction = function() return false end, clear = function() end }
local HALO = {}
HaloTextHelper = { addBadText = function(p, t) HALO[#HALO + 1] = t end, addGoodText = function() end }
JoypadState = { players = {}, controllers = {}, joypads = {} }
Joypad = { AButton = 1, BButton = 2, XButton = 3, YButton = 4 }
UIFont = { Small = "small" }
function triggerEvent() end

ZeD = setmetatable({}, { __index = function(t, k) return auto() end })   -- (a ZeD part not loaded here: a stand-in)
local SAFE = {}
ZeD.Safe = { on = function(name) return SAFE[name or "all"] or SAFE.all or false end, register = function() end,
             guard = function() end, trip = function() end }
function ZeD.tr(k, a, b) if a ~= nil then return k .. "(" .. tostring(a) .. (b ~= nil and ("," .. tostring(b)) or "") .. ")" end return k end
function ZeD.logOnce(where, err) print("logOnce " .. tostring(where) .. ": " .. tostring(err)) end
function ZeD.textCase(s) return s end
function ZeD.upper(s) return string.upper(s) end

local function loadZ(path)
    local f, err = loadfile(CLIENT .. path)
    if not f then return false, err end
    return pcall(f)
end

-- ===========================================================================
section("B7 MINIMAP: the Map wheel and ZeD's wheels")
-- ===========================================================================
do
    ZeD.Wheel = {}
    ZeD.DpadWheels = {}
    ISWorldMap = { IsAllowed = function() return true end, ToggleWorldMap = function() end }
    ISMiniMap = { ToggleMiniMap = function() end, FocusMiniMap = function() end }
    function getPlayerMiniMap() return {} end   -- (a mini-map exists in this game: the old wheel offered it)
    local okW, errW = loadZ("ZeD_Wheel.lua")
    check("ZeD_Wheel.lua loads", okW, errW)
    local okD, errD = loadZ("ZeD_DpadWheels.lua")
    check("ZeD_DpadWheels.lua loads", okD, errD)
    local Wd = ZeD.DpadWheels.Wd
    local list = (Wd and Wd.map) and Wd.map({}, 0) or {}
    check("the Map wheel holds the World map alone", #list == 1, #list)
    check("its slice is the World map", list[1] and list[1].name == "IGUI_WorldMap_Toggle", list[1] and list[1].name)
    for _, e in ipairs(list) do
        check("no mini-map slice (" .. tostring(e.name) .. ")", e.name ~= "IGUI_MiniMap_Toggle" and e.name ~= "IGUI_MiniMap_Focus")
    end
    local W = ZeD.Wheel
    check("ZeD.Wheel.isMiniMapCommand exists", type(W.isMiniMapCommand) == "function")
    if type(W.isMiniMapCommand) == "function" then
        check("the toggle is a mini-map command", W.isMiniMapCommand(ISMiniMap.ToggleMiniMap))
        check("the focus is a mini-map command", W.isMiniMapCommand(ISMiniMap.FocusMiniMap))
        check("the world map is not", not W.isMiniMapCommand(ISWorldMap.ToggleWorldMap))
        check("no command is not", not W.isMiniMapCommand(nil))
    end
    -- the radial's addSlice drops the game's mini-map slices when ZeD draws the wheel
    local src = io.open(CLIENT .. "Overrides/Wheels.lua"):read("*a")
    check("Overrides/Wheels.lua's addSlice asks isMiniMapCommand", src:find("W.isMiniMapCommand(command)", 1, true) ~= nil)
end

-- ===========================================================================
section("B6 HEATER: the key and the slice go to the dash")
-- ===========================================================================
do
    ZeD.Dashboard = {}
    ZeD.DashPx = { w = 800, h = 172 }
    local okD, errD = loadZ("ZeD_Dashboard.lua")
    check("ZeD_Dashboard.lua loads", okD, errD)
    local D = ZeD.Dashboard
    check("ZeD.Dashboard.heater exists", type(D.heater) == "function")
    -- a car with a heater; a driver
    local heater = { md = { active = false, temperature = 15 } }
    function heater:getModData() return self.md end
    local car = { running = false, keys = true, driverIs = nil }
    function car:getPartById(id) if id == "Heater" then return heater end return nil end
    function car:isEngineRunning() return self.running end
    function car:isKeysInIgnition() return self.keys end
    function car:isDriver(c) return c == self.driverIs end
    local p = { _class = "IsoPlayer", pn = 0 }
    function p:getVehicle() return car end
    function p:getPlayerNum() return self.pn end
    function p:playSound() end
    function p:isLocalPlayer() return true end
    car.driverIs = p
    local claimed = 0
    local inst = { vehicle = car, playerNum = 0 }
    function inst:isVisible() return true end
    function inst:_claim() claimed = claimed + 1 end
    D._instance = inst
    if type(D.heater) == "function" then
        SENT = {}
        local ok, r = pcall(D.heater, p)
        check("off, the key in: handled", ok and r == true, r)
        check("off, the key in: the heater goes on", SENT[1] and SENT[1].cmd == "toggleHeater" and SENT[1].args.on == true, SENT[1] and tostring(SENT[1].args.on))
        check("off, the key in: its temperature kept", SENT[1] and SENT[1].args.temp == 15, SENT[1] and SENT[1].args.temp)
        check("the climate controls lit", inst._climateUntil and inst._climateUntil > clock)
        check("no pad: the dash does not take it", claimed == 0)
        heater.md.active = true
        SENT = {}
        pcall(D.heater, p)
        check("on: the heater goes off", SENT[1] and SENT[1].args.on == false)
        heater.md.active = false
        car.keys, car.running = false, false
        SENT, HALO = {}, {}
        pcall(D.heater, p)
        check("no key, engine off: nothing sent", #SENT == 0, #SENT)
        check("no key: the game's own words over the head", HALO[1] == "UI_Vehicle_HeaterNeedKey", HALO[1])
        car.keys = true
        JoypadState.players[1] = {}
        pcall(D.heater, p)
        check("a driver on a pad: the dash takes it", claimed == 1, claimed)
        check("... on the climate controls", type(inst._wantFocus) == "table" and inst._wantFocus[1] == "heat")
        JoypadState.players[1] = nil
        claimed = 0
        car.driverIs = nil   -- a passenger
        JoypadState.players[1] = {}
        pcall(D.heater, p)
        check("a passenger on a pad: the dash stays read-only", claimed == 0)
        JoypadState.players[1] = nil
        car.driverIs = p
        SAFE.dashboard = true
        local ok2, r2 = pcall(D.heater, p)
        check("ZeD's dash given back to the game: declines", ok2 and r2 == false, r2)
        SAFE.dashboard = nil
        heater.none = true
        local saved = car.getPartById
        car.getPartById = function() return nil end
        local ok3, r3 = pcall(D.heater, p)
        check("no heater part: declines", ok3 and r3 == false)
        car.getPartById = saved
    end
    -- the hook: the key and the slice
    local vanillaCalls = 0
    ISVehicleMenu = { onToggleHeater = function() vanillaCalls = vanillaCalls + 1 end }
    local okH, errH = loadZ("Overrides/Heater.lua")
    check("Overrides/Heater.lua loads", okH, errH)
    check("onToggleHeater is wrapped", ISVehicleMenu._zedHeater ~= nil)
    local handled = 0
    local realHeater = D.heater
    D.heater = function() handled = handled + 1; return true end
    ISVehicleMenu.onToggleHeater(p)
    check("the key: ZeD's dash, not the game's window", handled == 1 and vanillaCalls == 0, vanillaCalls)
    D.heater = function() return false end
    ISVehicleMenu.onToggleHeater(p)
    check("the dash declines: the game's window", vanillaCalls == 1, vanillaCalls)
    D.heater = function() error("boom") end
    ISVehicleMenu.onToggleHeater(p)
    check("the dash fails: the game's window", vanillaCalls == 2, vanillaCalls)
    SAFE.dashboard = true
    D.heater = function() handled = handled + 1; return true end
    ISVehicleMenu.onToggleHeater(p)
    check("the dash switch on the game's: the game's window", vanillaCalls == 3)
    SAFE.dashboard = nil
    D.heater = realHeater
end

-- ===========================================================================
section("B8 LABEL: a CD's label in the reader")
-- ===========================================================================
do
    ZeD.Reader = {}
    ZeD.Print = {}
    local okR, errR = loadZ("ZeD_Reader.lua")
    check("ZeD_Reader.lua loads", okR, errR)
    local R = ZeD.Reader
    check("R.labelWords exists", type(R.labelWords) == "function")
    local md = { getTranslatedExtra = function() return "Released February 1993. <LINE> Potassium Records." end,
                 getTranslatedAuthor = function() return "Wilfred" end,
                 getTranslatedItemDisplayName = function() return "Your smile. Your kiss." end }
    local cd = { getMediaData = function() return md end, getDisplayName = function() return "CD: Your smile" end }
    local junk = { getMediaData = function() return nil end, getDisplayName = function() return "Spoon" end }
    local bagInv = { getItems = function() return { size = function() return 1 end, get = function() return cd end } end }
    local bag = { _class = "InventoryContainer", getMediaData = function() return nil end, getInventory = function() return bagInv end }
    local inv = { getItems = function() local l = { junk, bag }; return { size = function() return #l end, get = function(_, i) return l[i + 1] end } end }
    local p = { getInventory = function() return inv end, getPlayerNum = function() return 0 end }
    if type(R.labelWords) == "function" then
        local b = R.labelWords("Released February 1993. <LINE> Potassium Records.", cd)
        check("who made it, first", b[1] and b[1].kind == "kicker" and b[1].text == "Wilfred", b[1] and b[1].text)
        check("the label's two lines as two paragraphs", #b == 3 and b[2].text == "Released February 1993." and b[3].text == "Potassium Records.", #b)
        check("no markup left", not (b[2] and b[2].text:find("<", 1, true)))
        local b2 = R.labelWords("", nil)
        check("an empty label: no paragraphs", #b2 == 0, #b2)
        check("the head: the item's name", R.labelTitle(cd) == "CD: Your smile")
        check("no item: the game's Read label", R.labelTitle(nil) == "IGUI_media_readLabel")
        check("the carried CD found by its label, in a bag", R.labelItem(p, "Released February 1993. <LINE> Potassium Records.") == cd)
        check("a label nobody carries: none", R.labelItem(p, "nope") == nil)
    end
    -- the hook
    local vanilla = 0
    ISMediaInfo = { openPanel = function() vanilla = vanilla + 1 end }
    local opened = {}
    local okM, errM = loadZ("Overrides/MediaLabel.lua")
    check("Overrides/MediaLabel.lua loads", okM, errM)
    local realOpen = R.openLabel
    R.openLabel = function(pl, text) opened[#opened + 1] = text; return true end
    function getSpecificPlayer() return p end
    ISMediaInfo.openPanel(0, "Released")
    check("Read label opens ZeD's reader", opened[1] == "Released" and vanilla == 0, vanilla)
    SAFE.all = true
    ISMediaInfo.openPanel(0, "Released")
    check("safe mode: the game's window", vanilla == 1)
    SAFE.all = nil
    R.openLabel = function() return false end
    ISMediaInfo.openPanel(0, "x")
    check("the reader declines: the game's window", vanilla == 2)
    R.openLabel = realOpen
end

-- ===========================================================================
section("B9 MAKEUP: with the hair")
-- ===========================================================================
do
    ZeD.MakeUp = {}
    MakeUpDefinitions = { makeup = {
        { name = "FullFaceCamo1", category = "FullFace", item = "Base.MakeUp_CamoFullFace1", makeuptypes = { FacePaint = true } },
        { name = "Lipstick1", category = "Lips", item = "Base.MakeUp_Lips1", makeuptypes = { Lipstick = true } },
        { name = "EyesShadow1", category = "EyesShadow", item = "Base.MakeUp_EyesShadow1", makeuptypes = { Eyeshadow = true } },
    } }
    local okM, errM = loadZ("ZeD_MakeUp.lua")
    check("ZeD_MakeUp.lua loads", okM, errM)
    local MU = ZeD.MakeUp
    local function item(ft, mtype, name)
        return { ft = ft, getFullType = function() return ft end, getMakeUpType = function() return mtype end,
                 getDisplayName = function() return name end, getCurrentUses = function() return 3 end }
    end
    local lipstick = item("Base.Lipstick", "Lipstick", "Lipstick")
    local wornCamo = item("Base.MakeUp_CamoFullFace1", nil, "Camo")
    local invItems = { lipstick }
    local removed = {}
    local inv = { getItems = function() return { size = function() return #invItems end, get = function(_, i) return invItems[i + 1] end } end,
                  Remove = function(_, it) removed[#removed + 1] = it end,
                  containsRecursive = function(_, it) for _, x in ipairs(invItems) do if x == it then return true end end return false end }
    local worn = { wornCamo }
    local wornObj = { size = function() return #worn end, getItemByIndex = function(_, i) return worn[i + 1] end }
    local wornOff = {}
    local p = { getInventory = function() return inv end, getWornItems = function() return wornObj end,
                removeWornItem = function(_, it) wornOff[#wornOff + 1] = it end, getPlayerNum = function() return 0 end }
    local mirror = true
    ISInventoryPaneContextMenu = { doMakeUpMenu = function(ctx, makeup, pl)
        local o = ctx:addOption("IGUI_MakeUp", makeup, nil, pl)
        if not mirror then o.notAvailable = true; o.toolTip = { description = "Tooltip_NeedMirror" } end
    end }
    ISApplyMakeUp = { new = function(_, pl, it, ft) return { kind = "apply", pl = pl, it = it, ft = ft } end }
    if type(MU.rows) == "function" then
        local rows = MU.rows(p)
        local byKey = {}
        for _, r in ipairs(rows) do byKey[r.key] = r end
        local lips = byKey["m:a:Base.MakeUp_Lips1"]
        check("the lipstick's spot: Lips", lips and lips.grp == "Lips" and lips.verb == "Apply", lips and lips.grp)
        check("its words: the game's make-up name", lips and lips.label == "MakeUpType_Lipstick1")
        check("its tool: the lipstick carried", lips and lips.tool == "Lipstick")
        check("no spot the carried make-up cannot do", byKey["m:a:Base.MakeUp_EyesShadow1"] == nil)
        local off = byKey["m:r:Base.MakeUp_CamoFullFace1"]
        check("the worn camo under Remove", off and off.grp == "Remove" and off.verb == "Remove" and off.instant)
        check("the worn camo is not offered again", byKey["m:a:Base.MakeUp_CamoFullFace1"] == nil)
        check("a mirror: both can be done", lips and lips.ok and off and off.ok)
        QUEUE = {}
        lips.run(p)
        check("Apply: the game's ISApplyMakeUp", QUEUE[1] and QUEUE[1].kind == "apply" and QUEUE[1].it == lipstick and QUEUE[1].ft == "Base.MakeUp_Lips1")
        off.run(p)
        check("Remove: off the character and out of the bag", wornOff[1] == wornCamo and removed[1] == wornCamo)
        check("the figure wears the row's make-up", lips.mk and lips.mk.wear == "Base.MakeUp_Lips1" and off.mk and off.mk.off == "Base.MakeUp_CamoFullFace1")
        mirror = false
        local rows2 = MU.rows(p)
        check("no mirror: greyed with the game's reason", rows2[1] and rows2[1].ok == false and rows2[1].reason == "Tooltip_NeedMirror", rows2[1] and rows2[1].reason)
        mirror = true
        -- the make-up the Make Up option came from, asked again: dropped, it is no longer the tool
        local lip2 = item("Base.Lipstick", "Lipstick", "Red lipstick")
        local byPref = {}
        for _, r in ipairs(MU.rows(p, lip2)) do byPref[r.key] = r end
        check("a picked item no longer carried is not the tool", byPref["m:a:Base.MakeUp_Lips1"] and byPref["m:a:Base.MakeUp_Lips1"].toolItem == lipstick)
        invItems[#invItems + 1] = lip2
        byPref = {}
        for _, r in ipairs(MU.rows(p, lip2)) do byPref[r.key] = r end
        check("carried, the picked item comes first", byPref["m:a:Base.MakeUp_Lips1"] and byPref["m:a:Base.MakeUp_Lips1"].toolItem == lip2)
        lip2.getCurrentUses = function() return 0 end
        byPref = {}
        for _, r in ipairs(MU.rows(p, lip2)) do byPref[r.key] = r end
        check("used up, the picked item is not the tool", byPref["m:a:Base.MakeUp_Lips1"] and byPref["m:a:Base.MakeUp_Lips1"].toolItem == lipstick)
        -- a row made with an item that went before Apply applies nothing
        local stale = byPref["m:a:Base.MakeUp_Lips1"]
        table.remove(invItems, 1)
        QUEUE = {}
        stale.run(p)
        check("an item gone since the rows were made: nothing queued", #QUEUE == 0)
        table.insert(invItems, 1, lipstick)
        table.remove(invItems)
        check("relevant while carried or worn", MU.relevant(p))
        invItems, worn = {}, {}
        check("nothing carried or worn: no make-up part", not MU.relevant(p))
        invItems, worn = { lipstick }, { wornCamo }
    end
    -- the hair section: its parts and its figures
    ZeD.HairBeard = {}
    ZeD.Disclose = {}
    local okH, errH = loadZ("ZeD_HairBeard.lua")
    check("ZeD_HairBeard.lua loads", okH, errH)
    local HB = ZeD.HairBeard
    check("HB.partsOf exists", type(HB.partsOf) == "function")
    if type(HB.partsOf) == "function" then
        local function eq(a, b) return table.concat(a, ",") == table.concat(b, ",") end
        check("a man without make-up: Hair, Beard", eq(HB.partsOf({ female = false }), { "hair", "beard" }))
        check("a man with make-up: Hair, Beard, Make Up", eq(HB.partsOf({ female = false, hasMakeUp = true }), { "hair", "beard", "makeup" }))
        check("a woman with make-up: Hair, Make Up", eq(HB.partsOf({ female = true, hasMakeUp = true }), { "hair", "makeup" }))
    end
    if type(HB.dressMakeUp) == "function" then
        local slots = {}
        local wornD = { setItem = function(_, loc, it) slots[loc] = it end, getItem = function(_, loc) return slots[loc] end,
                        remove = function(_, it) for k, v in pairs(slots) do if v == it then slots[k] = nil end end end,
                        size = function() local n = 0; for _ in pairs(slots) do n = n + 1 end; return n end,
                        getItemByIndex = function(_, i) local n = 0; for _, v in pairs(slots) do if n == i then return v end; n = n + 1 end end,
                        getLocation = function(_, it) for k, v in pairs(slots) do if v == it then return k end end end }
        local desc = { getWornItems = function() return wornD end }
        local preview = { getBodyLocation = function() return "MakeUp_Lips" end, getFullType = function() return "Base.MakeUp_Lips1" end }
        local old = { getFullType = function() return "Base.MakeUp_Lips2" end }
        slots.MakeUp_Lips = old
        MU.previewItem = function() return preview end
        local undo = HB.dressMakeUp(desc, { wear = "Base.MakeUp_Lips1" })
        check("a row's figure wears the row's make-up", slots.MakeUp_Lips == preview)
        if undo then undo() end
        check("... and only that figure: the stand-in put back", slots.MakeUp_Lips == old)
        local undo2 = HB.dressMakeUp(desc, { off = "Base.MakeUp_Lips2" })
        check("a Remove row's figure without it", slots.MakeUp_Lips == nil)
        if undo2 then undo2() end
        check("... put back after", slots.MakeUp_Lips == old)
    else
        check("HB.dressMakeUp exists", false)
    end
    -- the make-up item's Make Up option
    local vanilla = 0
    ISInventoryPaneContextMenu.onMakeUp = function() vanilla = vanilla + 1 end
    local okO, errO = loadZ("Overrides/MakeUp.lua")
    check("Overrides/MakeUp.lua loads", okO, errO)
    local opened = 0
    local realOpen = MU.open
    MU.open = function() opened = opened + 1; return true end
    ISInventoryPaneContextMenu.onMakeUp(lipstick, p)
    check("Make Up opens the hair section, not the game's window", opened == 1 and vanilla == 0, vanilla)
    SAFE.windows = true
    ISInventoryPaneContextMenu.onMakeUp(lipstick, p)
    check("ZeD's windows given back: the game's window", vanilla == 1)
    SAFE.windows = nil
    MU.open = realOpen
end

-- ===========================================================================
section("NOTICES: balloons out of the Messages note")
-- ===========================================================================
do
    ZeD.Bubbles = {}
    ZeD.Px = { textWidth = function(s) return #tostring(s) * 6 end, k = function() return 1 end,
               rect = function() end, rects = function() end, text = function() end }
    ZeD.PixelFonts = {}
    local okB, errB = loadZ("ZeD_Bubbles.lua")
    check("ZeD_Bubbles.lua loads", okB, errB)
    local B = ZeD.Bubbles
    check("B.layoutNoticeBalloons exists", type(B.layoutNoticeBalloons) == "function")
    if type(B.layoutNoticeBalloons) == "function" then
        -- the note at the belt's right end: Deck (1280 wide, k = 1) and 720p, the note ~ 300 px right of the middle
        for _, sc in ipairs({ { "Deck 1280x800", 1280, 940 }, { "720p", 1280, 950 }, { "4K at 2x", 1920, 1260 }, { "note near the edge", 1280, 1250 } }) do
            local W, ax = sc[2], sc[3]
            local list = {}
            for i = 1, 3 do
                local lines, tw = B.noticeLines("Controller plugged in", "Controllers | Press A on it again to choose how it joins.")
                list[i] = { lines = lines, tw = tw, dot = {} }
            end
            local x0, y0, x1, y1 = B.layoutNoticeBalloons(list, 0 - ax, W - ax, true)
            local inside, stacked, tailOk = true, true, true
            for i, n in ipairs(list) do
                if ax + n.x < 0 or ax + n.x + n.w + 2 > W then inside = false end
                if i > 1 and not (list[i - 1].y + list[i - 1].h <= n.y) then stacked = false end   -- (older over newer)
            end
            local newest = list[#list]
            if not (newest.x <= -5 - 3 + 0 and newest.x + newest.w >= 6 + 3) then tailOk = false end
            check(sc[1] .. ": every balloon on the screen", inside)
            check(sc[1] .. ": the newest lowest, the older over it", stacked)
            check(sc[1] .. ": the newest over the note (its bottom just above it)", newest.y + newest.h == -B.GAP - B.TAIL_H, newest.y + newest.h)
            check(sc[1] .. ": the tail's base under the newest", tailOk, tostring(newest.x) .. "," .. tostring(newest.w))
            check(sc[1] .. ": the box holds them all", x0 <= newest.x and y1 == 0 and y0 <= list[1].y)
        end
        local lines = B.noticeLines("a", string.rep("word ", 200))
        check("a long notice: at most NOTICE_LINES lines", #lines == B.NOTICE_LINES, #lines)
        check("... the last ends ...", lines[#lines]:sub(-3) == "...")
        local _, y0 = B.layoutNoticeBalloons({ { lines = { "A" }, tw = 6 } }, -500, 500, false)
        check("no note on the screen: no tail room", y0 == -B.GAP - (1 * B.LINE - 2 + B.PAD * 2), y0)
    end
    -- the toasts window draws them out of the belt's note
    local src = io.open(CLIENT .. "ZeD_MessagesWindow.lua"):read("*a")
    check("the toasts no longer stand in the top right corner", src:find("TOAST_RIGHT", 1, true) == nil)
    check("the toasts come out of the belt's note", src:find("B.noteAnchor", 1, true) ~= nil and src:find("layoutNoticeBalloons", 1, true) ~= nil)
end

-- ===========================================================================
section("B12 B13 PADS: controllers join and leave through Messages")
-- ===========================================================================
do
    ZeD.Messages = {}
    ZeD.Settings = { messagesToastOn = function() return false end, messagesCatchOn = function() return true end }   -- (the default)
    function getPlayer() return {} end
    function getGameTime() return nil end
    local okM, errM = loadZ("ZeD_Messages.lua")
    check("ZeD_Messages.lua loads", okM, errM)
    local M = ZeD.Messages
    check("ZeD.Messages.pad exists", type(M.pad) == "function")
    -- the game's list, as far as its fill and invoke go
    local invoked = {}
    local vanillaCreate, vanillaBanner = 0, 0
    ISJoypadListBox = {}
    function ISJoypadListBox.fill(list)
        list:clear()
        list:addItem("IGUI_Controller_TakeOverPlayer(1)", { cmd = "takeover", playerNum = 0 })
        list:addItem("IGUI_Controller_AddNewPlayer", { cmd = "addnew" })
        list:addItem("UI_Cancel", { cmd = "cancel" })
    end
    function ISJoypadListBox:invoke() invoked[#invoked + 1] = { item = self.items[self.selected].item, jd = self.joypadData } end
    ISJoypadListBox.Create = function() vanillaCreate = vanillaCreate + 1; return { vanilla = true } end
    ISJoypadDisconnectedUI = { setKeyboardMouseActivated = function() invoked[#invoked + 1] = { kbm = true } end }
    ISJoypadDisconnectedUI.new = function() vanillaBanner = vanillaBanner + 1; return { vanilla = true } end
    MainScreen = { instance = nil }
    ZeD.PadJoin = {}
    local okC, errC = loadZ("Overrides/Controllers.lua")
    check("Overrides/Controllers.lua loads", okC, errC)
    if type(M.pad) == "function" then
        local jd = { id = 3 }
        local box = ISJoypadListBox.Create(1, jd)
        check("a new controller's A: no list on the screen", not box.vanilla and vanillaCreate == 0)
        box:fill()
        local src = M.sources["UI_ZeD_Pad_Source"]
        local note = src and src.items[1]
        check("a note in Messages: Controller plugged in", note and note.k == "pad" and note.head == "UI_ZeD_Pad_PluggedIn")
        check("a bubble says so", M.toasts[#M.toasts] and M.toasts[#M.toasts].head == "UI_ZeD_Pad_PluggedIn")
        local bs = note and note.padButtons or {}
        check("the game's choices as its buttons, Cancel left out", #bs == 2 and bs[1].label == "IGUI_Controller_TakeOverPlayer(1)" and bs[2].label == "IGUI_Controller_AddNewPlayer", #bs)
        if bs[2] then
            local ok = bs[2].run()
            check("a choice runs the game's own command for that controller", ok and invoked[1] and invoked[1].item.cmd == "addnew" and invoked[1].jd == jd)
        end
        -- the stand-in holds the controller as the game's list did: B lets go
        jd.focus = box
        box:onJoypadDown(Joypad.BButton, jd)
        check("B lets the controller go", jd.focus == nil and jd.activeWhilePaused == nil)
        box:fill()
        check("one note per controller", #M.sources["UI_ZeD_Pad_Source"].items == 1, #M.sources["UI_ZeD_Pad_Source"].items)
        -- unplugged and back
        local banner = ISJoypadDisconnectedUI:new(0)
        check("unplugged: no banner on the screen", not banner.vanilla and vanillaBanner == 0)
        banner:setAlwaysOnTop(true)
        banner:addToUIManager()
        local items = M.sources["UI_ZeD_Pad_Source"].items
        check("a note: Controller unplugged", items[1].head == "UI_ZeD_Pad_Unplugged" and items[1].pad == "p0")
        check("player one: Use keyboard and mouse on it", items[1].padButtons and items[1].padButtons[1].label == "IGUI_Controller_Disconnected2")
        banner:removeFromUIManager()
        items = M.sources["UI_ZeD_Pad_Source"].items
        check("back: the unplugged note replaced", items[1].head == "UI_ZeD_Pad_PluggedIn" and items[1].pad == "p0" and #items == 2, #items)
        local b2 = ISJoypadDisconnectedUI:new(1)
        b2:addToUIManager()
        check("player two: no keyboard button", M.sources["UI_ZeD_Pad_Source"].items[1].padButtons == nil)
        -- safe mode: the game's own
        SAFE.all = true
        local v = ISJoypadListBox.Create(1, { id = 4 })
        check("safe mode: the game's list", v.vanilla and vanillaCreate == 1)
        local vb = ISJoypadDisconnectedUI:new(0)
        check("safe mode: the game's banner", vb.vanilla and vanillaBanner == 1)
        SAFE.all = nil
    end
end

-- ===========================================================================
section("B14 PAUSED: the Character window for looking")
-- ===========================================================================
do
    ZeD.PausedLook = {}
    ZeD.Input = { Focus = {} }
    ZeD_PausedGlass = nil
    ISUIElement = { derive = function(self, name)
        local cls = { _name = name }
        cls.__index = cls
        return setmetatable(cls, { __index = ISUIElement })
    end, new = function(cls, x, y, w, h)
        return setmetatable({ x = x, y = y, width = w, height = h, visible = true }, cls)
    end }
    ISUIElement.__index = ISUIElement
    function ISUIElement:initialise() end
    function ISUIElement:instantiate() end
    function ISUIElement:getX() return self.x end
    function ISUIElement:getY() return self.y end
    function ISUIElement:getWidth() return self.width end
    function ISUIElement:getHeight() return self.height end
    function ISUIElement:setX(v) self.x = v end
    function ISUIElement:setY(v) self.y = v end
    function ISUIElement:setWidth(v) self.width = v end
    function ISUIElement:setHeight(v) self.height = v end
    function ISUIElement:isVisible() return self.visible end
    function ISUIElement:setVisible(v) self.visible = v end
    local okP, errP = loadZ("ZeD_PausedLook.lua")
    check("ZeD_PausedLook.lua loads", okP, errP)
    local PL = ZeD.PausedLook
    local function panel(x, y, w, h) return ISUIElement.new(ISUIElement, x, y, w, h) end
    local kids = {}
    local cw = { _tabStripPanel = panel(0, 20, 36, 400), _containerStrip = panel(408, 20, 36, 400), windowShaded = false }
    function cw:addChild(c) kids[#kids + 1] = c end
    function cw:removeChild(c) for i = #kids, 1, -1 do if kids[i] == c then table.remove(kids, i) end end end
    function cw:getChildren() return kids end
    local other = {}
    ZeD_CharacterWindow = { getWindow = function() return cw end }
    local zone = "charTabContent"
    ZeD.Input.Focus.liveZone = function() return { zone = zone } end
    if type(PL.blocks) == "function" then
        SPEED = 0
        check("paused: an action in the tab is held", PL.blocks(cw, {}))
        zone = "charTabBar"
        check("paused: the tab strip still answers", not PL.blocks(cw, {}))
        zone = "charContainerStrip"
        check("paused: the bags still answer", not PL.blocks(cw, {}))
        zone = "charMainInv"
        check("paused: the item list's actions are held", PL.blocks(cw, {}))
        check("paused: another window is not held", not PL.blocks(other, {}))
        SPEED = 1
        check("playing: nothing held", not PL.blocks(cw, {}))
        SPEED = 0
        PL.frame()
        local g = PL._glass
        check("paused: the glass over the tab and the list", g ~= nil and g:isVisible() and g:getX() == 36 and g:getWidth() == 372 and g:getHeight() == 400,
            g and (tostring(g:getX()) .. "," .. tostring(g:getWidth())))
        check("the glass takes presses", g and g.onMouseDown and g:onMouseDown(10, 10) == true)
        SPEED = 1
        PL.frame()
        check("playing: the glass gone", g and not g:isVisible())
    else
        check("ZeD.PausedLook.blocks exists", false)
    end
    -- the paired toggle no longer steps aside while paused, and the tab's click waits on drawn frames
    local cwsrc = io.open(CLIENT .. "ZeD_CharacterWindow.lua"):read("*a")
    local body = cwsrc:match("function ZeD_CharacterWindow%.toggleBothPaired%(playerNum%)(.-)\nend")
    check("toggleBothPaired opens the Character window alone while paused", body ~= nil
        and body:find("if getGameSpeed() <= 0 then", 1, true) ~= nil and body:find("ZeD_CharacterWindow.toggle(playerNum)", 1, true) ~= nil
        and not body:find("if getGameSpeed() <= 0 then return end", 1, true))
    local fm = io.open(CLIENT .. "Input/FocusManager.lua"):read("*a")
    check("the controller's A and X ask ZeD.PausedLook", select(2, fm:gsub("ZeD.PausedLook.blocks", "")) >= 3)
    local ci = io.open(CLIENT .. "Overrides/CharacterInfo.lua"):read("*a")
    check("the tab's click retries on drawn frames (a paused game has no ticks)", ci:find("Events.OnRenderTick or Events.OnTick", 1, true) ~= nil)
end

-- ===========================================================================
section("B15 STATION: any station gets a ZeD card")
-- ===========================================================================
do
    ZeD.Stations = {}
    ZeD.StationGeneral = {}
    ComponentType = { CraftBench = "CB", DryingCraftLogic = "DRY", CraftLogic = "CL", FurnaceLogic = "FURN", MashingLogic = "MASH", Resources = "RES" }
    local okS, errS = loadZ("Stations.lua")
    check("Stations.lua loads", okS, errS)
    local ST = ZeD.Stations
    local function ent(comps, mod, name)
        local o = { comps = comps }
        local sc = { getModID = function() return mod == nil and "SomeMod" or mod end, getName = function() return name or "Still" end }
        function o:getEntityScript() return sc end
        function o:getComponent(ct) return self.comps[ct] end
        function o:hasComponents() return next(self.comps) ~= nil end
        return o
    end
    local craft = {}
    local k1, c1 = ST.classify(ent({ CL = craft }))
    check("a plain craft machine: a machine (StationMachine's view)", k1 == "machine" and c1 == craft, k1)
    local furn = {}
    local k2 = ST.classify(ent({ FURN = furn }))
    check("an unknown logic stays out of the nearby list", k2 == nil, k2)
    local k3, c3 = ST.classify(ent({ FURN = furn }), true)
    check("the open route: a general station with its logic", k3 == "general" and c3 == furn, k3)
    local k4, c4 = ST.classify(ent({ RES = {} }), true)
    check("a store with no logic: a general station", k4 == "general" and c4 == nil, k4)
    check("a general station takes the game's lock", ST.isEntityKind("general"))
    check("nothing at all: no station", ST.classify(ent({}), true) == nil)
    -- the game's own entities that open its station window keep what opened before (the review)
    for _, nm in ipairs({ "Butcher Hook", "Log Bench", "Log Stool", "Log Table", "Other_Log_Stool" }) do
        check("the game's " .. nm .. ": not a general station", ST.classify(ent({ RES = {} }, "SomeMod", nm), true) == nil)
    end
    check("an entity from the game itself: not a general station", ST.classify(ent({ RES = {} }, "pz-vanilla"), true) == nil)
    check("an entity naming no mod: not a general station", ST.classify(ent({ RES = {} }, ""), true) == nil)
    local src = io.open(CLIENT .. "Overrides/Stations.lua"):read("*a")
    check("ISEntityUI.OpenWindow asks for general stations", src:find("ST.open(player, entity, true)", 1, true) ~= nil)
    local ct = io.open(CLIENT .. "CraftingTab.lua"):read("*a")
    check("the Craft tab draws the general view", ct:find("ZeD.StationGeneral, st", 1, true) ~= nil)

    ZeD.CraftingCore = {}
    local okG, errG = loadZ("StationGeneral.lua")
    check("StationGeneral.lua loads", okG, errG)
    local SG = ZeD.StationGeneral
    if type(SG.gather) == "function" then
        local function jlist(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end
        local function item(ft, name) return { getFullType = function() return ft end, getDisplayName = function() return name end } end
        local ore = item("Base.Ore", "Ore")
        local ingot = item("Base.Ingot", "Ingot")
        local inRes = { getIO = function() return "Input" end, getType = function() return "Item" end,
                        getStoredItems = function() return jlist({ ore, ore }) end, getItemAmount = function() return 2 end,
                        getItemCapacity = function() return 10 end, getFreeItemCapacity = function() return 8 end,
                        acceptsItem = function(_, it) return it:getFullType() == "Base.Ore" end }
        local outRes = { getIO = function() return "Output" end, getType = function() return "Item" end,
                         getStoredItems = function() return jlist({ ingot }) end, getItemAmount = function() return 1 end,
                         getItemCapacity = function() return 5 end, getFreeItemCapacity = function() return 4 end }
        local tank = { getIO = function() return "Any" end, getType = function() return "Fluid" end,
                       getFluidAmount = function() return 2.5 end, getFluidCapacity = function() return 10 end }
        local rc = { getResources = function() return jlist({ inRes, outRes, tank }) end }
        local logic = { isRunning = function() return false end, getPossibleRecipe = function() return { getName = function() return "Smelt" end } end,
                        canStart = function() return true end, getProgress = function() return 0 end }
        local obj = { getComponent = function(_, c) if c == "RES" then return rc end end }
        local bagOre = item("Base.Ore", "Ore")
        local stick = item("Base.Stick", "Stick")
        ZeD.CraftingCore.buildContainers = function() return jlist({ { getItems = function() return jlist({ bagOre, stick }) end } }) end
        local player = { isEquipped = function() return false end }
        local st = { obj = obj, comp = logic, kind = "general" }
        local d = SG.gather(st, player)
        check("its logic: idle, can start, the recipe it would make", d.logic and not d.running and d.canStart and d.recipe)
        check("its resources, each with its role and kind", #d.res == 3 and d.res[1].io == "in" and d.res[2].io == "out" and d.res[3].kind == "fluid")
        check("the stored items grouped by kind", #d.res[1].items == 1 and #d.res[1].items[1].items == 2)
        check("from the bags: only what an input takes", #d.bag == 1 and d.bag[1].type == "Base.Ore" and d.bag[1].res == inRes, #d.bag)
        local rows = SG.rows(d)
        local kinds = {}
        for _, r in ipairs(rows) do kinds[#kinds + 1] = r.kind end
        check("the card: recipe, cycle, each resource, the bags", table.concat(kinds, ",") == "recipe,cycle,head,stored,head,stored,head,amount,bagsHead,bag", table.concat(kinds, ","))
        local started, removedN, added = nil, 0, 0
        ISEntityUI = { WalkToEntity = function() return true end,
                       GenericCraftStart = function(pl, o, c, can, go) started = { can = can, go = go, c = c } end }
        ISItemSlotRemoveAction = { new = function() removedN = removedN + 1; return {} end }
        ISItemSlotAddAction = { new = function() added = added + 1; return {} end }
        QUEUE = {}
        SG.activate(player, st, { type = "gStart", enabled = true, running = false })
        check("Start: the game's GenericCraftStart on its logic", started and started.c == logic)
        SG.activate(player, st, { type = "gTake", res = outRes, group = d.res[2].items[1] })
        check("Take: the game's slot remove action", removedN == 1 and #QUEUE == 1)
        SG.activate(player, st, { type = "gAdd", group = d.bag[1] })
        check("Add: the game's slot add action", added == 1 and #QUEUE == 2)
        local noLogic = SG.rows(SG.gather({ obj = obj, comp = nil }, player))
        check("no logic: no recipe or Start", noLogic[1] and noLogic[1].kind == "head")
    else
        check("ZeD.StationGeneral.gather exists", false)
    end
end

-- ===========================================================================
section("ROUND 2 (the director's answers, Nov 7 2026)")
-- ===========================================================================
do
    -- 1. a save that left the game's mini-map showing: hidden
    ZeD.MiniMapOff = {}
    local shown = { true, false, false, false }
    local removed = 0
    local mms = {}
    function getPlayerMiniMap(pn)
        if pn > 1 then return nil end
        if mms[pn] then return mms[pn] end
        mms[pn] = { isReallyVisible = function() return shown[pn + 1] end,
                 setVisible = function(_, v) if not v then removed = removed + 1 end; shown[pn + 1] = v end }
        return mms[pn]
    end
    local okM, errM = loadZ("Overrides/MiniMap.lua")
    check("Overrides/MiniMap.lua loads", okM, errM)
    local MO = ZeD.MiniMapOff
    if type(MO.hide) == "function" then
        check("a shown mini-map taken off the screen", MO.hide() and removed == 1)
        check("nothing shown: nothing done", not MO.hide() and removed == 1)
        shown[1] = true
        SAFE.wheels = true
        shown[1] = false
        SAFE.wheels = true
        MO.hide()
        check("ZeD's wheels given back: the mini-map it hid shows again", shown[1] == true and removed == 1)
        check("... and stays", not MO.hide() and removed == 1)
        SAFE.wheels = nil
    else
        check("ZeD.MiniMapOff.hide exists", false)
    end

    -- 5. each player's notices from that player's belt; player one's when there is one belt
    ZeD.Belt = {}
    local okB, errB = loadZ("ZeD_Belt.lua")
    check("ZeD_Belt.lua loads", okB, errB)
    local B = ZeD.Belt
    local function hud(x, lampX)
        return { _drawn = true, getIsVisible = function() return true end, getX = function() return x end,
                 getY = function() return 700 end, _boxes = { { kind = "slot", x = 0, y = 0, w = 10, h = 10 }, { kind = "lamp", x = lampX, y = 4, w = 38, h = 38 } } }
    end
    B._hud = hud(100, 500)
    B._huds = nil
    local ax = B.noteAnchor(1)
    check("one belt: player two's notice from player one's note", ax == 100 + 500 + 19, ax)
    B._huds = { [0] = hud(100, 500), [1] = hud(1000, 400) }
    check("a belt per player: player two's from player two's note", B.noteAnchor(1) == 1000 + 400 + 19, B.noteAnchor(1))
    check("... player one's from player one's", B.noteAnchor(0) == 619)
    check("no belt for player three: player one's", B.noteAnchor(2) == 619)
    B._huds, B._hud = nil, nil
    check("no belt at all: none", B.noteAnchor(0) == nil)

    -- notices addressed to a player
    ZeD.MessagesWindow = {}
    ZeD.T = { px = function(v) return v end }
    function getSpecificPlayer(pn) if pn <= 1 then return {} end return nil end
    local okW, errW = loadZ("ZeD_MessagesWindow.lua")
    check("ZeD_MessagesWindow.lua loads", okW, errW)
    local W = ZeD.MessagesWindow
    if type(W.toastsFor) == "function" then
        local all = { { head = "a" }, { head = "b", pn = 1 }, { head = "c", pn = 3 } }
        local p0, p1 = W.toastsFor(0, all), W.toastsFor(1, all)
        check("player one's balloons: theirs and a player gone's", #p0 == 2 and p0[1].head == "a" and p0[2].head == "c", #p0)
        check("player two's: theirs", #p1 == 1 and p1[1].head == "b")
        -- 2. driving: the dash's note, the bubbles out of it
        ZeD.Messages.count = function() return 1 end
        local dash = { getIsVisible = function() return true end, getX = function() return 560 end, getY = function() return 900 end,
                       getWidth = function() return 800 end }
        ZeD.Dashboard.getInstance = function() return dash end
        local x, y, w = W.dashNoteRect()
        check("the dash's note: its top right, over the dash", x == 560 + 800 - 38 - 10 and y == 900 - 38 - 6 and w == 38, tostring(x) .. "," .. tostring(y))
        local nx, ny, tail = W.noticeAnchor(0)
        check("driving: the balloons out of the dash's note, with the tail", tail == true and nx == x + 19 and ny == y - 4, tostring(nx) .. "," .. tostring(ny))
        ZeD.Messages.count = function() return 0 end
        check("nothing kept: no dash note", W.dashNoteRect() == nil)
        local _, _, t2 = W.noticeAnchor(0)
        check("no note anywhere: no tail", t2 == false)
    else
        check("ZeD.MessagesWindow.toastsFor exists", false)
    end
    -- the controllers' unplugged note goes to that player
    local M = ZeD.Messages
    if ZeD.PadJoin and ZeD.PadJoin.unplugged then
        M.toasts = {}
        ZeD.PadJoin.unplugged(1)
        check("player two's controller unplugged: player two's balloon", M.toasts[1] and M.toasts[1].pn == 1, M.toasts[1] and M.toasts[1].pn)
    end

    -- 4. paused: the World window held too, the same veil
    local PL = ZeD.PausedLook
    if type(PL.worldRect) == "function" then
        local kids = {}
        local function panel(x, y, w, h) return ISUIElement.new(ISUIElement, x, y, w, h) end
        local ww = { _containerStrip = panel(0, 20, 36, 400), _actionTabStrip = panel(408, 20, 36, 400), windowShaded = false }
        function ww:addChild(c) kids[#kids + 1] = c end
        function ww:removeChild(c) for i = #kids, 1, -1 do if kids[i] == c then table.remove(kids, i) end end end
        function ww:getChildren() return kids end
        ZeD_WorldWindow = { getWindow = function() return ww end }
        ZeD.Input.Focus.liveZone = function() return { zone = "worldMainInv" } end
        SPEED = 0
        check("paused: the World window's actions held", PL.blocks(ww, {}))
        ZeD.Input.Focus.liveZone = function() return { zone = "worldTabBar" } end
        check("paused: the World window's tab strip free", not PL.blocks(ww, {}))
        PL.frame()
        local g = PL._wglass
        check("paused: the veil over the World window, between its bags and its tabs", g and g:isVisible() and g:getX() == 36 and g:getWidth() == 372, g and g:getX())
        SPEED = 1
        PL.frame()
        check("playing: the World window's veil gone", g and not g:isVisible())
    else
        check("ZeD.PausedLook.worldRect exists", false)
    end
end

-- ===========================================================================
section("ROUND 3 (the review, Nov 7 2026)")
-- ===========================================================================
do
    local M = ZeD.Messages
    -- 1. the controllers' balloons show whatever the notices setting says (Off by default)
    M.toasts = {}
    ZeD.PadJoin.unplugged(0)
    check("notices Off: a controller unplugged still pops its balloon", #M.toasts == 1, #M.toasts)
    M.toasts = {}
    if M.adminNote then M.adminNote("x") end
    check("notices Off: other notices still follow the setting", #M.toasts == 0, #M.toasts)

    -- 2. the pad works in the paused windows
    local PL = ZeD.PausedLook
    local cw = ZeD_CharacterWindow.getWindow()
    local jd = { focus = cw }
    JoypadState.players[1] = jd
    SPEED = 0
    PL.frame()
    check("paused, the Character window holding the pad: the pad works", jd.activeWhilePaused == true)
    SPEED = 1
    PL.frame()
    check("playing: put back as it was", jd.activeWhilePaused == nil)
    SPEED = 0
    jd.focus = ZeD_WorldWindow.getWindow()
    PL.frame()
    check("paused, the World window: the pad works", jd.activeWhilePaused == true)
    jd.focus = nil
    PL.frame()
    check("the window lets go: put back", jd.activeWhilePaused == nil)
    SPEED = 1
    JoypadState.players[1] = nil
    local fm = io.open(CLIENT .. "Input/FocusManager.lua"):read("*a")
    check("the pad's poll runs on drawn frames while paused", fm:find("if ok and sp == 0 then _onTick() end", 1, true) ~= nil)

    -- 5. the guest window and player one's focus; a guest controller unplugged; keyboard and mouse
    local W = ZeD.MessagesWindow
    local cleared = 0
    function setJoypadFocus() cleared = cleared + 1 end
    local own = { focus = "player one's window" }
    JoypadState.players[1] = own
    local guest = {}
    local win = { guestJoy = guest, playerNum = 0, setVisible = function() end, removeFromUIManager = function() end }
    guest.focus = win
    local close = ZeD_MessagesWindow and rawget(ZeD_MessagesWindow, "close")
    if close then
        close(win)
        check("closing the guest window leaves player one's focus", cleared == 0 and guest.focus == nil, cleared)
    else
        check("ZeD_MessagesWindow:close loaded", false)
    end
    JoypadState.players[1] = nil
    local closed = 0
    local gwin = { guestJoy = guest, close = function() closed = closed + 1 end }
    local realGet = W.get
    W.get = function() return gwin end
    JoypadState.controllers[7] = { joypad = guest }
    ZeD.PadJoin.onDisconnect(7)
    check("a guest controller unplugged: the window lets it go", closed == 1, closed)
    W.get = realGet
    local note = ZeD.PadJoin.unplugged(0)
    JoypadState.joypads[1] = { disconnectedUI = {} }
    note.padButtons[1].run()
    check("Use keyboard and mouse: the disconnected marker cleared", JoypadState.joypads[1].disconnectedUI == nil)
    M.toasts = {}
    local back = ZeD.PadJoin.replugged(0)
    check("... a later plug-in does not say player one's controller is back", back == nil and #M.toasts == 0)
    -- the stand-ins become a controller's focus, and the game's updateJoypadFocus names each focus with ui:toString()
    -- every frame until it settles: without one it threw every frame and never settled
    local st = ZeD.PadJoin.stub(1, { id = 1 })
    check("the join stand-in names itself (the game's updateJoypadFocus asks)", type(st.toString) == "function" and type(st:toString()) == "string")
    local ds = ZeD.PadJoin.disconnectedStub(1)
    check("the unplugged stand-in names itself too", type(ds.toString) == "function" and type(ds:toString()) == "string")
end

print(string.format("everyday_leftovers_sim: %d checks, %d failed", checks, failed))
os.exit(failed == 0 and 0 or 1)
