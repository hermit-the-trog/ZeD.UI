# ISXuiSkin Theming Reference

Build 42 introduced ISXuiSkin to decouple visual styling from UI logic. Instead of hardcoding colors in every component, styles are defined in skin tables and applied at construction time.

## How It Works

### Skin Tables

A skin is a Lua table mapping style names to property sets. Each style name (like `"S_TableLayout_Main"`) defines colors, fonts, and other visual properties for a specific component type.

```lua
-- Simplified skin structure
local skin = {
    S_TableLayout_Main = {
        backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9},
        borderColor = {r=0.3, g=0.3, b=0.3, a=1},
        font = UIFont.Small,
    },
    S_Button_Default = {
        backgroundColor = {r=0.15, g=0.15, b=0.15, a=0.9},
        backgroundColorMouseOver = {r=0.25, g=0.25, b=0.25, a=0.9},
        textColor = {r=0.9, g=0.9, b=0.9, a=1},
        borderColor = {r=0.4, g=0.4, b=0.4, a=1},
    },
}
```

### Building Skinned Components

`ISXuiSkin.build()` creates a component and applies skin properties in one call:

```lua
local panel = ISXuiSkin.build(skin, "S_TableLayout_Main", ISTableLayout, x, y, w, h)
-- Equivalent to:
--   local panel = ISTableLayout:new(x, y, w, h)
--   panel.backgroundColor = skin.S_TableLayout_Main.backgroundColor
--   panel.borderColor = skin.S_TableLayout_Main.borderColor
--   etc.
```

The first argument is the skin table, the second is the style name, the third is the class to instantiate, and the rest are constructor arguments.

### Finding Existing Styles

The game uses 200+ `ISXuiSkin.build` calls. To discover existing style names:

```
-- Grep the game source for skin usage
grep -r "ISXuiSkin.build" media/lua/client/
grep -r "xuiSkin" media/lua/client/
```

Common style name patterns:
- `S_TableLayout_*` — Table and grid layouts
- `S_Button_*` — Button variants
- `S_Panel_*` — Panel styles
- `S_Label_*` — Text labels
- `S_ScrollBar_*` — Scrollbar styling

## Overriding Skins for Your Mod

### Method 1: Modify the Skin Table

Hook into the skin system after it loads and replace style values:

```lua
Events.OnGameStart.Add(function()
    -- Find the active skin table (check game source for current access pattern)
    -- Override specific style entries
    local skin = getActiveSkin()  -- actual accessor varies, read the source
    if skin and skin.S_TableLayout_Main then
        skin.S_TableLayout_Main.backgroundColor = ZeD.Tokens.bgPanel
        skin.S_TableLayout_Main.borderColor = ZeD.Tokens.border
    end
end)
```

This reskins every vanilla component that uses those style names without touching any of their code.

### Method 2: Pass Custom Skins to Your Windows

For your own components, build your own skin table using your design tokens:

```lua
ZeD.Skin = {
    ZeD_Panel = {
        backgroundColor = ZeD.Tokens.bgPanel,
        borderColor = ZeD.Tokens.border,
    },
    ZeD_Button = {
        backgroundColor = ZeD.Tokens.bgPanel,
        backgroundColorMouseOver = {r=0.20, g=0.20, b=0.20, a=0.9},
        textColor = ZeD.Tokens.text,
        borderColor = ZeD.Tokens.border,
    },
    ZeD_Header = {
        backgroundColor = ZeD.Tokens.bg,
        textColor = ZeD.Tokens.text,
        font = ZeD.Tokens.fontHeading,
    },
}

-- Use it
local panel = ISXuiSkin.build(ZeD.Skin, "ZeD_Panel", ISPanel, x, y, w, h)
```

### Method 3: Entity Window Skins

ISBaseEntityWindow integrates with ISXuiSkin automatically. When you create an entity window, the skin gets passed down to child components:

```lua
function ZeD_BenchWindow:createChildren()
    ISBaseEntityWindow.createChildren(self)
    -- self.xuiSkin is automatically available
    self:createEntityHeader(self.xuiSkin, "EntityHeader")

    -- Use the skin for child components
    local infoPanel = ISXuiSkin.build(self.xuiSkin, "S_Panel_Info", ISPanel, x, y, w, h)
    self:addChild(infoPanel)
end
```

## Skin + Design Tokens Strategy

For a total UI overhaul, use both systems together:

1. **Design tokens** (`ZeD.Tokens`) are your single source of truth for visual values
2. **Skin tables** (`ZeD.Skin`) translate tokens into the format ISXuiSkin expects
3. **Factory functions** (`ZeD.Panel()`, `ZeD.Button()`) apply tokens directly for quick component creation
4. **Skin overrides** modify vanilla skin entries so unmodified vanilla components still match your visual language

This layered approach means:
- Your custom windows use your design system directly
- Vanilla windows you haven't replaced yet still pick up your color scheme through skin overrides
- Everything stays consistent as you work through the overhaul, component by component
