-- ZeD-UI/42/media/lua/client/ZeD/GridTint.lua
-- ============================================================================
-- ITEM-COLORED GRID TILES (the director, Nov 16 2026) - client; a helper, no component of its own
-- (InventoryRenderer's drawGridCell asks it for a tile's fill, so every grid view has it, the Multi-Slot
-- add-on's spans too, as GridLayout.lua draws each span with drawGridCell).
--
-- With "Item-colored tiles" on (ZeD setup, Look; off by default) a tile's fill is a soft, grayish tint of its
-- item's main color in place of the plain stripe: a CD blue, an axe red, a bat tan. The main colors are baked
-- from the game's icons (ZeDUI/tools/grid_tint/bake_item_tints.py -> shared/ZeD/ItemTints.lua), as Kahlua
-- cannot read a texture's pixels. Only the raw color is stored; the rule per theme is here, so a theme
-- change shows at once:
--   Light          lightness 0.74, saturation at most 0.30 (the director's pick: soft and gray, not pastel)
--   Dark           lightness 0.17, saturation at most 0.30 (deep and muted: the director picked a little darker)
--   High contrast  lightness 0.13, saturation at most 0.36 (deeper still, so the white text and marks stand off)
-- The hue is the item's. The weight and count sit on their own surface chips and the condition strip is framed,
-- so they read as before. A gray, black or white icon is baked as neutral gray, so it takes a soft gray tint (the
-- director's pick); an icon not in the table (another mod's item) keeps the plain fill.
-- Cost: one table lookup per tile per frame; the name lookup and the color math run once per texture and theme.
-- Pure ASCII.
-- ============================================================================

ZeD = ZeD or {}
ZeD.GridTint = ZeD.GridTint or {}
local G = ZeD.GridTint

-- per base theme: the tile's lightness and the most saturation it keeps (an unknown theme takes Dark's)
G.RULES = {
    light = { l = 0.74, s = 0.30 },
    dark  = { l = 0.17, s = 0.30 },
    hicon = { l = 0.13, s = 0.36 },
}

-- (one per texture: false for no tint, else { raw = 0xRRGGBB, [baseKey] = { r, g, b } }; never theme colors
-- read from ZeD.T, only the fixed rule's result, so a theme change still shows at once)
G._cache = G._cache or {}

--- The setting: "Item-colored tiles" (ZeD setup, Look)
function G.on()
    local S = ZeD.Settings
    return S and S.gridTint and S.gridTint() or false
end

-- HLS as Python's colorsys works it (the bake and the preview use the same), all 0 to 1
local function hue(m1, m2, h)
    h = h - math.floor(h)
    if h < 1 / 6 then return m1 + (m2 - m1) * h * 6 end
    if h < 0.5 then return m2 end
    if h < 2 / 3 then return m1 + (m2 - m1) * (2 / 3 - h) * 6 end
    return m1
end

--- A raw color (0xRRGGBB) under a rule { l, s }: its hue at the rule's lightness, its saturation capped.
--- Returns r, g, b, each 0 to 1.
function G.apply(raw, rule)
    local r = math.floor(raw / 65536) % 256 / 255
    local g = math.floor(raw / 256) % 256 / 255
    local b = raw % 256 / 255
    local mx, mn = math.max(r, g, b), math.min(r, g, b)
    local l = rule.l
    local h, s = 0, 0
    if mx > mn then
        local d = mx - mn
        local ol = (mx + mn) / 2
        if ol <= 0.5 then s = d / (mx + mn) else s = d / (2 - mx - mn) end
        local rc, gc, bc = (mx - r) / d, (mx - g) / d, (mx - b) / d
        if r == mx then h = bc - gc elseif g == mx then h = 2 + rc - bc else h = 4 + gc - rc end
        h = (h / 6) - math.floor(h / 6)
    end
    if s > rule.s then s = rule.s end
    if s <= 0 then return l, l, l end
    local m2 = (l <= 0.5) and (l * (1 + s)) or (l + s - l * s)
    local m1 = 2 * l - m2
    return hue(m1, m2, h + 1 / 3), hue(m1, m2, h), hue(m1, m2, h - 1 / 3)
end

--- A texture's key in ZeD.ItemTints: its name without a folder, ".png" or "Item_" ("Item_Axe" -> "Axe";
--- a loose file's texture is named by its path)
function G.key(name)
    if type(name) ~= "string" or name == "" then return nil end
    name = name:gsub("\\", "/")
    name = name:match("([^/]+)$") or name
    name = name:gsub("%.[pP][nN][gG]$", "")
    name = name:gsub("^Item_", "")
    return name
end

--- A tile's fill for tex on the theme T: r, g, b (0 to 1), or nil for the plain fill (the setting off, no
--- texture, or an icon with no main color). force: tinted whatever the setting says (an add-on's shaped grid,
--- GridLayout version 2: the director's approved shapes are all tinted, Nov 16 2026)
function G.of(T, tex, force)
    if not tex or not (force or G.on()) then return nil end
    local c = G._cache[tex]
    if c == nil then
        local ok, n = pcall(function() return tex:getName() end)
        local k = ok and G.key(n) or nil
        local raw = k and ZeD.ItemTints and ZeD.ItemTints[k] or nil
        c = raw and { raw = raw } or false
        G._cache[tex] = c
    end
    if not c then return nil end
    local bk = (T and G.RULES[T.baseKey]) and T.baseKey or "dark"
    local t = c[bk]
    if not t then
        local r, g, b = G.apply(c.raw, G.RULES[bk])
        t = { r, g, b }
        c[bk] = t
    end
    return t[1], t[2], t[3]
end

-- ============================================================================
-- THE CONTAINER STRIPS' TINTED BUTTONS (the director, Nov 25 2026; mock-up ZeDUI/mockups/container_tabs_color_v4.html,
-- "Stronger tint"; the shown one since framed by one hairline, no wash). Always on: each container button of both windows is filled with a stronger
-- tint of its picture's main color than the grid's tiles take; the shown one keeps its tint and gains a one-hairline
-- frame (the accent's bright tone; on Light a darker accent), no wash (the director, Nov 25 2026).
-- The colors: ZeD.ContainerTints (the game's Container_* pictures, the world's containers and the main inventory)
-- or ZeD.ItemTints (a bag's item icon); a picture in neither (another mod's) takes the neutral gray.
-- ============================================================================
G.STRIP = {
    light = { l = 0.80, s = 0.60 },
    dark  = { l = 0.26, s = 0.50 },
    hicon = { l = 0.20, s = 0.55 },
}
G._strip = G._strip or {}   -- per texture: { raw = 0xRRGGBB, [baseKey] = { r, g, b } }

--- A container button's picture's main color, 0xRRGGBB (a neutral gray when it has none known)
function G.stripRaw(tex)
    if not tex then return 0x808080 end
    local c = G._strip[tex]
    if c then return c.raw end
    local ok, n = pcall(function() return tex:getName() end)
    local name = ok and type(n) == "string" and n or ""
    name = name:gsub("\\", "/")
    name = name:match("([^/]+)$") or name
    name = name:gsub("%.[pP][nN][gG]$", "")
    local raw = ZeD.ContainerTints and ZeD.ContainerTints[name]
    if not raw then
        local k = G.key(name)
        raw = k and ZeD.ItemTints and ZeD.ItemTints[k] or nil
    end
    c = { raw = raw or 0x808080 }
    G._strip[tex] = c
    return c.raw
end

--- The button's fill on the theme T: r, g, b
function G.stripFill(T, tex)
    local bk = (T and G.STRIP[T.baseKey]) and T.baseKey or "dark"
    G.stripRaw(tex)
    local c = G._strip[tex or false] or { raw = 0x808080 }
    if not tex then G._strip[false] = c end
    local t = c[bk]
    if not t then
        local r, g, b = G.apply(c.raw, G.STRIP[bk])
        t = { r, g, b }
        c[bk] = t
    end
    return t[1], t[2], t[3]
end

--- One container button's background in (x, y, w, h) of panel: the tint, then the shown look (a one-hairline
--- frame) or the pointer's hover wash. The icon and the controller's mark go on after, as before.
function G.stripCell(panel, x, y, w, h, tex, lit, hover)
    local T = ZeD.T
    local r, g, b = G.stripFill(T, tex)
    panel:drawRect(x, y, w, h, 1, r, g, b)
    if lit then
        -- the shown one: its own tint and a one-hairline frame, no accent wash (the director, Nov 25 2026, after the
        -- frame fix's before and after: "single pixel outline/highlight, no wash")
        local ac = T.accent
        local f = T.px(1)
        local fr, fg, fb
        if T.baseKey == "light" then
            fr, fg, fb = ac.r * 0.72, ac.g * 0.72, ac.b * 0.72
        else
            local br = T.accentBright or ac
            fr, fg, fb = br.r, br.g, br.b
        end
        panel:drawRect(x, y, w, f, 1, fr, fg, fb)
        panel:drawRect(x, y + h - f, w, f, 1, fr, fg, fb)
        panel:drawRect(x, y, f, h, 1, fr, fg, fb)
        panel:drawRect(x + w - f, y, f, h, 1, fr, fg, fb)
    elseif hover then
        local hv = T.hover
        panel:drawRect(x, y, w, h, hv.a, hv.r, hv.g, hv.b)
    end
end
