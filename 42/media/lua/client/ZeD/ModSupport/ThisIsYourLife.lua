-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/ThisIsYourLife.lua
-- ============================================================================
-- THIS IS YOUR LIFE (Workshop 3773911887, mod id ThisIsYourLife; the director, Nov 2 2026, punch list 64: "support
-- it", scripted starts and poster stories included; the plan approved: "go with your plan for this is your life").
--
-- The mod takes over the game's own spawn, sandbox, occupation and looks screens at class level and puts its own
-- postcard screens on top. ZeD's main menu stands in for those screens at the instance level (MM.redirect), so under
-- ZeD the mod's screens never come up and no hometown is ever set. This file gives the mod's choices a ZeD home:
--
--   Spawn       the mod's hidden town "This Is Your Life" stays in ZeD's list; its Next opens the Hometown page
--   Hometown    ZeD's Spawn window again (the same map, house markers, town video and words), listing the mod's 11
--               hometowns with their origin trait, then (single player) its five poster stories. Next hands the pick
--               to the mod (TIYL.Flow.completeOrigin / completePosterStory) and goes on as the town's Next would.
--   a hometown  carries on through ZeD's own Sandbox, Occupation, Traits and Looks; the mod sets the spawn, the
--               origin trait, the map reveal and the partner start itself (its OnCreatePlayer hook). When ZeD's
--               Occupation comes up the pick is handed over once more, so a partner start ticked in Sandbox counts.
--   a story     fixes the name, the job, the traits and the look, so ZeD lets the mod's own occupation and looks
--               screens run (they fill themselves in and press Play): MM.redirectPass.
--   Back        from the Hometown page to the town list; a normal town clears any pending pick (TIYL.Flow.abandon).
-- ============================================================================
require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSpawn"

local MOD_ID = "ThisIsYourLife"
local MM = ZeD.MainMenu

local function modOn()
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    for i = 0, list:size() - 1 do
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
local function ready() return modOn() and TIYL and TIYL.Flow and TIYL.Origins and TIYL.REGION_NAME end

-- the poster stories' names (the mod draws them as flyer pictures only) and their opening lines' keys
local STORIES = {
    { id = "wizardskeep", name = "UI_ZeD_TIYL_StoryWizard",      opening = "UI_TIYL_Poster_Wizard_Opening1" },
    { id = "bakesale",    name = "UI_ZeD_TIYL_StoryBakeSale",    opening = "UI_TIYL_Poster_BakeSale_Opening1" },
    { id = "carfixation", name = "UI_ZeD_TIYL_StoryCarFixation", opening = "UI_TIYL_Poster_CarFixation_Opening1" },
    { id = "catfish",     name = "UI_ZeD_TIYL_StoryCatfish",     opening = "UI_TIYL_Poster_Catfish_Opening1" },
    { id = "dixiecabin",  name = "UI_ZeD_TIYL_StoryDixie",       opening = "UI_TIYL_Poster_Dixie_Opening1" },
}

local function vanilla() return MapSpawnSelect and MapSpawnSelect.instance end
local function isTiylItem(it) return it and it.region and it.region.name == TIYL.REGION_NAME end

-- the mod's hidden town in vanilla's list: its index and region
local function tiylIndex()
    local v = vanilla()
    if not (v and v.listbox) then return nil end
    for i, e in ipairs(v.listbox.items) do
        if isTiylItem(e.item) then return i, e.item.region end
    end
    return nil
end

-- the region chosen as the mod's own (as the mod's reselectTIYLRegion does)
local function selectTiylRegion()
    local v = vanilla()
    local i, region = tiylIndex()
    if not (v and i and region) then return false end
    v.listbox.selected = i
    v.selectedRegion = region
    pcall(setSpawnRegion, region.name)
    pcall(function() getCore():setSelectedMap(tostring(region.name)) end)
    return true
end

-- a hometown's houses for the map's markers (the mod's own spawn points, or its town's file)
local function originPoints(o)
    if o.spawnPoints then return o.spawnPoints end
    if not o.spawnDirectory then return nil end
    local ok, pts = pcall(SpawnRegionMgr.loadSpawnPointsFile, "media/maps/" .. o.spawnDirectory .. "/spawnpoints.lua", false)
    return ok and pts or nil
end

-- vanilla's own town for a hometown (its video and zoom come along)
local function vanillaTown(o)
    local v = vanilla()
    if not (v and v.listbox and o.spawnDirectory) then return nil end
    for _, e in ipairs(v.listbox.items) do
        local it = e.item
        if it and (it.name == o.spawnDirectory or (it.region and it.region.name == o.spawnDirectory)) then return it end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- THE HOMETOWN PAGE: ZeD's Spawn window with the mod's hometowns and stories
-- ---------------------------------------------------------------------------
ZeD_MMHometown = ZeD_MMSpawn:derive("ZeD_MMHometown")

function ZeD_MMHometown:new()
    local o = ZeD_MMSpawn.new(self)
    o._items = nil
    o.titleKey = "UI_ZeD_TIYL_Title"
    return o
end

function ZeD_MMHometown:items()
    if self._items then return self._items end
    local t = {}
    for _, o in ipairs(TIYL.Origins) do
        local tx = TIYL.Origins.getText or function(x, f) return tostring(x[f] or "") end
        local name = tx(o, "name")
        local blurb = tx(o, "blurb")
        local benefit = tx(o, "uniqueBenefit")
        local vt = vanillaTown(o)
        local it = { name = name, tiyl = { kind = "origin", id = o.id },
                     desc = blurb .. "<LINE>" .. ZeD.tr("UI_ZeD_TIYL_OriginTrait", benefit) }
        if o.id ~= "random" then
            local pts = originPoints(o)
            it.region = { name = TIYL.REGION_NAME, points = pts or {} }
            if vt then it.demoVideo, it.zoomX, it.zoomY, it.zoomS = vt.demoVideo, vt.zoomX, vt.zoomY, vt.zoomS end
        end
        t[#t + 1] = it
    end
    -- the poster stories, single player only (the mod's own rule)
    if not isClient() and TIYL.PosterStories and TIYL.PosterStories.get then
        for _, s in ipairs(STORIES) do
            local st = TIYL.PosterStories.get(s.id)
            if st and st.player then
                local p = st.player
                local who = ((p.forename or "") .. " " .. (p.surname or "")):gsub("^%s+", ""):gsub("%s+$", "")
                local line = getTextOrNull and getTextOrNull(s.opening)
                local desc = ZeD.tr("UI_ZeD_TIYL_StoryDesc", who)
                if line and line ~= "" then desc = desc .. "<LINE>\"" .. line .. "\"" end
                t[#t + 1] = { name = ZeD.tr("UI_ZeD_TIYL_StoryRow", ZeD.tr(s.name)), tiyl = { kind = "story", id = s.id }, desc = desc,
                              region = { name = TIYL.REGION_NAME, points = { unemployed = { { posX = p.posX, posY = p.posY, posZ = p.posZ or 0 } } } } }
            end
        end
    end
    self._items = t
    return t
end

function ZeD_MMHometown:isRandom(it) return it ~= nil and it.tiyl ~= nil and it.tiyl.id == "random" end
function ZeD_MMHometown:hasDetails() return false end   -- (the save name and seed were on the town list)

function ZeD_MMHometown:onShow()
    self._items = nil
    ZeD_MMSpawn.onShow(self)
    self.sel = 1
    self.focusId = "town:1"
end

-- NEXT: the pick goes to the mod, then on as the town's Next would (sandbox options or character creation)
function ZeD_MMHometown:next()
    local it = self:items()[self.sel]
    local v = vanilla()
    if not (it and it.tiyl and v) then return end
    if not selectTiylRegion() then
        print("[ZeD] This Is Your Life: the mod's town is not in the list; the town list stays")
        MM.showView("spawn")
        return
    end
    MM.clickSound()
    local ok, err = pcall(function()
        if it.tiyl.kind == "story" then TIYL.Flow.completePosterStory(it.tiyl.id)
        else TIYL.Flow.completeOrigin(it.tiyl.id) end
    end)
    if not ok then print("[ZeD] This Is Your Life: the mod refused the pick: " .. tostring(err)); return end
    if not (TIYL.PendingOriginId or TIYL.PendingPosterStoryId) then
        print("[ZeD] This Is Your Life: the pick did not take (" .. tostring(it.tiyl.id) .. ")")
        return
    end
    print("[ZeD] This Is Your Life: " .. it.tiyl.kind .. " " .. tostring(it.tiyl.id))
    local i = tiylIndex()
    v.listbox.selected = i
    MM.toVanilla()
    MapSpawnSelect.clickNext(v)
end

-- BACK: the town list, the pick dropped
function ZeD_MMHometown:back()
    MM.clickSound()
    pcall(TIYL.Flow.abandon)
    MM.showView("spawn")
end

-- ---------------------------------------------------------------------------
-- THE TOWN LIST: the mod's town opens the Hometown page; any other town drops a pick
-- ---------------------------------------------------------------------------
local baseNext = ZeD_MMSpawn.next
function ZeD_MMSpawn:next()
    if getmetatable(self) == ZeD_MMSpawn and ready() then
        local it = self:items()[self.sel]
        if isTiylItem(it) then
            if self:nameProblem() then return end
            MM.clickSound()
            self:syncToVanilla()
            selectTiylRegion()
            MM.showView("tiyl")
            return
        end
        pcall(TIYL.Flow.abandon)
    end
    return baseNext(self)
end

-- the mod's town says what it is in the town list (its own description is empty)
local baseDesc = ZeD_MMSpawn.drawDesc
function ZeD_MMSpawn:drawDesc(x, y, w, h, it)
    if getmetatable(self) == ZeD_MMSpawn and ready() and isTiylItem(it) and not it._zedTiylDesc then
        it._zedTiylDesc = true
        it.desc = ZeD.tr("UI_ZeD_TIYL_TownDesc")
    end
    return baseDesc(self, x, y, w, h, it)
end

-- ---------------------------------------------------------------------------
-- THE LATER SCREENS: a story lets the mod's own occupation and looks run; a hometown is handed over again
-- ---------------------------------------------------------------------------
local prevPass = MM.redirectPass
function MM.redirectPass(screen)
    if prevPass and prevPass(screen) then return true end
    if not ready() then return false end
    local m = MainScreen and MainScreen.instance
    if not m then return false end
    if screen ~= m.charCreationProfession and screen ~= m.charCreationMain then return false end
    if TIYL.PendingPosterStoryId then return true end
    -- a hometown: hand it over again as Occupation comes up (the mod reads the partner start from Sandbox then)
    if screen == m.charCreationProfession and TIYL.PendingOriginId then
        pcall(TIYL.Flow.completeOrigin, TIYL.PendingOriginId)
    end
    return false
end

MM.addView("tiyl", "tiylWin", function() return ZeD_MMHometown:new() end)
print("[ZeD] This Is Your Life support loaded" .. (modOn() and "" or " (mod off: nothing changes)"))
