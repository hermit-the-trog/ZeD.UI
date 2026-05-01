# Game UI Architecture Patterns

## Table of Contents
1. MVC/MVP for Games
2. Command Pattern
3. Flyweight for UI Elements
4. Dirty-Rectangle Rendering
5. Entity-Component vs Inheritance
6. Data-Driven Design
7. Signal/Slot Pattern
8. Object Pool

---

## 1. MVC/MVP for Games

Classic MVC adapted for game loops:

```
Model (game state)     ← update() modifies
  │
  ├── View (rendering)  ← render() reads Model, draws
  │
  └── Controller (input) ← processes input, calls Model methods
```

In game modding, the split is usually:
- **Model**: Java-side game objects (IsoPlayer, InventoryItem)
- **View**: Lua-side UI panels (ISPanel, PZAPI templates)
- **Controller**: Event handlers, mouse/keyboard callbacks

**Key rule**: View reads model, never writes it. Controller writes model through defined methods. View reacts to changes by polling model state each frame.

```lua
-- Model (Java side, accessed through getters)
-- player:getHealth(), player:getStats():getHunger()

-- View
function HealthBar:render()
    local health = self.player:getHealth()  -- read model
    local w = self.width * health           -- compute visual
    self:drawRect(0, 0, w, self.height, 1, 0.2, 0.8, 0.2)
end

-- Controller
function HealthBar:onMouseDown(x, y)
    -- UI interaction, not direct model mutation
    self:toggleExpanded()
end
```

### MVP Variant

Replace Controller with Presenter — a mediator between View and Model:

```lua
local InventoryPresenter = {}

function InventoryPresenter:new(view, player)
    local o = {view = view, player = player}
    return setmetatable(o, {__index = self})
end

function InventoryPresenter:refresh()
    local items = self.player:getInventory():getItems()
    local viewData = {}
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        viewData[#viewData + 1] = {
            name = item:getDisplayName(),
            icon = item:getIcon(),
            weight = item:getActualWeight(),
        }
    end
    self.view:setItems(viewData)  -- View only knows about view data
end
```

The Presenter converts Java model objects into simple Lua tables the View can consume. View never touches Java objects directly.

---

## 2. Command Pattern

Encapsulate actions as objects — enables undo, replay, macro recording:

```lua
local Command = {}
Command.__index = Command

function Command:new(execute, undo, description)
    return setmetatable({
        execute = execute,
        undo = undo,
        description = description,
    }, self)
end

-- Command history
local CommandHistory = {}
CommandHistory.stack = {}
CommandHistory.undoStack = {}

function CommandHistory:execute(cmd)
    cmd:execute()
    table.insert(self.stack, cmd)
    self.undoStack = {}  -- clear redo on new action
end

function CommandHistory:undo()
    local cmd = table.remove(self.stack)
    if cmd then
        cmd:undo()
        table.insert(self.undoStack, cmd)
    end
end
```

Useful for: crafting queues, build planning, UI state management with undo.

---

## 3. Flyweight for UI Elements

Share immutable state across many instances to reduce memory:

```lua
-- Heavy: each icon stores its own texture, font, color
-- Light: shared immutable data, per-instance mutable data

local IconStyles = {}  -- flyweight pool

function IconStyles.get(styleKey)
    if not IconStyles[styleKey] then
        IconStyles[styleKey] = {
            texture = getTexture("media/ui/" .. styleKey .. ".png"),
            font = UIFont.SdfRegular,
            padding = 4,
        }
    end
    return IconStyles[styleKey]
end

-- Each icon instance: tiny (just position + style reference)
function Icon:new(x, y, styleKey)
    local style = IconStyles.get(styleKey)
    return {x = x, y = y, style = style}  -- shared style object
end
```

When rendering hundreds of inventory icons, flyweight saves significant memory.

---

## 4. Dirty-Rectangle Rendering

Only re-render regions that changed:

```lua
local DirtyRegion = {}

function DirtyRegion:new()
    return setmetatable({dirty = true, regions = {}}, {__index = self})
end

function DirtyRegion:markDirty(x, y, w, h)
    self.dirty = true
    -- Optionally track specific regions
    table.insert(self.regions, {x=x, y=y, w=w, h=h})
end

function DirtyRegion:needsRedraw()
    return self.dirty
end

function DirtyRegion:clean()
    self.dirty = false
    self.regions = {}
end
```

PZ uses a simpler version: `setDirty()` marks an entire panel for re-layout. For game modding, the practical approach is marking panels dirty when data changes rather than tracking pixel regions.

```lua
function MyPanel:update()
    local newHealth = self.player:getHealth()
    if newHealth ~= self.cachedHealth then
        self.cachedHealth = newHealth
        self.needsRedraw = true
    end
end

function MyPanel:render()
    if not self.needsRedraw then return end
    -- expensive render work
    self.needsRedraw = false
end
```

---

## 5. Entity-Component vs Inheritance

Two philosophies for structuring game objects:

### Inheritance (PZ legacy)
```
IsoObject → IsoMovingObject → IsoGameCharacter → IsoPlayer
```
Pros: Simple mental model, type safety, clear hierarchy.
Cons: Diamond problem, rigid, hard to add cross-cutting behavior.

### Entity-Component (PZ Build 42)
```
GameEntity + [HealthComponent] + [InventoryComponent] + [RenderComponent]
```
Pros: Composable, mix-and-match capabilities, data-driven.
Cons: Harder to reason about, lookup overhead, debugging indirection.

### Hybrid (what PZ actually does)
PZ keeps the inheritance tree AND adds components. An `IsoPlayer` is still an `IsoGameCharacter`, AND it can have `CompLua` and other components attached. This is pragmatic — don't rewrite what works, but enable new patterns.

**For modding**: Use inheritance (`derive()`) when extending existing panel types. Use composition when building new systems (token-based theming, plugin architecture, data layers).

---

## 6. Data-Driven Design

Define behavior through data, not code:

```lua
-- Code-driven (hard to change)
function createSword()
    local item = {}
    item.name = "Iron Sword"
    item.damage = 15
    item.weight = 3.5
    return item
end

-- Data-driven (easy to change, moddable)
local itemDefs = {
    iron_sword = {name = "Iron Sword", damage = 15, weight = 3.5},
    steel_axe = {name = "Steel Axe", damage = 20, weight = 5.0},
}

function createItem(defKey)
    local def = itemDefs[defKey]
    if not def then error("Unknown item: " .. defKey) end
    local item = {}
    for k, v in pairs(def) do item[k] = v end
    return item
end
```

PZ's script system is exactly this — item properties defined in text files, read by Java, accessible via `getScriptItem()`. When designing mod systems, prefer data tables over hardcoded logic.

### Configuration Tables as DSL

```lua
-- Define UI layout as data
local layout = {
    type = "panel",
    width = 300, height = 400,
    padding = 8,
    children = {
        {type = "label", text = "Health", font = "bold"},
        {type = "bar", bind = "health", color = {0.2, 0.8, 0.2}},
        {type = "label", text = "Stamina", font = "bold"},
        {type = "bar", bind = "stamina", color = {0.2, 0.5, 0.8}},
    }
}

-- Builder reads data and creates real UI objects
function buildUI(spec, parent)
    local builders = {
        panel = buildPanel,
        label = buildLabel,
        bar = buildBar,
    }
    local widget = builders[spec.type](spec)
    if spec.children then
        for _, child in ipairs(spec.children) do
            buildUI(child, widget)
        end
    end
    if parent then parent:addChild(widget) end
    return widget
end
```

---

## 7. Signal/Slot Pattern

Type-safe event system with connection management:

```lua
local Signal = {}
Signal.__index = Signal

function Signal:new()
    return setmetatable({slots = {}}, self)
end

function Signal:connect(callback)
    local id = #self.slots + 1
    self.slots[id] = callback
    -- Return disconnect function
    return function()
        self.slots[id] = nil
    end
end

function Signal:emit(...)
    for _, slot in pairs(self.slots) do
        slot(...)
    end
end

-- Usage
local onHealthChanged = Signal:new()
local disconnect = onHealthChanged:connect(function(old, new)
    print("Health: " .. old .. " → " .. new)
end)

onHealthChanged:emit(100, 85)  -- fires callback
disconnect()                    -- removes callback
onHealthChanged:emit(85, 70)   -- nothing happens
```

Advantages over PZ's `Events.Add()`:
- Scoped connections (can disconnect specific callbacks)
- Per-object signals (not global)
- Type-checked arguments (by convention)

---

## 8. Object Pool

Reuse objects instead of creating/destroying them each frame:

```lua
local Pool = {}
Pool.__index = Pool

function Pool:new(factory, reset, initialSize)
    local pool = setmetatable({
        factory = factory,
        reset = reset,
        available = {},
        active = {},
    }, self)

    for i = 1, (initialSize or 10) do
        pool.available[#pool.available + 1] = factory()
    end
    return pool
end

function Pool:acquire()
    local obj = table.remove(self.available)
    if not obj then obj = self.factory() end
    self.active[obj] = true
    return obj
end

function Pool:release(obj)
    self.active[obj] = nil
    self.reset(obj)
    self.available[#self.available + 1] = obj
end
```

Useful for: tooltip popups, particle effects, temporary UI labels that appear/disappear frequently. Avoids GC pressure from constant allocation.
