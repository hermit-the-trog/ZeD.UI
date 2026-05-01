# PZAPI UI Framework Reference Guide

## Overview

PZAPI provides a hierarchical, composable UI system for Project Zomboid mods. It uses a metatransitive architecture where templates are callable tables that support inheritance through composition.

---

## 1. Meta System: The Engine

### Core Principles

PZAPI's power comes from the **metamethod system** in `Meta.lua`. All UI components are Lua tables with a shared metatable (`UI._mt`) that enables:

- **Template instantiation** via `__call` metamethod
- **Composition** through inheritance and table merging
- **Lifecycle management** through recursive hooks

### The `__call` Metamethod (Template Creation)

```lua
UI._mt.__call = function(self, _args)
    local res = setmetatable(UI._mergeTables(UI._copyValue(self), UI._copyValue(_args)), UI._mt)
    res.super = self
    return res
end
```

When you invoke a component like `UI.Node{...}`, this metamethod:
1. Deep-copies `self` (the template) using `_copyValue`
2. Deep-copies the passed arguments
3. Merges both using `_mergeTables` (children are recursively merged)
4. Stores the parent template as `super`
5. Returns a new table with the same metatable

**Result:** You now have a new instance that inherits from its parent template.

### Key Utility Functions

**`_copyValue(obj, seen)`** - Deep copy tables while skipping Java objects

- Handles circular references via `seen` table
- Preserves metatables
- Skips `javaObj` (Java interop objects)

**`_mergeTables(...)`** - Merge multiple tables with smart `children` handling

- Last value wins for conflicting keys
- `children` tables are recursively merged (not replaced)
- Enables safe template extension

### instantiate() - The Lifecycle

When you call `element:instantiate()` (or `.init()` in older syntax), this sequence fires:

1. **`_setParentChildRelationship()`** - Recursively sets `parent` pointers
2. **`_applyHooks()`** - Registers event extensions (mouse, scroll, drag)
3. **`_createAtomObjs()`** - Creates Java objects (`javaObj`) for rendering
4. **`_internalInit()`** - Calls Java-side initialization
5. **`_initElement()`** - Calls user's `init()` hook (Lua side)
6. **`_initResize()`** - Calls user's `onResize()` hook
7. **`UIManager.AddUI()`** - Registers with the render engine

Each function recursively processes the entire tree.

---

## 2. Atoms (Leaf Components)

### Node (Base Class)

**File:** `atoms/Node.lua`

Foundation of all UI. Pure rendering with no content.

**Properties:**
- `x, y` - Position (default: 0)
- `width, height` - Size (default: 256)
- `pivotX, pivotY` - Rotation center (0-1, default: 0)
- `angle` - Rotation in degrees (default: 0)
- `scaleX, scaleY` - Scale multiplier (default: 1)
- `r, g, b, a` - Color and alpha (0-1, default: 1, 1, 1, 1)
- `anchorLeft, anchorRight, anchorTop, anchorDown` - Anchor behavior (bool/pixels)
- `visible, enabled` - Render and input state (default: true)
- `alwaysBack, alwaysOnTop` - Z-order (default: false)
- `isStencil` - Use as clipping mask (default: false)

**Methods:**
- `setX(v)`, `setY(v)` - Position
- `setWidth(v)`, `setHeight(v)` - Size (triggers resize event)
- `setWidthSilent(v)`, `setHeightSilent(v)` - Size (no event)
- `setPivotX(v)`, `setPivotY(v)` - Pivot
- `setAngle(v)`, `setScaleX(v)`, `setScaleY(v)` - Transform
- `setColor(r, g, b, a)` - Color
- `setVisible(v)`, `setEnabled(v)` - State
- `centerOnScreen(playerNum)` - Auto-center

**Constructor:**
```lua
local node = UI.Node{
    width = 100, height = 100,
    r = 1, g = 0, b = 0
}
```

### Text

**File:** `atoms/Text.lua`

Extends Node. Renders localized or plain text.

**Properties:**
- `text` - Text to display (string, default: "")
- `font` - UIFont enum (default: UIFont.SdfRegular)

**Methods:**
- `setText(text)` - Change text
- `setFont(uiFont)` - Change font

**Constructor:**
```lua
UI.Text{
    text = "Hello",
    font = UIFont.SdfBold,
    scaleX = 0.5, scaleY = 0.5
}
```

### TextEntry

**File:** `atoms/TextEntry.lua`

Extends Node. Single or multi-line text input.

**Properties:**
- `text` - Initial text (string, default: "")
- `font` - UIFont enum (default: UIFont.SdfRegular)

**Methods:**
- `setText(text)` - Set text programmatically
- `getText()` - Get current text
- `setFont(uiFont)` - Change font
- `focus()`, `unfocus()` - Manage keyboard focus

**Constructor:**
```lua
UI.TextEntry{
    text = "Enter value",
    width = 200, height = 30,
    isMultiline = true
}
```

### Texture

**File:** `atoms/Texture.lua`

Extends Node. Renders images, supports 9-slice scaling and animation.

**Properties:**
- `texture` - Texture object from `getTexture()` (default: nil)
- `sliceLeft, sliceRight, sliceTop, sliceDown` - 9-slice margins (pixels, default: 0)
- `animDelay` - Milliseconds per frame (default: 0, no animation)
- `animFrameNum` - Total frame count (default: 0)
- `animFrameRows, animFrameColumns` - Grid layout (default: 0)

**Methods:**
- `setTexture(texture)` - Change texture
- `setSlice9(L, R, T, D)` - Set 9-slice offsets
- `setAnimValues(delay, frameNum, rows, cols)` - Configure animation

**Constructor:**
```lua
UI.Texture{
    texture = getTexture("media/ui/myimage.png"),
    width = 100, height = 100,
    sliceLeft = 10, sliceRight = 10,
    sliceTop = 10, sliceDown = 10
}
```

---

## 3. Molecules (Composite Components)

### Panel

**File:** `molecules/Panel.lua`

Extends Texture. A bordered container for grouping elements.

**Default Children:**
- `leftBorder, rightBorder, topBorder, downBorder` - Texture borders

**Default Properties:**
- `r=0, g=0, b=0, a=0.7` - Semi-transparent black background
- Border color defaults to `0.4, 0.4, 0.4, 1` (dark gray)

**Methods:**
- `setBorderColor(r, g, b, a)` - Change all borders

**Constructor:**
```lua
UI.Panel{
    width = 200, height = 100,
    children = {
        myLabel = UI.Text{text = "Content"}
    }
}
```

### TextButton

**File:** `molecules/TextButton.lua`

Extends Panel. Button with centered text label.

**Default Properties:**
- `sounds.activate = "UIActivateButton"` - Click sound

**Default Child:**
- `label` - UI.Text (centered, scaled 0.5x0.5)

**Behavior:**
- On hover: darkens to `0.1, 0.1, 0.1, 0.7`
- On normal: `0, 0, 0, 0.7`

**Constructor:**
```lua
UI.TextButton{
    x = 10, y = 10,
    width = 100, height = 30,
    children = {
        label = UI.TextButton.children.label{
            text = "Click Me"
        }
    },
    onLeftClick = function(self)
        print("Button pressed!")
    end
}
```

### ImageButton

**File:** `molecules/ImageButton.lua`

Extends Texture. Clickable image with hover effects.

**Default Properties:**
- `sounds.activate = "UIActivateButton"`

**Behavior:**
- Hover: tints to `0.4, 0.4, 0.8, 0.8` (blue)
- Normal: `1, 1, 1, 1` (white)

**Constructor:**
```lua
UI.ImageButton{
    x = 5, y = 5,
    width = 16, height = 16,
    texture = getTexture("media/ui/Button.png"),
    onLeftClick = function(self)
        print("Image clicked")
    end
}
```

### ScrollBarVertical

**File:** `molecules/ScrollBarVertical.lua`

Extends Panel. Vertical scrollbar with draggable thumb.

**Properties:**
- `width = 11` (pixels)
- Anchored top/bottom/right by default

**Children:**
- `top, bottom` - Texture buttons (up/down arrows)
- `bar` - Node containing scroll thumb with drag logic

**Methods:**
- `setBarSize(sizeCoeff)` - Set visible proportion (0-1). If >= 1, hides bar.
- `updateBar(percent)` - Position thumb (0-1 normalized)

**Behavior:**
- Dragging thumb: scrolls container child via `setY()`
- Automatically enforces bounds

**Constructor:**
```lua
UI.ScrollBarVertical{
    x = 400, y = 0,
    height = 300,
    anchorRight = 0
}
```

### TabPanel

**File:** `molecules/TabPanel.lua`

Extends Node. Multi-tab interface with auto-generated buttons.

**Required Property:**
- `tabs` - Array of child keys: `{"tab1", "tab2"}`
- Each tab key must have a `children[key]` with a `name` property

**Children (auto-generated):**
- `button_<id>` - Tab buttons (created in `init()`)
- `panel` - Header panel

**Methods:**
- `select(id)` - Switch to tab by key

**Behavior in init():**
- Creates buttons from `tabs` array
- Hides all tabs except first
- Sets first tab visible/enabled

**onResize():**
- Resizes all tab content to fill below header

**Constructor:**
```lua
UI.TabPanel{
    tabs = {"info", "settings"},
    children = {
        info = UI.Node{
            name = "Info Tab",
            children = {
                content = UI.Text{text = "Info here"}
            }
        },
        settings = UI.Node{
            name = "Settings",
            children = {...}
        }
    }
}
```

---

## 4. Organisms (Complex UIs)

### Window

**File:** `organisms/Window.lua`

Extends Node. Fully-featured draggable window with titlebar and resize.

**Default Children:**
- `bar` - Panel (titlebar, height=20)
  - `closeButton` - Close button (top-left)
  - `infoButton` - Info button
  - `settingsButton` - Settings (opens tooltip)
  - `pinButton` - Pin/collapse toggle
- `body` - Panel (content area)
- `bottomBar` - Panel (height=9, resize handle)

**Properties:**
- `isPin` - If true, collapses on click outside (default: false)
- `delayResizeW, delayResizeH` - Pending resize (internal)
- `leftDragX, leftDragY` - Pending position (internal)

**Methods:**
- `setCollapsed(bool)` - Hide/show body and bottom bar

**Behavior:**
- Title bar is draggable (calls `setX/setY` in renderUpdate)
- Bottom-right corner resizable (sets `delayResizeW/H`)
- Pin button toggles collapse on-click-outside
- Close button removes from UIManager

**Constructor:**
```lua
UI.Window{
    x = 100, y = 100,
    width = 400, height = 300,
    isPin = false,
    children = {
        bar = UI.Window.children.bar{...},
        body = UI.Window.children.body{
            children = {
                title = UI.Text{text = "My Window"}
            }
        },
        bottomBar = UI.Window.children.bottomBar{...}
    }
}
```

### TestExample

**File:** `organisms/TestExample.lua`

Reference implementation. Window with TabPanel containing 5 empty tabs.

**Tabs:** Info, Skills, Health, Protection, Temperature

Demonstrates composition: Window > TabPanel > multiple Node children.

### FishWindow

**File:** `organisms/FishWindow.lua`

Complete real example. Fishing UI with:
- Window frame with custom close behavior
- TabPanel with "Info" and "Guide" tabs
- Dynamic fish list (adds children in init)
- Real-time fish stats display
- Tooltips on hover

Key patterns shown:
- Custom `init()` to dynamically create children
- `UI._addChild()` to add after instantiation
- Real-time `update()` hooks
- Tooltip creation with `instantiate()`

---

## 5. Extension Hooks System

**File:** `atoms/AtomExtensions.lua`

Extensions are registered via `Hooks` table and auto-applied when matching properties exist.

### Mouse Extension

**Hook triggers:** Any of `onLeftClick`, `onRightClick`, `onLeftDrag`, `onRightDrag`, `onMiddleDrag`, `onHover`

**Added internal state:**
- `_atomExtMouse.consumeButtonDown` - Consume button down events (default: true)
- `_atomExtMouse.consumeMove` - Consume move events (default: true)
- `_atomExtMouse.pressed[btn]` - Active drag state: `{startX, startY, lastX, lastY}`
- `_atomExtMouse.isHover` - Current hover state

**Provided callbacks (call as methods on `self`):**

| Hook | Args | Fired |
|------|------|-------|
| `onHover(state)` | `state` = bool | Enter/exit bounds |
| `onLeftClick(x, y)` | Coords | Left mouse up inside |
| `onRightClick(x, y)` | Coords | Right mouse up inside |
| `onLeftDrag(data, dx, dy)` | `data={startX,startY,lastX,lastY}` | Left button dragged |
| `onRightDrag(data, dx, dy)` | Same | Right button dragged |
| `onMiddleDrag(data, dx, dy)` | Same | Middle button dragged |

**Usage:**
```lua
UI.Node{
    onLeftClick = function(self, x, y)
        print("Clicked at", x, y)
    end,
    onLeftDrag = function(self, data, dx, dy)
        self:setX(self.x + dx)
        self:setY(self.y + dy)
    end,
    onHover = function(self, state)
        if state then
            self:setColor(1, 1, 1, 1)
        else
            self:setColor(0.5, 0.5, 0.5, 1)
        end
    end
}
```

### Scroll Extension

**Hook triggers:** `onScroll` property

**Behavior:**
- Intercepts `onMouseWheel` events
- Auto-constrains Y position: `0 <= y <= parent.height - self.height`
- Calls `onScroll(percent)` where percent = `y / (parent.height - self.height)`

**Usage:**
```lua
UI.Texture{
    height = 200,
    onScroll = function(self, percent)
        print("Scrolled to", math.floor(percent * 100) .. "%")
    end
}
```

---

## 6. Practical Examples

### Example 1: Draggable Window with Button

```lua
local MyWindow = UI.Window{
    x = 100, y = 100,
    width = 300, height = 200,
    children = {
        body = UI.Window.children.body{
            children = {
                button = UI.TextButton{
                    x = 10, y = 10,
                    width = 80, height = 30,
                    children = {
                        label = UI.TextButton.children.label{
                            text = "Click Me"
                        }
                    },
                    onLeftClick = function(self)
                        print("Button clicked!")
                    end
                }
            }
        }
    }
}

MyWindow:instantiate()
```

### Example 2: Scrollable List

```lua
local items = {"Apple", "Banana", "Orange", "Pear", "Grape"}

local ScrollableList = UI.Node{
    width = 200, height = 300,
    isStencil = true,
    children = {
        scrollbar = UI.ScrollBarVertical{
            anchorRight = 0,
            container = nil  -- Will reference content below
        },
        content = UI.Node{
            width = 200, height = 0,  -- Set by init
            onScroll = function(self, percent)
                self.parent.children.scrollbar:updateBar(percent)
            end
        }
    },
    init = function(self)
        local y = 0
        for i, item in ipairs(items) do
            self.children.content.children["item_" .. i] = UI.Text{
                y = y,
                text = item,
                scaleX = 0.4, scaleY = 0.4
            }
            y = y + 20
        end
        self.children.content:setHeight(y)
        self.children.scrollbar.container = self.children.content
        self.children.scrollbar:setBarSize(self.height / self.children.content.height)
    end
}

ScrollableList:instantiate()
```

### Example 3: Tabbed Settings Panel

```lua
local Settings = UI.Window{
    x = 200, y = 200,
    width = 400, height = 300,
    children = {
        body = UI.Window.children.body{
            children = {
                tabs = UI.TabPanel{
                    tabs = {"graphics", "audio"},
                    children = {
                        graphics = UI.Node{
                            name = "Graphics",
                            children = {
                                brightness = UI.TextButton{
                                    x = 10, y = 10,
                                    width = 100, height = 30,
                                    onLeftClick = function(self)
                                        print("Adjust brightness")
                                    end
                                }
                            }
                        },
                        audio = UI.Node{
                            name = "Audio",
                            children = {
                                volume = UI.TextButton{
                                    x = 10, y = 10,
                                    width = 100, height = 30,
                                    onLeftClick = function(self)
                                        print("Adjust volume")
                                    end
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

Settings:instantiate()
```

---

## 7. testUI.lua Examples

The `testUI.lua` file contains two developer examples:

### TESTUI.show() - Interactive Element

Creates an interactive container demonstrating:
- Custom pivot and scale
- Slice9 texture with transforms
- Multi-button drag handlers (left=resize, right=move, middle=rotate)
- Real-time transformation during drag

**Key code:**
```lua
onLeftDrag = function(self, data, dx, dy)
    -- Resize from top-left while dragging
end,
onRightDrag = function(self, data, dx, dy)
    -- Move window
end,
onMiddleDrag = function(self, data, dx, dy)
    -- Rotate around pivot point
end
```

### TESTUI.show2() - Animated Sprite Window

Creates a Window with:
- Animated texture (sprite sheet: 29 frames, 6x5 grid)
- Play/Pause buttons that call `javaObj:animPlay()` and `javaObj:animPause()`

Demonstrates animation setup:
```lua
texture = getTexture("media/ui/UI_ANIMTEST.png"),
animDelay = 100,  -- 100ms per frame
animFrameNum = 29,  -- 29 total frames
animFrameRows = 6,  -- 6 rows
animFrameColumns = 5  -- 5 columns per row
```

---

## 8. Key Patterns & Best Practices

### Template Inheritance

Always start with a base template:

```lua
local MyBase = UI.Node{...}

local MyDerived = MyBase{
    -- Overrides and additions
}
```

### Dynamic Children

Add children after instantiation using `UI._addChild()`:

```lua
init = function(self)
    for i = 1, 10 do
        local child = UI.Text{text = "Item " .. i}
        UI._addChild(self, child)
    end
end
```

### Update Loops

Use `update()` for per-frame logic:

```lua
update = function(self)
    local time = getGameTime():getTimeAndXp()
    self.children.timeDisplay:setText(time)
end
```

### Lifecycle Hooks

- `init()` - Runs after tree creation, before Java init. Safe to add children here.
- `onResize()` - Runs after init. Resize children to fit parent.
- `renderUpdate()` - Per-frame. Use for animation, state checks.

### Anchoring

Set anchors to pin edges:

```lua
anchorLeft = 0,     -- Stick to left
anchorRight = 0,    -- Stick to right
anchorTop = 20,     -- 20px from top
anchorDown = -10    -- 10px from bottom (negative = inward)
```

### Color & Transparency

Use `setColor()` for hover effects:

```lua
onHover = function(self, state)
    if state then
        self:setColor(1, 1, 1, 1)  -- Bright
    else
        self:setColor(0.8, 0.8, 0.8, 0.8)  -- Dim
    end
end
```

---

## 9. ModOptions.lua

Optional framework for mod settings UI. Creates options that sync to `ModOptions.ini`.

**Key Classes:**
- `Options:new(modID, name)` - Create options object
- `Options:addTextEntry(id, name, value, tooltip)`
- `Options:addTickBox(id, name, value, tooltip)`
- `Options:addComboBox(id, name, tooltip)` then `.addItem(text, isSelected)`
- `Options:addSlider(id, name, min, max, step, value, tooltip)`
- `Options:addColorPicker(id, name, r, g, b, a, tooltip)`
- `Options:addKeyBind(id, name, key, tooltip)`

**Global API:**
- `PZAPI.ModOptions:create(modID, name)` - Create and register
- `PZAPI.ModOptions:save()` - Persist to file
- `PZAPI.ModOptions:load()` - Load from file

---

## Summary

| Layer | Purpose | Example |
|-------|---------|---------|
| **Meta** | Callable templates, inheritance, lifecycle | `UI.Node{...}` creates instance |
| **Atoms** | Leaf nodes: Node, Text, TextEntry, Texture | `UI.Text{text = "Hello"}` |
| **Molecules** | Composites: Panel, Button, ScrollBar, TabPanel | `UI.TextButton{...children}` |
| **Organisms** | Full UIs: Window, FishWindow, TestExample | `UI.Window{...body, bar}` |
| **Hooks** | Event handling: Mouse, Scroll | `onLeftClick`, `onHover`, `onLeftDrag` |
| **Instantiation** | `.instantiate()` wires tree to Java renderer | Final step to display |

**Core flow:**
1. Define template with metatables
2. Call as function to create instance: `MyUI.Node{...}`
3. Override/extend properties and children
4. Call `:instantiate()` to wire to renderer
5. Set event handlers in template definition
6. Hooks auto-apply via `_applyHooks()`
