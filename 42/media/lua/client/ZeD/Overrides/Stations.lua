-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Stations.lua
-- ============================================================================
-- STATION + CRAFTING WINDOW HOOKS — HOOK_MAP rows 1 and 14
-- Every vanilla way into a crafting surface lands in the World window:
--   * ISEntityUI.OpenWindow        — the station option in the world
--     right-click menu, the controller Interact prompt, clicking a big
--     multi-tile station: Craft tab bound to that bench or drying rack.
--   * ISOvenUITimedAction:perform  — "Stove settings" on an oven or a
--     microwave: Craft tab bound to the appliance.
--   * ISEntityUI.OpenHandcraftWindow — the crafting key, "craft with this
--     item", recipes in books and magazines: Craft tab, recipe selected.
--   * ISEntityUI.OpenBuildWindow   — the build key and build entries: Build
--     tab, recipe selected.
-- The vanilla windows never show. Vanilla runs only when ZeD declines (no
-- World window, or an entity that is not a station ZeD draws), and every time
-- while safe mode is on (SafeMode.lua).
-- ============================================================================

require "ZeD/SafeMode"
require "ZeD/Stations"

local ST = ZeD.Stations

-- Select a recipe and / or prefill the search in a CraftingCore tab once its
-- state exists (the tab creates it on its first frame).
local function focusRecipe(stateKey, searchKey, recipe, itemString)
    local name = nil
    if recipe and recipe.getName then name = recipe:getName() end
    local text = nil
    if itemString and itemString ~= "" then
        local full = string.gsub(itemString, "^!", "")
        local sm = getScriptManager and getScriptManager()
        local sc = sm and sm:FindItem(full)
        text = (sc and sc:getDisplayName()) or full
    end
    if not name and not text then return end
    local function apply()
        local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
        local state = win and win[stateKey]
        if not state then return false end
        if text then
            local f = win[searchKey]
            if f and f.input then f.input:setText(text) end
            state.search = text
            state.filterDirty = true
        end
        if name then
            ZeD.CraftingCore.openCraft(state, name)
            state.filterDirty = true
        end
        return true
    end
    if not apply() then
        local tries = 0
        local function tick()
            tries = tries + 1
            if apply() or tries >= 30 then Events.OnTick.Remove(tick) end
        end
        Events.OnTick.Add(tick)
    end
end

local function apply()
    if not ISEntityUI then return end

    -- Station windows (benches, drying racks)
    if not ISEntityUI._zedStationsHooked then
        ISEntityUI._zedStationsHooked = true

        local origOpenWindow = ISEntityUI.OpenWindow
        ISEntityUI.OpenWindow = function(player, entity)
            if ZeD.Safe.on() then return origOpenWindow(player, entity) end   -- safe mode: vanilla's window
            local ok, handled = pcall(function()
                if not (player and entity) then return false end
                if not ISEntityUI.CanOpenWindowFor(player, entity) then return false end
                local kind = ST.classify(ST.call(entity, "getMasterObject") or entity)
                if not ST.isEntityKind(kind) then return false end
                return ST.open(player, entity)
            end)
            if ok and handled then return end
            if not ok then print("[ZeD] Stations: OpenWindow route failed: " .. tostring(handled)) end
            return origOpenWindow(player, entity)
        end

        -- The crafting key, the controller wheel, "craft" entries in item menus
        -- and recipe books. A plain open (no recipe, no item) toggles like the
        -- vanilla key does.
        local origHandcraft = ISEntityUI.OpenHandcraftWindow
        ISEntityUI.OpenHandcraftWindow = function(player, isoObject, queryOverride, ignoreFindSurface, recipe, itemString)
            if ZeD.Safe.on() then return origHandcraft(player, isoObject, queryOverride, ignoreFindSurface, recipe, itemString) end
            local ok, handled = pcall(function()
                if not player then return false end
                local cur = ST.current(player)
                if recipe and cur and not (cur.kind == "bench" and ST.recipeSet(cur)[recipe:getName()]) then
                    ST.unbind(player)
                end
                local plain = (recipe == nil) and (itemString == nil or itemString == "")
                if not (ZeD_WorldWindow and ZeD_WorldWindow.openTab) then return false end
                if not ZeD_WorldWindow.openTab(player:getPlayerNum(), "craft", plain) then return false end
                focusRecipe("_craftState", "_craftSearch", recipe, itemString)
                return true
            end)
            if ok and handled then return end
            if not ok then print("[ZeD] Stations: OpenHandcraftWindow route failed: " .. tostring(handled)) end
            return origHandcraft(player, isoObject, queryOverride, ignoreFindSurface, recipe, itemString)
        end

        local origBuild = ISEntityUI.OpenBuildWindow
        ISEntityUI.OpenBuildWindow = function(player, isoObject, queryOverride, ignoreFindSurface, recipe, itemString)
            if ZeD.Safe.on() then return origBuild(player, isoObject, queryOverride, ignoreFindSurface, recipe, itemString) end
            local ok, handled = pcall(function()
                if not player then return false end
                local plain = (recipe == nil) and (itemString == nil or itemString == "")
                if not (ZeD_WorldWindow and ZeD_WorldWindow.openTab) then return false end
                if not ZeD_WorldWindow.openTab(player:getPlayerNum(), "build", plain) then return false end
                focusRecipe("_buildState", "_buildSearch", recipe, itemString)
                return true
            end)
            if ok and handled then return end
            if not ok then print("[ZeD] Stations: OpenBuildWindow route failed: " .. tostring(handled)) end
            return origBuild(player, isoObject, queryOverride, ignoreFindSurface, recipe, itemString)
        end
    end

    -- Oven and microwave settings
    if ISOvenUITimedAction and not ISOvenUITimedAction._zedHooked then
        ISOvenUITimedAction._zedHooked = true
        local origPerform = ISOvenUITimedAction.perform
        function ISOvenUITimedAction:perform()
            if ZeD.Safe.on() then return origPerform(self) end
            local obj = self.mcwave or self.stove
            local ok, handled = pcall(function() return ST.open(self.character, obj) end)
            if ok and handled then
                ISBaseTimedAction.perform(self)
                return
            end
            if not ok then print("[ZeD] Stations: oven route failed: " .. tostring(handled)) end
            return origPerform(self)
        end
    end

    print("[ZeD] Overrides/Stations: station, oven, crafting and build windows routed to the World window")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
