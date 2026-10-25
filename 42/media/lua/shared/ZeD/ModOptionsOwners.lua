-- ZeD-UI/42/media/lua/shared/ZeD/ModOptionsOwners.lua
-- ============================================================================
-- WHICH MOD MADE WHICH OPTIONS (director, Oct 24 2026: "can the mod manager also
-- show a mods individual settings in that mods info when selected from the list
-- of mods?"; mockup zed_mods_settings_picks_v1)
--
-- A mod makes its options with PZAPI.ModOptions:create(id, name), and the id is
-- the mod's own choice: of 114 subscribed mods with options only 47 used their
-- mod id. So the Mods screen asks who called: the mod folder of the file that
-- called create (the call stack, as ZeD.Messages.caller reads it).
--
-- The wrap has to be in place before any mod's options are made, and vanilla's
-- client/PZAPI/ModOptions.lua builds PZAPI.ModOptions afresh. This file is in
-- shared (every shared file runs before the client ones), so it watches the
-- PZAPI table: when vanilla sets PZAPI.ModOptions, then its create and load,
-- each is wrapped as it lands.
--
-- The wrapped load also notes every option's value the first time the game reads
-- the saved values (ModOptions.ini): before that read the values are the ones the
-- mod declared, its defaults (vanilla keeps none but a key's). The Mods screen's
-- Defaults button puts those back.
--
--   ZeD.ModOptionsOwners.ownerOf(optionsId)  the mod id that made those options, or nil
--   ZeD.ModOptionsOwners.forMod(modId)       that mod's options objects, in vanilla's order
--   ZeD.ModOptionsOwners.default(optionsId, optionId)  the declared value, or nil
-- ============================================================================
ZeD = ZeD or {}
ZeD.ModOptionsOwners = ZeD.ModOptionsOwners or {}
local O = ZeD.ModOptionsOwners
O.byId = O.byId or {}          -- optionsId -> mod id
O.defaults = O.defaults or {}  -- optionsId -> { optionId -> value }

local function safe(fn, ...) local ok, r = pcall(fn, ...); if ok then return r end return nil end
local function norm(p) return ("/" .. tostring(p or "")):gsub("\\", "/"):lower() end
local function rootOf(path)
    local p = norm(path)
    local a, b = p:find("/mods/[^/]+/")
    return a and p:sub(1, b) or nil
end

-- the mod folders of the mods that are on: "/mods/<folder>/" -> mod id
local roots = nil
local function readRoots()
    roots = {}
    local list = safe(function() return getActivatedMods() end)
    for i = 0, (list and list:size() or 0) - 1 do
        local id = list:get(i)
        local mi = safe(function() return getModInfoByID(id) end)
        if mi then
            for _, get in ipairs({ "getDir", "getVersionDir", "getCommonDir" }) do
                local dir = safe(function() return mi[get](mi) end)
                local root = dir and rootOf(tostring(dir) .. "/")
                if root then roots[root] = tostring(id) end
            end
        end
    end
end

local SELF = "modoptionsowners"
-- the mod whose file is calling (ZeD counts: ZeD's own options are ZeD's)
function O.caller()
    if not (getCurrentCoroutine and getCallframeTop and getCoroutineCallframeStack and getFilenameOfCallframe) then return nil end
    if not roots then readRoots() end
    local co = getCurrentCoroutine()
    if not co then return nil end
    local top = getCallframeTop(co) or 0
    for i = top - 1, 0, -1 do
        local cf = getCoroutineCallframeStack(co, i)
        local f = cf and safe(getFilenameOfCallframe, cf)
        if f and not tostring(f):lower():find(SELF, 1, true) then
            local root = rootOf(f)
            if root then return roots[root] end
        end
    end
    return nil
end

local function copy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do if type(x) ~= "function" and type(x) ~= "userdata" then t[k] = x end end
    return t
end

-- every option's value now, for the ones not noted yet (called just before vanilla's load)
local function noteDefaults(mo)
    for _, options in ipairs(rawget(mo, "Data") or {}) do
        local id = options.modOptionsID
        if id ~= nil then
            local d = O.defaults[id] or {}
            O.defaults[id] = d
            for _, opt in ipairs(options.data or {}) do
                if opt.id ~= nil and d[opt.id] == nil then
                    if opt.type == "tickbox" or opt.type == "textentry" or opt.type == "slider" then d[opt.id] = copy(opt.value)
                    elseif opt.type == "combobox" then d[opt.id] = opt.selected
                    elseif opt.type == "colorpicker" then d[opt.id] = copy(opt.color)
                    elseif opt.type == "keybind" then d[opt.id] = opt.defaultkey or opt.key
                    elseif opt.type == "multipletickbox" then
                        local vals = {}
                        for i, v in ipairs(opt.values or {}) do vals[i] = v.value end
                        d[opt.id] = vals
                    end
                end
            end
        end
    end
end

local function wrap(mo, key, fn)
    rawset(mo, key, fn)
    if key == "create" then
        rawset(mo, key, function(self, optionsId, name, ...)
            local owner = safe(O.caller)
            if owner and optionsId ~= nil then O.byId[tostring(optionsId)] = owner end
            return fn(self, optionsId, name, ...)
        end)
    elseif key == "load" then
        rawset(mo, key, function(self, ...)
            pcall(noteDefaults, self)
            return fn(self, ...)
        end)
    end
end

local function watchModOptions(mo)
    if type(mo) ~= "table" or getmetatable(mo) then return end
    for _, k in ipairs({ "create", "load" }) do
        local f = rawget(mo, k)
        if type(f) == "function" then rawset(mo, k, nil); wrap(mo, k, f) end
    end
    setmetatable(mo, { __newindex = function(t, k, v)
        if (k == "create" or k == "load") and type(v) == "function" then wrap(t, k, v) else rawset(t, k, v) end
    end })
end

pcall(function()
    PZAPI = PZAPI or {}
    if rawget(PZAPI, "ModOptions") then watchModOptions(PZAPI.ModOptions); return end
    if getmetatable(PZAPI) then return end
    setmetatable(PZAPI, { __newindex = function(t, k, v)
        rawset(t, k, v)
        if k == "ModOptions" then pcall(watchModOptions, v) end
    end })
end)

-- ----------------------------------------------------------------------------
function O.ownerOf(optionsId)
    return O.byId[tostring(optionsId)]
end

function O.default(optionsId, optionId)
    local d = O.defaults[optionsId]
    return d and d[optionId]
end

-- a mod's options objects: the ones it made, else (not seen being made) one named like the mod
function O.forMod(modId)
    local out = {}
    local mo = PZAPI and PZAPI.ModOptions
    for _, options in ipairs(mo and mo.Data or {}) do
        local id = tostring(options.modOptionsID)
        local owner = O.byId[id]
        if owner == modId or (owner == nil and id == tostring(modId)) then out[#out + 1] = options end
    end
    return out
end
