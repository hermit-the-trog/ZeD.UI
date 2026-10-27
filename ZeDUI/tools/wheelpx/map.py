"""Which wheel icon goes where: the one source the handoff's tables and wheel_icons_map.json are made from.
(The `slices` noted on each icon in the i_*.py modules were first guesses while drawing; this file decides.)

Four kinds of rule, in the order the wheel should try them:
  TEXT   a vanilla slice's words (a translation key): several vanilla slices share one picture, the words tell them apart
  KEEP   vanilla pictures that stay (items, traits, the controller's button glyphs)
  TEX    a vanilla picture, by a piece of its file name (lower case, forward slashes)
  ZED    ZeD's own wheels (ZeD_DpadWheels.lua): the icon or tab name a slice names now, and the new id; where one old
         name stands for two things, the slice decides
"""

TEXT = [   # (translation key the slice's words come from, the texture it comes with if that matters, id, why)
    ("UI_optionscreen_binding_Toggle Survival Guide", None, "guide", "vanilla shows the shrug"),
    ("IGUI_MiniMap_Toggle", None, "minimap", "all three map slices share Map_On"),
    ("IGUI_MiniMap_Focus", None, "pin", "all three map slices share Map_On"),
    ("IGUI_Emote_Shout", None, "bullhorn", "vanilla shows the Talkative trait"),
    ("IGUI_Emote_Group", None, "group", "the emote category; vanilla reuses Follow me's picture"),
    ("IGUI_BackButton_Zoom", "ZoomIn", "zoom_in", "ZoomIn and ZoomOut also mean add and remove elsewhere"),
    ("IGUI_BackButton_Zoom", "ZoomOut", "zoom_out", ""),
    ("ContextMenu_Vehicle_AttachTrailer", None, "link", "vanilla shows ZoomIn"),
    ("ContextMenu_Vehicle_AttachVehicle", None, "link", "towing another vehicle"),
    ("ContextMenu_Vehicle_DetachTrailer", None, "unlink", "vanilla shows ZoomOut"),
    ("ContextMenu_VehicleHeadlightsOn", None, "headlight_on", "vehicle_lightsON is the light sources' too"),
    ("ContextMenu_VehicleHeadlightsOff", None, "headlight_off", ""),
    ("ContextMenu_VehicleHotwire", None, "hotwire", "vanilla shows the ignition"),
    ("ContextMenu_VehicleHotwireSkill", None, "hotwire_off", "not skilled enough yet"),
    ("IGUI_EnterVehicle", None, "car_enter", "vanilla shows Change seats"),
    ("IGUI_ExitVehicle", None, "car_exit", ""),
    ("ContextMenu_Open_door", None, "car_door", "vanilla shows Exit"),
    ("ContextMenu_Close_door", None, "car_door", ""),
    ("IGUI_OpenHood", None, "car_door", ""), ("IGUI_CloseHood", None, "car_door", ""),
    ("IGUI_OpenTrunk", None, "car_door", ""), ("IGUI_CloseTrunk", None, "car_door", ""),
    ("ContextMenu_Unlock_Doors", None, "padlock_open", "Lock and Unlock share vehicle_lockdoors"),
    ("ContextMenu_UnlockDoor", None, "padlock_open", ""), ("IGUI_UnlockHood", None, "padlock_open", ""),
    ("IGUI_UnlockTrunk", None, "padlock_open", ""),
    ("ContextMenu_Vehicle_Wash", None, "wash", "vanilla shows the water drop item"),
    ("ContextMenu_CheckAnimalInsideTrailer", None, "cow", "vanilla shows the lamb item"),
    ("ContextMenu_FullInventory", None, "gas_can", "fuel, greyed: vanilla shows the petrol item"),
    ("ContextMenu_VehicleNeedHose", None, "gas_siphon", "siphoning, greyed: needs a hose"),
]

KEEP = ["item_", "trait_", "xbox", "joypad", "media/inventory"]   # items, traits, button glyphs: their own pictures

TEX = [   # (group, a piece of the texture's name, id); the first match wins, so the order matters
    # the vehicle
    ("vehicle", "vehicle_changeseats", "seat"), ("vehicle", "vehicle_ignitionon", "key"), ("vehicle", "vehicle_ignitionoff", "key_off"),
    ("vehicle", "vehicle_lightson", "bulb_on"), ("vehicle", "vehicle_lightsoff", "bulb_off"),
    ("vehicle", "vehicle_temperaturehot", "heat"), ("vehicle", "vehicle_temperaturecold", "snowflake"),
    ("vehicle", "vehicle_horn", "horn"), ("vehicle", "vehicle_lightbar", "lightbar"), ("vehicle", "vehicle_speakers", "speaker"),
    ("vehicle", "vehicle_windowopen", "window_open"), ("vehicle", "vehicle_windowclosed", "window_close"),
    ("vehicle", "vehicle_smash_window", "window_smash"), ("vehicle", "vehicle_lockdoors", "padlock"),
    ("vehicle", "vehicle_repair", "engine"), ("vehicle", "vehicle_sleep", "bed"), ("vehicle", "vehicle_exit", "car_exit"),
    ("vehicle", "vehicle_refuel_from_pump", "gas_pump"), ("vehicle", "vehicle_add_gas", "gas_can"), ("vehicle", "gas_refuel", "gas_can"),
    ("vehicle", "vehicle_siphon_gas", "gas_siphon"), ("vehicle", "gas_siphon", "gas_siphon"),
    # the firearm and the light source
    ("firearm and light", "firearmradial_insertmagazine", "mag_in"), ("firearm and light", "firearmradial_ejectmagazine", "mag_out"),
    ("firearm and light", "firearmradial_bulletsintomagazine", "rounds_mag"), ("firearm and light", "firearmradial_bulletsintofirearm", "rounds_in"),
    ("firearm and light", "firearmradial_bulletsfromfirearm", "rounds_out"), ("firearm and light", "firearmradial_unjam", "unjam"),
    ("firearm and light", "firearmradial_rack", "rack"), ("firearm and light", "firearmradial_chamberround", "chamber"),
    ("firearm and light", "lightsourceradial_insertbattery", "battery_in"), ("firearm and light", "lightsourceradial_removebattery", "battery_out"),
    # the animal
    ("animal", "animalactions_kill", "knife"), ("animal", "animalactions_grab", "carry_animal"), ("animal", "animalactions_milk", "milk"),
    ("animal", "animalactions_pet", "pet"), ("animal", "animalactions_rope", "rope"), ("animal", "animalactions_shear", "scissors"),
    ("animal", "animalactions_stats", "info"),
    # the back button's wheel, furniture, foraging, the map, speed, zoom
    ("back button, furniture, map", "heart2_on", "heart"), ("back button, furniture, map", "carpentry_on", "craft"),
    ("back button, furniture, map", "build_tool", "bricks"), ("back button, furniture, map", "furniture_off2", "chair"),
    ("back button, furniture, map", "furniture_pickup", "box_up"), ("back button, furniture, map", "furniture_place", "box_down"),
    ("back button, furniture, map", "furniture_rotate", "rotate"), ("back button, furniture, map", "furniture_disassemble", "screwdriver"),
    ("back button, furniture, map", "furniture_on2", "wrench"), ("back button, furniture, map", "foraging/eyeconon", "eye"),
    ("back button, furniture, map", "foraging/eyeconoff", "eye_off"), ("back button, furniture, map", "search_on_64", "magnifier"),
    ("back button, furniture, map", "search_off_64", "magnifier_off"), ("back button, furniture, map", "animalzone_on_64", "fence"),
    ("back button, furniture, map", "buildingroomseditor_64", "rooms"), ("back button, furniture, map", "worldmap/map_on", "map"),
    ("back button, furniture, map", "speedcontrols/play_off", "play"), ("back button, furniture, map", "speedcontrols/pause_off", "pause"),
    ("back button, furniture, map", "speedcontrols/ffwd1_off", "ff1"), ("back button, furniture, map", "speedcontrols/ffwd2_off", "ff2"),
    ("back button, furniture, map", "speedcontrols/wait_off", "wait"),
    ("back button, furniture, map", "zoomin", "plus"), ("back button, furniture, map", "zoomout", "minus"),
    # the emotes (category pictures included: Friendly is thumbsup, Signal is moveout) and the stick click's toggles
    ("emotes and stances", "emotes/wavehello", "wave"), ("emotes and stances", "emotes/wavebye", "wave_bye"),
    ("emotes and stances", "emotes/wave", "wave"), ("emotes and stances", "emotes/clap", "clap"),
    ("emotes and stances", "emotes/thumbsup", "thumbs_up"), ("emotes and stances", "emotes/thumbup", "thumbs_up"),
    ("emotes and stances", "emotes/thumbsdown", "thumbs_down"), ("emotes and stances", "emotes/thumbdown", "thumbs_down"),
    ("emotes and stances", "emotes/thankyou", "bow"), ("emotes and stances", "emotes/insult", "insult"),
    ("emotes and stances", "emotes/stop", "hand"), ("emotes and stances", "emotes/surrender", "surrender"),
    ("emotes and stances", "emotes/followme", "follow_me"), ("emotes and stances", "emotes/comehere", "come_here"),
    ("emotes and stances", "emotes/comefromfront", "come_here"), ("emotes and stances", "emotes/yes", "yes"),
    ("emotes and stances", "emotes/no", "no"), ("emotes and stances", "emotes/shrug", "shrug"),
    ("emotes and stances", "emotes/undecided", "undecided"), ("emotes and stances", "emotes/ceasefire", "target_off"),
    ("emotes and stances", "emotes/fire", "target"), ("emotes and stances", "emotes/moveout", "move_out"),
    ("emotes and stances", "emotes/freeze", "freeze"), ("emotes and stances", "emotes/followbehind", "follow_behind"),
    ("emotes and stances", "emotes/salute", "salute"), ("emotes and stances", "emotes/group", "group"),
    ("emotes and stances", "emotes/gears", "gears"),
    ("emotes and stances", "emotes/crouch_on", "sneak"), ("emotes and stances", "emotes/crouch_off", "sneak_off"),
    ("emotes and stances", "emotes/sit_on", "sit_ground"), ("emotes and stances", "emotes/sit_off", "sit_ground_off"),
    ("emotes and stances", "emotes/autowalk_on", "autowalk"), ("emotes and stances", "emotes/autowalk_off", "autowalk_off"),
]
# emotes/back stays the strip's own back glyph (ZeD_Wheel's W.isBack draws it): no picture needed

ZED = [   # (wheel, the slice: its label key, what it names now, id)
    # the character wheel (D-pad down)
    ("character", "UI_ZeD_Wheel_Tabs", "tab loot-tab-white", "crate"),
    ("character", "UI_ZeD_Wheel_Weapons", "knife", "knife"),
    ("character", "ContextMenu_Eat", "apple-whole", "apple"),
    ("character", "ContextMenu_Drink", "water-045-drink", "glass"),
    ("character", "UI_ZeD_Wheel_Medicine", "bandage-wound", "medkit"),
    ("character", "ContextMenu_Sleep", "bed", "bed"),
    ("character", "UI_ZeD_Wheel_Clothing", "fi-br-shirt-long-sleeve", "shirt"),
    ("character", "UI_ZeD_Wheel_Use", "backpack", "backpack"),
    ("character > Weapons", "UI_ZeD_Wheel_HandsFree", "backpack", "hand"),
    ("character > Medicine", "the wounds (H.treatments' entries)", "bandage-wound", "bandage"),
    ("character > Medicine, Clothing, Radio", "the tab slices (Health, Equipment, Radio)", "tab health- / equipment- / radio-tab-white", "heart / jacket / walkie"),
    ("character > Use", "ContextMenu_Smoke", "smoking", "cigarette"),
    ("character > Use", "ContextMenu_Read", "book-open-reader", "book"),
    ("character > Use", "UI_ZeD_Wheel_Watch", "clock", "watch"),
    ("character > Use", "IGUI_ItemType_Radio", "survival-077-radio", "walkie"),
    ("character > Watch", "UI_ZeD_Wheel_OpenWatch", "clock", "watch"),
    ("character > Watch", "UI_ZeD_Wheel_WatchLight", "lightbulb-on", "bulb_on"),
    ("character > Watch", "UI_ZeD_Wheel_WatchAlarm", "essential-collection-213-alarm", "alarm"),
    ("character > Radio", "UI_ZeD_Wheel_NextStation", "fm-radio", "seek"),
    # the world wheel (D-pad right)
    ("world", "UI_ZeD_Wheel_Tabs", "tab craft-tab-white", "craft"),
    ("world", "UI_ZeD_Wheel_Map", "crafting-game-037-map", "map"),
    ("world", "UI_ZeD_Wheel_Vehicle", "car-mechanic", "car"),
    ("world", "UI_ZeD_Wheel_Animal", "cow", "cow"),
    ("world", "UI_ZeD_Wheel_CraftBuild", "carpentry-015-toolbox", "toolbox"),
    ("world", "UI_ZeD_Wheel_Search", "fi-br-magnifying-glass-wave", "magnifier"),
    ("world", "UI_ZeD_Wheel_LightsPower", "lightbulb-on", "bulb_on"),
    ("world", "IGUI_Zone_Name", "map-marker", "fence"),
    ("world", "IGUI_Emote_Shout", "bullhorn", "bullhorn"),
    ("world (server)", "UI_ZeD_Wheel_Chat", "text-box-dots", "chat"),
    ("world (server)", "UI_ZeD_Wheel_Safety", "fi-br-lock", "padlock"),
    ("world (server)", "UI_ZeD_Wheel_Players", "handshake", "group"),
    ("world > Map", "IGUI_WorldMap_Toggle", "crafting-game-037-map", "map"),
    ("world > Map", "IGUI_MiniMap_Toggle", "fi-br-map-point", "minimap"),
    ("world > Map", "IGUI_MiniMap_Focus", "map-marker", "pin"),
    ("world > Craft and build", "IGUI_CraftingWindow_Title", "tab craft-tab-white", "craft"),
    ("world > Craft and build", "UI_ZeD_World_TabBuilding", "tab build-tab-white", "bricks"),
    ("world > Craft and build", "IGUI_BackButton_Movable", "tab move-tab-white", "chair"),
    ("world > Search", "UI_enable_search_mode", "eye", "eye"),
    ("world > Search", "UI_disable_search_mode", "eye", "eye_off"),
    ("world > Search", "UI_investigate_area_window_show", "tab forage-tab-white", "magnifier"),
    ("world > Search", "IGUI_Pickup", "fi-br-picking-box", "box_up"),
    ("world > Lights and power", "UI_ZeD_Wheel_RoomLights", "lightbulb-on", "bulb_on"),
    ("world > Lights and power", "ContextMenu_Generator", "doomsday-007-generator", "generator"),
    ("world > Lights and power", "ContextMenu_Light_fire / ContextMenu_Put_out_fire", "campfire", "campfire"),
    ("world > Vehicle", "IGUI_VehiclePartCatdashboard", "fuel-gauge", "gauge"),
    # the stance and settings wheel (D-pad left), its sub-wheels
    ("stance", "UI_ZeD_Wheel_Sit", "sitting-ground", "sit_ground"),
    ("stance", "UI_ZeD_Wheel_Crouch", "emotes/crouch_on / crouch_off", "sneak / sneak_off"),
    ("stance", "UI_ZeD_Wheel_AutoWalk", "emotes/autowalk_on / autowalk_off (else fi-br-person-walking-arrow-right)", "autowalk / autowalk_off"),
    ("stance", "UI_ZeD_Wheel_GameSpeed", "vanilla speedControls/Pause_Off", "ff1"),
    ("stance", "UI_ZeD_Wheel_Zoom", "vanilla ZoomIn", "zoom_in"),
    ("stance", "UI_ZeD_Wheel_View", "eye", "eye"),
    ("stance", "UI_ZeD_Wheel_Help", "info-guide", "help"),
    ("stance", "UI_ZeD_Wheel_Light (or the light's name)", "lightbulb-on", "bulb_on"),
    ("stance > Sit", "ContextMenu_SitGround / UI_ZeD_Wheel_GetUp", "emotes/sit_on / sit_off", "sit_ground / sit_ground_off"),
    ("stance > Sit", "UI_ZeD_Wheel_SitOn / UI_ZeD_Wheel_SitOnSeat", "chair", "sit_seat"),
    ("stance > Speed", "IGUI_BackButton_Play / UI_optionscreen_binding_Pause", "speedControls/Play_Off / Pause_Off", "play / pause"),
    ("stance > Speed", "IGUI_BackButton_FF1 / FF2 / FF3", "speedControls/FFwd1_Off / FFwd2_Off / Wait_Off", "ff1 / ff2 / wait"),
    ("stance > Zoom", "IGUI_BackButton_Zoom (nearer / farther)", "ZoomIn / ZoomOut", "zoom_in / zoom_out"),
    ("stance > View", "UI_ZeD_Wheel_HideInterface / UI_ZeD_Wheel_ShowInterface", "eye", "eye_off / eye"),
    ("stance > View", "UI_ZeD_Wheel_ResetWindows", "rotate-left", "rotate"),
    ("stance > View", "UI_ZeD_Settings_TextSize", "text-box-dots", "textsize"),
    ("stance > View", "UI_mainscreen_option", "gears", "gears"),
    ("stance > Help", "UI_optionscreen_binding_Toggle Survival Guide", "info-guide", "guide"),
    ("stance > Help", "UI_ZeD_Wheel_ControllerMap", "question", "gamepad"),
    # the ZeD setup wheel and its pickers (each picker's choices take the setting's icon)
    ("ZeD setup", "UI_ZeD_Settings_BaseTheme", "settings", "theme"),
    ("ZeD setup", "UI_ZeD_Settings_TextSize", "text-box-dots", "textsize"),
    ("ZeD setup", "UI_ZeD_Settings_SeeThrough", "architectural-windows-017-window-16", "seethrough"),
    ("ZeD setup", "UI_ZeD_Settings_FocusStyle", "fi-br-hand-back-point-right", "focus"),
    ("ZeD setup", "UI_ZeD_Settings_UiScale", "magnifying-glass-eye", "scale"),
    ("ZeD setup", "UI_ZeD_Settings_Moodles", "smile", "smiley"),
    ("ZeD setup", "UI_ZeD_Settings_ActionBar", "clock", "progress"),
    ("ZeD setup", "UI_ZeD_Msg_Title", "inbox-in", "inbox"),
    ("ZeD setup", "UI_ZeD_Wheel_ResetWindows", "rotate-left", "rotate"),
    ("ZeD setup", "UI_ZeD_Options_GroupZed", "gears", "gears"),
    ("ZeD setup", "UI_ZeD_Settings_SafeMode", "bolt-slash", "safemode"),
]

TABS = [   # the window tabs' slices (C.tabs, Wd.tabs and the rest name a tab by its icon name)
    ("loot-tab-white", "crate"), ("equipment-tab-white", "jacket"), ("health-tab-white", "heart"),
    ("thermal-tab-white", "thermometer"), ("identy-tab-white", "idcard"), ("journal-tab-white", "notebook"),
    ("skills-tab-white", "skills"), ("radio-tab-white", "walkie"), ("craft-tab-white", "craft"),
    ("build-tab-white", "bricks"), ("move-tab-white", "chair"), ("map-tab-white", "map"),
    ("forage-tab-white", "magnifier"), ("farm-tab-white", "cow"), ("vehicle-tab-white", "car"),
    ("appearance-tab-white", "mirror"), ("traits-tab-white", "traits"),
]


def used():
    ids = set()
    for r in TEXT: ids.add(r[2])
    for r in TEX: ids.add(r[2])
    for r in TABS: ids.add(r[1])
    for r in ZED:
        for t in r[3].split("/"): ids.add(t.strip())
    return ids
