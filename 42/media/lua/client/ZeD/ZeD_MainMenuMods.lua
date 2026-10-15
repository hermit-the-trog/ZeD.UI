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
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui

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
    if c and MM.now() - c.at < CACHE_MS then return c[1], c[2], c[3], c[4], c[5] end
    local m = model()
    local all, on, favs, maps, probs = 0, 0, 0, 0, 0
    for _, d in ipairs(m and m.sortedMods or {}) do
        all = all + 1
        if d.isActive then on = on + 1 end
        if d.favorite then favs = favs + 1 end
        if d.category == "map" then maps = maps + 1 end
        if self:problem(d) then probs = probs + 1 end
    end
    self._cnt = { all, on, favs, maps, probs, at = MM.now() }
    return all, on, favs, maps, probs
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
        local range = (vmin ~= "" or vmax ~= "") and (" (" .. (vmin ~= "" and vmin or "?") .. " to " .. (vmax ~= "" and vmax or "?") .. ")") or ""
        return "Made for another game version" .. range
    end
    if not d.isAvailable then
        local missing = {}
        for _, id in ipairs(jlist(d.modInfo:getRequire())) do
            local r = m.mods[id]
            if not r then missing[#missing + 1] = id
            elseif not r.isAvailable then missing[#missing + 1] = r.name end
        end
        if #missing > 0 then return "Needs " .. table.concat(missing, ", ") end
        return "Cannot run"
    end
    if d.isIncompatible and not d.isActive then
        local by = {}
        for id in pairs(d.incompatibleWith or {}) do
            local r = m.mods[id]
            if r and r.isActive then by[#by + 1] = r.name end
        end
        return "Conflicts with " .. table.concat(by, ", ")
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
        self:say((turnOn and "Also turned on (needed): " or "Also turned off (needs it): ") .. table.concat(extra, ", "))
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
    m:acceptChanges()        -- Load / New Game land back on the monitor through the redirects
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
    local t = { { name = nil, label = "No mods" } }
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
        self:say("No mods: " .. #diff.off .. " turned off")
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
    if #diff.on > 0 then bits[#bits + 1] = #diff.on .. " turned on" end
    if #diff.off > 0 then bits[#bits + 1] = #diff.off .. " turned off" end
    local msg = "Loaded " .. p.name .. (#bits > 0 and (": " .. table.concat(bits, ", ")) or "")
    if #diff.missing > 0 then msg = msg .. ". Not installed: " .. table.concat(diff.missing, ", ") end
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
    if name == "No mods" then return false end
    return not (m and m.presets[name]) or name == except
end

function ZeD_MMMods:savePreset()          -- NEW...: the strip's field holds the name
    local name = self.field:getText()
    if not self:nameFree(name) then return end
    self:writeProfile(name)
    self:setConfirm(false)
    self:say("Saved " .. name .. " (" .. #(extra(name).order or {}) .. " mods)")
end

function ZeD_MMMods:updateProfile()
    local name = self.psel
    if not name then return end
    self:writeProfile(name)
    self:setConfirm(false)
    self:say("Updated " .. name .. " to the mods on now")
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
        self:say("Renamed " .. old .. " to " .. new)
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
    self:say("Copied " .. old .. " as " .. new)
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
    self:say("Deleted " .. name)
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
    self:say("Copied " .. name .. " to the clipboard as text")
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
            self:say("Added " .. name)
            return
        end
    end
    self:say("Nothing to add: the text is not a profile")
end

function ZeD_MMMods:moreItems()
    local t = {}
    if self.psel then
        t[#t + 1] = { text = "Rename " .. self.psel .. "...", fn = function() self:setConfirm("rename") end }
        t[#t + 1] = { text = "Duplicate " .. self.psel .. "...", fn = function() self:setConfirm("dup") end }
        t[#t + 1] = { text = "Copy as Text", fn = function() self:copyPreset() end }
    end
    t[#t + 1] = { text = "Paste Profile Text...", fn = function() self:setConfirm("paste") end }
    t[#t + 1] = "-"
    t[#t + 1] = { text = "Turn Every Mod On", fn = function() self:setAll(true); self:say("Every mod that can run is on"); self:leaveProfiles() end }
    if self.psel then
        t[#t + 1] = "-"
        t[#t + 1] = { text = "Delete " .. self.psel .. "...", fn = function() self:setConfirm("delete") end }
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
        self:say(self.page == "order" and "Load order set" or "Map order set")
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
        if mode == "rename" then pre = self.psel or "" elseif mode == "dup" then pre = (self.psel or "") .. " copy" end
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
    self._specs, self._hits = {}, {}
    local w, h = UI.placeOnTube(self)
    local all, on = self:counts()
    local section = (self.page == "order" and "Load Order") or (self.page == "maps" and "Map Order") or (self.page == "profiles" and "Mod Profiles") or "Mods"
    local md = model()
    if md and md.isServerSettingsMods then section = "Server " .. section end   -- (a server's mods, from its settings)
    self.title = "Project Zomboid  +  " .. section
    self.titleStats = { { text = on .. " of " .. all .. " on", color = (on > 0) and T.positive or T.textDim } }
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
    UI.drawStripAndButtons(self, self._stripY, self._stripH, self._ask)
    ZeD_Window.render(self)
end

function ZeD_MMMods:buildStrip(stripY, stripH, w)
    local T = ZeD.T
    local row = 1000
    local ask = nil
    local m = model()
    if self.confirm == "back" then
        ask = "Keep the changes to your mods?"
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", "DISCARD", function() self:discard() end },
            { "confirm:yes", "KEEP", function() self:accept() end, "primary" } })
    elseif self.confirm == "template" then
        ask = MM.ui.plain(getText("UI_modselector_modTemplateWarn"))
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", "CANCEL", function() self:setConfirm(false) end },
            { "confirm:yes", "TURN ON", function() local d = self._templateFor; self:setConfirm(false); self:toggle(d, true) end, "primary" } })
    elseif self.confirm == "delete" then
        ask = "Delete the profile " .. tostring(self.psel) .. "?"
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", "CANCEL", function() self:setConfirm(false) end },
            { "confirm:yes", "DELETE", function() self:deletePreset() end, "danger" } })
    elseif self.confirm == "update" then
        local _, on = self:counts()
        ask = "Replace " .. tostring(self.psel) .. " with the " .. on .. (on == 1 and " mod" or " mods") .. " on now?"
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", "CANCEL", function() self:setConfirm(false) end },
            { "confirm:yes", "REPLACE", function() self:updateProfile() end, "primary" } })
    elseif FIELD_MODES[self.confirm] then
        local c = self.confirm
        ask = (c == "save" and "New profile name:") or (c == "rename" and "Rename to:") or (c == "dup" and "Copy as:") or "Profile text:"
        local text = self.field:getText()
        local valid
        if c == "paste" then valid = text and text:find(":", 1, true) ~= nil
        elseif c == "rename" then valid = self:nameFree(text, self.psel)
        else valid = self:nameFree(text) end
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", "CANCEL", function() self:setConfirm(false) end },
            { "confirm:yes", (c == "paste" and "ADD") or (c == "rename" and "RENAME") or "SAVE", function() self:fieldEnter() end, "primary", not valid } })
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
            { { "back", "BACK", function() self:leaveProfiles(); MM.clickSound() end } },
            { { "new", "NEW...", function() self:setConfirm("save") end },
              { "update", "UPDATE...", function() self:setConfirm("update") end, "default", not isUser or inUse },
              { "more", "MORE", function() self:openMore() end },
              { "load", "LOAD", function() self:loadProfile({ name = self.psel }) end, "primary", loadOff } })
    elseif self.page ~= "list" then
        local _, firstBad = self:orderStates()
        UI.stripSpecs(self, stripY, w, row,
            { { "back", "BACK", function() self:leaveOrder(false) end } },
            { { "auto", "AUTO", function() self:autoSort() end, "default", self.page ~= "order" },
              { "done", "DONE", function() self:leaveOrder(true) end, "primary", self.page == "order" and firstBad ~= nil } })
    else
        local mapConflicts = false
        pcall(function() mapConflicts = m and m:checkMapConflicts() or false end)
        local lefts = { { "back", "BACK", function() self:back() end } }
        local rights = {
            { "profiles", "PROFILES", function() self:enterProfiles() end },
            { "order", "LOAD ORDER", function() self:enterOrder("order") end },
        }
        if mapConflicts then rights[#rights + 1] = { "maps", "MAP ORDER", function() self:enterOrder("maps") end } end
        rights[#rights + 1] = { "accept", "ACCEPT", function() self:accept() end, "primary" }
        UI.stripSpecs(self, stripY, w, row, lefts, rights)
    end
    self._stripY, self._stripH, self._ask = stripY, stripH, ask
end

function ZeD_MMMods:drawList(x, y, w, h)
    local T = ZeD.T
    local bs, s2 = T.borderS, T.surf2
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    UI.insetBox(self, x, y, w, h)
    -- the filter tabs (System 7 folder tabs), then Find
    local all, on, favs, maps, probs = self:counts()
    local tabs = { { "all", "All " .. all }, { "enabled", "On " .. on }, { "favs", "Starred " .. favs }, { "maps", "Maps " .. maps }, { "problems", "Problems " .. probs } }
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
    self:drawText("Find:", x + T.px(8), fY + math.floor((fH - MM.fontH(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
    local ex = x + T.px(8) + MM.textW(f2, "Find:") + T.px(8)
    local eh = T.px(24)
    UI.styleEntry(self.find, ex, fY + math.floor((fH - eh) / 2), x + w - T.px(8) - ex, eh)
    self._hits[#self._hits + 1] = { id = "mods:find", x = ax + self.find.x, y = ay + self.find.y, w = self.find.width, h = self.find.height,
                                    fn = function() self.find:focus() end }

    -- the rows
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
        local msg = (self.filter == "favs") and "No favourites yet" or ((self.filter == "problems") and "Every mod can run" or "No mods match")
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
            local maxW = x + rw - T.px(10) - starW - T.px(6) - nx
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
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
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
    if not d then return end
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
    local f2, f1, f3 = T.fontF2, T.fontF1, T.fontF3
    if author ~= "" then
        local dc = T.textDim
        self:drawText(ZeD.Atoms.truncateText("by " .. author, f2, tw), tx, ny + T.px(2), dc.r, dc.g, dc.b, dc.a or 1, f2)
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
    verb("toggle", d.isActive and "TURN OFF" or "TURN ON", function() self:toggle(d) end, d.isActive and "default" or "primary", (not d.isActive) and prob ~= nil)
    verb("fav", d.favorite and "UNFAVOURITE" or "FAVOURITE", function() self:toggleFav(d) end)
    local wid, src, url = nil, "", ""
    pcall(function() wid = info:getWorkshopID(); src = tostring(info:getSource() or ""); url = tostring(info:getUrl() or "") end)
    if wid and wid ~= "" and src == "Steam" then verb("workshop", "WORKSHOP PAGE", function() activateSteamOverlayToWorkshopItem(wid) end) end
    if url ~= "" then verb("homepage", "HOMEPAGE", function() openUrl(url) end) end
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
    kv("VERSION", ver)
    if vmin ~= "" or vmax ~= "" then kv("GAME", (vmin ~= "" and vmin or "any") .. " to " .. (vmax ~= "" and vmax or "any")) end
    kv("MOD ID", tostring(d.modId))
    if wid and wid ~= "" then kv("WORKSHOP", tostring(wid)) end
    kv("TYPE", (d.category and d.category ~= "") and (getTextOrNull(d.category) or d.category) or nil)
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
            if not r then color, state = T.danger, "not installed"
            elseif r.isActive then color, state = (wantOn and T.positive or T.danger), "on"
            else color, state = T.textDim, "off" end
            local dsz = T.px(7)
            ZeD.Atoms.drawStatusDot(self, ix + T.px(4), cy + math.floor((MM.fontH(f2) - dsz) / 2), color, dsz)
            local c = T.text
            self:drawText(ZeD.Atoms.truncateText((r and r.name or id) .. ", " .. state, f2, iw - T.px(20)), ix + T.px(16), cy, c.r, c.g, c.b, c.a or 1, f2)
            cy = cy + MM.fontH(f2) + T.px(4)
        end
    end
    idList("NEEDS", jlist(info:getRequire()), true)
    local inc = {}
    for id in pairs(d.incompatibleWith or {}) do inc[#inc + 1] = id end
    table.sort(inc)
    idList("CANNOT RUN WITH", inc, false)
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
    btn("up", "MOVE UP", function() self:move(-1) end, (self.oSel or 1) <= 1)
    btn("down", "MOVE DOWN", function() self:move(1) end, (self.oSel or 1) >= #self.order)
    cy = cy + bh + T.px(14)
    local sel = self.order[self.oSel or 1]
    if self.page == "order" then
        local d = sel and m and m.mods[sel]
        if d then
            local la = T.accent
            self:drawText(string.upper(tostring(d.name)), rx, cy, la.r, la.g, la.b, la.a or 1, f1)
            cy = cy + T.px(20)
            local function names(ids)
                local t = {}
                for _, i2 in ipairs(ids) do t[#t + 1] = (m.mods[i2] and m.mods[i2].name) or i2 end
                return table.concat(t, ", ")
            end
            local req, after, before = jlist(d.modInfo:getRequire()), jlist(d.modInfo:getLoadAfter()), jlist(d.modInfo:getLoadBefore())
            if #req > 0 then line("Needs, loaded first: " .. names(req)) end
            if #after > 0 then line("Loads after: " .. names(after)) end
            if #before > 0 then line("Loads before: " .. names(before)) end
            if #req + #after + #before == 0 then line("No order rules") end
            local s = states[self.oSel or 1]
            cy = cy + T.px(6)
            if s == "bad" then line("A mod it needs loads after it; DONE waits until it is fixed", T.danger)
            elseif s == "soft" then line("Its load-before / load-after wish is not kept", T.warning) end
        end
        cy = cy + T.px(10)
        if firstBad then line("Fix the red rows (or AUTO) to set the order", T.danger) end
    else
        local la = T.accent
        self:drawText(string.upper(tostring(sel or "")), rx, cy, la.r, la.g, la.b, la.a or 1, f1)
        cy = cy + T.px(20)
        local conf = {}
        pcall(function() conf = jlist(m:getMapConflicts(sel)) end)
        if #conf > 0 then line("Shares map cells with: " .. table.concat(conf, ", ")) end
        line("Maps nearer the top win where they overlap")
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
            if not p.name then sub = "Every mod off"
            else
                sub = diff.count .. (diff.count == 1 and " mod" or " mods")
                if diff.inUse then sub = sub .. ", on now"
                elseif #diff.missing > 0 then sub = sub .. ", " .. #diff.missing .. " not installed" end
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
        facts[#facts + 1] = diff.count .. (diff.count == 1 and " mod" or " mods")
        if e and e.saved and e.saved ~= "" then facts[#facts + 1] = "saved " .. MM.playedText(e.saved) end
    else
        facts[#facts + 1] = "Plain Project Zomboid"
    end
    for _, l in ipairs(ZeD.Atoms.wrapText(table.concat(facts, ", "), f2, iw)) do
        self:drawText(l, ix, cy, dc.r, dc.g, dc.b, dc.a or 1, f2)
        cy = cy + MM.fontH(f2) + T.px(2)
    end
    if e and e.used and e.used ~= "" then
        self:drawText("Last loaded " .. MM.playedText(e.used), ix, cy, dc.r, dc.g, dc.b, dc.a or 1, f2)
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
    label("LOADING IT")
    if diff.noChange then
        dotLine((#diff.missing + #diff.cannot > 0) and "Turns nothing on or off" or "Changes nothing: these are the mods on now", T.accent)
    else
        if #diff.on > 0 then
            dotLine("Turns on " .. #diff.on, T.positive)
            for _, d in ipairs(diff.on) do dotLine(tostring(d.name), nil, T.px(12)) end
        end
        if #diff.off > 0 then
            dotLine("Turns off " .. #diff.off, T.textDim)
            for _, d in ipairs(diff.off) do dotLine(tostring(d.name), nil, T.px(12)) end
        end
    end
    if #diff.missing > 0 then
        dotLine("Not installed " .. #diff.missing .. ": stays off", T.danger)
        for _, id in ipairs(diff.missing) do dotLine(id, nil, T.px(12)) end
    end
    if #diff.cannot > 0 then
        dotLine("Cannot run " .. #diff.cannot .. ": stays off", T.danger)
        for _, d in ipairs(diff.cannot) do dotLine(tostring(d.name) .. " (" .. tostring(self:problem(d) or "cannot run") .. ")", nil, T.px(12)) end
    end
    -- the load order it keeps
    if selP.name and diff.count > 0 then
        cy = cy + T.px(10)
        label("LOAD ORDER")
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
            local nm = md and tostring(md.name) or (id .. ", not installed")
            self:drawText(ZeD.Atoms.truncateText(nm, f2, iw - numW - T.px(10)), ix + numW + T.px(10), cy, c.r, c.g, c.b, c.a or 1, f2)
            cy = cy + MM.fontH(f2) + T.px(3)
        end
        if not kept then
            cy = cy + T.px(4)
            self:drawText("Sorted by the mods' own rules", ix, cy, dc.r, dc.g, dc.b, dc.a or 1, f3)
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
            if self.page == "list" then self.sel = b.key; self.dscroll = 0
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
    local order = { "all", "enabled", "favs", "maps", "problems" }
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
    if self.confirm then return { { glyph = "A", label = "Select" }, { glyph = "B", label = "Cancel" } } end
    local f = self.focusId or ""
    if self.page == "profiles" then
        if f:sub(1, 5) == "prow:" then
            return { { glyph = "A", label = "Load" }, { glyph = "Y", label = "New" }, { glyph = "X", label = "More" }, { glyph = "B", label = "Back" } }
        end
        return { { glyph = "A", label = "Select" }, { glyph = "B", label = "Back" } }
    end
    if self.page ~= "list" then
        return { { glyph = "Y", label = "Move up" }, { glyph = "X", label = "Move down" }, { glyph = "B", label = "Back" } }
    end
    if f:sub(1, 5) == "mrow:" then
        return { { glyph = "A", label = "On / off" }, { glyph = "X", label = "Favourite" }, { glyph = "Y", label = "Profiles" }, { glyph = "LB", label = "" }, { glyph = "RB", label = "Filter" }, { glyph = "B", label = "Back" } }
    end
    return { { glyph = "A", label = "Select" }, { glyph = "B", label = "Back" } }
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
        if self.page == "list" then self.focusId = self.sel and ("mrow:" .. self.sel) or nil
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
