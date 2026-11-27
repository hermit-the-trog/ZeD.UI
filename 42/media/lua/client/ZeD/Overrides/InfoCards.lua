-- ZeD-UI/42/media/lua/client/ZeD/Overrides/InfoCards.lua
-- ============================================================================
-- OBJECT INFO HOOKS (override, client)
-- Vanilla's "Info" option on a generator, a campfire, a barbecue or fireplace
-- and a farm plot opens the ZeD object card in the World window's drawer
-- instead of the small vanilla info windows:
--   * the menu handlers (ISWorldObjectContextMenu.onInfoGenerator,
--     ISCampingMenu.onDisplayInfo, ISBBQMenu.onDisplayInfo,
--     ISFarmingMenu.onInfo) open the card at once when it is in reach, else
--     walk there first and open it on arrival (OC.openNear); no info cursor;
--   * the info timed actions' perform is the fallback for any other caller.
-- Vanilla runs only when ZeD declines (no World window, object not found),
-- and every time while safe mode is on (SafeMode.lua). Each hook sets a
-- _zed* flag before wrapping, so a Lua reload never wraps the wrapper.
-- ============================================================================

require "ZeD/SafeMode"
require "ZeD/ObjectCards"
require "ZeD/ObjectCardPower"
require "ZeD/ObjectCardFire"
require "ZeD/ObjectCardFarm"

local OC = ZeD.ObjectCards

-- The square the Info was asked about: the generator's, the campfire's (its Lua object or its tile), the plot's.
local function squareOf(obj)
    if not obj then return nil end
    local ok, sq = pcall(function() return obj:getSquare() end)
    if ok and sq then return sq end
    local okI, io = pcall(function() return obj:getIsoObject() end)
    if okI and io then
        local okS, s2 = pcall(function() return io:getSquare() end)
        if okS then return s2 end
    end
    return nil
end

local function route(label, player, kind, obj)
    -- (Nov 15 2026, the director: Info keeps opening the card, with the fuel, the condition and what it powers; a click
    -- on the machine or A at it pops the face out, FacePop.lua)
    -- (QA PW9 / FI9, Nov 26 2026) Info from past the card's reach opened it and the leash shut it on its first
    -- frame, with no walk: nothing at all happened. It goes through OC.openNear, as the fluid hook does (FL7):
    -- far off, he walks next to it and the card opens there; near, it opens at once. A path the game cannot
    -- find hands the call back to the game's own Info.
    local ok, handled = pcall(OC.openNear, player, kind, obj, squareOf(obj))
    if not ok then print("[ZeD] InfoCards: " .. label .. " route failed: " .. tostring(handled)) end
    return ok and handled
end

-- Swap a menu handler: open the card, else run vanilla.
local function hookHandler(tbl, name, label, pick)
    if not (tbl and tbl[name]) or tbl["_zed_" .. name] then return end
    tbl["_zed_" .. name] = true
    local orig = tbl[name]
    tbl[name] = function(...)
        if ZeD.Safe.on() then return orig(...) end   -- safe mode: vanilla's info window
        local player, kind, obj = pick(...)
        if player and obj and route(label, player, kind, obj) then return end
        return orig(...)
    end
end

-- Swap an info timed action's perform: open the card and finish the action.
local function hookPerform(cls, label, kind, objOf)
    if not cls or cls._zedInfoHooked then return end
    cls._zedInfoHooked = true
    local orig = cls.perform
    cls.perform = function(self)
        if ZeD.Safe.on() then return orig(self) end
        if route(label, self.character, kind, objOf(self)) then
            ISBaseTimedAction.perform(self)
            return
        end
        return orig(self)
    end
end

local function apply()
    -- generator
    hookHandler(ISWorldObjectContextMenu, "onInfoGenerator", "generator",
        function(worldobjects, generator, player) return getSpecificPlayer(player), "generator", generator end)
    hookPerform(ISGeneratorInfoAction, "generator", "generator", function(a) return a.object end)

    -- campfire (vanilla passes the Lua campfire where the IsoObject belongs)
    if ISCampingMenu then
        hookHandler(ISCampingMenu, "onDisplayInfo", "campfire",
            function(worldobjects, playerObj, isoCampfireObject, campfire) return playerObj, "fire", isoCampfireObject or campfire end)
    end
    hookPerform(ISCampingInfoAction, "campfire", "fire", function(a) return a.campfire or a.campfireTable end)

    -- barbecue / fireplace
    if ISBBQMenu then
        hookHandler(ISBBQMenu, "onDisplayInfo", "barbecue",
            function(worldobjects, player, bbq) return getSpecificPlayer(player), "fire", bbq end)
    end
    hookPerform(ISBBQInfoAction, "barbecue", "fire", function(a) return a.bbq end)

    -- farm plot
    if ISFarmingMenu then
        hookHandler(ISFarmingMenu, "onInfo", "plant",
            function(worldobjects, plant, sq, playerObj) return playerObj, "plant", plant end)
    end
    hookPerform(ISPlantInfoAction, "plant", "plant", function(a) return a.plant end)

    print("[ZeD] Overrides/InfoCards: generator, fire and farm plot info routed to the object card")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
