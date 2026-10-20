-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ActionBar.lua
-- ============================================================================
-- THE ACTION BAR — the progress bar over the character's head (Oct 19 2026;
-- mockup ZeDUI/mockups/zed_action_bar_v2.html, approved "ship it").
--
-- Vanilla: every timed action puts a plain bar over the head, drawn by the engine
-- (Options > Action Progress Bar Size, 100-400%), restarting for every item of a
-- queue. ZeD switches the engine's bar off as each action is created and draws its
-- own in the same spot, in one of two ways (Options > Mods > ZeD UI > Action bar):
--
--   VERBOSE (default)  two lines in the HUD's pixel faces (ZeD/PixelFonts.lua):
--                      the action in the 5 x 7 face in the accent with the queue
--                      (RIPPING 4/12); under it in the 3 x 5 legend face the item
--                      and its percent (SHEET 40%), the time so far for an action
--                      with no end (0:42), THEN <ACTION> while walking there; a
--                      2-unit bar for the whole job, notched between its items.
--   SIMPLE             ten segments in a frame, no words: one fill for the whole
--                      job, the next segment pulsing; no end = one segment sweeping.
--
-- Shared rules: a queue of the same action is one job; an action with no end
-- (maxTime -1: resting, sitting, chopping, walking there) never shows a percent;
-- finishing shows the positive colour for a moment, stopping goes grey (stopping is
-- nearly always the player's own choice), then the bar fades. Resting, sitting and
-- walking simply vanish when they end.
--
-- Vanilla's own "no bar" stays: an action whose Lua table says useProgressBar =
-- false (hotbar attach / detach, magazines, racking, petting, luring, the info
-- actions...) or that switches it off itself (foraging, exercise) gets none here.
-- Other players' bars in multiplayer stay the engine's.
--
-- Pixel art: drawn in design units on whole multiples (ZeD.Px canvas, k = the root
-- scale as a whole multiple x vanilla's size option), so every pixel stays square.
-- ============================================================================

require "ZeD/ZeD_Panel"
require "ZeD/ZeD_PixelParts"
require "TimedActions/ISBaseTimedAction"

ZeD = ZeD or {}
ZeD.ActionBar = ZeD.ActionBar or {}
local AB = ZeD.ActionBar
local P = ZeD.Px

-- ---------------------------------------------------------------------------
-- tuning
-- ---------------------------------------------------------------------------
AB.HEAD_Z = 0.62          -- the top of the hair above the feet, in floors (measured in game Oct 19 2026: 119 of 192 px)
AB.GAP = 6                -- design units between the head and the bar
AB.END_HOLD = 450         -- ms the done / stopped state holds before it fades
AB.END_FADE = 350         -- ms of fade after that
AB.QUIET_FADE = 250       -- ms for resting / sitting / walking to vanish

-- actions that end without a flash
local QUIET = { ISRestAction = true, ISSitOnGround = true, ISWalkToTimedAction = true, ISWalkToTimedActionF = true,
                ISPathFindAction = true, ISWaitWhileGettingUp = true }
local WALKS = { ISWalkToTimedAction = true, ISWalkToTimedActionF = true, ISPathFindAction = true }
AB.WALKS = WALKS

-- vanilla actions that switch their own bar off once started (in start(), after create)
local SELF_HIDDEN = { ISForageAction = true, ISFitnessAction = true }

-- ---------------------------------------------------------------------------
-- labels: what the character is doing, in the 5 x 7 face (capitals, digits)
-- ---------------------------------------------------------------------------
AB.LABELS = {
    ISReadABook = "READING", ISReadWorldMap = "READING", ISResearchRecipe = "RESEARCHING", ISWriteSomething = "WRITING",
    ISEatFoodAction = "EATING", ISDrinkFromBottle = "DRINKING", ISDrinkFluidAction = "DRINKING", ISTakeWaterAction = "DRINKING",
    ISTakePillAction = "TAKING PILLS",
    ISInventoryTransferAction = "MOVING", ISTransferAction = "MOVING", ISDropWorldItemAction = "DROPPING",
    ISDropVehicleItemAction = "DROPPING", ISGrabItemAction = "PICKING UP", ISMoveablesAction = "MOVING",
    ISConsolidateDrainable = "COMBINING", ISDumpContentsAction = "EMPTYING",
    ISCraftAction = "CRAFTING", ISHandcraftAction = "CRAFTING", ISCraftAnimAction = "CRAFTING", ISGenericCraftStart = "CRAFTING",
    ISBuildAction = "BUILDING", ISMultiStageBuild = "BUILDING", ISDismantleAction = "DISMANTLING", ISDestroyStuffAction = "DESTROYING",
    ISBarricadeAction = "BARRICADING", ISUnbarricadeAction = "PRYING OFF",
    ISRepairClothing = "REPAIRING", ISFixAction = "REPAIRING", ISRepairEngine = "REPAIRING", ISRepairLightbar = "REPAIRING",
    ISFixGenerator = "REPAIRING", ISFixVehiclePartAction = "REPAIRING", ISRemovePatch = "REMOVING PATCH",
    ISWearClothing = "PUTTING ON", ISUnequipAction = "TAKING OFF", ISEquipWeaponAction = "EQUIPPING",
    ISEquipHeavyItem = "LIFTING", ISClothingExtraAction = "CHANGING",
    ISWashClothing = "WASHING", ISWashYourself = "WASHING", ISWashVehicle = "WASHING", ISWringClothing = "WRINGING OUT",
    ISDryMyself = "DRYING OFF", ISCleanBlood = "CLEANING", ISCleanGraffiti = "CLEANING", ISCleanBandage = "CLEANING",
    ISApplyBandage = "BANDAGING", ISDisinfect = "DISINFECTING", ISStitch = "STITCHING", ISSplint = "SPLINTING",
    ISRemoveGlass = "REMOVING GLASS", ISRemoveBullet = "EXTRACTING", ISCleanBurn = "CLEANING",
    ISComfreyCataplasm = "APPLYING", ISGarlicCataplasm = "APPLYING", ISPlantainCataplasm = "APPLYING",
    ISMedicalCheckAction = "CHECKING",
    ISReloadWeaponAction = "RELOADING", ISUnloadBulletsFromFirearm = "UNLOADING", ISUnloadBulletsFromMagazine = "UNLOADING",
    ISUpgradeWeapon = "UPGRADING", ISRemoveWeaponUpgrade = "REMOVING",
    ISRestAction = "RESTING", ISSitOnGround = "SITTING", ISGetOnBedAction = "LYING DOWN", ISWaitWhileGettingUp = "GETTING UP",
    ISWalkToTimedAction = "WALKING", ISWalkToTimedActionF = "WALKING", ISPathFindAction = "WALKING",
    ISChopTreeAction = "CHOPPING", ISRemoveBush = "CLEARING", ISRemoveGrass = "CUTTING GRASS", ISScything = "SCYTHING",
    ISPlowAction = "DIGGING", ISDigStairsAction = "DIGGING", ISShovelGround = "SHOVELING", ISShovelAction = "SHOVELING",
    ISSeedActionNew = "SOWING", ISWaterPlantAction = "WATERING", ISHarvestPlantAction = "HARVESTING",
    ISFertilizeAction = "FERTILIZING", ISCurePlantAction = "TREATING", ISAddCompost = "COMPOSTING", ISGetCompost = "TAKING COMPOST",
    ISButcherAnimal = "BUTCHERING", ISCutAnimalOnHook = "BUTCHERING", ISRemoveLeatherFromAnimal = "SKINNING",
    ISRemoveMeatFromAnimal = "TAKING MEAT", ISRemoveHeadFromAnimal = "REMOVING HEAD", ISGatherBloodFromAnimal = "BLEEDING",
    ISGetAnimalBones = "TAKING BONES", ISMilkAnimal = "MILKING", ISShearAnimal = "SHEARING", ISKillAnimal = "KILLING",
    ISFeedAnimalFromHand = "FEEDING", ISGiveWaterToAnimal = "WATERING", ISPickupAnimal = "PICKING UP",
    ISHutchCleanFloor = "CLEANING", ISHutchCleanNest = "CLEANING", ISHutchGrabEgg = "TAKING EGGS", ISPickupDung = "PICKING UP",
    ISFluidTransferAction = "POURING", ISTransferWaterAction = "POURING", ISDumpWaterAction = "POURING OUT",
    ISFluidEmptyAction = "EMPTYING", ISEmptyRainBarrelAction = "EMPTYING", ISAddFluidFromItemAction = "FILLING",
    ISAddFuel = "ADDING FUEL", ISAddFuelAction = "ADDING FUEL", ISBBQAddFuel = "ADDING FUEL", ISTakeFuel = "TAKING FUEL",
    ISRefuelFromGasPump = "REFUELING", ISAddGasolineToVehicle = "REFUELING", ISTakeGasolineFromVehicle = "SIPHONING",
    ISLightFromKindle = "LIGHTING", ISLightFromLiterature = "LIGHTING", ISLightFromPetrol = "LIGHTING",
    ISBBQLightFromKindle = "LIGHTING", ISBBQLightFromLiterature = "LIGHTING", ISBBQLightFromPetrol = "LIGHTING",
    ISPutOutCampfireAction = "PUTTING OUT", ISPutOutFire = "PUTTING OUT", ISBBQExtinguish = "PUTTING OUT",
    ISInstallVehiclePart = "INSTALLING", ISUninstallVehiclePart = "REMOVING", ISHotwireVehicle = "HOTWIRING",
    ISSmashVehicleWindow = "SMASHING", ISSmashWindow = "SMASHING", ISRemoveBrokenGlass = "CLEARING GLASS",
    ISClimbThroughWindow = "CLIMBING", ISClimbOverFence = "CLIMBING", ISClimbSheetRopeAction = "CLIMBING",
    ISEnterVehicle = "GETTING IN", ISExitVehicle = "GETTING OUT", ISSwitchVehicleSeat = "CHANGING SEATS",
    ISPaintAction = "PAINTING", ISPaintSignAction = "PAINTING", ISPlasterAction = "PLASTERING", ISWallpaperAction = "WALLPAPERING",
    ISBuryCorpse = "BURYING", ISFillGrave = "FILLING GRAVE", ISBurnCorpseAction = "BURNING", ISGrabCorpseAction = "LIFTING",
    ISCutHair = "CUTTING HAIR", ISTrimBeard = "TRIMMING", ISDyeHair = "DYEING HAIR", ISApplyMakeUp = "MAKING UP",
    ISPlaceTrap = "SETTING TRAP", ISCheckTrapAction = "CHECKING TRAP", ISRemoveTrapAction = "TAKING TRAP",
    ISAddBaitAction = "BAITING", ISRemoveBaitAction = "TAKING BAIT",
    ISTakeGenerator = "PICKING UP", ISPlugGenerator = "PLUGGING IN", ISActivateGenerator = "SWITCHING",
    ISDeviceBatteryAction = "CHANGING", ISDeviceMediaAction = "CHANGING MEDIA",
    ISInflateTire = "INFLATING", ISDeflateTire = "DEFLATING", ISTakeEngineParts = "TAKING PARTS", ISTakeBricks = "TAKING BRICKS",
    ISPadlockAction = "LOCKING", ISPadlockByCodeAction = "LOCKING", ISPickAxeGroundCoverItem = "DIGGING UP",
    ISPickUpGroundCoverItem = "PICKING UP",
    -- the rest of vanilla (Oct 19 2026: the class names alone gave OVENING, HORNING...)
    AIAttachLureAction = "ATTACHING LURE", AIRemoveLureAction = "REMOVING LURE", AddChumToWaterAction = "CHUMMING",
    CreateChumFromGroundSandAction = "MAKING CHUM", HealthPanelAction = "TREATING",
    ISActivateCarBatteryChargerAction = "SWITCHING ON", ISAddAnimalInTrailer = "LOADING", ISAddBaitToFishNetAction = "BAITING",
    ISAddItemInRecipe = "ADDING", ISAddSheetAction = "HANGING SHEET", ISAddSheetRope = "TYING ROPE",
    ISAddTakeDispenserBottle = "CHANGING", ISAddWaterToTrough = "FILLING", ISAttachAnimalToPlayer = "LEASHING",
    ISAttachAnimalToTree = "TYING UP", ISAttachItemHotbar = "ATTACHING", ISAttachTrailerToVehicle = "HITCHING",
    ISBBQInfoAction = "CHECKING", ISBBQInsertPropaneTank = "FITTING TANK", ISBBQRemovePropaneTank = "REMOVING TANK",
    ISBBQToggle = "SWITCHING", ISChangeFishingRodEquip = "CHANGING", ISCheckAnimalInsideTrailer = "CHECKING",
    ISCheckFishingNetAction = "CHECKING NET", ISClearAshes = "CLEARING ASHES", ISCloseVehicleDoor = "CLOSING",
    ISConfigHeadlight = "ADJUSTING", ISConnectCarBatteryToChargerAction = "CONNECTING", ISDetachItemHotbar = "DETACHING",
    ISDetachTrailerFromVehicle = "UNHITCHING", ISDropAnimalCorpseAndThen = "DROPPING", ISDropCorpseAction = "DROPPING",
    ISDropCorpseIntoContainer = "DROPPING", ISEjectMagazine = "EJECTING", ISEmptyWaterInTrough = "EMPTYING",
    ISExtendedPlacementAction = "PLACING", ISFitnessAction = "EXERCISING", ISFluidPanelAction = "CHECKING",
    ISForageAction = "FORAGING", ISGeneratorInfoAction = "CHECKING", ISGetHutchInfo = "CHECKING", ISGrabCorpseItem = "LIFTING",
    ISHorn = "HONKING", ISHurricaneLanternExtinguish = "PUTTING OUT", ISHutchGrabAnimal = "GRABBING",
    ISHutchGrabCorpseAction = "GRABBING", ISInsertLightSourceFuelAction = "REFUELING", ISInsertMagazine = "LOADING",
    ISInspectAnimalTrackAction = "TRACKING", ISItemSlotAddAction = "ADDING", ISItemSlotRemoveAction = "REMOVING",
    ISKillAnimalInInventory = "KILLING", ISLightActions = "LIGHTING", ISLightbarUITimedAction = "SWITCHING",
    ISLitCandleExtinguish = "SNUFFING", ISLoadBulletsInMagazine = "LOADING", ISLockDoor = "LOCKING", ISLockDoors = "LOCKING",
    ISLockVehicleDoor = "LOCKING", ISLureAnimal = "LURING", ISOpenAnimalInfo = "CHECKING", ISOpenButcherHookUI = "CHECKING",
    ISOpenCloseCurtain = "USING", ISOpenCloseDoor = "USING", ISOpenCloseLid = "USING", ISOpenCloseVehicleWindow = "WINDING",
    ISOpenCloseWindow = "USING", ISOpenContainerTimedAction = "OPENING", ISOpenMechanicsUIAction = "INSPECTING",
    ISOpenVehicleDoor = "OPENING", ISOvenUITimedAction = "CHECKING", ISPetAnimal = "PETTING", ISPickupBrokenGlass = "PICKING UP",
    ISPickupFishAction = "PICKING UP", ISPlaceCarBatteryChargerAction = "PLACING", ISPlaceFishingNetAction = "SETTING NET",
    ISPlantInfoAction = "CHECKING", ISPlumbItem = "PLUMBING", ISPutAnimalInHutch = "PUTTING IN", ISPutAnimalOnHook = "HANGING",
    ISQueueActionsAction = "PREPARING", ISRackFirearm = "RACKING", ISRadioAction = "TUNING",
    ISRemoveAnimalFromHook = "TAKING DOWN", ISRemoveAnimalFromTrailer = "UNLOADING", ISRemoveBurntVehicle = "CLEARING WRECK",
    ISRemoveCampfireAction = "TAKING APART", ISRemoveCarBatteryFromChargerAction = "DISCONNECTING",
    ISRemoveFishingNetAction = "TAKING NET", ISRemoveLightSourceFuelAction = "TAKING FUEL", ISRemoveSheetAction = "TAKING DOWN",
    ISRemoveSheetRope = "UNTYING ROPE", ISSetComboWasherDryerMode = "SWITCHING", ISShutOffVehicleEngine = "SWITCHING OFF",
    ISStartCraftProcessorAction = "STARTING", ISStartVehicleEngine = "STARTING", ISStopAlarmClockAction = "SILENCING",
    ISStopVehicle = "STOPPING", ISTakeCarBatteryChargerAction = "PICKING UP", ISTakeTrap = "TAKING TRAP",
    ISThrowCorpseOverFence = "THROWING", ISThrowCorpseThroughWindow = "THROWING", ISToggleClothingDryer = "SWITCHING",
    ISToggleClothingWasher = "SWITCHING", ISToggleComboWasherDryer = "SWITCHING", ISToggleHutchDoor = "OPENING",
    ISToggleHutchEggHatchDoor = "OPENING", ISToggleLightAction = "SWITCHING", ISToggleLightSourceAction = "SWITCHING",
    ISToggleStoveAction = "SWITCHING", ISUnlockVehicleDoor = "UNLOCKING", ISWakeOtherPlayer = "WAKING",
    IsCampfireInfoAction = "CHECKING",
}

-- any mod's action, from its class name when the name starts with a verb: ISRepairGunAction -> REPAIRING GUN;
-- anything else (a name that starts with a noun) reads WORKING
local DOUBLE = { cut = true, put = true, dig = true, rip = true, plug = true, drop = true, chop = true, grab = true, pet = true,
                 stop = true, trim = true, set = true, sit = true, get = true, shut = true, wrap = true, plan = true, hit = true }
local SMALL = { ["A"] = true, ["AN"] = true, ["THE"] = true, ["FROM"] = true, ["TO"] = true, ["IN"] = true, ["ON"] = true,
                ["OF"] = true, ["INTO"] = true, ["WITH"] = true, ["FOR"] = true, ["AND"] = true, ["THEN"] = true }
function AB.gerund(word)
    local w = string.lower(word)
    if w == "" then return "" end
    if w:sub(-3) == "ing" then return w end
    if w:sub(-2) == "ie" then return w:sub(1, -3) .. "ying" end
    if w:sub(-1) == "e" and w:sub(-2) ~= "ee" and w:sub(-2) ~= "ye" and w:sub(-2) ~= "oe" then return w:sub(1, -2) .. "ing" end
    if DOUBLE[w] then return w .. w:sub(-1) .. "ing" end
    return w .. "ing"
end
local VERBS = {}
for w in ("add apply attach bake bandage barricade boil build burn bury buy carry carve catch change check chop clean clear "
       .. "climb close collect connect cook craft cut destroy detach dig disassemble dismantle drain drink drop dry dump dye eat "
       .. "empty equip extinguish feed fill fish fit fix forage gather get give grab grind harvest heal hunt inspect install "
       .. "kill knit light load lock make melt mend milk mix move open pack paint pick place plant plow plug pour prepare pull "
       .. "put read refuel remove repair research rest rip saw scrap sew sharpen shear shovel sit skin smash smelt smoke "
       .. "sow splint start stitch stop take tan tie toggle transfer treat trim tune unload unlock unpack untie upgrade use "
       .. "wash water wear weave wrap write"):gmatch("%a+") do VERBS[w] = true end
function AB.autoLabel(typeName)
    local s = tostring(typeName or "")
    s = s:gsub("^IS", ""):gsub("^Is", ""):gsub("^AI", "")
    s = s:gsub("TimedAction$", ""):gsub("Action$", ""):gsub("New$", ""):gsub("UI$", "")
    local words = {}
    for w in s:gmatch("[A-Z][a-z0-9]*") do words[#words + 1] = w end
    if #words == 0 or not VERBS[string.lower(words[1])] then return "WORKING" end
    local out = string.upper(AB.gerund(words[1]))
    -- one more word when it is a thing, not a little joining word, and it stays short
    local nxt = words[2] and string.upper(words[2]) or nil
    if nxt and not SMALL[nxt] and #out + 1 + #nxt <= 14 then out = out .. " " .. nxt end
    return out
end
function AB.label(action)
    if not action then return "WORKING" end
    local t = action.Type
    return AB.LABELS[t] or AB.autoLabel(t)
end

-- the item: what the action works with, in the 3 x 5 face's letters
local ITEM_FIELDS = { "item", "book", "food", "clothing", "weapon", "gun", "bandage", "bottle", "fluidContainer", "fuel",
                      "magazine", "seed", "part", "itemToRepair", "repairItem" }
local _allowed35 = nil
-- accented letters to their plain capitals (the pixel faces have A-Z only)
local PLAIN = { {"[àáâãäåÀÁÂÃÄÅ]", "A"}, {"[çÇ]", "C"}, {"[èéêëÈÉÊË]", "E"}, {"[ìíîïÌÍÎÏ]", "I"}, {"[ñÑ]", "N"},
                {"[òóôõöøÒÓÔÕÖØ]", "O"}, {"[ùúûüÙÚÛÜ]", "U"}, {"[ýÿÝ]", "Y"}, {"ß", "SS"}, {"[’‘]", "'"} }
function AB.clean(s)
    s = tostring(s or "")
    -- vanilla's "Book: Far From Home": the title, not the category (seen in game Oct 19 2026)
    local after = s:match("^[^:]+:%s+(.+)$")
    if after and after ~= "" then s = after end
    for _, p in ipairs(PLAIN) do s = s:gsub(p[1], p[2]) end
    if not _allowed35 then
        _allowed35 = {}
        for k, _ in pairs((ZeD.PixelFonts and ZeD.PixelFonts["35"]) or {}) do _allowed35[k] = true end
    end
    s = string.upper(tostring(s or ""))
    local out = {}
    for i = 1, #s do
        local ch = s:sub(i, i)
        if _allowed35[ch] then out[#out + 1] = ch end
    end
    s = table.concat(out):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    if #s > 16 then s = s:sub(1, 15):gsub(" $", "") .. ".." end
    return s
end
function AB.itemName(action)
    if not action then return "" end
    for _, f in ipairs(ITEM_FIELDS) do
        local v = action[f]
        if v ~= nil and type(v) ~= "string" and type(v) ~= "number" and type(v) ~= "boolean" and type(v) ~= "function" then
            local ok, name = pcall(function() return v:getDisplayName() end)
            if ok and name and name ~= "" then return AB.clean(name) end
        end
    end
    return ""
end

-- ---------------------------------------------------------------------------
-- the engine's bar off, ours on: hooks on the base timed action
-- ---------------------------------------------------------------------------
if not AB._hooked then
    AB._hooked = true
    local origCreate = ISBaseTimedAction.create
    ISBaseTimedAction.create = function(self, ...)
        local r = origCreate(self, ...)
        -- vanilla's own choice first: a table field false (or a self-hiding class) means no bar anywhere
        local wanted = self.useProgressBar ~= false and not SELF_HIDDEN[self.Type]
        self._zedBar = wanted
        self._zedStartMs = getTimestampMs()
        if self.action and self.character and instanceof(self.character, "IsoPlayer") and self.character:isLocalPlayer() then
            pcall(function() self.action:setUseProgressBar(false) end)
        end
        return r
    end
    local origPerform = ISBaseTimedAction.perform
    ISBaseTimedAction.perform = function(self, ...)
        local r = origPerform(self, ...)
        pcall(AB.onEnded, self, "done")
        return r
    end
    local origStop = ISBaseTimedAction.stop
    ISBaseTimedAction.stop = function(self, ...)
        pcall(AB.onEnded, self, "stopped")
        return origStop(self, ...)
    end
end

-- ---------------------------------------------------------------------------
-- the job: what the bar shows for one player, worked out from the queue each frame
-- ---------------------------------------------------------------------------
AB._jobs = AB._jobs or {}     -- playerNum -> job
AB._ends = AB._ends or {}     -- playerNum -> { kind, ms, st }
AB._last = AB._last or {}     -- playerNum -> the last state drawn (for the end snapshot)

local function nowMs() return getTimestampMs() end
local function playerNumOf(chr)
    local ok, n = pcall(function() return chr:getPlayerNum() end)
    return ok and n or nil
end
local function queueOf(chr)
    return ISTimedActionQueue and ISTimedActionQueue.queues and ISTimedActionQueue.queues[chr] or nil
end
local function shows(a) return a and a._zedBar ~= false end
local function noEnd(a) return (tonumber(a.maxTime) or -1) < 0 end
local function delta(a)
    if not a or not a.action then return 0 end
    local ok, d = pcall(function() return a:getJobDelta() end)
    d = ok and tonumber(d) or 0
    return math.max(0, math.min(1, d))
end

-- how many items an action still has to do: B42's item transfer merges the transfers queued after it into
-- one action (queueList: one step per entry, light items of a kind moved up to 20 at a time) and resets its
-- progress for every step (Oct 19 2026, seen in game: a six-item move read 1/1)
local function itemsOf(a)
    local ql = a.queueList
    if type(ql) == "table" and #ql > 0 then
        local n = 0
        for _, v in ipairs(ql) do n = n + ((type(v) == "table" and type(v.items) == "table") and #v.items or 1) end
        return n
    end
    return 1
end
-- the items left in the job: the current action's and those of the same kind queued after it (walks skipped)
local function remaining(list, typ)
    local n = 0
    for i = 1, #list do
        local a = list[i]
        if a.Type == typ then n = n + itemsOf(a)
        elseif not WALKS[a.Type] then break end
    end
    return n
end
AB.itemsOf, AB.remaining = itemsOf, remaining

-- the state for one player, or nil when nothing shows
function AB.state(chr, pn)
    local q = queueOf(chr)
    local list = q and q.queue or nil
    local cur = list and list[1] or nil
    local now = nowMs()
    if not cur then
        AB._jobs[pn] = nil
        return nil
    end
    -- walking there first: its own step; the job that follows keeps its count
    if WALKS[cur.Type] then
        local nextA = nil
        for i = 2, #list do if not WALKS[list[i].Type] then nextA = list[i]; break end end
        if not shows(cur) then return nil end
        -- a job already running (looting container after container) keeps its count through the walk
        local job = AB._jobs[pn]
        if job then job.walkFor = cur end
        return { phase = "walk", label = "WALKING", next = nextA and AB.label(nextA) or nil, item = "", noend = true,
                 frac = 0, qi = 0, qn = 1, el = 0 }
    end
    if not shows(cur) or not cur.action then return nil end
    -- an instant action (maxTime 0 or 1) never shows
    local mt = tonumber(cur.maxTime) or -1
    if mt >= 0 and mt <= 1 then return nil end
    local typ = cur.Type
    -- the job's total is what was left when it began, grown by anything queued since; done = total - left
    local rem = math.max(1, remaining(list, typ))
    local job = AB._jobs[pn]
    if job and job.type == typ and job.total then
        if rem > job.lastRem then job.total = job.total + (rem - job.lastRem) end
        job.walkFor = nil
    else
        job = { type = typ, total = rem, startMs = now }
        AB._jobs[pn] = job
    end
    job.lastRem = rem
    local done = math.max(0, job.total - rem)
    local st = { phase = "work", label = AB.label(cur), item = AB.itemName(cur), noend = noEnd(cur),
                 frac = delta(cur), qi = done, qn = math.max(1, job.total), el = (now - (cur._zedStartMs or job.startMs)) / 1000 }
    if st.noend then st.frac = 0; st.qn = 1; st.qi = 0 end
    return st
end

-- perform / stop: the end of the job (a perform with more of the same queued is not an end)
function AB.onEnded(action, kind)
    local chr = action and action.character
    if not chr or not instanceof(chr, "IsoPlayer") or not chr:isLocalPlayer() then return end
    if not shows(action) then return end
    local pn = playerNumOf(chr)
    if pn == nil then return end
    local last = AB._last[pn]
    if not last then return end
    if kind == "done" then
        local q = queueOf(chr)
        local list = q and q.queue or {}
        -- vanilla has already moved on: the next action of the same kind continues the job
        for i = 1, #list do
            local a = list[i]
            if a ~= action and a.Type == action.Type then return end
            if a ~= action and not WALKS[a.Type] then break end
        end
        if WALKS[action.Type] then return end      -- a walk that arrives is not the job's end
    end
    if kind == "stopped" and not action:isStarted() then return end
    local st = {}
    for k, v in pairs(last) do st[k] = v end
    if QUIET[action.Type] then st.phase = "gone"
    elseif kind == "done" then st.phase = "done"; st.frac = 1; st.qi = math.max(0, (st.qn or 1) - 1)
    else st.phase = "stopped" end
    AB._ends[pn] = { ms = nowMs(), st = st }
    AB._jobs[pn] = nil
end

-- how strongly an end state still shows, 1 -> 0 (nil when it is over)
local function endAlpha(e)
    local t = nowMs() - e.ms
    if e.st.phase == "gone" then
        if t > AB.QUIET_FADE then return nil end
        return 1 - t / AB.QUIET_FADE
    end
    if t <= AB.END_HOLD then return 1 end
    if t > AB.END_HOLD + AB.END_FADE then return nil end
    return 1 - (t - AB.END_HOLD) / AB.END_FADE
end

-- ---------------------------------------------------------------------------
-- the setting
-- ---------------------------------------------------------------------------
function AB.mode()
    local opt = ZeD.Settings and ZeD.Settings.actionBarOption
    local v = opt and opt.getValue and opt:getValue() or 1
    return v == 2 and "simple" or "verbose"
end

-- ---------------------------------------------------------------------------
-- drawing (design units on the canvas; colours from ZeD.T, read fresh every frame)
-- ---------------------------------------------------------------------------
local function R(cv, x, y, w, h, c, a) P.rect(cv, x, y, w, h, c, (c.a or 1) * (a or 1)) end

-- sizes, so the element can be placed before it draws
function AB.sizeSimple() return 53, 9 end
function AB.verboseText(st)
    local L1 = st.phase == "stopped" and "STOPPED" or st.phase == "done" and "DONE" or st.label
    local R1 = ""
    if st.qn > 1 and st.phase ~= "walk" then R1 = tostring(st.phase == "done" and st.qn or st.qi + 1) .. "/" .. tostring(st.qn) end
    local L2, R2 = "", ""
    if st.phase == "walk" then L2 = st.next and ("THEN " .. st.next) or "" else L2 = st.item or "" end
    if st.phase == "work" or st.phase == "stopped" then
        if st.noend then R2 = string.format("%d:%02d", math.floor((st.el or 0) / 60), math.floor((st.el or 0) % 60))
        else R2 = tostring(math.floor((st.frac or 0) * 100)) .. "%" end
    end
    if st.phase == "done" then R2 = "100%" end
    if st.phase == "walk" then R2 = "" end
    return L1, R1, L2, R2
end
function AB.sizeVerbose(st)
    local L1, R1, L2, R2 = AB.verboseText(st)
    local w1 = P.textWidth(L1, "57", 1) + (R1 ~= "" and 6 + P.textWidth(R1, "57", 1) or 0)
    local w2 = P.textWidth(L2, "35", 1) + (R2 ~= "" and 6 + P.textWidth(R2, "35", 1) or 0)
    return math.max(60, 4 + math.max(w1, w2) + 4), 24
end
local function overall(st) return st.qn > 1 and (st.qi + st.frac) / st.qn or st.frac end

function AB.drawSimple(cv, T, st, a, ms)
    local n, sw, sh, gap = 10, 4, 5, 1
    local W, H = AB.sizeSimple()
    R(cv, 0, 0, W, H, T.base, a); R(cv, 1, 1, W - 2, H - 2, T.surf1, a)
    local function sx(i) return 2 + i * (sw + gap) end
    local function lit(i, c, f)
        R(cv, sx(i), 2, sw, sh, c, a * (f or 1))
        if c == T.accent then R(cv, sx(i), 2, sw, 1, T.accentBright, a * (f or 1)) end
    end
    for i = 0, n - 1 do R(cv, sx(i), 2, sw, sh, T.surf3, a) end
    if st.noend and st.phase ~= "stopped" then
        local c = st.phase == "walk" and AB._dim or T.accent
        local ph = (ms / 1200) % 2
        local pos = math.floor((ph < 1 and ph or 2 - ph) * (n - 1) + 0.5)
        lit(pos, c); if pos > 0 then lit(pos - 1, c, 0.35) end; if pos < n - 1 then lit(pos + 1, c, 0.35) end
    elseif st.phase == "done" then
        for i = 0, n - 1 do lit(i, T.positive) end
    else
        local full = math.floor(overall(st) * n)
        local c = st.phase == "stopped" and AB._dim or T.accent
        for i = 0, full - 1 do lit(i, c) end
        if st.phase == "work" and full < n then
            lit(full, c, 0.25 + 0.35 * (0.5 + 0.5 * math.sin(ms / 1000 * math.pi * 2 * 0.9)))
        end
    end
end

function AB.drawVerbose(cv, T, st, a, ms)
    local L1, R1, L2, R2 = AB.verboseText(st)
    local W, H = AB.sizeVerbose(st)
    local pad = 4
    R(cv, 0, 0, W, H, T.borderS, a); R(cv, 1, 1, W - 2, H - 2, T.surf1, a)
    local c1 = st.phase == "done" and T.positive or ((st.phase == "stopped" or st.phase == "walk") and AB._dim or T.accent)
    local rc = st.phase == "stopped" and AB._dim or T.text
    local lc = st.phase == "stopped" and AB._dim or AB._legend
    -- P.text draws its rects at alpha 1 with the colour's rgb: the colour's own alpha and
    -- the fade go through the layer's drawRect for just these calls
    local function txt(s, x, y, c, font, align)
        if s == "" then return end
        cv.el._zedAlpha = a * (c.a or 1)
        P.text(cv, s, x, y, c, font, 1, align, nil, nil)
        cv.el._zedAlpha = 1
    end
    txt(L1, pad, 3, c1, "57")
    txt(R1, W - pad, 3, rc, "57", "r")
    txt(L2, pad, 12, lc, "35")
    txt(R2, W - pad, 12, lc, "35", "r")
    local bx, by, bw = pad, 19, W - pad * 2
    R(cv, bx, by, bw, 2, T.surf3, a)
    if st.noend and st.phase ~= "stopped" then
        local seg = 12
        local span = bw + seg
        local p = ((ms / 1000 * 26) % span) - seg
        local x0, x1 = math.max(bx, math.floor(bx + p)), math.min(bx + bw, math.floor(bx + p) + seg)
        if x1 > x0 then R(cv, x0, by, x1 - x0, 2, st.phase == "walk" and AB._dim or T.accent, a) end
    else
        local c = st.phase == "done" and T.positive or (st.phase == "stopped" and AB._dim or T.accent)
        local f = st.phase == "done" and 1 or overall(st)
        R(cv, bx, by, math.floor(bw * f + 0.5), 2, c, a)
    end
    if st.qn > 1 and st.qn <= 24 and bw / st.qn >= 3 then
        for i = 1, st.qn - 1 do R(cv, bx + math.floor(bw * i / st.qn + 0.5), by, 1, 2, T.surf1, a) end
    end
end

-- ---------------------------------------------------------------------------
-- the layer: one small top-level element per local player, moved to the head
-- every frame; never takes the pointer
-- ---------------------------------------------------------------------------
ZeD_ActionBarLayer = ZeD_ActionBarLayer or ZeD_Panel:derive("ZeD_ActionBarLayer")

function ZeD_ActionBarLayer:new(playerNum)
    local o = ZeD_Panel:new(0, 0, 1, 1)
    setmetatable(o, self)
    self.__index = self
    o.playerNum = playerNum or 0
    o._zedLabel = "Action bar"
    o.anchorBottom, o.anchorRight = false, false
    o.keepOnScreen = false
    o.wantMouseEvents = false
    return o
end

function ZeD_ActionBarLayer:instantiate()
    ZeD_Panel.instantiate(self)
    pcall(function() self.javaObject:setConsumeMouseEvents(false) end)
end

function ZeD_ActionBarLayer:onMouseMove() return false end
function ZeD_ActionBarLayer:onMouseMoveOutside() end
function ZeD_ActionBarLayer:onMouseDown() return false end
function ZeD_ActionBarLayer:onMouseUp() return false end
function ZeD_ActionBarLayer:onRightMouseDown() return false end
function ZeD_ActionBarLayer:onRightMouseUp() return false end
function ZeD_ActionBarLayer:onMouseWheel() return false end

-- P.text draws with alpha 1; route its rects through the bar's fade
function ZeD_ActionBarLayer:drawRect(x, y, w, h, a, r, g, b)
    ISUIElement.drawRect(self, x, y, w, h, a * (self._zedAlpha or 1), r, g, b)
end

-- the multiple: ZeD's root scale as a whole number, times vanilla's size option (1-4)
function AB.k()
    local root = (ZeD.Scale and ZeD.Scale.root and ZeD.Scale.root()) or 1
    local opt = 1
    pcall(function() opt = getCore():getOptionActionProgressBarSize() or 1 end)
    return P.k(root) * math.max(1, math.min(4, opt))
end

-- the top of the head on screen (UI coordinates)
function AB.headScreen(pn, chr)
    local x, y, z = chr:getX(), chr:getY(), chr:getZ()
    local sx = isoToScreenX(pn, x, y, z + AB.HEAD_Z)
    local sy = isoToScreenY(pn, x, y, z + AB.HEAD_Z)
    return sx, sy
end

function ZeD_ActionBarLayer:prerender()
    local T = ZeD.T
    local pn = self.playerNum
    local chr = getSpecificPlayer(pn)
    self._drawSt = nil
    if not T or not chr or chr:isDead() or chr:isAsleep() then return end
    local ms = nowMs()
    local ok, st = pcall(AB.state, chr, pn)
    if not ok then st = nil end
    local a = 1
    if st then
        AB._last[pn] = st
        AB._ends[pn] = nil
    else
        local e = AB._ends[pn]
        if e then
            a = endAlpha(e)
            if a then st = e.st else AB._ends[pn] = nil end
        end
    end
    if not st or not a or a <= 0 then return end
    -- colours that are not tokens of their own, synced in place (no allocation per frame)
    AB._dim = AB._dim or {}; ZeD.colorSync(AB._dim, T.text, (T.text.a or 1) * 0.55)
    AB._legend = AB._legend or {}; ZeD.colorSync(AB._legend, T.text, (T.text.a or 1) * 0.70)
    local mode = AB.mode()
    local W, H
    if mode == "simple" then W, H = AB.sizeSimple() else W, H = AB.sizeVerbose(st) end
    local k = AB.k()
    local hx, hy = AB.headScreen(pn, chr)
    if not hx then return end
    local px = math.floor(hx - W * k / 2 + 0.5)
    local py = math.floor(hy - (AB.GAP + H) * k + 0.5)
    if self:getX() ~= px then self:setX(px) end
    if self:getY() ~= py then self:setY(py) end
    if self:getWidth() ~= W * k then self:setWidth(W * k) end
    if self:getHeight() ~= H * k then self:setHeight(H * k) end
    self._drawSt, self._drawA, self._drawMode, self._k, self._ms = st, a, mode, k, ms
end

function ZeD_ActionBarLayer:render()
    local st = self._drawSt
    if not st then return end
    local T = ZeD.T
    local cv = P.canvas(self, 0, 0, self._k)
    self._zedAlpha = 1
    if self._drawMode == "simple" then AB.drawSimple(cv, T, st, self._drawA, self._ms)
    else AB.drawVerbose(cv, T, st, self._drawA, self._ms) end
    self._zedAlpha = 1
end

-- ---------------------------------------------------------------------------
-- lifecycle: one layer per local player, behind the windows
-- ---------------------------------------------------------------------------
AB._layers = AB._layers or {}
function AB.install(playerNum)
    playerNum = playerNum or 0
    if AB._layers[playerNum] then return AB._layers[playerNum] end
    local layer = ZeD_ActionBarLayer:new(playerNum)
    layer:initialise()
    layer:addToUIManager()
    layer:setVisible(true)
    pcall(function() layer:backMost() end)
    AB._layers[playerNum] = layer
    print("[ZeD] ActionBar: layer installed for player " .. tostring(playerNum) .. " (" .. AB.mode() .. ")")
    return layer
end

Events.OnGameStart.Add(function() AB._layers = {}; AB._jobs = {}; AB._ends = {}; AB._last = {}; AB.install(0) end)
Events.OnCreatePlayer.Add(function(playerNum) if playerNum and playerNum > 0 then AB.install(playerNum) end end)

print("[ZeD] ActionBar: module loaded")
return AB
