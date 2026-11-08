# Entity/Component UI Reference

Build 42's entity system is the backbone for interactive world objects. This reference covers how entities connect to UI, what data you can access, and how to build custom entity windows.

## Entity Architecture

An entity is a world object (crafting bench, stove, generator, etc.) composed of modular components. Each component adds a capability:

| ComponentType | What it provides | UI relevance |
|--------------|-----------------|--------------|
| `UiConfig` | UI window class, style, positioning | Determines WHICH window opens |
| `CraftBench` | Crafting recipes, skill requirements | Recipe list, progress bars |
| `Resources` | Item storage slots | Slot grids, item display |
| `FluidContainer` | Liquid storage, capacity | Fill bars, fluid type display |
| `ContextMenuConfig` | Custom context menu entries | Menu options when right-clicking |
| `SpriteConfig` | Visual representation | Icon/preview in UI |
| `Script` | Lua script components | Custom behavior hooks |

## How Entity Interaction Creates UI

When a player right-clicks an entity and selects an interaction option:

1. Engine reads the entity's `UiConfig` component
2. `UiConfig` specifies a window class name and style
3. Engine creates an instance of that window class (must be an `ISBaseEntityWindow` subclass)
4. Window receives the player and entity references
5. Window creates its child UI using entity component data
6. Engine manages proximity validation automatically

## Accessing Component Data

Inside your entity window, access components through `self.entity`:

```lua
function ZeD_BenchWindow:createChildren()
    ISBaseEntityWindow.createChildren(self)

    -- Check for components before accessing
    if self.entity:hasComponent(ComponentType.CraftBench) then
        local craftComp = self.entity:getComponent(ComponentType.CraftBench)
        -- craftComp gives you: recipes, skill requirements, crafting state
    end

    if self.entity:hasComponent(ComponentType.Resources) then
        local resComp = self.entity:getComponent(ComponentType.Resources)
        -- resComp gives you: slot count, items in slots, capacity
    end

    if self.entity:hasComponent(ComponentType.FluidContainer) then
        local fluidComp = self.entity:getComponent(ComponentType.FluidContainer)
        -- fluidComp gives you: current amount, max capacity, fluid type
    end
end
```

Always check `hasComponent()` before `getComponent()`. Not every entity has every component, and the combination varies by entity type.

## ISBaseEntityWindow Deep Dive

ISBaseEntityWindow extends ISCollapsableWindow with entity-specific features:

### What You Get for Free

- **Proximity auto-close**: Window closes when player walks more than `panelCloseDistance` tiles away (default: 4)
- **Player locking**: One player per entity at a time. `self.entity:setUsingPlayer(player)` on open, cleared on close
- **Vehicle check**: Prevents opening while player is in a vehicle
- **Split-screen awareness**: `stayOnSplitScreen()` keeps the window in the correct viewport
- **Layout dirtying**: Set `self.dirtyLayout = true` to trigger `calculateLayout()` next frame
- **ISXuiSkin integration**: `self.xuiSkin` is available for consistent skinned components

### Constructor Pattern

```lua
ZeD_EntityWindow = ISBaseEntityWindow:derive("ZeD_EntityWindow")

function ZeD_EntityWindow:new(x, y, player, entity)
    -- 7th argument is the entityUiStyle identifier
    local o = ISBaseEntityWindow:new(x, y, 400, 500, player, entity, "myStyle")
    setmetatable(o, self)
    self.__index = self

    -- Size constraints
    o.minimumWidth = 300
    o.minimumHeight = 350
    o.maximumWidth = 600
    o.maximumHeight = 0        -- 0 = unlimited
    o.maximumHeightPercent = 0.8  -- Max 80% of screen height

    return o
end
```

### createChildren Pattern

```lua
function ZeD_EntityWindow:createChildren()
    ISBaseEntityWindow.createChildren(self)

    -- Entity header (icon + name bar)
    self:createEntityHeader(self.xuiSkin, "EntityHeader")

    local y = self:titleBarHeight() + ZeD.Tokens.padMD
    local w = self.width - (ZeD.Tokens.padMD * 2)

    -- Build your content area below the header
    self.contentPanel = ZeD.Panel(ZeD.Tokens.padMD, y, w, self.height - y - ZeD.Tokens.padMD)
    self.contentPanel:setAnchorsTBLR(true, true, true, true)
    self.contentPanel:initialise()
    self:addChild(self.contentPanel)
end
```

### Responsive Layout

Entity windows support responsive resize through `calculateLayout`:

```lua
function ZeD_EntityWindow:calculateLayout(w, h)
    -- Called when window size changes
    -- Recalculate child positions and sizes
    local contentW = w - (ZeD.Tokens.padMD * 2)
    local contentH = h - self:titleBarHeight() - (ZeD.Tokens.padMD * 2)

    if self.contentPanel then
        self.contentPanel:setWidth(contentW)
        self.contentPanel:setHeight(contentH)
    end
end
```

Trigger a recalculation manually:
```lua
self.dirtyLayout = true  -- will call calculateLayout() next frame
-- or immediately:
self:xuiRecalculateLayout(self.width, self.height, true, false)
```

### Update Loop

The `update()` method runs every tick. ISBaseEntityWindow's default update checks:
- Is the entity still valid?
- Is the player still in range?
- Is the player still alive and not in a vehicle?

Override it to add your own per-tick logic, but always call the parent:

```lua
function ZeD_EntityWindow:update()
    ISBaseEntityWindow.update(self)
    -- Your tick logic (update progress bars, refresh data, etc.)
end
```

### Close Cleanup

Always clean up entity state when closing:

```lua
function ZeD_EntityWindow:close()
    -- Custom cleanup
    if self.entity then
        self.entity:setUsingPlayer(nil)  -- Release the lock
    end
    ISBaseEntityWindow.close(self)
end
```

## B42.16 Entity Window Variants

Build 42.16 formalized two concrete entity window implementations:

### ISEntityWindow (Direct Component Panels)

For entities with a single component panel or simple layout. Arranges component panels directly in the window body without tabs.

```lua
-- Engine creates this when entity UiConfig doesn't require tabs
-- Uses calculateLayout() for dynamic sizing
-- Component panels are direct children
```

### ISEntityTabWindow (Tabbed Interface)

For entities with multiple component panels. Uses `ISComponentsTabPanel` to create a tab bar where each tab corresponds to a component panel.

```lua
-- Engine creates this when entity has multiPanels > 1
-- ISComponentsTabPanel manages tab switching
-- Each tab has icon + text, derived from component type
-- Uses ISTableLayout for internal layout management
```

### ISEntityUI Helper Functions (B42.16)

```lua
ISEntityUI.GetEntityUiConfig(_entity)  -- Returns UiConfig component or nil
ISEntityUI.GetEntityUiStyle(_entity)   -- Returns style string
ISEntityUI.GetEntityUiSkin(_entity)    -- Returns skin identifier
ISEntityUI.GetComponentPanelClass()    -- Resolves component panel with validation
```

Component iteration: `_entity:componentSize()` returns count, `_entity:getComponentForIndex(i)` gets component by index.

### ISBaseEntityWindow B42.16 Layout Additions

```lua
-- New layout preference tracking
self.xuiPreferredResizeWidth    -- preferred width for layout
self.xuiPreferredResizeHeight   -- preferred height for layout
self.xuiResizeAnchorRight       -- right-anchored resize behavior

-- Enhanced layout recalculation
self:xuiRecalculateLayout(w, h, force, animate)
-- force=true bypasses dirty check, animate=true for smooth transitions
```

## Hooking Entity Window Creation

To replace a vanilla entity window with yours, you need to intercept the creation point. Common approaches:

### Hook the context menu handler

```lua
Events.OnFillWorldObjectContextMenu.Add(function(playerNum, context, worldobjects, test)
    for _, obj in ipairs(worldobjects) do
        if obj:hasComponent and obj:hasComponent(ComponentType.CraftBench) then
            -- Find and modify the existing menu option, or add your own
            -- that opens ZeD_BenchWindow instead of the vanilla one
        end
    end
end)
```

### Hook the UI creation function

```lua
-- Find where vanilla creates the entity window (grep for the class name)
-- Hook that function to return your window instead
local origCreate = ISCraftBenchUI.create  -- or whatever the creation function is
function ISCraftBenchUI.create(player, entity)
    return ZeD_BenchWindow:new(x, y, player, entity)
end
```

### Register a custom UiConfig handler

If the entity system supports it in B42, register your window class for specific entity styles so the engine creates your window automatically when that entity type is interacted with.

## Common Entity UI Patterns

### Item Slot Display

For entities with `Resources` component, display item slots:

```lua
local resComp = self.entity:getComponent(ComponentType.Resources)
-- Iterate slots to build a grid UI
-- Each slot can contain an item or be empty
-- Listen for changes to update the display
```

### Crafting Progress

For entities with `CraftBench` component, show crafting state:

```lua
local craftComp = self.entity:getComponent(ComponentType.CraftBench)
-- Read current recipe, progress, required items
-- Display progress bar
-- Update in update() tick
```

### Fluid Levels

For entities with `FluidContainer` component:

```lua
local fluidComp = self.entity:getComponent(ComponentType.FluidContainer)
-- Read current amount, max capacity, fluid type
-- Display fill bar with percentage
```
