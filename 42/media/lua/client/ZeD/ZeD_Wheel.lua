-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Wheel.lua
-- ============================================================================
-- THE WHEEL — vanilla's radial menus as the context strip's cells on a ring.
-- Mockup ZeDUI/mockups/zed_wheels_v1.html (approved Oct 15 2026: keep the wheel,
-- larger cells, ZeD icons with vanilla's own pictures where they say more); since
-- Oct 27 2026 every slice draws the wheels' own icons (PICTURES below).
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
-- at a larger size, System 7's hard shadow, and the strip's balloon
-- (ZeD.Molecules.drawContextBalloon) above the ring naming the pointed slice.
-- Under the ring, for the D-pad wheels: the breadcrumb as a tag and the
-- controller's prompts in a pop-up box (solid, the 1u frame, the hard shadow).
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
-- PICTURES: the wheels' own icons (the director's, Oct 27 2026; handoff
-- ZeDUI/HANDOFF_wheel_icons_20261027.md, map wheel_icons_map.json, source
-- ZeDUI/tools/wheelpx). Items, traits and the controller's glyphs keep their
-- pictures; anything unknown keeps its own (mods included).
-- ---------------------------------------------------------------------------
local _icons = {}
local function zicon(name)
    if _icons[name] == nil then _icons[name] = getTexture("media/textures/ZeD/icons/" .. name .. ".png") or false end
    return _icons[name] or nil
end

-- a wheel icon by its id, for an icon box of `box` screen px: the largest of
-- its four drawings that fits, drawn at its own size (pixel for pixel, never
-- stretched); a box under 16 scales the 16 down. Returns texture, size.
-- The files carry the zw_ prefix: a plain name such as map.png loads the game's
-- packed picture of that name instead (KB Q143). Nearest filtering (KB Q205).
local WHEEL_DIR = "media/textures/ZeD/wheel/"
local WHEEL_SIZES = { 48, 32, 24, 16 }
local _wheel = {}
local function wheelTex(size, id)
    local path = WHEEL_DIR .. size .. "/zw_" .. id .. ".png"
    if _wheel[path] == nil then _wheel[path] = Texture.getSharedTexture(path, 3) or false end   -- 3 = nearest filtering
    return _wheel[path] or nil
end
function W.iconTex(id, box)
    if not id then return nil, box end
    for _, s in ipairs(WHEEL_SIZES) do
        if s <= box then
            local t = wheelTex(s, id)
            if t then return t, s end
        end
    end
    return wheelTex(16, id), box
end

-- the tab a slice opens names it by the tab's icon (C.tabs, Wd.tabs: ZeD_DpadWheels)
W.TAB_ICONS = {
    ["loot-tab-white"] = "crate", ["equipment-tab-white"] = "jacket", ["health-tab-white"] = "heart",
    ["thermal-tab-white"] = "thermometer", ["identy-tab-white"] = "idcard", ["journal-tab-white"] = "notebook",
    ["skills-tab-white"] = "skills", ["radio-tab-white"] = "walkie", ["craft-tab-white"] = "craft",
    ["build-tab-white"] = "bricks", ["move-tab-white"] = "chair", ["map-tab-white"] = "map",
    ["forage-tab-white"] = "magnifier", ["farm-tab-white"] = "cow", ["vehicle-tab-white"] = "car",
    ["appearance-tab-white"] = "mirror", ["traits-tab-white"] = "traits",
}

-- the slice's words first: several vanilla slices share one picture
-- ({ key, icon, the picture it holds with only, true when the key takes arguments }).
-- The key's words in the player's language are found in the slice's text; a one-word
-- key is the whole text; a key with arguments matches the words before the first argument.
local TEXT_ICONS = {
    { "UI_optionscreen_binding_Toggle Survival Guide", "guide" },
    { "IGUI_MiniMap_Toggle", "minimap" }, { "IGUI_MiniMap_Focus", "pin" },
    { "IGUI_Emote_Shout", "bullhorn" }, { "IGUI_Emote_Group", "group" },
    { "IGUI_BackButton_Zoom", "zoom_in", "zoomin", true }, { "IGUI_BackButton_Zoom", "zoom_out", "zoomout", true },
    { "ContextMenu_Vehicle_AttachTrailer", "link", nil, true }, { "ContextMenu_Vehicle_AttachVehicle", "link", nil, true },
    { "ContextMenu_Vehicle_DetachTrailer", "unlink", nil, true },
    { "ContextMenu_VehicleHeadlightsOn", "headlight_on" }, { "ContextMenu_VehicleHeadlightsOff", "headlight_off" },
    { "ContextMenu_VehicleHotwire", "hotwire" }, { "ContextMenu_VehicleHotwireSkill", "hotwire_off" },
    { "IGUI_EnterVehicle", "car_enter" }, { "IGUI_ExitVehicle", "car_exit" },
    { "ContextMenu_Open_door", "car_door" }, { "ContextMenu_Close_door", "car_door" }, { "IGUI_OpenHood", "car_door" },
    { "IGUI_CloseHood", "car_door" }, { "IGUI_OpenTrunk", "car_door" }, { "IGUI_CloseTrunk", "car_door" },
    { "ContextMenu_Unlock_Doors", "padlock_open" }, { "ContextMenu_UnlockDoor", "padlock_open" },
    { "IGUI_UnlockHood", "padlock_open" }, { "IGUI_UnlockTrunk", "padlock_open" },
    { "ContextMenu_Vehicle_Wash", "wash" }, { "ContextMenu_CheckAnimalInsideTrailer", "cow" },
    { "ContextMenu_FullInventory", "gas_can" }, { "ContextMenu_VehicleNeedHose", "gas_siphon" },
}
-- vanilla's pictures that stay
local KEEP = { "item_", "trait_", "xbox", "joypad", "media/inventory" }
-- vanilla's pictures by the texture's name: the first match wins (emotes/wavehello before emotes/wave)
local TEX_ICONS = {
    -- vehicle
    { "vehicle_changeseats", "seat" }, { "vehicle_ignitionon", "key" }, { "vehicle_ignitionoff", "key_off" },
    { "vehicle_lightson", "bulb_on" }, { "vehicle_lightsoff", "bulb_off" }, { "vehicle_temperaturehot", "heat" },
    { "vehicle_temperaturecold", "snowflake" }, { "vehicle_horn", "horn" }, { "vehicle_lightbar", "lightbar" },
    { "vehicle_speakers", "speaker" }, { "vehicle_windowopen", "window_open" },
    { "vehicle_windowclosed", "window_close" }, { "vehicle_smash_window", "window_smash" },
    { "vehicle_lockdoors", "padlock" }, { "vehicle_repair", "engine" }, { "vehicle_sleep", "bed" },
    { "vehicle_exit", "car_exit" }, { "vehicle_refuel_from_pump", "gas_pump" }, { "vehicle_add_gas", "gas_can" },
    { "gas_refuel", "gas_can" }, { "vehicle_siphon_gas", "gas_siphon" }, { "gas_siphon", "gas_siphon" },
    -- firearm and light
    { "firearmradial_insertmagazine", "mag_in" }, { "firearmradial_ejectmagazine", "mag_out" },
    { "firearmradial_bulletsintomagazine", "rounds_mag" }, { "firearmradial_bulletsintofirearm", "rounds_in" },
    { "firearmradial_bulletsfromfirearm", "rounds_out" }, { "firearmradial_unjam", "unjam" },
    { "firearmradial_rack", "rack" }, { "firearmradial_chamberround", "chamber" },
    { "lightsourceradial_insertbattery", "battery_in" }, { "lightsourceradial_removebattery", "battery_out" },
    -- animal
    { "animalactions_kill", "knife" }, { "animalactions_grab", "carry_animal" }, { "animalactions_milk", "milk" },
    { "animalactions_pet", "pet" }, { "animalactions_rope", "rope" }, { "animalactions_shear", "scissors" },
    { "animalactions_stats", "info" },
    -- back button, furniture, map
    { "heart2_on", "heart" }, { "carpentry_on", "craft" }, { "build_tool", "bricks" }, { "furniture_off2", "chair" },
    { "furniture_pickup", "box_up" }, { "furniture_place", "box_down" }, { "furniture_rotate", "rotate" },
    { "furniture_disassemble", "screwdriver" }, { "furniture_on2", "wrench" }, { "foraging/eyeconon", "eye" },
    { "foraging/eyeconoff", "eye_off" }, { "search_on_64", "magnifier" }, { "search_off_64", "magnifier_off" },
    { "animalzone_on_64", "fence" }, { "buildingroomseditor_64", "rooms" }, { "worldmap/map_on", "map" },
    { "speedcontrols/play_off", "play" }, { "speedcontrols/pause_off", "pause" },
    { "speedcontrols/ffwd1_off", "ff1" }, { "speedcontrols/ffwd2_off", "ff2" }, { "speedcontrols/wait_off", "wait" },
    { "zoomin", "plus" }, { "zoomout", "minus" },
    -- emotes and stances
    { "emotes/wavehello", "wave" }, { "emotes/wavebye", "wave_bye" }, { "emotes/wave", "wave" },
    { "emotes/clap", "clap" }, { "emotes/thumbsup", "thumbs_up" }, { "emotes/thumbup", "thumbs_up" },
    { "emotes/thumbsdown", "thumbs_down" }, { "emotes/thumbdown", "thumbs_down" }, { "emotes/thankyou", "bow" },
    { "emotes/insult", "insult" }, { "emotes/stop", "hand" }, { "emotes/surrender", "surrender" },
    { "emotes/followme", "follow_me" }, { "emotes/comehere", "come_here" }, { "emotes/comefromfront", "come_here" },
    { "emotes/yes", "yes" }, { "emotes/no", "no" }, { "emotes/shrug", "shrug" }, { "emotes/undecided", "undecided" },
    { "emotes/ceasefire", "target_off" }, { "emotes/fire", "target" }, { "emotes/moveout", "move_out" },
    { "emotes/freeze", "freeze" }, { "emotes/followbehind", "follow_behind" }, { "emotes/salute", "salute" },
    { "emotes/group", "group" }, { "emotes/gears", "gears" }, { "emotes/crouch_on", "sneak" },
    { "emotes/crouch_off", "sneak_off" }, { "emotes/sit_on", "sit_ground" }, { "emotes/sit_off", "sit_ground_off" },
    { "emotes/autowalk_on", "autowalk" }, { "emotes/autowalk_off", "autowalk_off" },
}
W.TEXT_ICONS, W.KEEP, W.TEX_ICONS = TEXT_ICONS, KEEP, TEX_ICONS   -- (QA: zedqa_wheel_icons.lua)
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

-- the slice's text says the key (text: lower case, trimmed). A key with arguments is
-- asked with a stand-in for them (42.22 logs an exception for words asked without
-- their arguments) and matched on the words before the first.
local ARG = "ZEDWHEELARG"
local function says(text, key, args)
    if not getTextOrNull then return false end
    local own = args and getTextOrNull(key, ARG, ARG, ARG, ARG) or (not args and getTextOrNull(key)) or nil
    if not own or own == "" then return false end
    own = lower(own):gsub("<br>", "\n")
    if args then
        local cut = own:find(lower(ARG), 1, true)
        own = own:sub(1, (cut or (#own + 1)) - 1):gsub("%s+$", "")
        return own ~= "" and text:sub(1, #own) == own
    end
    if not own:find("%s") then return text == own end
    return text:find(own, 1, true) ~= nil
end

-- the picture for a slice: texture, tintable (a ZeD icon takes the ink / accent), wheel icon id
-- (an id draws the wheel icon: W.iconTex picks its drawing by the cell's icon box)
function W.picture(slice)
    local text = lower(slice.text):gsub("<br>", "\n"):gsub("^%s+", ""):gsub("%s+$", "")
    local name = texName(slice.texture)
    for _, m in ipairs(TEXT_ICONS) do
        if (not m[3] or name:find(m[3], 1, true)) and says(text, m[1], m[4]) then return nil, true, m[2] end
    end
    for _, k in ipairs(KEEP) do
        if name:find(k, 1, true) then return slice.texture, false end
    end
    for _, m in ipairs(TEX_ICONS) do
        if name:find(m[1], 1, true) then return nil, true, m[2] end
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
-- one cell: the hard shadow, the strip's cell at the wheel's size, the ink edge (1u)
local function drawCell(menu, x, y, cell, icon, slice, active)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    if slice._zedTex == nil then
        local tex, tint, id = W.picture(slice)
        slice._zedTex, slice._zedTint, slice._zedIcon = tex or false, tint, id
    end
    -- a wheel icon: its drawing for this box, centred in the cell at its own size
    local tex, tint, px = slice._zedTex or nil, slice._zedTint, icon
    if slice._zedIcon then tex, px = W.iconTex(slice._zedIcon, icon); tint = true end
    local def = { iconTexture = tex, iconTintable = tint, name = slice.text }
    local flags = { isActive = active, isDisabled = W.isOff(slice), hasSub = W.hasSub(slice), isBack = W.isBack(slice) }
    A.drawSteppedShadow(menu, x, y, cell, cell, INK)
    local ctx = T.ctx
    local cw, ch, ip, ts = ctx.cellW, ctx.cellH, ctx.iconPx, ctx.submenuTriSz
    ctx.cellW, ctx.cellH, ctx.iconPx, ctx.submenuTriSz = cell, cell, px, T.px(4)
    local ok, err = pcall(M.drawContextCell, menu, x, y, def, flags, T)
    ctx.cellW, ctx.cellH, ctx.iconPx, ctx.submenuTriSz = cw, ch, ip, ts
    if not ok then ZeD.logOnce("Wheel: cell", err) end
    if not active then A.frame(menu, x, y, cell, cell, INK) end
    -- a colour to pick (the ZeD wheel's accents): its swatch in the cell, a square with an ink edge
    if slice._zedSwatch then
        local sw = math.floor(icon * 0.75)
        local sx, sy = x + math.floor((cell - sw) / 2), y + math.floor((cell - sw) / 2)
        local c = slice._zedSwatch
        menu:drawRect(sx, sy, sw, sw, c.a or 1, c.r, c.g, c.b)
        A.frame(menu, sx, sy, sw, sw, INK)
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
    ZeD.Atoms.frame(menu, cx - math.floor(hs / 2), cy - math.floor(hs / 2), hs, hs, INK)
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

-- under the ring, centred on cx: the breadcrumb (which wheel, and where in it) as a tag, then
-- the controller's prompts for this wheel in a pop-up box. Both sit over the world, so both
-- are solid whatever the see-through setting says.
local NOP = { drawRectBorder = function() end, drawText = function() end, drawRect = function() end }
function W.drawUnder(menu, cx, y)
    local T, tm, A, M = ZeD.T, ZeD.TM, ZeD.Atoms, ZeD.Molecules
    local s1 = T.surf1
    if menu._zedCrumb then
        -- the breadcrumb: an outlined tag in its own words, on the solid surface
        local font = T.fontF1
        local s = A.textCase(menu._zedCrumb)
        local h = T.px(16)
        local w = tm:MeasureStringX(font, s) + T.px(5) * 2
        local x = math.floor(cx - w / 2)
        menu:drawRect(x, y, w, h, 1, s1.r, s1.g, s1.b)
        M.drawTag(menu, x, y, s, nil, { font = font, h = h, keepCase = true })
        y = y + h + T.px(8)
    end
    if menu._zedPrompts then
        -- the prompts: the footers' glyph legend, a pop-up box of its own
        local padX = T.px(7)
        local h = T.px(24)
        local inner = M.drawGlyphPrompts(NOP, 0, 0, h, menu._zedPrompts) - T.sp.sm * 2
        local w = inner + padX * 2
        local x = math.floor(cx - w / 2)
        A.drawHardShadow(menu, x, y, w, h)
        menu:drawRect(x, y, w, h, 1, s1.r, s1.g, s1.b)
        A.frame(menu, x, y, w, h, T.borderS)
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
