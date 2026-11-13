-- ZeDUI/tools/qa/zedqa_b8a_report.lua  (Nov 8 2026, hotfix beta 8a): in game, a copied bug report never names the
-- account. It plants a real Lua error (uncaught, in an event) whose words carry this computer's Zomboid folder and its
-- Windows user folder, both slash styles and mixed case, waits for Messages to file it, then copies it the three ways
-- the game offers: the Messages card's Copy on one error, its Copy on the source, and the ZeD wheel's Bug report (Copy
-- all). Each time it reads the clipboard back (Clipboard.getClipboard, 42.21) and checks: no user folder, no name, the
-- folders read ~/Zomboid and ~\ or ~/, and the last line says the name was taken out. The clipboard is put back.
-- grep "ZEDQA b8arp". The planted error stays in Messages (Clear removes it).
local TAG = "b8arp"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local npass, nfail = 0, 0
local function check(ok, what, d)
    ok = ok and true or false
    if ok then npass = npass + 1 else nfail = nfail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (d ~= nil and (" (" .. tostring(d) .. ")") or ""))
    return ok
end

local MS = ZeD.Messages
if not (MS and MS.scrub and MS.reportAll) then say("ERR this build has no report scrub"); say("DONE"); return end
local doc = tostring(getMyDocumentFolder() or "")
local home = string.match(doc, "^%a:[/\\][Uu][Ss][Ee][Rr][Ss][/\\][^/\\]+")
local name = home and string.match(home, "([^/\\]+)$")
say("Zomboid folder found: " .. ((doc ~= "") and "yes" or "no") .. ", under a Users folder: " .. (home and "yes" or "no"))
if not name then say("NOTE the Zomboid folder is not under C:\\Users here: the user-folder checks use a made-up path") end
local nm = name or "QaPerson"
local MARK = "ZEDQA-b8arp-planted"
local fwdDoc = string.gsub(doc, "\\", "/")
local mixedHome = "c:/USERS/" .. string.upper(nm)
local PLANT = MARK .. " in " .. doc .. "\\Lua\\b8arp.txt; " .. fwdDoc .. "/Saves/b8arp; "
    .. "C:\\Users\\" .. nm .. "\\AppData\\Local\\b8arp.tmp; " .. mixedHome .. "/Downloads/b8arp.lua"
local clipWas = Clipboard.getClipboard()

local function verify(label, text)
    text = tostring(text or "")
    local low = string.lower(text)
    check(string.find(text, MARK, 1, true) ~= nil, label .. ": the planted error is in the copy")
    check(not string.find(low, ":\\users\\", 1, true) and not string.find(low, ":/users/", 1, true), label .. ": no Users folder")
    check(not string.find(low, string.lower(nm), 1, true), label .. ": the account name is not in it")
    check(string.find(text, "~/Zomboid\\Lua\\b8arp.txt", 1, true) and string.find(text, "~/Zomboid/Saves/b8arp", 1, true), label .. ": the Zomboid folder reads ~/Zomboid")
    check(string.find(text, "~\\AppData\\Local\\b8arp.tmp", 1, true) and string.find(text, "~/Downloads/b8arp.lua", 1, true), label .. ": the user folder reads ~\\ and ~/")
    check(string.sub(text, -#MS.SCRUB_NOTE) == MS.SCRUB_NOTE, label .. ": the last line says the name was taken out")
end

-- where the planted error was filed: its source and its place in the kept list
local function planted()
    for srcName, s in pairs(MS.sources) do
        local it = s.kind == "err" and s.items[1]
        if it and it.k == "err" then
            for i, t in ipairs(it.texts) do if string.find(t, MARK, 1, true) then return srcName, i end end
        end
    end
    return nil
end

local plan, pi, pt = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function drive()
    local st = plan[pi]
    if not st then return end
    local now = getTimestampMs()
    if now - pt < st.ms then return end
    pt = now
    pi = pi + 1
    local ok, e = pcall(st.fn)
    if not ok then nfail = nfail + 1; say("FAIL ERR step " .. (pi - 1) .. ": " .. tostring(e)) end
    if pi > #plan then
        pcall(function() Clipboard.setClipboard(clipWas or "") end)
        say(npass .. " passed, " .. nfail .. " failed")
        say("DONE")
        Events.OnPreUIDraw.Remove(drive)
    end
end

add(100, function()
    local function boom() Events.OnTick.Remove(boom); error(PLANT) end
    Events.OnTick.Add(boom)
end)
add(4500, function()   -- (Messages reads the game's error list every two seconds)
    local src, i = planted()
    if not check(src ~= nil, "the planted error is filed in Messages") then return end
    -- the card's Copy on one error, as ZeD_MessagesWindow's pressCard does it
    local okC = pcall(function() ZeD_MessagesWindow.pressCard({ sel = src }, { copy = true, idx = i }) end)
    if not okC then Clipboard.setClipboard(MS.reportOne(src, i)) end
    verify("Copy (one error)", Clipboard.getClipboard())
    okC = pcall(function() ZeD_MessagesWindow.pressCard({ sel = src }, { copy = true }) end)
    if not okC then Clipboard.setClipboard(MS.report(src)) end
    verify("Copy (the source)", Clipboard.getClipboard())
    -- the wheel's Bug report (every error): its note is a modal, held back for the test
    local realModal = ISModalDialog
    ISModalDialog = { new = function() return { initialise = function() end, addToUIManager = function() end } end }
    local okB, err = pcall(MS.copyBugReport, 0)
    ISModalDialog = realModal
    check(okB, "Bug report copies", err)
    verify("Bug report (Copy all)", Clipboard.getClipboard())
end)
Events.OnPreUIDraw.Add(drive)
say("start")
