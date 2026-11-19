-- ZeDUI/tools/qa/zedqa_menu_welcome.lua  (Nov 19 2026, QA; tag mwel): MAIN MENU ONLY, pushed through the QA bridge.
-- The FEATURE_MAP rows "First-launch setup ..." and "Save and load a setup ..." (beta 21, ZeD_MainMenuWelcome.lua,
-- Settings.lua saveSetup / loadSetup / hasSetup). Every press goes through the window's own activate path (the
-- spec's id set as the focus, then the window's joyA, as a player's A), and the desk's Settings menu row through its
-- pull-down hit (the pointer's release). What it checks:
--   1. the first-run rule (ZeD_MainMenuOptionGroups.lua firstRun, a local reached only at boot from OnMainMenuEnter):
--      ZeD.QAAutoload is not set on this launch; with no ZeD_setup_seen.txt at the start the desk opened the welcome
--      by itself; with the file there it did not (welcome_run.ps1 makes one launch of each); ZeD.Welcome.seen()
--      matches the file. The autoload branch ("never on a QA autoload launch") needs an autoload launch, which
--      continues a save: not checked here beyond the flag being unset.
--   2. the desk's Settings menu has "ZeD setup: pick, save or load" and its row opens the welcome view; the window is
--      on screen; the three ways (way:1..3); MM.openWelcome() opens it too
--   3. Pick your own: Style, Theme, Text size, Moodles place and Accent set live (the options' values,
--      ZeD.Settings.lite(), ZeD.currentBase / currentSize / currentAccent); Playing with takes Controller
--   4. Skip (the Skip card, then the band's button): every option back to its value when the window opened
--   5. Tutorial: Show me around then Done writes ZeD_tutorial.txt = 1; No thanks then Done writes 0
--   6. Save setup writes ZeD_setup.txt with every ZeD option; hasSetup() true; options changed by picks; Load a setup
--      then Done restores every option exactly; loadSetup() returns one per option line
-- What it puts back: every ZeD option as found (and the theme on screen), ModOptions.ini line for line, the first
-- line(s) of ZeD_setup.txt / ZeD_tutorial.txt / ZeD_setup_seen.txt when they were there. A file that was not there
-- before is left for welcome_run.ps1 to delete (Lua cannot delete); the wrapper also puts all four back byte for byte.
--
-- Run ONLY through the wrapper (it keeps the director's four files safe, and makes the two boot launches):
--   pwsh -NoProfile -File ZeDUI/tools/qa/welcome_run.ps1
-- Lines: "ZEDQA mwel PASS ..." / "FAIL ..." / "SKIP ..." / "ERR ...", then "VERDICT PASS n" or "VERDICT FAIL n",
-- then DONE. grep "ZEDQA mwel".
local MM = ZeD.MainMenu
local St = ZeD.Settings
local WL = ZeD.Welcome
local function say(s) print("ZEDQA mwel " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, what, detail)
    if ok then pass = pass + 1 else fail = fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (detail ~= nil and (" | " .. tostring(detail)) or ""))
end
local keep = {}
local K = {}

-- ---- the stages: after(n, fn) runs fn n ticks after the one before; waitFor(cond, max, fn) as soon as cond is true
-- (fn(true)) or after max ticks (fn(false))
local stages, si, cnt = {}, 1, 0
local function after(n, fn) stages[#stages + 1] = { n = n, fn = fn } end
local function waitFor(cond, max, fn) stages[#stages + 1] = { n = max, cond = cond, fn = fn } end

-- ---- options
function K.opts() return St and St.opts end
function K.opt(id) local o = K.opts(); return o and o.dict and o.dict[id] end
function K.val(id)
    local o = K.opt(id)
    local v = nil
    if o then pcall(function() v = o:getValue() end) end
    return v
end
-- every option Skip and Save setup cover: an id, a getValue, not a multiple tickbox, not a button, a plain value
function K.snapAll()
    local t = {}
    for _, o in ipairs((K.opts() and K.opts().data) or {}) do
        if o.id and o.getValue and o.type ~= "multipletickbox" and o.type ~= "button" then
            local ok, v = pcall(o.getValue, o)
            if ok and v ~= nil and type(v) ~= "table" then t[o.id] = v end
        end
    end
    return t
end
function K.count(t) local n = 0; for _ in pairs(t or {}) do n = n + 1 end; return n end
-- the ids whose values differ between two snapshots (either side)
function K.diff(a, b)
    local bad, seen = {}, {}
    for id, v in pairs(a or {}) do seen[id] = true; if (b or {})[id] ~= v then bad[#bad + 1] = id .. "=" .. tostring(v) .. "/" .. tostring((b or {})[id]) end end
    for id, v in pairs(b or {}) do if not seen[id] then bad[#bad + 1] = id .. "=nil/" .. tostring(v) end end
    table.sort(bad)
    return bad
end
function K.short(list)
    local out = {}
    for i, s in ipairs(list) do if i <= 8 then out[#out + 1] = s end end
    if #list > 8 then out[#out + 1] = "(+" .. (#list - 8) .. " more)" end
    return table.concat(out, " ")
end
function K.setAll(t)
    for id, v in pairs(t or {}) do
        local o = K.opt(id)
        if o and o.setValue and K.val(id) ~= v then pcall(function() o:setValue(v) end) end
    end
    if St.applyThemeNow then pcall(St.applyThemeNow) end
end

-- ---- files in Zomboid/Lua
function K.readLines(name)
    local t = nil
    pcall(function()
        local r = getFileReader(name, false)
        if not r then return end
        t = {}
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        r:close()
    end)
    return t
end
function K.writeLines(name, lines, eol)
    if not lines then return end
    pcall(function()
        local w = getFileWriter(name, true, false)
        for i, l in ipairs(lines) do
            w:write(l)
            if eol or i < #lines then w:write(eol or "\n") end
        end
        w:close()
    end)
end
function K.same(a, b)
    if a == nil or b == nil then return a == b end
    return table.concat(a, "\n") == table.concat(b, "\n")
end
-- the setup file as id -> value text, and its option lines' count
function K.readSetup()
    local map, n = {}, 0
    for i, l in ipairs(K.readLines(St.SETUP_FILE) or {}) do
        local at = string.find(l, "=", 1, true)
        if i > 1 and at and at > 1 then map[string.sub(l, 1, at - 1)] = string.sub(l, at + 1); n = n + 1 end
    end
    return map, n
end

-- ---- the window and the player's presses
function K.W() return MM.root and MM.root.welcomeWin end
function K.open() local w = K.W(); return MM.view == "welcome" and w ~= nil and w:isVisible() end
function K.spec(id)
    local w = K.W()
    for _, s in ipairs((w and w._specs) or {}) do if s.id == id then return s end end
    return nil
end
-- a press as the player's A: the spec's id becomes the focus, the window's joyA runs the focused spec
function K.press(id)
    local w = K.W()
    local why = nil
    if not K.open() then why = "the welcome window is not open (view " .. tostring(MM.view) .. ")"
    else
        local s = K.spec(id)
        if not s then why = "no spec " .. id
        elseif s.disabled then why = id .. " is disabled"
        else
            w.focusId = id
            local rows, ri, ci = w:focusPos()
            if not ri or rows[ri][ci].id ~= id then why = "the focus did not land on " .. id
            else w:joyA() end
        end
    end
    if why then fail = fail + 1; say("FAIL press " .. id .. " | " .. why) end
    return why == nil
end
-- the item of a row other than the one picked now (a pick that changes something)
function K.other(key)
    if key == "theme" then return (ZeD.currentBase ~= "light") and 2 or 1 end
    if key == "text" then return (ZeD.currentSize ~= "large") and 2 or 1 end
    if key == "style" then return (K.val("lookStyle") == 1) and 2 or 1 end
    if key == "moodles" then return (K.val("moodlePlace") == 1) and 2 or 1 end
    if key == "accent" then return (K.val("accentColor") == 3) and 4 or 3 end
    return 2
end
local THEME_KEYS = { "dark", "light", "hicon" }
local SIZE_KEYS = { "small", "large" }
-- a pick through the window: opt:<row>:<n>, or opt:accent:<n>
function K.pick(key)
    local i = K.other(key)
    keep.picked = i
    K.press("opt:" .. key .. ":" .. i)
    return i
end
function K.lines(name) local t = K.readLines(name); return t and table.concat(t, "/") or "(no file)" end

-- =========================================================================================================
-- 0: as found
after(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    check(MM and MM.openWelcome and MM.menuItems and WL and WL.ROWS and St and St.saveSetup and St.loadSetup and St.hasSetup and St.opts,
        "the welcome's parts are loaded (MM.openWelcome, ZeD.Welcome, ZeD.Settings.saveSetup / loadSetup / hasSetup)")
    keep.opt0 = K.snapAll()
    keep.ini0 = K.readLines("ModOptions.ini")
    keep.setup0 = K.readLines(St.SETUP_FILE)
    keep.tut0 = K.readLines(WL.TUTORIAL_FILE)
    keep.seen0 = K.readLines(WL.SEEN_FILE)
    keep.look0 = { ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize }
    say("as found: " .. K.count(keep.opt0) .. " options; theme " .. tostring(ZeD.currentBase) .. ", accent " .. tostring(ZeD.currentAccent)
        .. ", size " .. tostring(ZeD.currentSize) .. "; ZeD_setup.txt " .. (keep.setup0 and "there" or "absent") .. ", ZeD_tutorial.txt "
        .. (keep.tut0 and "there" or "absent") .. ", ZeD_setup_seen.txt " .. (keep.seen0 and "there" or "absent") .. "; view " .. tostring(MM.view))
    check(ZeD.QAAutoload ~= true, "first run: this launch is not a QA autoload (ZeD.QAAutoload is not set)", tostring(ZeD.QAAutoload))
end)

-- 1: the first-run rule, as the desk decided at boot (firstRun waits 120 ticks and the fade-in, up to 1200)
waitFor(function() return keep.seen0 == nil and MM.view == "welcome" end, 900, function()
    if keep.seen0 == nil then
        check(MM.view == "welcome" and K.open(), "first run: with no ZeD_setup_seen.txt and no QA autoload, the desk opened the welcome by itself", tostring(MM.view))
        check(WL.seen() == false, "first run: ZeD.Welcome.seen() is false with no ZeD_setup_seen.txt")
    else
        check(MM.view ~= "welcome", "first run: with ZeD_setup_seen.txt there, the desk did not open the welcome", tostring(MM.view))
        check(WL.seen() == true, "first run: ZeD.Welcome.seen() is true with ZeD_setup_seen.txt there", K.lines(WL.SEEN_FILE))
    end
    -- back to the desk with nothing answered (the boot's window, if any, leaves as it came)
    if MM.view ~= "main" then MM.showView("main") end
end)

-- 2: the desk's Settings menu
after(20, function()
    local items = {}
    pcall(function() items = MM.menuItems("settings") or {} end)
    keep.menuIdx = nil
    for i, it in ipairs(items) do
        if type(it) == "table" and it.text == ZeD.tr("UI_ZeD_Welcome_MenuItem") then keep.menuIdx = i; keep.menuItem = it end
    end
    local word = keep.menuItem and keep.menuItem.text
    check(word == "ZeD setup: pick, save or load", "the desk's Settings menu has \"ZeD setup: pick, save or load\"", tostring(word))
    MM.ctx.open = "settings"   -- the menu title pressed: its pull-down opens
end)
after(20, function()
    local drop = MM.root and MM.root.drop
    local hit = nil
    local hid = "drop:settings:" .. tostring(keep.menuIdx)
    for _, h in ipairs((drop and drop._hits) or {}) do if h.id == hid then hit = h end end
    check(hit ~= nil and hit.fn ~= nil and drop:isVisible(), "the Settings menu's pull-down shows the row", hid)
    -- the pointer's release over the row: the menu closes, the row's fn runs
    MM.ctx.open = nil
    if hit and hit.fn then hit.fn()
    elseif keep.menuItem and keep.menuItem.fn then say("(the pull-down row was not found: its fn is called directly)"); keep.menuItem.fn() end
end)
after(20, function()
    local w = K.W()
    check(K.open(), "the Settings menu row \"ZeD setup: pick, save or load\" opens the welcome view", tostring(MM.view))
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local ok = w ~= nil and w:isVisible() and w.width > 0 and w.height > 0 and w:getAbsoluteX() >= 0 and w:getAbsoluteY() >= 0
        and w:getAbsoluteX() + w.width <= sw and w:getAbsoluteY() + w.height <= sh
    check(ok, "the welcome window is on screen", w and (w:getAbsoluteX() .. "," .. w:getAbsoluteY() .. " " .. w.width .. "x" .. w.height .. " on " .. sw .. "x" .. sh) or "no window")
    check(K.spec("way:1") ~= nil and K.spec("way:2") ~= nil and K.spec("way:3") ~= nil, "the welcome has the three ways (way:1 Pick your own, way:2 Load a setup, way:3 Skip)")
    MM.showView("main")
end)
after(15, function()
    check(MM.view == "main", "the desk is back on the main view", tostring(MM.view))
    MM.openWelcome()
end)

-- 3: Pick your own, live
after(20, function()
    check(K.open(), "MM.openWelcome() opens the welcome view", tostring(MM.view))
    keep.snapOpen = K.snapAll()   -- what Skip must put back
    local missing = {}
    for _, row in ipairs(WL.ROWS or {}) do
        for i = 1, #row.items do if not K.spec("opt:" .. row.key .. ":" .. i) then missing[#missing + 1] = row.key .. ":" .. i end end
    end
    for i = 1, #(St.accentKeys or {}) do if not K.spec("opt:accent:" .. i) then missing[#missing + 1] = "accent:" .. i end end
    check(#missing == 0 and #(St.accentKeys or {}) > 0, "Pick your own: every row's radio items and every accent swatch are there", K.short(missing))
    K.press("way:1")
end)
after(15, function()
    local w = K.W()
    check(w and w.way == 1, "Pick your own: the Pick your own card is picked", w and w.way)
    local i = K.pick("style")
    keep.style = i
end)
after(15, function()
    local i = keep.style
    check(K.val("lookStyle") == i and St.lite() == (i == 2), "Pick your own: Style sets Full or Lite live (the lookStyle option, ZeD.Settings.lite())",
        "picked " .. tostring(i) .. ", option " .. tostring(K.val("lookStyle")))
    keep.theme = K.pick("theme")
end)
after(15, function()
    local i = keep.theme
    local key = THEME_KEYS[i]
    local idx = 0
    for n, k in ipairs(St.baseKeys or {}) do if k == key then idx = n end end
    check(ZeD.currentBase == key and K.val("baseTheme") == idx, "Pick your own: Theme sets the theme live (ZeD.currentBase follows)",
        "picked " .. tostring(key) .. ", currentBase " .. tostring(ZeD.currentBase) .. ", option " .. tostring(K.val("baseTheme")))
    keep.text = K.pick("text")
end)
after(15, function()
    local key = SIZE_KEYS[keep.text]
    local opt = (St.sizeKeys or {})[K.val("textSize") or 0]
    check(ZeD.currentSize == key and opt == key, "Pick your own: Text size sets the text size live (ZeD.currentSize follows)",
        "picked " .. tostring(key) .. ", currentSize " .. tostring(ZeD.currentSize) .. ", option " .. tostring(opt))
    keep.moodles = K.pick("moodles")
end)
after(15, function()
    check(K.val("moodlePlace") == keep.moodles, "Pick your own: Moodles place sets the moodlePlace option live",
        "picked " .. tostring(keep.moodles) .. ", option " .. tostring(K.val("moodlePlace")))
    keep.accent = K.pick("accent")
end)
after(15, function()
    local key = (St.accentKeys or {})[keep.accent]
    check(K.val("accentColor") == keep.accent and ZeD.currentAccent == key, "Pick your own: Accent sets the accent live (ZeD.currentAccent follows)",
        "picked " .. tostring(key) .. ", currentAccent " .. tostring(ZeD.currentAccent) .. ", option " .. tostring(K.val("accentColor")))
    K.press("opt:input:2")
end)
after(15, function()
    local w = K.W()
    check(w and w.input == 2, "Pick your own: Playing with takes Controller", w and w.input)
    local d = K.diff(keep.snapOpen, K.snapAll())
    say("picked: " .. #d .. " option(s) differ from the window's opening: " .. K.short(d))
    K.press("way:3")
end)

-- 4: Skip
after(15, function()
    local w = K.W()
    check(w and w.way == 3, "Skip: the Skip card is picked", w and w.way)
    K.press("done")   -- (the band's main button reads Skip with way 3)
end)
after(20, function()
    local d = K.diff(keep.snapOpen, K.snapAll())
    check(#d == 0 and K.count(keep.snapOpen) > 0, "Skip puts every option back to its value when the window opened", K.short(d))
    check(MM.view == "main", "Skip closes the welcome (the main view)", tostring(MM.view))
    check(WL.seen() == true, "Skip writes ZeD_setup_seen.txt", K.lines(WL.SEEN_FILE))
    local want = (St.baseKeys or {})[(keep.snapOpen or {}).baseTheme or 0]
    check(want ~= nil and ZeD.currentBase == want, "Skip puts the theme on screen back", tostring(ZeD.currentBase) .. " / opened with " .. tostring(want))
    MM.openWelcome()
end)

-- 5: Tutorial
after(20, function()
    check(K.open(), "Tutorial: the welcome opens again", tostring(MM.view))
    K.press("way:1")
end)
-- (Playing with back on Mouse and keys first: the window keeps the Controller picked above, and Show me around with
-- Controller writes "pad", the tour's controller words, ZeD_Tutorial.lua)
after(15, function() K.press("opt:input:1") end)
after(15, function() K.press("opt:tutorial:1") end)
after(15, function()
    local w = K.W()
    check(w and w.tutorial == 1 and w.input == 1, "Tutorial: Show me around is picked, with Mouse and keys", w and (tostring(w.tutorial) .. " " .. tostring(w.input)))
    K.press("done")
end)
after(20, function()
    local t = K.readLines(WL.TUTORIAL_FILE)
    check(t ~= nil and t[1] == "1" and WL.tutorialWanted() == true, "Tutorial: Show me around then Done writes ZeD_tutorial.txt = 1", K.lines(WL.TUTORIAL_FILE))
    check(MM.view == "main", "Tutorial: Done closes the welcome", tostring(MM.view))
    MM.openWelcome()
end)
after(20, function() K.press("way:1") end)
after(15, function() K.press("opt:tutorial:2") end)
after(15, function() K.press("done") end)
after(20, function()
    local t = K.readLines(WL.TUTORIAL_FILE)
    check(t ~= nil and t[1] == "0" and WL.tutorialWanted() == false, "Tutorial: No thanks then Done writes ZeD_tutorial.txt = 0", K.lines(WL.TUTORIAL_FILE))
    MM.openWelcome()
end)

-- 6: Save setup, change, Load a setup
after(20, function()
    check(K.open(), "Save setup: the welcome opens again", tostring(MM.view))
    K.press("way:1")
end)
after(15, function()
    keep.saved = K.snapAll()
    K.press("save")
end)
after(15, function()
    local map, n = K.readSetup()
    local bad = {}
    for id, v in pairs(keep.saved or {}) do if map[id] ~= tostring(v) then bad[#bad + 1] = id .. "=" .. tostring(v) .. "/" .. tostring(map[id]) end end
    table.sort(bad)
    local head = (K.readLines(St.SETUP_FILE) or {})[1]
    check(#bad == 0 and n == K.count(keep.saved) and n > 0, "Save setup writes ZeD_setup.txt with every ZeD option",
        n .. " lines for " .. K.count(keep.saved) .. " options; header " .. tostring(head) .. (#bad > 0 and ("; wrong " .. K.short(bad)) or ""))
    check(St.hasSetup() == true, "hasSetup() is true after Save setup")
    local w = K.W()
    check(w and w.note == ZeD.tr("UI_ZeD_Welcome_Saved", St.SETUP_FILE), "Save setup: the band says it saved", w and w.note)
    K.pick("theme")
end)
after(15, function() K.pick("text") end)
after(15, function() K.pick("moodles") end)
after(15, function() K.pick("accent") end)
after(15, function() K.pick("style") end)
after(15, function()
    local d = K.diff(keep.saved, K.snapAll())
    check(#d >= 5, "Load a setup: five or more options changed by picks before Load", #d .. ": " .. K.short(d))
    K.press("way:2")
end)
after(15, function()
    local w = K.W()
    check(w and w.way == 2, "Load a setup: the Load a setup card is picked", w and w.way)
    K.press("done")   -- (the band's main button reads Load with way 2)
end)
after(20, function()
    local d = K.diff(keep.saved, K.snapAll())
    check(#d == 0, "Load a setup restores every option exactly as saved", K.short(d))
    local want = (St.baseKeys or {})[(keep.saved or {}).baseTheme or 0]
    check(want ~= nil and ZeD.currentBase == want, "Load a setup puts the saved theme on screen", tostring(ZeD.currentBase) .. " / saved " .. tostring(want))
    check(MM.view == "main", "Load a setup: Done closes the welcome", tostring(MM.view))
    local _, lines = K.readSetup()
    local n = St.loadSetup()
    check(n == lines and n > 0, "loadSetup() returns one per option line it set", tostring(n) .. " of " .. lines)
end)

-- put back
after(15, function()
    if MM.view ~= "main" then MM.showView("main") end
    K.setAll(keep.opt0)
    K.writeLines("ModOptions.ini", keep.ini0, "\r\n")
    -- (ZeD writes the setup file a line and "\n" each; the seen and tutorial files one word, no line end)
    if keep.setup0 then K.writeLines(St.SETUP_FILE, keep.setup0, "\n") end
    if keep.tut0 then K.writeLines(WL.TUTORIAL_FILE, keep.tut0) end
    if keep.seen0 then K.writeLines(WL.SEEN_FILE, keep.seen0) end
end)
after(15, function()
    local d = K.diff(keep.opt0, K.snapAll())
    check(#d == 0, "put back: every ZeD option as found", K.short(d))
    check(ZeD.currentBase == keep.look0[1] and ZeD.currentAccent == keep.look0[2] and ZeD.currentSize == keep.look0[3], "put back: the theme, accent and text size on screen as found",
        tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " " .. tostring(ZeD.currentSize))
    check(keep.ini0 ~= nil and K.same(K.readLines("ModOptions.ini"), keep.ini0), "put back: ModOptions.ini line for line")
    local files = { { St.SETUP_FILE, keep.setup0 }, { WL.TUTORIAL_FILE, keep.tut0 }, { WL.SEEN_FILE, keep.seen0 } }
    for _, f in ipairs(files) do
        if f[2] then check(K.same(K.readLines(f[1]), f[2]), "put back: " .. f[1] .. " line for line")
        else say("SKIP put back: " .. f[1] .. " was not there before; welcome_run.ps1 deletes it") end
    end
end)
after(10, function()
    say("end: " .. pass .. " pass, " .. fail .. " fail; view=" .. tostring(MM.view))
    say(fail > 0 and ("VERDICT FAIL " .. fail) or ("VERDICT PASS " .. pass))
    say("DONE")
end)

local function t()
    local s = stages[si]
    if not s then Events.OnFETick.Remove(t); return end
    cnt = cnt + 1
    local go = cnt >= s.n
    local met = false
    if s.cond then
        local ok, r = pcall(s.cond)
        met = ok and r and true or false
        if met then go = true end
    end
    if go then
        cnt = 0
        si = si + 1
        local ok, e = pcall(s.fn, met)
        if not ok then fail = fail + 1; say("ERR stage " .. (si - 1) .. " " .. tostring(e)) end
    end
end
Events.OnFETick.Add(t)
say("start")
