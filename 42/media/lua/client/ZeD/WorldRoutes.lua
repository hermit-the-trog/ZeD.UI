-- ZeD-UI/42/media/lua/client/ZeD/WorldRoutes.lua
-- ============================================================================
-- WORLD DEVICES AND ANIMALS: WHERE THE GAME'S OWN WINDOWS GO (client)
--
-- The routes that open the game's radio window, its animal info window and its
-- livestock zone window send the player to the ZeD surface that already shows
-- the same thing. The hooks live in Overrides/RadioWindow.lua (the radio window)
-- and Overrides/Animals.lua (animal info, Check zone); this file says where
-- each one goes and returns false whenever ZeD can't show it, so the caller
-- opens the game's window as before.
--
--   radio(chr, dev)       a TV, a house radio, a placed radio, a radio in the
--                         hands or on the back, a car's device part
--       * a radio item       -> Character window, Radio tab, on that radio
--       * the car's own radio, from a front seat -> the radio up close
--                            (ZeD_CarRadio.lua), as the vehicle wheel does
--       * anything else      -> World window, Radio tab, on that device. A
--                            device out of the tab's 3 x 3 reach (a TV across
--                            the room, a car's part) is pinned into the tab's
--                            list while it stays within the game's own reach
--                            for its window (10 tiles, ISRadioWindow:update),
--                            on the player's own floor only: going up or down
--                            stairs drops the pin, and a device on another
--                            floor opens nothing.
--   animal(chr, animal)   -> World window, Animals tab, that animal's view. An
--                            animal outside the ranch (no zone: a wild one, one
--                            in a trailer or a hutch outside a zone) keeps the
--                            game's reach for its window (ISAnimalUI: 5 tiles,
--                            4 from the hutch or trailer): past it, or once the
--                            animal is gone, the view steps back. Zone animals
--                            belong to the ranch, which ZeD shows from anywhere.
--   zone(chr, zone)       -> World window, Animals tab, that zone's view
--   zoneHelp(pn)          the game's first-time zone note, asked for from the
--                            zone view's help button: a ZeD note with the
--                            game's own words (IGUI_Animal_ZoneFirstInfo)
--
-- Split screen: each ZeD window belongs to one player. A route for another
-- player while the window is that player's goes to the game's window.
-- With the controller the pair opens and the pad goes to the window, as the
-- D-pad wheels do (ZeD_DpadWheels.lua H.worldTab).
-- ============================================================================

-- Kahlua has no next(); whether a table has any entry.
local function hasAny(t) if type(t) ~= "table" then return false end for _ in pairs(t) do return true end return false end
ZeD = ZeD or {}
ZeD.WorldRoutes = ZeD.WorldRoutes or {}
local WR = ZeD.WorldRoutes

-- the game's reach for a device's window (vanilla ISRadioWindow.lua: `local dist = 10`)
WR.REACH = 10

-- pinned devices, by player number: the device a route opened the tab on
WR.pins = WR.pins or {}

local function pnOf(chr)
    local ok, n = pcall(function() return chr:getPlayerNum() end)
    return ok and n or 0
end

local function isPad(pn)
    return JoypadState ~= nil and JoypadState.players ~= nil and JoypadState.players[pn + 1] ~= nil
end

-- the window is free for this player: closed, or already theirs
local function freeFor(win, chr)
    if not win then return true end
    local owner = win._playerObj
    return owner == nil or owner == chr
end
WR.freeFor = freeFor

-- player pn's windows (split view gives each local player their own; nil: the first player's)
local function worldWin(pn)
    return ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow(pn) or nil
end

local function charWin(pn)
    return ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow(pn) or nil
end

-- the pad goes to the window once the tab has been pressed (openTab presses it on a later tick)
function WR.padFollow(pn, getWin)
    if not isPad(pn) then return end
    local tries = 0
    local function tick()
        tries = tries + 1
        if tries < 3 then return end
        Events.OnTick.Remove(tick)
        local win = getWin(pn)
        local F = ZeD.Input and ZeD.Input.Focus
        if win and F and F.claimFocus then pcall(F.claimFocus, win) end
    end
    Events.OnTick.Add(tick)
end

local function pairForPad(pn)
    if isPad(pn) and ZeD_CharacterWindow and ZeD_CharacterWindow.ensureBothOpenForGamepad then
        pcall(ZeD_CharacterWindow.ensureBothOpenForGamepad, pn)
    end
end

-- ---------------------------------------------------------------------------
-- PINS: a device the Radio tab's 3 x 3 scan does not reach, kept in the World
-- window's list while the player is within the game's reach for its window
-- ---------------------------------------------------------------------------

local function isPart(dev) return instanceof(dev, "VehiclePart") end

-- where a device is, or nil when it has left the world (a set picked up, a radio
-- taken out of its car)
local function placeOf(dev)
    if isPart(dev) then
        local v = dev:getVehicle()
        if not v then return nil end
        local types = dev:getItemType()
        if types and not types:isEmpty() and not dev:getInventoryItem() then return nil end
        return dev:getX(), dev:getY()
    end
    if not dev:getSquare() then return nil end
    return dev:getX(), dev:getY()
end

-- the floor a device or the player is on (a whole number), or nil
local function floorOf(o)
    local ok, z = pcall(function() return o:getZ() end)
    if not (ok and type(z) == "number") then return nil end
    return math.floor(z)
end
WR.floorOf = floorOf

-- true when the device is on the player's floor (the game's window checks x and y only);
-- a floor that can't be read leaves the game's x and y reach alone
function WR.sameFloor(chr, dev)
    local pz, dz = floorOf(chr), floorOf(dev)
    if pz == nil or dz == nil then return true end
    return pz == dz
end

-- true while the player is within the game's reach for this device's window, on the same floor
function WR.inReach(chr, dev)
    if not (chr and dev) then return false end
    local ok, x, y = pcall(placeOf, dev)
    if not (ok and x) then return false end
    if not WR.sameFloor(chr, dev) then return false end
    local px, py = chr:getX(), chr:getY()
    return math.abs(px - x) < WR.REACH and math.abs(py - y) < WR.REACH
end

-- a pin drops as soon as its player leaves its floor or the reach, whether or not the World window is drawing
-- the tab (its list asks only while it is): one watcher on the player's update while any pin is held
local watching = false
local function watchPins(chr)
    if chr then
        local pn = pnOf(chr)
        local dev = WR.pins[pn]
        if dev and not WR.inReach(chr, dev) then WR.pins[pn] = nil end
    end
    if not hasAny(WR.pins) and watching then
        watching = false
        if Events and Events.OnPlayerUpdate then Events.OnPlayerUpdate.Remove(watchPins) end
    end
end
WR.watchPins = watchPins

function WR.pin(chr, dev)
    WR.pins[pnOf(chr)] = dev
    if not watching and Events and Events.OnPlayerUpdate then
        watching = true
        Events.OnPlayerUpdate.Add(watchPins)
    end
end

function WR.unpin(chr)
    WR.pins[pnOf(chr)] = nil
end

--- The Radio tab's world list (RadioTab.buildWorldRadios) with the pinned device added at the end when the 3 x 3
--- scan missed it; a pin out of reach is dropped, so walking back does not bring it again.
function WR.addPinned(chr, out)
    if not chr then return out end
    local pn = pnOf(chr)
    local dev = WR.pins[pn]
    if not dev then return out end
    if not WR.inReach(chr, dev) then
        WR.pins[pn] = nil
        return out
    end
    for _, e in ipairs(out) do
        if e.radioInstance == dev then return out end
    end
    local okd, dd = pcall(function() return dev:getDeviceData() end)
    if not (okd and dd) then
        WR.pins[pn] = nil
        return out
    end
    local _, x, y = pcall(placeOf, dev)
    local dx, dy = (x or 0) - chr:getX(), (y or 0) - chr:getY()
    local key
    if isPart(dev) then
        local okk, k = pcall(function() return "v:" .. tostring(dev:getVehicle():getId()) .. ":" .. tostring(dev:getId()) end)
        key = okk and k or "v:?"
    else
        key = string.format("w:%d,%d,%d", math.floor(dev:getX()), math.floor(dev:getY()), math.floor(dev:getZ()))
    end
    out[#out + 1] = {
        radioInstance = dev,
        deviceData    = dd,
        locationTag   = isPart(dev) and "Vehicle" or "Floor",
        kind          = "world",
        distance      = math.sqrt(dx * dx + dy * dy),
        cacheKey      = key,
        pinned        = true,
    }
    return out
end

-- the entry's place in a radio list, or nil
local function indexOf(list, dev)
    for i, e in ipairs(list or {}) do
        if e.radioInstance == dev then return i end
    end
    return nil
end
WR.indexOf = indexOf

-- ---------------------------------------------------------------------------
-- THE RADIO WINDOW'S ROUTES
-- ---------------------------------------------------------------------------

-- a radio item in the hands or on the back: the Character window's Radio tab
local function radioItem(chr, item)
    local RT = ZeD.RadioTab
    if not (RT and RT.buildEquippedRadios and ZeD_CharacterWindow and ZeD_CharacterWindow.openTab) then return false end
    if not indexOf(RT.buildEquippedRadios(chr), item) then
        -- not in the hands or on the back: one in a bag or the inventory is pinned for the tab (RadioTab lists it
        -- as "Carried" while it stays on the player); one on the floor or in a world container is not ours
        local okC, mine = pcall(function()
            local c = item:getContainer()
            return c ~= nil and c:isInCharacterInventory(chr)
        end)
        if not (okC and mine) then return false end
        RT._carried = RT._carried or {}
        RT._carried[pnOf(chr)] = item
        if not indexOf(RT.buildEquippedRadios(chr), item) then return false end
    end
    local pn = pnOf(chr)
    if not freeFor(charWin(pn), chr) then return false end
    pairForPad(pn)
    local win = charWin(pn)
    -- the list now, so the tab is on the strip for openTab's press (it rebuilds every 30 frames on its own)
    if win then win._radios = RT.buildEquippedRadios(chr) end
    if not ZeD_CharacterWindow.openTab(pn, "radio") then return false end
    win = charWin(pn)
    if not win then return false end
    win._radios = RT.buildEquippedRadios(chr)
    win._radioIdx = indexOf(win._radios, item) or 1
    win._radioFollow = item
    WR.padFollow(pn, charWin)
    return true
end

-- a device in the world or a car's part: the World window's Radio tab
local function worldDevice(chr, dev)
    local RT = ZeD.RadioTab
    if not (RT and RT.buildWorldRadios and ZeD_WorldWindow and ZeD_WorldWindow.openTab) then return false end
    if not freeFor(worldWin(pnOf(chr)), chr) then return false end
    -- another floor: nothing opens (the game's window would, as its reach reads x and y only)
    local okp, px = pcall(placeOf, dev)
    if okp and px and not WR.sameFloor(chr, dev) then return true end
    if not WR.inReach(chr, dev) then return false end
    WR.pin(chr, dev)
    local pn = pnOf(chr)
    pairForPad(pn)
    if ZeD_WorldWindow.getObjectCard and ZeD_WorldWindow.getObjectCard(pn) and ZeD_WorldWindow.closeObjectCard then
        ZeD_WorldWindow.closeObjectCard(pn)
    end
    local win = worldWin(pn)
    if win then
        -- the list now, so the tab is on the strip for openTab's press (it rebuilds every 30 frames on its own)
        win._radios = RT.buildWorldRadios(chr)
    end
    if not ZeD_WorldWindow.openTab(pn, "radio") then
        WR.unpin(chr)
        return false
    end
    win = worldWin(pn)
    if not win then
        WR.unpin(chr)
        return false
    end
    win._radios = RT.buildWorldRadios(chr)
    win._radioIdx = indexOf(win._radios, dev) or 1
    win._radioFollow = dev
    WR.padFollow(pn, worldWin)
    return true
end

-- the car's own radio from a front seat: the radio up close (as the vehicle wheel's Device Options slice does)
local function carRadio(chr, part)
    local O, CR = ZeD.RadioOps, ZeD.CarRadio
    if not (O and O.reachable and CR and CR.toggle) then return false end
    if part:getId() ~= "Radio" or O.reachable(chr) ~= part then return false end
    local ok, err = pcall(CR.toggle, chr, part)
    if not ok then print("[ZeD] WorldRoutes: the car radio could not come up close: " .. tostring(err)) end
    return ok
end

--- The game's radio window for dev, sent to ZeD's card (the header's radio
--- routes). True when ZeD took it (a device on another floor opens nothing at
--- all); false opens the game's window instead.
function WR.radio(chr, dev)
    if not (chr and dev) then return false end
    if instanceof(dev, "Radio") then return radioItem(chr, dev) end
    if isPart(dev) then
        if carRadio(chr, dev) then return true end
        return worldDevice(chr, dev)
    end
    if instanceof(dev, "IsoWaveSignal") then return worldDevice(chr, dev) end
    return false
end

-- ---------------------------------------------------------------------------
-- ANIMALS: the info window and Check zone
-- ---------------------------------------------------------------------------

local function animalsTab(chr)
    local AT = ZeD.AnimalsTab
    if not (AT and ZeD_WorldWindow and ZeD_WorldWindow.openTab) then return nil end
    local pn = pnOf(chr)
    if not freeFor(worldWin(pn), chr) then return nil end
    pairForPad(pn)
    if ZeD_WorldWindow.getObjectCard and ZeD_WorldWindow.getObjectCard(pn) and ZeD_WorldWindow.closeObjectCard then
        ZeD_WorldWindow.closeObjectCard(pn)
    end
    if not ZeD_WorldWindow.openTab(pn, "animals") then return nil end
    return worldWin(pn), AT, pn
end

-- the game's reach for its animal window (ISAnimalUI:prerender): 5 tiles from the animal (ISAnimalUI.maxDist),
-- 4 from the hutch or the trailer it is in; a held animal stays; a dead or gone one does not. The debug cheat
-- lifts it, as it does the game's.
WR.ANIMAL_REACH = 5
WR.ANIMAL_REACH_IN = 4

local function dist2d(chr, o)
    local dx, dy = o:getX() - chr:getX(), o:getY() - chr:getY()
    return math.sqrt(dx * dx + dy * dy)
end

function WR.animalInReach(chr, animal)
    if not (chr and animal) then return false end
    if AnimalContextMenu and AnimalContextMenu.cheat then return true end
    local ok, inReach = pcall(function()
        if animal:getHealth() <= 0 then return false end
        local hutch = animal:getHutch()
        if hutch then
            local sq = hutch:getSquare()
            return sq ~= nil and dist2d(chr, sq) <= WR.ANIMAL_REACH_IN
        end
        local veh = animal:getVehicle()
        if veh then return dist2d(chr, veh) <= WR.ANIMAL_REACH_IN end
        if animal:isHeld() then return true end
        if not animal:isExistInTheWorld() then return false end
        local maxD = (ISAnimalUI and type(ISAnimalUI.maxDist) == "number") and ISAnimalUI.maxDist or WR.ANIMAL_REACH
        return dist2d(chr, animal) <= maxD
    end)
    return ok and inReach == true
end

-- an animal in a livestock zone belongs to the ranch, which ZeD shows from anywhere
local function hasZone(animal)
    local ok, dz = pcall(function() return animal:getDZone() end)
    return ok and dz ~= nil
end

--- The Animals tab asks each frame it draws an animal's view: true when the view must step back
--- (the player left the game's reach for that animal, or it is gone).
function WR.animalLeft(win, animal)
    local r = win and win._zedAnimalReach
    if not r then return false end
    if r.animal ~= animal then
        win._zedAnimalReach = nil   -- the player moved on to another animal in ZeD's own views: no reach
        return false
    end
    if WR.animalInReach(r.chr, animal) then return false end
    win._zedAnimalReach = nil
    return true
end

--- The game's animal info window, sent to the Animals tab's view of that animal. True when
--- ZeD showed it; false opens the game's window instead.
function WR.animal(chr, animal)
    if not (chr and animal) then return false end
    local win, AT, pn = animalsTab(chr)
    if not (win and AT.showAnimal) then return false end
    AT.showAnimal(win, animal)
    win._zedAnimalReach = (not hasZone(animal)) and { animal = animal, chr = chr } or nil
    WR.padFollow(pn, worldWin)
    return true
end

--- The game's livestock zone window (Check zone), sent to the Animals tab's view of that
--- zone. True when ZeD showed it; false opens the game's window instead.
function WR.zone(chr, zone)
    if not (chr and zone) then return false end
    local okn, name = pcall(function() return zone:getName() end)
    if not (okn and name) then return false end
    local win, AT, pn = animalsTab(chr)
    if not (win and AT.getState and AT.navigate) then return false end
    -- the summary is read from the poller's cache: a zone it has not seen yet (just drawn) is read in now
    local AP = ZeD.AnimalsAlertPoller
    if AP and AP.getZoneSummary and not AP.getZoneSummary(name) and AP.refreshCache then pcall(AP.refreshCache) end
    local state = AT.getState(win)
    state.submode = "ranch"
    state.animalRef = nil
    AT.navigate(win, "zone", name, nil)
    if isPad(pn) then win._animalsNavFocusTarget = "breadcrumb" end   -- as the zone card's A-press lands
    WR.padFollow(pn, worldWin)
    return true
end

--- The game's first-time zone note's opening line, for the help line over the zone view's help button: its words
--- up to the first <LINE>, the tags taken out (the whole note when it has no <LINE>); nil without the text.
function WR.zoneNoteLead()
    local t = getText and getText("IGUI_Animal_ZoneFirstInfo") or nil
    if type(t) ~= "string" or t == "" or t == "IGUI_Animal_ZoneFirstInfo" then return nil end
    local cut = string.find(t, "<LINE>", 1, true)
    if cut then t = string.sub(t, 1, cut - 1) end
    t = string.gsub(t, "<[^>]*>", " ")
    t = string.gsub(t, "%s+", " ")
    t = string.gsub(t, "^ ", "")
    t = string.gsub(t, " $", "")
    if t == "" then return nil end
    return t
end

--- The game's first-time zone note, asked for (the zone view's help button): a ZeD note with the
--- game's own words; the game's own note (forced) when ZeD's prompt can't be built.
function WR.zoneHelp(pn)
    pn = pn or 0
    local P = ZeD.Prompt
    if P and P.rich then
        local ok, err = pcall(function()
            local o = P.rich(0, 0, 0, 0, getText("IGUI_Animal_ZoneFirstInfo"), false, nil, nil, pn)
            o:initialise()
            o:addToUIManager()
            if isPad(pn) and getJoypadFocus and setJoypadFocus then
                o.prevFocus = getJoypadFocus(pn)
                setJoypadFocus(pn, o)
            end
        end)
        if ok then return true end
        print("[ZeD] WorldRoutes: the zone note kept the game's: " .. tostring(err))
    end
    if ISAnimalZoneFirstInfo and ISAnimalZoneFirstInfo.showUI then
        ISAnimalZoneFirstInfo.showUI(pn, true)
        return true
    end
    return false
end

--- The game's first-time livestock zone note goes with its own zone window: with ZeD's World window up for this
--- player (the zone routes above went there) it is not shown (no first-run pop-ups); asked for (force) it shows.
--- True: skip the game's note.
function WR.skipZoneNote(pn, force)
    if force then return false end
    local win = worldWin(pn)
    if not win then return false end
    local chr = getSpecificPlayer and getSpecificPlayer(pn or 0) or nil
    return chr ~= nil and win._playerObj == chr
end

return WR
