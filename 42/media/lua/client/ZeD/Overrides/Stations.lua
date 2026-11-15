-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Stations.lua
-- ============================================================================
-- STATION + CRAFTING WINDOW HOOKS (override, client)
-- Every vanilla way into a crafting surface lands in the World window:
--   * ISEntityUI.OpenWindow        — the station option in the world
--     right-click menu, the controller Interact prompt, clicking a big
--     multi-tile station: Craft tab bound to that bench or drying rack, or
--     any other station in the general view (StationGeneral.lua).
--   * ISOvenUITimedAction:perform  — "Stove settings" on an oven or a
--     microwave: Craft tab bound to the appliance.
--   * ISEntityUI.OpenHandcraftWindow — the crafting key, "craft with this
--     item", recipes in books and magazines: Craft tab, recipe selected.
--   * ISEntityUI.OpenBuildWindow   — the build key and build entries: Build
--     tab, recipe selected.
-- The vanilla windows never show. Vanilla runs only when ZeD declines (no
-- World window, or an entity that is not a station ZeD draws), and every time
-- while safe mode is on (SafeMode.lua). The hooks sit behind _zed*Hooked
-- flags, so a Lua reload never wraps the wrapper.
-- ============================================================================

require "ZeD/SafeMode"
require "ZeD/Stations"

local ST = ZeD.Stations

-- Select a recipe and / or prefill the search in a CraftingCore tab once its
-- state exists (the tab creates it on its first frame). pn: the player whose window opened the tab.
local function focusRecipe(stateKey, searchKey, recipe, itemString, pn)
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
        local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow(pn)
        local state = win and win[stateKey]
        if not state then return false end
        if text then
            local f = win[searchKey]
            if f and f.input then f.input:setText(text) end
            state.search = text
            state.filterDirty = true
        end
        if name then
            -- the card is the list's picked row: the list's category and an old search step aside, so the
            -- recipe's row shows (Show never hides the open card's recipe); a list that left it out closes
            -- the card (CraftingCore.refilter)
            state.activeCat = "all"
            if not text then
                local f = win[searchKey]
                if f and f.input then f.input:setText("") end
                state.search = ""
            end
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

-- (Nov 14 2026, punch list 208) the oven a menu's Turn on is for, by player number: { obj, at = ms }. Only an
-- oven that is off: Turn off leaves the windows as they are. A mark older than a minute (a walk cut short) is dropped.
local pendingOven = {}
local OVEN_MARK_MS = 60000
local function markOven(playerObj, obj)
    if not (playerObj and obj) or ZeD.Safe.on() then return end
    if not instanceof(obj, "IsoStove") then return end
    local okA, on = pcall(function() return obj:Activated() end)
    if okA and not on then pendingOven[playerObj:getPlayerNum()] = { obj = obj, at = getTimestampMs() } end
end
local function openMarkedOven(playerObj, obj)
    if not (playerObj and obj) then return end
    local pn = playerObj:getPlayerNum()
    local m = pendingOven[pn]
    if not m then return end
    pendingOven[pn] = nil
    if m.obj ~= obj or getTimestampMs() - m.at > OVEN_MARK_MS then return end
    -- (Nov 15 2026, pop-outs: with faces on, the oven's face pops out beside the player instead of the Craft tab)
    if ZeD.FacePop and ZeD.FacePop.open(playerObj, obj) then return end
    ST.open(playerObj, obj)
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
                -- (a station ZeD has no view of its own for opens the general one)
                local kind = ST.classify(ST.call(entity, "getMasterObject") or entity, true)
                if not ST.isEntityKind(kind) then return false end
                return ST.open(player, entity, true)
            end)
            if ok and handled then return end
            if not ok then print("[ZeD] Stations: OpenWindow route failed: " .. tostring(handled)) end
            return origOpenWindow(player, entity)
        end

        -- The crafting key, the controller wheel, "craft" entries in item menus
        -- and recipe books. A plain open (no recipe, no item) toggles like the
        -- vanilla key does.
        -- (Nov 14 2026, punch list 233: a station opened from the world on a controller (the A prompt "Coffee Machine",
        -- a menu's open option) showed its tab but left the pad outside the window. The World window takes the pad,
        -- on the tab's first stop, when the tab is up and nothing else holds the pad.)
        local function padTake(pn, plain)
            if not (JoypadState and JoypadState.players and JoypadState.players[pn + 1]) then return end
            local F = ZeD.Input and ZeD.Input.Focus
            local win = ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow(pn)
            if not (F and win and win:isVisible()) then return end
            if F.modalUp and F.modalUp(pn) then return end
            if F.getFocusedWindow(pn) ~= win then F.claimFocus(win) end
            if plain and F.focusSoon then F.focusSoon(win, "worldTabContent", function() return true end, 1) end   -- (a recipe asked for: focusRecipe lands on it)
        end
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
                padTake(player:getPlayerNum(), plain)
                focusRecipe("_craftState", "_craftSearch", recipe, itemString, player:getPlayerNum())
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
                padTake(player:getPlayerNum(), plain)
                focusRecipe("_buildState", "_buildSearch", recipe, itemString, player:getPlayerNum())
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
            -- (Nov 15 2026, pop-outs: with faces on, Stove settings pops the face out beside the player (FacePop.lua);
            -- faces off: the Craft tab, as before)
            local ok, handled = pcall(function()
                if ZeD.FacePop and ZeD.FacePop.open(self.character, obj) then return true end
                return ST.open(self.character, obj)
            end)
            if ok and handled then
                ISBaseTimedAction.perform(self)
                return
            end
            if not ok then print("[ZeD] Stations: oven route failed: " .. tostring(handled)) end
            return origPerform(self)
        end
    end

    -- (Nov 14 2026, punch list 208: Turn on from a menu opens the World window on the Craft tab, where the oven's
    -- controls are, once the walk is done. The menus' Turn on mark the oven; ISToggleStoveAction:perform opens it.
    -- The World window's own power button calls the handler's perform straight (ContainerControls), so it does not.)
    local Tog = ISLootWindowObjectControlHandler_StoveToggle
    if Tog and not Tog._zedHooked then
        Tog._zedHooked = true
        local origMenu = Tog.handleJoypadContextMenu
        Tog.handleJoypadContextMenu = function(self, context)
            local first = context and context.numOptions or 1
            local r = origMenu(self, context)
            if context and context.options then
                pcall(function()
                    for i = first, (context.numOptions or 1) - 1 do
                        local o = context.options[i]
                        if o and o.target == self and o.onSelect and not o._zedOven then
                            local pick = o.onSelect
                            o._zedOven = true
                            o.onSelect = function(h, ...)
                                if h then pcall(markOven, h.playerObj, h.object) end
                                return pick(h, ...)
                            end
                        end
                    end
                end)
            end
            return r
        end
    end
    if ISInventoryPage and ISInventoryPage.toggleStove and not ISInventoryPage._zedOvenHooked then
        ISInventoryPage._zedOvenHooked = true
        local origPageToggle = ISInventoryPage.toggleStove
        ISInventoryPage.toggleStove = function(self, ...)
            pcall(function()
                local inv = self.inventoryPane and self.inventoryPane.inventory
                markOven(getPlayer(), inv and inv:getParent())   -- (vanilla's toggle walks getPlayer())
            end)
            return origPageToggle(self, ...)
        end
    end
    if ISWorldObjectContextMenu and ISWorldObjectContextMenu.onToggleStove and not ISWorldObjectContextMenu._zedOvenHooked then
        ISWorldObjectContextMenu._zedOvenHooked = true
        local origWorldToggle = ISWorldObjectContextMenu.onToggleStove
        ISWorldObjectContextMenu.onToggleStove = function(worldobjects, stove, player, ...)
            pcall(markOven, getSpecificPlayer(player), stove)
            return origWorldToggle(worldobjects, stove, player, ...)
        end
    end
    if ISToggleStoveAction and not ISToggleStoveAction._zedHooked then
        ISToggleStoveAction._zedHooked = true
        local origToggle = ISToggleStoveAction.perform
        function ISToggleStoveAction:perform()
            local r = origToggle(self)
            if not ZeD.Safe.on() then
                local ok, err = pcall(openMarkedOven, self.character, self.object)
                if not ok then print("[ZeD] Stations: oven turn-on route failed: " .. tostring(err)) end
            end
            return r
        end
    end

    print("[ZeD] Overrides/Stations: station, oven, crafting and build windows routed to the World window")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
