-- ZeD-UI/42/media/lua/client/ZeD/WindowHalves.lua
-- ============================================================================
-- WINDOW HALVES (client) - the dual pins of the Character and World windows,
-- a behaviour both windows attach, beside the curtain (WindowCurtain.lua).
--
-- Each window has two halves: the inventory side (strip and list) and the tab
-- drawer side (tab strip and drawer). Each half rolls up on its own, as the
-- game's inventory pages do: 2 s after the pointer leaves that half, or at
-- once on aim, unless that half is pinned. A rolled half comes back when the
-- pointer is over its part of the title bar.
--
--   inventory rolled:  the curtain rolls it under its rod (the rod carries
--                      the inventory's pin while it is rolled)
--   drawer rolled:     the tab drawer folds in, its tab still selected in the
--                      strip and named in the title; it comes back out on that
--                      tab when the half unrolls
--   both rolled:       the whole window rolls to its title bar, as it always has
--
-- One pin per half, each in its own end of the title bar: the drawer's pin on
-- the drawer's side, the inventory's on the inventory's. A pinned half never
-- rolls by itself; the roll box, the rod's tab and the tabs still work by hand.
-- With a controller there are no pointer timers (the game pins its pages for a
-- controller); the pins are stops in the title bar (A toggles) and the
-- aiming escape rolls only the unpinned halves (FocusManager).
--
-- The pins are kept with the character (modData ZeD_WinPinned: charInv,
-- charTabs, worldInv, worldTabs). An older save's single pin (char, world)
-- pins both halves. The single key stays written as "both halves pinned" for
-- anything that still reads it.
--
-- A window opts in with ZeD.Halves.attach(win, spec), after ZeD.Curtain.attach:
--   spec.key     "char" or "world" (the saved pins)
--   spec.side    the drawer's side of the window: "left" or "right"
--   spec.strip   the window's field holding its tab strip
--   spec.zone    the controller zone the pins go in
-- ============================================================================

require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.Halves = ZeD.Halves or {}
local H = ZeD.Halves

H.COLLAPSE_MS = 2000
H.REST_MS = 300       -- the pointer's rest on a rolled half's bar before that half comes back
local HALVES = { "inv", "drawer" }
local ENDS = { "left", "right" }

-- ---------------------------------------------------------------------------
-- Pins
-- ---------------------------------------------------------------------------
--- True while a half is pinned. win.pinned (both halves) also counts: QA and
--- older code set it straight on the window.
function H.isPinned(win, half)
    local s = win._halves
    return (s and s[half] and s[half].pinned) or win.pinned == true
end

local function save(win)
    local s = win._halves
    pcall(function()
        local md = getSpecificPlayer(win.playerNum or 0):getModData()
        local t = md.ZeD_WinPinned or {}
        md.ZeD_WinPinned = t
        t[s.key .. "Inv"] = s.inv.pinned
        t[s.key .. "Tabs"] = s.drawer.pinned
        t[s.key] = s.inv.pinned and s.drawer.pinned
    end)
end

-- The pins from the character's modData. A save with only the single pin
-- (before the halves) pins both halves when it was pinned.
local function load(win)
    local s = win._halves
    pcall(function()
        local md = getSpecificPlayer(win.playerNum or 0):getModData()
        local t = md.ZeD_WinPinned or {}
        md.ZeD_WinPinned = t
        local i, d = t[s.key .. "Inv"], t[s.key .. "Tabs"]
        if i == nil and d == nil then
            local old = t[s.key] == true
            i, d = old, old
            t[s.key .. "Inv"], t[s.key .. "Tabs"] = i, d
        end
        s.inv.pinned, s.drawer.pinned = i == true, d == true
    end)
    win.pinned = s.inv.pinned and s.drawer.pinned
end

--- Pin or unpin one half ("inv" or "drawer"), or both when half is nil. As the
--- window's own pin did, pinning a half that rolled by itself brings it back.
function H.setPin(win, half, on)
    local s = win._halves
    if not s then return end
    on = on and true or false
    for _, h in ipairs(HALVES) do
        if half == nil or half == h then
            local st = s[h]
            st.pinned = on
            st.out = nil
            if on and st.rolled and not st.hand then st.rolled = false end
        end
    end
    win.pinned = s.inv.pinned and s.drawer.pinned
    save(win)
    H.drive(win)
end

function H.togglePin(win, half)
    local s = win._halves
    if s and s[half] then H.setPin(win, half, not s[half].pinned) end
end

--- The help line's words for a half's pin.
function H.help(win, half)
    local on = H.isPinned(win, half)
    if half == "inv" then
        return ZeD.tr(on and "UI_ZeD_Win_HelpUnpinInv" or "UI_ZeD_Win_HelpPinInv")
    end
    return ZeD.tr(on and "UI_ZeD_Win_HelpUnpinTabs" or "UI_ZeD_Win_HelpPinTabs")
end

-- ---------------------------------------------------------------------------
-- Where the pins sit
-- ---------------------------------------------------------------------------
--- The half whose pin sits at one end of the title bar ("left" or "right"):
--- the drawer's pin on the drawer's side.
function H.halfAt(win, e)
    return (win._halves.side == e) and "drawer" or "inv"
end

-- the inventory's pin is on the rod while the curtain holds it rolled
local function onRod(win, half)
    return half == "inv" and win._rolled and not win.windowShaded
end

--- A pin's box at one end of the window's title bar, window-local, or nil while
--- that pin is on the rod. Left: after the close box. Right: where the
--- window's single pin always was, before the window box.
function H.pinRect(win, e)
    local s = win._halves
    if not s or onRod(win, H.halfAt(win, e)) then return nil end
    local T = ZeD.T
    local sz = T.closeBoxSz
    local r = s[e .. "Rect"]
    if not r then r = {}; s[e .. "Rect"] = r end
    if e == "right" then
        local box = win:windowBoxRect()
        r.x = (box and box.x or (win:getWidth() - T.sp.sm)) - T.sp.sm - sz
    else
        r.x = T.sp.sm + T.closeBoxSz + T.sp.sm
    end
    r.y, r.w, r.h = math.floor((win:titleBarHeight() - sz) / 2), sz, sz
    return r
end

--- How far the title moves right for the pin after the close box.
function H.titleShift(win)
    local r = win._halves and H.pinRect(win, "left")
    return r and (r.w + ZeD.T.sp.sm) or 0
end

--- The inventory's pin on a rolled side's rod, rod-local: at the rod's outer
--- end (a right rod), or after its close box (a left rod).
function H.rodPinRect(rod)
    local win = rod.win
    local s = win and win._halves
    if not s then return nil end
    local T = ZeD.T
    local sz = T.closeBoxSz
    local x = (s.side == "left") and (rod:getWidth() - T.sp.sm - sz) or (T.sp.sm + T.closeBoxSz + T.sp.sm)
    return { x = x, y = math.floor((T.titleBarH - sz) / 2), w = sz, h = sz }
end

--- How far a left rod's tab moves right for the pin after its close box.
function H.rodChipShift(win)
    local s = win._halves
    if not s or s.side ~= "right" then return 0 end
    return ZeD.T.closeBoxSz + ZeD.T.sp.sm
end

-- ---------------------------------------------------------------------------
-- Drawing and the pointer on the pins
-- ---------------------------------------------------------------------------
local function focusOn(win, half)
    local Focus = ZeD.Input and ZeD.Input.Focus
    return Focus and Focus.isFocused and Focus.isFocused(win, nil, "halfpin:" .. half) or false
end

--- Both title-bar pins (the window's title bar draw).
function H.drawTitlePins(win)
    local s = win._halves
    for _, e in ipairs(ENDS) do
        local r = H.pinRect(win, e)
        if r then
            local half = H.halfAt(win, e)
            ZeD_Window.drawPinBox(win, r, H.isPinned(win, half), s[half].hover)
            if focusOn(win, half) and ZeD.Focus and ZeD.Focus.mark then
                ZeD.Focus.mark(win, r.x, r.y, r.w, r.h, { win = win })
            end
        end
    end
end

--- The inventory's pin on the rod (the rod's draw, once it has rolled up).
function H.drawRodPin(rod)
    local win = rod.win
    local r = H.rodPinRect(rod)
    rod._pinRect = r
    if not r then return end
    local over = rod:isMouseOver() and ZeD.Atoms.mouseIn(rod, r.x, r.y, r.w, r.h)
    ZeD_Window.drawPinBox(rod, r, H.isPinned(win, "inv"), over)
    if over and ZeD.Help and ZeD.Help.set then ZeD.Help.set(win, H.help(win, "inv")) end
    if focusOn(win, "inv") and ZeD.Focus and ZeD.Focus.mark then
        ZeD.Focus.mark(rod, r.x, r.y, r.w, r.h, { win = win })
    end
end

--- The title-bar pins on the raw mouse (ZeD_Window:_watchBoxes): a press and
--- release on a pin asks update() to toggle it ("pin:inv" / "pin:drawer").
function H.watch(win, mx, my, down, fresh)
    local s = win._halves
    local on = win:pointerOn()
    for _, e in ipairs(ENDS) do
        local half = H.halfAt(win, e)
        local st = s[half]
        local r = H.pinRect(win, e)
        if r then
            local inside = on and mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h or false
            st.hover = inside
            if inside then win._updHelp = H.help(win, half) end
            if down then
                if fresh and inside then st.wasDown = true end
            elseif st.wasDown then
                st.wasDown = false
                if inside then win._boxDo = "pin:" .. half end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- The controller's stops
-- ---------------------------------------------------------------------------
local function pinElement(half, x, y, w, h)
    return {
        x = x, y = y, w = w, h = h,
        id = "halfpin:" .. half,
        promptA = function(ww) return ZeD.tr(H.isPinned(ww, half) and "UI_ZeD_Cm_Unpin" or "UI_ZeD_Prompt_Pin") end,
        onFocus = function() end,
        onActivate = function(ww) H.togglePin(ww, half) end,
    }
end

--- The pins as controller stops, window-local, left to right (the rod's pin
--- where the rod is). A pin on the bar is a stop as wide as the strip under it
--- (the tab strip under the drawer's, the bag strip under the inventory's): the
--- box itself overlaps its strip by a few pixels only, too little for the D-pad's
--- "lined up" test, and Up from the top tab or bag must land on it. The mark
--- still draws on the box (drawTitlePins).
function H.padElements(win)
    local s = win._halves
    local out = {}
    for _, e in ipairs(ENDS) do
        local r = H.pinRect(win, e)
        if r then
            local half = H.halfAt(win, e)
            local strip = (half == "drawer") and win[s.strip] or win._containerStrip
            local x, w = r.x, r.w
            if strip and strip:isVisible() and strip:getWidth() > 0 then x, w = strip:getX(), strip:getWidth() end
            out[#out + 1] = pinElement(half, x, r.y, w, r.h)
        end
    end
    local rod = win._rod
    local rr = win._rolled and rod and rod:isVisible() and rod._pinRect
    if rr then
        local ox = (s.side == "left") and win:getWidth() or -(win._rollW or 0)
        out[#out + 1] = pinElement("inv", ox + rr.x, rr.y, rr.w, rr.h)
    end
    table.sort(out, function(a, b) return a.x < b.x end)
    return out
end

-- The pins' zone, added to the end of the window's ring once (the ring's other
-- zones are found by name, so the order is free)
local function syncZone(win)
    local Focus = ZeD.Input and ZeD.Input.Focus
    local ring = win._focusRing
    if not (Focus and ring) then return end
    local name = win._halves.zone
    local found = false
    for i = 1, #ring do
        if ring[i].zone == name then found = true; break end
    end
    if not found then ring[#ring + 1] = { zone = name, focusable = false, elements = {}, focusedElementIdx = 1 } end
    local els = win.windowShaded and {} or H.padElements(win)
    Focus.setRingZoneElementsKeepId(win, name, els)
    Focus.setZoneFocusable(win, name, #els > 0)
end

-- ---------------------------------------------------------------------------
-- The halves on screen
-- ---------------------------------------------------------------------------
-- a tab drawer on show (or folded by its half), the drawer half's whole content
local function drawerOpen(win)
    return win._drawerOpen and win._drawerMode == "tab"
end

local function columnsOpen(win)
    return #(win._mcSelected or {}) > 0
end

-- The tab drawer folds only as a plain tab: no card over it, no Loot columns,
-- and the inventory showing beside it (a drawer as wide as the window has no
-- inventory to fold back to).
local function foldable(win)
    return drawerOpen(win) and not win._drawerObject and not win._drawerItem and not columnsOpen(win)
        and win._invDrawerOpen ~= false and win._activeTab ~= nil and win._activeTab ~= "loot"
end

-- the controller's stops follow the tab (both windows' own ring sync)
local function syncRing(win)
    local M = (win._halves.key == "char") and ZeD_CharacterWindow or ZeD_WorldWindow
    if M and M.syncRing then pcall(M.syncRing, win) end
end

-- The drawer shut at once: no closing slide (a half folded while the window is
-- rolled up must not show folding when the window comes down). It ends where the
-- windows' own animated close ends: the width the half-screen cap swallowed when
-- the drawer opened (_drawerCapLost, the usual case on the Deck and at 720p) is
-- given back, within the cap, and both cap counters start clean. The minimum
-- width comes down first (the engine clamps a real click's resize to it). The
-- Character window keeps its right edge (a push off the screen's left edge
-- remembered, as its close does); the World window keeps its left and settles
-- its push (ZeD_WorldWindow.settleCapPush, as its snaps to Loot do).
local function snapShut(win)
    local effW = math.floor(win._drawerEffW or 0)
    if effW <= 0 then return end
    local screenW = getCore():getScreenWidth()
    local maxW = win._maxWinW or math.floor(screenW * 0.5)
    local back = math.min(win._drawerCapLost or 0, effW)
    local newW = math.min(win:getWidth() - effW + back, maxW)
    win._drawerEffW, win._prevEffW = 0, 0
    win._drawerCapLost = 0
    win.minimumWidth = math.min(win.minimumWidth or newW, newW)
    win:setWidth(newW)
    if win._halves.side == "left" then
        if win._anchorRightEdge then
            local x = win._anchorRightEdge - newW
            local pushed = 0
            if x < 0 then pushed = -x; x = 0 end
            win._drawerCapPush = pushed
            win:setX(x)
            win._lastSetX = x
        else
            win._drawerCapPush = 0
        end
    elseif ZeD_WorldWindow and ZeD_WorldWindow.settleCapPush then
        ZeD_WorldWindow.settleCapPush(win)
    else
        win._drawerCapPush = 0
    end
end

-- The fold and unfold set the drawer's own fields, as a second press of the open
-- tab closes it and a press opens it again, but nothing else: the tab's scroll,
-- caches, selection and Equip pick stay as they were, so the drawer comes back
-- exactly as it went. (Pressing the tab through the strip went down its "new tab"
-- path: it scrolled the tab to the top, dropped its caches and the selection.)
-- The tab stays the window's while its drawer is rolled in: still selected in the
-- strip and named in the title, as a rolled inventory side keeps its tab on the
-- rod. (Set to Loot, a fold read as the window switching tabs on its own.)
local function fold(win, snap)
    local s = win._halves
    s.foldTab = win._activeTab
    win._drawerOpen, win._drawerMode, win._tabUnder = false, nil, nil
    if snap then snapShut(win) end
    syncRing(win)
end

local function unfold(win)
    local s = win._halves
    local tab = s.foldTab
    s.foldTab = nil
    if not tab or drawerOpen(win) then return end
    if s.key == "char" then win._preDrawerW = win:getWidth() end
    win._activeTab, win._drawerMode, win._drawerOpen, win._tabUnder = tab, "tab", true, nil
    syncRing(win)
end

--- The tab a folded drawer half keeps, for the saved layout (a window closed
--- with its drawer folded opens on that tab again), else nil.
function H.foldedTab(win)
    return win and win._halves and win._halves.foldTab or nil
end

--- True while a half has rolled by itself (the pointer, aim): Y counts such a
--- window as rolled up. A side rolled by hand does not count.
function H.anyRolled(win)
    local s = win and win._halves
    if not s then return false end
    return s.foldTab ~= nil or (win._rolled and not s.inv.hand) or false
end

--- A folded drawer forgotten (Reset this window: its Loot is what gets saved).
function H.forgetFold(win)
    local s = win and win._halves
    if not s then return end
    s.foldTab = nil
    s.drawer.rolled = false
    s.drawer.out = nil
end

-- the inventory list on show, or would be once the window comes down (a drawer as
-- wide as the window hides it; a rolled window keeps what it last saw)
local function invShown(win)
    local s = win._halves
    if win.windowShaded then return s.invShown ~= false end
    if win._rolled then s.invShown = true; return true end
    -- (the windows' own flag for an inventory a wide drawer hid, not the list panel's visibility,
    -- which lags a frame behind an unroll: read then, a list "hidden" kept the window rolled up)
    local on = win._invDrawerOpen ~= false
    s.invShown = on
    return on
end

-- the curtain rolls the inventory now, its rod already up when rolled from a rolled window
local function rollInv(win, atOnce)
    local s = win._halves
    s.driving = true
    ZeD.Curtain.roll(win)
    s.driving = false
    local rod = win._rod
    if atOnce and win._rolled and rod then
        rod._h = ZeD.T.titleBarH
        rod:setHeight(rod._h)
    end
end

--- Brings what the halves want on screen, one step per call (each update):
--- the whole window's shade, then the drawer's fold, then the curtain. A step
--- that waits on another (the curtain on a drawer still widening) is taken on
--- a later update.
function H.drive(win)
    local s = win._halves
    if not s then return end
    local inv, drw = s.inv, s.drawer
    -- (a tab, Loot or another tab pressed, Loot columns or an item card opened by hand under a
    -- folded half: that is the player's drawer now, and the half is down again. A card or the
    -- columns take the drawer's place, so the folded tab gives way to Loot, as its press would)
    if s.foldTab then
        local other = columnsOpen(win) or win._drawerItem or win._drawerObject
        if drawerOpen(win) or other or win._activeTab ~= s.foldTab then
            if other and win._activeTab == s.foldTab and not drawerOpen(win) then win._activeTab = "loot" end
            s.foldTab = nil; drw.rolled = false
        elseif win._invDrawerOpen == false then
            -- (the inventory hidden under a folded drawer, by the main bag's button: the drawer
            -- comes back, or the window would show its two strips alone)
            drw.rolled = false
        end
    end
    local hasDrawer = s.foldTab ~= nil or win._rolled or drawerOpen(win)
    local shaded = win.windowShaded
    if not hasDrawer and drw.rolled and not shaded then drw.rolled = false end
    local listShown = invShown(win)
    local effW = win._drawerEffW
    local settled = effW == s.lastEffW
    s.lastEffW = effW
    local cs = win._curtain
    -- (an inventory side with no list showing has nothing to keep: it rolls with the drawer)
    if (inv.rolled or not listShown) and (drw.rolled or not hasDrawer) and (inv.rolled or drw.rolled) then
        if not shaded then
            s.driving = true
            -- (the whole bar at the window's full width, as the window always rolled)
            if win._rolled and ZeD.Curtain then ZeD.Curtain.finishUnroll(win) end
            win._autoShaded = true
            win:setWindowShaded(true)
            s.driving = false
        end
        return
    end
    if shaded then
        -- a pinned half comes down with the window (only the unpinned one stays rolled)
        if H.isPinned(win, "inv") and not inv.hand then inv.rolled = false end
        if H.isPinned(win, "drawer") then drw.rolled = false end
        -- The half that stays rolled is put away before the window shows, so only the
        -- half brought back appears (no 100 ms of the whole window first): the drawer
        -- folds shut at once, and the inventory rolls with its rod already up.
        if drw.rolled and hasDrawer and not s.foldTab and foldable(win) then fold(win, true) end
        if not drw.rolled and s.foldTab then unfold(win) end
        s.driving = true
        win._autoShaded = false
        win:setWindowShaded(false)
        s.driving = false
        if inv.rolled and not win._rolled and cs and cs.canRoll() and invShown(win) then rollInv(win, true) end
        return
    end
    if drw.rolled and hasDrawer and not s.foldTab then
        if win._rolled and ZeD.Curtain then
            s.driving = true
            ZeD.Curtain.finishUnroll(win)
            s.driving = false
        end
        if foldable(win) then fold(win) end
        return
    end
    if not drw.rolled and s.foldTab then unfold(win); return end
    if inv.rolled and not win._rolled then
        if cs and cs.canRoll() and listShown and settled and (effW or 0) > 0 then rollInv(win, false) end
    elseif not inv.rolled and win._rolled then
        local rod = win._rod
        if not (rod and rod._target and rod._target > ZeD.T.titleBarH) then ZeD.Curtain.unroll(win) end
    end
end

--- Where the drawer half meets the inventory half, window-local x: the divider
--- line while both show; the whole window while one is rolled away; the tab
--- strip (and the drawer's pin) while no drawer shows. A window rolled to its
--- title bar is split evenly: each half hovers half the bar, whatever had folded
--- before (a folded drawer's part was a sliver beside its pin); the pins keep
--- their places.
function H.split(win)
    local s = win._halves
    if win.windowShaded then return math.floor(win:getWidth() / 2) end
    local w = win:getWidth()
    local x = win._dividerX
    if not x then
        local bags = win._containerStrip
        if win._rolled then
            x = (s.side == "left") and w or 0
        elseif drawerOpen(win) and not s.foldTab then
            -- (a drawer as wide as the window: the bag strip is still the inventory side's)
            if bags and bags:isVisible() then
                x = (s.side == "left") and bags:getX() or (bags:getX() + bags:getWidth())
            else
                x = (s.side == "left") and w or 0
            end
        else
            local strip = win[s.strip]
            local pr = H.pinRect(win, s.side)
            local sm = ZeD.T.sp.sm
            if s.side == "left" then
                x = math.max(strip and (strip:getX() + strip:getWidth()) or 0, pr and (pr.x + pr.w + sm) or 0)
            else
                x = math.min(strip and strip:getX() or w, pr and (pr.x - sm) or w)
            end
        end
    end
    return x
end

--- The pointer (window-local) against a half: inside its part of the window,
--- and on its part of the title bar. A rolled inventory side is its rod.
function H.hit(win, half, mx, my, split)
    local tbH = win:titleBarHeight()
    if half == "inv" and win._rolled and not win.windowShaded then
        local rod = win._rod
        if not (rod and rod:isVisible()) then return false, false end
        local rx, ry = rod:getX() - win:getX(), rod:getY() - win:getY()
        local inX = mx >= rx and mx < rx + rod:getWidth() and my >= ry
        return inX and my < ry + rod:getHeight(), inX and my < ry + tbH
    end
    if mx < 0 or my < 0 or mx > win:getWidth() or my > win:shownHeight() then return false, false end
    local left = (half == "drawer") == (win._halves.side == "left")
    local inX = (left and mx < split) or ((not left) and mx >= split)
    return inX, inX and my < tbH
end

-- an item held from this window: a row of its lists, or an Equip slot's
local function dragFrom(w)
    local c = w and w._mainContent
    if c and c._drag and c._drag:isActive() then return true end
    return (w and w._equipDrag and w._equipDrag:isActive()) and true or false
end

-- an item held in either window (the windows stay as they are until it drops)
local function itemDragging()
    for _, get in ipairs({ ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow, ZeD_WorldWindow and ZeD_WorldWindow.getWindow }) do
        if get and dragFrom(get()) then return true end
    end
    return false
end

--- True while the pointer (window-local) is on a half's pin: on the rod's pin
--- while the inventory side is rolled under it, else on the pin in the title bar.
--- A rolled half stays rolled under its own pin, so the click lands on the pin
--- (the rod takes the press: ZeD_CurtainRod:onMouseDown) and nothing moves in
--- under the pointer first (unrolled, the Character window's box sits exactly
--- where its rod's pin was).
function H.onPin(win, half, mx, my)
    local s = win._halves
    local rod = win._rod
    if half == "inv" and win._rolled and not win.windowShaded then
        local r = rod and rod:isVisible() and rod._pinRect
        if not r then return false end
        local x, y = mx - (rod:getX() - win:getX()), my - (rod:getY() - win:getY())
        return x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h
    end
    local e = (half == "drawer") and s.side or ((s.side == "left") and "right" or "left")
    local r = H.pinRect(win, e)
    return r ~= nil and mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h
end

-- Where each half's part of the window starts, for the pointer: the inventory's
-- and the drawer's split, and whether there is no drawer or no list at all.
local function splits(win)
    local s = win._halves
    local split = H.split(win)
    -- (no drawer at all: the whole window, bar and all, is the inventory's)
    local noDrawer = not (drawerOpen(win) or s.foldTab or win._rolled)
    local invSplit = noDrawer and ((s.side == "left") and 0 or win:getWidth()) or split
    -- (no inventory list showing, a drawer as wide as the window: the bar and the bag strip
    -- are the drawer's, and the inventory side has nothing to roll)
    local noList = s.invShown == false and not noDrawer
    local drwSplit = noList and ((s.side == "left") and win:getWidth() or 0) or split
    return invSplit, drwSplit, noDrawer, noList
end

-- An item held over a rolled half brings that half down at once, whatever the
-- other half's pin, so the drop lands in its list or on its tab: the inventory
-- from its rod, the drawer from its tab strip or its part of the title bar. (Only
-- a whole rolled window had this; a half rolled beside a pinned one stayed up.)
local function dragOver(win, mx, my)
    local s = win._halves
    local inv, drw = s.inv, s.drawer
    local invSplit, drwSplit = splits(win)
    if inv.rolled and win._rolled and H.hit(win, "inv", mx, my, invSplit) then
        inv.rolled, inv.hand, inv.restSince = false, false, nil
        -- (at once, not the rod's roll down: the release may come before it ends)
        s.driving = true
        ZeD.Curtain.finishUnroll(win)
        s.driving = false
    end
    if drw.rolled and s.foldTab and H.hit(win, "drawer", mx, my, drwSplit) then
        drw.rolled, drw.restSince = false, nil
    end
end

--- Each update (ZeD_Window:_autoCollapse): the halves' timers, the hover that
--- brings a rolled half back, the controller's stops, then one step on screen.
function H.update(win)
    local s = win._halves
    local pn = win.playerNum or 0
    local pad = JoypadState and JoypadState.players and JoypadState.players[pn + 1] ~= nil
    local now = getTimestampMs()
    local drag = itemDragging()
    local mx, my = getMouseX() - win:getAbsoluteX(), getMouseY() - win:getAbsoluteY()
    -- An item picked up in this window: the halves that rolled by themselves come
    -- back, so the drawer (an Equip slot) or the list is there to take it, and both
    -- stay until the drop (the timers below hold). Each half opens away from the
    -- other, so nothing moves under the pointer.
    local mine = drag and not pad and dragFrom(win)
    if mine and not s.dragMine then
        s.drawer.rolled = false
        if not s.inv.hand then s.inv.rolled = false end
    end
    s.dragMine = mine
    -- (an item held over a rolled window's title bar rolls it down, once, so its list takes the drop)
    if drag and win.windowShaded and not pad and mx >= 0 and mx <= win:getWidth() and my >= 0 and my < win:titleBarHeight() then
        win._autoShaded = false
        win:setWindowShaded(false)
    elseif drag and not pad and not win.windowShaded then
        dragOver(win, mx, my)
    end
    local aiming = false
    local p = getSpecificPlayer(pn)
    pcall(function() aiming = p and p:isAiming() end)
    -- (win._outSince in the future holds every timer: a tab opened by its key, QA's staging. The right
    -- button held is the mouse's aim: it holds nothing while the player aims)
    local hold = pad or drag or win.moving or isMouseButtonDown(0) or (isMouseButtonDown(1) and not aiming)
        or (win._outSince ~= nil and now < win._outSince)
    if not hold then
        local invSplit, drwSplit, noDrawer, noList = splits(win)
        for _, half in ipairs(HALVES) do
            local st = s[half]
            local inside, bar = H.hit(win, half, mx, my, half == "inv" and invSplit or drwSplit)
            local shown = win.windowShaded or (half == "inv" and win._rolled) or (half == "drawer" and s.foldTab ~= nil)
            if H.isPinned(win, half) or not st.rolled then st.restSince = nil end
            if H.isPinned(win, half) then
                st.out = nil
            elseif st.rolled then
                st.out = nil
                -- (a side rolled by hand stays until its tab is pressed; one the pointer rolled comes back on
                -- its bar, but not while the player aims through it, nor while the pointer is on its pin:
                -- unrolled under the pointer, the Character window's box took the pin's click and the menu
                -- opened)
                -- A rolled half comes back once the pointer has rested on its bar (the rod, or the
                -- rolled title bar) for H.REST_MS, timed on the clock: update() runs only every 100 ms,
                -- and a pointer passing over on its way elsewhere does not unroll it.
                local resting = not aiming and not H.onPin(win, half, mx, my) and bar and not st.hand
                if resting then
                    st.restSince = st.restSince or now
                    if now - st.restSince >= H.REST_MS then st.rolled = false; st.restSince = nil end
                else
                    st.restSince = nil
                    -- (rolled, but not showing so: the pointer in it brings the half back at once)
                    if not aiming and inside and not shown then st.rolled = false end
                end
            elseif inside or (half == "drawer" and noDrawer) or (half == "inv" and noList) then
                st.out = nil
            else
                st.out = st.out or now
                if aiming or now - st.out > H.COLLAPSE_MS then st.rolled = true; st.out = nil end
            end
        end
    else
        s.inv.out, s.drawer.out = nil, nil
        s.inv.restSince, s.drawer.restSince = nil, nil
    end
    H.drive(win)
    syncZone(win)
end

--- The aiming escape with a controller (FocusManager): the unpinned halves roll,
--- the pinned stay.
function H.aim(win)
    local s = win._halves
    if not s then return end
    for _, half in ipairs(HALVES) do
        if not H.isPinned(win, half) then s[half].rolled = true; s[half].out = nil end
    end
    H.drive(win)
end

--- Everything that rolled by itself comes down (a bumper or Y: "go look at this
--- window"). A side rolled by hand stays.
function H.showAll(win)
    local s = win._halves
    if not s then return end
    s.drawer.rolled = false
    if not s.inv.hand then s.inv.rolled = false end
    s.inv.out, s.drawer.out = nil, nil
    if win.windowShaded then
        s.driving = true
        win._autoShaded = false
        win:setWindowShaded(false)
        s.driving = false
    end
    H.drive(win)
end

-- ---------------------------------------------------------------------------
-- Attach
-- ---------------------------------------------------------------------------
--- Opt a window in (spec: see the header). The window's own shade and the
--- curtain still answer every other caller: a shade or unshade from anywhere
--- else (a double-click, Y, a tab's key) rolls or unrolls both halves with it,
--- and a roll or unroll of the curtain by hand moves the inventory half.
function H.attach(win, spec)
    win._halves = spec
    spec.inv = { pinned = false, rolled = false, hand = false }
    spec.drawer = { pinned = false, rolled = false }
    load(win)
    local baseShade = win.setWindowShaded
    win.setWindowShaded = function(self, shaded)
        local s = self._halves
        if s and not s.driving and (shaded and true or false) ~= (self.windowShaded and true or false) then
            s.drawer.rolled = shaded and true or false
            -- (a side rolled by hand under the shade is still rolled when the window comes down)
            s.inv.rolled = (shaded or (s.inv.hand and self._rolled)) and true or false
            if not s.inv.rolled then s.inv.hand = false end
            s.inv.out, s.drawer.out = nil, nil
        end
        return baseShade(self, shaded)
    end
    local cs = win._curtain
    if cs then
        local baseChange = cs.onChange
        cs.onChange = function(rolled)
            if baseChange then baseChange(rolled) end
            local s = win._halves
            if s and not s.driving then
                s.inv.rolled = rolled and true or false
                s.inv.hand = rolled and true or false
                s.inv.out = nil
            end
        end
    end
end
