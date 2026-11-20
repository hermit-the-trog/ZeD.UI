-- ZeDUI/tools/qa/gallery_v1_mp_shot.lua  (Nov 17 2026, QA; ZeD-GUI 1.0 gallery, picture 75 "Playing on a Server"): on the
-- ADMIN client (mp_client2.ps1 -Main -Run), after gallery_v1_mp.txt staged it in a lit Muldraugh street and the other
-- players (bob, carl, dave: QA's own test accounts) stand beside it and have each said a line on the General chat.
-- The admin itself is "angel" (gallery_v1_mp_run.ps1 makes that account), so no "zedqa" shows in the player list; the
-- chat is cleared of every line but the players' own (the teleports answer there as server lines).
--   * daytime held: the server's clock at 11:00 (the shim's ZeDQA.time) and the client's held there every frame for
--     the picture; clear sky; the time controls (top right) out of the UI for the picture; 4K at UI scale 1.75x
--   * the Character window alone, on the Server tab scrolled to its foot (PLAYERS: who is on the server), against the
--     left edge; the World window shut; the chat window on its General tab against the top right; the character and
--     the other players in the street between them, uncovered
--   * waits for the others within 7 squares and for chat lines from at least two of them (each up to 3 minutes), then
--     for the windows to keep still, then g1_75_server.png. If the chat window and the Character window overlap
--     (they do not fit in one picture), a second picture g1_75_chat.png with the Character window shut.
-- The pointer stays hidden by gallery_unload.lua (run in the manifest; gallery_reload.lua after this puts the load
-- back). Puts back: the clock hold, the time controls, the scale, the chat window shut. grep "ZEDQA g1mps".
G1S = {}
local G = G1S
G.p = getPlayer()
G.core = getCore()
G.Chat = ZeD.Chat
G.Sc = ZeD.Scale
G.guests = {}
function G.say(s) print("ZEDQA g1mps " .. tostring(s)) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
-- poll: fn every n frames until it returns true, at most max times
local function poll(n, max, fn) Q[#Q + 1] = { n = n, fn = fn, poll = true, max = max, tries = 0 } end

-- the other players' names (gallery_v1_mp_run.ps1 writes them, one a line)
pcall(function()
    local r = getFileReader("zedqa_cang_guests.txt", false)
    if not r then return end
    local l = r:readLine()
    while l do
        if l ~= "" then G.guests[#G.guests + 1] = l end
        l = r:readLine()
    end
    r:close()
end)
function G.others()
    local out = {}
    pcall(function()
        local l = getOnlinePlayers()
        for i = 0, l:size() - 1 do
            local o = l:get(i)
            if o ~= G.p and math.abs(o:getX() - G.p:getX()) <= 7 and math.abs(o:getY() - G.p:getY()) <= 7 then out[#out + 1] = tostring(o:getUsername()) end
        end
    end)
    return out
end
G.me = tostring(G.p:getUsername())
G.isGuest = {}
for _, g in ipairs(G.guests) do G.isGuest[g] = true end
-- a player's own line: written by one of the other players, not a server line (the teleports' replies, the welcome)
function G.playerLine(ln)
    return ln.author ~= nil and ln.author ~= G.me and ln.kind ~= "server" and (#G.guests == 0 or G.isGuest[ln.author] == true)
end
function G.chatAuthors()
    local seen, n = {}, 0
    for _, ln in ipairs(G.Chat.lines or {}) do
        if G.playerLine(ln) and not seen[ln.author] then seen[ln.author] = true; n = n + 1 end
    end
    return n
end
-- the chat cleared of everything but the players' own lines (QA's teleports answer on the chat as server lines)
function G.onlyPlayers()
    local keep, cut = {}, 0
    for _, ln in ipairs(G.Chat.lines or {}) do
        if G.playerLine(ln) then keep[#keep + 1] = ln else cut = cut + 1 end
    end
    G.Chat.lines = keep
    G.Chat.unreadN = 0
    if G.Chat.win then G.Chat.win._dirty = true end
    return cut
end
function G.cw() return ZeD_CharacterWindow.getWindow() end
function G.ww() return ZeD_WorldWindow.getWindow() end
function G.rect(w) return { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() } end
function G.overlap(a, b) return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h end
function G.shape()
    local s = GAL_SHAPE and GAL_SHAPE() or ""
    local w = G.Chat.win
    if w and w:getIsVisible() then s = s .. string.format("|chat %d,%d,%d,%d", math.floor(w:getX()), math.floor(w:getY()), math.floor(w:getWidth()), math.floor(w:getHeight())) end
    return s
end
function G.shot(name)
    local ok = pcall(function() G.core:TakeFullScreenshot(name) end)
    G.say("shot " .. name .. " " .. tostring(ok))
end

-- 1. daytime, clear sky, fresh, 1.75x, time controls out
step(5, function()
    pcall(function() sendClientCommand(G.p, "ZeDQA", "time", { h = 11.0 }) end)
    pcall(function() sendClientCommand(G.p, "ZeDQA", "fresh", {}) end)
    G.day = function() pcall(function() getGameTime():setTimeOfDay(11.0) end) end
    Events.OnTick.Add(G.day)
    pcall(function() UIManager.RemoveElement(UIManager.getSpeedControls()); G.speedOut = true end)
    pcall(function()
        local cm = getClimateManager()
        for i = 0, cm:getFloatMax() - 1 do
            local v = cm:getClimateFloat(i)
            local l = tostring(v:getName()):lower()
            if l:find("fog", 1, true) or l:find("precip", 1, true) or l:find("cloud", 1, true) then v:setEnableAdmin(true); v:setAdminValue(0) end
        end
    end)
    if G.Sc and G.Sc.root and math.abs(G.Sc.root() - 1.75) > 0.01 then
        G.scaleWas = G.Sc.override; G.Sc.override = 1.75; G.Sc.refresh(); ZeD.applyTheme(); G.scaled = true
    end
    G.say(string.format("guests expected %d (%s) | screen %dx%d | scale %s", #G.guests, table.concat(G.guests, ", "),
        math.floor(G.core:getScreenWidth()), math.floor(G.core:getScreenHeight()), tostring(G.Sc and G.Sc.root and G.Sc.root())))
end)
-- 2. the others beside the admin
poll(30, 360, function() return #G.others() >= math.max(1, #G.guests) end)
step(5, function()
    local o = G.others()
    G.say((#o >= math.max(1, #G.guests) and "PASS" or "FAIL") .. " players beside the admin: " .. #o .. " (" .. table.concat(o, ", ") .. ")")
    G.p:setDir(IsoDirections.SE)
end)
-- 3. zoom 0.75 (as the closing break, gallery_cinema_lib.lua C.zoom), so the players read at gallery size
G.zoomLeft = nil
poll(20, 20, function()
    if G.zoomLeft == nil then G.zoomLeft = math.floor((G.core:getZoom(0) - 0.75) / 0.25 + 0.5) end
    if G.zoomLeft == 0 then return true end
    G.core:doZoomScroll(0, (G.zoomLeft > 0) and -1 or 1)
    G.zoomLeft = (G.zoomLeft > 0) and (G.zoomLeft - 1) or (G.zoomLeft + 1)
    return G.zoomLeft == 0
end)
step(90, function() G.say("zoom " .. tostring(G.core:getZoom(0))) end)
-- 4. the Character window alone on the Server tab, at the left edge
step(10, function()
    if not (ZeD_CharacterWindow.isOpen and ZeD_CharacterWindow.isOpen(0)) then ZeD_CharacterWindow.toggleBothPaired(0) end
    if ZeD_Window and ZeD_Window.resetLayout then pcall(ZeD_Window.resetLayout) end
end)
step(30, function()
    local ok = pcall(function() ZeD_CharacterWindow.openTab(0, "server") end)
    local w = G.ww()
    if w then w:setVisible(false) end
    G.say("server tab " .. tostring(ok) .. " -> " .. tostring(G.cw() and G.cw()._activeTab))
end)
step(30, function()
    local c = G.cw()
    local m = math.floor(G.core:getScreenWidth() * 0.012)
    c:setX(m); c:setY(math.floor(G.core:getScreenHeight() * 0.04))
    -- the foot: PLAYERS, who is on the server
    local st = c._serverTab
    if st then
        pcall(function() st.scroll:setScrollPos(1) end)
        pcall(function() st.off = 100000 end)
    end
    G.say(string.format("character window at %d,%d %dx%d, server tab %s", math.floor(c:getX()), math.floor(c:getY()), math.floor(c:getWidth()), math.floor(c:getHeight()), tostring(st ~= nil)))
end)
-- 5. the chat on General, against the top right
step(10, function()
    G.Chat.tab = "general"
    local win = G.Chat.open(false)
    if not win then G.say("FAIL the chat window did not open (ZeD.Chat.active " .. tostring(G.Chat.active()) .. ")"); return end
    local W, H = G.core:getScreenWidth(), G.core:getScreenHeight()
    local cw, ch = math.floor(W * 0.27), math.floor(H * 0.30)
    pcall(function() win:setWidth(cw); win:setHeight(ch) end)
    win:setX(W - win:getWidth() - math.floor(W * 0.012)); win:setY(math.floor(H * 0.04))
    win._dirty = true
    G.say(string.format("chat window at %d,%d %dx%d", math.floor(win:getX()), math.floor(win:getY()), math.floor(win:getWidth()), math.floor(win:getHeight())))
end)
-- 6. lines from at least two of the others
poll(30, 360, function() return G.chatAuthors() >= math.min(2, math.max(1, #G.guests)) end)
step(5, function()
    local names = {}
    for _, ln in ipairs(G.Chat.lines or {}) do if ln.author then names[#names + 1] = ln.author end end
    G.say((G.chatAuthors() >= 2 and "PASS" or "FAIL") .. " chat lines from " .. G.chatAuthors() .. " other players (authors in order: " .. table.concat(names, ", ") .. ")")
    G.say("chat cleared of " .. G.onlyPlayers() .. " lines that were not the players' own; " .. #G.Chat.lines .. " left")
    if G.Chat.win then G.Chat.win._dirty = true; G.Chat.win._usedAt = getTimestampMs() end
    G.p:setDir(IsoDirections.SE)
end)
-- 7. still, then the picture
G.last, G.same = nil, 0
poll(1, 900, function()
    local s = G.shape()
    if s == G.last then G.same = G.same + 1 else G.last, G.same = s, 0 end
    return G.same >= (GAL_STILL or 20) + 10
end)
step(2, function()
    -- (the chat dims when left alone: woken just before the picture; any late server line cut again)
    G.onlyPlayers()
    if G.Chat.win then G.Chat.win._usedAt = getTimestampMs() end
    G.say(string.format("time %.2f | others beside %d | shape %s", getGameTime():getTimeOfDay(), #G.others(), G.shape()))
    G.shot("g1_75_server.png")
end)
-- 8. a second picture only when the two windows overlap
step(30, function()
    local c, w = G.cw(), G.Chat.win
    G.both = c and w and c:getIsVisible() and w:getIsVisible() and G.overlap(G.rect(c), G.rect(w))
    G.say("chat and character window overlap: " .. tostring(G.both and true or false) .. (G.both and " (g1_75_chat.png next)" or " (one picture holds both)"))
    if G.both then c:setVisible(false) end
end)
step(60, function()
    if not G.both then return end
    if G.Chat.win then G.Chat.win._usedAt = getTimestampMs() end
    G.shot("g1_75_chat.png")
end)
-- put back
step(20, function()
    if G.day then Events.OnTick.Remove(G.day) end
    if G.speedOut then pcall(function() UIManager.AddUI(UIManager.getSpeedControls()) end) end
    pcall(function() UIManager.getSpeedControls():setVisible(true) end)
    if G.scaled then G.Sc.override = G.scaleWas; G.Sc.refresh(); ZeD.applyTheme() end
    pcall(function() if G.Chat.win then G.Chat.win:close() end end)
    G.say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    local ok, r = pcall(s.fn)
    if not ok then G.say("ERR step " .. qi .. ": " .. tostring(r)) end
    if s.poll and ok and not r then
        s.tries = s.tries + 1
        if s.tries < s.max then return end
        G.say("poll at step " .. qi .. " gave up after " .. s.tries .. " tries")
    end
    qi = qi + 1
end
Events.OnPreUIDraw.Add(tick)
G.say("start")
