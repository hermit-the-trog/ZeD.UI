-- ZeDUI/tools/qa/zedqa_carkey_tex.lua  (Nov 17 2026, QA): Design's over-head handoff, set C (the car key), step 1:
-- does the game take a mod's media/ui/CarKey.png over its packed one, and at what size does it draw it?
-- Runs with the dev-only fixture ZeDQAOverheadTex (fixtures/ZeDQAOverheadTex, copied to Zomboid/mods; NEVER staged
-- or uploaded): its CarKey.png is Design's 1x (31 x 30), its CarKey_none.png Design's 2x (62 x 60). The game's own are
-- 32 x 32. Run through zedqa_mods_run.ps1 with carkey_tex_mods.txt and the carkey_tex.txt manifest.
-- Where the game draws the key (projectzomboid.jar, 42.22): in single player, IsoGameCharacter.renderlast puts
-- " [img=media/ui/CarKey.png,r,g,b]" in the character's name line (a TextDrawObject) while the character stands near
-- a car (getNearVehicle) and carries its key (or it is hotwired, or the sandbox's easy use is on); without the key
-- nothing is drawn. CarKey_none is a SayDebug line, " [img=media/ui/CarKey_none.png]", when an engine fails to start
-- for want of a key (BaseVehicle.tryStartEngine). TextDrawObject draws a picture at 0.75 of the texture's size.
-- The name line is Java's and Lua cannot read it, so this logs: the textures as the game loaded them (getTexture:
-- name, width, height; 31 x 30 means the mod's file won), the size a TextDrawObject gives the same image string
-- (Lua can build one: TextDrawObject.new), and the head's screen position with a CROP rect for each picture, to
-- measure the drawn key by eye.
--   1. a sedan on the drag strip (ZEDQA_CAR_WAIT), its key in the inventory (ZEDQA_CAR_PREP); the character 6 tiles
--      off (no key expected), then beside it (the key expected): ckt_far.png, ckt_key.png
--   2. the key taken out, still beside it (nothing expected): ckt_nokey.png
--   3. in the driver's seat (ZEDQA_CAR_ENTER: it refuses a car more than 25 tiles off or not ready), no key, the
--      engine tried: the CarKey_none line over the head (and what ZeD's speech bubble did with it): ckt_nokey_start.png
-- Puts back: out of the car, the key out of the inventory, the car removed (ZEDQA_CAR_AWAY), the character home.
-- grep "ZEDQA ckt".
local S = { p = getPlayer(), fails = 0, Q = {}, t = 0 }
S.pn = S.p:getPlayerNum()
local function say(s) print("ZEDQA ckt " .. tostring(s)) end
local function check(ok, what) if ok then say("PASS " .. what) else S.fails = S.fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("ckt_" .. n .. ".png") end); say("picture ckt_" .. n .. ".png") end
local function step(n, fn) S.Q[#S.Q + 1] = { n = n, fn = fn } end

function S.i(v) return math.floor((tonumber(v) or 0) + 0.5) end
function S.moveTo(x, y)
    pcall(function() S.p:setX(x); S.p:setY(y); S.p:setLastX(x); S.p:setLastY(y) end)
end
-- the texture as the game loaded it
function S.tex(path)
    local t = getTexture(path)
    if not t then say("texture " .. path .. ": none"); return nil end
    local nm, w, h = "?", -1, -1
    pcall(function() nm = tostring(t:getName()) end)
    pcall(function() w, h = t:getWidth(), t:getHeight() end)
    say(string.format("texture %s: name %s, %d x %d", path, nm, S.i(w), S.i(h)))
    return { w = w, h = h, name = nm }
end
-- the size a TextDrawObject gives a string (the name line's own kind of object)
function S.tdo(str)
    local w, h = -1, -1
    local ok, e = pcall(function()
        local o = TextDrawObject.new()
        o:setAllowAnyImage(true)
        o:setDefaultFont(UIFont.Small)
        o:ReadString(str)
        w, h = o:getWidth(), o:getHeight()
    end)
    if not ok then say("TextDrawObject failed for '" .. str .. "': " .. tostring(e)) end
    return w, h
end
-- what the game sees about the key now, and where the head is on screen
function S.state(tag)
    local v = S.v
    local near, have, hot, ign, easy = nil, nil, nil, nil, nil
    pcall(function() near = S.p:getNearVehicle() end)
    pcall(function() have = S.p:getInventory():haveThisKeyId(v:getKeyId()) end)
    pcall(function() hot = v:isHotwired() end)
    pcall(function() ign = v:isKeysInIgnition() end)
    pcall(function() easy = getSandboxOptions():getOptionByName("VehicleEasyUse"):getValue() end)
    say(string.format("%s: near vehicle %s (this car %s), its key in the inventory %s, hotwired %s, keys in ignition %s, sandbox easy use %s, name line height %s",
        tag, tostring(near ~= nil), tostring(near == v), tostring(have ~= nil), tostring(hot), tostring(ign), tostring(easy),
        tostring(pcall(function() return S.p:getUserNameHeight() end) and S.p:getUserNameHeight() or "?")))
    local hx, hy
    pcall(function()
        if ZeD.ActionBar and ZeD.ActionBar.headScreen then hx, hy = ZeD.ActionBar.headScreen(S.pn, S.p)
        else hx, hy = isoToScreenX(S.pn, S.p:getX(), S.p:getY(), S.p:getZ() + 0.85), isoToScreenY(S.pn, S.p:getX(), S.p:getY(), S.p:getZ() + 0.85) end
    end)
    if hx then
        local z = 1
        pcall(function() z = getCore():getZoom(S.pn) end)
        say(string.format("%s: head on screen %d,%d, zoom %.2f", tag, S.i(hx), S.i(hy), z))
        say(string.format("CROP ckt_%s x=%d y=%d w=%d h=%d (over the head: the name line and its key)", tag, S.i(hx - 90), S.i(hy - 110), 180, 130))
        say(string.format("CROP ckt_%s x=%d y=%d w=%d h=%d (tight, for measuring the key)", tag, S.i(hx - 40), S.i(hy - 70), 80, 70))
    end
    return near == v, have ~= nil, hot == true or easy == true
end

-- ===================================================================== the textures and their drawn size
step(20, function()
    if ZEDQA_HOME then ZEDQA_HOME("ckt") end
    S.hx, S.hy = S.p:getX(), S.p:getY()
    local active = false
    pcall(function() active = getActivatedMods():contains("ZeDQAOverheadTex") end)
    check(active, "the dev-only fixture ZeDQAOverheadTex is active (run with carkey_tex_mods.txt)")
    check(ZEDQA_CAR_WAIT ~= nil and ZEDQA_CAR_PREP ~= nil and ZEDQA_CAR_AWAY ~= nil, "the prelude's car helpers are here")
    S.key1 = S.tex("media/ui/CarKey.png")
    S.key0 = S.tex("media/ui/CarKey_none.png")
    local function verdict(t, mw, mh, what)
        if not t then say("RESULT " .. what .. ": no texture"); return end
        if S.i(t.w) == mw and S.i(t.h) == mh then say("RESULT " .. what .. ": the game loaded the MOD's file (" .. mw .. " x " .. mh .. "): a texture replacement takes")
        elseif S.i(t.w) == 32 and S.i(t.h) == 32 then say("RESULT " .. what .. ": the game kept its OWN packed texture (32 x 32): the replacement does not take")
        else say("RESULT " .. what .. ": " .. S.i(t.w) .. " x " .. S.i(t.h) .. ", neither the mod's (" .. mw .. " x " .. mh .. ") nor 32 x 32: look at the pictures") end
    end
    verdict(S.key1, 31, 30, "CarKey")
    verdict(S.key0, 62, 60, "CarKey_none")
    -- the drawn size: the same strings the game builds, measured by a TextDrawObject
    local w0, h0 = S.tdo("QA")
    local w1, h1 = S.tdo("QA [img=media/ui/CarKey.png,255,255,255]")
    local wi, hi = S.tdo(" [img=media/ui/CarKey.png,255,255,255]")
    local ws = S.tdo(" ")
    local wn, hn = S.tdo(" [img=media/ui/CarKey_none.png]")
    say(string.format("TextDrawObject: 'QA' %d x %d; 'QA' + key %d x %d; the key line alone %d x %d; a space %d wide; the no-key line %d x %d",
        S.i(w0), S.i(h0), S.i(w1), S.i(h1), S.i(wi), S.i(hi), S.i(ws), S.i(wn), S.i(hn)))
    if S.key1 then
        say(string.format("RESULT CarKey drawn size: about %d x %d (the key line less a space; 0.75 of the texture would be %d x %d)",
            S.i(wi - ws), S.i(hi), math.floor(S.key1.w * 0.75), math.floor(S.key1.h * 0.75)))
    end
    if S.key0 then
        say(string.format("RESULT CarKey_none drawn size: about %d x %d (0.75 of the texture would be %d x %d)",
            S.i(wn - ws), S.i(hn), math.floor(S.key0.w * 0.75), math.floor(S.key0.h * 0.75)))
    end
end)

-- ===================================================================== the car
step(10, function()
    if not ZEDQA_CAR_WAIT then S.why = "no ZEDQA_CAR_WAIT (run the prelude first)"; return end
    ZEDQA_CAR_WAIT("Base.CarNormal", "ckt", function(v) S.v = v end, function(why) S.why = why or "no car" end)
    S.t = 0
end)
step(10, function()
    S.t = S.t + 1
    if not (S.v or S.why) and S.t < 120 then return true end
    check(S.v ~= nil, "a sedan on the drag strip" .. (S.v and "" or (": " .. tostring(S.why or "never ready"))))
    if not S.v then return end
    S.key = ZEDQA_CAR_PREP(S.v)
    check(S.key ~= nil, "its key is in the inventory")
    say(string.format("car at %.1f,%.1f", S.v:getX(), S.v:getY()))
    S.moveTo(S.v:getX() + 6.5, S.v:getY() + 0.5)
end)
step(40, function()
    if not S.v then return end
    local near = S.state("far")
    check(not near, "6 tiles off, the car is not 'near' (no key expected over the head)")
    shot("far")
end)
-- beside it: the first spot the game counts as near
step(10, function()
    if not S.v then return end
    S.spots = { { 2.5, 0.5 }, { -2.5, 0.5 }, { 2.0, 0 }, { -2.0, 0 }, { 1.6, 0 }, { -1.6, 0 }, { 0.5, 3.5 }, { 0.5, -3.5 } }
    S.si = 0
    S.t = 0
end)
step(15, function()
    if not S.v then return end
    local near = false
    pcall(function() near = S.p:getNearVehicle() == S.v end)
    if near and S.si > 0 then say("beside it at offset " .. S.spots[S.si][1] .. "," .. S.spots[S.si][2]); return end
    S.si = S.si + 1
    if S.si > #S.spots then say("no spot beside the car counted as near"); return end
    S.moveTo(S.v:getX() + S.spots[S.si][1], S.v:getY() + S.spots[S.si][2])
    return true
end)
step(40, function()
    if not S.v then return end
    local near, have, other = S.state("key")
    check(near, "beside it, the game counts the car as near (getNearVehicle)")
    check(have, "with its key in the inventory (haveThisKeyId): the game draws CarKey over the head")
    if other then say("note: the car is hotwired or easy use is on, so the key shows without the key too") end
    shot("key")
end)
-- the key out: nothing expected
step(10, function()
    if not S.v then return end
    pcall(function() S.p:getInventory():Remove(S.key) end)
    S.keyOut = true
end)
step(40, function()
    if not S.v then return end
    local near, have, other = S.state("nokey")
    check(near and not have, "still beside it, the key out of the inventory (no key expected over the head" .. (other and ", but hotwired / easy use shows it anyway" or "") .. ")")
    shot("nokey")
end)
-- seated without the key, the engine tried: the CarKey_none line
step(10, function()
    if not S.v then return end
    S.moveTo(S.v:getX() + 2.5, S.v:getY() + 0.5)
end)
step(30, function()
    if not S.v then return end
    local ok, why = ZEDQA_CAR_ENTER(S.v, 0)
    S.inside = ok
    if not ok then say("not run: the no-key start (" .. tostring(why) .. ")"); return end
    pcall(function() S.v:setKeysInIgnition(false) end)
    local okT, e = pcall(function() S.v:tryStartEngine() end)
    say("in the driver's seat, no key: tryStartEngine " .. (okT and "called" or ("failed: " .. tostring(e))))
end)
step(12, function()
    if not S.inside then return end
    local line = nil
    pcall(function() line = S.p:getSayLine() end)
    say("the say line over the head: '" .. tostring(line) .. "'")
    local sp = ZeD.Bubbles and ZeD.Bubbles._sp and ZeD.Bubbles._sp[S.pn]
    say("ZeD's speech bubble holds: '" .. tostring(sp and sp.text) .. "'" .. ((sp and sp.text and string.find(tostring(sp.text), "img=", 1, true)) and " (the image tag as TEXT: ZeD drew the markup)" or ""))
    S.state("nokey_start")
    shot("nokey_start")
end)
step(40, function()
    if not S.inside then return end
    shot("nokey_start_late")
end)

-- ===================================================================== put back
step(10, function()
    if S.v then ZEDQA_CAR_AWAY(S.v, not S.keyOut and S.key or nil) end
end)
step(40, function()
    if S.v then
        local gone = true
        pcall(function()
            local it = getCell():getVehicles():iterator()
            while it:hasNext() do if it:next() == S.v then gone = false end end
        end)
        check(S.p:getVehicle() == nil, "put back: the character is out of the car")
        check(gone, "put back: the car is removed")
    end
    S.moveTo(S.hx, S.hy)
    say(S.fails == 0 and "all checks passed" or (S.fails .. " failed"))
    say("DONE")
end)

S.qi, S.wait = 1, nil
function S.tick()
    local s = S.Q[S.qi]
    if not s then Events.OnPreUIDraw.Remove(S.tick); return end
    S.wait = (S.wait or s.n) - 1
    if S.wait > 0 then return end
    S.wait = nil
    local ok, again = pcall(s.fn)
    if not ok then say("ERR step " .. S.qi .. ": " .. tostring(again)) end
    if not (ok and again == true) then S.qi = S.qi + 1 end
end
Events.OnPreUIDraw.Add(S.tick)
say("start")
