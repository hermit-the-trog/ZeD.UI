-- ZeDUI/tools/qa/zedqa_pointer_probe2.lua  (Nov 10 2026, Build; punch list 139, the pointer set)
-- After probe 1 (QA's Mac run, Nov 10): Mouse has setCursorVisible / isCursorVisible (the read-back works),
-- initCustomCursor, loadCursor and renderCursorTexture; nothing swaps a picture by name; the game's screenshots never
-- hold the pointer, so hiding was confirmed only by the read-back. This probe needs A PERSON WATCHING THE SCREEN: a
-- large notice says what should be happening to the pointer, and the person says whether it did.
--   1. SIGNATURES: loadCursor and initCustomCursor called with nothing, with a picture path, with a path and a hotspot,
--      each in pcall; every error is printed (Kahlua's errors often name the arguments a Java call wants). The picture
--      is one of ZeD's own (the 32 px drop-to-floor icon), so nothing new ships for the test.
--   2. HIDE BY EYE: notices A (Mouse.setCursorVisible) and B (getCore():setDisplayCursor): "THE POINTER SHOULD BE GONE"
--      for 5 s, then "BACK".
--   3. CUSTOM BY EYE: notices C (loadCursor with the media path) and D (with the full path in the mod's folder): "A RED
--      DOWN ARROW?" for 5 s each; then E, initCustomCursor() to put the game's own pointer back. If it can't, the custom
--      pointer may stay until the game restarts (use a throwaway copy).
--   4. READS: getCore():isDisplayCursor(), UIManager.isForceCursorVisible(), UIManager.getLastMouseTexture() (as text).
-- Any save, -debug, the QA bridge, after zedqa_prelude.lua. grep "ZEDQA pt2". Note what you SAW at each notice.
-- Nov 10 2026, run 2 (after QA's Mac run): the game's Lua has no next(), so steps 4 and 5 stopped ("tried to call nil");
-- loops now. loadCursor takes one argument and initCustomCursor none (their errors said so). Added: a second way to hide
-- (getCore():setDisplayCursor(false), the probe 1 find), and loadCursor with the picture's full path in the mod's folder
-- as well as the media path, each with its own notice.
local function say(s) print("ZEDQA pt2 " .. tostring(s)) end
local PIC = "media/textures/ZeD/wheel/32/zw_to_floor.png"

-- the notice: a big panel at the top of the screen, no clicks
local notice = nil
local function show(text)
    pcall(function()
        if not notice then
            notice = ISPanel:new(0, 0, 10, 10)
            notice:initialise()
            notice:instantiate()
            notice.background = true
            notice.backgroundColor = { r = 0.6, g = 0.05, b = 0.05, a = 0.95 }
            notice.borderColor = { r = 1, g = 1, b = 1, a = 1 }
            notice.render = function(self)
                self:drawTextCentre(self._text or "", self.width / 2, (self.height - 30) / 2, 1, 1, 1, 1, UIFont.Large)
            end
            notice:addToUIManager()
            pcall(function() notice.javaObject:setConsumeMouseEvents(false) end)
        end
        local w = getCore():getScreenWidth()
        notice:setX(math.floor(w * 0.15)); notice:setY(40)
        notice:setWidth(math.floor(w * 0.7)); notice:setHeight(80)
        notice._text = text
        notice:setVisible(text ~= nil)
    end)
    if text then say("NOTICE: " .. text) end
end

local works = {}   -- name -> the args that ran
local function try(label, fn)
    local ok, err = pcall(fn)
    say(label .. ": " .. (ok and "ran" or ("error: " .. tostring(err))))
    return ok
end

local steps, qi, wait = {}, 1, nil
local function step(frames, fn) steps[#steps + 1] = { n = frames, fn = fn } end

-- 1. SIGNATURES
step(10, function()
    say("Mouse.loadCursor is " .. type(Mouse and Mouse.loadCursor) .. "; Mouse.initCustomCursor is " .. type(Mouse and Mouse.initCustomCursor)
        .. "; Mouse.renderCursorTexture is " .. type(Mouse and Mouse.renderCursorTexture))
    -- (the no-argument calls last: one of them may be the reset)
    for _, name in ipairs({ "loadCursor", "initCustomCursor" }) do
        local f = Mouse and Mouse[name]
        if f then
            if try(name .. "(path)", function() f(PIC) end) then works[name] = works[name] or "path" end
            if try(name .. "(path, 0, 0)", function() f(PIC, 0, 0) end) then works[name] = works[name] or "path,x,y" end
            if try(name .. "(path, 16, 16)", function() f(PIC, 16, 16) end) then works[name] = works[name] or "path,x,y" end
        end
    end
    local any = false
    for n, a in pairs(works) do any = true; say("ran without an error: " .. tostring(n) .. "(" .. tostring(a) .. ")") end
    if not any then say("no picture call ran without an error") end
end)

-- 2. HIDE BY EYE (A: Mouse.setCursorVisible; B: getCore():setDisplayCursor)
step(10, function()
    try("setCursorVisible(false)", function() Mouse.setCursorVisible(false) end)
    show("A: THE POINTER SHOULD BE GONE (5 s). Move the mouse: is it?")
end)
step(300, function()
    try("setCursorVisible(true)", function() Mouse.setCursorVisible(true) end)
    show("A: THE POINTER SHOULD BE BACK. Is it?")
end)
step(180, function()
    try("getCore():setDisplayCursor(false)", function() getCore():setDisplayCursor(false) end)
    show("B: THE POINTER SHOULD BE GONE (5 s). Move the mouse: is it?")
end)
step(300, function()
    try("getCore():setDisplayCursor(true)", function() getCore():setDisplayCursor(true) end)
    show("B: THE POINTER SHOULD BE BACK. Is it?")
end)

-- 3. CUSTOM BY EYE: loadCursor(path), the media path, then the full path in the mod's folder
local function modPic()
    local p = nil
    pcall(function()
        local info = getModInfoByID("ZeD_UI")
        local dir = info and ((info.getVersionDir and info:getVersionDir()) or info:getDir())
        if dir then p = tostring(dir) .. "/" .. PIC end
    end)
    return p
end
local hasLoad = false
step(180, function()
    hasLoad = Mouse ~= nil and Mouse.loadCursor ~= nil
    if not hasLoad then show(nil); say("custom: skipped (no Mouse.loadCursor)"); return end
    try("loadCursor(media path)", function() Mouse.loadCursor(PIC) end)
    show("C: THE POINTER SHOULD LOOK LIKE A RED DOWN ARROW (5 s). Does it?")
end)
step(300, function()
    if not hasLoad then return end
    local full = modPic()
    say("the picture's full path: " .. tostring(full))
    if full then try("loadCursor(full path)", function() Mouse.loadCursor(full) end) end
    show("D: NOW, WITH THE FULL PATH: A RED DOWN ARROW (5 s)? Did it change from C?")
end)
step(300, function()
    if not hasLoad then return end
    -- the game's own pointer back: initCustomCursor takes no arguments (QA's run 1)
    try("initCustomCursor() to put the game's pointer back", function() Mouse.initCustomCursor() end)
    show("E: THE GAME'S OWN POINTER SHOULD BE BACK. Is it?")
end)

-- 4. READS
step(180, function()
    show(nil)
    pcall(function() if notice then notice:removeFromUIManager() end end)
    local core = getCore()
    local ok1, v1 = pcall(function() return core:isDisplayCursor() end)
    say("getCore():isDisplayCursor() -> " .. tostring(ok1 and v1 or ("error: " .. tostring(v1))))
    local ok2, v2 = pcall(function() return UIManager.isForceCursorVisible() end)
    say("UIManager.isForceCursorVisible() -> " .. tostring(ok2 and v2 or ("error: " .. tostring(v2))))
    local ok3, v3 = pcall(function() return UIManager.getLastMouseTexture() end)
    say("UIManager.getLastMouseTexture() -> " .. tostring(ok3 and v3 or ("error: " .. tostring(v3))))
    pcall(function() Mouse.setCursorVisible(true) end)
    pcall(function() getCore():setDisplayCursor(true) end)
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
