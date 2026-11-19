-- ZeDUI/tools/qa/kbmap_check.lua  (Nov 19 2026, QA; tag kbmap_check): the second half of the Keyboard map's restart
-- check (kbmap_run.ps1; manifest kbmap_check.txt). Built on rt_kit.lua. grep "ZEDQA kbmap_check".
-- The first launch (kbmap_set.lua) left one binding on a test key and wrote Lua/zedqa_kbmap_carry.txt (the name, the
-- key it had, the test key). After the restart: the game holds the test key (getCore():getKey) and keysB42.ini still
-- has its line; then ZeD.KeyboardMap.setKey puts the key it had back, and the game and the file agree.
-- kbmap_run.ps1 also puts keysB42.ini back byte for byte after, and removes the carry file.
if not RT then
    print("ZEDQA kbmap_check FAIL the kit (rt_kit.lua) is not loaded")
    print("ZEDQA kbmap_check VERDICT FAIL 1")
    print("ZEDQA kbmap_check DONE")
    return
end
local Q = RT.make("kbmap_check")
local KM = ZeD and ZeD.KeyboardMap
local S = {}

local function key(name)
    local c = nil
    pcall(function() c = getCore():getKey(name) end)
    return c or 0
end
local function readAll(file)
    local t = nil
    pcall(function()
        local r = getFileReader(file, false)
        if not r then return end
        t = {}
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        r:close()
    end)
    return t or {}
end
-- the binding's line in keysB42.ini, and its key as MainOptions.loadKeys reads it
local function fileKey(name)
    local pre = name .. "="
    for _, l in ipairs(readAll("keysB42.ini")) do
        if l:sub(1, #pre) == pre then
            local got = nil
            pcall(function()
                local sp = string.split(l, "=")
                for _, fv in ipairs(string.split(sp[2], ";")) do
                    local kv = string.split(fv, ":")
                    if kv[1] == "key" then got = tonumber(kv[2]) end
                end
            end)
            return got, l
        end
    end
    return nil, nil
end

Q.step(5, function()
    local c = readAll("zedqa_kbmap_carry.txt")
    S.name, S.orig, S.new = c[1], tonumber(c[2] or ""), tonumber(c[3] or "")
    if not Q.check(S.name ~= nil and S.orig ~= nil and S.new ~= nil, "Keyboard map restart: the first launch's carry file is here",
        table.concat(c, " / ")) then return end
    Q.check(key(S.name) == S.new, "Keyboard map restart: after a restart the game holds the key setKey gave",
        tostring(S.name) .. " on " .. tostring(key(S.name)) .. ", wanted " .. tostring(S.new))
    local fk, l = fileKey(S.name)
    Q.check(fk == S.new, "Keyboard map restart: after a restart keysB42.ini still has the key setKey gave", tostring(l))
    if KM and KM.setKey then KM.setKey(S.name, S.orig) end
end)
Q.step(5, function()
    if not (S.name and S.orig) then return end
    local fk, l = fileKey(S.name)
    Q.check(key(S.name) == S.orig and fk == S.orig, "Keyboard map restart: setKey puts the key it had back, in the game and the file",
        tostring(S.name) .. " on " .. tostring(key(S.name)) .. ", file " .. tostring(l) .. ", wanted " .. tostring(S.orig))
end)
Q.start()
