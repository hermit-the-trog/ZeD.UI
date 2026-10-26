-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/POM.lua
-- ============================================================================
-- SUPPORT FOR PLAYERS ON MAP (mod id POM, Workshop 2879960936). Mockup
-- zed_map_overlays_v1, approved "as recommended" Oct 26 2026.
--
-- The mod draws every player on the game's map and mini-map as a bright green
-- square with the name under it (its client PlayersOnMap.lua, drawPlayerOnMap),
-- from the list its server sends ("PlayersOnMap" / "players"; in single player its
-- own pom_getPlayers), under its sandbox rules (SandboxVars.PlayersOnMap: Enabled,
-- ShowPlayerNames, ShowMyName, ShowOnlyFaction, ShowDeadPlayers, MaxDistance;
-- admins see everyone). ZeD's Maps tab is its own map, so ZeD draws the same,
-- through the Maps tab's general hook (MapsTabExt.lua):
--   * other players as the mod's green squares with their names, by the mod's rules
--     (the game's own dot for the character stays; the game's own dots for others
--     give way to the mod's squares, as the mod switches them off on the game's map);
--   * your own name under your dot when the mod's Show My Name allows;
--   * a Players section in the side list: each name, how far and which way;
--     a click (or A) centres the map on that player.
-- Without the mod the map shows the game's own dots as the server allows
-- (MapsTab.lua).
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "POM"

local function modOn()
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    for i = 0, list:size() - 1 do
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
if not modOn() then return end

require "ZeD/Tokens"
require "ZeD/Tr"
require "ZeD/MapsTab"

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.POM = S

local GREEN = { r = 0, g = 1, b = 0 }   -- the mod's pom_dot_color
local DEAD = { r = 0.47, g = 0.47, b = 0.47 }

local function sb() return (SandboxVars and SandboxVars.PlayersOnMap) or {} end
local function enabled() return sb().Enabled ~= false end

-- the server's list, as the mod keeps it (multiplayer)
local _list = nil
local function onServerCommand(module, command, args)
    if module == "PlayersOnMap" and command == "players" then _list = args end
end
if Events and Events.OnServerCommand then Events.OnServerCommand.Add(onServerCommand) end

-- the players the mod would draw, with where they are now
local function players()
    local src = _list
    if not isClient() and pom_getPlayers then
        local ok, l = pcall(pom_getPlayers)
        if ok then src = l end
    end
    if not (src and src.players) then return {} end
    local me = getPlayer()
    if not me then return {} end
    local out = {}
    local rules = sb()
    local admin = isAdmin()
    local myFaction = Faction and Faction.getPlayerFaction(me)
    for _, p in pairs(src.players) do
        local isMe = (isClient() and p.id == me:getOnlineID()) or ((not isClient()) and p.num == me:getPlayerNum())
        local q = p
        -- a fresher place from the player object when this client has it (as the mod does)
        local obj = nil
        if isClient() and p.id then obj = getPlayerByOnlineID(p.id) end
        if not isClient() and p.num then obj = getSpecificPlayer(p.num) end
        if obj and pom_getPlayer then
            local ok, fresh = pcall(pom_getPlayer, obj)
            if ok and fresh then q = fresh end
        end
        local skip = false
        if q.invisible and not admin and not isMe then skip = true end
        if (not q.alive) and not rules.ShowDeadPlayers and not admin and not isMe then skip = true end
        local dx, dy = q.x - me:getX(), q.y - me:getY()
        local dist = math.sqrt(dx * dx + dy * dy)
        if not isMe and not admin and (rules.MaxDistance or -1) >= 0 and dist > rules.MaxDistance then skip = true end
        if rules.ShowOnlyFaction and not admin and not isMe then
            if not myFaction or myFaction:getName() ~= q.faction_name then skip = true end
        end
        if not skip then
            out[#out + 1] = { me = isMe, name = q.username or "", x = q.x, y = q.y, alive = q.alive ~= false, dist = dist, dx = dx, dy = dy }
        end
    end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    return out
end

-- "140 m north", "1.2 km south-east" (world +y is south; 2.414 = tan 67.5)
local function away(p)
    local ax, ay = math.abs(p.dx), math.abs(p.dy)
    local ns = (p.dy < 0) and "N" or "S"
    local ew = (p.dx < 0) and "W" or "E"
    local k
    if ax > ay * 2.414 then k = ew
    elseif ay > ax * 2.414 then k = ns
    else k = ns .. ew end
    local dir = ZeD.tr("UI_ZeD_Map_Dir" .. k)
    if p.dist >= 1000 then
        return ZeD.tr("UI_ZeD_Map_AwayKm", string.format("%.1f", p.dist / 1000), dir)
    end
    return ZeD.tr("UI_ZeD_Map_AwayM", tostring(math.floor(p.dist + 0.5)), dir)
end

local X = { order = 40 }

-- the game's dots for others give way to the mod's squares
function X.mapMade(mp, win)
    if enabled() then pcall(function() mp.mapAPI:setBoolean("RemotePlayers", false) end) end
end

function X.drawMap(mp, win)
    if not enabled() then return end
    local T, tm = ZeD.T, ZeD.TM
    local f = T.fontF1
    local fh = tm:getFontHeight(f)
    local rules = sb()
    local names = rules.ShowPlayerNames ~= false
    local half = T.px(3)
    for _, p in ipairs(players()) do
        local x = math.floor(mp.mapAPI:worldToUIX(p.x, p.y))
        local y = math.floor(mp.mapAPI:worldToUIY(p.x, p.y))
        if x > -T.px(80) and y > -T.px(30) and x < mp:getWidth() + T.px(80) and y < mp:getHeight() + T.px(30) then
            if not p.me then
                local c = p.alive and GREEN or DEAD
                mp:drawRect(x - half, y - half, half * 2 - 1, half * 2 - 1, 1, c.r, c.g, c.b)
                mp:drawRectBorder(x - half, y - half, half * 2, half * 2, 1, 0, 0, 0)
            end
            local showName = names and ((not p.me) or rules.ShowMyName)
            if showName and p.name ~= "" then
                local w = tm:MeasureStringX(f, p.name) + T.px(8)
                local ny = y + half * 2 - T.px(2)
                mp:drawRect(x - w / 2, ny, w, fh + T.px(1), 0.5, 0.5, 0.5, 0.5)
                mp:drawText(p.name, x + T.px(4) - w / 2, ny, 0, 0, 0, 1, f)
            end
        end
    end
end

-- the Players section: only other players, only while there are any
function X.side(win)
    if not enabled() then return nil end
    local rows = {}
    for _, p in ipairs(players()) do
        if not p.me then
            local px, py = p.x, p.y
            rows[#rows + 1] = { key = p.name, dot = p.alive and GREEN or DEAD, title = p.name, sub = away(p),
                activate = function(w)
                    local mp = w._worldMapPanel
                    if mp then mp.mapAPI:centerOn(px, py) end
                end }
        end
    end
    if #rows == 0 then return nil end
    return { key = "players", title = ZeD.tr("IGUI_Map_Sharing_Players"), count = #rows, rows = rows }
end

S.X = X   -- (the QA scripts drive it)
ZeD.MapsTab.addExtension(MOD_ID, X)
