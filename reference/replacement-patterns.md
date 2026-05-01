# Replacement Patterns Reference

Detailed examples and injection points for replacing vanilla UI components in a total overhaul.

## The Three Strategies in Practice

### Hook and Modify — Full Example

Changing the inventory panel's visual appearance without replacing the component:

```lua
-- media/lua/client/ZeD/Hooks/InventoryHooks.lua

require "ISUI/ISInventoryPane"

-- Hook the constructor to inject your styling
local origNew = ISInventoryPane.new
function ISInventoryPane:new(x, y, width, height, inventory, zoom)
    local o = origNew(self, x, y, width, height, inventory, zoom)

    -- Override visual properties
    o.backgroundColor = ZeD.Tokens.bgPanel
    o.borderColor = ZeD.Tokens.border

    return o
end

-- Hook createChildren to add custom elements
local origCreateChildren = ISInventoryPane.createChildren
function ISInventoryPane:createChildren()
    origCreateChildren(self)

    -- Add a custom filter bar at the top
    self.filterBar = ZeD.FilterBar(0, 0, self.width, 28, self)
    self.filterBar:initialise()
    self:addChild(self.filterBar)

    -- Shift existing content down to make room
    -- (read the source to find what children exist and adjust)
end

-- Hook render to customize drawing
local origRender = ISInventoryPane.render
function ISInventoryPane:render()
    origRender(self)

    -- Add custom overlay drawing after vanilla render
    self:drawRectBorder(0, 0, self.width, self.height,
        ZeD.Tokens.border.a, ZeD.Tokens.border.r,
        ZeD.Tokens.border.g, ZeD.Tokens.border.b)
end
```

**Key points:**
- Store the original function reference BEFORE replacing it
- Always call the original inside your replacement
- You can hook `new`, `createChildren`, `render`, `update`, `prerender`, or any method
- This is additive — other mods' hooks still work

### Derive and Override — Full Example

Replacing the health panel with a completely new layout while keeping the data connections:

```lua
-- media/lua/client/ZeD/Windows/ZeD_HealthPanel.lua

require "ISUI/ISHealthPanel"

ZeD_HealthPanel = ISHealthPanel:derive("ZeD_HealthPanel")

function ZeD_HealthPanel:new(x, y, width, height, player)
    -- Call parent constructor to get all the data binding
    local o = ISHealthPanel:new(x, y, width, height, player)
    setmetatable(o, self)
    self.__index = self

    -- Your custom properties
    o.showCompact = false

    return o
end

function ZeD_HealthPanel:createChildren()
    -- DON'T call ISHealthPanel.createChildren(self) if you want
    -- a completely different child layout. But DO call the grandparent:
    ISPanel.createChildren(self)

    -- Build your own layout
    local y = ZeD.Tokens.padMD

    self.bodyOutline = ZeD.BodyOutline(ZeD.Tokens.padMD, y, 120, 200, self.player)
    self.bodyOutline:initialise()
    self:addChild(self.bodyOutline)

    self.injuryList = ZeD.InjuryList(140, y, self.width - 150, 200, self.player)
    self.injuryList:initialise()
    self:addChild(self.injuryList)
end

function ZeD_HealthPanel:render()
    -- Skip ISHealthPanel.render() entirely — your own rendering
    ISPanel.render(self)

    -- Custom draw calls using self.player body damage data
    local bodyDamage = self.player:getBodyDamage()
    -- Draw your custom health visualization
end

function ZeD_HealthPanel:update()
    ISHealthPanel.update(self)
    -- Keep the parent's data updating, add your own refresh logic
end
```

**Key points:**
- You inherit the parent's data model (self.player, body damage access, etc.)
- You can skip specific parent methods (like createChildren or render) and implement your own
- Always keep `update()` calling the parent so data stays fresh
- The tricky part is knowing which parent methods you need vs which you're replacing

### Full Replacement — Finding Injection Points

For a complete replacement, you need to find WHERE vanilla creates the component and intercept:

```lua
-- Step 1: Find the creation point
-- Grep for "ISHealthPanel:new" in the game source
-- You'll find it in something like ISUIHandler.lua or ISCharacterScreen.lua

-- Step 2: Hook the creation point
-- Example: if ISCharacterScreen creates the health panel in createChildren()

local origCreateChildren = ISCharacterScreen.createChildren
function ISCharacterScreen:createChildren()
    origCreateChildren(self)

    -- Find and remove the vanilla health panel
    if self.healthPanel then
        self:removeChild(self.healthPanel)
    end

    -- Add your replacement
    self.healthPanel = ZeD_HealthPanel:new(
        self.healthPanel and self.healthPanel:getX() or 0,
        self.healthPanel and self.healthPanel:getY() or 0,
        self.width, self.height, self.player
    )
    self.healthPanel:initialise()
    self.healthPanel:createChildren()
    self:addChild(self.healthPanel)
end
```

## Injection Points for Major Systems

### HUD Panels

Created during player initialization. Look for:
- `ISUIHandler.lua` — Main HUD orchestrator
- `Events.OnCreatePlayer` handlers
- `ISPlayerData` — Manages per-player UI references

The HUD includes: health indicator, moodle panel, hotbar, clock, compass, mini-map. Each is an ISPanel subclass added to the UI manager.

### Inventory System

Multi-layered. Key files:
- `ISInventoryPage.lua` — The main inventory container (holds inventory panes)
- `ISInventoryPane.lua` — Individual item grid/list view
- `ISInventoryTransferAction.lua` — Transfer logic
- `ISInventoryItem.lua` — Item rendering in the grid

The inventory is created by `ISPlayerData` and added to `ISInventoryPage`. It has left (player) and right (container/loot) panes.

### Character Info / Stats

Tab-based system. Look for:
- `ISCharacterScreen.lua` — Main character info window
- `ISCharacterInfo.lua` — Character info tab
- `ISHealthPanel.lua` — Health body view
- `ISSkillProgressBar.lua` — Skill display
- `ISMoodleUI.lua` — Moodle indicators

The character screen uses a tab panel. Each tab is a separate panel class. You can replace individual tabs without touching the container.

### Crafting

Entity-based in Build 42. Look for:
- `Entity/ISUI/Components/Crafting/` — Crafting UI components
- `ISCraftBenchUI.lua` — Craft bench window
- `ISCraftingUI.lua` — Main crafting interface

### Context Menus

Hook-based. You don't replace context menus — you add to them:
```lua
Events.OnFillWorldObjectContextMenu.Add(function(playerNum, context, worldobjects, test)
    if test then return end  -- Skip during test passes
    -- Add your options
    context:addOption(getText("UI_ZeD_CustomAction"), worldobjects, onCustomAction)
end)
```

### Modal Dialogs

Created on-demand throughout the codebase:
```lua
local modal = ISModalDialog:new(x, y, width, height, text, yesOption, self, onConfirm)
modal:initialise()
modal:addToUIManager()
```

To restyle modals, hook `ISModalDialog:new` and `ISModalDialog:createChildren`.

## B42.16 Strategy 4: LootWindow Handler Registration

New in B42.16. Instead of context menu options, register persistent buttons in the loot window UI. Best for object interactions that should always be visible when a container is open (campfire fuel, stove toggles, appliance controls).

```lua
require "ISUI/LootWindow/ISLootWindowObjectControlHandler"

ISLootWindowObjectControlHandler_MyAction = ISLootWindowObjectControlHandler:derive("ISLootWindowObjectControlHandler_MyAction")
local Handler = ISLootWindowObjectControlHandler_MyAction

function Handler:shouldBeVisible()
    return self.object and self.object:getTextureName() == "my_texture"
end

function Handler:perform()
    if isGamePaused() then return end
    ISTimedActionQueue.add(ISMyAction:new(self.playerObj, self.object))
end

function Handler:handleJoypadContextMenu(context)
    self:addJoypadContextMenuOption(context, getText("UI_MyAction"))
end

function Handler:new()
    local o = ISLootWindowObjectControlHandler.new(self)
    o.altColor = true  -- tinted = object action, not container action
    return o
end

-- Register: displayToRight=true anchors to lower-right of loot UI
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_MyAction, true)
```

**When to use this vs context menu**: If the action is always relevant when the object's container is open (like adding fuel to a lit campfire), use a handler. If the action is situational or one-time, use the ISMenuElement context menu pattern.

## B42.16 Strategy 5: ISMenuElement Context Menu Registration

New modular context menu system. Register elements with zIndex priority control:

```lua
ISWorldMenuElements.MyContextElement = function()
    local element = ISMenuElement.new()
    element.zIndex = 500  -- lower = higher in menu
    function element.createMenu(contextData)
        if myCondition(contextData.object) then
            contextData.context:addOption("My Option", contextData.objects, myCallback)
        end
    end
    return element
end
```

Loaded automatically by ISContextManager on OnGameStart. Elements are iterated in ascending zIndex order.

## Gamepad / Controller Support

Every interactive element you build needs gamepad support if PZ supports it:

- Use `ISButton` — has built-in focus and A/B button handling
- Set `self:setFocusable(true)` on custom panels that should receive gamepad focus
- Implement `onJoypadDown(button, player)` for custom input handling
- Register with `JoypadState.players[playerIndex].focus = myPanel` to claim focus
- `ISScrollingListBox` handles gamepad navigation automatically
- **B42.16**: Call `self.character:setJoypadIgnoreAimUntilCentered(true)` when opening any custom gamepad UI that uses the right stick — prevents aiming during menu navigation
- **B42.16**: Use `menu:setHideWhenButtonReleased(JoypadButton)` for radial menus that should close when the trigger button is released
- **B42.16**: Input events `OnKeyStartPressed`, `OnKeyKeepPressed`, `OnKeyPressed` are shared between KB+Mouse and Gamepad — use these for unified input handling

If you're replacing a vanilla component that had gamepad support, your replacement needs it too. Read the vanilla implementation to see what gamepad hooks it registers.

## Cross-Mod Compatibility

When building replacement hooks:

1. **Check before removing**: Make sure the element you're removing exists before calling `removeChild`
2. **Use unique function names**: Don't shadow common names other mods might use
3. **Namespace globals**: Everything under `ZeD = ZeD or {}`
4. **Allow fallback**: If your hook fails, let the vanilla component through rather than breaking the UI
5. **Load order**: Use `require` to ensure dependencies load before your hooks. PZ loads alphabetically within each directory, but `require` forces explicit ordering.

```lua
-- Safe hook pattern with fallback
local origFunc = SomeClass.someMethod
function SomeClass.someMethod(self, ...)
    local success, result = pcall(function()
        return myReplacementLogic(self, ...)
    end)
    if success then
        return result
    else
        -- Log the error, fall back to vanilla
        print("ZeD-UI: Error in hook, falling back: " .. tostring(result))
        return origFunc(self, ...)
    end
end
```
