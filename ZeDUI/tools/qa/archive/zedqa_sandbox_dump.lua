-- ZeDUI/tools/qa/zedqa_sandbox_dump.lua  (Oct 24 2026)
-- Writes every sandbox setting of the running save, in vanilla's page order,
-- to Zomboid/Lua/ZeD_sandbox_dump.json: page, section, name, the game's own
-- label and help text, type, choices, limits, value, default, and whether a
-- mod added it. The data behind the mid-game sandbox window's mockup and its
-- help texts. Changes nothing. grep "ZEDQA sbd".
local function say(s) print("ZEDQA sbd " .. tostring(s)) end

local function esc(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\r", ""):gsub("\n", "\\n"):gsub("\t", " ")
    return "\"" .. s .. "\""
end
local function call(o, m, ...)
    if not o or not o[m] then return nil end
    local ok, v = pcall(o[m], o, ...)
    if ok then return v end
    return nil
end

local so = getSandboxOptions()
local out = {}
local function w(s) out[#out + 1] = s end
local seen = {}
local count = 0

local function option(page, section, s)
    local o = so:getOptionByName(s.name)
    if not o then say("missing " .. tostring(s.name)); return end
    seen[s.name] = true
    count = count + 1
    local co = call(o, "asConfigOption")
    local t = call(o, "getType") or "?"
    local f = {}
    f[#f + 1] = "\"page\":" .. esc(page)
    f[#f + 1] = "\"section\":" .. esc(section or "")
    f[#f + 1] = "\"name\":" .. esc(s.name)
    f[#f + 1] = "\"label\":" .. esc(s.translatedName or call(o, "getTranslatedName"))
    f[#f + 1] = "\"tooltip\":" .. esc(s.tooltip or call(o, "getTooltip"))
    f[#f + 1] = "\"type\":" .. esc(t)
    f[#f + 1] = "\"value\":" .. esc(call(co, "getValueAsString"))
    f[#f + 1] = "\"default\":" .. esc(call(co, "getDefaultValueAsString") or tostring(call(o, "getDefaultValue")))
    f[#f + 1] = "\"min\":" .. esc(call(co, "getMin"))
    f[#f + 1] = "\"max\":" .. esc(call(co, "getMax"))
    f[#f + 1] = "\"custom\":" .. tostring(call(o, "isCustom") == true)
    f[#f + 1] = "\"table\":" .. esc(call(o, "getTableName"))
    f[#f + 1] = "\"short\":" .. esc(call(o, "getShortName"))
    if s.values then
        local v = {}
        for _, x in ipairs(s.values) do v[#v + 1] = esc(x) end
        f[#f + 1] = "\"values\":[" .. table.concat(v, ",") .. "]"
    end
    w("{" .. table.concat(f, ",") .. "}")
end

local ok, err = pcall(function()
    local pages = ServerSettingsScreen.getSandboxSettingsTable()
    for _, page in ipairs(pages) do
        local section = nil
        for _, s in ipairs(page.settings or {}) do
            if s.title then section = getTextOrNull("Sandbox_" .. s.title) or s.title end
            option(page.name, section, s)
        end
    end
    -- anything not on a page (vanilla hides a few)
    for i = 1, so:getNumOptions() do
        local o = so:getOptionByIndex(i - 1)
        local n = o:getName()
        if not seen[n] then option("(not on a page)", nil, { name = n }) end
    end
end)
if not ok then say("ERR " .. tostring(err)) end

local fw = getFileWriter("ZeD_sandbox_dump.json", true, false)
fw:write("[\n" .. table.concat(out, ",\n") .. "\n]\n")
fw:close()
say(count .. " settings written to Lua/ZeD_sandbox_dump.json")
say("DONE")
