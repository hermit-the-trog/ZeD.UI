# Project Zomboid UI Hierarchy Reference

A complete guide to the UI class hierarchy for modders.

## Class Hierarchy Chain

```
ISBaseObject
    ↓
ISUIElement
    ↓
ISPanel
    ↓
ISCollapsableWindow
    ↓
ISBaseEntityWindow
```

---

## ISBaseObject

**Purpose:** Base class for all objects in the system. Provides event system.

**Constructor:**
```lua
local obj = ISBaseObject:new()
```

**Key Methods:**
- `initialise()` - Initialization hook (empty by default)
- `addEventListener(event, callback, target)` - Register event listener
- `removeEventListener(event, callback)` - Unregister listener
- `triggerEvent(event, ...)` - Fire event with up to 12 parameters
- `clearEventListeners()` - Remove all listeners

**Override Points:**
- `initialise()` - Set up initial state

**Example:**
```lua
local myObj = ISBaseObject:new()
myObj:addEventListener("customEvent", function(target, param1)
    print("Event fired: " .. param1)
end, self)
myObj:triggerEvent("customEvent", "hello")
```

---

## ISUIElement

**Purpose:** Base UI element. Handles positioning, visibility, and child management.

**Properties (from constructor):**
```lua
x, y, width, height          -- Position and size
visible = true               -- Visibility state
anchorLeft, anchorRight      -- Horizontal anchoring
anchorTop, anchorBottom      -- Vertical anchoring
children = {}                -- Child elements
ID                           -- Unique identifier (auto-assigned)
```

**Constructor:**
```lua
local elem = ISUIElement:new(x, y, width, height)
```

**Key Methods:**
- `initialise()` - Initialize UI element
- `setVisible(visible)` - Show/hide element
- `getIsVisible()` - Get visibility state
- `setX(x), setY(y)` - Set position
- `getX(), getY()` - Get position
- `setWidth(w), setHeight(h)` - Set dimensions
- `getWidth(), getHeight()` - Get dimensions
- `setAnchorLeft(bool), setAnchorRight(bool), setAnchorTop(bool), setAnchorBottom(bool)` - Set anchor points
- `setAnchorsTBLR(top, bottom, left, right)` - Set all anchors at once
- `addChild(child)` - Add child element
- `removeChild(child)` - Remove child element
- `bringToTop()` - Move to front
- `isMouseOver()` - Check mouse state
- `getMouseX(), getMouseY()` - Get relative mouse position
- `getAbsoluteX(), getAbsoluteY()` - Get world position
- `getCentreX(), getCentreY()` - Get center coordinates

**Override Points:**
- `initialise()` - Custom initialization
- `prerender()` - Called before rendering
- `render()` - Render the element
- `update()` - Called each frame
- `onMouseMove(dx, dy)` - Mouse movement
- `onMouseDown(x, y)` - Mouse pressed
- `onMouseUp(x, y)` - Mouse released

**Example:**
```lua
local panel = ISUIElement:new(100, 100, 300, 200)
panel:initialise()
panel:setAnchorLeft(true)
panel:setAnchorTop(true)
panel:setVisible(true)
```

---

## ISPanel

**Purpose:** Visual panel with optional background and dragging support.

**Constructor:**
```lua
local panel = ISPanel:new(x, y, width, height)
```

**Properties (adds to parent):**
```lua
background = true                                -- Draw background rectangle
backgroundColor = {r=0, g=0, b=0, a=0.5}        -- BG color
borderColor = {r=0.4, g=0.4, b=0.4, a=1}        -- Border color
moveWithMouse = false                            -- Enable dragging
moving = false                                   -- Currently being dragged
```

**Key Methods:**
- `noBackground()` - Disable background drawing
- `close()` - Hide panel
- `prerender()` - Draw background and border
- `onMouseDown(x, y)` - Start dragging if enabled
- `onMouseMove(dx, dy)` - Update drag position
- `onMouseUp(x, y)` - End dragging

**What ISPanel Adds vs ISUIElement:**
- Visual rendering (background + border)
- Mouse-driven dragging
- Close functionality

**Example:**
```lua
local panel = ISPanel:new(50, 50, 200, 150)
panel:initialise()
panel.moveWithMouse = true  -- Make it draggable
panel.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
panel:addToUIManager()
```

---

## ISCollapsableWindow

**Purpose:** Panel with title bar, collapse/pin buttons, and resizing.

**Constructor:**
```lua
local window = ISCollapsableWindow:new(x, y, width, height)
```

**Properties (adds to parent):**
```lua
title = nil                                      -- Title text
isCollapsed = false                              -- Current collapse state
pin = true                                       -- Pinned (stay open)
resizable = true                                 -- Allow resize
drawFrame = true                                 -- Draw title bar
backgroundColor = {r=0, g=0, b=0, a=0.8}        -- Window background
borderColor = {r=0.4, g=0.4, b=0.4, a=1}        -- Border color
titleFont = UIFont.Small                         -- Title text font
viewList = {}                                    -- Child views
closeButton, pinButton, collapseButton           -- Built-in buttons
resizeWidget, resizeWidget2                      -- Resize handles
```

**Key Methods:**
- `setTitle(title)` - Set window title
- `getTitle()` - Get window title
- `createChildren()` - Create buttons and widgets (call from init)
- `setResizable(bool)` - Enable/disable resizing
- `setDrawFrame(visible)` - Toggle frame drawing
- `addView(view)` - Add view below title bar
- `getViews()` - Get all views
- `titleBarHeight()` - Get height of title bar
- `resizeWidgetHeight()` - Get height of resize widget
- `collapse()` - Collapse window
- `pin()` - Pin window (prevent collapse)
- `close()` - Hide window
- `prerender()` - Draw title bar and background
- `render()` - Draw resize widgets
- `setInfo(text)` - Set info button tooltip

**Override Points:**
- `createChildren()` - Create custom child elements
- `close()` - Custom close behavior

**Example:**
```lua
local window = ISCollapsableWindow:new(100, 100, 400, 300)
window:initialise()
window:setTitle("My Window")
window:createChildren()
window:setResizable(true)
window:setInfo("This is helpful info")
window:addToUIManager()
```

---

## ISWindow

**Purpose:** Simple window with title bar and client area. Lightweight alternative to ISCollapsableWindow.

**Constructor:**
```lua
local window = ISWindow:new("Title", x, y, width, height)
```

**Properties:**
```lua
title = "Title"                                  -- Window title
TitleBarHeight = 19                              -- Static constant
SideMargin = 12                                  -- Static constant
BottomMargin = 12                                -- Static constant
hasClose = true                                  -- Has close button
toolbars = {}                                    -- Attached toolbars
```

**Key Methods:**
- `getClientLeft()` - Left edge of content area
- `getClientRight()` - Right edge of content area
- `getClientTop()` - Top edge of content area
- `getClientBottom()` - Bottom edge of content area
- `getClientWidth()` - Content area width
- `getClientHeight()` - Content area height
- `addToolbar(toolbar, height)` - Add toolbar to window
- `removeToolbar(toolbar)` - Remove toolbar
- `getTotalToolbarHeight()` - Get combined toolbar height
- `render()` - Draw title

**Use When:** You need a lightweight window with resizing from corners but no collapse/pin features.

**Example:**
```lua
local window = ISWindow:new("Simple Window", 50, 50, 300, 200)
window:initialise()
window:addToUIManager()
```

---

## ISCollapsableWindow (continued)

### More Details

**createChildren() implementation pattern:**
```lua
function MyWindow:createChildren()
    ISCollapsableWindow.createChildren(self)  -- Call parent

    -- Add custom child elements
    local myButton = ISButton:new(10, self:titleBarHeight(), 100, 20, "Click", self, function(self)
        print("Clicked!")
    end)
    myButton:initialise()
    self:addChild(myButton)
end
```

**Resize behavior:**
- Corner widget appears in bottom-right (if resizable)
- Handles position anchoring
- Updates size during mouse drag

**Collapse behavior:**
- Auto-collapses when mouse leaves for ~20 game ticks
- Can be prevented by pinning
- Use `uncollapse()` to expand by moving over title bar

---

## ISBaseEntityWindow

**Purpose:** Entity interaction window. Specialized for interacting with game objects/vehicles.

**Constructor:**
```lua
local window = ISBaseEntityWindow:new(x, y, width, height, player, entity, entityUiStyle)
```

**Properties (adds to parent):**
```lua
player = nil                                     -- IsoPlayer accessing entity
entity = nil                                     -- Target entity (IsoObject/Vehicle)
entityUiStyle = nil                              -- UI style identifier
panelCloseDistance = 4                           -- Distance before auto-close
enableHeader = true                              -- Show entity header
minimumWidth, minimumHeight = 0, 0               -- Minimum size bounds
maximumWidth, maximumHeight = 0, 0               -- Maximum size bounds (0=unlimited)
maximumHeightPercent = -1                        -- Max as % of screen
calculateLayout = nil                            -- Layout callback function
dirtyLayout = false                              -- Layout needs recalc
```

**Key Methods:**
- `createChildren()` - Initialize window
- `createEntityHeader(xuiSkin, styleName, ...)` - Create header widget
- `xuiRecalculateLayout(width, height, force, anchorRight)` - Trigger layout recalc
- `validateSizeBounds()` - Check size constraints
- `close()` - Close and clean up (unsets using player)
- `update()` - Check validity; auto-close if out of range
- `stayOnSplitScreen()` - Keep on player's split screen
- `isKeyConsumed(key)` - Customize key handling
- `onKeyRelease(key)` - Handle Escape key

**What ISBaseEntityWindow Adds:**
- Distance-based auto-close (default 4 tiles)
- Player/entity state tracking
- Layout recalculation system
- Size constraint validation
- Split-screen awareness

**Key Differences from ISCollapsableWindow:**
- Designed for entity interaction (auto-closes when too far away)
- Prevents usage when player is in vehicle
- Enforces single-player access to entity
- Built-in layout calculation system

**Example:**
```lua
function MyEntityWindow:new(x, y, player, entity)
    local self = ISBaseEntityWindow:new(x, y, 300, 400, player, entity, "default")
    setmetatable(self, MyEntityWindow)
    MyEntityWindow.__index = self

    self.minimumWidth = 200
    self.minimumHeight = 150

    return self
end

function MyEntityWindow:createChildren()
    ISBaseEntityWindow.createChildren(self)
    self:createEntityHeader(xuiSkin, "EntityHeader")

    -- Add custom UI elements below header
end

function MyEntityWindow:calculateLayout(w, h)
    -- Recalculate child positions based on width/height
end
```

---

## ISButton

**Purpose:** Clickable button with text, images, and hover effects.

**Constructor:**
```lua
local button = ISButton:new(x, y, width, height, title, clickTarget, onClickFunc, onMouseDownFunc, allowMouseUpProcessing)
```

**Properties:**
```lua
title = ""                                       -- Button text
onclick = nil                                    -- Click callback
onmousedown = nil                                -- Press callback
onMouseOverFunction = nil                        -- Hover callback
onmouseoutfunction = nil                         -- Mouse-out callback
enable = true                                    -- Is clickable
displayBackground = true                         -- Draw background
backgroundColor = {r=0, g=0, b=0, a=1}           -- Default color
backgroundColorMouseOver = {r=0.3, g=0.3, b=0.3, a=1} -- Hover color
borderColor = {r=0.7, g=0.7, b=0.7, a=1}        -- Border color
textColor = {r=1, g=1, b=1, a=1}                 -- Text color
font = UIFont.Small                              -- Text font
image = nil                                      -- Optional icon
tooltip = nil                                    -- Tooltip text
pressed = false                                  -- Currently pressed
```

**Key Methods:**
- `setTitle(title)` - Set button text
- `getTitle()` - Get button text
- `setFont(font)` - Set text font
- `setOnClick(func, arg1, arg2, arg3, arg4)` - Set click handler with args
- `setDisplayBackground(bool)` - Toggle background
- `setEnable(bool)` - Enable/disable button
- `isEnabled()` - Get enabled state
- `setBackgroundRGBA(r, g, b, a)` - Set background color
- `setBackgroundColorMouseOverRGBA(...)` - Set hover color
- `setBorderRGBA(r, g, b, a)` - Set border color
- `setImage(image)` - Set icon texture
- `setTooltip(text)` - Set tooltip
- `setWidthToTitle(minWidth)` - Auto-fit width to text
- `forceClick()` - Programmatic click
- `setRepeatWhilePressed(func)` - Repeating press callback
- `enableAcceptColor()` - Green highlight
- `enableCancelColor()` - Red highlight

**Callback Signatures:**
```lua
-- onclick
function onClickFunc(target, button, arg1, arg2, arg3, arg4)
end

-- onmousedown
function onMouseDownFunc(target, button, x, y)
end
```

**Example:**
```lua
local button = ISButton:new(50, 100, 120, 30, "Click Me", self, function(target, button, arg1)
    print("Button clicked!")
end)
button:initialise()
button:setBackgroundRGBA(0.2, 0.4, 0.2, 0.8)
button:setTooltip("This is a button")
panel:addChild(button)
```

---

## ISScrollingListBox

**Purpose:** Scrollable list with selection, items, and callbacks.

**Constructor:**
```lua
local listbox = ISScrollingListBox:new(x, y, width, height)
```

**Properties:**
```lua
items = {}                                       -- List items
selected = 1                                     -- Selected index
count = 0                                        -- Item count
itemheight = 20                                  -- Item height (pixels)
font = UIFont.Large                              -- Item font
backgroundColor = {r=0, g=0, b=0, a=0.8}        -- Background
borderColor = {r=0.4, g=0.4, b=0.4, a=0.9}      -- Border
textColor = {r=0.9, g=0.9, b=0.9, a=0.9}        -- Text color
selectedTextColor = {r=0.9, g=0.9, b=0.9, a=0.9} -- Selected text
selectionColor = {r=0.7, g=0.35, b=0.15, a=0.3} -- Selection highlight
onmousedown = nil                                -- Selection callback
onmousedblclick = nil                            -- Double-click callback
columns = {}                                     -- Column headers
vscroll = nil                                    -- Vertical scroll bar
```

**Key Methods:**
- `addItem(name, item, tooltip)` - Add item
- `insertItem(index, name, item)` - Insert at index
- `addUniqueItem(name, item, tooltip)` - Add if not exists
- `removeItem(name)` - Remove by text
- `removeItemByIndex(index)` - Remove by index
- `removeFirst()` - Remove first item
- `clear()` - Clear all items
- `contains(text)` - Check if item exists
- `getItem(index)` - Get item at index
- `getIndexOf(text)` - Get index of item
- `size()` - Get item count
- `setOnMouseDownFunction(target, func)` - Set selection callback
- `setOnMouseDoubleClick(target, func)` - Set double-click callback
- `setFont(font, padY)` - Set font and padding
- `setTextColorRGBA(r, g, b, a)` - Set text color
- `setSelectedTextColorRGBA(...)` - Set selected color
- `sort(comparator)` - Sort items
- `addColumn(name, size)` - Add column header
- `ensureVisible(index)` - Scroll to show item

**Item Structure:**
```lua
item = {
    text = "Item text",           -- Display text
    item = userObject,            -- Associated object
    tooltip = "Tooltip text",     -- Hover tooltip
    height = 20,                  -- Item height
    textColor = {r, g, b, a},     -- Custom color (optional)
    selectedTextColor = {...}     -- Custom selected color (optional)
}
```

**Callback Signatures:**
```lua
-- onmousedown (item selected)
function onSelection(target, item)
    print("Selected: " .. item.text)
end

-- onmousedblclick (item double-clicked)
function onDoubleClick(target, item)
    print("Double-clicked: " .. item.text)
end
```

**Example:**
```lua
local listbox = ISScrollingListBox:new(50, 50, 250, 300)
listbox:initialise()
listbox:addItem("Option 1", {data="opt1"}, "Tooltip 1")
listbox:addItem("Option 2", {data="opt2"}, "Tooltip 2")
listbox:setOnMouseDownFunction(self, function(target, item)
    print("Selected: " .. item.text)
end)
panel:addChild(listbox)
```

---

## Common Patterns & Tips

### Creating a Custom Window
```lua
MyCustomWindow = ISCollapsableWindow:derive("MyCustomWindow")

function MyCustomWindow:new(x, y, player)
    local self = ISCollapsableWindow:new(x, y, 300, 250)
    setmetatable(self, MyCustomWindow)
    MyCustomWindow.__index = self

    self.player = player
    return self
end

function MyCustomWindow:initialise()
    ISCollapsableWindow.initialise(self)
end

function MyCustomWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    self:setTitle("My Window")

    local btn = ISButton:new(10, 50, 100, 25, "Test", self, function()
        print("clicked")
    end)
    btn:initialise()
    self:addChild(btn)
end

-- Usage:
local window = MyCustomWindow:new(100, 100, player)
window:initialise()
window:createChildren()
window:addToUIManager()
```

### Anchoring Elements
```lua
-- Anchor to all edges (stretch to parent)
element:setAnchorLeft(true)
element:setAnchorRight(true)
element:setAnchorTop(true)
element:setAnchorBottom(true)

-- Or use shorthand:
element:setAnchorsTBLR(true, true, true, true)
```

### Event Handling
```lua
local obj = ISBaseObject:new()
obj:addEventListener("myevent", function(target, param)
    print("Event: " .. param)
end, self)

obj:triggerEvent("myevent", "hello")
```

### Safe Window Closing
```lua
function MyWindow:close()
    ISCollapsableWindow.close(self)
    self:removeFromUIManager()
    -- Clean up your resources here
end
```
