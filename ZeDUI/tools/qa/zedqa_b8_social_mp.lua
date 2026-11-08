-- ZeDUI/tools/qa/zedqa_b8_social_mp.lua  (Nov 7 2026, QA; tag b8so): two outside-review fixes of beta 7 that need a multiplayer client.
-- Run on the local test server's client as its admin (pwsh -File ZeDUI/tools/qa/mp_server.ps1 -Start -Mods "ZeD_UI;ZeDQAShim", then
-- zedqa_run.ps1 -Mp -Manifest ZeDUI/tools/qa/b8_menus_review_mp.txt). In single player the script says NOTE and ends.
--   mute     (item 9, f8ff66e2) Mute on the card of an account that is off: with the server part the server's mute list takes the name
--            (a_mute asked and answered), the game's /voiceban is NOT sent for it (it finds only a player who is on), the card says so, and
--            Unmute undoes it. The account is a made-up name, "b8qa_offline_probe", unmuted again at the end (also if a step fails).
--   whisper  (item 10, 3eafb70f) the chat line empties once a whisper went, "/w name " comes back when the line is opened again, and
--            empties again if left untouched. The game's whisper call is stood in for while the check runs (nobody is whispered to).
-- Restores SendCommandToServer, proceedPM and the chat window. grep "ZEDQA b8so".
local TAG = "b8so"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local Q = { pass = 0, fail = 0 }
local function verdict(ok, what)
    if ok then Q.pass = Q.pass + 1 else Q.fail = Q.fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what)
    return ok
end
local function shot(name) pcall(function() getCore():TakeFullScreenshot("zqa_b8_so_" .. name .. ".png") end) end

if not isClient() then say("NOTE not a multiplayer client: nothing to check here"); say("DONE"); return end

local Adm, C = ZeD.Admin, ZeD.Chat
local USER = "b8qa_offline_probe"
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local S = { sent = {}, answer = nil }

local realSend, realPM = SendCommandToServer, proceedPM
local function restore()
    SendCommandToServer, proceedPM = realSend, realPM
end

-- mute
at(10, function()
    verdict(Adm ~= nil and Adm.mute ~= nil, "ZeD.Admin.mute exists")
    say("server part live: " .. tostring(Adm.live and Adm.live()) .. ", my role " .. tostring(getPlayer():getAccessLevel()))
    if not (Adm.live and Adm.live()) then say("NOTE no server part: Mute on an offline card is the game's voice ban alone (gray); the live path is not checked"); S.skipMute = true; return end
    SendCommandToServer = function(cmd, ...)
        S.sent[#S.sent + 1] = tostring(cmd)
        return realSend(cmd, ...)
    end
    Adm.mute(USER, true, function(a) S.answer = a end, false)
end)
at(120, function()
    if S.skipMute then return end
    local a = S.answer
    say("a_mute answer: " .. tostring(a and a.ok) .. (a and a.err and (" " .. tostring(a.err)) or ""))
    verdict(a ~= nil and a.ok == true, "item 9: the server took the mute of an account that is off")
    verdict(Adm.isMuted(USER), "item 9: the mute list holds the name (" .. tostring(Adm.isMuted(USER)) .. ")")
    local voice = false
    for _, c in ipairs(S.sent) do if c:find("voiceban", 1, true) then voice = true end end
    verdict(not voice, "item 9: the game's /voiceban was not sent for an account that is off (" .. table.concat(S.sent, " | ") .. ")")
    S.answer, S.sent = nil, {}
    Adm.mute(USER, false, function(a2) S.answer = a2 end, false)
end)
at(240, function()
    if S.skipMute then return end
    verdict(S.answer ~= nil and S.answer.ok == true, "item 9: Unmute is taken too")
    verdict(not Adm.isMuted(USER), "item 9: the name is off the mute list again")
    SendCommandToServer = realSend
end)

-- whisper
at(260, function()
    if not (C and C.active and C.active()) then say("NOTE the ZeD chat is not active on this client: whisper not checked"); S.skipChat = true; return end
    proceedPM = function(t)
        local q = t:match('^%s*"([^"]+)"')
        return q or t:match("^%s*(%S+)") or ""
    end
    C.keep = nil
    S.win = C.open(false)
    S.openedChat = S.win ~= nil
end)
at(300, function()
    if S.skipChat then return end
    local w = C.win
    if not w then verdict(false, "item 10: the chat window opened"); return end
    C.tab, C.slowUntil = "general", 0
    w.input:setText("/w mike_d you there?")
    w.input:focus()
    w:submit()
    say("keep after the whisper: " .. tostring(C.keep and C.keep.text))
    verdict(w.input:getText() == "", "item 10: the line is empty once the whisper went")
    verdict(C.keep ~= nil and C.keep.text == "/w mike_d ", "item 10: the chat remembers '/w mike_d '")
    w:update()
    verdict(w.input:getText() == "", "item 10: it stays empty while you are out of the line")
    w:focusInput()
    verdict(w.input:getText() == "/w mike_d " and w.input:isFocused(), "item 10: opened again, the whisper's start comes back (" .. tostring(w.input:getText()) .. ")")
    shot("whisper_prefill")
    w.input:unfocus()
    w:update()
    verdict(w.input:getText() == "", "item 10: left untouched, the line empties again")
end)
at(340, function()
    restore()
    if C and C.keep then C.keep = nil end
    if S.openedChat and C.win then pcall(function() C.win:setVisible(false) end) end
    -- the probe name must not stay on the server's list
    if Adm and Adm.isMuted and Adm.isMuted(USER) then say("ERR the probe name is still muted: unmuting"); pcall(Adm.mute, USER, false, nil, false) end
    say("summary: " .. Q.pass .. " PASS, " .. Q.fail .. " FAIL")
    say("DONE")
end)

local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do
        if s.n == tick then
            local ok, e = pcall(s.fn)
            if not ok then say("ERR step " .. s.n .. ": " .. tostring(e)); restore() end
        end
    end
    if tick > 345 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
