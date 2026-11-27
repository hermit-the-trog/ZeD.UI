-- ZeDUI/tools/qa/oc_animals_cards_sim.lua  (Nov 26 2026, Build; QA's map 2026-11-26_map_cards_farm_animals.md)
-- Loads the real ObjectCardTrough.lua, ObjectCardHutch.lua and ObjectCardHook.lua over stubs, with OC.backTo,
-- ZeD_ObjectCard:close and OC.tick cut out of the real ObjectCards.lua and the hutch card's way back cut out of
-- AnimalsTab.lua.
--   TG2  an emptied bag in the trough (feed 0.00, one item) is no Food tag; feed above 0 is
--   TG7  Add water opens the fluid card with the trough card as its way back; the fluid card's close and the end
--        of its work (t._returnNow) bring the trough card back (oc_fluid_sim checks the pour's end sets it)
--   HU4  carrying a hen to a full hutch or one with both doors shut: Put in stays, greyed, in the game's words
--   HU5  a bird's Info keeps the hutch card as the Animals page's way back; B and Back bring the card up again
--   HU7  the Birds head has words in every language; the egg count uses the game's "Eggs: %1"
--   HU8  the hutch card closes past 5 from the entry square by the game's DistToProper (open at 5, shut at 5.10)
--   HK4  Remove corpse asks first, and the pad opens on a part, or the close key, never on Remove
--   HK6  a part the animal never had (false) reads No with no Gather
--   HK7  with only bodies the hook will not take, Add corpse is greyed with the game's reason; it jumps to the
--        first row that can hang
-- Run from the repo root:  lua51 ZeDUI/tools/qa/oc_animals_cards_sim.lua
-- It prints FAIL lines and a last line "oc_animals_cards_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]oc_animals_cards_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local Z = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function done()
    print("oc_animals_cards_sim: " .. checks .. " checks, " .. failed .. " failed")
    os.exit(failed > 0 and 1 or 0)
end
local function readFile(p)
    local f = assert(io.open(p, "rb"))
    local s = f:read("*a"):gsub("\r\n", "\n")
    f:close()
    return s
end

-- ---------------------------------------------------------------------------
-- the game, as far as the three cards ask
-- ---------------------------------------------------------------------------
local function list(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end,
    isEmpty = function() return #t == 0 end } end
-- a permissive stub: any method returns 0
local ANY = setmetatable({}, { __index = function() return function() return 0 end end })
-- the game's words: these few read as their key, so a check can see which the card chose
local GAME_WORDS = { IGUI_PutAnimalInHutch_HutchFull = true, IGUI_PutAnimalInHutch_DoorsClosed = true,
    Tooltip_ButcherUI_CantAddThis = true, IGUI_No = true, IGUI_Yes = true }
function getTextOrNull(k) return GAME_WORDS[k] and k or nil end
function getText(k) return k end
function getTexture() return nil end
function getDebug() return false end
function getTimestampMs() return 1000 end
function require() end
function getCell() return { getGridSquare = function() return nil end } end
ItemTag = { CLEAN_STAINS = "CleanStains", BUTCHER_ANIMAL = "ButcherAnimal" }
Perks = { Butchering = "Butchering" }
function instanceof(o, cls) return type(o) == "table" and o._cls ~= nil and o._cls[cls] == true end

local Q = { queue = {} }
ISTimedActionQueue = { getTimedActionQueue = function() return Q end, add = function(a) Q.queue[#Q.queue + 1] = a end,
    isPlayerDoingAction = function() return #Q.queue > 0 end }

local function newSq(x, y)
    local sq = { x = x, y = y }
    function sq:getX() return self.x end
    function sq:getY() return self.y end
    function sq:getZ() return 0 end
    -- (the game's: the distance between the two squares' corners)
    function sq:DistToProper(o) local dx, dy = self.x - o:getX(), self.y - o:getY(); return math.sqrt(dx * dx + dy * dy) end
    return sq
end

-- the player
local player = { x = 100.5, y = 100.5, hand = nil, items = {}, knife = nil }
function player:getX() return self.x end
function player:getY() return self.y end
function player:getZ() return 0 end
function player:getVehicle() return nil end
function player:isDead() return false end
function player:getPlayerNum() return 0 end
function player:getCurrentSquare() return newSq(math.floor(self.x), math.floor(self.y)) end
function player:getPrimaryHandItem() return self.hand end
function player:getSecondaryHandItem() return nil end
function player:getPerkLevel() return 3 end
function player:getInventory()
    local me = self
    return {
        getAllEvalRecurse = function(_, fn)
            local out = {}
            for _, it in ipairs(me.items) do if fn(it) then out[#out + 1] = it end end
            return list(out)
        end,
        getAllWaterFluidSources = function() return list({}) end,
        getFirstWaterFluidSources = function() return nil end,
        getFirstCleaningFluidSources = function() return nil end,
        getFirstTagEvalRecurse = function(_, tag) if tag == "ButcherAnimal" then return me.knife end return nil end,
        FindAll = function() return list(me.corpses or {}) end,
    }
end
function getSpecificPlayer() return player end

-- ZeD: words as their key and arguments
local COL = { r = 1, g = 1, b = 1, a = 1 }
ZeD = { tr = function(k, ...)
    local s = k
    for _, v in ipairs({ ... }) do s = s .. "|" .. tostring(v) end
    return s
end, logOnce = function(k, err) print("logOnce " .. tostring(k) .. ": " .. tostring(err)) end }
ZeD.T = setmetatable({ px = function(n) return n end, fillBarH = 6, buttonH = 20 }, { __index = function() return COL end })
ZeD.TM = { MeasureStringX = function() return 10 end, getFontHeight = function() return 10 end }
ZeD.Atoms, ZeD.Molecules, ZeD.CraftingCore = ANY, ANY, { truncText = function(s) return s end }
ZeD.textCase = function(s) return s end
ZeD.Disclose = { setting = function() return "folded" end }

-- what the bodies draw: buttons by fid, section heads, and every string
local buttons, sections, drawn, picks = {}, {}, {}, {}
local function clearDrawn() buttons, sections, drawn, picks = {}, {}, {}, {} end
local CARD = setmetatable({ drawText = function(_, s) drawn[#drawn + 1] = tostring(s) end,
    focusOf = function() return nil end, getHeight = function() return 800 end, _hookAvatar = false, _viewY = 0, _viewH = 800 }, { __index = function() return function() return 0 end end })

-- ObjectCards: the call helper, the registry and the pieces the cards use
local function call(o, m, ...)
    if o == nil then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end
local opened = {}
local currentEntry = nil
local OC = { kinds = {}, LEASH = 6, REFRESH = 15, BROWSE_EVERY = 60, DOT = "|", call = call }
OC.ui = setmetatable({
    button = function(_, _, _, label, o) buttons[o.fid or label] = o; return 0 end,
    section = function(_, _, _, _, a, b) sections[#sections + 1] = { a, b }; return 10 end,
    pick = function(_, _, _, _, o) picks[o.fid] = o; return 10 end,
    buttonW = function() return 10 end, tagW = function() return 10 end,
}, { __index = function() return function() return 0 end end })
function OC.register(def) OC.kinds[def.id] = def end
function OC.keyOf(sq, k) return k .. ":" .. sq:getX() .. "," .. sq:getY() end
function OC.whereOf() return "Inventory" end
function OC.spriteIcon() return nil end
function OC.sortTargets(t) return t end
function OC.eachSquare() end
function OC.squareDist(p, sq) local dx, dy = sq:getX() + 0.5 - p:getX(), sq:getY() + 0.5 - p:getY(); return math.sqrt(dx * dx + dy * dy) end
function OC.current() return currentEntry end
function OC.open(p, kind, obj, back) opened[#opened + 1] = { kind = kind, obj = obj, back = back }; return true end
ZeD.ObjectCards = OC

local ocSrc = readFile(Z .. "ObjectCards.lua")
local fBack = ocSrc:match("\n(function OC%.backTo%(.-\nend)\n")
local fClose = ocSrc:match("\n(function ZeD_ObjectCard:close%(.-\nend)\n")
local fTick = ocSrc:match("\n(local function sixtieths%(.-\nfunction OC%.tick%(.-\nend)\n")
check("OC.backTo, ZeD_ObjectCard:close and OC.tick are found in ObjectCards.lua", fBack and fClose and fTick)
if not (fBack and fClose and fTick) then done() end
local reopened, closedOut = {}, 0
ZeD_WorldWindow = {
    openObjectCard = function(pn, entry) reopened[#reopened + 1] = entry; return true end,
    closeObjectCard = function() closedOut = closedOut + 1 end,
}
ZeD_ObjectCard = {}
assert(loadstring("local OC, call = ...\n" .. fBack .. "\n" .. fClose .. "\n" .. fTick, "ObjectCards cut"))(OC, call)

-- the three real cards
for _, f in ipairs({ "ObjectCardTrough.lua", "ObjectCardHutch.lua", "ObjectCardHook.lua" }) do
    assert(loadstring(readFile(Z .. f), f))()
end
local trough, hutch, hook = OC.kinds.trough, OC.kinds.hutch, OC.kinds.hook
check("the trough, hutch and hook cards register", trough and hutch and hook)
if not (trough and hutch and hook) then done() end
local function verb(t, id) for _, v in ipairs(t.verbs or {}) do if v.id == id then return v end end end
local function has(s) for _, d in ipairs(drawn) do if d == s then return true end end return false end

-- ---------------------------------------------------------------------------
-- TG2 and TG7: the trough
-- ---------------------------------------------------------------------------
local bag = { _cls = { InventoryItem = true }, getFullType = function() return "Base.AnimalFeedBag" end,
    getDisplayName = function() return "Animal Feed" end, getTex = function() return nil end, isEquipped = function() return false end }
local feedAmt = 0
local troughFC = { isEmpty = function() return true end, getAmount = function() return 0 end }
local tro = { _cls = { IsoFeedingTrough = true }, sq = newSq(103, 100) }
function tro:getSquare() return self.sq end
function tro:getContainer() return { getItems = function() return list({ bag }) end } end
function tro:getCurrentFeedAmount() return feedAmt end
function tro:getFluidContainer() return troughFC end
function tro:getWater() return 0 end
function tro:getMaxWater() return 50 end
function tro:getObjectIndex() return 1 end
ISFluidContainer = { new = function(_, fc) return { fc = fc } end }
local tt = { obj = tro, sq = tro.sq, key = "trough" }
trough.refresh(tt, player)
local pill = trough.pill(tt)
check("TG2: an emptied bag (feed 0.00, one item) is no Food tag", pill ~= "UI_ZeD_Trough_PillFood", pill)
feedAmt = 2.5
trough.refresh(tt, player)
check("TG2: with feed in it the tag reads Food", trough.pill(tt) == "UI_ZeD_Trough_PillFood", trough.pill(tt))

feedAmt = 0
tro.getContainer = function() return { getItems = function() return list({}) end } end
trough.refresh(tt, player)
local troughEntry = { def = trough, t = tt }
currentEntry = troughEntry
local water = verb(tt, "water")
check("TG7: an empty trough has Add water", water and water.enabled ~= false)
opened = {}
if water then water.run(player, tt) end
check("TG7: Add water opens the fluid card", #opened == 1 and opened[1].kind == "fluid")
check("TG7: the fluid card carries the trough card as its way back", opened[1] and opened[1].back == troughEntry)

-- the fluid card's close (back key, B) brings the trough card back
local fluidEntry = { def = { id = "fluid", valid = function() return true end }, t = {}, back = troughEntry }
local card = setmetatable({ entry = fluidEntry, playerNum = 0 }, { __index = ZeD_ObjectCard })
reopened, closedOut = {}, 0
card:close()
check("TG7: closing the fluid card brings the trough card back", #reopened == 1 and reopened[1] == troughEntry and closedOut == 0)
-- a card with no way back closes as before
card.entry = { def = fluidEntry.def, t = {} }
reopened, closedOut = {}, 0
card:close()
check("TG7: a card with no way back just closes", #reopened == 0 and closedOut == 1)
-- the way back to a card whose object is gone closes as before
card.entry = { def = fluidEntry.def, t = {}, back = { def = { valid = function() return false end }, t = {} } }
reopened, closedOut = {}, 0
card:close()
check("TG7: a way back to a card that is gone closes instead", #reopened == 0 and closedOut == 1)
-- the end of the fluid card's work (t._returnNow) closes it from the tick, which goes back
local tick = OC.tick
local e = { def = { id = "fluid", valid = function() return true end, refresh = function() end }, t = { _returnNow = true }, back = troughEntry }
local alive = tick(e, player)
check("TG7: the tick ends the card once its work is done and a card waits", alive == false)
e = { def = e.def, t = { _returnNow = true } }
check("TG7: with no card waiting the tick keeps it", tick(e, player) == true)

-- ---------------------------------------------------------------------------
-- HU4, HU5, HU7, HU8: the hutch
-- ---------------------------------------------------------------------------
local hen = { _cls = {}, getFullName = function() return "Hen" end, getAnimalType = function() return "hen" end,
    isDead = function() return false end, canBePutInHutch = function() return true end }
player.hand = { _cls = { AnimalInventoryItem = true }, getAnimal = function() return hen end }
local inside, open, hatch = {}, true, false
local hu = { _cls = { IsoHutch = true }, sq = newSq(110, 100), entry = newSq(110, 102) }
function hu:getSquare() return self.sq end
function hu:getEntrySq() return self.entry end
function hu:getObjectIndex() return 1 end
function hu:getSprite() return nil end
function hu:isOpen() return open end
function hu:isEggHatchDoorOpen() return hatch end
function hu:isAllDoorClosed() return not open and not hatch end
function hu:getMaxNestBox() return 3 end
function hu:getNestBox() return { getEggsNb = function() return 1 end } end
function hu:getAnimalInNestBox() return nil end
function hu:haveRoomForNewEggs() return true end
function hu:getMaxAnimals() return 20 end
function hu:getAnimal(i) return inside[i + 1] end
function hu:getHutchDirt() return 0 end
function hu:getAnimalInside() return list(inside) end
local th = { obj = hu, sq = hu.entry, key = "hutch" }
for i = 1, 20 do inside[i] = hen end
hutch.refresh(th, player)
local put = verb(th, "putin")
check("HU4: carrying a hen to a full hutch, Put in is still there", put ~= nil and put.sensible ~= false)
check("HU4: and greyed", put and put.enabled == false)
check("HU4: with the game's reason, Hutch full", put and put.needsLine == "IGUI_PutAnimalInHutch_HutchFull", put and put.needsLine)
inside = {}
open, hatch = false, false
hutch.refresh(th, player)
put = verb(th, "putin")
check("HU4: both doors shut: Put in greyed with the game's Doors closed", put and put.sensible ~= false and put.enabled == false
    and put.needsLine == "IGUI_PutAnimalInHutch_DoorsClosed", put and put.needsLine)
open = true
hutch.refresh(th, player)
put = verb(th, "putin")
check("HU4: room and a door open: Put in can run", put and put.enabled == true and put.needsLine == nil)

-- HU7: the egg count in the game's words
inside = { hen }
hutch.refresh(th, player)
clearDrawn()
hutch.body(CARD, 0, 0, 480, th, player)
local eggsHead, birdsHead
for _, s in ipairs(sections) do
    if s[1] == "Egg Laying Boxes" then eggsHead = s[2] end
    if s[1] == "UI_ZeD_Hutch_Birds" then birdsHead = s[1] end
end
check("HU7: the egg count uses the game's Eggs: %1", eggsHead == "IGUI_Hutch_EggsNb|4", eggsHead)
check("HU7: the Birds head is drawn", birdsHead ~= nil)
-- every language has the Birds head in its own words, and the dropped "%1 eggs" key is gone from the English
local TR = ROOT .. "42/media/lua/shared/Translate/"
local langs = { "AR", "CA", "CH", "CN", "CS", "DA", "DE", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT", "JP", "KO",
    "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
local missing = {}
for _, L in ipairs(langs) do
    local s = readFile(TR .. L .. "/UI.json")
    local v = s:match('"UI_ZeD_Hutch_Birds":%s*"([^"]*)"')
    local q = s:match('"UI_ZeD_Hook_QRemove":%s*"([^"]*)"')
    if not v or v == "" or v == "Birds" or not q or q == "" then missing[#missing + 1] = L end
end
check("HU7: UI_ZeD_Hutch_Birds (and the hook's new question) in every language", #missing == 0, table.concat(missing, ","))
check("HU7: no card asks for the old %1 eggs key", readFile(Z .. "ObjectCardHutch.lua"):find("UI_ZeD_Hutch_Eggs\"", 1, true) == nil)

-- HU5: Info hands the hutch card to the Animals page as its way back
local hutchEntry = { def = hutch, t = th }
currentEntry = hutchEntry
local setReturn = nil
local WIN = { _activeTab = "animals" }
ZeD_WorldWindow.getWindow = function() return WIN end
ZeD_WorldWindow.openTab = function() end
ZeD.AnimalsTab = { showAnimal = function() end, setReturnCard = function(w, entry, a) setReturn = { w = w, entry = entry, a = a } end }
local info
for fid, b in pairs(buttons) do if string.find(fid, ":info", 1, true) then info = b end end
check("HU5: the bird row has Info", info ~= nil)
if info then info.run(CARD, player) end
check("HU5: Info keeps the hutch card as the page's way back", setReturn and setReturn.entry == hutchEntry and setReturn.a == hen)

-- the page's side (cut from AnimalsTab.lua): B and Back bring the card up
local atSrc = readFile(Z .. "AnimalsTab.lua")
local fRet = atSrc:match("\n(function AT%.setReturnCard%(.-)\nAT%.navigateBack%s*=")
check("HU5: the Animals tab's way back is found", fRet ~= nil)
if fRet then
    local AT = {}
    local state = { view = "animal", animalRef = hen }
    local stepped = 0
    local function getState() return state end
    local function navigateBack() stepped = stepped + 1 end
    local function WPN() return 0 end
    assert(loadstring("local AT, getState, navigateBack, WPN = ...\n" .. fRet, "AnimalsTab cut"))(AT, getState, navigateBack, WPN)
    local win = {}
    AT.setReturnCard(win, hutchEntry, hen)
    local els = { { id = "animals:submode:ranch" }, { id = "animals:back:animal" }, { id = "x", onCancel = function() return "own" end } }
    AT.withReturn(win, els)
    check("HU5: every stop without its own B gets one", els[1].onCancel ~= nil and els[2].onCancel ~= nil and els[3].onCancel() == "own")
    reopened = {}
    local took = els[1].onCancel(win)
    check("HU5: B on the bird page brings the hutch card back", took == true and #reopened == 1 and reopened[1] == hutchEntry)
    -- the page's Back: the card first, once; then it steps back as before
    AT.setReturnCard(win, hutchEntry, hen)
    reopened, stepped = {}, 0
    AT.goBack(win)
    check("HU5: the page's Back brings the card back, not the zone page", #reopened == 1 and stepped == 0)
    reopened, stepped = {}, 0
    AT.goBack(win)
    check("HU5: with no card waiting, Back steps back as before", #reopened == 0 and stepped == 1)
    -- another animal on the page: the way back is gone
    AT.setReturnCard(win, hutchEntry, hen)
    state.animalRef = {}
    reopened = {}
    check("HU5: on another animal B does not bring the card", AT.backToCard(win) == false and #reopened == 0)
end

-- HU8: the leash is the game's: DistToProper past 5 from the entry square
local he = { def = hutch, t = th }
local function at(x, y) player.x, player.y = x + 0.5, y + 0.5; Q.queue = {}; he._held, he._wasIdle = nil, nil; return tick(he, player) end
check("HU8: 5 tiles from the entry square the card stays", at(115, 102) == true)
check("HU8: 5.10 from the entry square the card closes", at(115, 103) == false)
check("HU8: 3 tiles off it stays", at(112, 104) == true)
player.x, player.y = 100.5, 100.5

-- ---------------------------------------------------------------------------
-- HK4, HK6, HK7: the hook
-- ---------------------------------------------------------------------------
local parts = {}
ButcheringUtil = {
    updateCorpseDatas = function(dt, a) dt.leather, dt.blood, dt.head, dt.meat = parts.leather, parts.blood or 0, parts.head, parts.meat; return a ~= nil end,
    getBuckets = function() return list({}) end,
}
-- (the game's test: ISButcherHookUI:isCorpseValid reads only the corpse's mod data)
ISButcherHookUI = { isCorpseValid = function(_, c)
    local md = c:getModData()
    if not md then return false end
    if md.animalSize < 0.4 then return false end
    return not md.skeleton
end }
local carcass = { _cls = {}, getCustomName = function() return "" end, getFullName = function() return "Angus Cow" end,
    getModData = function() return {} end }
local onHook = carcass
local hk = { _cls = { IsoButcherHook = true }, sq = newSq(120, 100) }
function hk:getSquare() return self.sq end
function hk:getAnimal() return onHook end
function hk:isRemovingBlood() return false end
function hk:getUsingPlayer() return nil end
function hk:isExistInTheWorld() return true end
function hk:setLuaHook() end
local Bridge = ZeD_HookBridge
local function newHookT()
    local br = setmetatable({ hook = hk, chr = player, progressBar = { progress = 0 } }, Bridge)
    br.animal3D = hk:getAnimal()
    br:updateCorpseDatas()
    return { obj = hk, sq = hk.sq, key = "hook", bridge = br }
end
player.knife = { getDisplayName = function() return "Knife" end }

-- HK4: a carcass with leather and a knife
parts = { leather = true, blood = 0, head = true, meat = true }
local tk = newHookT()
hook.refresh(tk, player)
local rem = verb(tk, "remove")
check("HK4: Remove corpse asks first", rem and rem.confirm ~= nil and rem.danger == true)
local of = hook.openFocus and hook.openFocus(tk)
check("HK4: the pad opens on a part it can gather", of == "hook:leather", of)
parts = { leather = false, blood = 0, head = false, meat = false }
tk = newHookT()
hook.refresh(tk, player)
of = hook.openFocus and hook.openFocus(tk)
check("HK4: with nothing to gather the pad opens on the close key, not Remove", of == "oc:back", of)

-- HK6: leather false (the breed has none) reads No, no Gather
parts = { leather = false, blood = 0, head = true, meat = true }
tk = newHookT()
hook.refresh(tk, player)
clearDrawn()
hook.body(CARD, 0, 0, 480, tk, player)
check("HK6: a part the animal never had has no Gather", buttons["hook:leather"] == nil)
check("HK6: and reads the game's No, not Taken", has("IGUI_No") and not has("UI_ZeD_Hook_Taken"))
check("HK6: a part that is there keeps its Gather", buttons["hook:head"] ~= nil and buttons["hook:meat"] ~= nil)
of = hook.openFocus and hook.openFocus(tk)
check("HK6: the pad does not open on the missing part", of == "hook:head", of)

-- HK7: an empty hook with only a hen near (too small for the hook)
onHook = nil
local function corpse(name, size)
    return { _cls = { InventoryItem = true }, getDisplayName = function() return name end, getTex = function() return nil end,
        getModData = function() return { AnimalType = "x", animalSize = size } end }
end
player.corpses = { corpse("Dead Hen", 0.2) }
tk = newHookT()
hook.refresh(tk, player)
local add = verb(tk, "add")
check("HK7: with only a hen near, Add corpse is greyed", add and add.enabled == false)
check("HK7: with the game's reason", add and add.needsLine == "Tooltip_ButcherUI_CantAddThis", add and add.needsLine)
player.corpses = { corpse("Dead Hen", 0.2), corpse("Dead Cow", 1.0) }
tk = newHookT()
hook.refresh(tk, player)
add = verb(tk, "add")
check("HK7: a body the hook takes lights Add corpse", add and add.enabled == true and add.needsLine == nil)
check("HK7: and it jumps to that body's row", add and add.jump == "hook:hang:2", add and add.jump)
player.corpses = {}
tk = newHookT()
hook.refresh(tk, player)
add = verb(tk, "add")
check("HK7: no bodies at all: greyed, with the empty list's own lines", add and add.enabled == false and add.needsLine == nil)

done()
