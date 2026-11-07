-- ZeD-UI/42/media/lua/client/ZeD/WorldRoutes.lua
-- ============================================================================
-- WORLD DEVICES AND ANIMALS: WHERE THE GAME'S OWN WINDOWS GO (Nov 7 2026,
-- VANILLA_WINDOWS_20261107.md rows B1, B4, B5; the director: "ZeD's card now")
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
--                            for its window (10 tiles, ISRadioWindow:update).
--   animal(chr, animal)   -> World window, Animals tab, that animal's view
--   zone(chr, zone)       -> World window, Animals tab, that zone's view
--
-- Split screen: each ZeD window belongs to one player. A route for another
-- player while the window is that player's goes to the game's window.
-- With the controller the pair opens and the pad goes to the window, as the
-- D-pad wheels do (ZeD_DpadWheels.lua H.worldTab).
-- ============================================================================

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

local function worldWin()
    return ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow() or nil
end

local function charWin()
    return ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow() or nil
end

-- the pad goes to the window once the tab has been pressed (openTab presses it on a later tick)
function WR.padFollow(pn, getWin)
    if not isPad(pn) then return end
    local tries = 0
    local function tick()
        tries = tries + 1
        if tries < 3 then return end
        Events.OnTick.Remove(tick)
        local win = getWin()
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

-- true while the player is within the game's reach for this device's window
function WR.inReach(chr, dev)
    if not (chr and dev) then return false end
    local ok, x, y = pcall(placeOf, dev)
    if not (ok and x) then return false end
    local px, py = chr:getX(), chr:getY()
    return math.abs(px - x) < WR.REACH and math.abs(py - y) < WR.REACH
end

function WR.pin(chr, dev)
    WR.pins[pnOf(chr)] = dev
end

function WR.unpin(chr)
    WR.pins[pnOf(chr)] = nil
end

-- the Radio tab's world list (RadioTab.buildWorldRadios) with the pinned device added at the end when the 3 x 3
-- scan missed it; a pin out of reach is dropped, so walking back does not bring it again
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
    if not indexOf(RT.buildEquippedRadios(chr), item) then return false end   -- not carried where the tab looks
    if not freeFor(charWin(), chr) then return false end
    local pn = pnOf(chr)
    pairForPad(pn)
    local win = charWin()
    -- the list now, so the tab is on the strip for openTab's press (it rebuilds every 30 frames on its own)
    if win then win._radios = RT.buildEquippedRadios(chr) end
    if not ZeD_CharacterWindow.openTab(pn, "radio") then return false end
    win = charWin()
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
    if not freeFor(worldWin(), chr) then return false end
    if not WR.inReach(chr, dev) then return false end
    WR.pin(chr, dev)
    local pn = pnOf(chr)
    pairForPad(pn)
    if ZeD_WorldWindow.getObjectCard and ZeD_WorldWindow.getObjectCard() and ZeD_WorldWindow.closeObjectCard then
        ZeD_WorldWindow.closeObjectCard()
    end
    local win = worldWin()
    if win then
        -- the list now, so the tab is on the strip for openTab's press (it rebuilds every 30 frames on its own)
        win._radios = RT.buildWorldRadios(chr)
    end
    if not ZeD_WorldWindow.openTab(pn, "radio") then
        WR.unpin(chr)
        return false
    end
    win = worldWin()
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
    if not freeFor(worldWin(), chr) then return nil end
    local pn = pnOf(chr)
    pairForPad(pn)
    if ZeD_WorldWindow.getObjectCard and ZeD_WorldWindow.getObjectCard() and ZeD_WorldWindow.closeObjectCard then
        ZeD_WorldWindow.closeObjectCard()
    end
    if not ZeD_WorldWindow.openTab(pn, "animals") then return nil end
    return worldWin(), AT, pn
end

function WR.animal(chr, animal)
    if not (chr and animal) then return false end
    local win, AT, pn = animalsTab(chr)
    if not (win and AT.showAnimal) then return false end
    AT.showAnimal(win, animal)
    WR.padFollow(pn, worldWin)
    return true
end

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

-- the game's first-time livestock zone note goes with its own zone window: with ZeD's World window up for this
-- player (the zone routes above went there) it is not shown (no first-run pop-ups); asked for (force) it shows
function WR.skipZoneNote(pn, force)
    if force then return false end
    local win = worldWin()
    if not win then return false end
    local chr = getSpecificPlayer and getSpecificPlayer(pn or 0) or nil
    return chr ~= nil and win._playerObj == chr
end

return WR
