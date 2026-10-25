-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ModSettings.lua
-- ============================================================================
-- A MOD'S OWN SETTINGS FOR ITS INFO PANE (director, Oct 24 2026: "can the mod
-- manager also show a mods individual settings in that mods info when selected
-- from the list of mods?"; mockup zed_mods_settings_picks_v1, approved)
--
-- OPTIONS: the mod's PZAPI.ModOptions (which mod made which: shared/ZeD/
-- ModOptionsOwners.lua). Vanilla's Options builds a control for every option on
-- its Mods page; those controls stay the engine, as in ZeD's Options window. A
-- row here is that window's row (MM.optionRows) found by the option's own
-- control (option.element), in the order the mod declared its options, with
-- its titles and descriptions between. A change is kept at once: the row's
-- GameOption copies the control into the option (vanilla's apply for it), then
-- the mod's own options:apply() and PZAPI.ModOptions:save(), as vanilla's
-- Options would do on Apply, for that mod only.
--
-- SANDBOX: the settings a mod adds to every new game, read from its own
-- media/sandbox-options.txt (so they show while the mod is off), named through
-- the game's text (Sandbox_<translation>) or, for a mod that is off, the mod's
-- own translation file (the player's language, else English).
--
--   S.optionRows(modId)   { sections = { { title, entries } }, count }
--   S.apply(entry)        keep one row's value (after its control changed)
--   S.defaults(modId)     every option back to the value the mod declared
--   S.sig(r)              a row's value as a short string (the changed dot)
--   S.help(entry)         the row's help text, plain
--   S.sandbox(modId)      { list = { setting, ... }, pages = { name, ... } } or nil
--   S.reset()             forget what was read (the Mods screen opens)
-- ============================================================================
require "ZeD/ZeD_MainMenuOptions"
ZeD = ZeD or {}
ZeD.ModSettings = ZeD.ModSettings or {}
local S = ZeD.ModSettings
local MM = ZeD.MainMenu
local OW = ZeD.ModOptionsOwners

local function safe(fn, ...) local ok, r = pcall(fn, ...); if ok then return r end return nil end
local function mo() local m = MainScreen and MainScreen.instance; return m and m.mainOptions end
local function plain(s) return MM.ui and MM.ui.plain(s) or tostring(s or "") end

-- ----------------------------------------------------------------------------
-- OPTIONS
-- ----------------------------------------------------------------------------
local cache = { at = -1e9, rows = nil }

-- vanilla's Mods page rows (the Options window's reading of it), kept two seconds
local function pageRows()
    local now = getTimestampMs()
    if cache.rows and now - cache.at < 2000 then return cache.rows end
    local o = mo()
    local want = getText("UI_mainscreen_mods")
    local rows = {}
    for _, v in ipairs(o and o.tabs and o.tabs.viewList or {}) do
        if v.name == want then rows = MM.optionRows({ view = v.view }) or {} end
    end
    cache.rows, cache.at = rows, now
    return rows
end

local SKIP_TYPE = { title = true, description = true, separator = true }

function S.optionRows(modId)
    local out = { sections = {}, count = 0 }
    if not (OW and PZAPI and PZAPI.ModOptions) then return out end
    local mine = OW.forMod(modId)
    if #mine == 0 then return out end
    local rows = pageRows()
    local byCtl = {}
    for _, r in ipairs(rows) do
        if r.control then byCtl[r.control] = r end
        if r.entry and r.entry.btn then byCtl[r.entry.btn] = r end
    end
    for _, options in ipairs(mine) do
        local sec = { title = getText(tostring(options.name or options.modOptionsID)), options = options, entries = {} }
        for _, opt in ipairs(options.data or {}) do
            if opt.type == "title" then
                sec.entries[#sec.entries + 1] = { kind = "header", text = getText(tostring(opt.name or "")) }
            elseif opt.type == "description" then
                if opt.text and opt.text ~= "" then sec.entries[#sec.entries + 1] = { kind = "note", text = plain(opt.text) } end
            elseif not SKIP_TYPE[opt.type] then
                local el = opt.element
                local r = el and (byCtl[el] or (type(el) == "table" and el.btn and byCtl[el.btn]))
                out.count = out.count + 1
                sec.entries[#sec.entries + 1] = { kind = "opt", r = r, option = opt, options = options,
                    label = getText(tostring(opt.name or opt.id or "")), key = tostring(options.modOptionsID) .. "." .. tostring(opt.id) }
            end
        end
        out.sections[#out.sections + 1] = sec
    end
    return out
end

-- how many options a mod has (0 for a mod that is off: its code never ran)
function S.count(modId)
    local n = 0
    for _, options in ipairs(OW and OW.forMod(modId) or {}) do
        for _, opt in ipairs(options.data or {}) do if not SKIP_TYPE[opt.type] then n = n + 1 end end
    end
    return n
end

-- the value of a row, as the Options window's changed dot compares it
function S.sig(r)
    local c = r and r.control
    if not c then return nil end
    if r.kind == "combo" then return tostring(c.selected)
    elseif r.kind == "tick" then
        local t = {}
        for i = 1, #(c.options or {}) do t[#t + 1] = c.selected[i] and "1" or "0" end
        return table.concat(t)
    elseif r.kind == "slider" then return tostring(c.currentValue)
    elseif r.kind == "color" then local b = c.backgroundColor or {}; return string.format("%.3f%.3f%.3f", b.r or 0, b.g or 0, b.b or 0)
    elseif r.kind == "key" then local e = r.entry; return e and (tostring(e.keyCode) .. tostring(e.shift) .. tostring(e.ctrl)) or nil
    elseif r.kind == "text" then return tostring(safe(function() return c:getText() end))
    end
    return nil
end

-- keep one row: vanilla's apply for its control, the mod's own apply, the save
function S.apply(entry)
    local r = entry and entry.r
    if r and r.opt and r.opt.apply then pcall(r.opt.apply, r.opt) end
    if entry.options and entry.options.apply then pcall(entry.options.apply, entry.options) end
    pcall(function() PZAPI.ModOptions:save() end)
    -- (the change is kept: the Options window must not see it as waiting for Apply)
    local o = mo()
    if o and o.gameOptions then o.gameOptions.changed = false end
end

-- every option of a mod back to the value it declared (keys stay: the Options window sets those)
function S.defaults(modId)
    local any = false
    for _, options in ipairs(OW and OW.forMod(modId) or {}) do
        for _, opt in ipairs(options.data or {}) do
            local d = OW.default(options.modOptionsID, opt.id)
            if d ~= nil and opt.setValue and opt.type ~= "keybind" then
                if opt.type == "multipletickbox" then
                    for i, v in ipairs(d) do if opt.values and opt.values[i] then opt.values[i].value = v end end
                    local el = opt.element
                    if el and el.setSelected then for i, v in ipairs(d) do pcall(el.setSelected, el, i, v) end end
                elseif opt.type == "colorpicker" then
                    pcall(opt.setValue, opt, { r = d.r, g = d.g, b = d.b, a = d.a or 1 })
                    if opt.element then opt.element.backgroundColor = { r = d.r, g = d.g, b = d.b, a = d.a or 1 } end
                else
                    pcall(opt.setValue, opt, d)
                end
                any = true
            end
        end
        if options.apply then pcall(options.apply, options) end
    end
    if any then
        pcall(function() PZAPI.ModOptions:save() end)
        local o = mo()
        if o and o.gameOptions then pcall(function() o.gameOptions:toUI() end); o.gameOptions.changed = false end
    end
    return any
end

-- whether any option of a mod differs from the value it declared
function S.offDefault(modId)
    for _, options in ipairs(OW and OW.forMod(modId) or {}) do
        for _, opt in ipairs(options.data or {}) do
            local d = OW.default(options.modOptionsID, opt.id)
            if d ~= nil and opt.type ~= "keybind" then
                if opt.type == "combobox" then if opt.selected ~= d then return true end
                elseif opt.type == "colorpicker" then
                    local c = opt.color or {}
                    if math.abs((c.r or 0) - (d.r or 0)) > 0.002 or math.abs((c.g or 0) - (d.g or 0)) > 0.002 or math.abs((c.b or 0) - (d.b or 0)) > 0.002 then return true end
                elseif opt.type == "multipletickbox" then
                    for i, v in ipairs(d) do if opt.values and opt.values[i] and opt.values[i].value ~= v then return true end end
                elseif opt.value ~= d then return true end
            end
        end
    end
    return false
end

-- the default as words (the help band's column)
function S.defaultText(entry)
    local opt, options = entry.option, entry.options
    local d = OW and OW.default(options.modOptionsID, opt.id)
    if d == nil then return nil end
    if opt.type == "tickbox" then return ZeD.tr(d and "UI_ZeD_Mods_ValueOn" or "UI_ZeD_Mods_ValueOff") end
    if opt.type == "combobox" then return tostring(opt.values and opt.values[d] or d) end
    if opt.type == "slider" then return (opt.step and opt.step < 1) and string.format("%.2f", d) or tostring(math.floor(d + 0.5)) end
    if opt.type == "textentry" then return tostring(d) end
    if opt.type == "keybind" then return safe(getKeyName, tonumber(d) or 0) end
    return nil
end

function S.help(entry)
    local t = entry.option and entry.option.tooltip
    if t and t ~= "" then return plain(getText(t)) end
    local c = entry.r and entry.r.control
    if c and type(c.tooltip) == "string" and c.tooltip ~= "" then return plain(c.tooltip) end
    return nil
end

-- ----------------------------------------------------------------------------
-- SANDBOX
-- ----------------------------------------------------------------------------
local sb = {}      -- modId -> parsed (false: none)
local trs = {}     -- modId -> { key -> text } from its own files

local function readLines(modId, path)
    local r = safe(function() return getModFileReader(modId, path, false) end)
    if not r then return nil end
    local t = {}
    local l = safe(function() return r:readLine() end)
    while l do
        t[#t + 1] = l
        l = safe(function() return r:readLine() end)
    end
    pcall(function() r:close() end)
    return t
end
S.readLines = readLines

local function lang()
    local n = safe(function() return tostring(Translator.getLanguage():name()) end)
    return (n and n ~= "") and n or "EN"
end

-- the mod's own Sandbox translations: Sandbox.json (Build 42) or Sandbox_<LANG>.txt
local function fileTr(modId)
    local t = trs[modId]
    if t then return t end
    t = {}
    local langs = { lang() }
    if langs[1] ~= "EN" then langs[2] = "EN" end
    for i = #langs, 1, -1 do   -- English first, the player's language over it
        local L = langs[i]
        for _, path in ipairs({ "media/lua/shared/Translate/" .. L .. "/Sandbox.json", "media/lua/shared/Translate/" .. L .. "/Sandbox_" .. L .. ".txt" }) do
            for _, line in ipairs(readLines(modId, path) or {}) do
                local k, v = line:match('^%s*"?([%w_%.%-]+)"?%s*[=:]%s*"(.*)"%s*,?%s*$')
                if k and v then t[k] = v:gsub('\\"', '"'):gsub("\\n", " ") end
            end
        end
    end
    trs[modId] = t
    return t
end

local function tr(modId, key)
    local t = getTextOrNull(key)
    if t and t ~= key then return t end
    return fileTr(modId)[key]
end

local function unq(v) return (tostring(v or ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub('^"(.*)"$', "%1")) end

local function parse(modId)
    local lines = readLines(modId, "media/sandbox-options.txt")
    if not lines then return false end
    local list, cur = {}, nil
    for _, line in ipairs(lines) do
        local name = line:match("^%s*option%s+([%w_%.%-]+)")
        if name then
            cur = { name = name, fields = {} }
            list[#list + 1] = cur
        elseif cur then
            local k, v = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*,?%s*$")
            if k then cur.fields[k] = unq(v) end
        end
    end
    if #list == 0 then return false end
    local out, pages, seenPage = { list = {}, pages = {} }, {}, {}
    for _, o in ipairs(list) do
        local f = o.fields
        local key = f.translation or o.name:gsub("%.", "_")
        local label = tr(modId, "Sandbox_" .. key) or o.name
        local tip = tr(modId, "Sandbox_" .. key .. "_tooltip")
        local page = f.page or ""
        if page ~= "" and not seenPage[page] then
            seenPage[page] = true
            pages[#pages + 1] = tr(modId, "Sandbox_" .. page) or page
        end
        local ty = string.lower(f.type or "")
        local s = { name = o.name, label = label, tooltip = tip and plain(tip) or nil, type = ty, page = tr(modId, "Sandbox_" .. page) or page }
        if ty == "boolean" then s.on = (string.lower(f.default or "") == "true")
        elseif ty == "enum" then
            local i = tonumber(f.default) or 1
            s.value = tr(modId, "Sandbox_" .. (f.valueTranslation or key) .. "_option" .. i) or tostring(i)
            s.count = tonumber(f.numValues)
        else
            s.value = f.default or ""
            if f.min or f.max then s.range = { f.min, f.max } end
        end
        out.list[#out.list + 1] = s
    end
    out.pages = pages
    return out
end

function S.sandbox(modId)
    if sb[modId] == nil then
        local ok, r = pcall(parse, modId)
        sb[modId] = (ok and r) or false
    end
    return sb[modId] or nil
end

function S.sandboxCount(modId)
    local s = S.sandbox(modId)
    return s and #s.list or 0
end

function S.reset()
    sb, trs = {}, {}
    cache.rows, cache.at = nil, -1e9
end
