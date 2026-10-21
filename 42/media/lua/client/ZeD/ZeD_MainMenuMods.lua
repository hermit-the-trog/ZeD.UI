-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuMods.lua
-- ============================================================================
-- THE MOD MANAGER ON THE MONITOR (HOOK_MAP row 26; director, Oct 14 2026:
-- "a more robust mod manager", design delegated, no mockup)
--
-- A ZeD window on the desk's screen in place of vanilla's ModSelector. Every
-- rule stays vanilla's: the screen drives ModSelector.instance.model (the
-- enable / disable cascade over requirements, incompatibilities, favourites,
-- presets in pz_modlist_settings.cfg, the load order, the map order, and
-- acceptChanges with its per-caller saving and Lua resets). Vanilla's own
-- ModSelector stays built but never shows: its setVisible(true) is redirected
-- here (MM.redirect), so the main menu, Load Game's and New Game's Choose
-- Mods, and Server Settings all land on this window.
--
-- What it adds over vanilla, all on vanilla's data:
--   * filter tabs (All / On / Starred / Maps / Problems) and a plain-text Find
--   * a red status dot and the reason on any mod that cannot run (game
--     version, a missing requirement) or is blocked by an enabled mod
--   * a detail pane: picture, author, version, IDs, what it needs and what
--     it conflicts with (each with its status dot), the description
--   * turning a mod on or off says which other mods came along (requirements)
--   * profiles (Oct 15 2026): vanilla's presets as a page of their own, each with its
--     load order kept (ZeD_modprofiles.txt), what loading it would change, new / update /
--     rename / duplicate / delete / share as text, and the profile in use in the title
--   * load order and map order as views of the same window, with the order
--     rules shown per row and MOVE UP / MOVE DOWN / AUTO
--   * BACK with changes asks in the action strip: KEEP or DISCARD
--   * (Oct 16 2026, director: "identifying conflicts, updating mods from the workshop,
--     reloading the lua ... and saying why a full restart is required") conflicts the
--     game never reports (the same Lua file or the same item / recipe in two mods, who
--     wins and the fix: ZeD_ModScan), the Workshop state of every subscribed item (a
--     Workshop tab, row tags, the detail's WORKSHOP line, Open in Steam), and a strip
--     that says what pending changes need: a reload (no exit) or, when Steam updated a
--     running mod, a restart for its pictures, with Quit to restart
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_ModScan"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui
local MS = ZeD.ModScan

-- design units
local LIST_SHARE = 0.48
local TABS_H, FIND_H, ROW_H, ICON = 30, 34, 42, 24
local DETAIL_PAD, POSTER = 12, 128
local KV_LABEL_W, KV_ROW_H = 96, 20
local NOTE_MS = 6000

local CATEGORY_ICON = { map = "Item_Map", vehicle = "Item_CarTire", features = "Item_ElectronicsScrap", modpack = "Item_SewingBox" }
local STAR = "media/textures/ZeD/icons/icon-star.png"

local function ms() return MainScreen and MainScreen.instance end
local function model() return ModSelector and ModSelector.instance and ModSelector.instance.model end

-- a Java ArrayList (or nil) as a Lua array
local function jlist(l)
    local t = {}
    if l then for i = 0, l:size() - 1 do t[#t + 1] = l:get(i) end end
    return t
end

-- ============================================================================
-- ZeD_MMMods
-- ============================================================================
ZeD_MMMods = ZeD_MMWindow:derive("ZeD_MMMods")

function ZeD_MMMods:new()
    local o = ZeD_MMWindow.new(self, "mods")
    o.noResetControl = true
    o.page = "list"          -- "list" | "order" | "maps"
    o.filter = "all"         -- "all" | "enabled" | "favs" | "maps"
    o.sel = nil
    o.scroll, o.dscroll = 0, 0
    o.confirm = false        -- false | "back" | "template" | "save" | "paste" | "delete" | "update" | "rename" | "dup"
    o.preset = nil           -- the profile last loaded or saved
    o.psel = nil             -- the Profiles page's picked profile (nil: "No mods")
    o.note = nil             -- { text, untilMs }: what a toggle or a preset did
    return o
end

function ZeD_MMMods:createChildren()
    ZeD_Window.createChildren(self)
    self.find = UI.newEntry(self)
    self.find.onTextChange = function() self.scroll = 0 end
    -- a focused field takes Return itself (the key never reaches the menu): onCommandEntered
    -- (the same key then also reaches the menu once the field lets go: _enterAt swallows it)
    self.find.onCommandEntered = function() self._enterAt = MM.now(); self.find:unfocus() end
    self.field = UI.newEntry(self)     -- the strip's field: preset name, pasted preset text
    self.field.onEscape = function() self:setConfirm(false) end
    self.field.onCommandEntered = function()
        self._enterAt = MM.now()
        self:fieldEnter()
    end
    self.field:setVisible(false)
end

function ZeD_MMMods:onShow()
    self.page = "list"
    self.confirm = false
    self.field:setVisible(false)
    self.find:setText("")
    self.scroll, self.dscroll = 0, 0
    self.note = nil
    self.sel = nil
    self.wsSel = nil
    self.psel = nil
    self.focusId = nil
end

-- the mods the list shows: vanilla's sorted records, through the tab and Find (plain text)
function ZeD_MMMods:rows()
    local m = model()
    if not m then return {} end
    local q = string.lower(tostring(self.find:getInternalText() or ""))
    local out = {}
    for _, d in ipairs(m.sortedMods or {}) do
        local keep = true
        if self.filter == "enabled" and not d.isActive then keep = false end
        if self.filter == "favs" and not d.favorite then keep = false end
        if self.filter == "maps" and d.category ~= "map" then keep = false end
        if self.filter == "problems" and not self:problem(d) then keep = false end
        if self.filter == "conflicts" and MS.count(d.modId) == 0 then keep = false end
        if keep and q ~= "" then
            local wid = ""
            pcall(function() wid = tostring(d.modInfo:getWorkshopID() or "") end)
            local hay = string.lower(tostring(d.name) .. " " .. tostring(d.modId) .. " " .. wid)
            keep = hay:find(q, 1, true) ~= nil
        end
        if keep then out[#out + 1] = d end
    end
    return out
end

-- counts and profile comparisons run several times a frame: kept for a moment, dropped on any change
local CACHE_MS = 150
function ZeD_MMMods:dirty() self._cnt, self._diffs = nil, nil end

function ZeD_MMMods:counts()
    local c = self._cnt
    if c and MM.now() - c.at < CACHE_MS then return c[1], c[2], c[3], c[4], c[5], c[6], c[7] end
    local m = model()
    local all, on, favs, maps, probs, confs = 0, 0, 0, 0, 0, 0
    for _, d in ipairs(m and m.sortedMods or {}) do
        all = all + 1
        if d.isActive then on = on + 1 end
        if d.favorite then favs = favs + 1 end
        if d.category == "map" then maps = maps + 1 end
        if self:problem(d) then probs = probs + 1 end
        if MS.count(d.modId) > 0 then confs = confs + 1 end
    end
    local ws = #MS.ws.order
    self._cnt = { all, on, favs, maps, probs, confs, ws, at = MM.now() }
    return all, on, favs, maps, probs, confs, ws
end

-- the installed mod a Workshop item brought (nil: none, or not installed yet)
function ZeD_MMMods:modForWs(wid)
    local m = model()
    for _, d in ipairs(m and m.sortedMods or {}) do
        local w = nil
        pcall(function() w = d.modInfo:getWorkshopID() end)
        if w and tostring(w) == wid then return d end
    end
    return nil
end

-- the tags at a row's right: its conflicts, then what Steam is doing with it
function ZeD_MMMods:rowChips(d)
    local out = {}
    local n = MS.count(d.modId)
    if n > 0 then out[#out + 1] = { ZeD.tr(n == 1 and "UI_ZeD_Mods_ChipConflictOne" or "UI_ZeD_Mods_ChipConflictMany", n), "warning" } end
    local it = MS.wsFor(d.modInfo)
    if it then
        if MS.ws.updatedNow[it.id] and MS.isLoaded(d.modId) then out[#out + 1] = { ZeD.tr("UI_ZeD_Mods_ChipUpdated"), "accent" }
        elseif it.state == "update" then out[#out + 1] = { ZeD.tr("UI_ZeD_Mods_ChipUpdate"), "info" }
        elseif it.state == "downloading" then out[#out + 1] = { ZeD.upper(ZeD.tr("UI_WorkshopServerItemState_Downloading")), "info" }
        elseif it.state == "queued" then out[#out + 1] = { ZeD.tr("UI_ZeD_Mods_ChipQueued"), "info" } end
    end
    return out
end

-- what the changes on the screen need, in a sentence for the strip; nil = nothing pending.
-- restart = true when a running mod was updated by Steam (its pictures stay old until a restart)
function ZeD_MMMods:pending()
    local m = model()
    if not m then return nil end
    local turnedOn, turnedOff = 0, 0
    for _, d in pairs(m.mods or {}) do
        if d.isActive ~= d.defaultActive then
            if d.isActive then turnedOn = turnedOn + 1 else turnedOff = turnedOff + 1 end
        end
    end
    local reorder = false
    pcall(function() reorder = ActiveMods.requiresResetLua(m:getActiveMods()) end)
    local updated = MS.updatedLoaded()
    if turnedOn == 0 and turnedOff == 0 and not reorder and #updated == 0 then return nil end
    local parts = {}
    if turnedOn > 0 then parts[#parts + 1] = ZeD.tr(turnedOn == 1 and "UI_ZeD_Mods_TurnedOnOne" or "UI_ZeD_Mods_TurnedOnMany", turnedOn) end
    if turnedOff > 0 then
        if #parts == 0 then parts[#parts + 1] = ZeD.tr(turnedOff == 1 and "UI_ZeD_Mods_TurnedOffOne" or "UI_ZeD_Mods_TurnedOffMany", turnedOff)
        else parts[#parts + 1] = ZeD.tr("UI_ZeD_Mods_TurnedOffShort", turnedOff) end
    end
    if #parts == 0 and reorder then parts[#parts + 1] = ZeD.tr("UI_ZeD_Mods_LoadOrderChanged") end
    local names = {}
    for _, id in ipairs(updated) do names[#names + 1] = MS.modName(id) end
    local text = table.concat(parts, ", ")
    if #updated > 0 then
        local who = (#names == 1) and names[1] or ((#names == 2) and ZeD.tr("UI_ZeD_ModScan_ListAnd", names[1], names[2]) or ZeD.tr("UI_ZeD_Mods_NMods", #names))
        local says = ZeD.tr(#names == 1 and "UI_ZeD_Mods_SteamUpdatedOne" or "UI_ZeD_Mods_SteamUpdatedMany", who)
        text = (text ~= "") and ZeD.tr("UI_ZeD_Mods_PendingThenSteam", text, says) or says
        return text, true
    end
    return ZeD.tr("UI_ZeD_Mods_PendingReload", text), false
end

function ZeD_MMMods:selected()
    local m = model()
    return m and self.sel and m.mods[self.sel] or nil
end

-- why a mod cannot be turned on (nil = it can): vanilla's isAvailable / isIncompatible, in words
function ZeD_MMMods:problem(d)
    local m = model()
    if not d then return nil end
    local ok, self_ = pcall(function() return d.modInfo:isAvailableSelf() end)
    if ok and self_ == false then
        local vmin, vmax = "", ""
        pcall(function() local v = d.modInfo:getVersionMin(); if v then vmin = v:toString() end end)
        pcall(function() local v = d.modInfo:getVersionMax(); if v then vmax = v:toString() end end)
        if vmin ~= "" or vmax ~= "" then return ZeD.tr("UI_ZeD_Mods_ProbVersionRange", vmin ~= "" and vmin or "?", vmax ~= "" and vmax or "?") end
        return ZeD.tr("UI_ZeD_Mods_ProbVersion")
    end
    if not d.isAvailable then
        local missing = {}
        for _, id in ipairs(jlist(d.modInfo:getRequire())) do
            local r = m.mods[id]
            if not r then missing[#missing + 1] = id
            elseif not r.isAvailable then missing[#missing + 1] = r.name end
        end
        if #missing > 0 then return ZeD.tr("UI_ZeD_Mods_ProbNeeds", table.concat(missing, ", ")) end
        return ZeD.tr("UI_ZeD_Mods_ProbCannot")
    end
    if d.isIncompatible and not d.isActive then
        local by = {}
        for id in pairs(d.incompatibleWith or {}) do
            local r = m.mods[id]
            if r and r.isActive then by[#by + 1] = r.name end
        end
        return ZeD.tr("UI_ZeD_Mods_ProbConflicts", table.concat(by, ", "))
    end
    return nil
end

-- ACTIONS ---------------------------------------------------------------------

local function activeSet(m)
    local s = {}
    for id, d in pairs(m.mods or {}) do if d.isActive then s[id] = true end end
    return s
end

-- vanilla's forceActivateMods (requirements cascade on, dependants cascade off);
-- the note says which other mods came along
function ZeD_MMMods:toggle(d, confirmed)
    local m = model()
    if not (m and d) then return end
    local turnOn = not d.isActive
    if turnOn and self:problem(d) then MM.hoverSound(); return end
    if turnOn and d.modId == "ModTemplate" and not confirmed then self._templateFor = d; self:setConfirm("template"); return end
    local before = activeSet(m)
    m:forceActivateMods(d.modInfo, turnOn)
    self:dirty()
    MM.clickSound()
    local after = activeSet(m)
    local extra = {}
    for id in pairs(after) do if not before[id] and id ~= d.modId then extra[#extra + 1] = m.mods[id] and m.mods[id].name or id end end
    for id in pairs(before) do if not after[id] and id ~= d.modId then extra[#extra + 1] = m.mods[id] and m.mods[id].name or id end end
    if #extra > 0 then
        self:say(ZeD.tr(turnOn and "UI_ZeD_Mods_AlsoOn" or "UI_ZeD_Mods_AlsoOff", table.concat(extra, ", ")))
    end
end

function ZeD_MMMods:toggleFav(d)
    local m = model()
    if not (m and d) then return end
    m:setFavorite(d.modId, (not d.favorite) and true or nil)
    MM.clickSound()
end

function ZeD_MMMods:say(text) self.note = { text = text, untilMs = MM.now() + NOTE_MS }; self:dirty() end

-- what changed since the screen opened (vanilla's Back test)
function ZeD_MMMods:changed()
    local m = model()
    for _, d in pairs(m and m.mods or {}) do
        if d.isActive ~= d.defaultActive then return true end
    end
    return false
end

-- vanilla's ModSelector:onAccept for whichever caller opened the list
function ZeD_MMMods:accept()
    local m = model()
    if not m then return end
    MM.clickSound()
    if self.find:isFocused() then self.find:unfocus() end
    local server = m.isServerSettingsMods
    local inst = ModSelector.instance
    -- a mod Steam updated while the game ran needs the reload vanilla would not run (no list change)
    local force = false
    if not (server or m.isNewGame or m.loadGameFolder) and #MS.updatedLoaded() > 0 then
        local needed = true
        pcall(function() needed = ActiveMods.requiresResetLua(m:getActiveMods()) end)
        force = not needed
    end
    m:acceptChanges()        -- Load / New Game land back on the monitor through the redirects
    if force then
        ms().bottomPanel:setVisible(false)
        getCore():ResetLua("default", "modsChanged")
        return
    end
    if inst.joyfocus then inst:clearJoypadFocus(); inst.joyfocus.focus = inst.returnToUI; updateJoypadFocus(inst.joyfocus) end
    -- server settings' mods: the settings window is back on the monitor (its redirect); the
    -- controller goes to the desk, not to vanilla's hidden screen
    if server then if MM.view == "mods" then MM.toVanilla() else MM.showView(MM.view) end; return end
    if MM.view == "mods" and ms() and ms().bottomPanel:isVisible() then MM.showView("main") end
end

-- vanilla's NO answer: every changed mod back to how it was, favourites too, then accept
function ZeD_MMMods:discard()
    local m = model()
    if not m then return end
    for _, d in pairs(m.mods or {}) do
        if d.isActive ~= d.defaultActive then m:forceActivateMods(d.modInfo, d.defaultActive) end
        m.favs[d.modId] = d.defaultFav
        d.favorite = d.defaultFav
    end
    self:accept()
end

-- the load order differs from the one running now (vanilla's own test)
function ZeD_MMMods:reordered()
    local m = model()
    local r = false
    if m then pcall(function() r = ActiveMods.requiresResetLua(m:getActiveMods()) end) end
    return r
end

-- the strip's DISCARD while changes wait: every mod back to how it loaded, the load order
-- too, and the screen stays
function ZeD_MMMods:revert()
    local m = model()
    if not m then return end
    for _, d in pairs(m.mods or {}) do
        if d.isActive ~= d.defaultActive then m:forceActivateMods(d.modInfo, d.defaultActive) end
    end
    local order, seen = {}, {}
    for _, id in ipairs(jlist(getActivatedMods())) do
        if m.mods[id] and m.mods[id].isActive then order[#order + 1] = id; seen[id] = true end
    end
    for _, id in ipairs(jlist(m:getActiveMods():getMods())) do if not seen[id] then order[#order + 1] = id end end
    m:correctAndSaveModOrder(order)
    self:dirty()
    MM.clickSound()
    self:say(ZeD.tr("UI_ZeD_Mods_SayDiscarded"))
end

-- a conflict's fix: the mod whose copy loses moves to just after the one that wins
function ZeD_MMMods:loadAfter(id, afterId)
    local m = model()
    if not m then return end
    local out = {}
    for _, x in ipairs(jlist(m:getActiveMods():getMods())) do if x ~= id then out[#out + 1] = x end end
    local pos = #out + 1
    for i, x in ipairs(out) do if x == afterId then pos = i + 1 end end
    table.insert(out, pos, id)
    m:correctAndSaveModOrder(out)
    self:dirty()
    MM.clickSound()
    self:say(ZeD.tr("UI_ZeD_Mods_SayLoadAfter", MS.modName(id), MS.modName(afterId)))
end

function ZeD_MMMods:back()
    if self.page ~= "list" then self:leaveOrder(false); return end
    if self:changed() then self:setConfirm("back") else self:accept() end
end

-- PROFILES (director, Oct 15 2026: "more robust features for managing mods and load profiles")
-- A profile is vanilla's mod-list preset (pz_modlist_settings.cfg, so vanilla's own screen and
-- its share text still work) plus what vanilla does not keep, in ZeD's own file
-- Zomboid/Lua/ZeD_modprofiles.txt: the load order, and when it was saved and last loaded.
-- The Profiles page lists them with what loading one would change; loading keeps the order.

local PROFILE_FILE = "ZeD_modprofiles.txt"
local Extra = { loaded = false, t = {} }   -- name -> { order = { ids }, saved = stamp, used = stamp }

local function stamp()
    local ok, s = pcall(function() return SimpleDateFormat.new("yyyy-MM-dd HH:mm", Locale.ENGLISH):format(Calendar.getInstance():getTime()) end)
    return ok and tostring(s) or ""
end

local function extrasLoad()
    Extra.t, Extra.loaded = {}, true
    local r = getFileReader(PROFILE_FILE, false)
    if not r then return end
    local cur
    local line = r:readLine()
    while line do
        local name = line:match("^%[(.+)%]$")
        if name then
            cur = { order = {} }
            Extra.t[name] = cur
        elseif cur then
            local k, v = line:match("^(%a+)=(.*)$")
            if k == "order" then for id in v:gmatch("[^;]+") do cur.order[#cur.order + 1] = id end
            elseif k then cur[k] = v end
        end
        line = r:readLine()
    end
    r:close()
end

local function extrasSave()
    local w = getFileWriter(PROFILE_FILE, true, false)
    if not w then return end
    w:write("ZeD-UI mod profiles: the load order and dates kept with each mod-list preset\n")
    local names = {}
    for n in pairs(Extra.t) do names[#names + 1] = n end
    table.sort(names)
    for _, n in ipairs(names) do
        local e = Extra.t[n]
        w:write("[" .. n .. "]\n")
        if e.order and #e.order > 0 then w:write("order=" .. table.concat(e.order, ";") .. "\n") end
        if e.saved and e.saved ~= "" then w:write("saved=" .. e.saved .. "\n") end
        if e.used and e.used ~= "" then w:write("used=" .. e.used .. "\n") end
    end
    w:close()
end

local function extra(name)
    if not Extra.loaded then extrasLoad() end
    return name and Extra.t[name] or nil
end

-- the mod IDs of a vanilla preset: vanilla's file loader keys them "id" (value the id), its
-- save keys them by id (value the Workshop number)
local function presetIds(p)
    local ids, set = {}, {}
    for k, v in pairs(p or {}) do
        local id = (type(v) == "string" and v ~= "" and not v:match("^%d+$")) and v or tostring(k):match("^[^\\]+")
        if id and not set[id] then set[id] = true; ids[#ids + 1] = id end
    end
    table.sort(ids)
    return ids, set
end

local function byName(a, b) return string.lower(tostring(a.name)) < string.lower(tostring(b.name)) end

function ZeD_MMMods:presetNames()
    local m = model()
    local t = {}
    for name in pairs(m and m.presets or {}) do t[#t + 1] = name end
    table.sort(t, function(a, b) return string.lower(a) < string.lower(b) end)
    return t
end

-- the Profiles page's rows: "No mods" first (every mod off), then the saved profiles
function ZeD_MMMods:profiles()
    local t = { { name = nil, label = ZeD.tr("UI_ZeD_Mods_NoMods") } }
    for _, n in ipairs(self:presetNames()) do t[#t + 1] = { name = n, label = n } end
    return t
end

-- what loading a profile changes from the mods on now
function ZeD_MMMods:profileDiff(p)
    local key = p.name or false          -- false: the "No mods" row
    local cache = self._diffs
    if not cache or MM.now() - cache.at > CACHE_MS then cache = { at = MM.now() }; self._diffs = cache end
    if cache[key] then return cache[key] end
    local m = model()
    local r = { on = {}, off = {}, missing = {}, cannot = {}, count = 0 }
    cache[key] = r
    if not m then return r end
    local ids, want = {}, {}
    if p.name then ids, want = presetIds(m.presets[p.name]) end
    r.count = #ids
    for _, id in ipairs(ids) do
        local d = m.mods[id]
        if not d then r.missing[#r.missing + 1] = id
        elseif not d.isAvailable then r.cannot[#r.cannot + 1] = d
        elseif not d.isActive then r.on[#r.on + 1] = d end
    end
    for id, d in pairs(m.mods or {}) do if d.isActive and not want[id] then r.off[#r.off + 1] = d end end
    table.sort(r.on, byName); table.sort(r.off, byName); table.sort(r.cannot, byName)
    -- noChange: loading turns nothing on or off; inUse: exactly the mods on now, all of them here
    r.noChange = (#r.on == 0 and #r.off == 0)
    r.inUse = p.name ~= nil and r.noChange and #r.missing == 0 and #r.cannot == 0
    return r
end

-- the profile whose mods are the ones on now (nil: none)
function ZeD_MMMods:profileInUse()
    -- two profiles can hold the same mods: the one last loaded or saved wins
    if self.preset and model() and model().presets[self.preset] and self:profileDiff({ name = self.preset }).inUse then return self.preset end
    for _, p in ipairs(self:profiles()) do
        if p.name and self:profileDiff(p).inUse then return p.name end
    end
    return nil
end

-- the order rules (vanilla's ModLoadOrderPanel:autoSort) over a list of mod IDs
local function ruleOrder(m, ids)
    local base = {}
    for _, id in ipairs(ids) do if m.mods[id] then base[#base + 1] = { id = id, info = m.mods[id].modInfo } end end
    table.sort(base, function(a, b) return a.id < b.id end)
    local auto, added = {}, {}
    local function indexOf(t, v) for i, x in ipairs(t) do if x == v then return i end end; return #t end
    for _, val in ipairs(base) do
        local temp = {}
        for _, a in ipairs(jlist(val.info:getLoadAfter())) do if not added[a] then temp[#temp + 1] = a; added[a] = true end end
        for _, r in ipairs(jlist(val.info:getRequire())) do if not added[r] then temp[#temp + 1] = r; added[r] = true end end
        temp[#temp + 1] = val.id
        local mIndex = #temp
        for _, b in ipairs(jlist(val.info:getLoadBefore())) do if not added[b] then temp[#temp + 1] = b; added[b] = true end end
        if added[val.id] then
            local index = indexOf(auto, val.id)
            for j = mIndex + 1, #temp do table.insert(auto, index + 1, temp[j]) end
            for j = 1, mIndex - 1 do table.insert(auto, index, temp[j]) end
        else
            for j = 1, #temp do auto[#auto + 1] = temp[j] end
            added[val.id] = true
        end
    end
    -- only the listed mods stay
    local inList = {}
    for _, id in ipairs(ids) do inList[id] = true end
    local out, seen = {}, {}
    for _, id in ipairs(auto) do if inList[id] and not seen[id] then out[#out + 1] = id; seen[id] = true end end
    return out
end

-- every mod off (the "No mods" profile)
function ZeD_MMMods:setAll(on)
    local m = model()
    if not m then return end
    for _, d in ipairs(m.sortedMods or {}) do
        if on then
            if not d.isActive and d.isAvailable and d.modId ~= "ModTemplate" then m:forceActivateMods(d.modInfo, true) end
        elseif d.isActive then
            m:forceActivateMods(d.modInfo, false)
        end
    end
    self.preset = nil
    self:dirty()
end

-- load: the profile's mods on (their requirements come along), the rest off, in the profile's order
function ZeD_MMMods:loadProfile(p)
    local m = model()
    if not (m and p) then return end
    local diff = self:profileDiff(p)
    MM.clickSound()
    if not p.name then
        self:setAll(false)
        self:say(ZeD.tr("UI_ZeD_Mods_SayNoMods", #diff.off))
        self:leaveProfiles()
        return
    end
    local _, want = presetIds(m.presets[p.name])
    for _, d in ipairs(m.sortedMods or {}) do
        if d.isActive and not want[d.modId] then m:forceActivateMods(d.modInfo, false) end
    end
    for _, d in ipairs(m.sortedMods or {}) do
        if want[d.modId] and not d.isActive and d.isAvailable then m:forceActivateMods(d.modInfo, true) end
    end
    -- the saved order first, then anything else now on (requirements pulled in); a profile saved
    -- before ZeD kept orders is sorted by the mods' own rules
    local active = jlist(m:getActiveMods():getMods())
    local isOn, seen, order = {}, {}, {}
    for _, id in ipairs(active) do isOn[id] = true end
    local e = extra(p.name)
    if e and e.order and #e.order > 0 then
        for _, id in ipairs(e.order) do if isOn[id] and not seen[id] then order[#order + 1] = id; seen[id] = true end end
        for _, id in ipairs(active) do if not seen[id] then order[#order + 1] = id; seen[id] = true end end
    else
        order = ruleOrder(m, active)
    end
    if #order > 0 then m:correctAndSaveModOrder(order) end
    e = e or { order = {} }
    e.used = stamp()
    Extra.t[p.name] = e
    extrasSave()
    self.preset = p.name
    local bits = {}
    if #diff.on > 0 then bits[#bits + 1] = ZeD.tr("UI_ZeD_Mods_BitOn", #diff.on) end
    if #diff.off > 0 then bits[#bits + 1] = ZeD.tr("UI_ZeD_Mods_BitOff", #diff.off) end
    local msg = (#bits > 0) and ZeD.tr("UI_ZeD_Mods_SayLoadedBits", p.name, table.concat(bits, ", ")) or ZeD.tr("UI_ZeD_Mods_SayLoaded", p.name)
    if #diff.missing > 0 then msg = ZeD.tr("UI_ZeD_Mods_SayNotInstalled", msg, table.concat(diff.missing, ", ")) end
    self:say(msg)
    self:leaveProfiles()
end

-- the mods on now, in load order, as a vanilla preset + ZeD's order (new, or replacing one)
function ZeD_MMMods:writeProfile(name)
    local m = model()
    if not (m and name and name ~= "") then return end
    local data, order = {}, {}
    local list = m:getActiveMods():getMods()
    for i = 0, list:size() - 1 do
        local id = list:get(i)
        local wid = ""
        pcall(function() wid = m.mods[id] and m.mods[id].modInfo:getWorkshopID() or "" end)
        data[id] = wid or ""
        order[#order + 1] = id
    end
    m.presets[name] = data
    m:saveModDataToFile()
    self:dirty()
    local e = extra(name) or {}
    e.order, e.saved = order, stamp()
    Extra.t[name] = e
    extrasSave()
    self.preset = name
    self.psel = name
end

function ZeD_MMMods:nameFree(name, except)
    local m = model()
    if not (name and name ~= "" and SandboxOptions.isValidPresetName(name)) then return false end
    if name == "No mods" or name == ZeD.tr("UI_ZeD_Mods_NoMods") then return false end   -- (the pseudo-profile's row: its English and its translated name)
    return not (m and m.presets[name]) or name == except
end

function ZeD_MMMods:savePreset()          -- NEW...: the strip's field holds the name
    local name = self.field:getText()
    if not self:nameFree(name) then return end
    self:writeProfile(name)
    self:setConfirm(false)
    self:say(ZeD.tr("UI_ZeD_Mods_SaySaved", name, #(extra(name).order or {})))
end

function ZeD_MMMods:updateProfile()
    local name = self.psel
    if not name then return end
    self:writeProfile(name)
    self:setConfirm(false)
    self:say(ZeD.tr("UI_ZeD_Mods_SayUpdated", name))
end

function ZeD_MMMods:renameProfile()
    local m = model()
    local old, new = self.psel, self.field:getText()
    if not (m and old and self:nameFree(new, old)) then return end
    if new ~= old then
        m.presets[new], m.presets[old] = m.presets[old], nil
        m:saveModDataToFile()
        extra(old)
        Extra.t[new], Extra.t[old] = Extra.t[old], nil
        extrasSave()
        if self.preset == old then self.preset = new end
        self.psel = new
        self:say(ZeD.tr("UI_ZeD_Mods_SayRenamed", old, new))
    end
    self:setConfirm(false)
end

function ZeD_MMMods:duplicateProfile()
    local m = model()
    local old, new = self.psel, self.field:getText()
    if not (m and old and self:nameFree(new)) then return end
    local copy = {}
    for k, v in pairs(m.presets[old] or {}) do copy[k] = v end
    m.presets[new] = copy
    m:saveModDataToFile()
    local e = extra(old)
    local order = {}
    for _, id in ipairs(e and e.order or {}) do order[#order + 1] = id end
    Extra.t[new] = { order = order, saved = stamp() }
    extrasSave()
    self.psel = new
    self:setConfirm(false)
    self:say(ZeD.tr("UI_ZeD_Mods_SayCopied", old, new))
end

function ZeD_MMMods:deletePreset()
    local m = model()
    local name = self.psel
    if not (m and name) then return end
    m.presets[name] = nil
    m:saveModDataToFile()
    extra(name)
    Extra.t[name] = nil
    extrasSave()
    self:say(ZeD.tr("UI_ZeD_Mods_SayDeleted", name))
    if self.preset == name then self.preset = nil end
    self.psel = nil
    self:setConfirm(false)
end

-- vanilla's share text ("name:id;id;"), written in the profile's load order
function ZeD_MMMods:copyPreset()
    local m = model()
    local name = self.psel
    if not (m and name and m.presets[name]) then return end
    local e = extra(name)
    local ids, set = presetIds(m.presets[name])
    local out, seen = {}, {}
    for _, id in ipairs(e and e.order or {}) do if set[id] and not seen[id] then out[#out + 1] = id; seen[id] = true end end
    for _, id in ipairs(ids) do if not seen[id] then out[#out + 1] = id end end
    Clipboard.setClipboard(name .. ":" .. table.concat(out, ";") .. ";")
    self:say(ZeD.tr("UI_ZeD_Mods_SayCopiedText", name))
end

-- a pasted share text (vanilla's addSharedPreset), its order kept as written
function ZeD_MMMods:pastePreset()
    local m = model()
    local txt = self.field:getText()
    if not (m and txt and txt ~= "") then return end
    local before = {}
    for name in pairs(m.presets) do before[name] = true end
    m:addSharedPreset({ internal = "OK", parent = { entry = { getText = function() return txt end } } })
    m:saveModDataToFile()
    self:setConfirm(false)
    for name in pairs(m.presets) do
        if not before[name] then
            local order = {}
            local body = txt:match(":(.*)$") or ""
            for v in body:gmatch("[^;]+") do local id = v:match("^[^\\]+"); if id and id:match("%S") then order[#order + 1] = id end end
            extra(name)
            Extra.t[name] = { order = order, saved = stamp() }
            extrasSave()
            self.psel = name
            self:say(ZeD.tr("UI_ZeD_Mods_SayAdded", name))
            return
        end
    end
    self:say(ZeD.tr("UI_ZeD_Mods_SayNothingToAdd"))
end

function ZeD_MMMods:moreItems()
    local t = {}
    if self.psel then
        t[#t + 1] = { text = ZeD.tr("UI_ZeD_Mods_MoreRename", self.psel), fn = function() self:setConfirm("rename") end }
        t[#t + 1] = { text = ZeD.tr("UI_ZeD_Mods_MoreDuplicate", self.psel), fn = function() self:setConfirm("dup") end }
        t[#t + 1] = { text = ZeD.tr("UI_ZeD_Mods_MoreCopyText"), fn = function() self:copyPreset() end }
    end
    t[#t + 1] = { text = ZeD.tr("UI_ZeD_Mods_MorePaste"), fn = function() self:setConfirm("paste") end }
    t[#t + 1] = "-"
    t[#t + 1] = { text = ZeD.tr("UI_ZeD_Mods_MoreAllOn"), fn = function() self:setAll(true); self:say(ZeD.tr("UI_ZeD_Mods_SayAllOn")); self:leaveProfiles() end }
    if self.psel then
        t[#t + 1] = "-"
        t[#t + 1] = { text = ZeD.tr("UI_ZeD_Mods_MoreDelete", self.psel), fn = function() self:setConfirm("delete") end }
    end
    return t
end

function ZeD_MMMods:openMore()
    for _, b in ipairs(self._specs) do
        if b.id == "more" then
            MM.openPopup("profilesMore", self:moreItems(), { x = self:getAbsoluteX() + b.x, y = self:getAbsoluteY() + b.y, w = b.w, h = b.h }, true)
            return
        end
    end
end

function ZeD_MMMods:enterProfiles()
    MM.clickSound()
    MM.ctx.open = nil
    self.confirm = false
    self.field:setVisible(false)
    self.page = "profiles"
    local inUse = self:profileInUse()
    self.psel = inUse or self.preset
    if self.psel and not (model() and model().presets[self.psel]) then self.psel = nil end
    self.scroll, self.dscroll = 0, 0
    local idx = 1
    for i, p in ipairs(self:profiles()) do if p.name == self.psel then idx = i end end
    self.focusId = "prow:" .. idx
end

function ZeD_MMMods:leaveProfiles()
    self.page = "list"
    self.confirm = false
    self.field:setVisible(false)
    self.scroll, self.dscroll = 0, 0
    self.focusId = nil
end

-- LOAD ORDER + MAP ORDER (vanilla's ModLoadOrderPanel / MapOrderUI rules) -----------

function ZeD_MMMods:enterOrder(page)
    local m = model()
    if not m then return end
    MM.clickSound()
    self.confirm = false
    if page == "order" then
        self.order = jlist(m:getActiveMods():getMods())
        self._orderStart = table.concat(self.order, ";")
    else
        self.order = jlist(m:getAllMapsInOrder())
        self._orderStart = table.concat(self.order, ";")
    end
    self.page = page
    self.oSel = 1
    self.scroll = 0
    self.focusId = "orow:1"
end

-- keep = true writes the order (vanilla's correctAndSaveModOrder / getMapOrder), false leaves it
function ZeD_MMMods:leaveOrder(keep)
    local m = model()
    if keep and m then
        if self.page == "order" then
            m:correctAndSaveModOrder(self.order)
        else
            local mo = m:getActiveMods():getMapOrder()
            mo:clear()
            for _, name in ipairs(self.order) do mo:add(name) end
        end
        self:say(ZeD.tr(self.page == "order" and "UI_ZeD_Mods_SayOrderSet" or "UI_ZeD_Mods_SayMapsSet"))
    end
    MM.clickSound()
    self.page = "list"
    self.scroll = 0
    self.focusId = nil
end

-- the order rules per row: "ok" | "soft" (load before / after not kept) | "bad" (a requirement loads later)
function ZeD_MMMods:orderStates()
    local m = model()
    local idx, st, firstBad = {}, {}, nil
    for i, id in ipairs(self.order) do idx[id] = i end
    for i, id in ipairs(self.order) do
        local d = m and m.mods[id]
        local s = "ok"
        if d then
            for _, r in ipairs(jlist(d.modInfo:getRequire())) do
                if idx[r] and idx[r] > i then s = "bad" end
                if not idx[r] then s = "bad" end
            end
            if s == "ok" then
                for _, b in ipairs(jlist(d.modInfo:getLoadBefore())) do if idx[b] and idx[b] < i then s = "soft" end end
                for _, a in ipairs(jlist(d.modInfo:getLoadAfter())) do if idx[a] and idx[a] > i then s = "soft" end end
            end
        end
        st[i] = s
        if s == "bad" and not firstBad then firstBad = i end
    end
    return st, firstBad
end

function ZeD_MMMods:move(delta)
    local i = self.oSel or 1
    local j = i + delta
    if j < 1 or j > #self.order then return end
    self.order[i], self.order[j] = self.order[j], self.order[i]
    self.oSel = j
    self.focusId = "orow:" .. j
    MM.hoverSound()
end

-- vanilla's ModLoadOrderPanel:autoSort, on our list
function ZeD_MMMods:autoSort()
    local m = model()
    if not m then return end
    self.order = ruleOrder(m, self.order)
    MM.clickSound()
end

-- THE STRIP'S QUESTIONS AND FIELDS ------------------------------------------------

local FIELD_MODES = { save = true, paste = true, rename = true, dup = true }

-- Return in the strip's field: the mode's own action
function ZeD_MMMods:fieldEnter()
    local c = self.confirm
    if c == "save" then self:savePreset() elseif c == "paste" then self:pastePreset()
    elseif c == "rename" then self:renameProfile() elseif c == "dup" then self:duplicateProfile() end
end

function ZeD_MMMods:setConfirm(mode)
    if self.confirm == mode then return end
    self.confirm = mode
    MM.ctx.open = nil
    if FIELD_MODES[mode] then
        local pre = ""
        if mode == "rename" then pre = self.psel or "" elseif mode == "dup" then pre = ZeD.tr("UI_ZeD_Mods_CopyName", self.psel or "") end
        self.field:setText(pre)
        self.field:setVisible(true)
        self.field:focus()
    else
        self.field:setVisible(false)
        if self.field:isFocused() then self.field:unfocus() end
    end
    self.focusId = mode and "confirm:yes" or nil
end

-- LAYOUT + DRAWING ---------------------------------------------------------------

function ZeD_MMMods:prerender()
    local T = ZeD.T
    if self.page == "list" then MS.step(); MS.wsPoll(true) end
    self._specs, self._hits = {}, {}
    local w, h = UI.placeOnTube(self)
    local all, on = self:counts()
    local md = model()
    local server = md and md.isServerSettingsMods   -- (a server's mods, from its settings)
    local section
    if self.page == "order" then section = server and "UI_ZeD_Mods_TitleServerOrder" or "UI_ZeD_Mods_TitleOrder"
    elseif self.page == "maps" then section = server and "UI_ZeD_Mods_TitleServerMaps" or "UI_ZeD_Mods_TitleMaps"
    elseif self.page == "profiles" then section = server and "UI_ZeD_Mods_TitleServerProfiles" or "UI_ZeD_Mods_TitleProfiles"
    else section = server and "UI_ZeD_Mods_TitleServer" or "UI_ZeD_Mods_Title" end
    self.title = ZeD.tr("UI_ZeD_Mods_TitleFmt", ZeD.tr(section))
    self.titleStats = { { text = ZeD.tr("UI_ZeD_Mods_StatOn", on, all), color = (on > 0) and T.positive or T.textDim } }
    local inUse = self:profileInUse()
    if inUse then table.insert(self.titleStats, 1, { text = inUse, color = T.accent }) end
    ZeD_Window.prerender(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = T.px(U.STRIP_BTN_H) + T.px(U.STRIP_PAD_Y) * 2
    local stripY = h - self:footerHeight() - stripH
    local bodyY, bodyH = tb + pad, stripY - tb - pad * 2
    if self.page == "list" then
        local lw = math.floor((w - pad * 3) * LIST_SHARE)
        local _, tabsW = self:tabList()          -- the list widens (to a point) before its tabs would run out
        lw = math.max(lw, math.min(tabsW, math.floor((w - pad * 3) * 0.62)))
        self:drawList(pad, bodyY, lw, bodyH)
        self:drawDetail(pad * 2 + lw, bodyY, w - pad * 3 - lw, bodyH)
        self.find:setVisible(true)
    elseif self.page == "profiles" then
        self.find:setVisible(false)
        self:drawProfiles(pad, bodyY, w - pad * 2, bodyH)
    else
        self.find:setVisible(false)
        self:drawOrder(pad, bodyY, w - pad * 2, bodyH)
    end
    self:buildStrip(stripY, stripH, w)
end

function ZeD_MMMods:render()
    UI.drawStripAndButtons(self, self._stripY, self._stripH, self._ask, self._askX)
    ZeD_Window.render(self)
end

function ZeD_MMMods:buildStrip(stripY, stripH, w)
    local T = ZeD.T
    local row = 1000
    local ask = nil
    local m = model()
    self._askX = nil
    if self.confirm == "back" then
        ask = ZeD.tr("UI_ZeD_Mods_AskKeep")
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", ZeD.tr("UI_ZeD_Options_Discard"), function() self:discard() end },
            { "confirm:yes", getText("ContextMenu_Keep"), function() self:accept() end, "primary" } })
    elseif self.confirm == "template" then
        ask = MM.ui.plain(getText("UI_modselector_modTemplateWarn"))
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", ZeD.tr("ContextMenu_Turn_On"), function() local d = self._templateFor; self:setConfirm(false); self:toggle(d, true) end, "primary" } })
    elseif self.confirm == "delete" then
        ask = ZeD.tr("UI_ZeD_Mods_AskDelete", tostring(self.psel))
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", getText("UI_btn_delete"), function() self:deletePreset() end, "danger" } })
    elseif self.confirm == "update" then
        local _, on = self:counts()
        ask = ZeD.tr(on == 1 and "UI_ZeD_Mods_AskReplaceOne" or "UI_ZeD_Mods_AskReplaceMany", tostring(self.psel), on)
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", ZeD.tr("UI_ZeD_Mods_Replace"), function() self:updateProfile() end, "primary" } })
    elseif FIELD_MODES[self.confirm] then
        local c = self.confirm
        ask = ZeD.tr((c == "save" and "UI_ZeD_Mods_AskNewName") or (c == "rename" and "UI_ZeD_Saves_AskRename") or (c == "dup" and "UI_ZeD_Mods_AskCopyAs") or "UI_ZeD_Mods_AskProfileText")
        local text = self.field:getText()
        local valid
        if c == "paste" then valid = text and text:find(":", 1, true) ~= nil
        elseif c == "rename" then valid = self:nameFree(text, self.psel)
        else valid = self:nameFree(text) end
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", (c == "paste" and getText("UI_btn_add")) or (c == "rename" and getText("UI_btn_rename")) or getText("UI_btn_save"), function() self:fieldEnter() end, "primary", not valid } })
        local f2 = T.fontF2
        local fx = T.px(U.STRIP_PAD_X) + T.px(4) + MM.textW(f2, ask) + T.px(10)
        local firstBtn = w
        for _, b in ipairs(self._specs) do if b.row == row then firstBtn = math.min(firstBtn, b.x) end end
        local fh = T.px(24)
        UI.styleEntry(self.field, fx, stripY + math.floor((stripH - fh) / 2), math.max(T.px(80), firstBtn - T.px(12) - fx), fh)
    elseif self.page == "profiles" then
        local isUser = self.psel ~= nil
        local selDiff = self:profileDiff({ name = self.psel })
        local inUse = isUser and selDiff.inUse
        local loadOff = selDiff.noChange
        UI.stripSpecs(self, stripY, w, row,
            { { "back", getText("UI_btn_back"), function() self:leaveProfiles(); MM.clickSound() end } },
            { { "new", ZeD.tr("UI_ZeD_Mods_BtnNew"), function() self:setConfirm("save") end },
              { "update", ZeD.tr("UI_ZeD_Mods_BtnUpdate"), function() self:setConfirm("update") end, "default", not isUser or inUse },
              { "more", ZeD.tr("UI_ZeD_Saves_More"), function() self:openMore() end },
              { "load", getText("UI_mainscreen_load"), function() self:loadProfile({ name = self.psel }) end, "primary", loadOff } })
    elseif self.page ~= "list" then
        local _, firstBad = self:orderStates()
        UI.stripSpecs(self, stripY, w, row,
            { { "back", getText("UI_btn_back"), function() self:leaveOrder(false) end } },
            { { "auto", ZeD.tr("UI_ZeD_Mods_BtnAuto"), function() self:autoSort() end, "default", self.page ~= "order" },
              { "done", getText("UI_mods_Done"), function() self:leaveOrder(true) end, "primary", self.page == "order" and firstBad ~= nil } })
    else
        local mapConflicts = false
        pcall(function() mapConflicts = m and m:checkMapConflicts() or false end)
        local lefts = { { "back", getText("UI_btn_back"), function() self:back() end } }
        local rights = {
            { "profiles", ZeD.tr("UI_ZeD_Mods_BtnProfiles"), function() self:enterProfiles() end },
            { "order", ZeD.tr("UI_ZeD_Mods_BtnLoadOrder"), function() self:enterOrder("order") end },
        }
        if mapConflicts then rights[#rights + 1] = { "maps", ZeD.tr("UI_ZeD_Mods_BtnMapOrder"), function() self:enterOrder("maps") end } end
        if self.filter == "ws" then rights[#rights + 1] = { "wsopen", ZeD.tr("UI_ZeD_Mods_BtnOpenWorkshop"), function() MS.openWorkshop() end } end
        -- changes waiting: the strip says what they need, DISCARD stays on the screen, RELOAD is vanilla's accept
        local pend, restart = nil, false
        if not (m and (m.isServerSettingsMods or m.isNewGame or m.loadGameFolder)) then pend, restart = self:pending() end
        if pend then
            if self:changed() or self:reordered() then rights[#rights + 1] = { "revert", ZeD.tr("UI_ZeD_Options_Discard"), function() self:revert() end } end
            rights[#rights + 1] = { "accept", ZeD.tr("UI_ZeD_Mods_BtnReload"), function() self:accept() end, "primary" }
            if restart then rights[#rights + 1] = { "restart", ZeD.tr("UI_ZeD_Mods_BtnQuitRestart"), function() MM.act.askQuit() end } end
        else
            rights[#rights + 1] = { "accept", getText("UI_btn_accept"), function() self:accept() end, "primary" }
        end
        local askX = UI.stripSpecs(self, stripY, w, row, lefts, rights)
        if pend then
            local firstBtn = w
            for _, b in ipairs(self._specs) do if b.row == row and b.x > askX then firstBtn = math.min(firstBtn, b.x) end end
            local room = firstBtn - T.px(12) - (askX + T.px(4))
            if room > T.px(60) then ask = ZeD.Atoms.truncateText(pend, T.fontF2, room); self._askX = askX + T.px(4) end
        end
    end
    self._stripY, self._stripH, self._ask = stripY, stripH, ask
end

-- a tag on a list row: on the list's own fill, so a picked (accent-tinted) row keeps it readable
local function rowBadge(p, text, x, y, variant)
    local T = ZeD.T
    local f = T.fontF1
    local bw = MM.textW(f, text) + T.sp.badgePadX * 2
    local bh = MM.fontH(f) + T.sp.badgePadY * 2
    local b = T.base
    p:drawRect(x, y, bw, bh, 1, b.r, b.g, b.b)
    ZeD.Atoms.drawBadge(p, text, x, y, variant, false, f, true)
end

-- the filter tabs: All and On always, the rest while they hold something (or are open);
-- a Conflicts or Workshop tab turning up is itself the news. Returns them and their width.
function ZeD_MMMods:tabList()
    local T = ZeD.T
    local all, on, favs, maps, probs, confs, wsn = self:counts()
    local tabs = { { "all", ZeD.tr("UI_ZeD_Mods_TabAll", all) }, { "enabled", ZeD.tr("UI_ZeD_Mods_TabOn", on) } }
    local more = { { "favs", "UI_ZeD_Mods_TabStarred", favs }, { "maps", "UI_ZeD_Mods_TabMaps", maps }, { "problems", "UI_ZeD_Mods_TabProblems", probs },
                   { "conflicts", "UI_ZeD_Mods_TabConflicts", confs }, { "ws", "UI_ZeD_Mods_TabWorkshop", wsn } }
    for _, t in ipairs(more) do
        if t[3] > 0 or self.filter == t[1] then tabs[#tabs + 1] = { t[1], ZeD.tr(t[2], t[3]) } end
    end
    local need = T.px(16)
    for _, t in ipairs(tabs) do need = need + MM.textW(T.fontF2, t[2]) + T.sp.tabPadX * 2 + T.sp.tabGap end
    return tabs, need
end

function ZeD_MMMods:drawList(x, y, w, h)
    local T = ZeD.T
    local bs, s2 = T.borderS, T.surf2
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    UI.insetBox(self, x, y, w, h)
    -- the filter tabs (System 7 folder tabs), then Find
    local tabs = self:tabList()
    self._tabOrder = {}
    for _, t in ipairs(tabs) do self._tabOrder[#self._tabOrder + 1] = t[1] end
    local tH = T.px(TABS_H)
    self:drawRect(x + T.px(1), y + T.px(1), w - T.px(2), tH, 1, s2.r, s2.g, s2.b)
    local tx = x + T.px(8)
    local tY = y + tH - T.tabH
    for _, t in ipairs(tabs) do
        local hid = "mods:tab:" .. t[1]
        local tw = ZeD.Molecules.drawTab(self, tx, tY, t[2], self.filter == t[1], MM.ctx.hot == hid, false)
        self._hits[#self._hits + 1] = { id = hid, x = ax + tx, y = ay + tY, w = tw, h = T.tabH, fn = function()
            if self.filter ~= t[1] then self.filter = t[1]; self.scroll = 0; MM.clickSound() end end }
        tx = tx + tw + T.sp.tabGap
    end
    self:drawRect(x, y + tH, w, T.px(1), bs.a, bs.r, bs.g, bs.b)
    local fY = y + tH + T.px(1)
    local fH = T.px(FIND_H)
    self:drawRect(x + T.px(1), fY, w - T.px(2), fH - T.px(1), 1, s2.r, s2.g, s2.b)
    self:drawRect(x, fY + fH - T.px(1), w, T.px(1), bs.a, bs.r, bs.g, bs.b)
    local f2, c = T.fontF2, T.text
    local findLabel = ZeD.tr("UI_ZeD_Options_Find")
    self:drawText(findLabel, x + T.px(8), fY + math.floor((fH - MM.fontH(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
    local ex = x + T.px(8) + MM.textW(f2, findLabel) + T.px(8)
    local eh = T.px(24)
    UI.styleEntry(self.find, ex, fY + math.floor((fH - eh) / 2), x + w - T.px(8) - ex, eh)
    self._hits[#self._hits + 1] = { id = "mods:find", x = ax + self.find.x, y = ay + self.find.y, w = self.find.width, h = self.find.height,
                                    fn = function() self.find:focus() end }

    -- the rows (the Workshop tab lists Steam's items instead)
    if self.filter == "ws" then self:drawWsRows(x, y, w, h, fY + fH); return end
    local rows = self:rows()
    if not self.sel and rows[1] then self.sel = rows[1].modId end
    local vy, vh = fY + fH, h - (fY + fH - y) - T.px(1)
    local rh = T.px(ROW_H)
    local rowsH = #rows * rh
    local sbW = T.sp.scrollbarW
    local over = rowsH > vh
    local rw = w - T.px(2) - (over and sbW or 0)
    self.scroll = math.max(0, math.min(self.scroll, math.max(0, rowsH - vh)))
    self._list = { x = x, y = vy, w = w, h = vh }
    local gp = MM.gamepad()
    local ac = T.accent
    local cb = T.checkboxSz
    local star = MM.tex and MM.tex(STAR, true) or getTexture(STAR)
    if #rows == 0 then
        local d = T.textDim
        local msg = (self.filter == "favs") and ZeD.tr("UI_ZeD_Mods_EmptyFavs") or ((self.filter == "problems") and ZeD.tr("UI_ZeD_Mods_EmptyProblems")
            or ((self.filter == "conflicts") and ZeD.tr(MS.res.done and "UI_ZeD_Mods_EmptyConflicts" or "UI_ZeD_Mods_EmptyChecking") or ZeD.tr("UI_ZeD_Mods_EmptyNone")))
        self:drawText(msg, x + T.px(12), vy + T.px(12), d.r, d.g, d.b, d.a or 1, f2)
    end
    self:setStencilRect(x + T.px(1), vy, w - T.px(2), vh)
    for i, d in ipairs(rows) do
        local ry = vy + (i - 1) * rh - self.scroll
        local rid = "mrow:" .. d.modId
        self._specs[#self._specs + 1] = { id = rid, listRow = true, row = i, col = 1, fn = function() self:toggle(d) end, key = d.modId, ry = (i - 1) * rh, rh = rh }
        if ry + rh > vy and ry < vy + vh then
            local isSel = d.modId == self.sel
            if gp and self.focusId == rid then self:drawRect(x + T.px(1), ry, rw, rh, 0.55, ac.r, ac.g, ac.b)
            elseif isSel then self:drawRect(x + T.px(1), ry, rw, rh, 0.22, ac.r, ac.g, ac.b) end
            self:drawRect(x + T.px(1), ry + rh - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
            local prob = self:problem(d)
            -- the box: on / off (a mod that cannot run draws it disabled)
            local cx, cyy = x + T.px(10), ry + math.floor((rh - cb) / 2)
            ZeD.Atoms.drawCheckbox(self, cx, cyy, d.isActive, MM.ctx.hot == "mods:cb:" .. d.modId, prob ~= nil and not d.isActive)
            -- icon
            local ix = cx + cb + T.px(8)
            local iconName = (d.icon and d.icon ~= "") and d.icon or CATEGORY_ICON[d.category or ""]
            local itex = iconName and getTexture(iconName) or nil
            if itex then self:drawTextureScaledAspect(itex, ix, ry + math.floor((rh - T.px(ICON)) / 2), T.px(ICON), T.px(ICON), 1, 1, 1, 1) end
            -- name, then id and what is wrong
            local nx = ix + T.px(ICON) + T.px(8)
            local starW = T.px(16)
            -- the tags (conflicts, Steam's state) sit at the right, before the star
            local chipR = x + rw - T.px(10) - starW - T.px(8)
            for ci, chip in ipairs(self:rowChips(d)) do
                local ctext = chip[1]
                local cwid = MM.textW(T.fontF1, ctext) + T.sp.badgePadX * 2
                local chh = MM.fontH(T.fontF1) + T.sp.badgePadY * 2
                chipR = chipR - cwid
                rowBadge(self, ctext, chipR, ry + math.floor((rh - chh) / 2), chip[2])
                chipR = chipR - T.px(6)
            end
            local maxW = chipR - T.px(4) - nx
            local nameC = (prob and not d.isActive) and T.textDim or T.textHead
            local l1y = ry + T.px(5)
            self:drawText(ZeD.Atoms.truncateText(tostring(d.name), f2, maxW), nx, l1y, nameC.r, nameC.g, nameC.b, nameC.a or 1, f2)
            local f3, dim = T.fontF3, T.textDim
            local l2y = ry + rh - T.px(5) - MM.fontH(f3)
            local lx = nx
            local sub = tostring(d.modId)
            if prob then
                local dsz = T.px(7)
                ZeD.Atoms.drawStatusDot(self, lx, l2y + math.floor((MM.fontH(f3) - dsz) / 2), T.danger, dsz)
                lx = lx + dsz + T.px(5)
                sub = prob
            end
            self:drawText(ZeD.Atoms.truncateText(sub, f3, maxW - (lx - nx)), lx, l2y, dim.r, dim.g, dim.b, dim.a or 1, f3)
            -- the favourite star
            local sx = x + rw - T.px(10) - starW
            local sy = ry + math.floor((rh - starW) / 2)
            local sHot = MM.ctx.hot == "mods:star:" .. d.modId
            if star and (d.favorite or sHot) then
                ZeD.Atoms.drawIcon(self, star, sx, sy, starW, d.favorite and 1 or 0.5, d.favorite and T.accent or T.textDim)
            end
            local cy0, ch = math.max(ry, vy), math.min(ry + rh, vy + vh) - math.max(ry, vy)
            self._hits[#self._hits + 1] = { id = "mods:row:" .. d.modId, x = ax + x, y = ay + cy0, w = rw, h = ch, fn = function() self:clickRow(d) end }
            self._hits[#self._hits + 1] = { id = "mods:cb:" .. d.modId, x = ax + x, y = ay + cy0, w = cb + T.px(16), h = ch, fn = function() self.sel = d.modId; self:toggle(d) end }
            self._hits[#self._hits + 1] = { id = "mods:star:" .. d.modId, x = ax + sx - T.px(4), y = ay + cy0, w = starW + T.px(8), h = ch, fn = function() self:toggleFav(d) end }
        end
    end
    self:clearStencilRect()
    if over then
        local sx = x + w - T.px(1) - sbW
        ZeD.Atoms.drawScrollTrack(self, sx, vy, sbW, vh)
        local th = math.max(T.px(24), math.floor(vh * vh / rowsH))
        local tyy = vy + math.floor((vh - th) * self.scroll / (rowsH - vh))
        ZeD.Atoms.drawScrollThumb(self, sx, tyy, sbW, th, MM.ctx.hot == "mods:track" and "hover" or "default")
        self._hits[#self._hits + 1] = { id = "mods:track", x = ax + sx, y = ay + vy, w = sbW, h = vh, drag = function(_, my)
            self.scroll = math.floor(((my - ay - vy) / vh) * rowsH - vh / 2) end }
    end
end

-- Steam's state of an item as a tag: text and colour
local WS_TAG = { ok = "positive", update = "info", downloading = "info", queued = "info", missing = "warning", none = "neutral" }
-- (its words, as translation keys: the small caps tag on the Workshop tab's rows)
local WS_TAG_TEXT = { ok = "UI_ZeD_Mods_TagOk", update = "UI_ZeD_Mods_TagUpdate", downloading = "UI_WorkshopServerItemState_Downloading",
                      queued = "UI_ZeD_Mods_TagQueued", missing = "UI_ZeD_Mods_TagMissing", none = "UI_WorkshopServerItemState_NotSubscribed" }

-- the Workshop tab's rows: every subscribed item with Steam's state, when it was
-- updated and its size; an item that brought a mod has its on / off box
function ZeD_MMMods:drawWsRows(x, y, w, h, vy)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local f2, f3 = T.fontF2, T.fontF3
    local items = MS.ws.order
    local vh = h - (vy - y) - T.px(1)
    local rh = T.px(ROW_H)
    local rowsH = #items * rh
    local sbW = T.sp.scrollbarW
    local over = rowsH > vh
    local rw = w - T.px(2) - (over and sbW or 0)
    self.scroll = math.max(0, math.min(self.scroll, math.max(0, rowsH - vh)))
    self._list = { x = x, y = vy, w = w, h = vh }
    if not self.wsSel and items[1] then self.wsSel = items[1].id; local d = self:modForWs(items[1].id); self.sel = d and d.modId or nil end
    if #items == 0 then
        local dc = T.textDim
        local msg = MS.ws.steamOff and ZeD.tr("UI_ZeD_Mods_WsNoSteam")
            or ZeD.tr((MS.ws.pending or not MS.ws.asked) and "UI_ZeD_Mods_WsAsking" or "UI_ZeD_Mods_WsNothing")
        self:drawText(msg, x + T.px(12), vy + T.px(12), dc.r, dc.g, dc.b, dc.a or 1, f2)
    end
    local gp, ac, cb = MM.gamepad(), T.accent, T.checkboxSz
    self:setStencilRect(x + T.px(1), vy, w - T.px(2), vh)
    for i, it in ipairs(items) do
        local ry = vy + (i - 1) * rh - self.scroll
        local d = self:modForWs(it.id)
        local rid = "wrow:" .. it.id
        self._specs[#self._specs + 1] = { id = rid, listRow = true, row = i, col = 1, key = d and d.modId or nil, wsid = it.id, chosen = self.wsSel == it.id,
                                          fn = function() if d then self:toggle(d) else MS.openInSteam(it.id) end end, ry = (i - 1) * rh, rh = rh }
        if ry + rh > vy and ry < vy + vh then
            if gp and self.focusId == rid then self:drawRect(x + T.px(1), ry, rw, rh, 0.55, ac.r, ac.g, ac.b)
            elseif self.wsSel == it.id then self:drawRect(x + T.px(1), ry, rw, rh, 0.22, ac.r, ac.g, ac.b) end
            self:drawRect(x + T.px(1), ry + rh - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
            local cx = x + T.px(10)
            if d then ZeD.Atoms.drawCheckbox(self, cx, ry + math.floor((rh - cb) / 2), d.isActive, MM.ctx.hot == "mods:wcb:" .. it.id, self:problem(d) ~= nil and not d.isActive) end
            local nx = cx + cb + T.px(8)
            -- the state tag at the right
            local tx = x + rw - T.px(10)
            if it.children == 0 then
                local fresh = d and MS.ws.updatedNow[it.id] and MS.isLoaded(d.modId)
                local tag = fresh and ZeD.tr("UI_ZeD_Mods_ChipUpdated") or (WS_TAG_TEXT[it.state] and ZeD.upper(ZeD.tr(WS_TAG_TEXT[it.state])) or "")
                local tw = MM.textW(T.fontF1, tag) + T.sp.badgePadX * 2
                local th = MM.fontH(T.fontF1) + T.sp.badgePadY * 2
                tx = tx - tw
                rowBadge(self, tag, tx, ry + math.floor((rh - th) / 2), fresh and "accent" or WS_TAG[it.state])
            end
            local maxW = tx - T.px(8) - nx
            local tc = T.textHead
            self:drawText(ZeD.Atoms.truncateText(it.title, f2, maxW), nx, ry + T.px(5), tc.r, tc.g, tc.b, tc.a or 1, f2)
            local sub
            if it.children > 0 then sub = ZeD.tr("UI_ZeD_Mods_WsCollectionItems", it.children)
            elseif it.state == "missing" then sub = ZeD.tr("UI_ZeD_Mods_WsNotFetched")
            else
                local bits = {}
                local ago = MS.ago(it.updated)
                if ago ~= "" then bits[#bits + 1] = ZeD.tr("UI_ZeD_Mods_WsUpdatedAgo", ago) end
                local sz = MS.size(it.size)
                if sz ~= "" then bits[#bits + 1] = sz end
                sub = table.concat(bits, " | ")
            end
            local dim = T.textDim
            self:drawText(ZeD.Atoms.truncateText(sub, f3, maxW), nx, ry + rh - T.px(5) - MM.fontH(f3), dim.r, dim.g, dim.b, dim.a or 1, f3)
            local cy0, ch = math.max(ry, vy), math.min(ry + rh, vy + vh) - math.max(ry, vy)
            self._hits[#self._hits + 1] = { id = "mods:wrow:" .. it.id, x = ax + x, y = ay + cy0, w = rw, h = ch, fn = function() self:clickWsRow(it, d) end }
            if d then self._hits[#self._hits + 1] = { id = "mods:wcb:" .. it.id, x = ax + x, y = ay + cy0, w = cb + T.px(16), h = ch,
                                                      fn = function() self.wsSel = it.id; self.sel = d.modId; self:toggle(d) end } end
        end
    end
    self:clearStencilRect()
    if over then
        local sx = x + w - T.px(1) - sbW
        ZeD.Atoms.drawScrollTrack(self, sx, vy, sbW, vh)
        local thh = math.max(T.px(24), math.floor(vh * vh / rowsH))
        local tyy = vy + math.floor((vh - thh) * self.scroll / (rowsH - vh))
        ZeD.Atoms.drawScrollThumb(self, sx, tyy, sbW, thh, MM.ctx.hot == "mods:track" and "hover" or "default")
        self._hits[#self._hits + 1] = { id = "mods:track", x = ax + sx, y = ay + vy, w = sbW, h = vh, drag = function(_, my)
            self.scroll = math.floor(((my - ay - vy) / vh) * rowsH - vh / 2) end }
    end
end

-- a Workshop row: a click picks it; a second click turns its mod on / off (or opens Steam's page)
function ZeD_MMMods:clickWsRow(it, d)
    local t = MM.now()
    if self.wsSel == it.id and self._lastClick and t - self._lastClick < 450 then
        self._lastClick = nil
        if d then self:toggle(d) else MS.openInSteam(it.id) end
        return
    end
    self._lastClick = t
    if self.wsSel ~= it.id then self.dscroll = 0; MM.hoverSound() end
    self.wsSel = it.id
    self.sel = d and d.modId or nil
    self.focusId = "wrow:" .. it.id
end

-- a click picks the mod; a second click on it soon after turns it on / off
function ZeD_MMMods:clickRow(d)
    local t = MM.now()
    if self.sel == d.modId and self._lastClick and t - self._lastClick < 450 then
        self._lastClick = nil
        self:toggle(d)
        return
    end
    self._lastClick = t
    if self.sel ~= d.modId then self.dscroll = 0; MM.hoverSound() end
    self.sel = d.modId
    self.focusId = "mrow:" .. d.modId
end

function ZeD_MMMods:drawDetail(x, y, w, h)
    local T = ZeD.T
    local bs = T.borderS
    self:drawRectBorder(x, y, w, h, bs.a, bs.r, bs.g, bs.b)
    local pad = T.px(DETAIL_PAD)
    local ix, iw = x + pad, w - pad * 2
    -- the note band: what the last toggle or preset did
    local top = y
    if self.note and MM.now() < self.note.untilMs then
        local f2 = T.fontF2
        local lines = ZeD.Atoms.wrapText(self.note.text, f2, iw - T.px(14))
        local nh = #lines * (MM.fontH(f2) + T.px(2)) + T.px(12)
        local s2 = T.surf2
        self:drawRect(x + T.px(1), y + T.px(1), w - T.px(2), nh, 1, s2.r, s2.g, s2.b)
        self:drawRect(x + T.px(1), y + nh, w - T.px(2), T.px(1), bs.a, bs.r, bs.g, bs.b)
        local dsz = T.px(7)
        ZeD.Atoms.drawStatusDot(self, ix, y + T.px(6) + math.floor((MM.fontH(f2) - dsz) / 2), T.accent, dsz)
        local ly = y + T.px(6)
        local c = T.text
        for _, l in ipairs(lines) do
            self:drawText(l, ix + dsz + T.px(7), ly, c.r, c.g, c.b, c.a or 1, f2)
            ly = ly + MM.fontH(f2) + T.px(2)
        end
        top = y + nh + T.px(1)
    end
    local d = self:selected()
    if not d then
        if self.filter == "ws" and self.wsSel and MS.ws.items[self.wsSel] then self:drawWsDetail(x, top, w, y + h - top) end
        return
    end
    local m = model()
    local info = d.modInfo
    local vy, vh = top, y + h - top
    self._detail = { x = x, y = vy, w = w, h = vh }
    self:setStencilRect(x + T.px(1), vy + T.px(1), w - T.px(2), vh - T.px(2))
    local cy = vy + pad - self.dscroll
    -- the picture, then the name, author, the verbs
    local psz = T.px(POSTER)
    local ptex = nil
    pcall(function() if info:getPosterCount() > 0 then ptex = getTexture(info:getPoster(0)) end end)
    local tx = ix
    if ptex then
        self:drawTextureScaledAspect(ptex, ix, cy, psz, psz, 1, 1, 1, 1)
        self:drawRectBorder(ix, cy, psz, psz, bs.a, bs.r, bs.g, bs.b)
        tx = ix + psz + T.px(12)
    end
    local tw = ix + iw - tx
    local hf = ZeD.Font.sdf.head
    local z = 20 * (T.scale or 1) / (hf.face or 64)
    local nameLines = ZeD.Atoms.wrapText(tostring(d.name), T.fontF4, tw)
    local tc = T.textHead
    local ny = cy
    local bigH = math.floor(ZeD.Text.height(hf, z))
    for i, l in ipairs(nameLines) do
        if i > 2 then break end
        ZeD.Text.draw(self, hf, l, tx, ny, z, tc.r, tc.g, tc.b, tc.a or 1, "l")
        ny = ny + bigH
    end
    local author = ""
    pcall(function() author = tostring(info:getAuthor() or "") end)
    local f2, f1 = T.fontF2, T.fontF1
    if author ~= "" then
        local dc = T.textDim
        self:drawText(ZeD.Atoms.truncateText(ZeD.tr("UI_ZeD_Mods_By", author), f2, tw), tx, ny + T.px(2), dc.r, dc.g, dc.b, dc.a or 1, f2)
        ny = ny + MM.fontH(f2) + T.px(4)
    end
    -- the verbs for this mod (the card's header verbs)
    local prob = self:problem(d)
    local by = ny + T.px(8)
    local bh = T.px(U.STRIP_BTN_H)
    local bx = tx
    local function verb(id, text, fn, variant, disabled)
        local bw = MM.textW(T.fontF3, text) + T.px(U.STRIP_BTN_PAD) * 2
        if bx + bw > tx + tw and bx > tx then bx = tx; by = by + bh + T.px(6) end
        self._specs[#self._specs + 1] = { id = id, text = text, fn = fn, variant = variant or "default", disabled = disabled,
                                          row = 500, col = #self._specs + 1, x = bx, y = by, w = bw, h = bh, clipTop = vy, clipBot = vy + vh }
        bx = bx + bw + T.px(6)
    end
    verb("toggle", ZeD.tr(d.isActive and "ContextMenu_Turn_Off" or "ContextMenu_Turn_On"), function() self:toggle(d) end, d.isActive and "default" or "primary", (not d.isActive) and prob ~= nil)
    verb("fav", ZeD.tr(d.favorite and "UI_ZeD_Mods_VerbUnfavourite" or "UI_ZeD_Mods_VerbFavourite"), function() self:toggleFav(d) end)
    local wid, src, url = nil, "", ""
    pcall(function() wid = info:getWorkshopID(); src = tostring(info:getSource() or ""); url = tostring(info:getUrl() or "") end)
    if wid and wid ~= "" then verb("workshop", ZeD.tr("UI_ZeD_Workshop_OpenInSteam"), function() MS.openInSteam(wid) end) end
    if url ~= "" then verb("homepage", ZeD.tr("Homepage"), function() openUrl(url) end) end
    cy = math.max(cy + (ptex and psz or 0), by + bh) + T.px(12)
    -- what is wrong, as vanilla knows it
    if prob then
        local dsz = T.px(7)
        ZeD.Atoms.drawStatusDot(self, ix, cy + math.floor((MM.fontH(f2) - dsz) / 2), T.danger, dsz)
        local c = T.text
        for _, l in ipairs(ZeD.Atoms.wrapText(prob, f2, iw - dsz - T.px(7))) do
            self:drawText(l, ix + dsz + T.px(7), cy, c.r, c.g, c.b, c.a or 1, f2)
            cy = cy + MM.fontH(f2) + T.px(2)
        end
        cy = cy + T.px(6)
    end
    -- the facts
    local kvH = T.px(KV_ROW_H)
    local vx = ix + T.px(KV_LABEL_W)
    local vw = ix + iw - vx
    local function kv(label, value)
        if not value or value == "" then return end
        local la = T.accent
        self:drawText(label, ix, cy + math.floor((kvH - MM.fontH(f1)) / 2), la.r, la.g, la.b, la.a or 1, f1)
        local c = T.text
        self:drawText(ZeD.Atoms.truncateText(value, f2, vw), vx, cy + math.floor((kvH - MM.fontH(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
        cy = cy + kvH
    end
    local ver, vmin, vmax = "", "", ""
    pcall(function() ver = tostring(info:getModVersion() or "") end)
    pcall(function() local v = info:getVersionMin(); if v then vmin = v:toString() end end)
    pcall(function() local v = info:getVersionMax(); if v then vmax = v:toString() end end)
    kv(ZeD.upper(ZeD.tr("Version")), ver)
    if vmin ~= "" or vmax ~= "" then kv(ZeD.tr("UI_ZeD_Mods_KvGame"), ZeD.tr("UI_ZeD_Mods_VersionRange", vmin ~= "" and vmin or ZeD.tr("UI_ZeD_Mods_Any"), vmax ~= "" and vmax or ZeD.tr("UI_ZeD_Mods_Any"))) end
    kv(ZeD.upper(ZeD.tr("ModID")), tostring(d.modId))
    -- what Steam is doing with it, and where it loads
    local it = MS.wsFor(info)
    local updatedNow = it and MS.ws.updatedNow[it.id] and MS.isLoaded(d.modId)
    if it then
        local bits = { updatedNow and ZeD.tr("UI_ZeD_Mods_UpdatedWhileRan") or MS.wsText(it.state) }
        local ago = MS.ago(it.updated)
        if ago ~= "" and not updatedNow then bits[#bits + 1] = ZeD.tr("UI_ZeD_Mods_UpdatedAgoLower", ago) end
        local sz = MS.size(it.size)
        if sz ~= "" then bits[#bits + 1] = sz end
        kv(ZeD.upper(ZeD.tr("UI_mainscreen_workshop")), table.concat(bits, " | "))
    end
    if wid and wid ~= "" then kv(ZeD.upper(ZeD.tr("WorkshopID")), tostring(wid)) end
    if d.isActive then
        local order = jlist(m:getActiveMods():getMods())
        for i, id in ipairs(order) do if id == d.modId then kv(ZeD.tr("UI_ZeD_Mods_KvLoadOrder"), ZeD.tr("UI_ZeD_Mods_OrderOf", i, #order)) end end
    end
    kv(ZeD.tr("UI_ZeD_Mods_KvType"), (d.category and d.category ~= "") and (getTextOrNull(d.category) or d.category) or nil)
    kv(ZeD.tr("UI_ZeD_Mods_KvReplaces"), MS.overrideText(d.modId))
    if updatedNow then
        cy = cy + T.px(4)
        local c = T.text
        local dsz = T.px(7)
        ZeD.Atoms.drawStatusDot(self, ix, cy + math.floor((MM.fontH(f2) - dsz) / 2), T.accent, dsz)
        for _, l in ipairs(ZeD.Atoms.wrapText(ZeD.tr("UI_ZeD_Mods_UpdatedNote"), f2, iw - dsz - T.px(7))) do
            self:drawText(l, ix + dsz + T.px(7), cy, c.r, c.g, c.b, c.a or 1, f2)
            cy = cy + MM.fontH(f2) + T.px(2)
        end
        cy = cy + T.px(4)
    end
    -- what it needs and what it cannot run with, each with its state
    local function idList(label, ids, wantOn)
        if #ids == 0 then return end
        cy = cy + T.px(4)
        local la = T.accent
        self:drawText(label, ix, cy, la.r, la.g, la.b, la.a or 1, f1)
        cy = cy + kvH
        for _, id in ipairs(ids) do
            local r = m.mods[id]
            local color, state
            if not r then color, state = T.danger, "UI_ZeD_Mods_ListNotInstalled"
            elseif r.isActive then color, state = (wantOn and T.positive or T.danger), "UI_ZeD_Mods_ListOn"
            else color, state = T.textDim, "UI_ZeD_Mods_ListOff" end
            local dsz = T.px(7)
            ZeD.Atoms.drawStatusDot(self, ix + T.px(4), cy + math.floor((MM.fontH(f2) - dsz) / 2), color, dsz)
            local c = T.text
            self:drawText(ZeD.Atoms.truncateText(ZeD.tr(state, r and r.name or id), f2, iw - T.px(20)), ix + T.px(16), cy, c.r, c.g, c.b, c.a or 1, f2)
            cy = cy + MM.fontH(f2) + T.px(4)
        end
    end
    idList(ZeD.tr("UI_ZeD_Mods_ListNeeds"), jlist(info:getRequire()), true)
    local inc = {}
    for id in pairs(d.incompatibleWith or {}) do inc[#inc + 1] = id end
    table.sort(inc)
    idList(ZeD.tr("UI_ZeD_Mods_ListCannotWith"), inc, false)
    cy = self:drawConflicts(d, ix, iw, cy, vy, vh)
    -- the description
    local desc = ""
    pcall(function() desc = MM.ui.plain(info:getDescription() or "") end)
    if desc ~= "" then
        cy = cy + T.px(8)
        local c = T.text
        for _, l in ipairs(ZeD.Atoms.wrapText(desc, f2, iw)) do
            self:drawText(l, ix, cy, c.r, c.g, c.b, c.a or 1, f2)
            cy = cy + MM.fontH(f2) + T.px(3)
        end
    end
    self:clearStencilRect()
    -- the pane scrolls as one unit when it runs long
    local contentH = cy + self.dscroll - vy + pad
    self._detail.contentH = contentH
    self.dscroll = math.max(0, math.min(self.dscroll, math.max(0, contentH - vh)))
end

-- wrapped text in the detail pane; returns the y under it
function ZeD_MMMods:paneText(text, x, cy, w, font, color)
    local T = ZeD.T
    for _, l in ipairs(ZeD.Atoms.wrapText(text, font, w)) do
        self:drawText(l, x, cy, color.r, color.g, color.b, color.a or 1, font)
        cy = cy + MM.fontH(font) + T.px(2)
    end
    return cy
end

-- a row of buttons in the detail pane (clipped with it); returns the y under them
function ZeD_MMMods:paneVerbs(list, x, cy, w, vy, vh, row)
    local T = ZeD.T
    local bh = T.px(U.STRIP_BTN_H)
    local bx = x
    for i, v in ipairs(list) do
        local bw = MM.textW(T.fontF3, ZeD.btnCase(v[2])) + T.px(U.STRIP_BTN_PAD) * 2
        if bx + bw > x + w and bx > x then bx = x; cy = cy + bh + T.px(6) end
        self._specs[#self._specs + 1] = { id = v[1], text = v[2], fn = v[3], variant = v[4] or "default", row = row, col = i,
                                          x = bx, y = cy, w = bw, h = bh, clipTop = vy, clipBot = vy + vh }
        bx = bx + bw + T.px(6)
    end
    return cy + bh
end

-- what a name looks like inside a button (long names are cut)
local function shortName(n)
    n = tostring(n)
    if string.len(n) > 22 then n = string.sub(n, 1, 20) .. "..." end
    return n
end

-- the CONFLICTS section: each conflict ZeD_ModScan found, who wins and why, and the fix
function ZeD_MMMods:drawConflicts(d, ix, iw, cy, vy, vh)
    local T = ZeD.T
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local loaded = MS.isLoaded(d.modId)
    if not d.isActive and not loaded then return cy end
    local m = model()
    local list = loaded and MS.forMod(d.modId) or {}
    cy = cy + T.px(4)
    local la, dim, txt, head = T.accent, T.textDim, T.text, T.textHead
    local kvH = T.px(KV_ROW_H)
    local head1 = ZeD.tr("UI_ZeD_Mods_ConflictsHead")
    self:drawText(head1, ix, cy, la.r, la.g, la.b, la.a or 1, f1)
    if #list > 0 then
        local lw = MM.textW(f1, head1)
        self:drawText(tostring(#list), ix + lw + T.px(8), cy, dim.r, dim.g, dim.b, dim.a or 1, f1)
    end
    cy = cy + kvH
    if not loaded then return self:paneText(ZeD.tr("UI_ZeD_Mods_ConflictsLater"), ix, cy, iw, f2, dim) + T.px(4) end
    if not MS.res.done then return self:paneText(ZeD.tr("UI_ZeD_Mods_ConflictsChecking"), ix, cy, iw, f2, dim) + T.px(4) end
    if #list == 0 then cy = self:paneText(ZeD.tr("UI_ZeD_Mods_ConflictsNone"), ix, cy, iw, f2, dim) end
    local order = {}
    for i, id in ipairs(jlist(m:getActiveMods():getMods())) do order[id] = i end
    local dsz = T.px(7)
    local tx, tw = ix + dsz + T.px(7), iw - dsz - T.px(7)
    for i, e in ipairs(list) do
        local mine = e.loser == d.modId
        local other = mine and e.winner or e.loser
        local win, lose = MS.modName(e.winner), MS.modName(e.loser)
        local many = #e.things > 1
        local title
        if e.kind == "file" then title = many and ZeD.tr("UI_ZeD_Mods_SameFiles", #e.things, MS.modName(other)) or ZeD.tr("UI_ZeD_Mods_SameFile", MS.modName(other))
        else
            local kinds = {}
            for noun in pairs(e.nouns) do kinds[#kinds + 1] = noun end
            table.sort(kinds)
            local k1 = MS.kindOf(kinds[1])
            if not many then title = ZeD.tr(k1 and k1.sameOne or "UI_ZeD_Mods_SameDefinition", MS.modName(other))
            elseif #kinds == 1 and k1 then title = ZeD.tr(k1.same, #e.things, MS.modName(other))
            else title = ZeD.tr("UI_ZeD_Mods_SameDefinitions", #e.things, MS.modName(other)) end
        end
        ZeD.Atoms.drawStatusDot(self, ix, cy + math.floor((MM.fontH(f2) - dsz) / 2), T.warning, dsz)
        cy = self:paneText(title, tx, cy, tw, f2, head)
        cy = self:paneText(many and ZeD.tr("UI_ZeD_Mods_AndMore", MS.thingText(e.things[1]), #e.things - 1) or MS.thingText(e.things[1]), tx, cy, tw, f3, dim) + T.px(2)
        -- who wins, and whether that is on purpose (the winner needs the other: a patch for it)
        local needs = false
        local winInfo = getModInfoByID(e.winner)
        for _, r in ipairs(jlist(winInfo and winInfo:getRequire())) do if r == e.loser then needs = true end end
        -- (scripts are read in file-name order across every mod, not in load order: tested on
        -- 42.21.0, so moving a mod cannot change who wins an item or a recipe)
        local why
        if e.kind == "file" then why = ZeD.tr("UI_ZeD_Mods_WhyFile", win, lose)
        else why = ZeD.tr(many and "UI_ZeD_Mods_WhyScriptMany" or "UI_ZeD_Mods_WhyScriptOne", win) end
        local fixed = e.kind == "file" and order[e.loser] and order[e.winner] and order[e.loser] > order[e.winner]
        if needs then why = why .. " " .. ZeD.tr("UI_ZeD_Mods_WhyNeeds", win, lose)
        elseif fixed then why = why .. " " .. ZeD.tr("UI_ZeD_Mods_WhyFixed", lose) end
        cy = self:paneText(why, tx, cy, tw, f2, txt) + T.px(6)
        local verbs = {}
        if e.kind == "file" and mine and not needs and not fixed and d.isActive then
            verbs[#verbs + 1] = { "cf:after:" .. i, ZeD.tr("UI_ZeD_Mods_VerbLoadAfter", shortName(lose)), function() self:loadAfter(e.loser, e.winner) end }
        end
        verbs[#verbs + 1] = { "cf:hide:" .. i, ZeD.tr("UI_ZeD_Mods_VerbHide"), function() MS.hide(e); self:dirty(); MM.clickSound() end }
        cy = self:paneVerbs(verbs, tx, cy, tw, vy, vh, 600 + i) + T.px(10)
    end
    local hid = MS.hiddenFor(d.modId)
    if hid > 0 then
        cy = self:paneText(ZeD.tr(hid == 1 and "UI_ZeD_Mods_HiddenOne" or "UI_ZeD_Mods_HiddenMany", hid), ix, cy, iw, f2, dim) + T.px(4)
        cy = self:paneVerbs({ { "cf:unhide", ZeD.tr("UI_ZeD_Mods_VerbShowAgain"), function() MS.unhideFor(d.modId); self:dirty(); MM.clickSound() end } }, ix, cy, iw, vy, vh, 699) + T.px(8)
    end
    return cy
end

-- the Workshop tab's item that brought no installed mod (not fetched yet, a collection, a map pack)
function ZeD_MMMods:drawWsDetail(x, vy, w, vh)
    local T = ZeD.T
    local it = MS.ws.items[self.wsSel]
    if not it then return end
    local pad = T.px(DETAIL_PAD)
    local ix, iw = x + pad, w - pad * 2
    self._detail = { x = x, y = vy, w = w, h = vh }
    self:setStencilRect(x + T.px(1), vy + T.px(1), w - T.px(2), vh - T.px(2))
    local cy = vy + pad - self.dscroll
    local hf = ZeD.Font.sdf.head
    local z = 20 * (T.scale or 1) / (hf.face or 64)
    local tc = T.textHead
    local bigH = math.floor(ZeD.Text.height(hf, z))
    for i, l in ipairs(ZeD.Atoms.wrapText(it.title, T.fontF4, iw)) do
        if i > 2 then break end
        ZeD.Text.draw(self, hf, l, ix, cy, z, tc.r, tc.g, tc.b, tc.a or 1, "l")
        cy = cy + bigH
    end
    cy = self:paneVerbs({ { "workshop", ZeD.tr("UI_ZeD_Workshop_OpenInSteam"), function() MS.openInSteam(it.id) end } }, ix, cy + T.px(8), iw, vy, vh, 500) + T.px(12)
    local f1, f2 = T.fontF1, T.fontF2
    local kvH = T.px(KV_ROW_H)
    local vx = ix + T.px(KV_LABEL_W)
    local function kv(label, value)
        if not value or value == "" then return end
        local la, c = T.accent, T.text
        self:drawText(label, ix, cy + math.floor((kvH - MM.fontH(f1)) / 2), la.r, la.g, la.b, la.a or 1, f1)
        self:drawText(ZeD.Atoms.truncateText(value, f2, ix + iw - vx), vx, cy + math.floor((kvH - MM.fontH(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
        cy = cy + kvH
    end
    kv(ZeD.upper(ZeD.tr("UI_mainscreen_workshop")), it.children > 0 and ZeD.tr("UI_ZeD_Mods_WsCollection", it.children) or MS.wsText(it.state))
    local ago = MS.ago(it.updated)
    if ago ~= "" then kv(ZeD.tr("UI_ZeD_Mods_KvUpdated"), ago) end
    kv(ZeD.tr("UI_ZeD_Mods_KvSize"), MS.size(it.size))
    kv(ZeD.upper(ZeD.tr("WorkshopID")), it.id)
    local why
    if it.children > 0 then why = ZeD.tr("UI_ZeD_Mods_WhyCollection")
    elseif it.state == "missing" then why = ZeD.tr("UI_ZeD_Mods_WhyMissing")
    elseif it.state == "update" or it.state == "downloading" or it.state == "queued" then why = ZeD.tr("UI_ZeD_Mods_WhyFetching")
    else why = ZeD.tr("UI_ZeD_Mods_WhyNoMod") end
    cy = self:paneText(why, ix, cy + T.px(8), iw, f2, T.text)
    self:clearStencilRect()
    local contentH = cy + self.dscroll - vy + pad
    self._detail.contentH = contentH
    self.dscroll = math.max(0, math.min(self.dscroll, math.max(0, contentH - vh)))
end

-- the load / map order list
function ZeD_MMMods:drawOrder(x, y, w, h)
    local T = ZeD.T
    local m = model()
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local f2, f3, f1 = T.fontF2, T.fontF3, T.fontF1
    local listW = math.floor(w * 0.55)
    UI.insetBox(self, x, y, listW, h)
    local states, firstBad = {}, nil
    if self.page == "order" then states, firstBad = self:orderStates() end
    local rh = T.px(32)
    local rowsH = #self.order * rh
    local vy, vh = y + T.px(1), h - T.px(2)
    self.scroll = math.max(0, math.min(self.scroll, math.max(0, rowsH - vh)))
    self._list = { x = x, y = vy, w = listW, h = vh }
    local gp = MM.gamepad()
    local ac = T.accent
    self:setStencilRect(x + T.px(1), vy, listW - T.px(2), vh)
    for i, id in ipairs(self.order) do
        local ry = vy + (i - 1) * rh - self.scroll
        local rid = "orow:" .. i
        self._specs[#self._specs + 1] = { id = rid, listRow = true, row = i, col = 1, index = i, ry = (i - 1) * rh, rh = rh }
        if ry + rh > vy and ry < vy + vh then
            if gp and self.focusId == rid then self:drawRect(x + T.px(1), ry, listW - T.px(2), rh, 0.55, ac.r, ac.g, ac.b)
            elseif i == self.oSel then self:drawRect(x + T.px(1), ry, listW - T.px(2), rh, 0.22, ac.r, ac.g, ac.b) end
            self:drawRect(x + T.px(1), ry + rh - T.px(1), listW - T.px(2), T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
            local d3 = T.textDim
            self:drawText(tostring(i), x + T.px(10), ry + math.floor((rh - MM.fontH(f3)) / 2), d3.r, d3.g, d3.b, d3.a or 1, f3)
            local nx = x + T.px(44)
            if self.page == "order" then
                local s = states[i]
                local col = (s == "bad" and T.danger) or (s == "soft" and T.warning) or T.positive
                local dsz = T.px(7)
                ZeD.Atoms.drawStatusDot(self, nx, ry + math.floor((rh - dsz) / 2), col, dsz)
                nx = nx + dsz + T.px(8)
            end
            local name = (self.page == "order" and m and m.mods[id]) and m.mods[id].name or id
            local c = T.textHead
            self:drawText(ZeD.Atoms.truncateText(tostring(name), f2, x + listW - T.px(12) - nx), nx, ry + math.floor((rh - MM.fontH(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
            local cy0, ch = math.max(ry, vy), math.min(ry + rh, vy + vh) - math.max(ry, vy)
            self._hits[#self._hits + 1] = { id = "mods:orow:" .. i, x = ax + x, y = ay + cy0, w = listW, h = ch, fn = function()
                self.oSel = i; self.focusId = rid; MM.hoverSound() end }
        end
    end
    self:clearStencilRect()
    -- the selected entry's rules and the move buttons, in a framed pane like the detail pane
    local px0, pw0 = x + listW + T.px(12), w - listW - T.px(12)
    local bs = T.borderS
    self:drawRectBorder(px0, y, pw0, h, bs.a, bs.r, bs.g, bs.b)
    local rx = px0 + T.px(DETAIL_PAD)
    local rw = pw0 - T.px(DETAIL_PAD) * 2
    local cy = y + T.px(DETAIL_PAD)
    local f = T.fontF2
    local c = T.text
    local function line(text, color)
        for _, l in ipairs(ZeD.Atoms.wrapText(text, f, rw - T.px(16))) do
            if color then
                local dsz = T.px(7)
                ZeD.Atoms.drawStatusDot(self, rx, cy + math.floor((MM.fontH(f) - dsz) / 2), color, dsz)
            end
            self:drawText(l, rx + (color and T.px(14) or 0), cy, c.r, c.g, c.b, c.a or 1, f)
            cy = cy + MM.fontH(f) + T.px(3)
            color = nil
        end
    end
    local bh = T.px(U.STRIP_BTN_H)
    local bx = rx
    local function btn(id, text, fn, disabled)
        local bw = MM.textW(T.fontF3, text) + T.px(U.STRIP_BTN_PAD) * 2
        self._specs[#self._specs + 1] = { id = id, text = text, fn = fn, variant = "default", disabled = disabled, row = 500, col = #self._specs + 1, x = bx, y = cy, w = bw, h = bh }
        bx = bx + bw + T.px(6)
    end
    btn("up", ZeD.tr("UI_ServerSettings_ButtonMoveUp"), function() self:move(-1) end, (self.oSel or 1) <= 1)
    btn("down", ZeD.tr("UI_ServerSettings_ButtonMoveDown"), function() self:move(1) end, (self.oSel or 1) >= #self.order)
    cy = cy + bh + T.px(14)
    local sel = self.order[self.oSel or 1]
    if self.page == "order" then
        local d = sel and m and m.mods[sel]
        if d then
            local la = T.accent
            self:drawText(ZeD.upper(tostring(d.name)), rx, cy, la.r, la.g, la.b, la.a or 1, f1)
            cy = cy + T.px(20)
            local function names(ids)
                local t = {}
                for _, i2 in ipairs(ids) do t[#t + 1] = (m.mods[i2] and m.mods[i2].name) or i2 end
                return table.concat(t, ", ")
            end
            local req, after, before = jlist(d.modInfo:getRequire()), jlist(d.modInfo:getLoadAfter()), jlist(d.modInfo:getLoadBefore())
            if #req > 0 then line(ZeD.tr("UI_ZeD_Mods_RuleNeeds", names(req))) end
            if #after > 0 then line(ZeD.tr("UI_ZeD_Mods_RuleAfter", names(after))) end
            if #before > 0 then line(ZeD.tr("UI_ZeD_Mods_RuleBefore", names(before))) end
            if #req + #after + #before == 0 then line(ZeD.tr("UI_ZeD_Mods_RuleNone")) end
            local s = states[self.oSel or 1]
            cy = cy + T.px(6)
            if s == "bad" then line(ZeD.tr("UI_ZeD_Mods_RuleBad"), T.danger)
            elseif s == "soft" then line(ZeD.tr("UI_ZeD_Mods_RuleSoft"), T.warning) end
        end
        cy = cy + T.px(10)
        if firstBad then line(ZeD.tr("UI_ZeD_Mods_RuleFix"), T.danger) end
    else
        local la = T.accent
        self:drawText(ZeD.upper(tostring(sel or "")), rx, cy, la.r, la.g, la.b, la.a or 1, f1)
        cy = cy + T.px(20)
        local conf = {}
        pcall(function() conf = jlist(m:getMapConflicts(sel)) end)
        if #conf > 0 then line(ZeD.tr("UI_ZeD_Mods_MapShares", table.concat(conf, ", "))) end
        line(ZeD.tr("UI_ZeD_Mods_MapRule"))
    end
end

-- the Profiles page: the profiles on the left, what loading the picked one would do on the right
function ZeD_MMMods:drawProfiles(x, y, w, h)
    local T = ZeD.T
    local m = model()
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local listW = math.floor(w * 0.42)
    UI.insetBox(self, x, y, listW, h)
    local list = self:profiles()
    local rh = T.px(ROW_H)
    local rowsH = #list * rh
    local vy, vh = y + T.px(1), h - T.px(2)
    self.scroll = math.max(0, math.min(self.scroll, math.max(0, rowsH - vh)))
    self._list = { x = x, y = vy, w = listW, h = vh }
    local gp = MM.gamepad()
    local ac = T.accent
    local selP = list[1]
    for _, p in ipairs(list) do if p.name == self.psel then selP = p end end
    self:setStencilRect(x + T.px(1), vy, listW - T.px(2), vh)
    for i, p in ipairs(list) do
        local ry = vy + (i - 1) * rh - self.scroll
        local rid = "prow:" .. i
        self._specs[#self._specs + 1] = { id = rid, listRow = true, row = i, col = 1, pname = p.name or false, ry = (i - 1) * rh, rh = rh,
                                          fn = function() self:loadProfile(p) end }
        if ry + rh > vy and ry < vy + vh then
            if gp and self.focusId == rid then self:drawRect(x + T.px(1), ry, listW - T.px(2), rh, 0.55, ac.r, ac.g, ac.b)
            elseif p == selP then self:drawRect(x + T.px(1), ry, listW - T.px(2), rh, 0.22, ac.r, ac.g, ac.b) end
            self:drawRect(x + T.px(1), ry + rh - T.px(1), listW - T.px(2), T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
            local diff = self:profileDiff(p)
            -- status dot: the accent for the profile in use, red when mods are missing
            local dsz = T.px(7)
            local nx = x + T.px(12)
            local dotC = (p.name and diff.inUse and T.accent) or ((#diff.missing + #diff.cannot > 0) and T.danger) or nil
            if dotC then ZeD.Atoms.drawStatusDot(self, nx, ry + T.px(5) + math.floor((MM.fontH(f2) - dsz) / 2), dotC, dsz) end
            nx = nx + dsz + T.px(8)
            local maxW = x + listW - T.px(10) - nx
            local nc = T.textHead
            self:drawText(ZeD.Atoms.truncateText(p.label, f2, maxW), nx, ry + T.px(5), nc.r, nc.g, nc.b, nc.a or 1, f2)
            local sub
            if not p.name then sub = ZeD.tr("UI_ZeD_Mods_ProfEveryOff")
            else
                local one = diff.count == 1
                if diff.inUse then sub = ZeD.tr(one and "UI_ZeD_Mods_ProfCountOneOn" or "UI_ZeD_Mods_ProfCountManyOn", diff.count)
                elseif #diff.missing > 0 then sub = ZeD.tr(one and "UI_ZeD_Mods_ProfCountOneMissing" or "UI_ZeD_Mods_ProfCountManyMissing", diff.count, #diff.missing)
                else sub = ZeD.tr(one and "UI_ZeD_Mods_ProfCountOne" or "UI_ZeD_Mods_ProfCountMany", diff.count) end
            end
            local d = T.textDim
            self:drawText(ZeD.Atoms.truncateText(sub, f3, maxW), nx, ry + rh - T.px(5) - MM.fontH(f3), d.r, d.g, d.b, d.a or 1, f3)
            local cy0, ch = math.max(ry, vy), math.min(ry + rh, vy + vh) - math.max(ry, vy)
            self._hits[#self._hits + 1] = { id = "mods:prow:" .. i, x = ax + x, y = ay + cy0, w = listW, h = ch, fn = function() self:clickProfile(p, i) end }
        end
    end
    self:clearStencilRect()
    if rowsH > vh then
        local sbW = T.sp.scrollbarW
        local sx = x + listW - T.px(1) - sbW
        ZeD.Atoms.drawScrollTrack(self, sx, vy, sbW, vh)
        local th = math.max(T.px(24), math.floor(vh * vh / rowsH))
        ZeD.Atoms.drawScrollThumb(self, sx, vy + math.floor((vh - th) * self.scroll / (rowsH - vh)), sbW, th, "default")
    end

    -- the picked profile, in a framed pane that scrolls as one unit
    local px0, pw0 = x + listW + T.px(12), w - listW - T.px(12)
    local bs = T.borderS
    self:drawRectBorder(px0, y, pw0, h, bs.a, bs.r, bs.g, bs.b)
    self._detail = { x = px0, y = y, w = pw0, h = h }
    local pad = T.px(DETAIL_PAD)
    local ix, iw = px0 + pad, pw0 - pad * 2
    self:setStencilRect(px0 + T.px(1), y + T.px(1), pw0 - T.px(2), h - T.px(2))
    local cy = y + pad - self.dscroll
    local diff = self:profileDiff(selP)
    local hf = ZeD.Font.sdf.head
    local z = 20 * (T.scale or 1) / (hf.face or 64)
    local tc = T.textHead
    ZeD.Text.draw(self, hf, ZeD.Atoms.truncateText(selP.label, T.fontF4, iw), ix, cy, z, tc.r, tc.g, tc.b, tc.a or 1, "l")
    cy = cy + math.floor(ZeD.Text.height(hf, z)) + T.px(2)
    local dc, c = T.textDim, T.text
    local e = extra(selP.name)
    local facts = {}
    if selP.name then
        facts[#facts + 1] = ZeD.tr(diff.count == 1 and "UI_ZeD_Mods_ProfCountOne" or "UI_ZeD_Mods_ProfCountMany", diff.count)
        if e and e.saved and e.saved ~= "" then facts[#facts + 1] = ZeD.tr("UI_ZeD_Mods_ProfSaved", MM.playedText(e.saved)) end
    else
        facts[#facts + 1] = ZeD.tr("UI_ZeD_Mods_ProfPlain")
    end
    for _, l in ipairs(ZeD.Atoms.wrapText(table.concat(facts, ", "), f2, iw)) do
        self:drawText(l, ix, cy, dc.r, dc.g, dc.b, dc.a or 1, f2)
        cy = cy + MM.fontH(f2) + T.px(2)
    end
    if e and e.used and e.used ~= "" then
        self:drawText(ZeD.tr("UI_ZeD_Mods_ProfLastLoaded", MM.playedText(e.used)), ix, cy, dc.r, dc.g, dc.b, dc.a or 1, f2)
        cy = cy + MM.fontH(f2) + T.px(2)
    end
    cy = cy + T.px(10)
    local dsz = T.px(7)
    local function dotLine(text, color, indent)
        local first = true
        local tx0 = ix + T.px(16) + (indent or 0)
        for _, l in ipairs(ZeD.Atoms.wrapText(text, f2, ix + iw - tx0)) do
            if first and color then ZeD.Atoms.drawStatusDot(self, ix + T.px(2), cy + math.floor((MM.fontH(f2) - dsz) / 2), color, dsz) end
            self:drawText(l, tx0, cy, c.r, c.g, c.b, c.a or 1, f2)
            cy = cy + MM.fontH(f2) + T.px(3)
            first = false
        end
    end
    local function label(text)
        local la = T.accent
        self:drawText(text, ix, cy, la.r, la.g, la.b, la.a or 1, f1)
        cy = cy + T.px(KV_ROW_H)
    end
    -- what loading it does
    label(ZeD.tr("UI_ZeD_Mods_ProfLoadingIt"))
    if diff.noChange then
        dotLine(ZeD.tr((#diff.missing + #diff.cannot > 0) and "UI_ZeD_Mods_ProfNothingOnOff" or "UI_ZeD_Mods_ProfNoChange"), T.accent)
    else
        if #diff.on > 0 then
            dotLine(ZeD.tr("UI_ZeD_Mods_ProfTurnsOn", #diff.on), T.positive)
            for _, d in ipairs(diff.on) do dotLine(tostring(d.name), nil, T.px(12)) end
        end
        if #diff.off > 0 then
            dotLine(ZeD.tr("UI_ZeD_Mods_ProfTurnsOff", #diff.off), T.textDim)
            for _, d in ipairs(diff.off) do dotLine(tostring(d.name), nil, T.px(12)) end
        end
    end
    if #diff.missing > 0 then
        dotLine(ZeD.tr("UI_ZeD_Mods_ProfMissing", #diff.missing), T.danger)
        for _, id in ipairs(diff.missing) do dotLine(id, nil, T.px(12)) end
    end
    if #diff.cannot > 0 then
        dotLine(ZeD.tr("UI_ZeD_Mods_ProfCannot", #diff.cannot), T.danger)
        for _, d in ipairs(diff.cannot) do dotLine(ZeD.tr("UI_ZeD_Mods_ProfCannotRow", tostring(d.name), tostring(self:problem(d) or ZeD.tr("UI_ZeD_Mods_ProbCannotLower"))), nil, T.px(12)) end
    end
    -- the load order it keeps
    if selP.name and diff.count > 0 then
        cy = cy + T.px(10)
        label(ZeD.tr("UI_ZeD_Mods_KvLoadOrder"))
        local ids, set = presetIds(m and m.presets[selP.name])
        local order, seen = {}, {}
        for _, id in ipairs(e and e.order or {}) do if set[id] and not seen[id] then order[#order + 1] = id; seen[id] = true end end
        local kept = #order > 0
        if not kept and m then order = ruleOrder(m, ids); for _, id in ipairs(order) do seen[id] = true end end
        for _, id in ipairs(ids) do if not seen[id] then order[#order + 1] = id end end
        local numW = MM.textW(f3, "000")
        for i, id in ipairs(order) do
            local md = m and m.mods[id]
            self:drawText(tostring(i), ix + numW - MM.textW(f3, tostring(i)), cy + math.floor((MM.fontH(f2) - MM.fontH(f3)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f3)
            local nm = md and tostring(md.name) or ZeD.tr("UI_ZeD_Mods_ListNotInstalled", id)
            self:drawText(ZeD.Atoms.truncateText(nm, f2, iw - numW - T.px(10)), ix + numW + T.px(10), cy, c.r, c.g, c.b, c.a or 1, f2)
            cy = cy + MM.fontH(f2) + T.px(3)
        end
        if not kept then
            cy = cy + T.px(4)
            self:drawText(ZeD.tr("UI_ZeD_Mods_ProfSortedByRules"), ix, cy, dc.r, dc.g, dc.b, dc.a or 1, f3)
            cy = cy + MM.fontH(f3)
        end
    end
    self:clearStencilRect()
    local contentH = cy + self.dscroll - y + pad
    self._detail.contentH = contentH
    self.dscroll = math.max(0, math.min(self.dscroll, math.max(0, contentH - h)))
end

-- a click picks the profile; a second click on it soon after loads it
function ZeD_MMMods:clickProfile(p, i)
    local t = MM.now()
    if self.psel == p.name and self._lastPClick and t - self._lastPClick < 450 then
        self._lastPClick = nil
        self:loadProfile(p)
        return
    end
    self._lastPClick = t
    if self.psel ~= p.name then self.dscroll = 0; MM.hoverSound() end
    self.psel = p.name
    self.focusId = "prow:" .. i
end

-- CONTROLLER + KEYS ---------------------------------------------------------------

function ZeD_MMMods:joyDir(dir)
    if FIELD_MODES[self.confirm] then
        if dir == "left" or dir == "right" then ZeD_MMWindow.joyDir(self, dir) end
        return
    end
    ZeD_MMWindow.joyDir(self, dir)
    for _, b in ipairs(self._specs) do
        if b.id == self.focusId and b.listRow then
            if self.page == "list" then
                if b.wsid and self.wsSel ~= b.wsid then self.dscroll = 0 end
                if b.wsid then self.wsSel = b.wsid; self.sel = b.key
                else self.sel = b.key; self.dscroll = 0 end
            elseif self.page == "profiles" then
                if self.psel ~= (b.pname or nil) then self.dscroll = 0 end
                self.psel = b.pname or nil
            else self.oSel = b.index end
            local vh = self._list and self._list.h or 0
            if b.ry < self.scroll then self.scroll = b.ry
            elseif b.ry + b.rh > self.scroll + vh then self.scroll = b.ry + b.rh - vh end
        end
    end
end

function ZeD_MMMods:joyA()
    if (self.page == "order" or self.page == "maps") and (self.focusId or ""):sub(1, 5) == "orow:" then return end   -- a row only picks; X / Y move it
    ZeD_MMWindow.joyA(self)
end
function ZeD_MMMods:joyB()
    if self.confirm then self:setConfirm(false)
    elseif self.page == "profiles" then self:leaveProfiles(); MM.clickSound()
    else self:back() end
end
function ZeD_MMMods:joyX()
    if self.confirm then return end
    if self.page == "profiles" then self:openMore() return end
    if self.page ~= "list" then self:move(1) return end
    self:toggleFav(self:selected())
end
function ZeD_MMMods:joyY()
    if self.confirm then return end
    if self.page == "profiles" then self:setConfirm("save") return end
    if self.page ~= "list" then self:move(-1) return end
    self:enterProfiles()
end
-- LB / RB walk the filter tabs
function ZeD_MMMods:joyBumper(dir)
    if self.page ~= "list" or self.confirm then return end
    local order = self._tabOrder or { "all", "enabled", "favs", "maps", "problems", "conflicts" }
    for i, k in ipairs(order) do
        if k == self.filter then
            local j = math.max(1, math.min(#order, i + dir))
            if j ~= i then self.filter = order[j]; self.scroll = 0; self.focusId = nil; MM.clickSound() end
            return
        end
    end
end

function ZeD_MMMods:getFooterPrompts()
    if not MM.gamepad() then return nil end
    local sel, back = ZeD.tr("UI_ZeD_MainMenu_PromptSelect"), ZeD.btnCase(getText("UI_btn_back"))
    if self.confirm then return { { glyph = "A", label = sel }, { glyph = "B", label = getText("UI_Cancel") } } end
    local f = self.focusId or ""
    if self.page == "profiles" then
        if f:sub(1, 5) == "prow:" then
            return { { glyph = "A", label = ZeD.btnCase(getText("UI_mainscreen_load")) }, { glyph = "Y", label = ZeD.tr("UI_ZeD_Mods_PromptNew") }, { glyph = "X", label = ZeD.tr("UI_ZeD_Saves_More") }, { glyph = "B", label = back } }
        end
        return { { glyph = "A", label = sel }, { glyph = "B", label = back } }
    end
    if self.page ~= "list" then
        return { { glyph = "Y", label = ZeD.tr("UI_ServerSettings_ButtonMoveUp") }, { glyph = "X", label = ZeD.tr("UI_ServerSettings_ButtonMoveDown") }, { glyph = "B", label = back } }
    end
    if f:sub(1, 5) == "mrow:" then
        return { { glyph = "A", label = ZeD.tr("UI_ZeD_Mods_PromptOnOff") }, { glyph = "X", label = ZeD.tr("UI_ZeD_Mods_PromptFavourite") }, { glyph = "Y", label = ZeD.tr("UI_ZeD_Mods_BtnProfiles") }, { glyph = "LB", label = "" }, { glyph = "RB", label = ZeD.tr("UI_ZeD_Mods_PromptFilter") }, { glyph = "B", label = back } }
    end
    if f:sub(1, 5) == "wrow:" then
        return { { glyph = "A", label = ZeD.tr("UI_ZeD_Mods_PromptOnOff") }, { glyph = "LB", label = "" }, { glyph = "RB", label = ZeD.tr("UI_ZeD_Mods_PromptFilter") }, { glyph = "B", label = back } }
    end
    return { { glyph = "A", label = sel }, { glyph = "B", label = back } }
end

function ZeD_MMMods:keyEscape()
    if self.confirm then self:setConfirm(false); return true end
    if self.find:isFocused() then self.find:unfocus(); return true end
    if self.page == "profiles" then self:leaveProfiles(); MM.clickSound(); return true end
    self:back()
    return true
end

function ZeD_MMMods:keyOther(key)
    if key == Keyboard.KEY_RETURN and self._enterAt and MM.now() - self._enterAt < 400 then return true end
    if FIELD_MODES[self.confirm] then
        if key == Keyboard.KEY_RETURN then self:fieldEnter(); return true end
        return false
    end
    if self.find:isFocused() then
        if key == Keyboard.KEY_RETURN then self.find:unfocus(); return true end
        return false
    end
    if self.confirm then return false end
    if key == Keyboard.KEY_RETURN then
        if self.page == "list" then self:accept()
        elseif self.page == "profiles" then self:loadProfile({ name = self.psel })
        else self:leaveOrder(true) end
        return true
    end
    if key == Keyboard.KEY_DELETE and self.page == "profiles" and self.psel then self:setConfirm("delete"); return true end
    if key == Keyboard.KEY_SPACE and self.page == "list" then self:toggle(self:selected()); return true end
    if key == Keyboard.KEY_UP or key == Keyboard.KEY_DOWN then
        if self.page == "list" and self.filter == "ws" then self.focusId = self.wsSel and ("wrow:" .. self.wsSel) or nil
        elseif self.page == "list" then self.focusId = self.sel and ("mrow:" .. self.sel) or nil
        elseif self.page == "profiles" then
            for i, p in ipairs(self:profiles()) do if p.name == self.psel then self.focusId = "prow:" .. i end end
        else self.focusId = "orow:" .. (self.oSel or 1) end
        self:joyDir(key == Keyboard.KEY_UP and "up" or "down")
        return true
    end
    return false
end

function ZeD_MMMods:close() self:back() end

-- the wheel: the list, or the detail pane under the pointer
function ZeD_MMMods:wheel(del)
    local T = ZeD.T
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    local l = self._list
    if l and mx >= l.x and mx <= l.x + l.w and my >= l.y and my <= l.y + l.h then
        self.scroll = self.scroll + del * T.px(ROW_H)
        return true
    end
    local d = self._detail
    if (self.page == "list" or self.page == "profiles") and d and mx >= d.x and mx <= d.x + d.w and my >= d.y and my <= d.y + d.h then
        self.dscroll = self.dscroll + del * T.px(40)
        return true
    end
    return false
end
function ZeD_MMMods:onMouseWheel(del) return MM.wheel(del) end

-- ============================================================================
-- ENTRY POINTS
-- ============================================================================

-- The main menu's MODS (window footer, Settings menu): vanilla's MainScreen MODS item
-- without its last line (which hides the menu).
function MM.openMods()
    local m = ms()
    local inst = ModSelector and ModSelector.instance
    if not (m and inst) or m.delay > 0 then return end
    MM.ctx.open = nil
    inst.model.isNewGame = false
    inst.model.loadGameFolder = nil
    inst.model.isServerSettingsMods = false
    MM.showView("mods")
    inst.model:reloadMods()
    ModSelector.showNagPanel()
    inst.returnToUI = m
end

-- the wheel goes to whichever list view is up
local _wheel = MM.wheel
function MM.wheel(del)
    if MM.view == "mods" and MM.root and MM.root.modsWin then return MM.root.modsWin:wheel(del) end
    return _wheel(del)
end

-- a mod installed or updated while the list is up (a Workshop download): vanilla reloads
-- its list only when its own screen shows, so the monitor's does it
if Events and Events.OnModsModified then
    Events.OnModsModified.Add(function()
        if MM.view == "mods" and MM.root and MM.root:isVisible() then
            local inst = ModSelector and ModSelector.instance
            if inst then inst.model:reloadMods() end
        end
    end)
end
