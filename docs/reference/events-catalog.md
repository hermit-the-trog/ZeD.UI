# Project Zomboid Events Catalog

A reference guide to all Lua events in Project Zomboid, organized by category. Events are fired by the engine and can be hooked using `Events.EventName.Add(callback)`.

## Game Lifecycle Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **OnGameBoot** | Before loading screen, at engine startup | `function()` | Early initialization before world loads |
| **OnGameStart** | After player spawns in world | `function()` | Main initialization point for mods |
| **OnGameStateEnter** | When entering a specific game state | `function(state)` | State machine transitions |
| **OnInitWorld** | Before world generation/loading | `function()` | Pre-world setup |
| **OnNewGame** | Creating new game | `function()` | New game setup |
| **OnLoad** | Save file loaded | `function()` | Post-load initialization |
| **OnServerStarted** | Server initialized | `function()` | Server-side startup |
| **OnServerStartSaving** | Before save begins | `function()` | Pre-save logic |
| **OnServerFinishSaving** | After save completes | `function()` | Post-save logic |
| **OnPostSave** | After entire save process | `function()` | Cleanup after saves |
| **OnPostDistributionMerge** | After distribution synchronization | `function()` | Post-sync cleanup |
| **OnPreDistributionMerge** | Before distribution sync | `function()` | Pre-sync preparation |
| **OnInitGlobalModData** | Loading mod global data | `function()` | Access to global mod data |

## Player Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **OnCreatePlayer** | Player object created | `function(player)` | Setup per player |
| **OnCreateSurvivor** | Survivor created (gameplay start) | `function(player)` | Character initialization |
| **OnPlayerDeath** | Player dies | `function(playerObj)` | Death handling, cleanup |
| **OnPlayerMove** | Player moves to adjacent tile | `function(player)` | Movement tracking |
| **OnPlayerUpdate** | Every tick for active player | `function(player)` | Per-frame logic |
| **OnSleepingTick** | Player sleeping (periodic) | `function(player)` | Sleep-state updates |

## Input Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **OnKeyPressed** | Key released after press | `function(key)` | Detect key presses |
| **OnKeyStartPressed** | Key initially pressed | `function(key)` | Key down detection |
| **OnKeyKeepPressed** | Key held continuously | `function(key)` | Sustained key input |
| **OnMouseDown** | Mouse left click | `function(target, x, y)` | Mouse handling |
| **OnMouseWheel** | Mouse wheel scroll | `function(dir)` | Scroll wheel input |
| **OnRightMouseDown** | Right mouse click | `function(x, y)` | Context menu prep |
| **OnContextKey** | Context menu key (default E) | `function()` | Interact key pressed |
| **OnJoypadActivate** | Joypad connected | `function(player)` | Gamepad connection |
| **OnJoypadDeactivate** | Joypad disconnected | `function(player)` | Gamepad loss |
| **OnJoypadBeforeDeactivate** | Before joypad removed | `function(player)` | Pre-disconnect |
| **OnJoypadBeforeReactivate** | Before joypad restored | `function(player)` | Pre-reconnect |
| **OnJoypadRenderUI** | Render joypad overlay | `function()` | Gamepad UI rendering |
| **OnGamepadConnect** | Controller connected | `function()` | New controller |
| **OnGamepadDisconnect** | Controller disconnected | `function()` | Controller removed |

## Rendering Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **OnTick** | Every engine tick (~30fps base) | `function()` | Main update loop |
| **OnRenderTick** | Every render frame | `function()` | Rendering logic |
| **OnPreUIDraw** | Before UI rendering | `function()` | Draw beneath UI |
| **OnPostUIDraw** | After UI rendering | `function()` | Draw above UI |
| **RenderOpaqueObjectsInWorld** | Render opaque world objects | `function()` | Custom world rendering |
| **OnResolutionChange** | Screen resolution changed | `function()` | UI relayout |

## Context Menu Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **OnFillWorldObjectContextMenu** | Building world context menu | `function(player, context, worldobjects, test)` | Add world item options |
| **OnFillInventoryObjectContextMenu** | Building inventory context menu | `function(player, context, items)` | Add inventory options |

## Zombie & Combat Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **OnZombieDead** | Zombie dies | `function(zombie)` | Zombie death logic |
| **OnHitZombie** | Successfully hit zombie | `function(zombie, wielder, bodyPart, weapon)` | Damage application |
| **OnDeadBodySpawn** | Dead body created | `function(body)` | Corpse handling |

## Vehicle Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **OnEnterVehicle** | Player enters vehicle | `function(player, seat)` | Vehicle entry |
| **OnExitVehicle** | Player exits vehicle | `function(player)` | Vehicle exit |
| **OnUseVehicle** | Vehicle interaction | `function(player, vehicle)` | Vehicle use |
| **OnSwitchVehicleSeat** | Change seat | `function(player, vehicle)` | Seat change |
| **OnSpawnVehicleStart** | Vehicle spawning | `function(vehicle)` | Vehicle spawn init |
| **OnVehicleHorn** | Vehicle horn sounded | `function(vehicle)` | Horn activation |
| **OnVehicleDamageTexture** | Vehicle takes damage | `function(vehicle, part)` | Damage application |
| **OnMechanicActionDone** | Mechanic action finished | `function(vehicle, player, action)` | Repair completion |

## World/Environment Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **OnInitWorld** | World initialization | `function()` | World setup |
| **OnLoadMapZones** | Map zones loading | `function()` | Zone data load |
| **OnLoadedMapZones** | Map zones loaded | `function()` | Post-load processing |
| **OnObjectAdded** | World object added | `function(object)` | Object tracking |
| **OnObjectAboutToBeRemoved** | Before object removal | `function(object)` | Cleanup before remove |
| **OnDestroyIsoThumpable** | Thumpable (wall) destroyed | `function(thumpable)` | Wall destruction |
| **LoadGridsquare** | Gridsquare loaded | `function(gridsquare)` | Chunk loading |
| **OnDoTileBuilding2** | Tile being built/modified | `function(x, y, z, player, tile)` | Building progress |
| **OnDoTileBuilding3** | More tile building | `function(x, y, z, player)` | Build completion |

## Item & Crafting Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **OnMakeItem** | Item crafted | `function(recipe, player, items)` | Crafting tracking |
| **OnWeaponHitTree** | Weapon hits tree | `function(player, weapon)` | Tree damage |
| **OnWeaponHitXp** | Weapon hit for XP | `function(player, zombie, weapon, damage)` | Combat XP |
| **OnEquipPrimary** | Primary weapon equipped | `function(player, item)` | Equip primary |
| **OnEquipSecondary** | Secondary/shield equipped | `function(player, item)` | Equip secondary |
| **SetDragItem** | Dragging item | `function(player, item)` | Drag tracking |
| **DoSpecialTooltip** | Custom tooltip rendering | `function(item, tooltip)` | Item tooltips |

## Weather & Climate Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **OnWeatherPeriodStart** | Weather period begins | `function(period)` | Weather start |
| **OnWeatherPeriodStage** | Weather period stage | `function(period, stage)` | Weather progression |
| **OnWeatherPeriodComplete** | Weather period ends | `function(period)` | Weather end |
| **OnThunderEvent** | Thunder occurs | `function()` | Thunder event |
| **OnClimateManagerInit** | Climate system init | `function()` | Climate setup |
| **OnClimateTickDebug** | Climate debug tick | `function()` | Debug climate |
| **OnInitSeasons** | Seasons system initialized | `function()` | Season setup |

## Network/Multiplayer Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **OnConnected** | Connected to server | `function()` | Connection established |
| **OnConnectFailed** | Connection failed | `function()` | Connection error |
| **OnDisconnect** | Disconnected from server | `function()` | Connection lost |
| **OnConnectionStateChanged** | Connection state changed | `function(state)` | State transition |
| **OnCoopJoinFailed** | Coop join failed | `function()` | Join error |
| **OnCoopServerMessage** | Server message received | `function(message)` | Server broadcast |
| **OnNetworkUsersReceived** | Network users list | `function()` | User sync |
| **OnClientCommand** | Command from client | `function(command, args)` | Client command |
| **OnServerCommand** | Command from server | `function(command, args)` | Server command |

## UI/Chat Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **OnChatWindowInit** | Chat window initializing | `function()` | Chat setup |
| **OnAddMessage** | Chat message added | `function(message, player)` | Message tracking |
| **OnAdminMessage** | Admin message | `function(message)` | Admin broadcast |
| **OnAlertMessage** | Alert message | `function(message)` | Alert display |
| **SwitchChatStream** | Chat stream switched | `function(stream)` | Stream change |
| **OnTabAdded** | Tab added to window | `function(tab)` | Tab creation |
| **OnTabRemoved** | Tab removed | `function(tab)` | Tab removal |
| **OnSetDefaultTab** | Default tab set | `function(tab)` | Tab default |

## Trade/Commerce Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **OnProcessTransaction** | Processing trade | `function(buyer, seller, items)` | Trade logic |
| **TradingUIAddItem** | Add item to trade | `function(item, container)` | UI trade add |
| **TradingUIRemoveItem** | Remove item from trade | `function(item, container)` | UI trade remove |
| **TradingUIUpdateState** | Trade UI state | `function(state)` | Trade state |
| **RequestTrade** | Trade requested | `function(requester, target)` | Trade init |
| **AcceptedTrade** | Trade accepted | `function(trader1, trader2)` | Trade accepted |
| **OnProcessAction** | Action being processed | `function(action, player)` | Action tracking |

## Faction/Social Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **ReceiveFactionInvite** | Faction invite received | `function(faction, inviter)` | Invite tracking |
| **AcceptedFactionInvite** | Faction invite accepted | `function(player, faction)` | Invite accepted |
| **OnSafehousesChanged** | Safehouse list changed | `function()` | Safehouse update |
| **ReceiveSafehouseInvite** | Safehouse invite | `function(safehouse)` | Invite received |
| **AcceptedSafehouseInvite** | Safehouse invite accepted | `function()` | Invite accepted |
| **SyncFaction** | Faction synced | `function()` | Faction sync |

## XP/Progression Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **AddXP** | XP added to skill | `function(skillName, amount, player)` | XP tracking |
| **LevelPerk** | Perk leveled up | `function(perk)` | Level gain |
| **OnWeaponHitXp** | Melee hit for XP | `function(player, zombie, weapon)` | Combat XP |

## Periodic Tick Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **EveryOneMinute** | Every 1 minute | `function()` | Frequent updates |
| **EveryTenMinutes** | Every 10 minutes | `function()` | Regular updates |
| **EveryHours** | Every 1 hour | `function()` | Hourly updates |
| **EveryDays** | Every 1 day | `function()` | Daily updates |

## Utility Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **OnMainMenuEnter** | Main menu displayed | `function()` | Menu init |
| **OnResetLua** | Lua engine reset | `function()` | Cleanup before reset |
| **RefreshCheats** | Cheat codes refreshed | `function()` | Cheat update |

## Steam/Workshop Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **OnSteamGameJoin** | Steam join invite | `function(params)` | Steam invite |
| **OnSteamFriendStatusChanged** | Friend status changed | `function(friend)` | Friend update |
| **OnSteamRefreshInternetServers** | Server list refresh | `function()` | Server sync |
| **OnSteamServerResponded** | Server responded | `function(server)` | Response received |
| **OnSteamServerResponded2** | Server responded (alt) | `function(server)` | Response received |
| **OnSteamServerFailedToRespond2** | Server timeout | `function()` | No response |
| **OnSteamRulesRefreshComplete** | Server rules loaded | `function()` | Rules sync |
| **OnSteamWorkshopItemUpdated** | Workshop item updated | `function(item)` | Update complete |
| **OnSteamWorkshopItemCreated** | Workshop item created | `function(item)` | Creation complete |
| **OnSteamWorkshopItemNotUpdated** | Workshop update failed | `function()` | Update failed |
| **OnSteamWorkshopItemNotCreated** | Workshop creation failed | `function()` | Creation failed |
| **OnServerWorkshopItems** | Server workshop items | `function()` | Workshop sync |

## Miscellaneous Events

| Event | Fires | Callback Signature | Usage |
|-------|-------|-------------------|-------|
| **OnItemFound** | Item discovered in search | `function(item)` | Search result |
| **OnMiniScoreboardUpdate** | Scoreboard updated | `function()` | Score update |
| **OnScoreboardUpdate** | Full scoreboard update | `function()` | Score sync |
| **OnInitRecordedMedia** | Media system init | `function()` | Media setup |
| **OnDynamicMovableRecipe** | Movable recipe found | `function(recipe)` | Recipe discovery |
| **OnMovingObjectCrop** | Moving object crop | `function(object)` | Crop tracking |
| **OnContainerUpdate** | Container contents changed | `function(container)` | Inventory sync |
| **OnWaterAmountChange** | Water amount changed | `function()` | Water level update |
| **OnWarUpdate** | War state updated | `function()` | War tracking |
| **OnMiniScoreboardUpdate** | Mini scoreboard | `function()` | Score mini update |
| **OnMouseDown** | Mouse click | `function(target, x, y)` | Click handling |
| **OnObjectLeftMouseButtonDown** | Object left click | `function(object, x, y)` | World click |
| **OnObjectLeftMouseButtonUp** | Object left release | `function(object, x, y)` | Click release |
| **OnObjectRightMouseButtonDown** | Object right click | `function(object, x, y)` | Context click |
| **OnObjectRightMouseButtonUp** | Object right release | `function(object, x, y)` | Context release |
| **OnLoadRadioScripts** | Radio scripts loaded | `function()` | Radio init |
| **OnLoadSoundBanks** | Sound banks loaded | `function()` | Audio init |
| **MngInvReceiveItems** | Manage inv receive items | `function(items)` | Item receipt |
| **OnFishingActionMPUpdate** | Fishing multiplayer update | `function(action, data)` | Fishing sync |
| **OnPressRackButton** | Rack button pressed | `function(weapon)` | Firearm action |
| **OnPressReloadButton** | Reload button pressed | `function(weapon)` | Reload action |
| **OnPressWalkTo** | Walk-to command | `function(x, y, z)` | Movement command |
| **OnReceiveUserlog** | Userlog message | `function(data)` | Logging |
| **OnClickedAnimalForContext** | Animal context clicked | `function(animal)` | Animal context |
| **OnAnimalTracks** | Animal tracks found | `function(tracks)` | Track detection |
| **OnRolesReceived** | Roles received | `function()` | Role sync |
| **OnCGlobalObjectSystemInit** | Client global objects | `function()` | Client init |
| **OnSGlobalObjectSystemInit** | Server global objects | `function()` | Server init |
| **OnChallengeQuery** | Challenge query | `function(query)` | Challenge check |
| **OnOverrideSearchManager** | Override search system | `function()` | Search override |
| **onEnableSearchMode** | Search mode enabled | `function()` | Search activation |
| **onUpdateIcon** | Icon updated | `function(icon)` | Icon refresh |
| **OnDeviceText** | Device text displayed | `function(text)` | Device output |
| **OnQRReceived** | QR code scanned | `function(data)` | QR data |
| **OnGoogleAuthRequest** | Google auth request | `function(code)` | Auth request |
| **ViewBannedIPs** | View banned IPs | `function()` | IP list |
| **ViewBannedSteamIDs** | View banned Steam IDs | `function()` | Steam ban list |
| **ViewTickets** | View support tickets | `function()` | Ticket list |
| **ServerPinged** | Server pinged | `function()` | Ping received |

---

## Event Registration Examples

```lua
-- Simple event with no parameters
Events.OnGameStart.Add(function()
    print("Game started!")
end)

-- Event with player parameter
Events.OnPlayerDeath.Add(function(playerObj)
    print(playerObj:getUsername() .. " died!")
end)

-- Event with multiple parameters
Events.OnFillWorldObjectContextMenu.Add(function(player, context, worldobjects, test)
    if test then return end  -- Skip during test passes
    context:addOption("Custom Option", worldobjects, function()
        print("Custom action!")
    end)
end)

-- Removing event listener
local function myCallback()
    print("Event fired")
end
Events.OnTick.Add(myCallback)
Events.OnTick.Remove(myCallback)
```

## Best Practices

1. **Timing**: Use `OnGameStart` for main mod initialization, not `OnGameBoot`
2. **Cleanup**: Always remove listeners when no longer needed to avoid memory leaks
3. **Performance**: Keep event callbacks lightweight; use timers for heavy work
4. **Server vs Client**: Check `isServer()` / `isClient()` when event fires on both
5. **Multiplayer Safety**: Validate player objects and use proper network synchronization
