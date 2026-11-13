-- ZeD-UI/42/media/lua/client/ZeD/FishingTab.lua
-- ============================================================================
-- THE FISHING TAB — client; an organism on the World window's tab strip.
-- A contextual tab: it shows while a fishing rod is in the main hand or water is
-- close (ZeD.FishingLog.visible), last in the strip's second group. One list
-- under a pinned header strip, the band at the foot:
--   the header      the line's state (Ready to cast, Line in the water, Fish on,
--                   No bait, No rod in hand) and where the water or the bobber is
--   the hero        the rod as the game names it, its line, hook and bait, Fishing
--   the chips       what the game's own Fishing panel lets this level read
--   BAIT            the bait in the bags; a row picks one for Add / Change bait,
--                   and from Fishing 6 how the species already caught rate it
--   CATCH LOG       this trip, then the newest catches of the whole game, with
--                   the Trophy wall key that opens the wall (ZeD.FishingWall)
--   MORE DETAIL     a fold: what this Fishing level gives
-- Every verb is the game's own: Cast moves the game's fishing state on, Reel in
-- and Let out line ask the rod for a short pull (FishingLog.pull), the bait keys
-- queue the game's Add Bait / Remove Bait actions, Stop fishing ends the state as
-- the game's stop key does. Nothing here changes how fishing plays.
-- The list is built first (FT.build, plain tables), then measured and drawn, so
-- what each state shows can be checked without the game.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ZeD_WorldWindow"
require "ZeD/FishingLog"
require "ZeD/FishingWall"

ZeD = ZeD or {}   -- Reload-safe: loading this file twice reuses the table instead of wiping it.
ZeD.FishingTab = ZeD.FishingTab or {}
local FT = ZeD.FishingTab
local Log = ZeD.FishingLog

FT.ID = "fishing"
local PAD, ROW_H, HEAD_H, COL_H, BAND2_H = 12, 24, 20, 18, 26   -- design units
local KV_H, SKILL_W, PIC_W = 18, 112, 64
local KEEP = { keepCase = true }   -- (the chips are the game's own words: drawn as they come)

local function tr(k, ...) return ZeD.tr(k, ...) end
local function px(n) return ZeD.T.px(n) end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
local function nowMs() return (getTimestampMs and getTimestampMs()) or 0 end
-- an item type's name, looked up once (the tab names the same few dozen types every frame: bait, junk, the log's)
local _names = {}
local function itemName(ft)
    if not ft then return "" end
    local n = _names[ft]
    if n == nil then
        n = safe(function() return getItemNameFromFullType(ft) end, ft)
        _names[ft] = n
    end
    return n
end

-- an item type's picture, looked up once (the game's own icon file, as its Fishing panel finds it)
local _icons = {}
local function iconOf(ft)
    if not ft then return nil end
    local c = _icons[ft]
    if c == nil then
        c = safe(function()
            local si = getScriptManager():FindItem(ft)
            local icon = si and si:getIcon()
            if si and si:getIconsForTexture() and not si:getIconsForTexture():isEmpty() then icon = si:getIconsForTexture():get(0) end
            return icon and getTexture("media/textures/Item_" .. icon .. ".png") or false
        end, false)
        _icons[ft] = c
    end
    return c or nil
end
FT.iconOf = iconOf

-- ---------------------------------------------------------------------------
-- THE SNAPSHOT: what the tab reads from the game this frame
-- ---------------------------------------------------------------------------
local function chipsOf(p, lv, wx, wy)
    local out = {}
    if wx and Fishing then
        local river = safe(function() return Fishing.isRiver(wx, wy) end, false)
        out[#out + 1] = { text = tr(river and "UI_ZeD_Fish_River" or "UI_ZeD_Fish_Lake"), tone = "acc" }
        if safe(function() return Fishing.Utils.isNearShore(wx, wy) end, false) then
            out[#out + 1] = { text = tr("UI_ZeD_Fish_NearShore"), tone = "dim" }
        end
    end
    local U = Fishing and Fishing.Utils
    if not U then return out end
    -- the game's own Fishing panel words and skill gates: Time from 2, Temperature 4, Weather 6, Wind 8
    local function chip(labelKey, gate, judge)
        local word, tone
        if lv < gate then word, tone = getText("Fluid_Unknown"), "unknown"
        else word, tone = judge() end
        out[#out + 1] = { text = tr("UI_ZeD_Fish_ChipKV", getText(labelKey), word), tone = tone }
    end
    chip("Sandbox_TimeOptions", 2, function()
        local t = U.getTimeParams()
        if t.coeff > 1 then return getText("IGUI_health_Good"), "good" end
        return getText("Sandbox_Normal"), "norm"
    end)
    chip("IGUI_Temperature", 4, function()
        local t = U.getTemperatureParams(p)
        if t.coeff == 1 then return getText("IGUI_health_Good"), "good" end
        if t.coeff == 0.75 then return getText("Sandbox_Normal"), "norm" end
        return getText("IGUI_Fishing_BadParam"), "bad"
    end)
    chip("IGUI_ClimateControl_Weather", 6, function()
        local t = U.getWeatherParams()
        if t.isFog then return getText("IGUI_Fishing_BadParam"), "bad" end
        if t.isRain then return getText("IGUI_health_Good"), "good" end
        return getText("Sandbox_Normal"), "norm"
    end)
    chip("IGUI_Fishing_Wind", 8, function()
        if getClimateManager():getWindPower() >= 0.5 then return getText("IGUI_Fishing_BadParam"), "bad" end
        return getText("Sandbox_Normal"), "norm"
    end)
    return out
end

-- The chips, worked out twice a second per player and again as soon as the water square or the level changes.
-- The shore test alone reads up to 225 squares (Fishing.Utils.isNearShore: 15 x 15 around the bobber); the game
-- itself asks only when its bobber's timer fires, and the weather it reads moves slower than that.
local CHIPS_MS = 500
local _chips = {}
local function chipsFor(p, lv, wx, wy)
    local key = p:getPlayerNum()
    local c = _chips[key]
    local t = nowMs()
    if c and t - c.at < CHIPS_MS and c.x == wx and c.y == wy and c.lv == lv then return c.list end
    if not c then c = {}; _chips[key] = c end
    c.at, c.x, c.y, c.lv, c.list = t, wx, wy, lv, chipsOf(p, lv, wx, wy)
    return c.list
end

-- the name the Skills tab knows Fishing by: the perk's own name, which the game translates (PerkFactory names each
-- perk with getText("IGUI_perks_" ..)), so the English word finds nothing in any other language
local function fishingPerkName() return Perks.Fishing:getName() end

--- What the tab shows for player p this frame, read from the game (st: the tab's own state, for the
--- picked bait and the fight's start).
function FT.snap(p, st)
    local s = { p = p, baits = Log.baits(p), lv = p:getPerkLevel(Perks.Fishing) }
    s.state = Log.state(p, s.baits)
    s.rod = Log.rodInHand(p)
    s.onHook = Log.onHook(s.rod)
    s.tackle = Log.tackle(s.rod)
    s.water = Log.water(p)
    s.data = Log.data(p)
    local gt = getGameTime()
    s.wa = gt and gt:getWorldAgeHours() or 0
    s.recent = Log.recent(p, (s.state == "wait" or s.state == "fight" or s.state == "nobait") and 3 or Log.LOG_SHOW)
    s.mounted = Log.mountedCount(p)
    s.caught = Log.caughtCount(p)
    s.speciesN = Log.speciesCount()
    -- (only with no rod in hand: Equip rod and the No rod line ask for it)
    s.bagRod = (s.state == "norod") and Log.rodInBags(p) or nil
    s.xpPct = 0
    local SK = ZeD.SkillsTab
    if SK and SK.getPinData then
        local okN, perkName = pcall(fishingPerkName)
        local okP, pin = false, nil
        if okN and perkName then okP, pin = pcall(SK.getPinData, p, perkName) end
        if okP and pin and pin.xpPct then s.xpPct = pin.xpPct end
    end
    -- the bait on the hook gets a row of its own when none of its kind is left in the bags (the game takes a lure
    -- or the last worm out of the bags as it goes on the hook), so it can still be picked and taken off
    if s.onHook then
        local inBags = false
        for _, b in ipairs(s.baits) do if b.type == s.onHook then inBags = true end end
        if not inBags then
            s.hookRow = { type = s.onHook, name = itemName(s.onHook), n = 0,
                          lure = (Fishing and Fishing.IsArtificalLure and Fishing.IsArtificalLure(s.onHook)) or false }
        end
    end
    -- the bait picked in the list: the one on the hook, else the first. The hook's bait is always a choice (picked,
    -- the bait key takes it off), with or without more of its kind in the bags.
    if st then
        local found = st.sel ~= nil and st.sel == s.onHook
        for _, b in ipairs(s.baits) do if b.type == st.sel then found = true end end
        if not found then st.sel = nil end
        if not st.sel then st.sel = s.onHook or (s.baits[1] and s.baits[1].type) end
        s.sel = st.sel
    end
    s.ratings, s.ratedN = Log.ratings(p, (s.state == "wait" or s.state == "fight") and s.onHook or s.sel)
    local m = Log.manager(p)
    local fr = m and m.fishingRod
    s.mgr, s.fr = m, fr
    if fr and fr.bobber then
        local bx, by = fr.bobber:getX(), fr.bobber:getY()
        s.bobber = { d = math.floor(math.sqrt((bx - p:getX()) ^ 2 + (by - p:getY()) ^ 2) + 0.5), dir = Log.bearing(p:getX(), p:getY(), bx, by) }
        s.tension = safe(function() return fr:getTension() end, 0)
        local lim = fr.tensionLimit or -1
        s.held = (lim > 0) and math.min(1, (fr.highTensionTimer or 0) / lim) or 0
    end
    local wx, wy = nil, nil
    if s.bobber then wx, wy = math.floor(fr.bobber:getX()), math.floor(fr.bobber:getY())
    elseif s.water then wx, wy = s.water.x, s.water.y end
    s.chips = chipsFor(p, s.lv, wx, wy)
    return s
end

-- ---------------------------------------------------------------------------
-- THE LIST: plain items per state (FT.build), then measured and drawn
-- ---------------------------------------------------------------------------
local function add(L, it) L[#L + 1] = it; return it end

local function wallCount(s) return s.mounted or 0 end

local function logSection(L, s)
    local d = s.data
    add(L, { k = "head", text = tr("UI_ZeD_Fish_LogHead"),
             right = (#s.recent < (d.n or 0)) and tr("UI_ZeD_Fish_LogOf", #s.recent, d.n or 0) or tr("UI_ZeD_Fish_LogGame", d.n or 0),
             wall = true, count = wallCount(s) })
    if #s.recent == 0 then
        add(L, { k = "empty", text = tr("UI_ZeD_Fish_LogEmpty") })
        return
    end
    add(L, { k = "col", cols = "log" })
    for i, e in ipairs(s.recent) do add(L, { k = "log", e = e, i = i }) end
end

local function tripSection(L, s)
    -- (a trip that went quiet is over: the record stays until the next cast, but it is no longer this trip)
    local tr0 = Log.liveTrip(s.data, s.wa)
    if not tr0 or (tr0.landed + tr0.junk + tr0.gone) == 0 then return end
    local wa0 = tr0.wa0 or 0
    add(L, { k = "head", text = tr("UI_ZeD_Fish_TripHead"), right = tr("UI_ZeD_Fish_TripSince", FT.hhmmAgo(wa0)) })
    add(L, { k = "fact", label = tr("UI_ZeD_Fish_TripLanded"), value = tr("UI_ZeD_Fish_TripFish", tr0.landed),
             sub = tr("UI_ZeD_Fish_TripOther", tr0.junk, tr0.gone) })
    if tr0.heavy then add(L, { k = "fact", label = tr("UI_ZeD_Fish_TripHeavy"), value = tr0.heavy, sub = string.format("%.2f", tr0.heavyWt or 0) }) end
    add(L, { k = "fact", label = tr("UI_ZeD_Fish_TripTotal"), value = string.format("%.2f", tr0.total or 0) })
    local used = {}
    for bt, n in pairs(tr0.baits or {}) do used[#used + 1] = tr("UI_ZeD_Fish_NOf", n, itemName(bt)) end
    table.sort(used)
    if #used > 0 then add(L, { k = "fact", label = tr("UI_ZeD_Fish_TripBait"), value = table.concat(used, ", ") }) end
    if tr0.line0 and tr0.line1 then
        add(L, { k = "fact", label = tr("UI_ZeD_Fish_Line"),
                 value = tr("UI_ZeD_Fish_FromTo", math.floor(tr0.line0 * 100 + 0.5), math.floor(tr0.line1 * 100 + 0.5)) })
    end
    add(L, { k = "fact", label = tr("UI_ZeD_Fish_TripSpecies"), value = tr("UI_ZeD_Fish_NOfM", s.caught, s.speciesN),
             sub = tr("UI_ZeD_Fish_GameRecord") })
end

local function baitSection(L, s, locked)
    local total = 0
    for _, b in ipairs(s.baits) do total = total + b.n end
    add(L, { k = "head", text = tr("UI_ZeD_Fish_BaitHead"), right = tr("UI_ZeD_Fish_BaitCount", #s.baits, total) })
    local hook = s.hookRow   -- (the bait on the hook, none of its kind left in the bags: first, its count 0)
    if #s.baits == 0 and not hook then
        add(L, { k = "empty", text = tr("UI_ZeD_Fish_NoBaitBags") })
        return
    end
    add(L, { k = "col", cols = "bait" })
    if hook then add(L, { k = "bait", r = hook, on = true, sel = (not locked) and (hook.type == s.sel), locked = locked }) end
    for _, b in ipairs(s.baits) do
        add(L, { k = "bait", r = b, on = (b.type == s.onHook), sel = (not locked) and (b.type == s.sel), locked = locked })
    end
    if #s.baits == 0 then add(L, { k = "empty", text = tr("UI_ZeD_Fish_NoBaitBags") }) end
    if s.ratings and #s.ratings > 0 then
        local bt = locked and s.onHook or s.sel
        local lines = {}
        for _, g in ipairs(s.ratings) do
            local names = {}
            for _, ft in ipairs(g.types) do names[#names + 1] = itemName(ft) end
            lines[#lines + 1] = { grade = tr(g.key), names = table.concat(names, ", ") }
        end
        add(L, { k = "rate", cap = tr("UI_ZeD_Fish_RateCap", itemName(bt), s.ratedN), lines = lines })
    end
end

-- the game's bait groups, each item's own name (fishing_properties.lua)
local GROUPS = {
    { t = "Worms", key = "UI_ZeD_Fish_GWorms" }, { t = "Insect", key = "UI_ZeD_Fish_GInsects" },
    { t = "Leeches", key = "UI_ZeD_Fish_GLeeches" }, { t = "Minnows", key = "UI_ZeD_Fish_GMinnows" },
    { t = "Flesh", key = "UI_ZeD_Fish_GFlesh" }, { t = "Plant", key = "UI_ZeD_Fish_GPlants" },
    { t = "ArtificalLure", key = "UI_ZeD_Fish_GLures" },
}
-- The junk and the bait groups' item names, put together once: the game's tables do not change in a game, and
-- the section names about fifty items and sorts seven lists. { junk = "..", groups = { { key, names }, .. } }
local _noBait = nil
local function noBaitNames()
    if _noBait then return _noBait end
    local nb = { groups = {} }
    local junk = {}
    for _, ft in ipairs((Fishing and Fishing.trashItems) or {}) do junk[#junk + 1] = itemName(ft) end
    nb.junk = table.concat(junk, ", ")
    for _, g in ipairs(GROUPS) do
        local set = Fishing and Fishing.lure and Fishing.lure[g.t]
        if set then
            local names, seen = {}, {}
            for ft in pairs(set) do
                local n = itemName(ft)
                if not seen[n] then seen[n] = true; names[#names + 1] = n end
            end
            table.sort(names)
            nb.groups[#nb.groups + 1] = { key = g.key, names = table.concat(names, ", ") }
        end
    end
    if Fishing then _noBait = nb end   -- (kept only once the game's fishing tables are there)
    return nb
end

local function noBaitSection(L)
    local nb = noBaitNames()
    add(L, { k = "head", text = tr("UI_ZeD_Fish_BaitHead"), right = "0" })
    add(L, { k = "empty", bad = true, text = tr("UI_ZeD_Fish_BareHook", nb.junk) })
    add(L, { k = "head", text = tr("UI_ZeD_Fish_TakeHead") })
    for _, g in ipairs(nb.groups) do add(L, { k = "fact", label = tr(g.key), value = g.names }) end
    add(L, { k = "head", text = tr("UI_ZeD_Fish_WhereHead") })
    add(L, { k = "fact", label = getText("IGUI_ScavengeUI_Title"), value = tr("UI_ZeD_Fish_WhereForage") })
    add(L, { k = "fact", label = itemName("Base.FishingNet"), value = tr("UI_ZeD_Fish_WhereNet") })
    add(L, { k = "fact", label = tr("UI_ZeD_Fish_WhereFoodLab"), value = tr("UI_ZeD_Fish_WhereFood") })
end

local function detailSection(L, s, st)
    add(L, { k = "fold", text = tr("UI_ZeD_Fish_More"), right = tr("UI_ZeD_Fish_MoreLine", s.lv), open = st.fold })
    if not st.fold then return end
    local lv = s.lv
    local U = Fishing and Fishing.Utils
    local lim = U and U.skillSizeLimit and U.skillSizeLimit[lv]
    local nxt = U and U.skillSizeLimit and U.skillSizeLimit[lv + 1]
    if lim then
        add(L, { k = "fact", label = tr("UI_ZeD_Fish_FSpecies"), value = tr("UI_ZeD_Fish_UpToKg", lim),
                 sub = nxt and tr("UI_ZeD_Fish_AtLevel", lv + 1, tr("UI_ZeD_Fish_UpToKg", nxt)) or nil })
    end
    if U and U.getFishSizeChancesBySkillLevel then
        local a, b, c = U.getFishSizeChancesBySkillLevel(lv, false, 1)
        local a2, b2, c2 = U.getFishSizeChancesBySkillLevel(lv, true, 1)
        local function sizes(x, y, z)
            return tr("UI_ZeD_Fish_Sizes", getText("IGUI_Fish_Small"), math.floor(x + 0.5), getText("IGUI_Fish_Medium"),
                math.floor(y + 0.5)) .. " | " .. getText("IGUI_Fish_Big") .. " " .. math.floor(z + 0.5)
        end
        add(L, { k = "fact", label = tr("UI_ZeD_Fish_FSizes"), value = sizes(a, b, c), sub = tr("UI_ZeD_Fish_NearShoreSub", sizes(a2, b2, c2)) })
    end
    -- FishingRod:consumeLure: live bait goes when ZombRand(20) beats the level, a lure one time in 30 x (level + 1)
    add(L, { k = "fact", label = tr("UI_ZeD_Fish_FUsed"), value = tr("UI_ZeD_Fish_UsedVal", math.max(0, 19 - lv)),
             sub = tr("UI_ZeD_Fish_LureVal", 30 * (lv + 1)) })
    -- Fish:getFishByLure: less junk from Fishing 5, 7 and 9
    local junkKey = (lv >= 9 and "UI_ZeD_Fish_JunkL9") or (lv >= 7 and "UI_ZeD_Fish_JunkL7") or (lv >= 5 and "UI_ZeD_Fish_JunkL5") or "UI_ZeD_Fish_JunkL0"
    add(L, { k = "fact", label = tr("UI_ZeD_Fish_FJunk"), value = tr(junkKey) })
    -- FishingRod:getSpawnBobberCoords: up to 1.5 / (level + 1) tiles each way
    add(L, { k = "fact", label = tr("UI_ZeD_Fish_FCast"), value = tr("UI_ZeD_Fish_CastVal", string.format("%.1f", 1.5 / (lv + 1))) })
    add(L, { k = "fact", label = tr("UI_ZeD_Fish_FTrophy"), value = tr(lv >= 8 and "UI_ZeD_Fish_TrophyYes" or "UI_ZeD_Fish_TrophyAt") })
    add(L, { k = "fact", label = tr("UI_ZeD_Fish_FRatings"), value = tr(lv >= Log.RATE_LV and "UI_ZeD_Fish_RatingsYes" or "UI_ZeD_Fish_RatingsAt") })
end

local function heroItems(L, s)
    add(L, { k = "hero" })
    if #s.chips > 0 then add(L, { k = "chips", chips = s.chips }) end
end

--- The tab's list for snapshot s (FT.snap) and the tab's state st: plain items, in order.
function FT.build(s, st)
    local L = {}
    local state = s.state
    if state == "fight" then
        add(L, { k = "tension" })
        add(L, { k = "hero" })
        logSection(L, s)
    elseif state == "wait" then
        heroItems(L, s)
        baitSection(L, s, true)
        logSection(L, s)
        detailSection(L, s, st)
    elseif state == "nobait" then
        heroItems(L, s)
        noBaitSection(L)
        logSection(L, s)
    elseif state == "ready" then
        heroItems(L, s)
        baitSection(L, s, false)
        tripSection(L, s)
        logSection(L, s)
        detailSection(L, s, st)
    else
        add(L, { k = "empty", text = tr(s.bagRod and "UI_ZeD_Fish_HoldRod" or "UI_ZeD_Fish_NoRodBags") })
        tripSection(L, s)
        logSection(L, s)
    end
    return L
end

--- The band at the foot for snapshot s: { status, buttons, lead } as ZeD.Molecules.drawBand takes them
--- (ids, not callbacks: FT.press runs them).
function FT.band(s, st)
    local b = { buttons = {}, lead = {} }
    local function btn(list, id, key, variant, disabled, help)
        list[#list + 1] = { id = id, label = tr(key), variant = variant, disabled = disabled, help = help and tr(help) or nil }
    end
    local state = s.state
    if st.ask == "clear" then
        b.question = tr("UI_ZeD_Fish_ClearAsk")
        btn(b.buttons, "cancel", "UI_Cancel")
        btn(b.buttons, "clearyes", "UI_ZeD_Fish_ClearLog", "danger")
        return b
    end
    local canClear = #(s.data.log or {}) > 0
    if state == "ready" then
        b.status = st.msg or tr("UI_ZeD_Fish_AimHint")
        local key = "UI_ZeD_Fish_AddBait"
        if s.onHook and s.sel == s.onHook then key = "UI_ZeD_Fish_RemoveBait"
        elseif s.onHook then key = "UI_ZeD_Fish_ChangeBait" end
        if canClear then btn(b.lead, "clear", "UI_ZeD_Fish_ClearLog") end
        btn(b.buttons, "bait", key, nil, s.sel == nil, "UI_ZeD_Fish_HelpBait")
        btn(b.buttons, "cast", "UI_ZeD_Fish_Cast", "primary", false, "UI_ZeD_Fish_HelpCast")
    elseif state == "wait" then
        b.status = st.msg or tr("UI_ZeD_Fish_BaitLocked")
        btn(b.buttons, "stop", "UI_ZeD_Fish_Stop", nil, false, "UI_ZeD_Fish_HelpStop")
        btn(b.buttons, "reel", "UI_ZeD_Fish_Reel", "primary", false, "UI_ZeD_Fish_HelpReel")
    elseif state == "fight" then
        btn(b.buttons, "stop", "UI_ZeD_Fish_Stop", nil, false, "UI_ZeD_Fish_HelpStop")
        btn(b.buttons, "release", "UI_ZeD_Fish_LetOut", nil, false, "UI_ZeD_Fish_HelpLetOut")
        btn(b.buttons, "reel", "UI_ZeD_Fish_Reel", "primary", false, "UI_ZeD_Fish_HelpReel")
    elseif state == "nobait" then
        b.status = st.msg or tr("UI_ZeD_Fish_JunkOnly")
        btn(b.buttons, "cast", "UI_ZeD_Fish_Cast", nil, false, "UI_ZeD_Fish_HelpCast")
        btn(b.buttons, "search", "UI_ZeD_Fish_Search", "primary", false, "UI_ZeD_Fish_HelpSearch")
    else
        b.status = st.msg
        if canClear then btn(b.lead, "clear", "UI_ZeD_Fish_ClearLog") end
        if s.bagRod then btn(b.buttons, "equip", "UI_ZeD_Fish_Equip", "primary", false, "UI_ZeD_Fish_HelpEquip") end
    end
    return b
end

--- The band key the controller lands on when the tab opens: the state's main action.
function FT.landId(s)
    local st = s and s.state
    if st == "ready" or st == "nobait" then return st == "ready" and "fish:b:cast" or "fish:b:search" end
    if st == "wait" or st == "fight" then return "fish:b:reel" end
    return "fish:wall"
end

-- ---------------------------------------------------------------------------
-- WORDS
-- ---------------------------------------------------------------------------
local MONTHS = {
    "UI_ZeD_Journal_MonthJan", "UI_ZeD_Journal_MonthFeb", "UI_ZeD_Journal_MonthMar", "UI_ZeD_Journal_MonthApr",
    "UI_ZeD_Journal_MonthMay", "UI_ZeD_Journal_MonthJun", "UI_ZeD_Journal_MonthJul", "UI_ZeD_Journal_MonthAug",
    "UI_ZeD_Journal_MonthSep", "UI_ZeD_Journal_MonthOct", "UI_ZeD_Journal_MonthNov", "UI_ZeD_Journal_MonthDec",
}
local function two(n) n = math.floor(n or 0); return (n < 10 and "0" or "") .. tostring(n) end
--- A record's clock time, "05:41".
function FT.hhmm(e) return two(e.hr) .. ":" .. two(e.mn) end
--- A record's day, "Jul 26".
function FT.day(e) return tr("UI_ZeD_Fish_Day", tr(MONTHS[(e.mo or 0) + 1] or MONTHS[1]), (e.dy or 0) + 1) end
--- A record's date, "Jul 26, 1993".
function FT.date(e) return tr("UI_ZeD_Fish_Date", tr(MONTHS[(e.mo or 0) + 1] or MONTHS[1]), (e.dy or 0) + 1, e.yr or 1993) end
--- The log's When column: today's catches by the clock, older ones by the day.
function FT.when(e, now)
    if now and e.yr == now.yr and e.mo == now.mo and e.dy == now.dy then return FT.hhmm(e) end
    return FT.day(e)
end
-- the clock time a game hour stamp (world age) fell on, "05:02"
function FT.hhmmAgo(wa)
    local gt = getGameTime()
    local nowWa = gt:getWorldAgeHours()
    local tod = gt:getTimeOfDay() - (nowWa - (wa or nowWa))
    while tod < 0 do tod = tod + 24 end
    -- (in whole minutes, with a hair of slack: a start at 06:10 comes back from the sums a hair under it, 06:09.99)
    local m = math.floor(tod * 60 + 0.001)
    local h = math.floor(m / 60)
    m = m - h * 60
    while h >= 24 do h = h - 24 end
    return two(h) .. ":" .. two(m)
end
local function mmss(ms)
    local sec = math.floor(math.max(0, ms) / 1000)
    local m = math.floor(sec / 60)
    return tostring(m) .. ":" .. two(sec - m * 60)
end

-- ---------------------------------------------------------------------------
-- MEASURE
-- ---------------------------------------------------------------------------
local function wrapH(text, font, w)
    local lines = ZeD.Atoms.wrapText(text or "", font, math.max(1, w))
    return #lines * (ZeD.TM:getFontHeight(font) + px(2)), lines
end

local function factCols(w)
    local lw = math.min(px(150), math.floor(w * 0.36))
    return lw, w - 2 * px(PAD) - lw - px(10)
end

local function measure(L, w, s)
    local T = ZeD.T
    local f1h, f2h = ZeD.TM:getFontHeight(T.fontF1), ZeD.TM:getFontHeight(T.fontF2)
    local y = 0
    for _, it in ipairs(L) do
        local k = it.k
        if k == "head" or k == "fold" then it.h = px(HEAD_H)
        elseif k == "col" then it.h = px(COL_H)
        elseif k == "bait" or k == "log" then it.h = px(ROW_H)
        elseif k == "empty" then
            local hh = wrapH(it.text, T.fontF2, w - 2 * px(PAD))
            it.h = hh + px(14)
        elseif k == "fact" then
            local _, vw = factCols(w)
            local hh, lines = wrapH(it.value .. (it.sub and ("  " .. it.sub) or ""), T.fontF2, vw)
            it.lines = lines
            it.h = math.max(px(KV_H), hh) + px(4)
        elseif k == "rate" then
            local _, vw = factCols(w)
            local hh = f1h + px(4)
            for _, ln in ipairs(it.lines) do
                local lh, lines = wrapH(ln.names, T.fontF2, vw)
                ln.wrapped = lines
                ln.h = math.max(px(KV_H), lh)
                hh = hh + ln.h
            end
            it.h = hh + px(10)
        elseif k == "chips" then
            local cx, rows = px(PAD), 1
            for _, c in ipairs(it.chips) do
                local cw = ZeD.Atoms.tagW and ZeD.Atoms.tagW(c.text, true, KEEP) or (ZeD.TM:MeasureStringX(T.fontF1, c.text) + px(22))
                if cx + cw > w - px(PAD) and cx > px(PAD) then rows = rows + 1; cx = px(PAD) end
                cx = cx + cw + px(4)
            end
            it.h = rows * px(20) + px(10)
        elseif k == "hero" then
            it.h = math.max(px(8) + ZeD.TM:getFontHeight(T.fontF4) + px(6) + 4 * (px(KV_H) + px(3)) + px(8), px(96))
        elseif k == "tension" then
            it.h = px(12) + f1h + px(8) + px(14) + px(6) + f1h + px(8) + f1h + px(4) + px(6) + px(8) + 2 * (f2h + px(4)) + px(8)
        else it.h = px(ROW_H) end
        it.y = y
        y = y + it.h
    end
    return y + px(8)
end

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------
local _fo = {}
-- the mark's options when the controller is on stop `id` in win, else nil. A row with no stop (a log row) has no id:
-- isFocused with no id answers for the whole window, and every log row would wear the mark.
local function focusOf(win, id)
    if id == nil then return nil end
    local Fo = ZeD.Input and ZeD.Input.Focus
    if Fo and Fo.isFocused and Fo.isFocused(win, nil, id) then _fo.win = win; return _fo end
    return nil
end
FT.focusOf = focusOf

local function text(panel, s, x, y, c, font)
    panel:drawText(s, x, y, c.r, c.g, c.b, c.a or 1, font)
end
local function textR(panel, s, rx, y, c, font)
    text(panel, s, rx - ZeD.TM:MeasureStringX(font, s), y, c, font)
end
local function cut(s, font, w) return ZeD.Atoms.truncateText(s or "", font, math.max(0, w)) end

local TONES = { acc = "accent", good = "positive", bad = "danger", norm = "textDim", dim = "textDim" }

local function drawHero(panel, s, x, y, w)
    local T, A = ZeD.T, ZeD.Atoms
    local tm = ZeD.TM
    local f1, f2, f3, f4 = T.fontF1, T.fontF2, T.fontF3, T.fontF4
    local picW, skW = px(PIC_W), px(SKILL_W)
    local box = px(44)
    local bx, by = x + math.floor((picW - box) / 2), y + px(10)
    ZeD.Surface.fill(panel, bx, by, box, box, "surf3")
    A.frame(panel, bx, by, box, box, T.borderS)
    local rod = s.rod or s.bagRod
    local tex = rod and safe(function() return rod:getTex() end, nil)
    if tex then panel:drawTextureScaledAspect(tex, bx + px(6), by + px(6), box - px(12), box - px(12), rod == s.rod and 1 or 0.45, 1, 1, 1) end
    -- the rod as the game names it ("Fishing Rod with Worm"), then its parts
    local ix = x + picW
    local iw = w - picW - skW - px(10)
    local name = rod and rod:getName() or tr("UI_ZeD_Fish_NoRod")
    text(panel, cut(name, f4, iw), ix, y + px(8), T.text, f4)
    local ry = y + px(8) + tm:getFontHeight(f4) + px(6)
    local labW = px(44)
    local vx = ix + labW + px(8)
    local function kv(label, i)
        local yy = ry + (i - 1) * (px(KV_H) + px(3))
        text(panel, label, ix, yy + math.floor((px(KV_H) - tm:getFontHeight(f3)) / 2), T.textDim, f3)
        return yy
    end
    local fy = math.floor((px(KV_H) - tm:getFontHeight(f2)) / 2)
    -- Rod: its condition
    local yy = kv(tr("UI_ZeD_Fish_Rod"), 1)
    if rod then
        local pc = safe(function() return rod:getCondition() / math.max(1, rod:getConditionMax()) end, 1)
        A.drawFillBar(panel, vx, yy + math.floor((px(KV_H) - T.fillBarH) / 2), px(64), pc, true, nil, nil, tr("UI_ZeD_Fish_Rod"))
        text(panel, tostring(math.floor(pc * 100 + 0.5)) .. "%", vx + px(70), yy + fy, T.text, f3)
    end
    -- Line: its kind and wear
    yy = kv(tr("UI_ZeD_Fish_Line"), 2)
    local tk = rod and Log.tackle(rod)
    if tk then
        local ln = itemName(tk.line)
        local lw = math.min(tm:MeasureStringX(f2, ln), iw - labW - px(120))
        text(panel, cut(ln, f2, lw), vx, yy + fy, T.text, f2)
        local bx2 = vx + lw + px(8)
        A.drawFillBar(panel, bx2, yy + math.floor((px(KV_H) - T.fillBarH) / 2), px(64), tk.cond, true, nil, nil, tr("UI_ZeD_Fish_Line"))
        text(panel, tostring(math.floor(math.max(0, tk.cond) * 100 + 0.5)) .. "%", bx2 + px(70), yy + fy, T.text, f3)
    end
    yy = kv(tr("UI_ZeD_Fish_Hook"), 3)
    if tk then text(panel, cut(tk.hook and itemName(tk.hook) or tr("UI_ZeD_Fish_NoHook"), f2, iw - labW - px(8)), vx, yy + fy, tk.hook and T.text or T.textDim, f2) end
    -- Bait: on the hook, and how many more are in the bags
    yy = kv(tr("UI_ZeD_Fish_Bait"), 4)
    if rod then
        if s.onHook then
            local n = 0
            for _, b in ipairs(s.baits) do if b.type == s.onHook then n = b.n end end
            local nm = itemName(s.onHook)
            text(panel, cut(nm, f2, iw - labW - px(8)), vx, yy + fy, T.text, f2)
            local sub = Fishing and Fishing.IsArtificalLure and Fishing.IsArtificalLure(s.onHook) and tr("UI_ZeD_Fish_RarelyLost") or tr("UI_ZeD_Fish_InBags", n)
            local sx = vx + tm:MeasureStringX(f2, nm) + px(8)
            text(panel, cut(sub, f3, x + w - skW - px(4) - sx), sx, yy + math.floor((px(KV_H) - tm:getFontHeight(f3)) / 2), T.textDim, f3)
        else
            A.drawStatusDot(panel, vx, yy + math.floor((px(KV_H) - px(7)) / 2), T.danger, px(7))
            text(panel, cut(tr("UI_ZeD_Fish_NoneOnHook"), f2, iw - labW - px(24)), vx + px(12), yy + fy, T.danger, f2)
        end
    end
    -- the skill: level, its ten segments, the way to the next
    local sx = x + w - skW
    A.drawDividerV(panel, sx, y, s.heroH or px(96))
    local cx = sx + px(10)
    text(panel, ZeD.textCase(getText("IGUI_perks_Fishing")), cx, y + px(8), T.textHead, f1)
    local ly = y + px(8) + tm:getFontHeight(f1) + px(5)
    text(panel, tostring(s.lv), cx, ly, T.accentText or T.accent, f4)
    text(panel, tr("UI_ZeD_Fish_OfTen"), cx + tm:MeasureStringX(f4, tostring(s.lv)) + px(4), ly + tm:getFontHeight(f4) - tm:getFontHeight(f3), T.textDim, f3)
    local py = ly + tm:getFontHeight(f4) + px(5)
    A.drawSegFill(panel, cx, py, skW - px(20), px(7), 10, s.lv, T.accent)
    if s.lv < 10 then
        text(panel, cut(tr("UI_ZeD_Fish_XpTo", math.floor(s.xpPct * 100), s.lv + 1), f3, skW - px(12)), cx, py + px(12), T.textDim, f3)
    end
end

local function drawTension(panel, s, x, y, w)
    local T, A = ZeD.T, ZeD.Atoms
    local tm = ZeD.TM
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local f1h = tm:getFontHeight(f1)
    local lx, lw = x + px(PAD), w - 2 * px(PAD)
    local t = s.tension or 0
    local v = math.max(0, math.min(1, t))
    local col = (v >= 0.8) and T.danger or ((v >= 0.5) and T.warning or T.accent)
    local cy = y + px(10)
    text(panel, ZeD.textCase(tr("UI_ZeD_Fish_Tension")), lx, cy, T.textHead, f1)
    textR(panel, (t < 0) and tr("UI_ZeD_Fish_TSlack") or (tostring(math.floor(v * 100 + 0.5)) .. "%"), lx + lw, cy, col, f3)
    cy = cy + f1h + px(8)
    local bh = px(14)
    ZeD.Surface.fill(panel, lx, cy, lw, bh, "surf3")
    A.frame(panel, lx, cy, lw, bh, T.borderS)
    if v > 0 then panel:drawRect(lx + 1, cy + 1, math.floor((lw - 2) * v), bh - 2, 1, col.r, col.g, col.b) end
    local mk = lx + math.floor(lw * 0.8)
    panel:drawRect(mk, cy - px(3), math.max(1, T.hair), bh + px(6), 1, T.text.r, T.text.g, T.text.b)
    cy = cy + bh + px(6)
    -- the scale's words: where it is slack, tight, where the line wears and where it snaps
    text(panel, tr("UI_ZeD_Fish_TSlack"), lx, cy, T.textDim, f1)
    local tw = tm:MeasureStringX(f1, tr("UI_ZeD_Fish_TTight"))
    text(panel, tr("UI_ZeD_Fish_TTight"), lx + math.floor(lw * 0.45) - math.floor(tw / 2), cy, T.textDim, f1)
    local ww = tm:MeasureStringX(f1, tr("UI_ZeD_Fish_TWears"))
    text(panel, tr("UI_ZeD_Fish_TWears"), math.min(mk - math.floor(ww / 2), lx + lw - ww - tm:MeasureStringX(f1, tr("UI_ZeD_Fish_TSnaps")) - px(8)), cy, T.textDim, f1)
    textR(panel, tr("UI_ZeD_Fish_TSnaps"), lx + lw, cy, T.textDim, f1)
    cy = cy + f1h + px(8)
    -- how long it has been held past the wear mark, against what the rod and Fishing allow (FishingRod:updateLine)
    text(panel, ZeD.textCase(tr("UI_ZeD_Fish_Held")), lx, cy, T.textHead, f1)
    textR(panel, tostring(math.floor((s.held or 0) * 100 + 0.5)) .. "%", lx + lw, cy, T.text, f3)
    cy = cy + f1h + px(4)
    ZeD.Surface.fill(panel, lx, cy, lw, px(6), "surf3")
    if (s.held or 0) > 0 then panel:drawRect(lx, cy, math.floor(lw * s.held), px(6), 1, T.danger.r, T.danger.g, T.danger.b) end
    cy = cy + px(6) + px(8)
    local kw = math.max(tm:MeasureStringX(f3, tr("UI_ZeD_Fish_FishLab")), tm:MeasureStringX(f3, tr("UI_ZeD_Fish_Line"))) + px(8)
    text(panel, tr("UI_ZeD_Fish_FishLab"), lx, cy, T.textDim, f3)
    text(panel, cut(tr("UI_ZeD_Fish_Unknown"), f2, lw - kw), lx + kw, cy, T.text, f2)
    cy = cy + tm:getFontHeight(f2) + px(4)
    local tk = s.tackle
    text(panel, tr("UI_ZeD_Fish_Line"), lx, cy, T.textDim, f3)
    text(panel, cut(tr("UI_ZeD_Fish_LineWear", tk and math.floor(math.max(0, tk.cond) * 100 + 0.5) or 0), f2, lw - kw), lx + kw, cy, T.text, f2)
    A.drawDividerH(panel, x, y + s.tensionH - T.hair, w, false)
end

local function drawRow(panel, win, st, it, x, dy, cw, mx, my)
    local T, A = ZeD.T, ZeD.Atoms
    local tm = ZeD.TM
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local h = it.h
    local hov = mx ~= nil and mx >= x and mx < x + cw and my >= dy and my < dy + h
    local tc, dc = T.text, T.textDim
    if it.k == "bait" and it.sel then
        local a = T.accent
        panel:drawRect(x, dy, cw, h, 1, a.r, a.g, a.b)
        tc = T.textOnAccent or T.base
        dc = tc
    elseif hov and it.k == "bait" and not it.locked then
        local hv = T.hover
        panel:drawRect(x, dy, cw, h, hv.a or 0.1, hv.r, hv.g, hv.b)
    end
    local f = focusOf(win, it.id)
    if f and ZeD.Focus and ZeD.Focus.mark and ZeD.Focus.mark(panel, x, dy, cw, h, f) and not it.sel then tc = T.textOnFocus end
    local fy2 = dy + math.floor((h - tm:getFontHeight(f2)) / 2)
    local fy3 = dy + math.floor((h - tm:getFontHeight(f3)) / 2)
    local lx, rx = x + px(PAD), x + cw - px(PAD)
    local isz = px(16)
    if it.k == "bait" then
        local r = it.r
        local ic = iconOf(r.type)
        if ic then panel:drawTextureScaledAspect(ic, lx, dy + math.floor((h - isz) / 2), isz, isz, 1, 1, 1, 1) end
        local cntS = tostring(r.n)
        textR(panel, cntS, rx, fy3, tc, f3)
        local right = rx - px(44)
        if r.where then
            local ws = cut(r.where, f3, px(110))
            textR(panel, ws, right, fy3, dc, f3)
            right = right - tm:MeasureStringX(f3, ws) - px(8)
        end
        local tags = {}
        if it.on then tags[#tags + 1] = tr("UI_ZeD_Fish_OnHook") end
        if r.lure then tags[#tags + 1] = tr("UI_ZeD_Fish_Lure") end
        for i = #tags, 1, -1 do
            local tw = A.tagW and A.tagW(tags[i], false) or (tm:MeasureStringX(f1, tags[i]) + px(12))
            if right - tw > lx + px(90) then
                right = right - tw
                ZeD.Molecules.drawTag(panel, right, dy + math.floor((h - px(16)) / 2), tags[i], nil, { textColor = tc, frameColor = it.sel and tc or nil })
                right = right - px(6)
            end
        end
        local nx = lx + isz + px(8)
        text(panel, cut(r.name, f2, right - nx), nx, fy2, tc, f2)
        if hov and not it.locked and ZeD.Help then ZeD.Help.set(panel, tr("UI_ZeD_Fish_HelpPick", r.name)) end
    else
        local e = it.e
        text(panel, FT.when(e, st._now), lx, fy3, dc, f3)
        local ix = lx + px(48)
        local ic = e.k ~= "gone" and iconOf(e.type) or nil
        if ic then panel:drawTextureScaledAspect(ic, ix, dy + math.floor((h - isz) / 2), isz, isz, 1, 1, 1, 1) end
        local wtS = (e.k == "gone") and "-" or string.format("%.2f", e.wt or 0)
        textR(panel, wtS, rx, fy3, tc, f3)
        local bx = rx - px(44) - px(76)
        text(panel, cut(e.bait and itemName(e.bait) or "-", f3, px(70)), bx, fy3, dc, f3)
        local nx = ix + isz + px(8)
        local right = bx - px(8)
        if e.k == "junk" then
            local jt = tr("UI_ZeD_Fish_Junk")
            local tw = A.tagW and A.tagW(jt, false) or (tm:MeasureStringX(f1, jt) + px(12))
            right = right - tw
            ZeD.Molecules.drawTag(panel, right, dy + math.floor((h - px(16)) / 2), jt, nil, { textColor = T.textDim })
            right = right - px(6)
        end
        local name = (e.k == "gone") and getText("IGUI_Fishing_NoCatch") or (e.name or "")
        text(panel, cut(name, f2, right - nx), nx, fy2, (e.k == "gone") and dc or tc, f2)
    end
    if it.k == "bait" and not it.locked then st.hits[#st.hits + 1] = { x = x, y = dy, w = cw, h = h, item = it } end
end

local function drawItem(panel, win, st, s, it, x, dy, cw, mx, my)
    local T, M, A = ZeD.T, ZeD.Molecules, ZeD.Atoms
    local tm = ZeD.TM
    local pad = px(PAD)
    local k = it.k
    if k == "head" then
        M.drawSectionHeader(panel, x + pad, dy, cw - pad, it.text, nil, true, false, nil, nil, pad, it.h, true)
        local right = x + cw - pad
        if it.wall then
            -- the Trophy wall key, in the log's head: it belongs with the log, and the band holds the fishing verbs
            local label = tr("UI_ZeD_Fish_WallBtn", it.count or 0)
            local bw = M.buttonW(label)
            local bh = T.buttonH - px(4)
            local bx, by = right - bw, dy + math.floor((it.h - bh) / 2)
            local hov = mx ~= nil and mx >= bx and mx < bx + bw and my >= by and my < by + bh
            M.drawButton(panel, bx, by, bw, bh, label, "default", hov and isMouseButtonDown(0), nil,
                { hover = hov, compact = false, focus = focusOf(win, "fish:wall"), help = tr("UI_ZeD_Fish_HelpWall"), win = win })
            st.hits[#st.hits + 1] = { x = bx, y = by, w = bw, h = bh, btn = "wall" }
            right = bx - px(8)
        end
        if it.right then
            local f1 = T.fontF1
            textR(panel, it.right, right, dy + math.floor((it.h - tm:getFontHeight(f1)) / 2), T.textDim, f1)
        end
    elseif k == "fold" then
        local hov = mx ~= nil and my >= dy and my < dy + it.h
        local f = focusOf(win, "fish:fold")
        M.drawSectionHeader(panel, x + pad, dy, cw - pad, it.text, nil, it.open, hov, nil, false, pad, it.h, false, f and { focus = f } or nil)
        if hov and ZeD.Help then ZeD.Help.set(panel, tr("UI_ZeD_Fish_HelpMore")) end
        textR(panel, it.right, x + cw - pad, dy + math.floor((it.h - tm:getFontHeight(T.fontF1)) / 2), T.textDim, T.fontF1)
        st.hits[#st.hits + 1] = { x = x, y = dy, w = cw, h = it.h, fold = true }
    elseif k == "col" then
        local f5 = T.fontF5
        local fy = dy + math.floor((it.h - tm:getFontHeight(f5)) / 2)
        local lx, rx = x + pad, x + cw - pad
        if it.cols == "bait" then
            text(panel, ZeD.textCase(tr("UI_ZeD_Fish_Bait")), lx + px(24), fy, T.textDim, f5)
            textR(panel, ZeD.textCase(tr("UI_ZeD_Fish_ColCount")), rx, fy, T.textDim, f5)
        else
            text(panel, ZeD.textCase(tr("UI_ZeD_Fish_ColWhen")), lx, fy, T.textDim, f5)
            text(panel, ZeD.textCase(tr("UI_ZeD_Fish_ColCatch")), lx + px(72), fy, T.textDim, f5)
            text(panel, ZeD.textCase(tr("UI_ZeD_Fish_Bait")), rx - px(44) - px(76), fy, T.textDim, f5)
            textR(panel, ZeD.textCase(tr("UI_ZeD_Inv_ColWt")), rx, fy, T.textDim, f5)
        end
    elseif k == "bait" or k == "log" then
        drawRow(panel, win, st, it, x, dy, cw, mx, my)
    elseif k == "empty" then
        local f2 = T.fontF2
        local _, lines = wrapH(it.text, f2, cw - 2 * pad)
        for i, ln in ipairs(lines) do
            text(panel, ln, x + pad, dy + px(7) + (i - 1) * (tm:getFontHeight(f2) + px(2)), it.bad and T.danger or T.textDim, f2)
        end
    elseif k == "fact" then
        local lw = factCols(cw)
        local f2, f3 = T.fontF2, T.fontF3
        text(panel, cut(it.label, f3, lw), x + pad, dy + px(2) + math.floor((px(KV_H) - tm:getFontHeight(f3)) / 2), T.textDim, f3)
        local vx = x + pad + lw + px(10)
        for i, ln in ipairs(it.lines or {}) do
            text(panel, ln, vx, dy + px(2) + (i - 1) * (tm:getFontHeight(f2) + px(2)), T.text, f2)
        end
    elseif k == "rate" then
        local lw = factCols(cw)
        local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
        ZeD.Surface.fill(panel, x, dy, cw, it.h, "surf1")
        local cy = dy + px(6)
        text(panel, cut(it.cap, f1, cw - 2 * pad), x + pad, cy, T.textHead, f1)
        cy = cy + tm:getFontHeight(f1) + px(4)
        local vx = x + pad + lw + px(10)
        for _, ln in ipairs(it.lines) do
            text(panel, cut(ln.grade, f3, lw), x + pad, cy, T.textDim, f3)
            for i, s2 in ipairs(ln.wrapped or {}) do
                text(panel, s2, vx, cy + (i - 1) * (tm:getFontHeight(f2) + px(2)), T.text, f2)
            end
            cy = cy + ln.h
        end
    elseif k == "chips" then
        local cx, cy = x + pad, dy + px(5)
        for _, c in ipairs(it.chips) do
            local cw2 = A.tagW and A.tagW(c.text, true, KEEP) or (tm:MeasureStringX(T.fontF1, c.text) + px(22))
            if cx + cw2 > x + cw - pad and cx > x + pad then cx = x + pad; cy = cy + px(20) end
            local col = T[TONES[c.tone] or "textDim"] or T.textDim
            M.drawTag(panel, cx, cy, c.text, col, { keepCase = true, hollow = (c.tone == "unknown") or nil })
            cx = cx + cw2 + px(4)
        end
        A.drawDividerH(panel, x, dy + it.h - T.hair, cw, false)
    elseif k == "hero" then
        s.heroH = it.h
        drawHero(panel, s, x, dy, cw)
        A.drawDividerH(panel, x, dy + it.h - T.hair, cw, false)
    elseif k == "tension" then
        s.tensionH = it.h
        drawTension(panel, s, x, dy, cw)
    end
end

-- the header strip: the state on the left, where the water or the bobber is on the right
local STATE_WORDS = { ready = "UI_ZeD_Fish_StReady", wait = "UI_ZeD_Fish_StWait", fight = "UI_ZeD_Fish_StFight",
                      nobait = "UI_ZeD_Fish_StNoBait", norod = "UI_ZeD_Fish_StNoRod" }
local function drawHeader(panel, s, x, y, w)
    local T, M, A = ZeD.T, ZeD.Molecules, ZeD.Atoms
    local tm = ZeD.TM
    local h = M.getTabHeaderH()
    M.drawTabHeader(panel, x, y, w, "", false, false, true)
    local bad = s.state == "fight" or s.state == "nobait"
    local c = bad and T.danger or ((s.state == "norod") and T.textDim or T.accent)
    local f = T.fontF4
    local lx = x + M.getTabPad()
    A.drawStatusDot(panel, lx, y + math.floor((h - px(7)) / 2), c, px(7))
    local words = tr(STATE_WORDS[s.state] or STATE_WORDS.norod)
    text(panel, words, lx + px(13), y + math.floor((h - tm:getFontHeight(f)) / 2), bad and T.danger or T.text, f)
    local right
    if s.bobber then right = tr("UI_ZeD_Fish_BobberAt", s.bobber.d, tr(s.bobber.dir))
    elseif s.water then
        right = (s.water.d <= 1) and tr("UI_ZeD_Fish_WaterNear") or tr("UI_ZeD_Fish_WaterAt", s.water.d, tr(s.water.dir))
    end
    if right then
        local f3 = T.fontF3
        local room = x + w - M.getTabPad() - (lx + px(13) + tm:MeasureStringX(f, words) + px(12))
        textR(panel, cut(right, f3, room), x + w - M.getTabPad(), y + math.floor((h - tm:getFontHeight(f3)) / 2), T.textDim, f3)
    end
    return h
end

-- the strip under the header while the line is out: waiting, or reeling a fish in, and the clock
local function drawLineBand(panel, st, s, x, y, w)
    local T, A = ZeD.T, ZeD.Atoms
    local tm = ZeD.TM
    local h = px(BAND2_H)
    local fight = s.state == "fight"
    local c = fight and T.danger or T.accent
    ZeD.Surface.fill(panel, x, y, w, h, "surf1")
    panel:drawRect(x, y, w, h, 0.22, c.r, c.g, c.b)
    A.drawDividerH(panel, x, y + h - T.hair, w, false)
    local f1 = T.fontF1
    local ty = y + math.floor((h - tm:getFontHeight(f1)) / 2)
    A.drawStatusDot(panel, x + px(PAD), y + math.floor((h - px(7)) / 2), c, px(7))
    text(panel, ZeD.textCase(tr(fight and "UI_ZeD_Fish_Reeling" or "UI_ZeD_Fish_Waiting")), x + px(PAD) + px(13), ty, fight and T.danger or (T.accentText or T.accent), f1)
    local since = fight and st.fishAt or Log.castAt
    local clock = since and mmss(nowMs() - since) or ""
    if not fight then
        local t = s.tension or 0
        clock = clock .. " | " .. tr((t < 0) and "UI_ZeD_Fish_TSlack" or "UI_ZeD_Fish_TTight")
    end
    textR(panel, clock, x + w - px(PAD), ty, T.text, T.fontF3)
    return h
end

local function state(win)
    local st = win._fishTab
    if not st then
        st = { scroll = ZeD_ScrollbarState:new(), items = {}, hits = {}, fold = false }
        win._fishTab = st
    end
    return st
end
FT.state = state

-- the controller's focus kept in view; returns nothing
local function follow(win, scroll, maxOff, sh)
    local Fo = ZeD.Input and ZeD.Input.Focus
    local fe = Fo and Fo.getFocusedWindow and Fo.getFocusedWindow() == win and Fo.getFocusedElement and Fo.getFocusedElement(win)
    if fe and fe.fish and fe.cy and maxOff > 0 then
        local off0 = math.floor(scroll.scrollPos * maxOff)
        local off1 = off0
        if fe.cy < off0 then off1 = fe.cy elseif fe.cy + (fe.h or 0) > off0 + sh then off1 = fe.cy + (fe.h or 0) - sh end
        if off1 ~= off0 then scroll:setScrollPos(math.max(0, math.min(1, off1 / maxOff))) end
    end
end
FT.follow = follow

local HELP = { wait = "UI_ZeD_Fish_TipWait", fight = "UI_ZeD_Fish_TipFight" }

local _bandSpec = { buttons = {}, lead = {} }
function FT.render(panel, win, x, y, w, h)
    local T, M = ZeD.T, ZeD.Molecules
    local st = state(win)
    local p = win._playerObj or getPlayer()
    if not p then return end
    if st.msg and nowMs() - (st.msgAt or 0) > 6000 then st.msg = nil end
    if st.wall then
        ZeD.FishingWall.render(panel, win, st, x, y, w, h)
        return
    end
    local s = FT.snap(p, st)
    st.s = s
    -- the Clear log question belongs to the state it was asked in: a cast made with the game's own keys moves the line
    -- on, and the band's fishing keys come back (the question would hide Stop, Reel in and Let out line)
    if st.ask and s.state ~= st.askIn then st.ask = nil end
    st._now = Log.clock()
    if s.state == "fight" then st.fishAt = st.fishAt or nowMs() else st.fishAt = nil end
    -- the state's standing help line (a pointed control's own help, set later this frame, wins)
    local helpKey = HELP[s.state]
    if s.state == "ready" and s.sel and s.sel ~= s.onHook then
        if ZeD.Help then ZeD.Help.set(panel, tr(s.onHook and "UI_ZeD_Fish_TipChange" or "UI_ZeD_Fish_TipAdd", itemName(s.sel), s.onHook and itemName(s.onHook) or "")) end
    elseif helpKey and ZeD.Help then ZeD.Help.set(panel, tr(helpKey)) end
    local L = FT.build(s, st)
    st.items = L
    local headH = drawHeader(panel, s, x, y, w)
    if s.state == "wait" or s.state == "fight" then headH = headH + drawLineBand(panel, st, s, x, y + headH, w) end
    local bandH = M.bandH()
    local sy, sh = y + headH, h - headH - bandH
    local listH = measure(L, w - T.sp.scrollbarW, s)
    local scroll = st.scroll
    local needs = listH > sh
    scroll.visible = needs
    local maxOff = math.max(0, listH - sh)
    if needs then
        scroll.x, scroll.y, scroll.width, scroll.height = x + w - T.sp.scrollbarW, sy, T.sp.scrollbarW, sh
        scroll:setBarSize(sh / math.max(1, listH))
        follow(win, scroll, maxOff, sh)
    else
        scroll:setScrollPos(0)
    end
    local off = needs and math.floor(scroll.scrollPos * maxOff) or 0
    st.off, st.sy, st.sh, st.x, st.w, st.maxOff = off, sy, sh, x, w, maxOff
    local Fo = ZeD.Input and ZeD.Input.Focus
    local mx, my = panel:getMouseX(), panel:getMouseY()
    if not (mx >= x and mx < x + w and my >= sy and my < sy + sh) or (Fo and Fo.cuesVisible and Fo.cuesVisible()) then mx, my = nil, nil end
    local cw = w - (needs and T.sp.scrollbarW or 0)
    st.cw = cw
    st.hits = {}
    for i, it in ipairs(L) do
        it.id = (it.k == "bait" and ("fish:bait:" .. tostring(it.r.type))) or (it.k == "fold" and "fish:fold") or nil
        if i == 1 then it.first = true end
    end
    panel:setStencilRect(x, sy, w, sh)
    for _, it in ipairs(L) do
        local dy = sy + it.y - off
        if dy + it.h >= sy and dy <= sy + sh then drawItem(panel, win, st, s, it, x, dy, cw, mx, my) end
    end
    panel:clearStencilRect()
    -- (PZ clips do not nest: the list's rect, once cleared, stays shut to what draws next, so the whole tab is opened
    -- again for the scrollbar and the band, and that clip comes off at the end)
    panel:setStencilRect(0, 0, panel:getWidth(), panel:getHeight())
    if needs then
        scroll:draw(panel)
        -- the controller on the scroll bar (its stop scrolls the list a row a press): the mark goes on the bar
        local f = focusOf(win, "fish:scroll")
        if f and ZeD.Focus and ZeD.Focus.mark then ZeD.Focus.mark(panel, scroll.x, scroll.y, scroll.width, scroll.height, f) end
    end
    FT.drawBand(panel, win, st, s, x, y + h - bandH, w)
    panel:clearStencilRect()
end

--- The band at the foot (status, the lead keys, the state's verbs); the rects go in st.band.
function FT.drawBand(panel, win, st, s, x, y, w)
    local spec = FT.band(s, st)
    local function prep(list)
        for _, b in ipairs(list) do
            b.focus = focusOf(win, "fish:b:" .. b.id)
            if b.focus and b.focus.win == nil then b.focus.win = win end
        end
    end
    prep(spec.buttons)
    prep(spec.lead)
    _bandSpec.buttons, _bandSpec.lead, _bandSpec.win = spec.buttons, spec.lead, win
    _bandSpec.question = spec.question
    _bandSpec.status = (spec.status and spec.status ~= "") and { text = spec.status } or nil
    local _, out = ZeD.Molecules.drawBand(panel, x, y, w, _bandSpec)
    st.band = {}
    for i, r in ipairs(out.buttons) do st.band[#st.band + 1] = { x = r.x, y = r.y, w = r.w, h = r.h, b = spec.buttons[i] } end
    for i, r in ipairs(out.lead) do st.band[#st.band + 1] = { x = r.x, y = r.y, w = r.w, h = r.h, b = spec.lead[i] } end
    -- a held press on Reel in / Let out line keeps the pull going while the button stays down
    if isMouseButtonDown and (isMouseButtonDown(0) or isMouseButtonDown(1)) then
        local mx, my = panel:getMouseX(), panel:getMouseY()
        for _, r in ipairs(st.band) do
            if (r.b.id == "reel" or r.b.id == "release") and mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h then
                Log.pull(r.b.id, 250)
            end
        end
    end
    -- the controller's A held on the same keys, the same way. FocusManager fires a hold once (onHoldActivate, which
    -- set st.padHold); the pull goes on while A stays down and the focus stays on that key.
    if st.padHold then
        local Fo = ZeD.Input and ZeD.Input.Focus
        local fe = Fo and Fo.getFocusedWindow and Fo.getFocusedWindow() == win and Fo.getFocusedElement and Fo.getFocusedElement(win)
        if fe and fe.id == st.padHoldId and Fo.holdingA and Fo.holdingA(win) then
            Log.pull(st.padHold, 250)
        else
            st.padHold, st.padHoldId = nil, nil
        end
    end
end

-- ---------------------------------------------------------------------------
-- WHAT THE KEYS DO
-- ---------------------------------------------------------------------------
local function sound(n) pcall(function() getSoundManager():playUISound(n or "UIActivateButton") end) end
local function say(st, key, ...)
    st.msg = tr(key, ...)
    st.msgAt = nowMs()
end

--- Ends fishing as the game's stop key does (FishingManager:update): the line wears unless only aiming,
--- the state goes back to None and the character's fishing animation is told to finish.
function FT.stopFishing(p)
    local m = Log.manager(p)
    if not m then return false end
    if m.state ~= m.states["Idle"] and m.fishingRod ~= nil then m.fishingRod:damageLine() end
    m:changeState("None")
    p:setVariable("FishingFinished", true)
    return true
end

local DO = {}
function DO.cast(p, st, s)
    local m = Log.manager(p)
    -- the game casts from its Idle state (rod aimed at water within reach), as its own cast key does
    if m and m.state == m.states["Idle"] and Fishing.Utils.isAccessibleAimDist(p) then
        m:changeState("Cast")
    else
        say(st, "UI_ZeD_Fish_AimFirst")
    end
end
function DO.bait(p, st, s)
    local rod, pn = s.rod, p:getPlayerNum()
    if not (rod and s.sel) then return end
    local want = nil
    -- (the bags as they are now, not the list's half-second copy: the item handed to the game has to be there)
    for _, b in ipairs(Log.baits(p, true)) do if b.type == s.sel then want = b end end
    -- the picked bait left the bags since the list was read: the hook keeps what it has (live bait taken off is lost)
    if s.sel ~= s.onHook and not want then return end
    -- the game's own Add Bait and Remove Bait (its rod menu's functions and timed actions)
    if s.onHook then ISInventoryPaneContextMenu.removeLure(pn, rod) end
    if want and s.sel ~= s.onHook then ISInventoryPaneContextMenu.addLure(pn, rod, want.item) end
end
function DO.stop(p) FT.stopFishing(p) end
function DO.reel() Log.pull("reel", 600) end
function DO.release() Log.pull("release", 600) end
function DO.search(p)
    -- the Foraging tab, its focus set to the game's Fish Bait category (the search window ZeD keeps hidden holds it)
    local sw = ISSearchWindow and ISSearchWindow.players and ISSearchWindow.players[p]
    if not sw and ISSearchWindow and ISSearchWindow.createUI then
        pcall(ISSearchWindow.createUI, p:getPlayerNum())
        sw = ISSearchWindow.players[p]
    end
    if sw then sw.searchFocusCategory = "FishBait" end
    ZeD_WorldWindow.openTab(p:getPlayerNum(), "forage")
end
function DO.equip(p)
    local rod = Log.rodInBags(p, true)
    if not rod then return end
    ISInventoryPaneContextMenu.transferIfNeeded(p, rod)
    ISInventoryPaneContextMenu.equipWeapon(rod, true, rod:isTwoHandWeapon(), p:getPlayerNum())
end
function DO.clear(p, st, s)
    st.ask = "clear"
    st.askIn = s and s.state   -- (FT.render takes the question down once the state moves on)
end
function DO.cancel(p, st) st.ask = nil end
function DO.clearyes(p, st)
    st.ask = nil
    Log.clearLog(p)
end
function DO.wall(p, st, s, win) ZeD.FishingWall.open(win, st) end
FT.DO = DO

--- Runs band key id (or the wall key) for the tab in win.
function FT.press(win, id)
    local st = state(win)
    local p = win._playerObj or getPlayer()
    if not (p and DO[id]) then return end
    sound()
    local ok, err = pcall(DO[id], p, st, st.s or FT.snap(p, st), win)
    if not ok and ZeD.logOnce then ZeD.logOnce("fishing tab " .. id, err) end
end

local function pick(st, it)
    st.sel = it.r.type
    sound("UISelectListItem")
end

function FT.onClick(win, x, y)
    local st = state(win)
    if st.wall then return ZeD.FishingWall.onClick(win, st, x, y) end
    for _, r in ipairs(st.band or {}) do
        if x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h then
            if not r.b.disabled then FT.press(win, r.b.id) end
            return true
        end
    end
    local sc = st.scroll
    if sc.visible and x >= sc.x and x < sc.x + sc.width and y >= sc.y and y < sc.y + sc.height then
        sc:handleMouseDown(y - sc.y)
        return true
    end
    if y < (st.sy or 0) or y >= (st.sy or 0) + (st.sh or 0) then return true end
    for _, hz in ipairs(st.hits or {}) do
        if x >= hz.x and x < hz.x + hz.w and y >= hz.y and y < hz.y + hz.h then
            if hz.btn then FT.press(win, hz.btn)
            elseif hz.fold then st.fold = not st.fold; sound()
            elseif hz.item then pick(st, hz.item) end
            return true
        end
    end
    return true
end

-- THE CONTROLLER IN THE LIST. Up and Down walk the list's stops in the list's own order, and follow() scrolls
-- each one in. A spatial pick would not do: a stop scrolled out of sight below the list sits under the band on
-- screen, so Down from the stop above it landed on the band and the rest of the list was out of reach. Past the
-- last stop Down goes on to the scroll bar while more of the list lies below; there Up and Down move the list a
-- row a press. At the bar's bottom end Down is the window's own move (to the band); at its top end Up goes back
-- to the lowest of the list's stops in view (the bar's rect sits below them all, so the window's move would find
-- nothing above). Left and Right, and Up from the first stop, are always the window's.
local FOCUS_ZONE = "worldTabContent"   -- (the World window's zone for a tab's stops)
local function isScrollStop(e) return e.id == "fish:scroll" end
-- the focus onto the first stop pred takes, with the tick a D-pad move makes (focusWhere itself is silent)
local function focusStop(w, pred)
    local Fo = ZeD.Input and ZeD.Input.Focus
    if not (Fo and Fo.focusWhere and Fo.focusWhere(w, FOCUS_ZONE, pred)) then return false end
    sound("UISelectListItem")
    return true
end
local function focusListStop(w, i) return focusStop(w, function(e) return e.listIdx == i end) end
local function listDir(w, el, dir)
    if dir ~= "up" and dir ~= "down" then return false end
    local st = w._fishTab
    if not (st and el.listIdx) then return false end
    local want = el.listIdx + ((dir == "down") and 1 or -1)
    if want < 1 then return false end
    if want > (st.nList or 0) then
        local sc = st.scroll
        if not (dir == "down" and sc and sc.visible and (sc.scrollPos or 0) < 1) then return false end
        return focusStop(w, isScrollStop)
    end
    return focusListStop(w, want)
end
local function scrollDir(w, el, dir)
    local st = w._fishTab
    local sc = st and st.scroll
    if not (sc and sc.visible) or (dir ~= "up" and dir ~= "down") then return false end
    local pos = sc.scrollPos or 0
    if dir == "down" and pos >= 1 then return false end
    if dir == "up" and pos <= 0 then
        -- the top: the lowest list stop wholly in view, else the first (follow() brings it in)
        local n, off, sh = st.nList or 0, st.off or 0, st.sh or 0
        if n == 0 then return false end
        local want = 1
        for i = n, 1, -1 do
            local cy, h = st.listCy[i], st.listH[i]
            if cy and cy >= off and cy + h <= off + sh then want = i; break end
        end
        return focusListStop(w, want)
    end
    local maxOff = st.maxOff or 0
    local step = (maxOff > 0) and (px(ROW_H) / maxOff) or 1
    sc:setScrollPos(pos + ((dir == "down") and step or -step))
    return true
end
-- A held on Reel in / Let out line: the first pull now, then FT.drawBand keeps it going while A stays down
local function holdPull(w, id)
    local st = state(w)
    st.padHold, st.padHoldId = id, "fish:b:" .. id
    FT.press(w, id)
end
-- the help line's words on the scroll bar ("D-pad Scroll", its glyph as the other help lines draw it), made once
local _scrollPrompts = nil
local function scrollPrompts()
    if _scrollPrompts then return _scrollPrompts end
    local Pr, words = ZeD.Prompt, tr("UI_ZeD_Prompt_DPadScroll")
    if not (Pr and Pr.padNote) then return { words } end
    _scrollPrompts = { Pr.padNote(words) }
    return _scrollPrompts
end

--- The controller's stops: the bait rows, the wall key, the fold, the scroll bar, then the band, in reading order.
function FT.buildFocusables(win)
    local st = win._fishTab
    if not st then return {} end
    if st.wall then return ZeD.FishingWall.stops(win, st) end
    local out = {}
    local sy, off, x0, cw = st.sy or 0, st.off or 0, st.x or 0, st.cw or 0
    -- (every stop, in view or not: Up and Down walk them in order and follow() scrolls each in. Where each one
    -- sits in the list is kept for the scroll bar's top end, in two tables the tab keeps)
    local n = 0
    st.listCy, st.listH = st.listCy or {}, st.listH or {}
    local function clip(e)
        n = n + 1
        e.listIdx, e.onDpadDir = n, listDir
        st.listCy[n], st.listH[n] = e.cy, e.h
        out[n] = e
    end
    for _, it in ipairs(st.items or {}) do
        local dy = sy + (it.y or 0) - off
        if it.k == "bait" and not it.locked then
            local item = it
            clip({ x = x0, y = dy, w = cw, h = it.h, cy = it.y, id = it.id or ("fish:bait:" .. tostring(it.r.type)), fish = true,
                   promptA = tr("UI_ZeD_Fish_PromptPick"), onFocus = function() end, onActivate = function() pick(st, item) end })
        elseif it.k == "head" and it.wall then
            local bw = ZeD.Molecules.buttonW(tr("UI_ZeD_Fish_WallBtn", it.count or 0))
            local bh = ZeD.T.buttonH - px(4)
            clip({ x = x0 + cw - px(PAD) - bw, y = dy + math.floor((it.h - bh) / 2), w = bw, h = bh, cy = it.y, id = "fish:wall", fish = true,
                   promptA = tr("UI_ZeD_Fish_PromptWall"), onFocus = function() end, onActivate = function(w) FT.press(w, "wall") end })
        elseif it.k == "fold" then
            clip({ x = x0, y = dy, w = cw, h = it.h, cy = it.y, id = "fish:fold", fish = true, isDisclosure = true,
                   onFocus = function() end, onActivate = function() st.fold = not st.fold; sound() end })
        end
    end
    st.nList = n
    -- the scroll bar, while the list runs past its view (no `fish` mark: follow() leaves the list where it scrolled).
    -- Its rect for the D-pad is the bar below the last stop, a sliver at the bar's foot when that stop is lower: no
    -- stop of the list has the bar above it, so Up from the first stop never lands there. The mark covers the bar.
    local sc = st.scroll
    if sc and sc.visible then
        local last = out[n]
        local top = math.max(sc.y, math.min(last and (last.y + last.h) or sc.y, sc.y + sc.height - 2))
        out[#out + 1] = { x = sc.x, y = top, w = sc.width, h = sc.y + sc.height - top, id = "fish:scroll", isGridScroll = true,
                          extraPrompts = scrollPrompts(), onFocus = function() end, onDpadDir = scrollDir }
    end
    for _, r in ipairs(st.band or {}) do
        local b = r.b
        out[#out + 1] = { x = r.x, y = r.y, w = r.w, h = r.h, id = "fish:b:" .. b.id, isPrimary = b.variant == "primary",
            help = b.help, promptA = b.label, onFocus = function() end,
            onActivate = function(w) if not b.disabled then FT.press(w, b.id) end end,
            onHoldActivate = (b.id == "reel" or b.id == "release") and function(w) holdPull(w, b.id) end or nil }
    end
    return out
end

--- The stops are rebuilt when the list's shape, its scroll or the band changes.
function FT.scrollKey(win)
    local st = win._fishTab
    if not st then return nil end
    if st.wall then return ZeD.FishingWall.key(st) end
    local parts = { tostring(st.off or 0), tostring(st.s and st.s.state), tostring(st.fold), tostring(st.ask) }
    for _, it in ipairs(st.items or {}) do parts[#parts + 1] = it.k end
    for _, r in ipairs(st.band or {}) do parts[#parts + 1] = r.b.id end
    return table.concat(parts, ",")
end

-- ---------------------------------------------------------------------------
-- THE TAB, AND OPENING ITSELF WHEN THE LINE GOES OUT
-- ---------------------------------------------------------------------------
--- The line went out (FishingLog's cast hook): with the World window open, its Fishing tab comes up.
--- With the window shut nothing opens.
function FT.onCast(p)
    if not (ZeD_WorldWindow and ZeD_WorldWindow.isOpen and ZeD_WorldWindow.isOpen()) then return false end
    if ZeD_WorldWindow.isTabShowing and ZeD_WorldWindow.isTabShowing(FT.ID) then return false end
    if not Log.visible(p) then return false end
    return ZeD_WorldWindow.openTab(p:getPlayerNum(), FT.ID) == true
end
local listed = false
for _, fn in ipairs(Log.onCast) do if fn == FT._castFn then listed = true end end
if not listed then
    FT._castFn = function(p) FT.onCast(p) end
    Log.onCast[#Log.onCast + 1] = FT._castFn
end

require "ZeD/ZeD_TabPx"
if ZeD.TabPx and ZeD.TabPx.ICONS then ZeD.TabPx.ICONS[FT.ID] = true end

ZeD_WorldWindow.addTab({
    id = FT.ID, after = "vehicle", group = 2, glyph = "H",
    iconName = "fishing-tab-white",
    vkey = "IGUI_perks_Fishing",
    label = function() return getText("IGUI_perks_Fishing") end,
    visible = function(win) return Log.visible((win and win._playerObj) or getPlayer()) end,
    render = FT.render,
    scroll = function(win)
        local st = win._fishTab
        if not st then return nil end
        if st.wall then return st.wall.scroll end
        return st.scroll
    end,
    onClick = FT.onClick,
    buildFocusables = FT.buildFocusables,
    scrollKey = FT.scrollKey,
    landOn = function(win)
        local st = win._fishTab
        if st and st.wall then return "fish:wb:back" end
        return FT.landId(st and st.s)
    end,
})

return FT
