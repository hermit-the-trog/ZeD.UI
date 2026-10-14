-- ZeD-UI/42/media/lua/client/ZeD/Overrides/InfoCards.lua
-- ============================================================================
-- OBJECT INFO HOOKS — HOOK_MAP rows 11 and 12
-- Vanilla's "Info" option on a generator, a campfire, a barbecue or fireplace
-- and a farm plot opens the ZeD object card in the World window's drawer
-- instead of the small vanilla info windows:
--   * the menu handlers (ISWorldObjectContextMenu.onInfoGenerator,
--     ISCampingMenu.onDisplayInfo, ISBBQMenu.onDisplayInfo,
--     ISFarmingMenu.onInfo) open the card at once: no walk, no info cursor;
--   * the info timed actions' perform is the fallback for any other caller.
-- Vanilla runs only when ZeD declines (no World window, object not found).
-- ============================================================================

require "ZeD/ObjectCards"
require "ZeD/ObjectCardPower"
require "ZeD/ObjectCardFire"
require "ZeD/ObjectCardFarm"

local OC = ZeD.ObjectCards

local function route(label, player, kind, obj)
    local ok, handled = pcall(OC.open, player, kind, obj)
    if not ok then print("[ZeD] InfoCards: " .. label .. " route failed: " .. tostring(handled)) end
    return ok and handled
end

-- Swap a menu handler: open the card, else run vanilla.
local function hookHandler(tbl, name, label, pick)
    if not (tbl and tbl[name]) or tbl["_zed_" .. name] then return end
    tbl["_zed_" .. name] = true
    local orig = tbl[name]
    tbl[name] = function(...)
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
