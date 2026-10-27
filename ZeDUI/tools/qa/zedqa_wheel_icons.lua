-- ZeDUI/tools/qa/zedqa_wheel_icons.lua  (Oct 27 2026)
-- The wheels' icons (ZeDUI/HANDOFF_wheel_icons_20261027.md; ZeD_Wheel.lua, ZeD_DpadWheels.lua). The
-- expectations below are wheel_icons_map.json's (ZeDUI/mockups/zed_wheel_icons_v1, Oct 27 2026), as data.
--   1. every icon's four drawings load, at their sizes (16 and 24, and the two doubled: 32 and 48);
--   2. the drawing for an icon box: the largest that fits, at its own size (the handoff's table, 0.5x to 2x);
--   3. vanilla's words (each with the picture vanilla gives that slice), vanilla's pictures by name in the
--      map's order, the pictures that stay, and the pairs that share a picture coming out different;
--   4. the tab icons: every tab of both windows has one;
--   5. ZeD's own wheels: every slice of every level of the five wheels has a wheel icon (or is an item, a
--      glyph, a colour), each of the map's slices has its icon, the ZeD wheel's pickers give their choices
--      the setting's icon;
--   6. vanilla's radials, live (vehicle outside and inside with the dashboard slice, the emotes and each
--      group, firearm, light, the stick click, vanilla's Back wheel and D-pad Right): every slice draws a
--      wheel icon or keeps an item / trait / glyph picture, and the cells draw each icon pixel for pixel;
--   7. captures at the scale in use (1.75x at 4K) and again at 1x (the scale put back after).
-- Copy to Zomboid/Lua/zedqa.lua and bump zedqa.go; grep "ZEDQA wi". The character steps into the
-- pickup and out again; the pistol, clip, bullets and torch go back as they were.
local p = getPlayer()
local pn = p:getPlayerNum()
local W, D = ZeD.Wheel, ZeD.DpadWheels
local function say(s) print("ZEDQA wi " .. tostring(s)) end
local fails, notes = 0, 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_wi_" .. n .. ".png") end) end
local Q, qi, waitT = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
if not (W and W.iconTex and D and D.pictureOf) then say("ERR the wheel icons are not loaded (ZeD.Wheel.iconTex, ZeD.DpadWheels.pictureOf)"); say("DONE"); return end

-- every icon id (151)
local IDS = {
    "knife", "apple", "glass", "medkit", "bandage", "bed", "shirt", "backpack", "hand", "cigarette", "book", "watch",
    "walkie", "map", "minimap", "pin", "car", "cow", "toolbox", "magnifier", "magnifier_off", "bulb_on", "bulb_off",
    "fence", "eye", "eye_off", "box_up", "box_down", "rotate", "screwdriver", "wrench", "generator", "campfire",
    "chair", "gauge", "bullhorn", "rooms", "seat", "car_door", "car_enter", "car_exit", "key", "key_off", "hotwire",
    "hotwire_off", "headlight_on", "headlight_off", "heat", "snowflake", "horn", "lightbar", "speaker",
    "window_open", "window_close", "window_smash", "padlock", "padlock_open", "engine", "wash", "link", "unlink",
    "gas_pump", "gas_can", "gas_siphon", "mag_in", "mag_out", "rounds_in", "rounds_out", "chamber", "rack", "unjam",
    "rounds_mag", "battery_in", "battery_out", "milk", "pet", "rope", "scissors", "stand", "wave", "point", "shrug",
    "surrender", "salute", "walk", "run", "sit_seat", "sneak", "climb", "carry", "sit_ground", "sit_ground_off",
    "sneak_off", "autowalk", "autowalk_off", "wave_bye", "bow", "freeze", "move_out", "follow_me", "follow_behind",
    "group", "carry_animal", "undecided", "come_here", "clap", "thumbs_up", "thumbs_down", "yes", "no", "insult",
    "chat", "target", "target_off", "back", "plus", "minus", "info", "help", "play", "pause", "ff1", "ff2", "wait",
    "seek", "gears", "zoom_in", "zoom_out", "theme", "textsize", "focus", "scale", "seethrough", "progress", "inbox",
    "smiley", "guide", "gamepad", "alarm", "heart", "safemode", "crate", "jacket", "thermometer", "idcard",
    "notebook", "skills", "craft", "bricks", "mirror", "traits",
}
-- vanilla's words: { key, picture or false, id }
local TEXT = {
    { "UI_optionscreen_binding_Toggle Survival Guide", false, "guide" }, { "IGUI_MiniMap_Toggle", false, "minimap" },
    { "IGUI_MiniMap_Focus", false, "pin" }, { "IGUI_Emote_Shout", false, "bullhorn" },
    { "IGUI_Emote_Group", false, "group" }, { "IGUI_BackButton_Zoom", "ZoomIn", "zoom_in" },
    { "IGUI_BackButton_Zoom", "ZoomOut", "zoom_out" }, { "ContextMenu_Vehicle_AttachTrailer", false, "link" },
    { "ContextMenu_Vehicle_AttachVehicle", false, "link" }, { "ContextMenu_Vehicle_DetachTrailer", false, "unlink" },
    { "ContextMenu_VehicleHeadlightsOn", false, "headlight_on" },
    { "ContextMenu_VehicleHeadlightsOff", false, "headlight_off" },
    { "ContextMenu_VehicleHotwire", false, "hotwire" }, { "ContextMenu_VehicleHotwireSkill", false, "hotwire_off" },
    { "IGUI_EnterVehicle", false, "car_enter" }, { "IGUI_ExitVehicle", false, "car_exit" },
    { "ContextMenu_Open_door", false, "car_door" }, { "ContextMenu_Close_door", false, "car_door" },
    { "IGUI_OpenHood", false, "car_door" }, { "IGUI_CloseHood", false, "car_door" },
    { "IGUI_OpenTrunk", false, "car_door" }, { "IGUI_CloseTrunk", false, "car_door" },
    { "ContextMenu_Unlock_Doors", false, "padlock_open" }, { "ContextMenu_UnlockDoor", false, "padlock_open" },
    { "IGUI_UnlockHood", false, "padlock_open" }, { "IGUI_UnlockTrunk", false, "padlock_open" },
    { "ContextMenu_Vehicle_Wash", false, "wash" }, { "ContextMenu_CheckAnimalInsideTrailer", false, "cow" },
    { "ContextMenu_FullInventory", false, "gas_can" }, { "ContextMenu_VehicleNeedHose", false, "gas_siphon" },
}
-- the picture vanilla gives each of those slices (ISVehicleMenu, ISDPadWheels, ISEmoteRadialMenu)
local LIGHT_ON, LIGHT_OFF = "media/ui/vehicles/vehicle_lightsON.png", "media/ui/vehicles/vehicle_lightsOFF.png"
local EXIT, LOCK, MAP_ON = "media/ui/vehicles/vehicle_exit.png", "media/ui/vehicles/vehicle_lockdoors.png", "media/textures/worldMap/Map_On.png"
local VPIC = {
    ["UI_optionscreen_binding_Toggle Survival Guide"] = "media/ui/emotes/shrug.png",
    IGUI_MiniMap_Toggle = MAP_ON, IGUI_MiniMap_Focus = MAP_ON,
    IGUI_Emote_Shout = "media/ui/Traits/trait_talkative.png", IGUI_Emote_Group = "media/ui/emotes/followme.png",
    ContextMenu_Vehicle_AttachTrailer = "media/ui/ZoomIn.png", ContextMenu_Vehicle_AttachVehicle = "media/ui/ZoomIn.png",
    ContextMenu_Vehicle_DetachTrailer = "media/ui/ZoomOut.png",
    ContextMenu_VehicleHeadlightsOn = LIGHT_ON, ContextMenu_VehicleHeadlightsOff = LIGHT_OFF,
    ContextMenu_VehicleHotwire = "media/ui/vehicles/vehicle_ignitionON.png", ContextMenu_VehicleHotwireSkill = "media/ui/vehicles/vehicle_ignitionOFF.png",
    IGUI_EnterVehicle = "media/ui/vehicles/vehicle_changeseats.png", IGUI_ExitVehicle = EXIT,
    ContextMenu_Open_door = EXIT, ContextMenu_Close_door = EXIT, IGUI_OpenHood = EXIT, IGUI_CloseHood = EXIT,
    IGUI_OpenTrunk = EXIT, IGUI_CloseTrunk = EXIT,
    ContextMenu_Unlock_Doors = LOCK, ContextMenu_UnlockDoor = LOCK, IGUI_UnlockHood = LOCK, IGUI_UnlockTrunk = LOCK,
    ContextMenu_Vehicle_Wash = "Item_WaterDrop", ContextMenu_CheckAnimalInsideTrailer = "media/ui/Item_SheepWhite_Lamb.png",
    ContextMenu_FullInventory = "Item_Petrol", ContextMenu_VehicleNeedHose = "Item_Petrol",
}
local KEEP = { "item_", "trait_", "xbox", "joypad", "media/inventory" }
-- vanilla's pictures, in order: { picture, id }
local TEX = {
    { "vehicle_changeseats", "seat" }, { "vehicle_ignitionon", "key" }, { "vehicle_ignitionoff", "key_off" },
    { "vehicle_lightson", "bulb_on" }, { "vehicle_lightsoff", "bulb_off" }, { "vehicle_temperaturehot", "heat" },
    { "vehicle_temperaturecold", "snowflake" }, { "vehicle_horn", "horn" }, { "vehicle_lightbar", "lightbar" },
    { "vehicle_speakers", "speaker" }, { "vehicle_windowopen", "window_open" },
    { "vehicle_windowclosed", "window_close" }, { "vehicle_smash_window", "window_smash" },
    { "vehicle_lockdoors", "padlock" }, { "vehicle_repair", "engine" }, { "vehicle_sleep", "bed" },
    { "vehicle_exit", "car_exit" }, { "vehicle_refuel_from_pump", "gas_pump" }, { "vehicle_add_gas", "gas_can" },
    { "gas_refuel", "gas_can" }, { "vehicle_siphon_gas", "gas_siphon" }, { "gas_siphon", "gas_siphon" },
    { "firearmradial_insertmagazine", "mag_in" }, { "firearmradial_ejectmagazine", "mag_out" },
    { "firearmradial_bulletsintomagazine", "rounds_mag" }, { "firearmradial_bulletsintofirearm", "rounds_in" },
    { "firearmradial_bulletsfromfirearm", "rounds_out" }, { "firearmradial_unjam", "unjam" },
    { "firearmradial_rack", "rack" }, { "firearmradial_chamberround", "chamber" },
    { "lightsourceradial_insertbattery", "battery_in" }, { "lightsourceradial_removebattery", "battery_out" },
    { "animalactions_kill", "knife" }, { "animalactions_grab", "carry_animal" }, { "animalactions_milk", "milk" },
    { "animalactions_pet", "pet" }, { "animalactions_rope", "rope" }, { "animalactions_shear", "scissors" },
    { "animalactions_stats", "info" }, { "heart2_on", "heart" }, { "carpentry_on", "craft" },
    { "build_tool", "bricks" }, { "furniture_off2", "chair" }, { "furniture_pickup", "box_up" },
    { "furniture_place", "box_down" }, { "furniture_rotate", "rotate" }, { "furniture_disassemble", "screwdriver" },
    { "furniture_on2", "wrench" }, { "foraging/eyeconon", "eye" }, { "foraging/eyeconoff", "eye_off" },
    { "search_on_64", "magnifier" }, { "search_off_64", "magnifier_off" }, { "animalzone_on_64", "fence" },
    { "buildingroomseditor_64", "rooms" }, { "worldmap/map_on", "map" }, { "speedcontrols/play_off", "play" },
    { "speedcontrols/pause_off", "pause" }, { "speedcontrols/ffwd1_off", "ff1" },
    { "speedcontrols/ffwd2_off", "ff2" }, { "speedcontrols/wait_off", "wait" }, { "zoomin", "plus" },
    { "zoomout", "minus" }, { "emotes/wavehello", "wave" }, { "emotes/wavebye", "wave_bye" },
    { "emotes/wave", "wave" }, { "emotes/clap", "clap" }, { "emotes/thumbsup", "thumbs_up" },
    { "emotes/thumbup", "thumbs_up" }, { "emotes/thumbsdown", "thumbs_down" }, { "emotes/thumbdown", "thumbs_down" },
    { "emotes/thankyou", "bow" }, { "emotes/insult", "insult" }, { "emotes/stop", "hand" },
    { "emotes/surrender", "surrender" }, { "emotes/followme", "follow_me" }, { "emotes/comehere", "come_here" },
    { "emotes/comefromfront", "come_here" }, { "emotes/yes", "yes" }, { "emotes/no", "no" },
    { "emotes/shrug", "shrug" }, { "emotes/undecided", "undecided" }, { "emotes/ceasefire", "target_off" },
    { "emotes/fire", "target" }, { "emotes/moveout", "move_out" }, { "emotes/freeze", "freeze" },
    { "emotes/followbehind", "follow_behind" }, { "emotes/salute", "salute" }, { "emotes/group", "group" },
    { "emotes/gears", "gears" }, { "emotes/crouch_on", "sneak" }, { "emotes/crouch_off", "sneak_off" },
    { "emotes/sit_on", "sit_ground" }, { "emotes/sit_off", "sit_ground_off" }, { "emotes/autowalk_on", "autowalk" },
    { "emotes/autowalk_off", "autowalk_off" },
}
local TABS = {
    ["loot-tab-white"] = "crate", ["equipment-tab-white"] = "jacket", ["health-tab-white"] = "heart",
    ["thermal-tab-white"] = "thermometer", ["identy-tab-white"] = "idcard", ["journal-tab-white"] = "notebook",
    ["skills-tab-white"] = "skills", ["radio-tab-white"] = "walkie", ["craft-tab-white"] = "craft",
    ["build-tab-white"] = "bricks", ["move-tab-white"] = "chair", ["map-tab-white"] = "map",
    ["forage-tab-white"] = "magnifier", ["farm-tab-white"] = "cow", ["vehicle-tab-white"] = "car",
    ["appearance-tab-white"] = "mirror", ["traits-tab-white"] = "traits",
}
-- ZeD's own wheels: { wheel, slice key(s), id(s) }
local ZED = {
    { "character", "UI_ZeD_Wheel_Tabs", "crate" },
    { "character", "UI_ZeD_Wheel_Weapons", "knife" },
    { "character", "ContextMenu_Eat", "apple" },
    { "character", "ContextMenu_Drink", "glass" },
    { "character", "UI_ZeD_Wheel_Medicine", "medkit" },
    { "character", "ContextMenu_Sleep", "bed" },
    { "character", "UI_ZeD_Wheel_Clothing", "shirt" },
    { "character", "UI_ZeD_Wheel_Use", "backpack" },
    { "character > Weapons", "UI_ZeD_Wheel_HandsFree", "hand" },
    { "character > Medicine", "the wounds (H.treatments' entries)", "bandage" },
    { "character > Medicine, Clothing, Radio", "the tab slices (Health, Equipment, Radio)", "heart / jacket / walkie" },
    { "character > Use", "ContextMenu_Smoke", "cigarette" },
    { "character > Use", "ContextMenu_Read", "book" },
    { "character > Use", "UI_ZeD_Wheel_Watch", "watch" },
    { "character > Use", "IGUI_ItemType_Radio", "walkie" },
    { "character > Watch", "UI_ZeD_Wheel_OpenWatch", "watch" },
    { "character > Watch", "UI_ZeD_Wheel_WatchLight", "bulb_on" },
    { "character > Watch", "UI_ZeD_Wheel_WatchAlarm", "alarm" },
    { "character > Radio", "UI_ZeD_Wheel_NextStation", "seek" },
    { "world", "UI_ZeD_Wheel_Tabs", "craft" },
    { "world", "UI_ZeD_Wheel_Map", "map" },
    { "world", "UI_ZeD_Wheel_Vehicle", "car" },
    { "world", "UI_ZeD_Wheel_Animal", "cow" },
    { "world", "UI_ZeD_Wheel_CraftBuild", "toolbox" },
    { "world", "UI_ZeD_Wheel_Search", "magnifier" },
    { "world", "UI_ZeD_Wheel_LightsPower", "bulb_on" },
    { "world", "IGUI_Zone_Name", "fence" },
    { "world", "IGUI_Emote_Shout", "bullhorn" },
    { "world (server)", "UI_ZeD_Wheel_Chat", "chat" },
    { "world (server)", "UI_ZeD_Wheel_Safety", "padlock" },
    { "world (server)", "UI_ZeD_Wheel_Players", "group" },
    { "world > Map", "IGUI_WorldMap_Toggle", "map" },
    { "world > Map", "IGUI_MiniMap_Toggle", "minimap" },
    { "world > Map", "IGUI_MiniMap_Focus", "pin" },
    { "world > Craft and build", "IGUI_CraftingWindow_Title", "craft" },
    { "world > Craft and build", "UI_ZeD_World_TabBuilding", "bricks" },
    { "world > Craft and build", "IGUI_BackButton_Movable", "chair" },
    { "world > Search", "UI_enable_search_mode", "eye" },
    { "world > Search", "UI_disable_search_mode", "eye_off" },
    { "world > Search", "UI_investigate_area_window_show", "magnifier" },
    { "world > Search", "IGUI_Pickup", "box_up" },
    { "world > Lights and power", "UI_ZeD_Wheel_RoomLights", "bulb_on" },
    { "world > Lights and power", "ContextMenu_Generator", "generator" },
    { "world > Lights and power", "ContextMenu_Light_fire / ContextMenu_Put_out_fire", "campfire" },
    { "world > Vehicle", "IGUI_VehiclePartCatdashboard", "gauge" },
    { "stance", "UI_ZeD_Wheel_Sit", "sit_ground" },
    { "stance", "UI_ZeD_Wheel_Crouch", "sneak / sneak_off" },
    { "stance", "UI_ZeD_Wheel_AutoWalk", "autowalk / autowalk_off" },
    { "stance", "UI_ZeD_Wheel_GameSpeed", "ff1" },
    { "stance", "UI_ZeD_Wheel_Zoom", "zoom_in" },
    { "stance", "UI_ZeD_Wheel_View", "eye" },
    { "stance", "UI_ZeD_Wheel_Help", "help" },
    { "stance", "UI_ZeD_Wheel_Light (or the light's name)", "bulb_on" },
    { "stance > Sit", "ContextMenu_SitGround / UI_ZeD_Wheel_GetUp", "sit_ground / sit_ground_off" },
    { "stance > Sit", "UI_ZeD_Wheel_SitOn / UI_ZeD_Wheel_SitOnSeat", "sit_seat" },
    { "stance > Speed", "IGUI_BackButton_Play / UI_optionscreen_binding_Pause", "play / pause" },
    { "stance > Speed", "IGUI_BackButton_FF1 / FF2 / FF3", "ff1 / ff2 / wait" },
    { "stance > Zoom", "IGUI_BackButton_Zoom (nearer / farther)", "zoom_in / zoom_out" },
    { "stance > View", "UI_ZeD_Wheel_HideInterface / UI_ZeD_Wheel_ShowInterface", "eye_off / eye" },
    { "stance > View", "UI_ZeD_Wheel_ResetWindows", "rotate" },
    { "stance > View", "UI_ZeD_Settings_TextSize", "textsize" },
    { "stance > View", "UI_mainscreen_option", "gears" },
    { "stance > Help", "UI_optionscreen_binding_Toggle Survival Guide", "guide" },
    { "stance > Help", "UI_ZeD_Wheel_ControllerMap", "gamepad" },
    { "ZeD setup", "UI_ZeD_Settings_BaseTheme", "theme" },
    { "ZeD setup", "UI_ZeD_Settings_TextSize", "textsize" },
    { "ZeD setup", "UI_ZeD_Settings_SeeThrough", "seethrough" },
    { "ZeD setup", "UI_ZeD_Settings_FocusStyle", "focus" },
    { "ZeD setup", "UI_ZeD_Settings_UiScale", "scale" },
    { "ZeD setup", "UI_ZeD_Settings_Moodles", "smiley" },
    { "ZeD setup", "UI_ZeD_Settings_ActionBar", "progress" },
    { "ZeD setup", "UI_ZeD_Msg_Title", "inbox" },
    { "ZeD setup", "UI_ZeD_Wheel_ResetWindows", "rotate" },
    { "ZeD setup", "UI_ZeD_Options_GroupZed", "gears" },
    { "ZeD setup", "UI_ZeD_Settings_SafeMode", "safemode" },
}

local IS_ID = {}
for _, id in ipairs(IDS) do IS_ID[id] = true end
local function lower(s) return string.lower(tostring(s or "")) end
local function texName(t)
    if not t then return "" end
    local ok, n = pcall(function() return t:getName() end)
    return ok and (lower(n):gsub("\\", "/")) or ""
end
-- a key's words; the keys that take an argument are asked with a stand-in (42.22 logs an exception for
-- words asked without their arguments) and matched on the words before it
local ARG, ARG_KEYS = "ZEDQAARG", { UI_ZeD_Wheel_SitOn = true, IGUI_BackButton_Zoom = true }
local function word(key)
    if ARG_KEYS[key] then return (key:sub(1, 7) == "UI_ZeD_") and ZeD.tr(key, ARG) or getText(key, ARG) end
    return (key:sub(1, 7) == "UI_ZeD_") and ZeD.tr(key) or getText(key)
end
-- a stand-in picture by name only (W.picture reads the texture's name)
local function named(n) return { getName = function() return n end } end
-- what the wheel makes of a slice: "id:<id>", "keep:<picture>", or "other:<picture>"
local function resolve(text, tex)
    local t, _, id = W.picture({ text = text, texture = tex })
    if id then return "id:" .. id end
    local n = texName(t)
    for _, k in ipairs(KEEP) do if n:find(k, 1, true) then return "keep:" .. n end end
    return "other:" .. n
end

-- the scene: windows closed, the pad nowhere, the debug console out of the shots
local pairWasOpen = ZeD_CharacterWindow.isOpen()
local S = ZeD.Settings
local scaleWas = S and S.uiScaleOption and S.uiScaleOption:getValue()
step(5, function()
    if ZeD_CharacterWindow.isOpen() and ZeD_CharacterWindow.toggleBothPaired then ZeD_CharacterWindow.toggleBothPaired(pn) end
    local F = ZeD.Input and ZeD.Input.Focus
    if F and F.releaseFocus then pcall(F.releaseFocus) end
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    say(string.format("scene: screen %dx%d, scale option %s, icon box %d at rest, %d pointed", getCore():getScreenWidth(), getCore():getScreenHeight(),
        tostring(scaleWas), ZeD.T.px(W.U.ICON), ZeD.T.px(W.U.ICON_ON)))
end)

-- 1. every icon's four drawings, through the wheel's own loader (nearest filtering is fixed at a
-- texture's first load, KB Q205), each the mod's file (not a packed picture of the same name, Q143)
step(2, function()
    local bad = {}
    for _, id in ipairs(IDS) do
        for _, sz in ipairs({ 16, 24, 32, 48 }) do
            local t, px = W.iconTex(id, sz)
            local n = texName(t)
            if not t or px ~= sz then bad[#bad + 1] = sz .. "/" .. id .. " missing"
            elseif t:getWidth() ~= sz or t:getHeight() ~= sz then bad[#bad + 1] = string.format("%d/%s is %dx%d", sz, id, t:getWidth(), t:getHeight())
            elseif not n:find("/zed/wheel/" .. sz .. "/zw_" .. id .. ".png", 1, true) then bad[#bad + 1] = sz .. "/" .. id .. " loaded " .. n end
        end
    end
    check(#bad == 0, string.format("all %d icons load at 16, 24, 32 and 48, each its own file (%d problems%s)", #IDS, #bad, #bad > 0 and (": " .. table.concat(bad, ", ")) or ""))
end)

-- 2. the drawing for a box (the handoff's table: 0.5x to 2x, at rest and pointed)
step(2, function()
    local BOX = { { 8, 16, 8 }, { 12, 16, 12 }, { 16, 16, 16 }, { 18, 16, 16 }, { 20, 16, 16 }, { 24, 24, 24 }, { 28, 24, 24 },
                  { 30, 24, 24 }, { 32, 32, 32 }, { 36, 32, 32 }, { 42, 32, 32 }, { 48, 48, 48 } }
    local bad = {}
    for _, b in ipairs(BOX) do
        local t, px = W.iconTex("knife", b[1])
        local w = t and t:getWidth()
        if w ~= b[2] or px ~= b[3] then bad[#bad + 1] = string.format("box %d: drawing %s at %s (want %d at %d)", b[1], tostring(w), tostring(px), b[2], b[3]) end
    end
    check(#bad == 0, "the drawing for each box: the largest that fits, at its own size; under 16 the 16 scaled down" .. (#bad > 0 and (": " .. table.concat(bad, "; ")) or ""))
    local rest, on = ZeD.T.px(W.U.ICON), ZeD.T.px(W.U.ICON_ON)
    local _, a = W.iconTex("knife", rest)
    local _, b = W.iconTex("knife", on)
    say(string.format("at this scale: box %d draws the %d, box %d draws the %d", rest, a, on, b))
end)

-- 3. vanilla's words, pictures, the pictures that stay, the pairs
step(2, function()
    local bad, skipped = {}, {}
    for _, r in ipairs(TEXT) do
        local own = getTextOrNull(r[1], "Trailer", "Car", "Hitch", "Ball")
        if not own then skipped[#skipped + 1] = r[1]
        else
            local pic = r[2] and ("media/ui/" .. r[2] .. ".png") or VPIC[r[1]]
            local text = getText(r[1], "Trailer", "Car", "Hitch", "Ball")
            local got = resolve(text, getTexture(pic) or named(pic))
            if got ~= "id:" .. r[3] then bad[#bad + 1] = r[1] .. " (" .. tostring(pic) .. "): " .. got .. ", want " .. r[3] end
        end
    end
    check(#bad == 0, string.format("vanilla's words: %d of %d give their icon over vanilla's picture%s", #TEXT - #bad - #skipped, #TEXT,
        #bad > 0 and (": " .. table.concat(bad, "; ")) or ""))
    if #skipped > 0 then notes = notes + 1; say("NOTE no words in this language for " .. table.concat(skipped, ", ") .. " (vanilla shows the key itself; nothing to match)") end
    bad = {}
    for _, r in ipairs(TEX) do
        local got = resolve("qa slice", named("media/ui/" .. r[1] .. ".png"))
        if got ~= "id:" .. r[2] then bad[#bad + 1] = r[1] .. ": " .. got .. ", want " .. r[2] end
    end
    check(#bad == 0, string.format("vanilla's pictures by name, in order: %d of %d%s", #TEX - #bad, #TEX, #bad > 0 and (": " .. table.concat(bad, "; ")) or ""))
    bad = {}
    for _, n in ipairs({ "media/ui/item_qa.png", "media/ui/traits/trait_qa.png", "media/ui/xbox_a.png", "media/ui/joypad_qa.png", "media/inventory/qa.png", "Item_Petrol" }) do
        local got = resolve("qa slice", (n == "Item_Petrol") and getTexture(n) or named(n))
        if got:sub(1, 5) ~= "keep:" then bad[#bad + 1] = n .. ": " .. got end
    end
    check(#bad == 0, "items, traits and the controller's glyphs keep their pictures" .. (#bad > 0 and (": " .. table.concat(bad, "; ")) or ""))
    -- the pairs that share a picture (the handoff's checks): the words tell them apart
    local torch = getText("ItemName_Base.HandTorch")
    local PAIRS = {
        { "headlights on / a light source on", getText("ContextMenu_VehicleHeadlightsOn"), LIGHT_ON, "headlight_on", torch .. "\n" .. getText("ContextMenu_Turn_On"), LIGHT_ON, "bulb_on" },
        { "headlights off / a light source off", getText("ContextMenu_VehicleHeadlightsOff"), LIGHT_OFF, "headlight_off", torch .. "\n" .. getText("ContextMenu_Turn_Off"), LIGHT_OFF, "bulb_off" },
        { "get in / change seats", getText("IGUI_EnterVehicle"), "media/ui/vehicles/vehicle_changeseats.png", "car_enter", getText("IGUI_SwitchSeat"), "media/ui/vehicles/vehicle_changeseats.png", "seat" },
        { "get out / a door", getText("IGUI_ExitVehicle"), EXIT, "car_exit", getText("ContextMenu_Open_door"), EXIT, "car_door" },
        { "lock / unlock", getText("ContextMenu_Lock_Doors"), LOCK, "padlock", getText("ContextMenu_Unlock_Doors"), LOCK, "padlock_open" },
        { "hitch / unhitch", getText("ContextMenu_Vehicle_AttachTrailer", "", ""), "media/ui/ZoomIn.png", "link", getText("ContextMenu_Vehicle_DetachTrailer", ""), "media/ui/ZoomOut.png", "unlink" },
        { "zoom in / plus", getText("IGUI_BackButton_Zoom", 50), "media/ui/ZoomIn.png", "zoom_in", "qa slice", "media/ui/ZoomIn.png", "plus" },
        { "zoom out / minus", getText("IGUI_BackButton_Zoom", 150), "media/ui/ZoomOut.png", "zoom_out", torch .. "\n" .. getText("ContextMenu_Unequip"), "media/ui/ZoomOut.png", "minus" },
    }
    for _, pr in ipairs(PAIRS) do
        local a, b = resolve(pr[2], getTexture(pr[3])), resolve(pr[5], getTexture(pr[6]))
        check(a == "id:" .. pr[4] and b == "id:" .. pr[7], string.format("%s share a picture and come out %s / %s", pr[1], a, b))
    end
end)

-- 4. the tab icons
step(2, function()
    local bad = {}
    for k, id in pairs(TABS) do if W.TAB_ICONS[k] ~= id then bad[#bad + 1] = k .. ": " .. tostring(W.TAB_ICONS[k]) .. ", want " .. id end end
    for _, win in ipairs({ ZeD_CharacterWindow, ZeD_WorldWindow }) do
        for _, tab in ipairs(win and win.TABS or {}) do
            local id = W.TAB_ICONS[tab.iconName or ""]
            if not (id and W.iconTex(id, 16)) then bad[#bad + 1] = tostring(tab.id) .. " (" .. tostring(tab.iconName) .. ") has no wheel icon" end
        end
    end
    check(#bad == 0, "the tab icons, and every tab of both windows has one" .. (#bad > 0 and (": " .. table.concat(bad, "; ")) or ""))
end)

-- 5. ZeD's own wheels, every level (the builders and their inner wheels, called as the wheels call them)
local DIR_OF = { character = { left = true }, world = { right = true, up = true }, ["world (server)"] = { up = true },
                 stance = { down = true }, ["ZeD setup"] = { select = true } }
local all = {}
local function idOf(e) local _, _, id = D.pictureOf(e); return id end
local function walk(dir, list, depth, crumb, parent)
    for _, e in ipairs(list or {}) do
        all[#all + 1] = { dir = dir, e = e, depth = depth, crumb = crumb, parent = parent }
        if e.sub and depth < 3 then
            local ok, subs = pcall(e.sub, p, pn)
            if ok then walk(dir, subs, depth + 1, crumb .. " > " .. tostring(e.name), e) end
        end
    end
end
step(2, function()
    for dir, d in pairs(D.DIRS) do
        local ok, top = pcall(D.B[d.build], p, pn)
        if check(ok and type(top) == "table", dir .. ": the wheel builds") then walk(dir, top, 1, dir, nil) end
    end
    -- every slice has a wheel icon, or is an item / glyph (tex) or a colour (swatch)
    local bad, n = {}, 0
    for _, a in ipairs(all) do
        local e = a.e
        local tex, _, id = D.pictureOf(e)
        if id then
            n = n + 1
            if not (IS_ID[id] and tex) then bad[#bad + 1] = a.crumb .. " > " .. tostring(e.name) .. ": " .. tostring(id) .. " is no icon" end
        elseif not (e.tex or e.swatch) then
            bad[#bad + 1] = a.crumb .. " > " .. tostring(e.name) .. ": no picture"
        end
    end
    check(#bad == 0, string.format("%d slices on ZeD's five wheels, %d with a wheel icon, the rest items, glyphs or colours%s", #all, n,
        #bad > 0 and (": " .. table.concat(bad, "; ")) or ""))
    -- the ZeD wheel's pickers: each choice has the setting's icon (the accent's choices are colours)
    bad = {}
    for _, a in ipairs(all) do
        if a.dir == "select" and a.parent and not a.e.swatch and idOf(a.e) ~= idOf(a.parent) then
            bad[#bad + 1] = tostring(a.parent.name) .. " > " .. tostring(a.e.name) .. ": " .. tostring(idOf(a.e))
        end
    end
    check(#bad == 0, "the ZeD wheel's pickers give their choices the setting's icon" .. (#bad > 0 and (": " .. table.concat(bad, "; ")) or ""))
end)
-- each of the map's slices: found by its words on its wheel, with the map's icon
local function split(s) local out = {}; for x in (s .. " / "):gmatch("(.-) / ") do out[#out + 1] = x end; return out end
local function says(name, key)
    local w = word(key)
    local cut = ARG_KEYS[key] and w:find(ARG, 1, true)
    if cut then local pre = w:sub(1, cut - 1); return pre ~= "" and tostring(name):sub(1, #pre) == pre end
    return name == w
end
step(2, function()
    local light = D.H.bestLight and D.H.bestLight(p)
    local found, missing, bad = 0, {}, {}
    for _, r in ipairs(ZED) do
        local top = r[1]:match("^(.-)%s*>") or r[1]
        local dirs = DIR_OF[top] or {}
        local ids = split(r[3])
        local hits = {}
        if r[2]:find("^the wounds") then
            local ok, list = pcall(D.H.treatments, p, pn)
            for _, e in ipairs(ok and type(list) == "table" and list or {}) do hits[#hits + 1] = { e = e, want = { ids[1] } } end
            if #hits == 0 then missing[#missing + 1] = "the wounds (no wound now)" end
        elseif r[2]:find("^the tab slices") then
            local T = ZeD_CharacterWindow.TABS
            for k, ti in ipairs({ 3, 2, 8 }) do
                local nm = ZeD_CharacterWindow.tabLabel(T[ti])
                for _, a in ipairs(all) do if a.dir == "left" and a.depth == 2 and a.e.name == nm and a.e.key ~= nil and a.e.run and not a.e.sub then hits[#hits + 1] = { e = a.e, want = { ids[k] } } end end
            end
        else
            local keys = split((r[2]:gsub("%s*%b()", "")))
            local stem = keys[1]:match("^(.*_)") or ""
            for k, key in ipairs(keys) do
                if not key:find("_") then key = stem .. key end
                for _, a in ipairs(all) do
                    local nm = a.e.name
                    if dirs[a.dir] and (says(nm, key) or (key == "UI_ZeD_Wheel_Light" and light and nm == light:getDisplayName())) then
                        hits[#hits + 1] = { e = a.e, want = (#ids == #keys) and { ids[k] } or ids }
                    end
                end
            end
            if #hits == 0 then missing[#missing + 1] = r[1] .. " / " .. r[2] end
        end
        for _, h in ipairs(hits) do
            local id = idOf(h.e)
            local ok = false
            for _, w in ipairs(h.want) do if id == w then ok = true end end
            if ok then found = found + 1 else bad[#bad + 1] = r[1] .. " / " .. tostring(h.e.name) .. ": " .. tostring(id) .. ", want " .. table.concat(h.want, " or ") end
        end
    end
    check(#bad == 0, string.format("the map's slices on ZeD's wheels: %d with their icon%s", found, #bad > 0 and (", wrong: " .. table.concat(bad, "; ")) or ""))
    if #missing > 0 then notes = notes + 1; say("NOTE not on the wheels now (the state decides): " .. table.concat(missing, "; ")) end
    -- the stance toggles say what they do now
    local cr, aw
    for _, a in ipairs(all) do
        if a.dir == "down" and a.e.name == ZeD.tr("UI_ZeD_Wheel_Crouch") then cr = idOf(a.e) end
        if a.dir == "down" and a.e.name == ZeD.tr("UI_ZeD_Wheel_AutoWalk") then aw = idOf(a.e) end
    end
    local walking = select(2, pcall(function() return p:isAutoWalk() end)) == true
    check(cr == (p:isSneaking() and "sneak_off" or "sneak") and aw == (walking and "autowalk_off" or "autowalk"),
        "Crouch and Auto-walk show what the slice does now: " .. tostring(cr) .. ", " .. tostring(aw))
end)

-- 6. vanilla's radials, live; the cells as drawn (drawContextCell watched for a few frames)
local menu = getPlayerRadialMenu(pn)
local bw = getPlayerBackButtonWheel(pn)
local cells
local M = ZeD.Molecules
local origCell = M.drawContextCell
M.drawContextCell = function(panel, x, y, def, flags, T)
    local k = (def.name or "") .. (flags.isActive and " (pointed)" or "")
    if cells and not cells[k] then cells[k] = { tex = def.iconTexture, px = T.ctx.iconPx, cell = T.ctx.cellW, active = flags.isActive } end
    return origCell(panel, x, y, def, flags, T)
end
local census = { slices = 0, ids = 0, kept = 0, other = {} }
local function survey(tag, m)
    m = m or menu
    local parts = {}
    for i, s in ipairs(m.slices or {}) do
        if not W.isPlace(s) and not W.isBack(s) and not s._zedSwatch then
            census.slices = census.slices + 1
            local got
            if s._zedIcon then got = "id:" .. s._zedIcon
            elseif s._zedTex ~= nil and s._zedTex ~= false then got = "keep?" .. texName(s._zedTex)
            else got = resolve(s.text, s.texture) end
            if got:sub(1, 3) == "id:" then
                census.ids = census.ids + 1
                if not IS_ID[got:sub(4)] then census.other[#census.other + 1] = tag .. " " .. i .. ": " .. got .. " is no icon" end
            else
                local kept = false
                for _, k in ipairs(KEEP) do if got:find(k, 1, true) then kept = true end end
                if kept then census.kept = census.kept + 1 else census.other[#census.other + 1] = tag .. " " .. i .. " (" .. tostring(s.text):gsub("\n", "/") .. "): " .. got end
            end
            parts[#parts + 1] = i .. ":" .. tostring(s.text):gsub("\n", "/") .. "=" .. got:gsub("^id:", "")
        end
    end
    say(tag .. ": " .. #(m.slices or {}) .. " slices | " .. table.concat(parts, "  "))
end
-- the cells drawn since `cells = {}`: each wheel icon at its own size, the size the box asks for
local function drawn(tag, m)
    local bad, n = {}, 0
    if #((m or menu).slices or {}) == 0 then notes = notes + 1; say("NOTE " .. tag .. ": the wheel is empty here"); cells = nil; return end
    local rest, on = ZeD.T.px(W.U.ICON), ZeD.T.px(W.U.ICON_ON)
    for name, c in pairs(cells or {}) do
        local w = c.tex and c.tex:getWidth()
        local nm = texName(c.tex)
        if nm:find("/zed/wheel/", 1, true) then
            n = n + 1
            local _, want = W.iconTex("knife", c.active and on or rest)
            if w ~= c.px or c.px ~= want then bad[#bad + 1] = string.format("%s: drawn %s px from a %s px drawing (want %d)", tostring(name):gsub("\n", "/"), tostring(c.px), tostring(w), want) end
        end
    end
    check(n > 0 and #bad == 0, string.format("%s: %d wheel icons drawn pixel for pixel at the box's size%s", tag, n, #bad > 0 and (": " .. table.concat(bad, "; ")) or ""))
    cells = nil
end
local function closeAll()
    local st = D.state[pn]
    if st and st.menu and st.menu.undisplay then pcall(st.menu.undisplay, st.menu) end
    D.state[pn] = nil
    for _, m in ipairs({ menu, bw }) do if m and m:isReallyVisible() then pcall(m.undisplay, m) end end
    W.qaPoint = nil
end
local function show(m) m = m or menu; if m:isReallyVisible() then return end; m:center(); m:addToUIManager(); if m.setVisible then m:setVisible(true) end end

-- the pickup and the gear the firearm and light wheels need
local car, spawnedCar
do
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do local v = it:next(); if v:getScript():getFullName() == "Base.PickUpTruck" and v:DistTo(p) < 20 then car = v end end
end
if not car then
    local sq = getCell():getGridSquare(math.floor(p:getX()) - 4, math.floor(p:getY()), math.floor(p:getZ()))
    local ok, v = pcall(function() return sq and addVehicleDebug("Base.PickUpTruck", IsoDirections.N, nil, sq) end)
    if ok and v then car, spawnedCar = v, v end
    say("no pickup within 20 tiles; spawned one beside the character: " .. tostring(spawnedCar ~= nil))
end
local inv = p:getInventory()
local function find(full) local items = inv:getItems(); for i = 0, items:size() - 1 do local x = items:get(i); if x:getFullType() == full then return x end end end
local prim, sec = p:getPrimaryHandItem(), p:getSecondaryHandItem()
local gave = {}
local function have(full) local x = find(full); if not x then x = inv:AddItem(full); gave[#gave + 1] = x end; return x end

-- a scene: fill the wheel, point a slice, watch the cells drawn, capture
local function scene(tag, fill, point, m, capture)
    step(10, function() closeAll(); fill(); W.qaPoint = point; cells = {} end)
    step(6, function() survey(tag, m); drawn(tag, m) end)
    if capture ~= false then step(14, function() shot(tag) end) end
    step(4, function() closeAll() end)
end
local function dpad(dir, inner)
    return function()
        if dir == "select" then bw:addCommands(); bw:addToUIManager(true); bw:setVisible(true)
        else ISDPadWheels[({ left = "onDisplayLeft", right = "onDisplayRight", up = "onDisplayUp", down = "onDisplayDown" })[dir]]({ player = pn, id = nil }) end
        if inner then
            local st = D.state[pn]
            for _, e in ipairs(st and st.path[1].entries or {}) do if e.name == inner then D.enter(pn, e); break end end
        end
    end
end
local function stickClick()
    menu:clear()
    menu:addSlice(getText("IGUI_LeftStickButtonRadial_ToggleCrouch"), getTexture(p:isSneaking() and "media/ui/emotes/crouch_off.png" or "media/ui/emotes/crouch_on.png"), nil)
    menu:addSlice(getText("IGUI_LeftStickButtonRadial_ToggleSitOnGround"), getTexture("media/ui/emotes/sit_on.png"), nil)
    menu:addSlice(getText("IGUI_LeftStickButtonRadial_ToggleAutoWalk"), getTexture("media/ui/emotes/autowalk_on.png"), nil)
    for _, s in ipairs(menu.slices) do s.command = { function() end } end   -- (live, not greyed: nothing runs, nothing is taken)
    show()
end
local function scenes(sfx, all7)
    scene("dpad_left" .. sfx, dpad("left"), 2, menu)
    scene("dpad_right" .. sfx, dpad("right"), 2, menu)
    scene("dpad_up" .. sfx, dpad("up"), 1, menu)
    scene("dpad_down" .. sfx, dpad("down"), 4, menu)
    scene("dpad_select" .. sfx, dpad("select"), 1, bw)
    if all7 then
        scene("dpad_left_use", dpad("left", ZeD.tr("UI_ZeD_Wheel_Use")), 1, menu)
        scene("dpad_down_speed", dpad("down", ZeD.tr("UI_ZeD_Wheel_GameSpeed")), 2, menu)
        scene("dpad_down_view", dpad("down", ZeD.tr("UI_ZeD_Wheel_View")), 1, menu)
        scene("dpad_select_theme", dpad("select", ZeD.tr("UI_ZeD_Settings_BaseTheme")), 1, bw)
    end
    scene("emotes" .. sfx, function() ISEmoteRadialMenu:new(p):fillMenu() end, 3, menu)
    if all7 then
        for _, g in ipairs({ "friendly", "hostile", "group", "signal" }) do
            scene("emotes_" .. g, function() ISEmoteRadialMenu:new(p):fillMenu(g) end, 1, menu)
        end
    end
    scene("gun" .. sfx, function()
        p:setPrimaryHandItem(have("Base.Pistol")); have("Base.9mmClip"); for _ = 1, 3 do have("Base.Bullets9mm") end
        local f = ISFirearmRadialMenu:new(p); f:fillMenu(); f:display()
    end, 1, menu)
    scene("light" .. sfx, function()
        p:setSecondaryHandItem(have("Base.HandTorch"))
        local l = ISLightSourceRadialMenu:new(p); l:fillMenu(); l:display()
    end, 1, menu)
    step(2, function() p:setPrimaryHandItem(prim); p:setSecondaryHandItem(sec) end)
    scene("stick" .. sfx, stickClick, 1, menu)
    if all7 then
        scene("vanilla_back", function() D.orig.select(bw); show(bw) end, 2, bw)
        scene("vanilla_dright", function() D.orig.right({ player = pn, id = -1 }); show() end, 1, menu)
        scene("car_outside", function() ISVehicleMenu.showRadialMenu(p) end, 1, menu)
    end
    step(10, function() if car then car:enter(0, p); triggerEvent("OnEnterVehicle", p) end end)
    scene("car_inside" .. sfx, function()
        ISVehicleMenu.showRadialMenu(p)
        if D.H.dashSlice then D.H.dashSlice(p, pn) end
        local last = menu.slices[#menu.slices]
        if all7 and ZeD.Dashboard and ZeD.Dashboard.canTakePad and ZeD.Dashboard.canTakePad(p) then
            check(last and last._zedIcon == "gauge", "in the car: the dashboard slice has the gauge (" .. tostring(last and last._zedIcon) .. ")")
        end
    end, 4, menu)
    step(10, function() if car and p:getVehicle() then p:getVehicle():exit(p); triggerEvent("OnExitVehicle", p) end end)
end

-- 7. at the scale in use, then at 1x
scenes("", true)
step(10, function()
    check(#census.other == 0, string.format("vanilla's radials and ZeD's wheels, live: %d slices, %d wheel icons, %d kept pictures%s", census.slices, census.ids, census.kept,
        #census.other > 0 and (", left over: " .. table.concat(census.other, "; ")) or ""))
    if S and S.uiScaleOption then S.uiScaleOption:setValue(4); S.applyScale() end
end)
step(60, function()
    say(string.format("now at 1x (text size %s): icon box %d at rest, %d pointed", tostring(ZeD.currentSize), ZeD.T.px(W.U.ICON), ZeD.T.px(W.U.ICON_ON)))
end)
scenes("_1x", false)
step(10, function()
    if S and S.uiScaleOption then S.uiScaleOption:setValue(scaleWas or 1); S.applyScale() end
end)
step(60, function()
    M.drawContextCell = origCell
    closeAll()
    for _, it in ipairs(gave) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
    p:setPrimaryHandItem(prim); p:setSecondaryHandItem(sec)
    if spawnedCar then pcall(function() spawnedCar:permanentlyRemove() end); spawnedCar = nil end
    if pairWasOpen and not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    say(string.format("scale back to option %s: icon box %d", tostring(S and S.uiScaleOption and S.uiScaleOption:getValue()), ZeD.T.px(W.U.ICON)))
    say(fails .. " failed, " .. notes .. " notes")
    say("DONE")
end)

-- step(n, fn): fn runs n ticks after the step before it
local function onTick()
    if waitT > 0 then waitT = waitT - 1; return end
    qi = qi + 1
    local s = Q[qi]
    if not s then Events.OnTick.Remove(onTick); return end
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. " " .. tostring(e)) end
    local nxt = Q[qi + 1]
    waitT = nxt and nxt.n or 0
end
waitT = Q[1] and Q[1].n or 0
Events.OnTick.Add(onTick)
say("start car=" .. tostring(car))
