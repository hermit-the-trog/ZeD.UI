-- ZeDUI/tools/qa/zedqa_pointer_probe.lua  (Nov 10 2026, Build; punch list 139, the pointer says what a drop will do)
-- The director's idea: the pointer itself changes while you drag (the game's pointing hand becomes the drop-to-floor,
-- put-in or equip icon). Whether ZeD can do it depends on what the game lets Lua reach, which can't be read from the
-- cloud session (no game install, the Java docs' hosts blocked). This probe, in a -debug game with the QA bridge,
-- reports it. Read-only, except step 3, which hides the pointer for a moment and shows it again.
--   1. WHAT LUA SEES: every function on the Mouse table (and its metatable's __index) whose name mentions cursor,
--      visible, texture, render, grab, hide or show; the same on getCore(), on UIManager, and on the globals
--   2. CANDIDATES: each of a list of likely names (Mouse.setCursorVisible, Mouse.isCursorVisible, Mouse.setCursor,
--      Mouse.setCursorTexture, getCore():setCursor...) found or not, and what a getter answers
--   3. HIDE: if Mouse.setCursorVisible exists, the pointer is hidden for about a second (shot zqa_ptr_hidden.png),
--      read back, then shown again (shot zqa_ptr_shown.png). Look at both shots: is the pointer gone in the first?
--   4. DRAWN: whether the game draws the pointer itself (a texture in the UI pass) or the system does: the probe
--      looks for media/ui cursor textures the game ships (getTexture on a few known names) and reports which load
-- Run in game after zedqa_prelude.lua (any save; the windows needn't be open). grep "ZEDQA ptr". Send every line and
-- the two shots back to Build.
local function say(s) print("ZEDQA ptr " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ptr_" .. n .. ".png") end); say("shot " .. n) end

local WORDS = { "ursor", "isible", "exture", "ender", "rab", "ide", "how", "ointer" }
local function interesting(name)
    name = tostring(name)
    for _, w in ipairs(WORDS) do if name:find(w, 1, true) then return true end end
    return false
end

-- the functions a table (a Java class or object as Lua sees it) answers to: its own keys and its metatable's __index
local function names(t)
    local out, seen = {}, {}
    local function scan(x, depth)
        if type(x) ~= "table" or depth > 3 then return end
        local ok = pcall(function()
            for k, v in pairs(x) do
                if type(k) == "string" and not seen[k] and (type(v) == "function" or type(v) == "userdata") then
                    seen[k] = true; out[#out + 1] = k
                end
            end
        end)
        if not ok then say("info: pairs refused on a table") end
        local mt = getmetatable(x)
        if mt and type(mt.__index) == "table" then scan(mt.__index, depth + 1) end
    end
    scan(t, 0)
    if type(t) == "userdata" then
        local mt = getmetatable(t)
        if mt and type(mt.__index) == "table" then scan(mt.__index, 1) end
    end
    table.sort(out)
    return out
end

local function report(label, t)
    if t == nil then say(label .. ": not reachable from Lua"); return end
    local all = names(t)
    local hits = {}
    for _, n in ipairs(all) do if interesting(n) then hits[#hits + 1] = n end end
    say(label .. ": " .. #all .. " functions; about the pointer: " .. (#hits > 0 and table.concat(hits, ", ") or "none"))
end

local steps, qi, wait = {}, 1, nil
local function step(frames, fn) steps[#steps + 1] = { n = frames, fn = fn } end

-- 1. WHAT LUA SEES
step(10, function()
    say("type(Mouse) = " .. type(Mouse))
    report("Mouse", Mouse)
    local core = getCore and getCore() or nil
    report("getCore()", core)
    report("UIManager", UIManager)
    -- globals whose names mention the pointer
    local g = {}
    for k, v in pairs(_G) do
        if type(k) == "string" and type(v) == "function" and (k:find("ursor", 1, true) or k:find("ouse", 1, true)) then g[#g + 1] = k end
    end
    table.sort(g)
    say("globals about the pointer or mouse: " .. (#g > 0 and table.concat(g, ", ") or "none"))
end)

-- 2. CANDIDATES
local CANDIDATES = {
    { "Mouse", "setCursorVisible" }, { "Mouse", "isCursorVisible" }, { "Mouse", "setCursor" },
    { "Mouse", "setCursorTexture" }, { "Mouse", "setNativeCursor" }, { "Mouse", "getCursor" },
    { "Mouse", "renderCursorTexture" }, { "Mouse", "setGrabbed" }, { "Mouse", "isGrabbed" },
    { "core", "setCursor" }, { "core", "setCursorVisible" }, { "core", "isCursorVisible" }, { "core", "getCursor" },
}
step(10, function()
    local core = getCore and getCore() or nil
    for _, c in ipairs(CANDIDATES) do
        local owner = (c[1] == "Mouse") and Mouse or core
        local f = nil
        pcall(function() f = owner and owner[c[2]] end)
        local line = c[1] .. "." .. c[2] .. ": " .. (f and "found" or "not found")
        if f and (c[2]:find("^is") or c[2]:find("^get")) then
            local ok, v = pcall(function() if c[1] == "Mouse" then return f() else return f(core) end end)
            line = line .. (ok and (" -> " .. tostring(v)) or (" (call failed: " .. tostring(v) .. ")"))
        end
        say(line)
    end
end)

-- 3. HIDE (only with Mouse.setCursorVisible)
local canHide = false
step(10, function()
    local f = nil
    pcall(function() f = Mouse and Mouse.setCursorVisible end)
    canHide = f ~= nil
    if not canHide then say("hide: no Mouse.setCursorVisible; skipped"); return end
    local ok, err = pcall(function() Mouse.setCursorVisible(false) end)
    say("hide: setCursorVisible(false) " .. (ok and "ran" or ("failed: " .. tostring(err))))
    local ok2, v = pcall(function() return Mouse.isCursorVisible and Mouse.isCursorVisible() end)
    say("hide: isCursorVisible now " .. tostring(ok2 and v))
end)
step(20, function() if canHide then shot("hidden") end end)
step(40, function()
    if not canHide then return end
    local ok, err = pcall(function() Mouse.setCursorVisible(true) end)
    say("show: setCursorVisible(true) " .. (ok and "ran" or ("failed: " .. tostring(err))))
end)
step(20, function() if canHide then shot("shown") end end)

-- 4. DRAWN: the game's own pointer pictures, if it ships any
local TEXTURES = { "media/ui/cursor.png", "media/ui/Cursor.png", "media/ui/mouse_cursor.png", "media/ui/cursor_hand.png",
                   "media/ui/Mouse.png", "media/ui/pointer.png", "media/ui/Hand_Cursor.png" }
step(10, function()
    local found = {}
    for _, path in ipairs(TEXTURES) do
        local ok, t = pcall(getTexture, path)
        if ok and t then found[#found + 1] = path end
    end
    say("cursor pictures the game loads: " .. (#found > 0 and table.concat(found, ", ") or "none of the names tried"))
    -- (the pointer shown again whatever happened above)
    if canHide then pcall(function() Mouse.setCursorVisible(true) end) end
    say("DONE")
end)

local function tick()
    local s = steps[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    wait = wait or (now + s.n * 1000 / 60)
    if now < wait then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
