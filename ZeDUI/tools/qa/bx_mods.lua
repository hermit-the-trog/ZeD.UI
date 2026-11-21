-- ZeDUI/tools/qa/bx_mods.lua  (Nov 21 2026, QA beast day; tag bx_mods): ZeD with nine other mods on at once.
-- Run through bx_mods_run.ps1 (it copies the mods in, runs zedqa_mods_run.ps1 with bx_mods_list.txt and bx_mods.txt,
-- and takes the copies out again). The mods (bx_mods_list.txt): Responsive Context Menus, Better Context Menu Icons,
-- Container Capacity Indicator, Easy Drop'n'Loot, Moodle Quarters, Wound Expansion, Spongie's Character Customisation
-- (the six ZeD has a support file for), Proximity Inventory and CleanHotBar (no support file: an inventory mod that
-- rewrites ISInventoryPage.update and a hotbar mod that rewrites ISHotbar's render, update and refresh).
-- What a player with these mods does, fast and in odd orders:
--   0. the mods are on and found; ZeD's support file answered for each mod it supports
--   1. step aside: the start check ran with this mod list; for each ZeD screen, what StepAside.detect finds matches
--      the record, the screen's switch, ZeD.Safe.on and the notice in Messages (the notice names the mod); a
--      supported mod is never a taker; a second check changes nothing; the Health key opens ZeD's window, or the
--      game's when Character info was handed back
--   2. both windows on every tab of both strips (a slow walk, each tab checked), then a fast mash over the tabs
--      with the pair shut and opened in the middle
--   3. the right-click menu, strip and list: opens on a tool's row, every row has its icon, stays open with its
--      selection through Responsive Context Menus' rebuilds, the tool is taken away while the menu shows it
--      (the menu must go, or still take the pad without an error), a right-click on the ground
--   4. the Health tab: wounds staged while it is open (a cut, scratches, a bandage), the tab's data follows the
--      game, a click on the cut part opens its treatment menu, the part heals while that menu is open, tabs
--      flipped mid-wound, everything healed
--   5. Messages: opens, every source chosen in turn, an error card's Open in Mods when a mod threw (else the pause
--      menu's own Mods button): the pause window's Mods page lists every mod that is on; the conflict scan's own
--      code runs over these mods' files without stopping
-- After every act: no new Lua error (the game's error count), and every ZeD window inside the screen (RT.bounds).
-- PUT BACK: wounds healed, god mode and invincible as found, the given things taken back, hands, the Context menu setting, Messages' read flags,
-- the pause window's page and jump note, the step-aside file, tabs, layout, the pair, speed 1, the character home.
-- Copy to Zomboid/Lua/ after zedqa_prelude.lua and rt_kit.lua; grep "ZEDQA bx_mods".

local Q = RT.make("bx_mods")
local S = { p = RT.p, pn = RT.pn, dead = false, tools = {}, mine = {}, on = {}, parts = {} }
local H = {}
local TAG = "bx_mods"

-- the mods of bx_mods_list.txt: id, its name on the Workshop, sup = ZeD ships ModSupport/<id>.lua for it
local LIST = {
    { id = "ResponsiveUI", name = "Responsive Context Menus", sup = true },
    { id = "SuperOl3gContextMenuIcons", name = "Better Context Menu Icons" },
    { id = "ContainerCapacityIndicator", name = "Container Capacity Indicator", sup = true },
    { id = "KADropnLoot", name = "Easy Drop'n'Loot", sup = true },
    { id = "moodle_quarters", name = "Moodle Quarters", sup = true },
    { id = "WoundExpansion", name = "Wound Expansion", sup = true },
    { id = "ProximityInventory", name = "Proximity Inventory" },
    { id = "CleanHotBar", name = "CleanHotBar" },
    { id = "SPNCC", name = "Spongie's Character Customisation", sup = true },
}

local function step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
local function waitFor(n, max, cond, fn)
    Q.waitFor(n, max, function() if S.dead then return true end; return cond() end,
        function(ok) if S.dead then return end; fn(ok) end)
end

-- ===================================================================== helpers
function H.bare(id) return (tostring(id or ""):gsub("^\\", "")) end
function H.active()
    local t, n = {}, 0
    pcall(function()
        local list = getActivatedMods()
        n = list:size()
        for i = 0, n - 1 do t[H.bare(list:get(i))] = i end
    end)
    return t, n
end
function H.signature()
    local ids = {}
    pcall(function()
        local list = getActivatedMods()
        for i = 0, list:size() - 1 do ids[#ids + 1] = H.bare(list:get(i)) end
    end)
    return table.concat(ids, ",")
end
function H.errs()
    local n = nil
    pcall(function() n = getLuaDebuggerErrorCount() end)
    return n
end
-- who Messages caught errors from this session
function H.errNames()
    local out = {}
    pcall(function()
        local _, errs = ZeD.Messages.list()
        for _, s in ipairs(errs or {}) do
            local it = s.items and s.items[1]
            out[#out + 1] = tostring(s.name) .. ((it and it.count) and (" x" .. tostring(it.count)) or "")
        end
    end)
    return table.concat(out, ", ")
end
-- no new Lua error since the last call
function H.noErr(what)
    local n = H.errs()
    if n == nil then
        if not S.noCounter then S.noCounter = true; Q.skip("the no-error checks", "this game has no Lua error counter") end
        return true
    end
    local d = n - (S.errAt or n)
    S.errAt = n
    return Q.check(d == 0, what .. ": no new Lua error", (d == 0) and nil or (d .. " new; Messages holds errors from: " .. H.errNames()))
end
function H.cw() return RT.cw() end
function H.cc() local w = RT.cw(); return w and w._mainContent end
function H.wOf(k) if k == "c" then return RT.cw() end; return RT.ww() end
function H.stripOf(k) if k == "c" then return RT.charStrip() end; return RT.worldStrip() end
function H.nameOf(k) if k == "c" then return "Character" end; return "World" end
function H.press(k, id) if k == "c" then return RT.charTab(id) end; return RT.worldTab(id) end
function H.bothOpen()
    local c, w = RT.cw(), RT.ww()
    local ok = false
    pcall(function() ok = RT.isOpen() and c ~= nil and w ~= nil and c:isVisible() and w:isVisible() end)
    return ok
end
function H.has(list, v)
    for _, x in ipairs(list or {}) do if x == v then return true end end
    return false
end
function H.vanilla()
    local v = nil
    pcall(function() v = getPlayerInfoPanel(S.pn) end)
    return v
end
function H.vanillaShown()
    local v = H.vanilla()
    local on = false
    pcall(function() on = v ~= nil and v:getIsVisible() == true end)
    return on
end
function H.safe(sc)
    local on = false
    pcall(function() on = ZeD.Safe.on(sc) == true end)
    return on
end
function H.menuUp()
    local up = false
    pcall(function() up = MainScreen.instance ~= nil and MainScreen.instance:isVisible() end)
    return up
end
function H.toggleMenu() pcall(function() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end) end
function H.readLines(file)
    local t = nil
    pcall(function()
        local r = getFileReader(file, false)
        if not r then return end
        t = {}
        local l = r:readLine()
        while l do t[#t + 1] = l; l = r:readLine() end
        r:close()
    end)
    return t
end
function H.writeLines(file, t)
    pcall(function()
        local w = getFileWriter(file, true, false)
        if not w then return end
        w:write(table.concat(t, "\r\n") .. "\r\n")
        w:close()
    end)
end

-- ===================================================================== 0. setup, the mods
function H.setup()
    if not (S.p and ZeD and ZeD_CharacterWindow and ZeD_WorldWindow and ZeD.StepAside and ZeD.Messages and ZeD.Settings) then
        Q.check(false, "ZeD is loaded (windows, step aside, Messages, settings)")
        S.dead = true
        return
    end
    local dead = false
    pcall(function() dead = S.p:isDead() end)
    if dead then Q.check(false, "the character is alive"); S.dead = true; return end
    if ZEDQA_HOME then pcall(ZEDQA_HOME, TAG) end
    S.speed0 = getGameSpeed()
    if S.speed0 == 0 then pcall(ZEDQA_SPEED or setGameSpeed, 1) end
    S.pairWas = RT.isOpen()
    S.snap = (S.pairWas and ZEDQA_LAYOUT_SNAP) and ZEDQA_LAYOUT_SNAP() or nil
    S.ph, S.sh = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    S.vanWas = H.vanillaShown()
    local c, w = RT.cw(), RT.ww()
    S.tabC0, S.tabW0 = c and c._activeTab, w and w._activeTab
    S.errAt = H.errs()
    S.err0 = S.errAt
    S.saLines = H.readLines("ZeD_step_aside.txt")
    S.readWas = {}
    for _, s in pairs(ZeD.Messages.sources or {}) do
        for _, it in ipairs(s.items or {}) do S.readWas[it] = it.read and true or false end
    end
    local o = ZeD.Settings.contextStyleOption
    if o then S.styleWas = o:getValue() end
    Q.say(string.format("screen %dx%d, pair open %s, speed %s, Lua errors so far %s", RT.core:getScreenWidth(), RT.core:getScreenHeight(),
        tostring(S.pairWas), tostring(S.speed0), tostring(S.err0)))
end
function H.modsOn()
    local act, n = H.active()
    local zi = act["ZeD_UI"]
    local missing, lost, order = {}, {}, {}
    for _, m in ipairs(LIST) do
        local at = act[m.id]
        S.on[m.id] = at ~= nil
        if at == nil then missing[#missing + 1] = m.id
        else
            order[#order + 1] = m.id .. "@" .. at
            local avail = false
            -- (asked by the id as the game's list holds it, which may carry a leading backslash)
            pcall(function() local mi = getModInfoByID(getActivatedMods():get(at)); avail = mi ~= nil and mi:isAvailable() == true end)
            if not avail then lost[#lost + 1] = m.id end
        end
    end
    Q.say("mods on: " .. n .. " (ZeD_UI at " .. tostring(zi) .. "): " .. table.concat(order, " "))
    Q.check(zi ~= nil, "ZeD_UI is on in this game")
    Q.check(#missing == 0, "all " .. #LIST .. " mods of bx_mods_list.txt are on in this game", (#missing > 0) and ("not on: " .. table.concat(missing, ", ")) or nil)
    Q.check(#lost == 0, "every one of them is found and available (its files are in Zomboid/mods)", (#lost > 0) and table.concat(lost, ", ") or nil)
    if #missing == #LIST then
        Q.skip("the whole script", "none of the mods is on: run it through bx_mods_run.ps1")
        S.dead = true
    end
end
function H.supportFiles()
    local none = {}
    local n = 0
    for _, m in ipairs(LIST) do
        if m.sup and S.on[m.id] then
            n = n + 1
            local t = ZeD.ModSupport and ZeD.ModSupport[m.id]
            if type(t) ~= "table" then none[#none + 1] = m.id end
        end
    end
    Q.check(#none == 0, "ZeD's support file answered for each supported mod that is on (" .. n .. ")", (#none > 0) and ("no ZeD.ModSupport table for " .. table.concat(none, ", ")) or nil)
    local unsup = {}
    for _, m in ipairs(LIST) do
        if m.sup and not ZeD.StepAside.SUPPORTED[m.id] then unsup[#unsup + 1] = m.id end
    end
    Q.check(#unsup == 0, "each supported mod is on step aside's never-a-taker list", (#unsup > 0) and table.concat(unsup, ", ") or nil)
end
Q.step(5, function() H.setup() end)
step(5, function() H.modsOn() end)
step(2, function() H.supportFiles() end)

-- ===================================================================== 1. step aside
function H.noticeFor(name)
    local src = ZeD.Messages.sources[S.head]
    for _, it in ipairs(src and src.items or {}) do
        if tostring(it.text or ""):find(tostring(name), 1, true) then return it end
    end
    return nil
end
function H.noticeCount()
    local src = ZeD.Messages.sources[S.head]
    return src and #src.items or 0
end
function H.optValue(sc)
    local v = nil
    pcall(function() v = ZeD.Settings.screenOptions[sc]:getValue() end)
    return v
end
-- one screen: what detect found against the record, the switch, Safe and the notice
function H.screen(sc, f, rec)
    local set, kept, val = rec.set[sc], rec.kept[sc], H.optValue(sc)
    if not f then
        S.mine[sc] = not H.safe(sc)
        Q.check(set == nil and S.mine[sc], sc .. ": no mod took it, so it is ZeD's (not handed back, its switch off)",
            "record set " .. tostring(set and set.id) .. ", switch " .. tostring(val) .. ", Safe.on " .. tostring(H.safe(sc)))
        return
    end
    Q.say(sc .. ": taken by " .. tostring(f.id) .. " (" .. tostring(f.name) .. "), why " .. tostring(f.why))
    Q.check(not ZeD.StepAside.SUPPORTED[f.id], sc .. ": the taker is not a mod ZeD supports", tostring(f.id))
    if kept == f.id then
        S.mine[sc] = not H.safe(sc)
        Q.check(set == nil and S.mine[sc], sc .. ": the player took it back from " .. tostring(f.id) .. " before, and it stays ZeD's",
            "switch " .. tostring(val))
        return
    end
    S.mine[sc] = false
    S.handed = (S.handed or 0) + 1
    Q.check(set ~= nil and set.id == f.id and val == 2 and H.safe(sc), sc .. ": handed back to the game for " .. tostring(f.id) .. " (record, switch ticked, Safe.on)",
        "record set " .. tostring(set and set.id) .. ", switch " .. tostring(val) .. ", Safe.on " .. tostring(H.safe(sc)))
    local it = H.noticeFor(f.name)
    Q.check(it ~= nil, sc .. ": Messages holds a notice under '" .. tostring(S.head) .. "' that names " .. tostring(f.name),
        H.noticeCount() .. " notices there" .. (it and (": " .. tostring(it.text)) or ""))
    local under = nil
    pcall(function() under = ZeD.StepAside.underFor(sc) end)
    Q.check(under ~= nil and tostring(under):find(tostring(f.name), 1, true) ~= nil, sc .. ": ZeD setup's line under the switch names the mod", tostring(under))
end
function H.setIds(rec)
    local t = {}
    for _, sc in ipairs(ZeD.StepAside.ORDER) do
        t[#t + 1] = sc .. "=" .. tostring(rec.set[sc] and rec.set[sc].id) .. "/" .. tostring(rec.kept[sc]) .. "/" .. tostring(H.optValue(sc))
    end
    return table.concat(t, " ")
end
function H.stepAside()
    local SA = ZeD.StepAside
    S.head = ZeD.tr("UI_ZeD_StepAside_Head")
    for _, sc in ipairs(SA.ORDER) do S.mine[sc] = not H.safe(sc) end
    local okD, found = pcall(SA.detect)
    if not Q.check(okD and type(found) == "table", "StepAside.detect runs over these mods' files", okD and nil or tostring(found)) then return end
    local rec = SA.record()
    for _, sc in ipairs(SA.ORDER) do
        local okS, e = pcall(H.screen, sc, found[sc], rec)
        if not okS then Q.check(false, sc .. ": the step-aside checks ran", tostring(e)) end
    end
    for sc, line in pairs(SA.partial or {}) do Q.say("note (" .. tostring(sc) .. "): " .. tostring(line)) end
    if H.safe() then Q.say("note: ZeD's whole Safe mode is on in this game") end
    S.setWas, S.noticesWas = H.setIds(rec), H.noticeCount()
    Q.say("record: " .. S.setWas .. "; notices " .. S.noticesWas .. "; handed back " .. tostring(S.handed or 0))
end
function H.stepAsideAgain()
    local SA = ZeD.StepAside
    local okC, e = pcall(SA.check)
    Q.check(okC, "a second StepAside.check (what the next start does) runs", okC and nil or tostring(e))
    local now = H.setIds(SA.record())
    Q.check(now == S.setWas and H.noticeCount() == S.noticesWas, "the second check changes nothing and says nothing more",
        now .. "; notices " .. H.noticeCount())
    H.noErr("step aside")
end
function H.healthKey()
    local ok = false
    pcall(function()
        local key = getCore():getKey(KeybindId.TOGGLE_HEALTH_PANEL)
        if key and key ~= 0 then xpUpdate.displayCharacterInfo(key); ok = true end
    end)
    return ok
end
waitFor(5, 900, function()
    local rec = ZeD.StepAside.record()
    return rec ~= nil and rec.mods == H.signature()
end, function(ok)
    Q.check(ok, "ZeD's start check ran with this mod list (the record's mods line is this game's list)",
        ok and nil or ("record mods: " .. tostring(ZeD.StepAside.record() and ZeD.StepAside.record().mods)))
end)
step(5, function() H.stepAside() end)
step(20, function() H.stepAsideAgain() end)
-- the Health key: ZeD's Character window, or the game's Character Info when a mod took it
step(5, function()
    S.keyGo = false
    if S.mine.charinfo and not S.mine.windows then
        Q.skip("the Health key", "Character info is ZeD's but the windows were handed back to a mod")
        return
    end
    RT.pairShut()
    local v = H.vanilla()
    if v and H.vanillaShown() then pcall(function() v:setVisible(false) end) end
end)
step(20, function()
    if S.mine.charinfo and not S.mine.windows then return end
    S.keyGo = H.healthKey()
    if not S.keyGo then Q.skip("the Health key", "no key is bound to the health panel") end
end)
waitFor(5, 300, function()
    if not S.keyGo then return true end
    if S.mine.charinfo then return RT.isOpen() end
    return H.vanillaShown()
end, function(ok)
    if not S.keyGo then return end
    if S.mine.charinfo then
        Q.check(ok and not H.vanillaShown(), "the Health key opens ZeD's Character window, not the game's Character Info",
            "ZeD's open " .. tostring(RT.isOpen()) .. ", the game's shown " .. tostring(H.vanillaShown()) .. ", tab " .. tostring(RT.cw() and RT.cw()._activeTab))
    else
        Q.check(ok and not RT.isOpen(), "Character info was handed back: the Health key opens the GAME's window, not ZeD's",
            "the game's shown " .. tostring(H.vanillaShown()) .. ", ZeD's open " .. tostring(RT.isOpen()))
    end
    H.noErr("the Health key")
end)
step(10, function()
    local v = H.vanilla()
    if v and H.vanillaShown() and not S.vanWas then pcall(function() v:setVisible(false) end) end
end)

-- ===================================================================== 2. both windows, every tab
step(5, function()
    if not S.mine.windows then
        Q.skip("both windows on every tab, the menus and the Health tab", "the windows were handed back to a mod (see step aside above)")
        return
    end
    RT.pairOpen()
end)
waitFor(5, 400, function() return not S.mine.windows or H.bothOpen() end, function(ok)
    if not S.mine.windows then return end
    S.win = Q.check(ok, "the inventory key's action opens both ZeD windows with the mods on",
        "Character " .. tostring(RT.isOpen()) .. ", World " .. tostring(RT.ww() ~= nil and RT.ww():isVisible()))
    if not S.win then return end
    S.tabC0, S.tabW0 = S.tabC0 or RT.cw()._activeTab, S.tabW0 or RT.ww()._activeTab
    H.noErr("the pair opening")
end)
step(30, function()
    if not S.win then return end
    RT.bounds(Q, "both windows open")
    local hud = nil
    pcall(function() hud = ZeD.Belt.getHUD(S.pn) end)
    if S.mine.belt then
        Q.check(hud ~= nil and hud:isVisible(), "the belt is ZeD's and it is on screen (CleanHotBar and Moodle Quarters on)")
    else
        Q.say("the belt was handed back; ZeD's belt shown: " .. tostring(hud ~= nil and hud:isVisible()))
    end
end)
-- the slow walk: one tab at a time, each given time to open and draw, then checked
function H.walkStart(k)
    S.walk = nil
    if not S.win then return end
    local ids = RT.tabs(H.stripOf(k))
    S.walk = { k = k, ids = ids, i = 0, n = 0, bad = {}, id = nil, t = 0 }
    Q.say(H.nameOf(k) .. " strip: " .. #ids .. " tabs: " .. table.concat(ids, " "))
end
function H.walkNote(W, w)
    W.n = W.n + 1
    local n = H.errs()
    local d = (n and S.errAt) and (n - S.errAt) or 0
    S.errAt = n or S.errAt
    local shown = false
    pcall(function() shown = w:isVisible() end)
    if w._activeTab ~= W.id then W.bad[#W.bad + 1] = W.id .. " did not open (on " .. tostring(w._activeTab) .. ")"
    elseif d > 0 then W.bad[#W.bad + 1] = W.id .. " threw " .. d
    elseif not shown then W.bad[#W.bad + 1] = W.id .. " hid the window" end
    RT.bounds(Q, H.nameOf(W.k) .. " tab " .. W.id)
end
function H.walkTick()
    local W = S.walk
    if not W then return true end
    local w = H.wOf(W.k)
    if not w then W.bad[#W.bad + 1] = "the window is gone"; return true end
    if not W.id then
        W.i = W.i + 1
        W.id = W.ids[W.i]
        if not W.id then return true end
        W.t = 0
        H.press(W.k, W.id)
        return false
    end
    W.t = W.t + 1
    if (w._activeTab == W.id and W.t >= 14) or W.t >= 150 then
        H.walkNote(W, w)
        W.id = nil
    end
    return false
end
function H.walkEnd(k)
    local W = S.walk
    if not W then return end
    Q.check(W.n > 0 and W.n == #W.ids and #W.bad == 0, H.nameOf(k) .. " window: every tab on its strip opens and draws with the mods on (" .. W.n .. " of " .. #W.ids .. ")",
        (#W.bad > 0) and (table.concat(W.bad, "; ") .. "; Messages holds errors from: " .. H.errNames()) or nil)
    S.walk = nil
end
for _, k in ipairs({ "c", "w" }) do
    step(4, function() H.walkStart(k) end)
    waitFor(2, 6000, function() return H.walkTick() end, function() H.walkEnd(k) end)
end
-- the mash: a tab every other frame, the two windows in turn, backwards; the pair shut and opened in the middle
function H.mashStart()
    S.mash = nil
    if not S.win then return end
    local c, w = RT.tabs(RT.charStrip()), RT.tabs(RT.worldStrip())
    local seq = {}
    for round = 1, 2 do
        for i = math.max(#c, #w), 1, -1 do
            if c[i] then seq[#seq + 1] = { "c", c[i] } end
            if w[i] then seq[#seq + 1] = { "w", w[i] } end
        end
    end
    S.mash = { seq = seq, i = 0, t = 0, half = math.floor(#seq / 2), pressed = 0, toggled = 0 }
end
function H.mashTick()
    local M = S.mash
    if not M then return true end
    M.t = M.t + 1
    if M.t - math.floor(M.t / 2) * 2 ~= 0 then return false end
    M.i = M.i + 1
    local e = M.seq[M.i]
    if not e then return true end
    if M.i == M.half or M.i == M.half + 3 then
        pcall(ZeD_CharacterWindow.toggleBothPaired, S.pn)
        M.toggled = M.toggled + 1
        return false
    end
    if RT.isOpen() then
        local ok = false
        pcall(function() ok = H.press(e[1], e[2]) end)
        if ok then M.pressed = M.pressed + 1 end
    end
    return false
end
step(4, function() H.mashStart() end)
waitFor(1, 2000, function() return H.mashTick() end, function()
    if S.mash and not RT.isOpen() then RT.pairOpen() end
end)
waitFor(10, 400, function() return not S.mash or H.bothOpen() end, function(ok)
    local M = S.mash
    if not M then return end
    Q.check(ok, "after the mash (" .. M.pressed .. " tab presses, the pair toggled " .. M.toggled .. " times) both windows are open")
    local c, w = RT.cw(), RT.ww()
    Q.check(c ~= nil and w ~= nil and H.has(RT.tabs(RT.charStrip()), c._activeTab) and H.has(RT.tabs(RT.worldStrip()), w._activeTab),
        "after the mash each window shows a tab that is on its strip", "Character " .. tostring(c and c._activeTab) .. ", World " .. tostring(w and w._activeTab))
    H.noErr("the tab mash")
end)
step(30, function()
    if not S.mash then return end
    RT.bounds(Q, "after the tab mash")
    RT.charTab("loot")
    RT.worldTab("loot")
    S.mash = nil
end)

-- ===================================================================== 3. the right-click menu
function H.menu()
    local m = nil
    pcall(function() local v = getPlayerContextMenu(S.pn); m = v and v._zedMenu end)
    if m then
        local open = false
        pcall(function() open = m._ctx ~= nil and m._ctx.open == true and m:isVisible() end)
        if not open then return nil end
    end
    return m
end
function H.closeMenu()
    local m = nil
    pcall(function() local v = getPlayerContextMenu(S.pn); m = v and v._zedMenu end)
    if m then pcall(function() m:close() end) end
    pcall(function()
        local v = getPlayerContextMenu(S.pn)
        if v and v:getIsVisible() then v:hideAndChildren() end
    end)
end
function H.gameMenuRows()
    local n, names = 0, {}
    pcall(function()
        local v = getPlayerContextMenu(S.pn)
        if v and v:getIsVisible() then
            for _, o in ipairs(v.options or {}) do n = n + 1; names[#names + 1] = tostring(o.name) end
        end
    end)
    return n, table.concat(names, " | ")
end
function H.zone(c, id)
    for _, z in ipairs(c and c._hitZones or {}) do if z.id == id then return z end end
    return nil
end
function H.reveal(c, item)
    local s = c and c._scroll
    local y = c and c._itemRenderYMap and c._itemRenderYMap[item]
    if not (s and y) then return end
    if S.scroll0 == nil then S.scroll0 = s.scrollPos or 0 end
    if not (s.visible and s.barSizeRatio and s.barSizeRatio > 0 and s.barSizeRatio < 1) then return end
    local vis = s.height
    local range = vis / s.barSizeRatio - vis
    if range <= 0 then return end
    local logical = y - s.y + math.floor(s.scrollPos * range)
    s:setScrollPos(math.max(0, math.min(1, (logical - math.floor(vis / 3)) / range)))
end
function H.rightClick(c, item)
    local z = H.zone(c, item)
    if not z then return false end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    c:onRightMouseDown(x, y)
    c:onRightMouseUp(x, y)
    return true
end
function H.iconless(defs, out, seen)
    for _, d in ipairs(defs or {}) do
        if type(d) == "table" and not seen[d] then
            seen[d] = true
            local back = d.isBack or d.id == "__back" or tostring(d.name) == ZeD.tr("UI_ZeD_CtxMenu_Back")
            if not (d.heading or back or d.pxIcon or d.iconTexture or d.check ~= nil) then out[#out + 1] = tostring(d.name) end
            H.iconless(d.children, out, seen)
        end
    end
    return out
end
function H.levelsOnScreen(m)
    local W, Hh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local bad = {}
    for i, lv in ipairs(m._levels or {}) do
        if lv.x < -1 or lv.y < -1 or lv.x + lv.w > W + 1 or lv.y + lv.h > Hh + 1 then
            bad[#bad + 1] = "level " .. i .. " at " .. math.floor(lv.x) .. "," .. math.floor(lv.y) .. " " .. math.floor(lv.w) .. "x" .. math.floor(lv.h)
        end
    end
    return #bad == 0, table.concat(bad, "; ")
end
-- the selected row's name; choose(m) selects a plain row past the first whose name no other row has
function H.selName(m)
    local nm = nil
    pcall(function()
        if m._levels then
            local lv = m._levels[1]
            local r = lv and lv.rows[lv.sel]
            nm = r and r.def and tostring(r.def.name)
        else
            local d = m._ctx.items[m._ctx.selected]
            nm = d and tostring(d.name)
        end
    end)
    return nm
end
function H.rowDefs(m)
    local out = {}
    if m._levels then
        for ri, r in ipairs(m._levels[1] and m._levels[1].rows or {}) do out[#out + 1] = { i = ri, def = r.def } end
    else
        for i, d in ipairs(m._ctx.items or {}) do out[#out + 1] = { i = i, def = d } end
    end
    return out
end
function H.choose(m)
    local rows = H.rowDefs(m)
    local count = {}
    for _, r in ipairs(rows) do
        local nm = r.def and tostring(r.def.name) or "?"
        count[nm] = (count[nm] or 0) + 1
    end
    for n, r in ipairs(rows) do
        local d = r.def
        if n >= 2 and type(d) == "table" and not d.heading and not d.isBack and d.id ~= "__back" and count[tostring(d.name)] == 1 then
            if m._levels then m._levels[1].sel = r.i else m._ctx.selected = r.i end
            return tostring(d.name)
        end
    end
    return nil
end
function H.padAbout(m)
    if m._levels then
        m:onJoypadDirDown(); m:onJoypadDirDown(); m:onJoypadDirUp()
    else
        m:onJoypadDirRight(); m:onJoypadDirRight(); m:onJoypadDirLeft()
    end
end
function H.menuSetup()
    S.menuGo = false
    if not S.win then return end
    local o = ZeD.Settings.contextStyleOption
    if not Q.check(o ~= nil and H.cc() ~= nil, "ZeD's Context menu setting and the bag's list are there") then return end
    RT.charTab("loot")
    local have = {}
    pcall(function()
        local items = S.p:getInventory():getItems()
        for i = 0, items:size() - 1 do have[items:get(i):getFullType()] = true end
    end)
    for _, ft in ipairs({ "Base.Hammer", "Base.Crowbar", "Base.Screwdriver", "Base.BallPeenHammer", "Base.ClubHammer", "Base.Wrench" }) do
        if #S.tools < 2 and not have[ft] then
            local it = RT.give(ft)
            if it then S.tools[#S.tools + 1] = it end
        end
    end
    S.menuGo = Q.check(#S.tools == 2, "two tools of kinds the bag does not hold were given", #S.tools .. " given")
end
step(10, function() H.menuSetup() end)

function H.menuOpened(ok, sname, want)
    local m = H.menu()
    local has = false
    pcall(function()
        for _, t in ipairs((m and type(m._ctx.target) == "table") and m._ctx.target or {}) do if t == S.item then has = true end end
    end)
    S.menuOk = Q.check(ok and m ~= nil and m.Type == want and has, "the " .. sname .. ": a right-click on the tool's row opens ZeD's menu (" .. want .. ") on the tool",
        "menu " .. tostring(m and m.Type) .. ", on the tool " .. tostring(has) .. ", by " .. tostring(S.clickBy))
    S.m = m
end
function H.menuRows(sname)
    local m = H.menu()
    if not (S.menuOk and m) then return end
    local defs = m._ctx.actions or {}
    local missing = H.iconless(defs, {}, {})
    Q.check(#defs > 0 and #missing == 0, "the " .. sname .. ": every row and submenu row has its icon with the mods' options in it",
        #defs .. " top rows" .. ((#missing > 0) and ("; no icon: " .. table.concat(missing, ", ")) or ""))
    RT.bounds(Q, "the " .. sname .. " open")
    if m._levels then
        local okL, why = H.levelsOnScreen(m)
        Q.check(okL, "the list's box is on screen", why)
    end
    S.selWant = H.choose(m)
    Q.say("the " .. sname .. ": selected for the hold: " .. tostring(S.selWant))
end
function H.menuHeld(sname)
    if not S.menuOk then return end
    local m = H.menu()
    if not S.on.ResponsiveUI then
        Q.check(m ~= nil and m == S.m, "the " .. sname .. " stays open over a second and a half")
        return
    end
    Q.check(m ~= nil and m == S.m, "the " .. sname .. " stays open through Responsive Context Menus' rebuilds (a second and a half, about six rebuilds)",
        "open " .. tostring(m ~= nil) .. ", the same menu " .. tostring(m == S.m))
    if m and S.selWant then
        Q.check(H.selName(m) == S.selWant, "the " .. sname .. " keeps its selected row through the rebuilds", tostring(S.selWant) .. " -> " .. tostring(H.selName(m)))
    end
    H.noErr("the " .. sname .. " held open")
end
function H.menuVanish(sname)
    if not S.menuOk then return end
    local gone = false
    pcall(function()
        local c = S.item:getContainer()
        if c then c:Remove(S.item); gone = S.item:getContainer() == nil or not c:contains(S.item) end
    end)
    S.vanished = Q.check(gone, "the " .. sname .. ": the tool is taken out of the bag while its menu is open")
    pcall(function() S.p:getInventory():setDrawDirty(true) end)
end
function H.menuAfterVanish(sname)
    if not (S.menuOk and S.vanished) then return end
    local m = H.menu()
    if not m then
        Q.check(true, "the " .. sname .. ": with its tool gone the menu closed by itself")
    else
        local okP, e = pcall(H.padAbout, m)
        Q.check(okP, "the " .. sname .. ": with its tool gone the menu stayed, and the pad moves over it without an error", okP and nil or tostring(e))
        local okC, e2 = pcall(function() m:close() end)
        Q.check(okC and H.menu() == nil, "the " .. sname .. ": the stale menu closes", okC and nil or tostring(e2))
    end
    H.noErr("the " .. sname .. " over a vanished tool")
end
for si, style in ipairs({ 1, 2 }) do
    local sname = (style == 1) and "strip" or "list"
    local want = (style == 1) and "ZeD_ContextMenu" or "ZeD_ContextList"
    step(6, function()
        S.menuOk, S.vanished, S.m = false, false, nil
        if not S.menuGo then return end
        H.closeMenu()
        pcall(function() ZeD.Settings.contextStyleOption:setValue(style) end)
        S.item = S.tools[si]
        H.reveal(H.cc(), S.item)
    end)
    step(8, function()
        if not S.menuGo then return end
        local ok = false
        pcall(function() ok = H.rightClick(H.cc(), S.item) end)
        S.clickBy = "the row's right-click"
        if not ok then
            -- (the row is not laid out this frame: the game's own builder for the item, as a right-click calls it)
            S.clickBy = "the game's menu builder (the row had no place this frame)"
            pcall(function() ISInventoryPaneContextMenu.createMenu(S.pn, true, { S.item }, 300, 300) end)
        end
    end)
    waitFor(2, 150, function() return not S.menuGo or H.menu() ~= nil end, function(ok)
        if S.menuGo then H.menuOpened(ok, sname, want) end
    end)
    step(4, function() local okR, e = pcall(H.menuRows, sname); if not okR then Q.check(false, "the " .. sname .. ": its rows read", tostring(e)) end end)
    Q.waitMs(1500)
    step(1, function() H.menuHeld(sname) end)
    step(2, function() H.menuVanish(sname) end)
    waitFor(2, 150, function() return not (S.menuOk and S.vanished) or H.menu() == nil end, function() end)
    step(2, function() H.menuAfterVanish(sname) end)
    waitFor(2, 300, function() return not (S.menuOk and S.vanished) or H.zone(H.cc(), S.item) == nil end, function(ok)
        if S.menuOk and S.vanished then Q.check(ok, "the " .. sname .. ": the bag's list drops the row of the tool that is gone (nothing stale)") end
    end)
    step(4, function() H.closeMenu() end)
end
-- a right-click on the ground under the character
step(10, function()
    S.wm = false
    if not S.menuGo then return end
    H.closeMenu()
    local okW, e = pcall(function()
        local sq = S.p:getCurrentSquare()
        local fl = sq and sq:getFloor()
        if not fl then error("no floor object under the character") end
        ISWorldObjectContextMenu.createMenu(S.pn, { fl }, math.floor(RT.core:getScreenWidth() / 2), math.floor(RT.core:getScreenHeight() / 2))
    end)
    if okW then S.wm = true else Q.skip("a right-click on the ground", "the game's world menu builder did not run here: " .. tostring(e)) end
end)
waitFor(2, 150, function() return not S.wm or H.menu() ~= nil end, function(ok)
    if not S.wm then return end
    local n, names = H.gameMenuRows()
    if ok then
        local m = H.menu()
        Q.check(true, "a right-click on the ground opens ZeD's menu", tostring(m.Type) .. ", " .. #(m._ctx.actions or {}) .. " top rows")
        RT.bounds(Q, "the ground's menu")
        if m._levels then
            local okL, why = H.levelsOnScreen(m)
            Q.check(okL, "the ground's list is on screen", why)
        end
    elseif n > 0 then
        Q.check(false, "a right-click on the ground opens ZeD's menu", "the game's own menu shows instead with " .. n .. " rows: " .. names)
    else
        Q.skip("a right-click on the ground opens ZeD's menu", "the game offers nothing for this ground")
        S.wm = false
    end
end)
Q.waitMs(800)
step(2, function()
    if not S.wm then return end
    H.closeMenu()
end)
step(10, function()
    if not S.wm then return end
    Q.check(H.menu() == nil, "the ground's menu closes")
    H.noErr("the ground's menu")
end)

-- ===================================================================== 4. the Health tab
function H.part(name)
    local bp = nil
    pcall(function() bp = S.p:getBodyDamage():getBodyPart(BodyPartType[name]) end)
    return bp
end
function H.fresh()
    local ok, d = pcall(ZeD.HealthTab.gatherData, S.p)
    if ok and type(d) == "table" then return d end
    S.gatherErr = tostring(d)
    return nil
end
function H.entryFor(data, bp)
    for _, e in ipairs(data and data.entries or {}) do if e.bodyPart == bp then return e end end
    return nil
end
function H.wound()
    S.hGo = false
    if not (S.win and RT.cw() and RT.cw()._activeTab == "health") then
        if S.win then Q.check(false, "the Health tab opens for its checks", "on " .. tostring(RT.cw() and RT.cw()._activeTab)) end
        return
    end
    RT.give("Base.Bandage"); RT.give("Base.Bandage"); RT.give("Base.AlcoholWipes")
    local arm = H.part("ForeArm_L")
    if not arm then Q.skip("the Health tab's wounds", "the left forearm could not be read"); return end
    S.arm = arm
    -- (the prelude's god mode heals a wound at once: off for these steps with invincible on, as zedqa_b8_wounds.lua does)
    local d0 = H.fresh()
    S.w0 = d0 and d0.woundedCount or 0
    S.godWas = S.p:isGodMod() and true or false
    pcall(function() S.invWas = S.p:isInvincible() and true or false end)
    S.p:setGodMod(false)
    pcall(function() S.p:setInvincible(true) end)
    local okS, e = pcall(function() arm:setCut(true); arm:setCutTime(20) end)
    if not okS then Q.skip("the Health tab's wounds", "a cut could not be staged: " .. tostring(e)); return end
    for _, nm in ipairs({ "Hand_R", "UpperLeg_R", "Foot_L", "Torso_Upper" }) do
        local bp = H.part(nm)
        if bp and pcall(function() bp:setScratched(true, true) end) then S.parts[#S.parts + 1] = bp end
    end
    pcall(function() S.parts[1]:setBandaged(true, 10, false, "Base.Bandage") end)
    local d = H.fresh()
    local en = H.entryFor(d, arm)
    S.hGo = Q.check(d ~= nil and en ~= nil and #en.conditions > 0, "Health: the cut forearm is on the tab's injury list at once, with its condition",
        d and ("wounded parts " .. tostring(d.woundedCount) .. ", staged " .. (#S.parts + 1)) or tostring(S.gatherErr))
    S.partName = en and en.name
    if d then
        local more = d.woundedCount - S.w0
        Q.check(more >= 1 and more <= #S.parts + 1, "Health: the wounded count grew by the staged wounds, no more",
            more .. " more for " .. (#S.parts + 1) .. " staged (" .. S.w0 .. " before)")
    end
end
-- (wounds bleed with god mode off: the overall health is kept up while they are on)
function H.topUp() pcall(function() if S.godWas ~= nil then S.p:getBodyDamage():setOverallBodyHealth(100) end end) end
step(6, function() if S.win then RT.charTab("health") end end)
waitFor(5, 400, function() return not S.win or (RT.cw() and RT.cw()._activeTab == "health") end, function() end)
step(20, function() H.wound() end)
-- the tab's own data (what it draws from) follows the game
waitFor(5, 400, function()
    if not S.hGo then return true end
    H.topUp()
    local w, d = RT.cw(), H.fresh()
    return w._healthCache ~= nil and d ~= nil and w._healthCache.woundedCount == d.woundedCount and d.woundedCount >= 1
end, function(ok)
    if not S.hGo then return end
    local w, d = RT.cw(), H.fresh()
    Q.check(ok, "Health: the open tab's own data shows the wounds the game has",
        "tab " .. tostring(w._healthCache and w._healthCache.woundedCount) .. ", game " .. tostring(d and d.woundedCount) .. ", other mods' lines shown " .. tostring(w._healthExtraShown))
    RT.bounds(Q, "the Health tab with wounds")
    H.noErr("the Health tab with wounds")
end)
-- tabs flipped mid-wound
step(3, function() if S.hGo then RT.charTab("skills") end end)
step(3, function() if S.hGo then RT.charTab("health") end end)
step(3, function() if S.hGo then RT.charTab("equip") end end)
step(3, function() if S.hGo then RT.charTab("health") end end)
waitFor(5, 400, function() return not S.hGo or RT.cw()._activeTab == "health" end, function(ok)
    if not S.hGo then return end
    Q.check(ok, "Health: back on the tab after four quick tab flips")
    H.noErr("the tab flips mid-wound")
end)
step(20, function()
    S.treat = false
    if not (S.hGo and S.partName) then return end
    H.closeMenu()
    local okP, e = pcall(ZeD.HealthTab._onPartClicked, RT.cw(), S.partName, nil, 10, 10)
    S.treat = Q.check(okP, "Health: a click on the cut part (" .. tostring(S.partName) .. ") runs", okP and nil or tostring(e))
end)
waitFor(2, 150, function()
    if not S.treat then return true end
    H.topUp()
    return H.menu() ~= nil or (H.gameMenuRows()) > 0
end, function(ok)
    if not S.treat then return end
    local n, names = H.gameMenuRows()
    local m = H.menu()
    Q.check(ok, "Health: the cut part's treatment menu opens (two bandages and wipes in the bag)",
        "ZeD's menu " .. tostring(m and m.Type) .. "; the game's rows: " .. n .. " " .. names)
    if ok then RT.bounds(Q, "the treatment menu") end
    -- the part heals while its menu is open
    pcall(function() S.arm:setCut(false); S.arm:setCutTime(0); S.arm:setBleeding(false) end)
end)
Q.waitMs(900)
step(2, function()
    if not S.treat then return end
    local m = H.menu()
    if m then
        local okP, e = pcall(H.padAbout, m)
        Q.check(okP, "Health: the treatment menu of a part that has healed takes the pad without an error", okP and nil or tostring(e))
    end
    H.closeMenu()
    H.noErr("the treatment menu over a healed part")
end)
function H.heal()
    pcall(function()
        for _, bp in ipairs(S.parts) do
            bp:setScratched(false, false)
            bp:setBandaged(false, 0)
            bp:setBleeding(false)
        end
        if S.arm then S.arm:setCut(false); S.arm:setCutTime(0); S.arm:setBleeding(false) end
    end)
    pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end)
    if S.godWas ~= nil then
        pcall(function() S.p:setGodMod(S.godWas) end)
        if S.invWas ~= nil then pcall(function() S.p:setInvincible(S.invWas) end) end
        S.godBack, S.godWas = S.godWas, nil
    end
end
step(10, function() if S.hGo then H.heal() end end)
waitFor(5, 600, function()
    if not S.hGo then return true end
    local w, d = RT.cw(), H.fresh()
    return d ~= nil and d.woundedCount <= (S.w0 or 0) and w._healthCache ~= nil and w._healthCache.woundedCount == d.woundedCount
end, function(ok)
    if not S.hGo then return end
    local w, d = RT.cw(), H.fresh()
    Q.check(ok, "Health: healed, the open tab shows no wound left (nothing stale)",
        "tab " .. tostring(w._healthCache and w._healthCache.woundedCount) .. ", game " .. tostring(d and d.woundedCount))
    H.noErr("the Health tab healed")
    RT.charTab("loot")
end)

-- ===================================================================== 5. Messages and the Mods list
function H.mw() local w = nil; pcall(function() w = ZeD.MessagesWindow.get(S.pn) end); return w end
function H.msgOpen()
    S.msg = nil
    if not ZeD.MessagesWindow then Q.check(false, "ZeD's Messages window is loaded"); return end
    H.closeMenu()
    local okO, e = pcall(ZeD.MessagesWindow.open, S.pn, nil)
    Q.check(okO, "Messages opens (the belt's note)", okO and nil or tostring(e))
    S.msg = okO and { i = 0, t = 0, names = {}, om = nil } or nil
end
function H.msgRows()
    local M = S.msg
    local win = H.mw()
    if not (M and win) then return end
    local okR, rows = pcall(win.rows, win)
    if not Q.check(okR and type(rows) == "table", "Messages lists its sources", okR and nil or tostring(rows)) then S.msg = nil; return end
    for _, r in ipairs(rows) do if r.src then M.names[#M.names + 1] = r.src.name end end
    Q.say("Messages: " .. #M.names .. " sources: " .. table.concat(M.names, " | "))
    RT.bounds(Q, "Messages open")
end
-- every source chosen in turn, a few frames each; an error card's Open in Mods button is noted on the way
function H.msgTick()
    local M = S.msg
    local win = H.mw()
    if not (M and win) then return true end
    M.t = M.t + 1
    if M.t - math.floor(M.t / 5) * 5 ~= 0 then return false end
    if M.cur and not M.om then
        for _, b in ipairs(win:cardButtons()) do
            if b.openMods and not M.om then M.om = M.cur end
        end
    end
    M.i = M.i + 1
    M.cur = M.names[M.i]
    if not M.cur then return true end
    pcall(win.choose, win, M.cur)
    return false
end
function H.pressOpenMods()
    local M = S.msg
    local win = H.mw()
    S.jumped = false
    if not (M and win and M.om) then return end
    for _, b in ipairs(win:cardButtons()) do
        if b.openMods and not S.jumped then
            local okP, e = pcall(win.pressCard, win, b)
            S.jumped = Q.check(okP, "Messages: Open in Mods pressed on the error card of '" .. tostring(M.om) .. "'", okP and nil or tostring(e))
        end
    end
end
step(10, function() H.msgOpen() end)
waitFor(3, 200, function() local w = H.mw(); return not S.msg or (w ~= nil and w:isReallyVisible()) end, function(ok)
    if S.msg then Q.check(ok, "the Messages window is on screen") end
end)
step(6, function() H.msgRows() end)
waitFor(1, 1500, function() return H.msgTick() end, function()
    if not S.msg then return end
    H.noErr("Messages, every source chosen in turn (" .. #S.msg.names .. ")")
    RT.bounds(Q, "Messages after its sources")
    local win = H.mw()
    if S.msg.om and win then pcall(win.choose, win, S.msg.om) end
    if S.handed and S.head and ZeD.Messages.sources[S.head] and win then pcall(win.choose, win, S.head) end
end)
step(12, function()
    local MM = ZeD.MainMenu
    S.MM = MM
    S.jump0 = MM and MM.pauseJump
    S.page0 = MM and MM.pause and MM.pause.page
    S.menuWas = H.menuUp()
    S.pauseGo = false
    if not (S.msg and MM) then return end
    if S.handed and S.msg.om == nil then RT.bounds(Q, "Messages on the step-aside notice") end
    if S.msg.om then
        local win = H.mw()
        if win then pcall(win.choose, win, S.msg.om) end
    else
        Q.skip("Messages: an error card's Open in Mods", "no mod threw an error this session, so Messages holds no error card; the pause menu's Mods button is used")
    end
end)
step(8, function()
    if not (S.msg and S.MM) then return end
    H.pressOpenMods()
    if not S.jumped then
        local win = H.mw()
        if win then pcall(function() win:close() end) end
        if not S.menuWas then H.toggleMenu() end
    end
    S.pauseGo = true
end)
waitFor(10, 500, function() return not S.pauseGo or (H.menuUp() and S.MM.pause ~= nil) end, function(ok)
    if not S.pauseGo then return end
    S.pauseOk = Q.check(ok, "the pause menu opens (ZeD's pause window)", "menu up " .. tostring(H.menuUp()))
    S.menuMine = not S.menuWas and H.menuUp()
    if not S.pauseOk or S.jumped then return end
    local pressed = false
    for _, s in ipairs(S.MM.pause._specs or {}) do
        if s.id == "mods" and s.fn and not pressed then pressed = pcall(s.fn) end
    end
    Q.check(pressed, "the pause window's Mods button is there and takes a press")
end)
function H.modsPage()
    local w = S.MM.pause
    local items = w._mods and w._mods.items or {}
    local _, n = H.active()
    local seen, bad, twice = {}, {}, {}
    for _, e in ipairs(items) do
        local id = H.bare(e.id)
        if seen[id] then twice[#twice + 1] = id end
        seen[id] = e
        if e.bad then bad[#bad + 1] = id .. " (" .. tostring(e.status) .. ")" end
    end
    Q.check(#items == n and #twice == 0, "the Mods page lists every mod that is on, once each", #items .. " rows for " .. n .. " mods" .. ((#twice > 0) and ("; twice: " .. table.concat(twice, ", ")) or ""))
    local missing, unnamed = {}, {}
    for _, m in ipairs(LIST) do
        if S.on[m.id] then
            local e = seen[m.id]
            if not e then missing[#missing + 1] = m.id
            elseif tostring(e.name or "") == "" or tostring(e.name) == tostring(e.id) then unnamed[#unnamed + 1] = m.id end
        end
    end
    Q.check(#missing == 0 and seen["ZeD_UI"] ~= nil, "the Mods page names each of the test's mods and ZeD", (#missing > 0) and ("missing: " .. table.concat(missing, ", ")) or nil)
    Q.check(#unnamed == 0, "each is listed by its name, not its bare id", (#unnamed > 0) and table.concat(unnamed, ", ") or nil)
    Q.say("the Mods page marks: " .. ((#bad > 0) and table.concat(bad, "; ") or "nothing (no mod missing, unavailable or with errors)"))
    if S.jumped then
        Q.check(w._mods ~= nil and w._mods.note ~= nil, "the Mods page says where the Mods screen will open (the error's file)", tostring(S.MM.pauseJump and S.MM.pauseJump.file))
    end
    local onScreen = false
    pcall(function()
        local W, Hh = RT.core:getScreenWidth(), RT.core:getScreenHeight()
        local x, y = w:getAbsoluteX(), w:getAbsoluteY()
        onScreen = x >= -1 and y >= -1 and x + w:getWidth() <= W + 1 and y + w:getHeight() <= Hh + 1
    end)
    Q.check(onScreen, "the pause window with its Mods list is inside the screen", math.floor(w:getWidth()) .. "x" .. math.floor(w:getHeight()) .. " for " .. #items .. " rows")
end
waitFor(6, 400, function()
    if not S.pauseOk then return true end
    local w = S.MM.pause
    return w.page == "mods" and w._mods ~= nil
end, function(ok)
    if not S.pauseOk then return end
    if not Q.check(ok, "the pause window shows its Mods page", "page " .. tostring(S.MM.pause.page)) then return end
    local okM, e = pcall(H.modsPage)
    if not okM then Q.check(false, "the Mods page's rows read", tostring(e)) end
    H.noErr("the pause window's Mods page")
end)
-- the conflict scan's own code over these mods' files (the Mods screen that shows it is a main-menu screen)
step(4, function()
    S.scan = false
    local MSc = ZeD.ModScan
    if not (S.pauseOk and MSc and MSc.start and MSc.step) then
        Q.skip("the conflict scan over these mods", "the pause window did not open, or ZeD.ModScan is not loaded in a game")
        return
    end
    local okS, e = pcall(MSc.start)
    S.scan = Q.check(okS, "the conflict scan starts over this game's mods", okS and nil or tostring(e))
    S.scanT = getTimestampMs()
end)
waitFor(1, 2400, function()
    if not S.scan then return true end
    local MSc = ZeD.ModScan
    for _ = 1, 3 do pcall(MSc.step) end
    return MSc.res ~= nil and MSc.res.done == true
end, function(ok)
    if not S.scan then return end
    local MSc = ZeD.ModScan
    if not ok then
        Q.skip("the conflict scan finishes", "still reading the mods' files after " .. math.floor((getTimestampMs() - S.scanT) / 1000) .. " s")
        return
    end
    local out, badN = {}, {}
    for _, m in ipairs(LIST) do
        local okC, c = pcall(MSc.count, m.id)
        local okS2, same = pcall(MSc.sameFor, m.id)
        if okC and okS2 and type(c) == "number" and type(same) == "number" then
            if c + same > 0 then out[#out + 1] = m.id .. " " .. c .. " (+" .. same .. " identical)" end
        else
            badN[#badN + 1] = m.id .. ": " .. tostring(c)
        end
    end
    local zc = 0
    pcall(function() zc = MSc.count("ZeD_UI") end)
    Q.check(#badN == 0, "the conflict scan finishes and counts each mod's conflicts (" .. math.floor((getTimestampMs() - S.scanT) / 1000) .. " s)",
        (#badN > 0) and table.concat(badN, "; ") or ("with conflicts: " .. ((#out > 0) and table.concat(out, ", ") or "none") .. "; ZeD_UI " .. tostring(zc)))
    H.noErr("the conflict scan")
end)
function H.pauseBack()
    pcall(function() if S.jumped and ZeD.ModFiles and ZeD.ModFiles.takeJump then ZeD.ModFiles.takeJump() end end)
    S.jumped = false
    pcall(function()
        if S.MM then
            S.MM.pauseJump = S.jump0
            if S.MM.pause then S.MM.pause.page = S.page0; S.MM.pause.focusId = nil end
        end
    end)
    if S.menuMine and H.menuUp() then H.toggleMenu() end
end
step(6, function() H.pauseBack() end)
waitFor(5, 400, function() return not S.menuMine or not H.menuUp() end, function(ok)
    if S.menuMine then Q.check(ok, "the pause menu shuts again and the game runs on", "speed " .. tostring(getGameSpeed())) end
    S.menuMine = nil
end)

-- ===================================================================== put back
Q.mark()
function H.backThings()
    H.pauseBack()
    H.closeMenu()
    local win = H.mw()
    if win then pcall(function() if win:isReallyVisible() then win:close() end end) end
    H.heal()
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    if S.styleWas ~= nil then pcall(function() ZeD.Settings.contextStyleOption:setValue(S.styleWas) end) end
    pcall(function() S.p:setPrimaryHandItem(S.ph) end)
    pcall(function() S.p:setSecondaryHandItem(S.sh) end)
    for it, was in pairs(S.readWas or {}) do it.read = was end
    pcall(function() ZeD.Messages.seq = (ZeD.Messages.seq or 0) + 1 end)
    local c = H.cc()
    if c then
        pcall(function()
            local sel = c._selectedItems or {}
            for k in pairs(sel) do sel[k] = nil end
            c._lastClickedItem = nil
            if S.scroll0 ~= nil and c._scroll then c._scroll:setScrollPos(S.scroll0) end
        end)
    end
    local v = H.vanilla()
    if v and S.vanWas == false and H.vanillaShown() then pcall(function() v:setVisible(false) end) end
end
function H.backFile()
    local now = H.readLines("ZeD_step_aside.txt")
    local same = (now == nil and S.saLines == nil) or (now ~= nil and S.saLines ~= nil and table.concat(now, "\n") == table.concat(S.saLines, "\n"))
    if not same and S.saLines then
        H.writeLines("ZeD_step_aside.txt", S.saLines)
        pcall(ZeD.StepAside.reload)
        now = H.readLines("ZeD_step_aside.txt")
        same = now ~= nil and table.concat(now, "\n") == table.concat(S.saLines, "\n")
    end
    Q.check(same, "put back: the step-aside file is as this script found it", tostring(now and #now) .. " lines, " .. tostring(S.saLines and #S.saLines) .. " at the start")
end
function H.backWindows()
    if RT.isOpen() then
        if S.tabC0 then RT.charTab(S.tabC0) end
        if S.tabW0 then RT.worldTab(S.tabW0) end
    end
    if ZEDQA_LAYOUT_BACK and S.pairWas then pcall(ZEDQA_LAYOUT_BACK, S.snap, TAG) end
end
function H.backCheck()
    if S.pairWas == false then RT.pairShut() elseif not RT.isOpen() and S.mine.windows then RT.pairOpen() end
    pcall(ZEDQA_SPEED or setGameSpeed, 1)
    if ZEDQA_HOME then pcall(ZEDQA_HOME, TAG) end
    local o = ZeD.Settings and ZeD.Settings.contextStyleOption
    Q.check(o == nil or o:getValue() == S.styleWas, "put back: the Context menu setting", tostring(o and o:getValue()))
    Q.check(S.p:getPrimaryHandItem() == S.ph and S.p:getSecondaryHandItem() == S.sh, "put back: the hands hold what they held")
    local d = H.fresh()
    local hp = nil
    pcall(function() hp = S.p:getBodyDamage():getOverallBodyHealth() end)
    Q.check(d ~= nil and d.woundedCount <= (S.w0 or 0), "put back: no wound left on the character", "wounded parts " .. tostring(d and d.woundedCount) .. ", health " .. tostring(hp))
    if S.godBack ~= nil then
        Q.check(S.p:isGodMod() == S.godBack, "put back: god mode as it was (" .. tostring(S.godBack) .. ")", tostring(S.p:isGodMod()))
    end
    Q.check(not H.menuUp() and getGameSpeed() == 1, "put back: the pause menu shut, game speed 1", "speed " .. tostring(getGameSpeed()))
    local n = H.errs()
    Q.say("the whole run: " .. tostring((n and S.err0) and (n - S.err0) or "?") .. " Lua errors with " .. #LIST .. " mods on" ..
        ((n and S.err0 and n > S.err0) and ("; Messages holds errors from: " .. H.errNames()) or ""))
end
Q.step(2, function() if S.p then H.backThings() end end)
Q.step(6, function() if S.p and ZeD and ZeD.StepAside then H.backFile() end end)
Q.step(6, function() if S.p then H.backWindows() end end)
Q.step(20, function() if S.p and ZeD and ZeD.HealthTab then H.backCheck() end end)
Q.start()
