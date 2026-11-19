-- ZeDUI/tools/qa/showcase_s3.lua  (Nov 18 2026, QA): the 1.0 Workshop description's showcase graphic 3, "Built for the
-- controller / Made to be read" (ZeDUI/workshop/showcase/SHOWCASE_CAPTURES.md, section 3). Angel Cross at the West
-- Point Fossoil (gallery_story_stage.lua): the controller shots on the forecourt by the pump and the story's station
-- wagon (spot pump), the theme and language shots inside among the shelves (spot stock). Daylight, the load under
-- 20 kg, no prescription glasses, no debug text, the pointer hidden, both windows at their own working heights to one
-- side with Angel uncovered (each shot logs its boxes, "COVERS the character" on one in front of him).
-- The shots land in Zomboid/Screenshots as sc3_<what>.png (flat, like every gallery script's; move them into
-- Screenshots/showcase/ after the run: Move-Item ~/Zomboid/Screenshots/sc3_*.png ~/Zomboid/Screenshots/showcase/).
--   sc3_buttonmap     the pause screen's Options > Controls > Button map and test, the Xbox pictures, the drawn pad with
--                     a made-up moment of input lit (A, the D-pad's left arm, RB, the left stick's click, the stick
--                     pushed, LT most of the way): gallery_v1_c3_b.lua's zqa_padmap_options, zedqa_pad_figure.lua
--                     "02_lit". The Options window sits to one side.
--   sc3_context       the whole screen on the controller: both windows open (Character on Equipment with the doll in
--                     its drawer, World on Loot), the hint strip above the belt with the game's button prompts in
--                     ZeD's button pictures, the belt, the moodles and the HUD
--   sc3_pad           the same spot: the Character window on Loot, the controller's highlight (the pointing hand) on
--                     the hammer's row, its card beside it, the window's foot showing the buttons as pictures
--   sc3_wheel         the same spot, the windows still open but not holding the pad: the D-pad's Character wheel
--                     open, Eat pointed (its quick chord in the bubble). A wheel cannot open while a window holds the
--                     pad (the D-pad moves in the window), and the hint strip is down while a window or a wheel has
--                     the pad, so the row, the strip and the wheel are three shots of one moment, not one
--   sc3_themes_dark   among the shelves: the Character window on Loot with the apple's card out in its drawer, the
--   sc3_themes_light  World window on Loot at the shelves; one spot and one moment, the same accent, only the theme
--   sc3_themes_hicon  changing (Dark, Light, High contrast)
--   sc3_language      the same moment as the themes, Dark, in the game's language. ONLY in a run with the game in
--                     another language (the game reads its language at launch: no live switch); in English the
--                     script takes the other six and logs sc3_language as not taken; in another language it takes
--                     only sc3_language. Russian is the one proven in game (Screenshots/lang_RU); Japanese works the
--                     same way (-Lang JP).
-- Run (QA only, after the gallery staging in the manifest):
--   pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Mode fullscreen4k -Manifest ZeDUI/tools/qa/showcase_s3.txt -Report showcase_s3
--   pwsh -File ZeDUI/tools/qa/lang_run.ps1 -Lang RU -Manifest showcase_s3.txt      (sc3_language; puts the language back)
-- No controller is plugged into the QA PC: ZeD's input mode is held on the controller (Detector.setLockedMode, as
-- rt_pad.lua and gallery_v1_c3_c.lua hold it) and the focus is put on a row the way gallery_v1_c3_c.lua's highlight
-- shots do. The hint strip asks the game for a pad's prompts, which the game only works out with a pad plugged in: for
-- the controller shots a stand-in asks the game's own rules (ISButtonPrompt's getBest*ButtonAction, the ones the game
-- runs for a pad each tick) and hands them to the real strip, which draws them with ZeD's button pictures. It stands
-- down, as on a real pad, while a window or a wheel holds the pad.
-- Adds three apples and a hammer (taken away after). Puts back: the theme and accent, the input mode, the focus, the
-- wheel, the button pictures, the controller highlight style, the hint strip's option and its prompts, the pause screen
-- and the Options window, the card, the list view choices, the items, the windows (place, height, tab, open), the place.
-- The language is put back by lang_run.ps1 (this script never changes it). grep "ZEDQA sc3": "shot", "not taken",
-- "box ... COVERS the character", "strip", "load", "put back".
if not C3 then print("ZEDQA sc3 ERR run gallery_v1_c3_common.lua first"); print("ZEDQA sc3 DONE"); return end
local Q = C3.make("sc3", 1100000)
local S = { items = {}, optWas = {} }
S.p, S.pn, S.core = C3.p, C3.pn, C3.core
S.St, S.MM, S.F = ZeD.Settings, ZeD.MainMenu, ZeD.Input.Focus
S.Det, S.D, S.W = ZeD.Input.Detector, ZeD.DpadWheels, ZeD.Wheel
-- the accent for every shot here: the gallery's (gallery_b11_look.lua's GAL_LOOK), so only the theme changes
S.accent = (GAL_LOOK and GAL_LOOK[2]) or "teal"
-- the game's language, read at launch: English takes six shots, any other language only sc3_language
S.lang = "EN"
pcall(function() S.lang = tostring(Translator.getLanguage():name()) end)
S.langRun = S.lang ~= "EN"

function S.setOpt(o, v) if o and v then pcall(function() o:setValue(v) end) end end
function S.getOpt(o) local v = nil; pcall(function() v = o:getValue() end); return v end
function S.add(ft) local it = S.p:getInventory():AddItem(ft); if it then S.items[#S.items + 1] = it end; return it end
function S.live()
    local function try(fn) local ok, v = pcall(fn); return ok and tostring(v) or "?" end
    return string.format("lang %s | theme %s %s %s | input %s | highlight %s | buttons %s", S.lang, tostring(ZeD.currentBase),
        tostring(ZeD.currentAccent), tostring(ZeD.currentSize), try(S.Det.getMode), try(S.St.focusStyle),
        try(function() return ZeD.PadGlyphs.set() end))
end

-- ===================================================================== the pause screen (gallery_v1_c3_b.lua)
function S.menuUp() return MainScreen and MainScreen.instance and MainScreen.instance:isVisible() end
function S.toggleMenu() ToggleEscapeMenu(getCore():getKey(KeybindId.MAIN_MENU)) end
function S.opts() return S.MM.pauseOpts or (S.MM.root and S.MM.root.optsWin) end
-- the Options window's own place() centres it every frame: wrapped on this instance to sit at one side
function S.pin(w)
    if not w or w._sc3pin then return end
    w._sc3pin = true
    w.place = function(self)
        local a, b = ZeD_MMOptions.place(self)
        local x = C3.sideX(self:getWidth(), "left")
        if self.x ~= x then self:setX(x) end
        return a, b
    end
end
function S.unpin(w) if w and w._sc3pin then w.place = nil; w._sc3pin = nil end end

-- ===================================================================== the card, the pad's row (gallery_v1_c3_c.lua)
-- the Character window's drawer shows this item's card (nil: no card)
function S.selectItem(item)
    local w = C3.CW()
    local c = w and w._mainContent
    if not (c and w._updateDrawer) then return false end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    c._selectedItems, c._lastClickedItem = sel, item
    w._updateDrawer(c)
    return true
end
function S.zoneOf(w, name) for i, z in ipairs(w and w._focusRing or {}) do if z.zone == name then return i, z end end; return nil, nil end
-- an inventory row on screen for the pad (the preferred item's when it is in view)
function S.pickRow(w, prefer)
    local _, z = S.zoneOf(w, "charMainInv")
    if not (z and z.focusable) then return nil end
    local ch = (w._mainContent and w._mainContent:getHeight()) or 0
    local pref, firstVis, firstAny
    for _, e in ipairs(z.elements or {}) do
        if e.item then
            firstAny = firstAny or e
            if ch > 0 and e.y >= 0 and e.y + e.h <= ch then
                firstVis = firstVis or e
                if prefer and e.item == prefer and not pref then pref = e end
            end
        end
    end
    return pref or firstVis or firstAny
end
-- the window takes the pad and its focus lands on that row
function S.focusOn(w, el)
    S.F.claimFocus(w)
    local zone = nil
    for _, z in ipairs(w._focusRing or {}) do for _, e in ipairs(z.elements or {}) do if e == el then zone = z.zone end end end
    if not zone then return nil end
    local got = S.F.focusWhere(w, zone, function(x) return x == el end)
    if got then S.F.dispatchJoypadDown(w, "QA") end
    return got
end

-- ===================================================================== the D-pad wheel (gallery_nov1_t3.lua)
function S.closeWheel()
    local st = S.D.state[S.pn]
    if st and st.menu and st.menu.undisplay then pcall(st.menu.undisplay, st.menu) end
    S.D.state[S.pn] = nil
    local m = getPlayerRadialMenu(S.pn)
    if m and m:isReallyVisible() then pcall(m.undisplay, m) end
    S.W.qaPoint = nil
end

-- ===================================================================== the hint strip's stand-in pad prompts
-- (ZeD_HintStrip.lua's PAD: the game's prompt fields and ZeD's picture for each button)
S.PAD = { { "aPrompt", "A" }, { "xPrompt", "X" }, { "yPrompt", "Y" }, { "bPrompt", "B" }, { "lbPrompt", "LB" }, { "rbPrompt", "RB" } }
-- the game's own rules for a pad's prompts, on a prompt object of the script's own (never added to the screen), at most
-- five times a second (as the strip's keyboard prompts are worked out)
function S.padPrompts()
    local St = S.St
    if St.hintStripMode and St.hintStripMode() == "off" then return nil end
    if S.p:isDead() or S.p:isAsleep() then return nil end
    local sc = UIManager.getSpeedControls and UIManager.getSpeedControls()
    if sc and sc:getCurrentGameSpeed() == 0 then return nil end
    if getFocusForPlayer(S.pn) ~= nil then return nil end
    -- (on a real pad the game's focus is on a window holding the pad, or on a wheel: the strip is down then)
    if S.F.getFocusedWindow(S.pn) then return nil end
    if S.D.state[S.pn] then return nil end
    local m = getPlayerRadialMenu(S.pn)
    if m and m:isReallyVisible() then return nil end
    local now = getTimestampMs()
    if now - (S.bpAt or 0) >= 200 then
        S.bpAt = now
        local bp, dir = S.bp, S.p:getDir()
        pcall(function() bp:clearButtonBindings() end)
        pcall(function() bp:getBestInteractButtonAction(dir) end)
        pcall(function() bp:getBestCancelButtonAction(dir) end)
        pcall(function() bp:getBestYButtonAction(dir) end)
        pcall(function() bp:getBestXButtonAction(dir) end)
        pcall(function() bp:getBestLBButtonAction(dir) end)
        pcall(function() bp:getBestRBButtonAction(dir) end)
        local out = {}
        for _, e in ipairs(S.PAD) do
            local t = bp[e[1]]
            if t and t ~= "" then out[#out + 1] = { glyph = e[2], label = tostring(t) } end
        end
        S.bpOut = out
    end
    return (S.bpOut and #S.bpOut > 0) and S.bpOut or nil
end
-- on: the strip asks the stand-in for the first player's prompts; off: the strip's own function again
function S.stripPad(on)
    local H = ZeD.HintStrip
    if not H then return end
    if on then
        if S.promptsWas then return end
        S.promptsWas = H.prompts
        S.bp = ISButtonPrompt:new(S.pn)
        H.prompts = function(pn)
            if pn ~= S.pn then return S.promptsWas(pn) end
            return S.padPrompts()
        end
    elseif S.promptsWas then
        H.prompts = S.promptsWas
        S.promptsWas, S.bp, S.bpOut = nil, nil, nil
    end
end
function S.stripHud() local h = nil; pcall(function() h = ZeD.HintStrip._huds[S.pn] end); return h end
function S.stripLine()
    local h = S.stripHud()
    if not (h and h._p) then return "the strip is down" end
    local words = {}
    for _, pr in ipairs(h._p) do words[#words + 1] = tostring(pr.glyph) .. " " .. tostring(pr.label) end
    return table.concat(words, " | ")
end

-- ===================================================================== the themes' moment (spot stock)
-- both windows open on Loot at their own heights, to one side; the apple's card out in the Character window
function S.stockMoment()
    Q.step(10, function()
        S.closeWheel()
        pcall(function() S.F.releaseFocus() end)
        S.Det.setLockedMode("kbm")
        S.stripPad(false)
        C3.go(Q, "stock", "SE")
        C3.pairOpen()
        Q.hold = C3.pairSide
        C3.park()
    end)
    Q.still(30, function() C3.charTab("loot"); C3.worldTab("loot") end)
    Q.still(20, function() if not S.selectItem(S.apple) then Q.say("ERR the inventory pane is not there for the apple's card") end end)
    Q.still(20, function() C3.park() end)
end
-- one theme: set, settled, the card again (the theme can rebuild the drawer), settled, the shot
function S.themeShot(base, name)
    Q.step(2, function() C3.theme(base, S.accent); C3.park() end)
    Q.still(10, function() S.selectItem(S.apple) end)
    Q.still(10, function() C3.park() end)
    Q.step(15, function()
        Q.say(name .. ": " .. S.live())
        Q.shot(name)
    end)
end

-- ===================================================================== setup
Q.step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    S.look = { ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize }
    S.wins = C3.snapWins()
    S.home = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
    S.optWas.glyphOption = S.getOpt(S.St.glyphOption)
    S.optWas.hintStripOption = S.getOpt(S.St.hintStripOption)
    S.focusWas = S.St.focusStyle and S.St.focusStyle() or "hand"
    S.padStateWas = S.MM.padState
    S.lockWas = nil
    pcall(function() S.lockWas = S.Det.getMode() end)
    C3.theme("dark", S.accent, S.look[3])
    C3.listView(true)
    for _ = 1, 3 do local a = S.add("Base.Apple"); S.apple = S.apple or a end
    S.hammer = S.add("Base.Hammer")
    pcall(function() ISInventoryPage.dirtyUI() end)
    if S.langRun then
        Q.say("the game is in " .. S.lang .. ": only sc3_language this run")
    else
        Q.say("the game is in English: sc3_language needs its own run (lang_run.ps1 -Lang RU or JP)")
    end
    Q.say("start: " .. S.live() .. " | apples " .. tostring(S.apple ~= nil) .. ", hammer " .. tostring(S.hammer ~= nil))
end)

if S.langRun then
    -- ================================================================= sc3_language (the themes' moment, Dark)
    S.stockMoment()
    Q.step(2, function() C3.theme("dark", S.accent); C3.park() end)
    Q.still(10, function() S.selectItem(S.apple) end)
    Q.still(10, function() C3.park() end)
    Q.step(15, function()
        Q.say("sc3_language: " .. S.live() .. " | the Loot tab reads " .. tostring(ZeD.tr("UI_ZeD_Char_TabLoot")))
        Q.shot("sc3_language")
    end)
else
    -- ================================================================= sc3_buttonmap (gallery_v1_c3_b.lua's 64)
    Q.step(10, function()
        C3.go(Q, "pump", "SE")
        C3.pairShut()
        -- (the Xbox pictures for this and the controller shots; put back after)
        for i, k in ipairs(S.St.glyphKeys or {}) do if k == "xbox" then S.St.glyphOption:setValue(i) end end
        if not S.menuUp() then S.toggleMenu() end
    end)
    Q.step(50, function() pcall(S.MM.openOptions) end)
    Q.step(50, function()
        local w = S.MM.pauseOpts
        if not (w and w:isVisible()) then Q.notTaken("sc3_buttonmap", "no in-game Options window"); return end
        S.pin(w)
        pcall(function() w:openVanillaController() end)
    end)
    Q.step(70, function()
        -- a made-up moment of input for the drawn pad (zedqa_pad_figure.lua "02_lit")
        S.MM.padState = function()
            return { b = { A = true, DL = true, RB = true, L3 = true }, ls = { 0.6, -0.4 }, rs = { 0, 0 }, lt = 0.6, rt = 0 }
        end
        C3.park()
    end)
    Q.step(40, function()
        local w = S.MM.pauseOpts
        if w and w.sub == "pad" and w._padFig then Q.shot("sc3_buttonmap", { { "options", w } })
        elseif w then Q.notTaken("sc3_buttonmap", "Button map and test did not open (" .. tostring(w.sub) .. ")") end
        S.MM.padState = S.padStateWas
    end)
    Q.step(10, function()
        local w = S.MM.pauseOpts
        pcall(function() w:closeSub() end)
        S.unpin(w)
        pcall(function() w:close() end)
    end)
    Q.step(20, function() if S.menuUp() then S.toggleMenu() end end)

    -- ================================================================= sc3_context (the forecourt, on the controller)
    Q.step(10, function()
        S.Det.setLockedMode("gamepad")
        pcall(function() S.St.setFocusStyle("hand") end)
        S.setOpt(S.St.hintStripOption, 1)          -- (the strip Always: ZeD's default)
        S.stripPad(true)
        C3.go(Q, "pump", "SE")
        C3.pairOpen()
        Q.hold = C3.pairSide
        C3.park()
    end)
    Q.still(30, function() C3.charTab("equip"); C3.worldTab("loot") end)
    Q.still(30, function() C3.park() end)
    -- (the strip comes up within a few frames of the stand-in's first answer)
    Q.waitFor(5, 120, function() local h = S.stripHud(); return h ~= nil and h._p ~= nil end, function(ok)
        Q.say("strip: " .. S.stripLine())
        if not ok then Q.say("note: sc3_context: the game has no prompt for this spot; the strip is not in the shot") end
        Q.say("sc3_context: " .. S.live())
        local h = S.stripHud()
        Q.shot("sc3_context", (h and h._p) and { { "hint strip", h, true } } or nil)
    end)

    -- ================================================================= sc3_pad (the highlight on the hammer's row)
    Q.step(5, function() C3.charTab("loot") end)
    Q.still(20, function() C3.park() end)
    Q.step(10, function()
        local w = C3.CW()
        local row = S.pickRow(w, S.hammer)
        S.padRow = row and S.focusOn(w, row)
        if not S.padRow then Q.say("ERR sc3_pad: no inventory row to put the pad on") end
    end)
    Q.still(12, function()
        if not S.padRow then Q.notTaken("sc3_pad", "no inventory row for the pad"); return end
        local e = S.F.getFocusedElement(C3.CW())
        Q.say("sc3_pad: pad focus on " .. tostring(e and e.item and e.item:getDisplayName()) .. " | strip: " .. S.stripLine() .. " | " .. S.live())
        Q.shot("sc3_pad")
    end)

    -- ================================================================= sc3_wheel (the windows open, the pad in the world)
    Q.step(5, function()
        pcall(function() S.F.releaseFocus() end)
        C3.park()
    end)
    Q.still(10, function()
        -- (the D-pad's left press the way the game makes it: ZeD's Character wheel; slice 3 is Eat, LB + A)
        ISDPadWheels.onDisplayLeft({ player = S.pn, id = nil })
        S.W.qaPoint = 3
    end)
    Q.step(30, function()
        local st = S.D.state[S.pn]
        local m = st and st.menu
        local sl = m and m.slices and m.slices[3]
        if not (m and m:isReallyVisible()) then Q.notTaken("sc3_wheel", "the Character wheel did not open"); return end
        Q.say("sc3_wheel: pointed " .. tostring(sl and sl.text) .. " | strip: " .. S.stripLine() .. " | " .. S.live())
        Q.shot("sc3_wheel")
    end)
    Q.step(5, function() S.closeWheel() end)

    -- ================================================================= sc3_themes_* (among the shelves)
    S.stockMoment()
    S.themeShot("dark", "sc3_themes_dark")
    S.themeShot("light", "sc3_themes_light")
    S.themeShot("hicon", "sc3_themes_hicon")
    Q.step(2, function() Q.notTaken("sc3_language", "the game is in English; run lang_run.ps1 -Lang RU (or JP) -Manifest showcase_s3.txt") end)
end

-- ===================================================================== put back
Q.mark()
Q.step(20, function()
    Q.hold = nil
    S.closeWheel()
    S.stripPad(false)
    S.MM.padState = S.padStateWas
    pcall(function() local w = S.opts(); if w then S.unpin(w); pcall(function() w:closeSub() end); if w:isVisible() then w:close() end end end)
    if S.menuUp() then S.toggleMenu() end
    pcall(function() S.F.releaseFocus() end)
    pcall(function() S.selectItem(nil) end)
    for i = #S.items, 1, -1 do local it = S.items[i]; pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    S.items = {}
    pcall(function() ISInventoryPage.dirtyUI() end)
    S.setOpt(S.St.glyphOption, S.optWas.glyphOption)
    S.setOpt(S.St.hintStripOption, S.optWas.hintStripOption)
    pcall(function() S.St.setFocusStyle(S.focusWas) end)
    pcall(function() S.Det.setLockedMode(nil) end)
    pcall(function() if S.St.save then S.St.save() end end)
    C3.listView(false)
    C3.theme(S.look[1], S.look[2], S.look[3])
    pcall(function() STORY.tp(S.home.x, S.home.y, S.home.z) end)
end)
Q.step(20, function()
    C3.backWins(S.wins)
    Q.say("put back: theme " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. ", input mode, focus, wheel, "
        .. "button pictures, highlight, hint strip, pause screen, card, items, list view, windows, place | input was "
        .. tostring(S.lockWas) .. " now " .. tostring(S.Det.getMode and S.Det.getMode()))
end)
Q.start()
