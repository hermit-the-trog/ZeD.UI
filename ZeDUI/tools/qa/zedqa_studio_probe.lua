-- ZeDUI/tools/qa/zedqa_studio_probe.lua  (Nov 10 2026, Build; punch list 145, the portrait studio's poses)
-- The director: "it needs poses if there are some". The studio's figure is the game's 3D character in the UI
-- (ISUI3DModel, as the ID photo and the hair menu use); ZeD has only ever set it to "idle". What else it takes can't be
-- read from the cloud session. This probe puts a large figure of the player on screen over a plain backdrop, with a
-- big label naming each step, and:
--   1. WHAT IT ANSWERS TO: every function on ISUI3DModel and on its Java object whose name mentions state, anim,
--      variable, pose, emote, sit, play, action, animate, set or get (Kahlua: no next(), loops only)
--   2. STATES: setState with each of a list of names (idle, walk, run, sneak, sitonground, sitonfurniture, emote ...);
--      each in pcall (an error printed), then a shot after 1.5 s: zqa_studio_state_<name>.png
--   3. EMOTES AND SITTING BY VARIABLE: when the Java object has setVariable, the game's emote names (wave, salute,
--      thumbs up ...) as "emote" with the emote state, and a few sitting variables; a shot each
--   4. ANIM SETS: setAnimSetName with a few names, each with idle and sitonground; a shot each
--   5. PAUSED: the game paused (setGameSpeed 0), the figure walking: two shots 1.5 s apart (zqa_studio_paused_a /
--      _b). Different poses in the two: it animates while paused; the same: it freezes. Then the game runs again.
-- Run in game after zedqa_prelude.lua, -debug OFF (the game's own Ctrl+A debug spawn throws a single-player game
-- out). grep "ZEDQA st". Send every line and the shots back to Build, and say which shots show a pose that differs
-- from idle (sitting, a wave, a salute ...).
local function say(s) print("ZEDQA st " .. tostring(s)) end

local steps, qi, wait = {}, 1, nil
local function step(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end

-- ---------------------------------------------------------------------------
-- the stage: a backdrop, the figure, the label
-- ---------------------------------------------------------------------------
local back, fig, label = nil, nil, nil
local function setLabel(t)
    if label then label._text = t end
    say("STEP " .. tostring(t))
end
local function shot(n)
    pcall(function() getCore():TakeFullScreenshot("zqa_studio_" .. n .. ".png") end)
    say("shot zqa_studio_" .. n .. ".png")
end

step(200, function()
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local fh = math.floor(sh * 0.8)
    local fw = math.floor(fh * 0.55)
    local fx, fy = math.floor((sw - fw) / 2), math.floor(sh * 0.12)
    back = ISPanel:new(fx - 40, fy - 20, fw + 80, fh + 40)
    back:initialise()
    back:instantiate()
    back.background = true
    back.backgroundColor = { r = 0.35, g = 0.42, b = 0.55, a = 1 }
    back.borderColor = { r = 1, g = 1, b = 1, a = 1 }
    back:addToUIManager()
    fig = ISUI3DModel:new(fx, fy, fw, fh)
    fig:initialise()
    fig:instantiate()
    fig:setCharacter(getPlayer())
    fig:setState("idle")
    fig:setDirection(IsoDirections.S)
    fig:setIsometric(false)
    fig:setZoom(0)
    fig:setYOffset(0)
    fig:setDoRandomExtAnimations(false)
    fig:addToUIManager()
    label = ISPanel:new(math.floor(sw * 0.2), 10, math.floor(sw * 0.6), 60)
    label:initialise()
    label:instantiate()
    label.background = true
    label.backgroundColor = { r = 0, g = 0, b = 0, a = 0.85 }
    label.borderColor = { r = 1, g = 1, b = 1, a = 1 }
    label.render = function(self)
        self:drawTextCentre(self._text or "", self.width / 2, 15, 1, 1, 0.4, 1, UIFont.Large)
    end
    label:addToUIManager()
    pcall(function() label.javaObject:setConsumeMouseEvents(false) end)
    setLabel("idle")
end)
step(1500, function() shot("idle") end)

-- ---------------------------------------------------------------------------
-- 1. WHAT IT ANSWERS TO
-- ---------------------------------------------------------------------------
local WORDS = { "tate", "nim", "ariable", "ose", "mote", "Sit", "sit", "lay", "ction", "nimate", "set", "get", "Set", "Get" }
local function interesting(n) for _, w in ipairs(WORDS) do if n:find(w, 1, true) then return true end end return false end
local function names(t)
    local out, seen = {}, {}
    local function scan(x, depth)
        if type(x) ~= "table" or depth > 3 then return end
        pcall(function()
            for k, v in pairs(x) do
                if type(k) == "string" and not seen[k] and (type(v) == "function" or type(v) == "userdata") then seen[k] = true; out[#out + 1] = k end
            end
        end)
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
local function report(lbl, t)
    if t == nil then say(lbl .. ": not reachable"); return end
    local all, hits = names(t), {}
    for _, n in ipairs(all) do if interesting(n) then hits[#hits + 1] = n end end
    say(lbl .. ": " .. #all .. " functions; " .. table.concat(hits, ", "))
end
step(100, function()
    report("ISUI3DModel", ISUI3DModel)
    report("its Java object", fig and fig.javaObject)
end)

-- ---------------------------------------------------------------------------
-- 2. STATES
-- ---------------------------------------------------------------------------
local STATES = { "walk", "run", "sprint", "sneak", "crouch", "sitonground", "SitOnGround", "sit", "sitonfurniture",
                 "SitOnFurniture", "emote", "aim", "fishing", "dance", "strafe", "sleep", "onground", "actions", "idle" }
for _, st in ipairs(STATES) do
    step(200, function()
        setLabel("state " .. st)
        local ok, err = pcall(function() fig:setState(st) end)
        say("setState(" .. st .. "): " .. (ok and "ran" or ("error: " .. tostring(err))))
    end)
    step(1500, function() shot("state_" .. st) end)
end

-- ---------------------------------------------------------------------------
-- 3. EMOTES AND SITTING BY VARIABLE (only if the Java object has setVariable)
-- ---------------------------------------------------------------------------
local EMOTES = { "wavehi", "wavebye", "salute1", "salute2", "comehere", "followme", "stop", "thumbsup", "thumbsdown",
                 "insult", "signalok", "shrug", "clap", "freeze", "surrender" }
local SITS = { "SitOnGround", "sitonground", "SittingOnFurniture", "sitonfurniture", "bSitting" }
local hasVar = false
step(100, function()
    local jo = fig and fig.javaObject
    local ok, v = pcall(function() return jo and jo.setVariable end)
    hasVar = ok and v ~= nil
    say("the Java object's setVariable: " .. tostring(hasVar))
end)
for _, em in ipairs(EMOTES) do
    step(200, function()
        if not hasVar then return end
        setLabel("emote " .. em)
        local ok, err = pcall(function() fig.javaObject:setVariable("emote", em); fig:setState("emote") end)
        say("emote " .. em .. ": " .. (ok and "ran" or ("error: " .. tostring(err))))
    end)
    step(1500, function() if hasVar then shot("emote_" .. em) end end)
end
for _, v in ipairs(SITS) do
    step(200, function()
        if not hasVar then return end
        setLabel("variable " .. v .. " = true")
        local ok, err = pcall(function() fig:setState("idle"); fig.javaObject:setVariable(v, true) end)
        say("variable " .. v .. ": " .. (ok and "ran" or ("error: " .. tostring(err))))
    end)
    step(1500, function()
        if not hasVar then return end
        shot("var_" .. v)
        pcall(function() fig.javaObject:setVariable(v, false) end)
    end)
end

-- ---------------------------------------------------------------------------
-- 4. ANIM SETS
-- ---------------------------------------------------------------------------
local SETS = { "player-avatar", "player", "player-vehicle" }
for _, set in ipairs(SETS) do
    for _, st in ipairs({ "idle", "sitonground" }) do
        step(200, function()
            setLabel("anim set " .. set .. ", " .. st)
            local ok, err = pcall(function() fig:setAnimSetName(set); fig:setState(st) end)
            say("setAnimSetName(" .. set .. ") + " .. st .. ": " .. (ok and "ran" or ("error: " .. tostring(err))))
        end)
        step(1500, function() shot("set_" .. set .. "_" .. st) end)
    end
end

-- ---------------------------------------------------------------------------
-- 5. PAUSED
-- ---------------------------------------------------------------------------
step(200, function()
    pcall(function() fig:setAnimSetName("player-avatar") end)
    pcall(function() fig:setState("walk") end)
    pcall(function() setGameSpeed(0) end)
    setLabel("PAUSED, walking: two shots 1.5 s apart")
end)
step(800, function() shot("paused_a") end)
step(1500, function() shot("paused_b") end)
step(200, function()
    pcall(function() setGameSpeed(1) end)
    setLabel("running again")
end)

-- ---------------------------------------------------------------------------
-- the end: everything off the screen
-- ---------------------------------------------------------------------------
step(500, function()
    for _, p in ipairs({ label, fig, back }) do pcall(function() p:removeFromUIManager() end) end
    say("DONE")
end)

local function tick()
    local s = steps[qi]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local now = getTimestampMs()
    wait = wait or (now + s.ms)
    if now < wait then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
