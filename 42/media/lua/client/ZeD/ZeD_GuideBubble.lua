-- ZeD-UI/42/media/lua/client/ZeD/ZeD_GuideBubble.lua
-- ============================================================================
-- THE SURVIVAL GUIDE'S BUBBLE (punch list 122). Client; a small driver over Messages (ZeD_Messages.lua).
--
-- The guide used to open full screen when a game started. Now it waits, and the first time anyone starts a game
-- with ZeD, about 30 seconds after the game is playable, a speech bubble comes out of the belt's Messages icon: the
-- survival guide is here, press F1 (or, on a controller, the Help wheel). It introduces the notices and the guide in
-- one. A click on the bubble opens the guide; a right-click dismisses it; the line stays in Messages with an Open.
-- Until the guide is opened or the bubble dismissed it comes back now and then through the first hour of play.
--
-- Only ever once: the first showing writes Zomboid/Lua/ZeD_guidebubble.txt, and a game that finds that file never
-- starts the clock. A game that ends before the bubble shows leaves the file alone. Player one only (a split-screen
-- partner has no belt of their own to wait on), and nothing on a server. The game's "Show the guide on startup"
-- option, if unticked, keeps the bubble away too. The clock is G.tick(now), called every game tick; nothing here uses
-- % on the ms clock (Kahlua gets it wrong past 2^31).
-- ============================================================================

require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.GuideBubble = ZeD.GuideBubble or {}
local G = ZeD.GuideBubble

G.FIRST_MS = 30000        -- after the game is playable
G.EVERY_MS = 720000       -- between one showing and the next: 12 minutes
G.HOUR_MS = 3600000       -- no showing after the first hour of play
G.SHOW_MS = 20000         -- how long the bubble stays up (it is long to read)
G.RETRY_MS = 5000         -- a showing held back (paused, guide open, dead) is tried again this often
local FILE = "ZeD_guidebubble.txt"
local KEY = "guide"

G.st = G.st or nil        -- this game's state: { t0, nextAt, shows, done, why }

-- ---------------------------------------------------------------------------
-- once ever, kept in a file under Zomboid/Lua (the way ZeD keeps its other first-time flags)
-- ---------------------------------------------------------------------------
function G.seenEver()
    local r = nil
    pcall(function() r = getFileReader(FILE, false) end)
    if not r then return false end
    local seen = false
    pcall(function()
        local l = r:readLine()
        while l do
            if l:match("^shown=1") then seen = true end
            l = r:readLine()
        end
    end)
    pcall(function() r:close() end)
    return seen
end

function G.markShown()
    pcall(function()
        local w = getFileWriter(FILE, true, false)
        if not w then return end
        w:write("shown=1\n")
        w:close()
    end)
end

-- ---------------------------------------------------------------------------
-- the words and the line in Messages
-- ---------------------------------------------------------------------------
function G.head() return ZeD.tr("UI_ZeD_Settings_Guide") end

--- The bubble's text, the key following the device in use (the guide's own device-aware names).
function G.text(pn)
    local key = "F1"
    if ZeD.Guide and ZeD.Guide.bubbleKey then key = ZeD.Guide.bubbleKey(pn or 0) end
    return ZeD.tr("UI_ZeD_Guide_Bubble", key)
end

--- True while the line is still in Messages (clearing the source is a way to say no thanks).
function G.lineKept()
    local M = ZeD.Messages
    local s = M and M.sources and M.sources[G.head()]
    for _, it in ipairs(s and s.items or {}) do
        if it.k == "notice" and it.key == KEY then return true end
    end
    return false
end

--- Click on the bubble, or Open on its line: the guide, on player one.
function G.open()
    if ZeD.Guide and ZeD.Guide.open then ZeD.Guide.open(0) end
end

--- Ends the offer for this game: opened (the guide came up by any road), dismissed (right-click) or cleared.
function G.done(why)
    local st = G.st
    if not st or st.done then return end
    st.done, st.why = true, why
    if why == "opened" then G.markShown() end   -- (the player found the guide by themself: no offer next game either)
    if st.toast and ZeD.Messages and ZeD.Messages.dropToast then ZeD.Messages.dropToast(st.toast) end
    st.toast = nil
end

function G.dismiss() G.done("dismissed") end

-- ---------------------------------------------------------------------------
-- the clock
-- ---------------------------------------------------------------------------
--- A new game: arm the clock unless this machine has had its bubble already (or the game is not for it).
function G.start()
    G.st = nil
    if isServer and isServer() then return end
    local core = getCore()
    if tostring(core:getGameMode()) == "Tutorial" then return end          -- (the tutorial teaches its own steps)
    if not core:getOptionShowSurvivalGuide() then return end
    if G.seenEver() then return end
    G.st = { shows = 0 }
end

-- the game is playable: a player one in the world, the main menu gone
local function playable()
    if MainScreen and MainScreen.instance and MainScreen.instance:isVisible() then return false end
    local p = getSpecificPlayer and getSpecificPlayer(0)
    if not p then return false end
    local dead = false
    pcall(function() dead = p:isDead() end)
    return not dead
end

-- a moment not to speak in: the game paused (the guide, Escape's menu), or the guide itself up
local function held()
    local sp = nil
    pcall(function() sp = getGameSpeed() end)
    if sp == 0 then return true end
    local W = ZeD.Guide
    local win = W and W.windows and W.windows[0]
    if win and win.isReallyVisible and win:isReallyVisible() then return true end
    local B = ZeD.GuideBook
    return (B and B.isOpen and B.isOpen(0)) and true or false
end

--- Called every game tick with the ms clock; shows the bubble when its time has come.
function G.tick(now)
    local st = G.st
    if not st or st.done then return end
    if not playable() then return end
    st.t0 = st.t0 or now
    -- (the hour of play runs out: no more showings)
    if now - st.t0 >= G.HOUR_MS then G.done("hour"); return end
    -- the line cleared from Messages after a showing: that is a no
    if st.shows > 0 and not G.lineKept() then G.done("cleared"); return end
    st.nextAt = st.nextAt or (st.t0 + G.FIRST_MS)
    if now < st.nextAt then return end
    if held() then st.nextAt = now + G.RETRY_MS; return end
    local M = ZeD.Messages
    if not (M and M.notice) then return end
    local _, t = M.notice(G.head(), G.text(0), { key = KEY, run = G.open, dismiss = G.dismiss, ms = G.SHOW_MS, long = true, pn = 0 })
    if not t then
        -- the balloons are off in ZeD setup: the line waits in Messages, and the bubble is not offered again this game
        G.done("off")
        return
    end
    st.toast = t
    st.shows = st.shows + 1
    st.nextAt = now + G.EVERY_MS
    if st.shows == 1 then G.markShown() end
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(G.start)
    Events.OnTick.Add(function()
        local ok, err = pcall(G.tick, getTimestampMs())
        if not ok and ZeD.logOnce then ZeD.logOnce("guide bubble", err) end
    end)
end
