-- ZeDUI/tools/qa/bxr_lite.lua  (Nov 21 2026, QA beast day; tag bxrl): the beast day report's pictures for Lite's ZeD
-- setup and the Animals tab, full screen at 4K, on the picture kit (gallery_v1_a_common.lua G1, hfr_common.lua HFR).
-- Manifest beast_report_lite.txt (beast_report_run.ps1 -Part lite). Pictures to Screenshots/bxr_<name>.png:
--   B3-2_lite_extras_on_additions_shown     ZeD setup in Lite from the pause menu, the extras still on (Style Lite set
--                                           as a value over the Vanilla Plus additions): the Additions group shows
--   B3-2_lite_extras_vanilla_additions_out  the same page, the extras on the Vanilla preset: the group is left out
--   B3-1_lite_defaults_live                 Lite with the extras on, scrolled to the Additions group: its rows read On
--                                           and Defaults (bottom left, by Back) is live, before it is pressed
--   B3-1_lite_after_defaults_extras_off     after Defaults (no Apply; Discard after): the extras read Off, Defaults greys
--   B7-5_before_remove_two_pens             the Animals tab's overview at the farm, two pens with animals
--   B7-5_after_remove_card_gone             after Remove zone on one pen, its animals still standing there: its card gone
-- The setup pictures: nothing is applied. The Options window is held solid (as with the pointer on it) and the pointer
-- the game reads is held on its title bar, so no row or button lights by chance (no hover in any picture).
-- The farm: zedqa_farm_spot.lua (earlier in the manifest) found the open 17 x 17 and stood the character in its middle;
-- two pens are made in it with a gap down the middle, and the character stays in the gap at the middle, so eight open
-- squares lie in front of him (south and east) and nothing beyond them can be drawn over him. Every animal stands on
-- one row two squares behind his, left and right of him: none over him, none under the windows. The overview is
-- scrolled as little as it takes to show both pens' cards (the farm's own zones are listed on it too).
-- WHAT IT PUTS BACK: every ZeD option as found (Style and each addition), the look, ModOptions.ini and
-- ZeD_custom_additions.txt line for line, the pause menu shut, getMouseX / getMouseY, the windows at their default
-- places and open or shut as found, both pens and every animal it made, the Animals tab on its overview, the World
-- window on Loot, game speed, the cheats as found, the character healed if hurt. grep "ZEDQA bxrl".
local S = HFR and HFR.init and HFR.init("bxrl", true)
if not S then return end
S.DIR = "bxr_"
local Q = S.Q
local MM, St = ZeD.MainMenu, ZeD.Settings
local AT, AP = ZeD.AnimalsTab, ZeD.AnimalsAlertPoller
local K = {}

-- ===================================================================== small helpers
function K.shot(name, what, keepMenu) S.shot(name, keepMenu); Q.say("SHOT " .. name .. " | " .. tostring(what)) end
function K.skip(name, why) Q.nErr = Q.nErr + 1; Q.say("SKIP " .. name .. " | " .. tostring(why)) end
function K.opts() local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo end
function K.val(id) local o = S.opt(id); local v = nil; pcall(function() v = o:getValue() end); return v end
function K.set(id, v) local o = S.opt(id); return o ~= nil and pcall(function() o:setValue(v) end) end
function K.readFile(name)
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
function K.writeFile(name, lines, eol)
    if not lines then return false end
    return pcall(function()
        local w = getFileWriter(name, true, false)
        for _, l in ipairs(lines) do w:write(l .. eol) end
        w:close()
    end)
end
function K.sameLines(a, b)
    if a == nil or b == nil then return a == b end
    if #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end
-- every ZeD option that holds a number or a yes/no: its stored value
function K.snapshot()
    local t, n = {}, 0
    local zo = K.opts()
    for id, o in pairs((zo and zo.dict) or {}) do
        local v = nil
        pcall(function() if type(o) == "table" and o.getValue and o.setValue then v = o:getValue() end end)
        if type(v) == "number" or type(v) == "boolean" then t[id] = v; n = n + 1 end
    end
    return t, n
end
function K.restoreOpts()
    local bad, n = {}, 0
    for id, v in pairs(S.opt0 or {}) do
        if K.val(id) ~= v then
            n = n + 1
            K.set(id, v)
            if K.val(id) ~= v then bad[#bad + 1] = id end
        end
    end
    return n, bad
end
-- the additions set to one of the presets (1 Vanilla, 2 Vanilla Plus), as stored values, the preset's own row with them
function K.preset(i)
    local P = St.ADDITION_PRESETS and St.ADDITION_PRESETS[i]
    local bad = {}
    for id, v in pairs(P or {}) do if not K.set(id, v) then bad[#bad + 1] = id end end
    if not K.set("additionsPreset", i) then bad[#bad + 1] = "additionsPreset" end
    return P ~= nil and #bad == 0, table.concat(bad, " ")
end
function K.offVanilla() return (St.additionsOffVanilla and St.additionsOffVanilla()) and true or false end

-- the pointer the game reads (Mouse.setXY does not move it): held where the script says, and given back
function K.holdMouse(x, y)
    if not K.gmx then
        K.gmx, K.gmy = getMouseX, getMouseY
        getMouseX = function() return K.fx end
        getMouseY = function() return K.fy end
    end
    K.fx, K.fy = math.floor(x), math.floor(y)
end
function K.freeMouse()
    if K.gmx then getMouseX, getMouseY = K.gmx, K.gmy end
    K.gmx, K.gmy = nil, nil
end

-- ----- the pause menu's Options window
function K.O() return MM.pauseOpts end
function K.optsUp() local w = K.O(); return w ~= nil and w:isVisible() end
function K.page() local w = K.O(); return w and w:pages()[w.pageIdx] end
function K.rows() local w = K.O(); local r = {}; if w then pcall(function() r = w:rowsFor(K.page()) end) end; return r end
function K.addTitle() return tostring(MM.optionGroups.text("UI_ZeD_Options_ZedAdditions")) end
function K.heads()
    local t = {}
    for _, r in ipairs(K.rows()) do if r.kind == "header" then t[#t + 1] = tostring(r.text) end end
    return t
end
-- the Additions heading: its y in the list (nil while the list has not been laid out), false when the page has none
function K.headY()
    local y = 0
    local title = K.addTitle()
    for _, r in ipairs(K.rows()) do
        if r.kind == "header" and tostring(r.text) == title then return y end
        if not r._h then return nil end
        y = y + r._h
    end
    return false
end
function K.parkOnTitle()
    local w = K.O()
    if w then K.holdMouse(w:getAbsoluteX() + w:getWidth() / 2, w:getAbsoluteY() + ZeD.T.px(8)) end
end
function K.hit(suffix)
    local w = K.O()
    for _, h in ipairs((w and w._hits) or {}) do
        local id = tostring(h.id)
        if id:sub(-#suffix) == suffix then return h end
    end
    return nil
end
function K.sel(id) local o = S.opt(id); return o and o.element and o.element.selected end
function K.extras() return "Ammo on the belt " .. tostring(K.sel("ammoBox")) .. ", Read marks " .. tostring(K.sel("readMarks")) .. ", Loadouts " .. tostring(K.sel("loadouts")) .. " (1 is Off)" end
-- the list scrolled so the Additions heading and the rows under it are in view; mode "top" keeps the page's top
-- (the Style row) in view while the heading and some rows still fit, "group" puts the heading near the list's top
function K.seek(mode)
    local w = K.O()
    local y = K.headY()
    if not (w and w._list) or y == nil then return false end
    if y == false then return true end
    local T = ZeD.T
    local want = (mode == "top") and math.max(0, y + T.px(240) - w._list.h) or math.max(0, y - T.px(40))
    if math.abs((w.scroll or 0) - want) > 1 and K.seekSet ~= want then w.scroll = want; K.seekSet = want; return false end
    return true
end
function K.headInView()
    local w = K.O()
    local y = K.headY()
    if not (w and w._list and y) then return false end
    local T = ZeD.T
    return y + T.px(3) >= w.scroll and y + T.px(26) <= w.scroll + w._list.h
end

-- ===================================================================== start
Q.step(5, function()
    S.start0()
    S.opt0, S.optN = K.snapshot()
    S.ini0 = K.readFile("ModOptions.ini")
    S.cus0 = K.readFile("ZeD_custom_additions.txt")
    S.was.base, S.was.accent, S.was.size = ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize
    S.was.x, S.was.y, S.was.z = S.p:getX(), S.p:getY(), S.p:getZ()
    S.was.wtab = S.WW() and S.WW()._activeTab
    S.mu = S.menuUp()
    Q.say(string.format("as found: Style %s, additions off Vanilla %s, preset %s, %d options kept, ModOptions.ini %s lines, custom set file %s",
        tostring(K.val("lookStyle")), tostring(K.offVanilla()), tostring(K.val("additionsPreset")), S.optN,
        tostring(S.ini0 and #S.ini0), tostring(S.cus0 and (#S.cus0 .. " lines") or "none")))
    pcall(function() S.p:setDir(IsoDirections.SE) end)
end)
Q.zoomTo(1.0)

-- ===================================================================== B3-2 and B3-1: ZeD setup in Lite
-- Lite as a value over the Vanilla Plus additions (zedqa_cfg_light_lite.lua's way: the option's own change would set
-- the additions to Vanilla): a player who came into Lite with extras on
Q.step(10, function()
    S.closePair()
    local okP, badP = K.preset(2)
    local okS = K.set("lookStyle", 2)
    pcall(St.reapplyFromOptions)
    S.styleSet = okS and okP
    Q.say("set: Style Lite " .. tostring(okS) .. ", additions Vanilla Plus " .. tostring(okP) .. ((badP ~= "") and (" (not set: " .. badP .. ")") or "")
        .. " | lite() " .. tostring(St.lite and St.lite()) .. ", additions off Vanilla " .. tostring(K.offVanilla()))
end)
Q.step(20, function() pcall(ZeD_Window.resetLayout) end)
Q.step(30, function()
    S.optOk = false
    if not S.menuUp() then S.toggleMenu() end
end)
Q.waitFor(10, 400, function() return S.menuUp() and MM.pauseOpts ~= nil end, function(ok)
    Q.say("pause menu up " .. tostring(ok))
    if ok then pcall(MM.openOptions) end
end)
Q.waitFor(5, 300, K.optsUp, function(ok)
    S.optOk = ok and true or false
    Q.say("Options open from the pause menu " .. tostring(S.optOk))
    if not S.optOk then return end
    local w = K.O()
    for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end
    w.scroll = 0
    w.focusId = nil
    w._groupCache = nil
    w.pointerOn = function() return true end   -- (solid, as with the pointer on it: Dark draws an unused window see-through)
    K.parkOnTitle()
end)
-- picture 1: the Additions group shows
Q.waitFor(10, 300, function() if not S.optOk then return true end; K.parkOnTitle(); return K.headY() ~= nil end, function() K.seekSet = nil end)
Q.waitFor(3, 300, function() return (not S.optOk) or K.seek("top") end, function() end)
Q.step(20, function()
    local name = "B3-2_lite_extras_on_additions_shown"
    if not S.optOk then K.skip(name, "Options did not open from the pause menu"); return end
    local w = K.O()
    local lite, y = (St.lite and St.lite()) and true or false, K.headY()
    S.scrollA = w.scroll
    Q.say("groups (Lite, extras on): " .. table.concat(K.heads(), " | ") .. " | scroll " .. tostring(w.scroll))
    if lite and y and K.headInView() and K.offVanilla() then
        K.shot(name, "ZeD setup from the pause menu, Style Lite, the extras on (Vanilla Plus): the " .. K.addTitle()
            .. " group is on the page; " .. K.extras(), true)
    else
        K.skip(name, "Lite " .. tostring(lite) .. ", extras off Vanilla " .. tostring(K.offVanilla()) .. ", the " .. K.addTitle()
            .. " heading on the page " .. tostring(y ~= false and y ~= nil) .. ", in view " .. tostring(K.headInView()))
    end
end)
-- B3-1, first picture: the whole Additions group, its rows On, and the Defaults button live, before it is pressed.
-- (No hover: the pointer the game reads stays on the title bar. The button is live in Lite whatever the extras, since
-- Style Lite and the run's 1.75x scale are off their defaults too; what B3-1 changed shows in the next picture.)
Q.step(5, function() K.seekSet = nil end)
Q.waitFor(3, 300, function() return (not S.optOk) or K.seek("group") end, function() K.parkOnTitle() end)
Q.step(30, function()
    local name = "B3-1_lite_defaults_live"
    if not S.optOk then K.skip(name, "Options did not open from the pause menu"); return end
    local w = K.O()
    local live = false
    pcall(function() live = w:zedOffDefault() and true or false end)
    local h = K.hit(":defaults")
    Q.say("before Defaults: something off its default " .. tostring(live) .. ", the Defaults button drawn " .. tostring(h ~= nil)
        .. ", greyed " .. tostring(h and h.disabled) .. " | " .. K.extras())
    if (St.lite and St.lite()) and K.headInView() and h and not h.disabled then
        K.shot(name, "ZeD setup in Lite with the extras on (Vanilla Plus), scrolled to the " .. K.addTitle() .. " group: its rows read On and "
            .. "Defaults (bottom left of the window, by Back) is live, not yet pressed; no hover; " .. K.extras(), true)
    else
        K.skip(name, "Lite " .. tostring(St.lite and St.lite()) .. ", the " .. K.addTitle() .. " heading in view " .. tostring(K.headInView())
            .. ", the Defaults button drawn " .. tostring(h ~= nil) .. ", greyed " .. tostring(h and h.disabled))
    end
end)
-- Defaults (no Apply), then the extras read Off
Q.step(10, function()
    if not S.optOk then return end
    local w = K.O()
    local QC = ZeD.QuickChords
    local reset = QC and QC.reset
    if QC then QC.reset = function() end end   -- (a chord saves at once; the director's chords stay)
    S.defOk = pcall(function() w:zedDefaults() end)
    if QC then QC.reset = reset end
    K.seekSet = nil
    Q.say("Defaults pressed " .. tostring(S.defOk) .. " | " .. K.extras())
end)
Q.waitFor(20, 300, function() if not S.optOk then return true end; K.parkOnTitle(); return K.headY() ~= nil end, function() K.seekSet = nil end)
Q.waitFor(3, 300, function() return (not S.optOk) or K.seek("group") end, function() end)
Q.step(30, function()
    local name = "B3-1_lite_after_defaults_extras_off"
    if not S.optOk then K.skip(name, "Options did not open from the pause menu"); return end
    local w = K.O()
    local a1, a2, a3 = K.sel("ammoBox"), K.sel("readMarks"), K.sel("loadouts")
    local off = a1 == 1 and a2 == 1 and a3 == 1
    local y = K.headY()
    local h = K.hit(":defaults")
    Q.say("after Defaults: " .. K.extras() .. ", changes waiting " .. tostring(w:anyChanged()) .. ", stored Ammo on the belt still " .. tostring(K.val("ammoBox"))
        .. ", the Defaults button greyed " .. tostring(h and h.disabled))
    if S.defOk and y and K.headInView() then
        K.shot(name, "after Defaults, nothing applied: the extras read " .. (off and "Off" or "NOT all Off") .. " (" .. K.extras()
            .. "), Defaults " .. ((h and h.disabled) and "greyed (nothing left off its default)" or "still live")
            .. "; every other ZeD row is on its default too (Style reads Full and UI scale Auto, 2x at 4K, so the window draws larger than in the"
            .. " other pictures) until Discard", true)
    else
        K.skip(name, "Defaults ran " .. tostring(S.defOk) .. ", the " .. K.addTitle() .. " heading in view " .. tostring(K.headInView()))
    end
end)
Q.step(10, function()
    if not S.optOk then return end
    local w = K.O()
    pcall(function() w:discardStay() end)
    Q.say("Discard: changes waiting " .. tostring(w:anyChanged()) .. " | " .. K.extras())
end)
-- picture 2 of B3-2: the extras on the Vanilla preset (stored), the page read again as it opens
Q.step(30, function()
    if not S.optOk then return end
    local w = K.O()
    local okP, badP = K.preset(1)
    pcall(function() w:onShow() end)
    for i, pg in ipairs(w:pages()) do if pg.setup then w.pageIdx = i end end
    w._groupCache = nil
    w.scroll = S.scrollA or 0
    K.parkOnTitle()
    Q.say("set: additions Vanilla " .. tostring(okP) .. ((badP ~= "") and (" (not set: " .. badP .. ")") or "") .. " | additions off Vanilla " .. tostring(K.offVanilla()))
end)
Q.waitFor(20, 300, function() if not S.optOk then return true end; K.parkOnTitle(); return K.headY() ~= nil end, function() end)
Q.step(20, function()
    local name = "B3-2_lite_extras_vanilla_additions_out"
    if not S.optOk then K.skip(name, "Options did not open from the pause menu"); return end
    local w = K.O()
    local lite, y = (St.lite and St.lite()) and true or false, K.headY()
    Q.say("groups (Lite, extras on Vanilla): " .. table.concat(K.heads(), " | ") .. " | scroll " .. tostring(w.scroll))
    if lite and y == false and not K.offVanilla() then
        K.shot(name, "the same page, Style Lite, every extra on the Vanilla preset: no " .. K.addTitle() .. " group (the groups: "
            .. table.concat(K.heads(), ", ") .. ")", true)
    else
        K.skip(name, "Lite " .. tostring(lite) .. ", extras off Vanilla " .. tostring(K.offVanilla()) .. ", the " .. K.addTitle()
            .. " heading still on the page " .. tostring(y ~= false))
    end
end)
-- out of Options and the pause menu, everything as found
function K.leaveOptions()
    local w = K.O()
    if w then
        w.pointerOn = nil
        if w:isVisible() then
            if w.confirm and w.confirm ~= "back" then pcall(function() w:setConfirm(false) end) end
            pcall(function() w:back() end)
            if w.confirm == "back" then pcall(function() w:discard() end) end
        end
    end
    K.freeMouse()
end
function K.optionsBack()
    local n, bad = K.restoreOpts()
    pcall(St.reapplyFromOptions)
    if S.was.base and (S.was.base ~= ZeD.currentBase or S.was.accent ~= ZeD.currentAccent or S.was.size ~= ZeD.currentSize) then
        pcall(function() ZeD.applyTheme(S.was.base, S.was.accent, S.was.size) end)
    end
    local iniNow = K.readFile("ModOptions.ini")
    local iniSame = K.sameLines(S.ini0, iniNow)
    if not iniSame and S.ini0 then K.writeFile("ModOptions.ini", S.ini0, "\r\n"); iniSame = K.sameLines(S.ini0, K.readFile("ModOptions.ini")) end
    local cusNow = K.readFile("ZeD_custom_additions.txt")
    local cusSame = K.sameLines(S.cus0, cusNow)
    if not cusSame and S.cus0 then K.writeFile("ZeD_custom_additions.txt", S.cus0, "\n"); cusSame = K.sameLines(S.cus0, K.readFile("ZeD_custom_additions.txt")) end
    Q.say("options put back: " .. n .. " set again" .. ((#bad > 0) and (", NOT " .. table.concat(bad, " ")) or ", all as found")
        .. " | Style " .. tostring(K.val("lookStyle")) .. ", look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent)
        .. " | ModOptions.ini line for line " .. tostring(iniSame) .. ", custom set file as found " .. tostring(cusSame))
    S.optsBack = true
end
Q.step(10, function() K.leaveOptions() end)
Q.step(10, function() if not S.mu and S.menuUp() then S.toggleMenu() end end)
Q.waitFor(5, 300, function() return S.mu or not S.menuUp() end, function() K.optionsBack() end)
Q.step(20, function() pcall(ZeD_Window.resetLayout) end)
Q.step(30, function() if getGameSpeed() <= 0 then setGameSpeed(1) end end)

-- ===================================================================== B7-5: Remove zone with animals still in the pen
local F = { animals = {}, keep = {}, gone = {}, pre = {}, names = {} }
local N1, N2 = "B7-5_before_remove_two_pens", "B7-5_after_remove_card_gone"
function F.W() return S.WW() end
function F.st() local w = F.W(); return w and AT.getState(w) or nil end
function F.zone(name) local z = nil; pcall(function() z = DesignationZoneAnimal.getZoneByName(name) end); return z end
function F.cellAnimals()
    local out = {}
    pcall(function()
        local it = getCell():getAnimals():iterator()
        while it:hasNext() do local a = it:next(); if a then out[#out + 1] = a end end
    end)
    return out
end
function F.spawn(kind, x, y, list)
    local a = nil
    pcall(function()
        local def = AnimalDefinitions.getDef(kind)
        local breed = def and def:getBreeds():get(0)
        if breed then a = addAnimal(getCell(), x, y, 0, kind, breed) end
    end)
    if not a then Q.say("could not make a " .. kind); return nil end
    pcall(function() a:getModData().ZeDQA_spawned = true end)
    pcall(function() a:setDebugStress(0) end)
    pcall(function() local b = a:getBehavior(); if b then b:setBlockMovement(true) end end)
    F.animals[#F.animals + 1] = a
    list[#list + 1] = a
    return a
end
function F.count(name) local s = AP.getZoneSummary(name, S.pn); return s and (s.count or #(s.animals or {})) or nil end
-- how many of the removed pen's animals name a zone as their own (the game sets it at each animal's zone check)
function F.owned()
    local n = 0
    for _, a in ipairs(F.gone) do
        local z = nil
        pcall(function() z = a:getDZone() end)
        if z then n = n + 1 end
    end
    return n
end
function F.inWorld(list)
    local live, n = {}, 0
    for _, a in ipairs(F.cellAnimals()) do live[a] = true end
    for _, a in ipairs(list) do if live[a] then n = n + 1 end end
    return n
end
function F.stand(x, y)
    local p = S.p
    pcall(function() p:setX(x); p:setY(y); p:setZ(0); p:setLastX(x); p:setLastY(y); p:setLastZ(0); p:setDir(IsoDirections.SE) end)
end
function F.cardDrawn(name)
    local w = F.W()
    for _, z in ipairs((w and w._animalsZoneCardZones) or {}) do
        if z.zoneName == name then return true end
    end
    return false
end
-- a zone card's place on the overview's page from the last frame ({ cy, h }), nil when it was not drawn
function F.cardRow(name)
    local w = F.W()
    local rows = w and w._animalsOvRows
    return rows and rows["animals:zonecard:" .. tostring(name)] or nil
end
-- the overview scrolled to off px of its page (clamped; nothing to do when the page fits its view)
function F.scrollTo(off)
    local w = F.W()
    local sc, clip = w and w._animalsScroll, w and w._animalsOvClip
    if not (sc and sc.setScrollPos and clip) then return false end
    local maxOff = math.max(0, (w._animalsOvH or 0) - clip.h)
    if maxOff <= 0 then return true end
    pcall(function() sc:setScrollPos(math.max(0, math.min(maxOff, off)) / maxOff) end)
    return true
end
-- a zone card drawn wholly inside the overview's view (the last frame)
function F.cardInView(name)
    local w = F.W()
    local clip = w and w._animalsOvClip
    if not clip then return false end
    for _, z in ipairs((w and w._animalsZoneCardZones) or {}) do
        if z.zoneName == name then return z.y >= clip.y - 1 and z.y + z.h <= clip.y + clip.h + 1 end
    end
    return false
end
-- the zombies within 40 squares taken away before a farm picture (QA save only, as S.start0 does at the start: the
-- wait at 3x gives others time to walk up)
function F.noZombies()
    local gone = 0
    pcall(function()
        local zl = getCell():getZombieList()
        local px, py = S.p:getX(), S.p:getY()
        for i = zl:size() - 1, 0, -1 do
            local z = zl:get(i)
            if z and math.abs(z:getX() - px) < 40 and math.abs(z:getY() - py) < 40 then z:removeFromWorld(); z:removeFromSquare(); gone = gone + 1 end
        end
    end)
    return gone
end
function F.back()
    local n = { animals = 0, zones = 0 }
    local w = F.W()
    if w and F.preSet then
        pcall(AT._endZoneEdit, w)
        pcall(AT._unlightZone, w)
        pcall(AT.switchSubmode, w, "ranch")
        if w._animalsScroll and w._animalsScroll.setScrollPos then pcall(function() w._animalsScroll:setScrollPos(0) end) end
    end
    for _, a in ipairs(F.animals) do
        if pcall(function() a:removeFromWorld(); a:removeFromSquare() end) then n.animals = n.animals + 1 end
    end
    F.animals = {}
    -- (an animal the game made again in the script's place, should one have been: it carries the script's mark)
    for _, a in ipairs(F.cellAnimals()) do
        local mine = false
        pcall(function() local md = a:getModData(); mine = md ~= nil and md.ZeDQA_spawned == true end)
        if F.preSet and mine and not F.pre[a] then pcall(function() a:removeFromWorld(); a:removeFromSquare() end); n.animals = n.animals + 1 end
    end
    for _, name in ipairs(F.names) do
        for _ = 1, 3 do
            local z = F.zone(name)
            if z then pcall(function() DesignationZoneAnimal.removeZone(z, true) end); n.zones = n.zones + 1 end
        end
    end
    pcall(function() S.p:resetSelectedZonesForHighlight(); S.p:setSeeDesignationZone(false) end)
    pcall(AP.refreshCache, S.pn)
    local left = {}
    for _, name in ipairs(F.names) do if F.zone(name) then left[#left + 1] = name end end
    F.names = {}
    return n, left
end

Q.step(10, function()
    F.ok = false
    local FARM = ZEDQA_FARM
    local z = FARM and FARM.zone
    if not (AT and AP and AT.navigate and AT.zoneAct and AT.getState and DesignationZoneAnimal and AnimalDefinitions and addAnimal) then
        F.why = "the Animals tab or the game's animal calls are not there"
    elseif not z then
        F.why = "zedqa_farm_spot.lua found no open 17 x 17 at the farm (or did not run before this script)"
    end
    if F.why then return end
    F.cx, F.cy = math.floor((z[1] + z[3]) / 2), math.floor((z[2] + z[4]) / 2)
    -- the character in the middle of the open 17 x 17 (where zedqa_farm_spot.lua stood him), in the gap between the
    -- pens: eight open squares in front of him (south and east), so nothing past the open ground can be drawn over him
    F.stand(F.cx + 0.5, F.cy + 0.5)
    F.staged = true
end)
Q.waitFor(10, 900, function()
    if not F.staged then return true end
    local c = getCell()
    return c:getGridSquare(F.cx - 8, F.cy - 8, 0) ~= nil and c:getGridSquare(F.cx + 8, F.cy + 8, 0) ~= nil and c:getGridSquare(F.cx, F.cy, 0) ~= nil
end, function(ok)
    if not F.staged then return end
    if not ok then F.why = "the farm's ground did not load round " .. F.cx .. "," .. F.cy; return end
    F.keepName, F.goneName = "Home Pasture", "Back Pen"
    if F.zone(F.keepName) or F.zone(F.goneName) then F.keepName, F.goneName = "QA Home Pasture", "QA Back Pen" end
    if F.zone(F.keepName) or F.zone(F.goneName) then F.why = "pens named " .. F.keepName .. " or " .. F.goneName .. " are already in the save"; return end
    for dx = -8, 8 do
        for dy = -8, 8 do
            local zz = nil
            pcall(function() zz = DesignationZoneAnimal.getZone(F.cx + dx, F.cy + dy, 0) end)
            if zz then F.why = "an animal zone already covers " .. (F.cx + dx) .. "," .. (F.cy + dy); return end
        end
    end
    for _, a in ipairs(F.cellAnimals()) do F.pre[a] = true end
    F.preSet = true
    -- two pens inside the open 17 x 17 (about 6 x 16 each), open ground between them for the character
    F.names = { F.keepName, F.goneName }
    local okZ, eZ = pcall(function()
        DesignationZoneAnimal.new(F.keepName, F.cx - 8, F.cy - 8, 0, F.cx - 2, F.cy + 8, true)
        DesignationZoneAnimal.new(F.goneName, F.cx + 2, F.cy - 8, 0, F.cx + 8, F.cy + 8, true)
    end)
    if not (okZ and F.zone(F.keepName) and F.zone(F.goneName)) then F.why = "the two pens could not be made (" .. tostring(eZ) .. ")"; return end
    -- every animal on one row two squares behind the character's (x + y two less than his): on the screen a line just
    -- above his feet, 384 to 896 px left and right of him at zoom 1, so none is over him and all are below the
    -- windows' bottom edge (735 px at 4K) wherever the windows sit
    F.spawn("ewe", F.cx - 4, F.cy + 2, F.keep)
    F.spawn("ewe", F.cx - 6, F.cy + 4, F.keep)
    F.spawn("ewe", F.cx + 2, F.cy - 4, F.gone)
    F.spawn("cow", F.cx + 4, F.cy - 6, F.gone)
    F.spawn("cow", F.cx + 6, F.cy - 8, F.gone)
    if #F.gone == 0 then F.why = "no animal could be made in " .. F.goneName; return end
    pcall(AP.refreshCache, S.pn)
    F.ok = true
    Q.say(string.format("farm: pens %s (%d animals) and %s (%d animals) round %d,%d; the character at %d,%d", F.keepName, #F.keep, F.goneName, #F.gone,
        F.cx, F.cy, math.floor(S.p:getX()), math.floor(S.p:getY())))
end)
Q.step(10, function()
    if not F.ok then return end
    S.openPair()
    pcall(ZeD_Window.resetLayout)
end)
Q.waitFor(20, 300, function()
    if not F.ok then return true end
    local w = F.W()
    if not w then return false end
    if w._activeTab ~= "animals" then
        if not S.worldTab("animals") then pcall(ZeD_WorldWindow.openTab, S.pn, "animals") end
        return false
    end
    return true
end, function(ok)
    if not F.ok then return end
    if not ok then F.ok = false; F.why = "the World window's Animals tab did not open"; return end
    pcall(AT.switchSubmode, F.W(), "ranch")
    F.n = 0
    pcall(function() setGameSpeed(3) end)   -- (3x through the wait for the animals' own zone check, back to 1 before the picture)
end)
-- each animal counted in its pen, and the removed pen's animals naming it as their own zone (what kept the ghost card)
Q.waitFor(5, 2400, function()
    if not F.ok then return true end
    F.n = F.n + 1
    if F.n - math.floor(F.n / 30) * 30 == 0 then pcall(AP.refreshCache, S.pn) end
    return F.count(F.keepName) == #F.keep and F.count(F.goneName) == #F.gone and F.owned() == #F.gone
end, function(ok)
    if not F.ok then return end
    pcall(function() setGameSpeed(1) end)
    pcall(AP.refreshCache, S.pn)
    Q.say(string.format("farm: counted %s of %d in %s, %s of %d in %s; %d of %d name a zone as their own%s", tostring(F.count(F.keepName)), #F.keep, F.keepName,
        tostring(F.count(F.goneName)), #F.gone, F.goneName, F.owned(), #F.gone, ok and "" or " (waited the whole time)"))
    F.stand(F.cx + 0.5, F.cy + 0.5)
end)
Q.step(60, function()
    if not F.ok then return end
    S.clearChar()
    Q.say("zombies taken away near the farm: " .. F.noZombies())
end)
-- both pens' cards in view: the overview scrolled as little as it takes (Alerts above, and the farm's own zones are
-- listed too, so the two cards can start below the view); the offset is kept for the second picture
Q.waitFor(5, 300, function()
    if not F.ok then return true end
    local w = F.W()
    local a, b = F.cardRow(F.keepName), F.cardRow(F.goneName)
    local clip = w and w._animalsOvClip
    if not (a and b and clip) then return false end
    F.ovOff = math.max(0, math.min(a.cy, b.cy + b.h - clip.h + ZeD.T.px(4)))
    F.scrollTo(F.ovOff)
    return F.cardInView(F.keepName) and F.cardInView(F.goneName)
end, function(ok)
    if F.ok then Q.say("both pens' cards in view " .. tostring(ok) .. " (the overview scrolled " .. tostring(F.ovOff) .. " px)") end
end)
Q.still(10, function()
    if not F.ok then K.skip(N1, F.why or "the farm was not staged"); return end
    local st, w = F.st(), F.W()
    local cA, cB = F.count(F.keepName), F.count(F.goneName)
    local inA, inB = F.cardInView(F.keepName), F.cardInView(F.goneName)
    if w and w._activeTab == "animals" and st and st.view == "overview" and (cB or 0) >= 1 and inA and inB then
        K.shot(N1, "the Animals tab's overview at the farm: " .. F.keepName .. " with " .. tostring(cA) .. " animals and " .. F.goneName .. " with " .. tostring(cB)
            .. ", a card each, both in view; the animals stand on a row just behind the character, left and right of him")
    else
        K.skip(N1, "tab " .. tostring(w and w._activeTab) .. ", view " .. tostring(st and st.view) .. ", " .. F.goneName .. " counts " .. tostring(cB)
            .. " animals, the cards in view " .. tostring(inA) .. " / " .. tostring(inB))
        F.ok = false
        F.why = "the pens did not show with their animals"
    end
end)
-- Remove zone as the player does it: the pen's page, Remove zone, the question's Remove
Q.step(10, function() if F.ok then pcall(AT.navigate, F.W(), "zone", F.goneName, nil) end end)
Q.step(40, function()
    if not F.ok then return end
    local w = F.W()
    local _, r = pcall(AT.zoneAct, w, "remove")
    Q.say("Remove zone asks first: " .. tostring(r == true and w._animalsRemoveConfirm == true))
end)
Q.step(30, function()
    if not F.ok then return end
    local _, r = pcall(AT.zoneAct, F.W(), "yes")
    Q.say("the question's Remove pressed: " .. tostring(r == true))
end)
Q.waitFor(5, 300, function()
    if not F.ok then return true end
    local st = F.st()
    return st and st.view == "overview" and F.zone(F.goneName) == nil
end, function(ok)
    if not F.ok then return end
    F.removed = ok and true or false
    S.clearChar()
    Q.say("zombies taken away near the farm: " .. F.noZombies())
end)
-- the overview at the first picture's scroll: Home Pasture's card where it was, and under it what the tab still lists
-- (the removed pen's card came after it, so a card left behind would show in the same place)
Q.waitFor(3, 300, function()
    if not F.ok then return true end
    F.scrollTo(F.ovOff or 0)
    return F.cardInView(F.keepName)
end, function() end)
Q.still(5, function()
    if not F.ok then K.skip(N2, F.why or "the farm was not staged"); return end
    local st, w = F.st(), F.W()
    local ghost = AP.getZoneSummary(F.goneName, S.pn)
    local card = F.cardDrawn(F.goneName)
    local there, own = F.inWorld(F.gone), F.owned()
    local inA = F.cardInView(F.keepName)
    Q.say(string.format("after Remove: the game still has the pen %s; the Animals tab still lists it %s%s; view %s; its animals still in the world %d of %d, %d still name a zone as their own",
        tostring(F.zone(F.goneName) ~= nil), tostring(ghost ~= nil or card), ghost and (" with " .. tostring(ghost.count) .. " animals") or "", tostring(st and st.view), there, #F.gone, own))
    if F.removed and w and w._activeTab == "animals" and there >= 1 and inA then
        K.shot(N2, "the overview right after Remove zone on " .. F.goneName .. ": its card is " .. ((ghost or card) and "STILL THERE (the fault)" or "gone") .. ", "
            .. F.keepName .. "'s card stays; " .. there .. " of its animals still stand where the pen was (" .. own .. " still name a zone as their own)")
    else
        K.skip(N2, "the pen removed " .. tostring(F.removed) .. ", tab " .. tostring(w and w._activeTab) .. ", its animals still in the world " .. there
            .. ", " .. F.keepName .. "'s card in view " .. tostring(inA))
    end
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    -- (a run cut short lands here: the pause menu, the options, the pointer and the speed first)
    K.leaveOptions()
    if not S.mu and S.menuUp() then S.toggleMenu() end
    if not S.optsBack then K.optionsBack(); pcall(ZeD_Window.resetLayout) end
    if getGameSpeed() ~= 1 then pcall(function() setGameSpeed(1) end) end
end)
Q.step(10, function()
    local n, left = F.back()
    Q.say("farm put back: " .. n.animals .. " animals and " .. n.zones .. " pens taken away" .. ((#left > 0) and (", STILL THERE: " .. table.concat(left, ", ")) or ", none left"))
    if S.was.x then
        local p = S.p
        pcall(function() p:setX(S.was.x); p:setY(S.was.y); p:setZ(S.was.z); p:setLastX(S.was.x); p:setLastY(S.was.y); p:setLastZ(S.was.z) end)
    end
    local hurt = false
    pcall(function() hurt = S.p:getBodyDamage():getOverallBodyHealth() < 100 end)
    if hurt then pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end) end
    Q.say("the character alive " .. tostring(not S.p:isDead()) .. ", healed by the script " .. tostring(hurt))
    S.takeMade()
    G1.glassesBack(Q)
end)
Q.step(20, function()
    S.openPair(); S.charTab("loot"); S.worldTab("loot")
    S.back0()
end)
Q.step(30, function()
    pcall(ZeD_Window.resetLayout)
    if not S.was.pairOpen then S.closePair() end
    pcall(function() Mouse.setCursorVisible(true) end)
    local bad = {}
    for id, v in pairs(S.opt0 or {}) do if K.val(id) ~= v then bad[#bad + 1] = id end end
    Q.say("put back: options " .. ((#bad == 0) and "all as found" or ("NOT " .. table.concat(bad, " "))) .. ", pause menu up " .. tostring(S.menuUp())
        .. ", the game's own pointer calls back " .. tostring(K.gmx == nil) .. ", speed " .. tostring(getGameSpeed()))
end)
Q.start()
