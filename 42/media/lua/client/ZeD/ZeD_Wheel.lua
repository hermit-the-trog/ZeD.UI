-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Wheel.lua
-- ============================================================================
-- THE WHEEL — vanilla's radial menus as the context strip's cells on a ring.
-- Mockup ZeDUI/mockups/zed_wheels_v1.html (approved Oct 15 2026: keep the wheel,
-- larger cells, ZeD icons with vanilla's own pictures where they say more).
-- HOOK_MAP row 29; Overrides/Wheels.lua puts this in place of the engine's
-- drawing for both vanilla wheels (getPlayerRadialMenu's ISRadialMenu and the
-- controller's ISBackButtonWheel).
--
-- Geometry is the engine's (RadialMenu.class, KB Q241): slice 1 centred at
-- 12 o'clock, the rest clockwise, each 360 / max(n, 2) degrees; a slice with
-- no text and no picture is an empty place (kept, never drawn or picked). The
-- pointer's direction (outside a small dead zone) or the right stick picks.
--
-- Drawn with the strip's own parts: ZeD.Molecules.drawContextCell (paper cell,
-- ink icon, accent when pointed, stipple when off, corner triangle, back glyph)
-- at a larger size, the System 7 stepped shadow, and the strip's balloon
-- (ZeD.Molecules.drawContextBalloon) above the ring naming the pointed slice.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/ContextMenuRegistry"

ZeD = ZeD or {}
ZeD.Wheel = ZeD.Wheel or {}
local W = ZeD.Wheel

-- design units
local U = {
    CELL = 22, ICON = 16,     -- a cell at rest: the strip's own size
    CELL_ON = 33, ICON_ON = 24, -- the pointed cell grows to 1.5x (director, Oct 15: smaller at rest, bigger when pointed)
    GAP = 10,                 -- room between neighbouring resting cells (centre to centre: CELL + GAP),
                              -- enough that the grown cell clears its neighbours too
    MIN_R = 28,               -- the ring's smallest radius: the pointed cell just clears the hub. Above
                              -- it the ring follows the number of slices (director, Oct 15: "is the size of
                              -- the wheel determined by the amount of actions?")
    DEAD = 0.4,               -- the pointer's dead zone, as a share of the ring's radius
    BUBBLE = 110,             -- room above the ring for the balloon
    HUB = 7,                  -- the small square at the centre
    DOT = 2,                  -- the ring line: a dot every 2 units
    STICK = 0.35,             -- the right stick picks once it is pushed this far
}
W.U = U

local INK = { r = 0.08, g = 0.08, b = 0.08, a = 1 }
local PAPER = { r = 0.95, g = 0.95, b = 0.95, a = 1 }

local function lower(s) return string.lower(tostring(s or "")) end

-- ---------------------------------------------------------------------------
-- PICTURES: ZeD's icons where the meaning is plain, vanilla's own pictures
-- where they say more (gestures, the firearm's steps, zoom and game speed,
-- battery, items); anything unknown keeps its own picture (mods included)
-- ---------------------------------------------------------------------------
local _icons = {}
local function zicon(name)
    if _icons[name] == nil then _icons[name] = getTexture("media/textures/ZeD/icons/" .. name .. ".png") or false end
    return _icons[name] or nil
end

-- the slice's words first (several vanilla slices share one picture)
-- ({ English words, icon, vanilla key that says the same in the player's language })
local TEXT_ICONS = {
    { "survival guide", "info-guide", "UI_optionscreen_binding_Toggle Survival Guide" },
    { "mini-map", "map-marker", "IGUI_MiniMap_Toggle" }, { "mini map", "map-marker", "IGUI_MiniMap_Focus" },
    { "shout", "bullhorn", "IGUI_Emote_Shout" },
}
-- vanilla's pictures that stay
local KEEP = { "emotes/", "firearmradial", "zoomin", "zoomout", "speedcontrols", "lightsourceradial",
               "item_", "trait_", "xbox", "joypad", "media/inventory" }
-- vanilla's pictures that become ZeD icons (by the texture's name)
local TEX_ICONS = {
    { "vehicle_changeseats", "fi-br-person-seat" }, { "vehicle_ignition", "engine" }, { "vehicle_lights", "lightbulb-on" },
    { "vehicle_temperaturehot", "fire-flame-curved" }, { "vehicle_horn", "bullhorn" }, { "vehicle_speakers", "fm-radio" },
    { "vehicle_window", "doomsday-048-window" }, { "vehicle_lockdoors", "fi-br-lock" }, { "vehicle_repair", "car-mechanic" },
    { "vehicle_sleep", "face-sleeping" }, { "vehicle_exit", "exit" }, { "vehicle_smash_window", "hammer-crash" },
    { "vehicle_refuel", "gas-pump" }, { "vehicle_add_gas", "gas-pump" }, { "gas_refuel", "gas-pump" }, { "gas_siphon", "gas-pump" },
    { "animalactions_kill", "knife" }, { "animalactions_grab", "fi-br-picking-box" }, { "animalactions_milk", "milk" },
    { "animalactions_pet", "hand" }, { "animalactions_rope", "knot-rope" }, { "animalactions_shear", "scissors" },
    { "animalactions_stats", "info" },
    { "heart2_on", "heart-rate" }, { "carpentry_on", "hammer" }, { "build_tool", "carpentry-015-toolbox" },
    { "furniture_off2", "sofa" }, { "furniture_pickup", "fi-br-picking-box" }, { "furniture_place", "box-target" },
    { "furniture_rotate", "rotate-left" }, { "furniture_disassemble", "carpentry-031-screwdriver" }, { "furniture_on2", "fi-br-wrench-alt" },
    { "foraging/eyecon", "eye" }, { "search_on_64", "fi-br-magnifying-glass-wave" }, { "search_off_64", "fi-br-magnifying-glass-wave" },
    { "animalzone_on_64", "cow" }, { "worldmap/map_on", "crafting-game-037-map" },
}
-- the item and the words vanilla adds with no action carry no name of their own
local OFF_NAMES = {
    { "vehicle_ignition", "IGUI_VehiclePartEngine" }, { "vehicle_sleep", "ContextMenu_Sleep" }, { "vehicle_repair", "ContextMenu_VehicleMechanics" },
    { "item_petrol", "Fluid_Name_Petrol" },
}

local function texName(tex)
    if not tex then return "" end
    local ok, n = pcall(function() return tex:getName() end)
    -- a file texture is named by its full Windows path: one separator for the patterns
    return ok and (lower(n):gsub("\\", "/")) or ""
end

-- the picture for a slice: texture, tintable (a ZeD icon takes the ink / accent)
function W.picture(slice)
    local text = lower(slice.text)
    for _, m in ipairs(TEXT_ICONS) do
        local own = m[3] and getTextOrNull and getTextOrNull(m[3])
        if text:find(m[1], 1, true) or (own and own ~= "" and text:find(lower(own), 1, true)) then
            local t = zicon(m[2]); if t then return t, true end
        end
    end
    local name = texName(slice.texture)
    for _, k in ipairs(KEEP) do
        if name:find(k, 1, true) then return slice.texture, false end
    end
    for _, m in ipairs(TEX_ICONS) do
        if name:find(m[1], 1, true) then local t = zicon(m[2]); if t then return t, true end end
    end
    local first = tostring(slice.text or ""):match("^[^\n]*")
    -- by the registry, so the name in the player's language finds its icon (not only the English text)
    local R = ZeD.ContextMenu and ZeD.ContextMenu.Registry
    if R and R.resolveIconForName and first and first ~= "" then
        local ok, t = pcall(R.resolveIconForName, first)
        if ok and t then return t, true end
    end
    local ci = ZeD.ContextIcons and first and ZeD.ContextIcons[first]
    if ci then local t = zicon(ci); if t then return t, true end end
    return slice.texture, false
end

-- ---------------------------------------------------------------------------
-- slices: what vanilla gave, read the strip's way
-- ---------------------------------------------------------------------------
function W.isPlace(slice) return slice and not slice.text and not slice.texture end
function W.isOff(slice) return slice and not W.isPlace(slice) and not (slice.command and slice.command[1]) end
function W.isBack(slice) return slice and texName(slice.texture):find("emotes/back", 1, true) ~= nil end
function W.hasSub(slice)
    local c = slice and slice.command
    if slice and slice._zedSub then return true end   -- (ZeD_QuickWheel: Eat, Drink ... open a wheel of items)
    return c and ISEmoteRadialMenu and c[1] == ISEmoteRadialMenu.fillMenu and c[3] ~= nil or false
end

local function lines(text)
    local out = {}
    for l in (tostring(text or "") .. "\n"):gmatch("([^\n]*)\n") do
        l = l:gsub("^%s+", ""):gsub("%s+$", "")
        if l ~= "" then out[#out + 1] = l end
    end
    return out
end

local function offName(slice)
    local name = texName(slice.texture)
    for _, m in ipairs(OFF_NAMES) do if name:find(m[1], 1, true) then return ZeD.tr(m[2]) end end
    return nil
end

-- ---------------------------------------------------------------------------
-- GEOMETRY (the engine's)
-- ---------------------------------------------------------------------------
-- cell / icon at rest, the ring's radius, the centre, cell / icon when pointed. Neighbouring
-- centres sit CELL + GAP apart in a straight line (the chord, not the arc), so a full
-- wheel never overlaps.
function W.geom(menu)
    local T = ZeD.T
    local n = #menu.slices
    local cell, icon = T.px(U.CELL), T.px(U.ICON)
    local cellOn, iconOn = T.px(U.CELL_ON), T.px(U.ICON_ON)
    local r = T.px(U.MIN_R)
    if n >= 3 then r = math.max(r, (cell + T.px(U.GAP)) / (2 * math.sin(math.pi / n))) end
    return cell, icon, math.floor(r), math.floor(menu.width / 2), math.floor(menu.height / 2), cellOn, iconOn
end

-- the slice in a direction (dx, dy in screen terms: y down); 1-based, or -1
function W.sliceAt(menu, dx, dy)
    local n = #menu.slices
    if n == 0 then return -1 end
    local step = 360 / math.max(n, 2)
    local deg = math.deg(math.atan2(dy, dx))
    local a = (deg + 90 + step / 2) % 360
    local i = math.floor(a / step) + 1
    if i < 1 or i > n or W.isPlace(menu.slices[i]) then return -1 end
    return i
end

function W.sliceFromMouse(menu, x, y)
    local _, _, r, cx, cy = W.geom(menu)
    local dx, dy = x - cx, y - cy
    if math.sqrt(dx * dx + dy * dy) < math.max(ZeD.T.px(10), r * U.DEAD) then return -1 end
    return W.sliceAt(menu, dx, dy)
end

function W.sliceFromJoypad(menu, id)
    if not id or id < 0 then return -1 end
    local ok, ax, ay = pcall(function() return getJoypadAimingAxisX(id), getJoypadAimingAxisY(id) end)
    if not ok or not ax or not ay then return -1 end
    if math.sqrt(ax * ax + ay * ay) < U.STICK then return -1 end
    return W.sliceAt(menu, ax, ay)
end

-- room for the ring and the balloon; the wheel keeps its centre when it grows
function W.fit(menu)
    local T = ZeD.T
    if not (T and T.px) then return end
    local _, _, r, _, _, cellOn = W.geom(menu)
    local side = math.floor(math.max((menu.outerRadius or 200) * 2, 2 * (r + cellOn + T.px(U.BUBBLE))))
    if menu.width ~= side or menu.height ~= side then
        local cx, cy = (menu.x or 0) + (menu.width or side) / 2, (menu.y or 0) + (menu.height or side) / 2
        menu:setWidth(side)
        menu:setHeight(side)
        menu:setX(math.floor(cx - side / 2))
        menu:setY(math.floor(cy - side / 2))
    end
end

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------
-- one cell: the stepped shadow, the strip's cell at the wheel's size, the ink edge
local function drawCell(menu, x, y, cell, icon, slice, active)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    if slice._zedTex == nil then
        local tex, tint = W.picture(slice)
        slice._zedTex, slice._zedTint = tex or false, tint
    end
    local def = { iconTexture = slice._zedTex or nil, iconTintable = slice._zedTint, name = slice.text }
    local flags = { isActive = active, isDisabled = W.isOff(slice), hasSub = W.hasSub(slice), isBack = W.isBack(slice) }
    A.drawSteppedShadow(menu, x, y, cell, cell, INK)
    local ctx = T.ctx
    local cw, ch, ip, ts = ctx.cellW, ctx.cellH, ctx.iconPx, ctx.submenuTriSz
    ctx.cellW, ctx.cellH, ctx.iconPx, ctx.submenuTriSz = cell, cell, icon, T.px(4)
    local ok, err = pcall(M.drawContextCell, menu, x, y, def, flags, T)
    ctx.cellW, ctx.cellH, ctx.iconPx, ctx.submenuTriSz = cw, ch, ip, ts
    if not ok then ZeD.logOnce("Wheel: cell", err) end
    if not active then menu:drawRectBorder(x, y, cell, cell, 1, INK.r, INK.g, INK.b) end
    -- a colour to pick (the ZeD wheel's accents): its swatch in the cell
    if slice._zedSwatch then
        local sw = math.floor(icon * 0.75)
        A.drawStatusDot(menu, x + math.floor((cell - sw) / 2), y + math.floor((cell - sw) / 2), slice._zedSwatch, sw)
    end
end

function W.draw(menu)
    local T = ZeD.T
    if not (T and T.px) then return end
    local slices = menu.slices or {}
    local n = #slices
    if n == 0 then return end
    local cell, icon, r, cx, cy, cellOn, iconOn = W.geom(menu)
    -- the ring line through the cells and the hub
    local u = T.px(1)
    local step = T.px(U.DOT) / math.max(1, r)
    local a = 0
    while a < 2 * math.pi do
        menu:drawRect(math.floor(cx + r * math.cos(a)), math.floor(cy + r * math.sin(a)), u, u, 0.55, INK.r, INK.g, INK.b)
        a = a + step
    end
    local hs = T.px(U.HUB)
    menu:drawRect(cx - math.floor(hs / 2), cy - math.floor(hs / 2), hs, hs, 1, PAPER.r, PAPER.g, PAPER.b)
    menu:drawRectBorder(cx - math.floor(hs / 2), cy - math.floor(hs / 2), hs, hs, 1, INK.r, INK.g, INK.b)
    -- the cells, slice 1 at 12 o'clock and clockwise: at rest the strip's size, the
    -- pointed one grown and drawn last (over the ring line, never over a neighbour)
    local sstep = 360 / math.max(n, 2)
    local function place(i, size)
        local ang = math.rad(-90 + (i - 1) * sstep)
        return math.floor(cx + r * math.cos(ang) - size / 2), math.floor(cy + r * math.sin(ang) - size / 2)
    end
    for i, s in ipairs(slices) do
        if not W.isPlace(s) and i ~= menu._zedPoint then
            local x, y = place(i, cell)
            drawCell(menu, x, y, cell, icon, s, false)
        end
    end
    local pi = menu._zedPoint
    if pi and pi > 0 and slices[pi] and not W.isPlace(slices[pi]) then
        local x, y = place(pi, cellOn)
        drawCell(menu, x, y, cellOn, iconOn, slices[pi], true)
    end
    -- the balloon above the ring: the pointed slice, or the open category
    local state
    local p = menu._zedPoint and slices[menu._zedPoint]
    if p and not W.isPlace(p) then
        local ls = lines(p.text)
        if W.isOff(p) then
            -- vanilla's words are the reason: under the slice's name, with the red dot
            local nm = offName(p)
            if nm then
                state = { labelText = nm, stateText = table.concat(ls, " "), stateKind = "bad" }
            elseif #ls > 1 then
                state = { labelText = ls[1], stateText = table.concat(ls, " ", 2), stateKind = "bad" }
            else
                state = { labelText = ls[1] or "" }
            end
        else
            state = { labelText = ls[1] or "", bodyText = table.concat(ls, " ", 2) }
        end
        if menu._zedTitle then state.parentChain = { menu._zedTitle } end
        if p._zedChord then state.labelPads = p._zedChord end   -- (its quick action chord: ZeD_DpadWheels / ZeD_QuickChords)
        if p._zedNote then state.bodyText, state.stateText, state.stateKind = p._zedNote, nil, nil end   -- (what assigning it did)
    elseif menu._zedTitle then
        state = { labelText = menu._zedTitle }
    end
    if state then
        local apexY = cy - r - math.floor(cellOn / 2) - T.px(6)
        state.pointerDir = "down"
        state.snug = true   -- (as wide as the words: a short second line keeps the bubble small)
        -- no room above (a wheel near the screen's top): under the ring instead
        if menu:getAbsoluteY() + apexY - T.px(80) < 0 then
            state.pointerDir = "up"
            apexY = cy + r + math.ceil(cellOn / 2) + T.px(6)
        end
        local ok, err = pcall(ZeD.Molecules.drawContextBalloon, menu, cx, apexY, state, T)
        if not ok then ZeD.logOnce("Wheel: balloon", err) end
    end
    -- the D-pad wheels (ZeD_DpadWheels.lua): the breadcrumb and the button
    -- prompts under the ring (mockup zed_dpad_wheels_v2)
    if menu._zedCrumb or menu._zedPrompts then
        local ok, err = pcall(W.drawUnder, menu, cx, cy + r + math.ceil(cellOn / 2) + T.px(12))
        if not ok then ZeD.logOnce("Wheel: crumb", err) end
    end
end

-- a strip on the theme's surface, centred on cx: the breadcrumb (which wheel,
-- and where in it), then the controller's prompts for this wheel
local NOP = { drawRectBorder = function() end, drawText = function() end, drawRect = function() end }
local BACKING_A = 0.92   -- the strips sit over the world: the surface nearly opaque
function W.drawUnder(menu, cx, y)
    local T, tm, A, M = ZeD.T, ZeD.TM, ZeD.Atoms, ZeD.Molecules
    local font = T.fontF5
    if menu._zedCrumb then
        -- the breadcrumb: a neutral badge (its own words, upper case) on the surface
        local s = ZeD.upper(menu._zedCrumb)
        local w = tm:MeasureStringX(font, s) + T.sp.badgePadX * 2
        local h = tm:MeasureStringY(font, s) + T.sp.badgePadY * 2
        local x = math.floor(cx - w / 2)
        M.drawBodyBg(menu, x, y, w, h, "surf1", BACKING_A)
        A.drawBadge(menu, s, x, y, "neutral", false, font, true)
        y = y + h + T.px(8)
    end
    if menu._zedPrompts then
        -- the prompts: the footers' glyph legend on the surface, in a border
        local padX = T.px(7)
        local h = T.px(24)
        local inner = M.drawGlyphPrompts(NOP, 0, 0, h, menu._zedPrompts) - T.sp.sm * 2
        local w = inner + padX * 2
        local x = math.floor(cx - w / 2)
        M.drawBodyBg(menu, x, y, w, h, "surf1", BACKING_A)
        A.drawBorder(menu, x, y, w, h)
        M.drawGlyphPrompts(menu, x + padX, y, h, menu._zedPrompts)
    end
end

-- the pointed slice, from the stick (a controller holds the wheel) or the mouse
function W.update(menu)
    if W.qaPoint then menu._zedPoint = W.qaPoint; return end   -- QA: a pointed slice without a pointer (zedqa_wheels.lua)
    if menu.joyfocus then
        menu._zedPoint = W.sliceFromJoypad(menu, menu.joyfocus.id)
    else
        menu._zedPoint = W.sliceFromMouse(menu, menu:getMouseX(), menu:getMouseY())
    end
end

-- a category being opened names the next wheel (the emote categories)
function W.noteChoice(menu, slice)
    if W.hasSub(slice) then
        W._pendingTitle, W._pendingFor = (lines(slice.text)[1]), menu
    end
end

function W.onClear(menu)
    if W._pendingFor == menu then
        menu._zedTitle = W._pendingTitle
        W._pendingTitle, W._pendingFor = nil, nil
    else
        menu._zedTitle = nil
    end
    menu._zedPoint = -1
    menu._zedCrumb, menu._zedPrompts, menu._zedDpad = nil, nil, nil   -- (a D-pad wheel sets them again after its clear)
end
