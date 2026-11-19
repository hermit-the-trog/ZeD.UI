-- ZeDUI/tools/qa/kbmap_set.lua  (Nov 19 2026, QA; tag kbmap_set): the first half of the Keyboard map's restart check
-- (kbmap_run.ps1; manifest kbmap_set.txt). Built on rt_kit.lua. grep "ZEDQA kbmap_set".
-- It puts the game's "Toggle Music" (no key by default) onto a key no binding uses with ZeD.KeyboardMap.setKey and
-- LEAVES IT SET for the next launch, and writes Lua/zedqa_kbmap_carry.txt (the name, the key it had, the test key)
-- for the second half, kbmap_check.lua, which checks the key came back after the restart and sets it back.
-- kbmap_run.ps1 copies keysB42.ini before and puts it back byte for byte after, whatever happens.
if not RT then
    print("ZEDQA kbmap_set FAIL the kit (rt_kit.lua) is not loaded")
    print("ZEDQA kbmap_set VERDICT FAIL 1")
    print("ZEDQA kbmap_set DONE")
    return
end
local Q = RT.make("kbmap_set")
local KM = ZeD and ZeD.KeyboardMap
local S = {}
local CARRY = "zedqa_kbmap_carry.txt"

local function key(name)
    local c = nil
    pcall(function() c = getCore():getKey(name) end)
    return c or 0
end
local function lines()
    local t = nil
    pcall(function()
        local r = getFileReader("keysB42.ini", false)
        if not r then return end
        t = {}
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        r:close()
    end)
    return t or {}
end
-- a key on the drawn keyboard no binding uses (punctuation first)
local function freeCap(data)
    local prefer = { "KEY_APOSTROPHE", "KEY_SEMICOLON", "KEY_RBRACKET", "KEY_LBRACKET", "KEY_BACKSLASH", "KEY_SLASH",
                     "KEY_EQUALS", "KEY_MINUS", "KEY_PERIOD", "KEY_COMMA" }
    for _, cn in ipairs(prefer) do
        local c = nil
        pcall(function() c = Keyboard[cn] end)
        if c and c ~= 0 and (data.used[c] or 0) == 0 then return c end
    end
    return nil
end

Q.step(5, function()
    S.name = "Toggle Music"
    pcall(function() S.name = tostring(KeybindId.TOGGLE_MUSIC:getId()) end)
    if not Q.check(KM ~= nil and KM.setKey ~= nil and KM.read ~= nil, "Keyboard map restart: ZeD.KeyboardMap is loaded") then return end
    S.orig = key(S.name)
    S.new = freeCap(KM.read())
    if not Q.check(S.new ~= nil, "Keyboard map restart: a free key to test with", tostring(S.new)) then return end
    local ok = pcall(function()
        local w = getFileWriter(CARRY, true, false)
        w:write(S.name .. "\r\n" .. tostring(S.orig) .. "\r\n" .. tostring(S.new) .. "\r\n")
        w:close()
    end)
    Q.check(ok, "Keyboard map restart: the carry file for the second launch is written", CARRY)
    KM.setKey(S.name, S.new)
end)
Q.step(5, function()
    if not S.new then return end
    Q.check(key(S.name) == S.new, "Keyboard map restart: setKey gives the game the test key before the restart",
        tostring(S.name) .. " on " .. tostring(key(S.name)) .. ", wanted " .. tostring(S.new))
    local want = S.name .. "=key:" .. tostring(S.new)
    local found = nil
    for _, l in ipairs(lines()) do if l:sub(1, #want) == want then found = l end end
    Q.check(found ~= nil, "Keyboard map restart: keysB42.ini holds the test key before the restart", tostring(found or want))
    Q.say("left set for the next launch: " .. tostring(S.name) .. " " .. tostring(S.orig) .. " -> " .. tostring(S.new))
end)
Q.start()
